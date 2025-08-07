#!/bin/bash

# vCluster with ArgoCD - Prerequisites Installation Script
# This script installs all required components for the vCluster setup

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
EKS_CLUSTER_NAME="${EKS_CLUSTER_NAME:-your-eks-cluster}"
AWS_REGION="${AWS_REGION:-us-east-1}"
DOMAIN_NAME="${DOMAIN_NAME:-yourdomain.com}"
EMAIL="${EMAIL:-admin@yourdomain.com}"

print_step() {
    echo -e "${BLUE}==== $1 ====${NC}"
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️ $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

# Check prerequisites
check_prerequisites() {
    print_step "Checking Prerequisites"
    
    # Check if kubectl is installed
    if ! command -v kubectl &> /dev/null; then
        print_error "kubectl is not installed. Please install kubectl first."
        exit 1
    fi
    
    # Check if helm is installed
    if ! command -v helm &> /dev/null; then
        print_error "helm is not installed. Please install helm first."
        exit 1
    fi
    
    # Check if AWS CLI is installed
    if ! command -v aws &> /dev/null; then
        print_error "AWS CLI is not installed. Please install AWS CLI first."
        exit 1
    fi
    
    # Check cluster connectivity
    if ! kubectl cluster-info &> /dev/null; then
        print_error "Cannot connect to Kubernetes cluster. Please check your kubeconfig."
        exit 1
    fi
    
    print_success "All prerequisites are met"
}

# Install vCluster operator
install_vcluster_operator() {
    print_step "Installing vCluster Operator"
    
    # Add vCluster Helm repository
    helm repo add loft-sh https://charts.loft.sh
    helm repo update
    
    # Create vcluster namespace
    kubectl create namespace vcluster-system --dry-run=client -o yaml | kubectl apply -f -
    
    # Install vCluster operator
    helm upgrade --install vcluster-operator loft-sh/vcluster \
        --namespace vcluster-system \
        --set operator.enabled=true \
        --wait
    
    print_success "vCluster operator installed"
}

# Apply RBAC configurations
apply_rbac() {
    print_step "Applying RBAC Configurations"
    
    kubectl apply -f rbac/vcluster-rbac.yaml
    
    print_success "RBAC configurations applied"
}

# Install NGINX Ingress Controller
install_nginx_ingress() {
    print_step "Installing NGINX Ingress Controller"
    
    # Add NGINX Helm repository
    helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
    helm repo update
    
    # Create namespace
    kubectl create namespace ingress-nginx --dry-run=client -o yaml | kubectl apply -f -
    
    # Install NGINX Ingress Controller
    helm upgrade --install ingress-nginx ingress-nginx/ingress-nginx \
        --namespace ingress-nginx \
        --set controller.service.type=LoadBalancer \
        --set controller.service.annotations."service\.beta\.kubernetes\.io/aws-load-balancer-type"="nlb" \
        --set controller.service.annotations."service\.beta\.kubernetes\.io/aws-load-balancer-scheme"="internet-facing" \
        --set controller.allowSnippetAnnotations=true \
        --wait
    
    print_success "NGINX Ingress Controller installed"
}

# Install cert-manager
install_cert_manager() {
    print_step "Installing cert-manager"
    
    # Add Jetstack Helm repository
    helm repo add jetstack https://charts.jetstack.io
    helm repo update
    
    # Create namespace
    kubectl create namespace cert-manager --dry-run=client -o yaml | kubectl apply -f -
    
    # Install cert-manager
    helm upgrade --install cert-manager jetstack/cert-manager \
        --namespace cert-manager \
        --set installCRDs=true \
        --wait
    
    # Apply cluster issuers
    cat <<EOF | kubectl apply -f -
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: letsencrypt-prod
spec:
  acme:
    email: ${EMAIL}
    server: https://acme-v02.api.letsencrypt.org/directory
    privateKeySecretRef:
      name: letsencrypt-prod
    solvers:
    - http01:
        ingress:
          class: nginx
---
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: letsencrypt-staging
spec:
  acme:
    email: ${EMAIL}
    server: https://acme-staging-v02.api.letsencrypt.org/directory
    privateKeySecretRef:
      name: letsencrypt-staging
    solvers:
    - http01:
        ingress:
          class: nginx
EOF
    
    print_success "cert-manager installed"
}

# Deploy ArgoCD Applications
deploy_argocd_apps() {
    print_step "Deploying ArgoCD Applications"
    
    # Update repository URLs in ArgoCD configurations
    sed -i "s|https://github.com/YOUR_ORG/YOUR_REPO.git|$(git remote get-url origin)|g" argocd/*.yaml
    
    # Apply ArgoCD configurations
    kubectl apply -f argocd/applicationset-vcluster.yaml
    kubectl apply -f argocd/prod-vcluster-app.yaml
    
    print_success "ArgoCD applications deployed"
}

# Create production vCluster configuration
create_prod_vcluster() {
    print_step "Creating Production vCluster Configuration"
    
    # Create vcluster-configs directory if it doesn't exist
    mkdir -p vcluster-configs/prod
    
    # Update domain in production values
    sed -i "s|yourdomain.com|${DOMAIN_NAME}|g" vcluster-configs/prod/values.yaml
    
    print_success "Production vCluster configuration ready"
}

# Get ingress controller external IP
get_ingress_ip() {
    print_step "Getting Ingress Controller External IP"
    
    echo "Waiting for LoadBalancer to be ready..."
    kubectl wait --namespace ingress-nginx \
        --for=condition=available \
        --timeout=300s \
        deployment/ingress-nginx-controller
    
    # Get the external IP/hostname
    EXTERNAL_IP=$(kubectl get service ingress-nginx-controller \
        -n ingress-nginx \
        -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')
    
    if [ -z "$EXTERNAL_IP" ]; then
        EXTERNAL_IP=$(kubectl get service ingress-nginx-controller \
            -n ingress-nginx \
            -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
    fi
    
    if [ -n "$EXTERNAL_IP" ]; then
        print_success "Ingress Controller External IP/Hostname: $EXTERNAL_IP"
        print_warning "Please create DNS records pointing your vCluster subdomains to: $EXTERNAL_IP"
        print_warning "Example DNS records:"
        echo "  - prod-vcluster.${DOMAIN_NAME} -> $EXTERNAL_IP"
        echo "  - dev-vcluster.${DOMAIN_NAME} -> $EXTERNAL_IP"
        echo "  - qa-vcluster.${DOMAIN_NAME} -> $EXTERNAL_IP"
        echo "  - *.${DOMAIN_NAME} -> $EXTERNAL_IP (wildcard for feature branches)"
    else
        print_warning "Could not determine external IP. Check the ingress-nginx service manually."
    fi
}

# Verify installation
verify_installation() {
    print_step "Verifying Installation"
    
    # Check vCluster operator
    if kubectl get deployment vcluster-operator -n vcluster-system &> /dev/null; then
        print_success "vCluster operator is running"
    else
        print_error "vCluster operator is not running"
    fi
    
    # Check NGINX Ingress
    if kubectl get deployment ingress-nginx-controller -n ingress-nginx &> /dev/null; then
        print_success "NGINX Ingress Controller is running"
    else
        print_error "NGINX Ingress Controller is not running"
    fi
    
    # Check cert-manager
    if kubectl get deployment cert-manager -n cert-manager &> /dev/null; then
        print_success "cert-manager is running"
    else
        print_error "cert-manager is not running"
    fi
    
    # Check ArgoCD applications
    if kubectl get applicationset vcluster-branches -n argocd &> /dev/null; then
        print_success "ArgoCD ApplicationSet is deployed"
    else
        print_warning "ArgoCD ApplicationSet not found - this is normal if ArgoCD hasn't synced yet"
    fi
}

# Main installation function
main() {
    echo -e "${GREEN}"
    echo "==========================================="
    echo "  vCluster with ArgoCD - Setup Script"
    echo "==========================================="
    echo -e "${NC}"
    
    echo "Configuration:"
    echo "  EKS Cluster: $EKS_CLUSTER_NAME"
    echo "  AWS Region: $AWS_REGION"
    echo "  Domain: $DOMAIN_NAME"
    echo "  Email: $EMAIL"
    echo ""
    
    read -p "Do you want to continue with the installation? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Installation cancelled."
        exit 0
    fi
    
    check_prerequisites
    install_vcluster_operator
    apply_rbac
    install_nginx_ingress
    install_cert_manager
    deploy_argocd_apps
    create_prod_vcluster
    get_ingress_ip
    verify_installation
    
    print_step "Installation Complete!"
    print_success "All components have been installed successfully"
    
    echo ""
    echo "Next steps:"
    echo "1. Configure your DNS records as shown above"
    echo "2. Update GitHub repository URLs in argocd/*.yaml files"
    echo "3. Configure GitHub Actions secrets (AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY)"
    echo "4. Create your first branch to test vCluster creation"
    echo "5. Check ArgoCD UI for new applications"
    echo ""
    print_warning "Remember to replace placeholder values in configuration files with your actual values!"
}

# Run main function
main "$@"