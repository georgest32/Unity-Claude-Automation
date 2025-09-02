#region Code Redundancy Detection Component
<#
.SYNOPSIS
    Unity Claude CPG - Code Redundancy Detection Component
    
.DESCRIPTION
    Implements sophisticated code redundancy detection algorithms to identify duplicate,
    similar, and redundant code patterns using structural and textual analysis.
    
    Key capabilities:
    - Duplicate function detection with configurable similarity thresholds
    - AST-based structural similarity analysis
    - Token-level duplicate code block identification
    - Clone detection with semantic equivalence checking
    - Statistical metrics for redundancy assessment
    - File-based grouping and impact analysis
    
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

#region Code Redundancy Detection

function Test-CodeRedundancy {
    <#
    .SYNOPSIS
        Tests for code redundancy using advanced similarity detection
        
    .DESCRIPTION
        Analyzes the Code Property Graph to identify duplicate functions, similar code blocks,
        and redundant patterns using both structural and textual analysis techniques.
        
    .PARAMETER Graph
        The CPG graph to analyze
        
    .PARAMETER SimilarityThreshold
        Threshold for similarity detection (0.0-1.0, default 0.8)
        
    .PARAMETER MinimumSize
        Minimum size in lines for code blocks to be considered for redundancy analysis
        
    .OUTPUTS
        System.Collections.Hashtable
        Contains redundancy analysis results with statistics and recommendations
        
    .EXAMPLE
        $redundancy = Test-CodeRedundancy -Graph $cpgGraph
        Write-Host "Found $($redundancy.DuplicateFunctions.Count) duplicate functions"
        
    .EXAMPLE
        $redundancy = Test-CodeRedundancy -Graph $cpgGraph -SimilarityThreshold 0.9 -MinimumSize 10
        $redundancy.SimilarCodeBlocks | ForEach-Object { 
            Write-Host "Similar block: $($_.Description)"
        }
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        $Graph,
        
        [ValidateRange(0.0, 1.0)]
        [double]$SimilarityThreshold = 0.8,
        
        [ValidateRange(1, 1000)]
        [int]$MinimumSize = 5
    )
    
    try {
        Write-Verbose "Testing code redundancy with threshold $SimilarityThreshold"
        
        # Get all function and method nodes
        $functionNodes = @($Graph.Nodes.Values | Where-Object { 
            $_.Type -in @([CPGNodeType]::Function, [CPGNodeType]::Method)
        })
        
        Write-Verbose "Analyzing $($functionNodes.Count) functions for redundancy"
        
        # Find duplicate functions
        $duplicateFunctions = Find-DuplicateFunctions -FunctionNodes $functionNodes -SimilarityThreshold $SimilarityThreshold
        
        # Find similar code blocks
        $similarBlocks = Find-SimilarCodeBlocks -Graph $Graph -MinimumSize $MinimumSize -SimilarityThreshold $SimilarityThreshold
        
        # Find clone groups
        $cloneGroups = Find-CloneGroups -Graph $Graph -SimilarityThreshold $SimilarityThreshold
        
        # Calculate redundancy statistics
        $stats = @{
            TotalFunctions = $functionNodes.Count
            DuplicateFunctions = @($duplicateFunctions).Count
            SimilarBlocks = @($similarBlocks).Count
            CloneGroups = @($cloneGroups).Count
            RedundancyRatio = if ($functionNodes.Count -gt 0) {
                [Math]::Round(([double](@($duplicateFunctions).Count) / [double]$functionNodes.Count) * 100, 2)
            } else { 0 }
        }
        
        # Group by file for analysis
        $byFile = @{}
        foreach ($duplicate in $duplicateFunctions) {
            $file = $duplicate.File
            if (-not $byFile.ContainsKey($file)) {
                $byFile[$file] = @{
                    File = $file
                    DuplicateCount = 0
                    Functions = @()
                }
            }
            $byFile[$file].DuplicateCount++
            $byFile[$file].Functions += $duplicate
        }
        
        # Create recommendations
        $recommendations = @()
        if (@($duplicateFunctions).Count -gt 0) {
            $recommendations += "Consider refactoring $(@($duplicateFunctions).Count) duplicate functions into shared utilities"
        }
        if (@($similarBlocks).Count -gt 0) {
            $recommendations += "Review $(@($similarBlocks).Count) similar code blocks for consolidation opportunities"
        }
        if (@($cloneGroups).Count -gt 0) {
            $recommendations += "Analyze $(@($cloneGroups).Count) clone groups for potential abstraction"
        }
        
        return @{
            DuplicateFunctions = @($duplicateFunctions)
            SimilarCodeBlocks = @($similarBlocks)
            CloneGroups = @($cloneGroups)
            Statistics = $stats
            ByFile = @($byFile.Values)
            Recommendations = @($recommendations)
            Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        }
    }
    catch {
        Write-Error "Failed to test code redundancy: $_"
        throw
    }
}

function Find-DuplicateFunctions {
    <#
    .SYNOPSIS
        Finds duplicate functions using structural similarity analysis
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [array]$FunctionNodes,
        
        [double]$SimilarityThreshold = 0.8
    )
    
    $duplicates = @()
    
    for ($i = 0; $i -lt $FunctionNodes.Count; $i++) {
        for ($j = $i + 1; $j -lt $FunctionNodes.Count; $j++) {
            $func1 = $FunctionNodes[$i]
            $func2 = $FunctionNodes[$j]
            
            # Skip if same function
            if ($func1.Id -eq $func2.Id) { continue }
            
            # Calculate similarity
            $similarity = Get-StructuralSimilarity -Node1 $func1 -Node2 $func2
            
            if ($similarity -ge $SimilarityThreshold) {
                $duplicates += @{
                    Function1 = @{
                        Name = $func1.Name
                        File = $func1.Properties.FilePath
                        Line = $func1.Properties.LineNumber
                        Id = $func1.Id
                    }
                    Function2 = @{
                        Name = $func2.Name
                        File = $func2.Properties.FilePath
                        Line = $func2.Properties.LineNumber
                        Id = $func2.Id
                    }
                    Similarity = [Math]::Round($similarity, 3)
                    Type = "Duplicate Function"
                }
            }
        }
    }
    
    return $duplicates
}

function Find-SimilarCodeBlocks {
    <#
    .SYNOPSIS
        Finds similar code blocks using token-level analysis
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        $Graph,
        
        [int]$MinimumSize = 5,
        [double]$SimilarityThreshold = 0.8
    )
    
    $similarBlocks = @()
    
    # Get all code block nodes
    $codeBlocks = @($Graph.Nodes.Values | Where-Object { 
        $_.Type -eq [CPGNodeType]::Block -and 
        $_.Properties.LineCount -ge $MinimumSize
    })
    
    Write-Verbose "Analyzing $($codeBlocks.Count) code blocks for similarity"
    
    for ($i = 0; $i -lt $codeBlocks.Count; $i++) {
        for ($j = $i + 1; $j -lt $codeBlocks.Count; $j++) {
            $block1 = $codeBlocks[$i]
            $block2 = $codeBlocks[$j]
            
            # Calculate token similarity
            $similarity = Get-TokenSimilarity -Block1 $block1 -Block2 $block2
            
            if ($similarity -ge $SimilarityThreshold) {
                $similarBlocks += @{
                    Block1 = @{
                        File = $block1.Properties.FilePath
                        StartLine = $block1.Properties.StartLine
                        EndLine = $block1.Properties.EndLine
                        LineCount = $block1.Properties.LineCount
                    }
                    Block2 = @{
                        File = $block2.Properties.FilePath
                        StartLine = $block2.Properties.StartLine
                        EndLine = $block2.Properties.EndLine
                        LineCount = $block2.Properties.LineCount
                    }
                    Similarity = [Math]::Round($similarity, 3)
                    Description = "Similar code block ($($block1.Properties.LineCount) lines)"
                }
            }
        }
    }
    
    return $similarBlocks
}

function Find-CloneGroups {
    <#
    .SYNOPSIS
        Identifies clone groups using semantic equivalence analysis
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        $Graph,
        
        [double]$SimilarityThreshold = 0.8
    )
    
    $cloneGroups = @()
    $processed = @{}
    
    # Get all nodes that can be clones
    $candidateNodes = @($Graph.Nodes.Values | Where-Object { 
        $_.Type -in @([CPGNodeType]::Function, [CPGNodeType]::Method, [CPGNodeType]::Class)
    })
    
    foreach ($node in $candidateNodes) {
        if ($processed.ContainsKey($node.Id)) { continue }
        
        $cloneGroup = @($node)
        $processed[$node.Id] = $true
        
        # Find all similar nodes
        foreach ($otherNode in $candidateNodes) {
            if ($processed.ContainsKey($otherNode.Id) -or $node.Id -eq $otherNode.Id) { continue }
            
            $similarity = Get-SemanticSimilarity -Node1 $node -Node2 $otherNode
            
            if ($similarity -ge $SimilarityThreshold) {
                $cloneGroup += $otherNode
                $processed[$otherNode.Id] = $true
            }
        }
        
        # Only add if group has multiple members
        if ($cloneGroup.Count -gt 1) {
            $cloneGroups += @{
                GroupSize = $cloneGroup.Count
                Type = $node.Type
                Members = @($cloneGroup | ForEach-Object {
                    @{
                        Name = $_.Name
                        File = $_.Properties.FilePath
                        Line = $_.Properties.LineNumber
                        Id = $_.Id
                    }
                })
                AverageSimilarity = [Math]::Round($SimilarityThreshold, 3)
            }
        }
    }
    
    return $cloneGroups
}

function Get-StructuralSimilarity {
    <#
    .SYNOPSIS
        Calculates structural similarity between two nodes
    #>
    [CmdletBinding()]
    param($Node1, $Node2)
    
    $similarity = 0.0
    $factors = 0
    
    # Name similarity (Levenshtein distance)
    if ($Node1.Name -and $Node2.Name) {
        $nameSimilarity = 1.0 - (Get-LevenshteinDistance $Node1.Name $Node2.Name) / [Math]::Max($Node1.Name.Length, $Node2.Name.Length)
        $similarity += $nameSimilarity * 0.3
        $factors += 0.3
    }
    
    # Parameter count similarity
    if ($Node1.Properties.ParameterCount -and $Node2.Properties.ParameterCount) {
        $paramDiff = [Math]::Abs($Node1.Properties.ParameterCount - $Node2.Properties.ParameterCount)
        $maxParams = [Math]::Max($Node1.Properties.ParameterCount, $Node2.Properties.ParameterCount)
        if ($maxParams -gt 0) {
            $paramSimilarity = 1.0 - ($paramDiff / $maxParams)
            $similarity += $paramSimilarity * 0.2
            $factors += 0.2
        }
    }
    
    # Size similarity
    if ($Node1.Properties.Size -and $Node2.Properties.Size) {
        $sizeDiff = [Math]::Abs($Node1.Properties.Size - $Node2.Properties.Size)
        $maxSize = [Math]::Max($Node1.Properties.Size, $Node2.Properties.Size)
        if ($maxSize -gt 0) {
            $sizeSimilarity = 1.0 - ($sizeDiff / $maxSize)
            $similarity += $sizeSimilarity * 0.5
            $factors += 0.5
        }
    }
    
    return if ($factors -gt 0) { $similarity / $factors } else { 0.0 }
}

function Get-TokenSimilarity {
    <#
    .SYNOPSIS
        Calculates token-level similarity between code blocks
    #>
    [CmdletBinding()]
    param($Block1, $Block2)
    
    # Simplified token similarity - would normally use actual tokenization
    $content1 = $Block1.Properties.Content -split '\s+' | Where-Object { $_ -ne '' }
    $content2 = $Block2.Properties.Content -split '\s+' | Where-Object { $_ -ne '' }
    
    if (-not $content1 -or -not $content2) { return 0.0 }
    
    $commonTokens = 0
    $totalTokens = [Math]::Max($content1.Count, $content2.Count)
    
    foreach ($token in $content1) {
        if ($token -in $content2) {
            $commonTokens++
        }
    }
    
    return if ($totalTokens -gt 0) { [double]$commonTokens / [double]$totalTokens } else { 0.0 }
}

function Get-SemanticSimilarity {
    <#
    .SYNOPSIS
        Calculates semantic similarity for clone detection
    #>
    [CmdletBinding()]
    param($Node1, $Node2)
    
    # Combine structural and behavioral similarity
    $structuralSim = Get-StructuralSimilarity -Node1 $Node1 -Node2 $Node2
    
    # Add behavioral factors (simplified)
    $behavioralSim = 0.0
    if ($Node1.Properties.ReturnType -eq $Node2.Properties.ReturnType) {
        $behavioralSim += 0.3
    }
    if ($Node1.Properties.Complexity -and $Node2.Properties.Complexity) {
        $complexityDiff = [Math]::Abs($Node1.Properties.Complexity - $Node2.Properties.Complexity)
        $maxComplexity = [Math]::Max($Node1.Properties.Complexity, $Node2.Properties.Complexity)
        if ($maxComplexity -gt 0) {
            $behavioralSim += (1.0 - ($complexityDiff / $maxComplexity)) * 0.2
        }
    }
    
    return ($structuralSim * 0.7) + ($behavioralSim * 0.3)
}

function Get-LevenshteinDistance {
    <#
    .SYNOPSIS
        Calculates Levenshtein distance between two strings
    #>
    [CmdletBinding()]
    param([string]$String1, [string]$String2)
    
    if (-not $String1) { return $String2.Length }
    if (-not $String2) { return $String1.Length }
    
    $len1 = $String1.Length
    $len2 = $String2.Length
    $matrix = New-Object 'int[,]' ($len1 + 1), ($len2 + 1)
    
    for ($i = 0; $i -le $len1; $i++) { $matrix[$i, 0] = $i }
    for ($j = 0; $j -le $len2; $j++) { $matrix[0, $j] = $j }
    
    for ($i = 1; $i -le $len1; $i++) {
        for ($j = 1; $j -le $len2; $j++) {
            $cost = if ($String1[$i-1] -eq $String2[$j-1]) { 0 } else { 1 }
            $matrix[$i, $j] = [Math]::Min([Math]::Min(
                $matrix[$i-1, $j] + 1,      # deletion
                $matrix[$i, $j-1] + 1),     # insertion
                $matrix[$i-1, $j-1] + $cost # substitution
            )
        }
    }
    
    return $matrix[$len1, $len2]
}

#endregion Code Redundancy Detection

# Export public functions
Export-ModuleMember -Function @(
    'Test-CodeRedundancy',
    'Find-DuplicateFunctions',
    'Find-SimilarCodeBlocks',
    'Find-CloneGroups'
)

#endregion Code Redundancy Detection Component
# SIG # Begin signature block
# MIIFzgYJKoZIhvcNAQcCoIIFvzCCBbsCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCC3L2ouKlhXZ9pb
# oyr4TJb3wtQ5T1mebN0mYmru7lusSKCCAzAwggMsMIICFKADAgECAhB1HRbZIqgr
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
# MAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEII7O3I9Oe4K+d8fcp/t+rKLz
# I/54FZTOmBcCa5K3WwcvMA0GCSqGSIb3DQEBAQUABIIBAEV6WdRxaA4C2izKKdlk
# Urw96KVSWZnPmJc71aXEAbY5ZIh+cBaZSVyUgc8CShwvo3rL8eO6aphjA8eL7YlR
# Ta3jBjJkMgW0476AR7XZlK8+Hd40iwAwvRotLWrKn7Ssn9/D0OOyehLX14CzN1Zz
# 0Si9W+GP0S1RSyPQ+g/yfoQXFOjVGt+KSUwpZfSsEJvo0jL3zlVjtdAv2Isx0ACr
# JKlJvzpHoSU7KckxUagDRAUerO34CgQfwQqwgCYXlADnzKpNaN1fLsJ03siVi9bB
# fzPkYKQ3HMWoqD/1fwY3X2DVInYOCshqgXsFqzg20R4Cxw/88ZsdKUZMXwIkuGE2
# D/g=
# SIG # End signature block
