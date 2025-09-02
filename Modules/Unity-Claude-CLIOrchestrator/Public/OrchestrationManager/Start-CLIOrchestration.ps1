function Start-CLIOrchestration {
    <#
    .SYNOPSIS
        Starts the main CLI orchestration system with autonomous capabilities
        
    .DESCRIPTION
        Initializes and runs the complete CLI orchestration system including
        autonomous monitoring, decision making, and response processing
        
    .PARAMETER AutonomousMode
        Whether to enable autonomous operation mode
        
    .PARAMETER MonitoringInterval
        Interval in seconds for monitoring checks (default: 30)
        
    .PARAMETER MaxExecutionTime
        Maximum execution time in minutes before automatic shutdown (default: 60)
        
    .PARAMETER EnableResponseAnalysis
        Whether to enable comprehensive response analysis
        
    .PARAMETER EnableDecisionMaking
        Whether to enable autonomous decision making
        
    .OUTPUTS
        PSCustomObject with orchestration results and statistics
        
    .EXAMPLE
        $results = Start-CLIOrchestration -AutonomousMode -MonitoringInterval 60 -MaxExecutionTime 120
    #>
    [CmdletBinding()]
    param(
        [switch]$AutonomousMode,
        [int]$MonitoringInterval = 30,
        [int]$MaxExecutionTime = 60,
        [switch]$EnableResponseAnalysis,
        [switch]$EnableDecisionMaking
    )
    
    try {
        Write-Host ""
        Write-Host "=====================================================================" -ForegroundColor Cyan
        Write-Host "         Unity-Claude CLI Orchestration System v2.0" -ForegroundColor Cyan
        Write-Host "=====================================================================" -ForegroundColor Cyan
        Write-Host ""
        
        Write-Host "CONFIGURATION:" -ForegroundColor Yellow
        Write-Host "  Autonomous Mode: $AutonomousMode" -ForegroundColor Gray
        Write-Host "  Monitoring Interval: $MonitoringInterval seconds" -ForegroundColor Gray
        Write-Host "  Max Execution Time: $MaxExecutionTime minutes" -ForegroundColor Gray
        Write-Host "  Response Analysis: $EnableResponseAnalysis" -ForegroundColor Gray
        Write-Host "  Decision Making: $EnableDecisionMaking" -ForegroundColor Gray
        Write-Host ""
        
        $orchestrationResults = [PSCustomObject]@{
            StartTime = Get-Date
            EndTime = $null
            Mode = if ($AutonomousMode) { "Autonomous" } else { "Manual" }
            TotalRunTime = 0
            MonitoringCycles = 0
            ResponsesAnalyzed = 0
            DecisionsMade = 0
            ActionsExecuted = 0
            Errors = @()
            Status = "Running"
        }
        
        # Initialize components
        Write-Host "Initializing orchestration components..." -ForegroundColor Cyan
        
        # Verify Claude window is available
        $claudeWindow = Find-ClaudeWindow
        if (-not $claudeWindow) {
            throw "Claude Code CLI window not found. Please ensure Claude CLI is open and visible."
        }
        Write-Host "  Claude CLI window detected successfully" -ForegroundColor Green
        
        # Initialize response directory
        $responseDir = ".\ClaudeResponses\Autonomous"
        if (-not (Test-Path $responseDir)) {
            New-Item -ItemType Directory -Path $responseDir -Force | Out-Null
        }
        Write-Host "  Response directory initialized: $responseDir" -ForegroundColor Green
        
        # Start monitoring loop
        Write-Host "Starting orchestration monitoring..." -ForegroundColor Cyan
        $startTime = Get-Date
        $maxRunTime = New-TimeSpan -Minutes $MaxExecutionTime
        
        do {
            try {
                $orchestrationResults.MonitoringCycles++
                $currentTime = Get-Date
                $elapsedTime = $currentTime - $startTime
                
                Write-Host "`n--- Monitoring Cycle $($orchestrationResults.MonitoringCycles) ---" -ForegroundColor Yellow
                Write-Host "Runtime: $($elapsedTime.ToString('hh\:mm\:ss'))" -ForegroundColor Gray
                
                # Check for new responses if autonomous mode is enabled
                if ($AutonomousMode) {
                    $responseFiles = Get-ChildItem -Path $responseDir -Filter "*.json" -ErrorAction SilentlyContinue |
                                   Where-Object { $_.LastWriteTime -gt $startTime } |
                                   Sort-Object LastWriteTime
                    
                    if ($responseFiles) {
                        Write-Host "Found $($responseFiles.Count) new response file(s)" -ForegroundColor Green
                        
                        foreach ($file in $responseFiles) {
                            try {
                                $orchestrationResults.ResponsesAnalyzed++
                                Write-Host "Processing: $($file.Name)" -ForegroundColor Cyan
                                
                                if ($EnableResponseAnalysis) {
                                    $analysisResult = Invoke-ComprehensiveResponseAnalysis -ResponseFile $file.FullName
                                    Write-Host "  Analysis completed: $($analysisResult.Status)" -ForegroundColor Green
                                }
                                
                                if ($EnableDecisionMaking) {
                                    $decisionResult = Invoke-AutonomousDecisionMaking -ResponseFile $file.FullName
                                    $orchestrationResults.DecisionsMade++
                                    Write-Host "  Decision: $($decisionResult.Decision)" -ForegroundColor Yellow
                                    
                                    # Execute decision if it requires action
                                    if ($decisionResult.Decision -in @("EXECUTE", "CONTINUE", "INVESTIGATE", "EXECUTE_TEST", "FIX", "COMPILE")) {
                                        $executionResult = Invoke-DecisionExecution -DecisionResult $decisionResult
                                        if ($executionResult.ExecutionStatus -eq "Success") {
                                            $orchestrationResults.ActionsExecuted++
                                            Write-Host "  Action executed successfully" -ForegroundColor Green
                                        } else {
                                            Write-Host "  Action execution failed: $($executionResult.Errors -join '; ')" -ForegroundColor Red
                                        }
                                    }
                                }
                                
                            } catch {
                                $orchestrationResults.Errors += "Error processing $($file.Name): $($_.Exception.Message)"
                                Write-Host "  Error: $($_.Exception.Message)" -ForegroundColor Red
                            }
                        }
                    } else {
                        Write-Host "No new responses to process" -ForegroundColor Gray
                    }
                    
                    # Check for test completion signal files
                    $signalFiles = Get-ChildItem -Path $responseDir -Filter "TestComplete_*.signal" -ErrorAction SilentlyContinue |
                                   Where-Object { $_.LastWriteTime -gt $startTime } |
                                   Sort-Object LastWriteTime
                    
                    if ($signalFiles) {
                        foreach ($signalFile in $signalFiles) {
                            try {
                                # Read the signal file
                                $signalData = Get-Content $signalFile.FullName -Raw | ConvertFrom-Json
                                
                                Write-Host "Test completed: $($signalData.TestPath)" -ForegroundColor Green
                                Write-Host "Test status: $($signalData.Status)" -ForegroundColor $(if($signalData.Status -eq "SUCCESS"){"Green"}else{"Red"})
                                
                                # Read test results
                                $testResults = if (Test-Path $signalData.ResultFile) {
                                    Get-Content $signalData.ResultFile -Raw
                                } else {
                                    "Test results file not found: $($signalData.ResultFile)"
                                }
                                
                                # Submit to Claude
                                $boilerplatePath = "C:\UnityProjects\Sound-and-Shoal\Unity-Claude-Automation\CLAUDE_PROMPT_DIRECTIVES_COMPLETE_UCA.txt"
                                $boilerplate = if (Test-Path $boilerplatePath) { 
                                    Get-Content $boilerplatePath -Raw 
                                } else { 
                                    "Please review the following test results and provide analysis." 
                                }
                                
                                $promptText = @"
$boilerplate

***END OF BOILERPLATE***

//Prompt type, additional instructions, and parameters below:
Prompt-type: Test Results
Test Path: $($signalData.TestPath)
Test Status: $($signalData.Status)
Exit Code: $($signalData.ExitCode)
Result File: $($signalData.ResultFile)
Execution Time: $($signalData.Timestamp)

Test Results:
=============
$testResults
"@
                                
                                try {
                                    $submissionResult = Submit-ToClaudeViaTypeKeys -PromptText $promptText
                                    if ($submissionResult) {
                                        Write-Host "Successfully submitted test results to Claude" -ForegroundColor Green
                                        $orchestrationResults.ActionsExecuted++
                                    } else {
                                        Write-Host "Failed to submit to Claude" -ForegroundColor Red
                                    }
                                } catch {
                                    Write-Host "Exception during Claude submission: $($_.Exception.Message)" -ForegroundColor Red
                                }
                                
                                # Archive the signal file
                                $archivePath = "$($signalFile.FullName).processed"
                                try {
                                    Move-Item -Path $signalFile.FullName -Destination $archivePath -Force
                                } catch {
                                    Write-Host "Warning: Failed to archive signal file: $($_.Exception.Message)" -ForegroundColor Yellow
                                }
                                
                            } catch {
                                Write-Warning "Error processing signal file: $($_.Exception.Message)"
                            }
                        }
                    }
                }
                
                # Display current status
                Write-Host "Status: Responses: $($orchestrationResults.ResponsesAnalyzed), Decisions: $($orchestrationResults.DecisionsMade), Actions: $($orchestrationResults.ActionsExecuted)" -ForegroundColor Cyan
                
                # Check for exit conditions
                if ($elapsedTime -gt $maxRunTime) {
                    Write-Host "Maximum execution time reached. Shutting down..." -ForegroundColor Yellow
                    break
                }
                
                # Wait for next cycle
                Start-Sleep -Seconds $MonitoringInterval
                
            } catch {
                $orchestrationResults.Errors += "Monitoring cycle error: $($_.Exception.Message)"
                Write-Host "Monitoring cycle error: $($_.Exception.Message)" -ForegroundColor Red
                Start-Sleep -Seconds 5  # Brief pause before retrying
            }
            
        } while ($true)
        
        # Finalize results
        $orchestrationResults.EndTime = Get-Date
        $orchestrationResults.TotalRunTime = ($orchestrationResults.EndTime - $orchestrationResults.StartTime).TotalMinutes
        $orchestrationResults.Status = "Completed"
        
        Write-Host "`n=====================================================================" -ForegroundColor Cyan
        Write-Host "         CLI Orchestration Session Complete" -ForegroundColor Cyan
        Write-Host "=====================================================================" -ForegroundColor Cyan
        Write-Host "Runtime: $($orchestrationResults.TotalRunTime.ToString('F1')) minutes" -ForegroundColor Gray
        Write-Host "Cycles: $($orchestrationResults.MonitoringCycles)" -ForegroundColor Gray
        Write-Host "Responses Analyzed: $($orchestrationResults.ResponsesAnalyzed)" -ForegroundColor Gray
        Write-Host "Decisions Made: $($orchestrationResults.DecisionsMade)" -ForegroundColor Gray
        Write-Host "Actions Executed: $($orchestrationResults.ActionsExecuted)" -ForegroundColor Gray
        Write-Host "Errors: $($orchestrationResults.Errors.Count)" -ForegroundColor Gray
        
        if ($orchestrationResults.Errors.Count -gt 0) {
            Write-Host "`nErrors encountered:" -ForegroundColor Red
            $orchestrationResults.Errors | ForEach-Object { Write-Host "  $_" -ForegroundColor Red }
        }
        
        return $orchestrationResults
    } catch {
        Write-Host "CRITICAL ERROR: CLI orchestration failed: $($_.Exception.Message)" -ForegroundColor Red
        Write-Host "Press Enter to close this window..." -ForegroundColor Yellow
        Read-Host
        throw
    }
}