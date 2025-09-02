# Unity-Claude-RunspaceManagement Core Component
# Core configuration and logging for runspace management
# Part of refactored RunspaceManagement module

$ErrorActionPreference = "Stop"

# Script-level variables for module state
$script:WriteAgentLogAvailable = $false
$script:RunspacePools = @{}
$script:SharedVariables = [System.Collections.Concurrent.ConcurrentDictionary[string, object]]::new()
$script:SessionStates = @{}

# Dependency validation function
function Test-ModuleDependencyAvailability {
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

# Initialize parallel processing module if available
try {
    if (-not (Get-Module Unity-Claude-ParallelProcessing -ErrorAction SilentlyContinue)) {
        Import-Module Unity-Claude-ParallelProcessing -ErrorAction Stop
        Write-Host "[DEBUG] [StatePreservation] Loaded Unity-Claude-ParallelProcessing module" -ForegroundColor Gray
    } else {
        Write-Host "[DEBUG] [StatePreservation] Unity-Claude-ParallelProcessing already loaded, preserving state" -ForegroundColor Gray
    }
    $script:WriteAgentLogAvailable = $true
} catch {
    Write-Warning "Failed to import Unity-Claude-ParallelProcessing: $($_.Exception.Message)"
    Write-Warning "Using Write-Host fallback for logging"
}

# Fallback logging function if Write-AgentLog not available
function Write-FallbackLog {
    param(
        [string]$Message,
        [string]$Level = "INFO"
    )
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $prefix = "[$timestamp] [RunspaceManagement] [$Level]"
    
    switch ($Level) {
        "ERROR" { Write-Host "$prefix $Message" -ForegroundColor Red }
        "WARNING" { Write-Host "$prefix $Message" -ForegroundColor Yellow }
        "SUCCESS" { Write-Host "$prefix $Message" -ForegroundColor Green }
        "DEBUG" { Write-Debug "$prefix $Message" }
        default { Write-Host "$prefix $Message" }
    }
}

# Module logging function with fallback
function Write-ModuleLog {
    param(
        [string]$Message,
        [ValidateSet("INFO", "WARNING", "ERROR", "SUCCESS", "DEBUG")]
        [string]$Level = "INFO"
    )
    
    if ($script:WriteAgentLogAvailable) {
        try {
            Write-AgentLog -Message $Message -Level $Level -Component "RunspaceManagement"
        } catch {
            Write-FallbackLog -Message $Message -Level $Level
        }
    } else {
        Write-FallbackLog -Message $Message -Level $Level
    }
}

# Get runspace pools registry
function Get-RunspacePoolRegistry {
    <#
    .SYNOPSIS
    Returns the current runspace pools registry
    #>
    [CmdletBinding()]
    param()
    
    return $script:RunspacePools.Clone()
}

# Update runspace pool registry
function Update-RunspacePoolRegistry {
    param(
        [string]$PoolName,
        [object]$Pool
    )
    
    $script:RunspacePools[$PoolName] = $Pool
    Write-ModuleLog -Message "Updated runspace pool registry for: $PoolName" -Level "DEBUG"
}

# Get shared variables dictionary
function Get-SharedVariablesDictionary {
    <#
    .SYNOPSIS
    Returns reference to the shared variables concurrent dictionary
    #>
    [CmdletBinding()]
    param()
    
    return $script:SharedVariables
}

# Get session states registry
function Get-SessionStatesRegistry {
    <#
    .SYNOPSIS
    Returns the current session states registry
    #>
    [CmdletBinding()]
    param()
    
    return $script:SessionStates.Clone()
}

# Update session state registry
function Update-SessionStateRegistry {
    param(
        [string]$StateName,
        [object]$State
    )
    
    $script:SessionStates[$StateName] = $State
    Write-ModuleLog -Message "Updated session state registry for: $StateName" -Level "DEBUG"
}

# Export module members
Export-ModuleMember -Function @(
    'Test-ModuleDependencyAvailability',
    'Write-FallbackLog',
    'Write-ModuleLog',
    'Get-RunspacePoolRegistry',
    'Update-RunspacePoolRegistry',
    'Get-SharedVariablesDictionary',
    'Get-SessionStatesRegistry',
    'Update-SessionStateRegistry'
) -Variable @(
    'WriteAgentLogAvailable',
    'RunspacePools',
    'SharedVariables',
    'SessionStates'
)

Write-ModuleLog -Message "RunspaceCore component loaded successfully" -Level "DEBUG"




# SIG # Begin signature block
# MIIFzgYJKoZIhvcNAQcCoIIFvzCCBbsCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCArOcFxF7PReOZp
# arznI3tGX9eqGxoNcsm6tqx6p+o3uqCCAzAwggMsMIICFKADAgECAhB1HRbZIqgr
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
# MAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIEDktHj7V2/h4aeXDJPHwBOD
# vcjQUFbCK63TJny1SXH4MA0GCSqGSIb3DQEBAQUABIIBAD9yi+xfMWnpD31OomSf
# aTAUJUKYSLVCaAaMRegho/tKBA22IqsjAMoFiJYlKOvQHP8Lt0rX3veZMf7HC0kP
# iKxiMXJQOQ8NewFX7AGIC36UunDPJ+63cGVsKV93VjGUgWNiUn8SE6hgdLUT6mXV
# GJiD2xjp5HOyMECso3uIYfLztxyx4/A+ioBx9lAi0Exmdsd0H/9UEdmIotgx+Vqg
# 4FF7bCzUNJbnG/znZ+3t3WW/Kw1c8o92QG/oJt9cMp0xdXHVG0aHLfQ5nw/5JQE4
# sDkbiWYf1ddvRdM2ZpuiggRlaquiwLa1/otZ2MLqt86sUAxncsXJ+/21jVbD0y1p
# DuE=
# SIG # End signature block
