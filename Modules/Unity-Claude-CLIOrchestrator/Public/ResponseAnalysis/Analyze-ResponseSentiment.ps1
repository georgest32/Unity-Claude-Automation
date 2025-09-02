function Analyze-ResponseSentiment {
    <#
    .SYNOPSIS
        Analyzes the sentiment and tone of Claude response text
        
    .DESCRIPTION
        Performs sentiment analysis on response text to determine:
        - Overall sentiment (Positive, Negative, Neutral)
        - Confidence level
        - Tone indicators (Success, Error, Warning, Information)
        - Emotional indicators
        - Recommendation urgency
        
    .PARAMETER ResponseText
        The Claude response text to analyze
        
    .PARAMETER DetailedAnalysis
        Switch to perform more detailed sentiment analysis
        
    .OUTPUTS
        PSCustomObject containing sentiment analysis results
        
    .EXAMPLE
        $sentiment = Analyze-ResponseSentiment -ResponseText $claudeResponse -DetailedAnalysis
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$ResponseText,
        
        [switch]$DetailedAnalysis
    )
    
    try {
        Write-Verbose "Analyzing response sentiment ($($ResponseText.Length) characters)"
        
        $sentiment = [PSCustomObject]@{
            OverallSentiment = "Neutral"
            Confidence = 0
            Tone = "Information"
            PositiveIndicators = @()
            NegativeIndicators = @()
            WarningIndicators = @()
            UrgencyLevel = "Normal"
            EmotionalTone = "Professional"
            RecommendationPresent = $false
            ActionRequired = $false
            AnalyzedAt = Get-Date
            WordCount = 0
            SentenceCount = 0
        }
        
        if ([string]::IsNullOrWhiteSpace($ResponseText)) {
            Write-Warning "Response text is empty or null"
            return $sentiment
        }
        
        # Basic text statistics
        $words = $ResponseText -split '\s+' | Where-Object { $_ -match '\w' }
        $sentiment.WordCount = $words.Count
        $sentiment.SentenceCount = ($ResponseText -split '[.!?]+').Count - 1
        
        # Define sentiment indicators
        $positiveWords = @(
            'success', 'successful', 'complete', 'completed', 'working', 'fixed', 'resolved',
            'excellent', 'good', 'great', 'perfect', 'optimal', 'improved', 'enhanced',
            'ready', 'available', 'functional', 'stable', 'reliable', 'efficient'
        )
        
        $negativeWords = @(
            'error', 'fail', 'failed', 'failure', 'broken', 'missing', 'not found',
            'critical', 'severe', 'urgent', 'problem', 'issue', 'bug', 'crash',
            'timeout', 'exception', 'corrupt', 'invalid', 'incorrect', 'wrong'
        )
        
        $warningWords = @(
            'warning', 'caution', 'attention', 'notice', 'alert', 'deprecated',
            'temporary', 'workaround', 'fallback', 'limited', 'partial', 'incomplete'
        )
        
        $urgencyWords = @(
            'immediate', 'urgent', 'critical', 'emergency', 'asap', 'quickly',
            'now', 'priority', 'important', 'must', 'required', 'necessary'
        )
        
        # Convert response to lowercase for analysis
        $lowerResponse = $ResponseText.ToLower()
        
        # Count sentiment indicators
        $positiveCount = 0
        $negativeCount = 0
        $warningCount = 0
        $urgencyCount = 0
        
        foreach ($word in $positiveWords) {
            $matches = [regex]::Matches($lowerResponse, "\b$word\b")
            if ($matches.Count -gt 0) {
                $positiveCount += $matches.Count
                $sentiment.PositiveIndicators += "$word ($($matches.Count))"
            }
        }
        
        foreach ($word in $negativeWords) {
            $matches = [regex]::Matches($lowerResponse, "\b$word\b")
            if ($matches.Count -gt 0) {
                $negativeCount += $matches.Count
                $sentiment.NegativeIndicators += "$word ($($matches.Count))"
            }
        }
        
        foreach ($word in $warningWords) {
            $matches = [regex]::Matches($lowerResponse, "\b$word\b")
            if ($matches.Count -gt 0) {
                $warningCount += $matches.Count
                $sentiment.WarningIndicators += "$word ($($matches.Count))"
            }
        }
        
        foreach ($word in $urgencyWords) {
            $matches = [regex]::Matches($lowerResponse, "\b$word\b")
            if ($matches.Count -gt 0) {
                $urgencyCount += $matches.Count
            }
        }
        
        # Determine overall sentiment
        $totalSentiment = $positiveCount - $negativeCount
        if ($totalSentiment > 2) {
            $sentiment.OverallSentiment = "Positive"
            $sentiment.Confidence = [Math]::Min(90, 50 + ($totalSentiment * 5))
        } elseif ($totalSentiment < -2) {
            $sentiment.OverallSentiment = "Negative"  
            $sentiment.Confidence = [Math]::Min(90, 50 + ([Math]::Abs($totalSentiment) * 5))
        } else {
            $sentiment.OverallSentiment = "Neutral"
            $sentiment.Confidence = [Math]::Max(30, 60 - ([Math]::Abs($totalSentiment) * 10))
        }
        
        # Determine tone
        if ($negativeCount -gt 3) {
            $sentiment.Tone = "Error"
        } elseif ($warningCount -gt 2) {
            $sentiment.Tone = "Warning"
        } elseif ($positiveCount -gt 3) {
            $sentiment.Tone = "Success"
        } else {
            $sentiment.Tone = "Information"
        }
        
        # Determine urgency level
        if ($urgencyCount -gt 2) {
            $sentiment.UrgencyLevel = "High"
        } elseif ($urgencyCount -gt 0) {
            $sentiment.UrgencyLevel = "Medium"
        } else {
            $sentiment.UrgencyLevel = "Normal"
        }
        
        # Check for recommendations
        if ($ResponseText -match 'RECOMMENDATION|RECOMMENDED|should|need to|suggest') {
            $sentiment.RecommendationPresent = $true
        }
        
        # Check if action is required
        if ($ResponseText -match 'TEST|FIX|COMPILE|RESTART|ERROR|must|required|need to') {
            $sentiment.ActionRequired = $true
        }
        
        # Determine emotional tone (if detailed analysis requested)
        if ($DetailedAnalysis) {
            if ($positiveCount -gt $negativeCount * 2) {
                $sentiment.EmotionalTone = "Encouraging"
            } elseif ($negativeCount -gt $positiveCount * 2) {
                $sentiment.EmotionalTone = "Concerned"
            } elseif ($warningCount -gt 0) {
                $sentiment.EmotionalTone = "Cautious"
            } else {
                $sentiment.EmotionalTone = "Professional"
            }
        }
        
        Write-Verbose "Sentiment analysis complete:"
        Write-Verbose "  Overall Sentiment: $($sentiment.OverallSentiment) ($($sentiment.Confidence)%)"
        Write-Verbose "  Tone: $($sentiment.Tone)"
        Write-Verbose "  Urgency: $($sentiment.UrgencyLevel)"
        Write-Verbose "  Positive indicators: $($sentiment.PositiveIndicators.Count)"
        Write-Verbose "  Negative indicators: $($sentiment.NegativeIndicators.Count)"
        Write-Verbose "  Warning indicators: $($sentiment.WarningIndicators.Count)"
        
        return $sentiment
        
    } catch {
        Write-Error "Error analyzing response sentiment: $_"
        return [PSCustomObject]@{
            OverallSentiment = "Unknown"
            Confidence = 0
            Tone = "Error"
            PositiveIndicators = @()
            NegativeIndicators = @()
            WarningIndicators = @()
            UrgencyLevel = "Unknown"
            EmotionalTone = "Unknown"
            RecommendationPresent = $false
            ActionRequired = $false
            AnalyzedAt = Get-Date
            WordCount = 0
            SentenceCount = 0
            Error = $_.Exception.Message
        }
    }
}

# Export function
Export-ModuleMember -Function 'Analyze-ResponseSentiment'