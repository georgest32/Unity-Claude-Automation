# PatternAnalysis.psm1
# Phase 7 Day 3-4 Hours 5-8: Advanced Pattern Analysis
# N-gram modeling and pattern similarity calculations
# Date: 2025-08-25

#region Advanced Pattern Analysis

# Build n-gram model for pattern analysis
function Build-NGramModel {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Text,
        
        [Parameter()]
        [int]$N = 3,
        
        [Parameter()]
        [switch]$IncludeStatistics
    )
    
    Write-DecisionLog "Building $N-gram model from text (length: $($Text.Length))" "DEBUG"
    
    $ngrams = @{}
    $words = $Text -split '\s+' | Where-Object { $_ -ne '' }
    
    if ($words.Count -lt $N) {
        Write-DecisionLog "Text too short for $N-gram analysis" "WARN"
        return @{
            NGrams = @{}
            Count = 0
            N = $N
        }
    }
    
    # Generate n-grams (PowerShell 5.1 compatible)
    for ($i = 0; $i -le ($words.Count - $N); $i++) {
        $ngramWords = @()
        for ($j = $i; $j -lt ($i + $N); $j++) {
            $ngramWords += $words[$j]
        }
        $ngram = $ngramWords -join ' '
        if ($ngrams.ContainsKey($ngram)) {
            $ngrams[$ngram]++
        } else {
            $ngrams[$ngram] = 1
        }
    }
    
    $result = @{
        NGrams = $ngrams
        Count = $ngrams.Count
        N = $N
        TotalWords = $words.Count
    }
    
    if ($IncludeStatistics) {
        # Calculate frequency statistics
        $frequencies = $ngrams.Values | Sort-Object -Descending
        $result.Statistics = @{
            MostCommon = ($ngrams.GetEnumerator() | Sort-Object Value -Descending | Select-Object -First 5)
            UniqueNGrams = $ngrams.Count
            TotalNGrams = ($frequencies | Measure-Object -Sum).Sum
            MaxFrequency = if ($frequencies.Count -gt 0) { $frequencies[0] } else { 0 }
            MeanFrequency = if ($frequencies.Count -gt 0) { ($frequencies | Measure-Object -Average).Average } else { 0 }
        }
    }
    
    return $result
}

# Calculate pattern similarity using multiple metrics
function Calculate-PatternSimilarity {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Pattern1,
        
        [Parameter(Mandatory = $true)]
        [string]$Pattern2,
        
        [Parameter()]
        [ValidateSet('Jaccard', 'Cosine', 'Levenshtein', 'All')]
        [string]$Method = 'All'
    )
    
    Write-DecisionLog "Calculating pattern similarity using method: $Method" "DEBUG"
    
    $similarities = @{}
    
    # Jaccard similarity
    if ($Method -eq 'Jaccard' -or $Method -eq 'All') {
        $set1 = $Pattern1 -split '\s+' | Where-Object { $_ -ne '' } | Sort-Object -Unique
        $set2 = $Pattern2 -split '\s+' | Where-Object { $_ -ne '' } | Sort-Object -Unique
        
        $intersection = $set1 | Where-Object { $_ -in $set2 }
        $union = $set1 + $set2 | Sort-Object -Unique
        
        if ($union.Count -gt 0) {
            $similarities.Jaccard = [Math]::Round($intersection.Count / $union.Count, 4)
        } else {
            $similarities.Jaccard = 0.0
        }
    }
    
    # Cosine similarity
    if ($Method -eq 'Cosine' -or $Method -eq 'All') {
        $words1 = $Pattern1 -split '\s+' | Where-Object { $_ -ne '' }
        $words2 = $Pattern2 -split '\s+' | Where-Object { $_ -ne '' }
        
        # Create term frequency vectors
        $allWords = $words1 + $words2 | Sort-Object -Unique
        $vector1 = @{}
        $vector2 = @{}
        
        foreach ($word in $allWords) {
            $vector1[$word] = ($words1 | Where-Object { $_ -eq $word }).Count
            $vector2[$word] = ($words2 | Where-Object { $_ -eq $word }).Count
        }
        
        # Calculate dot product and magnitudes
        $dotProduct = 0
        $magnitude1 = 0
        $magnitude2 = 0
        
        foreach ($word in $allWords) {
            $dotProduct += $vector1[$word] * $vector2[$word]
            $magnitude1 += $vector1[$word] * $vector1[$word]
            $magnitude2 += $vector2[$word] * $vector2[$word]
        }
        
        if ($magnitude1 -gt 0 -and $magnitude2 -gt 0) {
            $similarities.Cosine = [Math]::Round($dotProduct / ([Math]::Sqrt($magnitude1) * [Math]::Sqrt($magnitude2)), 4)
        } else {
            $similarities.Cosine = 0.0
        }
    }
    
    # Levenshtein distance (normalized)
    if ($Method -eq 'Levenshtein' -or $Method -eq 'All') {
        $distance = Get-LevenshteinDistance -String1 $Pattern1 -String2 $Pattern2
        $maxLength = [Math]::Max($Pattern1.Length, $Pattern2.Length)
        if ($maxLength -gt 0) {
            $similarities.Levenshtein = [Math]::Round(1 - ($distance / $maxLength), 4)
        } else {
            $similarities.Levenshtein = 1.0
        }
    }
    
    # Calculate combined similarity if all methods used
    if ($Method -eq 'All' -and $similarities.Count -gt 0) {
        $similarities.Combined = [Math]::Round(($similarities.Values | Measure-Object -Average).Average, 4)
    }
    
    return $similarities
}

# Calculate Levenshtein distance
function Get-LevenshteinDistance {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$String1,
        
        [Parameter(Mandatory = $true)]
        [string]$String2
    )
    
    $len1 = $String1.Length
    $len2 = $String2.Length
    
    # Create distance matrix
    $matrix = New-Object 'int[,]' ($len1 + 1), ($len2 + 1)
    
    # Initialize first column and row
    for ($i = 0; $i -le $len1; $i++) {
        $matrix[$i, 0] = $i
    }
    for ($j = 0; $j -le $len2; $j++) {
        $matrix[0, $j] = $j
    }
    
    # Calculate distances
    for ($i = 1; $i -le $len1; $i++) {
        for ($j = 1; $j -le $len2; $j++) {
            $cost = if ($String1[$i - 1] -eq $String2[$j - 1]) { 0 } else { 1 }
            
            $matrix[$i, $j] = [Math]::Min(
                [Math]::Min(
                    $matrix[$i - 1, $j] + 1,      # Deletion
                    $matrix[$i, $j - 1] + 1       # Insertion
                ),
                $matrix[$i - 1, $j - 1] + $cost   # Substitution
            )
        }
    }
    
    return $matrix[$len1, $len2]
}

#endregion

# Export pattern analysis functions
Export-ModuleMember -Function Build-NGramModel, Calculate-PatternSimilarity, Get-LevenshteinDistance
# SIG # Begin signature block
# MIIFzgYJKoZIhvcNAQcCoIIFvzCCBbsCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCAEHSotuBOSlefH
# WhJzpAs/BVzdUU4VFiH5MWXKb7X5JaCCAzAwggMsMIICFKADAgECAhB1HRbZIqgr
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
# MAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIGZUbenuNrWsgk5Hs1QMC30i
# Gerxf8Pwh4Xl2PO8yWi/MA0GCSqGSIb3DQEBAQUABIIBAIw1XOqptHJkpEfZp7kX
# ny2qzsFt+XGCTwDfx+tcQiZd5zy1vlGqMvhAARRptDhF4oYFy1DR8KVpTXviGEf8
# rhgbxgkyxChBgLB/n9RVS5SFxIdmL8nb0gFrhxBNk5Vad8gyZvu/BgTS9IIXzQUz
# JME18wNF/o4BFqdHPgTIaiR8Mv3TIg47rs6aEbp4J3kp6gMTghpOONjHgmAi6hoT
# f1s2bwYUHNhnbucFbV8sYjeoxqlMIJhAhB1yH26QuDNgmUipcA3oXANhs9kKx7jf
# 4gII99/HzQvgWGiRuZBCB2zj/62hiA2A7qHplOP2flJphQ5m/2wqD1h3ZPZWBP0s
# PiA=
# SIG # End signature block
