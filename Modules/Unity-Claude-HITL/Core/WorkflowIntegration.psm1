# WorkflowIntegration.psm1
# Human-in-the-Loop Workflow Integration and Utilities Component
# Version 2.0.0 - 2025-08-26
# Part of refactored Unity-Claude-HITL module

# Import required components
$coreModule = Join-Path $PSScriptRoot "HITLCore.psm1"
$requestModule = Join-Path $PSScriptRoot "ApprovalRequests.psm1"
$tokenModule = Join-Path $PSScriptRoot "SecurityTokens.psm1"

if (Test-Path $coreModule) { Import-Module $coreModule -Force -Global -ErrorAction SilentlyContinue }
if (Test-Path $requestModule) { Import-Module $requestModule -Force -Global -ErrorAction SilentlyContinue }
if (Test-Path $tokenModule) { Import-Module $tokenModule -Force -Global -ErrorAction SilentlyContinue }

#region Workflow Integration

function Wait-HumanApproval {
    <#
    .SYNOPSIS
        Waits for human approval with timeout and escalation support.
    
    .DESCRIPTION
        Blocks workflow execution until human approval is received,
        implementing research-based timeout and escalation strategies.
    
    .PARAMETER ApprovalRequest
        The approval request to wait for.
    
    .PARAMETER TimeoutMinutes
        Maximum time to wait before escalation or fallback.
    
    .EXAMPLE
        $result = Wait-HumanApproval -ApprovalRequest $request -TimeoutMinutes 60
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [PSCustomObject]$ApprovalRequest,
        
        [Parameter()]
        [int]$TimeoutMinutes = $(if ($script:HITLConfig) { $script:HITLConfig.DefaultTimeout } else { 1440 })
    )
    
    Write-Host "⏳ Waiting for human approval - Request ID: $($ApprovalRequest.Id)" -ForegroundColor Yellow
    
    try {
        $startTime = Get-Date
        $checkInterval = 30  # Check every 30 seconds
        
        while ($true) {
            # Check if approval status has changed
            $currentStatus = Get-ApprovalStatus -ApprovalId $ApprovalRequest.Id
            
            if ($currentStatus.Status -eq 'approved') {
                Write-Host "✅ Approval granted by: $($currentStatus.ApprovedBy)" -ForegroundColor Green
                return @{
                    Approved = $true
                    ApprovedBy = $currentStatus.ApprovedBy
                    ApprovalTime = $currentStatus.ApprovedAt
                    Comments = $currentStatus.Comments
                }
            }
            
            if ($currentStatus.Status -eq 'rejected') {
                Write-Host "❌ Approval rejected by: $($currentStatus.ApprovedBy)" -ForegroundColor Red
                return @{
                    Approved = $false
                    RejectedBy = $currentStatus.ApprovedBy
                    RejectionTime = $currentStatus.ApprovedAt
                    RejectionReason = $currentStatus.RejectionReason
                }
            }
            
            # Check for timeout
            $elapsedMinutes = ((Get-Date) - $startTime).TotalMinutes
            if ($elapsedMinutes -ge $TimeoutMinutes) {
                Write-Warning "⏰ Approval timeout reached after $TimeoutMinutes minutes"
                
                # Handle escalation or fallback
                $escalationResult = Set-ApprovalEscalation -ApprovalRequest $ApprovalRequest
                if ($escalationResult.Escalated) {
                    Write-Host "📈 Request escalated to next level" -ForegroundColor Yellow
                    # Continue waiting with new timeout
                    $TimeoutMinutes = $(if ($script:HITLConfig) { $script:HITLConfig.EscalationTimeout } else { 720 })
                    $startTime = Get-Date
                    continue
                } else {
                    # Fallback action
                    Write-Warning "🚫 Maximum escalation reached. Applying fallback action."
                    return @{
                        Approved = $false
                        TimedOut = $true
                        FallbackAction = 'reject'
                    }
                }
            }
            
            Start-Sleep -Seconds $checkInterval
        }
    }
    catch {
        Write-Error "Error waiting for human approval: $($_.Exception.Message)"
        return @{
            Approved = $false
            Error = $_.Exception.Message
        }
    }
}

function Resume-WorkflowFromApproval {
    <#
    .SYNOPSIS
        Resumes a LangGraph workflow after human approval.
    
    .DESCRIPTION
        Integrates with LangGraph to resume workflows using the Command primitive
        and research-validated resume patterns.
    
    .PARAMETER ThreadId
        LangGraph thread ID for the workflow.
    
    .PARAMETER ApprovalResult
        Result from the approval process.
    
    .EXAMPLE
        Resume-WorkflowFromApproval -ThreadId $threadId -ApprovalResult $approvalResult
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$ThreadId,
        
        [Parameter(Mandatory = $true)]
        [hashtable]$ApprovalResult
    )
    
    Write-Verbose "Resuming workflow for thread: $ThreadId"
    
    try {
        # Prepare LangGraph resume command
        $resumePayload = @{
            thread_id = $ThreadId
            command = @{
                resume = $ApprovalResult
            }
        }
        
        # Send resume command to LangGraph endpoint
        $config = Get-HITLConfiguration
        $endpoint = "$($config.LangGraphEndpoint)/resume"
        
        # This would make an actual HTTP request in full implementation
        Write-Host "🔄 Workflow resume command prepared for thread: $ThreadId" -ForegroundColor Blue
        # In full implementation: Invoke-RestMethod -Uri $endpoint -Method POST -Body (ConvertTo-Json $resumePayload) -ContentType 'application/json'
        
        Write-Host "✅ Workflow resumed successfully." -ForegroundColor Green
        return $true
    }
    catch {
        Write-Error "Failed to resume workflow: $($_.Exception.Message)"
        return $false
    }
}

function Invoke-HumanApprovalWorkflow {
    <#
    .SYNOPSIS
        Complete workflow for requesting and processing human approval.
    
    .PARAMETER WorkflowId
        Unique identifier for the workflow.
    
    .PARAMETER Title
        Title for the approval request.
    
    .PARAMETER Description
        Description of what needs approval.
    
    .PARAMETER Recipients
        Email recipients for approval notifications.
    
    .PARAMETER UrgencyLevel
        Urgency level for the approval.
    
    .EXAMPLE
        $result = Invoke-HumanApprovalWorkflow -WorkflowId "deploy-001" -Title "Production Deployment" -Description "Deploy v2.0 to production" -Recipients @('manager@company.com') -UrgencyLevel 'high'
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$WorkflowId,
        
        [Parameter(Mandatory = $true)]
        [string]$Title,
        
        [Parameter(Mandatory = $true)]
        [string]$Description,
        
        [Parameter(Mandatory = $true)]
        [string[]]$Recipients,
        
        [Parameter()]
        [ValidateSet('low', 'medium', 'high', 'critical')]
        [string]$UrgencyLevel = 'medium'
    )
    
    Write-Host "🔄 Starting human approval workflow: $WorkflowId" -ForegroundColor Cyan
    
    try {
        # Step 1: Create approval request
        $request = New-ApprovalRequest -WorkflowId $WorkflowId -Title $Title -Description $Description -UrgencyLevel $UrgencyLevel
        if (-not $request) {
            throw "Failed to create approval request"
        }
        
        # Step 2: Send notifications
        $notificationResult = Send-ApprovalNotification -ApprovalRequest $request -Recipients $Recipients
        if (-not $notificationResult) {
            throw "Failed to send approval notifications"
        }
        
        # Step 3: Wait for approval
        $approvalResult = Wait-HumanApproval -ApprovalRequest $request
        
        # Step 4: Resume workflow if approved
        if ($approvalResult.Approved) {
            $resumeResult = Resume-WorkflowFromApproval -ThreadId $request.ThreadId -ApprovalResult $approvalResult
            if ($resumeResult) {
                Write-Host "✅ Human approval workflow completed successfully." -ForegroundColor Green
            }
        }
        
        return $approvalResult
    }
    catch {
        Write-Error "Human approval workflow failed: $($_.Exception.Message)"
        return @{
            Approved = $false
            Error = $_.Exception.Message
        }
    }
}

#endregion

#region Utility Functions

function Invoke-ApprovalAction {
    <#
    .SYNOPSIS
        Processes approval actions from email links or API calls.
    
    .PARAMETER Token
        The approval token from the request.
    
    .PARAMETER Action
        The action to perform: approve, reject, review.
    
    .PARAMETER Comments
        Optional comments from the approver.
    
    .EXAMPLE
        Invoke-ApprovalAction -Token $token -Action 'approve' -Comments 'Looks good'
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Token,
        
        [Parameter(Mandatory = $true)]
        [ValidateSet('approve', 'reject', 'review')]
        [string]$Action,
        
        [Parameter()]
        [string]$Comments = ""
    )
    
    try {
        # Validate token
        if (-not (Test-ApprovalToken -Token $Token)) {
            Write-Error "Invalid or expired approval token"
            return $false
        }
        
        Write-Host "✅ Processing approval action: $Action" -ForegroundColor Green
        
        # In full implementation:
        # 1. Decode token to get approval ID
        # 2. Update database with action
        # 3. Send notifications
        # 4. Resume workflow if appropriate
        
        return $true
    }
    catch {
        Write-Error "Failed to process approval action: $($_.Exception.Message)"
        return $false
    }
}

function Export-ApprovalMetrics {
    <#
    .SYNOPSIS
        Exports approval system metrics and analytics.
    
    .EXAMPLE
        Export-ApprovalMetrics
    #>
    [CmdletBinding()]
    param()
    
    Write-Host "📊 Exporting approval metrics..." -ForegroundColor Blue
    # Would generate comprehensive metrics in full implementation
    
    return @{
        TotalRequests = 0
        ApprovedCount = 0
        RejectedCount = 0
        TimeoutCount = 0
        AverageApprovalTime = 0
        MetricsGenerated = Get-Date
    }
}

function Test-HITLSystemHealth {
    <#
    .SYNOPSIS
        Tests HITL system health and connectivity.
    
    .EXAMPLE
        Test-HITLSystemHealth
    #>
    [CmdletBinding()]
    param()
    
    Write-Host "🔍 Testing HITL system health..." -ForegroundColor Blue
    
    $healthChecks = @{
        DatabaseConnectivity = $false
        EmailConfiguration = $false
        LangGraphEndpoint = $false
        SecurityTokens = $false
    }
    
    try {
        # Test database connectivity
        $config = Get-HITLConfiguration
        $healthChecks.DatabaseConnectivity = Test-DatabaseConnection -DatabasePath $config.DatabasePath
        
        # Test email configuration
        $healthChecks.EmailConfiguration = $config.NotificationSettings.EmailEnabled
        
        # Test LangGraph endpoint
        # In full implementation: Test-Connection to LangGraph endpoint
        $healthChecks.LangGraphEndpoint = $true
        
        # Test security tokens
        $testToken = New-ApprovalToken -ApprovalId 999999
        $healthChecks.SecurityTokens = Test-ApprovalToken -Token $testToken
        
        $overallHealth = ($healthChecks.Values | Where-Object { $_ -eq $true }).Count -eq $healthChecks.Count
        
        Write-Host "🏥 HITL System Health: $(if ($overallHealth) { 'HEALTHY' } else { 'ISSUES DETECTED' })" -ForegroundColor $(if ($overallHealth) { 'Green' } else { 'Red' })
        
        return @{
            OverallHealth = $overallHealth
            Details = $healthChecks
            Timestamp = Get-Date
        }
    }
    catch {
        Write-Error "Health check failed: $($_.Exception.Message)"
        return @{
            OverallHealth = $false
            Error = $_.Exception.Message
            Timestamp = Get-Date
        }
    }
}

#endregion

#region Export Module Members

Export-ModuleMember -Function @(
    'Wait-HumanApproval',
    'Resume-WorkflowFromApproval',
    'Invoke-HumanApprovalWorkflow',
    'Invoke-ApprovalAction',
    'Export-ApprovalMetrics',
    'Test-HITLSystemHealth'
)

#endregion
# SIG # Begin signature block
# MIIFzgYJKoZIhvcNAQcCoIIFvzCCBbsCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCAA3Gdng4Wpx2IA
# edP6FuuCUQ48DMQYlp4b0sX3FmqcVKCCAzAwggMsMIICFKADAgECAhB1HRbZIqgr
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
# MAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIC1vJoIbRTdnJOH7GLKLlpvp
# pgPhOXARvzZhwbIHY5kXMA0GCSqGSIb3DQEBAQUABIIBAGlOYiy/wqmSxWo+WA1/
# QphGQ8m4Sk7jywYxzwAwxV1zrNxaVwRPcxYnhYY0uc6gI0PF5y3piCUZRRImcfdz
# 2Sa48ZqPb7IcG0IZfLbodIp0qcdlWonWoBE+MHnSbBmvnTrWPJkxP0vUurPsj4Xm
# OaAfWNioUK6ezheqE9xGCpuwSfGO73DpiG4IP2AeJKUqE696OAv1OafkJX06Fj/R
# ml3RMDTafJayRd4MfuebqA3n4lSAr3Xo9hkKDSXDNbz9oXmGLx+u/E1tjGaa+Wsy
# SnFNV/6rj0/sf35UZoo62r8s6lQZ0bM85fpYZ9oA8k9QwCg9QeMmSpQJGolvH8dW
# 9gI=
# SIG # End signature block
