#Requires -Version 5.1
<#
.SYNOPSIS
    Test script for Unified CPG Module with Advanced Edge Types

.DESCRIPTION
    Tests the complete CPG implementation including base classes and advanced edges

.NOTES
    Part of Enhanced Documentation System Second Pass Implementation
    Created: 2025-08-28
#>

# Import the unified module
$modulePath = Split-Path -Parent $MyInvocation.MyCommand.Path
Write-Host "[TEST] Loading CPG-Unified module from: $modulePath\Core\CPG-Unified.psm1" -ForegroundColor Cyan
Import-Module "$modulePath\Core\CPG-Unified.psm1" -Force -Verbose

Write-Host "[TEST] Module loaded. Enabling debug mode..." -ForegroundColor Cyan
if (Get-Command Set-CPGDebug -ErrorAction SilentlyContinue) {
    Set-CPGDebug -Enable $true
    Write-Host "[TEST] Debug mode enabled" -ForegroundColor Green
} else {
    Write-Host "[TEST] Warning: Set-CPGDebug not available" -ForegroundColor Yellow
}

# Test results storage
$testResults = @{
    Passed = 0
    Failed = 0
    Tests = @()
}

function Test-Assert {
    param(
        [string]$TestName,
        [scriptblock]$Condition,
        [string]$ErrorMessage = "Test failed"
    )
    
    try {
        $result = & $Condition
        if ($result) {
            $testResults.Passed++
            $testResults.Tests += @{
                Name = $TestName
                Passed = $true
                Message = "OK"
            }
            Write-Host "[PASS] $TestName" -ForegroundColor Green
        } else {
            $testResults.Failed++
            $testResults.Tests += @{
                Name = $TestName
                Passed = $false
                Message = $ErrorMessage
            }
            Write-Host "[FAIL] $TestName - $ErrorMessage" -ForegroundColor Red
        }
    } catch {
        $testResults.Failed++
        $testResults.Tests += @{
            Name = $TestName
            Passed = $false
            Message = $_.Exception.Message
        }
        Write-Host "[ERROR] $TestName - $($_.Exception.Message)" -ForegroundColor Red
    }
}

Write-Host "`n=== Testing Unified CPG Module ===" -ForegroundColor Cyan

# Test 1: Basic Node Creation
Write-Host "`n[Test Group: Basic CPG Components]" -ForegroundColor Yellow

$module = New-CPGNode -Name "TestModule" -Type Module -FilePath "test.ps1" -StartLine 1 -EndLine 100
Test-Assert "Basic Node Creation" {
    $module -ne $null -and
    $module.GetType().Name -eq 'CPGNode' -and
    $module.Name -eq "TestModule" -and
    $module.Type -eq [CPGNodeType]::Module
}

$function = New-CPGNode -Name "TestFunction" -Type Function
Test-Assert "Function Node Creation" {
    $function -ne $null -and
    $function.Type -eq [CPGNodeType]::Function
}

# Test 2: Basic Edge Creation
$basicEdge = New-CPGEdge -SourceId $module.Id -TargetId $function.Id -Type Contains
Test-Assert "Basic Edge Creation" {
    $basicEdge -ne $null -and
    $basicEdge.GetType().Name -eq 'CPGEdge' -and
    $basicEdge.Type -eq [CPGEdgeType]::Contains
}

# Test 3: Graph Creation
Write-Host "`n[Test Group: Graph Operations]" -ForegroundColor Yellow

$graph = New-CPGraph -Name "TestGraph"
Test-Assert "Graph Creation" {
    $graph -ne $null -and
    $graph.GetType().Name -eq 'CPGraph' -and
    $graph.Name -eq "TestGraph"
}

$graph.Nodes[$module.Id] = $module
$graph.Nodes[$function.Id] = $function
$graph.Edges[$basicEdge.Id] = $basicEdge

Test-Assert "Graph Population" {
    $graph.Nodes.Count -eq 2 -and
    $graph.Edges.Count -eq 1
}

# Test 4: DataFlow Edge with Inheritance
Write-Host "`n[Test Group: Advanced Edge Types - DataFlow]" -ForegroundColor Yellow

$variableA = New-CPGNode -Name "VariableA" -Type Variable
$variableB = New-CPGNode -Name "VariableB" -Type Variable

$dataFlowEdge = New-DataFlowEdge `
    -SourceId $variableA.Id `
    -TargetId $variableB.Id `
    -FlowType DataFlowDirect `
    -DataType "string" `
    -IsMutable $false `
    -IsAsync $false

Test-Assert "DataFlow Edge Creation" {
    $dataFlowEdge -ne $null -and
    $dataFlowEdge.GetType().Name -eq 'DataFlowEdge'
}

Test-Assert "DataFlow Edge Inheritance" {
    $dataFlowEdge -is [CPGEdge] -and
    $dataFlowEdge.Type -eq [CPGEdgeType]::DataFlow
}

Test-Assert "DataFlow Edge Properties" {
    $dataFlowEdge.AdvancedType -eq [AdvancedEdgeType]::DataFlowDirect -and
    $dataFlowEdge.DataType -eq "string" -and
    $dataFlowEdge.IsMutable -eq $false
}

$dataFlowEdge.AddTransformation("ToUpper")
$dataFlowEdge.AddTransformation("Trim")

Test-Assert "DataFlow Transformations" {
    $dataFlowEdge.TransformationPath.Count -eq 2 -and
    $dataFlowEdge.FlowMetrics.Complexity -eq 2
}

$flowAnalysis = $dataFlowEdge.AnalyzeFlow()
Test-Assert "DataFlow Analysis" {
    $flowAnalysis.Type -eq "DataFlowDirect" -and
    $flowAnalysis.Transformations -eq 2
}

# Test 5: ControlFlow Edge with Inheritance
Write-Host "`n[Test Group: Advanced Edge Types - ControlFlow]" -ForegroundColor Yellow

$ifStatement = New-CPGNode -Name "IfStatement" -Type Function
$thenBlock = New-CPGNode -Name "ThenBlock" -Type Function
$elseBlock = New-CPGNode -Name "ElseBlock" -Type Function

$controlFlowEdge = New-ControlFlowEdge `
    -SourceId $ifStatement.Id `
    -TargetId $thenBlock.Id `
    -FlowType ControlFlowConditional `
    -Condition "x > 0" `
    -ExecutionProbability 0.7

Test-Assert "ControlFlow Edge Creation" {
    $controlFlowEdge -ne $null -and
    $controlFlowEdge.GetType().Name -eq 'ControlFlowEdge'
}

Test-Assert "ControlFlow Edge Inheritance" {
    $controlFlowEdge -is [CPGEdge] -and
    $controlFlowEdge.Type -eq [CPGEdgeType]::Follows
}

Test-Assert "ControlFlow Conditional Properties" {
    $controlFlowEdge.IsConditional -eq $true -and
    $controlFlowEdge.Condition -eq "x > 0" -and
    $controlFlowEdge.ExecutionProbability -eq 0.7
}

$loopEdge = New-ControlFlowEdge `
    -SourceId $thenBlock.Id `
    -TargetId $ifStatement.Id `
    -FlowType ControlFlowLoop

Test-Assert "ControlFlow Loop Detection" {
    $loopEdge.IsLoop -eq $true
}

# Test 6: Inheritance Edge
Write-Host "`n[Test Group: Advanced Edge Types - Inheritance]" -ForegroundColor Yellow

$baseClass = New-CPGNode -Name "BaseClass" -Type Class
$derivedClass = New-CPGNode -Name "DerivedClass" -Type Class

$inheritanceEdge = New-InheritanceEdge `
    -SourceId $derivedClass.Id `
    -TargetId $baseClass.Id `
    -InheritanceType InheritanceExtends `
    -BaseType "BaseClass" `
    -DerivedType "DerivedClass"

Test-Assert "Inheritance Edge Creation" {
    $inheritanceEdge -ne $null -and
    $inheritanceEdge.GetType().Name -eq 'InheritanceEdge'
}

Test-Assert "Inheritance Edge Base Type" {
    $inheritanceEdge -is [CPGEdge] -and
    $inheritanceEdge.Type -eq [CPGEdgeType]::Extends
}

$inheritanceEdge.AddInheritedMember("MethodA")
$inheritanceEdge.AddInheritedMember("PropertyB")
$inheritanceEdge.AddOverriddenMember("MethodA")

Test-Assert "Inheritance Members" {
    $inheritanceEdge.InheritedMembers.Count -eq 2 -and
    $inheritanceEdge.OverriddenMembers.Count -eq 1
}

# Test 7: Implementation Edge
Write-Host "`n[Test Group: Advanced Edge Types - Implementation]" -ForegroundColor Yellow

$interface = New-CPGNode -Name "ILogger" -Type Interface
$implementation = New-CPGNode -Name "FileLogger" -Type Class

$implementationEdge = New-ImplementationEdge `
    -SourceId $implementation.Id `
    -TargetId $interface.Id `
    -ImplementationType ImplementationInterface `
    -InterfaceName "ILogger" `
    -ImplementorName "FileLogger" `
    -RequiredMethods @("Log", "LogError", "LogWarning")

Test-Assert "Implementation Edge Creation" {
    $implementationEdge -ne $null -and
    $implementationEdge.GetType().Name -eq 'ImplementationEdge'
}

Test-Assert "Implementation Edge Inheritance" {
    $implementationEdge -is [CPGEdge] -and
    $implementationEdge.Type -eq [CPGEdgeType]::Implements
}

$implementationEdge.ImplementedMethods = @("Log", "LogError")
$implementationEdge.ValidateImplementation()

Test-Assert "Implementation Validation" {
    $implementationEdge.IsComplete -eq $false -and
    [Math]::Round($implementationEdge.ComplianceMetrics.Coverage, 2) -eq 66.67
}

# Test 8: Composition Edge
Write-Host "`n[Test Group: Advanced Edge Types - Composition]" -ForegroundColor Yellow

$container = New-CPGNode -Name "Car" -Type Class
$component = New-CPGNode -Name "Engine" -Type Class

$compositionEdge = New-CompositionEdge `
    -SourceId $container.Id `
    -TargetId $component.Id `
    -CompositionType CompositionHasA `
    -ContainerType "Car" `
    -ComponentType "Engine" `
    -Cardinality "1"

Test-Assert "Composition Edge Creation" {
    $compositionEdge -ne $null -and
    $compositionEdge.GetType().Name -eq 'CompositionEdge'
}

Test-Assert "Composition Edge Inheritance" {
    $compositionEdge -is [CPGEdge] -and
    $compositionEdge.Type -eq [CPGEdgeType]::Contains
}

Test-Assert "Composition Ownership" {
    $compositionEdge.IsOwnership -eq $true -and
    $compositionEdge.IsShared -eq $false
}

# Test 9: Mixed Graph with All Edge Types
Write-Host "`n[Test Group: Unified Graph Operations]" -ForegroundColor Yellow

$unifiedGraph = New-CPGraph -Name "UnifiedTestGraph"

# Add all nodes
$allNodes = @($module, $function, $variableA, $variableB, $ifStatement, 
              $thenBlock, $elseBlock, $baseClass, $derivedClass, 
              $interface, $implementation, $container, $component)

foreach ($node in $allNodes) {
    $unifiedGraph.Nodes[$node.Id] = $node
}

# Add all edges
$allEdges = @($basicEdge, $dataFlowEdge, $controlFlowEdge, $loopEdge,
              $inheritanceEdge, $implementationEdge, $compositionEdge)

foreach ($edge in $allEdges) {
    $unifiedGraph.Edges[$edge.Id] = $edge
}

Test-Assert "Unified Graph Construction" {
    $unifiedGraph.Nodes.Count -eq 13 -and
    $unifiedGraph.Edges.Count -eq 7
}

Test-Assert "Edge Type Diversity" {
    $edgeTypes = $unifiedGraph.Edges.Values | ForEach-Object { $_.GetType().Name } | Sort-Object -Unique
    $edgeTypes.Count -eq 6  # CPGEdge, DataFlowEdge, ControlFlowEdge, InheritanceEdge, ImplementationEdge, CompositionEdge
}

Test-Assert "Base Type Compatibility" {
    $allEdgesAreCPGEdges = $true
    foreach ($edge in $unifiedGraph.Edges.Values) {
        if (-not ($edge -is [CPGEdge])) {
            $allEdgesAreCPGEdges = $false
            break
        }
    }
    $allEdgesAreCPGEdges -eq $true
}

# Test 10: Serialization
Write-Host "`n[Test Group: Serialization]" -ForegroundColor Yellow

Test-Assert "Node Serialization" {
    $nodeHash = $module.ToHashtable()
    $nodeHash.Name -eq "TestModule" -and
    $nodeHash.Type -eq "Module"
}

Test-Assert "Edge Serialization" {
    $edgeHash = $basicEdge.ToHashtable()
    $edgeHash.Type -eq "Contains" -and
    $edgeHash.ContainsKey("SourceId") -and
    $edgeHash.ContainsKey("TargetId")
}

Test-Assert "Graph Metadata" {
    $graphHash = $unifiedGraph.ToHashtable()
    $graphHash.NodesCount -eq 13 -and
    $graphHash.EdgesCount -eq 7
}

# Final Results
Write-Host "`n=== Test Results ===" -ForegroundColor Cyan
Write-Host "Passed: $($testResults.Passed)" -ForegroundColor Green
Write-Host "Failed: $($testResults.Failed)" -ForegroundColor $(if ($testResults.Failed -gt 0) { 'Red' } else { 'Gray' })
Write-Host "Total:  $($testResults.Passed + $testResults.Failed)"

# Export results
$timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
$resultsFile = Join-Path (Split-Path $MyInvocation.MyCommand.Path) "UnifiedCPG-TestResults-$timestamp.json"
$testResults | ConvertTo-Json -Depth 10 | Set-Content $resultsFile
Write-Host "`nResults saved to: $resultsFile" -ForegroundColor Gray

# Return exit code
exit $(if ($testResults.Failed -eq 0) { 0 } else { 1 })