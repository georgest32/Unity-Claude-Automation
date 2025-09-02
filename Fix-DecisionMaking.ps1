# Fix the decision-making function to actually submit recommendations
# This patches Invoke-AutonomousDecisionMaking to process and submit recommendations

Write-Host "Fixing Invoke-AutonomousDecisionMaking in OrchestrationManager.psm1..." -ForegroundColor Yellow

$modulePath = "C:\UnityProjects\Sound-and-Shoal\Unity-Claude-Automation\Modules\Unity-Claude-CLIOrchestrator\Core\OrchestrationManager.psm1"

# Read the current content
$content = Get-Content $modulePath -Raw

# Find the section after response analysis where we should add submission logic
$insertPoint = '$responseAnalysis = Invoke-ComprehensiveResponseAnalysis -AnalysisDepth "Basic"'

# Add recommendation submission logic
$submissionCode = @'
        $responseAnalysis = Invoke-ComprehensiveResponseAnalysis -AnalysisDepth "Basic"
        
        # Process recommendations from response files
        if ($responseAnalysis.TotalRecommendations -gt 0) {
            Write-Host "  Found $($responseAnalysis.TotalRecommendations) recommendations to process" -ForegroundColor Yellow
            
            # Get the most recent response files with recommendations
            $responseFiles = Get-ChildItem -Path ".\ClaudeResponses\Autonomous" -Filter "*.json" -File |
                Sort-Object LastWriteTime -Descending | Select-Object -First 10
            
            foreach ($responseFile in $responseFiles) {
                try {
                    $content = Get-Content $responseFile.FullName -Raw | ConvertFrom-Json
                    
                    # Check for RECOMMENDATION field
                    if ($content.response -and $content.response -match "RECOMMENDATION:") {
                        $recommendationText = $content.response
                        
                        Write-Host "  Submitting recommendation from $($responseFile.Name)..." -ForegroundColor Cyan
                        Write-Host "    $recommendationText" -ForegroundColor Gray
                        
                        # Submit to Claude
                        if (Get-Command Submit-ToClaudeViaTypeKeys -ErrorAction SilentlyContinue) {
                            $submissionResult = Submit-ToClaudeViaTypeKeys -PromptText $recommendationText
                            
                            if ($submissionResult) {
                                Write-Host "    Recommendation submitted successfully!" -ForegroundColor Green
                                $decisionResults.ActionsExecuted++
                                $decisionResults.ExecutedActions += @{
                                    Type = "RecommendationSubmission"
                                    Source = $responseFile.Name
                                    Text = $recommendationText
                                    Result = "Success"
                                    Timestamp = Get-Date
                                }
                                
                                # Only submit one recommendation per cycle
                                break
                            } else {
                                Write-Host "    Submission failed" -ForegroundColor Red
                            }
                        }
                    }
                } catch {
                    Write-Host "    Error processing file: $_" -ForegroundColor Red
                }
            }
        }
'@

# Replace the line with our enhanced version
$content = $content -replace [regex]::Escape($insertPoint), $submissionCode

# Save the updated file
$content | Set-Content $modulePath -Force

Write-Host "OrchestrationManager.psm1 has been updated with recommendation submission logic" -ForegroundColor Green
Write-Host ""
Write-Host "The CLIOrchestrator will now:" -ForegroundColor Yellow
Write-Host "  1. Check for recommendations in response files" -ForegroundColor Gray
Write-Host "  2. Extract RECOMMENDATION: text from JSON files" -ForegroundColor Gray
Write-Host "  3. Submit recommendations to Claude via TypeKeys" -ForegroundColor Gray
Write-Host "  4. Track submission results in decision logs" -ForegroundColor Gray
Write-Host ""
Write-Host "The running CLIOrchestrator should pick up the changes on the next cycle" -ForegroundColor Cyan