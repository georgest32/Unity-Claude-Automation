# Test-FileWatcherDetection.ps1
# Tests why FileSystemWatcher isn't detecting files created by Claude Code
# Date: 2025-08-21

Write-Host ""
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "TESTING FILEWATCHER DETECTION" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host ""

$targetDir = "C:\UnityProjects\Sound-and-Shoal\Unity-Claude-Automation\ClaudeResponses\Autonomous"

Write-Host "Target directory: $targetDir" -ForegroundColor Yellow
Write-Host ""

# Method 1: Using Set-Content (PowerShell native)
Write-Host "Test 1: Creating file with Set-Content..." -ForegroundColor Cyan
$testFile1 = Join-Path $targetDir "test_detection_setcontent_$(Get-Date -Format 'HHmmss').json"
$content1 = @{
    test = "Set-Content method"
    timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss.fff'
} | ConvertTo-Json
Set-Content -Path $testFile1 -Value $content1 -Encoding UTF8
Write-Host "  Created: $(Split-Path $testFile1 -Leaf)" -ForegroundColor Green
Start-Sleep -Seconds 2

# Method 2: Using Out-File
Write-Host ""
Write-Host "Test 2: Creating file with Out-File..." -ForegroundColor Cyan
$testFile2 = Join-Path $targetDir "test_detection_outfile_$(Get-Date -Format 'HHmmss').json"
$content2 = @{
    test = "Out-File method"
    timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss.fff'
} | ConvertTo-Json
$content2 | Out-File -FilePath $testFile2 -Encoding UTF8
Write-Host "  Created: $(Split-Path $testFile2 -Leaf)" -ForegroundColor Green
Start-Sleep -Seconds 2

# Method 3: Using .NET File.WriteAllText (what Claude Code might use)
Write-Host ""
Write-Host "Test 3: Creating file with [System.IO.File]::WriteAllText..." -ForegroundColor Cyan
$testFile3 = Join-Path $targetDir "test_detection_dotnet_$(Get-Date -Format 'HHmmss').json"
$content3 = @{
    test = ".NET WriteAllText method"
    timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss.fff'
} | ConvertTo-Json
[System.IO.File]::WriteAllText($testFile3, $content3)
Write-Host "  Created: $(Split-Path $testFile3 -Leaf)" -ForegroundColor Green
Start-Sleep -Seconds 2

# Method 4: Using Add-Content (incremental write)
Write-Host ""
Write-Host "Test 4: Creating file with Add-Content..." -ForegroundColor Cyan
$testFile4 = Join-Path $targetDir "test_detection_addcontent_$(Get-Date -Format 'HHmmss').json"
$content4 = @{
    test = "Add-Content method"
    timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss.fff'
} | ConvertTo-Json
Add-Content -Path $testFile4 -Value $content4 -Encoding UTF8
Write-Host "  Created: $(Split-Path $testFile4 -Leaf)" -ForegroundColor Green
Start-Sleep -Seconds 2

# Method 5: Create then modify (trigger both events)
Write-Host ""
Write-Host "Test 5: Create empty then write content..." -ForegroundColor Cyan
$testFile5 = Join-Path $targetDir "test_detection_twostep_$(Get-Date -Format 'HHmmss').json"
# Create empty
New-Item -Path $testFile5 -ItemType File -Force | Out-Null
Write-Host "  Created empty: $(Split-Path $testFile5 -Leaf)" -ForegroundColor Yellow
Start-Sleep -Milliseconds 500
# Write content
$content5 = @{
    test = "Two-step creation method"
    timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss.fff'
} | ConvertTo-Json
Set-Content -Path $testFile5 -Value $content5 -Encoding UTF8
Write-Host "  Wrote content: $(Split-Path $testFile5 -Leaf)" -ForegroundColor Green
Start-Sleep -Seconds 2

# Check the log for FileWatcher events
Write-Host ""
Write-Host "Checking log for FileWatcher events..." -ForegroundColor Cyan
$logPath = "C:\UnityProjects\Sound-and-Shoal\Unity-Claude-Automation\unity_claude_automation.log"
if (Test-Path $logPath) {
    $recentLogs = Get-Content $logPath -Tail 100 | Where-Object { $_ -like "*FileWatcher*" -and $_ -like "*test_detection*" }
    if ($recentLogs) {
        Write-Host "  Found FileWatcher events:" -ForegroundColor Green
        $recentLogs | ForEach-Object {
            Write-Host "    $_" -ForegroundColor Gray
        }
    } else {
        Write-Host "  No FileWatcher events found for test files!" -ForegroundColor Red
    }
} else {
    Write-Host "  Log file not found!" -ForegroundColor Red
}

Write-Host ""
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "TEST COMPLETE" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Check the AutonomousAgent window to see if any files were detected." -ForegroundColor Yellow
Write-Host ""
Write-Host "Files created:" -ForegroundColor Cyan
Write-Host "  1. $testFile1" -ForegroundColor Gray
Write-Host "  2. $testFile2" -ForegroundColor Gray
Write-Host "  3. $testFile3" -ForegroundColor Gray
Write-Host "  4. $testFile4" -ForegroundColor Gray
Write-Host "  5. $testFile5" -ForegroundColor Gray
# SIG # Begin signature block
# MIIFqQYJKoZIhvcNAQcCoIIFmjCCBZYCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUUXTcnDcWqzvlBRnVatqjz9SN
# pkygggMwMIIDLDCCAhSgAwIBAgIQdR0W2SKoK5VE8JId4ZxrRTANBgkqhkiG9w0B
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
# CQQxFgQUuzgvKuEKi1iROmmjwp67o4CZv2cwDQYJKoZIhvcNAQEBBQAEggEAkVCh
# LhYBSjTDaT8Lz2y08S7P6jdVF8kTGYouEw0Q4qIK9VtJ6Ayx85Ess7SkCMQMezi5
# tQBJfeRX+mgCa+00lS77CdjBL19WXoPZf7C6eOCI3AuB3WpaEyUu0QQHiysPPJhm
# sI7/baFvDi/+hw8AxdrOumWb4I5xQTq6IMdI84+0o0mD96H+uGZrhJWqLwaGSDLh
# mcoSDhcO0manSbyVAuBthJ9n1bBVCIJxia3cdeSpQBzQ9ahw92XLoOzQy6PKnfgX
# Z9N3a5BVftOsuamlQATluC1MesmEfLpt7UkrPVJjG60dgyUHrS+/X69xJOPcbLPT
# vyeR0PqPVQMKIWdgMA==
# SIG # End signature block
