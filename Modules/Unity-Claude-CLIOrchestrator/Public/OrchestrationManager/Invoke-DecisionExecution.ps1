function Invoke-DecisionExecution {
    <#
    .SYNOPSIS
        Executes decisions with safety checks and validation
        
    .DESCRIPTION
        Takes a decision result and safely executes the recommended actions
        
    .PARAMETER DecisionResult
        The decision result object from Invoke-AutonomousDecisionMaking
        
    .OUTPUTS
        PSCustomObject with execution results
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [PSCustomObject]$DecisionResult
    )
    
    try {
        Write-Host "DEBUG Invoke-DecisionExecution: Processing decision: $($DecisionResult.Decision)" -ForegroundColor DarkGray
        
        $executionResult = [PSCustomObject]@{
            Timestamp = Get-Date
            Decision = $DecisionResult.Decision
            ExecutionStatus = "Not Executed"
            Actions = @()
            Errors = @()
            TestResults = $null
        }
        
        # Safety check
        if (-not $DecisionResult.SafetyChecks) {
            Write-Host "DEBUG SAFETY CHECK FAILED - Blocking execution" -ForegroundColor Red
            $executionResult.ExecutionStatus = "Blocked - Safety Check Failed"
            $executionResult.Errors += "Execution blocked due to failed safety validation"
            return $executionResult
        }
        
        # Execute based on decision
        switch ($DecisionResult.Decision) {
            "EXECUTE_TEST" {
                Write-Host "DEBUG *** TESTING FLOW EXECUTION *** EXECUTE_TEST CASE REACHED ***" -ForegroundColor Magenta
                Write-Host "DEBUG TESTING FLOW: Starting test execution phase" -ForegroundColor Cyan
                Write-Host "DEBUG TESTING FLOW: TestPath from decision: '$($DecisionResult.TestPath)'" -ForegroundColor Cyan
                Write-Host "DEBUG TESTING FLOW: Decision confidence: $($DecisionResult.Confidence)%" -ForegroundColor Cyan
                
                if (-not $DecisionResult.TestPath) {
                    Write-Host "DEBUG TESTING FLOW: [ERROR] CRITICAL ERROR: No test path found in decision" -ForegroundColor Red
                    $executionResult.ExecutionStatus = "Failed"
                    $executionResult.Errors += "No test path specified in decision result"
                    return $executionResult
                }
                
                Write-Host "DEBUG TESTING FLOW: [OK] Test path validation successful" -ForegroundColor Green
                
                # Execute the test
                try {
                    Write-Host "DEBUG TESTING FLOW: [START] Starting test execution for: $($DecisionResult.TestPath)" -ForegroundColor Yellow
                    $testPath = $DecisionResult.TestPath
                    
                    # Normalize and validate test path
                    if (-not [System.IO.Path]::IsPathRooted($testPath)) {
                        $testPath = Join-Path (Get-Location) $testPath
                        Write-Host "DEBUG TESTING FLOW: [PATH] Normalized relative path to: $testPath" -ForegroundColor DarkGray
                    }
                    
                    # Check if test file exists
                    Write-Host "DEBUG TESTING FLOW: [CHECK] Checking if test file exists: $testPath" -ForegroundColor DarkGray
                    if (-not (Test-Path $testPath)) {
                        Write-Host "DEBUG TESTING FLOW: [ERROR] Test file not found: $testPath" -ForegroundColor Red
                        Write-Host "DEBUG TESTING FLOW: Current directory: $(Get-Location)" -ForegroundColor Red
                        Write-Host "DEBUG TESTING FLOW: Available .ps1 files in current directory:" -ForegroundColor Red
                        Get-ChildItem -Filter "*.ps1" | Select-Object Name | ForEach-Object { Write-Host "  - $($_.Name)" -ForegroundColor DarkRed }
                        $executionResult.ExecutionStatus = "Failed"
                        $executionResult.Errors += "Test file not found: $testPath"
                        return $executionResult
                    }
                    
                    Write-Host "DEBUG TESTING FLOW: [OK] Test file exists and is accessible" -ForegroundColor Green
                    
                    # Generate result file name
                    $timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
                    $testName = [System.IO.Path]::GetFileNameWithoutExtension($testPath)
                    $resultFile = ".\{0}-TestResults-{1}.txt" -f $testName, $timestamp
                    Write-Host "DEBUG TESTING FLOW: [RESULTS] Test results will be saved to: $resultFile" -ForegroundColor DarkGray
                    
                    # Execute test in new window
                    Write-Host "DEBUG TESTING FLOW: [WINDOW] Opening new PowerShell window for test execution..." -ForegroundColor Cyan
                    $testRunnerPath = ".\Execute-TestInWindow.ps1"
                    
                    Write-Host "DEBUG TESTING FLOW: [CHECK] Checking for test runner script: $testRunnerPath" -ForegroundColor DarkGray
                    if (-not (Test-Path $testRunnerPath)) {
                        Write-Host "DEBUG TESTING FLOW: [WARNING] Test runner script not found, falling back to inline execution" -ForegroundColor Yellow
                        Write-Host "DEBUG TESTING FLOW: [INLINE] Executing test inline with powershell.exe" -ForegroundColor Yellow
                        
                        # Fallback to inline execution with comprehensive logging
                        Write-Host "DEBUG TESTING FLOW: Command: powershell.exe -ExecutionPolicy Bypass -File '$testPath'" -ForegroundColor DarkYellow
                        Write-Host "[TRACE] TESTING FLOW - About to execute test inline" -ForegroundColor DarkMagenta
                        Write-Host "[TRACE] Current directory: $(Get-Location)" -ForegroundColor DarkMagenta
                        Write-Host "[TRACE] Test file full path: $testPath" -ForegroundColor DarkMagenta
                        Write-Host "[TRACE] Test file size: $((Get-Item $testPath).Length) bytes" -ForegroundColor DarkMagenta
                        $testOutput = & powershell.exe -ExecutionPolicy Bypass -File $testPath 2>&1
                        Write-Host "[TRACE] TESTING FLOW - Test execution completed, capturing output" -ForegroundColor DarkMagenta
                        $exitCode = $LASTEXITCODE
                        
                        Write-Host "DEBUG TESTING FLOW: [DONE] Inline execution completed" -ForegroundColor Green
                        Write-Host "DEBUG TESTING FLOW: Exit code: $exitCode" -ForegroundColor Green
                        Write-Host "DEBUG TESTING FLOW: Output lines: $($testOutput.Count)" -ForegroundColor Green
                        
                        # Save test results
                        $testResultContent = @"
Test Execution Report
====================
Test Script: $testPath
Execution Time: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
Exit Code: $exitCode

Test Output:
============
$($testOutput -join "`n")
"@
                        
                        $testResultContent | Out-File -FilePath $resultFile -Encoding UTF8
                        Write-Host "DEBUG Test results saved to: $resultFile" -ForegroundColor Green
                        
                        $executionResult.ExecutionStatus = "Success"
                        $executionResult.Actions += "Executed test: $testPath"
                        $executionResult.Actions += "Results saved to: $resultFile"
                        $executionResult.TestResults = $resultFile
                        
                        # Now submit results to Claude
                        Write-Host "DEBUG Preparing to submit test results to Claude..." -ForegroundColor Cyan
                        Write-Host "[TRACE] TESTING FLOW - Claude submission phase started" -ForegroundColor DarkMagenta
                        Write-Host "[TRACE] Result file path: $resultFile" -ForegroundColor DarkMagenta
                        Write-Host "[TRACE] Test output lines: $($testOutput.Count)" -ForegroundColor DarkMagenta
                        
                        # Build the prompt for Claude
                        $boilerplatePath = "C:\UnityProjects\Sound-and-Shoal\Unity-Claude-Automation\CLAUDE_PROMPT_DIRECTIVES_COMPLETE_UCA.txt"
                        Write-Host "[TRACE] Boilerplate path: $boilerplatePath" -ForegroundColor DarkMagenta
                        Write-Host "[TRACE] Boilerplate exists: $(Test-Path $boilerplatePath)" -ForegroundColor DarkMagenta
                        $boilerplate = if (Test-Path $boilerplatePath) { 
                            $bp = Get-Content $boilerplatePath -Raw 
                            Write-Host "[TRACE] Boilerplate loaded, length: $($bp.Length) characters" -ForegroundColor DarkMagenta
                            $bp
                        } else { 
                            Write-Host "[TRACE] Using fallback boilerplate" -ForegroundColor DarkMagenta
                            "Please review the following test results and provide analysis." 
                        }
                        
                        $promptText = @"
$boilerplate

***END OF BOILERPLATE***

//Prompt type, additional instructions, and parameters below:
Prompt-type: Testing
Test Results File: $resultFile

The test has been executed. Please review the test results file at $resultFile.
Exit Code: $exitCode

Test Output Summary:
$($testOutput | Select-Object -First 50 | Out-String)
"@
                        
                        Write-Host "[TRACE] Final prompt text built, total length: $($promptText.Length) characters" -ForegroundColor DarkMagenta
                        Write-Host "[TRACE] Prompt preview (first 200 chars): $($promptText.Substring(0, [Math]::Min(200, $promptText.Length)))..." -ForegroundColor DarkGray
                        Write-Host "DEBUG Attempting to submit prompt to Claude..." -ForegroundColor DarkGray
                        
                        # Submit to Claude
                        try {
                            Write-Host "[TRACE] Calling Submit-ToClaudeViaTypeKeys function" -ForegroundColor DarkMagenta
                            $submissionResult = Submit-ToClaudeViaTypeKeys -PromptText $promptText
                            Write-Host "[TRACE] Submit-ToClaudeViaTypeKeys returned: $submissionResult" -ForegroundColor DarkMagenta
                            if ($submissionResult) {
                                Write-Host "DEBUG Successfully submitted test results to Claude" -ForegroundColor Green
                                Write-Host "[TRACE] TESTING FLOW - End-to-end test execution and submission complete" -ForegroundColor DarkMagenta
                                $executionResult.Actions += "Submitted test results to Claude"
                            }
                            else {
                                Write-Host "DEBUG Failed to submit test results to Claude" -ForegroundColor Red
                                Write-Host "[TRACE] TESTING FLOW - Claude submission failed" -ForegroundColor DarkMagenta
                                $executionResult.Errors += "Failed to submit test results to Claude"
                            }
                        }
                        catch {
                            Write-Host "DEBUG Exception during Claude submission: $_" -ForegroundColor Red
                            Write-Host "[TRACE] TESTING FLOW - Exception during Claude submission: $($_.Exception)" -ForegroundColor DarkMagenta
                            $executionResult.Errors += "Claude submission error: $_"
                        }
                    }
                    else {
                        # Start test in new window
                        Write-Host "DEBUG TESTING FLOW: [OK] Test runner script found, using windowed execution" -ForegroundColor Green
                        Write-Host "DEBUG TESTING FLOW: [BUILD] Building arguments for test runner" -ForegroundColor Green
                        
                        $arguments = @(
                            "-NoProfile",
                            "-ExecutionPolicy", "Bypass",
                            "-File", $testRunnerPath,
                            "-TestPath", $testPath,
                            "-ResultFile", $resultFile
                        )
                        
                        Write-Host "DEBUG TESTING FLOW: Arguments: $($arguments -join ' ')" -ForegroundColor DarkGreen
                        Write-Host "DEBUG TESTING FLOW: [LAUNCH] Launching test process..." -ForegroundColor Green
                        
                        $process = Start-Process -FilePath "powershell.exe" -ArgumentList $arguments -PassThru
                        Write-Host "DEBUG TESTING FLOW: [OK] Test window launched with process ID: $($process.Id)" -ForegroundColor Cyan
                        Write-Host "DEBUG TESTING FLOW: Process name: $($process.ProcessName)" -ForegroundColor Cyan
                        Write-Host "DEBUG TESTING FLOW: Start time: $($process.StartTime)" -ForegroundColor Cyan
                        
                        # Don't wait for completion - let it run async and check for signal file
                        $executionResult.ExecutionStatus = "Success"
                        $executionResult.Actions += "Launched test in new window: $testPath"
                        $executionResult.Actions += "Test process ID: $($process.Id)"
                        $executionResult.TestResults = $resultFile
                        
                        Write-Host "DEBUG TESTING FLOW: [OK] Test launched successfully in new window" -ForegroundColor Green
                        Write-Host "DEBUG TESTING FLOW: [SIGNAL] Test will signal completion via signal file" -ForegroundColor Yellow
                        Write-Host "DEBUG TESTING FLOW: [MONITOR] The orchestrator will pick up the signal file in the next monitoring cycle" -ForegroundColor Yellow
                        
                        # The orchestrator will pick up the signal file in the next monitoring cycle
                        return $executionResult
                    }
                }
                catch {
                    Write-Host "DEBUG ERROR executing test: $_" -ForegroundColor Red
                    $executionResult.ExecutionStatus = "Failed"
                    $executionResult.Errors += "Test execution error: $_"
                }
            }
            "DEBUG" {
                Write-Host "DEBUG Processing DEBUG decision" -ForegroundColor Yellow
                $executionResult.ExecutionStatus = "Investigating"
                $executionResult.Actions += "Flagged for debugging investigation"
            }
            "EXECUTE" {
                Write-Host "DEBUG Processing EXECUTE decision" -ForegroundColor Yellow
                $executionResult.ExecutionStatus = "Simulated"  # Safe simulation for now
                $executionResult.Actions += "Would execute recommended action (simulated)"
            }
            "INVESTIGATE" {
                Write-Host "DEBUG Processing INVESTIGATE decision" -ForegroundColor Yellow
                $executionResult.ExecutionStatus = "Investigating"
                $executionResult.Actions += "Flagged for investigation"
            }
            "CONTINUE" {
                Write-Host "DEBUG Processing CONTINUE decision" -ForegroundColor Yellow
                # Extract the recommendation from the response file and submit to Claude
                try {
                    if ($DecisionResult.ResponseText) {
                        Write-Host "DEBUG Submitting continuation to Claude..." -ForegroundColor DarkGray
                        $submissionResult = Submit-ToClaudeViaTypeKeys -PromptText $DecisionResult.ResponseText
                        if ($submissionResult) {
                            $executionResult.ExecutionStatus = "Success"
                            $executionResult.Actions += "Successfully submitted continuation to Claude"
                            Write-Host "DEBUG Continuation submitted successfully" -ForegroundColor Green
                        }
                        else {
                            $executionResult.ExecutionStatus = "Failed"
                            $executionResult.Errors += "Failed to submit prompt to Claude"
                            Write-Host "DEBUG Failed to submit continuation" -ForegroundColor Red
                        }
                    }
                    else {
                        $executionResult.ExecutionStatus = "No Action Required"
                        $executionResult.Actions += "No recommendation found in response"
                        Write-Host "DEBUG No recommendation to continue with" -ForegroundColor Gray
                    }
                }
                catch {
                    $executionResult.ExecutionStatus = "Failed"
                    $executionResult.Errors += "Error processing CONTINUE decision: $($_.Exception.Message)"
                    Write-Host "DEBUG ERROR in CONTINUE: $_" -ForegroundColor Red
                }
            }
            "BLOCK" {
                Write-Host "DEBUG Processing BLOCK decision" -ForegroundColor Red
                $executionResult.ExecutionStatus = "Blocked"
                $executionResult.Actions += "Action blocked for safety"
            }
            default {
                Write-Host "DEBUG Unknown decision type: $($DecisionResult.Decision)" -ForegroundColor Red
                $executionResult.ExecutionStatus = "Unknown Decision"
                $executionResult.Errors += "Unknown decision type: $($DecisionResult.Decision)"
            }
        }
        
        Write-Host "DEBUG Execution Result: $($executionResult.ExecutionStatus)" -ForegroundColor Cyan
        return $executionResult
    }
    catch {
        Write-Host "DEBUG CRITICAL ERROR in Invoke-DecisionExecution: $_" -ForegroundColor Red
        throw "Execution failed: $($_.Exception.Message)"
    }
}