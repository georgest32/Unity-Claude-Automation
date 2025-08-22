# Submit-ErrorsToClaude-Headless.ps1
# Uses Claude Code's headless mode for true background automation
# NO WINDOW SWITCHING REQUIRED!

[CmdletBinding()]
param(
    [string]$ErrorLogPath,
    [string]$ErrorType = 'Last',
    [switch]$StreamOutput,
    [switch]$JsonOutput,
    [string]$OutputFile
)

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host " Claude Headless Automation" -ForegroundColor Cyan
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

# Determine output format
$outputFormat = ""
if ($JsonOutput) {
    $outputFormat = "--output-format stream-json"
} elseif ($StreamOutput) {
    $outputFormat = "--output-format stream"
}

try {
    Write-Host "Submitting to Claude in headless mode..." -ForegroundColor Cyan
    Write-Host "(This runs completely in the background!)" -ForegroundColor Green
    Write-Host ""
    
    # Save prompt to temp file for piping
    $tempFile = [System.IO.Path]::GetTempFileName()
    $prompt | Set-Content -Path $tempFile -Encoding UTF8
    
    # Build command
    $claudeCmd = "type `"$tempFile`" | claude -p `"Please analyze and fix these errors`" $outputFormat"
    
    if ($OutputFile) {
        $claudeCmd += " > `"$OutputFile`""
        Write-Host "Output will be saved to: $OutputFile" -ForegroundColor Yellow
    }
    
    Write-Host "Executing: $claudeCmd" -ForegroundColor Gray
    Write-Host ""
    
    # Execute the command
    $result = cmd /c $claudeCmd 2>&1
    
    # Display result if not redirected
    if (-not $OutputFile) {
        Write-Host "Claude's Response:" -ForegroundColor Cyan
        Write-Host "=================" -ForegroundColor Cyan
        Write-Host $result -ForegroundColor White
    }
    
    # Save to timestamped file
    $responseFile = Join-Path $PSScriptRoot "ClaudeResponse_$(Get-Date -Format 'yyyyMMdd_HHmmss').md"
    $result | Set-Content -Path $responseFile
    
    Write-Host ""
    Write-Host "Response saved to: $responseFile" -ForegroundColor Green
    
    # Clean up temp file
    Remove-Item $tempFile -Force -ErrorAction SilentlyContinue
    
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Green
    Write-Host " Background Submission Complete!" -ForegroundColor Green
    Write-Host "========================================" -ForegroundColor Green
    
} catch {
    Write-Host "Error during submission: $_" -ForegroundColor Red
    
    # Fallback
    $prompt | Set-Clipboard
    Write-Host "Prompt copied to clipboard as fallback" -ForegroundColor Yellow
}
# SIG # Begin signature block
# MIIFqQYJKoZIhvcNAQcCoIIFmjCCBZYCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUsGhD+LG0+CyKbKwlyXDQQdbm
# K7KgggMwMIIDLDCCAhSgAwIBAgIQdR0W2SKoK5VE8JId4ZxrRTANBgkqhkiG9w0B
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
# CQQxFgQUoQ1P8a5LiFFSsTTjkuFdcVVARP8wDQYJKoZIhvcNAQEBBQAEggEAovbw
# LjintKaTFXhzyqjDCGZfUsSWi3nuinP6Abu938duHpLPRs71M4BsP+BEogl6+u42
# eIE0kA4ZJqJGajRdLFg1/EXywSP8Do0WOB0ZbeKP5NE0LkDaMs+j3OVo4FL5eiF/
# T5uupsahMIdk6thARqlQO9ZXkTyZ5PD5fa1seolC7+dxEuHfS0wP/URC8HrGWUdt
# LkjtkzQL6MZ0MKYLKvwmjzFCmrTPRaGFkmusuxcJvmDUGANJNnOs+ChPbyW0vP0f
# v/WyptNQXuATILVzTzJ4GLkiHhRolzE3iPp/LcCDBu0HiwBAmjNTqIhDV+UqMprP
# F8F36x0t3UWl93vP+w==
# SIG # End signature block
