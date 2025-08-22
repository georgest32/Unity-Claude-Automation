# Debug-RecompileSignaling.ps1
# Comprehensive debugging of the recompilation signaling system
# Date: 2025-08-18

Set-Location "C:\UnityProjects\Sound-and-Shoal\Unity-Claude-Automation"

Write-Host "RECOMPILATION SIGNALING SYSTEM DIAGNOSTIC" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan

$issues = @()

# Check 1: Signal file exists
Write-Host "" -ForegroundColor White
Write-Host "1. Checking signal file..." -ForegroundColor Yellow
$signalFile = ".\unity_recompile_signal.json"

if (Test-Path $signalFile) {
    $fileInfo = Get-Item $signalFile
    Write-Host "  [+] Signal file exists" -ForegroundColor Green
    Write-Host "    Path: $signalFile" -ForegroundColor Gray
    Write-Host "    Modified: $($fileInfo.LastWriteTime)" -ForegroundColor Gray
    Write-Host "    Size: $($fileInfo.Length) bytes" -ForegroundColor Gray
    
    try {
        $content = Get-Content $signalFile | ConvertFrom-Json
        Write-Host "    Content: $($content.reason)" -ForegroundColor Gray
    } catch {
        Write-Host "  [-] Invalid JSON content" -ForegroundColor Red
        $issues += "Signal file has invalid JSON"
    }
} else {
    Write-Host "  [-] Signal file does not exist" -ForegroundColor Red
    $issues += "Signal file missing"
}

# Check 2: Module loading
Write-Host "" -ForegroundColor White
Write-Host "2. Testing module loading..." -ForegroundColor Yellow

try {
    Import-Module ".\Modules\Unity-Claude-RecompileSignaling.psm1" -Force
    Write-Host "  [+] RecompileSignaling module loaded" -ForegroundColor Green
} catch {
    Write-Host "  [-] Failed to load module: $($_.Exception.Message)" -ForegroundColor Red
    $issues += "Module loading failed: $($_.Exception.Message)"
}

# Check 3: Rapid switch path
Write-Host "" -ForegroundColor White
Write-Host "3. Checking rapid switch path..." -ForegroundColor Yellow

$modulePath = ".\Modules\"
$rapidSwitchPath1 = Join-Path $modulePath "..\Invoke-RapidUnitySwitch.ps1"
$rapidSwitchPath2 = ".\Invoke-RapidUnitySwitch.ps1"

Write-Host "  Current module path construction: $rapidSwitchPath1" -ForegroundColor Gray
Write-Host "  Correct path should be: $rapidSwitchPath2" -ForegroundColor Gray

if (Test-Path $rapidSwitchPath1) {
    Write-Host "  [+] Module path construction works" -ForegroundColor Green
} else {
    Write-Host "  [-] Module path construction fails" -ForegroundColor Red
    $issues += "Rapid switch path construction incorrect"
}

if (Test-Path $rapidSwitchPath2) {
    Write-Host "  [+] Direct rapid switch path exists" -ForegroundColor Green
} else {
    Write-Host "  [-] Rapid switch script missing" -ForegroundColor Red
    $issues += "Rapid switch script not found"
}

# Check 4: Test signal monitoring startup
Write-Host "" -ForegroundColor White
Write-Host "4. Testing signal monitoring startup..." -ForegroundColor Yellow

try {
    $testCallback = {
        Write-Host "  [>] TEST SIGNAL DETECTED!" -ForegroundColor Cyan
    }
    
    $result = Start-RecompileSignalMonitoring -OnSignalDetected $testCallback
    
    if ($result.Success) {
        Write-Host "  [+] Signal monitoring started successfully" -ForegroundColor Green
        
        # Test signal detection
        Write-Host "  [+] Testing signal detection..." -ForegroundColor Yellow
        Start-Sleep 2
        
        # Modify signal file to trigger detection
        if (Test-Path $signalFile) {
            (Get-Item $signalFile).LastWriteTime = Get-Date
            Write-Host "  [+] Signal file timestamp updated" -ForegroundColor Green
            
            # Wait for detection
            Write-Host "  [+] Waiting 5 seconds for detection..." -ForegroundColor Gray
            for ($i = 5; $i -gt 0; $i--) {
                Write-Host "." -NoNewline -ForegroundColor Gray
                Start-Sleep 1
            }
            Write-Host "" -ForegroundColor White
        }
        
        # Stop monitoring
        Stop-RecompileSignalMonitoring
        Write-Host "  [+] Signal monitoring stopped" -ForegroundColor Green
        
    } else {
        Write-Host "  [-] Signal monitoring failed: $($result.Error)" -ForegroundColor Red
        $issues += "Signal monitoring startup failed: $($result.Error)"
    }
    
} catch {
    Write-Host "  [-] Error testing signal monitoring: $($_.Exception.Message)" -ForegroundColor Red
    $issues += "Signal monitoring test failed: $($_.Exception.Message)"
}

# Check 5: Manual rapid switch test
Write-Host "" -ForegroundColor White
Write-Host "5. Testing rapid switch directly..." -ForegroundColor Yellow

try {
    if (Test-Path ".\Invoke-RapidUnitySwitch.ps1") {
        Write-Host "  [+] Testing rapid switch execution..." -ForegroundColor Yellow
        $rapidResult = & ".\Invoke-RapidUnitySwitch.ps1" -WaitMilliseconds 50 -Measure -TestMode
        
        if ($rapidResult.Success) {
            Write-Host "  [+] Rapid switch test successful" -ForegroundColor Green
            Write-Host "    Test mode time: $([Math]::Round($rapidResult.TotalMilliseconds, 2))ms" -ForegroundColor Gray
        } else {
            Write-Host "  [-] Rapid switch test failed" -ForegroundColor Red
            $issues += "Rapid switch test failed"
        }
    } else {
        Write-Host "  [-] Rapid switch script not found" -ForegroundColor Red
        $issues += "Rapid switch script missing"
    }
} catch {
    Write-Host "  [-] Error testing rapid switch: $($_.Exception.Message)" -ForegroundColor Red
    $issues += "Rapid switch execution failed: $($_.Exception.Message)"
}

# Check 6: Unity process detection
Write-Host "" -ForegroundColor White
Write-Host "6. Checking Unity process..." -ForegroundColor Yellow

$unityProcesses = Get-Process | Where-Object { 
    $_.ProcessName -like "*Unity*" -and 
    $_.MainWindowTitle -like "*Unity*" -and
    $_.MainWindowTitle -notlike "*Hub*"
}

if ($unityProcesses) {
    Write-Host "  [+] Found $($unityProcesses.Count) Unity processes" -ForegroundColor Green
    foreach ($proc in $unityProcesses) {
        Write-Host "    - $($proc.ProcessName): $($proc.MainWindowTitle)" -ForegroundColor Gray
    }
} else {
    Write-Host "  [!] No Unity Editor processes found" -ForegroundColor Yellow
    Write-Host "    This may prevent window switching from working" -ForegroundColor Yellow
}

# Summary
Write-Host "" -ForegroundColor White
Write-Host "DIAGNOSTIC SUMMARY:" -ForegroundColor Cyan
Write-Host "==================" -ForegroundColor Cyan

if ($issues.Count -eq 0) {
    Write-Host "[+] No issues found - system should be working" -ForegroundColor Green
} else {
    Write-Host "[-] Found $($issues.Count) issues:" -ForegroundColor Red
    for ($i = 0; $i -lt $issues.Count; $i++) {
        Write-Host "  $($i + 1). $($issues[$i])" -ForegroundColor Red
    }
    
    Write-Host "" -ForegroundColor White
    Write-Host "RECOMMENDED FIXES:" -ForegroundColor Yellow
    
    if ("Rapid switch path construction incorrect" -in $issues) {
        Write-Host "1. Fix path construction in Unity-Claude-RecompileSignaling.psm1" -ForegroundColor Gray
    }
    if ("Signal file missing" -in $issues) {
        Write-Host "2. Create signal file to trigger system" -ForegroundColor Gray
    }
    if ($issues -like "*monitoring*") {
        Write-Host "3. Check FileSystemWatcher permissions and setup" -ForegroundColor Gray
    }
}

Write-Host "" -ForegroundColor White
Write-Host "Press Enter to exit..." -ForegroundColor Gray
Read-Host
# SIG # Begin signature block
# MIIFqQYJKoZIhvcNAQcCoIIFmjCCBZYCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUdTIeqcfPX7LquEATMsDwoy3J
# XX6gggMwMIIDLDCCAhSgAwIBAgIQdR0W2SKoK5VE8JId4ZxrRTANBgkqhkiG9w0B
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
# CQQxFgQUsxA+RAAOu2uSoZcjlYoRmG4RVxkwDQYJKoZIhvcNAQEBBQAEggEAi33X
# hxFhkZ4BC5pp/56h+Hw2cJes5jdRGny2sX47b2eoGia+LkAqH/4wLSyev9O3F4Wy
# Wj8ZTEn5HO6BAmis6WtuV6WrodzdzAXnBM/YPd96XpliYgHUarkmVx+nSlLJNR1r
# G1Z0enKnNsivtmSfbZDzDPgBUXlASrmrjSI4qLZDY5f2It1lYXei4ZeGBgsdDqc4
# HL+OYeVIZFZvu8DVcY/K89J9d4Ei2n0cVoUD1ZmuHTfvuPtz4vINNYFwYrxWqzg7
# rADf0fZtVWqYpQ+LI7CY90oqylfg7ow0XaHOU6eBLbv12sMsGpBx1aAu3bLAnHs9
# uS4Nbq+Dk+Jt9PX9pA==
# SIG # End signature block
