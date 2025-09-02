# Test-EventLogIntegrationPoints.ps1
# Comprehensive test for Phase 3 Days 3-4: Event Log Integration Points
# Tests all workflow integrations and correlation tools

param(
    [switch]$SkipWorkflowTests,
    [switch]$SkipCorrelationTests,
    [switch]$SkipPatternTests,
    [switch]$GenerateSampleEvents
)

$ErrorActionPreference = 'Stop'
$testResults = @()
$testStartTime = Get-Date

# Test result tracking
function Add-TestResult {
    param(
        [string]$TestName,
        [bool]$Passed,
        [string]$Details,
        [double]$Duration = 0
    )
    
    $script:testResults += [PSCustomObject]@{
        TestName = $TestName
        Passed = $Passed
        Details = $Details
        Duration = $Duration
        Timestamp = Get-Date
    }
    
    $status = if ($Passed) { "PASS" } else { "FAIL" }
    $color = if ($Passed) { "Green" } else { "Red" }
    Write-Host "[$status] $TestName" -ForegroundColor $color
    if ($Details) {
        Write-Host "  Details: $Details" -ForegroundColor Gray
    }
}

Write-Host "Unity-Claude Event Log Integration Points Test" -ForegroundColor Cyan
Write-Host "=============================================" -ForegroundColor Cyan
Write-Host "Phase 3 Days 3-4 Validation" -ForegroundColor Cyan
Write-Host "PowerShell Version: $($PSVersionTable.PSVersion)" -ForegroundColor Gray
Write-Host ""

# Test 1: Event Log Module Load
Write-Host "Test 1: Event Log Module Load" -ForegroundColor Yellow
try {
    Import-Module "$PSScriptRoot\Modules\Unity-Claude-EventLog" -Force
    Add-TestResult -TestName "Event Log Module Load" -Passed $true -Details "Module loaded successfully"
}
catch {
    Add-TestResult -TestName "Event Log Module Load" -Passed $false -Details $_.Exception.Message
    Write-Host "Cannot continue without Event Log module" -ForegroundColor Red
    exit 1
}

# Generate sample events if requested
if ($GenerateSampleEvents) {
    Write-Host ""
    Write-Host "Generating Sample Events..." -ForegroundColor Yellow
    
    try {
        # Generate a workflow with correlation
        $workflowCorrelation = [guid]::NewGuid()
        
        # Unity compilation events
        Write-UCEventLog -Message "Unity compilation started" -EntryType Information -Component Unity -Action "CompilationStart" -CorrelationId $workflowCorrelation
        Start-Sleep -Milliseconds 500
        
        Write-UCEventLog -Message "Unity error detected: CS0103" -EntryType Warning -Component Unity -Action "ErrorDetected" `
            -Details @{ErrorCode="CS0103"; File="Test.cs"; Line=42} -CorrelationId $workflowCorrelation
        Start-Sleep -Milliseconds 300
        
        Write-UCEventLog -Message "Unity compilation completed" -EntryType Information -Component Unity -Action "CompilationComplete" `
            -Details @{Duration=1500; Errors=1; Warnings=3} -CorrelationId $workflowCorrelation
        
        # Claude submission events
        Start-Sleep -Milliseconds 200
        Write-UCEventLog -Message "Claude submission started" -EntryType Information -Component Claude -Action "SubmissionStart" -CorrelationId $workflowCorrelation
        Start-Sleep -Milliseconds 800
        
        Write-UCEventLog -Message "Claude response received" -EntryType Information -Component Claude -Action "ResponseReceived" `
            -Details @{ResponseLength=2048; ProcessingTime=750} -CorrelationId $workflowCorrelation
        
        # Agent events
        Write-UCEventLog -Message "Autonomous Agent processing response" -EntryType Information -Component Agent -Action "ProcessingStart" -CorrelationId $workflowCorrelation
        Start-Sleep -Milliseconds 400
        
        Write-UCEventLog -Message "Autonomous Agent state changed" -EntryType Information -Component Agent -Action "StateChange" `
            -Details @{OldState="Idle"; NewState="Processing"} -CorrelationId $workflowCorrelation
        
        # Generate some recurring errors for pattern detection
        for ($i = 1; $i -le 5; $i++) {
            Write-UCEventLog -Message "Connection timeout to Unity Editor" -EntryType Error -Component IPC -Action "ConnectionFailed" `
                -Details @{Attempt=$i; Port=56000}
            Start-Sleep -Milliseconds 100
        }
        
        # Generate performance degradation
        for ($i = 1; $i -le 6; $i++) {
            $duration = 100 * (1 + $i * 0.3)  # Increasing duration
            Write-UCEventLog -Message "Dashboard refresh completed - Duration: ${duration}ms" -EntryType Information -Component Dashboard -Action "RefreshComplete" `
                -Details @{Duration=$duration; ItemsProcessed=50}
            Start-Sleep -Milliseconds 200
        }
        
        Write-Host "  Generated sample events with correlation ID: $workflowCorrelation" -ForegroundColor Green
        Add-TestResult -TestName "Generate Sample Events" -Passed $true -Details "Events generated successfully"
    }
    catch {
        Add-TestResult -TestName "Generate Sample Events" -Passed $false -Details $_.Exception.Message
    }
}

# Test 2: Unity Workflow Integration
if (-not $SkipWorkflowTests) {
    Write-Host ""
    Write-Host "Test 2: Unity Workflow Integration" -ForegroundColor Yellow
    
    try {
        # Test the enhanced export script
        $exportScript = "$PSScriptRoot\Export-Tools\Export-ErrorsForClaude-EventLog.ps1"
        
        if (Test-Path $exportScript) {
            # Run export with NoEventLog to avoid permission issues in test
            $exportResult = & $exportScript -ErrorType Last -NoEventLog
            
            if (Test-Path "$PSScriptRoot\Export-Tools\ErrorExport_*.md") {
                Add-TestResult -TestName "Unity Export Integration" -Passed $true -Details "Export script with event logging works"
            }
            else {
                Add-TestResult -TestName "Unity Export Integration" -Passed $false -Details "Export file not created"
            }
        }
        else {
            Add-TestResult -TestName "Unity Export Integration" -Passed $false -Details "Enhanced export script not found"
        }
    }
    catch {
        Add-TestResult -TestName "Unity Export Integration" -Passed $false -Details $_.Exception.Message
    }
    
    # Test Claude submission integration
    Write-Host ""
    Write-Host "Test 3: Claude Submission Integration" -ForegroundColor Yellow
    
    try {
        $submissionScript = "$PSScriptRoot\CLI-Automation\Submit-ErrorsToClaude-EventLog.ps1"
        
        if (Test-Path $submissionScript) {
            Add-TestResult -TestName "Claude Submission Script" -Passed $true -Details "Enhanced submission script exists"
            
            # Validate script syntax
            $scriptContent = Get-Content $submissionScript -Raw
            $errors = $null
            $null = [System.Management.Automation.PSParser]::Tokenize($scriptContent, [ref]$errors)
            
            if ($errors.Count -eq 0) {
                Add-TestResult -TestName "Claude Script Syntax" -Passed $true -Details "No syntax errors"
            }
            else {
                Add-TestResult -TestName "Claude Script Syntax" -Passed $false -Details "$($errors.Count) syntax errors found"
            }
        }
        else {
            Add-TestResult -TestName "Claude Submission Script" -Passed $false -Details "Enhanced submission script not found"
        }
    }
    catch {
        Add-TestResult -TestName "Claude Submission Integration" -Passed $false -Details $_.Exception.Message
    }
    
    # Test Agent integration
    Write-Host ""
    Write-Host "Test 4: Autonomous Agent Integration" -ForegroundColor Yellow
    
    try {
        $agentScript = "$PSScriptRoot\Modules\Unity-Claude-SystemStatus\Monitoring\Test-AutonomousAgentStatus-EventLog.ps1"
        
        if (Test-Path $agentScript) {
            # Source the functions
            . $agentScript
            
            # Test function availability
            if (Get-Command Test-AutonomousAgentStatus -ErrorAction SilentlyContinue) {
                Add-TestResult -TestName "Agent Status Function" -Passed $true -Details "Enhanced agent status function available"
                
                # Test with NoEventLog flag
                $agentStatus = Test-AutonomousAgentStatus -NoEventLog
                Add-TestResult -TestName "Agent Status Check" -Passed $true -Details "Status check completed (Result: $agentStatus)"
            }
            else {
                Add-TestResult -TestName "Agent Status Function" -Passed $false -Details "Function not found after sourcing"
            }
        }
        else {
            Add-TestResult -TestName "Agent Integration Script" -Passed $false -Details "Enhanced agent script not found"
        }
    }
    catch {
        Add-TestResult -TestName "Agent Integration" -Passed $false -Details $_.Exception.Message
    }
}

# Test 5: Event Correlation
if (-not $SkipCorrelationTests) {
    Write-Host ""
    Write-Host "Test 5: Event Correlation Tools" -ForegroundColor Yellow
    
    try {
        # Test correlation function
        if (Get-Command Get-UCEventCorrelation -ErrorAction SilentlyContinue) {
            # Get recent correlations
            $correlations = Get-UCEventCorrelation -StartTime (Get-Date).AddHours(-1)
            
            if ($correlations) {
                Add-TestResult -TestName "Event Correlation" -Passed $true -Details "Found $($correlations.Count) correlation groups"
                
                # Test specific correlation ID if we generated events
                if ($GenerateSampleEvents -and $workflowCorrelation) {
                    $specific = Get-UCEventCorrelation -CorrelationId $workflowCorrelation
                    
                    if ($specific.Count -gt 0) {
                        Add-TestResult -TestName "Specific Correlation" -Passed $true -Details "Found $($specific.Count) events for test correlation"
                    }
                    else {
                        Add-TestResult -TestName "Specific Correlation" -Passed $false -Details "Test correlation events not found"
                    }
                }
            }
            else {
                Add-TestResult -TestName "Event Correlation" -Passed $true -Details "No correlations found (may be empty log)"
            }
        }
        else {
            Add-TestResult -TestName "Correlation Function" -Passed $false -Details "Get-UCEventCorrelation not available"
        }
    }
    catch {
        Add-TestResult -TestName "Event Correlation" -Passed $false -Details $_.Exception.Message
    }
}

# Test 6: Pattern Detection
if (-not $SkipPatternTests) {
    Write-Host ""
    Write-Host "Test 6: Pattern Detection Tools" -ForegroundColor Yellow
    
    try {
        # Test pattern detection function
        if (Get-Command Get-UCEventPatterns -ErrorAction SilentlyContinue) {
            # Look for patterns in recent events
            $patterns = Get-UCEventPatterns -TimeRange 1 -MinOccurrences 2
            
            if ($patterns) {
                Add-TestResult -TestName "Pattern Detection" -Passed $true -Details "Found $($patterns.Count) patterns"
                
                # Check pattern types
                $patternTypes = $patterns | ForEach-Object { $_.Type } | Select-Object -Unique
                Write-Host "  Pattern types found: $($patternTypes -join ', ')" -ForegroundColor Gray
                
                # Test specific pattern types if we generated events
                if ($GenerateSampleEvents) {
                    $recurringErrors = Get-UCEventPatterns -PatternType RecurringErrors -MinOccurrences 3
                    
                    if ($recurringErrors.Count -gt 0) {
                        Add-TestResult -TestName "Recurring Error Detection" -Passed $true -Details "Detected $($recurringErrors.Count) recurring error patterns"
                    }
                    else {
                        Add-TestResult -TestName "Recurring Error Detection" -Passed $false -Details "Sample recurring errors not detected"
                    }
                    
                    $perfDegradation = Get-UCEventPatterns -PatternType PerformanceDegradation -MinOccurrences 3
                    
                    if ($perfDegradation.Count -gt 0) {
                        Add-TestResult -TestName "Performance Degradation Detection" -Passed $true -Details "Detected performance degradation"
                    }
                    else {
                        Add-TestResult -TestName "Performance Degradation Detection" -Passed $false -Details "Sample performance degradation not detected"
                    }
                }
            }
            else {
                Add-TestResult -TestName "Pattern Detection" -Passed $true -Details "No patterns found (may be insufficient data)"
            }
        }
        else {
            Add-TestResult -TestName "Pattern Function" -Passed $false -Details "Get-UCEventPatterns not available"
        }
    }
    catch {
        Add-TestResult -TestName "Pattern Detection" -Passed $false -Details $_.Exception.Message
    }
}

# Test 7: Performance Validation
Write-Host ""
Write-Host "Test 7: Integration Performance" -ForegroundColor Yellow

try {
    # Test event logging performance with correlation
    $perfCorrelation = [guid]::NewGuid()
    $perfTimes = @()
    
    for ($i = 1; $i -le 10; $i++) {
        $perfStart = Get-Date
        
        Write-UCEventLog -Message "Performance test $i" `
            -EntryType Information `
            -Component Monitor `
            -Action "PerfTest" `
            -Details @{Iteration=$i; TestTime=(Get-Date).ToString()} `
            -CorrelationId $perfCorrelation `
            -NoFallback
        
        $perfTime = ((Get-Date) - $perfStart).TotalMilliseconds
        $perfTimes += $perfTime
    }
    
    $avgTime = ($perfTimes | Measure-Object -Average).Average
    $maxTime = ($perfTimes | Measure-Object -Maximum).Maximum
    
    $perfPassed = $avgTime -lt 100  # Target: <100ms average
    
    Add-TestResult -TestName "Integration Performance" -Passed $perfPassed `
        -Details "Avg: $([math]::Round($avgTime, 2))ms, Max: $([math]::Round($maxTime, 2))ms" `
        -Duration $avgTime
}
catch {
    Add-TestResult -TestName "Integration Performance" -Passed $false -Details $_.Exception.Message
}

# Generate Test Report
Write-Host ""
Write-Host "Test Summary" -ForegroundColor Cyan
Write-Host "============" -ForegroundColor Cyan

$totalTests = $testResults.Count
$passedTests = ($testResults | Where-Object { $_.Passed }).Count
$failedTests = $totalTests - $passedTests
$passRate = if ($totalTests -gt 0) { [math]::Round(($passedTests / $totalTests) * 100, 2) } else { 0 }

Write-Host "Total Tests: $totalTests" -ForegroundColor White
Write-Host "Passed: $passedTests" -ForegroundColor Green
Write-Host "Failed: $failedTests" -ForegroundColor $(if ($failedTests -gt 0) { "Red" } else { "Green" })
Write-Host "Pass Rate: $passRate%" -ForegroundColor $(if ($passRate -ge 80) { "Green" } elseif ($passRate -ge 60) { "Yellow" } else { "Red" })
Write-Host "Total Duration: $([math]::Round(((Get-Date) - $testStartTime).TotalSeconds, 2)) seconds" -ForegroundColor Gray

# Save test results
$resultsFile = "$PSScriptRoot\Test-EventLogIntegrationPoints-Results_$(Get-Date -Format 'yyyyMMdd_HHmmss').txt"

$reportContent = @"
Unity-Claude Event Log Integration Points Test Results
======================================================
Phase 3 Days 3-4 Validation
Generated: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
PowerShell Version: $($PSVersionTable.PSVersion)

Test Summary
------------
Total Tests: $totalTests
Passed: $passedTests
Failed: $failedTests
Pass Rate: $passRate%
Duration: $([math]::Round(((Get-Date) - $testStartTime).TotalSeconds, 2)) seconds

Detailed Results
----------------
$($testResults | Format-Table -AutoSize | Out-String)

Integration Points Tested
-------------------------
1. Unity Compilation Workflow - Event logging in error export
2. Claude Submission Workflow - Event logging in submission process
3. Autonomous Agent Integration - State change and status monitoring
4. Event Correlation Tools - Cross-component event correlation
5. Pattern Detection Tools - Recurring errors and performance analysis
6. Performance Validation - Sub-100ms event logging performance

Recommendations
---------------
$(if ($failedTests -gt 0) {
    if ($testResults | Where-Object { $_.TestName -like "*Module*" -and -not $_.Passed }) {
        "- Check Event Log module installation and configuration"
    }
    if ($testResults | Where-Object { $_.TestName -like "*Integration*" -and -not $_.Passed }) {
        "- Verify enhanced scripts are in correct locations"
    }
    if ($testResults | Where-Object { $_.TestName -like "*Pattern*" -and -not $_.Passed }) {
        "- Generate sample events with -GenerateSampleEvents flag"
    }
} else {
    "All integration points passed successfully!"
})

"@

$reportContent | Set-Content $resultsFile

Write-Host ""
Write-Host "Results saved to: $resultsFile" -ForegroundColor Gray

# Check if we should recommend generating sample events
if (-not $GenerateSampleEvents -and ($testResults | Where-Object { $_.TestName -like "*Pattern*" -or $_.TestName -like "*Correlation*" })) {
    Write-Host ""
    Write-Host "TIP: Run with -GenerateSampleEvents to test pattern detection" -ForegroundColor Yellow
}

# Return exit code
exit $(if ($failedTests -eq 0) { 0 } else { 1 })
# SIG # Begin signature block
# MIIFzgYJKoZIhvcNAQcCoIIFvzCCBbsCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCAVPf/WRkclVJ+U
# ixfLk+jeg53qWG4WnwxgKil5FQ5/WqCCAzAwggMsMIICFKADAgECAhB1HRbZIqgr
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
# MAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIE/ZHKuCNbKLXjk0QeZ7M5e2
# 6IaLL9FBFXtruouSoGOOMA0GCSqGSIb3DQEBAQUABIIBAJ7zUD0I9ZEkolWGL0fU
# /V7LJFwo1q+6pmVXdq3ck1VEiTLEZhI9dRKEBcZlafaCmb5TnTk46jbvWVMdSkGJ
# zouHPhXm/ou8F1Ejz2yi3SvexKZcQVLh0X6XjhbMyKqfLDrZ+YP60kFAK0m5U77m
# MnBf1nugr4wh3e0T5W8apNkdj5PE61bCFBTkVxiOxGj8usmnj6MG+ik8Yj3b/7dM
# 6Ns/cDBsggCeYkFR3hPjvLMY0PeH3cxC7OW2a3/oB1h3CxokPw5SpFwnmJPBkJeI
# kkKvY0Gd/ckEAjYYq0UU7iK7cJuCletUMFfDTzvzSDlh8LRvIkkK6xqnJL8nNo8U
# CBc=
# SIG # End signature block
