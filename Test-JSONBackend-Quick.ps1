# Quick test of JSON backend functionality
Import-Module './Modules/Unity-Claude-Learning/Unity-Claude-Learning.psm1' -Force -DisableNameChecking

Write-Host "Testing JSON backend..." -ForegroundColor Yellow

# Test adding a pattern
$pattern1 = Add-ErrorPattern -ErrorMessage "CS0246 error test" -Fix "using UnityEngine;" -Verbose
Write-Host "Pattern 1: $pattern1" -ForegroundColor Cyan

# Test string similarity  
$similarity = Get-StringSimilarity -String1 "test" -String2 "best"
Write-Host "Similarity: $similarity" -ForegroundColor Cyan

# Check configuration
$config = Get-LearningConfig
Write-Host "Storage Backend: $($config.StorageBackend)" -ForegroundColor Green

Write-Host "Test completed!" -ForegroundColor Green
# SIG # Begin signature block
# MIIFqQYJKoZIhvcNAQcCoIIFmjCCBZYCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUI02dtcqIKjuzFC3vVQRYDYXl
# 3CmgggMwMIIDLDCCAhSgAwIBAgIQdR0W2SKoK5VE8JId4ZxrRTANBgkqhkiG9w0B
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
# CQQxFgQUQGbvbmbUNx3DVK3KilliCDIo7QwwDQYJKoZIhvcNAQEBBQAEggEAcJJB
# MXBOMw7kWynrzJIvzlhw+brzjyTPMKDUSC0UpVJ0l/boefUM+QnM4yvx0EEJzvmz
# uVmOi4QvNU+7MAP+9k+a13avPdPzK0/GaN15gnBa2H6EJYv5/iPrTug5sulYl6au
# ffGPTnihHb/90k7KtC/bQa+Il84xVpnN8WrMEPN9wOGrhND1VMnjxR4cFxbzIm5v
# f9xDKIwSyMwZtk9ZFU2iSWLrV3rUWRWKe3LhN9GfTVTRco6fR5T1s8xbEUIrhkzx
# fnKtT+Ku8J6kiMSlwP8BZytXOSB7+yd+Weq4eYcQ9xveUnfE0P3ao1Cvz8IFCDiC
# ryIJiVVF/mRHUw5dvg==
# SIG # End signature block
