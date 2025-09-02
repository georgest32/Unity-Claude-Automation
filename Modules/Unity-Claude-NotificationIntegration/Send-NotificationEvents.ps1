function Send-UnityErrorNotificationEvent {
    <#
    .SYNOPSIS
    Sends notifications for Unity compilation errors
    #>
    [CmdletBinding()]
    param(
        [hashtable]$NotificationData,
        [hashtable]$Configuration
    )
    
    Write-SystemStatusLog "Sending Unity error notification" -Level 'DEBUG'
    
    try {
        # Create notification content
        $subject = "Unity Compilation Error - $($NotificationData.ErrorCount) Error(s) Detected"
        $severity = if ($NotificationData.ErrorCount -gt 5) { "Critical" } elseif ($NotificationData.ErrorCount -gt 2) { "High" } else { "Medium" }
        
        $messageContent = @{
            Subject = $subject
            Severity = $severity
            Source = $NotificationData.Source
            Timestamp = $NotificationData.Timestamp
            Details = @{
                ErrorCount = $NotificationData.ErrorCount
                WarningCount = $NotificationData.WarningCount
                LogFile = $NotificationData.LogFile
                Errors = $NotificationData.Errors
            }
            Summary = "Unity compilation failed with $($NotificationData.ErrorCount) error(s)"
        }
        
        # Send via configured notification methods
        $results = @()
        
        if ($Configuration.EmailNotifications.Enabled -and $Configuration.EmailNotifications.NotificationTypes.UnityCompilationError) {
            try {
                $emailResult = Send-EmailWithRetry -Configuration $Configuration.EmailNotifications -Content $messageContent
                $results += @{ Method = "Email"; Success = $emailResult.Success; Details = $emailResult }
            } catch {
                Write-SystemStatusLog "Failed to send Unity error email notification: $($_.Exception.Message)" -Level 'ERROR'
                $results += @{ Method = "Email"; Success = $false; Error = $_.Exception.Message }
            }
        }
        
        if ($Configuration.WebhookNotifications.Enabled -and $Configuration.WebhookNotifications.NotificationTypes.UnityCompilationError) {
            try {
                $webhookResult = Send-WebhookWithRetry -Configuration $Configuration.WebhookNotifications -Content $messageContent
                $results += @{ Method = "Webhook"; Success = $webhookResult.Success; Details = $webhookResult }
            } catch {
                Write-SystemStatusLog "Failed to send Unity error webhook notification: $($_.Exception.Message)" -Level 'ERROR'
                $results += @{ Method = "Webhook"; Success = $false; Error = $_.Exception.Message }
            }
        }
        
        Write-SystemStatusLog "Unity error notification sent via $($results.Count) method(s)" -Level 'INFO'
        return $results
        
    } catch {
        Write-SystemStatusLog "Error sending Unity error notification: $($_.Exception.Message)" -Level 'ERROR'
        throw $_
    }
}

function Send-UnityWarningNotification {
    <#
    .SYNOPSIS
    Sends notifications for Unity compilation warnings
    #>
    [CmdletBinding()]
    param(
        [hashtable]$NotificationData,
        [hashtable]$Configuration
    )
    
    Write-SystemStatusLog "Sending Unity warning notification" -Level 'DEBUG'
    
    try {
        $subject = "Unity Compilation Warning - $($NotificationData.WarningCount) Warning(s) Detected"
        $severity = if ($NotificationData.WarningCount -gt 10) { "Medium" } else { "Low" }
        
        $messageContent = @{
            Subject = $subject
            Severity = $severity
            Source = $NotificationData.Source
            Timestamp = $NotificationData.Timestamp
            Details = @{
                WarningCount = $NotificationData.WarningCount
                LogFile = $NotificationData.LogFile
            }
            Summary = "Unity compilation completed with $($NotificationData.WarningCount) warning(s)"
        }
        
        $results = @()
        
        if ($Configuration.EmailNotifications.Enabled) {
            try {
                $emailResult = Send-EmailWithRetry -Configuration $Configuration.EmailNotifications -Content $messageContent
                $results += @{ Method = "Email"; Success = $emailResult.Success; Details = $emailResult }
            } catch {
                $results += @{ Method = "Email"; Success = $false; Error = $_.Exception.Message }
            }
        }
        
        if ($Configuration.WebhookNotifications.Enabled) {
            try {
                $webhookResult = Send-WebhookWithRetry -Configuration $Configuration.WebhookNotifications -Content $messageContent
                $results += @{ Method = "Webhook"; Success = $webhookResult.Success; Details = $webhookResult }
            } catch {
                $results += @{ Method = "Webhook"; Success = $false; Error = $_.Exception.Message }
            }
        }
        
        return $results
        
    } catch {
        Write-SystemStatusLog "Error sending Unity warning notification: $($_.Exception.Message)" -Level 'ERROR'
        throw $_
    }
}

function Send-UnitySuccessNotification {
    <#
    .SYNOPSIS
    Sends notifications for successful Unity compilation
    #>
    [CmdletBinding()]
    param(
        [hashtable]$NotificationData,
        [hashtable]$Configuration
    )
    
    Write-SystemStatusLog "Sending Unity success notification" -Level 'DEBUG'
    
    try {
        $subject = "Unity Compilation Success"
        $severity = "Info"
        
        $messageContent = @{
            Subject = $subject
            Severity = $severity
            Source = $NotificationData.Source
            Timestamp = $NotificationData.Timestamp
            Details = @{
                LogFile = $NotificationData.LogFile
            }
            Summary = "Unity compilation completed successfully"
        }
        
        $results = @()
        
        if ($Configuration.EmailNotifications.Enabled -and $Configuration.EmailNotifications.NotificationTypes.FixApplicationSuccess) {
            try {
                $emailResult = Send-EmailWithRetry -Configuration $Configuration.EmailNotifications -Content $messageContent
                $results += @{ Method = "Email"; Success = $emailResult.Success; Details = $emailResult }
            } catch {
                $results += @{ Method = "Email"; Success = $false; Error = $_.Exception.Message }
            }
        }
        
        if ($Configuration.WebhookNotifications.Enabled -and $Configuration.WebhookNotifications.NotificationTypes.FixApplicationSuccess) {
            try {
                $webhookResult = Send-WebhookWithRetry -Configuration $Configuration.WebhookNotifications -Content $messageContent
                $results += @{ Method = "Webhook"; Success = $webhookResult.Success; Details = $webhookResult }
            } catch {
                $results += @{ Method = "Webhook"; Success = $false; Error = $_.Exception.Message }
            }
        }
        
        return $results
        
    } catch {
        Write-SystemStatusLog "Error sending Unity success notification: $($_.Exception.Message)" -Level 'ERROR'
        throw $_
    }
}

function Send-ClaudeSubmissionNotificationEvent {
    <#
    .SYNOPSIS
    Sends notifications for Claude submission status
    #>
    [CmdletBinding()]
    param(
        [hashtable]$NotificationData,
        [hashtable]$Configuration
    )
    
    Write-SystemStatusLog "Sending Claude submission notification" -Level 'DEBUG'
    
    try {
        $subject = if ($NotificationData.Success) { "Claude Submission Success" } else { "Claude Submission Failure" }
        $severity = if ($NotificationData.Success) { "Info" } else { "High" }
        
        $messageContent = @{
            Subject = $subject
            Severity = $severity
            Source = $NotificationData.Source
            Timestamp = $NotificationData.Timestamp
            Details = @{
                Success = $NotificationData.Success
                ResponseFile = $NotificationData.ResponseFile
                ResponseType = $NotificationData.ResponseType
            }
            Summary = if ($NotificationData.Success) { "Claude successfully processed the submission" } else { "Claude submission failed or encountered an error" }
        }
        
        $results = @()
        
        if ($Configuration.EmailNotifications.Enabled -and $Configuration.EmailNotifications.NotificationTypes.ClaudeSubmissionFailure) {
            try {
                $emailResult = Send-EmailWithRetry -Configuration $Configuration.EmailNotifications -Content $messageContent
                $results += @{ Method = "Email"; Success = $emailResult.Success; Details = $emailResult }
            } catch {
                $results += @{ Method = "Email"; Success = $false; Error = $_.Exception.Message }
            }
        }
        
        if ($Configuration.WebhookNotifications.Enabled -and $Configuration.WebhookNotifications.NotificationTypes.ClaudeSubmissionFailure) {
            try {
                $webhookResult = Send-WebhookWithRetry -Configuration $Configuration.WebhookNotifications -Content $messageContent
                $results += @{ Method = "Webhook"; Success = $webhookResult.Success; Details = $webhookResult }
            } catch {
                $results += @{ Method = "Webhook"; Success = $false; Error = $_.Exception.Message }
            }
        }
        
        return $results
        
    } catch {
        Write-SystemStatusLog "Error sending Claude submission notification: $($_.Exception.Message)" -Level 'ERROR'
        throw $_
    }
}

function Send-ClaudeRateLimitNotification {
    <#
    .SYNOPSIS
    Sends notifications for Claude API rate limiting
    #>
    [CmdletBinding()]
    param(
        [hashtable]$NotificationData,
        [hashtable]$Configuration
    )
    
    Write-SystemStatusLog "Sending Claude rate limit notification" -Level 'DEBUG'
    
    try {
        $subject = "Claude API Rate Limit Encountered"
        $severity = "Medium"
        
        $messageContent = @{
            Subject = $subject
            Severity = $severity
            Source = $NotificationData.Source
            Timestamp = $NotificationData.Timestamp
            Details = @{
                ResponseFile = $NotificationData.ResponseFile
            }
            Summary = "Claude API rate limiting detected - submissions may be delayed"
        }
        
        $results = @()
        
        if ($Configuration.EmailNotifications.Enabled) {
            try {
                $emailResult = Send-EmailWithRetry -Configuration $Configuration.EmailNotifications -Content $messageContent
                $results += @{ Method = "Email"; Success = $emailResult.Success; Details = $emailResult }
            } catch {
                $results += @{ Method = "Email"; Success = $false; Error = $_.Exception.Message }
            }
        }
        
        if ($Configuration.WebhookNotifications.Enabled) {
            try {
                $webhookResult = Send-WebhookWithRetry -Configuration $Configuration.WebhookNotifications -Content $messageContent
                $results += @{ Method = "Webhook"; Success = $webhookResult.Success; Details = $webhookResult }
            } catch {
                $results += @{ Method = "Webhook"; Success = $false; Error = $_.Exception.Message }
            }
        }
        
        return $results
        
    } catch {
        Write-SystemStatusLog "Error sending Claude rate limit notification: $($_.Exception.Message)" -Level 'ERROR'
        throw $_
    }
}

function Send-ErrorResolutionNotification {
    <#
    .SYNOPSIS
    Sends notifications for error resolution outcomes
    #>
    [CmdletBinding()]
    param(
        [hashtable]$NotificationData,
        [hashtable]$Configuration
    )
    
    Write-SystemStatusLog "Sending error resolution notification" -Level 'DEBUG'
    
    try {
        $subject = "Error Resolution $($NotificationData.Type)"
        $severity = switch ($NotificationData.Type) {
            "Success" { "Info" }
            "Failure" { "High" }
            "Validation" { "Low" }
            default { "Medium" }
        }
        
        $messageContent = @{
            Subject = $subject
            Severity = $severity
            Source = $NotificationData.Source
            Timestamp = $NotificationData.Timestamp
            Details = @{
                Type = $NotificationData.Type
                Message = $NotificationData.Message
                LogFile = $NotificationData.LogFile
            }
            Summary = "Error resolution process: $($NotificationData.Type.ToLower())"
        }
        
        $results = @()
        
        # Send notifications based on type and configuration
        $shouldNotify = $false
        switch ($NotificationData.Type) {
            "Success" { $shouldNotify = $Configuration.EmailNotifications.NotificationTypes.FixApplicationSuccess }
            "Failure" { $shouldNotify = $true }  # Always notify on failures
            "Validation" { $shouldNotify = $Configuration.Notifications.EnableHealthNotifications }
        }
        
        if ($shouldNotify) {
            if ($Configuration.EmailNotifications.Enabled) {
                try {
                    $emailResult = Send-EmailWithRetry -Configuration $Configuration.EmailNotifications -Content $messageContent
                    $results += @{ Method = "Email"; Success = $emailResult.Success; Details = $emailResult }
                } catch {
                    $results += @{ Method = "Email"; Success = $false; Error = $_.Exception.Message }
                }
            }
            
            if ($Configuration.WebhookNotifications.Enabled) {
                try {
                    $webhookResult = Send-WebhookWithRetry -Configuration $Configuration.WebhookNotifications -Content $messageContent
                    $results += @{ Method = "Webhook"; Success = $webhookResult.Success; Details = $webhookResult }
                } catch {
                    $results += @{ Method = "Webhook"; Success = $false; Error = $_.Exception.Message }
                }
            }
        }
        
        return $results
        
    } catch {
        Write-SystemStatusLog "Error sending error resolution notification: $($_.Exception.Message)" -Level 'ERROR'
        throw $_
    }
}

function Send-SystemHealthNotification {
    <#
    .SYNOPSIS
    Sends notifications for system health status changes
    #>
    [CmdletBinding()]
    param(
        [hashtable]$NotificationData,
        [hashtable]$Configuration
    )
    
    Write-SystemStatusLog "Sending system health notification" -Level 'DEBUG'
    
    try {
        $subject = "System Health Alert - $($NotificationData.Type) ($($NotificationData.Count) Issue(s))"
        $severity = switch ($NotificationData.Type) {
            "Critical" { "Critical" }
            "Warning" { "Medium" }
            "Recovery" { "Info" }
            default { "Medium" }
        }
        
        $messageContent = @{
            Subject = $subject
            Severity = $severity
            Source = $NotificationData.Source
            Timestamp = $NotificationData.Timestamp
            Details = @{
                Type = $NotificationData.Type
                Count = $NotificationData.Count
                Issues = $NotificationData.Issues
            }
            Summary = "System health monitoring detected $($NotificationData.Count) $($NotificationData.Type.ToLower()) issue(s)"
        }
        
        $results = @()
        
        if ($Configuration.EmailNotifications.Enabled -and $Configuration.EmailNotifications.NotificationTypes.SystemHealthWarning) {
            try {
                $emailResult = Send-EmailWithRetry -Configuration $Configuration.EmailNotifications -Content $messageContent
                $results += @{ Method = "Email"; Success = $emailResult.Success; Details = $emailResult }
            } catch {
                $results += @{ Method = "Email"; Success = $false; Error = $_.Exception.Message }
            }
        }
        
        if ($Configuration.WebhookNotifications.Enabled -and $Configuration.WebhookNotifications.NotificationTypes.SystemHealthWarning) {
            try {
                $webhookResult = Send-WebhookWithRetry -Configuration $Configuration.WebhookNotifications -Content $messageContent
                $results += @{ Method = "Webhook"; Success = $webhookResult.Success; Details = $webhookResult }
            } catch {
                $results += @{ Method = "Webhook"; Success = $false; Error = $_.Exception.Message }
            }
        }
        
        return $results
        
    } catch {
        Write-SystemStatusLog "Error sending system health notification: $($_.Exception.Message)" -Level 'ERROR'
        throw $_
    }
}

function Send-AutonomousAgentNotification {
    <#
    .SYNOPSIS
    Sends notifications for autonomous agent status changes
    #>
    [CmdletBinding()]
    param(
        [hashtable]$NotificationData,
        [hashtable]$Configuration
    )
    
    Write-SystemStatusLog "Sending autonomous agent notification" -Level 'DEBUG'
    
    try {
        $subject = "Autonomous Agent Status Change - $($NotificationData.CurrentStatus)"
        $severity = switch ($NotificationData.CurrentStatus) {
            "Failed" { "Critical" }
            "InterventionRequired" { "High" }
            "Restarting" { "Medium" }
            default { "Info" }
        }
        
        $messageContent = @{
            Subject = $subject
            Severity = $severity
            Source = $NotificationData.Source
            Timestamp = $NotificationData.Timestamp
            Details = @{
                CurrentStatus = $NotificationData.CurrentStatus
                PreviousStatus = $NotificationData.PreviousStatus
                StatusData = $NotificationData.StatusData
            }
            Summary = "Autonomous agent status changed from $($NotificationData.PreviousStatus) to $($NotificationData.CurrentStatus)"
        }
        
        $results = @()
        
        if ($Configuration.EmailNotifications.Enabled -and $Configuration.EmailNotifications.NotificationTypes.AutonomousAgentFailure) {
            try {
                $emailResult = Send-EmailWithRetry -Configuration $Configuration.EmailNotifications -Content $messageContent
                $results += @{ Method = "Email"; Success = $emailResult.Success; Details = $emailResult }
            } catch {
                $results += @{ Method = "Email"; Success = $false; Error = $_.Exception.Message }
            }
        }
        
        if ($Configuration.WebhookNotifications.Enabled -and $Configuration.WebhookNotifications.NotificationTypes.AutonomousAgentFailure) {
            try {
                $webhookResult = Send-WebhookWithRetry -Configuration $Configuration.WebhookNotifications -Content $messageContent
                $results += @{ Method = "Webhook"; Success = $webhookResult.Success; Details = $webhookResult }
            } catch {
                $results += @{ Method = "Webhook"; Success = $false; Error = $_.Exception.Message }
            }
        }
        
        return $results
        
    } catch {
        Write-SystemStatusLog "Error sending autonomous agent notification: $($_.Exception.Message)" -Level 'ERROR'
        throw $_
    }
}

# Functions available for dot-sourcing in main module
# Send-UnityErrorNotificationEvent, Send-UnityWarningNotification, Send-UnitySuccessNotification, Send-ClaudeSubmissionNotificationEvent, Send-ClaudeRateLimitNotification, Send-ErrorResolutionNotification, Send-SystemHealthNotification, Send-AutonomousAgentNotification
# SIG # Begin signature block
# MIIFzgYJKoZIhvcNAQcCoIIFvzCCBbsCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCCKgaqNI+KAi9xf
# CavN3rgTYmkRDInmXX19MS4lNrKhl6CCAzAwggMsMIICFKADAgECAhB1HRbZIqgr
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
# MAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEICFqtrDwo7GC1DUwrSmXg59Y
# J02SeqO390MvBUrJ3g4+MA0GCSqGSIb3DQEBAQUABIIBAHVZ8ywAJAmEOjLvXD8D
# ZGWFhn7Bxbl8vga9Hf39QrUNyobrHEQ1n79YTf0/aPXk3mSTiOnWC0rmq4HzwZ8O
# Mb6pBvXeJhgAFaO5Cxaa8uCVcil996HNWHt6FB7j1aw+HZH2Shaqv/z9oCUnD2eZ
# PFVj197KxsxYYTPMq6vQjc+DGeDlhuhbBgk8x+hkOibYgHsszjnermtIc3SYKw/r
# AaxPEytPGudJW0WV3Dzk+iVQQPD4RIV+x4Z/8B2oFdjTHj6AJ+eAoHDv5wq776tK
# YUIiBz/mJpqprn5Kb3Sc55oq3vaZN5XQgTpZc4ralBspug2HXQa5nYc5WL6Spkk4
# JeE=
# SIG # End signature block
