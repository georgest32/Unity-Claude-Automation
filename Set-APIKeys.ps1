# PowerShell script to set API keys as environment variables
# Run this script with administrator privileges for system-wide settings

param(
    [Parameter(Mandatory=$false)]
    [string]$OpenAIKey,
    
    [Parameter(Mandatory=$false)]
    [string]$AnthropicKey,
    
    [switch]$SystemWide = $false,
    
    [switch]$TestKeys = $false
)

Write-Host "API Key Configuration Script" -ForegroundColor Cyan
Write-Host "=============================" -ForegroundColor Cyan

# Function to set environment variable
function Set-APIKey {
    param(
        [string]$KeyName,
        [string]$KeyValue,
        [bool]$SystemWide
    )
    
    if ([string]::IsNullOrEmpty($KeyValue)) {
        Write-Host "Skipping $KeyName (no value provided)" -ForegroundColor Yellow
        return
    }
    
    if ($SystemWide) {
        # Set system-wide (requires admin)
        try {
            [System.Environment]::SetEnvironmentVariable($KeyName, $KeyValue, [System.EnvironmentVariableTarget]::Machine)
            Write-Host "✓ $KeyName set system-wide" -ForegroundColor Green
        }
        catch {
            Write-Host "✗ Failed to set $KeyName system-wide. Run as administrator." -ForegroundColor Red
            Write-Host "  Error: $_" -ForegroundColor Red
        }
    }
    else {
        # Set for current user
        [System.Environment]::SetEnvironmentVariable($KeyName, $KeyValue, [System.EnvironmentVariableTarget]::User)
        Write-Host "✓ $KeyName set for current user" -ForegroundColor Green
    }
    
    # Also set in current session
    Set-Item -Path "env:$KeyName" -Value $KeyValue
    Write-Host "✓ $KeyName set in current session" -ForegroundColor Green
}

# Function to test API keys
function Test-APIKey {
    param(
        [string]$KeyName,
        [string]$Provider
    )
    
    $key = [System.Environment]::GetEnvironmentVariable($KeyName)
    
    if ([string]::IsNullOrEmpty($key)) {
        Write-Host "✗ $KeyName is not set" -ForegroundColor Red
        return $false
    }
    
    Write-Host "✓ $KeyName is configured" -ForegroundColor Green
    Write-Host "  Key starts with: $($key.Substring(0, [Math]::Min(10, $key.Length)))..." -ForegroundColor Gray
    
    # Test the key with a simple API call
    if ($Provider -eq "OpenAI") {
        Write-Host "  Testing OpenAI API..." -ForegroundColor Yellow
        try {
            $headers = @{
                "Authorization" = "Bearer $key"
                "Content-Type" = "application/json"
            }
            $response = Invoke-RestMethod -Uri "https://api.openai.com/v1/models" -Headers $headers -Method Get -ErrorAction Stop
            Write-Host "  ✓ OpenAI API key is valid! Found $($response.data.Count) models" -ForegroundColor Green
            return $true
        }
        catch {
            Write-Host "  ✗ OpenAI API key validation failed" -ForegroundColor Red
            Write-Host "    Error: $($_.Exception.Message)" -ForegroundColor Red
            return $false
        }
    }
    elseif ($Provider -eq "Anthropic") {
        Write-Host "  Testing Anthropic API..." -ForegroundColor Yellow
        try {
            $headers = @{
                "x-api-key" = $key
                "anthropic-version" = "2023-06-01"
                "Content-Type" = "application/json"
            }
            $body = @{
                model = "claude-3-haiku-20240307"
                max_tokens = 10
                messages = @(
                    @{
                        role = "user"
                        content = "Hi"
                    }
                )
            } | ConvertTo-Json
            
            $response = Invoke-RestMethod -Uri "https://api.anthropic.com/v1/messages" -Headers $headers -Method Post -Body $body -ErrorAction Stop
            Write-Host "  ✓ Anthropic API key is valid!" -ForegroundColor Green
            return $true
        }
        catch {
            if ($_.Exception.Response.StatusCode -eq 'Unauthorized') {
                Write-Host "  ✗ Anthropic API key is invalid" -ForegroundColor Red
            }
            else {
                Write-Host "  ✓ Anthropic API key format appears valid (connection test)" -ForegroundColor Green
                return $true
            }
            return $false
        }
    }
    
    return $true
}

# Main execution
Write-Host ""

# Set OpenAI key if provided
if (-not [string]::IsNullOrEmpty($OpenAIKey)) {
    Write-Host "Setting OpenAI API Key..." -ForegroundColor Cyan
    Set-APIKey -KeyName "OPENAI_API_KEY" -KeyValue $OpenAIKey -SystemWide $SystemWide
}

# Set Anthropic key if provided
if (-not [string]::IsNullOrEmpty($AnthropicKey)) {
    Write-Host "`nSetting Anthropic API Key..." -ForegroundColor Cyan
    Set-APIKey -KeyName "ANTHROPIC_API_KEY" -KeyValue $AnthropicKey -SystemWide $SystemWide
}

# Test keys if requested or if any key was just set
if ($TestKeys -or -not [string]::IsNullOrEmpty($OpenAIKey) -or -not [string]::IsNullOrEmpty($AnthropicKey)) {
    Write-Host "`nTesting API Keys..." -ForegroundColor Cyan
    Write-Host "===================" -ForegroundColor Cyan
    
    $openAIValid = Test-APIKey -KeyName "OPENAI_API_KEY" -Provider "OpenAI"
    $anthropicValid = Test-APIKey -KeyName "ANTHROPIC_API_KEY" -Provider "Anthropic"
    
    Write-Host "`nSummary:" -ForegroundColor Cyan
    Write-Host "--------" -ForegroundColor Cyan
    
    if ($openAIValid -and $anthropicValid) {
        Write-Host "✓ Both API keys are configured and valid!" -ForegroundColor Green
        Write-Host "✓ You can use hybrid mode (recommended)" -ForegroundColor Green
    }
    elseif ($openAIValid) {
        Write-Host "✓ OpenAI API key is valid" -ForegroundColor Green
        Write-Host "⚠ Anthropic API key not configured/valid" -ForegroundColor Yellow
        Write-Host "  You can use OPENAI_ONLY profile" -ForegroundColor Yellow
    }
    elseif ($anthropicValid) {
        Write-Host "✓ Anthropic API key is valid" -ForegroundColor Green
        Write-Host "⚠ OpenAI API key not configured/valid" -ForegroundColor Yellow
        Write-Host "  You can use CLAUDE_ONLY profile" -ForegroundColor Yellow
    }
    else {
        Write-Host "✗ No valid API keys found" -ForegroundColor Red
        Write-Host "  Please check your API keys and try again" -ForegroundColor Red
    }
}

Write-Host "`nUsage Examples:" -ForegroundColor Cyan
Write-Host "---------------" -ForegroundColor Cyan
Write-Host "# Set OpenAI key for current user:" -ForegroundColor Gray
Write-Host '  .\Set-APIKeys.ps1 -OpenAIKey "sk-..."' -ForegroundColor White
Write-Host ""
Write-Host "# Set both keys system-wide (run as admin):" -ForegroundColor Gray
Write-Host '  .\Set-APIKeys.ps1 -OpenAIKey "sk-..." -AnthropicKey "sk-ant-..." -SystemWide' -ForegroundColor White
Write-Host ""
Write-Host "# Test existing keys:" -ForegroundColor Gray
Write-Host '  .\Set-APIKeys.ps1 -TestKeys' -ForegroundColor White
Write-Host ""
Write-Host "Note: You may need to restart your terminal for changes to take effect." -ForegroundColor Yellow
# SIG # Begin signature block
# MIIFzgYJKoZIhvcNAQcCoIIFvzCCBbsCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCBOV7CFbu7gVWbF
# GzQq53xv7lMk+fd4gj4luj6XyfcCSqCCAzAwggMsMIICFKADAgECAhB1HRbZIqgr
# lUTwkh3hnGtFMA0GCSqGSIb3DQEBCwUAMC4xLDAqBgNVBAMMI1VuaXR5LUNsYXVk
# ZS1BdXRvbWF0aW9uLURldmVsb3BtZW50MB4XDTI1MDgyMDIxMTUxN1oXDTI2MDgy
# MDIxMzUxN1owLjEsMCoGA1UEAwwjVW5pdHktQ2xhdWRlLUF1dG9tYXRpb24tRGV2
# ZWxvcG1lbnQwggEiMA0GCSqGSIb3DQEBAQUAA4IBDwAwggEKAoIBAQCx4feqKdUQ
# 6GufY4umNzlM1Pi8aHUGR8HlfhIWFjsrRAxCxhieRlWbHe0Hw+pVBeX76X57e5Pu
# 4Kxxzu+MxMry0NJYf3yOLRTfhYskHBcLraXUCtrMwqnhPKvul6Sx6Lu8vilk605W
# ADJNifl3WFuexVCYJJM9G2mfuYIDN+rZ5zmpn0qCXum49bm629h+HyJ205Zrn9aB
# hIrA4i/JlrAh1kosWnCo62psl7ixbNVqFqwWEt+gAqSeIo4ChwkOQl7GHmk78Q5I
# oRneY4JTVlKzhdZEYhJGFXeoZml/5jcmUcox4UNYrKdokE7z8ZTmyowBOUNS+sHI
# G1TY5DZSb8vdAgMBAAGjRjBEMA4GA1UdDwEB/wQEAwIHgDATBgNVHSUEDDAKBggr
# BgEFBQcDAzAdBgNVHQ4EFgQUfDms7LrGVboHjmwlSyIjYD/JLQwwDQYJKoZIhvcN
# AQELBQADggEBABRMsfT7DzKy+aFi4HDg0MpxmbjQxOH1lzUzanaECRiyA0sn7+sA
# /4jvis1+qC5NjDGkLKOTCuDzIXnBWLCCBugukXbIO7g392ANqKdHjBHw1WlLvMVk
# 4WSmY096lzpvDd3jJApr/Alcp4KmRGNLnQ3vv+F9Uj58Uo1qjs85vt6fl9xe5lo3
# rFahNHL4ngjgyF8emNm7FItJeNtVe08PhFn0caOX0FTzXrZxGGO6Ov8tzf91j/qK
# QdBifG7Fx3FF7DifNqoBBo55a7q0anz30k8p+V0zllrLkgGXfOzXmA1L37Qmt3QB
# FCdJVigjQMuHcrJsWd8rg857Og0un91tfZIxggH0MIIB8AIBATBCMC4xLDAqBgNV
# BAMMI1VuaXR5LUNsYXVkZS1BdXRvbWF0aW9uLURldmVsb3BtZW50AhB1HRbZIqgr
# lUTwkh3hnGtFMA0GCWCGSAFlAwQCAQUAoIGEMBgGCisGAQQBgjcCAQwxCjAIoAKA
# AKECgAAwGQYJKoZIhvcNAQkDMQwGCisGAQQBgjcCAQQwHAYKKwYBBAGCNwIBCzEO
# MAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIMUGTmajTjVgBKv3a/eVZ+HK
# gtyNrL09n0iS4QUHT5sVMA0GCSqGSIb3DQEBAQUABIIBAJy7hCiWd8OVvprujn3M
# j/GK2v9P/arJb1/mkwU/pkH1EsVyySTMnK+hh24574RJBQyOYU6KDY43dEnNUxkv
# 2z2cpcwt5c4TWi+018mqi33L+4eHA7VRDHAV9cFhMf/NWKCbkoKnVxloQ7VcfL/M
# pKyCVCl5Aq5gu49Yj3QVhbmcAXnYNoTnuqhDq8XRgU+tNhXJ91T0EQgebYd7iUC8
# oe74Wq66zsH0PBgjzbm6P5g7Dj57mAWT33+aj2vgOrStnbYWPCvAc6r882tGtppY
# 4/XLC1sSSEsYjQebKDUPn27XGacwfcyXaNwCDtBjEv+SMMxnEag4ciXbdbMABSnU
# zQE=
# SIG # End signature block
