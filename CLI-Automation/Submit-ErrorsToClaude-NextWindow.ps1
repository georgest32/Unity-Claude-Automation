# Submit-ErrorsToClaude-NextWindow.ps1
# Switches to next window (Claude) and types the error submission

[CmdletBinding()]
param(
    [string]$ErrorLogPath,
    [string]$ErrorType = 'Last',
    [switch]$QuickMode,  # Shorter prompt for faster typing
    [int]$DelayMs = 50    # Delay between lines (adjust if needed)
)

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host " Auto-Submit to Next Window (Claude)" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
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

# Build prompt
if ($QuickMode) {
    # Shorter version for quick typing
    $prompt = @"
Unity automation errors - please analyze and fix:

$errorContent

Provide specific fixes with code.
"@
} else {
    # Full prompt
    $prompt = @"
Unity-Claude Automation Error Analysis

Project: Sound-and-Shoal (Unity 2021.1.14f1)
System: Modular Unity-Claude automation

Errors detected ($errorCount issues):

$errorContent

Please provide:
1. Root cause analysis
2. Specific fixes with file paths and code
3. Step-by-step resolution
"@
}

# Load SendKeys
Add-Type -AssemblyName System.Windows.Forms

Write-Host "SETUP INSTRUCTIONS:" -ForegroundColor Yellow
Write-Host "1. Make sure Claude Code chat is open in the next window" -ForegroundColor White
Write-Host "2. Click in the Claude input area if needed" -ForegroundColor White
Write-Host "3. This script will switch to it and start typing" -ForegroundColor White
Write-Host ""
Write-Host "Starting in 3 seconds..." -ForegroundColor Cyan
Start-Sleep -Seconds 3

try {
    # Switch to next window (Alt+Tab)
    Write-Host "Switching to next window..." -ForegroundColor Yellow
    [System.Windows.Forms.SendKeys]::SendWait("%{TAB}")
    
    # Small delay to ensure window switch completes
    Start-Sleep -Milliseconds 500
    
    Write-Host "Typing prompt..." -ForegroundColor Yellow
    Write-Host "(This may take a moment for long error logs)" -ForegroundColor Gray
    
    # Type the prompt line by line
    $lines = $prompt -split "`n"
    $lineCount = $lines.Count
    $currentLine = 0
    
    foreach ($line in $lines) {
        $currentLine++
        
        # Show progress
        if ($currentLine % 10 -eq 0) {
            $percent = [Math]::Round(($currentLine / $lineCount) * 100)
            Write-Host "  Progress: $percent%" -ForegroundColor Gray
        }
        
        # Escape special characters for SendKeys
        # SendKeys special chars: + ^ % ~ ( ) { } [ ]
        $escapedLine = $line
        $escapedLine = $escapedLine -replace '\+', '{+}'
        $escapedLine = $escapedLine -replace '\^', '{^}'
        $escapedLine = $escapedLine -replace '%', '{%}'
        $escapedLine = $escapedLine -replace '~', '{~}'
        $escapedLine = $escapedLine -replace '\(', '{(}'
        $escapedLine = $escapedLine -replace '\)', '{)}'
        $escapedLine = $escapedLine -replace '\[', '{[}'
        $escapedLine = $escapedLine -replace '\]', '{]}'
        $escapedLine = $escapedLine -replace '\{', '{{}'
        $escapedLine = $escapedLine -replace '\}', '{}}'
        
        # Send the line
        if ($escapedLine.Length -gt 0) {
            [System.Windows.Forms.SendKeys]::SendWait($escapedLine)
        }
        
        # Send Enter for new line
        [System.Windows.Forms.SendKeys]::SendWait("{ENTER}")
        
        # Small delay between lines to prevent buffer overflow
        Start-Sleep -Milliseconds $DelayMs
    }
    
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Green
    Write-Host " Prompt Typed Successfully!" -ForegroundColor Green
    Write-Host "========================================" -ForegroundColor Green
    Write-Host ""
    Write-Host "Now press Enter in Claude to submit, or review first" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Optional: Press Enter here to auto-submit to Claude" -ForegroundColor Yellow
    $autoSubmit = Read-Host "Press Enter to submit, or 'N' to skip"
    
    if ($autoSubmit -ne 'N' -and $autoSubmit -ne 'n') {
        # Switch back to Claude window
        [System.Windows.Forms.SendKeys]::SendWait("%{TAB}")
        Start-Sleep -Milliseconds 200
        
        # Send Enter to submit
        [System.Windows.Forms.SendKeys]::SendWait("{ENTER}")
        Write-Host "Submitted to Claude!" -ForegroundColor Green
    }
    
} catch {
    Write-Host "SendKeys error: $_" -ForegroundColor Red
    
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
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUrLCEQ3haB4TYKrE+Pr22XNIo
# JsegggMwMIIDLDCCAhSgAwIBAgIQdR0W2SKoK5VE8JId4ZxrRTANBgkqhkiG9w0B
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
# CQQxFgQUW6P184eyVtCLy3FkygG70WYMQgUwDQYJKoZIhvcNAQEBBQAEggEAStFN
# Ogpd4DoJtpgynUcnoLs+hUR+atH7rKe+Tcf1ZxUD32BaG9xADI3HlFCPspydp3bw
# AgKajHn/UY6iWb41Mb/l5jiAMT10wJDDWe+h+BNWox2HdhVdXmXeiaMCLH3P0woy
# qDFZ2OEX+3Yxq/W2ac/CLkM/K4PhMETRAyaYujpCXKCAc3RjbQVNXryvk85bbDMS
# GYjOTY9bT2SnsSmTAM7o2KmN85nbxBFlV9EKpKfMcbxCXmUSreab2PuOgPauBSsv
# NflU2OEox5FRZKsoImJ0ZWsUSxAt+MKFH40+ovnMSVlj6+re4U8YZ/bvwahSAjgr
# zGIxj5DCHe4sUUqR5w==
# SIG # End signature block
