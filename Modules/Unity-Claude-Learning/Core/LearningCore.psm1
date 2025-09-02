# Unity-Claude-Learning Core Component
# Core configuration and shared utilities for learning system
# Part of refactored Learning module

$ErrorActionPreference = "Stop"

# Module configuration state
$script:LearningConfig = @{
    DatabasePath = Join-Path (Split-Path $PSScriptRoot -Parent) "LearningDatabase.db"
    StoragePath = Split-Path $PSScriptRoot -Parent
    StorageBackend = "Unknown"  # Will be detected: "SQLite" or "JSON"
    MaxPatternAge = 30  # Days before pattern expires
    MinConfidence = 0.7  # Minimum confidence for auto-apply
    EnableAutoFix = $false  # Safety switch for self-patching
}

$script:PatternCache = @{}
$script:SuccessMetrics = @{
    TotalAttempts = 0
    SuccessfulFixes = 0
    FailedFixes = 0
    PatternsLearned = 0
}

# Shared logging function
function Write-LearningLog {
    param(
        [string]$Message,
        [ValidateSet("INFO", "WARNING", "ERROR", "DEBUG", "VERBOSE")]
        [string]$Level = "INFO"
    )
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logMessage = "[$timestamp] [Unity-Claude-Learning] [$Level] $Message"
    
    switch ($Level) {
        "ERROR" { Write-Error $logMessage }
        "WARNING" { Write-Warning $logMessage }
        "DEBUG" { Write-Debug $logMessage }
        "VERBOSE" { Write-Verbose $logMessage }
        default { Write-Host $logMessage }
    }
}

# Get configuration
function Get-LearningConfig {
    <#
    .SYNOPSIS
    Gets the current learning module configuration
    
    .DESCRIPTION
    Returns the current configuration settings for the learning module
    #>
    [CmdletBinding()]
    param()
    
    return $script:LearningConfig.Clone()
}

# Set configuration
function Set-LearningConfig {
    <#
    .SYNOPSIS
    Sets learning module configuration
    
    .DESCRIPTION
    Updates configuration settings for the learning module
    #>
    [CmdletBinding()]
    param(
        [string]$DatabasePath,
        [string]$StoragePath,
        [int]$MaxPatternAge,
        [double]$MinConfidence,
        [bool]$EnableAutoFix
    )
    
    if ($PSBoundParameters.ContainsKey('DatabasePath')) {
        $script:LearningConfig.DatabasePath = $DatabasePath
        Write-LearningLog -Message "Updated DatabasePath to: $DatabasePath" -Level "INFO"
    }
    
    if ($PSBoundParameters.ContainsKey('StoragePath')) {
        $script:LearningConfig.StoragePath = $StoragePath
        Write-LearningLog -Message "Updated StoragePath to: $StoragePath" -Level "INFO"
    }
    
    if ($PSBoundParameters.ContainsKey('MaxPatternAge')) {
        $script:LearningConfig.MaxPatternAge = $MaxPatternAge
        Write-LearningLog -Message "Updated MaxPatternAge to: $MaxPatternAge days" -Level "INFO"
    }
    
    if ($PSBoundParameters.ContainsKey('MinConfidence')) {
        $script:LearningConfig.MinConfidence = $MinConfidence
        Write-LearningLog -Message "Updated MinConfidence to: $MinConfidence" -Level "INFO"
    }
    
    if ($PSBoundParameters.ContainsKey('EnableAutoFix')) {
        $script:LearningConfig.EnableAutoFix = $EnableAutoFix
        $status = if ($EnableAutoFix) { "enabled" } else { "disabled" }
        Write-LearningLog -Message "Auto-fix functionality $status" -Level "WARNING"
    }
}

# Get pattern cache
function Get-PatternCache {
    <#
    .SYNOPSIS
    Returns the current pattern cache
    #>
    [CmdletBinding()]
    param()
    
    return $script:PatternCache.Clone()
}

# Update pattern cache
function Update-PatternCache {
    param(
        [string]$Key,
        [object]$Value
    )
    
    $script:PatternCache[$Key] = $Value
    Write-LearningLog -Message "Updated pattern cache for key: $Key" -Level "DEBUG"
}

# Clear pattern cache
function Clear-PatternCache {
    <#
    .SYNOPSIS
    Clears the pattern cache
    #>
    [CmdletBinding()]
    param()
    
    $script:PatternCache.Clear()
    Write-LearningLog -Message "Pattern cache cleared" -Level "INFO"
}

# Get success metrics
function Get-SuccessMetrics {
    <#
    .SYNOPSIS
    Returns current success metrics
    #>
    [CmdletBinding()]
    param()
    
    return $script:SuccessMetrics.Clone()
}

# Update success metrics
function Update-SuccessMetrics {
    param(
        [ValidateSet("TotalAttempts", "SuccessfulFixes", "FailedFixes", "PatternsLearned")]
        [string]$Metric,
        [int]$Increment = 1
    )
    
    $script:SuccessMetrics[$Metric] += $Increment
    Write-LearningLog -Message "Updated $Metric by $Increment (now: $($script:SuccessMetrics[$Metric]))" -Level "DEBUG"
}

# Utility function to measure execution time
function Measure-ExecutionTime {
    <#
    .SYNOPSIS
    Measures the execution time of a script block
    
    .DESCRIPTION
    Utility function to track performance of operations
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [scriptblock]$ScriptBlock,
        
        [string]$Label = "Operation"
    )
    
    $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
    
    try {
        $result = & $ScriptBlock
        $stopwatch.Stop()
        
        return @{
            Result = $result
            ElapsedMilliseconds = $stopwatch.ElapsedMilliseconds
            Success = $true
            Label = $Label
        }
    }
    catch {
        $stopwatch.Stop()
        
        return @{
            Error = $_.Exception.Message
            ElapsedMilliseconds = $stopwatch.ElapsedMilliseconds
            Success = $false
            Label = $Label
        }
    }
}

# Export module members
Export-ModuleMember -Function @(    'Write-LearningLog',
    'Get-LearningConfig',
    'Set-LearningConfig',
    'Get-PatternCache',
    'Update-PatternCache',
    'Clear-PatternCache',
    'Get-SuccessMetrics',
    'Update-SuccessMetrics',
    'Measure-ExecutionTime'
) -Variable @(
    'LearningConfig',
    'PatternCache',
    'SuccessMetrics'
)

Write-LearningLog -Message "LearningCore component loaded successfully" -Level "DEBUG"

# SIG # Begin signature block
# MIIFzgYJKoZIhvcNAQcCoIIFvzCCBbsCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCClyZFzMMpw0DqS
# Ig946ThyzSsJjcBcSl3Cw98K14VraqCCAzAwggMsMIICFKADAgECAhB1HRbZIqgr
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
# MAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIJg1nmMDIR1fgLkc7kYezsbx
# QnYAKb7CGt94/2MlykxKMA0GCSqGSIb3DQEBAQUABIIBAKoaBsDBvq6b5xz5Q0gV
# beRdvowhSLbCzx30B1qsmNdf2lFqjqTwndzdXqTj5AAu839H9RRofZgB/KXatebx
# xYU0nyg8ahx1Oml4z0pteGIl4VO3VIaWHbNb5dl0YbFDZqAbGwIr8nLNxbVfbUDX
# 7sg6giODaIwZ4An6PDDLfWwLtGiZciTsu0djMGEG+0hYWgMdT1Krmt7k0EvT8ghf
# oMBC28Z3XbYzwBpKONQNU107gWfJGNuE669E3RWqTu+yedFjDl9+4j9snPesk4d4
# UJVFAgW2zGu5d/KHlWTRuB5nvtJLOIbGP/oga1JFa5ixIdgEAwYMZMJmkFL4gbN4
# QOE=
# SIG # End signature block
