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