# Parameters
param (
    [string]$INSTALLATION_NAME,
    [string]$NAMESPACE_SINGLE
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

# Assign default values if they were not loaded
if ([string]::IsNullOrEmpty($INSTALLATION_NAME)) { $INSTALLATION_NAME = "arc-runner-gke" }
if ([string]::IsNullOrEmpty($NAMESPACE_SINGLE)) { $NAMESPACE_SINGLE = "arc-single" }

Write-Host "Uninstalling GitHub Runner Scale Set via Helm..."
try {
  helm uninstall $INSTALLATION_NAME --namespace $NAMESPACE_SINGLE
  Write-Host "GitHub Runner Scale Set uninstalled successfully."
}
catch {
  Write-Host "GitHub Runner Scale Set is not installed or already uninstalled."
}

Write-Host "Uninstalling GitHub Actions Runner Controller via Helm..."
try {
  helm uninstall arc --namespace $NAMESPACE_SINGLE
  Write-Host "GitHub Actions Runner Controller uninstalled successfully."
}
catch {
  Write-Host "GitHub Actions Runner Controller is not installed or already uninstalled."
}

Write-Host ""
Write-Host "Checking installed Helm releases in $NAMESPACE_SINGLE..."
helm list -n $NAMESPACE_SINGLE

Write-Host ""
Write-Host "Uninstallation completed!"