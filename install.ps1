# Build the project
cargo build --release
if ($LASTEXITCODE -ne 0) {
    Write-Error "Failed to build project"
    exit 1
}

# Default directories
$DEFAULT_ROOT = "$env:LOCALAPPDATA\vuv"
$DEFAULT_VUV_DIR = "$DEFAULT_ROOT\vuv"
$DEFAULT_VUV_CONFIG = "$DEFAULT_ROOT\vuvconfig"
$DEFAULT_VENV_DIR = "$DEFAULT_ROOT\venvs"

# Allow customization through environment variables
$VUV_ROOT = if ($env:VUV_ROOT) { $env:VUV_ROOT } else { $DEFAULT_ROOT }
$VUV_DIR = if ($env:VUV_BIN_DIR) { $env:VUV_BIN_DIR } else { "$VUV_ROOT\vuv" }
$VUV_CONFIG = if ($env:VUV_CONFIG_DIR) { $env:VUV_CONFIG_DIR } else { "$VUV_ROOT\vuvconfig" }
$VENV_DIR = if ($env:VUV_VENV_DIR) { $env:VUV_VENV_DIR } else { "$VUV_ROOT\venvs" }

# Create directories if they don't exist
New-Item -ItemType Directory -Force -Path $VUV_DIR | Out-Null
New-Item -ItemType Directory -Force -Path $VUV_CONFIG | Out-Null
New-Item -ItemType Directory -Force -Path $VENV_DIR | Out-Null

# Copy the binary
Copy-Item "target\release\vuv-rs.exe" "$VUV_DIR\vuv-bin.exe" -Force

# Create PowerShell profile if it doesn't exist
if (!(Test-Path $PROFILE)) {
    New-Item -ItemType File -Path $PROFILE -Force | Out-Null
}

# Create the shell function
$shellFunction = @"
# vuv configuration
`$env:VUV_ROOT = '$VUV_ROOT'
`$env:VUV_BIN_DIR = '$VUV_DIR'
`$env:VUV_CONFIG_DIR = '$VUV_CONFIG'
`$env:VUV_VENV_DIR = '$VENV_DIR'

function vuv {
    param(`$command, `$args)
    
    switch (`$command) {
        'activate' {
            if (-not `$args) {
                Write-Error "Usage: vuv activate <environment_name>"
                return
            }
            `$venvPath = Join-Path `$env:VUV_VENV_DIR `$args
            if (-not (Test-Path `$venvPath)) {
                Write-Error "Virtual environment `$args does not exist"
                return
            }
            `$activateScript = Join-Path `$venvPath "Scripts\Activate.ps1"
            if (Test-Path `$activateScript) {
                . `$activateScript
            } else {
                Write-Error "Activation script not found"
                return
            }
        }
        'deactivate' {
            if (-not `$env:VIRTUAL_ENV) {
                Write-Error "No virtual environment is currently activated"
                return
            }
            deactivate
        }
        default {
            & "`$env:VUV_BIN_DIR\vuv-bin.exe" `$command `$args
        }
    }
}

# Add tab completion for vuv commands
Register-ArgumentCompleter -CommandName vuv -ParameterName command -ScriptBlock {
    param(`$commandName, `$parameterName, `$wordToComplete, `$commandAst, `$fakeBoundParameters)
    
    `$commands = @('activate', 'deactivate', 'create', 'remove', 'list', 'install', 'uninstall', 'config')
    
    if (-not `$wordToComplete) {
        `$commands
    } else {
        `$commands | Where-Object {
            `$_ -like "`$wordToComplete*"
        }
    }
}

# Add tab completion for environment names in 'activate' command
Register-ArgumentCompleter -CommandName vuv -ParameterName args -ScriptBlock {
    param(`$commandName, `$parameterName, `$wordToComplete, `$commandAst, `$fakeBoundParameters)
    
    if (`$fakeBoundParameters['command'] -eq 'activate') {
        Get-ChildItem -Path `$env:VUV_VENV_DIR -Directory | Select-Object -ExpandProperty Name |
        Where-Object { `$_ -like "`$wordToComplete*" }
    }
}
"@

# Add the function to PowerShell profile
$profileContent = Get-Content $PROFILE -Raw -ErrorAction SilentlyContinue
if ($profileContent -notmatch 'function vuv') {
    Add-Content $PROFILE "`n$shellFunction"
}

# Add to PATH if not already there
$userPath = [Environment]::GetEnvironmentVariable("Path", "User")
if ($userPath -notmatch [regex]::Escape($VUV_DIR)) {
    [Environment]::SetEnvironmentVariable("Path", "$userPath;$VUV_DIR", "User")
}

Write-Host "Installation complete!"
Write-Host "Configuration:"
Write-Host "  VUV_ROOT      = $VUV_ROOT"
Write-Host "  VUV_BIN_DIR   = $VUV_DIR"
Write-Host "  VUV_CONFIG_DIR = $VUV_CONFIG"
Write-Host "  VUV_VENV_DIR  = $VENV_DIR"
Write-Host
Write-Host "Directory structure:"
Write-Host "  $VUV_ROOT"
Write-Host "  ├── vuv       (binary and scripts)"
Write-Host "  ├── vuvconfig (configuration files)"
Write-Host "  └── venvs     (virtual environments)"
Write-Host
Write-Host "To customize these locations, set these environment variables before installation:"
Write-Host "  VUV_ROOT      - Root directory for all vuv files"
Write-Host "  VUV_BIN_DIR   - Directory for vuv binary"
Write-Host "  VUV_CONFIG_DIR - Directory for vuv configuration"
Write-Host "  VUV_VENV_DIR  - Directory for virtual environments"
Write-Host
Write-Host "Please restart PowerShell or run:"
Write-Host ". $PROFILE" 