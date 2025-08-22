# Test-Manual-Simple.ps1
# Simple manual test with ASCII-only PowerShell 5.1 syntax
# Date: 2025-08-18

Set-Location "C:\UnityProjects\Sound-and-Shoal\Unity-Claude-Automation"

Write-Host "MANUAL CLAUDE CODE CLI SUBMISSION TEST" -ForegroundColor Cyan
Write-Host "=======================================" -ForegroundColor Cyan

# Load the module
Import-Module ".\Modules\Unity-Claude-CLISubmission.psm1" -Force

# Create test Unity errors
$testErrors = @(
    "Assets/Scripts/TestScript.cs(10,25): error CS1002: ; expected",
    "Assets/Scripts/TestScript.cs(15,30): error CS0246: The type or namespace name 'UnknownType' could not be found"
)

Write-Host "Test 1: Generate autonomous prompt..." -ForegroundColor Yellow
$promptResult = New-AutonomousPrompt -Errors $testErrors -Context "Manual test"

if ($promptResult.Success) {
    Write-Host "  Prompt generated successfully" -ForegroundColor Green
    Write-Host "  Error count: $($promptResult.ErrorCount)" -ForegroundColor Gray
    Write-Host "  Prompt length: $($promptResult.Prompt.Length) characters" -ForegroundColor Gray
} else {
    Write-Host "  Prompt generation failed" -ForegroundColor Red
    return
}

Write-Host "" -ForegroundColor White
Write-Host "Test 2: Check for target windows..." -ForegroundColor Yellow
$claudeProcess = Get-Process | Where-Object { $_.MainWindowTitle -like "*Claude*" -or $_.MainWindowTitle -like "*PowerShell*" }

if ($claudeProcess) {
    Write-Host "  Found target windows:" -ForegroundColor Green
    foreach ($proc in $claudeProcess) {
        Write-Host "    $($proc.MainWindowTitle)" -ForegroundColor Gray
    }
} else {
    Write-Host "  No suitable windows found" -ForegroundColor Red
}

Write-Host "" -ForegroundColor White
Write-Host "Test 3: SUBMITTING PROMPT TO CLAUDE CODE CLI..." -ForegroundColor Yellow
Write-Host "MAKE SURE THIS WINDOW IS ACTIVE!" -ForegroundColor Red

Write-Host "Submitting in 3 seconds..." -ForegroundColor Yellow
Start-Sleep 1
Write-Host "Submitting in 2 seconds..." -ForegroundColor Yellow
Start-Sleep 1
Write-Host "Submitting in 1 second..." -ForegroundColor Yellow
Start-Sleep 1

Write-Host "SUBMITTING NOW..." -ForegroundColor Red
$submissionResult = Submit-PromptToClaudeCode -Prompt $promptResult.Prompt

if ($submissionResult.Success) {
    Write-Host "" -ForegroundColor White
    Write-Host "SUCCESS! PROMPT SUBMITTED!" -ForegroundColor Green
    Write-Host "Target: $($submissionResult.TargetWindow)" -ForegroundColor White
    Write-Host "Length: $($submissionResult.PromptLength) characters" -ForegroundColor White
    Write-Host "" -ForegroundColor White
    Write-Host "CHECK CLAUDE CODE CLI FOR THE PROMPT!" -ForegroundColor Cyan
} else {
    Write-Host "" -ForegroundColor White
    Write-Host "SUBMISSION FAILED" -ForegroundColor Red
    Write-Host "Error: $($submissionResult.Error)" -ForegroundColor Red
}

Write-Host "" -ForegroundColor White
Write-Host "Press Enter to exit..." -ForegroundColor Yellow
Read-Host
# SIG # Begin signature block
# MIIFqQYJKoZIhvcNAQcCoIIFmjCCBZYCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUietG9mvK/YxaY1R17Bz8rLfk
# Vd2gggMwMIIDLDCCAhSgAwIBAgIQdR0W2SKoK5VE8JId4ZxrRTANBgkqhkiG9w0B
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
# CQQxFgQUy3Nns21YqRWBL2WwCM8gLYbr+jQwDQYJKoZIhvcNAQEBBQAEggEAr5/c
# saFEaG+I93tPkwUmKAHAKlPvHcwKehybg35mYCUX8+aPNOGP32pr6PtRJxkC0EVh
# NY0ivQPb7rbDpyLL7NI4qh7x1KzQ2ctmGWqGNBtpJNDaBtY1qG6GX5D1XdifHQts
# NPHOmq/Cm792io45QwAfEU3KnePeKIKY/cqHRrwxliLtcZon7vckUhcPdOGWBt7t
# Km5/MziMFyYOpGP7bN4BF3mmOv7yT2POBU3ho1/Z9uBhHvUsG9f20Pj4nNSHbHBi
# T1VNFlPazLobR5JBHh/gK17XquSSmWNSh+ySNXSHqdHbqN2Z2LmJxIEmuSRNkLZt
# v/ybAXA3Le+soNdUAQ==
# SIG # End signature block
