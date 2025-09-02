# Debug version of PredictiveAnalysis test
param(
    [string]$TestPath = "C:\UnityProjects\Sound-and-Shoal\Unity-Claude-Automation"
)

# Setup module path
$env:PSModulePath = "C:\UnityProjects\Sound-and-Shoal\Unity-Claude-Automation\Modules;$env:PSModulePath"

Write-Host "Debug Test: PredictiveAnalysis Module" -ForegroundColor Cyan
Write-Host "======================================" -ForegroundColor Cyan

# Test 1: Import modules
Write-Host "`nTest 1: Importing modules..." -ForegroundColor Yellow
try {
    Import-Module Unity-Claude-CPG -Force -ErrorAction Stop
    Write-Host "  CPG module imported" -ForegroundColor Green
    
    Import-Module Unity-Claude-LLM -Force -ErrorAction Stop  
    Write-Host "  LLM module imported" -ForegroundColor Green
    
    Import-Module Unity-Claude-Cache -Force -ErrorAction Stop
    Write-Host "  Cache module imported" -ForegroundColor Green
    
    Import-Module Unity-Claude-PredictiveAnalysis -Force -ErrorAction Stop
    Write-Host "  PredictiveAnalysis module imported" -ForegroundColor Green
}
catch {
    Write-Host "  ERROR importing modules: $_" -ForegroundColor Red
    exit 1
}

# Test 2: Initialize cache with detailed error
Write-Host "`nTest 2: Initialize cache..." -ForegroundColor Yellow
try {
    $result = Initialize-PredictiveCache -MaxSizeMB 100 -TTLMinutes 60 -Verbose
    Write-Host "  Initialize-PredictiveCache returned: $result" -ForegroundColor Cyan
    
    if ($result -eq $true) {
        Write-Host "  Cache initialized successfully" -ForegroundColor Green
    } else {
        Write-Host "  Cache initialization returned false" -ForegroundColor Red
    }
}
catch {
    Write-Host "  ERROR in Initialize-PredictiveCache: $_" -ForegroundColor Red
    Write-Host "  Exception Type: $($_.Exception.GetType().Name)" -ForegroundColor Red
    Write-Host "  Stack Trace:" -ForegroundColor Red
    Write-Host $_.ScriptStackTrace -ForegroundColor Red
}

# Test 3: Create test graph
Write-Host "`nTest 3: Create test graph..." -ForegroundColor Yellow
try {
    $graph = New-CPGraph -Name "TestGraph"
    
    # Add some nodes (New-CPGNode doesn't have Id parameter)
    $node1 = New-CPGNode -Type Function -Name "TestFunction1" -Properties @{Lines = 100; Id = "func1"}
    $node2 = New-CPGNode -Type Function -Name "TestFunction2" -Properties @{Lines = 200; Id = "func2"}
    
    Add-CPGNode -Graph $graph -Node $node1
    Add-CPGNode -Graph $graph -Node $node2
    
    # Add edge
    $edge = New-CPGEdge -From "func1" -To "func2" -Type Calls
    Add-CPGEdge -Graph $graph -Edge $edge
    
    Write-Host "  Graph created with $($graph.Nodes.Count) nodes" -ForegroundColor Green
}
catch {
    Write-Host "  ERROR creating graph: $_" -ForegroundColor Red
}

# Test 4: Get Maintenance Prediction
Write-Host "`nTest 4: Get Maintenance Prediction..." -ForegroundColor Yellow
try {
    $prediction = Get-MaintenancePrediction -Graph $graph -Verbose
    Write-Host "  Prediction result type: $($prediction.GetType().Name)" -ForegroundColor Cyan
    
    if ($prediction) {
        Write-Host "  Risk Level: $($prediction.RiskLevel)" -ForegroundColor Cyan
        Write-Host "  Score: $($prediction.Score)" -ForegroundColor Cyan
        Write-Host "  Maintenance prediction successful" -ForegroundColor Green
    } else {
        Write-Host "  No prediction returned" -ForegroundColor Red
    }
}
catch {
    Write-Host "  ERROR in Get-MaintenancePrediction: $_" -ForegroundColor Red
    Write-Host "  Exception Type: $($_.Exception.GetType().Name)" -ForegroundColor Red
    Write-Host "  Stack Trace:" -ForegroundColor Red
    Write-Host $_.ScriptStackTrace -ForegroundColor Red
}

# Test 5: Calculate Technical Debt
Write-Host "`nTest 5: Calculate Technical Debt..." -ForegroundColor Yellow
try {
    $debt = Calculate-TechnicalDebt -Graph $graph -Verbose
    Write-Host "  Debt result type: $($debt.GetType().Name)" -ForegroundColor Cyan
    
    if ($debt) {
        Write-Host "  Total Hours: $($debt.TotalHours)" -ForegroundColor Cyan
        Write-Host "  Priority: $($debt.Priority)" -ForegroundColor Cyan
        Write-Host "  Technical debt calculated" -ForegroundColor Green
    } else {
        Write-Host "  No debt data returned" -ForegroundColor Red
    }
}
catch {
    Write-Host "  ERROR in Calculate-TechnicalDebt: $_" -ForegroundColor Red
    Write-Host "  Exception Type: $($_.Exception.GetType().Name)" -ForegroundColor Red
}

# Test 6: Find Refactoring Opportunities
Write-Host "`nTest 6: Find Refactoring Opportunities..." -ForegroundColor Yellow
try {
    $opportunities = Find-RefactoringOpportunities -Graph $graph -Verbose
    Write-Host "  Result type: $($opportunities.GetType().Name)" -ForegroundColor Cyan
    
    if ($opportunities) {
        Write-Host "  Found $($opportunities.Count) opportunities" -ForegroundColor Green
    } else {
        Write-Host "  No opportunities returned" -ForegroundColor Red
    }
}
catch {
    Write-Host "  ERROR in Find-RefactoringOpportunities: $_" -ForegroundColor Red
    Write-Host "  Exception Type: $($_.Exception.GetType().Name)" -ForegroundColor Red
}

Write-Host "`n======================================" -ForegroundColor Cyan
Write-Host "Debug Test Complete" -ForegroundColor Cyan
# SIG # Begin signature block
# MIIFzgYJKoZIhvcNAQcCoIIFvzCCBbsCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCDt5dDiWJ1xGlUw
# TypDHylGTsAATKlgYZaNITlbFHxy7KCCAzAwggMsMIICFKADAgECAhB1HRbZIqgr
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
# MAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIKMAJF/Lb6hX9jpYmGxrRyVZ
# ST7Ck9IxPl+H3rpPwdI1MA0GCSqGSIb3DQEBAQUABIIBAEHW6UBrhPyeCDuTz9DN
# glkXeiuRREY4VeDKbL0qA5TZfYdbvGCkn6dZq7RCVzKa5K2DsahM5EyZRvuDcat6
# hL6pA2Z/7RBNx88kd50Dy9YtQCxQYGKTnLTAQNwtkLiZRLbPVdEEWdnKkbQ/vQLv
# +uG+rWlwVeXnkJHBKB9fI+4hoYn1WEfrEyj1+EOGOMtXhleBV+z7tlqCBnCCY4IC
# v2v8HeaJv1yx6QV2jPM7W8hLWl6KJLraibn7JfA09eKdai0XevpCwjgKTnIdS6Mw
# +afoXILnz3rer/qu72d1rKO3gm7BXOrz8nyckhFSxcb4gQE7owH2fIl4xyJTHzsA
# YoA=
# SIG # End signature block
