# Unity-Claude-PredictiveAnalysis Risk Assessment Component
# Bug probability, maintenance risk, anti-patterns, and design flaw detection
# Part of refactored PredictiveAnalysis module

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

# Import dependencies
$CorePath = Join-Path $PSScriptRoot "PredictiveCore.psm1"
$TrendPath = Join-Path $PSScriptRoot "TrendAnalysis.psm1"
$MaintenancePath = Join-Path $PSScriptRoot "MaintenancePrediction.psm1"
$RefactoringPath = Join-Path $PSScriptRoot "RefactoringDetection.psm1"
$SmellPath = Join-Path $PSScriptRoot "CodeSmellPrediction.psm1"

Import-Module $CorePath -Force
Import-Module $TrendPath -Force
Import-Module $MaintenancePath -Force
Import-Module $RefactoringPath -Force
Import-Module $SmellPath -Force

function Predict-BugProbability {
    <#
    .SYNOPSIS
    Predicts the probability of bugs based on multiple code quality factors
    .DESCRIPTION
    Analyzes code churn, complexity, test coverage, recent changes, and author patterns
    to estimate the likelihood of bugs occurring in a given path
    .PARAMETER Path
    Path to analyze for bug probability
    .PARAMETER Graph
    Optional CPG graph for enhanced complexity analysis
    .EXAMPLE
    Predict-BugProbability -Path "C:\Project\Module" -Graph $cpgGraph
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Path,
        
        $Graph = $null
    )
    
    Write-Verbose "Predicting bug probability for $Path"
    
    try {
        # Check cache first
        $cacheKey = "bug_prob_${Path}_$($Graph -ne $null)"
        $cached = Get-CacheItem -Key $cacheKey
        if ($cached) {
            Write-Verbose "Returning cached bug probability"
            return $cached
        }
        
        # Initialize risk factors (weights sum to 1.0)
        $factors = @{
            HighChurn = @{ Weight = 0.0; Value = 0.3 }
            HighComplexity = @{ Weight = 0.0; Value = 0.25 }
            LowTestCoverage = @{ Weight = 0.0; Value = 0.3 }
            RecentChanges = @{ Weight = 0.0; Value = 0.2 }
            MultipleAuthors = @{ Weight = 0.0; Value = 0.15 }
            HistoricalBugs = @{ Weight = 0.0; Value = 0.1 }
        }
        
        # Factor 1: Code churn analysis
        try {
            $churn = Measure-CodeChurn -Path $Path -DaysBack 30
            if ($churn -and $churn.ChurnRate -gt 50) {
                $factors.HighChurn.Weight = [Math]::Min($churn.ChurnRate / 100, 1.0)
                Write-Verbose "High churn detected: $($churn.ChurnRate) lines/day"
            }
        }
        catch {
            Write-Verbose "Could not analyze code churn: $_"
        }
        
        # Factor 2: Complexity analysis
        if ($Graph) {
            try {
                $functionNodes = Get-CPGNode -Graph $Graph -Type 'Function'
                if ($functionNodes) {
                    $avgComplexity = ($functionNodes | Where-Object { $_.Properties.CyclomaticComplexity } | 
                        Measure-Object -Property { $_.Properties.CyclomaticComplexity } -Average).Average
                    
                    if ($avgComplexity -gt 10) {
                        $factors.HighComplexity.Weight = [Math]::Min($avgComplexity / 20, 1.0)
                        Write-Verbose "High complexity detected: $avgComplexity average"
                    }
                }
            }
            catch {
                Write-Verbose "Could not analyze complexity: $_"
            }
        }
        
        # Factor 3: Test coverage estimation (simplified)
        try {
            $codeFiles = Get-ChildItem -Path $Path -Filter "*.ps*1" -Recurse -ErrorAction SilentlyContinue
            $testFiles = Get-ChildItem -Path $Path -Filter "*test*.ps1" -Recurse -ErrorAction SilentlyContinue
            
            if ($codeFiles.Count -gt 0) {
                $testRatio = $testFiles.Count / $codeFiles.Count
                if ($testRatio -lt 0.3) {  # Less than 30% test files
                    $factors.LowTestCoverage.Weight = 1.0 - $testRatio
                    Write-Verbose "Low test coverage detected: $($testRatio * 100)%"
                }
            }
        }
        catch {
            Write-Verbose "Could not analyze test coverage: $_"
        }
        
        # Factor 4: Recent changes
        try {
            $recentCommits = git log --since="1 week ago" --pretty=format:"%H" -- $Path 2>$null | Measure-Object
            if ($recentCommits.Count -gt 5) {
                $factors.RecentChanges.Weight = [Math]::Min($recentCommits.Count / 20, 1.0)
                Write-Verbose "High recent activity detected: $($recentCommits.Count) commits"
            }
        }
        catch {
            Write-Verbose "Could not analyze recent changes: $_"
        }
        
        # Factor 5: Author diversity (bus factor)
        try {
            $authors = Get-AuthorContributions -Path $Path -DaysBack 30
            if ($authors -and $authors.TotalAuthors -gt 3) {
                # More authors can mean more inconsistency
                $factors.MultipleAuthors.Weight = [Math]::Min($authors.TotalAuthors / 10, 0.5)
                Write-Verbose "Multiple authors detected: $($authors.TotalAuthors)"
            }
        }
        catch {
            Write-Verbose "Could not analyze author contributions: $_"
        }
        
        # Calculate weighted probability
        $probability = 0
        $totalWeight = 0
        
        foreach ($factor in $factors.GetEnumerator()) {
            if ($factor.Value.Weight -gt 0) {
                $contribution = $factor.Value.Weight * $factor.Value.Value
                $probability += $contribution
                $totalWeight += $factor.Value.Weight
                Write-Verbose "$($factor.Key): Weight=$($factor.Value.Weight), Contribution=$contribution"
            }
        }
        
        # Normalize if we have contributing factors
        if ($totalWeight -gt 0) {
            $probability = $probability / $totalWeight
        }
        
        $probability = [Math]::Min([Math]::Max($probability, 0.0), 1.0)
        
        # Determine risk level and recommendations
        $risk = if ($probability -gt 0.7) { 'High' }
               elseif ($probability -gt 0.4) { 'Medium' }
               else { 'Low' }
        
        $recommendation = switch ($risk) {
            'High' { 
                "Critical bug risk detected. Immediate actions: comprehensive testing, code review, and consider refactoring complex areas." 
            }
            'Medium' { 
                "Moderate bug risk. Recommended: increase test coverage, implement additional code reviews, and monitor closely." 
            }
            'Low' { 
                "Low bug risk. Maintain current quality practices and continue monitoring." 
            }
        }
        
        $result = @{
            Path = $Path
            Probability = [Math]::Round($probability, 3)
            Risk = $risk
            Confidence = if ($totalWeight -gt 0.5) { 'High' } 
                        elseif ($totalWeight -gt 0.2) { 'Medium' } 
                        else { 'Low' }
            ContributingFactors = $factors.Keys | Where-Object { $factors[$_].Weight -gt 0 }
            FactorWeights = $factors
            Recommendation = $recommendation
            ActionItems = Get-BugPreventionActions -Risk $risk -Factors $factors
        }
        
        # Cache the result
        Set-CacheItem -Key $cacheKey -Value $result -TTLMinutes 60
        
        return $result
    }
    catch {
        Write-Error "Failed to predict bug probability: $_"
        return $null
    }
}

function Get-BugPreventionActions {
    <#
    .SYNOPSIS
    Generates specific action items based on bug risk factors
    .PARAMETER Risk
    Risk level (High, Medium, Low)
    .PARAMETER Factors
    Contributing risk factors
    #>
    [CmdletBinding()]
    param(
        [string]$Risk,
        [hashtable]$Factors
    )
    
    $actions = @()
    
    # High churn actions
    if ($Factors.HighChurn.Weight -gt 0) {
        $actions += "Implement code review gates for frequently changing files"
        $actions += "Consider architectural changes to reduce change frequency"
    }
    
    # High complexity actions
    if ($Factors.HighComplexity.Weight -gt 0) {
        $actions += "Refactor complex functions using Extract Method pattern"
        $actions += "Add comprehensive unit tests for complex logic"
    }
    
    # Low test coverage actions
    if ($Factors.LowTestCoverage.Weight -gt 0) {
        $actions += "Implement test-driven development practices"
        $actions += "Add unit tests for critical business logic"
        $actions += "Set up automated testing in CI/CD pipeline"
    }
    
    # Recent changes actions
    if ($Factors.RecentChanges.Weight -gt 0) {
        $actions += "Implement mandatory code review for all changes"
        $actions += "Add regression testing for recently changed areas"
    }
    
    # Multiple authors actions
    if ($Factors.MultipleAuthors.Weight -gt 0) {
        $actions += "Establish clear coding standards and guidelines"
        $actions += "Implement pair programming for critical changes"
    }
    
    # Risk-specific actions
    if ($Risk -eq 'High') {
        $actions += "Implement feature flags for gradual rollout"
        $actions += "Set up enhanced monitoring and alerting"
        $actions += "Plan immediate stabilization sprint"
    }
    
    return $actions
}

function Get-MaintenanceRisk {
    <#
    .SYNOPSIS
    Assesses maintenance risk for a given path
    .DESCRIPTION
    Provides a simplified interface to get maintenance risk level
    .PARAMETER Path
    Path to assess for maintenance risk
    .EXAMPLE
    Get-MaintenanceRisk -Path "C:\Project\Module"
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Path
    )
    
    Write-Verbose "Assessing maintenance risk for $Path"
    
    try {
        $prediction = Get-MaintenancePrediction -Path $Path
        if ($prediction) {
            return @{
                Path = $Path
                RiskLevel = $prediction.RiskLevel
                Score = $prediction.Score
                Timeline = $prediction.Timeline
                TopIssues = $prediction.TopIssues
                Recommendations = $prediction.Recommendations
            }
        }
        
        return @{
            Path = $Path
            RiskLevel = 'Unknown'
            Score = 0
            Timeline = 'Unable to determine'
            TopIssues = @()
            Recommendations = @("Unable to assess - ensure path is valid and accessible")
        }
    }
    catch {
        Write-Error "Failed to get maintenance risk: $_"
        return @{
            Path = $Path
            RiskLevel = 'Unknown'
            Score = 0
            Timeline = 'Error during assessment'
            TopIssues = @()
            Recommendations = @("Assessment failed: $_")
        }
    }
}

function Find-AntiPatterns {
    <#
    .SYNOPSIS
    Detects common anti-patterns in code structure
    .DESCRIPTION
    Identifies problematic code patterns like spaghetti code, copy-paste programming,
    and other structural issues that indicate design problems
    .PARAMETER Graph
    CPG graph to analyze for anti-patterns
    .EXAMPLE
    Find-AntiPatterns -Graph $cpgGraph
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        $Graph
    )
    
    Write-Verbose "Finding anti-patterns in code structure"
    
    try {
        # Check cache first
        $cacheKey = "antipatterns_${Graph.Name}"
        $cached = Get-CacheItem -Key $cacheKey
        if ($cached) {
            Write-Verbose "Returning cached anti-pattern analysis"
            return $cached
        }
        
        $antiPatterns = @()
        
        # 1. Spaghetti Code Detection (high complexity with many dependencies)
        $spaghettiPatterns = Find-SpaghettiCode -Graph $Graph
        $antiPatterns += $spaghettiPatterns
        
        # 2. Copy-Paste Programming Detection
        $copyPastePatterns = Find-CopyPasteProgramming -Graph $Graph
        $antiPatterns += $copyPastePatterns
        
        # 3. Golden Hammer Pattern (overuse of single solution)
        $goldenHammerPatterns = Find-GoldenHammer -Graph $Graph
        $antiPatterns += $goldenHammerPatterns
        
        # 4. Magic Numbers and Strings
        $magicPatterns = Find-MagicConstants -Graph $Graph
        $antiPatterns += $magicPatterns
        
        # 5. Shotgun Surgery (changes scattered across many files)
        $shotgunPatterns = Find-ShotgunSurgery -Graph $Graph
        $antiPatterns += $shotgunPatterns
        
        $result = @{
            AntiPatterns = $antiPatterns
            Summary = @{
                Total = $antiPatterns.Count
                High = ($antiPatterns | Where-Object { $_.Severity -eq 'High' }).Count
                Medium = ($antiPatterns | Where-Object { $_.Severity -eq 'Medium' }).Count
                Low = ($antiPatterns | Where-Object { $_.Severity -eq 'Low' }).Count
                Categories = $antiPatterns | Group-Object Type | ForEach-Object { @{ Type = $_.Name; Count = $_.Count } }
            }
            Recommendations = Get-AntiPatternRecommendations -AntiPatterns $antiPatterns
        }
        
        # Cache the result
        Set-CacheItem -Key $cacheKey -Value $result -TTLMinutes 90
        
        return $result
    }
    catch {
        Write-Error "Failed to find anti-patterns: $_"
        return $null
    }
}

function Find-SpaghettiCode {
    <#
    .SYNOPSIS
    Detects spaghetti code anti-pattern
    .PARAMETER Graph
    CPG graph to analyze
    #>
    [CmdletBinding()]
    param([Parameter(Mandatory)]$Graph)
    
    $patterns = @()
    $functionNodes = Get-CPGNode -Graph $Graph -Type 'Function'
    
    foreach ($func in $functionNodes) {
        $complexity = $func.Properties.CyclomaticComplexity
        if ($complexity -and $complexity -gt 15) {
            $edges = Get-CPGEdge -Graph $Graph -SourceId $func.Id
            $dependencies = $edges | Where-Object { $_.Type -in @('Calls', 'Uses', 'DependsOn') }
            
            if ($dependencies -and $dependencies.Count -gt 20) {
                $patterns += @{
                    Type = 'SpaghettiCode'
                    Target = $func.Name
                    File = $func.Properties.File
                    Severity = if ($complexity -gt 25 -and $dependencies.Count -gt 30) { 'High' } 
                              elseif ($complexity -gt 20 -or $dependencies.Count -gt 25) { 'Medium' } 
                              else { 'Low' }
                    Description = "Complex function ($complexity complexity) with $($dependencies.Count) dependencies"
                    Metrics = @{
                        Complexity = $complexity
                        Dependencies = $dependencies.Count
                        LinesOfCode = $func.Properties.LineCount
                    }
                    Fix = 'Break down into smaller functions, reduce dependencies, simplify control flow'
                }
            }
        }
    }
    
    return $patterns
}

function Find-CopyPasteProgramming {
    <#
    .SYNOPSIS
    Detects copy-paste programming anti-pattern
    .PARAMETER Graph
    CPG graph to analyze
    #>
    [CmdletBinding()]
    param([Parameter(Mandatory)]$Graph)
    
    $patterns = @()
    
    try {
        $duplicates = Get-DuplicationCandidates -Graph $Graph -MinSimilarity 0.85
        
        # Group by similarity level to identify widespread copy-paste
        $highSimilarity = $duplicates | Where-Object { $_.Similarity -gt 0.95 }
        $mediumSimilarity = $duplicates | Where-Object { $_.Similarity -gt 0.85 -and $_.Similarity -le 0.95 }
        
        if ($highSimilarity.Count -gt 3) {
            $patterns += @{
                Type = 'CopyPasteProgramming'
                Target = 'Multiple functions'
                File = 'Various files'
                Severity = 'High'
                Description = "$($highSimilarity.Count) instances of near-identical code (>95% similarity)"
                Metrics = @{
                    HighSimilarityCount = $highSimilarity.Count
                    AverageSimilarity = [Math]::Round(($highSimilarity | Measure-Object Similarity -Average).Average, 2)
                    AffectedFiles = ($highSimilarity | ForEach-Object { @($_.SourceFile, $_.TargetFile) } | Select-Object -Unique).Count
                }
                Fix = 'Extract common functionality into shared utility functions or base classes'
            }
        }
        
        if ($mediumSimilarity.Count -gt 5) {
            $patterns += @{
                Type = 'CopyPasteProgramming'
                Target = 'Multiple functions'
                File = 'Various files'
                Severity = 'Medium'
                Description = "$($mediumSimilarity.Count) instances of similar code structures (85-95% similarity)"
                Metrics = @{
                    MediumSimilarityCount = $mediumSimilarity.Count
                    AverageSimilarity = [Math]::Round(($mediumSimilarity | Measure-Object Similarity -Average).Average, 2)
                    AffectedFiles = ($mediumSimilarity | ForEach-Object { @($_.SourceFile, $_.TargetFile) } | Select-Object -Unique).Count
                }
                Fix = 'Consider refactoring similar structures into reusable components'
            }
        }
    }
    catch {
        Write-Verbose "Could not analyze duplication patterns: $_"
    }
    
    return $patterns
}

function Find-GoldenHammer {
    <#
    .SYNOPSIS
    Detects golden hammer anti-pattern (overuse of single approach)
    .PARAMETER Graph
    CPG graph to analyze
    #>
    [CmdletBinding()]
    param([Parameter(Mandatory)]$Graph)
    
    $patterns = @()
    
    try {
        # Look for overuse of specific patterns or libraries
        $functionNodes = Get-CPGNode -Graph $Graph -Type 'Function'
        $callPatterns = @{}
        
        foreach ($func in $functionNodes) {
            $calls = Get-CPGEdge -Graph $Graph -SourceId $func.Id -Type 'Calls'
            foreach ($call in $calls) {
                $targetNode = $Graph.Nodes[$call.To]
                if ($targetNode -and $targetNode.Name) {
                    $pattern = $targetNode.Name -replace '-.*$', ''  # Get verb part
                    if (-not $callPatterns.ContainsKey($pattern)) {
                        $callPatterns[$pattern] = 0
                    }
                    $callPatterns[$pattern]++
                }
            }
        }
        
        # Identify overused patterns
        $totalCalls = ($callPatterns.Values | Measure-Object -Sum).Sum
        if ($totalCalls -gt 0) {
            $dominant = $callPatterns.GetEnumerator() | Sort-Object Value -Descending | Select-Object -First 3
            
            foreach ($pattern in $dominant) {
                $percentage = ($pattern.Value / $totalCalls) * 100
                if ($percentage -gt 40) {  # Single pattern used >40% of the time
                    $patterns += @{
                        Type = 'GoldenHammer'
                        Target = $pattern.Name
                        File = 'Multiple files'
                        Severity = if ($percentage -gt 60) { 'High' } elseif ($percentage -gt 50) { 'Medium' } else { 'Low' }
                        Description = "Overuse of '$($pattern.Name)' pattern ($([Math]::Round($percentage, 1))% of all function calls)"
                        Metrics = @{
                            UsagePercentage = [Math]::Round($percentage, 1)
                            CallCount = $pattern.Value
                            TotalCalls = $totalCalls
                        }
                        Fix = 'Diversify approaches, consider alternative patterns and solutions'
                    }
                }
            }
        }
    }
    catch {
        Write-Verbose "Could not analyze call patterns: $_"
    }
    
    return $patterns
}

function Find-MagicConstants {
    <#
    .SYNOPSIS
    Detects magic numbers and hardcoded strings
    .PARAMETER Graph
    CPG graph to analyze
    #>
    [CmdletBinding()]
    param([Parameter(Mandatory)]$Graph)
    
    $patterns = @()
    
    # This is a simplified implementation - in a real scenario,
    # we'd need to analyze the AST more deeply for literal values
    $functionNodes = Get-CPGNode -Graph $Graph -Type 'Function'
    $magicCount = 0
    
    foreach ($func in $functionNodes) {
        # Estimate magic constants based on function complexity and parameters
        if ($func.Properties.LineCount -and $func.Properties.LineCount -gt 20) {
            # Heuristic: assume 1 magic constant per 10 lines in longer functions
            $estimatedMagic = [Math]::Floor($func.Properties.LineCount / 10)
            $magicCount += $estimatedMagic
        }
    }
    
    if ($magicCount -gt 10) {
        $patterns += @{
            Type = 'MagicConstants'
            Target = 'Various functions'
            File = 'Multiple files'
            Severity = if ($magicCount -gt 30) { 'High' } elseif ($magicCount -gt 20) { 'Medium' } else { 'Low' }
            Description = "Estimated $magicCount magic constants/hardcoded values"
            Metrics = @{
                EstimatedCount = $magicCount
                FunctionsAnalyzed = $functionNodes.Count
            }
            Fix = 'Extract magic numbers to named constants, use configuration files for hardcoded strings'
        }
    }
    
    return $patterns
}

function Find-ShotgunSurgery {
    <#
    .SYNOPSIS
    Detects shotgun surgery anti-pattern (changes scattered across many files)
    .PARAMETER Graph
    CPG graph to analyze
    #>
    [CmdletBinding()]
    param([Parameter(Mandatory)]$Graph)
    
    $patterns = @()
    
    try {
        # Look for highly coupled modules that would require coordinated changes
        $moduleNodes = Get-CPGNode -Graph $Graph -Type 'Module'
        
        foreach ($module in $moduleNodes) {
            $couplingIssues = Get-CouplingIssues -Graph $Graph -Threshold 5
            $highCoupling = $couplingIssues | Where-Object { $_.Module -eq $module.Name -and $_.CouplingScore -gt 12 }
            
            if ($highCoupling) {
                $patterns += @{
                    Type = 'ShotgunSurgery'
                    Target = $module.Name
                    File = $module.Properties.File
                    Severity = if ($highCoupling.CouplingScore -gt 20) { 'High' } 
                              elseif ($highCoupling.CouplingScore -gt 15) { 'Medium' } 
                              else { 'Low' }
                    Description = "Module requires changes across $($highCoupling.ExternalDependencies) dependencies when modified"
                    Metrics = @{
                        CouplingScore = $highCoupling.CouplingScore
                        ExternalDependencies = $highCoupling.ExternalDependencies
                        ExternalCalls = $highCoupling.ExternalCalls
                    }
                    Fix = 'Reduce coupling through dependency inversion, facade patterns, or architectural refactoring'
                }
            }
        }
    }
    catch {
        Write-Verbose "Could not analyze coupling for shotgun surgery: $_"
    }
    
    return $patterns
}

function Get-AntiPatternRecommendations {
    <#
    .SYNOPSIS
    Generates recommendations based on detected anti-patterns
    .PARAMETER AntiPatterns
    Array of detected anti-patterns
    #>
    [CmdletBinding()]
    param([array]$AntiPatterns)
    
    $recommendations = @()
    
    if ($AntiPatterns.Count -eq 0) {
        return @("No significant anti-patterns detected. Continue following good design practices.")
    }
    
    $patternTypes = $AntiPatterns | Group-Object Type
    
    foreach ($group in $patternTypes) {
        switch ($group.Name) {
            'SpaghettiCode' {
                $recommendations += "Address spaghetti code ($($group.Count) instances) through systematic refactoring using Extract Method and Simplify Conditional patterns."
            }
            'CopyPasteProgramming' {
                $recommendations += "Eliminate code duplication ($($group.Count) instances) by extracting common functionality into shared utilities."
            }
            'GoldenHammer' {
                $recommendations += "Diversify solution approaches ($($group.Count) instances) by exploring alternative patterns and technologies."
            }
            'MagicConstants' {
                $recommendations += "Replace magic constants ($($group.Count) instances) with named constants and configuration parameters."
            }
            'ShotgunSurgery' {
                $recommendations += "Reduce coupling ($($group.Count) instances) through architectural refactoring and dependency management."
            }
        }
    }
    
    # Priority recommendations
    $highSeverity = $AntiPatterns | Where-Object { $_.Severity -eq 'High' }
    if ($highSeverity.Count -gt 0) {
        $recommendations += "PRIORITY: Address $($highSeverity.Count) high-severity anti-patterns immediately to prevent architectural degradation."
    }
    
    return $recommendations
}

function Get-DesignFlaws {
    <#
    .SYNOPSIS
    Detects architectural and design flaws
    .DESCRIPTION
    Identifies circular dependencies, tight coupling, and other structural problems
    .PARAMETER Graph
    CPG graph to analyze for design flaws
    .EXAMPLE
    Get-DesignFlaws -Graph $cpgGraph
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        $Graph
    )
    
    Write-Verbose "Detecting design flaws in architecture"
    
    try {
        # Check cache first
        $cacheKey = "design_flaws_${Graph.Name}"
        $cached = Get-CacheItem -Key $cacheKey
        if ($cached) {
            Write-Verbose "Returning cached design flaw analysis"
            return $cached
        }
        
        $flaws = @()
        
        # 1. Circular Dependencies
        $circularFlaws = Find-CircularDependencies -Graph $Graph
        $flaws += $circularFlaws
        
        # 2. Interface Segregation Violations
        $interfaceFlaws = Find-InterfaceViolations -Graph $Graph
        $flaws += $interfaceFlaws
        
        # 3. Dependency Inversion Violations
        $dependencyFlaws = Find-DependencyViolations -Graph $Graph
        $flaws += $dependencyFlaws
        
        # 4. Single Responsibility Violations (already covered in god classes)
        $responsibilityFlaws = Find-ResponsibilityViolations -Graph $Graph
        $flaws += $responsibilityFlaws
        
        $result = @{
            DesignFlaws = $flaws
            Summary = @{
                Total = $flaws.Count
                Critical = ($flaws | Where-Object { $_.Severity -eq 'Critical' }).Count
                High = ($flaws | Where-Object { $_.Severity -eq 'High' }).Count
                Medium = ($flaws | Where-Object { $_.Severity -eq 'Medium' }).Count
                Categories = $flaws | Group-Object Type | ForEach-Object { @{ Type = $_.Name; Count = $_.Count } }
            }
            ArchitecturalHealth = Get-ArchitecturalHealthScore -Flaws $flaws
            Recommendations = Get-DesignFlawRecommendations -Flaws $flaws
        }
        
        # Cache the result
        Set-CacheItem -Key $cacheKey -Value $result -TTLMinutes 120
        
        return $result
    }
    catch {
        Write-Error "Failed to detect design flaws: $_"
        return $null
    }
}

function Find-CircularDependencies {
    <#
    .SYNOPSIS
    Detects circular dependencies between modules
    .PARAMETER Graph
    CPG graph to analyze
    #>
    [CmdletBinding()]
    param([Parameter(Mandatory)]$Graph)
    
    $flaws = @()
    $moduleNodes = Get-CPGNode -Graph $Graph -Type 'Module'
    
    foreach ($module in $moduleNodes) {
        try {
            $visited = @{}
            $recursionStack = @{}
            
            if (Find-CircularDependencyDFS -Graph $Graph -ModuleId $module.Id -Visited $visited -RecursionStack $recursionStack) {
                $flaws += @{
                    Type = 'CircularDependency'
                    Target = $module.Name
                    File = $module.Properties.File
                    Severity = 'High'
                    Description = 'Module participates in circular dependency chain'
                    Impact = 'High coupling, difficult testing, build issues'
                    Fix = 'Break dependency cycle using dependency inversion or interface extraction'
                }
            }
        }
        catch {
            Write-Verbose "Error checking circular dependency for $($module.Name): $_"
        }
    }
    
    return $flaws
}

function Find-CircularDependencyDFS {
    <#
    .SYNOPSIS
    Depth-first search for circular dependencies
    #>
    [CmdletBinding()]
    param($Graph, $ModuleId, $Visited, $RecursionStack)
    
    $visited[$ModuleId] = $true
    $recursionStack[$ModuleId] = $true
    
    try {
        $dependencies = Get-CPGEdge -Graph $Graph -SourceId $ModuleId -Type 'DependsOn'
        
        foreach ($dep in $dependencies) {
            $targetId = $dep.To
            
            if (-not $visited.ContainsKey($targetId)) {
                if (Find-CircularDependencyDFS -Graph $Graph -ModuleId $targetId -Visited $visited -RecursionStack $recursionStack) {
                    return $true
                }
            }
            elseif ($recursionStack.ContainsKey($targetId) -and $recursionStack[$targetId]) {
                return $true  # Circular dependency found
            }
        }
    }
    catch {
        Write-Verbose "Error in DFS for module ${ModuleId}: $($_.Exception.Message)"
    }
    
    $recursionStack[$ModuleId] = $false
    return $false
}

function Find-InterfaceViolations {
    <#
    .SYNOPSIS
    Detects interface segregation principle violations
    .PARAMETER Graph
    CPG graph to analyze
    #>
    [CmdletBinding()]
    param([Parameter(Mandatory)]$Graph)
    
    $flaws = @()
    
    # Look for large interfaces or classes with too many public methods
    $classNodes = Get-CPGNode -Graph $Graph -Type 'Class'
    
    foreach ($class in $classNodes) {
        try {
            $publicMethods = Get-CPGEdge -Graph $Graph -SourceId $class.Id -Type 'Contains' |
                Where-Object { 
                    $method = $Graph.Nodes[$_.To]
                    $method.Type -eq 'Function' -and $method.Properties.Visibility -eq 'Public'
                }
            
            if ($publicMethods -and $publicMethods.Count -gt 15) {
                $flaws += @{
                    Type = 'InterfaceSegregationViolation'
                    Target = $class.Name
                    File = $class.Properties.File
                    Severity = if ($publicMethods.Count -gt 25) { 'High' } else { 'Medium' }
                    Description = "Class exposes $($publicMethods.Count) public methods, violating interface segregation"
                    Impact = 'Clients forced to depend on methods they do not use'
                    Fix = 'Split into smaller, focused interfaces or use role interfaces'
                    Metrics = @{
                        PublicMethodCount = $publicMethods.Count
                        Threshold = 15
                    }
                }
            }
        }
        catch {
            Write-Verbose "Error analyzing interface for $($class.Name): $_"
        }
    }
    
    return $flaws
}

function Find-DependencyViolations {
    <#
    .SYNOPSIS
    Detects dependency inversion principle violations
    .PARAMETER Graph
    CPG graph to analyze
    #>
    [CmdletBinding()]
    param([Parameter(Mandatory)]$Graph)
    
    $flaws = @()
    
    # Look for high-level modules depending on low-level modules
    $moduleNodes = Get-CPGNode -Graph $Graph -Type 'Module'
    
    foreach ($module in $moduleNodes) {
        try {
            $dependencies = Get-CPGEdge -Graph $Graph -SourceId $module.Id -Type 'DependsOn'
            $concreteDeps = 0
            $totalDeps = $dependencies.Count
            
            foreach ($dep in $dependencies) {
                $targetModule = $Graph.Nodes[$dep.To]
                # Heuristic: modules with "Impl", "Concrete", or specific tech names are low-level
                if ($targetModule.Name -match '(Impl|Concrete|File|Database|Http|Sql)') {
                    $concreteDeps++
                }
            }
            
            if ($totalDeps -gt 0 -and ($concreteDeps / $totalDeps) -gt 0.6) {
                $flaws += @{
                    Type = 'DependencyInversionViolation'
                    Target = $module.Name
                    File = $module.Properties.File
                    Severity = 'Medium'
                    Description = "Module depends heavily on concrete implementations ($concreteDeps/$totalDeps dependencies)"
                    Impact = 'Tight coupling, difficult testing, reduced flexibility'
                    Fix = 'Introduce abstractions/interfaces, use dependency injection'
                    Metrics = @{
                        ConcreteDependencies = $concreteDeps
                        TotalDependencies = $totalDeps
                        ConcreteRatio = [Math]::Round(($concreteDeps / $totalDeps) * 100, 1)
                    }
                }
            }
        }
        catch {
            Write-Verbose "Error analyzing dependencies for $($module.Name): $_"
        }
    }
    
    return $flaws
}

function Find-ResponsibilityViolations {
    <#
    .SYNOPSIS
    Detects single responsibility principle violations
    .PARAMETER Graph
    CPG graph to analyze
    #>
    [CmdletBinding()]
    param([Parameter(Mandatory)]$Graph)
    
    $flaws = @()
    
    # Leverage existing god class detection
    try {
        $godClasses = Find-GodClasses -Graph $Graph -MethodThreshold 15
        
        foreach ($god in $godClasses) {
            if ($god.Responsibilities.Count -gt 2) {
                $flaws += @{
                    Type = 'SingleResponsibilityViolation'
                    Target = $god.Name
                    File = $god.File
                    Severity = $god.Severity
                    Description = "Class has multiple responsibilities: $($god.Responsibilities -join ', ')"
                    Impact = 'High coupling, difficult maintenance, unclear purpose'
                    Fix = 'Split class based on identified responsibilities'
                    Metrics = @{
                        ResponsibilityCount = $god.Responsibilities.Count
                        MethodCount = $god.MethodCount
                        PropertyCount = $god.PropertyCount
                    }
                }
            }
        }
    }
    catch {
        Write-Verbose "Error finding responsibility violations: $_"
    }
    
    return $flaws
}

function Get-ArchitecturalHealthScore {
    <#
    .SYNOPSIS
    Calculates architectural health score based on design flaws
    .PARAMETER Flaws
    Array of detected design flaws
    #>
    [CmdletBinding()]
    param([array]$Flaws)
    
    if ($Flaws.Count -eq 0) {
        return @{
            Score = 95
            Grade = 'A'
            Description = 'Excellent architectural health'
        }
    }
    
    # Calculate penalty based on flaw severity
    $penalty = 0
    foreach ($flaw in $Flaws) {
        $penalty += switch ($flaw.Severity) {
            'Critical' { 15 }
            'High' { 10 }
            'Medium' { 5 }
            'Low' { 2 }
            default { 3 }
        }
    }
    
    $score = [Math]::Max(0, 100 - $penalty)
    
    $grade = if ($score -ge 90) { 'A' }
            elseif ($score -ge 80) { 'B' }
            elseif ($score -ge 70) { 'C' }
            elseif ($score -ge 60) { 'D' }
            else { 'F' }
    
    $description = switch ($grade) {
        'A' { 'Excellent architectural health' }
        'B' { 'Good architectural health with minor issues' }
        'C' { 'Fair architectural health, improvement needed' }
        'D' { 'Poor architectural health, significant issues' }
        'F' { 'Critical architectural issues requiring immediate attention' }
    }
    
    return @{
        Score = $score
        Grade = $grade
        Description = $description
        FlawCount = $Flaws.Count
        PenaltyPoints = $penalty
    }
}

function Get-DesignFlawRecommendations {
    <#
    .SYNOPSIS
    Generates recommendations based on detected design flaws
    .PARAMETER Flaws
    Array of detected design flaws
    #>
    [CmdletBinding()]
    param([array]$Flaws)
    
    $recommendations = @()
    
    if ($Flaws.Count -eq 0) {
        return @("Architecture appears healthy. Continue following SOLID principles and design patterns.")
    }
    
    $flawTypes = $Flaws | Group-Object Type
    
    foreach ($group in $flawTypes) {
        switch ($group.Name) {
            'CircularDependency' {
                $recommendations += "CRITICAL: Break circular dependencies ($($group.Count) found) using dependency inversion or interface extraction."
            }
            'InterfaceSegregationViolation' {
                $recommendations += "Split large interfaces ($($group.Count) violations) into smaller, focused role-based interfaces."
            }
            'DependencyInversionViolation' {
                $recommendations += "Introduce abstractions ($($group.Count) violations) to depend on interfaces rather than concrete implementations."
            }
            'SingleResponsibilityViolation' {
                $recommendations += "Refactor classes with multiple responsibilities ($($group.Count) violations) into focused, single-purpose components."
            }
        }
    }
    
    # Overall architectural recommendations
    $criticalFlaws = $Flaws | Where-Object { $_.Severity -eq 'Critical' }
    if ($criticalFlaws.Count -gt 0) {
        $recommendations += "URGENT: Address $($criticalFlaws.Count) critical architectural flaws before proceeding with new features."
    }
    
    $recommendations += "Consider implementing architectural fitness functions to prevent future design degradation."
    $recommendations += "Establish regular architecture reviews and design decision documentation (ADRs)."
    
    return $recommendations
}

# Export functions
Export-ModuleMember -Function @(
    'Predict-BugProbability',
    'Get-MaintenanceRisk', 
    'Find-AntiPatterns',
    'Get-DesignFlaws'
)

Write-Verbose "RiskAssessment component loaded successfully"
# SIG # Begin signature block
# MIIFzgYJKoZIhvcNAQcCoIIFvzCCBbsCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCDpF0HPamP4hdkl
# 1J6O1jJlycfPToLvUMpEOi6iuPCMUqCCAzAwggMsMIICFKADAgECAhB1HRbZIqgr
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
# MAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIOqJXQBbu3L2OSWSvCR/lrtX
# UPDrD9wqJ979jDW3o5MIMA0GCSqGSIb3DQEBAQUABIIBAFj01RT7OGRXKz1VNzN5
# qOPQp9c/htMRsO6GMrUZIc1a2xGKtwEK6fdiCVIBgAYSmhOhsJo2j+e1i3xhFMVm
# RswWBs6m+7j3VGQegHq62p+0yXL1NtAaKhpXw20/4opwWuBYESlbcI/9Io2OsW4K
# W+ZO/jv6ZAAmw/1FmxpJV9BoJT+kpAVTZk+RQGKOGAHjz5OyQ+s/OWU/2yWVe93S
# r15EgczgEjAJSSYhFJ6MgeO7GaJ7n1kcq1HinXMkH8q0BfxuEpXev1WaSKk/b030
# tl49JbBXRamb02TTAVMKq4+Tarr7IcPrX9f76R+iVbIJe7yrONa67qwlb9rsZIim
# Pw0=
# SIG # End signature block
