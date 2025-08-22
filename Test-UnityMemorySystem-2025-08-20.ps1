# Test-UnityMemorySystem-2025-08-20.ps1
# Comprehensive test of Unity memory monitoring and cleanup automation system

param(
    [switch]$Verbose
)

$timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss.fff"
$logFile = "C:\UnityProjects\Sound-and-Shoal\Unity-Claude-Automation\TEST_RESULTS_UNITY_MEMORY_SYSTEM_2025_08_20.txt"

function Write-TestLog {
    param([string]$Message)
    $timestamped = "[$timestamp] $Message"
    Write-Host $timestamped -ForegroundColor Cyan
    Add-Content -Path $logFile -Value $timestamped
}

function Write-TestResult {
    param([string]$TestName, [bool]$Passed, [string]$Details)
    $result = if ($Passed) { "✅ PASS" } else { "❌ FAIL" }
    $message = "$result - ${TestName}: $Details"
    Write-Host $message -ForegroundColor $(if ($Passed) { "Green" } else { "Red" })
    Add-Content -Path $logFile -Value "[$timestamp] $message"
}

Write-TestLog "=== Unity Memory Monitoring System Test ==="
Write-TestLog "Testing Unity MemoryMonitor.cs and PowerShell integration"

$testResults = @()

# Test 1: Verify Unity MemoryMonitor.cs file exists
Write-TestLog "`nTest 1: Unity MemoryMonitor.cs File"
$memoryMonitorPath = "C:\UnityProjects\Sound-and-Shoal\Dithering\Assets\Scripts\MemoryMonitor.cs"
$memoryMonitorExists = Test-Path $memoryMonitorPath

if ($memoryMonitorExists) {
    Write-TestResult "Unity MemoryMonitor File" $true "MemoryMonitor.cs created at $memoryMonitorPath"
    $testResults += @{ Test = "MemoryMonitorFile"; Passed = $true }
} else {
    Write-TestResult "Unity MemoryMonitor File" $false "MemoryMonitor.cs not found at expected path"
    $testResults += @{ Test = "MemoryMonitorFile"; Passed = $false }
}

# Test 2: Verify PowerShell MemoryAnalysis module
Write-TestLog "`nTest 2: PowerShell MemoryAnalysis Module"
$memoryModulePath = "C:\UnityProjects\Sound-and-Shoal\Unity-Claude-Automation\Modules\Unity-Claude-MemoryAnalysis.psm1"
$memoryModuleExists = Test-Path $memoryModulePath

if ($memoryModuleExists) {
    try {
        Import-Module $memoryModulePath -Force
        $functions = Get-Command -Module Unity-Claude-MemoryAnalysis
        
        if ($functions.Count -ge 5) {
            Write-TestResult "PowerShell MemoryAnalysis Module" $true "$($functions.Count) functions exported successfully"
            $testResults += @{ Test = "MemoryAnalysisModule"; Passed = $true }
        } else {
            Write-TestResult "PowerShell MemoryAnalysis Module" $false "Only $($functions.Count) functions exported (expected 6+)"
            $testResults += @{ Test = "MemoryAnalysisModule"; Passed = $false }
        }
    } catch {
        Write-TestResult "PowerShell MemoryAnalysis Module" $false "Error importing module: $_"
        $testResults += @{ Test = "MemoryAnalysisModule"; Passed = $false }
    }
} else {
    Write-TestResult "PowerShell MemoryAnalysis Module" $false "Module file not found"
    $testResults += @{ Test = "MemoryAnalysisModule"; Passed = $false }
}

# Test 3: Test Memory Monitoring System Check
Write-TestLog "`nTest 3: Memory Monitoring System Check"
try {
    $systemCheck = Test-MemoryMonitoringSystem
    
    if ($systemCheck -and $systemCheck.AutonomousPathExists) {
        Write-TestResult "Memory Monitoring System" $true "System check passed, autonomous path verified"
        $testResults += @{ Test = "SystemCheck"; Passed = $true }
    } else {
        Write-TestResult "Memory Monitoring System" $false "System check failed or autonomous path missing"
        $testResults += @{ Test = "SystemCheck"; Passed = $false }
    }
} catch {
    Write-TestResult "Memory Monitoring System" $false "Error during system check: $_"
    $testResults += @{ Test = "SystemCheck"; Passed = $false }
}

# Test 4: Verify AutomationLogs Directory Structure
Write-TestLog "`nTest 4: AutomationLogs Directory Structure"
$automationLogsDir = "C:\UnityProjects\Sound-and-Shoal\Unity-Claude-Automation\AutomationLogs"
$dirExists = Test-Path $automationLogsDir

if ($dirExists) {
    Write-TestResult "AutomationLogs Directory" $true "Directory exists at $automationLogsDir"
    $testResults += @{ Test = "AutomationLogsDir"; Passed = $true }
} else {
    Write-TestResult "AutomationLogs Directory" $false "AutomationLogs directory not found"
    $testResults += @{ Test = "AutomationLogsDir"; Passed = $false }
}

# Test 5: Test Memory Analysis Function
Write-TestLog "`nTest 5: Memory Analysis Function"
try {
    # Create test memory data
    $testMemoryData = [PSCustomObject]@{
        currentMemoryMB = 600
        currentObjectCount = 8500
        memoryTrend = 5.2
        timestamp = (Get-Date).ToString('yyyy-MM-dd HH:mm:ss.fff')
    }
    
    $analysisResult = Analyze-MemoryData -MemoryData $testMemoryData
    
    if ($analysisResult -and $analysisResult.RequiresAction -eq $true) {
        Write-TestResult "Memory Analysis Function" $true "Analysis detected action required for 600MB memory usage"
        $testResults += @{ Test = "MemoryAnalysis"; Passed = $true }
    } else {
        Write-TestResult "Memory Analysis Function" $false "Analysis did not properly detect threshold breach"
        $testResults += @{ Test = "MemoryAnalysis"; Passed = $false }
    }
} catch {
    Write-TestResult "Memory Analysis Function" $false "Error testing memory analysis: $_"
    $testResults += @{ Test = "MemoryAnalysis"; Passed = $false }
}

# Summary
Write-TestLog "`n=== Test Summary ==="
$passedTests = ($testResults | Where-Object { $_.Passed -eq $true }).Count
$totalTests = $testResults.Count
$successRate = [math]::Round(($passedTests / $totalTests) * 100, 1)

Write-TestLog "Tests Passed: $passedTests/$totalTests ($successRate%)"

if ($successRate -ge 90) {
    Write-Host "`n✅ SUCCESS: Unity memory monitoring system ready!" -ForegroundColor Green
    Write-TestLog "✅ UNITY MEMORY SYSTEM READY FOR INTEGRATION"
} elseif ($successRate -ge 75) {
    Write-Host "`n⚠️  PARTIAL: Most components working, minor setup needed" -ForegroundColor Yellow
    Write-TestLog "⚠️ PARTIAL SUCCESS - MINOR ISSUES TO RESOLVE"
} else {
    Write-Host "`n❌ FAILURE: Critical components missing" -ForegroundColor Red
    Write-TestLog "❌ CRITICAL SETUP ISSUES - ADDITIONAL WORK REQUIRED"
}

Write-TestLog "`nDetailed Results:"
foreach ($result in $testResults) {
    $status = if ($result.Passed) { "PASS" } else { "FAIL" }
    Write-TestLog "  $($result.Test): $status"
}

Write-TestLog "`n=== Integration Instructions ==="
Write-TestLog "1. Place MemoryMonitor.cs in Unity project: Assets/Scripts/"
Write-TestLog "2. Recompile Unity project to activate memory monitoring"
Write-TestLog "3. Start memory analysis: Import-Module Unity-Claude-MemoryAnalysis; Start-UnityMemoryMonitoring -ContinuousMode"
Write-TestLog "4. Monitor AutomationLogs directory for memory data exports"
Write-TestLog "5. Verify autonomous agent receives memory recommendations"

Write-TestLog "`nTest completed at $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"

return @{
    TestsPassed = $passedTests
    TotalTests = $totalTests
    SuccessRate = $successRate
    Results = $testResults
}
# SIG # Begin signature block
# MIIFqQYJKoZIhvcNAQcCoIIFmjCCBZYCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUCm66mxtYrTpL68oEPNKczsEV
# b92gggMwMIIDLDCCAhSgAwIBAgIQdR0W2SKoK5VE8JId4ZxrRTANBgkqhkiG9w0B
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
# CQQxFgQU5obB7VRjSo9CdPCCbm+bVpeRlvkwDQYJKoZIhvcNAQEBBQAEggEAhubu
# X/CuVraXzLy2cwb8gr/MVW5Ul20sOADYU2n5CTeLzdownlCPb/CALYLd+V8YHhgY
# +yWYsZtTS1RRE6DQEVZwUpotIy9RG7qLjN+5dOvidufYugLVxDi3R2t+pgH+m0I0
# R1pQwg8/Ad3R5QCKxEohQVOUXgHI1CuRCZ1NyWuC2IiGw4mPH8pZohM6wzfcRkMg
# DdRmR5Tamf0PS5pABUaN3V0FWTzTXyHHtdxxT3troUWwN/rJx2tSw+lGyRXfq+M4
# Yv2C7sRM/Vf6jVM6/EkNeSUFeXi9ZH/Hqaj5nJkzGl7mCOzb+oOAbXubwW7ID2CP
# NLZ0mqpHEIyOZLuuwQ==
# SIG # End signature block
