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