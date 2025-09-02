function Find-RecommendationPatterns {
    <#
    .SYNOPSIS
        Identifies and extracts recommendation patterns from Claude responses
        
    .DESCRIPTION
        Analyzes response text to find and categorize recommendation patterns including:
        - Direct recommendations (RECOMMENDATION: format)
        - Action suggestions (should, need to, etc.)
        - File operations (read, write, create, etc.)
        - Testing recommendations
        - Implementation suggestions
        
    .PARAMETER ResponseText
        The Claude response text to analyze for patterns
        
    .PARAMETER PatternTypes
        Optional array of specific pattern types to search for
        
    .OUTPUTS
        PSCustomObject containing categorized recommendation patterns
        
    .EXAMPLE
        $patterns = Find-RecommendationPatterns -ResponseText $claudeResponse
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$ResponseText,
        
        [string[]]$PatternTypes = @("Direct", "Actions", "Files", "Testing", "Implementation")
    )
    
    try {
        Write-Verbose "Finding recommendation patterns in response ($($ResponseText.Length) characters)"
        
        $patterns = [PSCustomObject]@{
            DirectRecommendations = @()
            ActionSuggestions = @()
            FileOperations = @()
            TestingRecommendations = @()
            ImplementationSuggestions = @()
            UrgentActions = @()
            OptionalActions = @()
            PatternCount = 0
            ConfidenceScore = 0
            AnalyzedAt = Get-Date
        }
        
        if ([string]::IsNullOrWhiteSpace($ResponseText)) {
            Write-Warning "Response text is empty or null"
            return $patterns
        }
        
        # Direct Recommendations (RECOMMENDATION: format)
        if ($PatternTypes -contains "Direct") {
            $directPatterns = @(
                'RECOMMENDATION:\s*([^`n`r]+)',
                'RECOMMENDED:\s*([^`n`r]+)',
                'RECOMMEND:\s*([^`n`r]+)',
                'I recommend\s*([^`n`r]+)',
                'My recommendation\s*([^`n`r]+)'
            )
            
            foreach ($pattern in $directPatterns) {
                $matches = [regex]::Matches($ResponseText, $pattern, 'IgnoreCase')
                foreach ($match in $matches) {
                    $recommendation = $match.Groups[1].Value.Trim()
                    if ($recommendation -and $recommendation -notin $patterns.DirectRecommendations) {
                        $patterns.DirectRecommendations += $recommendation
                    }
                }
            }
        }
        
        # Action Suggestions (should, need to, must, etc.)
        if ($PatternTypes -contains "Actions") {
            $actionPatterns = @(
                'you should\s+([^.!?`n`r]+)',
                'we should\s+([^.!?`n`r]+)',
                'need to\s+([^.!?`n`r]+)',
                'must\s+([^.!?`n`r]+)',
                'have to\s+([^.!?`n`r]+)',
                'suggest\s+([^.!?`n`r]+)',
                'advise\s+([^.!?`n`r]+)',
                'consider\s+([^.!?`n`r]+)'
            )
            
            foreach ($pattern in $actionPatterns) {
                $matches = [regex]::Matches($ResponseText, $pattern, 'IgnoreCase')
                foreach ($match in $matches) {
                    $action = $match.Groups[1].Value.Trim()
                    if ($action -and $action -notin $patterns.ActionSuggestions) {
                        $patterns.ActionSuggestions += $action
                    }
                }
            }
        }
        
        # File Operations
        if ($PatternTypes -contains "Files") {
            $filePatterns = @(
                '(create|make|generate)\s+([^`s]+\.(ps1|psm1|psd1|json|md|txt))',
                '(read|check|review)\s+([^`s]+\.(ps1|psm1|psd1|json|md|txt))',
                '(edit|modify|update)\s+([^`s]+\.(ps1|psm1|psd1|json|md|txt))',
                '(delete|remove)\s+([^`s]+\.(ps1|psm1|psd1|json|md|txt))',
                'run\s+([^`s]+\.ps1)',
                'execute\s+([^`s]+\.ps1)',
                'test\s+([^`s]+\.ps1)'
            )
            
            foreach ($pattern in $filePatterns) {
                $matches = [regex]::Matches($ResponseText, $pattern, 'IgnoreCase')
                foreach ($match in $matches) {
                    $operation = $match.Groups[1].Value
                    $fileName = $match.Groups[2].Value
                    $fileOp = "$operation $fileName"
                    if ($fileOp -notin $patterns.FileOperations) {
                        $patterns.FileOperations += $fileOp
                    }
                }
            }
        }
        
        # Testing Recommendations
        if ($PatternTypes -contains "Testing") {
            $testPatterns = @(
                'TEST\s*[-:]\s*([^`n`r]+)',
                'run.*test\s*([^`n`r]*)',
                'execute.*test\s*([^`n`r]*)',
                'validate\s+([^`n`r]+)',
                'verify\s+([^`n`r]+)',
                'check\s+([^`n`r]+)',
                'test the\s+([^`n`r]+)',
                'testing\s+([^`n`r]+)'
            )
            
            foreach ($pattern in $testPatterns) {
                $matches = [regex]::Matches($ResponseText, $pattern, 'IgnoreCase')
                foreach ($match in $matches) {
                    $testRec = if ($match.Groups.Count -gt 1 -and $match.Groups[1].Value.Trim()) {
                        $match.Groups[1].Value.Trim()
                    } else {
                        $match.Value.Trim()
                    }
                    if ($testRec -and $testRec -notin $patterns.TestingRecommendations) {
                        $patterns.TestingRecommendations += $testRec
                    }
                }
            }
        }
        
        # Implementation Suggestions
        if ($PatternTypes -contains "Implementation") {
            $implPatterns = @(
                'implement\s+([^`n`r]+)',
                'add\s+([^`n`r]+)',
                'create\s+([^`n`r]+)',
                'build\s+([^`n`r]+)',
                'develop\s+([^`n`r]+)',
                'fix\s+([^`n`r]+)',
                'enhance\s+([^`n`r]+)',
                'improve\s+([^`n`r]+)',
                'refactor\s+([^`n`r]+)'
            )
            
            foreach ($pattern in $implPatterns) {
                $matches = [regex]::Matches($ResponseText, $pattern, 'IgnoreCase')
                foreach ($match in $matches) {
                    $implementation = $match.Groups[1].Value.Trim()
                    if ($implementation -and $implementation -notin $patterns.ImplementationSuggestions) {
                        $patterns.ImplementationSuggestions += $implementation
                    }
                }
            }
        }
        
        # Categorize by urgency
        $urgentKeywords = @('critical', 'urgent', 'immediate', 'must', 'required', 'necessary', 'error', 'fix')
        $optionalKeywords = @('should', 'could', 'might', 'consider', 'suggest', 'optional', 'enhance')
        
        # Check all recommendations for urgency
        $allRecommendations = $patterns.DirectRecommendations + $patterns.ActionSuggestions + 
                             $patterns.FileOperations + $patterns.TestingRecommendations + 
                             $patterns.ImplementationSuggestions
        
        foreach ($rec in $allRecommendations) {
            $recLower = $rec.ToLower()
            $isUrgent = $urgentKeywords | Where-Object { $recLower -match $_ }
            $isOptional = $optionalKeywords | Where-Object { $recLower -match $_ }
            
            if ($isUrgent) {
                $patterns.UrgentActions += $rec
            } elseif ($isOptional) {
                $patterns.OptionalActions += $rec
            }
        }
        
        # Calculate pattern statistics
        $patterns.PatternCount = $patterns.DirectRecommendations.Count + $patterns.ActionSuggestions.Count + 
                                $patterns.FileOperations.Count + $patterns.TestingRecommendations.Count + 
                                $patterns.ImplementationSuggestions.Count
        
        # Calculate confidence score based on pattern clarity and quantity
        if ($patterns.DirectRecommendations.Count -gt 0) {
            $patterns.ConfidenceScore += 30  # High confidence for direct recommendations
        }
        if ($patterns.PatternCount -gt 0) {
            $patterns.ConfidenceScore += [Math]::Min(50, $patterns.PatternCount * 10)
        }
        if ($patterns.UrgentActions.Count -gt 0) {
            $patterns.ConfidenceScore += 20  # Bonus for urgent actions
        }
        
        Write-Verbose "Recommendation pattern analysis complete:"
        Write-Verbose "  Direct Recommendations: $($patterns.DirectRecommendations.Count)"
        Write-Verbose "  Action Suggestions: $($patterns.ActionSuggestions.Count)"
        Write-Verbose "  File Operations: $($patterns.FileOperations.Count)"
        Write-Verbose "  Testing Recommendations: $($patterns.TestingRecommendations.Count)"
        Write-Verbose "  Implementation Suggestions: $($patterns.ImplementationSuggestions.Count)"
        Write-Verbose "  Urgent Actions: $($patterns.UrgentActions.Count)"
        Write-Verbose "  Total Patterns: $($patterns.PatternCount)"
        Write-Verbose "  Confidence Score: $($patterns.ConfidenceScore)"
        
        return $patterns
        
    } catch {
        Write-Error "Error finding recommendation patterns: $_"
        return [PSCustomObject]@{
            DirectRecommendations = @()
            ActionSuggestions = @()
            FileOperations = @()
            TestingRecommendations = @()
            ImplementationSuggestions = @()
            UrgentActions = @()
            OptionalActions = @()
            PatternCount = 0
            ConfidenceScore = 0
            AnalyzedAt = Get-Date
            Error = $_.Exception.Message
        }
    }
}

# Export function
Export-ModuleMember -Function 'Find-RecommendationPatterns'