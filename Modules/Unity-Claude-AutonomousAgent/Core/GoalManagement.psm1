# GoalManagement.psm1
# Goal tracking and management for advanced conversation management

# Import core module for shared variables
Import-Module (Join-Path $PSScriptRoot "ConversationCore.psm1") -Force

function Add-ConversationGoal {
    <#
    .SYNOPSIS
    Adds a new conversation goal with tracking capabilities
    
    .DESCRIPTION
    Creates and tracks conversation goals with success criteria and measurement
    
    .PARAMETER Type
    Type of goal (ProblemSolving, Information, TaskCompletion, LearningObjective)
    
    .PARAMETER Description
    Description of the goal
    
    .PARAMETER Priority
    Priority level (High, Medium, Low)
    
    .PARAMETER SuccessCriteria
    Criteria for measuring goal completion
    #>
    param(
        [Parameter(Mandatory = $true)]
        [ValidateSet("ProblemSolving", "Information", "TaskCompletion", "LearningObjective")]
        [string]$Type,
        
        [Parameter(Mandatory = $true)]
        [string]$Description,
        
        [ValidateSet("High", "Medium", "Low")]
        [string]$Priority = "Medium",
        
        [hashtable]$SuccessCriteria = @{}
    )
    
    Write-StateLog "Adding conversation goal: $Type - $Description" -Level "INFO"
    
    try {
        $goal = [PSCustomObject]@{
            Id = [Guid]::NewGuid().ToString()
            Type = $Type
            Description = $Description
            Priority = $Priority
            SuccessCriteria = $SuccessCriteria
            Status = "Active"
            Progress = 0.0
            CreatedAt = Get-Date
            UpdatedAt = Get-Date
            SessionId = $script:ConversationState.SessionId
            CompletedAt = $null
            EffectivenessScore = 0.0
            RelatedPrompts = @()
            Milestones = @()
        }
        
        $script:ConversationGoals += $goal
        
        # Update conversation effectiveness
        Update-ConversationEffectiveness
        
        # Persist goals
        Save-ConversationGoals
        
        Write-StateLog "Added conversation goal: $($goal.Id)" -Level "SUCCESS"
        
        return @{
            Success = $true
            GoalId = $goal.Id
            TotalGoals = $script:ConversationGoals.Count
        }
    }
    catch {
        Write-StateLog "Failed to add conversation goal: $_" -Level "ERROR"
        return @{
            Success = $false
            Error = $_.Exception.Message
        }
    }
}

function Update-ConversationGoal {
    <#
    .SYNOPSIS
    Updates an existing conversation goal
    
    .DESCRIPTION
    Updates goal progress, status, and tracking information
    
    .PARAMETER GoalId
    ID of the goal to update
    
    .PARAMETER Progress
    Progress percentage (0-100)
    
    .PARAMETER Status
    New status (Active, Completed, Failed, Suspended)
    
    .PARAMETER Milestone
    Optional milestone to add
    #>
    param(
        [Parameter(Mandatory = $true)]
        [string]$GoalId,
        
        [ValidateRange(0, 100)]
        [double]$Progress,
        
        [ValidateSet("Active", "Completed", "Failed", "Suspended")]
        [string]$Status,
        
        [string]$Milestone
    )
    
    Write-StateLog "Updating conversation goal: $GoalId" -Level "DEBUG"
    
    try {
        $goal = $script:ConversationGoals | Where-Object { $_.Id -eq $GoalId }
        
        if (-not $goal) {
            Write-StateLog "Goal not found: $GoalId" -Level "WARNING"
            return @{
                Success = $false
                Reason = "Goal not found"
            }
        }
        
        # Update progress
        if ($PSBoundParameters.ContainsKey('Progress')) {
            $goal.Progress = $Progress
            Write-StateLog "Updated goal progress to $Progress%" -Level "DEBUG"
        }
        
        # Update status
        if ($PSBoundParameters.ContainsKey('Status')) {
            $goal.Status = $Status
            
            if ($Status -eq "Completed") {
                $goal.CompletedAt = Get-Date
                $goal.Progress = 100.0
                Write-StateLog "Goal completed: $($goal.Description)" -Level "SUCCESS"
            }
        }
        
        # Add milestone
        if ($PSBoundParameters.ContainsKey('Milestone')) {
            $goal.Milestones += @{
                Description = $Milestone
                Timestamp = Get-Date
                ProgressAtTime = $goal.Progress
            }
            Write-StateLog "Added milestone to goal: $Milestone" -Level "DEBUG"
        }
        
        $goal.UpdatedAt = Get-Date
        
        # Calculate effectiveness score
        Calculate-GoalEffectiveness -Goal $goal
        
        # Update overall effectiveness
        Update-ConversationEffectiveness
        
        # Persist changes
        Save-ConversationGoals
        
        return @{
            Success = $true
            Goal = $goal
        }
    }
    catch {
        Write-StateLog "Failed to update conversation goal: $_" -Level "ERROR"
        return @{
            Success = $false
            Error = $_.Exception.Message
        }
    }
}

function Get-ConversationGoals {
    <#
    .SYNOPSIS
    Gets conversation goals
    
    .DESCRIPTION
    Returns filtered list of conversation goals
    
    .PARAMETER Status
    Filter by status
    
    .PARAMETER Type
    Filter by type
    
    .PARAMETER Priority
    Filter by priority
    #>
    param(
        [ValidateSet("Active", "Completed", "Failed", "Suspended", "All")]
        [string]$Status = "All",
        
        [ValidateSet("ProblemSolving", "Information", "TaskCompletion", "LearningObjective", "All")]
        [string]$Type = "All",
        
        [ValidateSet("High", "Medium", "Low", "All")]
        [string]$Priority = "All"
    )
    
    Write-StateLog "Getting conversation goals (Status: $Status, Type: $Type)" -Level "DEBUG"
    
    try {
        $filteredGoals = $script:ConversationGoals
        
        # Filter by status
        if ($Status -ne "All") {
            $filteredGoals = $filteredGoals | Where-Object { $_.Status -eq $Status }
        }
        
        # Filter by type
        if ($Type -ne "All") {
            $filteredGoals = $filteredGoals | Where-Object { $_.Type -eq $Type }
        }
        
        # Filter by priority
        if ($Priority -ne "All") {
            $filteredGoals = $filteredGoals | Where-Object { $_.Priority -eq $Priority }
        }
        
        # Sort by priority and creation time
        $priorityMap = @{ "High" = 1; "Medium" = 2; "Low" = 3 }
        $filteredGoals = $filteredGoals | Sort-Object { $priorityMap[$_.Priority] }, CreatedAt
        
        Write-StateLog "Retrieved $($filteredGoals.Count) goals" -Level "INFO"
        
        return @{
            Success = $true
            Goals = $filteredGoals
            TotalCount = $filteredGoals.Count
        }
    }
    catch {
        Write-StateLog "Failed to get conversation goals: $_" -Level "ERROR"
        return @{
            Success = $false
            Error = $_.Exception.Message
        }
    }
}

function Calculate-GoalRelevance {
    <#
    .SYNOPSIS
    Calculates relevance score for goals based on current context
    
    .DESCRIPTION
    Determines which goals are most relevant to current conversation
    
    .PARAMETER Context
    Current conversation context
    #>
    param(
        [Parameter(Mandatory = $true)]
        [hashtable]$Context
    )
    
    Write-StateLog "Calculating goal relevance" -Level "DEBUG"
    
    try {
        $relevanceScores = @()
        
        foreach ($goal in ($script:ConversationGoals | Where-Object { $_.Status -eq "Active" })) {
            $score = 0.0
            
            # Base score on priority
            switch ($goal.Priority) {
                "High" { $score += 0.5 }
                "Medium" { $score += 0.3 }
                "Low" { $score += 0.1 }
            }
            
            # Score based on progress (prefer partially completed goals)
            if ($goal.Progress -gt 0 -and $goal.Progress -lt 100) {
                $score += 0.2 * ($goal.Progress / 100)
            }
            
            # Score based on recency
            $hoursSinceUpdate = ((Get-Date) - $goal.UpdatedAt).TotalHours
            if ($hoursSinceUpdate -lt 1) { $score += 0.2 }
            elseif ($hoursSinceUpdate -lt 4) { $score += 0.1 }
            
            # Check for keyword matches in recent prompts
            if ($Context.LastPrompt) {
                $keywords = $goal.Description -split '\s+' | Where-Object { $_.Length -gt 4 }
                foreach ($keyword in $keywords) {
                    if ($Context.LastPrompt.Content -match $keyword) {
                        $score += 0.1
                    }
                }
            }
            
            $relevanceScores += [PSCustomObject]@{
                GoalId = $goal.Id
                Goal = $goal
                RelevanceScore = [Math]::Min($score, 1.0)
            }
        }
        
        # Sort by relevance score
        $relevanceScores = $relevanceScores | Sort-Object RelevanceScore -Descending
        
        Write-StateLog "Calculated relevance for $($relevanceScores.Count) goals" -Level "INFO"
        
        return @{
            Success = $true
            RelevanceScores = $relevanceScores
            MostRelevant = $relevanceScores | Select-Object -First 1
        }
    }
    catch {
        Write-StateLog "Failed to calculate goal relevance: $_" -Level "ERROR"
        return @{
            Success = $false
            Error = $_.Exception.Message
        }
    }
}

# Private helper functions
function Calculate-GoalEffectiveness {
    param($Goal)
    
    try {
        $effectiveness = 0.0
        
        # Progress contribution (40%)
        $effectiveness += ($Goal.Progress / 100) * 0.4
        
        # Time efficiency (30%)
        if ($Goal.Status -eq "Completed" -and $Goal.CompletedAt) {
            $duration = ($Goal.CompletedAt - $Goal.CreatedAt).TotalHours
            # Assume goals should complete within 4 hours for max efficiency
            $timeEfficiency = [Math]::Max(0, 1 - ($duration / 4))
            $effectiveness += $timeEfficiency * 0.3
        }
        elseif ($Goal.Status -eq "Active") {
            # Partial credit for active goals based on progress rate
            $duration = ((Get-Date) - $Goal.CreatedAt).TotalHours
            if ($duration -gt 0) {
                $progressRate = $Goal.Progress / $duration
                $effectiveness += [Math]::Min($progressRate / 25, 1) * 0.15  # 25% per hour is ideal
            }
        }
        
        # Milestone achievement (30%)
        if ($Goal.Milestones.Count -gt 0) {
            $milestoneScore = [Math]::Min($Goal.Milestones.Count / 5, 1)  # Max credit at 5 milestones
            $effectiveness += $milestoneScore * 0.3
        }
        
        $Goal.EffectivenessScore = [Math]::Round($effectiveness, 3)
    }
    catch {
        Write-StateLog "Error calculating goal effectiveness: $_" -Level "WARNING"
    }
}

function Update-ConversationEffectiveness {
    try {
        $activeGoals = $script:ConversationGoals | Where-Object { $_.Status -eq "Active" }
        $completedGoals = $script:ConversationGoals | Where-Object { $_.Status -eq "Completed" }
        
        $script:ConversationEffectiveness = @{
            TotalGoals = $script:ConversationGoals.Count
            ActiveGoals = $activeGoals.Count
            CompletedGoals = $completedGoals.Count
            FailedGoals = ($script:ConversationGoals | Where-Object { $_.Status -eq "Failed" }).Count
            AverageProgress = if ($activeGoals) { ($activeGoals.Progress | Measure-Object -Average).Average } else { 0 }
            CompletionRate = if ($script:ConversationGoals.Count -gt 0) { 
                [Math]::Round($completedGoals.Count / $script:ConversationGoals.Count * 100, 1) 
            } else { 0 }
            AverageEffectiveness = if ($script:ConversationGoals.Count -gt 0) {
                [Math]::Round(($script:ConversationGoals.EffectivenessScore | Measure-Object -Average).Average, 3)
            } else { 0 }
            LastUpdated = Get-Date
        }
        
        # Save effectiveness metrics
        Save-ConversationEffectiveness
    }
    catch {
        Write-StateLog "Error updating conversation effectiveness: $_" -Level "WARNING"
    }
}

function Save-ConversationGoals {
    Write-StateLog "Saving conversation goals" -Level "DEBUG"
    
    try {
        if ($script:ConversationGoals.Count -gt 0) {
            $goalsData = $script:ConversationGoals | ConvertTo-Json -Depth 10
            Set-Content -Path $script:GoalsPersistencePath -Value $goalsData -Force
            
            Write-StateLog "Conversation goals saved ($($script:ConversationGoals.Count) goals)" -Level "DEBUG"
        }
    }
    catch {
        Write-StateLog "Failed to save conversation goals: $_" -Level "WARNING"
    }
}

function Save-ConversationEffectiveness {
    Write-StateLog "Saving conversation effectiveness" -Level "DEBUG"
    
    try {
        $effectivenessData = $script:ConversationEffectiveness | ConvertTo-Json -Depth 10
        Set-Content -Path $script:EffectivenessPersistencePath -Value $effectivenessData -Force
        
        Write-StateLog "Conversation effectiveness saved" -Level "DEBUG"
    }
    catch {
        Write-StateLog "Failed to save conversation effectiveness: $_" -Level "WARNING"
    }
}

Export-ModuleMember -Function Add-ConversationGoal, Update-ConversationGoal, Get-ConversationGoals, Calculate-GoalRelevance
# SIG # Begin signature block
# MIIFzgYJKoZIhvcNAQcCoIIFvzCCBbsCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCCrJlZ3dqzQm5qE
# kCJ9CpVSTw1Qfuo434MzchZrxUWRfKCCAzAwggMsMIICFKADAgECAhB1HRbZIqgr
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
# MAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIMGsbb+JkM21B9rIGC65p150
# MTv+pkCV3lutnSTZypBjMA0GCSqGSIb3DQEBAQUABIIBAH6GRWnZr+mLy4O4niwP
# oSfmAg06xO2A7YWaR/uKZspFgUpsQ6DB+kdj2FTPFjwOBizD42UyicFJh93if4Me
# Byu7a35HEIwIKVmX3Zm/kcMpgN0U/Jliku+gsA9NxfwELZ4TYnlca8HCTxUxnfeD
# SwSJppew5GGaEWBLqBsevvhR477Bg4x2DMLeA3cIjBeM1Mjz3dHr7lKc2Ke4IVea
# RDnReuIBN6XSetfpfBNzRdkb1WqcCYfKejZStszHnUCcSxJx4JWK4z2+jrMvG1a8
# AQnz5Ly9vPnKA+OuEjD1FC0eqk7HkKfjnvAdCrolB+NdyJp+J7+UvoFQvVs2un9v
# SnA=
# SIG # End signature block
