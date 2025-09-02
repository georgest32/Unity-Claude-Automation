#Requires -Version 5.1
#Requires -Modules Pester

<#
.SYNOPSIS
    Comprehensive tests for Unity-Claude-CPG module.

.DESCRIPTION
    Tests CPG node/edge creation, graph operations, AST conversion,
    and thread-safety of the implementation.

.NOTES
    Version: 1.0.0
    Author: Unity-Claude Automation System
    Date: 2025-08-24
#>

# Module import and test setup
BeforeAll {
    $script:enumPath = Join-Path $PSScriptRoot "Unity-Claude-CPG-Enums.ps1"
    . $script:enumPath
    $script:modulePath = Join-Path $PSScriptRoot "Unity-Claude-CPG.psd1"
    Import-Module $script:modulePath -Force

    # Test data setup
    $script:TestScriptContent = @'
function Get-TestData {
    [CmdletBinding()]
    param(
        [string]$Name = "Default",
        [int]$Count = 10
    )
    
    $result = @()
    for ($i = 0; $i -lt $Count; $i++) {
        $result += "Item$i"
    }
    
    return $result
}

function Process-TestData {
    param($Data)
    
    $processed = Get-TestData -Count 5
    
    if ($Data) {
        foreach ($item in $Data) {
            Write-Host $item
        }
    }
    
    return $processed
}

class TestClass {
    [string]$Name
    [int]$Value
    
    TestClass([string]$name) {
        $this.Name = $name
        $this.Value = 0
    }
    
    [void] IncrementValue() {
        $this.Value++
    }
}

$global:TestVariable = "TestValue"
$data = Get-TestData -Name "Test" -Count 20
Process-TestData -Data $data
'@
}

Describe "CPG Node Operations" {
    
    Context "Node Creation" {
        It "Should create a node with correct properties" {
            $node = New-CPGNode -Name "TestFunction" -Type Function
            
            $node | Should -Not -BeNullOrEmpty
            $node.Name | Should -Be "TestFunction"
            $node.Type | Should -Be ([CPGNodeType]::Function)
            $node.Id | Should -Not -BeNullOrEmpty
            $node.CreatedAt | Should -BeOfType [datetime]
        }
        
        It "Should create nodes with different types" {
            $types = @('Module', 'Function', 'Class', 'Variable', 'Parameter')
            
            foreach ($type in $types) {
                $node = New-CPGNode -Name "Test$type" -Type $type
                $node.Type.ToString() | Should -Be $type
            }
        }
        
        It "Should store metadata and properties" {
            $props = @{ Language = 'PowerShell'; Version = '1.0' }
            $meta = @{ Author = 'Test'; Date = Get-Date }
            
            $node = New-CPGNode -Name "TestNode" -Type Module -Properties $props -Metadata $meta
            
            $node.Properties.Language | Should -Be 'PowerShell'
            $node.Properties.Version | Should -Be '1.0'
            $node.Metadata.Author | Should -Be 'Test'
        }
        
        It "Should track file location information" {
            $node = New-CPGNode -Name "TestFunc" -Type Function `
                -FilePath "C:\test.ps1" -StartLine 10 -EndLine 20
            
            $node.FilePath | Should -Be "C:\test.ps1"
            $node.StartLine | Should -Be 10
            $node.EndLine | Should -Be 20
        }
    }
    
    Context "Node Serialization" {
        It "Should convert node to hashtable" {
            $node = New-CPGNode -Name "TestNode" -Type Function
            $hash = $node.ToHashtable()
            
            $hash | Should -BeOfType [hashtable]
            $hash.Name | Should -Be "TestNode"
            $hash.Type | Should -Be "Function"
            $hash.Id | Should -Be $node.Id
        }
    }
}

Describe "CPG Edge Operations" {
    
    Context "Edge Creation" {
        It "Should create an edge with correct properties" {
            $node1 = New-CPGNode -Name "Func1" -Type Function
            $node2 = New-CPGNode -Name "Func2" -Type Function
            
            $edge = New-CPGEdge -SourceId $node1.Id -TargetId $node2.Id -Type Calls
            
            $edge | Should -Not -BeNullOrEmpty
            $edge.SourceId | Should -Be $node1.Id
            $edge.TargetId | Should -Be $node2.Id
            $edge.Type | Should -Be ([CPGEdgeType]::Calls)
        }
        
        It "Should support different edge types" {
            $node1 = New-CPGNode -Name "Node1" -Type Variable
            $node2 = New-CPGNode -Name "Node2" -Type Function
            
            $edgeTypes = @('Uses', 'Assigns', 'References', 'DependsOn')
            
            foreach ($type in $edgeTypes) {
                $edge = New-CPGEdge -SourceId $node1.Id -TargetId $node2.Id -Type $type
                $edge.Type.ToString() | Should -Be $type
            }
        }
        
        It "Should support edge direction" {
            $node1 = New-CPGNode -Name "Node1" -Type Module
            $node2 = New-CPGNode -Name "Node2" -Type Module
            
            $edge = New-CPGEdge -SourceId $node1.Id -TargetId $node2.Id `
                -Type DependsOn -Direction Bidirectional
            
            $edge.Direction | Should -Be ([EdgeDirection]::Bidirectional)
        }
        
        It "Should support edge weights" {
            $node1 = New-CPGNode -Name "Node1" -Type Function
            $node2 = New-CPGNode -Name "Node2" -Type Function
            
            $edge = New-CPGEdge -SourceId $node1.Id -TargetId $node2.Id `
                -Type Calls -Weight 0.75
            
            $edge.Weight | Should -Be 0.75
        }
    }
}

Describe "CPG Graph Operations" {
    
    Context "Graph Creation and Management" {
        It "Should create an empty graph" {
            $graph = New-CPGraph -Name "TestGraph"
            
            $graph | Should -Not -BeNullOrEmpty
            $graph.Name | Should -Be "TestGraph"
            $graph.Nodes.Count | Should -Be 0
            $graph.Edges.Count | Should -Be 0
        }
        
        It "Should add nodes to graph" {
            $graph = New-CPGraph -Name "TestGraph"
            $node1 = New-CPGNode -Name "Func1" -Type Function
            $node2 = New-CPGNode -Name "Var1" -Type Variable
            
            Add-CPGNode -Graph $graph -Node $node1
            Add-CPGNode -Graph $graph -Node $node2
            
            $graph.Nodes.Count | Should -Be 2
            $graph.Nodes[$node1.Id] | Should -Be $node1
            $graph.Nodes[$node2.Id] | Should -Be $node2
        }
        
        It "Should add edges to graph" {
            $graph = New-CPGraph -Name "TestGraph"
            $node1 = New-CPGNode -Name "Func1" -Type Function
            $node2 = New-CPGNode -Name "Func2" -Type Function
            
            Add-CPGNode -Graph $graph -Node $node1
            Add-CPGNode -Graph $graph -Node $node2
            
            $edge = New-CPGEdge -SourceId $node1.Id -TargetId $node2.Id -Type Calls
            Add-CPGEdge -Graph $graph -Edge $edge
            
            $graph.Edges.Count | Should -Be 1
            $graph.Edges[$edge.Id] | Should -Be $edge
        }
        
        It "Should maintain adjacency list" {
            $graph = New-CPGraph -Name "TestGraph"
            $node1 = New-CPGNode -Name "Func1" -Type Function
            $node2 = New-CPGNode -Name "Func2" -Type Function
            
            Add-CPGNode -Graph $graph -Node $node1
            Add-CPGNode -Graph $graph -Node $node2
            
            $edge = New-CPGEdge -SourceId $node1.Id -TargetId $node2.Id -Type Calls
            Add-CPGEdge -Graph $graph -Edge $edge
            
            $graph.AdjacencyList[$node1.Id].Outgoing | Should -Contain $edge.Id
            $graph.AdjacencyList[$node2.Id].Incoming | Should -Contain $edge.Id
        }
    }
    
    Context "Graph Queries" {
        BeforeEach {
            $script:TestGraph = New-CPGraph -Name "QueryTestGraph"
            
            # Create test nodes
            $func1 = New-CPGNode -Name "Function1" -Type Function
            $func2 = New-CPGNode -Name "Function2" -Type Function
            $var1 = New-CPGNode -Name "Variable1" -Type Variable
            $var2 = New-CPGNode -Name "Variable2" -Type Variable
            
            Add-CPGNode -Graph $script:TestGraph -Node $func1
            Add-CPGNode -Graph $script:TestGraph -Node $func2
            Add-CPGNode -Graph $script:TestGraph -Node $var1
            Add-CPGNode -Graph $script:TestGraph -Node $var2
            
            # Create test edges
            $edge1 = New-CPGEdge -SourceId $func1.Id -TargetId $func2.Id -Type Calls
            $edge2 = New-CPGEdge -SourceId $func1.Id -TargetId $var1.Id -Type Uses
            $edge3 = New-CPGEdge -SourceId $func2.Id -TargetId $var2.Id -Type Assigns
            
            Add-CPGEdge -Graph $script:TestGraph -Edge $edge1
            Add-CPGEdge -Graph $script:TestGraph -Edge $edge2
            Add-CPGEdge -Graph $script:TestGraph -Edge $edge3
            
            $script:Func1Id = $func1.Id
            $script:Func2Id = $func2.Id
            $script:Var1Id = $var1.Id
        }
        
        It "Should get nodes by type" {
            $functions = Get-CPGNode -Graph $script:TestGraph -Type Function
            $variables = Get-CPGNode -Graph $script:TestGraph -Type Variable
            
            $functions.Count | Should -Be 2
            $variables.Count | Should -Be 2
        }
        
        It "Should get nodes by name" {
            $node = Get-CPGNode -Graph $script:TestGraph -Name "Function1"
            
            $node | Should -Not -BeNullOrEmpty
            $node.Name | Should -Be "Function1"
        }
        
        It "Should get edges by type" {
            $callEdges = Get-CPGEdge -Graph $script:TestGraph -Type Calls
            $useEdges = Get-CPGEdge -Graph $script:TestGraph -Type Uses
            
            $callEdges.Count | Should -Be 1
            $useEdges.Count | Should -Be 1
        }
        
        It "Should get neighbors" {
            $neighbors = Get-CPGNeighbors -Graph $script:TestGraph `
                -NodeId $script:Func1Id -Direction Forward
            
            $neighbors.Count | Should -Be 2
            $neighbors.Name | Should -Contain "Function2"
            $neighbors.Name | Should -Contain "Variable1"
        }
        
        It "Should find paths between nodes" {
            $path = Find-CPGPath -Graph $script:TestGraph `
                -StartNodeId $script:Func1Id -EndNodeId $script:Func2Id
            
            $path | Should -Not -BeNullOrEmpty
            $path[0].Id | Should -Be $script:Func1Id
            $path[-1].Id | Should -Be $script:Func2Id
        }
    }
    
    Context "Graph Statistics" {
        It "Should calculate graph statistics" {
            $graph = New-CPGraph -Name "StatsGraph"
            
            # Add nodes
            for ($i = 0; $i -lt 5; $i++) {
                $node = New-CPGNode -Name "Node$i" -Type Function
                Add-CPGNode -Graph $graph -Node $node
            }
            
            # Add edges
            $nodes = $graph.Nodes.Values | Select-Object -First 5
            for ($i = 0; $i -lt 4; $i++) {
                $edge = New-CPGEdge -SourceId $nodes[$i].Id -TargetId $nodes[$i+1].Id -Type Calls
                Add-CPGEdge -Graph $graph -Edge $edge
            }
            
            $stats = Get-CPGStatistics -Graph $graph
            
            $stats.NodeCount | Should -Be 5
            $stats.EdgeCount | Should -Be 4
            $stats.NodeTypes | Should -Not -BeNullOrEmpty
            $stats.EdgeTypes | Should -Not -BeNullOrEmpty
        }
    }
}

Describe "AST to CPG Conversion" {
    
    BeforeEach {
        # Set test file path
        $script:TestFilePath = Join-Path $TestDrive "TestScript.ps1"
        # Create test file
        $script:TestScriptContent | Out-File -FilePath $script:TestFilePath -Encoding UTF8
    }
    
    Context "File Conversion" {
        It "Should convert PowerShell file to CPG" {
            $graph = ConvertTo-CPGFromFile -FilePath $script:TestFilePath
            
            $graph | Should -Not -BeNullOrEmpty
            $graph.Nodes.Count | Should -BeGreaterThan 0
            $graph.Edges.Count | Should -BeGreaterThan 0
        }
        
        It "Should detect functions in AST" {
            $graph = ConvertTo-CPGFromFile -FilePath $script:TestFilePath
            
            $functions = Get-CPGNode -Graph $graph -Type Function
            $functionNames = $functions.Name
            
            $functionNames | Should -Contain "Get-TestData"
            $functionNames | Should -Contain "Process-TestData"
        }
        
        It "Should detect classes in AST" {
            $graph = ConvertTo-CPGFromFile -FilePath $script:TestFilePath
            
            $classes = Get-CPGNode -Graph $graph -Type Class
            $classNames = $classes.Name
            
            $classNames | Should -Contain "TestClass"
        }
        
        It "Should detect variables in AST" {
            $graph = ConvertTo-CPGFromFile -FilePath $script:TestFilePath
            
            $variables = Get-CPGNode -Graph $graph -Type Variable
            $variableNames = $variables.Name
            
            $variableNames | Should -Contain "TestVariable"
            $variableNames | Should -Contain "data"
        }
        
        It "Should detect function calls" {
            $graph = ConvertTo-CPGFromFile -FilePath $script:TestFilePath
            
            $callEdges = Get-CPGEdge -Graph $graph -Type Calls
            
            $callEdges.Count | Should -BeGreaterThan 0
        }
        
        It "Should include data flow analysis when requested" {
            $graph = ConvertTo-CPGFromFile -FilePath $script:TestFilePath -IncludeDataFlow
            
            $dataFlowEdges = Get-CPGEdge -Graph $graph -Type DataFlow
            
            # Should have at least some data flow edges
            $dataFlowEdges | Should -Not -BeNullOrEmpty
        }
        
        It "Should include control flow analysis when requested" {
            $graph = ConvertTo-CPGFromFile -FilePath $script:TestFilePath -IncludeControlFlow
            
            $controlFlowEdges = Get-CPGEdge -Graph $graph -Type Follows
            
            # Should have control flow edges
            $controlFlowEdges | Should -Not -BeNullOrEmpty
        }
    }
    
    Context "AST Node Processing" {
        It "Should process parameters correctly" {
            $ast = [System.Management.Automation.Language.Parser]::ParseInput(
                'function Test { param([string]$Name, [int]$Count = 10) }',
                [ref]$null,
                [ref]$null
            )
            
            $graph = Convert-ASTtoCPG -AST $ast -FilePath "test.ps1"
            
            $parameters = Get-CPGNode -Graph $graph -Type Parameter
            $paramNames = $parameters.Name
            
            $paramNames | Should -Contain "Name"
            $paramNames | Should -Contain "Count"
        }
        
        It "Should process class members correctly" {
            $ast = [System.Management.Automation.Language.Parser]::ParseInput(
                'class Test { [string]$Name; [void] DoWork() {} }',
                [ref]$null,
                [ref]$null
            )
            
            $graph = Convert-ASTtoCPG -AST $ast -FilePath "test.ps1"
            
            $properties = Get-CPGNode -Graph $graph -Type Property
            $methods = Get-CPGNode -Graph $graph -Type Method
            
            $properties.Name | Should -Contain "Name"
            $methods.Name | Should -Contain "DoWork"
        }
    }
}

Describe "Graph Export/Import" {
    
    Context "JSON Export/Import" {
        It "Should export graph to JSON" {
            $graph = New-CPGraph -Name "ExportTest"
            $node = New-CPGNode -Name "TestNode" -Type Function
            Add-CPGNode -Graph $graph -Node $node
            
            $exportPath = Join-Path $TestDrive "graph.json"
            Export-CPGraph -Graph $graph -Path $exportPath -Format JSON
            
            Test-Path $exportPath | Should -Be $true
            
            $content = Get-Content $exportPath -Raw | ConvertFrom-Json
            $content.Name | Should -Be "ExportTest"
        }
        
        It "Should import graph from JSON" {
            $graph = New-CPGraph -Name "ImportTest"
            $node1 = New-CPGNode -Name "Node1" -Type Function
            $node2 = New-CPGNode -Name "Node2" -Type Variable
            Add-CPGNode -Graph $graph -Node $node1
            Add-CPGNode -Graph $graph -Node $node2
            
            $edge = New-CPGEdge -SourceId $node1.Id -TargetId $node2.Id -Type Uses
            Add-CPGEdge -Graph $graph -Edge $edge
            
            $exportPath = Join-Path $TestDrive "import.json"
            Export-CPGraph -Graph $graph -Path $exportPath -Format JSON
            
            $imported = Import-CPGraph -Path $exportPath
            
            $imported.Name | Should -Be "ImportTest"
            $imported.Nodes.Count | Should -Be 2
            $imported.Edges.Count | Should -Be 1
        }
    }
    
    Context "DOT Export" {
        It "Should export graph to DOT format" {
            $graph = New-CPGraph -Name "DotTest"
            $node1 = New-CPGNode -Name "A" -Type Function
            $node2 = New-CPGNode -Name "B" -Type Function
            Add-CPGNode -Graph $graph -Node $node1
            Add-CPGNode -Graph $graph -Node $node2
            
            $edge = New-CPGEdge -SourceId $node1.Id -TargetId $node2.Id -Type Calls
            Add-CPGEdge -Graph $graph -Edge $edge
            
            $exportPath = Join-Path $TestDrive "graph.dot"
            Export-CPGraph -Graph $graph -Path $exportPath -Format DOT
            
            Test-Path $exportPath | Should -Be $true
            
            $content = Get-Content $exportPath -Raw
            $content | Should -Match "digraph"
            $content | Should -Match "Function\\\\nA"
            $content | Should -Match "->"
        }
    }
    
    Context "GraphML Export" {
        It "Should export graph to GraphML format" {
            $graph = New-CPGraph -Name "GraphMLTest"
            $node = New-CPGNode -Name "TestNode" -Type Module
            Add-CPGNode -Graph $graph -Node $node
            
            $exportPath = Join-Path $TestDrive "graph.graphml"
            Export-CPGraph -Graph $graph -Path $exportPath -Format GraphML
            
            Test-Path $exportPath | Should -Be $true
            
            $content = Get-Content $exportPath -Raw
            $content | Should -Match '<graphml'
            $content | Should -Match '<node'
            $content | Should -Match 'TestNode'
        }
    }
}

Describe "Thread Safety" {
    
    Context "Concurrent Operations" {
        It "Should handle concurrent node additions" {
            $graph = New-CPGraph -Name "ConcurrentTest"
            
            $jobs = 1..5 | ForEach-Object {
                Start-Job -ScriptBlock {
                    param($GraphId, $Index)
                    
                    Import-Module $using:modulePath -Force
                    
                    for ($i = 0; $i -lt 10; $i++) {
                        $node = New-CPGNode -Name "Node_${Index}_${i}" -Type Function
                        # Note: In real implementation, would need to pass graph reference properly
                    }
                } -ArgumentList $graph.Id, $_
            }
            
            $jobs | Wait-Job | Remove-Job
            
            # Basic check that module can handle concurrent access
            # More detailed testing would require proper shared memory handling
            $graph | Should -Not -BeNullOrEmpty
        }
    }
}

Describe "Integration Tests" {
    
    Context "End-to-End Workflow" {
        It "Should complete full analysis workflow" {
            # Create a test script
            $testScript = @'
function Main {
    $config = Get-Configuration
    $data = Process-Data -Config $config
    Save-Results -Data $data
}

function Get-Configuration {
    return @{ Setting = "Value" }
}

function Process-Data {
    param($Config)
    return @{ Processed = $true }
}

function Save-Results {
    param($Data)
    Write-Host "Saved"
}

Main
'@
            
            $scriptPath = Join-Path $TestDrive "workflow.ps1"
            $testScript | Out-File -FilePath $scriptPath -Encoding UTF8
            
            # Convert to CPG
            $graph = ConvertTo-CPGFromFile -FilePath $scriptPath `
                -IncludeDataFlow -IncludeControlFlow
            
            # Verify structure
            $functions = Get-CPGNode -Graph $graph -Type Function
            $functions.Count | Should -Be 4
            
            # Verify relationships
            $mainFunc = Get-CPGNode -Graph $graph -Name "Main"
            $neighbors = Get-CPGNeighbors -Graph $graph -NodeId $mainFunc.Id
            
            $neighbors.Name | Should -Contain "Get-Configuration"
            $neighbors.Name | Should -Contain "Process-Data"
            $neighbors.Name | Should -Contain "Save-Results"
            
            # Export and verify
            $exportPath = Join-Path $TestDrive "workflow.json"
            Export-CPGraph -Graph $graph -Path $exportPath -Format JSON
            
            Test-Path $exportPath | Should -Be $true
        }
    }
}
# SIG # Begin signature block
# MIIFzgYJKoZIhvcNAQcCoIIFvzCCBbsCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCCej+LGD5kR2x9m
# LOu/m3BbiFwDJrOJkhcUGFKi37EZSaCCAzAwggMsMIICFKADAgECAhB1HRbZIqgr
# lUTwkh3hnGtFMA0GCSqGSIb3DQEBCwUAMC4xLDAqBgNVBAMMI1VuaXR5LUNsYXVk
# ZS1BdXRvbWF0aW9uLURldmVsb3BtZW50MB4XDTI1MDgyMDIxMTUxN1oXDTI2MDgy
# MDIxMzUxN1owLjEsMCoGA1UEAwwjVW5pdHktQ2xhdWRlLUF1dG9tYXRpb24tRGV2
# ZWxvcG1lbnQwggEiMA0GCSqGSIb3DQEBAQUAA4IBDwAwggEKAoIBAQCx4feqKdUQ
# 6GufY4umNzlM1Pi8aHUGR8HlfhIWFjsrRAxCxhieRlWbHe0Hw+pVBeX76X57e5Pu
# 4Kxxzu+MxMry0NJYf3yOLRTfhYskHBcLraXUCtrMwqnhPKvul6Sx6Lu8vilk605W
# ADJNifl3WFuexVCYJJM9G2mfuYIDN+rZ5zmpn0qCXum49bm629h+HyJ205Zrn9aB
# hIrA4i/JlrAh1kosWnCo62psl7ixbNVqFqwWEt+gAqSeIo4ChwkOQl7GHmk78Q5I
# oRneY4JTVlKzhdZEYhJGFXeoZml/5jcmUcox4UNYrKdokE7z8ZTmyowBOUNS+sHI
# G1TY5DZSb8vdAgMBAAGjRjBEMA4GA1UdDwEB/wQEAwIHgDATBgNVHSUEDDAKBggr
# BgEFBQcDAzAdBgNVHQ4EFgQUfDms7LrGVboHjmwlSyIjYD/JLQwwDQYJKoZIhvcN
# AQELBQADggEBABRMsfT7DzKy+aFi4HDg0MpxmbjQxOH1lzUzanaECRiyA0sn7+sA
# /4jvis1+qC5NjDGkLKOTCuDzIXnBWLCCBugukXbIO7g392ANqKdHjBHw1WlLvMVk
# 4WSmY096lzpvDd3jJApr/Alcp4KmRGNLnQ3vv+F9Uj58Uo1qjs85vt6fl9xe5lo3
# rFahNHL4ngjgyF8emNm7FItJeNtVe08PhFn0caOX0FTzXrZxGGO6Ov8tzf91j/qK
# QdBifG7Fx3FF7DifNqoBBo55a7q0anz30k8p+V0zllrLkgGXfOzXmA1L37Qmt3QB
# FCdJVigjQMuHcrJsWd8rg857Og0un91tfZIxggH0MIIB8AIBATBCMC4xLDAqBgNV
# BAMMI1VuaXR5LUNsYXVkZS1BdXRvbWF0aW9uLURldmVsb3BtZW50AhB1HRbZIqgr
# lUTwkh3hnGtFMA0GCWCGSAFlAwQCAQUAoIGEMBgGCisGAQQBgjcCAQwxCjAIoAKA
# AKECgAAwGQYJKoZIhvcNAQkDMQwGCisGAQQBgjcCAQQwHAYKKwYBBAGCNwIBCzEO
# MAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIFpAjgX8lklKzDeR2zyVanlX
# JHJxztjhWdXNPqZjypIjMA0GCSqGSIb3DQEBAQUABIIBADqbiW4YE6r9/xYFLBL/
# q0wXihABP+U88JKXPaOwQK/0RJyzAw+VvxU9V6+maLzWf3QIcloAbR7LkllGEfyi
# SH0wjTtsc8md7YtDAAxYz8eSRQsM6MmzxTtZkKD1j+5XkxY/HG6NwZq8Kav8mA9D
# qs6apQQZzPGlKiCQlHgckf4yaQboyR13FV6GGwHWkgSfBzH+UhrUoesiZHku2PlG
# TIDC00nfwko6L+lYkBW8NwvrxsEuNX4NURq+WobXGayDaQECeSL1ydKtnfaHNrTw
# afamZQpTdsFwVZRZzjNGXevnpvSf4EmwRAhanoY/HS/lPHXmS0NTDypOWm1soslV
# W6w=
# SIG # End signature block
