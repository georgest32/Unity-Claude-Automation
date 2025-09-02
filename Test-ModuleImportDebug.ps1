# Debug script to test module import issues
param()

Write-Host "Testing PredictiveAnalysis Module Import" -ForegroundColor Cyan
Write-Host "=========================================" -ForegroundColor Cyan

# Set module path
$env:PSModulePath = "C:\UnityProjects\Sound-and-Shoal\Unity-Claude-Automation\Modules;$env:PSModulePath"
Write-Host "Module Path set: $($env:PSModulePath.Split(';')[0])" -ForegroundColor Green

# Test 1: Import CPG module
Write-Host "`nTest 1: Importing CPG module..." -ForegroundColor Yellow
try {
    Import-Module Unity-Claude-CPG -Force -Verbose -ErrorAction Stop
    Write-Host "  SUCCESS: CPG module imported" -ForegroundColor Green
    $cpgFunctions = Get-Command -Module Unity-Claude-CPG
    Write-Host "  CPG Functions available: $($cpgFunctions.Count)" -ForegroundColor Green
} catch {
    Write-Host "  FAILED: CPG module import failed" -ForegroundColor Red
    Write-Host "  Error: $_" -ForegroundColor Red
}

# Test 2: Import LLM module
Write-Host "`nTest 2: Importing LLM module..." -ForegroundColor Yellow
try {
    Import-Module Unity-Claude-LLM -Force -Verbose -ErrorAction Stop
    Write-Host "  SUCCESS: LLM module imported" -ForegroundColor Green
    $llmFunctions = Get-Command -Module Unity-Claude-LLM
    Write-Host "  LLM Functions available: $($llmFunctions.Count)" -ForegroundColor Green
} catch {
    Write-Host "  FAILED: LLM module import failed" -ForegroundColor Red
    Write-Host "  Error: $_" -ForegroundColor Red
}

# Test 3: Import Cache module
Write-Host "`nTest 3: Importing Cache module..." -ForegroundColor Yellow
try {
    Import-Module Unity-Claude-Cache -Force -Verbose -ErrorAction Stop
    Write-Host "  SUCCESS: Cache module imported" -ForegroundColor Green
    $cacheFunctions = Get-Command -Module Unity-Claude-Cache
    Write-Host "  Cache Functions available: $($cacheFunctions.Count)" -ForegroundColor Green
} catch {
    Write-Host "  FAILED: Cache module import failed" -ForegroundColor Red
    Write-Host "  Error: $_" -ForegroundColor Red
}

# Test 4: Import PredictiveAnalysis module
Write-Host "`nTest 4: Importing PredictiveAnalysis module..." -ForegroundColor Yellow
try {
    Import-Module Unity-Claude-PredictiveAnalysis -Force -Verbose -ErrorAction Stop
    Write-Host "  SUCCESS: PredictiveAnalysis module imported" -ForegroundColor Green
    $paFunctions = Get-Command -Module Unity-Claude-PredictiveAnalysis
    Write-Host "  PredictiveAnalysis Functions available: $($paFunctions.Count)" -ForegroundColor Green
    
    # List first few functions
    Write-Host "  Sample functions:" -ForegroundColor Cyan
    $paFunctions | Select-Object -First 5 | ForEach-Object {
        Write-Host "    - $($_.Name)" -ForegroundColor Gray
    }
} catch {
    Write-Host "  FAILED: PredictiveAnalysis module import failed" -ForegroundColor Red
    Write-Host "  Error: $_" -ForegroundColor Red
    Write-Host "  Stack Trace:" -ForegroundColor Red
    Write-Host $_.ScriptStackTrace -ForegroundColor Red
}

# Test 5: Check if specific functions exist
Write-Host "`nTest 5: Checking for specific functions..." -ForegroundColor Yellow
$testFunctions = @(
    'Get-CodeEvolutionTrend',
    'Get-MaintenancePrediction',
    'Find-RefactoringOpportunities',
    'New-ImprovementRoadmap'
)

foreach ($func in $testFunctions) {
    if (Get-Command $func -ErrorAction SilentlyContinue) {
        Write-Host "  [OK] $func exists" -ForegroundColor Green
    } else {
        Write-Host "  [MISSING] $func not found" -ForegroundColor Red
    }
}

Write-Host "`n=========================================" -ForegroundColor Cyan
Write-Host "Module Import Debug Complete" -ForegroundColor Cyan
# SIG # Begin signature block
# MIIFzgYJKoZIhvcNAQcCoIIFvzCCBbsCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCBp/nUM2Tt1da7T
# eVOlojnbRv+CaCztesSrKa66AhNXvqCCAzAwggMsMIICFKADAgECAhB1HRbZIqgr
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
# MAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIBmAHeaEMMzY+xwdyhaWfn0D
# bZ8D+9bn5iqCfj1JbZkdMA0GCSqGSIb3DQEBAQUABIIBAAjWH6caljtGaWrYx1b3
# 5Imxh+AwNcJSq+emR+Ww+pPVQJQrG7zVC8yi3mLTzT07v4AZNO9lmWUBLH0z1n+V
# sGORCl0Ri1ED2jDRegrSsb8OiSnk176FWF2oY1JgZpUhUmsITGk53rINgK2Hb/jl
# LiBuQXh3RITJQig7IiM4qpz15srdZpFlhyxjP19TavDfz3/SCBe2HSmau5WTNOGF
# V29iheDuJjceoiZwpplOkOfG5MD2cfsyqPWi4GpvEB7nNWIkhLcSal6pZ0DG+t6K
# odgr8Tq/wpe2yYSCxVzPH69GOAQQnrd0jr/segDBw6kqtbbiEYu+JWpS/iMyTnZz
# hM4=
# SIG # End signature block
