# Unity-Claude-IntegrationEngine.psm1
# Master integration module for complete autonomous feedback loop orchestration
# Coordinates all Phase 1 and Phase 2 modules in automated Claude Code CLI cycles
# Date: 2025-08-18 | Day 14: Integration Testing and Validation

#region Module Configuration and Dependencies

# Load required modules
$ErrorActionPreference = "Stop"

Write-Host "[IntegrationEngine] Loading integration engine module..." -ForegroundColor Cyan

# Module paths
$modulePath = Split-Path $PSScriptRoot -Parent
$autonomousAgentPath = Join-Path $modulePath "Unity-Claude-AutonomousAgent\Unity-Claude-AutonomousAgent.psm1"
$safeExecutionPath = Join-Path $modulePath "SafeCommandExecution\SafeCommandExecution.psm1"
$cliAutomationPath = Join-Path $modulePath "Execution\CLIAutomation.psm1"
$promptEnginePath = Join-Path $modulePath "Unity-Claude-AutonomousAgent\IntelligentPromptEngine.psm1"

# Import required modules
$requiredModules = @{
    "AutonomousAgent" = $autonomousAgentPath
    "SafeExecution" = $safeExecutionPath
    "CLIAutomation" = $cliAutomationPath
    "PromptEngine" = $promptEnginePath
}

foreach ($moduleInfo in $requiredModules.GetEnumerator()) {
    $moduleName = $moduleInfo.Key
    $modulePath = $moduleInfo.Value
    
    if (Test-Path $modulePath) {
        try {
            Import-Module $modulePath -Force -DisableNameChecking
            Write-Host "[IntegrationEngine] Loaded $moduleName module" -ForegroundColor Green
        } catch {
            Write-Host "[IntegrationEngine] ERROR loading ${moduleName}: $($_.Exception.Message)" -ForegroundColor Red
            throw "Failed to load required module: $moduleName"
        }
    } else {
        Write-Host "[IntegrationEngine] ERROR: $moduleName module not found at $modulePath" -ForegroundColor Red
        throw "Required module not found: $moduleName"
    }
}

# Global configuration
$script:IntegrationConfig = @{
    # Cycle Configuration
    MaxCyclesPerSession = 50
    CycleTimeoutMs = 300000  # 5 minutes per cycle
    ResponseTimeoutMs = 60000  # 1 minute wait for Claude response
    
    # State Management
    SessionDataPath = Join-Path $PSScriptRoot "..\SessionData"
    StateFile = "integration_state.json"
    LogFile = "integration_engine.log"
    
    # Performance Monitoring
    EnablePerformanceMetrics = $true
    MetricsCollectionInterval = 10  # seconds
    
    # Safety Configuration
    EnableSafetyChecks = $true
    MaxConsecutiveFailures = 5
    CircuitBreakerThreshold = 3
    
    # Debug Configuration
    VerboseLogging = $true
    DebugMode = $false
}

# Ensure session data directory exists
if (-not (Test-Path $script:IntegrationConfig.SessionDataPath)) {
    New-Item -Path $script:IntegrationConfig.SessionDataPath -ItemType Directory -Force | Out-Null
}

#endregion

#region Logging and Utilities

function Write-IntegrationLog {
    param(
        [string]$Message,
        [ValidateSet("INFO", "WARNING", "ERROR", "DEBUG")]
        [string]$Level = "INFO",
        [string]$Source = "IntegrationEngine"
    )
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss.fff"
    $logEntry = "[$timestamp] [$Level] [$Source] $Message"
    
    # Console output with colors
    $color = switch ($Level) {
        "INFO" { "White" }
        "WARNING" { "Yellow" }
        "ERROR" { "Red" }
        "DEBUG" { "Gray" }
    }
    
    if ($Level -ne "DEBUG" -or $script:IntegrationConfig.DebugMode) {
        Write-Host $logEntry -ForegroundColor $color
    }
    
    # File logging
    $logFile = Join-Path $script:IntegrationConfig.SessionDataPath $script:IntegrationConfig.LogFile
    try {
        Add-Content -Path $logFile -Value $logEntry -Encoding UTF8
    } catch {
        Write-Warning "Failed to write to log file: $($_.Exception.Message)"
    }
}

function Get-CurrentTimestamp {
    return Get-Date -Format "yyyy-MM-dd HH:mm:ss.fff"
}

function New-CycleId {
    return [System.Guid]::NewGuid().ToString("N").Substring(0, 8)
}

#endregion

#region State Management

function Initialize-IntegrationState {
    param(
        [string]$SessionId = (New-Guid).ToString("N").Substring(0, 12)
    )
    
    Write-IntegrationLog "Initializing integration state for session: $SessionId"
    
    $state = @{
        SessionId = $SessionId
        StartTime = Get-CurrentTimestamp
        LastActivity = Get-CurrentTimestamp
        Status = "Initializing"
        CycleCount = 0
        SuccessfulCycles = 0
        FailedCycles = 0
        ConsecutiveFailures = 0
        CircuitBreakerTripped = $false
        CurrentCycle = $null
        PerformanceMetrics = @{
            AverageCycleTime = 0
            TotalProcessingTime = 0
            LastCycleTime = 0
        }
        Configuration = $script:IntegrationConfig
        LastError = $null
    }
    
    $stateFile = Join-Path $script:IntegrationConfig.SessionDataPath $script:IntegrationConfig.StateFile
    $state | ConvertTo-Json -Depth 10 | Set-Content -Path $stateFile -Encoding UTF8
    
    return $state
}

function Get-IntegrationState {
    $stateFile = Join-Path $script:IntegrationConfig.SessionDataPath $script:IntegrationConfig.StateFile
    
    if (Test-Path $stateFile) {
        try {
            $stateJson = Get-Content -Path $stateFile -Raw
            return $stateJson | ConvertFrom-Json
        } catch {
            Write-IntegrationLog "Failed to load state file: $($_.Exception.Message)" -Level "WARNING"
            return $null
        }
    }
    
    return $null
}

function Update-IntegrationState {
    param(
        [hashtable]$StateUpdates
    )
    
    $state = Get-IntegrationState
    if ($null -eq $state) {
        Write-IntegrationLog "No existing state found, initializing new state" -Level "WARNING"
        $state = Initialize-IntegrationState
    }
    
    # Convert PSCustomObject to hashtable for easier manipulation
    $stateHash = @{}
    $state.PSObject.Properties | ForEach-Object { $stateHash[$_.Name] = $_.Value }
    
    # Apply updates
    foreach ($update in $StateUpdates.GetEnumerator()) {
        $stateHash[$update.Key] = $update.Value
    }
    
    # Update timestamp
    $stateHash.LastActivity = Get-CurrentTimestamp
    
    # Save updated state
    $stateFile = Join-Path $script:IntegrationConfig.SessionDataPath $script:IntegrationConfig.StateFile
    $stateHash | ConvertTo-Json -Depth 10 | Set-Content -Path $stateFile -Encoding UTF8
    
    return $stateHash
}

#endregion

#region Cycle Management

function New-FeedbackCycle {
    param(
        [string]$TriggerType = "Manual",
        [string]$InitialPrompt = $null,
        [hashtable]$Context = @{}
    )
    
    $cycleId = New-CycleId
    
    $cycle = @{
        CycleId = $cycleId
        StartTime = Get-CurrentTimestamp
        TriggerType = $TriggerType
        InitialPrompt = $InitialPrompt
        Context = $Context
        Phases = @{
            Monitor = @{ Status = "Pending"; StartTime = $null; EndTime = $null; Duration = 0; Result = $null }
            Parse = @{ Status = "Pending"; StartTime = $null; EndTime = $null; Duration = 0; Result = $null }
            Analyze = @{ Status = "Pending"; StartTime = $null; EndTime = $null; Duration = 0; Result = $null }
            Execute = @{ Status = "Pending"; StartTime = $null; EndTime = $null; Duration = 0; Result = $null }
            Generate = @{ Status = "Pending"; StartTime = $null; EndTime = $null; Duration = 0; Result = $null }
            Submit = @{ Status = "Pending"; StartTime = $null; EndTime = $null; Duration = 0; Result = $null }
        }
        Status = "Running"
        Success = $null
        ErrorMessage = $null
        EndTime = $null
        TotalDuration = 0
    }
    
    Write-IntegrationLog "Created new feedback cycle: $cycleId" -Level "INFO"
    return $cycle
}

function Update-CyclePhase {
    param(
        [hashtable]$Cycle,
        [string]$PhaseName,
        [string]$Status,
        [object]$Result = $null,
        [string]$ErrorMessage = $null
    )
    
    $phase = $Cycle.Phases[$PhaseName]
    
    if ($Status -eq "Running" -and $phase.Status -eq "Pending") {
        $phase.StartTime = Get-CurrentTimestamp
        $phase.Status = "Running"
        Write-IntegrationLog "Starting phase: $PhaseName (Cycle: $($Cycle.CycleId))" -Level "INFO"
    } elseif ($Status -in @("Completed", "Failed")) {
        $phase.EndTime = Get-CurrentTimestamp
        $phase.Status = $Status
        $phase.Result = $Result
        
        if ($phase.StartTime) {
            $phase.Duration = ((Get-Date $phase.EndTime) - (Get-Date $phase.StartTime)).TotalMilliseconds
        }
        
        if ($Status -eq "Failed" -and $ErrorMessage) {
            $phase.ErrorMessage = $ErrorMessage
        }
        
        $level = if ($Status -eq "Failed") { "ERROR" } else { "INFO" }
        Write-IntegrationLog "Completed phase: $PhaseName (Status: $Status, Duration: $($phase.Duration)ms)" -Level $level
    }
}

function Complete-FeedbackCycle {
    param(
        [hashtable]$Cycle,
        [bool]$Success,
        [string]$ErrorMessage = $null
    )
    
    $Cycle.EndTime = Get-CurrentTimestamp
    $Cycle.Success = $Success
    $Cycle.Status = if ($Success) { "Completed" } else { "Failed" }
    
    if ($ErrorMessage) {
        $Cycle.ErrorMessage = $ErrorMessage
    }
    
    if ($Cycle.StartTime) {
        $Cycle.TotalDuration = ((Get-Date $Cycle.EndTime) - (Get-Date $Cycle.StartTime)).TotalMilliseconds
    }
    
    $level = if ($Success) { "INFO" } else { "ERROR" }
    Write-IntegrationLog "Cycle completed: $($Cycle.CycleId) (Success: $Success, Duration: $($Cycle.TotalDuration)ms)" -Level $level
    
    return $Cycle
}

#endregion

#region Feedback Loop Implementation

function Invoke-FeedbackCyclePhase1Monitor {
    param(
        [hashtable]$Cycle,
        [int]$TimeoutMs = 60000
    )
    
    Update-CyclePhase -Cycle $Cycle -PhaseName "Monitor" -Status "Running"
    
    try {
        Write-IntegrationLog "Phase 1: Starting Claude response monitoring" -Level "INFO"
        
        # Start Claude response monitoring
        $monitoring = Start-ClaudeResponseMonitoring
        
        if ($monitoring) {
            Update-CyclePhase -Cycle $Cycle -PhaseName "Monitor" -Status "Completed" -Result $monitoring
            return @{ Success = $true; Result = $monitoring }
        } else {
            throw "Failed to start Claude response monitoring"
        }
    } catch {
        $errorMsg = "Monitor phase failed: $($_.Exception.Message)"
        Write-IntegrationLog $errorMsg -Level "ERROR"
        Update-CyclePhase -Cycle $Cycle -PhaseName "Monitor" -Status "Failed" -ErrorMessage $errorMsg
        return @{ Success = $false; Error = $errorMsg }
    }
}

function Invoke-FeedbackCyclePhase2Parse {
    param(
        [hashtable]$Cycle,
        [string]$ResponseFile
    )
    
    Update-CyclePhase -Cycle $Cycle -PhaseName "Parse" -Status "Running"
    
    try {
        Write-IntegrationLog "Phase 2: Parsing Claude response from: $ResponseFile" -Level "INFO"
        
        # Process Claude response and extract recommendations
        $parseResult = Invoke-ProcessClaudeResponse -ResponseFile $ResponseFile
        
        if ($parseResult -and $parseResult.Recommendations.Count -gt 0) {
            Update-CyclePhase -Cycle $Cycle -PhaseName "Parse" -Status "Completed" -Result $parseResult
            return @{ Success = $true; Result = $parseResult }
        } else {
            throw "No actionable recommendations found in Claude response"
        }
    } catch {
        $errorMsg = "Parse phase failed: $($_.Exception.Message)"
        Write-IntegrationLog $errorMsg -Level "ERROR"
        Update-CyclePhase -Cycle $Cycle -PhaseName "Parse" -Status "Failed" -ErrorMessage $errorMsg
        return @{ Success = $false; Error = $errorMsg }
    }
}

function Invoke-FeedbackCyclePhase3Analyze {
    param(
        [hashtable]$Cycle,
        [object]$ParseResult
    )
    
    Update-CyclePhase -Cycle $Cycle -PhaseName "Analyze" -Status "Running"
    
    try {
        Write-IntegrationLog "Phase 3: Analyzing command results and recommendations" -Level "INFO"
        
        # Analyze recommendations and determine next actions
        $analysisResult = Invoke-CommandResultAnalysis -Recommendations $ParseResult.Recommendations
        
        if ($analysisResult) {
            Update-CyclePhase -Cycle $Cycle -PhaseName "Analyze" -Status "Completed" -Result $analysisResult
            return @{ Success = $true; Result = $analysisResult }
        } else {
            throw "Failed to analyze recommendations"
        }
    } catch {
        $errorMsg = "Analyze phase failed: $($_.Exception.Message)"
        Write-IntegrationLog $errorMsg -Level "ERROR"
        Update-CyclePhase -Cycle $Cycle -PhaseName "Analyze" -Status "Failed" -ErrorMessage $errorMsg
        return @{ Success = $false; Error = $errorMsg }
    }
}

function Invoke-FeedbackCyclePhase4Execute {
    param(
        [hashtable]$Cycle,
        [object]$AnalysisResult
    )
    
    Update-CyclePhase -Cycle $Cycle -PhaseName "Execute" -Status "Running"
    
    try {
        Write-IntegrationLog "Phase 4: Executing recommended commands" -Level "INFO"
        
        $executionResults = @()
        
        # Execute each recommendation through safe command execution
        foreach ($recommendation in $AnalysisResult.Recommendations) {
            try {
                $execResult = Invoke-SafeRecommendedCommand -Recommendation $recommendation
                $executionResults += $execResult
                
                Write-IntegrationLog "Executed command: $($recommendation.Type) - Success: $($execResult.Success)" -Level "INFO"
            } catch {
                Write-IntegrationLog "Command execution failed: $($_.Exception.Message)" -Level "WARNING"
                $executionResults += @{ Success = $false; Error = $_.ToString(); Recommendation = $recommendation }
            }
        }
        
        $overallSuccess = ($executionResults | Where-Object { $_.Success }).Count -gt 0
        
        if ($overallSuccess) {
            Update-CyclePhase -Cycle $Cycle -PhaseName "Execute" -Status "Completed" -Result $executionResults
            return @{ Success = $true; Result = $executionResults }
        } else {
            throw "All command executions failed"
        }
    } catch {
        $errorMsg = "Execute phase failed: $($_.Exception.Message)"
        Write-IntegrationLog $errorMsg -Level "ERROR"
        Update-CyclePhase -Cycle $Cycle -PhaseName "Execute" -Status "Failed" -ErrorMessage $errorMsg
        return @{ Success = $false; Error = $errorMsg }
    }
}

function Invoke-FeedbackCyclePhase5Generate {
    param(
        [hashtable]$Cycle,
        [object]$ExecutionResults
    )
    
    Update-CyclePhase -Cycle $Cycle -PhaseName "Generate" -Status "Running"
    
    try {
        Write-IntegrationLog "Phase 5: Generating follow-up prompt based on execution results" -Level "INFO"
        
        # Determine prompt type based on execution results
        $promptType = Invoke-PromptTypeSelection -ExecutionResults $ExecutionResults
        
        # Generate appropriate prompt
        $promptResult = New-PromptTemplate -Type $promptType -Context @{
            ExecutionResults = $ExecutionResults
            CycleHistory = $Cycle
        }
        
        if ($promptResult -and $promptResult.Prompt) {
            Update-CyclePhase -Cycle $Cycle -PhaseName "Generate" -Status "Completed" -Result $promptResult
            return @{ Success = $true; Result = $promptResult }
        } else {
            throw "Failed to generate follow-up prompt"
        }
    } catch {
        $errorMsg = "Generate phase failed: $($_.Exception.Message)"
        Write-IntegrationLog $errorMsg -Level "ERROR"
        Update-CyclePhase -Cycle $Cycle -PhaseName "Generate" -Status "Failed" -ErrorMessage $errorMsg
        return @{ Success = $false; Error = $errorMsg }
    }
}

function Invoke-FeedbackCyclePhase6Submit {
    param(
        [hashtable]$Cycle,
        [object]$PromptResult
    )
    
    Update-CyclePhase -Cycle $Cycle -PhaseName "Submit" -Status "Running"
    
    try {
        Write-IntegrationLog "Phase 6: Submitting prompt to Claude CLI" -Level "INFO"
        
        # Submit prompt using CLI automation with fallback methods
        $submitResult = Submit-ClaudeInputWithFallback -Prompt $PromptResult.Prompt -Methods @("FileInput", "SendKeys") -RetryCount 2
        
        if ($submitResult.Success) {
            Update-CyclePhase -Cycle $Cycle -PhaseName "Submit" -Status "Completed" -Result $submitResult
            return @{ Success = $true; Result = $submitResult }
        } else {
            throw "Failed to submit prompt to Claude: $($submitResult.Error)"
        }
    } catch {
        $errorMsg = "Submit phase failed: $($_.Exception.Message)"
        Write-IntegrationLog $errorMsg -Level "ERROR"
        Update-CyclePhase -Cycle $Cycle -PhaseName "Submit" -Status "Failed" -ErrorMessage $errorMsg
        return @{ Success = $false; Error = $errorMsg }
    }
}

#endregion

#region Main Orchestration Functions

function Start-AutonomousFeedbackLoop {
    param(
        [string]$InitialPrompt = $null,
        [int]$MaxCycles = $null,
        [int]$CycleTimeoutMs = $null,
        [hashtable]$Configuration = @{}
    )
    
    Write-IntegrationLog "Starting autonomous feedback loop" -Level "INFO"
    
    # Initialize or load state
    $state = Get-IntegrationState
    if ($null -eq $state) {
        $state = Initialize-IntegrationState
    }
    
    # Apply configuration overrides
    if ($MaxCycles) { $script:IntegrationConfig.MaxCyclesPerSession = $MaxCycles }
    if ($CycleTimeoutMs) { $script:IntegrationConfig.CycleTimeoutMs = $CycleTimeoutMs }
    
    # Update state to running
    Update-IntegrationState -StateUpdates @{
        Status = "Running"
        CircuitBreakerTripped = $false
    }
    
    try {
        $cycleCount = 0
        $consecutiveFailures = 0
        
        while ($cycleCount -lt $script:IntegrationConfig.MaxCyclesPerSession) {
            # Check circuit breaker
            if ($consecutiveFailures -ge $script:IntegrationConfig.CircuitBreakerThreshold) {
                Write-IntegrationLog "Circuit breaker tripped after $consecutiveFailures consecutive failures" -Level "ERROR"
                Update-IntegrationState -StateUpdates @{
                    Status = "CircuitBreakerTripped"
                    CircuitBreakerTripped = $true
                    LastError = "Circuit breaker tripped"
                }
                break
            }
            
            $cycleCount++
            Write-IntegrationLog "Starting feedback cycle $cycleCount of $($script:IntegrationConfig.MaxCyclesPerSession)" -Level "INFO"
            
            # Create new cycle
            $cycle = New-FeedbackCycle -TriggerType "Autonomous" -InitialPrompt $InitialPrompt
            
            # Update state with current cycle
            Update-IntegrationState -StateUpdates @{
                CurrentCycle = $cycle
                CycleCount = $cycleCount
            }
            
            try {
                # Execute complete feedback cycle
                $cycleResult = Invoke-CompleteFeedbackCycle -Cycle $cycle
                
                if ($cycleResult.Success) {
                    $consecutiveFailures = 0
                    Update-IntegrationState -StateUpdates @{
                        SuccessfulCycles = $state.SuccessfulCycles + 1
                        ConsecutiveFailures = 0
                    }
                    Write-IntegrationLog "Cycle $cycleCount completed successfully" -Level "INFO"
                } else {
                    $consecutiveFailures++
                    Update-IntegrationState -StateUpdates @{
                        FailedCycles = $state.FailedCycles + 1
                        ConsecutiveFailures = $consecutiveFailures
                        LastError = $cycleResult.Error
                    }
                    Write-IntegrationLog "Cycle $cycleCount failed: $($cycleResult.Error)" -Level "ERROR"
                }
                
            } catch {
                $consecutiveFailures++
                $errorMsg = "Cycle $cycleCount exception: $($_.Exception.Message)"
                Write-IntegrationLog $errorMsg -Level "ERROR"
                
                Update-IntegrationState -StateUpdates @{
                    FailedCycles = $state.FailedCycles + 1
                    ConsecutiveFailures = $consecutiveFailures
                    LastError = $errorMsg
                }
            }
            
            # Brief pause between cycles
            Start-Sleep -Seconds 2
        }
        
        Write-IntegrationLog "Autonomous feedback loop completed: $cycleCount cycles executed" -Level "INFO"
        Update-IntegrationState -StateUpdates @{ Status = "Completed" }
        
    } catch {
        $errorMsg = "Autonomous feedback loop failed: $($_.Exception.Message)"
        Write-IntegrationLog $errorMsg -Level "ERROR"
        Update-IntegrationState -StateUpdates @{
            Status = "Failed"
            LastError = $errorMsg
        }
        throw
    }
}

function Invoke-CompleteFeedbackCycle {
    param(
        [hashtable]$Cycle
    )
    
    $cycleStartTime = Get-Date
    Write-IntegrationLog "Executing complete feedback cycle: $($Cycle.CycleId)" -Level "INFO"
    
    try {
        # Phase 1: Monitor for Claude responses
        $monitorResult = Invoke-FeedbackCyclePhase1Monitor -Cycle $Cycle
        if (-not $monitorResult.Success) {
            return Complete-FeedbackCycle -Cycle $Cycle -Success $false -ErrorMessage $monitorResult.Error
        }
        
        # Wait for actual Claude response file (simulated here)
        # In real implementation, this would wait for FileSystemWatcher event
        $responseFile = "claude_response_$(Get-Date -Format 'yyyyMMdd_HHmmss').json"
        
        # Phase 2: Parse Claude response
        $parseResult = Invoke-FeedbackCyclePhase2Parse -Cycle $Cycle -ResponseFile $responseFile
        if (-not $parseResult.Success) {
            return Complete-FeedbackCycle -Cycle $Cycle -Success $false -ErrorMessage $parseResult.Error
        }
        
        # Phase 3: Analyze results
        $analyzeResult = Invoke-FeedbackCyclePhase3Analyze -Cycle $Cycle -ParseResult $parseResult.Result
        if (-not $analyzeResult.Success) {
            return Complete-FeedbackCycle -Cycle $Cycle -Success $false -ErrorMessage $analyzeResult.Error
        }
        
        # Phase 4: Execute commands
        $executeResult = Invoke-FeedbackCyclePhase4Execute -Cycle $Cycle -AnalysisResult $analyzeResult.Result
        if (-not $executeResult.Success) {
            return Complete-FeedbackCycle -Cycle $Cycle -Success $false -ErrorMessage $executeResult.Error
        }
        
        # Phase 5: Generate follow-up prompt
        $generateResult = Invoke-FeedbackCyclePhase5Generate -Cycle $Cycle -ExecutionResults $executeResult.Result
        if (-not $generateResult.Success) {
            return Complete-FeedbackCycle -Cycle $Cycle -Success $false -ErrorMessage $generateResult.Error
        }
        
        # Phase 6: Submit prompt
        $submitResult = Invoke-FeedbackCyclePhase6Submit -Cycle $Cycle -PromptResult $generateResult.Result
        if (-not $submitResult.Success) {
            return Complete-FeedbackCycle -Cycle $Cycle -Success $false -ErrorMessage $submitResult.Error
        }
        
        # All phases completed successfully
        $completedCycle = Complete-FeedbackCycle -Cycle $Cycle -Success $true
        return @{ Success = $true; Cycle = $completedCycle }
        
    } catch {
        $errorMsg = "Complete feedback cycle failed: $($_.Exception.Message)"
        Write-IntegrationLog $errorMsg -Level "ERROR"
        $failedCycle = Complete-FeedbackCycle -Cycle $Cycle -Success $false -ErrorMessage $errorMsg
        return @{ Success = $false; Error = $errorMsg; Cycle = $failedCycle }
    }
}

function Stop-AutonomousFeedbackLoop {
    param(
        [string]$Reason = "Manual stop requested"
    )
    
    Write-IntegrationLog "Stopping autonomous feedback loop: $Reason" -Level "INFO"
    
    # Update state to stopped
    Update-IntegrationState -StateUpdates @{
        Status = "Stopped"
        LastError = $Reason
    }
    
    # Stop Claude monitoring if active
    try {
        Stop-ClaudeResponseMonitoring
    } catch {
        Write-IntegrationLog "Warning: Failed to stop Claude monitoring: $($_.Exception.Message)" -Level "WARNING"
    }
    
    Write-IntegrationLog "Autonomous feedback loop stopped successfully" -Level "INFO"
}

function Get-FeedbackLoopStatus {
    $state = Get-IntegrationState
    
    if ($null -eq $state) {
        return @{
            Status = "NotInitialized"
            Message = "No active feedback loop session"
        }
    }
    
    return @{
        SessionId = $state.SessionId
        Status = $state.Status
        StartTime = $state.StartTime
        LastActivity = $state.LastActivity
        CycleCount = $state.CycleCount
        SuccessfulCycles = $state.SuccessfulCycles
        FailedCycles = $state.FailedCycles
        ConsecutiveFailures = $state.ConsecutiveFailures
        CircuitBreakerTripped = $state.CircuitBreakerTripped
        CurrentCycle = $state.CurrentCycle
        PerformanceMetrics = $state.PerformanceMetrics
        LastError = $state.LastError
    }
}

function Resume-FeedbackLoopSession {
    param(
        [string]$SessionId = $null
    )
    
    $state = Get-IntegrationState
    
    if ($null -eq $state) {
        throw "No session state found to resume"
    }
    
    if ($SessionId -and $state.SessionId -ne $SessionId) {
        throw "Session ID mismatch. Expected: $SessionId, Found: $($state.SessionId)"
    }
    
    Write-IntegrationLog "Resuming feedback loop session: $($state.SessionId)" -Level "INFO"
    
    # Reset status if it was stopped or failed
    if ($state.Status -in @("Stopped", "Failed")) {
        Update-IntegrationState -StateUpdates @{
            Status = "Running"
            ConsecutiveFailures = 0
            CircuitBreakerTripped = $false
        }
    }
    
    # Continue with remaining cycles
    $remainingCycles = $script:IntegrationConfig.MaxCyclesPerSession - $state.CycleCount
    
    if ($remainingCycles -gt 0) {
        Start-AutonomousFeedbackLoop -MaxCycles $remainingCycles
    } else {
        Write-IntegrationLog "Session already completed maximum cycles" -Level "INFO"
    }
}

#endregion

#region Module Exports

Export-ModuleMember -Function @(
    # Main orchestration functions
    'Start-AutonomousFeedbackLoop',
    'Stop-AutonomousFeedbackLoop', 
    'Get-FeedbackLoopStatus',
    'Resume-FeedbackLoopSession',
    
    # Cycle management
    'New-FeedbackCycle',
    'Invoke-CompleteFeedbackCycle',
    
    # State management
    'Initialize-IntegrationState',
    'Get-IntegrationState',
    'Update-IntegrationState',
    
    # Utilities
    'Write-IntegrationLog'
)

#endregion

Write-Host "[IntegrationEngine] Module loaded successfully" -ForegroundColor Green
# SIG # Begin signature block
# MIIFqQYJKoZIhvcNAQcCoIIFmjCCBZYCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQU5iiek25hVqajaPAUiX/RaoyM
# 7fSgggMwMIIDLDCCAhSgAwIBAgIQdR0W2SKoK5VE8JId4ZxrRTANBgkqhkiG9w0B
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
# CQQxFgQUTAnhv8mTiuwMBaM9ZYuZ6eE2Y8YwDQYJKoZIhvcNAQEBBQAEggEAW6QO
# Ifbwr0zzuganIMLIMpp77VoHyYOf5EvgJonSpagGQjFotuYkiSzH/dEzVFq26FvU
# t3ftP2D8AWM73XpUHi+fb8GGeUoCMcumkmiGCUIm9tn0tysuzoT6hOsRzEBXQByr
# dr31lksSIifUmH7vi2SOBIQ/XkAU76jYPyIRQLrwkPChawJ3n3dCU+kWxoJtfy3X
# vBoMcwhyNoHTBXepV85fJlXUrYBbkK2tK4bspIbCC1KdhOvb24stQQ3DwaRHY1MS
# TCPQ20FBs5wTk39qUXfS4mM1VfJ+qnF1XvOvSi58k7OCt40CNXmYlkmHuayLyIk9
# F18DCnuZLPigRcZZsQ==
# SIG # End signature block
