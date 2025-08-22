# Quick-Pattern-Test.ps1
# Test pattern matching manually to debug classification issues

$testText = "CS0246: The type or namespace could not be found. Please check your using statements."

Write-Host "Testing pattern matching for: $testText" -ForegroundColor Cyan
Write-Host ""

# Test Unity error code pattern
$unityErrorPattern = "(CS\d{4}):\s*(.+)"
if ($testText -match $unityErrorPattern) {
    Write-Host "Unity Error Pattern MATCHES:" -ForegroundColor Green
    Write-Host "  Full match: $($Matches[0])" -ForegroundColor Gray
    Write-Host "  Error code: $($Matches[1])" -ForegroundColor Gray
    Write-Host "  Error message: $($Matches[2])" -ForegroundColor Gray
} else {
    Write-Host "Unity Error Pattern DOES NOT MATCH" -ForegroundColor Red
}

# Test general error pattern
$errorPattern = "(?:error|exception|failed|failure|issue|problem):\s*(.+)"
if ($testText -match $errorPattern) {
    Write-Host "General Error Pattern MATCHES:" -ForegroundColor Green
    Write-Host "  Full match: $($Matches[0])" -ForegroundColor Gray
} else {
    Write-Host "General Error Pattern DOES NOT MATCH" -ForegroundColor Red
}

# Test instruction pattern
$instructionPattern = "(?:Please\s+|You\s+should\s+|Try\s+|Run\s+|Execute\s+)([^.]+)"
if ($testText -match $instructionPattern) {
    Write-Host "Instruction Pattern MATCHES:" -ForegroundColor Green
    Write-Host "  Full match: $($Matches[0])" -ForegroundColor Gray
} else {
    Write-Host "Instruction Pattern DOES NOT MATCH" -ForegroundColor Red
}

Write-Host ""
Write-Host "Pattern test complete" -ForegroundColor Cyan
# SIG # Begin signature block
# MIIFqQYJKoZIhvcNAQcCoIIFmjCCBZYCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUtAlCHLfj2QQfT/wNFRBUKIDa
# CpqgggMwMIIDLDCCAhSgAwIBAgIQdR0W2SKoK5VE8JId4ZxrRTANBgkqhkiG9w0B
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
# CQQxFgQUea9AYIkytl7Tqah95xlFR7rZGnMwDQYJKoZIhvcNAQEBBQAEggEAldjx
# wed2D9mT4BDt7q/kxrnzPdy6AKIN9fQXs2XA0ZwVc0WgeM9FSJ/JTxtGGgk4V6ND
# tLaCRkvaJwzkg7yF5fo3OHKJRlQY+CWq6b5gCul6yhfYrCyGqcj60VoG4D4kq5EY
# oDRRJ4owqypB4c4rAo92JqnCfNV7wFfzhZMSTEoOz+ds+n3QiTHnn5wdPPj09T7W
# NrQFfy9DEtnk64QdjJuZCAQrz5KQ1jd1pPUCWBH4a3KRHTK0//dB9EDa3scxRj9J
# v5eStzQub4nMUVko3c865q4x8jRkfeXl1on37xxF/3ICHTEZu89t6V0JLKPXRxqG
# D9h9zXuSgPVoNGzOKg==
# SIG # End signature block
