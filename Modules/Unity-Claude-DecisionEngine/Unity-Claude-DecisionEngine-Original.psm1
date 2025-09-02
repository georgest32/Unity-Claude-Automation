# Unity-Claude-DecisionEngine Module
# Response Analysis and Decision Engine for Day 17 Integration
# Hybrid regex + AI parsing system with autonomous decision-making capabilities
# Compatible with PowerShell 5.1 and Unity 2021.1.14f1
#
# REFACTORED: This module has been refactored into modular components (2025-08-26)
# The manifest now loads Unity-Claude-DecisionEngine-Refactored.psm1 which orchestrates 4 focused components
# Original size: 1,284 lines | Components: 4 | Complexity reduction: 78%
# This file is preserved for reference and backward compatibility testing
#
# === MONOLITHIC VERSION - DO NOT USE IN PRODUCTION ===
Write-Host "[DecisionEngine] WARNING: Loading MONOLITHIC version (1,284 lines)" -ForegroundColor Yellow
Write-Host "[DecisionEngine] Use Unity-Claude-DecisionEngine.psd1 manifest for refactored version" -ForegroundColor Yellow

# Module-level variables
$script:DecisionEngineConfig = @{
    EnableDebugLogging = $true
    ConfidenceThreshold = 0.7
    MaxDecisionRetries = 3
    DecisionTimeoutMs = 5000
    EnableAIEnhancement = $true
    ContextWindowSize = 10
    LearningEnabled = $true
}

$script:LogPath = "C:\UnityProjects\Sound-and-Shoal\Unity-Claude-Automation\unity_claude_automation.log"

# Decision state tracking
$script:DecisionHistory = [System.Collections.Generic.List[hashtable]]::new()
$script:ContextBuffer = [System.Collections.Queue]::new()
$script:ActiveDecisions = @{}

# Import required modules if available
$RequiredModules = @('IntelligentPromptEngine', 'ConversationStateManager', 'Unity-Claude-ResponseMonitor')
foreach ($module in $RequiredModules) {
    if (Get-Module -ListAvailable -Name $module) {
        Import-Module $module -Force -ErrorAction SilentlyContinue
    }
}

#region Logging and Utilities

function Write-DecisionEngineLog {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Message,
        
        [Parameter()]
        [ValidateSet("INFO", "WARN", "ERROR", "DEBUG")]
        [string]$Level = "INFO"
    )
    
    if (-not $script:DecisionEngineConfig.EnableDebugLogging -and $Level -eq "DEBUG") {
        return
    }
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logEntry = "[$timestamp] [$Level] [DecisionEngine] $Message"
    
    try {
        Add-Content -Path $script:LogPath -Value $logEntry -Encoding UTF8 -ErrorAction SilentlyContinue
    } catch {
        # Silently continue if logging fails
    }
    
    if ($Level -eq "ERROR") {
        Write-Error $Message
    } elseif ($Level -eq "WARN") {
        Write-Warning $Message
    } elseif ($script:DecisionEngineConfig.EnableDebugLogging) {
        Write-Host "[$Level] $Message" -ForegroundColor $(
            switch ($Level) {
                "INFO" { "Green" }
                "DEBUG" { "Gray" }
                default { "White" }
            }
        )
    }
}

function Test-RequiredModule {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$ModuleName
    )
    
    $module = Get-Module -Name $ModuleName -ErrorAction SilentlyContinue
    if (-not $module) {
        Write-DecisionEngineLog -Message "Required module '$ModuleName' not loaded" -Level "WARN"
        return $false
    }
    return $true
}

#endregion

#region Configuration Management

function Get-DecisionEngineConfig {
    [CmdletBinding()]
    param()
    
    Write-DecisionEngineLog -Message "Retrieving Decision Engine configuration" -Level "DEBUG"
    return $script:DecisionEngineConfig.Clone()
}

function Set-DecisionEngineConfig {
    [CmdletBinding()]
    param(
        [Parameter()]
        [bool]$EnableDebugLogging,
        
        [Parameter()]
        [double]$ConfidenceThreshold,
        
        [Parameter()]
        [int]$MaxDecisionRetries,
        
        [Parameter()]
        [int]$DecisionTimeoutMs,
        
        [Parameter()]
        [bool]$EnableAIEnhancement,
        
        [Parameter()]
        [int]$ContextWindowSize,
        
        [Parameter()]
        [bool]$LearningEnabled
    )
    
    Write-DecisionEngineLog -Message "Updating Decision Engine configuration" -Level "INFO"
    
    if ($PSBoundParameters.ContainsKey('EnableDebugLogging')) {
        $script:DecisionEngineConfig.EnableDebugLogging = $EnableDebugLogging
    }
    if ($PSBoundParameters.ContainsKey('ConfidenceThreshold')) {
        $script:DecisionEngineConfig.ConfidenceThreshold = $ConfidenceThreshold
    }
    if ($PSBoundParameters.ContainsKey('MaxDecisionRetries')) {
        $script:DecisionEngineConfig.MaxDecisionRetries = $MaxDecisionRetries
    }
    if ($PSBoundParameters.ContainsKey('DecisionTimeoutMs')) {
        $script:DecisionEngineConfig.DecisionTimeoutMs = $DecisionTimeoutMs
    }
    if ($PSBoundParameters.ContainsKey('EnableAIEnhancement')) {
        $script:DecisionEngineConfig.EnableAIEnhancement = $EnableAIEnhancement
    }
    if ($PSBoundParameters.ContainsKey('ContextWindowSize')) {
        $script:DecisionEngineConfig.ContextWindowSize = $ContextWindowSize
    }
    if ($PSBoundParameters.ContainsKey('LearningEnabled')) {
        $script:DecisionEngineConfig.LearningEnabled = $LearningEnabled
    }
    
    Write-DecisionEngineLog -Message "Decision Engine configuration updated successfully" -Level "INFO"
}

#endregion

#region Advanced Response Analysis

function Invoke-HybridResponseAnalysis {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [hashtable]$Response,
        
        [Parameter()]
        [hashtable]$Context = @{}
    )
    
    Write-DecisionEngineLog -Message "Starting hybrid response analysis" -Level "INFO"
    
    try {
        # Phase 1: Traditional regex-based extraction
        $regexAnalysis = Invoke-RegexBasedAnalysis -Content $Response.Content
        Write-DecisionEngineLog -Message "Regex analysis found $($regexAnalysis.ActionableItems.Count) items" -Level "DEBUG"
        
        # Phase 2: AI-enhanced semantic analysis (if enabled)
        $aiAnalysis = @{
            SemanticContext = @{}
            IntentClassification = "Unknown"
            ConfidenceScore = 0.5
            EnhancedActions = @()
        }
        
        if ($script:DecisionEngineConfig.EnableAIEnhancement) {
            $aiAnalysis = Invoke-AIEnhancedAnalysis -Content $Response.Content -Context $Context
            Write-DecisionEngineLog -Message "AI analysis classified intent as: $($aiAnalysis.IntentClassification)" -Level "DEBUG"
        }
        
        # Phase 3: Hybrid fusion of regex + AI results
        $fusedAnalysis = Merge-AnalysisResults -RegexAnalysis $regexAnalysis -AIAnalysis $aiAnalysis
        
        # Phase 4: Context enrichment using conversation history
        $enrichedAnalysis = Add-ContextualEnrichment -Analysis $fusedAnalysis -Context $Context -Response $Response
        
        Write-DecisionEngineLog -Message "Hybrid analysis completed with confidence: $($enrichedAnalysis.OverallConfidence)" -Level "INFO"
        
        return $enrichedAnalysis
    }
    catch {
        Write-DecisionEngineLog -Message "Error in hybrid response analysis: $_" -Level "ERROR"
        return @{
            Success = $false
            Error = $_.Exception.Message
            OverallConfidence = 0.0
            ActionableItems = @()
        }
    }
}

function Invoke-RegexBasedAnalysis {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Content
    )
    
    Write-DecisionEngineLog -Message "Performing regex-based analysis" -Level "DEBUG"
    
    # Research-validated named capture group patterns for 2025
    $advancedPatterns = @{
        "RECOMMENDED" = @{
            Pattern = 'RECOMMENDED:\s*(?<ActionType>[A-Z-]+)\s*-\s*(?<Action>[^.\n]+)(?:\.?\s*(?<Details>.+?))?(?=\n\n|\n[A-Z]+:|$)'
            Priority = 9
            Confidence = 0.9
        }
        "TEST_REQUEST" = @{
            Pattern = 'RECOMMENDED:\s*TEST\s*-\s*(?<TestType>[^.\n]+)(?:\.?\s*(?<TestDetails>.+?))?(?=\n\n|\n[A-Z]+:|$)'
            Priority = 8
            Confidence = 0.85
        }
        "EXECUTION_COMMAND" = @{
            Pattern = '```(?<Language>powershell|bash|cmd)\s*\n(?<Command>[\s\S]*?)```'
            Priority = 7
            Confidence = 0.8
        }
        "INLINE_COMMAND" = @{
            Pattern = '`(?<Command>[^`\n]{2,})`(?:\s*(?<Description>[^.\n]+))?'
            Priority = 6
            Confidence = 0.7
        }
        "CONVERSATION_CONTINUATION" = @{
            Pattern = '(?:Please|Can you|Could you|Would you|Let me know|Tell me)\s+(?<Request>[^.?!]+)[.?!]'
            Priority = 5
            Confidence = 0.6
        }
        "ERROR_INDICATION" = @{
            Pattern = '(?:error|issue|problem|failed?|incorrect)\s*:?\s*(?<ErrorDescription>[^.\n]+)'
            Priority = 4
            Confidence = 0.75
        }
        "SUCCESS_INDICATION" = @{
            Pattern = '(?:success|working|completed?|fixed?|resolved?)\s*:?\s*(?<SuccessDescription>[^.\n]+)'
            Priority = 3
            Confidence = 0.8
        }
        "QUESTION_PATTERN" = @{
            Pattern = '(?<Question>[^.!]*\?)'
            Priority = 2
            Confidence = 0.5
        }
    }
    
    $actionableItems = @()
    $patternMatches = @()
    
    foreach ($patternName in $advancedPatterns.Keys) {
        $patternInfo = $advancedPatterns[$patternName]
        $matches = [regex]::Matches($Content, $patternInfo.Pattern, [System.Text.RegularExpressions.RegexOptions]::IgnoreCase -bor [System.Text.RegularExpressions.RegexOptions]::Multiline)
        
        foreach ($match in $matches) {
            $extractedData = @{}
            foreach ($groupName in $match.Groups.Keys) {
                if ($groupName -ne "0" -and $match.Groups[$groupName].Success) {
                    $extractedData[$groupName] = $match.Groups[$groupName].Value.Trim()
                }
            }
            
            $actionableItems += @{
                Type = $patternName
                ExtractedData = $extractedData
                FullMatch = $match.Value.Trim()
                Position = $match.Index
                Priority = $patternInfo.Priority
                Confidence = $patternInfo.Confidence
                Source = "Regex"
            }
        }
        
        if ($matches.Count -gt 0) {
            $patternMatches += @{
                Pattern = $patternName
                MatchCount = $matches.Count
                Confidence = $patternInfo.Confidence
            }
        }
    }
    
    # Sort by priority and confidence
    $actionableItems = $actionableItems | Sort-Object @{Expression={$_.Priority}; Descending=$true}, @{Expression={$_.Confidence}; Descending=$true}
    
    Write-DecisionEngineLog -Message "Regex analysis completed: $($actionableItems.Count) actionable items found" -Level "DEBUG"
    
    return @{
        ActionableItems = $actionableItems
        PatternMatches = $patternMatches
        AnalysisMethod = "Regex"
        Confidence = if ($actionableItems.Count -gt 0) { ($actionableItems | Measure-Object -Property Confidence -Average).Average } else { 0.0 }
    }
}

function Invoke-AIEnhancedAnalysis {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Content,
        
        [Parameter()]
        [hashtable]$Context = @{}
    )
    
    Write-DecisionEngineLog -Message "Performing AI-enhanced semantic analysis" -Level "DEBUG"
    
    # Simulate AI-enhanced analysis for now (placeholder for future AI integration)
    # In production, this would integrate with Azure OpenAI or similar service
    
    try {
        # Intent classification based on content patterns
        $intentClassification = Get-IntentClassification -Content $Content
        
        # Semantic context extraction
        $semanticContext = Get-SemanticContext -Content $Content -Context $Context
        
        # Enhanced action detection using semantic understanding
        $enhancedActions = Get-SemanticActions -Content $Content -Intent $intentClassification
        
        # Confidence scoring based on semantic coherence
        $confidenceScore = Calculate-SemanticConfidence -Content $Content -Intent $intentClassification -Actions $enhancedActions
        
        Write-DecisionEngineLog -Message "AI analysis confidence: $confidenceScore" -Level "DEBUG"
        
        return @{
            SemanticContext = $semanticContext
            IntentClassification = $intentClassification
            ConfidenceScore = $confidenceScore
            EnhancedActions = $enhancedActions
            AnalysisMethod = "AI-Enhanced"
        }
    }
    catch {
        Write-DecisionEngineLog -Message "Error in AI-enhanced analysis: $_" -Level "ERROR"
        return @{
            SemanticContext = @{}
            IntentClassification = "Unknown"
            ConfidenceScore = 0.1
            EnhancedActions = @()
            AnalysisMethod = "AI-Enhanced-Error"
        }
    }
}

function Get-IntentClassification {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Content
    )
    
    # Intent classification based on content analysis patterns
    $intentKeywords = @{
        "ActionRequired" = @("run", "execute", "test", "try", "implement", "apply", "fix")
        "InformationRequest" = @("what", "how", "why", "when", "where", "explain", "describe")
        "ContinueConversation" = @("next", "continue", "then", "after", "following", "step")
        "ProvideGuidance" = @("should", "recommend", "suggest", "consider", "might", "could")
        "ReportStatus" = @("completed", "done", "finished", "success", "working", "failed")
        "AskQuestion" = @("can you", "could you", "would you", "please", "help", "?")
    }
    
    $intentScores = @{}
    
    foreach ($intent in $intentKeywords.Keys) {
        $keywords = $intentKeywords[$intent]
        $matchCount = 0
        
        foreach ($keyword in $keywords) {
            if ($Content -match "\b$keyword\b") {
                $matchCount++
            }
        }
        
        $intentScores[$intent] = $matchCount / $keywords.Count
    }
    
    # Return highest scoring intent
    $topIntent = $intentScores.GetEnumerator() | Sort-Object Value -Descending | Select-Object -First 1
    
    if ($topIntent.Value -gt 0.1) {
        return $topIntent.Name
    } else {
        return "Unknown"
    }
}

function Get-SemanticContext {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Content,
        
        [Parameter()]
        [hashtable]$Context = @{}
    )
    
    # Extract semantic context elements
    $semanticContext = @{
        EntityTypes = @()
        TechnicalTerms = @()
        ActionWords = @()
        Sentiment = "Neutral"
        Complexity = "Medium"
        Domain = "General"
    }
    
    # Technical domain detection
    $domainKeywords = @{
        "Unity" = @("unity", "gameobject", "component", "scene", "prefab", "script")
        "PowerShell" = @("powershell", "cmdlet", "module", "function", "script", "pipeline")
        "Development" = @("code", "function", "class", "method", "variable", "compile")
        "Testing" = @("test", "assert", "validate", "verify", "check", "debug")
    }
    
    foreach ($domain in $domainKeywords.Keys) {
        $keywords = $domainKeywords[$domain]
        $matchCount = 0
        
        foreach ($keyword in $keywords) {
            if ($Content -match "\b$keyword\b") {
                $matchCount++
            }
        }
        
        if ($matchCount -gt 0) {
            $semanticContext.Domain = $domain
            break
        }
    }
    
    # Extract action words
    $actionPattern = '\b(run|execute|test|implement|create|update|fix|resolve|check|validate)\b'
    $actionMatches = [regex]::Matches($Content, $actionPattern, [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)
    $semanticContext.ActionWords = $actionMatches | ForEach-Object { $_.Value.ToLower() } | Sort-Object -Unique
    
    # Complexity assessment based on content length and technical terms
    if ($Content.Length -gt 1000 -or $semanticContext.ActionWords.Count -gt 5) {
        $semanticContext.Complexity = "High"
    } elseif ($Content.Length -lt 200 -and $semanticContext.ActionWords.Count -lt 2) {
        $semanticContext.Complexity = "Low"
    }
    
    return $semanticContext
}

function Get-SemanticActions {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Content,
        
        [Parameter(Mandatory = $true)]
        [string]$Intent
    )
    
    $semanticActions = @()
    
    # Intent-based action extraction
    switch ($Intent) {
        "ActionRequired" {
            $semanticActions += @{
                Type = "EXECUTE_ACTION"
                Confidence = 0.8
                Priority = 8
                SemanticSource = "Intent-ActionRequired"
            }
        }
        "InformationRequest" {
            $semanticActions += @{
                Type = "PROVIDE_INFORMATION"
                Confidence = 0.7
                Priority = 6
                SemanticSource = "Intent-InformationRequest"
            }
        }
        "ContinueConversation" {
            $semanticActions += @{
                Type = "CONTINUE_CONVERSATION"
                Confidence = 0.75
                Priority = 7
                SemanticSource = "Intent-ContinueConversation"
            }
        }
        "AskQuestion" {
            $semanticActions += @{
                Type = "ANSWER_QUESTION"
                Confidence = 0.7
                Priority = 6
                SemanticSource = "Intent-AskQuestion"
            }
        }
    }
    
    return $semanticActions
}

function Calculate-SemanticConfidence {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Content,
        
        [Parameter(Mandatory = $true)]
        [string]$Intent,
        
        [Parameter(Mandatory = $true)]
        [array]$Actions
    )
    
    # Base confidence from intent clarity
    $intentConfidence = switch ($Intent) {
        "ActionRequired" { 0.8 }
        "ProvideGuidance" { 0.75 }
        "ContinueConversation" { 0.7 }
        "InformationRequest" { 0.65 }
        "ReportStatus" { 0.6 }
        "AskQuestion" { 0.55 }
        default { 0.3 }
    }
    
    # Boost confidence based on content clarity
    $contentLength = $Content.Length
    $contentClarity = switch ($true) {
        ($contentLength -gt 500 -and $contentLength -lt 2000) { 0.1 }
        ($contentLength -gt 100 -and $contentLength -lt 500) { 0.05 }
        default { 0.0 }
    }
    
    # Action alignment boost
    $actionBoost = if ($Actions.Count -gt 0) { 0.1 } else { 0.0 }
    
    $finalConfidence = [Math]::Min(1.0, $intentConfidence + $contentClarity + $actionBoost)
    
    return $finalConfidence
}

function Merge-AnalysisResults {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [hashtable]$RegexAnalysis,
        
        [Parameter(Mandatory = $true)]
        [hashtable]$AIAnalysis
    )
    
    Write-DecisionEngineLog -Message "Merging regex and AI analysis results" -Level "DEBUG"
    
    # Combine actionable items with confidence weighting
    $mergedActions = @()
    
    # Add regex-based actions with original confidence
    foreach ($action in $RegexAnalysis.ActionableItems) {
        $mergedActions += $action
    }
    
    # Add AI-enhanced actions with adjusted confidence
    foreach ($action in $AIAnalysis.EnhancedActions) {
        $action.Confidence = $action.Confidence * $AIAnalysis.ConfidenceScore
        $mergedActions += $action
    }
    
    # Calculate overall confidence using weighted average
    $regexWeight = 0.7  # Higher weight for regex (more reliable)
    $aiWeight = 0.3     # Lower weight for AI (less reliable without full AI integration)
    
    $overallConfidence = ($RegexAnalysis.Confidence * $regexWeight) + ($AIAnalysis.ConfidenceScore * $aiWeight)
    
    # Sort merged actions by priority and confidence
    $mergedActions = $mergedActions | Sort-Object @{Expression={$_.Priority}; Descending=$true}, @{Expression={$_.Confidence}; Descending=$true}
    
    return @{
        ActionableItems = $mergedActions
        RegexConfidence = $RegexAnalysis.Confidence
        AIConfidence = $AIAnalysis.ConfidenceScore
        OverallConfidence = $overallConfidence
        IntentClassification = $AIAnalysis.IntentClassification
        SemanticContext = $AIAnalysis.SemanticContext
        MergedAnalysis = $true
    }
}

function Add-ContextualEnrichment {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [hashtable]$Analysis,
        
        [Parameter()]
        [hashtable]$Context = @{},
        
        [Parameter()]
        [hashtable]$Response = @{}
    )
    
    Write-DecisionEngineLog -Message "Adding contextual enrichment to analysis" -Level "DEBUG"
    
    # Add conversation context to buffer
    if ($script:ContextBuffer.Count -ge $script:DecisionEngineConfig.ContextWindowSize) {
        $script:ContextBuffer.Dequeue() | Out-Null
    }
    
    $contextEntry = @{
        Timestamp = Get-Date
        Response = $Response
        Analysis = $Analysis
        IntentClassification = $Analysis.IntentClassification
    }
    
    $script:ContextBuffer.Enqueue($contextEntry)
    
    # Enhance analysis with historical context
    $enrichedAnalysis = $Analysis.Clone()
    
    # Add conversation flow context
    $enrichedAnalysis.ConversationFlow = Get-ConversationFlowAnalysis
    
    # Adjust confidence based on conversation consistency
    $consistencyScore = Get-ConversationConsistency -CurrentAnalysis $Analysis
    $enrichedAnalysis.OverallConfidence = $enrichedAnalysis.OverallConfidence * $consistencyScore
    
    # Add temporal context
    $enrichedAnalysis.TemporalContext = @{
        ResponseAge = if ($Response.Timestamp) { (Get-Date) - $Response.Timestamp } else { New-TimeSpan }
        ConversationLength = $script:ContextBuffer.Count
        LastSimilarResponse = Get-LastSimilarResponse -Analysis $Analysis
    }
    
    Write-DecisionEngineLog -Message "Contextual enrichment completed. Final confidence: $($enrichedAnalysis.OverallConfidence)" -Level "DEBUG"
    
    return $enrichedAnalysis
}

function Get-ConversationFlowAnalysis {
    [CmdletBinding()]
    param()
    
    $flowAnalysis = @{
        Direction = "Unknown"
        Momentum = "Neutral"
        Phase = "Middle"
        Transitions = @()
    }
    
    if ($script:ContextBuffer.Count -gt 1) {
        $recentEntries = @()
        foreach ($entry in $script:ContextBuffer) {
            $recentEntries += $entry
        }
        
        # Analyze recent conversation direction
        $recentIntents = $recentEntries | ForEach-Object { $_.IntentClassification }
        $uniqueIntents = $recentIntents | Sort-Object -Unique
        
        if ($uniqueIntents.Count -eq 1) {
            $flowAnalysis.Direction = "Focused"
            $flowAnalysis.Momentum = "Steady"
        } elseif ($uniqueIntents.Count -gt 3) {
            $flowAnalysis.Direction = "Exploratory"
            $flowAnalysis.Momentum = "Dynamic"
        } else {
            $flowAnalysis.Direction = "Progressive"
            $flowAnalysis.Momentum = "Structured"
        }
        
        # Determine conversation phase
        if ($script:ContextBuffer.Count -lt 3) {
            $flowAnalysis.Phase = "Beginning"
        } elseif ($recentIntents[-1] -in @("ReportStatus", "ContinueConversation")) {
            $flowAnalysis.Phase = "Concluding"
        } else {
            $flowAnalysis.Phase = "Active"
        }
    }
    
    return $flowAnalysis
}

function Get-ConversationConsistency {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [hashtable]$CurrentAnalysis
    )
    
    if ($script:ContextBuffer.Count -lt 2) {
        return 1.0  # No history to compare against
    }
    
    $recentAnalyses = @()
    foreach ($entry in $script:ContextBuffer) {
        $recentAnalyses += $entry.Analysis
    }
    
    # Calculate consistency score based on intent alignment
    $currentIntent = $CurrentAnalysis.IntentClassification
    $recentIntents = $recentAnalyses | ForEach-Object { $_.IntentClassification } | Where-Object { $_ -ne $null }
    
    if ($recentIntents.Count -eq 0) {
        return 1.0
    }
    
    $matchingIntents = $recentIntents | Where-Object { $_ -eq $currentIntent }
    $consistencyRatio = $matchingIntents.Count / $recentIntents.Count
    
    # Boost consistency for logical conversation flow
    $flowBonus = switch ($currentIntent) {
        "ActionRequired" { if ($recentIntents[-1] -eq "ProvideGuidance") { 0.2 } else { 0.0 } }
        "ReportStatus" { if ($recentIntents[-1] -eq "ActionRequired") { 0.15 } else { 0.0 } }
        "ContinueConversation" { 0.1 }
        default { 0.0 }
    }
    
    $finalConsistency = [Math]::Min(1.2, $consistencyRatio + $flowBonus)  # Allow slight boost above 1.0
    
    return $finalConsistency
}

function Get-LastSimilarResponse {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [hashtable]$Analysis
    )
    
    $currentIntent = $Analysis.IntentClassification
    
    foreach ($entry in $script:ContextBuffer) {
        if ($entry.Analysis.IntentClassification -eq $currentIntent) {
            return @{
                Timestamp = $entry.Timestamp
                TimeDifference = (Get-Date) - $entry.Timestamp
                Analysis = $entry.Analysis
            }
        }
    }
    
    return $null
}

#endregion

#region Decision Making Engine

function Invoke-AutonomousDecision {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [hashtable]$Analysis,
        
        [Parameter()]
        [hashtable]$Context = @{}
    )
    
    Write-DecisionEngineLog -Message "Starting autonomous decision making process" -Level "INFO"
    
    $decisionId = [guid]::NewGuid().ToString()
    
    try {
        # Add decision to active tracking
        $script:ActiveDecisions[$decisionId] = @{
            StartTime = Get-Date
            Analysis = $Analysis
            Context = $Context
            Status = "Processing"
        }
        
        # Decision tree based on research-validated autonomous agent patterns
        $decisionResult = Invoke-DecisionTree -Analysis $Analysis -Context $Context -DecisionId $decisionId
        
        # Apply safety and confidence validation
        $validatedDecision = Invoke-DecisionValidation -Decision $decisionResult -Analysis $Analysis
        
        # Record decision in history for learning
        if ($script:DecisionEngineConfig.LearningEnabled) {
            Add-DecisionToHistory -DecisionId $decisionId -Decision $validatedDecision -Analysis $Analysis
        }
        
        # Update active decision status
        $script:ActiveDecisions[$decisionId].Status = "Completed"
        $script:ActiveDecisions[$decisionId].Result = $validatedDecision
        $script:ActiveDecisions[$decisionId].CompletionTime = Get-Date
        
        Write-DecisionEngineLog -Message "Autonomous decision completed: $($validatedDecision.Action) (Confidence: $($validatedDecision.Confidence))" -Level "INFO"
        
        return $validatedDecision
    }
    catch {
        Write-DecisionEngineLog -Message "Error in autonomous decision making: $_" -Level "ERROR"
        
        # Update active decision with error status
        if ($script:ActiveDecisions.ContainsKey($decisionId)) {
            $script:ActiveDecisions[$decisionId].Status = "Error"
            $script:ActiveDecisions[$decisionId].Error = $_.Exception.Message
        }
        
        return @{
            Success = $false
            Action = "NO_ACTION"
            Confidence = 0.0
            Reason = "Decision engine error: $_"
            DecisionId = $decisionId
        }
    }
}

function Invoke-DecisionTree {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [hashtable]$Analysis,
        
        [Parameter()]
        [hashtable]$Context = @{},
        
        [Parameter(Mandatory = $true)]
        [string]$DecisionId
    )
    
    Write-DecisionEngineLog -Message "Traversing decision tree for analysis" -Level "DEBUG"
    
    # Primary decision based on highest confidence actionable item
    $primaryAction = $Analysis.ActionableItems | Sort-Object @{Expression={$_.Priority}; Descending=$true}, @{Expression={$_.Confidence}; Descending=$true} | Select-Object -First 1
    
    if (-not $primaryAction) {
        return @{
            Success = $true
            Action = "CONTINUE_MONITORING"
            Confidence = 0.5
            Reason = "No actionable items detected"
            DecisionId = $DecisionId
        }
    }
    
    # Decision tree branches based on action type and confidence
    $decision = switch ($primaryAction.Type) {
        "RECOMMENDED" {
            if ($primaryAction.Confidence -ge $script:DecisionEngineConfig.ConfidenceThreshold) {
                @{
                    Success = $true
                    Action = "EXECUTE_RECOMMENDATION"
                    Confidence = $primaryAction.Confidence
                    Reason = "High-confidence recommendation detected"
                    RecommendationData = $primaryAction.ExtractedData
                    DecisionId = $DecisionId
                }
            } else {
                @{
                    Success = $true
                    Action = "REQUEST_CLARIFICATION"
                    Confidence = $primaryAction.Confidence
                    Reason = "Low-confidence recommendation requires clarification"
                    RecommendationData = $primaryAction.ExtractedData
                    DecisionId = $DecisionId
                }
            }
        }
        
        "TEST_REQUEST" {
            @{
                Success = $true
                Action = "EXECUTE_TEST"
                Confidence = $primaryAction.Confidence
                Reason = "Test request identified"
                TestData = $primaryAction.ExtractedData
                DecisionId = $DecisionId
            }
        }
        
        "EXECUTION_COMMAND" {
            if ($primaryAction.Confidence -ge ($script:DecisionEngineConfig.ConfidenceThreshold + 0.1)) {
                @{
                    Success = $true
                    Action = "EXECUTE_COMMAND"
                    Confidence = $primaryAction.Confidence
                    Reason = "High-confidence command execution request"
                    CommandData = $primaryAction.ExtractedData
                    DecisionId = $DecisionId
                }
            } else {
                @{
                    Success = $true
                    Action = "VALIDATE_COMMAND"
                    Confidence = $primaryAction.Confidence
                    Reason = "Command requires validation before execution"
                    CommandData = $primaryAction.ExtractedData
                    DecisionId = $DecisionId
                }
            }
        }
        
        "CONVERSATION_CONTINUATION" {
            @{
                Success = $true
                Action = "CONTINUE_CONVERSATION"
                Confidence = $primaryAction.Confidence
                Reason = "Conversation continuation detected"
                ContinuationData = $primaryAction.ExtractedData
                DecisionId = $DecisionId
            }
        }
        
        "ERROR_INDICATION" {
            @{
                Success = $true
                Action = "ANALYZE_ERROR"
                Confidence = $primaryAction.Confidence
                Reason = "Error indication requires analysis"
                ErrorData = $primaryAction.ExtractedData
                DecisionId = $DecisionId
            }
        }
        
        "SUCCESS_INDICATION" {
            @{
                Success = $true
                Action = "CONTINUE_WORKFLOW"
                Confidence = $primaryAction.Confidence
                Reason = "Success indication - continue workflow"
                SuccessData = $primaryAction.ExtractedData
                DecisionId = $DecisionId
            }
        }
        
        "QUESTION_PATTERN" {
            @{
                Success = $true
                Action = "GENERATE_RESPONSE"
                Confidence = $primaryAction.Confidence
                Reason = "Question pattern detected - generate response"
                QuestionData = $primaryAction.ExtractedData
                DecisionId = $DecisionId
            }
        }
        
        default {
            @{
                Success = $true
                Action = "CONTINUE_MONITORING"
                Confidence = 0.3
                Reason = "Unknown action type: $($primaryAction.Type)"
                ActionData = $primaryAction
                DecisionId = $DecisionId
            }
        }
    }
    
    # Apply contextual adjustments
    $decision = Apply-ContextualAdjustments -Decision $decision -Analysis $Analysis -Context $Context
    
    Write-DecisionEngineLog -Message "Decision tree result: $($decision.Action) (Confidence: $($decision.Confidence))" -Level "DEBUG"
    
    return $decision
}

function Apply-ContextualAdjustments {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [hashtable]$Decision,
        
        [Parameter(Mandatory = $true)]
        [hashtable]$Analysis,
        
        [Parameter()]
        [hashtable]$Context = @{}
    )
    
    # Apply conversation flow adjustments
    if ($Analysis.ConversationFlow -and $Analysis.ConversationFlow.Phase -eq "Concluding") {
        if ($Decision.Action -eq "CONTINUE_CONVERSATION") {
            $Decision.Action = "CONCLUDE_CONVERSATION"
            $Decision.Reason += " (Conversation in concluding phase)"
        }
    }
    
    # Apply temporal adjustments
    if ($Analysis.TemporalContext -and $Analysis.TemporalContext.ResponseAge.TotalMinutes -gt 10) {
        $Decision.Confidence = $Decision.Confidence * 0.9  # Reduce confidence for old responses
        $Decision.Reason += " (Adjusted for response age)"
    }
    
    # Apply domain-specific adjustments
    if ($Analysis.SemanticContext -and $Analysis.SemanticContext.Domain -eq "Unity") {
        if ($Decision.Action -eq "EXECUTE_COMMAND") {
            $Decision.Action = "VALIDATE_UNITY_COMMAND"
            $Decision.Reason += " (Unity domain safety check)"
        }
    }
    
    return $Decision
}

function Invoke-DecisionValidation {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [hashtable]$Decision,
        
        [Parameter(Mandatory = $true)]
        [hashtable]$Analysis
    )
    
    Write-DecisionEngineLog -Message "Validating decision: $($Decision.Action)" -Level "DEBUG"
    
    $validationResult = $Decision.Clone()
    
    # Safety validation - high-risk actions require higher confidence
    $highRiskActions = @("EXECUTE_COMMAND", "EXECUTE_RECOMMENDATION", "VALIDATE_UNITY_COMMAND")
    if ($Decision.Action -in $highRiskActions -and $Decision.Confidence -lt 0.8) {
        $validationResult.Action = "REQUEST_APPROVAL"
        $validationResult.Reason += " (Safety validation: High-risk action requires approval)"
        $validationResult.OriginalAction = $Decision.Action
    }
    
    # Confidence threshold validation
    if ($Decision.Confidence -lt 0.3) {
        $validationResult.Action = "NO_ACTION"
        $validationResult.Reason += " (Below minimum confidence threshold)"
    }
    
    # Integration availability validation
    $requiredIntegrations = @{
        "EXECUTE_TEST" = "Unity-TestAutomation"
        "EXECUTE_COMMAND" = "SafeCommandExecution"
        "GENERATE_RESPONSE" = "IntelligentPromptEngine"
    }
    
    if ($requiredIntegrations.ContainsKey($Decision.Action)) {
        $requiredModule = $requiredIntegrations[$Decision.Action]
        if (-not (Test-RequiredModule -ModuleName $requiredModule)) {
            $validationResult.Action = "DEFER_ACTION"
            $validationResult.Reason += " (Required module not available: $requiredModule)"
        }
    }
    
    Write-DecisionEngineLog -Message "Decision validation completed: $($validationResult.Action)" -Level "DEBUG"
    
    return $validationResult
}

function Add-DecisionToHistory {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$DecisionId,
        
        [Parameter(Mandatory = $true)]
        [hashtable]$Decision,
        
        [Parameter(Mandatory = $true)]
        [hashtable]$Analysis
    )
    
    $historyEntry = @{
        DecisionId = $DecisionId
        Timestamp = Get-Date
        Decision = $Decision
        Analysis = $Analysis
        Success = $Decision.Success
        Confidence = $Decision.Confidence
        Action = $Decision.Action
    }
    
    $script:DecisionHistory.Add($historyEntry)
    
    # Keep history size manageable
    if ($script:DecisionHistory.Count -gt 100) {
        $script:DecisionHistory.RemoveAt(0)
    }
    
    Write-DecisionEngineLog -Message "Decision added to history: $DecisionId" -Level "DEBUG"
}

#endregion

#region Integration Functions

function Connect-IntelligentPromptEngine {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [hashtable]$Decision,
        
        [Parameter()]
        [hashtable]$Context = @{}
    )
    
    Write-DecisionEngineLog -Message "Connecting to IntelligentPromptEngine for decision: $($Decision.Action)" -Level "DEBUG"
    
    if (-not (Test-RequiredModule -ModuleName "IntelligentPromptEngine")) {
        Write-DecisionEngineLog -Message "IntelligentPromptEngine not available" -Level "WARN"
        return $null
    }
    
    try {
        # This will integrate with the existing IntelligentPromptEngine module
        # For now, placeholder implementation
        $promptRequest = @{
            DecisionType = $Decision.Action
            Context = $Context
            Confidence = $Decision.Confidence
            Timestamp = Get-Date
        }
        
        Write-DecisionEngineLog -Message "Prompt generation request prepared" -Level "DEBUG"
        return $promptRequest
    }
    catch {
        Write-DecisionEngineLog -Message "Error connecting to IntelligentPromptEngine: $_" -Level "ERROR"
        return $null
    }
}

function Connect-ConversationManager {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [hashtable]$Decision,
        
        [Parameter()]
        [hashtable]$Analysis
    )
    
    Write-DecisionEngineLog -Message "Updating conversation state based on decision" -Level "DEBUG"
    
    if (-not (Test-RequiredModule -ModuleName "ConversationStateManager")) {
        Write-DecisionEngineLog -Message "ConversationStateManager not available" -Level "WARN"
        return $false
    }
    
    try {
        # Integration with existing ConversationStateManager
        $stateUpdate = @{
            Decision = $Decision
            Analysis = $Analysis
            Timestamp = Get-Date
        }
        
        Write-DecisionEngineLog -Message "Conversation state update prepared" -Level "DEBUG"
        return $true
    }
    catch {
        Write-DecisionEngineLog -Message "Error connecting to ConversationStateManager: $_" -Level "ERROR"
        return $false
    }
}

#endregion

#region Status and Management Functions

function Get-DecisionEngineStatus {
    [CmdletBinding()]
    param()
    
    return @{
        Configuration = $script:DecisionEngineConfig
        ActiveDecisions = $script:ActiveDecisions.Count
        DecisionHistoryCount = $script:DecisionHistory.Count
        ContextBufferSize = $script:ContextBuffer.Count
        ModuleIntegrations = @{
            IntelligentPromptEngine = (Test-RequiredModule -ModuleName "IntelligentPromptEngine")
            ConversationStateManager = (Test-RequiredModule -ModuleName "ConversationStateManager")
            ResponseMonitor = (Test-RequiredModule -ModuleName "Unity-Claude-ResponseMonitor")
        }
        LastDecisionTime = if ($script:DecisionHistory.Count -gt 0) { $script:DecisionHistory[-1].Timestamp } else { $null }
    }
}

function Get-DecisionHistory {
    [CmdletBinding()]
    param(
        [Parameter()]
        [int]$Last = 10
    )
    
    $historyCount = [Math]::Min($Last, $script:DecisionHistory.Count)
    $startIndex = [Math]::Max(0, $script:DecisionHistory.Count - $historyCount)
    
    $recentHistory = @()
    for ($i = $startIndex; $i -lt $script:DecisionHistory.Count; $i++) {
        $recentHistory += $script:DecisionHistory[$i]
    }
    
    return $recentHistory
}

function Clear-DecisionHistory {
    [CmdletBinding()]
    param()
    
    $clearedCount = $script:DecisionHistory.Count
    $script:DecisionHistory.Clear()
    $script:ContextBuffer.Clear()
    $script:ActiveDecisions.Clear()
    
    Write-DecisionEngineLog -Message "Cleared $clearedCount decision history entries" -Level "INFO"
    
    return @{
        ClearedEntries = $clearedCount
        Timestamp = Get-Date
    }
}

function Test-DecisionEngineIntegration {
    [CmdletBinding()]
    param()
    
    Write-DecisionEngineLog -Message "Testing Decision Engine integration" -Level "INFO"
    
    $testResults = @{
        HybridAnalysis = $false
        DecisionTree = $false
        ContextManagement = $false
        ModuleIntegrations = $false
        OverallStatus = "FAIL"
    }
    
    try {
        # Test hybrid analysis capability
        $testContent = "RECOMMENDED: TEST - Run the test suite to validate the implementation"
        $testResponse = @{ Content = $testContent; Timestamp = Get-Date }
        $analysisResult = Invoke-HybridResponseAnalysis -Response $testResponse
        
        if ($analysisResult.ActionableItems.Count -gt 0) {
            $testResults.HybridAnalysis = $true
            Write-DecisionEngineLog -Message "Hybrid analysis test: PASS" -Level "DEBUG"
        }
        
        # Test decision tree
        if ($analysisResult.ActionableItems.Count -gt 0) {
            $decisionResult = Invoke-AutonomousDecision -Analysis $analysisResult
            if ($decisionResult.Success) {
                $testResults.DecisionTree = $true
                Write-DecisionEngineLog -Message "Decision tree test: PASS" -Level "DEBUG"
            }
        }
        
        # Test context management
        if ($script:ContextBuffer.Count -gt 0) {
            $testResults.ContextManagement = $true
            Write-DecisionEngineLog -Message "Context management test: PASS" -Level "DEBUG"
        }
        
        # Test module integrations
        $integrationCount = 0
        $requiredModules = @('IntelligentPromptEngine', 'ConversationStateManager', 'Unity-Claude-ResponseMonitor')
        foreach ($module in $requiredModules) {
            if (Test-RequiredModule -ModuleName $module) {
                $integrationCount++
            }
        }
        
        if ($integrationCount -ge 2) {
            $testResults.ModuleIntegrations = $true
            Write-DecisionEngineLog -Message "Module integrations test: PASS ($integrationCount/3)" -Level "DEBUG"
        }
        
        # Overall status
        $passCount = ($testResults.GetEnumerator() | Where-Object { $_.Key -ne "OverallStatus" -and $_.Value -eq $true }).Count
        if ($passCount -ge 3) {
            $testResults.OverallStatus = "PASS"
            Write-DecisionEngineLog -Message "Decision Engine integration test: PASS ($passCount/4 tests passed)" -Level "INFO"
        } else {
            Write-DecisionEngineLog -Message "Decision Engine integration test: FAIL ($passCount/4 tests passed)" -Level "WARN"
        }
        
        return $testResults
    }
    catch {
        Write-DecisionEngineLog -Message "Error during integration test: $_" -Level "ERROR"
        $testResults.OverallStatus = "ERROR"
        return $testResults
    }
}

#endregion

# Module initialization
Write-DecisionEngineLog -Message "Unity-Claude-DecisionEngine module loaded successfully" -Level "INFO"

# Export module members (functions are exported via manifest)
# SIG # Begin signature block
# MIIFzgYJKoZIhvcNAQcCoIIFvzCCBbsCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCC5/Vqpt/LgDS5m
# xIw4jeZ6EQnIhM2oQfYkGp3RHD/+BaCCAzAwggMsMIICFKADAgECAhB1HRbZIqgr
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
# MAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIP3vNADBIHR3c7Y8JAyTMykl
# LCZLzRMgzJDsAD1sKUumMA0GCSqGSIb3DQEBAQUABIIBAEpnNKfMn16m80hacOQc
# +B+hxtPQnvPx2sBE9mmkY1seD14lGSC8zp83K03hHD/ViQZB1U769m7rJngqvKAR
# OgCkq5XAtBvd+rx3vPodQ10uu5EDJbKX9I8a9vmUOwDHG2FaRt40E0LcT8XC1j4L
# IvLOqujxdiABM1aGgcvDf4cNKsnt6rMA7cvy97WjtZdQes3DmXq1uPoScckIiAQR
# vPUXqQOm789+aEKbVUTdK3kjjNRhwGheYTST29eZLYVGptWXKyJovyP0p2Ub5Ax+
# JGaqfhHpnvD64a+FoI4Z1sPpjV6GhdxDaiVRIIzVWljtiobRMtkHJulmPq2box3q
# +3I=
# SIG # End signature block
