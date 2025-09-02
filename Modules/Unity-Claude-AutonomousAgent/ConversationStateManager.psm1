# ConversationStateManager.psm1
# Phase 3 Day 16: Advanced Conversation Management - Enhanced Multi-Turn Dialogue
# Provides advanced state tracking, role-aware history, goal management, and context preservation for autonomous Claude Code CLI agent
#
# REFACTORED: This module has been refactored into modular components (2025-08-26)
# The manifest now loads ConversationStateManager-Refactored.psm1 which orchestrates 6 focused components
# Original size: 1,399 lines | Components: 6 | Complexity reduction: 78%
# This file is preserved for reference and backward compatibility testing
#
# === MONOLITHIC VERSION - DO NOT USE IN PRODUCTION ===
Write-Host "[ConversationStateManager] WARNING: Loading MONOLITHIC version (1,399 lines)" -ForegroundColor Yellow
Write-Host "[ConversationStateManager] Use ConversationStateManager.psd1 manifest for refactored version" -ForegroundColor Yellow

# Module-level variables for state management
$script:ConversationState = $null
$script:StateHistory = @()
$script:ConversationHistory = @()
$script:SessionMetadata = @{}
$script:MaxHistorySize = 20
$script:StatePersistencePath = Join-Path $PSScriptRoot "ConversationState.json"
$script:HistoryPersistencePath = Join-Path $PSScriptRoot "ConversationHistory.json"

# Day 16 Enhancement: Advanced Conversation Management Variables
$script:ConversationGoals = @()
$script:RoleAwareHistory = @()
$script:DialoguePatterns = @{}
$script:ConversationEffectiveness = @{}
$script:GoalsPersistencePath = Join-Path $PSScriptRoot "ConversationGoals.json"
$script:EffectivenessPersistencePath = Join-Path $PSScriptRoot "ConversationEffectiveness.json"
$script:MaxRoleHistorySize = 50

# Logging configuration
$script:LogPath = Join-Path (Split-Path (Split-Path $PSScriptRoot -Parent) -Parent) "unity_claude_automation.log"
$script:LogMutex = [System.Threading.Mutex]::new($false, "UnityClaudeAutomationLogMutex")

function Write-StateLog {
    param(
        [string]$Message,
        [string]$Level = "INFO",
        [string]$Component = "ConversationStateManager"
    )
    
    try {
        $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss.fff"
        $logEntry = "[$timestamp] [$Level] [$Component] $Message"
        
        # Thread-safe file writing
        $acquired = $script:LogMutex.WaitOne(1000)
        if ($acquired) {
            try {
                Add-Content -Path $script:LogPath -Value $logEntry -ErrorAction SilentlyContinue
            }
            finally {
                $script:LogMutex.ReleaseMutex()
            }
        }
    }
    catch {
        Write-Verbose "Failed to write log: $_"
    }
}

function Initialize-ConversationState {
    <#
    .SYNOPSIS
    Initializes the conversation state machine
    
    .DESCRIPTION
    Sets up the initial state, loads persisted state if available, and prepares the state machine
    
    .PARAMETER SessionId
    Optional session identifier for continuing previous sessions
    
    .PARAMETER LoadPersisted
    Whether to load previously persisted state
    #>
    param(
        [string]$SessionId = "",
        [switch]$LoadPersisted
    )
    
    Write-StateLog "Initializing conversation state machine" -Level "INFO"
    
    try {
        # Generate session ID if not provided
        if ([string]::IsNullOrEmpty($SessionId)) {
            $SessionId = [Guid]::NewGuid().ToString()
            Write-StateLog "Generated new session ID: $SessionId" -Level "INFO"
        }
        
        # Define state machine structure
        $script:ConversationState = @{
            CurrentState = "Idle"
            PreviousState = $null
            SessionId = $SessionId
            StartTime = Get-Date
            LastStateChange = Get-Date
            TransitionCount = 0
            ErrorCount = 0
            SuccessCount = 0
            Metadata = @{
                UnityVersion = "2021.1.14f1"
                PowerShellVersion = $PSVersionTable.PSVersion.ToString()
                ModuleVersion = "2.0.0"
            }
        }
        
        # Initialize session metadata
        $script:SessionMetadata = @{
            SessionId = $SessionId
            StartTime = Get-Date
            ConversationRounds = 0
            TotalCommands = 0
            SuccessfulCommands = 0
            FailedCommands = 0
            AverageResponseTime = 0
            LastActivity = Get-Date
        }
        
        # Day 16 Enhancement: Initialize Advanced Conversation Management
        Write-StateLog "Initializing advanced conversation management features" -Level "INFO"
        
        # Initialize conversation goals tracking
        $script:ConversationGoals = @()
        
        # Initialize role-aware conversation history
        $script:RoleAwareHistory = @()
        
        # Initialize dialogue patterns for domain-agnostic management
        $script:DialoguePatterns = @{
            UserIntents = @{}
            SystemResponses = @{}
            ConversationFlows = @()
            EffectivenessScores = @{}
        }
        
        # Initialize conversation effectiveness tracking
        $script:ConversationEffectiveness = @{
            GoalCompletionRate = 0.0
            AverageUserSatisfaction = 0.0
            ConversationLength = 0
            TopicCoherence = 0.0
            ResponseRelevance = 0.0
            RecoverySuccess = 0.0
            LastCalculation = Get-Date
        }
        
        Write-StateLog "Advanced conversation management features initialized" -Level "SUCCESS"
        
        # Load persisted state if requested
        if ($LoadPersisted -and (Test-Path $script:StatePersistencePath)) {
            Write-StateLog "Loading persisted state from: $script:StatePersistencePath" -Level "INFO"
            $persisted = Get-Content $script:StatePersistencePath -Raw | ConvertFrom-Json
            
            # Restore relevant fields
            if ($persisted.SessionId -eq $SessionId) {
                $script:ConversationState.TransitionCount = $persisted.TransitionCount
                $script:ConversationState.ErrorCount = $persisted.ErrorCount
                $script:ConversationState.SuccessCount = $persisted.SuccessCount
                Write-StateLog "Restored persisted state for session: $SessionId" -Level "INFO"
            }
        }
        
        # Load conversation history if available
        if ($LoadPersisted -and (Test-Path $script:HistoryPersistencePath)) {
            Write-StateLog "Loading conversation history from: $script:HistoryPersistencePath" -Level "INFO"
            $historyData = Get-Content $script:HistoryPersistencePath -Raw | ConvertFrom-Json
            
            # Convert back to proper PowerShell objects
            $script:ConversationHistory = @()
            foreach ($item in $historyData) {
                $script:ConversationHistory += [PSCustomObject]$item
            }
            
            Write-StateLog "Loaded $($script:ConversationHistory.Count) history items" -Level "INFO"
        }
        
        # Initialize state history
        $script:StateHistory = @()
        
        Write-StateLog "Conversation state machine initialized successfully" -Level "SUCCESS"
        return @{
            Success = $true
            SessionId = $SessionId
            State = $script:ConversationState
        }
    }
    catch {
        Write-StateLog "Failed to initialize conversation state: $_" -Level "ERROR"
        return @{
            Success = $false
            Error = $_.Exception.Message
        }
    }
}

function Set-ConversationState {
    <#
    .SYNOPSIS
    Transitions the conversation to a new state
    
    .DESCRIPTION
    Validates and performs state transitions with logging and history tracking
    
    .PARAMETER NewState
    The target state to transition to
    
    .PARAMETER Reason
    Optional reason for the state transition
    
    .PARAMETER Metadata
    Optional metadata to attach to the transition
    #>
    param(
        [Parameter(Mandatory = $true)]
        [ValidateSet("Idle", "Initializing", "Processing", "WaitingForInput", 
                     "Analyzing", "GeneratingPrompt", "Error", "Completed")]
        [string]$NewState,
        
        [string]$Reason = "",
        
        [hashtable]$Metadata = @{}
    )
    
    Write-StateLog "Attempting state transition: $($script:ConversationState.CurrentState) -> $NewState" -Level "INFO"
    
    try {
        # Validate state transition
        $validTransitions = Get-ValidStateTransitions -CurrentState $script:ConversationState.CurrentState
        
        if ($NewState -notin $validTransitions -and $NewState -ne "Error") {
            Write-StateLog "Invalid state transition attempted: $($script:ConversationState.CurrentState) -> $NewState" -Level "WARNING"
            return @{
                Success = $false
                Error = "Invalid state transition"
                ValidTransitions = $validTransitions
            }
        }
        
        # Record transition in history
        $transition = @{
            FromState = $script:ConversationState.CurrentState
            ToState = $NewState
            Timestamp = Get-Date
            Reason = $Reason
            Metadata = $Metadata
        }
        
        $script:StateHistory += $transition
        
        # Update state
        $script:ConversationState.PreviousState = $script:ConversationState.CurrentState
        $script:ConversationState.CurrentState = $NewState
        $script:ConversationState.LastStateChange = Get-Date
        $script:ConversationState.TransitionCount++
        
        # Update error count if transitioning to error state
        if ($NewState -eq "Error") {
            $script:ConversationState.ErrorCount++
        }
        
        # Update success count if transitioning to completed state
        if ($NewState -eq "Completed") {
            $script:ConversationState.SuccessCount++
        }
        
        # Persist state
        Save-ConversationState
        
        Write-StateLog "State transition successful: $($transition.FromState) -> $($transition.ToState)" -Level "SUCCESS"
        
        return @{
            Success = $true
            CurrentState = $NewState
            PreviousState = $script:ConversationState.PreviousState
            TransitionCount = $script:ConversationState.TransitionCount
        }
    }
    catch {
        Write-StateLog "Failed to set conversation state: $_" -Level "ERROR"
        return @{
            Success = $false
            Error = $_.Exception.Message
        }
    }
}

function Get-ConversationState {
    <#
    .SYNOPSIS
    Gets the current conversation state
    
    .DESCRIPTION
    Returns the current state machine status and metadata
    
    .PARAMETER IncludeHistory
    Include state transition history
    
    .PARAMETER IncludeMetrics
    Include conversation metrics
    #>
    param(
        [switch]$IncludeHistory,
        [switch]$IncludeMetrics
    )
    
    Write-StateLog "Getting conversation state" -Level "DEBUG"
    
    try {
        $result = @{
            Success = $true
            CurrentState = $script:ConversationState.CurrentState
            PreviousState = $script:ConversationState.PreviousState
            SessionId = $script:ConversationState.SessionId
            LastStateChange = $script:ConversationState.LastStateChange
            TransitionCount = $script:ConversationState.TransitionCount
            ErrorCount = $script:ConversationState.ErrorCount
            SuccessCount = $script:ConversationState.SuccessCount
        }
        
        if ($IncludeHistory) {
            $result.StateHistory = $script:StateHistory
        }
        
        if ($IncludeMetrics) {
            $uptime = (Get-Date) - $script:ConversationState.StartTime
            $result.Metrics = @{
                UptimeMinutes = [Math]::Round($uptime.TotalMinutes, 2)
                TransitionsPerMinute = if ($uptime.TotalMinutes -gt 0) { 
                    [Math]::Round($script:ConversationState.TransitionCount / $uptime.TotalMinutes, 2) 
                } else { 0 }
                ErrorRate = if ($script:ConversationState.TransitionCount -gt 0) {
                    [Math]::Round($script:ConversationState.ErrorCount / $script:ConversationState.TransitionCount, 2)
                } else { 0 }
                SuccessRate = if ($script:ConversationState.TransitionCount -gt 0) {
                    [Math]::Round($script:ConversationState.SuccessCount / $script:ConversationState.TransitionCount, 2)
                } else { 0 }
            }
        }
        
        return $result
    }
    catch {
        Write-StateLog "Failed to get conversation state: $_" -Level "ERROR"
        return @{
            Success = $false
            Error = $_.Exception.Message
        }
    }
}

function Get-ValidStateTransitions {
    <#
    .SYNOPSIS
    Gets valid state transitions from current state
    
    .DESCRIPTION
    Returns array of valid target states based on state machine rules
    
    .PARAMETER CurrentState
    The current state to check transitions from
    #>
    param(
        [Parameter(Mandatory = $true)]
        [string]$CurrentState
    )
    
    Write-StateLog "Getting valid transitions for state: $CurrentState" -Level "DEBUG"
    
    # Define state transition rules
    $transitionRules = @{
        "Idle" = @("Initializing", "Processing", "Error", "Completed")
        "Initializing" = @("Processing", "WaitingForInput", "Error", "Completed")
        "Processing" = @("WaitingForInput", "Analyzing", "Error", "Completed")
        "WaitingForInput" = @("Analyzing", "Processing", "Error", "Completed", "Idle")
        "Analyzing" = @("GeneratingPrompt", "Processing", "Error", "Completed", "Idle")
        "GeneratingPrompt" = @("Processing", "WaitingForInput", "Error", "Completed")
        "Error" = @("Idle", "Processing", "Completed")
        "Completed" = @("Idle", "Initializing")
    }
    
    return $transitionRules[$CurrentState]
}

function Add-ConversationHistoryItem {
    <#
    .SYNOPSIS
    Adds an item to conversation history
    
    .DESCRIPTION
    Records conversation interactions with circular buffer management
    
    .PARAMETER Type
    Type of conversation item (Prompt, Response, Command, Result, Error)
    
    .PARAMETER Content
    The content of the conversation item
    
    .PARAMETER Metadata
    Optional metadata for the item
    #>
    param(
        [Parameter(Mandatory = $true)]
        [ValidateSet("Prompt", "Response", "Command", "Result", "Error")]
        [string]$Type,
        
        [Parameter(Mandatory = $true)]
        [string]$Content,
        
        [hashtable]$Metadata = @{}
    )
    
    Write-StateLog "Adding conversation history item of type: $Type" -Level "DEBUG"
    
    try {
        # Create history item
        $historyItem = [PSCustomObject]@{
            Id = [Guid]::NewGuid().ToString()
            Type = $Type
            Content = $Content
            Timestamp = Get-Date
            SessionId = $script:ConversationState.SessionId
            StateAtTime = $script:ConversationState.CurrentState
            Metadata = $Metadata
        }
        
        # Add to history with circular buffer management
        $script:ConversationHistory += $historyItem
        
        # Maintain circular buffer size
        if ($script:ConversationHistory.Count -gt $script:MaxHistorySize) {
            Write-StateLog "Circular buffer full, removing oldest item" -Level "DEBUG"
            $script:ConversationHistory = $script:ConversationHistory[1..($script:MaxHistorySize)]
        }
        
        # Update session metadata
        $script:SessionMetadata.LastActivity = Get-Date
        
        if ($Type -eq "Prompt") {
            $script:SessionMetadata.ConversationRounds++
        }
        
        if ($Type -eq "Command") {
            $script:SessionMetadata.TotalCommands++
        }
        
        # Persist history
        Save-ConversationHistory
        
        Write-StateLog "Added history item: $($historyItem.Id)" -Level "SUCCESS"
        
        return @{
            Success = $true
            ItemId = $historyItem.Id
            HistoryCount = $script:ConversationHistory.Count
        }
    }
    catch {
        Write-StateLog "Failed to add conversation history item: $_" -Level "ERROR"
        return @{
            Success = $false
            Error = $_.Exception.Message
        }
    }
}

function Get-ConversationHistory {
    <#
    .SYNOPSIS
    Retrieves conversation history
    
    .DESCRIPTION
    Returns filtered conversation history based on criteria
    
    .PARAMETER Last
    Number of most recent items to return
    
    .PARAMETER Type
    Filter by conversation item type
    
    .PARAMETER Since
    Filter items since specific datetime
    #>
    param(
        [int]$Last = 0,
        
        [ValidateSet("", "Prompt", "Response", "Command", "Result", "Error")]
        [string]$Type = "",
        
        [datetime]$Since = [datetime]::MinValue
    )
    
    Write-StateLog "Getting conversation history (Last: $Last, Type: $Type)" -Level "DEBUG"
    
    try {
        $history = $script:ConversationHistory
        
        # Apply filters
        if (![string]::IsNullOrEmpty($Type)) {
            $history = $history | Where-Object { $_.Type -eq $Type }
        }
        
        if ($Since -ne [datetime]::MinValue) {
            $history = $history | Where-Object { $_.Timestamp -gt $Since }
        }
        
        if ($Last -gt 0) {
            $startIndex = [Math]::Max(0, $history.Count - $Last)
            $history = $history[$startIndex..($history.Count - 1)]
        }
        
        Write-StateLog "Retrieved $($history.Count) history items" -Level "INFO"
        
        return @{
            Success = $true
            History = $history
            TotalCount = $script:ConversationHistory.Count
            FilteredCount = $history.Count
        }
    }
    catch {
        Write-StateLog "Failed to get conversation history: $_" -Level "ERROR"
        return @{
            Success = $false
            Error = $_.Exception.Message
        }
    }
}

function Get-ConversationContext {
    <#
    .SYNOPSIS
    Gets relevant conversation context for prompt generation
    
    .DESCRIPTION
    Extracts and formats relevant context from conversation history
    
    .PARAMETER MaxItems
    Maximum number of context items to include
    
    .PARAMETER IncludeErrors
    Whether to include error context
    #>
    param(
        [int]$MaxItems = 5,
        [switch]$IncludeErrors
    )
    
    Write-StateLog "Getting conversation context (MaxItems: $MaxItems)" -Level "DEBUG"
    
    try {
        $context = @{
            SessionId = $script:ConversationState.SessionId
            CurrentState = $script:ConversationState.CurrentState
            ConversationRounds = $script:SessionMetadata.ConversationRounds
            RecentHistory = @()
            LastError = $null
            LastCommand = $null
            LastResult = $null
        }
        
        # Get recent prompts and responses
        $recentItems = $script:ConversationHistory | 
            Where-Object { $_.Type -in @("Prompt", "Response") } |
            Select-Object -Last $MaxItems
        
        foreach ($item in $recentItems) {
            $context.RecentHistory += @{
                Type = $item.Type
                Content = if ($item.Content.Length -gt 500) {
                    $item.Content.Substring(0, 497) + "..."
                } else {
                    $item.Content
                }
                Timestamp = $item.Timestamp
            }
        }
        
        # Get last command and result
        $lastCommand = $script:ConversationHistory | 
            Where-Object { $_.Type -eq "Command" } |
            Select-Object -Last 1
        
        if ($lastCommand) {
            $context.LastCommand = @{
                Content = $lastCommand.Content
                Timestamp = $lastCommand.Timestamp
            }
        }
        
        $lastResult = $script:ConversationHistory |
            Where-Object { $_.Type -eq "Result" } |
            Select-Object -Last 1
            
        if ($lastResult) {
            $context.LastResult = @{
                Content = $lastResult.Content
                Timestamp = $lastResult.Timestamp
            }
        }
        
        # Include last error if requested
        if ($IncludeErrors) {
            $lastError = $script:ConversationHistory |
                Where-Object { $_.Type -eq "Error" } |
                Select-Object -Last 1
                
            if ($lastError) {
                $context.LastError = @{
                    Content = $lastError.Content
                    Timestamp = $lastError.Timestamp
                }
            }
        }
        
        Write-StateLog "Generated context with $($context.RecentHistory.Count) history items" -Level "INFO"
        
        return @{
            Success = $true
            Context = $context
        }
    }
    catch {
        Write-StateLog "Failed to get conversation context: $_" -Level "ERROR"
        return @{
            Success = $false
            Error = $_.Exception.Message
        }
    }
}

function Clear-ConversationHistory {
    <#
    .SYNOPSIS
    Clears conversation history
    
    .DESCRIPTION
    Removes conversation history with optional persistence
    
    .PARAMETER KeepPersisted
    Whether to keep persisted history file
    #>
    param(
        [switch]$KeepPersisted
    )
    
    Write-StateLog "Clearing conversation history" -Level "WARNING"
    
    try {
        $oldCount = $script:ConversationHistory.Count
        $script:ConversationHistory = @()
        
        if (-not $KeepPersisted -and (Test-Path $script:HistoryPersistencePath)) {
            Remove-Item $script:HistoryPersistencePath -Force
            Write-StateLog "Removed persisted history file" -Level "INFO"
        }
        
        Write-StateLog "Cleared $oldCount history items" -Level "SUCCESS"
        
        return @{
            Success = $true
            ItemsCleared = $oldCount
        }
    }
    catch {
        Write-StateLog "Failed to clear conversation history: $_" -Level "ERROR"
        return @{
            Success = $false
            Error = $_.Exception.Message
        }
    }
}

function Save-ConversationState {
    <#
    .SYNOPSIS
    Persists conversation state to disk
    
    .DESCRIPTION
    Saves current state machine status for recovery
    #>
    
    Write-StateLog "Saving conversation state" -Level "DEBUG"
    
    try {
        $stateData = $script:ConversationState | ConvertTo-Json -Depth 10
        Set-Content -Path $script:StatePersistencePath -Value $stateData -Force
        
        Write-StateLog "Conversation state saved successfully" -Level "DEBUG"
    }
    catch {
        Write-StateLog "Failed to save conversation state: $_" -Level "WARNING"
    }
}

function Save-ConversationHistory {
    <#
    .SYNOPSIS
    Persists conversation history to disk
    
    .DESCRIPTION
    Saves conversation history for session recovery
    #>
    
    Write-StateLog "Saving conversation history" -Level "DEBUG"
    
    try {
        if ($script:ConversationHistory.Count -gt 0) {
            $historyData = $script:ConversationHistory | ConvertTo-Json -Depth 10
            Set-Content -Path $script:HistoryPersistencePath -Value $historyData -Force
            
            Write-StateLog "Conversation history saved ($($script:ConversationHistory.Count) items)" -Level "DEBUG"
        }
    }
    catch {
        Write-StateLog "Failed to save conversation history: $_" -Level "WARNING"
    }
}

function Get-SessionMetadata {
    <#
    .SYNOPSIS
    Gets session metadata and statistics
    
    .DESCRIPTION
    Returns comprehensive session information and metrics
    #>
    
    Write-StateLog "Getting session metadata" -Level "DEBUG"
    
    try {
        # Calculate average response time
        $responseTimes = @()
        for ($i = 0; $i -lt $script:ConversationHistory.Count - 1; $i++) {
            if ($script:ConversationHistory[$i].Type -eq "Prompt" -and 
                $script:ConversationHistory[$i + 1].Type -eq "Response") {
                $responseTime = ($script:ConversationHistory[$i + 1].Timestamp - $script:ConversationHistory[$i].Timestamp).TotalSeconds
                $responseTimes += $responseTime
            }
        }
        
        if ($responseTimes.Count -gt 0) {
            $script:SessionMetadata.AverageResponseTime = [Math]::Round(($responseTimes | Measure-Object -Average).Average, 2)
        }
        
        # Calculate success rate
        if ($script:SessionMetadata.TotalCommands -gt 0) {
            $successRate = [Math]::Round($script:SessionMetadata.SuccessfulCommands / $script:SessionMetadata.TotalCommands * 100, 1)
        } else {
            $successRate = 0
        }
        
        $result = @{
            Success = $true
            Metadata = $script:SessionMetadata
            Statistics = @{
                SuccessRate = $successRate
                AverageResponseTimeSeconds = $script:SessionMetadata.AverageResponseTime
                SessionDurationMinutes = [Math]::Round(((Get-Date) - $script:SessionMetadata.StartTime).TotalMinutes, 2)
                HistoryItemCount = $script:ConversationHistory.Count
                StateTransitionCount = $script:ConversationState.TransitionCount
            }
        }
        
        Write-StateLog "Retrieved session metadata" -Level "INFO"
        return $result
    }
    catch {
        Write-StateLog "Failed to get session metadata: $_" -Level "ERROR"
        return @{
            Success = $false
            Error = $_.Exception.Message
        }
    }
}

function Reset-ConversationState {
    <#
    .SYNOPSIS
    Resets the conversation state machine
    
    .DESCRIPTION
    Clears all state and history, optionally preserving files
    
    .PARAMETER PreserveFiles
    Whether to keep persisted state files
    #>
    param(
        [switch]$PreserveFiles
    )
    
    Write-StateLog "Resetting conversation state machine" -Level "WARNING"
    
    try {
        # Clear in-memory data
        $script:ConversationState = $null
        $script:StateHistory = @()
        $script:ConversationHistory = @()
        $script:SessionMetadata = @{}
        
        # Remove persisted files if requested
        if (-not $PreserveFiles) {
            if (Test-Path $script:StatePersistencePath) {
                Remove-Item $script:StatePersistencePath -Force
                Write-StateLog "Removed state persistence file" -Level "INFO"
            }
            
            if (Test-Path $script:HistoryPersistencePath) {
                Remove-Item $script:HistoryPersistencePath -Force
                Write-StateLog "Removed history persistence file" -Level "INFO"
            }
        }
        
        Write-StateLog "Conversation state machine reset complete" -Level "SUCCESS"
        
        return @{
            Success = $true
            FilesPreserved = $PreserveFiles.IsPresent
        }
    }
    catch {
        Write-StateLog "Failed to reset conversation state: $_" -Level "ERROR"
        return @{
            Success = $false
            Error = $_.Exception.Message
        }
    }
}

# Day 16 Enhancement: Advanced Conversation Management Functions

function Add-ConversationGoal {
    <#
    .SYNOPSIS
    Adds a new conversation goal with tracking capabilities
    
    .DESCRIPTION
    Creates and tracks conversation goals with success criteria and measurement
    
    .PARAMETER Type
    Type of goal (ProblemSolving, Information, TaskCompletion, LearningObjective)
    
    .PARAMETER Description
    Description of the goal
    
    .PARAMETER Priority
    Priority level (High, Medium, Low)
    
    .PARAMETER SuccessCriteria
    Criteria for measuring goal completion
    #>
    param(
        [Parameter(Mandatory = $true)]
        [ValidateSet("ProblemSolving", "Information", "TaskCompletion", "LearningObjective")]
        [string]$Type,
        
        [Parameter(Mandatory = $true)]
        [string]$Description,
        
        [ValidateSet("High", "Medium", "Low")]
        [string]$Priority = "Medium",
        
        [hashtable]$SuccessCriteria = @{}
    )
    
    Write-StateLog "Adding conversation goal: $Type - $Description" -Level "INFO"
    
    try {
        $goal = [PSCustomObject]@{
            Id = [Guid]::NewGuid().ToString()
            Type = $Type
            Description = $Description
            Priority = $Priority
            SuccessCriteria = $SuccessCriteria
            Status = "Active"
            Progress = 0.0
            CreatedAt = Get-Date
            UpdatedAt = Get-Date
            SessionId = $script:ConversationState.SessionId
            CompletedAt = $null
            EffectivenessScore = 0.0
        }
        
        $script:ConversationGoals += $goal
        
        # Update conversation effectiveness
        Update-ConversationEffectiveness
        
        # Persist goals
        Save-ConversationGoals
        
        Write-StateLog "Added conversation goal: $($goal.Id)" -Level "SUCCESS"
        
        return @{
            Success = $true
            GoalId = $goal.Id
            TotalGoals = $script:ConversationGoals.Count
        }
    }
    catch {
        Write-StateLog "Failed to add conversation goal: $_" -Level "ERROR"
        return @{
            Success = $false
            Error = $_.Exception.Message
        }
    }
}

function Add-RoleAwareHistoryItem {
    <#
    .SYNOPSIS
    Adds role-aware conversation history item with enhanced tracking
    
    .DESCRIPTION
    Tracks conversation with explicit role assignment and CALM agent patterns
    
    .PARAMETER Role
    Role in conversation (User, Assistant, System, Tool)
    
    .PARAMETER Content
    Content of the message
    
    .PARAMETER Intent
    Detected intent (Question, Instruction, Information, Error, Confirmation)
    
    .PARAMETER Confidence
    Confidence score for intent detection
    
    .PARAMETER Context
    Additional context information
    #>
    param(
        [Parameter(Mandatory = $true)]
        [ValidateSet("User", "Assistant", "System", "Tool")]
        [string]$Role,
        
        [Parameter(Mandatory = $true)]
        [string]$Content,
        
        [ValidateSet("Question", "Instruction", "Information", "Error", "Confirmation")]
        [string]$Intent = "Information",
        
        [double]$Confidence = 0.0,
        
        [hashtable]$Context = @{}
    )
    
    Write-StateLog "Adding role-aware history item: $Role - $Intent" -Level "DEBUG"
    
    try {
        $historyItem = [PSCustomObject]@{
            Id = [Guid]::NewGuid().ToString()
            Role = $Role
            Content = $Content
            Intent = $Intent
            Confidence = $Confidence
            Context = $Context
            Timestamp = Get-Date
            SessionId = $script:ConversationState.SessionId
            ConversationRound = $script:SessionMetadata.ConversationRounds
            TokenCount = $Content.Length  # Approximate token count
            ResponseTime = if ($Context.ContainsKey("ResponseTime")) { $Context.ResponseTime } else { 0 }
            GoalRelevance = 0.0
        }
        
        # Calculate goal relevance
        if ($script:ConversationGoals.Count -gt 0) {
            $historyItem.GoalRelevance = Calculate-GoalRelevance -Content $Content -Goals $script:ConversationGoals
        }
        
        # Add to role-aware history
        $script:RoleAwareHistory += $historyItem
        
        # Maintain circular buffer
        if ($script:RoleAwareHistory.Count -gt $script:MaxRoleHistorySize) {
            Write-StateLog "Role-aware history buffer full, removing oldest items" -Level "DEBUG"
            $script:RoleAwareHistory = $script:RoleAwareHistory[1..($script:MaxRoleHistorySize)]
        }
        
        # Update dialogue patterns
        Update-DialoguePatterns -Item $historyItem
        
        # Update conversation effectiveness
        Update-ConversationEffectiveness
        
        Write-StateLog "Added role-aware history item: $($historyItem.Id)" -Level "SUCCESS"
        
        return @{
            Success = $true
            ItemId = $historyItem.Id
            GoalRelevance = $historyItem.GoalRelevance
            HistoryCount = $script:RoleAwareHistory.Count
        }
    }
    catch {
        Write-StateLog "Failed to add role-aware history item: $_" -Level "ERROR"
        return @{
            Success = $false
            Error = $_.Exception.Message
        }
    }
}

function Update-ConversationGoal {
    <#
    .SYNOPSIS
    Updates conversation goal progress and status
    
    .DESCRIPTION
    Updates goal completion status, progress, and effectiveness scoring
    
    .PARAMETER GoalId
    ID of the goal to update
    
    .PARAMETER Progress
    Progress percentage (0.0 to 1.0)
    
    .PARAMETER Status
    Updated status (Active, Completed, Abandoned, Blocked)
    
    .PARAMETER EffectivenessScore
    Effectiveness score (0.0 to 1.0)
    #>
    param(
        [Parameter(Mandatory = $true)]
        [string]$GoalId,
        
        [double]$Progress = -1,
        
        [ValidateSet("Active", "Completed", "Abandoned", "Blocked")]
        [string]$Status = "",
        
        [double]$EffectivenessScore = -1
    )
    
    Write-StateLog "Updating conversation goal: $GoalId" -Level "DEBUG"
    
    try {
        $goal = $script:ConversationGoals | Where-Object { $_.Id -eq $GoalId }
        
        if (-not $goal) {
            throw "Goal not found: $GoalId"
        }
        
        $updated = $false
        
        if ($Progress -ge 0 -and $Progress -le 1) {
            $goal.Progress = $Progress
            $updated = $true
            Write-StateLog "Updated goal progress: $Progress" -Level "DEBUG"
        }
        
        if ($Status -ne "") {
            $goal.Status = $Status
            $updated = $true
            
            if ($Status -eq "Completed") {
                $goal.CompletedAt = Get-Date
                $goal.Progress = 1.0
            }
            
            Write-StateLog "Updated goal status: $Status" -Level "DEBUG"
        }
        
        if ($EffectivenessScore -ge 0 -and $EffectivenessScore -le 1) {
            $goal.EffectivenessScore = $EffectivenessScore
            $updated = $true
            Write-StateLog "Updated goal effectiveness: $EffectivenessScore" -Level "DEBUG"
        }
        
        if ($updated) {
            $goal.UpdatedAt = Get-Date
            
            # Update conversation effectiveness
            Update-ConversationEffectiveness
            
            # Persist goals
            Save-ConversationGoals
            
            Write-StateLog "Updated conversation goal: $GoalId" -Level "SUCCESS"
        }
        
        return @{
            Success = $true
            Updated = $updated
            Goal = $goal
        }
    }
    catch {
        Write-StateLog "Failed to update conversation goal: $_" -Level "ERROR"
        return @{
            Success = $false
            Error = $_.Exception.Message
        }
    }
}

function Get-RoleAwareHistory {
    <#
    .SYNOPSIS
    Retrieves role-aware conversation history with filtering
    
    .DESCRIPTION
    Returns filtered role-aware history with advanced search capabilities
    
    .PARAMETER Role
    Filter by role
    
    .PARAMETER Intent
    Filter by intent
    
    .PARAMETER Last
    Number of recent items to return
    
    .PARAMETER MinConfidence
    Minimum confidence threshold
    #>
    param(
        [ValidateSet("User", "Assistant", "System", "Tool")]
        [string]$Role = "",
        
        [ValidateSet("Question", "Instruction", "Information", "Error", "Confirmation")]
        [string]$Intent = "",
        
        [int]$Last = 0,
        
        [double]$MinConfidence = 0.0
    )
    
    Write-StateLog "Getting role-aware history with filters" -Level "DEBUG"
    
    try {
        $filteredHistory = $script:RoleAwareHistory
        
        if ($Role -ne "") {
            $filteredHistory = $filteredHistory | Where-Object { $_.Role -eq $Role }
        }
        
        if ($Intent -ne "") {
            $filteredHistory = $filteredHistory | Where-Object { $_.Intent -eq $Intent }
        }
        
        if ($MinConfidence -gt 0) {
            $filteredHistory = $filteredHistory | Where-Object { $_.Confidence -ge $MinConfidence }
        }
        
        if ($Last -gt 0 -and $filteredHistory.Count -gt $Last) {
            $filteredHistory = $filteredHistory | Select-Object -Last $Last
        }
        
        Write-StateLog "Retrieved $($filteredHistory.Count) role-aware history items" -Level "INFO"
        
        return @{
            Success = $true
            History = $filteredHistory
            TotalCount = $script:RoleAwareHistory.Count
            FilteredCount = $filteredHistory.Count
        }
    }
    catch {
        Write-StateLog "Failed to get role-aware history: $_" -Level "ERROR"
        return @{
            Success = $false
            Error = $_.Exception.Message
        }
    }
}

function Get-ConversationGoals {
    <#
    .SYNOPSIS
    Retrieves conversation goals with filtering
    
    .DESCRIPTION
    Returns conversation goals with status and effectiveness information
    
    .PARAMETER Status
    Filter by status
    
    .PARAMETER Type
    Filter by type
    
    .PARAMETER Priority
    Filter by priority
    #>
    param(
        [ValidateSet("Active", "Completed", "Abandoned", "Blocked")]
        [string]$Status = "",
        
        [ValidateSet("ProblemSolving", "Information", "TaskCompletion", "LearningObjective")]
        [string]$Type = "",
        
        [ValidateSet("High", "Medium", "Low")]
        [string]$Priority = ""
    )
    
    Write-StateLog "Getting conversation goals with filters" -Level "DEBUG"
    
    try {
        $filteredGoals = $script:ConversationGoals
        
        if ($Status -ne "") {
            $filteredGoals = $filteredGoals | Where-Object { $_.Status -eq $Status }
        }
        
        if ($Type -ne "") {
            $filteredGoals = $filteredGoals | Where-Object { $_.Type -eq $Type }
        }
        
        if ($Priority -ne "") {
            $filteredGoals = $filteredGoals | Where-Object { $_.Priority -eq $Priority }
        }
        
        Write-StateLog "Retrieved $($filteredGoals.Count) conversation goals" -Level "INFO"
        
        return @{
            Success = $true
            Goals = $filteredGoals
            TotalCount = $script:ConversationGoals.Count
            FilteredCount = $filteredGoals.Count
            CompletionRate = if ($script:ConversationGoals.Count -gt 0) {
                ($script:ConversationGoals | Where-Object { $_.Status -eq "Completed" }).Count / $script:ConversationGoals.Count
            } else { 0 }
        }
    }
    catch {
        Write-StateLog "Failed to get conversation goals: $_" -Level "ERROR"
        return @{
            Success = $false
            Error = $_.Exception.Message
        }
    }
}

# Helper functions for Day 16 enhancements

function Calculate-GoalRelevance {
    param(
        [string]$Content,
        [array]$Goals
    )
    
    if ($Goals.Count -eq 0) { return 0.0 }
    
    $totalRelevance = 0.0
    foreach ($goal in $Goals) {
        $keywords = $goal.Description.Split(" ", [StringSplitOptions]::RemoveEmptyEntries)
        $matches = 0
        
        foreach ($keyword in $keywords) {
            if ($Content -match $keyword) {
                $matches++
            }
        }
        
        $relevance = if ($keywords.Count -gt 0) { $matches / $keywords.Count } else { 0 }
        $totalRelevance += $relevance
    }
    
    return [Math]::Min($totalRelevance / $Goals.Count, 1.0)
}

function Update-DialoguePatterns {
    param(
        [PSCustomObject]$Item
    )
    
    # Ensure DialoguePatterns structure exists
    if (-not $script:DialoguePatterns) {
        $script:DialoguePatterns = @{
            UserIntents = @{}
            SystemResponses = @{}
            ConversationFlows = @()
            EffectivenessScores = @{}
        }
    }
    
    # Ensure UserIntents is a hashtable
    if (-not $script:DialoguePatterns.UserIntents -or $script:DialoguePatterns.UserIntents -isnot [Hashtable]) {
        $script:DialoguePatterns.UserIntents = @{}
    }
    
    # Ensure SystemResponses is a hashtable
    if (-not $script:DialoguePatterns.SystemResponses -or $script:DialoguePatterns.SystemResponses -isnot [Hashtable]) {
        $script:DialoguePatterns.SystemResponses = @{}
    }
    
    # Update user intents tracking
    if ($Item.Role -eq "User") {
        if (-not $script:DialoguePatterns.UserIntents.ContainsKey($Item.Intent)) {
            $script:DialoguePatterns.UserIntents[$Item.Intent] = 0
        }
        $currentValue = $script:DialoguePatterns.UserIntents[$Item.Intent]
        $script:DialoguePatterns.UserIntents[$Item.Intent] = [int]$currentValue + 1
    }
    
    # Update system responses tracking
    if ($Item.Role -eq "Assistant" -or $Item.Role -eq "System") {
        if (-not $script:DialoguePatterns.SystemResponses.ContainsKey($Item.Intent)) {
            $script:DialoguePatterns.SystemResponses[$Item.Intent] = 0
        }
        $currentValue = $script:DialoguePatterns.SystemResponses[$Item.Intent]
        $script:DialoguePatterns.SystemResponses[$Item.Intent] = [int]$currentValue + 1
    }
    
    # Track conversation flows
    if ($script:RoleAwareHistory.Count -gt 1) {
        $previousItem = $script:RoleAwareHistory[-2]
        $flow = "$($previousItem.Role):$($previousItem.Intent) -> $($Item.Role):$($Item.Intent)"
        $script:DialoguePatterns.ConversationFlows += $flow
    }
}

function Update-ConversationEffectiveness {
    if ($script:ConversationGoals.Count -eq 0 -or $script:RoleAwareHistory.Count -eq 0) {
        return
    }
    
    # Calculate goal completion rate
    $completedGoals = ($script:ConversationGoals | Where-Object { $_.Status -eq "Completed" }).Count
    $script:ConversationEffectiveness.GoalCompletionRate = if ($script:ConversationGoals.Count -gt 0) {
        $completedGoals / $script:ConversationGoals.Count
    } else { 0 }
    
    # Calculate average conversation length
    $script:ConversationEffectiveness.ConversationLength = $script:RoleAwareHistory.Count
    
    # Calculate topic coherence (simplified)
    $userMessages = $script:RoleAwareHistory | Where-Object { $_.Role -eq "User" }
    $script:ConversationEffectiveness.TopicCoherence = if ($userMessages.Count -gt 1) {
        $avgGoalRelevance = ($userMessages | Measure-Object -Property GoalRelevance -Average).Average
        [Math]::Max($avgGoalRelevance, 0.1)
    } else { 0.5 }
    
    # Calculate response relevance
    $assistantMessages = $script:RoleAwareHistory | Where-Object { $_.Role -eq "Assistant" }
    $script:ConversationEffectiveness.ResponseRelevance = if ($assistantMessages.Count -gt 0) {
        $avgConfidence = ($assistantMessages | Measure-Object -Property Confidence -Average).Average
        [Math]::Max($avgConfidence, 0.1)
    } else { 0.5 }
    
    $script:ConversationEffectiveness.LastCalculation = Get-Date
}

function Save-ConversationGoals {
    try {
        $script:ConversationGoals | ConvertTo-Json -Depth 5 | Set-Content -Path $script:GoalsPersistencePath -Encoding UTF8
        Write-StateLog "Conversation goals saved successfully" -Level "DEBUG"
    }
    catch {
        Write-StateLog "Failed to save conversation goals: $_" -Level "ERROR"
    }
}

# Export module functions
Export-ModuleMember -Function @(
    'Initialize-ConversationState',
    'Set-ConversationState',
    'Get-ConversationState',
    'Get-ValidStateTransitions',
    'Add-ConversationHistoryItem',
    'Get-ConversationHistory',
    'Get-ConversationContext',
    'Clear-ConversationHistory',
    'Get-SessionMetadata',
    'Reset-ConversationState',
    # Day 16 Enhancement: Advanced Conversation Management Functions
    'Add-ConversationGoal',
    'Add-RoleAwareHistoryItem',
    'Update-ConversationGoal',
    'Get-RoleAwareHistory',
    'Get-ConversationGoals'
)

Write-StateLog "ConversationStateManager module loaded successfully" -Level "INFO"
# SIG # Begin signature block
# MIIFzgYJKoZIhvcNAQcCoIIFvzCCBbsCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCD8+i2Cja6h5SVg
# rKaVf1QEXb28J1BLWfWsow7JYEfWgKCCAzAwggMsMIICFKADAgECAhB1HRbZIqgr
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
# MAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEINjB6GFodM740CBatHiS9b52
# cxnm0YxpaQgAWKaJaOYbMA0GCSqGSIb3DQEBAQUABIIBABTrdCbraQ2I246VxN3i
# FAm1JtViZPj/leq8DYNOV3ITcIr8R8uUMPsNzvWWfv7cK9rg98gaH9I6nc0dHb8v
# yXOiLUCwDzm68X4jw25qTle8SEkQfxEDGqJg3nI0VVcHRnii1VzfosKLZjE6iWrM
# ZMAxNxqs+sAaBGpwFBthxNp5Tjl/Oga8/MS/D8y7Xnq1rKD64sxoUY0dPKKHu8CL
# V4g0Z2waGKvkg95ZYfGYQuBwEGFuDMhlmjdGLx5/ITFEt43TBBb8PhAFnPvGqPC3
# l1LRjXEzYJ34RBVPBl/mGveQbBDPvzhyu8bCM1zRLGV0SdFTib4JwLkXsMHfK7pF
# NxM=
# SIG # End signature block
