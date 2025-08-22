# Test-FileMonitoring.ps1
# Test if file monitoring is working properly
# Date: 2025-08-18

Set-Location "C:\UnityProjects\Sound-and-Shoal\Unity-Claude-Automation"

Write-Host "TESTING FILE MONITORING SYSTEM" -ForegroundColor Cyan
Write-Host "===============================" -ForegroundColor Cyan

try {
    # Load the monitoring module
    Import-Module ".\Modules\Unity-Claude-ReliableMonitoring.psm1" -Force
    Write-Host "[+] Loaded Unity monitoring module" -ForegroundColor Green
    
    # Create test callback
    $callbackTriggered = $false
    $testCallback = {
        param($errors)
        $global:callbackTriggered = $true
        Write-Host "" -ForegroundColor White
        Write-Host "[>] CALLBACK TRIGGERED!" -ForegroundColor Green
        Write-Host "====================================" -ForegroundColor Green
        Write-Host "Detected $($errors.Count) errors:" -ForegroundColor Yellow
        foreach ($error in $errors) {
            Write-Host "  - $error" -ForegroundColor Red
        }
        Write-Host "====================================" -ForegroundColor Green
    }
    
    # Start monitoring
    Write-Host "[+] Starting file monitoring..." -ForegroundColor Yellow
    $monitorResult = Start-ReliableUnityMonitoring -OnErrorDetected $testCallback
    
    if ($monitorResult.Success) {
        Write-Host "[+] Monitoring started successfully!" -ForegroundColor Green
        Write-Host "  Method: $($monitorResult.Method)" -ForegroundColor Gray
        Write-Host "  FileWatcher: $($monitorResult.FileWatcher)" -ForegroundColor Gray
        Write-Host "  Polling: $($monitorResult.Polling)" -ForegroundColor Gray
        
        Write-Host "" -ForegroundColor White
        Write-Host "Now I'll modify the Unity error file to trigger detection..." -ForegroundColor Yellow
        Start-Sleep 2
        
        # Modify the file to trigger detection
        $errorFile = ".\unity_errors_safe.json"
        if (Test-Path $errorFile) {
            $content = Get-Content $errorFile | ConvertFrom-Json
            $content.exportTime = Get-Date -Format "yyyy-MM-dd HH:mm:ss.fff"
            
            # Add timestamp to trigger detection
            $content.testTrigger = Get-Date -Format "yyyy-MM-dd HH:mm:ss.fff"
            
            $json = $content | ConvertTo-Json -Depth 4
            [System.IO.File]::WriteAllText($errorFile, $json, [System.Text.Encoding]::UTF8)
            
            Write-Host "[+] Modified error file at $(Get-Date -Format 'HH:mm:ss')" -ForegroundColor Green
            
            # Wait for detection
            Write-Host "[+] Waiting 15 seconds for callback..." -ForegroundColor Yellow
            for ($i = 15; $i -gt 0; $i--) {
                if ($global:callbackTriggered) {
                    Write-Host "" -ForegroundColor White
                    Write-Host "[SUCCESS] File monitoring is working!" -ForegroundColor Green
                    break
                }
                Write-Host "." -NoNewline -ForegroundColor Gray
                Start-Sleep 1
            }
            
            if (-not $global:callbackTriggered) {
                Write-Host "" -ForegroundColor White
                Write-Host "[WARNING] Callback was not triggered within 15 seconds" -ForegroundColor Yellow
                Write-Host "This suggests the file monitoring may not be working properly" -ForegroundColor Red
                
                # Try manual trigger
                Write-Host "[+] Attempting manual callback trigger..." -ForegroundColor Yellow
                & $testCallback @("Manual test error")
            }
            
        } else {
            Write-Host "[-] Unity error file not found" -ForegroundColor Red
        }
        
        # Stop monitoring
        Write-Host "" -ForegroundColor White
        Write-Host "[+] Stopping monitoring..." -ForegroundColor Yellow
        Stop-ReliableUnityMonitoring
        Write-Host "[+] Monitoring stopped" -ForegroundColor Green
        
    } else {
        Write-Host "[-] Failed to start monitoring: $($monitorResult.Error)" -ForegroundColor Red
    }
    
} catch {
    Write-Host "[-] Error during test: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host "" -ForegroundColor White
Write-Host "DIAGNOSIS:" -ForegroundColor Cyan
if ($global:callbackTriggered) {
    Write-Host "[+] File monitoring system is working correctly" -ForegroundColor Green
    Write-Host "If your autonomous system isn't responding, check:" -ForegroundColor Yellow
    Write-Host "  1. Is the autonomous system using the same monitoring approach?" -ForegroundColor Gray
    Write-Host "  2. Are there any errors in the autonomous system console?" -ForegroundColor Gray
    Write-Host "  3. Is the Unity error file being updated with new timestamps?" -ForegroundColor Gray
} else {
    Write-Host "[-] File monitoring system is not working" -ForegroundColor Red
    Write-Host "Possible issues:" -ForegroundColor Yellow
    Write-Host "  1. FileSystemWatcher permissions" -ForegroundColor Gray
    Write-Host "  2. File locking by other processes" -ForegroundColor Gray
    Write-Host "  3. Polling interval too long" -ForegroundColor Gray
    Write-Host "  4. Module loading issues" -ForegroundColor Gray
}

Write-Host "" -ForegroundColor White
Write-Host "Press Enter to exit..." -ForegroundColor Gray
Read-Host
# SIG # Begin signature block
# MIIFqQYJKoZIhvcNAQcCoIIFmjCCBZYCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUtNtp1M3lDyLX4rjuQq7r8+vj
# wyigggMwMIIDLDCCAhSgAwIBAgIQdR0W2SKoK5VE8JId4ZxrRTANBgkqhkiG9w0B
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
# CQQxFgQUhReExI55Vpf1TK86mBCTxkFL15kwDQYJKoZIhvcNAQEBBQAEggEAb6yL
# Ho0YpB/INxuQOZBic3P+rXDQ2Lc/MIu1ZNZre4TKPrXHwYuDN4XRauuaf/16vvgT
# ugKk1QGABf1BrXtiRNp0//Y3Ea8KkanbjC/1tO92/rdAB9eYZ1cmlyd++kinl1Zx
# IExmxhVEAQp294Fq9O/i84clt80Bzq7QyYagevSPrqRBRaGJIEbhzuusPMkwa5X/
# DLJ7L9CKx/AhpwowT3dDNC21cbuWb9hcfL31V5fI4/JHgmwBQA3U/BQAb8J7WQec
# 6RPB3AN4c/5d0SEZydj7uWJnvf0cqP3Wp/y9y4xvNGqxRb9HrvulqUNoDx5sa/aX
# WH/Kg//e1IPieVvwQg==
# SIG # End signature block
