
function Get-TopologicalSort {
    <#
    .SYNOPSIS
    Enhanced topological sorting with parallel execution detection and robust cycle validation.
    
    .DESCRIPTION
    Performs topological sorting on a dependency graph using both DFS and Kahn's algorithm approaches.
    Identifies parallel execution groups and provides comprehensive cycle detection.
    
    .PARAMETER DependencyGraph
    Hashtable where keys are nodes and values are arrays of dependencies.
    
    .PARAMETER EnableParallelGroups
    When enabled, returns parallel execution groups along with topological order.
    
    .PARAMETER Algorithm
    Choose between 'DFS' (default, backward compatible) or 'Kahn' algorithm.
    
    .EXAMPLE
    Get-TopologicalSort -DependencyGraph @{A=@();B=@('A');C=@('A');D=@('B','C')}
    
    .EXAMPLE
    Get-TopologicalSort -DependencyGraph $graph -EnableParallelGroups -Algorithm 'Kahn'
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [hashtable]$DependencyGraph,
        
        [Parameter()]
        [switch]$EnableParallelGroups,
        
        [Parameter()]
        [ValidateSet('DFS', 'Kahn')]
        [string]$Algorithm = 'DFS'
    )
    
    Write-SystemStatusLog "Performing topological sort on dependency graph with $($DependencyGraph.Keys.Count) nodes using $Algorithm algorithm" -Level 'DEBUG'
    
    # Enhanced input validation
    if ($DependencyGraph.Keys.Count -eq 0) {
        Write-SystemStatusLog "Empty dependency graph provided" -Level 'WARN'
        return @()
    }
    
    # Choose algorithm implementation
    if ($Algorithm -eq 'Kahn') {
        return Get-TopologicalSort-Kahn -DependencyGraph $DependencyGraph -EnableParallelGroups:$EnableParallelGroups
    } else {
        return Get-TopologicalSort-DFS -DependencyGraph $DependencyGraph -EnableParallelGroups:$EnableParallelGroups
    }
}

function Get-TopologicalSort-DFS {
    <#
    .SYNOPSIS
    DFS-based topological sorting with enhanced cycle detection and parallel group identification.
    #>
    [CmdletBinding()]
    param(
        [hashtable]$DependencyGraph,
        [switch]$EnableParallelGroups
    )
    
    [System.Collections.ArrayList]$result = @()
    $visited = @{}
    $visiting = @{}
    $nodeDepth = @{}
    
    function Visit-Node($node, $depth = 0) {
        # Optimized version with reduced logging for performance
        
        if ($visiting[$node]) { 
            # Simplified circular dependency detection for performance
            $errorMsg = "Circular dependency detected: $node"
            Write-SystemStatusLog $errorMsg -Level 'ERROR'
            throw $errorMsg 
        }
        if ($visited[$node]) { 
            return 
        }
        
        $visiting[$node] = $true
        $nodeDepth[$node] = $depth
        
        # Process dependencies if they exist
        if ($DependencyGraph.ContainsKey($node) -and $DependencyGraph[$node]) {
            foreach ($dependency in $DependencyGraph[$node]) {
                if ($dependency) {  # Only process non-null dependencies
                    Visit-Node $dependency ($depth + 1)
                }
            }
        }
        
        $visiting[$node] = $false
        $visited[$node] = $true
        [void]$result.Add($node)
    }
    
    try {
        foreach ($node in $DependencyGraph.Keys) {
            if (-not $visited[$node]) { 
                Visit-Node $node 
            }
        }
        
        Write-SystemStatusLog "DFS topological sort completed. Result order: $($result -join ', ')" -Level 'INFO'
        
        if ($EnableParallelGroups) {
            $parallelGroups = Get-ParallelExecutionGroups -TopologicalOrder $result -DependencyGraph $DependencyGraph -NodeDepth $nodeDepth
            return @{
                TopologicalOrder = @($result)
                ParallelGroups = $parallelGroups
                Algorithm = 'DFS'
            }
        } else {
            return @($result)
        }
    }
    catch {
        Write-SystemStatusLog "Error in DFS topological sort - $($_.Exception.Message)" -Level 'ERROR'
        throw
    }
}

function Get-TopologicalSort-Kahn {
    <#
    .SYNOPSIS
    Kahn's algorithm implementation with parallel execution group detection.
    #>
    [CmdletBinding()]
    param(
        [hashtable]$DependencyGraph,
        [switch]$EnableParallelGroups
    )
    
    Write-SystemStatusLog "Starting Kahn's algorithm for topological sorting" -Level 'DEBUG'
    
    # Build in-degree map and adjacency list
    $inDegree = @{}
    $adjacencyList = @{}
    $allNodes = @{}
    
    # Initialize all nodes
    foreach ($node in $DependencyGraph.Keys) {
        $allNodes[$node] = $true
        $inDegree[$node] = 0
        $adjacencyList[$node] = @()
        
        # Also track dependencies as nodes
        if ($DependencyGraph[$node]) {
            foreach ($dep in $DependencyGraph[$node]) {
                if ($dep) {
                    $allNodes[$dep] = $true
                    if (-not $inDegree.ContainsKey($dep)) {
                        $inDegree[$dep] = 0
                        $adjacencyList[$dep] = @()
                    }
                }
            }
        }
    }
    
    # Build edges and calculate in-degrees
    foreach ($node in $DependencyGraph.Keys) {
        if ($DependencyGraph[$node]) {
            foreach ($dependency in $DependencyGraph[$node]) {
                if ($dependency) {
                    # Edge from dependency to node (dependency must come first)
                    $adjacencyList[$dependency] += $node
                    $inDegree[$node]++
                }
            }
        }
    }
    
    $inDegreeInfo = ($inDegree.GetEnumerator() | ForEach-Object { "$($_.Key)=$($_.Value)" }) -join ', '
    Write-SystemStatusLog "Built graph: $($allNodes.Keys.Count) nodes, in-degrees: $inDegreeInfo" -Level 'DEBUG'
    
    # Find nodes with no incoming edges (can start immediately)
    $queue = [System.Collections.Queue]::new()
    $parallelGroups = @()
    $currentGroup = @()
    
    foreach ($node in $inDegree.Keys) {
        if ($inDegree[$node] -eq 0) {
            $queue.Enqueue($node)
            $currentGroup += $node
        }
    }
    
    if ($currentGroup.Count -gt 0) {
        $parallelGroups += ,@($currentGroup)
        Write-SystemStatusLog "Initial parallel group: $($currentGroup -join ', ')" -Level 'DEBUG'
    }
    
    [System.Collections.ArrayList]$result = @()
    $processedCount = 0
    
    # Process nodes level by level for parallel grouping
    while ($queue.Count -gt 0) {
        $currentLevelSize = $queue.Count
        $nextGroup = @()
        
        # Process all nodes at current level
        for ($i = 0; $i -lt $currentLevelSize; $i++) {
            $node = $queue.Dequeue()
            [void]$result.Add($node)
            $processedCount++
            
            # Reduce in-degree of adjacent nodes
            foreach ($adjacent in $adjacencyList[$node]) {
                $inDegree[$adjacent]--
                
                if ($inDegree[$adjacent] -eq 0) {
                    $queue.Enqueue($adjacent)
                    $nextGroup += $adjacent
                }
            }
        }
        
        # Add next parallel group if any nodes are ready
        if ($nextGroup.Count -gt 0) {
            $parallelGroups += ,@($nextGroup)
            Write-SystemStatusLog "Next parallel group: $($nextGroup -join ', ')" -Level 'DEBUG'
        }
    }
    
    # Check for cycles (if not all nodes were processed)
    if ($processedCount -ne $allNodes.Keys.Count) {
        $remaining = @()
        foreach ($node in $allNodes.Keys) {
            if ($inDegree[$node] -gt 0) {
                $nodeDegree = $inDegree[$node]
                $remaining += "$node(in-degree:$nodeDegree)"
            }
        }
        $errorMsg = "Circular dependency detected. Unprocessed nodes: $($remaining -join ', ')"
        Write-SystemStatusLog $errorMsg -Level 'ERROR'
        throw $errorMsg
    }
    
    Write-SystemStatusLog "Kahn's algorithm completed. Result order: $($result -join ', ')" -Level 'INFO'
    Write-SystemStatusLog "Parallel groups: $($parallelGroups.Count) groups identified" -Level 'INFO'
    
    if ($EnableParallelGroups) {
        return @{
            TopologicalOrder = @($result)
            ParallelGroups = $parallelGroups
            Algorithm = 'Kahn'
        }
    } else {
        return @($result)
    }
}

function Get-ParallelExecutionGroups {
    <#
    .SYNOPSIS
    Analyzes topological order to identify nodes that can execute in parallel.
    #>
    [CmdletBinding()]
    param(
        [array]$TopologicalOrder,
        [hashtable]$DependencyGraph,
        [hashtable]$NodeDepth
    )
    
    Write-SystemStatusLog "Analyzing parallel execution groups from topological order" -Level 'DEBUG'
    
    # Group nodes by depth level (nodes at same depth can run in parallel)
    $depthGroups = @{}
    
    foreach ($node in $TopologicalOrder) {
        $depth = if ($NodeDepth[$node] -ne $null) { $NodeDepth[$node] } else { 0 }
        if (-not $depthGroups.ContainsKey($depth)) {
            $depthGroups[$depth] = @()
        }
        $depthGroups[$depth] += $node
    }
    
    # Convert to ordered array of parallel groups
    $parallelGroups = @()
    $sortedDepths = $depthGroups.Keys | Sort-Object -Descending  # Deeper dependencies first
    
    foreach ($depth in $sortedDepths) {
        if ($depthGroups[$depth].Count -gt 0) {
            $parallelGroups += ,@($depthGroups[$depth])
            $groupNodes = $depthGroups[$depth] -join ', '
            Write-SystemStatusLog "Parallel group at depth ${depth}: $groupNodes" -Level 'DEBUG'
        }
    }
    
    return $parallelGroups
}
# SIG # Begin signature block
# MIIFqQYJKoZIhvcNAQcCoIIFmjCCBZYCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUbG5kg5e/MfvNbkGIPYSltotX
# WcSgggMwMIIDLDCCAhSgAwIBAgIQdR0W2SKoK5VE8JId4ZxrRTANBgkqhkiG9w0B
# AQsFADAuMSwwKgYDVQQDDCNVbml0eS1DbGF1ZGUtQXV0b21hdGlvbi1EZXZlbG9w
# bWVudDAeFw0yNTA4MjAyMTE1MTdaFw0yNjA4MjAyMTM1MTdaMC4xLDAqBgNVBAMM
# I1VuaXR5LUNsYXVkZS1BdXRvbWF0aW9uLURldmVsb3BtZW50MIIBIjANBgkqhkiG
# 9w0BAQEFAAOCAQ8AMIIBCgKCAQEAseH3qinVEOhrn2OLpjc5TNT4vGh1BkfB5X4S
# FhY7K0QMQsYYnkZVmx3tB8PqVQXl++l+e3uT7uCscc7vjMTK8tDSWH98ji0U34WL
# JBwXC62l1ArazMKp4Tyr7peksei7vL4pZOtOVgAyTYn5d1hbnsVQmCSTPRtpn7mC
# Azfq2ec5qZ9Kgl7puPW5utvYfh8idtOWa5/WgYSKwOIvyZawIdZKLFpwqOtqbJe4
# sWzVahasFhLfoAKkniKOAocJDkJexh5pO/EOSKEZ3mOCU1ZSs4XWRGISRhV3qGZp
# f+Y3JlHKMeFDWKynaJBO8/GU5sqMATlDUvrByBtU2OQ2Um/L3QIDAQABo0YwRDAO
# BgNVHQ8BAf8EBAMCB4AwEwYDVR0lBAwwCgYIKwYBBQUHAwMwHQYDVR0OBBYEFHw5
# rOy6xlW6B45sJUsiI2A/yS0MMA0GCSqGSIb3DQEBCwUAA4IBAQAUTLH0+w8ysvmh
# YuBw4NDKcZm40MTh9Zc1M2p2hAkYsgNLJ+/rAP+I74rNfqguTYwxpCyjkwrg8yF5
# wViwggboLpF2yDu4N/dgDainR4wR8NVpS7zFZOFkpmNPepc6bw3d4yQKa/wJXKeC
# pkRjS50N77/hfVI+fFKNao7POb7en5fcXuZaN6xWoTRy+J4I4MhfHpjZuxSLSXjb
# VXtPD4RZ9HGjl9BU8162cRhjujr/Lc3/dY/6ikHQYnxuxcdxRew4nzaqAQaOeWu6
# tGp899JPKfldM5Zay5IBl3zs15gNS9+0Jrd0ARQnSVYoI0DLh3KybFnfK4POezoN
# Lp/dbX2SMYIB4zCCAd8CAQEwQjAuMSwwKgYDVQQDDCNVbml0eS1DbGF1ZGUtQXV0
# b21hdGlvbi1EZXZlbG9wbWVudAIQdR0W2SKoK5VE8JId4ZxrRTAJBgUrDgMCGgUA
# oHgwGAYKKwYBBAGCNwIBDDEKMAigAoAAoQKAADAZBgkqhkiG9w0BCQMxDAYKKwYB
# BAGCNwIBBDAcBgorBgEEAYI3AgELMQ4wDAYKKwYBBAGCNwIBFTAjBgkqhkiG9w0B
# CQQxFgQUwpjFSVgbQAmQIL6B7O8tqx+k7KowDQYJKoZIhvcNAQEBBQAEggEASWqr
# 4mUeC+1IDYUyrpRoHv2Ro7Ex5iLuklNZLoKLtL6lCug0dveJy7RUwqiGHNLQC6kI
# TLpvYwRSrrN3/ycr7abxrqwEdWl3N2cPM8WpORd9TqJr7XM2vEOnSbxasd2Dah89
# EpXLLFWJK4CcJM7DBes88ZcsMTDDeaGqwJww3g6mr84XFzuYGeyFieaK458Cf+4Q
# UZwoBVPDF9a11jP/51Fz287s8aIOe2M5wSRjJ5LPpAXqKnx1v0ead/p6a+JZWg6o
# rjFAdsEN9RJubfjGg2RDzZ5GYZb/wwYOiQ8IHbmnSOEHFnR1rg7oBTKkGraQhUrz
# puuWsVHQxteZLNTsgw==
# SIG # End signature block
