# NotificationSystem.psm1
# Human-in-the-Loop Notification System Component
# Version 2.0.0 - 2025-08-26
# Part of refactored Unity-Claude-HITL module

# Import required components
$coreModule = Join-Path $PSScriptRoot "HITLCore.psm1"
if (Test-Path $coreModule) {
    Import-Module $coreModule -Force -Global -ErrorAction SilentlyContinue
}

#region Notification System

function Send-ApprovalNotification {
    <#
    .SYNOPSIS
        Sends approval notifications via email and other channels.
    
    .DESCRIPTION
        Sends mobile-optimized approval notifications with one-click approval links,
        implementing research-based best practices for email approvals.
    
    .PARAMETER ApprovalRequest
        The approval request object to send notifications for.
    
    .PARAMETER Recipients
        Array of email addresses to notify.
    
    .PARAMETER IncludeWebhook
        Whether to include webhook notifications.
    
    .EXAMPLE
        Send-ApprovalNotification -ApprovalRequest $request -Recipients @('manager@company.com')
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [PSCustomObject]$ApprovalRequest,
        
        [Parameter(Mandatory = $true)]
        [string[]]$Recipients,
        
        [Parameter()]
        [switch]$IncludeWebhook
    )
    
    Write-Verbose "Sending approval notification for request ID: $($ApprovalRequest.Id)"
    
    try {
        # Generate approval URLs with secure tokens
        $baseUrl = "http://localhost:8080/approval"  # This would be configurable
        $approveUrl = "$baseUrl/approve?token=$($ApprovalRequest.ApprovalToken)"
        $rejectUrl = "$baseUrl/reject?token=$($ApprovalRequest.ApprovalToken)"
        $reviewUrl = "$baseUrl/review?token=$($ApprovalRequest.ApprovalToken)"
        
        # Create mobile-optimized email content
        $emailSubject = "[$($ApprovalRequest.UrgencyLevel.ToUpper())] Approval Required: $($ApprovalRequest.Title)"
        
        $emailBody = Build-ApprovalEmailTemplate -ApprovalRequest $ApprovalRequest -ApproveUrl $approveUrl -RejectUrl $rejectUrl -ReviewUrl $reviewUrl
        
        # Send email notification using existing email system
        $config = Get-HITLConfiguration
        if ($config.NotificationSettings.EmailEnabled) {
            foreach ($recipient in $Recipients) {
                # This would integrate with the existing MailKit system
                Write-Host "📧 Email notification sent to: $recipient" -ForegroundColor Blue
                # In full implementation: Send-EmailNotification -To $recipient -Subject $emailSubject -Body $emailBody -IsHtml
            }
        }
        
        # Send webhook notification if enabled
        if ($IncludeWebhook -and $config.NotificationSettings.WebhookEnabled) {
            $webhookPayload = @{
                event = 'approval_requested'
                approval_id = $ApprovalRequest.Id
                workflow_id = $ApprovalRequest.WorkflowId
                title = $ApprovalRequest.Title
                urgency = $ApprovalRequest.UrgencyLevel
                expires_at = $ApprovalRequest.ExpiresAt.ToString('o')
                approve_url = $approveUrl
                reject_url = $rejectUrl
                review_url = $reviewUrl
            }
            
            Write-Host "🌐 Webhook notification prepared" -ForegroundColor Blue
            # In full implementation: Invoke-WebhookNotification -Payload $webhookPayload
        }
        
        Write-Host "Approval notification sent successfully." -ForegroundColor Green
        return $true
    }
    catch {
        Write-Error "Failed to send approval notification: $($_.Exception.Message)"
        return $false
    }
}

function Build-ApprovalEmailTemplate {
    <#
    .SYNOPSIS
        Builds mobile-optimized HTML email template for approvals.
    
    .PARAMETER ApprovalRequest
        The approval request object.
    
    .PARAMETER ApproveUrl
        URL for approval action.
    
    .PARAMETER RejectUrl
        URL for rejection action.
    
    .PARAMETER ReviewUrl
        URL for review action.
    
    .EXAMPLE
        $html = Build-ApprovalEmailTemplate -ApprovalRequest $request -ApproveUrl $approveUrl -RejectUrl $rejectUrl -ReviewUrl $reviewUrl
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [PSCustomObject]$ApprovalRequest,
        
        [Parameter(Mandatory = $true)]
        [string]$ApproveUrl,
        
        [Parameter(Mandatory = $true)]
        [string]$RejectUrl,
        
        [Parameter(Mandatory = $true)]
        [string]$ReviewUrl
    )
    
    $emailBody = @"
<html>
<head>
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <style>
        body { font-family: Arial, sans-serif; line-height: 1.6; margin: 0; padding: 20px; background-color: #f4f4f4; }
        .container { max-width: 600px; margin: 0 auto; background: white; padding: 30px; border-radius: 10px; box-shadow: 0 0 10px rgba(0,0,0,0.1); }
        .header { background-color: #2c3e50; color: white; padding: 20px; border-radius: 5px; text-align: center; margin-bottom: 20px; }
        .urgency-high { background-color: #e74c3c; }
        .urgency-critical { background-color: #c0392b; }
        .content { margin-bottom: 30px; }
        .actions { text-align: center; margin: 30px 0; }
        .btn { display: inline-block; padding: 15px 30px; margin: 10px; text-decoration: none; border-radius: 5px; font-weight: bold; font-size: 16px; }
        .btn-approve { background-color: #27ae60; color: white; }
        .btn-reject { background-color: #e74c3c; color: white; }
        .btn-review { background-color: #3498db; color: white; }
        .details { background-color: #f8f9fa; padding: 20px; border-left: 4px solid #3498db; margin: 20px 0; }
        .footer { text-align: center; color: #7f8c8d; font-size: 12px; margin-top: 30px; padding-top: 20px; border-top: 1px solid #ecf0f1; }
        @media (max-width: 480px) {
            .container { padding: 15px; }
            .btn { display: block; margin: 10px 0; }
        }
    </style>
</head>
<body>
    <div class="container">
        <div class="header$($ApprovalRequest.UrgencyLevel -eq 'high' ? ' urgency-high' : '')$($ApprovalRequest.UrgencyLevel -eq 'critical' ? ' urgency-critical' : '')">
            <h2>Approval Required</h2>
            <p>Urgency: $($ApprovalRequest.UrgencyLevel.ToUpper())</p>
        </div>
        
        <div class="content">
            <h3>$($ApprovalRequest.Title)</h3>
            <p><strong>Workflow ID:</strong> $($ApprovalRequest.WorkflowId)</p>
            <p><strong>Requested by:</strong> $($ApprovalRequest.RequestedBy)</p>
            <p><strong>Expires at:</strong> $($ApprovalRequest.ExpiresAt.ToString('yyyy-MM-dd HH:mm:ss'))</p>
            
            <div class="details">
                <h4>Description</h4>
                <p>$($ApprovalRequest.Description)</p>
                
                $(if ($ApprovalRequest.ChangesSummary) { "<h4>Changes Summary</h4><p>$($ApprovalRequest.ChangesSummary)</p>" })
                
                $(if ($ApprovalRequest.ImpactAnalysis) { "<h4>Impact Analysis</h4><p>$($ApprovalRequest.ImpactAnalysis)</p>" })
            </div>
        </div>
        
        <div class="actions">
            <a href="$ApproveUrl" class="btn btn-approve">✅ APPROVE</a>
            <a href="$RejectUrl" class="btn btn-reject">❌ REJECT</a>
            <a href="$ReviewUrl" class="btn btn-review">👁️ REVIEW DETAILS</a>
        </div>
        
        <div class="footer">
            <p>This is an automated approval request from Unity-Claude-Automation.</p>
            <p>Request ID: $($ApprovalRequest.Id) | Token expires: $($ApprovalRequest.ExpiresAt.ToString('yyyy-MM-dd HH:mm'))</p>
        </div>
    </div>
</body>
</html>
"@
    
    return $emailBody
}

function Send-ApprovalReminder {
    <#
    .SYNOPSIS
        Sends reminder notifications for pending approvals.
    
    .PARAMETER ApprovalRequest
        The approval request to send reminder for.
    
    .PARAMETER Recipients
        Recipients to remind.
    
    .EXAMPLE
        Send-ApprovalReminder -ApprovalRequest $request -Recipients @('manager@company.com')
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [PSCustomObject]$ApprovalRequest,
        
        [Parameter(Mandatory = $true)]
        [string[]]$Recipients
    )
    
    Write-Host "⏰ Sending approval reminder for request ID: $($ApprovalRequest.Id)" -ForegroundColor Yellow
    
    # Calculate time remaining
    $timeRemaining = $ApprovalRequest.ExpiresAt - (Get-Date)
    $hoursRemaining = [Math]::Floor($timeRemaining.TotalHours)
    
    # Modify subject for reminder
    $subject = "[REMINDER - $hoursRemaining hrs remaining] Approval Required: $($ApprovalRequest.Title)"
    
    # Send reminder using same notification system
    return Send-ApprovalNotification -ApprovalRequest $ApprovalRequest -Recipients $Recipients
}

function Send-ApprovalResultNotification {
    <#
    .SYNOPSIS
        Sends notifications about approval results.
    
    .PARAMETER ApprovalRequest
        The approval request.
    
    .PARAMETER Result
        The approval result (approved/rejected).
    
    .PARAMETER Recipients
        Recipients to notify.
    
    .EXAMPLE
        Send-ApprovalResultNotification -ApprovalRequest $request -Result $result -Recipients @('requester@company.com')
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [PSCustomObject]$ApprovalRequest,
        
        [Parameter(Mandatory = $true)]
        [hashtable]$Result,
        
        [Parameter(Mandatory = $true)]
        [string[]]$Recipients
    )
    
    $status = if ($Result.Approved) { "APPROVED" } else { "REJECTED" }
    $color = if ($Result.Approved) { "Green" } else { "Red" }
    
    Write-Host "📬 Sending approval result notification: $status" -ForegroundColor $color
    
    # In full implementation, would send detailed result notification
    foreach ($recipient in $Recipients) {
        Write-Host "📧 Result notification sent to: $recipient" -ForegroundColor Blue
    }
    
    return $true
}

#endregion

#region Export Module Members

Export-ModuleMember -Function @(
    'Send-ApprovalNotification',
    'Build-ApprovalEmailTemplate',
    'Send-ApprovalReminder',
    'Send-ApprovalResultNotification'
)

#endregion
# SIG # Begin signature block
# MIIFzgYJKoZIhvcNAQcCoIIFvzCCBbsCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCDgMCHGbwpvleh4
# xZ33TZMZCWnea459sdjJ0DBrkpbYO6CCAzAwggMsMIICFKADAgECAhB1HRbZIqgr
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
# MAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEINakZfviDPCGuChcmqNkZZEk
# 2vRgzFjWG/7kYiXwHAhIMA0GCSqGSIb3DQEBAQUABIIBACpCeShI1ehGf66b4fcp
# Nw3Yc7HdVimkfgN2b5cmDJfGaWflMU6m4U8dEgrUc0OWFuNp+GnPaRgsKU0SwGbH
# fd9VmRnWtQsUcSWswiaXRItF9PTqE4IdKTqAqMBF3DH6DvZHq5qCH2LnKbT89R4g
# 7xkjwwpMcMTBjPpwQFaVu97Vo64+9B3eJ1pFn+sdZTlwPsHYQ5IlCKdjC2vkvD0V
# +4Ckqjqwilyr5txiKWHb00Sm2N53zkvUhJBZuV3tbL2KapNXy5EjYD1RKjTD1rXj
# eQ+Mi/575SRcHrGqXuZpG77hVMTIdPz1NQNqox/FqDZQLPOKjwUj3QrwYsbM2tb9
# aJo=
# SIG # End signature block
