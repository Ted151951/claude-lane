# claude-lane Installation Script for Windows
# Installs claude-lane with secure DPAPI key storage

param(
    [switch]$Force = $false
)

$ErrorActionPreference = "Stop"

# Configuration
$InstallDir = "$env:USERPROFILE\.local\bin"
$ConfigDir = "$env:USERPROFILE\.claude"
$RepoUrl = "https://github.com/Ted151951/claude-lane"
$TempDir = Join-Path $env:TEMP "claude-lane-install-$(Get-Random)"
$CurrentVersion = "v1.2.0"
$script:IsUpgrade = $false

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

function Test-ExistingInstallation {
    $installedVersion = ""
    
    # Check if claude-lane is already installed
    if (Test-Path "$InstallDir\claude-lane.bat") {
        Write-Status "Found existing claude-lane installation"
        
        # Try to get version from the installed script
        if (Get-Command claude-lane -ErrorAction SilentlyContinue) {
            try {
                $versionOutput = & claude-lane --version 2>$null
                if ($versionOutput -match "v(\d+\.\d+\.\d+)") {
                    $installedVersion = "v$($Matches[1])"
                }
            }
            catch {
                # Version command failed, continue with upgrade
            }
        }
        
        if ($installedVersion) {
            Write-Status "Currently installed version: $installedVersion"
            
            if ($installedVersion -eq $CurrentVersion) {
                Write-Warning "claude-lane $CurrentVersion is already installed"
                Write-Host "Re-running installation to ensure all components are up to date..."
                $script:IsUpgrade = $true
            }
            elseif ([System.Version]($installedVersion -replace 'v','') -lt [System.Version]($CurrentVersion -replace 'v','')) {
                Write-Status "Upgrading from $installedVersion to $CurrentVersion"
                $script:IsUpgrade = $true
            }
            else {
                Write-Warning "Installed version ($installedVersion) is newer than this installer ($CurrentVersion)"
                Write-Host "Proceeding with installation anyway..."
                $script:IsUpgrade = $true
            }
        }
        else {
            Write-Status "Existing installation found but version could not be determined"
            Write-Status "Proceeding with upgrade..."
            $script:IsUpgrade = $true
        }
        
        # Backup existing config if it exists and this is an upgrade
        if ((Test-Path "$ConfigDir\config.yaml") -and $script:IsUpgrade) {
            $backupFile = "$ConfigDir\config.yaml.backup.$(Get-Date -Format 'yyyyMMdd_HHmmss')"
            Copy-Item "$ConfigDir\config.yaml" $backupFile
            Write-Status "Backed up existing config to: $backupFile"
        }
    }
    else {
        Write-Status "No existing installation found - performing fresh installation"
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
    if ($script:IsUpgrade) {
        Write-Status "Upgrading claude-lane..."
    }
    else {
        Write-Status "Installing claude-lane..."
    }
    
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
powershell.exe -ExecutionPolicy Bypass -Command "& '%USERPROFILE%\.claude\scripts\windows\claude-lane.ps1' %*"
"@
    
    Set-Content -Path "$InstallDir\claude-lane.bat" -Value $mainScript
    
    # Copy PowerShell implementation
    $scriptsDir = "$env:USERPROFILE\.claude\scripts\windows"
    New-Item -ItemType Directory -Path $scriptsDir -Force | Out-Null
    
    Copy-Item "$TempDir\claude-lane\scripts\windows\keystore.ps1" -Destination $scriptsDir
    Copy-Item "$TempDir\claude-lane\scripts\windows\claude-lane.ps1" -Destination $scriptsDir
    
    # Copy templates directory for reference
    $templatesDir = "$env:USERPROFILE\.claude\templates"
    New-Item -ItemType Directory -Path $templatesDir -Force | Out-Null
    Copy-Item "$TempDir\claude-lane\templates\config.yaml" -Destination $templatesDir
    
    # Copy configuration template only if it doesn't exist (fresh install)
    if (-not (Test-Path "$ConfigDir\config.yaml")) {
        Copy-Item "$TempDir\claude-lane\templates\config.yaml" -Destination $ConfigDir
        Write-Status "Created default configuration at $ConfigDir\config.yaml"
    }
    elseif ($script:IsUpgrade) {
        Write-Status "Preserved existing configuration at $ConfigDir\config.yaml"
        Write-Status "Updated template available at $templatesDir\config.yaml"
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
    if ($script:IsUpgrade) {
        Write-Success "claude-lane upgraded successfully to $CurrentVersion!"
        Write-Host ""
        Write-Host "Upgrade completed:" -ForegroundColor Green
        Write-Host "• Configuration preserved at $ConfigDir\config.yaml"
        Write-Host "• API keys remain securely stored"
        Write-Host "• Updated template available at $env:USERPROFILE\.claude\templates\config.yaml"
        Write-Host ""
        Write-Host "Test your upgrade:"
        Write-Host "  claude-lane status"
        Write-Host "  claude-lane --version"
        Write-Host ""
        if (Test-Path "$ConfigDir\config.yaml.backup.*") {
            Write-Host "Configuration backup created for safety"
        }
        Write-Host "For upgrade guide: https://github.com/Ted151951/claude-lane/blob/main/UPGRADE.md"
    }
    else {
        Write-Success "claude-lane installed successfully!"
        Write-Host ""
        Write-Host "Next steps:"
        Write-Host "1. Edit your configuration: $ConfigDir\config.yaml"
        Write-Host "2. Store your API keys:"
        Write-Host "   claude-lane set-key official-api sk-ant-api03-..."
        Write-Host "   claude-lane set-key proxy your-proxy-key"
        Write-Host "3. Switch between endpoints:"
        Write-Host "   claude-lane official-api"
        Write-Host "   claude-lane proxy"
        Write-Host ""
        Write-Host "For help: claude-lane help"
    }
    Write-Host "Documentation: https://github.com/Ted151951/claude-lane"
}

function Main {
    Write-Host "🚀 claude-lane Installation Script for Windows" -ForegroundColor Cyan
    Write-Host "=============================================" -ForegroundColor Cyan
    
    # Check for existing installation first
    Test-ExistingInstallation
    
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