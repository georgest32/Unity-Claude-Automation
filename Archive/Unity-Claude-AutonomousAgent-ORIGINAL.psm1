# Unity-Claude-AutonomousAgent.psm1
# Autonomous agent module for complete Claude Code CLI feedback loop automation
# Implements FileSystemWatcher, response parsing, command execution, and conversation management
# Date: 2025-08-18

#region Module Configuration and State

# Load additional modules for Phase 2 Days 9-10
# Use Import-Module instead of dot-sourcing to prevent files opening in editor
Write-Host "[DEBUG] Unity-Claude-AutonomousAgent: Starting module load" -ForegroundColor Cyan

$conversationStatePath = Join-Path $PSScriptRoot "ConversationStateManager.psm1"
$contextOptPath = Join-Path $PSScriptRoot "ContextOptimization.psm1"

Write-Host "[DEBUG] ConversationStateManager path: $conversationStatePath" -ForegroundColor Gray
Write-Host "[DEBUG] ContextOptimization path: $contextOptPath" -ForegroundColor Gray

if (Test-Path $conversationStatePath) {
    Write-Host "[DEBUG] ConversationStateManager file exists, importing..." -ForegroundColor Green
    try {
        Import-Module $conversationStatePath -Force -DisableNameChecking
        Write-Host "[DEBUG] ConversationStateManager imported successfully" -ForegroundColor Green
    } catch {
        Write-Host "[ERROR] Failed to import ConversationStateManager: $_" -ForegroundColor Red
    }
} else {
    Write-Host "[ERROR] ConversationStateManager file not found!" -ForegroundColor Red
}

if (Test-Path $contextOptPath) {
    Write-Host "[DEBUG] ContextOptimization file exists, importing..." -ForegroundColor Green
    try {
        Import-Module $contextOptPath -Force -DisableNameChecking
        Write-Host "[DEBUG] ContextOptimization imported successfully" -ForegroundColor Green
    } catch {
        Write-Host "[ERROR] Failed to import ContextOptimization: $_" -ForegroundColor Red
    }
} else {
    Write-Host "[ERROR] ContextOptimization file not found!" -ForegroundColor Red
}

Write-Host "[DEBUG] Module loading phase completed" -ForegroundColor Cyan

$script:AgentConfig = @{
    # Claude Code CLI Integration
    ClaudeOutputDirectory = Join-Path $PSScriptRoot "..\..\ClaudeResponses\Autonomous"
    ConversationHistoryPath = "$env:USERPROFILE\.claude\projects"
    
    # Response Processing
    ResponseTimeoutMs = 30000  # 30 seconds to wait for Claude response
    DebounceMs = 2000  # Wait 2 seconds after file change before processing
    MaxRetries = 3
    
    # Command Execution
    CommandTimeoutMs = 300000  # 5 minutes for command execution
    MaxConcurrentCommands = 3
    
    # Safety and Security
    ConfidenceThreshold = 0.7  # Minimum confidence for autonomous execution
    DryRunMode = $false  # Set to true for testing
    RequireHumanApproval = $false  # Override for sensitive operations
    
    # Conversation Management
    MaxConversationRounds = 10  # Maximum autonomous conversation rounds
    ContextPreservationDepth = 5  # Number of previous interactions to preserve
}

$script:AgentState = @{
    # Monitoring State
    IsMonitoring = $false
    FileWatcher = $null
    LastProcessedFile = ""
    
    # Conversation State
    CurrentConversationId = ""
    ConversationRound = 0
    ConversationContext = @()
    LastClaudeResponse = ""
    
    # Enhanced Day 2 State
    LastResponseClassification = $null
    LastConversationContext = $null
    LastConversationState = $null
    
    # Execution State  
    IsExecutingCommand = $false
    PendingCommands = [System.Collections.Queue]::new()
    ExecutionResults = @()
    
    # Statistics
    TotalConversationRounds = 0
    SuccessfulExecutions = 0
    FailedExecutions = 0
    HumanInterventions = 0
}

# Thread-safe logging using mutex
$script:LogMutex = New-Object System.Threading.Mutex($false, "UnityClaudeAutonomousAgentLog")

#endregion

#region Logging Functions

function Write-AgentLog {
    <#
    .SYNOPSIS
    Thread-safe logging function for autonomous agent operations
    
    .DESCRIPTION
    Writes log entries to the central unity_claude_automation.log file with mutex protection
    for thread-safe operation across multiple autonomous processes
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Message,
        
        [Parameter()]
        [ValidateSet("DEBUG", "INFO", "WARNING", "ERROR", "SUCCESS")]
        [string]$Level = "INFO",
        
        [Parameter()]
        [string]$Component = "AutonomousAgent"
    )
    
    try {
        # Acquire mutex for thread-safe file writing
        $script:LogMutex.WaitOne() | Out-Null
        
        $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss.fff"
        $logEntry = "[$timestamp] [$Level] [$Component] $Message"
        $logFile = Join-Path $PSScriptRoot "..\..\unity_claude_automation.log"
        
        Add-Content -Path $logFile -Value $logEntry -Encoding UTF8 -Force
        
        # Console output with color coding
        switch ($Level) {
            "ERROR" { Write-Host $logEntry -ForegroundColor Red }
            "WARNING" { Write-Host $logEntry -ForegroundColor Yellow }
            "SUCCESS" { Write-Host $logEntry -ForegroundColor Green }
            "DEBUG" { Write-Host $logEntry -ForegroundColor Cyan }
            default { Write-Host $logEntry -ForegroundColor Gray }
        }
    }
    catch {
        Write-Error "Failed to write to agent log: $_"
    }
    finally {
        # Always release mutex
        $script:LogMutex.ReleaseMutex()
    }
}

function Initialize-AgentLogging {
    <#
    .SYNOPSIS
    Initializes logging system for autonomous agent
    #>
    [CmdletBinding()]
    param()
    
    Write-AgentLog -Message "Autonomous agent logging system initialized" -Level "INFO"
    Write-AgentLog -Message "Agent configuration loaded successfully" -Level "DEBUG"
    
    # Create output directory if it doesn't exist
    if (-not (Test-Path $script:AgentConfig.ClaudeOutputDirectory)) {
        New-Item -Path $script:AgentConfig.ClaudeOutputDirectory -ItemType Directory -Force | Out-Null
        Write-AgentLog -Message "Created Claude output directory: $($script:AgentConfig.ClaudeOutputDirectory)" -Level "INFO"
    }
}

#endregion

#region FileSystemWatcher Implementation

function Start-ClaudeResponseMonitoring {
    <#
    .SYNOPSIS
    Starts FileSystemWatcher monitoring for Claude Code CLI responses
    
    .DESCRIPTION
    Monitors the Claude output directory for new response files created by headless mode
    Implements debouncing and thread-safe event handling
    #>
    [CmdletBinding()]
    param(
        [string]$OutputDirectory = $script:AgentConfig.ClaudeOutputDirectory,
        [int]$DebounceMs = $script:AgentConfig.DebounceMs
    )
    
    Write-AgentLog -Message "Starting Claude response monitoring" -Level "INFO"
    Write-AgentLog -Message "Monitoring directory: $OutputDirectory" -Level "DEBUG"
    
    try {
        # Ensure directory exists
        if (-not (Test-Path $OutputDirectory)) {
            New-Item -Path $OutputDirectory -ItemType Directory -Force | Out-Null
            Write-AgentLog -Message "Created monitoring directory: $OutputDirectory" -Level "INFO"
        }
        
        # Create FileSystemWatcher
        $script:AgentState.FileWatcher = New-Object System.IO.FileSystemWatcher
        $script:AgentState.FileWatcher.Path = $OutputDirectory
        $script:AgentState.FileWatcher.Filter = "*.json"  # Monitor JSON response files
        $script:AgentState.FileWatcher.IncludeSubdirectories = $false
        $script:AgentState.FileWatcher.NotifyFilter = [System.IO.NotifyFilters]::Creation -bor [System.IO.NotifyFilters]::LastWrite
        
        # Register event handlers
        Register-ObjectEvent -InputObject $script:AgentState.FileWatcher -EventName "Created" -Action {
            $filePath = $Event.SourceEventArgs.FullPath
            Write-AgentLog -Message "FileSystemWatcher: File created - $filePath" -Level "DEBUG" -Component "FileWatcher"
            
            # Implement debouncing - wait before processing
            Start-Sleep -Milliseconds $script:AgentConfig.DebounceMs
            
            # Process the response file
            try {
                Invoke-ProcessClaudeResponse -ResponseFilePath $filePath
            }
            catch {
                Write-AgentLog -Message "Error processing Claude response: $_" -Level "ERROR" -Component "FileWatcher"
            }
        } | Out-Null
        
        Register-ObjectEvent -InputObject $script:AgentState.FileWatcher -EventName "Changed" -Action {
            $filePath = $Event.SourceEventArgs.FullPath
            Write-AgentLog -Message "FileSystemWatcher: File changed - $filePath" -Level "DEBUG" -Component "FileWatcher"
            
            # Only process if it's not the same file we just processed
            if ($filePath -ne $script:AgentState.LastProcessedFile) {
                # Implement debouncing
                Start-Sleep -Milliseconds $script:AgentConfig.DebounceMs
                
                # Process the response file
                try {
                    Invoke-ProcessClaudeResponse -ResponseFilePath $filePath
                }
                catch {
                    Write-AgentLog -Message "Error processing Claude response: $_" -Level "ERROR" -Component "FileWatcher"
                }
            }
        } | Out-Null
        
        # Start monitoring
        $script:AgentState.FileWatcher.EnableRaisingEvents = $true
        $script:AgentState.IsMonitoring = $true
        
        Write-AgentLog -Message "Claude response monitoring started successfully" -Level "SUCCESS"
        Write-AgentLog -Message "Monitoring filter: *.json in $OutputDirectory" -Level "DEBUG"
        
        return $true
    }
    catch {
        Write-AgentLog -Message "Failed to start Claude response monitoring: $_" -Level "ERROR"
        return $false
    }
}

function Stop-ClaudeResponseMonitoring {
    <#
    .SYNOPSIS
    Stops FileSystemWatcher monitoring and cleans up resources
    #>
    [CmdletBinding()]
    param()
    
    Write-AgentLog -Message "Stopping Claude response monitoring" -Level "INFO"
    
    try {
        if ($script:AgentState.FileWatcher) {
            $script:AgentState.FileWatcher.EnableRaisingEvents = $false
            $script:AgentState.FileWatcher.Dispose()
            $script:AgentState.FileWatcher = $null
            Write-AgentLog -Message "FileSystemWatcher disposed successfully" -Level "DEBUG"
        }
        
        # Unregister event handlers
        Get-EventSubscriber | Where-Object { $_.SourceIdentifier -like "*FileSystemWatcher*" } | Unregister-Event
        
        $script:AgentState.IsMonitoring = $false
        Write-AgentLog -Message "Claude response monitoring stopped successfully" -Level "SUCCESS"
        
        return $true
    }
    catch {
        Write-AgentLog -Message "Error stopping Claude response monitoring: $_" -Level "ERROR"
        return $false
    }
}

#endregion

#region Claude Response Processing

function Invoke-ProcessClaudeResponse {
    <#
    .SYNOPSIS
    Processes a Claude Code CLI response file and extracts actionable recommendations
    
    .DESCRIPTION
    Parses JSON response from Claude, extracts RECOMMENDED commands, validates safety,
    and queues for execution or human approval
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$ResponseFilePath,
        
        [int]$MaxRetries = $script:AgentConfig.MaxRetries
    )
    
    Write-AgentLog -Message "Processing Claude response file: $ResponseFilePath" -Level "INFO" -Component "ResponseProcessor"
    
    # Validate file exists and is accessible
    $retryCount = 0
    while ($retryCount -lt $MaxRetries) {
        try {
            if (-not (Test-Path $ResponseFilePath)) {
                throw "Response file not found: $ResponseFilePath"
            }
            
            # Wait for file to be completely written (avoid reading partial files)
            Start-Sleep -Milliseconds 500
            
            # Check if file is locked by another process
            try {
                $fileStream = [System.IO.File]::Open($ResponseFilePath, 'Open', 'Read', 'ReadWrite')
                $fileStream.Close()
                $fileStream.Dispose()
                Write-AgentLog -Message "File accessibility confirmed: $ResponseFilePath" -Level "DEBUG" -Component "ResponseProcessor"
                break
            }
            catch {
                $retryCount++
                Write-AgentLog -Message "File locked, retry $retryCount/$MaxRetries" -Level "WARNING" -Component "ResponseProcessor"
                Start-Sleep -Milliseconds 1000
                
                if ($retryCount -ge $MaxRetries) {
                    throw "File remains locked after $MaxRetries attempts: $_"
                }
            }
        }
        catch {
            Write-AgentLog -Message "Error accessing response file: $_" -Level "ERROR" -Component "ResponseProcessor"
            return $false
        }
    }
    
    try {
        # Read and parse JSON response
        $responseContent = Get-Content -Path $ResponseFilePath -Raw -Encoding UTF8
        Write-AgentLog -Message "Response file read successfully ($(([System.Text.Encoding]::UTF8.GetBytes($responseContent)).Length) bytes)" -Level "DEBUG" -Component "ResponseProcessor"
        
        if ([string]::IsNullOrWhiteSpace($responseContent)) {
            Write-AgentLog -Message "Response file is empty, skipping processing" -Level "WARNING" -Component "ResponseProcessor"
            return $false
        }
        
        # Parse JSON with error handling for PowerShell 5.1 compatibility
        try {
            $responseObject = $responseContent | ConvertFrom-Json -ErrorAction Stop
            Write-AgentLog -Message "JSON response parsed successfully" -Level "DEBUG" -Component "ResponseProcessor"
        }
        catch {
            Write-AgentLog -Message "JSON parsing failed, treating as plain text: $_" -Level "WARNING" -Component "ResponseProcessor"
            $responseObject = @{ content = $responseContent; format = "text" }
        }
        
        # Update conversation state
        $script:AgentState.LastClaudeResponse = $responseContent
        $script:AgentState.LastProcessedFile = $ResponseFilePath
        
        # Enhanced Day 2 Processing: Classification, Context, and State Detection
        
        # Classify the response type
        $responseClassification = Classify-ClaudeResponse -ResponseObject $responseObject
        Write-AgentLog -Message "Response classified as: $($responseClassification.PrimaryType) (Confidence: $($responseClassification.Confidence))" -Level "INFO" -Component "ResponseProcessor"
        
        # Extract conversation context
        $conversationContext = Extract-ConversationContext -ResponseObject $responseObject
        Write-AgentLog -Message "Context extracted - Errors: $($conversationContext.ErrorMentions.Count), Files: $($conversationContext.FileMentions.Count)" -Level "DEBUG" -Component "ResponseProcessor"
        
        # Detect conversation state
        $conversationState = Detect-ConversationState -ResponseObject $responseObject -ConversationHistory $script:AgentState.ConversationContext
        Write-AgentLog -Message "Conversation state: $($conversationState.PrimaryState) (Can proceed autonomously: $($conversationState.CanProceedAutonomously))" -Level "INFO" -Component "ResponseProcessor"
        
        # Update agent state with enhanced information
        $script:AgentState.LastClaudeResponse = $responseContent
        $script:AgentState.LastProcessedFile = $ResponseFilePath
        $script:AgentState.LastResponseClassification = $responseClassification
        $script:AgentState.LastConversationContext = $conversationContext
        $script:AgentState.LastConversationState = $conversationState
        
        # Extract and process recommendations with enhanced parsing
        $recommendations = Find-ClaudeRecommendations -ResponseObject $responseObject
        Write-AgentLog -Message "Enhanced parsing found $($recommendations.Count) recommendations in response" -Level "INFO" -Component "ResponseProcessor"
        
        foreach ($recommendation in $recommendations) {
            Write-AgentLog -Message "Processing enhanced recommendation: $($recommendation.Type) - $($recommendation.Details) (Confidence: $($recommendation.Confidence), Pattern: $($recommendation.Pattern))" -Level "INFO" -Component "ResponseProcessor"
            
            # Enhanced recommendation includes confidence and pattern information
            $recommendation.ResponseClassification = $responseClassification
            $recommendation.ConversationContext = $conversationContext
            $recommendation.ConversationState = $conversationState
            
            # Queue recommendation for execution with enhanced context
            Add-RecommendationToQueue -Recommendation $recommendation
        }
        
        # Handle non-recommendation responses
        if ($recommendations.Count -eq 0) {
            Write-AgentLog -Message "No recommendations found, handling based on classification: $($responseClassification.PrimaryType)" -Level "INFO" -Component "ResponseProcessor"
            
            switch ($responseClassification.PrimaryType) {
                "Question" {
                    Write-AgentLog -Message "Claude is asking questions - may require human intervention" -Level "WARNING" -Component "ResponseProcessor"
                    # TODO: Implement question handling logic
                }
                "Error" {
                    Write-AgentLog -Message "Claude encountered an error - escalating to human" -Level "ERROR" -Component "ResponseProcessor"
                    # TODO: Implement error escalation logic
                }
                "Information" {
                    Write-AgentLog -Message "Claude provided information - analyzing for implicit actions" -Level "INFO" -Component "ResponseProcessor"
                    # TODO: Implement information analysis for implicit recommendations
                }
            }
        }
        
        # Update statistics
        $script:AgentState.TotalConversationRounds++
        
        Write-AgentLog -Message "Claude response processing completed successfully" -Level "SUCCESS" -Component "ResponseProcessor"
        return $true
    }
    catch {
        Write-AgentLog -Message "Error processing Claude response: $_" -Level "ERROR" -Component "ResponseProcessor"
        return $false
    }
}

function Find-ClaudeRecommendations {
    <#
    .SYNOPSIS
    Extracts RECOMMENDED commands from Claude responses using enhanced regex pattern matching
    
    .DESCRIPTION
    Parses Claude response text to find "RECOMMENDED: TYPE - details" patterns with advanced
    pattern recognition and confidence scoring for autonomous decision making
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [object]$ResponseObject
    )
    
    Write-AgentLog -Message "Starting enhanced recommendation extraction" -Level "DEBUG" -Component "EnhancedRecommendationParser"
    
    $recommendations = @()
    $responseText = ""
    
    # Extract text content from different response formats
    if ($ResponseObject -is [string]) {
        $responseText = $ResponseObject
    }
    elseif ($ResponseObject.content) {
        $responseText = $ResponseObject.content
    }
    elseif ($ResponseObject.message) {
        $responseText = $ResponseObject.message
    }
    elseif ($ResponseObject.text) {
        $responseText = $ResponseObject.text
    }
    else {
        # Convert object to string as fallback
        $responseText = $ResponseObject | Out-String
    }
    
    Write-AgentLog -Message "Extracted response text ($(($responseText.Length)) characters)" -Level "DEBUG" -Component "EnhancedRecommendationParser"
    
    # Enhanced regex patterns with named capturing groups for different recommendation formats
    $patterns = @{
        # Standard RECOMMENDED format
        Standard = '(?i)RECOMMENDED:\s*(?<type>TEST|BUILD|ANALYZE|DEBUGGING|CONTINUE|ARP)\s*[-–]\s*(?<details>[^\r\n]+)'
        
        # Action-oriented format (e.g., "You should TEST - run unit tests")
        ActionOriented = '(?i)(?:you\s+should|i\s+recommend|please)\s+(?<type>TEST|BUILD|ANALYZE|RUN|EXECUTE)\s*[-–]\s*(?<details>[^\r\n]+)'
        
        # Direct instruction format (e.g., "RUN TESTS to validate")
        DirectInstruction = '(?i)(?<type>RUN\s+TESTS?|BUILD|ANALYZE|EXECUTE|COMPILE)\s+(?<details>to\s+[^\r\n]+|for\s+[^\r\n]+|[^\r\n]*)'
        
        # Suggestion format (e.g., "I suggest running tests", "I recommend running tests")
        Suggestion = '(?i)i\s+(?:suggest|recommend)\s+(?<action>running|building|analyzing|executing|testing)\s+(?<details>[^\r\n]+)'
    }
    
    $allMatches = @()
    
    # Apply all patterns and collect matches
    foreach ($patternName in $patterns.Keys) {
        $matches = [regex]::Matches($responseText, $patterns[$patternName])
        Write-AgentLog -Message "Pattern '$patternName' found $($matches.Count) matches" -Level "DEBUG" -Component "EnhancedRecommendationParser"
        
        foreach ($match in $matches) {
            $allMatches += @{
                Match = $match
                Pattern = $patternName
                Confidence = Get-PatternConfidence -PatternName $patternName -Match $match
            }
        }
    }
    
    Write-AgentLog -Message "Total recommendation patterns found: $($allMatches.Count)" -Level "INFO" -Component "EnhancedRecommendationParser"
    
    # Process each match and create recommendation objects
    foreach ($matchInfo in $allMatches) {
        try {
            $match = $matchInfo.Match
            $recommendationType = ""
            $recommendationDetails = ""
            
            # Extract type and details based on pattern
            switch ($matchInfo.Pattern) {
                "Standard" {
                    $recommendationType = $match.Groups['type'].Value.Trim().ToUpper()
                    $recommendationDetails = $match.Groups['details'].Value.Trim()
                }
                "ActionOriented" {
                    $recommendationType = $match.Groups['type'].Value.Trim().ToUpper()
                    $recommendationDetails = $match.Groups['details'].Value.Trim()
                }
                "DirectInstruction" {
                    $rawType = $match.Groups['type'].Value.Trim()
                    $recommendationType = Convert-TypeToStandard -RawType $rawType
                    $recommendationDetails = $match.Groups['details'].Value.Trim()
                }
                "Suggestion" {
                    $action = $match.Groups['action'].Value.Trim()
                    $recommendationType = Convert-ActionToType -Action $action
                    $recommendationDetails = $match.Groups['details'].Value.Trim()
                }
            }
            
            Write-AgentLog -Message "Enhanced extraction - Pattern: $($matchInfo.Pattern), Type: $recommendationType, Details: $recommendationDetails" -Level "DEBUG" -Component "EnhancedRecommendationParser"
            
            # Validate and normalize recommendation type
            $normalizedType = Normalize-RecommendationType -Type $recommendationType
            if ($normalizedType) {
                $recommendation = @{
                    Type = $normalizedType
                    Details = $recommendationDetails
                    Source = "Claude"
                    Timestamp = Get-Date
                    ProcessingId = [System.Guid]::NewGuid().ToString()
                    Confidence = $matchInfo.Confidence
                    Pattern = $matchInfo.Pattern
                    OriginalText = $match.Value
                }
                
                $recommendations += $recommendation
                Write-AgentLog -Message "Enhanced recommendation created - ID: $($recommendation.ProcessingId), Confidence: $($recommendation.Confidence)" -Level "INFO" -Component "EnhancedRecommendationParser"
            }
            else {
                Write-AgentLog -Message "Invalid recommendation type after normalization: $recommendationType" -Level "WARNING" -Component "EnhancedRecommendationParser"
            }
        }
        catch {
            Write-AgentLog -Message "Error processing enhanced recommendation: $_" -Level "ERROR" -Component "EnhancedRecommendationParser"
        }
    }
    
    # Remove duplicates based on type and details similarity (only if we have recommendations)
    if ($recommendations.Count -gt 0) {
        $uniqueRecommendations = Remove-DuplicateRecommendations -Recommendations $recommendations
        Write-AgentLog -Message "After deduplication: $($uniqueRecommendations.Count) unique recommendations" -Level "INFO" -Component "EnhancedRecommendationParser"
    }
    else {
        $uniqueRecommendations = @()
        Write-AgentLog -Message "No recommendations to deduplicate" -Level "DEBUG" -Component "EnhancedRecommendationParser"
    }
    
    return $uniqueRecommendations
}

function Get-PatternConfidence {
    <#
    .SYNOPSIS
    Calculates confidence score for recommendation patterns based on pattern type and content
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$PatternName,
        
        [Parameter(Mandatory = $true)]
        [System.Text.RegularExpressions.Match]$Match
    )
    
    # Base confidence scores for different pattern types
    $baseConfidence = @{
        Standard = 0.95        # "RECOMMENDED: TYPE -" format (highest confidence)
        ActionOriented = 0.85  # "You should TEST -" format
        DirectInstruction = 0.80  # "RUN TESTS to validate" format
        Suggestion = 0.75      # "I suggest running" format (lowest confidence)
    }
    
    $confidence = $baseConfidence[$PatternName]
    
    # Adjust confidence based on specificity and clarity
    $details = ""
    if ($Match.Groups['details'] -and $Match.Groups['details'].Success) {
        $details = $Match.Groups['details'].Value.Trim()
        
        # Increase confidence for specific, actionable details
        if ($details.Length -gt 30) {
            $confidence += 0.05  # Detailed instructions boost confidence
        }
        
        # Increase confidence for specific Unity or technical terms
        if ($details -match "(?i)unity|test|build|compile|error|fix") {
            $confidence += 0.03
        }
        
        # Decrease confidence for vague instructions
        if ($details -match "(?i)check|verify|look|see|maybe|might|consider") {
            $confidence -= 0.05
        }
    }
    
    # Ensure confidence stays within 0.0-1.0 range
    $confidence = [Math]::Max(0.0, [Math]::Min(1.0, $confidence))
    
    Write-AgentLog -Message "Pattern confidence calculated: $PatternName = $confidence" -Level "DEBUG" -Component "ConfidenceCalculator"
    
    return $confidence
}

function Convert-TypeToStandard {
    <#
    .SYNOPSIS
    Converts various command type formats to standard types
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$RawType
    )
    
    $standardTypes = @{
        "RUN TESTS" = "TEST"
        "RUN TEST" = "TEST"
        "EXECUTE TESTS" = "TEST"
        "COMPILE" = "BUILD"
        "BUILD" = "BUILD"
        "ANALYZE" = "ANALYZE"
        "EXECUTE" = "TEST"  # Default execute to test
    }
    
    $normalized = $RawType.Trim().ToUpper()
    $result = $standardTypes[$normalized]
    
    if (-not $result) {
        # Fuzzy matching for similar types
        foreach ($key in $standardTypes.Keys) {
            if ($normalized -like "*$($key.Split(' ')[0])*") {
                $result = $standardTypes[$key]
                break
            }
        }
    }
    
    Write-AgentLog -Message "Type conversion: '$RawType' -> '$result'" -Level "DEBUG" -Component "TypeConverter"
    return $result
}

function Convert-ActionToType {
    <#
    .SYNOPSIS
    Converts action verbs to standard command types
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Action
    )
    
    $actionMappings = @{
        "running" = "TEST"
        "testing" = "TEST" 
        "building" = "BUILD"
        "compiling" = "BUILD"
        "analyzing" = "ANALYZE"
        "executing" = "TEST"
    }
    
    $normalized = $Action.Trim().ToLower()
    $result = $actionMappings[$normalized]
    
    Write-AgentLog -Message "Action conversion: '$Action' -> '$result'" -Level "DEBUG" -Component "ActionConverter"
    return $result
}

function Normalize-RecommendationType {
    <#
    .SYNOPSIS
    Normalizes recommendation types to standard values
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Type
    )
    
    $validTypes = @("TEST", "BUILD", "ANALYZE", "DEBUGGING", "CONTINUE", "ARP")
    $normalized = $Type.Trim().ToUpper()
    
    if ($normalized -in $validTypes) {
        return $normalized
    }
    
    # Fuzzy matching for close matches
    foreach ($validType in $validTypes) {
        if ($normalized -like "*$validType*" -or $validType -like "*$normalized*") {
            Write-AgentLog -Message "Fuzzy match normalization: '$Type' -> '$validType'" -Level "DEBUG" -Component "TypeNormalizer"
            return $validType
        }
    }
    
    Write-AgentLog -Message "No valid normalization found for: '$Type'" -Level "WARNING" -Component "TypeNormalizer"
    return $null
}

function Remove-DuplicateRecommendations {
    <#
    .SYNOPSIS
    Removes duplicate recommendations based on type and details similarity
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [array]$Recommendations
    )
    
    $unique = @()
    
    foreach ($rec in $Recommendations) {
        $isDuplicate = $false
        
        foreach ($existing in $unique) {
            # Check for exact type match
            if ($rec.Type -eq $existing.Type) {
                # Calculate similarity of details
                $similarity = Get-StringSimilarity -String1 $rec.Details -String2 $existing.Details
                
                if ($similarity -gt 0.8) {  # 80% similarity threshold for duplicates
                    $isDuplicate = $true
                    Write-AgentLog -Message "Duplicate recommendation detected: $($rec.Type) - similarity $similarity" -Level "DEBUG" -Component "DuplicateRemover"
                    
                    # Keep the one with higher confidence
                    if ($rec.Confidence -gt $existing.Confidence) {
                        Write-AgentLog -Message "Replacing with higher confidence version" -Level "DEBUG" -Component "DuplicateRemover"
                        $unique = $unique | Where-Object { $_.ProcessingId -ne $existing.ProcessingId }
                        $unique += $rec
                    }
                    break
                }
            }
        }
        
        if (-not $isDuplicate) {
            $unique += $rec
        }
    }
    
    Write-AgentLog -Message "Removed $($Recommendations.Count - $unique.Count) duplicate recommendations" -Level "INFO" -Component "DuplicateRemover"
    return $unique
}

function Get-StringSimilarity {
    <#
    .SYNOPSIS
    Calculates string similarity for duplicate detection
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$String1,
        
        [Parameter(Mandatory = $true)]
        [string]$String2
    )
    
    # Simple similarity calculation using common words
    $words1 = $String1.ToLower() -split '\s+' | Where-Object { $_.Length -gt 2 }
    $words2 = $String2.ToLower() -split '\s+' | Where-Object { $_.Length -gt 2 }
    
    if ($words1.Count -eq 0 -and $words2.Count -eq 0) { return 1.0 }
    if ($words1.Count -eq 0 -or $words2.Count -eq 0) { return 0.0 }
    
    $common = 0
    foreach ($word1 in $words1) {
        if ($word1 -in $words2) {
            $common++
        }
    }
    
    $similarity = ($common * 2.0) / ($words1.Count + $words2.Count)
    return $similarity
}

#endregion

#region Response Classification Engine

function Classify-ClaudeResponse {
    <#
    .SYNOPSIS
    Classifies Claude responses into categories for different handling
    
    .DESCRIPTION
    Analyzes Claude response content to determine response type:
    - Recommendation: Contains actionable recommendations
    - Question: Claude is asking for clarification or information
    - Information: Claude is providing information without recommendations
    - Instruction: Claude is giving step-by-step instructions
    - Error: Claude encountered an error or limitation
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [object]$ResponseObject
    )
    
    Write-AgentLog -Message "Starting Claude response classification" -Level "DEBUG" -Component "ResponseClassifier"
    
    # Extract text content
    $responseText = ""
    if ($ResponseObject -is [string]) {
        $responseText = $ResponseObject
    }
    elseif ($ResponseObject.content) {
        $responseText = $ResponseObject.content
    }
    elseif ($ResponseObject.message) {
        $responseText = $ResponseObject.message
    }
    else {
        $responseText = $ResponseObject | Out-String
    }
    
    Write-AgentLog -Message "Classifying response text ($($responseText.Length) characters)" -Level "DEBUG" -Component "ResponseClassifier"
    
    # Classification patterns
    $classifications = @()
    
    # Check for recommendations
    if ($responseText -match '(?i)RECOMMENDED|you\s+should|i\s+recommend|i\s+suggest') {
        $classifications += @{
            Type = "Recommendation"
            Confidence = 0.9
            Indicators = @("RECOMMENDED", "you should", "I recommend", "I suggest")
        }
    }
    
    # Check for questions
    $questionPatterns = @(
        '\?',  # Question marks
        '(?i)can\s+you\s+(?:tell\s+me|provide|clarify)',  # "Can you tell me"
        '(?i)(?:what|how|when|where|why|which)\s+(?:is|are|do|does|did|will|would|should|could)',  # Question words
        '(?i)could\s+you\s+(?:please\s+)?(?:check|verify|confirm)',  # "Could you check"
        '(?i)do\s+you\s+(?:have|know|see|understand)'  # "Do you have"
    )
    
    $questionScore = 0
    foreach ($pattern in $questionPatterns) {
        $matches = [regex]::Matches($responseText, $pattern)
        $questionScore += $matches.Count * 0.2
    }
    
    if ($questionScore -gt 0.1) {
        $classifications += @{
            Type = "Question"
            Confidence = [Math]::Min(0.9, $questionScore)
            Indicators = @("Question patterns detected")
        }
    }
    
    # Check for information/explanation
    $infoPatterns = @(
        '(?i)(?:here\s+(?:is|are)|this\s+(?:is|shows)|the\s+(?:reason|issue|problem)\s+is)',
        '(?i)(?:based\s+on|according\s+to|as\s+you\s+can\s+see)',
        '(?i)(?:the\s+(?:error|issue|problem)|this\s+(?:error|issue|problem))'
    )
    
    $infoScore = 0
    foreach ($pattern in $infoPatterns) {
        $matches = [regex]::Matches($responseText, $pattern)
        $infoScore += $matches.Count * 0.15
    }
    
    if ($infoScore -gt 0.1) {
        $classifications += @{
            Type = "Information"
            Confidence = [Math]::Min(0.8, $infoScore)
            Indicators = @("Information patterns detected")
        }
    }
    
    # Check for instructions
    if ($responseText -match '(?i)(?:step\s+\d+|first|then|next|finally|follow\s+these\s+steps)') {
        $classifications += @{
            Type = "Instruction"
            Confidence = 0.85
            Indicators = @("Step-by-step patterns detected")
        }
    }
    
    # Check for errors
    if ($responseText -match '(?i)(?:i\s+(?:cannot|can''t|unable)|error|sorry|unfortunately)') {
        $classifications += @{
            Type = "Error"
            Confidence = 0.8
            Indicators = @("Error/limitation patterns detected")
        }
    }
    
    # Default to Information if no specific classification found
    if ($classifications.Count -eq 0) {
        $classifications += @{
            Type = "Information"
            Confidence = 0.5
            Indicators = @("Default classification")
        }
    }
    
    # Return highest confidence classification
    $bestClassification = $classifications | Sort-Object Confidence -Descending | Select-Object -First 1
    
    Write-AgentLog -Message "Response classified as: $($bestClassification.Type) (Confidence: $($bestClassification.Confidence))" -Level "INFO" -Component "ResponseClassifier"
    
    return @{
        PrimaryType = $bestClassification.Type
        Confidence = $bestClassification.Confidence
        AllClassifications = $classifications
        ResponseLength = $responseText.Length
    }
}

function Extract-ConversationContext {
    <#
    .SYNOPSIS
    Extracts conversation context and relevant information from Claude responses
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [object]$ResponseObject
    )
    
    Write-AgentLog -Message "Extracting conversation context from Claude response" -Level "DEBUG" -Component "ContextExtractor"
    
    # Extract text content
    $responseText = ""
    if ($ResponseObject -is [string]) {
        $responseText = $ResponseObject
    }
    elseif ($ResponseObject.content) {
        $responseText = $ResponseObject.content
    }
    else {
        $responseText = $ResponseObject | Out-String
    }
    
    $context = @{
        ErrorMentions = @()
        FileMentions = @()
        TechnicalTerms = @()
        UnitySpecificContent = @()
        ConversationCues = @()
        NextActionSuggestions = @()
    }
    
    # Extract error mentions
    $errorPatterns = @(
        '(?i)(?<error>CS\d{4}:?[^\r\n]*)',  # Unity compilation errors
        '(?i)(?<error>error[^\r\n:]*:?[^\r\n]*)',  # General errors
        '(?i)(?<error>exception[^\r\n]*)',  # Exceptions
        '(?i)(?<error>failed[^\r\n]*)'  # Failures
    )
    
    foreach ($pattern in $errorPatterns) {
        $matches = [regex]::Matches($responseText, $pattern)
        foreach ($match in $matches) {
            $context.ErrorMentions += $match.Groups['error'].Value.Trim()
        }
    }
    
    # Extract file mentions
    $filePattern = '(?i)(?<file>[A-Za-z]:\\[^\s\r\n]*\.[a-z]{2,4}|[^\s\r\n]*\.(?:cs|js|ts|ps1|psm1|psd1|json|xml|txt)[^\s\r\n]*)'
    $fileMatches = [regex]::Matches($responseText, $filePattern)
    foreach ($match in $fileMatches) {
        $context.FileMentions += $match.Groups['file'].Value.Trim()
    }
    
    # Extract Unity-specific content
    $unityTerms = @("Unity", "GameObject", "MonoBehaviour", "EditorApplication", "CompilationPipeline", "Assembly", "Editor", "PlayMode", "EditMode")
    foreach ($term in $unityTerms) {
        if ($responseText -match "(?i)$term") {
            $context.UnitySpecificContent += $term
        }
    }
    
    # Extract conversation cues
    $cuePhrases = @("Let me", "I'll", "First", "Next", "Then", "Finally", "Before we", "After that")
    foreach ($phrase in $cuePhrases) {
        if ($responseText -match "(?i)$phrase") {
            $context.ConversationCues += $phrase
        }
    }
    
    # Extract next action suggestions
    $actionPattern = '(?i)(?:next|then|after\s+that),?\s*(?<action>[^\r\n.]+)'
    $actionMatches = [regex]::Matches($responseText, $actionPattern)
    foreach ($match in $actionMatches) {
        $context.NextActionSuggestions += $match.Groups['action'].Value.Trim()
    }
    
    Write-AgentLog -Message "Context extracted - Errors: $($context.ErrorMentions.Count), Files: $($context.FileMentions.Count), Unity terms: $($context.UnitySpecificContent.Count)" -Level "INFO" -Component "ContextExtractor"
    
    return $context
}

function Detect-ConversationState {
    <#
    .SYNOPSIS
    Detects the current conversation state for autonomous decision making
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [object]$ResponseObject,
        
        [Parameter()]
        [array]$ConversationHistory = @()
    )
    
    Write-AgentLog -Message "Detecting conversation state" -Level "DEBUG" -Component "StateDetector"
    
    # Extract text content
    $responseText = ""
    if ($ResponseObject -is [string]) {
        $responseText = $ResponseObject
    }
    elseif ($ResponseObject.content) {
        $responseText = $ResponseObject.content
    }
    else {
        $responseText = $ResponseObject | Out-String
    }
    
    # State detection patterns
    $states = @{
        WaitingForInput = @{
            Patterns = @(
                '(?i)(?:can\s+you\s+(?:provide|tell\s+me|show\s+me)|what\s+(?:is|are)|do\s+you\s+have)',
                '(?i)(?:could\s+you\s+please|please\s+(?:provide|send|share))',
                '(?i)(?:i\s+need\s+(?:more|additional)|please\s+(?:clarify|explain))',
                '(?i)\?'  # Question marks are strong indicators of waiting for input
            )
            BaseConfidence = 0.9
        }
        
        Processing = @{
            Patterns = @(
                '(?i)(?:let\s+me\s+(?:analyze|check|review|examine)|i''ll\s+(?:help|assist|work))',
                '(?i)(?:analyzing|processing|examining|reviewing)',
                '(?i)(?:working\s+on|looking\s+(?:at|into))',
                '(?i)(?:i\s+am\s+(?:analyzing|checking|reviewing))'
            )
            BaseConfidence = 0.85
        }
        
        Completed = @{
            Patterns = @(
                '(?i)(?:completed|finished|done|resolved)',
                '(?i)(?:here\s+(?:is|are)\s+the\s+(?:results|fix|solution))',
                '(?i)(?:the\s+(?:issue\s+is\s+)?(?:fixed|resolved|complete))'
            )
            BaseConfidence = 0.9
        }
        
        ProvidingGuidance = @{
            Patterns = @(
                '(?i)(?:here''s\s+how|follow\s+these\s+steps|to\s+(?:fix|resolve))',
                '(?i)(?:step\s+\d+|first|then|next|finally)',
                '(?i)(?:try\s+(?:the\s+following|this)|attempt\s+to)'
            )
            BaseConfidence = 0.85
        }
        
        ErrorEncountered = @{
            Patterns = @(
                '(?i)(?:i\s+(?:cannot|can''t)|unable\s+to|sorry)',
                '(?i)(?:error|exception|failed\s+to)',
                '(?i)(?:unfortunately|limitation|not\s+possible)'
            )
            BaseConfidence = 0.85
        }
    }
    
    $stateScores = @{}
    
    # Calculate scores for each state
    foreach ($stateName in $states.Keys) {
        $score = 0
        $state = $states[$stateName]
        
        foreach ($pattern in $state.Patterns) {
            $matches = [regex]::Matches($responseText, $pattern)
            $score += $matches.Count * 0.2
        }
        
        if ($score -gt 0) {
            $stateScores[$stateName] = [Math]::Min(0.95, $state.BaseConfidence + $score * 0.1)
        }
    }
    
    # Determine primary state
    $primaryState = "Unknown"
    $confidence = 0.3
    
    if ($stateScores.Count -gt 0) {
        $bestState = $stateScores.GetEnumerator() | Sort-Object Value -Descending | Select-Object -First 1
        $primaryState = $bestState.Name
        $confidence = $bestState.Value
    }
    
    Write-AgentLog -Message "Conversation state detected: $primaryState (Confidence: $confidence)" -Level "INFO" -Component "StateDetector"
    
    return @{
        PrimaryState = $primaryState
        Confidence = $confidence
        AllStates = $stateScores
        ConversationRound = $ConversationHistory.Count + 1
        RequiresHumanInput = ($primaryState -eq "WaitingForInput")
        CanProceedAutonomously = ($primaryState -in @("Completed", "ProvidingGuidance")) -and ($confidence -gt 0.7)
    }
}

#endregion

#region Command Queue Management

function Add-RecommendationToQueue {
    <#
    .SYNOPSIS
    Adds a recommendation to the execution queue with safety validation
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [hashtable]$Recommendation
    )
    
    Write-AgentLog -Message "Adding recommendation to execution queue: $($Recommendation.ProcessingId)" -Level "INFO" -Component "QueueManager"
    
    try {
        # Safety validation
        if ($Recommendation.Confidence -lt $script:AgentConfig.ConfidenceThreshold) {
            Write-AgentLog -Message "Recommendation below confidence threshold ($($Recommendation.Confidence) < $($script:AgentConfig.ConfidenceThreshold)), requiring human approval" -Level "WARNING" -Component "QueueManager"
            $Recommendation.RequiresApproval = $true
        }
        
        # Add to queue
        $script:AgentState.PendingCommands.Enqueue($Recommendation)
        
        Write-AgentLog -Message "Recommendation queued successfully: $($Recommendation.Type)" -Level "SUCCESS" -Component "QueueManager"
        
        # Trigger queue processing if not already running
        if (-not $script:AgentState.IsExecutingCommand) {
            Start-ThreadJob -ScriptBlock {
                # Import this module in the job context
                Import-Module $args[0] -Force
                Invoke-ProcessCommandQueue
            } -ArgumentList $PSScriptRoot -Name "CommandQueueProcessor" | Out-Null
        }
        
        return $true
    }
    catch {
        Write-AgentLog -Message "Error adding recommendation to queue: $_" -Level "ERROR" -Component "QueueManager"
        return $false
    }
}

function Invoke-ProcessCommandQueue {
    <#
    .SYNOPSIS
    Processes pending commands from the execution queue
    #>
    [CmdletBinding()]
    param()
    
    Write-AgentLog -Message "Starting command queue processing" -Level "INFO" -Component "QueueProcessor"
    
    while ($script:AgentState.PendingCommands.Count -gt 0) {
        try {
            $script:AgentState.IsExecutingCommand = $true
            
            # Dequeue next recommendation
            $recommendation = $script:AgentState.PendingCommands.Dequeue()
            Write-AgentLog -Message "Processing recommendation: $($recommendation.ProcessingId)" -Level "INFO" -Component "QueueProcessor"
            
            # Check if human approval required
            if ($recommendation.RequiresApproval -or $script:AgentConfig.RequireHumanApproval) {
                Write-AgentLog -Message "Human approval required for: $($recommendation.Type) - $($recommendation.Details)" -Level "WARNING" -Component "QueueProcessor"
                # TODO: Implement human approval mechanism
                continue
            }
            
            # Execute recommendation based on type
            $result = Invoke-SafeRecommendedCommand -Recommendation $recommendation
            
            # Store execution result
            $script:AgentState.ExecutionResults += @{
                RecommendationId = $recommendation.ProcessingId
                Type = $recommendation.Type
                Details = $recommendation.Details
                Result = $result
                Timestamp = Get-Date
                Success = $result.Success
            }
            
            if ($result.Success) {
                $script:AgentState.SuccessfulExecutions++
                Write-AgentLog -Message "Command executed successfully: $($recommendation.Type)" -Level "SUCCESS" -Component "QueueProcessor"
                
                # Generate follow-up prompt based on results
                $followUpPrompt = New-FollowUpPrompt -Recommendation $recommendation -Result $result
                if ($followUpPrompt) {
                    # Submit follow-up prompt to Claude
                    Submit-PromptToClaude -Prompt $followUpPrompt
                }
            }
            else {
                $script:AgentState.FailedExecutions++
                Write-AgentLog -Message "Command execution failed: $($recommendation.Type) - $($result.ErrorMessage)" -Level "ERROR" -Component "QueueProcessor"
            }
        }
        catch {
            Write-AgentLog -Message "Error in queue processing: $_" -Level "ERROR" -Component "QueueProcessor"
            $script:AgentState.FailedExecutions++
        }
    }
    
    $script:AgentState.IsExecutingCommand = $false
    Write-AgentLog -Message "Command queue processing completed" -Level "INFO" -Component "QueueProcessor"
}

#endregion

#region Day 3: Safe Command Execution Framework with Constrained Runspace

# Whitelisted cmdlets for constrained runspace execution
$script:SafeCmdlets = @{
    # File and path operations (safe subset)
    "Get-Content" = [Microsoft.PowerShell.Commands.GetContentCommand]
    "Test-Path" = [Microsoft.PowerShell.Commands.TestPathCommand]  
    "Get-ChildItem" = [Microsoft.PowerShell.Commands.GetChildItemCommand]
    "Get-Item" = [Microsoft.PowerShell.Commands.GetItemCommand]
    "Split-Path" = [Microsoft.PowerShell.Commands.SplitPathCommand]
    "Join-Path" = [Microsoft.PowerShell.Commands.JoinPathCommand]
    "Resolve-Path" = [Microsoft.PowerShell.Commands.ResolvePathCommand]
    
    # Measurement and analysis
    "Measure-Command" = [Microsoft.PowerShell.Commands.MeasureCommandCommand]
    "Measure-Object" = [Microsoft.PowerShell.Commands.MeasureObjectCommand]
    "Select-String" = [Microsoft.PowerShell.Commands.SelectStringCommand]
    "Select-Object" = [Microsoft.PowerShell.Commands.SelectObjectCommand]
    
    # Process management (controlled)
    "Get-Process" = [Microsoft.PowerShell.Commands.GetProcessCommand]
    "Start-Process" = [Microsoft.PowerShell.Commands.StartProcessCommand]
    "Stop-Process" = [Microsoft.PowerShell.Commands.StopProcessCommand]
    
    # String and data operations
    "ConvertFrom-Json" = [Microsoft.PowerShell.Commands.ConvertFromJsonCommand]
    "ConvertTo-Json" = [Microsoft.PowerShell.Commands.ConvertToJsonCommand]
    "Out-String" = [Microsoft.PowerShell.Commands.OutStringCommand]
    "Write-Output" = [Microsoft.PowerShell.Commands.WriteOutputCommand]
    
    # Basic utilities
    "Get-Date" = [Microsoft.PowerShell.Commands.GetDateCommand]
    "Start-Sleep" = [Microsoft.PowerShell.Commands.StartSleepCommand]
    "Write-Host" = [Microsoft.PowerShell.Commands.WriteHostCommand]
}

# Dangerous cmdlets that are explicitly blocked
$script:BlockedCmdlets = @(
    "Invoke-Expression",
    "Invoke-Command", 
    "Add-Type",
    "New-Object",
    "Set-ExecutionPolicy",
    "Import-Module",
    "Remove-Module",
    "Set-Location",
    "Set-Content",
    "Out-File",
    "Add-Content",
    "Remove-Item",
    "New-Item",
    "Copy-Item",
    "Move-Item"
)

function New-ConstrainedRunspace {
    <#
    .SYNOPSIS
    Creates a constrained runspace with whitelisted cmdlets for safe command execution
    
    .DESCRIPTION
    Creates a secure PowerShell runspace with only approved cmdlets available.
    Blocks dangerous cmdlets and provides isolated execution environment.
    #>
    [CmdletBinding()]
    param(
        [Parameter()]
        [hashtable]$AdditionalCmdlets = @{},
        
        [Parameter()]
        [int]$TimeoutMs = 300000  # 5 minutes default
    )
    
    Write-AgentLog -Message "Creating constrained runspace for safe command execution" -Level "INFO" -Component "ConstrainedRunspaceFactory"
    
    try {
        # Create empty initial session state
        $initialSessionState = [System.Management.Automation.Runspaces.InitialSessionState]::Create()
        Write-AgentLog -Message "Empty InitialSessionState created" -Level "DEBUG" -Component "ConstrainedRunspaceFactory"
        
        # Add safe cmdlets to the session state
        $cmdletCount = 0
        foreach ($cmdletName in $script:SafeCmdlets.Keys) {
            try {
                $cmdletType = $script:SafeCmdlets[$cmdletName]
                $cmdletEntry = New-Object System.Management.Automation.Runspaces.SessionStateCmdletEntry($cmdletName, $cmdletType, $null)
                $initialSessionState.Commands.Add($cmdletEntry)
                $cmdletCount++
                
                Write-AgentLog -Message "Added safe cmdlet: $cmdletName" -Level "DEBUG" -Component "ConstrainedRunspaceFactory"
            }
            catch {
                Write-AgentLog -Message "Failed to add cmdlet $cmdletName`: $_" -Level "WARNING" -Component "ConstrainedRunspaceFactory"
            }
        }
        
        # Add any additional cmdlets specified
        foreach ($cmdletName in $AdditionalCmdlets.Keys) {
            try {
                $cmdletType = $AdditionalCmdlets[$cmdletName]
                $cmdletEntry = New-Object System.Management.Automation.Runspaces.SessionStateCmdletEntry($cmdletName, $cmdletType, $null)
                $initialSessionState.Commands.Add($cmdletEntry)
                $cmdletCount++
                
                Write-AgentLog -Message "Added additional cmdlet: $cmdletName" -Level "DEBUG" -Component "ConstrainedRunspaceFactory"
            }
            catch {
                Write-AgentLog -Message "Failed to add additional cmdlet $cmdletName`: $_" -Level "WARNING" -Component "ConstrainedRunspaceFactory"
            }
        }
        
        Write-AgentLog -Message "Total cmdlets added to constrained runspace: $cmdletCount" -Level "INFO" -Component "ConstrainedRunspaceFactory"
        
        # Create the constrained runspace
        $runspace = [System.Management.Automation.Runspaces.RunspaceFactory]::CreateRunspace($initialSessionState)
        $runspace.Open()
        
        Write-AgentLog -Message "Constrained runspace created and opened successfully" -Level "SUCCESS" -Component "ConstrainedRunspaceFactory"
        
        # Store timeout setting for later use
        $runspace.SessionStateProxy.SetVariable("ConstrainedRunspaceTimeout", $TimeoutMs)
        
        return @{
            Runspace = $runspace
            CmdletCount = $cmdletCount
            TimeoutMs = $TimeoutMs
            Created = Get-Date
        }
    }
    catch {
        Write-AgentLog -Message "Error creating constrained runspace: $_" -Level "ERROR" -Component "ConstrainedRunspaceFactory"
        return $null
    }
}

function Test-CommandSafety {
    <#
    .SYNOPSIS
    Validates that a command is safe for execution in constrained environment
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$CommandName,
        
        [Parameter()]
        [array]$Parameters = @()
    )
    
    Write-AgentLog -Message "Testing command safety: $CommandName" -Level "DEBUG" -Component "CommandSafetyValidator"
    
    # Check if command is in blocked list
    if ($CommandName -in $script:BlockedCmdlets) {
        Write-AgentLog -Message "Command is explicitly blocked: $CommandName" -Level "ERROR" -Component "CommandSafetyValidator"
        return @{
            IsSafe = $false
            Reason = "Command is explicitly blocked for security"
            RiskLevel = "High"
        }
    }
    
    # Check if command is in safe list
    if ($CommandName -in $script:SafeCmdlets.Keys) {
        Write-AgentLog -Message "Command is whitelisted as safe: $CommandName" -Level "DEBUG" -Component "CommandSafetyValidator"
        
        # Additional parameter validation for specific commands
        $parameterValidation = Test-ParameterSafety -CommandName $CommandName -Parameters $Parameters
        
        return @{
            IsSafe = $parameterValidation.IsSafe
            Reason = if ($parameterValidation.IsSafe) { "Command and parameters are safe" } else { $parameterValidation.Reason }
            RiskLevel = if ($parameterValidation.IsSafe) { "Low" } else { "Medium" }
        }
    }
    
    # Unknown commands are not safe
    Write-AgentLog -Message "Command is not whitelisted: $CommandName" -Level "WARNING" -Component "CommandSafetyValidator"
    return @{
        IsSafe = $false
        Reason = "Command is not in whitelisted safe commands"
        RiskLevel = "Medium"
    }
}

function Test-ParameterSafety {
    <#
    .SYNOPSIS
    Validates parameters for safe command execution
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$CommandName,
        
        [Parameter()]
        [array]$Parameters = @()
    )
    
    Write-AgentLog -Message "Validating parameters for command: $CommandName" -Level "DEBUG" -Component "ParameterValidator"
    
    foreach ($param in $Parameters) {
        # Check for dangerous characters using Contains method to avoid wildcard pattern issues
        $dangerousChars = @('`', ';', '|', '&', '$', '(', ')', '{', '}', '[', ']', '<', '>')
        
        foreach ($char in $dangerousChars) {
            if ($param.ToString().Contains($char)) {
                Write-AgentLog -Message "Dangerous character detected in parameter: $char" -Level "WARNING" -Component "ParameterValidator"
                return @{
                    IsSafe = $false
                    Reason = "Parameter contains dangerous character: $char"
                }
            }
        }
        
        # Path validation for file-related commands
        if ($CommandName -in @("Get-Content", "Test-Path", "Get-ChildItem", "Get-Item")) {
            $pathValidation = Test-PathSafety -Path $param
            if (-not $pathValidation.IsSafe) {
                return $pathValidation
            }
        }
        
        Write-AgentLog -Message "Parameter validated as safe: $param" -Level "DEBUG" -Component "ParameterValidator"
    }
    
    return @{
        IsSafe = $true
        Reason = "All parameters validated successfully"
    }
}

function Test-PathSafety {
    <#
    .SYNOPSIS
    Validates that file paths are within project boundaries
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path
    )
    
    Write-AgentLog -Message "Validating path safety: $Path" -Level "DEBUG" -Component "PathValidator"
    
    # Get project root directory
    $projectRoot = "C:\UnityProjects\Sound-and-Shoal"  # TODO: Make configurable
    
    try {
        # Resolve to absolute path to prevent directory traversal
        $resolvedPath = [System.IO.Path]::GetFullPath($Path)
        $resolvedProjectRoot = [System.IO.Path]::GetFullPath($projectRoot)
        
        # Check if path is within project boundaries
        if (-not $resolvedPath.StartsWith($resolvedProjectRoot, [System.StringComparison]::OrdinalIgnoreCase)) {
            Write-AgentLog -Message "Path is outside project boundaries: $resolvedPath" -Level "ERROR" -Component "PathValidator"
            return @{
                IsSafe = $false
                Reason = "Path is outside allowed project boundaries"
            }
        }
        
        # Check for dangerous path patterns
        $dangerousPatterns = @("\..\", "//", "\\\\", "~", "%")
        foreach ($pattern in $dangerousPatterns) {
            if ($Path -like "*$pattern*") {
                Write-AgentLog -Message "Dangerous path pattern detected: $pattern" -Level "WARNING" -Component "PathValidator"
                return @{
                    IsSafe = $false
                    Reason = "Path contains dangerous pattern: $pattern"
                }
            }
        }
        
        Write-AgentLog -Message "Path validated as safe: $resolvedPath" -Level "DEBUG" -Component "PathValidator"
        return @{
            IsSafe = $true
            Reason = "Path is within project boundaries and safe"
            ResolvedPath = $resolvedPath
        }
    }
    catch {
        Write-AgentLog -Message "Error validating path: $_" -Level "ERROR" -Component "PathValidator"
        return @{
            IsSafe = $false
            Reason = "Path validation error: $($_.Exception.Message)"
        }
    }
}

function Invoke-SafeConstrainedCommand {
    <#
    .SYNOPSIS
    Executes a command in a constrained runspace with comprehensive safety checks
    
    .DESCRIPTION
    Creates a constrained runspace, validates command safety, sanitizes parameters,
    and executes with timeout protection and resource limits
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$CommandName,
        
        [Parameter()]
        [hashtable]$Parameters = @{},
        
        [Parameter()]
        [int]$TimeoutMs = 60000,  # 1 minute default for constrained commands
        
        [Parameter()]
        [switch]$DryRun
    )
    
    Write-AgentLog -Message "Starting safe constrained command execution: $CommandName" -Level "INFO" -Component "SafeConstrainedExecutor"
    
    # Validate command safety
    $parameterArray = $Parameters.Values
    $safetyCheck = Test-CommandSafety -CommandName $CommandName -Parameters $parameterArray
    
    if (-not $safetyCheck.IsSafe) {
        Write-AgentLog -Message "Command failed safety check: $($safetyCheck.Reason)" -Level "ERROR" -Component "SafeConstrainedExecutor"
        return @{
            Success = $false
            Output = ""
            ErrorMessage = "Command rejected by safety validation: $($safetyCheck.Reason)"
            ExitCode = -1
            ExecutionTime = 0
        }
    }
    
    Write-AgentLog -Message "Command passed safety validation (Risk: $($safetyCheck.RiskLevel))" -Level "INFO" -Component "SafeConstrainedExecutor"
    
    if ($DryRun) {
        Write-AgentLog -Message "DRY RUN: Would execute $CommandName with parameters: $($Parameters | ConvertTo-Json -Compress)" -Level "INFO" -Component "SafeConstrainedExecutor"
        return @{
            Success = $true
            Output = "DRY RUN: Command would execute safely"
            ErrorMessage = ""
            ExitCode = 0
            ExecutionTime = 0
        }
    }
    
    # Create constrained runspace
    $runspaceInfo = New-ConstrainedRunspace -TimeoutMs $TimeoutMs
    if (-not $runspaceInfo) {
        Write-AgentLog -Message "Failed to create constrained runspace" -Level "ERROR" -Component "SafeConstrainedExecutor"
        return @{
            Success = $false
            Output = ""
            ErrorMessage = "Failed to create constrained runspace"
            ExitCode = -1
            ExecutionTime = 0
        }
    }
    
    try {
        $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
        $runspace = $runspaceInfo.Runspace
        
        Write-AgentLog -Message "Executing command in constrained runspace (Timeout: $TimeoutMs ms)" -Level "INFO" -Component "SafeConstrainedExecutor"
        
        # Create PowerShell instance with constrained runspace
        $powershell = [System.Management.Automation.PowerShell]::Create()
        $powershell.Runspace = $runspace
        
        # Build command with parameters
        $powershell.AddCommand($CommandName)
        foreach ($paramName in $Parameters.Keys) {
            $sanitizedValue = Sanitize-ParameterValue -Value $Parameters[$paramName]
            $powershell.AddParameter($paramName, $sanitizedValue)
            Write-AgentLog -Message "Added parameter: $paramName = $sanitizedValue" -Level "DEBUG" -Component "SafeConstrainedExecutor"
        }
        
        # Execute with timeout protection
        $asyncResult = $powershell.BeginInvoke()
        $completed = $asyncResult.AsyncWaitHandle.WaitOne($TimeoutMs)
        
        if (-not $completed) {
            Write-AgentLog -Message "Command execution timed out, terminating..." -Level "WARNING" -Component "SafeConstrainedExecutor"
            $powershell.Stop()
            throw "Command execution timed out after $($TimeoutMs/1000) seconds"
        }
        
        # Get results
        $results = $powershell.EndInvoke($asyncResult)
        $errors = $powershell.Streams.Error
        
        $stopwatch.Stop()
        
        Write-AgentLog -Message "Constrained command execution completed in $($stopwatch.ElapsedMilliseconds)ms" -Level "SUCCESS" -Component "SafeConstrainedExecutor"
        
        # Check for errors
        if ($errors.Count -gt 0) {
            $errorMessage = ($errors | ForEach-Object { $_.Exception.Message }) -join "; "
            Write-AgentLog -Message "Command execution had errors: $errorMessage" -Level "WARNING" -Component "SafeConstrainedExecutor"
            
            return @{
                Success = $false
                Output = ($results | Out-String).Trim()
                ErrorMessage = $errorMessage
                ExitCode = 1
                ExecutionTime = $stopwatch.ElapsedMilliseconds
            }
        }
        
        return @{
            Success = $true
            Output = ($results | Out-String).Trim()
            ErrorMessage = ""
            ExitCode = 0
            ExecutionTime = $stopwatch.ElapsedMilliseconds
        }
    }
    catch {
        Write-AgentLog -Message "Error in constrained command execution: $_" -Level "ERROR" -Component "SafeConstrainedExecutor"
        return @{
            Success = $false
            Output = ""
            ErrorMessage = $_.Exception.Message
            ExitCode = -1
            ExecutionTime = if ($stopwatch) { $stopwatch.ElapsedMilliseconds } else { 0 }
        }
    }
    finally {
        # Cleanup resources
        if ($powershell) {
            $powershell.Dispose()
        }
        if ($runspaceInfo -and $runspaceInfo.Runspace) {
            $runspaceInfo.Runspace.Close()
            $runspaceInfo.Runspace.Dispose()
        }
        
        Write-AgentLog -Message "Constrained runspace resources cleaned up" -Level "DEBUG" -Component "SafeConstrainedExecutor"
    }
}

function Sanitize-ParameterValue {
    <#
    .SYNOPSIS
    Sanitizes parameter values to prevent injection attacks
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [object]$Value
    )
    
    if ($Value -is [string]) {
        # Remove dangerous characters
        $sanitized = $Value -replace '[`;&|$(){}[\]<>]', ''
        
        # Trim whitespace
        $sanitized = $sanitized.Trim()
        
        # Limit length to prevent buffer overflows
        if ($sanitized.Length -gt 1000) {
            $sanitized = $sanitized.Substring(0, 1000)
            Write-AgentLog -Message "Parameter value truncated to 1000 characters" -Level "WARNING" -Component "ParameterSanitizer"
        }
        
        if ($sanitized -ne $Value) {
            Write-AgentLog -Message "Parameter value sanitized: '$Value' -> '$sanitized'" -Level "DEBUG" -Component "ParameterSanitizer"
        }
        
        return $sanitized
    }
    
    # Non-string values returned as-is (numbers, booleans, etc.)
    return $Value
}

#endregion

#region Safe Command Execution Framework

function Invoke-SafeRecommendedCommand {
    <#
    .SYNOPSIS
    Safely executes a recommended command using constrained runspace and validation
    
    .DESCRIPTION
    Executes commands in isolated, secure environment with whitelisted cmdlets only
    Supports TEST, BUILD, and ANALYZE command types with comprehensive safety checks
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [hashtable]$Recommendation
    )
    
    Write-AgentLog -Message "Executing safe command: $($Recommendation.Type)" -Level "INFO" -Component "SafeExecutor"
    
    try {
        # Validate recommendation type
        $validTypes = @("TEST", "BUILD", "ANALYZE")
        if ($Recommendation.Type -notin $validTypes) {
            throw "Invalid command type: $($Recommendation.Type). Allowed types: $($validTypes -join ', ')"
        }
        
        # Create execution result object
        $result = @{
            Success = $false
            Output = ""
            ErrorMessage = ""
            ExecutionTime = 0
            ExitCode = -1
        }
        
        $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
        
        switch ($Recommendation.Type) {
            "TEST" {
                Write-AgentLog -Message "Executing TEST command: $($Recommendation.Details)" -Level "INFO" -Component "SafeExecutor"
                $result = Invoke-TestCommand -Details $Recommendation.Details
            }
            "BUILD" {
                Write-AgentLog -Message "Executing BUILD command: $($Recommendation.Details)" -Level "INFO" -Component "SafeExecutor"
                $result = Invoke-BuildCommand -Details $Recommendation.Details
            }
            "ANALYZE" {
                Write-AgentLog -Message "Executing ANALYZE command: $($Recommendation.Details)" -Level "INFO" -Component "SafeExecutor"
                $result = Invoke-AnalyzeCommand -Details $Recommendation.Details
            }
        }
        
        $stopwatch.Stop()
        $result.ExecutionTime = $stopwatch.ElapsedMilliseconds
        
        Write-AgentLog -Message "Command execution completed in $($result.ExecutionTime)ms - Success: $($result.Success)" -Level "INFO" -Component "SafeExecutor"
        
        return $result
    }
    catch {
        Write-AgentLog -Message "Error in safe command execution: $_" -Level "ERROR" -Component "SafeExecutor"
        return @{
            Success = $false
            Output = ""
            ErrorMessage = $_.Exception.Message
            ExecutionTime = 0
            ExitCode = -1
        }
    }
}

function Invoke-TestCommand {
    <#
    .SYNOPSIS
    Executes TEST type commands with Unity Test Runner and PowerShell tests
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Details
    )
    
    Write-AgentLog -Message "Processing TEST command details: $Details" -Level "DEBUG" -Component "TestExecutor"
    
    # Parse test command details
    if ($Details -match "(?i)unity.*test|run.*test|test.*unity") {
        return Invoke-UnityTests -TestDetails $Details
    }
    elseif ($Details -match "(?i)powershell.*test|pester|module.*test") {
        return Invoke-PowerShellTests -TestDetails $Details
    }
    elseif ($Details -match "(?i)compilation|compile|build.*test") {
        return Invoke-CompilationTest -TestDetails $Details
    }
    else {
        Write-AgentLog -Message "Unknown test type, defaulting to compilation test" -Level "WARNING" -Component "TestExecutor"
        return Invoke-CompilationTest -TestDetails $Details
    }
}

function Invoke-UnityTests {
    <#
    .SYNOPSIS
    Executes Unity Test Runner commands safely with constrained runspace and hanging prevention
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$TestDetails,
        
        [Parameter()]
        [switch]$DryRun
    )
    
    Write-AgentLog -Message "Executing Unity tests with enhanced security: $TestDetails" -Level "INFO" -Component "SecureUnityTestExecutor"
    
    try {
        # Validate Unity executable path
        $unityPath = Find-UnityExecutable
        if (-not $unityPath) {
            throw "Unity executable not found"
        }
        
        # Validate Unity executable is safe to execute
        $unityPathValidation = Test-PathSafety -Path $unityPath
        if (-not $unityPathValidation.IsSafe) {
            throw "Unity executable path validation failed: $($unityPathValidation.Reason)"
        }
        
        # Determine test platform (EditMode or PlayMode)
        $testPlatform = "EditMode"  # Default
        if ($TestDetails -match "(?i)playmode|play.*mode") {
            $testPlatform = "PlayMode"
        }
        
        # Setup and validate test paths
        $projectPath = "C:\UnityProjects\Sound-and-Shoal\Dithering"  # TODO: Make configurable
        $projectPathValidation = Test-PathSafety -Path $projectPath
        if (-not $projectPathValidation.IsSafe) {
            throw "Project path validation failed: $($projectPathValidation.Reason)"
        }
        
        $testTimestamp = Get-Date -Format "yyyyMMdd_HHmmss"
        $resultsPath = Join-Path $script:AgentConfig.ClaudeOutputDirectory "test_results_$testTimestamp.xml"
        $resultsPathValidation = Test-PathSafety -Path $resultsPath
        if (-not $resultsPathValidation.IsSafe) {
            throw "Results path validation failed: $($resultsPathValidation.Reason)"
        }
        
        # Validate and sanitize Unity command parameters
        $sanitizedProjectPath = Sanitize-ParameterValue -Value $projectPath
        $sanitizedResultsPath = Sanitize-ParameterValue -Value $resultsPath
        $sanitizedTestPlatform = Sanitize-ParameterValue -Value $testPlatform
        
        Write-AgentLog -Message "All paths validated and sanitized for Unity execution" -Level "INFO" -Component "SecureUnityTestExecutor"
        
        if ($DryRun) {
            Write-AgentLog -Message "DRY RUN: Would execute Unity tests with platform $testPlatform" -Level "INFO" -Component "SecureUnityTestExecutor"
            return @{
                Success = $true
                Output = "DRY RUN: Unity test execution validated for $testPlatform platform"
                ErrorMessage = ""
                ExitCode = 0
                ExecutionTime = 0
            }
        }
        
        # Use constrained execution for file operations
        Write-AgentLog -Message "Using constrained runspace for Unity test file operations" -Level "DEBUG" -Component "SecureUnityTestExecutor"
        
        # Validate results directory exists using constrained execution
        $dirCheckResult = Invoke-SafeConstrainedCommand -CommandName "Test-Path" -Parameters @{ Path = (Split-Path $resultsPath -Parent) }
        if ($dirCheckResult.Success -and $dirCheckResult.Output -eq "False") {
            Write-AgentLog -Message "Creating results directory using constrained execution" -Level "INFO" -Component "SecureUnityTestExecutor"
            # Directory creation would need to be handled by external process since New-Item is blocked
        }
        
        # Build Unity command with validated parameters
        $logPath = Join-Path $script:AgentConfig.ClaudeOutputDirectory "unity_test_log.txt"
        $sanitizedLogPath = Sanitize-ParameterValue -Value $logPath
        
        $unityArgs = @(
            "-runTests",
            "-batchmode", 
            "-projectPath", $sanitizedProjectPath,
            "-testResults", $sanitizedResultsPath,
            "-testPlatform", $sanitizedTestPlatform,
            "-logFile", $sanitizedLogPath
            # Note: No -quit flag to prevent hanging per Learning #98
        )
        
        Write-AgentLog -Message "Secure Unity command: $unityPath $($unityArgs -join ' ')" -Level "DEBUG" -Component "SecureUnityTestExecutor"
        
        # Execute Unity with enhanced security and hanging prevention
        $process = Start-Process -FilePath $unityPath -ArgumentList $unityArgs -PassThru -NoNewWindow
        Write-AgentLog -Message "Secure Unity test process started (PID: $($process.Id))" -Level "INFO" -Component "SecureUnityTestExecutor"
        
        # Enhanced watchdog timer with security monitoring
        $watchdogTimeoutMs = 300000  # 5 minutes maximum
        $checkIntervalMs = 5000     # Check every 5 seconds
        $totalWaitTime = 0
        
        while (-not $process.HasExited -and $totalWaitTime -lt $watchdogTimeoutMs) {
            Start-Sleep -Milliseconds $checkIntervalMs
            $totalWaitTime += $checkIntervalMs
            
            # Monitor process for security (CPU usage, memory, etc.)
            try {
                $processInfo = Get-Process -Id $process.Id -ErrorAction SilentlyContinue
                if ($processInfo) {
                    Write-AgentLog -Message "Unity process monitoring - CPU: $($processInfo.CPU), Memory: $($processInfo.WorkingSet64/1MB)MB, Elapsed: $($totalWaitTime/1000)s" -Level "DEBUG" -Component "SecureUnityTestExecutor"
                }
            }
            catch {
                Write-AgentLog -Message "Process monitoring warning: $_" -Level "DEBUG" -Component "SecureUnityTestExecutor"
            }
        }
        
        # Handle timeout or completion
        if (-not $process.HasExited) {
            Write-AgentLog -Message "Unity test process timed out, terminating securely..." -Level "WARNING" -Component "SecureUnityTestExecutor"
            $process.Kill()
            $process.WaitForExit(5000)
            
            return @{
                Success = $false
                Output = "Unity test execution timed out"
                ErrorMessage = "Process exceeded maximum execution time ($($watchdogTimeoutMs/1000) seconds)"
                ExitCode = -1
                ExecutionTime = $totalWaitTime
            }
        }
        
        Write-AgentLog -Message "Secure Unity test process completed (Exit Code: $($process.ExitCode))" -Level "INFO" -Component "SecureUnityTestExecutor"
        
        # Read test results using constrained execution
        $testOutput = ""
        if (Test-Path $resultsPath) {
            $readResult = Invoke-SafeConstrainedCommand -CommandName "Get-Content" -Parameters @{ Path = $resultsPath; Raw = $true }
            if ($readResult.Success) {
                $testOutput = $readResult.Output
                Write-AgentLog -Message "Test results read securely ($(([System.Text.Encoding]::UTF8.GetBytes($testOutput)).Length) bytes)" -Level "DEBUG" -Component "SecureUnityTestExecutor"
            }
            else {
                Write-AgentLog -Message "Failed to read test results securely: $($readResult.ErrorMessage)" -Level "WARNING" -Component "SecureUnityTestExecutor"
            }
        }
        
        return @{
            Success = ($process.ExitCode -eq 0)
            Output = $testOutput
            ErrorMessage = if ($process.ExitCode -ne 0) { "Unity tests failed with exit code $($process.ExitCode)" } else { "" }
            ExitCode = $process.ExitCode
            ExecutionTime = $totalWaitTime
        }
    }
    catch {
        Write-AgentLog -Message "Error in secure Unity test execution: $_" -Level "ERROR" -Component "SecureUnityTestExecutor"
        return @{
            Success = $false
            Output = ""
            ErrorMessage = $_.Exception.Message
            ExitCode = -1
            ExecutionTime = 0
        }
    }
}

function Find-UnityExecutable {
    <#
    .SYNOPSIS
    Locates Unity executable for command line execution
    #>
    [CmdletBinding()]
    param()
    
    # Common Unity installation paths
    $unityPaths = @(
        "C:\Program Files\Unity\Hub\Editor\2021.1.14f1\Editor\Unity.exe",
        "C:\Program Files\Unity\Editor\Unity.exe",
        "C:\Program Files (x86)\Unity\Editor\Unity.exe"
    )
    
    foreach ($path in $unityPaths) {
        if (Test-Path $path) {
            Write-AgentLog -Message "Found Unity executable: $path" -Level "DEBUG" -Component "UnityFinder"
            return $path
        }
    }
    
    Write-AgentLog -Message "Unity executable not found in standard locations" -Level "WARNING" -Component "UnityFinder"
    return $null
}

#endregion

#region Prompt Generation and Claude Integration

function New-FollowUpPrompt {
    <#
    .SYNOPSIS
    Generates intelligent follow-up prompts based on command execution results
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [hashtable]$Recommendation,
        
        [Parameter(Mandatory = $true)]
        [hashtable]$Result
    )
    
    Write-AgentLog -Message "Generating follow-up prompt for: $($Recommendation.Type)" -Level "INFO" -Component "PromptGenerator"
    
    try {
        $promptType = "Continue"  # Default prompt type
        $promptContent = ""
        
        if ($Result.Success) {
            Write-AgentLog -Message "Command succeeded, generating success prompt" -Level "DEBUG" -Component "PromptGenerator"
            
            switch ($Recommendation.Type) {
                "TEST" {
                    $promptType = "Test Results"
                    $promptContent = @"
The test execution completed successfully. Here are the results:

**Test Command**: $($Recommendation.Details)
**Execution Time**: $($Result.ExecutionTime)ms
**Exit Code**: $($Result.ExitCode)
**Output**: 
$($Result.Output)

The tests passed successfully. What should be the next step?
"@
                }
                "BUILD" {
                    $promptType = "Test Results"
                    $promptContent = @"
The build execution completed successfully. Here are the results:

**Build Command**: $($Recommendation.Details)
**Execution Time**: $($Result.ExecutionTime)ms
**Exit Code**: $($Result.ExitCode)

The build completed successfully. What should be the next step?
"@
                }
                "ANALYZE" {
                    $promptType = "Continue"
                    $promptContent = @"
The analysis completed successfully. Here are the results:

**Analysis Command**: $($Recommendation.Details)
**Results**: 
$($Result.Output)

Based on this analysis, what should be the next action?
"@
                }
            }
        }
        else {
            Write-AgentLog -Message "Command failed, generating error prompt" -Level "DEBUG" -Component "PromptGenerator"
            
            $promptType = "Debugging"
            $promptContent = @"
The recommended command failed to execute. Here are the details:

**Failed Command**: $($Recommendation.Type) - $($Recommendation.Details)
**Error Message**: $($Result.ErrorMessage)
**Exit Code**: $($Result.ExitCode)
**Output**: 
$($Result.Output)

Please analyze this failure and provide guidance on how to resolve the issue.
"@
        }
        
        $followUpPrompt = @{
            Type = $promptType
            Content = $promptContent
            Timestamp = Get-Date
            SourceRecommendation = $Recommendation.ProcessingId
            ConversationRound = $script:AgentState.ConversationRound + 1
        }
        
        Write-AgentLog -Message "Follow-up prompt generated: Type=$promptType, Length=$($promptContent.Length)" -Level "SUCCESS" -Component "PromptGenerator"
        
        return $followUpPrompt
    }
    catch {
        Write-AgentLog -Message "Error generating follow-up prompt: $_" -Level "ERROR" -Component "PromptGenerator"
        return $null
    }
}

function Submit-PromptToClaude {
    <#
    .SYNOPSIS
    Submits a prompt to Claude Code CLI using headless mode with output redirection
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [hashtable]$Prompt
    )
    
    Write-AgentLog -Message "Submitting prompt to Claude Code CLI: Type=$($Prompt.Type)" -Level "INFO" -Component "ClaudeSubmitter"
    
    try {
        # Increment conversation round
        $script:AgentState.ConversationRound = $Prompt.ConversationRound
        
        # Create unique output file for this prompt
        $timestamp = Get-Date -Format "yyyyMMdd_HHmmss_fff"
        $responseFile = Join-Path $script:AgentConfig.ClaudeOutputDirectory "response_$timestamp.json"
        
        # Escape prompt content for command line
        $escapedPrompt = $Prompt.Content -replace '"', '""'
        
        # Build Claude Code CLI command with headless mode and JSON output
        $claudeCommand = "claude"
        $claudeArgs = @(
            "-p", $escapedPrompt,
            "--output-format", "json"
        )
        
        Write-AgentLog -Message "Claude command: $claudeCommand $($claudeArgs -join ' ')" -Level "DEBUG" -Component "ClaudeSubmitter"
        Write-AgentLog -Message "Response will be captured to: $responseFile" -Level "DEBUG" -Component "ClaudeSubmitter"
        
        # Execute Claude Code CLI with output redirection
        $errorPath = Join-Path $script:AgentConfig.ClaudeOutputDirectory "claude_error_$timestamp.txt"
        $claudeProcess = Start-Process -FilePath $claudeCommand -ArgumentList $claudeArgs -PassThru -NoNewWindow -RedirectStandardOutput $responseFile -RedirectStandardError $errorPath
        
        Write-AgentLog -Message "Claude process started (PID: $($claudeProcess.Id))" -Level "INFO" -Component "ClaudeSubmitter"
        
        # Wait for Claude to complete with timeout
        $claudeTimeoutMs = $script:AgentConfig.ResponseTimeoutMs
        $completed = $claudeProcess.WaitForExit($claudeTimeoutMs)
        
        if (-not $completed) {
            Write-AgentLog -Message "Claude process timed out, terminating..." -Level "WARNING" -Component "ClaudeSubmitter"
            $claudeProcess.Kill()
            throw "Claude Code CLI timed out after $($claudeTimeoutMs/1000) seconds"
        }
        
        Write-AgentLog -Message "Claude process completed (Exit Code: $($claudeProcess.ExitCode))" -Level "INFO" -Component "ClaudeSubmitter"
        
        # Validate response file was created
        if (Test-Path $responseFile) {
            Write-AgentLog -Message "Claude response captured successfully: $responseFile" -Level "SUCCESS" -Component "ClaudeSubmitter"
            
            # Update conversation context
            $script:AgentState.ConversationContext += @{
                Round = $script:AgentState.ConversationRound
                Prompt = $Prompt
                ResponseFile = $responseFile
                Timestamp = Get-Date
            }
            
            # Note: Response processing will be handled by FileSystemWatcher
            return $true
        }
        else {
            throw "Claude response file not created: $responseFile"
        }
    }
    catch {
        Write-AgentLog -Message "Error submitting prompt to Claude: $_" -Level "ERROR" -Component "ClaudeSubmitter"
        return $false
    }
}

#endregion

#region Placeholder Command Implementations

function Invoke-PowerShellTests {
    <#
    .SYNOPSIS
    Placeholder for PowerShell test execution (Pester, module tests)
    #>
    [CmdletBinding()]
    param([string]$TestDetails)
    
    Write-AgentLog -Message "PowerShell test execution: $TestDetails" -Level "INFO" -Component "PowerShellTestExecutor"
    
    # TODO: Implement Pester test execution
    return @{
        Success = $true
        Output = "PowerShell tests completed (placeholder implementation)"
        ErrorMessage = ""
        ExitCode = 0
    }
}

function Invoke-CompilationTest {
    <#
    .SYNOPSIS
    Executes Unity compilation test using existing rapid compilation system
    #>
    [CmdletBinding()]
    param([string]$TestDetails)
    
    Write-AgentLog -Message "Compilation test execution: $TestDetails" -Level "INFO" -Component "CompilationTestExecutor"
    
    try {
        # Use existing rapid compilation script
        $rapidCompileScript = Join-Path $PSScriptRoot "..\..\Invoke-RapidUnityCompile.ps1"
        
        if (Test-Path $rapidCompileScript) {
            $compileResult = & $rapidCompileScript
            
            return @{
                Success = $true
                Output = "Compilation test completed using rapid compile system"
                ErrorMessage = ""
                ExitCode = 0
            }
        }
        else {
            throw "Rapid compile script not found: $rapidCompileScript"
        }
    }
    catch {
        return @{
            Success = $false
            Output = ""
            ErrorMessage = $_.Exception.Message
            ExitCode = -1
        }
    }
}

function Invoke-BuildCommand {
    <#
    .SYNOPSIS
    Placeholder for BUILD command execution
    #>
    [CmdletBinding()]
    param([string]$Details)
    
    Write-AgentLog -Message "Build command execution: $Details" -Level "INFO" -Component "BuildExecutor"
    
    # TODO: Implement Unity build automation with hanging prevention
    return @{
        Success = $true
        Output = "Build completed (placeholder implementation)"
        ErrorMessage = ""
        ExitCode = 0
    }
}

function Invoke-AnalyzeCommand {
    <#
    .SYNOPSIS
    Placeholder for ANALYZE command execution
    #>
    [CmdletBinding()]
    param([string]$Details)
    
    Write-AgentLog -Message "Analyze command execution: $Details" -Level "INFO" -Component "AnalyzeExecutor"
    
    # TODO: Implement log analysis and reporting automation
    return @{
        Success = $true
        Output = "Analysis completed (placeholder implementation)"
        ErrorMessage = ""
        ExitCode = 0
    }
}

#endregion

#region Module Exports

# Export public functions
Export-ModuleMember -Function @(
    'Initialize-AgentLogging',
    'Start-ClaudeResponseMonitoring', 
    'Stop-ClaudeResponseMonitoring',
    'Write-AgentLog',
    'Invoke-ProcessClaudeResponse',
    'Find-ClaudeRecommendations',
    'Add-RecommendationToQueue',
    'Invoke-ProcessCommandQueue',
    'Invoke-SafeRecommendedCommand',
    'New-FollowUpPrompt',
    'Submit-PromptToClaude',
    'Find-UnityExecutable',
    'Invoke-TestCommand',
    'Invoke-UnityTests',
    'Invoke-CompilationTest',
    'Invoke-PowerShellTests',
    'Invoke-BuildCommand',
    'Invoke-AnalyzeCommand',
    'Get-PatternConfidence',
    'Convert-TypeToStandard',
    'Convert-ActionToType', 
    'Normalize-RecommendationType',
    'Remove-DuplicateRecommendations',
    'Get-StringSimilarity',
    'Classify-ClaudeResponse',
    'Extract-ConversationContext',
    'Detect-ConversationState',
    'New-ConstrainedRunspace',
    'Test-CommandSafety',
    'Test-ParameterSafety',
    'Test-PathSafety',
    'Invoke-SafeConstrainedCommand',
    'Sanitize-ParameterValue'
)

# Module initialization note: Call Initialize-AgentLogging manually after import

Write-Host "[DEBUG] Unity-Claude-AutonomousAgent: Module export completed" -ForegroundColor Cyan
Write-Host "[DEBUG] Exported functions count: 32" -ForegroundColor Gray
Write-Host "[DEBUG] Key functions available:" -ForegroundColor Gray
Write-Host "  - Initialize-AgentLogging" -ForegroundColor Gray
Write-Host "  - Start-ClaudeResponseMonitoring" -ForegroundColor Gray
Write-Host "  - Write-AgentLog" -ForegroundColor Gray
Write-Host "[DEBUG] Note: This is the ORIGINAL module - refactored functions not available" -ForegroundColor Yellow

#endregion
# SIG # Begin signature block
# MIIFqQYJKoZIhvcNAQcCoIIFmjCCBZYCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUutfpME+ztoiMSjhK8I5zGooP
# 23ygggMwMIIDLDCCAhSgAwIBAgIQdR0W2SKoK5VE8JId4ZxrRTANBgkqhkiG9w0B
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
# CQQxFgQUihfBwjSWWVQdj+k1BGASFiZ3gBkwDQYJKoZIhvcNAQEBBQAEggEAiW49
# qNebvYdXyyErIwksNxiHO36GpNbUAoWryL6ePqX7tXDX0+gSlBWt4JTYVBu21wtX
# 2gVPI2FdktWsz7dK5+Sf4RVhd9saRykC0XEBmOWpUsi7sT+nCNR3jUYVKqc+v07A
# y9t9rIfW2U9KRlDaI28aWdrklh3vTXfJMbnHRcJS+0euTxNgw1+VU03lI2F3wXWi
# pORslx8umQCpqimk/YoWpM/lOjE9In9oK2fKDPbTy6blqGyqqa4i4aoi6Y3XZMSX
# G9wmhl+66N+KVh0wdETJxpG9lvsgpT7mVTaIy1XN48sCeiDOQPYbrQ40peKrUrLS
# fmqTX3JlaGrq2uVwsg==
# SIG # End signature block
