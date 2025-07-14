# claude-lane PowerShell Implementation for Windows
# Provides the same functionality as the bash version

# Use $args directly instead of param block for better compatibility

# Debug: Show raw $args
Write-Host "DEBUG: Raw args count: $($args.Count)" -ForegroundColor Red
Write-Host "DEBUG: Raw args content: '$($args -join "', '")'" -ForegroundColor Red

# Configuration
$ConfigDir = "$env:USERPROFILE\.claude"
$ConfigFile = "$ConfigDir\config.yaml"
$LastProfileFile = "$ConfigDir\last_profile"
$KeystoreScript = "$env:USERPROFILE\.claude\scripts\windows\keystore.ps1"
$DefaultProfile = "official-api"

# Global flags
$script:EnvOnly = $false

function Show-Usage {
    Write-Host "claude-lane - Secure Claude API endpoint switcher"
    Write-Host ""
    Write-Host "Usage:"
    Write-Host "  claude-lane [message]               - Use last profile (or official) and run claude"
    Write-Host "  claude-lane <profile> [message]     - Switch to profile and run claude"
    Write-Host "  claude-lane set-key <ref> <key>     - Store an API key securely"
    Write-Host "  claude-lane list                    - List available profiles and stored keys"
    Write-Host "  claude-lane status                  - Show current configuration status"
    Write-Host "  claude-lane --reset                 - Reset to official profile"
    Write-Host "  claude-lane --env-only [profile]    - Only set environment variables"
    Write-Host "  claude-lane help                    - Show this help message"
    Write-Host ""
    Write-Host "Examples:"
    Write-Host "  claude-lane `"Hello, how are you?`"    - Quick chat with last/default profile"
    Write-Host "  claude-lane official `"Write a poem`"  - Use official API to write a poem"
    Write-Host "  claude-lane set-key official sk-ant-api03-..."
    Write-Host "  claude-lane proxy                   - Switch to proxy and run claude interactively"
    Write-Host "  claude-lane --env-only official     - Only set environment, don't run claude"
    Write-Host ""
    Write-Host "Configuration:"
    Write-Host "  Config file: $ConfigFile"
    Write-Host "  Last profile: $LastProfileFile"
    Write-Host "  Keys stored using Windows DPAPI"
}

function Ensure-ConfigDir {
    if (-not (Test-Path $ConfigDir)) {
        New-Item -ItemType Directory -Path $ConfigDir -Force | Out-Null
    }
}

function Save-LastProfile {
    param([string]$Profile)
    Set-Content -Path $LastProfileFile -Value $Profile
}

function Get-LastProfile {
    if (Test-Path $LastProfileFile) {
        return (Get-Content -Path $LastProfileFile -Raw).Trim()
    } else {
        return $DefaultProfile
    }
}

function Get-CurrentProfile {
    if ($env:CLAUDE_LANE_PROFILE) {
        return $env:CLAUDE_LANE_PROFILE
    } else {
        return Get-LastProfile
    }
}

function Show-Status {
    Write-Host "=== claude-lane Status ==="
    Write-Host "Config file: $ConfigFile"
    Write-Host "Last profile file: $LastProfileFile"
    Write-Host ""
    
    $currentProfile = Get-CurrentProfile
    Write-Host "Current/Last profile: $currentProfile"
    
    if ($env:ANTHROPIC_API_KEY) {
        Write-Host "Environment: ANTHROPIC_API_KEY is set"
        Write-Host "Environment: ANTHROPIC_BASE_URL=$($env:ANTHROPIC_BASE_URL)"
    } else {
        Write-Host "Environment: No ANTHROPIC_API_KEY set"
    }
    
    Write-Host ""
    if (Get-Command claude -ErrorAction SilentlyContinue) {
        $claudePath = (Get-Command claude).Source
        Write-Host "Claude CLI: Available ($claudePath)"
    } else {
        Write-Host "Claude CLI: Not found in PATH"
    }
    
    Write-Host ""
    List-ProfilesAndKeys
}

function Call-Keystore {
    param([string[]]$Arguments)
    & powershell.exe -ExecutionPolicy Bypass -File $KeystoreScript @Arguments
}

function Test-ValidProfile {
    param([string]$Profile)
    
    if (-not (Test-Path $ConfigFile)) {
        return $false
    }
    
    $content = Get-Content $ConfigFile
    foreach ($line in $content) {
        if ($line -match "^\s*$Profile\s*:") {
            return $true
        }
    }
    return $false
}

function Parse-YamlProfile {
    param([string]$Profile)
    
    if (-not (Test-Path $ConfigFile)) {
        Write-Error "Config file not found: $ConfigFile"
        exit 1
    }
    
    $content = Get-Content $ConfigFile
    $inEndpoints = $false
    $inProfile = $false
    $baseUrl = ""
    $keyRef = ""
    
    foreach ($line in $content) {
        $trimmedLine = $line.Trim()
        if ($trimmedLine -eq "" -or $trimmedLine.StartsWith("#")) { continue }
        
        # Look for endpoints: section
        if ($trimmedLine -eq "endpoints:") {
            $inEndpoints = $true
            continue
        }
        
        # If we're in endpoints section, look for our profile
        if ($inEndpoints) {
            # Check if this line starts a new profile (2 spaces indentation)
            if ($line -match "^  [a-zA-Z0-9_-]+:") {
                if ($trimmedLine -eq "${Profile}:") {
                    $inProfile = $true
                } else {
                    $inProfile = $false
                }
                continue
            }
            
            # If we're in the target profile, parse the properties (4+ spaces indentation)
            if ($inProfile -and $line -match "^    ") {
                if ($trimmedLine -match "base_url:\s*`"?([^`"]+)`"?") {
                    $baseUrl = $Matches[1]
                }
                elseif ($trimmedLine -match "key_ref:\s*`"?([^`"]+)`"?") {
                    $keyRef = $Matches[1]
                }
            }
        }
    }
    
    if (-not $baseUrl -or -not $keyRef) {
        Write-Error "Profile '$Profile' not found or incomplete"
        exit 1
    }
    
    return @{
        BaseUrl = $baseUrl
        KeyRef = $keyRef
    }
}

function Use-WebLogin {
    param([string[]]$ClaudeArgs = @())
    
    Write-Host "Using Claude CLI's built-in web login..." -ForegroundColor Green
    Write-Host ""
    
    # Auto-run claude if available
    if (Get-Command claude -ErrorAction SilentlyContinue) {
        if ($ClaudeArgs.Count -gt 0) {
            Write-Host "Running: claude $($ClaudeArgs -join ' ')"
            & claude @ClaudeArgs
        } else {
            Write-Host "Running claude interactively..."
            & claude
        }
    } else {
        Write-Host "Claude CLI not found. Please install it first:" -ForegroundColor Red
        Write-Host "Visit: https://github.com/anthropics/claude-cli"
    }
}

function Use-Profile {
    param(
        [string]$Profile,
        [string[]]$ClaudeArgs = @()
    )
    
    if (-not $Profile) {
        Write-Error "Profile name required"
        Show-Usage
        exit 1
    }
    
    # If no config file exists, use Claude CLI's built-in web login
    if (-not (Test-Path $ConfigFile)) {
        Write-Host "No configuration found. Using Claude CLI's built-in web login." -ForegroundColor Green
        Write-Host ""
        Use-WebLogin $ClaudeArgs
        return
    }
    
    $config = Parse-YamlProfile $Profile
    $apiKey = Call-Keystore @("get", $config.KeyRef)
    
    if ($LASTEXITCODE -ne 0) {
        Write-Error "Failed to retrieve API key for '$($config.KeyRef)'"
        Write-Error "Use 'claude-lane set-key $($config.KeyRef) <your-api-key>' to store the key"
        exit 1
    }
    
    # Set environment variables
    $env:ANTHROPIC_API_KEY = $apiKey
    $env:ANTHROPIC_BASE_URL = $config.BaseUrl
    $env:CLAUDE_LANE_PROFILE = $Profile
    
    # Save as last used profile
    Ensure-ConfigDir
    Save-LastProfile $Profile
    
    Write-Host "Switched to profile '$Profile'"
    Write-Host "Base URL: $($config.BaseUrl)"
    Write-Host "Using key: $($config.KeyRef)"
    
    # If ENV_ONLY flag is set, just set environment and exit
    if ($script:EnvOnly) {
        Write-Host ""
        Write-Host "Environment variables set:"
        Write-Host "  ANTHROPIC_API_KEY=***"
        Write-Host "  ANTHROPIC_BASE_URL=$($config.BaseUrl)"
        Write-Host "  CLAUDE_LANE_PROFILE=$Profile"
        return
    }
    
    # Auto-run claude if available
    if (Get-Command claude -ErrorAction SilentlyContinue) {
        Write-Host ""
        if ($ClaudeArgs.Count -gt 0) {
            # Run claude with provided arguments
            Write-Host "Running: claude $($ClaudeArgs -join ' ')"
            & claude @ClaudeArgs
        } else {
            # Run claude interactively
            Write-Host "Running claude interactively..."
            & claude
        }
    } else {
        Write-Host ""
        Write-Host "Claude CLI not found. Environment variables set:"
        Write-Host "  ANTHROPIC_API_KEY=***"
        Write-Host "  ANTHROPIC_BASE_URL=$($config.BaseUrl)"
        Write-Host ""
        Write-Host "To install Claude CLI, visit: https://github.com/anthropics/claude-cli"
        if ($ClaudeArgs.Count -gt 0) {
            Write-Host ""
            Write-Host "You wanted to run: claude $($ClaudeArgs -join ' ')"
        }
    }
}

function List-ProfilesAndKeys {
    Write-Host "=== Available Profiles ==="
    
    if (-not (Test-Path $ConfigFile)) {
        Write-Host "No configuration file found." -ForegroundColor Yellow
        Write-Host ""
        Write-Host "Available options:" -ForegroundColor Green
        Write-Host "  • Run without config (web login): claude-lane" -ForegroundColor Cyan
        Write-Host "    (just type 'claude-lane' without parameters to start chatting)"
        Write-Host ""
        Write-Host "  • Set up API keys for advanced usage:" -ForegroundColor Cyan
        Write-Host "    1. Copy template: Copy-Item `"$env:USERPROFILE\.claude\scripts\windows\..\..\templates\config.yaml`" `"$ConfigFile`""
        Write-Host "    2. Store API key: claude-lane set-key official sk-ant-api03-your-key"
        Write-Host "    3. Use API mode: claude-lane official-api `"Hello`""
        return
    }
    
    # Parse profiles from config file
    $profiles = @()
    $content = Get-Content $ConfigFile
    $inEndpoints = $false
    
    foreach ($line in $content) {
        $trimmed = $line.Trim()
        if ($trimmed -eq "endpoints:") {
            $inEndpoints = $true
            continue
        }
        
        if ($inEndpoints -and $line -match "^  ([a-zA-Z0-9_-]+):") {
            $profileName = $Matches[1]
            
            # Try to get the key_ref for this profile
            $keyRef = ""
            $profileFound = $false
            $inThisProfile = $false
            
            foreach ($configLine in $content) {
                $configTrimmed = $configLine.Trim()
                if ($configTrimmed -eq "${profileName}:") {
                    $inThisProfile = $true
                    continue
                }
                if ($inThisProfile -and $configLine -match "^  [a-zA-Z0-9_-]+:" -and $configTrimmed -ne "${profileName}:") {
                    $inThisProfile = $false
                }
                if ($inThisProfile -and $configLine -match "^    key_ref:\s*`"?([^`"]+)`"?") {
                    $keyRef = $Matches[1]
                    break
                }
            }
            
            # Check if the key exists
            $hasKey = $false
            if ($keyRef) {
                $testKey = Call-Keystore @("get", $keyRef) 2>$null
                $hasKey = ($LASTEXITCODE -eq 0)
            }
            
            $statusIcon = if ($hasKey) { "[OK]" } else { "[--]" }
            $statusText = if ($hasKey) { "has key" } else { "no key" }
            
            Write-Host "  $statusIcon $profileName ($statusText)"
            
            if (-not $hasKey -and $keyRef) {
                Write-Host "      To add key: claude-lane set-key $keyRef sk-your-api-key" -ForegroundColor Gray
            }
        }
    }
    
    Write-Host ""
    Write-Host "=== Usage ==="
    Write-Host "Without config (web login): claude-lane `"Hello`"" -ForegroundColor Green
    Write-Host "With API profile: claude-lane profile-name `"Hello`"" -ForegroundColor Cyan
}

function Parse-Arguments {
    param([string[]]$Args)
    
    $profile = ""
    $claudeArgs = @()
    $i = 0
    
    while ($i -lt $Args.Count) {
        $arg = $Args[$i]
        switch ($arg) {
            "--env-only" {
                $script:EnvOnly = $true
                $i++
            }
            "--reset" {
                $profile = $DefaultProfile
                $i++
            }
            { $_ -in @("--help", "-h", "help") } {
                Show-Usage
                exit 0
            }
            "--version" {
                Write-Host "claude-lane v1.1.0"
                exit 0
            }
            "set-key" {
                if ($Args.Count -ne 3) {
                    Write-Error "'set-key' requires key_ref and api_key arguments"
                    Show-Usage
                    exit 1
                }
                Ensure-ConfigDir
                Call-Keystore @("set", $Args[1], $Args[2])
                exit 0
            }
            "list" {
                List-ProfilesAndKeys
                exit 0
            }
            "status" {
                Show-Status
                exit 0
            }
            { $_.StartsWith("-") } {
                Write-Error "Unknown option '$arg'"
                Show-Usage
                exit 1
            }
            default {
                # Check if this is a known profile
                if (-not $profile -and (Test-ValidProfile $arg)) {
                    $profile = $arg
                    $i++
                } else {
                    # This and all remaining args are for claude
                    $claudeArgs = $Args[$i..($Args.Count-1)]
                    break
                }
            }
        }
    }
    
    # If no profile specified, use last/default
    if (-not $profile) {
        $profile = Get-CurrentProfile
    }
    
    # Use the profile and pass remaining args to claude
    Use-Profile $profile $claudeArgs
}

# Main entry point
function Main {
    param([string[]]$Args)
    
    # Debug: Show what arguments we received
    Write-Host "DEBUG: Received $($Args.Count) arguments: $($Args -join ', ')" -ForegroundColor Magenta
    
    # Handle special case of no arguments
    if ($Args.Count -eq 0) {
        # If no config file, use web login directly
        if (-not (Test-Path $ConfigFile)) {
            Use-WebLogin @()
        } else {
            $lastProfile = Get-CurrentProfile
            # Check if the profile exists and has a key before using it
            if (Test-ValidProfile $lastProfile) {
                $config = Parse-YamlProfile $lastProfile
                $testKey = Call-Keystore @("get", $config.KeyRef) 2>$null
                if ($LASTEXITCODE -eq 0) {
                    # Profile has a valid key, use it
                    Use-Profile $lastProfile
                } else {
                    # Profile exists but no key, show helpful message
                    Write-Host "Profile '$lastProfile' is configured but missing API key." -ForegroundColor Yellow
                    Write-Host "To set up the key: claude-lane set-key $($config.KeyRef) sk-your-api-key"
                    Write-Host "Or use web login: claude-lane (without profile name)"
                    Write-Host ""
                    Use-WebLogin @()
                }
            } else {
                # Invalid profile, fall back to web login
                Write-Host "Last used profile '$lastProfile' not found in config." -ForegroundColor Yellow
                Use-WebLogin @()
            }
        }
        return
    }
    
    # Parse and execute
    Parse-Arguments $Args
}

# Run main function
Main $args