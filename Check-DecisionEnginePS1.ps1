# Test script to check DecisionEngine.psm1 syntax
$ErrorActionPreference = 'Stop'

Write-Host "Checking DecisionEngine.psm1 for syntax errors..." -ForegroundColor Cyan

$filePath = "C:\UnityProjects\Sound-and-Shoal\Unity-Claude-Automation\Modules\Unity-Claude-CLIOrchestrator\Core\DecisionEngine.psm1"

# Parse the file
$tokens = $null
$parseErrors = $null
$ast = [System.Management.Automation.Language.Parser]::ParseFile($filePath, [ref]$tokens, [ref]$parseErrors)

if ($parseErrors) {
    Write-Host "Found $($parseErrors.Count) syntax error(s):" -ForegroundColor Red
    foreach ($parseError in $parseErrors) {
        Write-Host ""
        Write-Host "Line $($parseError.Extent.StartLineNumber), Column $($parseError.Extent.StartColumnNumber):" -ForegroundColor Yellow
        Write-Host "  Error: $($parseError.Message)" -ForegroundColor Red
        $lineContent = Get-Content $filePath | Select-Object -Skip ($parseError.Extent.StartLineNumber - 1) -First 1
        Write-Host "  Line content: $lineContent" -ForegroundColor Gray
    }
} else {
    Write-Host "No syntax errors found!" -ForegroundColor Green
}
# SIG # Begin signature block
# MIIFzgYJKoZIhvcNAQcCoIIFvzCCBbsCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCAyHIeZ0+hBygyS
# 3SMejHH+buOzU2/09xMMfCmN4kE0RaCCAzAwggMsMIICFKADAgECAhB1HRbZIqgr
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
# MAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEICz9HXohRT6IONE70x/FeCkj
# c8Pxyue7hTIOBEojWYvJMA0GCSqGSIb3DQEBAQUABIIBABAuK5iccSawaxeYQ/ta
# QDEz8GavgcVm7aHjMTgAXQR4/AiKiUITsUp/KtE54I7keVJ41pR9eaoWkutiv1Tv
# xEzxSdcpERz7FVEDa6C9cLNvGMT17LMOzOkAQ8Mh85mhbXnCD48flUVHtjOR6mTe
# oFlbyaWW2yp3hJoGcSPXUD/xhk35xr3ib974u8IH54AFT0H4V5zTOdmK8sygQAng
# h3x+ajJA7ocwYVfOzAUXrE6L1+MDawqaQpoK8PqPx2qrooIqCylbFwRnj3cLCDnK
# ibpp1cJdAt/jfXJ7SVuuQUi7bWzFYA6jUTyDwvMh0WZ+gdLqz4P9I/e025qt1Cgd
# /0U=
# SIG # End signature block
