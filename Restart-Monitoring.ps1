# Restart-Monitoring.ps1
# Clean up failed jobs and restart Unity error monitoring
# Date: 2025-08-18

Set-Location "C:\UnityProjects\Sound-and-Shoal\Unity-Claude-Automation"

Write-Host "RESTARTING AUTONOMOUS MONITORING" -ForegroundColor Cyan
Write-Host "=================================" -ForegroundColor Cyan

# Step 1: Clean up any existing jobs
Write-Host "Step 1: Cleaning up existing jobs..." -ForegroundColor Yellow
$allJobs = Get-Job
if ($allJobs) {
    foreach ($job in $allJobs) {
        Write-Host "  Removing Job ID: $($job.Id) ($($job.Name)) - State: $($job.State)" -ForegroundColor Gray
        Stop-Job $job -ErrorAction SilentlyContinue
        Remove-Job $job -Force -ErrorAction SilentlyContinue
    }
    Write-Host "  All jobs cleaned up" -ForegroundColor Green
} else {
    Write-Host "  No existing jobs to clean" -ForegroundColor Gray
}

# Step 2: Load modules
Write-Host "Step 2: Loading modules..." -ForegroundColor Yellow
Import-Module ".\Modules\Unity-Claude-CLISubmission.psm1" -Force
Import-Module ".\Modules\Unity-Claude-SessionManager.psm1" -Force
Import-Module ".\Modules\Unity-Claude-AutonomousStateTracker.psm1" -Force
Write-Host "  Modules loaded" -ForegroundColor Green

# Step 3: Test Unity errors exist
Write-Host "Step 3: Verifying Unity errors..." -ForegroundColor Yellow
$logPath = "C:\Users\georg\AppData\Local\Unity\Editor\Editor.log"
$logContent = Get-Content $logPath -Tail 100

$foundErrors = @()
$errorPatterns = @("CS0103:", "CS0246:", "CS1061:", "CS0029:", "CS1002:")

foreach ($pattern in $errorPatterns) {
    $matches = $logContent | Where-Object { $_ -match $pattern }
    if ($matches) {
        $foundErrors += $matches
    }
}

if ($foundErrors.Count -gt 0) {
    Write-Host "  Found $($foundErrors.Count) Unity compilation errors" -ForegroundColor Green
    $foundErrors | Select-Object -First 3 | ForEach-Object { Write-Host "    $_" -ForegroundColor Red }
} else {
    Write-Host "  No Unity errors found - need to force Unity compilation" -ForegroundColor Yellow
}

# Step 4: Start new autonomous monitoring
Write-Host "Step 4: Starting fresh autonomous monitoring..." -ForegroundColor Yellow

# Define error callback that will actually submit to Claude
$errorCallback = {
    param($errors)
    
    Write-Host "[AUTONOMOUS] Unity errors detected: $($errors.Count)" -ForegroundColor Cyan
    
    # Generate prompt
    Import-Module "C:\UnityProjects\Sound-and-Shoal\Unity-Claude-Automation\Modules\Unity-Claude-CLISubmission.psm1" -Force
    $promptResult = New-AutonomousPrompt -Errors $errors
    
    if ($promptResult.Success) {
        Write-Host "[AUTONOMOUS] Generated prompt for $($promptResult.ErrorCount) errors" -ForegroundColor Green
        
        # Submit to Claude Code CLI
        $submissionResult = Submit-PromptToClaudeCode -Prompt $promptResult.Prompt
        
        if ($submissionResult.Success) {
            Write-Host "[AUTONOMOUS] ✅ PROMPT SUBMITTED TO CLAUDE CODE CLI!" -ForegroundColor Green
            Write-Host "[AUTONOMOUS] Target window: $($submissionResult.TargetWindow)" -ForegroundColor Gray
            Write-Host "[AUTONOMOUS] Prompt length: $($submissionResult.PromptLength) characters" -ForegroundColor Gray
        } else {
            Write-Host "[AUTONOMOUS] ❌ Failed to submit prompt: $($submissionResult.Error)" -ForegroundColor Red
        }
    } else {
        Write-Host "[AUTONOMOUS] ❌ Failed to generate prompt" -ForegroundColor Red
    }
}

# Start monitoring with our callback
$monitoringResult = Start-UnityErrorMonitoring -OnErrorDetected $errorCallback

if ($monitoringResult.Success) {
    Write-Host "  ✅ New monitoring started!" -ForegroundColor Green
    Write-Host "  Job ID: $($monitoringResult.JobId)" -ForegroundColor Gray
    
    # Verify job is running
    Start-Sleep 2
    $newJob = Get-Job -Id $monitoringResult.JobId -ErrorAction SilentlyContinue
    if ($newJob) {
        Write-Host "  Job status: $($newJob.State)" -ForegroundColor Gray
    }
} else {
    Write-Host "  ❌ Failed to start monitoring: $($monitoringResult.Error)" -ForegroundColor Red
}

Write-Host "" -ForegroundColor White
Write-Host "🚀 AUTONOMOUS MONITORING RESTARTED!" -ForegroundColor Green
Write-Host "===================================" -ForegroundColor Green
Write-Host "The system will now:" -ForegroundColor White
Write-Host "• Monitor Unity Editor.log for new compilation errors" -ForegroundColor Gray
Write-Host "• Generate intelligent prompts when errors detected" -ForegroundColor Gray
Write-Host "• Submit prompts to Claude Code CLI automatically" -ForegroundColor Gray
Write-Host "" -ForegroundColor White
Write-Host "If Unity errors already exist, make a small change in Unity to trigger recompilation" -ForegroundColor Yellow
Write-Host "Or press Ctrl+R in Unity to force refresh" -ForegroundColor Yellow

Write-Host "" -ForegroundColor White
Write-Host "Press Enter to continue monitoring..." -ForegroundColor Yellow
Read-Host
# SIG # Begin signature block
# MIIFqQYJKoZIhvcNAQcCoIIFmjCCBZYCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUZ+7dGD2LFERFVc4ysfMGLPL1
# JZigggMwMIIDLDCCAhSgAwIBAgIQdR0W2SKoK5VE8JId4ZxrRTANBgkqhkiG9w0B
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
# CQQxFgQUUqLH4dMUAtcMhP3YpwLv/qr3U9gwDQYJKoZIhvcNAQEBBQAEggEAow+h
# 8A/h2ZJvMrAGsQRp3+9MtsA9Awrh8cN0OxwmC+ehP+ogMKNu3xoWXNMCo9UwIK10
# ny0KOTQLanUI+h6QFsEJvWj3AGJKzgOJ+P6xtvd62U143MxZQ6+JhwCDDWQdq88N
# rAGf0L7fxCx0vBsq9ykF9+4CDLwos33CcPwbqEObguCNuz9TQGCjXZim1NVhkczQ
# 9nnfy9ItB/6iuuszRtqWLTqpHRhWk5d1OejnP1smKEoHPhHfoGgnt/vZP+wIjoxC
# k77T4A7ovwI7lHuTG8WHiRhGXsYtbwgGiEVZswjDHQOxb2CMG6Gdp7ah9+gIbA6g
# xlFHsbzbzt8IS6IQdg==
# SIG # End signature block
