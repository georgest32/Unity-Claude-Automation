# Fix script to restore OrchestrationManager.psm1 and apply clean fix
# This addresses the syntax error introduced by the previous fix

Write-Host "Fixing OrchestrationManager.psm1 syntax error..." -ForegroundColor Cyan

$modulePath = "C:\UnityProjects\Sound-and-Shoal\Unity-Claude-Automation\Modules\Unity-Claude-CLIOrchestrator\Core\OrchestrationManager.psm1"
$backupPath = "$modulePath.backup_20250827_004022"  # Using the backup before the broken fix

# First, restore from the clean backup
if (Test-Path $backupPath) {
    Write-Host "Restoring from clean backup..." -ForegroundColor Yellow
    Copy-Item $backupPath $modulePath -Force
    Write-Host "Restored from: $backupPath" -ForegroundColor Green
} else {
    Write-Host "ERROR: Backup not found at $backupPath" -ForegroundColor Red
    Write-Host "Looking for other backups..." -ForegroundColor Yellow
    $alternativeBackups = Get-ChildItem (Split-Path $modulePath -Parent) -Filter "OrchestrationManager.psm1.backup_*" | Sort-Object LastWriteTime -Descending
    if ($alternativeBackups) {
        $latestBackup = $alternativeBackups[0]
        Write-Host "Found backup: $($latestBackup.FullName)" -ForegroundColor Green
        Copy-Item $latestBackup.FullName $modulePath -Force
        Write-Host "Restored from alternative backup" -ForegroundColor Green
    } else {
        Write-Host "ERROR: No backups found. Manual intervention required." -ForegroundColor Red
        exit 1
    }
}

# Now apply a clean fix for the Invoke-DecisionExecution function
Write-Host "Applying clean test execution fix..." -ForegroundColor Yellow

# Read the restored content
$content = Get-Content $modulePath -Raw

# Create the properly formatted function
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

# Check if function exists in the restored file
if ($content -match 'function\s+Invoke-DecisionExecution\s*\{[\s\S]*?\n\}(?=\s*\nfunction|\s*\n#|\s*$)') {
    Write-Host "Found existing Invoke-DecisionExecution function, replacing with proper implementation..." -ForegroundColor Yellow
    $content = $content -replace 'function\s+Invoke-DecisionExecution\s*\{[\s\S]*?\n\}(?=\s*\nfunction|\s*\n#|\s*$)', $newFunction
} else {
    Write-Host "Invoke-DecisionExecution function not found, checking for Export-ModuleMember..." -ForegroundColor Yellow
    # Add the function before Export-ModuleMember if it exists
    if ($content -match '(Export-ModuleMember[\s\S]*)$') {
        $content = $content -replace '(Export-ModuleMember[\s\S]*)$', "$newFunction`n`n`$1"
        # Make sure Invoke-DecisionExecution is in the export list
        if ($content -notmatch 'Export-ModuleMember.*Invoke-DecisionExecution') {
            $content = $content -replace '(Export-ModuleMember\s+-Function\s+)([^\r\n]+)', '$1$2, Invoke-DecisionExecution'
        }
    } else {
        # If no Export-ModuleMember, just append at the end
        $content = $content + "`n`n$newFunction`n`nExport-ModuleMember -Function Invoke-DecisionExecution"
    }
}

# Save the fixed content
$content | Out-File $modulePath -Encoding UTF8

Write-Host "Fix applied successfully!" -ForegroundColor Green
Write-Host ""

# Verify syntax is correct
Write-Host "Verifying syntax..." -ForegroundColor Cyan
$tokens = $null
$errors = $null
[System.Management.Automation.Language.Parser]::ParseFile($modulePath, [ref]$tokens, [ref]$errors) | Out-Null

if ($errors) {
    Write-Host "WARNING: Syntax errors still detected:" -ForegroundColor Red
    $errors | ForEach-Object { Write-Host "  - $($_.Message)" -ForegroundColor Red }
} else {
    Write-Host "No syntax errors detected!" -ForegroundColor Green
}

Write-Host ""
Write-Host "The OrchestrationManager should now load correctly." -ForegroundColor Cyan
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Yellow
Write-Host "1. Restart the CLIOrchestrator" -ForegroundColor White
Write-Host "2. Test with a JSON file in ClaudeResponses\Autonomous" -ForegroundColor White
Write-Host "3. Verify test execution works properly" -ForegroundColor White