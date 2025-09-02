# DecisionEngine.psm1
# Phase 7 Day 3-4: Decision Engine Implementation
# Enhanced autonomous decision-making for Claude Code CLI responses
# Date: 2025-08-25

# ============================================================================
# MONOLITHIC VERSION - REFACTORED TO COMPONENT-BASED ARCHITECTURE
# This file has been refactored into focused components for better maintainability
# New Architecture: DecisionEngine-Refactored.psm1 + 5 specialized components
# Original: 926 lines -> Components: ~185 lines average (80% complexity reduction)
# Use DecisionEngine-Refactored.psm1 for new implementations
# ============================================================================

Write-Host "[WARN] Loading DecisionEngine.psm1 (MONOLITHIC VERSION - Consider using DecisionEngine-Refactored.psm1)" -ForegroundColor Yellow

#region Module Configuration and Logging

# Core configuration for decision engine
$script:DecisionConfig = @{
    # Rule-based decision matrix
    DecisionMatrix = @{
        "CONTINUE" = @{
            Priority = 1
            ActionType = "Continuation"
            SafetyLevel = "Low"
            RequiresValidation = $false
            MaxRetryAttempts = 1
            TimeoutSeconds = 30
        }
        "TEST" = @{
            Priority = 2
            ActionType = "TestExecution"
            SafetyLevel = "Medium"
            RequiresValidation = $true
            MaxRetryAttempts = 2
            TimeoutSeconds = 300
        }
        "FIX" = @{
            Priority = 3
            ActionType = "FileModification"
            SafetyLevel = "High"
            RequiresValidation = $true
            MaxRetryAttempts = 1
            TimeoutSeconds = 120
        }
        "COMPILE" = @{
            Priority = 4
            ActionType = "BuildOperation"
            SafetyLevel = "Medium"
            RequiresValidation = $true
            MaxRetryAttempts = 2
            TimeoutSeconds = 180
        }
        "RESTART" = @{
            Priority = 5
            ActionType = "ServiceRestart"
            SafetyLevel = "High"
            RequiresValidation = $true
            MaxRetryAttempts = 1
            TimeoutSeconds = 60
        }
        "COMPLETE" = @{
            Priority = 6
            ActionType = "TaskCompletion"
            SafetyLevel = "Low"
            RequiresValidation = $false
            MaxRetryAttempts = 1
            TimeoutSeconds = 30
        }
        "ERROR" = @{
            Priority = 7
            ActionType = "ErrorHandling"
            SafetyLevel = "Low"
            RequiresValidation = $false
            MaxRetryAttempts = 3
            TimeoutSeconds = 60
        }
    }
    
    # Safety validation thresholds
    SafetyThresholds = @{
        MinimumConfidence = 0.7
        MaxFileSize = 10MB
        AllowedFileExtensions = @('.ps1', '.psm1', '.psd1', '.json', '.txt', '.md', '.yml', '.yaml')
        BlockedPaths = @('C:\Windows', 'C:\Program Files', 'C:\Program Files (x86)')
        MaxConcurrentActions = 3
    }
    
    # Performance targets
    PerformanceTargets = @{
        DecisionTimeMs = 100
        ValidationTimeMs = 50
        QueueProcessingTimeMs = 25
    }
    
    # Action queue configuration
    ActionQueue = @{
        MaxQueueSize = 10
        PriorityLevels = 7
        DefaultTimeout = 300
    }
}

# Logging function with millisecond precision
function Write-DecisionLog {
    param(
        [string]$Message,
        [string]$Level = "INFO",
        [string]$Component = "DecisionEngine"
    )
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss.fff"
    $logEntry = "[$timestamp] [$Level] [$Component] $Message"
    Write-Host $logEntry -ForegroundColor $(
        switch ($Level) {
            "ERROR" { "Red" }
            "WARN" { "Yellow" }
            "SUCCESS" { "Green" }
            "DEBUG" { "Gray" }
            default { "White" }
        }
    )
}

#endregion

#region Rule-Based Decision Trees

# Main decision tree processor
function Invoke-RuleBasedDecision {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [hashtable]$AnalysisResult,
        
        [Parameter()]
        [switch]$IncludeDetails,
        
        [Parameter()]
        [switch]$DryRun
    )
    
    Write-DecisionLog "Starting rule-based decision processing" "INFO"
    $startTime = Get-Date
    
    try {
        # Input validation
        if (-not $AnalysisResult.ContainsKey('Recommendations') -or 
            -not $AnalysisResult.ContainsKey('ConfidenceAnalysis')) {
            throw "Invalid analysis result - missing required components"
        }
        
        $recommendations = $AnalysisResult.Recommendations
        $confidence = $AnalysisResult.ConfidenceAnalysis
        
        Write-DecisionLog "Processing $($recommendations.Count) recommendations with confidence $($confidence.OverallConfidence)" "INFO"
        
        # Step 1: Safety validation
        $safetyResult = Test-SafetyValidation -AnalysisResult $AnalysisResult
        if (-not $safetyResult.IsSafe) {
            Write-DecisionLog "Safety validation failed: $($safetyResult.Reason)" "ERROR"
            return @{
                Decision = "BLOCK"
                Reason = "Safety validation failed: $($safetyResult.Reason)"
                ProcessingTimeMs = ((Get-Date) - $startTime).TotalMilliseconds
                Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss.fff"
            }
        }
        
        # Step 2: Priority-based decision resolution
        $priorityResult = Resolve-PriorityDecision -Recommendations $recommendations -ConfidenceAnalysis $confidence
        
        # Step 3: Action queue preparation
        $queueResult = New-ActionQueueItem -Decision $priorityResult -AnalysisResult $AnalysisResult -DryRun:$DryRun
        
        # Step 4: Compile final decision
        $finalDecision = @{
            # Core Decision
            Decision = $priorityResult.RecommendationType
            Action = $priorityResult.Action
            Priority = $priorityResult.Priority
            
            # Safety Assessment
            SafetyLevel = $priorityResult.SafetyLevel
            SafetyValidated = $safetyResult.IsSafe
            
            # Confidence and Quality
            ConfidenceScore = $confidence.OverallConfidence
            QualityRating = $confidence.QualityRating
            
            # Action Queue Information
            QueuePosition = $queueResult.QueuePosition
            EstimatedExecutionTime = $queueResult.EstimatedExecutionTime
            
            # Processing Metadata
            ProcessingTimeMs = ((Get-Date) - $startTime).TotalMilliseconds
            Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss.fff"
            DryRun = $DryRun.IsPresent
        }
        
        # Add detailed information if requested
        if ($IncludeDetails) {
            $finalDecision.Details = @{
                AllRecommendations = $recommendations
                SafetyDetails = $safetyResult
                PriorityAnalysis = $priorityResult
                QueueDetails = $queueResult
            }
        }
        
        $processingTime = [int]$finalDecision.ProcessingTimeMs
        Write-DecisionLog "Decision completed: $($finalDecision.Decision) (Priority: $($finalDecision.Priority), Time: ${processingTime}ms)" "SUCCESS"
        
        # Performance warning
        if ($processingTime -gt $script:DecisionConfig.PerformanceTargets.DecisionTimeMs) {
            Write-DecisionLog "Decision processing exceeded target time (${processingTime}ms > $($script:DecisionConfig.PerformanceTargets.DecisionTimeMs)ms)" "WARN"
        }
        
        return $finalDecision
        
    } catch {
        $processingTime = ((Get-Date) - $startTime).TotalMilliseconds
        Write-DecisionLog "Decision processing failed: $($_.Exception.Message)" "ERROR"
        
        return @{
            Decision = "ERROR"
            Reason = $_.Exception.Message
            ProcessingTimeMs = $processingTime
            Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss.fff"
            Error = $_.Exception.ToString()
        }
    }
}

# Priority-based decision resolver
function Resolve-PriorityDecision {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [array]$Recommendations,
        
        [Parameter(Mandatory = $true)]
        [hashtable]$ConfidenceAnalysis
    )
    
    Write-DecisionLog "Resolving priority decision from $($Recommendations.Count) recommendations" "DEBUG"
    
    if ($Recommendations.Count -eq 0) {
        Write-DecisionLog "No recommendations found - defaulting to CONTINUE" "WARN"
        return @{
            RecommendationType = "CONTINUE"
            Action = "Continue processing"
            Priority = 1
            SafetyLevel = "Low"
            Reason = "No specific recommendations found"
        }
    }
    
    # Step 1: Filter by confidence threshold
    $confidenceThreshold = $script:DecisionConfig.SafetyThresholds.MinimumConfidence
    $validRecommendations = @($Recommendations | Where-Object { 
        $_.Confidence -ge $confidenceThreshold 
    })
    
    if ($validRecommendations.Count -eq 0) {
        Write-DecisionLog "No recommendations meet confidence threshold ($confidenceThreshold)" "WARN"
        return @{
            RecommendationType = "ERROR"
            Action = "Insufficient confidence in recommendations"
            Priority = 7
            SafetyLevel = "Low"
            Reason = "No recommendations meet minimum confidence threshold"
        }
    }
    
    Write-DecisionLog "Found $($validRecommendations.Count) recommendations above confidence threshold" "DEBUG"
    
    # Step 2: Sort by priority (lower number = higher priority)
    # Step 2: Add matrix properties and sort
    $prioritizedRecommendations = @()
    foreach ($rec in $validRecommendations) {
        $recType = $rec.Type
        $matrixEntry = $script:DecisionConfig.DecisionMatrix[$recType]
        
        if ($matrixEntry) {
            $rec | Add-Member -NotePropertyName 'MatrixPriority' -NotePropertyValue $matrixEntry.Priority -Force
            $rec | Add-Member -NotePropertyName 'MatrixSafetyLevel' -NotePropertyValue $matrixEntry.SafetyLevel -Force
            $rec | Add-Member -NotePropertyName 'MatrixActionType' -NotePropertyValue $matrixEntry.ActionType -Force
        } else {
            Write-DecisionLog "Unknown recommendation type: $recType - treating as low priority" "WARN"
            $rec | Add-Member -NotePropertyName 'MatrixPriority' -NotePropertyValue 10 -Force
            $rec | Add-Member -NotePropertyName 'MatrixSafetyLevel' -NotePropertyValue "Unknown" -Force
            $rec | Add-Member -NotePropertyName 'MatrixActionType' -NotePropertyValue "Unknown" -Force
        }
        $prioritizedRecommendations += $rec
    }
    
    # Sort by priority (only if multiple recommendations)
    # Lower priority number = higher priority, so sort ascending by priority
    # Then by confidence descending (higher is better) as tiebreaker
    if ($prioritizedRecommendations.Count -gt 1) {
        $prioritizedRecommendations = @($prioritizedRecommendations | Sort-Object @{Expression='MatrixPriority'; Ascending=$true}, @{Expression='Confidence'; Ascending=$false})
    }
    
    # Step 3: Select highest priority recommendation
    if ($prioritizedRecommendations.Count -eq 0) {
        Write-DecisionLog "No prioritized recommendations available" "ERROR"
        return @{
            RecommendationType = "ERROR"
            Action = "No valid recommendations found"
            Priority = 7
            SafetyLevel = "Low"
            Reason = "No prioritized recommendations available"
        }
    }
    
    $selectedRecommendation = $prioritizedRecommendations[0]
    
    # Step 4: Handle conflicts if multiple recommendations have same priority
    $samePriority = $prioritizedRecommendations | Where-Object { $_.MatrixPriority -eq $selectedRecommendation.MatrixPriority }
    if ($samePriority.Count -gt 1) {
        Write-DecisionLog "Found $($samePriority.Count) recommendations with same priority - using confidence as tiebreaker" "DEBUG"
        # Already sorted by confidence descending, so first item is correct
    }
    
    $result = @{
        RecommendationType = $selectedRecommendation.Type
        Action = $selectedRecommendation.Action
        Priority = $selectedRecommendation.MatrixPriority
        SafetyLevel = $selectedRecommendation.MatrixSafetyLevel
        ActionType = $selectedRecommendation.MatrixActionType
        Confidence = $selectedRecommendation.Confidence
        Reason = "Selected highest priority recommendation with confidence $($selectedRecommendation.Confidence)"
    }
    
    Write-DecisionLog "Selected recommendation: $($result.RecommendationType) (Priority: $($result.Priority), Confidence: $($result.Confidence))" "INFO"
    
    return $result
}

#endregion

#region Safety Validation Framework

# Comprehensive safety validation
function Test-SafetyValidation {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [hashtable]$AnalysisResult
    )
    
    Write-DecisionLog "Starting safety validation" "DEBUG"
    $startTime = Get-Date
    
    try {
        $safetyChecks = @()
        $overallSafe = $true
        
        # Check 1: Overall confidence threshold
        $confidence = $AnalysisResult.ConfidenceAnalysis.OverallConfidence
        $minConfidence = $script:DecisionConfig.SafetyThresholds.MinimumConfidence
        
        if ($confidence -lt $minConfidence) {
            $safetyChecks += @{
                Check = "ConfidenceThreshold"
                Result = "FAIL"
                Message = "Overall confidence ($confidence) below threshold ($minConfidence)"
                Impact = "High"
            }
            $overallSafe = $false
        } else {
            $safetyChecks += @{
                Check = "ConfidenceThreshold"
                Result = "PASS"
                Message = "Confidence level acceptable ($confidence >= $minConfidence)"
                Impact = "None"
            }
        }
        
        # Check 2: File path validation (if file operations detected)
        if ($AnalysisResult.Entities -and $AnalysisResult.Entities.FilePaths) {
            foreach ($filePath in $AnalysisResult.Entities.FilePaths) {
                # Handle both string and object formats for file paths
                $pathValue = if ($filePath -is [string]) { $filePath } else { $filePath.Value }
                $pathCheck = Test-SafeFilePath -FilePath $pathValue
                if (-not $pathCheck.IsSafe) {
                    $safetyChecks += @{
                        Check = "FilePathSafety"
                        Result = "FAIL"
                        Message = "Unsafe file path detected: $($pathCheck.Reason)"
                        Impact = "High"
                        FilePath = $pathValue
                    }
                    $overallSafe = $false
                } else {
                    $safetyChecks += @{
                        Check = "FilePathSafety"
                        Result = "PASS"
                        Message = "File path validated: $pathValue"
                        Impact = "None"
                        FilePath = $pathValue
                    }
                }
            }
        }
        
        # Check 3: Command validation (if PowerShell commands detected)
        if ($AnalysisResult.Entities -and $AnalysisResult.Entities.PowerShellCommands) {
            foreach ($command in $AnalysisResult.Entities.PowerShellCommands) {
                $cmdCheck = Test-SafeCommand -Command $command.Value
                if (-not $cmdCheck.IsSafe) {
                    $safetyChecks += @{
                        Check = "CommandSafety"
                        Result = "FAIL"
                        Message = "Unsafe command detected: $($cmdCheck.Reason)"
                        Impact = "High"
                        Command = $command.Value
                    }
                    $overallSafe = $false
                } else {
                    $safetyChecks += @{
                        Check = "CommandSafety"
                        Result = "PASS"
                        Message = "Command validated: $($command.Value)"
                        Impact = "None"
                        Command = $command.Value
                    }
                }
            }
        }
        
        # Check 4: Action queue capacity
        $queueCapacity = Test-ActionQueueCapacity
        if (-not $queueCapacity.HasCapacity) {
            $safetyChecks += @{
                Check = "QueueCapacity"
                Result = "FAIL"
                Message = "Action queue at capacity - cannot queue additional actions"
                Impact = "Medium"
            }
            $overallSafe = $false
        } else {
            $safetyChecks += @{
                Check = "QueueCapacity"
                Result = "PASS"
                Message = "Queue capacity available ($($queueCapacity.AvailableSlots) slots)"
                Impact = "None"
            }
        }
        
        $validationTime = ((Get-Date) - $startTime).TotalMilliseconds
        $targetTime = $script:DecisionConfig.PerformanceTargets.ValidationTimeMs
        
        if ($validationTime -gt $targetTime) {
            Write-DecisionLog "Safety validation exceeded target time (${validationTime}ms > ${targetTime}ms)" "WARN"
        }
        
        $result = @{
            IsSafe = $overallSafe
            Reason = if ($overallSafe) { "All safety checks passed" } else { "One or more safety checks failed" }
            Checks = $safetyChecks
            ValidationTimeMs = $validationTime
            ChecksPassed = ($safetyChecks | Where-Object { $_.Result -eq "PASS" }).Count
            ChecksFailed = ($safetyChecks | Where-Object { $_.Result -eq "FAIL" }).Count
        }
        
        Write-DecisionLog "Safety validation completed: $($result.ChecksPassed) passed, $($result.ChecksFailed) failed (${validationTime}ms)" $(if ($overallSafe) { "SUCCESS" } else { "WARN" })
        
        return $result
        
    } catch {
        Write-DecisionLog "Safety validation error: $($_.Exception.Message)" "ERROR"
        return @{
            IsSafe = $false
            Reason = "Safety validation error: $($_.Exception.Message)"
            ValidationTimeMs = ((Get-Date) - $startTime).TotalMilliseconds
            Error = $_.Exception.ToString()
        }
    }
}

# File path safety validation
function Test-SafeFilePath {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$FilePath
    )
    
    try {
        # Handle empty or null paths
        if ([string]::IsNullOrWhiteSpace($FilePath)) {
            return @{
                IsSafe = $true
                Reason = "Empty path - no safety concerns"
                Confidence = 1.0
                SafetyLevel = "High"
            }
        }
        
        # Normalize path
        $normalizedPath = [System.IO.Path]::GetFullPath($FilePath)
        
        # Check blocked paths
        foreach ($blockedPath in $script:DecisionConfig.SafetyThresholds.BlockedPaths) {
            if ($normalizedPath.StartsWith($blockedPath, [System.StringComparison]::OrdinalIgnoreCase)) {
                return @{
                    IsSafe = $false
                    Reason = "Path in blocked directory: $blockedPath"
                    NormalizedPath = $normalizedPath
                }
            }
        }
        
        # Check file extension
        $extension = [System.IO.Path]::GetExtension($FilePath).ToLowerInvariant()
        if ($extension -and -not ($script:DecisionConfig.SafetyThresholds.AllowedFileExtensions -contains $extension)) {
            return @{
                IsSafe = $false
                Reason = "File extension not allowed: $extension"
                NormalizedPath = $normalizedPath
            }
        }
        
        # Check file size if file exists
        if (Test-Path $normalizedPath) {
            $fileSize = (Get-Item $normalizedPath).Length
            if ($fileSize -gt $script:DecisionConfig.SafetyThresholds.MaxFileSize) {
                return @{
                    IsSafe = $false
                    Reason = "File too large: $fileSize bytes (max: $($script:DecisionConfig.SafetyThresholds.MaxFileSize))"
                    NormalizedPath = $normalizedPath
                }
            }
        }
        
        return @{
            IsSafe = $true
            Reason = "File path validated successfully"
            NormalizedPath = $normalizedPath
        }
        
    } catch {
        return @{
            IsSafe = $false
            Reason = "Path validation error: $($_.Exception.Message)"
            NormalizedPath = $FilePath
        }
    }
}

# Command safety validation
function Test-SafeCommand {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Command
    )
    
    # List of potentially dangerous commands/patterns
    $dangerousPatterns = @(
        'rm\s+-rf\s*/',
        'del\s+/s\s+/q',
        'Remove-Item\s+.*-Recurse.*-Force',
        'Format-Volume',
        'Restart-Computer',
        'Stop-Computer',
        'Clear-Host',
        'Clear-Content.*\*',
        'net\s+user.*password',
        'reg\s+delete',
        'schtasks.*delete',
        'wmic.*delete'
    )
    
    foreach ($pattern in $dangerousPatterns) {
        if ($Command -match $pattern) {
            return @{
                IsSafe = $false
                Reason = "Command matches dangerous pattern: $pattern"
                Command = $Command
            }
        }
    }
    
    # Additional checks for script execution
    if ($Command -match '\.ps1|\.bat|\.cmd|\.exe') {
        # Allow test scripts (with or without full paths)
        if ($Command -match 'Test-.*\.ps1|.*Test.*\.ps1') {
            return @{
                IsSafe = $true
                Reason = "Test script execution allowed"
                Command = $Command
            }
        }
        # Allow scripts in project directory
        elseif ($Command -match 'C:\\UnityProjects\\Sound-and-Shoal\\Unity-Claude-Automation') {
            return @{
                IsSafe = $true
                Reason = "Project directory script execution allowed"
                Command = $Command
            }
        }
        else {
            return @{
                IsSafe = $false
                Reason = "Script execution outside allowed scope"
                Command = $Command
            }
        }
    }
    
    return @{
        IsSafe = $true
        Reason = "Command validated successfully"
        Command = $Command
    }
}

#endregion

#region Priority-Based Action Queue

# Action queue management
$script:ActionQueue = @()
$script:QueueLock = New-Object System.Threading.Mutex($false, "CLIOrchestratorQueue")

# Test action queue capacity
function Test-ActionQueueCapacity {
    [CmdletBinding()]
    param()
    
    $currentSize = $script:ActionQueue.Count
    $maxSize = $script:DecisionConfig.ActionQueue.MaxQueueSize
    
    return @{
        HasCapacity = $currentSize -lt $maxSize
        CurrentSize = $currentSize
        MaxSize = $maxSize
        AvailableSlots = [Math]::Max(0, $maxSize - $currentSize)
    }
}

# Create new action queue item
function New-ActionQueueItem {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [hashtable]$Decision,
        
        [Parameter(Mandatory = $true)]
        [hashtable]$AnalysisResult,
        
        [Parameter()]
        [switch]$DryRun
    )
    
    Write-DecisionLog "Creating action queue item for: $($Decision.RecommendationType)" "DEBUG"
    
    try {
        # Get decision matrix entry
        $matrixEntry = $script:DecisionConfig.DecisionMatrix[$Decision.RecommendationType]
        if (-not $matrixEntry) {
            throw "Unknown recommendation type: $($Decision.RecommendationType)"
        }
        
        # Calculate estimated execution time
        $baseTime = $matrixEntry.TimeoutSeconds
        $complexityMultiplier = switch ($Decision.SafetyLevel) {
            "High" { 1.5 }
            "Medium" { 1.2 }
            "Low" { 1.0 }
            default { 1.0 }
        }
        $estimatedTime = [int]($baseTime * $complexityMultiplier)
        
        # Generate unique action ID
        $actionId = "CLIOrchestratorAction_$($Decision.RecommendationType)_$(Get-Date -Format 'yyyyMMdd_HHmmss_fff')"
        
        $queueItem = @{
            # Core Identification
            ActionId = $actionId
            RecommendationType = $Decision.RecommendationType
            ActionType = $Decision.ActionType
            
            # Execution Parameters
            Action = $Decision.Action
            Priority = $Decision.Priority
            SafetyLevel = $Decision.SafetyLevel
            MaxRetryAttempts = $matrixEntry.MaxRetryAttempts
            TimeoutSeconds = $matrixEntry.TimeoutSeconds
            EstimatedExecutionTime = $estimatedTime
            
            # Context Information
            SourceAnalysis = $AnalysisResult
            ConfidenceScore = $Decision.Confidence
            
            # Queue Management
            QueuedTime = Get-Date
            QueuePosition = $script:ActionQueue.Count + 1
            Status = "Queued"
            DryRun = $DryRun.IsPresent
            
            # Retry Logic
            RetryCount = 0
            LastAttempt = $null
            LastError = $null
        }
        
        # Add to queue if not dry run
        if (-not $DryRun) {
            try {
                $script:QueueLock.WaitOne(1000) | Out-Null
                $script:ActionQueue += $queueItem
                Write-DecisionLog "Action queued: $actionId (Position: $($queueItem.QueuePosition))" "SUCCESS"
            } finally {
                $script:QueueLock.ReleaseMutex()
            }
        } else {
            Write-DecisionLog "DRY RUN: Action would be queued: $actionId" "INFO"
        }
        
        return $queueItem
        
    } catch {
        Write-DecisionLog "Failed to create queue item: $($_.Exception.Message)" "ERROR"
        throw
    }
}

# Get current action queue status
function Get-ActionQueueStatus {
    [CmdletBinding()]
    param(
        [Parameter()]
        [switch]$IncludeDetails
    )
    
    try {
        $script:QueueLock.WaitOne(1000) | Out-Null
        
        $queueStatus = @{
            TotalItems = $script:ActionQueue.Count
            QueuedItems = ($script:ActionQueue | Where-Object { $_.Status -eq "Queued" }).Count
            ExecutingItems = ($script:ActionQueue | Where-Object { $_.Status -eq "Executing" }).Count
            CompletedItems = ($script:ActionQueue | Where-Object { $_.Status -eq "Completed" }).Count
            FailedItems = ($script:ActionQueue | Where-Object { $_.Status -eq "Failed" }).Count
            Capacity = Test-ActionQueueCapacity
            LastUpdate = Get-Date -Format "yyyy-MM-dd HH:mm:ss.fff"
        }
        
        if ($IncludeDetails -and $script:ActionQueue.Count -gt 0) {
            $queueStatus.QueueDetails = $script:ActionQueue | ForEach-Object {
                @{
                    ActionId = $_.ActionId
                    Type = $_.RecommendationType
                    Priority = $_.Priority
                    Status = $_.Status
                    QueuedTime = $_.QueuedTime
                    EstimatedTime = $_.EstimatedExecutionTime
                }
            }
        }
        
        return $queueStatus
        
    } finally {
        $script:QueueLock.ReleaseMutex()
    }
}

#endregion

#region Fallback Strategies

# Handle ambiguous or conflicting recommendations
function Resolve-ConflictingRecommendations {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [array]$ConflictingRecommendations,
        
        [Parameter(Mandatory = $true)]
        [hashtable]$ConfidenceAnalysis
    )
    
    Write-DecisionLog "Resolving conflicts between $($ConflictingRecommendations.Count) recommendations" "WARN"
    
    # Strategy 1: Use priority matrix
    $prioritized = $ConflictingRecommendations | ForEach-Object {
        $matrixEntry = $script:DecisionConfig.DecisionMatrix[$_.Type]
        $_ | Add-Member -NotePropertyName 'MatrixPriority' -NotePropertyValue ($matrixEntry?.Priority ?? 10) -PassThru
    } | Sort-Object MatrixPriority, @{Expression = {$_.Confidence}; Descending = $true}
    
    # Strategy 2: If priorities are equal, use confidence
    $selected = $prioritized[0]
    
    # Strategy 3: If confidence is low, default to safe action
    if ($selected.Confidence -lt 0.6) {
        Write-DecisionLog "Low confidence in conflict resolution - defaulting to CONTINUE" "WARN"
        return @{
            RecommendationType = "CONTINUE"
            Action = "Continue due to conflict resolution uncertainty"
            Priority = 1
            SafetyLevel = "Low"
            Reason = "Conflict resolution with low confidence - defaulting to safe action"
            ConflictResolutionStrategy = "SafeDefault"
        }
    }
    
    Write-DecisionLog "Conflict resolved: Selected $($selected.Type) with confidence $($selected.Confidence)" "INFO"
    
    return @{
        RecommendationType = $selected.Type
        Action = $selected.Action
        Priority = $selected.MatrixPriority
        SafetyLevel = $script:DecisionConfig.DecisionMatrix[$selected.Type]?.SafetyLevel ?? "Unknown"
        Confidence = $selected.Confidence
        Reason = "Conflict resolved using priority matrix and confidence scoring"
        ConflictResolutionStrategy = "PriorityMatrix"
        AlternativeRecommendations = if ($prioritized.Count -gt 1) { 
            $alternatives = @()
            for ($i = 1; $i -lt $prioritized.Count; $i++) { $alternatives += $prioritized[$i] }
            $alternatives
        } else { @() }
    }
}

# Graceful degradation for low-confidence scenarios
function Invoke-GracefulDegradation {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [hashtable]$AnalysisResult,
        
        [Parameter()]
        [string]$DegradationReason = "Low confidence analysis"
    )
    
    Write-DecisionLog "Invoking graceful degradation: $DegradationReason" "WARN"
    
    # Analyze what we can safely do
    $safeActions = @("CONTINUE", "COMPLETE", "ERROR")
    $confidence = $AnalysisResult.ConfidenceAnalysis?.OverallConfidence ?? 0.0
    
    # Select safest action based on context
    $degradedAction = if ($confidence -lt 0.3) {
        @{
            RecommendationType = "ERROR"
            Action = "Request clarification due to low confidence analysis"
            Priority = 7
            SafetyLevel = "Low"
            Reason = "Confidence too low for autonomous decision-making ($confidence)"
        }
    } elseif ($AnalysisResult.Classification?.Category -eq "Complete") {
        @{
            RecommendationType = "COMPLETE"
            Action = "Mark task as complete based on context analysis"
            Priority = 6
            SafetyLevel = "Low"
            Reason = "Task appears complete despite analysis uncertainty"
        }
    } else {
        @{
            RecommendationType = "CONTINUE"
            Action = "Continue processing with manual review recommendation"
            Priority = 1
            SafetyLevel = "Low"
            Reason = "Safe continuation while seeking human guidance"
        }
    }
    
    $degradedAction.DegradationApplied = $true
    $degradedAction.OriginalAnalysis = $AnalysisResult
    $degradedAction.DegradationReason = $DegradationReason
    
    Write-DecisionLog "Graceful degradation applied: $($degradedAction.RecommendationType)" "INFO"
    
    return $degradedAction
}

#endregion

# Export all functions for CLIOrchestrator integration
Export-ModuleMember -Function @(
    'Invoke-RuleBasedDecision',
    'Resolve-PriorityDecision',
    'Test-SafetyValidation',
    'Test-SafeFilePath',
    'Test-SafeCommand',
    'Test-ActionQueueCapacity',
    'New-ActionQueueItem',
    'Get-ActionQueueStatus',
    'Resolve-ConflictingRecommendations',
    'Invoke-GracefulDegradation'
)

# Module initialization
Write-DecisionLog "DecisionEngine module loaded successfully" "SUCCESS"
Write-DecisionLog "Configuration: $($script:DecisionConfig.DecisionMatrix.Count) decision types, $($script:DecisionConfig.ActionQueue.MaxQueueSize) max queue size" "INFO"
# SIG # Begin signature block
# MIIFzgYJKoZIhvcNAQcCoIIFvzCCBbsCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCCpRl1qy3cLJERI
# mLwNpqDuKQf6eMcWBe1NCiDdfqdxnKCCAzAwggMsMIICFKADAgECAhB1HRbZIqgr
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
# MAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIJq6efbSLmVAdRtAEspKevAk
# 7GKZLwvjT/TW34NWX3QkMA0GCSqGSIb3DQEBAQUABIIBAE7opiRASZ0+NvHB9aH/
# vumWZ4lU7DxyDWcrKRG6iCoVLhYCJEuJHBlIV85XvEAyYgC34xAgGL4P+sB36zN3
# o8rZ7ErOgeP1bvfElHLZW3Dx3/c6XBDIquqP/IElBBRGpmMecu1COEJWHSdNjEAj
# lkWmqQKYgEohJMfc3Aaqt+jUyZRK+7PS8lozODuX2nfsyf52PN+6iaR+qar5MXgd
# AF7lou79toqMWGvLA+yjv6LKveY/4Z1DIR3jYaHtzr5QckJM2mjnsR3Ci56xLMNa
# 6WSMB9wMERuRptVDKsSD+VipeHYd+NOzJz8R65BB7+2nzdHVkVKqx4kJP4bEne8C
# NqQ=
# SIG # End signature block
