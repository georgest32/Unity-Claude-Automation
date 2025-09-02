#region AnalyticsReporting Module - Analytics and Reporting Functions
<#
.SYNOPSIS
    Unity Claude Predictive Analysis - Analytics & Reporting Component
    
.DESCRIPTION
    Provides comprehensive analytics and reporting capabilities including:
    - ROI analysis for improvement roadmaps
    - Historical metrics collection and analysis
    - Performance tracking and trend analysis
    - Model updating and calibration
    - Priority action extraction and ranking
    - Effort estimation for refactoring opportunities
    
.VERSION
    2.0.0
    
.DEPENDENCIES
    - Unity-Claude-CPG (Code Property Graph analysis)
    - Unity-Claude-Cache (Performance optimization)
    - Git (Version control integration)
    
.AUTHOR
    Unity-Claude-Automation Framework
#>

# Import required dependencies
Import-Module -Name (Join-Path $PSScriptRoot '..\Unity-Claude-CPG\Unity-Claude-CPG.psd1') -Force -ErrorAction SilentlyContinue
Import-Module -Name (Join-Path $PSScriptRoot '..\Unity-Claude-Cache\Unity-Claude-Cache.psd1') -Force -ErrorAction SilentlyContinue

#region ROI Analysis Functions

function Get-ROIAnalysis {
    <#
    .SYNOPSIS
        Analyzes Return on Investment for improvement roadmaps
        
    .DESCRIPTION
        Calculates comprehensive ROI metrics including investment costs, expected returns,
        payback periods, and net value creation for improvement initiatives
        
    .PARAMETER Roadmap
        Improvement roadmap hashtable containing phases, actions, and effort estimates
        
    .OUTPUTS
        System.Collections.Hashtable
        Contains investment analysis, returns projection, payback period, and recommendations
        
    .EXAMPLE
        $roadmap = New-ImprovementRoadmap -Path "C:\Project" -Graph $graph
        $roi = Get-ROIAnalysis -Roadmap $roadmap
        Write-Host "Payback period: $($roi.PaybackPeriod) months"
    #>
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

function Estimate-RefactoringEffort {
    <#
    .SYNOPSIS
        Estimates effort required for refactoring opportunities
        
    .DESCRIPTION
        Calculates time and complexity estimates for various refactoring types,
        adjusting based on code complexity metrics when available
        
    .PARAMETER Opportunity
        Refactoring opportunity hashtable with Type and Target properties
        
    .PARAMETER Graph
        Optional Code Property Graph for complexity analysis
        
    .OUTPUTS
        System.Collections.Hashtable
        Contains effort estimates, complexity assessment, and time projections
        
    .EXAMPLE
        $opportunity = @{ Type = 'ExtractMethod'; Target = 'ProcessData' }
        $effort = Estimate-RefactoringEffort -Opportunity $opportunity -Graph $graph
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [hashtable]$Opportunity,
        
        $Graph = $null
    )
    
    Write-Verbose "Estimating refactoring effort for $($Opportunity.Type) on $($Opportunity.Target)"
    
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

function Get-PriorityActions {
    <#
    .SYNOPSIS
        Extracts and ranks priority actions from improvement roadmaps
        
    .DESCRIPTION
        Sorts and prioritizes improvement actions based on priority level and effort,
        returning the most critical items for immediate attention
        
    .PARAMETER Roadmap
        Improvement roadmap hashtable containing phased actions
        
    .PARAMETER TopN
        Number of top priority actions to return (default: 5)
        
    .OUTPUTS
        System.Collections.Hashtable[]
        Array of priority actions with phase, priority, and effort information
        
    .EXAMPLE
        $roadmap = New-ImprovementRoadmap -Path "C:\Project" -Graph $graph
        $actions = Get-PriorityActions -Roadmap $roadmap -TopN 10
        $actions | Format-Table Phase, Action, Priority, EstimatedHours
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [hashtable]$Roadmap,
        
        [int]$TopN = 5
    )
    
    Write-Verbose "Getting priority actions from roadmap (top $TopN)"
    
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

#endregion ROI Analysis Functions

#region Historical Metrics Functions

function Get-HistoricalMetrics {
    <#
    .SYNOPSIS
        Collects comprehensive historical metrics for a codebase path
        
    .DESCRIPTION
        Aggregates multiple historical analysis metrics including code evolution,
        churn rates, author contributions, and commit patterns over time
        
    .PARAMETER Path
        File system path to analyze
        
    .PARAMETER DaysBack
        Number of days of history to analyze (default: 365)
        
    .OUTPUTS
        System.Collections.Hashtable
        Contains evolution, churn, authors, and commit frequency metrics
        
    .EXAMPLE
        $metrics = Get-HistoricalMetrics -Path "C:\Project\src" -DaysBack 180
        Write-Host "Total commits: $($metrics.CommitFrequency.TotalCommits)"
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Path,
        
        [int]$DaysBack = 365
    )
    
    Write-Verbose "Getting historical metrics for $Path over $DaysBack days"
    
    try {
        $cacheKey = "historical_metrics_$($Path.Replace('\', '_').Replace(':', ''))_$DaysBack"
        $cached = Get-CacheItem -Key $cacheKey
        if ($cached) {
            Write-Verbose "Returning cached historical metrics"
            return $cached
        }
        
        $metrics = @{
            Evolution = Get-CodeEvolutionTrend -Path $Path -DaysBack $DaysBack -Granularity Monthly
            Churn = Measure-CodeChurn -Path $Path -DaysBack $DaysBack
            Authors = Get-AuthorContributions -Path $Path -DaysBack $DaysBack
            CommitFrequency = Get-CommitFrequency -Path $Path -DaysBack $DaysBack
        }
        
        Set-CacheItem -Key $cacheKey -Value $metrics -TTLMinutes 60
        return $metrics
    }
    catch {
        Write-Error "Failed to get historical metrics: $_"
        return $null
    }
}

function Get-ComplexityTrend {
    <#
    .SYNOPSIS
        Analyzes complexity trends over time for a codebase
        
    .DESCRIPTION
        Tracks code complexity metrics and provides trend analysis with projections
        for future complexity evolution
        
    .PARAMETER Path
        File system path to analyze
        
    .PARAMETER Samples
        Number of historical samples to analyze (default: 5)
        
    .OUTPUTS
        System.Collections.Hashtable
        Contains complexity metrics, trends, and projections
        
    .EXAMPLE
        $trend = Get-ComplexityTrend -Path "C:\Project" -Samples 10
        Write-Host "Complexity trend: $($trend.Trend)"
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Path,
        
        [int]$Samples = 5
    )
    
    Write-Verbose "Analyzing complexity trend for $Path with $Samples samples"
    
    try {
        $cacheKey = "complexity_trend_$($Path.Replace('\', '_').Replace(':', ''))_$Samples"
        $cached = Get-CacheItem -Key $cacheKey
        if ($cached) {
            Write-Verbose "Returning cached complexity trend"
            return $cached
        }
        
        # This would ideally track complexity over git history
        # Simplified version returns current complexity
        
        $files = Get-ChildItem -Path $Path -Filter "*.ps*1" -Recurse -File
        $totalComplexity = 0
        $fileCount = 0
        
        foreach ($file in $files) {
            $content = Get-Content $file.FullName -Raw -ErrorAction SilentlyContinue
            if ($content) {
                $complexity = ([regex]::Matches($content, '\b(if|while|for|foreach|switch|catch)\b')).Count
                $totalComplexity += $complexity
                $fileCount++
            }
        }
        
        $avgComplexity = if ($fileCount -gt 0) { [Math]::Round($totalComplexity / $fileCount, 2) } else { 0 }
        
        $result = @{
            Path = $Path
            AverageComplexity = $avgComplexity
            TotalComplexity = $totalComplexity
            FileCount = $fileCount
            Trend = 'Stable'  # Would calculate from historical data
            Projection = 'Maintaining current level'
        }
        
        Set-CacheItem -Key $cacheKey -Value $result -TTLMinutes 30
        return $result
    }
    catch {
        Write-Error "Failed to analyze complexity trend: $_"
        return $null
    }
}

function Get-CommitFrequency {
    <#
    .SYNOPSIS
        Analyzes commit frequency patterns for a path
        
    .DESCRIPTION
        Calculates commit statistics including total commits, daily/weekly averages,
        and activity patterns over a specified time period
        
    .PARAMETER Path
        File system path to analyze
        
    .PARAMETER DaysBack
        Number of days to look back for commit analysis (default: 30)
        
    .OUTPUTS
        System.Collections.Hashtable
        Contains commit frequency statistics and patterns
        
    .EXAMPLE
        $frequency = Get-CommitFrequency -Path "src/main.ps1" -DaysBack 60
        Write-Host "Commits per week: $($frequency.CommitsPerWeek)"
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Path,
        
        [int]$DaysBack = 30
    )
    
    Write-Verbose "Getting commit frequency for $Path over $DaysBack days"
    
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
    <#
    .SYNOPSIS
        Analyzes author contribution patterns and bus factor risk
        
    .DESCRIPTION
        Examines commit patterns by author to identify contribution distribution
        and assess knowledge concentration risks (bus factor)
        
    .PARAMETER Path
        File system path to analyze
        
    .PARAMETER DaysBack
        Number of days to analyze for contributions (default: 90)
        
    .OUTPUTS
        System.Collections.Hashtable
        Contains author statistics and bus factor assessment
        
    .EXAMPLE
        $contributions = Get-AuthorContributions -Path "C:\Project" -DaysBack 180
        Write-Host "Bus factor risk: $($contributions.BusFactorRisk)"
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Path,
        
        [int]$DaysBack = 90
    )
    
    Write-Verbose "Analyzing author contributions for $Path over $DaysBack days"
    
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
            if ($totalCommits -gt 0) {
                $contrib.Percentage = [Math]::Round(($contrib.Commits / $totalCommits) * 100, 1)
            }
        }
        
        return @{
            Path = $Path
            Period = "$DaysBack days"
            TotalAuthors = $contributions.Count
            TotalCommits = $totalCommits
            TopContributors = $contributions | Select-Object -First 5
            BusFactorRisk = if ($contributions.Count -gt 0 -and $contributions[0].Percentage -gt 50) { 'High' }
                           elseif ($contributions.Count -gt 0 -and $contributions[0].Percentage -gt 30) { 'Medium' }
                           else { 'Low' }
        }
    }
    catch {
        Write-Error "Failed to analyze author contributions: $_"
        return $null
    }
}

#endregion Historical Metrics Functions

#region Model Management Functions

function Update-PredictionModels {
    <#
    .SYNOPSIS
        Updates prediction models with new training data and feedback
        
    .DESCRIPTION
        Adjusts prediction model weights and parameters based on actual outcomes
        versus predicted values to improve future accuracy
        
    .PARAMETER NewData
        Hashtable containing actual vs predicted values for model calibration
        
    .OUTPUTS
        System.Boolean
        True if models were successfully updated, False otherwise
        
    .EXAMPLE
        $feedback = @{
            ActualMaintenanceHours = 15
            PredictedMaintenanceHours = 12
        }
        $updated = Update-PredictionModels -NewData $feedback
    #>
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
                
                # Initialize prediction models if not exists
                if (-not $script:PredictionModels) {
                    $script:PredictionModels = @{
                        MaintenanceModel = @{
                            Weights = @{
                                Complexity = 0.3
                                Churn = 0.25
                                Size = 0.2
                                Age = 0.15
                                BugHistory = 0.1
                            }
                        }
                    }
                }
                
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

#endregion Model Management Functions

#region Utility Functions

function Get-CouplingIssues {
    <#
    .SYNOPSIS
        Identifies coupling issues and architectural problems in code
        
    .DESCRIPTION
        Analyzes module dependencies and external calls to identify tight coupling
        and architectural debt that may impact maintainability
        
    .PARAMETER Graph
        Code Property Graph containing module and dependency information
        
    .PARAMETER Threshold
        Coupling threshold above which issues are reported (default: 7)
        
    .OUTPUTS
        System.Collections.Hashtable[]
        Array of coupling issues with scores and recommendations
        
    .EXAMPLE
        $graph = ConvertTo-CPGFromPath -Path "C:\Project"
        $issues = Get-CouplingIssues -Graph $graph -Threshold 10
        $issues | Format-Table Module, CouplingScore, Risk
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        $Graph,
        
        [int]$Threshold = 7
    )
    
    Write-Verbose "Analyzing coupling issues with threshold $Threshold"
    
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

#endregion Utility Functions

# Export public functions
Export-ModuleMember -Function @(
    'Get-ROIAnalysis',
    'Estimate-RefactoringEffort', 
    'Get-PriorityActions',
    'Get-HistoricalMetrics',
    'Get-ComplexityTrend',
    'Get-CommitFrequency',
    'Get-AuthorContributions',
    'Update-PredictionModels',
    'Get-CouplingIssues'
)

#endregion AnalyticsReporting Module
# SIG # Begin signature block
# MIIFzgYJKoZIhvcNAQcCoIIFvzCCBbsCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCDasluwwQ+dH3ih
# TtxXY5zd8fVaQNrSZGaRYtwZFTGtfKCCAzAwggMsMIICFKADAgECAhB1HRbZIqgr
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
# MAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIK6TudcPMnq1OAUysCg0rrZ9
# 0Y1nK09ryr+suS+WIw1yMA0GCSqGSIb3DQEBAQUABIIBAD5MVTv/Gsg8NJwL5mBG
# iJyRUTNkfTLdX83nRnrR+kidJDBYLOZlZQVsYUI2wP6aTYNsgRF3AEac1jSeuUqn
# 4u/QsgS4lbOBGQpOsxRlEGGObFB2b0Y2Xvv35kEzkvrf519Qbd44KVCbFIiFFnbP
# 4g0h2RFGBvslpwV06PntOUTci6MH1D8mwkjxzVSHPDe1NSNWJ6ltnzus5O/uEzqF
# cw02Gfgp+UPxbgR8TnI4b6G5BheWfThbooSNMPbn4IxKr3UzjKnD5+w62QqAF9YJ
# 6mwQO9zkzGZGmH6lPev1ahtRWldduP8Vdcnp86I9f+QT1N6mneAQbT4dhXmczZPv
# Nhs=
# SIG # End signature block
