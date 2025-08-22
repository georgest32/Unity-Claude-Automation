# Test-Day18-Hour2.5-Basic-ModuleLoad.ps1
# Basic module loading test to identify crash source
# Simplified test to isolate issues causing PowerShell window closure

[CmdletBinding()]
param(
    [switch]$SaveResults = $true
)

$ErrorActionPreference = "Continue"

function Write-SafeLog {
    param([string]$Message, [string]$Level = "INFO")
    $timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss.fff'
    $logLine = "[$timestamp] [$Level] $Message"
    Write-Host $logLine
    
    # Also write to file immediately for crash investigation
    try {
        Add-Content -Path "basic_test_log.txt" -Value $logLine -ErrorAction SilentlyContinue
    } catch {
        # Ignore file write errors
    }
}

Write-SafeLog "========================================" -Level "INFO"
Write-SafeLog "Day 18 Hour 2.5: Basic Module Loading Test" -Level "INFO"
Write-SafeLog "Purpose: Identify source of PowerShell window crash" -Level "INFO"
Write-SafeLog "========================================" -Level "INFO"

# Test 1: Check if module file exists
Write-SafeLog "Test 1: Checking if Unity-Claude-SystemStatus module file exists" -Level "INFO"
try {
    $modulePath = ".\Modules\Unity-Claude-SystemStatus\Unity-Claude-SystemStatus.psm1"
    if (Test-Path $modulePath) {
        Write-SafeLog "Module file found: $modulePath" -Level "OK"
    } else {
        Write-SafeLog "Module file NOT found: $modulePath" -Level "ERROR"
        exit 1
    }
} catch {
    Write-SafeLog "Error checking module file: $_" -Level "ERROR"
    exit 1
}

# Test 2: Try to read module content without loading
Write-SafeLog "Test 2: Reading module content to check for syntax issues" -Level "INFO"
try {
    $moduleContent = Get-Content $modulePath -Raw -ErrorAction Stop
    $contentLength = $moduleContent.Length
    Write-SafeLog "Module content read successfully: $contentLength characters" -Level "OK"
} catch {
    Write-SafeLog "Error reading module content: $_" -Level "ERROR"
    exit 1
}

# Test 3: Check PowerShell syntax without executing
Write-SafeLog "Test 3: Checking PowerShell syntax validation" -Level "INFO"
try {
    $tokens = $null
    $errors = $null
    [System.Management.Automation.Language.Parser]::ParseInput($moduleContent, [ref]$tokens, [ref]$errors)
    
    if ($errors.Count -eq 0) {
        Write-SafeLog "PowerShell syntax validation passed: No syntax errors found" -Level "OK"
    } else {
        Write-SafeLog "PowerShell syntax validation failed: $($errors.Count) errors found" -Level "ERROR"
        foreach ($error in $errors) {
            Write-SafeLog "Syntax Error: $($error.Message) at line $($error.Extent.StartLineNumber)" -Level "ERROR"
        }
        exit 1
    }
} catch {
    Write-SafeLog "Error during syntax validation: $_" -Level "ERROR"
    exit 1
}

# Test 4: Try loading System.Core assembly (required for named pipes)
Write-SafeLog "Test 4: Testing System.Core assembly loading" -Level "INFO"
try {
    Add-Type -AssemblyName System.Core -ErrorAction Stop
    Write-SafeLog "System.Core assembly loaded successfully" -Level "OK"
} catch {
    Write-SafeLog "Failed to load System.Core assembly: $_" -Level "ERROR"
    # Don't exit - this might not be critical
}

# Test 5: Try creating concurrent collections (used in module)
Write-SafeLog "Test 5: Testing concurrent collections creation" -Level "INFO"
try {
    $testQueue = [System.Collections.Concurrent.ConcurrentQueue[PSObject]]::new()
    $testDict = [System.Collections.Concurrent.ConcurrentDictionary[string,PSObject]]::new()
    Write-SafeLog "Concurrent collections created successfully" -Level "OK"
} catch {
    Write-SafeLog "Failed to create concurrent collections: $_" -Level "ERROR"
    exit 1
}

# Test 6: Try importing module with error handling
Write-SafeLog "Test 6: Attempting to import Unity-Claude-SystemStatus module" -Level "INFO"
try {
    Write-SafeLog "Starting module import..." -Level "DEBUG"
    Import-Module $modulePath -Force -ErrorAction Stop
    Write-SafeLog "Module imported successfully" -Level "OK"
    
    # Test basic function availability
    $functions = Get-Command -Module "Unity-Claude-SystemStatus" -ErrorAction SilentlyContinue
    Write-SafeLog "Module functions available: $($functions.Count)" -Level "INFO"
    
} catch {
    Write-SafeLog "Module import failed: $_" -Level "ERROR"
    Write-SafeLog "Exception Type: $($_.Exception.GetType().Name)" -Level "ERROR"
    Write-SafeLog "Stack Trace: $($_.Exception.StackTrace)" -Level "ERROR"
    exit 1
}

# Test 7: Try basic module function (safest one)
Write-SafeLog "Test 7: Testing basic module function execution" -Level "INFO"
try {
    if (Get-Command "Write-SystemStatusLog" -ErrorAction SilentlyContinue) {
        Write-SystemStatusLog "Test log message from basic test" -Level "INFO"
        Write-SafeLog "Basic module function executed successfully" -Level "OK"
    } else {
        Write-SafeLog "Write-SystemStatusLog function not available" -Level "WARN"
    }
} catch {
    Write-SafeLog "Error executing basic module function: $_" -Level "ERROR"
    # Don't exit - this is just a test
}

# Test 8: Try module cleanup
Write-SafeLog "Test 8: Testing module cleanup" -Level "INFO"
try {
    Remove-Module "Unity-Claude-SystemStatus" -Force -ErrorAction SilentlyContinue
    Write-SafeLog "Module removed successfully" -Level "OK"
} catch {
    Write-SafeLog "Error removing module: $_" -Level "ERROR"
}

Write-SafeLog "========================================" -Level "INFO"
Write-SafeLog "Basic Module Loading Test Complete" -Level "INFO"
Write-SafeLog "If this test completed without crashing, the issue is in specific module functions" -Level "INFO"
Write-SafeLog "========================================" -Level "INFO"

# Save results
if ($SaveResults) {
    try {
        $resultsPath = "basic_module_test_results.txt"
        "Basic Module Loading Test Results - $(Get-Date)" | Out-File $resultsPath -Encoding UTF8
        "Test completed successfully without PowerShell window crash" | Add-Content $resultsPath -Encoding UTF8
        "Next step: Test individual module functions incrementally" | Add-Content $resultsPath -Encoding UTF8
        Write-SafeLog "Results saved to: $resultsPath" -Level "OK"
    } catch {
        Write-SafeLog "Failed to save results: $_" -Level "ERROR"
    }
}

Write-SafeLog "Basic test complete - Press Enter to continue or Ctrl+C to exit" -Level "INFO"
Read-Host "Press Enter to exit"
# SIG # Begin signature block
# MIIFqQYJKoZIhvcNAQcCoIIFmjCCBZYCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUr8pCjx+e36xSNQYT9yrfwL4m
# IbKgggMwMIIDLDCCAhSgAwIBAgIQdR0W2SKoK5VE8JId4ZxrRTANBgkqhkiG9w0B
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
# CQQxFgQUZRnEJE+FrVJ/03pidqBv1L5HShwwDQYJKoZIhvcNAQEBBQAEggEAV0Zq
# 7lGKmjrlo5ByCr9wHbjVNUbkV8yn74502OS9obtzaK5bIex1UE3DYqt84KvdtmWe
# i+HW9/z5q1PlfP7sV3vg+bYu2DmYPKY5acymQ/pYcwdAR/huj72Ror6f82GnZUTV
# oP8H28OBVtu9XGkie3YlqodxQB25yZpTQmLMiU8gNSzrcbjty6ceyGTJ3O4OS/sf
# pMP8egzoKpmZT7ffD+M0tCZ2NUbAJXveZH5QFfn5XxwgOKPIpXPb93Z0cvbi0yaI
# k4kGm4S+e6NuzSZeA9bIqqmsto+8Ss9jYlDYXAVXwsM8YuOzGgwFX/Eu5rHZEfA2
# snlu/d+iPFSdaa+gyA==
# SIG # End signature block
