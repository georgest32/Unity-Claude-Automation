# Test-ConsoleExporter.ps1
# Test monitoring the existing ConsoleErrorExporter JSON file
# Date: 2025-08-18

Set-Location "C:\UnityProjects\Sound-and-Shoal\Unity-Claude-Automation"

Write-Host "TESTING UNITY CONSOLE EXPORTER MONITORING" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan

$jsonPath = "C:\UnityProjects\Sound-and-Shoal\AutomationLogs\current_errors.json"

Write-Host "JSON file path: $jsonPath" -ForegroundColor White

# Check if file exists
if (Test-Path $jsonPath) {
    $fileInfo = Get-Item $jsonPath
    Write-Host "✓ File exists" -ForegroundColor Green
    Write-Host "  Size: $($fileInfo.Length) bytes" -ForegroundColor Gray
    Write-Host "  Modified: $($fileInfo.LastWriteTime)" -ForegroundColor Gray
    
    # Read current content
    try {
        $content = Get-Content $jsonPath -Raw
        Write-Host "  Content preview:" -ForegroundColor Gray
        Write-Host $content.Substring(0, [Math]::Min(300, $content.Length)) -ForegroundColor DarkGray
        
        # Try to parse JSON
        $jsonData = $content | ConvertFrom-Json
        if ($jsonData.errors) {
            Write-Host "  ✓ Contains $($jsonData.errors.Count) errors" -ForegroundColor Green
        } else {
            Write-Host "  ! No errors in JSON structure" -ForegroundColor Yellow
        }
    } catch {
        Write-Host "  ✗ Error reading file: $($_.Exception.Message)" -ForegroundColor Red
    }
} else {
    Write-Host "✗ JSON file does not exist" -ForegroundColor Red
    Write-Host "  The ConsoleErrorExporter may not be running" -ForegroundColor Yellow
    Write-Host "  Check if Unity is open with the ConsoleErrorExporter script" -ForegroundColor Yellow
}

# Test the updated monitoring
Write-Host "" -ForegroundColor White
Write-Host "Testing updated autonomous monitoring..." -ForegroundColor Yellow

Import-Module ".\Modules\Unity-Claude-CLISubmission.psm1" -Force

# Test monitoring setup
$testCallback = {
    param($errors)
    Write-Host "CALLBACK TRIGGERED with $($errors.Count) errors:" -ForegroundColor Green
    foreach ($error in $errors) {
        Write-Host "  $error" -ForegroundColor Red
    }
}

Write-Host "Starting monitoring test..." -ForegroundColor Yellow
$monitorResult = Start-UnityErrorMonitoring -OnErrorDetected $testCallback

if ($monitorResult.Success) {
    Write-Host "✓ Monitoring started successfully" -ForegroundColor Green
    Write-Host "  Job ID: $($monitorResult.JobId)" -ForegroundColor Gray
    
    Write-Host "" -ForegroundColor White
    Write-Host "Now:" -ForegroundColor Cyan
    Write-Host "1. Open Unity" -ForegroundColor White
    Write-Host "2. Create a syntax error in any C# script" -ForegroundColor White
    Write-Host "3. Save the file" -ForegroundColor White
    Write-Host "4. Watch for monitoring activity!" -ForegroundColor White
    
    Write-Host "" -ForegroundColor White
    Write-Host "Monitoring for 30 seconds..." -ForegroundColor Yellow
    
    for ($i = 30; $i -gt 0; $i--) {
        Write-Host "." -NoNewline -ForegroundColor Gray
        Start-Sleep 1
        
        # Check job output
        $job = Get-Job -Id $monitorResult.JobId -ErrorAction SilentlyContinue
        if ($job -and $job.HasMoreData) {
            $output = Receive-Job $job -Keep
            if ($output) {
                Write-Host "" -ForegroundColor White
                Write-Host "Job output:" -ForegroundColor Cyan
                $output | ForEach-Object { Write-Host "  $_" -ForegroundColor Gray }
            }
        }
    }
    
    # Clean up
    Stop-UnityErrorMonitoring
    Write-Host "" -ForegroundColor White
    Write-Host "✓ Monitoring test complete" -ForegroundColor Green
    
} else {
    Write-Host "✗ Failed to start monitoring: $($monitorResult.Error)" -ForegroundColor Red
}

Write-Host "" -ForegroundColor White
Write-Host "Press Enter to exit..." -ForegroundColor Yellow
Read-Host
# SIG # Begin signature block
# MIIFqQYJKoZIhvcNAQcCoIIFmjCCBZYCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUxr1kObbgnNhUBbPH08CKdxol
# fWCgggMwMIIDLDCCAhSgAwIBAgIQdR0W2SKoK5VE8JId4ZxrRTANBgkqhkiG9w0B
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
# CQQxFgQUu5cdAHtz3xXGxnrj5WtEtTRCyaMwDQYJKoZIhvcNAQEBBQAEggEAM1vw
# R3DL0hm3J/+Zu595NROciXDs+d3jxpNk4sV6rf/CCVzLurZY7mkkypMV7iPWSzVH
# x/+uRSCzUxCarjtgYS1OZQTsgXgN7K+lkoo+8uq7Q2WXeRcYiCppKs0R2qWbmFo1
# Kq1o8aCcdFNikSPTcTLF2F9TiwlhgC6c/dVUhSUwr+M6OPzzww2iJRLXKCjP89s0
# D37BW7n/4Ael8VSilFYdO8i6+ORU7h1LN6zr5Ik5E/qRPHxNBQIlZjq3PsiSlhBL
# d8UuNZxEuNNGKvaIrsVeeClsViCXXIJK5eL/EEqL2jUn5+edw3qvZ+u/hW79aimr
# V18dd6X3olG5LHSitg==
# SIG # End signature block
