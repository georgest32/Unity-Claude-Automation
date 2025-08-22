# Test script for Unity-Claude Safety Framework
# Phase 3 Week 3: Validates all safety framework functionality

param(
    [switch]$Verbose
)

Write-Host "=== Testing Unity-Claude Safety Framework ===" -ForegroundColor Yellow
Write-Host "Date: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor Gray

# Import modules
try {
    Import-Module './Modules/Unity-Claude-Safety/Unity-Claude-Safety.psm1' -Force -DisableNameChecking
    Write-Host "[PASS] Module imported successfully" -ForegroundColor Green
} catch {
    Write-Host "[FAIL] Module import failed: $_" -ForegroundColor Red
    exit 1
}

$testResults = @{
    Passed = 0
    Failed = 0
    Skipped = 0
    Details = @()
}

function Test-SafetyFunction {
    param(
        [string]$TestName,
        [scriptblock]$TestBlock,
        [string]$ExpectedResult = ""
    )
    
    Write-Host "`nTesting: $TestName" -ForegroundColor Cyan
    
    try {
        $result = & $TestBlock
        
        if ($ExpectedResult -and $result -ne $ExpectedResult) {
            Write-Host "  [FAIL] Expected: $ExpectedResult, Got: $result" -ForegroundColor Red
            $script:testResults.Failed++
            $script:testResults.Details += "[FAIL] $TestName"
        } else {
            Write-Host "  [PASS] $TestName" -ForegroundColor Green
            $script:testResults.Passed++
            $script:testResults.Details += "[PASS] $TestName"
        }
        
        if ($Verbose -and $result) {
            Write-Host "  Result: $($result | ConvertTo-Json -Compress)" -ForegroundColor Gray
        }
        
    } catch {
        Write-Host "  [FAIL] Error: $_" -ForegroundColor Red
        $script:testResults.Failed++
        $script:testResults.Details += "[FAIL] $TestName - Error: $_"
    }
}

# Test 1: Configuration Management
Test-SafetyFunction -TestName "Get-SafetyConfiguration" -TestBlock {
    $config = Get-SafetyConfiguration
    if ($config.ConfidenceThreshold -eq 0.7) { return "PASS" } else { return "FAIL" }
} -ExpectedResult "PASS"

Test-SafetyFunction -TestName "Set-SafetyConfiguration" -TestBlock {
    Set-SafetyConfiguration -ConfidenceThreshold 0.8 -DryRunMode $true | Out-Null
    $config = Get-SafetyConfiguration
    if ($config.ConfidenceThreshold -eq 0.8 -and $config.DryRunMode -eq $true) { 
        # Reset to defaults
        Set-SafetyConfiguration -ConfidenceThreshold 0.7 -DryRunMode $false | Out-Null
        return "PASS" 
    } else { 
        return "FAIL" 
    }
} -ExpectedResult "PASS"

# Test 2: Critical File Detection
Test-SafetyFunction -TestName "Test-CriticalFile - ProjectSettings" -TestBlock {
    $isCritical = Test-CriticalFile -FilePath "C:\Unity\ProjectSettings\ProjectSettings.asset"
    if ($isCritical) { return "PASS" } else { return "FAIL" }
} -ExpectedResult "PASS"

Test-SafetyFunction -TestName "Test-CriticalFile - Regular Script" -TestBlock {
    $isCritical = Test-CriticalFile -FilePath "C:\Unity\Assets\Scripts\Player.cs"
    if (-not $isCritical) { return "PASS" } else { return "FAIL" }
} -ExpectedResult "PASS"

# Test 3: Safety Checks
Test-SafetyFunction -TestName "Test-FixSafety - Low Confidence" -TestBlock {
    $safety = Test-FixSafety -FilePath "C:\temp\test.txt" -Confidence 0.5 -FixContent "test content"
    if (-not $safety.IsSafe) { return "PASS" } else { return "FAIL" }
} -ExpectedResult "PASS"

Test-SafetyFunction -TestName "Test-FixSafety - High Confidence" -TestBlock {
    # Create test file
    $testFile = Join-Path $env:TEMP "safety_test_$(Get-Random).txt"
    "test" | Set-Content $testFile
    
    $safety = Test-FixSafety -FilePath $testFile -Confidence 0.85 -FixContent "safe content"
    
    # Clean up
    Remove-Item $testFile -Force -ErrorAction SilentlyContinue
    
    if ($safety.IsSafe) { return "PASS" } else { return "FAIL" }
} -ExpectedResult "PASS"

Test-SafetyFunction -TestName "Test-FixSafety - Critical File Low Confidence" -TestBlock {
    # Create test file with critical path structure
    $testDir = Join-Path $env:TEMP "TestProject\Packages"
    if (-not (Test-Path $testDir)) { New-Item -ItemType Directory -Path $testDir -Force | Out-Null }
    $testFile = Join-Path $testDir "manifest.json"
    "{}" | Set-Content $testFile
    
    $safety = Test-FixSafety -FilePath $testFile -Confidence 0.8 -FixContent "update"
    
    # Clean up
    Remove-Item $testFile -Force -ErrorAction SilentlyContinue
    Remove-Item (Split-Path $testDir) -Recurse -Force -ErrorAction SilentlyContinue
    
    # Should fail because critical files need 0.9 confidence
    if (-not $safety.IsSafe -and $safety.IsCriticalFile) { return "PASS" } else { return "FAIL" }
} -ExpectedResult "PASS"

# Test 4: Backup Functionality
Test-SafetyFunction -TestName "Invoke-SafetyBackup" -TestBlock {
    # Create test file
    $testFile = Join-Path $env:TEMP "backup_test_$(Get-Random).txt"
    "original content" | Set-Content $testFile
    
    $backupPath = Invoke-SafetyBackup -FilePath $testFile -BackupReason "Test backup"
    
    $backupExists = Test-Path $backupPath
    
    # Clean up
    Remove-Item $testFile -Force -ErrorAction SilentlyContinue
    if ($backupPath) { Remove-Item $backupPath -Force -ErrorAction SilentlyContinue }
    if ($backupPath) { Remove-Item "$backupPath.json" -Force -ErrorAction SilentlyContinue }
    
    if ($backupExists) { return "PASS" } else { return "FAIL" }
} -ExpectedResult "PASS"

# Test 5: Dry Run Capabilities
Test-SafetyFunction -TestName "Invoke-DryRun - Console Output" -TestBlock {
    # Create test files
    $testFile1 = Join-Path $env:TEMP "dryrun_test1_$(Get-Random).cs"
    $testFile2 = Join-Path $env:TEMP "dryrun_test2_$(Get-Random).cs"
    "test content 1" | Set-Content $testFile1
    "test content 2" | Set-Content $testFile2
    
    $fixes = @(
        @{
            FilePath = $testFile1
            FixContent = "fix content 1"
            Confidence = 0.8
            Description = "Test fix 1"
        },
        @{
            FilePath = $testFile2
            FixContent = "fix content 2"
            Confidence = 0.6
            Description = "Test fix 2"
        }
    )
    
    $results = Invoke-DryRun -Fixes $fixes -OutputFormat "Console"
    
    # Clean up
    Remove-Item $testFile1 -Force -ErrorAction SilentlyContinue
    Remove-Item $testFile2 -Force -ErrorAction SilentlyContinue
    
    # Should have 2 results, 1 would apply (0.8 > 0.7), 1 would skip (0.6 < 0.7)
    $wouldApply = @($results | Where-Object { $_.WouldApply }).Count
    if ($wouldApply -eq 1) { return "PASS" } else { return "FAIL" }
} -ExpectedResult "PASS"

# Test 6: Safe Fix Application
Test-SafetyFunction -TestName "Invoke-SafeFixApplication - Dry Run Mode" -TestBlock {
    # Enable dry run mode
    Set-SafetyConfiguration -DryRunMode $true | Out-Null
    
    # Create test file
    $testFile = Join-Path $env:TEMP "safefixapp_test_$(Get-Random).cs"
    "original content" | Set-Content $testFile
    
    $fixes = @(
        @{
            FilePath = $testFile
            FixContent = "test fix"
            Confidence = 0.9
        }
    )
    
    $results = Invoke-SafeFixApplication -Fixes $fixes -Verbose
    
    # Clean up
    Remove-Item $testFile -Force -ErrorAction SilentlyContinue
    
    # Reset dry run mode
    Set-SafetyConfiguration -DryRunMode $false | Out-Null
    
    # Enhanced debugging for array detection
    Write-Verbose "DEBUG: Results type: $($results.GetType().Name)"
    Write-Verbose "DEBUG: Results count: $(if ($results.Count) { $results.Count } else { 'No Count property' })"
    Write-Verbose "DEBUG: Results -is [array]: $($results -is [array])"
    Write-Verbose "DEBUG: Results -is [System.Array]: $($results -is [System.Array])"
    Write-Verbose "DEBUG: Results -is [Object[]]: $($results -is [Object[]])"
    
    # In dry run mode, should return dry run results (array)
    if ($results -is [array]) { 
        Write-Verbose "DEBUG: Array test PASSED"
        return "PASS" 
    } else { 
        Write-Verbose "DEBUG: Array test FAILED - not detected as array"
        return "FAIL" 
    }
} -ExpectedResult "PASS"

# Test 7: Dangerous Pattern Detection
Test-SafetyFunction -TestName "Test-FixSafety - Dangerous Pattern" -TestBlock {
    $testFile = Join-Path $env:TEMP "danger_test_$(Get-Random).txt"
    "test" | Set-Content $testFile
    
    $safety = Test-FixSafety -FilePath $testFile -Confidence 0.95 -FixContent "Remove-Item C:\ -Recurse -Force"
    
    Remove-Item $testFile -Force -ErrorAction SilentlyContinue
    
    if (-not $safety.IsSafe -and $safety.Reason -eq "Dangerous operation detected") { 
        return "PASS" 
    } else { 
        return "FAIL" 
    }
} -ExpectedResult "PASS"

# Test 8: Force Override
Test-SafetyFunction -TestName "Test-FixSafety - Force Override" -TestBlock {
    $testFile = Join-Path $env:TEMP "force_test_$(Get-Random).txt"
    "test" | Set-Content $testFile
    
    $safety = Test-FixSafety -FilePath $testFile -Confidence 0.3 -FixContent "forced fix" -Force
    
    Remove-Item $testFile -Force -ErrorAction SilentlyContinue
    
    if ($safety.IsSafe -and $safety.Reason -match "overridden") { 
        return "PASS" 
    } else { 
        return "FAIL" 
    }
} -ExpectedResult "PASS"

# Test 9: Max Changes Limit
Test-SafetyFunction -TestName "Max Changes Per Run" -TestBlock {
    # Set max changes to 2
    Write-Verbose "DEBUG: Setting MaxChangesPerRun to 2"
    Set-SafetyConfiguration -MaxChangesPerRun 2 -Verbose | Out-Null
    
    # Create 5 fixes
    $fixes = 1..5 | ForEach-Object {
        @{
            FilePath = "C:\test\file$_.cs"
            FixContent = "fix $_"
            Confidence = 0.9
        }
    }
    
    # Should only process 2
    Write-Verbose "DEBUG: Getting configuration"
    $config = Get-SafetyConfiguration -Verbose
    Write-Verbose "DEBUG: Retrieved MaxChangesPerRun = $($config.MaxChangesPerRun), Expected = 2"
    
    # CRITICAL: Store value BEFORE reset (PowerShell reference semantics fix)
    $actualConfigValue = $config.MaxChangesPerRun
    
    # Reset (this modifies the same object $config points to)
    Set-SafetyConfiguration -MaxChangesPerRun 10 | Out-Null
    
    # Enhanced debugging with guaranteed visibility
    Write-Host "  DEBUG: Stored value before reset: '$actualConfigValue'" -ForegroundColor Gray
    Write-Host "  DEBUG: Config value after reset: '$($config.MaxChangesPerRun)'" -ForegroundColor Gray
    Write-Host "  DEBUG: Stored value type: $($actualConfigValue.GetType().Name)" -ForegroundColor Gray
    
    # Multiple comparison approaches for reliability (using stored value)
    try {
        # Approach 1: Explicit type casting
        $actualValue = [int]($actualConfigValue)
        $expectedValue = [int]2
        Write-Host "  DEBUG: Type-safe cast - Expected: $expectedValue (type: $($expectedValue.GetType().Name)), Actual: $actualValue (type: $($actualValue.GetType().Name))" -ForegroundColor Gray
        
        # Approach 2: Direct comparison with stored value
        $directMatch = ($actualConfigValue -eq 2)
        Write-Host "  DEBUG: Direct comparison result: $directMatch" -ForegroundColor Gray
        
        # Approach 3: String comparison as fallback
        $stringMatch = ($actualConfigValue.ToString() -eq "2")
        Write-Host "  DEBUG: String comparison result: $stringMatch" -ForegroundColor Gray
        
        # Use type-safe comparison as primary check
        if ($actualValue -eq $expectedValue) { 
            Write-Host "  DEBUG: Test PASSED - type-safe values match ($actualValue = $expectedValue)" -ForegroundColor Green
            return "PASS" 
        } elseif ($directMatch) {
            Write-Host "  DEBUG: Test PASSED - direct comparison succeeded" -ForegroundColor Green
            return "PASS"
        } elseif ($stringMatch) {
            Write-Host "  DEBUG: Test PASSED - string comparison succeeded" -ForegroundColor Green
            return "PASS"
        } else { 
            Write-Host "  DEBUG: Test FAILED - All comparison methods failed" -ForegroundColor Red
            Write-Host "  DEBUG: Stored: '$actualConfigValue', Cast: $actualValue, Expected: $expectedValue" -ForegroundColor Red
            return "FAIL" 
        }
        
    } catch {
        Write-Host "  DEBUG: Exception in comparison: $_" -ForegroundColor Red
        Write-Host "  DEBUG: Falling back to string comparison" -ForegroundColor Yellow
        if ($actualConfigValue.ToString() -eq "2") {
            return "PASS"
        } else {
            return "FAIL"
        }
    }
} -ExpectedResult "PASS"

# Test 10: Logging
Test-SafetyFunction -TestName "Add-SafetyLog" -TestBlock {
    Add-SafetyLog -Message "Test log entry" -Level "INFO"
    Add-SafetyLog -Message "Test warning" -Level "WARNING"
    Add-SafetyLog -Message "Test error" -Level "ERROR"
    
    $logPath = (Get-SafetyConfiguration).LogPath
    if (Test-Path $logPath) {
        $logs = Get-Content $logPath -Tail 3
        if ($logs -match "Test log entry" -and $logs -match "Test warning" -and $logs -match "Test error") {
            return "PASS"
        }
    }
    return "FAIL"
} -ExpectedResult "PASS"

# Summary
Write-Host "`n=== TEST SUMMARY ===" -ForegroundColor Yellow
Write-Host "Total Tests: $($testResults.Passed + $testResults.Failed + $testResults.Skipped)" -ForegroundColor White
Write-Host "Passed: $($testResults.Passed)" -ForegroundColor Green
Write-Host "Failed: $($testResults.Failed)" -ForegroundColor Red
Write-Host "Skipped: $($testResults.Skipped)" -ForegroundColor Yellow

if ($testResults.Failed -eq 0) {
    Write-Host "`n[SUCCESS] All safety framework tests passed!" -ForegroundColor Green
} else {
    Write-Host "`n[FAILURE] Some tests failed. Review details above." -ForegroundColor Red
    Write-Host "`nFailed Tests:" -ForegroundColor Red
    $testResults.Details | Where-Object { $_ -match "FAIL" } | ForEach-Object {
        Write-Host "  $_" -ForegroundColor Red
    }
}

# Export results
$resultsPath = "test_results_safety_framework_$(Get-Date -Format 'yyyyMMdd_HHmmss').json"
$testResults | ConvertTo-Json -Depth 10 | Set-Content $resultsPath
Write-Host "`nTest results saved to: $resultsPath" -ForegroundColor Cyan

exit $(if ($testResults.Failed -eq 0) { 0 } else { 1 })
# SIG # Begin signature block
# MIIFqQYJKoZIhvcNAQcCoIIFmjCCBZYCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUexux9ld+Aa7tl3MPtb9QvOrD
# gdOgggMwMIIDLDCCAhSgAwIBAgIQdR0W2SKoK5VE8JId4ZxrRTANBgkqhkiG9w0B
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
# CQQxFgQU6GH+W6s7tkaij4KxJKM1p5l0XDgwDQYJKoZIhvcNAQEBBQAEggEAi7Jg
# hcKRfvDc19G1lGaIzQNgoFMUvoD1FcsqFo4iblOH2arEyejDUNnAVDcBYo/sw3KN
# hWHGVoV2Yn4YyzNVR6anH6I/Fwka7OnW/c6tNzeCu/TUnLrqYyPpmBeVLTNBoSAN
# C1FI2cftTDDeHZtRlH9YxHeEGGurE9xc4XYuw2camB9brxj9wVQtxMOkqqtVytAM
# so9soz9ERqlMyJmCTLGIT77jPMWywPu/OXx136hpH7RSk2RePnCZ78HeSkYB4Ex3
# gVzvFxOkJZSOL3MvXmqcicmIO5b/Wl14x2cOnZMYw9E2XR1eJC4uONV93gaOrUID
# EZhFbAiqcIf5lIPAgg==
# SIG # End signature block
