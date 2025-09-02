# Unity-Claude-PredictiveAnalysis Code Smell Prediction Component
# Detects code smells like long methods, god classes, feature envy, and data clumps
# Part of refactored PredictiveAnalysis module

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

# Import dependencies
$CorePath = Join-Path $PSScriptRoot "PredictiveCore.psm1"
$RefactoringPath = Join-Path $PSScriptRoot "RefactoringDetection.psm1"

Import-Module $CorePath -Force
Import-Module $RefactoringPath -Force

function Predict-CodeSmells {
    <#
    .SYNOPSIS
    Predicts code smells in a codebase using CPG analysis
    .DESCRIPTION
    Analyzes code structure to identify various types of code smells including long methods,
    god classes, feature envy, and data clumps with confidence scores and remediation advice
    .PARAMETER Graph
    CPG graph to analyze for code smells
    .PARAMETER CustomThresholds
    Custom threshold values to override default smell detection thresholds
    .EXAMPLE
    Predict-CodeSmells -Graph $cpgGraph -CustomThresholds @{ MethodLength = 40; ClassSize = 400 }
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        $Graph,
        
        [hashtable]$CustomThresholds = @{}
    )
    
    Write-Verbose "Predicting code smells"
    
    try {
        # Check cache first
        $cacheKey = "smells_${Graph.Name}_$($CustomThresholds.GetHashCode())"
        $cached = Get-CacheItem -Key $cacheKey
        if ($cached) {
            Write-Verbose "Returning cached code smell analysis"
            return $cached
        }
        
        # Get default thresholds from configuration
        $config = Get-PredictiveConfig
        $defaultThresholds = @{
            MethodLength = 50
            ClassSize = 500
            CyclomaticComplexity = 10
            CouplingScore = 7
            DuplicationRatio = 0.05
            ParameterCount = 5
            ExternalCallThreshold = 5
        }
        
        # Merge with custom thresholds
        $thresholds = $defaultThresholds.Clone()
        foreach ($key in $CustomThresholds.Keys) {
            if ($thresholds.ContainsKey($key)) {
                $thresholds[$key] = $CustomThresholds[$key]
            }
        }
        
        $smells = @()
        
        # Detect long methods
        $longMethods = Find-LongMethods -Graph $Graph -Threshold $thresholds.MethodLength
        foreach ($method in $longMethods) {
            $severity = if ($method.LineCount -gt ($thresholds.MethodLength * 2)) { 'High' } 
                       elseif ($method.LineCount -gt ($thresholds.MethodLength * 1.5)) { 'Medium' } 
                       else { 'Low' }
                       
            $smells += @{
                Type = 'LongMethod'
                Target = $method.Name
                File = $method.File
                Severity = $severity
                Confidence = 0.95
                Impact = 'Readability, Testability, Maintainability'
                Fix = 'Extract Method refactoring - break into smaller, focused functions'
                Details = @{
                    CurrentLines = $method.LineCount
                    Threshold = $thresholds.MethodLength
                    Complexity = $method.Complexity
                    Parameters = $method.Parameters
                }
                Priority = $method.Priority
            }
        }
        
        # Detect god classes
        $godClasses = Find-GodClasses -Graph $Graph -MethodThreshold 20 -PropertyThreshold 15
        foreach ($class in $godClasses) {
            $smells += @{
                Type = 'GodClass'
                Target = $class.Name
                File = $class.File
                Severity = $class.Severity
                Confidence = 0.9
                Impact = 'Maintainability, Coupling, Single Responsibility Violation'
                Fix = $class.RefactoringStrategy
                Details = @{
                    MethodCount = $class.MethodCount
                    PropertyCount = $class.PropertyCount
                    Responsibilities = $class.Responsibilities
                }
                Priority = $class.Severity
            }
        }
        
        # Detect feature envy
        $featureEnvySmells = Find-FeatureEnvy -Graph $Graph -Threshold $thresholds.ExternalCallThreshold
        foreach ($envy in $featureEnvySmells) {
            $smells += $envy
        }
        
        # Detect data clumps
        $dataClumps = Find-DataClumps -Graph $Graph -MinOccurrences 3 -MinParameterCount $thresholds.ParameterCount
        foreach ($clump in $dataClumps) {
            $smells += $clump
        }
        
        # Detect high complexity methods
        $complexMethods = Find-HighComplexityMethods -Graph $Graph -Threshold $thresholds.CyclomaticComplexity
        foreach ($complex in $complexMethods) {
            $smells += $complex
        }
        
        # Detect excessive parameters
        $parameterSmells = Find-ExcessiveParameters -Graph $Graph -Threshold $thresholds.ParameterCount
        foreach ($param in $parameterSmells) {
            $smells += $param
        }
        
        # Calculate overall smell score
        $smellScore = 0
        foreach ($smell in $smells) {
            $severityWeight = switch ($smell.Severity) {
                'High' { 3 }
                'Medium' { 2 }
                'Low' { 1 }
                default { 1 }
            }
            $smellScore += $severityWeight * $smell.Confidence
        }
        
        # Create summary
        $summary = @{
            Total = $smells.Count
            High = ($smells | Where-Object { $_.Severity -eq 'High' }).Count
            Medium = ($smells | Where-Object { $_.Severity -eq 'Medium' }).Count
            Low = ($smells | Where-Object { $_.Severity -eq 'Low' }).Count
            TopSmells = $smells | Group-Object Type | Sort-Object Count -Descending | Select-Object -First 3 Name, Count
            Categories = @{
                LongMethod = ($smells | Where-Object { $_.Type -eq 'LongMethod' }).Count
                GodClass = ($smells | Where-Object { $_.Type -eq 'GodClass' }).Count
                FeatureEnvy = ($smells | Where-Object { $_.Type -eq 'FeatureEnvy' }).Count
                DataClump = ($smells | Where-Object { $_.Type -eq 'DataClump' }).Count
                HighComplexity = ($smells | Where-Object { $_.Type -eq 'HighComplexity' }).Count
                ExcessiveParameters = ($smells | Where-Object { $_.Type -eq 'ExcessiveParameters' }).Count
            }
        }
        
        $healthRating = if ($smellScore -lt 5) { 'Excellent' }
                       elseif ($smellScore -lt 15) { 'Good' }
                       elseif ($smellScore -lt 30) { 'Fair' }
                       else { 'Poor' }
        
        $result = @{
            Smells = $smells
            Score = [Math]::Round($smellScore, 2)
            Summary = $summary
            HealthRating = $healthRating
            Recommendations = Get-SmellRecommendations -Smells $smells -Score $smellScore
            Thresholds = $thresholds
        }
        
        # Cache the result
        Set-CacheItem -Key $cacheKey -Value $result -TTLMinutes 45
        
        return $result
    }
    catch {
        Write-Error "Failed to predict code smells: $_"
        return $null
    }
}

function Find-FeatureEnvy {
    <#
    .SYNOPSIS
    Detects feature envy code smell
    .DESCRIPTION
    Identifies functions that make excessive calls to external modules/classes
    .PARAMETER Graph
    CPG graph to analyze
    .PARAMETER Threshold
    Minimum number of external calls to flag as feature envy
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        $Graph,
        
        [int]$Threshold = 5
    )
    
    $envySmells = @()
    $functionNodes = Get-CPGNode -Graph $Graph -Type 'Function'
    
    foreach ($node in $functionNodes) {
        $externalCalls = Get-CPGEdge -Graph $Graph -SourceId $node.Id -Type 'Calls' |
            Where-Object { 
                $targetNode = $Graph.Nodes[$_.To]
                $targetNode -and $targetNode.Properties.Module -and $targetNode.Properties.Module -ne $node.Properties.Module
            }
        
        if ($externalCalls -and $externalCalls.Count -gt $Threshold) {
            # Analyze which external module is called most
            $moduleCallCounts = $externalCalls | ForEach-Object {
                $Graph.Nodes[$_.To].Properties.Module
            } | Group-Object | Sort-Object Count -Descending
            
            $primaryTarget = $moduleCallCounts[0]
            
            $envySmells += @{
                Type = 'FeatureEnvy'
                Target = $node.Name
                File = $node.Properties.File
                Severity = if ($externalCalls.Count -gt $Threshold * 2) { 'High' } 
                          elseif ($externalCalls.Count -gt $Threshold * 1.5) { 'Medium' } 
                          else { 'Low' }
                Confidence = [Math]::Min(0.5 + ($externalCalls.Count / 20.0), 0.9)
                Impact = 'Coupling, Cohesion, Maintainability'
                Fix = "Consider moving method to $($primaryTarget.Name) or create adapter pattern"
                Details = @{
                    ExternalCalls = $externalCalls.Count
                    PrimaryTarget = $primaryTarget.Name
                    CallsToTarget = $primaryTarget.Count
                    Threshold = $Threshold
                }
                Priority = 'Medium'
            }
        }
    }
    
    return $envySmells
}

function Find-DataClumps {
    <#
    .SYNOPSIS
    Detects data clump code smell
    .DESCRIPTION
    Identifies groups of parameters that appear together frequently across methods
    .PARAMETER Graph
    CPG graph to analyze
    .PARAMETER MinOccurrences
    Minimum number of methods that must share parameters to be considered a clump
    .PARAMETER MinParameterCount
    Minimum number of parameters in a group to be considered
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        $Graph,
        
        [int]$MinOccurrences = 3,
        
        [int]$MinParameterCount = 3
    )
    
    $clumpSmells = @()
    $functionNodes = Get-CPGNode -Graph $Graph -Type 'Function'
    $parameterPatterns = @{}
    
    # Collect parameter patterns
    foreach ($node in $functionNodes) {
        if ($node.Properties.Parameters -and $node.Properties.Parameters.Count -ge $MinParameterCount) {
            $params = $node.Properties.Parameters | Sort-Object
            
            # Generate all combinations of 3+ parameters
            for ($i = 0; $i -le $params.Count - $MinParameterCount; $i++) {
                for ($j = $i + $MinParameterCount - 1; $j -lt $params.Count; $j++) {
                    $paramGroup = $params[$i..$j] | Sort-Object | Join-String -Separator ','
                    
                    if (-not $parameterPatterns.ContainsKey($paramGroup)) {
                        $parameterPatterns[$paramGroup] = @()
                    }
                    $parameterPatterns[$paramGroup] += @{
                        Function = $node.Name
                        File = $node.Properties.File
                        Parameters = $params[$i..$j]
                    }
                }
            }
        }
    }
    
    # Identify clumps
    foreach ($pattern in $parameterPatterns.GetEnumerator()) {
        if ($pattern.Value.Count -ge $MinOccurrences) {
            $functions = $pattern.Value | ForEach-Object { $_.Function }
            $files = $pattern.Value | ForEach-Object { $_.File } | Select-Object -Unique
            
            $clumpSmells += @{
                Type = 'DataClump'
                Target = $functions -join ', '
                File = $files -join ', '
                Severity = if ($pattern.Value.Count -gt $MinOccurrences * 2) { 'Medium' } else { 'Low' }
                Confidence = [Math]::Min(0.4 + ($pattern.Value.Count / 10.0), 0.8)
                Impact = 'Code Duplication, Maintainability, Parameter Management'
                Fix = 'Extract parameter object or data class to encapsulate related data'
                Details = @{
                    Parameters = $pattern.Value[0].Parameters -join ', '
                    Occurrences = $pattern.Value.Count
                    AffectedFunctions = $functions
                    MinOccurrences = $MinOccurrences
                }
                Priority = 'Low'
            }
        }
    }
    
    return $clumpSmells
}

function Find-HighComplexityMethods {
    <#
    .SYNOPSIS
    Detects methods with excessive cyclomatic complexity
    .DESCRIPTION
    Identifies methods that exceed complexity thresholds
    .PARAMETER Graph
    CPG graph to analyze
    .PARAMETER Threshold
    Cyclomatic complexity threshold
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        $Graph,
        
        [int]$Threshold = 10
    )
    
    $complexitySmells = @()
    $functionNodes = Get-CPGNode -Graph $Graph -Type 'Function'
    
    foreach ($node in $functionNodes) {
        if ($node.Properties.CyclomaticComplexity -and $node.Properties.CyclomaticComplexity -gt $Threshold) {
            $complexity = $node.Properties.CyclomaticComplexity
            
            $complexitySmells += @{
                Type = 'HighComplexity'
                Target = $node.Name
                File = $node.Properties.File
                Severity = if ($complexity -gt $Threshold * 2) { 'High' } 
                          elseif ($complexity -gt $Threshold * 1.5) { 'Medium' } 
                          else { 'Low' }
                Confidence = 0.9
                Impact = 'Testability, Maintainability, Understandability'
                Fix = 'Reduce branching logic, extract conditions into methods, use polymorphism'
                Details = @{
                    Complexity = $complexity
                    Threshold = $Threshold
                    LineCount = $node.Properties.LineCount
                }
                Priority = if ($complexity -gt $Threshold * 2) { 'High' } else { 'Medium' }
            }
        }
    }
    
    return $complexitySmells
}

function Find-ExcessiveParameters {
    <#
    .SYNOPSIS
    Detects methods with too many parameters
    .DESCRIPTION
    Identifies methods that have excessive parameter counts
    .PARAMETER Graph
    CPG graph to analyze
    .PARAMETER Threshold
    Maximum parameter count threshold
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        $Graph,
        
        [int]$Threshold = 5
    )
    
    $parameterSmells = @()
    $functionNodes = Get-CPGNode -Graph $Graph -Type 'Function'
    
    foreach ($node in $functionNodes) {
        if ($node.Properties.Parameters -and $node.Properties.Parameters.Count -gt $Threshold) {
            $paramCount = $node.Properties.Parameters.Count
            
            $parameterSmells += @{
                Type = 'ExcessiveParameters'
                Target = $node.Name
                File = $node.Properties.File
                Severity = if ($paramCount -gt $Threshold * 2) { 'High' } 
                          elseif ($paramCount -gt $Threshold * 1.5) { 'Medium' } 
                          else { 'Low' }
                Confidence = 0.85
                Impact = 'Usability, Maintainability, Testing Complexity'
                Fix = 'Extract parameter object, use builder pattern, or split method responsibilities'
                Details = @{
                    ParameterCount = $paramCount
                    Threshold = $Threshold
                    Parameters = $node.Properties.Parameters -join ', '
                }
                Priority = 'Medium'
            }
        }
    }
    
    return $parameterSmells
}

function Get-SmellRecommendations {
    <#
    .SYNOPSIS
    Generates prioritized recommendations based on detected smells
    .DESCRIPTION
    Analyzes smell patterns to provide actionable remediation advice
    .PARAMETER Smells
    Array of detected code smells
    .PARAMETER Score
    Overall smell score
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [array]$Smells,
        
        [Parameter(Mandatory)]
        [double]$Score
    )
    
    $recommendations = @()
    
    # High-level recommendations based on score
    if ($Score -gt 30) {
        $recommendations += "Critical: Immediate refactoring required. Focus on high-severity smells first."
        $recommendations += "Consider code review process improvements and establish quality gates."
    } elseif ($Score -gt 15) {
        $recommendations += "Plan systematic refactoring over next 2-3 sprints."
        $recommendations += "Implement static analysis tools to prevent future smell accumulation."
    } elseif ($Score -gt 5) {
        $recommendations += "Monitor smell trends and address during regular maintenance."
        $recommendations += "Focus on preventing new smells rather than fixing all existing ones."
    } else {
        $recommendations += "Good code health. Maintain current practices."
        $recommendations += "Consider periodic smell monitoring as part of CI/CD pipeline."
    }
    
    # Specific recommendations based on smell types
    $smellTypes = $Smells | Group-Object Type
    
    foreach ($smellGroup in $smellTypes) {
        switch ($smellGroup.Name) {
            'LongMethod' {
                $recommendations += "Long Methods ($($smellGroup.Count)): Apply Extract Method refactoring to break down large functions."
            }
            'GodClass' {
                $recommendations += "God Classes ($($smellGroup.Count)): Apply Single Responsibility Principle - split classes by functionality."
            }
            'FeatureEnvy' {
                $recommendations += "Feature Envy ($($smellGroup.Count)): Move methods closer to the data they use most."
            }
            'DataClump' {
                $recommendations += "Data Clumps ($($smellGroup.Count)): Create parameter objects or data classes for frequently grouped parameters."
            }
            'HighComplexity' {
                $recommendations += "High Complexity ($($smellGroup.Count)): Simplify conditional logic using guard clauses and polymorphism."
            }
            'ExcessiveParameters' {
                $recommendations += "Excessive Parameters ($($smellGroup.Count)): Use parameter objects or builder pattern to reduce parameter count."
            }
        }
    }
    
    return $recommendations
}

# Export functions
Export-ModuleMember -Function @(
    'Predict-CodeSmells',
    'Find-FeatureEnvy',
    'Find-DataClumps', 
    'Find-HighComplexityMethods',
    'Find-ExcessiveParameters',
    'Get-SmellRecommendations'
)

Write-Verbose "CodeSmellPrediction component loaded successfully"
# SIG # Begin signature block
# MIIFzgYJKoZIhvcNAQcCoIIFvzCCBbsCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCCjLEObBp70ETTo
# up91wrWOQRXDouRJwTIbcx75on68IKCCAzAwggMsMIICFKADAgECAhB1HRbZIqgr
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
# MAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEICIuGTtaVRuFsu4iELiWhuPL
# jnCnZIeJXb8h1KL+XY3UMA0GCSqGSIb3DQEBAQUABIIBAKQHTpZSoE07OwCMNS5B
# nLYbsu9lRmr7D3kthTl1Vfn/zwT+JrM1CPKY4WACeSkjRH440rIZuF1GYw3PmB2F
# 4azp0TONcVG2wdP4b+4jn+K+XOmyqyYJjpOh9FVzrAK6MNxkKC4+JGvWgaAB2SBe
# 35Uob5vsoQURyYEYRp3+/i7/EmvO9uB8ZEc7UyhcZXt4+PDi/ocmakFwUqwp2exz
# bqLcqwL7VC52EhraNsDwccp8irMjCIODR84VFzcMgQg9CvVTrlVeOMbJPb0n1bBJ
# z3PYqyF8MDuKQWvCz1xRv6WI6EQytuVhz2Q3eNGAsW4VxvyDDqVWzf42VGTML/B2
# z3Q=
# SIG # End signature block
