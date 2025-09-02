# CircuitBreaker.psm1
# Phase 7 Day 3-4 Hours 5-8: Circuit Breaker Pattern Implementation
# Advanced failure protection and recovery mechanisms
# Date: 2025-08-25

#region Circuit Breaker Configuration

# Circuit breaker state management
$script:CircuitBreakers = @{}

# Default circuit breaker configuration
$script:CircuitBreakerConfig = @{
    # Failure thresholds
    FailureThreshold = 5           # Number of failures before opening
    SuccessThreshold = 2           # Number of successes to close from half-open
    TimeoutDuration = 30000        # Milliseconds before attempting recovery
    
    # Monitoring windows
    MonitoringWindow = 60000       # Time window for failure counting (ms)
    SlidingWindow = $true          # Use sliding window vs fixed window
    
    # Recovery strategies
    RecoveryStrategies = @{
        Exponential = @{
            InitialDelay = 1000
            MaxDelay = 60000
            Multiplier = 2
        }
        Linear = @{
            Increment = 5000
            MaxDelay = 60000
        }
        Fixed = @{
            Delay = 30000
        }
    }
    
    # State transition callbacks
    StateCallbacks = @{
        OnOpen = $null
        OnClose = $null
        OnHalfOpen = $null
    }
    
    # Metrics collection
    CollectMetrics = $true
    MetricsRetention = 3600000     # 1 hour in milliseconds
}

# Circuit breaker states enum
enum CircuitState {
    Closed = 0      # Normal operation
    Open = 1        # Blocking requests
    HalfOpen = 2    # Testing recovery
}

# Logging function for circuit breaker
function Write-CircuitBreakerLog {
    param(
        [string]$Message,
        [string]$Level = "INFO",
        [string]$CircuitName = "Unknown"
    )
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss.fff"
    $logEntry = "[$timestamp] [CircuitBreaker] [$CircuitName] [$Level] $Message"
    Write-Host $logEntry -ForegroundColor $(
        switch ($Level) {
            "ERROR" { "Red" }
            "WARN" { "Yellow" }
            "SUCCESS" { "Green" }
            "DEBUG" { "Gray" }
            "STATE" { "Cyan" }
            default { "White" }
        }
    )
}

#endregion

#region Circuit Breaker Core Implementation

# Create or get circuit breaker instance
function Get-CircuitBreaker {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Name,
        
        [Parameter()]
        [hashtable]$Configuration = @{}
    )
    
    if (-not $script:CircuitBreakers.ContainsKey($Name)) {
        # Create new circuit breaker
        $config = $script:CircuitBreakerConfig.Clone()
        
        # Merge custom configuration
        foreach ($key in $Configuration.Keys) {
            $config[$key] = $Configuration[$key]
        }
        
        $circuitBreaker = [PSCustomObject]@{
            Name = $Name
            State = [CircuitState]::Closed
            FailureCount = 0
            SuccessCount = 0
            LastFailureTime = $null
            LastStateChange = Get-Date
            NextRetryTime = $null
            Configuration = $config
            History = New-Object System.Collections.Queue
            Metrics = @{
                TotalRequests = 0
                TotalFailures = 0
                TotalSuccesses = 0
                TotalTimeouts = 0
                StateChanges = 0
                LastReset = Get-Date
            }
            RecoveryAttempts = 0
            ConsecutiveSuccesses = 0
            ConsecutiveFailures = 0
        }
        
        $script:CircuitBreakers[$Name] = $circuitBreaker
        Write-CircuitBreakerLog "Circuit breaker created with state: Closed" "INFO" $Name
    }
    
    return $script:CircuitBreakers[$Name]
}

# Test if circuit breaker allows request
function Test-CircuitBreakerState {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Name
    )
    
    $breaker = Get-CircuitBreaker -Name $Name
    
    switch ($breaker.State) {
        ([CircuitState]::Closed) {
            return @{
                CanProceed = $true
                State = "Closed"
                Message = "Circuit is closed - requests allowed"
            }
        }
        
        ([CircuitState]::Open) {
            # Check if timeout has expired
            if ($breaker.NextRetryTime -and (Get-Date) -ge $breaker.NextRetryTime) {
                # Transition to half-open
                Set-CircuitBreakerState -Name $Name -NewState HalfOpen
                Write-CircuitBreakerLog "Timeout expired - transitioning to HalfOpen" "STATE" $Name
                
                return @{
                    CanProceed = $true
                    State = "HalfOpen"
                    Message = "Circuit is half-open - testing recovery"
                }
            } else {
                $remainingTime = if ($breaker.NextRetryTime) {
                    [Math]::Round(($breaker.NextRetryTime - (Get-Date)).TotalSeconds, 1)
                } else { 0 }
                
                return @{
                    CanProceed = $false
                    State = "Open"
                    Message = "Circuit is open - requests blocked"
                    RetryAfterSeconds = $remainingTime
                }
            }
        }
        
        ([CircuitState]::HalfOpen) {
            return @{
                CanProceed = $true
                State = "HalfOpen"
                Message = "Circuit is half-open - limited requests allowed"
            }
        }
        
        default {
            return @{
                CanProceed = $false
                State = "Unknown"
                Message = "Circuit state unknown - requests blocked"
            }
        }
    }
}

# Invoke action with circuit breaker protection
function Invoke-CircuitBreakerAction {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Name,
        
        [Parameter(Mandatory = $true)]
        [scriptblock]$Action,
        
        [Parameter()]
        [scriptblock]$FallbackAction = $null,
        
        [Parameter()]
        [int]$TimeoutMs = 30000,
        
        [Parameter()]
        [hashtable]$Context = @{}
    )
    
    $breaker = Get-CircuitBreaker -Name $Name
    $startTime = Get-Date
    
    try {
        # Check circuit state
        $stateCheck = Test-CircuitBreakerState -Name $Name
        
        if (-not $stateCheck.CanProceed) {
            Write-CircuitBreakerLog "Request blocked - circuit open" "WARN" $Name
            
            if ($FallbackAction) {
                Write-CircuitBreakerLog "Executing fallback action" "INFO" $Name
                return & $FallbackAction
            } else {
                throw "Circuit breaker is open - request blocked (retry after $($stateCheck.RetryAfterSeconds)s)"
            }
        }
        
        # Execute action with timeout
        $job = Start-Job -ScriptBlock $Action -ArgumentList $Context
        $completed = Wait-Job -Job $job -Timeout ($TimeoutMs / 1000)
        
        if (-not $completed) {
            Stop-Job -Job $job
            Remove-Job -Job $job -Force
            throw "Action timed out after ${TimeoutMs}ms"
        }
        
        # Get result
        $result = Receive-Job -Job $job
        Remove-Job -Job $job
        
        # Check for errors in job
        if ($job.State -eq 'Failed') {
            throw "Action failed: $($job.ChildJobs[0].JobStateInfo.Reason)"
        }
        
        # Record success
        Register-CircuitBreakerSuccess -Name $Name
        $breaker.Metrics.TotalSuccesses++
        
        $executionTime = ((Get-Date) - $startTime).TotalMilliseconds
        Write-CircuitBreakerLog "Action succeeded in ${executionTime}ms" "SUCCESS" $Name
        
        return $result
        
    } catch {
        # Record failure
        Register-CircuitBreakerFailure -Name $Name -Error $_.Exception.Message
        $breaker.Metrics.TotalFailures++
        
        Write-CircuitBreakerLog "Action failed: $($_.Exception.Message)" "ERROR" $Name
        
        if ($FallbackAction) {
            Write-CircuitBreakerLog "Executing fallback action after failure" "INFO" $Name
            return & $FallbackAction
        } else {
            throw
        }
    } finally {
        $breaker.Metrics.TotalRequests++
        
        # Clean up metrics if retention period exceeded
        if ($breaker.Configuration.CollectMetrics) {
            Clear-OldCircuitBreakerMetrics -Name $Name
        }
    }
}

#endregion

#region State Management

# Set circuit breaker state
function Set-CircuitBreakerState {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Name,
        
        [Parameter(Mandatory = $true)]
        [ValidateSet('Closed', 'Open', 'HalfOpen')]
        [string]$NewState,
        
        [Parameter()]
        [string]$Reason = "Manual state change"
    )
    
    $breaker = Get-CircuitBreaker -Name $Name
    $oldState = $breaker.State
    
    # Convert string to enum
    $stateEnum = [CircuitState]::$NewState
    
    if ($oldState -eq $stateEnum) {
        Write-CircuitBreakerLog "State already $NewState - no change" "DEBUG" $Name
        return
    }
    
    $breaker.State = $stateEnum
    $breaker.LastStateChange = Get-Date
    $breaker.Metrics.StateChanges++
    
    # State-specific actions
    switch ($stateEnum) {
        ([CircuitState]::Open) {
            # Calculate next retry time based on recovery strategy
            $strategy = $breaker.Configuration.RecoveryStrategies.Exponential
            $delay = [Math]::Min(
                $strategy.InitialDelay * [Math]::Pow($strategy.Multiplier, $breaker.RecoveryAttempts),
                $strategy.MaxDelay
            )
            $breaker.NextRetryTime = (Get-Date).AddMilliseconds($delay)
            $breaker.RecoveryAttempts++
            
            Write-CircuitBreakerLog "Circuit opened - next retry in ${delay}ms" "STATE" $Name
            
            # Execute callback if defined
            if ($breaker.Configuration.StateCallbacks.OnOpen) {
                & $breaker.Configuration.StateCallbacks.OnOpen $breaker
            }
        }
        
        ([CircuitState]::Closed) {
            $breaker.FailureCount = 0
            $breaker.SuccessCount = 0
            $breaker.ConsecutiveFailures = 0
            $breaker.ConsecutiveSuccesses = 0
            $breaker.RecoveryAttempts = 0
            $breaker.NextRetryTime = $null
            
            Write-CircuitBreakerLog "Circuit closed - normal operation resumed" "STATE" $Name
            
            # Execute callback if defined
            if ($breaker.Configuration.StateCallbacks.OnClose) {
                & $breaker.Configuration.StateCallbacks.OnClose $breaker
            }
        }
        
        ([CircuitState]::HalfOpen) {
            $breaker.SuccessCount = 0
            $breaker.ConsecutiveSuccesses = 0
            
            Write-CircuitBreakerLog "Circuit half-open - testing recovery" "STATE" $Name
            
            # Execute callback if defined
            if ($breaker.Configuration.StateCallbacks.OnHalfOpen) {
                & $breaker.Configuration.StateCallbacks.OnHalfOpen $breaker
            }
        }
    }
    
    # Add to history
    if ($breaker.History.Count -ge 100) {
        $breaker.History.Dequeue() | Out-Null
    }
    
    $breaker.History.Enqueue(@{
        Timestamp = Get-Date
        OldState = $oldState.ToString()
        NewState = $NewState
        Reason = $Reason
    })
    
    Write-CircuitBreakerLog "State changed from $($oldState) to $NewState - $Reason" "STATE" $Name
}

# Register successful execution
function Register-CircuitBreakerSuccess {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Name
    )
    
    $breaker = Get-CircuitBreaker -Name $Name
    $breaker.ConsecutiveSuccesses++
    $breaker.ConsecutiveFailures = 0
    
    switch ($breaker.State) {
        ([CircuitState]::HalfOpen) {
            $breaker.SuccessCount++
            
            if ($breaker.SuccessCount -ge $breaker.Configuration.SuccessThreshold) {
                Set-CircuitBreakerState -Name $Name -NewState Closed -Reason "Success threshold reached"
            } else {
                Write-CircuitBreakerLog "Success in half-open state ($($breaker.SuccessCount)/$($breaker.Configuration.SuccessThreshold))" "INFO" $Name
            }
        }
        
        ([CircuitState]::Closed) {
            # Reset failure count on success in closed state
            if ($breaker.FailureCount -gt 0) {
                $breaker.FailureCount--
                Write-CircuitBreakerLog "Failure count reduced to $($breaker.FailureCount)" "DEBUG" $Name
            }
        }
    }
}

# Register failed execution
function Register-CircuitBreakerFailure {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Name,
        
        [Parameter()]
        [string]$Error = "Unknown error"
    )
    
    $breaker = Get-CircuitBreaker -Name $Name
    $breaker.LastFailureTime = Get-Date
    $breaker.ConsecutiveFailures++
    $breaker.ConsecutiveSuccesses = 0
    
    switch ($breaker.State) {
        ([CircuitState]::Closed) {
            # Check if within monitoring window
            if ($breaker.Configuration.SlidingWindow) {
                # Remove old failures outside window
                $windowStart = (Get-Date).AddMilliseconds(-$breaker.Configuration.MonitoringWindow)
                $recentFailures = @($breaker.History.ToArray() | 
                    Where-Object { 
                        $_.Timestamp -ge $windowStart -and 
                        $_.Type -eq 'Failure' 
                    })
                $breaker.FailureCount = $recentFailures.Count + 1
            } else {
                $breaker.FailureCount++
            }
            
            Write-CircuitBreakerLog "Failure recorded ($($breaker.FailureCount)/$($breaker.Configuration.FailureThreshold)): $Error" "WARN" $Name
            
            if ($breaker.FailureCount -ge $breaker.Configuration.FailureThreshold) {
                Set-CircuitBreakerState -Name $Name -NewState Open -Reason "Failure threshold exceeded"
            }
        }
        
        ([CircuitState]::HalfOpen) {
            # Any failure in half-open immediately opens circuit
            Set-CircuitBreakerState -Name $Name -NewState Open -Reason "Failure during recovery test"
        }
    }
    
    # Add to history
    if ($breaker.History.Count -ge 100) {
        $breaker.History.Dequeue() | Out-Null
    }
    
    $breaker.History.Enqueue(@{
        Timestamp = Get-Date
        Type = 'Failure'
        Error = $Error
    })
}

#endregion

#region Recovery Strategies

# Implement exponential backoff recovery
function Get-ExponentialBackoffDelay {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Name
    )
    
    $breaker = Get-CircuitBreaker -Name $Name
    $strategy = $breaker.Configuration.RecoveryStrategies.Exponential
    
    $delay = [Math]::Min(
        $strategy.InitialDelay * [Math]::Pow($strategy.Multiplier, $breaker.RecoveryAttempts),
        $strategy.MaxDelay
    )
    
    return $delay
}

# Implement linear backoff recovery
function Get-LinearBackoffDelay {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Name
    )
    
    $breaker = Get-CircuitBreaker -Name $Name
    $strategy = $breaker.Configuration.RecoveryStrategies.Linear
    
    $delay = [Math]::Min(
        $strategy.Increment * $breaker.RecoveryAttempts,
        $strategy.MaxDelay
    )
    
    return $delay
}

# Reset circuit breaker
function Reset-CircuitBreaker {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Name,
        
        [Parameter()]
        [switch]$ClearHistory,
        
        [Parameter()]
        [switch]$ResetMetrics
    )
    
    $breaker = Get-CircuitBreaker -Name $Name
    
    # Reset to closed state
    Set-CircuitBreakerState -Name $Name -NewState Closed -Reason "Manual reset"
    
    # Clear history if requested
    if ($ClearHistory) {
        $breaker.History.Clear()
        Write-CircuitBreakerLog "History cleared" "INFO" $Name
    }
    
    # Reset metrics if requested
    if ($ResetMetrics) {
        $breaker.Metrics = @{
            TotalRequests = 0
            TotalFailures = 0
            TotalSuccesses = 0
            TotalTimeouts = 0
            StateChanges = 0
            LastReset = Get-Date
        }
        Write-CircuitBreakerLog "Metrics reset" "INFO" $Name
    }
    
    Write-CircuitBreakerLog "Circuit breaker reset completed" "SUCCESS" $Name
}

#endregion

#region Metrics and Monitoring

# Get circuit breaker statistics
function Get-CircuitBreakerStatistics {
    [CmdletBinding()]
    param(
        [Parameter()]
        [string]$Name = $null,
        
        [Parameter()]
        [switch]$IncludeHistory
    )
    
    if ($Name) {
        $breakers = @{ $Name = Get-CircuitBreaker -Name $Name }
    } else {
        $breakers = $script:CircuitBreakers
    }
    
    $statistics = @{}
    
    foreach ($breakerName in $breakers.Keys) {
        $breaker = $breakers[$breakerName]
        
        $stats = @{
            Name = $breakerName
            CurrentState = $breaker.State.ToString()
            LastStateChange = $breaker.LastStateChange
            FailureCount = $breaker.FailureCount
            SuccessCount = $breaker.SuccessCount
            ConsecutiveFailures = $breaker.ConsecutiveFailures
            ConsecutiveSuccesses = $breaker.ConsecutiveSuccesses
            RecoveryAttempts = $breaker.RecoveryAttempts
            Metrics = $breaker.Metrics
        }
        
        # Calculate success rate
        if ($breaker.Metrics.TotalRequests -gt 0) {
            $stats.SuccessRate = [Math]::Round(
                ($breaker.Metrics.TotalSuccesses / $breaker.Metrics.TotalRequests) * 100, 
                2
            )
        } else {
            $stats.SuccessRate = 0
        }
        
        # Add history if requested
        if ($IncludeHistory) {
            $stats.RecentHistory = @($breaker.History.ToArray() | Select-Object -Last 10)
        }
        
        # Add next retry time if circuit is open
        if ($breaker.State -eq [CircuitState]::Open -and $breaker.NextRetryTime) {
            $stats.NextRetryTime = $breaker.NextRetryTime
            $stats.RetryInSeconds = [Math]::Round(
                ($breaker.NextRetryTime - (Get-Date)).TotalSeconds, 
                1
            )
        }
        
        $statistics[$breakerName] = $stats
    }
    
    return $statistics
}

# Clear old metrics based on retention policy
function Clear-OldCircuitBreakerMetrics {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Name
    )
    
    $breaker = Get-CircuitBreaker -Name $Name
    
    if (-not $breaker.Configuration.CollectMetrics) {
        return
    }
    
    $retentionTime = (Get-Date).AddMilliseconds(-$breaker.Configuration.MetricsRetention)
    
    # Remove old history entries
    $newHistory = New-Object System.Collections.Queue
    foreach ($entry in $breaker.History.ToArray()) {
        if ($entry.Timestamp -ge $retentionTime) {
            $newHistory.Enqueue($entry)
        }
    }
    
    if ($newHistory.Count -lt $breaker.History.Count) {
        $removed = $breaker.History.Count - $newHistory.Count
        $breaker.History = $newHistory
        Write-CircuitBreakerLog "Removed $removed old history entries" "DEBUG" $Name
    }
}

#endregion

#region Health Checks

# Check health of all circuit breakers
function Test-CircuitBreakerHealth {
    [CmdletBinding()]
    param(
        [Parameter()]
        [double]$UnhealthyThreshold = 0.5  # Percentage of open circuits considered unhealthy
    )
    
    $totalBreakers = $script:CircuitBreakers.Count
    
    if ($totalBreakers -eq 0) {
        return @{
            Healthy = $true
            Message = "No circuit breakers configured"
            TotalBreakers = 0
        }
    }
    
    $openBreakers = @($script:CircuitBreakers.Values | Where-Object { $_.State -eq [CircuitState]::Open })
    $halfOpenBreakers = @($script:CircuitBreakers.Values | Where-Object { $_.State -eq [CircuitState]::HalfOpen })
    
    $openPercentage = $openBreakers.Count / $totalBreakers
    
    $health = @{
        Healthy = $openPercentage -lt $UnhealthyThreshold
        TotalBreakers = $totalBreakers
        OpenBreakers = $openBreakers.Count
        HalfOpenBreakers = $halfOpenBreakers.Count
        ClosedBreakers = $totalBreakers - $openBreakers.Count - $halfOpenBreakers.Count
        OpenPercentage = [Math]::Round($openPercentage * 100, 2)
    }
    
    if ($health.Healthy) {
        $health.Message = "Circuit breaker system healthy"
    } else {
        $health.Message = "Circuit breaker system degraded - $($health.OpenPercentage)% circuits open"
        $health.OpenCircuits = $openBreakers | ForEach-Object { $_.Name }
    }
    
    return $health
}

#endregion

#region Graceful Degradation

# Implement graceful degradation strategy
function Invoke-GracefulDegradationWithCircuitBreaker {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$ServiceName,
        
        [Parameter(Mandatory = $true)]
        [scriptblock]$PrimaryAction,
        
        [Parameter()]
        [scriptblock]$DegradedAction = $null,
        
        [Parameter()]
        [scriptblock]$FallbackAction = $null,
        
        [Parameter()]
        [hashtable]$Context = @{}
    )
    
    Write-CircuitBreakerLog "Attempting service call with graceful degradation" "INFO" $ServiceName
    
    try {
        # Try primary action with circuit breaker
        $result = Invoke-CircuitBreakerAction `
            -Name $ServiceName `
            -Action $PrimaryAction `
            -Context $Context
        
        Write-CircuitBreakerLog "Primary action succeeded" "SUCCESS" $ServiceName
        return @{
            Success = $true
            DegradationLevel = "None"
            Result = $result
        }
        
    } catch {
        Write-CircuitBreakerLog "Primary action failed: $($_.Exception.Message)" "WARN" $ServiceName
        
        # Try degraded action if available
        if ($DegradedAction) {
            try {
                Write-CircuitBreakerLog "Attempting degraded action" "INFO" $ServiceName
                $result = & $DegradedAction $Context
                
                return @{
                    Success = $true
                    DegradationLevel = "Partial"
                    Result = $result
                    Message = "Service degraded but functional"
                }
                
            } catch {
                Write-CircuitBreakerLog "Degraded action failed: $($_.Exception.Message)" "WARN" $ServiceName
            }
        }
        
        # Fall back to final option
        if ($FallbackAction) {
            try {
                Write-CircuitBreakerLog "Attempting fallback action" "INFO" $ServiceName
                $result = & $FallbackAction $Context
                
                return @{
                    Success = $true
                    DegradationLevel = "Fallback"
                    Result = $result
                    Message = "Service using fallback mechanism"
                }
                
            } catch {
                Write-CircuitBreakerLog "Fallback action failed: $($_.Exception.Message)" "ERROR" $ServiceName
            }
        }
        
        # All options exhausted
        return @{
            Success = $false
            DegradationLevel = "Failed"
            Error = "All service options exhausted"
            LastError = $_.Exception.Message
        }
    }
}

#endregion

#region Module Management

# Export circuit breaker configuration for persistence
function Export-CircuitBreakerConfiguration {
    [CmdletBinding()]
    param(
        [Parameter()]
        [string]$Path = "C:\UnityProjects\Sound-and-Shoal\Unity-Claude-Automation\Data\CircuitBreakers.json"
    )
    
    try {
        $exportData = @{
            Configuration = $script:CircuitBreakerConfig
            Breakers = @{}
            ExportTime = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        }
        
        foreach ($name in $script:CircuitBreakers.Keys) {
            $breaker = $script:CircuitBreakers[$name]
            $exportData.Breakers[$name] = @{
                State = $breaker.State.ToString()
                FailureCount = $breaker.FailureCount
                SuccessCount = $breaker.SuccessCount
                RecoveryAttempts = $breaker.RecoveryAttempts
                Metrics = $breaker.Metrics
                Configuration = $breaker.Configuration
            }
        }
        
        # Create directory if needed
        $directory = Split-Path -Path $Path -Parent
        if (-not (Test-Path $directory)) {
            New-Item -ItemType Directory -Path $directory -Force | Out-Null
        }
        
        $exportData | ConvertTo-Json -Depth 10 | Out-File -FilePath $Path -Encoding UTF8
        
        Write-CircuitBreakerLog "Configuration exported to $Path" "SUCCESS" "Export"
        return $true
        
    } catch {
        Write-CircuitBreakerLog "Failed to export configuration: $($_.Exception.Message)" "ERROR" "Export"
        return $false
    }
}

# Import circuit breaker configuration
function Import-CircuitBreakerConfiguration {
    [CmdletBinding()]
    param(
        [Parameter()]
        [string]$Path = "C:\UnityProjects\Sound-and-Shoal\Unity-Claude-Automation\Data\CircuitBreakers.json"
    )
    
    try {
        if (-not (Test-Path $Path)) {
            Write-CircuitBreakerLog "Configuration file not found: $Path" "WARN" "Import"
            return $false
        }
        
        $importData = Get-Content -Path $Path -Raw | ConvertFrom-Json
        
        # Restore configuration
        if ($importData.Configuration) {
            foreach ($key in $importData.Configuration.PSObject.Properties.Name) {
                $script:CircuitBreakerConfig[$key] = $importData.Configuration.$key
            }
        }
        
        # Restore breakers
        if ($importData.Breakers) {
            foreach ($name in $importData.Breakers.PSObject.Properties.Name) {
                $breakerData = $importData.Breakers.$name
                $breaker = Get-CircuitBreaker -Name $name -Configuration $breakerData.Configuration
                
                # Restore state and counters
                $breaker.FailureCount = $breakerData.FailureCount
                $breaker.SuccessCount = $breakerData.SuccessCount
                $breaker.RecoveryAttempts = $breakerData.RecoveryAttempts
                
                if ($breakerData.Metrics) {
                    foreach ($key in $breakerData.Metrics.PSObject.Properties.Name) {
                        $breaker.Metrics[$key] = $breakerData.Metrics.$key
                    }
                }
            }
        }
        
        Write-CircuitBreakerLog "Configuration imported from $Path (exported: $($importData.ExportTime))" "SUCCESS" "Import"
        return $true
        
    } catch {
        Write-CircuitBreakerLog "Failed to import configuration: $($_.Exception.Message)" "ERROR" "Import"
        return $false
    }
}

#endregion

# Module initialization
Write-CircuitBreakerLog "Circuit Breaker module loaded successfully" "SUCCESS" "Module"

# Export functions
Export-ModuleMember -Function @(
    # Core Functions
    'Get-CircuitBreaker',
    'Test-CircuitBreakerState',
    'Invoke-CircuitBreakerAction',
    
    # State Management
    'Set-CircuitBreakerState',
    'Register-CircuitBreakerSuccess',
    'Register-CircuitBreakerFailure',
    'Reset-CircuitBreaker',
    
    # Recovery Strategies
    'Get-ExponentialBackoffDelay',
    'Get-LinearBackoffDelay',
    
    # Metrics and Monitoring
    'Get-CircuitBreakerStatistics',
    'Clear-OldCircuitBreakerMetrics',
    'Test-CircuitBreakerHealth',
    
    # Graceful Degradation
    'Invoke-GracefulDegradationWithCircuitBreaker',
    
    # Configuration Management
    'Export-CircuitBreakerConfiguration',
    'Import-CircuitBreakerConfiguration'
)
# SIG # Begin signature block
# MIIFzgYJKoZIhvcNAQcCoIIFvzCCBbsCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCCmHYb15VB0TZvi
# 384gzVj61Dw5o67Krlq4sPLM20tIN6CCAzAwggMsMIICFKADAgECAhB1HRbZIqgr
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
# MAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIL4zrk+lHbYy1yvPXiRLXY+x
# FxFaCK2lbA0NFGTgRJaNMA0GCSqGSIb3DQEBAQUABIIBAG0oEJ99Nq4Xv8PpdjmL
# Dmm6/9ivMwb3MzSxiRhsNmb3e+BJhJEclHSv0yA8YKOsM7J9/tA07hkDdfr/C7AA
# oHEFt9McHEVjVMzswv5AHJu7v+NDNi+i5Lnm0novELqXmeyDtV6YX7ue0vYWqmRj
# kkJcJSqNbWvsOKTVYP5Z8Swy+p2K0YcGawe6I048AYSgo5El6zxKa3yiL4xkL5T2
# 1Q7dpHediwjldpFOU90ZxbUJ3+Du02IqwotsPnAX9kuq/JHPCsD9xzi0ba9/6op+
# J8DzkEq083ndErULOKxvCDcOa/nOgHBm9soOWna5fFCZ/nH+mK16mitVqY6+trWu
# mjw=
# SIG # End signature block
