# Trigger-AutonomousSystem.ps1
# Force trigger the autonomous system by updating Unity error file
# Date: 2025-08-18

Set-Location "C:\UnityProjects\Sound-and-Shoal\Unity-Claude-Automation"

Write-Host "TRIGGERING AUTONOMOUS SYSTEM" -ForegroundColor Cyan
Write-Host "============================" -ForegroundColor Cyan

# Check current error file
$errorFile = ".\unity_errors_safe.json"
if (Test-Path $errorFile) {
    $fileInfo = Get-Item $errorFile
    Write-Host "Current error file timestamp: $($fileInfo.LastWriteTime)" -ForegroundColor Gray
    
    # Read current content
    $currentContent = Get-Content $errorFile | ConvertFrom-Json
    Write-Host "Current errors: $($currentContent.totalErrors)" -ForegroundColor Gray
    
    # Update the export time to current time (this should trigger file monitoring)
    $currentContent.exportTime = Get-Date -Format "yyyy-MM-dd HH:mm:ss.fff"
    
    # Add a new error entry to ensure detection
    $newError = @{
        message = "Test autonomous trigger - CS0116: A namespace cannot directly contain members"
        stackTrace = ""
        type = "CompilationError"
        timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss.fff"
        source = "AutonomousTrigger"
    }
    
    # Update the content
    $currentContent.errors += $newError
    $currentContent.totalErrors = $currentContent.errors.Count
    
    # Write back to file (this should trigger the FileSystemWatcher)
    $updatedJson = $currentContent | ConvertTo-Json -Depth 4
    [System.IO.File]::WriteAllText($errorFile, $updatedJson, [System.Text.Encoding]::UTF8)
    
    Write-Host "[+] Updated error file with new timestamp" -ForegroundColor Green
    Write-Host "[+] Added test error to trigger autonomous system" -ForegroundColor Green
    Write-Host "New timestamp: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss.fff')" -ForegroundColor Gray
    Write-Host "Total errors: $($currentContent.totalErrors)" -ForegroundColor Gray
    
    Write-Host "" -ForegroundColor White
    Write-Host "The autonomous system should now detect this file change!" -ForegroundColor Yellow
    Write-Host "Watch your autonomous system window for activity..." -ForegroundColor Yellow
    
} else {
    Write-Host "[-] Unity error file not found: $errorFile" -ForegroundColor Red
    Write-Host "The SafeConsoleExporter in Unity may not be working" -ForegroundColor Yellow
}

Write-Host "" -ForegroundColor White
Write-Host "Press Enter to continue..." -ForegroundColor Gray
Read-Host
# SIG # Begin signature block
# MIIFqQYJKoZIhvcNAQcCoIIFmjCCBZYCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUOtpDKJMnUnZMte8Ub4sG+l9W
# kTegggMwMIIDLDCCAhSgAwIBAgIQdR0W2SKoK5VE8JId4ZxrRTANBgkqhkiG9w0B
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
# CQQxFgQUJYUQdNXJhmh1/KX9DD7aEZtrjsMwDQYJKoZIhvcNAQEBBQAEggEAn3zP
# t8ebbOPprYpdP1w5p2ObR3T/Kx8ZL5/S+tIpT8SkHsomuhC8oBsvdsVxuHP8sn9B
# +4yy9rx8ebfD262EnTt1Tiov8dAkgu7glP/PMcT5JG6BR8FdUU1OQBaRT7nb53jv
# FEZ7NCPJ2ZPHICo8idyyGqbqCHELQHAqrvKHbXRLJbsurwxxoD9C83XoerKANiA4
# haRQ1Qt6jFqf5e6QR4pnabyDwVHHu39l8OKf29735hAQrJTfEGu6Bzifxgxq1mG1
# 6E1w53rI4szurd1jHCTdHJ53HHNhyCgvO4+UZqCRPsv0Fg7J0jKYeSkE+cbxPlxO
# 1VUbBsKGB62r/OxHaA==
# SIG # End signature block
