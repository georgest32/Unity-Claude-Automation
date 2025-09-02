# ApprovalRequests.psm1
# Human-in-the-Loop Approval Request Management Component
# Version 2.0.0 - 2025-08-26
# Part of refactored Unity-Claude-HITL module

# Import required components
$coreModule = Join-Path $PSScriptRoot "HITLCore.psm1"
$tokenModule = Join-Path $PSScriptRoot "SecurityTokens.psm1"
if (Test-Path $coreModule) { Import-Module $coreModule -Force -Global -ErrorAction SilentlyContinue }
if (Test-Path $tokenModule) { Import-Module $tokenModule -Force -Global -ErrorAction SilentlyContinue }

#region Approval Request Management

function New-ApprovalRequest {
    <#
    .SYNOPSIS
        Creates a new approval request.
    
    .DESCRIPTION
        Creates a comprehensive approval request with context, impact analysis,
        and metadata based on research findings for effective HITL workflows.
    
    .PARAMETER WorkflowId
        Unique identifier for the workflow requiring approval.
    
    .PARAMETER Title
        Short, descriptive title for the approval request.
    
    .PARAMETER Description
        Detailed description of what requires approval.
    
    .PARAMETER ChangesSummary
        Summary of changes being made.
    
    .PARAMETER ImpactAnalysis
        Analysis of the impact of the proposed changes.
    
    .PARAMETER UrgencyLevel
        Urgency level: low, medium, high, critical.
    
    .PARAMETER RequestType
        Type of approval: documentation, config, critical, etc.
    
    .PARAMETER Metadata
        Additional metadata as hashtable.
    
    .EXAMPLE
        $request = New-ApprovalRequest -WorkflowId "doc-update-001" -Title "Update API Documentation" -Description "Update REST API docs for v2.0" -UrgencyLevel "medium"
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$WorkflowId,
        
        [Parameter(Mandatory = $true)]
        [string]$Title,
        
        [Parameter(Mandatory = $true)]
        [string]$Description,
        
        [Parameter()]
        [string]$ChangesSummary = "",
        
        [Parameter()]
        [string]$ImpactAnalysis = "",
        
        [Parameter()]
        [ValidateSet('low', 'medium', 'high', 'critical')]
        [string]$UrgencyLevel = 'medium',
        
        [Parameter()]
        [string]$RequestType = 'documentation',
        
        [Parameter()]
        [hashtable]$Metadata = @{}
    )
    
    Write-Verbose "Creating approval request for workflow: $WorkflowId"
    
    try {
        # Generate unique thread ID (LangGraph integration)
        $threadId = [System.Guid]::NewGuid().ToString()
        
        # Calculate expiration based on urgency and configuration
        $timeoutMinutes = switch ($UrgencyLevel) {
            'critical' { 480 }    # 8 hours
            'high' { 720 }        # 12 hours
            'medium' { $(if ($script:HITLConfig) { $script:HITLConfig.DefaultTimeout } else { 1440 }) }  # 24 hours
            'low' { 2880 }        # 48 hours
        }
        
        $expiresAt = (Get-Date).AddMinutes($timeoutMinutes)
        
        # Create approval request object
        $approvalRequest = [PSCustomObject]@{
            Id = 0  # Will be set by database
            WorkflowId = $WorkflowId
            ThreadId = $threadId
            RequestType = $RequestType
            Title = $Title
            Description = $Description
            ChangesSummary = $ChangesSummary
            ImpactAnalysis = $ImpactAnalysis
            UrgencyLevel = $UrgencyLevel
            RequestedBy = $env:USERNAME
            CreatedAt = (Get-Date)
            ExpiresAt = $expiresAt
            EscalationLevel = 0
            Status = 'pending'
            ApprovedBy = $null
            ApprovedAt = $null
            RejectionReason = $null
            ApprovalToken = $null
            MobileFriendly = $true
            Metadata = (ConvertTo-Json $Metadata -Compress)
        }
        
        # In a full implementation, this would insert into the database
        # For now, we'll simulate by generating an ID and token
        $approvalRequest.Id = Get-Random -Minimum 1000 -Maximum 9999
        $approvalRequest.ApprovalToken = New-ApprovalToken -ApprovalId $approvalRequest.Id
        
        Write-Host "Approval request created successfully. ID: $($approvalRequest.Id)" -ForegroundColor Green
        return $approvalRequest
    }
    catch {
        Write-Error "Failed to create approval request: $($_.Exception.Message)"
        return $null
    }
}

function Get-ApprovalStatus {
    <#
    .SYNOPSIS
        Gets the current status of an approval request.
    
    .PARAMETER ApprovalId
        The ID of the approval request.
    
    .EXAMPLE
        $status = Get-ApprovalStatus -ApprovalId 123
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [int]$ApprovalId
    )
    
    # Simulate database query for demo
    # In full implementation, this would query the SQLite database
    return [PSCustomObject]@{
        Id = $ApprovalId
        Status = 'pending'  # pending, approved, rejected, expired
        ApprovedBy = $null
        ApprovedAt = $null
        RejectionReason = $null
        Comments = $null
        EscalationLevel = 0
    }
}

function Set-ApprovalEscalation {
    <#
    .SYNOPSIS
        Handles approval escalation based on timeout and rules.
    
    .PARAMETER ApprovalRequest
        The approval request to escalate.
    
    .EXAMPLE
        $result = Set-ApprovalEscalation -ApprovalRequest $request
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [PSCustomObject]$ApprovalRequest
    )
    
    try {
        $maxLevels = if ($script:HITLConfig) { $script:HITLConfig.MaxEscalationLevels } else { 3 }
        if ($ApprovalRequest.EscalationLevel -ge $maxLevels) {
            return @{ Escalated = $false; MaxReached = $true }
        }
        
        # Increment escalation level
        $ApprovalRequest.EscalationLevel++
        
        Write-Host "📈 Escalating approval request to level: $($ApprovalRequest.EscalationLevel)" -ForegroundColor Yellow
        
        # In full implementation, this would:
        # 1. Update database
        # 2. Notify next escalation level
        # 3. Reset timeout
        
        return @{ Escalated = $true; NewLevel = $ApprovalRequest.EscalationLevel }
    }
    catch {
        Write-Error "Failed to escalate approval: $($_.Exception.Message)"
        return @{ Escalated = $false; Error = $_.Exception.Message }
    }
}

function Get-PendingApprovals {
    <#
    .SYNOPSIS
        Gets all pending approval requests.
    
    .EXAMPLE
        $pending = Get-PendingApprovals
    #>
    [CmdletBinding()]
    param()
    
    # Simulate database query
    Write-Host "📋 Retrieving pending approvals..." -ForegroundColor Blue
    return @()  # Would return actual pending approvals from database
}

function Update-ApprovalStatus {
    <#
    .SYNOPSIS
        Updates the status of an approval request.
    
    .PARAMETER ApprovalId
        ID of the approval request.
    
    .PARAMETER Status
        New status for the request.
    
    .PARAMETER ApprovedBy
        Who approved/rejected the request.
    
    .PARAMETER Comments
        Optional comments.
    
    .EXAMPLE
        Update-ApprovalStatus -ApprovalId 123 -Status 'approved' -ApprovedBy 'john.doe'
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [int]$ApprovalId,
        
        [Parameter(Mandatory = $true)]
        [ValidateSet('pending', 'approved', 'rejected', 'expired')]
        [string]$Status,
        
        [Parameter()]
        [string]$ApprovedBy,
        
        [Parameter()]
        [string]$Comments
    )
    
    try {
        # In full implementation, would update database
        Write-Verbose "Updated approval $ApprovalId status to: $Status"
        return $true
    }
    catch {
        Write-Error "Failed to update approval status: $($_.Exception.Message)"
        return $false
    }
}

#endregion

#region Export Module Members

Export-ModuleMember -Function @(
    'New-ApprovalRequest',
    'Get-ApprovalStatus',
    'Set-ApprovalEscalation', 
    'Get-PendingApprovals',
    'Update-ApprovalStatus'
)

#endregion
# SIG # Begin signature block
# MIIFzgYJKoZIhvcNAQcCoIIFvzCCBbsCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCAFAIel1IXELVyn
# ZjBGABftk+Ixz4/lCdZqLFZkfCSRAaCCAzAwggMsMIICFKADAgECAhB1HRbZIqgr
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
# MAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIIz8SXnb+eWzhwm0tz11wbHh
# iiJQPsO6GrIWkcK11ADWMA0GCSqGSIb3DQEBAQUABIIBACyecXz9+pR5cKB718QX
# pDYDsPBBfolx4sSimgsxwbIMYqWP+aGab2K4KwVDjxWbIAqwpF6uPkpPstQ1U2Td
# 1DQBiHSY+czGm0Xhzn3ZrcAKJZ5x4cM6cZXL80myz3GAIo0RpmxClcOJ9Mdud3PD
# lLdqKy2g9IGtON7COhsZFjfve7uiX2tz46hrjbHD1Fcymwe5TuNrHO8iRjo0mIKv
# wzBDBt8HBS3iMshkS/5sQQ55z5sFhn7i4DSF5SjhvbGnUlYxPKgeGZcvtLXkTTn6
# CH0plu7+fUkEC508TO9duBLOxgizVaoM2jzCOUpLO/taTdLNXQ6t1GdDoAKJd1qD
# 9B0=
# SIG # End signature block
