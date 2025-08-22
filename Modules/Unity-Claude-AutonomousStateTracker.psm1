# Unity-Claude-AutonomousStateTracker.psm1
# Autonomous operation state tracking and health monitoring for Day 14 Integration Testing
# Provides comprehensive state machine, health monitoring, and intervention management
# Date: 2025-08-18 | Day 14: Complete Feedback Loop Integration

#region Module Configuration and Dependencies

$ErrorActionPreference = "Stop"

Write-Host "[StateTracker] Loading autonomous operation state tracking module..." -ForegroundColor Cyan

# State tracking configuration
$script:StateConfig = @{
    # State management
    StateDataPath = Join-Path $PSScriptRoot "..\SessionData\States"
    HealthDataPath = Join-Path $PSScriptRoot "..\SessionData\Health"
    StateHistoryRetention = 1000  # Number of state transitions to keep
    
    # Health monitoring
    HealthCheckIntervalSeconds = 30
    MetricsCollectionIntervalSeconds = 60
    AlertThresholdMinutes = 5
    CriticalThresholdMinutes = 15
    
    # Intervention triggers
    MaxConsecutiveFailures = 5
    MaxCycleTimeMinutes = 10
    MinSuccessRate = 0.7  # 70%
    MaxMemoryUsageMB = 500
    MaxCpuPercentage = 80
    
    # Circuit breaker settings
    CircuitBreakerFailureThreshold = 3
    CircuitBreakerTimeoutMinutes = 10
    CircuitBreakerRecoveryAttempts = 3
    
    # Logging
    VerboseLogging = $true
    LogFile = "autonomous_state_tracker.log"
}

# Ensure directories exist
foreach ($path in @($script:StateConfig.StateDataPath, $script:StateConfig.HealthDataPath)) {
    if (-not (Test-Path $path)) {
        New-Item -Path $path -ItemType Directory -Force | Out-Null
    }
}

# Define autonomous operation states
$script:AutonomousStates = @{
    "Idle" = @{
        Description = "Agent is idle, waiting for triggers"
        AllowedTransitions = @("Initializing", "Stopped", "Error")
        IsOperational = $false
        RequiresMonitoring = $false
    }
    "Initializing" = @{
        Description = "Agent is starting up and initializing components"
        AllowedTransitions = @("Active", "Error", "Stopped")
        IsOperational = $false
        RequiresMonitoring = $true
    }
    "Active" = @{
        Description = "Agent is actively processing feedback loops"
        AllowedTransitions = @("Monitoring", "Processing", "Paused", "Error", "Stopped")
        IsOperational = $true
        RequiresMonitoring = $true
    }
    "Monitoring" = @{
        Description = "Agent is monitoring for Claude responses"
        AllowedTransitions = @("Processing", "Active", "Paused", "Error", "Stopped")
        IsOperational = $true
        RequiresMonitoring = $true
    }
    "Processing" = @{
        Description = "Agent is processing Claude response and executing commands"
        AllowedTransitions = @("Generating", "Active", "Error", "Stopped")
        IsOperational = $true
        RequiresMonitoring = $true
    }
    "Generating" = @{
        Description = "Agent is generating follow-up prompts"
        AllowedTransitions = @("Submitting", "Active", "Error", "Stopped")
        IsOperational = $true
        RequiresMonitoring = $true
    }
    "Submitting" = @{
        Description = "Agent is submitting prompts to Claude"
        AllowedTransitions = @("Monitoring", "Active", "Error", "Stopped")
        IsOperational = $true
        RequiresMonitoring = $true
    }
    "Paused" = @{
        Description = "Agent is paused, awaiting human intervention"
        AllowedTransitions = @("Active", "Stopped", "Error")
        IsOperational = $false
        RequiresMonitoring = $true
    }
    "Error" = @{
        Description = "Agent encountered an error and requires attention"
        AllowedTransitions = @("Recovering", "Stopped", "Idle")
        IsOperational = $false
        RequiresMonitoring = $true
    }
    "Recovering" = @{
        Description = "Agent is attempting to recover from error state"
        AllowedTransitions = @("Active", "Error", "Stopped")
        IsOperational = $false
        RequiresMonitoring = $true
    }
    "CircuitBreakerOpen" = @{
        Description = "Circuit breaker is open due to repeated failures"
        AllowedTransitions = @("Recovering", "Stopped")
        IsOperational = $false
        RequiresMonitoring = $true
    }
    "Stopped" = @{
        Description = "Agent has been stopped"
        AllowedTransitions = @("Idle", "Initializing")
        IsOperational = $false
        RequiresMonitoring = $false
    }
}

#endregion

#region Logging and Utilities

function Write-StateTrackerLog {
    param(
        [string]$Message,
        [ValidateSet("INFO", "WARNING", "ERROR", "DEBUG")]
        [string]$Level = "INFO",
        [string]$Component = "StateTracker"
    )
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss.fff"
    $logEntry = "[$timestamp] [$Level] [$Component] $Message"
    
    # Console output with colors
    $color = switch ($Level) {
        "INFO" { "White" }
        "WARNING" { "Yellow" }
        "ERROR" { "Red" }
        "DEBUG" { "Gray" }
    }
    
    if ($Level -ne "DEBUG" -or $script:StateConfig.VerboseLogging) {
        Write-Host $logEntry -ForegroundColor $color
    }
    
    # File logging
    $logFile = Join-Path (Split-Path $script:StateConfig.StateDataPath -Parent) $script:StateConfig.LogFile
    try {
        Add-Content -Path $logFile -Value $logEntry -Encoding UTF8
    } catch {
        Write-Warning "Failed to write to state tracker log: $($_.Exception.Message)"
    }
}

function Get-StateTimestamp {
    return Get-Date -Format "yyyy-MM-dd HH:mm:ss.fff"
}

function New-StateTrackingId {
    return [System.Guid]::NewGuid().ToString("N").Substring(0, 12)
}

#endregion

#region State Management

function Initialize-AutonomousStateTracking {
    param(
        [string]$AgentId = (New-StateTrackingId),
        [string]$InitialState = "Idle"
    )
    
    Write-StateTrackerLog "Initializing autonomous state tracking for agent: $AgentId" -Level "INFO"
    
    # Validate initial state
    if (-not $script:AutonomousStates.ContainsKey($InitialState)) {
        throw "Invalid initial state: $InitialState"
    }
    
    $stateTracking = @{
        # Agent identification
        AgentId = $AgentId
        TrackingId = New-StateTrackingId
        
        # Current state
        CurrentState = $InitialState
        PreviousState = $null
        StateStartTime = Get-StateTimestamp
        LastTransition = Get-StateTimestamp
        
        # State history
        StateHistory = @()
        TransitionCount = 0
        
        # Health monitoring
        HealthStatus = "Unknown"
        LastHealthCheck = $null
        HealthMetrics = @{
            CpuUsage = 0
            MemoryUsage = 0
            ResponseTime = 0
            SuccessRate = 0
            ErrorRate = 0
            ConsecutiveFailures = 0
            ConsecutiveSuccesses = 0
        }
        
        # Performance tracking
        PerformanceMetrics = @{
            TotalCycles = 0
            SuccessfulCycles = 0
            FailedCycles = 0
            AverageResponseTime = 0
            TotalProcessingTime = 0
            LastCycleTime = 0
        }
        
        # Intervention tracking
        InterventionTriggers = @()
        LastIntervention = $null
        InterventionCount = 0
        
        # Circuit breaker state
        CircuitBreaker = @{
            IsOpen = $false
            FailureCount = 0
            LastFailure = $null
            RecoveryAttempts = 0
            NextRetryTime = $null
        }
        
        # Timestamps
        StartTime = Get-StateTimestamp
        LastActivity = Get-StateTimestamp
        
        # Configuration
        Configuration = $script:StateConfig
    }
    
    # Add initial state to history
    $initialStateEntry = @{
        FromState = $null
        ToState = $InitialState
        Timestamp = Get-StateTimestamp
        Reason = "Initial state"
        Metadata = @{}
    }
    $stateTracking.StateHistory += $initialStateEntry
    
    # Save state tracking
    $saveResult = Save-StateTracking -StateTracking $stateTracking
    if ($saveResult.Success) {
        Write-StateTrackerLog "State tracking initialized successfully" -Level "INFO"
        return @{ Success = $true; StateTracking = $stateTracking }
    } else {
        Write-StateTrackerLog "Failed to save initial state tracking: $($saveResult.Error)" -Level "ERROR"
        return @{ Success = $false; Error = $saveResult.Error }
    }
}

function Get-AutonomousStateTracking {
    param(
        [string]$AgentId
    )
    
    $stateFile = Join-Path $script:StateConfig.StateDataPath "$AgentId.json"
    
    if (-not (Test-Path $stateFile)) {
        Write-StateTrackerLog "State tracking file not found for agent: $AgentId" -Level "WARNING"
        return @{ Success = $false; Error = "State tracking not found" }
    }
    
    try {
        $stateJson = Get-Content -Path $stateFile -Raw
        $stateTracking = $stateJson | ConvertFrom-Json
        
        # Convert PSCustomObject to hashtable
        $stateHash = @{}
        $stateTracking.PSObject.Properties | ForEach-Object { $stateHash[$_.Name] = $_.Value }
        
        return @{ Success = $true; StateTracking = $stateHash }
    } catch {
        Write-StateTrackerLog "Failed to load state tracking: $($_.Exception.Message)" -Level "ERROR"
        return @{ Success = $false; Error = $_.ToString() }
    }
}

function Save-StateTracking {
    param(
        [hashtable]$StateTracking
    )
    
    try {
        $agentId = $StateTracking.AgentId
        $StateTracking.LastActivity = Get-StateTimestamp
        
        $stateFile = Join-Path $script:StateConfig.StateDataPath "$agentId.json"
        $StateTracking | ConvertTo-Json -Depth 20 | Set-Content -Path $stateFile -Encoding UTF8
        
        return @{ Success = $true }
    } catch {
        Write-StateTrackerLog "Failed to save state tracking: $($_.Exception.Message)" -Level "ERROR"
        return @{ Success = $false; Error = $_.ToString() }
    }
}

function Set-AutonomousState {
    param(
        [string]$AgentId,
        [string]$NewState,
        [string]$Reason = "State transition",
        [hashtable]$Metadata = @{}
    )
    
    $stateResult = Get-AutonomousStateTracking -AgentId $AgentId
    if (-not $stateResult.Success) {
        return $stateResult
    }
    
    $stateTracking = $stateResult.StateTracking
    $currentState = $stateTracking.CurrentState
    
    # Validate state transition
    $validationResult = Test-StateTransition -FromState $currentState -ToState $NewState
    if (-not $validationResult.IsValid) {
        Write-StateTrackerLog "Invalid state transition: $currentState -> $NewState. $($validationResult.Reason)" -Level "ERROR"
        return @{ Success = $false; Error = $validationResult.Reason }
    }
    
    # Record state transition
    $stateTransition = @{
        FromState = $currentState
        ToState = $NewState
        Timestamp = Get-StateTimestamp
        Reason = $Reason
        Metadata = $Metadata
        Duration = $null
    }
    
    # Calculate duration in previous state
    if ($stateTracking.StateStartTime) {
        $duration = ((Get-Date) - (Get-Date $stateTracking.StateStartTime)).TotalMilliseconds
        $stateTransition.Duration = $duration
    }
    
    # Update state tracking
    $stateTracking.PreviousState = $currentState
    $stateTracking.CurrentState = $NewState
    $stateTracking.StateStartTime = Get-StateTimestamp
    $stateTracking.LastTransition = Get-StateTimestamp
    $stateTracking.TransitionCount += 1
    
    # Add to state history
    $stateTracking.StateHistory += $stateTransition
    
    # Trim state history if it gets too long
    if ($stateTracking.StateHistory.Count -gt $script:StateConfig.StateHistoryRetention) {
        $stateTracking.StateHistory = $stateTracking.StateHistory | Select-Object -Last $script:StateConfig.StateHistoryRetention
    }
    
    Write-StateTrackerLog "State transition: $currentState -> $NewState ($Reason)" -Level "INFO"
    
    # Check for intervention triggers after state change
    $interventionResult = Test-InterventionTriggers -StateTracking $stateTracking
    if ($interventionResult.TriggerRequired) {
        Invoke-InterventionTrigger -StateTracking $stateTracking -TriggerReason $interventionResult.Reason
    }
    
    # Save updated state tracking
    return Save-StateTracking -StateTracking $stateTracking
}

function Test-StateTransition {
    param(
        [string]$FromState,
        [string]$ToState
    )
    
    # Check if states exist
    if (-not $script:AutonomousStates.ContainsKey($FromState)) {
        return @{ IsValid = $false; Reason = "Unknown from state: $FromState" }
    }
    
    if (-not $script:AutonomousStates.ContainsKey($ToState)) {
        return @{ IsValid = $false; Reason = "Unknown to state: $ToState" }
    }
    
    # Check if transition is allowed
    $allowedTransitions = $script:AutonomousStates[$FromState].AllowedTransitions
    if ($ToState -notin $allowedTransitions) {
        return @{ IsValid = $false; Reason = "Transition not allowed from $FromState to $ToState" }
    }
    
    return @{ IsValid = $true; Reason = "Valid transition" }
}

#endregion

#region Health Monitoring

function Invoke-HealthCheck {
    param(
        [string]$AgentId
    )
    
    $stateResult = Get-AutonomousStateTracking -AgentId $AgentId
    if (-not $stateResult.Success) {
        return $stateResult
    }
    
    $stateTracking = $stateResult.StateTracking
    
    try {
        # Collect system metrics
        $systemMetrics = Get-SystemMetrics
        
        # Update health metrics
        $stateTracking.HealthMetrics.CpuUsage = $systemMetrics.CpuUsage
        $stateTracking.HealthMetrics.MemoryUsage = $systemMetrics.MemoryUsage
        $stateTracking.HealthMetrics.ResponseTime = $systemMetrics.ResponseTime
        
        # Calculate health status
        $healthStatus = Calculate-HealthStatus -HealthMetrics $stateTracking.HealthMetrics
        $stateTracking.HealthStatus = $healthStatus.Status
        $stateTracking.LastHealthCheck = Get-StateTimestamp
        
        Write-StateTrackerLog "Health check completed: $($healthStatus.Status)" -Level "DEBUG"
        
        # Check for critical health issues
        if ($healthStatus.Status -eq "Critical") {
            $interventionResult = Invoke-InterventionTrigger -StateTracking $stateTracking -TriggerReason "Critical health status: $($healthStatus.Reason)"
        }
        
        # Save updated state tracking
        $saveResult = Save-StateTracking -StateTracking $stateTracking
        
        return @{ 
            Success = $true
            HealthStatus = $healthStatus.Status
            Metrics = $stateTracking.HealthMetrics
            RequiresIntervention = ($healthStatus.Status -eq "Critical")
        }
    } catch {
        Write-StateTrackerLog "Health check failed: $($_.Exception.Message)" -Level "ERROR"
        return @{ Success = $false; Error = $_.ToString() }
    }
}

function Get-SystemMetrics {
    try {
        # Get process information
        $process = Get-Process -Id $PID
        
        # CPU usage (approximation)
        $cpuUsage = Get-CimInstance -ClassName Win32_Processor | Measure-Object -Property LoadPercentage -Average | Select-Object -ExpandProperty Average
        
        # Memory usage
        $memoryUsage = [Math]::Round($process.WorkingSet64 / 1MB, 2)
        
        # Response time (placeholder - would be measured from actual operations)
        $responseTime = 0
        
        return @{
            CpuUsage = $cpuUsage
            MemoryUsage = $memoryUsage
            ResponseTime = $responseTime
        }
    } catch {
        Write-StateTrackerLog "Failed to get system metrics: $($_.Exception.Message)" -Level "WARNING"
        return @{
            CpuUsage = 0
            MemoryUsage = 0
            ResponseTime = 0
        }
    }
}

function Calculate-HealthStatus {
    param(
        [hashtable]$HealthMetrics
    )
    
    $issues = @()
    $status = "Healthy"
    
    # Check CPU usage
    if ($HealthMetrics.CpuUsage -gt $script:StateConfig.MaxCpuPercentage) {
        $issues += "High CPU usage: $($HealthMetrics.CpuUsage)%"
        $status = "Warning"
    }
    
    # Check memory usage
    if ($HealthMetrics.MemoryUsage -gt $script:StateConfig.MaxMemoryUsageMB) {
        $issues += "High memory usage: $($HealthMetrics.MemoryUsage)MB"
        $status = "Warning"
    }
    
    # Check consecutive failures
    if ($HealthMetrics.ConsecutiveFailures -gt $script:StateConfig.MaxConsecutiveFailures) {
        $issues += "Too many consecutive failures: $($HealthMetrics.ConsecutiveFailures)"
        $status = "Critical"
    }
    
    # Check success rate
    if ($HealthMetrics.SuccessRate -lt $script:StateConfig.MinSuccessRate -and $HealthMetrics.SuccessRate -gt 0) {
        $issues += "Low success rate: $($HealthMetrics.SuccessRate)"
        $status = "Warning"
    }
    
    $reason = if ($issues.Count -gt 0) { $issues -join "; " } else { "All metrics within normal range" }
    
    return @{
        Status = $status
        Reason = $reason
        Issues = $issues
    }
}

#endregion

#region Intervention Management

function Test-InterventionTriggers {
    param(
        [hashtable]$StateTracking
    )
    
    $triggers = @()
    
    # Check consecutive failures
    if ($StateTracking.HealthMetrics.ConsecutiveFailures -ge $script:StateConfig.MaxConsecutiveFailures) {
        $triggers += "Max consecutive failures exceeded: $($StateTracking.HealthMetrics.ConsecutiveFailures)"
    }
    
    # Check if stuck in non-operational state
    if ($StateTracking.CurrentState -in @("Error", "Paused", "CircuitBreakerOpen")) {
        $stateStartTime = Get-Date $StateTracking.StateStartTime
        $stateDuration = ((Get-Date) - $stateStartTime).TotalMinutes
        
        if ($stateDuration -gt $script:StateConfig.AlertThresholdMinutes) {
            $triggers += "Stuck in $($StateTracking.CurrentState) state for $([Math]::Round($stateDuration, 1)) minutes"
        }
    }
    
    # Check success rate
    if ($StateTracking.PerformanceMetrics.TotalCycles -gt 5 -and 
        $StateTracking.HealthMetrics.SuccessRate -lt $script:StateConfig.MinSuccessRate) {
        $triggers += "Success rate below threshold: $($StateTracking.HealthMetrics.SuccessRate)"
    }
    
    # Check circuit breaker
    if ($StateTracking.CircuitBreaker.IsOpen) {
        $triggers += "Circuit breaker is open"
    }
    
    return @{
        TriggerRequired = ($triggers.Count -gt 0)
        Reason = $triggers -join "; "
        Triggers = $triggers
    }
}

function Invoke-InterventionTrigger {
    param(
        [hashtable]$StateTracking,
        [string]$TriggerReason
    )
    
    $intervention = @{
        InterventionId = New-StateTrackingId
        Timestamp = Get-StateTimestamp
        Reason = $TriggerReason
        AgentState = $StateTracking.CurrentState
        HealthStatus = $StateTracking.HealthStatus
        AutomaticActions = @()
        HumanActionRequired = $false
    }
    
    Write-StateTrackerLog "Intervention triggered: $TriggerReason" -Level "WARNING"
    
    # Determine automatic actions based on trigger reason
    if ($TriggerReason -like "*consecutive failures*") {
        # Attempt circuit breaker pattern
        $intervention.AutomaticActions += "Activating circuit breaker"
        $StateTracking.CircuitBreaker.IsOpen = $true
        $StateTracking.CircuitBreaker.FailureCount = $StateTracking.HealthMetrics.ConsecutiveFailures
        $StateTracking.CircuitBreaker.LastFailure = Get-StateTimestamp
        $StateTracking.CircuitBreaker.NextRetryTime = (Get-Date).AddMinutes($script:StateConfig.CircuitBreakerTimeoutMinutes).ToString("yyyy-MM-dd HH:mm:ss.fff")
        
        # Transition to circuit breaker state
        Set-AutonomousState -AgentId $StateTracking.AgentId -NewState "CircuitBreakerOpen" -Reason "Circuit breaker activated due to consecutive failures"
    }
    
    if ($TriggerReason -like "*High memory usage*") {
        $intervention.AutomaticActions += "Requesting garbage collection"
        [System.GC]::Collect()
        [System.GC]::WaitForPendingFinalizers()
    }
    
    if ($TriggerReason -like "*stuck*" -or $TriggerReason -like "*Critical health*") {
        $intervention.HumanActionRequired = $true
        $intervention.AutomaticActions += "Pausing autonomous operation for human review"
        
        # Transition to paused state if not already in error handling
        if ($StateTracking.CurrentState -notin @("Paused", "Stopped", "Error")) {
            Set-AutonomousState -AgentId $StateTracking.AgentId -NewState "Paused" -Reason "Human intervention required: $TriggerReason"
        }
    }
    
    # Record intervention
    $StateTracking.InterventionTriggers += $intervention
    $StateTracking.LastIntervention = $intervention.InterventionId
    $StateTracking.InterventionCount += 1
    
    # Save updated state
    Save-StateTracking -StateTracking $StateTracking
    
    Write-StateTrackerLog "Intervention actions: $($intervention.AutomaticActions -join ', '). Human action required: $($intervention.HumanActionRequired)" -Level "INFO"
    
    return @{
        Success = $true
        Intervention = $intervention
        HumanActionRequired = $intervention.HumanActionRequired
    }
}

function Update-PerformanceMetrics {
    param(
        [string]$AgentId,
        [hashtable]$MetricUpdates
    )
    
    $stateResult = Get-AutonomousStateTracking -AgentId $AgentId
    if (-not $stateResult.Success) {
        return $stateResult
    }
    
    $stateTracking = $stateResult.StateTracking
    
    # Update performance metrics
    foreach ($metric in $MetricUpdates.GetEnumerator()) {
        $stateTracking.PerformanceMetrics[$metric.Key] = $metric.Value
    }
    
    # Calculate derived metrics
    if ($stateTracking.PerformanceMetrics.TotalCycles -gt 0) {
        $stateTracking.HealthMetrics.SuccessRate = [Math]::Round(($stateTracking.PerformanceMetrics.SuccessfulCycles / $stateTracking.PerformanceMetrics.TotalCycles), 3)
        $stateTracking.HealthMetrics.ErrorRate = [Math]::Round(($stateTracking.PerformanceMetrics.FailedCycles / $stateTracking.PerformanceMetrics.TotalCycles), 3)
    }
    
    # Update consecutive counters based on last operation
    if ($MetricUpdates.ContainsKey("LastOperationSuccess")) {
        if ($MetricUpdates.LastOperationSuccess) {
            $stateTracking.HealthMetrics.ConsecutiveSuccesses += 1
            $stateTracking.HealthMetrics.ConsecutiveFailures = 0
        } else {
            $stateTracking.HealthMetrics.ConsecutiveFailures += 1
            $stateTracking.HealthMetrics.ConsecutiveSuccesses = 0
        }
    }
    
    return Save-StateTracking -StateTracking $stateTracking
}

#endregion

#region Circuit Breaker Management

function Test-CircuitBreakerState {
    param(
        [string]$AgentId
    )
    
    $stateResult = Get-AutonomousStateTracking -AgentId $AgentId
    if (-not $stateResult.Success) {
        return $stateResult
    }
    
    $stateTracking = $stateResult.StateTracking
    $circuitBreaker = $stateTracking.CircuitBreaker
    
    if (-not $circuitBreaker.IsOpen) {
        return @{ Success = $true; IsOpen = $false; CanProceed = $true }
    }
    
    # Check if enough time has passed for retry
    if ($circuitBreaker.NextRetryTime) {
        $nextRetryTime = Get-Date $circuitBreaker.NextRetryTime
        $canRetry = (Get-Date) -gt $nextRetryTime
        
        if ($canRetry) {
            Write-StateTrackerLog "Circuit breaker timeout expired, allowing retry attempt" -Level "INFO"
            return @{ Success = $true; IsOpen = $true; CanProceed = $true; RetryAttempt = $true }
        } else {
            $waitMinutes = [Math]::Round(($nextRetryTime - (Get-Date)).TotalMinutes, 1)
            return @{ Success = $true; IsOpen = $true; CanProceed = $false; WaitMinutes = $waitMinutes }
        }
    }
    
    return @{ Success = $true; IsOpen = $true; CanProceed = $false }
}

function Reset-CircuitBreaker {
    param(
        [string]$AgentId,
        [string]$Reason = "Manual reset"
    )
    
    $stateResult = Get-AutonomousStateTracking -AgentId $AgentId
    if (-not $stateResult.Success) {
        return $stateResult
    }
    
    $stateTracking = $stateResult.StateTracking
    
    # Reset circuit breaker
    $stateTracking.CircuitBreaker.IsOpen = $false
    $stateTracking.CircuitBreaker.FailureCount = 0
    $stateTracking.CircuitBreaker.LastFailure = $null
    $stateTracking.CircuitBreaker.RecoveryAttempts = 0
    $stateTracking.CircuitBreaker.NextRetryTime = $null
    
    # Reset consecutive failures
    $stateTracking.HealthMetrics.ConsecutiveFailures = 0
    
    Write-StateTrackerLog "Circuit breaker reset: $Reason" -Level "INFO"
    
    # Transition out of circuit breaker state if currently in it
    if ($stateTracking.CurrentState -eq "CircuitBreakerOpen") {
        Set-AutonomousState -AgentId $AgentId -NewState "Idle" -Reason "Circuit breaker reset"
    }
    
    return Save-StateTracking -StateTracking $stateTracking
}

#endregion

#region Status and Reporting

function Get-AutonomousOperationStatus {
    param(
        [string]$AgentId
    )
    
    $stateResult = Get-AutonomousStateTracking -AgentId $AgentId
    if (-not $stateResult.Success) {
        return $stateResult
    }
    
    $stateTracking = $stateResult.StateTracking
    
    # Calculate operational duration
    $startTime = Get-Date $stateTracking.StartTime
    $totalDuration = ((Get-Date) - $startTime).TotalMinutes
    
    # Calculate current state duration
    $stateStartTime = Get-Date $stateTracking.StateStartTime
    $currentStateDuration = ((Get-Date) - $stateStartTime).TotalMinutes
    
    $status = @{
        # Basic info
        AgentId = $stateTracking.AgentId
        CurrentState = $stateTracking.CurrentState
        IsOperational = $script:AutonomousStates[$stateTracking.CurrentState].IsOperational
        
        # Timing
        TotalDurationMinutes = [Math]::Round($totalDuration, 2)
        CurrentStateDurationMinutes = [Math]::Round($currentStateDuration, 2)
        LastTransition = $stateTracking.LastTransition
        
        # Health
        HealthStatus = $stateTracking.HealthStatus
        LastHealthCheck = $stateTracking.LastHealthCheck
        ConsecutiveFailures = $stateTracking.HealthMetrics.ConsecutiveFailures
        ConsecutiveSuccesses = $stateTracking.HealthMetrics.ConsecutiveSuccesses
        
        # Performance
        TotalCycles = $stateTracking.PerformanceMetrics.TotalCycles
        SuccessRate = $stateTracking.HealthMetrics.SuccessRate
        ErrorRate = $stateTracking.HealthMetrics.ErrorRate
        
        # Intervention
        InterventionCount = $stateTracking.InterventionCount
        LastIntervention = $stateTracking.LastIntervention
        
        # Circuit Breaker
        CircuitBreakerOpen = $stateTracking.CircuitBreaker.IsOpen
        CircuitBreakerFailures = $stateTracking.CircuitBreaker.FailureCount
        
        # Resource usage
        CpuUsage = $stateTracking.HealthMetrics.CpuUsage
        MemoryUsage = $stateTracking.HealthMetrics.MemoryUsage
    }
    
    return @{ Success = $true; Status = $status }
}

function Get-StateTransitionHistory {
    param(
        [string]$AgentId,
        [int]$MaxEntries = 20
    )
    
    $stateResult = Get-AutonomousStateTracking -AgentId $AgentId
    if (-not $stateResult.Success) {
        return $stateResult
    }
    
    $stateTracking = $stateResult.StateTracking
    $history = $stateTracking.StateHistory | Select-Object -Last $MaxEntries
    
    return @{ Success = $true; History = $history; TotalTransitions = $stateTracking.TransitionCount }
}

#endregion

#region Module Exports

Export-ModuleMember -Function @(
    # State management
    'Initialize-AutonomousStateTracking',
    'Get-AutonomousStateTracking',
    'Set-AutonomousState',
    
    # Health monitoring
    'Invoke-HealthCheck',
    'Update-PerformanceMetrics',
    
    # Intervention management
    'Test-InterventionTriggers',
    'Invoke-InterventionTrigger',
    
    # Circuit breaker
    'Test-CircuitBreakerState',
    'Reset-CircuitBreaker',
    
    # Status and reporting
    'Get-AutonomousOperationStatus',
    'Get-StateTransitionHistory',
    
    # Utilities
    'Write-StateTrackerLog',
    'Save-StateTracking'
)

#endregion

Write-Host "[StateTracker] Autonomous operation state tracking module loaded successfully" -ForegroundColor Green
# SIG # Begin signature block
# MIIFqQYJKoZIhvcNAQcCoIIFmjCCBZYCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUqbLvXwBxV/pOpt2YHDIVvptA
# MJGgggMwMIIDLDCCAhSgAwIBAgIQdR0W2SKoK5VE8JId4ZxrRTANBgkqhkiG9w0B
# AQsFADAuMSwwKgYDVQQDDCNVbml0eS1DbGF1ZGUtQXV0b21hdGlvbi1EZXZlbG9w
# bWVudDAeFw0yNTA4MjAyMTE1MTdaFw0yNjA4MjAyMTM1MTdaMC4xLDAqBgNVBAMM
# I1VuaXR5LUNsYXVkZS1BdXRvbWF0aW9uLURldmVsb3BtZW50MIIBIjANBgkqhkiG
# 9w0BAQEFAAOCAQ8AMIIBCgKCAQEAseH3qinVEOhrn2OLpjc5TNT4vGh1BkfB5X4S
# FhY7K0QMQsYYnkZVmx3tB8PqVQXl++l+e3uT7uCscc7vjMTK8tDSWH98ji0U34WL
# JBwXC62l1ArazMKp4Tyr7peksei7vL4pZOtOVgAyTYn5d1hbnsVQmCSTPRtpn7mC
# Azfq2ec5qZ9Kgl7puPW5utvYfh8idtOWa5/WgYSKwOIvyZawIdZKLFpwqOtqbJe4
# sWzVahasFhLfoAKkniKOAocJDkJexh5pO/EOSKEZ3mOCU1ZSs4XWRGISRhV3qGZp
# f+Y3JlHKMeFDWKynaJBO8/GU5sqMATlDUvrByBtU2OQ2Um/L3QIDAQABo0YwRDAO
# BgNVHQ8BAf8EBAMCB4AwEwYDVR0lBAwwCgYIKwYBBQUHAwMwHQYDVR0OBBYEFHw5
# rOy6xlW6B45sJUsiI2A/yS0MMA0GCSqGSIb3DQEBCwUAA4IBAQAUTLH0+w8ysvmh
# YuBw4NDKcZm40MTh9Zc1M2p2hAkYsgNLJ+/rAP+I74rNfqguTYwxpCyjkwrg8yF5
# wViwggboLpF2yDu4N/dgDainR4wR8NVpS7zFZOFkpmNPepc6bw3d4yQKa/wJXKeC
# pkRjS50N77/hfVI+fFKNao7POb7en5fcXuZaN6xWoTRy+J4I4MhfHpjZuxSLSXjb
# VXtPD4RZ9HGjl9BU8162cRhjujr/Lc3/dY/6ikHQYnxuxcdxRew4nzaqAQaOeWu6
# tGp899JPKfldM5Zay5IBl3zs15gNS9+0Jrd0ARQnSVYoI0DLh3KybFnfK4POezoN
# Lp/dbX2SMYIB4zCCAd8CAQEwQjAuMSwwKgYDVQQDDCNVbml0eS1DbGF1ZGUtQXV0
# b21hdGlvbi1EZXZlbG9wbWVudAIQdR0W2SKoK5VE8JId4ZxrRTAJBgUrDgMCGgUA
# oHgwGAYKKwYBBAGCNwIBDDEKMAigAoAAoQKAADAZBgkqhkiG9w0BCQMxDAYKKwYB
# BAGCNwIBBDAcBgorBgEEAYI3AgELMQ4wDAYKKwYBBAGCNwIBFTAjBgkqhkiG9w0B
# CQQxFgQU6F/YrQslAcdfCfJHytw561dWAyswDQYJKoZIhvcNAQEBBQAEggEAUuvG
# 1r7gqvOki93sgMwNqaQmVrskk6wDh/jmS01NwDA77pIDydZRWoX06V2ds/uwfedW
# 4vpz6rJkJs2NzwB+6JYw+l4g9oUom7gjqe4bP5gdnpNKNmYtlMYPAIH2QSFi+LSm
# U2dVsmKdnKGUl0SlG6Vn2FsLLsfk8tDFBNzWGOe239oimIZrWeUrv2qkkgXp9d2o
# lbrmEMoEuGnvzeElXhJuxNqmbZajHrSFBft8pAVmYGMtPEhhmgqCEibuc8P9oe1q
# zE8vHX+a3ZTfNLXz7tFVECOnxnu2jPWAKc0J83zqutdO6+pzrdk7wba99w13Uea2
# H3eKumESfPwJ4eXcrw==
# SIG # End signature block
