# Test-ClaudeSubmission.ps1
# Quick test to verify Claude submission is working

Write-Host "`n═══════════════════════════════════════" -ForegroundColor Cyan
Write-Host " Testing Claude Auto-Submission" -ForegroundColor Cyan
Write-Host "═══════════════════════════════════════`n" -ForegroundColor Cyan

# Create a test error log
$testContent = @"
# Unity-Claude Test Error Report
Generated: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')

## Test Errors
\`\`\`
Assets\Scripts\Test.cs(10,5): error CS0246: The type or namespace name 'TestType' could not be found
Assets\Scripts\Test.cs(20,10): error CS0117: 'GameObject' does not contain a definition for 'TestMethod'
NullReferenceException: Object reference not set to an instance of an object
  at TestScript.Update() in Assets\Scripts\TestScript.cs:42
\`\`\`

## System Info
- Unity: 2021.1.14f1
- Project: Sound-and-Shoal
- This is a TEST submission to verify Claude integration

Please respond with: "Claude submission test successful!"
"@

# Save test log
$testLog = Join-Path $env:TEMP "test_claude_submission.md"
$testContent | Set-Content -Path $testLog

Write-Host "Test log created: $testLog" -ForegroundColor Gray
Write-Host "`nSubmitting test to Claude..." -ForegroundColor Yellow

# Try to submit (using auto version that actually submits)
& (Join-Path $PSScriptRoot 'Submit-ErrorsToClaude-Auto.ps1') `
    -ErrorLogPath $testLog `
    -WaitForResponse `
    -TimeoutSeconds 30

Write-Host "`n═══════════════════════════════════════" -ForegroundColor Green
Write-Host " Test Complete!" -ForegroundColor Green
Write-Host "═══════════════════════════════════════" -ForegroundColor Green

Write-Host "`nIf you saw 'Claude submission test successful!' then it's working!" -ForegroundColor Cyan

# Cleanup
Remove-Item $testLog -Force -ErrorAction SilentlyContinue
# SIG # Begin signature block
# MIIFqQYJKoZIhvcNAQcCoIIFmjCCBZYCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUPpdoWoVBsW8r6GKJlMrOdDGA
# rCugggMwMIIDLDCCAhSgAwIBAgIQdR0W2SKoK5VE8JId4ZxrRTANBgkqhkiG9w0B
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
# CQQxFgQUYJ+om4ehQltrTrc/HT1LRn4od9MwDQYJKoZIhvcNAQEBBQAEggEAnSY/
# bpSTavsqF5ypvuRY/3ZlzR+Z8dWv8FYFxzQSexhJXpG92c25PttHxhs+y+dU0+TJ
# CJfg/+5P8rYoB22UI2gvqmIXzH07qzrcrlXRz5jwifvahsRrWpkQ8e6rdybsVihJ
# zuVYov6XeNbAnGja8B4WvAZrWmrM5jPpTRwIzBjFNonJ3xndJL9C8BB63tr4hTqT
# 088XS94i8XeFV/DdVXmr3Ef6uksrI5/9jWqFNbEFHueizDZvZB2HJuS587AlYDbF
# VeRZgZzuyDJr3yKkvkQpBlONuU7D6vTRR9+UfhKVtzOGJA1VUcQRi9a7LK8vH1x8
# udQ5ppIW1PfdhrbsXw==
# SIG # End signature block
