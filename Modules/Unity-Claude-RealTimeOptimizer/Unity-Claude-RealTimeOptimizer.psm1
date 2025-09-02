# Unity-Claude-RealTimeOptimizer.psm1
# Real-Time System Resource Optimization Module  
# Part of Week 3: Real-Time Intelligence - Day 11, Hour 7-8
# Focuses on optimizing the real-time monitoring and intelligence systems

# PowerShell 5.1 compatible - using full type names instead of using statements

# Module-level variables for real-time optimization state
$script:RTOptimizerState = @{
    IsMonitoring = $false
    ResourceMonitor = $null
    ThrottleController = $null
    MemoryManager = $null
    Configuration = @{
        # Resource thresholds for real-time system
        CPUThresholdHigh = 75      # Start throttling real-time operations
        CPUThresholdLow = 55       # Stop throttling
        MemoryThresholdHigh = 80   # Start aggressive cleanup
        MemoryThresholdLow = 65    # Normal operation
        
        # Adaptive throttling for real-time processing
        BaseProcessingInterval = 100    # milliseconds for real-time
        MaxThrottleMultiplier = 4       # max 4x slowdown
        ThrottleAdjustmentStep = 0.25   # 25% adjustments
        
        # Intelligent batching for events
        MinBatchSize = 1
        MaxBatchSize = 15
        OptimalBatchSize = 5
        
        # Memory management for continuous operation
        GCInterval = 20000          # 20 seconds for active system
        VariableCleanupInterval = 45000  # 45 seconds
        CacheCleanupInterval = 90000     # 90 seconds
        
        # Real-time monitoring intervals
        ResourceCheckInterval = 500     # 500ms for responsive monitoring
        PerformanceReportInterval = 15000  # 15 seconds
    }
    Statistics = @{
        CurrentCPUUsage = 0
        CurrentMemoryUsage = 0
        CurrentThrottleMultiplier = 1.0
        CurrentBatchSize = 5
        GCCollections = 0
        ThrottleAdjustments = 0
        BatchSizeAdjustments = 0
        ProcessedEvents = 0
        OptimizationActions = 0
        StartTime = $null
        LastOptimization = $null
    }
    ResourceHistory = [System.Collections.Generic.List[PSCustomObject]]::new()
    PerformanceCounters = $null
    MonitoringThread = $null
    OptimizationThread = $null
}

# Real-time optimization modes
enum RTOptimizationMode {
    RealTime      # Prioritize responsiveness
    Balanced      # Balance responsiveness and efficiency  
    Efficiency    # Prioritize resource efficiency
    Adaptive      # Auto-adjust based on workload
}

# System load levels
enum SystemLoadLevel {
    Low       # < 25% CPU, < 50% Memory
    Normal    # 25-50% CPU, 50-70% Memory
    High      # 50-75% CPU, 70-85% Memory
    Critical  # 75-90% CPU, 85-95% Memory
    Emergency # > 90% CPU, > 95% Memory
}

function Initialize-RealTimeOptimizer {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [RTOptimizationMode]$Mode = [RTOptimizationMode]::Balanced,
        
        [Parameter(Mandatory = $false)]
        [hashtable]$Configuration = @{}
    )
    
    Write-Host "Initializing Real-Time System Optimizer..." -ForegroundColor Cyan
    Write-Verbose "Real-Time Optimization Mode: $Mode"
    
    # Apply mode-specific configurations
    Set-RTOptimizationMode -Mode $Mode
    
    # Merge with custom configuration
    foreach ($key in $Configuration.Keys) {
        $script:RTOptimizerState.Configuration[$key] = $Configuration[$key]
    }
    
    # Initialize monitoring components
    Initialize-RTResourceMonitor
    Initialize-RTThrottleController  
    Initialize-RTMemoryManager
    
    # Set start time
    $script:RTOptimizerState.Statistics.StartTime = Get-Date
    
    Write-Host "Real-Time Optimizer initialized in $Mode mode" -ForegroundColor Green
    return $true
}

function Set-RTOptimizationMode {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [RTOptimizationMode]$Mode
    )
    
    switch ($Mode) {
        'RealTime' {
            # Prioritize responsiveness
            $script:RTOptimizerState.Configuration.BaseProcessingInterval = 50
            $script:RTOptimizerState.Configuration.ResourceCheckInterval = 250
            $script:RTOptimizerState.Configuration.OptimalBatchSize = 3
            $script:RTOptimizerState.Configuration.CPUThresholdHigh = 65
            $script:RTOptimizerState.Configuration.MemoryThresholdHigh = 75
        }
        'Efficiency' {
            # Prioritize resource conservation
            $script:RTOptimizerState.Configuration.BaseProcessingInterval = 200
            $script:RTOptimizerState.Configuration.ResourceCheckInterval = 1000
            $script:RTOptimizerState.Configuration.OptimalBatchSize = 10
            $script:RTOptimizerState.Configuration.CPUThresholdHigh = 85
            $script:RTOptimizerState.Configuration.MemoryThresholdHigh = 90
        }
        'Adaptive' {
            # Will auto-adjust based on system behavior
            $script:RTOptimizerState.Configuration.BaseProcessingInterval = 100
            $script:RTOptimizerState.Configuration.ResourceCheckInterval = 500
            $script:RTOptimizerState.Configuration.OptimalBatchSize = 5
        }
    }
}

function Initialize-RTResourceMonitor {
    [CmdletBinding()]
    param()
    
    $script:RTOptimizerState.ResourceMonitor = @{
        CPUCounter = $null
        MemoryCounter = $null
        ProcessCounter = $null
        IsInitialized = $false
        LastReadTime = Get-Date
        ReadInterval = 1000  # 1 second minimum between reads
    }
    
    try {
        Write-Verbose "Initializing real-time resource monitoring counters..."
        
        # Initialize optimized performance counters
        $script:RTOptimizerState.ResourceMonitor.CPUCounter = New-Object System.Diagnostics.PerformanceCounter("Processor", "% Processor Time", "_Total")
        $script:RTOptimizerState.ResourceMonitor.MemoryCounter = New-Object System.Diagnostics.PerformanceCounter("Memory", "Available MBytes")
        $script:RTOptimizerState.ResourceMonitor.ProcessCounter = New-Object System.Diagnostics.PerformanceCounter("Process", "Working Set", "powershell")
        
        # Get baseline readings
        [void]$script:RTOptimizerState.ResourceMonitor.CPUCounter.NextValue()
        [void]$script:RTOptimizerState.ResourceMonitor.MemoryCounter.NextValue()
        
        $script:RTOptimizerState.ResourceMonitor.IsInitialized = $true
        Write-Verbose "Real-time resource monitor initialized successfully"
    }
    catch {
        Write-Warning "Failed to initialize performance counters, using fallback monitoring: $_"
        $script:RTOptimizerState.ResourceMonitor.IsInitialized = $false
    }
}

function Initialize-RTThrottleController {
    [CmdletBinding()]
    param()
    
    $script:RTOptimizerState.ThrottleController = @{
        CurrentMultiplier = 1.0
        LastAdjustment = Get-Date
        IsThrottling = $false
        ThrottleHistory = [System.Collections.Generic.List[PSCustomObject]]::new()
        ConsecutiveHighLoad = 0
        ConsecutiveLowLoad = 0
    }
    
    Write-Verbose "Real-time throttle controller initialized"
}

function Initialize-RTMemoryManager {
    [CmdletBinding()]
    param()
    
    $script:RTOptimizerState.MemoryManager = @{
        LastGC = Get-Date
        LastVariableCleanup = Get-Date
        LastCacheCleanup = Get-Date
        ManagedVariables = [System.Collections.Generic.HashSet[string]]::new()
        MemoryBaseline = [System.GC]::GetTotalMemory($false)
        MemoryPeakUsage = 0
        IsActive = $true
    }
    
    # Get initial memory baseline
    [System.GC]::Collect()
    $script:RTOptimizerState.MemoryManager.MemoryBaseline = [System.GC]::GetTotalMemory($false)
    
    Write-Verbose "Real-time memory manager initialized with baseline: $([Math]::Round($script:RTOptimizerState.MemoryManager.MemoryBaseline / 1MB, 2))MB"
}

function Start-RealTimeOptimization {
    [CmdletBinding()]
    param()
    
    if ($script:RTOptimizerState.IsMonitoring) {
        Write-Warning "Real-time optimization is already running"
        return $false
    }
    
    Write-Host "Starting Real-Time System Optimization..." -ForegroundColor Cyan
    
    try {
        # Start resource monitoring thread
        Start-RTResourceMonitoringThread
        
        # Start optimization thread
        Start-RTOptimizationThread
        
        $script:RTOptimizerState.IsMonitoring = $true
        Write-Host "Real-Time Optimization started" -ForegroundColor Green
        
        return $true
    }
    catch {
        Write-Error "Failed to start real-time optimization: $_"
        return $false
    }
}

function Start-RTResourceMonitoringThread {
    [CmdletBinding()]
    param()
    
    $monitoringScript = {
        param($State)
        
        while ($State.IsMonitoring) {
            try {
                $currentTime = Get-Date
                
                # Throttle resource reading to avoid overhead
                if (($currentTime - $State.ResourceMonitor.LastReadTime).TotalMilliseconds -ge $State.ResourceMonitor.ReadInterval) {
                    
                    # Get current resource usage efficiently
                    $cpuUsage = Get-RTCurrentCPUUsage -State $State
                    $memoryUsage = Get-RTCurrentMemoryUsage -State $State
                    
                    # Update statistics
                    $State.Statistics.CurrentCPUUsage = $cpuUsage
                    $State.Statistics.CurrentMemoryUsage = $memoryUsage
                    
                    # Create resource snapshot for adaptive algorithms
                    $snapshot = @{
                        Timestamp = $currentTime
                        CPUUsage = $cpuUsage
                        MemoryUsage = $memoryUsage
                        LoadLevel = Get-SystemLoadLevel -CPU $cpuUsage -Memory $memoryUsage
                        ThrottleMultiplier = $State.Statistics.CurrentThrottleMultiplier
                        BatchSize = $State.Statistics.CurrentBatchSize
                    }
                    
                    # Maintain rolling history (keep last 50 for real-time)
                    if ($State.ResourceHistory.Count -ge 50) {
                        $State.ResourceHistory.RemoveAt(0)
                    }
                    $State.ResourceHistory.Add([PSCustomObject]$snapshot)
                    
                    $State.ResourceMonitor.LastReadTime = $currentTime
                }
                
                # Sleep for configured check interval
                Start-Sleep -Milliseconds $State.Configuration.ResourceCheckInterval
            }
            catch {
                Write-Error "Error in RT resource monitoring thread: $_"
                Start-Sleep -Milliseconds 2000  # Wait before retry
            }
        }
    }
    
    # Create and start monitoring thread
    $runspace = [runspacefactory]::CreateRunspace()
    $runspace.Open()
    
    $powershell = [powershell]::Create()
    $powershell.Runspace = $runspace
    [void]$powershell.AddScript($monitoringScript)
    [void]$powershell.AddArgument($script:RTOptimizerState)
    
    $script:RTOptimizerState.MonitoringThread = $powershell.BeginInvoke()
    
    Write-Verbose "RT resource monitoring thread started"
}

function Start-RTOptimizationThread {
    [CmdletBinding()]
    param()
    
    $optimizationScript = {
        param($State)
        
        while ($State.IsMonitoring) {
            try {
                $currentTime = Get-Date
                $loadLevel = Get-SystemLoadLevel -CPU $State.Statistics.CurrentCPUUsage -Memory $State.Statistics.CurrentMemoryUsage
                
                # Adaptive throttling based on system load
                switch ($loadLevel) {
                    'Emergency' {
                        Enable-RTEmergencyThrottling -State $State
                        Invoke-RTEmergencyCleanup -State $State
                    }
                    'Critical' {
                        Enable-RTAdaptiveThrottling -State $State -Aggressive:$true
                        Invoke-RTMemoryCleanup -State $State
                    }
                    'High' {
                        Enable-RTAdaptiveThrottling -State $State
                    }
                    'Normal' {
                        Optimize-RTBatchSize -State $State
                    }
                    'Low' {
                        Disable-RTAdaptiveThrottling -State $State
                        Optimize-RTBatchSize -State $State -Increase:$true
                    }
                }
                
                # Periodic memory management
                if (($currentTime - $State.MemoryManager.LastGC).TotalMilliseconds -gt $State.Configuration.GCInterval) {
                    Invoke-RTPeriodicCleanup -State $State
                }
                
                # Cache cleanup
                if (($currentTime - $State.MemoryManager.LastCacheCleanup).TotalMilliseconds -gt $State.Configuration.CacheCleanupInterval) {
                    Invoke-RTCacheCleanup -State $State
                }
                
                $State.Statistics.LastOptimization = $currentTime
                
                # Sleep for optimization cycle
                Start-Sleep -Milliseconds ($State.Configuration.PerformanceReportInterval / 2)
            }
            catch {
                Write-Error "Error in RT optimization thread: $_"
                Start-Sleep -Milliseconds 5000
            }
        }
    }
    
    # Create and start optimization thread
    $runspace = [runspacefactory]::CreateRunspace()
    $runspace.Open()
    
    $powershell = [powershell]::Create()
    $powershell.Runspace = $runspace
    [void]$powershell.AddScript($optimizationScript)
    [void]$powershell.AddArgument($script:RTOptimizerState)
    
    $script:RTOptimizerState.OptimizationThread = $powershell.BeginInvoke()
    
    Write-Verbose "RT optimization thread started"
}

function Get-RTCurrentCPUUsage {
    [CmdletBinding()]
    param(
        [hashtable]$State
    )
    
    try {
        if ($State.ResourceMonitor.IsInitialized -and $State.ResourceMonitor.CPUCounter) {
            # Use performance counter for efficiency (research-validated approach)
            return [Math]::Round($State.ResourceMonitor.CPUCounter.NextValue(), 2)
        }
        else {
            # Fallback to WMI for accuracy
            $cpu = Get-CimInstance -ClassName Win32_Processor | Measure-Object -Property LoadPercentage -Average
            return [Math]::Round($cpu.Average, 2)
        }
    }
    catch {
        Write-Verbose "RT CPU monitoring failed: $_"
        return 0  # Safe default
    }
}

function Get-RTCurrentMemoryUsage {
    [CmdletBinding()]
    param(
        [hashtable]$State
    )
    
    try {
        if ($State.ResourceMonitor.IsInitialized -and $State.ResourceMonitor.MemoryCounter) {
            # Use performance counter
            $availableMB = $State.ResourceMonitor.MemoryCounter.NextValue()
        }
        else {
            # Fallback to Get-Counter
            $counter = Get-Counter '\Memory\Available MBytes' -ErrorAction Stop
            $availableMB = $counter.CounterSamples[0].CookedValue
        }
        
        # Calculate usage percentage
        $totalMemory = Get-CimInstance -ClassName Win32_ComputerSystem | Select-Object -ExpandProperty TotalPhysicalMemory
        $totalMemoryMB = [Math]::Round($totalMemory / 1MB)
        $usedMemoryMB = $totalMemoryMB - $availableMB
        return [Math]::Round(($usedMemoryMB / $totalMemoryMB) * 100, 2)
    }
    catch {
        Write-Verbose "RT memory monitoring failed: $_"
        return 0  # Safe default
    }
}

function Get-SystemLoadLevel {
    [CmdletBinding()]
    param(
        [double]$CPU,
        [double]$Memory
    )
    
    # Determine overall system load level
    if ($CPU -gt 90 -or $Memory -gt 95) {
        return [SystemLoadLevel]::Emergency
    }
    elseif ($CPU -gt 75 -or $Memory -gt 85) {
        return [SystemLoadLevel]::Critical
    }
    elseif ($CPU -gt 50 -or $Memory -gt 70) {
        return [SystemLoadLevel]::High
    }
    elseif ($CPU -gt 25 -or $Memory -gt 50) {
        return [SystemLoadLevel]::Normal
    }
    else {
        return [SystemLoadLevel]::Low
    }
}

function Enable-RTAdaptiveThrottling {
    [CmdletBinding()]
    param(
        [hashtable]$State,
        [switch]$Aggressive
    )
    
    $adjustmentMultiplier = if ($Aggressive) { 2.0 } else { 1.0 }
    
    if (-not $State.ThrottleController.IsThrottling) {
        $State.ThrottleController.IsThrottling = $true
        $State.ThrottleController.CurrentMultiplier = 1.5 * $adjustmentMultiplier
        $State.ThrottleController.ConsecutiveHighLoad++
        $State.Statistics.ThrottleAdjustments++
        
        Write-Verbose "RT adaptive throttling enabled ($(if($Aggressive){'aggressive '}))- multiplier: $($State.ThrottleController.CurrentMultiplier)"
    }
    else {
        # Increase throttling gradually
        $step = $State.Configuration.ThrottleAdjustmentStep * $adjustmentMultiplier
        $newMultiplier = $State.ThrottleController.CurrentMultiplier + $step
        $State.ThrottleController.CurrentMultiplier = [Math]::Min($newMultiplier, $State.Configuration.MaxThrottleMultiplier)
        $State.Statistics.CurrentThrottleMultiplier = $State.ThrottleController.CurrentMultiplier
        $State.ThrottleController.ConsecutiveHighLoad++
        
        Write-Verbose "Increased RT throttling to $($State.ThrottleController.CurrentMultiplier)x"
    }
}

function Enable-RTEmergencyThrottling {
    [CmdletBinding()]
    param(
        [hashtable]$State
    )
    
    Write-Warning "Emergency system load detected - enabling maximum throttling"
    
    $State.ThrottleController.IsThrottling = $true
    $State.ThrottleController.CurrentMultiplier = $State.Configuration.MaxThrottleMultiplier
    $State.Statistics.CurrentThrottleMultiplier = $State.ThrottleController.CurrentMultiplier
    $State.Statistics.ThrottleAdjustments++
    
    # Emergency batch size reduction
    $State.Statistics.CurrentBatchSize = $State.Configuration.MinBatchSize
}

function Disable-RTAdaptiveThrottling {
    [CmdletBinding()]
    param(
        [hashtable]$State
    )
    
    if ($State.ThrottleController.IsThrottling) {
        $State.ThrottleController.ConsecutiveLowLoad++
        
        # Only disable after consecutive low load periods
        if ($State.ThrottleController.ConsecutiveLowLoad -ge 3) {
            # Decrease throttling gradually
            $newMultiplier = $State.ThrottleController.CurrentMultiplier - $State.Configuration.ThrottleAdjustmentStep
            
            if ($newMultiplier -le 1.0) {
                $State.ThrottleController.IsThrottling = $false
                $State.ThrottleController.CurrentMultiplier = 1.0
                $State.ThrottleController.ConsecutiveLowLoad = 0
                Write-Verbose "RT adaptive throttling disabled - system load normalized"
            }
            else {
                $State.ThrottleController.CurrentMultiplier = $newMultiplier
                Write-Verbose "Decreased RT throttling to $($State.ThrottleController.CurrentMultiplier)x"
            }
            
            $State.Statistics.CurrentThrottleMultiplier = $State.ThrottleController.CurrentMultiplier
        }
    }
    else {
        # Reset consecutive counters
        $State.ThrottleController.ConsecutiveHighLoad = 0
        $State.ThrottleController.ConsecutiveLowLoad = 0
    }
}

function Optimize-RTBatchSize {
    [CmdletBinding()]
    param(
        [hashtable]$State,
        [switch]$Increase
    )
    
    $currentBatch = $State.Statistics.CurrentBatchSize
    $optimalBatch = $State.Configuration.OptimalBatchSize
    
    if ($Increase -and $currentBatch -lt $State.Configuration.MaxBatchSize) {
        $State.Statistics.CurrentBatchSize = [Math]::Min($currentBatch + 1, $State.Configuration.MaxBatchSize)
        $State.Statistics.BatchSizeAdjustments++
        Write-Verbose "Increased RT batch size to $($State.Statistics.CurrentBatchSize)"
    }
    elseif (-not $Increase -and $currentBatch -gt $State.Configuration.MinBatchSize) {
        $State.Statistics.CurrentBatchSize = [Math]::Max($currentBatch - 1, $State.Configuration.MinBatchSize)
        $State.Statistics.BatchSizeAdjustments++
        Write-Verbose "Decreased RT batch size to $($State.Statistics.CurrentBatchSize)"
    }
}

function Invoke-RTPeriodicCleanup {
    [CmdletBinding()]
    param(
        [hashtable]$State
    )
    
    Write-Verbose "Performing RT periodic memory cleanup"
    
    $beforeMemory = [System.GC]::GetTotalMemory($false)
    
    # Research-validated garbage collection pattern for continuous operation
    [System.GC]::GetTotalMemory($true) | Out-Null
    [System.GC]::Collect(0, [System.GCCollectionMode]::Optimized)
    [System.GC]::WaitForPendingFinalizers()
    
    $afterMemory = [System.GC]::GetTotalMemory($false)
    $freedMB = [Math]::Round(($beforeMemory - $afterMemory) / 1MB, 2)
    
    $State.MemoryManager.LastGC = Get-Date
    $State.Statistics.GCCollections++
    
    Write-Verbose "RT periodic cleanup freed ${freedMB}MB"
}

function Invoke-RTEmergencyCleanup {
    [CmdletBinding()]
    param(
        [hashtable]$State
    )
    
    Write-Warning "Performing RT emergency memory cleanup"
    
    $beforeMemory = [System.GC]::GetTotalMemory($false)
    
    # Aggressive memory cleanup for emergency situations
    [System.GC]::GetTotalMemory($true) | Out-Null
    [System.GC]::Collect(2, [System.GCCollectionMode]::Forced)
    [System.GC]::WaitForPendingFinalizers()
    [System.GC]::Collect(2, [System.GCCollectionMode]::Forced)
    
    # Clear resource history to free memory
    $State.ResourceHistory.Clear()
    
    $afterMemory = [System.GC]::GetTotalMemory($false)
    $freedMB = [Math]::Round(($beforeMemory - $afterMemory) / 1MB, 2)
    
    $State.Statistics.GCCollections++
    $State.Statistics.OptimizationActions++
    
    Write-Warning "RT emergency cleanup freed ${freedMB}MB"
}

function Invoke-RTCacheCleanup {
    [CmdletBinding()]
    param(
        [hashtable]$State
    )
    
    Write-Verbose "Performing RT cache cleanup"
    
    # Cleanup can be integrated with Change Intelligence cache
    try {
        if (Get-Command "Clear-ChangeIntelligenceCache" -ErrorAction SilentlyContinue) {
            $clearedEntries = Clear-ChangeIntelligenceCache
            Write-Verbose "Cleared $clearedEntries cache entries"
        }
        
        $State.MemoryManager.LastCacheCleanup = Get-Date
    }
    catch {
        Write-Verbose "Cache cleanup failed: $_"
    }
}

function Get-RTOptimalBatchSize {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [int]$QueueLength,
        
        [Parameter(Mandatory = $false)]
        [SystemLoadLevel]$LoadLevel = [SystemLoadLevel]::Normal
    )
    
    $config = $script:RTOptimizerState.Configuration
    
    # Base calculation on queue pressure and system load using if-elseif to avoid array issues
    $queueFactor = if ($QueueLength -gt 50) { 2.0 }
                   elseif ($QueueLength -gt 20) { 1.5 }
                   elseif ($QueueLength -gt 10) { 1.2 }
                   else { 1.0 }
    
    $loadFactor = if ($LoadLevel -eq 'Emergency') { 0.5 }
                  elseif ($LoadLevel -eq 'Critical') { 0.7 }
                  elseif ($LoadLevel -eq 'High') { 0.8 }
                  elseif ($LoadLevel -eq 'Normal') { 1.0 }
                  elseif ($LoadLevel -eq 'Low') { 1.2 }
                  else { 1.0 }
    
    $optimalSize = [Math]::Round($config.OptimalBatchSize * $queueFactor * $loadFactor)
    return [Math]::Max($config.MinBatchSize, [Math]::Min($optimalSize, $config.MaxBatchSize))
}

function Get-RTThrottledDelay {
    [CmdletBinding()]
    param()
    
    $baseInterval = $script:RTOptimizerState.Configuration.BaseProcessingInterval
    $throttleMultiplier = $script:RTOptimizerState.Statistics.CurrentThrottleMultiplier
    
    return [Math]::Round($baseInterval * $throttleMultiplier)
}

function Get-RTPerformanceStatistics {
    [CmdletBinding()]
    param()
    
    $stats = $script:RTOptimizerState.Statistics.Clone()
    
    if ($stats.StartTime) {
        $stats.Runtime = (Get-Date) - $stats.StartTime
        
        # Calculate events per second
        if ($stats.Runtime.TotalSeconds -gt 0) {
            $stats.EventsPerSecond = [Math]::Round($stats.ProcessedEvents / $stats.Runtime.TotalSeconds, 2)
        }
    }
    
    $stats.IsMonitoring = $script:RTOptimizerState.IsMonitoring
    $stats.ResourceHistoryCount = $script:RTOptimizerState.ResourceHistory.Count
    $stats.SystemLoadLevel = Get-SystemLoadLevel -CPU $stats.CurrentCPUUsage -Memory $stats.CurrentMemoryUsage
    
    return [PSCustomObject]$stats
}

function Stop-RealTimeOptimizer {
    [CmdletBinding()]
    param()
    
    Write-Host "Stopping Real-Time Optimizer..." -ForegroundColor Yellow
    
    # Stop monitoring
    $script:RTOptimizerState.IsMonitoring = $false
    
    # Cleanup performance counters
    if ($script:RTOptimizerState.ResourceMonitor.CPUCounter) {
        $script:RTOptimizerState.ResourceMonitor.CPUCounter.Dispose()
    }
    
    if ($script:RTOptimizerState.ResourceMonitor.MemoryCounter) {
        $script:RTOptimizerState.ResourceMonitor.MemoryCounter.Dispose()
    }
    
    if ($script:RTOptimizerState.ResourceMonitor.ProcessCounter) {
        $script:RTOptimizerState.ResourceMonitor.ProcessCounter.Dispose()
    }
    
    # Final cleanup
    Invoke-RTPeriodicCleanup -State $script:RTOptimizerState
    
    Write-Host "Real-Time Optimizer stopped" -ForegroundColor Yellow
    
    return Get-RTPerformanceStatistics
}

# Export module functions
Export-ModuleMember -Function @(
    'Initialize-RealTimeOptimizer',
    'Start-RealTimeOptimization',
    'Stop-RealTimeOptimizer',
    'Get-RTPerformanceStatistics',
    'Get-RTOptimalBatchSize',
    'Get-RTThrottledDelay'
)