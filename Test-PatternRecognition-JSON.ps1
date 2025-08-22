# Test Pattern Recognition with JSON Backend
# Validates that the updated Find-SimilarPatterns function works correctly

Import-Module './Modules/Unity-Claude-Learning/Unity-Claude-Learning.psm1' -Force -DisableNameChecking

Write-Host "=== Pattern Recognition Test with JSON Backend ===" -ForegroundColor Yellow

# Add some test patterns with different Unity error types
Write-Host "`nAdding test error patterns..." -ForegroundColor Cyan

$patterns = @(
    @{ Error = "CS0246: The type or namespace name 'UnityEngine' could not be found"; Fix = "using UnityEngine;"; Type = "MissingUsing" }
    @{ Error = "CS0103: The name 'Debug' does not exist in the current context"; Fix = "using UnityEngine;"; Type = "MissingUsing" }
    @{ Error = "CS1061: 'GameObject' does not contain a definition for 'SetActive'"; Fix = "gameObject.SetActive(true);"; Type = "IncorrectAPI" }
    @{ Error = "NullReferenceException: Object reference not set to an instance"; Fix = "if (obj != null) { ... }"; Type = "NullCheck" }
    @{ Error = "ArgumentNullException: Value cannot be null"; Fix = "Check for null before using"; Type = "NullCheck" }
)

$patternIds = @()
foreach ($pattern in $patterns) {
    Write-Host "  Adding: $($pattern.Error.Substring(0, 50))..." -ForegroundColor Gray
    $id = Add-ErrorPattern -ErrorMessage $pattern.Error -Fix $pattern.Fix -Verbose
    $patternIds += $id
    Write-Host "  Pattern ID: $id" -ForegroundColor Green
}

Write-Host "`nTesting similarity search..." -ForegroundColor Cyan

# Test various similarity searches
$testCases = @(
    @{ Query = "CS0246: The type 'Transform' could not be found"; Expected = "UnityEngine missing using" }
    @{ Query = "CS0103: The name 'GameObject' does not exist"; Expected = "Debug/UnityEngine missing" }
    @{ Query = "NullReference error in Update method"; Expected = "Null check patterns" }
    @{ Query = "Object reference is null"; Expected = "Null check patterns" }
)

foreach ($testCase in $testCases) {
    Write-Host "`n--- Testing: $($testCase.Query)" -ForegroundColor White
    Write-Host "Expected: $($testCase.Expected)" -ForegroundColor Gray
    
    # Test with different thresholds
    $thresholds = @(0.5, 0.7, 0.85)
    
    foreach ($threshold in $thresholds) {
        Write-Host "  Threshold $threshold`: " -NoNewline -ForegroundColor Yellow
        
        $results = Find-SimilarPatterns -ErrorSignature $testCase.Query -SimilarityThreshold $threshold -MaxResults 3 -Verbose
        
        if ($results.Count -gt 0) {
            Write-Host "$($results.Count) matches" -ForegroundColor Green
            foreach ($result in $results) {
                Write-Host "    - Similarity: $([math]::Round($result.Similarity, 3)), Confidence: $([math]::Round($result.Confidence, 3))" -ForegroundColor Cyan
                Write-Host "      Error: $($result.ErrorSignature.Substring(0, [math]::Min(60, $result.ErrorSignature.Length)))..." -ForegroundColor Gray
            }
        } else {
            Write-Host "No matches" -ForegroundColor Red
        }
    }
}

# Test performance with caching
Write-Host "`n--- Performance Test ---" -ForegroundColor Yellow

$testQuery = "CS0246: Missing namespace reference"
Write-Host "Query: $testQuery" -ForegroundColor Gray

# First run (fresh calculation)
$stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
$results1 = Find-SimilarPatterns -ErrorSignature $testQuery -SimilarityThreshold 0.6 -UseCache $false
$stopwatch.Stop()
$time1 = $stopwatch.ElapsedMilliseconds

# Second run (with caching enabled)
$stopwatch.Restart()
$results2 = Find-SimilarPatterns -ErrorSignature $testQuery -SimilarityThreshold 0.6 -UseCache $true
$stopwatch.Stop()
$time2 = $stopwatch.ElapsedMilliseconds

Write-Host "First run (no cache): ${time1}ms, Found: $($results1.Count)" -ForegroundColor Cyan
Write-Host "Second run (cached): ${time2}ms, Found: $($results2.Count)" -ForegroundColor Cyan

if ($time1 -gt 0 -and $time2 -gt 0) {
    $speedup = [math]::Round($time1 / $time2, 2)
    Write-Host "Speedup: ${speedup}x" -ForegroundColor Green
}

# Display storage statistics
Write-Host "`n--- JSON Storage Statistics ---" -ForegroundColor Yellow
$stats = Get-JSONStorageStats -StoragePath $script:LearningConfig.StoragePath
$stats | Format-Table -AutoSize

Write-Host "`n=== Pattern Recognition Test Completed ===" -ForegroundColor Green
# SIG # Begin signature block
# MIIFqQYJKoZIhvcNAQcCoIIFmjCCBZYCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUozcALCsqzC0MwOtIQ1/fPQQW
# noWgggMwMIIDLDCCAhSgAwIBAgIQdR0W2SKoK5VE8JId4ZxrRTANBgkqhkiG9w0B
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
# CQQxFgQUESvisCrf6WOA4eFILzSYW5k774swDQYJKoZIhvcNAQEBBQAEggEAnvUc
# wyh0wXeyqBP3ghIcr7NWSb89CakTm8zxEdjzMeaAr7zUfi2w0v5tActEO3oji6tG
# g+9AbHVlEN+ICtlGe5Ni1Gl7SQfcw7/Xei63gy1WtI0CSWVoAGfaU/7n6vpOpp/1
# Qd64TBBnudMIrtHILiiPLYG5dxSXGXyL/nnvCazfzVsT5f6EYIOVr/UfZGY78KbN
# V275i0XD/IXAFdb8OYCh1zu9xBJlqxNXwCt+syqY0zrquh4vcBhwHzXSPMdZfUrr
# KAjsPOeSX74vTHIdrq3n/GWAdVg2ywtmcn4OoCWLUYjYPdyB14wtpbhw/w7S6OLs
# Dw6zDmjoZW7H8aLqmA==
# SIG # End signature block
