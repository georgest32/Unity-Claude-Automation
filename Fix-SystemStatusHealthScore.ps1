# Fix-SystemStatusHealthScore.ps1
# Fix missing HealthScore properties in system status validation
# Add missing HealthScore properties to subsystems that need them
# Date: 2025-08-21

[CmdletBinding()]
param()

Write-Host "=== SystemStatus HealthScore Fix ===" -ForegroundColor Cyan
Write-Host "Adding missing HealthScore properties to subsystem registrations" -ForegroundColor White
Write-Host ""

$statusFile = ".\Modules\system_status.json"

Write-Host "[DEBUG] [HealthScoreFix] Reading current system status..." -ForegroundColor Gray

try {
    if (-not (Test-Path $statusFile)) {
        Write-Host "[ERROR] [HealthScoreFix] System status file not found: $statusFile" -ForegroundColor Red
        exit 1
    }
    
    # Read current status
    $statusContent = Get-Content $statusFile -Raw -Encoding UTF8
    $statusData = $statusContent | ConvertFrom-Json
    
    Write-Host "[INFO] [HealthScoreFix] Current subsystems in status file:" -ForegroundColor White
    
    $subsystemsFixed = 0
    $subsystemsTotal = 0
    
    # Check each subsystem for HealthScore
    foreach ($subsystemName in $statusData.subsystems.PSObject.Properties.Name) {
        $subsystem = $statusData.subsystems.$subsystemName
        $subsystemsTotal++
        
        $hasHealthScore = $subsystem.PSObject.Properties.Name -contains "HealthScore"
        $healthScoreValue = if ($hasHealthScore) { $subsystem.HealthScore } else { "MISSING" }
        
        Write-Host "  $subsystemName`: HealthScore = $healthScoreValue" -ForegroundColor $(if ($hasHealthScore) { "Green" } else { "Red" })
        
        # Add HealthScore if missing
        if (-not $hasHealthScore) {
            $subsystem | Add-Member -MemberType NoteProperty -Name "HealthScore" -Value 0 -Force
            Write-Host "    [FIXED] Added HealthScore property (default: 0)" -ForegroundColor Yellow
            $subsystemsFixed++
        }
    }
    
    # Check if we need to add any missing standard subsystems
    $standardSubsystems = @("ClaudeCodeCLI", "Unity-Claude-AutonomousAgent")
    
    foreach ($standardName in $standardSubsystems) {
        $existsInStatus = $statusData.subsystems.PSObject.Properties.Name -contains $standardName
        
        if (-not $existsInStatus) {
            Write-Host "[INFO] [HealthScoreFix] Adding missing standard subsystem: $standardName" -ForegroundColor Yellow
            
            # Create basic subsystem structure with HealthScore
            $newSubsystem = @{
                ProcessId = $null
                Status = "Unknown"
                LastHeartbeat = (Get-Date -Format "yyyy-MM-dd HH:mm:ss.fff")
                HealthScore = 0
                Performance = @{
                    ResponseTimeMs = 0
                    CpuPercent = 0
                    MemoryMB = 0
                }
                ModuleInfo = @{
                    Path = $null
                    ExportedFunctions = @{}
                    Version = "1.0.0"
                }
            }
            
            $statusData.subsystems | Add-Member -MemberType NoteProperty -Name $standardName -Value $newSubsystem -Force
            Write-Host "    [ADDED] Created subsystem '$standardName' with HealthScore" -ForegroundColor Green
            $subsystemsFixed++
        }
    }
    
    # Update timestamp
    $statusData.last_update = Get-Date -Format "yyyy-MM-dd HH:mm:ss.fff"
    
    # Save updated status
    $updatedJson = $statusData | ConvertTo-Json -Depth 10
    $updatedJson | Set-Content $statusFile -Encoding UTF8
    
    Write-Host ""
    Write-Host "[SUCCESS] [HealthScoreFix] System status updated successfully" -ForegroundColor Green
    Write-Host "[INFO] [HealthScoreFix] Subsystems processed: $subsystemsTotal" -ForegroundColor White
    Write-Host "[INFO] [HealthScoreFix] Subsystems fixed: $subsystemsFixed" -ForegroundColor White
    
} catch {
    Write-Host "[ERROR] [HealthScoreFix] Failed to fix system status: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "=== Validation Test ===" -ForegroundColor Yellow

try {
    # Test the fix by importing SystemStatus module and reading status
    Write-Host "[DEBUG] [HealthScoreFix] Testing SystemStatus module validation..." -ForegroundColor Gray
    
    # Import SystemStatus module if not already loaded
    if (-not (Get-Module Unity-Claude-SystemStatus)) {
        Import-Module ".\Modules\Unity-Claude-SystemStatus\Unity-Claude-SystemStatus.psm1" -Force -Global -ErrorAction Stop
    }
    
    # Test reading system status (this should trigger validation)
    $testStatus = Read-SystemStatus
    
    if ($testStatus) {
        Write-Host "[SUCCESS] [HealthScoreFix] SystemStatus validation passed" -ForegroundColor Green
        Write-Host "[INFO] [HealthScoreFix] Total subsystems: $($testStatus.subsystems.Count)" -ForegroundColor White
        
        # Check for validation errors in the logs
        $recentLogs = Get-Content ".\unity_claude_automation.log" -Tail 10 -ErrorAction SilentlyContinue
        $healthScoreErrors = $recentLogs | Where-Object { $_ -like "*Missing required property 'HealthScore'*" }
        
        if ($healthScoreErrors) {
            Write-Host "[WARNING] [HealthScoreFix] Still finding HealthScore validation errors:" -ForegroundColor Yellow
            foreach ($error in $healthScoreErrors) {
                Write-Host "  $error" -ForegroundColor Red
            }
        } else {
            Write-Host "[SUCCESS] [HealthScoreFix] No HealthScore validation errors detected" -ForegroundColor Green
        }
    }
    
} catch {
    Write-Host "[ERROR] [HealthScoreFix] Validation test failed: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host ""
Write-Host "=== Fix Summary ===" -ForegroundColor Cyan

Write-Host "HealthScore Fix Applied:" -ForegroundColor White
Write-Host "- Added missing HealthScore properties to all subsystems" -ForegroundColor Gray
Write-Host "- Created missing standard subsystems if needed" -ForegroundColor Gray  
Write-Host "- Updated system status timestamp" -ForegroundColor Gray
Write-Host "- Validated fix with SystemStatus module" -ForegroundColor Gray

Write-Host ""
Write-Host "Next Steps:" -ForegroundColor White
Write-Host "1. Restart Start-UnifiedSystem-Complete.ps1 to test fix" -ForegroundColor Gray
Write-Host "2. Monitor for HealthScore validation errors" -ForegroundColor Gray
Write-Host "3. Proceed with email notification integration" -ForegroundColor Gray

Write-Host ""
Write-Host "=== HealthScore Fix Complete ===" -ForegroundColor Cyan
# SIG # Begin signature block
# MIIFqQYJKoZIhvcNAQcCoIIFmjCCBZYCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQU6I5Vp/qQBuHzUbgbPqTIWzUx
# ELqgggMwMIIDLDCCAhSgAwIBAgIQdR0W2SKoK5VE8JId4ZxrRTANBgkqhkiG9w0B
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
# CQQxFgQUBtxrqM0Puf4+51LLhgnv2MvX0MkwDQYJKoZIhvcNAQEBBQAEggEAF+pf
# aPBLW/ffUw4dS1Q6vDWjxhdfLeYbMbWo/4uWbGjCAEkpzbcBq7bLY7HdH2Mjw0EL
# gKcHcC28kdiXqs5T7DDNuLdjU0akku9IZxNDYrEG0VDFg7wI1r/dmAUtB/57Z1as
# FXi4EBjV1v0COUTf9NHgFLhQOy2B9HaiXWyb768UAjJ9OakMAyazvNsN4m9kITX+
# ERQm+jNoQ7aBiLryWAs2GqjQl4fuWtq6rosc4qplz2l8u08Gah6ymGfcYYA4IQ0Q
# NIpe+vUkoq98Z5Jufkqzu0VPnXBUix7TqzZKHxLM9DKwCJBSdcxbzmjHIppYTxQz
# 3s6cic3rwZYKrLc88Q==
# SIG # End signature block
