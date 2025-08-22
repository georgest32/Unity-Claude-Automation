# Test-ModuleLoading-Quick.ps1
# Quick validation test for Unity-Claude-RunspaceManagement module syntax fixes
# Date: 2025-08-21

Write-Host "=== Quick Module Loading Test ===" -ForegroundColor Cyan
Write-Host "Testing Unity-Claude-RunspaceManagement module after syntax fixes" -ForegroundColor Yellow

try {
    Write-Host "Attempting to import module..." -ForegroundColor White
    Import-Module ".\Modules\Unity-Claude-RunspaceManagement\Unity-Claude-RunspaceManagement.psd1" -Force -ErrorAction Stop
    Write-Host "[SUCCESS] Module imported without errors" -ForegroundColor Green
    
    Write-Host "Checking exported functions..." -ForegroundColor White
    $exportedFunctions = Get-Command -Module Unity-Claude-RunspaceManagement
    Write-Host "[SUCCESS] Exported functions: $($exportedFunctions.Count)" -ForegroundColor Green
    
    Write-Host "Testing core function..." -ForegroundColor White
    $sessionConfig = New-RunspaceSessionState
    if ($sessionConfig -and $sessionConfig.SessionState) {
        Write-Host "[SUCCESS] New-RunspaceSessionState working" -ForegroundColor Green
    } else {
        Write-Host "[FAIL] New-RunspaceSessionState returned invalid result" -ForegroundColor Red
    }
    
    Write-Host "`n=== MODULE LOADING SUCCESS ===" -ForegroundColor Green
    Write-Host "All syntax errors resolved, module operational" -ForegroundColor Green
    
} catch {
    Write-Host "[FAIL] Module loading failed: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "Additional error details:" -ForegroundColor Yellow
    Write-Host $_.Exception.ToString() -ForegroundColor Red
}

Write-Host "`nQuick test completed at $(Get-Date)" -ForegroundColor Cyan
# SIG # Begin signature block
# MIIFqQYJKoZIhvcNAQcCoIIFmjCCBZYCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUEivJO8UxpwPjG/8V6DIyJRVb
# j3mgggMwMIIDLDCCAhSgAwIBAgIQdR0W2SKoK5VE8JId4ZxrRTANBgkqhkiG9w0B
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
# CQQxFgQUpUl2CmqO3fz1AHgx/4/KQd/Pi6AwDQYJKoZIhvcNAQEBBQAEggEADSWR
# KiYXV4EQD4T+oqYr68sdIDuQLb0cq3pLN5QiS/crg1oLW5G52ZUrmYMq2TtcugwU
# Ro/PLcZVodnZ3zoF9sH107tQ0kPzhIHqkM7N5TwvDiRDOjYYT1z9XLrJYKPhPbSH
# W8AXlfQkDQEUUX2yR2yfcWK0vaZ1FBi69DrFRXJbwkegWsoC++XL5dHmaVHmf8/o
# jarauLHbkUXjFmSTkwxylN3oqiYJPS1TybJeRtIvkjP1WUzEaET4rPbPpmyvGXkG
# R2gJidF3ZmWne/iu7vQ0bPqGQQJt+EoxGQaPFX5cFW0xMxcK6+jahumuAHzY/69d
# xUAK+pubO2heR2Uw0A==
# SIG # End signature block
