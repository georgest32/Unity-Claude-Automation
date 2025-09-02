# ConfidenceBands.psm1
# Phase 7 Day 3-4 Hours 5-8: Confidence Band Classification
# Confidence band determination and pattern confidence calculations
# Date: 2025-08-25

#region Confidence Band Functions

# Determine confidence band based on adjusted confidence
function Get-ConfidenceBand {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [double]$Confidence
    )
    
    $bands = $script:BayesianConfig.ConfidenceBands
    
    if ($Confidence -ge $bands.VeryHigh) {
        return "VeryHigh"
    } elseif ($Confidence -ge $bands.High) {
        return "High"
    } elseif ($Confidence -ge $bands.Medium) {
        return "Medium"
    } elseif ($Confidence -ge $bands.Low) {
        return "Low"
    } else {
        return "VeryLow"
    }
}

# Calculate pattern confidence based on historical patterns
function Calculate-PatternConfidence {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [array]$Patterns,
        
        [Parameter()]
        [hashtable]$HistoricalPatterns = @{}
    )
    
    Write-DecisionLog "Calculating pattern confidence for $($Patterns.Count) patterns" "DEBUG"
    
    $totalConfidence = 0.0
    $weightSum = 0.0
    
    foreach ($pattern in $Patterns) {
        $patternKey = "$($pattern.Type)_$($pattern.Category)"
        
        # Base confidence from pattern
        $baseConfidence = $pattern.Confidence
        
        # Historical adjustment if available
        if ($HistoricalPatterns.ContainsKey($patternKey)) {
            $historical = $HistoricalPatterns[$patternKey]
            $successRate = $historical.SuccessCount / [Math]::Max(1, $historical.TotalCount)
            $adjustedConfidence = ($baseConfidence * 0.6) + ($successRate * 0.4)
        } else {
            $adjustedConfidence = $baseConfidence
        }
        
        # Weight by pattern priority
        $weight = switch ($pattern.Priority) {
            1 { 1.5 }
            2 { 1.2 }
            3 { 1.0 }
            4 { 0.8 }
            default { 0.5 }
        }
        
        $totalConfidence += $adjustedConfidence * $weight
        $weightSum += $weight
    }
    
    if ($weightSum -gt 0) {
        $averageConfidence = $totalConfidence / $weightSum
    } else {
        $averageConfidence = 0.5  # Default confidence
    }
    
    return @{
        PatternConfidence = $averageConfidence
        PatternCount = $Patterns.Count
        ConfidenceBand = Get-ConfidenceBand -Confidence $averageConfidence
        WeightedScore = $totalConfidence
    }
}

#endregion

# Export confidence band functions
Export-ModuleMember -Function Get-ConfidenceBand, Calculate-PatternConfidence
# SIG # Begin signature block
# MIIFzgYJKoZIhvcNAQcCoIIFvzCCBbsCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCCbc2oOZpSZq7U6
# G/oHotLltUaRU8MOePQMw+EVuS5msKCCAzAwggMsMIICFKADAgECAhB1HRbZIqgr
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
# MAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIHcgKe+NkH+F3pHU+ZFRJEER
# KGC8/Rlu+B+yt4Sb4LFDMA0GCSqGSIb3DQEBAQUABIIBABY4eu3sWNgzNuy43NFN
# EknzzJS9tqzAcdkNkTdsN0orp7rEyJtRnLoeuzWkvnf8k1wdF9oxpeejnsdSSKQX
# 6EI3nQgGLoWJRN05DQYBKbCctYJoJ3YIAR5l3ahAicGEjGk0hBl0UiP/wQlcSBh4
# zS0yidgHh9mvbpLV7VsX9lgnj5mq3OPOTutINdYAf5FWHSy6OE4fDoxpp37QYvMV
# mIm2MAd0nsdZjUGOZPY6MHzizzKcyG11kZSzva7VDf1V3am8j94v3e88wauyUzU3
# BgnoGvko1T67+zLQqWgRQz8+8YwtzlNzc8NSzSZWnSpjFijCNw2+vm0UQ4LHJM8r
# MNg=
# SIG # End signature block
