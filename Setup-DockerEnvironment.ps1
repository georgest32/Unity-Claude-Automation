# Unity-Claude-Automation Docker Environment Setup Script
# Sets up .env file with API keys and configuration

param(
    [switch]$Interactive,
    [string]$OpenAIKey,
    [string]$AnthropicKey,
    [string]$GitHubToken,
    [switch]$UseExisting
)

Write-Host "Unity-Claude-Automation Docker Environment Setup" -ForegroundColor Cyan
Write-Host "================================================" -ForegroundColor Cyan
Write-Host ""

$envPath = Join-Path $PSScriptRoot ".env"
$envExamplePath = Join-Path $PSScriptRoot ".env.example"

# Check if .env already exists
if (Test-Path $envPath) {
    Write-Host "WARNING: .env file already exists!" -ForegroundColor Yellow
    $overwrite = Read-Host "Do you want to overwrite it? (y/N)"
    if ($overwrite -ne 'y') {
        Write-Host "Setup cancelled. Existing .env file preserved." -ForegroundColor Gray
        exit 0
    }
}

# Check for existing environment variables or stored keys
if ($UseExisting) {
    Write-Host "Checking for existing API keys..." -ForegroundColor Yellow
    
    # Check environment variables
    if (-not $OpenAIKey -and $env:OPENAI_API_KEY) {
        $OpenAIKey = $env:OPENAI_API_KEY
        Write-Host "  Found OpenAI key in environment variable" -ForegroundColor Green
    }
    
    if (-not $AnthropicKey -and $env:ANTHROPIC_API_KEY) {
        $AnthropicKey = $env:ANTHROPIC_API_KEY
        Write-Host "  Found Anthropic key in environment variable" -ForegroundColor Green
    }
    
    if (-not $GitHubToken -and $env:GITHUB_TOKEN) {
        $GitHubToken = $env:GITHUB_TOKEN
        Write-Host "  Found GitHub token in environment variable" -ForegroundColor Green
    }
    
    # Check common locations for stored keys
    $configPaths = @(
        "$env:USERPROFILE\.config\unity-claude\api_keys.json",
        "$env:APPDATA\Unity-Claude\config.json",
        "$PSScriptRoot\secrets\api_keys.json"
    )
    
    foreach ($configPath in $configPaths) {
        if (Test-Path $configPath) {
            Write-Host "  Found config file: $configPath" -ForegroundColor Gray
            try {
                $config = Get-Content $configPath | ConvertFrom-Json
                if (-not $OpenAIKey -and $config.openai_key) {
                    $OpenAIKey = $config.openai_key
                    Write-Host "  Loaded OpenAI key from config" -ForegroundColor Green
                }
                if (-not $AnthropicKey -and $config.anthropic_key) {
                    $AnthropicKey = $config.anthropic_key
                    Write-Host "  Loaded Anthropic key from config" -ForegroundColor Green
                }
                if (-not $GitHubToken -and $config.github_token) {
                    $GitHubToken = $config.github_token
                    Write-Host "  Loaded GitHub token from config" -ForegroundColor Green
                }
            } catch {
                Write-Host "  Could not parse config file: $_" -ForegroundColor Gray
            }
        }
    }
    Write-Host ""
}

# Interactive mode - prompt for missing keys
if ($Interactive) {
    Write-Host "Enter your API keys (press Enter to skip if not available):" -ForegroundColor Yellow
    Write-Host ""
    
    if (-not $OpenAIKey) {
        $OpenAIKey = Read-Host "OpenAI API Key"
    } else {
        Write-Host "OpenAI API Key: [Already provided]" -ForegroundColor Gray
    }
    
    if (-not $AnthropicKey) {
        $AnthropicKey = Read-Host "Anthropic API Key"
    } else {
        Write-Host "Anthropic API Key: [Already provided]" -ForegroundColor Gray
    }
    
    if (-not $GitHubToken) {
        $GitHubToken = Read-Host "GitHub Personal Access Token"
    } else {
        Write-Host "GitHub Token: [Already provided]" -ForegroundColor Gray
    }
    Write-Host ""
}

# Validate keys format (basic validation)
function Test-APIKey {
    param([string]$Key, [string]$Type)
    
    if ([string]::IsNullOrWhiteSpace($Key)) {
        return $false
    }
    
    switch ($Type) {
        "OpenAI" {
            # OpenAI keys typically start with 'sk-'
            return $Key -match '^sk-[\w-]+$'
        }
        "Anthropic" {
            # Anthropic keys typically start with 'sk-ant-'
            return $Key -match '^sk-ant-[\w-]+$'
        }
        "GitHub" {
            # GitHub tokens can be classic (40 chars) or fine-grained (starts with github_pat_)
            return ($Key.Length -eq 40) -or ($Key -match '^github_pat_[\w]+$') -or ($Key -match '^ghp_[\w]+$')
        }
        default { return $true }
    }
}

# Validate provided keys
$validationResults = @()
if ($OpenAIKey) {
    if (Test-APIKey -Key $OpenAIKey -Type "OpenAI") {
        $validationResults += "  OpenAI key format: Valid"
        Write-Host "  OpenAI key format: Valid" -ForegroundColor Green
    } else {
        $validationResults += "  OpenAI key format: May be invalid (doesn't match expected pattern)"
        Write-Host "  OpenAI key format: May be invalid (doesn't match expected pattern)" -ForegroundColor Yellow
    }
}

if ($AnthropicKey) {
    if (Test-APIKey -Key $AnthropicKey -Type "Anthropic") {
        $validationResults += "  Anthropic key format: Valid"
        Write-Host "  Anthropic key format: Valid" -ForegroundColor Green
    } else {
        $validationResults += "  Anthropic key format: May be invalid (doesn't match expected pattern)"
        Write-Host "  Anthropic key format: May be invalid (doesn't match expected pattern)" -ForegroundColor Yellow
    }
}

if ($GitHubToken) {
    if (Test-APIKey -Key $GitHubToken -Type "GitHub") {
        $validationResults += "  GitHub token format: Valid"
        Write-Host "  GitHub token format: Valid" -ForegroundColor Green
    } else {
        $validationResults += "  GitHub token format: May be invalid (doesn't match expected pattern)"
        Write-Host "  GitHub token format: May be invalid (doesn't match expected pattern)" -ForegroundColor Yellow
    }
}

Write-Host ""

# Create .env file content
$envContent = @"
# Unity-Claude-Automation Docker Environment Variables
# Generated on $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
# WARNING: Never commit this file to version control!

# API Keys
OPENAI_API_KEY=$OpenAIKey
ANTHROPIC_API_KEY=$AnthropicKey
LANGGRAPH_API_KEY=$AnthropicKey
GITHUB_TOKEN=$GitHubToken

# Service Configuration
POWERSHELL_TELEMETRY_OPTOUT=1
PYTHONUNBUFFERED=1
AUTOGEN_USE_DOCKER=0

# Database Paths
LANGGRAPH_DB_PATH=/app/data/langgraph.db

# Monitoring Configuration
WATCH_PATH=/watch
LOG_PATH=/var/log/monitoring

# Network Configuration
DOCKER_NETWORK_SUBNET=172.20.0.0/16

# Container Registry (for production)
REGISTRY_URL=localhost:5000
IMAGE_TAG=latest

# Logging Levels
LOG_LEVEL=INFO
DEBUG_MODE=false

# Additional Services Configuration
FASTAPI_ENV=production
DOCS_BASE_URL=http://localhost:8080
API_BASE_URL=http://localhost:8000
AUTOGEN_BASE_URL=http://localhost:8001

# Security Settings
CORS_ORIGINS=["http://localhost:3000", "http://localhost:8080"]
JWT_SECRET_KEY=change-this-to-a-random-secret-key-in-production
TOKEN_EXPIRATION_HOURS=24
"@

# Write .env file
try {
    Set-Content -Path $envPath -Value $envContent -Encoding UTF8
    Write-Host "SUCCESS: .env file created at: $envPath" -ForegroundColor Green
    Write-Host ""
    
    # Add to .gitignore if not already there
    $gitignorePath = Join-Path $PSScriptRoot ".gitignore"
    if (Test-Path $gitignorePath) {
        $gitignoreContent = Get-Content $gitignorePath -Raw
        if ($gitignoreContent -notmatch '\.env') {
            Add-Content -Path $gitignorePath -Value "`n# Environment variables`n.env"
            Write-Host "Added .env to .gitignore for security" -ForegroundColor Gray
        }
    }
    
    # Display summary
    Write-Host "Configuration Summary:" -ForegroundColor Cyan
    Write-Host "=====================" -ForegroundColor Cyan
    if ($OpenAIKey) {
        $maskedKey = $OpenAIKey.Substring(0, 7) + "..." + $OpenAIKey.Substring($OpenAIKey.Length - 4)
        Write-Host "  OpenAI API Key: $maskedKey" -ForegroundColor Gray
    } else {
        Write-Host "  OpenAI API Key: [Not configured]" -ForegroundColor Yellow
    }
    
    if ($AnthropicKey) {
        $maskedKey = $AnthropicKey.Substring(0, 10) + "..." + $AnthropicKey.Substring($AnthropicKey.Length - 4)
        Write-Host "  Anthropic API Key: $maskedKey" -ForegroundColor Gray
        Write-Host "  LangGraph API Key: [Same as Anthropic]" -ForegroundColor Gray
    } else {
        Write-Host "  Anthropic API Key: [Not configured]" -ForegroundColor Yellow
        Write-Host "  LangGraph API Key: [Not configured]" -ForegroundColor Yellow
    }
    
    if ($GitHubToken) {
        $maskedToken = $GitHubToken.Substring(0, 10) + "..." + $GitHubToken.Substring($GitHubToken.Length - 4)
        Write-Host "  GitHub Token: $maskedToken" -ForegroundColor Gray
    } else {
        Write-Host "  GitHub Token: [Not configured]" -ForegroundColor Yellow
    }
    
    Write-Host ""
    Write-Host "Next Steps:" -ForegroundColor Green
    Write-Host "1. Review the .env file and update any additional settings if needed"
    Write-Host "2. Run: docker compose build" -ForegroundColor Cyan
    Write-Host "3. Run: docker compose up -d" -ForegroundColor Cyan
    Write-Host "4. Test: .\docker\build.ps1 -Test" -ForegroundColor Cyan
    
} catch {
    Write-Host "ERROR: Failed to create .env file: $_" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "Setup complete!" -ForegroundColor Green
# SIG # Begin signature block
# MIIFzgYJKoZIhvcNAQcCoIIFvzCCBbsCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCAiXSiHOBOHPLp5
# EXUu1rv0kcsGdM0fu4G9hu+6G6qmw6CCAzAwggMsMIICFKADAgECAhB1HRbZIqgr
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
# MAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIAafPEqITgx8HzvHI7jKTEZs
# qRAhEnJ26xOKlfbSg6rCMA0GCSqGSIb3DQEBAQUABIIBAIhWefLjG1YyBxuPXScQ
# MMH9ID78LChiHeUEq7SYlvXZlHlppfgRYiIMPWrgH6Xv30irNg1i6La4JPr9iTcj
# UFmTb6q89PFCQUPuEP1SSbvj51NCsAoNQY8feXbT4alBsSRykVgsJAEAHvW07Ejs
# idUME91WZy/4RE3rqymor3kmQisHwHsK5bKX8csVC/DFIwZXhY21r4WMkNz7tNGg
# GpEZYsbxsuJEwEQDHBt+CXkIqcdC+vos4px0vmFt6wb1vONxvCKaCuevud4cwk9A
# 0dmwouCNuBDQlSmgCQF+QBnxHndCziUi4TD/fkP2sBnW2njHX59rqNPL1X1/aiP2
# +ZQ=
# SIG # End signature block
