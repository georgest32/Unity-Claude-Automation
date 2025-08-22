# Debug-UnityLog.ps1
# Debug Unity Editor.log location and content
# Date: 2025-08-18

Write-Host "DEBUGGING UNITY EDITOR LOG" -ForegroundColor Cyan
Write-Host "============================" -ForegroundColor Cyan

# Check the expected path
$expectedPath = "C:\Users\georg\AppData\Local\Unity\Editor\Editor.log"
Write-Host "Checking expected path: $expectedPath" -ForegroundColor Yellow

if (Test-Path $expectedPath) {
    $logInfo = Get-Item $expectedPath
    Write-Host "  ✓ File exists" -ForegroundColor Green
    Write-Host "  Size: $($logInfo.Length) bytes" -ForegroundColor Gray
    Write-Host "  Last modified: $($logInfo.LastWriteTime)" -ForegroundColor Gray
    
    # Check recent content for compilation errors
    Write-Host "  Recent content (last 20 lines):" -ForegroundColor Gray
    $recentContent = Get-Content $expectedPath -Tail 20
    $hasErrors = $false
    
    foreach ($line in $recentContent) {
        if ($line -match "CS\d+:") {
            Write-Host "    ERROR: $line" -ForegroundColor Red
            $hasErrors = $true
        } else {
            Write-Host "    $line" -ForegroundColor DarkGray
        }
    }
    
    if (-not $hasErrors) {
        Write-Host "  ! No compilation errors in recent log entries" -ForegroundColor Yellow
    }
    
} else {
    Write-Host "  ✗ File does not exist" -ForegroundColor Red
}

# Check alternative Unity log locations
Write-Host "" -ForegroundColor White
Write-Host "Checking alternative Unity log locations..." -ForegroundColor Yellow

$alternativePaths = @(
    "$env:LOCALAPPDATA\Unity\Editor\Editor.log",
    "$env:APPDATA\Unity\Editor\Editor.log", 
    "$env:USERPROFILE\AppData\Local\Unity\Editor\Editor.log",
    "$env:USERPROFILE\AppData\Roaming\Unity\Editor\Editor.log",
    "C:\Users\$env:USERNAME\AppData\Local\Unity\Editor\Editor.log"
)

foreach ($path in $alternativePaths) {
    if (Test-Path $path) {
        $altInfo = Get-Item $path
        Write-Host "  ✓ Found: $path" -ForegroundColor Green
        Write-Host "    Size: $($altInfo.Length) bytes | Modified: $($altInfo.LastWriteTime)" -ForegroundColor Gray
        
        if ($path -ne $expectedPath) {
            Write-Host "    ⚠️  This is different from the expected path!" -ForegroundColor Yellow
        }
    }
}

# Check Unity process information
Write-Host "" -ForegroundColor White
Write-Host "Checking Unity processes..." -ForegroundColor Yellow

$unityProcesses = Get-Process | Where-Object { $_.ProcessName -like "*Unity*" }
if ($unityProcesses) {
    foreach ($proc in $unityProcesses) {
        Write-Host "  Unity process: $($proc.ProcessName) (PID: $($proc.Id))" -ForegroundColor Green
        if ($proc.MainWindowTitle) {
            Write-Host "    Window: $($proc.MainWindowTitle)" -ForegroundColor Gray
        }
    }
} else {
    Write-Host "  No Unity processes currently running" -ForegroundColor Yellow
}

# Test Unity compilation to generate fresh errors
Write-Host "" -ForegroundColor White
Write-Host "RECOMMENDATIONS:" -ForegroundColor Cyan
Write-Host "1. Verify Unity is actually compiling scripts (check Console in Unity)" -ForegroundColor White
Write-Host "2. Try creating a syntax error and forcing recompilation (Ctrl+R)" -ForegroundColor White
Write-Host "3. Check Unity Console for red error messages" -ForegroundColor White
Write-Host "4. Ensure Unity is writing to the log file (timestamps should update)" -ForegroundColor White

Write-Host "" -ForegroundColor White
Write-Host "Press Enter to exit..." -ForegroundColor Yellow
Read-Host
# SIG # Begin signature block
# MIIFqQYJKoZIhvcNAQcCoIIFmjCCBZYCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQURs70vWfflkvDMkwykKhJPFmQ
# RgegggMwMIIDLDCCAhSgAwIBAgIQdR0W2SKoK5VE8JId4ZxrRTANBgkqhkiG9w0B
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
# CQQxFgQUZb1jv8ULBAZZrHHVc7gJf7+cOiswDQYJKoZIhvcNAQEBBQAEggEACjCp
# IhWm06i2t1g0rA4Dt8mPqUjewJ2joceeqU1B84AmpGu6JrfqZaA2k0CpohG/NEEe
# 92u/XUFSpcfkVaIGgBf0W0WjKQB1Y/0tJSF8WSosmexe+Gvl7RbUNaUL0gcQ4+UQ
# DzxWvVmisCdImblmzkaUZXDEh/Ztn6K+s1dk74YJKByoeTi1LyzmL9kvgKOTJf/u
# IGn/AWyjQpZdDxb0Kae20j5Zzft2AHdSOIC9dnjsymBqe74TKTNMOKDkeYjX1i07
# LdxDJTv5WUsksbSghx6YKswtY6f4Mhk9/znCDH+EjhukDoZhjw2UU3P8GMarPOsG
# tGMPhaygyJUZxV3lEQ==
# SIG # End signature block
