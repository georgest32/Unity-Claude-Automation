#requires -Version 5.1

<#
.SYNOPSIS
Comprehensive test script for Week 2 completion and Week 3 readiness

.DESCRIPTION
Run this script to verify:
- Week 2 Day 10 deliverables
- AI component organization
- Visualization system components
- Week 3 prerequisites
- Functional tests of key components

.PARAMETER RunFunctionalTests
Actually test the functionality of components (takes longer)

.PARAMETER QuickTest
Run only essential checks (faster)

.EXAMPLE
.\Test-Complete-System-Verification.ps1
Run all verification tests

.EXAMPLE
.\Test-Complete-System-Verification.ps1 -RunFunctionalTests
Run with functional testing of components

.EXAMPLE
.\Test-Complete-System-Verification.ps1 -QuickTest
Run quick essential checks only

.NOTES
Date: 2025-08-30
Author: Unity-Claude-Automation System
#>

param(
    [switch]$RunFunctionalTests,
    [switch]$QuickTest
)

# Initialize test tracking
$global:TestResults = @{
    TotalTests = 0
    PassedTests = 0
    FailedTests = 0
    StartTime = Get-Date
    Categories = @{}
}

function Write-TestHeader {
    param([string]$Title)
    Write-Host ""
    Write-Host ("=" * 60) -ForegroundColor Cyan
    Write-Host $Title -ForegroundColor Cyan
    Write-Host ("=" * 60) -ForegroundColor Cyan
    Write-Host ""
}

function Write-TestResult {
    param(
        [string]$TestName,
        [bool]$Passed,
        [string]$Details = ""
    )
    
    $global:TestResults.TotalTests++
    
    if ($Passed) {
        $global:TestResults.PassedTests++
        Write-Host "[PASS] " -ForegroundColor Green -NoNewline
        Write-Host $TestName -ForegroundColor White
    }
    else {
        $global:TestResults.FailedTests++
        Write-Host "[FAIL] " -ForegroundColor Red -NoNewline
        Write-Host $TestName -ForegroundColor White
    }
    
    if ($Details) {
        Write-Host "       $Details" -ForegroundColor Gray
    }
}

function Test-FileExists {
    param(
        [string]$Path,
        [string]$Description
    )
    
    $exists = Test-Path $Path
    Write-TestResult -TestName $Description -Passed $exists -Details $(if ($exists) { "Found: $(Split-Path $Path -Leaf)" } else { "Missing: $Path" })
    return $exists
}

function Test-ModuleImport {
    param(
        [string]$ModulePath,
        [string]$ModuleName
    )
    
    try {
        Import-Module $ModulePath -Force -ErrorAction Stop
        $module = Get-Module $ModuleName
        if ($module) {
            $functionCount = $module.ExportedFunctions.Count
            Write-TestResult -TestName "Import $ModuleName" -Passed $true -Details "$functionCount functions exported"
            return $true
        }
    }
    catch {
        Write-TestResult -TestName "Import $ModuleName" -Passed $false -Details $_.Exception.Message
    }
    return $false
}

# Start testing
Clear-Host
Write-Host ""
Write-Host "COMPREHENSIVE SYSTEM VERIFICATION TEST" -ForegroundColor Magenta
Write-Host "======================================" -ForegroundColor Magenta
Write-Host "Testing Week 2 completion and Week 3 readiness" -ForegroundColor White
Write-Host "Started: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor Gray
Write-Host ""

# ==============================================================================
# SECTION 1: WEEK 2 DAY 10 DELIVERABLES
# ==============================================================================
if (-not $QuickTest) {
    Write-TestHeader "SECTION 1: Week 2 Day 10 Deliverables"
    
    # Documentation files
    Test-FileExists -Path ".\Documentation\Enhanced-Visualization-Guide.md" -Description "Enhanced Visualization Guide"
    Test-FileExists -Path ".\Week2-Success-Metrics-Validation-Report.md" -Description "Week 2 Success Metrics Report"
    Test-FileExists -Path ".\Week3-Preparation-Advanced-Features-Plan.md" -Description "Week 3 Preparation Plan"
    Test-FileExists -Path ".\Week2_Day10_Integration_Documentation_2025_08_30.md" -Description "Week 2 Day 10 Documentation"
    
    # Test files
    Test-FileExists -Path ".\Test-Week2-Day10-Integration-Fixed.ps1" -Description "Week 2 Integration Test"
    Test-FileExists -Path ".\Verify-Week2-Day10-Deliverables.ps1" -Description "Week 2 Verification Script"
    
    # Visualization components
    Test-FileExists -Path ".\Start-Visualization-Dashboard.ps1" -Description "Visualization Dashboard Script"
    Test-FileExists -Path ".\Modules\Unity-Claude-AST-Enhanced\Unity-Claude-AST-Enhanced.psm1" -Description "AST Enhanced Module"
}

# ==============================================================================
# SECTION 2: AI COMPONENT ORGANIZATION
# ==============================================================================
Write-TestHeader "SECTION 2: AI Component Organization (New Structure)"

# LangGraph components
$langGraphBase = ".\Modules\Unity-Claude-AI-Integration\LangGraph"
Test-FileExists -Path "$langGraphBase\Unity-Claude-LangGraphBridge.psm1" -Description "LangGraph Bridge Module"
Test-FileExists -Path "$langGraphBase\Unity-Claude-MultiStepOrchestrator.psm1" -Description "Multi-Step Orchestrator"
Test-FileExists -Path "$langGraphBase\Workflows\PredictiveAnalysis-LangGraph-Workflows.json" -Description "Predictive Analysis Workflows"
Test-FileExists -Path "$langGraphBase\Workflows\MultiStep-Orchestrator-Workflows.json" -Description "Multi-Step Workflows"

# AutoGen components
$autoGenBase = ".\Modules\Unity-Claude-AI-Integration\AutoGen"
Test-FileExists -Path "$autoGenBase\Unity-Claude-AutoGen.psm1" -Description "AutoGen Module"
Test-FileExists -Path "$autoGenBase\Unity-Claude-AutoGenMonitoring.psm1" -Description "AutoGen Monitoring"
Test-FileExists -Path "$autoGenBase\PowerShell-AutoGen-Terminal-Integration.ps1" -Description "AutoGen Terminal Integration"

# Ollama components
$ollamaBase = ".\Modules\Unity-Claude-AI-Integration\Ollama"
Test-FileExists -Path "$ollamaBase\Unity-Claude-Ollama.psm1" -Description "Ollama Module"
Test-FileExists -Path "$ollamaBase\Unity-Claude-Ollama-Optimized-Fixed.psm1" -Description "Ollama Optimized"

# ==============================================================================
# SECTION 3: MODULE FUNCTIONALITY
# ==============================================================================
if ($RunFunctionalTests) {
    Write-TestHeader "SECTION 3: Module Functionality Tests"
    
    # Test AST Enhanced module
    $astModule = ".\Modules\Unity-Claude-AST-Enhanced\Unity-Claude-AST-Enhanced.psm1"
    if (Test-Path $astModule) {
        if (Test-ModuleImport -ModulePath $astModule -ModuleName "Unity-Claude-AST-Enhanced") {
            # Test specific functions
            $functions = @("Get-ModuleCallGraph", "Get-CrossModuleRelationships", "Export-CallGraphData")
            foreach ($func in $functions) {
                $exists = Get-Command $func -ErrorAction SilentlyContinue
                Write-TestResult -TestName "Function: $func" -Passed ($null -ne $exists)
            }
        }
    }
    
    # Test LangGraph module
    $langGraphModule = ".\Modules\Unity-Claude-AI-Integration\LangGraph\Unity-Claude-LangGraphBridge.psm1"
    if (Test-Path $langGraphModule) {
        Test-ModuleImport -ModulePath $langGraphModule -ModuleName "Unity-Claude-LangGraphBridge"
    }
    
    # Test Ollama module
    $ollamaModule = ".\Modules\Unity-Claude-AI-Integration\Ollama\Unity-Claude-Ollama.psm1"
    if (Test-Path $ollamaModule) {
        Test-ModuleImport -ModulePath $ollamaModule -ModuleName "Unity-Claude-Ollama"
    }
}

# ==============================================================================
# SECTION 4: WEEK 3 PREREQUISITES
# ==============================================================================
Write-TestHeader "SECTION 4: Week 3 Prerequisites"

# Check for FileSystemWatcher implementations
Write-Host "Checking FileSystemWatcher implementations..." -ForegroundColor Yellow
$fswModules = Get-ChildItem -Path ".\Modules" -Filter "*.psm1" -Recurse -ErrorAction SilentlyContinue |
              Where-Object { 
                  try {
                      (Get-Content $_.FullName -Raw -ErrorAction SilentlyContinue) -match "FileSystemWatcher"
                  } catch { $false }
              }

if ($fswModules) {
    Write-TestResult -TestName "FileSystemWatcher Implementations" -Passed $true -Details "$($fswModules.Count) modules with FSW"
    if (-not $QuickTest) {
        foreach ($module in $fswModules | Select-Object -First 3) {
            Write-Host "       - $($module.Name)" -ForegroundColor Gray
        }
    }
}
else {
    Write-TestResult -TestName "FileSystemWatcher Implementations" -Passed $false
}

# Check for monitoring patterns
$monitoringPatterns = @{
    "Circuit Breaker" = 'Circuit.*Breaker|CircuitBreaker'
    "Performance Monitoring" = 'Get-Counter|Performance.*Monitor'
    "Health Check" = 'Health.*Check|Test-.*Health'
}

foreach ($pattern in $monitoringPatterns.GetEnumerator()) {
    $found = Get-ChildItem -Path ".\Modules" -Filter "*.psm1" -Recurse -ErrorAction SilentlyContinue |
             Where-Object { 
                 try {
                     (Get-Content $_.FullName -Raw -ErrorAction SilentlyContinue) -match $pattern.Value
                 } catch { $false }
             } |
             Select-Object -First 1
    
    Write-TestResult -TestName "Pattern: $($pattern.Key)" -Passed ($null -ne $found) -Details $(if ($found) { "Found in: $($found.Name)" })
}

# ==============================================================================
# SECTION 5: QUICK FUNCTIONALITY CHECK
# ==============================================================================
if (-not $QuickTest) {
    Write-TestHeader "SECTION 5: Quick Functionality Check"
    
    # Check if DependencySearch module is available
    $depSearch = Get-Module -ListAvailable DependencySearch
    Write-TestResult -TestName "DependencySearch Module Available" -Passed ($null -ne $depSearch) -Details $(if ($depSearch) { "Version: $($depSearch.Version)" })
    
    # Check Node.js availability
    try {
        $nodeVersion = & node --version 2>$null
        Write-TestResult -TestName "Node.js Available" -Passed ($null -ne $nodeVersion) -Details $nodeVersion
    }
    catch {
        Write-TestResult -TestName "Node.js Available" -Passed $false -Details "Required for visualization dashboard"
    }
    
    # Check visualization directory structure
    $vizDirs = @(".\Visualization", ".\Visualization\public", ".\Visualization\public\static\data")
    $vizOk = $true
    foreach ($dir in $vizDirs) {
        if (-not (Test-Path $dir)) {
            $vizOk = $false
            break
        }
    }
    Write-TestResult -TestName "Visualization Directory Structure" -Passed $vizOk
}

# ==============================================================================
# SECTION 6: INTEGRATION TEST
# ==============================================================================
if ($RunFunctionalTests -and -not $QuickTest) {
    Write-TestHeader "SECTION 6: Integration Test"
    
    Write-Host "Testing module integration..." -ForegroundColor Yellow
    
    try {
        # Try to analyze a simple module
        $astModule = Get-Module Unity-Claude-AST-Enhanced
        if ($astModule) {
            $testPath = ".\Modules\Unity-Claude-AI-Integration\LangGraph\Unity-Claude-LangGraphBridge.psm1"
            if (Test-Path $testPath) {
                $result = Get-ModuleCallGraph -ModulePaths @($testPath) -CacheResults -ErrorAction Stop
                Write-TestResult -TestName "AST Analysis Integration" -Passed ($null -ne $result)
            }
        }
    }
    catch {
        Write-TestResult -TestName "AST Analysis Integration" -Passed $false -Details $_.Exception.Message
    }
}

# ==============================================================================
# FINAL SUMMARY
# ==============================================================================
Write-TestHeader "TEST SUMMARY"

$duration = [math]::Round(((Get-Date) - $global:TestResults.StartTime).TotalSeconds, 2)
$successRate = if ($global:TestResults.TotalTests -gt 0) {
    [math]::Round(($global:TestResults.PassedTests / $global:TestResults.TotalTests) * 100, 1)
} else { 0 }

# Display results
Write-Host "Total Tests: $($global:TestResults.TotalTests)" -ForegroundColor White
Write-Host "Passed: $($global:TestResults.PassedTests)" -ForegroundColor Green
Write-Host "Failed: $($global:TestResults.FailedTests)" -ForegroundColor $(if ($global:TestResults.FailedTests -gt 0) { "Red" } else { "Gray" })
Write-Host "Success Rate: $successRate%" -ForegroundColor $(if ($successRate -ge 80) { "Green" } elseif ($successRate -ge 60) { "Yellow" } else { "Red" })
Write-Host "Duration: $duration seconds" -ForegroundColor Gray

Write-Host ""

# Final verdict
if ($successRate -ge 90) {
    Write-Host "VERDICT: SYSTEM FULLY VERIFIED" -ForegroundColor Green -BackgroundColor DarkGreen
    Write-Host "Ready to proceed with Week 3 implementation" -ForegroundColor Green
}
elseif ($successRate -ge 70) {
    Write-Host "VERDICT: SYSTEM PARTIALLY VERIFIED" -ForegroundColor Yellow -BackgroundColor DarkYellow
    Write-Host "Most components ready, review failed tests" -ForegroundColor Yellow
}
else {
    Write-Host "VERDICT: SYSTEM NEEDS ATTENTION" -ForegroundColor Red -BackgroundColor DarkRed
    Write-Host "Multiple components missing or failing" -ForegroundColor Red
}

Write-Host ""
Write-Host "Test completed: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor Gray

# Save results
$resultFile = ".\Test-Results-$(Get-Date -Format 'yyyyMMdd-HHmmss').json"
$global:TestResults | ConvertTo-Json -Depth 3 | Out-File -FilePath $resultFile -Encoding UTF8
Write-Host "Results saved to: $resultFile" -ForegroundColor Cyan

# Exit with appropriate code
exit $(if ($successRate -ge 80) { 0 } else { 1 })