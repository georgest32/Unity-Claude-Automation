#Requires -Version 5.1
<#
.SYNOPSIS
    Core data structures for Code Property Graph (CPG) implementation.

.DESCRIPTION
    Contains enumerations and class definitions for CPG nodes, edges, and graphs.
    This module provides the foundational data types for the CPG system.

.NOTES
    Part of Unity-Claude-CPG refactored architecture
    Originally from Unity-Claude-CPG.psm1 (lines 32-245)
    Refactoring Date: 2025-08-25
#>

# Module-level variables for thread-safe graph storage
$script:CPGStorage = [hashtable]::Synchronized(@{})
$script:NodeIndex = [hashtable]::Synchronized(@{})
$script:EdgeIndex = [hashtable]::Synchronized(@{})
$script:GraphMetadata = [hashtable]::Synchronized(@{})
$script:CPGLock = [System.Threading.ReaderWriterLock]::new()

# Node type enumeration
enum CPGNodeType {
    Module
    Function
    Class
    Method
    Variable
    Parameter
    File
    Property
    Field
    Namespace
    Interface
    Enum
    Constant
    Label
    Comment
    Unknown
}

# Edge type enumeration
enum CPGEdgeType {
    Calls           # Function/method calls
    Uses            # Variable usage
    Imports         # Module imports
    Extends         # Class inheritance
    Implements      # Interface implementation
    DependsOn       # General dependency
    References      # Object references
    Assigns         # Variable assignment
    Returns         # Return values
    Throws          # Exception throwing
    Catches         # Exception handling
    Contains        # Containment relationship
    Follows         # Control flow
    DataFlow        # Data flow
    Overrides       # Method overriding
}

# Edge direction enumeration
enum EdgeDirection {
    Forward
    Backward
    Bidirectional
}

class CPGNode {
    [string]$Id
    [string]$Name
    [CPGNodeType]$Type
    [hashtable]$Properties
    [string]$FilePath
    [int]$StartLine
    [int]$EndLine
    [int]$StartColumn
    [int]$EndColumn
    [string]$Language
    [datetime]$CreatedAt
    [datetime]$ModifiedAt
    [hashtable]$Metadata
    
    CPGNode() {
        $this.Id = [guid]::NewGuid().ToString()
        $this.Properties = @{}
        $this.Metadata = @{}
        $this.CreatedAt = Get-Date
        $this.ModifiedAt = Get-Date
    }
    
    CPGNode([string]$name, [CPGNodeType]$type) {
        $this.Id = [guid]::NewGuid().ToString()
        $this.Name = $name
        $this.Type = $type
        $this.Properties = @{}
        $this.Metadata = @{}
        $this.CreatedAt = Get-Date
        $this.ModifiedAt = Get-Date
    }
    
    [string] ToString() {
        return "$($this.Type)::$($this.Name)"
    }
    
    [hashtable] ToHashtable() {
        return @{
            Id = $this.Id
            Name = $this.Name
            Type = $this.Type.ToString()
            Properties = $this.Properties
            FilePath = $this.FilePath
            StartLine = $this.StartLine
            EndLine = $this.EndLine
            StartColumn = $this.StartColumn
            EndColumn = $this.EndColumn
            Language = $this.Language
            CreatedAt = $this.CreatedAt
            ModifiedAt = $this.ModifiedAt
            Metadata = $this.Metadata
        }
    }
}

class CPGEdge {
    [string]$Id
    [string]$SourceId
    [string]$TargetId
    [CPGEdgeType]$Type
    [EdgeDirection]$Direction
    [hashtable]$Properties
    [double]$Weight
    [datetime]$CreatedAt
    [hashtable]$Metadata
    
    CPGEdge() {
        $this.Id = [guid]::NewGuid().ToString()
        $this.Properties = @{}
        $this.Metadata = @{}
        $this.Weight = 1.0
        $this.Direction = [EdgeDirection]::Forward
        $this.CreatedAt = Get-Date
    }
    
    CPGEdge([string]$sourceId, [string]$targetId, [CPGEdgeType]$type) {
        $this.Id = [guid]::NewGuid().ToString()
        $this.SourceId = $sourceId
        $this.TargetId = $targetId
        $this.Type = $type
        $this.Properties = @{}
        $this.Metadata = @{}
        $this.Weight = 1.0
        $this.Direction = [EdgeDirection]::Forward
        $this.CreatedAt = Get-Date
    }
    
    [string] ToString() {
        return "$($this.SourceId) -[$($this.Type)]-> $($this.TargetId)"
    }
    
    [hashtable] ToHashtable() {
        return @{
            Id = $this.Id
            SourceId = $this.SourceId
            TargetId = $this.TargetId
            Type = $this.Type.ToString()
            Direction = $this.Direction.ToString()
            Properties = $this.Properties
            Weight = $this.Weight
            CreatedAt = $this.CreatedAt
            Metadata = $this.Metadata
        }
    }
}

class CPGraph {
    [string]$Id
    [string]$Name
    [hashtable]$Nodes
    [hashtable]$Edges
    [hashtable]$AdjacencyList
    [hashtable]$Metadata
    [datetime]$CreatedAt
    [datetime]$ModifiedAt
    [int]$Version
    
    CPGraph() {
        $this.Id = [guid]::NewGuid().ToString()
        $this.Nodes = [hashtable]::Synchronized(@{})
        $this.Edges = [hashtable]::Synchronized(@{})
        $this.AdjacencyList = [hashtable]::Synchronized(@{})
        $this.Metadata = [hashtable]::Synchronized(@{})
        $this.CreatedAt = Get-Date
        $this.ModifiedAt = Get-Date
        $this.Version = 1
    }
    
    CPGraph([string]$name) {
        $this.Id = [guid]::NewGuid().ToString()
        $this.Name = $name
        $this.Nodes = [hashtable]::Synchronized(@{})
        $this.Edges = [hashtable]::Synchronized(@{})
        $this.AdjacencyList = [hashtable]::Synchronized(@{})
        $this.Metadata = [hashtable]::Synchronized(@{})
        $this.CreatedAt = Get-Date
        $this.ModifiedAt = Get-Date
        $this.Version = 1
    }
    
    [void] UpdateModifiedTime() {
        $this.ModifiedAt = Get-Date
        $this.Version++
    }
    
    [string] ToString() {
        return "CPGraph '$($this.Name)' (Nodes: $($this.Nodes.Count), Edges: $($this.Edges.Count))"
    }
    
    [hashtable] ToHashtable() {
        return @{
            Id = $this.Id
            Name = $this.Name
            NodesCount = $this.Nodes.Count
            EdgesCount = $this.Edges.Count
            CreatedAt = $this.CreatedAt
            ModifiedAt = $this.ModifiedAt
            Version = $this.Version
            Metadata = $this.Metadata
        }
    }
}

# Export data structures
Export-ModuleMember -Variable @(
    'CPGStorage',
    'NodeIndex', 
    'EdgeIndex',
    'GraphMetadata',
    'CPGLock'
)

# REFACTORING MARKER: This module was refactored from Unity-Claude-CPG.psm1 on 2025-08-25
# Original file size: 1013 lines
# This component: Core data structures and classes
# SIG # Begin signature block
# MIIFzgYJKoZIhvcNAQcCoIIFvzCCBbsCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCCtRCw9dZKPmdO3
# m5CMB1Cg4+puqamzcmPHWTo3jBb3oqCCAzAwggMsMIICFKADAgECAhB1HRbZIqgr
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
# MAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIGHnFdswJrPtbzJKqI+98UaU
# 2Lc+hYDlhp0a3jm/DwuSMA0GCSqGSIb3DQEBAQUABIIBAAs88SQhFksRSIJ3HnEx
# olwRi6ilc3NfyjYOH+PICMU3ZzNEEExmfe9QjWtLFE0d4uny0H5qDIMyMdfMrcqE
# eOj/SN9igTsUOXhI3VRF5N1EaKe3OssRmMO2djieMbfvkZsXgN0Zzaqa+6NYQAFw
# /7apqlDbVU8xOZWlwx08VhDUAa6lK5PuZaTAsi2PAnL/fYqFT8S0jLc3d3V17myy
# 1vBNOExS5+HO2MiXfKGPLFxor9VlLgw5yb2CxoGRUBP84UPCKNqPGLyPoWDTmyvw
# pouWNEVt8ilfaQ+sgY/urCBm+luM4zEQrRR/fVHlEftkCW37Jo5NoDVLIPhTsfDm
# ObI=
# SIG # End signature block
