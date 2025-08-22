# Test-ImprovedWindowDetection.ps1
# Test the improved Claude Code CLI window detection system
# Date: 2025-08-18

Set-Location "C:\UnityProjects\Sound-and-Shoal\Unity-Claude-Automation"

Write-Host "IMPROVED WINDOW DETECTION TEST" -ForegroundColor Cyan
Write-Host "===============================" -ForegroundColor Cyan

try {
    # Load the new window detection module
    Write-Host "Loading window detection module..." -ForegroundColor Yellow
    Import-Module ".\Modules\Unity-Claude-WindowDetection.psm1" -Force
    Write-Host "[+] Window detection module loaded" -ForegroundColor Green
    
    # Test 1: Show all windows
    Write-Host "" -ForegroundColor White
    Write-Host "1. All Available Windows:" -ForegroundColor Yellow
    Write-Host "=========================" -ForegroundColor Yellow
    
    $allWindows = Get-DetailedWindowInfo
    foreach ($window in $allWindows | Select-Object -First 10) {
        Write-Host "  Title: $($window.WindowTitle)" -ForegroundColor White
        Write-Host "    Process: $($window.ProcessName) (PID: $($window.ProcessId))" -ForegroundColor Gray
        Write-Host "    Start Time: $($window.StartTime)" -ForegroundColor DarkGray
        Write-Host "    Command: $($window.CommandLine -replace '.*\\', '...\\')" -ForegroundColor DarkGray
        Write-Host "" -ForegroundColor DarkGray
    }
    
    # Test 2: Claude Code detection
    Write-Host "" -ForegroundColor White
    Write-Host "2. Claude Code CLI Detection:" -ForegroundColor Yellow
    Write-Host "=============================" -ForegroundColor Yellow
    
    $detectionResult = Find-ClaudeCodeCLIWindow -Detailed
    
    if ($detectionResult.Success) {
        Write-Host "[SUCCESS] Claude Code CLI detected!" -ForegroundColor Green
        Write-Host "  Window: $($detectionResult.WindowTitle)" -ForegroundColor White
        Write-Host "  Process: $($detectionResult.ProcessName) (PID: $($detectionResult.ProcessId))" -ForegroundColor Gray
        Write-Host "  Confidence: $($detectionResult.Confidence)%" -ForegroundColor Green
        Write-Host "  Analysis Score: $($detectionResult.Analysis.Score)" -ForegroundColor Gray
        
        if ($detectionResult.Analysis.Reasons) {
            Write-Host "  Reasons:" -ForegroundColor Cyan
            foreach ($reason in $detectionResult.Analysis.Reasons) {
                Write-Host "    - $reason" -ForegroundColor Gray
            }
        }
    } else {
        Write-Host "[FAILED] Claude Code CLI not detected" -ForegroundColor Red
        Write-Host "Error: $($detectionResult.Error)" -ForegroundColor Red
        
        if ($detectionResult.AvailableWindows) {
            Write-Host "" -ForegroundColor White
            Write-Host "Top scoring windows:" -ForegroundColor Yellow
            $topWindows = $detectionResult.AvailableWindows | 
                Sort-Object { $_.Analysis.Score } -Descending | 
                Select-Object -First 5
                
            foreach ($scored in $topWindows) {
                $w = $scored.WindowInfo
                $a = $scored.Analysis
                Write-Host "  Score $($a.Score): $($w.WindowTitle) ($($w.ProcessName))" -ForegroundColor Gray
            }
        }
    }
    
    # Test 3: CLI Submission Integration
    Write-Host "" -ForegroundColor White
    Write-Host "3. CLI Submission Integration Test:" -ForegroundColor Yellow
    Write-Host "===================================" -ForegroundColor Yellow
    
    # Load CLI submission module
    Import-Module ".\Modules\Unity-Claude-CLISubmission.psm1" -Force
    
    # Test with a safe prompt (won't actually submit)
    Write-Host "Testing window detection in CLI submission..." -ForegroundColor Gray
    
    # We'll simulate by checking if the module can load and detect
    if (Get-Module Unity-Claude-WindowDetection) {
        Write-Host "[+] Window detection module available to CLI submission" -ForegroundColor Green
        
        # Try to detect the window (this won't submit anything)
        $testDetection = Find-ClaudeCodeCLIWindow
        if ($testDetection.Success) {
            Write-Host "[+] CLI submission would target: $($testDetection.WindowTitle)" -ForegroundColor Green
            Write-Host "    This looks correct!" -ForegroundColor Green
        } else {
            Write-Host "[-] CLI submission would fail to find Claude Code window" -ForegroundColor Red
        }
    } else {
        Write-Host "[-] Window detection module not available to CLI submission" -ForegroundColor Red
    }
    
    # Test 4: Current window info
    Write-Host "" -ForegroundColor White
    Write-Host "4. Current Active Window:" -ForegroundColor Yellow
    Write-Host "=========================" -ForegroundColor Yellow
    
    $currentWindow = Get-ForegroundWindow
    if ($currentWindow) {
        Write-Host "  Active Window: $($currentWindow.WindowTitle)" -ForegroundColor White
        Write-Host "  Process ID: $($currentWindow.ProcessId)" -ForegroundColor Gray
        Write-Host "  Window Handle: $($currentWindow.WindowHandle)" -ForegroundColor Gray
        
        # Test if current window would be detected as Claude Code
        $currentWindowInfo = @{
            ProcessId = $currentWindow.ProcessId
            WindowTitle = $currentWindow.WindowTitle
            ProcessName = (Get-Process -Id $currentWindow.ProcessId).ProcessName
            CommandLine = "Current window test"
            StartTime = Get-Date
            WindowHandle = $currentWindow.WindowHandle
        }
        
        $currentAnalysis = Test-ClaudeCodeWindow -WindowInfo $currentWindowInfo
        Write-Host "  Claude Code likelihood: $($currentAnalysis.Confidence)%" -ForegroundColor Gray
        Write-Host "  Would be detected: $($currentAnalysis.IsLikelyClaudeCode)" -ForegroundColor Gray
        
    } else {
        Write-Host "  Could not get current window information" -ForegroundColor Red
    }
    
    # Summary
    Write-Host "" -ForegroundColor White
    Write-Host "TEST SUMMARY:" -ForegroundColor Cyan
    Write-Host "=============" -ForegroundColor Cyan
    
    if ($detectionResult.Success) {
        Write-Host "[SUCCESS] Improved window detection is working!" -ForegroundColor Green
        Write-Host "The autonomous system should now correctly target:" -ForegroundColor White
        Write-Host "  $($detectionResult.WindowTitle)" -ForegroundColor Green
        Write-Host "Instead of random PowerShell/debug windows." -ForegroundColor Gray
    } else {
        Write-Host "[ISSUE] Window detection needs refinement" -ForegroundColor Yellow
        Write-Host "The system may still have trouble finding Claude Code CLI" -ForegroundColor Gray
    }
    
} catch {
    Write-Host "Test failed with error: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "Stack trace: $($_.ScriptStackTrace)" -ForegroundColor DarkRed
}

Write-Host "" -ForegroundColor White
Write-Host "Press Enter to exit..." -ForegroundColor Gray
Read-Host
# SIG # Begin signature block
# MIIFqQYJKoZIhvcNAQcCoIIFmjCCBZYCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUT4Srpyep6gkUeIAAtHx4ZG1x
# NcOgggMwMIIDLDCCAhSgAwIBAgIQdR0W2SKoK5VE8JId4ZxrRTANBgkqhkiG9w0B
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
# CQQxFgQUHWiXTj1L4m94RFBzXpE6Jsta+1EwDQYJKoZIhvcNAQEBBQAEggEASxYd
# DVLNzUaI0y+ZCOL8coSn8b5dmlF3wU/QAaesIOJ34z9Se5kJJMS3jvwbFxWSXjuS
# 8skn94pwg1a1Z7BuChip9fGdUYZfZcobetLcfUUcxOrLmURjxgYmpRQ6OKt/t+EH
# bNpSiT63B4guRWOO57v7c/2sgXkp7PxQor9Ung+4GWgrPQvZPhb7KGAigqZj50oL
# DYfaiLE09dRGk64kATRuuciZzJMtxprAwZhNRaxARj2TYm7BEAw3Z+RazaRPxejs
# JEBFj0LPp8P8SFd9PiNyWSV53NycdtHb+ebiJA7PgweeFf0VTndtUj25sPKOgDU/
# 4k5xpEdu1Nb+/K7HuQ==
# SIG # End signature block
