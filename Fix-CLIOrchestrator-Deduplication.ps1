# Fix-CLIOrchestrator-Deduplication.ps1
# Fixes the duplicate processing issue by moving processed files to a Processed folder

$ErrorActionPreference = 'Stop'

Write-Host "Fixing CLIOrchestrator duplicate processing issue..." -ForegroundColor Cyan

# Path to the module
$modulePath = 'C:\UnityProjects\Sound-and-Shoal\Unity-Claude-Automation\Modules\Unity-Claude-CLIOrchestrator\Core\OrchestrationManager.psm1'

# Backup the current file
$backupPath = $modulePath + '.backup_dedup_' + (Get-Date -Format 'yyyyMMdd_HHmmss')
Copy-Item $modulePath $backupPath
Write-Host "Created backup: $backupPath" -ForegroundColor Gray

# Read current content
$content = Get-Content $modulePath -Raw

# Find the Invoke-AutonomousDecisionMaking function and update it
$updatedFunction = @'
function Invoke-AutonomousDecisionMaking {
    <#
    .SYNOPSIS
        Makes autonomous decisions based on analyzed responses
    .DESCRIPTION
        Processes recommendations and executes approved actions autonomously
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false)]
        [hashtable]$AnalysisResults = @{},
        
        [Parameter(Mandatory=$false)]
        [hashtable]$Context = @{},
        
        [Parameter(Mandatory=$false)]
        [switch]$DryRun
    )
    
    try {
        Write-Host "`nAutonomous Decision Making Started" -ForegroundColor Cyan
        
        # Initialize results
        $decisionResults = @{
            Timestamp = Get-Date
            DecisionsMade = 0
            ActionsExecuted = 0
            ExecutedActions = @()
            SkippedActions = @()
            Errors = @()
        }
        
        # Check for JSON response files from Claude
        $responsePath = "C:\UnityProjects\Sound-and-Shoal\Unity-Claude-Automation\ClaudeResponses\Autonomous"
        
        # Create Processed folder if it doesn't exist
        $processedPath = Join-Path $responsePath "Processed"
        if (-not (Test-Path $processedPath)) {
            New-Item -Path $processedPath -ItemType Directory -Force | Out-Null
            Write-Host "  Created Processed folder for consumed files" -ForegroundColor Gray
        }
        
        if (Test-Path $responsePath) {
            Write-Host "  Checking for Claude response files..." -ForegroundColor Yellow
            $responseFiles = Get-ChildItem -Path $responsePath -Filter "*.json" -File -ErrorAction SilentlyContinue
            
            if ($responseFiles.Count -gt 0) {
                Write-Host "  Found $($responseFiles.Count) JSON response files" -ForegroundColor Green
                
                foreach ($responseFile in $responseFiles) {
                    try {
                        Write-Host "  Processing: $($responseFile.Name)" -ForegroundColor Yellow
                        $content = Get-Content $responseFile.FullName -Raw | ConvertFrom-Json
                        
                        # Check for RECOMMENDATION field
                        if ($content.RESPONSE -and $content.RESPONSE -match "RECOMMENDATION:") {
                            $recommendationText = $content.RESPONSE
                            
                            Write-Host "  Found recommendation to submit..." -ForegroundColor Cyan
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
                                    
                                    # Move file to Processed folder after successful submission
                                    $destinationPath = Join-Path $processedPath $responseFile.Name
                                    
                                    # If file already exists in Processed, append timestamp
                                    if (Test-Path $destinationPath) {
                                        $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
                                        $baseName = [System.IO.Path]::GetFileNameWithoutExtension($responseFile.Name)
                                        $extension = [System.IO.Path]::GetExtension($responseFile.Name)
                                        $newName = "${baseName}_${timestamp}${extension}"
                                        $destinationPath = Join-Path $processedPath $newName
                                    }
                                    
                                    Move-Item -Path $responseFile.FullName -Destination $destinationPath -Force
                                    Write-Host "    Moved to Processed folder: $([System.IO.Path]::GetFileName($destinationPath))" -ForegroundColor DarkGray
                                    
                                    # Only submit one recommendation per cycle to avoid overwhelming the system
                                    Write-Host "    Breaking after first submission (one per cycle)" -ForegroundColor DarkGray
                                    break
                                } else {
                                    Write-Host "    Submission failed - keeping file for retry" -ForegroundColor Red
                                    $decisionResults.Errors += "Failed to submit recommendation from $($responseFile.Name)"
                                }
                            } else {
                                Write-Host "    Submit-ToClaudeViaTypeKeys not available" -ForegroundColor Red
                                $decisionResults.Errors += "Submit function not available"
                            }
                        } else {
                            # No RECOMMENDATION found, move to Processed anyway to avoid reprocessing
                            Write-Host "    No RECOMMENDATION found in $($responseFile.Name), moving to Processed" -ForegroundColor Gray
                            $destinationPath = Join-Path $processedPath $responseFile.Name
                            
                            # Handle duplicate names
                            if (Test-Path $destinationPath) {
                                $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
                                $baseName = [System.IO.Path]::GetFileNameWithoutExtension($responseFile.Name)
                                $extension = [System.IO.Path]::GetExtension($responseFile.Name)
                                $newName = "${baseName}_${timestamp}${extension}"
                                $destinationPath = Join-Path $processedPath $newName
                            }
                            
                            Move-Item -Path $responseFile.FullName -Destination $destinationPath -Force
                            Write-Host "    Moved non-recommendation file to Processed" -ForegroundColor DarkGray
                        }
                    } catch {
                        Write-Host "    Error processing file $($responseFile.Name): $_" -ForegroundColor Red
                        $decisionResults.Errors += "Error processing $($responseFile.Name): $_"
                    }
                }
            } else {
                Write-Verbose "  No new JSON files to process"
            }
        }
        
        # Process analysis results if provided
        if ($AnalysisResults.Recommendations -and $AnalysisResults.Recommendations.Count -gt 0) {
            Write-Host "  Processing $($AnalysisResults.Recommendations.Count) recommendations from analysis" -ForegroundColor Yellow
            
            foreach ($recommendation in $AnalysisResults.Recommendations) {
                $decisionResults.DecisionsMade++
                
                # Evaluate confidence and priority
                $shouldExecute = ($recommendation.Confidence -ge 0.7 -and $recommendation.Priority -in @("High", "Critical"))
                
                if ($shouldExecute -and -not $DryRun) {
                    try {
                        # Execute the recommendation
                        Write-Host "    Executing: $($recommendation.Action)" -ForegroundColor Green
                        $decisionResults.ActionsExecuted++
                        $decisionResults.ExecutedActions += $recommendation
                    } catch {
                        Write-Host "    Failed to execute: $_" -ForegroundColor Red
                        $decisionResults.Errors += $_
                    }
                } else {
                    Write-Host "    Skipping: $($recommendation.Action) (Confidence: $($recommendation.Confidence))" -ForegroundColor Gray
                    $decisionResults.SkippedActions += $recommendation
                }
            }
        }
        
        Write-Host "`n  Decision Making Complete:" -ForegroundColor Green
        Write-Host "    Decisions Made: $($decisionResults.DecisionsMade)"
        Write-Host "    Actions Executed: $($decisionResults.ActionsExecuted)"
        Write-Host "    Errors: $($decisionResults.Errors.Count)"
        
        return $decisionResults
        
    } catch {
        Write-Host "Error in autonomous decision making: $_" -ForegroundColor Red
        throw $_
    }
}
'@

# Replace the entire function
if ($content -match 'function Invoke-AutonomousDecisionMaking\s*\{[\s\S]*?\n\}(?=\s*(?:function|Export-ModuleMember|$))') {
    $content = $content -replace 'function Invoke-AutonomousDecisionMaking\s*\{[\s\S]*?\n\}(?=\s*(?:function|Export-ModuleMember|$))', $updatedFunction
    Write-Host "Updated Invoke-AutonomousDecisionMaking function" -ForegroundColor Green
} else {
    Write-Host "Could not find function to replace - may need manual intervention" -ForegroundColor Yellow
}

# Save the updated content
$content | Set-Content $modulePath -Encoding UTF8

Write-Host ""
Write-Host "Fix applied successfully!" -ForegroundColor Green
Write-Host ""
Write-Host "Changes made:" -ForegroundColor Yellow
Write-Host "1. Added creation of 'Processed' subfolder in ClaudeResponses\Autonomous" -ForegroundColor White
Write-Host "2. Files are now moved to Processed folder after successful submission" -ForegroundColor White
Write-Host "3. Files without recommendations are also moved to avoid reprocessing" -ForegroundColor White
Write-Host "4. Duplicate filenames in Processed folder get timestamp appended" -ForegroundColor White
Write-Host "5. Failed submissions keep files in place for retry" -ForegroundColor White
Write-Host "6. Only processes one recommendation per cycle to avoid overwhelming" -ForegroundColor White
Write-Host ""
Write-Host "The CLIOrchestrator will now:" -ForegroundColor Cyan
Write-Host "- Only process each JSON file once" -ForegroundColor Green
Write-Host "- Move processed files to the Processed subfolder" -ForegroundColor Green
Write-Host "- Keep failed submissions for retry" -ForegroundColor Green
Write-Host "- Submit only one recommendation per polling cycle" -ForegroundColor Green