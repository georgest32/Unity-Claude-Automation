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