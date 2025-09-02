# Unity-Claude-GitHub.psm1
# Root module script for Unity-Claude GitHub Integration
# Phase 4, Week 8, Day 1

# Module variables
$script:ModuleRoot = $PSScriptRoot
$script:ConfigPath = Join-Path $env:APPDATA "Unity-Claude\GitHub"
$script:CredentialPath = Join-Path $script:ConfigPath "github.credential"
$script:ConfigFile = Join-Path $script:ConfigPath "config.json"

# Ensure configuration directory exists
if (-not (Test-Path $script:ConfigPath)) {
    New-Item -Path $script:ConfigPath -ItemType Directory -Force | Out-Null
    Write-Verbose "Created configuration directory: $script:ConfigPath"
}

# Default configuration
$script:DefaultConfig = @{
    MaxRetryAttempts = 5
    BaseRetryDelay = 1
    RateLimitWarningThreshold = 0.8
    DefaultRepository = $null
    DefaultOwner = $null
    EnableDebugLogging = $false
    TokenExpirationWarningDays = 7
    LastTokenRotation = $null
}

# Load configuration
if (Test-Path $script:ConfigFile) {
    try {
        $configContent = Get-Content $script:ConfigFile -Raw -ErrorAction Stop
        if ($configContent -and $configContent.Trim()) {
            $jsonConfig = $configContent | ConvertFrom-Json -ErrorAction Stop
            if ($jsonConfig) {
                $script:Config = ConvertTo-HashTable -InputObject $jsonConfig
                Write-Verbose "Loaded configuration from: $script:ConfigFile"
            } else {
                throw "Config file contains no data"
            }
        } else {
            throw "Config file is empty"
        }
    } catch {
        Write-Verbose "Failed to load configuration file: $_. Using defaults."
        $script:Config = $script:DefaultConfig.Clone()
    }
} else {
    $script:Config = $script:DefaultConfig.Clone()
    Write-Verbose "Using default configuration"
}

# Helper function to convert PSCustomObject to Hashtable
function ConvertTo-HashTable {
    param(
        [Parameter(ValueFromPipeline)]
        $InputObject
    )
    
    process {
        if ($null -eq $InputObject) {
            return $null
        }
        
        if ($InputObject -is [System.Collections.IEnumerable] -and $InputObject -isnot [string]) {
            $collection = @(
                foreach ($object in $InputObject) {
                    ConvertTo-HashTable $object
                }
            )
            Write-Output -NoEnumerate $collection
        } elseif ($InputObject -is [psobject]) {
            $hash = @{}
            foreach ($property in $InputObject.PSObject.Properties) {
                $hash[$property.Name] = ConvertTo-HashTable $property.Value
            }
            $hash
        } else {
            $InputObject
        }
    }
}

# Dot-source public functions
$Public = @(Get-ChildItem -Path "$PSScriptRoot\Public\*.ps1" -ErrorAction SilentlyContinue)
foreach ($import in $Public) {
    try {
        Write-Verbose "Importing public function: $($import.Name)"
        . $import.FullName
    } catch {
        Write-Error "Failed to import public function $($import.Name): $_"
    }
}

# Dot-source private functions
$Private = @(Get-ChildItem -Path "$PSScriptRoot\Private\*.ps1" -ErrorAction SilentlyContinue)
foreach ($import in $Private) {
    try {
        Write-Verbose "Importing private function: $($import.Name)"
        . $import.FullName
    } catch {
        Write-Error "Failed to import private function $($import.Name): $_"
    }
}

# Export public functions (private functions are not exported)
Export-ModuleMember -Function $Public.BaseName

# Module initialization
Write-Verbose "Unity-Claude-GitHub module loaded successfully"
Write-Verbose "Configuration path: $script:ConfigPath"
Write-Verbose "Public functions: $($Public.Count)"
Write-Verbose "Private functions: $($Private.Count)"

# Check for PowerShellForGitHub module (optional dependency)
$script:PowerShellForGitHubAvailable = $false
if (Get-Module -Name PowerShellForGitHub -ListAvailable) {
    $script:PowerShellForGitHubAvailable = $true
    Write-Verbose "PowerShellForGitHub module is available"
} else {
    Write-Verbose @"
PowerShellForGitHub module is not installed.
The Unity-Claude-GitHub module will work without it, but some advanced features may be limited.
To install: Install-Module -Name PowerShellForGitHub
"@
}

# Check for existing credentials
if (Test-Path $script:CredentialPath) {
    Write-Verbose "Found existing GitHub credentials at: $script:CredentialPath"
} else {
    Write-Verbose "No GitHub credentials found. Use Set-GitHubPAT to configure."
}

# Log module loading to unity_claude_automation.log
$moduleParent = Split-Path $PSScriptRoot -Parent
$projectRoot = Split-Path $moduleParent -Parent
$logFile = Join-Path $projectRoot "unity_claude_automation.log"
$timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
$logEntry = "[$timestamp] [INFO] Unity-Claude-GitHub module loaded - Version 1.0.0"
Add-Content -Path $logFile -Value $logEntry -ErrorAction SilentlyContinue
# SIG # Begin signature block
# MIIFzgYJKoZIhvcNAQcCoIIFvzCCBbsCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCAJqoLClLtnEaOt
# 6yX5+jcIM4HdAUP8XFXMHhCbChGPHqCCAzAwggMsMIICFKADAgECAhB1HRbZIqgr
# lUTwkh3hnGtFMA0GCSqGSIb3DQEBCwUAMC4xLDAqBgNVBAMMI1VuaXR5LUNsYXVk
# ZS1BdXRvbWF0aW9uLURldmVsb3BtZW50MB4XDTI1MDgyMDIxMTUxN1oXDTI2MDgy
# MDIxMzUxN1owLjEsMCoGA1UEAwwjVW5pdHktQ2xhdWRlLUF1dG9tYXRpb24tRGV2
# ZWxvcG1lbnQwggEiMA0GCSqGSIb3DQEBAQUAA4IBDwAwggEKAoIBAQCx4feqKdUQ
# 6GufY4umNzlM1Pi8aHUGR8HlfhIWFjsrRAxCxhieRlWbHe0Hw+pVBeX76X57e5Pu
# 4Kxxzu+MxMry0NJYf3yOLRTfhYskHBcLraXUCtrMwqnhPKvul6Sx6Lu8vilk605W
# ADJNifl3WFuexVCYJJM9G2mfuYIDN+rZ5zmpn0qCXum49bm629h+HyJ205Zrn9aB
# hIrA4i/JlrAh1kosWnCo62psl7ixbNVqFqwWEt+gAqSeIo4ChwkOQl7GHmk78Q5I
# oRneY4JTVlKzhdZEYhJGFXeoZml/5jcmUcox4UNYrKdokE7z8ZTmyowBOUNS+sHI
# G1TY5DZSb8vdAgMBAAGjRjBEMA4GA1UdDwEB/wQEAwIHgDATBgNVHSUEDDAKBggr
# BgEFBQcDAzAdBgNVHQ4EFgQUfDms7LrGVboHjmwlSyIjYD/JLQwwDQYJKoZIhvcN
# AQELBQADggEBABRMsfT7DzKy+aFi4HDg0MpxmbjQxOH1lzUzanaECRiyA0sn7+sA
# /4jvis1+qC5NjDGkLKOTCuDzIXnBWLCCBugukXbIO7g392ANqKdHjBHw1WlLvMVk
# 4WSmY096lzpvDd3jJApr/Alcp4KmRGNLnQ3vv+F9Uj58Uo1qjs85vt6fl9xe5lo3
# rFahNHL4ngjgyF8emNm7FItJeNtVe08PhFn0caOX0FTzXrZxGGO6Ov8tzf91j/qK
# QdBifG7Fx3FF7DifNqoBBo55a7q0anz30k8p+V0zllrLkgGXfOzXmA1L37Qmt3QB
# FCdJVigjQMuHcrJsWd8rg857Og0un91tfZIxggH0MIIB8AIBATBCMC4xLDAqBgNV
# BAMMI1VuaXR5LUNsYXVkZS1BdXRvbWF0aW9uLURldmVsb3BtZW50AhB1HRbZIqgr
# lUTwkh3hnGtFMA0GCWCGSAFlAwQCAQUAoIGEMBgGCisGAQQBgjcCAQwxCjAIoAKA
# AKECgAAwGQYJKoZIhvcNAQkDMQwGCisGAQQBgjcCAQQwHAYKKwYBBAGCNwIBCzEO
# MAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEICfJDDCNs0PTGsXr1UWEIpAd
# kuTFILkkI9OLFEMqHM7WMA0GCSqGSIb3DQEBAQUABIIBAEYcYEQZHDcJ3AKrQd3m
# o/sORJLVCwdL244arbCWDsmYjau6VRR8UXfQT31gXuNj8uluRI7MDeuyQ0ShocFp
# g+dKhUa5StpZf7YLmxpnWKPPNMjqzPkoBn/MHWJewuADNsY/S/OPYB3sTQkDwewZ
# HERsnVEhj//Lch1P5omOB6b7p+wqxqlszG2M2jLLJ1eiB8djKkaR7tP7NGaHnlRo
# /34Q2EcvHa2iLtZHvKmN8w5D+zknRcJdNKFHh0RjB2RzfbLGxNHuvhV1AjI10nB9
# hsi7fRDcxoMQn7ZKJAgu5i1F2bqJcz4i3O8600gmGs+fb/8BG2qor18mJbQtZJ6G
# TQw=
# SIG # End signature block
