# Review-PendingFixes.ps1
# Human approval system for reviewing and managing low-confidence Claude fixes
# Provides interactive interface for approving, rejecting, or modifying pending fixes

[CmdletBinding()]
param(
    [Parameter()]
    [ValidateSet("List", "Review", "Approve", "Reject", "ApproveAll", "RejectAll", "Clean")]
    [string]$Action = "List",
    
    [Parameter()]
    [string]$ApprovalId = "",
    
    [Parameter()]
    [switch]$AutoApply,  # Automatically apply approved fixes
    
    [Parameter()]
    [switch]$Interactive  # Interactive mode for step-by-step review
)

$ErrorActionPreference = 'Stop'

# Import Unity-Claude-FixEngine module
try {
    $ModulePath = Join-Path $PSScriptRoot "Modules\Unity-Claude-FixEngine\Unity-Claude-FixEngine.psd1"
    if (Test-Path $ModulePath) {
        Import-Module $ModulePath -Force -ErrorAction Stop
        Write-Host "Unity-Claude-FixEngine module loaded successfully" -ForegroundColor Green
    } else {
        throw "Unity-Claude-FixEngine module not found at: $ModulePath"
    }
} catch {
    Write-Error "Failed to load Unity-Claude-FixEngine module: $_"
    exit 1
}

# Initialize paths
$ApprovalDir = Join-Path $PSScriptRoot "PendingApprovals"
$ApprovedDir = Join-Path $PSScriptRoot "ApprovedFixes"
$RejectedDir = Join-Path $PSScriptRoot "RejectedFixes"
$LogFile = Join-Path $PSScriptRoot "fix_approval.log"

# Ensure directories exist
@($ApprovalDir, $ApprovedDir, $RejectedDir) | ForEach-Object {
    if (-not (Test-Path $_)) {
        New-Item -Path $_ -ItemType Directory -Force | Out-Null
    }
}

# Logging function
function Write-ApprovalLog {
    param(
        [string]$Message,
        [string]$Level = "INFO"
    )
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logEntry = "[$timestamp] [$Level] $Message"
    Add-Content -Path $LogFile -Value $logEntry -Force
    
    switch ($Level) {
        "ERROR" { Write-Host $logEntry -ForegroundColor Red }
        "WARNING" { Write-Host $logEntry -ForegroundColor Yellow }
        "SUCCESS" { Write-Host $logEntry -ForegroundColor Green }
        default { Write-Host $logEntry -ForegroundColor Gray }
    }
}

# Function to get all pending approvals
function Get-PendingApprovals {
    $approvals = @()
    
    if (Test-Path $ApprovalDir) {
        $approvalFiles = Get-ChildItem -Path $ApprovalDir -Filter "*.json" | Sort-Object LastWriteTime -Descending
        
        foreach ($file in $approvalFiles) {
            try {
                $content = Get-Content -Path $file.FullName -Raw | ConvertFrom-Json
                $approval = [PSCustomObject]@{
                    Id = $file.BaseName
                    FilePath = $content.FilePath
                    ErrorMessage = $content.ErrorMessage
                    Confidence = $content.Confidence
                    Timestamp = $content.Timestamp
                    FixResult = $content.FixResult
                    ParsedError = $content.ParsedError
                    ApprovalFile = $file.FullName
                    Status = $content.Status ?? "PendingApproval"
                }
                $approvals += $approval
            } catch {
                Write-ApprovalLog "Failed to parse approval file: $($file.Name) - $_" "ERROR"
            }
        }
    }
    
    return $approvals
}

# Function to display pending approvals list
function Show-PendingApprovalsList {
    $approvals = Get-PendingApprovals
    
    if ($approvals.Count -eq 0) {
        Write-Host "No pending approvals found." -ForegroundColor Green
        return
    }
    
    Write-Host "`n=== PENDING FIX APPROVALS ===" -ForegroundColor Cyan
    Write-Host "Total pending: $($approvals.Count)" -ForegroundColor White
    Write-Host ""
    
    $index = 1
    foreach ($approval in $approvals) {
        $ageMinutes = [math]::Round(((Get-Date) - [DateTime]$approval.Timestamp).TotalMinutes, 1)
        
        Write-Host "[$index] $($approval.Id)" -ForegroundColor Yellow
        Write-Host "    File: $($approval.FilePath)" -ForegroundColor White
        Write-Host "    Error: $($approval.ErrorMessage)" -ForegroundColor Gray
        Write-Host "    Confidence: $($approval.Confidence) (Threshold: Auto-apply if > 0.7)" -ForegroundColor Gray
        Write-Host "    Age: $ageMinutes minutes" -ForegroundColor Gray
        Write-Host ""
        $index++
    }
    
    Write-Host "Use 'Review-PendingFixes.ps1 -Action Review -ApprovalId <id>' to review individual fixes" -ForegroundColor Cyan
    Write-Host "Use 'Review-PendingFixes.ps1 -Interactive' for step-by-step review" -ForegroundColor Cyan
}

# Function to review a specific approval in detail
function Show-ApprovalDetails {
    param([string]$ApprovalId)
    
    $approvals = Get-PendingApprovals
    $approval = $approvals | Where-Object { $_.Id -eq $ApprovalId }
    
    if (-not $approval) {
        Write-Host "Approval not found: $ApprovalId" -ForegroundColor Red
        return $null
    }
    
    Write-Host "`n=== FIX APPROVAL DETAILS ===" -ForegroundColor Cyan
    Write-Host "ID: $($approval.Id)" -ForegroundColor Yellow
    Write-Host "File: $($approval.FilePath)" -ForegroundColor White
    Write-Host "Error: $($approval.ErrorMessage)" -ForegroundColor Gray
    Write-Host "Confidence: $($approval.Confidence)" -ForegroundColor Gray
    Write-Host "Timestamp: $($approval.Timestamp)" -ForegroundColor Gray
    Write-Host ""
    
    # Show current file content
    if (Test-Path $approval.FilePath) {
        Write-Host "=== CURRENT FILE CONTENT ===" -ForegroundColor Cyan
        $content = Get-Content -Path $approval.FilePath
        $lineNum = 1
        foreach ($line in $content) {
            $prefix = if ($lineNum -eq $approval.ParsedError.LineNumber) { ">>> " } else { "    " }
            Write-Host "$prefix$($lineNum.ToString().PadLeft(3)): $line" -ForegroundColor $(if ($lineNum -eq $approval.ParsedError.LineNumber) { "Yellow" } else { "Gray" })
            $lineNum++
            if ($lineNum -gt 50) {
                Write-Host "    ... (file truncated for display)" -ForegroundColor Gray
                break
            }
        }
        Write-Host ""
    }
    
    # Show proposed fix
    if ($approval.FixResult -and $approval.FixResult.SuggestedFix) {
        Write-Host "=== PROPOSED FIX ===" -ForegroundColor Cyan
        Write-Host $approval.FixResult.SuggestedFix -ForegroundColor White
        Write-Host ""
        
        # Show fix preview if possible
        try {
            $previewResult = Apply-FixToContent -FilePath $approval.FilePath -Fix $approval.FixResult.SuggestedFix -Preview
            Write-Host "=== FIX PREVIEW (First 30 lines) ===" -ForegroundColor Cyan
            $previewLines = $previewResult -split "`n" | Select-Object -First 30
            $lineNum = 1
            foreach ($line in $previewLines) {
                Write-Host "    $($lineNum.ToString().PadLeft(3)): $line" -ForegroundColor Cyan
                $lineNum++
            }
            if ($previewResult -split "`n" | Measure-Object | Select-Object -ExpandProperty Count -gt 30) {
                Write-Host "    ... (preview truncated)" -ForegroundColor Gray
            }
            Write-Host ""
        } catch {
            Write-Host "Unable to generate fix preview: $_" -ForegroundColor Red
        }
    }
    
    # Show safety assessment
    if ($approval.FixResult -and $approval.FixResult.SafetyResult) {
        Write-Host "=== SAFETY ASSESSMENT ===" -ForegroundColor Cyan
        $safety = $approval.FixResult.SafetyResult
        Write-Host "Safe: $($safety.IsSafe)" -ForegroundColor $(if ($safety.IsSafe) { "Green" } else { "Red" })
        Write-Host "Reason: $($safety.Reason)" -ForegroundColor Gray
        
        if ($safety.Warnings -and $safety.Warnings.Count -gt 0) {
            Write-Host "Warnings:" -ForegroundColor Yellow
            foreach ($warning in $safety.Warnings) {
                Write-Host "  - $warning" -ForegroundColor Yellow
            }
        }
        
        if ($safety.Recommendations -and $safety.Recommendations.Count -gt 0) {
            Write-Host "Recommendations:" -ForegroundColor Blue
            foreach ($rec in $safety.Recommendations) {
                Write-Host "  - $rec" -ForegroundColor Blue
            }
        }
        Write-Host ""
    }
    
    return $approval
}

# Function to approve a fix
function Approve-Fix {
    param(
        [Parameter(Mandatory = $true)]
        $Approval,
        
        [switch]$Apply
    )
    
    try {
        Write-ApprovalLog "Approving fix for: $($Approval.FilePath)" "INFO"
        
        # Move approval file to approved directory
        $approvedFile = Join-Path $ApprovedDir "$($Approval.Id).json"
        Move-Item -Path $Approval.ApprovalFile -Destination $approvedFile
        
        # Apply fix if requested
        if ($Apply) {
            Write-Host "Applying approved fix..." -ForegroundColor Green
            
            $result = Invoke-ClaudeFixApplication -FilePath $Approval.FilePath -ErrorMessage $Approval.ErrorMessage -Force
            
            if ($result.Success) {
                Write-ApprovalLog "Successfully applied approved fix for: $($Approval.FilePath)" "SUCCESS"
                Write-Host "Fix applied successfully!" -ForegroundColor Green
                
                # Update the approval record with application result
                $approvalData = Get-Content -Path $approvedFile -Raw | ConvertFrom-Json
                $approvalData | Add-Member -NotePropertyName "AppliedTimestamp" -NotePropertyValue (Get-Date -Format "yyyy-MM-dd HH:mm:ss")
                $approvalData | Add-Member -NotePropertyName "ApplicationResult" -NotePropertyValue $result
                $approvalData | ConvertTo-Json -Depth 10 | Set-Content -Path $approvedFile -Encoding UTF8
                
                return $true
            } else {
                Write-ApprovalLog "Failed to apply approved fix: $($result.Error)" "ERROR"
                Write-Host "Failed to apply fix: $($result.Error)" -ForegroundColor Red
                return $false
            }
        } else {
            Write-Host "Fix approved but not applied. Use -AutoApply to apply immediately." -ForegroundColor Yellow
            return $true
        }
        
    } catch {
        Write-ApprovalLog "Error approving fix: $_" "ERROR"
        Write-Host "Error approving fix: $_" -ForegroundColor Red
        return $false
    }
}

# Function to reject a fix
function Reject-Fix {
    param(
        [Parameter(Mandatory = $true)]
        $Approval,
        
        [string]$Reason = "Manual rejection"
    )
    
    try {
        Write-ApprovalLog "Rejecting fix for: $($Approval.FilePath) - Reason: $Reason" "INFO"
        
        # Add rejection reason to the approval data
        $approvalData = Get-Content -Path $Approval.ApprovalFile -Raw | ConvertFrom-Json
        $approvalData | Add-Member -NotePropertyName "RejectedTimestamp" -NotePropertyValue (Get-Date -Format "yyyy-MM-dd HH:mm:ss")
        $approvalData | Add-Member -NotePropertyName "RejectionReason" -NotePropertyValue $Reason
        
        # Move approval file to rejected directory
        $rejectedFile = Join-Path $RejectedDir "$($Approval.Id).json"
        $approvalData | ConvertTo-Json -Depth 10 | Set-Content -Path $rejectedFile -Encoding UTF8
        
        Remove-Item -Path $Approval.ApprovalFile -Force
        
        Write-Host "Fix rejected and moved to rejected fixes directory." -ForegroundColor Yellow
        return $true
        
    } catch {
        Write-ApprovalLog "Error rejecting fix: $_" "ERROR"
        Write-Host "Error rejecting fix: $_" -ForegroundColor Red
        return $false
    }
}

# Interactive review function
function Start-InteractiveReview {
    $approvals = Get-PendingApprovals
    
    if ($approvals.Count -eq 0) {
        Write-Host "No pending approvals to review." -ForegroundColor Green
        return
    }
    
    Write-Host "`n=== INTERACTIVE FIX REVIEW ===" -ForegroundColor Cyan
    Write-Host "Reviewing $($approvals.Count) pending fixes..." -ForegroundColor White
    Write-Host ""
    
    foreach ($approval in $approvals) {
        Show-ApprovalDetails -ApprovalId $approval.Id
        
        do {
            Write-Host "Actions: [A]pprove & Apply, [P]approve Only, [R]eject, [S]kip, [Q]uit" -ForegroundColor Cyan
            $choice = Read-Host "Your choice"
            
            switch ($choice.ToUpper()) {
                "A" {
                    if (Approve-Fix -Approval $approval -Apply) {
                        Write-Host "Fix approved and applied successfully!" -ForegroundColor Green
                    }
                    break
                }
                "P" {
                    if (Approve-Fix -Approval $approval) {
                        Write-Host "Fix approved (not applied)." -ForegroundColor Yellow
                    }
                    break
                }
                "R" {
                    $reason = Read-Host "Rejection reason (optional)"
                    if (-not $reason) { $reason = "Manual rejection during interactive review" }
                    if (Reject-Fix -Approval $approval -Reason $reason) {
                        Write-Host "Fix rejected." -ForegroundColor Yellow
                    }
                    break
                }
                "S" {
                    Write-Host "Skipping this fix." -ForegroundColor Gray
                    break
                }
                "Q" {
                    Write-Host "Exiting interactive review." -ForegroundColor Gray
                    return
                }
                default {
                    Write-Host "Invalid choice. Please select A, P, R, S, or Q." -ForegroundColor Red
                    continue
                }
            }
            break
        } while ($true)
        
        Write-Host ""
    }
    
    Write-Host "Interactive review completed." -ForegroundColor Green
}

# Main execution
Write-Host ""
Write-Host "=== Unity Claude Fix Approval System ===" -ForegroundColor Cyan
Write-Host ""

switch ($Action) {
    "List" {
        Show-PendingApprovalsList
    }
    
    "Review" {
        if (-not $ApprovalId) {
            Write-Host "ApprovalId is required for Review action." -ForegroundColor Red
            exit 1
        }
        Show-ApprovalDetails -ApprovalId $ApprovalId
    }
    
    "Approve" {
        if (-not $ApprovalId) {
            Write-Host "ApprovalId is required for Approve action." -ForegroundColor Red
            exit 1
        }
        
        $approvals = Get-PendingApprovals
        $approval = $approvals | Where-Object { $_.Id -eq $ApprovalId }
        
        if ($approval) {
            Approve-Fix -Approval $approval -Apply:$AutoApply
        } else {
            Write-Host "Approval not found: $ApprovalId" -ForegroundColor Red
        }
    }
    
    "Reject" {
        if (-not $ApprovalId) {
            Write-Host "ApprovalId is required for Reject action." -ForegroundColor Red
            exit 1
        }
        
        $approvals = Get-PendingApprovals
        $approval = $approvals | Where-Object { $_.Id -eq $ApprovalId }
        
        if ($approval) {
            $reason = Read-Host "Rejection reason (optional)"
            if (-not $reason) { $reason = "Manual rejection" }
            Reject-Fix -Approval $approval -Reason $reason
        } else {
            Write-Host "Approval not found: $ApprovalId" -ForegroundColor Red
        }
    }
    
    "ApproveAll" {
        $approvals = Get-PendingApprovals
        Write-Host "Approving all $($approvals.Count) pending fixes..." -ForegroundColor Yellow
        
        foreach ($approval in $approvals) {
            Approve-Fix -Approval $approval -Apply:$AutoApply
        }
    }
    
    "RejectAll" {
        $approvals = Get-PendingApprovals
        Write-Host "Rejecting all $($approvals.Count) pending fixes..." -ForegroundColor Yellow
        
        foreach ($approval in $approvals) {
            Reject-Fix -Approval $approval -Reason "Bulk rejection"
        }
    }
    
    "Clean" {
        Write-Host "Cleaning old approval files..." -ForegroundColor Yellow
        
        # Remove approval files older than 7 days
        $cutoffDate = (Get-Date).AddDays(-7)
        
        @($ApprovedDir, $RejectedDir) | ForEach-Object {
            if (Test-Path $_) {
                Get-ChildItem -Path $_ -Filter "*.json" | Where-Object { $_.LastWriteTime -lt $cutoffDate } | ForEach-Object {
                    Write-Host "Removing old file: $($_.Name)" -ForegroundColor Gray
                    Remove-Item -Path $_.FullName -Force
                }
            }
        }
        
        Write-Host "Cleanup completed." -ForegroundColor Green
    }
}

if ($Interactive) {
    Start-InteractiveReview
}

Write-Host ""
# SIG # Begin signature block
# MIIFqQYJKoZIhvcNAQcCoIIFmjCCBZYCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUk+4YWB22opCccEA7apn/Sn9u
# bymgggMwMIIDLDCCAhSgAwIBAgIQdR0W2SKoK5VE8JId4ZxrRTANBgkqhkiG9w0B
# AQsFADAuMSwwKgYDVQQDDCNVbml0eS1DbGF1ZGUtQXV0b21hdGlvbi1EZXZlbG9w
# bWVudDAeFw0yNTA4MjAyMTE1MTdaFw0yNjA4MjAyMTM1MTdaMC4xLDAqBgNVBAMM
# I1VuaXR5LUNsYXVkZS1BdXRvbWF0aW9uLURldmVsb3BtZW50MIIBIjANBgkqhkiG
# 9w0BAQEFAAOCAQ8AMIIBCgKCAQEAseH3qinVEOhrn2OLpjc5TNT4vGh1BkfB5X4S
# FhY7K0QMQsYYnkZVmx3tB8PqVQXl++l+e3uT7uCscc7vjMTK8tDSWH98ji0U34WL
# JBwXC62l1ArazMKp4Tyr7peksei7vL4pZOtOVgAyTYn5d1hbnsVQmCSTPRtpn7mC
# Azfq2ec5qZ9Kgl7puPW5utvYfh8idtOWa5/WgYSKwOIvyZawIdZKLFpwqOtqbJe4
# sWzVahasFhLfoAKkniKOAocJDkJexh5pO/EOSKEZ3mOCU1ZSs4XWRGISRhV3qGZp
# f+Y3JlHKMeFDWKynaJBO8/GU5sqMATlDUvrByBtU2OQ2Um/L3QIDAQABo0YwRDAO
# BgNVHQ8BAf8EBAMCB4AwEwYDVR0lBAwwCgYIKwYBBQUHAwMwHQYDVR0OBBYEFHw5
# rOy6xlW6B45sJUsiI2A/yS0MMA0GCSqGSIb3DQEBCwUAA4IBAQAUTLH0+w8ysvmh
# YuBw4NDKcZm40MTh9Zc1M2p2hAkYsgNLJ+/rAP+I74rNfqguTYwxpCyjkwrg8yF5
# wViwggboLpF2yDu4N/dgDainR4wR8NVpS7zFZOFkpmNPepc6bw3d4yQKa/wJXKeC
# pkRjS50N77/hfVI+fFKNao7POb7en5fcXuZaN6xWoTRy+J4I4MhfHpjZuxSLSXjb
# VXtPD4RZ9HGjl9BU8162cRhjujr/Lc3/dY/6ikHQYnxuxcdxRew4nzaqAQaOeWu6
# tGp899JPKfldM5Zay5IBl3zs15gNS9+0Jrd0ARQnSVYoI0DLh3KybFnfK4POezoN
# Lp/dbX2SMYIB4zCCAd8CAQEwQjAuMSwwKgYDVQQDDCNVbml0eS1DbGF1ZGUtQXV0
# b21hdGlvbi1EZXZlbG9wbWVudAIQdR0W2SKoK5VE8JId4ZxrRTAJBgUrDgMCGgUA
# oHgwGAYKKwYBBAGCNwIBDDEKMAigAoAAoQKAADAZBgkqhkiG9w0BCQMxDAYKKwYB
# BAGCNwIBBDAcBgorBgEEAYI3AgELMQ4wDAYKKwYBBAGCNwIBFTAjBgkqhkiG9w0B
# CQQxFgQU4+0wPhIpIpIuBJwddT2yE20MNPgwDQYJKoZIhvcNAQEBBQAEggEALZ+2
# jP3kOjfJdm/UD4WQOZ+es9qeiGS/nNqhMFx5sdHH6eFFcc0pc6eK6Zq903mzWUBq
# NsaERAMz6zjOXXX9iz9TmpnPOpqWuBLMk6qGxQCwk1C9ZIirR54ErFLewnq6lE7k
# MWDK/Alj5tThBZtrx0YqxzSSih6mUG5niVrgxZBbPRll2HMVR/iD6ZyRUR88bkEO
# 48Va4GsZPz4Ge/EkLanJdcR50yU4w5fKt5NLhINt2SBpVo7aBPXc9pB62LX/fy0j
# 82Zy/ZlD57kVs6wF8zFEHT7r5atUw0zS5VHFzSq1r06TKWZL8WRa3RMnHzKGqE44
# 6smrShSfXPynUnFDEQ==
# SIG # End signature block
