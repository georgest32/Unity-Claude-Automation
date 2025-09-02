#region Graph Traversal for Unreachable Code Component
<#
.SYNOPSIS
    Unity Claude CPG - Graph Traversal for Unreachable Code Component
    
.DESCRIPTION
    Implements graph traversal algorithms to identify unreachable code sections using
    Code Property Graph analysis. Performs reachability analysis using breadth-first
    search to find functions, classes, and code blocks that are never called or referenced.
    
    Key capabilities:
    - Auto-detection of entry points (main functions, exported functions, public methods)
    - BFS-based reachability analysis across CPG nodes
    - Unreachable code identification with severity assessment
    - File-based grouping and statistical reporting
    - Parent-child relationship tracking for comprehensive analysis
    
.VERSION
    2.0.0 - Refactored modular component
    
.DEPENDENCIES
    - Unity-Claude-CPG (Code Property Graph analysis)
    
.AUTHOR
    Unity-Claude-Automation Framework
#>

# Import required dependencies
$cpgModule = Join-Path (Split-Path $PSScriptRoot -Parent) "Unity-Claude-CPG.psd1"
if (Test-Path $cpgModule) {
    Import-Module $cpgModule -Force -ErrorAction SilentlyContinue
}

# Load CPG enums
$enumPath = Join-Path (Split-Path $PSScriptRoot -Parent) "Unity-Claude-CPG-Enums.ps1"
if (Test-Path $enumPath) {
    . $enumPath
}

#region Graph Traversal for Unreachable Code

function Find-UnreachableCode {
    <#
    .SYNOPSIS
        Finds unreachable code using CPG graph traversal
        
    .DESCRIPTION
        Analyzes the Code Property Graph to identify functions, classes, and code blocks
        that are never called or referenced using breadth-first search reachability analysis.
        
    .PARAMETER Graph
        The CPG graph to analyze
        
    .PARAMETER EntryPoints
        Array of entry point node IDs (e.g., main functions, exported functions)
        
    .OUTPUTS
        System.Collections.Hashtable
        Contains unreachable code analysis with statistics and file groupings
        
    .EXAMPLE
        $unreachable = Find-UnreachableCode -Graph $cpgGraph -EntryPoints @("main", "Start-Application")
        Write-Host "Found $($unreachable.UnreachableCode.Count) unreachable code sections"
        
    .EXAMPLE
        $unreachable = Find-UnreachableCode -Graph $cpgGraph
        $unreachable.ByFile | ForEach-Object { 
            Write-Host "File $($_.File) has $($_.Count) unreachable items"
        }
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        $Graph,
        
        [string[]]$EntryPoints = @()
    )
    
    try {
        Write-Verbose "Finding unreachable code in graph with $($Graph.Nodes.Count) nodes"
        
        # If no entry points specified, find them automatically
        if ($EntryPoints.Count -eq 0) {
            Write-Verbose "Auto-detecting entry points"
            
            # Find potential entry points
            $EntryPoints = @()
            
            # Main functions
            $EntryPoints += $Graph.Nodes.Values | 
                Where-Object { $_.Type -eq [CPGNodeType]::Function -and $_.Name -match "^(main|Main|Start|Initialize)" } |
                Select-Object -ExpandProperty Id
            
            # Exported functions (PowerShell modules)
            $EntryPoints += $Graph.Nodes.Values | 
                Where-Object { $_.Type -eq [CPGNodeType]::Function -and $_.Properties.IsExported -eq $true } |
                Select-Object -ExpandProperty Id
            
            # Public methods (classes)
            $EntryPoints += $Graph.Nodes.Values | 
                Where-Object { $_.Type -eq [CPGNodeType]::Method -and $_.Properties.Visibility -eq "Public" } |
                Select-Object -ExpandProperty Id
            
            # Event handlers
            $EntryPoints += $Graph.Nodes.Values | 
                Where-Object { $_.Type -eq [CPGNodeType]::Function -and $_.Name -match "(_Click|_Load|_Changed|Handler)$" } |
                Select-Object -ExpandProperty Id
            
            # Module-level code
            $EntryPoints += $Graph.Nodes.Values | 
                Where-Object { $_.Type -eq [CPGNodeType]::Module } |
                Select-Object -ExpandProperty Id
        }
        
        Write-Verbose "Found $($EntryPoints.Count) entry points"
        
        # Perform reachability analysis using BFS
        $reachable = @{}
        $queue = New-Object System.Collections.Queue
        
        # Initialize with entry points
        foreach ($entryPoint in $EntryPoints) {
            if ($Graph.Nodes.ContainsKey($entryPoint)) {
                $queue.Enqueue($entryPoint)
                $reachable[$entryPoint] = $true
            }
        }
        
        # Traverse graph
        while ($queue.Count -gt 0) {
            $currentId = $queue.Dequeue()
            
            # Find all outgoing edges
            $outgoingEdges = $Graph.Edges.Values | Where-Object { $_.Source -eq $currentId }
            
            foreach ($edge in $outgoingEdges) {
                if (-not $reachable.ContainsKey($edge.Target)) {
                    $reachable[$edge.Target] = $true
                    $queue.Enqueue($edge.Target)
                    
                    # Also mark parent nodes as reachable (e.g., class if method is reachable)
                    $targetNode = $Graph.Nodes[$edge.Target]
                    if ($targetNode -and $targetNode.Properties.ParentId) {
                        if (-not $reachable.ContainsKey($targetNode.Properties.ParentId)) {
                            $reachable[$targetNode.Properties.ParentId] = $true
                            $queue.Enqueue($targetNode.Properties.ParentId)
                        }
                    }
                }
            }
        }
        
        Write-Verbose "Found $($reachable.Count) reachable nodes"
        
        # Identify unreachable nodes
        $unreachableNodes = @()
        foreach ($node in $Graph.Nodes.Values) {
            # Only consider function/method/class nodes
            if ($node.Type -in @([CPGNodeType]::Function, [CPGNodeType]::Method, [CPGNodeType]::Class)) {
                if (-not $reachable.ContainsKey($node.Id)) {
                    $unreachableNodes += @{
                        Id = $node.Id
                        Name = $node.Name
                        Type = $node.Type
                        File = $node.Properties.FilePath
                        Line = $node.Properties.LineNumber
                        Severity = if ($node.Type -eq [CPGNodeType]::Class) { "High" } 
                                  elseif ($node.Properties.Size -gt 50) { "High" }
                                  else { "Medium" }
                    }
                }
            }
        }
        
        # Calculate statistics
        $totalNodesCount = @($Graph.Nodes.Values).Count
        $reachableCount = @($reachable.Keys).Count
        
        $stats = @{
            TotalNodes = $totalNodesCount
            ReachableNodes = $reachableCount
            UnreachableNodes = @($unreachableNodes).Count
            Coverage = if ($totalNodesCount -gt 0) { 
                [Math]::Round(([double]$reachableCount / [double]$totalNodesCount) * 100, 2)
            } else { 0 }
        }
        
        # Group by file
        $byFile = $unreachableNodes | Group-Object -Property { $_.File } | 
            ForEach-Object {
                @{
                    File = $_.Name
                    Count = $_.Count
                    Items = $_.Group
                }
            }
        
        # Ensure arrays are returned
        return @{
            UnreachableCode = @($unreachableNodes)
            Statistics = $stats
            ByFile = @($byFile)
            EntryPoints = @($EntryPoints)
            Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        }
    }
    catch {
        Write-Error "Failed to find unreachable code: $_"
        throw
    }
}

#endregion Graph Traversal for Unreachable Code

# Export public functions
Export-ModuleMember -Function @(
    'Find-UnreachableCode'
)

#endregion Graph Traversal for Unreachable Code Component
# SIG # Begin signature block
# MIIFzgYJKoZIhvcNAQcCoIIFvzCCBbsCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCAXShk+MTXOsKXE
# ZgN9oNxIYOMjIBSTVw8LBB4mNV2SmqCCAzAwggMsMIICFKADAgECAhB1HRbZIqgr
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
# MAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIG7IXB0zpisWuzI3lwOGBSlY
# H7y6AnOjqBap41fVEC7vMA0GCSqGSIb3DQEBAQUABIIBACWFN2AwyoaK3vCXYakl
# q0JQ5jUe/anDiKMCaarMWYeQnXEAUAejA/R3xQUDvJ2DHEufszvGDpeH45SA5XOR
# C71mP102Y3dl3t99foAMDKciCHTxchZ8dGDNPAiic98cClRF9IseL755Lrlatrk8
# 46V5DxLueDonjwmvEf/DvnXnyKNLSIhmBWNeia56OT+wbEaiyXz7qU4RaGxkHdr4
# lIGZfG3H0emJ+8+uFsv4T7Iq9XS0Ibv7aiHzAkviDzgP7WQ57tXqZ+ltf4Nj//IF
# /8xf0PAaVyzG2hiPA3e13mpK78Bw4wmTdHLM0hOernxs97A2kHeceCQhDjItViR0
# 2Dg=
# SIG # End signature block
