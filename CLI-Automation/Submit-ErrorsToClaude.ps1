# Submit-ErrorsToClaude.ps1
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

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host " Auto-Submit Errors to Claude" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan

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
$prompt = @"
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

$(if ($AutoFix) { @"

AUTOFIX MODE ENABLED: Please provide exact PowerShell commands and file edits that can be executed immediately to fix these errors. Format your response with clear ```powershell and ```csharp code blocks.
"@ })

Error Log Contents:
===================

$errorContent

Please analyze these errors and provide a solution. If you need more context about specific files, let me know which ones to examine.
"@

# Save prompt to temp file
$promptFile = [System.IO.Path]::GetTempFileName()
Set-Content -Path $promptFile -Value $prompt -Encoding UTF8

Write-Host "`nSubmitting to Claude..." -ForegroundColor Cyan
Write-Host "Model: $Model" -ForegroundColor Gray

# Build Claude command
$claudeArgs = @(
    'chat',
    '--model', $Model,
    '--max-tokens', '8192'
)

# Check if Claude is available
try {
    $claudeVersion = & $ClaudeExe --version 2>&1
    Write-Host "Claude CLI: $claudeVersion" -ForegroundColor Gray
} catch {
    Write-Host "Claude CLI not found!" -ForegroundColor Red
    Write-Host "Install with: npm install -g @anthropic-ai/claude-cli" -ForegroundColor Yellow
    
    # Fallback: Copy prompt to clipboard
    $prompt | Set-Clipboard
    Write-Host "`nPrompt copied to clipboard instead!" -ForegroundColor Green
    Write-Host "Paste this into Claude web interface or VS Code" -ForegroundColor Yellow
    exit 1
}

# Submit to Claude
try {
    if ($WaitForResponse) {
        Write-Host "Waiting for Claude's response..." -ForegroundColor Yellow
        
        # Create a job to handle timeout
        $job = Start-Job -ScriptBlock {
            param($exe, $args, $prompt)
            $prompt | & $exe $args
        } -ArgumentList $ClaudeExe, $claudeArgs, $prompt
        
        $completed = Wait-Job -Job $job -Timeout $TimeoutSeconds
        
        if ($completed) {
            $response = Receive-Job -Job $job
            Remove-Job -Job $job
            
            # Save response
            $responseFile = Join-Path $PSScriptRoot "ClaudeResponse_$(Get-Date -Format 'yyyyMMdd_HHmmss').md"
            $response | Out-String | Set-Content -Path $responseFile
            
            Write-Host "`n========================================" -ForegroundColor Green
            Write-Host " Claude's Response Received!" -ForegroundColor Green
            Write-Host "========================================`n" -ForegroundColor Green
            
            # Show first part of response
            $preview = ($response | Out-String).Substring(0, [Math]::Min(500, $response.Length))
            Write-Host $preview -ForegroundColor White
            Write-Host "`n... (response saved to: $responseFile)" -ForegroundColor Gray
            
            # Parse for immediate actions if AutoFix
            if ($AutoFix -and $response -match '```powershell(.*?)```') {
                Write-Host "`n=== Auto-Fix Commands Found ===" -ForegroundColor Magenta
                $commands = $matches[1].Trim()
                Write-Host $commands -ForegroundColor Yellow
                
                Write-Host "`nExecute these commands? (Y/N): " -NoNewline -ForegroundColor Cyan
                $confirm = Read-Host
                
                if ($confirm -eq 'Y') {
                    Write-Host "Executing fixes..." -ForegroundColor Green
                    Invoke-Expression $commands
                }
            }
            
            return $responseFile
        } else {
            Stop-Job -Job $job
            Remove-Job -Job $job
            Write-Host "Claude response timed out after $TimeoutSeconds seconds" -ForegroundColor Yellow
        }
    } else {
        # Fire and forget - just submit
        Start-Process -FilePath $ClaudeExe -ArgumentList $claudeArgs -RedirectStandardInput $promptFile -NoNewWindow
        Write-Host "`nâœ" Error report submitted to Claude!" -ForegroundColor Green
        Write-Host "Check your Claude interface for the response" -ForegroundColor Yellow
    }
    
} catch {
    Write-Host "Failed to submit to Claude: $_" -ForegroundColor Red
    
    # Fallback: Save prompt for manual submission
    $fallbackFile = Join-Path $PSScriptRoot "ClaudePrompt_$(Get-Date -Format 'yyyyMMdd_HHmmss').txt"
    $prompt | Set-Content -Path $fallbackFile
    
    Write-Host "`nPrompt saved to: $fallbackFile" -ForegroundColor Yellow
    Write-Host "You can manually submit this to Claude" -ForegroundColor Gray
} finally {
    # Cleanup temp file
    if (Test-Path $promptFile) {
        Remove-Item $promptFile -Force -ErrorAction SilentlyContinue
    }
}

Write-Host "`n========================================" -ForegroundColor DarkGray
Write-Host " Submission Complete" -ForegroundColor White
Write-Host "========================================" -ForegroundColor DarkGray

# SIG # Begin signature block
# MIIFqQYJKoZIhvcNAQcCoIIFmjCCBZYCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUgnj9GXCl1g6TjLbxduBxf56n
# 2RigggMwMIIDLDCCAhSgAwIBAgIQdR0W2SKoK5VE8JId4ZxrRTANBgkqhkiG9w0B
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
# CQQxFgQUvcBbzZL+IMH6V6acrdfcYLHtnRgwDQYJKoZIhvcNAQEBBQAEggEAndv9
# SAsdhEOzpkHk4UfZvOL/jRA6nEah01AlQxTFnFztg1bs92l1WYIgR9GV4guU7o37
# MFgEltlMBByq54JXQFmMQrzEM0dZJImrSmOB3xHZlGjy+HTFIINzZ3A8yUwSbtM5
# A+q6ocfccHfIW/j54bXs9sgxsH+WHo/vfVp9g62fvK5vOohE+9mPJopZ618FfAVA
# HlxH40q35z7X523UcjB5a36mRofg7Y5r4uIlveTz/UvOrmSUWK/k/+bl2UAwEqGU
# HZ9vsxkiPNT9rWbjfsTBBj2JOvAXhmdzwzyYdnuC/J3GK8HeP6p/BSKDaOEVlD2J
# IHAKticXbeostrU73w==
# SIG # End signature block
