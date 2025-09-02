# ParallelProcessorCore.psm1
# Core configuration, logging, and shared utilities for the parallel processing framework

using namespace System.Management.Automation.Runspaces
using namespace System.Collections.Concurrent
using namespace System.Threading

Write-Debug "[ParallelProcessorCore] Module loaded - REFACTORED VERSION"

#region Core Configuration

# Global configuration for parallel processing
$script:ParallelProcessorConfig = @{
    DefaultRetryCount = 3
    DefaultTimeoutSeconds = 300  # 5 minutes
    MaxThreadsLimit = 50  # Reasonable maximum
    OptimalCpuMultiplier = 2  # For mixed workloads
    DebugMode = $false
    VerboseLogging = $false
}

# Thread-safe collections for shared state
$script:GlobalProcessorRegistry = [ConcurrentDictionary[string, object]]::new()
$script:GlobalStatistics = [hashtable]::Synchronized(@{
    TotalProcessorsCreated = 0
    TotalJobsSubmitted = 0
    TotalJobsCompleted = 0
    TotalJobsFailed = 0
    LastActivity = [datetime]::Now
})

#endregion

#region Logging and Debugging

function Write-ParallelProcessorLog {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Message,
        
        [Parameter()]
        [ValidateSet('Debug', 'Verbose', 'Information', 'Warning', 'Error')]
        [string]$Level = 'Information',
        
        [Parameter()]
        [string]$Component = 'ParallelProcessor',
        
        [Parameter()]
        [string]$ProcessorId = 'Unknown'
    )
    
    $timestamp = [datetime]::Now.ToString('yyyy-MM-dd HH:mm:ss.fff')
    $logMessage = "[$timestamp] [$Component-$ProcessorId] $Message"
    
    switch ($Level) {
        'Debug' { 
            if ($script:ParallelProcessorConfig.DebugMode) {
                Write-Debug $logMessage 
            }
        }
        'Verbose' { 
            if ($script:ParallelProcessorConfig.VerboseLogging) {
                Write-Verbose $logMessage 
            }
        }
        'Information' { Write-Information $logMessage -InformationAction Continue }
        'Warning' { Write-Warning $logMessage }
        'Error' { Write-Error $logMessage }
    }
}

function Set-ParallelProcessorDebugMode {
    [CmdletBinding()]
    param(
        [Parameter()]
        [bool]$Enabled = $true
    )
    
    $script:ParallelProcessorConfig.DebugMode = $Enabled
    Write-ParallelProcessorLog "Debug mode set to: $Enabled" -Level Information
}

#endregion

#region Core Utility Functions

function Get-OptimalThreadCount {
    [CmdletBinding()]
    param(
        [Parameter()]
        [ValidateSet('CPU', 'IO', 'Mixed')]
        [string]$WorkloadType = 'Mixed',
        
        [Parameter()]
        [int]$MaxThreads = 0
    )
    
    $cpuCount = [Environment]::ProcessorCount
    
    # Calculate based on workload type
    $optimal = switch ($WorkloadType) {
        'CPU' { $cpuCount }
        'IO' { $cpuCount * 4 }
        'Mixed' { $cpuCount * $script:ParallelProcessorConfig.OptimalCpuMultiplier }
    }
    
    # Apply limits
    if ($MaxThreads -gt 0) {
        $optimal = [Math]::Min($optimal, $MaxThreads)
    }
    
    $optimal = [Math]::Min($optimal, $script:ParallelProcessorConfig.MaxThreadsLimit)
    $optimal = [Math]::Max($optimal, 1)  # Minimum of 1
    
    Write-ParallelProcessorLog "Calculated optimal threads: $optimal (CPU: $cpuCount, Type: $WorkloadType)" -Level Debug
    return $optimal
}

function New-ProcessorId {
    [CmdletBinding()]
    param()
    
    $id = [Guid]::NewGuid().ToString('N')[0..7] -join ''
    Write-ParallelProcessorLog "Generated processor ID: $id" -Level Debug
    return $id
}

function Register-ParallelProcessor {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$ProcessorId,
        
        [Parameter(Mandatory)]
        [object]$ProcessorInstance
    )
    
    $script:GlobalProcessorRegistry[$ProcessorId] = $ProcessorInstance
    $script:GlobalStatistics.TotalProcessorsCreated++
    $script:GlobalStatistics.LastActivity = [datetime]::Now
    
    Write-ParallelProcessorLog "Registered processor: $ProcessorId" -Level Debug -ProcessorId $ProcessorId
}

function Unregister-ParallelProcessor {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$ProcessorId
    )
    
    $removed = $script:GlobalProcessorRegistry.TryRemove($ProcessorId, [ref]$null)
    if ($removed) {
        Write-ParallelProcessorLog "Unregistered processor: $ProcessorId" -Level Debug -ProcessorId $ProcessorId
    }
    return $removed
}

#endregion

#region Validation Functions

function Test-ScriptBlockSafety {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [scriptblock]$ScriptBlock
    )
    
    $scriptText = $ScriptBlock.ToString()
    
    # Basic safety checks
    $dangerousPatterns = @(
        'Remove-Item.*-Recurse',
        'Format-Volume',
        'Clear-Host',
        'Restart-Computer',
        'Stop-Computer'
    )
    
    foreach ($pattern in $dangerousPatterns) {
        if ($scriptText -match $pattern) {
            Write-ParallelProcessorLog "Potentially dangerous script detected: $pattern" -Level Warning
            return $false
        }
    }
    
    return $true
}

function Test-ParameterValidity {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [hashtable]$Parameters
    )
    
    # Check for null or invalid parameters
    foreach ($key in $Parameters.Keys) {
        if ($null -eq $Parameters[$key]) {
            Write-ParallelProcessorLog "Null parameter detected: $key" -Level Warning
            return $false
        }
    }
    
    return $true
}

#endregion

#region Configuration Management

function Get-ParallelProcessorConfiguration {
    [CmdletBinding()]
    param()
    
    return $script:ParallelProcessorConfig.Clone()
}

function Set-ParallelProcessorConfiguration {
    [CmdletBinding()]
    param(
        [Parameter()]
        [int]$DefaultRetryCount,
        
        [Parameter()]
        [int]$DefaultTimeoutSeconds,
        
        [Parameter()]
        [int]$MaxThreadsLimit,
        
        [Parameter()]
        [int]$OptimalCpuMultiplier,
        
        [Parameter()]
        [bool]$VerboseLogging
    )
    
    if ($PSBoundParameters.ContainsKey('DefaultRetryCount')) {
        $script:ParallelProcessorConfig.DefaultRetryCount = $DefaultRetryCount
    }
    
    if ($PSBoundParameters.ContainsKey('DefaultTimeoutSeconds')) {
        $script:ParallelProcessorConfig.DefaultTimeoutSeconds = $DefaultTimeoutSeconds
    }
    
    if ($PSBoundParameters.ContainsKey('MaxThreadsLimit')) {
        $script:ParallelProcessorConfig.MaxThreadsLimit = $MaxThreadsLimit
    }
    
    if ($PSBoundParameters.ContainsKey('OptimalCpuMultiplier')) {
        $script:ParallelProcessorConfig.OptimalCpuMultiplier = $OptimalCpuMultiplier
    }
    
    if ($PSBoundParameters.ContainsKey('VerboseLogging')) {
        $script:ParallelProcessorConfig.VerboseLogging = $VerboseLogging
    }
    
    Write-ParallelProcessorLog "Configuration updated" -Level Information
}

function Get-GlobalParallelProcessorStatistics {
    [CmdletBinding()]
    param()
    
    $stats = $script:GlobalStatistics.Clone()
    $stats.ActiveProcessors = $script:GlobalProcessorRegistry.Count
    $stats.LastActivity = $script:GlobalStatistics.LastActivity
    
    return $stats
}

#endregion

# Export functions
Export-ModuleMember -Function @(
    'Write-ParallelProcessorLog',
    'Set-ParallelProcessorDebugMode',
    'Get-OptimalThreadCount',
    'New-ProcessorId',
    'Register-ParallelProcessor',
    'Unregister-ParallelProcessor',
    'Test-ScriptBlockSafety',
    'Test-ParameterValidity',
    'Get-ParallelProcessorConfiguration',
    'Set-ParallelProcessorConfiguration',
    'Get-GlobalParallelProcessorStatistics'
) -Variable @() -Alias @()
# Added by Fix-ParallelProcessorExports
Export-ModuleMember -Function Get-OptimalThreadCount


# SIG # Begin signature block
# MIIFzgYJKoZIhvcNAQcCoIIFvzCCBbsCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCDcxsQgs5Q4+XiY
# kIAs/MPWWGZa2TTFP+1UbqZzIgwLvaCCAzAwggMsMIICFKADAgECAhB1HRbZIqgr
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
# MAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIIuVYOezao8hVJf0Mm9yWoTg
# vVOfyNDV8DTbUn4Drm6vMA0GCSqGSIb3DQEBAQUABIIBAKAgOE9on7agFkexvxq7
# ZKFtbbvLUo+uQ3Jd/S5bslHxKqqVv/lTobHtD3mtoFTTzFMB7nL5GtRq9raCIovz
# aAXq+uAO+Qw7TRgvg3j33Pa6oodWCknm3yEWZ/mPPoCkh8JOYCjMgVkxj2PxR2y/
# gZNzQlnBhsMt9nDIXBefG4DSEZrdtzFuEGKypkjY6AUEbPxNMhGMe4yglEHIJ7cH
# l5RFGv9ejgqlp6qFQ2iO2GRcidCB0I5Ka8Dxt5xmnaVKLRWkifApweFF7EsQ5d4W
# Xu9Iq2qAAGnTVgRCMnlqBqyT1xxYZjYOhqU9E9OOr76nHS+hYZfDhQ979lpCbEZg
# wyw=
# SIG # End signature block
