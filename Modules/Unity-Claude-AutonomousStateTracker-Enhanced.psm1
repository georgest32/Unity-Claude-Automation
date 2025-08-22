# Unity-Claude-AutonomousStateTracker-Enhanced.psm1
# Enhanced autonomous operation state tracking for Phase 3 Day 15
# Comprehensive state machine with persistence, recovery, and human intervention
# Date: 2025-08-19 | Phase 3 Day 15: Autonomous Agent State Management

#region Module Configuration and Enhanced Dependencies

$ErrorActionPreference = "Stop"

Write-Host "[Enhanced-StateTracker] Loading Phase 3 autonomous state management..." -ForegroundColor Cyan

# Enhanced state tracking configuration based on research findings
$script:EnhancedStateConfig = @{
    # Core state management paths
    StateDataPath = Join-Path $PSScriptRoot "..\SessionData\States"
    CheckpointPath = Join-Path $PSScriptRoot "..\SessionData\Checkpoints"
    HealthDataPath = Join-Path $PSScriptRoot "..\SessionData\Health"
    BackupPath = Join-Path $PSScriptRoot "..\SessionData\Backups"
    
    # State persistence settings (based on research)
    StateHistoryRetention = 2000
    CheckpointIntervalMinutes = 5     # Create checkpoints every 5 minutes
    BackupRetentionDays = 7
    IncrementalCheckpoints = $true    # Research finding: minimize checkpoint cost
    
    # Performance monitoring (Get-Counter integration)
    HealthCheckIntervalSeconds = 15   # More frequent for real-time monitoring
    PerformanceCounterInterval = 30   # Performance counter sampling
    MetricsCollectionIntervalSeconds = 60
    AlertThresholdMinutes = 3         # Faster alerts for autonomous operation
    CriticalThresholdMinutes = 10
    
    # Human intervention triggers (research-based thresholds)
    MaxConsecutiveFailures = 3        # Lower threshold for faster intervention
    MaxCycleTimeMinutes = 8           # Tighter cycle time monitoring
    MinSuccessRate = 0.75             # 75% success rate minimum
    MaxMemoryUsageMB = 800           # Higher threshold for complex operations
    MaxCpuPercentage = 70            # Conservative CPU usage
    
    # Performance counter thresholds (research findings)
    CriticalMemoryPercentage = 85
    CriticalDiskSpaceGB = 5
    NetworkLatencyThresholdMs = 1000
    
    # Circuit breaker enhancements
    CircuitBreakerFailureThreshold = 2  # More sensitive
    CircuitBreakerTimeoutMinutes = 5     # Faster recovery attempts
    CircuitBreakerRecoveryAttempts = 5   # More recovery attempts
    
    # Human intervention configuration
    HumanApprovalTimeout = 300        # 5 minutes for human response
    EscalationEnabled = $true
    NotificationMethods = @("Console", "File", "Event")  # Multiple notification methods
    
    # Logging enhancements
    VerboseLogging = $true
    LogFile = "autonomous_state_tracker_enhanced.log"
    PerformanceLogFile = "performance_metrics.log"
    InterventionLogFile = "human_interventions.log"
}

# Ensure all directories exist
foreach ($path in @($script:EnhancedStateConfig.StateDataPath, $script:EnhancedStateConfig.CheckpointPath, 
                   $script:EnhancedStateConfig.HealthDataPath, $script:EnhancedStateConfig.BackupPath)) {
    if (-not (Test-Path $path)) {
        New-Item -Path $path -ItemType Directory -Force | Out-Null
    }
}

# Enhanced autonomous operation states (building on Day 14 implementation)
$script:EnhancedAutonomousStates = @{
    "Idle" = @{
        Description = "Agent is idle, awaiting triggers or initialization"
        AllowedTransitions = @("Initializing", "Stopped", "Error")
        IsOperational = $false
        RequiresMonitoring = $false
        HumanInterventionRequired = $false
        HealthCheckLevel = "Minimal"
    }
    "Initializing" = @{
        Description = "Agent is initializing components and performing startup checks"
        AllowedTransitions = @("Active", "Error", "Stopped")
        IsOperational = $false
        RequiresMonitoring = $true
        HumanInterventionRequired = $false
        HealthCheckLevel = "Standard"
    }
    "Active" = @{
        Description = "Agent is actively managing autonomous feedback loops"
        AllowedTransitions = @("Monitoring", "Processing", "Paused", "Error", "Stopped")
        IsOperational = $true
        RequiresMonitoring = $true
        HumanInterventionRequired = $false
        HealthCheckLevel = "Comprehensive"
    }
    "Monitoring" = @{
        Description = "Agent is monitoring Claude responses and system state"
        AllowedTransitions = @("Processing", "Active", "Paused", "Error", "Stopped")
        IsOperational = $true
        RequiresMonitoring = $true
        HumanInterventionRequired = $false
        HealthCheckLevel = "Comprehensive"
    }
    "Processing" = @{
        Description = "Agent is processing responses and executing safe commands"
        AllowedTransitions = @("Generating", "Active", "Error", "Stopped", "HumanApprovalRequired")
        IsOperational = $true
        RequiresMonitoring = $true
        HumanInterventionRequired = $false
        HealthCheckLevel = "Intensive"
    }
    "Generating" = @{
        Description = "Agent is generating intelligent follow-up prompts"
        AllowedTransitions = @("Submitting", "Active", "Error", "Stopped")
        IsOperational = $true
        RequiresMonitoring = $true
        HumanInterventionRequired = $false
        HealthCheckLevel = "Standard"
    }
    "Submitting" = @{
        Description = "Agent is submitting prompts to Claude Code CLI"
        AllowedTransitions = @("Monitoring", "Active", "Error", "Stopped")
        IsOperational = $true
        RequiresMonitoring = $true
        HumanInterventionRequired = $false
        HealthCheckLevel = "Standard"
    }
    "Paused" = @{
        Description = "Agent is paused, awaiting human intervention"
        AllowedTransitions = @("Active", "Stopped", "Error")
        IsOperational = $false
        RequiresMonitoring = $true
        HumanInterventionRequired = $true
        HealthCheckLevel = "Minimal"
    }
    "HumanApprovalRequired" = @{
        Description = "Agent requires human approval for high-impact operations"
        AllowedTransitions = @("Processing", "Active", "Paused", "Error", "Stopped")
        IsOperational = $false
        RequiresMonitoring = $true
        HumanInterventionRequired = $true
        HealthCheckLevel = "Standard"
    }
    "Error" = @{
        Description = "Agent encountered an error and requires attention"
        AllowedTransitions = @("Recovering", "Stopped", "Idle", "HumanApprovalRequired")
        IsOperational = $false
        RequiresMonitoring = $true
        HumanInterventionRequired = $false
        HealthCheckLevel = "Diagnostic"
    }
    "Recovering" = @{
        Description = "Agent is attempting autonomous recovery from error state"
        AllowedTransitions = @("Active", "Error", "Stopped", "HumanApprovalRequired")
        IsOperational = $false
        RequiresMonitoring = $true
        HumanInterventionRequired = $false
        HealthCheckLevel = "Intensive"
    }
    "CircuitBreakerOpen" = @{
        Description = "Circuit breaker activated due to repeated failures"
        AllowedTransitions = @("Recovering", "Stopped", "HumanApprovalRequired")
        IsOperational = $false
        RequiresMonitoring = $true
        HumanInterventionRequired = $true
        HealthCheckLevel = "Diagnostic"
    }
    "Stopped" = @{
        Description = "Agent has been safely stopped"
        AllowedTransitions = @("Idle", "Initializing")
        IsOperational = $false
        RequiresMonitoring = $false
        HumanInterventionRequired = $false
        HealthCheckLevel = "None"
    }
}

# Performance counter definitions (based on research findings)
$script:PerformanceCounters = @{
    "CPU" = @{
        CounterPath = "\Processor(_Total)\% Processor Time"
        ThresholdWarning = 60
        ThresholdCritical = 80
        Unit = "Percentage"
    }
    "Memory" = @{
        CounterPath = "\Memory\% Committed Bytes In Use"
        ThresholdWarning = 70
        ThresholdCritical = 85
        Unit = "Percentage"
    }
    "DiskSpace" = @{
        CounterPath = "\LogicalDisk(C:)\% Free Space"
        ThresholdWarning = 15
        ThresholdCritical = 10
        Unit = "Percentage"
    }
    "ProcessCount" = @{
        CounterPath = "\System\Processes"
        ThresholdWarning = 200
        ThresholdCritical = 300
        Unit = "Count"
    }
    "HandleCount" = @{
        CounterPath = "\Process(_Total)\Handle Count"
        ThresholdWarning = 50000
        ThresholdCritical = 75000
        Unit = "Count"
    }
}

#endregion

#region Enhanced Logging and Utilities

function ConvertTo-HashTable {
    <#
    .SYNOPSIS
    PowerShell 5.1 compatible function to convert PSCustomObject to Hashtable
    .DESCRIPTION
    Replaces the -AsHashtable parameter which is not available in PowerShell 5.1.
    Handles nested objects and provides recursive conversion capabilities.
    .PARAMETER Object
    The PSCustomObject to convert to a hashtable
    .PARAMETER Recurse
    If specified, recursively converts nested PSCustomObjects to hashtables
    .NOTES
    Created for PowerShell 5.1 compatibility - replaces ConvertFrom-Json -AsHashtable
    Research validated solution for Unity-Claude Automation compatibility
    #>
    param(
        [Parameter(Mandatory=$true, ValueFromPipeline=$true)]
        [PSCustomObject] $Object,
        [switch] $Recurse
    )
    
    # Handle null or non-object inputs
    if ($null -eq $Object) {
        Write-EnhancedStateLog -Message "ConvertTo-HashTable: Null object provided" -Level "DEBUG"
        return @{}
    }
    
    # Handle already converted hashtables
    if ($Object -is [Hashtable]) {
        Write-EnhancedStateLog -Message "ConvertTo-HashTable: Object is already a hashtable" -Level "DEBUG"
        return $Object
    }
    
    # Create new hashtable for conversion
    $hashtable = @{}
    
    try {
        # Iterate through PSObject properties for conversion
        $Object.PSObject.Properties | ForEach-Object {
            $propertyName = $_.Name
            $propertyValue = $_.Value
            
            # Special handling for DateTime objects to prevent ETS property issues
            if ($propertyValue -is [DateTime] -or ($propertyValue -and $propertyValue.GetType().Name -eq "DateTime")) {
                Write-EnhancedStateLog -Message "ConvertTo-HashTable: Special DateTime handling for property: $propertyName" -Level "DEBUG"
                # Use BaseObject to get underlying .NET DateTime without ETS properties
                $baseDateTime = if ($propertyValue.PSObject.BaseObject) { $propertyValue.PSObject.BaseObject } else { $propertyValue }
                # Store as ISO8601 string for reliable JSON serialization and deserialization
                $hashtable[$propertyName] = $baseDateTime.ToString("yyyy-MM-ddTHH:mm:ss.fffK")
            }
            # Handle recursive conversion for nested objects
            elseif ($Recurse -and ($propertyValue -is [PSCustomObject])) {
                Write-EnhancedStateLog -Message "ConvertTo-HashTable: Recursively converting property: $propertyName" -Level "DEBUG"
                $hashtable[$propertyName] = ConvertTo-HashTable -Object $propertyValue -Recurse
            } 
            else {
                $hashtable[$propertyName] = $propertyValue
            }
        }
        
        Write-EnhancedStateLog -Message "ConvertTo-HashTable: Successfully converted object with $($hashtable.Keys.Count) properties" -Level "DEBUG"
        return $hashtable
        
    } catch {
        Write-EnhancedStateLog -Message "ConvertTo-HashTable: Conversion failed - $($_.Exception.Message)" -Level "ERROR"
        return @{}
    }
}

function Get-SafeDateTime {
    <#
    .SYNOPSIS
    Safely extract DateTime value from various PowerShell object types (PSObject, String, DateTime)
    .DESCRIPTION
    Handles PowerShell ETS DateTime objects, ISO strings, and direct DateTime objects consistently
    .PARAMETER DateTimeObject
    The object to extract DateTime value from
    .NOTES
    Created to resolve PowerShell 5.1 ETS property issues with DateTime objects
    #>
    param(
        [Parameter(Mandatory=$true)]
        $DateTimeObject
    )
    
    try {
        # Handle null or empty cases
        if ($null -eq $DateTimeObject -or $DateTimeObject -eq "") {
            Write-EnhancedStateLog -Message "Get-SafeDateTime: Null or empty DateTime object provided" -Level "DEBUG"
            return $null
        }
        
        # If it's already a proper DateTime, return it
        if ($DateTimeObject -is [DateTime]) {
            Write-EnhancedStateLog -Message "Get-SafeDateTime: Input is already DateTime" -Level "DEBUG"
            return $DateTimeObject
        }
        
        # Handle our custom DateTime hashtable structure (legacy support)
        if ($DateTimeObject -is [Hashtable] -and $DateTimeObject.ContainsKey("Type") -and $DateTimeObject.Type -eq "DateTime") {
            Write-EnhancedStateLog -Message "Get-SafeDateTime: Handling legacy custom DateTime hashtable structure" -Level "DEBUG"
            if ($DateTimeObject.ContainsKey("DateTimeValue")) {
                return [DateTime]$DateTimeObject.DateTimeValue
            } elseif ($DateTimeObject.ContainsKey("Ticks")) {
                return [DateTime]::new([long]$DateTimeObject.Ticks)
            } elseif ($DateTimeObject.ContainsKey("ISO8601")) {
                return [DateTime]::Parse([string]$DateTimeObject.ISO8601)
            }
        }
        
        # If it's a string, try to parse it (handles ISO8601 format)
        if ($DateTimeObject -is [string]) {
            Write-EnhancedStateLog -Message "Get-SafeDateTime: Parsing string DateTime: $DateTimeObject" -Level "DEBUG"
            try {
                # Try parsing as ISO8601 format first
                return [DateTime]::Parse([string]$DateTimeObject, $null, [System.Globalization.DateTimeStyles]::RoundtripKind)
            } catch {
                # Fallback to standard parsing
                return [DateTime]::Parse([string]$DateTimeObject)
            }
        }
        
        # Handle PSObject with ETS properties (DisplayHint, DateTime, value)
        if ($DateTimeObject.PSObject) {
            Write-EnhancedStateLog -Message "Get-SafeDateTime: Handling PSObject with ETS properties" -Level "DEBUG"
            
            # Try to get BaseObject first
            if ($DateTimeObject.PSObject.BaseObject -and $DateTimeObject.PSObject.BaseObject -is [DateTime]) {
                Write-EnhancedStateLog -Message "Get-SafeDateTime: Using PSObject.BaseObject" -Level "DEBUG"
                return [DateTime]$DateTimeObject.PSObject.BaseObject
            }
            
            # Try to access the 'value' property for complex ETS objects
            if ($DateTimeObject.value -and $DateTimeObject.value -is [DateTime]) {
                Write-EnhancedStateLog -Message "Get-SafeDateTime: Using 'value' property from ETS object" -Level "DEBUG"
                return [DateTime]$DateTimeObject.value
            }
            
            # Try to cast the entire object
            try {
                $converted = [DateTime]$DateTimeObject
                Write-EnhancedStateLog -Message "Get-SafeDateTime: Successfully cast PSObject to DateTime" -Level "DEBUG"
                return [DateTime]$converted
            } catch {
                Write-EnhancedStateLog -Message "Get-SafeDateTime: Failed to cast PSObject to DateTime: $($_.Exception.Message)" -Level "DEBUG"
            }
        }
        
        # Last resort: try ToString() and parse
        try {
            $stringValue = $DateTimeObject.ToString()
            Write-EnhancedStateLog -Message "Get-SafeDateTime: Attempting to parse ToString() result: $stringValue" -Level "DEBUG"
            return [DateTime]::Parse([string]$stringValue)
        } catch {
            Write-EnhancedStateLog -Message "Get-SafeDateTime: Failed to parse ToString() result: $($_.Exception.Message)" -Level "DEBUG"
        }
        
        # If all else fails, log error and return null
        Write-EnhancedStateLog -Message "Get-SafeDateTime: Unable to extract DateTime from object type: $($DateTimeObject.GetType().Name)" -Level "ERROR"
        return $null
        
    } catch {
        Write-EnhancedStateLog -Message "Get-SafeDateTime: Exception occurred: $($_.Exception.Message)" -Level "ERROR"
        return $null
    }
}

function Get-UptimeMinutes {
    <#
    .SYNOPSIS
    Safely calculates uptime minutes from StartTime to current time
    .DESCRIPTION
    Completely avoids DateTime subtraction to prevent op_Subtraction ambiguity errors
    .PARAMETER StartTime
    The start time (can be DateTime, string, or hashtable)
    .NOTES
    Uses only ticks arithmetic to avoid PowerShell 5.1 ETS DateTime op_Subtraction issues
    #>
    param(
        [Parameter(Mandatory=$true)]
        $StartTime
    )
    
    try {
        Write-EnhancedStateLog -Message "Get-UptimeMinutes: Calculating uptime from StartTime" -Level "DEBUG"
        
        # Get current time as ticks only - avoid DateTime object operations
        $currentTicks = [long](Get-Date).Ticks
        Write-EnhancedStateLog -Message "Get-UptimeMinutes: Current ticks: $currentTicks" -Level "DEBUG"
        
        # Convert StartTime to DateTime safely and extract ticks
        $startDateTime = Get-SafeDateTime -DateTimeObject $StartTime
        if ($null -eq $startDateTime) {
            Write-EnhancedStateLog -Message "Get-UptimeMinutes: Failed to convert StartTime to DateTime" -Level "ERROR"
            return 0.0
        }
        
        $startTicks = [long]$startDateTime.Ticks
        Write-EnhancedStateLog -Message "Get-UptimeMinutes: Start ticks: $startTicks" -Level "DEBUG"
        
        # Calculate difference using only arithmetic (no DateTime operations)
        # Force explicit conversion to [long] to avoid type ambiguity
        if ([long]$currentTicks -ge [long]$startTicks) {
            $ticksDifference = [long]$currentTicks - [long]$startTicks
            # Convert ticks to minutes: 1 tick = 100 nanoseconds, 1 minute = 600,000,000 ticks
            $uptimeMinutes = [double]([long]$ticksDifference / 600000000.0)
            
            Write-EnhancedStateLog -Message "Get-UptimeMinutes: Calculated uptime: $uptimeMinutes minutes" -Level "DEBUG"
            return [double]$uptimeMinutes
        } else {
            Write-EnhancedStateLog -Message "Get-UptimeMinutes: Start time is in the future, returning 0" -Level "WARNING"
            return 0.0
        }
        
    } catch {
        Write-EnhancedStateLog -Message "Get-UptimeMinutes: Exception occurred: $($_.Exception.Message)" -Level "ERROR"
        Write-EnhancedStateLog -Message "Get-UptimeMinutes: Stack trace: $($_.ScriptStackTrace)" -Level "ERROR"
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
    
    if ($Level -ne "DEBUG" -or $script:EnhancedStateConfig.VerboseLogging) {
        Write-Host $logEntry -ForegroundColor $color
    }
    
    # File logging based on level
    $logFile = switch ($Level) {
        "PERFORMANCE" { $script:EnhancedStateConfig.PerformanceLogFile }
        "INTERVENTION" { $script:EnhancedStateConfig.InterventionLogFile }
        default { $script:EnhancedStateConfig.LogFile }
    }
    
    try {
        $logEntry | Out-File -FilePath (Join-Path $script:EnhancedStateConfig.StateDataPath $logFile) -Append -Encoding UTF8
    } catch {
        Write-Warning "Failed to write to log file: $($_.Exception.Message)"
    }
    
    # Event log for critical items
    if ($Level -in @("ERROR", "INTERVENTION") -and $script:EnhancedStateConfig.NotificationMethods -contains "Event") {
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
        
        # Collect all performance counters in one operation for efficiency
        $counterPaths = $script:PerformanceCounters.Values | ForEach-Object { $_.CounterPath }
        $counterData = Get-Counter -Counter $counterPaths -ErrorAction SilentlyContinue
        
        foreach ($counter in $script:PerformanceCounters.GetEnumerator()) {
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
        
        # Add PowerShell-specific metrics
        $psProcess = Get-Process -Id $PID
        $metrics["PowerShellMemory"] = @{
            Value = [math]::Round($psProcess.WorkingSet64 / 1MB, 2)
            Unit = "MB"
            Status = if ($psProcess.WorkingSet64 / 1MB -gt $script:EnhancedStateConfig.MaxMemoryUsageMB) { "Warning" } else { "Normal" }
            Timestamp = $timestamp
        }
        
        $metrics["PowerShellCPU"] = @{
            Value = [math]::Round($psProcess.CPU, 2)
            Unit = "Seconds"
            Status = "Normal"
            Timestamp = $timestamp
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

#endregion

#region State Machine Core Functions

function Initialize-EnhancedAutonomousStateTracking {
    <#
    .SYNOPSIS
    Initialize enhanced autonomous state tracking with persistence and recovery
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$AgentId,
        
        [string]$InitialState = "Idle",
        
        [switch]$RestoreFromCheckpoint
    )
    
    try {
        Write-EnhancedStateLog -Message "Initializing enhanced autonomous state tracking for agent: $AgentId" -Level "INFO"
        
        # Create agent state structure with proper DateTime handling
        $currentTime = Get-Date
        $agentState = @{
            AgentId = $AgentId
            CurrentState = $InitialState
            PreviousState = $null
            StateHistory = @()
            StartTime = $currentTime
            LastStateChange = $currentTime
            LastHealthCheck = $currentTime
            HealthMetrics = @{}
            InterventionHistory = @()
            CheckpointHistory = @()
            ConsecutiveFailures = 0
            SuccessfulOperations = 0
            TotalOperations = 0
            CircuitBreakerState = "Closed"
            HumanInterventionRequested = $false
            PerformanceBaseline = @{}
        }
        
        # Attempt to restore from checkpoint if requested
        if ($RestoreFromCheckpoint) {
            $restored = Restore-AgentStateFromCheckpoint -AgentId $AgentId
            if ($restored) {
                $agentState = $restored
                Write-EnhancedStateLog -Message "Agent state restored from checkpoint" -Level "INFO"
            }
        }
        
        # Validate initial state
        if (-not $script:EnhancedAutonomousStates.ContainsKey($agentState.CurrentState)) {
            throw "Invalid initial state: $($agentState.CurrentState)"
        }
        
        # Save initial state
        Save-AgentState -AgentState $agentState
        
        # Create initial checkpoint
        New-StateCheckpoint -AgentState $agentState -Reason "Initial state tracking initialization"
        
        Write-EnhancedStateLog -Message "Enhanced autonomous state tracking initialized successfully" -Level "INFO" -AdditionalData @{
            AgentId = $AgentId
            InitialState = $agentState.CurrentState
            RestoreRequested = $RestoreFromCheckpoint.IsPresent
        }
        
        return $agentState
        
    } catch {
        Write-EnhancedStateLog -Message "Failed to initialize enhanced state tracking: $($_.Exception.Message)" -Level "ERROR"
        throw
    }
}

function Set-EnhancedAutonomousState {
    <#
    .SYNOPSIS
    Set autonomous agent state with enhanced validation and persistence
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$AgentId,
        
        [Parameter(Mandatory = $true)]
        [string]$NewState,
        
        [string]$Reason = "State transition",
        
        [hashtable]$AdditionalData = @{},
        
        [switch]$Force
    )
    
    try {
        # Load current agent state
        $agentState = Get-AgentState -AgentId $AgentId
        if (-not $agentState) {
            throw "Agent state not found for AgentId: $AgentId"
        }
        
        $currentState = $agentState.CurrentState
        
        # Validate state transition unless forced
        if (-not $Force) {
            $allowedTransitions = $script:EnhancedAutonomousStates[$currentState].AllowedTransitions
            if ($NewState -notin $allowedTransitions) {
                throw "Invalid state transition from '$currentState' to '$NewState'. Allowed transitions: $($allowedTransitions -join ', ')"
            }
        }
        
        # Validate new state exists
        if (-not $script:EnhancedAutonomousStates.ContainsKey($NewState)) {
            throw "Invalid state: $NewState"
        }
        
        Write-EnhancedStateLog -Message "State transition: $currentState -> $NewState | Reason: $Reason" -Level "INFO" -AdditionalData $AdditionalData
        
        # Update agent state with proper DateTime handling
        $changeTime = Get-Date
        $agentState.PreviousState = $currentState
        $agentState.CurrentState = $NewState
        $agentState.LastStateChange = $changeTime
        
        # Add to state history
        $stateTransition = @{
            FromState = $currentState
            ToState = $NewState
            Timestamp = $changeTime
            Reason = $Reason
            AdditionalData = $AdditionalData
            Forced = $Force.IsPresent
        }
        
        $agentState.StateHistory = @($agentState.StateHistory) + @($stateTransition)
        
        # Trim state history if needed
        if ($agentState.StateHistory.Count -gt $script:EnhancedStateConfig.StateHistoryRetention) {
            $agentState.StateHistory = $agentState.StateHistory | Select-Object -Last $script:EnhancedStateConfig.StateHistoryRetention
        }
        
        # Handle special state transitions
        switch ($NewState) {
            "Error" {
                $agentState.ConsecutiveFailures++
                
                # Check for circuit breaker activation
                if ($agentState.ConsecutiveFailures -ge $script:EnhancedStateConfig.CircuitBreakerFailureThreshold -and 
                    $agentState.CircuitBreakerState -eq "Closed") {
                    
                    Write-EnhancedStateLog -Message "Circuit breaker opened due to consecutive failures: $($agentState.ConsecutiveFailures)" -Level "WARNING"
                    $agentState.CircuitBreakerState = "Open"
                    $NewState = "CircuitBreakerOpen"  # Override the state to circuit breaker
                    
                    # Request human intervention for circuit breaker
                    Request-HumanIntervention -AgentId $AgentId -Reason "Circuit breaker activated" -Priority "High"
                }
            }
            "Active" {
                if ($agentState.PreviousState -eq "Error" -or $agentState.PreviousState -eq "Recovering") {
                    $agentState.ConsecutiveFailures = 0  # Reset failure count on successful recovery
                    $agentState.CircuitBreakerState = "Closed"
                }
                $agentState.SuccessfulOperations++
            }
            "HumanApprovalRequired" {
                Request-HumanIntervention -AgentId $AgentId -Reason $Reason -Priority "Medium"
            }
        }
        
        $agentState.TotalOperations++
        
        # Save updated state
        Save-AgentState -AgentState $agentState
        
        # Create checkpoint for critical state changes
        if ($NewState -in @("Error", "CircuitBreakerOpen", "HumanApprovalRequired", "Stopped")) {
            New-StateCheckpoint -AgentState $agentState -Reason "Critical state change: $NewState"
        }
        
        return $agentState
        
    } catch {
        Write-EnhancedStateLog -Message "Failed to set autonomous state: $($_.Exception.Message)" -Level "ERROR"
        throw
    }
}

function Get-EnhancedAutonomousState {
    <#
    .SYNOPSIS
    Get current autonomous agent state with enhanced information
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$AgentId,
        
        [switch]$IncludeHistory,
        
        [switch]$IncludePerformanceMetrics
    )
    
    try {
        $agentState = Get-AgentState -AgentId $AgentId
        if (-not $agentState) {
            return $null
        }
        
        # Calculate current success rate
        $successRate = if ($agentState.TotalOperations -gt 0) {
            [math]::Round($agentState.SuccessfulOperations / $agentState.TotalOperations, 3)
        } else {
            0
        }
        
        # Get current state definition
        $stateDefinition = $script:EnhancedAutonomousStates[$agentState.CurrentState]
        
        # Build response object
        $response = @{
            AgentId = $agentState.AgentId
            CurrentState = $agentState.CurrentState
            PreviousState = $agentState.PreviousState
            StateDescription = $stateDefinition.Description
            IsOperational = $stateDefinition.IsOperational
            RequiresMonitoring = $stateDefinition.RequiresMonitoring
            HumanInterventionRequired = $stateDefinition.HumanInterventionRequired
            LastStateChange = $agentState.LastStateChange
            UptimeMinutes = if ($agentState.StartTime) { 
                [math]::Round((Get-UptimeMinutes -StartTime $agentState.StartTime), 2) 
            } else { 
                0.0 
            }
            SuccessRate = $successRate
            ConsecutiveFailures = $agentState.ConsecutiveFailures
            TotalOperations = $agentState.TotalOperations
            CircuitBreakerState = $agentState.CircuitBreakerState
            HumanInterventionRequested = $agentState.HumanInterventionRequested
        }
        
        # Add history if requested
        if ($IncludeHistory) {
            $response.StateHistory = $agentState.StateHistory | Select-Object -Last 20
            $response.InterventionHistory = $agentState.InterventionHistory | Select-Object -Last 10
        }
        
        # Add performance metrics if requested
        if ($IncludePerformanceMetrics) {
            $response.CurrentPerformanceMetrics = Get-SystemPerformanceMetrics
            $response.HealthMetrics = $agentState.HealthMetrics
        }
        
        return $response
        
    } catch {
        Write-EnhancedStateLog -Message "Failed to get autonomous state: $($_.Exception.Message)" -Level "ERROR"
        throw
    }
}

#endregion

#region State Persistence and Recovery

function Save-AgentState {
    <#
    .SYNOPSIS
    Save agent state to JSON with backup rotation
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [hashtable]$AgentState
    )
    
    try {
        $agentId = $AgentState.AgentId
        $stateFile = Join-Path $script:EnhancedStateConfig.StateDataPath "$agentId.json"
        
        # Create backup of existing state
        if (Test-Path $stateFile) {
            $backupFile = Join-Path $script:EnhancedStateConfig.BackupPath "$agentId-$(Get-Date -Format 'yyyyMMdd-HHmmss').json"
            Copy-Item $stateFile $backupFile -ErrorAction SilentlyContinue
        }
        
        # Save current state
        $AgentState | ConvertTo-Json -Depth 10 | Out-File -FilePath $stateFile -Encoding UTF8
        
        Write-EnhancedStateLog -Message "Agent state saved successfully" -Level "DEBUG" -AdditionalData @{ AgentId = $agentId }
        
    } catch {
        Write-EnhancedStateLog -Message "Failed to save agent state: $($_.Exception.Message)" -Level "ERROR"
        throw
    }
}

function Get-AgentState {
    <#
    .SYNOPSIS
    Load agent state from JSON
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$AgentId
    )
    
    try {
        $stateFile = Join-Path $script:EnhancedStateConfig.StateDataPath "$AgentId.json"
        
        if (-not (Test-Path $stateFile)) {
            return $null
        }
        
        $stateJson = Get-Content $stateFile -Raw
        $agentState = ConvertTo-HashTable -Object ($stateJson | ConvertFrom-Json) -Recurse
        
        return $agentState
        
    } catch {
        Write-EnhancedStateLog -Message "Failed to load agent state: $($_.Exception.Message)" -Level "ERROR"
        return $null
    }
}

function New-StateCheckpoint {
    <#
    .SYNOPSIS
    Create a state checkpoint for recovery purposes (based on research findings)
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [hashtable]$AgentState,
        
        [string]$Reason = "Scheduled checkpoint"
    )
    
    try {
        $timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
        $checkpointId = "$($AgentState.AgentId)-$timestamp"
        $checkpointFile = Join-Path $script:EnhancedStateConfig.CheckpointPath "$checkpointId.json"
        
        # Create checkpoint data
        $checkpoint = @{
            CheckpointId = $checkpointId
            AgentId = $AgentState.AgentId
            Timestamp = Get-Date
            Reason = $Reason
            AgentState = $AgentState
            SystemState = Get-SystemPerformanceMetrics
            PowerShellProcess = @{
                PID = $PID
                WorkingSet = (Get-Process -Id $PID).WorkingSet64
                StartTime = Get-SafeDateTime -DateTimeObject (Get-Process -Id $PID).StartTime
            }
        }
        
        # Save checkpoint
        $checkpoint | ConvertTo-Json -Depth 15 | Out-File -FilePath $checkpointFile -Encoding UTF8
        
        # Update agent state with checkpoint reference
        $checkpointEntry = @{
            CheckpointId = $checkpointId
            Timestamp = Get-Date
            Reason = $Reason
            FilePath = $checkpointFile
        }
        $AgentState.CheckpointHistory = @($AgentState.CheckpointHistory) + @($checkpointEntry)
        
        # Trim checkpoint history
        if ($AgentState.CheckpointHistory.Count -gt 50) {
            $AgentState.CheckpointHistory = $AgentState.CheckpointHistory | Select-Object -Last 50
        }
        
        Write-EnhancedStateLog -Message "State checkpoint created: $checkpointId" -Level "INFO" -AdditionalData @{ Reason = $Reason }
        
        return $checkpointId
        
    } catch {
        Write-EnhancedStateLog -Message "Failed to create state checkpoint: $($_.Exception.Message)" -Level "ERROR"
        throw
    }
}

function Restore-AgentStateFromCheckpoint {
    <#
    .SYNOPSIS
    Restore agent state from the most recent checkpoint
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$AgentId,
        
        [string]$CheckpointId
    )
    
    try {
        $checkpointFiles = Get-ChildItem -Path $script:EnhancedStateConfig.CheckpointPath -Filter "$AgentId-*.json" | 
                          Sort-Object LastWriteTime -Descending
        
        if (-not $checkpointFiles) {
            Write-EnhancedStateLog -Message "No checkpoints found for agent: $AgentId" -Level "WARNING"
            return $null
        }
        
        $targetCheckpoint = if ($CheckpointId) {
            $checkpointFiles | Where-Object { $_.BaseName -eq $CheckpointId } | Select-Object -First 1
        } else {
            $checkpointFiles | Select-Object -First 1  # Most recent
        }
        
        if (-not $targetCheckpoint) {
            Write-EnhancedStateLog -Message "Checkpoint not found: $CheckpointId" -Level "WARNING"
            return $null
        }
        
        # Load checkpoint data
        $checkpointJson = Get-Content $targetCheckpoint.FullName -Raw
        $checkpointData = ConvertTo-HashTable -Object ($checkpointJson | ConvertFrom-Json) -Recurse
        
        # Extract agent state
        $restoredState = $checkpointData.AgentState
        
        # Update restoration metadata
        $restoredState.RestoredFromCheckpoint = $checkpointData.CheckpointId
        $restoredState.RestoredAt = Get-Date
        
        Write-EnhancedStateLog -Message "Agent state restored from checkpoint: $($checkpointData.CheckpointId)" -Level "INFO" -AdditionalData @{
            AgentId = $AgentId
            CheckpointTimestamp = $checkpointData.Timestamp
        }
        
        return $restoredState
        
    } catch {
        Write-EnhancedStateLog -Message "Failed to restore from checkpoint: $($_.Exception.Message)" -Level "ERROR"
        return $null
    }
}

#endregion

#region Human Intervention System

function Request-HumanIntervention {
    <#
    .SYNOPSIS
    Request human intervention with multiple notification methods
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$AgentId,
        
        [Parameter(Mandatory = $true)]
        [string]$Reason,
        
        [ValidateSet("Low", "Medium", "High", "Critical")]
        [string]$Priority = "Medium",
        
        [hashtable]$Context = @{}
    )
    
    try {
        $timestamp = Get-Date
        $interventionId = New-Guid | Select-Object -ExpandProperty Guid
        
        # Create intervention record
        $intervention = @{
            InterventionId = $interventionId
            AgentId = $AgentId
            Timestamp = $timestamp
            Reason = $Reason
            Priority = $Priority
            Context = $Context
            Status = "Requested"
            ResponseDeadline = $timestamp.AddSeconds($script:EnhancedStateConfig.HumanApprovalTimeout)
            ResolutionTime = $null
            Response = $null
        }
        
        # Update agent state
        $agentState = Get-AgentState -AgentId $AgentId
        if ($agentState) {
            $agentState.HumanInterventionRequested = $true
            $agentState.InterventionHistory = @($agentState.InterventionHistory) + @($intervention)
            Save-AgentState -AgentState $agentState
        }
        
        # Log intervention request
        Write-EnhancedStateLog -Message "Human intervention requested: $Reason" -Level "INTERVENTION" -AdditionalData @{
            InterventionId = $interventionId
            Priority = $Priority
            AgentId = $AgentId
        }
        
        # Send notifications based on configuration
        foreach ($method in $script:EnhancedStateConfig.NotificationMethods) {
            switch ($method) {
                "Console" {
                    $message = @"
[HUMAN INTERVENTION REQUIRED]
Agent: $AgentId
Priority: $Priority
Reason: $Reason
Intervention ID: $interventionId
Response required by: $($intervention.ResponseDeadline)

Actions available:
- Use 'Approve-AgentIntervention -InterventionId $interventionId' to approve
- Use 'Deny-AgentIntervention -InterventionId $interventionId -Reason "explanation"' to deny
- Use 'Get-PendingInterventions -AgentId $AgentId' to view all pending interventions
"@
                    Write-Host $message -ForegroundColor Yellow -BackgroundColor DarkRed
                }
                "File" {
                    $interventionFile = Join-Path $script:EnhancedStateConfig.StateDataPath "pending_interventions.json"
                    $existingInterventions = if (Test-Path $interventionFile) {
                        $existingData = ConvertTo-HashTable -Object (Get-Content $interventionFile -Raw | ConvertFrom-Json) -Recurse
                        if ($existingData -is [Array]) { $existingData } else { @() }
                    } else {
                        @()
                    }
                    $existingInterventions = @($existingInterventions) + @($intervention)
                    $existingInterventions | ConvertTo-Json -Depth 10 | Out-File -FilePath $interventionFile -Encoding UTF8
                }
            }
        }
        
        return $interventionId
        
    } catch {
        Write-EnhancedStateLog -Message "Failed to request human intervention: $($_.Exception.Message)" -Level "ERROR"
        throw
    }
}

function Approve-AgentIntervention {
    <#
    .SYNOPSIS
    Approve a pending human intervention request
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$InterventionId,
        
        [string]$Response = "Approved",
        
        [string]$NextAction = "Continue"
    )
    
    try {
        # Find and update intervention
        $updated = Update-InterventionStatus -InterventionId $InterventionId -Status "Approved" -Response $Response
        
        if ($updated) {
            Write-EnhancedStateLog -Message "Human intervention approved: $InterventionId" -Level "INTERVENTION" -AdditionalData @{
                Response = $Response
                NextAction = $NextAction
            }
            
            # Update agent state to clear intervention flag
            $agentState = Get-AgentState -AgentId $updated.AgentId
            if ($agentState) {
                $agentState.HumanInterventionRequested = $false
                Save-AgentState -AgentState $agentState
                
                # Transition to appropriate state based on next action
                switch ($NextAction) {
                    "Continue" { 
                        if ($agentState.CurrentState -ne "Active") {
                            Set-EnhancedAutonomousState -AgentId $updated.AgentId -NewState "Active" -Reason "Human intervention approved"
                        }
                    }
                    "Pause" { Set-EnhancedAutonomousState -AgentId $updated.AgentId -NewState "Paused" -Reason "Human intervention approved - paused" }
                    "Stop" { Set-EnhancedAutonomousState -AgentId $updated.AgentId -NewState "Stopped" -Reason "Human intervention approved - stopped" }
                }
            }
            
            return $true
        }
        
        return $false
        
    } catch {
        Write-EnhancedStateLog -Message "Failed to approve intervention: $($_.Exception.Message)" -Level "ERROR"
        throw
    }
}

function Deny-AgentIntervention {
    <#
    .SYNOPSIS
    Deny a pending human intervention request
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$InterventionId,
        
        [Parameter(Mandatory = $true)]
        [string]$Reason
    )
    
    try {
        $updated = Update-InterventionStatus -InterventionId $InterventionId -Status "Denied" -Response $Reason
        
        if ($updated) {
            Write-EnhancedStateLog -Message "Human intervention denied: $InterventionId" -Level "INTERVENTION" -AdditionalData @{
                Reason = $Reason
            }
            
            # Update agent state
            $agentState = Get-AgentState -AgentId $updated.AgentId
            if ($agentState) {
                $agentState.HumanInterventionRequested = $false
                Save-AgentState -AgentState $agentState
                
                # Transition to paused state for manual resolution
                Set-EnhancedAutonomousState -AgentId $updated.AgentId -NewState "Paused" -Reason "Human intervention denied: $Reason"
            }
            
            return $true
        }
        
        return $false
        
    } catch {
        Write-EnhancedStateLog -Message "Failed to deny intervention: $($_.Exception.Message)" -Level "ERROR"
        throw
    }
}

function Update-InterventionStatus {
    <#
    .SYNOPSIS
    Update intervention status in persistent storage
    #>
    [CmdletBinding()]
    param(
        [string]$InterventionId,
        [string]$Status,
        [string]$Response
    )
    
    try {
        $interventionFile = Join-Path $script:EnhancedStateConfig.StateDataPath "pending_interventions.json"
        
        if (-not (Test-Path $interventionFile)) {
            return $null
        }
        
        $interventionsData = ConvertTo-HashTable -Object (Get-Content $interventionFile -Raw | ConvertFrom-Json) -Recurse
        $interventions = if ($interventionsData -is [Array]) { $interventionsData } else { @($interventionsData) }
        $targetIntervention = $interventions | Where-Object { $_.InterventionId -eq $InterventionId }
        
        if ($targetIntervention) {
            $targetIntervention.Status = $Status
            $targetIntervention.Response = $Response
            $targetIntervention.ResolutionTime = Get-Date
            
            # Save updated interventions
            $interventions | ConvertTo-Json -Depth 10 | Out-File -FilePath $interventionFile -Encoding UTF8
            
            return $targetIntervention
        }
        
        return $null
        
    } catch {
        Write-EnhancedStateLog -Message "Failed to update intervention status: $($_.Exception.Message)" -Level "ERROR"
        return $null
    }
}

#endregion

#region Performance and Health Monitoring

function Start-EnhancedHealthMonitoring {
    <#
    .SYNOPSIS
    Start enhanced health monitoring with performance counters and thresholds
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$AgentId
    )
    
    try {
        Write-EnhancedStateLog -Message "Starting enhanced health monitoring for agent: $AgentId" -Level "INFO"
        
        # Create monitoring job
        $monitoringScript = {
            param($AgentId, $StateConfig, $PerformanceCounters, $EnhancedAutonomousStates)
            
            # Import module functions in job context
            $modulePath = Split-Path $PSScriptRoot -Parent
            Import-Module (Join-Path $modulePath "Unity-Claude-AutonomousStateTracker-Enhanced.psm1") -Force
            
            while ($true) {
                try {
                    # Get current agent state
                    $agentState = Get-AgentState -AgentId $AgentId
                    if (-not $agentState) {
                        Start-Sleep -Seconds $StateConfig.HealthCheckIntervalSeconds
                        continue
                    }
                    
                    # Skip monitoring if not required
                    $stateDefinition = $EnhancedAutonomousStates[$agentState.CurrentState]
                    if (-not $stateDefinition.RequiresMonitoring) {
                        Start-Sleep -Seconds $StateConfig.HealthCheckIntervalSeconds
                        continue
                    }
                    
                    # Collect performance metrics
                    $performanceMetrics = Get-SystemPerformanceMetrics
                    
                    # Test health thresholds
                    $healthAssessment = Test-SystemHealthThresholds -PerformanceMetrics $performanceMetrics
                    
                    # Update agent state with health data
                    $agentState.HealthMetrics = $performanceMetrics
                    $agentState.LastHealthCheck = Get-Date
                    
                    # Handle health issues
                    if ($healthAssessment.RequiresIntervention) {
                        $reasons = $healthAssessment.CriticalIssues -join "; "
                        Request-HumanIntervention -AgentId $AgentId -Reason "Critical system health issues: $reasons" -Priority "Critical"
                        
                        # Transition to error state
                        Set-EnhancedAutonomousState -AgentId $AgentId -NewState "Error" -Reason "Critical health threshold exceeded"
                    } elseif ($healthAssessment.RequiresAttention) {
                        $reasons = $healthAssessment.HealthIssues -join "; "
                        Write-EnhancedStateLog -Message "Health warning: $reasons" -Level "WARNING" -Component "HealthMonitor"
                    }
                    
                    # Save updated state
                    Save-AgentState -AgentState $agentState
                    
                    # Log performance data
                    Write-EnhancedStateLog -Message "Health check completed" -Level "PERFORMANCE" -AdditionalData $performanceMetrics
                    
                } catch {
                    Write-EnhancedStateLog -Message "Health monitoring error: $($_.Exception.Message)" -Level "ERROR" -Component "HealthMonitor"
                }
                
                Start-Sleep -Seconds $StateConfig.HealthCheckIntervalSeconds
            }
        }
        
        # Start monitoring job
        $job = Start-Job -ScriptBlock $monitoringScript -ArgumentList $AgentId, $script:EnhancedStateConfig, $script:PerformanceCounters, $script:EnhancedAutonomousStates
        
        Write-EnhancedStateLog -Message "Enhanced health monitoring started (Job ID: $($job.Id))" -Level "INFO"
        
        return $job
        
    } catch {
        Write-EnhancedStateLog -Message "Failed to start health monitoring: $($_.Exception.Message)" -Level "ERROR"
        throw
    }
}

function Stop-EnhancedHealthMonitoring {
    <#
    .SYNOPSIS
    Stop enhanced health monitoring jobs
    #>
    [CmdletBinding()]
    param(
        [string]$AgentId
    )
    
    try {
        # Find and stop monitoring jobs
        $jobs = Get-Job | Where-Object { $_.Command -like "*HealthMonitoring*" }
        
        foreach ($job in $jobs) {
            Stop-Job $job -ErrorAction SilentlyContinue
            Remove-Job $job -Force -ErrorAction SilentlyContinue
        }
        
        Write-EnhancedStateLog -Message "Enhanced health monitoring stopped" -Level "INFO"
        
    } catch {
        Write-EnhancedStateLog -Message "Failed to stop health monitoring: $($_.Exception.Message)" -Level "ERROR"
    }
}

#endregion

#region Public Interface

# Export enhanced public functions
Export-ModuleMember -Function @(
    # Core state management
    'Initialize-EnhancedAutonomousStateTracking',
    'Set-EnhancedAutonomousState',
    'Get-EnhancedAutonomousState',
    'Get-AgentState',
    'Save-AgentState',
    
    # State persistence and recovery
    'New-StateCheckpoint',
    'Restore-AgentStateFromCheckpoint',
    
    # Human intervention
    'Request-HumanIntervention',
    'Approve-AgentIntervention',
    'Deny-AgentIntervention',
    
    # Health and performance monitoring
    'Start-EnhancedHealthMonitoring',
    'Stop-EnhancedHealthMonitoring',
    'Get-SystemPerformanceMetrics',
    'Test-SystemHealthThresholds',
    
    # Utilities and compatibility
    'Write-EnhancedStateLog',
    'ConvertTo-HashTable',
    'Get-SafeDateTime',
    'Get-UptimeMinutes'
)

Write-Host "[Enhanced-StateTracker] Phase 3 autonomous state management module loaded successfully" -ForegroundColor Green
Write-Host "[Enhanced-StateTracker] Features: Enhanced state machine, JSON persistence, performance monitoring, human intervention" -ForegroundColor Gray

#endregion
# SIG # Begin signature block
# MIIFqQYJKoZIhvcNAQcCoIIFmjCCBZYCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUCNSgdiWT/5AFQdORQU7fqZgs
# VCSgggMwMIIDLDCCAhSgAwIBAgIQdR0W2SKoK5VE8JId4ZxrRTANBgkqhkiG9w0B
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
# CQQxFgQUugv9I5BkZOO3FkCTYCFntCpMlakwDQYJKoZIhvcNAQEBBQAEggEAF/Bn
# tbF2h6pCb3uITy9+x+LV2Fkn18KHoLYphorQu2zBxqJBUfoV99j9PSxZMZDuxFxa
# 3i48MBSuCC8y/g2zJuPcdwMUaTHbYHddxeBShu66hbRzmxLjk/zSD2u0xw0h1W7O
# EmsF8TU+5BoSKMajgaKYSQ5rXBXFAzinkt7i/xOZMLNwf7i6Z3LKZh5cBBCIcXqF
# TLO4XfrGiPvOIIFVIZvVgZPJakx+AByHqbhrvrU5msdmHCj9jGGC05zPLEsZa4gw
# 2opnRiBWbVDdSbDeG4q4Y252jGUgiHXUwyJXAykFhFCqgpBnlzncaisszYw+uLkK
# slNg43xwm07GfPK8QQ==
# SIG # End signature block
