# Test-DatabaseIntegration.ps1
# Test suite for enhanced database integration with similarity caching and confidence scoring
# Phase 3 Implementation - Week 1, Day 3 Testing

[CmdletBinding()]
param(
    [switch]$VerboseOutput,
    [switch]$CleanDatabase
)

if ($VerboseOutput) { $VerbosePreference = 'Continue' }

Write-Host "Unity-Claude Learning: Database Integration Test Suite" -ForegroundColor Cyan
Write-Host "=======================================================" -ForegroundColor Cyan

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

function Test-DatabaseFunction {
    param(
        [string]$TestName,
        [scriptblock]$TestScript,
        [string]$ExpectedResult = $null
    )
    
    $TestResults.Total++
    Write-Host "`nTest: $TestName" -ForegroundColor Yellow
    
    try {
        $result = & $TestScript
        
        if ($ExpectedResult) {
            if ($result -like $ExpectedResult) {
                Write-Host "  ✅ PASS" -ForegroundColor Green
                $TestResults.Passed++
                $TestResults.Details += @{
                    Test = $TestName
                    Status = "PASS"
                    Result = $result
                }
            } else {
                Write-Host "  ❌ FAIL - Expected: $ExpectedResult, Got: $result" -ForegroundColor Red
                $TestResults.Failed++
                $TestResults.Details += @{
                    Test = $TestName
                    Status = "FAIL"
                    Expected = $ExpectedResult
                    Actual = $result
                }
            }
        } else {
            # Just check if no error occurred
            Write-Host "  ✅ PASS - No errors" -ForegroundColor Green
            Write-Host "  Result: $result" -ForegroundColor Gray
            $TestResults.Passed++
            $TestResults.Details += @{
                Test = $TestName
                Status = "PASS"
                Result = $result
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

# Clean database if requested
if ($CleanDatabase) {
    Write-Host "`n🧹 Cleaning database..." -ForegroundColor Yellow
    $dbPath = Join-Path $PSScriptRoot "..\Modules\Unity-Claude-Learning\LearningDatabase.db"
    if (Test-Path $dbPath) {
        Remove-Item $dbPath -Force
        Write-Host "  Database removed" -ForegroundColor Gray
    }
}

Write-Host "`n🗄️ Testing Database Initialization..." -ForegroundColor White

# Test 1: Database initialization
Test-DatabaseFunction -TestName "Database Initialization" -TestScript {
    $result = Initialize-LearningDatabase
    if ($result.Success) {
        return "SUCCESS"
    } else {
        throw $result.Error
    }
} -ExpectedResult "SUCCESS"

Write-Host "`n🔗 Testing Pattern Similarity Caching..." -ForegroundColor White

# Test 2: Add test patterns
Test-DatabaseFunction -TestName "Add Sample Error Patterns" -TestScript {
    # Add some sample patterns for testing
    $pattern1 = Add-ErrorPattern -ErrorMessage "error CS0246: The type or namespace name 'GameObject' could not be found" -Fix "using UnityEngine;"
    $pattern2 = Add-ErrorPattern -ErrorMessage "error CS0246: The type or namespace name 'Transform' could not be found" -Fix "using UnityEngine;"
    $pattern3 = Add-ErrorPattern -ErrorMessage "error CS0103: The name 'Debug' does not exist in the current context" -Fix "using UnityEngine;"
    
    if ($pattern1 -and $pattern2 -and $pattern3) {
        return "3 patterns added successfully"
    } else {
        throw "Failed to add patterns"
    }
}

# Test 3: Find similar patterns (should calculate and cache similarities)
Test-DatabaseFunction -TestName "Find Similar Patterns (Fresh Calculation)" -TestScript {
    $signature = Get-ErrorSignature -ErrorText "error CS0246: The type or namespace name 'Rigidbody' could not be found"
    $similar = Find-SimilarPatterns -ErrorSignature $signature -SimilarityThreshold 0.6 -UseCache $false
    
    return "Found $($similar.Count) similar patterns"
}

# Test 4: Find similar patterns again (should use cache)
Test-DatabaseFunction -TestName "Find Similar Patterns (Cached)" -TestScript {
    $signature = Get-ErrorSignature -ErrorText "error CS0246: The type or namespace name 'Rigidbody' could not be found"
    $similar = Find-SimilarPatterns -ErrorSignature $signature -SimilarityThreshold 0.6 -UseCache $true
    
    $cachedCount = ($similar | Where-Object { $_.Source -eq "Cached" }).Count
    $calculatedCount = ($similar | Where-Object { $_.Source -eq "Calculated" }).Count
    
    return "Found $($similar.Count) patterns ($cachedCount cached, $calculatedCount calculated)"
}

Write-Host "`n🎯 Testing Confidence Scoring..." -ForegroundColor White

# Test 5: Calculate confidence scores
Test-DatabaseFunction -TestName "Calculate Confidence Scores" -TestScript {
    $signature = Get-ErrorSignature -ErrorText "error CS0246: The type or namespace name 'GameObject' could not be found"
    $similar = Find-SimilarPatterns -ErrorSignature $signature -SimilarityThreshold 0.5 -MaxResults 3
    
    $confidenceResults = @()
    foreach ($pattern in $similar) {
        $confidence = Calculate-ConfidenceScore -PatternID $pattern.PatternID -SimilarityScore $pattern.Similarity
        $confidenceResults += "Pattern $($pattern.PatternID): $([Math]::Round($confidence.FinalConfidence * 100, 1))%"
    }
    
    return "Calculated confidence for $($confidenceResults.Count) patterns: $($confidenceResults -join ', ')"
}

Write-Host "`n⚡ Testing Performance..." -ForegroundColor White

# Test 6: Performance test with caching
Test-DatabaseFunction -TestName "Similarity Caching Performance" -TestScript {
    $testErrors = @(
        "error CS0246: The type or namespace name 'Vector3' could not be found",
        "error CS0246: The type or namespace name 'Quaternion' could not be found",
        "error CS0103: The name 'Input' does not exist in the current context"
    )
    
    # First run (should cache)
    $start = Get-Date
    foreach ($error in $testErrors) {
        $signature = Get-ErrorSignature -ErrorText $error
        Find-SimilarPatterns -ErrorSignature $signature -SimilarityThreshold 0.6 -UseCache $false | Out-Null
    }
    $firstRun = (Get-Date) - $start
    
    # Second run (should use cache)
    $start = Get-Date
    foreach ($error in $testErrors) {
        $signature = Get-ErrorSignature -ErrorText $error
        Find-SimilarPatterns -ErrorSignature $signature -SimilarityThreshold 0.6 -UseCache $true | Out-Null
    }
    $secondRun = (Get-Date) - $start
    
    $speedup = $firstRun.TotalMilliseconds / $secondRun.TotalMilliseconds
    return "First run: $([Math]::Round($firstRun.TotalMilliseconds, 0))ms, Cached run: $([Math]::Round($secondRun.TotalMilliseconds, 0))ms (${speedup}x speedup)"
}

Write-Host "`n📊 Testing Database Schema..." -ForegroundColor White

# Test 7: Verify new tables exist
Test-DatabaseFunction -TestName "Verify PatternSimilarity Table" -TestScript {
    $dbPath = Join-Path $PSScriptRoot "..\Modules\Unity-Claude-Learning\LearningDatabase.db"
    if (-not (Test-Path $dbPath)) {
        throw "Database file not found"
    }
    
    # Count similarity records
    Add-Type -Path "System.Data.SQLite.dll" -ErrorAction SilentlyContinue
    $connection = New-Object System.Data.SQLite.SQLiteConnection
    $connection.ConnectionString = "Data Source=$dbPath;Version=3;"
    
    try {
        $connection.Open()
        $command = $connection.CreateCommand()
        $command.CommandText = "SELECT COUNT(*) FROM PatternSimilarity"
        $count = $command.ExecuteScalar()
        $connection.Close()
        
        return "PatternSimilarity table has $count records"
    } catch {
        if ($connection.State -eq 'Open') { $connection.Close() }
        throw "Failed to query PatternSimilarity table: $_"
    }
}

# Test 8: Verify confidence scores table
Test-DatabaseFunction -TestName "Verify ConfidenceScores Table" -TestScript {
    $dbPath = Join-Path $PSScriptRoot "..\Modules\Unity-Claude-Learning\LearningDatabase.db"
    $connection = New-Object System.Data.SQLite.SQLiteConnection
    $connection.ConnectionString = "Data Source=$dbPath;Version=3;"
    
    try {
        $connection.Open()
        $command = $connection.CreateCommand()
        $command.CommandText = "SELECT COUNT(*) FROM ConfidenceScores"
        $count = $command.ExecuteScalar()
        $connection.Close()
        
        return "ConfidenceScores table has $count records"
    } catch {
        if ($connection.State -eq 'Open') { $connection.Close() }
        throw "Failed to query ConfidenceScores table: $_"
    }
}

Write-Host "`n📈 Test Results Summary" -ForegroundColor White
Write-Host "======================" -ForegroundColor White
Write-Host "Total Tests: $($TestResults.Total)" -ForegroundColor Cyan
Write-Host "Passed: $($TestResults.Passed)" -ForegroundColor Green  
Write-Host "Failed: $($TestResults.Failed)" -ForegroundColor Red

if ($TestResults.Failed -eq 0) {
    Write-Host "`n🎉 All database integration tests passed!" -ForegroundColor Green
    $exitCode = 0
} else {
    Write-Host "`n❌ Some tests failed:" -ForegroundColor Red
    $TestResults.Details | Where-Object { $_.Status -ne "PASS" } | ForEach-Object {
        Write-Host "  - $($_.Test): $($_.Status)" -ForegroundColor Red
        if ($_.Error) {
            Write-Host "    Error: $($_.Error)" -ForegroundColor Red
        }
        if ($_.Expected -and $_.Actual) {
            Write-Host "    Expected: $($_.Expected), Got: $($_.Actual)" -ForegroundColor Red
        }
    }
    $exitCode = 1
}

# Save detailed results
$ResultsPath = Join-Path $PSScriptRoot "database-integration-test-results.json"
$TestResults | ConvertTo-Json -Depth 3 | Set-Content $ResultsPath
Write-Host "`n📄 Detailed results saved to: $ResultsPath" -ForegroundColor Gray

Write-Host "`n✅ Database integration testing completed" -ForegroundColor Cyan

# Display learning configuration
Write-Host "`n⚙️ Current Learning Configuration:" -ForegroundColor Gray
Get-LearningConfig | Format-List

exit $exitCode
# SIG # Begin signature block
# MIIFqQYJKoZIhvcNAQcCoIIFmjCCBZYCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQU1fwi+x7kvqkVmSWo8mXxFSJa
# vAGgggMwMIIDLDCCAhSgAwIBAgIQdR0W2SKoK5VE8JId4ZxrRTANBgkqhkiG9w0B
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
# CQQxFgQUZV3QyXh7T05vsGsNi81I5WFh9ZkwDQYJKoZIhvcNAQEBBQAEggEAP4Z2
# eeA/fq73S28aLiScTY44RvUh2owSy24YnFH08fESep5C5gqgURGNJUdSob+6uvU1
# i0z/N/Df98lNLYvnajWpQo7qTO71L36PPG/kcRFiwas46PmrI36he6CFP4a269/x
# Kh/3vZ2C1TqaUw3e0WQW3zvhrcVJwoXydlCvk2LA7RN/PeHxCLz9Gut6mUwwm8z8
# wea3KMzlkk/6kFJcKpO8HmEzcXcT7bSFus4iejWWbsRfQmw8sG7IFYYcJhaA3XtZ
# ZIQ4CVcWqDMnn4afOUFXoNGeNsCP18o40ilBq6R74sE2ni/Qms2cAICXVRAiG6t3
# X+pe/zhU00pTtVN/6w==
# SIG # End signature block
