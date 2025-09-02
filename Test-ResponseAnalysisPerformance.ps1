# Test-ResponseAnalysisPerformance.ps1
# Phase 7 Day 1-2 Hours 4: Performance Optimization Validation
# Target: Validate <200ms response analysis time achievement

[CmdletBinding()]
param(
    [Parameter()]
    [int]$TestIterations = 50,
    
    [Parameter()]
    [switch]$SaveResults,
    
    [Parameter()]
    [switch]$ShowProgress
)

# Import required modules
Write-Host "Importing modules..." -ForegroundColor Cyan
try {
    Import-Module "$PSScriptRoot\Modules\Unity-Claude-CLIOrchestrator\Unity-Claude-CLIOrchestrator.psd1" -Force
    Import-Module "$PSScriptRoot\Modules\Unity-Claude-CLIOrchestrator\Core\PerformanceOptimizer.psm1" -Force
    Write-Host "Modules imported successfully" -ForegroundColor Green
} catch {
    Write-Error "Failed to import modules: $($_.Exception.Message)"
    exit 1
}

$testResults = @{
    TestSuite = "ResponseAnalysisPerformance"
    StartTime = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    EndTime = $null
    TestIterations = $TestIterations
    TargetResponseTime = 200  # milliseconds
    Results = @()
    Summary = @{
        TotalTests = 0
        PassedTests = 0
        FailedTests = 0
        AverageResponseTime = 0.0
        TargetMet = $false
    }
}

Write-Host "Starting Response Analysis Performance Tests" -ForegroundColor Yellow
Write-Host "Target: <200ms response analysis time" -ForegroundColor Yellow
Write-Host "Iterations: $TestIterations" -ForegroundColor Yellow
Write-Host ""

# Test Cases
$testCases = @(
    @{
        Name = "Small JSON Response (Basic)"
        Content = @{
            RESPONSE = "RECOMMENDATION: TEST - C:\Test\File.ps1"
            timestamp = (Get-Date -Format "o")
            issue = "Basic test case"
        } | ConvertTo-Json
        ExpectedTime = 100  # milliseconds
    },
    @{
        Name = "Medium Mixed Content Response"
        Content = @"
RECOMMENDATION: FIX - C:\UnityProjects\TestProject\Scripts\PlayerController.cs

Analysis shows multiple issues:

```json
{
  "errors": [
    "CS0103: The name 'rigidbody' does not exist",
    "CS0246: The type or namespace name 'UnityEngine' not found",
    "CS0117: 'Transform' does not contain definition"
  ],
  "files": [
    "PlayerController.cs",
    "GameManager.cs", 
    "UIController.cs"
  ],
  "suggestions": [
    "Add using UnityEngine statement",
    "Check component references",
    "Verify namespace declarations"
  ]
}
```

The following Unity components are affected:
- MonoBehaviour inheritance issues
- Transform component access problems  
- Rigidbody reference errors

Run Test-Unity-Compilation to verify fixes.
Execute Build-UnityProject after corrections.
"@
        ExpectedTime = 150
    },
    @{
        Name = "Large Complex Response with Entities"
        Content = @"
RECOMMENDATION: FIX - C:\UnityProjects\LargeProject\Scripts\ComplexSystem.cs

ERROR: Multiple compilation issues detected across 15 files

Affected Files:
- C:\UnityProjects\LargeProject\Scripts\PlayerController.cs (Lines: 23, 45, 67, 89)
- C:\UnityProjects\LargeProject\Scripts\GameManager.cs (Lines: 12, 34, 56, 78, 90)
- C:\UnityProjects\LargeProject\Scripts\UIController.cs (Lines: 15, 27, 39, 51)
- C:\UnityProjects\LargeProject\Scripts\AudioManager.cs (Lines: 8, 16, 24, 32)
- C:\UnityProjects\LargeProject\Scripts\NetworkManager.cs (Lines: 41, 53, 65)

Error Details:
CS0103: The name 'rigidbody' does not exist in the current context
CS0246: The type or namespace name 'UnityEngine' could not be found
CS0117: 'Transform' does not contain a definition for 'position'
CS0619: 'Component.rigidbody' is obsolete: 'Property rigidbody has been deprecated'
MSB4066: The assembly 'UnityEngine.dll' could not be found
CS1061: 'GameObject' does not contain a definition for 'SetActive'

Unity Components Referenced:
MonoBehaviour, ScriptableObject, GameObject, Transform, Rigidbody, Collider,
Renderer, MeshRenderer, SpriteRenderer, AudioSource, Camera, Light,
Canvas, Button, Text, Image, Slider, ScrollRect, Dropdown

Commands to Execute:
1. Test-Unity-Compilation -ProjectPath "C:\UnityProjects\LargeProject"
2. Build-UnityProject -Configuration Debug -Platform Windows64
3. Start-Unity-Editor -ProjectPath "C:\UnityProjects\LargeProject" -BatchMode
4. dotnet build "C:\UnityProjects\LargeProject\Assembly-CSharp.csproj"
5. unity.exe -projectPath "C:\UnityProjects\LargeProject" -quit -batchmode

Variables Referenced:
$projectPath, $buildConfiguration, $targetPlatform, $outputDirectory,
$assemblyReferences, $compilationSymbols, $playerSettings

Method Calls Detected:
GetComponent<T>(), FindObjectOfType<T>(), Instantiate(), Destroy(), 
SetActive(bool), CompareTag(string), SendMessage(string), BroadcastMessage(string)

Recommended Resolution Steps:
1. Update all rigidbody references to GetComponent<Rigidbody>()
2. Add proper using UnityEngine statements to all affected files
3. Replace obsolete property access patterns with modern component access
4. Verify assembly references in project settings
5. Run comprehensive compilation test after fixes

Additional Context:
This is part of a larger refactoring effort to modernize the Unity project
from version 2019.4 to Unity 2023.1. The changes affect core gameplay
systems including physics, UI, audio, and networking components.
"@
        ExpectedTime = 200
    }
)

# Run performance tests for each case
foreach ($testCase in $testCases) {
    Write-Host "Testing: $($testCase.Name)" -ForegroundColor Cyan
    
    $caseResults = @{
        Name = $testCase.Name
        ExpectedTime = $testCase.ExpectedTime
        ContentLength = $testCase.Content.Length
        ResponseTimes = @()
        AverageTime = 0.0
        MinTime = [double]::MaxValue
        MaxTime = 0.0
        TargetMet = $false
        CacheUtilization = @{
            HitRate = 0.0
            TotalHits = 0
            TotalMisses = 0
        }
    }
    
    # Clear performance metrics for clean test
    try {
        Invoke-CacheCleanup -Force | Out-Null
    } catch {
        # Cache cleanup not critical for test
    }
    
    # Run iterations
    for ($i = 1; $i -le $TestIterations; $i++) {
        $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
        
        try {
            # Test the universal response parser (our main performance target)
            $result = Invoke-UniversalResponseParser -ResponseContent $testCase.Content -ExtractEntities -AnalyzeSentiment -ValidateSchema
            
            $stopwatch.Stop()
            $responseTime = $stopwatch.ElapsedMilliseconds
            
            $caseResults.ResponseTimes += $responseTime
            
            if ($responseTime -lt $caseResults.MinTime) {
                $caseResults.MinTime = $responseTime
            }
            if ($responseTime -gt $caseResults.MaxTime) {
                $caseResults.MaxTime = $responseTime
            }
            
        } catch {
            $stopwatch.Stop()
            Write-Warning "Test iteration $i failed: $($_.Exception.Message)"
            # Count as maximum penalty time
            $caseResults.ResponseTimes += 500
        }
        
        # Show progress
        if ($ShowProgress -and ($i % 10 -eq 0)) {
            $avgSoFar = ($caseResults.ResponseTimes | Measure-Object -Average).Average
            Write-Host "  Progress: $i/$TestIterations, Avg: $([Math]::Round($avgSoFar, 1))ms" -ForegroundColor Gray
        }
    }
    
    # Calculate statistics
    $caseResults.AverageTime = [Math]::Round(($caseResults.ResponseTimes | Measure-Object -Average).Average, 2)
    $caseResults.TargetMet = ($caseResults.AverageTime -le $testResults.TargetResponseTime)
    
    # Get performance report if available
    try {
        $perfReport = Get-PerformanceReport
        $caseResults.CacheUtilization.HitRate = $perfReport.CacheHitRate
        $caseResults.CacheUtilization.TotalHits = $script:PerformanceMetrics.CacheHits ?? 0
        $caseResults.CacheUtilization.TotalMisses = $script:PerformanceMetrics.CacheMisses ?? 0
    } catch {
        # Performance report not available
    }
    
    # Display results
    $statusColor = if ($caseResults.TargetMet) { "Green" } else { "Red" }
    $status = if ($caseResults.TargetMet) { "PASS" } else { "FAIL" }
    
    Write-Host "  Result: $($caseResults.AverageTime)ms (Target: $($testResults.TargetResponseTime)ms) - $status" -ForegroundColor $statusColor
    Write-Host "  Range: $([Math]::Round($caseResults.MinTime, 1))ms - $([Math]::Round($caseResults.MaxTime, 1))ms" -ForegroundColor Gray
    if ($caseResults.CacheUtilization.HitRate -gt 0) {
        Write-Host "  Cache Hit Rate: $($caseResults.CacheUtilization.HitRate)%" -ForegroundColor Gray
    }
    Write-Host ""
    
    $testResults.Results += $caseResults
    $testResults.Summary.TotalTests++
    
    if ($caseResults.TargetMet) {
        $testResults.Summary.PassedTests++
    } else {
        $testResults.Summary.FailedTests++
    }
}

# Calculate overall summary
$allResponseTimes = @()
foreach ($result in $testResults.Results) {
    $allResponseTimes += $result.ResponseTimes
}

$testResults.Summary.AverageResponseTime = [Math]::Round(($allResponseTimes | Measure-Object -Average).Average, 2)
$testResults.Summary.TargetMet = ($testResults.Summary.AverageResponseTime -le $testResults.TargetResponseTime)

$testResults.EndTime = Get-Date -Format "yyyy-MM-dd HH:mm:ss"

# Display final results
Write-Host "=== PERFORMANCE TEST RESULTS ===" -ForegroundColor Yellow
Write-Host "Overall Average Response Time: $($testResults.Summary.AverageResponseTime)ms" -ForegroundColor $(if($testResults.Summary.TargetMet) {"Green"} else {"Red"})
Write-Host "Target Response Time: $($testResults.TargetResponseTime)ms" -ForegroundColor Yellow
Write-Host "Target Met: $($testResults.Summary.TargetMet)" -ForegroundColor $(if($testResults.Summary.TargetMet) {"Green"} else {"Red"})
Write-Host "Tests Passed: $($testResults.Summary.PassedTests)/$($testResults.Summary.TotalTests)" -ForegroundColor $(if($testResults.Summary.PassedTests -eq $testResults.Summary.TotalTests) {"Green"} else {"Red"})
Write-Host ""

# Detailed breakdown
Write-Host "=== DETAILED RESULTS ===" -ForegroundColor Yellow
foreach ($result in $testResults.Results) {
    $status = if ($result.TargetMet) { "PASS" } else { "FAIL" }
    $statusColor = if ($result.TargetMet) { "Green" } else { "Red" }
    
    Write-Host "$($result.Name):" -ForegroundColor Cyan
    Write-Host "  Average: $($result.AverageTime)ms - $status" -ForegroundColor $statusColor
    Write-Host "  Range: $([Math]::Round($result.MinTime, 1))ms - $([Math]::Round($result.MaxTime, 1))ms"
    Write-Host "  Content: $($result.ContentLength) characters"
    if ($result.CacheUtilization.HitRate -gt 0) {
        Write-Host "  Cache: $($result.CacheUtilization.HitRate)% hit rate"
    }
    Write-Host ""
}

# Performance recommendations
Write-Host "=== RECOMMENDATIONS ===" -ForegroundColor Yellow
try {
    $perfReport = Get-PerformanceReport
    if ($perfReport.Recommendations.Count -gt 0) {
        foreach ($recommendation in $perfReport.Recommendations) {
            Write-Host "- $recommendation" -ForegroundColor Yellow
        }
    } else {
        Write-Host "- Performance is optimal" -ForegroundColor Green
    }
} catch {
    Write-Host "- Performance report not available" -ForegroundColor Gray
}

# Save results if requested
if ($SaveResults) {
    $timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
    $resultFile = "$PSScriptRoot\ResponseAnalysisPerformance-TestResults-$timestamp.json"
    
    try {
        $testResults | ConvertTo-Json -Depth 10 | Out-File -FilePath $resultFile -Encoding UTF8
        Write-Host "Results saved to: $resultFile" -ForegroundColor Green
    } catch {
        Write-Warning "Failed to save results: $($_.Exception.Message)"
    }
}

# Return results for further processing
return $testResults
# SIG # Begin signature block
# MIIFzgYJKoZIhvcNAQcCoIIFvzCCBbsCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCDIsVbyxt2alkPn
# 0Hs1J/XllLQwmYUoyoITAV2oIWFsK6CCAzAwggMsMIICFKADAgECAhB1HRbZIqgr
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
# MAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEII8XzQR2ry/Qm8sgBoWf8ULo
# G+bZ2QFa7990oVDLzQ3RMA0GCSqGSIb3DQEBAQUABIIBAEmoWgcGAVniGTb/KDLX
# 66XZxkdIgM6pSMFtstC+QQtCQhqaR/2xVhBxTF8Q6A1qvatOrAvUL+WCoT32XhDx
# uKrmUFkVDTY20Y+1pe7EBATujYsC0a/jo8lvUIenpKuJqKRo1Z7yME5F+LeTzLpS
# G8FY0eSOtsyOMzxW4uCgIeJ7fe0uxPa5HRCcByyoyPUj52CoYfTC4tGdF2Irx+3P
# tu+LTmqxoBZXaMXljfrO8EGuzCl+RDp1C5iU+3tj/Znmj0jMdtGiF3+0qUreoNko
# yzivCA0yjr+NszZ01Q46q36QlQqX6Uj2DmOFoWTNcbF3FFq5t+JBCrkrmOlzn4lS
# e6U=
# SIG # End signature block
