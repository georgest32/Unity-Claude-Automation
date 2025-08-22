# Quick-TriggerTest.ps1
# Simple test to trigger autonomous system immediately
# Date: 2025-08-18

Set-Location "C:\UnityProjects\Sound-and-Shoal\Unity-Claude-Automation"

Write-Host "QUICK AUTONOMOUS TRIGGER TEST" -ForegroundColor Cyan
Write-Host "=============================" -ForegroundColor Cyan

$errorFile = ".\unity_errors_safe.json"

if (Test-Path $errorFile) {
    Write-Host "[+] Found Unity error file" -ForegroundColor Green
    
    # Simple approach: just update the timestamp by touching the file
    Write-Host "[+] Updating file timestamp to trigger monitoring..." -ForegroundColor Yellow
    
    # Method 1: Update file timestamp
    (Get-Item $errorFile).LastWriteTime = Get-Date
    Write-Host "  Timestamp updated: $(Get-Date -Format 'HH:mm:ss.fff')" -ForegroundColor Gray
    
    Start-Sleep 2
    
    # Method 2: Add a simple byte to force file change
    $content = Get-Content $errorFile -Raw
    $content += " "  # Add a space
    [System.IO.File]::WriteAllText($errorFile, $content.TrimEnd() + " ", [System.Text.Encoding]::UTF8)
    Write-Host "  Content modified: $(Get-Date -Format 'HH:mm:ss.fff')" -ForegroundColor Gray
    
    Start-Sleep 2
    
    # Method 3: Restore original content but with fresh write
    $originalContent = $content.TrimEnd()
    [System.IO.File]::WriteAllText($errorFile, $originalContent, [System.Text.Encoding]::UTF8)
    Write-Host "  Final write: $(Get-Date -Format 'HH:mm:ss.fff')" -ForegroundColor Gray
    
    Write-Host "" -ForegroundColor White
    Write-Host "[>] AUTONOMOUS SYSTEM SHOULD ACTIVATE NOW!" -ForegroundColor Green
    Write-Host "Watch your autonomous system window for immediate activity..." -ForegroundColor Yellow
    Write-Host "" -ForegroundColor White
    Write-Host "Expected behavior:" -ForegroundColor Cyan
    Write-Host "- File change detected within 2 seconds" -ForegroundColor Gray
    Write-Host "- Autonomous callback triggered" -ForegroundColor Gray
    Write-Host "- Prompt generated and submitted to Claude Code CLI" -ForegroundColor Gray
    
} else {
    Write-Host "[-] Unity error file not found: $errorFile" -ForegroundColor Red
    Write-Host "Make sure Unity is running with SafeConsoleExporter" -ForegroundColor Yellow
}

Write-Host "" -ForegroundColor White
Write-Host "Press Enter to exit..." -ForegroundColor Gray
Read-Host
# SIG # Begin signature block
# MIIFqQYJKoZIhvcNAQcCoIIFmjCCBZYCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUeOwAFDW7BgWEYmPiXUSFJYXQ
# IhWgggMwMIIDLDCCAhSgAwIBAgIQdR0W2SKoK5VE8JId4ZxrRTANBgkqhkiG9w0B
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
# CQQxFgQU685C5OwE0YmhzYVImO9wBpa+vG4wDQYJKoZIhvcNAQEBBQAEggEAVPHG
# juxhdG3Pu8cg78upJabpTjGCiS4YMd0OkJ9+SbS4cL0b1IG534PkdLBKAWptfJXT
# Wu5iZJnOw+Gy5rZHvESMkAgq4H5maS4xqqDh5/0FwnGNd9ajAWU6bu2MgVp8FhYZ
# yXCEPC8Jg3Byu24ImcDbU3ySaiMNGRDlbolwmKkNQcm48XShLrV3p+S2BIwKnay6
# LL2TydpbGmal4S/84Pw8WXoZKJ1STzw05EyaoINZaC7lPNufa/zQNp186o14Epn1
# V736q9QWrKdmWGNdI9uSSjBNG5Ii4yW6ZfzJrTcPJ6gHm0HWrDSvZxAfH8O0t0sC
# S+Fnvx4uxaCtSZxyLA==
# SIG # End signature block
