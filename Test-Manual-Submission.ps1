# Test-Manual-Submission.ps1
# Manually test prompt submission to Claude Code CLI
# Bypass all monitoring and just test the core submission functionality
# Date: 2025-08-18

Set-Location "C:\UnityProjects\Sound-and-Shoal\Unity-Claude-Automation"

Write-Host "MANUAL CLAUDE CODE CLI SUBMISSION TEST" -ForegroundColor Cyan
Write-Host "=======================================" -ForegroundColor Cyan

# Load the module
Import-Module ".\Modules\Unity-Claude-CLISubmission.psm1" -Force

# Create test Unity errors (simulate what would be detected)
$testErrors = @(
    "Assets/Scripts/TestScript.cs(10,25): error CS1002: ; expected",
    "Assets/Scripts/TestScript.cs(15,30): error CS0246: The type or namespace name 'UnknownType' could not be found",
    "Assets/Scripts/TestScript.cs(20,15): error CS0029: Cannot implicitly convert type 'string' to 'int'"
)

Write-Host "Test 1: Generate autonomous prompt..." -ForegroundColor Yellow
$promptResult = New-AutonomousPrompt -Errors $testErrors -Context "Manual test of autonomous system"

if ($promptResult.Success) {
    Write-Host "  ✓ Prompt generated successfully" -ForegroundColor Green
    Write-Host "  Error count: $($promptResult.ErrorCount)" -ForegroundColor Gray
    Write-Host "  Prompt length: $($promptResult.Prompt.Length) characters" -ForegroundColor Gray
    
    Write-Host "" -ForegroundColor White
    Write-Host "Generated prompt preview:" -ForegroundColor Cyan
    $preview = $promptResult.Prompt.Substring(0, [Math]::Min(300, $promptResult.Prompt.Length))
    Write-Host $preview -ForegroundColor White
    Write-Host "..." -ForegroundColor Gray
    
} else {
    Write-Host "  ✗ Prompt generation failed" -ForegroundColor Red
    return
}

Write-Host "" -ForegroundColor White
Write-Host "Test 2: Check Claude Code CLI window detection..." -ForegroundColor Yellow

# Find target windows
$allProcesses = Get-Process | Where-Object { $_.MainWindowTitle -ne "" }
Write-Host "All windows with titles:" -ForegroundColor Gray
$allProcesses | ForEach-Object { 
    if ($_.MainWindowTitle -like "*Claude*" -or $_.MainWindowTitle -like "*PowerShell*") {
        Write-Host "  ✓ $($_.MainWindowTitle) (PID: $($_.Id))" -ForegroundColor Green
    } else {
        Write-Host "    $($_.MainWindowTitle) (PID: $($_.Id))" -ForegroundColor DarkGray
    }
}

Write-Host "" -ForegroundColor White
Write-Host "Test 3: Manual prompt submission..." -ForegroundColor Yellow
Write-Host "THIS WILL SUBMIT A PROMPT TO CLAUDE CODE CLI IN 5 SECONDS!" -ForegroundColor Red
Write-Host "Make sure this Claude Code CLI window is visible and active!" -ForegroundColor Yellow

for ($i = 5; $i -gt 0; $i--) {
    Write-Host "  Submitting in $i seconds..." -ForegroundColor Yellow
    Start-Sleep 1
}

Write-Host "SUBMITTING NOW..." -ForegroundColor Red
$submissionResult = Submit-PromptToClaudeCode -Prompt $promptResult.Prompt

if ($submissionResult.Success) {
    Write-Host "" -ForegroundColor White
    Write-Host "✅ SUCCESS! PROMPT SUBMITTED TO CLAUDE CODE CLI!" -ForegroundColor Green
    Write-Host "==========================================" -ForegroundColor Green
    Write-Host "Target window: $($submissionResult.TargetWindow)" -ForegroundColor White
    Write-Host "Submission time: $($submissionResult.SubmissionTime)" -ForegroundColor White
    Write-Host "Prompt length: $($submissionResult.PromptLength) characters" -ForegroundColor White
    Write-Host "" -ForegroundColor White
    Write-Host "🎯 CHECK CLAUDE CODE CLI WINDOW FOR THE AUTONOMOUS PROMPT! 🎯" -ForegroundColor Cyan
    Write-Host "" -ForegroundColor White
    Write-Host "The autonomous system IS WORKING!" -ForegroundColor Green
    Write-Host "The issue was just with the background monitoring job." -ForegroundColor Yellow
    
} else {
    Write-Host "" -ForegroundColor White
    Write-Host "❌ SUBMISSION FAILED" -ForegroundColor Red
    Write-Host "===================" -ForegroundColor Red
    Write-Host "Error: $($submissionResult.Error)" -ForegroundColor Red
    Write-Host "" -ForegroundColor White
    Write-Host "Possible issues:" -ForegroundColor Yellow
    Write-Host "1. Claude Code CLI window not found or not focused" -ForegroundColor Gray
    Write-Host "2. SendKeys not working properly" -ForegroundColor Gray
    Write-Host "3. Window focus management issue" -ForegroundColor Gray
}

Write-Host "" -ForegroundColor White
Write-Host "Press Enter to exit..." -ForegroundColor Yellow
Read-Host
# SIG # Begin signature block
# MIIFqQYJKoZIhvcNAQcCoIIFmjCCBZYCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUi1FJ6BQeuJgHLz6cyQukUnvG
# h+igggMwMIIDLDCCAhSgAwIBAgIQdR0W2SKoK5VE8JId4ZxrRTANBgkqhkiG9w0B
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
# CQQxFgQUx8yPFgKnsL1cbFotomf1SMYywrcwDQYJKoZIhvcNAQEBBQAEggEAPMFE
# nK7kktBOtuj/4YjBbeOTyB9H/cQ4KsUIc88OJZZHN83uKXYPQAH/kdlP2J6q3vqV
# xYnx1dYVoBo6HmbnFSy9i2kfTABLbHScoP+8tAi35MRypjkDAyHS1eKQXMJbumhk
# /o+DOdIpi0duaeGgl0GWNREC8aRjKsaoSJ778c3o4Da5CFFQlVTWOXE89yiPw4Ep
# dEcZi87kZa4xCSyurv1z5NucrSRrp6+yjxWA2kPYoQHSkkjyiVRyPmi7uxOv2cWS
# ATSUQw6TA3imZBHMwuwonelvPMl9jNGR1ckH+N2JlMJFJ0o789oufff9/Ici9LIf
# eivRTNPMsOjfVa4rsw==
# SIG # End signature block
