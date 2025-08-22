$testFile = "C:\UnityProjects\Sound-and-Shoal\Unity-Claude-Automation\ClaudeResponses\Autonomous\correct_format_systemio.json"
$testContent = @{
    timestamp = (Get-Date).ToString('yyyy-MM-ddTHH:mm:ss.fffZ')
    response = "RECOMMENDED: CONTINUE - Proceed to Day 19 development phase"
    type = "recommendation"
    source = "systemio_creation_test"
} | ConvertTo-Json

Write-Host "Creating file using [System.IO.File]::WriteAllText (same as self-test)..." -ForegroundColor Yellow
[System.IO.File]::WriteAllText($testFile, $testContent)
Write-Host "File created: correct_format_systemio.json" -ForegroundColor Green

Write-Host "This file should be detected and processed with actionable recommendations!" -ForegroundColor Cyan
# SIG # Begin signature block
# MIIFqQYJKoZIhvcNAQcCoIIFmjCCBZYCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQULnnIzFQtMWQk8MKNakuxbf6L
# sO6gggMwMIIDLDCCAhSgAwIBAgIQdR0W2SKoK5VE8JId4ZxrRTANBgkqhkiG9w0B
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
# CQQxFgQUIy7a2N1B6tvSM2fNOxKeOCKzqfowDQYJKoZIhvcNAQEBBQAEggEAGT9Y
# JXzQsOFWDQNyVQ1uLvl46gYCFMQnwopX6o14CVGILcdFa3l3IcA6Tsdnu5WdjtHe
# NRqx2BNlHpcdbOO5FUzt/gljROrSYc1Riia2nyDqxwDcxZwn4S4re0FuTaXBx7vA
# 2jdtvbgzTktI9C6bYGjRhNAafw4FrJy9i+nLkCVYFTyW33Gjv50yB4HafOuTvqJT
# YDZGFTfl0uLrFgP8lEZ+ok2vkx1B2nzJH/dzZIIMuFPp7huKHcH/FDCq6zj8yK80
# WIIt1GwcKXnoH1HCEnAIc98HYLm+tUp6qfovo9IclqRMMnScRDeco+uKXnbn8MBE
# vEnErmypa6seJMSF3g==
# SIG # End signature block
