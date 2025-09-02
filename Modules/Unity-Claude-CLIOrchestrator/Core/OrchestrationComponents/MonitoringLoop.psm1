# MonitoringLoop.psm1
# Monitoring loop and execution cycle management

function Start-MonitoringLoop {
    <#
    .SYNOPSIS
        Starts the autonomous monitoring loop
    #>
    [CmdletBinding()]
    param(
        [PSCustomObject]$OrchestrationResults,
        [int]$MonitoringInterval,
        [int]$MaxExecutionTime,
        [switch]$EnableResponseAnalysis,
        [switch]$EnableDecisionMaking
    )
    
    try {
        $startTime = Get-Date
        $maxEndTime = $startTime.AddMinutes($MaxExecutionTime)
        $cycleCount = 0
        
        Write-Host "Monitoring loop started at $($startTime.ToString('HH:mm:ss'))" -ForegroundColor Cyan
        Write-Host "Will run until $($maxEndTime.ToString('HH:mm:ss')) (max $MaxExecutionTime minutes)" -ForegroundColor Gray
        Write-Host ""
        
        while ((Get-Date) -lt $maxEndTime) {
            $cycleCount++
            $cycleStart = Get-Date
            
            Write-Host "--- Monitoring Cycle $cycleCount ---" -ForegroundColor Yellow
            Write-Host "Time: $($cycleStart.ToString('HH:mm:ss'))" -ForegroundColor Gray
            
            # Check for new signal files
            $responseDir = ".\ClaudeResponses\Autonomous"
            $signalFiles = Get-ChildItem -Path $responseDir -Filter "*.signal" -ErrorAction SilentlyContinue
            
            if ($signalFiles.Count -gt 0) {
                Write-Host "Found $($signalFiles.Count) signal file(s) to process" -ForegroundColor Green
                
                foreach ($signalFile in $signalFiles) {
                    try {
                        Write-Host "  Processing: $($signalFile.Name)" -ForegroundColor Cyan
                        
                        # Process the response file
                        $responseFile = Process-SignalFile -SignalFile $signalFile.FullName
                        if ($responseFile) {
                            $OrchestrationResults.ResponsesAnalyzed++
                            
                            # Analyze response if enabled
                            if ($EnableResponseAnalysis) {
                                $analysis = Invoke-ComprehensiveResponseAnalysis -ResponseFile $responseFile
                                Write-Host "    Analysis complete - Confidence: $($analysis.Confidence)%" -ForegroundColor Gray
                            }
                            
                            # Make decision if enabled
                            if ($EnableDecisionMaking) {
                                $decision = Invoke-AutonomousDecisionMaking -ResponseFile $responseFile
                                if ($decision) {
                                    $OrchestrationResults.DecisionsMade++
                                    Write-Host "    Decision: $($decision.Action)" -ForegroundColor Yellow
                                    
                                    # Execute decision
                                    $result = Invoke-DecisionExecution -Decision $decision
                                    if ($result.Success) {
                                        $OrchestrationResults.ActionsExecuted++
                                        Write-Host "    Execution successful" -ForegroundColor Green
                                    }
                                }
                            }
                        }
                    }
                    catch {
                        Write-Host "    ERROR processing signal: $_" -ForegroundColor Red
                        $OrchestrationResults.Errors += $_
                    }
                }
            }
            else {
                Write-Host "No new signals detected" -ForegroundColor Gray
            }
            
            $OrchestrationResults.MonitoringCycles = $cycleCount
            
            # Calculate time until next cycle
            $cycleEnd = Get-Date
            $cycleDuration = ($cycleEnd - $cycleStart).TotalSeconds
            $sleepTime = [Math]::Max(1, $MonitoringInterval - $cycleDuration)
            
            if ((Get-Date).AddSeconds($sleepTime) -lt $maxEndTime) {
                Write-Host "Next cycle in $sleepTime seconds..." -ForegroundColor Gray
                Write-Host ""
                Start-Sleep -Seconds $sleepTime
            }
            else {
                Write-Host "Maximum execution time reached" -ForegroundColor Yellow
                break
            }
        }
        
        Write-Host "Monitoring loop completed after $cycleCount cycles" -ForegroundColor Green
        return $OrchestrationResults
    }
    catch {
        Write-Host "ERROR in Start-MonitoringLoop: $_" -ForegroundColor Red
        $OrchestrationResults.Errors += $_
        return $OrchestrationResults
    }
}

function Invoke-SingleExecutionCycle {
    <#
    .SYNOPSIS
        Performs a single execution cycle without looping
    #>
    [CmdletBinding()]
    param(
        [PSCustomObject]$OrchestrationResults,
        [switch]$EnableResponseAnalysis,
        [switch]$EnableDecisionMaking
    )
    
    try {
        Write-Host "Performing single execution cycle..." -ForegroundColor Cyan
        
        # Check for existing signal files
        $responseDir = ".\ClaudeResponses\Autonomous"
        $signalFiles = Get-ChildItem -Path $responseDir -Filter "*.signal" -ErrorAction SilentlyContinue
        
        if ($signalFiles.Count -eq 0) {
            Write-Host "No signal files found to process" -ForegroundColor Yellow
            
            # Check for recent response files
            $recentResponses = Get-ChildItem -Path $responseDir -Filter "*.json" -ErrorAction SilentlyContinue |
                Where-Object { $_.LastWriteTime -gt (Get-Date).AddMinutes(-5) }
            
            if ($recentResponses.Count -gt 0) {
                Write-Host "Found $($recentResponses.Count) recent response file(s)" -ForegroundColor Green
                $signalFiles = $recentResponses
            }
        }
        
        foreach ($file in $signalFiles) {
            try {
                Write-Host "Processing: $($file.Name)" -ForegroundColor Cyan
                
                # Process response
                $responseData = Process-ResponseFile -FilePath $file.FullName
                if ($responseData) {
                    $OrchestrationResults.ResponsesAnalyzed++
                    
                    # Analyze if enabled
                    if ($EnableResponseAnalysis) {
                        $analysis = Invoke-ComprehensiveResponseAnalysis -ResponseFile $file.FullName
                        Write-Host "  Analysis confidence: $($analysis.Confidence)%" -ForegroundColor Gray
                    }
                    
                    # Make decision if enabled
                    if ($EnableDecisionMaking) {
                        $decision = Invoke-AutonomousDecisionMaking -ResponseFile $file.FullName
                        if ($decision) {
                            $OrchestrationResults.DecisionsMade++
                            Write-Host "  Decision made: $($decision.Action)" -ForegroundColor Yellow
                            
                            # Execute
                            $result = Invoke-DecisionExecution -Decision $decision
                            if ($result.Success) {
                                $OrchestrationResults.ActionsExecuted++
                                Write-Host "  Action executed successfully" -ForegroundColor Green
                            }
                        }
                    }
                }
            }
            catch {
                Write-Host "  ERROR: $_" -ForegroundColor Red
                $OrchestrationResults.Errors += $_
            }
        }
        
        $OrchestrationResults.MonitoringCycles = 1
        return $OrchestrationResults
    }
    catch {
        Write-Host "ERROR in Invoke-SingleExecutionCycle: $_" -ForegroundColor Red
        $OrchestrationResults.Errors += $_
        return $OrchestrationResults
    }
}

function Process-SignalFile {
    <#
    .SYNOPSIS
        Processes a signal file and handles both test completion signals and response signals
    #>
    [CmdletBinding()]
    param(
        [string]$SignalFile
    )
    
    try {
        Write-Host "[TRACE] Process-SignalFile: Starting processing of $SignalFile" -ForegroundColor DarkMagenta
        
        if (-not (Test-Path $SignalFile)) {
            throw "Signal file not found: $SignalFile"
        }
        
        $signalName = Split-Path $SignalFile -Leaf
        Write-Host "[TRACE] Process-SignalFile: Signal file name: $signalName" -ForegroundColor DarkMagenta
        
        # Check if this is a TestComplete signal (these are standalone and don't need JSON files)
        if ($signalName -match '^TestComplete_') {
            Write-Host "[TRACE] Process-SignalFile: Detected TestComplete signal - processing independently" -ForegroundColor DarkMagenta
            
            # Read signal data
            $signalContent = Get-Content $SignalFile -Raw
            Write-Host "[TRACE] Process-SignalFile: Signal content: $signalContent" -ForegroundColor DarkMagenta
            
            try {
                $signalData = $signalContent | ConvertFrom-Json
                Write-Host "[TRACE] Process-SignalFile: Parsed signal data successfully" -ForegroundColor DarkMagenta
                Write-Host "[TRACE] Test Path: $($signalData.TestPath)" -ForegroundColor DarkMagenta
                Write-Host "[TRACE] Result File: $($signalData.ResultFile)" -ForegroundColor DarkMagenta
                Write-Host "[TRACE] Exit Code: $($signalData.ExitCode)" -ForegroundColor DarkMagenta
                Write-Host "[TRACE] Status: $($signalData.Status)" -ForegroundColor $(if($signalData.Status -eq "SUCCESS"){"Green"}else{"Red"})
                if ($signalData.ErrorDetails) {
                    Write-Host "[TRACE] Error Details: $($signalData.ErrorDetails)" -ForegroundColor Red
                }
                
                # Process test completion
                Write-Host "[DEBUG] Processing TestComplete signal - submitting results to Claude" -ForegroundColor Cyan
                
                if ($signalData.ResultFile -and (Test-Path $signalData.ResultFile)) {
                    $resultContent = Get-Content $signalData.ResultFile -Raw
                    Write-Host "[TRACE] Result file content length: $($resultContent.Length) characters" -ForegroundColor DarkMagenta
                    
                    # Build prompt with boilerplate
                    $boilerplatePath = "C:\UnityProjects\Sound-and-Shoal\Unity-Claude-Automation\CLAUDE_PROMPT_DIRECTIVES_COMPLETE_UCA.txt"
                    $boilerplate = if (Test-Path $boilerplatePath) { 
                        Get-Content $boilerplatePath -Raw 
                    } else { 
                        "Please review the following test results and provide analysis." 
                    }
                    
                    # Build appropriate prompt based on success/failure
                    if ($signalData.Status -eq "SUCCESS") {
                        $promptText = @"
$boilerplate

***END OF BOILERPLATE***

//Prompt type, additional instructions, and parameters below:
Prompt-type: Testing
Test Results File: $($signalData.ResultFile)
Test Path: $($signalData.TestPath)
Exit Code: $($signalData.ExitCode)
Status: $($signalData.Status)

The test has been executed successfully. Please review the test results:

$resultContent
"@
                    } else {
                        # Test failed - include error details
                        $promptText = @"
$boilerplate

***END OF BOILERPLATE***

//Prompt type, additional instructions, and parameters below:
Prompt-type: Testing
Test Results File: $($signalData.ResultFile)
Test Path: $($signalData.TestPath)
Exit Code: $($signalData.ExitCode)
Status: $($signalData.Status)
Error Details: $($signalData.ErrorDetails)

The test FAILED with errors. Please review the test results and error details to diagnose the issue:

$resultContent

ERROR SUMMARY:
$($signalData.ErrorDetails)

Please analyze the failure and suggest fixes.
"@
                    }
                    
                    Write-Host "[TRACE] Built prompt text, length: $($promptText.Length) characters" -ForegroundColor DarkMagenta
                    
                    # Submit to Claude
                    try {
                        $submissionResult = Submit-ToClaudeViaTypeKeys -PromptText $promptText
                        if ($submissionResult) {
                            Write-Host "[DEBUG] Successfully submitted TestComplete results to Claude" -ForegroundColor Green
                        } else {
                            Write-Host "[ERROR] Failed to submit TestComplete results to Claude" -ForegroundColor Red
                        }
                    } catch {
                        Write-Host "[ERROR] Exception during TestComplete Claude submission: $_" -ForegroundColor Red
                    }
                } else {
                    Write-Host "[ERROR] TestComplete signal result file not found: $($signalData.ResultFile)" -ForegroundColor Red
                }
                
            } catch {
                Write-Host "[ERROR] Failed to parse TestComplete signal JSON: $_" -ForegroundColor Red
            }
            
            # Mark signal as processed
            $processedFile = "$SignalFile.processed"
            Move-Item -Path $SignalFile -Destination $processedFile -Force
            Write-Host "[TRACE] TestComplete signal marked as processed: $processedFile" -ForegroundColor DarkMagenta
            
            return $null  # TestComplete signals don't return JSON files
        }
        else {
            # Handle regular response signals (these need corresponding JSON files)
            Write-Host "[TRACE] Process-SignalFile: Regular response signal - looking for JSON file" -ForegroundColor DarkMagenta
            
            $jsonFile = $SignalFile -replace '\.signal$', '.json'
            Write-Host "[TRACE] Process-SignalFile: Expected JSON file: $jsonFile" -ForegroundColor DarkMagenta
            
            if (-not (Test-Path $jsonFile)) {
                Write-Host "[ERROR] Response file not found for signal: $jsonFile" -ForegroundColor Red
                throw "Response file not found: $jsonFile"
            }
            
            # Mark signal as processed
            $processedFile = "$SignalFile.processed"
            Move-Item -Path $SignalFile -Destination $processedFile -Force
            
            Write-Host "[TRACE] Regular signal processed: $(Split-Path $SignalFile -Leaf)" -ForegroundColor DarkMagenta
            return $jsonFile
        }
    }
    catch {
        Write-Host "[ERROR] in Process-SignalFile: $_" -ForegroundColor Red
        return $null
    }
}

# Functions are available directly when dot-sourced
# No Export-ModuleMember needed for dot-sourcing