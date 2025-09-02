# Test script for Unity-Claude-NotificationConfiguration module
# Created: 2025-08-22
# Purpose: Validate the new configuration management system

Write-Host "=== Testing Unity-Claude-NotificationConfiguration Module ===" -ForegroundColor Cyan
Write-Host ""

$testResults = @{
    ModuleName = "Unity-Claude-NotificationConfiguration"
    TestTime = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Tests = @()
    Passed = 0
    Failed = 0
}

# Test 1: Module Import
Write-Host "Test 1: Module Import..." -ForegroundColor Yellow
try {
    Import-Module ".\Modules\Unity-Claude-NotificationConfiguration\Unity-Claude-NotificationConfiguration.psd1" -Force
    Write-Host "  SUCCESS: Module imported" -ForegroundColor Green
    $testResults.Tests += @{Name="Module Import"; Result="Pass"}
    $testResults.Passed++
} catch {
    Write-Host "  FAILED: $_" -ForegroundColor Red
    $testResults.Tests += @{Name="Module Import"; Result="Fail"; Error=$_.ToString()}
    $testResults.Failed++
}

# Test 2: Get Configuration
Write-Host ""
Write-Host "Test 2: Get Configuration..." -ForegroundColor Yellow
try {
    $config = Get-NotificationConfig -Section 'EmailNotifications'
    if ($config) {
        Write-Host "  SUCCESS: Configuration loaded" -ForegroundColor Green
        Write-Host "    Email Enabled: $($config.Enabled)" -ForegroundColor Gray
        Write-Host "    SMTP Server: $($config.SMTPServer)" -ForegroundColor Gray
        $testResults.Tests += @{Name="Get Configuration"; Result="Pass"}
        $testResults.Passed++
    } else {
        throw "Configuration returned null"
    }
} catch {
    Write-Host "  FAILED: $_" -ForegroundColor Red
    $testResults.Tests += @{Name="Get Configuration"; Result="Fail"; Error=$_.ToString()}
    $testResults.Failed++
}

# Test 3: Backup Configuration
Write-Host ""
Write-Host "Test 3: Backup Configuration..." -ForegroundColor Yellow
try {
    $backupFile = Backup-NotificationConfig -Description "Test backup" -Silent
    if (Test-Path $backupFile) {
        Write-Host "  SUCCESS: Backup created at $(Split-Path $backupFile -Leaf)" -ForegroundColor Green
        $testResults.Tests += @{Name="Backup Configuration"; Result="Pass"; BackupFile=$backupFile}
        $testResults.Passed++
    } else {
        throw "Backup file not created"
    }
} catch {
    Write-Host "  FAILED: $_" -ForegroundColor Red
    $testResults.Tests += @{Name="Backup Configuration"; Result="Fail"; Error=$_.ToString()}
    $testResults.Failed++
}

# Test 4: Configuration Validation
Write-Host ""
Write-Host "Test 4: Configuration Validation..." -ForegroundColor Yellow
try {
    $isValid = Test-NotificationConfig
    Write-Host "  Configuration Valid: $isValid" -ForegroundColor $(if ($isValid) {"Green"} else {"Yellow"})
    $testResults.Tests += @{Name="Configuration Validation"; Result="Pass"; Valid=$isValid}
    $testResults.Passed++
} catch {
    Write-Host "  FAILED: $_" -ForegroundColor Red
    $testResults.Tests += @{Name="Configuration Validation"; Result="Fail"; Error=$_.ToString()}
    $testResults.Failed++
}

# Test 5: Get Backup History
Write-Host ""
Write-Host "Test 5: Get Backup History..." -ForegroundColor Yellow
try {
    $backups = Get-ConfigBackupHistory -Limit 5
    Write-Host "  SUCCESS: Found $($backups.Count) backups" -ForegroundColor Green
    if ($backups.Count -gt 0) {
        Write-Host "    Latest: $($backups[0].BackupTime)" -ForegroundColor Gray
    }
    $testResults.Tests += @{Name="Get Backup History"; Result="Pass"; BackupCount=$backups.Count}
    $testResults.Passed++
} catch {
    Write-Host "  FAILED: $_" -ForegroundColor Red
    $testResults.Tests += @{Name="Get Backup History"; Result="Fail"; Error=$_.ToString()}
    $testResults.Failed++
}

# Test 6: Cache Performance
Write-Host ""
Write-Host "Test 6: Cache Performance..." -ForegroundColor Yellow
try {
    # First call (no cache)
    $start = Get-Date
    $config1 = Get-NotificationConfig -NoCache
    $noCacheTime = ((Get-Date) - $start).TotalMilliseconds
    
    # Second call (cached)
    $start = Get-Date
    $config2 = Get-NotificationConfig
    $cachedTime = ((Get-Date) - $start).TotalMilliseconds
    
    Write-Host "  No Cache: $([math]::Round($noCacheTime, 2))ms" -ForegroundColor Gray
    Write-Host "  Cached: $([math]::Round($cachedTime, 2))ms" -ForegroundColor Gray
    
    if ($cachedTime -lt $noCacheTime) {
        Write-Host "  SUCCESS: Cache improving performance" -ForegroundColor Green
    } else {
        Write-Host "  WARNING: Cache not improving performance" -ForegroundColor Yellow
    }
    
    $testResults.Tests += @{Name="Cache Performance"; Result="Pass"; NoCacheMs=$noCacheTime; CachedMs=$cachedTime}
    $testResults.Passed++
} catch {
    Write-Host "  FAILED: $_" -ForegroundColor Red
    $testResults.Tests += @{Name="Cache Performance"; Result="Fail"; Error=$_.ToString()}
    $testResults.Failed++
}

# Summary
Write-Host ""
Write-Host "=== TEST SUMMARY ===" -ForegroundColor Cyan
Write-Host "Total Tests: $($testResults.Passed + $testResults.Failed)" -ForegroundColor White
Write-Host "Passed: $($testResults.Passed)" -ForegroundColor Green
Write-Host "Failed: $($testResults.Failed)" -ForegroundColor $(if ($testResults.Failed -eq 0) {"Green"} else {"Red"})

$successRate = if (($testResults.Passed + $testResults.Failed) -gt 0) {
    [math]::Round(($testResults.Passed / ($testResults.Passed + $testResults.Failed)) * 100, 2)
} else { 0 }

Write-Host "Success Rate: $successRate%" -ForegroundColor $(if ($successRate -ge 80) {"Green"} elseif ($successRate -ge 60) {"Yellow"} else {"Red"})

# Save results
$resultsFile = ".\Test_Results_NotificationConfiguration_$(Get-Date -Format 'yyyyMMdd_HHmmss').txt"
$testResults | ConvertTo-Json -Depth 3 | Set-Content $resultsFile
Write-Host ""
Write-Host "Results saved to: $resultsFile" -ForegroundColor Cyan

if ($testResults.Failed -eq 0) {
    Write-Host ""
    Write-Host "All tests passed! The NotificationConfiguration module is working correctly." -ForegroundColor Green
} else {
    Write-Host ""
    Write-Host "Some tests failed. Please review the errors above." -ForegroundColor Yellow
}
# SIG # Begin signature block
# MIIFzgYJKoZIhvcNAQcCoIIFvzCCBbsCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCCfDdFTxDCWqiS9
# s7m8FGUE/ywqRHu+pzcC0nyRNHjgZqCCAzAwggMsMIICFKADAgECAhB1HRbZIqgr
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
# MAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIPooZAMMWTSLcogMgBnEC045
# jFJmg+A5JnHuxG1o6JAsMA0GCSqGSIb3DQEBAQUABIIBAKhX8ZppTsTsj600F1Dm
# sA0Yxgat3HLrE3lSYlgu7y61uW81zvvex60hi9Zq7MVsfN7vHMeQB27z+5qNPOpD
# 64PrCTZICkqVT3XRALxdAoMTNHAZGBmfAi8DLbZUz90C02JPe7liIjSW5XyO7CuZ
# 4FshiSFFmcAxVJf5vc8PpEuh/C528qEsOuNy2CB9cOtdCitR62lYbf1vF3vFXpSs
# iTX4j/Ms1mvs8a1oGoLM9JTg7G9Y7Ieiu/lc0Mx67aozKkjyacLx2ckNzmVYaqvi
# cW3E+2Qrs7Awe+lNUtr6ofbYh4KpkFYTT9TnBP7b5R6ZaI3NHfJSmU57npKKzdVS
# hgo=
# SIG # End signature block
