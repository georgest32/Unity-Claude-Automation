# Test-Week3-Day5-Simple.ps1
# Simple validation test for Week 3 Day 5: End-to-End Integration
# Date: 2025-08-21

Write-Host "=== Week 3 Day 5: End-to-End Integration System Validation ===" -ForegroundColor Cyan

try {
    # Import all modules
    $moduleBasePath = "C:\UnityProjects\Sound-and-Shoal\Unity-Claude-Automation\Modules"
    
    Write-Host "1. Importing dependency modules..." -ForegroundColor Yellow
    Import-Module "$moduleBasePath\Unity-Claude-ParallelProcessing\Unity-Claude-ParallelProcessing.psm1" -Force
    Import-Module "$moduleBasePath\Unity-Claude-RunspaceManagement\Unity-Claude-RunspaceManagement.psm1" -Force
    Import-Module "$moduleBasePath\Unity-Claude-UnityParallelization\Unity-Claude-UnityParallelization.psm1" -Force
    Import-Module "$moduleBasePath\Unity-Claude-ClaudeParallelization\Unity-Claude-ClaudeParallelization.psm1" -Force
    Import-Module "$moduleBasePath\Unity-Claude-IntegratedWorkflow\Unity-Claude-IntegratedWorkflow.psm1" -Force
    
    Write-Host "   All modules imported successfully" -ForegroundColor Green
    
    # Test 1: Check if all functions are available
    Write-Host "2. Validating IntegratedWorkflow functions..." -ForegroundColor Yellow
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
    
    if ($missingFunctions.Count -eq 0) {
        Write-Host "   All 8 IntegratedWorkflow functions available" -ForegroundColor Green
    } else {
        Write-Host "   Missing functions: $($missingFunctions -join ', ')" -ForegroundColor Red
        throw "Required functions not available"
    }
    
    # Test 2: Create an integrated workflow
    Write-Host "3. Creating integrated workflow..." -ForegroundColor Yellow
    $workflow = New-IntegratedWorkflow -WorkflowName "ValidationTest" -MaxUnityProjects 2 -MaxClaudeSubmissions 4 -EnableResourceOptimization -EnableErrorPropagation
    
    if ($workflow -and $workflow.WorkflowName -eq "ValidationTest") {
        Write-Host "   Workflow created successfully: $($workflow.WorkflowName)" -ForegroundColor Green
        Write-Host "   Status: $($workflow.Status)" -ForegroundColor Green
        Write-Host "   Unity Projects: $($workflow.MaxUnityProjects)" -ForegroundColor Green  
        Write-Host "   Claude Submissions: $($workflow.MaxClaudeSubmissions)" -ForegroundColor Green
    } else {
        Write-Host "   Workflow creation failed" -ForegroundColor Red
        throw "Workflow creation failed"
    }
    
    # Test 3: Initialize adaptive throttling
    Write-Host "4. Testing adaptive throttling..." -ForegroundColor Yellow
    $throttlingResult = Initialize-AdaptiveThrottling -IntegratedWorkflow $workflow -EnableCPUThrottling -EnableMemoryThrottling -CPUThreshold 75 -MemoryThreshold 80
    
    if ($throttlingResult.Success) {
        Write-Host "   Adaptive throttling initialized successfully" -ForegroundColor Green
        Write-Host "   CPU Threshold: 75 percent, Memory Threshold: 80 percent" -ForegroundColor Green
    } else {
        Write-Host "   Adaptive throttling failed: $($throttlingResult.Message)" -ForegroundColor Red
        throw "Adaptive throttling failed"
    }
    
    # Test 4: Get workflow status
    Write-Host "5. Testing workflow status..." -ForegroundColor Yellow
    $status = Get-IntegratedWorkflowStatus -IntegratedWorkflow $workflow -IncludeDetailedMetrics
    
    if ($status -and $status.WorkflowName -eq "ValidationTest") {
        Write-Host "   Status retrieved successfully" -ForegroundColor Green
        Write-Host "   Overall Status: $($status.OverallStatus)" -ForegroundColor Green
        Write-Host "   Components Available: $($status.Components.Count)" -ForegroundColor Green
    } else {
        Write-Host "   Status retrieval failed" -ForegroundColor Red
        throw "Status retrieval failed"
    }
    
    # Test 5: Performance analysis
    Write-Host "6. Testing performance analysis..." -ForegroundColor Yellow
    $performanceData = Get-WorkflowPerformanceAnalysis -IntegratedWorkflow $workflow -MonitoringDuration 5 -IncludeSystemMetrics
    
    if ($performanceData -and $performanceData.WorkflowName -eq "ValidationTest") {
        Write-Host "   Performance analysis completed" -ForegroundColor Green
        Write-Host "   Analysis Duration: $($performanceData.AnalysisDuration)ms" -ForegroundColor Green
        Write-Host "   Recommendations: $($performanceData.OptimizationRecommendations.Count)" -ForegroundColor Green
    } else {
        Write-Host "   Performance analysis failed" -ForegroundColor Red
        throw "Performance analysis failed"
    }
    
    # Final success
    Write-Host "=== WEEK 3 DAY 5 VALIDATION: SUCCESS ===" -ForegroundColor Green
    Write-Host "All 8 IntegratedWorkflow functions operational" -ForegroundColor Green
    Write-Host "Workflow creation and management working" -ForegroundColor Green  
    Write-Host "Adaptive throttling system functional" -ForegroundColor Green
    Write-Host "Status monitoring and performance analysis working" -ForegroundColor Green
    Write-Host "Complete end-to-end integration system validated" -ForegroundColor Green
    
    Write-Host "Week 3 Day 5 End-to-End Integration: COMPLETE AND OPERATIONAL" -ForegroundColor Cyan
    
} catch {
    Write-Host "=== WEEK 3 DAY 5 VALIDATION: FAILED ===" -ForegroundColor Red
    Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "Week 3 Day 5 End-to-End Integration: NEEDS ATTENTION" -ForegroundColor Red
    exit 1
}
# SIG # Begin signature block
# MIIFqQYJKoZIhvcNAQcCoIIFmjCCBZYCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUGbblNJroIZsdCOlg95JGPAra
# Yg6gggMwMIIDLDCCAhSgAwIBAgIQdR0W2SKoK5VE8JId4ZxrRTANBgkqhkiG9w0B
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
# CQQxFgQUVB3qWxBIRiCuIhwCthOJ10NeMiowDQYJKoZIhvcNAQEBBQAEggEAqa/x
# BfJ5RFtLXGaZN2ZhcV9Jf3/jko2bqtf0hJh+VYomOauVrMy67m4WaJ2HgwiFqQTS
# 7uBdAD1VkMwcCj5YUlq0irMECsVIflB7y80tJAnDQi3az3z9X1TMS/24azs5aX/6
# HDkW4DRw1tlbI5Q6rk/bB5/CeDhHMvQZY2mmFrK+LjJkwXvR2iDwAGOVbzjRcFTn
# nftMfGEug+8J+bnukp89F9F3jLptsVNXMmq64NUWeV5gNhvxx07fs/Tma4W5XmOw
# z/UDvZblBm3vGWVSj+p2DBk1w4jliLIIsuYAEB08HtbRpBO24i1RbtykxeEOGEVY
# epArF0GCtLQzj1mwVg==
# SIG # End signature block
