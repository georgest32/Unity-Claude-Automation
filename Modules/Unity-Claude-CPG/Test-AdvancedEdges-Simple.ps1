#Requires -Version 5.1
<#
.SYNOPSIS
    Simple test script for CPG Advanced Edge Types

.DESCRIPTION
    Tests advanced edge types without requiring CPGNode class

.NOTES
    Part of Enhanced Documentation System Second Pass Implementation
    Created: 2025-08-28
#>

# Import modules
$modulePath = Split-Path -Parent $MyInvocation.MyCommand.Path
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

Write-Host "`n=== Testing CPG Advanced Edge Types (Simplified) ===" -ForegroundColor Cyan

# Test 1: DataFlow Edge Creation
Write-Host "`n[Test Group: DataFlow Edges]" -ForegroundColor Yellow

# Use simple node IDs instead of CPGNode objects
$sourceId = [guid]::NewGuid().ToString()
$targetId = [guid]::NewGuid().ToString()

$dataFlowEdge = New-DataFlowEdge `
    -SourceId $sourceId `
    -TargetId $targetId `
    -FlowType DataFlowDirect `
    -DataType "string" `
    -IsMutable $false `
    -IsAsync $false

Test-Assert "DataFlow Edge Creation" {
    $dataFlowEdge -ne $null -and
    $dataFlowEdge.AdvancedType -eq [AdvancedEdgeType]::DataFlowDirect
}

Test-Assert "DataFlow Edge IDs" {
    $dataFlowEdge.SourceId -eq $sourceId -and
    $dataFlowEdge.TargetId -eq $targetId
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

$ifId = [guid]::NewGuid().ToString()
$thenId = [guid]::NewGuid().ToString()
$elseId = [guid]::NewGuid().ToString()

$controlFlowEdge = New-ControlFlowEdge `
    -SourceId $ifId `
    -TargetId $thenId `
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
    -SourceId $thenId `
    -TargetId $ifId `
    -FlowType ControlFlowLoop

Test-Assert "ControlFlow Loop Detection" {
    $loopEdge.IsLoop -eq $true
}

# Test 3: Inheritance Edge Creation
Write-Host "`n[Test Group: Inheritance Edges]" -ForegroundColor Yellow

$baseClassId = [guid]::NewGuid().ToString()
$derivedClassId = [guid]::NewGuid().ToString()

$inheritanceEdge = New-InheritanceEdge `
    -SourceId $derivedClassId `
    -TargetId $baseClassId `
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

$interfaceId = [guid]::NewGuid().ToString()
$implementationId = [guid]::NewGuid().ToString()

$implementationEdge = New-ImplementationEdge `
    -SourceId $implementationId `
    -TargetId $interfaceId `
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
    [Math]::Round($implementationEdge.ComplianceMetrics.Coverage, 2) -eq 66.67
}

Test-Assert "Implementation Violations" {
    $implementationEdge.ComplianceMetrics.Violations -contains "LogWarning"
}

# Test 5: Composition Edge Creation
Write-Host "`n[Test Group: Composition Edges]" -ForegroundColor Yellow

$containerId = [guid]::NewGuid().ToString()
$componentId = [guid]::NewGuid().ToString()

$compositionEdge = New-CompositionEdge `
    -SourceId $containerId `
    -TargetId $componentId `
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

# Test 6: Edge Type Enumeration
Write-Host "`n[Test Group: Enumerations]" -ForegroundColor Yellow

Test-Assert "AdvancedEdgeType Enumeration" {
    [AdvancedEdgeType]::DataFlowDirect -ne $null -and
    [AdvancedEdgeType]::ControlFlowConditional -ne $null -and
    [AdvancedEdgeType]::InheritanceExtends -ne $null
}

# Test 7: Graph Building with Advanced Edges
Write-Host "`n[Test Group: Graph Construction]" -ForegroundColor Yellow

$graph = @{
    Nodes = @{}
    Edges = @{
        $dataFlowEdge.Id = $dataFlowEdge
        $controlFlowEdge.Id = $controlFlowEdge
        $loopEdge.Id = $loopEdge
        $inheritanceEdge.Id = $inheritanceEdge
        $implementationEdge.Id = $implementationEdge
        $compositionEdge.Id = $compositionEdge
    }
}

Test-Assert "Graph Edge Collection" {
    $graph.Edges.Count -eq 6
}

Test-Assert "Edge Type Diversity" {
    $edgeTypes = $graph.Edges.Values | ForEach-Object { $_.Type } | Sort-Object -Unique
    $edgeTypes.Count -ge 4
}

# Test 8: Edge Analysis Methods
Write-Host "`n[Test Group: Edge Analysis]" -ForegroundColor Yellow

Test-Assert "DataFlow Analysis Method" {
    $analysis = $dataFlowEdge.AnalyzeFlow()
    $analysis.ContainsKey("Type") -and
    $analysis.ContainsKey("DataType") -and
    $analysis.ContainsKey("Metrics")
}

Test-Assert "ControlFlow Analysis Method" {
    $analysis = $controlFlowEdge.AnalyzeControlFlow()
    $analysis.ContainsKey("Type") -and
    $analysis.ContainsKey("IsConditional") -and
    $analysis.ContainsKey("Metrics")
}

Test-Assert "Implementation Analysis Method" {
    $analysis = $implementationEdge.AnalyzeImplementation()
    $analysis.ContainsKey("IsComplete") -and
    $analysis.ContainsKey("Compliance")
}

# Final Results
Write-Host "`n=== Test Results ===" -ForegroundColor Cyan
Write-Host "Passed: $($testResults.Passed)" -ForegroundColor Green
Write-Host "Failed: $($testResults.Failed)" -ForegroundColor $(if ($testResults.Failed -gt 0) { 'Red' } else { 'Gray' })
Write-Host "Total:  $($testResults.Passed + $testResults.Failed)"

# Export results
$timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
$resultsFile = Join-Path (Split-Path $MyInvocation.MyCommand.Path) "AdvancedEdges-SimpleTestResults-$timestamp.json"
$testResults | ConvertTo-Json -Depth 10 | Set-Content $resultsFile
Write-Host "`nResults saved to: $resultsFile" -ForegroundColor Gray

# Return exit code
exit $(if ($testResults.Failed -eq 0) { 0 } else { 1 })