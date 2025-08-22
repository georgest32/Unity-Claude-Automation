# Test Suite for Unity ANALYZE Command Automation - Day 6
# Validates all ANALYZE command functionality implemented in SafeCommandExecution.psm1
# Date: 2025-08-18
# Context: Day 6 ANALYZE commands testing for Claude Code CLI Automation

param(
    [switch]$Detailed,
    [switch]$SkipLongTests,
    [string]$LogLevel = "Info"
)

# Test configuration
$TestConfig = @{
    ProjectRoot = "C:\UnityProjects\Sound-and-Shoal\Unity-Claude-Automation"
    ModulePath = "C:\UnityProjects\Sound-and-Shoal\Unity-Claude-Automation\Modules"
    TestDataPath = "C:\UnityProjects\Sound-and-Shoal\Unity-Claude-Automation\Testing\TestData"
    UnityLogPath = "$env:LOCALAPPDATA\Unity\Editor\Editor.log"
    TestTimeout = 30
    MockLogFile = $null
}

# Create test data directory if it doesn't exist
if (-not (Test-Path $TestConfig.TestDataPath)) {
    New-Item -Path $TestConfig.TestDataPath -ItemType Directory -Force | Out-Null
}

# Initialize test results tracking
$TestResults = @{
    Total = 0
    Passed = 0
    Failed = 0
    Skipped = 0
    Details = @()
    StartTime = Get-Date
}

function Write-TestResult {
    param(
        [string]$TestName,
        [bool]$Passed,
        [string]$Details = "",
        [string]$Error = ""
    )
    
    $TestResults.Total++
    if ($Passed) {
        $TestResults.Passed++
        $status = "PASS"
        $color = "Green"
    } else {
        $TestResults.Failed++
        $status = "FAIL"
        $color = "Red"
    }
    
    $result = @{
        TestName = $TestName
        Status = $status
        Details = $Details
        Error = $Error
        Timestamp = Get-Date
    }
    
    $TestResults.Details += $result
    
    if ($Detailed) {
        Write-Host "[$status] $TestName" -ForegroundColor $color
        if ($Details) { Write-Host "  $Details" -ForegroundColor Gray }
        if ($Error) { Write-Host "  ERROR: $Error" -ForegroundColor Red }
    } else {
        Write-Host "$status" -ForegroundColor $color -NoNewline
    }
}

function Skip-Test {
    param([string]$TestName, [string]$Reason)
    $TestResults.Total++
    $TestResults.Skipped++
    Write-Host "SKIP" -ForegroundColor Yellow -NoNewline
    if ($Detailed) {
        Write-Host ""
        Write-Host "[SKIP] $TestName - $Reason" -ForegroundColor Yellow
    }
}

function Create-MockUnityLog {
    param([string]$LogPath)
    
    $mockLogContent = @"
Unity Console
$((Get-Date).ToString('yyyy-MM-dd HH:mm:ss'))

Compilation started at $((Get-Date).ToString('HH:mm:ss'))
Assets/Scripts/TestScript.cs(15,8): error CS0246: The type or namespace name 'UnknownType' could not be found (are you missing a using directive or an assembly reference?)
Assets/Scripts/Another.cs(23,12): error CS0103: The name 'undefinedVariable' does not exist in the current context
Assets/Scripts/TestClass.cs(45,20): error CS1061: 'Transform' does not contain a definition for 'InvalidMethod' and no accessible extension method 'InvalidMethod' accepting a first argument of type 'Transform' could be found
Assets/Scripts/Convert.cs(12,5): error CS0029: Cannot implicitly convert type 'string' to 'int'
Assets/Scripts/Warning.cs(8,10): warning CS0219: The variable 'unusedVar' is assigned but its value is never used

Build started at $((Get-Date).ToString('HH:mm:ss'))
Building Player for Windows x64...
Exception: NullReferenceException: Object reference not set to an instance of an object
  at UnityEngine.Component.get_transform() [0x00000] in <filename unknown>:0

Failed to import Assets/Models/InvalidModel.fbx
Asset import failed for Assets/Textures/MissingTexture.png

Build completed successfully in 45.2 seconds
Compilation succeeded after 12.3 seconds

Running tests on platform EditMode
Test run completed - 15 passed, 2 failed in 8.7 seconds

Import completed for 25 assets in 3.2 seconds
"@
    
    Set-Content -Path $LogPath -Value $mockLogContent -Encoding UTF8
    return $LogPath
}

Write-Host "Starting Unity ANALYZE Command Automation Tests - Day 6" -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Cyan

# Create mock Unity log for testing in project root to avoid path security issues
$TestConfig.MockLogFile = Join-Path $TestConfig.ProjectRoot "test_unity.log"
Create-MockUnityLog -LogPath $TestConfig.MockLogFile

Write-Host ""
Write-Host "Loading required modules..." -ForegroundColor Yellow

try {
    # Import required modules
    Import-Module "$($TestConfig.ModulePath)\SafeCommandExecution\SafeCommandExecution.psd1" -Force
    Write-Host "SafeCommandExecution module loaded successfully" -ForegroundColor Green
} catch {
    Write-Host "CRITICAL: Failed to load SafeCommandExecution module: $_" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "Running ANALYZE Command Tests..." -ForegroundColor Yellow
Write-Host ""

# Test 1: Enhanced Invoke-AnalysisCommand Operation Routing
try {
    $command = @{
        Operation = 'LogAnalysis'
        Arguments = @{
            LogPath = $TestConfig.MockLogFile
        }
    }
    
    $result = Invoke-AnalysisCommand -Command $command -TimeoutSeconds 30
    $passed = $result.Success -eq $true -and $result.AnalysisResult -ne $null
    Write-TestResult -TestName "Enhanced Invoke-AnalysisCommand LogAnalysis routing" -Passed $passed -Details "Operation routing successful: $($result.Success)"
} catch {
    Write-TestResult -TestName "Enhanced Invoke-AnalysisCommand LogAnalysis routing" -Passed $false -Error $_.Exception.Message
}

# Test 2: Invoke-UnityLogAnalysis Basic Functionality
try {
    $command = @{
        Arguments = @{
            LogPath = $TestConfig.MockLogFile
        }
    }
    
    $result = Invoke-UnityLogAnalysis -Command $command -TimeoutSeconds 30
    $passed = $result.Success -eq $true -and 
              $result.AnalysisResult.TotalLines -gt 0 -and
              $result.AnalysisResult.Summary.ErrorCount -gt 0
    
    Write-TestResult -TestName "Invoke-UnityLogAnalysis basic functionality" -Passed $passed -Details "Analyzed $($result.AnalysisResult.TotalLines) lines, found $($result.AnalysisResult.Summary.ErrorCount) errors"
} catch {
    Write-TestResult -TestName "Invoke-UnityLogAnalysis basic functionality" -Passed $false -Error $_.Exception.Message
}

# Test 3: Unity Error Pattern Recognition
try {
    $command = @{
        Arguments = @{
            LogPath = $TestConfig.MockLogFile
        }
    }
    
    $result = Invoke-UnityLogAnalysis -Command $command
    $errorCount = $result.AnalysisResult.Summary.ErrorCount
    $compilationErrors = $result.AnalysisResult.Summary.CompilationErrors
    $runtimeErrors = $result.AnalysisResult.Summary.RuntimeErrors
    
    $passed = $errorCount -ge 4 -and $compilationErrors -ge 4
    Write-TestResult -TestName "Unity error pattern recognition" -Passed $passed -Details "Compilation errors: $compilationErrors, Runtime errors: $runtimeErrors, Total: $errorCount"
} catch {
    Write-TestResult -TestName "Unity error pattern recognition" -Passed $false -Error $_.Exception.Message
}

# Test 4: Invoke-UnityErrorPatternAnalysis
try {
    $command = @{
        Arguments = @{
            LogPath = $TestConfig.MockLogFile
        }
    }
    
    $result = Invoke-UnityErrorPatternAnalysis -Command $command -TimeoutSeconds 30
    $passed = $result.Success -eq $true -and 
              $result.PatternAnalysis.ErrorPatterns.Count -gt 0 -and
              $result.PatternAnalysis.FrequencyAnalysis.Count -gt 0
    
    Write-TestResult -TestName "Invoke-UnityErrorPatternAnalysis functionality" -Passed $passed -Details "Pattern analysis with $($result.PatternAnalysis.ErrorPatterns.Count) patterns analyzed"
} catch {
    Write-TestResult -TestName "Invoke-UnityErrorPatternAnalysis functionality" -Passed $false -Error $_.Exception.Message
}

# Test 5: Error Pattern Frequency Analysis
try {
    $command = @{
        Arguments = @{
            LogPath = $TestConfig.MockLogFile
        }
    }
    
    $result = Invoke-UnityErrorPatternAnalysis -Command $command
    $cs0246Count = $result.PatternAnalysis.ErrorPatterns.CS0246.Frequency
    $cs0103Count = $result.PatternAnalysis.ErrorPatterns.CS0103.Frequency
    
    $passed = $cs0246Count -gt 0 -and $cs0103Count -gt 0
    Write-TestResult -TestName "Error pattern frequency analysis" -Passed $passed -Details "CS0246: $cs0246Count, CS0103: $cs0103Count occurrences"
} catch {
    Write-TestResult -TestName "Error pattern frequency analysis" -Passed $false -Error $_.Exception.Message
}

# Test 6: Invoke-UnityPerformanceAnalysis
try {
    $command = @{
        Arguments = @{
            LogPath = $TestConfig.MockLogFile
            MetricTypes = @('Compilation', 'Build', 'Test', 'Import')
        }
    }
    
    $result = Invoke-UnityPerformanceAnalysis -Command $command -TimeoutSeconds 30
    $passed = $result.Success -eq $true -and 
              $result.PerformanceAnalysis.Metrics.Count -gt 0 -and
              $result.Duration -gt 0
    
    Write-TestResult -TestName "Invoke-UnityPerformanceAnalysis functionality" -Passed $passed -Details "Performance analysis completed in $($result.Duration)ms with $($result.PerformanceAnalysis.Metrics.Count) metrics"
} catch {
    Write-TestResult -TestName "Invoke-UnityPerformanceAnalysis functionality" -Passed $false -Error $_.Exception.Message
}

# Test 7: Performance Metrics Extraction
try {
    $command = @{
        Arguments = @{
            LogPath = $TestConfig.MockLogFile
        }
    }
    
    $result = Invoke-UnityPerformanceAnalysis -Command $command
    $buildMetrics = $result.PerformanceAnalysis.Metrics.BuildTime
    $compilationMetrics = $result.PerformanceAnalysis.Metrics.CompilationTime
    
    $passed = $buildMetrics -ne $null -or $compilationMetrics -ne $null
    $details = if ($buildMetrics) { "Build metrics found: $($buildMetrics.Count) samples" } 
              elseif ($compilationMetrics) { "Compilation metrics found: $($compilationMetrics.Count) samples" }
              else { "Metrics extraction attempted" }
    
    Write-TestResult -TestName "Performance metrics extraction" -Passed $passed -Details $details
} catch {
    Write-TestResult -TestName "Performance metrics extraction" -Passed $false -Error $_.Exception.Message
}

# Test 8: Invoke-UnityTrendAnalysis
try {
    $command = @{
        Operation = 'TrendAnalysis'
        Arguments = @{
            LogPath = $TestConfig.MockLogFile
            TimeRange = 7
        }
    }
    
    $result = Invoke-AnalysisCommand -Command $command -TimeoutSeconds 30
    $passed = $result.Success -eq $true
    Write-TestResult -TestName "Invoke-UnityTrendAnalysis via routing" -Passed $passed -Details "Trend analysis routing: $($result.Success)"
} catch {
    Write-TestResult -TestName "Invoke-UnityTrendAnalysis via routing" -Passed $false -Error $_.Exception.Message
}

# Test 9: Invoke-UnityReportGeneration
try {
    $analysisData = @{
        LogPath = $TestConfig.MockLogFile
        Summary = @{
            ErrorCount = 5
            WarningCount = 1
            TotalLines = 25
        }
        Metrics = @{
            CompilationTime = @{ AverageDuration = 12300 }
            BuildTime = @{ AverageDuration = 45200 }
        }
    }
    
    $command = @{
        Operation = 'ReportGeneration'
        Arguments = @{
            AnalysisData = $analysisData
            OutputFormat = 'HTML'
            OutputPath = Join-Path $TestConfig.ProjectRoot "test_report.html"
        }
    }
    
    $result = Invoke-AnalysisCommand -Command $command -TimeoutSeconds 30
    $passed = $result.Success -eq $true
    Write-TestResult -TestName "Invoke-UnityReportGeneration HTML output" -Passed $passed -Details "Report generation: $($result.Success)"
} catch {
    Write-TestResult -TestName "Invoke-UnityReportGeneration HTML output" -Passed $false -Error $_.Exception.Message
}

# Test 10: Export-UnityAnalysisData JSON Format
try {
    $analysisData = @{
        LogPath = $TestConfig.MockLogFile
        AnalyzedAt = Get-Date
        Summary = @{
            ErrorCount = 5
            WarningCount = 1
            InfoCount = 20
        }
        ErrorPatterns = @{
            CS0246 = @{ Frequency = 1; Description = "Type not found" }
            CS0103 = @{ Frequency = 1; Description = "Name not in context" }
        }
    }
    
    $command = @{
        Operation = 'DataExport'
        Arguments = @{
            AnalysisData = $analysisData
            OutputFormat = 'JSON'
            OutputPath = Join-Path $TestConfig.ProjectRoot "test_export.json"
        }
    }
    
    $result = Invoke-AnalysisCommand -Command $command -TimeoutSeconds 30
    $passed = $result.Success -eq $true
    Write-TestResult -TestName "Export-UnityAnalysisData JSON format" -Passed $passed -Details "Data export JSON: $($result.Success)"
} catch {
    Write-TestResult -TestName "Export-UnityAnalysisData JSON format" -Passed $false -Error $_.Exception.Message
}

# Test 11: Export-UnityAnalysisData CSV Format
try {
    $analysisData = @{
        Summary = @{
            ErrorCount = 5
            WarningCount = 1
            InfoCount = 20
        }
        Metrics = @{
            CompilationTime = @{ 
                Count = 2
                AverageDuration = 12300
                MinDuration = 10000
                MaxDuration = 14600
            }
        }
    }
    
    $command = @{
        Arguments = @{
            AnalysisData = $analysisData
            OutputFormat = 'CSV'
            OutputPath = Join-Path $TestConfig.ProjectRoot "test_export.csv"
        }
    }
    
    $result = Export-UnityAnalysisData -Command $command -TimeoutSeconds 30
    $passed = $result.Success -eq $true
    Write-TestResult -TestName "Export-UnityAnalysisData CSV format" -Passed $passed -Details "Data export CSV: $($result.Success)"
} catch {
    Write-TestResult -TestName "Export-UnityAnalysisData CSV format" -Passed $false -Error $_.Exception.Message
}

# Test 12: Get-UnityAnalyticsMetrics
try {
    $analysisData = @{
        Summary = @{
            ErrorCount = 5
            WarningCount = 1
            InfoCount = 20
        }
        Metrics = @{
            CompilationTime = @{ 
                AverageDuration = 12300
                Count = 2
            }
            BuildTime = @{
                AverageDuration = 45200
                Count = 1
            }
        }
    }
    
    $command = @{
        Operation = 'MetricExtraction'
        Arguments = @{
            AnalysisData = $analysisData
            MetricTypes = @('Performance', 'Quality', 'Trends')
        }
    }
    
    $result = Invoke-AnalysisCommand -Command $command -TimeoutSeconds 30
    $passed = $result.Success -eq $true
    Write-TestResult -TestName "Get-UnityAnalyticsMetrics extraction" -Passed $passed -Details "Metrics extraction: $($result.Success)"
} catch {
    Write-TestResult -TestName "Get-UnityAnalyticsMetrics extraction" -Passed $false -Error $_.Exception.Message
}

# Test 13: ANALYZE Command Security Validation
try {
    $command = @{
        Operation = 'LogAnalysis'
        Arguments = @{
            LogPath = "C:\Windows\System32\evil.exe"  # Dangerous path
        }
    }
    
    $result = Invoke-AnalysisCommand -Command $command -TimeoutSeconds 10
    $passed = $result.Success -eq $false  # Should fail due to unsafe path
    Write-TestResult -TestName "ANALYZE command security validation" -Passed $passed -Details "Dangerous path blocked: $($result.Success -eq $false)"
} catch {
    $passed = $true  # Exception is expected for security validation
    Write-TestResult -TestName "ANALYZE command security validation" -Passed $passed -Details "Security exception thrown as expected"
}

# Test 14: Missing Log File Handling
try {
    $command = @{
        Arguments = @{
            LogPath = "C:\NonExistent\missing.log"
        }
    }
    
    $result = Invoke-UnityLogAnalysis -Command $command -TimeoutSeconds 10
    $passed = $result.Success -eq $false  # Should fail gracefully
    Write-TestResult -TestName "Missing log file handling" -Passed $passed -Details "Missing file handled gracefully: $($result.Success -eq $false)"
} catch {
    $passed = $true  # Exception is acceptable for missing files
    Write-TestResult -TestName "Missing log file handling" -Passed $passed -Details "Exception thrown for missing file"
}

# Test 15: Operation Routing Validation
try {
    $validOperations = @('LogAnalysis', 'ErrorPattern', 'Performance', 'TrendAnalysis', 'ReportGeneration', 'DataExport', 'MetricExtraction')
    $testsPassed = 0
    
    foreach ($operation in $validOperations) {
        $command = @{
            Operation = $operation
            Arguments = @{
                LogPath = $TestConfig.MockLogFile
            }
        }
        
        try {
            $result = Invoke-AnalysisCommand -Command $command -TimeoutSeconds 10
            if ($result -ne $null) { $testsPassed++ }
        } catch {
            # Some operations may fail due to missing arguments, but routing should work
            if ($_.Exception.Message -notmatch "not found|routing") { $testsPassed++ }
        }
    }
    
    $passed = $testsPassed -ge 5  # At least 5 operations should route correctly
    Write-TestResult -TestName "Operation routing validation" -Passed $passed -Details "Successfully routed $testsPassed/$($validOperations.Count) operations"
} catch {
    Write-TestResult -TestName "Operation routing validation" -Passed $false -Error $_.Exception.Message
}

# Performance benchmark test (if not skipping long tests)
if (-not $SkipLongTests) {
    try {
        $startTime = Get-Date
        
        $command = @{
            Arguments = @{
                LogPath = $TestConfig.MockLogFile
            }
        }
        
        $result = Invoke-UnityLogAnalysis -Command $command
        $duration = ((Get-Date) - $startTime).TotalMilliseconds
        
        $passed = $duration -lt 5000  # Should complete within 5 seconds
        Write-TestResult -TestName "ANALYZE performance benchmark" -Passed $passed -Details "Analysis completed in ${duration}ms (target: <5000ms)"
    } catch {
        Write-TestResult -TestName "ANALYZE performance benchmark" -Passed $false -Error $_.Exception.Message
    }
} else {
    Skip-Test -TestName "ANALYZE performance benchmark" -Reason "Long tests skipped"
}

# Cleanup test files
try {
    if (Test-Path $TestConfig.MockLogFile) {
        Remove-Item $TestConfig.MockLogFile -Force
    }
    
    $testFiles = Get-ChildItem -Path $TestConfig.TestDataPath -Filter "test_*" -ErrorAction SilentlyContinue
    foreach ($file in $testFiles) {
        Remove-Item $file.FullName -Force -ErrorAction SilentlyContinue
    }
} catch {
    # Cleanup failures are not critical
}

# Final results
$TestResults.EndTime = Get-Date
$duration = ($TestResults.EndTime - $TestResults.StartTime).TotalSeconds

Write-Host ""
Write-Host ""
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "Unity ANALYZE Command Automation Test Results - Day 6" -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "Total Tests: $($TestResults.Total)" -ForegroundColor White
Write-Host "Passed: $($TestResults.Passed)" -ForegroundColor Green
Write-Host "Failed: $($TestResults.Failed)" -ForegroundColor Red
Write-Host "Skipped: $($TestResults.Skipped)" -ForegroundColor Yellow
Write-Host "Duration: $([math]::Round($duration, 2)) seconds" -ForegroundColor White

$successRate = if ($TestResults.Total -gt 0) { 
    [math]::Round(($TestResults.Passed / $TestResults.Total) * 100, 1) 
} else { 0 }

Write-Host "Success Rate: $successRate%" -ForegroundColor $(if ($successRate -ge 90) { 'Green' } elseif ($successRate -ge 70) { 'Yellow' } else { 'Red' })

if ($TestResults.Failed -gt 0) {
    Write-Host ""
    Write-Host "Failed Tests:" -ForegroundColor Red
    foreach ($failure in ($TestResults.Details | Where-Object { $_.Status -eq 'FAIL' })) {
        Write-Host "  - $($failure.TestName): $($failure.Error)" -ForegroundColor Red
    }
}

Write-Host ""
if ($successRate -ge 90) {
    Write-Host "Day 6 ANALYZE Commands: VALIDATION SUCCESSFUL" -ForegroundColor Green
    Write-Host "All critical ANALYZE functionality is operational" -ForegroundColor Green
} elseif ($successRate -ge 70) {
    Write-Host "Day 6 ANALYZE Commands: MOSTLY SUCCESSFUL" -ForegroundColor Yellow
    Write-Host "Core ANALYZE functionality working, minor issues detected" -ForegroundColor Yellow
} else {
    Write-Host "Day 6 ANALYZE Commands: VALIDATION FAILED" -ForegroundColor Red
    Write-Host "Critical issues detected in ANALYZE functionality" -ForegroundColor Red
}

Write-Host ""
Write-Host "Test completed at $(Get-Date)" -ForegroundColor Gray

# Return success rate for automation
return $successRate
# SIG # Begin signature block
# MIIFqQYJKoZIhvcNAQcCoIIFmjCCBZYCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUELlUbwGHDV3Gjt9HK3IIKaDu
# nT6gggMwMIIDLDCCAhSgAwIBAgIQdR0W2SKoK5VE8JId4ZxrRTANBgkqhkiG9w0B
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
# CQQxFgQU85iXL+zEjyA7c/UM03IbF6NFpngwDQYJKoZIhvcNAQEBBQAEggEAROOZ
# HEukO1dk0WRDFsepFG2kVMUeVUNdIcdltX6PnemFwMn2sfS8On0xGui0HMD18ogt
# hAP1lEUWNbFVrbYPJ51+jRRoDBeQLLzLfhuS6QL07Qzi5AVYdAeNWFHbUVh+TLd7
# s/RPTQbxzEJUgq91M0lsDJ8iEofWYdFQms45L1DStzCxkfNDSMPTWuz1RReHRIfk
# XwTSBNZzjUHXgjW6qdJaIJSIvxfDxq0NWrCwnY0+UX0xw7+6hkc1pNBEsW/K6A3g
# 6Q6RU1IoKMqpzDirqvY9n7MLqKa8Qkm1s/6SOTRT404Re6+vTpjq2+VcFvfbYoM0
# 9ZTG9LMhjEswBPIBxg==
# SIG # End signature block
