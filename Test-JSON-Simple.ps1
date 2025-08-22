# Test-JSON-Simple.ps1
# Simple test for ConsoleErrorExporter JSON monitoring
# ASCII only, PowerShell 5.1 compatible
# Date: 2025-08-18

Set-Location "C:\UnityProjects\Sound-and-Shoal\Unity-Claude-Automation"

Write-Host "TESTING CONSOLE EXPORTER JSON" -ForegroundColor Cyan
Write-Host "==============================" -ForegroundColor Cyan

$jsonPath = "C:\UnityProjects\Sound-and-Shoal\AutomationLogs\current_errors.json"
Write-Host "Checking: $jsonPath" -ForegroundColor White

if (Test-Path $jsonPath) {
    $fileInfo = Get-Item $jsonPath
    Write-Host "File exists" -ForegroundColor Green
    Write-Host "Size: $($fileInfo.Length) bytes" -ForegroundColor Gray
    Write-Host "Modified: $($fileInfo.LastWriteTime)" -ForegroundColor Gray
    
    $content = Get-Content $jsonPath -Raw
    Write-Host "Content:" -ForegroundColor Gray
    Write-Host $content -ForegroundColor DarkGray
    
    $jsonData = $content | ConvertFrom-Json
    if ($jsonData.errors) {
        Write-Host "Found $($jsonData.errors.Count) errors in JSON" -ForegroundColor Green
        foreach ($error in $jsonData.errors) {
            Write-Host "  Error: $($error.message)" -ForegroundColor Red
        }
    } else {
        Write-Host "No errors in JSON" -ForegroundColor Yellow
    }
    
} else {
    Write-Host "JSON file does not exist" -ForegroundColor Red
    Write-Host "ConsoleErrorExporter may not be running" -ForegroundColor Yellow
}

Write-Host "" -ForegroundColor White
Write-Host "Now testing updated autonomous monitoring..." -ForegroundColor Yellow

Import-Module ".\Modules\Unity-Claude-CLISubmission.psm1" -Force

$testCallback = {
    param($errors)
    Write-Host "AUTONOMOUS SYSTEM TRIGGERED!" -ForegroundColor Green
    Write-Host "Detected $($errors.Count) errors:" -ForegroundColor Green
    foreach ($error in $errors) {
        Write-Host "  $error" -ForegroundColor Red
    }
}

$monitorResult = Start-UnityErrorMonitoring -OnErrorDetected $testCallback

if ($monitorResult.Success) {
    Write-Host "Monitoring started - Job ID: $($monitorResult.JobId)" -ForegroundColor Green
    Write-Host "Create Unity errors now and watch for detection!" -ForegroundColor Cyan
    
    Write-Host "Waiting 20 seconds for activity..." -ForegroundColor Yellow
    for ($i = 0; $i -lt 20; $i++) {
        Start-Sleep 1
        Write-Host "." -NoNewline -ForegroundColor Gray
    }
    
    Stop-UnityErrorMonitoring
    Write-Host "" -ForegroundColor White
    Write-Host "Test complete" -ForegroundColor Green
} else {
    Write-Host "Failed to start monitoring: $($monitorResult.Error)" -ForegroundColor Red
}

Write-Host "" -ForegroundColor White
Write-Host "Press Enter to exit..." -ForegroundColor Yellow
Read-Host
# SIG # Begin signature block
# MIIFqQYJKoZIhvcNAQcCoIIFmjCCBZYCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUo3RUavrnL2S+lxIzkInYNnav
# dgugggMwMIIDLDCCAhSgAwIBAgIQdR0W2SKoK5VE8JId4ZxrRTANBgkqhkiG9w0B
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
# CQQxFgQUj8IB8Wir3TQxPwPMsdE+PTmY+DowDQYJKoZIhvcNAQEBBQAEggEAqWka
# siuYz4zNEbo79YdgxCQyQLCzxHdtd2D9OyXehbcT+P5DkO4hdzfwegBAEVu4hII2
# FamdKe1ZpJgyvgenCKWDxPN9rOHeQouf3B+/CgF4UDsZtnCnmXwgdMKObijzUGj6
# 71y2V4tiDwat3HcXt+HZTUXH2/ni3hx/jibtHLMC/SLxBudSQutEJpVhyemvYF1L
# z+DLKAmX+XHsFf9eSI75vkV/ZvJ8kyTeBVAo1gMwEBr53gh3G66seW5DvnFnWb3c
# r0SyHuSI9tsS5QXUDD7kSUROINRY0NcOjoeP+V75jqv4yMRdcZJj+qvCJe55UfzJ
# PHh9CywN1wGLYN265Q==
# SIG # End signature block
