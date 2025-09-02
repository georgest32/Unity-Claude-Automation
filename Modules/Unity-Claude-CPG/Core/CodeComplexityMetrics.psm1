#region Code Complexity Metrics Component
<#
.SYNOPSIS
    Unity Claude CPG - Code Complexity Metrics Component
    
.DESCRIPTION
    Implements comprehensive code complexity analysis including cyclomatic complexity,
    cognitive complexity, nesting depth, and maintainability metrics using CPG analysis.
    
    Key capabilities:
    - Cyclomatic complexity calculation (McCabe's method)
    - Cognitive complexity assessment (Sonar's method)
    - Nesting depth analysis with weighted scoring
    - Lines of Code (LOC) metrics with categorization
    - Maintainability index calculation
    - Halstead complexity metrics
    - Function and class-level complexity scoring
    - Risk assessment and recommendations
    
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

#region Code Complexity Metrics

function Get-CodeComplexityMetrics {
    <#
    .SYNOPSIS
        Calculates comprehensive code complexity metrics for the CPG
        
    .DESCRIPTION
        Analyzes functions, methods, and classes in the Code Property Graph to calculate
        various complexity metrics including cyclomatic, cognitive, and maintainability metrics.
        
    .PARAMETER Graph
        The CPG graph to analyze
        
    .PARAMETER IncludeHalstead
        Include Halstead complexity metrics in analysis
        
    .PARAMETER DetailedAnalysis
        Include detailed per-function analysis
        
    .OUTPUTS
        System.Collections.Hashtable
        Contains comprehensive complexity analysis with metrics and recommendations
        
    .EXAMPLE
        $complexity = Get-CodeComplexityMetrics -Graph $cpgGraph
        Write-Host "Average cyclomatic complexity: $($complexity.Statistics.AverageCyclomaticComplexity)"
        
    .EXAMPLE
        $complexity = Get-CodeComplexityMetrics -Graph $cpgGraph -IncludeHalstead -DetailedAnalysis
        $complexity.HighComplexityFunctions | ForEach-Object { 
            Write-Host "High complexity: $($_.Name) - Cyclomatic: $($_.CyclomaticComplexity)"
        }
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        $Graph,
        
        [switch]$IncludeHalstead,
        [switch]$DetailedAnalysis
    )
    
    try {
        Write-Verbose "Calculating code complexity metrics for graph with $($Graph.Nodes.Count) nodes"
        
        # Get all analyzable nodes
        $functionNodes = @($Graph.Nodes.Values | Where-Object { 
            $_.Type -in @([CPGNodeType]::Function, [CPGNodeType]::Method)
        })
        
        $classNodes = @($Graph.Nodes.Values | Where-Object { 
            $_.Type -eq [CPGNodeType]::Class
        })
        
        Write-Verbose "Analyzing $($functionNodes.Count) functions and $($classNodes.Count) classes"
        
        # Calculate complexity for each function
        $functionComplexities = @()
        foreach ($func in $functionNodes) {
            $complexity = Get-FunctionComplexity -FunctionNode $func -Graph $Graph -IncludeHalstead:$IncludeHalstead
            $functionComplexities += $complexity
        }
        
        # Calculate complexity for each class
        $classComplexities = @()
        foreach ($class in $classNodes) {
            $complexity = Get-ClassComplexity -ClassNode $class -Graph $Graph
            $classComplexities += $complexity
        }
        
        # Calculate overall statistics
        $stats = Get-ComplexityStatistics -FunctionComplexities $functionComplexities -ClassComplexities $classComplexities
        
        # Identify high complexity items
        $highComplexityFunctions = @($functionComplexities | Where-Object { 
            $_.CyclomaticComplexity -gt 10 -or $_.CognitiveComplexity -gt 15
        })
        
        $highComplexityClasses = @($classComplexities | Where-Object { 
            $_.AverageMethodComplexity -gt 8 -or $_.TotalMethods -gt 20
        })
        
        # Generate recommendations
        $recommendations = Get-ComplexityRecommendations -Stats $stats -HighComplexityFunctions $highComplexityFunctions -HighComplexityClasses $highComplexityClasses
        
        $result = @{
            Statistics = $stats
            HighComplexityFunctions = @($highComplexityFunctions)
            HighComplexityClasses = @($highComplexityClasses)
            Recommendations = @($recommendations)
            Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        }
        
        # Add detailed analysis if requested
        if ($DetailedAnalysis) {
            $result.FunctionComplexities = @($functionComplexities)
            $result.ClassComplexities = @($classComplexities)
        }
        
        return $result
    }
    catch {
        Write-Error "Failed to calculate code complexity metrics: $_"
        throw
    }
}

function Get-FunctionComplexity {
    <#
    .SYNOPSIS
        Calculates complexity metrics for a single function
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        $FunctionNode,
        
        [Parameter(Mandatory)]
        $Graph,
        
        [switch]$IncludeHalstead
    )
    
    $complexity = @{
        Name = $FunctionNode.Name
        File = $FunctionNode.Properties.FilePath
        Line = $FunctionNode.Properties.LineNumber
        LinesOfCode = $FunctionNode.Properties.Size -or 0
    }
    
    # Calculate cyclomatic complexity
    $complexity.CyclomaticComplexity = Get-CyclomaticComplexity -FunctionNode $FunctionNode -Graph $Graph
    
    # Calculate cognitive complexity
    $complexity.CognitiveComplexity = Get-CognitiveComplexity -FunctionNode $FunctionNode -Graph $Graph
    
    # Calculate nesting depth
    $complexity.MaxNestingDepth = Get-MaxNestingDepth -FunctionNode $FunctionNode -Graph $Graph
    
    # Calculate maintainability index
    $complexity.MaintainabilityIndex = Get-MaintainabilityIndex -FunctionNode $FunctionNode
    
    # Add Halstead metrics if requested
    if ($IncludeHalstead) {
        $halstead = Get-HalsteadMetrics -FunctionNode $FunctionNode
        $complexity.HalsteadVolume = $halstead.Volume
        $complexity.HalsteadDifficulty = $halstead.Difficulty
        $complexity.HalsteadEffort = $halstead.Effort
    }
    
    # Calculate risk level
    $complexity.RiskLevel = Get-ComplexityRiskLevel -Complexity $complexity
    
    return $complexity
}

function Get-ClassComplexity {
    <#
    .SYNOPSIS
        Calculates complexity metrics for a single class
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        $ClassNode,
        
        [Parameter(Mandatory)]
        $Graph
    )
    
    # Get all methods in the class
    $methods = @($Graph.Nodes.Values | Where-Object { 
        $_.Type -eq [CPGNodeType]::Method -and 
        $_.Properties.ParentId -eq $ClassNode.Id
    })
    
    $methodComplexities = @()
    foreach ($method in $methods) {
        $methodComplexity = Get-FunctionComplexity -FunctionNode $method -Graph $Graph
        $methodComplexities += $methodComplexity.CyclomaticComplexity
    }
    
    $complexity = @{
        Name = $ClassNode.Name
        File = $ClassNode.Properties.FilePath
        Line = $ClassNode.Properties.LineNumber
        TotalMethods = $methods.Count
        TotalLinesOfCode = ($methods | Measure-Object -Property { $_.Properties.Size } -Sum).Sum
        AverageMethodComplexity = if ($methodComplexities.Count -gt 0) {
            [Math]::Round(($methodComplexities | Measure-Object -Average).Average, 2)
        } else { 0 }
        MaxMethodComplexity = if ($methodComplexities.Count -gt 0) {
            ($methodComplexities | Measure-Object -Maximum).Maximum
        } else { 0 }
    }
    
    # Calculate weighted complexity index
    $complexity.WeightedComplexityIndex = [Math]::Round(
        ($complexity.AverageMethodComplexity * 0.6) + 
        ($complexity.TotalMethods * 0.2) + 
        (($complexity.TotalLinesOfCode / 100) * 0.2), 2
    )
    
    return $complexity
}

function Get-CyclomaticComplexity {
    <#
    .SYNOPSIS
        Calculates McCabe cyclomatic complexity
    #>
    [CmdletBinding()]
    param($FunctionNode, $Graph)
    
    # Base complexity is 1
    $complexity = 1
    
    # Count decision points (simplified - would normally parse AST)
    $decisionPatterns = @(
        'if', 'elseif', 'else', 'switch', 'case', 'default',
        'while', 'for', 'foreach', 'do', 'try', 'catch',
        'and', 'or', '\?', '&&', '\|\|'
    )
    
    $content = $FunctionNode.Properties.Content
    if ($content) {
        foreach ($pattern in $decisionPatterns) {
            $matches = [regex]::Matches($content, $pattern, [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)
            $complexity += @($matches).Count
        }
    }
    
    return $complexity
}

function Get-CognitiveComplexity {
    <#
    .SYNOPSIS
        Calculates cognitive complexity (Sonar method)
    #>
    [CmdletBinding()]
    param($FunctionNode, $Graph)
    
    # Simplified cognitive complexity calculation
    $complexity = 0
    $nestingLevel = 0
    
    $content = $FunctionNode.Properties.Content
    if (-not $content) { return 0 }
    
    # Pattern weights for cognitive complexity
    $patterns = @{
        'if|elseif' = 1
        'else' = 1
        'switch' = 1
        'for|foreach|while|do' = 1
        'try|catch|finally' = 1
        'break|continue' = 1
        'goto' = 2
        'and|or|\&\&|\|\|' = 1
    }
    
    # Simplified nesting-aware complexity calculation
    $lines = $content -split "`n"
    foreach ($line in $lines) {
        # Track nesting level changes
        if ($line -match '\{') { $nestingLevel++ }
        if ($line -match '\}') { $nestingLevel = [Math]::Max(0, $nestingLevel - 1) }
        
        # Add complexity for patterns
        foreach ($pattern in $patterns.Keys) {
            if ($line -match $pattern) {
                $baseComplexity = $patterns[$pattern]
                $nestingBonus = [Math]::Max(0, $nestingLevel - 1)
                $complexity += $baseComplexity + $nestingBonus
            }
        }
    }
    
    return $complexity
}

function Get-MaxNestingDepth {
    <#
    .SYNOPSIS
        Calculates maximum nesting depth
    #>
    [CmdletBinding()]
    param($FunctionNode, $Graph)
    
    $maxDepth = 0
    $currentDepth = 0
    
    $content = $FunctionNode.Properties.Content
    if (-not $content) { return 0 }
    
    $lines = $content -split "`n"
    foreach ($line in $lines) {
        # Count opening braces
        $openBraces = ($line -split '\{').Count - 1
        $closeBraces = ($line -split '\}').Count - 1
        
        $currentDepth += $openBraces
        $maxDepth = [Math]::Max($maxDepth, $currentDepth)
        $currentDepth -= $closeBraces
        $currentDepth = [Math]::Max(0, $currentDepth)
    }
    
    return $maxDepth
}

function Get-MaintainabilityIndex {
    <#
    .SYNOPSIS
        Calculates maintainability index
    #>
    [CmdletBinding()]
    param($FunctionNode)
    
    $loc = $FunctionNode.Properties.Size -or 10
    $complexity = 5  # Simplified complexity estimate
    $volume = [Math]::Log($loc) * 33.3  # Simplified volume calculation
    
    # Microsoft's maintainability index formula (simplified)
    $maintainabilityIndex = [Math]::Max(0, 
        171 - (5.2 * [Math]::Log($volume)) - 
        (0.23 * $complexity) - 
        (16.2 * [Math]::Log($loc))
    )
    
    return [Math]::Round($maintainabilityIndex, 2)
}

function Get-HalsteadMetrics {
    <#
    .SYNOPSIS
        Calculates Halstead complexity metrics
    #>
    [CmdletBinding()]
    param($FunctionNode)
    
    $content = $FunctionNode.Properties.Content
    if (-not $content) {
        return @{
            Volume = 0
            Difficulty = 0
            Effort = 0
        }
    }
    
    # Simplified Halstead calculation (would normally need proper tokenization)
    $tokens = $content -split '\s+' | Where-Object { $_ -ne '' }
    $uniqueTokens = $tokens | Select-Object -Unique
    
    $n1 = @($uniqueTokens | Where-Object { $_ -match '^[a-zA-Z_][a-zA-Z0-9_]*$' }).Count  # Operators
    $n2 = @($uniqueTokens | Where-Object { $_ -notmatch '^[a-zA-Z_][a-zA-Z0-9_]*$' }).Count  # Operands
    $N1 = @($tokens | Where-Object { $_ -match '^[a-zA-Z_][a-zA-Z0-9_]*$' }).Count
    $N2 = @($tokens | Where-Object { $_ -notmatch '^[a-zA-Z_][a-zA-Z0-9_]*$' }).Count
    
    $vocabulary = $n1 + $n2
    $length = $N1 + $N2
    
    if ($vocabulary -eq 0) { $vocabulary = 1 }
    if ($n2 -eq 0) { $n2 = 1 }
    
    $volume = $length * [Math]::Log($vocabulary, 2)
    $difficulty = ($n1 / 2) * ($N2 / $n2)
    $effort = $difficulty * $volume
    
    return @{
        Volume = [Math]::Round($volume, 2)
        Difficulty = [Math]::Round($difficulty, 2)
        Effort = [Math]::Round($effort, 2)
    }
}

function Get-ComplexityRiskLevel {
    <#
    .SYNOPSIS
        Determines risk level based on complexity metrics
    #>
    [CmdletBinding()]
    param($Complexity)
    
    $cyclomaticRisk = if ($Complexity.CyclomaticComplexity -gt 20) { "High" }
                     elseif ($Complexity.CyclomaticComplexity -gt 10) { "Medium" }
                     else { "Low" }
    
    $cognitiveRisk = if ($Complexity.CognitiveComplexity -gt 30) { "High" }
                    elseif ($Complexity.CognitiveComplexity -gt 15) { "Medium" }
                    else { "Low" }
    
    $nestingRisk = if ($Complexity.MaxNestingDepth -gt 5) { "High" }
                  elseif ($Complexity.MaxNestingDepth -gt 3) { "Medium" }
                  else { "Low" }
    
    # Overall risk is highest individual risk
    $risks = @($cyclomaticRisk, $cognitiveRisk, $nestingRisk)
    if ("High" -in $risks) { return "High" }
    elseif ("Medium" -in $risks) { return "Medium" }
    else { return "Low" }
}

function Get-ComplexityStatistics {
    <#
    .SYNOPSIS
        Calculates overall complexity statistics
    #>
    [CmdletBinding()]
    param($FunctionComplexities, $ClassComplexities)
    
    $cyclomaticValues = @($FunctionComplexities.CyclomaticComplexity)
    $cognitiveValues = @($FunctionComplexities.CognitiveComplexity)
    $locValues = @($FunctionComplexities.LinesOfCode)
    
    return @{
        TotalFunctions = $FunctionComplexities.Count
        TotalClasses = $ClassComplexities.Count
        AverageCyclomaticComplexity = if ($cyclomaticValues.Count -gt 0) {
            [Math]::Round(($cyclomaticValues | Measure-Object -Average).Average, 2)
        } else { 0 }
        MaxCyclomaticComplexity = if ($cyclomaticValues.Count -gt 0) {
            ($cyclomaticValues | Measure-Object -Maximum).Maximum
        } else { 0 }
        AverageCognitiveComplexity = if ($cognitiveValues.Count -gt 0) {
            [Math]::Round(($cognitiveValues | Measure-Object -Average).Average, 2)
        } else { 0 }
        AverageLinesOfCode = if ($locValues.Count -gt 0) {
            [Math]::Round(($locValues | Measure-Object -Average).Average, 2)
        } else { 0 }
        HighRiskFunctions = @($FunctionComplexities | Where-Object { $_.RiskLevel -eq "High" }).Count
        MediumRiskFunctions = @($FunctionComplexities | Where-Object { $_.RiskLevel -eq "Medium" }).Count
        LowRiskFunctions = @($FunctionComplexities | Where-Object { $_.RiskLevel -eq "Low" }).Count
    }
}

function Get-ComplexityRecommendations {
    <#
    .SYNOPSIS
        Generates complexity-based recommendations
    #>
    [CmdletBinding()]
    param($Stats, $HighComplexityFunctions, $HighComplexityClasses)
    
    $recommendations = @()
    
    if ($Stats.AverageCyclomaticComplexity -gt 10) {
        $recommendations += "Average cyclomatic complexity is high ($($Stats.AverageCyclomaticComplexity)) - consider refactoring complex functions"
    }
    
    if (@($HighComplexityFunctions).Count -gt 0) {
        $recommendations += "Found $(@($HighComplexityFunctions).Count) high-complexity functions requiring immediate attention"
    }
    
    if (@($HighComplexityClasses).Count -gt 0) {
        $recommendations += "Found $(@($HighComplexityClasses).Count) complex classes that may benefit from decomposition"
    }
    
    if ($Stats.HighRiskFunctions -gt ($Stats.TotalFunctions * 0.2)) {
        $recommendations += "High proportion of risky functions ($($Stats.HighRiskFunctions)/$($Stats.TotalFunctions)) - prioritize refactoring"
    }
    
    if ($recommendations.Count -eq 0) {
        $recommendations += "Code complexity metrics are within acceptable ranges"
    }
    
    return $recommendations
}

#endregion Code Complexity Metrics

# Export public functions
Export-ModuleMember -Function @(
    'Get-CodeComplexityMetrics',
    'Get-FunctionComplexity',
    'Get-ClassComplexity'
)

#endregion Code Complexity Metrics Component
# SIG # Begin signature block
# MIIFzgYJKoZIhvcNAQcCoIIFvzCCBbsCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCCU/hlkH4MN/Tjz
# SU9VNihx45xLPyFj7EyRvDqd7mrarqCCAzAwggMsMIICFKADAgECAhB1HRbZIqgr
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
# MAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIAjItTMJhtd2h/F4xpFvQKiC
# cSMHzCGT4QFuxDdGaDa3MA0GCSqGSIb3DQEBAQUABIIBAB9jrC3KD/Gp7QvotAbz
# Uayf0T3jiPHi3WuAmMpChqyk93rAkkDHpUxKwGoLIsI4GgHXA5wFC84EMvTcZ89X
# 6D9SI0rCOgO95L/EYo7am+nX9R8y022w2hVa3T/bp2mSe9eR8Bf0P7V+DFsaynxN
# 2BfZ5NlW/b43sUJfsBas888eFPPXeSyqDXLaQ2P7Mbahwnaj6gLzgT8WwDX4pcsW
# NpWhk5BT3I6jPN1QPQthyJHjduSSImzgunpIHECj8rx94WHfP26bsYo0kB7/EaUZ
# l6DUgiwkk9J6oewCDjUE40vWTHLILszTpI1z42oBohw/Kf2MJFWd9LaeDizAPPGH
# A5Y=
# SIG # End signature block
