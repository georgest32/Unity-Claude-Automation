# Setup-GitHubIntegration.ps1
# Interactive setup script for GitHub Integration
# Phase 4, Week 8

param(
    [switch]$Interactive = $true
)

Write-Host "================================" -ForegroundColor Yellow
Write-Host " GitHub Integration Setup       " -ForegroundColor Yellow
Write-Host "================================" -ForegroundColor Yellow
Write-Host ""

# Import the module
Write-Host "Importing Unity-Claude-GitHub module..." -ForegroundColor Cyan
try {
    $modulePath = Join-Path $PSScriptRoot "Modules\Unity-Claude-GitHub"
    Import-Module $modulePath -Force -ErrorAction Stop
    Write-Host "  Module imported successfully" -ForegroundColor Green
}
catch {
    Write-Host "  Failed to import module: $_" -ForegroundColor Red
    exit 1
}

# Check current PAT status
Write-Host "`nChecking current authentication status..." -ForegroundColor Cyan
$hasToken = Test-GitHubPAT

if ($hasToken) {
    Write-Host "  GitHub PAT is already configured" -ForegroundColor Green
    
    if ($Interactive) {
        $response = Read-Host "Do you want to update the existing token? (y/n)"
        if ($response -ne 'y') {
            Write-Host "Keeping existing token" -ForegroundColor Yellow
            exit 0
        }
    }
}
else {
    Write-Host "  No GitHub PAT found" -ForegroundColor Yellow
}

# Instructions for creating a PAT
Write-Host "`n" -ForegroundColor White
Write-Host "To set up GitHub integration, you need a Personal Access Token (PAT)." -ForegroundColor White
Write-Host ""
Write-Host "Steps to create a GitHub PAT:" -ForegroundColor Cyan
Write-Host "1. Go to: https://github.com/settings/tokens" -ForegroundColor White
Write-Host "2. Click 'Generate new token' -> 'Generate new token (classic)'" -ForegroundColor White
Write-Host "3. Give it a descriptive name (e.g., 'Unity-Claude-Automation')" -ForegroundColor White
Write-Host "4. Set expiration (recommend 90 days for security)" -ForegroundColor White
Write-Host "5. Select these scopes:" -ForegroundColor White
Write-Host "   - repo (Full control of private repositories)" -ForegroundColor Yellow
Write-Host "   - workflow (optional, for Actions integration)" -ForegroundColor Gray
Write-Host "6. Click 'Generate token' at the bottom" -ForegroundColor White
Write-Host "7. COPY THE TOKEN NOW - you won't see it again!" -ForegroundColor Red
Write-Host ""

if ($Interactive) {
    Write-Host "Press Enter when you have your token ready..." -ForegroundColor Cyan
    Read-Host
    
    # Prompt for the token
    Write-Host "`nEnter your GitHub Personal Access Token:" -ForegroundColor Yellow
    Write-Host "(Note: The token will not be displayed as you type)" -ForegroundColor Gray
    $secureToken = Read-Host -AsSecureString
    
    # Convert SecureString to plain text for Set-GitHubPAT
    $BSTR = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($secureToken)
    $token = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR)
    [System.Runtime.InteropServices.Marshal]::ZeroFreeBSTR($BSTR)
    
    if ([string]::IsNullOrWhiteSpace($token)) {
        Write-Host "No token provided. Exiting." -ForegroundColor Red
        exit 1
    }
    
    # Set the token
    Write-Host "`nSaving token securely..." -ForegroundColor Cyan
    try {
        Set-GitHubPAT -Token $token
        Write-Host "  Token saved successfully" -ForegroundColor Green
    }
    catch {
        Write-Host "  Failed to save token: $_" -ForegroundColor Red
        exit 1
    }
    
    # Test the token
    Write-Host "`nTesting GitHub authentication..." -ForegroundColor Cyan
    if (Test-GitHubPAT) {
        Write-Host "  Authentication successful!" -ForegroundColor Green
        
        # Try to get rate limit info
        try {
            $rateLimit = Get-GitHubRateLimit
            Write-Host "`nRate Limit Status:" -ForegroundColor Cyan
            Write-Host "  Limit: $($rateLimit.Limit)" -ForegroundColor White
            Write-Host "  Remaining: $($rateLimit.Remaining)" -ForegroundColor White
            Write-Host "  Reset: $($rateLimit.Reset)" -ForegroundColor White
        }
        catch {
            Write-Host "  Could not retrieve rate limit info" -ForegroundColor Yellow
        }
    }
    else {
        Write-Host "  Authentication test failed" -ForegroundColor Red
        Write-Host "  Please verify your token has the correct permissions" -ForegroundColor Yellow
        exit 1
    }
    
    # Optional: Set default repository
    Write-Host "`nWould you like to set a default repository for testing? (y/n)" -ForegroundColor Cyan
    $response = Read-Host
    
    if ($response -eq 'y') {
        $owner = Read-Host "Enter repository owner (GitHub username or org)"
        $repo = Read-Host "Enter repository name"
        
        if ($owner -and $repo) {
            # Save to module config
            $configPath = Join-Path $env:APPDATA "Unity-Claude\GitHub\config.json"
            $config = @{
                DefaultOwner = $owner
                DefaultRepository = $repo
            }
            
            try {
                $configDir = Split-Path $configPath -Parent
                if (-not (Test-Path $configDir)) {
                    New-Item -Path $configDir -ItemType Directory -Force | Out-Null
                }
                
                $config | ConvertTo-Json | Set-Content -Path $configPath -Encoding UTF8
                Write-Host "  Default repository set: $owner/$repo" -ForegroundColor Green
            }
            catch {
                Write-Host "  Could not save default repository: $_" -ForegroundColor Yellow
            }
        }
    }
    
    Write-Host "`n================================" -ForegroundColor Green
    Write-Host " Setup Complete!                " -ForegroundColor Green
    Write-Host "================================" -ForegroundColor Green
    Write-Host ""
    Write-Host "You can now run the tests:" -ForegroundColor White
    Write-Host "  .\Test-GitHubIssueManagement.ps1 -AllTests -SaveResults" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Or use the GitHub integration functions:" -ForegroundColor White
    Write-Host "  New-GitHubIssue" -ForegroundColor Cyan
    Write-Host "  Search-GitHubIssues" -ForegroundColor Cyan
    Write-Host "  Test-GitHubIssueDuplicate" -ForegroundColor Cyan
    Write-Host ""
}
else {
    # Non-interactive mode
    Write-Host "Run this script without -Interactive:$false for guided setup" -ForegroundColor Yellow
}
# SIG # Begin signature block
# MIIFzgYJKoZIhvcNAQcCoIIFvzCCBbsCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCAdfGU9CELT3TIT
# 87LA65x/bAJcGFtorp1ec/ZRnTvN6KCCAzAwggMsMIICFKADAgECAhB1HRbZIqgr
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
# MAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIF2BOkHbh1dhbzZ2DdBhk5c7
# e6g9/+UlCAiekgoP440tMA0GCSqGSIb3DQEBAQUABIIBAED7fyN7udGB73Plkh4V
# SHG5KT4w5aMuS/PS9nS7W549YC5r9G+A0uwqbdvT+KgzNSjNT+d29l9focpD2ijW
# Ptqj9zS+b6oehCXStOqtTg7e0bj1rENl4eIY8UVB8p/HRrNwPCNHNVvvdp9Qx7qn
# pzpJfS74ZlDYat9rK9zFGqxFlplR/lS2KlDTiSjLiKYVJHbwmG+MJMmELxmA49gx
# /Q0zhejJgA+18zxQeNs8kfBPDx/CqU4j2VPRnuA0DPvKQGF4gI7KfnQT+am4yQhF
# KIozXdePyzfQnVYhgWxuJlT+VF2LXvGXuGEjk19/DqcpV+/T/psOizl/x6UGDMH2
# ofc=
# SIG # End signature block
