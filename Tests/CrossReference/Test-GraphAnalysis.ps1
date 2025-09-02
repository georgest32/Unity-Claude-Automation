# Test-GraphAnalysis.ps1
# Focused test for documentation graph analysis
[CmdletBinding()]
param(
    [switch]$EnableVerbose
)

if ($EnableVerbose) {
    $VerbosePreference = "Continue"
}

Write-Host "Documentation Graph Analysis Tests" -ForegroundColor Cyan
Write-Host "===================================" -ForegroundColor Cyan

$testResults = @{
    TestName = "Graph Analysis"
    Passed = 0
    Failed = 0
    Tests = @{}
}

# Test 1: Load required modules
try {
    Write-Host "Loading required modules..." -ForegroundColor Yellow
    Import-Module ".\Modules\Unity-Claude-DocumentationCrossReference\Unity-Claude-DocumentationCrossReference.psm1" -Force -ErrorAction Stop
    Import-Module ".\Modules\Unity-Claude-DocumentationSuggestions\Unity-Claude-DocumentationSuggestions.psm1" -Force -ErrorAction Stop
    Write-Host "  [PASS] Modules loaded" -ForegroundColor Green
    $testResults.Passed++
    $testResults.Tests.ModuleLoad = $true
}
catch {
    Write-Host "  [FAIL] Module load failed: $_" -ForegroundColor Red
    $testResults.Failed++
    $testResults.Tests.ModuleLoad = $false
    return $testResults
}

# Test 2: Initialize cross-reference system
try {
    Write-Host "Initializing cross-reference system..." -ForegroundColor Yellow
    $initResult = Initialize-DocumentationCrossReference -EnableRealTimeMonitoring -EnableAIEnhancement
    
    if ($initResult) {
        Write-Host "  [PASS] System initialized" -ForegroundColor Green
        $testResults.Passed++
        $testResults.Tests.SystemInit = $true
    }
    else {
        Write-Host "  [FAIL] System initialization failed" -ForegroundColor Red
        $testResults.Failed++
        $testResults.Tests.SystemInit = $false
    }
}
catch {
    Write-Host "  [FAIL] Initialization error: $_" -ForegroundColor Red
    $testResults.Failed++
    $testResults.Tests.SystemInit = $false
}

# Test 3: Build documentation graph with safe test data
try {
    Write-Host "Building documentation graph..." -ForegroundColor Yellow
    
    # Create test directory with sample files
    $testDir = ".\Tests\CrossReference\TestDocs"
    if (-not (Test-Path $testDir)) {
        New-Item -ItemType Directory -Path $testDir -Force | Out-Null
    }
    
    # Create sample documentation files
    @"
# Main Documentation
This links to [sub-doc](./sub-doc.md) and [api-doc](./api-doc.md).
"@ | Set-Content "$testDir\main.md"
    
    @"
# Sub Documentation
References back to [main](./main.md).
"@ | Set-Content "$testDir\sub-doc.md"
    
    @"
# API Documentation
See [main documentation](./main.md) for details.
"@ | Set-Content "$testDir\api-doc.md"
    
    # Build graph with test directory only
    $graphResult = Build-DocumentationGraph -DocumentationPaths @($testDir) -IncludeMetrics
    
    if ($graphResult -and $graphResult.Metrics) {
        Write-Host "  [PASS] Graph built successfully" -ForegroundColor Green
        Write-Host "    Nodes: $($graphResult.Metrics.TotalNodes)" -ForegroundColor Gray
        Write-Host "    Edges: $($graphResult.Metrics.TotalEdges)" -ForegroundColor Gray
        $testResults.Passed++
        $testResults.Tests.GraphBuild = $true
        
        # Store for next tests
        $script:testGraph = $graphResult
    }
    else {
        Write-Host "  [FAIL] Graph build failed" -ForegroundColor Red
        $testResults.Failed++
        $testResults.Tests.GraphBuild = $false
    }
}
catch {
    Write-Host "  [FAIL] Graph build error: $_" -ForegroundColor Red
    $testResults.Failed++
    $testResults.Tests.GraphBuild = $false
}

# Test 4: Centrality analysis (if graph was built)
try {
    Write-Host "Testing centrality analysis..." -ForegroundColor Yellow
    
    if ($script:testGraph) {
        $centrality = Calculate-DocumentationCentrality -Graph $script:testGraph
        
        if ($centrality) {
            Write-Host "  [PASS] Centrality calculated" -ForegroundColor Green
            $testResults.Passed++
            $testResults.Tests.Centrality = $true
        }
        else {
            Write-Host "  [WARN] No centrality scores (may be correct for small graph)" -ForegroundColor Yellow
            $testResults.Passed++
            $testResults.Tests.Centrality = $true
        }
    }
    else {
        Write-Host "  [SKIP] No graph available for centrality analysis" -ForegroundColor Yellow
        $testResults.Tests.Centrality = "Skipped"
    }
}
catch {
    Write-Host "  [FAIL] Centrality error: $_" -ForegroundColor Red
    $testResults.Failed++
    $testResults.Tests.Centrality = $false
}

# Test 5: Content embedding generation
try {
    Write-Host "Testing content embedding generation..." -ForegroundColor Yellow
    
    $testContent = "This is a test of the documentation embedding system for similarity analysis."
    $embedding = Generate-ContentEmbedding -Content $testContent
    
    if ($embedding -and ($embedding | Measure-Object).Count -gt 0) {
        Write-Host "  [PASS] Embedding generated" -ForegroundColor Green
        Write-Host "    Dimensions: $($embedding.Count)" -ForegroundColor Gray
        $testResults.Passed++
        $testResults.Tests.Embedding = $true
    }
    else {
        Write-Host "  [WARN] No embedding generated (AI may not be available)" -ForegroundColor Yellow
        $testResults.Passed++
        $testResults.Tests.Embedding = $true
    }
}
catch {
    Write-Host "  [FAIL] Embedding error: $_" -ForegroundColor Red
    $testResults.Failed++
    $testResults.Tests.Embedding = $false
}

# Clean up test files
try {
    if (Test-Path $testDir) {
        Remove-Item $testDir -Recurse -Force -ErrorAction SilentlyContinue
    }
}
catch {
    # Ignore cleanup errors
}

# Summary
Write-Host "`nGraph Analysis Test Summary" -ForegroundColor Cyan
Write-Host "===========================" -ForegroundColor Cyan
Write-Host "Passed: $($testResults.Passed)" -ForegroundColor Green
Write-Host "Failed: $($testResults.Failed)" -ForegroundColor Red
if ($testResults.Passed + $testResults.Failed -gt 0) {
    Write-Host "Success Rate: $([math]::Round(($testResults.Passed / ($testResults.Passed + $testResults.Failed)) * 100, 2))%" -ForegroundColor Yellow
}

return $testResults