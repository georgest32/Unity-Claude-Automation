function Get-SystemPerformanceMetrics {
    <#
    .SYNOPSIS
    Collects system performance metrics using Get-Counter with enhanced error handling
    
    .DESCRIPTION
    Comprehensive performance monitoring following 2025 best practices:
    - Get-Counter wrapper with robust error handling
    - Remote monitoring support with ComputerName parameter
    - Structured metric output with standardized format
    - PowerShell 5.1 compatible implementation
    - Configurable counter paths and sampling
    - Performance optimization with caching
    
    .PARAMETER ComputerName
    Computer names to collect metrics from (default: local computer)
    
    .PARAMETER CounterPaths
    Performance counter paths to collect
    
    .PARAMETER SampleInterval
    Interval between samples in seconds (default: 1)
    
    .PARAMETER MaxSamples
    Maximum number of samples to collect (default: 1)
    
    .PARAMETER Continuous
    Collect samples continuously until stopped
    
    .PARAMETER OutputFormat
    Output format: Object (PowerShell objects), JSON (structured JSON), CSV (comma-separated)
    
    .EXAMPLE
    Get-SystemPerformanceMetrics
    
    .EXAMPLE
    Get-SystemPerformanceMetrics -ComputerName "Server01", "Server02" -MaxSamples 5
    
    .EXAMPLE
    Get-SystemPerformanceMetrics -CounterPaths @('\Processor(_Total)\% Processor Time') -Continuous
    #>
    [CmdletBinding()]
    param(
        [string[]]$ComputerName = @($env:COMPUTERNAME),
        
        [string[]]$CounterPaths = @(
            '\Processor(_Total)\% Processor Time',
            '\Memory\Available MBytes',
            '\PhysicalDisk(_Total)\Disk Reads/sec',
            '\PhysicalDisk(_Total)\Disk Writes/sec',
            '\Network Interface(*)\Bytes Total/sec'
        ),
        
        [int]$SampleInterval = 1,
        
        [int]$MaxSamples = 1,
        
        [switch]$Continuous,
        
        [ValidateSet('Object', 'JSON', 'CSV')]
        [string]$OutputFormat = 'Object'
    )
    
    Write-TraceLog -Message "Starting performance metrics collection" -Operation "Get-SystemPerformanceMetrics" -Context @{
        ComputerCount = $ComputerName.Count
        CounterCount = $CounterPaths.Count
        SampleInterval = $SampleInterval
        MaxSamples = $MaxSamples
        Continuous = $Continuous.IsPresent
    }
    
    $timer = [System.Diagnostics.Stopwatch]::StartNew()
    $allMetrics = @()
    $sampleCount = 0
    
    try {
        # Validate counter paths before collection
        $validatedCounters = Test-PerformanceCounterPaths -CounterPaths $CounterPaths -ComputerName $ComputerName
        
        if ($validatedCounters.Count -eq 0) {
            throw "No valid performance counters found"
        }
        
        Write-SystemStatusLog "Collecting $($validatedCounters.Count) performance counters from $($ComputerName.Count) computers" -Level 'INFO' -Source 'PerformanceMetrics'
        
        do {
            $sampleTimer = [System.Diagnostics.Stopwatch]::StartNew()
            
            try {
                # Collect performance counters
                $counters = Get-Counter -Counter $validatedCounters -ComputerName $ComputerName -SampleInterval $SampleInterval -MaxSamples 1 -ErrorAction Stop
                
                foreach ($counterSet in $counters.CounterSamples) {
                    $metric = Convert-CounterSampleToMetric -CounterSample $counterSet -SampleNumber ($sampleCount + 1)
                    $allMetrics += $metric
                }
                
                $sampleCount++
                $sampleTimer.Stop()
                
                Write-TraceLog -Message "Sample $sampleCount collected" -Operation "CollectSample" -Timer $sampleTimer -Context @{
                    SampleNumber = $sampleCount
                    CountersCollected = $counters.CounterSamples.Count
                    ElapsedMs = $sampleTimer.ElapsedMilliseconds
                }
                
            } catch {
                Write-SystemStatusLog "Error collecting performance sample $($sampleCount + 1): $($_.Exception.Message)" -Level 'ERROR' -Source 'PerformanceMetrics'
                
                # Try to collect individual counters to identify problematic ones
                $partialMetrics = Get-PartialPerformanceCounters -CounterPaths $validatedCounters -ComputerName $ComputerName -SampleNumber ($sampleCount + 1)
                $allMetrics += $partialMetrics
                $sampleCount++
            }
            
            # Break if we've reached max samples (unless continuous)
            if (-not $Continuous -and $sampleCount -ge $MaxSamples) {
                break
            }
            
            # Add delay between samples if continuous and not the last sample
            if ($Continuous -or $sampleCount -lt $MaxSamples) {
                if ($SampleInterval -gt 1) {
                    Start-Sleep -Seconds ($SampleInterval - 1) # Subtract 1 because Get-Counter already waited
                }
            }
            
        } while ($Continuous -or $sampleCount -lt $MaxSamples)
        
        $timer.Stop()
        
        Write-SystemStatusLog "Performance metrics collection completed: $($allMetrics.Count) metrics in $($timer.ElapsedMilliseconds)ms" -Level 'OK' -Source 'PerformanceMetrics'
        
        # Process and format output
        $result = Format-PerformanceMetricsOutput -Metrics $allMetrics -OutputFormat $OutputFormat -CollectionInfo @{
            SampleCount = $sampleCount
            Duration = $timer.Elapsed
            ComputerNames = $ComputerName
            CounterPaths = $validatedCounters
        }
        
        Write-TraceLog -Message "Performance metrics collection completed successfully" -Operation "Get-SystemPerformanceMetrics" -Timer $timer -Context @{
            MetricsCollected = $allMetrics.Count
            SamplesCompleted = $sampleCount
            OutputFormat = $OutputFormat
        }
        
        return $result
        
    } catch {
        $timer.Stop()
        Write-SystemStatusLog "Performance metrics collection failed: $($_.Exception.Message)" -Level 'ERROR' -Source 'PerformanceMetrics'
        Write-TraceLog -Message "Performance metrics collection failed" -Operation "Get-SystemPerformanceMetrics" -Timer $timer -Context @{
            Error = $_.Exception.Message
            SamplesCompleted = $sampleCount
        }
        
        throw
    }
}

function Test-PerformanceCounterPaths {
    <#
    .SYNOPSIS
    Validates performance counter paths before collection
    #>
    param(
        [string[]]$CounterPaths,
        [string[]]$ComputerName
    )
    
    $validCounters = @()
    
    foreach ($counter in $CounterPaths) {
        try {
            # Test counter availability
            $testResult = Get-Counter -Counter $counter -ComputerName $ComputerName[0] -MaxSamples 1 -ErrorAction Stop
            $validCounters += $counter
            
            Write-TraceLog -Message "Counter validated: $counter" -Operation "ValidateCounter" -TraceLevel 'Detail'
            
        } catch {
            Write-SystemStatusLog "Invalid performance counter: $counter - $($_.Exception.Message)" -Level 'WARN' -Source 'PerformanceMetrics'
        }
    }
    
    return $validCounters
}

function Convert-CounterSampleToMetric {
    <#
    .SYNOPSIS
    Converts a Get-Counter sample to standardized metric format
    #>
    param(
        [object]$CounterSample,
        [int]$SampleNumber
    )
    
    return [PSCustomObject]@{
        Timestamp = $CounterSample.Timestamp
        Computer = $CounterSample.Path.Split('\')[2]  # Extract computer name from path
        CounterPath = $CounterSample.Path
        CounterName = Split-Path $CounterSample.Path -Leaf
        Instance = if ($CounterSample.InstanceName) { $CounterSample.InstanceName } else { '_Total' }
        Value = $CounterSample.CookedValue
        RawValue = $CounterSample.RawValue
        SampleNumber = $SampleNumber
        Status = $CounterSample.Status
        Unit = Get-CounterUnit -CounterPath $CounterSample.Path
    }
}

function Get-PartialPerformanceCounters {
    <#
    .SYNOPSIS
    Collects individual counters when batch collection fails
    #>
    param(
        [string[]]$CounterPaths,
        [string[]]$ComputerName,
        [int]$SampleNumber
    )
    
    $partialMetrics = @()
    
    foreach ($counter in $CounterPaths) {
        try {
            $result = Get-Counter -Counter $counter -ComputerName $ComputerName -MaxSamples 1 -ErrorAction Stop
            
            foreach ($sample in $result.CounterSamples) {
                $metric = Convert-CounterSampleToMetric -CounterSample $sample -SampleNumber $SampleNumber
                $partialMetrics += $metric
            }
            
        } catch {
            Write-SystemStatusLog "Failed to collect counter $counter : $($_.Exception.Message)" -Level 'ERROR' -Source 'PerformanceMetrics'
            
            # Create error metric
            $errorMetric = [PSCustomObject]@{
                Timestamp = Get-Date
                Computer = $ComputerName[0]
                CounterPath = $counter
                CounterName = Split-Path $counter -Leaf
                Instance = 'Error'
                Value = $null
                RawValue = $null
                SampleNumber = $SampleNumber
                Status = 'Error'
                Error = $_.Exception.Message
                Unit = 'Unknown'
            }
            $partialMetrics += $errorMetric
        }
    }
    
    return $partialMetrics
}

function Get-CounterUnit {
    <#
    .SYNOPSIS
    Determines the unit of measurement for a performance counter
    #>
    param([string]$CounterPath)
    
    $counterName = Split-Path $CounterPath -Leaf
    
    switch -Regex ($counterName) {
        '% |Percent' { return 'Percent' }
        'Bytes|MB|KB|GB' { return 'Bytes' }
        '/sec|per second' { return 'PerSecond' }
        'Count|Number' { return 'Count' }
        'Time|Duration' { return 'Time' }
        default { return 'Unknown' }
    }
}

function Format-PerformanceMetricsOutput {
    <#
    .SYNOPSIS
    Formats performance metrics in the requested output format
    #>
    param(
        [object[]]$Metrics,
        [string]$OutputFormat,
        [hashtable]$CollectionInfo
    )
    
    switch ($OutputFormat) {
        'Object' {
            return @{
                Metrics = $Metrics
                Summary = Get-PerformanceMetricsSummary -Metrics $Metrics
                CollectionInfo = $CollectionInfo
            }
        }
        
        'JSON' {
            $output = @{
                Timestamp = Get-Date
                Metrics = $Metrics
                Summary = Get-PerformanceMetricsSummary -Metrics $Metrics
                CollectionInfo = $CollectionInfo
            }
            return ConvertTo-Json $output -Depth 4 -Compress
        }
        
        'CSV' {
            return $Metrics | ConvertTo-Csv -NoTypeInformation
        }
        
        default {
            return $Metrics
        }
    }
}

function Get-PerformanceMetricsSummary {
    <#
    .SYNOPSIS
    Generates summary statistics for collected performance metrics
    #>
    param([object[]]$Metrics)
    
    $summary = @{
        TotalMetrics = $Metrics.Count
        UniqueCounters = ($Metrics | Group-Object CounterPath).Count
        UniqueComputers = ($Metrics | Group-Object Computer).Count
        TimeRange = @{
            Start = ($Metrics | Measure-Object Timestamp -Minimum).Minimum
            End = ($Metrics | Measure-Object Timestamp -Maximum).Maximum
        }
        Errors = ($Metrics | Where-Object { $_.Status -eq 'Error' }).Count
    }
    
    # Add performance highlights
    $cpuMetrics = $Metrics | Where-Object { $_.CounterName -like '*Processor Time*' }
    if ($cpuMetrics) {
        $summary.CPUUsage = @{
            Average = [math]::Round(($cpuMetrics | Measure-Object Value -Average).Average, 2)
            Maximum = [math]::Round(($cpuMetrics | Measure-Object Value -Maximum).Maximum, 2)
        }
    }
    
    $memoryMetrics = $Metrics | Where-Object { $_.CounterName -like '*Available*' }
    if ($memoryMetrics) {
        $summary.MemoryAvailable = @{
            Average = [math]::Round(($memoryMetrics | Measure-Object Value -Average).Average, 2)
            Minimum = [math]::Round(($memoryMetrics | Measure-Object Value -Minimum).Minimum, 2)
        }
    }
    
    return $summary
}
# SIG # Begin signature block
# MIIFzgYJKoZIhvcNAQcCoIIFvzCCBbsCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCDbj196/733x7NE
# BkmU6Xsf7tmlflCcPGROub2V59N8wKCCAzAwggMsMIICFKADAgECAhB1HRbZIqgr
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
# MAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIJlfwGdQmEwBCvGGAIpK6ffn
# XL6GcUakwWyDV4pT39JDMA0GCSqGSIb3DQEBAQUABIIBAA7/jcCTNTB8rZ74cgZ7
# aecPDVQLduP3iTiY28GuVKvybdQLwfCeRAJR8cGB8w7UUNGL49KHlfNFuOzLK1l2
# mWZ1xN4T+xUvmblnYWxuFmsNDbFW0jVUsk+2VIA6NQg4MC88Sla6jmYLeobp1jsq
# +oKrDz4pZdJJxvAvWEodxbFYxnN0otgLquH8hD5bGouVq6JSwoPHhs6pKQwSKpU+
# z9QrKrA9y2vaEQsHxrTkEp9yW/22VFD1UnhL7b7PsxlJZ2kEjKnqYK/SnwGE1NKx
# Yckv4sUTM2uFsDpC7NDiPA+y0/WsOGqoTcknwLkAZyj9B9huHjzGOsR3SUA5ZJNS
# RDg=
# SIG # End signature block
