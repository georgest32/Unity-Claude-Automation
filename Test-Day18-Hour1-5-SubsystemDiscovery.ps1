# Day 18: Hour 1.5 - Subsystem Discovery and Registration Test
# Comprehensive test for Integration Points 4, 5, and 6
# Date: 2025-08-19

param(
    [switch]$SaveResults = $true,
    [string]$ResultsFile = "TestResults_Day18_Hour1-5_SubsystemDiscovery_$(Get-Date -Format 'yyyyMMdd_HHmmss').txt"
)

# Initialize test environment
$ErrorActionPreference = "Continue"
$testStartTime = Get-Date
$projectRoot = "C:\UnityProjects\Sound-and-Shoal\Unity-Claude-Automation"
$resultsPath = Join-Path $projectRoot $ResultsFile

Write-Host "=== Day 18 Hour 1.5: Subsystem Discovery and Registration Test ===" -ForegroundColor Cyan
Write-Host "Test started at: $testStartTime" -ForegroundColor White
Write-Host "Results will be saved to: $resultsPath" -ForegroundColor Gray

# Function to write test results
function Write-TestResult {
    param([string]$Message, [string]$Level = "INFO")
    
    $timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss.fff'
    $logLine = "[$timestamp] [$Level] $Message"
    
    switch ($Level) {
        'PASS' { Write-Host $logLine -ForegroundColor Green }
        'FAIL' { Write-Host $logLine -ForegroundColor Red }
        'WARN' { Write-Host $logLine -ForegroundColor Yellow }
        default { Write-Host $logLine }
    }
    
    if ($SaveResults) {
        Add-Content -Path $resultsPath -Value $logLine -ErrorAction SilentlyContinue
    }
}

# Test results tracking
$testResults = @{
    TotalTests = 0
    PassedTests = 0
    FailedTests = 0
    WarningTests = 0
    TestDetails = @()
}

function Add-TestResult {
    param([string]$TestName, [bool]$Passed, [string]$Details = "", [string]$Expected = "", [string]$Actual = "")
    
    $testResults.TotalTests++
    $level = if ($Passed) { 
        $testResults.PassedTests++
        "PASS" 
    } else { 
        $testResults.FailedTests++
        "FAIL" 
    }
    
    $testResults.TestDetails += @{
        Name = $TestName
        Passed = $Passed
        Details = $Details
        Expected = $Expected
        Actual = $Actual
        Timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss.fff'
    }
    
    Write-TestResult "$TestName - $Details" -Level $level
    if ($Expected -and $Actual) {
        Write-TestResult "  Expected: $Expected" -Level "INFO"
        Write-TestResult "  Actual: $Actual" -Level "INFO"
    }
}

Write-TestResult "Starting Day 18 Hour 1.5 comprehensive test suite..." -Level "INFO"

# Test 1: Module Loading and Import
Write-TestResult "`n=== Test Group 1: Module Loading and Import ===" -Level "INFO"

try {
    $modulePath = Join-Path $projectRoot "Modules\Unity-Claude-SystemStatus\Unity-Claude-SystemStatus.psm1"
    
    # Test 1.1: Module file exists
    $moduleExists = Test-Path $modulePath
    Add-TestResult "Module file exists" $moduleExists "Unity-Claude-SystemStatus.psm1 should exist at correct path" "File exists" "File exists: $moduleExists"
    
    # Test 1.2: Module manifest exists
    $manifestPath = Join-Path $projectRoot "Modules\Unity-Claude-SystemStatus\Unity-Claude-SystemStatus.psd1"
    $manifestExists = Test-Path $manifestPath
    Add-TestResult "Module manifest exists" $manifestExists "Unity-Claude-SystemStatus.psd1 should exist" "File exists" "File exists: $manifestExists"
    
    # Test 1.3: Module can be imported
    try {
        Import-Module $modulePath -Force -DisableNameChecking
        $importSuccess = $true
        Add-TestResult "Module import successful" $importSuccess "Module should import without errors"
    } catch {
        $importSuccess = $false
        Add-TestResult "Module import successful" $importSuccess "Import failed: $($_.Exception.Message)"
    }
    
    # Test 1.4: Required functions are available
    if ($importSuccess) {
        $expectedFunctions = @(
            'Initialize-SystemStatusMonitoring',
            'Get-SubsystemProcessId',
            'Update-SubsystemProcessInfo', 
            'Register-Subsystem',
            'Unregister-Subsystem',
            'Get-RegisteredSubsystems',
            'Send-Heartbeat',
            'Test-HeartbeatResponse',
            'Test-AllSubsystemHeartbeats'
        )
        
        foreach ($functionName in $expectedFunctions) {
            $functionExists = Get-Command $functionName -ErrorAction SilentlyContinue
            Add-TestResult "Function $functionName available" ($null -ne $functionExists) "Function should be exported and available"
        }
    }
    
} catch {
    Add-TestResult "Module loading test group" $false "Unexpected error: $($_.Exception.Message)"
}

# Test 2: Integration Point 4 - Process ID Detection and Management
Write-TestResult "`n=== Test Group 2: Integration Point 4 - Process ID Detection ===" -Level "INFO"

try {
    # Test 2.1: Get-SubsystemProcessId function
    $testSubsystemName = "TestSubsystem"
    $processId = Get-SubsystemProcessId -SubsystemName $testSubsystemName
    
    $pidTestPassed = ($processId -is [int] -and $processId -gt 0) -or ($processId -eq $null)
    Add-TestResult "Get-SubsystemProcessId returns valid result" $pidTestPassed "Should return integer PID or null" "Integer or null" "Returned: $processId (Type: $($processId.GetType().Name))"
    
    # Test 2.2: Update-SubsystemProcessInfo function
    # First initialize the module to set up initial data structures (SAFE MODE)
    $initResult = Initialize-SystemStatusMonitoring -EnableCommunication:$false -EnableFileWatcher:$false
    Add-TestResult "Initialize-SystemStatusMonitoring" $initResult "Initialization should succeed"
    
    if ($initResult) {
        # Register a test subsystem first
        $testModulePath = Join-Path $projectRoot "Modules\Unity-Claude-Core\Unity-Claude-Core.psm1"
        if (Test-Path $testModulePath) {
            $registerResult = Register-Subsystem -SubsystemName $testSubsystemName -ModulePath $testModulePath
            Add-TestResult "Test subsystem registration" $registerResult "Should register test subsystem successfully"
            
            if ($registerResult) {
                $updateResult = Update-SubsystemProcessInfo -SubsystemName $testSubsystemName
                Add-TestResult "Update-SubsystemProcessInfo" $updateResult "Should update process information successfully"
            }
        } else {
            Add-TestResult "Test module path availability" $false "Unity-Claude-Core.psm1 not found for testing"
        }
    }
    
} catch {
    Add-TestResult "Process ID detection test group" $false "Unexpected error: $($_.Exception.Message)"
}

# Test 3: Integration Point 5 - Subsystem Registration Framework
Write-TestResult "`n=== Test Group 3: Integration Point 5 - Subsystem Registration ===" -Level "INFO"

try {
    # Test 3.1: Register-Subsystem with valid module
    $testModulePath = Join-Path $projectRoot "Modules\Unity-Claude-Core\Unity-Claude-Core.psm1"
    if (Test-Path $testModulePath) {
        $testSubsystemName2 = "TestSubsystem2"
        $registerResult = Register-Subsystem -SubsystemName $testSubsystemName2 -ModulePath $testModulePath -Dependencies @("Unity-Claude-Core")
        Add-TestResult "Register-Subsystem with valid module" $registerResult "Should register subsystem successfully with valid module path"
        
        # Test 3.2: Get-RegisteredSubsystems
        $registeredSubsystems = Get-RegisteredSubsystems
        $subsystemFound = $false
        foreach ($subsystem in $registeredSubsystems) {
            if ($subsystem.Name -eq $testSubsystemName2) {
                $subsystemFound = $true
                break
            }
        }
        Add-TestResult "Get-RegisteredSubsystems finds registered subsystem" $subsystemFound "Registered subsystem should appear in subsystem list"
        
        # Test 3.3: Unregister-Subsystem
        $unregisterResult = Unregister-Subsystem -SubsystemName $testSubsystemName2
        Add-TestResult "Unregister-Subsystem" $unregisterResult "Should unregister subsystem successfully"
        
        # Test 3.4: Verify subsystem is removed
        $registeredSubsystemsAfter = Get-RegisteredSubsystems
        $subsystemStillFound = $false
        foreach ($subsystem in $registeredSubsystemsAfter) {
            if ($subsystem.Name -eq $testSubsystemName2) {
                $subsystemStillFound = $true
                break
            }
        }
        Add-TestResult "Subsystem removal verification" (-not $subsystemStillFound) "Unregistered subsystem should not appear in subsystem list"
    } else {
        Add-TestResult "Test module availability for registration tests" $false "Unity-Claude-Core.psm1 not found - cannot test registration"
    }
    
    # Test 3.5: Register-Subsystem with invalid module path
    $invalidResult = Register-Subsystem -SubsystemName "InvalidSubsystem" -ModulePath "C:\NonExistent\Module.psm1"
    Add-TestResult "Register-Subsystem with invalid module path" (-not $invalidResult) "Should fail gracefully with invalid module path"
    
} catch {
    Add-TestResult "Subsystem registration test group" $false "Unexpected error: $($_.Exception.Message)"
}

# Test 4: Integration Point 6 - Heartbeat Detection Implementation
Write-TestResult "`n=== Test Group 4: Integration Point 6 - Heartbeat Detection ===" -Level "INFO"

try {
    # Set up a test subsystem for heartbeat testing
    $testModulePath = Join-Path $projectRoot "Modules\Unity-Claude-Core\Unity-Claude-Core.psm1"
    if (Test-Path $testModulePath) {
        $heartbeatTestSubsystem = "HeartbeatTestSubsystem"
        $registerResult = Register-Subsystem -SubsystemName $heartbeatTestSubsystem -ModulePath $testModulePath
        
        if ($registerResult) {
            # Test 4.1: Send-Heartbeat
            $heartbeatResult = Send-Heartbeat -SubsystemName $heartbeatTestSubsystem -HealthScore 0.9
            Add-TestResult "Send-Heartbeat" $heartbeatResult "Should send heartbeat successfully for registered subsystem"
            
            # Test 4.2: Test-HeartbeatResponse immediately after sending
            $heartbeatResponseResult = Test-HeartbeatResponse -SubsystemName $heartbeatTestSubsystem
            $isHealthyAfterHeartbeat = $heartbeatResponseResult.IsHealthy
            Add-TestResult "Test-HeartbeatResponse after recent heartbeat" $isHealthyAfterHeartbeat "Should report healthy status immediately after heartbeat" "Healthy (true)" "Healthy: $isHealthyAfterHeartbeat"
            
            # Test 4.3: Heartbeat response details
            $missedHeartbeats = $heartbeatResponseResult.MissedHeartbeats
            $timeSinceLastHeartbeat = $heartbeatResponseResult.TimeSinceLastHeartbeat
            Add-TestResult "Heartbeat response timing" ($timeSinceLastHeartbeat -lt 10) "Time since last heartbeat should be very recent" "< 10 seconds" "$timeSinceLastHeartbeat seconds"
            
            # Test 4.4: Test-AllSubsystemHeartbeats
            $allHeartbeatResults = Test-AllSubsystemHeartbeats
            $totalSubsystems = $allHeartbeatResults.TotalSubsystems
            $healthyCount = $allHeartbeatResults.HealthyCount
            Add-TestResult "Test-AllSubsystemHeartbeats execution" ($totalSubsystems -gt 0) "Should test heartbeats for all registered subsystems" "> 0 subsystems" "$totalSubsystems subsystems, $healthyCount healthy"
            
            # Test 4.5: Invalid subsystem heartbeat test
            $invalidHeartbeatResult = Test-HeartbeatResponse -SubsystemName "NonExistentSubsystem"
            $invalidSubsystemUnhealthy = (-not $invalidHeartbeatResult.IsHealthy)
            Add-TestResult "Invalid subsystem heartbeat test" $invalidSubsystemUnhealthy "Should report unhealthy for non-existent subsystem"
            
            # Test 4.6: Send heartbeat with low health score
            $lowHealthHeartbeat = Send-Heartbeat -SubsystemName $heartbeatTestSubsystem -HealthScore 0.3
            if ($lowHealthHeartbeat) {
                $lowHealthResponse = Test-HeartbeatResponse -SubsystemName $heartbeatTestSubsystem
                $statusIsCritical = ($lowHealthResponse.Status -eq "Critical")
                Add-TestResult "Low health score status determination" $statusIsCritical "Health score 0.3 should result in Critical status" "Critical" "Status: $($lowHealthResponse.Status)"
            }
            
            # Clean up test subsystem
            Unregister-Subsystem -SubsystemName $heartbeatTestSubsystem | Out-Null
        } else {
            Add-TestResult "Heartbeat test setup" $false "Could not register test subsystem for heartbeat testing"
        }
    } else {
        Add-TestResult "Heartbeat test module availability" $false "Unity-Claude-Core.psm1 not found for heartbeat testing"
    }
    
} catch {
    Add-TestResult "Heartbeat detection test group" $false "Unexpected error: $($_.Exception.Message)"
}

# Test 5: System Status File Operations  
Write-TestResult "`n=== Test Group 5: System Status File Operations ===" -Level "INFO"

try {
    # Test 5.1: Read system status file
    $statusData = Read-SystemStatus
    $readSuccess = ($null -ne $statusData -and $statusData -is [hashtable])
    Add-TestResult "Read-SystemStatus" $readSuccess "Should successfully read system status data" "Hashtable" "Type: $($statusData.GetType().Name)"
    
    # Test 5.2: Write system status file
    if ($readSuccess) {
        $statusData.SystemInfo.LastUpdate = Get-Date -Format 'yyyy-MM-dd HH:mm:ss.fff'
        $writeSuccess = Write-SystemStatus -StatusData $statusData
        Add-TestResult "Write-SystemStatus" $writeSuccess "Should successfully write system status data to file"
        
        # Test 5.3: Verify file was updated
        $systemStatusFile = Join-Path $projectRoot "system_status.json"
        if (Test-Path $systemStatusFile) {
            $fileInfo = Get-Item $systemStatusFile
            $fileUpdatedRecently = ((Get-Date) - $fileInfo.LastWriteTime).TotalMinutes -lt 1
            Add-TestResult "System status file updated recently" $fileUpdatedRecently "System status file should have been updated within last minute"
        }
    }
    
    # Test 5.4: JSON schema validation (PowerShell 5.1 compatible)
    if ($readSuccess) {
        $schemaValidationResult = Test-SystemStatusSchema -StatusData $statusData
        Add-TestResult "JSON schema validation (PS5.1 compatible)" $schemaValidationResult "System status data should pass structural validation"
    }
    
} catch {
    Add-TestResult "System status file operations test group" $false "Unexpected error: $($_.Exception.Message)"
}

# Test Summary and Results
Write-TestResult "`n=== Test Summary ===" -Level "INFO"
$testEndTime = Get-Date
$testDuration = $testEndTime - $testStartTime

Write-TestResult "Test execution completed at: $testEndTime" -Level "INFO"
Write-TestResult "Total test duration: $([math]::Round($testDuration.TotalSeconds, 2)) seconds" -Level "INFO"
Write-TestResult "Total tests executed: $($testResults.TotalTests)" -Level "INFO"
Write-TestResult "Tests passed: $($testResults.PassedTests)" -Level "PASS"
Write-TestResult "Tests failed: $($testResults.FailedTests)" -Level "FAIL"

$successRate = if ($testResults.TotalTests -gt 0) { 
    [math]::Round(($testResults.PassedTests / $testResults.TotalTests) * 100, 1)
} else { 0 }
Write-TestResult "Success rate: $successRate%" -Level "INFO"

# Detailed test results
if ($testResults.FailedTests -gt 0) {
    Write-TestResult "`n=== Failed Test Details ===" -Level "WARN"
    foreach ($test in $testResults.TestDetails) {
        if (-not $test.Passed) {
            Write-TestResult "FAILED: $($test.Name) - $($test.Details)" -Level "FAIL"
        }
    }
}

# Hour 1.5 Completion Assessment
Write-TestResult "`n=== Day 18 Hour 1.5 Completion Assessment ===" -Level "INFO"

$criticalTestsPassed = @(
    ($testResults.TestDetails | Where-Object { $_.Name -like "*Module import successful*" }).Passed,
    ($testResults.TestDetails | Where-Object { $_.Name -like "*Get-SubsystemProcessId*" }).Passed,
    ($testResults.TestDetails | Where-Object { $_.Name -like "*Register-Subsystem with valid module*" }).Passed,
    ($testResults.TestDetails | Where-Object { $_.Name -like "*Send-Heartbeat*" }).Passed
)

$criticalTestsPassedCount = ($criticalTestsPassed | Where-Object { $_ -eq $true }).Count
$hour15Complete = $criticalTestsPassedCount -eq 4 -and $testResults.FailedTests -eq 0

if ($hour15Complete) {
    Write-TestResult "✅ Hour 1.5 COMPLETED SUCCESSFULLY" -Level "PASS"
    Write-TestResult "✅ Integration Point 4 (Process ID Detection): OPERATIONAL" -Level "PASS"
    Write-TestResult "✅ Integration Point 5 (Subsystem Registration): OPERATIONAL" -Level "PASS"
    Write-TestResult "✅ Integration Point 6 (Heartbeat Detection): OPERATIONAL" -Level "PASS"
    Write-TestResult "✅ Ready to proceed to Hour 2.5: Cross-Subsystem Communication Protocol" -Level "PASS"
} else {
    Write-TestResult "❌ Hour 1.5 INCOMPLETE - Issues detected" -Level "FAIL"
    Write-TestResult "Critical tests passed: $criticalTestsPassedCount/4" -Level "WARN"
    Write-TestResult "Review failed tests before proceeding to Hour 2.5" -Level "WARN"
}

# Clean up resources to prevent PowerShell crashes
try {
    Stop-SystemStatusMonitoring | Out-Null
    Write-TestResult "Resources cleaned up successfully" -Level "INFO"
} catch {
    Write-TestResult "Cleanup warning: $($_.Exception.Message)" -Level "WARN"
}

Write-TestResult "`nTest results saved to: $resultsPath" -Level "INFO"
Write-TestResult "Day 18 Hour 1.5 Subsystem Discovery and Registration test completed." -Level "INFO"

# Return test results for automation
return @{
    Success = $hour15Complete
    TotalTests = $testResults.TotalTests
    PassedTests = $testResults.PassedTests
    FailedTests = $testResults.FailedTests
    SuccessRate = $successRate
    Duration = $testDuration
    ResultsFile = $resultsPath
    CriticalTestsStatus = @{
        ModuleImport = ($testResults.TestDetails | Where-Object { $_.Name -like "*Module import successful*" }).Passed
        ProcessIDDetection = ($testResults.TestDetails | Where-Object { $_.Name -like "*Get-SubsystemProcessId*" }).Passed
        SubsystemRegistration = ($testResults.TestDetails | Where-Object { $_.Name -like "*Register-Subsystem with valid module*" }).Passed
        HeartbeatDetection = ($testResults.TestDetails | Where-Object { $_.Name -like "*Send-Heartbeat*" }).Passed
    }
}
# SIG # Begin signature block
# MIIFqQYJKoZIhvcNAQcCoIIFmjCCBZYCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUErkN3oWqiNRsSDoRvlSRZ35j
# 7sGgggMwMIIDLDCCAhSgAwIBAgIQdR0W2SKoK5VE8JId4ZxrRTANBgkqhkiG9w0B
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
# CQQxFgQUlUTB8Fa2jkXMZZV80hg4B8n4VzYwDQYJKoZIhvcNAQEBBQAEggEAodsA
# m2JmkznYbFvcuZRecPuh8aB3Ka6qSUThoafwmrhVDdUj7bjJ/9j21IAvI5FScLFF
# qej71gOGG67QQ1ZTIEkc23weFUEac7Bb9t7/DF/e5eYD17CDHRXywcTW6dSLUJWB
# PkAjtSliE3+1Lh2/gT7AmY8p77EM0VRONIHKWmCtO+FkK82THiDs0PQEKGlmt/yV
# lUvY8bp73ofGPZPF2V+2XPdUZ/hv2aJ/7k3ekmzHwt3zIMZrnFBy7DZzWdesdz+D
# 8KIT08cuNvIdVvSvN+w7p+hBFmYSQr1hLg/pVw2iMhxWWI9q1zbpCe5Q2QMoKDT4
# uPh8R2xvxwA13aG1zA==
# SIG # End signature block
