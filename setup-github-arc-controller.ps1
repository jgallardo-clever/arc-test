# Parameters
param (
    [string]$INSTALLATION_NAME,
    [string]$NAMESPACE_SYSTEMS,
    [string]$NAMESPACE_RUNNERS,
    [string]$GITHUB_CONFIG_URL,
    [string]$GITHUB_PAT,
    [int]$MIN_RUNNERS
)

# Load variables from .env if it exists and were not provided as parameters
if (Test-Path ".env") {
    Write-Host "Loading variables from .env..."
    Get-Content ".env" | ForEach-Object {
        if ($_ -match '^\s*([a-zA-Z_][a-zA-Z0-9_]*)\s*=\s*(.*)$' -and $_ -notmatch '^#') {
            $name, $value = $matches[1], $matches[2]
            $value = $value.Trim().Trim('"').Trim("'")
            
            # Only assign if the parameter was not passed explicitly (is empty)
            if ([string]::IsNullOrEmpty((Get-Variable -Name $name -ErrorAction SilentlyContinue).Value)) {
                Set-Variable -Name $name -Value $value
            }
        }
    }
}

# Validate that we have the required parameters
if ([string]::IsNullOrEmpty($GITHUB_CONFIG_URL) -or [string]::IsNullOrEmpty($GITHUB_PAT)) {
    Write-Host "ERROR: GITHUB_CONFIG_URL and GITHUB_PAT are required." -ForegroundColor Red
    Write-Host "Provide these parameters or create a .env file with the configured variables." -ForegroundColor Red
    exit 1
}

# Assign default values if they were not loaded
if ([string]::IsNullOrEmpty($INSTALLATION_NAME)) { $INSTALLATION_NAME = "arc-runner-gke" }
if ([string]::IsNullOrEmpty($NAMESPACE_SYSTEMS)) { $NAMESPACE_SYSTEMS = "arc-systems" }
if ([string]::IsNullOrEmpty($NAMESPACE_RUNNERS)) { $NAMESPACE_RUNNERS = "arc-runners" }
if ($MIN_RUNNERS -eq 0) { $MIN_RUNNERS = 1 }

Write-Host "Adding the Actions Runner Controller Helm repository..."
try {
  helm repo add actions-runner-controller https://actions-runner-controller.github.io/actions-runner-controller
  Write-Host "Helm repository 'actions-runner-controller' added successfully."
}
catch {
  Write-Host "Helm repository 'actions-runner-controller' already exists. Continuing..."
}

Write-Host "Updating Helm repositories..."
try {
  helm repo update
  Write-Host "Helm repositories updated successfully."
}
catch {
  Write-Host "Failed to update Helm repositories. Please check your Helm configuration."
  exit 1
}

Write-Host "Installing GitHub Actions Runner Controller via Helm..."
try {
  helm install arc `
  --namespace $NAMESPACE_SYSTEMS `
  --create-namespace `
  oci://ghcr.io/actions/actions-runner-controller-charts/gha-runner-scale-set-controller
  Write-Host "GitHub Actions Runner Controller installed successfully."
}
catch {
  Write-Host "GitHub Actions Runner Controller is already installed. Continuing..."
}

Write-Host "Installing GitHub Runner Scale Set via Helm..."
try {
  helm install $INSTALLATION_NAME `
    --namespace $NAMESPACE_RUNNERS `
    --create-namespace `
    --set githubConfigUrl=$GITHUB_CONFIG_URL `
    --set githubConfigSecret.github_token=$GITHUB_PAT `
    --set minRunners=$MIN_RUNNERS `
    --set runnerScaleSetName="$INSTALLATION_NAME" `
    oci://ghcr.io/actions/actions-runner-controller-charts/gha-runner-scale-set
  Write-Host "GitHub Runner Scale Set installed successfully."
}
catch {
  Write-Host "GitHub Runner Scale Set is already installed. Continuing..."
}


Write-Host "Checking the helm list for installed releases..."
try {
  helm list --all-namespaces
}
catch {
  Write-Host "Failed to retrieve Helm releases. Please check your Helm installation."
  exit 1
}

Write-Host "Checking the pods in the $NAMESPACE_SYSTEMS namespace..."
try {
  kubectl get pods -n $NAMESPACE_SYSTEMS
}
catch {
  Write-Host "Failed to retrieve pods in the $NAMESPACE_SYSTEMS namespace. Please check your Kubernetes cluster."
  exit 1
}

Write-Host "Checking the pods in the $NAMESPACE_RUNNERS namespace..."
try {
  kubectl get pods -n $NAMESPACE_RUNNERS
}
catch {
  Write-Host "Failed to retrieve pods in the $NAMESPACE_RUNNERS namespace. Please check your Kubernetes cluster."
  exit 1
}

Write-Host "Next steps:"
Write-Host "1. Monitor the runner pods in the $NAMESPACE_RUNNERS namespace using:"
Write-Host "   kubectl get pods -n $NAMESPACE_RUNNERS"
Write-Host "2. Verify the runners are registered in your GitHub repository under Settings > Actions > Runners."
Write-Host "3. Configure your GitHub Actions workflows to use the runners, do you need to add 'runs-on: $INSTALLATION_NAME' in your workflow files."
Write-Host "4. Adjust the minRunners value in the Helm release if you need to scale the number of runners."
Write-Host "5. For more details, refer to the GitHub Actions Runner Controller documentation at https://docs.github.com/en/actions/tutorials/use-actions-runner-controller/quickstart."