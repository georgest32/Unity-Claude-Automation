# Create-ClaudeResponseCapture.ps1
# Script to capture Claude's actual text responses after submission

param(
    [string]$PromptId = (New-Guid).ToString(),
    [int]$TimeoutSeconds = 30
)

Write-Host "=== Claude Response Capture System ===" -ForegroundColor Cyan
Write-Host "Prompt ID: $PromptId" -ForegroundColor Yellow

# The challenge: After submitting a prompt via SendKeys, we need to capture Claude's response
# Claude Code CLI doesn't have an API, so we need to monitor for the response

$possibleMethods = @"
Possible methods to capture Claude's response:

1. CLIPBOARD MONITORING
   - After Claude responds, user could copy the response (Ctrl+A, Ctrl+C)
   - Script monitors clipboard for changes
   - Pro: Simple, reliable
   - Con: Requires manual copy action

2. SCREEN CAPTURE / OCR
   - Take screenshot of Claude window
   - Use OCR to extract text
   - Pro: Fully automated
   - Con: Complex, requires OCR library

3. FILE SYSTEM MONITORING
   - Claude might save responses to a specific location
   - Monitor for new files in Claude's data directory
   - Pro: Automated if Claude saves responses
   - Con: Need to find where Claude saves data

4. WINDOW TEXT EXTRACTION
   - Use Windows API to extract text from Claude window
   - Pro: Direct access to window content
   - Con: May not work with all window types

5. LOG FILE MONITORING
   - Claude might write to log files
   - Monitor Claude's log directory
   - Pro: Reliable if logs exist
   - Con: Need to find log location

6. MANUAL SAVE TRIGGER
   - After response, trigger Ctrl+S to save
   - Monitor for saved file
   - Pro: Controlled save location
   - Con: Requires manual trigger
"@

Write-Host $possibleMethods -ForegroundColor Gray

# Method 1: Clipboard monitoring (simplest approach)
Write-Host "`n=== Implementing Clipboard Monitor ===" -ForegroundColor Green

Add-Type -AssemblyName System.Windows.Forms

$initialClipboard = [System.Windows.Forms.Clipboard]::GetText()
Write-Host "Initial clipboard content captured" -ForegroundColor Gray

Write-Host "`nMonitoring clipboard for Claude's response..." -ForegroundColor Yellow
Write-Host "After Claude responds, please:" -ForegroundColor Cyan
Write-Host "  1. Select all text (Ctrl+A)" -ForegroundColor White
Write-Host "  2. Copy to clipboard (Ctrl+C)" -ForegroundColor White

$startTime = Get-Date
$captured = $false

while (-not $captured -and ((Get-Date) - $startTime).TotalSeconds -lt $TimeoutSeconds) {
    Start-Sleep -Milliseconds 500
    
    $currentClipboard = [System.Windows.Forms.Clipboard]::GetText()
    
    if ($currentClipboard -ne $initialClipboard -and $currentClipboard) {
        Write-Host "`n✓ New clipboard content detected!" -ForegroundColor Green
        
        # Save the response
        $responseFile = "C:\UnityProjects\Sound-and-Shoal\Unity-Claude-Automation\ClaudeResponses\Captured\response_$(Get-Date -Format 'yyyyMMdd_HHmmss').txt"
        $responseDir = Split-Path $responseFile -Parent
        
        if (-not (Test-Path $responseDir)) {
            New-Item -Path $responseDir -ItemType Directory -Force | Out-Null
        }
        
        $currentClipboard | Set-Content $responseFile -Encoding UTF8
        
        Write-Host "Response saved to: $responseFile" -ForegroundColor Green
        Write-Host "`nCaptured Response:" -ForegroundColor Cyan
        Write-Host $currentClipboard -ForegroundColor White
        
        # Create structured response for autonomous agent
        $structuredResponse = @{
            timestamp = (Get-Date -Format "yyyy-MM-ddTHH:mm:ss.fffZ")
            promptId = $PromptId
            type = "claude_response"
            response = $currentClipboard
            captureMethod = "clipboard"
        }
        
        $jsonFile = "C:\UnityProjects\Sound-and-Shoal\Unity-Claude-Automation\ClaudeResponses\Autonomous\captured_response_$(Get-Date -Format 'yyyyMMdd_HHmmss').json"
        $structuredResponse | ConvertTo-Json -Depth 10 | Set-Content $jsonFile -Encoding UTF8
        
        Write-Host "Structured response saved to: $jsonFile" -ForegroundColor Green
        
        $captured = $true
        
        return @{
            Success = $true
            Response = $currentClipboard
            ResponseFile = $responseFile
            JsonFile = $jsonFile
        }
    }
    
    # Show waiting indicator
    Write-Host "." -NoNewline
}

if (-not $captured) {
    Write-Host "`nTimeout: No response captured within $TimeoutSeconds seconds" -ForegroundColor Red
    return @{
        Success = $false
        Error = "Timeout waiting for response"
    }
}
# SIG # Begin signature block
# MIIFqQYJKoZIhvcNAQcCoIIFmjCCBZYCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUJxJtzbECH0sX9wt6HHB/o6U6
# 9JCgggMwMIIDLDCCAhSgAwIBAgIQdR0W2SKoK5VE8JId4ZxrRTANBgkqhkiG9w0B
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
# CQQxFgQUs24WFNeRrPPNpj/d5jdqvMiebaMwDQYJKoZIhvcNAQEBBQAEggEAAWw/
# lbGJhV1gYP2Bz1aN8UbHqi3Pqyi20S0N4JJiKI3InKrPVKoAxTTb3UHwBJ4olGKx
# EL0yyNchiYns+LRnxWhTfiDa+iGUS4vThOdJA5o/44/P1JSdtkkBmEGRq2SnmmJ6
# wt7KZ3NGOVCWMeBeXB2hld0IMlurbr+Rvw9QuFjFxKXQdhYZXrmM5iskw6XPe1aY
# Q96lvGJUvI5Dqu/6AZjHasNgqqbsJ+VajPfjCezm4zBiqfGVzBNFBHbrQ9UvF/0K
# nXafTFBfOFJ4/XIYn7YIt9MjXxHnzW1A9qKIkholLx9/F34UrLXY4DNDCZ6v/YyU
# uI2V4kX5sGcQ8SiYjA==
# SIG # End signature block
