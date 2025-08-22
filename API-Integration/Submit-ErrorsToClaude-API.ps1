# Submit-ErrorsToClaude-API.ps1
# Direct Claude API integration for true background automation
# No window switching required!

[CmdletBinding()]
param(
    [string]$ErrorLogPath,
    [string]$ErrorType = 'Last',
    [string]$Model = 'claude-3-5-sonnet-20241022',
    [int]$MaxTokens = 4096,
    [switch]$StreamResponse,
    [switch]$SaveResponse
)

# Configuration
$script:Config = @{
    ApiEndpoint = "https://api.anthropic.com/v1/messages"
    ApiVersion = "2023-06-01"
    DefaultModel = $Model
    MaxTokens = $MaxTokens
    ResponsePath = Join-Path $PSScriptRoot 'ClaudeAPIResponses'
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host " Claude API Direct Integration" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Check for API key
if (-not $env:ANTHROPIC_API_KEY) {
    Write-Host "ERROR: ANTHROPIC_API_KEY environment variable not set!" -ForegroundColor Red
    Write-Host ""
    Write-Host "To set your API key:" -ForegroundColor Yellow
    Write-Host '  $env:ANTHROPIC_API_KEY = "your-api-key-here"' -ForegroundColor White
    Write-Host ""
    Write-Host "Or add to your PowerShell profile for persistence:" -ForegroundColor Yellow
    Write-Host '  notepad $PROFILE' -ForegroundColor White
    Write-Host '  Add: $env:ANTHROPIC_API_KEY = "your-api-key-here"' -ForegroundColor White
    Write-Host ""
    Write-Host "Get your API key from: https://console.anthropic.com/api-keys" -ForegroundColor Cyan
    exit 1
}

Write-Host "API key found" -ForegroundColor Green

# Export errors if needed
if (-not $ErrorLogPath) {
    Write-Host "Exporting current errors..." -ForegroundColor Yellow
    
    $exportScript = Join-Path (Split-Path $PSScriptRoot) 'Export-Tools\Export-ErrorsForClaude-Fixed.ps1'
    if (Test-Path $exportScript) {
        $ErrorLogPath = & $exportScript -ErrorType $ErrorType `
                                        -IncludeConsole `
                                        -IncludeTestResults `
                                        -IncludeEditorLog
    } else {
        # Fallback export
        $errorContent = "Unity-Claude Automation Error Report`n"
        $errorContent += "Timestamp: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')`n`n"
        $errorContent += "No specific errors exported. Please check:`n"
        $errorContent += "* AutomationLogs\*.log`n"
        $errorContent += "* Unity Editor console`n"
        $errorContent += "* Test results`n"
        
        $timestamp = Get-Date -Format 'yyyyMMdd_HHmmss'
        $filename = "ErrorExport_$timestamp.txt"
        $ErrorLogPath = Join-Path $PSScriptRoot $filename
        $errorContent | Set-Content -Path $ErrorLogPath
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
    Write-Host "No errors found in log" -ForegroundColor Yellow
    # Continue anyway as there might be other issues to analyze
}

Write-Host "Found $errorCount error indicators" -ForegroundColor Yellow

# Build the prompt - using single quotes to avoid interpolation issues
$systemPrompt = 'You are an expert Unity developer and C# programmer helping to debug and fix Unity automation errors.
You have deep knowledge of:
* Unity 2021.1.14f1 and its APIs
* C# compilation errors and their solutions
* Unity Editor automation
* PowerShell scripting
* The Unity-Claude automation system architecture

Provide specific, actionable solutions with exact code fixes.'

# Build user prompt with string concatenation to avoid here-string issues
$userPrompt = "Unity-Claude Automation Error Analysis Request`n`n"
$userPrompt += "Project: Sound-and-Shoal (Unity 2021.1.14f1)`n"
$userPrompt += "System: Modular Unity-Claude automation`n"
$userPrompt += "Location: C:\UnityProjects\Sound-and-Shoal" + "`n`n"
$userPrompt += "Errors detected: $errorCount issues`n`n"
$userPrompt += $errorContent
$userPrompt += "`n`nPlease provide:`n"
$userPrompt += "1. Root cause analysis of each error`n"
$userPrompt += "2. Specific fixes with exact file paths and code`n"
$userPrompt += "3. Step-by-step resolution instructions`n"
$userPrompt += "4. Any preventive measures to avoid similar issues`n`n"
$userPrompt += "Focus on practical solutions that can be immediately implemented."

# Prepare API request
$headers = @{
    "x-api-key" = $env:ANTHROPIC_API_KEY
    "anthropic-version" = $script:Config.ApiVersion
    "content-type" = "application/json"
}

$body = @{
    model = $script:Config.DefaultModel
    messages = @(
        @{
            role = "user"
            content = $userPrompt
        }
    )
    system = $systemPrompt
    max_tokens = $script:Config.MaxTokens
    temperature = 0.3  # Lower temperature for more focused, deterministic responses
} | ConvertTo-Json -Depth 10

if ($Verbose) {
    Write-Host ""
    Write-Host "Request Details:" -ForegroundColor Gray
    Write-Host "  Model: $($script:Config.DefaultModel)" -ForegroundColor Gray
    Write-Host "  Max Tokens: $($script:Config.MaxTokens)" -ForegroundColor Gray
    Write-Host "  Prompt Length: $($userPrompt.Length) chars" -ForegroundColor Gray
}

# Make API request
Write-Host ""
Write-Host "Submitting to Claude API..." -ForegroundColor Cyan
Write-Host "(This runs completely in the background!)" -ForegroundColor Green

try {
    $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
    
    $response = Invoke-RestMethod -Uri $script:Config.ApiEndpoint `
                                  -Method Post `
                                  -Headers $headers `
                                  -Body $body `
                                  -ErrorAction Stop
    
    $stopwatch.Stop()
    $elapsed = $stopwatch.Elapsed.TotalSeconds
    
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Green
    Write-Host " Response Received!" -ForegroundColor Green
    Write-Host "========================================" -ForegroundColor Green
    Write-Host ""
    Write-Host "Response time: $([Math]::Round($elapsed, 2)) seconds" -ForegroundColor Gray
    
    # Extract the response text
    $responseText = $response.content[0].text
    
    # Display token usage if available
    if ($response.usage) {
        Write-Host ""
        Write-Host "Token Usage:" -ForegroundColor Cyan
        Write-Host "  Input: $($response.usage.input_tokens) tokens" -ForegroundColor White
        Write-Host "  Output: $($response.usage.output_tokens) tokens" -ForegroundColor White
        
        # Calculate approximate cost (based on current pricing)
        $inputCost = ($response.usage.input_tokens / 1000000) * 3
        $outputCost = ($response.usage.output_tokens / 1000000) * 15
        $totalCost = $inputCost + $outputCost
        
        Write-Host "  Estimated Cost: `$$([Math]::Round($totalCost, 4))" -ForegroundColor Yellow
    }
    
    # Display the response
    Write-Host ""
    Write-Host "Claude's Analysis:" -ForegroundColor Cyan
    Write-Host "==================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host $responseText -ForegroundColor White
    
    # Save response if requested
    if ($SaveResponse) {
        if (-not (Test-Path $script:Config.ResponsePath)) {
            New-Item -ItemType Directory -Path $script:Config.ResponsePath -Force | Out-Null
        }
        
        $timestamp2 = Get-Date -Format 'yyyyMMdd_HHmmss'
        $responseFile = Join-Path $script:Config.ResponsePath "Response_$timestamp2.md"
        
        $fullResponse = "# Claude API Response`n"
        $fullResponse += "**Date**: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')`n"
        $fullResponse += "**Model**: $($response.model)`n"
        $fullResponse += "**Response Time**: $([Math]::Round($elapsed, 2))s`n"
        $fullResponse += "**Tokens**: Input=$($response.usage.input_tokens), Output=$($response.usage.output_tokens)`n`n"
        $fullResponse += "## Original Error Report`n"
        $fullResponse += "```````n"
        $fullResponse += $errorContent
        $fullResponse += "`n```````n`n"
        $fullResponse += "## Claude's Analysis`n"
        $fullResponse += $responseText
        
        $fullResponse | Set-Content -Path $responseFile
        
        Write-Host ""
        Write-Host "Response saved to:" -ForegroundColor Green
        Write-Host "  $responseFile" -ForegroundColor White
    }
    
    # Extract PowerShell commands if present
    if ($responseText -match '```powershell([\s\S]*?)```') {
        Write-Host ""
        Write-Host "========================================" -ForegroundColor Magenta
        Write-Host " PowerShell Commands Found" -ForegroundColor Magenta
        Write-Host "========================================" -ForegroundColor Magenta
        
        $commands = $matches[1].Trim()
        Write-Host $commands -ForegroundColor Yellow
        
        Write-Host ""
        Write-Host "Execute these commands? (Y/N): " -NoNewline -ForegroundColor Cyan
        $confirm = Read-Host
        
        if ($confirm -eq 'Y' -or $confirm -eq 'y') {
            Write-Host "Executing fixes..." -ForegroundColor Green
            try {
                Invoke-Expression $commands
                Write-Host "Commands executed successfully!" -ForegroundColor Green
            } catch {
                Write-Host "Error executing commands: $_" -ForegroundColor Red
            }
        }
    }
    
} catch {
    Write-Host ""
    Write-Host "API Request Failed!" -ForegroundColor Red
    Write-Host ""
    
    if ($_.Exception.Response) {
        $streamReader = [System.IO.StreamReader]::new($_.Exception.Response.GetResponseStream())
        $errorBody = $streamReader.ReadToEnd()
        $streamReader.Close()
        
        Write-Host "Error Details:" -ForegroundColor Red
        try {
            $errorJson = $errorBody | ConvertFrom-Json
            if ($errorJson.error) {
                Write-Host "  Type: $($errorJson.error.type)" -ForegroundColor Yellow
                Write-Host "  Message: $($errorJson.error.message)" -ForegroundColor Yellow
            } else {
                Write-Host $errorBody -ForegroundColor Yellow
            }
        } catch {
            Write-Host $errorBody -ForegroundColor Yellow
        }
    } else {
        Write-Host "Error: $_" -ForegroundColor Red
    }
    
    Write-Host ""
    Write-Host "Troubleshooting:" -ForegroundColor Cyan
    Write-Host "1. Check your API key is valid" -ForegroundColor White
    Write-Host "2. Ensure you have API credits remaining" -ForegroundColor White
    Write-Host "3. Check your internet connection" -ForegroundColor White
    Write-Host '4. Visit: https://console.anthropic.com' -ForegroundColor White
    
    exit 1
}

# SIG # Begin signature block
# MIIFqQYJKoZIhvcNAQcCoIIFmjCCBZYCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUNypsuD7lkJP0h6VV5b5mTq68
# DuugggMwMIIDLDCCAhSgAwIBAgIQdR0W2SKoK5VE8JId4ZxrRTANBgkqhkiG9w0B
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
# CQQxFgQUwlURmkw2whKTWwMz7iAvGL+92fEwDQYJKoZIhvcNAQEBBQAEggEAYMaB
# rV1DpKoteGSNB3+YluQag4OAgk7CThYnwCOXvNDvScjuZv+wjqiZI2k5GmQ6pgTn
# YOpBK46SzzPBGPr27hTxEVGH/U4tKRWv+de16wNFnXS3l2uobQG9GP0MxRjozSQb
# NRL9Ulp8+nVCdM7YndWWiiC1pU1fy5kbaN/aOEYrQPrkmtdJkDLX7rWTD8ash/h5
# GKaRefyg5tetokW9uXGS/kvSzO3qzQgCpPpSEqR33mSlAcLswIwhANLO0ymxHZER
# 8+rneU3YXhziC5tTqOLttoirD3Nd5wELf30bojXciU6xGiWgcd39/fCPcF5vaH7A
# mzHATEAf6/bwvx9Cqg==
# SIG # End signature block
