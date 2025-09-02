#Requires -Version 5.1
<#
.SYNOPSIS
    Test script for CPG Advanced Edge Types

.DESCRIPTION
    Tests DataFlow, ControlFlow, Inheritance, Implementation, and Composition edges

.NOTES
    Part of Enhanced Documentation System Second Pass Implementation
    Created: 2025-08-28
#>

# Import required modules
$modulePath = Split-Path -Parent $MyInvocation.MyCommand.Path

# Load the data structures module and import the classes
. "$modulePath\Core\CPG-DataStructures.psm1"

# Now import the other modules
Import-Module "$modulePath\Core\CPG-ThreadSafeOperations.psm1" -Force
Import-Module "$modulePath\Core\CPG-AdvancedEdges.psm1" -Force

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

Write-Host "`n=== Testing CPG Advanced Edge Types ===" -ForegroundColor Cyan

# Test 1: DataFlow Edge Creation
Write-Host "`n[Test Group: DataFlow Edges]" -ForegroundColor Yellow

$sourceNode = [CPGNode]::new("VariableA", [CPGNodeType]::Variable)
$targetNode = [CPGNode]::new("VariableB", [CPGNodeType]::Variable)

$dataFlowEdge = New-DataFlowEdge `
    -SourceId $sourceNode.Id `
    -TargetId $targetNode.Id `
    -FlowType DataFlowDirect `
    -DataType "string" `
    -IsMutable $false `
    -IsAsync $false

Test-Assert "DataFlow Edge Creation" {
    $dataFlowEdge -ne $null -and
    $dataFlowEdge.AdvancedType -eq [AdvancedEdgeType]::DataFlowDirect
}

Test-Assert "DataFlow Edge Properties" {
    $dataFlowEdge.DataType -eq "string" -and
    $dataFlowEdge.IsMutable -eq $false -and
    $dataFlowEdge.IsAsync -eq $false
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

# Test 2: ControlFlow Edge Creation
Write-Host "`n[Test Group: ControlFlow Edges]" -ForegroundColor Yellow

$ifNode = [CPGNode]::new("IfStatement", [CPGNodeType]::Function)
$thenNode = [CPGNode]::new("ThenBlock", [CPGNodeType]::Function)
$elseNode = [CPGNode]::new("ElseBlock", [CPGNodeType]::Function)

$controlFlowEdge = New-ControlFlowEdge `
    -SourceId $ifNode.Id `
    -TargetId $thenNode.Id `
    -FlowType ControlFlowConditional `
    -Condition "x > 0" `
    -ExecutionProbability 0.7

Test-Assert "ControlFlow Edge Creation" {
    $controlFlowEdge -ne $null -and
    $controlFlowEdge.AdvancedType -eq [AdvancedEdgeType]::ControlFlowConditional
}

Test-Assert "ControlFlow Conditional Properties" {
    $controlFlowEdge.IsConditional -eq $true -and
    $controlFlowEdge.Condition -eq "x > 0" -and
    $controlFlowEdge.ExecutionProbability -eq 0.7
}

$loopEdge = New-ControlFlowEdge `
    -SourceId $thenNode.Id `
    -TargetId $ifNode.Id `
    -FlowType ControlFlowLoop

Test-Assert "ControlFlow Loop Detection" {
    $loopEdge.IsLoop -eq $true
}

# Test 3: Inheritance Edge Creation
Write-Host "`n[Test Group: Inheritance Edges]" -ForegroundColor Yellow

$baseClass = [CPGNode]::new("BaseClass", [CPGNodeType]::Class)
$derivedClass = [CPGNode]::new("DerivedClass", [CPGNodeType]::Class)

$inheritanceEdge = New-InheritanceEdge `
    -SourceId $derivedClass.Id `
    -TargetId $baseClass.Id `
    -InheritanceType InheritanceExtends `
    -BaseType "BaseClass" `
    -DerivedType "DerivedClass"

Test-Assert "Inheritance Edge Creation" {
    $inheritanceEdge -ne $null -and
    $inheritanceEdge.AdvancedType -eq [AdvancedEdgeType]::InheritanceExtends
}

$inheritanceEdge.AddInheritedMember("MethodA")
$inheritanceEdge.AddInheritedMember("PropertyB")
$inheritanceEdge.AddOverriddenMember("MethodA")

Test-Assert "Inheritance Members" {
    $inheritanceEdge.InheritedMembers.Count -eq 2 -and
    $inheritanceEdge.OverriddenMembers.Count -eq 1
}

$inheritAnalysis = $inheritanceEdge.AnalyzeInheritance()
Test-Assert "Inheritance Analysis" {
    $inheritAnalysis.InheritedCount -eq 2 -and
    $inheritAnalysis.OverriddenCount -eq 1
}

# Test 4: Implementation Edge Creation
Write-Host "`n[Test Group: Implementation Edges]" -ForegroundColor Yellow

$interface = [CPGNode]::new("ILogger", [CPGNodeType]::Interface)
$implementation = [CPGNode]::new("FileLogger", [CPGNodeType]::Class)

$implementationEdge = New-ImplementationEdge `
    -SourceId $implementation.Id `
    -TargetId $interface.Id `
    -ImplementationType ImplementationInterface `
    -InterfaceName "ILogger" `
    -ImplementorName "FileLogger" `
    -RequiredMethods @("Log", "LogError", "LogWarning")

Test-Assert "Implementation Edge Creation" {
    $implementationEdge -ne $null -and
    $implementationEdge.AdvancedType -eq [AdvancedEdgeType]::ImplementationInterface
}

$implementationEdge.ImplementedMethods = @("Log", "LogError")
$implementationEdge.ValidateImplementation()

Test-Assert "Implementation Validation" {
    $implementationEdge.IsComplete -eq $false -and
    $implementationEdge.ComplianceMetrics.Coverage -eq 66.66666666666667
}

Test-Assert "Implementation Violations" {
    $implementationEdge.ComplianceMetrics.Violations -contains "LogWarning"
}

# Test 5: Composition Edge Creation
Write-Host "`n[Test Group: Composition Edges]" -ForegroundColor Yellow

$container = [CPGNode]::new("Car", [CPGNodeType]::Class)
$component = [CPGNode]::new("Engine", [CPGNodeType]::Class)

$compositionEdge = New-CompositionEdge `
    -SourceId $container.Id `
    -TargetId $component.Id `
    -CompositionType CompositionHasA `
    -ContainerType "Car" `
    -ComponentType "Engine" `
    -Cardinality "1"

Test-Assert "Composition Edge Creation" {
    $compositionEdge -ne $null -and
    $compositionEdge.AdvancedType -eq [AdvancedEdgeType]::CompositionHasA
}

Test-Assert "Composition Ownership" {
    $compositionEdge.IsOwnership -eq $true -and
    $compositionEdge.IsShared -eq $false
}

$compositionEdge.SetCardinality("1..*")
Test-Assert "Composition Cardinality" {
    $compositionEdge.Cardinality -eq "1..*"
}

# Test 6: Graph Operations with Advanced Edges
Write-Host "`n[Test Group: Graph Operations]" -ForegroundColor Yellow

$graph = @{
    Nodes = @{
        $sourceNode.Id = $sourceNode
        $targetNode.Id = $targetNode
        $ifNode.Id = $ifNode
        $thenNode.Id = $thenNode
        $elseNode.Id = $elseNode
        $baseClass.Id = $baseClass
        $derivedClass.Id = $derivedClass
        $interface.Id = $interface
        $implementation.Id = $implementation
        $container.Id = $container
        $component.Id = $component
    }
    Edges = @{
        $dataFlowEdge.Id = $dataFlowEdge
        $controlFlowEdge.Id = $controlFlowEdge
        $loopEdge.Id = $loopEdge
        $inheritanceEdge.Id = $inheritanceEdge
        $implementationEdge.Id = $implementationEdge
        $compositionEdge.Id = $compositionEdge
    }
}

Test-Assert "Graph Construction" {
    $graph.Nodes.Count -eq 11 -and
    $graph.Edges.Count -eq 6
}

# Test 7: Control Flow Graph Analysis
$cfgEntry = $ifNode.Id
$cfg = Get-ControlFlowGraph -Graph $graph -EntryPoint $cfgEntry

Test-Assert "Control Flow Graph Analysis" {
    $cfg.EntryPoint -eq $cfgEntry -and
    $cfg.Loops.Count -eq 1 -and
    $cfg.Branches.Count -eq 1
}

# Test 8: Inheritance Hierarchy Analysis
$hierarchy = Get-InheritanceHierarchy -Graph $graph -RootType $baseClass.Id

Test-Assert "Inheritance Hierarchy" {
    $hierarchy.Root -eq $baseClass.Id -and
    $hierarchy.Children.ContainsKey($derivedClass.Id)
}

# Test 9: Interface Compliance Check
$compliance = Get-InterfaceCompliance -Graph $graph -InterfaceId $interface.Id

Test-Assert "Interface Compliance Check" {
    $compliance.TotalCompliance -lt 100 -and
    $compliance.Issues.Count -eq 1
}

# Test 10: Composition Structure Analysis
$structure = Get-CompositionStructure -Graph $graph -ContainerId $container.Id

Test-Assert "Composition Structure" {
    $structure.TotalComponents -eq 1 -and
    $structure.OwnershipCount -eq 1
}

# Test 11: Mermaid Diagram Generation
Write-Host "`n[Test Group: Visualization]" -ForegroundColor Yellow

$mermaid = ConvertTo-MermaidDiagram `
    -Graph $graph `
    -ShowControlFlow `
    -ShowInheritance `
    -ShowComposition

Test-Assert "Mermaid Diagram Generation" {
    $mermaid -match "graph LR" -and
    $mermaid -match "-->|if|" -and
    $mermaid -match "--|>"
}

# Final Results
Write-Host "`n=== Test Results ===" -ForegroundColor Cyan
Write-Host "Passed: $($testResults.Passed)" -ForegroundColor Green
Write-Host "Failed: $($testResults.Failed)" -ForegroundColor $(if ($testResults.Failed -gt 0) { 'Red' } else { 'Gray' })
Write-Host "Total:  $($testResults.Passed + $testResults.Failed)"

# Export results
$timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
$resultsFile = Join-Path (Split-Path $MyInvocation.MyCommand.Path) "AdvancedEdges-TestResults-$timestamp.json"
$testResults | ConvertTo-Json -Depth 10 | Set-Content $resultsFile
Write-Host "`nResults saved to: $resultsFile" -ForegroundColor Gray

# Return exit code
exit $(if ($testResults.Failed -eq 0) { 0 } else { 1 })