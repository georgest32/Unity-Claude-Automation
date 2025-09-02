function Initialize-DiagnosticPerformanceMonitoring {
    <#
    .SYNOPSIS
    Initializes performance counter monitoring for diagnostic mode
    
    .DESCRIPTION
    Sets up performance counter collection infrastructure for diagnostic sessions:
    - Configures default performance counters
    - Initializes data collection structures
    - Sets up background monitoring if requested
    - PowerShell 5.1 compatible implementation
    
    .PARAMETER CounterPaths
    Custom performance counter paths to monitor
    
    .PARAMETER SampleInterval
    Interval between performance samples in seconds
    
    .PARAMETER EnableBackground
    Enable background collection during diagnostic session
    
    .EXAMPLE
    Initialize-DiagnosticPerformanceMonitoring
    
    .EXAMPLE
    Initialize-DiagnosticPerformanceMonitoring -SampleInterval 5 -EnableBackground
    #>
    [CmdletBinding()]
    param(
        [string[]]$CounterPaths = @(
            '\Processor(_Total)\% Processor Time',
            '\Memory\Available MBytes',
            '\Process(' + (Get-Process -Id $PID).ProcessName + ')\Working Set',
            '\Process(' + (Get-Process -Id $PID).ProcessName + ')\% Processor Time'
        ),
        
        [int]$SampleInterval = 30,
        
        [switch]$EnableBackground
    )
    
    try {
        Write-SystemStatusLog "Initializing diagnostic performance monitoring" -Level 'DEBUG' -Source 'DiagnosticPerformance'
        
        # Initialize script-scoped variables for performance monitoring
        $script:DiagnosticPerformanceCounters = $CounterPaths
        $script:DiagnosticPerformanceData = @()
        $script:DiagnosticSampleInterval = $SampleInterval
        $script:DiagnosticBackgroundEnabled = $EnableBackground.IsPresent
        $script:DiagnosticPerformanceJob = $null
        
        # Validate counter paths
        $validatedCounters = @()
        foreach ($counter in $CounterPaths) {
            try {
                $testSample = Get-Counter -Counter $counter -MaxSamples 1 -ErrorAction Stop
                $validatedCounters += $counter
                Write-SystemStatusLog "Performance counter validated: $counter" -Level 'TRACE' -Source 'DiagnosticPerformance'
            } catch {
                Write-SystemStatusLog "Invalid performance counter: $counter - $($_.Exception.Message)" -Level 'WARN' -Source 'DiagnosticPerformance'
            }
        }
        
        $script:DiagnosticPerformanceCounters = $validatedCounters
        
        if ($validatedCounters.Count -eq 0) {
            throw "No valid performance counters available for monitoring"
        }
        
        Write-SystemStatusLog "Performance monitoring initialized with $($validatedCounters.Count) counters" -Level 'INFO' -Source 'DiagnosticPerformance'
        
        # Start background monitoring if requested
        if ($EnableBackground) {
            Start-BackgroundPerformanceMonitoring
        }
        
        return @{
            Success = $true
            CountersValidated = $validatedCounters.Count
            SampleInterval = $SampleInterval
            BackgroundEnabled = $EnableBackground.IsPresent
        }
        
    } catch {
        Write-SystemStatusLog "Failed to initialize performance monitoring: $($_.Exception.Message)" -Level 'ERROR' -Source 'DiagnosticPerformance'
        
        return @{
            Success = $false
            Error = $_.Exception.Message
        }
    }
}

function Stop-DiagnosticPerformanceMonitoring {
    <#
    .SYNOPSIS
    Stops diagnostic performance monitoring and cleans up resources
    #>
    [CmdletBinding()]
    param()
    
    try {
        Write-SystemStatusLog "Stopping diagnostic performance monitoring" -Level 'DEBUG' -Source 'DiagnosticPerformance'
        
        # Stop background job if running
        if ($script:DiagnosticPerformanceJob) {
            try {
                Stop-Job $script:DiagnosticPerformanceJob -ErrorAction SilentlyContinue
                Remove-Job $script:DiagnosticPerformanceJob -Force -ErrorAction SilentlyContinue
                Write-SystemStatusLog "Background performance monitoring job stopped" -Level 'DEBUG' -Source 'DiagnosticPerformance'
            } catch {
                Write-SystemStatusLog "Error stopping performance job: $($_.Exception.Message)" -Level 'WARN' -Source 'DiagnosticPerformance'
            }
        }
        
        # Get final data count before cleanup
        $dataCount = if ($script:DiagnosticPerformanceData) { $script:DiagnosticPerformanceData.Count } else { 0 }
        
        # Reset script variables
        $script:DiagnosticPerformanceCounters = $null
        $script:DiagnosticPerformanceData = $null
        $script:DiagnosticSampleInterval = $null
        $script:DiagnosticBackgroundEnabled = $false
        $script:DiagnosticPerformanceJob = $null
        
        Write-SystemStatusLog "Performance monitoring stopped (collected $dataCount data points)" -Level 'INFO' -Source 'DiagnosticPerformance'
        
        return @{
            Success = $true
            DataPointsCollected = $dataCount
        }
        
    } catch {
        Write-SystemStatusLog "Error stopping performance monitoring: $($_.Exception.Message)" -Level 'ERROR' -Source 'DiagnosticPerformance'
        
        return @{
            Success = $false
            Error = $_.Exception.Message
        }
    }
}

function Start-BackgroundPerformanceMonitoring {
    <#
    .SYNOPSIS
    Starts background performance data collection
    #>
    [CmdletBinding()]
    param()
    
    try {
        if (-not $script:DiagnosticPerformanceCounters -or $script:DiagnosticPerformanceCounters.Count -eq 0) {
            throw "No performance counters configured for background monitoring"
        }
        
        # Create background job for continuous monitoring
        $jobScript = {
            param($Counters, $Interval, $MaxDataPoints)
            
            $collectedData = @()
            
            while ($true) {
                try {
                    $samples = Get-Counter -Counter $Counters -MaxSamples 1 -ErrorAction Stop
                    
                    foreach ($sample in $samples.CounterSamples) {
                        $dataPoint = @{
                            Timestamp = Get-Date
                            CounterPath = $sample.Path
                            Value = $sample.CookedValue
                            InstanceName = $sample.InstanceName
                        }
                        $collectedData += $dataPoint
                    }
                    
                    # Limit data collection to prevent memory issues
                    if ($collectedData.Count -gt $MaxDataPoints) {
                        $collectedData = $collectedData | Select-Object -Last ($MaxDataPoints / 2)
                    }
                    
                } catch {
                    # Ignore collection errors in background job
                }
                
                Start-Sleep -Seconds $Interval
            }
        }
        
        $script:DiagnosticPerformanceJob = Start-Job -ScriptBlock $jobScript -ArgumentList $script:DiagnosticPerformanceCounters, $script:DiagnosticSampleInterval, 1000
        
        Write-SystemStatusLog "Background performance monitoring started (Job ID: $($script:DiagnosticPerformanceJob.Id))" -Level 'DEBUG' -Source 'DiagnosticPerformance'
        
    } catch {
        Write-SystemStatusLog "Failed to start background performance monitoring: $($_.Exception.Message)" -Level 'ERROR' -Source 'DiagnosticPerformance'
    }
}

function Register-DiagnosticTimeout {
    <#
    .SYNOPSIS
    Registers a timer to automatically disable diagnostic mode after timeout
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [TimeSpan]$Duration
    )
    
    try {
        # Use a simple approach - store timeout in script variable and check in Test-DiagnosticMode
        $script:DiagnosticTimeout = (Get-Date).Add($Duration)
        
        Write-SystemStatusLog "Diagnostic timeout registered for $($Duration.TotalMinutes) minutes" -Level 'DEBUG' -Source 'DiagnosticMode'
        
        return @{
            Success = $true
            TimeoutAt = $script:DiagnosticTimeout
        }
        
    } catch {
        Write-SystemStatusLog "Failed to register diagnostic timeout: $($_.Exception.Message)" -Level 'ERROR' -Source 'DiagnosticMode'
        
        return @{
            Success = $false
            Error = $_.Exception.Message
        }
    }
}
# SIG # Begin signature block
# MIIFzgYJKoZIhvcNAQcCoIIFvzCCBbsCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCARjg68rxH78Kx/
# AHMfPYAdFJ/vUWg9O2bGyB4O77+Fx6CCAzAwggMsMIICFKADAgECAhB1HRbZIqgr
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
# MAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIAKC1FDGN+yub/C4BKFrmd6T
# P+3RpPeuEwtNznE3BoVqMA0GCSqGSIb3DQEBAQUABIIBAEW83nQmjiXMKsu/N7p5
# wd7VRMpfTKu4xsOoF3Ggoxe2AUY8TvSekGjBYiMPrqB6sboJONHDhnnodp15a7l1
# 3YhGOVeJTccRdYqobKUO2JvyjagXaL3mqYPXFkAPcyT5UBlffJ/ItVZgjfDw+cf8
# Y6QyvQlEQeBB4X6wLWGMdrXwniYsA/VwUENR2H6NbljQmwNMl/nTqjBAW5t4A6AR
# 4XwB3e5UnqOms7w9GV8EDUqdDeR6i73ay/iB/qyzD7WEbbS8EFHmrTkJ8dIBoUTo
# Ipj4WBwwJU+wya/m8C0qjDfLHaKil27TOwpS4t7cUryGJZYprDakVyWcEyOEre3n
# d0Y=
# SIG # End signature block
