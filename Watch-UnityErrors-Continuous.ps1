# Watch-UnityErrors-Continuous.ps1
# Continuous monitoring system for Unity compilation errors with automatic Claude fix application
# Implements FileSystemWatcher with debouncing and Unity-Claude-FixEngine integration

[CmdletBinding()]
param(
    [string]$EditorLogPath = "C:\Users\georg\AppData\Local\Unity\Editor\Editor.log",
    [string]$ErrorJsonPath = "C:\UnityProjects\Sound-and-Shoal\Dithering\AutomationLogs\current_errors.json",
    [string]$ServerUrl = "http://localhost:5560",
    [int]$DebounceMs = 2000,  # Wait 2 seconds after last change before processing
    [int]$MaxRetries = 3,
    [double]$AutoApplyThreshold = 0.7,  # Confidence threshold for automatic fix application
    [switch]$DryRun,   # Don't actually apply fixes, just log what would happen
    [switch]$ForceManualApproval  # Always require human approval regardless of confidence
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

# Import required types
Add-Type -TypeDefinition @"
using System;
using System.Collections.Concurrent;
public class ErrorEvent {
    public DateTime Timestamp { get; set; }
    public string FilePath { get; set; }
    public string ChangeType { get; set; }
    public string[] Errors { get; set; }
}
"@

# Initialize logging
$LogFile = Join-Path $PSScriptRoot "unity_claude_automation.log"
function Write-Log {
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

# Initialize state management
$script:State = @{
    LastProcessedTime = [DateTime]::MinValue
    LastErrorHash = ""
    ProcessingQueue = [System.Collections.Concurrent.ConcurrentQueue[ErrorEvent]]::new()
    IsProcessing = $false
    LastDebounceTimer = $null
    ConsecutiveFailures = 0
    TotalErrorsFixed = 0
    TotalSubmissions = 0
    AutoAppliedFixes = 0
    ManualApprovalRequired = 0
    FixApplicationResults = @()
    PendingManualApprovals = @()
}

# Function to check if server is running
function Test-ServerConnection {
    try {
        $response = Invoke-RestMethod -Uri "$ServerUrl/status" -Method GET -ErrorAction SilentlyContinue
        return $response.status -eq 'running'
    } catch {
        return $false
    }
}

# Function to trigger Unity compilation via server
function Invoke-UnityCompilation {
    Write-Log "Triggering Unity compilation..." "INFO"
    try {
        $body = @{ command = "trigger-compilation" } | ConvertTo-Json
        $response = Invoke-RestMethod -Uri "$ServerUrl/command" -Method POST -Body $body -ContentType 'application/json'
        
        if ($response.status -eq 'success') {
            Write-Log "Unity compilation triggered successfully" "SUCCESS"
            return $true
        } else {
            Write-Log "Failed to trigger compilation: $($response.message)" "ERROR"
            return $false
        }
    } catch {
        Write-Log "Error triggering compilation: $_" "ERROR"
        return $false
    }
}

# Function to get current errors from Unity
function Get-CurrentErrors {
    try {
        if (Test-Path $ErrorJsonPath) {
            $content = Get-Content $ErrorJsonPath -Raw
            if ($content) {
                $parsed = $content | ConvertFrom-Json
                # Handle both array and object formats
                if ($parsed -is [array]) {
                    return $parsed
                } elseif ($parsed -is [PSCustomObject] -or $parsed -is [hashtable]) {
                    # Empty object {} means no errors
                    $props = @($parsed.PSObject.Properties)
                    if ($props.Count -eq 0) {
                        return @()
                    }
                    # If object has properties, convert to array
                    return @($parsed)
                }
            }
        }
        return @()
    } catch {
        Write-Log "Error reading current_errors.json: $_" "ERROR"
        return @()
    }
}

# Function to calculate error hash for comparison
function Get-ErrorHash {
    param($Errors)
    
    if (-not $Errors -or $Errors.Count -eq 0) {
        return ""
    }
    
    $errorString = ($Errors | Sort-Object | Out-String)
    $bytes = [System.Text.Encoding]::UTF8.GetBytes($errorString)
    $hash = [System.Security.Cryptography.SHA256]::Create()
    $hashBytes = $hash.ComputeHash($bytes)
    return [System.BitConverter]::ToString($hashBytes).Replace("-", "")
}

# Function to parse error details from Unity error strings
function Parse-UnityError {
    param([string]$ErrorString)
    
    $result = @{
        FilePath = ""
        LineNumber = 0
        ColumnNumber = 0
        ErrorCode = ""
        Message = ""
        FullMessage = $ErrorString
    }
    
    # Parse Unity error format: FilePath(line,col): error CSxxxx: message
    if ($ErrorString -match '^(.+?)\((\d+),(\d+)\):\s*error\s+(CS\d+):\s*(.+)$') {
        $result.FilePath = $matches[1].Trim()
        $result.LineNumber = [int]$matches[2]
        $result.ColumnNumber = [int]$matches[3]
        $result.ErrorCode = $matches[4]
        $result.Message = $matches[5]
    } elseif ($ErrorString -match '^(.+?)\((\d+),(\d+)\):\s*(.+)$') {
        # Fallback pattern without error code
        $result.FilePath = $matches[1].Trim()
        $result.LineNumber = [int]$matches[2]
        $result.ColumnNumber = [int]$matches[3]
        $result.Message = $matches[4]
    }
    
    return $result
}

# Function to apply fix using Unity-Claude-FixEngine with confidence-based decision making
function Apply-FixWithConfidenceCheck {
    param(
        [string]$FilePath,
        [string]$ErrorMessage,
        [hashtable]$ParsedError
    )
    
    try {
        Write-Log "Attempting to fix error in: $FilePath" "INFO"
        Write-Log "Error: $ErrorMessage" "INFO"
        
        if ($DryRun) {
            Write-Log "[DRY RUN] Would attempt to fix: $ErrorMessage" "INFO"
            return @{ Success = $true; DryRun = $true; Confidence = 0.8 }
        }
        
        # Use Unity-Claude-FixEngine to generate and apply fix
        $fixResult = Invoke-ClaudeFixApplication -FilePath $FilePath -ErrorMessage $ErrorMessage
        
        if ($fixResult.Success) {
            $confidence = if ($fixResult.Confidence) { $fixResult.Confidence } else { 0.5 }
            Write-Log "Fix generated with confidence: $confidence" "INFO"
            
            # Determine if auto-apply or manual approval is needed
            if ($ForceManualApproval -or $confidence -lt $AutoApplyThreshold) {
                # Requires manual approval
                Write-Log "Fix requires manual approval (confidence: $confidence < threshold: $AutoApplyThreshold)" "WARNING"
                
                $approvalItem = @{
                    Timestamp = Get-Date
                    FilePath = $FilePath
                    ErrorMessage = $ErrorMessage
                    ParsedError = $ParsedError
                    FixResult = $fixResult
                    Confidence = $confidence
                    Status = "PendingApproval"
                }
                
                $script:State.PendingManualApprovals += $approvalItem
                $script:State.ManualApprovalRequired++
                
                # Save pending approval to file for review
                Save-PendingApproval -ApprovalItem $approvalItem
                
                return @{ 
                    Success = $false; 
                    RequiresApproval = $true; 
                    Confidence = $confidence;
                    Message = "Fix requires manual approval"
                }
            } else {
                # Auto-apply fix
                Write-Log "Auto-applying fix with high confidence: $confidence" "SUCCESS"
                $script:State.AutoAppliedFixes++
                
                # Log the successful fix application
                $resultItem = @{
                    Timestamp = Get-Date
                    FilePath = $FilePath
                    ErrorMessage = $ErrorMessage
                    FixResult = $fixResult
                    Confidence = $confidence
                    Applied = $true
                    AutoApplied = $true
                }
                
                $script:State.FixApplicationResults += $resultItem
                
                return @{ 
                    Success = $true; 
                    AutoApplied = $true; 
                    Confidence = $confidence;
                    FixResult = $fixResult
                }
            }
        } else {
            Write-Log "Failed to generate fix: $($fixResult.Error)" "ERROR"
            return @{ 
                Success = $false; 
                Error = $fixResult.Error;
                Message = "Fix generation failed"
            }
        }
        
    } catch {
        Write-Log "Exception in fix application: $_" "ERROR"
        return @{ Success = $false; Error = $_; Message = "Exception during fix application" }
    }
}

# Function to process errors using Unity-Claude-FixEngine
function Process-ErrorsWithFixEngine {
    param($Errors)
    
    $script:State.TotalSubmissions++
    
    Write-Log "Processing $($Errors.Count) errors with Unity-Claude-FixEngine..." "INFO"
    
    $successfulFixes = 0
    $failedFixes = 0
    $pendingApprovals = 0
    
    try {
        foreach ($errorString in $Errors) {
            $parsedError = Parse-UnityError -ErrorString $errorString
            
            if ($parsedError.FilePath -and (Test-Path $parsedError.FilePath)) {
                Write-Log "Processing error in file: $($parsedError.FilePath)" "INFO"
                
                $fixResult = Apply-FixWithConfidenceCheck -FilePath $parsedError.FilePath -ErrorMessage $errorString -ParsedError $parsedError
                
                if ($fixResult.Success) {
                    $successfulFixes++
                    Write-Log "Successfully applied fix for: $($parsedError.FilePath)" "SUCCESS"
                } elseif ($fixResult.RequiresApproval) {
                    $pendingApprovals++
                    Write-Log "Fix requires manual approval for: $($parsedError.FilePath)" "WARNING"
                } else {
                    $failedFixes++
                    Write-Log "Failed to fix: $($parsedError.FilePath) - $($fixResult.Message)" "ERROR"
                }
            } else {
                Write-Log "Cannot process error - file not found or path not parsed: $errorString" "WARNING"
                $failedFixes++
            }
        }
        
        # Summary
        Write-Log "Fix processing completed - Success: $successfulFixes, Failed: $failedFixes, Pending Approval: $pendingApprovals" "INFO"
        
        return @{
            Success = ($successfulFixes -gt 0 -or $pendingApprovals -gt 0)
            SuccessfulFixes = $successfulFixes
            FailedFixes = $failedFixes
            PendingApprovals = $pendingApprovals
        }
        
    } catch {
        Write-Log "Error in fix engine processing: $_" "ERROR"
        return @{ Success = $false; Error = $_ }
    }
}

# Function to save pending approval to file for human review
function Save-PendingApproval {
    param($ApprovalItem)
    
    try {
        $approvalDir = Join-Path $PSScriptRoot "PendingApprovals"
        if (-not (Test-Path $approvalDir)) {
            New-Item -Path $approvalDir -ItemType Directory -Force | Out-Null
        }
        
        $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
        $fileName = "approval_${timestamp}_$(Split-Path $ApprovalItem.FilePath -Leaf).json"
        $filePath = Join-Path $approvalDir $fileName
        
        $ApprovalItem | ConvertTo-Json -Depth 10 | Set-Content -Path $filePath -Encoding UTF8
        
        Write-Log "Pending approval saved to: $filePath" "INFO"
        Write-Host "MANUAL APPROVAL REQUIRED:" -ForegroundColor Yellow
        Write-Host "  File: $($ApprovalItem.FilePath)" -ForegroundColor Yellow
        Write-Host "  Error: $($ApprovalItem.ErrorMessage)" -ForegroundColor Yellow
        Write-Host "  Confidence: $($ApprovalItem.Confidence)" -ForegroundColor Yellow
        Write-Host "  Review file: $filePath" -ForegroundColor Yellow
        Write-Host "" -ForegroundColor Yellow
        
    } catch {
        Write-Log "Failed to save pending approval: $_" "ERROR"
    }
}

# Function to display pending approvals summary
function Show-PendingApprovalsSummary {
    if ($script:State.PendingManualApprovals.Count -gt 0) {
        Write-Host "\n=== PENDING MANUAL APPROVALS ===" -ForegroundColor Yellow
        
        foreach ($approval in $script:State.PendingManualApprovals) {
            Write-Host "File: $($approval.FilePath)" -ForegroundColor White
            Write-Host "Error: $($approval.ErrorMessage)" -ForegroundColor Gray
            Write-Host "Confidence: $($approval.Confidence)" -ForegroundColor Gray
            Write-Host "Time: $($approval.Timestamp)" -ForegroundColor Gray
            Write-Host "" -ForegroundColor Gray
        }
        
        Write-Host "Total pending approvals: $($script:State.PendingManualApprovals.Count)" -ForegroundColor Yellow
        Write-Host "Check PendingApprovals folder for detailed fix previews" -ForegroundColor Yellow
        Write-Host "" -ForegroundColor Yellow
    }
}

# Function to process error queue with debouncing
function Process-ErrorQueue {
    if ($script:State.IsProcessing) {
        Write-Log "Already processing, skipping..." "WARNING"
        return
    }
    
    $script:State.IsProcessing = $true
    
    try {
        # Get current errors
        $currentErrors = Get-CurrentErrors
        
        if ($currentErrors.Count -eq 0) {
            Write-Log "No compilation errors detected" "SUCCESS"
            $script:State.ConsecutiveFailures = 0
            return
        }
        
        # Check if errors have changed
        $currentHash = Get-ErrorHash -Errors $currentErrors
        if ($currentHash -eq $script:State.LastErrorHash) {
            Write-Log "Errors unchanged, skipping submission" "INFO"
            return
        }
        
        Write-Log "Detected $($currentErrors.Count) new/changed compilation errors" "WARNING"
        $script:State.LastErrorHash = $currentHash
        
        # Process errors with Unity-Claude-FixEngine
        $processResult = Process-ErrorsWithFixEngine -Errors $currentErrors
        
        if ($processResult.Success) {
            Write-Log "Fix processing completed - Applied: $($processResult.SuccessfulFixes), Pending: $($processResult.PendingApprovals)" "SUCCESS"
            
            # Wait for any async fix application to complete
            if ($processResult.SuccessfulFixes -gt 0) {
                Write-Log "Waiting 10 seconds for applied fixes to be processed by Unity..." "INFO"
                Start-Sleep -Seconds 10
            }
            
            # Trigger recompilation to check if errors are fixed
            if (Test-ServerConnection) {
                Invoke-UnityCompilation
                
                # Wait for compilation to complete
                Start-Sleep -Seconds 5
                
                # Check if errors are resolved
                $newErrors = Get-CurrentErrors
                if ($newErrors.Count -eq 0) {
                    Write-Log "All errors fixed successfully!" "SUCCESS"
                    $script:State.TotalErrorsFixed += $processResult.SuccessfulFixes
                    $script:State.ConsecutiveFailures = 0
                    $script:State.LastErrorHash = ""  # Clear hash when no errors
                } elseif ($newErrors.Count -lt $currentErrors.Count) {
                    $actualFixed = $currentErrors.Count - $newErrors.Count
                    Write-Log "Partially fixed: $actualFixed errors resolved, $($newErrors.Count) remaining" "WARNING"
                    $script:State.TotalErrorsFixed += $actualFixed
                    $script:State.LastErrorHash = Get-ErrorHash -Errors $newErrors  # Update hash
                } else {
                    Write-Log "No errors resolved by compilation - may need manual intervention" "WARNING"
                    if ($processResult.PendingApprovals -eq 0) {
                        $script:State.ConsecutiveFailures++
                    }
                }
            } else {
                Write-Log "Server not available for compilation trigger" "WARNING"
            }
            
            # Show pending approvals summary if any
            if ($processResult.PendingApprovals -gt 0) {
                Show-PendingApprovalsSummary
            }
        } else {
            $script:State.ConsecutiveFailures++
            Write-Log "Failed to process errors with fix engine (failure count: $($script:State.ConsecutiveFailures))" "ERROR"
        }
        
        # Check for too many consecutive failures
        if ($script:State.ConsecutiveFailures -ge $MaxRetries) {
            Write-Log "Maximum consecutive failures reached. Pausing for 5 minutes..." "ERROR"
            Start-Sleep -Seconds 300
            $script:State.ConsecutiveFailures = 0
        }
        
    } catch {
        Write-Log "Error in processing queue: $_" "ERROR"
    } finally {
        $script:State.IsProcessing = $false
    }
}

# Function to setup FileSystemWatcher with debouncing
function Start-FileWatcher {
    Write-Log "Setting up file system watcher for: $ErrorJsonPath" "INFO"
    
    $folder = Split-Path $ErrorJsonPath -Parent
    $filter = Split-Path $ErrorJsonPath -Leaf
    
    # Create FileSystemWatcher
    $watcher = New-Object System.IO.FileSystemWatcher
    $watcher.Path = $folder
    $watcher.Filter = $filter
    $watcher.NotifyFilter = [System.IO.NotifyFilters]::LastWrite
    $watcher.EnableRaisingEvents = $true
    
    # Define action for file changes with debouncing
    $action = {
        $path = $Event.SourceEventArgs.FullPath
        $changeType = $Event.SourceEventArgs.ChangeType
        $timeStamp = $Event.TimeGenerated
        
        Write-Host "[$timeStamp] File change detected: $changeType" -ForegroundColor Gray
        
        # Cancel previous debounce timer if exists
        if ($script:State.LastDebounceTimer) {
            Unregister-Event -SourceIdentifier "DebounceTimer" -ErrorAction SilentlyContinue
        }
        
        # Create new debounce timer
        $timer = New-Object System.Timers.Timer
        $timer.Interval = $DebounceMs
        $timer.AutoReset = $false
        
        Register-ObjectEvent -InputObject $timer -EventName Elapsed -SourceIdentifier "DebounceTimer" -Action {
            Process-ErrorQueue
        } | Out-Null
        
        $timer.Start()
        $script:State.LastDebounceTimer = $timer
    }
    
    # Register events
    Register-ObjectEvent -InputObject $watcher -EventName "Changed" -Action $action | Out-Null
    
    return $watcher
}

# Main execution
Write-Host ""
Write-Host "=== Unity-Claude Continuous Error Monitor ===" -ForegroundColor Cyan
Write-Host ""
Write-Log "Starting continuous error monitoring system" "INFO"

# Check prerequisites
if (-not (Test-Path $ErrorJsonPath)) {
    Write-Log "Error file not found: $ErrorJsonPath" "ERROR"
    Write-Log "Ensure Unity is running with ConsoleErrorExporter" "ERROR"
    exit 1
}

Write-Host "Unity-Claude-FixEngine Mode: Automated error fixing with confidence-based decisions" -ForegroundColor Green
Write-Host "Auto-apply threshold: $AutoApplyThreshold (fixes with lower confidence require manual approval)" -ForegroundColor Green
Write-Host "Force manual approval: $ForceManualApproval" -ForegroundColor Green
Write-Host ""

# Check server connection for compilation triggering
if (-not (Test-ServerConnection)) {
    Write-Log "Bidirectional server not running. Starting it..." "WARNING"
    $launcherScript = Join-Path $PSScriptRoot "Start-BidirectionalServer-Launcher.ps1"
    if (Test-Path $launcherScript) {
        & $launcherScript
        Start-Sleep -Seconds 3
    }
}

# Initial status display
Write-Host "Configuration:" -ForegroundColor Cyan
Write-Host "  Error JSON Path: $ErrorJsonPath" -ForegroundColor White
Write-Host "  Editor Log Path: $EditorLogPath" -ForegroundColor White
Write-Host "  Debounce Time: ${DebounceMs}ms" -ForegroundColor White
Write-Host "  Submission Mode: Unity-Claude-FixEngine (Automated)" -ForegroundColor White
Write-Host "  Auto-Apply Threshold: $AutoApplyThreshold" -ForegroundColor White
Write-Host "  Force Manual Approval: $ForceManualApproval" -ForegroundColor White
Write-Host "  Dry Run: $DryRun" -ForegroundColor White
Write-Host ""

# Start file watcher
$watcher = Start-FileWatcher

# Main monitoring loop
Write-Host "Monitoring started. Press Ctrl+C to stop." -ForegroundColor Green
Write-Host ""

try {
    while ($true) {
        # Periodic status update every 60 seconds
        Start-Sleep -Seconds 60
        
        Write-Host "[$(Get-Date -Format 'HH:mm:ss')] Status Update:" -ForegroundColor Gray
        Write-Host "  Total Submissions: $($script:State.TotalSubmissions)" -ForegroundColor Gray
        Write-Host "  Total Errors Fixed: $($script:State.TotalErrorsFixed)" -ForegroundColor Gray
        Write-Host "  Auto-Applied Fixes: $($script:State.AutoAppliedFixes)" -ForegroundColor Gray
        Write-Host "  Manual Approvals Required: $($script:State.ManualApprovalRequired)" -ForegroundColor Gray
        Write-Host "  Pending Approvals: $($script:State.PendingManualApprovals.Count)" -ForegroundColor Gray
        Write-Host "  Consecutive Failures: $($script:State.ConsecutiveFailures)" -ForegroundColor Gray
        
        # Also do a manual check periodically (backup for missed events)
        if ((Get-Date) -gt $script:State.LastProcessedTime.AddMinutes(5)) {
            Write-Log "Performing periodic manual check..." "INFO"
            Process-ErrorQueue
            $script:State.LastProcessedTime = Get-Date
        }
    }
} finally {
    # Cleanup
    Write-Log "Stopping file watcher..." "INFO"
    
    if ($watcher) {
        $watcher.EnableRaisingEvents = $false
        $watcher.Dispose()
    }
    
    Get-EventSubscriber | Where-Object { $_.SourceObject -eq $watcher } | Unregister-Event
    Get-Job | Where-Object { $_.Name -like "*FileWatcher*" } | Remove-Job -Force
    
    Write-Log "Monitoring stopped" "INFO"
    Write-Host "Monitoring stopped." -ForegroundColor Yellow
}
# SIG # Begin signature block
# MIIFqQYJKoZIhvcNAQcCoIIFmjCCBZYCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUFrAPuFk/j7bFsuBqk2uH/MY9
# G9WgggMwMIIDLDCCAhSgAwIBAgIQdR0W2SKoK5VE8JId4ZxrRTANBgkqhkiG9w0B
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
# CQQxFgQULMZ9slrncVf9irZ3qG7N4/pJEfowDQYJKoZIhvcNAQEBBQAEggEAluhI
# yOOausplhK/UfawZyQBjyDq+C2BZxK+4nX58OiCH2nglL/voRuuUP3g7Mzi9nRQm
# y8FDaEKVGKLXMdZNM2zeFEtM1Up3H5kgREtkQMSeIHhFeB1dWOmHynRU2V8T7HF3
# I3JFAoGzsgnVL2I+ePY8sNyDluaWJaqzslERPvcRZwacPVi/0LDJVhhj3sQMSoYj
# 7vCAeC3lyKoSl7EPzmKgit70/72nv3ASke6FldIGU4Fi0dnQM6ZEZsPjPWbKeQ+H
# nwTXREZf8wiBgO8wLgjd4LTbCctxzjQ62qMfyMz/H4L4p6X7bmtunQH+Uk+E+pCG
# A6dcbjR41wHyF4ui5g==
# SIG # End signature block
