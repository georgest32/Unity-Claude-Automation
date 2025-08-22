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
        $script:Config = Get-Content $script:ConfigFile -Raw | ConvertFrom-Json | ConvertTo-HashTable
        Write-Verbose "Loaded configuration from: $script:ConfigFile"
    } catch {
        Write-Warning "Failed to load configuration file. Using defaults."
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