# Diagnose-AutonomousSystem.ps1
# Quick diagnostic script to check autonomous system status
# Date: 2025-08-18

Set-Location "C:\UnityProjects\Sound-and-Shoal\Unity-Claude-Automation"

Write-Host "AUTONOMOUS SYSTEM DIAGNOSTIC" -ForegroundColor Cyan
Write-Host "============================" -ForegroundColor Cyan

# Check 1: Unity error file
Write-Host "" -ForegroundColor White
Write-Host "1. Unity Error Export Status:" -ForegroundColor Yellow
$safeExportPath = ".\unity_errors_safe.json"

if (Test-Path $safeExportPath) {
    $fileInfo = Get-Item $safeExportPath
    $content = Get-Content $safeExportPath | ConvertFrom-Json
    
    Write-Host "  [+] File exists: $safeExportPath" -ForegroundColor Green
    Write-Host "    Last modified: $($fileInfo.LastWriteTime)" -ForegroundColor Gray
    Write-Host "    Size: $($fileInfo.Length) bytes" -ForegroundColor Gray
    Write-Host "    Total errors: $($content.totalErrors)" -ForegroundColor Gray
    Write-Host "    Is compiling: $($content.isCompiling)" -ForegroundColor Gray
    
    if ($content.totalErrors -gt 0) {
        Write-Host "  [!] Unity has $($content.totalErrors) active errors:" -ForegroundColor Yellow
        foreach ($error in $content.errors) {
            Write-Host "    - $($error.message)" -ForegroundColor Red
        }
    } else {
        Write-Host "  [+] No Unity errors detected" -ForegroundColor Green
    }
} else {
    Write-Host "  [-] Unity error file not found!" -ForegroundColor Red
    Write-Host "    Expected: $safeExportPath" -ForegroundColor Gray
    Write-Host "    Make sure Unity is open with SafeConsoleExporter.cs active" -ForegroundColor Yellow
}

# Check 2: Claude response file
Write-Host "" -ForegroundColor White
Write-Host "2. Claude Response File Status:" -ForegroundColor Yellow
$responsePath = ".\claude_responses.json"

if (Test-Path $responsePath) {
    $responseInfo = Get-Item $responsePath
    $responseContent = Get-Content $responsePath | ConvertFrom-Json
    
    Write-Host "  [+] File exists: $responsePath" -ForegroundColor Green
    Write-Host "    Last modified: $($responseInfo.LastWriteTime)" -ForegroundColor Gray
    Write-Host "    Total responses: $($responseContent.totalResponses)" -ForegroundColor Gray
    Write-Host "    Last session: $($responseContent.lastSessionId)" -ForegroundColor Gray
} else {
    Write-Host "  [!] Claude response file not found" -ForegroundColor Yellow
    Write-Host "    Expected: $responsePath" -ForegroundColor Gray
    Write-Host "    This file is created when Claude responses are exported" -ForegroundColor Gray
}

# Check 3: Module availability
Write-Host "" -ForegroundColor White
Write-Host "3. Required Modules Status:" -ForegroundColor Yellow

$requiredModules = @(
    "Unity-Claude-ReliableMonitoring.psm1",
    "Unity-Claude-CLISubmission.psm1", 
    "Unity-Claude-ResponseMonitoring.psm1"
)

foreach ($module in $requiredModules) {
    $modulePath = ".\Modules\$module"
    if (Test-Path $modulePath) {
        Write-Host "  [+] $module - Available" -ForegroundColor Green
    } else {
        Write-Host "  [-] $module - Missing!" -ForegroundColor Red
    }
}

# Check 4: Running processes
Write-Host "" -ForegroundColor White
Write-Host "4. PowerShell Processes:" -ForegroundColor Yellow

$psProcesses = Get-Process | Where-Object { 
    $_.ProcessName -like "*powershell*" -or 
    $_.ProcessName -like "*pwsh*" -or
    $_.ProcessName -like "*WindowsTerminal*"
}

if ($psProcesses) {
    Write-Host "  [+] Found $($psProcesses.Count) relevant processes:" -ForegroundColor Green
    foreach ($proc in $psProcesses) {
        Write-Host "    - $($proc.ProcessName) (PID: $($proc.Id)) - $($proc.MainWindowTitle)" -ForegroundColor Gray
    }
} else {
    Write-Host "  [!] No PowerShell processes found" -ForegroundColor Yellow
}

# Check 5: File monitoring test
Write-Host "" -ForegroundColor White
Write-Host "5. File Monitoring Test:" -ForegroundColor Yellow

try {
    # Try to load the monitoring module
    Import-Module ".\Modules\Unity-Claude-ReliableMonitoring.psm1" -Force -ErrorAction Stop
    Write-Host "  [+] Unity monitoring module loaded successfully" -ForegroundColor Green
    
    # Test callback
    $testCallback = {
        param($errors)
        Write-Host "  [>] TEST CALLBACK TRIGGERED! Detected $($errors.Count) errors" -ForegroundColor Cyan
    }
    
    Write-Host "  [+] Testing monitoring startup..." -ForegroundColor Yellow
    $monitorResult = Start-ReliableUnityMonitoring -OnErrorDetected $testCallback
    
    if ($monitorResult.Success) {
        Write-Host "  [+] Monitoring started successfully!" -ForegroundColor Green
        Write-Host "    Method: $($monitorResult.Method)" -ForegroundColor Gray
        Write-Host "    FileWatcher: $($monitorResult.FileWatcher)" -ForegroundColor Gray
        Write-Host "    Polling: $($monitorResult.Polling)" -ForegroundColor Gray
        
        Write-Host "  [+] Testing for 10 seconds..." -ForegroundColor Yellow
        for ($i = 10; $i -gt 0; $i--) {
            Write-Host "." -NoNewline -ForegroundColor Gray
            Start-Sleep 1
        }
        
        Write-Host "" -ForegroundColor White
        Write-Host "  [+] Stopping test monitoring..." -ForegroundColor Yellow
        Stop-ReliableUnityMonitoring
        Write-Host "  [+] Test monitoring stopped" -ForegroundColor Green
        
    } else {
        Write-Host "  [-] Monitoring failed to start: $($monitorResult.Error)" -ForegroundColor Red
    }
    
} catch {
    Write-Host "  [-] Error testing monitoring: $($_.Exception.Message)" -ForegroundColor Red
}

# Check 6: Autonomous system status
Write-Host "" -ForegroundColor White
Write-Host "6. Current Autonomous System Status:" -ForegroundColor Yellow

# Check if autonomous system is running by looking for session files
$sessionPath = ".\SessionData\Sessions"
if (Test-Path $sessionPath) {
    $sessionFiles = Get-ChildItem $sessionPath -Filter "*.json" | Sort-Object LastWriteTime -Descending | Select-Object -First 5
    if ($sessionFiles) {
        Write-Host "  [+] Found $($sessionFiles.Count) recent session files:" -ForegroundColor Green
        foreach ($session in $sessionFiles) {
            Write-Host "    - $($session.Name) (Modified: $($session.LastWriteTime))" -ForegroundColor Gray
        }
    } else {
        Write-Host "  [!] No session files found - system may not be running" -ForegroundColor Yellow
    }
} else {
    Write-Host "  [!] Session directory not found" -ForegroundColor Yellow
}

# Summary and recommendations
Write-Host "" -ForegroundColor White
Write-Host "RECOMMENDATIONS:" -ForegroundColor Cyan
Write-Host "================" -ForegroundColor Cyan

if (Test-Path $safeExportPath) {
    $errorContent = Get-Content $safeExportPath | ConvertFrom-Json
    if ($errorContent.totalErrors -gt 0) {
        Write-Host "[!] Unity has active errors - autonomous system should be detecting these!" -ForegroundColor Yellow
        Write-Host "    To start the autonomous system:" -ForegroundColor White
        Write-Host "    1. Open a new PowerShell window" -ForegroundColor Gray
        Write-Host "    2. Run: .\Start-ImprovedAutonomy-Fixed.ps1" -ForegroundColor Gray
        Write-Host "    3. Wait for system to detect Unity errors" -ForegroundColor Gray
        Write-Host "    4. Watch for autonomous prompt submission to Claude Code CLI" -ForegroundColor Gray
    } else {
        Write-Host "[+] No Unity errors to process - create a test error to trigger the system" -ForegroundColor Green
        Write-Host "    Run: .\Test-CompleteFeedbackLoop.ps1" -ForegroundColor Gray
    }
} else {
    Write-Host "[!] Unity SafeConsoleExporter not working" -ForegroundColor Red
    Write-Host "    1. Make sure Unity is open" -ForegroundColor Gray
    Write-Host "    2. Ensure SafeConsoleExporter.cs is in the project" -ForegroundColor Gray
    Write-Host "    3. Check Unity console for SafeConsoleExporter messages" -ForegroundColor Gray
}

Write-Host "" -ForegroundColor White
Write-Host "Diagnosis complete. Press Enter to exit..." -ForegroundColor Yellow
Read-Host
# SIG # Begin signature block
# MIIFqQYJKoZIhvcNAQcCoIIFmjCCBZYCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUv0IAKf9LDMaBlq9ByNIq3pn3
# qCKgggMwMIIDLDCCAhSgAwIBAgIQdR0W2SKoK5VE8JId4ZxrRTANBgkqhkiG9w0B
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
# CQQxFgQU3oipuhT8tWV09InKmjrYcc8dxCIwDQYJKoZIhvcNAQEBBQAEggEAUvWm
# Y6IORNTPz9Cle8YNhrdE/lpxRxrrbJ0yi47p2OI05I7QHi7Sa5MKktOBGUh5m7fO
# OGAW2UUaMOEFxO4a8dhOl2Ym7Rpdw2FdRMtlY09IXhlV1gyEgutzD7tyLCMMkl4B
# Z1JgfklxlaiBR8PHs5kbn0HNB1x8+WrwO5CEge192Y2YYcug0/OTMt2bsiYVs+Xb
# CvWjpvZQqIWYbS7d+8WuRx5IAQbJxoG8svXerABBjNPQGz6JxO0MgMjN7EoGNJw5
# ZG+JgslQRLpt+2mc0kZBfnODXWC6ku22Sd5NTDLQw+ej6p/rNqHuyEb+uZNd1MNo
# 2s+JBBOIyoGPwPrkDQ==
# SIG # End signature block
