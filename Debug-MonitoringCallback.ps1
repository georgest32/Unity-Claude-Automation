# Debug-MonitoringCallback.ps1
# Debug the callback triggering mechanism
# Date: 2025-08-18

Set-Location "C:\UnityProjects\Sound-and-Shoal\Unity-Claude-Automation"

Write-Host "DEBUGGING MONITORING CALLBACK" -ForegroundColor Cyan
Write-Host "==============================" -ForegroundColor Cyan

# Import module
Import-Module ".\Modules\Unity-Claude-ReliableMonitoring.psm1" -Force

# Test direct JSON reading
$unityErrorPath = "C:\UnityProjects\Sound-and-Shoal\Unity-Claude-Automation\unity_errors_safe.json"
Write-Host "Testing direct JSON reading..." -ForegroundColor Yellow

if (Test-Path $unityErrorPath) {
    try {
        $content = Get-Content $unityErrorPath -Raw -Encoding UTF8
        Write-Host "Raw JSON content length: $($content.Length) characters" -ForegroundColor Gray
        
        # Remove BOM if present
        if ($content[0] -eq [char]0xFEFF) {
            $content = $content.Substring(1)
            Write-Host "Removed UTF8 BOM" -ForegroundColor Yellow
        }
        
        $errorData = $content | ConvertFrom-Json
        Write-Host "Successfully parsed JSON" -ForegroundColor Green
        Write-Host "Total errors: $($errorData.totalErrors)" -ForegroundColor White
        Write-Host "Error count: $($errorData.errors.Count)" -ForegroundColor White
        
        foreach ($error in $errorData.errors) {
            Write-Host "  Error: $($error.message)" -ForegroundColor Red
        }
        
    } catch {
        Write-Host "ERROR parsing JSON: $($_.Exception.Message)" -ForegroundColor Red
    }
}

# Define debug callback
$debugCallback = {
    param($errors)
    Write-Host "" -ForegroundColor White
    Write-Host "*** CALLBACK TRIGGERED! ***" -ForegroundColor Green -BackgroundColor Black
    Write-Host "Error count: $($errors.Count)" -ForegroundColor Yellow
    foreach ($error in $errors) {
        Write-Host "  ERROR: $error" -ForegroundColor Red
    }
    Write-Host "*** END CALLBACK ***" -ForegroundColor Green -BackgroundColor Black
    Write-Host "" -ForegroundColor White
}

# Start monitoring with debug
Write-Host "" -ForegroundColor White
Write-Host "Starting monitoring with debug callback..." -ForegroundColor Yellow
$result = Start-ReliableUnityMonitoring -OnErrorDetected $debugCallback

if ($result.Success) {
    Write-Host "Monitoring started. Current status:" -ForegroundColor Green
    $status = Get-ReliableMonitoringStatus
    Write-Host "  LastErrorCount: $($status.LastErrorCount)" -ForegroundColor Gray
    Write-Host "  FileWatcherActive: $($status.FileWatcherActive)" -ForegroundColor Gray
    Write-Host "  PollingActive: $($status.PollingActive)" -ForegroundColor Gray
    
    # Manually trigger the Process-UnityErrors function to debug
    Write-Host "" -ForegroundColor White
    Write-Host "Manually triggering Process-UnityErrors for debugging..." -ForegroundColor Magenta
    
    # I need to access the internal function - let me check the module for a test function
    Write-Host "Waiting 10 seconds for automatic detection..." -ForegroundColor Yellow
    Start-Sleep 10
    
    # Update file timestamp to trigger change
    Write-Host "Updating file timestamp to force detection..." -ForegroundColor Magenta
    if (Test-Path $unityErrorPath) {
        (Get-Item $unityErrorPath).LastWriteTime = Get-Date
        Write-Host "File timestamp updated" -ForegroundColor Green
    }
    
    # Wait for detection
    Write-Host "Waiting 10 more seconds for callback..." -ForegroundColor Yellow
    Start-Sleep 10
    
    Stop-ReliableUnityMonitoring
    Write-Host "Monitoring stopped" -ForegroundColor Green
    
} else {
    Write-Host "Failed to start monitoring: $($result.Error)" -ForegroundColor Red
}

Write-Host "" -ForegroundColor White
Write-Host "Debug complete. Press Enter to exit..." -ForegroundColor Yellow
Read-Host
# SIG # Begin signature block
# MIIFqQYJKoZIhvcNAQcCoIIFmjCCBZYCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUY8rdjemWQ1Ob+wc/jaGyrCUn
# YkOgggMwMIIDLDCCAhSgAwIBAgIQdR0W2SKoK5VE8JId4ZxrRTANBgkqhkiG9w0B
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
# CQQxFgQUMlKajDooAxqNu712K6ED6KAUVRwwDQYJKoZIhvcNAQEBBQAEggEAbTh4
# od2SNFVJS2IvQ6eRjHH/+qk0T5gcW26k6EdIgiAYxDk3PmhWX+4NQ5Rnk5Asl/la
# R8iH1Ggt+PZ54aqUeEsa6847a0uZ3CZjilcUq+rUtqfP7dK4acZ09mdrJfOpEMIu
# ILgHHtlR0kaS54BJOy8rSK8zPGZdY/MsO7FPn/zAVOHj2XTpALM+1pfWZSxyhS4p
# oXXtNFUPIKQYJKTZ3GhBiC/N7TUZHkbmg7Or5wEzNkTIOoWC7aFFzyeUHLSqZ+LK
# z5N3QplJs9+/JQ99Pu/K2O+3Nhwle0Z93CNl2XJ/7B+o3qOyBuL25pGXCnIP8us6
# ZJ8PoAYX496cSGIjtA==
# SIG # End signature block
