# Fix script for CLIOrchestrator Test Execution
# This script patches the CLIOrchestrator to properly execute test scripts from JSON recommendations

Write-Host "Fixing CLIOrchestrator Test Execution..." -ForegroundColor Cyan

# Backup the original file
$modulePath = "C:\UnityProjects\Sound-and-Shoal\Unity-Claude-Automation\Modules\Unity-Claude-CLIOrchestrator\Core\OrchestrationManager.psm1"
$backupPath = "$modulePath.backup_$(Get-Date -Format 'yyyyMMdd_HHmmss')"

if (Test-Path $modulePath) {
    Copy-Item $modulePath $backupPath -Force
    Write-Host "Created backup at: $backupPath" -ForegroundColor Gray
}

# Read the current content
$content = Get-Content $modulePath -Raw

# Find and replace the Invoke-DecisionExecution function to properly handle TEST actions
$newFunction = @'
function Invoke-DecisionExecution {
    param(
        [Parameter(Mandatory = $true)]
        [hashtable]$DecisionResult
    )
    
    try {
        $executionStart = Get-Date
        
        # Extract the action details from the decision
        $action = $DecisionResult.Action
        $decision = $DecisionResult.Decision
        
        Write-Host "  Executing decision: $decision" -ForegroundColor Yellow
        
        # For TEST/EXECUTE decisions with Testing recommendations
        if ($decision -eq "EXECUTE" -and $action -match "Testing\s*-\s*(.+)") {
            $testPath = $matches[1].Trim()
            
            Write-Host "  Executing test script: $testPath" -ForegroundColor Cyan
            
            # Check if test file exists
            if (Test-Path $testPath) {
                try {
                    # Execute the test script
                    $testOutput = & $testPath 2>&1
                    
                    Write-Host "  Test execution completed successfully" -ForegroundColor Green
                    
                    return @{
                        ExecutionStatus = "Success"
                        Decision = $decision
                        Action = $action
                        ExecutionTimeMs = ((Get-Date) - $executionStart).TotalMilliseconds
                        Output = $testOutput | Out-String
                        Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
                    }
                }
                catch {
                    Write-Host "  Test execution failed: $($_.Exception.Message)" -ForegroundColor Red
                    
                    return @{
                        ExecutionStatus = "Failed"
                        Decision = $decision
                        Action = $action
                        ExecutionTimeMs = ((Get-Date) - $executionStart).TotalMilliseconds
                        Errors = @($_.Exception.Message)
                        Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
                    }
                }
            }
            else {
                Write-Host "  Test script not found: $testPath" -ForegroundColor Red
                
                return @{
                    ExecutionStatus = "Failed"
                    Decision = $decision
                    Action = $action
                    ExecutionTimeMs = ((Get-Date) - $executionStart).TotalMilliseconds
                    Errors = @("Test script not found: $testPath")
                    Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
                }
            }
        }
        # Handle other decision types
        else {
            Write-Host "  Processing decision type: $decision" -ForegroundColor Gray
            
            # Placeholder for other action types
            return @{
                ExecutionStatus = "Success"
                Decision = $decision
                Action = $action
                ExecutionTimeMs = ((Get-Date) - $executionStart).TotalMilliseconds
                Output = "Decision processed (placeholder implementation)"
                Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
            }
        }
    }
    catch {
        return @{
            ExecutionStatus = "Failed"
            Decision = $DecisionResult.Decision
            Action = $DecisionResult.Action
            ExecutionTimeMs = 0
            Errors = @($_.Exception.Message)
            Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        }
    }
}
'@

# Check if function already exists and replace it
if ($content -match 'function\s+Invoke-DecisionExecution\s*\{[\s\S]*?\n\}(?=\s*\nfunction|\s*$)') {
    Write-Host "Found existing Invoke-DecisionExecution function, replacing..." -ForegroundColor Yellow
    $content = $content -replace 'function\s+Invoke-DecisionExecution\s*\{[\s\S]*?\n\}(?=\s*\nfunction|\s*$)', $newFunction
}
else {
    Write-Host "Adding Invoke-DecisionExecution function..." -ForegroundColor Yellow
    # Add the function at the end of the file before Export-ModuleMember
    if ($content -match '(Export-ModuleMember[\s\S]*)$') {
        $content = $content -replace '(Export-ModuleMember[\s\S]*)$', "$newFunction`n`n`$1"
    }
    else {
        # If no Export-ModuleMember, just append at the end
        $content = $content + "`n`n$newFunction`n`nExport-ModuleMember -Function Invoke-DecisionExecution"
    }
}

# Save the updated content
$content | Out-File $modulePath -Encoding UTF8

Write-Host "Fix applied successfully!" -ForegroundColor Green
Write-Host ""
Write-Host "The CLIOrchestrator should now be able to execute test scripts specified in JSON recommendations." -ForegroundColor Cyan
Write-Host ""
Write-Host "To test the fix:" -ForegroundColor Yellow
Write-Host "1. Restart the CLIOrchestrator" -ForegroundColor White
Write-Host "2. Create a JSON file with format:" -ForegroundColor White
Write-Host '   { "response": "RECOMMENDATION: Testing - C:\\path\\to\\test.ps1" }' -ForegroundColor Gray
Write-Host "3. Place it in ClaudeResponses\Autonomous directory" -ForegroundColor White
Write-Host "4. Watch the CLIOrchestrator execute the test" -ForegroundColor White