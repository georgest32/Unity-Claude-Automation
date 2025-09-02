# Test-PredictiveAnalysis.ps1
# Comprehensive test suite for Unity-Claude-PredictiveAnalysis module
# Phase 3 Day 3-4: Advanced Intelligence Features

param(
    [switch]$SaveResults,
    [switch]$Verbose,
    [switch]$TestWithGit,  # Only run git-dependent tests if in a git repo
    [string]$TestPath = $PSScriptRoot
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

# Initialize test variables
$script:TestRoadmap = $null

# Test results structure
$script:TestResults = @{
    TestSuite = 'PredictiveAnalysis'
    StartTime = Get-Date
    Environment = @{
        PowerShellVersion = $PSVersionTable.PSVersion.ToString()
        ModulePath = Join-Path $PSScriptRoot 'Modules\Unity-Claude-PredictiveAnalysis'
        TestPath = $TestPath
    }
    Tests = @()
    Summary = @{
        Total = 0
        Passed = 0
        Failed = 0
        Skipped = 0
    }
}

# Helper function to add test result
function Add-TestResult {
    param(
        [string]$Name,
        [string]$Status,
        [object]$Result = $null,
        [string]$Error = '',
        [long]$Duration = 0
    )
    
    $test = @{
        Name = $Name
        Status = $Status
        Result = $Result
        Error = $Error
        Duration = $Duration
        Timestamp = Get-Date
    }
    
    $script:TestResults.Tests += $test
    $script:TestResults.Summary.Total++
    $script:TestResults.Summary.$Status++
    
    $color = switch ($Status) {
        'Passed' { 'Green' }
        'Failed' { 'Red' }
        'Skipped' { 'Yellow' }
        default { 'Gray' }
    }
    
    Write-Host "[$Status] $Name $(if ($Duration) {"($Duration ms)"})" -ForegroundColor $color
    if ($Error -and $Verbose) {
        Write-Host "  Error: $Error" -ForegroundColor Red
    }
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host " Predictive Analysis Module Test Suite " -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Test 1: Module Import
Write-Host "Test Group 1: Module Loading" -ForegroundColor Yellow
Write-Host "-----------------------------" -ForegroundColor Gray

$sw = [System.Diagnostics.Stopwatch]::StartNew()
try {
    # Import required dependencies first
    Import-Module "$PSScriptRoot\Modules\Unity-Claude-CPG\Unity-Claude-CPG.psd1" -Force -ErrorAction Stop
    Import-Module "$PSScriptRoot\Modules\Unity-Claude-CPG\Unity-Claude-SemanticAnalysis.psd1" -Force -ErrorAction Stop
    Import-Module "$PSScriptRoot\Modules\Unity-Claude-LLM\Unity-Claude-LLM.psd1" -Force -ErrorAction Stop
    Import-Module "$PSScriptRoot\Modules\Unity-Claude-Cache\Unity-Claude-Cache.psd1" -Force -ErrorAction Stop
    
    # Now import the predictive analysis module
    Import-Module "$PSScriptRoot\Modules\Unity-Claude-PredictiveAnalysis\Unity-Claude-PredictiveAnalysis.psd1" -Force -ErrorAction Stop
    
    $commands = Get-Command -Module Unity-Claude-PredictiveAnalysis
    if ($commands.Count -ge 25) {
        Add-TestResult -Name "Module Import" -Status "Passed" `
            -Result "Loaded $($commands.Count) functions" -Duration $sw.ElapsedMilliseconds
    } else {
        throw "Expected at least 25 functions, got $($commands.Count)"
    }
}
catch {
    Add-TestResult -Name "Module Import" -Status "Failed" -Error $_.Exception.Message
}
finally {
    $sw.Stop()
}

# Test 2: Cache Initialization
Write-Host ""
Write-Host "Test Group 2: Initialization" -ForegroundColor Yellow
Write-Host "-----------------------------" -ForegroundColor Gray

$sw.Restart()
try {
    $result = Initialize-PredictiveCache -MaxSizeMB 50 -TTLMinutes 30
    if ($result -eq $true) {
        Add-TestResult -Name "Cache Initialization" -Status "Passed" `
            -Result "Cache initialized successfully" -Duration $sw.ElapsedMilliseconds
    } else {
        throw "Cache initialization returned false"
    }
}
catch {
    Add-TestResult -Name "Cache Initialization" -Status "Failed" -Error $_.Exception.Message
}
finally {
    $sw.Stop()
}

# Test 3: Trend Analysis (Git-dependent)
if ($TestWithGit) {
    Write-Host ""
    Write-Host "Test Group 3: Trend Analysis" -ForegroundColor Yellow
    Write-Host "-----------------------------" -ForegroundColor Gray
    
    # Test Code Evolution Trend
    $sw.Restart()
    try {
        $trend = Get-CodeEvolutionTrend -Path $TestPath -DaysBack 7 -Granularity Daily
        if ($trend -and $trend.TotalCommits -ge 0) {
            Add-TestResult -Name "Code Evolution Trend" -Status "Passed" `
                -Result "Found $($trend.TotalCommits) commits" -Duration $sw.ElapsedMilliseconds
        } else {
            throw "No trend data returned"
        }
    }
    catch {
        Add-TestResult -Name "Code Evolution Trend" -Status "Failed" -Error $_.Exception.Message
    }
    finally {
        $sw.Stop()
    }
    
    # Test Code Churn
    $sw.Restart()
    try {
        $churn = Measure-CodeChurn -Path $TestPath -DaysBack 7
        if ($churn -and $churn.ChurnRate -ge 0) {
            Add-TestResult -Name "Code Churn Measurement" -Status "Passed" `
                -Result "Churn rate: $($churn.ChurnRate) lines/day" -Duration $sw.ElapsedMilliseconds
        } else {
            throw "Invalid churn data"
        }
    }
    catch {
        Add-TestResult -Name "Code Churn Measurement" -Status "Failed" -Error $_.Exception.Message
    }
    finally {
        $sw.Stop()
    }
    
    # Test Hotspot Analysis
    $sw.Restart()
    try {
        $hotspots = Get-HotspotAnalysis -Path $TestPath -TopN 5 -DaysBack 30
        if ($hotspots) {
            Add-TestResult -Name "Hotspot Analysis" -Status "Passed" `
                -Result "Analyzed $($hotspots.Hotspots.Count) hotspots" -Duration $sw.ElapsedMilliseconds
        } else {
            throw "No hotspot data returned"
        }
    }
    catch {
        Add-TestResult -Name "Hotspot Analysis" -Status "Failed" -Error $_.Exception.Message
    }
    finally {
        $sw.Stop()
    }
}
else {
    Add-TestResult -Name "Code Evolution Trend" -Status "Skipped" -Result "Git tests disabled"
    Add-TestResult -Name "Code Churn Measurement" -Status "Skipped" -Result "Git tests disabled"
    Add-TestResult -Name "Hotspot Analysis" -Status "Skipped" -Result "Git tests disabled"
}

# Test 4: Maintenance Prediction
Write-Host ""
Write-Host "Test Group 4: Maintenance Prediction" -ForegroundColor Yellow
Write-Host "-------------------------------------" -ForegroundColor Gray

# Create a sample graph for testing
$testGraph = $null
$sw.Restart()
try {
    $testGraph = New-CPGraph -Name "TestGraph"
    
    # Add some test nodes
    $funcNode = New-CPGNode -Name "Test-Function" -Type "Function" -Properties @{
        LineCount = 75
        CyclomaticComplexity = 12
        Parameters = @('param1', 'param2')
    }
    Add-CPGNode -Graph $testGraph -Node $funcNode
    
    $classNode = New-CPGNode -Name "TestClass" -Type "Class" -Properties @{
        File = "TestClass.ps1"
    }
    Add-CPGNode -Graph $testGraph -Node $classNode
    
    # Add edges
    $edge = New-CPGEdge -SourceId $classNode.Id -TargetId $funcNode.Id -Type "Contains"
    Add-CPGEdge -Graph $testGraph -Edge $edge
    
    Add-TestResult -Name "Test Graph Creation" -Status "Passed" `
        -Result "Created graph with $($testGraph.Nodes.Count) nodes" -Duration $sw.ElapsedMilliseconds
}
catch {
    Add-TestResult -Name "Test Graph Creation" -Status "Failed" -Error $_.Exception.Message
}
finally {
    $sw.Stop()
}

# Test Maintenance Prediction
$sw.Restart()
try {
    $prediction = Get-MaintenancePrediction -Path $TestPath -Graph $testGraph
    if ($prediction -and $prediction.Score -ge 0 -and $prediction.Score -le 100) {
        Add-TestResult -Name "Maintenance Prediction" -Status "Passed" `
            -Result "Score: $($prediction.Score), Risk: $($prediction.RiskLevel)" -Duration $sw.ElapsedMilliseconds
    } else {
        throw "Invalid prediction score"
    }
}
catch {
    Add-TestResult -Name "Maintenance Prediction" -Status "Failed" -Error $_.Exception.Message
}
finally {
    $sw.Stop()
}

# Test Technical Debt Calculation
$sw.Restart()
try {
    $debt = Calculate-TechnicalDebt -Path $TestPath -Graph $testGraph
    if ($debt -and $debt.TotalHours -ge 0) {
        Add-TestResult -Name "Technical Debt Calculation" -Status "Passed" `
            -Result "Total debt: $($debt.TotalHours) hours" -Duration $sw.ElapsedMilliseconds
    } else {
        throw "Invalid debt calculation"
    }
}
catch {
    Add-TestResult -Name "Technical Debt Calculation" -Status "Failed" -Error $_.Exception.Message
}
finally {
    $sw.Stop()
}

# Test 5: Refactoring Detection
Write-Host ""
Write-Host "Test Group 5: Refactoring Detection" -ForegroundColor Yellow
Write-Host "------------------------------------" -ForegroundColor Gray

# Test Find Refactoring Opportunities
$sw.Restart()
try {
    # Add more nodes for refactoring detection
    $longMethod = New-CPGNode -Name "Very-Long-Method" -Type "Function" -Properties @{
        LineCount = 150
        CyclomaticComplexity = 25
        Parameters = @('p1', 'p2', 'p3', 'p4', 'p5')
    }
    Add-CPGNode -Graph $testGraph -Node $longMethod
    
    $opportunities = Find-RefactoringOpportunities -Graph $testGraph -MaxResults 5
    if ($opportunities -and $opportunities.Summary) {
        Add-TestResult -Name "Find Refactoring Opportunities" -Status "Passed" `
            -Result "Found $($opportunities.Summary.Total) opportunities" -Duration $sw.ElapsedMilliseconds
    } else {
        throw "No opportunities found"
    }
}
catch {
    Add-TestResult -Name "Find Refactoring Opportunities" -Status "Failed" -Error $_.Exception.Message
}
finally {
    $sw.Stop()
}

# Test Find Long Methods
$sw.Restart()
try {
    $longMethods = Find-LongMethods -Graph $testGraph -Threshold 50
    if ($longMethods -ne $null) {
        Add-TestResult -Name "Find Long Methods" -Status "Passed" `
            -Result "Found $($longMethods.Count) long methods" -Duration $sw.ElapsedMilliseconds
    } else {
        throw "Function returned null"
    }
}
catch {
    Add-TestResult -Name "Find Long Methods" -Status "Failed" -Error $_.Exception.Message
}
finally {
    $sw.Stop()
}

# Test Find God Classes
$sw.Restart()
try {
    # Add a god class for testing
    $godClass = New-CPGNode -Name "GodClass" -Type "Class" -Properties @{
        File = "GodClass.ps1"
    }
    Add-CPGNode -Graph $testGraph -Node $godClass
    
    # Add many methods to make it a god class
    for ($i = 1; $i -le 25; $i++) {
        $method = New-CPGNode -Name "Method$i" -Type "Function" -Properties @{
            LineCount = 20
        }
        Add-CPGNode -Graph $testGraph -Node $method
        $edge = New-CPGEdge -SourceId $godClass.Id -TargetId $method.Id -Type "Contains"
        Add-CPGEdge -Graph $testGraph -Edge $edge
    }
    
    $godClasses = Find-GodClasses -Graph $testGraph -MethodThreshold 20
    if ($godClasses -ne $null) {
        Add-TestResult -Name "Find God Classes" -Status "Passed" `
            -Result "Found $($godClasses.Count) god classes" -Duration $sw.ElapsedMilliseconds
    } else {
        throw "Function returned null"
    }
}
catch {
    Add-TestResult -Name "Find God Classes" -Status "Failed" -Error $_.Exception.Message
}
finally {
    $sw.Stop()
}

# Test 6: Code Smell Prediction
Write-Host ""
Write-Host "Test Group 6: Code Smell Prediction" -ForegroundColor Yellow
Write-Host "------------------------------------" -ForegroundColor Gray

# Test Predict Code Smells
$sw.Restart()
try {
    $smells = Predict-CodeSmells -Graph $testGraph
    if ($smells -and $smells.Score -ge 0) {
        Add-TestResult -Name "Predict Code Smells" -Status "Passed" `
            -Result "Smell score: $($smells.Score), Total: $($smells.Summary.Total)" -Duration $sw.ElapsedMilliseconds
    } else {
        throw "Invalid smell prediction"
    }
}
catch {
    Add-TestResult -Name "Predict Code Smells" -Status "Failed" -Error $_.Exception.Message
}
finally {
    $sw.Stop()
}

# Test 7: Improvement Roadmap
Write-Host ""
Write-Host "Test Group 7: Improvement Roadmap" -ForegroundColor Yellow
Write-Host "----------------------------------" -ForegroundColor Gray

# Test New Improvement Roadmap
$sw.Restart()
try {
    $roadmap = New-ImprovementRoadmap -Path $TestPath -Graph $testGraph -MaxPhases 3
    if ($roadmap -and $roadmap.Phases.Count -gt 0) {
        Add-TestResult -Name "New Improvement Roadmap" -Status "Passed" `
            -Result "$($roadmap.Phases.Count) phases, $($roadmap.TotalEffort) hours" -Duration $sw.ElapsedMilliseconds
    } else {
        throw "Invalid roadmap generated"
    }
    
    # Store for export test
    $script:TestRoadmap = $roadmap
}
catch {
    Add-TestResult -Name "New Improvement Roadmap" -Status "Failed" -Error $_.Exception.Message
}
finally {
    $sw.Stop()
}

# Test Export Roadmap Report
if ($null -ne $script:TestRoadmap) {
    $sw.Restart()
    try {
        $outputPath = Join-Path $env:TEMP "TestRoadmap_$(Get-Date -Format 'yyyyMMdd_HHmmss').json"
        $result = Export-RoadmapReport -Roadmap $script:TestRoadmap -OutputPath $outputPath -Format JSON
        
        if (Test-Path $result) {
            Add-TestResult -Name "Export Roadmap Report" -Status "Passed" `
                -Result "Exported to $result" -Duration $sw.ElapsedMilliseconds
            
            # Clean up
            Remove-Item $result -Force -ErrorAction SilentlyContinue
        } else {
            throw "Export file not created"
        }
    }
    catch {
        Add-TestResult -Name "Export Roadmap Report" -Status "Failed" -Error $_.Exception.Message
    }
    finally {
        $sw.Stop()
    }
}
else {
    Add-TestResult -Name "Export Roadmap Report" -Status "Skipped" -Result "No roadmap to export"
}

# Test 8: Utility Functions
Write-Host ""
Write-Host "Test Group 8: Utility Functions" -ForegroundColor Yellow
Write-Host "--------------------------------" -ForegroundColor Gray

# Test Bug Probability Prediction
$sw.Restart()
try {
    $bugProb = Predict-BugProbability -Path $TestPath -Graph $testGraph
    if ($bugProb -and $bugProb.Probability -ge 0 -and $bugProb.Probability -le 1) {
        Add-TestResult -Name "Predict Bug Probability" -Status "Passed" `
            -Result "Probability: $($bugProb.Probability), Risk: $($bugProb.Risk)" -Duration $sw.ElapsedMilliseconds
    } else {
        throw "Invalid probability value"
    }
}
catch {
    Add-TestResult -Name "Predict Bug Probability" -Status "Failed" -Error $_.Exception.Message
}
finally {
    $sw.Stop()
}

# Test Complexity Trend
$sw.Restart()
try {
    $trend = Get-ComplexityTrend -Path $TestPath -Samples 3
    if ($trend -and $trend.AverageComplexity -ge 0) {
        Add-TestResult -Name "Get Complexity Trend" -Status "Passed" `
            -Result "Avg complexity: $($trend.AverageComplexity)" -Duration $sw.ElapsedMilliseconds
    } else {
        throw "Invalid complexity trend"
    }
}
catch {
    Add-TestResult -Name "Get Complexity Trend" -Status "Failed" -Error $_.Exception.Message
}
finally {
    $sw.Stop()
}

# Test ROI Analysis
if ($null -ne $script:TestRoadmap) {
    $sw.Restart()
    try {
        $roi = Get-ROIAnalysis -Roadmap $script:TestRoadmap
        if ($roi -and $roi.PaybackPeriod -ge 0) {
            Add-TestResult -Name "Get ROI Analysis" -Status "Passed" `
                -Result "Payback: $($roi.PaybackPeriod) months" -Duration $sw.ElapsedMilliseconds
        } else {
            throw "Invalid ROI analysis"
        }
    }
    catch {
        Add-TestResult -Name "Get ROI Analysis" -Status "Failed" -Error $_.Exception.Message
    }
    finally {
        $sw.Stop()
    }
}
else {
    Add-TestResult -Name "Get ROI Analysis" -Status "Skipped" -Result "No roadmap for ROI"
}

# Complete test run
$script:TestResults.EndTime = Get-Date
$script:TestResults.Duration = $script:TestResults.EndTime - $script:TestResults.StartTime

# Display Summary
Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host " Test Summary" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Total Tests: $($script:TestResults.Summary.Total)" -ForegroundColor White
Write-Host "Passed: $($script:TestResults.Summary.Passed)" -ForegroundColor Green
Write-Host "Failed: $($script:TestResults.Summary.Failed)" -ForegroundColor $(if ($script:TestResults.Summary.Failed -gt 0) { 'Red' } else { 'Gray' })
Write-Host "Skipped: $($script:TestResults.Summary.Skipped)" -ForegroundColor Yellow
Write-Host "Duration: $([Math]::Round($script:TestResults.Duration.TotalSeconds, 2)) seconds" -ForegroundColor Gray
Write-Host ""

$passRate = if ($script:TestResults.Summary.Total -gt 0) {
    [Math]::Round(($script:TestResults.Summary.Passed / $script:TestResults.Summary.Total) * 100, 1)
} else { 0 }

Write-Host "Pass Rate: $passRate%" -ForegroundColor $(if ($passRate -ge 80) { 'Green' } elseif ($passRate -ge 60) { 'Yellow' } else { 'Red' })

# Save results if requested
if ($SaveResults) {
    $resultsFile = "PredictiveAnalysis-TestResults-$(Get-Date -Format 'yyyyMMdd-HHmmss').json"
    $script:TestResults | ConvertTo-Json -Depth 10 | Out-File -FilePath $resultsFile -Encoding UTF8
    Write-Host ""
    Write-Host "Results saved to: $resultsFile" -ForegroundColor Cyan
}

# Return success/failure
if ($script:TestResults.Summary.Failed -eq 0) {
    Write-Host ""
    Write-Host "ALL TESTS PASSED!" -ForegroundColor Green
    exit 0
}
else {
    Write-Host ""
    Write-Host "SOME TESTS FAILED!" -ForegroundColor Red
    exit 1
}
# SIG # Begin signature block
# MIIFzgYJKoZIhvcNAQcCoIIFvzCCBbsCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCD2vlCSAjL3s5/b
# CqtqhE+EVsOvgn1oaY4AIdFGo/ke86CCAzAwggMsMIICFKADAgECAhB1HRbZIqgr
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
# MAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIDUkcGiyRhA128EiXfHy9M7u
# V76zPRRym7n2JNSMJJO6MA0GCSqGSIb3DQEBAQUABIIBAAjhWr+5Q99t3I/RGz+X
# IxRGXFZ5c1i5sWkzo3PMOTUxc0a8IqnSkYRbYGcC060ZbJpPsPhc1rIv+yZiro6C
# 1r7kjQ+mwxuxXaIRYtpN22zVNsjhPora0L6JT7/LRUhEukEAec+muclbx2YmLCev
# 2qmidYA1TuXE3OvRW6z64nutDmZ/kPUwGtsEBgPfuqve0/0a5W41vCg1jaCR1P4S
# fu8+WT3qBT0rcdE/KSCWbT/r1/lsNYmqKkbVb692GdFjVuPFGFF2NRZM1K67/yJ2
# aVZRKfbYTWPT4GPO2rLkhCl+xSA/okSvL1y1o7O4SipZA/Xi5gvgza4g/Mh5pS/E
# OVA=
# SIG # End signature block
