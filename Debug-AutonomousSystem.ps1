# Debug-AutonomousSystem.ps1
# Debug why the autonomous system isn't detecting Unity errors
# Date: 2025-08-18

Set-Location "C:\UnityProjects\Sound-and-Shoal\Unity-Claude-Automation"

Write-Host "DEBUGGING AUTONOMOUS SYSTEM" -ForegroundColor Cyan
Write-Host "============================" -ForegroundColor Cyan

# Test 1: Check Unity Editor.log path
$logPath = "C:\Users\georg\AppData\Local\Unity\Editor\Editor.log"
Write-Host "Test 1: Unity Editor.log path check..." -ForegroundColor Yellow

if (Test-Path $logPath) {
    $logInfo = Get-Item $logPath
    Write-Host "  ✓ Unity Editor.log found" -ForegroundColor Green
    Write-Host "    Size: $($logInfo.Length) bytes" -ForegroundColor Gray
    Write-Host "    Last modified: $($logInfo.LastWriteTime)" -ForegroundColor Gray
} else {
    Write-Host "  ✗ Unity Editor.log NOT found at: $logPath" -ForegroundColor Red
}

# Test 2: Check for recent compilation errors
Write-Host "Test 2: Checking for recent compilation errors..." -ForegroundColor Yellow
try {
    $logContent = Get-Content $logPath -Tail 50
    $errorPatterns = @("CS0103:", "CS0246:", "CS1061:", "CS0029:", "CS1002:", "CS0117:")
    $foundErrors = @()
    
    foreach ($pattern in $errorPatterns) {
        $matches = $logContent | Where-Object { $_ -match $pattern }
        if ($matches) {
            $foundErrors += $matches
        }
    }
    
    if ($foundErrors.Count -gt 0) {
        Write-Host "  ✓ Found $($foundErrors.Count) compilation errors in recent log:" -ForegroundColor Green
        $foundErrors | ForEach-Object { Write-Host "    $_" -ForegroundColor Gray }
    } else {
        Write-Host "  ! No compilation errors found in recent log entries" -ForegroundColor Yellow
        Write-Host "    Recent log entries:" -ForegroundColor Gray
        $logContent | Select-Object -Last 5 | ForEach-Object { Write-Host "    $_" -ForegroundColor DarkGray }
    }
} catch {
    Write-Host "  ✗ Error reading Unity log: $($_.Exception.Message)" -ForegroundColor Red
}

# Test 3: Check background monitoring job status
Write-Host "Test 3: Checking Unity error monitoring job..." -ForegroundColor Yellow
$jobs = Get-Job -Name "UnityErrorMonitor" -ErrorAction SilentlyContinue

if ($jobs) {
    foreach ($job in $jobs) {
        Write-Host "  ✓ Found monitoring job ID: $($job.Id)" -ForegroundColor Green
        Write-Host "    State: $($job.State)" -ForegroundColor Gray
        Write-Host "    Has more data: $($job.HasMoreData)" -ForegroundColor Gray
        
        if ($job.HasMoreData) {
            Write-Host "    Recent job output:" -ForegroundColor Gray
            $jobOutput = Receive-Job $job -Keep
            $jobOutput | Select-Object -Last 3 | ForEach-Object { Write-Host "      $_" -ForegroundColor DarkGray }
        }
    }
} else {
    Write-Host "  ✗ No Unity error monitoring jobs found" -ForegroundColor Red
}

# Test 4: Manual error detection test
Write-Host "Test 4: Manual error detection test..." -ForegroundColor Yellow
try {
    Import-Module ".\Modules\Unity-Claude-CLISubmission.psm1" -Force
    
    # Simulate error detection
    $testErrors = @(
        "CS0103: The name 'MissingVariable' does not exist in the current context",
        "CS0246: The type or namespace name 'UnknownType' could not be found"
    )
    
    Write-Host "  Testing prompt generation with sample errors..." -ForegroundColor Gray
    $promptResult = New-AutonomousPrompt -Errors $testErrors -Context "Manual test"
    
    if ($promptResult.Success) {
        Write-Host "  ✓ Prompt generation working" -ForegroundColor Green
        Write-Host "    Error count: $($promptResult.ErrorCount)" -ForegroundColor Gray
        Write-Host "    Prompt length: $($promptResult.Prompt.Length) characters" -ForegroundColor Gray
    } else {
        Write-Host "  ✗ Prompt generation failed" -ForegroundColor Red
    }
    
} catch {
    Write-Host "  ✗ Manual test failed: $($_.Exception.Message)" -ForegroundColor Red
}

# Test 5: Check Claude Code CLI window detection
Write-Host "Test 5: Checking Claude Code CLI window detection..." -ForegroundColor Yellow
try {
    $claudeProcess = Get-Process | Where-Object { $_.MainWindowTitle -like "*Claude Code*" -or $_.ProcessName -like "*claude*" }
    
    if ($claudeProcess) {
        Write-Host "  ✓ Found potential Claude Code windows:" -ForegroundColor Green
        $claudeProcess | ForEach-Object { Write-Host "    $($_.MainWindowTitle) (PID: $($_.Id))" -ForegroundColor Gray }
    } else {
        Write-Host "  ! No Claude Code windows found, checking PowerShell windows..." -ForegroundColor Yellow
        $psProcess = Get-Process | Where-Object { $_.MainWindowTitle -like "*PowerShell*" }
        if ($psProcess) {
            Write-Host "  ✓ Found PowerShell windows:" -ForegroundColor Green
            $psProcess | ForEach-Object { Write-Host "    $($_.MainWindowTitle) (PID: $($_.Id))" -ForegroundColor Gray }
        } else {
            Write-Host "  ✗ No suitable target windows found" -ForegroundColor Red
        }
    }
} catch {
    Write-Host "  ✗ Window detection failed: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host "" -ForegroundColor White
Write-Host "RECOMMENDATION:" -ForegroundColor Cyan
Write-Host "If no errors are detected in Unity log, try:" -ForegroundColor White
Write-Host "1. Open Unity and force recompilation (Ctrl+R)" -ForegroundColor Gray
Write-Host "2. Create a syntax error in any Unity script" -ForegroundColor Gray
Write-Host "3. Check Unity Console for actual compilation errors" -ForegroundColor Gray

Write-Host "" -ForegroundColor White
Write-Host "Press Enter to exit..." -ForegroundColor Yellow
Read-Host
# SIG # Begin signature block
# MIIFqQYJKoZIhvcNAQcCoIIFmjCCBZYCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUE0fTFW2VUpY+wzPJ7Q2l04I2
# gzagggMwMIIDLDCCAhSgAwIBAgIQdR0W2SKoK5VE8JId4ZxrRTANBgkqhkiG9w0B
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
# CQQxFgQUfCBp/1I1xEFoRXZpzWvX0ylEA7QwDQYJKoZIhvcNAQEBBQAEggEAFa1z
# LBsOhYYB6A2uZF7udSonWs57oszDv12yKZJ4Nq+MhZFRoff/+yAXqrCmFwM/75Fs
# dngZZCimppZAXjizYcbpUcb30rwPQbbuASYQAREZzKlG1yF6TuQSK7qNkWUgbEnk
# PyhlvHaL5P9MKtXQaouDN5Lyixb2M7JDwPTUmaCuEyF/myTiQvcF7oRkvh+Z+LKN
# 9Hrt8CIXgLHK7WbSF3Ob/eqMZMJ9g9W+0Oh0ui24QyajwCWjWohwUtnXjenoFC1e
# eqYTmavjq79YJotBwZMYzyFKqS6Gct6Rc7ZcTgj3pSQohcl5Mo3RJye0nz2TSsgH
# Pbn3CnC44pNPWjsPoA==
# SIG # End signature block
