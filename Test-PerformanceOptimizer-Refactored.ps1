# Test-PerformanceOptimizer-Refactored.ps1
# Test script for refactored Unity-Claude-PerformanceOptimizer module

param(
    [switch]$Verbose,
    [switch]$SaveResults
)

$ErrorActionPreference = 'Stop'
$VerbosePreference = if ($Verbose) { 'Continue' } else { 'SilentlyContinue' }

Write-Host "Testing Unity-Claude-PerformanceOptimizer Refactored Module" -ForegroundColor Cyan
Write-Host "=" * 60

$testResults = @{
    TestSuite = 'Unity-Claude-PerformanceOptimizer-Refactored'
    StartTime = [datetime]::Now
    Tests = @()
}

# Test 1: Module Import
Write-Host "`nTest 1: Module Import" -ForegroundColor Yellow
$test1 = @{
    Name = 'Module Import'
    Status = 'Failed'
    Error = $null
}

try {
    Remove-Module Unity-Claude-PerformanceOptimizer -Force -ErrorAction SilentlyContinue
    Import-Module "$PSScriptRoot\Modules\Unity-Claude-PerformanceOptimizer\Unity-Claude-PerformanceOptimizer.psd1" -Force
    $test1.Status = 'Passed'
    Write-Host "  [PASSED] Module imported successfully" -ForegroundColor Green
}
catch {
    $test1.Error = $_.Exception.Message
    Write-Host "  [FAILED] $($_.Exception.Message)" -ForegroundColor Red
}
$testResults.Tests += $test1

# Test 2: Check Component Modules
Write-Host "`nTest 2: Component Modules" -ForegroundColor Yellow
$test2 = @{
    Name = 'Component Modules'
    Status = 'Failed'
    Error = $null
    Components = @()
}

try {
    $componentPath = "$PSScriptRoot\Modules\Unity-Claude-PerformanceOptimizer\Core"
    $expectedComponents = @(
        'OptimizerConfiguration.psm1',
        'FileSystemMonitoring.psm1',
        'PerformanceMonitoring.psm1',
        'PerformanceOptimization.psm1',
        'FileProcessing.psm1',
        'ReportingExport.psm1'
    )
    
    $allFound = $true
    foreach ($component in $expectedComponents) {
        $exists = Test-Path (Join-Path $componentPath $component)
        $test2.Components += @{
            Name = $component
            Exists = $exists
        }
        if (-not $exists) {
            $allFound = $false
            Write-Host "  [MISSING] $component" -ForegroundColor Red
        } else {
            Write-Host "  [OK] $component" -ForegroundColor Green
        }
    }
    
    if ($allFound) {
        $test2.Status = 'Passed'
    }
}
catch {
    $test2.Error = $_.Exception.Message
    Write-Host "  [ERROR] $($_.Exception.Message)" -ForegroundColor Red
}
$testResults.Tests += $test2

# Test 3: Exported Functions
Write-Host "`nTest 3: Exported Functions" -ForegroundColor Yellow
$test3 = @{
    Name = 'Exported Functions'
    Status = 'Failed'
    Error = $null
    Functions = @()
}

try {
    $module = Get-Module Unity-Claude-PerformanceOptimizer
    if ($module) {
        $exportedFunctions = @(
            'New-PerformanceOptimizer',
            'Start-OptimizedProcessing',
            'Stop-OptimizedProcessing',
            'Get-PerformanceMetrics',
            'Get-ThroughputMetrics',
            'Start-BatchProcessor',
            'Export-PerformanceReport',
            'Get-PerformanceOptimizerComponents',
            'Test-PerformanceOptimizerHealth'
        )
        
        $allExported = $true
        foreach ($func in $exportedFunctions) {
            $exists = Get-Command $func -Module Unity-Claude-PerformanceOptimizer -ErrorAction SilentlyContinue
            $test3.Functions += @{
                Name = $func
                Exported = [bool]$exists
            }
            if (-not $exists) {
                $allExported = $false
                Write-Host "  [MISSING] $func" -ForegroundColor Red
            } else {
                Write-Host "  [OK] $func" -ForegroundColor Green
            }
        }
        
        if ($allExported) {
            $test3.Status = 'Passed'
        }
    }
}
catch {
    $test3.Error = $_.Exception.Message
    Write-Host "  [ERROR] $($_.Exception.Message)" -ForegroundColor Red
}
$testResults.Tests += $test3

# Test 4: Create Performance Optimizer Instance
Write-Host "`nTest 4: Create PerformanceOptimizer Instance" -ForegroundColor Yellow
$test4 = @{
    Name = 'Create PerformanceOptimizer'
    Status = 'Failed'
    Error = $null
}

try {
    $tempPath = Join-Path $env:TEMP "PerfOptimizerTest_$(Get-Date -Format 'yyyyMMdd_HHmmss')"
    New-Item -ItemType Directory -Path $tempPath -Force | Out-Null
    
    $optimizer = New-PerformanceOptimizer -BasePath $tempPath -TargetThroughput 50
    if ($optimizer) {
        $test4.Status = 'Passed'
        Write-Host "  [PASSED] PerformanceOptimizer instance created" -ForegroundColor Green
        
        # Test component health
        $health = Test-PerformanceOptimizerHealth -Optimizer $optimizer
        Write-Host "  [INFO] Optimizer health check:" -ForegroundColor Cyan
        Write-Host "    - IsRunning: $($health.IsRunning)"
        Write-Host "    - CacheManager: $($health.Components.CacheManager)"
        Write-Host "    - IncrementalProcessor: $($health.Components.IncrementalProcessor)"
        Write-Host "    - ParallelProcessor: $($health.Components.ParallelProcessor)"
    }
    
    # Clean up
    Remove-Item $tempPath -Recurse -Force -ErrorAction SilentlyContinue
}
catch {
    $test4.Error = $_.Exception.Message
    Write-Host "  [FAILED] $($_.Exception.Message)" -ForegroundColor Red
}
$testResults.Tests += $test4

# Test 5: Module Version Check
Write-Host "`nTest 5: Module Version Check" -ForegroundColor Yellow
$test5 = @{
    Name = 'Module Version'
    Status = 'Failed'
    Error = $null
}

try {
    $module = Get-Module Unity-Claude-PerformanceOptimizer
    if ($module.Version -eq '2.0.0') {
        $test5.Status = 'Passed'
        Write-Host "  [PASSED] Module version is 2.0.0 (refactored)" -ForegroundColor Green
    } else {
        Write-Host "  [WARNING] Module version is $($module.Version)" -ForegroundColor Yellow
    }
}
catch {
    $test5.Error = $_.Exception.Message
    Write-Host "  [ERROR] $($_.Exception.Message)" -ForegroundColor Red
}
$testResults.Tests += $test5

# Summary
$testResults.EndTime = [datetime]::Now
$testResults.Duration = $testResults.EndTime - $testResults.StartTime

Write-Host "`n" + "=" * 60
Write-Host "TEST SUMMARY" -ForegroundColor Cyan
$passedTests = ($testResults.Tests | Where-Object Status -eq 'Passed').Count
$totalTests = $testResults.Tests.Count
$passRate = if ($totalTests -gt 0) { [Math]::Round(($passedTests / $totalTests) * 100, 1) } else { 0 }

Write-Host "Passed: $passedTests / $totalTests ($passRate%)"
Write-Host "Duration: $([Math]::Round($testResults.Duration.TotalSeconds, 2)) seconds"

if ($passedTests -eq $totalTests) {
    Write-Host "`n[SUCCESS] All tests passed!" -ForegroundColor Green
} else {
    Write-Host "`n[WARNING] Some tests failed" -ForegroundColor Yellow
}

# Save results
if ($SaveResults) {
    $resultsFile = "PerformanceOptimizer-Refactored-TestResults-$(Get-Date -Format 'yyyyMMdd-HHmmss').json"
    $testResults | ConvertTo-Json -Depth 5 | Out-File $resultsFile -Encoding UTF8
    Write-Host "`nResults saved to: $resultsFile" -ForegroundColor Cyan
}

return $testResults
# SIG # Begin signature block
# MIIFzgYJKoZIhvcNAQcCoIIFvzCCBbsCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCDT+Ebp3ciaMxAV
# bjQ099Voxp4u+d1pG81KYTF7yds3HKCCAzAwggMsMIICFKADAgECAhB1HRbZIqgr
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
# MAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIDe14hWBGu09ISHYQlhH0vkg
# 20eGXGXk1HPglIrGAyvCMA0GCSqGSIb3DQEBAQUABIIBAAMDbHjXZboYT7iOpyO4
# UTyuyDQXO9IEETX0ZvXUrWVnyirbmYNOp4UzqGJdZjfcjpp7Z4jDW1FQ0C8wI4CX
# Pj0qmdPPMjCCSniQrQJ22qq1zFwfOR64X0gR18JmeWdNKspq50iCL2VcpSb6Es/U
# z5vJAbGQBDRcfxF1IB5kjt+9Hjw28asQPvIIrcdhMSq9XO3D4UKBjlPhzadNuk5Q
# Q5fvPshDeeQKRf1H8EXpG899AGXCSTNuFXzYGGXV9XpR5k7zsNlc8ZBseXar52tk
# u0Z1JEmQ9wGwuGs+ZOaQLQ5dLSIhO2ONGbD9PEnDTfzPXh3Fk3gq1aJPPeW2lNTU
# sbA=
# SIG # End signature block
