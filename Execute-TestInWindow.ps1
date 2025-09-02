# Execute-TestInWindow.ps1
# Runs a test script in a new PowerShell window with full output capture and signaling

param(
    [Parameter(Mandatory = $true)]
    [string]$TestPath,
    
    [Parameter(Mandatory = $false)]
    [string]$ResultFile,
    
    [Parameter(Mandatory = $false)]
    [switch]$AutoClose
)

$ErrorActionPreference = 'Continue'  # Changed from 'Stop' to continue on errors

# Initialize variables
$testOutput = @()
$testExitCode = 1  # Default to failure
$testStatus = "FAILED"
$errorDetails = $null

try {
    Write-Host ""
    Write-Host "=====================================" -ForegroundColor Cyan
    Write-Host "    Test Execution Runner v3.0      " -ForegroundColor Cyan
    Write-Host "    (Enhanced Error Handling)       " -ForegroundColor Yellow
    Write-Host "=====================================" -ForegroundColor Cyan
    Write-Host ""
    
    # Log every step
    Write-Host "[TRACE] Starting test execution runner with error handling" -ForegroundColor Magenta
    Write-Host "[TRACE] Test path: $TestPath" -ForegroundColor Magenta
    Write-Host "[TRACE] Error action preference: Continue (will capture all output)" -ForegroundColor Magenta
    
    # Validate test file exists
    if (-not (Test-Path $TestPath)) {
        $errorDetails = "Test file not found: $TestPath"
        Write-Host "[ERROR] $errorDetails" -ForegroundColor Red
        $testOutput = @("[ERROR] $errorDetails")
        throw $errorDetails
    }
    
    Write-Host "Test Script: $TestPath" -ForegroundColor Yellow
    Write-Host "Start Time: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor Gray
    Write-Host ""
    
    # Generate result file name if not provided
    if (-not $ResultFile) {
        $testName = [System.IO.Path]::GetFileNameWithoutExtension($TestPath)
        $timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
        $ResultFile = ".\$testName-TestResults-$timestamp.txt"
    }
    
    Write-Host "Result File: $ResultFile" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Executing test..." -ForegroundColor Cyan
    Write-Host "==================" -ForegroundColor Cyan
    Write-Host ""
    
    # Execute the test and capture all output (including errors)
    $testStartTime = Get-Date
    Write-Host "[TRACE] Executing PowerShell script..." -ForegroundColor Magenta
    Write-Host "[TRACE] Using -NoProfile -NonInteractive to avoid hangs" -ForegroundColor Magenta
    Write-Host "[TRACE] Will capture both stdout and stderr" -ForegroundColor Magenta
    
    try {
        # Run with NoProfile and NonInteractive to avoid signature prompts
        # Capture both stdout and stderr by redirecting all streams
        $testOutput = & powershell.exe -NoProfile -NonInteractive -ExecutionPolicy Bypass -Command "& '$TestPath'" 2>&1 | Out-String -Stream
        $testExitCode = $LASTEXITCODE
        
        # Handle null output
        if ($null -eq $testOutput -or $testOutput.Count -eq 0) {
            $testOutput = @("[WARNING] Test produced no output")
            Write-Host "[WARNING] Test produced no output" -ForegroundColor Yellow
        }
    }
    catch {
        Write-Host "[ERROR] Exception during test execution: $_" -ForegroundColor Red
        $testOutput = @(
            "[ERROR] Test execution failed with exception:",
            $_.Exception.Message,
            $_.ScriptStackTrace
        )
        $testExitCode = 1
        $errorDetails = $_.Exception.Message
    }
    
    $testEndTime = Get-Date
    $testDuration = $testEndTime - $testStartTime
    
    Write-Host "[TRACE] Test execution completed with exit code: $testExitCode" -ForegroundColor Magenta
    Write-Host "[TRACE] Test duration: $($testDuration.TotalSeconds.ToString('F2')) seconds" -ForegroundColor Magenta
    
    # Display test output with color coding
    $testOutput | ForEach-Object {
        if ($_ -match "ERROR|FAIL") {
            Write-Host $_ -ForegroundColor Red
        }
        elseif ($_ -match "SUCCESS|PASS") {
            Write-Host $_ -ForegroundColor Green
        }
        elseif ($_ -match "WARNING") {
            Write-Host $_ -ForegroundColor Yellow
        }
        else {
            Write-Host $_
        }
    }
    
    Write-Host ""
    Write-Host "==================" -ForegroundColor Cyan
    Write-Host "Test execution completed" -ForegroundColor Cyan
    Write-Host ""
    
    # Determine test result
    $testStatus = if ($testExitCode -eq 0) { "SUCCESS" } else { "FAILED" }
    $statusColor = if ($testExitCode -eq 0) { "Green" } else { "Red" }
    
    Write-Host "Exit Code: $testExitCode" -ForegroundColor $statusColor
    Write-Host "Status: $testStatus" -ForegroundColor $statusColor
    Write-Host "Duration: $($testDuration.TotalSeconds.ToString('F2')) seconds" -ForegroundColor Gray
    Write-Host ""
    
    # Format and save results
    $testResultContent = @"
====================================
Test Execution Report
====================================

Test Script: $TestPath
Execution Time: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
Duration: $($testDuration.TotalSeconds.ToString('F2')) seconds
Exit Code: $testExitCode
Status: $testStatus

Test Output:
============
$($testOutput -join "`n")

====================================
End of Test Report
====================================
"@
    
    # Save results to file
    Write-Host "[TRACE] Saving results to: $ResultFile" -ForegroundColor Magenta
    $testResultContent | Out-File -FilePath $ResultFile -Encoding UTF8
    Write-Host "Results saved to: $ResultFile" -ForegroundColor Green
    
    # Create a signal file for the orchestrator
    $signalDir = ".\ClaudeResponses\Autonomous"
    if (-not (Test-Path $signalDir)) {
        New-Item -ItemType Directory -Path $signalDir -Force | Out-Null
    }
    
    $signalFile = "$signalDir\TestComplete_$(Get-Date -Format 'yyyyMMdd_HHmmss').signal"
    Write-Host "[TRACE] Creating signal file: $signalFile" -ForegroundColor Magenta
    
    @{
        TestPath = $TestPath
        ResultFile = $ResultFile
        ExitCode = $testExitCode
        Status = $testStatus
        Timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
    } | ConvertTo-Json | Out-File -FilePath $signalFile -Encoding UTF8
    
    Write-Host "Signal file created: $signalFile" -ForegroundColor Green
    Write-Host ""
    
    if (-not $AutoClose) {
        Write-Host "Test execution complete. Window will remain open for review." -ForegroundColor Cyan
        Write-Host "Press Enter to close..." -ForegroundColor Yellow
        Read-Host
    }
    
    # Exit code will be set later after finally block
}
catch {
    Write-Host ""
    Write-Host "[ERROR] Test execution runner encountered an error!" -ForegroundColor Red
    Write-Host "[ERROR] $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "[TRACE] Full error: $_" -ForegroundColor DarkRed
    Write-Host "[TRACE] Stack trace: $($_.ScriptStackTrace)" -ForegroundColor DarkRed
    Write-Host ""
    
    # Capture error for results
    if ($null -eq $testOutput -or $testOutput.Count -eq 0) {
        $testOutput = @()
    }
    $testOutput += "[ERROR] Test runner error: $($_.Exception.Message)"
    $errorDetails = $_.Exception.Message
    $testExitCode = 1
    $testStatus = "FAILED"
}
finally {
    Write-Host "[TRACE] Entering finally block - ensuring results are saved" -ForegroundColor Magenta
    
    # Ensure we have some output to save
    if ($null -eq $testOutput -or $testOutput.Count -eq 0) {
        $testOutput = @("[ERROR] No test output captured")
    }
    
    # Ensure we have a result file path
    if (-not $ResultFile) {
        $testName = [System.IO.Path]::GetFileNameWithoutExtension($TestPath)
        $timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
        $ResultFile = ".\$testName-TestResults-$timestamp.txt"
    }
    
    # Ensure we have duration
    if (-not $testDuration) {
        $testDuration = New-TimeSpan -Seconds 0
    }
    
    # Always save test results, even on failure
    Write-Host "[TRACE] Saving test results to: $ResultFile" -ForegroundColor Yellow
    
    $testResultContent = @"
====================================
Test Execution Report
====================================

Test Script: $TestPath
Execution Time: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
Duration: $($testDuration.TotalSeconds.ToString('F2')) seconds
Exit Code: $testExitCode
Status: $testStatus
Error Details: $errorDetails

Test Output:
============
$($testOutput -join "`n")

====================================
End of Test Report
====================================
"@
    
    try {
        $testResultContent | Out-File -FilePath $ResultFile -Encoding UTF8
        Write-Host "[SUCCESS] Results saved to: $ResultFile" -ForegroundColor Green
    }
    catch {
        Write-Host "[ERROR] Failed to save results: $_" -ForegroundColor Red
    }
    
    # Always create a signal file for the orchestrator
    Write-Host "[TRACE] Creating signal file for orchestrator" -ForegroundColor Yellow
    
    try {
        $signalDir = ".\ClaudeResponses\Autonomous"
        if (-not (Test-Path $signalDir)) {
            New-Item -ItemType Directory -Path $signalDir -Force | Out-Null
        }
        
        $signalFile = "$signalDir\TestComplete_$(Get-Date -Format 'yyyyMMdd_HHmmss').signal"
        
        @{
            TestPath = $TestPath
            ResultFile = $ResultFile
            ExitCode = $testExitCode
            Status = $testStatus
            ErrorDetails = $errorDetails
            Timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
        } | ConvertTo-Json | Out-File -FilePath $signalFile -Encoding UTF8
        
        Write-Host "[SUCCESS] Signal file created: $signalFile" -ForegroundColor Green
    }
    catch {
        Write-Host "[ERROR] Failed to create signal file: $_" -ForegroundColor Red
    }
    
    Write-Host ""
    Write-Host "=====================================" -ForegroundColor Cyan
    Write-Host "Test execution complete." -ForegroundColor Cyan
    Write-Host "Status: $testStatus" -ForegroundColor $(if($testStatus -eq "SUCCESS"){"Green"}else{"Red"})
    Write-Host "Exit Code: $testExitCode" -ForegroundColor $(if($testExitCode -eq 0){"Green"}else{"Red"})
    Write-Host "=====================================" -ForegroundColor Cyan
    
    if (-not $AutoClose) {
        Write-Host ""
        Write-Host "Window will remain open for review." -ForegroundColor Yellow
        Write-Host "Press Enter to close..." -ForegroundColor Yellow
        Read-Host
    }
    
    # Exit with the appropriate code
    exit $testExitCode
}