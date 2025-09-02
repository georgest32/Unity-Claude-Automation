# CoreUtilities.psm1
# Core utility functions for autonomous state tracking
# Refactored component from Unity-Claude-AutonomousStateTracker-Enhanced.psm1
# Component: Core utilities and helper functions (220 lines)

#region Core Utility Functions

function ConvertTo-HashTable {
    <#
    .SYNOPSIS
    Convert PSCustomObject to hashtable recursively for JSON compatibility
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        $Object,
        
        [switch]$Recurse
    )
    
    if ($null -eq $Object) {
        return $null
    }
    
    if ($Object -is [System.Collections.IDictionary]) {
        $hashTable = @{}
        foreach ($key in $Object.Keys) {
            if ($Recurse -and $null -ne $Object[$key] -and 
                ($Object[$key].GetType().Name -eq 'PSCustomObject' -or $Object[$key] -is [System.Collections.IDictionary])) {
                $hashTable[$key] = ConvertTo-HashTable -Object $Object[$key] -Recurse
            } else {
                $hashTable[$key] = $Object[$key]
            }
        }
        return $hashTable
    }
    
    if ($Object.GetType().Name -eq 'PSCustomObject') {
        $hashTable = @{}
        $Object.PSObject.Properties | ForEach-Object {
            if ($Recurse -and $null -ne $_.Value -and 
                ($_.Value.GetType().Name -eq 'PSCustomObject' -or $_.Value -is [System.Collections.IDictionary])) {
                $hashTable[$_.Name] = ConvertTo-HashTable -Object $_.Value -Recurse
            } else {
                $hashTable[$_.Name] = $_.Value
            }
        }
        return $hashTable
    }
    
    if ($Object -is [Array]) {
        $arrayResult = @()
        foreach ($item in $Object) {
            if ($Recurse -and $null -ne $item -and 
                ($item.GetType().Name -eq 'PSCustomObject' -or $item -is [System.Collections.IDictionary])) {
                $arrayResult += ConvertTo-HashTable -Object $item -Recurse
            } else {
                $arrayResult += $item
            }
        }
        return $arrayResult
    }
    
    return $Object
}

function Get-SafeDateTime {
    <#
    .SYNOPSIS
    Safe DateTime conversion that handles various input types and prevents exceptions
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        $DateTimeObject
    )
    
    try {
        if ($null -eq $DateTimeObject) {
            Write-Warning "Get-SafeDateTime: Null DateTime object provided"
            return $null
        }
        
        # Handle different input types
        if ($DateTimeObject -is [DateTime]) {
            return $DateTimeObject
        }
        
        if ($DateTimeObject -is [string]) {
            $parsedDate = $null
            if ([DateTime]::TryParse($DateTimeObject, [ref]$parsedDate)) {
                return $parsedDate
            } else {
                Write-Warning "Get-SafeDateTime: Failed to parse string '$DateTimeObject' as DateTime"
                return $null
            }
        }
        
        # Try to convert using DateTime constructor
        $convertedDate = [DateTime]$DateTimeObject
        return $convertedDate
        
    } catch {
        Write-Warning "Get-SafeDateTime: Exception converting DateTime: $($_.Exception.Message)"
        return $null
    }
}

function Get-UptimeMinutes {
    <#
    .SYNOPSIS
    Calculate uptime in minutes with proper error handling and type safety
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        $StartTime
    )
    
    try {
        # Get current time as ticks only - avoid DateTime object operations
        $currentTicks = [long](Get-Date).Ticks
        
        # Convert StartTime to DateTime safely and extract ticks
        $startDateTime = Get-SafeDateTime -DateTimeObject $StartTime
        if ($null -eq $startDateTime) {
            return 0.0
        }
        
        $startTicks = [long]$startDateTime.Ticks
        
        # Calculate difference using only arithmetic (no DateTime operations)
        # Force explicit conversion to [long] to avoid type ambiguity
        if ([long]$currentTicks -ge [long]$startTicks) {
            $ticksDifference = [long]$currentTicks - [long]$startTicks
            # Convert ticks to minutes: 1 tick = 100 nanoseconds, 1 minute = 600,000,000 ticks
            $uptimeMinutes = [double]([long]$ticksDifference / 600000000.0)
            
            return [double]$uptimeMinutes
        } else {
            return 0.0
        }
        
    } catch {
        Write-Warning "Get-UptimeMinutes: Exception occurred: $($_.Exception.Message)"
        return 0.0
    }
}

function Write-EnhancedStateLog {
    <#
    .SYNOPSIS
    Enhanced logging with multiple output methods and performance tracking
    #>
    param(
        [string]$Message,
        [ValidateSet("INFO", "WARNING", "ERROR", "DEBUG", "PERFORMANCE", "INTERVENTION")]
        [string]$Level = "INFO",
        [string]$Component = "Enhanced-StateTracker",
        [hashtable]$AdditionalData = @{}
    )
    
    # Get configuration from StateConfiguration module
    $stateConfig = Get-EnhancedStateConfig
    if (-not $stateConfig) {
        Write-Warning "StateConfiguration not available, using default logging"
        Write-Host "[$Level] [$Component] $Message"
        return
    }
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss.fff"
    $logEntry = "[$timestamp] [$Level] [$Component] $Message"
    
    # Add additional data if provided
    if ($AdditionalData.Count -gt 0) {
        $dataJson = $AdditionalData | ConvertTo-Json -Compress
        $logEntry += " | Data: $dataJson"
    }
    
    # Console output with colors
    $color = switch ($Level) {
        "INFO" { "White" }
        "WARNING" { "Yellow" }
        "ERROR" { "Red" }
        "DEBUG" { "Gray" }
        "PERFORMANCE" { "Cyan" }
        "INTERVENTION" { "Magenta" }
    }
    
    if ($Level -ne "DEBUG" -or $stateConfig.VerboseLogging) {
        Write-Host $logEntry -ForegroundColor $color
    }
    
    # File logging based on level
    $logFile = switch ($Level) {
        "PERFORMANCE" { $stateConfig.PerformanceLogFile }
        "INTERVENTION" { $stateConfig.InterventionLogFile }
        default { $stateConfig.LogFile }
    }
    
    try {
        $logEntry | Out-File -FilePath (Join-Path $stateConfig.StateDataPath $logFile) -Append -Encoding UTF8
    } catch {
        Write-Warning "Failed to write to log file: $($_.Exception.Message)"
    }
    
    # Event log for critical items
    if ($Level -in @("ERROR", "INTERVENTION") -and $stateConfig.NotificationMethods -contains "Event") {
        try {
            Write-EventLog -LogName Application -Source "Unity-Claude-Automation" -EventId 1001 -EntryType Information -Message $logEntry
        } catch {
            # Event source may not exist, ignore for now
        }
    }
}

function Get-SystemPerformanceMetrics {
    <#
    .SYNOPSIS
    Collect comprehensive system performance metrics using Get-Counter
    #>
    [CmdletBinding()]
    param()
    
    try {
        $metrics = @{}
        $timestamp = Get-Date
        
        # Get performance counters configuration
        $performanceCounters = Get-PerformanceCounters
        if (-not $performanceCounters) {
            Write-Warning "Performance counters configuration not available"
            return @{}
        }
        
        # Get state configuration for thresholds
        $stateConfig = Get-EnhancedStateConfig
        
        # Collect all performance counters in one operation for efficiency
        $counterPaths = $performanceCounters.Values | ForEach-Object { $_.CounterPath }
        $counterData = Get-Counter -Counter $counterPaths -ErrorAction SilentlyContinue
        
        foreach ($counter in $performanceCounters.GetEnumerator()) {
            $counterName = $counter.Key
            $counterConfig = $counter.Value
            
            $counterValue = $counterData.CounterSamples | Where-Object { $_.Path -like "*$($counterConfig.CounterPath.Split('\')[-1])*" } | Select-Object -First 1
            
            if ($counterValue) {
                $value = [math]::Round($counterValue.CookedValue, 2)
                $status = "Normal"
                
                if ($value -ge $counterConfig.ThresholdCritical) {
                    $status = "Critical"
                } elseif ($value -ge $counterConfig.ThresholdWarning) {
                    $status = "Warning"
                }
                
                $metrics[$counterName] = @{
                    Value = $value
                    Unit = $counterConfig.Unit
                    Status = $status
                    Timestamp = $timestamp
                    ThresholdWarning = $counterConfig.ThresholdWarning
                    ThresholdCritical = $counterConfig.ThresholdCritical
                }
            }
        }
        
        # Add PowerShell-specific metrics if state config available
        if ($stateConfig) {
            $psProcess = Get-Process -Id $PID
            $metrics["PowerShellMemory"] = @{
                Value = [math]::Round($psProcess.WorkingSet64 / 1MB, 2)
                Unit = "MB"
                Status = if ($psProcess.WorkingSet64 / 1MB -gt $stateConfig.MaxMemoryUsageMB) { "Warning" } else { "Normal" }
                Timestamp = $timestamp
            }
            
            $metrics["PowerShellCPU"] = @{
                Value = [math]::Round($psProcess.CPU, 2)
                Unit = "Seconds"
                Status = "Normal"
                Timestamp = $timestamp
            }
        }
        
        return $metrics
        
    } catch {
        Write-EnhancedStateLog -Message "Failed to collect performance metrics: $($_.Exception.Message)" -Level "ERROR"
        return @{}
    }
}

function Test-SystemHealthThresholds {
    <#
    .SYNOPSIS
    Test system health against configured thresholds and trigger interventions if needed
    #>
    [CmdletBinding()]
    param(
        [hashtable]$PerformanceMetrics
    )
    
    $healthIssues = @()
    $criticalIssues = @()
    
    foreach ($metric in $PerformanceMetrics.GetEnumerator()) {
        $metricName = $metric.Key
        $metricData = $metric.Value
        
        if ($metricData.Status -eq "Critical") {
            $criticalIssues += "$metricName is critical: $($metricData.Value) $($metricData.Unit)"
        } elseif ($metricData.Status -eq "Warning") {
            $healthIssues += "$metricName is elevated: $($metricData.Value) $($metricData.Unit)"
        }
    }
    
    return @{
        HealthIssues = $healthIssues
        CriticalIssues = $criticalIssues
        RequiresIntervention = $criticalIssues.Count -gt 0
        RequiresAttention = $healthIssues.Count -gt 0
    }
}

# Export functions
Export-ModuleMember -Function @(
    'ConvertTo-HashTable',
    'Get-SafeDateTime',
    'Get-UptimeMinutes',
    'Write-EnhancedStateLog',
    'Get-SystemPerformanceMetrics',
    'Test-SystemHealthThresholds'
)

#endregion
# SIG # Begin signature block
# MIIFzgYJKoZIhvcNAQcCoIIFvzCCBbsCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCBVwRanYMSGp9fh
# eBWWwDVU1jJo3d79oWTmc0dgHqFSXqCCAzAwggMsMIICFKADAgECAhB1HRbZIqgr
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
# MAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIMXX7TdqH39EWvuNVk9ji1m7
# ljDdh1UCuZZmeXA7l6X3MA0GCSqGSIb3DQEBAQUABIIBADZRSpa3/pu4AtMD82i2
# amD+8CmTbXSJDb9k0lkpfv2kLIu1UUzpJr15zr9v5dhNLr8WE728pZEKustCJGdd
# Mt/u3SRovPMuFhRGSUeSuQPNS1hNA8D4pZy/dgjzr1UsDY0QoTIPRPxr5gNyYkbl
# fXAvttNR8usuf2DgvYmxPPS5dr7nq6pNX7JsFdQIYmtpU4COPyG6NKQ+KdAPZlMP
# /b0/Hn9b9JPUNpZBb0YtnwurI2nIgipDVB3FRqxjZcTXhPq8WUGtaUZ7qADHVeAP
# T4DeprDpJF2XeANGD+5nKrdGfyb4mCHaoHr2vHFPtfWgQdxckQEpIkJr1efr2cJ0
# fkY=
# SIG # End signature block
