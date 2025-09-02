# Test-Phase7-Day1-2-PatternRecognitionEnhancements.ps1
# Comprehensive test for enhanced pattern recognition with Bayesian confidence scoring
# Phase 7 Day 1-2: Hours 5-8 validation

[CmdletBinding()]
param(
    [Parameter()]
    [ValidateSet("Basic", "Advanced", "Performance", "All")]
    [string]$TestType = "All",
    
    [Parameter()]
    [switch]$SaveResults
)

$ErrorActionPreference = "Continue"
$testResults = @()
$testStartTime = Get-Date

Write-Host "=== Phase 7 Day 1-2 Pattern Recognition Enhancement Tests ===" -ForegroundColor Cyan
Write-Host "Test Type: $TestType" -ForegroundColor Yellow
Write-Host "Start Time: $($testStartTime.ToString('yyyy-MM-dd HH:mm:ss'))" -ForegroundColor Gray

#region Test Setup

# Import required modules
try {
    Import-Module ".\Modules\Unity-Claude-CLIOrchestrator\Unity-Claude-CLIOrchestrator.psd1" -Force -Global
    Write-Host "✓ CLIOrchestrator module imported successfully" -ForegroundColor Green
} catch {
    Write-Host "✗ Failed to import CLIOrchestrator module: $($_.Exception.Message)" -ForegroundColor Red
    return
}

# Test data with varying complexity
$testCases = @(
    @{
        Name = "Simple Recommendation"
        Content = "RECOMMENDATION: TEST - C:\UnityProjects\Test-Script.ps1"
        ExpectedEntities = @("FilePath", "PowerShellCommand")
        ExpectedPatterns = 1
        Description = "Basic recommendation extraction test"
    },
    @{
        Name = "Complex Multi-Entity Response"
        Content = @"
RECOMMENDATION: FIX - C:\UnityProjects\Sound-and-Shoal\Unity-Claude-Automation\Start-SystemStatusMonitoring.ps1

The issue occurs in line 245 where the Get-SystemStatus command fails with error:
'Cannot bind argument to parameter 'Path' because it is null or empty.'

Please check the $configPath variable initialization around line 230-240.
Also ensure the Import-Module Unity-Claude-SystemStatus is working correctly.
"@
        ExpectedEntities = @("FilePath", "PowerShellCommand", "Variable", "ErrorMessage")
        ExpectedPatterns = 2
        Description = "Complex response with multiple entity types and error context"
    },
    @{
        Name = "URL and Network Context"
        Content = "RECOMMENDATION: CONTINUE - Please visit https://docs.anthropic.com/claude-code for documentation. The service is running on port 8080."
        ExpectedEntities = @("URL", "Port")
        ExpectedPatterns = 1
        Description = "Network-related entity extraction"
    },
    @{
        Name = "Bayesian Confidence Test"
        Content = "RECOMMENDATION: COMPILE - C:\UnityProjects\MyProject.sln with high confidence based on successful pattern matching"
        ExpectedEntities = @("FilePath")
        ExpectedPatterns = 1
        Description = "Test Bayesian confidence scoring with context"
    }
)

#endregion

#region Basic Tests

if ($TestType -in @("Basic", "All")) {
    Write-Host "`n--- Basic Pattern Recognition Tests ---" -ForegroundColor Magenta
    
    foreach ($testCase in $testCases) {
        Write-Host "  Testing: $($testCase.Name)" -ForegroundColor Yellow
        $testStart = [System.Diagnostics.Stopwatch]::StartNew()
        
        try {
            # Test the enhanced pattern recognition
            $analysisResult = Invoke-PatternRecognitionAnalysis -ResponseContent $testCase.Content -IncludeDetails
            
            $testStart.Stop()
            
            # Validate results
            $patternCount = if ($analysisResult.Recommendations) { $analysisResult.Recommendations.Count } else { 0 }
            $entityCount = if ($analysisResult.Entities) { $analysisResult.Entities.Count } else { 0 }
            $confidenceScore = if ($analysisResult.ConfidenceAnalysis.OverallConfidence) { 
                $analysisResult.ConfidenceAnalysis.OverallConfidence 
            } else { 0.0 }
            
            $success = ($patternCount -ge $testCase.ExpectedPatterns) -and ($entityCount -ge $testCase.ExpectedEntities.Count)
            
            $testResult = @{
                Name = $testCase.Name
                Status = if ($success) { "PASSED" } else { "FAILED" }
                Duration = $testStart.ElapsedMilliseconds
                Details = @{
                    PatternsFound = $patternCount
                    EntitiesFound = $entityCount
                    ConfidenceScore = $confidenceScore
                    ProcessingTime = $analysisResult.ProcessingTimeMs
                }
                Error = $null
            }
            
            if ($success) {
                Write-Host "    ✓ PASSED - Patterns: $patternCount, Entities: $entityCount, Confidence: $($confidenceScore.ToString('P1'))" -ForegroundColor Green
            } else {
                Write-Host "    ✗ FAILED - Expected patterns: $($testCase.ExpectedPatterns), Found: $patternCount" -ForegroundColor Red
            }
            
        } catch {
            $testStart.Stop()
            Write-Host "    ✗ ERROR - $($_.Exception.Message)" -ForegroundColor Red
            
            $testResult = @{
                Name = $testCase.Name
                Status = "ERROR"
                Duration = $testStart.ElapsedMilliseconds
                Details = $null
                Error = $_.Exception.Message
            }
        }
        
        $testResults += $testResult
    }
}

#endregion

#region Advanced Tests

if ($TestType -in @("Advanced", "All")) {
    Write-Host "`n--- Advanced Enhancement Tests ---" -ForegroundColor Magenta
    
    # Test 1: Position Weight Matrix Scoring
    Write-Host "  Testing: Position Weight Matrix (PWM) Scoring" -ForegroundColor Yellow
    $testStart = [System.Diagnostics.Stopwatch]::StartNew()
    
    try {
        $testContext = @{
            "FilePath" = "C:\Test.ps1"
            "ErrorMessage" = "File not found"
            "LineNumber" = "42"
        }
        $testWeights = @{
            "FilePath" = 0.9
            "ErrorMessage" = 0.8
            "LineNumber" = 0.7
        }
        
        $pwmScore = Get-PositionWeightMatrixScore -PatternContext $testContext -PatternWeights $testWeights
        $testStart.Stop()
        
        $success = ($pwmScore -ge 0.1 -and $pwmScore -le 1.0)
        
        Write-Host "    ✓ PWM Score: $($pwmScore.ToString('F3')) (Duration: $($testStart.ElapsedMilliseconds)ms)" -ForegroundColor Green
        
        $testResults += @{
            Name = "Position Weight Matrix Scoring"
            Status = if ($success) { "PASSED" } else { "FAILED" }
            Duration = $testStart.ElapsedMilliseconds
            Details = @{ PWMScore = $pwmScore }
            Error = $null
        }
        
    } catch {
        $testStart.Stop()
        Write-Host "    ✗ ERROR - $($_.Exception.Message)" -ForegroundColor Red
        
        $testResults += @{
            Name = "Position Weight Matrix Scoring"
            Status = "ERROR"
            Duration = $testStart.ElapsedMilliseconds
            Details = $null
            Error = $_.Exception.Message
        }
    }
    
    # Test 2: Joint Entity Classification
    Write-Host "  Testing: Joint Entity Classification" -ForegroundColor Yellow
    $testStart = [System.Diagnostics.Stopwatch]::StartNew()
    
    try {
        $testSpan = @{
            Text = "Get-SystemStatus -Path C:\Config\settings.json"
            StartPosition = 0
            Length = 45
            Type = "Multi"
            SentenceContext = @{ Text = "Please run Get-SystemStatus -Path C:\Config\settings.json to verify configuration." }
        }
        
        $entities = Invoke-JointEntityClassification -Span $testSpan -FullText $testSpan.SentenceContext.Text
        $testStart.Stop()
        
        $entityCount = $entities.Count
        $success = $entityCount -ge 2  # Should find PowerShellCommand and FilePath
        
        Write-Host "    ✓ Joint Classification - Entities: $entityCount (Duration: $($testStart.ElapsedMilliseconds)ms)" -ForegroundColor Green
        
        $testResults += @{
            Name = "Joint Entity Classification"
            Status = if ($success) { "PASSED" } else { "FAILED" }
            Duration = $testStart.ElapsedMilliseconds
            Details = @{ EntitiesFound = $entityCount }
            Error = $null
        }
        
    } catch {
        $testStart.Stop()
        Write-Host "    ✗ ERROR - $($_.Exception.Message)" -ForegroundColor Red
        
        $testResults += @{
            Name = "Joint Entity Classification"
            Status = "ERROR"
            Duration = $testStart.ElapsedMilliseconds
            Details = $null
            Error = $_.Exception.Message
        }
    }
    
    # Test 3: CRPS Calibration
    Write-Host "  Testing: CRPS Confidence Calibration" -ForegroundColor Yellow
    $testStart = [System.Diagnostics.Stopwatch]::StartNew()
    
    try {
        $rawConfidence = 0.85
        $patternType = "TEST"
        
        $calibratedConfidence = Invoke-CRPSCalibration -RawConfidence $rawConfidence -PatternType $patternType
        $testStart.Stop()
        
        $success = ($calibratedConfidence -ge 0.1 -and $calibratedConfidence -le 1.0)
        
        Write-Host "    ✓ CRPS Calibration - Raw: $($rawConfidence.ToString('F3')), Calibrated: $($calibratedConfidence.ToString('F3'))" -ForegroundColor Green
        
        $testResults += @{
            Name = "CRPS Confidence Calibration"
            Status = if ($success) { "PASSED" } else { "FAILED" }
            Duration = $testStart.ElapsedMilliseconds
            Details = @{ RawConfidence = $rawConfidence; CalibratedConfidence = $calibratedConfidence }
            Error = $null
        }
        
    } catch {
        $testStart.Stop()
        Write-Host "    ✗ ERROR - $($_.Exception.Message)" -ForegroundColor Red
        
        $testResults += @{
            Name = "CRPS Confidence Calibration"
            Status = "ERROR"
            Duration = $testStart.ElapsedMilliseconds
            Details = $null
            Error = $_.Exception.Message
        }
    }
}

#endregion

#region Performance Tests

if ($TestType -in @("Performance", "All")) {
    Write-Host "`n--- Performance Tests ---" -ForegroundColor Magenta
    
    # Test performance with larger text
    $largeTestContent = @"
RECOMMENDATION: FIX - C:\UnityProjects\Sound-and-Shoal\Unity-Claude-Automation\Start-SystemStatusMonitoring.ps1

Multiple issues detected in the system monitoring script:
1. Error in Get-SystemStatus at line 245: 'Cannot bind argument to parameter Path'
2. Import-Module Unity-Claude-SystemStatus failed at line 15
3. Variable $configPath is null or empty around lines 230-240
4. Service connection to https://monitoring.example.com:8080 timeout
5. Email notification failed for admin@company.com
6. Log file C:\Logs\system-status.log is locked
7. PowerShell command Get-Counter -Counter "\Processor(_Total)\% Processor Time" returned error
8. Network connection to IP address 192.168.1.100 on port 3389 failed
9. Registry key HKLM:\SOFTWARE\Unity\Claude\Config not found
10. File permissions issue for C:\Program Files\Unity\Claude\Automation\config.json

Please review each issue systematically and implement appropriate fixes.
The system should handle these edge cases gracefully.
"@
    
    Write-Host "  Testing: Large Content Performance" -ForegroundColor Yellow
    $performanceIterations = 5
    $performanceTimes = @()
    
    for ($i = 1; $i -le $performanceIterations; $i++) {
        try {
            $analysisResult = Invoke-PatternRecognitionAnalysis -ResponseContent $largeTestContent
            $performanceTimes += $analysisResult.ProcessingTimeMs
        } catch {
            Write-Host "    ✗ Performance test iteration $i failed: $($_.Exception.Message)" -ForegroundColor Red
        }
    }
    
    if ($performanceTimes.Count -gt 0) {
        $avgTime = ($performanceTimes | Measure-Object -Average).Average
        $minTime = ($performanceTimes | Measure-Object -Minimum).Minimum
        $maxTime = ($performanceTimes | Measure-Object -Maximum).Maximum
        
        $performanceTarget = 300  # 300ms target from implementation plan
        $success = $avgTime -le $performanceTarget
        
        Write-Host "    Performance Results - Avg: $([Math]::Round($avgTime, 1))ms, Range: $minTime-${maxTime}ms" -ForegroundColor $(if ($success) { "Green" } else { "Yellow" })
        Write-Host "    Target: ${performanceTarget}ms - $(if ($success) { "✓ MET" } else { "⚠ EXCEEDED" })" -ForegroundColor $(if ($success) { "Green" } else { "Yellow" })
        
        $testResults += @{
            Name = "Large Content Performance"
            Status = if ($success) { "PASSED" } else { "SLOW" }
            Duration = $avgTime
            Details = @{
                AverageTime = $avgTime
                MinTime = $minTime
                MaxTime = $maxTime
                Target = $performanceTarget
                Iterations = $performanceIterations
            }
            Error = $null
        }
    }
}

#endregion

#region Results Summary

$testEndTime = Get-Date
$totalDuration = ($testEndTime - $testStartTime).TotalMilliseconds

Write-Host "`n=== Test Results Summary ===" -ForegroundColor Cyan
Write-Host "Total Tests: $($testResults.Count)" -ForegroundColor White
Write-Host "Passed: $(($testResults | Where-Object { $_.Status -eq "PASSED" }).Count)" -ForegroundColor Green
Write-Host "Failed: $(($testResults | Where-Object { $_.Status -eq "FAILED" }).Count)" -ForegroundColor Red
Write-Host "Errors: $(($testResults | Where-Object { $_.Status -eq "ERROR" }).Count)" -ForegroundColor Red
Write-Host "Slow: $(($testResults | Where-Object { $_.Status -eq "SLOW" }).Count)" -ForegroundColor Yellow
Write-Host "Total Duration: $([Math]::Round($totalDuration, 1))ms" -ForegroundColor Gray

# Calculate success rate
$successfulTests = ($testResults | Where-Object { $_.Status -in @("PASSED", "SLOW") }).Count
$successRate = if ($testResults.Count -gt 0) { ($successfulTests / $testResults.Count) * 100 } else { 0 }
Write-Host "Success Rate: $($successRate.ToString('F1'))%" -ForegroundColor $(if ($successRate -ge 90) { "Green" } elseif ($successRate -ge 75) { "Yellow" } else { "Red" })

# Phase 7 Day 1-2 Completion Assessment
$coreEnhancements = @("Position Weight Matrix Scoring", "Joint Entity Classification", "CRPS Confidence Calibration")
$coreEnhancementsPassed = ($testResults | Where-Object { $_.Name -in $coreEnhancements -and $_.Status -eq "PASSED" }).Count

Write-Host "`nPhase 7 Day 1-2 Assessment:" -ForegroundColor Cyan
Write-Host "Core Enhancements: $coreEnhancementsPassed / $($coreEnhancements.Count)" -ForegroundColor $(if ($coreEnhancementsPassed -eq $coreEnhancements.Count) { "Green" } else { "Yellow" })

if ($coreEnhancementsPassed -eq $coreEnhancements.Count -and $successRate -ge 85) {
    Write-Host "✓ Phase 7 Day 1-2 Hours 5-8: READY FOR COMPLETION" -ForegroundColor Green
} elseif ($successRate -ge 70) {
    Write-Host "⚠ Phase 7 Day 1-2 Hours 5-8: NEEDS MINOR ADJUSTMENTS" -ForegroundColor Yellow
} else {
    Write-Host "✗ Phase 7 Day 1-2 Hours 5-8: REQUIRES SIGNIFICANT WORK" -ForegroundColor Red
}

#endregion

#region Save Results

if ($SaveResults) {
    $resultsObject = @{
        TestSuite = "Phase7-Day1-2-PatternRecognitionEnhancements"
        TestType = $TestType
        StartTime = $testStartTime.ToString("yyyy-MM-ddTHH:mm:ss.fffK")
        EndTime = $testEndTime.ToString("yyyy-MM-ddTHH:mm:ss.fffK")
        TotalDuration = $totalDuration
        Results = $testResults
        Summary = @{
            TotalTests = $testResults.Count
            Passed = ($testResults | Where-Object { $_.Status -eq "PASSED" }).Count
            Failed = ($testResults | Where-Object { $_.Status -eq "FAILED" }).Count
            Errors = ($testResults | Where-Object { $_.Status -eq "ERROR" }).Count
            Slow = ($testResults | Where-Object { $_.Status -eq "SLOW" }).Count
            SuccessRate = $successRate
            CoreEnhancementsPassed = $coreEnhancementsPassed
            Phase7Day1_2Status = if ($coreEnhancementsPassed -eq $coreEnhancements.Count -and $successRate -ge 85) { 
                "READY_FOR_COMPLETION" 
            } elseif ($successRate -ge 70) { 
                "NEEDS_MINOR_ADJUSTMENTS" 
            } else { 
                "REQUIRES_SIGNIFICANT_WORK" 
            }
        }
    }
    
    $resultsFileName = "Phase7-Day1-2-PatternRecognition-TestResults-$(Get-Date -Format 'yyyyMMdd-HHmmss').json"
    $resultsObject | ConvertTo-Json -Depth 10 | Out-File -FilePath $resultsFileName -Encoding UTF8
    Write-Host "`nResults saved to: $resultsFileName" -ForegroundColor Green
}

#endregion

return $testResults
# SIG # Begin signature block
# MIIFzgYJKoZIhvcNAQcCoIIFvzCCBbsCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCAuOFy5VTw693mC
# brGWeFTRkhxuswoz0K6pSEqd2JPpGKCCAzAwggMsMIICFKADAgECAhB1HRbZIqgr
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
# MAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIELYbXIjJSZrfLlpUczw31+u
# xz3AOl0vKhXRfOPpG1ZXMA0GCSqGSIb3DQEBAQUABIIBAFmGJQSRov+6oLUjr1wK
# iLB8e1Xpdcq45zOKa3QaCWNKode8/5D0Us74UsEtS8c6h3i4FfTdepy+WOeKppcU
# rTVDhVRtPyP688RE69XEaMuRzsEfRaRUNj0ofS9I4n3NA+XfxE0V+YE3rrB2B3Vj
# gjNnyCFy/6Mb3+p7CMhloHV+ro9mcUzgV7J151FGrVoMl7lfDttf2zWhexqE4S0Q
# lfsC1Ac/KfLHBGGYmTaYh74VqlGToKvZ4D28SrApniS9J232v4rnxBpCaxXt7+Qr
# QVoCqmJFOHnfT7Ez8XnNZfElfhWUmzlxSzKFuh3EKifwqT07n/O8HC1TcGaOrN9w
# Gbw=
# SIG # End signature block
