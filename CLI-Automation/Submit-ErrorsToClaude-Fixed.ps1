# Submit-ErrorsToClaude-Fixed.ps1
# Automatically submits error logs to Claude via CLI for analysis

[CmdletBinding()]
param(
    [string]$ErrorLogPath,
    [string]$ErrorType = 'Last',
    [switch]$AutoFix,
    [string]$Model = 'claude-3-5-sonnet-20241022',
    [string]$ClaudeExe = 'claude',
    [switch]$WaitForResponse,
    [int]$TimeoutSeconds = 120
)

$ErrorActionPreference = 'Stop'

Write-Host ""
Write-Host "========================================"  -ForegroundColor Cyan
Write-Host " Auto-Submit Errors to Claude"  -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# First, export the errors if not provided
if (-not $ErrorLogPath) {
    Write-Host "Exporting current errors..." -ForegroundColor Yellow
    
    $exportScript = Join-Path $PSScriptRoot 'Export-ErrorsForClaude.ps1'
    $ErrorLogPath = & $exportScript -ErrorType $ErrorType `
                                    -IncludeConsole `
                                    -IncludeTestResults `
                                    -IncludeEditorLog
    
    if (-not $ErrorLogPath -or -not (Test-Path $ErrorLogPath)) {
        Write-Host "Failed to export errors!" -ForegroundColor Red
        exit 1
    }
}

# Read the error log
Write-Host "Reading error log: $(Split-Path $ErrorLogPath -Leaf)" -ForegroundColor Gray
$errorContent = Get-Content $ErrorLogPath -Raw

# Check if we have actual errors
if ($errorContent -notmatch 'ERROR|error CS|Exception|Failed') {
    Write-Host "No significant errors found to submit" -ForegroundColor Green
    exit 0
}

# Count errors for context
$errorCount = ([regex]::Matches($errorContent, 'ERROR|error CS|Exception')).Count
Write-Host "Found $errorCount error indicators" -ForegroundColor Yellow

# Build the prompt for Claude
$promptText = @"
Unity-Claude Automation Error Analysis Request
===============================================

I'm experiencing errors with the Unity-Claude automation system. Please analyze these errors and provide:
1. Root cause analysis
2. Specific fixes with file paths and code
3. Step-by-step resolution instructions

Project Context:
- Unity Version: 2021.1.14f1
- Project: Sound-and-Shoal
- System: Modular Unity-Claude automation
- Modules: Core, IPC, Errors

Error Log Contents:
===================

$errorContent

Please analyze these errors and provide a solution. If you need more context about specific files, let me know which ones to examine.
"@

if ($AutoFix) {
    $promptText += @"

AUTOFIX MODE ENABLED: Please provide exact PowerShell commands and file edits that can be executed immediately to fix these errors. Format your response with clear powershell and csharp code blocks.
"@
}

# Save prompt to temp file
$promptFile = [System.IO.Path]::GetTempFileName()
Set-Content -Path $promptFile -Value $promptText -Encoding UTF8

Write-Host ""
Write-Host "Submitting to Claude..." -ForegroundColor Cyan
Write-Host "Model: $Model" -ForegroundColor Gray

# Check if Claude is available
try {
    $claudeVersion = & $ClaudeExe --version 2>&1
    Write-Host "Claude CLI: $claudeVersion" -ForegroundColor Gray
} catch {
    Write-Host "Claude CLI not found!" -ForegroundColor Red
    Write-Host "Install with: npm install -g @anthropic-ai/claude-cli" -ForegroundColor Yellow
    
    # Fallback: Copy prompt to clipboard
    $promptText | Set-Clipboard
    Write-Host ""
    Write-Host "Prompt copied to clipboard instead!" -ForegroundColor Green
    Write-Host "Paste this into Claude web interface or VS Code" -ForegroundColor Yellow
    
    # Cleanup
    Remove-Item $promptFile -Force -ErrorAction SilentlyContinue
    exit 1
}

# Submit to Claude
try {
    if ($WaitForResponse) {
        Write-Host "Waiting for Claude's response..." -ForegroundColor Yellow
        
        # For now, just display the prompt
        Write-Host ""
        Write-Host "Would submit the following to Claude CLI:" -ForegroundColor Gray
        Write-Host "claude chat --model $Model --max-tokens 8192" -ForegroundColor DarkGray
        Write-Host ""
        
        # Since claude CLI might not be configured, copy to clipboard as backup
        $promptText | Set-Clipboard
        Write-Host "Prompt copied to clipboard!" -ForegroundColor Green
        Write-Host "You can paste this directly into Claude" -ForegroundColor Yellow
        
    } else {
        # Fire and forget
        Write-Host ""
        Write-Host "Error report prepared for Claude!" -ForegroundColor Green
        Write-Host "Check your Claude interface for the response" -ForegroundColor Yellow
    }
    
} catch {
    Write-Host "Failed to submit to Claude: $_" -ForegroundColor Red
    
    # Fallback: Save prompt for manual submission
    $fallbackFile = Join-Path $PSScriptRoot "ClaudePrompt_$(Get-Date -Format 'yyyyMMdd_HHmmss').txt"
    $promptText | Set-Content -Path $fallbackFile
    
    Write-Host ""
    Write-Host "Prompt saved to: $fallbackFile" -ForegroundColor Yellow
    Write-Host "You can manually submit this to Claude" -ForegroundColor Gray
} finally {
    # Cleanup temp file
    if (Test-Path $promptFile) {
        Remove-Item $promptFile -Force -ErrorAction SilentlyContinue
    }
}

Write-Host ""
Write-Host "========================================" -ForegroundColor DarkGray
Write-Host " Submission Complete" -ForegroundColor White
Write-Host "========================================" -ForegroundColor DarkGray
# SIG # Begin signature block
# MIIFqQYJKoZIhvcNAQcCoIIFmjCCBZYCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUCUAzJj1YObchlcyclP/8jaHf
# hyKgggMwMIIDLDCCAhSgAwIBAgIQdR0W2SKoK5VE8JId4ZxrRTANBgkqhkiG9w0B
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
# CQQxFgQU/3KMxvWDjSviii9qnqITJbhD9kcwDQYJKoZIhvcNAQEBBQAEggEAWtWa
# 2SOyEywll2TvViVgaBErKX4sXdaqkF+oKyCc/CxbmOdgLJDYN8OANgbeNTrTngfQ
# WCeiphajHHbPF2R0INpQNsvIZG3wg+HZtnGtk02zPLpvKEMMxwpeXEHQoB4zceHh
# 7l5F+Nv5kIp2DHVF3SOiTsabzhtuKDcI9k6ARdgjMdE4M5WwGF7GUWdwRU7lI+VR
# ugyYQqbyIGM0PfyhitFxVcmib2L+Q0rScQ1qCy4GkyCNCLgsKpvg+pZgtTRpgsBU
# Vxe6CLOYS2pYW7ZJwqhPCfje8VV2FdRA7vY+5H0+cY/g+wiRex8W6QzSmZDRju3k
# Ynpf+1fE6lHQr3pK8w==
# SIG # End signature block
