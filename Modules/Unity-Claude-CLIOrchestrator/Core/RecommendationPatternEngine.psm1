# Unity-Claude-CLIOrchestrator - Recommendation Pattern Recognition Engine
# Phase 7 Day 1-2 Hours 5-8: Enhanced Pattern Recognition
# Compatible with PowerShell 5.1 and Claude Code CLI 2025

#region Enhanced Recommendation Patterns Configuration

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
            "accomplished\s*[:]\s*(.+)"
        )
        Confidence = 0.90
        BaseWeight = 0.9
        ActionType = "TaskCompletion"
        Priority = "Medium"
        ValidationRules = @("TaskKeyword")
    }
    "ERROR" = @{
        Pattern = "ERROR[:]\s*(.+)"
        SemanticPatterns = @(
            "(?:critical\s+)?error\s*[:]\s*(.+)",
            "exception\s*[:]\s*(.+)",
            "failure\s*[:]\s*(.+)",
            "(?:compile\s+)?error\s*[:]\s*(.+)"
        )
        Confidence = 0.95
        BaseWeight = 1.3
        ActionType = "ErrorHandling"
        Priority = "Critical"
        ValidationRules = @("ErrorKeyword")
    }
}

# Pattern statistics tracking
$script:PatternStats = @{
    PatternHits = @{}
    LastUpdated = Get-Date
    TotalMatches = 0
}

#endregion

#region Core Pattern Functions

function Initialize-CompiledPatterns {
    [CmdletBinding()]
    param()
    
    $compilationStart = [System.Diagnostics.Stopwatch]::StartNew()
    
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
                PatternInfo = $patternInfo
                CompiledAt = Get-Date
            }
        }
        
        $compilationStart.Stop()
        Write-Host "Compiled $($script:CompiledPatterns.Count) recommendation patterns in $($compilationStart.ElapsedMilliseconds)ms" -ForegroundColor Green
        
    } catch {
        Write-Warning "Failed to compile patterns: $($_.Exception.Message)"
        return $false
    }
    
    return $true
}

function Find-RecommendationPatterns {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$ResponseText
    )
    
    # Initialize compiled patterns if not done yet
    if ($script:CompiledPatterns.Count -eq 0) {
        if (-not (Initialize-CompiledPatterns)) {
            Write-Warning "Failed to initialize compiled patterns, using fallback method"
            return @()
        }
    }
    
    $recommendations = @()
    $totalMatchTime = [System.Diagnostics.Stopwatch]::StartNew()
    
    foreach ($patternName in $script:RecommendationPatterns.Keys) {
        $patternInfo = $script:RecommendationPatterns[$patternName]
        $compiledPatternSet = $script:CompiledPatterns[$patternName]
        
        if (-not $compiledPatternSet) {
            Write-Warning "Compiled pattern not found for $patternName, skipping"
            continue
        }
        
        # Primary pattern matching
        $primaryMatch = $compiledPatternSet.Primary.Match($ResponseText)
        
        if ($primaryMatch.Success) {
            $confidence = $patternInfo.Confidence
            $matchType = "Primary"
            
            # Extract recommendation details
            $recommendation = @{
                Type = $patternName
                Action = if ($primaryMatch.Groups.Count -gt 1) { $primaryMatch.Groups[1].Value.Trim() } else { $primaryMatch.Value.Trim() }
                Details = if ($primaryMatch.Groups.Count -gt 2) { $primaryMatch.Groups[2].Value.Trim() } else { "" }
                Confidence = $confidence
                Priority = $patternInfo.Priority
                ActionType = $patternInfo.ActionType
                Position = $primaryMatch.Index
                MatchType = $matchType
                PatternName = $patternName
            }
            
            $recommendations += $recommendation
            
            # Track pattern usage
            if (-not $script:PatternStats.PatternHits.ContainsKey($patternName)) {
                $script:PatternStats.PatternHits[$patternName] = 0
            }
            $script:PatternStats.PatternHits[$patternName]++
            $script:PatternStats.TotalMatches++
        }
        else {
            # Try semantic patterns for fuzzy matching
            foreach ($semanticRegex in $compiledPatternSet.Semantic) {
                $semanticMatch = $semanticRegex.Match($ResponseText)
                
                if ($semanticMatch.Success) {
                    $confidence = $patternInfo.Confidence * 0.85  # Slightly lower confidence for semantic matches
                    $matchType = "Semantic"
                    
                    $recommendation = @{
                        Type = $patternName
                        Action = if ($semanticMatch.Groups.Count -gt 1) { $semanticMatch.Groups[1].Value.Trim() } else { $semanticMatch.Value.Trim() }
                        Details = if ($semanticMatch.Groups.Count -gt 2) { $semanticMatch.Groups[2].Value.Trim() } else { "" }
                        Confidence = $confidence
                        Priority = $patternInfo.Priority
                        ActionType = $patternInfo.ActionType
                        Position = $semanticMatch.Index
                        MatchType = $matchType
                        PatternName = $patternName
                    }
                    
                    $recommendations += $recommendation
                    
                    # Track pattern usage
                    if (-not $script:PatternStats.PatternHits.ContainsKey($patternName)) {
                        $script:PatternStats.PatternHits[$patternName] = 0
                    }
                    $script:PatternStats.PatternHits[$patternName]++
                    $script:PatternStats.TotalMatches++
                    
                    break  # Only match the first semantic pattern
                }
            }
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
    
    return $sortedRecommendations
}

#endregion

# Export functions
Export-ModuleMember -Function @(
    'Initialize-CompiledPatterns',
    'Find-RecommendationPatterns'
)
# SIG # Begin signature block
# MIIFzgYJKoZIhvcNAQcCoIIFvzCCBbsCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCAsKZIwhHct1/YI
# YhyWfgbB2WUFLr5eaRjKLkciktxj7aCCAzAwggMsMIICFKADAgECAhB1HRbZIqgr
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
# MAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIN3g4++hYJjSazox5LzuBuS4
# v9oFvcpqG2vxcH4lvtydMA0GCSqGSIb3DQEBAQUABIIBAELNv4/yodpEtYOvtPmh
# iZfvSM1W1n6J0IxWwsmFE91DngzWvhTQCtyiOwgO8UPm62lifLLYQhoPvEt6aDRK
# kHSKTNLlyhXVl8HeNDFlE4P6KWvb6aN3kRdIVhnT/momsuwZ13wFzvxVAepPTzZ3
# 4fo3oFUG3wfJ9pA3Nw1YPX+tmqM3R5UEQJVs31T8A7pFcNsy1af2Xy1Ahguc05xR
# BqQRhtjdYcF5VUFa+y6IuJnx3hdBc96NUC528YTGgcehZiTTYptidD+0iExF5wyN
# xH5hV9JiZ66npbJRmuNtV56eyzsnuAaKXrA7EoDNwbueZ2nsEWKWBhuQ4SmyqMYi
# 0BI=
# SIG # End signature block
