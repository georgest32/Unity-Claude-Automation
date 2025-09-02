# DecisionExecution-Fixed.psm1
# Simplified decision execution functions

function Invoke-DecisionExecution {
    <#
    .SYNOPSIS
        Executes autonomous decisions with safety checks
    #>
    [CmdletBinding()]
    param(
        [PSCustomObject]$Decision
    )
    
    try {
        Write-Host "    Executing decision: $($Decision.Action)" -ForegroundColor Cyan
        
        $result = [PSCustomObject]@{
            Timestamp = Get-Date
            Decision = $Decision
            Success = $false
            Output = $null
            Error = $null
            ExecutionTime = 0
        }
        
        $startTime = Get-Date
        
        # Check if confirmation is required
        if ($Decision.RequiresConfirmation) {
            Write-Host "      This action requires confirmation. Skipping in autonomous mode." -ForegroundColor Yellow
            $result.Output = "Confirmation required - skipped"
            return $result
        }
        
        # Execute based on action type
        switch ($Decision.Action) {
            "ExecuteTest" {
                $result = Execute-TestAction -Decision $Decision
            }
            
            "EXECUTE_TEST" {
                $result = Execute-TestAction -Decision $Decision
            }
            
            "ApplyFix" {
                Write-Host "      Fix action execution not implemented in test mode" -ForegroundColor Yellow
                $result.Success = $true
                $result.Output = "Fix action simulated"
            }
            
            "Escalate" {
                Write-Host "      Escalating to human operator..." -ForegroundColor Yellow
                $result.Success = $true
                $result.Output = "Decision escalated for human review"
            }
            
            default {
                Write-Host "      Unknown action type: $($Decision.Action)" -ForegroundColor Yellow
                $result.Output = "Unknown action type"
            }
        }
        
        $endTime = Get-Date
        $result.ExecutionTime = ($endTime - $startTime).TotalMilliseconds
        
        Write-Host "      Execution completed in $([math]::Round($result.ExecutionTime, 2))ms" -ForegroundColor Gray
        Write-Host "      Success: $($result.Success)" -ForegroundColor Gray
        
        return $result
    }
    catch {
        Write-Host "ERROR in Invoke-DecisionExecution: $_" -ForegroundColor Red
        return [PSCustomObject]@{
            Timestamp = Get-Date
            Decision = $Decision
            Success = $false
            Output = $null
            Error = $_.ToString()
            ExecutionTime = 0
        }
    }
}

function Execute-TestAction {
    <#
    .SYNOPSIS
        Executes test actions
    #>
    [CmdletBinding()]
    param(
        [PSCustomObject]$Decision
    )
    
    try {
        Write-Host "        Executing test action..." -ForegroundColor Cyan
        
        $result = [PSCustomObject]@{
            Success = $false
            Output = $null
            Error = $null
        }
        
        # Check if test path is provided
        if (-not $Decision.TestPath) {
            throw "No test path specified in decision"
        }
        
        $testPath = $Decision.TestPath
        Write-Host "        Test Path: $testPath" -ForegroundColor Gray
        
        # Basic safety check for test path
        if ($testPath -match "\.\./" -or ($testPath -match "^[C-Z]:" -and -not $testPath.StartsWith("C:\UnityProjects"))) {
            throw "Test path fails safety validation: $testPath"
        }
        
        # Check if test file exists (if absolute path)
        if ([System.IO.Path]::IsPathRooted($testPath)) {
            if (-not (Test-Path $testPath)) {
                throw "Test file not found: $testPath"
            }
        } else {
            # Relative path - construct full path
            $fullTestPath = Join-Path (Get-Location) $testPath
            if (-not (Test-Path $fullTestPath)) {
                Write-Host "        Test file not found at: $fullTestPath" -ForegroundColor Yellow
                Write-Host "        This would be executed in production mode" -ForegroundColor Yellow
            }
        }
        
        # In test mode, just simulate the execution
        Write-Host "        [SIMULATION] Would execute: $testPath" -ForegroundColor Green
        $result.Success = $true
        $result.Output = "Test execution simulated successfully"
        
        return $result
    }
    catch {
        Write-Host "ERROR in Execute-TestAction: $_" -ForegroundColor Red
        return [PSCustomObject]@{
            Success = $false
            Output = $null
            Error = $_.ToString()
        }
    }
}

Write-Verbose "DecisionExecution-Fixed module functions loaded successfully"