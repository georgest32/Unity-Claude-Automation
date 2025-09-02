# RoleAwareManagement.psm1
# Role-aware history and dialogue pattern management

# Import core module for shared variables
Import-Module (Join-Path $PSScriptRoot "ConversationCore.psm1") -Force

function Add-RoleAwareHistoryItem {
    <#
    .SYNOPSIS
    Adds a role-aware item to conversation history
    
    .DESCRIPTION
    Tracks conversation with role attribution and dialogue patterns
    
    .PARAMETER Role
    Role of the participant (User, Assistant, System)
    
    .PARAMETER Content
    Content of the interaction
    
    .PARAMETER Intent
    Detected intent of the interaction
    
    .PARAMETER Confidence
    Confidence score for intent detection
    #>
    param(
        [Parameter(Mandatory = $true)]
        [ValidateSet("User", "Assistant", "System")]
        [string]$Role,
        
        [Parameter(Mandatory = $true)]
        [string]$Content,
        
        [string]$Intent = "Unknown",
        
        [ValidateRange(0.0, 1.0)]
        [double]$Confidence = 0.5
    )
    
    Write-StateLog "Adding role-aware history item: $Role" -Level "DEBUG"
    
    try {
        $historyItem = [PSCustomObject]@{
            Id = [Guid]::NewGuid().ToString()
            Role = $Role
            Content = $Content
            Intent = $Intent
            Confidence = $Confidence
            Timestamp = Get-Date
            SessionId = $script:ConversationState.SessionId
            TurnNumber = $script:RoleAwareHistory.Count + 1
            ResponseLatency = $null
            Sentiment = Analyze-Sentiment -Text $Content
            Keywords = Extract-Keywords -Text $Content
            TopicShift = $false
            DialogueAct = Classify-DialogueAct -Content $Content -Role $Role
        }
        
        # Calculate response latency if this is a response to previous item
        if ($script:RoleAwareHistory.Count -gt 0) {
            $previousItem = $script:RoleAwareHistory[-1]
            if ($previousItem.Role -ne $Role) {
                $historyItem.ResponseLatency = ((Get-Date) - $previousItem.Timestamp).TotalSeconds
            }
            
            # Detect topic shift
            $historyItem.TopicShift = Detect-TopicShift -Current $historyItem -Previous $previousItem
        }
        
        # Add to role-aware history
        $script:RoleAwareHistory += $historyItem
        
        # Trim if needed
        if ($script:RoleAwareHistory.Count -gt $script:MaxRoleHistorySize) {
            $script:RoleAwareHistory = $script:RoleAwareHistory[-$script:MaxRoleHistorySize..-1]
            Write-StateLog "Trimmed role-aware history to $script:MaxRoleHistorySize items" -Level "DEBUG"
        }
        
        # Update dialogue patterns
        Update-DialoguePatterns -HistoryItem $historyItem
        
        Write-StateLog "Added role-aware history item (Turn: $($historyItem.TurnNumber))" -Level "DEBUG"
        
        return @{
            Success = $true
            ItemId = $historyItem.Id
            TurnNumber = $historyItem.TurnNumber
        }
    }
    catch {
        Write-StateLog "Failed to add role-aware history item: $_" -Level "ERROR"
        return @{
            Success = $false
            Error = $_.Exception.Message
        }
    }
}

function Get-RoleAwareHistory {
    <#
    .SYNOPSIS
    Gets role-aware conversation history
    
    .DESCRIPTION
    Returns filtered role-aware history with analysis
    
    .PARAMETER Role
    Filter by specific role
    
    .PARAMETER Limit
    Maximum number of items to return
    
    .PARAMETER IncludeAnalysis
    Include pattern analysis in results
    #>
    param(
        [ValidateSet("User", "Assistant", "System", "All")]
        [string]$Role = "All",
        
        [int]$Limit = 0,
        
        [switch]$IncludeAnalysis
    )
    
    Write-StateLog "Getting role-aware history (Role: $Role)" -Level "DEBUG"
    
    try {
        $filteredHistory = $script:RoleAwareHistory
        
        # Filter by role
        if ($Role -ne "All") {
            $filteredHistory = $filteredHistory | Where-Object { $_.Role -eq $Role }
        }
        
        # Apply limit
        if ($Limit -gt 0 -and $filteredHistory.Count -gt $Limit) {
            $filteredHistory = $filteredHistory[-$Limit..-1]
        }
        
        $result = @{
            Success = $true
            History = $filteredHistory
            TotalCount = $filteredHistory.Count
        }
        
        # Include analysis if requested
        if ($IncludeAnalysis) {
            $result.Analysis = Analyze-DialogueHistory -History $filteredHistory
        }
        
        Write-StateLog "Retrieved $($filteredHistory.Count) role-aware history items" -Level "INFO"
        
        return $result
    }
    catch {
        Write-StateLog "Failed to get role-aware history: $_" -Level "ERROR"
        return @{
            Success = $false
            Error = $_.Exception.Message
        }
    }
}

function Update-DialoguePatterns {
    <#
    .SYNOPSIS
    Updates dialogue pattern tracking
    
    .DESCRIPTION
    Analyzes and tracks dialogue patterns for improved conversation flow
    #>
    param(
        [Parameter(Mandatory = $true)]
        [PSCustomObject]$HistoryItem
    )
    
    Write-StateLog "Updating dialogue patterns" -Level "DEBUG"
    
    try {
        # Initialize patterns if needed
        if (-not $script:DialoguePatterns.ContainsKey("Patterns")) {
            $script:DialoguePatterns = @{
                Patterns = @{}
                Sequences = @()
                Statistics = @{
                    TotalTurns = 0
                    AverageResponseLatency = 0.0
                    TopicShifts = 0
                    IntentDistribution = @{}
                    DialogueActDistribution = @{}
                }
                LastUpdated = Get-Date
            }
        }
        
        # Update statistics
        $script:DialoguePatterns.Statistics.TotalTurns++
        
        # Track intent distribution
        if (-not $script:DialoguePatterns.Statistics.IntentDistribution.ContainsKey($HistoryItem.Intent)) {
            $script:DialoguePatterns.Statistics.IntentDistribution[$HistoryItem.Intent] = 0
        }
        $script:DialoguePatterns.Statistics.IntentDistribution[$HistoryItem.Intent]++
        
        # Track dialogue act distribution
        if (-not $script:DialoguePatterns.Statistics.DialogueActDistribution.ContainsKey($HistoryItem.DialogueAct)) {
            $script:DialoguePatterns.Statistics.DialogueActDistribution[$HistoryItem.DialogueAct] = 0
        }
        $script:DialoguePatterns.Statistics.DialogueActDistribution[$HistoryItem.DialogueAct]++
        
        # Track topic shifts
        if ($HistoryItem.TopicShift) {
            $script:DialoguePatterns.Statistics.TopicShifts++
        }
        
        # Update average response latency
        if ($HistoryItem.ResponseLatency) {
            $currentAvg = $script:DialoguePatterns.Statistics.AverageResponseLatency
            $totalTurns = $script:DialoguePatterns.Statistics.TotalTurns
            $script:DialoguePatterns.Statistics.AverageResponseLatency = 
                (($currentAvg * ($totalTurns - 1)) + $HistoryItem.ResponseLatency) / $totalTurns
        }
        
        # Track dialogue sequences (patterns of exchanges)
        if ($script:RoleAwareHistory.Count -ge 2) {
            $sequence = @()
            $lookback = [Math]::Min(5, $script:RoleAwareHistory.Count)
            for ($i = $script:RoleAwareHistory.Count - $lookback; $i -lt $script:RoleAwareHistory.Count; $i++) {
                $sequence += "$($script:RoleAwareHistory[$i].Role):$($script:RoleAwareHistory[$i].DialogueAct)"
            }
            
            $sequenceKey = $sequence -join " -> "
            if (-not $script:DialoguePatterns.Patterns.ContainsKey($sequenceKey)) {
                $script:DialoguePatterns.Patterns[$sequenceKey] = 0
            }
            $script:DialoguePatterns.Patterns[$sequenceKey]++
        }
        
        $script:DialoguePatterns.LastUpdated = Get-Date
        
        Write-StateLog "Updated dialogue patterns (Total turns: $($script:DialoguePatterns.Statistics.TotalTurns))" -Level "DEBUG"
    }
    catch {
        Write-StateLog "Failed to update dialogue patterns: $_" -Level "WARNING"
    }
}

function Update-ConversationEffectiveness {
    <#
    .SYNOPSIS
    Updates overall conversation effectiveness metrics
    
    .DESCRIPTION
    Calculates and tracks conversation quality and effectiveness
    #>
    
    Write-StateLog "Updating conversation effectiveness" -Level "DEBUG"
    
    try {
        # Initialize if needed
        if (-not $script:ConversationEffectiveness -or 
            -not $script:ConversationEffectiveness.ContainsKey("Metrics")) {
            $script:ConversationEffectiveness = @{
                Metrics = @{
                    Coherence = 0.0
                    Relevance = 0.0
                    Efficiency = 0.0
                    UserSatisfaction = 0.0
                    TaskCompletion = 0.0
                }
                Scores = @{
                    Overall = 0.0
                    Trend = "Stable"
                }
                History = @()
                LastCalculated = Get-Date
            }
        }
        
        # Calculate coherence (based on topic shifts and dialogue flow)
        $totalTurns = $script:DialoguePatterns.Statistics.TotalTurns
        if ($totalTurns -gt 0) {
            $topicShiftRate = $script:DialoguePatterns.Statistics.TopicShifts / $totalTurns
            $script:ConversationEffectiveness.Metrics.Coherence = [Math]::Max(0, 1 - ($topicShiftRate * 2))
        }
        
        # Calculate relevance (based on goal alignment)
        $activeGoals = $script:ConversationGoals | Where-Object { $_.Status -eq "Active" }
        if ($activeGoals) {
            $avgProgress = ($activeGoals.Progress | Measure-Object -Average).Average / 100
            $script:ConversationEffectiveness.Metrics.Relevance = $avgProgress
        }
        
        # Calculate efficiency (based on response latency and turn count)
        if ($script:DialoguePatterns.Statistics.AverageResponseLatency -gt 0) {
            # Assume 2 seconds is ideal response time
            $latencyScore = [Math]::Max(0, 1 - ($script:DialoguePatterns.Statistics.AverageResponseLatency / 10))
            $script:ConversationEffectiveness.Metrics.Efficiency = $latencyScore
        }
        
        # Calculate task completion
        $completedGoals = $script:ConversationGoals | Where-Object { $_.Status -eq "Completed" }
        if ($script:ConversationGoals.Count -gt 0) {
            $script:ConversationEffectiveness.Metrics.TaskCompletion = 
                $completedGoals.Count / $script:ConversationGoals.Count
        }
        
        # Estimate user satisfaction (based on error rate and success rate)
        $errorRate = if ($script:SessionMetadata.TotalCommands -gt 0) {
            $script:SessionMetadata.TotalErrors / $script:SessionMetadata.TotalCommands
        } else { 0 }
        $script:ConversationEffectiveness.Metrics.UserSatisfaction = [Math]::Max(0, 1 - $errorRate)
        
        # Calculate overall score
        $metrics = $script:ConversationEffectiveness.Metrics
        $script:ConversationEffectiveness.Scores.Overall = [Math]::Round(
            ($metrics.Coherence * 0.2 + 
             $metrics.Relevance * 0.25 + 
             $metrics.Efficiency * 0.2 + 
             $metrics.TaskCompletion * 0.25 + 
             $metrics.UserSatisfaction * 0.1), 3)
        
        # Track history for trend analysis
        $script:ConversationEffectiveness.History += @{
            Timestamp = Get-Date
            Score = $script:ConversationEffectiveness.Scores.Overall
        }
        
        # Keep only last 20 history items
        if ($script:ConversationEffectiveness.History.Count -gt 20) {
            $script:ConversationEffectiveness.History = 
                $script:ConversationEffectiveness.History[-20..-1]
        }
        
        # Determine trend
        if ($script:ConversationEffectiveness.History.Count -ge 3) {
            $recent = $script:ConversationEffectiveness.History[-3..-1].Score
            $avgRecent = ($recent | Measure-Object -Average).Average
            $previousScore = $script:ConversationEffectiveness.History[-4].Score
            
            if ($avgRecent -gt $previousScore + 0.05) {
                $script:ConversationEffectiveness.Scores.Trend = "Improving"
            } elseif ($avgRecent -lt $previousScore - 0.05) {
                $script:ConversationEffectiveness.Scores.Trend = "Declining"
            } else {
                $script:ConversationEffectiveness.Scores.Trend = "Stable"
            }
        }
        
        $script:ConversationEffectiveness.LastCalculated = Get-Date
        
        Write-StateLog "Updated conversation effectiveness (Score: $($script:ConversationEffectiveness.Scores.Overall))" -Level "DEBUG"
    }
    catch {
        Write-StateLog "Failed to update conversation effectiveness: $_" -Level "WARNING"
    }
}

# Private helper functions
function Analyze-Sentiment {
    param([string]$Text)
    
    # Simple sentiment analysis based on keyword presence
    $positiveWords = @('good', 'great', 'excellent', 'perfect', 'success', 'worked', 'thanks', 'helpful')
    $negativeWords = @('bad', 'error', 'failed', 'wrong', 'issue', 'problem', 'broken', 'unable')
    
    $positiveCount = ($positiveWords | Where-Object { $Text -match $_ }).Count
    $negativeCount = ($negativeWords | Where-Object { $Text -match $_ }).Count
    
    if ($positiveCount -gt $negativeCount) { return "Positive" }
    elseif ($negativeCount -gt $positiveCount) { return "Negative" }
    else { return "Neutral" }
}

function Extract-Keywords {
    param([string]$Text)
    
    # Extract significant words (simple implementation)
    $stopWords = @('the', 'is', 'at', 'which', 'on', 'a', 'an', 'as', 'are', 'was', 'were', 'to', 'of', 'for', 'with', 'in')
    $words = $Text -split '\s+' | Where-Object { 
        $_.Length -gt 3 -and $_ -notin $stopWords 
    } | Select-Object -Unique -First 5
    
    return $words
}

function Classify-DialogueAct {
    param(
        [string]$Content,
        [string]$Role
    )
    
    # Simple dialogue act classification
    if ($Content -match '\?') { return "Question" }
    elseif ($Content -match '^(yes|no|ok|sure|agreed)') { return "Agreement" }
    elseif ($Content -match 'please|could you|would you|can you') { return "Request" }
    elseif ($Content -match 'because|since|therefore') { return "Explanation" }
    elseif ($Content -match 'thank|thanks|appreciate') { return "Acknowledgment" }
    elseif ($Role -eq "System") { return "SystemMessage" }
    elseif ($Role -eq "Assistant" -and $Content -match 'error|failed|unable') { return "ErrorReport" }
    else { return "Statement" }
}

function Detect-TopicShift {
    param(
        [PSCustomObject]$Current,
        [PSCustomObject]$Previous
    )
    
    # Simple topic shift detection based on keyword overlap
    if (-not $Previous.Keywords -or -not $Current.Keywords) { return $false }
    
    $overlap = $Previous.Keywords | Where-Object { $_ -in $Current.Keywords }
    $overlapRatio = $overlap.Count / [Math]::Max($Previous.Keywords.Count, 1)
    
    return ($overlapRatio -lt 0.3)  # Less than 30% overlap suggests topic shift
}

function Analyze-DialogueHistory {
    param([array]$History)
    
    if ($History.Count -eq 0) { return @{} }
    
    return @{
        TurnCount = $History.Count
        RoleDistribution = $History | Group-Object Role | ForEach-Object { 
            @{ $_.Name = $_.Count } 
        }
        AverageResponseLatency = [Math]::Round(
            ($History | Where-Object { $_.ResponseLatency } | 
             Measure-Object ResponseLatency -Average).Average, 2)
        SentimentDistribution = $History | Group-Object Sentiment | ForEach-Object { 
            @{ $_.Name = $_.Count } 
        }
        TopicShifts = ($History | Where-Object { $_.TopicShift }).Count
        DialogueActDistribution = $History | Group-Object DialogueAct | ForEach-Object { 
            @{ $_.Name = $_.Count } 
        }
    }
}

Export-ModuleMember -Function Add-RoleAwareHistoryItem, Get-RoleAwareHistory, Update-DialoguePatterns, Update-ConversationEffectiveness
# SIG # Begin signature block
# MIIFzgYJKoZIhvcNAQcCoIIFvzCCBbsCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCD6k+yNbhHjMYm2
# L3r92qznoHLdBCm3QXPxd0pq1MBPu6CCAzAwggMsMIICFKADAgECAhB1HRbZIqgr
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
# MAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIBaN6wTeqFOrPlml79rNVwaL
# FWyrtJASItqlEIWvYzwKMA0GCSqGSIb3DQEBAQUABIIBABqksO6rJlX3dEZ14Hvs
# J3k5LMfoJRCcWoD3h3p1DwHzi8RYBT9JvJWBffDgtI30iFThN1tOpSCDjD6VKXvH
# /qpfjyl+73+mgOzSqPvFMEy3gnG4hvicYw/6R9YYA8x2JLO/PLwqy7PN9e2YqGDa
# 6wvtKQqbDvYRxXvMorUwuavfJbJDT2cMRcl+5aQP5SkwmoR7Xuadiq3gHCaetSIG
# RSb4vkiCmteoYgcgZkdHSJDpZW7D1l2KFhDpEXxDoltuzSoHbtyTQ9NRQrsAxncn
# N3aTcXU8NEsjV6twYvMeG9WWofbw1H9JlU9j/n/aVQVkKlJ0+xgj+THhstna6B5b
# l64=
# SIG # End signature block
