function Invoke-AutonomousExecutionLoop {
    <#
    .SYNOPSIS
        Executes the main autonomous execution loop with decision making
        
    .DESCRIPTION
        Manages the autonomous execution cycle including prompt generation,
        submission, response processing, and action execution
        
    .PARAMETER MaxIterations
        Maximum number of execution iterations (default: 10)
        
    .PARAMETER DelayBetweenIterations
        Delay in seconds between iterations (default: 5)
        
    .PARAMETER StopOnError
        Whether to stop execution on first error
        
    .PARAMETER ResponseDirectory
        Directory to monitor for Claude responses (default: ./ClaudeResponses/Autonomous/)
        
    .OUTPUTS
        PSCustomObject with execution loop results and statistics
        
    .EXAMPLE
        $results = Invoke-AutonomousExecutionLoop -MaxIterations 5 -DelayBetweenIterations 10
    #>
    [CmdletBinding()]
    param(
        [int]$MaxIterations = 10,
        [int]$DelayBetweenIterations = 5,
        [switch]$StopOnError,
        [string]$ResponseDirectory = ".\ClaudeResponses\Autonomous\"
    )
    
    try {
        Write-Host "Starting autonomous execution loop..." -ForegroundColor Cyan
        Write-Host "  Max Iterations: $MaxIterations" -ForegroundColor Gray
        Write-Host "  Delay Between Iterations: $DelayBetweenIterations seconds" -ForegroundColor Gray
        Write-Host "  Response Directory: $ResponseDirectory" -ForegroundColor Gray
        Write-Host "  Stop On Error: $StopOnError" -ForegroundColor Gray
        
        $executionResults = [PSCustomObject]@{
            StartTime = Get-Date
            EndTime = $null
            TotalIterations = 0
            SuccessfulIterations = 0
            FailedIterations = 0
            ProcessedResponses = 0
            ExecutedActions = 0
            Errors = @()
            IterationResults = @()
        }
        
        # Ensure response directory exists
        if (-not (Test-Path $ResponseDirectory)) {
            New-Item -Path $ResponseDirectory -ItemType Directory -Force | Out-Null
            Write-Host "  Created response directory: $ResponseDirectory" -ForegroundColor Gray
        }
        
        # Main execution loop
        for ($iteration = 1; $iteration -le $MaxIterations; $iteration++) {
            Write-Host ""
            Write-Host "=== ITERATION $iteration/$MaxIterations ===" -ForegroundColor Cyan
            
            $iterationStart = Get-Date
            $iterationResult = [PSCustomObject]@{
                Iteration = $iteration
                StartTime = $iterationStart
                EndTime = $null
                Success = $false
                ActionsExecuted = 0
                ResponsesProcessed = 0
                Error = $null
            }
            
            try {
                # Check for new response files
                $responseFiles = Get-ChildItem -Path $ResponseDirectory -Filter "*.json" | 
                                 Sort-Object LastWriteTime -Descending |
                                 Select-Object -First 3
                
                Write-Host "  Found $($responseFiles.Count) response files to process" -ForegroundColor Gray
                
                if ($responseFiles.Count -eq 0) {
                    Write-Host "  No response files found - generating autonomous prompt" -ForegroundColor Yellow
                    
                    # Generate autonomous prompt
                    $prompt = New-AutonomousPrompt -BasePrompt "Continue autonomous operations and provide status update" -IncludeDirective -Priority "Medium"
                    
                    # Submit prompt
                    $submissionSuccess = Submit-ToClaudeViaTypeKeys -PromptText $prompt
                    
                    if ($submissionSuccess) {
                        Write-Host "  Prompt submitted successfully - waiting for response" -ForegroundColor Green
                        $iterationResult.Success = $true
                    } else {
                        Write-Host "  Prompt submission failed" -ForegroundColor Red
                        $iterationResult.Error = "Prompt submission failed"
                    }
                    
                } else {
                    # Process existing response files
                    $hasActionableRecommendations = $false
                    $recommendationPrompt = ""
                    
                    foreach ($responseFile in $responseFiles) {
                        Write-Host "  Processing response file: $($responseFile.Name)" -ForegroundColor Gray
                        
                        $response = Process-ResponseFile -ResponseFilePath $responseFile.FullName -ExtractRecommendations -ValidateStructure
                        $iterationResult.ResponsesProcessed++
                        
                        # Check if this response has actionable recommendations
                        if ($response.Recommendations -and $response.Recommendations.Count -gt 0) {
                            Write-Host "    Found $($response.Recommendations.Count) recommendations" -ForegroundColor Yellow
                            $hasActionableRecommendations = $true
                            
                            # Build prompt from recommendations
                            foreach ($rec in $response.Recommendations) {
                                if ($rec.Text) {
                                    $recommendationPrompt = $rec.Text
                                    break # Use first recommendation as prompt
                                }
                            }
                        }
                        
                        # Execute recommended actions
                        foreach ($action in $response.NextActions) {
                            Write-Host "    Executing action: $($action.Type) $($action.Target)" -ForegroundColor Yellow
                            
                            # Here you would implement actual action execution
                            # For now, just log the action
                            $iterationResult.ActionsExecuted++
                        }
                    }
                    
                    # If we found actionable recommendations, submit them to Claude
                    if ($hasActionableRecommendations -and $recommendationPrompt) {
                        Write-Host "  Submitting recommendation to Claude..." -ForegroundColor Cyan
                        
                        # Generate autonomous prompt from recommendation
                        $prompt = if (Get-Command New-AutonomousPrompt -ErrorAction SilentlyContinue) {
                            New-AutonomousPrompt -BasePrompt $recommendationPrompt -IncludeDirective -Priority "High"
                        } else {
                            $recommendationPrompt
                        }
                        
                        # Submit prompt
                        $submissionSuccess = Submit-ToClaudeViaTypeKeys -PromptText $prompt
                        
                        if ($submissionSuccess) {
                            Write-Host "  Recommendation submitted successfully" -ForegroundColor Green
                            $iterationResult.Success = $true
                        } else {
                            Write-Host "  Recommendation submission failed" -ForegroundColor Red
                            $iterationResult.Error = "Recommendation submission failed"
                        }
                    } else {
                        Write-Host "  No actionable recommendations to submit" -ForegroundColor Gray
                        $iterationResult.Success = $true
                    }
                }
                
                $executionResults.SuccessfulIterations++
                
            } catch {
                Write-Host "  ERROR in iteration $iteration`: $_" -ForegroundColor Red
                $iterationResult.Error = $_.Exception.Message
                $executionResults.FailedIterations++
                $executionResults.Errors += "Iteration $iteration`: $($_.Exception.Message)"
                
                if ($StopOnError) {
                    Write-Host "  Stopping execution loop due to error" -ForegroundColor Red
                    break
                }
            }
            
            $iterationResult.EndTime = Get-Date
            $executionResults.IterationResults += $iterationResult
            $executionResults.TotalIterations++
            $executionResults.ProcessedResponses += $iterationResult.ResponsesProcessed
            $executionResults.ExecutedActions += $iterationResult.ActionsExecuted
            
            # Delay before next iteration
            if ($iteration -lt $MaxIterations) {
                Write-Host "  Waiting $DelayBetweenIterations seconds before next iteration..." -ForegroundColor Gray
                Start-Sleep -Seconds $DelayBetweenIterations
            }
        }
        
        $executionResults.EndTime = Get-Date
        
        Write-Host ""
        Write-Host "=== EXECUTION LOOP COMPLETE ===" -ForegroundColor Green
        Write-Host "  Total Iterations: $($executionResults.TotalIterations)" -ForegroundColor Gray
        Write-Host "  Successful: $($executionResults.SuccessfulIterations)" -ForegroundColor Gray
        Write-Host "  Failed: $($executionResults.FailedIterations)" -ForegroundColor Gray
        Write-Host "  Responses Processed: $($executionResults.ProcessedResponses)" -ForegroundColor Gray
        Write-Host "  Actions Executed: $($executionResults.ExecutedActions)" -ForegroundColor Gray
        
        return $executionResults
        
    } catch {
        Write-Host "Error in autonomous execution loop: $_" -ForegroundColor Red
        throw
    }
}