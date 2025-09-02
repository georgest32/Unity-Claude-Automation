# Test-Syntax.ps1
# Test for syntax errors in component files

Write-Host 'Testing PowerShell Function Definition and File Syntax' -ForegroundColor Cyan
Write-Host ('=' * 50)

# Test 1: Basic function definition
Write-Host "Test 1: Basic function definition..." -ForegroundColor Yellow
function Test-BasicFunction { 
    Write-Host 'Basic function works!' 
}

$cmd = Get-Command 'Test-BasicFunction' -ErrorAction SilentlyContinue
Write-Host "  Test-BasicFunction available: $($cmd -ne $null)"

# Test 2: Check DecisionMaking.psm1 syntax
Write-Host "`nTest 2: Checking DecisionMaking.psm1 syntax..." -ForegroundColor Yellow
$decisionMakingPath = 'C:\UnityProjects\Sound-and-Shoal\Unity-Claude-Automation\Modules\Unity-Claude-CLIOrchestrator\Core\OrchestrationComponents\DecisionMaking.psm1'

try {
    # Try to parse the file for syntax errors
    $null = [System.Management.Automation.PSParser]::Tokenize((Get-Content $decisionMakingPath -Raw), [ref]$null)
    Write-Host "  DecisionMaking.psm1: No syntax errors detected" -ForegroundColor Green
} catch {
    Write-Host "  DecisionMaking.psm1: Syntax error - $_" -ForegroundColor Red
}

# Test 3: Check DecisionExecution.psm1 syntax  
Write-Host "`nTest 3: Checking DecisionExecution.psm1 syntax..." -ForegroundColor Yellow
$decisionExecutionPath = 'C:\UnityProjects\Sound-and-Shoal\Unity-Claude-Automation\Modules\Unity-Claude-CLIOrchestrator\Core\OrchestrationComponents\DecisionExecution.psm1'

try {
    $null = [System.Management.Automation.PSParser]::Tokenize((Get-Content $decisionExecutionPath -Raw), [ref]$null)
    Write-Host "  DecisionExecution.psm1: No syntax errors detected" -ForegroundColor Green
} catch {
    Write-Host "  DecisionExecution.psm1: Syntax error - $_" -ForegroundColor Red
}

# Test 4: Try to manually dot-source and execute a simple function from DecisionMaking
Write-Host "`nTest 4: Manual dot-source test..." -ForegroundColor Yellow
try {
    . $decisionMakingPath
    Write-Host "  Dot-source completed successfully" -ForegroundColor Green
    
    # Check if any functions were defined
    $functionsAfterDotSource = Get-Command -CommandType Function | Where-Object { $_.Source -eq "" } | Measure-Object
    Write-Host "  Functions available after dot-source: $($functionsAfterDotSource.Count)"
    
    # Look specifically for our function
    if (Get-Command "Invoke-AutonomousDecisionMaking" -ErrorAction SilentlyContinue) {
        Write-Host "  [SUCCESS] Invoke-AutonomousDecisionMaking is available!" -ForegroundColor Green
    } else {
        Write-Host "  [PROBLEM] Invoke-AutonomousDecisionMaking is still not available" -ForegroundColor Red
        
        # Try to find any function that contains "Autonomous" in the name
        $similarFunctions = Get-Command -CommandType Function | Where-Object { $_.Name -like "*Autonomous*" }
        if ($similarFunctions) {
            Write-Host "  Similar functions found:" -ForegroundColor Yellow
            $similarFunctions | ForEach-Object { Write-Host "    - $($_.Name)" -ForegroundColor Gray }
        }
    }
} catch {
    Write-Host "  Dot-source failed: $_" -ForegroundColor Red
}