$testFile = "C:\UnityProjects\Sound-and-Shoal\Unity-Claude-Automation\ClaudeResponses\Autonomous\systemio_final_test.json"

# Create exactly matching format for the regex pattern
$testContent = @{
    timestamp = (Get-Date).ToString('yyyy-MM-ddTHH:mm:ss.fffZ')
    response = "RECOMMENDED: CONTINUE - Proceed to Day 19 development phase"
    type = "recommendation"
    source = "systemio_final_test"
} | ConvertTo-Json

Write-Host "Creating file using [System.IO.File]::WriteAllText (exact self-test method)..." -ForegroundColor Yellow
Write-Host "Content: RECOMMENDED: CONTINUE - Proceed to Day 19 development phase" -ForegroundColor Cyan
[System.IO.File]::WriteAllText($testFile, $testContent)
Write-Host "File created: systemio_final_test.json" -ForegroundColor Green

Write-Host "This should match the regex pattern: RECOMMENDED:\s*(CONTINUE)\s*-\s*(.*)" -ForegroundColor Magenta
# SIG # Begin signature block
# MIIFqQYJKoZIhvcNAQcCoIIFmjCCBZYCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUi26gvDmqr+NGnNoeNAigORN7
# C6igggMwMIIDLDCCAhSgAwIBAgIQdR0W2SKoK5VE8JId4ZxrRTANBgkqhkiG9w0B
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
# CQQxFgQU3bZALseReM1U2ZrP00Kq6Omrc5QwDQYJKoZIhvcNAQEBBQAEggEAoAFL
# XAlDhjT7UdaioXgKGHHiIoFNKfZY5qRsygEmvnrcj7Ed+EbZ/627hVl86t3Dpjfg
# qeEaUk8JiPCDHcUPXxN61XwauotXJU7Qb1WVATBELtcy28z6cVRCH78R0K2Kx7YZ
# xzkOk8rvJkQXGVzrKl9/BlZnarNLafHc323/F6e1Ohv/7d74G6W0/yhZOlaFoJLC
# dlPinL61+zukHxamuK1Lz7F87xin9B8X3zHs3GZkOdN2ZzNI0AGxnw7tNGtmdNbW
# +UYZErSKaVo086KO3XNQOQONST25RWKbutK643EJKIwZn2epuNcX5rS06swlEGAX
# xQTaFn2OzZQ6MdNghw==
# SIG # End signature block
