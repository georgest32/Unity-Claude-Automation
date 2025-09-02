# Unity-Claude-RunspaceManagement Module/Variable Preloading Component
# Handles module and variable preloading for session states
# Part of refactored RunspaceManagement module

$ErrorActionPreference = "Stop"

# Import core components with conditional loading and fallback
$CorePath = Join-Path $PSScriptRoot "RunspaceCore.psm1"
$SessionStatePath = Join-Path $PSScriptRoot "SessionStateConfiguration.psm1"

# Check for and load required functions with fallback
try {
    if (-not (Get-Command Write-ModuleLog -ErrorAction SilentlyContinue)) {
        . $CorePath -ErrorAction SilentlyContinue
    }
    if (-not (Get-Command Add-SessionStateVariable -ErrorAction SilentlyContinue)) {
        . $SessionStatePath -ErrorAction SilentlyContinue
    }
} catch {
    Write-Host "[ModuleVariablePreloading] Warning: Could not load dependencies, using fallback logging" -ForegroundColor Yellow
    function Write-ModuleLog {
        param([string]$Message, [string]$Level = "INFO")
        $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        Write-Host "[$timestamp] [ModuleVariablePreloading] [$Level] $Message"
    }
    function Add-SessionStateVariable { param($SessionStateConfig, $Name, $Value, $Description) }
    function Add-SessionStateModule { param($SessionStateConfig, $ModuleName) }
}

# Track registered modules and variables
$script:RegisteredModules = @()
$script:RegisteredVariables = @()

function Import-SessionStateModules {
    <#
    .SYNOPSIS
    Imports critical Unity-Claude modules into session state
    .DESCRIPTION
    Pre-loads essential modules for Unity-Claude automation in runspace pool session state
    .PARAMETER SessionStateConfig
    Session state configuration object
    .PARAMETER ModuleList
    Array of module names to import (defaults to critical Unity-Claude modules)
    .EXAMPLE
    Import-SessionStateModules -SessionStateConfig $config
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [hashtable]$SessionStateConfig,
        [string[]]$ModuleList = @(
            'Unity-Claude-ParallelProcessing',
            'Unity-Claude-SystemStatus'
        )
    )
    
    Write-ModuleLog -Message "Importing critical Unity-Claude modules into session state..." -Level "INFO"
    
    try {
        $importedCount = 0
        $failedCount = 0
        
        foreach ($moduleName in $ModuleList) {
            try {
                # Check if module exists in current session first
                $moduleExists = Get-Module -Name $moduleName -ListAvailable -ErrorAction SilentlyContinue
                
                if ($moduleExists) {
                    Add-SessionStateModule -SessionStateConfig $SessionStateConfig -ModuleName $moduleName
                    $script:RegisteredModules += $moduleName
                    $importedCount++
                    Write-ModuleLog -Message "Successfully imported module: $moduleName" -Level "DEBUG"
                } else {
                    Write-ModuleLog -Message "Module not found: $moduleName" -Level "WARNING"
                    $failedCount++
                }
            } catch {
                Write-ModuleLog -Message "Failed to import module ${moduleName}: $($_.Exception.Message)" -Level "WARNING"
                $failedCount++
            }
        }
        
        $result = @{
            ImportedCount = $importedCount
            FailedCount = $failedCount
            TotalModules = $ModuleList.Count
            SuccessRate = [math]::Round(($importedCount / $ModuleList.Count) * 100, 2)
        }
        
        Write-ModuleLog -Message "Module import completed: $importedCount/$($ModuleList.Count) modules imported successfully ($($result.SuccessRate)%)" -Level "INFO"
        
        return $result
        
    } catch {
        Write-ModuleLog -Message "Failed to import session state modules: $($_.Exception.Message)" -Level "ERROR"
        throw
    }
}

function Initialize-SessionStateVariables {
    <#
    .SYNOPSIS
    Initializes critical variables in session state
    .DESCRIPTION
    Pre-loads essential variables for Unity-Claude automation in runspace pool session state
    .PARAMETER SessionStateConfig
    Session state configuration object
    .PARAMETER Variables
    Hashtable of variables to initialize
    .EXAMPLE
    Initialize-SessionStateVariables -SessionStateConfig $config -Variables @{GlobalStatus=$statusData}
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [hashtable]$SessionStateConfig,
        [hashtable]$Variables = @{}
    )
    
    Write-ModuleLog -Message "Initializing critical variables in session state..." -Level "INFO"
    
    try {
        # Add default Unity-Claude variables
        $defaultVariables = @{
            'UnityClaudeVersion' = '2.0.0'
            'AutomationStartTime' = Get-Date
            'RunspaceMode' = 'Pool'
            'ThreadSafeLogging' = $true
        }
        
        # Merge with provided variables
        $allVariables = $defaultVariables.Clone()
        foreach ($key in $Variables.Keys) {
            $allVariables[$key] = $Variables[$key]
        }
        
        $initializedCount = 0
        
        foreach ($varName in $allVariables.Keys) {
            try {
                Add-SessionStateVariable -SessionStateConfig $SessionStateConfig -Name $varName -Value $allVariables[$varName] -Description "Unity-Claude automation variable"
                $script:RegisteredVariables += $varName
                $initializedCount++
                Write-ModuleLog -Message "Initialized variable: $varName" -Level "DEBUG"
            } catch {
                Write-ModuleLog -Message "Failed to initialize variable ${varName}: $($_.Exception.Message)" -Level "WARNING"
            }
        }
        
        $result = @{
            InitializedCount = $initializedCount
            TotalVariables = $allVariables.Count
            SuccessRate = [math]::Round(($initializedCount / $allVariables.Count) * 100, 2)
        }
        
        Write-ModuleLog -Message "Variable initialization completed: $initializedCount/$($allVariables.Count) variables initialized ($($result.SuccessRate)%)" -Level "INFO"
        
        return $result
        
    } catch {
        Write-ModuleLog -Message "Failed to initialize session state variables: $($_.Exception.Message)" -Level "ERROR"
        throw
    }
}

function Get-SessionStateModules {
    <#
    .SYNOPSIS
    Gets list of modules in session state
    .DESCRIPTION
    Returns information about modules configured in the session state
    .PARAMETER SessionStateConfig
    Session state configuration object
    .EXAMPLE
    Get-SessionStateModules -SessionStateConfig $config
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [hashtable]$SessionStateConfig
    )
    
    try {
        $sessionState = $SessionStateConfig.SessionState
        
        # Get modules from session state (this is limited in PowerShell 5.1)
        $moduleInfo = @{
            RegisteredModules = $script:RegisteredModules
            ModuleCount = $SessionStateConfig.Metadata.ModulesCount
            LastUpdate = Get-Date
        }
        
        Write-ModuleLog -Message "Retrieved session state modules: $($moduleInfo.ModuleCount) modules" -Level "INFO"
        
        return $moduleInfo
        
    } catch {
        Write-ModuleLog -Message "Failed to get session state modules: $($_.Exception.Message)" -Level "ERROR"
        throw
    }
}

function Get-SessionStateVariables {
    <#
    .SYNOPSIS
    Gets list of variables in session state
    .DESCRIPTION
    Returns information about variables configured in the session state
    .PARAMETER SessionStateConfig
    Session state configuration object
    .EXAMPLE
    Get-SessionStateVariables -SessionStateConfig $config
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [hashtable]$SessionStateConfig
    )
    
    try {
        $sessionState = $SessionStateConfig.SessionState
        
        # Get variables from session state
        $variableInfo = @{
            RegisteredVariables = $script:RegisteredVariables
            VariableCount = $SessionStateConfig.Metadata.VariablesCount
            SessionStateVariables = @()
            LastUpdate = Get-Date
        }
        
        # Get variables from session state (limited access in PowerShell 5.1)
        try {
            $variableInfo.SessionStateVariables = $sessionState.Variables | ForEach-Object { 
                @{
                    Name = $_.Name
                    Type = if ($_.Value) { $_.Value.GetType().Name } else { "Unknown" }
                    Description = $_.Description
                }
            }
        } catch {
            Write-ModuleLog -Message "Unable to enumerate session state variables directly" -Level "DEBUG"
        }
        
        Write-ModuleLog -Message "Retrieved session state variables: $($variableInfo.VariableCount) variables" -Level "INFO"
        
        return $variableInfo
        
    } catch {
        Write-ModuleLog -Message "Failed to get session state variables: $($_.Exception.Message)" -Level "ERROR"
        throw
    }
}

# Export functions
Export-ModuleMember -Function @(
    'Import-SessionStateModules',
    'Initialize-SessionStateVariables',
    'Get-SessionStateModules',
    'Get-SessionStateVariables'
)

Write-ModuleLog -Message "ModuleVariablePreloading component loaded successfully" -Level "DEBUG"
# SIG # Begin signature block
# MIIFzgYJKoZIhvcNAQcCoIIFvzCCBbsCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCB0dsD/o/N3Xdz+
# W846pNZeIdNxzE3ELe3H2ThvTOu5JKCCAzAwggMsMIICFKADAgECAhB1HRbZIqgr
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
# MAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIB0Loq0pQoe8djUK1ptG2Tvz
# ABxgALmlj9avmbXLZfdiMA0GCSqGSIb3DQEBAQUABIIBAJ+5RC5aUDRpDz26Sd7j
# +AhqQ7+12H2OZtqYRWYY7fNGN3wM3fXVsx/nhMT0C00zYzYJSMJPJTLOrH3s2T6g
# G6eq8x/ZUZlOjx+gRnOIFpuHRTwOYjkbVMIS4XfOmOU0X6PmtRinXyC7em9oMpHo
# CDq4tSMMWPaeZu4qNwwgh0c3LWcM36T5fPSDmiWKisgoC381rtC3MsHW/eIZ7bSX
# Li9+hLRbKIB9O98HKbBE6Aq18KFJrMxV2TcIkPW9NIjEZuhz7VYvqFAK8GEJvN0D
# qEHO8Jw+hNmvLaymawHCFMQdNa6VhLul+C60AFpDFgINlH7t5NX1QvTHUS2suRZE
# QTY=
# SIG # End signature block
