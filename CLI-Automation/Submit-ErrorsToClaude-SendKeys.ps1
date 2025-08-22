# Submit-ErrorsToClaude-SendKeys.ps1
# Automated submission using SendKeys to interact with Claude CLI

[CmdletBinding()]
param(
    [string]$ErrorLogPath,
    [string]$ErrorType = 'Last',
    [string]$Model = 'claude-3-5-sonnet-20241022'
)

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host " SendKeys Claude Submission" -ForegroundColor Cyan
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

# Build prompt (shorter for SendKeys)
$prompt = @"
Analyze these Unity automation errors and provide fixes:

$errorContent

Provide specific solutions with file paths and code.
"@

Write-Host "Starting Claude CLI in new window..." -ForegroundColor Yellow

# Start claude in a new window
$claudeProcess = Start-Process -FilePath "claude" `
                              -ArgumentList "chat", "--model", $Model `
                              -PassThru `
                              -WindowStyle Normal

# Wait for Claude to initialize
Start-Sleep -Seconds 2

# Use Windows SendKeys via COM
Add-Type -AssemblyName System.Windows.Forms

try {
    # Bring Claude window to front
    [System.Windows.Forms.SendKeys]::SendWait("%{TAB}")
    Start-Sleep -Milliseconds 500
    
    # Send the prompt
    Write-Host "Sending prompt via SendKeys..." -ForegroundColor Yellow
    
    # Send prompt in chunks to avoid buffer issues
    $lines = $prompt -split "`n"
    foreach ($line in $lines) {
        # Escape special characters for SendKeys
        $escapedLine = $line -replace '[+^%~(){}]', '{$0}'
        [System.Windows.Forms.SendKeys]::SendWait($escapedLine)
        [System.Windows.Forms.SendKeys]::SendWait("{ENTER}")
        Start-Sleep -Milliseconds 100
    }
    
    # Send final enter to submit
    Start-Sleep -Milliseconds 500
    [System.Windows.Forms.SendKeys]::SendWait("{ENTER}")
    
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Green
    Write-Host " Prompt Sent to Claude!" -ForegroundColor Green
    Write-Host "========================================" -ForegroundColor Green
    Write-Host ""
    Write-Host "Claude should now be processing your request." -ForegroundColor Cyan
    Write-Host "Check the Claude window for the response." -ForegroundColor Yellow
    
} catch {
    Write-Host "SendKeys failed: $_" -ForegroundColor Red
    
    # Fallback to clipboard
    $prompt | Set-Clipboard
    Write-Host ""
    Write-Host "Prompt copied to clipboard instead!" -ForegroundColor Green
    Write-Host "Paste it in the Claude window with Ctrl+V" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "========================================" -ForegroundColor DarkGray
Write-Host " Submission Complete" -ForegroundColor White
Write-Host "========================================" -ForegroundColor DarkGray
# SIG # Begin signature block
# MIIFqQYJKoZIhvcNAQcCoIIFmjCCBZYCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUxOU2Do9xtV0fU7OcNus6XIuP
# j/SgggMwMIIDLDCCAhSgAwIBAgIQdR0W2SKoK5VE8JId4ZxrRTANBgkqhkiG9w0B
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
# CQQxFgQUBX6UEwwsxWmSxzOgozjqevwgWPUwDQYJKoZIhvcNAQEBBQAEggEAaipz
# oJNqVd3Qw6lYXJ/WIx0T659T6C50Nf+41FUwW1GkofCOMR0emNB9v/gorH2HgEbn
# q9qzos0kuV2Jv5bK2yLiBJaP1HslrZx9PrK+Mmau66qpZO5JHlfpuyDc31mSFpUX
# HFATHjeYzQFFcT4JwvvU0u4ef4a16f3rXUpwQfA5YvcfM89Qgsifx8NEyd55YoMm
# cBSYQmJQlLFEH1QZ2UDecQ7OLKx6SuXwvDzH2fvUso/z3hBkXgnTfM48/uPC0mR2
# 2dRWvbRyck3Cnx4V2rWRIyQPRWwOAbJPNIeIK0YpKnYpDOZLGjb0cgJQHVOanenr
# 3Y63S9X9qgWfMy+kFQ==
# SIG # End signature block
