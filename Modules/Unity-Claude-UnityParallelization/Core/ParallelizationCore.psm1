#Requires -Version 5.1
<#
.SYNOPSIS
    Core utilities and configuration for Unity parallelization module.

.DESCRIPTION
    Provides logging, dependency management, and shared configuration
    for Unity parallel monitoring operations.

.NOTES
    Part of Unity-Claude-UnityParallelization refactored architecture
    Originally from Unity-Claude-UnityParallelization.psm1 (lines 1-119)
    Refactoring Date: 2025-08-25
#>

$ErrorActionPreference = "Stop"

#region Module Configuration

# Module-level variables for Unity project management
$script:RegisteredUnityProjects = @{}
$script:ActiveUnityMonitors = @{}
$script:UnityParallelizationConfig = @{
    UnityExecutablePath = ""
    DefaultLogPath = "$env:LOCALAPPDATA\Unity\Editor"
    ErrorPatterns = @{
        CompilationError = '^.*\(\d+,\d+\): error.*$'
        CS0246 = 'CS0246.*could not be found'
        CS0103 = 'CS0103.*does not exist'
        CS1061 = 'CS1061.*does not contain'
        CS0029 = 'CS0029.*cannot implicitly convert'
    }
    MonitoringInterval = 1000  # 1 second
    CompilationTimeout = 300   # 5 minutes
    ErrorDetectionLatency = 500 # 500ms target
}

# Module availability tracking
$script:RequiredModulesAvailable = @{}
$script:WriteModuleLogAvailable = $false

#endregion

#region Dependency Management

function Test-ModuleDependencyAvailability {
    <#
    .SYNOPSIS
    Tests availability of required module dependencies
    .DESCRIPTION
    Validates that required modules are available for the parallelization module
    .PARAMETER RequiredModules
    Array of required module names
    .PARAMETER ModuleName
    Name of the module being checked
    #>
    param(
        [string[]]$RequiredModules,
        [string]$ModuleName = "Unknown"
    )
    
    $missingModules = @()
    foreach ($reqModule in $RequiredModules) {
        $module = Get-Module $reqModule -ErrorAction SilentlyContinue
        if (-not $module) {
            $missingModules += $reqModule
        }
    }
    
    if ($missingModules.Count -gt 0) {
        Write-Warning "[$ModuleName] Missing required modules: $($missingModules -join ', '). Import them explicitly before using this module."
        return $false
    }
    
    return $true
}

# Initialize module dependencies
function Initialize-ModuleDependencies {
    <#
    .SYNOPSIS
    Initializes required module dependencies
    .DESCRIPTION
    Attempts to load required modules and tracks their availability
    #>
    
    # Try to load Unity-Claude-RunspaceManagement
    try {
        if (-not (Get-Module Unity-Claude-RunspaceManagement -ErrorAction SilentlyContinue)) {
            Import-Module Unity-Claude-RunspaceManagement -ErrorAction Stop
            Write-Host "[DEBUG] [StatePreservation] Loaded Unity-Claude-RunspaceManagement module" -ForegroundColor Gray
        } else {
            Write-Host "[DEBUG] [StatePreservation] Unity-Claude-RunspaceManagement already loaded, preserving state" -ForegroundColor Gray
        }
        $script:RequiredModulesAvailable['RunspaceManagement'] = $true
        $script:WriteModuleLogAvailable = $true
    } catch {
        Write-Warning "Failed to import Unity-Claude-RunspaceManagement: $($_.Exception.Message)"
        $script:RequiredModulesAvailable['RunspaceManagement'] = $false
    }
    
    # Try to load Unity-Claude-ParallelProcessing
    try {
        if (-not (Get-Module Unity-Claude-ParallelProcessing -ErrorAction SilentlyContinue)) {
            Import-Module Unity-Claude-ParallelProcessing -ErrorAction Stop
            Write-Host "[DEBUG] [StatePreservation] Loaded Unity-Claude-ParallelProcessing module" -ForegroundColor Gray
        } else {
            Write-Host "[DEBUG] [StatePreservation] Unity-Claude-ParallelProcessing already loaded, preserving state" -ForegroundColor Gray
        }
        $script:RequiredModulesAvailable['ParallelProcessing'] = $true
    } catch {
        Write-Warning "Failed to import Unity-Claude-ParallelProcessing: $($_.Exception.Message)"
        $script:RequiredModulesAvailable['ParallelProcessing'] = $false
    }
}

#endregion

#region Logging Functions

function Write-FallbackLog {
    <#
    .SYNOPSIS
    Fallback logging function when module logging is unavailable
    .DESCRIPTION
    Provides basic console logging when the main logging module is not available
    #>
    param(
        [string]$Message,
        [string]$Level = "INFO",
        [string]$Component = "UnityParallelization"
    )
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss.fff"
    $logMessage = "[$timestamp] [$Level] [$Component] $Message"
    
    switch ($Level) {
        "ERROR" { Write-Host $logMessage -ForegroundColor Red }
        "WARNING" { Write-Host $logMessage -ForegroundColor Yellow }
        "DEBUG" { Write-Host $logMessage -ForegroundColor Gray }
        default { Write-Host $logMessage -ForegroundColor White }
    }
}

function Write-UnityParallelLog {
    <#
    .SYNOPSIS
    Wrapper function for logging with fallback
    .DESCRIPTION
    Attempts to use module logging, falls back to console logging if unavailable
    #>
    param(
        [string]$Message,
        [string]$Level = "INFO", 
        [string]$Component = "UnityParallelization"
    )
    
    if ($script:WriteModuleLogAvailable -and (Get-Command Write-ModuleLog -ErrorAction SilentlyContinue)) {
        Write-ModuleLog -Message $Message -Level $Level -Component $Component
    } else {
        Write-FallbackLog -Message $Message -Level $Level -Component $Component
    }
}

#endregion

#region Configuration Access

function Get-UnityParallelizationConfig {
    <#
    .SYNOPSIS
    Gets the Unity parallelization configuration
    .DESCRIPTION
    Returns the current Unity parallelization configuration settings
    #>
    [CmdletBinding()]
    param()
    
    return $script:UnityParallelizationConfig
}

function Set-UnityParallelizationConfig {
    <#
    .SYNOPSIS
    Sets Unity parallelization configuration values
    .DESCRIPTION
    Updates the Unity parallelization configuration settings
    .PARAMETER Configuration
    Hashtable containing configuration updates
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [hashtable]$Configuration
    )
    
    foreach ($key in $Configuration.Keys) {
        if ($script:UnityParallelizationConfig.ContainsKey($key)) {
            $script:UnityParallelizationConfig[$key] = $Configuration[$key]
            Write-UnityParallelLog -Message "Updated configuration: $key = $($Configuration[$key])" -Level "DEBUG"
        } else {
            Write-UnityParallelLog -Message "Unknown configuration key: $key" -Level "WARNING"
        }
    }
}

#endregion

#region Module Initialization

# Initialize dependencies when module loads
Initialize-ModuleDependencies

# Module loading notification
Write-UnityParallelLog -Message "Unity-Claude-UnityParallelization Core module loaded" -Level "DEBUG"

#endregion

#region Module Exports

Export-ModuleMember -Function @(
    'Test-ModuleDependencyAvailability',
    'Initialize-ModuleDependencies',
    'Write-FallbackLog',
    'Write-UnityParallelLog',
    'Get-UnityParallelizationConfig',
    'Set-UnityParallelizationConfig'
) -Variable @(
    'RegisteredUnityProjects',
    'ActiveUnityMonitors',
    'UnityParallelizationConfig',
    'RequiredModulesAvailable'
)

#endregion

# REFACTORING MARKER: This module was refactored from Unity-Claude-UnityParallelization.psm1 on 2025-08-25
# Original file size: 2084 lines
# This component: Core utilities and configuration (lines 1-119, ~119 lines)
# SIG # Begin signature block
# MIIFzgYJKoZIhvcNAQcCoIIFvzCCBbsCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCDAlHuj5JHXfPYb
# iRyVvIB6+qDZlfulxmDpQmnhL8+FOKCCAzAwggMsMIICFKADAgECAhB1HRbZIqgr
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
# MAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIM6c9/PbUSPLoROyGXw+LgvG
# kjB4GsTYiDmmpQB4ipYgMA0GCSqGSIb3DQEBAQUABIIBABvGJRAYTfxA2C6MA4VI
# 0A89uNIr2i/xnB16/vf8lb9Provr6Z3J+KC9LzfN6ysYakFVqfrRjOniAJqBQaeb
# 26ncGiqFhDyLJ44MN2WV+MROMBrSbIXo6/wWLXIMwtaCi5HLiB46QibkATWgfdRf
# oO/Bgehn/pq5oiUqeB4gsvEkVRejmPT+1/3eh+4rBbBxwsoekoNwbvQNkze6Vmwf
# 9RTO4M0Z8GCxwS4zSro+UfwfkTZslvPeEe8txvLkPLdPbNX6BJmrCB9bf+b2GzbZ
# WGx8abYBjd0rTqSuv1TLA+evd5qsWkNS1A5bzjhI0SbUNkxRIl6nrDNo202GaFRC
# CPI=
# SIG # End signature block
