# Unity-Claude-PredictiveAnalysis Trend Analysis Component
# Code evolution trends, churn analysis, and hotspot detection
# Part of refactored PredictiveAnalysis module

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

# Import core component
$CorePath = Join-Path $PSScriptRoot "PredictiveCore.psm1"
Import-Module $CorePath -Force

function Get-CodeEvolutionTrend {
    <#
    .SYNOPSIS
    Analyzes code evolution trends over time
    .DESCRIPTION
    Examines git history to identify code evolution patterns, commit frequency, and change patterns
    .PARAMETER Path
    Path to analyze for evolution trends
    .PARAMETER DaysBack
    Number of days to look back in history
    .PARAMETER Granularity
    Analysis granularity (Daily, Weekly, Monthly)
    .EXAMPLE
    Get-CodeEvolutionTrend -Path "C:\Project" -DaysBack 30 -Granularity Weekly
    #>
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
        $cached = Get-CacheItem -Key $cacheKey
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
        Set-CacheItem -Key $cacheKey -Value $trend -TTLMinutes 60
        
        return $trend
    }
    catch {
        Write-Error "Failed to analyze code evolution trend: $_"
        return $null
    }
}

function Measure-CodeChurn {
    <#
    .SYNOPSIS
    Measures code churn metrics for a path
    .DESCRIPTION
    Calculates churn rate, addition/deletion rates, and risk assessment based on change patterns
    .PARAMETER Path
    Path to measure churn for
    .PARAMETER DaysBack
    Number of days to analyze
    .EXAMPLE
    Measure-CodeChurn -Path "C:\Project" -DaysBack 30
    #>
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
        
        return $churn
    }
    catch {
        Write-Error "Failed to measure code churn: $_"
        return $null
    }
}

function Get-HotspotAnalysis {
    <#
    .SYNOPSIS
    Identifies hotspots in the codebase
    .DESCRIPTION
    Finds files with high change frequency and complexity, indicating potential problem areas
    .PARAMETER Path
    Path to analyze for hotspots
    .PARAMETER TopN
    Number of top hotspots to return
    .PARAMETER DaysBack
    Number of days to look back for change analysis
    .EXAMPLE
    Get-HotspotAnalysis -Path "C:\Project" -TopN 10 -DaysBack 90
    #>
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

# Export functions
Export-ModuleMember -Function @(
    'Get-CodeEvolutionTrend',
    'Measure-CodeChurn',
    'Get-HotspotAnalysis'
)

Write-Verbose "TrendAnalysis component loaded successfully"
# SIG # Begin signature block
# MIIFzgYJKoZIhvcNAQcCoIIFvzCCBbsCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCAmClzPHCBOi8XD
# 1R9APmSpwxHXGSnyS5ZFXm6H9mK6BqCCAzAwggMsMIICFKADAgECAhB1HRbZIqgr
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
# MAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIEUiHWILI96+hHuVEO997KG1
# z+TYzgbIYYls5njhApA3MA0GCSqGSIb3DQEBAQUABIIBAEF8a0AQ7JFE7JaZ5izj
# I2qXuKxpkbA4alSWcYocmEE2CvCWjf+GSjQ2tTPgGo5IdZMVp2sSdR0roNgkXsc/
# umUYob2/AAGuO3FXyRW8Z+a0L3Ltsns3UYIyurBEfjNflbbRJfk4pRvmLL2/VjBI
# RVdxFrbxmRxcfv1iRFExVmoseYD7mKCSrNVe6GNBwbQzlOFLTlgVENTbELg39d92
# CrsQSlAocKMCcphMjguEnFRokL4qIXHjMdNqyVAmIr8OcHYHfnQ9Tqzv1XWrmBz0
# q/rW1xEDF5qfFZhdMsL0n+rHVkEoeVqba4cezGbJNPvhiXq5tEuwXn+AihljYvEL
# 6Rk=
# SIG # End signature block
