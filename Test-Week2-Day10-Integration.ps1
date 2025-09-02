#requires -Version 5.1

<#
.SYNOPSIS
Week 2 Day 10 Integration Test Suite for Enhanced Visualization System

.DESCRIPTION
Comprehensive integration testing for Week 2 visualization components including:
- Unity-Claude-AST-Enhanced module functionality
- DependencySearch module integration
- Function call graph generation
- Relationship mapping and analysis
- D3.js data export capabilities
- Visualization dashboard readiness

.NOTES
Date: 2025-08-30
Author: Unity-Claude-Automation System
Part of: MAXIMUM_UTILIZATION_IMPLEMENTATION_PLAN_2025_08_29.md Week 2 Day 10
#>

param(
    [switch]$Verbose,
    [switch]$GenerateSampleData,
    [switch]$TestVisualization
)

# Set verbose preference
if ($Verbose) {
    $VerbosePreference = "Continue"
}

# Initialize test results
$testResults = @{
    TotalTests = 0
    PassedTests = 0
    FailedTests = 0
    Errors = @()
    StartTime = Get-Date
    Details = @()
}

function Write-TestLog {
    param(
        [string]$Message,
        [string]$Level = "Info"
    )
    
    $colors = @{
        "Info" = "White"
        "Success" = "Green"
        "Warning" = "Yellow"
        "Error" = "Red"
        "Test" = "Cyan"
    }
    
    $color = $colors[$Level]
    Write-Host "[$(Get-Date -Format 'HH:mm:ss')] [$Level] $Message" -ForegroundColor $color
}

function Test-ComponentAvailability {
    param([string]$TestName, [scriptblock]$TestBlock)
    
    $testResults.TotalTests++
    Write-TestLog "Running test: $TestName" -Level "Test"
    
    try {
        $result = & $TestBlock
        if ($result) {
            $testResults.PassedTests++
            Write-TestLog "PASS: $TestName" -Level "Success"
            $testResults.Details += @{
                Test = $TestName
                Status = "Passed"
                Result = $result
                Time = Get-Date
            }
            return $true
        }
        else {
            $testResults.FailedTests++
            Write-TestLog "FAIL: $TestName" -Level "Error"
            $testResults.Details += @{
                Test = $TestName
                Status = "Failed"
                Result = "Test returned false"
                Time = Get-Date
            }
            return $false
        }
    }
    catch {
        $testResults.FailedTests++
        $testResults.Errors += $_.Exception.Message
        Write-TestLog "ERROR: $TestName - $_" -Level "Error"
        $testResults.Details += @{
            Test = $TestName
            Status = "Error"
            Result = $_.Exception.Message
            Time = Get-Date
        }
        return $false
    }
}

Write-Host "===============================================" -ForegroundColor Cyan
Write-Host "Week 2 Day 10 - Visualization System Integration Test" -ForegroundColor Cyan
Write-Host "===============================================" -ForegroundColor Cyan
Write-Host ""

# Test 1: DependencySearch Module Availability
Test-ComponentAvailability "DependencySearch Module Available" {
    $module = Get-Module -ListAvailable DependencySearch
    if ($module) {
        Write-Verbose "DependencySearch version: $($module.Version)"
        return $true
    }
    return $false
}

# Test 2: Unity-Claude-AST-Enhanced Module
Test-ComponentAvailability "Unity-Claude-AST-Enhanced Module Exists" {
    $modulePath = Join-Path $PSScriptRoot "Modules\Unity-Claude-AST-Enhanced\Unity-Claude-AST-Enhanced.psm1"
    if (Test-Path $modulePath) {
        Write-Verbose "Module path: $modulePath"
        return $true
    }
    return $false
}

# Test 3: Import Unity-Claude-AST-Enhanced Module
Test-ComponentAvailability "Import Unity-Claude-AST-Enhanced Module" {
    $modulePath = Join-Path $PSScriptRoot "Modules\Unity-Claude-AST-Enhanced\Unity-Claude-AST-Enhanced.psm1"
    try {
        Import-Module $modulePath -Force
        $module = Get-Module Unity-Claude-AST-Enhanced
        if ($module) {
            Write-Verbose "Module loaded with $($module.ExportedFunctions.Count) functions"
            return $true
        }
    }
    catch {
        Write-Verbose "Import error: $_"
    }
    return $false
}

# Test 4: Core AST Functions Available
Test-ComponentAvailability "Core AST Functions Available" {
    $requiredFunctions = @(
        "Get-ModuleCallGraph",
        "Get-ModuleDependencyMap",
        "Export-VisualizationData",
        "Get-FunctionCallRelationships"
    )
    
    $module = Get-Module Unity-Claude-AST-Enhanced
    if ($module) {
        $availableFunctions = $module.ExportedFunctions.Keys
        $missingFunctions = $requiredFunctions | Where-Object { $_ -notin $availableFunctions }
        
        if ($missingFunctions.Count -eq 0) {
            Write-Verbose "All required functions available"
            return $true
        }
        else {
            Write-Verbose "Missing functions: $($missingFunctions -join ', ')"
        }
    }
    return $false
}

# Test 5: Test Module Analysis on Sample Module
Test-ComponentAvailability "Module Analysis on Unity-Claude-Core" {
    try {
        $coreModulePath = Join-Path $PSScriptRoot "Modules\Unity-Claude-Core\Unity-Claude-Core.psm1"
        if (Test-Path $coreModulePath) {
            $callGraph = Get-ModuleCallGraph -ModulePaths @($coreModulePath) -CacheResults
            if ($callGraph) {
                Write-Verbose "Analysis completed with $($callGraph.Functions.Count) functions found"
                return $true
            }
        }
        else {
            Write-Verbose "Unity-Claude-Core module not found"
        }
    }
    catch {
        Write-Verbose "Analysis error: $_"
    }
    return $false
}

# Test 6: Cross-Module Dependency Detection
Test-ComponentAvailability "Cross-Module Dependency Detection" {
    try {
        $modules = @(
            "Unity-Claude-Core",
            "Unity-Claude-SystemStatus"
        )
        
        $dependencyMap = Get-ModuleDependencyMap -ModuleNames $modules
        if ($dependencyMap -and $dependencyMap.Dependencies) {
            Write-Verbose "Found $($dependencyMap.Dependencies.Count) dependencies"
            return $true
        }
    }
    catch {
        Write-Verbose "Dependency detection error: $_"
    }
    return $false
}

# Test 7: D3.js Data Export Format
Test-ComponentAvailability "D3.js Data Export Format" {
    try {
        $testData = @{
            Functions = @(
                @{ Name = "Test-Function1"; Module = "TestModule" },
                @{ Name = "Test-Function2"; Module = "TestModule" }
            )
            Dependencies = @(
                @{ From = "Test-Function1"; To = "Test-Function2"; Weight = 1 }
            )
        }
        
        $exportedData = Export-VisualizationData -Data $testData -Format "D3"
        if ($exportedData -and $exportedData.nodes -and $exportedData.links) {
            Write-Verbose "D3.js format validated with $($exportedData.nodes.Count) nodes and $($exportedData.links.Count) links"
            return $true
        }
    }
    catch {
        Write-Verbose "Export format error: $_"
    }
    return $false
}

# Test 8: Visualization Directory Structure
Test-ComponentAvailability "Visualization Directory Structure" {
    $vizPath = Join-Path $PSScriptRoot "Visualization"
    if (Test-Path $vizPath) {
        $requiredDirs = @("public", "public\static", "public\static\data")
        $missingDirs = $requiredDirs | Where-Object { -not (Test-Path (Join-Path $vizPath $_)) }
        
        if ($missingDirs.Count -eq 0) {
            Write-Verbose "All visualization directories present"
            return $true
        }
        else {
            Write-Verbose "Missing directories: $($missingDirs -join ', ')"
        }
    }
    return $false
}

# Test 9: Node.js Availability for Dashboard
Test-ComponentAvailability "Node.js Available for Dashboard" {
    try {
        $nodeVersion = & node --version 2>$null
        if ($nodeVersion) {
            Write-Verbose "Node.js version: $nodeVersion"
            return $true
        }
    }
    catch {
        Write-Verbose "Node.js not available"
    }
    return $false
}

# Test 10: Generate Sample Visualization Data
if ($GenerateSampleData) {
    Test-ComponentAvailability "Generate Sample Visualization Data" {
        try {
            # Get all Unity-Claude modules
            $modulePaths = Get-ChildItem -Path (Join-Path $PSScriptRoot "Modules") -Filter "*.psm1" -Recurse | 
                           Select-Object -First 5 -ExpandProperty FullName
            
            if ($modulePaths) {
                $callGraph = Get-ModuleCallGraph -ModulePaths $modulePaths -CacheResults
                $vizData = Export-VisualizationData -Data $callGraph -Format "D3"
                
                # Save to visualization directory
                $outputPath = Join-Path $PSScriptRoot "Visualization\public\static\data\module-relationships.json"
                $vizData | ConvertTo-Json -Depth 10 | Out-File -FilePath $outputPath -Encoding UTF8
                
                Write-Verbose "Generated visualization data with $($vizData.nodes.Count) nodes"
                return (Test-Path $outputPath)
            }
        }
        catch {
            Write-Verbose "Data generation error: $_"
        }
        return $false
    }
}

# Test 11: Test Visualization Dashboard Script
if ($TestVisualization) {
    Test-ComponentAvailability "Visualization Dashboard Script" {
        $dashboardScript = Join-Path $PSScriptRoot "Start-Visualization-Dashboard.ps1"
        if (Test-Path $dashboardScript) {
            Write-Verbose "Dashboard script found at: $dashboardScript"
            
            # Check if script has required parameters
            $scriptContent = Get-Content $dashboardScript -Raw
            if ($scriptContent -match 'param.*Port.*OpenBrowser.*GenerateData') {
                Write-Verbose "Dashboard script has required parameters"
                return $true
            }
        }
        return $false
    }
}

# Test 12: Performance Metrics
Test-ComponentAvailability "Performance Metrics - AST Analysis Speed" {
    try {
        $testPath = Join-Path $PSScriptRoot "Modules\Unity-Claude-Core\Unity-Claude-Core.psm1"
        if (Test-Path $testPath) {
            $startTime = Get-Date
            $result = Get-ModuleCallGraph -ModulePaths @($testPath) -CacheResults
            $duration = ((Get-Date) - $startTime).TotalMilliseconds
            
            Write-Verbose "Analysis completed in $([math]::Round($duration, 2))ms"
            
            # Target: < 500ms for single module
            return ($duration -lt 500)
        }
    }
    catch {
        Write-Verbose "Performance test error: $_"
    }
    return $false
}

# Summary Report
Write-Host ""
Write-Host "===============================================" -ForegroundColor Cyan
Write-Host "Test Summary" -ForegroundColor Cyan
Write-Host "===============================================" -ForegroundColor Cyan

$duration = ((Get-Date) - $testResults.StartTime).TotalSeconds
$successRate = if ($testResults.TotalTests -gt 0) { 
    [math]::Round(($testResults.PassedTests / $testResults.TotalTests) * 100, 2) 
} else { 0 }

Write-Host "Total Tests: $($testResults.TotalTests)" -ForegroundColor White
Write-Host "Passed: $($testResults.PassedTests)" -ForegroundColor Green
Write-Host "Failed: $($testResults.FailedTests)" -ForegroundColor $(if ($testResults.FailedTests -gt 0) { "Red" } else { "Gray" })
Write-Host "Success Rate: $successRate%" -ForegroundColor $(if ($successRate -ge 80) { "Green" } elseif ($successRate -ge 60) { "Yellow" } else { "Red" })
Write-Host "Duration: $([math]::Round($duration, 2)) seconds" -ForegroundColor White

if ($testResults.Errors.Count -gt 0) {
    Write-Host ""
    Write-Host "Errors Encountered:" -ForegroundColor Red
    $testResults.Errors | ForEach-Object { Write-Host "  - $_" -ForegroundColor Red }
}

# Export results
$resultsPath = Join-Path $PSScriptRoot "Week2-Day10-Integration-Results-$(Get-Date -Format 'yyyyMMdd-HHmmss').json"
$testResults | ConvertTo-Json -Depth 10 | Out-File -FilePath $resultsPath -Encoding UTF8
Write-Host ""
Write-Host "Results saved to: $resultsPath" -ForegroundColor Cyan

# Return success if 80% or more tests pass
exit $(if ($successRate -ge 80) { 0 } else { 1 })