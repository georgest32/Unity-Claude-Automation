# Debug-StatusKeys.ps1
# Quick debug to see what keys exist in status data
# Date: 2025-08-20

Set-Location "C:\UnityProjects\Sound-and-Shoal\Unity-Claude-Automation"

Import-Module .\Modules\Unity-Claude-SystemStatus\Unity-Claude-SystemStatus.psd1 -Force

$status = Read-SystemStatus
Write-Host "Status keys: $($status.Keys -join ', ')" -ForegroundColor Yellow

if ($status.Subsystems) {
    Write-Host "Subsystems type: $($status.Subsystems.GetType().Name)" -ForegroundColor Gray
    Write-Host "Subsystems keys: $($status.Subsystems.Keys -join ', ')" -ForegroundColor Gray
} else {
    Write-Host "Subsystems: NULL" -ForegroundColor Red
}

if ($status.subsystems) {
    Write-Host "subsystems (lowercase) type: $($status.subsystems.GetType().Name)" -ForegroundColor Gray  
    Write-Host "subsystems (lowercase) keys: $($status.subsystems.Keys -join ', ')" -ForegroundColor Gray
} else {
    Write-Host "subsystems (lowercase): NULL" -ForegroundColor Red
}
# SIG # Begin signature block
# MIIFqQYJKoZIhvcNAQcCoIIFmjCCBZYCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUifdCztdp35q2u4ay8gWJqF+L
# AsegggMwMIIDLDCCAhSgAwIBAgIQdR0W2SKoK5VE8JId4ZxrRTANBgkqhkiG9w0B
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
# CQQxFgQUG9OqMMEcRLpKu/IAkEiiGhlmkHYwDQYJKoZIhvcNAQEBBQAEggEAbwX9
# dnzf/b2ewJdXP7zzLGp92a0t5AytQmaLjPlqsOMjuF3Oq2yb0C4TRsWhf7HdnNQb
# uF3sfM3WKsnGtZCKq71BzVdp7O/0Ix756utYKHvZAIUewQWgn6cLce7xRwwHuT1T
# 2QMciIk2fbHDE96fUXT1mZWx/GDLRiyLyqHNK+KpB1Yp/05/ObyEfPuGd9F8DORK
# kWYLxRxnHZf8OfhzH2EEU9bs2lNL4UEO/n4cx8qTBlXuMSof+AuQ2EJ3gKSH3gSX
# yjaxDzfjdTGnxFWkK7kTywEOtWwp6PNJgnkUiR3HQPOOAQXEijZ8ogYarvPtfL/X
# YRlVjy74OkJ+pCIROQ==
# SIG # End signature block
