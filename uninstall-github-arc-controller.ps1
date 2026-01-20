# Parameters
param (
    [string]$INSTALLATION_NAME,
    [string]$NAMESPACE_SYSTEMS,
    [string]$NAMESPACE_RUNNERS
)

# Load variables from .env if it exists and were not provided as parameters
if (Test-Path ".env") {
    Write-Host "Loading variables from .env..."
    Get-Content ".env" | ForEach-Object {
        if ($_ -match '^\s*([a-zA-Z_][a-zA-Z0-9_]*)\s*=\s*(.*)$' -and $_ -notmatch '^#') {
            $name, $value = $matches[1], $matches[2]
            $value = $value -replace '^["'\'']|["'\'']$', ''  # Remove quotes
            
            # Only assign if the parameter was not passed explicitly
            if ((Get-Variable -Name $name -ErrorAction SilentlyContinue) -eq $null -or (Get-Variable -Name $name).Value -eq $null) {
                Set-Variable -Name $name -Value $value -Scope Global
            }
        }
    }
}

# Assign default values if they were not loaded
if ([string]::IsNullOrEmpty($INSTALLATION_NAME)) { $INSTALLATION_NAME = "arc-runner-gke" }
if ([string]::IsNullOrEmpty($NAMESPACE_SYSTEMS)) { $NAMESPACE_SYSTEMS = "arc-systems" }
if ([string]::IsNullOrEmpty($NAMESPACE_RUNNERS)) { $NAMESPACE_RUNNERS = "arc-runners" }

Write-Host "Uninstalling GitHub Runner Scale Set via Helm..."
try {
  helm uninstall $INSTALLATION_NAME --namespace $NAMESPACE_RUNNERS
  Write-Host "GitHub Runner Scale Set uninstalled successfully."
}
catch {
  Write-Host "GitHub Runner Scale Set is not installed or already uninstalled. Continuing..."
  exit 1
}

Write-Host "Uninstalling GitHub Actions Runner Controller via Helm..."
try {
  helm uninstall arc --namespace $NAMESPACE_SYSTEMS
  Write-Host "GitHub Actions Runner Controller uninstalled successfully."
}
catch {
  Write-Host "GitHub Actions Runner Controller is not installed or already uninstalled. Continuing..."
  exit 1
}

Write-Host "Checking the helm list for installed releases..."
try {
  helm list --all-namespaces
}
catch {
  Write-Host "Failed to retrieve Helm releases. Please check your Helm installation."
  exit 1
}

Write-Host "Uninstallation process completed."