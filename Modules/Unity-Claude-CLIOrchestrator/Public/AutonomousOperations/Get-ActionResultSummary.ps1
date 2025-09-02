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