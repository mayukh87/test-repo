# Complete Implementation Guide: vCluster with ArgoCD and GitHub Actions

This guide provides **detailed step-by-step instructions** to set up automatic vCluster management based on GitHub branching strategy using ArgoCD in EKS.

## 🎯 What You'll Achieve

- **Automatic vCluster Creation**: When you create `dev`, `qa`, or `feature/*` branches
- **Automatic vCluster Deletion**: When you delete branches
- **Production vCluster**: Always-running production environment
- **ArgoCD Management**: All vClusters visible and managed in ArgoCD UI
- **Complete Automation**: Zero manual intervention for vCluster lifecycle

## 📋 Prerequisites

### Required Tools
- ✅ EKS cluster with ArgoCD already installed
- ✅ `kubectl` configured to access your EKS cluster
- ✅ `helm` v3.x installed
- ✅ AWS CLI configured with appropriate permissions
- ✅ GitHub repository with Actions enabled

### Required Permissions
Your AWS credentials need the following permissions:
- EKS cluster admin access
- Load Balancer creation/deletion
- Route53 (if using automatic DNS)

## 🚀 Step 1: Clone and Configure Repository

1. **Clone this repository** (or copy all files to your existing repo):
   ```bash
   git clone <your-repo-url>
   cd <your-repo>
   ```

2. **Update configuration placeholders**:

   Replace the following placeholders in all files:
   - `YOUR_ORG/YOUR_REPO` → Your GitHub repository (e.g., `mycompany/my-app`)
   - `your-eks-cluster` → Your actual EKS cluster name
   - `yourdomain.com` → Your actual domain name
   - `admin@yourdomain.com` → Your email address

   Quick way to do this:
   ```bash
   # Replace repository URLs
   find . -name "*.yaml" -exec sed -i 's|YOUR_ORG/YOUR_REPO|mycompany/my-app|g' {} \;
   
   # Replace cluster name
   find . -name "*.yaml" -name "*.sh" -exec sed -i 's|your-eks-cluster|my-actual-cluster|g' {} \;
   
   # Replace domain
   find . -name "*.yaml" -exec sed -i 's|yourdomain.com|myactual.com|g' {} \;
   
   # Replace email
   find . -name "*.yaml" -exec sed -i 's|admin@yourdomain.com|me@myactual.com|g' {} \;
   ```

## 🔧 Step 2: Install Prerequisites

### Option A: Automated Installation (Recommended)

Run the automated installation script:

```bash
# Set your configuration
export EKS_CLUSTER_NAME="your-actual-cluster-name"
export AWS_REGION="us-east-1"
export DOMAIN_NAME="yourdomain.com"
export EMAIL="admin@yourdomain.com"

# Run installation
./scripts/install-prerequisites.sh
```

### Option B: Manual Installation

If you prefer manual control, follow these steps:

1. **Install vCluster Operator**:
   ```bash
   helm repo add loft-sh https://charts.loft.sh
   helm repo update
   kubectl create namespace vcluster-system
   helm install vcluster-operator loft-sh/vcluster \
     --namespace vcluster-system \
     --set operator.enabled=true
   ```

2. **Apply RBAC Configurations**:
   ```bash
   kubectl apply -f rbac/vcluster-rbac.yaml
   ```

3. **Install NGINX Ingress Controller**:
   ```bash
   helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
   helm repo update
   
   helm install ingress-nginx ingress-nginx/ingress-nginx \
     --namespace ingress-nginx \
     --create-namespace \
     --set controller.service.type=LoadBalancer \
     --set controller.service.annotations."service\.beta\.kubernetes\.io/aws-load-balancer-type"="nlb" \
     --set controller.allowSnippetAnnotations=true
   ```

4. **Install cert-manager**:
   ```bash
   helm repo add jetstack https://charts.jetstack.io
   helm repo update
   
   helm install cert-manager jetstack/cert-manager \
     --namespace cert-manager \
     --create-namespace \
     --set installCRDs=true
   
   # Apply ClusterIssuers
   kubectl apply -f networking/cert-manager.yaml
   ```

## 🔑 Step 3: Configure GitHub Actions Secrets

In your GitHub repository, go to **Settings** → **Secrets and variables** → **Actions** and add:

| Secret Name | Value | Description |
|-------------|--------|-------------|
| `AWS_ACCESS_KEY_ID` | Your AWS access key | For EKS cluster access |
| `AWS_SECRET_ACCESS_KEY` | Your AWS secret key | For EKS cluster access |

### Creating AWS IAM User for GitHub Actions

1. **Create IAM User**:
   ```bash
   aws iam create-user --user-name github-actions-vcluster
   ```

2. **Create and attach policy**:
   ```json
   {
     "Version": "2012-10-17",
     "Statement": [
       {
         "Effect": "Allow",
         "Action": [
           "eks:DescribeCluster",
           "eks:UpdateKubeconfig"
         ],
         "Resource": "arn:aws:eks:*:*:cluster/your-cluster-name"
       }
     ]
   }
   ```

3. **Generate access keys**:
   ```bash
   aws iam create-access-key --user-name github-actions-vcluster
   ```

## 📦 Step 4: Deploy ArgoCD Applications

1. **Apply ArgoCD ApplicationSet**:
   ```bash
   kubectl apply -f argocd/applicationset-vcluster.yaml
   ```

2. **Deploy Production vCluster Application**:
   ```bash
   kubectl apply -f argocd/prod-vcluster-app.yaml
   ```

3. **Verify in ArgoCD UI**:
   - Go to your ArgoCD UI: `https://a1a2a7247b4e240129a9cc6099f23409-1670662044.us-east-1.elb.amazonaws.com`
   - You should see:
     - `vcluster-branches` (ApplicationSet)
     - `prod-vcluster` (Application)

## 🌐 Step 5: Configure DNS

1. **Get LoadBalancer External IP**:
   ```bash
   kubectl get service ingress-nginx-controller -n ingress-nginx
   ```

2. **Create DNS Records** in your DNS provider:
   ```
   Type: CNAME/A
   Name: prod-vcluster.yourdomain.com
   Value: <LoadBalancer-External-IP>
   
   Type: CNAME/A  
   Name: *.yourdomain.com
   Value: <LoadBalancer-External-IP>
   ```

   The wildcard record ensures all vCluster subdomains work automatically.

## 🧪 Step 6: Test the Setup

### Test 1: Create a Development Branch

1. **Create and push a dev branch**:
   ```bash
   git checkout -b dev
   git push origin dev
   ```

2. **Check GitHub Actions**:
   - Go to your repository → **Actions**
   - You should see "Create vCluster on Branch Creation" workflow running
   - Check the workflow logs for progress

3. **Verify in ArgoCD**:
   - Refresh your ArgoCD UI
   - You should see a new application: `vcluster-dev`
   - Wait for it to sync and become healthy

4. **Access the vCluster**:
   ```bash
   # Get vCluster kubeconfig
   vcluster connect dev-vcluster -n vcluster-dev
   
   # Or access via web
   # https://dev-vcluster.yourdomain.com
   ```

### Test 2: Create a Feature Branch

1. **Create a feature branch**:
   ```bash
   git checkout -b feature/new-feature
   git push origin feature/new-feature
   ```

2. **Verify the workflow creates the configuration and ArgoCD picks it up**

### Test 3: Delete a Branch

1. **Delete the feature branch**:
   ```bash
   git push origin --delete feature/new-feature
   ```

2. **Check the deletion workflow**:
   - GitHub Actions should run the deletion workflow
   - ArgoCD should remove the application
   - Kubernetes resources should be cleaned up

## 🔍 Step 7: Monitoring and Verification

### Check vCluster Status
```bash
# List all vClusters
kubectl get virtualclusters --all-namespaces

# Check specific vCluster
kubectl describe virtualcluster prod-vcluster -n vcluster-prod

# Check ArgoCD applications
kubectl get applications -n argocd | grep vcluster
```

### Access vCluster
```bash
# Connect to production vCluster
vcluster connect prod-vcluster -n vcluster-prod

# Connect to dev vCluster
vcluster connect dev-vcluster -n vcluster-dev

# List all contexts
kubectl config get-contexts
```

### Monitor Resources
```bash
# Check resource usage
kubectl top pods --all-namespaces | grep vcluster

# Check ingress
kubectl get ingress --all-namespaces
```

## 🚨 Troubleshooting

### Issue: ArgoCD ApplicationSet not detecting branches

**Solution**:
1. Check if the repository URL is correct in `argocd/applicationset-vcluster.yaml`
2. Verify ArgoCD has access to your repository
3. Check ArgoCD logs:
   ```bash
   kubectl logs -n argocd deployment/argocd-applicationset-controller
   ```

### Issue: vCluster not starting

**Solution**:
1. Check vCluster operator logs:
   ```bash
   kubectl logs -n vcluster-system deployment/vcluster-operator
   ```
2. Check if resources are sufficient:
   ```bash
   kubectl describe nodes
   ```

### Issue: Ingress not working

**Solution**:
1. Check NGINX ingress controller:
   ```bash
   kubectl get pods -n ingress-nginx
   kubectl logs -n ingress-nginx deployment/ingress-nginx-controller
   ```
2. Verify DNS records are correct
3. Check SSL certificates:
   ```bash
   kubectl get certificates --all-namespaces
   kubectl describe certificaterequest -n vcluster-prod
   ```

### Issue: GitHub Actions failing

**Solution**:
1. Check AWS credentials in GitHub secrets
2. Verify EKS cluster name and region
3. Check IAM permissions for the GitHub Actions user

## 📊 Resource Requirements

### Minimum Cluster Resources
- **CPU**: 4 cores available for vClusters
- **Memory**: 8GB available for vClusters  
- **Storage**: 50GB for persistent volumes

### Per vCluster Resource Usage
- **Production**: 2 CPU, 4GB RAM, 50GB storage
- **QA**: 1 CPU, 2GB RAM, 10GB storage
- **Dev**: 0.5 CPU, 1GB RAM, 5GB storage
- **Feature**: 0.3 CPU, 512MB RAM, 3GB storage

## 🔒 Security Considerations

1. **RBAC**: All vClusters run with limited permissions
2. **Network Isolation**: Each vCluster is isolated in its own namespace
3. **SSL/TLS**: All ingress traffic is encrypted with Let's Encrypt certificates
4. **Secrets**: GitHub Actions uses minimal required AWS permissions

## 🎉 Success Criteria

After successful setup, you should have:

✅ **Automatic vCluster Creation**: New branches trigger vCluster creation  
✅ **ArgoCD Integration**: All vClusters visible in ArgoCD UI  
✅ **Automatic Cleanup**: Branch deletion removes vClusters  
✅ **Production Environment**: Always-running prod-vcluster  
✅ **SSL Certificates**: Automatic SSL for all vCluster domains  
✅ **GitHub Integration**: Issues created/closed automatically  

## 📞 Support

If you encounter issues:

1. **Check the logs** of each component
2. **Review the troubleshooting section** above
3. **Verify all placeholders** have been replaced with actual values
4. **Check resource availability** in your cluster

---

**🎯 You now have a fully automated vCluster management system!** 

Every time you create a branch, a corresponding vCluster will be automatically created and managed by ArgoCD. When you delete the branch, the vCluster is automatically cleaned up. Your production environment runs independently and is always available.