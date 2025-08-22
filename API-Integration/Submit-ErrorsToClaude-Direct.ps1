# Submit-ErrorsToClaude-Direct.ps1
# Direct submission using PowerShell native piping

[CmdletBinding()]
param(
    [string]$ErrorLogPath,
    [string]$ErrorType = 'Last',
    [switch]$Verbose
)

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host " Claude Direct Submission" -ForegroundColor Cyan
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
Write-Host ""

# Build a concise prompt for headless mode
$prompt = "Unity automation detected $errorCount errors. Please analyze and provide specific fixes:`n`n$errorContent"

try {
    Write-Host "Method 1: Direct PowerShell piping..." -ForegroundColor Cyan
    
    # Method 1: Direct piping with PowerShell
    $result = $prompt | & claude -p "Analyze these Unity errors and provide fixes" 2>&1
    
    if ($result) {
        Write-Host ""
        Write-Host "Claude's Response:" -ForegroundColor Green
        Write-Host "=================" -ForegroundColor Green
        Write-Host $result
        
        # Save response
        $responseFile = Join-Path $PSScriptRoot "ClaudeResponse_$(Get-Date -Format 'yyyyMMdd_HHmmss').md"
        $result | Set-Content -Path $responseFile
        Write-Host ""
        Write-Host "Response saved to: $responseFile" -ForegroundColor Gray
    } else {
        throw "No response from claude"
    }
    
} catch {
    Write-Host "Method 1 failed: $_" -ForegroundColor Yellow
    Write-Host ""
    
    try {
        Write-Host "Method 2: Using echo piping..." -ForegroundColor Cyan
        
        # Method 2: Echo with escaped quotes
        $escapedPrompt = $prompt -replace '"', '\"'
        $result = echo "$escapedPrompt" | & claude -p "Analyze and fix these errors" 2>&1
        
        if ($result) {
            Write-Host ""
            Write-Host "Claude's Response:" -ForegroundColor Green
            Write-Host "=================" -ForegroundColor Green
            Write-Host $result
            
            # Save response
            $responseFile = Join-Path $PSScriptRoot "ClaudeResponse_$(Get-Date -Format 'yyyyMMdd_HHmmss').md"
            $result | Set-Content -Path $responseFile
            Write-Host ""
            Write-Host "Response saved to: $responseFile" -ForegroundColor Gray
        } else {
            throw "No response from echo method"
        }
        
    } catch {
        Write-Host "Method 2 failed: $_" -ForegroundColor Yellow
        Write-Host ""
        
        # Method 3: File-based approach
        Write-Host "Method 3: File-based submission..." -ForegroundColor Cyan
        
        $tempFile = [System.IO.Path]::GetTempFileName()
        $prompt | Set-Content -Path $tempFile -Encoding UTF8
        
        Write-Host "Running: Get-Content $tempFile | claude -p ..." -ForegroundColor Gray
        
        $result = Get-Content $tempFile -Raw | & claude -p "Analyze these Unity errors" 2>&1
        
        if ($result) {
            Write-Host ""
            Write-Host "Claude's Response:" -ForegroundColor Green
            Write-Host "=================" -ForegroundColor Green
            Write-Host $result
            
            # Save response
            $responseFile = Join-Path $PSScriptRoot "ClaudeResponse_$(Get-Date -Format 'yyyyMMdd_HHmmss').md"
            $result | Set-Content -Path $responseFile
            Write-Host ""
            Write-Host "Response saved to: $responseFile" -ForegroundColor Gray
        }
        
        Remove-Item $tempFile -Force -ErrorAction SilentlyContinue
    }
}

Write-Host ""
Write-Host "========================================" -ForegroundColor DarkGray
Write-Host " Submission Complete" -ForegroundColor White
Write-Host "========================================" -ForegroundColor DarkGray
# SIG # Begin signature block
# MIIFqQYJKoZIhvcNAQcCoIIFmjCCBZYCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQU2B/8TQTY6xOa/zXXZxFK9DtV
# yQmgggMwMIIDLDCCAhSgAwIBAgIQdR0W2SKoK5VE8JId4ZxrRTANBgkqhkiG9w0B
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
# CQQxFgQUxtyOyHwaybDrVNY2xSdQxidK9nswDQYJKoZIhvcNAQEBBQAEggEAVFM/
# H7HKTlPzQRkq6rTInBkFWfRYQYZ6tlHX8yQhZXdUPYKZMADFw5xdxzfQ/7N1QYx9
# GRhmNkphV8vuoI5ZWq9xEFwd4Sd4zreDYvaE3Nqdy5rVMPHHZEHgJ131MrA+t9Qf
# ikIshO1Co6vtYnQNFPjYvJRMq37YmbFR/tKtWIlLM8n2yhf6/AflN4dKZ1fvzhD4
# suMoGK4f4fB4VROd1ZPQ4Bz05No8wUK6ti58qFGJpWim4V7O6u62yzrVETjdGTx1
# VXWQBPRT140Rx8c+P3qaeRLv2sbWuWP8crZkd/slmU8jzCIfIKt2jVp3GyieFD2i
# QelZrRqTPgJviaXtiQ==
# SIG # End signature block
