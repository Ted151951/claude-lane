# claude-lane Installation Script for Windows
# Installs claude-lane with secure DPAPI key storage

param(
    [switch]$Force = $false
)

$ErrorActionPreference = "Stop"

# Configuration
$InstallDir = "$env:USERPROFILE\.local\bin"
$ConfigDir = "$env:USERPROFILE\.claude"
$RepoUrl = "https://github.com/yourusername/claude-lane"
$TempDir = Join-Path $env:TEMP "claude-lane-install-$(Get-Random)"

function Write-Status {
    param([string]$Message)
    Write-Host "[INFO] $Message" -ForegroundColor Blue
}

function Write-Success {
    param([string]$Message)
    Write-Host "[SUCCESS] $Message" -ForegroundColor Green
}

function Write-Warning {
    param([string]$Message)
    Write-Host "[WARNING] $Message" -ForegroundColor Yellow
}

function Write-Error {
    param([string]$Message)
    Write-Host "[ERROR] $Message" -ForegroundColor Red
}

function Test-PowerShellVersion {
    if ($PSVersionTable.PSVersion.Major -lt 5) {
        Write-Error "PowerShell 5.0 or later is required. Current version: $($PSVersionTable.PSVersion)"
        exit 1
    }
}

function Test-ExecutionPolicy {
    $currentPolicy = Get-ExecutionPolicy -Scope CurrentUser
    if ($currentPolicy -eq "Restricted") {
        Write-Warning "Current execution policy is Restricted."
        Write-Status "Attempting to set execution policy to RemoteSigned for current user..."
        
        try {
            Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser -Force
            Write-Success "Execution policy updated to RemoteSigned"
        }
        catch {
            Write-Error "Failed to update execution policy. Please run:"
            Write-Error "Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser"
            exit 1
        }
    }
}

function Download-ClaudeLane {
    Write-Status "Downloading claude-lane..."
    
    # Create temp directory
    New-Item -ItemType Directory -Path $TempDir -Force | Out-Null
    
    try {
        # Try to use git first
        if (Get-Command git -ErrorAction SilentlyContinue) {
            & git clone $RepoUrl "$TempDir\claude-lane"
        }
        else {
            # Fallback to downloading ZIP
            $zipUrl = "$RepoUrl/archive/main.zip"
            $zipPath = "$TempDir\claude-lane.zip"
            
            Invoke-WebRequest -Uri $zipUrl -OutFile $zipPath
            Expand-Archive -Path $zipPath -DestinationPath $TempDir
            Move-Item "$TempDir\claude-lane-main" "$TempDir\claude-lane"
        }
        
        if (-not (Test-Path "$TempDir\claude-lane")) {
            throw "Failed to download claude-lane repository"
        }
    }
    catch {
        Write-Error "Failed to download claude-lane: $($_.Exception.Message)"
        exit 1
    }
}

function Install-ClaudeLane {
    Write-Status "Installing claude-lane..."
    
    # Create installation directories
    New-Item -ItemType Directory -Path $InstallDir -Force | Out-Null
    New-Item -ItemType Directory -Path $ConfigDir -Force | Out-Null
    
    # Copy main script (convert to .bat for Windows)
    $mainScript = @"
@echo off
setlocal enabledelayedexpansion

rem claude-lane Windows Batch Wrapper
rem This wrapper calls the PowerShell implementation

set "SCRIPT_DIR=%~dp0"
set "PROJECT_ROOT=%SCRIPT_DIR%.."
set "CONFIG_DIR=%USERPROFILE%\.claude"

rem Call the PowerShell script with all arguments
powershell.exe -ExecutionPolicy Bypass -File "%PROJECT_ROOT%\scripts\windows\claude-lane.ps1" %*
"@
    
    Set-Content -Path "$InstallDir\claude-lane.bat" -Value $mainScript
    
    # Copy PowerShell implementation
    $scriptsDir = "$env:USERPROFILE\.claude\scripts\windows"
    New-Item -ItemType Directory -Path $scriptsDir -Force | Out-Null
    
    Copy-Item "$TempDir\claude-lane\scripts\windows\keystore.ps1" -Destination $scriptsDir
    
    # Create the main PowerShell script
    $mainPsScript = Get-Content "$TempDir\claude-lane\bin\claude-lane" -Raw
    
    # Convert bash script to PowerShell (simplified version)
    $windowsPsScript = @"
# claude-lane PowerShell Implementation for Windows
param(
    [Parameter(Position=0)]
    [string]`$Action,
    
    [Parameter(Position=1)]
    [string]`$Param1,
    
    [Parameter(Position=2)]
    [string]`$Param2
)

`$ConfigDir = "`$env:USERPROFILE\.claude"
`$ConfigFile = "`$ConfigDir\config.yaml"
`$KeystoreScript = "`$env:USERPROFILE\.claude\scripts\windows\keystore.ps1"

function Show-Usage {
    Write-Host "claude-lane - Secure Claude API endpoint switcher"
    Write-Host ""
    Write-Host "Usage:"
    Write-Host "  claude-lane <profile>           - Use the specified profile"
    Write-Host "  claude-lane set-key <ref> <key> - Store an API key securely"
    Write-Host "  claude-lane list                - List available profiles and keys"
    Write-Host "  claude-lane help                - Show this help"
}

function Call-Keystore {
    param([string[]]`$Arguments)
    & powershell.exe -ExecutionPolicy Bypass -File `$KeystoreScript @Arguments
}

function Parse-YamlProfile {
    param([string]`$Profile)
    
    if (-not (Test-Path `$ConfigFile)) {
        Write-Error "Config file not found: `$ConfigFile"
        exit 1
    }
    
    `$content = Get-Content `$ConfigFile
    `$inProfile = `$false
    `$baseUrl = ""
    `$keyRef = ""
    
    foreach (`$line in `$content) {
        `$line = `$line.Trim()
        if (`$line -eq "" -or `$line.StartsWith("#")) { continue }
        
        if (`$line -eq "`${Profile}:") {
            `$inProfile = `$true
            continue
        }
        
        if (`$line -match "^[a-zA-Z0-9_-]+:" -and `$line -ne "`${Profile}:") {
            `$inProfile = `$false
            continue
        }
        
        if (`$inProfile) {
            if (`$line -match "base_url:\s*`"?([^`"]+)`"?") {
                `$baseUrl = `$Matches[1]
            }
            elseif (`$line -match "key_ref:\s*`"?([^`"]+)`"?") {
                `$keyRef = `$Matches[1]
            }
        }
    }
    
    if (-not `$baseUrl -or -not `$keyRef) {
        Write-Error "Profile '`$Profile' not found or incomplete"
        exit 1
    }
    
    return @{
        BaseUrl = `$baseUrl
        KeyRef = `$keyRef
    }
}

function Use-Profile {
    param([string]`$Profile)
    
    `$config = Parse-YamlProfile `$Profile
    `$apiKey = Call-Keystore @("get", `$config.KeyRef)
    
    if (`$LASTEXITCODE -ne 0) {
        Write-Error "Failed to retrieve API key for '`$(`$config.KeyRef)'"
        Write-Error "Use 'claude-lane set-key `$(`$config.KeyRef) <your-api-key>' to store the key"
        exit 1
    }
    
    `$env:ANTHROPIC_API_KEY = `$apiKey
    `$env:ANTHROPIC_BASE_URL = `$config.BaseUrl
    
    Write-Host "Switched to profile '`$Profile'"
    Write-Host "Base URL: `$(`$config.BaseUrl)"
    Write-Host "Using key: `$(`$config.KeyRef)"
    
    if (Get-Command claude -ErrorAction SilentlyContinue) {
        Write-Host ""
        Write-Host "Environment configured. You can now use the 'claude' command."
    }
}

function List-ProfilesAndKeys {
    Write-Host "=== Available Profiles ==="
    if (Test-Path `$ConfigFile) {
        `$content = Get-Content `$ConfigFile
        foreach (`$line in `$content) {
            if (`$line -match "^[a-zA-Z0-9_-]+:") {
                `$profile = `$line -replace ":.*", ""
                Write-Host "  - `$profile"
            }
        }
    }
    else {
        Write-Host "No configuration file found"
    }
    
    Write-Host ""
    Write-Host "=== Stored Keys ==="
    Call-Keystore @("list")
}

# Main command dispatch
switch (`$Action) {
    "set-key" {
        if (-not `$Param1 -or -not `$Param2) {
            Write-Error "'set-key' requires key_ref and api_key arguments"
            Show-Usage
            exit 1
        }
        if (-not (Test-Path `$ConfigDir)) {
            New-Item -ItemType Directory -Path `$ConfigDir -Force | Out-Null
        }
        Call-Keystore @("set", `$Param1, `$Param2)
    }
    "list" {
        List-ProfilesAndKeys
    }
    { `$_ -in @("help", "-h", "--help", "") } {
        Show-Usage
    }
    default {
        Use-Profile `$Action
    }
}
"@
    
    Set-Content -Path "$scriptsDir\claude-lane.ps1" -Value $windowsPsScript
    
    # Copy configuration template if it doesn't exist
    if (-not (Test-Path "$ConfigDir\config.yaml")) {
        Copy-Item "$TempDir\claude-lane\templates\config.yaml" -Destination $ConfigDir
        Write-Status "Created default configuration at $ConfigDir\config.yaml"
    }
}

function Update-Path {
    # Check if install directory is in PATH
    $currentPath = [Environment]::GetEnvironmentVariable("PATH", "User")
    if ($currentPath -notlike "*$InstallDir*") {
        $newPath = "$InstallDir;$currentPath"
        [Environment]::SetEnvironmentVariable("PATH", $newPath, "User")
        Write-Success "Added $InstallDir to user PATH"
        Write-Warning "Please restart your terminal or run 'refreshenv' to use claude-lane"
    }
}

function Remove-TempFiles {
    if (Test-Path $TempDir) {
        Remove-Item -Path $TempDir -Recurse -Force
    }
}

function Show-NextSteps {
    Write-Success "claude-lane installed successfully!"
    Write-Host ""
    Write-Host "Next steps:"
    Write-Host "1. Edit your configuration: $ConfigDir\config.yaml"
    Write-Host "2. Store your API keys:"
    Write-Host "   claude-lane set-key official sk-ant-api03-..."
    Write-Host "   claude-lane set-key proxy your-proxy-key"
    Write-Host "3. Switch between endpoints:"
    Write-Host "   claude-lane official"
    Write-Host "   claude-lane proxy"
    Write-Host ""
    Write-Host "For help: claude-lane help"
}

function Main {
    Write-Host "🚀 claude-lane Installation Script for Windows" -ForegroundColor Cyan
    Write-Host "=============================================" -ForegroundColor Cyan
    
    # Pre-flight checks
    Test-PowerShellVersion
    Test-ExecutionPolicy
    
    try {
        # Download and install
        Download-ClaudeLane
        Install-ClaudeLane
        Update-Path
        
        # Show next steps
        Show-NextSteps
    }
    finally {
        # Cleanup
        Remove-TempFiles
    }
}

# Run main installation
Main