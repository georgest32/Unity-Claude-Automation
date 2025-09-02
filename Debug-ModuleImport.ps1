# Debug module import issues
$ErrorActionPreference = 'Continue'

Write-Host "Testing module imports step by step..." -ForegroundColor Cyan

# Test 1: CPG
Write-Host "`n1. Importing CPG module..." -ForegroundColor Yellow
try {
    Import-Module "$PSScriptRoot\Modules\Unity-Claude-CPG\Unity-Claude-CPG.psd1" -Force -ErrorAction Stop
    Write-Host "   SUCCESS: CPG module imported" -ForegroundColor Green
} catch {
    Write-Host "   ERROR: $_" -ForegroundColor Red
    Write-Host "   Stack: $($_.ScriptStackTrace)" -ForegroundColor Yellow
}

# Test 2: SemanticAnalysis
Write-Host "`n2. Importing SemanticAnalysis module..." -ForegroundColor Yellow
try {
    Import-Module "$PSScriptRoot\Modules\Unity-Claude-CPG\Unity-Claude-SemanticAnalysis.psd1" -Force -ErrorAction Stop
    Write-Host "   SUCCESS: SemanticAnalysis module imported" -ForegroundColor Green
} catch {
    Write-Host "   ERROR: $_" -ForegroundColor Red
    Write-Host "   Stack: $($_.ScriptStackTrace)" -ForegroundColor Yellow
}

# Test 3: LLM
Write-Host "`n3. Importing LLM module..." -ForegroundColor Yellow
try {
    Import-Module "$PSScriptRoot\Modules\Unity-Claude-LLM\Unity-Claude-LLM.psd1" -Force -ErrorAction Stop
    Write-Host "   SUCCESS: LLM module imported" -ForegroundColor Green
} catch {
    Write-Host "   ERROR: $_" -ForegroundColor Red
    Write-Host "   Stack: $($_.ScriptStackTrace)" -ForegroundColor Yellow
}

# Test 4: Cache
Write-Host "`n4. Importing Cache module..." -ForegroundColor Yellow
try {
    Import-Module "$PSScriptRoot\Modules\Unity-Claude-Cache\Unity-Claude-Cache.psd1" -Force -ErrorAction Stop
    Write-Host "   SUCCESS: Cache module imported" -ForegroundColor Green
} catch {
    Write-Host "   ERROR: $_" -ForegroundColor Red
    Write-Host "   Stack: $($_.ScriptStackTrace)" -ForegroundColor Yellow
}

# Test 5: PredictiveAnalysis
Write-Host "`n5. Importing PredictiveAnalysis module..." -ForegroundColor Yellow
try {
    Import-Module "$PSScriptRoot\Modules\Unity-Claude-PredictiveAnalysis\Unity-Claude-PredictiveAnalysis.psd1" -Force -ErrorAction Stop
    $commands = Get-Command -Module Unity-Claude-PredictiveAnalysis
    Write-Host "   SUCCESS: PredictiveAnalysis module imported with $($commands.Count) functions" -ForegroundColor Green
    
    # Test if a specific function exists
    $testFunc = Get-Command Initialize-PredictiveCache -ErrorAction SilentlyContinue
    if ($testFunc) {
        Write-Host "   SUCCESS: Initialize-PredictiveCache function available" -ForegroundColor Green
    } else {
        Write-Host "   ERROR: Initialize-PredictiveCache function not found" -ForegroundColor Red
    }
} catch {
    Write-Host "   ERROR: $_" -ForegroundColor Red
    Write-Host "   Stack: $($_.ScriptStackTrace)" -ForegroundColor Yellow
    
    # Check if module file exists
    $moduleFile = "$PSScriptRoot\Modules\Unity-Claude-PredictiveAnalysis\Unity-Claude-PredictiveAnalysis.psd1"
    if (Test-Path $moduleFile) {
        Write-Host "   INFO: Module file exists at $moduleFile" -ForegroundColor Cyan
    } else {
        Write-Host "   ERROR: Module file not found at $moduleFile" -ForegroundColor Red
    }
}
# SIG # Begin signature block
# MIIFzgYJKoZIhvcNAQcCoIIFvzCCBbsCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCBBVzV1YAg7Aq0h
# 1FpojTiK97TgNS2dSBWOH+DF79HYV6CCAzAwggMsMIICFKADAgECAhB1HRbZIqgr
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
# MAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIGr+ftxS9xnUkoNKrsm65vhN
# bpsOs/kphUkL/Qhb1PGpMA0GCSqGSIb3DQEBAQUABIIBAACOGc5HUp0/bbXtGpKa
# gkkezW3mS8APkYgGZl1TBu5i3uxDAo8LfVxZoXHsRzZoZcv9vWqXjFm8oc8YAmBb
# C4sAmeyRV6tOcd1JdvV0eIpSFBEGOD8QTCwp6olo3OFIY3YWWDkam1PCkOGEy8Xl
# nH5zxoGMdLD4qJzlKaZSwfDtevmcXQmWY8p2xnIweyoStjOBIUN4YaZikuSPSv1p
# Cp6nQ8443O0wTGK1gWbUFvTs3mwaQkoXikNOb7t+L7WKAAHypB0vrm+biKqYRHLm
# Eb3x6aJjjP/1aB7siFy7KEwNV6Ab5/jrV5FuYMfrU3pJBz9NwoDYHZoPlEx9vEGp
# JC0=
# SIG # End signature block
