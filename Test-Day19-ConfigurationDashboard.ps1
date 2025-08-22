# Test-Day19-ConfigurationDashboard.ps1
# Day 19: Test Suite for Configuration Management and Dashboard
# Validates all Day 19 implementation components

param(
    [switch]$Verbose,
    [switch]$SaveResults
)

$testResults = @()
$startTime = Get-Date

Write-Host "================================================" -ForegroundColor Cyan
Write-Host "  Day 19: Configuration & Dashboard Test Suite" -ForegroundColor Yellow
Write-Host "================================================" -ForegroundColor Cyan
Write-Host ""

# Test 1: Configuration Module Loading
Write-Host "[TEST 1] Configuration Module Loading..." -ForegroundColor Yellow
try {
    Import-Module (Join-Path $PSScriptRoot "Unity-Claude-Configuration.psm1") -Force -ErrorAction Stop
    
    $functions = @(
        'Get-AutomationConfig',
        'Set-AutomationConfig',
        'Test-AutomationConfig',
        'Get-ConfigurationSummary'
    )
    
    $allFound = $true
    foreach ($func in $functions) {
        if (-not (Get-Command $func -ErrorAction SilentlyContinue)) {
            Write-Host "  Missing function: $func" -ForegroundColor Red
            $allFound = $false
        }
    }
    
    if ($allFound) {
        Write-Host "  SUCCESS: All configuration functions available" -ForegroundColor Green
        $testResults += @{ Test = "Module Loading"; Result = "PASS"; Details = "All functions loaded" }
    } else {
        throw "Some functions missing"
    }
} catch {
    Write-Host "  FAILED: $_" -ForegroundColor Red
    $testResults += @{ Test = "Module Loading"; Result = "FAIL"; Details = $_.ToString() }
}

# Test 2: Configuration File Existence
Write-Host "[TEST 2] Configuration Files..." -ForegroundColor Yellow
try {
    $configFiles = @(
        "autonomous_config.json",
        "autonomous_config.development.json",
        "autonomous_config.production.json"
    )
    
    $allExist = $true
    foreach ($file in $configFiles) {
        $path = Join-Path $PSScriptRoot $file
        if (Test-Path $path) {
            Write-Host "    Found: $file" -ForegroundColor Green
        } else {
            Write-Host "    Missing: $file" -ForegroundColor Red
            $allExist = $false
        }
    }
    
    if ($allExist) {
        Write-Host "  SUCCESS: All configuration files present" -ForegroundColor Green
        $testResults += @{ Test = "Config Files"; Result = "PASS"; Details = "All files exist" }
    } else {
        throw "Some configuration files missing"
    }
} catch {
    Write-Host "  FAILED: $_" -ForegroundColor Red
    $testResults += @{ Test = "Config Files"; Result = "FAIL"; Details = $_.ToString() }
}

# Test 3: Configuration Loading
Write-Host "[TEST 3] Configuration Loading..." -ForegroundColor Yellow
try {
    $config = Get-AutomationConfig -Environment "development"
    
    if ($config) {
        Write-Host "    Loaded sections: $($config.Keys -join ', ')" -ForegroundColor Gray
        
        # Check required sections
        $requiredSections = @("autonomous_operation", "claude_cli", "monitoring", "dashboard")
        $missingSections = @()
        
        foreach ($section in $requiredSections) {
            if (-not $config.ContainsKey($section)) {
                $missingSections += $section
            }
        }
        
        if ($missingSections.Count -eq 0) {
            Write-Host "  SUCCESS: Configuration loaded with all required sections" -ForegroundColor Green
            $testResults += @{ Test = "Config Loading"; Result = "PASS"; Details = "All sections present" }
        } else {
            throw "Missing sections: $($missingSections -join ', ')"
        }
    } else {
        throw "Failed to load configuration"
    }
} catch {
    Write-Host "  FAILED: $_" -ForegroundColor Red
    $testResults += @{ Test = "Config Loading"; Result = "FAIL"; Details = $_.ToString() }
}

# Test 4: Configuration Get/Set Operations
Write-Host "[TEST 4] Configuration Get/Set Operations..." -ForegroundColor Yellow
try {
    # Test getting a specific value
    $originalValue = Get-AutomationConfig -Section "autonomous_operation.max_conversation_rounds"
    Write-Host "    Original value: $originalValue" -ForegroundColor Gray
    
    # Test setting a value
    $testValue = 42
    $setResult = Set-AutomationConfig -Section "test.temporary.value" -Value $testValue
    
    if ($setResult) {
        # Verify the value was set
        $getValue = Get-AutomationConfig -Section "test.temporary.value"
        
        if ($getValue -eq $testValue) {
            Write-Host "  SUCCESS: Get/Set operations working correctly" -ForegroundColor Green
            $testResults += @{ Test = "Config Get/Set"; Result = "PASS"; Details = "Values match" }
        } else {
            throw "Set value ($testValue) doesn't match get value ($getValue)"
        }
    } else {
        throw "Failed to set configuration value"
    }
} catch {
    Write-Host "  FAILED: $_" -ForegroundColor Red
    $testResults += @{ Test = "Config Get/Set"; Result = "FAIL"; Details = $_.ToString() }
}

# Test 5: Configuration Validation
Write-Host "[TEST 5] Configuration Validation..." -ForegroundColor Yellow
try {
    $validation = Test-AutomationConfig -Environment "development"
    
    if ($validation) {
        Write-Host "    Validation complete: $($validation.Results.Count) checks performed" -ForegroundColor Gray
        
        $failedChecks = $validation.Results | Where-Object { -not $_.Valid }
        
        if ($failedChecks.Count -gt 0) {
            Write-Host "    Failed checks:" -ForegroundColor Yellow
            foreach ($check in $failedChecks) {
                Write-Host "      - $($check.Section): $($check.Message)" -ForegroundColor Yellow
            }
        }
        
        if ($validation.Valid) {
            Write-Host "  SUCCESS: Configuration is valid" -ForegroundColor Green
            $testResults += @{ Test = "Config Validation"; Result = "PASS"; Details = "All checks passed" }
        } else {
            Write-Host "  WARNING: Configuration has validation issues" -ForegroundColor Yellow
            $testResults += @{ Test = "Config Validation"; Result = "WARN"; Details = "$($failedChecks.Count) issues" }
        }
    } else {
        throw "Validation returned null"
    }
} catch {
    Write-Host "  FAILED: $_" -ForegroundColor Red
    $testResults += @{ Test = "Config Validation"; Result = "FAIL"; Details = $_.ToString() }
}

# Test 6: Configuration Summary
Write-Host "[TEST 6] Configuration Summary..." -ForegroundColor Yellow
try {
    $summary = Get-ConfigurationSummary -Environment "development"
    
    if ($summary) {
        Write-Host "    Environment: $($summary.Environment)" -ForegroundColor Gray
        Write-Host "    Total Settings: $($summary.Statistics.TotalSettings)" -ForegroundColor Gray
        Write-Host "    Enabled Features: $($summary.Statistics.EnabledFeatures -join ', ')" -ForegroundColor Gray
        
        Write-Host "  SUCCESS: Configuration summary generated" -ForegroundColor Green
        $testResults += @{ Test = "Config Summary"; Result = "PASS"; Details = "$($summary.Statistics.TotalSettings) settings" }
    } else {
        throw "Summary returned null"
    }
} catch {
    Write-Host "  FAILED: $_" -ForegroundColor Red
    $testResults += @{ Test = "Config Summary"; Result = "FAIL"; Details = $_.ToString() }
}

# Test 7: Dashboard Scripts Existence
Write-Host "[TEST 7] Dashboard Scripts..." -ForegroundColor Yellow
try {
    $dashboardScripts = @(
        "Start-EnhancedDashboard.ps1",
        "Edit-AutomationConfig.ps1"
    )
    
    $allExist = $true
    foreach ($script in $dashboardScripts) {
        $path = Join-Path $PSScriptRoot $script
        if (Test-Path $path) {
            Write-Host "    Found: $script" -ForegroundColor Green
        } else {
            Write-Host "    Missing: $script" -ForegroundColor Red
            $allExist = $false
        }
    }
    
    if ($allExist) {
        Write-Host "  SUCCESS: All dashboard scripts present" -ForegroundColor Green
        $testResults += @{ Test = "Dashboard Scripts"; Result = "PASS"; Details = "All scripts exist" }
    } else {
        throw "Some dashboard scripts missing"
    }
} catch {
    Write-Host "  FAILED: $_" -ForegroundColor Red
    $testResults += @{ Test = "Dashboard Scripts"; Result = "FAIL"; Details = $_.ToString() }
}

# Test 8: UniversalDashboard Module Check
Write-Host "[TEST 8] UniversalDashboard Module..." -ForegroundColor Yellow
try {
    $udModule = Get-Module -ListAvailable -Name "UniversalDashboard.Community"
    
    if ($udModule) {
        Write-Host "    Version: $($udModule.Version)" -ForegroundColor Gray
        Write-Host "  SUCCESS: UniversalDashboard.Community module available" -ForegroundColor Green
        $testResults += @{ Test = "UD Module"; Result = "PASS"; Details = "Version $($udModule.Version)" }
    } else {
        Write-Host "  WARNING: UniversalDashboard.Community not installed" -ForegroundColor Yellow
        Write-Host "    Run: Install-UniversalDashboard.ps1" -ForegroundColor Gray
        $testResults += @{ Test = "UD Module"; Result = "WARN"; Details = "Not installed" }
    }
} catch {
    Write-Host "  FAILED: $_" -ForegroundColor Red
    $testResults += @{ Test = "UD Module"; Result = "FAIL"; Details = $_.ToString() }
}

# Test 9: Configuration Environment Switching
Write-Host "[TEST 9] Environment Switching..." -ForegroundColor Yellow
try {
    $environments = @("development", "production", "test")
    $allWork = $true
    
    foreach ($env in $environments) {
        $config = Get-AutomationConfig -Environment $env -Force
        if ($config) {
            Write-Host "    ${env}: Loaded successfully" -ForegroundColor Green
        } else {
            Write-Host "    ${env}: Failed to load" -ForegroundColor Red
            $allWork = $false
        }
    }
    
    if ($allWork) {
        Write-Host "  SUCCESS: All environments can be loaded" -ForegroundColor Green
        $testResults += @{ Test = "Env Switching"; Result = "PASS"; Details = "All environments work" }
    } else {
        throw "Some environments failed to load"
    }
} catch {
    Write-Host "  FAILED: $_" -ForegroundColor Red
    $testResults += @{ Test = "Env Switching"; Result = "FAIL"; Details = $_.ToString() }
}

# Test 10: Integration Test
Write-Host "[TEST 10] Integration Test..." -ForegroundColor Yellow
try {
    # Test the full workflow
    Write-Host "    1. Loading config..." -ForegroundColor Gray
    $config = Get-AutomationConfig -Environment "development"
    
    Write-Host "    2. Modifying value..." -ForegroundColor Gray
    $testSection = "integration_test.timestamp"
    Set-AutomationConfig -Section $testSection -Value (Get-Date).ToString()
    
    Write-Host "    3. Validating..." -ForegroundColor Gray
    $validation = Test-AutomationConfig -Environment "development"
    
    Write-Host "    4. Getting summary..." -ForegroundColor Gray
    $summary = Get-ConfigurationSummary -Environment "development"
    
    if ($config -and $validation -and $summary) {
        Write-Host "  SUCCESS: Full integration workflow completed" -ForegroundColor Green
        $testResults += @{ Test = "Integration"; Result = "PASS"; Details = "All steps completed" }
    } else {
        throw "Integration test incomplete"
    }
} catch {
    Write-Host "  FAILED: $_" -ForegroundColor Red
    $testResults += @{ Test = "Integration"; Result = "FAIL"; Details = $_.ToString() }
}

# Calculate summary
$endTime = Get-Date
$duration = $endTime - $startTime

$passCount = ($testResults | Where-Object { $_.Result -eq "PASS" }).Count
$warnCount = ($testResults | Where-Object { $_.Result -eq "WARN" }).Count
$failCount = ($testResults | Where-Object { $_.Result -eq "FAIL" }).Count
$totalTests = $testResults.Count

Write-Host ""
Write-Host "================================================" -ForegroundColor Cyan
Write-Host "                TEST SUMMARY" -ForegroundColor Yellow
Write-Host "================================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Total Tests: $totalTests" -ForegroundColor White
Write-Host "Passed: $passCount" -ForegroundColor Green
Write-Host "Warnings: $warnCount" -ForegroundColor Yellow
Write-Host "Failed: $failCount" -ForegroundColor Red
Write-Host "Duration: $([Math]::Round($duration.TotalSeconds, 2)) seconds" -ForegroundColor Gray
Write-Host ""

# Display results table
Write-Host "Test Results:" -ForegroundColor Cyan
$testResults | ForEach-Object {
    $color = switch ($_.Result) {
        "PASS" { "Green" }
        "WARN" { "Yellow" }
        "FAIL" { "Red" }
    }
    Write-Host "  [$($_.Result)]" -NoNewline -ForegroundColor $color
    Write-Host " $($_.Test): $($_.Details)" -ForegroundColor Gray
}

# Save results if requested
if ($SaveResults) {
    $resultsFile = Join-Path $PSScriptRoot "Day19_TestResults_$(Get-Date -Format 'yyyyMMdd_HHmmss').json"
    
    $report = @{
        Timestamp = Get-Date
        Duration = $duration.TotalSeconds
        Environment = $env:COMPUTERNAME
        Summary = @{
            Total = $totalTests
            Passed = $passCount
            Warnings = $warnCount
            Failed = $failCount
        }
        Results = $testResults
    }
    
    $report | ConvertTo-Json -Depth 5 | Set-Content $resultsFile
    Write-Host ""
    Write-Host "Results saved to: $resultsFile" -ForegroundColor Cyan
}

# Final verdict
Write-Host ""
if ($failCount -eq 0) {
    if ($warnCount -eq 0) {
        Write-Host "ALL TESTS PASSED! Day 19 implementation successful!" -ForegroundColor Green
    } else {
        Write-Host "Day 19 implementation functional with $warnCount warnings." -ForegroundColor Yellow
    }
} else {
    Write-Host "Day 19 implementation has $failCount failures that need attention." -ForegroundColor Red
}

Write-Host ""
Write-Host "Day 19 Configuration & Dashboard Test Complete!" -ForegroundColor Cyan
# SIG # Begin signature block
# MIIFqQYJKoZIhvcNAQcCoIIFmjCCBZYCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUPbKEgYXJ1YiFBJ4MSB6dpQNx
# hx6gggMwMIIDLDCCAhSgAwIBAgIQdR0W2SKoK5VE8JId4ZxrRTANBgkqhkiG9w0B
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
# CQQxFgQUl2g/rKHrMcnTtajoMTjM0Z4mGWIwDQYJKoZIhvcNAQEBBQAEggEAA7eK
# yl1pbhH6Wcx9G/wlIK4opgrgabLG2CdNFC3/AAjoXa0CWHNsWJbxT3ZuZpmOE0oo
# lY/NlpdafMJ85hw/mY4X50C8AyZCgk4W7FAmO+EphZMmmYP9IXSDrrh9JSRm1YVY
# u/5GhwrkgIuVjYllywkJFM8TNBcnuPBJAg8+SxB0wM5XkIvXjfN0CZ8+HHwowLvi
# HE/yrXwjSDceIdwsX7kcTviaUlOlhkpD/w7PbogaQtCOuG8NRh3OHl3Y9ZeRR1Lx
# NNNWgNlxqzpjoHX9YP0Wl4rZVecfH+BioX042P9rOD7IDMaGZf7yDuykINKX522R
# pQIfhaSq3P2r2X1ytA==
# SIG # End signature block
