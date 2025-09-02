# Test-Day45-CrossLanguageMapping.ps1
# Comprehensive test suite for Cross-Language Mapping implementation
# Tests: CrossLanguage-UnifiedModel.psm1, CrossLanguage-GraphMerger.psm1, CrossLanguage-DependencyMaps.psm1
# Created: 2025-08-28 04:30 AM

param(
    [switch] $Detailed,
    [switch] $Performance,
    [string] $OutputPath = "CrossLanguageMapping-TestResults-$(Get-Date -Format 'yyyyMMdd-HHmmss').json"
)

# Import test framework and required modules
$ModulePath = "$PSScriptRoot\Modules\Unity-Claude-CPG\Core"

try {
    Import-Module "$ModulePath\CPG-Unified.psm1" -Force
    Import-Module "$ModulePath\CrossLanguage-UnifiedModel.psm1" -Force
    Import-Module "$ModulePath\CrossLanguage-GraphMerger.psm1" -Force
    Import-Module "$ModulePath\CrossLanguage-DependencyMaps.psm1" -Force
    Write-Host "✅ All required modules imported successfully" -ForegroundColor Green
}
catch {
    Write-Host "❌ Failed to import required modules: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

# Test results container
$TestResults = @{
    TestSuite = "CrossLanguageMapping"
    StartTime = Get-Date
    EndTime = $null
    TotalTests = 0
    PassedTests = 0
    FailedTests = 0
    SkippedTests = 0
    TestDetails = @()
    Performance = @{}
    ModuleInfo = @{
        UnifiedModel = @{
            LineCount = 0
            ClassCount = 0
            FunctionCount = 0
        }
        GraphMerger = @{
            LineCount = 0
            ClassCount = 0
            FunctionCount = 0
        }
        DependencyMaps = @{
            LineCount = 0
            ClassCount = 0
            FunctionCount = 0
        }
    }
}

# Helper functions
function Test-Function {
    param(
        [string] $TestName,
        [scriptblock] $TestCode,
        [string] $Category = "General"
    )
    
    $TestResults.TotalTests++
    $testStart = Get-Date
    
    try {
        $result = & $TestCode
        $success = $result -eq $true -or ($result -and $result.Success -eq $true)
        
        if ($success) {
            $TestResults.PassedTests++
            $status = "PASS"
            $color = "Green"
        }
        else {
            $TestResults.FailedTests++
            $status = "FAIL"
            $color = "Red"
        }
    }
    catch {
        $TestResults.FailedTests++
        $status = "ERROR"
        $color = "Red"
        $result = $_.Exception.Message
    }
    
    $testDuration = (Get-Date) - $testStart
    
    $testDetail = @{
        Name = $TestName
        Category = $Category
        Status = $status
        Duration = $testDuration
        Result = $result
        Timestamp = Get-Date
    }
    
    $TestResults.TestDetails += $testDetail
    
    Write-Host "[$status] $TestName" -ForegroundColor $color
    if ($Detailed -and $result -and $result -ne $true) {
        Write-Host "  Result: $result" -ForegroundColor Gray
    }
}

function Get-ModuleStats {
    param([string] $ModulePath)
    
    if (-not (Test-Path $ModulePath)) { return @{LineCount = 0; ClassCount = 0; FunctionCount = 0} }
    
    $content = Get-Content $ModulePath -Raw
    return @{
        LineCount = ($content -split "`n").Count
        ClassCount = ([regex]::Matches($content, "class\s+\w+")).Count
        FunctionCount = ([regex]::Matches($content, "function\s+[\w-]+")).Count
    }
}

# Collect module statistics
Write-Host "`n=== MODULE STATISTICS ===" -ForegroundColor Cyan
$TestResults.ModuleInfo.UnifiedModel = Get-ModuleStats "$ModulePath\CrossLanguage-UnifiedModel.psm1"
$TestResults.ModuleInfo.GraphMerger = Get-ModuleStats "$ModulePath\CrossLanguage-GraphMerger.psm1"
$TestResults.ModuleInfo.DependencyMaps = Get-ModuleStats "$ModulePath\CrossLanguage-DependencyMaps.psm1"

Write-Host "UnifiedModel: $($TestResults.ModuleInfo.UnifiedModel.LineCount) lines, $($TestResults.ModuleInfo.UnifiedModel.ClassCount) classes, $($TestResults.ModuleInfo.UnifiedModel.FunctionCount) functions"
Write-Host "GraphMerger: $($TestResults.ModuleInfo.GraphMerger.LineCount) lines, $($TestResults.ModuleInfo.GraphMerger.ClassCount) classes, $($TestResults.ModuleInfo.GraphMerger.FunctionCount) functions"
Write-Host "DependencyMaps: $($TestResults.ModuleInfo.DependencyMaps.LineCount) lines, $($TestResults.ModuleInfo.DependencyMaps.ClassCount) classes, $($TestResults.ModuleInfo.DependencyMaps.FunctionCount) functions"

Write-Host "`n=== CROSS-LANGUAGE UNIFIED MODEL TESTS ===" -ForegroundColor Cyan

# Test 1: UnifiedNode creation
Test-Function "Create UnifiedNode instances" {
    try {
        $node1 = [UnifiedNode]::new("TestClass", [UnifiedNodeType]::ClassDefinition, "CSharp")
        $node2 = [UnifiedNode]::new("TestFunction", [UnifiedNodeType]::FunctionDefinition, "Python")
        
        return $node1 -and $node2 -and $node1.Name -eq "TestClass" -and $node2.SourceLanguage -eq "Python"
    }
    catch { return $false }
} "UnifiedModel"

# Test 2: UnifiedRelation creation
Test-Function "Create UnifiedRelation instances" {
    try {
        $relation = [UnifiedRelation]::new([UnifiedRelationType]::Calls, "node1", "node2", "JavaScript")
        
        return $relation -and $relation.Type -eq [UnifiedRelationType]::Calls -and $relation.SourceLanguage -eq "JavaScript"
    }
    catch { return $false }
} "UnifiedModel"

# Test 3: LanguageMapper functionality
Test-Function "LanguageMapper cross-language mapping" {
    try {
        $mapper = [LanguageMapper]::new("CSharp")
        
        # Create mock original node
        $originalNode = [PSCustomObject]@{
            Name = "MyClass"
            Type = "ClassDefinition"
            Namespace = "MyNamespace"
            Properties = @{}
        }
        
        $unifiedNode = $mapper.MapToUnified($originalNode)
        
        return $unifiedNode -and $unifiedNode.Name -eq "MyClass"
    }
    catch { return $false }
} "UnifiedModel"

# Test 4: NodeNormalizer functionality
Test-Function "NodeNormalizer standardization" {
    try {
        $normalizer = [NodeNormalizer]::new()
        
        $normalized1 = $normalizer.NormalizeNaming("my_function", "Python")
        $normalized2 = $normalizer.NormalizeNaming("MyFunction", "CSharp")
        
        return $normalized1 -and $normalized2
    }
    catch { return $false }
} "UnifiedModel"

# Test 5: RelationshipResolver equivalency detection
Test-Function "RelationshipResolver equivalency detection" {
    try {
        $resolver = [RelationshipResolver]::new()
        
        $node1 = [UnifiedNode]::new("TestClass", [UnifiedNodeType]::ClassDefinition, "CSharp")
        $node2 = [UnifiedNode]::new("TestClass", [UnifiedNodeType]::ClassDefinition, "Python")
        
        $equivalency = $resolver.FindEquivalentConstructs($node1, $node2)
        
        return $equivalency -and $equivalency.Confidence -gt 0.0
    }
    catch { return $false }
} "UnifiedModel"

# Test 6: New-UnifiedCPG function
Test-Function "New-UnifiedCPG function execution" {
    try {
        # Create mock language graphs
        $mockGraphs = @{
            "CSharp" = [PSCustomObject]@{
                Nodes = @{
                    "node1" = [PSCustomObject]@{
                        Id = "node1"
                        Name = "TestClass"
                        Type = [UnifiedNodeType]::ClassDefinition
                        Namespace = "Test"
                        Properties = @{}
                    }
                }
                Relations = @()
            }
            "Python" = [PSCustomObject]@{
                Nodes = @{
                    "node2" = [PSCustomObject]@{
                        Id = "node2"
                        Name = "test_function"
                        Type = [UnifiedNodeType]::FunctionDefinition
                        Namespace = "test"
                        Properties = @{}
                    }
                }
                Relations = @()
            }
        }
        
        $unifiedCPG = New-UnifiedCPG -LanguageGraphs $mockGraphs -Name "TestUnifiedCPG"
        
        return $unifiedCPG -and $unifiedCPG.Name -eq "TestUnifiedCPG"
    }
    catch { return $false }
} "UnifiedModel"

Write-Host "`n=== CROSS-LANGUAGE GRAPH MERGER TESTS ===" -ForegroundColor Cyan

# Test 7: GraphMerger instantiation
Test-Function "GraphMerger class instantiation" {
    try {
        $mockGraphs = @{
            "CSharp" = [PSCustomObject]@{ Nodes = @{} }
            "Python" = [PSCustomObject]@{ Nodes = @{} }
        }
        
        $merger = [GraphMerger]::new($mockGraphs, [MergeStrategy]::Hybrid)
        
        return $merger -and $merger.Strategy -eq [MergeStrategy]::Hybrid
    }
    catch { return $false }
} "GraphMerger"

# Test 8: Merge-LanguageGraphs function
Test-Function "Merge-LanguageGraphs function execution" {
    try {
        # Create more detailed mock graphs
        $mockGraphs = @{
            "CSharp" = [PSCustomObject]@{
                Nodes = @{
                    "cs_node1" = [PSCustomObject]@{
                        Id = "cs_node1"
                        Name = "CustomerService"
                        Type = [UnifiedNodeType]::ClassDefinition
                        Namespace = "Services"
                        Properties = @{}
                    }
                }
                Edges = @()
                Relations = @()
            }
            "Python" = [PSCustomObject]@{
                Nodes = @{
                    "py_node1" = [PSCustomObject]@{
                        Id = "py_node1"
                        Name = "customer_service"
                        Type = [UnifiedNodeType]::ClassDefinition
                        Namespace = "services"
                        Properties = @{}
                    }
                }
                Edges = @()
                Relations = @()
            }
        }
        
        $mergeResult = Merge-LanguageGraphs -LanguageGraphs $mockGraphs -Strategy Hybrid
        
        return $mergeResult -and $mergeResult.Success
    }
    catch { return $false }
} "GraphMerger"

# Test 9: Resolve-NamingConflicts function
Test-Function "Resolve-NamingConflicts function execution" {
    try {
        $mockGraphs = @{
            "CSharp" = [PSCustomObject]@{
                Nodes = @{
                    "cs_conflict" = [PSCustomObject]@{
                        Id = "cs_conflict"
                        Name = "Utils"
                        Type = [UnifiedNodeType]::ClassDefinition
                        Namespace = "Common"
                    }
                }
            }
            "JavaScript" = [PSCustomObject]@{
                Nodes = @{
                    "js_conflict" = [PSCustomObject]@{
                        Id = "js_conflict"
                        Name = "Utils"
                        Type = [UnifiedNodeType]::ClassDefinition
                        Namespace = "Common"
                    }
                }
            }
        }
        
        $conflicts = Resolve-NamingConflicts -LanguageGraphs $mockGraphs
        
        return $conflicts -ne $null
    }
    catch { return $false }
} "GraphMerger"

# Test 10: Detect-Duplicates function
Test-Function "Detect-Duplicates function execution" {
    try {
        $mockGraphs = @{
            "Language1" = [PSCustomObject]@{
                Nodes = @{
                    "node1" = [PSCustomObject]@{
                        Name = "SameFunction"
                        Type = [UnifiedNodeType]::FunctionDefinition
                    }
                }
            }
            "Language2" = [PSCustomObject]@{
                Nodes = @{
                    "node2" = [PSCustomObject]@{
                        Name = "SameFunction"
                        Type = [UnifiedNodeType]::FunctionDefinition
                    }
                }
            }
        }
        
        $duplicates = Detect-Duplicates -LanguageGraphs $mockGraphs -SimilarityThreshold 0.9
        
        return $duplicates -ne $null
    }
    catch { return $false }
} "GraphMerger"

Write-Host "`n=== CROSS-LANGUAGE DEPENDENCY MAPS TESTS ===" -ForegroundColor Cyan

# Test 11: CrossLanguageReference creation
Test-Function "CrossLanguageReference class creation" {
    try {
        $reference = [CrossLanguageReference]::new("CSharp", "Python", "node1", "node2", [ReferenceType]::Strong)
        
        return $reference -and $reference.SourceLanguage -eq "CSharp" -and $reference.TargetLanguage -eq "Python"
    }
    catch { return $false }
} "DependencyMaps"

# Test 12: DependencyNode functionality
Test-Function "DependencyNode class functionality" {
    try {
        $node = [DependencyNode]::new("test_id", "TestNode", "CSharp", [UnifiedNodeType]::ClassDefinition)
        $node.IncomingDependencies.Add("dep1")
        $node.OutgoingDependencies.Add("dep2")
        $node.UpdateMetrics()
        
        return $node.Metrics.InDegree -eq 1 -and $node.Metrics.OutDegree -eq 1
    }
    catch { return $false }
} "DependencyMaps"

# Test 13: DependencyGraph functionality
Test-Function "DependencyGraph class functionality" {
    try {
        $graph = [DependencyGraph]::new("TestGraph")
        
        $node = [DependencyNode]::new("node1", "TestNode", "CSharp", [UnifiedNodeType]::ClassDefinition)
        $graph.AddNode($node)
        
        $reference = [CrossLanguageReference]::new("CSharp", "Python", "node1", "node2", [ReferenceType]::Strong)
        $graph.AddReference($reference)
        
        return $graph.Nodes.Count -eq 1 -and $graph.References.Count -eq 1
    }
    catch { return $false }
} "DependencyMaps"

# Test 14: CrossLanguageReferenceResolver
Test-Function "CrossLanguageReferenceResolver functionality" {
    try {
        $mockGraphs = @{
            "CSharp" = [PSCustomObject]@{
                Nodes = @{
                    "cs1" = [PSCustomObject]@{
                        Id = "cs1"
                        Name = "Import-Module TestModule"
                        Type = [UnifiedNodeType]::ImportStatement
                        Properties = @{ ModuleName = "TestModule" }
                    }
                }
            }
            "Python" = [PSCustomObject]@{
                Nodes = @{
                    "py1" = [PSCustomObject]@{
                        Id = "py1"
                        Name = "TestModule"
                        Type = [UnifiedNodeType]::ModuleDefinition
                        Properties = @{}
                    }
                }
            }
        }
        
        $resolver = [CrossLanguageReferenceResolver]::new($mockGraphs)
        $dependencyGraph = $resolver.ResolveAllReferences()
        
        return $dependencyGraph -ne $null
    }
    catch { return $false }
} "DependencyMaps"

# Test 15: Resolve-CrossLanguageReferences function
Test-Function "Resolve-CrossLanguageReferences function execution" {
    try {
        $mockGraphs = @{
            "CSharp" = [PSCustomObject]@{
                Nodes = @{
                    "cs_func" = [PSCustomObject]@{
                        Id = "cs_func"
                        Name = "CallPythonFunction()"
                        Type = [UnifiedNodeType]::FunctionCall
                        Properties = @{}
                    }
                }
            }
            "Python" = [PSCustomObject]@{
                Nodes = @{
                    "py_func" = [PSCustomObject]@{
                        Id = "py_func"
                        Name = "python_function"
                        Type = [UnifiedNodeType]::FunctionDefinition
                        Properties = @{}
                    }
                }
            }
        }
        
        $result = Resolve-CrossLanguageReferences -LanguageGraphs $mockGraphs
        
        return $result -and $result.Success
    }
    catch { return $false }
} "DependencyMaps"

# Test 16: Generate-DependencyGraph function
Test-Function "Generate-DependencyGraph function execution" {
    try {
        $mockDependencyGraph = [DependencyGraph]::new("TestGraph")
        
        $node1 = [DependencyNode]::new("node1", "TestNode1", "CSharp", [UnifiedNodeType]::ClassDefinition)
        $node2 = [DependencyNode]::new("node2", "TestNode2", "Python", [UnifiedNodeType]::FunctionDefinition)
        
        $mockDependencyGraph.AddNode($node1)
        $mockDependencyGraph.AddNode($node2)
        
        $diagram = Generate-DependencyGraph -DependencyGraph $mockDependencyGraph -Format "Mermaid"
        
        return $diagram -and $diagram.Contains("graph TD")
    }
    catch { return $false }
} "DependencyMaps"

# Test 17: Detect-CircularDependencies function
Test-Function "Detect-CircularDependencies function execution" {
    try {
        $mockDependencyGraph = [DependencyGraph]::new("CircularTestGraph")
        
        # Create nodes that could form a cycle
        $node1 = [DependencyNode]::new("node1", "Node1", "CSharp", [UnifiedNodeType]::ClassDefinition)
        $node2 = [DependencyNode]::new("node2", "Node2", "Python", [UnifiedNodeType]::ClassDefinition)
        
        $mockDependencyGraph.AddNode($node1)
        $mockDependencyGraph.AddNode($node2)
        
        $cycles = Detect-CircularDependencies -DependencyGraph $mockDependencyGraph
        
        return $cycles -ne $null
    }
    catch { return $false }
} "DependencyMaps"

# Test 18: Performance test - Large graph merging
if ($Performance) {
    Test-Function "Performance: Large graph merging" {
        try {
            $performanceStart = Get-Date
            
            # Create larger mock graphs for performance testing
            $largeMockGraphs = @{
                "CSharp" = [PSCustomObject]@{ Nodes = @{} }
                "Python" = [PSCustomObject]@{ Nodes = @{} }
                "JavaScript" = [PSCustomObject]@{ Nodes = @{} }
            }
            
            # Add 100 nodes per language
            for ($i = 1; $i -le 100; $i++) {
                $largeMockGraphs["CSharp"].Nodes["cs_$i"] = [PSCustomObject]@{
                    Id = "cs_$i"
                    Name = "CSharpClass$i"
                    Type = [UnifiedNodeType]::ClassDefinition
                    Properties = @{}
                }
                
                $largeMockGraphs["Python"].Nodes["py_$i"] = [PSCustomObject]@{
                    Id = "py_$i"
                    Name = "python_function_$i"
                    Type = [UnifiedNodeType]::FunctionDefinition
                    Properties = @{}
                }
                
                $largeMockGraphs["JavaScript"].Nodes["js_$i"] = [PSCustomObject]@{
                    Id = "js_$i"
                    Name = "jsFunction$i"
                    Type = [UnifiedNodeType]::FunctionDefinition
                    Properties = @{}
                }
            }
            
            $mergeResult = Merge-LanguageGraphs -LanguageGraphs $largeMockGraphs -Strategy Hybrid
            
            $performanceDuration = (Get-Date) - $performanceStart
            $TestResults.Performance.LargeGraphMerging = $performanceDuration
            
            Write-Host "  Performance: $($performanceDuration.TotalMilliseconds)ms for 300 nodes" -ForegroundColor Yellow
            
            return $mergeResult.Success -and $performanceDuration.TotalSeconds -lt 30
        }
        catch { return $false }
    } "Performance"
}

# Test 19: Integration test - End-to-end workflow
Test-Function "Integration: End-to-end cross-language workflow" {
    try {
        # Create comprehensive mock graphs
        $integrationGraphs = @{
            "CSharp" = [PSCustomObject]@{
                Nodes = @{
                    "cs_service" = [PSCustomObject]@{
                        Id = "cs_service"
                        Name = "UserService"
                        Type = [UnifiedNodeType]::ClassDefinition
                        Namespace = "Services"
                        Properties = @{}
                    }
                    "cs_import" = [PSCustomObject]@{
                        Id = "cs_import"
                        Name = "Import-Module DataProcessor"
                        Type = [UnifiedNodeType]::ImportStatement
                        Properties = @{ ModuleName = "DataProcessor" }
                    }
                }
                Relations = @()
            }
            "Python" = [PSCustomObject]@{
                Nodes = @{
                    "py_processor" = [PSCustomObject]@{
                        Id = "py_processor"
                        Name = "DataProcessor"
                        Type = [UnifiedNodeType]::ModuleDefinition
                        Namespace = "data"
                        Properties = @{}
                    }
                    "py_function" = [PSCustomObject]@{
                        Id = "py_function"
                        Name = "process_data"
                        Type = [UnifiedNodeType]::FunctionDefinition
                        Properties = @{}
                    }
                }
                Relations = @()
            }
        }
        
        # Step 1: Create unified CPG
        $unifiedCPG = New-UnifiedCPG -LanguageGraphs $integrationGraphs -Name "IntegrationTest"
        
        # Step 2: Merge language graphs
        $mergeResult = Merge-LanguageGraphs -LanguageGraphs $integrationGraphs -Strategy Hybrid
        
        # Step 3: Resolve cross-language references
        $referenceResult = Resolve-CrossLanguageReferences -LanguageGraphs $integrationGraphs
        
        # Step 4: Generate dependency visualization
        if ($referenceResult.Success -and $referenceResult.DependencyGraph) {
            $diagram = Generate-DependencyGraph -DependencyGraph $referenceResult.DependencyGraph -Format "Mermaid"
            
            return $unifiedCPG -and $mergeResult.Success -and $referenceResult.Success -and $diagram
        }
        
        return $false
    }
    catch { return $false }
} "Integration"

# Test 20: Error handling and edge cases
Test-Function "Error handling: Invalid inputs and edge cases" {
    try {
        # Test with empty graphs
        $emptyGraphs = @{}
        $emptyResult = Merge-LanguageGraphs -LanguageGraphs $emptyGraphs -Strategy Conservative
        
        # Test with null inputs
        try {
            $nullResult = New-UnifiedCPG -LanguageGraphs $null
            $nullHandled = $false
        }
        catch {
            $nullHandled = $true
        }
        
        # Test with malformed graph structure
        $malformedGraphs = @{
            "BadLanguage" = "Not an object"
        }
        
        try {
            $malformedResult = Resolve-CrossLanguageReferences -LanguageGraphs $malformedGraphs
            $malformedHandled = $false
        }
        catch {
            $malformedHandled = $true
        }
        
        return $nullHandled -and $malformedHandled
    }
    catch { return $false }
} "ErrorHandling"

# Complete test run
$TestResults.EndTime = Get-Date
$TestResults.Duration = $TestResults.EndTime - $TestResults.StartTime

# Generate summary
Write-Host "`n=== TEST SUMMARY ===" -ForegroundColor Cyan
Write-Host "Total Tests: $($TestResults.TotalTests)"
Write-Host "Passed: $($TestResults.PassedTests)" -ForegroundColor Green
Write-Host "Failed: $($TestResults.FailedTests)" -ForegroundColor Red
Write-Host "Success Rate: $('{0:P2}' -f ($TestResults.PassedTests / $TestResults.TotalTests))"
Write-Host "Duration: $($TestResults.Duration.TotalSeconds) seconds"

# Calculate total lines of code
$totalLines = $TestResults.ModuleInfo.UnifiedModel.LineCount + 
              $TestResults.ModuleInfo.GraphMerger.LineCount + 
              $TestResults.ModuleInfo.DependencyMaps.LineCount

Write-Host "`n=== IMPLEMENTATION METRICS ===" -ForegroundColor Cyan
Write-Host "Total Lines of Code: $totalLines"
Write-Host "Total Classes: $(($TestResults.ModuleInfo.UnifiedModel.ClassCount + $TestResults.ModuleInfo.GraphMerger.ClassCount + $TestResults.ModuleInfo.DependencyMaps.ClassCount))"
Write-Host "Total Functions: $(($TestResults.ModuleInfo.UnifiedModel.FunctionCount + $TestResults.ModuleInfo.GraphMerger.FunctionCount + $TestResults.ModuleInfo.DependencyMaps.FunctionCount))"

if ($Performance -and $TestResults.Performance.LargeGraphMerging) {
    Write-Host "`n=== PERFORMANCE METRICS ===" -ForegroundColor Cyan
    Write-Host "Large Graph Merging: $($TestResults.Performance.LargeGraphMerging.TotalMilliseconds)ms"
}

# Save detailed results
$TestResults | ConvertTo-Json -Depth 10 | Out-File -FilePath $OutputPath -Encoding UTF8
Write-Host "`nDetailed results saved to: $OutputPath" -ForegroundColor Yellow

# Exit with appropriate code
if ($TestResults.FailedTests -eq 0) {
    Write-Host "`n✅ All tests passed successfully!" -ForegroundColor Green
    exit 0
}
else {
    Write-Host "`n❌ $($TestResults.FailedTests) tests failed" -ForegroundColor Red
    exit 1
}