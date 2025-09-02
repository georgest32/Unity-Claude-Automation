# Test the exact code from the test script
Write-Host "Testing ESLint detection logic..." -ForegroundColor Cyan

# Find eslint - try multiple variants (same as test script)
$eslintCmd = Get-Command "eslint.cmd" -ErrorAction SilentlyContinue
Write-Host "eslint.cmd result: $($eslintCmd -ne $null)" -ForegroundColor Yellow

if (-not $eslintCmd) {
    Write-Host "eslint.cmd not found, trying eslint..." -ForegroundColor Yellow
    $eslintCmd = Get-Command "eslint" -ErrorAction SilentlyContinue
    Write-Host "eslint result: $($eslintCmd -ne $null)" -ForegroundColor Yellow
}

if (-not $eslintCmd) {
    Write-Host "[FAILED] eslint/eslint.cmd not found in PATH" -ForegroundColor Red
} else {
    Write-Host "[SUCCESS] Found: $($eslintCmd.Name) at $($eslintCmd.Source)" -ForegroundColor Green
    
    # Test what the script would do
    $eslintExe = if ($eslintCmd.Name -eq "eslint.cmd") { "cmd.exe" } else { $eslintCmd.Source }
    Write-Host "Would execute: $eslintExe" -ForegroundColor Gray
}

# Additional check - what if we're in a different execution context?
Write-Host "`nDirect check in current context:" -ForegroundColor Cyan
$directCheck = Get-Command eslint -ErrorAction SilentlyContinue
if ($directCheck) {
    Write-Host "Direct 'eslint' found: $($directCheck.Source)" -ForegroundColor Green
    Write-Host "Type: $($directCheck.CommandType)" -ForegroundColor Gray
}

# Check if it's a PATH issue in function context
Write-Host "`nChecking in function context:" -ForegroundColor Cyan
function Test-InFunction {
    $eslintCmd = Get-Command "eslint.cmd" -ErrorAction SilentlyContinue
    if (-not $eslintCmd) {
        $eslintCmd = Get-Command "eslint" -ErrorAction SilentlyContinue
    }
    return $eslintCmd
}

$funcResult = Test-InFunction
if ($funcResult) {
    Write-Host "In function context: Found $($funcResult.Name)" -ForegroundColor Green
} else {
    Write-Host "In function context: NOT FOUND" -ForegroundColor Red
}
# SIG # Begin signature block
# MIIFzgYJKoZIhvcNAQcCoIIFvzCCBbsCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCDJscpRhS7fDnSv
# Kj31Yr+ILxm59hJWt0qL5Tit8yxosaCCAzAwggMsMIICFKADAgECAhB1HRbZIqgr
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
# MAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEILllG7tppKhVnzFSD7uQ9X6b
# nHdEUTSuHIhDKzzqWUWSMA0GCSqGSIb3DQEBAQUABIIBAHKjXEQjIrHpw8G6lh4+
# ZNlM/X/uxApM+xGAo9A56XaPhPiDLr2QvUHjjw1ova/XvLxOtrZ2jN6TUgJEgypG
# EZva8VjnYEbygZojDjO6IVk2xsn3nwopU4UN/iJMQ1iIF6hE3Ny49Lbx1bsoybGQ
# kkHT4RiwowmOePi8BjLD5UCIzsFZ/GgR67ytSLUqpSfWKIFTJgWFA8Fjdk85bVOH
# zgnBk4CWKJ0BUXUg3JXKn+/3r4HaCIo5KbrmLlf2ci4NYvq478wgJyunQ8tIPQBB
# MfkrTLo6Fqe7n7OGY725/qec1Z+LqcKrCV0t30uG2p9+wIP/u0Sr8ywpAujKtjt2
# HtA=
# SIG # End signature block
