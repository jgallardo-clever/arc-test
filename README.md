# GitHub Actions Runner Controller Setup

This repository contains PowerShell scripts to install and uninstall the GitHub Actions Runner Controller (ARC) on a Kubernetes cluster using Helm.

## Prerequisites

Before running the installation script, ensure you have the following tools installed:

- **PowerShell 5.1+** - Required to run the setup and uninstall scripts
- **kubectl** - Kubernetes command-line tool (latest version recommended)
- **Helm 3+** - Package manager for Kubernetes
- **Git** - For cloning this repository
- Active access to a Kubernetes cluster

## Environment Configuration

### Setup .env File

1. Copy the `.env.example` file to `.env`:
   ```powershell
   Copy-Item .env.example .env
   ```

2. Open `.env` in your preferred editor and configure the following variables:

   - **INSTALLATION_NAME** - Name of the Helm release (default: `arc-runner-gke`)
   - **NAMESPACE_SYSTEMS** - Kubernetes namespace for system components (default: `arc-systems`)
   - **NAMESPACE_RUNNERS** - Kubernetes namespace for runner pods (default: `arc-runners`)
   - **GITHUB_CONFIG_URL** - GitHub repository or organization URL where runners will be registered
     - Examples:
       - Personal repo: `https://github.com/username/repository`
       - Organization repo: `https://github.com/org-name/repository`
       - Organization level: `https://github.com/org-name`
       - Enterprise level: `https://github.com/enterprises/enterprise-name`
   - **GITHUB_PAT** - GitHub Personal Access Token (required permissions: `repo`, `admin:org_hook`, `workflow`)
   - **MIN_RUNNERS** - Minimum number of active runners (default: `1`)

## Installation Instructions

### Step 1: Configure kubectl Context

First, set up your kubectl context to connect to your Kubernetes cluster:

```powershell
# List available contexts
kubectl config get-contexts

# Switch to your target cluster context
kubectl config use-context <your-cluster-context>

# Verify the connection
kubectl cluster-info
```

#### For Cloud Providers

If your cluster is hosted on a cloud provider, you need to authenticate and configure credentials before setting the kubectl context:

**Amazon EKS (AWS)**
```powershell
# Install AWS CLI v2 (if not already installed)
# https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html

# Configure AWS credentials
aws configure

# Update kubeconfig for your EKS cluster
aws eks update-kubeconfig --region <region> --name <cluster-name>

# Verify connection
kubectl cluster-info
```

**Google Kubernetes Engine (GKE)**
```powershell
# Install Google Cloud SDK
# https://cloud.google.com/sdk/docs/install

# Authenticate with Google Cloud
gcloud auth login

# Set your project ID
gcloud config set project <project-id>

# Install Plugin Auth (if not already installed)
gcloud components install gke-gcloud-auth-plugin

# Get credentials for your GKE cluster
gcloud container clusters get-credentials <cluster-name> --region <region>

# Verify connection
kubectl cluster-info
```

**Azure Kubernetes Service (AKS)**
```powershell
# Install Azure CLI
# https://docs.microsoft.com/en-us/cli/azure/install-azure-cli

# Login to Azure
az login

# Set your subscription
az account set --subscription <subscription-id>

# Get credentials for your AKS cluster
az aks get-credentials --resource-group <resource-group> --name <cluster-name>

# Verify connection
kubectl cluster-info
```

**DigitalOcean Kubernetes (DOKS)**
```powershell
# Install doctl CLI
# https://docs.digitalocean.com/reference/doctl/how-to/install/

# Authenticate with DigitalOcean
doctl auth init

# Get credentials for your cluster
doctl kubernetes cluster kubeconfig save <cluster-id>

# Verify connection
kubectl cluster-info
```

### Step 2: Run the Setup Script

Execute the installation script using one of the following methods:

**Option 1: Using .env file (Recommended)**
```powershell
.\setup-github-arc-controller.ps1
```

**Option 2: Override parameters from command line**
```powershell
.\setup-github-arc-controller.ps1 -MIN_RUNNERS 5 -INSTALLATION_NAME my-runners
```

**Option 3: Provide all parameters explicitly**
```powershell
.\setup-github-arc-controller.ps1 `
  -GITHUB_CONFIG_URL "https://github.com/org/repo" `
  -GITHUB_PAT "ghp_your_token" `
  -MIN_RUNNERS 3
```

**Option 4: Single Namespace Installation (Require a pre-existing namespace)**
```powershell
.\setup-github-arc-controller-one-ns.ps1
```

### Step 3: Verify Installation

After the setup completes successfully, verify the installation:

```powershell
# Check Helm releases
helm list --all-namespaces

# Check system pods
kubectl get pods -n arc-systems

# Check runner pods
kubectl get pods -n arc-runners

# View runner logs
kubectl logs -n arc-runners -l app.kubernetes.io/component=runner
```

> In the case of single namespace installation, use the single namespace name instead of `arc-systems` and `arc-runners`.

## Uninstallation Instructions

To remove the GitHub Actions Runner Controller from your cluster:

```powershell
# Using .env file
.\uninstall-github-arc-controller.ps1

# Or with parameters
.\uninstall-github-arc-controller.ps1 -INSTALLATION_NAME arc-runner-gke -NAMESPACE_SYSTEMS arc-systems
```

The uninstall script will remove:
- GitHub Runner Scale Set deployment
- GitHub Actions Runner Controller
- Associated namespaces (optional - you may need to remove these manually)

## Troubleshooting

**Issue: "ERROR: GITHUB_CONFIG_URL and GITHUB_PAT are required"**
- Ensure your `.env` file exists and contains these variables, or provide them as parameters

**Issue: Runners not appearing in GitHub**
- Check that the `GITHUB_PAT` token has correct permissions
- Verify the `GITHUB_CONFIG_URL` is correct
- Check runner pod logs: `kubectl logs -n arc-runners <pod-name>`

**Issue: kubectl connection failed**
- Run `kubectl config get-contexts` to verify your cluster context
- Ensure your cluster credentials are valid
- Verify your firewall/network allows access to the cluster

## Additional Resources

- [GitHub Actions Runner Controller Documentation](https://docs.github.com/en/actions/tutorials/use-actions-runner-controller/quickstart)
- [Helm Documentation](https://helm.sh/docs/)
- [Kubernetes Documentation](https://kubernetes.io/docs/)

## License

This project is provided as-is for use with GitHub Actions Runner Controller.