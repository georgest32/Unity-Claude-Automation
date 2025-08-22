# Submit-ErrorsToClaude-Auto.ps1
# Actually submits error logs to Claude Code CLI

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
Write-Host " Auto-Submit Errors to Claude Code"  -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# First, export the errors if not provided
if (-not $ErrorLogPath) {
    Write-Host "Exporting current errors..." -ForegroundColor Yellow
    
    $exportScript = Join-Path $PSScriptRoot 'Export-ErrorsForClaude-Fixed.ps1'
    if (Test-Path $exportScript) {
        $ErrorLogPath = & $exportScript -ErrorType $ErrorType `
                                        -IncludeConsole `
                                        -IncludeTestResults `
                                        -IncludeEditorLog
    } else {
        # Create a simple error log
        $ErrorLogPath = Join-Path $env:TEMP "error_export_$(Get-Date -Format 'yyyyMMdd_HHmmss').md"
        "# Error Log`n`nNo export script found - using test data" | Set-Content $ErrorLogPath
    }
    
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

Please analyze these errors and provide a solution.
"@

if ($AutoFix) {
    $promptText += @"

AUTOFIX MODE: Provide exact PowerShell commands and file edits that can be executed immediately.
"@
}

Write-Host ""
Write-Host "Submitting to Claude Code..." -ForegroundColor Cyan

# Create temp file for prompt
$promptFile = [System.IO.Path]::GetTempFileName()
$promptFile = [System.IO.Path]::ChangeExtension($promptFile, ".txt")
Set-Content -Path $promptFile -Value $promptText -Encoding UTF8

try {
    # Check Claude availability
    $claudeCheck = & $ClaudeExe --version 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Host "Claude Code detected: $claudeCheck" -ForegroundColor Green
        
        # Actually submit to Claude using stdin
        Write-Host "Sending prompt to Claude..." -ForegroundColor Yellow
        
        # Use Claude chat command with the prompt (without max-tokens as Claude Code doesn't support it)
        $response = $promptText | & $ClaudeExe chat --model $Model 2>&1
        
        if ($LASTEXITCODE -eq 0) {
            # Save response
            $responseFile = Join-Path $PSScriptRoot "ClaudeResponse_$(Get-Date -Format 'yyyyMMdd_HHmmss').md"
            $response | Out-String | Set-Content -Path $responseFile
            
            Write-Host ""
            Write-Host "========================================" -ForegroundColor Green
            Write-Host " Claude Response Received!" -ForegroundColor Green
            Write-Host "========================================" -ForegroundColor Green
            Write-Host ""
            
            # Show response
            Write-Host $response -ForegroundColor White
            
            Write-Host ""
            Write-Host "Full response saved to: $responseFile" -ForegroundColor Gray
            
            # Parse for code blocks if AutoFix
            if ($AutoFix) {
                $responseText = $response | Out-String
                if ($responseText -match '```powershell([\s\S]*?)```') {
                    Write-Host ""
                    Write-Host "=== PowerShell Commands Found ===" -ForegroundColor Magenta
                    $commands = $matches[1].Trim()
                    Write-Host $commands -ForegroundColor Yellow
                    
                    Write-Host ""
                    Write-Host "Execute these commands? (Y/N): " -NoNewline -ForegroundColor Cyan
                    $confirm = Read-Host
                    
                    if ($confirm -eq 'Y') {
                        Write-Host "Executing fixes..." -ForegroundColor Green
                        Invoke-Expression $commands
                    }
                }
            }
            
        } else {
            Write-Host "Claude returned an error: $response" -ForegroundColor Red
            
            # Fallback to clipboard
            $promptText | Set-Clipboard
            Write-Host ""
            Write-Host "Prompt copied to clipboard as fallback!" -ForegroundColor Yellow
            Write-Host "You can paste this into Claude web interface" -ForegroundColor Gray
        }
        
    } else {
        throw "Claude CLI check failed"
    }
    
} catch {
    Write-Host "Error submitting to Claude: $_" -ForegroundColor Red
    
    # Fallback: Copy to clipboard
    $promptText | Set-Clipboard
    Write-Host ""
    Write-Host "Prompt copied to clipboard!" -ForegroundColor Green
    Write-Host "Paste this into your Claude interface" -ForegroundColor Yellow
    
} finally {
    # Cleanup
    if (Test-Path $promptFile) {
        Remove-Item $promptFile -Force -ErrorAction SilentlyContinue
    }
}

Write-Host ""
Write-Host "========================================" -ForegroundColor DarkGray
Write-Host " Submission Process Complete" -ForegroundColor White
Write-Host "========================================" -ForegroundColor DarkGray
# SIG # Begin signature block
# MIIFqQYJKoZIhvcNAQcCoIIFmjCCBZYCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUHXsTCUgA2QWJOonZAO9KP7nA
# 3wugggMwMIIDLDCCAhSgAwIBAgIQdR0W2SKoK5VE8JId4ZxrRTANBgkqhkiG9w0B
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
# CQQxFgQULq2CcJSrqM2Ld2+xQ+5HoAG6fy0wDQYJKoZIhvcNAQEBBQAEggEAnH/C
# tZx18JC8S0D5g4DNer7x5f5+yZTcJEa/PbT4yGTfpIu8bhGVGy+JM57ypuKdyphi
# D03e/XQn1McbbWdliaQ0XGqLwLxlmgF2jeELtM9Qfg5HODfBBpePe9DvwOvWau0/
# 0eeDp0KPTUm7l28yCAQiM/DzzaikbjAvE6vCNkN9GWmK1gl6VHWUtYSaCPeIi+AX
# VWoYntobaibczZ+q2gJv8/5TnNS0oiOaU4P6bBe1FnpNgOtatfRFreHAv2gTT4h9
# q8QNUrAZHLmJv+oZR8x1QtYFf2aa2285VOCcHYqT2MKqRQko90npMDlRaA4fXJDW
# jKmb052MgRlGCM8dSw==
# SIG # End signature block
