# Unity-Claude-Learning String Similarity Component
# String matching and similarity algorithms
# Part of refactored Learning module

$ErrorActionPreference = "Stop"

# Import core component
$CorePath = Join-Path $PSScriptRoot "LearningCore.psm1"
Import-Module $CorePath -Force

#region String Similarity Functions

function Get-StringSimilarity {
    <#
    .SYNOPSIS
    Calculates similarity between two strings using Levenshtein distance
    .DESCRIPTION
    Returns a normalized similarity score from 0.0 (completely different) to 1.0 (identical)
    .PARAMETER String1
    First string to compare
    .PARAMETER String2
    Second string to compare
    .PARAMETER Algorithm
    Algorithm to use (Levenshtein, JaroWinkler, NGram)
    .EXAMPLE
    Get-StringSimilarity -String1 "hello" -String2 "hallo"
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$String1,
        
        [Parameter(Mandatory)]
        [string]$String2,
        
        [ValidateSet('Levenshtein', 'JaroWinkler', 'NGram')]
        [string]$Algorithm = 'Levenshtein'
    )
    
    # Quick checks
    if ($String1 -eq $String2) { return 1.0 }
    if ([string]::IsNullOrWhiteSpace($String1) -or [string]::IsNullOrWhiteSpace($String2)) { return 0.0 }
    
    switch ($Algorithm) {
        'Levenshtein' {
            $distance = Get-LevenshteinDistance -String1 $String1 -String2 $String2
            $maxLength = [Math]::Max($String1.Length, $String2.Length)
            return [Math]::Max(0, 1.0 - ($distance / $maxLength))
        }
        'JaroWinkler' {
            return Get-JaroWinklerSimilarity -String1 $String1 -String2 $String2
        }
        'NGram' {
            return Get-NGramSimilarity -String1 $String1 -String2 $String2 -N 3
        }
        default {
            return Get-LevenshteinSimilarity -String1 $String1 -String2 $String2
        }
    }
}

function Get-LevenshteinDistance {
    <#
    .SYNOPSIS
    Calculates the Levenshtein edit distance between two strings
    .DESCRIPTION
    Returns the minimum number of single-character edits required
    .PARAMETER String1
    First string
    .PARAMETER String2
    Second string
    .EXAMPLE
    Get-LevenshteinDistance -String1 "kitten" -String2 "sitting"
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$String1,
        
        [Parameter(Mandatory)]
        [string]$String2
    )
    
    $len1 = $String1.Length
    $len2 = $String2.Length
    
    # Optimization: if one string is empty
    if ($len1 -eq 0) { return $len2 }
    if ($len2 -eq 0) { return $len1 }
    
    # Create distance matrix
    $matrix = New-Object 'int[,]' ($len1 + 1), ($len2 + 1)
    
    # Initialize first row and column
    for ($i = 0; $i -le $len1; $i++) { $matrix[$i, 0] = $i }
    for ($j = 0; $j -le $len2; $j++) { $matrix[0, $j] = $j }
    
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

function Get-LevenshteinSimilarity {
    <#
    .SYNOPSIS
    Calculates normalized Levenshtein similarity score
    .DESCRIPTION
    Returns a score from 0.0 to 1.0 based on Levenshtein distance
    .PARAMETER String1
    First string
    .PARAMETER String2
    Second string
    .EXAMPLE
    Get-LevenshteinSimilarity -String1 "test" -String2 "text"
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$String1,
        
        [Parameter(Mandatory)]
        [string]$String2
    )
    
    if ($String1 -eq $String2) { return 1.0 }
    
    $distance = Get-LevenshteinDistance -String1 $String1 -String2 $String2
    $maxLength = [Math]::Max($String1.Length, $String2.Length)
    
    if ($maxLength -eq 0) { return 0.0 }
    
    return [Math]::Max(0, 1.0 - ($distance / $maxLength))
}

function Get-JaroWinklerSimilarity {
    <#
    .SYNOPSIS
    Calculates Jaro-Winkler similarity between strings
    .DESCRIPTION
    Better for short strings and typo detection
    .PARAMETER String1
    First string
    .PARAMETER String2
    Second string
    .PARAMETER PrefixScale
    Scaling factor for common prefix (default 0.1)
    .EXAMPLE
    Get-JaroWinklerSimilarity -String1 "martha" -String2 "marhta"
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$String1,
        
        [Parameter(Mandatory)]
        [string]$String2,
        
        [double]$PrefixScale = 0.1
    )
    
    # Get Jaro similarity first
    $jaro = Get-JaroSimilarity -String1 $String1 -String2 $String2
    
    if ($jaro -lt 0.7) {
        return $jaro
    }
    
    # Calculate common prefix length (up to 4 characters)
    $prefix = 0
    $maxPrefix = [Math]::Min(4, [Math]::Min($String1.Length, $String2.Length))
    
    for ($i = 0; $i -lt $maxPrefix; $i++) {
        if ($String1[$i] -eq $String2[$i]) {
            $prefix++
        } else {
            break
        }
    }
    
    # Jaro-Winkler similarity
    return $jaro + ($prefix * $PrefixScale * (1 - $jaro))
}

function Get-JaroSimilarity {
    <#
    .SYNOPSIS
    Calculates Jaro similarity between strings
    .DESCRIPTION
    Base Jaro algorithm without Winkler modification
    .PARAMETER String1
    First string
    .PARAMETER String2
    Second string
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$String1,
        
        [Parameter(Mandatory)]
        [string]$String2
    )
    
    if ($String1 -eq $String2) { return 1.0 }
    
    $len1 = $String1.Length
    $len2 = $String2.Length
    
    if ($len1 -eq 0 -and $len2 -eq 0) { return 1.0 }
    if ($len1 -eq 0 -or $len2 -eq 0) { return 0.0 }
    
    # Calculate match window
    $matchWindow = ([Math]::Max($len1, $len2) / 2) - 1
    $matchWindow = [Math]::Max(0, $matchWindow)
    
    $s1Matches = New-Object bool[] $len1
    $s2Matches = New-Object bool[] $len2
    
    $matches = 0
    $transpositions = 0
    
    # Find matches
    for ($i = 0; $i -lt $len1; $i++) {
        $start = [Math]::Max(0, $i - $matchWindow)
        $end = [Math]::Min($i + $matchWindow + 1, $len2)
        
        for ($j = $start; $j -lt $end; $j++) {
            if ($s2Matches[$j] -or $String1[$i] -ne $String2[$j]) {
                continue
            }
            
            $s1Matches[$i] = $true
            $s2Matches[$j] = $true
            $matches++
            break
        }
    }
    
    if ($matches -eq 0) { return 0.0 }
    
    # Count transpositions
    $k = 0
    for ($i = 0; $i -lt $len1; $i++) {
        if (-not $s1Matches[$i]) { continue }
        
        while (-not $s2Matches[$k]) { $k++ }
        
        if ($String1[$i] -ne $String2[$k]) {
            $transpositions++
        }
        $k++
    }
    
    # Calculate Jaro similarity
    return ($matches / $len1 + $matches / $len2 + ($matches - $transpositions / 2) / $matches) / 3
}

function Get-NGramSimilarity {
    <#
    .SYNOPSIS
    Calculates N-gram based similarity
    .DESCRIPTION
    Compares strings based on common n-grams
    .PARAMETER String1
    First string
    .PARAMETER String2
    Second string
    .PARAMETER N
    Size of n-grams (default 3)
    .EXAMPLE
    Get-NGramSimilarity -String1 "hello" -String2 "hallo" -N 2
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$String1,
        
        [Parameter(Mandatory)]
        [string]$String2,
        
        [int]$N = 3
    )
    
    if ($String1 -eq $String2) { return 1.0 }
    if ($String1.Length -lt $N -or $String2.Length -lt $N) {
        # Fall back to character-level comparison
        return Get-LevenshteinSimilarity -String1 $String1 -String2 $String2
    }
    
    # Generate n-grams
    $ngrams1 = Get-NGrams -Text $String1 -N $N
    $ngrams2 = Get-NGrams -Text $String2 -N $N
    
    if ($ngrams1.Count -eq 0 -or $ngrams2.Count -eq 0) {
        return 0.0
    }
    
    # Calculate Jaccard similarity
    $intersection = $ngrams1 | Where-Object { $ngrams2 -contains $_ }
    $union = $ngrams1 + $ngrams2 | Select-Object -Unique
    
    return $intersection.Count / $union.Count
}

function Get-NGrams {
    <#
    .SYNOPSIS
    Generates n-grams from text
    .PARAMETER Text
    Input text
    .PARAMETER N
    Size of n-grams
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Text,
        
        [int]$N = 3
    )
    
    $ngrams = @()
    
    if ($Text.Length -ge $N) {
        for ($i = 0; $i -le ($Text.Length - $N); $i++) {
            $ngrams += $Text.Substring($i, $N)
        }
    }
    
    return $ngrams
}

function Get-ErrorSignature {
    <#
    .SYNOPSIS
    Creates normalized error signature for pattern matching
    .DESCRIPTION
    Normalizes error text for consistent pattern matching
    .PARAMETER ErrorText
    Raw error text
    .EXAMPLE
    Get-ErrorSignature -ErrorText "CS0246: The type or namespace 'Foo' could not be found"
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$ErrorText
    )
    
    # Remove timestamps
    $signature = $ErrorText -replace '\d{4}-\d{2}-\d{2}[\s\-]\d{2}:\d{2}:\d{2}', ''
    
    # Remove line numbers
    $signature = $signature -replace '\(\d+,\d+\)', ''
    $signature = $signature -replace 'line \d+', 'line N'
    
    # Normalize paths
    $signature = $signature -replace '[A-Za-z]:\\[^:]*\\', 'PATH\'
    $signature = $signature -replace '\/[^:]*\/', 'PATH/'
    
    # Remove GUIDs
    $signature = $signature -replace '[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}', 'GUID'
    
    # Trim and normalize whitespace
    $signature = $signature.Trim() -replace '\s+', ' '
    
    return $signature
}

#endregion

# Export functions
Export-ModuleMember -Function @(
    'Get-StringSimilarity',
    'Get-LevenshteinDistance',
    'Get-LevenshteinSimilarity',
    'Get-JaroWinklerSimilarity',
    'Get-JaroSimilarity',
    'Get-NGramSimilarity',
    'Get-NGrams',
    'Get-ErrorSignature'
)

if (Get-Command Write-ModuleLog -ErrorAction SilentlyContinue) {
    Write-ModuleLog -Message "StringSimilarity component loaded successfully" -Level "DEBUG"
} else {
    Write-Verbose "[StringSimilarity] Component loaded successfully"
}
# SIG # Begin signature block
# MIIFzgYJKoZIhvcNAQcCoIIFvzCCBbsCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCD7my1TFb5YAHop
# I1ZiZS5ggjj2lVkwXXbTAEyiOb8aY6CCAzAwggMsMIICFKADAgECAhB1HRbZIqgr
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
# MAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIDuvJvhdhOKxgpGB5diWNCXq
# hmn/H8iITaUCy3I5kvb/MA0GCSqGSIb3DQEBAQUABIIBADjRCXDdmRx82o7pXnPT
# h5qx3934DH24y9iPEzL7AdQ3Ldy4g7V/h9phjkfciOufgo+cHH8sBmhD6kH9RXX7
# t3I5TkaLaqoyCHPIJlMA7zG40U03R5rzZIKc4SfItwcvns4ztI0deG3rvdLQ4uOW
# 68YL7uMDoTAyCUlba2V83BXkjemG4qzb7FwrdKJQ1yKgFf8Yo1yqnxoC7VACCgJu
# yR+t8JJvEKDfk5LKZHeON2DOjowbKh7ai/Nvr+gEJQyjmrhHPkzAcqSaBdpJoYa0
# eoY+kozMR+TD3lZWp31JGTZFLGr8idQeqnTqMyVdcIqa5xcNeXd2AojjMKsmtgjA
# 7Vk=
# SIG # End signature block
