$testFile = "C:\UnityProjects\Sound-and-Shoal\Unity-Claude-Automation\ClaudeResponses\Autonomous\matching_creation_method.json"
$testContent = @{
    timestamp = (Get-Date).ToString('yyyy-MM-ddTHH:mm:ss.fffZ')
    response = "RECOMMENDATION: Continue to Day 19 - Testing file creation method"
    type = "method_test"
} | ConvertTo-Json

Write-Host "Creating file using [System.IO.File]::WriteAllText..." -ForegroundColor Yellow
[System.IO.File]::WriteAllText($testFile, $testContent)
Write-Host "File created: matching_creation_method.json" -ForegroundColor Green

Start-Sleep -Seconds 5

Write-Host "Checking if .pending file was created..." -ForegroundColor Yellow
if (Test-Path "C:\UnityProjects\Sound-and-Shoal\Unity-Claude-Automation\ClaudeResponses\Autonomous\.pending") {
    Write-Host "SUCCESS: .pending file exists!" -ForegroundColor Green
    Get-Content "C:\UnityProjects\Sound-and-Shoal\Unity-Claude-Automation\ClaudeResponses\Autonomous\.pending"
} else {
    Write-Host "FAILURE: No .pending file created" -ForegroundColor Red
}
# SIG # Begin signature block
# MIIFqQYJKoZIhvcNAQcCoIIFmjCCBZYCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUAUU4MNAQOJk+fKW0LASK+SJG
# CG+gggMwMIIDLDCCAhSgAwIBAgIQdR0W2SKoK5VE8JId4ZxrRTANBgkqhkiG9w0B
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
# CQQxFgQUHvRh8lt+eIiGTfldbikCMJ4KajYwDQYJKoZIhvcNAQEBBQAEggEAMLtm
# Q/Ik8bQ++0V19RdEvxco5KWfTNYJSDAdU/WbUJa3KJjzMDOlNIrPEFo17vhoTwnb
# BzXFlIsKcO+Kps2Gyoqcs+ayaD4/TjhcBwO7BXJSzs08edyIbf5H1uT4vPzzkTaU
# wSNGCR5qiauCnadwG/xLuah0HQ0nvaeujk6AB2jSd2OH+1/GBS3MRnfPRwqsVwnD
# hMG3BngQSxatztyjq3BraL/F7ApzGEbx5d9PUlk4D4dNKIilGDtME8WKd5QrkL4Y
# 2z23JSPGw/609O72wbpCrQmq3pjPfSVtioykO4lk0XeWqaogu8LIMFenFU6ntP5f
# ULd2pjRhSBSeLJceIw==
# SIG # End signature block
