#Requires -Version 5.1
<#
.SYNOPSIS
    Test script for Week 1, Day 2 implementations: Call Graph Builder and Data Flow Tracker

.DESCRIPTION
    Tests call graph construction and data flow analysis functionality

.NOTES
    Part of Enhanced Documentation System Second Pass Implementation
    Created: 2025-08-28
#>

# Set up test environment
$testStartTime = Get-Date
$modulePath = "$PSScriptRoot\Modules\Unity-Claude-CPG\Core"
$testResults = @{
    Passed = 0
    Failed = 0
    Timestamp = $testStartTime
    Tests = @()
}

Write-Host "`n=== Testing Day 2 Implementations ===" -ForegroundColor Cyan
Write-Host "Date: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor Gray
Write-Host "Modules: Call Graph Builder & Data Flow Tracker`n" -ForegroundColor Gray

# Create a test PowerShell script for analysis
$testScriptPath = "$PSScriptRoot\Test-SampleScript.ps1"
$testScriptContent = @'
# Sample script for testing call graph and data flow

$global:ConfigPath = "C:\Config\settings.json"
$script:LogLevel = "Info"

function Initialize-System {
    param(
        [string]$Mode = "Default"
    )
    
    Write-Host "Initializing system in $Mode mode"
    $config = Load-Configuration
    
    if ($config) {
        Process-Configuration -Config $config
    }
    
    Start-Monitoring
    return $config
}

function Load-Configuration {
    Write-Host "Loading configuration"
    $settings = @{
        Mode = "Production"
        Timeout = 30
    }
    
    # Potential security issue: password in plain text
    $password = "SecretPassword123"
    
    return $settings
}

function Process-Configuration {
    param(
        [hashtable]$Config
    )
    
    $processedCount = 0
    
    foreach ($key in $Config.Keys) {
        Write-Host "Processing: $key"
        $processedCount++
    }
    
    # Recursive call
    if ($processedCount -lt 10) {
        Process-Configuration -Config $Config
    }
    
    return $processedCount
}

function Start-Monitoring {
    $monitoringActive = $true
    
    # Dynamic invocation (potential security risk)
    $command = "Get-Process"
    Invoke-Expression $command
    
    # Another dynamic invocation
    & "Get-Service"
    
    return $monitoringActive
}

# Script entry point
$result = Initialize-System -Mode "Test"

# Variable usage patterns
$counter = 0
$counter++

for ($i = 0; $i -lt 5; $i++) {
    $counter = $counter + $i
}

# Unused variable (dead code)
$unusedVar = "This is never used"

# Undefined use
Write-Host $undefinedVariable

# Tainted data flow
$userInput = Read-Host "Enter command"
Invoke-Expression $userInput  # Security vulnerability
'@

$testScriptContent | Set-Content -Path $testScriptPath -Encoding UTF8

# Function to run tests
function Test-Assert {
    param(
        [string]$TestName,
        [scriptblock]$Condition,
        [string]$ErrorMessage = "Test failed"
    )
    
    try {
        Write-Host "  Testing: $TestName... " -NoNewline
        $result = & $Condition
        if ($result) {
            $testResults.Passed++
            $testResults.Tests += @{
                Name = $TestName
                Passed = $true
                Message = "OK"
                Duration = ((Get-Date) - $testStartTime).TotalMilliseconds
            }
            Write-Host "PASS" -ForegroundColor Green
        } else {
            $testResults.Failed++
            $testResults.Tests += @{
                Name = $TestName
                Passed = $false
                Message = $ErrorMessage
                Duration = ((Get-Date) - $testStartTime).TotalMilliseconds
            }
            Write-Host "FAIL - $ErrorMessage" -ForegroundColor Red
        }
    } catch {
        $testResults.Failed++
        $testResults.Tests += @{
            Name = $TestName
            Passed = $false
            Message = $_.Exception.Message
            Duration = ((Get-Date) - $testStartTime).TotalMilliseconds
        }
        Write-Host "ERROR - $($_.Exception.Message)" -ForegroundColor Red
    }
}

# Test 1: Call Graph Builder Module Load
Write-Host "`n[Test Group 1: Call Graph Builder]" -ForegroundColor Yellow

Test-Assert "Load Call Graph Builder Module" {
    Import-Module "$modulePath\CPG-CallGraphBuilder.psm1" -Force -ErrorAction Stop
    Get-Command -Module "CPG-CallGraphBuilder" | Out-Null
    $true
}

Test-Assert "Call Graph Builder Functions Available" {
    $functions = @(
        'Build-PowerShellCallGraph',
        'Resolve-VirtualMethodCalls',
        'Get-CallGraphMetrics',
        'Export-CallGraph'
    )
    $available = $true
    foreach ($func in $functions) {
        if (-not (Get-Command $func -ErrorAction SilentlyContinue)) {
            $available = $false
            break
        }
    }
    $available
}

# Test 2: Build Call Graph
$callGraph = $null
Test-Assert "Build PowerShell Call Graph" {
    $script:callGraph = Build-PowerShellCallGraph -ScriptPath $testScriptPath
    $callGraph -ne $null -and $callGraph.GetType().Name -eq 'CallGraph'
}

Test-Assert "Call Graph Contains Functions" {
    $callGraph.CallNodes.Count -ge 4  # Should have at least 4 functions
}

Test-Assert "Call Graph Contains Edges" {
    $callGraph.CallEdges.Count -gt 0  # Should have call edges
}

Test-Assert "Detect Recursive Calls" {
    $callGraph.RecursiveCalls.Count -gt 0  # Process-Configuration is recursive
}

# Test 3: Call Graph Metrics
$metrics = $null
Test-Assert "Get Call Graph Metrics" {
    $script:metrics = Get-CallGraphMetrics -CallGraph $callGraph
    $metrics -ne $null -and $metrics.ContainsKey('TotalFunctions')
}

Test-Assert "Metrics Show Entry Points" {
    $metrics.EntryPoints.Count -gt 0
}

Test-Assert "Metrics Show Leaf Functions" {
    $metrics.LeafFunctions.Count -gt 0
}

# Test 4: Export Call Graph
Test-Assert "Export Call Graph to JSON" {
    $exportPath = "$PSScriptRoot\CallGraph-Test.json"
    Export-CallGraph -CallGraph $callGraph -OutputPath $exportPath -Format JSON
    Test-Path $exportPath
}

# Test 5: Data Flow Tracker Module Load
Write-Host "`n[Test Group 2: Data Flow Tracker]" -ForegroundColor Yellow

Test-Assert "Load Data Flow Tracker Module" {
    Import-Module "$modulePath\CPG-DataFlowTracker.psm1" -Force -ErrorAction Stop
    Get-Command -Module "CPG-DataFlowTracker" | Out-Null
    $true
}

Test-Assert "Data Flow Tracker Functions Available" {
    $functions = @(
        'Build-PowerShellDataFlow',
        'Compute-LiveVariables',
        'Analyze-DataSensitivity',
        'Get-DataFlowMetrics',
        'Export-DataFlow'
    )
    $available = $true
    foreach ($func in $functions) {
        if (-not (Get-Command $func -ErrorAction SilentlyContinue)) {
            $available = $false
            break
        }
    }
    $available
}

# Test 6: Build Data Flow
$dataFlow = $null
Test-Assert "Build PowerShell Data Flow" {
    $script:dataFlow = Build-PowerShellDataFlow -ScriptPath $testScriptPath
    $dataFlow -ne $null -and $dataFlow.GetType().Name -eq 'DataFlowGraph'
}

Test-Assert "Data Flow Contains Definitions" {
    $dataFlow.Definitions.Count -gt 0
}

Test-Assert "Data Flow Contains Uses" {
    $dataFlow.Uses.Count -gt 0
}

Test-Assert "Def-Use Chains Created" {
    $dataFlow.DefUseChains.Count -gt 0
}

# Test 7: Taint Analysis
Test-Assert "Taint Analysis Detects Security Issues" {
    $dataFlow.TaintAnalysis.Count -gt 0  # Should detect Invoke-Expression usage
}

Test-Assert "Tainted Variables Marked" {
    $taintedFound = $false
    foreach ($taint in $dataFlow.TaintAnalysis.Values) {
        if ($taint.Level -ne 'Untainted') {
            $taintedFound = $true
            break
        }
    }
    $taintedFound
}

# Test 8: Data Sensitivity Analysis
$sensitivity = $null
Test-Assert "Analyze Data Sensitivity" {
    $script:sensitivity = Analyze-DataSensitivity -DataFlow $dataFlow
    $sensitivity -ne $null -and $sensitivity.Count -gt 0
}

Test-Assert "Detect Sensitive Variables" {
    $sensitiveFound = $false
    foreach ($item in $sensitivity.Values) {
        if ($item.Variable.Name -like '*password*') {
            $sensitiveFound = $true
            break
        }
    }
    $sensitiveFound
}

# Test 9: Data Flow Metrics
$dfMetrics = $null
Test-Assert "Get Data Flow Metrics" {
    $script:dfMetrics = Get-DataFlowMetrics -DataFlow $dataFlow
    $dfMetrics -ne $null -and $dfMetrics.ContainsKey('TotalVariables')
}

Test-Assert "Metrics Show Unused Definitions" {
    $dfMetrics.UnusedDefinitions -ne $null  # unusedVar should be detected
}

Test-Assert "Metrics Show Undefined Uses" {
    $dfMetrics.UndefinedUses -ne $null  # undefinedVariable should be detected
}

# Test 10: Export Data Flow
Test-Assert "Export Data Flow to JSON" {
    $exportPath = "$PSScriptRoot\DataFlow-Test.json"
    Export-DataFlow -DataFlow $dataFlow -OutputPath $exportPath -Format JSON
    Test-Path $exportPath
}

# Test 11: Integration Tests
Write-Host "`n[Test Group 3: Integration]" -ForegroundColor Yellow

Test-Assert "Call Graph and Data Flow Consistency" {
    # Both should analyze the same script successfully
    $callGraph.Name -eq $dataFlow.Name
}

Test-Assert "Performance Within Limits" {
    # Check if analysis completed within reasonable time
    $duration = (Get-Date) - $testStartTime
    $duration.TotalSeconds -lt 30  # Should complete within 30 seconds
}

# Clean up test files
Write-Host "`n[Cleanup]" -ForegroundColor Yellow
if (Test-Path $testScriptPath) {
    Remove-Item $testScriptPath -Force
    Write-Host "  Removed test script" -ForegroundColor Gray
}
if (Test-Path "$PSScriptRoot\CallGraph-Test.json") {
    Remove-Item "$PSScriptRoot\CallGraph-Test.json" -Force
    Write-Host "  Removed call graph export" -ForegroundColor Gray
}
if (Test-Path "$PSScriptRoot\DataFlow-Test.json") {
    Remove-Item "$PSScriptRoot\DataFlow-Test.json" -Force
    Write-Host "  Removed data flow export" -ForegroundColor Gray
}

# Generate test report
Write-Host "`n=== Test Results Summary ===" -ForegroundColor Cyan
Write-Host "Total Tests: $($testResults.Passed + $testResults.Failed)" -ForegroundColor White
Write-Host "Passed: $($testResults.Passed)" -ForegroundColor Green
Write-Host "Failed: $($testResults.Failed)" -ForegroundColor $(if ($testResults.Failed -gt 0) { 'Red' } else { 'Gray' })
Write-Host "Success Rate: $([Math]::Round(($testResults.Passed / ($testResults.Passed + $testResults.Failed)) * 100, 2))%"
Write-Host "Total Duration: $([Math]::Round(((Get-Date) - $testStartTime).TotalSeconds, 2)) seconds"

# Save detailed results
$resultsFile = "$PSScriptRoot\Day2-TestResults-$(Get-Date -Format 'yyyyMMdd-HHmmss').json"
$testResults | ConvertTo-Json -Depth 10 | Set-Content $resultsFile -Encoding UTF8
Write-Host "`nDetailed results saved to: $resultsFile" -ForegroundColor Gray

# Exit code
$exitCode = if ($testResults.Failed -eq 0) { 0 } else { 1 }
Write-Host "`nTest suite " -NoNewline
if ($exitCode -eq 0) {
    Write-Host "PASSED" -ForegroundColor Green
} else {
    Write-Host "FAILED" -ForegroundColor Red
}

exit $exitCode