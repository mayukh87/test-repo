# vCluster Management with ArgoCD and GitHub Actions

This guide provides a complete setup for managing vClusters dynamically based on GitHub branching strategy using ArgoCD in EKS.

## Architecture Overview

- **Feature branches** → Automatic vCluster creation (dev-vcluster, qa-vcluster)
- **Branch deletion** → Automatic vCluster decommissioning
- **PROD vCluster** → Standalone, always running
- **ArgoCD** → Manages all vClusters via ApplicationSets

## Prerequisites

- EKS cluster with ArgoCD installed
- GitHub repository with Actions enabled
- kubectl access to your EKS cluster
- Helm 3.x installed

## Step-by-Step Implementation

### Step 1: Install vCluster Operator

First, install the vCluster operator in your EKS cluster:

```bash
# Add vCluster Helm repository
helm repo add loft-sh https://charts.loft.sh
helm repo update

# Create vcluster namespace
kubectl create namespace vcluster-system

# Install vCluster operator
helm install vcluster-operator loft-sh/vcluster \
  --namespace vcluster-system \
  --set operator.enabled=true
```

### Step 2: Configure RBAC and Service Accounts

Create service accounts and RBAC permissions for ArgoCD to manage vClusters.

### Step 3: Create ArgoCD ApplicationSets

Set up ApplicationSets to automatically deploy vClusters based on Git repository state.

### Step 4: GitHub Actions Workflows

Configure workflows for:
- vCluster creation on branch creation
- vCluster deletion on branch deletion

### Step 5: Production vCluster

Deploy standalone production vCluster.

### Step 6: Networking and Ingress

Configure access to vClusters.

## Files Created

- `argocd/applicationset-vcluster.yaml` - ArgoCD ApplicationSet for dynamic vClusters
- `argocd/prod-vcluster-app.yaml` - Production vCluster application
- `helm/vcluster/` - Helm chart for vCluster deployments
- `.github/workflows/vcluster-create.yaml` - Create vCluster workflow
- `.github/workflows/vcluster-delete.yaml` - Delete vCluster workflow
- `rbac/` - RBAC configurations
- `vcluster-configs/` - vCluster configuration files
