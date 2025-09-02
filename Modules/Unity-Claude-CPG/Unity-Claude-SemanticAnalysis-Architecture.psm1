# Unity-Claude-SemanticAnalysis-Architecture.psm1
# Architecture Recovery and Analysis Functions
# Part of Unity-Claude-SemanticAnalysis module

#region Architecture Recovery

function Recover-Architecture {
    <#
    .SYNOPSIS
    Recovers architectural patterns and structures from code analysis.
    
    .DESCRIPTION
    Analyzes the codebase structure to identify architectural patterns,
    layer separation, module dependencies, and overall system organization.
    
    .PARAMETER Graph
    The CPG graph to analyze for architectural patterns
    
    .PARAMETER UseCache
    Whether to use cached results if available
    
    .EXAMPLE
    $architecture = Recover-Architecture -Graph $graph
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
        
        Write-Verbose "Recovering architectural patterns from graph"
        
        $cacheKey = Get-CacheKey -Graph $Graph -Prefix "ARCH"
        
        if ($UseCache -and $script:UC_SA_Cache.ContainsKey($cacheKey)) {
            Write-Verbose "Recover-Architecture cache hit"
            return ,$script:UC_SA_Cache[$cacheKey]
        }
    }
    
    process {
        $architecturalResults = @()
        
        try {
            # Identify layers
            $layers = Identify-SystemLayers -Graph $Graph
            $architecturalResults += $layers
            
            # Analyze dependencies
            $dependencies = Analyze-ModuleDependencies -Graph $Graph
            $architecturalResults += $dependencies
            
            # Identify architectural patterns
            $patterns = Find-ArchitecturalPatterns -Graph $Graph
            $architecturalResults += $patterns
            
            # Analyze component relationships
            $components = Analyze-ComponentRelationships -Graph $Graph
            $architecturalResults += $components
            
            # Cache results
            if ($UseCache) {
                $script:UC_SA_Cache[$cacheKey] = $architecturalResults
            }
            
            Write-Verbose "Architecture recovery complete. Found $($architecturalResults.Count) architectural elements"
        }
        catch {
            Write-Verbose "Architecture recovery error: $($_.Exception.Message)"
            return @()
        }
    }
    
    end {
        if ($architecturalResults -eq $null) {
            return @()
        }
        return ,$architecturalResults
    }
}

function Identify-SystemLayers {
    <#
    .SYNOPSIS
    Identifies system layers from code organization
    
    .PARAMETER Graph
    The CPG graph to analyze
    #>
    param($Graph)
    
    $layers = @()
    $allNodes = Unity-Claude-CPG\Get-CPGNode -Graph $Graph
    
    # Group by file path patterns to identify layers
    $layerPatterns = @{
        'Presentation' = @('ui', 'view', 'controller', 'web', 'api', 'rest', 'endpoint')
        'Business' = @('service', 'manager', 'logic', 'domain', 'business', 'core')
        'Data' = @('repository', 'dao', 'data', 'storage', 'persistence', 'model')
        'Infrastructure' = @('config', 'util', 'helper', 'common', 'infrastructure')
    }
    
    $nodesByLayer = @{}
    
    foreach ($node in $allNodes) {
        $filePath = if ($node.FilePath) { $node.FilePath.ToLower() } else { $node.Name.ToLower() }
        
        foreach ($layerName in $layerPatterns.Keys) {
            $patterns = $layerPatterns[$layerName]
            foreach ($pattern in $patterns) {
                if ($filePath -match $pattern) {
                    if (-not $nodesByLayer.ContainsKey($layerName)) {
                        $nodesByLayer[$layerName] = @()
                    }
                    $nodesByLayer[$layerName] += $node
                    break
                }
            }
        }
    }
    
    # Create layer analysis results
    foreach ($layerName in $nodesByLayer.Keys) {
        $layerNodes = $nodesByLayer[$layerName]
        $layers += [PSCustomObject]@{
            Type = 'SystemLayer'
            LayerName = $layerName
            NodeCount = $layerNodes.Count
            Nodes = $layerNodes
            Confidence = 0.8
            Evidence = @("File path patterns suggest $layerName layer")
        }
    }
    
    return $layers
}

function Analyze-ModuleDependencies {
    <#
    .SYNOPSIS
    Analyzes dependencies between modules
    
    .PARAMETER Graph
    The CPG graph to analyze
    #>
    param($Graph)
    
    $dependencies = @()
    $allEdges = Unity-Claude-CPG\Get-CPGEdge -Graph $Graph
    $allNodes = Unity-Claude-CPG\Get-CPGNode -Graph $Graph
    
    # Group nodes by module (file)
    $nodesByModule = @{}
    foreach ($node in $allNodes) {
        $module = if ($node.FilePath) { 
            Split-Path $node.FilePath -Leaf 
        } else { 
            'Unknown' 
        }
        
        if (-not $nodesByModule.ContainsKey($module)) {
            $nodesByModule[$module] = @()
        }
        $nodesByModule[$module] += $node
    }
    
    # Analyze cross-module dependencies
    foreach ($moduleA in $nodesByModule.Keys) {
        $nodesA = $nodesByModule[$moduleA]
        $nodeIdsA = $nodesA | ForEach-Object { $_.Id }
        
        foreach ($moduleB in $nodesByModule.Keys) {
            if ($moduleA -eq $moduleB) { continue }
            
            $nodesB = $nodesByModule[$moduleB]
            $nodeIdsB = $nodesB | ForEach-Object { $_.Id }
            
            # Count dependencies from A to B
            $dependencyCount = ($allEdges | Where-Object {
                $nodeIdsA -contains $_.SourceId -and $nodeIdsB -contains $_.TargetId
            }).Count
            
            if ($dependencyCount -gt 0) {
                $dependencies += [PSCustomObject]@{
                    Type = 'ModuleDependency'
                    FromModule = $moduleA
                    ToModule = $moduleB
                    DependencyCount = $dependencyCount
                    DependencyType = if ($dependencyCount -gt 5) { 'Strong' } elseif ($dependencyCount -gt 2) { 'Moderate' } else { 'Weak' }
                    Confidence = 0.9
                }
            }
        }
    }
    
    return $dependencies
}

function Find-ArchitecturalPatterns {
    <#
    .SYNOPSIS
    Identifies architectural patterns in the system
    
    .PARAMETER Graph
    The CPG graph to analyze
    #>
    param($Graph)
    
    $patterns = @()
    $allNodes = Unity-Claude-CPG\Get-CPGNode -Graph $Graph
    
    # Look for MVC pattern
    $controllers = $allNodes | Where-Object { $_.Name -match 'Controller$' }
    $models = $allNodes | Where-Object { $_.Name -match 'Model$|Entity$' }
    $views = $allNodes | Where-Object { $_.Name -match 'View$|Template$' }
    
    if ($controllers.Count -gt 0 -and ($models.Count -gt 0 -or $views.Count -gt 0)) {
        $patterns += [PSCustomObject]@{
            Type = 'ArchitecturalPattern'
            PatternName = 'MVC'
            Confidence = 0.85
            Evidence = @(
                "Found $($controllers.Count) controllers",
                "Found $($models.Count) models",
                "Found $($views.Count) views"
            )
            Components = @{
                Controllers = $controllers.Count
                Models = $models.Count  
                Views = $views.Count
            }
        }
    }
    
    # Look for Repository pattern
    $repositories = $allNodes | Where-Object { $_.Name -match 'Repository$|Repo$' }
    if ($repositories.Count -gt 0) {
        $patterns += [PSCustomObject]@{
            Type = 'ArchitecturalPattern'
            PatternName = 'Repository'
            Confidence = 0.9
            Evidence = @("Found $($repositories.Count) repository classes")
            Components = @{
                Repositories = $repositories.Count
            }
        }
    }
    
    # Look for Service Layer pattern
    $services = $allNodes | Where-Object { $_.Name -match 'Service$|Manager$' }
    if ($services.Count -gt 0) {
        $patterns += [PSCustomObject]@{
            Type = 'ArchitecturalPattern'
            PatternName = 'ServiceLayer'
            Confidence = 0.8
            Evidence = @("Found $($services.Count) service classes")
            Components = @{
                Services = $services.Count
            }
        }
    }
    
    # Look for Factory pattern
    $factories = $allNodes | Where-Object { $_.Name -match 'Factory$|Builder$' }
    if ($factories.Count -gt 0) {
        $patterns += [PSCustomObject]@{
            Type = 'ArchitecturalPattern'
            PatternName = 'Factory'
            Confidence = 0.85
            Evidence = @("Found $($factories.Count) factory classes")
            Components = @{
                Factories = $factories.Count
            }
        }
    }
    
    return $patterns
}

function Analyze-ComponentRelationships {
    <#
    .SYNOPSIS
    Analyzes relationships between system components
    
    .PARAMETER Graph
    The CPG graph to analyze
    #>
    param($Graph)
    
    $relationships = @()
    $allNodes = Unity-Claude-CPG\Get-CPGNode -Graph $Graph
    $allEdges = Unity-Claude-CPG\Get-CPGEdge -Graph $Graph
    
    # Analyze class relationships
    $classes = $allNodes | Where-Object { $_.Type -eq 'Class' }
    
    foreach ($class in $classes) {
        # Find related classes through edges
        $relatedNodeIds = $allEdges | Where-Object { 
            $_.SourceId -eq $class.Id -or $_.TargetId -eq $class.Id 
        } | ForEach-Object { 
            if ($_.SourceId -eq $class.Id) { $_.TargetId } else { $_.SourceId }
        }
        
        $relatedClasses = $allNodes | Where-Object { 
            $_.Type -eq 'Class' -and $relatedNodeIds -contains $_.Id 
        }
        
        if ($relatedClasses.Count -gt 0) {
            $relationships += [PSCustomObject]@{
                Type = 'ComponentRelationship'
                ComponentName = $class.Name
                ComponentType = 'Class'
                RelatedComponents = $relatedClasses | ForEach-Object { $_.Name }
                RelationshipCount = $relatedClasses.Count
                RelationshipStrength = if ($relatedClasses.Count -gt 3) { 'Strong' } elseif ($relatedClasses.Count -gt 1) { 'Moderate' } else { 'Weak' }
                FilePath = $class.FilePath
            }
        }
    }
    
    return $relationships
}

#endregion

# Export functions
Export-ModuleMember -Function @(
    'Recover-Architecture',
    'Identify-SystemLayers',
    'Analyze-ModuleDependencies',
    'Find-ArchitecturalPatterns',
    'Analyze-ComponentRelationships'
)
# SIG # Begin signature block
# MIIFzgYJKoZIhvcNAQcCoIIFvzCCBbsCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCCf6l9zxN1eL3mF
# i+7tRzcRCl932cAqcRrZkMfq2SA6FaCCAzAwggMsMIICFKADAgECAhB1HRbZIqgr
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
# MAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIOzGVXeVSgYU1TwOJ/dnrj2e
# qfn1yTtPV8i6dtLREYzQMA0GCSqGSIb3DQEBAQUABIIBAJgYjMMvM6Zs3WWIKVrM
# j5cGkMjPhIkTRGbODaKweTMEo2AXjkpStPByzT583Vjl6l8+Cq0XgxnY8OymmbOi
# d2H0V4kND+zfc4eP3zMeY/26ieq8hF7dJJB7Hrw5mPm/mVfJ5YVIATNL774tssNt
# jlazvNvssIc7jiH0xCtUl/A4kL/2lM+lErikNx6gHGBpJU6f/CH6ItD11dHjcZom
# kUptAt01AVhEGdVkL6nQMM881J9BdV/lCAvG7Gm1Isy1ZfqHuPIQ65iM4Jzh8U5H
# USpnepCUff4rUySJ20LuYMGXuGn7G6PcSGMZayzO3y0ymCQNRKQF2QlZyUXuxHiy
# /RQ=
# SIG # End signature block
