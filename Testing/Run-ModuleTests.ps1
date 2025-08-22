# Run-ModuleTests.ps1
# Quick test runner for Unity-Claude modules

Write-Host "`n================================" -ForegroundColor Cyan
Write-Host " Unity-Claude Module Test Suite" -ForegroundColor Cyan
Write-Host "================================`n" -ForegroundColor Cyan

# Run the test suite
$testScript = Join-Path $PSScriptRoot "Test-UnityClaudeModules.ps1"

if (Test-Path $testScript) {
    Write-Host "Starting module tests...`n" -ForegroundColor Yellow
    
    # Run with report generation
    & $testScript -GenerateReport -Verbose:$false
    
    $exitCode = $LASTEXITCODE
    
    if ($exitCode -eq 0) {
        Write-Host "`nâœ" All tests passed!" -ForegroundColor Green
    } else {
        Write-Host "`nFAILED $exitCode test(s) failed" -ForegroundColor Red
        Write-Host "Check the generated HTML report for details" -ForegroundColor Yellow
    }
} else {
    Write-Host "Test script not found: $testScript" -ForegroundColor Red
    exit 1
}

Write-Host "`nPress any key to exit..."
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")

# SIG # Begin signature block
# MIIFqQYJKoZIhvcNAQcCoIIFmjCCBZYCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUY8ubu/s4eoSqFqKqN6HC5JmO
# tX2gggMwMIIDLDCCAhSgAwIBAgIQdR0W2SKoK5VE8JId4ZxrRTANBgkqhkiG9w0B
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
# CQQxFgQU43y/w6RiybJENvkCOfbbtxfBtkswDQYJKoZIhvcNAQEBBQAEggEATlAs
# oXDdQj9NjwDwmAzzhQXyDzyIRmtfV/RwSzWCBWHi9RvDJd4l8PfYUMGntA2RGXns
# NlX05E0jSSCl42jteR57p4WJ+Yi3Xd1fOj2N4JHYb6xSVY7WxuXXzomXShOAQFMW
# 1rxllo28r4Jd4vnRaJGw7R/+xuyrqI4+RdcvjG2dLr6MtkpBhi8CxnQhfPpFZ0Yw
# omHDEA4jeTn+9xzPN0MS7p95zMRXYg+YsCs/IhaxUKp+8czIfC3/vOHFPUBhWv8D
# aXCXP7uU0L8K+GeryiO3JlUwUJIz0JXEhvfkoacly7RM/uGE0J/tU7I6Sr+/L+4F
# Oq+D2aEu5BdlIEVX7Q==
# SIG # End signature block
