# Test environment in different contexts
Write-Host "Testing environment contexts..." -ForegroundColor Cyan

# Check current PATH
Write-Host "`nCurrent PATH contains npm-global: $($env:PATH -like '*npm-global*')" -ForegroundColor Yellow

# Test in scriptblock (similar to how test script runs)
Write-Host "`nTesting in ScriptBlock context:" -ForegroundColor Cyan
$result = & {
    $eslintCmd = Get-Command "eslint.cmd" -ErrorAction SilentlyContinue
    if (-not $eslintCmd) {
        $eslintCmd = Get-Command "eslint" -ErrorAction SilentlyContinue
    }
    return [PSCustomObject]@{
        Found = ($null -ne $eslintCmd)
        Name = if ($eslintCmd) { $eslintCmd.Name } else { "N/A" }
        Source = if ($eslintCmd) { $eslintCmd.Source } else { "N/A" }
    }
}

Write-Host "  Found: $($result.Found)" -ForegroundColor $(if ($result.Found) { "Green" } else { "Red" })
Write-Host "  Name: $($result.Name)" -ForegroundColor Gray
Write-Host "  Source: $($result.Source)" -ForegroundColor Gray

# Test what happens when we use ./
Write-Host "`nSimulating ./ invocation:" -ForegroundColor Cyan
Set-Location $PSScriptRoot
$testScript = @'
$eslintCmd = Get-Command "eslint.cmd" -ErrorAction SilentlyContinue
if (-not $eslintCmd) {
    $eslintCmd = Get-Command "eslint" -ErrorAction SilentlyContinue
}
if ($eslintCmd) {
    Write-Host "Found: $($eslintCmd.Name)" -ForegroundColor Green
} else {
    Write-Host "NOT FOUND" -ForegroundColor Red
}
'@

$testScript | Out-File -FilePath "$PSScriptRoot\temp-test.ps1" -Encoding UTF8
& ./temp-test.ps1
Remove-Item "$PSScriptRoot\temp-test.ps1" -Force

# Check if conda is interfering
Write-Host "`nChecking for Conda interference:" -ForegroundColor Cyan
if ($env:CONDA_DEFAULT_ENV) {
    Write-Host "  Conda environment active: $env:CONDA_DEFAULT_ENV" -ForegroundColor Yellow
    Write-Host "  This might affect PATH resolution" -ForegroundColor Yellow
} else {
    Write-Host "  No Conda environment active" -ForegroundColor Gray
}
# SIG # Begin signature block
# MIIFzgYJKoZIhvcNAQcCoIIFvzCCBbsCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCA1WJ1cZTv1RMBP
# YEBB360gllOe/dUrpHplnqfgX/J7CKCCAzAwggMsMIICFKADAgECAhB1HRbZIqgr
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
# MAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIFuiEzZWJEpNKpVmF2GXTrdu
# 4b6T/QnWFw/CXGp+cOwRMA0GCSqGSIb3DQEBAQUABIIBACGro/FhOzZozNRYNkWa
# eAFSbiUzSmJ2uP2eCHa1bPKWppYnLSYVqqMHjzQJZ2cy/6HKMKyBr67uamG5Anvr
# 6jq5FfGMjaWrXiod5yzxFyav6gQLop61WedcdcHmTcFxKM5XuZI8PZ9oOZPdhgQy
# ay5jhAZZXNBvpvLish0ccH41vaeEGWqlS/pFpxJiP9IuchBvIiwASyUa59OcysZQ
# UTeWTFEAulpTLwro5bXkuj+nsq+3NijvmJirVaKCXD6IuhjQkrIog9BHZxSP4hol
# fAgQNvGippHsPXS4rLJi/qUbeH1MDxdkS6egSl6mckrKHSiKMMLP+o999wCo8NYY
# nAI=
# SIG # End signature block
