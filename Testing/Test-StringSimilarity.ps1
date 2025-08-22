# Test-StringSimilarity.ps1
# Comprehensive test suite for string similarity pattern matching
# Phase 3 Implementation - Day 2 Testing

[CmdletBinding()]
param(
    [switch]$VerboseOutput
)

# Set verbose preference if switch provided
if ($VerboseOutput) { $VerbosePreference = 'Continue' }

Write-Host "Unity-Claude Learning: String Similarity Test Suite" -ForegroundColor Cyan
Write-Host "====================================================" -ForegroundColor Cyan

# Import the learning module
$ModulePath = Join-Path $PSScriptRoot "..\Modules\Unity-Claude-Learning\Unity-Claude-Learning.psm1"
try {
    Import-Module $ModulePath -Force -DisableNameChecking
    Write-Host "✅ Module loaded successfully" -ForegroundColor Green
} catch {
    Write-Host "❌ Failed to load module: $_" -ForegroundColor Red
    exit 1
}

# Test results tracking
$TestResults = @{
    Passed = 0
    Failed = 0
    Total = 0
    Details = @()
}

function Test-StringSimilarityFunction {
    param(
        [string]$TestName,
        [string]$String1,
        [string]$String2,
        [double]$ExpectedSimilarity,
        [double]$Tolerance = 0.05
    )
    
    $TestResults.Total++
    Write-Host "`nTest: $TestName" -ForegroundColor Yellow
    Write-Host "  String1: '$String1'"
    Write-Host "  String2: '$String2'"
    
    try {
        $similarity = Get-StringSimilarity -String1 $String1 -String2 $String2 -Algorithm Levenshtein
        $distance = [Math]::Abs($similarity - $ExpectedSimilarity)
        
        Write-Host "  Result: $similarity" -ForegroundColor Cyan
        Write-Host "  Expected: $ExpectedSimilarity (±$Tolerance)"
        
        if ($distance -le $Tolerance) {
            Write-Host "  ✅ PASS" -ForegroundColor Green
            $TestResults.Passed++
            $TestResults.Details += @{
                Test = $TestName
                Status = "PASS"
                Expected = $ExpectedSimilarity
                Actual = $similarity
                Difference = $distance
            }
        } else {
            Write-Host "  ❌ FAIL (difference: $distance)" -ForegroundColor Red
            $TestResults.Failed++
            $TestResults.Details += @{
                Test = $TestName
                Status = "FAIL"
                Expected = $ExpectedSimilarity
                Actual = $similarity
                Difference = $distance
            }
        }
    } catch {
        Write-Host "  ❌ ERROR: $_" -ForegroundColor Red
        $TestResults.Failed++
        $TestResults.Details += @{
            Test = $TestName
            Status = "ERROR"
            Error = $_.Exception.Message
        }
    }
}

function Test-ErrorSignatureNormalization {
    param(
        [string]$TestName,
        [string]$RawError,
        [string]$ExpectedPattern
    )
    
    $TestResults.Total++
    Write-Host "`nTest: $TestName" -ForegroundColor Yellow
    Write-Host "  Raw: '$RawError'"
    
    try {
        $signature = Get-ErrorSignature -ErrorText $RawError
        Write-Host "  Result: '$signature'" -ForegroundColor Cyan
        Write-Host "  Expected pattern: '$ExpectedPattern'"
        
        if ($signature -like $ExpectedPattern) {
            Write-Host "  ✅ PASS" -ForegroundColor Green
            $TestResults.Passed++
            $TestResults.Details += @{
                Test = $TestName
                Status = "PASS"
                Expected = $ExpectedPattern
                Actual = $signature
            }
        } else {
            Write-Host "  ❌ FAIL" -ForegroundColor Red
            $TestResults.Failed++
            $TestResults.Details += @{
                Test = $TestName
                Status = "FAIL"
                Expected = $ExpectedPattern
                Actual = $signature
            }
        }
    } catch {
        Write-Host "  ❌ ERROR: $_" -ForegroundColor Red
        $TestResults.Failed++
        $TestResults.Details += @{
            Test = $TestName
            Status = "ERROR"
            Error = $_.Exception.Message
        }
    }
}

# Performance test function
function Test-Performance {
    param(
        [int]$Iterations = 1000
    )
    
    Write-Host "`nPerformance Test: $Iterations iterations" -ForegroundColor Yellow
    
    $testStrings = @(
        @("error CS0246: type not found", "error CS0103: name not exist"),
        @("warning CS0168: variable declared", "warning CS0219: variable assigned"),
        @("Assets/Scripts/Test.cs(10,5)", "Assets/Scripts/Other.cs(15,3)")
    )
    
    $start = Get-Date
    for ($i = 0; $i -lt $Iterations; $i++) {
        $testPair = $testStrings[$i % $testStrings.Length]
        Get-StringSimilarity -String1 $testPair[0] -String2 $testPair[1] | Out-Null
    }
    $duration = (Get-Date) - $start
    
    $avgMs = $duration.TotalMilliseconds / $Iterations
    Write-Host "  Total time: $($duration.TotalMilliseconds)ms" -ForegroundColor Cyan
    Write-Host "  Average per calculation: $([Math]::Round($avgMs, 3))ms" -ForegroundColor Cyan
    
    # Performance criteria: should be under 10ms per calculation
    if ($avgMs -lt 10) {
        Write-Host "  ✅ Performance acceptable" -ForegroundColor Green
        return $true
    } else {
        Write-Host "  ⚠️ Performance slower than expected" -ForegroundColor Yellow
        return $false
    }
}

Write-Host "`n🧪 Running String Similarity Tests..." -ForegroundColor White

# Test 1: Identical strings
Test-StringSimilarityFunction -TestName "Identical strings" -String1 "error CS0246" -String2 "error CS0246" -ExpectedSimilarity 1.0

# Test 2: Similar error codes  
Test-StringSimilarityFunction -TestName "Similar error codes" -String1 "error CS0246" -String2 "error CS0247" -ExpectedSimilarity 0.92 -Tolerance 0.02

# Test 3: Different error types
Test-StringSimilarityFunction -TestName "Different error types" -String1 "error CS0246" -String2 "warning CS0168" -ExpectedSimilarity 0.33 -Tolerance 0.10

# Test 4: Completely different strings
Test-StringSimilarityFunction -TestName "Unrelated strings" -String1 "hello world" -String2 "goodbye universe" -ExpectedSimilarity 0.25 -Tolerance 0.15

# Test 5: Unity-specific error patterns
Test-StringSimilarityFunction -TestName "Unity namespace errors" -String1 "CS0246: type 'GameObject' not found" -String2 "CS0246: type 'Transform' not found" -ExpectedSimilarity 0.75 -Tolerance 0.10

# Test 6: Path variations
Test-StringSimilarityFunction -TestName "Path variations" -String1 "Assets/Scripts/Player.cs(10,5)" -String2 "Assets/Scripts/Enemy.cs(15,3)" -ExpectedSimilarity 0.60 -Tolerance 0.15

Write-Host "`n🔧 Running Error Signature Normalization Tests..." -ForegroundColor White

# Test 7: CS0246 normalization
Test-ErrorSignatureNormalization -TestName "CS0246 type not found" -RawError "error CS0246: The type or namespace name 'GameObject' could not be found" -ExpectedPattern "CS0246: The type or namespace name 'TYPE' could not be found"

# Test 8: File path normalization  
Test-ErrorSignatureNormalization -TestName "File path normalization" -RawError "Assets/Scripts/Test.cs(10,5): error CS0103: variable not found" -ExpectedPattern "CS0103: variable not found"

# Test 9: Variable name normalization
Test-ErrorSignatureNormalization -TestName "Variable normalization" -RawError "error CS0103: The name 'myVariable' does not exist" -ExpectedPattern "CS0103: The name 'IDENTIFIER' does not exist"

Write-Host "`n⚡ Running Performance Tests..." -ForegroundColor White

# Performance test
$performanceOk = Test-Performance -Iterations 100

Write-Host "`n📊 Test Results Summary" -ForegroundColor White
Write-Host "======================" -ForegroundColor White
Write-Host "Total Tests: $($TestResults.Total)" -ForegroundColor Cyan
Write-Host "Passed: $($TestResults.Passed)" -ForegroundColor Green  
Write-Host "Failed: $($TestResults.Failed)" -ForegroundColor Red

if ($TestResults.Failed -eq 0) {
    Write-Host "`n🎉 All tests passed!" -ForegroundColor Green
    $exitCode = 0
} else {
    Write-Host "`n❌ Some tests failed:" -ForegroundColor Red
    $TestResults.Details | Where-Object { $_.Status -ne "PASS" } | ForEach-Object {
        Write-Host "  - $($_.Test): $($_.Status)" -ForegroundColor Red
        if ($_.Error) {
            Write-Host "    Error: $($_.Error)" -ForegroundColor Red
        }
        if ($_.Difference) {
            Write-Host "    Expected: $($_.Expected), Got: $($_.Actual), Diff: $($_.Difference)" -ForegroundColor Red
        }
    }
    $exitCode = 1
}

# Save detailed results
$ResultsPath = Join-Path $PSScriptRoot "string-similarity-test-results.json"
$TestResults | ConvertTo-Json -Depth 3 | Set-Content $ResultsPath
Write-Host "`n📄 Detailed results saved to: $ResultsPath" -ForegroundColor Gray

Write-Host "`n✅ String similarity testing completed" -ForegroundColor Cyan
exit $exitCode
# SIG # Begin signature block
# MIIFqQYJKoZIhvcNAQcCoIIFmjCCBZYCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUbYgjTBl6VIURXjq40Tyer/v7
# 8pugggMwMIIDLDCCAhSgAwIBAgIQdR0W2SKoK5VE8JId4ZxrRTANBgkqhkiG9w0B
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
# CQQxFgQUKmRWRkYC+20JoPnVoxa/c1jyy7QwDQYJKoZIhvcNAQEBBQAEggEAjClB
# Ua1P1134HA33xB9adNOlUI38L3uNHs+3lGyjNUDbIT/tDLR71bh4lW+O0hmF4RNN
# F18xmTD0wO6dREWtxXdqmq9lS9buB/u6l3tcUcJc9xFxk6r+61v0tBhFcQCndDxA
# 6h22VqHX+tJyBObGDg1E1ftuE2pZI/qnYQ2yw0JGdIBlaGgqlxJ5yaUnC4NcB2JQ
# 6+tKhzrUnbgn22fNVmUpe4jWiuBcWF05azs2pySTbCt+zSRhm4tigbH7JPVSuuJO
# 5zZSMi6E3yQYrUJql0OfA2LLuvn4aiduP7oC8W1krA4SAOJp3WjQ3h1o7fsWJAQs
# zv8xo1FUOmxupS25Wg==
# SIG # End signature block
