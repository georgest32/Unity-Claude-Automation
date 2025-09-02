# Fix for automatic submission of recommendations from processed response files
# The issue: CLIOrchestrator detects and processes JSON response files, but doesn't submit recommendations back to Claude
# This fix modifies the logic to submit recommendations when found

$modulePath = "C:\UnityProjects\Sound-and-Shoal\Unity-Claude-Automation\Modules\Unity-Claude-CLIOrchestrator\Core\AutonomousOperations.psm1"

Write-Host "Fixing automatic submission logic in AutonomousOperations.psm1..." -ForegroundColor Yellow

# Read the current module content
$content = Get-Content $modulePath -Raw

# Find the section that processes existing response files (lines 593-612)
# We need to add submission logic after processing recommendations

$oldBlock = @'
                } else {
                    # Process existing response files
                    foreach ($responseFile in $responseFiles) {
                        Write-Host "  Processing response file: $($responseFile.Name)" -ForegroundColor Gray
                        
                        $response = Process-ResponseFile -ResponseFilePath $responseFile.FullName -ExtractRecommendations -ValidateStructure
                        $iterationResult.ResponsesProcessed++
                        
                        # Execute recommended actions
                        foreach ($action in $response.NextActions) {
                            Write-Host "    Executing action: $($action.Type) $($action.Target)" -ForegroundColor Yellow
                            
                            # Here you would implement actual action execution
                            # For now, just log the action
                            $iterationResult.ActionsExecuted++
                        }
                    }
                    
                    $iterationResult.Success = $true
                }
'@

$newBlock = @'
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
'@

# Replace the old block with the new one
if ($content -match [regex]::Escape($oldBlock)) {
    $content = $content -replace [regex]::Escape($oldBlock), $newBlock
    
    # Save the modified content
    Set-Content -Path $modulePath -Value $content -Encoding UTF8 -Force
    
    Write-Host "Successfully updated AutonomousOperations.psm1" -ForegroundColor Green
    Write-Host "The module will now submit recommendations found in processed response files" -ForegroundColor Green
} else {
    Write-Host "Warning: Could not find the exact code block to replace" -ForegroundColor Yellow
    Write-Host "The module may have already been modified or has different formatting" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "To apply this fix:" -ForegroundColor Cyan
Write-Host "1. Stop the current CLIOrchestrator if running" -ForegroundColor White
Write-Host "2. Restart CLIOrchestrator with: .\Start-CLIOrchestrator-Fixed.ps1" -ForegroundColor White
Write-Host ""
Write-Host "The system will now automatically submit recommendations from JSON response files to Claude." -ForegroundColor Green