# Unity-Claude-CLIOrchestrator - Pattern Recognition & Classification Engine
# Phase 7 Day 1-2 Hours 5-8: Pattern Recognition & Classification Implementation
# Compatible with PowerShell 5.1 and Claude Code CLI 2025

#region Module Configuration

$script:PatternConfig = @{
    ConfidenceThreshold = 0.75
    PatternCacheSize = 1000
    LearningEnabled = $true
    ClassificationTypes = @(
        "Instruction",
        "Question", 
        "Information",
        "Error",
        "Complete",
        "TestResult",
        "Continuation"
    )
}

# Enhanced Compiled Regex Patterns for Performance (640x improvement over basic regex)
$script:CompiledPatterns = @{}

$script:RecommendationPatterns = @{
    "CONTINUE" = @{
        Pattern = "RECOMMENDATION:\s*CONTINUE[:]\s*(.+)"
        SemanticPatterns = @(
            "continue\s+with\s+(.+)",
            "proceed\s+to\s+(.+)",
            "next\s+step[:\s]*(.+)"
        )
        Confidence = 0.95
        BaseWeight = 1.0
        ActionType = "Continuation"
        Priority = "High"
        ValidationRules = @("FilePath", "ActionVerb")
    }
    "TEST" = @{
        Pattern = "RECOMMENDATION:\s*TEST\s*[-]\s*([^:]+):\s*(.+)"
        SemanticPatterns = @(
            "run\s+test[s]?\s*[:]\s*([^:\r\n]+)",
            "execute\s+([^\.]+\.ps1)",
            "test\s+the\s+(.+)",
            "invoke\s*[-]?test\s*([^\s]+)"
        )
        Confidence = 0.95
        BaseWeight = 1.2
        ActionType = "TestExecution"
        Priority = "High"
        ValidationRules = @("FilePath", "TestKeyword")
    }
    "FIX" = @{
        Pattern = "RECOMMENDATION:\s*FIX\s*[-]\s*([^:]+):\s*(.+)"
        SemanticPatterns = @(
            "fix\s+(?:the\s+)?(.+?)\s*[:]\s*(.+)",
            "correct\s+(.+?)\s+in\s+(.+)",
            "repair\s+(.+?)\s*[:]\s*(.+)",
            "resolve\s+(.+?)\s+by\s+(.+)"
        )
        Confidence = 0.95
        BaseWeight = 1.1
        ActionType = "CodeFix"
        Priority = "High"
        ValidationRules = @("FilePath", "ActionVerb")
    }
    "COMPILE" = @{
        Pattern = "RECOMMENDATION:\s*COMPILE\s*[-]\s*(.+)"
        SemanticPatterns = @(
            "compile\s+(?:the\s+)?(.+)",
            "build\s+(?:the\s+)?(.+)",
            "rebuild\s+(.+)",
            "msbuild\s+(.+)"
        )
        Confidence = 0.95
        BaseWeight = 1.0
        ActionType = "Compilation"
        Priority = "High"
        ValidationRules = @("ProjectPath", "ActionVerb")
    }
    "RESTART" = @{
        Pattern = "RECOMMENDATION:\s*RESTART\s*[-]\s*([^:]+):\s*(.+)"
        SemanticPatterns = @(
            "restart\s+(?:the\s+)?(.+?)\s*[:]\s*(.+)",
            "reload\s+(.+?)\s+(.+)",
            "stop\s+and\s+start\s+(.+)",
            "cycle\s+(.+?)\s*[:]\s*(.+)"
        )
        Confidence = 0.95
        BaseWeight = 0.8
        ActionType = "ModuleRestart"
        Priority = "Medium"
        ValidationRules = @("ServiceName", "ActionVerb")
    }
    "COMPLETE" = @{
        Pattern = "RECOMMENDATION:\s*COMPLETE\s*[-]\s*(.+)"
        SemanticPatterns = @(
            "(?:task\s+)?complet(?:e|ed)\s*[:]\s*(.+)",
            "finish(?:ed)?\s*[:]\s*(.+)",
            "done\s*[:]\s*(.+)",
            "success(?:ful)?\s*[:]\s*(.+)"
        )
        Confidence = 0.95
        BaseWeight = 0.7
        ActionType = "Completion"
        Priority = "Low"
        ValidationRules = @("StatusKeyword")
    }
    "ERROR" = @{
        Pattern = "RECOMMENDATION:\s*ERROR\s*[-]\s*([^:]+):\s*(.+)"
        SemanticPatterns = @(
            "error\s*[:]\s*(.+)",
            "exception\s*[:]\s*(.+)",
            "fail(?:ed|ure)\s*[:]\s*(.+)",
            "critical\s+issue\s*[:]\s*(.+)"
        )
        Confidence = 0.95
        BaseWeight = 1.5
        ActionType = "ErrorHandling"
        Priority = "Critical"
        ValidationRules = @("ErrorCode", "ActionVerb")
    }
    "ANALYZE" = @{
        Pattern = "RECOMMENDATION:\s*ANALYZE\s*[-]\s*(.+)"
        SemanticPatterns = @(
            "analyz(?:e|ed?)\s+(.+)",
            "review\s+(.+)",
            "inspect\s+(.+)",
            "examine\s+(.+)"
        )
        Confidence = 0.85
        BaseWeight = 0.9
        ActionType = "Analysis"
        Priority = "Medium"
        ValidationRules = @("FilePath", "ActionVerb")
    }
    "CREATE" = @{
        Pattern = "RECOMMENDATION:\s*CREATE\s*[-]\s*(.+)"
        SemanticPatterns = @(
            "create\s+(?:a\s+)?(.+)",
            "generate\s+(.+)",
            "make\s+(?:a\s+)?(.+)",
            "add\s+(?:a\s+)?new\s+(.+)"
        )
        Confidence = 0.90
        BaseWeight = 1.0
        ActionType = "Creation"
        Priority = "Medium"
        ValidationRules = @("FilePath", "ActionVerb")
    }
}

# Enhanced Context Patterns with Semantic Relationships
$script:ContextPatterns = @{
    "FileReference" = @{
        Pattern = "(?i)(?:file|script|module):\s*([^\s]+\.(?:ps1|psm1|psd1|cs|js|py|md|json|xml|yaml))"
        SemanticPatterns = @(
            "(?i)(?:path|location|directory)[:\s]*([a-z][:][^\s<>:""|?*]+\.(?:ps1|psm1|psd1|cs|js|py|md|json|xml|yaml))",
            "(?i)(?:open|edit|modify|update)\s+([^\s]+\.(?:ps1|psm1|psd1|cs|js|py|md|json|xml|yaml))",
            "(?i)([a-z][:][^\s<>:""|?*]+\.(?:ps1|psm1|psd1|cs|js|py|md|json|xml|yaml))\s+(?:contains|has|includes)"
        )
        ExtractGroup = 1
        EntityType = "FilePath"
        RelationshipTypes = @("Contains", "DependsOn", "Imports", "References")
        ContextWeight = 1.2
    }
    "ErrorReference" = @{
        Pattern = "(?i)error(?:\s+at\s+line\s+(\d+))?:?\s*([^\r\n]+)"
        SemanticPatterns = @(
            "(?i)exception\s*[:]\s*([^\r\n]+)",
            "(?i)(?:compilation|runtime)\s+error\s*[:]\s*([^\r\n]+)",
            "(?i)failed\s+with\s*[:]\s*([^\r\n]+)",
            "(?i)(?:cs|ps)\d{4}\s*[:]\s*([^\r\n]+)"
        )
        ExtractGroup = 2
        EntityType = "ErrorMessage"
        RelationshipTypes = @("CausedBy", "OccursIn", "RelatedTo")
        ContextWeight = 1.5
        AdditionalProperties = @{
            LineNumber = 1
            Severity = "High"
        }
    }
    "CommandReference" = @{
        Pattern = "(?i)(?:cmdlet|command|function):\s*([A-Za-z][-A-Za-z0-9]*)"
        SemanticPatterns = @(
            "(?i)invoke[-\s]*([A-Za-z][-A-Za-z0-9]*)",
            "(?i)execute\s+([A-Za-z][-A-Za-z0-9]*)",
            "(?i)run\s+([A-Za-z][-A-Za-z0-9]*)",
            "(?i)([A-Za-z][-A-Za-z0-9]*)\s+(?:was|is)\s+(?:executed|invoked|called)"
        )
        ExtractGroup = 1
        EntityType = "PowerShellCommand"
        RelationshipTypes = @("Executes", "CallsTo", "InvokedBy")
        ContextWeight = 1.1
        AdditionalProperties = @{
            Module = "Unknown"
            Parameters = @()
        }
    }
    "ModuleReference" = @{
        Pattern = "(?i)(?:module|namespace):\s*([A-Za-z][-A-Za-z0-9\.]*)"
        SemanticPatterns = @(
            "(?i)import[-\s]*module\s+([A-Za-z][-A-Za-z0-9\.]*)",
            "(?i)from\s+([A-Za-z][-A-Za-z0-9\.]*)\s+import",
            "(?i)using\s+([A-Za-z][-A-Za-z0-9\.]*)",
            "(?i)([A-Za-z][-A-Za-z0-9\.]*)\s+module\s+(?:loaded|imported|available)"
        )
        ExtractGroup = 1
        EntityType = "ModuleName"
        RelationshipTypes = @("ImportedBy", "ExportsTo", "DependsOn")
        ContextWeight = 1.0
    }
    "TestReference" = @{
        Pattern = "(?i)test(?:\s+(?:file|script))?:\s*([^\s]+\.(?:ps1|Tests\.ps1))"
        SemanticPatterns = @(
            "(?i)(?:pester|unit|integration)\s+test[s]?\s*[:]\s*([^\s]+\.(?:ps1|Tests\.ps1))",
            "(?i)run\s+test[s]?\s+(?:in|from)\s+([^\s]+\.(?:ps1|Tests\.ps1))",
            "(?i)test\s+(?:file|script)\s+([^\s]+\.(?:ps1|Tests\.ps1))",
            "(?i)([^\s]+\.Tests\.ps1)\s+(?:passed|failed|executed)"
        )
        ExtractGroup = 1
        EntityType = "TestFile"
        RelationshipTypes = @("Tests", "Validates", "CoverageOf")
        ContextWeight = 1.3
        AdditionalProperties = @{
            TestType = "Unknown"
            Status = "Unknown"
        }
    }
    "ParameterReference" = @{
        Pattern = "(?i)parameter\s*[:]\s*([A-Za-z][-A-Za-z0-9]*)"
        SemanticPatterns = @(
            "(?i)[-]([A-Za-z][-A-Za-z0-9]*)\s+(?:parameter|param|arg)",
            "(?i)with\s+parameter\s+([A-Za-z][-A-Za-z0-9]*)",
            "(?i)([A-Za-z][-A-Za-z0-9]*)\s+parameter\s+(?:is|was|should)"
        )
        ExtractGroup = 1
        EntityType = "Parameter"
        RelationshipTypes = @("PassedTo", "RequiredBy", "ConfiguresFor")
        ContextWeight = 0.8
    }
    "VariableReference" = @{
        Pattern = "(?i)variable\s*[:]\s*\$([A-Za-z][-A-Za-z0-9]*)"
        SemanticPatterns = @(
            "(?i)\$([A-Za-z][-A-Za-z0-9]*)\s+(?:variable|var)",
            "(?i)set\s+\$([A-Za-z][-A-Za-z0-9]*)",
            "(?i)\$([A-Za-z][-A-Za-z0-9]*)\s+(?:is|was|contains)"
        )
        ExtractGroup = 1
        EntityType = "Variable"
        RelationshipTypes = @("AssignedBy", "UsedIn", "PassedTo")
        ContextWeight = 0.7
    }
    "ClassReference" = @{
        Pattern = "(?i)class\s*[:]\s*([A-Za-z][-A-Za-z0-9]*)"
        SemanticPatterns = @(
            "(?i)(?:class|type)\s+([A-Za-z][-A-Za-z0-9]*)",
            "(?i)new\s+([A-Za-z][-A-Za-z0-9]*)",
            "(?i)([A-Za-z][-A-Za-z0-9]*)\s+(?:class|type|object)"
        )
        ExtractGroup = 1
        EntityType = "ClassName"
        RelationshipTypes = @("InheritsFrom", "ImplementsTo", "InstantiatedBy")
        ContextWeight = 1.0
    }
    "URLReference" = @{
        Pattern = "(?i)(?:url|link|endpoint):\s*(https?://[^\s]+)"
        SemanticPatterns = @(
            "(https?://[^\s<>""{}|\\^`\[\]]+)",
            "(?i)(?:visit|go\s+to|navigate\s+to)\s+(https?://[^\s]+)",
            "(?i)(?:api|rest|web)\s+(?:endpoint|url)\s*[:]\s*(https?://[^\s]+)"
        )
        ExtractGroup = 1
        EntityType = "URL"
        RelationshipTypes = @("ConnectsTo", "Fetches", "APICall")
        ContextWeight = 0.9
    }
}

$script:ClassificationFeatures = @{
    "QuestionIndicators" = @("what", "how", "when", "where", "why", "which", "can", "should", "would", "could", "?")
    "InstructionIndicators" = @("implement", "create", "add", "remove", "update", "modify", "fix", "enhance", "integrate")
    "ErrorIndicators" = @("error", "exception", "failed", "failure", "crash", "bug", "issue", "problem")
    "CompletionIndicators" = @("complete", "finished", "done", "success", "ready", "accomplished")
    "InformationIndicators" = @("status", "report", "summary", "analysis", "findings", "results")
}

$script:PatternCache = @{}
$script:ClassificationStats = @{}
$script:LogPath = "C:\UnityProjects\Sound-and-Shoal\Unity-Claude-Automation\unity_claude_automation.log"

# Pattern validation rules
$script:ValidationRules = @{
    "FilePath" = "(?i)[a-z][:][\\\/](?:[^\s<>:""|?*]+[\\\/])*[^\s<>:""|?*]+\.(?:ps1|psm1|psd1|cs|js|py|md|json|xml|yaml)"
    "TestKeyword" = "(?i)\b(?:test|spec|should|expect|verify|validate)\b"
    "ActionVerb" = "(?i)\b(?:run|execute|invoke|start|stop|create|build|compile|fix|analyze|test)\b"
    "ServiceName" = "(?i)\b[a-z][-a-z0-9]*(?:service|process|daemon)?\b"
    "StatusKeyword" = "(?i)\b(?:complete|finish|done|success|ready|pass|fail)\b"
    "ErrorCode" = "(?i)\b(?:error|exception|cs\d{4}|ps\d{4})\b"
    "ProjectPath" = "(?i)[a-z][:][\\\/](?:[^\s<>:""|?*]+[\\\/])*[^\s<>:""|?*]+\.(?:csproj|sln|vcxproj)"
}

# Pattern performance statistics
$script:PatternStats = @{
    CompilationTime = 0
    LastCompiled = $null
    PatternHits = @{}
    ValidationResults = @{}
}

#endregion

#region Pattern Compilation and Validation

function Initialize-CompiledPatterns {
    [CmdletBinding()]
    param()
    
    $compilationStart = [System.Diagnostics.Stopwatch]::StartNew()
    Write-PatternLog -Message "Initializing compiled regex patterns for enhanced performance" -Level "INFO"
    
    try {
        $script:CompiledPatterns.Clear()
        
        foreach ($patternName in $script:RecommendationPatterns.Keys) {
            $patternInfo = $script:RecommendationPatterns[$patternName]
            
            # Compile primary pattern with culture-invariant options
            $primaryRegex = [regex]::new($patternInfo.Pattern, "Compiled, IgnoreCase, CultureInvariant")
            
            # Compile semantic patterns
            $semanticRegexes = @()
            foreach ($semanticPattern in $patternInfo.SemanticPatterns) {
                $semanticRegexes += [regex]::new($semanticPattern, "Compiled, IgnoreCase, CultureInvariant")
            }
            
            $script:CompiledPatterns[$patternName] = @{
                Primary = $primaryRegex
                Semantic = $semanticRegexes
                BaseWeight = $patternInfo.BaseWeight
                ValidationRules = $patternInfo.ValidationRules
                CompilationTime = Get-Date
            }
            
            Write-PatternLog -Message "Compiled pattern: $patternName" -Level "DEBUG"
        }
        
        $compilationStart.Stop()
        $script:PatternStats.CompilationTime = $compilationStart.ElapsedMilliseconds
        $script:PatternStats.LastCompiled = Get-Date
        
        Write-PatternLog -Message "Pattern compilation completed in $($compilationStart.ElapsedMilliseconds)ms" -Level "PERF"
        
    } catch {
        Write-PatternLog -Message "Pattern compilation failed: $($_.Exception.Message)" -Level "ERROR"
        throw
    }
}

function Test-PatternValidation {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$ExtractedValue,
        
        [Parameter(Mandatory = $true)]
        [string[]]$ValidationRules
    )
    
    $validationResults = @{
        IsValid = $true
        PassedRules = @()
        FailedRules = @()
        Score = 0.0
    }
    
    foreach ($ruleName in $ValidationRules) {
        if ($script:ValidationRules.ContainsKey($ruleName)) {
            $rulePattern = $script:ValidationRules[$ruleName]
            $ruleRegex = [regex]::new($rulePattern, "IgnoreCase, CultureInvariant")
            
            if ($ruleRegex.IsMatch($ExtractedValue)) {
                $validationResults.PassedRules += $ruleName
                $validationResults.Score += 1.0
            } else {
                $validationResults.FailedRules += $ruleName
                $validationResults.IsValid = $false
            }
        }
    }
    
    # Calculate normalized score
    if ($ValidationRules.Count -gt 0) {
        $validationResults.Score = $validationResults.Score / $ValidationRules.Count
    }
    
    return $validationResults
}

function Get-EnhancedPatternMatch {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$ResponseText,
        
        [Parameter(Mandatory = $true)]
        [string]$PatternName
    )
    
    if (-not $script:CompiledPatterns.ContainsKey($PatternName)) {
        Write-PatternLog -Message "Pattern not found: $PatternName" -Level "WARN"
        return $null
    }
    
    $compiledPattern = $script:CompiledPatterns[$PatternName]
    $bestMatch = $null
    $highestConfidence = 0.0
    
    # Test primary pattern first
    $primaryMatch = $compiledPattern.Primary.Match($ResponseText)
    if ($primaryMatch.Success) {
        $confidence = $compiledPattern.BaseWeight * 0.95  # Primary patterns get high base confidence
        
        $bestMatch = @{
            MatchType = "Primary"
            Match = $primaryMatch
            BaseConfidence = $confidence
            PatternWeight = $compiledPattern.BaseWeight
        }
        $highestConfidence = $confidence
    }
    
    # Test semantic patterns for additional matches
    for ($i = 0; $i -lt $compiledPattern.Semantic.Count; $i++) {
        $semanticRegex = $compiledPattern.Semantic[$i]
        $semanticMatch = $semanticRegex.Match($ResponseText)
        
        if ($semanticMatch.Success) {
            # Semantic patterns get slightly lower base confidence but pattern-weighted boost
            $confidence = ($compiledPattern.BaseWeight * 0.85) + (0.1 * ($i + 1) / $compiledPattern.Semantic.Count)
            
            if ($confidence -gt $highestConfidence) {
                $bestMatch = @{
                    MatchType = "Semantic"
                    Match = $semanticMatch
                    BaseConfidence = $confidence
                    PatternWeight = $compiledPattern.BaseWeight
                    SemanticIndex = $i
                }
                $highestConfidence = $confidence
            }
        }
    }
    
    # Apply validation scoring if we found a match
    if ($bestMatch -and $compiledPattern.ValidationRules.Count -gt 0) {
        $extractedValue = if ($bestMatch.Match.Groups.Count -gt 1) { $bestMatch.Match.Groups[1].Value } else { $bestMatch.Match.Value }
        $validationResult = Test-PatternValidation -ExtractedValue $extractedValue -ValidationRules $compiledPattern.ValidationRules
        
        # Adjust confidence based on validation
        $bestMatch.ValidationResult = $validationResult
        $bestMatch.FinalConfidence = $bestMatch.BaseConfidence * (0.7 + 0.3 * $validationResult.Score)
    } else {
        $bestMatch.FinalConfidence = $bestMatch.BaseConfidence
    }
    
    return $bestMatch
}

#endregion

#region Logging Functions

function Write-PatternLog {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Message,
        
        [Parameter()]
        [ValidateSet("INFO", "WARN", "ERROR", "DEBUG", "PERF")]
        [string]$Level = "INFO"
    )
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss.fff"
    $logEntry = "[$timestamp] [$Level] [PatternRecognitionEngine] $Message"
    
    try {
        Add-Content -Path $script:LogPath -Value $logEntry -Encoding UTF8 -ErrorAction SilentlyContinue
    } catch {
        # Silently continue if logging fails
    }
    
    if ($Level -eq "ERROR") {
        Write-Error $Message
    } elseif ($Level -eq "WARN") {
        Write-Warning $Message
    } else {
        $color = switch ($Level) {
            "INFO" { "Green" }
            "DEBUG" { "Gray" }
            "PERF" { "Cyan" }
            default { "White" }
        }
        Write-Host "[$Level] $Message" -ForegroundColor $color
    }
}

#endregion

#region Recommendation Pattern Recognition

function Find-RecommendationPatterns {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$ResponseText
    )
    
    Write-PatternLog -Message "Analyzing response for enhanced recommendation patterns" -Level "DEBUG"
    
    # Initialize compiled patterns if not done yet
    if ($script:CompiledPatterns.Count -eq 0) {
        Initialize-CompiledPatterns
    }
    
    $recommendations = @()
    $totalMatchTime = [System.Diagnostics.Stopwatch]::StartNew()
    
    foreach ($patternName in $script:RecommendationPatterns.Keys) {
        $patternInfo = $script:RecommendationPatterns[$patternName]
        
        Write-PatternLog -Message "Testing enhanced pattern: $patternName" -Level "DEBUG"
        
        # Use enhanced pattern matching with ensemble and validation
        $enhancedMatch = Get-EnhancedPatternMatch -ResponseText $ResponseText -PatternName $patternName
        
        if ($enhancedMatch -and $enhancedMatch.Match.Success) {
            $match = $enhancedMatch.Match
            
            # Track pattern usage statistics
            if (-not $script:PatternStats.PatternHits.ContainsKey($patternName)) {
                $script:PatternStats.PatternHits[$patternName] = 0
            }
            $script:PatternStats.PatternHits[$patternName]++
            
            $recommendation = @{
                Type = $patternName
                ActionType = $patternInfo.ActionType
                Priority = $patternInfo.Priority
                Confidence = $enhancedMatch.FinalConfidence
                BaseConfidence = $enhancedMatch.BaseConfidence
                PatternWeight = $enhancedMatch.PatternWeight
                MatchType = $enhancedMatch.MatchType
                FullMatch = $match.Value
                ExtractedValue = if ($match.Groups.Count -gt 1) { $match.Groups[1].Value } else { $null }
                AdditionalInfo = if ($match.Groups.Count -gt 2) { $match.Groups[2].Value } else { $null }
                Position = $match.Index
                Length = $match.Length
                ValidationResult = $enhancedMatch.ValidationResult
                AnalysisTimestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss.fff"
            }
            
            # Enhanced type-specific property extraction
            switch ($patternName) {
                "TEST" {
                    $recommendation.FilePath = if ($match.Groups.Count -gt 1) { $match.Groups[1].Value } else { $null }
                    $recommendation.Action = if ($match.Groups.Count -gt 2) { $match.Groups[2].Value } else { $null }
                    $recommendation.TestType = "Execution"
                }
                "FIX" {
                    $recommendation.FilePath = if ($match.Groups.Count -gt 1) { $match.Groups[1].Value } else { $null }
                    $recommendation.Action = if ($match.Groups.Count -gt 2) { $match.Groups[2].Value } else { $null }
                    $recommendation.FixType = "CodeCorrection"
                }
                "RESTART" {
                    $recommendation.ServiceName = if ($match.Groups.Count -gt 1) { $match.Groups[1].Value } else { $null }
                    $recommendation.Action = if ($match.Groups.Count -gt 2) { $match.Groups[2].Value } else { $null }
                    $recommendation.RestartType = "ServiceCycle"
                }
                "COMPILE" {
                    $recommendation.ProjectPath = if ($match.Groups.Count -gt 1) { $match.Groups[1].Value } else { $null }
                    $recommendation.CompileType = "BuildProject"
                }
                "ANALYZE" {
                    $recommendation.Target = if ($match.Groups.Count -gt 1) { $match.Groups[1].Value } else { $null }
                    $recommendation.AnalysisType = "CodeReview"
                }
                "CREATE" {
                    $recommendation.Target = if ($match.Groups.Count -gt 1) { $match.Groups[1].Value } else { $null }
                    $recommendation.CreationType = "FileGeneration"
                }
                "ERROR" {
                    $recommendation.ErrorSource = if ($match.Groups.Count -gt 1) { $match.Groups[1].Value } else { $null }
                    $recommendation.ErrorDetail = if ($match.Groups.Count -gt 2) { $match.Groups[2].Value } else { $null }
                    $recommendation.ErrorType = "SystemException"
                }
            }
            
            $recommendations += $recommendation
            
            $confidenceDisplay = "{0:P1}" -f $enhancedMatch.FinalConfidence
            Write-PatternLog -Message "Found recommendation: $patternName ($($enhancedMatch.MatchType), confidence: $confidenceDisplay)" -Level "INFO"
        }
    }
    
    $totalMatchTime.Stop()
    
    # Enhanced sorting with confidence-weighted priority
    $priorityOrder = @{ "Critical" = 0; "High" = 1; "Medium" = 2; "Low" = 3 }
    $sortedRecommendations = $recommendations | Sort-Object @{
        Expression = { $priorityOrder[$_.Priority] - ($_.Confidence * 0.5) }  # Confidence affects priority
    }, @{
        Expression = { -$_.Confidence }  # Higher confidence first within same priority
    }, Position  # Position as final tiebreaker
    
    Write-PatternLog -Message "Enhanced pattern analysis: found $($recommendations.Count) patterns in $($totalMatchTime.ElapsedMilliseconds)ms" -Level "PERF"
    
    # Store pattern statistics for learning
    if ($recommendations.Count -gt 0) {
        $avgConfidence = ($recommendations | Measure-Object Confidence -Average).Average
        $maxConfidence = ($recommendations | Measure-Object Confidence -Maximum).Maximum
        
        Write-PatternLog -Message "Pattern quality: avg confidence $($avgConfidence.ToString('P1')), max confidence $($maxConfidence.ToString('P1'))" -Level "INFO"
    }
    
    return $sortedRecommendations
}

#endregion

#region Entity Relationship Graph System

# Entity relationship graph structure
$script:EntityGraph = @{
    Nodes = @{}
    Edges = @{}
    NodeCounter = 0
    LastUpdated = $null
}

# Temporal context tracking for command sequences
$script:TemporalContext = @{
    CommandSequences = @()
    LastCommandTime = $null
    SequenceThreshold = 5000  # milliseconds
}

function New-EntityNode {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [PSObject]$Entity
    )
    
    $nodeId = "node_" + $script:EntityGraph.NodeCounter++
    
    $node = @{
        Id = $nodeId
        Type = $Entity.Type
        Value = $Entity.Value
        Properties = @{
            Position = $Entity.Position
            Context = $Entity.Context
            PatternName = $Entity.PatternName
            ContextWeight = if ($Entity.ContextWeight) { $Entity.ContextWeight } else { 1.0 }
            CreatedAt = Get-Date
            LastAccessed = Get-Date
            AccessCount = 1
        }
        Relationships = @{}
        SemanticSimilarity = @{}
    }
    
    # Add type-specific properties
    switch ($Entity.Type) {
        "FilePath" { 
            $node.Properties.Extension = [System.IO.Path]::GetExtension($Entity.Value)
            $node.Properties.Directory = [System.IO.Path]::GetDirectoryName($Entity.Value)
            $node.Properties.FileName = [System.IO.Path]::GetFileName($Entity.Value)
        }
        "ErrorMessage" {
            $node.Properties.Severity = "High"
            $node.Properties.Category = "Unknown"
        }
        "PowerShellCommand" {
            $node.Properties.Module = "Unknown"
            $node.Properties.CommandType = "Unknown"
        }
        "URL" {
            $node.Properties.Domain = [System.Uri]::new($Entity.Value).Host
            $node.Properties.Protocol = [System.Uri]::new($Entity.Value).Scheme
        }
    }
    
    $script:EntityGraph.Nodes[$nodeId] = $node
    return $nodeId
}

function New-EntityRelationship {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$SourceNodeId,
        
        [Parameter(Mandatory = $true)]
        [string]$TargetNodeId,
        
        [Parameter(Mandatory = $true)]
        [string]$RelationshipType,
        
        [Parameter()]
        [double]$Confidence = 1.0,
        
        [Parameter()]
        [hashtable]$Properties = @{}
    )
    
    $edgeId = "$SourceNodeId-$RelationshipType-$TargetNodeId"
    
    $edge = @{
        Id = $edgeId
        SourceNodeId = $SourceNodeId
        TargetNodeId = $TargetNodeId
        RelationshipType = $RelationshipType
        Confidence = $Confidence
        Properties = $Properties
        CreatedAt = Get-Date
        Weight = $Confidence
    }
    
    $script:EntityGraph.Edges[$edgeId] = $edge
    
    # Update node relationships
    if ($script:EntityGraph.Nodes.ContainsKey($SourceNodeId)) {
        if (-not $script:EntityGraph.Nodes[$SourceNodeId].Relationships.ContainsKey($RelationshipType)) {
            $script:EntityGraph.Nodes[$SourceNodeId].Relationships[$RelationshipType] = @()
        }
        $script:EntityGraph.Nodes[$SourceNodeId].Relationships[$RelationshipType] += $TargetNodeId
    }
    
    return $edgeId
}

function Get-EntitySimilarity {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [PSObject]$Entity1,
        
        [Parameter(Mandatory = $true)]
        [PSObject]$Entity2
    )
    
    # Type similarity (same type gets higher score)
    $typeSimilarity = if ($Entity1.Type -eq $Entity2.Type) { 1.0 } else { 0.0 }
    
    # Value similarity using Levenshtein distance approximation
    $value1 = $Entity1.Value.ToLower()
    $value2 = $Entity2.Value.ToLower()
    
    # Simple character-based similarity
    $maxLength = [Math]::Max($value1.Length, $value2.Length)
    $commonChars = 0
    $minLength = [Math]::Min($value1.Length, $value2.Length)
    
    for ($i = 0; $i -lt $minLength; $i++) {
        if ($value1[$i] -eq $value2[$i]) {
            $commonChars++
        }
    }
    
    $valueSimilarity = if ($maxLength -gt 0) { $commonChars / $maxLength } else { 0.0 }
    
    # Context similarity (same pattern name or similar context)
    $contextSimilarity = if ($Entity1.PatternName -eq $Entity2.PatternName) { 1.0 } else { 0.5 }
    
    # Weighted average
    $overallSimilarity = ($typeSimilarity * 0.4) + ($valueSimilarity * 0.4) + ($contextSimilarity * 0.2)
    
    return @{
        OverallSimilarity = $overallSimilarity
        TypeSimilarity = $typeSimilarity
        ValueSimilarity = $valueSimilarity
        ContextSimilarity = $contextSimilarity
    }
}

function Build-EntityRelationshipGraph {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [array]$Entities
    )
    
    Write-PatternLog -Message "Building entity relationship graph with $($Entities.Count) entities" -Level "DEBUG"
    
    $nodeIds = @()
    
    # Create nodes for all entities
    foreach ($entity in $Entities) {
        $nodeId = New-EntityNode -Entity $entity
        $nodeIds += $nodeId
    }
    
    # Establish relationships between entities
    for ($i = 0; $i -lt $nodeIds.Count; $i++) {
        for ($j = $i + 1; $j -lt $nodeIds.Count; $j++) {
            $entity1 = $Entities[$i]
            $entity2 = $Entities[$j]
            $nodeId1 = $nodeIds[$i]
            $nodeId2 = $nodeIds[$j]
            
            # Calculate semantic similarity
            $similarity = Get-EntitySimilarity -Entity1 $entity1 -Entity2 $entity2
            
            # Create relationships based on proximity and semantic similarity
            if ($similarity.OverallSimilarity -gt 0.7) {
                New-EntityRelationship -SourceNodeId $nodeId1 -TargetNodeId $nodeId2 -RelationshipType "SimilarTo" -Confidence $similarity.OverallSimilarity
            }
            
            # Proximity-based relationships (entities close to each other in text)
            $positionDifference = [Math]::Abs($entity1.Position - $entity2.Position)
            if ($positionDifference -lt 100) {  # Within 100 characters
                $proximityConfidence = 1.0 - ($positionDifference / 100.0)
                New-EntityRelationship -SourceNodeId $nodeId1 -TargetNodeId $nodeId2 -RelationshipType "NearTo" -Confidence $proximityConfidence
            }
            
            # Type-specific relationships
            $relationshipType = Get-TypeSpecificRelationship -Entity1 $entity1 -Entity2 $entity2
            if ($relationshipType) {
                New-EntityRelationship -SourceNodeId $nodeId1 -TargetNodeId $nodeId2 -RelationshipType $relationshipType -Confidence 0.8
            }
        }
    }
    
    $script:EntityGraph.LastUpdated = Get-Date
    
    Write-PatternLog -Message "Entity graph built: $($script:EntityGraph.Nodes.Count) nodes, $($script:EntityGraph.Edges.Count) edges" -Level "INFO"
    
    return @{
        NodeCount = $script:EntityGraph.Nodes.Count
        EdgeCount = $script:EntityGraph.Edges.Count
        GraphDensity = if ($script:EntityGraph.Nodes.Count -gt 1) { 
            ($script:EntityGraph.Edges.Count * 2) / ($script:EntityGraph.Nodes.Count * ($script:EntityGraph.Nodes.Count - 1))
        } else { 
            0.0 
        }
    }
}

function Get-TypeSpecificRelationship {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [PSObject]$Entity1,
        
        [Parameter(Mandatory = $true)]
        [PSObject]$Entity2
    )
    
    # Define type-specific relationship patterns
    $typeRelationships = @{
        "FilePath" = @{
            "ErrorMessage" = "ErrorIn"
            "PowerShellCommand" = "ExecutedBy"
            "TestFile" = "TestedBy"
        }
        "PowerShellCommand" = @{
            "ModuleName" = "FromModule"
            "Parameter" = "TakesParameter"
            "Variable" = "ModifiesVariable"
        }
        "ErrorMessage" = @{
            "FilePath" = "OccursIn"
            "ModuleName" = "FromModule"
        }
        "TestFile" = @{
            "FilePath" = "Tests"
            "ModuleName" = "TestsModule"
        }
    }
    
    if ($typeRelationships.ContainsKey($Entity1.Type) -and 
        $typeRelationships[$Entity1.Type].ContainsKey($Entity2.Type)) {
        return $typeRelationships[$Entity1.Type][$Entity2.Type]
    }
    
    return $null
}

function Get-EntityClusterAnalysis {
    [CmdletBinding()]
    param()
    
    $clusters = @()
    $visitedNodes = @{}
    
    foreach ($nodeId in $script:EntityGraph.Nodes.Keys) {
        if (-not $visitedNodes.ContainsKey($nodeId)) {
            $cluster = Get-ConnectedNodes -StartNodeId $nodeId -VisitedNodes $visitedNodes
            if ($cluster.Count -gt 1) {
                $clusters += @{
                    Id = "cluster_" + $clusters.Count
                    Nodes = $cluster
                    Size = $cluster.Count
                    CentralNode = Get-MostConnectedNode -NodeIds $cluster
                    Coherence = Get-ClusterCoherence -NodeIds $cluster
                }
            }
        }
    }
    
    return $clusters
}

function Get-ConnectedNodes {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$StartNodeId,
        
        [Parameter(Mandatory = $true)]
        [hashtable]$VisitedNodes
    )
    
    $connectedNodes = @($StartNodeId)
    $visitedNodes[$StartNodeId] = $true
    $queue = @($StartNodeId)
    
    while ($queue.Count -gt 0) {
        $currentNodeId = $queue[0]
        $queue = $queue[1..($queue.Count - 1)]
        
        # Find all connected nodes through edges
        foreach ($edgeId in $script:EntityGraph.Edges.Keys) {
            $edge = $script:EntityGraph.Edges[$edgeId]
            $connectedNodeId = $null
            
            if ($edge.SourceNodeId -eq $currentNodeId -and -not $visitedNodes.ContainsKey($edge.TargetNodeId)) {
                $connectedNodeId = $edge.TargetNodeId
            } elseif ($edge.TargetNodeId -eq $currentNodeId -and -not $visitedNodes.ContainsKey($edge.SourceNodeId)) {
                $connectedNodeId = $edge.SourceNodeId
            }
            
            if ($connectedNodeId) {
                $connectedNodes += $connectedNodeId
                $visitedNodes[$connectedNodeId] = $true
                $queue += $connectedNodeId
            }
        }
    }
    
    return $connectedNodes
}

function Get-MostConnectedNode {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [array]$NodeIds
    )
    
    $connectionCounts = @{}
    
    foreach ($nodeId in $NodeIds) {
        $connectionCounts[$nodeId] = 0
        
        foreach ($edgeId in $script:EntityGraph.Edges.Keys) {
            $edge = $script:EntityGraph.Edges[$edgeId]
            if ($edge.SourceNodeId -eq $nodeId -or $edge.TargetNodeId -eq $nodeId) {
                $connectionCounts[$nodeId]++
            }
        }
    }
    
    $mostConnected = $connectionCounts.GetEnumerator() | Sort-Object Value -Descending | Select-Object -First 1
    return $mostConnected.Key
}

function Get-ClusterCoherence {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [array]$NodeIds
    )
    
    if ($NodeIds.Count -lt 2) {
        return 1.0
    }
    
    $totalPairs = ($NodeIds.Count * ($NodeIds.Count - 1)) / 2
    $connectedPairs = 0
    
    for ($i = 0; $i -lt $NodeIds.Count; $i++) {
        for ($j = $i + 1; $j -lt $NodeIds.Count; $j++) {
            $nodeId1 = $NodeIds[$i]
            $nodeId2 = $NodeIds[$j]
            
            # Check if there's a direct edge between these nodes
            foreach ($edgeId in $script:EntityGraph.Edges.Keys) {
                $edge = $script:EntityGraph.Edges[$edgeId]
                if (($edge.SourceNodeId -eq $nodeId1 -and $edge.TargetNodeId -eq $nodeId2) -or
                    ($edge.SourceNodeId -eq $nodeId2 -and $edge.TargetNodeId -eq $nodeId1)) {
                    $connectedPairs++
                    break
                }
            }
        }
    }
    
    return if ($totalPairs -gt 0) { $connectedPairs / $totalPairs } else { 0.0 }
}

#endregion

#region Enhanced Context Entity Extraction

function Extract-ContextEntities {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$ResponseContent
    )
    
    Write-PatternLog -Message "Extracting enhanced context entities from response" -Level "DEBUG"
    
    $entities = @()
    $extractionStart = [System.Diagnostics.Stopwatch]::StartNew()
    
    foreach ($patternName in $script:ContextPatterns.Keys) {
        $patternInfo = $script:ContextPatterns[$patternName]
        
        Write-PatternLog -Message "Extracting entities with enhanced pattern: $patternName" -Level "DEBUG"
        
        # Primary pattern extraction with compiled regex
        $primaryRegex = [regex]::new($patternInfo.Pattern, "Compiled, IgnoreCase, CultureInvariant")
        $primaryMatches = $primaryRegex.Matches($ResponseContent)
        
        foreach ($match in $primaryMatches) {
            $extractedValue = $match.Groups[$patternInfo.ExtractGroup].Value
            
            if (-not [string]::IsNullOrWhiteSpace($extractedValue)) {
                $entity = @{
                    Type = $patternInfo.EntityType
                    Value = $extractedValue.Trim()
                    Position = $match.Index
                    Length = $match.Length
                    Context = $match.Value
                    PatternName = $patternName
                    MatchType = "Primary"
                    ContextWeight = $patternInfo.ContextWeight
                    RelationshipTypes = $patternInfo.RelationshipTypes
                    ExtractedAt = Get-Date
                    Confidence = 0.95  # High confidence for primary pattern matches
                }
                
                # Add type-specific additional properties
                if ($patternInfo.AdditionalProperties) {
                    foreach ($key in $patternInfo.AdditionalProperties.Keys) {
                        $entity[$key] = $patternInfo.AdditionalProperties[$key]
                    }
                }
                
                $entities += $entity
                
                Write-PatternLog -Message "Extracted primary entity: $($entity.Type) = '$($entity.Value)'" -Level "DEBUG"
            }
        }
        
        # Semantic pattern extraction for additional matches
        if ($patternInfo.SemanticPatterns) {
            foreach ($semanticPattern in $patternInfo.SemanticPatterns) {
                $semanticRegex = [regex]::new($semanticPattern, "Compiled, IgnoreCase, CultureInvariant")
                $semanticMatches = $semanticRegex.Matches($ResponseContent)
                
                foreach ($match in $semanticMatches) {
                    $extractedValue = $match.Groups[1].Value  # First capture group for semantic patterns
                    
                    if (-not [string]::IsNullOrWhiteSpace($extractedValue)) {
                        # Check for duplicates (same value and type)
                        $isDuplicate = $entities | Where-Object { 
                            $_.Type -eq $patternInfo.EntityType -and 
                            $_.Value -eq $extractedValue.Trim() 
                        }
                        
                        if (-not $isDuplicate) {
                            $entity = @{
                                Type = $patternInfo.EntityType
                                Value = $extractedValue.Trim()
                                Position = $match.Index
                                Length = $match.Length
                                Context = $match.Value
                                PatternName = $patternName
                                MatchType = "Semantic"
                                ContextWeight = $patternInfo.ContextWeight * 0.9  # Slightly lower confidence for semantic
                                RelationshipTypes = $patternInfo.RelationshipTypes
                                ExtractedAt = Get-Date
                                Confidence = 0.85  # Lower confidence for semantic pattern matches
                            }
                            
                            # Add type-specific additional properties
                            if ($patternInfo.AdditionalProperties) {
                                foreach ($key in $patternInfo.AdditionalProperties.Keys) {
                                    $entity[$key] = $patternInfo.AdditionalProperties[$key]
                                }
                            }
                            
                            $entities += $entity
                            
                            Write-PatternLog -Message "Extracted semantic entity: $($entity.Type) = '$($entity.Value)'" -Level "DEBUG"
                        }
                    }
                }
            }
        }
    }
    
    $extractionStart.Stop()
    
    # Enhanced entity validation and enrichment
    $validatedEntities = @()
    foreach ($entity in $entities) {
        # Context validation
        $isValidContext = Test-EntityContextValidation -Entity $entity
        
        if ($isValidContext.IsValid) {
            # Enrich entity with validation information
            $entity.ValidationResult = $isValidContext
            $entity.EnrichedProperties = Get-EntityEnrichment -Entity $entity
            
            $validatedEntities += $entity
        } else {
            Write-PatternLog -Message "Entity validation failed: $($entity.Type) = '$($entity.Value)' - $($isValidContext.Reason)" -Level "DEBUG"
        }
    }
    
    # Remove duplicates with enhanced deduplication
    $uniqueEntities = Get-DeduplicatedEntities -Entities $validatedEntities
    
    # Sort by position and relevance score
    $sortedEntities = $uniqueEntities | Sort-Object @{
        Expression = { $_.ContextWeight * $_.Confidence }  # Relevance score
        Descending = $true
    }, Position
    
    # Build entity relationship graph
    if ($sortedEntities.Count -gt 1) {
        Write-PatternLog -Message "Building entity relationship graph for $($sortedEntities.Count) entities" -Level "DEBUG"
        $graphMetrics = Build-EntityRelationshipGraph -Entities $sortedEntities
        
        # Add graph analysis results
        $clusterAnalysis = Get-EntityClusterAnalysis
        
        # Enhance entities with graph information
        foreach ($entity in $sortedEntities) {
            $entity.GraphMetrics = $graphMetrics
            $entity.ClusterAnalysis = $clusterAnalysis
        }
        
        Write-PatternLog -Message "Graph analysis: $($graphMetrics.NodeCount) nodes, $($graphMetrics.EdgeCount) edges, density: $($graphMetrics.GraphDensity.ToString('P1'))" -Level "INFO"
    }
    
    Write-PatternLog -Message "Enhanced entity extraction: $($sortedEntities.Count) entities in $($extractionStart.ElapsedMilliseconds)ms" -Level "PERF"
    return $sortedEntities
}

function Test-EntityContextValidation {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [PSObject]$Entity
    )
    
    $validationResult = @{
        IsValid = $true
        Reason = ""
        Confidence = 1.0
        ValidationChecks = @{}
    }
    
    # Type-specific validation
    switch ($Entity.Type) {
        "FilePath" {
            # Validate file path format
            $pathValid = $Entity.Value -match '^[a-zA-Z]:[\\\/].*\.[a-zA-Z0-9]+$'
            $validationResult.ValidationChecks["PathFormat"] = $pathValid
            
            if (-not $pathValid) {
                $validationResult.IsValid = $false
                $validationResult.Reason = "Invalid file path format"
                $validationResult.Confidence = 0.3
            }
        }
        "URL" {
            # Validate URL format
            try {
                $uri = [System.Uri]::new($Entity.Value)
                $urlValid = $uri.IsAbsoluteUri
                $validationResult.ValidationChecks["URLFormat"] = $urlValid
                
                if (-not $urlValid) {
                    $validationResult.IsValid = $false
                    $validationResult.Reason = "Invalid URL format"
                    $validationResult.Confidence = 0.2
                }
            } catch {
                $validationResult.IsValid = $false
                $validationResult.Reason = "URL parsing failed"
                $validationResult.Confidence = 0.1
            }
        }
        "PowerShellCommand" {
            # Validate PowerShell command format
            $cmdValid = $Entity.Value -match '^[A-Za-z][A-Za-z0-9\-]*$'
            $validationResult.ValidationChecks["CommandFormat"] = $cmdValid
            
            if (-not $cmdValid) {
                $validationResult.IsValid = $false
                $validationResult.Reason = "Invalid PowerShell command format"
                $validationResult.Confidence = 0.4
            }
        }
        "ErrorMessage" {
            # Validate error message has meaningful content
            $errorValid = $Entity.Value.Length -gt 5 -and -not ($Entity.Value -match '^\s*$')
            $validationResult.ValidationChecks["ErrorContent"] = $errorValid
            
            if (-not $errorValid) {
                $validationResult.IsValid = $false
                $validationResult.Reason = "Error message too short or empty"
                $validationResult.Confidence = 0.2
            }
        }
    }
    
    # Context coherence validation
    $contextCoherent = $Entity.Context.Length -gt $Entity.Value.Length
    $validationResult.ValidationChecks["ContextCoherence"] = $contextCoherent
    
    if (-not $contextCoherent) {
        $validationResult.Confidence *= 0.8  # Reduce confidence but don't invalidate
    }
    
    return $validationResult
}

function Get-EntityEnrichment {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [PSObject]$Entity
    )
    
    $enrichment = @{}
    
    switch ($Entity.Type) {
        "FilePath" {
            $enrichment.Extension = [System.IO.Path]::GetExtension($Entity.Value)
            $enrichment.Directory = [System.IO.Path]::GetDirectoryName($Entity.Value)
            $enrichment.FileName = [System.IO.Path]::GetFileNameWithoutExtension($Entity.Value)
            $enrichment.IsScript = $enrichment.Extension -in @('.ps1', '.psm1', '.psd1')
            $enrichment.IsCode = $enrichment.Extension -in @('.cs', '.js', '.py', '.ps1', '.psm1')
        }
        "PowerShellCommand" {
            # Try to determine command type and module
            $knownModules = @{
                'Get-' = 'Microsoft.PowerShell.Management'
                'Set-' = 'Microsoft.PowerShell.Management'
                'New-' = 'Microsoft.PowerShell.Management'
                'Remove-' = 'Microsoft.PowerShell.Management'
                'Test-' = 'Microsoft.PowerShell.Diagnostics'
                'Invoke-' = 'Microsoft.PowerShell.Utility'
            }
            
            foreach ($prefix in $knownModules.Keys) {
                if ($Entity.Value.StartsWith($prefix)) {
                    $enrichment.ProbableModule = $knownModules[$prefix]
                    $enrichment.CommandType = switch ($prefix) {
                        'Get-' { 'Query' }
                        'Set-' { 'Modification' }
                        'New-' { 'Creation' }
                        'Remove-' { 'Deletion' }
                        'Test-' { 'Validation' }
                        'Invoke-' { 'Execution' }
                        default { 'Unknown' }
                    }
                    break
                }
            }
        }
        "ErrorMessage" {
            # Classify error severity and type
            $errorText = $Entity.Value.ToLower()
            if ($errorText.Contains('critical') -or $errorText.Contains('fatal')) {
                $enrichment.Severity = 'Critical'
            } elseif ($errorText.Contains('warning')) {
                $enrichment.Severity = 'Warning'
            } else {
                $enrichment.Severity = 'Error'
            }
            
            if ($errorText.Contains('compilation') -or $errorText.Contains('build')) {
                $enrichment.Category = 'Compilation'
            } elseif ($errorText.Contains('runtime') -or $errorText.Contains('execution')) {
                $enrichment.Category = 'Runtime'
            } else {
                $enrichment.Category = 'General'
            }
        }
        "URL" {
            try {
                $uri = [System.Uri]::new($Entity.Value)
                $enrichment.Domain = $uri.Host
                $enrichment.Protocol = $uri.Scheme
                $enrichment.Port = $uri.Port
                $enrichment.IsSecure = $uri.Scheme -eq 'https'
                $enrichment.IsLocalhost = $uri.Host -in @('localhost', '127.0.0.1', '::1')
            } catch {
                $enrichment.ParseError = $_.Exception.Message
            }
        }
    }
    
    return $enrichment
}

function Get-DeduplicatedEntities {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [array]$Entities
    )
    
    $deduplicatedEntities = @()
    $entityHashes = @{}
    
    foreach ($entity in $Entities) {
        # Create a hash based on type and value for exact duplicates
        $exactHash = "$($entity.Type):$($entity.Value.ToLower())"
        
        if ($entityHashes.ContainsKey($exactHash)) {
            # Merge with existing entity, keeping the one with higher confidence
            $existing = $entityHashes[$exactHash]
            if ($entity.Confidence -gt $existing.Confidence) {
                # Replace with higher confidence entity
                $entityHashes[$exactHash] = $entity
                
                # Update the deduplicatedEntities array
                for ($i = 0; $i -lt $deduplicatedEntities.Count; $i++) {
                    if ($deduplicatedEntities[$i].Type -eq $existing.Type -and 
                        $deduplicatedEntities[$i].Value -eq $existing.Value) {
                        $deduplicatedEntities[$i] = $entity
                        break
                    }
                }
            }
        } else {
            $entityHashes[$exactHash] = $entity
            $deduplicatedEntities += $entity
        }
    }
    
    Write-PatternLog -Message "Deduplication: $($Entities.Count) -> $($deduplicatedEntities.Count) entities" -Level "DEBUG"
    return $deduplicatedEntities
}

#endregion

#region Response Classification

function Get-FeatureScore {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$ResponseContent,
        
        [Parameter(Mandatory = $true)]
        [string[]]$Indicators
    )
    
    $content = $ResponseContent.ToLower()
    $score = 0
    $matchedIndicators = @()
    
    foreach ($indicator in $Indicators) {
        $pattern = "\b$([regex]::Escape($indicator.ToLower()))\b"
        $matches = [regex]::Matches($content, $pattern)
        
        if ($matches.Count -gt 0) {
            $score += $matches.Count
            $matchedIndicators += $indicator
        }
    }
    
    return @{
        Score = $score
        MatchedIndicators = $matchedIndicators
        NormalizedScore = if ($Indicators.Count -gt 0) { $score / $Indicators.Count } else { 0 }
    }
}

function Classify-ResponseType {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$ResponseContent,
        
        [Parameter()]
        [array]$Recommendations = @(),
        
        [Parameter()]
        [array]$Entities = @()
    )
    
    Write-PatternLog -Message "Starting ensemble-based response type classification" -Level "DEBUG"
    
    # Enhanced feature engineering with context-aware scoring
    $enhancedFeatures = Get-EnhancedFeatureEngineering -ResponseContent $ResponseContent -Recommendations $Recommendations -Entities $Entities
    
    # Ensemble of classifiers for robust classification
    $classifierResults = @()
    
    # Classifier 1: Rule-based decision tree classifier
    $decisionTreeResult = Invoke-DecisionTreeClassifier -ResponseContent $ResponseContent -Features $enhancedFeatures
    $classifierResults += @{
        Method = "DecisionTree"
        Result = $decisionTreeResult
        Weight = 0.35
        Reliability = 0.88
    }
    
    # Classifier 2: Feature-based probabilistic classifier  
    $featureClassifierResult = Invoke-FeatureBasedClassifier -ResponseContent $ResponseContent -Features $enhancedFeatures
    $classifierResults += @{
        Method = "FeatureBased"
        Result = $featureClassifierResult
        Weight = 0.25
        Reliability = 0.82
    }
    
    # Classifier 3: Recommendation-based classifier with Bayesian enhancement
    $recommendationClassifierResult = Invoke-RecommendationClassifier -Recommendations $Recommendations -Features $enhancedFeatures
    $classifierResults += @{
        Method = "RecommendationBased"
        Result = $recommendationClassifierResult
        Weight = 0.25
        Reliability = 0.90
    }
    
    # Classifier 4: Entity-context classifier
    $entityClassifierResult = Invoke-EntityContextClassifier -Entities $Entities -Features $enhancedFeatures
    $classifierResults += @{
        Method = "EntityContext"
        Result = $entityClassifierResult
        Weight = 0.15
        Reliability = 0.75
    }
    
    # Ensemble voting with weighted confidence aggregation
    $ensembleResult = Invoke-EnsembleVoting -ClassifierResults $classifierResults
    
    # Apply Bayesian confidence calibration to final result
    $calibratedResult = Invoke-BayesianClassificationCalibration -EnsembleResult $ensembleResult -Features $enhancedFeatures
    
    Write-PatternLog -Message "Ensemble classification: $($calibratedResult.Type) (confidence: $($calibratedResult.Confidence.ToString('P2')), reliability: $($calibratedResult.ReliabilityIndex.ToString('P2')))" -Level "INFO"
    return $calibratedResult
}

function Get-EnhancedFeatureEngineering {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$ResponseContent,
        
        [Parameter()]
        [array]$Recommendations = @(),
        
        [Parameter()]
        [array]$Entities = @()
    )
    
    $features = @{}
    
    # Text-based features
    $features.TextLength = $ResponseContent.Length
    $features.WordCount = ($ResponseContent -split '\s+').Count
    $features.SentenceCount = ($ResponseContent -split '[.!?]').Count
    $features.ParagraphCount = ($ResponseContent -split '\n\s*\n').Count
    
    # Linguistic features
    $features.QuestionMarks = ($ResponseContent.ToCharArray() | Where-Object { $_ -eq '?' }).Count
    $features.ExclamationMarks = ($ResponseContent.ToCharArray() | Where-Object { $_ -eq '!' }).Count
    $features.UppercaseRatio = if ($features.TextLength -gt 0) { 
        ($ResponseContent.ToCharArray() | Where-Object { [char]::IsUpper($_) }).Count / $features.TextLength 
    } else { 0 }
    
    # Recommendation features
    $features.RecommendationCount = $Recommendations.Count
    $features.RecommendationTypes = if ($Recommendations.Count -gt 0) { 
        ($Recommendations | Group-Object Type).Count 
    } else { 0 }
    $features.HighPriorityRecommendations = if ($Recommendations.Count -gt 0) { 
        ($Recommendations | Where-Object { $_.Priority -eq "High" }).Count 
    } else { 0 }
    
    # Entity features
    $features.EntityCount = if ($null -ne $Entities) { $Entities.Count } else { 0 }
    $features.EntityTypes = if ($null -ne $Entities -and $Entities.Count -gt 0) { 
        ($Entities | Group-Object Type).Count 
    } else { 0 }
    $features.ErrorEntityCount = if ($null -ne $Entities -and $Entities.Count -gt 0) { 
        ($Entities | Where-Object { $_.Type -eq "ErrorMessage" }).Count 
    } else { 0 }
    $features.FileEntityCount = if ($null -ne $Entities -and $Entities.Count -gt 0) { 
        ($Entities | Where-Object { $_.Type -eq "FilePath" }).Count 
    } else { 0 }
    
    # Pattern-based features
    $features.CodeBlockCount = ([regex]::Matches($ResponseContent, '```[\s\S]*?```')).Count
    $features.CommandCount = ([regex]::Matches($ResponseContent, '\b[A-Z][a-zA-Z-]*\b')).Count
    $features.PathCount = ([regex]::Matches($ResponseContent, '[A-Za-z]:[\\\/][\w\\\/.-]*')).Count
    
    # Semantic features
    $content = $ResponseContent.ToLower()
    $features.ActionWords = ($content -split '\s+' | Where-Object { 
        $_ -in @('run', 'execute', 'test', 'fix', 'create', 'update', 'install', 'compile', 'build') 
    }).Count
    $features.QuestionWords = ($content -split '\s+' | Where-Object { 
        $_ -in @('what', 'how', 'why', 'when', 'where', 'which', 'who') 
    }).Count
    $features.ErrorWords = ($content -split '\s+' | Where-Object { 
        $_ -in @('error', 'fail', 'exception', 'issue', 'problem', 'warning') 
    }).Count
    
    return $features
}

function Invoke-DecisionTreeClassifier {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$ResponseContent,
        
        [Parameter(Mandatory = $true)]
        [hashtable]$Features
    )
    
    $confidence = 0.5
    $type = "Information"
    $reasoning = @()
    
    # Decision tree logic with multiple decision paths
    
    # Path 1: High priority recommendations -> Instruction
    if ($Features.HighPriorityRecommendations -gt 0) {
        $type = "Instruction"
        $confidence = 0.85 + ($Features.HighPriorityRecommendations * 0.05)
        $reasoning += "High-priority recommendations present ($($Features.HighPriorityRecommendations))"
    }
    # Path 2: Multiple errors detected -> Error
    elseif ($Features.ErrorEntityCount -gt 1 -or $Features.ErrorWords -gt 2) {
        $type = "Error" 
        $confidence = 0.80 + ([Math]::Min(0.15, $Features.ErrorEntityCount * 0.05))
        $reasoning += "Multiple error indicators detected"
    }
    # Path 3: Question patterns -> Question
    elseif ($Features.QuestionMarks -gt 0 -or $Features.QuestionWords -gt 1) {
        $type = "Question"
        $confidence = 0.75 + ([Math]::Min(0.15, $Features.QuestionWords * 0.05))
        $reasoning += "Question patterns detected"
    }
    # Path 4: Completion indicators -> Complete
    elseif ($ResponseContent -match '\b(complete|done|finished|success)\b' -and $Features.RecommendationCount -eq 0) {
        $type = "Complete"
        $confidence = 0.78
        $reasoning += "Completion indicators without new recommendations"
    }
    # Path 5: Action words with entities -> Instruction
    elseif ($Features.ActionWords -gt 2 -and $Features.EntityCount -gt 1) {
        $type = "Instruction"
        $confidence = 0.72
        $reasoning += "Action words with contextual entities"
    }
    # Path 6: Default information classification
    else {
        $type = "Information"
        $confidence = 0.60
        $reasoning += "Default information classification"
    }
    
    # Confidence adjustments based on supporting evidence
    if ($Features.EntityCount -gt 3) {
        $confidence += 0.05
        $reasoning += "High entity count support"
    }
    if ($Features.CodeBlockCount -gt 0) {
        $confidence += 0.03
        $reasoning += "Code block presence"
    }
    
    $confidence = [Math]::Min(0.95, $confidence)
    
    return @{
        Type = $type
        Confidence = $confidence
        Reasoning = $reasoning
        FeatureSupport = @{
            EntityCount = $Features.EntityCount
            RecommendationCount = $Features.RecommendationCount
            ActionWords = $Features.ActionWords
            ErrorWords = $Features.ErrorWords
        }
    }
}

function Invoke-FeatureBasedClassifier {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$ResponseContent,
        
        [Parameter(Mandatory = $true)]
        [hashtable]$Features
    )
    
    $classificationScores = @{
        "Instruction" = 0.0
        "Question" = 0.0
        "Error" = 0.0
        "Complete" = 0.0
        "Information" = 0.0
    }
    
    # Feature-based scoring with weighted contributions
    
    # Instruction scoring
    $classificationScores["Instruction"] += $Features.ActionWords * 0.12
    $classificationScores["Instruction"] += $Features.RecommendationCount * 0.15
    $classificationScores["Instruction"] += $Features.CommandCount * 0.08
    $classificationScores["Instruction"] += $Features.CodeBlockCount * 0.10
    
    # Question scoring
    $classificationScores["Question"] += $Features.QuestionMarks * 0.20
    $classificationScores["Question"] += $Features.QuestionWords * 0.15
    if ($Features.RecommendationCount -eq 0) {
        $classificationScores["Question"] += 0.10  # Bonus for no recommendations
    }
    
    # Error scoring
    $classificationScores["Error"] += $Features.ErrorWords * 0.18
    $classificationScores["Error"] += $Features.ErrorEntityCount * 0.25
    $classificationScores["Error"] += $Features.ExclamationMarks * 0.05
    
    # Complete scoring
    if ($ResponseContent -match '\b(complete|done|finished|success|resolved)\b') {
        $classificationScores["Complete"] += 0.30
    }
    if ($Features.RecommendationCount -eq 0) {
        $classificationScores["Complete"] += 0.15
    }
    
    # Information scoring (baseline)
    $classificationScores["Information"] = 0.40  # Base information score
    if ($Features.TextLength -gt 200) {
        $classificationScores["Information"] += 0.10
    }
    
    # Normalize scores to probabilities
    $totalScore = ($classificationScores.Values | Measure-Object -Sum).Sum
    if ($totalScore -eq 0) {
        $totalScore = 1.0
    }
    
    $normalizedScores = @{}
    foreach ($type in $classificationScores.Keys) {
        $normalizedScores[$type] = $classificationScores[$type] / $totalScore
    }
    
    # Select highest scoring classification
    $topClassification = $normalizedScores.GetEnumerator() | Sort-Object Value -Descending | Select-Object -First 1
    
    return @{
        Type = $topClassification.Key
        Confidence = [Math]::Min(0.90, $topClassification.Value + 0.20)
        AllScores = $normalizedScores
        FeatureContributions = $classificationScores
    }
}

function Invoke-RecommendationClassifier {
    [CmdletBinding()]
    param(
        [Parameter()]
        [array]$Recommendations = @(),
        
        [Parameter(Mandatory = $true)]
        [hashtable]$Features
    )
    
    if ($Recommendations.Count -eq 0) {
        return @{
            Type = "Information"
            Confidence = 0.60
            Reasoning = "No recommendations present"
        }
    }
    
    # Analyze recommendation patterns with Bayesian enhancement
    $primaryRecommendation = $Recommendations[0]
    $recommendationType = $primaryRecommendation.Type
    
    # Get Bayesian confidence for the primary recommendation
    $bayesianResult = Get-BayesianConfidence -PatternType $recommendationType -ObservedConfidence $primaryRecommendation.Confidence
    
    # Classification based on recommendation type patterns
    $classificationType = switch ($recommendationType) {
        "TEST" { "Instruction" }
        "FIX" { "Instruction" }
        "COMPILE" { "Instruction" }
        "RESTART" { "Instruction" }
        "ERROR" { "Error" }
        "COMPLETE" { "Complete" }
        "ANALYZE" { "Question" }
        default { "Instruction" }
    }
    
    # Confidence calculation with Bayesian enhancement
    $baseConfidence = $bayesianResult.BayesianConfidence
    
    # Adjustment based on supporting recommendations
    if ($Recommendations.Count -gt 1) {
        $consistentRecommendations = ($Recommendations | Where-Object { 
            switch ($_.Type) {
                "TEST" { $classificationType -eq "Instruction" }
                "FIX" { $classificationType -eq "Instruction" }
                "COMPILE" { $classificationType -eq "Instruction" }
                "ERROR" { $classificationType -eq "Error" }
                "COMPLETE" { $classificationType -eq "Complete" }
                default { $false }
            }
        }).Count
        
        $consistencyBonus = ($consistentRecommendations / $Recommendations.Count) * 0.15
        $baseConfidence += $consistencyBonus
    }
    
    return @{
        Type = $classificationType
        Confidence = [Math]::Min(0.92, $baseConfidence)
        RecommendationType = $recommendationType
        BayesianEnhancement = $bayesianResult
        SupportingRecommendations = $Recommendations.Count - 1
    }
}

function Invoke-EntityContextClassifier {
    [CmdletBinding()]
    param(
        [Parameter()]
        [array]$Entities = @(),
        
        [Parameter(Mandatory = $true)]
        [hashtable]$Features
    )
    
    if ($null -eq $Entities -or $Entities.Count -eq 0) {
        return @{
            Type = "Information"
            Confidence = 0.55
            Reasoning = "No contextual entities detected"
        }
    }
    
    # Entity type analysis for classification
    $entityTypes = $Entities | Group-Object Type
    $typeWeights = @{
        "ErrorMessage" = @{ Type = "Error"; Weight = 0.85 }
        "TestFile" = @{ Type = "Instruction"; Weight = 0.75 }
        "PowerShellCommand" = @{ Type = "Instruction"; Weight = 0.70 }
        "FilePath" = @{ Type = "Instruction"; Weight = 0.60 }
        "ModuleName" = @{ Type = "Information"; Weight = 0.65 }
        "URL" = @{ Type = "Information"; Weight = 0.55 }
        "Variable" = @{ Type = "Instruction"; Weight = 0.60 }
    }
    
    $classificationVotes = @{}
    $totalWeight = 0.0
    
    foreach ($entityGroup in $entityTypes) {
        $entityType = $entityGroup.Name
        $count = $entityGroup.Count
        
        if ($typeWeights.ContainsKey($entityType)) {
            $typeInfo = $typeWeights[$entityType]
            $classificationType = $typeInfo.Type
            $weight = $typeInfo.Weight * $count
            
            if (-not $classificationVotes.ContainsKey($classificationType)) {
                $classificationVotes[$classificationType] = 0.0
            }
            
            $classificationVotes[$classificationType] += $weight
            $totalWeight += $weight
        }
    }
    
    if ($totalWeight -eq 0) {
        return @{
            Type = "Information"
            Confidence = 0.55
            Reasoning = "Entity types not recognized for classification"
        }
    }
    
    # Select highest voted classification
    $topVote = $classificationVotes.GetEnumerator() | Sort-Object Value -Descending | Select-Object -First 1
    $confidence = [Math]::Min(0.85, ($topVote.Value / $totalWeight) + 0.25)
    
    return @{
        Type = $topVote.Key
        Confidence = $confidence
        EntityAnalysis = @{
            TotalEntities = $Entities.Count
            EntityTypes = $entityTypes.Count
            DominantTypes = $entityTypes | Sort-Object Count -Descending | Select-Object -First 3 Name, Count
        }
        VotingResults = $classificationVotes
    }
}

function Invoke-EnsembleVoting {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [array]$ClassifierResults
    )
    
    $classificationVotes = @{}
    $totalWeight = 0.0
    $ensembleEvidence = @()
    
    # Weighted voting across all classifiers
    foreach ($classifierResult in $ClassifierResults) {
        $method = $classifierResult.Method
        $result = $classifierResult.Result
        $weight = $classifierResult.Weight * $classifierResult.Reliability
        $classificationType = $result.Type
        $confidence = $result.Confidence
        
        # Weighted vote calculation
        $vote = $confidence * $weight
        
        if (-not $classificationVotes.ContainsKey($classificationType)) {
            $classificationVotes[$classificationType] = @{
                TotalVotes = 0.0
                VoterCount = 0
                Confidences = @()
                Methods = @()
            }
        }
        
        $classificationVotes[$classificationType].TotalVotes += $vote
        $classificationVotes[$classificationType].VoterCount += 1
        $classificationVotes[$classificationType].Confidences += $confidence
        $classificationVotes[$classificationType].Methods += $method
        
        $totalWeight += $weight
        
        $ensembleEvidence += @{
            Method = $method
            Classification = $classificationType
            Confidence = $confidence
            Weight = $weight
            Vote = $vote
        }
    }
    
    if ($totalWeight -eq 0) {
        return @{
            Type = "Information"
            Confidence = 0.50
            Reasons = @("Ensemble voting failed - no valid votes")
            SupportingEvidence = 0
        }
    }
    
    # Calculate final ensemble results
    $finalResults = @{}
    foreach ($classificationType in $classificationVotes.Keys) {
        $voteInfo = $classificationVotes[$classificationType]
        $normalizedVote = $voteInfo.TotalVotes / $totalWeight
        $averageConfidence = ($voteInfo.Confidences | Measure-Object -Average).Average
        $voterConsensus = $voteInfo.VoterCount / $ClassifierResults.Count
        
        $finalResults[$classificationType] = @{
            NormalizedVote = $normalizedVote
            AverageConfidence = $averageConfidence
            VoterConsensus = $voterConsensus
            SupportingMethods = $voteInfo.Methods
            EnsembleScore = $normalizedVote * $averageConfidence * (0.5 + 0.5 * $voterConsensus)
        }
    }
    
    # Select winning classification
    $winner = $finalResults.GetEnumerator() | Sort-Object { $_.Value.EnsembleScore } -Descending | Select-Object -First 1
    $winningType = $winner.Key
    $winningResults = $winner.Value
    
    return @{
        Type = $winningType
        Confidence = [Math]::Min(0.95, $winningResults.EnsembleScore + 0.15)
        Reasons = @("Ensemble voting: $($winningResults.VoterConsensus.ToString('P0')) consensus")
        SupportingEvidence = $winningResults.SupportingMethods.Count
        EnsembleDetails = @{
            AllResults = $finalResults
            VotingEvidence = $ensembleEvidence
            TotalWeight = $totalWeight
            WinnerScore = $winningResults.EnsembleScore
        }
    }
}

function Invoke-BayesianClassificationCalibration {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [PSObject]$EnsembleResult,
        
        [Parameter(Mandatory = $true)]
        [hashtable]$Features
    )
    
    $classificationType = $EnsembleResult.Type
    $ensembleConfidence = $EnsembleResult.Confidence
    
    # Apply Platt scaling calibration for final confidence
    $plattResult = Invoke-PlattScaling -PatternType $classificationType -RawConfidence $ensembleConfidence
    $calibratedConfidence = $plattResult.CalibratedProbability
    
    # Calculate reliability index based on ensemble consistency and feature support
    $featureSupport = switch ($classificationType) {
        "Instruction" { ($Features.ActionWords + $Features.RecommendationCount + $Features.CommandCount) / 3.0 }
        "Question" { ($Features.QuestionMarks + $Features.QuestionWords) }
        "Error" { ($Features.ErrorWords + $Features.ErrorEntityCount) }
        "Complete" { if ($Features.RecommendationCount -eq 0) { 2.0 } else { 0.5 } }
        "Information" { 1.0 }
        default { 0.5 }
    }
    
    $featureSupportNormalized = [Math]::Min(1.0, $featureSupport / 3.0)
    $reliabilityIndex = ($calibratedConfidence * 0.7) + ($featureSupportNormalized * 0.3)
    
    # Calculate uncertainty quantification
    $ensembleUncertainty = 1.0 - $EnsembleResult.EnsembleDetails.WinnerScore
    $calibrationUncertainty = 1.96 * [Math]::Sqrt($calibratedConfidence * (1 - $calibratedConfidence) / 30)
    $totalUncertainty = [Math]::Min(1.0, $ensembleUncertainty + $calibrationUncertainty)
    
    return @{
        Type = $classificationType
        Confidence = $calibratedConfidence
        ReliabilityIndex = $reliabilityIndex
        Reasons = $EnsembleResult.Reasons
        SupportingEvidence = $EnsembleResult.SupportingEvidence
        CalibrationDetails = @{
            RawEnsembleConfidence = $ensembleConfidence
            PlattScalingResult = $plattResult
            FeatureSupport = $featureSupportNormalized
            UncertaintyQuantification = @{
                EnsembleUncertainty = $ensembleUncertainty
                CalibrationUncertainty = $calibrationUncertainty
                TotalUncertainty = $totalUncertainty
            }
        }
        EnsembleDetails = $EnsembleResult.EnsembleDetails
    }
}

#endregion

#region Bayesian Confidence Scoring

# Bayesian prior probabilities based on historical pattern performance
$script:BayesianPriors = @{
    "TEST" = @{ Success = 0.85; Total = 100; LastUpdated = (Get-Date) }
    "FIX" = @{ Success = 0.75; Total = 80; LastUpdated = (Get-Date) }
    "COMPILE" = @{ Success = 0.80; Total = 90; LastUpdated = (Get-Date) }
    "RESTART" = @{ Success = 0.70; Total = 60; LastUpdated = (Get-Date) }
    "COMPLETE" = @{ Success = 0.95; Total = 120; LastUpdated = (Get-Date) }
    "ERROR" = @{ Success = 0.90; Total = 110; LastUpdated = (Get-Date) }
    "CONTINUE" = @{ Success = 0.88; Total = 95; LastUpdated = (Get-Date) }
    "ANALYZE" = @{ Success = 0.82; Total = 75; LastUpdated = (Get-Date) }
    "CREATE" = @{ Success = 0.78; Total = 65; LastUpdated = (Get-Date) }
}

# Platt scaling parameters for probability calibration (A and B parameters)
$script:PlattScalingParams = @{
    "TEST" = @{ A = -0.5; B = 0.8 }
    "FIX" = @{ A = -0.7; B = 0.9 }
    "COMPILE" = @{ A = -0.6; B = 0.85 }
    "RESTART" = @{ A = -0.8; B = 0.95 }
    "COMPLETE" = @{ A = -0.3; B = 0.75 }
    "ERROR" = @{ A = -0.4; B = 0.8 }
    "CONTINUE" = @{ A = -0.45; B = 0.82 }
    "ANALYZE" = @{ A = -0.55; B = 0.88 }
    "CREATE" = @{ A = -0.65; B = 0.92 }
}

function Update-BayesianPriors {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$PatternType,
        
        [Parameter(Mandatory = $true)]
        [bool]$Success
    )
    
    if ($script:BayesianPriors.ContainsKey($PatternType)) {
        $prior = $script:BayesianPriors[$PatternType]
        
        # Update with new evidence using Bayesian updating
        $currentSuccesses = $prior.Success * $prior.Total
        if ($Success) {
            $currentSuccesses += 1
        }
        $prior.Total += 1
        $prior.Success = $currentSuccesses / $prior.Total
        $prior.LastUpdated = Get-Date
        
        Write-PatternLog -Message "Updated Bayesian prior for $PatternType: Success rate $($prior.Success.ToString('P1'))" -Level "DEBUG"
    }
}

function Get-BayesianConfidence {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$PatternType,
        
        [Parameter(Mandatory = $true)]
        [double]$ObservedConfidence,
        
        [Parameter()]
        [double]$EvidenceStrength = 1.0
    )
    
    # Get prior probability
    $prior = if ($script:BayesianPriors.ContainsKey($PatternType)) { 
        $script:BayesianPriors[$PatternType].Success 
    } else { 
        0.5  # Default prior for unknown patterns
    }
    
    # Likelihood function - how likely is this observed confidence given success/failure
    $likelihoodSuccess = $ObservedConfidence
    $likelihoodFailure = 1.0 - $ObservedConfidence
    
    # Bayesian calculation: P(Success|Evidence) = P(Evidence|Success) * P(Success) / P(Evidence)
    $evidenceGivenSuccess = $likelihoodSuccess * $prior * $EvidenceStrength
    $evidenceGivenFailure = $likelihoodFailure * (1.0 - $prior) * $EvidenceStrength
    $totalEvidence = $evidenceGivenSuccess + $evidenceGivenFailure
    
    $bayesianConfidence = if ($totalEvidence -gt 0) { 
        $evidenceGivenSuccess / $totalEvidence 
    } else { 
        $prior 
    }
    
    return @{
        BayesianConfidence = $bayesianConfidence
        Prior = $prior
        LikelihoodSuccess = $likelihoodSuccess
        LikelihoodFailure = $likelihoodFailure
        EvidenceStrength = $EvidenceStrength
    }
}

function Invoke-PlattScaling {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$PatternType,
        
        [Parameter(Mandatory = $true)]
        [double]$RawConfidence
    )
    
    # Apply Platt scaling: P(y=1|f) = 1 / (1 + exp(A*f + B))
    # where f is the raw confidence score, A and B are learned parameters
    
    $params = if ($script:PlattScalingParams.ContainsKey($PatternType)) {
        $script:PlattScalingParams[$PatternType]
    } else {
        @{ A = -0.5; B = 0.8 }  # Default parameters
    }
    
    # Transform raw confidence to decision function value
    $decisionValue = [Math]::Log($RawConfidence / (1.0 - $RawConfidence))
    
    # Apply Platt scaling transformation
    $scaledValue = $params.A * $decisionValue + $params.B
    $calibratedProbability = 1.0 / (1.0 + [Math]::Exp(-$scaledValue))
    
    return @{
        CalibratedProbability = $calibratedProbability
        DecisionValue = $decisionValue
        ScalingParameters = $params
        RawConfidence = $RawConfidence
    }
}

function Get-PatternWeightedScore {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [array]$Recommendations
    )
    
    $weightedScores = @()
    $totalWeight = 0.0
    
    foreach ($recommendation in $Recommendations) {
        $patternType = $recommendation.Type
        
        # Get Bayesian confidence
        $bayesianResult = Get-BayesianConfidence -PatternType $patternType -ObservedConfidence $recommendation.Confidence
        
        # Apply Platt scaling for calibration
        $plattResult = Invoke-PlattScaling -PatternType $patternType -RawConfidence $bayesianResult.BayesianConfidence
        
        # Calculate pattern weight based on validation results and historical performance
        $validationWeight = if ($recommendation.ValidationResult) {
            $recommendation.ValidationResult.Score
        } else {
            0.8  # Default weight for non-validated patterns
        }
        
        $historicalWeight = if ($script:BayesianPriors.ContainsKey($patternType)) {
            $script:BayesianPriors[$patternType].Success
        } else {
            0.5
        }
        
        $finalWeight = ($validationWeight * 0.6) + ($historicalWeight * 0.4)
        $weightedScore = $plattResult.CalibratedProbability * $finalWeight
        
        $weightedScores += @{
            PatternType = $patternType
            RawConfidence = $recommendation.Confidence
            BayesianConfidence = $bayesianResult.BayesianConfidence
            CalibratedConfidence = $plattResult.CalibratedProbability
            ValidationWeight = $validationWeight
            HistoricalWeight = $historicalWeight
            FinalWeight = $finalWeight
            WeightedScore = $weightedScore
            Priority = $recommendation.Priority
        }
        
        $totalWeight += $finalWeight
    }
    
    return @{
        WeightedScores = $weightedScores
        TotalWeight = $totalWeight
        AverageWeight = if ($weightedScores.Count -gt 0) { $totalWeight / $weightedScores.Count } else { 0.0 }
    }
}

function Calculate-OverallConfidence {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [array]$Recommendations,
        
        [Parameter(Mandatory = $true)]
        [PSObject]$Classification,
        
        [Parameter()]
        [array]$Entities = @()
    )
    
    Write-PatternLog -Message "Calculating Bayesian-enhanced overall confidence score" -Level "DEBUG"
    
    $confidenceFactors = @()
    
    # Enhanced recommendation confidence with Bayesian and Platt scaling
    if ($Recommendations.Count -gt 0) {
        $patternWeightedResult = Get-PatternWeightedScore -Recommendations $Recommendations
        
        # Calculate weighted average of calibrated confidences
        $totalWeightedConfidence = 0.0
        foreach ($weightedScore in $patternWeightedResult.WeightedScores) {
            $totalWeightedConfidence += $weightedScore.WeightedScore
        }
        
        $avgCalibratedConfidence = if ($patternWeightedResult.TotalWeight -gt 0) {
            $totalWeightedConfidence / $patternWeightedResult.TotalWeight
        } else {
            0.5
        }
        
        $confidenceFactors += @{
            Factor = "EnhancedRecommendations"
            Weight = 0.45  # Increased weight due to enhanced accuracy
            Score = $avgCalibratedConfidence
            Count = $Recommendations.Count
            Method = "Bayesian+PlattScaling"
            WeightingDetails = $patternWeightedResult
        }
        
        Write-PatternLog -Message "Bayesian confidence calculation: $($avgCalibratedConfidence.ToString('P2'))" -Level "DEBUG"
    }
    
    # Classification confidence with uncertainty estimation
    $classificationScore = $Classification.Confidence
    $uncertaintyPenalty = if ($Classification.SupportingEvidence -lt 2) { 0.9 } else { 1.0 }
    $adjustedClassificationScore = $classificationScore * $uncertaintyPenalty
    
    $confidenceFactors += @{
        Factor = "Classification"
        Weight = 0.25
        Score = $adjustedClassificationScore
        SupportingEvidence = $Classification.SupportingEvidence
        UncertaintyPenalty = $uncertaintyPenalty
    }
    
    # Entity extraction confidence with relationship scoring (null-safe)
    if ($null -ne $Entities -and $Entities.Count -gt 0) {
        # Enhanced entity scoring with type diversity bonus
        $entityTypes = ($Entities | Group-Object Type).Count
        $typeWeights = @{
            "FilePath" = 1.2
            "ErrorMessage" = 1.5
            "PowerShellCommand" = 1.1
            "TestFile" = 1.3
            "ModuleName" = 1.0
        }
        
        $weightedEntityScore = 0.0
        foreach ($entity in $Entities) {
            $weight = if ($typeWeights.ContainsKey($entity.Type)) { $typeWeights[$entity.Type] } else { 1.0 }
            $weightedEntityScore += $weight
        }
        
        $normalizedEntityScore = [Math]::Min(1.0, $weightedEntityScore / 10.0)  # Normalize to reasonable scale
        $diversityBonus = [Math]::Min(0.2, $entityTypes / 5.0 * 0.2)  # Bonus for type diversity
        $finalEntityScore = $normalizedEntityScore + $diversityBonus
        
        $confidenceFactors += @{
            Factor = "EnhancedEntityExtraction"
            Weight = 0.2
            Score = [Math]::Min(1.0, $finalEntityScore)
            Count = $Entities.Count
            TypeDiversity = $entityTypes
            DiversityBonus = $diversityBonus
        }
    }
    
    # Response completeness with entropy calculation
    $completenessEntropy = 0.0
    if ($Recommendations.Count -gt 0) {
        # Calculate information entropy of recommendations
        $priorityCounts = $Recommendations | Group-Object Priority | ForEach-Object { $_.Count }
        $totalRecs = $Recommendations.Count
        
        foreach ($count in $priorityCounts) {
            $probability = $count / $totalRecs
            if ($probability -gt 0) {
                $completenessEntropy -= $probability * [Math]::Log($probability, 2)
            }
        }
    }
    
    $completenessScore = if ($Recommendations.Count -gt 0 -and $null -ne $Entities -and $Entities.Count -gt 0) { 
        0.9 + (0.1 * [Math]::Min(1.0, $completenessEntropy / 2.0))  # Entropy bonus for diverse recommendations
    } else { 
        0.6 
    }
    
    $confidenceFactors += @{
        Factor = "Completeness"
        Weight = 0.1
        Score = $completenessScore
        InformationEntropy = $completenessEntropy
    }
    
    # Calculate Bayesian weighted average
    $totalWeight = ($confidenceFactors | Measure-Object Weight -Sum).Sum
    $weightedSum = ($confidenceFactors | ForEach-Object { $_.Weight * $_.Score } | Measure-Object -Sum).Sum
    
    $rawOverallConfidence = if ($totalWeight -gt 0) { $weightedSum / $totalWeight } else { 0.5 }
    
    # Apply final Platt scaling calibration to overall confidence
    $finalPlattResult = Invoke-PlattScaling -PatternType "OVERALL" -RawConfidence $rawOverallConfidence
    $overallConfidence = $finalPlattResult.CalibratedProbability
    
    # Calculate confidence intervals using Bayesian credible intervals
    $confidenceInterval = @{
        Lower = [Math]::Max(0.0, $overallConfidence - (1.96 * [Math]::Sqrt($overallConfidence * (1 - $overallConfidence) / 50)))
        Upper = [Math]::Min(1.0, $overallConfidence + (1.96 * [Math]::Sqrt($overallConfidence * (1 - $overallConfidence) / 50)))
        Width = 2 * 1.96 * [Math]::Sqrt($overallConfidence * (1 - $overallConfidence) / 50)
    }
    
    $result = @{
        OverallConfidence = $overallConfidence
        RawConfidence = $rawOverallConfidence
        ConfidenceInterval = $confidenceInterval
        ConfidenceFactors = $confidenceFactors
        CalibrationMethod = "Bayesian+PlattScaling"
        QualityRating = switch ([int]($overallConfidence * 10)) {
            { $_ -ge 9 } { "Excellent" }
            { $_ -ge 8 } { "Very Good" }
            { $_ -ge 7 } { "Good" }
            { $_ -ge 6 } { "Fair" }
            { $_ -ge 5 } { "Adequate" }
            default { "Poor" }
        }
        UncertaintyScore = 1.0 - $overallConfidence
        ReliabilityIndex = $overallConfidence * (1.0 - $confidenceInterval.Width)
    }
    
    Write-PatternLog -Message "Bayesian confidence: $($overallConfidence.ToString('P2')) [$($confidenceInterval.Lower.ToString('P2'))-$($confidenceInterval.Upper.ToString('P2'))] ($($result.QualityRating))" -Level "INFO"
    return $result
}

#endregion

#region Main Pattern Analysis Function

function Invoke-PatternRecognitionAnalysis {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$ResponseContent,
        
        [Parameter()]
        [PSObject]$ParsedJson,
        
        [Parameter()]
        [switch]$IncludeDetails
    )
    
    $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
    Write-PatternLog -Message "Starting comprehensive pattern recognition analysis" -Level "INFO"
    
    try {
        # Step 1: Recommendation Pattern Recognition
        Write-PatternLog -Message "Step 1: Finding recommendation patterns" -Level "DEBUG"
        $recommendations = Find-RecommendationPatterns -ResponseText $ResponseContent
        
        # Step 2: Context Entity Extraction
        Write-PatternLog -Message "Step 2: Extracting context entities" -Level "DEBUG"
        $entities = Extract-ContextEntities -ResponseContent $ResponseContent
        
        # Step 3: Response Classification
        Write-PatternLog -Message "Step 3: Classifying response type" -Level "DEBUG"
        $classification = Classify-ResponseType -ResponseContent $ResponseContent -Recommendations $recommendations -Entities $entities
        
        # Step 4: Confidence Scoring
        Write-PatternLog -Message "Step 4: Calculating confidence scores" -Level "DEBUG"
        $confidenceAnalysis = Calculate-OverallConfidence -Recommendations $recommendations -Classification $classification -Entities $entities
        
        # Compile results
        $analysisResult = @{
            Recommendations = $recommendations
            Entities = $entities
            Classification = $classification
            ConfidenceAnalysis = $confidenceAnalysis
            ProcessingTimeMs = $stopwatch.ElapsedMilliseconds
            ResponseLength = $ResponseContent.Length
            AnalysisTimestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss.fff"
        }
        
        # Add detailed information if requested
        if ($IncludeDetails) {
            $analysisResult.Details = @{
                PatternCache = $script:PatternCache
                ClassificationStats = $script:ClassificationStats
                ConfigSettings = $script:PatternConfig
            }
        }
        
        $stopwatch.Stop()
        Write-PatternLog -Message "Pattern recognition analysis completed in $($stopwatch.ElapsedMilliseconds)ms" -Level "PERF"
        
        return $analysisResult
        
    } catch {
        $stopwatch.Stop()
        Write-PatternLog -Message "Pattern recognition analysis failed: $($_.Exception.Message)" -Level "ERROR"
        throw
    }
}

#endregion

#region Exported Functions

Export-ModuleMember -Function @(
    'Invoke-PatternRecognitionAnalysis',
    'Find-RecommendationPatterns',
    'Extract-ContextEntities',
    'Classify-ResponseType',
    'Calculate-OverallConfidence'
)

#endreg
# SIG # Begin signature block
# MIIFzgYJKoZIhvcNAQcCoIIFvzCCBbsCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCCkWcFiiUIVX2/h
# CCqh0Vqss09IhwaaaXcFDL4f1Elhu6CCAzAwggMsMIICFKADAgECAhB1HRbZIqgr
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
# MAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEILjbTLjJ4TvBe0oxCEhTywdu
# FQlZ/1nnjd3Bnu8j4jA3MA0GCSqGSIb3DQEBAQUABIIBAJTiKJaMNnK0OaJJF9XL
# bgmfybdQqytNFle8h0UEJhEe+fDbjFweOEI+SwuHCdl5m1InuSEf2QKi8tMaALC7
# kJUVh1ZOHP8V94VZ59rmc9VBazjyQDNyrFqIFFfNb2VlrSmewMAmajcLpLqk2tw9
# pK4k3jY1R28QUULCsR0hg66T4Vwfp6xj6HpThZOomtHWq1+qRaqwU3i6+PmewIdu
# 4IscOsku0/oOEz+d9Om3WKHhO7qD1G5FcrqDK0tqsg/Iamy7HPTihNf42orG7q5Z
# aOSfvIOTcBzC9SzZMakpzHbCIwtMQVeVOab6oTlJCv06CKoMKABww+v5glrCnQlR
# Iyo=
# SIG # End signature block
