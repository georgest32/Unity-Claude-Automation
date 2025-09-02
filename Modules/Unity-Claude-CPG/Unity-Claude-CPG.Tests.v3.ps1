#Requires -Version 5.0
#Requires -Modules Pester

<#
.SYNOPSIS
    Unity-Claude-CPG Module Tests - Pester v3 Compatible
.DESCRIPTION
    Comprehensive test suite for the Unity-Claude-CPG module
    Compatible with Pester version 3.x
#>

$ErrorActionPreference = 'Stop'

# Module import and test setup
$modulePath = Join-Path $PSScriptRoot "Unity-Claude-CPG.psd1"
Import-Module $modulePath -Force

# Test data
$script:TestScriptContent = @'
function Get-TestData {
    [CmdletBinding()]
    param(
        [string]$Name = "Default",
        [int]$Count = 10
    )
    
    $data = @()
    for ($i = 0; $i -lt $Count; $i++) {
        $data += "Item$i"
    }
    return $data
}

function Process-TestData {
    param($Data)
    Write-Host "Processing $($Data.Count) items"
}

class TestClass {
    [string]$Name
    [int]$Value
    
    TestClass([string]$name, [int]$value) {
        $this.Name = $name
        $this.Value = $value
    }
    
    [string] ToString() {
        return "$($this.Name): $($this.Value)"
    }
}

$globalVar = "TestGlobal"
$result = Get-TestData -Name "Test" -Count 5
Process-TestData -Data $result
'@

Describe "CPG Node Operations" {
    
    Context "Node Creation" {
        It "Should create a node with correct properties" {
            $node = New-CPGNode -Type Function -Name "TestFunction" -Metadata @{Param="Value"}
            
            $node | Should Not BeNullOrEmpty
            $node.Type | Should Be "Function"
            $node.Name | Should Be "TestFunction"
            $node.Id | Should Not BeNullOrEmpty
            $node.Metadata.Param | Should Be "Value"
        }
        
        It "Should create nodes with different types" {
            $types = @('Function', 'Variable', 'Class', 'Method', 'Property', 'Parameter')
            
            foreach ($type in $types) {
                $node = New-CPGNode -Type $type -Name "Test$type"
                $node.Type | Should Be $type
            }
        }
        
        It "Should store metadata and properties" {
            $metadata = @{
                Author = "Test"
                Version = "1.0"
                Tags = @("test", "sample")
            }
            $node = New-CPGNode -Type Function -Name "TestFunc" -Metadata $metadata
            $node.Metadata.Author | Should Be "Test"
            $node.Metadata.Version | Should Be "1.0"
            $node.Metadata.Tags.Count | Should Be 2
        }
        
        It "Should track file location information" {
            $node = New-CPGNode -Type Function -Name "TestFunc" -FilePath "test.ps1" -StartLine 10 -EndLine 20
            $node.FilePath | Should Be "test.ps1"
            $node.StartLine | Should Be 10
            $node.EndLine | Should Be 20
        }
    }
    
    Context "Node Serialization" {
        It "Should convert node to hashtable" {
            $node = New-CPGNode -Type Function -Name "TestFunc"
            $hashtable = ConvertTo-CPGNodeHashtable -Node $node
            
            $hashtable.GetType().Name | Should Be "Hashtable"
            $hashtable.Type | Should Be "Function"
            $hashtable.Name | Should Be "TestFunc"
        }
    }
}

Describe "CPG Edge Operations" {
    
    Context "Edge Creation" {
        It "Should create an edge with correct properties" {
            $source = New-CPGNode -Type Function -Name "SourceFunc"
            $target = New-CPGNode -Type Variable -Name "TargetVar"
            $edge = New-CPGEdge -Source $source -Target $target -Type "Uses"
            
            $edge | Should Not BeNullOrEmpty
            $edge.SourceId | Should Be $source.Id
            $edge.TargetId | Should Be $target.Id
            $edge.Type | Should Be "Uses"
        }
        
        It "Should support different edge types" {
            $source = New-CPGNode -Type Function -Name "Func"
            $target = New-CPGNode -Type Variable -Name "Var"
            
            $edgeTypes = @('Uses', 'Defines', 'Calls', 'Contains', 'Inherits', 'References')
            foreach ($type in $edgeTypes) {
                $edge = New-CPGEdge -Source $source -Target $target -Type $type
                $edge.Type | Should Be $type
            }
        }
        
        It "Should support edge weights" {
            $source = New-CPGNode -Type Function -Name "Func"
            $target = New-CPGNode -Type Variable -Name "Var"
            $edge = New-CPGEdge -Source $source -Target $target -Type "Uses" -Weight 0.8
            
            $edge.Weight | Should Be 0.8
        }
    }
}

Describe "CPG Graph Operations" {
    
    Context "Graph Creation and Management" {
        It "Should create an empty graph" {
            $graph = New-CPGraph -Name "TestGraph"
            $graph | Should Not BeNullOrEmpty
            $graph.Name | Should Be "TestGraph"
            $graph.Nodes | Should Not BeNullOrEmpty
            $graph.Edges | Should Not BeNullOrEmpty
            $graph.Nodes.Count | Should Be 0
            $graph.Edges.Count | Should Be 0
        }
        
        It "Should add nodes to graph" {
            $graph = New-CPGraph -Name "TestGraph"
            $node1 = New-CPGNode -Type Function -Name "Func1"
            $node2 = New-CPGNode -Type Variable -Name "Var1"
            
            Add-CPGNode -Graph $graph -Node $node1
            Add-CPGNode -Graph $graph -Node $node2
            
            $graph.Nodes.Count | Should Be 2
            $graph.Nodes.ContainsKey($node1.Id) | Should Be $true
            $graph.Nodes.ContainsKey($node2.Id) | Should Be $true
        }
        
        It "Should add edges to graph" {
            $graph = New-CPGraph -Name "TestGraph"
            $node1 = New-CPGNode -Type Function -Name "Func1"
            $node2 = New-CPGNode -Type Variable -Name "Var1"
            
            Add-CPGNode -Graph $graph -Node $node1
            Add-CPGNode -Graph $graph -Node $node2
            
            $edge = New-CPGEdge -Source $node1 -Target $node2 -Type "Uses"
            Add-CPGEdge -Graph $graph -Edge $edge
            
            $graph.Edges.Count | Should Be 1
        }
        
        It "Should maintain adjacency list" {
            $graph = New-CPGraph -Name "TestGraph"
            $node1 = New-CPGNode -Type Function -Name "Func1"
            $node2 = New-CPGNode -Type Variable -Name "Var1"
            
            Add-CPGNode -Graph $graph -Node $node1
            Add-CPGNode -Graph $graph -Node $node2
            
            $edge = New-CPGEdge -Source $node1 -Target $node2 -Type "Uses"
            Add-CPGEdge -Graph $graph -Edge $edge
            
            $graph.AdjacencyList[$node1.Id] | Should Not BeNullOrEmpty
            $graph.AdjacencyList[$node1.Id] -contains $node2.Id | Should Be $true
        }
    }
    
    Context "Graph Queries" {
        BeforeEach {
            $script:TestGraph = New-CPGraph -Name "QueryTestGraph"
            
            # Add various nodes
            $func1 = New-CPGNode -Type Function -Name "GetData"
            $func2 = New-CPGNode -Type Function -Name "SetData"
            $var1 = New-CPGNode -Type Variable -Name "data"
            $var2 = New-CPGNode -Type Variable -Name "result"
            $class1 = New-CPGNode -Type Class -Name "DataClass"
            
            Add-CPGNode -Graph $script:TestGraph -Node $func1
            Add-CPGNode -Graph $script:TestGraph -Node $func2
            Add-CPGNode -Graph $script:TestGraph -Node $var1
            Add-CPGNode -Graph $script:TestGraph -Node $var2
            Add-CPGNode -Graph $script:TestGraph -Node $class1
            
            # Add edges
            Add-CPGEdge -Graph $script:TestGraph -Edge (New-CPGEdge -Source $func1 -Target $var1 -Type "Uses")
            Add-CPGEdge -Graph $script:TestGraph -Edge (New-CPGEdge -Source $func1 -Target $var2 -Type "Defines")
            Add-CPGEdge -Graph $script:TestGraph -Edge (New-CPGEdge -Source $func2 -Target $var1 -Type "Uses")
            Add-CPGEdge -Graph $script:TestGraph -Edge (New-CPGEdge -Source $class1 -Target $func1 -Type "Contains")
        }
        
        It "Should get nodes by type" {
            $functions = Get-CPGNode -Graph $script:TestGraph -Type Function
            $functions.Count | Should Be 2
            
            $variables = Get-CPGNode -Graph $script:TestGraph -Type Variable
            $variables.Count | Should Be 2
            
            $classes = Get-CPGNode -Graph $script:TestGraph -Type Class
            $classes.Count | Should Be 1
        }
        
        It "Should get nodes by name" {
            $node = Get-CPGNode -Graph $script:TestGraph -Name "GetData"
            $node | Should Not BeNullOrEmpty
            $node.Name | Should Be "GetData"
        }
        
        It "Should get edges by type" {
            $usesEdges = Get-CPGEdge -Graph $script:TestGraph -Type "Uses"
            $usesEdges.Count | Should Be 2
            
            $definesEdges = Get-CPGEdge -Graph $script:TestGraph -Type "Defines"
            $definesEdges.Count | Should Be 1
        }
        
        It "Should get neighbors" {
            $func1 = Get-CPGNode -Graph $script:TestGraph -Name "GetData"
            $neighbors = Get-CPGNeighbors -Graph $script:TestGraph -NodeId $func1.Id
            $neighbors.Count | Should Be 2
        }
        
        It "Should find paths between nodes" {
            $func1 = Get-CPGNode -Graph $script:TestGraph -Name "GetData"
            $var2 = Get-CPGNode -Graph $script:TestGraph -Name "result"
            $paths = Find-CPGPath -Graph $script:TestGraph -StartNodeId $func1.Id -EndNodeId $var2.Id
            $paths | Should Not BeNullOrEmpty
        }
    }
    
    Context "Graph Statistics" {
        It "Should calculate graph statistics" {
            $graph = New-CPGraph -Name "StatsGraph"
            
            # Add nodes
            for ($i = 0; $i -lt 10; $i++) {
                Add-CPGNode -Graph $graph -Node (New-CPGNode -Type Function -Name "Func$i")
            }
            
            # Add some edges
            $nodes = $graph.Nodes.Values | Select-Object -First 5
            for ($i = 0; $i -lt 4; $i++) {
                Add-CPGEdge -Graph $graph -Edge (New-CPGEdge -Source $nodes[$i] -Target $nodes[$i+1] -Type "Calls")
            }
            
            $stats = Get-CPGStatistics -Graph $graph
            $stats | Should Not BeNullOrEmpty
            $stats.NodeCount | Should Be 10
            $stats.EdgeCount | Should Be 4
            $stats.AverageOutDegree | Should BeGreaterThan 0
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
            
            $graph | Should Not BeNullOrEmpty
            $graph.Nodes.Count | Should BeGreaterThan 0
            $graph.Edges.Count | Should BeGreaterThan 0
        }
        
        It "Should detect functions in AST" {
            $graph = ConvertTo-CPGFromFile -FilePath $script:TestFilePath
            
            $functions = Get-CPGNode -Graph $graph -Type Function
            $functionNames = $functions | ForEach-Object { $_.Name }
            
            $functionNames -contains "Get-TestData" | Should Be $true
            $functionNames -contains "Process-TestData" | Should Be $true
        }
        
        It "Should detect classes in AST" {
            $graph = ConvertTo-CPGFromFile -FilePath $script:TestFilePath
            
            $classes = Get-CPGNode -Graph $graph -Type Class
            $classNames = $classes | ForEach-Object { $_.Name }
            
            $classNames -contains "TestClass" | Should Be $true
        }
        
        It "Should detect variables in AST" {
            $graph = ConvertTo-CPGFromFile -FilePath $script:TestFilePath
            
            $variables = Get-CPGNode -Graph $graph -Type Variable
            $varNames = $variables | ForEach-Object { $_.Name }
            
            $varNames -contains "globalVar" | Should Be $true
            $varNames -contains "result" | Should Be $true
        }
        
        It "Should detect function calls" {
            $graph = ConvertTo-CPGFromFile -FilePath $script:TestFilePath
            
            $calls = Get-CPGEdge -Graph $graph -Type "Calls"
            $calls | Should Not BeNullOrEmpty
        }
    }
}

Describe "Graph Export/Import" {
    
    Context "JSON Export/Import" {
        It "Should export graph to JSON" {
            $graph = New-CPGraph -Name "ExportTest"
            Add-CPGNode -Graph $graph -Node (New-CPGNode -Type Function -Name "TestFunc")
            
            $json = Export-CPGToJson -Graph $graph
            $json | Should Not BeNullOrEmpty
            
            # Should be valid JSON
            { $json | ConvertFrom-Json } | Should Not Throw
        }
        
        It "Should import graph from JSON" {
            $originalGraph = New-CPGraph -Name "ImportTest"
            $node = New-CPGNode -Type Function -Name "TestFunc"
            Add-CPGNode -Graph $originalGraph -Node $node
            
            $json = Export-CPGToJson -Graph $originalGraph
            $importedGraph = Import-CPGFromJson -Json $json
            
            $importedGraph | Should Not BeNullOrEmpty
            $importedGraph.Name | Should Be "ImportTest"
            $importedGraph.Nodes.Count | Should Be 1
        }
    }
}

# Run a simple verification
Write-Host "`nCPG Module Tests - Pester v3 Compatible" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
# SIG # Begin signature block
# MIIFzgYJKoZIhvcNAQcCoIIFvzCCBbsCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCBxXKLKwi44II8J
# XgeETHh3K5on6vKxXE39KFr1pZxoLKCCAzAwggMsMIICFKADAgECAhB1HRbZIqgr
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
# MAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIAPSx4RQvSiqKo4U2+qeiX7s
# /VC5t9unHQyQVnGmw26gMA0GCSqGSIb3DQEBAQUABIIBAHOV6RjT+m1mOXdAnw8C
# Hb1OUXCqBwndbeYZH9GkXy3lK79wELdL0Yu698pXxJchYv3f4usdD28yytrZTeUg
# AxpmV45cXd5CJQPK5afhCuCoxFkLzTEi2doq1z+melTXQTPhFwSOTDXZn+5TcfuO
# g5yIi3N5I4Xka17zlYhPsO1jKuAREPOmx/vkzzi5+VFvI9AM4kQoB5sAt6n2eN/o
# mkEUqc567VP21g9ybnn2YU2aW8mmCtQwHuCaiQYFnyzalPdkP/1IIuZ5N7E71Yy0
# x5QN23lVwrLRdf9RDMjoB9NviXLc6PjoxlyxXDVEIffRbSpoHPTWM565PB4O5O2V
# img=
# SIG # End signature block
