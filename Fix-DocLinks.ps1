# Fix-DocLinks.ps1
# Fixes relative links in API documentation

$apiFiles = Get-ChildItem -Path "docs\api" -Filter "*.md" -Recurse

foreach ($file in $apiFiles) {
    $content = Get-Content $file.FullName -Raw
    
    # Fix relative links to go up two directories
    $content = $content -replace '\[Home\]\(\.\./index\.md\)', '[Home](../../index.md)'
    $content = $content -replace '\[User Guide\]\(\.\./user-guide/overview\.md\)', '[User Guide](../../user-guide/overview.md)'
    $content = $content -replace '\[Getting Started\]\(\.\./getting-started/installation\.md\)', '[Getting Started](../../getting-started/installation.md)'
    
    Set-Content -Path $file.FullName -Value $content -Encoding UTF8
    Write-Host "Fixed links in: $($file.Name)" -ForegroundColor Green
}

Write-Host "`nAll API documentation links fixed!" -ForegroundColor Cyan
# SIG # Begin signature block
# MIIFzgYJKoZIhvcNAQcCoIIFvzCCBbsCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCBl4KvIpWUJsgCq
# FyEleYd4o+tIj3lYxzPb/D3AwGY5xKCCAzAwggMsMIICFKADAgECAhB1HRbZIqgr
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
# MAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIDt3oZh0cfBtKe0KWmxk2Y9M
# ybrmc7R/6O4BtYbjENwtMA0GCSqGSIb3DQEBAQUABIIBAEcNSVFz0kLyRS3wa1Yk
# Xr26GgHTXTmLhWjqVQuuC0gxWp/9yexnWnzBqmPbRqSaRd0E3URhkyK6it39IWdr
# 3g4afY4MIarV4q+vrFVe3kIYkkhv9TvqFe14aDrgFCfdN32V9saLjHaVdmHvERK4
# MISHqNhjjwyTuG3y/bXnEdJTgxfffYKpwCtYzc6IZxebAcAGZm0DeyvDNk0Xlk4+
# jaxIZr2ktr9IGX8staa3dRY2Ki8t5iDii/oR2Xw/YmPmQpkZmUhOq9eudDmSe5Xf
# FehtA6PZ5+8bB4m4Eq8ZnS8W8471ZXyrWmcdEGeo5P/iZx1kwAaQ2e5n7H3EtqZj
# 4l4=
# SIG # End signature block
