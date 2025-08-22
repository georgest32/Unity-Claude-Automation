# Test-Week6-Day5-ConfigurationDocumentation.ps1
# Week 6 Day 5: Configuration & Documentation Testing
# Tests notification configuration management and input locking integration
# Date: 2025-08-21

[CmdletBinding()]
param(
    [switch]$SaveResults,
    [switch]$TestInputLock,
    [int]$InputLockTestDuration = 10,
    [switch]$SkipAdminTests
)

Write-Host "=== Week 6 Day 5: Configuration & Documentation Test ===" -ForegroundColor Cyan
Write-Host "Testing notification configuration management and input locking integration" -ForegroundColor Green
Write-Host "Date: $(Get-Date)" -ForegroundColor Green

# Configure PSModulePath
$env:PSModulePath = "C:\UnityProjects\Sound-and-Shoal\Unity-Claude-Automation\Modules;$env:PSModulePath"

# Test results tracking
$TestResults = @{
    TestName = "Week6-Day5-ConfigurationDocumentation"
    StartTime = Get-Date
    Tests = @()
    Categories = @{
        ConfigurationManagement = @{Passed = 0; Failed = 0; Total = 0}
        InputLockIntegration = @{Passed = 0; Failed = 0; Total = 0}
        DocumentationValidation = @{Passed = 0; Failed = 0; Total = 0}
        SecurityCompliance = @{Passed = 0; Failed = 0; Total = 0}
    }
    Summary = @{
        Total = 0
        Passed = 0
        Failed = 0
        Duration = 0
        PassRate = 0
    }
}

function Write-TestResult {
    param(
        [string]$TestName,
        [bool]$Success,
        [string]$Message = "",
        [int]$Duration = 0,
        [string]$Category = "General"
    )
    
    $status = if ($Success) { "PASS" } else { "FAIL" }
    $color = if ($Success) { "Green" } else { "Red" }
    
    Write-Host "[$status] $TestName" -ForegroundColor $color
    if ($Message) {
        Write-Host "    $Message" -ForegroundColor Gray
    }
    if ($Duration -gt 0) {
        Write-Host "    Duration: ${Duration}ms" -ForegroundColor Gray
    }
    
    $TestResults.Summary.Total++
    if ($TestResults.Categories.ContainsKey($Category)) {
        $TestResults.Categories[$Category].Total++
        if ($Success) {
            $TestResults.Summary.Passed++
            $TestResults.Categories[$Category].Passed++
        } else {
            $TestResults.Summary.Failed++
            $TestResults.Categories[$Category].Failed++
        }
    }
    
    return $Success
}

try {
    Write-Host ""
    Write-Host "=== 1. Configuration Management Testing ====" -ForegroundColor Cyan
    
    # Test 1: Import notification configuration module
    $startTime = Get-Date
    try {
        Import-Module Unity-Claude-NotificationConfiguration -Force -ErrorAction Stop
        $success = $true
        $message = "Notification configuration module imported successfully"
    } catch {
        $success = $false
        $message = "Module import failed: $($_.Exception.Message)"
    }
    $duration = ((Get-Date) - $startTime).TotalMilliseconds
    Write-TestResult "Notification Configuration Module Import" $success $message $duration "ConfigurationManagement"
    
    # Test 2: Initialize default configuration
    $startTime = Get-Date
    try {
        $initResult = Initialize-NotificationConfiguration -Force
        $success = ($initResult -and $initResult.Success)
        $message = if ($success) { 
            "Configuration initialized at: $($initResult.ConfigurationPath)" 
        } else { 
            "Configuration initialization failed: $($initResult.Error)" 
        }
    } catch {
        $success = $false
        $message = "Configuration initialization error: $($_.Exception.Message)"
    }
    $duration = ((Get-Date) - $startTime).TotalMilliseconds
    Write-TestResult "Default Configuration Initialization" $success $message $duration "ConfigurationManagement"
    
    # Test 3: Configuration validation
    $startTime = Get-Date
    try {
        $validation = Test-NotificationConfiguration
        $success = ($validation -ne $null)
        $message = if ($success) { 
            "Validation result: Valid=$($validation.IsValid), Errors=$($validation.Errors.Count), Warnings=$($validation.Warnings.Count)" 
        } else { 
            "Configuration validation failed" 
        }
    } catch {
        $success = $false
        $message = "Configuration validation error: $($_.Exception.Message)"
    }
    $duration = ((Get-Date) - $startTime).TotalMilliseconds
    Write-TestResult "Configuration Validation" $success $message $duration "ConfigurationManagement"
    
    # Test 4: Configuration update and retrieval
    $startTime = Get-Date
    try {
        $updateResult = Set-NotificationConfiguration -Section "General" -Settings @{LogLevel = "Debug"; MaxNotificationsPerMinute = 15}
        $config = Get-NotificationConfiguration -Section "General"
        
        $success = ($updateResult.Success -and $config.LogLevel -eq "Debug" -and $config.MaxNotificationsPerMinute -eq 15)
        $message = if ($success) { 
            "Configuration updated and retrieved successfully" 
        } else { 
            "Configuration update/retrieval failed" 
        }
    } catch {
        $success = $false
        $message = "Configuration update error: $($_.Exception.Message)"
    }
    $duration = ((Get-Date) - $startTime).TotalMilliseconds
    Write-TestResult "Configuration Update and Retrieval" $success $message $duration "ConfigurationManagement"
    
    # Test 5: Configuration export/import
    $startTime = Get-Date
    try {
        $exportPath = "test_config_export.json"
        $exportResult = Export-NotificationConfiguration -Path $exportPath
        $importResult = Import-NotificationConfiguration -Path $exportPath -Backup
        
        $success = ($exportResult.Success -and $importResult.Success)
        $message = if ($success) { 
            "Configuration export/import successful" 
        } else { 
            "Export/import failed" 
        }
        
        # Cleanup
        if (Test-Path $exportPath) {
            Remove-Item $exportPath -Force
        }
    } catch {
        $success = $false
        $message = "Export/import error: $($_.Exception.Message)"
    }
    $duration = ((Get-Date) - $startTime).TotalMilliseconds
    Write-TestResult "Configuration Export/Import" $success $message $duration "ConfigurationManagement"
    
    Write-Host ""
    Write-Host "=== 2. Input Lock Integration Testing ====" -ForegroundColor Cyan
    
    # Test 6: Input lock configuration retrieval
    $startTime = Get-Date
    try {
        $inputConfig = Get-InputLockConfiguration
        $success = ($inputConfig -ne $null -and $inputConfig.Configuration -ne $null -and $inputConfig.RuntimeStatus -ne $null)
        $message = if ($success) { 
            "Input lock config retrieved - Enabled: $($inputConfig.Configuration.Enabled), Admin: $($inputConfig.RuntimeStatus.HasAdminPrivileges)" 
        } else { 
            "Input lock configuration retrieval failed" 
        }
    } catch {
        $success = $false
        $message = "Input lock config error: $($_.Exception.Message)"
    }
    $duration = ((Get-Date) - $startTime).TotalMilliseconds
    Write-TestResult "Input Lock Configuration Retrieval" $success $message $duration "InputLockIntegration"
    
    # Test 7: Input lock configuration update
    $startTime = Get-Date
    try {
        $configResult = Set-InputLockConfiguration -Enabled $true -AutoLockOnSubmission $true -TimeoutSeconds 60
        $success = ($configResult -and $configResult.Success)
        $message = if ($success) { 
            "Input lock configuration updated successfully" 
        } else { 
            "Input lock configuration update failed: $($configResult.Error)" 
        }
    } catch {
        $success = $false
        $message = "Input lock config update error: $($_.Exception.Message)"
    }
    $duration = ((Get-Date) - $startTime).TotalMilliseconds
    Write-TestResult "Input Lock Configuration Update" $success $message $duration "InputLockIntegration"
    
    # Test 8: Enhanced CLI submission module
    $startTime = Get-Date
    try {
        Import-Module Unity-Claude-CLISubmission-Enhanced -Force -ErrorAction Stop
        $success = $true
        $message = "Enhanced CLI submission module imported successfully"
    } catch {
        $success = $false
        $message = "Enhanced CLI module import failed: $($_.Exception.Message)"
    }
    $duration = ((Get-Date) - $startTime).TotalMilliseconds
    Write-TestResult "Enhanced CLI Submission Module Import" $success $message $duration "InputLockIntegration"
    
    # Test 9: Input lock script availability
    $startTime = Get-Date
    try {
        $inputConfig = Get-InputLockConfiguration
        $lockScriptExists = $inputConfig.RuntimeStatus.LockScriptExists
        $unlockScriptPath = $inputConfig.RuntimeStatus.LockScriptPath
        
        $success = $lockScriptExists
        $message = if ($success) { 
            "Input lock script found at: $unlockScriptPath" 
        } else { 
            "Input lock script not found at: $unlockScriptPath" 
        }
    } catch {
        $success = $false
        $message = "Input lock script check error: $($_.Exception.Message)"
    }
    $duration = ((Get-Date) - $startTime).TotalMilliseconds
    Write-TestResult "Input Lock Script Availability" $success $message $duration "InputLockIntegration"
    
    # Test 10: Administrator privilege check
    $startTime = Get-Date
    try {
        $isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")
        
        if ($SkipAdminTests -and -not $isAdmin) {
            $success = $true
            $message = "Administrator test skipped (not running as admin)"
        } else {
            $success = $isAdmin
            $message = if ($success) { 
                "Running with Administrator privileges" 
            } else { 
                "Not running as Administrator - input locking will be limited" 
            }
        }
    } catch {
        $success = $false
        $message = "Administrator check error: $($_.Exception.Message)"
    }
    $duration = ((Get-Date) - $startTime).TotalMilliseconds
    Write-TestResult "Administrator Privilege Check" $success $message $duration "SecurityCompliance"
    
    # Test 11: Input lock functionality test (if admin and requested)
    if ($TestInputLock -and -not $SkipAdminTests) {
        $startTime = Get-Date
        try {
            $isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")
            
            if ($isAdmin) {
                Write-Host "Testing actual input lock functionality for $InputLockTestDuration seconds..." -ForegroundColor Yellow
                Write-Host "WARNING: Your keyboard and mouse will be locked!" -ForegroundColor Red
                $response = Read-Host "Continue? (Y/N)"
                
                if ($response -eq 'Y') {
                    $lockScript = (Get-InputLockConfiguration).RuntimeStatus.LockScriptPath
                    if (Test-Path $lockScript) {
                        $lockJob = Start-Job -ScriptBlock {
                            param($ScriptPath, $Duration)
                            & $ScriptPath -Lock -TimeoutSeconds $Duration
                        } -ArgumentList $lockScript, $InputLockTestDuration
                        
                        Start-Sleep -Seconds ($InputLockTestDuration + 2)
                        
                        $success = ($lockJob.State -eq "Completed")
                        $message = if ($success) { 
                            "Input lock test completed successfully" 
                        } else { 
                            "Input lock test failed or timed out" 
                        }
                        
                        # Cleanup
                        Stop-Job $lockJob -ErrorAction SilentlyContinue
                        Remove-Job $lockJob -ErrorAction SilentlyContinue
                    } else {
                        $success = $false
                        $message = "Lock script not found for testing"
                    }
                } else {
                    $success = $true
                    $message = "Input lock test skipped by user choice"
                }
            } else {
                $success = $false
                $message = "Input lock test requires Administrator privileges"
            }
        } catch {
            $success = $false
            $message = "Input lock test error: $($_.Exception.Message)"
        }
        $duration = ((Get-Date) - $startTime).TotalMilliseconds
        Write-TestResult "Input Lock Functionality Test" $success $message $duration "InputLockIntegration"
    }
    
    Write-Host ""
    Write-Host "=== 3. Documentation Validation ====" -ForegroundColor Cyan
    
    # Test 12: Documentation file existence
    $startTime = Get-Date
    try {
        $docPath = ".\Documentation\INPUT_LOCKING_SETUP_GUIDE.md"
        $docExists = Test-Path $docPath
        
        $success = $docExists
        $message = if ($success) { 
            "Input locking documentation found at: $docPath" 
        } else { 
            "Documentation not found at: $docPath" 
        }
    } catch {
        $success = $false
        $message = "Documentation check error: $($_.Exception.Message)"
    }
    $duration = ((Get-Date) - $startTime).TotalMilliseconds
    Write-TestResult "Documentation File Existence" $success $message $duration "DocumentationValidation"
    
    # Test 13: Configuration integration with system status
    $startTime = Get-Date
    try {
        $systemStatusPath = ".\Modules\system_status.json"
        $statusExists = Test-Path $systemStatusPath
        
        if ($statusExists) {
            $statusContent = Get-Content $systemStatusPath -Raw | ConvertFrom-Json
            $hasNotificationIntegration = ($statusContent.subsystems -and $statusContent.subsystems.NotificationIntegration)
            
            $success = $hasNotificationIntegration
            $message = if ($success) { 
                "System status has notification integration entry" 
            } else { 
                "System status missing notification integration" 
            }
        } else {
            $success = $false
            $message = "System status file not found"
        }
    } catch {
        $success = $false
        $message = "System status integration check error: $($_.Exception.Message)"
    }
    $duration = ((Get-Date) - $startTime).TotalMilliseconds
    Write-TestResult "System Status Integration" $success $message $duration "DocumentationValidation"
    
    # Calculate final results
    $TestResults.EndTime = Get-Date
    $TestResults.Summary.Duration = (($TestResults.EndTime - $TestResults.StartTime).TotalSeconds)
    $TestResults.Summary.PassRate = if ($TestResults.Summary.Total -gt 0) { 
        [math]::Round(($TestResults.Summary.Passed / $TestResults.Summary.Total) * 100, 2) 
    } else { 0 }
    
    # Display summary
    Write-Host ""
    Write-Host "=== Week 6 Day 5 Configuration & Documentation Results Summary ===" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Testing Execution Summary:" -ForegroundColor White
    Write-Host "Total Tests: $($TestResults.Summary.Total)" -ForegroundColor White
    Write-Host "Passed: $($TestResults.Summary.Passed)" -ForegroundColor Green
    Write-Host "Failed: $($TestResults.Summary.Failed)" -ForegroundColor Red
    Write-Host "Duration: $($TestResults.Summary.Duration) seconds" -ForegroundColor White
    Write-Host "Pass Rate: $($TestResults.Summary.PassRate)%" -ForegroundColor $(if ($TestResults.Summary.PassRate -ge 80) { "Green" } else { "Red" })
    
    Write-Host ""
    Write-Host "Category Breakdown:" -ForegroundColor White
    foreach ($category in $TestResults.Categories.GetEnumerator()) {
        $cat = $category.Value
        $catPassRate = if ($cat.Total -gt 0) { [math]::Round(($cat.Passed / $cat.Total) * 100, 2) } else { 0 }
        $color = if ($catPassRate -ge 80) { "Green" } else { "Red" }
        Write-Host "$($category.Key): $($cat.Passed)/$($cat.Total) ($catPassRate%)" -ForegroundColor $color
    }
    
    # Final status
    if ($TestResults.Summary.PassRate -ge 80) {
        Write-Host ""
        Write-Host "WEEK 6 DAY 5 CONFIGURATION & DOCUMENTATION: SUCCESS" -ForegroundColor Green
        Write-Host "Configuration management and input locking integration operational" -ForegroundColor Green
    } else {
        Write-Host ""
        Write-Host "WEEK 6 DAY 5 CONFIGURATION & DOCUMENTATION: PARTIAL SUCCESS" -ForegroundColor Yellow
        Write-Host "Some configuration or integration features need attention" -ForegroundColor Yellow
    }
    
    # Save results if requested
    if ($SaveResults) {
        $resultsFile = "Week6Day5_ConfigurationDocumentation_Results_$(Get-Date -Format 'yyyyMMdd_HHmmss').txt"
        $TestResults | ConvertTo-Json -Depth 3 | Out-File $resultsFile
        Write-Host "Results saved to: $resultsFile" -ForegroundColor Green
    }
    
} catch {
    Write-Host "=== WEEK 6 DAY 5 CONFIGURATION & DOCUMENTATION: FAILED ===" -ForegroundColor Red
    Write-Host "Critical error: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}
# SIG # Begin signature block
# MIIFqQYJKoZIhvcNAQcCoIIFmjCCBZYCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUh8UjDdwgs8nDyKmNmnuT4Llz
# yYugggMwMIIDLDCCAhSgAwIBAgIQdR0W2SKoK5VE8JId4ZxrRTANBgkqhkiG9w0B
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
# CQQxFgQUHkGamUIWl0a8O6+p9UmwSEQxYPIwDQYJKoZIhvcNAQEBBQAEggEAosSF
# l1rqVVaeSG+f/ZA3ozQMg1yhQ3GN/azBcfaqmyK4Txpj7d5Eoim51agTXUmaMS0s
# x6v3v1Fa2xIzNpF05YOEH4CBmHr5k4s3QhsD8GGJ4gJwfzCPlbexO/am6dcY5GLI
# EkUW/BxfGyFk7YtWMNBlUtjn1D6N0mnEIA+ITLYVyVyB67bSSPXX7q/dlHkijijq
# oxvbnMm26ImlaYO5A6nbpzL1fiTcCAqOSW11C7NLFkXW0VVZcFfBswHRxiK6eeIs
# +V21JbaGM2UMsF+w0EW4GEIXi3Gvj/SCgiQGwuNFyvSwM6juzb9fSavCPj5D9FCg
# V9kV0Qf5nVtojfjO8Q==
# SIG # End signature block
