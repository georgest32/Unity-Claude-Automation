# Submit-ErrorsToClaude-Final.ps1
# Final version - uses SendKeys for Claude Code CLI which doesn't support piping
# This is the recommended approach for Claude Code v1.0.53

[CmdletBinding()]
param(
    [string]$ErrorLogPath,
    [string]$ErrorType = 'Last',
    [switch]$QuickMode,
    [switch]$AutoSubmit,
    [int]$DelayMs = 30
)

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host " Claude Code Auto-Submit (v1.0.53)" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Note: Claude Code doesn't support piped input." -ForegroundColor Yellow
Write-Host "Using SendKeys automation approach." -ForegroundColor Yellow
Write-Host ""

# Export errors if needed
if (-not $ErrorLogPath) {
    Write-Host "Exporting current errors..." -ForegroundColor Yellow
    
    $exportScript = Join-Path $PSScriptRoot 'Export-ErrorsForClaude-Fixed.ps1'
    if (Test-Path $exportScript) {
        $ErrorLogPath = & $exportScript -ErrorType $ErrorType `
                                        -IncludeConsole `
                                        -IncludeTestResults `
                                        -IncludeEditorLog
    }
}

if (-not $ErrorLogPath -or -not (Test-Path $ErrorLogPath)) {
    Write-Host "No errors to submit" -ForegroundColor Green
    exit 0
}

# Read error content
$errorContent = Get-Content $ErrorLogPath -Raw
$errorCount = ([regex]::Matches($errorContent, 'ERROR|error CS|Exception')).Count

if ($errorCount -eq 0) {
    Write-Host "No errors found" -ForegroundColor Green
    exit 0
}

Write-Host "Found $errorCount errors" -ForegroundColor Yellow

# Build prompt (keep it concise for faster typing)
if ($QuickMode) {
    $prompt = @"
Unity errors detected - please fix:

$errorContent

Provide specific code fixes.
"@
} else {
    $prompt = @"
Unity-Claude Automation Error Report
Project: Sound-and-Shoal
Errors: $errorCount issues found

$errorContent

Please analyze and provide:
1. Root cause
2. Specific fixes with code
3. File paths to modify
"@
}

# Load SendKeys
Add-Type -AssemblyName System.Windows.Forms

Write-Host ""
Write-Host "INSTRUCTIONS:" -ForegroundColor Yellow
Write-Host "1. Make sure Claude Code chat is open in the next window" -ForegroundColor White
Write-Host "2. Position this window so you can Alt+Tab to Claude" -ForegroundColor White
Write-Host "3. The script will switch and start typing automatically" -ForegroundColor White
Write-Host ""

if ($AutoSubmit) {
    Write-Host "Auto-submit: ENABLED (will press Enter after typing)" -ForegroundColor Green
} else {
    Write-Host "Auto-submit: DISABLED (you'll need to press Enter manually)" -ForegroundColor Gray
}

Write-Host ""
Write-Host "Starting in 3 seconds..." -ForegroundColor Cyan
Write-Host "Press Ctrl+C to cancel" -ForegroundColor Gray

for ($i = 3; $i -gt 0; $i--) {
    Write-Host "$i..." -ForegroundColor Yellow
    Start-Sleep -Seconds 1
}

try {
    # Switch to next window (Alt+Tab)
    Write-Host "Switching to Claude Code..." -ForegroundColor Yellow
    [System.Windows.Forms.SendKeys]::SendWait("%{TAB}")
    
    # Wait for window switch
    Start-Sleep -Milliseconds 500
    
    # Clear any existing text (Ctrl+A, Delete)
    Write-Host "Clearing input field..." -ForegroundColor Gray
    [System.Windows.Forms.SendKeys]::SendWait("^a")
    Start-Sleep -Milliseconds 100
    [System.Windows.Forms.SendKeys]::SendWait("{DELETE}")
    Start-Sleep -Milliseconds 200
    
    Write-Host "Typing prompt..." -ForegroundColor Yellow
    
    # Type the prompt line by line
    $lines = $prompt -split "`n"
    $totalLines = $lines.Count
    $currentLine = 0
    
    foreach ($line in $lines) {
        $currentLine++
        
        # Progress indicator
        if ($currentLine % 5 -eq 0 -or $currentLine -eq $totalLines) {
            $percent = [Math]::Round(($currentLine / $totalLines) * 100)
            Write-Host "  Progress: $percent% ($currentLine/$totalLines lines)" -ForegroundColor Gray
        }
        
        # Escape special characters for SendKeys
        $escapedLine = $line -replace '[+^%~(){\[\]}]', '{$0}'
        
        # Send the line
        if ($escapedLine.Length -gt 0) {
            [System.Windows.Forms.SendKeys]::SendWait($escapedLine)
        }
        
        # Send Enter for new line
        [System.Windows.Forms.SendKeys]::SendWait("{ENTER}")
        
        # Small delay to prevent buffer overflow
        Start-Sleep -Milliseconds $DelayMs
    }
    
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Green
    Write-Host " ✅ Prompt Typed Successfully!" -ForegroundColor Green
    Write-Host "========================================" -ForegroundColor Green
    Write-Host ""
    
    if ($AutoSubmit) {
        Write-Host "Auto-submitting in 1 second..." -ForegroundColor Yellow
        Start-Sleep -Seconds 1
        
        # Send Enter to submit
        [System.Windows.Forms.SendKeys]::SendWait("{ENTER}")
        Write-Host "✅ Submitted to Claude!" -ForegroundColor Green
        Write-Host ""
        Write-Host "Claude is now processing your request." -ForegroundColor Cyan
    } else {
        Write-Host "Review the prompt in Claude Code" -ForegroundColor Cyan
        Write-Host "Press Enter in Claude to submit when ready" -ForegroundColor Yellow
    }
    
} catch {
    Write-Host ""
    Write-Host "❌ Error: $_" -ForegroundColor Red
    
    # Fallback to clipboard
    $prompt | Set-Clipboard
    Write-Host ""
    Write-Host "Prompt copied to clipboard as fallback!" -ForegroundColor Green
    Write-Host "Switch to Claude and paste with Ctrl+V" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "========================================" -ForegroundColor DarkGray
Write-Host " Auto-Submit Complete" -ForegroundColor White
Write-Host "========================================" -ForegroundColor DarkGray
# SIG # Begin signature block
# MIIFqQYJKoZIhvcNAQcCoIIFmjCCBZYCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQU7rCgFMJ9K9GeWJLgM/nMJ36w
# /FOgggMwMIIDLDCCAhSgAwIBAgIQdR0W2SKoK5VE8JId4ZxrRTANBgkqhkiG9w0B
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
# CQQxFgQUn1InS3K8fRbwOvJYzP9NohdbXg8wDQYJKoZIhvcNAQEBBQAEggEAht7Q
# uASjw3xDPrglNl0h83uzOHhPNuSiysNT/PgyoDlOsWhn8IMxpzQl3LIBi9hEr8mO
# wmQQTr3p2HJX/F/lStSRVdY1lG7aVvANM6A81oK5muRADQoLnX720MF0TedkQlxa
# f0kcT3M6gQTc+w8j7K0p9dJsGc4V2542rI0fAD+jw3/5f2WvcBieOSjVzbTIXWmQ
# KidjxbWVOyLvFHFhRtdbwZexGzAg7Py57EF7AmVdUcm/8FafAPOWGSNV56ygZ9Xf
# 1VuTQfEhHQFO5ExOBKG8vVWsTv1D7r7fUj8OLv/VUMixAgDPt/OwdaS9EjI60Si9
# a6Oq3Wf9TdZ8vDbFmQ==
# SIG # End signature block
