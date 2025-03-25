# Default directories (matching install.ps1)
$DEFAULT_ROOT = "$env:LOCALAPPDATA\vuv"
$DEFAULT_VUV_DIR = "$DEFAULT_ROOT\vuv"
$DEFAULT_VUV_CONFIG = "$DEFAULT_ROOT\vuvconfig"
$DEFAULT_VENV_DIR = "$DEFAULT_ROOT\venvs"

# Get actual directories from environment variables if set
$VUV_ROOT = if ($env:VUV_ROOT_DIR) { $env:VUV_ROOT_DIR } else { $DEFAULT_ROOT }
$VUV_DIR = if ($env:VUV_CONFIG_DIR) { $env:VUV_CONFIG_DIR } else { $DEFAULT_VUV_DIR }
$VUV_CONFIG = if ($env:VUV_CONFIG) { $env:VUV_CONFIG } else { $DEFAULT_VUV_CONFIG }
$VENV_DIR = if ($env:VUV_VENV_DIR) { $env:VUV_VENV_DIR } else { $DEFAULT_VENV_DIR }

Write-Host "This will uninstall vuv and remove all related files and configurations."
Write-Host "The following directories will be removed:"
Write-Host "  Root directory: $VUV_ROOT"
Write-Host "  Program directory: $VUV_DIR"
Write-Host "  Config directory: $VUV_CONFIG"
Write-Host "  Virtual environments: $VENV_DIR"

$keepVenvs = Read-Host "Do you want to keep existing virtual environments? [y/N]"
$keepVenvs = if ($keepVenvs) { $keepVenvs } else { 'n' }

$confirm = Read-Host "Are you sure you want to proceed with uninstallation? [y/N]"
$confirm = if ($confirm) { $confirm } else { 'n' }

if ($confirm -notmatch '^[yY]$') {
    Write-Host "Uninstallation cancelled."
    exit 1
}

# Remove program files and configurations
Write-Host "Removing program files and configurations..."
if (Test-Path $VUV_DIR) {
    Remove-Item -Path $VUV_DIR -Recurse -Force
}
if (Test-Path $VUV_CONFIG) {
    Remove-Item -Path $VUV_CONFIG -Recurse -Force
}

# Remove virtual environments if user didn't choose to keep them
if ($keepVenvs -notmatch '^[yY]$') {
    Write-Host "Removing virtual environments..."
    if (Test-Path $VENV_DIR) {
        Remove-Item -Path $VENV_DIR -Recurse -Force
    }
} else {
    Write-Host "Keeping virtual environments in $VENV_DIR"
}

# Remove root directory if empty
if (Test-Path $VUV_ROOT) {
    $items = Get-ChildItem -Path $VUV_ROOT -Force
    if ($items.Count -eq 0) {
        Remove-Item -Path $VUV_ROOT -Force
    }
}

# Remove environment variables
[System.Environment]::SetEnvironmentVariable('VUV_ROOT_DIR', $null, 'User')
[System.Environment]::SetEnvironmentVariable('VUV_CONFIG_DIR', $null, 'User')
[System.Environment]::SetEnvironmentVariable('VUV_CONFIG', $null, 'User')
[System.Environment]::SetEnvironmentVariable('VUV_VENV_DIR', $null, 'User')

# Update PATH
$userPath = [System.Environment]::GetEnvironmentVariable('Path', 'User')
$newPath = ($userPath -split ';' | Where-Object { $_ -notmatch 'vuv' }) -join ';'
[System.Environment]::SetEnvironmentVariable('Path', $newPath, 'User')

Write-Host "Uninstallation complete!"
Write-Host "Please restart your terminal to apply all changes." 