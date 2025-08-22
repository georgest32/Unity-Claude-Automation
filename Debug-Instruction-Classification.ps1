# Debug-Instruction-Classification.ps1
# Debug instruction classification

Write-Host "Debug Instruction Classification" -ForegroundColor Cyan
Write-Host "===============================" -ForegroundColor Cyan

# Import the module first
try {
    Import-Module "C:\UnityProjects\Sound-and-Shoal\Unity-Claude-Automation\Modules\Unity-Claude-AutonomousAgent\Unity-Claude-AutonomousAgent-Refactored.psd1" -Force
    Write-Host "Module imported successfully" -ForegroundColor Green
} catch {
    Write-Host "Module import failed: $_" -ForegroundColor Red
    exit 1
}

# Test the instruction test case
$testText = "RECOMMENDED: TEST - Please run the validation script to check functionality"

Write-Host ""
Write-Host "Test Text: $testText" -ForegroundColor Yellow
Write-Host ""

# Enable debug output
$DebugPreference = "Continue"

Write-Host "Calling Invoke-ResponseClassification for instruction text..." -ForegroundColor Cyan
$result = Invoke-ResponseClassification -ResponseText $testText -UseAdvancedTree

Write-Host ""
Write-Host "Results:" -ForegroundColor Yellow
Write-Host "  Category: $($result.Classification.Category)" -ForegroundColor Gray
Write-Host "  Confidence: $($result.Classification.Confidence)" -ForegroundColor Gray
Write-Host "  Decision Path: $($result.Classification.DecisionPath -join ' -> ')" -ForegroundColor Gray
Write-Host "  Intent: $($result.Classification.Intent)" -ForegroundColor Gray
Write-Host "  Sentiment: $($result.Classification.Sentiment)" -ForegroundColor Gray

Write-Host ""
Write-Host "Expected:" -ForegroundColor Yellow
Write-Host "  Category: Instruction" -ForegroundColor Gray
Write-Host "  Intent: ActionRequest" -ForegroundColor Gray
Write-Host "  Sentiment: Neutral" -ForegroundColor Gray

$categoryMatch = $result.Classification.Category -eq "Instruction"
$intentMatch = $result.Classification.Intent -eq "ActionRequest"
$sentimentMatch = $result.Classification.Sentiment -eq "Neutral"

Write-Host ""
Write-Host "Matches:" -ForegroundColor Yellow
Write-Host "  Category: $categoryMatch" -ForegroundColor $(if ($categoryMatch) { 'Green' } else { 'Red' })
Write-Host "  Intent: $intentMatch" -ForegroundColor $(if ($intentMatch) { 'Green' } else { 'Red' })
Write-Host "  Sentiment: $sentimentMatch" -ForegroundColor $(if ($sentimentMatch) { 'Green' } else { 'Red' })

if ($categoryMatch -and $intentMatch -and $sentimentMatch) {
    Write-Host ""
    Write-Host "SUCCESS: All conditions match" -ForegroundColor Green
} else {
    Write-Host ""
    Write-Host "FAILURE: Some conditions don't match" -ForegroundColor Red
}

Write-Host ""
Write-Host "Debug complete" -ForegroundColor Cyan
# SIG # Begin signature block
# MIIFqQYJKoZIhvcNAQcCoIIFmjCCBZYCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUXCkaWyb/742akQyx1VUGKEuO
# zO+gggMwMIIDLDCCAhSgAwIBAgIQdR0W2SKoK5VE8JId4ZxrRTANBgkqhkiG9w0B
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
# CQQxFgQUHSnTCtI2saK58mINs0kQAhdU+ccwDQYJKoZIhvcNAQEBBQAEggEAiRAw
# 68vpxh8Hg9X/5x21A6k2Q2BmC95lvB0jdhMxsu7A041Ee1x5eGgERJzRpRj0Q3dP
# mf9HmzAzuCMQVFwptE15Nq3mcB3rTIW0Hqqg7d614tHJRo8FG79T9L3SEr4NzdFi
# t4Nqc43m9Rja3rRZnwcUKC9AqOf/Nm2K2t3mEyCpdeYuqRQcOOHQ47klrN74cNfa
# p4AvTOzgCYhTlcMG5ThCURPSfNVl+/Z2E0KZ4VsowgqMBf2AuGQ3e0mM2qwYo3oa
# B4wUt7gBMjt2LWtL2r6+vdUGNuRxDMobU/c+hXgdjdooCmfL6NOE+fZM0r3KHNjK
# WQ8S0Sum5fjoOXBPxg==
# SIG # End signature block
