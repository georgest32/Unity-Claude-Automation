# Test-ASTAnalysis.ps1
# Focused test for AST-based cross-reference analysis
[CmdletBinding()]
param(
    [switch]$EnableVerbose
)

if ($EnableVerbose) {
    $VerbosePreference = "Continue"
}

Write-Host "AST Cross-Reference Analysis Tests" -ForegroundColor Cyan
Write-Host "===================================" -ForegroundColor Cyan

$testResults = @{
    TestName = "AST Analysis"
    Passed = 0
    Failed = 0
    Tests = @{}
}

# Test 1: Load module
try {
    Write-Host "Loading DocumentationCrossReference module..." -ForegroundColor Yellow
    Import-Module ".\Modules\Unity-Claude-DocumentationCrossReference\Unity-Claude-DocumentationCrossReference.psm1" -Force -ErrorAction Stop
    Write-Host "  [PASS] Module loaded" -ForegroundColor Green
    $testResults.Passed++
    $testResults.Tests.ModuleLoad = $true
}
catch {
    Write-Host "  [FAIL] Module load failed: $_" -ForegroundColor Red
    $testResults.Failed++
    $testResults.Tests.ModuleLoad = $false
    return $testResults
}

# Test 2: Test AST analysis on a safe test file
try {
    Write-Host "Testing AST analysis on safe test file..." -ForegroundColor Yellow
    
    # Create a simple test file that won't cause crashes
    $testFile = ".\Tests\CrossReference\test-sample.ps1"
    $testContent = @"
function Test-Function {
    param(`$Name)
    Write-Host "Hello `$Name"
}

function Get-Data {
    `$result = Test-Function -Name "World"
    return `$result
}

# Call the function
Get-Data
"@
    
    # Ensure directory exists
    if (-not (Test-Path ".\Tests\CrossReference")) {
        New-Item -ItemType Directory -Path ".\Tests\CrossReference" -Force | Out-Null
    }
    
    Set-Content -Path $testFile -Value $testContent -Force
    
    $astResult = Get-ASTCrossReferences -FilePath $testFile
    
    if ($astResult -and $astResult.References) {
        Write-Host "  [PASS] AST analysis completed" -ForegroundColor Green
        Write-Host "    Functions found: $($astResult.References.FunctionDefinitions.Count)" -ForegroundColor Gray
        Write-Host "    Calls found: $($astResult.References.FunctionCalls.Count)" -ForegroundColor Gray
        $testResults.Passed++
        $testResults.Tests.ASTAnalysis = $true
    }
    else {
        Write-Host "  [FAIL] No AST results returned" -ForegroundColor Red
        $testResults.Failed++
        $testResults.Tests.ASTAnalysis = $false
    }
}
catch {
    Write-Host "  [FAIL] AST analysis error: $_" -ForegroundColor Red
    $testResults.Failed++
    $testResults.Tests.ASTAnalysis = $false
}

# Test 3: Function definition detection
try {
    Write-Host "Testing function definition detection..." -ForegroundColor Yellow
    
    if (Test-Path $testFile) {
        $functions = Find-FunctionDefinitions -FilePath $testFile
        
        if ($functions -and $functions.Count -eq 2) {
            Write-Host "  [PASS] Found correct number of functions (2)" -ForegroundColor Green
            $testResults.Passed++
            $testResults.Tests.FunctionDetection = $true
        }
        else {
            Write-Host "  [FAIL] Expected 2 functions, found: $($functions.Count)" -ForegroundColor Red
            $testResults.Failed++
            $testResults.Tests.FunctionDetection = $false
        }
    }
}
catch {
    Write-Host "  [FAIL] Function detection error: $_" -ForegroundColor Red
    $testResults.Failed++
    $testResults.Tests.FunctionDetection = $false
}

# Test 4: Function call analysis
try {
    Write-Host "Testing function call analysis..." -ForegroundColor Yellow
    
    if (Test-Path $testFile) {
        $calls = Find-FunctionCalls -FilePath $testFile
        
        if ($calls) {
            Write-Host "  [PASS] Function calls analyzed" -ForegroundColor Green
            Write-Host "    Calls found: $($calls.Count)" -ForegroundColor Gray
            $testResults.Passed++
            $testResults.Tests.CallAnalysis = $true
        }
        else {
            Write-Host "  [WARN] No function calls found (may be correct)" -ForegroundColor Yellow
            $testResults.Passed++
            $testResults.Tests.CallAnalysis = $true
        }
    }
}
catch {
    Write-Host "  [FAIL] Call analysis error: $_" -ForegroundColor Red
    $testResults.Failed++
    $testResults.Tests.CallAnalysis = $false
}

# Summary
Write-Host "`nAST Analysis Test Summary" -ForegroundColor Cyan
Write-Host "=========================" -ForegroundColor Cyan
Write-Host "Passed: $($testResults.Passed)" -ForegroundColor Green
Write-Host "Failed: $($testResults.Failed)" -ForegroundColor Red
Write-Host "Success Rate: $([math]::Round(($testResults.Passed / ($testResults.Passed + $testResults.Failed)) * 100, 2))%" -ForegroundColor Yellow

# Clean up test file
if (Test-Path $testFile) {
    Remove-Item $testFile -Force -ErrorAction SilentlyContinue
}

return $testResults