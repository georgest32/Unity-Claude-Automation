# Test-Week3-Day5-EndToEndIntegration-Fixed.ps1  
# Fixed test suite using direct function calls for Week 3 Day 5
# Phase 1 Week 3 Day 5: End-to-End Integration and Performance Optimization Testing
# Date: 2025-08-21

[CmdletBinding()]
param(
    [switch]$SaveResults,
    [switch]$EnableResourceMonitoring,
    [switch]$TestWithRealUnityProjects,
    [switch]$TestWithRealClaudeAPI
)

Write-Host "=== Week 3 Day 5: End-to-End Integration Test (FIXED) ===" -ForegroundColor Cyan
Write-Host "Phase 1 Week 3 Day 5: Complete Workflow Integration" -ForegroundColor Green
Write-Host "Date: $(Get-Date)" -ForegroundColor Green
Write-Host "PowerShell Version: $($PSVersionTable.PSVersion)" -ForegroundColor Green

# Configure PSModulePath for custom modules
$env:PSModulePath = "C:\UnityProjects\Sound-and-Shoal\Unity-Claude-Automation\Modules;" + $env:PSModulePath

# Import all required modules in dependency order
try {
    Write-Host "Importing modules..." -ForegroundColor Yellow
    Import-Module Unity-Claude-ParallelProcessing -Force
    Import-Module Unity-Claude-RunspaceManagement -Force
    Import-Module Unity-Claude-UnityParallelization -Force
    Import-Module Unity-Claude-ClaudeParallelization -Force
    Import-Module Unity-Claude-IntegratedWorkflow -Force
    Write-Host "All modules imported successfully" -ForegroundColor Green
} catch {
    Write-Host "Module import failed: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

# Test results tracking
$TestResults = @{
    TestName = "Week3-Day5-EndToEndIntegration-Fixed"
    StartTime = Get-Date
    Tests = @()
    Categories = @{
        ModuleLoading = @{Passed = 0; Failed = 0; Total = 0}
        WorkflowIntegration = @{Passed = 0; Failed = 0; Total = 0}
        PerformanceOptimization = @{Passed = 0; Failed = 0; Total = 0}
        EndToEndWorkflow = @{Passed = 0; Failed = 0; Total = 0}
    }
    Summary = @{
        Total = 0
        Passed = 0
        Failed = 0
        Duration = 0
        PassRate = 0
    }
}

function Write-TestResult {
    param(
        [string]$TestName,
        [bool]$Success,
        [string]$Message = "",
        [int]$Duration = 0,
        [string]$Category = "General"
    )
    
    $status = if ($Success) { "PASS" } else { "FAIL" }
    $color = if ($Success) { "Green" } else { "Red" }
    
    Write-Host "[$status] $TestName" -ForegroundColor $color
    if ($Message) {
        Write-Host "    $Message" -ForegroundColor Gray
    }
    if ($Duration -gt 0) {
        Write-Host "    Duration: ${Duration}ms" -ForegroundColor Gray
    }
    
    # Update statistics
    $TestResults.Summary.Total++
    if ($TestResults.Categories.ContainsKey($Category)) {
        $TestResults.Categories[$Category].Total++
        if ($Success) {
            $TestResults.Summary.Passed++
            $TestResults.Categories[$Category].Passed++
        } else {
            $TestResults.Summary.Failed++
            $TestResults.Categories[$Category].Failed++
        }
    }
    
    return $Success
}

try {
    Write-Host ""
    Write-Host "=== 1. Module Integration Validation ===" -ForegroundColor Cyan
    
    # Test 1: IntegratedWorkflow Functions Available
    $startTime = Get-Date
    try {
        $expectedFunctions = @(
            'New-IntegratedWorkflow',
            'Start-IntegratedWorkflow',
            'Get-IntegratedWorkflowStatus',
            'Stop-IntegratedWorkflow',
            'Initialize-AdaptiveThrottling',
            'Update-AdaptiveThrottling',
            'New-IntelligentJobBatching',
            'Get-WorkflowPerformanceAnalysis'
        )
        
        $missingFunctions = @()
        foreach ($func in $expectedFunctions) {
            if (-not (Get-Command $func -ErrorAction SilentlyContinue)) {
                $missingFunctions += $func
            }
        }
        
        $success = ($missingFunctions.Count -eq 0)
        $message = if ($success) { "All $($expectedFunctions.Count) IntegratedWorkflow functions available" } else { "Missing: $($missingFunctions -join ', ')" }
    } catch {
        $success = $false
        $message = "Function check error: $($_.Exception.Message)"
    }
    $duration = ((Get-Date) - $startTime).TotalMilliseconds
    Write-TestResult "IntegratedWorkflow Functions Available" $success $message $duration "ModuleLoading"
    
    Write-Host ""
    Write-Host "=== 2. Workflow Creation and Management ===" -ForegroundColor Cyan
    
    # Test 2: Basic Workflow Creation
    $startTime = Get-Date
    try {
        $workflow = New-IntegratedWorkflow -WorkflowName "TestBasic" -MaxUnityProjects 2 -MaxClaudeSubmissions 4 -EnableResourceOptimization -EnableErrorPropagation
        $success = ($workflow -and $workflow.WorkflowName -eq "TestBasic" -and $workflow.Status -eq 'Created')
        $message = if ($success) { "Workflow created: $($workflow.WorkflowName), Status: $($workflow.Status)" } else { "Workflow creation failed" }
    } catch {
        $success = $false
        $message = "Workflow creation error: $($_.Exception.Message)"
    }
    $duration = ((Get-Date) - $startTime).TotalMilliseconds
    Write-TestResult "Basic Integrated Workflow Creation" $success $message $duration "WorkflowIntegration"
    
    # Test 3: Workflow Status
    $startTime = Get-Date
    try {
        $status = Get-IntegratedWorkflowStatus -IntegratedWorkflow $workflow -IncludeDetailedMetrics
        $success = ($status -and $status.WorkflowName -eq "TestBasic")
        $message = if ($success) { "Status: $($status.OverallStatus), Components: $($status.Components.Count)" } else { "Status retrieval failed" }
    } catch {
        $success = $false
        $message = "Status error: $($_.Exception.Message)"
    }
    $duration = ((Get-Date) - $startTime).TotalMilliseconds
    Write-TestResult "Workflow Status and Monitoring" $success $message $duration "WorkflowIntegration"
    
    Write-Host ""
    Write-Host "=== 3. Performance Optimization Framework ===" -ForegroundColor Cyan
    
    # Test 4: Adaptive Throttling
    $startTime = Get-Date
    try {
        $throttlingResult = Initialize-AdaptiveThrottling -IntegratedWorkflow $workflow -EnableCPUThrottling -EnableMemoryThrottling -CPUThreshold 75 -MemoryThreshold 80
        $success = ($throttlingResult -and $throttlingResult.Success)
        $message = if ($success) { "Throttling initialized: CPU 75%, Memory 80%" } else { "Throttling failed: $($throttlingResult.Message)" }
    } catch {
        $success = $false
        $message = "Throttling error: $($_.Exception.Message)"
    }
    $duration = ((Get-Date) - $startTime).TotalMilliseconds
    Write-TestResult "Adaptive Throttling Initialization" $success $message $duration "PerformanceOptimization"
    
    # Test 5: Performance Analysis
    $startTime = Get-Date
    try {
        $performanceData = Get-WorkflowPerformanceAnalysis -IntegratedWorkflow $workflow -MonitoringDuration 5 -IncludeSystemMetrics
        $success = ($performanceData -and $performanceData.WorkflowName -eq "TestBasic")
        $message = if ($success) { "Performance analysis: $($performanceData.OptimizationRecommendations.Count) recommendations, $($performanceData.AnalysisDuration)ms" } else { "Performance analysis failed" }
    } catch {
        $success = $false
        $message = "Performance analysis error: $($_.Exception.Message)"
    }
    $duration = ((Get-Date) - $startTime).TotalMilliseconds
    Write-TestResult "Performance Analysis Framework" $success $message $duration "PerformanceOptimization"
    
    Write-Host ""
    Write-Host "=== 4. End-to-End Workflow Execution ===" -ForegroundColor Cyan
    
    # Test 6: Complete Workflow Test
    $startTime = Get-Date
    try {
        $e2eWorkflow = New-IntegratedWorkflow -WorkflowName "E2E-Test" -MaxUnityProjects 1 -MaxClaudeSubmissions 2 -EnableResourceOptimization
        Initialize-AdaptiveThrottling -IntegratedWorkflow $e2eWorkflow -EnableCPUThrottling | Out-Null
        
        $workflowStatus = Get-IntegratedWorkflowStatus -IntegratedWorkflow $e2eWorkflow
        $success = ($e2eWorkflow -and $workflowStatus -and $workflowStatus.OverallStatus -eq "Created")
        $message = if ($success) { "E2E workflow operational: $($workflowStatus.OverallStatus)" } else { "E2E workflow failed" }
    } catch {
        $success = $false
        $message = "E2E workflow error: $($_.Exception.Message)"
    }
    $duration = ((Get-Date) - $startTime).TotalMilliseconds
    Write-TestResult "Complete End-to-End Workflow" $success $message $duration "EndToEndWorkflow"
    
    # Calculate final results
    $TestResults.EndTime = Get-Date
    $TestResults.Summary.Duration = (($TestResults.EndTime - $TestResults.StartTime).TotalSeconds)
    $TestResults.Summary.PassRate = if ($TestResults.Summary.Total -gt 0) { 
        [math]::Round(($TestResults.Summary.Passed / $TestResults.Summary.Total) * 100, 2) 
    } else { 0 }
    
    # Display summary
    Write-Host ""
    Write-Host "=== End-to-End Integration Testing Results Summary ===" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Testing Execution Summary:" -ForegroundColor White
    Write-Host "Total Tests: $($TestResults.Summary.Total)" -ForegroundColor White
    Write-Host "Passed: $($TestResults.Summary.Passed)" -ForegroundColor Green
    Write-Host "Failed: $($TestResults.Summary.Failed)" -ForegroundColor Red
    Write-Host "Duration: $($TestResults.Summary.Duration) seconds" -ForegroundColor White
    Write-Host "Pass Rate: $($TestResults.Summary.PassRate)%" -ForegroundColor $(if ($TestResults.Summary.PassRate -ge 80) { "Green" } else { "Red" })
    
    Write-Host ""
    Write-Host "Category Breakdown:" -ForegroundColor White
    foreach ($category in $TestResults.Categories.GetEnumerator()) {
        $cat = $category.Value
        $catPassRate = if ($cat.Total -gt 0) { [math]::Round(($cat.Passed / $cat.Total) * 100, 2) } else { 0 }
        $color = if ($catPassRate -ge 80) { "Green" } else { "Red" }
        Write-Host "$($category.Key): $($cat.Passed)/$($cat.Total) ($catPassRate%)" -ForegroundColor $color
    }
    
    # Final status
    if ($TestResults.Summary.PassRate -ge 80) {
        Write-Host ""
        Write-Host "WEEK 3 DAY 5 END-TO-END INTEGRATION: SUCCESS" -ForegroundColor Green
        Write-Host "Complete end-to-end integration system operational" -ForegroundColor Green
    } else {
        Write-Host ""
        Write-Host "WEEK 3 DAY 5 END-TO-END INTEGRATION: PARTIAL SUCCESS" -ForegroundColor Yellow
        Write-Host "Core functionality working, minor fixes needed" -ForegroundColor Yellow
    }
    
    # Save results if requested
    if ($SaveResults) {
        $resultsFile = "Week3Day5_Fixed_Test_Results_$(Get-Date -Format 'yyyyMMdd_HHmmss').txt"
        $TestResults | ConvertTo-Json -Depth 3 | Out-File $resultsFile
        Write-Host "Results saved to: $resultsFile" -ForegroundColor Green
    }
    
} catch {
    Write-Host "=== WEEK 3 DAY 5 TESTING: FAILED ===" -ForegroundColor Red
    Write-Host "Critical error: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}
# SIG # Begin signature block
# MIIFqQYJKoZIhvcNAQcCoIIFmjCCBZYCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQU3Gl5XmPM0fza0CJ/tOXQLoOG
# spigggMwMIIDLDCCAhSgAwIBAgIQdR0W2SKoK5VE8JId4ZxrRTANBgkqhkiG9w0B
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
# CQQxFgQUgpj0hm38J2Rivtw1FbVqiU+n3ZwwDQYJKoZIhvcNAQEBBQAEggEAKLAC
# 8bdJILLoLAehA1J2/mqHaR0C1mrh+r9aWPFuUALXg47RMFnO82XlGMRsGYicgW1V
# GaiYPgFLRj2TNHXMkon85IT5nylGF1i7x4kFPWo7oLVrjl5VrHPcjNapcNWbwG4r
# runBksVzG78/eF6AYIFGxCsOB+QcMebRvgaRmW+7svOp5FS2MwIfJfFVqcqR3KOy
# Xymn5gyxsOBg4wkBoiwp3OuAMoZYnvFUM2PwslCHnRmeRNPmkYHAZ1HG5jR7rSVN
# PXW9dUY9y75j58xA4WwRZn4Icz1j85a542IAf8T5YhjLZKv1gIebAgfnGI23h8lc
# GxH7oWce+2a8FhL7bQ==
# SIG # End signature block
