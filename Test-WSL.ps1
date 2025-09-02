# Test WSL detection
Write-Host "Testing WSL detection..." -ForegroundColor Yellow

# Method 1: Direct check
Write-Host "`nMethod 1: Direct list"
$directList = wsl --list --quiet
Write-Host "Direct output:"
$directList

# Method 2: Converted to string
Write-Host "`nMethod 2: As string"
$asString = wsl --list --quiet | Out-String
Write-Host "String output: [$asString]"

# Method 3: Remove spaces
Write-Host "`nMethod 3: Cleaned"
$cleaned = ($asString -replace '\s', '')
Write-Host "Cleaned: [$cleaned]"

# Method 4: Check for Ubuntu
Write-Host "`nMethod 4: Detection"
if ($cleaned -like "*Ubuntu*") {
    Write-Host "Ubuntu FOUND" -ForegroundColor Green
} else {
    Write-Host "Ubuntu NOT FOUND" -ForegroundColor Red
}

# Method 5: Alternative approach - check if we can run a command in Ubuntu
Write-Host "`nMethod 5: Try to run command in Ubuntu"
try {
    $ubuntuTest = wsl -d Ubuntu -e echo "Ubuntu is working" 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Host "Ubuntu is accessible: $ubuntuTest" -ForegroundColor Green
        $ubuntuInstalled = $true
    } else {
        Write-Host "Ubuntu not accessible" -ForegroundColor Red
        $ubuntuInstalled = $false
    }
} catch {
    Write-Host "Ubuntu not accessible (exception)" -ForegroundColor Red
    $ubuntuInstalled = $false
}

Write-Host "`nResult: Ubuntu installed = $ubuntuInstalled"
# SIG # Begin signature block
# MIIFzgYJKoZIhvcNAQcCoIIFvzCCBbsCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCCIH4E/8PlTHPJf
# WZrcssAuHAXKIue3RfzqpYLnEIDNK6CCAzAwggMsMIICFKADAgECAhB1HRbZIqgr
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
# MAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIF27Hl472BoN17d7MsK4yX8T
# EKvQlAsm3nL42tTFd0zWMA0GCSqGSIb3DQEBAQUABIIBAD4C95zKseNPVoxST0kb
# VPtFB8L93g2wq3IRTlo3g0x11VYyvJ/NC8y6Kl+HIZ60yrc1/Thp+gYNNVWho5Gj
# pWJcFhEopQ0WRTDpE2LVEiGFjPSrRlitQaI6mrVGFD1D02NUC6ZLLJkBPXJWyd9T
# OzbYS98hEDy36zi76f8beK6WeYVKDBoofUiRgctbYiMDsiu9xvf43d3zRfzAwn5J
# 7+M9Gpg/UKo3emPeToeJAOpPhW/NrWbKeicMkWShXY3fxiQHcmfVGvKzvUycNUYZ
# rxKObn/KheJ2dizQFYo3ymoCNy0/oX0dBX4uxtFO30wGJM5lSXz0Idt7uIbPeTOx
# gM8=
# SIG # End signature block
