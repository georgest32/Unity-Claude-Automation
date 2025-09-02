# Environment Check Script
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "PowerShell Environment Check" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

# PowerShell version
Write-Host "`nPowerShell Version:" -ForegroundColor Yellow
$PSVersionTable.PSVersion | Format-Table -AutoSize

# Check for eslint
Write-Host "`nChecking for ESLint:" -ForegroundColor Yellow
$eslintCmd = Get-Command "eslint.cmd" -ErrorAction SilentlyContinue
$eslint = Get-Command "eslint" -ErrorAction SilentlyContinue

if ($eslintCmd) {
    Write-Host "  eslint.cmd found at: $($eslintCmd.Source)" -ForegroundColor Green
} else {
    Write-Host "  eslint.cmd NOT found" -ForegroundColor Red
}

if ($eslint) {
    Write-Host "  eslint found at: $($eslint.Source)" -ForegroundColor Green
} else {
    Write-Host "  eslint NOT found" -ForegroundColor Red
}

# Check PATH for npm-global
Write-Host "`nSearching PATH for npm-global directories:" -ForegroundColor Yellow
$env:PATH.Split(';') | Where-Object { $_ -like "*npm*" -or $_ -like "*.npm-global*" } | ForEach-Object {
    Write-Host "  $_" -ForegroundColor Gray
}

# Check for PSScriptAnalyzer
Write-Host "`nChecking for PSScriptAnalyzer:" -ForegroundColor Yellow
$psa = Get-Module -ListAvailable PSScriptAnalyzer
if ($psa) {
    Write-Host "  PSScriptAnalyzer found:" -ForegroundColor Green
    $psa | ForEach-Object {
        Write-Host "    Version: $($_.Version) at $($_.Path)" -ForegroundColor Gray
    }
} else {
    Write-Host "  PSScriptAnalyzer NOT found" -ForegroundColor Red
}

# Check which PowerShell is default
Write-Host "`nDefault PowerShell check:" -ForegroundColor Yellow
Write-Host "  Current process: $([System.Diagnostics.Process]::GetCurrentProcess().ProcessName)" -ForegroundColor Gray
Write-Host "  Executable: $([System.Diagnostics.Process]::GetCurrentProcess().MainModule.FileName)" -ForegroundColor Gray
# SIG # Begin signature block
# MIIFzgYJKoZIhvcNAQcCoIIFvzCCBbsCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCCiHAL4xrCzi5dK
# DoTLVWC5cPQ0p5G+1BPosdYnWRheE6CCAzAwggMsMIICFKADAgECAhB1HRbZIqgr
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
# MAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIB+DtSaWMYQr702mcQLAAWMF
# +QSou1MVpBg2E2ri1WZtMA0GCSqGSIb3DQEBAQUABIIBAAj28xn/xQ2Oo1VumKSZ
# XDONry0dlmvQqAhARGVCjTKiPwSNo/3poTh+tshyeP96SOmmpfW9Nuviixeq/WiR
# 9PUagdF8WMxdDxr0py+GldhL2rN4lDrDkRp59WEKRV4nK7GgX6hJAEdnxBubMNig
# 9TB7TpNnEw4PNA+e71pDhlnxbEx0FoJ8aSVRGUplrgNYceLxkLbwiiNjTYGnxUA4
# wyBfHQNDV6MggK6MUbEoXornNzObL8vBBSNmyncWlqjTs48DNfdNV1gBaxeSaJRs
# pN6IZHIn+DBl3j8oJ9ctbq6bx5+kvFU7Gzz4eYek3ER+7C42/JuBBxTg4tlbVI0y
# Rb0=
# SIG # End signature block
