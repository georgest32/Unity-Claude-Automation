# Test-SpecificFunction.ps1
# Try to isolate and test the specific function definition

Write-Host 'Testing Specific Function Definition Loading' -ForegroundColor Cyan
Write-Host ('=' * 50)

$decisionMakingPath = 'C:\UnityProjects\Sound-and-Shoal\Unity-Claude-Automation\Modules\Unity-Claude-CLIOrchestrator\Core\OrchestrationComponents\DecisionMaking.psm1'

# Read the file content
Write-Host "Reading DecisionMaking.psm1 content..." -ForegroundColor Yellow
$content = Get-Content $decisionMakingPath -Raw

# Extract just the function definition for Invoke-AutonomousDecisionMaking
Write-Host "Extracting function definition..." -ForegroundColor Yellow
$pattern = '(?s)function Invoke-AutonomousDecisionMaking.*?(?=^function|\z)'
$match = [regex]::Match($content, $pattern, 'Multiline')

if ($match.Success) {
    Write-Host "  Function definition found!" -ForegroundColor Green
    Write-Host "  Length: $($match.Value.Length) characters"
    
    # Show the first few lines of the function
    $lines = $match.Value -split "`n" | Select-Object -First 10
    Write-Host "  First 10 lines:"
    $lines | ForEach-Object { Write-Host "    $_" -ForegroundColor Gray }
    
    # Try to execute just this function definition
    Write-Host "`nTrying to execute just this function definition..." -ForegroundColor Yellow
    try {
        Invoke-Expression $match.Value
        Write-Host "  Function definition executed successfully" -ForegroundColor Green
        
        # Check if the function is now available
        $cmd = Get-Command "Invoke-AutonomousDecisionMaking" -ErrorAction SilentlyContinue
        if ($cmd) {
            Write-Host "  [SUCCESS] Invoke-AutonomousDecisionMaking is now available!" -ForegroundColor Green
        } else {
            Write-Host "  [PROBLEM] Function still not available after execution" -ForegroundColor Red
        }
    } catch {
        Write-Host "  Function execution failed: $_" -ForegroundColor Red
    }
} else {
    Write-Host "  Function definition NOT found!" -ForegroundColor Red
}

# Also check DecisionExecution.psm1
Write-Host "`nChecking DecisionExecution.psm1..." -ForegroundColor Yellow
$decisionExecutionPath = 'C:\UnityProjects\Sound-and-Shoal\Unity-Claude-Automation\Modules\Unity-Claude-CLIOrchestrator\Core\OrchestrationComponents\DecisionExecution.psm1'
$content2 = Get-Content $decisionExecutionPath -Raw

$pattern2 = '(?s)function Invoke-DecisionExecution.*?(?=^function|\z)'
$match2 = [regex]::Match($content2, $pattern2, 'Multiline')

if ($match2.Success) {
    Write-Host "  Invoke-DecisionExecution definition found!" -ForegroundColor Green
    try {
        Invoke-Expression $match2.Value
        Write-Host "  Function definition executed successfully" -ForegroundColor Green
        
        $cmd2 = Get-Command "Invoke-DecisionExecution" -ErrorAction SilentlyContinue
        if ($cmd2) {
            Write-Host "  [SUCCESS] Invoke-DecisionExecution is now available!" -ForegroundColor Green
        } else {
            Write-Host "  [PROBLEM] Function still not available after execution" -ForegroundColor Red
        }
    } catch {
        Write-Host "  Function execution failed: $_" -ForegroundColor Red
    }
} else {
    Write-Host "  Invoke-DecisionExecution definition NOT found!" -ForegroundColor Red
}

# Final check
Write-Host "`nFinal availability check:" -ForegroundColor Cyan
$finalFunctions = @('Invoke-AutonomousDecisionMaking', 'Invoke-DecisionExecution')
foreach ($func in $finalFunctions) {
    $cmd = Get-Command $func -ErrorAction SilentlyContinue
    Write-Host "  ${func}: $($cmd -ne $null)" -ForegroundColor $(if ($cmd) { 'Green' } else { 'Red' })
}