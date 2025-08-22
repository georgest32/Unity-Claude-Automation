# Test-AltTab.ps1
# Test the improved Alt+Tab window switching functionality
# Date: 2025-08-18

Set-Location "C:\UnityProjects\Sound-and-Shoal\Unity-Claude-Automation"

Write-Host "TESTING AUTONOMOUS ALT+TAB WINDOW SWITCHING" -ForegroundColor Cyan
Write-Host "===========================================" -ForegroundColor Cyan

# Load module
Import-Module ".\Modules\Unity-Claude-CLISubmission.psm1" -Force

# Create test prompt
$testErrors = @("Assets/Scripts/Test.cs(10,20): error CS1002: ; expected")
$promptResult = New-AutonomousPrompt -Errors $testErrors -Context "Alt+Tab test"

Write-Host "Test prompt generated" -ForegroundColor Green
Write-Host "This test will:" -ForegroundColor White
Write-Host "1. Try direct window focus first" -ForegroundColor Gray
Write-Host "2. Use Alt+Tab if direct focus fails" -ForegroundColor Gray
Write-Host "3. Automatically find Claude Code CLI window" -ForegroundColor Gray
Write-Host "4. Submit prompt without manual intervention" -ForegroundColor Gray

Write-Host "" -ForegroundColor White
Write-Host "TESTING AUTONOMOUS WINDOW SWITCHING..." -ForegroundColor Yellow
Write-Host "Don't touch anything - let the system handle it!" -ForegroundColor Cyan

Start-Sleep 2

$submissionResult = Submit-PromptToClaudeCode -Prompt $promptResult.Prompt

if ($submissionResult.Success) {
    Write-Host "" -ForegroundColor White
    Write-Host "SUCCESS! Autonomous window switching worked!" -ForegroundColor Green
    Write-Host "Target: $($submissionResult.TargetWindow)" -ForegroundColor White
    Write-Host "Check Claude Code CLI for the autonomous prompt!" -ForegroundColor Cyan
} else {
    Write-Host "Failed: $($submissionResult.Error)" -ForegroundColor Red
}

Write-Host "" -ForegroundColor White
Write-Host "Press Enter to exit..." -ForegroundColor Yellow
Read-Host
# SIG # Begin signature block
# MIIFqQYJKoZIhvcNAQcCoIIFmjCCBZYCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQULZOVv1u9nvWLmjbAIBunh/Dv
# GvKgggMwMIIDLDCCAhSgAwIBAgIQdR0W2SKoK5VE8JId4ZxrRTANBgkqhkiG9w0B
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
# CQQxFgQUJb9WAF2qpjPzk4VQuanhX3AvQZMwDQYJKoZIhvcNAQEBBQAEggEAFHDr
# 61UueqPG4SiNPpiQW8rdCm2yzqOoLu2byUETILXQRz0GhmXW4N3iblFlqObAfflN
# RXgPuXTNv+gMT6t4Pvsa8Q0rjYOmNgHRt7Dpa/HDv/m6sy7IerOvuQdzbNVoHvuH
# WslEpLC2sK/CODen59HgEmW0gdMYJKiG8P13gfsyQt15AL8u7bAM+OkiO8aSR6kf
# ICCOhA6cweU/nVmLmYMbu8QWiSMF2QeSx+WiBoa/REsPo/BUUCXEyzlC0n8sL5KM
# N2lXzrK/dG9qJJgCs3+PthcHmlzQ1WXzoFTcJVAvWZJMm/aIzcQmDreeC1sm2KG9
# qVypAEmdPQykYyYeEg==
# SIG # End signature block
