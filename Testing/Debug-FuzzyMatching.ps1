# Debug-FuzzyMatching.ps1
# Debug script to manually test failing fuzzy matching calculations
# This will show verbose output for each calculation to understand why tests fail

param(
    [switch]$Verbose
)

if ($Verbose) {
    $VerbosePreference = 'Continue'
}

# Add module path
$modulePath = Join-Path (Split-Path $PSScriptRoot) 'Modules'
if ($env:PSModulePath -notlike "*$modulePath*") {
    $env:PSModulePath = "$modulePath;$env:PSModulePath"
}

Write-Host "`n=== FUZZY MATCHING DEBUG ANALYSIS ===" -ForegroundColor Cyan
Write-Host "Analyzing failing test cases with detailed output" -ForegroundColor Yellow

# Load module
Write-Host "`nLoading module..." -ForegroundColor Gray
Import-Module Unity-Claude-Learning-Simple -Force

Write-Host "`n=== TEST 1: Unity Error Patterns Similarity ===" -ForegroundColor Cyan
Write-Host "This test checks if similarity values meet expected thresholds" -ForegroundColor Gray

# Test Case 1A
$str1a = "CS0246: GameObject not found"
$str2a = "CS0246: GameObject could not be found"
Write-Host "`nComparing:" -ForegroundColor Yellow
Write-Host "  String 1: '$str1a' (Length: $($str1a.Length))" -ForegroundColor Gray
Write-Host "  String 2: '$str2a' (Length: $($str2a.Length))" -ForegroundColor Gray

$distance1 = Get-LevenshteinDistance -String1 $str1a -String2 $str2a -UseCache $false
$similarity1 = Get-StringSimilarity -String1 $str1a -String2 $str2a

Write-Host "`nResults:" -ForegroundColor Yellow
Write-Host "  Levenshtein Distance: $distance1" -ForegroundColor White
Write-Host "  Max Length: $([Math]::Max($str1a.Length, $str2a.Length))" -ForegroundColor White
Write-Host "  Similarity: $similarity1%" -ForegroundColor $(if ($similarity1 -gt 70) { "Green" } else { "Red" })
Write-Host "  Expected: > 70%" -ForegroundColor Gray
Write-Host "  Test Result: $(if ($similarity1 -gt 70) { "[PASS]" } else { "[FAIL]" })" -ForegroundColor $(if ($similarity1 -gt 70) { "Green" } else { "Red" })

# Test Case 1B
$str1b = "NullReferenceException"
$str2b = "NullReference"
Write-Host "`nComparing:" -ForegroundColor Yellow
Write-Host "  String 1: '$str1b' (Length: $($str1b.Length))" -ForegroundColor Gray
Write-Host "  String 2: '$str2b' (Length: $($str2b.Length))" -ForegroundColor Gray

$distance2 = Get-LevenshteinDistance -String1 $str1b -String2 $str2b -UseCache $false
$similarity2 = Get-StringSimilarity -String1 $str1b -String2 $str2b

Write-Host "`nResults:" -ForegroundColor Yellow
Write-Host "  Levenshtein Distance: $distance2" -ForegroundColor White
Write-Host "  Max Length: $([Math]::Max($str1b.Length, $str2b.Length))" -ForegroundColor White
Write-Host "  Similarity: $similarity2%" -ForegroundColor $(if ($similarity2 -ge 59) { "Green" } else { "Red" })
Write-Host "  Expected: >= 59%" -ForegroundColor Gray
Write-Host "  Test Result: $(if ($similarity2 -ge 59) { "[PASS]" } else { "[FAIL]" })" -ForegroundColor $(if ($similarity2 -ge 59) { "Green" } else { "Red" })

# Combined test result
$test1Pass = ($similarity1 -gt 70) -and ($similarity2 -ge 59)
Write-Host "`nCombined Test 1 Result: $(if ($test1Pass) { "[PASS]" } else { "[FAIL]" })" -ForegroundColor $(if ($test1Pass) { "Green" } else { "Red" })

Write-Host "`n=== TEST 2: Fuzzy Match - Error Messages ===" -ForegroundColor Cyan
Write-Host "This test checks fuzzy matching with specific thresholds" -ForegroundColor Gray

# Test Case 2A
$str2a1 = "CS0246: The type or namespace 'GameObject' could not be found"
$str2a2 = "CS0246: GameObject not found"
Write-Host "`nComparing:" -ForegroundColor Yellow
Write-Host "  String 1: '$str2a1'" -ForegroundColor Gray
Write-Host "           (Length: $($str2a1.Length))" -ForegroundColor Gray
Write-Host "  String 2: '$str2a2'" -ForegroundColor Gray
Write-Host "           (Length: $($str2a2.Length))" -ForegroundColor Gray

$match2a = Test-FuzzyMatch -String1 $str2a1 -String2 $str2a2 -MinSimilarity 45
$sim2a = Get-StringSimilarity -String1 $str2a1 -String2 $str2a2
$dist2a = Get-LevenshteinDistance -String1 $str2a1 -String2 $str2a2 -UseCache $false

Write-Host "`nResults:" -ForegroundColor Yellow
Write-Host "  Levenshtein Distance: $dist2a" -ForegroundColor White
Write-Host "  Similarity: $sim2a%" -ForegroundColor White
Write-Host "  Threshold: 45%" -ForegroundColor Gray
Write-Host "  Fuzzy Match: $match2a" -ForegroundColor $(if ($match2a) { "Green" } else { "Red" })
Write-Host "  Test Result: $(if ($match2a) { "[PASS]" } else { "[FAIL]" })" -ForegroundColor $(if ($match2a) { "Green" } else { "Red" })

# Test Case 2B
$str2b1 = "Missing using directive"
$str2b2 = "Missing using statement"
Write-Host "`nComparing:" -ForegroundColor Yellow
Write-Host "  String 1: '$str2b1' (Length: $($str2b1.Length))" -ForegroundColor Gray
Write-Host "  String 2: '$str2b2' (Length: $($str2b2.Length))" -ForegroundColor Gray

$match2b = Test-FuzzyMatch -String1 $str2b1 -String2 $str2b2 -MinSimilarity 60
$sim2b = Get-StringSimilarity -String1 $str2b1 -String2 $str2b2
$dist2b = Get-LevenshteinDistance -String1 $str2b1 -String2 $str2b2 -UseCache $false

Write-Host "`nResults:" -ForegroundColor Yellow
Write-Host "  Levenshtein Distance: $dist2b" -ForegroundColor White
Write-Host "  Similarity: $sim2b%" -ForegroundColor White
Write-Host "  Threshold: 60%" -ForegroundColor Gray
Write-Host "  Fuzzy Match: $match2b" -ForegroundColor $(if ($match2b) { "Green" } else { "Red" })
Write-Host "  Test Result: $(if ($match2b) { "[PASS]" } else { "[FAIL]" })" -ForegroundColor $(if ($match2b) { "Green" } else { "Red" })

# Combined test result
$test2Pass = $match2a -and $match2b
Write-Host "`nCombined Test 2 Result: $(if ($test2Pass) { "[PASS]" } else { "[FAIL]" })" -ForegroundColor $(if ($test2Pass) { "Green" } else { "Red" })

Write-Host "`n=== TEST 3: Find Similar Patterns ===" -ForegroundColor Cyan
Write-Host "This test checks pattern storage and retrieval" -ForegroundColor Gray

# Initialize storage - this loads existing patterns
Write-Host "`nInitializing storage..." -ForegroundColor Gray
Initialize-LearningStorage | Out-Null

# Add test patterns
Write-Host "Adding test patterns..." -ForegroundColor Gray
$p1 = Add-ErrorPattern -ErrorMessage "CS0246: GameObject could not be found" -Fix "using UnityEngine;"
$p2 = Add-ErrorPattern -ErrorMessage "CS0246: The type GameObject was not found" -Fix "using UnityEngine;"

Write-Host "Pattern 1 ID: $p1" -ForegroundColor Gray
Write-Host "Pattern 2 ID: $p2" -ForegroundColor Gray

# Verify patterns were added (p1 and p2 are just IDs, not objects)
if ($p1 -and $p2) {
    Write-Host "Patterns successfully added with IDs" -ForegroundColor Green
} else {
    Write-Host "WARNING: Pattern addition may have failed" -ForegroundColor Yellow
}

# Search for similar patterns
$searchQuery = "CS0246: GameObject not found"
Write-Host "`nSearching for patterns similar to: '$searchQuery'" -ForegroundColor Yellow
Write-Host "Minimum similarity threshold: 70%" -ForegroundColor Gray

# Get current patterns count for debugging
$config = Get-LearningConfig
Write-Host "Current patterns file: $($config.PatternsFile)" -ForegroundColor Gray
if (Test-Path $config.PatternsFile) {
    $jsonContent = Get-Content $config.PatternsFile -Raw | ConvertFrom-Json
    $patternCount = ($jsonContent | Get-Member -MemberType NoteProperty).Count
    Write-Host "Patterns in file: $patternCount" -ForegroundColor Gray
}

$similar = Find-SimilarPatterns -ErrorMessage $searchQuery -MinSimilarity 70 -Verbose

Write-Host "`nResults:" -ForegroundColor Yellow
if ($similar -and $similar.Count -gt 0) {
    Write-Host "  Found $($similar.Count) similar pattern(s):" -ForegroundColor Green
    foreach ($pattern in $similar) {
        Write-Host "    - Pattern: '$($pattern.ErrorMessage)'" -ForegroundColor Gray
        Write-Host "      Similarity: $($pattern.Similarity)%" -ForegroundColor White
        
        # Handle Fixes being either an object or array
        $fixDisplay = "N/A"
        if ($pattern.Fixes) {
            if ($pattern.Fixes -is [hashtable] -or $pattern.Fixes -is [PSCustomObject]) {
                # Single fix stored as object
                $fixDisplay = $pattern.Fixes.Code
            } elseif ($pattern.Fixes -is [array]) {
                # Multiple fixes stored as array
                $fixDisplay = ($pattern.Fixes | ForEach-Object { $_.Code }) -join "; "
            } else {
                $fixDisplay = $pattern.Fixes.ToString()
            }
        }
        Write-Host "      Fix: $fixDisplay" -ForegroundColor Gray
    }
    Write-Host "  Test Result: [PASS]" -ForegroundColor Green
} else {
    Write-Host "  No patterns found!" -ForegroundColor Red
    Write-Host "  Test Result: [FAIL]" -ForegroundColor Red
    
    # Debug: Check if patterns are actually stored
    Write-Host "`n  Debug: Checking stored patterns..." -ForegroundColor Yellow
    $allPatterns = Get-LearningConfig
    Write-Host "  Patterns file: $($allPatterns.PatternsFile)" -ForegroundColor Gray
    if (Test-Path $allPatterns.PatternsFile) {
        $content = Get-Content $allPatterns.PatternsFile -Raw
        Write-Host "  File exists. Content length: $($content.Length) chars" -ForegroundColor Gray
        if ($content.Length -lt 500) {
            Write-Host "  Raw content:" -ForegroundColor Gray
            Write-Host $content -ForegroundColor DarkGray
        }
    } else {
        Write-Host "  Patterns file does not exist!" -ForegroundColor Red
    }
}

Write-Host "`n=== SUMMARY ===" -ForegroundColor Cyan
$allPassed = $test1Pass -and $test2Pass -and ($similar.Count -gt 0)
Write-Host "Test 1 (Unity Error Patterns): $(if ($test1Pass) { "[PASS]" } else { "[FAIL]" })" -ForegroundColor $(if ($test1Pass) { "Green" } else { "Red" })
Write-Host "Test 2 (Fuzzy Match Error Messages): $(if ($test2Pass) { "[PASS]" } else { "[FAIL]" })" -ForegroundColor $(if ($test2Pass) { "Green" } else { "Red" })
Write-Host "Test 3 (Find Similar Patterns): $(if ($similar.Count -gt 0) { "[PASS]" } else { "[FAIL]" })" -ForegroundColor $(if ($similar.Count -gt 0) { "Green" } else { "Red" })
Write-Host "`nOverall Result: $(if ($allPassed) { "[ALL TESTS PASS]" } else { "[SOME TESTS FAIL]" })" -ForegroundColor $(if ($allPassed) { "Green" } else { "Red" })

Write-Host "`n=== RECOMMENDATIONS ===" -ForegroundColor Cyan
if (-not $test1Pass) {
    Write-Host "- Test 1 failed: Check similarity calculation formula" -ForegroundColor Yellow
    if ($similarity2 -lt 59) {
        Write-Host "  Specifically: 'NullReferenceException' vs 'NullReference' = $similarity2%" -ForegroundColor Yellow
        Write-Host "  This is below the 59% threshold." -ForegroundColor Yellow
    }
}
if (-not $test2Pass) {
    Write-Host "- Test 2 failed: Check fuzzy matching thresholds" -ForegroundColor Yellow
    if (-not $match2a) {
        Write-Host "  Test 2A: Similarity = $sim2a% (threshold: 45%)" -ForegroundColor Yellow
    }
    if (-not $match2b) {
        Write-Host "  Test 2B: 'directive' vs 'statement' similarity = $sim2b% (threshold: 60%)" -ForegroundColor Yellow
    }
}
if ($similar.Count -eq 0) {
    Write-Host "- Test 3 failed: Pattern storage/retrieval issue" -ForegroundColor Yellow
    Write-Host "  Check if patterns are being saved to JSON correctly" -ForegroundColor Yellow
    Write-Host "  Verify Find-SimilarPatterns is searching the pattern store" -ForegroundColor Yellow
}
# SIG # Begin signature block
# MIIFqQYJKoZIhvcNAQcCoIIFmjCCBZYCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUFPTE6iZNvZMKofAuGUXHGpoI
# cYSgggMwMIIDLDCCAhSgAwIBAgIQdR0W2SKoK5VE8JId4ZxrRTANBgkqhkiG9w0B
# AQsFADAuMSwwKgYDVQQDDCNVbml0eS1DbGF1ZGUtQXV0b21hdGlvbi1EZXZlbG9w
# bWVudDAeFw0yNTA4MjAyMTE1MTdaFw0yNjA4MjAyMTM1MTdaMC4xLDAqBgNVBAMM
# I1VuaXR5LUNsYXVkZS1BdXRvbWF0aW9uLURldmVsb3BtZW50MIIBIjANBgkqhkiG
# 9w0BAQEFAAOCAQ8AMIIBCgKCAQEAseH3qinVEOhrn2OLpjc5TNT4vGh1BkfB5X4S
# FhY7K0QMQsYYnkZVmx3tB8PqVQXl++l+e3uT7uCscc7vjMTK8tDSWH98ji0U34WL
# JBwXC62l1ArazMKp4Tyr7peksei7vL4pZOtOVgAyTYn5d1hbnsVQmCSTPRtpn7mC
# Azfq2ec5qZ9Kgl7puPW5utvYfh8idtOWa5/WgYSKwOIvyZawIdZKLFpwqOtqbJe4
# sWzVahasFhLfoAKkniKOAocJDkJexh5pO/EOSKEZ3mOCU1ZSs4XWRGISRhV3qGZp
# f+Y3JlHKMeFDWKynaJBO8/GU5sqMATlDUvrByBtU2OQ2Um/L3QIDAQABo0YwRDAO
# BgNVHQ8BAf8EBAMCB4AwEwYDVR0lBAwwCgYIKwYBBQUHAwMwHQYDVR0OBBYEFHw5
# rOy6xlW6B45sJUsiI2A/yS0MMA0GCSqGSIb3DQEBCwUAA4IBAQAUTLH0+w8ysvmh
# YuBw4NDKcZm40MTh9Zc1M2p2hAkYsgNLJ+/rAP+I74rNfqguTYwxpCyjkwrg8yF5
# wViwggboLpF2yDu4N/dgDainR4wR8NVpS7zFZOFkpmNPepc6bw3d4yQKa/wJXKeC
# pkRjS50N77/hfVI+fFKNao7POb7en5fcXuZaN6xWoTRy+J4I4MhfHpjZuxSLSXjb
# VXtPD4RZ9HGjl9BU8162cRhjujr/Lc3/dY/6ikHQYnxuxcdxRew4nzaqAQaOeWu6
# tGp899JPKfldM5Zay5IBl3zs15gNS9+0Jrd0ARQnSVYoI0DLh3KybFnfK4POezoN
# Lp/dbX2SMYIB4zCCAd8CAQEwQjAuMSwwKgYDVQQDDCNVbml0eS1DbGF1ZGUtQXV0
# b21hdGlvbi1EZXZlbG9wbWVudAIQdR0W2SKoK5VE8JId4ZxrRTAJBgUrDgMCGgUA
# oHgwGAYKKwYBBAGCNwIBDDEKMAigAoAAoQKAADAZBgkqhkiG9w0BCQMxDAYKKwYB
# BAGCNwIBBDAcBgorBgEEAYI3AgELMQ4wDAYKKwYBBAGCNwIBFTAjBgkqhkiG9w0B
# CQQxFgQU+iKiH/E8Nft8yC8pe7yRyB+mKWEwDQYJKoZIhvcNAQEBBQAEggEAmgm0
# phEJPqiPQmT5Pmp5+pPuiLk6A6yyIXCrWU+5iI7wrf7+nDoJG4vKmX6mWQiT1Sli
# /TFvVOrZ8Q7DxgZYN2dnrJffVWkmApFSCgp9rB6MeAXnN86PCE+1ViSjFeHNhUpd
# W5vR4eysyfSHRVNuZxHYpp8t1RoLp9z6uX7AOF6wNOhMXevPfkVS4/l6cvRXhLIj
# YRl04kIkFT4Y3F/NNb/KTuAzfNZTHIIo/WNIU11Z77SMpZuVazJlv9vtKGMBZn6i
# sTAHTlZ3zF+RrxuLr+geWyblFC3DEMtGz4sHrZ5pKKlgfXpPOEPQorZqiebFEiQW
# B8l901Af57cyTEUGuw==
# SIG # End signature block
