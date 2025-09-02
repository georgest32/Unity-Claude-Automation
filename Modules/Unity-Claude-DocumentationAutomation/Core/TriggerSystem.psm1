#region Module Header
<#
.SYNOPSIS
    Documentation Auto-Generation Trigger System
    
.DESCRIPTION
    Handles registration, management, and execution of documentation auto-generation
    triggers including file changes, Git commits, scheduled updates, and manual triggers.
    
.VERSION
    2.0.0
    
.AUTHOR
    Unity-Claude-Automation
#>
#endregion

#region Trigger Management Functions

function Register-DocumentationTrigger {
    <#
    .SYNOPSIS
        Registers an auto-generation trigger
    .DESCRIPTION
        Sets up triggers for automatic documentation updates
    .PARAMETER Name
        Trigger name
    .PARAMETER Type
        Trigger type (FileChange, GitCommit, Schedule, Manual)
    .PARAMETER Condition
        Trigger condition
    .EXAMPLE
        Register-DocumentationTrigger -Name "PSM1Changes" -Type FileChange -Condition "*.psm1"
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Name,
        [Parameter(Mandatory)]
        [ValidateSet('FileChange', 'GitCommit', 'Schedule', 'Manual', 'APICall')]
        [string]$Type,
        [Parameter(Mandatory)]
        [string]$Condition,
        [string]$Action,
        [hashtable]$Parameters = @{},
        [int]$Priority = 5,
        [switch]$Enabled = $true
    )
    
    try {
        $trigger = @{
            Name = $Name
            Type = $Type
            Condition = $Condition
            Action = $Action
            Parameters = $Parameters
            Priority = $Priority
            Enabled = $Enabled.IsPresent
            CreatedAt = Get-Date
            LastTriggered = $null
            TriggerCount = 0
        }
        
        # Remove existing trigger with same name
        $script:DocumentationAutomationConfig.ActiveTriggers = 
            $script:DocumentationAutomationConfig.ActiveTriggers | Where-Object { $_.Name -ne $Name }
        
        # Add new trigger
        $script:DocumentationAutomationConfig.ActiveTriggers += $trigger
        
        Write-Host "Documentation trigger '$Name' registered successfully" -ForegroundColor Green
        Write-Verbose "Type: $Type, Condition: $Condition"
        
        return $trigger
        
    } catch {
        Write-Error "Failed to register documentation trigger: $_"
        throw
    }
}

function Unregister-DocumentationTrigger {
    <#
    .SYNOPSIS
        Unregisters a documentation trigger
    .DESCRIPTION
        Removes trigger from active triggers list
    .PARAMETER Name
        Trigger name to remove
    .EXAMPLE
        Unregister-DocumentationTrigger -Name "PSM1Changes"
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Name
    )
    
    try {
        $initialCount = $script:DocumentationAutomationConfig.ActiveTriggers.Count
        $script:DocumentationAutomationConfig.ActiveTriggers = 
            $script:DocumentationAutomationConfig.ActiveTriggers | Where-Object { $_.Name -ne $Name }
        
        $removedCount = $initialCount - $script:DocumentationAutomationConfig.ActiveTriggers.Count
        
        if ($removedCount -eq 0) {
            Write-Warning "Trigger '$Name' not found"
        } else {
            Write-Host "Trigger '$Name' unregistered successfully" -ForegroundColor Green
        }
        
    } catch {
        Write-Error "Failed to unregister documentation trigger: $_"
        throw
    }
}

function Get-DocumentationTriggers {
    <#
    .SYNOPSIS
        Gets registered documentation triggers
    .DESCRIPTION
        Returns list of registered triggers with status
    .PARAMETER Name
        Get specific trigger by name
    .PARAMETER Type
        Filter by trigger type
    .EXAMPLE
        Get-DocumentationTriggers -Type FileChange
    #>
    [CmdletBinding()]
    param(
        [string]$Name,
        [ValidateSet('FileChange', 'GitCommit', 'Schedule', 'Manual', 'APICall', 'All')]
        [string]$Type = 'All',
        [switch]$EnabledOnly
    )
    
    try {
        $triggers = $script:DocumentationAutomationConfig.ActiveTriggers
        
        if ($Name) {
            return $triggers | Where-Object { $_.Name -eq $Name }
        }
        
        if ($Type -ne 'All') {
            $triggers = $triggers | Where-Object { $_.Type -eq $Type }
        }
        
        if ($EnabledOnly) {
            $triggers = $triggers | Where-Object { $_.Enabled }
        }
        
        return $triggers | Sort-Object Priority, Name
        
    } catch {
        Write-Error "Error getting documentation triggers: $_"
        throw
    }
}

function Test-TriggerConditions {
    <#
    .SYNOPSIS
        Tests if trigger conditions are met
    .DESCRIPTION
        Evaluates trigger conditions and returns true if trigger should fire
    .PARAMETER TriggerName
        Name of trigger to test
    .EXAMPLE
        Test-TriggerConditions -TriggerName "PSM1Changes"
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$TriggerName
    )
    
    try {
        $trigger = $script:DocumentationAutomationConfig.ActiveTriggers | 
                   Where-Object { $_.Name -eq $TriggerName -and $_.Enabled }
        
        if (-not $trigger) {
            return $false
        }
        
        switch ($trigger.Type) {
            'FileChange' {
                # Check if matching files have been modified recently
                $files = Get-ChildItem -Path . -Filter $trigger.Condition -Recurse -File
                $recentFiles = $files | Where-Object { 
                    $_.LastWriteTime -gt (Get-Date).AddMinutes(-$script:DocumentationAutomationConfig.TriggerInterval)
                }
                return $recentFiles.Count -gt 0
            }
            'GitCommit' {
                # Check for recent commits
                try {
                    $recentCommits = git log --since="$($script:DocumentationAutomationConfig.TriggerInterval) minutes ago" --oneline
                    return $recentCommits.Count -gt 0
                } catch {
                    return $false
                }
            }
            'Schedule' {
                # Parse schedule and check if it's time
                # For now, simple interval-based scheduling
                if ($trigger.LastTriggered) {
                    $interval = [int]$trigger.Condition
                    return ((Get-Date) - $trigger.LastTriggered).TotalMinutes -ge $interval
                }
                return $true
            }
            'Manual' {
                # Manual triggers don't auto-fire
                return $false
            }
            'APICall' {
                # API triggers are handled externally
                return $false
            }
        }
        
        return $false
        
    } catch {
        Write-Error "Error testing trigger conditions: $_"
        return $false
    }
}

function Invoke-DocumentationUpdate {
    <#
    .SYNOPSIS
        Invokes documentation update from trigger
    .DESCRIPTION
        Executes documentation update process when trigger fires
    .PARAMETER TriggerName
        Name of trigger that fired
    .PARAMETER EnableGitHubPR
        Create GitHub PR for changes
    .EXAMPLE
        Invoke-DocumentationUpdate -TriggerName "PSM1Changes" -EnableGitHubPR
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$TriggerName,
        [switch]$EnableGitHubPR,
        [switch]$Force
    )
    
    try {
        $trigger = $script:DocumentationAutomationConfig.ActiveTriggers | 
                   Where-Object { $_.Name -eq $TriggerName }
        
        if (-not $trigger) {
            throw "Trigger '$TriggerName' not found"
        }
        
        Write-Host "Executing documentation update for trigger: $TriggerName" -ForegroundColor Cyan
        
        # Update trigger stats
        $trigger.LastTriggered = Get-Date
        $trigger.TriggerCount++
        
        # Create backup before changes
        $backupResult = New-DocumentationBackup -Reason "Pre-trigger: $TriggerName"
        
        try {
            # Determine what needs to be updated based on trigger type
            $changes = @()
            
            switch ($trigger.Type) {
                'FileChange' {
                    # Find changed files and update their documentation
                    $files = Get-ChildItem -Path . -Filter $trigger.Condition -Recurse -File
                    $recentFiles = $files | Where-Object { 
                        $_.LastWriteTime -gt (Get-Date).AddMinutes(-($script:DocumentationAutomationConfig.TriggerInterval * 2))
                    }
                    
                    foreach ($file in $recentFiles) {
                        $docPath = $file.FullName -replace '\.ps(m?)1$', '.md'
                        $docPath = $docPath -replace '\\Modules\\', '\docs\api\'
                        
                        # Generate documentation content (simplified for demo)
                        $content = @"
# $($file.BaseName)

Auto-generated documentation for $($file.Name)

Last updated: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
Source file: $($file.FullName)

## Overview
This file was automatically updated by the documentation system.

## Details
Generated from source file analysis.
"@
                        
                        $changes += @{
                            Type = if (Test-Path $docPath) { 'Update' } else { 'Create' }
                            Path = $docPath
                            Content = $content
                        }
                    }
                }
                'GitCommit' {
                    # Analyze recent commits and update affected documentation
                    $commits = git log --since="$($script:DocumentationAutomationConfig.TriggerInterval) minutes ago" --name-only --oneline
                    # Process commits to identify documentation that needs updates
                    # For demo, create a general update
                    $changes += @{
                        Type = 'Update'
                        Path = '.\docs\CHANGELOG.md'
                        Content = "# Changelog`n`nUpdated: $(Get-Date)`n`nRecent commits processed by automation.`n"
                    }
                }
            }
            
            if ($changes.Count -eq 0) {
                Write-Host "No documentation changes needed" -ForegroundColor Yellow
                return
            }
            
            # Apply changes
            foreach ($change in $changes) {
                $dir = Split-Path $change.Path -Parent
                if ($dir -and -not (Test-Path $dir)) {
                    New-Item -Path $dir -ItemType Directory -Force | Out-Null
                }
                
                switch ($change.Type) {
                    'Create' { 
                        New-Item -Path $change.Path -ItemType File -Force | Out-Null
                        Set-Content -Path $change.Path -Value $change.Content
                        Write-Host "Created: $($change.Path)" -ForegroundColor Green
                    }
                    'Update' { 
                        Set-Content -Path $change.Path -Value $change.Content 
                        Write-Host "Updated: $($change.Path)" -ForegroundColor Yellow
                    }
                }
            }
            
            # Create PR if requested
            if ($EnableGitHubPR -and $changes.Count -gt 0) {
                $prTitle = "docs: Auto-update from trigger '$TriggerName'"
                New-DocumentationPR -Title $prTitle -Changes $changes
            }
            
            Write-Host "Documentation update completed successfully" -ForegroundColor Green
            Write-Host "  Trigger: $TriggerName" -ForegroundColor Gray
            Write-Host "  Changes: $($changes.Count)" -ForegroundColor Gray
            Write-Host "  GitHub PR: $EnableGitHubPR" -ForegroundColor Gray
            
        } catch {
            Write-Error "Documentation update failed: $_"
            # Restore from backup on failure
            Write-Host "Attempting to restore from backup..." -ForegroundColor Yellow
            try {
                Restore-DocumentationBackup -BackupId $backupResult.Id -Force
                Write-Host "Restored from backup successfully" -ForegroundColor Green
            } catch {
                Write-Error "Failed to restore from backup: $_"
            }
            throw
        }
        
    } catch {
        Write-Error "Failed to invoke documentation update: $_"
        throw
    }
}

function Start-DocumentationReview {
    <#
    .SYNOPSIS
        Starts a documentation review workflow
    .DESCRIPTION
        Initiates review process for documentation changes
    .PARAMETER Changes
        Changes to review
    .PARAMETER Reviewers
        List of reviewers
    .EXAMPLE
        Start-DocumentationReview -Changes $changes -Reviewers @('user1', 'user2')
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [array]$Changes,
        [string[]]$Reviewers,
        [string]$ReviewType = 'Standard',
        [int]$TimeoutHours = 72
    )
    
    try {
        $reviewId = "review-$(Get-Date -Format 'yyyyMMdd-HHmmss')"
        
        $review = @{
            Id = $reviewId
            Changes = $Changes
            Reviewers = $Reviewers
            ReviewType = $ReviewType
            Status = 'Pending'
            CreatedAt = Get-Date
            TimeoutAt = (Get-Date).AddHours($TimeoutHours)
            Comments = @()
            Approvals = @()
            Rejections = @()
        }
        
        $script:DocumentationAutomationConfig.ReviewQueue += $review
        
        Write-Host "Documentation review started: $reviewId" -ForegroundColor Cyan
        Write-Host "  Changes: $($Changes.Count)" -ForegroundColor Gray
        Write-Host "  Reviewers: $($Reviewers -join ', ')" -ForegroundColor Gray
        Write-Host "  Timeout: $TimeoutHours hours" -ForegroundColor Gray
        
        return $review
        
    } catch {
        Write-Error "Failed to start documentation review: $_"
        throw
    }
}

function Get-ReviewStatus {
    <#
    .SYNOPSIS
        Gets status of documentation reviews
    .DESCRIPTION
        Returns current status of active reviews
    .PARAMETER ReviewId
        Specific review ID to check
    .EXAMPLE
        Get-ReviewStatus -ReviewId "review-20250825-143022"
    #>
    [CmdletBinding()]
    param(
        [string]$ReviewId,
        [ValidateSet('Pending', 'Approved', 'Rejected', 'Timeout', 'All')]
        [string]$Status = 'All'
    )
    
    try {
        $reviews = $script:DocumentationAutomationConfig.ReviewQueue
        
        if ($ReviewId) {
            return $reviews | Where-Object { $_.Id -eq $ReviewId }
        }
        
        if ($Status -ne 'All') {
            $reviews = $reviews | Where-Object { $_.Status -eq $Status }
        }
        
        return $reviews | Sort-Object CreatedAt -Descending
        
    } catch {
        Write-Error "Error getting review status: $_"
        throw
    }
}

function Approve-DocumentationChanges {
    <#
    .SYNOPSIS
        Approves documentation changes in review
    .DESCRIPTION
        Records approval for pending documentation review
    .PARAMETER ReviewId
        Review ID to approve
    .PARAMETER Reviewer
        Name of approving reviewer
    .EXAMPLE
        Approve-DocumentationChanges -ReviewId "review-20250825-143022" -Reviewer "user1"
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$ReviewId,
        [Parameter(Mandatory)]
        [string]$Reviewer,
        [string]$Comments
    )
    
    try {
        $review = $script:DocumentationAutomationConfig.ReviewQueue | Where-Object { $_.Id -eq $ReviewId }
        
        if (-not $review) {
            throw "Review '$ReviewId' not found"
        }
        
        if ($review.Status -ne 'Pending') {
            throw "Review '$ReviewId' is not in pending status"
        }
        
        # Record approval
        $approval = @{
            Reviewer = $Reviewer
            ApprovedAt = Get-Date
            Comments = $Comments
        }
        
        $review.Approvals += $approval
        
        # Check if all required approvals are received
        $requiredApprovals = if ($review.Reviewers) { $review.Reviewers.Count } else { 1 }
        
        if ($review.Approvals.Count -ge $requiredApprovals) {
            $review.Status = 'Approved'
            $review.ApprovedAt = Get-Date
            
            Write-Host "Review '$ReviewId' fully approved and ready for merge" -ForegroundColor Green
        } else {
            Write-Host "Review '$ReviewId' approved by $Reviewer ($($review.Approvals.Count)/$requiredApprovals)" -ForegroundColor Yellow
        }
        
        return $review
        
    } catch {
        Write-Error "Failed to approve documentation changes: $_"
        throw
    }
}

function Reject-DocumentationChanges {
    <#
    .SYNOPSIS
        Rejects documentation changes in review
    .DESCRIPTION
        Records rejection for pending documentation review
    .PARAMETER ReviewId
        Review ID to reject
    .PARAMETER Reviewer
        Name of rejecting reviewer
    .PARAMETER Reason
        Reason for rejection
    .EXAMPLE
        Reject-DocumentationChanges -ReviewId "review-20250825-143022" -Reviewer "user1" -Reason "Formatting issues"
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$ReviewId,
        [Parameter(Mandatory)]
        [string]$Reviewer,
        [Parameter(Mandatory)]
        [string]$Reason
    )
    
    try {
        $review = $script:DocumentationAutomationConfig.ReviewQueue | Where-Object { $_.Id -eq $ReviewId }
        
        if (-not $review) {
            throw "Review '$ReviewId' not found"
        }
        
        if ($review.Status -ne 'Pending') {
            throw "Review '$ReviewId' is not in pending status"
        }
        
        # Record rejection
        $rejection = @{
            Reviewer = $Reviewer
            RejectedAt = Get-Date
            Reason = $Reason
        }
        
        $review.Rejections += $rejection
        $review.Status = 'Rejected'
        $review.RejectedAt = Get-Date
        
        Write-Host "Review '$ReviewId' rejected by $Reviewer" -ForegroundColor Red
        Write-Host "  Reason: $Reason" -ForegroundColor Gray
        
        return $review
        
    } catch {
        Write-Error "Failed to reject documentation changes: $_"
        throw
    }
}

function Get-ReviewMetrics {
    <#
    .SYNOPSIS
        Gets review process metrics
    .DESCRIPTION
        Returns metrics about the documentation review process
    .PARAMETER Days
        Number of days to analyze (default: 30)
    .EXAMPLE
        Get-ReviewMetrics -Days 7
    #>
    [CmdletBinding()]
    param(
        [int]$Days = 30
    )
    
    try {
        $startDate = (Get-Date).AddDays(-$Days)
        $reviews = $script:DocumentationAutomationConfig.ReviewQueue | 
                  Where-Object { $_.CreatedAt -ge $startDate }
        
        $metrics = @{
            Period = "$Days days"
            TotalReviews = $reviews.Count
            Approved = ($reviews | Where-Object { $_.Status -eq 'Approved' }).Count
            Rejected = ($reviews | Where-Object { $_.Status -eq 'Rejected' }).Count
            Pending = ($reviews | Where-Object { $_.Status -eq 'Pending' }).Count
            Timeout = ($reviews | Where-Object { $_.Status -eq 'Timeout' }).Count
            AverageReviewTime = 0
            ApprovalRate = 0
        }
        
        # Calculate average review time for completed reviews
        $completedReviews = $reviews | Where-Object { $_.Status -in @('Approved', 'Rejected') }
        if ($completedReviews.Count -gt 0) {
            $totalTime = 0
            foreach ($review in $completedReviews) {
                $endTime = if ($review.ApprovedAt) { $review.ApprovedAt } else { $review.RejectedAt }
                $totalTime += ($endTime - $review.CreatedAt).TotalHours
            }
            $metrics.AverageReviewTime = [math]::Round($totalTime / $completedReviews.Count, 2)
        }
        
        # Calculate approval rate
        if ($metrics.TotalReviews -gt 0) {
            $metrics.ApprovalRate = [math]::Round(($metrics.Approved / $metrics.TotalReviews) * 100, 2)
        }
        
        return $metrics
        
    } catch {
        Write-Error "Error getting review metrics: $_"
        throw
    }
}

#endregion

Export-ModuleMember -Function @(
    'Register-DocumentationTrigger',
    'Unregister-DocumentationTrigger',
    'Get-DocumentationTriggers',
    'Test-TriggerConditions',
    'Invoke-DocumentationUpdate',
    'Start-DocumentationReview',
    'Get-ReviewStatus',
    'Approve-DocumentationChanges',
    'Reject-DocumentationChanges',
    'Get-ReviewMetrics'
)
# SIG # Begin signature block
# MIIFzgYJKoZIhvcNAQcCoIIFvzCCBbsCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCBHO4E5wUdQTaRq
# 1rVnjqadYfJIh+tcmOoRNMP5D4ana6CCAzAwggMsMIICFKADAgECAhB1HRbZIqgr
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
# MAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIMLUhIigs77C+g1nM2E68g6+
# CQZ6EDXmBFEOx296wtmoMA0GCSqGSIb3DQEBAQUABIIBAAZ6Ewl6mgA3wlzprsHx
# Rjf677/tSw10SMMn7qY0U/lPuxhaiSkIGmC4g1sqYItlDZIQrYZfhvP7czwxs346
# 2CTxTl1qur+H6oyvvbWDsu9Pj7Qusc8FJE2FmBP+YcEfNn4W+JfVwaDJjOnX8cIE
# 94L76tYVq3sorFG2Qmg0QljKrXopyvdsWiCAFPX83OoRBIBtsyboyk25wT7jKzxs
# xOIN5bC2XWEvcF+opzCwZg4V9egt5J0YqdbiNx+yEljaLMDDMY/gFqZshVMU6T5x
# YZS8k8C08U39lWw3A/IBzU6ZKYlngaNOgg5RGJ+mSy71Fm+k91Nc8ee6ocKxRE7l
# yrc=
# SIG # End signature block
