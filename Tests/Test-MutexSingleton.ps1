# Test-MutexSingleton.ps1
# Tests mutex-based singleton enforcement for Unity-Claude-Automation
# Date: 2025-08-22

param(
    [string]$OutputFile = ".\Test_Results_MutexSingleton_$(Get-Date -Format 'yyyyMMdd_HHmmss').txt"
)

# Initialize test results
$testResults = @()
$testStartTime = Get-Date

function Write-TestResult {
    param(
        [string]$Message,
        [string]$Level = "INFO"
    )
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss.fff"
    $logMessage = "[$timestamp] [$Level] $Message"
    Write-Host $logMessage -ForegroundColor $(
        switch ($Level) {
            "ERROR" { "Red" }
            "WARN" { "Yellow" }
            "OK" { "Green" }
            "DEBUG" { "Gray" }
            default { "White" }
        }
    )
    $script:testResults += $logMessage
}

Write-TestResult "========================================" "INFO"
Write-TestResult "MUTEX SINGLETON ENFORCEMENT TEST SUITE" "INFO"
Write-TestResult "========================================" "INFO"
Write-TestResult "Test started at: $testStartTime" "INFO"
Write-TestResult "Output file: $OutputFile" "INFO"
Write-TestResult "" "INFO"

# Set working directory
Set-Location "C:\UnityProjects\Sound-and-Shoal\Unity-Claude-Automation"

# Clear module cache to ensure fresh load
Write-TestResult "Clearing module cache..." "INFO"
Remove-Module Unity-Claude-SystemStatus -Force -ErrorAction SilentlyContinue

# Import the SystemStatus module
Write-TestResult "Importing Unity-Claude-SystemStatus module..." "INFO"
try {
    Import-Module ".\Modules\Unity-Claude-SystemStatus\Unity-Claude-SystemStatus.psd1" -Force -ErrorAction Stop
    Write-TestResult "Module imported successfully" "OK"
    
    # Verify mutex functions are available
    $requiredFunctions = @('New-SubsystemMutex', 'Test-SubsystemMutex', 'Remove-SubsystemMutex')
    $missing = $requiredFunctions | Where-Object { -not (Get-Command $_ -ErrorAction SilentlyContinue) }
    
    if ($missing) {
        Write-TestResult "[ERROR] Missing exported functions: $($missing -join ', ')" "ERROR"
        Write-TestResult "[DEBUG] Module functions present:" "DEBUG"
        Get-Command -Module Unity-Claude-SystemStatus | Select-Object -ExpandProperty Name | Sort-Object | ForEach-Object {
            Write-TestResult "  - $_" "DEBUG"
        }
        $testResults | Out-File $OutputFile
        exit 1
    }
    Write-TestResult "All required mutex functions verified" "OK"
    
} catch {
    Write-TestResult "Failed to import module: $_" "ERROR"
    $testResults | Out-File $OutputFile
    exit 1
}

# Test 1: Single Instance Acquisition
Write-TestResult "" "INFO"
Write-TestResult "TEST 1: Single Instance Acquisition" "INFO"
Write-TestResult "======================================" "INFO"

try {
    $mutexResult = New-SubsystemMutex -SubsystemName "TestSubsystem1" -TimeoutMs 1000
    
    if ($mutexResult.Acquired) {
        Write-TestResult "SUCCESS: Acquired mutex for TestSubsystem1" "OK"
        Write-TestResult "  IsNew: $($mutexResult.IsNew)" "DEBUG"
        Write-TestResult "  Message: $($mutexResult.Message)" "DEBUG"
        
        # Clean up
        Remove-SubsystemMutex -MutexObject $mutexResult.Mutex -SubsystemName "TestSubsystem1"
        Write-TestResult "Cleaned up mutex" "DEBUG"
    } else {
        Write-TestResult "FAILED: Could not acquire mutex" "ERROR"
        Write-TestResult "  Message: $($mutexResult.Message)" "ERROR"
    }
} catch {
    Write-TestResult "EXCEPTION in Test 1: $_" "ERROR"
}

# Test 2: Duplicate Prevention (Same Process)
Write-TestResult "" "INFO"
Write-TestResult "TEST 2: Duplicate Prevention (Same Process)" "INFO"
Write-TestResult "===========================================" "INFO"

try {
    # Acquire first mutex
    $mutex1 = New-SubsystemMutex -SubsystemName "TestSubsystem2" -TimeoutMs 1000
    
    if ($mutex1.Acquired) {
        Write-TestResult "Acquired first mutex for TestSubsystem2" "OK"
        
        # Try to acquire same mutex again
        $mutex2 = New-SubsystemMutex -SubsystemName "TestSubsystem2" -TimeoutMs 100
        
        if (-not $mutex2.Acquired) {
            Write-TestResult "SUCCESS: Second acquisition blocked as expected" "OK"
            Write-TestResult "  Message: $($mutex2.Message)" "DEBUG"
        } else {
            Write-TestResult "FAILED: Second acquisition should have been blocked" "ERROR"
            Remove-SubsystemMutex -MutexObject $mutex2.Mutex -SubsystemName "TestSubsystem2"
        }
        
        # Clean up first mutex
        Remove-SubsystemMutex -MutexObject $mutex1.Mutex -SubsystemName "TestSubsystem2"
        Write-TestResult "Cleaned up first mutex" "DEBUG"
    } else {
        Write-TestResult "FAILED: Could not acquire first mutex" "ERROR"
    }
} catch {
    Write-TestResult "EXCEPTION in Test 2: $_" "ERROR"
}

# Test 3: Abandoned Mutex Recovery
Write-TestResult "" "INFO"
Write-TestResult "TEST 3: Abandoned Mutex Recovery" "INFO"
Write-TestResult "=================================" "INFO"

try {
    # Create a script that acquires mutex and exits without releasing
    $abandonScript = @'
Import-Module "C:\UnityProjects\Sound-and-Shoal\Unity-Claude-Automation\Modules\Unity-Claude-SystemStatus\Unity-Claude-SystemStatus.psd1" -Force
$mutex = New-SubsystemMutex -SubsystemName "TestSubsystem3" -TimeoutMs 1000
if ($mutex.Acquired) {
    Write-Host "Acquired mutex in child process"
    # Exit without releasing - simulating crash
    exit 0
}
'@
    
    $abandonScript | Out-File ".\Test-AbandonMutex.ps1" -Encoding ASCII
    
    # Run script in separate process that will abandon the mutex
    Write-TestResult "Starting process that will abandon mutex..." "INFO"
    $process = Start-Process -FilePath "powershell.exe" -ArgumentList "-ExecutionPolicy", "Bypass", "-File", ".\Test-AbandonMutex.ps1" -PassThru -WindowStyle Hidden
    
    # Wait for process to acquire and abandon mutex
    Start-Sleep -Seconds 2
    
    if (-not $process.HasExited) {
        Stop-Process -Id $process.Id -Force
    }
    
    Write-TestResult "Process terminated, mutex should be abandoned" "INFO"
    
    # Try to acquire the abandoned mutex
    $recoveredMutex = New-SubsystemMutex -SubsystemName "TestSubsystem3" -TimeoutMs 1000
    
    if ($recoveredMutex.Acquired) {
        Write-TestResult "SUCCESS: Recovered abandoned mutex" "OK"
        Write-TestResult "  Message: $($recoveredMutex.Message)" "DEBUG"
        
        # Clean up
        Remove-SubsystemMutex -MutexObject $recoveredMutex.Mutex -SubsystemName "TestSubsystem3"
        Write-TestResult "Cleaned up recovered mutex" "DEBUG"
    } else {
        Write-TestResult "FAILED: Could not recover abandoned mutex" "ERROR"
        Write-TestResult "  Message: $($recoveredMutex.Message)" "ERROR"
    }
    
    # Clean up test script
    Remove-Item ".\Test-AbandonMutex.ps1" -ErrorAction SilentlyContinue
    
} catch {
    Write-TestResult "EXCEPTION in Test 3: $_" "ERROR"
}

# Test 4: Cross-Session Blocking
Write-TestResult "" "INFO"
Write-TestResult "TEST 4: Cross-Session Blocking" "INFO"
Write-TestResult "===============================" "INFO"

try {
    # Create a script that holds mutex for testing
    $holdScript = @'
param([int]$HoldTime = 5)
Import-Module "C:\UnityProjects\Sound-and-Shoal\Unity-Claude-Automation\Modules\Unity-Claude-SystemStatus\Unity-Claude-SystemStatus.psd1" -Force
$mutex = New-SubsystemMutex -SubsystemName "TestSubsystem4" -TimeoutMs 1000
if ($mutex.Acquired) {
    Write-Host "Holding mutex for $HoldTime seconds..."
    Start-Sleep -Seconds $HoldTime
    Remove-SubsystemMutex -MutexObject $mutex.Mutex -SubsystemName "TestSubsystem4"
    Write-Host "Released mutex"
} else {
    Write-Host "Could not acquire mutex"
}
'@
    
    $holdScript | Out-File ".\Test-HoldMutex.ps1" -Encoding ASCII
    
    # Start process that holds mutex
    Write-TestResult "Starting process to hold mutex..." "INFO"
    $holdProcess = Start-Process -FilePath "powershell.exe" -ArgumentList "-ExecutionPolicy", "Bypass", "-File", ".\Test-HoldMutex.ps1", "-HoldTime", "5" -PassThru -WindowStyle Hidden
    
    # Give it time to acquire
    Start-Sleep -Seconds 1
    
    # Try to acquire from this session - should fail
    Write-TestResult "Attempting to acquire mutex from current session..." "INFO"
    $blockedMutex = New-SubsystemMutex -SubsystemName "TestSubsystem4" -TimeoutMs 500
    
    if (-not $blockedMutex.Acquired) {
        Write-TestResult "SUCCESS: Cross-session blocking working" "OK"
        Write-TestResult "  Message: $($blockedMutex.Message)" "DEBUG"
    } else {
        Write-TestResult "FAILED: Should have been blocked by other session" "ERROR"
        Remove-SubsystemMutex -MutexObject $blockedMutex.Mutex -SubsystemName "TestSubsystem4"
    }
    
    # Wait for holding process to finish
    Write-TestResult "Waiting for holding process to release..." "INFO"
    $holdProcess.WaitForExit(10000) | Out-Null
    
    # Now try again - should succeed
    Start-Sleep -Seconds 1
    $freedMutex = New-SubsystemMutex -SubsystemName "TestSubsystem4" -TimeoutMs 1000
    
    if ($freedMutex.Acquired) {
        Write-TestResult "SUCCESS: Acquired mutex after other session released" "OK"
        Remove-SubsystemMutex -MutexObject $freedMutex.Mutex -SubsystemName "TestSubsystem4"
    } else {
        Write-TestResult "FAILED: Should have acquired after release" "ERROR"
    }
    
    # Clean up test script
    Remove-Item ".\Test-HoldMutex.ps1" -ErrorAction SilentlyContinue
    
} catch {
    Write-TestResult "EXCEPTION in Test 4: $_" "ERROR"
}

# Test 5: Test-SubsystemMutex Function
Write-TestResult "" "INFO"
Write-TestResult "TEST 5: Test-SubsystemMutex Function" "INFO"
Write-TestResult "=====================================" "INFO"

try {
    # Test when no mutex exists
    $status1 = Test-SubsystemMutex -SubsystemName "TestSubsystem5"
    
    if (-not $status1.Exists -and -not $status1.IsHeld) {
        Write-TestResult "SUCCESS: Correctly detected no mutex exists" "OK"
        Write-TestResult "  Message: $($status1.Message)" "DEBUG"
    } else {
        Write-TestResult "FAILED: Should detect no mutex" "ERROR"
    }
    
    # Create a mutex
    $mutex = New-SubsystemMutex -SubsystemName "TestSubsystem5" -TimeoutMs 1000
    
    if ($mutex.Acquired) {
        # Test while mutex is held
        $status2 = Test-SubsystemMutex -SubsystemName "TestSubsystem5"
        
        if ($status2.Exists -and $status2.IsHeld) {
            Write-TestResult "SUCCESS: Correctly detected mutex exists and is held" "OK"
            Write-TestResult "  Message: $($status2.Message)" "DEBUG"
        } else {
            Write-TestResult "FAILED: Should detect mutex exists and is held" "ERROR"
        }
        
        # Clean up
        Remove-SubsystemMutex -MutexObject $mutex.Mutex -SubsystemName "TestSubsystem5"
        
        # Test after release
        Start-Sleep -Milliseconds 500
        $status3 = Test-SubsystemMutex -SubsystemName "TestSubsystem5"
        
        if (-not $status3.IsHeld) {
            Write-TestResult "SUCCESS: Correctly detected mutex is not held after release" "OK"
            Write-TestResult "  Message: $($status3.Message)" "DEBUG"
        } else {
            Write-TestResult "FAILED: Should detect mutex is not held" "ERROR"
        }
    }
    
} catch {
    Write-TestResult "EXCEPTION in Test 5: $_" "ERROR"
}

# Summary
$testEndTime = Get-Date
$testDuration = $testEndTime - $testStartTime

Write-TestResult "" "INFO"
Write-TestResult "========================================" "INFO"
Write-TestResult "TEST SUITE COMPLETED" "INFO"
Write-TestResult "========================================" "INFO"
Write-TestResult "End time: $testEndTime" "INFO"
Write-TestResult "Duration: $($testDuration.TotalSeconds) seconds" "INFO"

# Count results
$errorCount = ($testResults | Where-Object { $_ -match '\[ERROR\]' }).Count
$successCount = ($testResults | Where-Object { $_ -match 'SUCCESS:' }).Count

Write-TestResult "" "INFO"
Write-TestResult "Results Summary:" "INFO"
Write-TestResult "  Successes: $successCount" $(if ($successCount -gt 0) { "OK" } else { "WARN" })
Write-TestResult "  Errors: $errorCount" $(if ($errorCount -eq 0) { "OK" } else { "ERROR" })

# Save results to file
Write-TestResult "" "INFO"
Write-TestResult "Saving results to: $OutputFile" "INFO"
$testResults | Out-File $OutputFile -Encoding ASCII

if ($errorCount -eq 0) {
    Write-TestResult "All tests passed successfully!" "OK"
} else {
    Write-TestResult "Some tests failed. Review the output for details." "WARN"
}

Write-TestResult "Test output saved to: $OutputFile" "INFO"