# Classification.psm1
# Phase 2 Day 11: Enhanced Response Processing - Response Classification Engine
# Provides response type classification, intent detection, and sentiment analysis
# Date: 2025-08-18

#region Module Dependencies

# Import required modules
Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) "Core\AgentLogging.psm1") -Force

#endregion

#region Module Variables

# Classification decision tree structure
$script:ClassificationTree = @{
    "Root" = @{
        Condition = "Always"
        Children = @("ErrorDetection", "InstructionDetection", "QuestionDetection", "CompletionDetection", "InformationDefault")
    }
    
    "ErrorDetection" = @{
        Condition = "Contains error indicators"
        Patterns = @("error", "exception", "failed", "failure", "CS\d{4}", "issue", "problem")
        PatternWeights = @(0.3, 0.3, 0.4, 0.4, 0.9, 0.3, 0.3)  # CS\d{4} has highest weight
        Priority = 1
        Category = "Error"
        MinConfidence = 0.25
        Children = @()
    }
    
    "InstructionDetection" = @{
        Condition = "Contains command or instruction indicators"
        Patterns = @("RECOMMENDED:", "please", "you should", "try", "run", "execute", "install", "create", "update")
        PatternWeights = @(0.9, 0.6, 0.7, 0.5, 0.5, 0.5, 0.4, 0.4, 0.4)  # RECOMMENDED: has highest weight
        Priority = 2
        Category = "Instruction"
        MinConfidence = 0.4
        Children = @("HighConfidenceInstruction", "MediumConfidenceInstruction")
    }
    
    "HighConfidenceInstruction" = @{
        Condition = "High confidence instruction patterns"
        Patterns = @("RECOMMENDED:", "TEST -", "BUILD -", "ANALYZE -")
        PatternWeights = @(0.9, 0.8, 0.8, 0.8)  # All command patterns have high weight
        Priority = 1
        Category = "Instruction"
        MinConfidence = 0.5
        Children = @()
    }
    
    "MediumConfidenceInstruction" = @{
        Condition = "Medium confidence instruction patterns"
        Patterns = @("please", "you should", "try", "run")
        PatternWeights = @(0.6, 0.7, 0.5, 0.5)  # "you should" has highest weight
        Priority = 2
        Category = "Instruction"
        MinConfidence = 0.4
        Children = @()
    }
    
    "QuestionDetection" = @{
        Condition = "Contains question indicators"
        Patterns = @("\?", "what", "how", "why", "where", "when", "should", "could", "would")
        PatternWeights = @(0.9, 0.6, 0.6, 0.6, 0.6, 0.6, 0.4, 0.4, 0.4)  # ? has highest weight
        Priority = 3
        Category = "Question"
        MinConfidence = 0.4
        Children = @()
    }
    
    "CompletionDetection" = @{
        Condition = "Contains completion indicators"
        Patterns = @("completed", "finished", "done", "success", "successful", "resolved", "fixed")
        PatternWeights = @(0.8, 0.8, 0.7, 0.7, 0.7, 0.8, 0.8)  # All completion words have high weight
        Priority = 4
        Category = "Complete"
        MinConfidence = 0.4
        Children = @()
    }
    
    "InformationDefault" = @{
        Condition = "Default category for informational content"
        Patterns = @()
        Priority = 5
        Category = "Information"
        MinConfidence = 0.3
        Children = @()
    }
}

# Intent detection patterns
$script:IntentPatterns = @{
    "RequestHelp" = @{
        Patterns = @("help", "assist", "guide", "support", "need", "how to")
        Intent = "HelpRequest"
        Confidence = 0.8
    }
    
    "RequestInformation" = @{
        Patterns = @("what is", "explain", "describe", "tell me about", "information about")
        Intent = "InformationRequest"
        Confidence = 0.7
    }
    
    "RequestAction" = @{
        Patterns = @("please", "can you", "would you", "could you", "run", "execute")
        Intent = "ActionRequest"
        Confidence = 0.8
    }
    
    "ProvideUpdate" = @{
        Patterns = @("completed", "finished", "done", "updated", "fixed", "resolved")
        Intent = "StatusUpdate"
        Confidence = 0.7
    }
    
    "ReportError" = @{
        Patterns = @("error", "failed", "issue", "problem", "exception", "CS\d{4}")
        Intent = "ErrorReport"
        Confidence = 0.9
    }
}

# Sentiment analysis indicators
$script:SentimentIndicators = @{
    "Positive" = @{
        Terms = @("success", "working", "correct", "good", "excellent", "perfect", "fixed", "resolved", "completed")
        Weight = 1.0
    }
    
    "Negative" = @{
        Terms = @("error", "failed", "broken", "issue", "problem", "incorrect", "wrong", "bad")
        Weight = -1.0
    }
    
    "Neutral" = @{
        Terms = @("information", "note", "update", "change", "modify", "adjust", "consider")
        Weight = 0.0
    }
}

#endregion

#region Classification Functions

function Invoke-ResponseClassification {
    <#
    .SYNOPSIS
    Classifies Claude response using decision tree logic
    
    .DESCRIPTION
    Applies decision tree classification to determine response type and confidence
    
    .PARAMETER ResponseText
    The Claude response text to classify
    
    .PARAMETER UseAdvancedTree
    Whether to use the full decision tree or simplified classification
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$ResponseText,
        
        [switch]$UseAdvancedTree
    )
    
    Write-AgentLog "Starting response classification" -Level "DEBUG" -Component "Classification"
    
    try {
        $classification = @{
            Category = "Information"
            Confidence = 0.0
            Intent = "Unknown"
            Sentiment = "Neutral"
            SentimentScore = 0.0
            DecisionPath = @()
            MatchedPatterns = @()
        }
        
        Write-AgentLog "UseAdvancedTree parameter: $UseAdvancedTree" -Level "DEBUG" -Component "Classification"
        
        if ($UseAdvancedTree) {
            # Use full decision tree
            Write-AgentLog "Using advanced decision tree classification" -Level "DEBUG" -Component "Classification"
            $treeResult = Invoke-DecisionTreeClassification -ResponseText $ResponseText
            $classification.Category = $treeResult.Category
            $classification.Confidence = $treeResult.Confidence
            $classification.DecisionPath = $treeResult.DecisionPath
            Write-AgentLog "Advanced tree result: Category=$($treeResult.Category), Confidence=$($treeResult.Confidence)" -Level "DEBUG" -Component "Classification"
        } else {
            # Simplified classification
            Write-AgentLog "Using simplified classification" -Level "DEBUG" -Component "Classification"
            $simpleResult = Get-SimpleClassification -ResponseText $ResponseText
            $classification.Category = $simpleResult.Category
            $classification.Confidence = $simpleResult.Confidence
            $classification.DecisionPath = $simpleResult.DecisionPath
            Write-AgentLog "Simple classification result: Category=$($simpleResult.Category), Confidence=$($simpleResult.Confidence)" -Level "DEBUG" -Component "Classification"
        }
        
        # Detect intent
        $intentResult = Get-ResponseIntent -ResponseText $ResponseText
        $classification.Intent = $intentResult.Intent
        
        # Analyze sentiment
        $sentimentResult = Get-ResponseSentiment -ResponseText $ResponseText
        $classification.Sentiment = $sentimentResult.Sentiment
        $classification.SentimentScore = $sentimentResult.Score
        
        Write-AgentLog "Classification complete: $($classification.Category) (Confidence: $($classification.Confidence))" -Level "INFO" -Component "Classification"
        
        return @{
            Success = $true
            Classification = $classification
        }
    }
    catch {
        Write-AgentLog "Response classification failed: $_" -Level "ERROR" -Component "Classification"
        return @{
            Success = $false
            Error = $_.Exception.Message
        }
    }
}

function Invoke-DecisionTreeClassification {
    <#
    .SYNOPSIS
    Applies decision tree classification logic
    
    .DESCRIPTION
    Traverses the classification decision tree to determine response category
    
    .PARAMETER ResponseText
    The response text to classify
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$ResponseText
    )
    
    Write-AgentLog "Starting decision tree classification for text: $($ResponseText.Substring(0, [Math]::Min(50, $ResponseText.Length)))..." -Level "DEBUG" -Component "Classification"
    
    $result = @{
        Category = "Information"
        Confidence = 0.0
        DecisionPath = @()
        MatchedPatterns = @()
    }
    
    # Traverse decision tree
    $currentNodes = @($script:ClassificationTree["Root"].Children)
    $result.DecisionPath += "Root"
    
    # Convert to priority-ordered list (exclude InformationDefault from priority testing)
    $priorityNodes = @("ErrorDetection", "InstructionDetection", "QuestionDetection", "CompletionDetection")
    $defaultNode = "InformationDefault"
    
    Write-AgentLog "Decision tree using FIRST QUALIFYING MATCH logic (not best match)" -Level "DEBUG" -Component "Classification"
    Write-AgentLog "Priority order: $($priorityNodes -join ' -> ') -> $defaultNode" -Level "DEBUG" -Component "Classification"
    
    # Test priority nodes in order - use FIRST qualifying match, not best match
    $selectedNode = $null
    foreach ($nodeName in $priorityNodes) {
        if ($script:ClassificationTree.ContainsKey($nodeName)) {
            $node = $script:ClassificationTree[$nodeName]
            Write-AgentLog "Testing priority node: $nodeName (MinConfidence: $($node.MinConfidence))" -Level "DEBUG" -Component "Classification"
            
            $score = Test-NodeCondition -ResponseText $ResponseText -Node $node
            Write-AgentLog "Node $nodeName scored: $score (threshold: $($node.MinConfidence))" -Level "DEBUG" -Component "Classification"
            
            if ($score -ge $node.MinConfidence) {
                Write-AgentLog "FIRST QUALIFYING MATCH: $nodeName with score $score >= threshold $($node.MinConfidence)" -Level "DEBUG" -Component "Classification"
                $selectedNode = $nodeName
                $result.Category = $node.Category
                $result.Confidence = $score
                $result.DecisionPath += $nodeName
                break  # Stop on first qualifying match
            } else {
                Write-AgentLog "Node $nodeName failed threshold: $score < $($node.MinConfidence)" -Level "DEBUG" -Component "Classification"
            }
        }
    }
    
    # If no priority node qualified, use default
    if (-not $selectedNode) {
        Write-AgentLog "No priority nodes qualified, using default: $defaultNode" -Level "DEBUG" -Component "Classification"
        $defaultNodeObj = $script:ClassificationTree[$defaultNode]
        $result.Category = $defaultNodeObj.Category
        $result.Confidence = 0.5  # Fixed confidence for default, not 1.0
        $result.DecisionPath += $defaultNode
    }
    
    # Handle child nodes if selected node has children (preserved for future expansion)
    if ($selectedNode -and $script:ClassificationTree[$selectedNode].Children.Count -gt 0) {
        Write-AgentLog "Selected node has children, could extend traversal" -Level "DEBUG" -Component "Classification"
        # For now, stop at first level - can extend later if needed
    }
    
    Write-AgentLog "Decision tree traversal complete: $($result.DecisionPath -join ' -> ')" -Level "DEBUG" -Component "Classification"
    Write-AgentLog "Final result: Category=$($result.Category), Confidence=$($result.Confidence)" -Level "INFO" -Component "Classification"
    
    return $result
}

function Test-NodeCondition {
    <#
    .SYNOPSIS
    Tests if response text matches node conditions
    
    .DESCRIPTION
    Evaluates response text against node patterns and returns confidence score using weighted matching
    
    .PARAMETER ResponseText
    The response text to test
    
    .PARAMETER Node
    The decision tree node to test against
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$ResponseText,
        
        [Parameter(Mandatory = $true)]
        [hashtable]$Node
    )
    
    Write-AgentLog "Testing node condition: $($Node.Condition)" -Level "DEBUG" -Component "Classification"
    
    if ($Node.Patterns.Count -eq 0) {
        Write-AgentLog "  No patterns to test, returning 1.0" -Level "DEBUG" -Component "Classification"
        return 1.0  # Always match for default nodes
    }
    
    $totalWeight = 0.0
    $matchedWeight = 0.0
    $hasWeights = $Node.ContainsKey("PatternWeights") -and $Node.PatternWeights.Count -eq $Node.Patterns.Count
    
    Write-AgentLog "  Testing $($Node.Patterns.Count) patterns, HasWeights: $hasWeights" -Level "DEBUG" -Component "Classification"
    
    for ($i = 0; $i -lt $Node.Patterns.Count; $i++) {
        $pattern = $Node.Patterns[$i]
        $weight = if ($hasWeights) { $Node.PatternWeights[$i] } else { 1.0 }
        $totalWeight += $weight
        
        # Test pattern - handle regex patterns properly
        $matched = $false
        if ($pattern -match "\\d") {
            # Regex pattern (like CS\d{4})
            $matched = $ResponseText -match $pattern
        } else {
            # Simple word pattern
            $matched = $ResponseText -match "\b$pattern\b"
        }
        
        if ($matched) {
            $matchedWeight += $weight
            Write-AgentLog "    MATCH: Pattern '$pattern' (weight: $weight)" -Level "DEBUG" -Component "Classification"
        } else {
            Write-AgentLog "    NO MATCH: Pattern '$pattern'" -Level "DEBUG" -Component "Classification"
        }
    }
    
    $confidence = if ($totalWeight -gt 0) { $matchedWeight / $totalWeight } else { 0 }
    $confidence = [Math]::Round($confidence, 2)
    
    Write-AgentLog "  Node result: $confidence confidence (matched weight: $matchedWeight, total weight: $totalWeight)" -Level "DEBUG" -Component "Classification"
    
    return $confidence
}

function Get-ResponseIntent {
    <#
    .SYNOPSIS
    Detects the intent of the Claude response
    
    .DESCRIPTION
    Analyzes response text to determine the user's likely intent
    
    .PARAMETER ResponseText
    The response text to analyze
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$ResponseText
    )
    
    $bestIntent = "Unknown"
    $bestConfidence = 0.0
    $matchedPatterns = @()
    
    foreach ($intentName in $script:IntentPatterns.Keys) {
        $intent = $script:IntentPatterns[$intentName]
        $patternMatches = 0
        
        foreach ($pattern in $intent.Patterns) {
            if ($ResponseText -match "\b$pattern\b") {
                $patternMatches++
                $matchedPatterns += @{
                    Intent = $intentName
                    Pattern = $pattern
                    Confidence = $intent.Confidence
                }
            }
        }
        
        if ($patternMatches -gt 0) {
            $confidence = ($patternMatches / $intent.Patterns.Count) * $intent.Confidence
            if ($confidence -gt $bestConfidence) {
                $bestConfidence = $confidence
                $bestIntent = $intent.Intent
            }
        }
    }
    
    Write-AgentLog "Intent detected: $bestIntent (Confidence: $bestConfidence)" -Level "DEBUG" -Component "Classification"
    
    return @{
        Success = $true
        Intent = $bestIntent
        Confidence = [Math]::Round($bestConfidence, 2)
        MatchedPatterns = $matchedPatterns
    }
}

function Get-ResponseSentiment {
    <#
    .SYNOPSIS
    Analyzes sentiment of Claude response
    
    .DESCRIPTION
    Performs sentiment analysis to determine positive/negative/neutral tone
    
    .PARAMETER ResponseText
    The response text to analyze
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$ResponseText
    )
    
    $sentimentScore = 0.0
    $termCounts = @{
        Positive = 0
        Negative = 0
        Neutral = 0
    }
    
    # Count sentiment indicators
    foreach ($category in $script:SentimentIndicators.Keys) {
        foreach ($term in $script:SentimentIndicators[$category].Terms) {
            $matches = [regex]::Matches($ResponseText, "\b$term\b", [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)
            $termCounts[$category] += $matches.Count
            $sentimentScore += $matches.Count * $script:SentimentIndicators[$category].Weight
        }
    }
    
    # Normalize score
    $totalTerms = $termCounts.Positive + $termCounts.Negative + $termCounts.Neutral
    if ($totalTerms -gt 0) {
        $sentimentScore = $sentimentScore / $totalTerms
    }
    
    # Determine sentiment category
    $sentiment = if ($sentimentScore -gt 0.2) { "Positive" } 
                elseif ($sentimentScore -lt -0.2) { "Negative" } 
                else { "Neutral" }
    
    Write-AgentLog "Sentiment analysis: $sentiment (Score: $([Math]::Round($sentimentScore, 2)))" -Level "DEBUG" -Component "Classification"
    
    return @{
        Success = $true
        Sentiment = $sentiment
        Score = [Math]::Round($sentimentScore, 2)
        TermCounts = $termCounts
    }
}

function Get-SimpleClassification {
    <#
    .SYNOPSIS
    Provides simple classification without decision tree
    
    .DESCRIPTION
    Quick classification using basic pattern matching
    
    .PARAMETER ResponseText
    The response text to classify
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$ResponseText
    )
    
    # Simple rule-based classification
    if ($ResponseText -match "(?:error|exception|failed|failure|CS\d{4}|issue|problem)") {
        return @{
            Category = "Error"
            Confidence = 0.8
            DecisionPath = @("Simple", "ErrorPattern")
        }
    }
    elseif ($ResponseText -match "(?:RECOMMENDED:|please|you should|try|run|execute)") {
        return @{
            Category = "Instruction"
            Confidence = 0.7
            DecisionPath = @("Simple", "InstructionPattern")
        }
    }
    elseif ($ResponseText -match "\?") {
        return @{
            Category = "Question"
            Confidence = 0.6
            DecisionPath = @("Simple", "QuestionPattern")
        }
    }
    elseif ($ResponseText -match "(?:completed|finished|done|success|successful|resolved|fixed)") {
        return @{
            Category = "Complete"
            Confidence = 0.5
            DecisionPath = @("Simple", "CompletionPattern")
        }
    }
    else {
        return @{
            Category = "Information"
            Confidence = 0.4
            DecisionPath = @("Simple", "DefaultInformation")
        }
    }
}

function Get-ClassificationMetrics {
    <#
    .SYNOPSIS
    Gets classification performance metrics
    
    .DESCRIPTION
    Returns statistics about classification accuracy and performance
    
    .PARAMETER ClassificationHistory
    Historical classification results for analysis
    #>
    [CmdletBinding()]
    param(
        [array]$ClassificationHistory = @()
    )
    
    if ($ClassificationHistory.Count -eq 0) {
        return @{
            Success = $true
            Metrics = @{
                TotalClassifications = 0
                AverageConfidence = 0.0
                CategoryDistribution = @{}
                IntentDistribution = @{}
                SentimentDistribution = @{}
            }
        }
    }
    
    try {
        $metrics = @{
            TotalClassifications = $ClassificationHistory.Count
            AverageConfidence = 0.0
            CategoryDistribution = @{}
            IntentDistribution = @{}
            SentimentDistribution = @{}
        }
        
        # Calculate average confidence
        $confidenceSum = ($ClassificationHistory | Measure-Object -Property Confidence -Sum).Sum
        $metrics.AverageConfidence = [Math]::Round($confidenceSum / $ClassificationHistory.Count, 2)
        
        # Category distribution
        $categoryGroups = $ClassificationHistory | Group-Object -Property Category
        foreach ($group in $categoryGroups) {
            $percentage = [Math]::Round(($group.Count / $ClassificationHistory.Count) * 100, 1)
            $metrics.CategoryDistribution[$group.Name] = @{
                Count = $group.Count
                Percentage = $percentage
            }
        }
        
        # Intent distribution
        $intentGroups = $ClassificationHistory | Group-Object -Property Intent
        foreach ($group in $intentGroups) {
            $percentage = [Math]::Round(($group.Count / $ClassificationHistory.Count) * 100, 1)
            $metrics.IntentDistribution[$group.Name] = @{
                Count = $group.Count
                Percentage = $percentage
            }
        }
        
        # Sentiment distribution
        $sentimentGroups = $ClassificationHistory | Group-Object -Property Sentiment
        foreach ($group in $sentimentGroups) {
            $percentage = [Math]::Round(($group.Count / $ClassificationHistory.Count) * 100, 1)
            $metrics.SentimentDistribution[$group.Name] = @{
                Count = $group.Count
                Percentage = $percentage
            }
        }
        
        Write-AgentLog "Classification metrics calculated for $($ClassificationHistory.Count) entries" -Level "INFO" -Component "Classification"
        
        return @{
            Success = $true
            Metrics = $metrics
        }
    }
    catch {
        Write-AgentLog "Classification metrics calculation failed: $_" -Level "ERROR" -Component "Classification"
        return @{
            Success = $false
            Error = $_.Exception.Message
        }
    }
}

function Test-ClassificationEngine {
    <#
    .SYNOPSIS
    Tests the classification engine functionality
    
    .DESCRIPTION
    Validates classification capabilities using test cases
    #>
    [CmdletBinding()]
    param()
    
    Write-AgentLog "Testing classification engine" -Level "INFO" -Component "Classification"
    
    $testCases = @(
        @{
            Name = "Error Classification"
            Text = "CS0246: The type or namespace name could not be found"
            ExpectedCategory = "Error"
            ExpectedIntent = "ErrorReport"
            ExpectedSentiment = "Negative"
        },
        @{
            Name = "Instruction Classification"
            Text = "RECOMMENDED: TEST - Please run the validation script to check functionality"
            ExpectedCategory = "Instruction"
            ExpectedIntent = "ActionRequest"
            ExpectedSentiment = "Neutral"
        },
        @{
            Name = "Question Classification"
            Text = "What Unity version are you using? Could you provide more details?"
            ExpectedCategory = "Question"
            ExpectedIntent = "InformationRequest"
            ExpectedSentiment = "Neutral"
        },
        @{
            Name = "Completion Classification"
            Text = "The implementation was successful and all tests are now passing"
            ExpectedCategory = "Complete"
            ExpectedIntent = "StatusUpdate"
            ExpectedSentiment = "Positive"
        }
    )
    
    $testsPassed = 0
    $testsTotal = $testCases.Count
    
    foreach ($testCase in $testCases) {
        try {
            Write-AgentLog "Testing: $($testCase.Name)" -Level "DEBUG" -Component "Classification"
            
            $classificationResult = Invoke-ResponseClassification -ResponseText $testCase.Text -UseAdvancedTree
            
            if ($classificationResult.Success) {
                $classification = $classificationResult.Classification
                $categoryMatch = $classification.Category -eq $testCase.ExpectedCategory
                $intentMatch = $classification.Intent -eq $testCase.ExpectedIntent
                $sentimentMatch = $classification.Sentiment -eq $testCase.ExpectedSentiment
                
                if ($categoryMatch -and $intentMatch -and $sentimentMatch) {
                    Write-AgentLog "  PASS: $($testCase.Name)" -Level "DEBUG" -Component "Classification"
                    $testsPassed++
                } else {
                    Write-AgentLog "  FAIL: $($testCase.Name) - Category: $categoryMatch, Intent: $intentMatch, Sentiment: $sentimentMatch" -Level "WARNING" -Component "Classification"
                }
            } else {
                Write-AgentLog "  FAIL: $($testCase.Name) - Classification failed" -Level "WARNING" -Component "Classification"
            }
        }
        catch {
            Write-AgentLog "  ERROR: $($testCase.Name) - $_" -Level "ERROR" -Component "Classification"
        }
    }
    
    $successRate = [Math]::Round(($testsPassed / $testsTotal) * 100, 1)
    Write-AgentLog "Classification engine test completed: $testsPassed/$testsTotal ($successRate%)" -Level "SUCCESS" -Component "Classification"
    
    return @{
        Success = $testsPassed -eq $testsTotal
        TestsPassed = $testsPassed
        TestsTotal = $testsTotal
        SuccessRate = $successRate
    }
}

#endregion

# Export module functions
Export-ModuleMember -Function @(
    'Invoke-ResponseClassification',
    'Invoke-DecisionTreeClassification',
    'Test-NodeCondition',
    'Get-ResponseIntent',
    'Get-ResponseSentiment',
    'Get-SimpleClassification',
    'Get-ClassificationMetrics',
    'Test-ClassificationEngine'
)

Write-AgentLog "Classification module loaded successfully" -Level "INFO" -Component "Classification"
# SIG # Begin signature block
# MIIFqQYJKoZIhvcNAQcCoIIFmjCCBZYCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQU8dQzamNCIU+eVbbP+kJZWOF0
# CsCgggMwMIIDLDCCAhSgAwIBAgIQdR0W2SKoK5VE8JId4ZxrRTANBgkqhkiG9w0B
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
# CQQxFgQUmKHFYjTlRxClLXRWgVCBFjpgmwUwDQYJKoZIhvcNAQEBBQAEggEAhqXz
# 0rKcBmVlNb2xsUM1+LJeVD8Mc+/2qnepq/pvTGVIOzMkCRuZxXqExifH8+nWyR1i
# D6g/0G2NcdxtkIkTn4vrapU+bm7gyADRZf51Fx9JQp6bFKwBs8n9ppFBWAFnmDB9
# hioHRR9SzeNHqPKlPC4DnpKMiWhuAKtLwMbDHjyFi0SRpzdoJ4Co/nOvlKpa5Lgz
# KlPnpYi5QMnIHtzJ04TYdjvlIIQEw6o/nEqNexx1fKOYUGL9dMJ9dR9BiSqHtHaX
# cI8WmhF4f0LtJ35r1txMU0p4BXyxWmcegEqlmZwLJl4N3LbL4/RS31vw97Xe1SMw
# lqYAtqvsVr8+zY+JiA==
# SIG # End signature block
