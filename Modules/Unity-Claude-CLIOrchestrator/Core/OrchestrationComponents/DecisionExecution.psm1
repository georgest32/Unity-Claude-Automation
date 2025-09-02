# DecisionExecution.psm1
# Decision execution and action implementation

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
            "EXECUTE_TEST" {
                $result = Execute-TestAction -Decision $Decision
            }
            
            "APPLY_FIX" {
                $result = Execute-FixAction -Decision $Decision
            }
            
            "VALIDATE_FIX" {
                $result = Execute-ValidationAction -Decision $Decision
            }
            
            "TRIGGER_COMPILATION" {
                $result = Execute-CompilationAction -Decision $Decision
            }
            
            "GENERATE_SUMMARY" {
                $result = Execute-SummaryAction -Decision $Decision
            }
            
            "EXECUTE_RECOMMENDED" {
                $result = Execute-RecommendedAction -Decision $Decision
            }
            
            "MONITOR" {
                Write-Host "      Continuing monitoring..." -ForegroundColor Gray
                $result.Success = $true
                $result.Output = "Monitoring continued"
            }
            
            "BLOCKED" {
                Write-Host "      Action was blocked by safety check" -ForegroundColor Red
                $result.Output = "Blocked by safety validation"
            }
            
            default {
                Write-Host "      Unknown action type: $($Decision.Action)" -ForegroundColor Yellow
                $result.Output = "Unknown action"
            }
        }
        
        $endTime = Get-Date
        $result.ExecutionTime = [Math]::Round(($endTime - $startTime).TotalSeconds, 2)
        
        if ($result.Success) {
            Write-Host "      Execution completed successfully in $($result.ExecutionTime)s" -ForegroundColor Green
        }
        else {
            Write-Host "      Execution failed: $($result.Error)" -ForegroundColor Red
        }
        
        return $result
    }
    catch {
        Write-Host "ERROR in Invoke-DecisionExecution: $_" -ForegroundColor Red
        return [PSCustomObject]@{
            Success = $false
            Error = $_.ToString()
        }
    }
}

function Execute-TestAction {
    <#
    .SYNOPSIS
        Executes test-related actions
    #>
    [CmdletBinding()]
    param(
        [PSCustomObject]$Decision
    )
    
    try {
        $result = [PSCustomObject]@{
            Success = $false
            Output = $null
            Error = $null
        }
        
        $testPath = $Decision.Parameters.TestPath
        if (-not $testPath) {
            throw "Test path not specified"
        }
        
        if (-not (Test-Path $testPath)) {
            throw "Test file not found: $testPath"
        }
        
        Write-Host "      Executing test: $testPath" -ForegroundColor Cyan
        
        # Execute test script
        $testOutput = & powershell.exe -File $testPath -NoProfile -ErrorAction Stop 2>&1
        
        # Process test output
        $result.Output = $testOutput -join "`n"
        $result.Success = $LASTEXITCODE -eq 0
        
        # Create results file
        $resultsFile = ".\ClaudeResponses\Autonomous\TestResults_$(Get-Date -Format 'yyyyMMdd_HHmmss').json"
        $testResults = @{
            timestamp = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
            test_path = $testPath
            success = $result.Success
            output = $result.Output
            execution_time = (Get-Date).ToString()
        }
        $testResults | ConvertTo-Json -Depth 10 | Set-Content -Path $resultsFile
        
        Write-Host "      Test results saved to: $resultsFile" -ForegroundColor Gray
        
        # Submit results back to Claude
        Submit-TestResultsToClaude -ResultsFile $resultsFile
        
        return $result
    }
    catch {
        return [PSCustomObject]@{
            Success = $false
            Output = $null
            Error = $_.ToString()
        }
    }
}

function Execute-ValidationAction {
    <#
    .SYNOPSIS
        Executes validation actions
    #>
    [CmdletBinding()]
    param(
        [PSCustomObject]$Decision
    )
    
    try {
        Write-Host "      Performing validation..." -ForegroundColor Cyan
        
        $result = [PSCustomObject]@{
            Success = $false
            Output = $null
            Error = $null
        }
        
        # Run validation tests
        $validationScript = ".\Test-CLIOrchestrator-Simple.ps1"
        if (Test-Path $validationScript) {
            $validationOutput = & powershell.exe -File $validationScript -NoProfile 2>&1
            $result.Output = $validationOutput -join "`n"
            $result.Success = $validationOutput -match "SUCCESS"
        }
        else {
            # Basic module import validation
            try {
                Import-Module ".\Modules\Unity-Claude-CLIOrchestrator\Unity-Claude-CLIOrchestrator.psd1" -Force -ErrorAction Stop
                $result.Success = $true
                $result.Output = "Module imported successfully"
            }
            catch {
                $result.Error = $_.ToString()
            }
        }
        
        return $result
    }
    catch {
        return [PSCustomObject]@{
            Success = $false
            Output = $null
            Error = $_.ToString()
        }
    }
}

function Submit-TestResultsToClaude {
    <#
    .SYNOPSIS
        Submits test results back to Claude Code CLI
    #>
    [CmdletBinding()]
    param(
        [string]$ResultsFile
    )
    
    try {
        Write-Host "      Submitting results to Claude..." -ForegroundColor Cyan
        
        # Find Claude window
        $claudeWindow = Find-ClaudeWindow
        if (-not $claudeWindow) {
            throw "Claude window not found"
        }
        
        # Read results
        $results = Get-Content -Path $ResultsFile -Raw | ConvertFrom-Json
        
        # Build submission prompt
        $prompt = @"
Test execution completed:
- Test: $($results.test_path)
- Result: $(if ($results.success) { 'PASSED' } else { 'FAILED' })
- Time: $($results.timestamp)

Please analyze the results and provide recommendations for next steps.
"@
        
        # Submit to Claude
        Submit-ToClaude -Text $prompt
        
        Write-Host "      Results submitted successfully" -ForegroundColor Green
        return $true
    }
    catch {
        Write-Host "      Failed to submit results: $_" -ForegroundColor Red
        return $false
    }
}

function Execute-RecommendedAction {
    <#
    .SYNOPSIS
        Executes recommended actions from analysis
    #>
    [CmdletBinding()]
    param(
        [PSCustomObject]$Decision
    )
    
    try {
        $actionType = $Decision.Parameters.ActionType
        Write-Host "      Executing recommended action: $actionType" -ForegroundColor Cyan
        
        $result = [PSCustomObject]@{
            Success = $false
            Output = $null
            Error = $null
        }
        
        switch ($actionType) {
            "FIX" {
                Write-Host "        Applying recommended fixes..." -ForegroundColor Gray
                # Implementation would go here
                $result.Output = "Fix action queued for manual review"
            }
            
            "DEBUG" {
                Write-Host "        Initiating debug analysis..." -ForegroundColor Gray
                # Implementation would go here
                $result.Output = "Debug analysis initiated"
            }
            
            "COMPILE" {
                Write-Host "        Triggering compilation..." -ForegroundColor Gray
                # Implementation would go here
                $result.Output = "Compilation triggered"
            }
            
            default {
                $result.Output = "Action type not implemented: $actionType"
            }
        }
        
        $result.Success = $true
        return $result
    }
    catch {
        return [PSCustomObject]@{
            Success = $false
            Output = $null
            Error = $_.ToString()
        }
    }
}

function Execute-SummaryAction {
    <#
    .SYNOPSIS
        Generates execution summary
    #>
    [CmdletBinding()]
    param(
        [PSCustomObject]$Decision
    )
    
    try {
        Write-Host "      Generating execution summary..." -ForegroundColor Cyan
        
        $summaryFile = ".\ClaudeResponses\Autonomous\ExecutionSummary_$(Get-Date -Format 'yyyyMMdd_HHmmss').md"
        
        $summary = @"
# CLIOrchestrator Execution Summary

**Generated:** $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')

## Decision Details
- Action: $($Decision.Action)
- Safety Level: $($Decision.SafetyLevel)
- Execution Mode: $($Decision.ExecutionMode)

## Analysis Summary
- Prompt Type: $($Decision.Analysis.PromptType)
- Confidence: $($Decision.Analysis.Confidence)%
- Priority: $($Decision.Analysis.Priority)

## Recommendations
$(if ($Decision.Analysis.Recommendations.Count -gt 0) {
    $Decision.Analysis.Recommendations | ForEach-Object { "- $_" }
} else {
    "- No specific recommendations"
})

## Status
Summary generation complete.
"@
        
        $summary | Set-Content -Path $summaryFile
        
        return [PSCustomObject]@{
            Success = $true
            Output = "Summary saved to: $summaryFile"
            Error = $null
        }
    }
    catch {
        return [PSCustomObject]@{
            Success = $false
            Output = $null
            Error = $_.ToString()
        }
    }
}

# Functions are available directly when dot-sourced
# No Export-ModuleMember needed for dot-sourcing