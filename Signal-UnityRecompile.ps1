# Signal-UnityRecompile.ps1
# Signal autonomous system to switch to Unity and trigger recompilation
# Used by Claude after making code changes
# Date: 2025-08-18

Set-Location "C:\UnityProjects\Sound-and-Shoal\Unity-Claude-Automation"

Write-Host "SIGNALING UNITY RECOMPILATION REQUEST" -ForegroundColor Cyan
Write-Host "=====================================" -ForegroundColor Cyan

# Create signal file for autonomous system
$signalFile = ".\unity_recompile_signal.json"
$signalData = @{
    timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss.fff"
    requestedBy = "Claude"
    reason = "Code changes made - recompilation required"
    priority = "High"
    windowSwitchRequired = $true
}

$json = $signalData | ConvertTo-Json -Depth 3
[System.IO.File]::WriteAllText($signalFile, $json, [System.Text.Encoding]::UTF8)

Write-Host "[+] Unity recompilation signal sent!" -ForegroundColor Green
Write-Host "  Signal file: $signalFile" -ForegroundColor Gray
Write-Host "  Timestamp: $($signalData.timestamp)" -ForegroundColor Gray
Write-Host "" -ForegroundColor White
Write-Host "The autonomous system should now:" -ForegroundColor Yellow
Write-Host "1. Detect the recompilation signal" -ForegroundColor Gray
Write-Host "2. Switch to Unity window to trigger recompilation" -ForegroundColor Gray
Write-Host "3. Switch back to monitoring" -ForegroundColor Gray
Write-Host "4. Detect any new compilation results" -ForegroundColor Gray
# SIG # Begin signature block
# MIIFqQYJKoZIhvcNAQcCoIIFmjCCBZYCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUsp+GGVzeXBi1/VD9BhSLgPDY
# egmgggMwMIIDLDCCAhSgAwIBAgIQdR0W2SKoK5VE8JId4ZxrRTANBgkqhkiG9w0B
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
# CQQxFgQU19Tv7IK2rp94sgktP19AujqfXuwwDQYJKoZIhvcNAQEBBQAEggEAZ5Pg
# UBpLt2aN0SF7CNk9VIwssYhtir5UeSGya/WCkuiwqGyGTRXlknBUNgOZgBgf3eFv
# mocAfPhAI2c5dymtBrkVn4triQdeV/N/RSHMEFbK+kG3bEEDz684eTTxwhm+5lFy
# uPNO+nuDy8IJGFp8C0b/AEjl5KAhcGNmgRRGiPp3cpmm2svnPTuNyCYBVkYiNUTt
# zxNxkxS1NiemyuhVy7DX4d8l7F8PcHf8tO/LCJXlT1pwQZI6gqmRnoZZ3uZjfwxA
# Ct5/mpL57goJztNeHyXjP2knW4aVY7i5RgpAchIHRq1VlhTSPzvr0MAuZE+JNpwo
# pK1mK7qI/VjuY37gNg==
# SIG # End signature block
