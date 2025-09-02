# Test-ParallelProcessor-Refactored.ps1
# Comprehensive testing of the refactored Unity-Claude-ParallelProcessor module

[CmdletBinding()]
param(
    [switch]$SaveResults,
    [switch]$DetailedOutput
)

$ErrorActionPreference = 'Stop'

# Test configuration
$TestSuite = "ParallelProcessor-Refactored"
$StartTime = Get-Date
$TestResults = @{
    TestSuite = $TestSuite
    StartTime = $StartTime.ToString('yyyy-MM-ddTHH:mm:ss')
    EndTime = $null
    TotalTests = 0
    PassedTests = 0
    FailedTests = 0
    SkippedTests = 0
    Results = @()
    Summary = @{}
}

function Write-TestResult {
    param(
        [string]$TestName,
        [string]$Status,  # 'PASSED', 'FAILED', 'SKIPPED'
        [string]$Message = '',
        [object]$Details = $null,
        [string]$Error = ''
    )
    
    $result = @{
        TestName = $TestName
        Status = $Status
        Message = $Message
        Details = $Details
        Error = $Error
        Timestamp = (Get-Date).ToString('yyyy-MM-ddTHH:mm:ss')
    }
    
    $TestResults.Results += $result
    $TestResults.TotalTests++
    
    switch ($Status) {
        'PASSED' { 
            $TestResults.PassedTests++
            Write-Host "✓ $TestName" -ForegroundColor Green
            if ($DetailedOutput -and $Message) { Write-Host "  $Message" -ForegroundColor Gray }
        }
        'FAILED' { 
            $TestResults.FailedTests++
            Write-Host "✗ $TestName" -ForegroundColor Red
            if ($Error) { Write-Host "  Error: $Error" -ForegroundColor Red }
        }
        'SKIPPED' { 
            $TestResults.SkippedTests++
            Write-Host "○ $TestName (SKIPPED)" -ForegroundColor Yellow
            if ($Message) { Write-Host "  $Message" -ForegroundColor Yellow }
        }
    }
}

Write-Host "=" * 80
Write-Host "Testing Refactored Unity-Claude-ParallelProcessor Module" -ForegroundColor Cyan
Write-Host "Started: $($StartTime.ToString('yyyy-MM-dd HH:mm:ss'))" -ForegroundColor Cyan
Write-Host "=" * 80

#region Module Import Tests

Write-Host "`n[Phase 1: Module Import Tests]" -ForegroundColor Magenta

try {
    # Clean any existing modules
    Get-Module Unity-Claude-ParallelProcessor* | Remove-Module -Force -ErrorAction SilentlyContinue
    
    # Test import of refactored module
    Import-Module ".\Modules\Unity-Claude-ParallelProcessor\Unity-Claude-ParallelProcessor.psd1" -Force
    Write-TestResult "Import Refactored Module" "PASSED" "Module imported successfully"
} catch {
    Write-TestResult "Import Refactored Module" "FAILED" "" $null $_.Exception.Message
    Write-Host "CRITICAL: Cannot continue tests without module import" -ForegroundColor Red
    exit 1
}

# Test module information
try {
    $moduleInfo = Get-UnityClaudeParallelProcessorInfo
    if ($moduleInfo.Version -eq "2.0.0-Refactored" -and $moduleInfo.Architecture -eq "Modular Component-Based") {
        Write-TestResult "Module Information" "PASSED" "Version: $($moduleInfo.Version), Architecture: $($moduleInfo.Architecture)"
    } else {
        Write-TestResult "Module Information" "FAILED" "Unexpected module info" $moduleInfo
    }
} catch {
    Write-TestResult "Module Information" "FAILED" "" $null $_.Exception.Message
}

# Test function availability
$requiredFunctions = @(
    'New-ParallelProcessor',
    'Invoke-ParallelProcessing',
    'Start-BatchProcessing',
    'Get-ParallelProcessorStatistics',
    'Get-JobStatus',
    'Stop-ParallelProcessor',
    'Test-ParallelProcessorHealth'
)

$missingFunctions = @()
foreach ($func in $requiredFunctions) {
    if (-not (Get-Command $func -ErrorAction SilentlyContinue)) {
        $missingFunctions += $func
    }
}

if ($missingFunctions.Count -eq 0) {
    Write-TestResult "Core Functions Available" "PASSED" "All $($requiredFunctions.Count) required functions found"
} else {
    Write-TestResult "Core Functions Available" "FAILED" "Missing functions: $($missingFunctions -join ', ')"
}

#endregion

#region Component Functionality Tests

Write-Host "`n[Phase 2: Component Functionality Tests]" -ForegroundColor Magenta

# Test optimal thread calculation
try {
    $optimalThreads = Get-OptimalThreadCount -WorkloadType 'CPU'
    if ($optimalThreads -gt 0 -and $optimalThreads -le ([Environment]::ProcessorCount * 4)) {
        Write-TestResult "Optimal Thread Calculation" "PASSED" "CPU threads: $optimalThreads"
    } else {
        Write-TestResult "Optimal Thread Calculation" "FAILED" "Invalid thread count: $optimalThreads"
    }
} catch {
    Write-TestResult "Optimal Thread Calculation" "FAILED" "" $null $_.Exception.Message
}

# Test runspace pool manager creation
try {
    $poolManager = New-RunspacePoolManager -MinThreads 2 -MaxThreads 4 -ProcessorId "TEST-POOL"
    if ($poolManager -and $poolManager.IsOpen) {
        Write-TestResult "RunspacePool Manager Creation" "PASSED" "Pool created and opened"
        $poolManager.Dispose()
    } else {
        Write-TestResult "RunspacePool Manager Creation" "FAILED" "Pool not created or not open"
    }
} catch {
    Write-TestResult "RunspacePool Manager Creation" "FAILED" "" $null $_.Exception.Message
}

# Test statistics tracker
try {
    $statsTracker = New-StatisticsTracker -ProcessorId "TEST-STATS"
    if ($statsTracker) {
        $stats = $statsTracker.GetStatistics()
        if ($stats.ProcessorId -eq "TEST-STATS" -and $stats.TotalJobsSubmitted -eq 0) {
            Write-TestResult "Statistics Tracker Creation" "PASSED" "Stats tracker initialized"
        } else {
            Write-TestResult "Statistics Tracker Creation" "FAILED" "Invalid initial stats" $stats
        }
        $statsTracker.Dispose()
    } else {
        Write-TestResult "Statistics Tracker Creation" "FAILED" "Stats tracker not created"
    }
} catch {
    Write-TestResult "Statistics Tracker Creation" "FAILED" "" $null $_.Exception.Message
}

#endregion

#region Parallel Processing Tests

Write-Host "`n[Phase 3: Parallel Processing Tests]" -ForegroundColor Magenta

# Test basic parallel processor creation
try {
    $processor = New-ParallelProcessor -MaxThreads 3 -TimeoutSeconds 30
    if ($processor -and $processor.ProcessorId) {
        Write-TestResult "Parallel Processor Creation" "PASSED" "Processor ID: $($processor.ProcessorId)"
        
        # Test processor health
        $health = Test-ParallelProcessorHealth -Processor $processor
        if ($health.IsHealthy) {
            Write-TestResult "Processor Health Check" "PASSED" "Processor is healthy"
        } else {
            Write-TestResult "Processor Health Check" "FAILED" "Health issues: $($health.Issues -join ', ')"
        }
        
        # Test simple parallel processing
        try {
            $testScript = { param($Number) return $Number * 2 }
            $testData = 1..5
            
            $results = Invoke-ParallelProcessing -Processor $processor -ScriptBlock $testScript -InputObject $testData
            
            if ($results.Count -eq 5 -and ($results | Measure-Object -Sum).Sum -eq 30) {
                Write-TestResult "Simple Parallel Processing" "PASSED" "5 jobs completed, sum = 30"
            } else {
                Write-TestResult "Simple Parallel Processing" "FAILED" "Unexpected results" $results
            }
        } catch {
            Write-TestResult "Simple Parallel Processing" "FAILED" "" $null $_.Exception.Message
        }
        
        # Test statistics retrieval
        try {
            $stats = Get-ParallelProcessorStatistics -Processor $processor
            if ($stats.TotalJobsCompleted -ge 5) {
                Write-TestResult "Statistics Retrieval" "PASSED" "Completed jobs: $($stats.TotalJobsCompleted)"
            } else {
                Write-TestResult "Statistics Retrieval" "FAILED" "Expected 5+ jobs, got $($stats.TotalJobsCompleted)"
            }
        } catch {
            Write-TestResult "Statistics Retrieval" "FAILED" "" $null $_.Exception.Message
        }
        
        # Clean up processor
        Stop-ParallelProcessor -Processor $processor
        Write-TestResult "Processor Cleanup" "PASSED" "Processor stopped and disposed"
        
    } else {
        Write-TestResult "Parallel Processor Creation" "FAILED" "Processor not created"
    }
} catch {
    Write-TestResult "Parallel Processor Creation" "FAILED" "" $null $_.Exception.Message
}

#endregion

#region Batch Processing Tests

Write-Host "`n[Phase 4: Batch Processing Tests]" -ForegroundColor Magenta

try {
    $batchProcessor = New-ParallelProcessor -MaxThreads 2
    if ($batchProcessor) {
        
        # Test batch processing
        $batchScript = { param($Item) return "Processed: $Item" }
        $batchData = @("A", "B", "C", "D", "E")
        
        $batchResults = Start-BatchProcessing -Processor $batchProcessor -ProcessingScript $batchScript -InputObject $batchData -BatchSize 2
        
        if ($batchResults.Count -eq 5 -and ($batchResults[0] -like "Processed: *")) {
            Write-TestResult "Batch Processing" "PASSED" "5 items processed in batches"
        } else {
            Write-TestResult "Batch Processing" "FAILED" "Unexpected batch results" $batchResults
        }
        
        Stop-ParallelProcessor -Processor $batchProcessor
    } else {
        Write-TestResult "Batch Processing" "SKIPPED" "Could not create batch processor"
    }
} catch {
    Write-TestResult "Batch Processing" "FAILED" "" $null $_.Exception.Message
}

#endregion

#region Error Handling Tests

Write-Host "`n[Phase 5: Error Handling Tests]" -ForegroundColor Magenta

try {
    $errorProcessor = New-ParallelProcessor -MaxThreads 2 -RetryCount 1
    if ($errorProcessor) {
        
        # Test error handling with retry
        $errorScript = { param($Number) if ($Number -eq 3) { throw "Test error for $Number" } else { return $Number * 10 } }
        $errorData = 1..5
        
        $errorResults = Invoke-ParallelProcessing -Processor $errorProcessor -ScriptBlock $errorScript -InputObject $errorData -ContinueOnError
        
        # Should have 4 successful results (1,2,4,5) and 1 failure (3)
        $successCount = ($errorResults | Where-Object { $_ -ne $null }).Count
        if ($successCount -eq 4) {
            Write-TestResult "Error Handling with Retry" "PASSED" "4/5 jobs succeeded as expected"
        } else {
            Write-TestResult "Error Handling with Retry" "FAILED" "Expected 4 successes, got $successCount"
        }
        
        Stop-ParallelProcessor -Processor $errorProcessor
    } else {
        Write-TestResult "Error Handling with Retry" "SKIPPED" "Could not create error processor"
    }
} catch {
    Write-TestResult "Error Handling with Retry" "FAILED" "" $null $_.Exception.Message
}

#endregion

#region Performance Tests

Write-Host "`n[Phase 6: Performance Tests]" -ForegroundColor Magenta

try {
    $perfProcessor = New-ParallelProcessor -MaxThreads 4
    if ($perfProcessor) {
        
        # Test performance with larger dataset
        $perfScript = { param($Number) Start-Sleep -Milliseconds 50; return $Number * $Number }
        $perfData = 1..20
        
        $perfStopwatch = [System.Diagnostics.Stopwatch]::StartNew()
        $perfResults = Invoke-ParallelProcessing -Processor $perfProcessor -ScriptBlock $perfScript -InputObject $perfData
        $perfStopwatch.Stop()
        
        # Should complete faster than sequential (20 * 50ms = 1000ms minimum sequential)
        $parallelTime = $perfStopwatch.ElapsedMilliseconds
        if ($parallelTime -lt 800 -and $perfResults.Count -eq 20) {
            Write-TestResult "Performance Test" "PASSED" "20 jobs in $parallelTime ms (< 800ms threshold)"
        } else {
            Write-TestResult "Performance Test" "FAILED" "Too slow: $parallelTime ms, or wrong result count: $($perfResults.Count)"
        }
        
        Stop-ParallelProcessor -Processor $perfProcessor
    } else {
        Write-TestResult "Performance Test" "SKIPPED" "Could not create performance processor"
    }
} catch {
    Write-TestResult "Performance Test" "FAILED" "" $null $_.Exception.Message
}

#endregion

# Complete test results
$EndTime = Get-Date
$TestResults.EndTime = $EndTime.ToString('yyyy-MM-ddTHH:mm:ss')
$TestResults.Duration = ($EndTime - $StartTime).TotalSeconds

$TestResults.Summary = @{
    TotalTests = $TestResults.TotalTests
    PassedTests = $TestResults.PassedTests
    FailedTests = $TestResults.FailedTests
    SkippedTests = $TestResults.SkippedTests
    SuccessRate = if ($TestResults.TotalTests -gt 0) { [math]::Round(($TestResults.PassedTests / $TestResults.TotalTests) * 100, 2) } else { 0 }
    Duration = "$([math]::Round($TestResults.Duration, 2)) seconds"
    OverallResult = if ($TestResults.FailedTests -eq 0) { "SUCCESS" } else { "FAILED" }
}

# Display summary
Write-Host "`n" + ("=" * 80)
Write-Host "Test Summary" -ForegroundColor Cyan
Write-Host "=" * 80
Write-Host "Total Tests: $($TestResults.TotalTests)" -ForegroundColor White
Write-Host "Passed: $($TestResults.PassedTests)" -ForegroundColor Green
Write-Host "Failed: $($TestResults.FailedTests)" -ForegroundColor Red
Write-Host "Skipped: $($TestResults.SkippedTests)" -ForegroundColor Yellow
Write-Host "Success Rate: $($TestResults.Summary.SuccessRate)%" -ForegroundColor $(if ($TestResults.Summary.SuccessRate -ge 90) { 'Green' } elseif ($TestResults.Summary.SuccessRate -ge 70) { 'Yellow' } else { 'Red' })
Write-Host "Duration: $($TestResults.Summary.Duration)" -ForegroundColor White
Write-Host "Overall Result: $($TestResults.Summary.OverallResult)" -ForegroundColor $(if ($TestResults.Summary.OverallResult -eq 'SUCCESS') { 'Green' } else { 'Red' })
Write-Host "=" * 80

# Save results if requested
if ($SaveResults) {
    $resultFile = "ParallelProcessor-Refactored-TestResults-$(Get-Date -Format 'yyyyMMdd-HHmmss').json"
    $TestResults | ConvertTo-Json -Depth 10 | Out-File $resultFile -Encoding UTF8
    Write-Host "`nResults saved to: $resultFile" -ForegroundColor Green
}

# Return results for programmatic access
return $TestResults
# SIG # Begin signature block
# MIIFzgYJKoZIhvcNAQcCoIIFvzCCBbsCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCB78WUzjLS2VxSN
# Tw8NUCrL0T54vGiUtE7Ee5NmpP8C26CCAzAwggMsMIICFKADAgECAhB1HRbZIqgr
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
# MAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIJOzFAyC7epAuSeDpTSQ/xSR
# 4RqGkCWvPds8vOub7Q97MA0GCSqGSIb3DQEBAQUABIIBAF6knAVpl/IMbzKrQzTT
# gP9dEwP3Bh3Rm+2R3gRVtO+fSF12ySg8WibQo1fe7S6L1SuGiZlHn9CtdU5x7tWl
# KUXl5l54rUdcX8TzFa4VItEk4vWGe0Ws6AkOzCUpwVK7TTk9wvr57Q7HO8R0PoRJ
# 8Bi/bSi+fuWWsPfMDVYpim+MDp1hcH2F8v8VrSESG1Ycl+6G8g2y8EiRGw9rYE67
# +KvxNJhMmmWJeSn0Zvem1aoH0r8Ym15x3KVyn0TZCpGwD27/SM0wnqPTEZoObP43
# ZO1e3NvRARYEir1DegUTNE9RuZT2OmKDgPL2vG9WCt75DYBnPrH8MHCntQx8llhv
# z3A=
# SIG # End signature block
