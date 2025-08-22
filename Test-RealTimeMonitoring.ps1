# Test-RealTimeMonitoring.ps1
# Test real-time file monitoring without blocking
# Date: 2025-08-18

Set-Location "C:\UnityProjects\Sound-and-Shoal\Unity-Claude-Automation"

Write-Host "TESTING REAL-TIME MONITORING" -ForegroundColor Cyan
Write-Host "============================" -ForegroundColor Cyan

try {
    # Load monitoring module
    Import-Module ".\Modules\Unity-Claude-ReliableMonitoring.psm1" -Force
    Write-Host "[+] Loaded monitoring module" -ForegroundColor Green
    
    # Create callback
    $callbackTriggered = $false
    $detectionTimes = @()
    
    $testCallback = {
        param($errors)
        $global:callbackTriggered = $true
        $global:detectionTimes += Get-Date
        
        Write-Host "" -ForegroundColor White
        Write-Host "[>] REAL-TIME DETECTION!" -ForegroundColor Green
        Write-Host "Time: $(Get-Date -Format 'HH:mm:ss.fff')" -ForegroundColor Yellow
        Write-Host "Errors: $($errors.Count)" -ForegroundColor Gray
        Write-Host "========================" -ForegroundColor Green
    }
    
    # Start monitoring
    Write-Host "[+] Starting real-time monitoring..." -ForegroundColor Yellow
    $monitorResult = Start-ReliableUnityMonitoring -OnErrorDetected $testCallback
    
    if ($monitorResult.Success) {
        Write-Host "[+] Monitoring active!" -ForegroundColor Green
        Write-Host "  Method: $($monitorResult.Method)" -ForegroundColor Gray
        Write-Host "  FileWatcher: $($monitorResult.FileWatcher)" -ForegroundColor Gray
        Write-Host "  Polling: $($monitorResult.Polling)" -ForegroundColor Gray
        
        Write-Host "" -ForegroundColor White
        Write-Host "REAL-TIME TEST SEQUENCE:" -ForegroundColor Cyan
        Write-Host "I will modify the Unity error file 3 times with 5-second intervals" -ForegroundColor White
        Write-Host "Each modification should trigger immediate detection" -ForegroundColor White
        Write-Host "" -ForegroundColor White
        
        # Test sequence with non-blocking waits
        for ($test = 1; $test -le 3; $test++) {
            Write-Host "Test $test - Modifying error file..." -ForegroundColor Yellow
            
            # Modify the file
            $errorFile = ".\unity_errors_safe.json"
            if (Test-Path $errorFile) {
                $content = Get-Content $errorFile | ConvertFrom-Json
                
                # Create new object with updated properties (avoid property assignment issues)
                $newContent = @{
                    errors = $content.errors
                    totalErrors = $content.totalErrors
                    exportTime = Get-Date -Format "yyyy-MM-dd HH:mm:ss.fff"
                    isCompiling = $content.isCompiling
                    testNumber = $test
                    triggerTime = Get-Date -Format "yyyy-MM-dd HH:mm:ss.fff"
                }
                
                $json = $newContent | ConvertTo-Json -Depth 4
                [System.IO.File]::WriteAllText($errorFile, $json, [System.Text.Encoding]::UTF8)
                
                $modifyTime = Get-Date
                Write-Host "  File modified at: $($modifyTime.ToString('HH:mm:ss.fff'))" -ForegroundColor Gray
                
                # Non-blocking wait for detection (up to 10 seconds)
                $timeout = $modifyTime.AddSeconds(10)
                $detected = $false
                
                while ((Get-Date) -lt $timeout -and -not $detected) {
                    Start-Sleep -Milliseconds 100  # Short sleep to allow events
                    
                    # Check if callback was triggered since modification
                    if ($global:detectionTimes.Count -gt 0) {
                        $lastDetection = $global:detectionTimes[-1]
                        if ($lastDetection -gt $modifyTime) {
                            $detected = $true
                            $responseTime = ($lastDetection - $modifyTime).TotalMilliseconds
                            Write-Host "  [SUCCESS] Detected in $([Math]::Round($responseTime))ms!" -ForegroundColor Green
                        }
                    }
                }
                
                if (-not $detected) {
                    Write-Host "  [WARNING] No detection within 10 seconds" -ForegroundColor Yellow
                }
                
            } else {
                Write-Host "  [ERROR] Unity error file not found" -ForegroundColor Red
            }
            
            # Wait between tests (non-blocking)
            if ($test -lt 3) {
                Write-Host "  Waiting 5 seconds for next test..." -ForegroundColor Gray
                for ($i = 5; $i -gt 0; $i--) {
                    Write-Host "." -NoNewline -ForegroundColor DarkGray
                    Start-Sleep 1
                }
                Write-Host "" -ForegroundColor White
            }
        }
        
        # Stop monitoring
        Write-Host "" -ForegroundColor White
        Write-Host "Stopping monitoring..." -ForegroundColor Yellow
        Stop-ReliableUnityMonitoring
        Write-Host "[+] Monitoring stopped" -ForegroundColor Green
        
        # Results
        Write-Host "" -ForegroundColor White
        Write-Host "TEST RESULTS:" -ForegroundColor Cyan
        Write-Host "=============" -ForegroundColor Cyan
        Write-Host "Total detections: $($global:detectionTimes.Count)" -ForegroundColor White
        
        if ($global:detectionTimes.Count -gt 0) {
            Write-Host "Detection times:" -ForegroundColor Gray
            foreach ($time in $global:detectionTimes) {
                Write-Host "  - $($time.ToString('HH:mm:ss.fff'))" -ForegroundColor Gray
            }
            
            if ($global:detectionTimes.Count -eq 3) {
                Write-Host "[SUCCESS] Real-time monitoring is working perfectly!" -ForegroundColor Green
            } else {
                Write-Host "[PARTIAL] Some detections missed - may need tuning" -ForegroundColor Yellow
            }
        } else {
            Write-Host "[FAILED] No real-time detections occurred" -ForegroundColor Red
            Write-Host "The FileSystemWatcher may not be working properly" -ForegroundColor Yellow
        }
        
    } else {
        Write-Host "[-] Failed to start monitoring: $($monitorResult.Error)" -ForegroundColor Red
    }
    
} catch {
    Write-Host "[-] Test error: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host "" -ForegroundColor White
Write-Host "Press Enter to exit..." -ForegroundColor Gray
Read-Host
# SIG # Begin signature block
# MIIFqQYJKoZIhvcNAQcCoIIFmjCCBZYCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQU0vwSXplpD4rfVCG//Ix3LVAu
# i5SgggMwMIIDLDCCAhSgAwIBAgIQdR0W2SKoK5VE8JId4ZxrRTANBgkqhkiG9w0B
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
# CQQxFgQU2ZnLaLWpeniE8BmXmeQJjJJ4WKkwDQYJKoZIhvcNAQEBBQAEggEAMBIa
# TUAXjsgSqrIA4JRrVqSxgY6TVQgy5AsY85cQ18mAqOGRB6ZMBQqsaFMCs4UBCGMr
# pCCTmdY35BOAJYuD9EkcpnQ+lMpz0sRZZ6Y6T5PUpNsuROABWtlWn5nYM8s8SPib
# CA0AoSP0RlBSEb49nTjszk+SslTmh2BGK9FB2MUzOFS2DX+Azxyj8JzZBMHN7bER
# rfXlSbtbgMFZu8Dh2zX/LqK7YWCramDtSSJxlxYPZRFnSlQ1Tu+GyUPmhwHpXg3C
# tjyhDFkVOPnTyIw7ZliYs/WK2lweTQSnNsOMsTxBW/gfd9GuGYUCnz/ebiE7aBnk
# xflngogFpU+JBq0Deg==
# SIG # End signature block
