# Submit-ToClaude-Simple.ps1
# Simple error submission that copies to clipboard for Claude

[CmdletBinding()]
param(
    [string]$ErrorLogPath,
    [string]$ErrorType = 'Last',
    [switch]$AutoExport
)

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host " Simple Claude Error Submission" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Export errors if needed
if ($AutoExport -or -not $ErrorLogPath) {
    Write-Host "Exporting current errors..." -ForegroundColor Yellow
    
    $exportScript = Join-Path $PSScriptRoot 'Export-ErrorsForClaude-Fixed.ps1'
    if (Test-Path $exportScript) {
        $ErrorLogPath = & $exportScript -ErrorType $ErrorType `
                                        -IncludeConsole `
                                        -IncludeTestResults `
                                        -IncludeEditorLog
    }
    
    if (-not $ErrorLogPath -or -not (Test-Path $ErrorLogPath)) {
        Write-Host "No errors to export" -ForegroundColor Green
        exit 0
    }
}

# Read the error log
Write-Host "Reading: $(Split-Path $ErrorLogPath -Leaf)" -ForegroundColor Gray
$errorContent = Get-Content $ErrorLogPath -Raw

# Check for errors
$errorCount = ([regex]::Matches($errorContent, 'ERROR|error CS|Exception')).Count
if ($errorCount -eq 0) {
    Write-Host "No errors found in log" -ForegroundColor Green
    exit 0
}

Write-Host "Found $errorCount error indicators" -ForegroundColor Yellow

# Build formatted prompt
$prompt = @"
# Unity-Claude Automation Error Analysis

I need help with these Unity compilation/automation errors:

## Project Context
- Unity: 2021.1.14f1
- Project: Sound-and-Shoal
- System: Modular Unity-Claude automation

## Error Log
$errorContent

Please analyze these errors and provide:
1. Root cause analysis
2. Specific fixes with file paths
3. Step-by-step resolution
"@

# Copy to clipboard
$prompt | Set-Clipboard

Write-Host ""
Write-Host "========================================" -ForegroundColor Green
Write-Host " COPIED TO CLIPBOARD!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host ""
Write-Host "NEXT STEPS:" -ForegroundColor Yellow
Write-Host "1. The error report is now in your clipboard" -ForegroundColor White
Write-Host "2. Click in this chat window" -ForegroundColor White
Write-Host "3. Press Ctrl+V to paste" -ForegroundColor White
Write-Host "4. Press Enter to send to Claude" -ForegroundColor White
Write-Host ""
Write-Host "I'll analyze the errors and provide solutions!" -ForegroundColor Cyan

# Also save to file for reference
$promptFile = Join-Path $PSScriptRoot "ClaudePrompt_$(Get-Date -Format 'yyyyMMdd_HHmmss').txt"
$prompt | Set-Content -Path $promptFile
Write-Host "Prompt also saved to: $promptFile" -ForegroundColor Gray
# SIG # Begin signature block
# MIIFqQYJKoZIhvcNAQcCoIIFmjCCBZYCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUgVpCSuOK9str5+g5UVhtRaT1
# AOGgggMwMIIDLDCCAhSgAwIBAgIQdR0W2SKoK5VE8JId4ZxrRTANBgkqhkiG9w0B
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
# CQQxFgQUZQxaVJPleqmULIAPnvg6NqOiBDcwDQYJKoZIhvcNAQEBBQAEggEAB90t
# hURE244RepLgWQBQCI9CDIE9BGo9gtzfcTlHGQUd/LV8lFTU1+8BjleC2oix7Rue
# UmkkYYGnef8IDr9y+qlFaB344omasw3zJWXkaNK15QQZJCNeo2MmKgnak97JueA9
# TC9kVysgeGBgjwvpA/GmT3HcB7mTEsNiC4CpPl0Q4fQTAaX+h21uBDwGC7ZzWVjg
# +waNgltDgGQrJ1m/OZoasHJdrgZ8A+uRQvUiIb7Fah0XujjFoTvmZ7XU1RQkURrW
# mf1uvaZM92cqnH7XbyTFvCx5K8Q6+EIDIJLfv35VULhfk2tp8b5DwP89cpO42oyA
# Xkzw6sSbRyAgtJqaKg==
# SIG # End signature block
