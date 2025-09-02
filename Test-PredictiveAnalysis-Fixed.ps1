# Fixed test for PredictiveAnalysis module
param(
    [string]$TestPath = "C:\UnityProjects\Sound-and-Shoal\Unity-Claude-Automation"
)

# Setup module path
$env:PSModulePath = "C:\UnityProjects\Sound-and-Shoal\Unity-Claude-Automation\Modules;$env:PSModulePath"

Write-Host "PredictiveAnalysis Module Test Suite (Fixed)" -ForegroundColor Cyan
Write-Host "=============================================" -ForegroundColor Cyan

# Test 1: Import modules
Write-Host "`nTest 1: Importing modules..." -ForegroundColor Yellow
try {
    Import-Module Unity-Claude-CPG -Force -ErrorAction Stop
    Import-Module Unity-Claude-LLM -Force -ErrorAction Stop  
    Import-Module Unity-Claude-Cache -Force -ErrorAction Stop
    Import-Module Unity-Claude-PredictiveAnalysis -Force -ErrorAction Stop
    Write-Host "  SUCCESS: All modules imported" -ForegroundColor Green
}
catch {
    Write-Host "  ERROR importing modules: $_" -ForegroundColor Red
    exit 1
}

# Test 2: Initialize cache
Write-Host "`nTest 2: Initialize cache..." -ForegroundColor Yellow
try {
    $result = Initialize-PredictiveCache -MaxSizeMB 100 -TTLMinutes 60
    if ($result -eq $true) {
        Write-Host "  SUCCESS: Cache initialized" -ForegroundColor Green
    } else {
        Write-Host "  FAILED: Cache initialization returned false" -ForegroundColor Red
    }
}
catch {
    Write-Host "  ERROR: $_" -ForegroundColor Red
}

# Test 3: Create test graph with proper properties
Write-Host "`nTest 3: Create test graph..." -ForegroundColor Yellow
try {
    $graph = New-CPGraph -Name "TestGraph"
    
    # Create nodes with proper properties for analysis
    $node1 = New-CPGNode -Type Function -Name "TestFunction1" -Properties @{
        Lines = 100
        LineCount = 100
        MethodCount = 5
        PropertyCount = 3
        Complexity = 15
    }
    $node2 = New-CPGNode -Type Function -Name "TestFunction2" -Properties @{
        Lines = 200
        LineCount = 200
        MethodCount = 10
        PropertyCount = 8
        Complexity = 25
    }
    $node3 = New-CPGNode -Type Class -Name "TestClass1" -Properties @{
        Lines = 500
        LineCount = 500
        MethodCount = 25
        PropertyCount = 20
        Complexity = 50
    }
    
    Add-CPGNode -Graph $graph -Node $node1
    Add-CPGNode -Graph $graph -Node $node2
    Add-CPGNode -Graph $graph -Node $node3
    
    # Add edges properly - Note: CPG edges don't use From/To in constructor
    # They're added with source/target after creation
    $edge1 = New-CPGEdge -Type Calls -Properties @{Source = $node1.Name; Target = $node2.Name}
    Add-CPGEdge -Graph $graph -Edge $edge1
    
    Write-Host "  SUCCESS: Graph created with $($graph.Nodes.Count) nodes" -ForegroundColor Green
}
catch {
    Write-Host "  ERROR: $_" -ForegroundColor Red
}

# Test 4: Get Maintenance Prediction (requires Path)
Write-Host "`nTest 4: Get Maintenance Prediction..." -ForegroundColor Yellow
try {
    $prediction = Get-MaintenancePrediction -Path $TestPath -Graph $graph
    if ($prediction) {
        Write-Host "  SUCCESS: Risk Level = $($prediction.RiskLevel), Score = $($prediction.Score)" -ForegroundColor Green
    } else {
        Write-Host "  FAILED: No prediction returned" -ForegroundColor Red
    }
}
catch {
    Write-Host "  ERROR: $_" -ForegroundColor Red
}

# Test 5: Calculate Technical Debt (requires Path)
Write-Host "`nTest 5: Calculate Technical Debt..." -ForegroundColor Yellow
try {
    $debt = Calculate-TechnicalDebt -Path $TestPath -Graph $graph
    if ($debt) {
        Write-Host "  SUCCESS: Total Hours = $($debt.TotalHours), Priority = $($debt.Priority)" -ForegroundColor Green
    } else {
        Write-Host "  FAILED: No debt data returned" -ForegroundColor Red
    }
}
catch {
    Write-Host "  ERROR: $_" -ForegroundColor Red
}

# Test 6: Find Refactoring Opportunities (takes Graph directly)
Write-Host "`nTest 6: Find Refactoring Opportunities..." -ForegroundColor Yellow
try {
    $opportunities = Find-RefactoringOpportunities -Graph $graph
    if ($opportunities) {
        Write-Host "  SUCCESS: Found $($opportunities.Count) opportunities" -ForegroundColor Green
    } else {
        Write-Host "  FAILED: No opportunities returned" -ForegroundColor Red
    }
}
catch {
    Write-Host "  ERROR: $_" -ForegroundColor Red
}

# Test 7: Find Long Methods
Write-Host "`nTest 7: Find Long Methods..." -ForegroundColor Yellow
try {
    $longMethods = Find-LongMethods -Graph $graph -Threshold 50
    if ($longMethods) {
        Write-Host "  SUCCESS: Found $($longMethods.Count) long methods" -ForegroundColor Green
    } else {
        Write-Host "  INFO: No long methods found (good!)" -ForegroundColor Cyan
    }
}
catch {
    Write-Host "  ERROR: $_" -ForegroundColor Red
}

# Test 8: Find God Classes
Write-Host "`nTest 8: Find God Classes..." -ForegroundColor Yellow
try {
    $godClasses = Find-GodClasses -Graph $graph -MethodThreshold 20
    if ($godClasses) {
        Write-Host "  SUCCESS: Found $($godClasses.Count) god classes" -ForegroundColor Green
    } else {
        Write-Host "  INFO: No god classes found (good!)" -ForegroundColor Cyan
    }
}
catch {
    Write-Host "  ERROR: $_" -ForegroundColor Red
}

# Test 9: Predict Code Smells
Write-Host "`nTest 9: Predict Code Smells..." -ForegroundColor Yellow
try {
    $smells = Predict-CodeSmells -Graph $graph
    if ($smells) {
        Write-Host "  SUCCESS: Score = $($smells.Score), Severity = $($smells.Severity)" -ForegroundColor Green
    } else {
        Write-Host "  FAILED: No smell prediction returned" -ForegroundColor Red
    }
}
catch {
    Write-Host "  ERROR: $_" -ForegroundColor Red
}

# Test 10: New Improvement Roadmap (requires Path)
Write-Host "`nTest 10: New Improvement Roadmap..." -ForegroundColor Yellow
try {
    $roadmap = New-ImprovementRoadmap -Path $TestPath -Graph $graph -MaxPhases 3
    if ($roadmap) {
        Write-Host "  SUCCESS: Created roadmap with $($roadmap.Phases.Count) phases" -ForegroundColor Green
    } else {
        Write-Host "  FAILED: No roadmap returned" -ForegroundColor Red
    }
}
catch {
    Write-Host "  ERROR: $_" -ForegroundColor Red
}

# Test 11: Predict Bug Probability (requires Path)
Write-Host "`nTest 11: Predict Bug Probability..." -ForegroundColor Yellow
try {
    $bugProb = Predict-BugProbability -Path $TestPath -Graph $graph
    if ($bugProb) {
        Write-Host "  SUCCESS: Bug probability = $bugProb" -ForegroundColor Green
    } else {
        Write-Host "  FAILED: No probability returned" -ForegroundColor Red
    }
}
catch {
    Write-Host "  ERROR: $_" -ForegroundColor Red
}

# Test 12: Get Complexity Trend (takes Graph)
Write-Host "`nTest 12: Get Complexity Trend..." -ForegroundColor Yellow
try {
    $trend = Get-ComplexityTrend -Graph $graph -DaysBack 7
    if ($trend) {
        Write-Host "  SUCCESS: Trend direction = $($trend.Direction)" -ForegroundColor Green
    } else {
        Write-Host "  INFO: No trend data (expected without git history)" -ForegroundColor Cyan
    }
}
catch {
    Write-Host "  ERROR: $_" -ForegroundColor Red
}

Write-Host "`n=============================================" -ForegroundColor Cyan
Write-Host "Test Suite Complete" -ForegroundColor Cyan
# SIG # Begin signature block
# MIIFzgYJKoZIhvcNAQcCoIIFvzCCBbsCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCA/JEEhnKssnwXm
# c2dli15+3HYnCd0Hq3pA358dkuDyhKCCAzAwggMsMIICFKADAgECAhB1HRbZIqgr
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
# MAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIBZzfP6sBvNK2C9vI8xpQ/zg
# Kw0Czg/53qC1U6MwY/9bMA0GCSqGSIb3DQEBAQUABIIBAFWUZ7qGnn9OpbyGrkWO
# 6QnQtaAhVtRQvHIXHPYpGNG+ulzP6L5ISj+vEqCtqtJFCcrgC/IAQ2ydGjduwglH
# aFhd+YdRFsQQ2IPYwqjN+UU7/PDhADnT3nOJDxS49uQDf95hEYC987C0ex+49tQB
# GFeO7BVseD7LDYIBx2+r070zv0KK+OzgHACtReWrgC2ttTFDdZdEUxQXMJT1/WxQ
# +EucKIbmYQmmS8IaS6YxMMVpNqApg+DYqIuczN4apmvzP/5y3mUrVVCCYYnjpwRh
# Off+drSBLTeQU/OsbXU6jESdqoDYmFv6cXp3sk6axJa6VDK8+WjuxGzT6msATBK0
# T0s=
# SIG # End signature block
