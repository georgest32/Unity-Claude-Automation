# Debug-Simple.ps1
# Simple debug script with ASCII-only PowerShell 5.1 syntax
# Date: 2025-08-18

Set-Location "C:\UnityProjects\Sound-and-Shoal\Unity-Claude-Automation"

Write-Host "DEBUGGING AUTONOMOUS SYSTEM" -ForegroundColor Cyan
Write-Host "============================" -ForegroundColor Cyan

# Test 1: Check Unity Editor.log
$logPath = "C:\Users\georg\AppData\Local\Unity\Editor\Editor.log"
Write-Host "Test 1: Unity Editor.log check..." -ForegroundColor Yellow

if (Test-Path $logPath) {
    $logInfo = Get-Item $logPath
    Write-Host "  Unity Editor.log found" -ForegroundColor Green
    Write-Host "  Size: $($logInfo.Length) bytes" -ForegroundColor Gray
    Write-Host "  Last modified: $($logInfo.LastWriteTime)" -ForegroundColor Gray
} else {
    Write-Host "  Unity Editor.log NOT found" -ForegroundColor Red
}

# Test 2: Check for compilation errors
Write-Host "Test 2: Checking for compilation errors..." -ForegroundColor Yellow
$logContent = Get-Content $logPath -Tail 20 -ErrorAction SilentlyContinue
$errorPatterns = @("CS0103:", "CS0246:", "CS1061:", "CS0029:", "CS1002:")
$foundErrors = @()

foreach ($pattern in $errorPatterns) {
    $matches = $logContent | Where-Object { $_ -match $pattern }
    if ($matches) {
        $foundErrors += $matches
    }
}

if ($foundErrors.Count -gt 0) {
    Write-Host "  Found $($foundErrors.Count) compilation errors:" -ForegroundColor Green
    foreach ($error in $foundErrors) {
        Write-Host "    $error" -ForegroundColor Gray
    }
} else {
    Write-Host "  No compilation errors found in recent log" -ForegroundColor Yellow
    Write-Host "  Recent log entries:" -ForegroundColor Gray
    $logContent | Select-Object -Last 3 | ForEach-Object { Write-Host "    $_" -ForegroundColor DarkGray }
}

# Test 3: Check monitoring job
Write-Host "Test 3: Checking monitoring jobs..." -ForegroundColor Yellow
$jobs = Get-Job -Name "UnityErrorMonitor" -ErrorAction SilentlyContinue

if ($jobs) {
    foreach ($job in $jobs) {
        Write-Host "  Found job ID: $($job.Id)" -ForegroundColor Green
        Write-Host "  State: $($job.State)" -ForegroundColor Gray
        Write-Host "  Has data: $($job.HasMoreData)" -ForegroundColor Gray
    }
} else {
    Write-Host "  No monitoring jobs found" -ForegroundColor Red
}

# Test 4: Test prompt generation
Write-Host "Test 4: Testing prompt generation..." -ForegroundColor Yellow
Import-Module ".\Modules\Unity-Claude-CLISubmission.psm1" -Force -ErrorAction SilentlyContinue

$testErrors = @(
    "CS0103: The name 'test' does not exist",
    "CS0246: The type 'UnknownType' could not be found"
)

$promptResult = New-AutonomousPrompt -Errors $testErrors -Context "Debug test"
if ($promptResult.Success) {
    Write-Host "  Prompt generation works" -ForegroundColor Green
    Write-Host "  Generated prompt length: $($promptResult.Prompt.Length)" -ForegroundColor Gray
} else {
    Write-Host "  Prompt generation failed" -ForegroundColor Red
}

# Test 5: Check Claude Code window
Write-Host "Test 5: Checking for Claude Code window..." -ForegroundColor Yellow
$claudeProcess = Get-Process | Where-Object { $_.MainWindowTitle -like "*Claude*" -or $_.MainWindowTitle -like "*PowerShell*" }

if ($claudeProcess) {
    Write-Host "  Found potential target windows:" -ForegroundColor Green
    foreach ($proc in $claudeProcess) {
        Write-Host "    $($proc.MainWindowTitle)" -ForegroundColor Gray
    }
} else {
    Write-Host "  No suitable windows found" -ForegroundColor Red
}

Write-Host "" -ForegroundColor White
Write-Host "NEXT STEPS:" -ForegroundColor Cyan
Write-Host "1. If no errors in log: Create Unity compilation error" -ForegroundColor White
Write-Host "2. If job not running: Restart autonomous system" -ForegroundColor White
Write-Host "3. If errors exist but not detected: Check job output" -ForegroundColor White

Write-Host "" -ForegroundColor White
Write-Host "Press Enter to exit..." -ForegroundColor Yellow
Read-Host
# SIG # Begin signature block
# MIIFqQYJKoZIhvcNAQcCoIIFmjCCBZYCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUsOnNkZWWhp1H6e20JYBPR/1c
# bv6gggMwMIIDLDCCAhSgAwIBAgIQdR0W2SKoK5VE8JId4ZxrRTANBgkqhkiG9w0B
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
# CQQxFgQUvwZWP/+Gns6/+hXvmLUcITQt7zwwDQYJKoZIhvcNAQEBBQAEggEAOfXW
# KB3aiUjFnOFfyH0L6GWJ4qG16SbMM351dYNOzZ6cBk6ISin4aEV3b7EepYp+790g
# AVtre7436/jKTYGzkVea0l5B402aRGjbBUm2ZWgDOoK4zK5NNCS3B8iC1HfnXjU3
# 8n98dCrJirdzS6FnSQoNeBpwJdRmVIv06U/MC9SzTQTSN+XCJ0UpbavLYGZZNaQO
# J9tkeA02Kvd7/jBjLuWobWbmTsMkBOk3wJR98mbmJocIosAIgnp7+0L0XallEKaz
# XSOJ2+fqRzf8BEWJAJOxTAdHJkSg80QdKCAfNN9exkigVywNaZx+3L5R0yahE+tS
# g4tkhpHO127qNIYLSA==
# SIG # End signature block
