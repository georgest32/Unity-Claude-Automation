# Unity-Claude-PredictiveAnalysis Refactoring Detection Component
# Identifies refactoring opportunities, long methods, god classes, and code duplication
# Part of refactored PredictiveAnalysis module

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

# Import dependencies
$CorePath = Join-Path $PSScriptRoot "PredictiveCore.psm1"
Import-Module $CorePath -Force

function Find-RefactoringOpportunities {
    <#
    .SYNOPSIS
    Identifies refactoring opportunities in a codebase
    .DESCRIPTION
    Analyzes code structure to find long methods, god classes, duplication, and coupling issues
    .PARAMETER Graph
    CPG graph to analyze
    .PARAMETER MaxResults
    Maximum number of opportunities to return
    .EXAMPLE
    Find-RefactoringOpportunities -Graph $cpgGraph -MaxResults 15
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        $Graph,
        
        [int]$MaxResults = 10
    )
    
    Write-Verbose "Finding refactoring opportunities"
    
    try {
        # Check cache first
        $cacheKey = "refactoring_${Graph.Name}_${MaxResults}"
        $cached = Get-CacheItem -Key $cacheKey
        if ($cached) {
            Write-Verbose "Returning cached refactoring opportunities"
            return $cached
        }
        
        $opportunities = @()
        
        # Find long methods
        $longMethods = Find-LongMethods -Graph $Graph -Threshold 50
        foreach ($method in $longMethods) {
            $opportunities += @{
                Type = 'ExtractMethod'
                Target = $method.Name
                Reason = "Method has $($method.LineCount) lines (threshold: 50)"
                Effort = 'Medium'
                Impact = 'High'
                Confidence = 0.9
                File = $method.File
                Details = $method.RefactoringHint
            }
        }
        
        # Find god classes
        $godClasses = Find-GodClasses -Graph $Graph -MethodThreshold 20
        foreach ($class in $godClasses) {
            $opportunities += @{
                Type = 'SplitClass'
                Target = $class.Name
                Reason = "Class has $($class.MethodCount) methods and $($class.PropertyCount) properties"
                Effort = 'High'
                Impact = 'High'
                Confidence = 0.85
                File = $class.File
                Details = $class.RefactoringStrategy
            }
        }
        
        # Find duplication candidates
        $duplicates = Get-DuplicationCandidates -Graph $Graph -MinSimilarity 0.8
        foreach ($dup in $duplicates) {
            $opportunities += @{
                Type = 'ExtractCommon'
                Target = "$($dup.Source) and $($dup.Target)"
                Reason = "$([Math]::Round($dup.Similarity * 100, 0))% code similarity"
                Effort = 'Low'
                Impact = 'Medium'
                Confidence = $dup.Similarity
                File = "$($dup.SourceFile) | $($dup.TargetFile)"
                Details = $dup.RefactoringHint
            }
        }
        
        # Find coupling issues
        $coupling = Get-CouplingIssues -Graph $Graph -Threshold 7
        foreach ($issue in $coupling) {
            $opportunities += @{
                Type = 'ReduceCoupling'
                Target = $issue.Module
                Reason = "High coupling score of $($issue.CouplingScore)"
                Effort = 'High'
                Impact = 'Medium'
                Confidence = 0.7
                File = $issue.Module
                Details = $issue.Recommendation
            }
        }
        
        # Sort by impact and confidence
        $sortedOpportunities = $opportunities | Sort-Object @{Expression={
            switch ($_.Impact) {
                'High' { 3 }
                'Medium' { 2 }
                'Low' { 1 }
                default { 0 }
            }
        }; Descending=$true}, @{Expression={$_.Confidence}; Descending=$true} | Select-Object -First $MaxResults
        
        $result = @{
            Opportunities = $sortedOpportunities
            Summary = @{
                Total = $sortedOpportunities.Count
                HighImpact = ($sortedOpportunities | Where-Object { $_.Impact -eq 'High' }).Count
                LowEffort = ($sortedOpportunities | Where-Object { $_.Effort -eq 'Low' }).Count
                TopRecommendation = if ($sortedOpportunities.Count -gt 0) { $sortedOpportunities[0] } else { $null }
                Categories = @{
                    ExtractMethod = ($sortedOpportunities | Where-Object { $_.Type -eq 'ExtractMethod' }).Count
                    SplitClass = ($sortedOpportunities | Where-Object { $_.Type -eq 'SplitClass' }).Count
                    ExtractCommon = ($sortedOpportunities | Where-Object { $_.Type -eq 'ExtractCommon' }).Count
                    ReduceCoupling = ($sortedOpportunities | Where-Object { $_.Type -eq 'ReduceCoupling' }).Count
                }
            }
        }
        
        # Cache the result
        Set-CacheItem -Key $cacheKey -Value $result -TTLMinutes 30
        
        return $result
    }
    catch {
        Write-Error "Failed to find refactoring opportunities: $_"
        return $null
    }
}

function Find-LongMethods {
    <#
    .SYNOPSIS
    Identifies methods that exceed line count thresholds
    .DESCRIPTION
    Analyzes function nodes in CPG to find methods with excessive line counts
    .PARAMETER Graph
    CPG graph to analyze
    .PARAMETER Threshold
    Line count threshold for flagging methods as long
    .EXAMPLE
    Find-LongMethods -Graph $cpgGraph -Threshold 40
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        $Graph,
        
        [int]$Threshold = 50
    )
    
    Write-Verbose "Finding long methods (threshold: $Threshold lines)"
    
    try {
        $longMethods = @()
        
        $functionNodes = Get-CPGNode -Graph $Graph -Type 'Function'
        
        foreach ($node in $functionNodes) {
            if ($node.Properties.LineCount -and $node.Properties.LineCount -gt $Threshold) {
                $refactoringHint = if ($node.Properties.LineCount -gt 100) {
                    "Consider breaking into multiple smaller functions"
                } elseif ($node.Properties.CyclomaticComplexity -and $node.Properties.CyclomaticComplexity -gt 10) {
                    "High complexity suggests multiple responsibilities"
                } else {
                    "Extract logical sections into helper functions"
                }
                
                $longMethods += @{
                    Name = $node.Name
                    LineCount = $node.Properties.LineCount
                    File = $node.Properties.File
                    Complexity = $node.Properties.CyclomaticComplexity
                    Parameters = if ($node.Properties.Parameters) { $node.Properties.Parameters.Count } else { 0 }
                    RefactoringHint = $refactoringHint
                    Priority = if ($node.Properties.LineCount -gt 100 -and $node.Properties.CyclomaticComplexity -gt 15) { 'High' }
                              elseif ($node.Properties.LineCount -gt 80 -or $node.Properties.CyclomaticComplexity -gt 10) { 'Medium' }
                              else { 'Low' }
                }
            }
        }
        
        return $longMethods | Sort-Object LineCount -Descending
    }
    catch {
        Write-Error "Failed to find long methods: $_"
        return @()
    }
}

function Find-GodClasses {
    <#
    .SYNOPSIS
    Identifies classes with too many methods or properties
    .DESCRIPTION
    Finds classes that violate single responsibility principle by having excessive methods/properties
    .PARAMETER Graph
    CPG graph to analyze
    .PARAMETER MethodThreshold
    Maximum number of methods before flagging as god class
    .PARAMETER PropertyThreshold
    Maximum number of properties before flagging as god class
    .EXAMPLE
    Find-GodClasses -Graph $cpgGraph -MethodThreshold 15 -PropertyThreshold 10
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        $Graph,
        
        [int]$MethodThreshold = 20,
        
        [int]$PropertyThreshold = 15
    )
    
    Write-Verbose "Finding god classes (method threshold: $MethodThreshold, property threshold: $PropertyThreshold)"
    
    try {
        $godClasses = @()
        
        $classNodes = Get-CPGNode -Graph $Graph -Type 'Class'
        
        foreach ($node in $classNodes) {
            $methods = Get-CPGEdge -Graph $Graph -SourceId $node.Id -Type 'Contains' | 
                Where-Object { $Graph.Nodes[$_.To].Type -eq 'Function' }
            
            $properties = Get-CPGEdge -Graph $Graph -SourceId $node.Id -Type 'Contains' | 
                Where-Object { $Graph.Nodes[$_.To].Type -eq 'Property' }
            
            $methodCount = if ($methods) { $methods.Count } else { 0 }
            $propertyCount = if ($properties) { $properties.Count } else { 0 }
            
            if ($methodCount -gt $MethodThreshold -or $propertyCount -gt $PropertyThreshold) {
                $refactoringStrategy = if ($methodCount -gt 30) {
                    "Split into multiple classes based on responsibility"
                } elseif ($propertyCount -gt 20) {
                    "Consider using composition or data transfer objects"  
                } else {
                    "Review single responsibility principle"
                }
                
                $godClass = @{
                    Name = $node.Name
                    MethodCount = $methodCount
                    PropertyCount = $propertyCount
                    File = $node.Properties.File
                    Responsibilities = @()
                    RefactoringStrategy = $refactoringStrategy
                    Severity = if ($methodCount -gt 40 -or $propertyCount -gt 30) { 'High' }
                              elseif ($methodCount -gt 25 -or $propertyCount -gt 20) { 'Medium' }
                              else { 'Low' }
                }
                
                # Try to identify responsibilities based on method name patterns
                if ($methods) {
                    $methodNames = $methods | ForEach-Object { $Graph.Nodes[$_.To].Name }
                    $prefixes = $methodNames | ForEach-Object { 
                        if ($_ -match '^(Get|Set|Add|Remove|Create|Delete|Update|Find|Search|Validate|Process|Handle|Calculate)-') {
                            $Matches[1]
                        } elseif ($_ -match '^([A-Za-z]+)') {
                            ($Matches[1] -split '(?=[A-Z])')[-1]
                        }
                    } | Where-Object { $_ } | Group-Object | Where-Object { $_.Count -gt 2 }
                    
                    foreach ($prefix in $prefixes) {
                        $godClass.Responsibilities += "$($prefix.Name) operations ($($prefix.Count) methods)"
                    }
                }
                
                $godClasses += $godClass
            }
        }
        
        return $godClasses | Sort-Object { $_.MethodCount + $_.PropertyCount } -Descending
    }
    catch {
        Write-Error "Failed to find god classes: $_"
        return @()
    }
}

function Get-DuplicationCandidates {
    <#
    .SYNOPSIS
    Finds functions with similar structure that could be refactored
    .DESCRIPTION
    Compares function signatures and structures to identify duplication opportunities
    .PARAMETER Graph
    CPG graph to analyze
    .PARAMETER MinSimilarity
    Minimum similarity threshold (0.0 to 1.0)
    .EXAMPLE
    Get-DuplicationCandidates -Graph $cpgGraph -MinSimilarity 0.75
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        $Graph,
        
        [ValidateRange(0.0, 1.0)]
        [double]$MinSimilarity = 0.8
    )
    
    Write-Verbose "Finding duplication candidates (min similarity: $MinSimilarity)"
    
    try {
        $candidates = @()
        $functionNodes = Get-CPGNode -Graph $Graph -Type 'Function'
        
        if ($functionNodes.Count -lt 2) {
            Write-Verbose "Not enough functions to analyze for duplication"
            return $candidates
        }
        
        # Compare functions pairwise
        for ($i = 0; $i -lt $functionNodes.Count - 1; $i++) {
            for ($j = $i + 1; $j -lt $functionNodes.Count; $j++) {
                $node1 = $functionNodes[$i]
                $node2 = $functionNodes[$j]
                
                # Skip if same function
                if ($node1.Name -eq $node2.Name) { continue }
                
                # Calculate similarity based on multiple factors
                $similarity = Calculate-FunctionSimilarity -Function1 $node1 -Function2 $node2 -Graph $Graph
                
                if ($similarity -ge $MinSimilarity) {
                    $refactoringHint = if ($similarity -gt 0.95) {
                        "Nearly identical - consider complete extraction"
                    } elseif ($node1.Properties.File -eq $node2.Properties.File) {
                        "Same file - extract to private helper function"
                    } else {
                        "Different files - extract to shared utility module"
                    }
                    
                    $candidates += @{
                        Source = $node1.Name
                        Target = $node2.Name
                        Similarity = [Math]::Round($similarity, 2)
                        SourceFile = $node1.Properties.File
                        TargetFile = $node2.Properties.File
                        RefactoringHint = $refactoringHint
                        Priority = if ($similarity -gt 0.95) { 'High' } 
                                  elseif ($similarity -gt 0.85) { 'Medium' } 
                                  else { 'Low' }
                        EstimatedSavings = [Math]::Round(($node1.Properties.LineCount + $node2.Properties.LineCount) * ($similarity - 0.5), 0)
                    }
                }
            }
        }
        
        return $candidates | Sort-Object Similarity -Descending
    }
    catch {
        Write-Error "Failed to find duplication candidates: $_"
        return @()
    }
}

function Calculate-FunctionSimilarity {
    <#
    .SYNOPSIS
    Calculates similarity score between two functions
    .DESCRIPTION
    Uses multiple heuristics to determine structural similarity between functions
    .PARAMETER Function1
    First function node
    .PARAMETER Function2
    Second function node
    .PARAMETER Graph
    CPG graph containing the functions
    .EXAMPLE
    Calculate-FunctionSimilarity -Function1 $func1 -Function2 $func2 -Graph $graph
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        $Function1,
        
        [Parameter(Mandatory)]
        $Function2,
        
        [Parameter(Mandatory)]
        $Graph
    )
    
    $similarity = 0.0
    
    try {
        # Parameter count similarity (20% weight)
        if ($Function1.Properties.Parameters -and $Function2.Properties.Parameters) {
            $param1Count = $Function1.Properties.Parameters.Count
            $param2Count = $Function2.Properties.Parameters.Count
            
            if ($param1Count -eq $param2Count) {
                $similarity += 0.2
            } elseif ($param1Count -gt 0 -and $param2Count -gt 0) {
                $paramSim = 1 - ([Math]::Abs($param1Count - $param2Count) / [Math]::Max($param1Count, $param2Count))
                $similarity += $paramSim * 0.2
            }
        }
        
        # Line count similarity (30% weight)
        if ($Function1.Properties.LineCount -and $Function2.Properties.LineCount) {
            $line1 = $Function1.Properties.LineCount
            $line2 = $Function2.Properties.LineCount
            
            $lineDiff = [Math]::Abs($line1 - $line2)
            $avgLines = ($line1 + $line2) / 2
            
            if ($avgLines -gt 0) {
                $lineSimilarity = [Math]::Max(0, 1 - ($lineDiff / $avgLines))
                $similarity += $lineSimilarity * 0.3
            }
        }
        
        # Complexity similarity (20% weight)
        if ($Function1.Properties.CyclomaticComplexity -and $Function2.Properties.CyclomaticComplexity) {
            $comp1 = $Function1.Properties.CyclomaticComplexity
            $comp2 = $Function2.Properties.CyclomaticComplexity
            
            if ($comp1 -eq $comp2) {
                $similarity += 0.2
            } elseif ($comp1 -gt 0 -and $comp2 -gt 0) {
                $compSim = 1 - ([Math]::Abs($comp1 - $comp2) / [Math]::Max($comp1, $comp2))
                $similarity += $compSim * 0.2
            }
        }
        
        # Edge pattern similarity (30% weight)
        $edges1 = Get-CPGEdge -Graph $Graph -SourceId $Function1.Id
        $edges2 = Get-CPGEdge -Graph $Graph -SourceId $Function2.Id
        
        if ($edges1 -and $edges2) {
            $edgeTypes1 = $edges1 | Select-Object -ExpandProperty Type -Unique
            $edgeTypes2 = $edges2 | Select-Object -ExpandProperty Type -Unique
            
            $commonTypes = $edgeTypes1 | Where-Object { $_ -in $edgeTypes2 }
            $allTypes = ($edgeTypes1 + $edgeTypes2) | Select-Object -Unique
            
            if ($allTypes.Count -gt 0) {
                $edgeSimilarity = $commonTypes.Count / $allTypes.Count
                $similarity += $edgeSimilarity * 0.3
            }
        }
        
        return [Math]::Min([Math]::Max($similarity, 0.0), 1.0)
    }
    catch {
        Write-Verbose "Error calculating function similarity: $_"
        return 0.0
    }
}

function Get-CouplingIssues {
    <#
    .SYNOPSIS
    Analyzes coupling between modules
    .DESCRIPTION
    Identifies modules with high coupling scores based on dependencies and external calls
    .PARAMETER Graph
    CPG graph to analyze
    .PARAMETER Threshold
    Coupling score threshold for flagging issues
    .EXAMPLE
    Get-CouplingIssues -Graph $cpgGraph -Threshold 8
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        $Graph,
        
        [int]$Threshold = 7
    )
    
    Write-Verbose "Analyzing coupling issues (threshold: $Threshold)"
    
    try {
        $issues = @()
        $moduleNodes = Get-CPGNode -Graph $Graph -Type 'Module'
        
        foreach ($module in $moduleNodes) {
            # Count external dependencies
            $externalDeps = Get-CPGEdge -Graph $Graph -SourceId $module.Id -Type 'DependsOn' |
                Where-Object { 
                    $target = $Graph.Nodes[$_.To]
                    $target -and $target.Type -eq 'Module' -and $target.Id -ne $module.Id
                }
            
            # Count external calls from functions in this module
            $functionsInModule = Get-CPGEdge -Graph $Graph -SourceId $module.Id -Type 'Contains' |
                Where-Object { $Graph.Nodes[$_.To].Type -eq 'Function' }
            
            $externalCalls = 0
            if ($functionsInModule) {
                foreach ($func in $functionsInModule) {
                    $calls = Get-CPGEdge -Graph $Graph -SourceId $func.To -Type 'Calls' |
                        Where-Object {
                            $targetFunc = $Graph.Nodes[$_.To]
                            $targetFunc -and $targetFunc.Properties.Module -and $targetFunc.Properties.Module -ne $module.Name
                        }
                    if ($calls) {
                        $externalCalls += $calls.Count
                    }
                }
            }
            
            # Calculate coupling score
            $depCount = if ($externalDeps) { $externalDeps.Count } else { 0 }
            $callWeight = [Math]::Min($externalCalls / 10, 10)  # Normalize call count
            $couplingScore = $depCount + $callWeight
            
            if ($couplingScore -gt $Threshold) {
                $risk = if ($couplingScore -gt 15) { 'High' } 
                       elseif ($couplingScore -gt 10) { 'Medium' } 
                       else { 'Low' }
                
                $recommendation = if ($couplingScore -gt 15) {
                    "Critical coupling - consider architectural refactoring"
                } elseif ($depCount -gt 5) {
                    "Too many dependencies - apply dependency inversion"
                } else {
                    "High external communication - consider facade pattern"
                }
                
                $issues += @{
                    Module = $module.Name
                    CouplingScore = [Math]::Round($couplingScore, 1)
                    ExternalDependencies = $depCount
                    ExternalCalls = $externalCalls
                    Risk = $risk
                    Recommendation = $recommendation
                }
            }
        }
        
        return $issues | Sort-Object CouplingScore -Descending
    }
    catch {
        Write-Error "Failed to analyze coupling issues: $_"
        return @()
    }
}

# Export functions
Export-ModuleMember -Function @(
    'Find-RefactoringOpportunities',
    'Find-LongMethods', 
    'Find-GodClasses',
    'Get-DuplicationCandidates',
    'Calculate-FunctionSimilarity',
    'Get-CouplingIssues'
)

Write-Verbose "RefactoringDetection component loaded successfully"
# SIG # Begin signature block
# MIIFzgYJKoZIhvcNAQcCoIIFvzCCBbsCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCAfE9c63dDEGCgk
# j45YbjXz4NXgy/r1fJM0dgmkyDupt6CCAzAwggMsMIICFKADAgECAhB1HRbZIqgr
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
# MAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEILf+Zh1H2tAvyoTLE1uxjdFk
# cabA8gvckwBxc0F/1Wr0MA0GCSqGSIb3DQEBAQUABIIBAH9KMhg7q8exQ43hC6pG
# sqUXo2G8A/xBmac6o2b6VtL0GrWDTJQK26H11rb/GLhjtKNKfGseUsvjW4BHAkeZ
# XID8QQL3s07hGwVBHd7kdN6ODs4J6+JAARDJDHBf6g4l+iIEIYEOEjFR3nhGb+s2
# TdiODxD2m9Q2dBCfJaqFTPiKb4B1R1bn5dcIWIq51X4hcjtNX9v48LUDP8Ox5BNr
# grz4p27x9tWfYl0ruvxXIPP3cNjikFKPF8fhbSHXSHSXwhWpG8UDLIcNMbBmHSXO
# 0YTKKF7wnqJyQZqfzJFZvJhipqK3GRGUVFGAF3n4lDiZdYhytKXuT9O7uJBiSvaT
# dGI=
# SIG # End signature block
