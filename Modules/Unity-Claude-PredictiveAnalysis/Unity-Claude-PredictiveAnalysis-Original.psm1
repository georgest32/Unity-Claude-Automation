# Unity-Claude-PredictiveAnalysis.psm1
# Phase 3 Day 3-4: Advanced Intelligence Features - Predictive Analysis
# Implements trend analysis, maintenance prediction, refactoring detection, and improvement roadmaps

# Dependencies handled by test scripts - removed using statements to avoid path issues

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

# Module-level cache for predictions
$script:PredictionCache = $null
$script:MetricsHistory = @{}
$script:PredictionModels = @{}

#region Initialization

function Initialize-PredictiveCache {
    [CmdletBinding()]
    param(
        [int]$MaxSizeMB = 100,
        [int]$TTLMinutes = 60
    )
    
    Write-Verbose "Initializing predictive analysis cache..."
    
    try {
        $script:PredictionCache = New-CacheManager -MaxSize $MaxSizeMB
        
        # Initialize metric history storage
        $script:MetricsHistory = @{
            CodeChurn = @{}
            Complexity = @{}
            Coverage = @{}
            BugReports = @{}
            LastUpdated = Get-Date
        }
        
        # Initialize prediction models
        $script:PredictionModels = @{
            MaintenanceModel = @{
                Weights = @{
                    Complexity = 0.3
                    Churn = 0.25
                    Coverage = 0.15
                    Age = 0.1
                    Dependencies = 0.2
                }
            }
            SmellModel = @{
                Thresholds = @{
                    MethodLength = 50
                    ClassSize = 500
                    CyclomaticComplexity = 10
                    CouplingScore = 7
                    DuplicationRatio = 0.05
                }
            }
        }
        
        Write-Verbose "Predictive cache initialized successfully"
        return $true
    }
    catch {
        Write-Error "Failed to initialize predictive cache: $_"
        return $false
    }
}

#endregion Initialization

#region Trend Analysis

function Get-CodeEvolutionTrend {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Path,
        
        [int]$DaysBack = 30,
        
        [ValidateSet('Daily', 'Weekly', 'Monthly')]
        [string]$Granularity = 'Weekly'
    )
    
    Write-Verbose "Analyzing code evolution trend for $Path"
    
    try {
        # Check cache first
        $cacheKey = "evolution_${Path}_${DaysBack}_${Granularity}"
        $cached = Get-CacheItem -CacheManager $script:PredictionCache -Key $cacheKey
        if ($cached) {
            Write-Verbose "Returning cached evolution trend"
            return $cached
        }
        
        # Get git history
        $startDate = (Get-Date).AddDays(-$DaysBack)
        $gitLog = git log --since="$($startDate.ToString('yyyy-MM-dd'))" --pretty=format:"%H|%ad|%an" --date=short --numstat -- $Path 2>$null
        
        if (-not $gitLog) {
            Write-Warning "No git history found for $Path"
            return $null
        }
        
        # Parse commits and build trend data
        $commits = @()
        $currentCommit = $null
        
        foreach ($line in $gitLog) {
            if ($line -match '^([a-f0-9]{40})\|(\d{4}-\d{2}-\d{2})\|(.+)$') {
                if ($currentCommit) {
                    $commits += $currentCommit
                }
                $currentCommit = @{
                    Hash = $Matches[1]
                    Date = [DateTime]::Parse($Matches[2])
                    Author = $Matches[3]
                    LinesAdded = 0
                    LinesDeleted = 0
                    FilesChanged = 0
                }
            }
            elseif ($line -match '^(\d+)\s+(\d+)\s+(.+)$') {
                # Numstat line: additions deletions filename
                $currentCommit.LinesAdded += [int]$Matches[1]
                $currentCommit.LinesDeleted += [int]$Matches[2]
                $currentCommit.FilesChanged++
            }
        }
        
        if ($currentCommit) {
            $commits += $currentCommit
        }
        
        # Group by granularity
        $grouped = switch ($Granularity) {
            'Daily' {
                $commits | Group-Object { $_.Date.ToString('yyyy-MM-dd') }
            }
            'Weekly' {
                $commits | Group-Object { 
                    $cal = [System.Globalization.CultureInfo]::CurrentCulture.Calendar
                    $week = $cal.GetWeekOfYear($_.Date, [System.Globalization.CalendarWeekRule]::FirstDay, [DayOfWeek]::Monday)
                    "$($_.Date.Year)-W$($week.ToString('00'))"
                }
            }
            'Monthly' {
                $commits | Group-Object { $_.Date.ToString('yyyy-MM') }
            }
        }
        
        # Build trend analysis
        $trend = @{
            Path = $Path
            Period = "$DaysBack days"
            Granularity = $Granularity
            TotalCommits = $commits.Count
            UniqueAuthors = ($commits | Select-Object -ExpandProperty Author -Unique).Count
            TotalLinesAdded = ($commits | Measure-Object -Property LinesAdded -Sum).Sum
            TotalLinesDeleted = ($commits | Measure-Object -Property LinesDeleted -Sum).Sum
            NetChange = ($commits | Measure-Object -Property LinesAdded -Sum).Sum - ($commits | Measure-Object -Property LinesDeleted -Sum).Sum
            DataPoints = @()
        }
        
        foreach ($group in $grouped) {
            $groupCommits = $group.Group
            $trend.DataPoints += @{
                Period = $group.Name
                Commits = $groupCommits.Count
                LinesAdded = ($groupCommits | Measure-Object -Property LinesAdded -Sum).Sum
                LinesDeleted = ($groupCommits | Measure-Object -Property LinesDeleted -Sum).Sum
                NetChange = ($groupCommits | Measure-Object -Property LinesAdded -Sum).Sum - ($groupCommits | Measure-Object -Property LinesDeleted -Sum).Sum
                Authors = ($groupCommits | Select-Object -ExpandProperty Author -Unique).Count
            }
        }
        
        # Calculate trend indicators
        if ($trend.DataPoints.Count -ge 2) {
            $firstHalf = $trend.DataPoints[0..([Math]::Floor($trend.DataPoints.Count / 2) - 1)]
            $secondHalf = $trend.DataPoints[[Math]::Floor($trend.DataPoints.Count / 2)..($trend.DataPoints.Count - 1)]
            
            $firstHalfChurn = ($firstHalf | Measure-Object -Property NetChange -Sum).Sum
            $secondHalfChurn = ($secondHalf | Measure-Object -Property NetChange -Sum).Sum
            
            $trend.TrendDirection = if ($secondHalfChurn -gt $firstHalfChurn) { 'Increasing' } 
                                   elseif ($secondHalfChurn -lt $firstHalfChurn) { 'Decreasing' } 
                                   else { 'Stable' }
            
            $trend.Volatility = [Math]::Round(($trend.DataPoints | ForEach-Object { [Math]::Abs($_.NetChange) } | Measure-Object -Average).Average, 2)
        }
        
        # Cache the result
        Set-CacheItem -CacheManager $script:PredictionCache -Key $cacheKey -Value $trend -TTLSeconds (60 * 60)
        
        return $trend
    }
    catch {
        Write-Error "Failed to analyze code evolution trend: $_"
        return $null
    }
}

function Measure-CodeChurn {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Path,
        
        [int]$DaysBack = 30
    )
    
    Write-Verbose "Measuring code churn for $Path"
    
    try {
        $evolution = Get-CodeEvolutionTrend -Path $Path -DaysBack $DaysBack -Granularity Daily
        
        if (-not $evolution) {
            return $null
        }
        
        $churn = @{
            Path = $Path
            Period = "$DaysBack days"
            TotalChurn = $evolution.TotalLinesAdded + $evolution.TotalLinesDeleted
            ChurnRate = [Math]::Round(($evolution.TotalLinesAdded + $evolution.TotalLinesDeleted) / $DaysBack, 2)
            AdditionRate = [Math]::Round($evolution.TotalLinesAdded / $DaysBack, 2)
            DeletionRate = [Math]::Round($evolution.TotalLinesDeleted / $DaysBack, 2)
            NetGrowthRate = [Math]::Round($evolution.NetChange / $DaysBack, 2)
            ChurnRatio = if ($evolution.TotalLinesAdded -gt 0) {
                [Math]::Round($evolution.TotalLinesDeleted / $evolution.TotalLinesAdded, 2)
            } else { 0 }
            Risk = 'Low'
        }
        
        # Determine risk level based on churn rate
        if ($churn.ChurnRate -gt 100) {
            $churn.Risk = 'Critical'
        } elseif ($churn.ChurnRate -gt 50) {
            $churn.Risk = 'High'
        } elseif ($churn.ChurnRate -gt 20) {
            $churn.Risk = 'Medium'
        }
        
        # Store in history
        $script:MetricsHistory.CodeChurn[$Path] = $churn
        
        return $churn
    }
    catch {
        Write-Error "Failed to measure code churn: $_"
        return $null
    }
}

function Get-HotspotAnalysis {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Path,
        
        [int]$TopN = 10,
        
        [int]$DaysBack = 90
    )
    
    Write-Verbose "Analyzing hotspots in $Path"
    
    try {
        # Get file change frequency
        $startDate = (Get-Date).AddDays(-$DaysBack)
        $fileChanges = git log --since="$($startDate.ToString('yyyy-MM-dd'))" --name-only --pretty=format: -- "$Path" 2>$null | 
            Where-Object { $_ -ne '' } |
            Group-Object |
            Sort-Object Count -Descending |
            Select-Object -First $TopN
        
        $hotspots = @()
        
        foreach ($file in $fileChanges) {
            # Get file metrics
            $filePath = Join-Path $Path $file.Name
            
            if (Test-Path $filePath) {
                $content = Get-Content $filePath -Raw
                $lines = ($content -split "`n").Count
                
                # Get complexity if it's a code file
                $complexity = 0
                if ($filePath -match '\.(ps1|psm1|py|js|cs)$') {
                    # Simple complexity estimation
                    $complexity = ([regex]::Matches($content, '\b(if|while|for|foreach|switch|catch)\b')).Count
                }
                
                $hotspots += @{
                    File = $file.Name
                    ChangeCount = $file.Count
                    Lines = $lines
                    Complexity = $complexity
                    Risk = if ($file.Count -gt 20 -and $complexity -gt 10) { 'High' }
                          elseif ($file.Count -gt 10 -or $complexity -gt 5) { 'Medium' }
                          else { 'Low' }
                    Recommendation = if ($file.Count -gt 20) {
                        "High change frequency indicates potential design issues. Consider refactoring."
                    } elseif ($complexity -gt 10) {
                        "High complexity combined with changes suggests maintenance burden."
                    } else {
                        "Monitor for increasing change frequency."
                    }
                }
            }
        }
        
        return @{
            Path = $Path
            Period = "$DaysBack days"
            TopFiles = $TopN
            Hotspots = $hotspots
            Summary = @{
                CriticalFiles = ($hotspots | Where-Object { $_.Risk -eq 'High' }).Count
                TotalChanges = ($hotspots | Measure-Object -Property ChangeCount -Sum).Sum
                AverageComplexity = [Math]::Round(($hotspots | Measure-Object -Property Complexity -Average).Average, 2)
            }
        }
    }
    catch {
        Write-Error "Failed to analyze hotspots: $_"
        return $null
    }
}

#endregion Trend Analysis

#region Maintenance Prediction

function Get-MaintenancePrediction {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Path,
        
        $Graph = $null,
        
        [switch]$IncludeLLMInsights
    )
    
    Write-Verbose "Generating maintenance prediction for $Path"
    
    try {
        # Gather metrics
        $metrics = @{
            Churn = Measure-CodeChurn -Path $Path -DaysBack 30
            Hotspots = Get-HotspotAnalysis -Path $Path -TopN 5 -DaysBack 90
            Complexity = $null
            Coverage = $null
            Dependencies = $null
        }
        
        # Get complexity from CPG if available
        if ($Graph) {
            $complexityMetrics = Get-CodeComplexityMetrics -Graph $Graph
            $metrics.Complexity = $complexityMetrics
        }
        
        # Calculate maintenance score (0-100, higher = more maintenance needed)
        $weights = $script:PredictionModels.MaintenanceModel.Weights
        $score = 0
        
        # Churn factor
        if ($metrics.Churn) {
            $churnScore = [Math]::Min($metrics.Churn.ChurnRate / 2, 50)  # Max 50 points
            $score += $churnScore * $weights.Churn
        }
        
        # Complexity factor
        if ($metrics.Complexity) {
            $complexityScore = [Math]::Min($metrics.Complexity.AverageCyclomaticComplexity * 5, 50)
            $score += $complexityScore * $weights.Complexity
        }
        
        # Hotspot factor
        if ($metrics.Hotspots) {
            $hotspotScore = $metrics.Hotspots.Summary.CriticalFiles * 10
            $score += [Math]::Min($hotspotScore, 50) * 0.2
        }
        
        # Normalize score to 0-100
        $score = [Math]::Min([Math]::Round($score, 0), 100)
        
        # Determine risk level and timeline
        $riskLevel = switch ($score) {
            {$_ -ge 75} { 'Critical'; break }
            {$_ -ge 50} { 'High'; break }
            {$_ -ge 25} { 'Medium'; break }
            default { 'Low' }
        }
        
        $maintenanceTimeline = switch ($riskLevel) {
            'Critical' { 'Immediate (within 1 week)' }
            'High' { 'Short-term (within 1 month)' }
            'Medium' { 'Medium-term (within 3 months)' }
            'Low' { 'Long-term (within 6 months)' }
        }
        
        $prediction = @{
            Path = $Path
            Score = $score
            RiskLevel = $riskLevel
            Timeline = $maintenanceTimeline
            Metrics = $metrics
            TopIssues = @()
            Recommendations = @()
        }
        
        # Identify top issues
        if ($metrics.Churn -and $metrics.Churn.Risk -in @('High', 'Critical')) {
            $prediction.TopIssues += "High code churn rate ($($metrics.Churn.ChurnRate) lines/day)"
        }
        
        if ($metrics.Complexity -and $metrics.Complexity.AverageCyclomaticComplexity -gt 10) {
            $prediction.TopIssues += "High complexity (avg: $($metrics.Complexity.AverageCyclomaticComplexity))"
        }
        
        if ($metrics.Hotspots -and $metrics.Hotspots.Summary.CriticalFiles -gt 0) {
            $prediction.TopIssues += "$($metrics.Hotspots.Summary.CriticalFiles) critical hotspot files"
        }
        
        # Generate recommendations
        if ($score -ge 75) {
            $prediction.Recommendations += "Immediate refactoring required to reduce technical debt"
            $prediction.Recommendations += "Consider breaking down complex modules"
            $prediction.Recommendations += "Implement comprehensive testing before changes"
        } elseif ($score -ge 50) {
            $prediction.Recommendations += "Plan refactoring sprint in next iteration"
            $prediction.Recommendations += "Increase test coverage for high-risk areas"
            $prediction.Recommendations += "Review and simplify complex functions"
        } elseif ($score -ge 25) {
            $prediction.Recommendations += "Monitor trends and plan gradual improvements"
            $prediction.Recommendations += "Document complex areas for future maintenance"
        } else {
            $prediction.Recommendations += "Continue regular maintenance practices"
            $prediction.Recommendations += "Monitor for increasing complexity"
        }
        
        # Add LLM insights if requested
        if ($IncludeLLMInsights) {
            $llmPrompt = @"
Based on these maintenance metrics for ${Path}:
- Maintenance Score: $score/100
- Risk Level: $riskLevel
- Code Churn Rate: $($metrics.Churn.ChurnRate) lines/day
- Critical Hotspots: $($metrics.Hotspots.Summary.CriticalFiles)

Provide 3 specific, actionable maintenance recommendations.
"@
            
            try {
                $llmResponse = Invoke-OllamaGenerate -Prompt $llmPrompt -MaxTokens 500
                if ($llmResponse.Success) {
                    $prediction.LLMInsights = $llmResponse.Response
                }
            }
            catch {
                Write-Warning "Could not get LLM insights: $_"
            }
        }
        
        return $prediction
    }
    catch {
        Write-Error "Failed to generate maintenance prediction: $_"
        return $null
    }
}

function Calculate-TechnicalDebt {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Path,
        
        $Graph = $null
    )
    
    Write-Verbose "Calculating technical debt for $Path"
    
    try {
        # Initialize debt calculation
        $debt = @{
            Path = $Path
            TotalHours = 0
            Categories = @{}
            Items = @()
            EstimatedCost = 0
        }
        
        # Get various metrics
        $obsolescence = if ($Graph) { Find-UnreachableCode -Graph $Graph } else { $null }
        $duplication = if ($Graph) { Test-CodeRedundancy -Graph $Graph } else { $null }
        $complexity = if ($Graph) { Get-CodeComplexityMetrics -Graph $Graph } else { $null }
        
        # Calculate debt from obsolete code
        if ($obsolescence) {
            $obsoleteHours = $obsolescence.Count * 2  # 2 hours per obsolete item average
            $debt.Categories['ObsoleteCode'] = $obsoleteHours
            $debt.TotalHours += $obsoleteHours
            
            foreach ($item in $obsolescence) {
                $debt.Items += @{
                    Type = 'ObsoleteCode'
                    Description = "Unreachable code in $($item.Name)"
                    EstimatedHours = 2
                    Priority = 'Medium'
                }
            }
        }
        
        # Calculate debt from duplication
        if ($duplication -and $duplication.DuplicationPercentage -gt 5) {
            $dupHours = [Math]::Round($duplication.DuplicationPercentage * 10, 0)
            $debt.Categories['CodeDuplication'] = $dupHours
            $debt.TotalHours += $dupHours
            
            $debt.Items += @{
                Type = 'CodeDuplication'
                Description = "$($duplication.DuplicationPercentage)% code duplication"
                EstimatedHours = $dupHours
                Priority = 'High'
            }
        }
        
        # Calculate debt from complexity
        if ($complexity -and $complexity.AverageCyclomaticComplexity -gt 10) {
            $complexHours = [Math]::Round(($complexity.AverageCyclomaticComplexity - 10) * 5, 0)
            $debt.Categories['HighComplexity'] = $complexHours
            $debt.TotalHours += $complexHours
            
            $debt.Items += @{
                Type = 'HighComplexity'
                Description = "Average complexity of $($complexity.AverageCyclomaticComplexity)"
                EstimatedHours = $complexHours
                Priority = 'High'
            }
        }
        
        # Check for missing documentation
        $files = Get-ChildItem -Path $Path -Filter "*.ps*1" -Recurse -File
        $undocumented = 0
        
        foreach ($file in $files) {
            $content = Get-Content $file.FullName -Raw
            if ($content -notmatch '<#[\s\S]+?#>' -and $content -notmatch '^\s*#') {
                $undocumented++
            }
        }
        
        if ($undocumented -gt 0) {
            $docHours = $undocumented * 0.5  # 30 minutes per file
            $debt.Categories['MissingDocumentation'] = $docHours
            $debt.TotalHours += $docHours
            
            $debt.Items += @{
                Type = 'MissingDocumentation'
                Description = "$undocumented files without documentation"
                EstimatedHours = $docHours
                Priority = 'Low'
            }
        }
        
        # Calculate estimated cost (assuming $100/hour)
        $debt.EstimatedCost = $debt.TotalHours * 100
        
        # Add summary
        $debt.Summary = @{
            TotalItems = $debt.Items.Count
            HighPriority = ($debt.Items | Where-Object { $_.Priority -eq 'High' }).Count
            PaybackPeriod = if ($debt.TotalHours -gt 40) { 'Long-term' } 
                           elseif ($debt.TotalHours -gt 20) { 'Medium-term' }
                           else { 'Short-term' }
        }
        
        return $debt
    }
    catch {
        Write-Error "Failed to calculate technical debt: $_"
        return $null
    }
}

#endregion Maintenance Prediction

#region Refactoring Detection

function Find-RefactoringOpportunities {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        $Graph,
        
        [int]$MaxResults = 10
    )
    
    Write-Verbose "Finding refactoring opportunities"
    
    try {
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
            }
        }
        
        # Sort by impact and confidence
        $opportunities = $opportunities | Sort-Object @{Expression={$_.Impact}; Descending=$true}, @{Expression={$_.Confidence}; Descending=$true} | Select-Object -First $MaxResults
        
        return @{
            Opportunities = $opportunities
            Summary = @{
                Total = $opportunities.Count
                HighImpact = ($opportunities | Where-Object { $_.Impact -eq 'High' }).Count
                LowEffort = ($opportunities | Where-Object { $_.Effort -eq 'Low' }).Count
                TopRecommendation = if ($opportunities.Count -gt 0) { $opportunities[0] } else { $null }
            }
        }
    }
    catch {
        Write-Error "Failed to find refactoring opportunities: $_"
        return $null
    }
}

function Find-LongMethods {
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
                $longMethods += @{
                    Name = $node.Name
                    LineCount = $node.Properties.LineCount
                    File = $node.Properties.File
                    Complexity = $node.Properties.CyclomaticComplexity
                    Parameters = $node.Properties.Parameters.Count
                    RefactoringHint = if ($node.Properties.LineCount -gt 100) {
                        "Consider breaking into multiple smaller functions"
                    } elseif ($node.Properties.CyclomaticComplexity -gt 10) {
                        "High complexity suggests multiple responsibilities"
                    } else {
                        "Extract logical sections into helper functions"
                    }
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
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        $Graph,
        
        [int]$MethodThreshold = 20,
        
        [int]$PropertyThreshold = 15
    )
    
    Write-Verbose "Finding god classes"
    
    try {
        $godClasses = @()
        
        $classNodes = Get-CPGNode -Graph $Graph -Type 'Class'
        
        foreach ($node in $classNodes) {
            $methods = Get-CPGEdge -Graph $Graph -SourceId $node.Id -Type 'Contains' | 
                Where-Object { $Graph.Nodes[$_.To].Type -eq 'Function' }
            
            $properties = Get-CPGEdge -Graph $Graph -SourceId $node.Id -Type 'Contains' | 
                Where-Object { $Graph.Nodes[$_.To].Type -eq 'Property' }
            
            if ($methods.Count -gt $MethodThreshold -or $properties.Count -gt $PropertyThreshold) {
                $godClasses += @{
                    Name = $node.Name
                    MethodCount = $methods.Count
                    PropertyCount = $properties.Count
                    File = $node.Properties.File
                    Responsibilities = @()
                    RefactoringStrategy = if ($methods.Count -gt 30) {
                        "Split into multiple classes based on responsibility"
                    } elseif ($properties.Count -gt 20) {
                        "Consider using composition or data transfer objects"
                    } else {
                        "Review single responsibility principle"
                    }
                }
                
                # Try to identify responsibilities
                $methodNames = $methods | ForEach-Object { $Graph.Nodes[$_.To].Name }
                $prefixes = $methodNames | ForEach-Object { ($_ -split '-')[0] } | Group-Object | Where-Object { $_.Count -gt 2 }
                
                foreach ($prefix in $prefixes) {
                    $godClasses[-1].Responsibilities += "$($prefix.Name) operations ($($prefix.Count) methods)"
                }
            }
        }
        
        return $godClasses | Sort-Object MethodCount -Descending
    }
    catch {
        Write-Error "Failed to find god classes: $_"
        return @()
    }
}

function Get-DuplicationCandidates {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        $Graph,
        
        [double]$MinSimilarity = 0.8
    )
    
    Write-Verbose "Finding duplication candidates (min similarity: $MinSimilarity)"
    
    try {
        $candidates = @()
        $functionNodes = Get-CPGNode -Graph $Graph -Type 'Function'
        
        # Compare functions pairwise
        for ($i = 0; $i -lt $functionNodes.Count - 1; $i++) {
            for ($j = $i + 1; $j -lt $functionNodes.Count; $j++) {
                $node1 = $functionNodes[$i]
                $node2 = $functionNodes[$j]
                
                # Skip if same function
                if ($node1.Name -eq $node2.Name) { continue }
                
                # Calculate similarity based on structure
                $similarity = 0
                
                # Check parameter count similarity
                if ($node1.Properties.Parameters -and $node2.Properties.Parameters) {
                    if ($node1.Properties.Parameters.Count -eq $node2.Properties.Parameters.Count) {
                        $similarity += 0.2
                    }
                }
                
                # Check line count similarity
                if ($node1.Properties.LineCount -and $node2.Properties.LineCount) {
                    $lineDiff = [Math]::Abs($node1.Properties.LineCount - $node2.Properties.LineCount)
                    $avgLines = ($node1.Properties.LineCount + $node2.Properties.LineCount) / 2
                    if ($avgLines -gt 0) {
                        $lineSimilarity = 1 - ($lineDiff / $avgLines)
                        $similarity += $lineSimilarity * 0.3
                    }
                }
                
                # Check complexity similarity
                if ($node1.Properties.CyclomaticComplexity -and $node2.Properties.CyclomaticComplexity) {
                    if ($node1.Properties.CyclomaticComplexity -eq $node2.Properties.CyclomaticComplexity) {
                        $similarity += 0.2
                    }
                }
                
                # Check edge pattern similarity
                $edges1 = Get-CPGEdge -Graph $Graph -SourceId $node1.Id
                $edges2 = Get-CPGEdge -Graph $Graph -SourceId $node2.Id
                
                if ($edges1.Count -gt 0 -and $edges2.Count -gt 0) {
                    $edgeTypes1 = $edges1 | Select-Object -ExpandProperty Type -Unique
                    $edgeTypes2 = $edges2 | Select-Object -ExpandProperty Type -Unique
                    
                    $commonTypes = $edgeTypes1 | Where-Object { $_ -in $edgeTypes2 }
                    $allTypes = $edgeTypes1 + $edgeTypes2 | Select-Object -Unique
                    
                    if ($allTypes.Count -gt 0) {
                        $edgeSimilarity = $commonTypes.Count / $allTypes.Count
                        $similarity += $edgeSimilarity * 0.3
                    }
                }
                
                if ($similarity -ge $MinSimilarity) {
                    $candidates += @{
                        Source = $node1.Name
                        Target = $node2.Name
                        Similarity = [Math]::Round($similarity, 2)
                        SourceFile = $node1.Properties.File
                        TargetFile = $node2.Properties.File
                        RefactoringHint = if ($similarity -gt 0.95) {
                            "Nearly identical - consider complete extraction"
                        } elseif ($node1.Properties.File -eq $node2.Properties.File) {
                            "Same file - extract to private helper function"
                        } else {
                            "Different files - extract to shared utility module"
                        }
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

#endregion Refactoring Detection

#region Code Smell Prediction

function Predict-CodeSmells {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        $Graph,
        
        [hashtable]$CustomThresholds = @{}
    )
    
    Write-Verbose "Predicting code smells"
    
    try {
        $smells = @()
        $thresholds = $script:PredictionModels.SmellModel.Thresholds
        
        # Override with custom thresholds
        foreach ($key in $CustomThresholds.Keys) {
            $thresholds[$key] = $CustomThresholds[$key]
        }
        
        # Check for long methods
        $longMethods = Find-LongMethods -Graph $Graph -Threshold $thresholds.MethodLength
        foreach ($method in $longMethods) {
            $smells += @{
                Type = 'LongMethod'
                Target = $method.Name
                Severity = if ($method.LineCount -gt ($thresholds.MethodLength * 2)) { 'High' } 
                          elseif ($method.LineCount -gt ($thresholds.MethodLength * 1.5)) { 'Medium' } 
                          else { 'Low' }
                Confidence = 0.95
                Impact = 'Readability, Testability'
                Fix = 'Extract Method refactoring'
            }
        }
        
        # Check for god classes
        $godClasses = Find-GodClasses -Graph $Graph -MethodThreshold 20
        foreach ($class in $godClasses) {
            $smells += @{
                Type = 'GodClass'
                Target = $class.Name
                Severity = 'High'
                Confidence = 0.9
                Impact = 'Maintainability, Coupling'
                Fix = 'Split class based on responsibilities'
            }
        }
        
        # Check for feature envy
        $functionNodes = Get-CPGNode -Graph $Graph -Type 'Function'
        foreach ($node in $functionNodes) {
            $externalCalls = Get-CPGEdge -Graph $Graph -SourceId $node.Id -Type 'Calls' |
                Where-Object { 
                    $targetNode = $Graph.Nodes[$_.To]
                    $targetNode.Properties.Module -and $targetNode.Properties.Module -ne $node.Properties.Module
                }
            
            if ($externalCalls.Count -gt 5) {
                $smells += @{
                    Type = 'FeatureEnvy'
                    Target = $node.Name
                    Severity = 'Medium'
                    Confidence = 0.7
                    Impact = 'Coupling, Cohesion'
                    Fix = 'Move method to appropriate class'
                }
            }
        }
        
        # Check for data clumps
        $parameterPatterns = @{}
        foreach ($node in $functionNodes) {
            if ($node.Properties.Parameters -and $node.Properties.Parameters.Count -ge 3) {
                $paramKey = $node.Properties.Parameters | Sort-Object | Join-String -Separator ','
                if (-not $parameterPatterns.ContainsKey($paramKey)) {
                    $parameterPatterns[$paramKey] = @()
                }
                $parameterPatterns[$paramKey] += $node.Name
            }
        }
        
        foreach ($pattern in $parameterPatterns.GetEnumerator()) {
            if ($pattern.Value.Count -ge 3) {
                $smells += @{
                    Type = 'DataClump'
                    Target = $pattern.Value -join ', '
                    Severity = 'Low'
                    Confidence = 0.6
                    Impact = 'Duplication, Maintainability'
                    Fix = 'Extract parameter object'
                }
            }
        }
        
        # Calculate smell score
        $smellScore = 0
        foreach ($smell in $smells) {
            $severityWeight = switch ($smell.Severity) {
                'High' { 3 }
                'Medium' { 2 }
                'Low' { 1 }
            }
            $smellScore += $severityWeight * $smell.Confidence
        }
        
        return @{
            Smells = $smells
            Score = [Math]::Round($smellScore, 2)
            Summary = @{
                Total = $smells.Count
                High = ($smells | Where-Object { $_.Severity -eq 'High' }).Count
                Medium = ($smells | Where-Object { $_.Severity -eq 'Medium' }).Count
                Low = ($smells | Where-Object { $_.Severity -eq 'Low' }).Count
                TopSmells = $smells | Group-Object Type | Sort-Object Count -Descending | Select-Object -First 3
            }
            HealthRating = if ($smellScore -lt 5) { 'Excellent' }
                          elseif ($smellScore -lt 15) { 'Good' }
                          elseif ($smellScore -lt 30) { 'Fair' }
                          else { 'Poor' }
        }
    }
    catch {
        Write-Error "Failed to predict code smells: $_"
        return $null
    }
}

#endregion Code Smell Prediction

#region Improvement Roadmaps

function New-ImprovementRoadmap {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Path,
        
        $Graph = $null,
        
        [int]$MaxPhases = 5,
        
        [switch]$IncludeLLMRecommendations
    )
    
    Write-Verbose "Creating improvement roadmap for $Path"
    
    try {
        # Gather all analyses
        $analyses = @{
            Maintenance = Get-MaintenancePrediction -Path $Path -Graph $Graph
            TechnicalDebt = Calculate-TechnicalDebt -Path $Path -Graph $Graph
            Refactoring = if ($Graph) { Find-RefactoringOpportunities -Graph $Graph } else { $null }
            CodeSmells = if ($Graph) { Predict-CodeSmells -Graph $Graph } else { $null }
            Evolution = Get-CodeEvolutionTrend -Path $Path -DaysBack 90
        }
        
        # Initialize roadmap
        $roadmap = @{
            Path = $Path
            CreatedDate = Get-Date
            Phases = @()
            TotalEffort = 0
            ExpectedROI = @{}
            Success = @{
                Metrics = @()
                Targets = @()
            }
        }
        
        # Phase 1: Critical Issues
        $phase1Actions = @()
        
        if ($analyses.Maintenance.RiskLevel -in @('Critical', 'High')) {
            $phase1Actions += @{
                Action = 'Address critical maintenance issues'
                Tasks = $analyses.Maintenance.TopIssues
                EstimatedHours = 20
                Priority = 'Critical'
            }
        }
        
        if ($analyses.CodeSmells -and $analyses.CodeSmells.Summary.High -gt 0) {
            $highSmells = $analyses.CodeSmells.Smells | Where-Object { $_.Severity -eq 'High' }
            $phase1Actions += @{
                Action = 'Fix high-severity code smells'
                Tasks = $highSmells | ForEach-Object { "$($_.Type) in $($_.Target)" }
                EstimatedHours = $highSmells.Count * 4
                Priority = 'High'
            }
        }
        
        if ($phase1Actions.Count -gt 0) {
            $roadmap.Phases += @{
                Number = 1
                Name = 'Critical Issue Resolution'
                Duration = '1-2 weeks'
                Actions = $phase1Actions
                TotalHours = ($phase1Actions | Measure-Object -Property EstimatedHours -Sum).Sum
                ExpectedOutcome = 'Stabilize codebase and eliminate critical risks'
            }
        }
        
        # Phase 2: High-Impact Refactoring
        $phase2Actions = @()
        
        if ($analyses.Refactoring) {
            $highImpact = $analyses.Refactoring.Opportunities | Where-Object { $_.Impact -eq 'High' }
            if ($highImpact) {
                $phase2Actions += @{
                    Action = 'High-impact refactoring'
                    Tasks = $highImpact | ForEach-Object { "$($_.Type): $($_.Target)" }
                    EstimatedHours = $highImpact.Count * 8
                    Priority = 'High'
                }
            }
        }
        
        if ($analyses.TechnicalDebt.TotalHours -gt 40) {
            $phase2Actions += @{
                Action = 'Reduce technical debt'
                Tasks = $analyses.TechnicalDebt.Items | Where-Object { $_.Priority -eq 'High' } | ForEach-Object { $_.Description }
                EstimatedHours = ($analyses.TechnicalDebt.Items | Where-Object { $_.Priority -eq 'High' } | Measure-Object -Property EstimatedHours -Sum).Sum
                Priority = 'High'
            }
        }
        
        if ($phase2Actions.Count -gt 0) {
            $roadmap.Phases += @{
                Number = 2
                Name = 'High-Impact Improvements'
                Duration = '2-3 weeks'
                Actions = $phase2Actions
                TotalHours = ($phase2Actions | Measure-Object -Property EstimatedHours -Sum).Sum
                ExpectedOutcome = 'Significant improvement in code quality and maintainability'
            }
        }
        
        # Phase 3: Performance and Optimization
        $phase3Actions = @()
        
        if ($analyses.Evolution -and $analyses.Evolution.Volatility -gt 50) {
            $phase3Actions += @{
                Action = 'Stabilize volatile components'
                Tasks = @('Identify and refactor frequently changing modules', 'Improve abstractions')
                EstimatedHours = 16
                Priority = 'Medium'
            }
        }
        
        $phase3Actions += @{
            Action = 'Performance optimization'
            Tasks = @('Profile and optimize hot paths', 'Implement caching where appropriate')
            EstimatedHours = 12
            Priority = 'Medium'
        }
        
        if ($phase3Actions.Count -gt 0) {
            $roadmap.Phases += @{
                Number = 3
                Name = 'Optimization Phase'
                Duration = '1-2 weeks'
                Actions = $phase3Actions
                TotalHours = ($phase3Actions | Measure-Object -Property EstimatedHours -Sum).Sum
                ExpectedOutcome = 'Improved performance and stability'
            }
        }
        
        # Phase 4: Documentation and Testing
        $phase4Actions = @()
        
        if ($analyses.TechnicalDebt.Categories.ContainsKey('MissingDocumentation')) {
            $phase4Actions += @{
                Action = 'Complete documentation'
                Tasks = @('Document all public APIs', 'Add inline comments for complex logic')
                EstimatedHours = $analyses.TechnicalDebt.Categories['MissingDocumentation']
                Priority = 'Low'
            }
        }
        
        $phase4Actions += @{
            Action = 'Enhance test coverage'
            Tasks = @('Add unit tests for critical functions', 'Implement integration tests')
            EstimatedHours = 20
            Priority = 'Medium'
        }
        
        if ($phase4Actions.Count -gt 0) {
            $roadmap.Phases += @{
                Number = 4
                Name = 'Documentation and Testing'
                Duration = '1 week'
                Actions = $phase4Actions
                TotalHours = ($phase4Actions | Measure-Object -Property EstimatedHours -Sum).Sum
                ExpectedOutcome = 'Comprehensive documentation and test coverage'
            }
        }
        
        # Phase 5: Continuous Improvement
        $roadmap.Phases += @{
            Number = 5
            Name = 'Continuous Improvement'
            Duration = 'Ongoing'
            Actions = @(
                @{
                    Action = 'Establish code review process'
                    Tasks = @('Set up automated code analysis', 'Regular peer reviews')
                    EstimatedHours = 4
                    Priority = 'Low'
                }
                @{
                    Action = 'Monitor metrics'
                    Tasks = @('Track complexity trends', 'Monitor code churn', 'Review test coverage')
                    EstimatedHours = 2
                    Priority = 'Low'
                }
            )
            TotalHours = 6
            ExpectedOutcome = 'Sustained code quality improvements'
        }
        
        # Calculate total effort
        $roadmap.TotalEffort = ($roadmap.Phases | Measure-Object -Property TotalHours -Sum).Sum
        
        # Calculate ROI
        $roadmap.ExpectedROI = @{
            ReducedMaintenanceTime = "$([Math]::Round($roadmap.TotalEffort * 0.3, 0)) hours/month saved"
            ReducedBugRate = "30-50% reduction expected"
            ImprovedVelocity = "15-25% increase in feature delivery"
            TeamSatisfaction = "Improved developer experience"
        }
        
        # Define success metrics
        $roadmap.Success.Metrics = @(
            'Code complexity reduced by 30%'
            'Test coverage increased to 80%'
            'Critical code smells eliminated'
            'Documentation coverage at 100%'
        )
        
        $roadmap.Success.Targets = @(
            @{Metric = 'Cyclomatic Complexity'; Current = $analyses.CodeSmells.Score; Target = $analyses.CodeSmells.Score * 0.5}
            @{Metric = 'Technical Debt Hours'; Current = $analyses.TechnicalDebt.TotalHours; Target = $analyses.TechnicalDebt.TotalHours * 0.3}
            @{Metric = 'Code Smells'; Current = $analyses.CodeSmells.Summary.Total; Target = [Math]::Max(0, $analyses.CodeSmells.Summary.Total - $analyses.CodeSmells.Summary.High)}
        )
        
        # Add LLM recommendations if requested
        if ($IncludeLLMRecommendations) {
            $llmPrompt = @"
Based on this code improvement roadmap with $($roadmap.Phases.Count) phases and $($roadmap.TotalEffort) total hours of effort:

Key issues identified:
- Maintenance Risk: $($analyses.Maintenance.RiskLevel)
- Technical Debt: $($analyses.TechnicalDebt.TotalHours) hours
- Code Smells: $($analyses.CodeSmells.Summary.Total) total

Provide 3 strategic recommendations for maximizing the success of this improvement initiative.
"@
            
            try {
                $llmResponse = Invoke-OllamaGenerate -Prompt $llmPrompt -MaxTokens 500
                if ($llmResponse.Success) {
                    $roadmap.StrategicRecommendations = $llmResponse.Response
                }
            }
            catch {
                Write-Warning "Could not get LLM recommendations: $_"
            }
        }
        
        return $roadmap
    }
    catch {
        Write-Error "Failed to create improvement roadmap: $_"
        return $null
    }
}

function Export-RoadmapReport {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [hashtable]$Roadmap,
        
        [string]$OutputPath = ".\ImprovementRoadmap.html",
        
        [ValidateSet('HTML', 'Markdown', 'JSON')]
        [string]$Format = 'HTML'
    )
    
    Write-Verbose "Exporting roadmap report to $OutputPath"
    
    try {
        switch ($Format) {
            'JSON' {
                $Roadmap | ConvertTo-Json -Depth 10 | Out-File -FilePath $OutputPath -Encoding UTF8
            }
            
            'Markdown' {
                $markdown = @"
# Improvement Roadmap
**Path**: $($Roadmap.Path)  
**Created**: $($Roadmap.CreatedDate)  
**Total Effort**: $($Roadmap.TotalEffort) hours

## Executive Summary
This roadmap outlines a comprehensive improvement plan with $($Roadmap.Phases.Count) phases to enhance code quality, reduce technical debt, and improve maintainability.

## Phases

"@
                
                foreach ($phase in $Roadmap.Phases) {
                    $markdown += @"
### Phase $($phase.Number): $($phase.Name)
**Duration**: $($phase.Duration)  
**Total Hours**: $($phase.TotalHours)  
**Expected Outcome**: $($phase.ExpectedOutcome)

#### Actions:
"@
                    foreach ($action in $phase.Actions) {
                        $markdown += "- **$($action.Action)** ($($action.Priority) priority, $($action.EstimatedHours)h)`n"
                        foreach ($task in $action.Tasks) {
                            $markdown += "  - $task`n"
                        }
                    }
                    $markdown += "`n"
                }
                
                $markdown += @"
## Expected ROI
- **Reduced Maintenance Time**: $($Roadmap.ExpectedROI.ReducedMaintenanceTime)
- **Reduced Bug Rate**: $($Roadmap.ExpectedROI.ReducedBugRate)
- **Improved Velocity**: $($Roadmap.ExpectedROI.ImprovedVelocity)
- **Team Satisfaction**: $($Roadmap.ExpectedROI.TeamSatisfaction)

## Success Metrics
"@
                foreach ($metric in $Roadmap.Success.Metrics) {
                    $markdown += "- $metric`n"
                }
                
                $markdown | Out-File -FilePath $OutputPath -Encoding UTF8
            }
            
            'HTML' {
                $html = @"
<!DOCTYPE html>
<html>
<head>
    <title>Improvement Roadmap</title>
    <style>
        body { font-family: Arial, sans-serif; max-width: 1200px; margin: 0 auto; padding: 20px; }
        h1 { color: #2c3e50; }
        h2 { color: #34495e; border-bottom: 2px solid #3498db; padding-bottom: 5px; }
        h3 { color: #7f8c8d; }
        .phase { background: #f8f9fa; padding: 15px; margin: 15px 0; border-radius: 5px; }
        .high { color: #e74c3c; font-weight: bold; }
        .medium { color: #f39c12; font-weight: bold; }
        .low { color: #27ae60; }
        .critical { color: #c0392b; font-weight: bold; }
        .summary { background: #ecf0f1; padding: 10px; border-left: 4px solid #3498db; }
        .roi { background: #d5f4e6; padding: 10px; margin: 10px 0; }
        table { width: 100%; border-collapse: collapse; }
        th, td { padding: 8px; text-align: left; border: 1px solid #ddd; }
        th { background: #3498db; color: white; }
    </style>
</head>
<body>
    <h1>Improvement Roadmap</h1>
    <div class="summary">
        <p><strong>Path:</strong> $($Roadmap.Path)</p>
        <p><strong>Created:</strong> $($Roadmap.CreatedDate)</p>
        <p><strong>Total Effort:</strong> $($Roadmap.TotalEffort) hours</p>
    </div>
    
    <h2>Phases</h2>
"@
                
                foreach ($phase in $Roadmap.Phases) {
                    $html += @"
    <div class="phase">
        <h3>Phase $($phase.Number): $($phase.Name)</h3>
        <p><strong>Duration:</strong> $($phase.Duration) | <strong>Total Hours:</strong> $($phase.TotalHours)</p>
        <p><strong>Expected Outcome:</strong> $($phase.ExpectedOutcome)</p>
        <h4>Actions:</h4>
        <ul>
"@
                    foreach ($action in $phase.Actions) {
                        $priorityClass = $action.Priority.ToLower()
                        $html += "        <li><span class='$priorityClass'>[$($action.Priority)]</span> <strong>$($action.Action)</strong> ($($action.EstimatedHours)h)<ul>`n"
                        foreach ($task in $action.Tasks) {
                            $html += "            <li>$task</li>`n"
                        }
                        $html += "        </ul></li>`n"
                    }
                    $html += "        </ul>`n    </div>`n"
                }
                
                $html += @"
    <h2>Expected ROI</h2>
    <div class="roi">
        <ul>
            <li><strong>Reduced Maintenance Time:</strong> $($Roadmap.ExpectedROI.ReducedMaintenanceTime)</li>
            <li><strong>Reduced Bug Rate:</strong> $($Roadmap.ExpectedROI.ReducedBugRate)</li>
            <li><strong>Improved Velocity:</strong> $($Roadmap.ExpectedROI.ImprovedVelocity)</li>
            <li><strong>Team Satisfaction:</strong> $($Roadmap.ExpectedROI.TeamSatisfaction)</li>
        </ul>
    </div>
    
    <h2>Success Metrics</h2>
    <table>
        <tr><th>Metric</th><th>Current</th><th>Target</th></tr>
"@
                foreach ($target in $Roadmap.Success.Targets) {
                    $html += "        <tr><td>$($target.Metric)</td><td>$($target.Current)</td><td>$($target.Target)</td></tr>`n"
                }
                
                $html += @"
    </table>
</body>
</html>
"@
                
                $html | Out-File -FilePath $OutputPath -Encoding UTF8
            }
        }
        
        Write-Verbose "Roadmap report exported successfully"
        return $OutputPath
    }
    catch {
        Write-Error "Failed to export roadmap report: $_"
        return $null
    }
}

#endregion Improvement Roadmaps

#region Utility Functions

function Get-CouplingIssues {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        $Graph,
        
        [int]$Threshold = 7
    )
    
    Write-Verbose "Analyzing coupling issues"
    
    try {
        $issues = @()
        $moduleNodes = Get-CPGNode -Graph $Graph -Type 'Module'
        
        foreach ($module in $moduleNodes) {
            # Count external dependencies
            $externalDeps = Get-CPGEdge -Graph $Graph -SourceId $module.Id -Type 'DependsOn' |
                Where-Object { 
                    $target = $Graph.Nodes[$_.To]
                    $target.Type -eq 'Module' -and $target.Id -ne $module.Id
                }
            
            # Count external calls
            $functionsInModule = Get-CPGEdge -Graph $Graph -SourceId $module.Id -Type 'Contains' |
                Where-Object { $Graph.Nodes[$_.To].Type -eq 'Function' }
            
            $externalCalls = 0
            foreach ($func in $functionsInModule) {
                $calls = Get-CPGEdge -Graph $Graph -SourceId $func.To -Type 'Calls' |
                    Where-Object {
                        $targetFunc = $Graph.Nodes[$_.To]
                        $targetFunc.Properties.Module -and $targetFunc.Properties.Module -ne $module.Name
                    }
                $externalCalls += $calls.Count
            }
            
            $couplingScore = $externalDeps.Count + ([Math]::Min($externalCalls / 10, 10))
            
            if ($couplingScore -gt $Threshold) {
                $issues += @{
                    Module = $module.Name
                    CouplingScore = [Math]::Round($couplingScore, 1)
                    ExternalDependencies = $externalDeps.Count
                    ExternalCalls = $externalCalls
                    Risk = if ($couplingScore -gt 15) { 'High' } 
                          elseif ($couplingScore -gt 10) { 'Medium' } 
                          else { 'Low' }
                    Recommendation = if ($couplingScore -gt 15) {
                        "Critical coupling - consider architectural refactoring"
                    } elseif ($externalDeps.Count -gt 5) {
                        "Too many dependencies - apply dependency inversion"
                    } else {
                        "High external communication - consider facade pattern"
                    }
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

function Get-CommitFrequency {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Path,
        
        [int]$DaysBack = 30
    )
    
    Write-Verbose "Getting commit frequency for $Path"
    
    try {
        $startDate = (Get-Date).AddDays(-$DaysBack)
        $commits = git log --since="$($startDate.ToString('yyyy-MM-dd'))" --pretty=format:"%H" -- $Path 2>$null | Measure-Object
        
        return @{
            Path = $Path
            Period = "$DaysBack days"
            TotalCommits = $commits.Count
            CommitsPerDay = [Math]::Round($commits.Count / $DaysBack, 2)
            CommitsPerWeek = [Math]::Round($commits.Count / ($DaysBack / 7), 2)
        }
    }
    catch {
        Write-Error "Failed to get commit frequency: $_"
        return $null
    }
}

function Get-AuthorContributions {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Path,
        
        [int]$DaysBack = 90
    )
    
    Write-Verbose "Analyzing author contributions for $Path"
    
    try {
        $startDate = (Get-Date).AddDays(-$DaysBack)
        $authorStats = git shortlog -sn --since="$($startDate.ToString('yyyy-MM-dd'))" -- $Path 2>$null
        
        $contributions = @()
        foreach ($line in $authorStats) {
            if ($line -match '^\s*(\d+)\s+(.+)$') {
                $contributions += @{
                    Author = $Matches[2].Trim()
                    Commits = [int]$Matches[1]
                    Percentage = 0  # Will calculate after
                }
            }
        }
        
        $totalCommits = ($contributions | Measure-Object -Property Commits -Sum).Sum
        
        foreach ($contrib in $contributions) {
            $contrib.Percentage = [Math]::Round(($contrib.Commits / $totalCommits) * 100, 1)
        }
        
        return @{
            Path = $Path
            Period = "$DaysBack days"
            TotalAuthors = $contributions.Count
            TotalCommits = $totalCommits
            TopContributors = $contributions | Select-Object -First 5
            BusFactorRisk = if ($contributions[0].Percentage -gt 50) { 'High' }
                           elseif ($contributions[0].Percentage -gt 30) { 'Medium' }
                           else { 'Low' }
        }
    }
    catch {
        Write-Error "Failed to analyze author contributions: $_"
        return $null
    }
}

function Predict-BugProbability {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Path,
        
        $Graph = $null
    )
    
    Write-Verbose "Predicting bug probability for $Path"
    
    try {
        # Factors that increase bug probability
        $factors = @{
            HighChurn = 0
            HighComplexity = 0
            LowCoverage = 0
            RecentChanges = 0
            MultipleAuthors = 0
        }
        
        # Check code churn
        $churn = Measure-CodeChurn -Path $Path -DaysBack 30
        if ($churn -and $churn.ChurnRate -gt 50) {
            $factors.HighChurn = 0.3
        }
        
        # Check complexity
        if ($Graph) {
            $complexity = Get-CodeComplexityMetrics -Graph $Graph
            if ($complexity -and $complexity.AverageCyclomaticComplexity -gt 10) {
                $factors.HighComplexity = 0.25
            }
        }
        
        # Check recent changes
        $recentCommits = Get-CommitFrequency -Path $Path -DaysBack 7
        if ($recentCommits -and $recentCommits.TotalCommits -gt 5) {
            $factors.RecentChanges = 0.2
        }
        
        # Check author diversity
        $authors = Get-AuthorContributions -Path $Path -DaysBack 30
        if ($authors -and $authors.TotalAuthors -gt 3) {
            $factors.MultipleAuthors = 0.15
        }
        
        # Assume low coverage if no tests found (simplified)
        $testFiles = Get-ChildItem -Path $Path -Filter "*test*.ps1" -Recurse -ErrorAction SilentlyContinue
        if ($testFiles.Count -eq 0) {
            $factors.LowCoverage = 0.3
        }
        
        # Calculate probability
        $probability = 0
        foreach ($factor in $factors.Values) {
            $probability += $factor
        }
        $probability = [Math]::Min($probability, 1.0)
        
        return @{
            Path = $Path
            Probability = [Math]::Round($probability, 2)
            Risk = if ($probability -gt 0.7) { 'High' }
                  elseif ($probability -gt 0.4) { 'Medium' }
                  else { 'Low' }
            Factors = $factors
            Recommendation = if ($probability -gt 0.7) {
                "High bug risk - implement comprehensive testing immediately"
            } elseif ($probability -gt 0.4) {
                "Moderate bug risk - increase test coverage and code reviews"
            } else {
                "Low bug risk - maintain current quality practices"
            }
        }
    }
    catch {
        Write-Error "Failed to predict bug probability: $_"
        return $null
    }
}

function Get-MaintenanceRisk {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Path
    )
    
    Write-Verbose "Assessing maintenance risk for $Path"
    
    try {
        $prediction = Get-MaintenancePrediction -Path $Path
        return $prediction.RiskLevel
    }
    catch {
        Write-Error "Failed to get maintenance risk: $_"
        return 'Unknown'
    }
}

function Get-SmellProbability {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        $Graph,
        
        [string]$Type = 'All'
    )
    
    Write-Verbose "Getting code smell probability"
    
    try {
        $smells = Predict-CodeSmells -Graph $Graph
        
        if ($Type -eq 'All') {
            return $smells.Score / 100  # Normalize to 0-1
        }
        else {
            $specificSmells = $smells.Smells | Where-Object { $_.Type -eq $Type }
            if ($specificSmells) {
                return ($specificSmells | Measure-Object -Property Confidence -Average).Average
            }
            return 0
        }
    }
    catch {
        Write-Error "Failed to get smell probability: $_"
        return 0
    }
}

function Find-AntiPatterns {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        $Graph
    )
    
    Write-Verbose "Finding anti-patterns"
    
    try {
        $antiPatterns = @()
        
        # Detect spaghetti code (high complexity with many dependencies)
        $complexFunctions = Get-CPGNode -Graph $Graph -Type 'Function' |
            Where-Object { $_.Properties.CyclomaticComplexity -gt 15 }
        
        foreach ($func in $complexFunctions) {
            $edges = Get-CPGEdge -Graph $Graph -SourceId $func.Id
            if ($edges.Count -gt 20) {
                $antiPatterns += @{
                    Type = 'SpaghettiCode'
                    Target = $func.Name
                    Severity = 'High'
                    Description = 'Complex function with too many dependencies'
                }
            }
        }
        
        # Detect copy-paste programming
        $duplicates = Get-DuplicationCandidates -Graph $Graph -MinSimilarity 0.9
        if ($duplicates.Count -gt 3) {
            $antiPatterns += @{
                Type = 'CopyPasteProgramming'
                Target = 'Multiple locations'
                Severity = 'Medium'
                Description = "$($duplicates.Count) instances of near-identical code"
            }
        }
        
        return $antiPatterns
    }
    catch {
        Write-Error "Failed to find anti-patterns: $_"
        return @()
    }
}

function Get-DesignFlaws {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        $Graph
    )
    
    Write-Verbose "Detecting design flaws"
    
    try {
        $flaws = @()
        
        # Check for circular dependencies
        $modules = Get-CPGNode -Graph $Graph -Type 'Module'
        foreach ($module in $modules) {
            $visited = @{}
            $stack = @($module.Id)
            
            while ($stack.Count -gt 0) {
                $current = $stack[-1]
                $stack = $stack[0..($stack.Count - 2)]
                
                if ($visited.ContainsKey($current)) {
                    if ($visited[$current] -eq $module.Id) {
                        $flaws += @{
                            Type = 'CircularDependency'
                            Target = $module.Name
                            Severity = 'High'
                            Description = 'Module has circular dependency'
                        }
                        break
                    }
                    continue
                }
                
                $visited[$current] = $module.Id
                
                $deps = Get-CPGEdge -Graph $Graph -SourceId $current -Type 'DependsOn'
                foreach ($dep in $deps) {
                    $stack += $dep.To
                }
            }
        }
        
        return $flaws
    }
    catch {
        Write-Error "Failed to detect design flaws: $_"
        return @()
    }
}

function Calculate-SmellScore {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        $Graph
    )
    
    Write-Verbose "Calculating smell score"
    
    try {
        $smells = Predict-CodeSmells -Graph $Graph
        return $smells.Score
    }
    catch {
        Write-Error "Failed to calculate smell score: $_"
        return 0
    }
}

function Get-PriorityActions {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [hashtable]$Roadmap,
        
        [int]$TopN = 5
    )
    
    Write-Verbose "Getting priority actions from roadmap"
    
    try {
        $allActions = @()
        
        foreach ($phase in $Roadmap.Phases) {
            foreach ($action in $phase.Actions) {
                $allActions += @{
                    Phase = $phase.Number
                    Action = $action.Action
                    Priority = $action.Priority
                    EstimatedHours = $action.EstimatedHours
                    Tasks = $action.Tasks
                }
            }
        }
        
        # Sort by priority and effort
        $priorityOrder = @{'Critical' = 0; 'High' = 1; 'Medium' = 2; 'Low' = 3}
        $sorted = $allActions | Sort-Object @{Expression={$priorityOrder[$_.Priority]}}, EstimatedHours
        
        return $sorted | Select-Object -First $TopN
    }
    catch {
        Write-Error "Failed to get priority actions: $_"
        return @()
    }
}

function Estimate-RefactoringEffort {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [hashtable]$Opportunity,
        
        $Graph = $null
    )
    
    Write-Verbose "Estimating refactoring effort"
    
    try {
        $baseEffort = switch ($Opportunity.Type) {
            'ExtractMethod' { 2 }
            'SplitClass' { 8 }
            'ExtractCommon' { 4 }
            'ReduceCoupling' { 12 }
            default { 4 }
        }
        
        # Adjust based on complexity if graph available
        if ($Graph) {
            $node = Get-CPGNode -Graph $Graph | Where-Object { $_.Name -eq $Opportunity.Target } | Select-Object -First 1
            if ($node -and $node.Properties.CyclomaticComplexity) {
                $complexityMultiplier = 1 + ($node.Properties.CyclomaticComplexity / 20)
                $baseEffort = [Math]::Round($baseEffort * $complexityMultiplier, 0)
            }
        }
        
        return @{
            Type = $Opportunity.Type
            Target = $Opportunity.Target
            EstimatedHours = $baseEffort
            Complexity = switch ($baseEffort) {
                {$_ -le 2} { 'Trivial' }
                {$_ -le 4} { 'Simple' }
                {$_ -le 8} { 'Moderate' }
                {$_ -le 16} { 'Complex' }
                default { 'Very Complex' }
            }
        }
    }
    catch {
        Write-Error "Failed to estimate refactoring effort: $_"
        return $null
    }
}

function Get-ROIAnalysis {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [hashtable]$Roadmap
    )
    
    Write-Verbose "Analyzing ROI for improvement roadmap"
    
    try {
        $roi = @{
            Investment = @{
                TotalHours = $Roadmap.TotalEffort
                EstimatedCost = $Roadmap.TotalEffort * 100  # $100/hour
            }
            Returns = @{
                MonthlyTimeSaved = [Math]::Round($Roadmap.TotalEffort * 0.3, 0)
                BugReductionPercent = 40
                VelocityIncreasePercent = 20
            }
            PaybackPeriod = 0
            NetValue = 0
        }
        
        # Calculate payback period
        if ($roi.Returns.MonthlyTimeSaved -gt 0) {
            $roi.PaybackPeriod = [Math]::Round($roi.Investment.TotalHours / $roi.Returns.MonthlyTimeSaved, 1)
        }
        
        # Calculate net value over 1 year
        $yearlyTimeSaved = $roi.Returns.MonthlyTimeSaved * 12
        $yearlyValueCreated = $yearlyTimeSaved * 100
        $roi.NetValue = $yearlyValueCreated - $roi.Investment.EstimatedCost
        
        $roi.Recommendation = if ($roi.PaybackPeriod -le 3) {
            "Excellent ROI - proceed immediately"
        } elseif ($roi.PaybackPeriod -le 6) {
            "Good ROI - schedule for next quarter"
        } else {
            "Moderate ROI - consider partial implementation"
        }
        
        return $roi
    }
    catch {
        Write-Error "Failed to analyze ROI: $_"
        return $null
    }
}

function Get-HistoricalMetrics {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Path,
        
        [int]$DaysBack = 365
    )
    
    Write-Verbose "Getting historical metrics for $Path"
    
    try {
        return @{
            Evolution = Get-CodeEvolutionTrend -Path $Path -DaysBack $DaysBack -Granularity Monthly
            Churn = Measure-CodeChurn -Path $Path -DaysBack $DaysBack
            Authors = Get-AuthorContributions -Path $Path -DaysBack $DaysBack
            CommitFrequency = Get-CommitFrequency -Path $Path -DaysBack $DaysBack
        }
    }
    catch {
        Write-Error "Failed to get historical metrics: $_"
        return $null
    }
}

function Update-PredictionModels {
    [CmdletBinding()]
    param(
        [hashtable]$NewData
    )
    
    Write-Verbose "Updating prediction models with new data"
    
    try {
        # This would typically update ML models with new training data
        # For now, just adjust weights based on feedback
        
        if ($NewData.ActualMaintenanceHours -and $NewData.PredictedMaintenanceHours) {
            $error = ($NewData.ActualMaintenanceHours - $NewData.PredictedMaintenanceHours) / $NewData.PredictedMaintenanceHours
            
            # Adjust weights if error is significant
            if ([Math]::Abs($error) -gt 0.2) {
                $adjustment = 1 + ($error * 0.1)  # 10% adjustment
                
                foreach ($key in $script:PredictionModels.MaintenanceModel.Weights.Keys) {
                    $script:PredictionModels.MaintenanceModel.Weights[$key] *= $adjustment
                }
                
                Write-Verbose "Adjusted model weights by $(($adjustment - 1) * 100)%"
            }
        }
        
        return $true
    }
    catch {
        Write-Error "Failed to update prediction models: $_"
        return $false
    }
}

function Get-ComplexityTrend {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Path,
        
        [int]$Samples = 5
    )
    
    Write-Verbose "Analyzing complexity trend for $Path"
    
    try {
        # This would ideally track complexity over git history
        # Simplified version returns current complexity
        
        $files = Get-ChildItem -Path $Path -Filter "*.ps*1" -Recurse -File
        $totalComplexity = 0
        $fileCount = 0
        
        foreach ($file in $files) {
            $content = Get-Content $file.FullName -Raw
            $complexity = ([regex]::Matches($content, '\b(if|while|for|foreach|switch|catch)\b')).Count
            $totalComplexity += $complexity
            $fileCount++
        }
        
        $avgComplexity = if ($fileCount -gt 0) { [Math]::Round($totalComplexity / $fileCount, 2) } else { 0 }
        
        return @{
            Path = $Path
            AverageComplexity = $avgComplexity
            TotalComplexity = $totalComplexity
            FileCount = $fileCount
            Trend = 'Stable'  # Would calculate from historical data
            Projection = 'Maintaining current level'
        }
    }
    catch {
        Write-Error "Failed to analyze complexity trend: $_"
        return $null
    }
}

#endregion Utility Functions

# Initialize cache on module load
Initialize-PredictiveCache

# Export all public functions
Export-ModuleMember -Function * -Alias gct, gmp, fro, pcs, nir
# SIG # Begin signature block
# MIIFzgYJKoZIhvcNAQcCoIIFvzCCBbsCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCCtWQzysoumSQHg
# HY3JekYkiJfQVRMaztx/NzLejCyqfKCCAzAwggMsMIICFKADAgECAhB1HRbZIqgr
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
# MAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIMwM24TWBDLbTjnd/vkFpRPi
# K8zz1NVFzQb4NEaVZ0xOMA0GCSqGSIb3DQEBAQUABIIBACU1Ptr7ojpOjTopW2vR
# kVYxzLVIbLwr1vVxPKGbVYf1PFz+1JfwUTRGxGNx/m07mXX743+98pmn7v15mWIG
# 3LRPhJeQ19rjQCAFiNJPpj6YbkxrEp1sNbYm9EGkZEUaGh2CVyk1B5sYa6t0I+Uk
# 8c4sQedGSOwM1QxvJqKAZ7K2fbstYPS1ee1CHfNsrmbbmrZ4pE7SXyEkuLdFeqjV
# bRy+5VkoR+dO0JuP2J+ZKgfmutz+eW+bsSXT5i3fSpYTsyQuuzVAnwty7m580Tkb
# EDXatxO8akXw1oD+DgDEZfoY6iVZfR8TMFa7J10ayQNYuJ0SOBsyX1/Qobf7kBbP
# RiQ=
# SIG # End signature block
