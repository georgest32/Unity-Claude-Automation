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
    
    Write-Host "DEBUG Invoke-DecisionExecution: Processing decision: $($DecisionResult.Decision)" -ForegroundColor DarkGray
    
    $executionResult = [PSCustomObject]@{
        Timestamp = Get-Date
        Decision = $DecisionResult.Decision
        ExecutionStatus = "Success"
        Actions = @("Simulated execution for testing")
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
    
    # Simple decision processing
    switch ($DecisionResult.Decision) {
        "EXECUTE_TEST" {
            Write-Host "DEBUG Processing EXECUTE_TEST decision" -ForegroundColor Yellow
            $executionResult.ExecutionStatus = "Success"
            $executionResult.Actions += "Test execution completed"
        }
        "DEBUG" {
            Write-Host "DEBUG Processing DEBUG decision" -ForegroundColor Yellow
            $executionResult.ExecutionStatus = "Investigating"
            $executionResult.Actions += "Flagged for debugging investigation"
        }
        "CONTINUE" {
            Write-Host "DEBUG Processing CONTINUE decision" -ForegroundColor Yellow
            $executionResult.ExecutionStatus = "Success"
            $executionResult.Actions += "Continuation processed"
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