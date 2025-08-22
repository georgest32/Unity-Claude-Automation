# Submit-ErrorsToClaude-Automated.ps1
# Fully automated error submission to Claude Code CLI

[CmdletBinding()]
param(
    [string]$ErrorLogPath,
    [string]$ErrorType = 'Last',
    [switch]$AutoFix,
    [string]$Model = 'claude-3-5-sonnet-20241022',
    [string]$ClaudeExe = 'claude',
    [int]$TimeoutSeconds = 120
)

$ErrorActionPreference = 'Stop'

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host " Automated Claude Error Submission" -ForegroundColor Cyan
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
    }
    
    if (-not $ErrorLogPath -or -not (Test-Path $ErrorLogPath)) {
        Write-Host "No errors found to submit" -ForegroundColor Green
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

# Build the prompt
$promptText = @"
Unity-Claude Automation Error Analysis

I'm experiencing errors with the Unity-Claude automation system. Please analyze these errors and provide:
1. Root cause analysis
2. Specific fixes with file paths and code
3. Step-by-step resolution instructions

Project Context:
- Unity Version: 2021.1.14f1
- Project: Sound-and-Shoal
- System: Modular Unity-Claude automation

Error Log Contents:

$errorContent

Please analyze these errors and provide a solution.
"@

if ($AutoFix) {
    $promptText += "`n`nAUTOFIX MODE: Provide exact PowerShell commands that can be executed immediately."
}

Write-Host ""
Write-Host "Submitting to Claude Code CLI..." -ForegroundColor Cyan

# Save prompt to temp file
$tempPromptFile = [System.IO.Path]::GetTempFileName()
$promptText | Set-Content -Path $tempPromptFile -Encoding UTF8

# Create a PowerShell script that will feed the prompt to claude
$submitScript = @'
param($promptFile, $model)
$prompt = Get-Content $promptFile -Raw
Write-Output $prompt | & claude chat --model $model
'@

$tempScriptFile = [System.IO.Path]::GetTempFileName()
$tempScriptFile = [System.IO.Path]::ChangeExtension($tempScriptFile, ".ps1")
$submitScript | Set-Content -Path $tempScriptFile

try {
    Write-Host "Sending to Claude (model: $Model)..." -ForegroundColor Yellow
    
    # Method 1: Try using Start-Process with input redirection
    $responseFile = [System.IO.Path]::GetTempFileName()
    
    $process = Start-Process -FilePath "pwsh.exe" `
                            -ArgumentList "-NoProfile", "-Command", "& '$tempScriptFile' -promptFile '$tempPromptFile' -model '$Model'" `
                            -RedirectStandardOutput $responseFile `
                            -RedirectStandardError "NUL" `
                            -NoNewWindow `
                            -PassThru `
                            -Wait
    
    if (Test-Path $responseFile) {
        $response = Get-Content $responseFile -Raw
        
        if ($response -and $response.Length -gt 10) {
            # Save response
            $savedResponseFile = Join-Path $PSScriptRoot "ClaudeResponse_$(Get-Date -Format 'yyyyMMdd_HHmmss').md"
            $response | Set-Content -Path $savedResponseFile
            
            Write-Host ""
            Write-Host "========================================" -ForegroundColor Green
            Write-Host " Claude Response Received!" -ForegroundColor Green
            Write-Host "========================================" -ForegroundColor Green
            Write-Host ""
            
            # Display response
            Write-Host $response -ForegroundColor White
            
            Write-Host ""
            Write-Host "Response saved to: $savedResponseFile" -ForegroundColor Gray
            
            # Parse for PowerShell commands if AutoFix
            if ($AutoFix -and $response -match '```powershell([\s\S]*?)```') {
                Write-Host ""
                Write-Host "=== PowerShell Commands Found ===" -ForegroundColor Magenta
                $commands = $matches[1].Trim()
                Write-Host $commands -ForegroundColor Yellow
                
                Write-Host ""
                Write-Host "Execute these commands automatically? (Y/N): " -NoNewline -ForegroundColor Cyan
                $confirm = Read-Host
                
                if ($confirm -eq 'Y') {
                    Write-Host "Executing fixes..." -ForegroundColor Green
                    Invoke-Expression $commands
                    Write-Host "Fixes applied!" -ForegroundColor Green
                }
            }
            
            $success = $true
        } else {
            throw "No response received from Claude"
        }
    } else {
        throw "Response file not created"
    }
    
} catch {
    Write-Host "Primary method failed: $_" -ForegroundColor Yellow
    
    # Method 2: Try using echo/type with cmd
    Write-Host "Trying alternative method..." -ForegroundColor Yellow
    
    try {
        $cmdCommand = "type `"$tempPromptFile`" | claude chat --model $Model"
        $response = cmd /c $cmdCommand 2>&1 | Out-String
        
        if ($response -and $response.Length -gt 10) {
            # Save response
            $savedResponseFile = Join-Path $PSScriptRoot "ClaudeResponse_$(Get-Date -Format 'yyyyMMdd_HHmmss').md"
            $response | Set-Content -Path $savedResponseFile
            
            Write-Host ""
            Write-Host "========================================" -ForegroundColor Green
            Write-Host " Claude Response Received!" -ForegroundColor Green
            Write-Host "========================================" -ForegroundColor Green
            Write-Host ""
            
            Write-Host $response -ForegroundColor White
            
            Write-Host ""
            Write-Host "Response saved to: $savedResponseFile" -ForegroundColor Gray
            
            $success = $true
        } else {
            throw "No response from alternative method"
        }
        
    } catch {
        Write-Host "Alternative method also failed: $_" -ForegroundColor Red
        
        # Final fallback: Save prompt for manual submission
        $fallbackFile = Join-Path $PSScriptRoot "ClaudePrompt_$(Get-Date -Format 'yyyyMMdd_HHmmss').txt"
        $promptText | Set-Content -Path $fallbackFile
        
        Write-Host ""
        Write-Host "Automated submission failed." -ForegroundColor Red
        Write-Host "Prompt saved to: $fallbackFile" -ForegroundColor Yellow
        Write-Host ""
        Write-Host "You can:" -ForegroundColor Cyan
        Write-Host "1. Copy the prompt from the file above" -ForegroundColor White
        Write-Host "2. Run: claude chat --model $Model" -ForegroundColor White
        Write-Host "3. Paste the prompt when Claude opens" -ForegroundColor White
        
        # Also copy to clipboard
        $promptText | Set-Clipboard
        Write-Host ""
        Write-Host "Prompt also copied to clipboard for convenience!" -ForegroundColor Green
    }
    
} finally {
    # Cleanup temp files
    if (Test-Path $tempPromptFile) { Remove-Item $tempPromptFile -Force -ErrorAction SilentlyContinue }
    if (Test-Path $tempScriptFile) { Remove-Item $tempScriptFile -Force -ErrorAction SilentlyContinue }
    if (Test-Path $responseFile) { Remove-Item $responseFile -Force -ErrorAction SilentlyContinue }
}

Write-Host ""
Write-Host "========================================" -ForegroundColor DarkGray
Write-Host " Automation Complete" -ForegroundColor White
Write-Host "========================================" -ForegroundColor DarkGray
# SIG # Begin signature block
# MIIFqQYJKoZIhvcNAQcCoIIFmjCCBZYCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQU6bfMK5S8aru12UNKVR3XMTwf
# gVCgggMwMIIDLDCCAhSgAwIBAgIQdR0W2SKoK5VE8JId4ZxrRTANBgkqhkiG9w0B
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
# CQQxFgQUSJ75GvvvfzFmUd8Z8fcpxTVQWzswDQYJKoZIhvcNAQEBBQAEggEArFWF
# +lNesyxHDPuLhOH46sSZDRXhIdO1lhRNs32mn2kWdoelAwtZvFmQqPTTSOqZ4zKc
# UWLsZjx6gjPfivtij/6E3UBV+AusZ/tGOjVNoi1w2CyPjtXH6gP2yojfJjz3JDvN
# 53aTDBDLq+jD9/E+1ZJSOREI9oxTvyPP++Pp5i+YMFwc0OsChKcdMfMhr83sb34B
# KUkXqEsP9h3Ffr0MhD37p6tDx8dZqi0Qstnt9GjHASTvFHz9f04+4pkmx08uaCU5
# il/Nw01plpZoSNLqaGS57XdQ/6QrRobnSf41ruY+t7mbNpSbaE/nVUnkEGgov7SQ
# UgqqjYjDXvVrVHAdRg==
# SIG # End signature block

