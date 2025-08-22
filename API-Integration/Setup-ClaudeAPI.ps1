# Setup-ClaudeAPI.ps1
# Helper script to set up Claude API integration

[CmdletBinding()]
param(
    [switch]$TestOnly,
    [switch]$Persistent
)

Write-Host ""
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "           Claude API Setup Assistant                     " -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host ""

# Check current status
$hasApiKey = [bool]$env:ANTHROPIC_API_KEY

if ($hasApiKey) {
    Write-Host "[OK] API Key Status: CONFIGURED" -ForegroundColor Green
    $maskedKey = $env:ANTHROPIC_API_KEY.Substring(0, 10) + "..." + $env:ANTHROPIC_API_KEY.Substring($env:ANTHROPIC_API_KEY.Length - 4)
    Write-Host "   Current Key: $maskedKey" -ForegroundColor Gray
} else {
    Write-Host "[X] API Key Status: NOT CONFIGURED" -ForegroundColor Red
}

Write-Host ""

# Test mode
if ($TestOnly) {
    if (-not $hasApiKey) {
        Write-Host "Cannot test without API key configured" -ForegroundColor Red
        exit 1
    }
    
    Write-Host "Testing Claude API connection..." -ForegroundColor Yellow
    
    $headers = @{
        "x-api-key" = $env:ANTHROPIC_API_KEY
        "anthropic-version" = "2023-06-01"
        "content-type" = "application/json"
    }
    
    $body = @{
        model = "claude-3-5-sonnet-20241022"
        messages = @(
            @{
                role = "user"
                content = "Reply with 'API connection successful' and nothing else."
            }
        )
        max_tokens = 50
    } | ConvertTo-Json
    
    try {
        $response = Invoke-RestMethod -Uri "https://api.anthropic.com/v1/messages" `
                                      -Method Post `
                                      -Headers $headers `
                                      -Body $body `
                                      -ErrorAction Stop
        
        Write-Host "[OK] API Test Successful!" -ForegroundColor Green
        Write-Host "   Response: $($response.content[0].text)" -ForegroundColor White
        Write-Host ""
        Write-Host "Token usage:" -ForegroundColor Cyan
        Write-Host "   Input: $($response.usage.input_tokens)" -ForegroundColor White
        Write-Host "   Output: $($response.usage.output_tokens)" -ForegroundColor White
        
    } catch {
        Write-Host "[X] API Test Failed!" -ForegroundColor Red
        Write-Host "   Error: $_" -ForegroundColor Yellow
    }
    
    exit
}

# Setup mode
if (-not $hasApiKey) {
    Write-Host "Let's set up your Claude API key!" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Steps to get your API key:" -ForegroundColor Yellow
    Write-Host "1. Go to: https://console.anthropic.com/api-keys" -ForegroundColor White
    Write-Host "2. Sign in or create an account" -ForegroundColor White
    Write-Host "3. Click 'Create Key'" -ForegroundColor White
    Write-Host "4. Name your key (e.g., 'Unity-Claude-Automation')" -ForegroundColor White
    Write-Host "5. Copy the key (starts with 'sk-ant-api...')" -ForegroundColor White
    Write-Host ""
    
    Write-Host "Enter your API key (or press Enter to skip): " -NoNewline -ForegroundColor Cyan
    $apiKey = Read-Host -AsSecureString
    
    if ($apiKey.Length -gt 0) {
        # Convert SecureString to plain text
        $BSTR = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($apiKey)
        $plainKey = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR)
        [System.Runtime.InteropServices.Marshal]::ZeroFreeBSTR($BSTR)
        
        # Validate key format
        if ($plainKey -match '^sk-ant-api\d{2}-[\w-]+$') {
            $env:ANTHROPIC_API_KEY = $plainKey
            Write-Host "[OK] API key set for this session!" -ForegroundColor Green
            
            if ($Persistent) {
                Write-Host ""
                Write-Host "Making API key persistent..." -ForegroundColor Yellow
                
                # Add to PowerShell profile
                $profileContent = @"

# Claude API Key for Unity-Claude Automation
`$env:ANTHROPIC_API_KEY = "$plainKey"
"@
                
                if (-not (Test-Path $PROFILE)) {
                    New-Item -Path $PROFILE -ItemType File -Force | Out-Null
                }
                
                Add-Content -Path $PROFILE -Value $profileContent
                Write-Host "[OK] API key added to PowerShell profile!" -ForegroundColor Green
                Write-Host "   Location: $PROFILE" -ForegroundColor Gray
            } else {
                Write-Host ""
                Write-Host "To make persistent, run:" -ForegroundColor Yellow
                Write-Host "  .\Setup-ClaudeAPI.ps1 -Persistent" -ForegroundColor White
            }
        } else {
            Write-Host "[X] Invalid API key format!" -ForegroundColor Red
            Write-Host "   Keys should start with 'sk-ant-api'" -ForegroundColor Yellow
        }
    }
}

# Show current configuration
Write-Host ""
Write-Host "============================================================" -ForegroundColor DarkGray
Write-Host " Configuration Summary" -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor DarkGray

$configItems = @(
    @{Name = "API Key"; Value = if ($env:ANTHROPIC_API_KEY) { "[OK] Configured" } else { "[X] Not Set" }}
    @{Name = "API Endpoint"; Value = "https://api.anthropic.com/v1/messages"}
    @{Name = "Default Model"; Value = "claude-3-5-sonnet-20241022"}
    @{Name = "Pricing"; Value = "`$3/1M input, `$15/1M output tokens"}
    @{Name = "Free Credits"; Value = "`$5 for new accounts"}
)

foreach ($item in $configItems) {
    Write-Host "$($item.Name): " -NoNewline -ForegroundColor White
    Write-Host $item.Value -ForegroundColor Gray
}

Write-Host ""
Write-Host "Available Commands:" -ForegroundColor Cyan
Write-Host "  .\Setup-ClaudeAPI.ps1 -TestOnly" -ForegroundColor White
Write-Host "    Test API connection" -ForegroundColor Gray
Write-Host ""
Write-Host "  .\Submit-ErrorsToClaude-API.ps1" -ForegroundColor White
Write-Host "    Submit errors to Claude API" -ForegroundColor Gray
Write-Host ""
Write-Host "  .\Setup-ClaudeAPI.ps1 -Persistent" -ForegroundColor White
Write-Host "    Save API key to profile" -ForegroundColor Gray

if (-not $env:ANTHROPIC_API_KEY) {
    Write-Host ""
    Write-Host "NOTE: Remember to set your API key before using the automation!" -ForegroundColor Yellow
}
# SIG # Begin signature block
# MIIFqQYJKoZIhvcNAQcCoIIFmjCCBZYCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUdY+Aal/Q3hkGqfKn7p9TgaPw
# VBKgggMwMIIDLDCCAhSgAwIBAgIQdR0W2SKoK5VE8JId4ZxrRTANBgkqhkiG9w0B
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
# CQQxFgQUlsB3FWBTje/4Urzp1VxIgROwNOQwDQYJKoZIhvcNAQEBBQAEggEAjzZZ
# bKYcuFfgirV4ldVIbzmyhZr3YKhf3K5T0DhtUq3yzdYiWesQijZmB7HlPbd5rq+E
# kflzc/yGVt4VLdll0vGTjc2cd5gg/YPqHuKfN1ttonl12lLQJTK7ClTAjEAEphhe
# K/MjPPk/0CvPLTcTD8wq/npZ0SFRBDrQ3bLe49EJ7AAEqvtRFnYPtl0kC3dxTn6C
# cNJQAcviIbcJ1hfFDEbXTeQv1nJdZTWlEAH54SrYhG0/mUI5luRUgFI6aon4dhE/
# tmRb4z6SRek9ZJOF8ZFg/WNK1BbdCXTzJbPk7HK5ZZKYhTR0GvamjxuGE5bjMAmx
# k9gMJXdmM1rWFoBwRg==
# SIG # End signature block
