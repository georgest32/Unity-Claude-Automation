# Unity-Claude-SemanticAnalysis-Metrics.psm1
# Cohesion and Complexity Metrics Functions
# Part of Unity-Claude-SemanticAnalysis module

#region Cohesion Metrics

function Get-CohesionMetrics {
    <#
    .SYNOPSIS
    Calculates cohesion metrics for code modules using CPG analysis.
    
    .DESCRIPTION
    Computes CHM (Cohesion at Message level) and CHD (Cohesion at Domain level)
    metrics to evaluate module cohesion and coupling.
    
    .PARAMETER Graph
    The CPG graph to analyze
    
    .PARAMETER UseCache
    Whether to use cached results if available
    
    .EXAMPLE
    $metrics = Get-CohesionMetrics -Graph $graph
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        $Graph,
        
        [switch]$UseCache = $true
    )
    
    begin {
        # Import helpers if needed
        if (-not (Get-Command Test-IsCPGraph -ErrorAction SilentlyContinue)) {
            Import-Module (Join-Path $PSScriptRoot "Unity-Claude-SemanticAnalysis-Helpers.psm1") -Force -Global
        }
        
        # Initialize cache if needed
        if (-not $script:UC_SA_Cache) { 
            $script:UC_SA_Cache = @{} 
        }
        
        if (-not (Test-IsCPGraph -Graph $Graph)) {
            throw "Invalid graph instance passed to $($MyInvocation.MyCommand.Name)"
        }
        
        $Graph = Ensure-GraphDuckType -Graph $Graph
        
        Write-Verbose "Calculating cohesion metrics for graph"
        
        $cacheKey = Get-CacheKey -Graph $Graph -Prefix "COHESION"
        
        if ($UseCache -and $script:UC_SA_Cache.ContainsKey($cacheKey)) {
            Write-Verbose "Get-CohesionMetrics cache hit"
            return ,$script:UC_SA_Cache[$cacheKey]
        }
    }
    
    process {
        $cohesionResults = @()
        
        try {
            # Group nodes by module/file
            $nodesByFile = @{}
            $allNodes = Unity-Claude-CPG\Get-CPGNode -Graph $Graph
            
            foreach ($node in $allNodes) {
                $file = if ($node.FilePath) { $node.FilePath } else { 'Unknown' }
                if (-not $nodesByFile.ContainsKey($file)) {
                    $nodesByFile[$file] = @()
                }
                $nodesByFile[$file] += $node
            }
            
            # Calculate metrics for each module
            foreach ($file in $nodesByFile.Keys) {
                $moduleNodes = $nodesByFile[$file]
                $metrics = Calculate-ModuleCohesion -Nodes $moduleNodes -Graph $Graph -ModuleName $file
                if ($metrics) {
                    $cohesionResults += $metrics
                }
            }
            
            # If no file grouping, analyze as single module
            if ($cohesionResults.Count -eq 0 -and $allNodes.Count -gt 0) {
                $metrics = Calculate-ModuleCohesion -Nodes $allNodes -Graph $Graph -ModuleName 'Main'
                if ($metrics) {
                    $cohesionResults += $metrics
                }
            }
            
            # Normalize results
            $cohesionResults = @($cohesionResults | ForEach-Object { 
                Normalize-AnalysisRecord -Record $_ -Kind 'Cohesion' 
            })
            
            # Cache results
            if ($UseCache) {
                $script:UC_SA_Cache[$cacheKey] = $cohesionResults
            }
            
            Write-Verbose "Cohesion analysis complete. Analyzed $($cohesionResults.Count) modules"
        }
        catch {
            Write-Verbose "Cohesion metrics error: $($_.Exception.Message)"
            return @()
        }
    }
    
    end {
        # Final normalization and array return
        $cohesionResults = @($cohesionResults | ForEach-Object { Normalize-AnalysisRecord -Record $_ -Kind 'Cohesion' })
        if ($UseCache) { $script:UC_SA_Cache[$cacheKey] = $cohesionResults }
        return ,$cohesionResults
    }
}

function Calculate-ModuleCohesion {
    <#
    .SYNOPSIS
    Calculates cohesion metrics for a single module
    
    .PARAMETER Nodes
    The nodes belonging to the module
    
    .PARAMETER Graph
    The containing graph for edge analysis
    
    .PARAMETER ModuleName
    The name of the module being analyzed
    #>
    param(
        [array]$Nodes,
        $Graph,
        [string]$ModuleName
    )
    
    if ($Nodes.Count -eq 0) {
        return $null
    }
    
    # Get edges between nodes
    $allEdges = Unity-Claude-CPG\Get-CPGEdge -Graph $Graph
    $nodeIds = $Nodes | ForEach-Object { $_.Id }
    
    # Count internal connections (cohesion)
    $internalEdges = $allEdges | Where-Object {
        $nodeIds -contains $_.SourceId -and $nodeIds -contains $_.TargetId
    }
    $internalConnectionCount = @($internalEdges).Count
    
    # Count external connections (coupling)
    $externalEdges = $allEdges | Where-Object {
        ($nodeIds -contains $_.SourceId -and $nodeIds -notcontains $_.TargetId) -or
        ($nodeIds -notcontains $_.SourceId -and $nodeIds -contains $_.TargetId)
    }
    $externalConnectionCount = @($externalEdges).Count
    
    # Calculate CHM (Cohesion at Message level)
    # Higher CHM = more internal method calls relative to total
    $totalConnections = $internalConnectionCount + $externalConnectionCount
    $chm = if ($totalConnections -gt 0) {
        [Math]::Round($internalConnectionCount / $totalConnections, 3)
    } else {
        0.0
    }
    
    # Calculate CHD (Cohesion at Domain level)  
    # Based on semantic similarity of node names and purposes
    $functions = $Nodes | Where-Object { $_.Type -eq 'Function' -or $_.Type -eq 'Method' }
    if ($functions.Count -le 1) {
        $chm = 0; $chd = 0
    }
    $chd = Calculate-SemanticCohesion -Nodes $Nodes
    
    # Validate and clamp values
    if ($null -eq $chm -or [double]::IsNaN([double]$chm)) { $chm = 0 }
    if ($null -eq $chd -or [double]::IsNaN([double]$chd)) { $chd = 0 }
    # Clamp values to 0-1 range locally
    $chmClamped = [Math]::Round([Math]::Max(0, [Math]::Min(1, [double]$chm)), 3)
    $chdClamped = [Math]::Round([Math]::Max(0, [Math]::Min(1, [double]$chd)), 3)
    $overallValue = ($chmClamped * 0.6) + ($chdClamped * 0.4)
    $overall = [Math]::Round([Math]::Max(0, [Math]::Min(1, [double]$overallValue)), 3)
    
    # Calculate coupling metric
    $coupling = if ($Nodes.Count -gt 0) {
        [Math]::Round($externalConnectionCount / $Nodes.Count, 3)
    } else {
        0.0
    }
    
    # Determine cohesion quality
    $quality = if ($chm -ge 0.7 -and $chd -ge 0.7) {
        'High'
    } elseif ($chm -ge 0.4 -or $chd -ge 0.4) {
        'Medium'
    } else {
        'Low'
    }
    
    $cohesionResult = [PSCustomObject]@{
        Module = $ModuleName
        NodeCount = $Nodes.Count
        InternalConnections = $internalConnectionCount
        ExternalConnections = $externalConnectionCount
        CHM = $chmClamped
        CHD = $chdClamped
        OverallCohesion = $overall
        Coupling = $coupling
        Quality = $quality
        Recommendations = Get-CohesionRecommendations -CHM $chmClamped -CHD $chdClamped -Coupling $coupling
    }
    
    # Normalize result
    $cohesionResult = Normalize-AnalysisRecord -Record $cohesionResult -Kind 'Cohesion'
    
    return $cohesionResult
}

function Calculate-SemanticCohesion {
    <#
    .SYNOPSIS
    Calculates semantic cohesion based on naming patterns
    
    .PARAMETER Nodes
    The nodes to analyze for semantic similarity
    #>
    param(
        [array]$Nodes
    )
    
    if ($Nodes.Count -le 1) {
        return 1.0  # Single node is perfectly cohesive with itself
    }
    
    # Extract common prefixes and patterns
    $names = $Nodes | Where-Object { $_.Name } | ForEach-Object { $_.Name }
    
    if ($names.Count -eq 0) {
        return 0.0
    }
    
    # Find common prefixes
    $prefixes = @{}
    foreach ($name in $names) {
        if ($name -match '^([A-Z][a-z]*|Get|Set|New|Remove|Update|Test|Find)') {
            $prefix = $Matches[1]
            if (-not $prefixes.ContainsKey($prefix)) {
                $prefixes[$prefix] = 0
            }
            $prefixes[$prefix]++
        }
    }
    
    # Calculate cohesion based on shared prefixes
    $maxPrefix = ($prefixes.Values | Measure-Object -Maximum).Maximum
    $cohesion = if ($names.Count -gt 0) {
        [Math]::Round($maxPrefix / $names.Count, 3)
    } else {
        0.0
    }
    
    # Adjust based on common domains
    $domainTerms = @('User', 'Order', 'Product', 'Customer', 'Account', 'Service', 'Manager', 'Controller')
    $domainMatches = 0
    
    foreach ($term in $domainTerms) {
        $matches = ($names | Where-Object { $_ -match $term }).Count
        if ($matches -gt $domainMatches) {
            $domainMatches = $matches
        }
    }
    
    $domainCohesion = if ($names.Count -gt 0) {
        [Math]::Round($domainMatches / $names.Count, 3)
    } else {
        0.0
    }
    
    # Return weighted average
    return [Math]::Round(($cohesion * 0.6 + $domainCohesion * 0.4), 3)
}

function Get-CohesionRecommendations {
    <#
    .SYNOPSIS
    Generates recommendations based on cohesion metrics
    
    .PARAMETER CHM
    Cohesion at Message level
    
    .PARAMETER CHD
    Cohesion at Domain level
    
    .PARAMETER Coupling
    External coupling metric
    #>
    param(
        [double]$CHM,
        [double]$CHD,
        [double]$Coupling
    )
    
    $recommendations = @()
    
    if ($CHM -lt 0.4) {
        $recommendations += "Low message cohesion - Consider grouping related methods together"
    }
    
    if ($CHD -lt 0.4) {
        $recommendations += "Low domain cohesion - Consider splitting into domain-specific modules"
    }
    
    if ($Coupling -gt 0.7) {
        $recommendations += "High coupling - Consider reducing external dependencies"
    }
    
    if ($CHM -gt 0.8 -and $CHD -gt 0.8) {
        $recommendations += "Excellent cohesion - Module is well-organized"
    }
    
    if ($recommendations.Count -eq 0) {
        $recommendations += "Acceptable cohesion levels"
    }
    
    return $recommendations
}

function Get-ComplexityMetrics {
    <#
    .SYNOPSIS
    Calculates complexity metrics for code
    
    .DESCRIPTION
    Computes cyclomatic and cognitive complexity metrics
    
    .PARAMETER Graph
    The CPG graph to analyze
    
    .PARAMETER UseCache
    Whether to use cached results if available
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        $Graph,
        
        [switch]$UseCache = $true
    )
    
    # Implementation would calculate cyclomatic and cognitive complexity
    # Placeholder for now
    return @()
}

#endregion

# Export functions
Export-ModuleMember -Function @(
    'Get-CohesionMetrics',
    'Calculate-ModuleCohesion',
    'Calculate-SemanticCohesion',
    'Get-CohesionRecommendations',
    'Get-ComplexityMetrics'
)
# SIG # Begin signature block
# MIIFzgYJKoZIhvcNAQcCoIIFvzCCBbsCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCC0KWV48GRXpEjG
# hjZ6Vy31EKP7S5CS4rp5mzHWuYoRKqCCAzAwggMsMIICFKADAgECAhB1HRbZIqgr
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
# MAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIMXJty0SZmEo6P/ZiqojXeYB
# 22kH7jFZXfD2/KtrMTMRMA0GCSqGSIb3DQEBAQUABIIBAJUmbxvu7cOvYk8zfncx
# GCTXZgLT3qNdcsl/GEl0lB/sj5r5wz7XGYyyI/jmdvRq4V3yHpoMqF5An436L4Bf
# 4w2692ZNOF6PNqxg1kzy5Sr5A0jzpvG2XJbDY3btTpxbOLrymyFUsD4B4DHx0r0A
# HD0Z8DdLk9yEJV5iJ6tM52+Wr6AOIqRBuZb628kKqfawHGrMu9EhB6xOMKnI4sw4
# S/urvofDymPIonQ8GkfshcgyF3exoqYkqFrhWA/pEF2LDQ7yqaSfBnbEY14W+1Bf
# 9SZ+TZe6EF0Y8BY0md4NVU/9BZbxumclyfBjOvwUxJN7Csvt81XAir2fAegf/hcv
# gss=
# SIG # End signature block
