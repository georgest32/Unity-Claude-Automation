# ResponseParsing.psm1
# Phase 2 Day 11: Enhanced Response Processing - Advanced Response Parsing
# Provides enhanced regex pattern library, multi-pattern processing, and response categorization
# Date: 2025-08-18

#region Module Dependencies

# Import required modules
Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) "Core\AgentLogging.psm1") -Force

#endregion

#region Module Variables

# Enhanced regex patterns for Claude response parsing
$script:ClaudeResponsePatterns = @{
    # Command patterns (enhanced from existing)
    "RECOMMENDED_Command" = @{
        Pattern = "RECOMMENDED:\s*(TEST|BUILD|ANALYZE|DEBUG|CONTINUE|RUN|EXECUTE)\s*-\s*(.+)"
        Groups = @("FullMatch", "CommandType", "Details")
        Confidence = 0.95
        Category = "Instruction"
    }
    
    "Direct_Instruction" = @{
        Pattern = "(?:Please\s+|You\s+should\s+|Try\s+|Run\s+|Execute\s+)([^.]+)"
        Groups = @("FullMatch", "Command")
        Confidence = 0.85
        Category = "Instruction"
    }
    
    "File_Reference" = @{
        Pattern = "(?:file|script|module)\s+(?:at\s+)?([A-Za-z]:\\[^,\s]+\.(?:ps1|psm1|psd1|cs|txt|log|json))"
        Groups = @("FullMatch", "FilePath")
        Confidence = 0.90
        Category = "Information"
    }
    
    # Question patterns
    "Question_Pattern" = @{
        Pattern = "(?:What|How|Why|Where|When|Should|Would|Could|Can|Do|Did|Will|Are|Is)\s+[^?]*\?"
        Groups = @("FullMatch")
        Confidence = 0.85
        Category = "Question"
    }
    
    "Clarification_Request" = @{
        Pattern = "(?:Could you clarify|Please specify|I need more information about|What do you mean by)"
        Groups = @("FullMatch")
        Confidence = 0.80
        Category = "Question"
    }
    
    # Error patterns
    "Error_Detection" = @{
        Pattern = "(?:error|exception|failed|failure|issue|problem):\s*(.+)"
        Groups = @("FullMatch", "ErrorDescription")
        Confidence = 0.90
        Category = "Error"
    }
    
    "Unity_Error_Code" = @{
        Pattern = "(CS\d{4}):\s*(.+)"
        Groups = @("FullMatch", "ErrorCode", "ErrorMessage")
        Confidence = 0.95
        Category = "Error"
    }
    
    # Completion patterns
    "Task_Completion" = @{
        Pattern = "(?:completed|finished|done|success|successful|resolved|fixed)"
        Groups = @("FullMatch")
        Confidence = 0.75
        Category = "Complete"
    }
    
    "Next_Steps" = @{
        Pattern = "(?:Next\s+step|Now\s+(?:you\s+)?(?:can|should)|Following\s+(?:this|that))"
        Groups = @("FullMatch")
        Confidence = 0.70
        Category = "Information"
    }
    
    # Advanced patterns
    "Code_Block_Reference" = @{
        Pattern = "\b(?:function|class|if|for|while)\s+\w+"
        Groups = @("FullMatch")
        Confidence = 0.75
        Category = "Information"
    }
    
    "Confidence_Indicator" = @{
        Pattern = "(?:confident|certain|sure|likely|probably|might|may|unsure|uncertain)"
        Groups = @("FullMatch")
        Confidence = 0.60
        Category = "Information"
    }
}

# Response quality indicators
$script:QualityIndicators = @{
    "Positive" = @("success", "working", "correct", "fixed", "resolved", "completed")
    "Negative" = @("error", "failed", "issue", "problem", "incorrect", "broken")
    "Uncertainty" = @("might", "may", "possibly", "perhaps", "unsure", "unclear")
    "Confidence" = @("definitely", "certainly", "confirmed", "verified", "validated")
}

# Logging configuration
$script:LogPath = Join-Path (Split-Path (Split-Path $PSScriptRoot -Parent) -Parent) "unity_claude_automation.log"

#endregion

#region Core Response Parsing Functions

function Invoke-EnhancedResponseParsing {
    <#
    .SYNOPSIS
    Performs comprehensive parsing of Claude responses using enhanced pattern library
    
    .DESCRIPTION
    Analyzes Claude responses using advanced regex patterns, multi-pattern processing,
    and confidence scoring to extract actionable information
    
    .PARAMETER ResponseText
    The Claude response text to parse
    
    .PARAMETER PatternFilter
    Optional filter to apply specific pattern categories
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$ResponseText,
        
        [ValidateSet("", "Instruction", "Question", "Information", "Error", "Complete")]
        [string]$PatternFilter = ""
    )
    
    Write-AgentLog "Starting enhanced response parsing" -Level "DEBUG" -Component "ResponseParsing"
    
    try {
        $parseResults = @{
            ParsedAt = Get-Date
            ResponseLength = $ResponseText.Length
            PatternsMatched = @()
            Categories = @{}
            OverallConfidence = 0.0
            QualityScore = 0.0
            ExtractedEntities = @()
        }
        
        # Apply all relevant patterns
        foreach ($patternName in $script:ClaudeResponsePatterns.Keys) {
            $pattern = $script:ClaudeResponsePatterns[$patternName]
            
            # Apply pattern filter if specified
            if (![string]::IsNullOrEmpty($PatternFilter) -and $pattern.Category -ne $PatternFilter) {
                continue
            }
            
            Write-AgentLog "Applying pattern: $patternName" -Level "DEBUG" -Component "ResponseParsing"
            
            # Test pattern match
            if ($ResponseText -match $pattern.Pattern) {
                Write-AgentLog "MATCH FOUND: Pattern '$patternName' matched '$($Matches[0])' in category $($pattern.Category)" -Level "DEBUG" -Component "ResponseParsing"
                
                $matchResult = @{
                    PatternName = $patternName
                    Category = $pattern.Category
                    Confidence = $pattern.Confidence
                    MatchedText = $Matches[0]
                    Groups = @{}
                }
                
                # Extract named groups
                for ($i = 0; $i -lt $pattern.Groups.Count; $i++) {
                    if ($i -lt $Matches.Count) {
                        $matchResult.Groups[$pattern.Groups[$i]] = $Matches[$i]
                    }
                }
                
                $parseResults.PatternsMatched += $matchResult
                
                # Update category tracking
                if (-not $parseResults.Categories.ContainsKey($pattern.Category)) {
                    $parseResults.Categories[$pattern.Category] = @()
                }
                $parseResults.Categories[$pattern.Category] += $matchResult
                
                Write-AgentLog "Pattern matched: $patternName (Confidence: $($pattern.Confidence))" -Level "DEBUG" -Component "ResponseParsing"
            }
        }
        
        # Calculate overall confidence
        if ($parseResults.PatternsMatched.Count -gt 0) {
            $totalConfidence = 0
            foreach ($match in $parseResults.PatternsMatched) {
                $totalConfidence += $match.Confidence
            }
            $parseResults.OverallConfidence = [Math]::Round($totalConfidence / $parseResults.PatternsMatched.Count, 2)
        }
        
        # Calculate quality score
        $parseResults.QualityScore = Get-ResponseQualityScore -ResponseText $ResponseText
        
        Write-AgentLog "Enhanced parsing completed: $($parseResults.PatternsMatched.Count) patterns matched" -Level "SUCCESS" -Component "ResponseParsing"
        
        return @{
            Success = $true
            Results = $parseResults
        }
    }
    catch {
        Write-AgentLog "Enhanced response parsing failed: $_" -Level "ERROR" -Component "ResponseParsing"
        return @{
            Success = $false
            Error = $_.Exception.Message
        }
    }
}

function Get-ResponseQualityScore {
    <#
    .SYNOPSIS
    Calculates quality score for Claude response
    
    .DESCRIPTION
    Analyzes response text for quality indicators including clarity, completeness, and confidence
    
    .PARAMETER ResponseText
    The response text to analyze
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$ResponseText
    )
    
    try {
        $qualityScore = 0.0
        $indicators = @{
            Positive = 0
            Negative = 0
            Uncertainty = 0
            Confidence = 0
        }
        
        # Count quality indicators
        foreach ($category in $script:QualityIndicators.Keys) {
            foreach ($term in $script:QualityIndicators[$category]) {
                $matches = [regex]::Matches($ResponseText, "\b$term\b", [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)
                $indicators[$category] += $matches.Count
            }
        }
        
        # Calculate base quality score
        $qualityScore = [Math]::Max(0, ($indicators.Positive * 0.3) + ($indicators.Confidence * 0.4) - ($indicators.Negative * 0.2) - ($indicators.Uncertainty * 0.1))
        
        # Length bonus (longer responses often more detailed)
        $lengthBonus = [Math]::Min(0.2, $ResponseText.Length / 5000)
        $qualityScore += $lengthBonus
        
        # Structure bonus (formatted responses)
        if ($ResponseText -match "(?:##|###|\*\*|\d+\.)" ) {
            $qualityScore += 0.1
        }
        
        # Cap at reasonable maximum
        $qualityScore = [Math]::Min(1.0, $qualityScore)
        
        Write-AgentLog "Quality score calculated: $([Math]::Round($qualityScore, 2))" -Level "DEBUG" -Component "ResponseParsing"
        
        return [Math]::Round($qualityScore, 2)
    }
    catch {
        Write-AgentLog "Quality score calculation failed: $_" -Level "ERROR" -Component "ResponseParsing"
        return 0.0
    }
}

function Extract-CommandsFromResponse {
    <#
    .SYNOPSIS
    Extracts actionable commands from Claude response
    
    .DESCRIPTION
    Identifies and extracts specific commands that can be executed autonomously
    
    .PARAMETER ResponseText
    The Claude response text to parse
    
    .PARAMETER RequireRecommended
    Only extract commands with RECOMMENDED prefix
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$ResponseText,
        
        [switch]$RequireRecommended
    )
    
    Write-AgentLog "Extracting commands from response" -Level "DEBUG" -Component "ResponseParsing"
    
    try {
        $commands = @()
        
        # Extract RECOMMENDED commands
        $recommendedMatches = [regex]::Matches($ResponseText, "RECOMMENDED:\s*(TEST|BUILD|ANALYZE|DEBUG|CONTINUE|RUN|EXECUTE)\s*-\s*(.+)", [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)
        
        foreach ($match in $recommendedMatches) {
            $commands += @{
                Type = "RECOMMENDED"
                CommandType = $match.Groups[1].Value.ToUpper()
                Details = $match.Groups[2].Value.Trim()
                Confidence = 0.95
                Source = "RECOMMENDED_Pattern"
                ExecutionPriority = "High"
            }
        }
        
        # Extract direct instructions if not requiring RECOMMENDED only
        if (-not $RequireRecommended) {
            $instructionMatches = [regex]::Matches($ResponseText, "(?:Please\s+|You\s+should\s+|Try\s+|Run\s+|Execute\s+)([^.]+)", [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)
            
            foreach ($match in $instructionMatches) {
                $commands += @{
                    Type = "INSTRUCTION"
                    CommandType = "GENERAL"
                    Details = $match.Groups[1].Value.Trim()
                    Confidence = 0.75
                    Source = "Direct_Instruction"
                    ExecutionPriority = "Medium"
                }
            }
        }
        
        Write-AgentLog "Extracted $($commands.Count) commands from response" -Level "INFO" -Component "ResponseParsing"
        
        return @{
            Success = $true
            Commands = $commands
            CommandCount = $commands.Count
        }
    }
    catch {
        Write-AgentLog "Command extraction failed: $_" -Level "ERROR" -Component "ResponseParsing"
        return @{
            Success = $false
            Error = $_.Exception.Message
            Commands = @()
        }
    }
}

function Get-ResponseCategorization {
    <#
    .SYNOPSIS
    Categorizes Claude response using decision tree logic
    
    .DESCRIPTION
    Applies decision tree classification to determine primary response category
    
    .PARAMETER ResponseText
    The response text to categorize
    
    .PARAMETER ParseResults
    Optional pre-computed parse results
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$ResponseText,
        
        [hashtable]$ParseResults
    )
    
    Write-AgentLog "Categorizing response using decision tree" -Level "DEBUG" -Component "ResponseParsing"
    
    try {
        # Get parse results if not provided
        if (-not $ParseResults) {
            $parseResult = Invoke-EnhancedResponseParsing -ResponseText $ResponseText
            if (-not $parseResult.Success) {
                throw "Failed to parse response for categorization"
            }
            $ParseResults = $parseResult.Results
        }
        
        # Decision tree classification
        $categorization = @{
            PrimaryCategory = "Information"
            SecondaryCategory = $null
            Confidence = 0.0
            ReasoningChain = @()
            Categories = @{}
        }
        
        # Count category occurrences
        foreach ($category in $ParseResults.Categories.Keys) {
            $count = $ParseResults.Categories[$category].Count
            
            # Calculate average confidence manually (fix for hashtable Measure-Object issue)
            $totalConfidence = 0
            foreach ($item in $ParseResults.Categories[$category]) {
                $totalConfidence += $item.Confidence
            }
            $avgConfidence = if ($count -gt 0) { $totalConfidence / $count } else { 0 }
            
            $categorization.Categories[$category] = @{
                Count = $count
                AverageConfidence = [Math]::Round($avgConfidence, 2)
                Weight = $count * $avgConfidence
            }
        }
        
        # Decision tree logic with debug logging
        $categorization.ReasoningChain += "Starting decision tree classification"
        Write-AgentLog "Available categories: $($categorization.Categories.Keys -join ', ')" -Level "DEBUG" -Component "ResponseParsing"
        
        # Debug each category
        foreach ($debugCategory in $categorization.Categories.Keys) {
            $debugData = $categorization.Categories[$debugCategory]
            Write-AgentLog "Category ${debugCategory}: Count=$($debugData.Count), Weight=$($debugData.Weight), AvgConf=$($debugData.AverageConfidence)" -Level "DEBUG" -Component "ResponseParsing"
        }
        
        # Rule 1: Error detection takes precedence (lowered threshold)
        if ($categorization.Categories.ContainsKey("Error") -and $categorization.Categories["Error"].Weight -gt 0.3) {
            $categorization.PrimaryCategory = "Error"
            $categorization.Confidence = $categorization.Categories["Error"].AverageConfidence
            $categorization.ReasoningChain += "Rule 1: Error category detected (Weight: $($categorization.Categories['Error'].Weight))"
        }
        # Rule 2: Instructions are high priority (lowered threshold)
        elseif ($categorization.Categories.ContainsKey("Instruction") -and $categorization.Categories["Instruction"].Weight -gt 0.4) {
            $categorization.PrimaryCategory = "Instruction"
            $categorization.Confidence = $categorization.Categories["Instruction"].AverageConfidence
            $categorization.ReasoningChain += "Rule 2: Instruction category (Weight: $($categorization.Categories['Instruction'].Weight))"
        }
        # Rule 3: Questions require responses
        elseif ($categorization.Categories.ContainsKey("Question") -and $categorization.Categories["Question"].Count -gt 0) {
            $categorization.PrimaryCategory = "Question"
            $categorization.Confidence = $categorization.Categories["Question"].AverageConfidence
            $categorization.ReasoningChain += "Rule 3: Question category detected (Count: $($categorization.Categories['Question'].Count))"
        }
        # Rule 4: Completion indicates task done (lowered threshold)
        elseif ($categorization.Categories.ContainsKey("Complete") -and $categorization.Categories["Complete"].Weight -gt 0.3) {
            $categorization.PrimaryCategory = "Complete"
            $categorization.Confidence = $categorization.Categories["Complete"].AverageConfidence
            $categorization.ReasoningChain += "Rule 4: Completion category (Weight: $($categorization.Categories['Complete'].Weight))"
        }
        # Rule 5: Default to Information
        else {
            $categorization.PrimaryCategory = "Information"
            $categorization.Confidence = 0.5
            $categorization.ReasoningChain += "Rule 5: Default to Information category (no other conditions met)"
            
            # Debug why other conditions weren't met
            if ($categorization.Categories.Count -gt 0) {
                Write-AgentLog "Defaulted to Information. Available weights: $(($categorization.Categories.GetEnumerator() | ForEach-Object { "$($_.Name)=$($_.Value.Weight)" }) -join ', ')" -Level "DEBUG" -Component "ResponseParsing"
            }
        }
        
        # Determine secondary category
        $sortedCategories = $categorization.Categories.GetEnumerator() | 
            Where-Object { $_.Name -ne $categorization.PrimaryCategory } |
            Sort-Object { $_.Value.Weight } -Descending
            
        if ($sortedCategories.Count -gt 0) {
            $categorization.SecondaryCategory = $sortedCategories[0].Name
        }
        
        Write-AgentLog "Response categorized as: $($categorization.PrimaryCategory) (Confidence: $($categorization.Confidence))" -Level "INFO" -Component "ResponseParsing"
        
        return @{
            Success = $true
            Categorization = $categorization
        }
    }
    catch {
        Write-AgentLog "Response categorization failed: $_" -Level "ERROR" -Component "ResponseParsing"
        return @{
            Success = $false
            Error = $_.Exception.Message
        }
    }
}

function Get-ResponseEntities {
    <#
    .SYNOPSIS
    Extracts entities from Claude response
    
    .DESCRIPTION
    Identifies and extracts specific entities like file paths, error codes, Unity terms
    
    .PARAMETER ResponseText
    The response text to analyze
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$ResponseText
    )
    
    Write-AgentLog "Extracting entities from response" -Level "DEBUG" -Component "ResponseParsing"
    
    try {
        $entities = @{
            FilePaths = @()
            ErrorCodes = @()
            UnityTerms = @()
            Commands = @()
            Numbers = @()
        }
        
        # Extract file paths
        $fileMatches = [regex]::Matches($ResponseText, "[A-Za-z]:\\[^,\s]+\.(?:ps1|psm1|psd1|cs|txt|log|json)")
        foreach ($match in $fileMatches) {
            $entities.FilePaths += $match.Value
        }
        
        # Extract Unity error codes
        $errorMatches = [regex]::Matches($ResponseText, "CS\d{4}")
        foreach ($match in $errorMatches) {
            $entities.ErrorCodes += $match.Value
        }
        
        # Extract Unity-specific terms
        $unityTerms = @("Unity", "GameObject", "MonoBehaviour", "Transform", "Component", "Scene", "Asset", "Script")
        foreach ($term in $unityTerms) {
            if ($ResponseText -match "\b$term\b") {
                $entities.UnityTerms += $term
            }
        }
        
        # Extract command-like patterns
        $commandMatches = [regex]::Matches($ResponseText, "\b(?:Install|Remove|Add|Delete|Create|Update|Test|Build|Run|Execute)-\w+")
        foreach ($match in $commandMatches) {
            $entities.Commands += $match.Value
        }
        
        # Extract numbers (potentially line numbers, percentages, etc.)
        $numberMatches = [regex]::Matches($ResponseText, "\b\d+(?:\.\d+)?\b")
        foreach ($match in $numberMatches) {
            $entities.Numbers += $match.Value
        }
        
        $totalEntities = $entities.FilePaths.Count + $entities.ErrorCodes.Count + $entities.UnityTerms.Count + $entities.Commands.Count + $entities.Numbers.Count
        
        Write-AgentLog "Extracted $totalEntities entities from response" -Level "INFO" -Component "ResponseParsing"
        
        return @{
            Success = $true
            Entities = $entities
            TotalEntities = $totalEntities
        }
    }
    catch {
        Write-AgentLog "Entity extraction failed: $_" -Level "ERROR" -Component "ResponseParsing"
        return @{
            Success = $false
            Error = $_.Exception.Message
        }
    }
}

function Test-ResponseParsingModule {
    <#
    .SYNOPSIS
    Tests the response parsing module functionality
    
    .DESCRIPTION
    Validates parsing capabilities using test cases
    #>
    [CmdletBinding()]
    param()
    
    Write-AgentLog "Testing response parsing module" -Level "INFO" -Component "ResponseParsing"
    
    $testCases = @(
        @{
            Name = "RECOMMENDED Command"
            Text = "RECOMMENDED: TEST - Run the validation script to ensure all functions work correctly"
            ExpectedCategory = "Instruction"
            ExpectedCommands = 1
        },
        @{
            Name = "Error Response"
            Text = "CS0246: The type or namespace name could not be found. Please check your using statements."
            ExpectedCategory = "Error"
            ExpectedEntities = 1
        },
        @{
            Name = "Question Response"
            Text = "What Unity version are you using? Could you clarify the exact error message?"
            ExpectedCategory = "Question"
            ExpectedEntities = 0
        },
        @{
            Name = "Completion Response"
            Text = "The fix has been successfully applied and the issue is now resolved. Task completed."
            ExpectedCategory = "Complete"
            ExpectedEntities = 0
        }
    )
    
    $testsPassed = 0
    $testsTotal = $testCases.Count
    
    foreach ($testCase in $testCases) {
        try {
            Write-AgentLog "Testing: $($testCase.Name)" -Level "DEBUG" -Component "ResponseParsing"
            
            $parseResult = Invoke-EnhancedResponseParsing -ResponseText $testCase.Text
            $categorizationResult = Get-ResponseCategorization -ResponseText $testCase.Text -ParseResults $parseResult.Results
            
            if ($parseResult.Success -and $categorizationResult.Success) {
                $actualCategory = $categorizationResult.Categorization.PrimaryCategory
                if ($actualCategory -eq $testCase.ExpectedCategory) {
                    Write-AgentLog "  PASS: $($testCase.Name) - Category: $actualCategory" -Level "DEBUG" -Component "ResponseParsing"
                    $testsPassed++
                } else {
                    Write-AgentLog "  FAIL: $($testCase.Name) - Expected: $($testCase.ExpectedCategory), Got: $actualCategory" -Level "WARNING" -Component "ResponseParsing"
                }
            } else {
                Write-AgentLog "  FAIL: $($testCase.Name) - Parsing or categorization failed" -Level "WARNING" -Component "ResponseParsing"
            }
        }
        catch {
            Write-AgentLog "  ERROR: $($testCase.Name) - $_" -Level "ERROR" -Component "ResponseParsing"
        }
    }
    
    $successRate = [Math]::Round(($testsPassed / $testsTotal) * 100, 1)
    Write-AgentLog "Response parsing module test completed: $testsPassed/$testsTotal ($successRate%)" -Level "SUCCESS" -Component "ResponseParsing"
    
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
    'Invoke-EnhancedResponseParsing',
    'Get-ResponseQualityScore',
    'Extract-CommandsFromResponse',
    'Get-ResponseCategorization',
    'Get-ResponseEntities',
    'Test-ResponseParsingModule'
)

Write-AgentLog "ResponseParsing module loaded successfully" -Level "INFO" -Component "ResponseParsing"
# SIG # Begin signature block
# MIIFqQYJKoZIhvcNAQcCoIIFmjCCBZYCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUNhvkSl681HwTnjo+SgyCbpfX
# 07CgggMwMIIDLDCCAhSgAwIBAgIQdR0W2SKoK5VE8JId4ZxrRTANBgkqhkiG9w0B
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
# CQQxFgQULWwdLVQB/R0nyrXTcYoN7whuG0UwDQYJKoZIhvcNAQEBBQAEggEAsd3A
# KYuCXNkYz9o7vUjw44HPDJtFADEi9s+XHYriBXfBb1kH2PlVqCkMhVzjA5BK5Fqp
# j750n3HGj45Mw+prDPRR8zG0SvIGHOyK1zJVjKsta1JEJhCvsPJPTjozhFOx9wDp
# cCiUW/vaIg8QJGpGBWHJ8ASsz+lame6ew86//mqxAIeDos3dO1ByjUmRVkvYIQyc
# H/9bwWmSt8fRbGu81VsOYqwd421gpbzWLALncTAIaNkUiPBu9ZOuJ6cIQPoIh2fi
# 3+c7TTvJi9r9ayJNvld9TbxlfJW01YavHkbOGPZirsXvRYg09QjmMkKCsoQBqYqw
# LyQ57logJUtBteq8dg==
# SIG # End signature block
