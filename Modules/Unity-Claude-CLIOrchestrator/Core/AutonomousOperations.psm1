#region AutonomousOperations Component
<#
.SYNOPSIS
    Unity-Claude CLI Orchestrator - Autonomous Operations Component
    
.DESCRIPTION
    Manages autonomous prompt generation, execution loops, and response processing.
    Provides intelligent automation capabilities for the CLI orchestrator.
    
.COMPONENT
    Part of Unity-Claude-CLIOrchestrator refactored architecture
    
.FUNCTIONS
    - New-AutonomousPrompt: Creates intelligent prompts with boilerplate integration
    - Get-ActionResultSummary: Summarizes action results for follow-up processing
    - Process-ResponseFile: Processes Claude response files with recommendation extraction
    - Invoke-AutonomousExecutionLoop: Main autonomous execution loop with decision making
#>
#endregion

# Private script variables
$script:SimpleDirective = " ================================================== CRITICAL: AT THE END OF YOUR RESPONSE, YOU MUST CREATE A RESPONSE .JSON FILE AT ./ClaudeResponses/Autonomous/ AND IN IT WRITE THE END OF YOUR RESPONSE, WHICH SHOULD END WITH: [RECOMMENDATION: CONTINUE]; [RECOMMENDATION: TEST <Name>]; [RECOMMENDATION: FIX <File>]; [RECOMMENDATION: COMPILE]; [RECOMMENDATION: RESTART <Module>]; [RECOMMENDATION: COMPLETE]; [RECOMMENDATION: ERROR <Description>]=================================================="

$script:BoilerplatePrompt = $null
try {
    $boilerplatePath = Join-Path $PSScriptRoot "..\Resources\BoilerplatePrompt.txt"
    if (Test-Path $boilerplatePath) {
        $script:BoilerplatePrompt = Get-Content -Path $boilerplatePath -Raw
    }
} catch {
    Write-Host "Warning: Could not load boilerplate prompt file: $_" -ForegroundColor Yellow
}

if (-not $script:BoilerplatePrompt) {
    # Fallback to simple directive if file not found
    $script:BoilerplatePrompt = "Please process the following recommendation and provide a detailed response."
}

function New-AutonomousPrompt {
    <#
    .SYNOPSIS
        Creates an intelligent autonomous prompt with boilerplate integration
        
    .DESCRIPTION
        Constructs prompts for autonomous operations, integrating boilerplate text,
        directives, and context-aware content generation
        
    .PARAMETER BasePrompt
        The base prompt text to enhance
        
    .PARAMETER Context
        Additional context information to include
        
    .PARAMETER IncludeDirective
        Whether to include the simple directive for response formatting
        
    .PARAMETER Priority
        Priority level for the prompt (High, Medium, Low)
        
    .OUTPUTS
        String - The constructed autonomous prompt
        
    .EXAMPLE
        $prompt = New-AutonomousPrompt -BasePrompt "Analyze test results" -Context $testResults -Priority "High"
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$BasePrompt,
        
        [string]$Context = "",
        [switch]$IncludeDirective,
        [ValidateSet("High", "Medium", "Low")]
        [string]$Priority = "Medium"
    )
    
    try {
        Write-Host "Creating autonomous prompt..." -ForegroundColor Cyan
        Write-Host "  Base Prompt Length: $($BasePrompt.Length) characters" -ForegroundColor Gray
        Write-Host "  Priority: $Priority" -ForegroundColor Gray
        
        $promptBuilder = @()
        
        # Add priority indicator
        $priorityIndicator = switch ($Priority) {
            "High" { "[HIGH PRIORITY TASK]" }
            "Medium" { "[STANDARD TASK]" }
            "Low" { "[LOW PRIORITY TASK]" }
        }
        $promptBuilder += $priorityIndicator
        $promptBuilder += ""
        
        # Add boilerplate if available
        if ($script:BoilerplatePrompt -and $script:BoilerplatePrompt.Trim()) {
            $promptBuilder += "SYSTEM CONTEXT:"
            $promptBuilder += $script:BoilerplatePrompt.Trim()
            $promptBuilder += ""
            $promptBuilder += "TASK REQUEST:"
        }
        
        # Add base prompt
        $promptBuilder += $BasePrompt.Trim()
        
        # Add context if provided
        if ($Context -and $Context.Trim()) {
            $promptBuilder += ""
            $promptBuilder += "ADDITIONAL CONTEXT:"
            $promptBuilder += $Context.Trim()
        }
        
        # Add directive if requested
        if ($IncludeDirective) {
            $promptBuilder += ""
            $promptBuilder += "RESPONSE REQUIREMENTS:"
            $promptBuilder += $script:SimpleDirective
        }
        
        # Add timestamp
        $promptBuilder += ""
        $promptBuilder += "Generated: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
        
        $finalPrompt = $promptBuilder -join "`n"
        
        Write-Host "  Final Prompt Length: $($finalPrompt.Length) characters" -ForegroundColor Gray
        Write-Host "Autonomous prompt created successfully" -ForegroundColor Green
        
        return $finalPrompt
        
    } catch {
        Write-Host "Error creating autonomous prompt: $_" -ForegroundColor Red
        throw
    }
}

function Get-ActionResultSummary {
    <#
    .SYNOPSIS
        Creates a summary of action results for autonomous decision making
        
    .DESCRIPTION
        Analyzes action execution results and creates structured summaries
        for follow-up processing and decision making
        
    .PARAMETER ActionResults
        Array of action result objects to summarize
        
    .PARAMETER IncludeDetails
        Whether to include detailed information in the summary
        
    .PARAMETER MaxDetailItems
        Maximum number of detailed items to include (default: 10)
        
    .OUTPUTS
        PSCustomObject with structured summary information
        
    .EXAMPLE
        $summary = Get-ActionResultSummary -ActionResults $results -IncludeDetails
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [array]$ActionResults,
        
        [switch]$IncludeDetails,
        [int]$MaxDetailItems = 10
    )
    
    try {
        Write-Host "Generating action result summary..." -ForegroundColor Cyan
        Write-Host "  Processing $($ActionResults.Count) action results" -ForegroundColor Gray
        
        $summary = [PSCustomObject]@{
            TotalActions = $ActionResults.Count
            SuccessfulActions = 0
            FailedActions = 0
            SuccessRate = 0.0
            AverageExecutionTime = 0.0
            TotalExecutionTime = 0.0
            ErrorTypes = @{}
            ActionTypes = @{}
            RecommendedFollowup = @()
            GeneratedAt = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        }
        
        if ($ActionResults.Count -eq 0) {
            Write-Host "  No action results to process" -ForegroundColor Yellow
            return $summary
        }
        
        # Analyze results
        $totalExecutionTime = 0
        $errorCounts = @{}
        $typeCounts = @{}
        
        foreach ($result in $ActionResults) {
            # Count success/failure
            if ($result.Success -eq $true) {
                $summary.SuccessfulActions++
            } else {
                $summary.FailedActions++
                
                # Categorize errors
                $errorType = if ($result.Error) {
                    $result.Error.GetType().Name
                } elseif ($result.StandardError) {
                    "ExecutionError"
                } else {
                    "UnknownError"
                }
                
                if (-not $errorCounts.ContainsKey($errorType)) {
                    $errorCounts[$errorType] = 0
                }
                $errorCounts[$errorType]++
            }
            
            # Track execution time
            if ($result.ExecutionTimeMs) {
                $totalExecutionTime += $result.ExecutionTimeMs
            }
            
            # Categorize action types
            $actionType = if ($result.ActionType) {
                $result.ActionType
            } elseif ($result.ScriptPath) {
                "ScriptExecution"
            } else {
                "Generic"
            }
            
            if (-not $typeCounts.ContainsKey($actionType)) {
                $typeCounts[$actionType] = 0
            }
            $typeCounts[$actionType]++
        }
        
        # Calculate metrics
        $summary.SuccessRate = if ($ActionResults.Count -gt 0) {
            [math]::Round(($summary.SuccessfulActions / $ActionResults.Count) * 100, 2)
        } else { 0.0 }
        
        $summary.TotalExecutionTime = $totalExecutionTime
        $summary.AverageExecutionTime = if ($ActionResults.Count -gt 0) {
            [math]::Round($totalExecutionTime / $ActionResults.Count, 2)
        } else { 0.0 }
        
        $summary.ErrorTypes = $errorCounts
        $summary.ActionTypes = $typeCounts
        
        # Generate recommendations
        $recommendations = @()
        
        if ($summary.SuccessRate -lt 50) {
            $recommendations += "CRITICAL: Low success rate ($($summary.SuccessRate)%) - investigate common failure patterns"
        } elseif ($summary.SuccessRate -lt 80) {
            $recommendations += "WARNING: Moderate success rate ($($summary.SuccessRate)%) - review failed actions"
        }
        
        if ($summary.AverageExecutionTime -gt 30000) { # 30 seconds
            $recommendations += "PERFORMANCE: High average execution time ($([math]::Round($summary.AverageExecutionTime/1000, 1))s) - optimize actions"
        }
        
        # Error-specific recommendations
        $topError = $errorCounts.GetEnumerator() | Sort-Object Value -Descending | Select-Object -First 1
        if ($topError -and $topError.Value -gt 2) {
            $recommendations += "ERROR PATTERN: $($topError.Name) occurred $($topError.Value) times - investigate root cause"
        }
        
        if ($recommendations.Count -eq 0) {
            $recommendations += "STATUS: Action execution appears healthy - continue monitoring"
        }
        
        $summary.RecommendedFollowup = $recommendations
        
        # Add detailed information if requested
        if ($IncludeDetails) {
            $summary | Add-Member -NotePropertyName 'DetailedResults' -NotePropertyValue @()
            
            $detailCount = [math]::Min($MaxDetailItems, $ActionResults.Count)
            for ($i = 0; $i -lt $detailCount; $i++) {
                $result = $ActionResults[$i]
                $summary.DetailedResults += [PSCustomObject]@{
                    Index = $i + 1
                    Success = $result.Success
                    ExecutionTimeMs = $result.ExecutionTimeMs
                    ActionType = if ($result.ActionType) { $result.ActionType } else { "Unknown" }
                    Summary = if ($result.Summary) {
                        $result.Summary.Substring(0, [math]::Min(100, $result.Summary.Length))
                    } else { "No summary available" }
                }
            }
        }
        
        Write-Host "  Success Rate: $($summary.SuccessRate)%" -ForegroundColor $(if ($summary.SuccessRate -ge 80) { 'Green' } elseif ($summary.SuccessRate -ge 50) { 'Yellow' } else { 'Red' })
        Write-Host "  Average Execution Time: $([math]::Round($summary.AverageExecutionTime, 2))ms" -ForegroundColor Gray
        Write-Host "  Recommendations: $($recommendations.Count)" -ForegroundColor Gray
        
        Write-Host "Action result summary generated successfully" -ForegroundColor Green
        
        return $summary
        
    } catch {
        Write-Host "Error generating action result summary: $_" -ForegroundColor Red
        throw
    }
}

function Process-ResponseFile {
    <#
    .SYNOPSIS
        Processes Claude response files and extracts recommendations
        
    .DESCRIPTION
        Analyzes response JSON files from Claude to extract recommendations,
        confidence levels, and next actions for autonomous processing
        
    .PARAMETER ResponseFilePath
        Path to the Claude response JSON file
        
    .PARAMETER ExtractRecommendations
        Whether to extract and parse recommendation text
        
    .PARAMETER ValidateStructure
        Whether to validate the JSON structure
        
    .OUTPUTS
        PSCustomObject with processed response information
        
    .EXAMPLE
        $response = Process-ResponseFile -ResponseFilePath ".\ClaudeResponses\response.json" -ExtractRecommendations
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$ResponseFilePath,
        
        [switch]$ExtractRecommendations,
        [switch]$ValidateStructure
    )
    
    try {
        Write-Host "Processing response file: $ResponseFilePath" -ForegroundColor Cyan
        Write-Host "[DEBUG] TESTING FLOW RESPONSE PROCESSING - Starting response file analysis" -ForegroundColor Magenta
        
        # Validate file exists
        if (-not (Test-Path $ResponseFilePath)) {
            throw "Response file not found: $ResponseFilePath"
        }
        
        # Read and parse JSON
        $jsonContent = Get-Content $ResponseFilePath -Raw -Encoding UTF8
        Write-Host "  File size: $($jsonContent.Length) characters" -ForegroundColor Gray
        Write-Host "[DEBUG] Raw JSON content (first 500 chars): $($jsonContent.Substring(0, [Math]::Min(500, $jsonContent.Length)))" -ForegroundColor DarkGray
        
        try {
            $responseData = $jsonContent | ConvertFrom-Json
        } catch {
            Write-Host "  Warning: Invalid JSON structure, attempting repair..." -ForegroundColor Yellow
            
            # Attempt basic JSON repair
            $repairedJson = $jsonContent
            
            # Fix common issues
            $repairedJson = $repairedJson -replace '(?<!\\)\\(?!["\\/bfnrt]|u[0-9a-fA-F]{4})', '\\\\'
            $repairedJson = $repairedJson -replace ',\s*}', '}'
            $repairedJson = $repairedJson -replace ',\s*]', ']'
            
            try {
                $responseData = $repairedJson | ConvertFrom-Json
                Write-Host "  JSON repair successful" -ForegroundColor Green
            } catch {
                throw "Unable to parse response file as JSON: $_"
            }
        }
        
        $processedResponse = [PSCustomObject]@{
            FilePath = $ResponseFilePath
            ProcessedAt = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
            IsValid = $true
            HasRecommendations = $false
            Recommendations = @()
            ConfidenceLevel = "Unknown"
            ResponseType = "Unknown"
            PromptType = "Unknown"
            TestDetails = $null
            NextActions = @()
            Metadata = @{}
        }
        
        # Extract basic metadata
        if ($responseData.timestamp) {
            $processedResponse.Metadata.Timestamp = $responseData.timestamp
        }
        
        # Enhanced prompt type extraction - check multiple fields
        if ($responseData.prompt_type) {
            $processedResponse.PromptType = $responseData.prompt_type
            $processedResponse.ResponseType = $responseData.prompt_type
            Write-Host "[DEBUG] Extracted prompt_type: $($responseData.prompt_type)" -ForegroundColor Green
        } elseif ($responseData."prompt-type") {
            $processedResponse.PromptType = $responseData."prompt-type"
            $processedResponse.ResponseType = $responseData."prompt-type"
            Write-Host "[DEBUG] Extracted prompt-type: $($responseData.'prompt-type')" -ForegroundColor Green
        }
        
        # Extract test details if present
        if ($responseData.details) {
            $processedResponse.TestDetails = $responseData.details
            Write-Host "[DEBUG] Extracted test details: $($responseData.details)" -ForegroundColor Green
        } elseif ($responseData.test_path) {
            $processedResponse.TestDetails = $responseData.test_path
            Write-Host "[DEBUG] Extracted test_path: $($responseData.test_path)" -ForegroundColor Green
        } elseif ($responseData."test-path") {
            $processedResponse.TestDetails = $responseData."test-path"
            Write-Host "[DEBUG] Extracted test-path: $($responseData.'test-path')" -ForegroundColor Green
        }
        
        # Validate structure if requested
        if ($ValidateStructure) {
            $requiredFields = @("timestamp", "RESPONSE")
            $missingFields = @()
            
            foreach ($field in $requiredFields) {
                if (-not ($responseData.PSObject.Properties.Name -contains $field)) {
                    $missingFields += $field
                }
            }
            
            if ($missingFields.Count -gt 0) {
                Write-Host "  Warning: Missing required fields: $($missingFields -join ', ')" -ForegroundColor Yellow
                $processedResponse.IsValid = $false
            }
        }
        
        # Extract recommendations if requested
        if ($ExtractRecommendations) {
            $recommendationText = ""
            
            # Look for RESPONSE field
            if ($responseData.RESPONSE) {
                $recommendationText = $responseData.RESPONSE
            } elseif ($responseData.recommendation) {
                $recommendationText = $responseData.recommendation
            } elseif ($responseData.response) {
                $recommendationText = $responseData.response
            }
            
            Write-Host "[DEBUG] TESTING FLOW - Recommendation text found: $($recommendationText.Length) characters" -ForegroundColor Magenta
            
            if ($recommendationText) {
                $processedResponse.HasRecommendations = $true
                
                # Parse recommendations using enhanced regex patterns
                $recommendationPatterns = @(
                    'RECOMMENDATION:\s*TEST\s*[-:]?\s*([^\n\r]+)',  # RECOMMENDATION: TEST - path
                    'RECOMMENDATION:\s*([^\n\r]+)',                  # RECOMMENDATION: anything
                    '\[RECOMMENDATION:\s*([^\]]+)\]',               # [RECOMMENDATION: ...]
                    'RECOMMEND:\s*([^\n\r]+)'                       # RECOMMEND: ...
                )
                
                foreach ($pattern in $recommendationPatterns) {
                    $matches = [regex]::Matches($recommendationText, $pattern, [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)
                    
                    foreach ($match in $matches) {
                        $recommendation = $match.Groups[1].Value.Trim()
                        if ($recommendation -and $recommendation.Length -gt 0) {
                            $processedResponse.Recommendations += [PSCustomObject]@{
                                Text = $recommendation
                                Type = if ($recommendation -match '^(TEST|COMPILE|FIX|RESTART|CONTINUE|COMPLETE|ERROR)') { $matches[1] } else { "UNKNOWN" }
                            }
                            Write-Host "[DEBUG] Found recommendation: $recommendation" -ForegroundColor Cyan
                        }
                    }
                }
                
                # Extract confidence indicators
                if ($recommendationText -match '(?i)confidence[:\s]*([0-9.]+)%?') {
                    $processedResponse.ConfidenceLevel = $matches[1] + "%"
                } elseif ($recommendationText -match '(?i)(high|medium|low)\s+confidence') {
                    $processedResponse.ConfidenceLevel = $matches[1]
                }
            }
        }
        
        # Generate next actions based on recommendations and prompt type
        Write-Host "[DEBUG] TESTING FLOW - Processing next actions for prompt type: $($processedResponse.PromptType)" -ForegroundColor Magenta
        
        # Special handling for Testing prompt type
        if ($processedResponse.PromptType -eq "Testing" -and $processedResponse.TestDetails) {
            Write-Host "[DEBUG] TESTING FLOW - Creating TEST action for: $($processedResponse.TestDetails)" -ForegroundColor Green
            $processedResponse.NextActions += [PSCustomObject]@{
                Type = "TEST"
                Target = $processedResponse.TestDetails
                Priority = "High"
                Source = "PromptType"
            }
        }
        
        # Process explicit recommendations
        foreach ($rec in $processedResponse.Recommendations) {
            $recText = if ($rec.Text) { $rec.Text } else { $rec }
            
            if ($recText -match '^(TEST|COMPILE|FIX|RESTART|CONTINUE|COMPLETE|ERROR)[\s:-]*(.*)') {
                $actionType = $matches[1]
                $actionTarget = $matches[2].Trim()
                
                # Special handling for TEST recommendations
                if ($actionType -eq "TEST" -and $actionTarget) {
                    Write-Host "[DEBUG] TESTING FLOW - Found TEST recommendation with target: $actionTarget" -ForegroundColor Green
                }
                
                $processedResponse.NextActions += [PSCustomObject]@{
                    Type = $actionType
                    Target = $actionTarget
                    Priority = switch ($actionType) {
                        "ERROR" { "High" }
                        "FIX" { "High" }
                        "TEST" { "High" }  # Changed TEST to High priority
                        "COMPILE" { "Medium" }
                        "RESTART" { "Low" }
                        "CONTINUE" { "Low" }
                        "COMPLETE" { "Low" }
                        default { "Medium" }
                    }
                    Source = "Recommendation"
                }
            }
        }
        
        Write-Host "  Recommendations found: $($processedResponse.Recommendations.Count)" -ForegroundColor Gray
        Write-Host "  Next actions identified: $($processedResponse.NextActions.Count)" -ForegroundColor Gray
        Write-Host "  Confidence level: $($processedResponse.ConfidenceLevel)" -ForegroundColor Gray
        
        Write-Host "Response file processed successfully" -ForegroundColor Green
        
        return $processedResponse
        
    } catch {
        Write-Host "Error processing response file: $_" -ForegroundColor Red
        throw
    }
}

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

# Export functions
Export-ModuleMember -Function @(
    'New-AutonomousPrompt',
    'Get-ActionResultSummary', 
    'Process-ResponseFile',
    'Invoke-AutonomousExecutionLoop'
)
# SIG # Begin signature block
# MIIFzgYJKoZIhvcNAQcCoIIFvzCCBbsCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCD58cxuoYLkTeN7
# e+imqj3TB8+b45zh2cKhpxXnHabNHKCCAzAwggMsMIICFKADAgECAhB1HRbZIqgr
# lUTwkh3hnGtFMA0GCSqGSIb3DQEBCwUAMC4xLDAqBgNVBAMMI1VuaXR5LUNsYXVk
# ZS1BdXRvbWF0aW9uLURldmVsb3BtZW50MB4XDTI1MDgyMDIxMTUxN1oXDTI2MDgy
# MDIxMzUxN1owLjEsMCoGA1UEAwwjVW5pdHktQ2xhdWRlLUF1dG9tYXRpb24tRGV2
# ZWxvcG1lbnQwggEiMA0GCSqGSIb3DQEBAQUAA4IBDwAwggEKAoIBAQCx4feqKdUQ
# 6GufY4umNzlM1Pi8aHUGR8HlfhIWFjsrRAxCxhieRlWbHe0Hw+pVBeX76X57e5Pu
# 4Kxxzu+MxMry0NJYf3yOLRTfhYskHBcLraXUCtrMwqnhPKvul6Sx6Lu8vilk605W
# ADJNifl3WFuexVCYJJM9G2mfuYIDN+rZ5zmpn0qCXum49bm629h+HyJ205Zrn9aB
# hIrA4i/JlrAh1kosWnCo62psl7ixbNVqFqwWEt+gAqSeIo4ChwkOQl7GHmk78Q5I
# oRneY4JTVlKzhdZEYhJGFXeoZml/5jcmUcox4UNYrKdokE7z8ZTmyowBOUNS+sHI
# G1TY5DZSb8vdAgMBAAGjRjBEMA4GA1UdDwEB/wQEAwIHgDATBgNVHSUEDDAKBggr
# BgEFBQcDAzAdBgNVHQ4EFgQUfDms7LrGVboHjmwlSyIjYD/JLQwwDQYJKoZIhvcN
# AQELBQADggEBABRMsfT7DzKy+aFi4HDg0MpxmbjQxOH1lzUzanaECRiyA0sn7+sA
# /4jvis1+qC5NjDGkLKOTCuDzIXnBWLCCBugukXbIO7g392ANqKdHjBHw1WlLvMVk
# 4WSmY096lzpvDd3jJApr/Alcp4KmRGNLnQ3vv+F9Uj58Uo1qjs85vt6fl9xe5lo3
# rFahNHL4ngjgyF8emNm7FItJeNtVe08PhFn0caOX0FTzXrZxGGO6Ov8tzf91j/qK
# QdBifG7Fx3FF7DifNqoBBo55a7q0anz30k8p+V0zllrLkgGXfOzXmA1L37Qmt3QB
# FCdJVigjQMuHcrJsWd8rg857Og0un91tfZIxggH0MIIB8AIBATBCMC4xLDAqBgNV
# BAMMI1VuaXR5LUNsYXVkZS1BdXRvbWF0aW9uLURldmVsb3BtZW50AhB1HRbZIqgr
# lUTwkh3hnGtFMA0GCWCGSAFlAwQCAQUAoIGEMBgGCisGAQQBgjcCAQwxCjAIoAKA
# AKECgAAwGQYJKoZIhvcNAQkDMQwGCisGAQQBgjcCAQQwHAYKKwYBBAGCNwIBCzEO
# MAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIBDLrwMz/43ZzXyVM1RC7a/a
# hur4cjemcSy43+TR9SLwMA0GCSqGSIb3DQEBAQUABIIBAHbt3Te/zPeR2hdRtzjq
# 77ApDDJFePuelK5FmJoNwbhQ6AKiKFDKOhhkmyNHR8xFQti+IXEANEpOCb0rYBdI
# LyeI6Djh3heoSqxGEKhX0AplKezmROpjAoS73rggygJI93cgL+flMajLTYC4JolP
# /YWaSTbt2IsZCaDzwaWJsNrWWXVuzeEyc1mPPm+ZDHXrVRIpwFQtTG3IRdM+ka+/
# gnCtzhLkrhm4vnRt4VzLXgMAio51NrmY9GZl440B+RsupVoOK2lAUkR9ZXU2za6S
# bL/eS5h7ADP6NZlPiDU3ofraTL5w238y0+Vv+uYlD2ujOpKPRvvcrxff2syeiQo7
# Zno=
# SIG # End signature block

