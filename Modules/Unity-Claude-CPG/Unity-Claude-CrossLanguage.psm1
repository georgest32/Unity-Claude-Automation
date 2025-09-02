# Unity-Claude-CrossLanguage.psm1
# Cross-language relationship mapping for multi-language codebases
# Merges CPG graphs from different languages into unified representation

#Requires -Version 5.1

# Load enums
$enumPath = Join-Path $PSScriptRoot "Unity-Claude-CPG-Enums.ps1"
if (Test-Path $enumPath) {
    . $enumPath
}

function Merge-LanguageGraphs {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [hashtable[]]$Graphs,
        
        [string]$MergedGraphName = "UnifiedCPG"
    )
    
    Write-Verbose "Merging $($Graphs.Count) language graphs into unified CPG"
    
    # Create new unified graph
    $unifiedGraph = New-CPGraph -Name $MergedGraphName
    
    # Track cross-language references
    $importMap = @{}      # Maps import statements to actual modules/files
    $functionMap = @{}    # Maps function names across languages
    $classMap = @{}       # Maps class names across languages
    
    # Phase 1: Copy all nodes and edges from individual graphs
    foreach ($graphInfo in $Graphs) {
        $graph = $graphInfo.Graph
        $language = $graphInfo.Language
        
        Write-Verbose "Processing $language graph with $($graph.Nodes.Count) nodes"
        
        # Copy nodes with language prefix in ID to avoid collisions
        foreach ($node in $graph.Nodes.Values) {
            $newNode = [PSCustomObject]@{
                Id = "$language-$($node.Id)"
                Name = $node.Name
                Type = $node.Type
                Properties = $node.Properties + @{ SourceLanguage = $language }
                FilePath = $node.FilePath
                StartLine = $node.StartLine
                EndLine = $node.EndLine
                Language = $language
            }
            
            # Add to unified graph
            $unifiedGraph.Nodes[$newNode.Id] = $newNode
            
            # Track in maps for cross-reference resolution
            switch ($node.Type) {
                ([CPGNodeType]::Function) {
                    if (-not $functionMap.ContainsKey($node.Name)) {
                        $functionMap[$node.Name] = @()
                    }
                    $functionMap[$node.Name] += $newNode
                }
                ([CPGNodeType]::Class) {
                    if (-not $classMap.ContainsKey($node.Name)) {
                        $classMap[$node.Name] = @()
                    }
                    $classMap[$node.Name] += $newNode
                }
                ([CPGNodeType]::Module) {
                    $importName = $node.Properties.ImportPath ?? $node.Name
                    if (-not $importMap.ContainsKey($importName)) {
                        $importMap[$importName] = @()
                    }
                    $importMap[$importName] += $newNode
                }
            }
        }
        
        # Copy edges with updated node IDs
        foreach ($edge in $graph.Edges.Values) {
            $newEdge = [PSCustomObject]@{
                Id = [guid]::NewGuid().ToString()
                SourceId = "$language-$($edge.SourceId)"
                TargetId = "$language-$($edge.TargetId)"
                Type = $edge.Type
                Properties = $edge.Properties + @{ SourceLanguage = $language }
            }
            
            $unifiedGraph.Edges[$newEdge.Id] = $newEdge
            
            # Update adjacency lists
            if (-not $unifiedGraph.AdjacencyList.ContainsKey($newEdge.SourceId)) {
                $unifiedGraph.AdjacencyList[$newEdge.SourceId] = @()
            }
            $unifiedGraph.AdjacencyList[$newEdge.SourceId] += $newEdge.TargetId
        }
    }
    
    # Phase 2: Resolve cross-language references
    Write-Verbose "Resolving cross-language references"
    
    # Find and link cross-language imports/exports
    Resolve-CrossLanguageImports -Graph $unifiedGraph -ImportMap $importMap
    
    # Link shared interfaces (e.g., REST APIs, gRPC services)
    Resolve-SharedInterfaces -Graph $unifiedGraph -FunctionMap $functionMap
    
    # Link data models across languages
    Resolve-DataModels -Graph $unifiedGraph -ClassMap $classMap
    
    Write-Verbose "Unified graph created with $($unifiedGraph.Nodes.Count) nodes and $($unifiedGraph.Edges.Count) edges"
    
    return $unifiedGraph
}

function Resolve-CrossLanguageImports {
    [CmdletBinding()]
    param(
        $Graph,
        [hashtable]$ImportMap
    )
    
    Write-Verbose "Resolving cross-language imports"
    
    # Common import patterns
    $importPatterns = @{
        # Python importing JavaScript module (via subprocess, API calls, etc.)
        "Python-JavaScript" = @{
            Pattern = "subprocess.*node|requests.*localhost|fetch.*api"
            EdgeType = [CPGEdgeType]::References
        }
        # JavaScript importing Python (via child_process, API calls)
        "JavaScript-Python" = @{
            Pattern = "child_process.*python|fetch.*api|axios"
            EdgeType = [CPGEdgeType]::References
        }
        # C# referencing other services
        "CSharp-Any" = @{
            Pattern = "HttpClient|RestClient|ServiceReference"
            EdgeType = [CPGEdgeType]::References
        }
    }
    
    $crossRefCount = 0
    
    # Look for cross-language references in node properties
    foreach ($node in $Graph.Nodes.Values) {
        if ($node.Type -eq [CPGNodeType]::Module -or $node.Properties.ImportPath) {
            $importPath = $node.Properties.ImportPath ?? $node.Name
            
            # Check if this import refers to a module in another language
            foreach ($kvp in $ImportMap.GetEnumerator()) {
                $importName = $kvp.Key
                $targetNodes = $kvp.Value
                
                # Skip same-language imports
                $targetNodes = $targetNodes | Where-Object { $_.Language -ne $node.Language }
                
                if ($targetNodes.Count -gt 0 -and (Test-ImportMatch -ImportPath $importPath -ImportName $importName)) {
                    foreach ($target in $targetNodes) {
                        # Create cross-language reference edge
                        $edge = [PSCustomObject]@{
                            Id = [guid]::NewGuid().ToString()
                            SourceId = $node.Id
                            TargetId = $target.Id
                            Type = [CPGEdgeType]::References
                            Properties = @{
                                CrossLanguage = $true
                                SourceLanguage = $node.Language
                                TargetLanguage = $target.Language
                                ReferenceType = "Import"
                            }
                        }
                        
                        $Graph.Edges[$edge.Id] = $edge
                        $crossRefCount++
                        
                        Write-Verbose "  Created cross-language reference: $($node.Language)->$($target.Language) for $importName"
                    }
                }
            }
        }
    }
    
    Write-Verbose "  Resolved $crossRefCount cross-language import references"
}

function Test-ImportMatch {
    param(
        [string]$ImportPath,
        [string]$ImportName
    )
    
    # Normalize paths for comparison
    $ImportPath = $ImportPath -replace '[\\/]', '/' -replace '\.py$|\.js$|\.ts$|\.cs$', ''
    $ImportName = $ImportName -replace '[\\/]', '/' -replace '\.py$|\.js$|\.ts$|\.cs$', ''
    
    # Check various matching patterns
    return $ImportPath -eq $ImportName -or 
           $ImportPath.EndsWith("/$ImportName") -or
           $ImportName.EndsWith("/$ImportPath") -or
           ($ImportPath -match [regex]::Escape($ImportName))
}

function Resolve-SharedInterfaces {
    [CmdletBinding()]
    param(
        $Graph,
        [hashtable]$FunctionMap
    )
    
    Write-Verbose "Resolving shared interfaces (APIs, RPC, etc.)"
    
    $interfaceCount = 0
    
    # Common API patterns
    $apiPatterns = @(
        # REST API endpoints
        @{ Pattern = "^(get|post|put|delete|patch)_"; Type = "REST" },
        @{ Pattern = "Controller$|Route\(|app\.(get|post|put|delete)"; Type = "REST" },
        
        # gRPC services
        @{ Pattern = "Service$|_pb2|\.proto"; Type = "gRPC" },
        
        # GraphQL
        @{ Pattern = "Query$|Mutation$|Resolver$"; Type = "GraphQL" }
    )
    
    # Find API endpoints and their implementations
    foreach ($funcName in $FunctionMap.Keys) {
        $functions = $FunctionMap[$funcName]
        
        if ($functions.Count -gt 1) {
            # Check if this looks like an API endpoint
            $isApi = $false
            $apiType = ""
            
            foreach ($pattern in $apiPatterns) {
                if ($funcName -match $pattern.Pattern) {
                    $isApi = $true
                    $apiType = $pattern.Type
                    break
                }
            }
            
            if ($isApi) {
                # Link all implementations of this API
                for ($i = 0; $i -lt $functions.Count - 1; $i++) {
                    for ($j = $i + 1; $j -lt $functions.Count; $j++) {
                        if ($functions[$i].Language -ne $functions[$j].Language) {
                            $edge = [PSCustomObject]@{
                                Id = [guid]::NewGuid().ToString()
                                SourceId = $functions[$i].Id
                                TargetId = $functions[$j].Id
                                Type = [CPGEdgeType]::Implements
                                Properties = @{
                                    CrossLanguage = $true
                                    InterfaceType = $apiType
                                    SharedInterface = $funcName
                                }
                            }
                            
                            $Graph.Edges[$edge.Id] = $edge
                            $interfaceCount++
                            
                            Write-Verbose "  Linked shared $apiType interface: $funcName ($($functions[$i].Language) <-> $($functions[$j].Language))"
                        }
                    }
                }
            }
        }
    }
    
    Write-Verbose "  Resolved $interfaceCount shared interface connections"
}

function Resolve-DataModels {
    [CmdletBinding()]
    param(
        $Graph,
        [hashtable]$ClassMap
    )
    
    Write-Verbose "Resolving shared data models"
    
    $modelCount = 0
    
    # Look for classes with similar names across languages
    foreach ($className in $ClassMap.Keys) {
        $classes = $ClassMap[$className]
        
        if ($classes.Count -gt 1) {
            # Check if classes are in different languages
            $languages = $classes.Language | Select-Object -Unique
            
            if ($languages.Count -gt 1) {
                # These might be the same data model in different languages
                # Link them with a DataModel relationship
                
                for ($i = 0; $i -lt $classes.Count - 1; $i++) {
                    for ($j = $i + 1; $j -lt $classes.Count; $j++) {
                        if ($classes[$i].Language -ne $classes[$j].Language) {
                            # Check structural similarity (simplified - real implementation would compare properties)
                            $similarity = Test-DataModelSimilarity -Class1 $classes[$i] -Class2 $classes[$j] -Graph $Graph
                            
                            if ($similarity -gt 0.7) {  # 70% similarity threshold
                                $edge = [PSCustomObject]@{
                                    Id = [guid]::NewGuid().ToString()
                                    SourceId = $classes[$i].Id
                                    TargetId = $classes[$j].Id
                                    Type = [CPGEdgeType]::References
                                    Properties = @{
                                        CrossLanguage = $true
                                        ReferenceType = "DataModel"
                                        ModelName = $className
                                        Similarity = $similarity
                                    }
                                }
                                
                                $Graph.Edges[$edge.Id] = $edge
                                $modelCount++
                                
                                Write-Verbose "  Linked data model: $className ($($classes[$i].Language) <-> $($classes[$j].Language), similarity: $([Math]::Round($similarity * 100, 1))%)"
                            }
                        }
                    }
                }
            }
        }
    }
    
    Write-Verbose "  Resolved $modelCount shared data model connections"
}

function Test-DataModelSimilarity {
    param(
        $Class1,
        $Class2,
        $Graph
    )
    
    # Simplified similarity check based on class properties
    # In a real implementation, this would compare:
    # - Property names and types
    # - Method signatures
    # - Inheritance patterns
    
    # For now, use name similarity and property count
    $nameSimilarity = Get-StringSimilarity -String1 $Class1.Name -String2 $Class2.Name
    
    # Get properties/fields for each class
    $class1Props = $Graph.Edges.Values | Where-Object {
        $_.SourceId -eq $Class1.Id -and $_.Type -eq [CPGEdgeType]::Contains
    } | ForEach-Object {
        $Graph.Nodes[$_.TargetId]
    } | Where-Object {
        $_.Type -in @([CPGNodeType]::Property, [CPGNodeType]::Field)
    }
    
    $class2Props = $Graph.Edges.Values | Where-Object {
        $_.SourceId -eq $Class2.Id -and $_.Type -eq [CPGEdgeType]::Contains
    } | ForEach-Object {
        $Graph.Nodes[$_.TargetId]
    } | Where-Object {
        $_.Type -in @([CPGNodeType]::Property, [CPGNodeType]::Field)
    }
    
    # Calculate property overlap
    $propSimilarity = 0
    if ($class1Props.Count -gt 0 -and $class2Props.Count -gt 0) {
        $commonProps = 0
        foreach ($prop1 in $class1Props) {
            foreach ($prop2 in $class2Props) {
                if ((Get-StringSimilarity -String1 $prop1.Name -String2 $prop2.Name) -gt 0.8) {
                    $commonProps++
                    break
                }
            }
        }
        
        $propSimilarity = $commonProps / [Math]::Max($class1Props.Count, $class2Props.Count)
    }
    
    # Weighted average of similarities
    return ($nameSimilarity * 0.3 + $propSimilarity * 0.7)
}

function Get-StringSimilarity {
    param(
        [string]$String1,
        [string]$String2
    )
    
    # Simple Levenshtein distance-based similarity
    if ($String1 -eq $String2) { return 1.0 }
    if ([string]::IsNullOrEmpty($String1) -or [string]::IsNullOrEmpty($String2)) { return 0.0 }
    
    # Normalize strings
    $s1 = $String1.ToLower() -replace '[_-]', ''
    $s2 = $String2.ToLower() -replace '[_-]', ''
    
    if ($s1 -eq $s2) { return 0.95 }
    
    # Calculate Levenshtein distance
    $len1 = $s1.Length
    $len2 = $s2.Length
    $matrix = New-Object 'int[,]' ($len1 + 1), ($len2 + 1)
    
    for ($i = 0; $i -le $len1; $i++) { $matrix[$i, 0] = $i }
    for ($j = 0; $j -le $len2; $j++) { $matrix[0, $j] = $j }
    
    for ($i = 1; $i -le $len1; $i++) {
        for ($j = 1; $j -le $len2; $j++) {
            $cost = if ($s1[$i-1] -eq $s2[$j-1]) { 0 } else { 1 }
            $matrix[$i, $j] = [Math]::Min(
                [Math]::Min($matrix[$i-1, $j] + 1, $matrix[$i, $j-1] + 1),
                $matrix[$i-1, $j-1] + $cost
            )
        }
    }
    
    $distance = $matrix[$len1, $len2]
    $maxLen = [Math]::Max($len1, $len2)
    
    return 1.0 - ($distance / $maxLen)
}

function Get-CrossLanguageStatistics {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        $Graph
    )
    
    Write-Verbose "Calculating cross-language statistics"
    
    $stats = @{
        TotalNodes = $Graph.Nodes.Count
        TotalEdges = $Graph.Edges.Count
        Languages = @{}
        CrossLanguageEdges = 0
        CrossLanguageTypes = @{}
    }
    
    # Count nodes by language
    foreach ($node in $Graph.Nodes.Values) {
        $lang = $node.Language ?? "Unknown"
        if (-not $stats.Languages.ContainsKey($lang)) {
            $stats.Languages[$lang] = @{
                Nodes = 0
                Functions = 0
                Classes = 0
                Modules = 0
            }
        }
        
        $stats.Languages[$lang].Nodes++
        
        switch ($node.Type) {
            ([CPGNodeType]::Function) { $stats.Languages[$lang].Functions++ }
            ([CPGNodeType]::Class) { $stats.Languages[$lang].Classes++ }
            ([CPGNodeType]::Module) { $stats.Languages[$lang].Modules++ }
        }
    }
    
    # Count cross-language edges
    foreach ($edge in $Graph.Edges.Values) {
        if ($edge.Properties.CrossLanguage -eq $true) {
            $stats.CrossLanguageEdges++
            
            $refType = $edge.Properties.ReferenceType ?? "Unknown"
            if (-not $stats.CrossLanguageTypes.ContainsKey($refType)) {
                $stats.CrossLanguageTypes[$refType] = 0
            }
            $stats.CrossLanguageTypes[$refType]++
        }
    }
    
    # Calculate connectivity metrics
    $stats.CrossLanguageRatio = if ($stats.TotalEdges -gt 0) {
        [Math]::Round(($stats.CrossLanguageEdges / $stats.TotalEdges) * 100, 2)
    } else { 0 }
    
    return $stats
}

function Export-UnifiedGraph {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        $Graph,
        
        [Parameter(Mandatory)]
        [string]$OutputPath,
        
        [ValidateSet("JSON", "GraphML", "DOT", "Markdown")]
        [string]$Format = "JSON"
    )
    
    Write-Verbose "Exporting unified graph to $Format format"
    
    switch ($Format) {
        "JSON" {
            $exportData = @{
                Name = $Graph.Name
                Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
                Statistics = Get-CrossLanguageStatistics -Graph $Graph
                Nodes = $Graph.Nodes.Values
                Edges = $Graph.Edges.Values
            }
            
            $exportData | ConvertTo-Json -Depth 10 | Out-File -FilePath $OutputPath -Encoding UTF8
        }
        
        "Markdown" {
            $stats = Get-CrossLanguageStatistics -Graph $Graph
            
            $markdown = @"
# Unified Code Property Graph Report

Generated: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")

## Summary Statistics

- **Total Nodes**: $($stats.TotalNodes)
- **Total Edges**: $($stats.TotalEdges)
- **Cross-Language Edges**: $($stats.CrossLanguageEdges) ($($stats.CrossLanguageRatio)%)

## Language Distribution

| Language | Nodes | Functions | Classes | Modules |
|----------|-------|-----------|---------|---------|
"@
            
            foreach ($lang in $stats.Languages.Keys | Sort-Object) {
                $langStats = $stats.Languages[$lang]
                $markdown += "`n| $lang | $($langStats.Nodes) | $($langStats.Functions) | $($langStats.Classes) | $($langStats.Modules) |"
            }
            
            $markdown += @"

## Cross-Language Connections

| Connection Type | Count |
|-----------------|-------|
"@
            
            foreach ($type in $stats.CrossLanguageTypes.Keys | Sort-Object) {
                $markdown += "`n| $type | $($stats.CrossLanguageTypes[$type]) |"
            }
            
            $markdown | Out-File -FilePath $OutputPath -Encoding UTF8
        }
        
        default {
            Write-Warning "Export format $Format not yet implemented"
        }
    }
    
    Write-Verbose "Graph exported to: $OutputPath"
}

# Export functions
Export-ModuleMember -Function @(
    'Merge-LanguageGraphs',
    'Get-CrossLanguageStatistics',
    'Export-UnifiedGraph'
)
# SIG # Begin signature block
# MIIFzgYJKoZIhvcNAQcCoIIFvzCCBbsCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCBSxPKPDZfaOqDD
# 3XEgGFMUojj2W/lmOglu5m7+gYz/WKCCAzAwggMsMIICFKADAgECAhB1HRbZIqgr
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
# MAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIE0jk7e4o4h5CxSa3pJVnaZi
# 3MflLI0kjZ1Xz/u+Nu3nMA0GCSqGSIb3DQEBAQUABIIBAI8iANXfqpAqlaTXBY3j
# 54RnueFVT5Oo4ISFcPgDCVQ3UF165Lzx+nmH1BuCC4QAUyQ1ufr6kJeb/kfPkrzt
# tO96MHgUBHzcnZp6dlwmYivYVOq2MuCjxgOdS3HCziQ3JDNmZsmFrOedAtcOw9lc
# 8jkc2DvwnhgOHBVWFehG/1kh0VFhOAJI/XVdH8jlsqNYyfFwwGEHH7dvlJFzZYnc
# UnJC2UXWMD5NcZGL5dS6NS67evztJtzm4SKa9oX3fIoEmjiNf8Nzw4mBz9dy5XLP
# jfRGBnLfiSxyOfjxzdPmbmJqdiAkGZaQIWZBrCEIQiHV9AdHk3zFEQk58qgxeWqy
# A0s=
# SIG # End signature block
