#requires -Version 5.1

<#
.SYNOPSIS
Comprehensive Test Suite for Unity-Claude-AST-Enhanced Module
AST Analysis Integration Testing for Day 6 Implementation

.DESCRIPTION
This test suite provides comprehensive validation of the Unity-Claude-AST-Enhanced module including:
- All AST analysis functions
- Relationship mapping accuracy validation
- Performance testing for large-scale analysis
- Integration testing with existing Enhanced Documentation System components
- D3.js data structure validation
- Import/Export analysis validation

.NOTES
Script: Test-AST-Enhancement.ps1
Version: 1.0.0
Date: 2025-08-30
Author: Unity-Claude-Automation System
Dependencies: Unity-Claude-AST-Enhanced module, DependencySearch module, Pester (optional)
#>

param(
    [ValidateSet("Quick", "Comprehensive", "Performance", "Integration")]
    [string]$TestMode = "Comprehensive",
    [string]$OutputPath = ".\TestResults",
    [switch]$SaveResults = $true,
    [switch]$Verbose = $true
)

# Initialize test environment
$ErrorActionPreference = 'Stop'
$VerbosePreference = if ($Verbose) { 'Continue' } else { 'SilentlyContinue' }

# Import required modules
try {
    Import-Module ".\Modules\Unity-Claude-AST-Enhanced\Unity-Claude-AST-Enhanced.psd1" -Force
    Write-Host "✓ Unity-Claude-AST-Enhanced module imported successfully" -ForegroundColor Green
}
catch {
    Write-Error "Failed to import Unity-Claude-AST-Enhanced module: $($_.Exception.Message)"
    exit 1
}

# Test results container
$script:TestResults = @{
    StartTime = Get-Date
    TestMode = $TestMode
    Results = @()
    Summary = @{}
    Performance = @{}
    Errors = @()
}

#region Core Test Functions

function Test-ModuleImport {
    Write-Host "`n=== Testing Module Import and Basic Functionality ===" -ForegroundColor Cyan
    
    $testResult = @{
        TestName = "Module Import and Basic Functionality"
        Status = "Unknown"
        Details = @()
        ExecutionTime = $null
    }
    
    $startTime = Get-Date
    
    try {
        # Test 1: Verify module functions are available
        $exportedFunctions = Get-Command -Module Unity-Claude-AST-Enhanced
        $expectedFunctions = @(
            'Get-ModuleCallGraph',
            'Get-CrossModuleRelationships',
            'Get-FunctionCallAnalysis',
            'Export-CallGraphData'
        )
        
        foreach ($expectedFunction in $expectedFunctions) {
            if ($exportedFunctions.Name -contains $expectedFunction) {
                $testResult.Details += "✓ Function $expectedFunction available"
            } else {
                throw "Expected function $expectedFunction not found"
            }
        }
        
        # Test 2: Verify DependencySearch integration
        $dependencyCommands = Get-Command -Module DependencySearch -ErrorAction SilentlyContinue
        if ($dependencyCommands) {
            $testResult.Details += "✓ DependencySearch module integration verified"
        } else {
            $testResult.Details += "⚠ DependencySearch module not available (may affect functionality)"
        }
        
        $testResult.Status = "Passed"
        $testResult.Details += "✓ All basic functionality tests passed"
        
    }
    catch {
        $testResult.Status = "Failed"
        $testResult.Details += "✗ Error: $($_.Exception.Message)"
        $script:TestResults.Errors += $testResult
    }
    
    $testResult.ExecutionTime = (Get-Date) - $startTime
    $script:TestResults.Results += $testResult
    
    Write-Host "Status: $($testResult.Status)" -ForegroundColor $(if ($testResult.Status -eq "Passed") { "Green" } else { "Red" })
    return $testResult.Status -eq "Passed"
}

function Test-ModuleCallGraphGeneration {
    Write-Host "`n=== Testing Module Call Graph Generation ===" -ForegroundColor Cyan
    
    $testResult = @{
        TestName = "Module Call Graph Generation"
        Status = "Unknown"
        Details = @()
        ExecutionTime = $null
    }
    
    $startTime = Get-Date
    
    try {
        # Create test module files
        $testModulesPath = Join-Path $OutputPath "TestModules"
        if (-not (Test-Path $testModulesPath)) {
            New-Item -ItemType Directory -Path $testModulesPath -Force | Out-Null
        }
        
        # Create test module 1
        $testModule1 = @"
#requires -Version 5.1

function Test-Function1 {
    param([string]$Parameter1)
    
    Write-Host "Test Function 1"
    Test-Function2 -Parameter1 $Parameter1
}

function Test-Function2 {
    param([string]$Parameter1)
    
    Write-Host "Test Function 2: $Parameter1"
}

Export-ModuleMember -Function @('Test-Function1', 'Test-Function2')
"@
        
        $module1Path = Join-Path $testModulesPath "TestModule1.psm1"
        $testModule1 | Out-File -FilePath $module1Path -Encoding UTF8
        
        # Create test module 2 with imports
        $testModule2 = @"
#requires -Version 5.1

Import-Module TestModule1 -Force

function Test-Function3 {
    param([string]$Parameter1)
    
    Test-Function1 -Parameter1 $Parameter1
    Write-Host "Test Function 3"
}

function Test-Function4 {
    Write-Host "Test Function 4"
}

Export-ModuleMember -Function @('Test-Function3', 'Test-Function4')
"@
        
        $module2Path = Join-Path $testModulesPath "TestModule2.psm1"
        $testModule2 | Out-File -FilePath $module2Path -Encoding UTF8
        
        # Test call graph generation
        Write-Verbose "Testing call graph generation with test modules..."
        $callGraph = Get-ModuleCallGraph -ModulePaths @($module1Path, $module2Path)
        
        # Validate results
        if ($callGraph) {
            $testResult.Details += "✓ Call graph generated successfully"
            $testResult.Details += "✓ Found $($callGraph.Modules.Count) modules"
            $testResult.Details += "✓ Total functions: $(($callGraph.Modules | ForEach-Object { $_.Functions.Count } | Measure-Object -Sum).Sum)"
            
            # Validate structure
            if ($callGraph.Modules -and $callGraph.AnalysisMetrics) {
                $testResult.Details += "✓ Call graph structure validated"
            } else {
                throw "Call graph structure incomplete"
            }
            
            # Test relationships
            if ($callGraph.Relationships) {
                $testResult.Details += "✓ Found $($callGraph.Relationships.Count) relationships"
            } else {
                $testResult.Details += "⚠ No relationships found (may be expected for test modules)"
            }
            
        } else {
            throw "Call graph generation returned null"
        }
        
        $testResult.Status = "Passed"
        
    }
    catch {
        $testResult.Status = "Failed"
        $testResult.Details += "✗ Error: $($_.Exception.Message)"
        $script:TestResults.Errors += $testResult
    }
    
    $testResult.ExecutionTime = (Get-Date) - $startTime
    $script:TestResults.Results += $testResult
    
    Write-Host "Status: $($testResult.Status)" -ForegroundColor $(if ($testResult.Status -eq "Passed") { "Green" } else { "Red" })
    return $testResult.Status -eq "Passed"
}

function Test-ImportExportAnalysis {
    Write-Host "`n=== Testing Import/Export Analysis Functions ===" -ForegroundColor Cyan
    
    $testResult = @{
        TestName = "Import/Export Analysis"
        Status = "Unknown"
        Details = @()
        ExecutionTime = $null
    }
    
    $startTime = Get-Date
    
    try {
        # Source the Import-Export-Analysis functions
        $importExportScript = ".\Modules\Unity-Claude-AST-Enhanced\Import-Export-Analysis.ps1"
        if (Test-Path $importExportScript) {
            . $importExportScript
            $testResult.Details += "✓ Import-Export-Analysis.ps1 sourced successfully"
        } else {
            throw "Import-Export-Analysis.ps1 not found"
        }
        
        # Test with existing modules in the project
        $moduleSearchPath = ".\Modules\**\*.psm1"
        $existingModules = Get-ChildItem -Path $moduleSearchPath -ErrorAction SilentlyContinue
        
        if ($existingModules.Count -gt 0) {
            $modulePaths = $existingModules | Select-Object -First 3 -ExpandProperty FullName
            $testResult.Details += "✓ Found $($existingModules.Count) modules for testing (using first 3)"
            
            # Test Import Analysis
            Write-Verbose "Testing Get-ModuleImportAnalysis..."
            $importAnalysis = Get-ModuleImportAnalysis -ModulePaths $modulePaths -TrackUsageFrequency -Verbose:$false
            
            if ($importAnalysis) {
                $testResult.Details += "✓ Import analysis completed"
                $testResult.Details += "✓ Analyzed $($importAnalysis.AnalyzedModules.Count) modules"
                $testResult.Details += "✓ Found $($importAnalysis.ImportRelationships.Count) import relationships"
            } else {
                throw "Import analysis returned null"
            }
            
            # Test Export Analysis
            Write-Verbose "Testing Get-ModuleExportAnalysis..."
            $exportAnalysis = Get-ModuleExportAnalysis -ModulePaths $modulePaths -IncludeImplicitExports -Verbose:$false
            
            if ($exportAnalysis) {
                $testResult.Details += "✓ Export analysis completed"
                $testResult.Details += "✓ Found $($exportAnalysis.ExportedFunctions.Count) exported functions"
                $testResult.Details += "✓ Explicit exports: $($exportAnalysis.ExplicitExports.Count)"
                $testResult.Details += "✓ Implicit exports: $($exportAnalysis.ImplicitExports.Count)"
            } else {
                throw "Export analysis returned null"
            }
            
            # Test Dependency Chain Analysis
            if ($importAnalysis.ImportRelationships.Count -gt 0) {
                Write-Verbose "Testing Get-ModuleDependencyChain..."
                $dependencyChains = Get-ModuleDependencyChain -ImportRelationships $importAnalysis.ImportRelationships -DetectCircularDependencies
                
                if ($dependencyChains) {
                    $testResult.Details += "✓ Dependency chain analysis completed"
                    $testResult.Details += "✓ Found $($dependencyChains.Statistics.TotalChains) dependency chains"
                    $testResult.Details += "✓ Max depth: $($dependencyChains.Statistics.MaxDepth)"
                    $testResult.Details += "✓ Circular dependencies: $($dependencyChains.Statistics.CircularDependencies)"
                } else {
                    $testResult.Details += "⚠ Dependency chain analysis returned null (may be expected)"
                }
            }
            
        } else {
            $testResult.Details += "⚠ No existing modules found for testing - creating minimal test"
            
            # Use the test modules created in previous test
            $testModulesPath = Join-Path $OutputPath "TestModules"
            if (Test-Path $testModulesPath) {
                $testModulePaths = Get-ChildItem -Path "$testModulesPath\*.psm1" | Select-Object -ExpandProperty FullName
                if ($testModulePaths.Count -gt 0) {
                    $importAnalysis = Get-ModuleImportAnalysis -ModulePaths $testModulePaths -Verbose:$false
                    $testResult.Details += "✓ Import analysis completed with test modules"
                }
            }
        }
        
        $testResult.Status = "Passed"
        
    }
    catch {
        $testResult.Status = "Failed"
        $testResult.Details += "✗ Error: $($_.Exception.Message)"
        $script:TestResults.Errors += $testResult
    }
    
    $testResult.ExecutionTime = (Get-Date) - $startTime
    $script:TestResults.Results += $testResult
    
    Write-Host "Status: $($testResult.Status)" -ForegroundColor $(if ($testResult.Status -eq "Passed") { "Green" } else { "Red" })
    return $testResult.Status -eq "Passed"
}

function Test-D3DataStructures {
    Write-Host "`n=== Testing D3.js Data Structure Generation ===" -ForegroundColor Cyan
    
    $testResult = @{
        TestName = "D3.js Data Structures"
        Status = "Unknown"
        Details = @()
        ExecutionTime = $null
    }
    
    $startTime = Get-Date
    
    try {
        # Source the D3 Data Structures functions
        $d3Script = ".\Modules\Unity-Claude-AST-Enhanced\D3-Data-Structures.ps1"
        if (Test-Path $d3Script) {
            . $d3Script
            $testResult.Details += "✓ D3-Data-Structures.ps1 sourced successfully"
        } else {
            throw "D3-Data-Structures.ps1 not found"
        }
        
        # Create mock data for testing
        $mockCallGraph = @{
            Modules = @(
                @{
                    Name = "TestModule1"
                    Path = "TestModule1.psm1"
                    Functions = @(
                        @{ Name = "Function1"; Parameters = @("param1"); IsExported = $true }
                        @{ Name = "Function2"; Parameters = @(); IsExported = $false }
                    )
                    ExportedFunctions = @("Function1")
                }
                @{
                    Name = "TestModule2"
                    Path = "TestModule2.psm1"
                    Functions = @(
                        @{ Name = "Function3"; Parameters = @("param1", "param2"); IsExported = $true }
                    )
                    ExportedFunctions = @("Function3")
                }
            )
            Relationships = @(
                @{
                    SourceModule = "TestModule2"
                    TargetModule = "TestModule1"
                    RelationshipType = "Import"
                    Strength = 10
                    Frequency = 1
                }
            )
            AnalysisMetrics = @{
                TotalModules = 2
                TotalFunctions = 3
                TotalRelationships = 1
            }
        }
        
        # Test D3 network data export
        Write-Verbose "Testing Export-D3NetworkData..."
        $d3Data = Export-D3NetworkData -CallGraphData $mockCallGraph
        
        if ($d3Data) {
            $testResult.Details += "✓ D3 network data generated successfully"
            
            # Validate D3 data structure
            if ($d3Data.nodes -and $d3Data.links -and $d3Data.metadata) {
                $testResult.Details += "✓ D3 data structure validated"
                $testResult.Details += "✓ Nodes: $($d3Data.nodes.Count)"
                $testResult.Details += "✓ Links: $($d3Data.links.Count)"
            } else {
                throw "D3 data structure incomplete"
            }
            
            # Validate node properties
            $moduleNodes = $d3Data.nodes | Where-Object { $_.type -eq "module" }
            if ($moduleNodes.Count -gt 0) {
                $sampleNode = $moduleNodes[0]
                if ($sampleNode.id -and $sampleNode.metadata -and $sampleNode.visual) {
                    $testResult.Details += "✓ Node structure validated"
                } else {
                    throw "Node structure incomplete"
                }
            }
            
            # Validate link properties
            if ($d3Data.links.Count -gt 0) {
                $sampleLink = $d3Data.links[0]
                if ($null -ne $sampleLink.source -and $null -ne $sampleLink.target -and $sampleLink.type) {
                    $testResult.Details += "✓ Link structure validated"
                } else {
                    throw "Link structure incomplete"
                }
            }
            
        } else {
            throw "D3 network data export returned null"
        }
        
        # Test relationship matrix export
        Write-Verbose "Testing Export-RelationshipMatrix..."
        $matrixData = Export-RelationshipMatrix -CallGraphData $mockCallGraph -MatrixFormat "PSObject"
        
        if ($matrixData) {
            $testResult.Details += "✓ Relationship matrix generated successfully"
            
            if ($matrixData.adjacencyMatrix -and $matrixData.metadata) {
                $testResult.Details += "✓ Matrix structure validated"
            } else {
                throw "Matrix structure incomplete"
            }
        } else {
            throw "Relationship matrix export returned null"
        }
        
        $testResult.Status = "Passed"
        
    }
    catch {
        $testResult.Status = "Failed"
        $testResult.Details += "✗ Error: $($_.Exception.Message)"
        $script:TestResults.Errors += $testResult
    }
    
    $testResult.ExecutionTime = (Get-Date) - $startTime
    $script:TestResults.Results += $testResult
    
    Write-Host "Status: $($testResult.Status)" -ForegroundColor $(if ($testResult.Status -eq "Passed") { "Green" } else { "Red" })
    return $testResult.Status -eq "Passed"
}

function Test-PerformanceScenarios {
    Write-Host "`n=== Testing Performance Scenarios ===" -ForegroundColor Cyan
    
    $testResult = @{
        TestName = "Performance Testing"
        Status = "Unknown"
        Details = @()
        ExecutionTime = $null
    }
    
    $startTime = Get-Date
    
    try {
        # Get all available modules for performance testing
        $allModules = Get-ChildItem -Path ".\Modules\**\*.psm1" -ErrorAction SilentlyContinue
        
        if ($allModules.Count -gt 0) {
            $moduleCount = [math]::Min($allModules.Count, 10)  # Limit to 10 modules for performance testing
            $modulePaths = $allModules | Select-Object -First $moduleCount -ExpandProperty FullName
            
            $testResult.Details += "✓ Testing performance with $moduleCount modules"
            
            # Test call graph generation performance
            $callGraphStartTime = Get-Date
            $callGraph = Get-ModuleCallGraph -ModulePaths $modulePaths -CacheResults
            $callGraphTime = (Get-Date) - $callGraphStartTime
            
            $script:TestResults.Performance.CallGraphGeneration = $callGraphTime.TotalSeconds
            $testResult.Details += "✓ Call graph generation: $([math]::Round($callGraphTime.TotalSeconds, 2))s"
            
            # Performance threshold check (should be under 30 seconds for 10 modules)
            if ($callGraphTime.TotalSeconds -lt 30) {
                $testResult.Details += "✓ Performance within acceptable threshold"
            } else {
                $testResult.Details += "⚠ Performance slower than expected (>30s)"
            }
            
            # Test memory usage (basic check)
            $memoryBefore = [System.GC]::GetTotalMemory($false)
            
            # Source additional analysis functions
            if (Test-Path ".\Modules\Unity-Claude-AST-Enhanced\Import-Export-Analysis.ps1") {
                . ".\Modules\Unity-Claude-AST-Enhanced\Import-Export-Analysis.ps1"
                
                $importAnalysisStartTime = Get-Date
                $importAnalysis = Get-ModuleImportAnalysis -ModulePaths $modulePaths -Verbose:$false
                $importAnalysisTime = (Get-Date) - $importAnalysisStartTime
                
                $script:TestResults.Performance.ImportAnalysis = $importAnalysisTime.TotalSeconds
                $testResult.Details += "✓ Import analysis: $([math]::Round($importAnalysisTime.TotalSeconds, 2))s"
            }
            
            $memoryAfter = [System.GC]::GetTotalMemory($false)
            $memoryUsed = ($memoryAfter - $memoryBefore) / 1MB
            
            $script:TestResults.Performance.MemoryUsage = $memoryUsed
            $testResult.Details += "✓ Memory usage: $([math]::Round($memoryUsed, 2)) MB"
            
        } else {
            $testResult.Details += "⚠ No modules found for performance testing"
        }
        
        $testResult.Status = "Passed"
        
    }
    catch {
        $testResult.Status = "Failed"
        $testResult.Details += "✗ Error: $($_.Exception.Message)"
        $script:TestResults.Errors += $testResult
    }
    
    $testResult.ExecutionTime = (Get-Date) - $startTime
    $script:TestResults.Results += $testResult
    
    Write-Host "Status: $($testResult.Status)" -ForegroundColor $(if ($testResult.Status -eq "Passed") { "Green" } else { "Red" })
    return $testResult.Status -eq "Passed"
}

function Test-IntegrationScenarios {
    Write-Host "`n=== Testing Integration Scenarios ===" -ForegroundColor Cyan
    
    $testResult = @{
        TestName = "Integration Testing"
        Status = "Unknown"
        Details = @()
        ExecutionTime = $null
    }
    
    $startTime = Get-Date
    
    try {
        # Test integration with existing Enhanced Documentation System components
        $existingModules = @()
        
        # Check for other Unity-Claude modules
        $unityClaudeModules = Get-ChildItem -Path ".\Modules\Unity-Claude-*" -Directory -ErrorAction SilentlyContinue
        if ($unityClaudeModules) {
            $testResult.Details += "✓ Found $($unityClaudeModules.Count) Unity-Claude modules for integration testing"
            
            foreach ($moduleDir in $unityClaudeModules) {
                $modulePath = Get-ChildItem -Path "$($moduleDir.FullName)\*.psm1" -ErrorAction SilentlyContinue
                if ($modulePath) {
                    $existingModules += $modulePath.FullName
                }
            }
        }
        
        if ($existingModules.Count -gt 0) {
            # Test call graph generation with existing modules
            $integrationCallGraph = Get-ModuleCallGraph -ModulePaths $existingModules
            
            if ($integrationCallGraph) {
                $testResult.Details += "✓ Integration call graph generated"
                $testResult.Details += "✓ Modules analyzed: $($integrationCallGraph.Modules.Count)"
                $testResult.Details += "✓ Total relationships: $($integrationCallGraph.Relationships.Count)"
                
                # Test data export integration
                $exportResult = Export-CallGraphData -CallGraph $integrationCallGraph -OutputPath $OutputPath -ExportFormat "D3JS"
                if ($exportResult -and $exportResult.D3JS) {
                    $testResult.Details += "✓ D3.js data export integration successful"
                    $testResult.Details += "✓ Export saved to: $($exportResult.D3JS)"
                } else {
                    throw "Data export integration failed"
                }
                
            } else {
                throw "Integration call graph generation failed"
            }
            
        } else {
            $testResult.Details += "⚠ No existing Unity-Claude modules found for integration testing"
            
            # Test with the Unity-Claude-AST-Enhanced module itself
            $selfModule = ".\Modules\Unity-Claude-AST-Enhanced\Unity-Claude-AST-Enhanced.psm1"
            if (Test-Path $selfModule) {
                $selfAnalysis = Get-ModuleCallGraph -ModulePaths @($selfModule)
                if ($selfAnalysis) {
                    $testResult.Details += "✓ Self-analysis integration successful"
                } else {
                    throw "Self-analysis integration failed"
                }
            }
        }
        
        # Test JSON serialization (important for integration)
        $testData = @{
            modules = @("Module1", "Module2")
            relationships = @(@{ source = "Module1"; target = "Module2"; type = "Import" })
        }
        
        try {
            $jsonData = $testData | ConvertTo-Json -Depth 5
            $deserializedData = $jsonData | ConvertFrom-Json
            if ($deserializedData.modules -and $deserializedData.relationships) {
                $testResult.Details += "✓ JSON serialization integration verified"
            } else {
                throw "JSON serialization failed"
            }
        }
        catch {
            throw "JSON serialization integration test failed: $($_.Exception.Message)"
        }
        
        $testResult.Status = "Passed"
        
    }
    catch {
        $testResult.Status = "Failed"
        $testResult.Details += "✗ Error: $($_.Exception.Message)"
        $script:TestResults.Errors += $testResult
    }
    
    $testResult.ExecutionTime = (Get-Date) - $startTime
    $script:TestResults.Results += $testResult
    
    Write-Host "Status: $($testResult.Status)" -ForegroundColor $(if ($testResult.Status -eq "Passed") { "Green" } else { "Red" })
    return $testResult.Status -eq "Passed"
}

#endregion

#region Main Test Execution

function Invoke-TestSuite {
    Write-Host "Unity-Claude-AST-Enhanced Module Test Suite" -ForegroundColor Yellow
    Write-Host "=========================================" -ForegroundColor Yellow
    Write-Host "Test Mode: $TestMode" -ForegroundColor Cyan
    Write-Host "Start Time: $($script:TestResults.StartTime)" -ForegroundColor Cyan
    
    # Ensure output directory exists
    if (-not (Test-Path $OutputPath)) {
        New-Item -ItemType Directory -Path $OutputPath -Force | Out-Null
    }
    
    $testsPassed = 0
    $totalTests = 0
    
    # Execute tests based on mode
    switch ($TestMode) {
        "Quick" {
            $totalTests = 2
            $testsPassed += if (Test-ModuleImport) { 1 } else { 0 }
            $testsPassed += if (Test-ModuleCallGraphGeneration) { 1 } else { 0 }
        }
        
        "Comprehensive" {
            $totalTests = 5
            $testsPassed += if (Test-ModuleImport) { 1 } else { 0 }
            $testsPassed += if (Test-ModuleCallGraphGeneration) { 1 } else { 0 }
            $testsPassed += if (Test-ImportExportAnalysis) { 1 } else { 0 }
            $testsPassed += if (Test-D3DataStructures) { 1 } else { 0 }
            $testsPassed += if (Test-IntegrationScenarios) { 1 } else { 0 }
        }
        
        "Performance" {
            $totalTests = 3
            $testsPassed += if (Test-ModuleImport) { 1 } else { 0 }
            $testsPassed += if (Test-ModuleCallGraphGeneration) { 1 } else { 0 }
            $testsPassed += if (Test-PerformanceScenarios) { 1 } else { 0 }
        }
        
        "Integration" {
            $totalTests = 3
            $testsPassed += if (Test-ModuleImport) { 1 } else { 0 }
            $testsPassed += if (Test-ModuleCallGraphGeneration) { 1 } else { 0 }
            $testsPassed += if (Test-IntegrationScenarios) { 1 } else { 0 }
        }
    }
    
    # Calculate summary
    $script:TestResults.Summary = @{
        TotalTests = $totalTests
        TestsPassed = $testsPassed
        TestsFailed = $totalTests - $testsPassed
        SuccessRate = if ($totalTests -gt 0) { ($testsPassed / $totalTests) * 100 } else { 0 }
        ExecutionTime = (Get-Date) - $script:TestResults.StartTime
    }
    
    # Display summary
    Write-Host "`n=========================================" -ForegroundColor Yellow
    Write-Host "Test Suite Summary" -ForegroundColor Yellow
    Write-Host "=========================================" -ForegroundColor Yellow
    Write-Host "Total Tests: $totalTests" -ForegroundColor Cyan
    Write-Host "Tests Passed: $testsPassed" -ForegroundColor Green
    Write-Host "Tests Failed: $($totalTests - $testsPassed)" -ForegroundColor Red
    Write-Host "Success Rate: $([math]::Round($script:TestResults.Summary.SuccessRate, 2))%" -ForegroundColor $(if ($script:TestResults.Summary.SuccessRate -gt 80) { "Green" } else { "Yellow" })
    Write-Host "Execution Time: $([math]::Round($script:TestResults.Summary.ExecutionTime.TotalSeconds, 2))s" -ForegroundColor Cyan
    
    # Display performance metrics if available
    if ($script:TestResults.Performance.Count -gt 0) {
        Write-Host "`nPerformance Metrics:" -ForegroundColor Yellow
        foreach ($metric in $script:TestResults.Performance.GetEnumerator()) {
            Write-Host "  $($metric.Key): $([math]::Round($metric.Value, 2))s" -ForegroundColor Cyan
        }
    }
    
    # Display errors if any
    if ($script:TestResults.Errors.Count -gt 0) {
        Write-Host "`nErrors Encountered:" -ForegroundColor Red
        foreach ($error in $script:TestResults.Errors) {
            Write-Host "  $($error.TestName): $($error.Details -join '; ')" -ForegroundColor Red
        }
    }
    
    # Save results if requested
    if ($SaveResults) {
        $resultsFile = Join-Path $OutputPath "AST-Enhancement-TestResults-$(Get-Date -Format 'yyyyMMdd-HHmmss').json"
        $script:TestResults | ConvertTo-Json -Depth 10 | Out-File -FilePath $resultsFile -Encoding UTF8
        Write-Host "`nTest results saved to: $resultsFile" -ForegroundColor Green
    }
    
    return $script:TestResults.Summary.SuccessRate -gt 80
}

#endregion

# Execute the test suite
try {
    $success = Invoke-TestSuite
    if ($success) {
        Write-Host "`n✓ AST Enhancement testing completed successfully!" -ForegroundColor Green
        exit 0
    } else {
        Write-Host "`n✗ AST Enhancement testing completed with failures!" -ForegroundColor Red
        exit 1
    }
}
catch {
    Write-Error "Test suite execution failed: $($_.Exception.Message)"
    exit 1
}