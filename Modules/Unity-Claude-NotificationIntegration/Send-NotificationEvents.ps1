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