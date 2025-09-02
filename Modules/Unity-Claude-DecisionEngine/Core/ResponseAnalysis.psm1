# ResponseAnalysis.psm1
# Advanced Response Analysis for Decision Engine
# Part of the refactored Unity-Claude-DecisionEngine module

# Import core module for shared functions
$corePath = Join-Path $PSScriptRoot "DecisionEngineCore.psm1"
if (Test-Path $corePath) {
    Import-Module $corePath -Force -DisableNameChecking
}

#region Hybrid Response Analysis

function Invoke-HybridResponseAnalysis {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$ResponseText,
        
        [Parameter()]
        [hashtable]$Context = @{}
    )
    
    Write-DecisionEngineLog -Message "Starting hybrid response analysis" -Level "DEBUG"
    
    $analysisResult = @{
        Timestamp = Get-Date
        ResponseText = $ResponseText
        Method = "Hybrid"
        Confidence = 0.0
        Intent = "UNKNOWN"
        Entities = @{}
        Actions = @()
        Recommendations = @()
        SemanticContext = @{}
    }
    
    try {
        # Step 1: Regex-based analysis (fast, deterministic)
        $regexResult = Invoke-RegexBasedAnalysis -ResponseText $ResponseText
        $analysisResult.RegexAnalysis = $regexResult
        
        # Step 2: AI-enhanced analysis if enabled
        if ($script:DecisionEngineConfig.EnableAIEnhancement) {
            $aiResult = Invoke-AIEnhancedAnalysis -ResponseText $ResponseText -Context $Context
            $analysisResult.AIAnalysis = $aiResult
            
            # Merge results with weighted confidence
            $analysisResult = Merge-AnalysisResults -RegexResult $regexResult -AIResult $aiResult
        } else {
            $analysisResult = $regexResult
        }
        
        # Step 3: Contextual enrichment
        $analysisResult = Add-ContextualEnrichment -Analysis $analysisResult -Context $Context
        
        Write-DecisionEngineLog -Message "Analysis complete. Confidence: $($analysisResult.Confidence)" -Level "INFO"
        
    } catch {
        Write-DecisionEngineLog -Message "Analysis error: $_" -Level "ERROR"
        $analysisResult.Error = $_.Exception.Message
        $analysisResult.Confidence = 0.0
    }
    
    return $analysisResult
}

#endregion

#region Regex-Based Analysis

function Invoke-RegexBasedAnalysis {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$ResponseText
    )
    
    Write-DecisionEngineLog -Message "Performing regex-based analysis" -Level "DEBUG"
    
    $result = @{
        Intent = "UNKNOWN"
        Confidence = 0.5
        Entities = @{}
        Actions = @()
        Patterns = @()
    }
    
    # Intent classification patterns
    $intentPatterns = @{
        "RECOMMENDATION" = @("I (suggest|recommend|propose|advise)", "You (should|could|might want to)", "Consider", "It would be (good|better|best)")
        "ERROR" = @("error|exception|failed|failure", "cannot|unable to", "invalid|incorrect")
        "SUCCESS" = @("success|successful|complete|completed", "done|finished", "working|works")
        "CLARIFICATION" = @("What (do you mean|are you asking)", "Could you (clarify|explain)", "I need more (information|details)")
        "EXECUTE" = @("I'll|I will", "Let me", "Running|Executing|Processing", "Starting|Beginning")
    }
    
    foreach ($intent in $intentPatterns.Keys) {
        foreach ($pattern in $intentPatterns[$intent]) {
            if ($ResponseText -match $pattern) {
                $result.Intent = $intent
                $result.Confidence = [Math]::Min($result.Confidence + 0.2, 1.0)
                $result.Patterns += $pattern
                Write-DecisionEngineLog -Message "Pattern match: $intent - $pattern" -Level "DEBUG"
            }
        }
    }
    
    # Entity extraction patterns
    $entityPatterns = @{
        "FilePath" = '(?:[A-Za-z]:\\|\\\\|\/)[^<>:"|?*\n\r]+\.[a-zA-Z]{2,4}'
        "ClassName" = '\b[A-Z][a-zA-Z0-9_]*(?:\.[A-Z][a-zA-Z0-9_]*)*\b'
        "FunctionName" = '\b[a-z][a-zA-Z0-9_]*\s*\('
        "ErrorCode" = '\b(?:0x[0-9A-F]+|[A-Z][0-9]{3,})\b'
        "LineNumber" = '\bline\s+(\d+)\b'
        "URL" = 'https?://[^\s<>"{}|\\^`\[\]]+'
    }
    
    foreach ($entityType in $entityPatterns.Keys) {
        if ($ResponseText -match $entityPatterns[$entityType]) {
            if (-not $result.Entities.ContainsKey($entityType)) {
                $result.Entities[$entityType] = @()
            }
            $matches[0] | ForEach-Object {
                $result.Entities[$entityType] += $_
            }
            Write-DecisionEngineLog -Message "Entity found: $entityType - $($matches[0])" -Level "DEBUG"
        }
    }
    
    # Action extraction
    $actionPatterns = @(
        @{ Pattern = "(?:run|execute|start)\s+([^\s]+)"; Type = "EXECUTE_COMMAND" },
        @{ Pattern = "(?:open|view|check)\s+([^\s]+)"; Type = "OPEN_FILE" },
        @{ Pattern = "(?:fix|repair|resolve)\s+([^\s]+)"; Type = "FIX_ISSUE" },
        @{ Pattern = "(?:test|verify|validate)\s+([^\s]+)"; Type = "TEST" }
    )
    
    foreach ($actionPattern in $actionPatterns) {
        if ($ResponseText -match $actionPattern.Pattern) {
            $result.Actions += @{
                Type = $actionPattern.Type
                Target = $matches[1]
                Confidence = 0.8
            }
            Write-DecisionEngineLog -Message "Action detected: $($actionPattern.Type) - $($matches[1])" -Level "DEBUG"
        }
    }
    
    return $result
}

#endregion

#region AI-Enhanced Analysis

function Invoke-AIEnhancedAnalysis {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$ResponseText,
        
        [Parameter()]
        [hashtable]$Context = @{}
    )
    
    Write-DecisionEngineLog -Message "Performing AI-enhanced analysis" -Level "DEBUG"
    
    $result = @{
        Intent = "UNKNOWN"
        Confidence = 0.5
        SemanticContext = @{}
        SuggestedActions = @()
    }
    
    try {
        # Get intent classification
        $result.Intent = Get-IntentClassification -Text $ResponseText
        
        # Extract semantic context
        $result.SemanticContext = Get-SemanticContext -Text $ResponseText -Context $Context
        
        # Generate suggested actions
        $result.SuggestedActions = Get-SemanticActions -Text $ResponseText -Intent $result.Intent
        
        # Calculate confidence based on context
        $result.Confidence = Calculate-SemanticConfidence -Analysis $result -Context $Context
        
    } catch {
        Write-DecisionEngineLog -Message "AI analysis error: $_" -Level "WARN"
        # Fall back to basic confidence
        $result.Confidence = 0.3
    }
    
    return $result
}

function Get-IntentClassification {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Text
    )
    
    # Simplified semantic intent classification
    $intents = @{
        "RECOMMENDATION" = @("suggest", "recommend", "should", "could", "advise", "propose")
        "ERROR" = @("error", "fail", "problem", "issue", "bug", "broken")
        "SUCCESS" = @("success", "complete", "done", "working", "fixed", "resolved")
        "EXECUTE" = @("run", "execute", "start", "begin", "launch", "perform")
        "CLARIFICATION" = @("what", "why", "how", "clarify", "explain", "understand")
    }
    
    $scores = @{}
    foreach ($intent in $intents.Keys) {
        $score = 0
        foreach ($keyword in $intents[$intent]) {
            if ($Text -match "\b$keyword\b") {
                $score++
            }
        }
        $scores[$intent] = $score
    }
    
    $topIntent = ($scores.GetEnumerator() | Sort-Object Value -Descending | Select-Object -First 1).Key
    return $topIntent
}

function Get-SemanticContext {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Text,
        
        [Parameter()]
        [hashtable]$Context = @{}
    )
    
    $semanticContext = @{
        Domain = "Unknown"
        Technical = $false
        Urgency = "Normal"
        Complexity = "Medium"
    }
    
    # Domain detection
    if ($Text -match "Unity|GameObject|Component|Scene") {
        $semanticContext.Domain = "Unity"
    } elseif ($Text -match "PowerShell|cmdlet|module|function") {
        $semanticContext.Domain = "PowerShell"
    } elseif ($Text -match "code|script|program|compile") {
        $semanticContext.Domain = "Programming"
    }
    
    # Technical content detection
    if ($Text -match "error|exception|stack trace|debug") {
        $semanticContext.Technical = $true
    }
    
    # Urgency detection
    if ($Text -match "urgent|critical|immediately|asap|emergency") {
        $semanticContext.Urgency = "High"
    } elseif ($Text -match "when you can|later|eventually") {
        $semanticContext.Urgency = "Low"
    }
    
    # Complexity assessment
    $wordCount = ($Text -split '\s+').Count
    if ($wordCount -gt 100) {
        $semanticContext.Complexity = "High"
    } elseif ($wordCount -lt 20) {
        $semanticContext.Complexity = "Low"
    }
    
    return $semanticContext
}

function Get-SemanticActions {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Text,
        
        [Parameter()]
        [string]$Intent = "UNKNOWN"
    )
    
    $actions = @()
    
    # Intent-based action suggestions
    switch ($Intent) {
        "EXECUTE" {
            $actions += @{ Action = "EXECUTE"; Priority = "High" }
        }
        "ERROR" {
            $actions += @{ Action = "DIAGNOSE"; Priority = "High" }
            $actions += @{ Action = "FIX"; Priority = "Medium" }
        }
        "RECOMMENDATION" {
            $actions += @{ Action = "EVALUATE"; Priority = "Medium" }
            $actions += @{ Action = "IMPLEMENT"; Priority = "Low" }
        }
        "CLARIFICATION" {
            $actions += @{ Action = "PROVIDE_INFO"; Priority = "High" }
        }
    }
    
    return $actions
}

function Calculate-SemanticConfidence {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [hashtable]$Analysis,
        
        [Parameter()]
        [hashtable]$Context = @{}
    )
    
    $confidence = 0.5
    
    # Adjust confidence based on intent clarity
    if ($Analysis.Intent -ne "UNKNOWN") {
        $confidence += 0.2
    }
    
    # Adjust based on semantic context
    if ($Analysis.SemanticContext.Technical) {
        $confidence += 0.1
    }
    
    # Adjust based on action suggestions
    if ($Analysis.SuggestedActions.Count -gt 0) {
        $confidence += 0.1
    }
    
    # Cap confidence at 1.0
    return [Math]::Min($confidence, 1.0)
}

#endregion

#region Result Merging

function Merge-AnalysisResults {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [hashtable]$RegexResult,
        
        [Parameter(Mandatory = $true)]
        [hashtable]$AIResult
    )
    
    Write-DecisionEngineLog -Message "Merging analysis results" -Level "DEBUG"
    
    $merged = @{
        Intent = $RegexResult.Intent
        Confidence = 0.0
        Entities = $RegexResult.Entities
        Actions = $RegexResult.Actions
        SemanticContext = $AIResult.SemanticContext
        Patterns = $RegexResult.Patterns
    }
    
    # Weighted confidence calculation
    $regexWeight = 0.6
    $aiWeight = 0.4
    
    if ($RegexResult.Intent -eq $AIResult.Intent) {
        # Agreement boosts confidence
        $merged.Confidence = ($RegexResult.Confidence * $regexWeight + $AIResult.Confidence * $aiWeight) * 1.2
        $merged.Intent = $RegexResult.Intent
    } else {
        # Disagreement reduces confidence
        if ($RegexResult.Confidence -gt $AIResult.Confidence) {
            $merged.Intent = $RegexResult.Intent
            $merged.Confidence = $RegexResult.Confidence * 0.8
        } else {
            $merged.Intent = $AIResult.Intent
            $merged.Confidence = $AIResult.Confidence * 0.8
        }
    }
    
    # Merge suggested actions
    $merged.Actions += $AIResult.SuggestedActions
    
    # Cap confidence at 1.0
    $merged.Confidence = [Math]::Min($merged.Confidence, 1.0)
    
    Write-DecisionEngineLog -Message "Merged intent: $($merged.Intent), Confidence: $($merged.Confidence)" -Level "DEBUG"
    
    return $merged
}

function Add-ContextualEnrichment {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [hashtable]$Analysis,
        
        [Parameter()]
        [hashtable]$Context = @{}
    )
    
    Write-DecisionEngineLog -Message "Adding contextual enrichment" -Level "DEBUG"
    
    # Add conversation flow analysis
    if (Test-RequiredModule -ModuleName "ConversationStateManager") {
        $flowAnalysis = Get-ConversationFlowAnalysis
        $Analysis.ConversationFlow = $flowAnalysis
        
        # Adjust confidence based on conversation consistency
        $consistency = Get-ConversationConsistency -CurrentAnalysis $Analysis
        $Analysis.Confidence *= $consistency
    }
    
    # Add historical context
    if ($script:DecisionHistory.Count -gt 0) {
        $lastSimilar = Get-LastSimilarResponse -CurrentAnalysis $Analysis
        if ($lastSimilar) {
            $Analysis.HistoricalContext = $lastSimilar
            $Analysis.Confidence *= 1.1  # Boost confidence for consistent patterns
        }
    }
    
    # Add context buffer information
    if ($script:ContextBuffer.Count -gt 0) {
        $Analysis.RecentContext = $script:ContextBuffer.ToArray() | Select-Object -Last 5
    }
    
    return $Analysis
}

#endregion

#region Helper Functions

function Get-ConversationFlowAnalysis {
    [CmdletBinding()]
    param()
    
    # Simplified flow analysis
    return @{
        Stage = "Active"
        TurnCount = $script:DecisionHistory.Count
        LastIntent = if ($script:DecisionHistory.Count -gt 0) { $script:DecisionHistory[-1].Intent } else { "UNKNOWN" }
    }
}

function Get-ConversationConsistency {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [hashtable]$CurrentAnalysis
    )
    
    if ($script:DecisionHistory.Count -eq 0) {
        return 1.0
    }
    
    $lastDecision = $script:DecisionHistory[-1]
    
    # Check for intent consistency
    if ($lastDecision.Intent -eq $CurrentAnalysis.Intent) {
        return 1.1  # Consistent intent
    } elseif ($lastDecision.Intent -eq "ERROR" -and $CurrentAnalysis.Intent -eq "SUCCESS") {
        return 1.2  # Problem resolution pattern
    } else {
        return 0.95  # Slight reduction for unexpected changes
    }
}

function Get-LastSimilarResponse {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [hashtable]$CurrentAnalysis
    )
    
    foreach ($decision in $script:DecisionHistory[-10..-1]) {
        if ($decision -and $decision.Intent -eq $CurrentAnalysis.Intent) {
            return $decision
        }
    }
    
    return $null
}

#endregion

# Export module members
Export-ModuleMember -Function @(
    'Invoke-HybridResponseAnalysis',
    'Invoke-RegexBasedAnalysis',
    'Invoke-AIEnhancedAnalysis',
    'Get-IntentClassification',
    'Get-SemanticContext',
    'Get-SemanticActions',
    'Calculate-SemanticConfidence',
    'Merge-AnalysisResults',
    'Add-ContextualEnrichment',
    'Get-ConversationFlowAnalysis',
    'Get-ConversationConsistency',
    'Get-LastSimilarResponse'
)
# SIG # Begin signature block
# MIIFzgYJKoZIhvcNAQcCoIIFvzCCBbsCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCB/X1wX1KClUQuz
# 48Jxk6Vt3lJDGXZ2oCjeiGreLLyvj6CCAzAwggMsMIICFKADAgECAhB1HRbZIqgr
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
# MAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIEg4V6kO+AKYWUtZa0JtUmR1
# YlNGpABl2txJgnqMjPuXMA0GCSqGSIb3DQEBAQUABIIBAKcEpNzwwZA64OfQc6C6
# dMH40/EcS4YpT6519tgNv1n6ZqMiFd1NXvQN3Wa29IZW9dvnTIGMvjgZ2gaXxY1a
# Y72u1imxRupXU6nJGhRMKwd3QSjGCEwr1VxEsHO+fuP+kNWoq7uCrBFIbKndtdCd
# gyhBIwSbRI90xHPdX5mzDFC2uO1d7iWW1DBVuZ8Ycfz7FtSahzIYpO+DRk5+2A9W
# jPzBiRsoDDfVK03sRQa7X5hlmWM0LC9Oh6GtJhPmnrIYDQpR06CAH9bQfFRzvDql
# GVJiHlzLJrjq9X4AkM7VYKyKq7PgSD08yFFDliZIwmapK9YzeotGKtyEgW8nmGiG
# lZ4=
# SIG # End signature block
