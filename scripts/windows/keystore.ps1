# Windows DPAPI Key Storage for claude-lane
# Provides secure key storage using Windows Data Protection API

param(
    [Parameter(Mandatory=$true)]
    [ValidateSet("set", "get", "delete", "list")]
    [string]$Action,
    
    [Parameter(Mandatory=$false)]
    [string]$KeyRef,
    
    [Parameter(Mandatory=$false)]
    [string]$ApiKey
)

Add-Type -AssemblyName System.Security

$keyStorePath = Join-Path $env:USERPROFILE ".claude\keys"

function Ensure-KeyStoreDirectory {
    if (-not (Test-Path $keyStorePath)) {
        New-Item -ItemType Directory -Path $keyStorePath -Force | Out-Null
    }
}

function Protect-Data {
    param([string]$data)
    $bytes = [System.Text.Encoding]::UTF8.GetBytes($data)
    $protectedData = [System.Security.Cryptography.ProtectedData]::Protect($bytes, $null, [System.Security.Cryptography.DataProtectionScope]::CurrentUser)
    return [System.Convert]::ToBase64String($protectedData)
}

function Unprotect-Data {
    param([string]$protectedData)
    try {
        $bytes = [System.Convert]::FromBase64String($protectedData)
        $unprotectedBytes = [System.Security.Cryptography.ProtectedData]::Unprotect($bytes, $null, [System.Security.Cryptography.DataProtectionScope]::CurrentUser)
        return [System.Text.Encoding]::UTF8.GetString($unprotectedBytes)
    }
    catch {
        Write-Error "Failed to decrypt key: $($_.Exception.Message)"
        return $null
    }
}

function Set-ApiKey {
    param([string]$keyRef, [string]$apiKey)
    
    Ensure-KeyStoreDirectory
    $keyFile = Join-Path $keyStorePath "$keyRef.key"
    $protectedKey = Protect-Data $apiKey
    Set-Content -Path $keyFile -Value $protectedKey
    Write-Host "Key '$keyRef' stored securely"
}

function Get-ApiKey {
    param([string]$keyRef)
    
    $keyFile = Join-Path $keyStorePath "$keyRef.key"
    if (-not (Test-Path $keyFile)) {
        Write-Error "Key '$keyRef' not found"
        return $null
    }
    
    $protectedKey = Get-Content -Path $keyFile -Raw
    return Unprotect-Data $protectedKey.Trim()
}

function Remove-ApiKey {
    param([string]$keyRef)
    
    $keyFile = Join-Path $keyStorePath "$keyRef.key"
    if (Test-Path $keyFile) {
        Remove-Item $keyFile
        Write-Host "Key '$keyRef' deleted"
    } else {
        Write-Error "Key '$keyRef' not found"
    }
}

function List-ApiKeys {
    if (-not (Test-Path $keyStorePath)) {
        Write-Host "No keys stored"
        return
    }
    
    $keyFiles = Get-ChildItem -Path $keyStorePath -Filter "*.key"
    if ($keyFiles.Count -eq 0) {
        Write-Host "No keys stored"
        return
    }
    
    Write-Host "Stored keys:"
    foreach ($file in $keyFiles) {
        $keyName = $file.BaseName
        Write-Host "  - $keyName"
    }
}

switch ($Action) {
    "set" {
        if (-not $KeyRef -or -not $ApiKey) {
            Write-Error "Both -KeyRef and -ApiKey are required for 'set' action"
            exit 1
        }
        Set-ApiKey $KeyRef $ApiKey
    }
    "get" {
        if (-not $KeyRef) {
            Write-Error "-KeyRef is required for 'get' action"
            exit 1
        }
        $key = Get-ApiKey $KeyRef
        if ($key) {
            Write-Output $key
        } else {
            exit 1
        }
    }
    "delete" {
        if (-not $KeyRef) {
            Write-Error "-KeyRef is required for 'delete' action"
            exit 1
        }
        Remove-ApiKey $KeyRef
    }
    "list" {
        List-ApiKeys
    }
}