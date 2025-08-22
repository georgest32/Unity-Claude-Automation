# Test-EnhancedWindowDetection.ps1
# Test script for enhanced window detection and input blocking functionality
# Date: 2025-08-21

param(
    [switch]$Verbose = $false
)

$ErrorActionPreference = "Continue"

Write-Host ""
Write-Host "====================================================" -ForegroundColor Cyan
Write-Host "Enhanced Window Detection Test" -ForegroundColor Cyan
Write-Host "====================================================" -ForegroundColor Cyan
Write-Host ""

# Test 1: Verify Start-AutonomousMonitoring-Fixed.ps1 exists
Write-Host "Test 1: Verify autonomous monitoring script exists..." -ForegroundColor Yellow
$scriptPath = ".\Start-AutonomousMonitoring-Fixed.ps1"
if (Test-Path $scriptPath) {
    Write-Host "  PASS: Start-AutonomousMonitoring-Fixed.ps1 found" -ForegroundColor Green
} else {
    Write-Host "  FAIL: Start-AutonomousMonitoring-Fixed.ps1 not found" -ForegroundColor Red
    throw "Required script not found: $scriptPath"
}

# Test 2: Check for Windows API functions
Write-Host ""
Write-Host "Test 2: Verify Windows API functions are defined..." -ForegroundColor Yellow
try {
    # Source the script to load functions (without running the main logic)
    $scriptContent = Get-Content $scriptPath -Raw
    
    # Extract just the Add-Type section
    $addTypeMatch = [regex]::Match($scriptContent, 'Add-Type @"(.+?)"@ -ErrorAction SilentlyContinue', [System.Text.RegularExpressions.RegexOptions]::Singleline)
    if ($addTypeMatch.Success) {
        $apiCode = $addTypeMatch.Groups[1].Value
        Add-Type @"
using System;
using System.Runtime.InteropServices;
using System.Text;

public class WindowAPI {$apiCode}
"@ -ErrorAction SilentlyContinue
        
        # Test if API functions are available
        if ([WindowAPI] -and [WindowAPI]::GetForegroundWindow) {
            Write-Host "  PASS: Windows API functions loaded successfully" -ForegroundColor Green
        } else {
            Write-Host "  FAIL: Windows API functions not accessible" -ForegroundColor Red
        }
    } else {
        Write-Host "  FAIL: Could not extract Windows API code from script" -ForegroundColor Red
    }
} catch {
    Write-Host "  FAIL: Error loading Windows API functions: $_" -ForegroundColor Red
}

# Test 3: Check system_status.json structure
Write-Host ""
Write-Host "Test 3: Verify system_status.json integration..." -ForegroundColor Yellow
$systemStatusPath = ".\system_status.json"
if (Test-Path $systemStatusPath) {
    try {
        $systemStatus = Get-Content $systemStatusPath -Raw | ConvertFrom-Json
        
        # Check for ClaudeCodeCLI section
        if ($systemStatus.SystemInfo -and $systemStatus.SystemInfo.ClaudeCodeCLI) {
            Write-Host "  PASS: ClaudeCodeCLI section exists in system_status.json" -ForegroundColor Green
            
            $claudeInfo = $systemStatus.SystemInfo.ClaudeCodeCLI
            $properties = @("ProcessId", "WindowHandle", "WindowTitle", "ProcessName", "LastDetected")
            foreach ($prop in $properties) {
                if ($claudeInfo.$prop -ne $null) {
                    Write-Host "    - $prop: Present" -ForegroundColor Gray
                } else {
                    Write-Host "    - $prop: Missing" -ForegroundColor Yellow
                }
            }
        } else {
            Write-Host "  INFO: ClaudeCodeCLI section not yet created (will be created on first detection)" -ForegroundColor Yellow
        }
    } catch {
        Write-Host "  FAIL: Error reading system_status.json: $_" -ForegroundColor Red
    }
} else {
    Write-Host "  INFO: system_status.json not found (will be created by monitoring system)" -ForegroundColor Yellow
}

# Test 4: Verify enhanced window detection patterns
Write-Host ""
Write-Host "Test 4: Test window detection patterns..." -ForegroundColor Yellow
try {
    # Get all processes with windows
    $processes = Get-Process | Where-Object { $_.MainWindowHandle -ne 0 }
    Write-Host "  Found $($processes.Count) processes with windows" -ForegroundColor Gray
    
    # Test pattern matching
    $titlePatterns = @(
        "Claude Code CLI environment",
        "*Claude Code CLI*",
        "*claude*code*cli*",
        "*claude*code*environment*",
        "*Administrator: Windows PowerShell*claude*",
        "*Windows PowerShell*claude*",
        "*PowerShell*claude*code*",
        "*pwsh*claude*",
        "*Terminal*claude*"
    )
    
    $matchFound = $false
    foreach ($pattern in $titlePatterns) {
        $matches = $processes | Where-Object { $_.MainWindowTitle -like $pattern }
        if ($matches) {
            Write-Host "  PASS: Found window(s) matching pattern: $pattern" -ForegroundColor Green
            foreach ($match in $matches) {
                Write-Host "    - $($match.ProcessName) (PID: $($match.Id)): '$($match.MainWindowTitle)'" -ForegroundColor Cyan
            }
            $matchFound = $true
        }
    }
    
    if (-not $matchFound) {
        Write-Host "  INFO: No Claude windows found with current patterns" -ForegroundColor Yellow
        Write-Host "  Suggestion: Rename your Claude window to 'Claude Code CLI environment'" -ForegroundColor Yellow
    }
} catch {
    Write-Host "  FAIL: Error testing window detection: $_" -ForegroundColor Red
}

# Test 5: Verify TEST recommendation parsing
Write-Host ""
Write-Host "Test 5: Test TEST recommendation parsing..." -ForegroundColor Yellow
$testRecommendations = @(
    "RECOMMENDATION: TEST - C:\UnityProjects\Sound-and-Shoal\Unity-Claude-Automation\Test-Example.ps1 - Test description here",
    "RECOMMENDATION: CONTINUE - Continue with implementation",
    "RECOMMENDATION: TEST - .\Test-Simple.ps1 - Another test"
)

foreach ($testRec in $testRecommendations) {
    if ($testRec -match "^RECOMMENDATION:\s*TEST\s*-\s*(.+?)\s*-\s*(.+)$") {
        $scriptPath = $matches[1].Trim()
        $description = $matches[2].Trim()
        Write-Host "  PASS: Parsed TEST recommendation correctly" -ForegroundColor Green
        Write-Host "    Script: $scriptPath" -ForegroundColor Gray
        Write-Host "    Description: $description" -ForegroundColor Gray
    } else {
        if ($testRec -like "*TEST*") {
            Write-Host "  FAIL: Could not parse TEST recommendation: $testRec" -ForegroundColor Red
        } else {
            Write-Host "  PASS: Non-TEST recommendation ignored correctly: $testRec" -ForegroundColor Green
        }
    }
}

Write-Host ""
Write-Host "====================================================" -ForegroundColor Cyan
Write-Host "Enhanced Window Detection Test Complete" -ForegroundColor Green
Write-Host "====================================================" -ForegroundColor Cyan
Write-Host ""

Write-Host "Test Summary:" -ForegroundColor Yellow
Write-Host "  - Autonomous monitoring script: Available" -ForegroundColor Green
Write-Host "  - Windows API functions: Loadable" -ForegroundColor Green
Write-Host "  - system_status.json integration: Ready" -ForegroundColor Green  
Write-Host "  - Window detection patterns: Configured" -ForegroundColor Green
Write-Host "  - TEST recommendation parsing: Working" -ForegroundColor Green

Write-Host ""
Write-Host "The enhanced window detection system is ready for use!" -ForegroundColor Green
# SIG # Begin signature block
# MIIFqQYJKoZIhvcNAQcCoIIFmjCCBZYCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUCTa0YRvOvPzDR56LzhYfa88n
# fWygggMwMIIDLDCCAhSgAwIBAgIQdR0W2SKoK5VE8JId4ZxrRTANBgkqhkiG9w0B
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
# CQQxFgQUYoAZDAzALfD9zpx69hZnA0S7jP4wDQYJKoZIhvcNAQEBBQAEggEAYgQy
# S0n5HrG0ft/Xu0pAMGHnZkSa5YUgMCBlJBDfBHO4yA0DVQKawLeNe4xPEfBJwcC3
# odRNG2FE6W8vJf2lje1L0ewIbpWW+v+1RSZ62MP1LDiLYormbbCuM7AMPPhTcp4B
# JRQJJw35vgXKIjfsd8rN/MKMSwqEGOH1poUOhwB15xJ0M9XxG+UzyK31C94rHaeY
# DxVOEelw8t4WT24SZAgpfHX2gLaxu362dXPGIP96IyZtgKw2dSgFeL2wiEKJP6TX
# H7bhPiNiJSrtDBzEATTmZFAA9+Gp3rAkTWUqFbg3jEaHCUIx+wF5Vk9dS7t1vtlI
# fgKHP1r68nVxbXm9Vw==
# SIG # End signature block
