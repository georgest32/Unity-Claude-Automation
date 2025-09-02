# TemporalContextTracking.psm1
# Phase 7 Day 3-4 Hours 5-8: Temporal Context and Time-Series Analysis
# Temporal decision patterns and context relevance analysis
# Date: 2025-08-25

#region Temporal Context Tracking

# Temporal context storage
$script:TemporalContext = @{
    RecentDecisions = New-Object System.Collections.Queue
    MaxHistorySize = 50
    TimeWindows = @{
        Immediate = 60      # 1 minute
        Recent = 300        # 5 minutes
        Short = 1800        # 30 minutes
        Medium = 7200       # 2 hours
        Long = 86400        # 24 hours
    }
}

# Add temporal context to decision
function Add-TemporalContext {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [hashtable]$Decision,
        
        [Parameter()]
        [int]$TimeWindowSeconds = 300
    )
    
    Write-DecisionLog "Adding temporal context with window: ${TimeWindowSeconds}s" "DEBUG"
    
    $now = Get-Date
    $decision.Timestamp = $now
    
    # Add to recent decisions queue
    $script:TemporalContext.RecentDecisions.Enqueue($decision)
    
    # Maintain queue size
    while ($script:TemporalContext.RecentDecisions.Count -gt $script:TemporalContext.MaxHistorySize) {
        $script:TemporalContext.RecentDecisions.Dequeue() | Out-Null
    }
    
    # Analyze recent patterns
    $recentDecisions = @($script:TemporalContext.RecentDecisions.ToArray() | 
        Where-Object { ($now - $_.Timestamp).TotalSeconds -le $TimeWindowSeconds })
    
    $temporalAnalysis = @{
        WindowSize = $TimeWindowSeconds
        DecisionCount = $recentDecisions.Count
        TimeRange = if ($recentDecisions.Count -gt 0) {
            @{
                Start = ($recentDecisions | Sort-Object Timestamp | Select-Object -First 1).Timestamp
                End = $now
            }
        } else { @{} }
    }
    
    # Analyze decision type frequency
    if ($recentDecisions.Count -gt 0) {
        $typeFrequency = $recentDecisions | Group-Object DecisionType | ForEach-Object {
            @{
                Type = $_.Name
                Count = $_.Count
                Percentage = [Math]::Round(($_.Count / $recentDecisions.Count) * 100, 2)
            }
        } | Sort-Object Count -Descending
        
        $temporalAnalysis.TypeFrequency = $typeFrequency
        $temporalAnalysis.DominantType = $typeFrequency[0].Type
        
        # Calculate decision velocity (decisions per minute)
        $timeSpan = ($now - $temporalAnalysis.TimeRange.Start).TotalMinutes
        if ($timeSpan -gt 0) {
            $temporalAnalysis.DecisionVelocity = [Math]::Round($recentDecisions.Count / $timeSpan, 2)
        }
        
        # Detect patterns
        $temporalAnalysis.Patterns = @{
            Repetitive = ($typeFrequency[0].Percentage -gt 60)
            HighVelocity = ($temporalAnalysis.DecisionVelocity -gt 10)
            LowVariety = ($typeFrequency.Count -le 2)
        }
    }
    
    $decision.TemporalContext = $temporalAnalysis
    
    return $decision
}

# Get temporal context relevance
function Get-TemporalContextRelevance {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$DecisionType,
        
        [Parameter()]
        [string]$TimeWindow = 'Recent'
    )
    
    $windowSeconds = $script:TemporalContext.TimeWindows[$TimeWindow]
    if (-not $windowSeconds) {
        Write-DecisionLog "Unknown time window: $TimeWindow - using Recent" "WARN"
        $windowSeconds = $script:TemporalContext.TimeWindows.Recent
    }
    
    $now = Get-Date
    $relevantDecisions = @($script:TemporalContext.RecentDecisions.ToArray() | 
        Where-Object { 
            ($now - $_.Timestamp).TotalSeconds -le $windowSeconds -and
            $_.DecisionType -eq $DecisionType
        })
    
    if ($relevantDecisions.Count -eq 0) {
        return @{
            Relevance = 0.5  # Neutral relevance
            SampleSize = 0
            TimeWindow = $TimeWindow
            Message = "No recent decisions of type $DecisionType"
        }
    }
    
    # Calculate success rate
    $successCount = @($relevantDecisions | Where-Object { $_.Success -eq $true }).Count
    $successRate = $successCount / $relevantDecisions.Count
    
    # Calculate recency weight (more recent = higher weight)
    $weights = $relevantDecisions | ForEach-Object {
        $age = ($now - $_.Timestamp).TotalSeconds
        1 - ($age / $windowSeconds)  # Linear decay
    }
    $averageWeight = ($weights | Measure-Object -Average).Average
    
    # Combine success rate and recency
    $relevance = ($successRate * 0.7) + ($averageWeight * 0.3)
    
    return @{
        Relevance = [Math]::Round($relevance, 3)
        SampleSize = $relevantDecisions.Count
        TimeWindow = $TimeWindow
        SuccessRate = [Math]::Round($successRate, 3)
        RecencyFactor = [Math]::Round($averageWeight, 3)
        Message = "Based on $($relevantDecisions.Count) recent decisions"
    }
}

#endregion

# Export temporal context functions
Export-ModuleMember -Function Add-TemporalContext, Get-TemporalContextRelevance -Variable TemporalContext
# SIG # Begin signature block
# MIIFzgYJKoZIhvcNAQcCoIIFvzCCBbsCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCAgVHTehFSnQM4r
# u8QESrAJenF0ce/W9HvZgWgNTyc2SKCCAzAwggMsMIICFKADAgECAhB1HRbZIqgr
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
# MAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIAy4pCb6BOKau+25EwGHCLTH
# fWV4aA8AQWO+qvhMZtBjMA0GCSqGSIb3DQEBAQUABIIBAGBvKw7P2CUC7vv0YFYW
# nAqUMq4krv+OYNAebF2r1hrnxfmT5zWVuOpDbGmoo+ppFy0jQtMEKse4NzXgM525
# xzuC65IJNM18Aeqygl4TbDBeid6g5i9z/HJ+gbOvxtOqYanTXLWWDEw4TlIuRkKi
# VWduTsAHisyspo/dYzEGTKG7sLvm5DUgdfRiRYcEQVDeJBu5dKuQ1UbIzwSQHATl
# 5/AIN1BEfgjwnx8EMOWCx1kaX2Skj/6EoKJg3+/gx4YPVbTTqst9kln+m09FwYzF
# AaMsGeGDpVilARtKtye1WDNW/OSg4PVVK+PzGe8gMTvRVMq1kq/TMo7M+kNI9ukU
# wA4=
# SIG # End signature block
