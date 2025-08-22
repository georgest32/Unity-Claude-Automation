# Test-AutonomousAgentDetection.ps1
# Helper script to test if the Autonomous Agent is detecting JSON files
# Date: 2025-08-21

param(
    [Parameter()]
    [string]$TestMessage = "TEST - Manual detection test",
    
    [Parameter()]
    [switch]$CheckLogs,
    
    [Parameter()]
    [switch]$ClearOldTests
)

$ErrorActionPreference = "Continue"

Write-Host "=====================================" -ForegroundColor Cyan
Write-Host "Autonomous Agent Detection Test" -ForegroundColor Cyan
Write-Host "=====================================" -ForegroundColor Cyan
Write-Host ""

# Define paths
$responsePath = "C:\UnityProjects\Sound-and-Shoal\Unity-Claude-Automation\ClaudeResponses\Autonomous"
$logPath = "C:\UnityProjects\Sound-and-Shoal\Unity-Claude-Automation\unity_claude_automation.log"

# Clear old test files if requested
if ($ClearOldTests) {
    Write-Host "Clearing old test files..." -ForegroundColor Yellow
    Get-ChildItem -Path $responsePath -Filter "*test*.json" | Remove-Item -Force
    Write-Host "Old test files cleared" -ForegroundColor Green
    Write-Host ""
}

# Check if directory exists
if (-not (Test-Path $responsePath)) {
    Write-Host "Creating response directory: $responsePath" -ForegroundColor Yellow
    New-Item -Path $responsePath -ItemType Directory -Force | Out-Null
}

Write-Host "Response directory: $responsePath" -ForegroundColor Cyan
Write-Host "Directory exists: $(Test-Path $responsePath)" -ForegroundColor Green
Write-Host ""

# Create test JSON file
$timestamp = Get-Date -Format 'yyyyMMdd_HHmmss'
$testFileName = "manual_test_$timestamp.json"
$testFilePath = Join-Path $responsePath $testFileName

$testContent = @{
    timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss.fff'
    session_id = "manual_test_$timestamp"
    response = "RECOMMENDATION: $TestMessage"
    type = "manual_test"
    test_metadata = @{
        created_by = "Test-AutonomousAgentDetection.ps1"
        process_id = $PID
        machine_name = $env:COMPUTERNAME
        user = $env:USERNAME
    }
} | ConvertTo-Json -Depth 3

Write-Host "Creating test file: $testFileName" -ForegroundColor Yellow
try {
    # Write the file
    [System.IO.File]::WriteAllText($testFilePath, $testContent)
    Write-Host "Test file created successfully" -ForegroundColor Green
    Write-Host "Full path: $testFilePath" -ForegroundColor Gray
    
    # Verify file exists
    if (Test-Path $testFilePath) {
        $fileInfo = Get-Item $testFilePath
        Write-Host "File size: $($fileInfo.Length) bytes" -ForegroundColor Gray
        Write-Host "Created at: $($fileInfo.CreationTime)" -ForegroundColor Gray
    }
}
catch {
    Write-Host "Error creating test file: $_" -ForegroundColor Red
}

Write-Host ""
Write-Host "Waiting 5 seconds for FileSystemWatcher to detect..." -ForegroundColor Yellow
Start-Sleep -Seconds 5

# Check if .pending file was created (indicates detection)
$pendingFile = Join-Path $responsePath ".pending"
if (Test-Path $pendingFile) {
    Write-Host "SUCCESS: FileSystemWatcher detected the file!" -ForegroundColor Green
    Write-Host "Pending file exists: $pendingFile" -ForegroundColor Green
    
    # Read pending file content
    $pendingContent = Get-Content $pendingFile -ErrorAction SilentlyContinue
    Write-Host "Pending file content: $pendingContent" -ForegroundColor Gray
}
else {
    Write-Host "WARNING: No .pending file found - FileSystemWatcher may not have detected the file" -ForegroundColor Red
    Write-Host "This indicates the Autonomous Agent is not properly monitoring the directory" -ForegroundColor Yellow
}

# Check logs if requested
if ($CheckLogs) {
    Write-Host ""
    Write-Host "Checking logs for FileSystemWatcher activity..." -ForegroundColor Cyan
    
    if (Test-Path $logPath) {
        # Get recent FileWatcher entries
        $recentLogs = Get-Content $logPath -Tail 100 | Where-Object { $_ -match "FileWatcher|FSWatcher" }
        
        if ($recentLogs) {
            Write-Host "Recent FileSystemWatcher log entries:" -ForegroundColor Cyan
            $recentLogs | Select-Object -Last 10 | ForEach-Object {
                Write-Host "  $_" -ForegroundColor Gray
            }
        }
        else {
            Write-Host "No recent FileSystemWatcher entries found in logs" -ForegroundColor Yellow
        }
        
        # Check for our specific test file
        $testFileLogs = Get-Content $logPath -Tail 100 | Where-Object { $_ -match $testFileName }
        if ($testFileLogs) {
            Write-Host ""
            Write-Host "Logs mentioning our test file:" -ForegroundColor Green
            $testFileLogs | ForEach-Object {
                Write-Host "  $_" -ForegroundColor Gray
            }
        }
    }
    else {
        Write-Host "Log file not found: $logPath" -ForegroundColor Red
    }
}

Write-Host ""
Write-Host "Test complete!" -ForegroundColor Cyan
Write-Host ""
Write-Host "Next steps if detection failed:" -ForegroundColor Yellow
Write-Host "1. Check if AutonomousAgent is running: Get-Process | Where-Object { `$_.MainWindowTitle -match 'Autonomous' }" -ForegroundColor Gray
Write-Host "2. Restart the Autonomous Agent" -ForegroundColor Gray
Write-Host "3. Check Get-EventSubscriber for FileSystemWatcher events" -ForegroundColor Gray
Write-Host "4. Review full logs: Get-Content .\unity_claude_automation.log -Tail 50" -ForegroundColor Gray
# SIG # Begin signature block
# MIIFqQYJKoZIhvcNAQcCoIIFmjCCBZYCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUP/6xDDCbNJGTUWHmMelR6RBv
# GyegggMwMIIDLDCCAhSgAwIBAgIQdR0W2SKoK5VE8JId4ZxrRTANBgkqhkiG9w0B
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
# CQQxFgQU7RMarKRLuz6ZXuAy4ZoxV+U2aBAwDQYJKoZIhvcNAQEBBQAEggEAfNuZ
# p8ctkWv3Tn7bX3URKpI6LW+xSta69nHITse0V/9GGRxwcx4f+v2fiQHAXG1P3bP9
# d4yxzDiSGuGK9aqH/18oMnN7oZIo87GWIqqj9hSQu7MqEBiWMCs9KrsVM/zv+EmZ
# YuyIXbaO53BzzV24V6U5DrLyYIy677QPI12KZeyLjWn8JnUD2Hm4SrvuI2i4nsl8
# kSyvUGxt1YKkp+FqgXUKXzPOCMlnCM2HoT8OmLPaZ5NaEPpoYl5GMeytNFMJreZJ
# cQPyC0u7D0dVuXGNlOfHxxC8CDHIP/RwNbkfj4k+kB+oJn2/TWBS9+F0gNPZL6RF
# TvJRV7S5HZYTOaKyVg==
# SIG # End signature block
