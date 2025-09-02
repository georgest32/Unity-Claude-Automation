# Check-SyntaxError.ps1
$ErrorActionPreference = "Stop"

$file = "C:\UnityProjects\Sound-and-Shoal\Unity-Claude-Automation\Modules\Unity-Claude-ParallelProcessor\Unity-Claude-ParallelProcessor.psm1"

Write-Host "Checking syntax of: $file" -ForegroundColor Cyan

$errors = $null
$tokens = $null
$ast = [System.Management.Automation.Language.Parser]::ParseFile(
    $file,
    [ref]$tokens,
    [ref]$errors
)

if ($errors -and $errors.Count -gt 0) {
    Write-Host "Found $($errors.Count) syntax error(s):" -ForegroundColor Red
    foreach ($err in $errors) {
        Write-Host "  Line $($err.Extent.StartLineNumber): $($err.Message)" -ForegroundColor Yellow
        Write-Host "  Near: $($err.Extent.Text)" -ForegroundColor Gray
    }
} else {
    Write-Host "No syntax errors found!" -ForegroundColor Green
}

# Try to import and see what happens
try {
    Import-Module $file -Force -ErrorAction Stop
    Write-Host "Module imported successfully!" -ForegroundColor Green
} catch {
    Write-Host "Import failed: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "Error details: $($_.Exception.InnerException)" -ForegroundColor Yellow
}
# SIG # Begin signature block
# MIIFzgYJKoZIhvcNAQcCoIIFvzCCBbsCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCBDUI9OaLU1LZ5H
# x7zIak0BU3XAj6U0mPeCclNuQc+6CKCCAzAwggMsMIICFKADAgECAhB1HRbZIqgr
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
# MAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIPlMriSfGkRFH0C52PHii0lj
# iddHqaD6eMT9ESrochVbMA0GCSqGSIb3DQEBAQUABIIBAF4O9fcvMxxT6+KYu+xO
# 6fmHoGhdXAQ5VuARebbPFZTVNO6mVpRAOlM84D7QsCXwM6dxkmCyb0aNZy9wMG59
# 8PNzog5sxBJ9VSjpRuDoQmSBaJ5Z2zePfRb0DS4m5oTq5EirSP2mYTg2ivKsHt/J
# WmF7n5FYciZiAgzNGAMuNeVuSAA5EWUCfef1aV819pLNPacWSQkLqiugPNB8Xwrh
# 8xk9HxTzsaH2XN3dxmeTyOs9D73NkZncdVKOXr5b0SQBKJvP3EI62OQ5JTgbc6MB
# 0B8H72pyVZyiWwwwpGM65Q7v8eZrYUYoZe8H8X+c4HRaJzIrK8QBBcIncLHq7waL
# Lxg=
# SIG # End signature block
