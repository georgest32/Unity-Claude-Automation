# Test-MonitoringSimple.ps1
# Simple test to verify the ReliableMonitoring system detects the Unity errors
# Date: 2025-08-18

Set-Location "C:\UnityProjects\Sound-and-Shoal\Unity-Claude-Automation"

Write-Host "TESTING RELIABLE MONITORING SYSTEM" -ForegroundColor Cyan
Write-Host "===================================" -ForegroundColor Cyan

# Import the module
Import-Module ".\Modules\Unity-Claude-ReliableMonitoring.psm1" -Force

# Check if Unity JSON file exists and has errors
$unityErrorPath = "C:\UnityProjects\Sound-and-Shoal\Unity-Claude-Automation\unity_errors_safe.json"
Write-Host "Checking Unity error file..." -ForegroundColor Yellow

if (Test-Path $unityErrorPath) {
    $fileInfo = Get-Item $unityErrorPath
    Write-Host "[+] Unity error file exists" -ForegroundColor Green
    Write-Host "    Modified: $($fileInfo.LastWriteTime)" -ForegroundColor Gray
    Write-Host "    Size: $($fileInfo.Length) bytes" -ForegroundColor Gray
    
    try {
        $content = Get-Content $unityErrorPath -Raw
        $errorData = $content | ConvertFrom-Json
        Write-Host "    Total errors: $($errorData.totalErrors)" -ForegroundColor Yellow
        
        if ($errorData.errors) {
            foreach ($error in $errorData.errors) {
                Write-Host "    ERROR: $($error.message)" -ForegroundColor Red
            }
        }
    } catch {
        Write-Host "    [-] Error reading JSON: $($_.Exception.Message)" -ForegroundColor Red
    }
} else {
    Write-Host "[-] Unity error file not found" -ForegroundColor Red
    Write-Host "    Expected: $unityErrorPath" -ForegroundColor Gray
}

# Test callback
$testCallback = {
    param($errors)
    Write-Host "" -ForegroundColor White
    Write-Host "[>] MONITORING CALLBACK TRIGGERED!" -ForegroundColor Green
    Write-Host "===================================" -ForegroundColor Green
    Write-Host "Detected $($errors.Count) Unity errors:" -ForegroundColor Yellow
    
    foreach ($error in $errors) {
        Write-Host "  ERROR: $error" -ForegroundColor Red
    }
    Write-Host "===================================" -ForegroundColor Green
}

# Start monitoring
Write-Host "" -ForegroundColor White
Write-Host "Starting reliable monitoring..." -ForegroundColor Yellow
$monitorResult = Start-ReliableUnityMonitoring -OnErrorDetected $testCallback

if ($monitorResult.Success) {
    Write-Host "[+] Monitoring started successfully!" -ForegroundColor Green
    Write-Host "    Method: $($monitorResult.Method)" -ForegroundColor Gray
    Write-Host "    FileWatcher: $($monitorResult.FileWatcher)" -ForegroundColor Gray
    Write-Host "    Polling: $($monitorResult.Polling)" -ForegroundColor Gray
    
    # Get monitoring status
    Write-Host "" -ForegroundColor White
    Write-Host "Current monitoring status:" -ForegroundColor Yellow
    $status = Get-ReliableMonitoringStatus
    Write-Host "    FileWatcherActive: $($status.FileWatcherActive)" -ForegroundColor Gray
    Write-Host "    PollingActive: $($status.PollingActive)" -ForegroundColor Gray
    Write-Host "    EventSubscriptions: $($status.EventSubscriptions)" -ForegroundColor Gray
    Write-Host "    LastErrorCount: $($status.LastErrorCount)" -ForegroundColor Gray
    
    Write-Host "" -ForegroundColor White
    Write-Host "TESTING INSTRUCTIONS:" -ForegroundColor Cyan
    Write-Host "1. Keep this window open" -ForegroundColor White
    Write-Host "2. Go to Unity and create/save a syntax error" -ForegroundColor White
    Write-Host "3. Watch for callback activity here" -ForegroundColor White
    Write-Host "4. Or manually trigger by updating the JSON file timestamp" -ForegroundColor White
    
    Write-Host "" -ForegroundColor White
    Write-Host "Monitoring for 60 seconds..." -ForegroundColor Yellow
    
    for ($i = 60; $i -gt 0; $i--) {
        Write-Host "." -NoNewline -ForegroundColor Gray
        Start-Sleep 1
        
        # Check for manual trigger test
        if ($i -eq 50) {
            Write-Host "" -ForegroundColor White
            Write-Host "[TEST] Manually updating JSON timestamp to trigger detection..." -ForegroundColor Magenta
            if (Test-Path $unityErrorPath) {
                (Get-Item $unityErrorPath).LastWriteTime = Get-Date
            }
        }
    }
    
    # Stop monitoring
    Write-Host "" -ForegroundColor White
    Write-Host "Stopping monitoring..." -ForegroundColor Yellow
    Stop-ReliableUnityMonitoring
    Write-Host "[+] Monitoring stopped" -ForegroundColor Green
    
} else {
    Write-Host "[-] Failed to start monitoring: $($monitorResult.Error)" -ForegroundColor Red
}

Write-Host "" -ForegroundColor White
Write-Host "Test complete. Press Enter to exit..." -ForegroundColor Yellow
Read-Host
# SIG # Begin signature block
# MIIFqQYJKoZIhvcNAQcCoIIFmjCCBZYCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUTMOBX1E12YLsz9RMIAESZz8s
# lGGgggMwMIIDLDCCAhSgAwIBAgIQdR0W2SKoK5VE8JId4ZxrRTANBgkqhkiG9w0B
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
# CQQxFgQUBId6Cf7iI3MQ+AAwlP+aGhcsdzIwDQYJKoZIhvcNAQEBBQAEggEAZeuM
# u+28NiYTHLPRPmm0EZYe2Ldz7qDg3yyr0j+UauK02GByjxMpI4WeNnpqsHGOizcQ
# jyeb4O0q4zgckOjPBUA0bikPh97JOxxc3rY74P6HPHTbRN2lS0XDuz+867E8axBu
# pV2b5t6vEZJiQa9WaXa3tuWz5QBzJ3fJC1cMrGF9sNW9hXTgWVxnNKWTA9d+UShF
# qsdI70CHLuUaBE2OB50ZHGqiO4Rg8yaQ/4p/C49PpZ742ITnMHtdj6QVq1N52KhG
# OjGl3k1DjB8TO2sEOaA9R09OhsZ2QBAVODWlBMgUnbtavnlDVtswT3+4WL/b/hD0
# HmfWUjCgjFGI2FZAyQ==
# SIG # End signature block
