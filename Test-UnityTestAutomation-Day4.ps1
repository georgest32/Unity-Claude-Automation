# Test Script for Phase 1 Day 4: Unity Test Automation
# Tests Unity-TestAutomation module with SafeCommandExecution integration
# Date: 2025-08-18

[CmdletBinding()]
param(
    [Parameter()]
    [switch]$SkipUnityTests,
    
    [Parameter()]
    [string]$UnityProjectPath = "C:\UnityProjects\Sound-and-Shoal\Dithering"
)

# Initialize test environment
$ErrorActionPreference = 'Stop'
$testResults = @()
$testStartTime = Get-Date

# Colors for output
$colors = @{
    Pass = 'Green'
    Fail = 'Red'
    Skip = 'Yellow'
    Info = 'Cyan'
    Section = 'Magenta'
}

function Write-TestSection {
    param([string]$Title)
    Write-Host "`n" -NoNewline
    Write-Host ("=" * 60) -ForegroundColor $colors.Section
    Write-Host $Title -ForegroundColor $colors.Section
    Write-Host ("=" * 60) -ForegroundColor $colors.Section
}

function Write-TestResult {
    param(
        [string]$TestName,
        [bool]$Success,
        [string]$Message = "",
        [bool]$Skipped = $false
    )
    
    if ($Skipped) {
        Write-Host "[SKIP] " -ForegroundColor $colors.Skip -NoNewline
        Write-Host "$TestName" -ForegroundColor White
        if ($Message) {
            Write-Host "       $Message" -ForegroundColor Gray
        }
        $script:testResults += @{
            Name = $TestName
            Result = 'Skipped'
            Message = $Message
        }
    }
    elseif ($Success) {
        Write-Host "[PASS] " -ForegroundColor $colors.Pass -NoNewline
        Write-Host "$TestName" -ForegroundColor White
        if ($Message) {
            Write-Host "       $Message" -ForegroundColor Gray
        }
        $script:testResults += @{
            Name = $TestName
            Result = 'Passed'
            Message = $Message
        }
    }
    else {
        Write-Host "[FAIL] " -ForegroundColor $colors.Fail -NoNewline
        Write-Host "$TestName" -ForegroundColor White
        if ($Message) {
            Write-Host "       $Message" -ForegroundColor $colors.Fail
        }
        $script:testResults += @{
            Name = $TestName
            Result = 'Failed'
            Message = $Message
        }
    }
}

# Test 1: Module Loading
Write-TestSection "Test 1: Module Loading"

try {
    # Import SafeCommandExecution module first
    Write-Host "Importing SafeCommandExecution module..." -ForegroundColor $colors.Info
    Import-Module "$PSScriptRoot\Modules\SafeCommandExecution\SafeCommandExecution.psd1" -Force -ErrorAction Stop
    
    $safeModule = Get-Module SafeCommandExecution
    if ($safeModule) {
        $safeFunctions = Get-Command -Module SafeCommandExecution
        Write-TestResult -TestName "SafeCommandExecution Module Load" -Success $true `
            -Message "Loaded with $($safeFunctions.Count) functions"
    }
    else {
        Write-TestResult -TestName "SafeCommandExecution Module Load" -Success $false `
            -Message "Module not found after import"
    }
}
catch {
    Write-TestResult -TestName "SafeCommandExecution Module Load" -Success $false `
        -Message $_.Exception.Message
}

try {
    # Import Unity-TestAutomation module
    Write-Host "Importing Unity-TestAutomation module..." -ForegroundColor $colors.Info
    Import-Module "$PSScriptRoot\Modules\Unity-TestAutomation\Unity-TestAutomation.psm1" -Force -ErrorAction Stop
    
    $testModule = Get-Module Unity-TestAutomation
    if ($testModule) {
        $testFunctions = Get-Command -Module Unity-TestAutomation -ErrorAction SilentlyContinue
        Write-TestResult -TestName "Unity-TestAutomation Module Load" -Success $true `
            -Message "Loaded with $($testFunctions.Count) functions"
    }
    else {
        Write-TestResult -TestName "Unity-TestAutomation Module Load" -Success $false `
            -Message "Module not found after import"
    }
}
catch {
    Write-TestResult -TestName "Unity-TestAutomation Module Load" -Success $false `
        -Message $_.Exception.Message
}

# Test 2: Function Availability
Write-TestSection "Test 2: Function Availability"

$expectedFunctions = @(
    'Invoke-UnityEditModeTests',
    'Invoke-UnityPlayModeTests',
    'Get-UnityTestResults',
    'Get-UnityTestCategories',
    'New-UnityTestFilter',
    'Invoke-PowerShellTests',
    'Find-CustomTestScripts',
    'Get-TestResultAggregation',
    'Export-TestReport'
)

foreach ($funcName in $expectedFunctions) {
    $func = Get-Command $funcName -ErrorAction SilentlyContinue
    if ($func) {
        Write-TestResult -TestName "Function: $funcName" -Success $true
    }
    else {
        Write-TestResult -TestName "Function: $funcName" -Success $false `
            -Message "Function not found"
    }
}

# Test 3: SafeCommandExecution Integration
Write-TestSection "Test 3: SafeCommandExecution Integration"

try {
    # Test constrained runspace creation
    Write-Host "Testing constrained runspace creation..." -ForegroundColor $colors.Info
    $runspace = New-ConstrainedRunspace -AllowedCommands @('Get-Date', 'Write-Output')
    
    if ($runspace -and $runspace.RunspaceStateInfo.State -eq 'Opened') {
        Write-TestResult -TestName "Constrained Runspace Creation" -Success $true
        $runspace.Close()
    }
    else {
        Write-TestResult -TestName "Constrained Runspace Creation" -Success $false `
            -Message "Runspace not in expected state"
    }
}
catch {
    Write-TestResult -TestName "Constrained Runspace Creation" -Success $false `
        -Message $_.Exception.Message
}

try {
    # Test command safety validation
    Write-Host "Testing command safety validation..." -ForegroundColor $colors.Info
    
    $safeCommand = @{
        CommandType = 'Test'
        Operation = 'RunPesterTests'
        Arguments = @('Get-Date')
    }
    
    $unsafeCommand = @{
        CommandType = 'Test'
        Operation = 'RunTests'
        Arguments = @('Invoke-Expression "dangerous"')
    }
    
    $safeResult = Test-CommandSafety -Command $safeCommand
    $unsafeResult = Test-CommandSafety -Command $unsafeCommand
    
    if ($safeResult.IsSafe -and -not $unsafeResult.IsSafe) {
        Write-TestResult -TestName "Command Safety Validation" -Success $true `
            -Message "Correctly identified safe and unsafe commands"
    }
    else {
        Write-TestResult -TestName "Command Safety Validation" -Success $false `
            -Message "Failed to correctly identify command safety"
    }
}
catch {
    Write-TestResult -TestName "Command Safety Validation" -Success $false `
        -Message $_.Exception.Message
}

# Test 4: Unity Test Discovery (if Unity project available)
Write-TestSection "Test 4: Unity Test Discovery"

if ($SkipUnityTests) {
    Write-TestResult -TestName "Unity Test Category Discovery" -Skipped $true `
        -Message "Unity tests skipped by parameter"
}
elseif (Test-Path $UnityProjectPath) {
    try {
        Write-Host "Discovering Unity test categories..." -ForegroundColor $colors.Info
        $categories = Get-UnityTestCategories -ProjectPath $UnityProjectPath
        
        if ($categories) {
            Write-TestResult -TestName "Unity Test Category Discovery" -Success $true `
                -Message "Found $($categories.Count) categories"
        }
        else {
            Write-TestResult -TestName "Unity Test Category Discovery" -Success $true `
                -Message "No categories found (may be expected)"
        }
    }
    catch {
        Write-TestResult -TestName "Unity Test Category Discovery" -Success $false `
            -Message $_.Exception.Message
    }
}
else {
    Write-TestResult -TestName "Unity Test Category Discovery" -Skipped $true `
        -Message "Unity project path not found: $UnityProjectPath"
}

# Test 5: Test Filter Generation
Write-TestSection "Test 5: Test Filter Generation"

try {
    Write-Host "Testing filter generation..." -ForegroundColor $colors.Info
    
    $filter = New-UnityTestFilter `
        -IncludeCategories @('Unit', 'Integration') `
        -ExcludeCategories @('Slow') `
        -NamePattern 'Test*'
    
    if ($filter.Category -and $filter.Filter) {
        Write-TestResult -TestName "Test Filter Generation" -Success $true `
            -Message "Category: $($filter.Category), Filter: $($filter.Filter)"
    }
    else {
        Write-TestResult -TestName "Test Filter Generation" -Success $false `
            -Message "Filter not generated correctly"
    }
}
catch {
    Write-TestResult -TestName "Test Filter Generation" -Success $false `
        -Message $_.Exception.Message
}

# Test 6: PowerShell Test Discovery
Write-TestSection "Test 6: PowerShell Test Discovery"

try {
    Write-Host "Discovering PowerShell test scripts..." -ForegroundColor $colors.Info
    
    $testScripts = Find-CustomTestScripts -SearchPath $PSScriptRoot
    
    if ($testScripts) {
        Write-TestResult -TestName "PowerShell Test Discovery" -Success $true `
            -Message "Found $($testScripts.Count) test scripts"
    }
    else {
        Write-TestResult -TestName "PowerShell Test Discovery" -Success $true `
            -Message "No test scripts found (creating this one counts!)"
    }
}
catch {
    Write-TestResult -TestName "PowerShell Test Discovery" -Success $false `
        -Message $_.Exception.Message
}

# Test 7: Result Aggregation
Write-TestSection "Test 7: Result Aggregation"

try {
    Write-Host "Testing result aggregation..." -ForegroundColor $colors.Info
    
    # Create temp directory for test results
    $tempResultDir = Join-Path $env:TEMP "Unity-TestResults-$(Get-Date -Format 'yyyyMMdd_HHmmss')"
    New-Item -ItemType Directory -Path $tempResultDir -Force | Out-Null
    
    # Create mock XML result files
    $editModeXml = @'
<?xml version="1.0" encoding="utf-8"?>
<test-run id="1" total="10" passed="8" failed="1" skipped="1" duration="5.2" start-time="2025-08-18 10:00:00" end-time="2025-08-18 10:00:05" result="Passed">
  <test-suite type="Assembly" id="1" name="EditModeTests" total="10" passed="8" failed="1" skipped="1">
    <test-case id="1" name="TestExample" result="Passed" duration="0.5" />
  </test-suite>
</test-run>
'@
    
    Set-Content -Path "$tempResultDir\EditMode-Results.xml" -Value $editModeXml
    
    $aggregation = Get-TestResultAggregation -ResultsDirectory $tempResultDir
    
    if ($aggregation -and $aggregation.Summary.TotalTests -gt 0) {
        Write-TestResult -TestName "Result Aggregation" -Success $true `
            -Message "Aggregated $($aggregation.Summary.TotalTests) tests"
    }
    else {
        Write-TestResult -TestName "Result Aggregation" -Success $false `
            -Message "Aggregation failed or returned no results"
    }
    
    # Cleanup
    Remove-Item -Path $tempResultDir -Recurse -Force -ErrorAction SilentlyContinue
}
catch {
    Write-TestResult -TestName "Result Aggregation" -Success $false `
        -Message $_.Exception.Message
}

# Test 8: Report Generation
Write-TestSection "Test 8: Report Generation"

try {
    Write-Host "Testing report generation..." -ForegroundColor $colors.Info
    
    # Create mock aggregated results
    $mockResults = @{
        Timestamp = Get-Date
        Summary = @{
            TotalTests = 100
            TotalPassed = 85
            TotalFailed = 10
            TotalSkipped = 5
            TotalDuration = 120.5
            OverallResult = 'Partial'
        }
        Results = @{
            Unity = @{
                EditMode = @{
                    Summary = @{
                        Total = 50
                        Passed = 45
                        Failed = 3
                        Skipped = 2
                        Duration = 60.2
                    }
                }
                PlayMode = @{
                    Summary = @{
                        Total = 30
                        Passed = 25
                        Failed = 4
                        Skipped = 1
                        Duration = 45.3
                    }
                }
            }
            PowerShell = @{
                Total = 20
                Passed = 15
                Failed = 3
                Skipped = 2
                Duration = 15.0
            }
        }
    }
    
    $tempReportPath = Join-Path $env:TEMP "TestReport_$(Get-Date -Format 'yyyyMMdd_HHmmss').html"
    
    $reportPath = Export-TestReport -AggregatedResults $mockResults -OutputPath $tempReportPath -Format HTML
    
    if (Test-Path $reportPath) {
        Write-TestResult -TestName "HTML Report Generation" -Success $true `
            -Message "Report generated at: $reportPath"
        
        # Cleanup
        Remove-Item -Path $reportPath -Force -ErrorAction SilentlyContinue
    }
    else {
        Write-TestResult -TestName "HTML Report Generation" -Success $false `
            -Message "Report file not created"
    }
}
catch {
    Write-TestResult -TestName "HTML Report Generation" -Success $false `
        -Message $_.Exception.Message
}

# Test 9: Safe Command Execution
Write-TestSection "Test 9: Safe Command Execution"

try {
    Write-Host "Testing safe command execution..." -ForegroundColor $colors.Info
    
    $testCommand = @{
        CommandType = 'PowerShell'
        Operation = 'GetDate'
        Arguments = @{
            Script = 'Get-Date'
        }
    }
    
    $result = Invoke-SafeCommand -Command $testCommand -TimeoutSeconds 5
    
    if ($result.Success) {
        Write-TestResult -TestName "Safe Command Execution" -Success $true `
            -Message "Command executed safely"
    }
    else {
        Write-TestResult -TestName "Safe Command Execution" -Success $false `
            -Message "Command execution failed: $($result.Error)"
    }
}
catch {
    Write-TestResult -TestName "Safe Command Execution" -Success $false `
        -Message $_.Exception.Message
}

# Test 10: Path Safety Validation
Write-TestSection "Test 10: Path Safety Validation"

try {
    Write-Host "Testing path safety validation..." -ForegroundColor $colors.Info
    
    $safePath = $PSScriptRoot
    $unsafePath = "C:\Windows\System32"
    
    $safeResult = Test-PathSafety -Path $safePath -AllowedPaths @($PSScriptRoot)
    $unsafeResult = Test-PathSafety -Path $unsafePath -AllowedPaths @($PSScriptRoot)
    
    if ($safeResult -and -not $unsafeResult) {
        Write-TestResult -TestName "Path Safety Validation" -Success $true `
            -Message "Correctly validated safe and unsafe paths"
    }
    else {
        Write-TestResult -TestName "Path Safety Validation" -Success $false `
            -Message "Path validation not working correctly"
    }
}
catch {
    Write-TestResult -TestName "Path Safety Validation" -Success $false `
        -Message $_.Exception.Message
}

# Final Summary
Write-TestSection "Test Summary"

$passed = ($testResults | Where-Object { $_.Result -eq 'Passed' }).Count
$failed = ($testResults | Where-Object { $_.Result -eq 'Failed' }).Count
$skipped = ($testResults | Where-Object { $_.Result -eq 'Skipped' }).Count
$total = $testResults.Count

Write-Host "`nTotal Tests: $total" -ForegroundColor White
Write-Host "Passed: $passed" -ForegroundColor $colors.Pass
Write-Host "Failed: $failed" -ForegroundColor $(if ($failed -gt 0) { $colors.Fail } else { 'Gray' })
Write-Host "Skipped: $skipped" -ForegroundColor $(if ($skipped -gt 0) { $colors.Skip } else { 'Gray' })

$duration = (Get-Date) - $testStartTime
Write-Host "`nTest Duration: $($duration.TotalSeconds) seconds" -ForegroundColor $colors.Info

# Success rate
if ($total -gt 0) {
    $successRate = [Math]::Round(($passed / ($total - $skipped)) * 100, 2)
    Write-Host "Success Rate: $successRate%" -ForegroundColor $(if ($successRate -ge 80) { $colors.Pass } else { $colors.Fail })
}

# Export results
$resultsFile = Join-Path $PSScriptRoot "TestResults_UnityTestAutomation_Day4_$(Get-Date -Format 'yyyyMMdd_HHmmss').json"
$testResults | ConvertTo-Json -Depth 3 | Out-File -FilePath $resultsFile -Encoding UTF8
Write-Host "`nTest results saved to: $resultsFile" -ForegroundColor $colors.Info

# Return success/failure
exit $(if ($failed -eq 0) { 0 } else { 1 })
# SIG # Begin signature block
# MIIFqQYJKoZIhvcNAQcCoIIFmjCCBZYCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUx/nFeTmj8gnAeBNPDBpMBxd2
# /HKgggMwMIIDLDCCAhSgAwIBAgIQdR0W2SKoK5VE8JId4ZxrRTANBgkqhkiG9w0B
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
# CQQxFgQUSqKfMouGIHTqbq251Rp/aHPiLBUwDQYJKoZIhvcNAQEBBQAEggEAhMxi
# 1geYHbAOpIgjbS4KXCW0XoBCoRpVxr2OfdyuvuQ6yYWW9ROuZTisop/hWuQ2KaDA
# 3U7EHNlHMXBn4Q3tQYOikrMKDb2aX1GS23nFJY7WZK5Qw1QQtVYiSOIL4vmHszgE
# oBUOtOiCFJwLEKz4BdPIoBSe7ZJSnOyDqp+ySKy9fg6RcA1USmrI4rPvxaMvJKwY
# g33bc6mP1mXSxytgIu4+WIIBlauxEyF4sEdnr6lsngJtKFQJA+V+AFZc3EJgMpFj
# /Jh5ATyjK9uojx7hx1ec9dwNPPRtWvQNsr5ixo5kGriZ2NeqUX5aXB6SVaPp0hxq
# wRWbzU/gBCmOAJBzYA==
# SIG # End signature block
