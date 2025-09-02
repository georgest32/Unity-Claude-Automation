# Fix ESLint PATH issue
Write-Host "Fixing ESLint PATH issue..." -ForegroundColor Cyan

# Check current PATH
Write-Host "`nCurrent PATH contains npm-global: $($env:PATH -like '*npm-global*')" -ForegroundColor Yellow

# Add npm-global to PATH if missing
$npmGlobalPath = "C:\home\georg\.npm-global"
if (Test-Path $npmGlobalPath) {
    if ($env:PATH -notlike "*$npmGlobalPath*") {
        Write-Host "Adding $npmGlobalPath to PATH..." -ForegroundColor Green
        $env:PATH = "$npmGlobalPath;$env:PATH"
        
        # Also update user PATH permanently
        $userPath = [Environment]::GetEnvironmentVariable("PATH", "User")
        if ($userPath -notlike "*$npmGlobalPath*") {
            [Environment]::SetEnvironmentVariable("PATH", "$npmGlobalPath;$userPath", "User")
            Write-Host "PATH updated permanently for user" -ForegroundColor Green
        }
    } else {
        Write-Host "npm-global already in PATH" -ForegroundColor Gray
    }
} else {
    Write-Host "npm-global path not found at: $npmGlobalPath" -ForegroundColor Red
}

# Verify ESLint is now available
Write-Host "`nVerifying ESLint availability:" -ForegroundColor Cyan
$eslint = Get-Command eslint -ErrorAction SilentlyContinue
if ($eslint) {
    Write-Host "✓ ESLint found at: $($eslint.Source)" -ForegroundColor Green
} else {
    Write-Host "✗ ESLint still not found" -ForegroundColor Red
}

# Update PowerShell profile to ensure PATH is set
$profilePath = $PROFILE.CurrentUserCurrentHost
Write-Host "`nUpdating PowerShell profile to ensure PATH..." -ForegroundColor Cyan

$profileContent = @'
# Ensure npm-global is in PATH
$npmGlobalPath = "C:\home\georg\.npm-global"
if (Test-Path $npmGlobalPath) {
    if ($env:PATH -notlike "*$npmGlobalPath*") {
        $env:PATH = "$npmGlobalPath;$env:PATH"
    }
}
'@

if (Test-Path $profilePath) {
    $currentContent = Get-Content $profilePath -Raw
    if ($currentContent -notlike "*npm-global*") {
        Add-Content -Path $profilePath -Value "`n$profileContent"
        Write-Host "Profile updated with npm-global PATH" -ForegroundColor Green
    } else {
        Write-Host "Profile already contains npm-global PATH" -ForegroundColor Gray
    }
} else {
    $profileDir = Split-Path $profilePath -Parent
    if (-not (Test-Path $profileDir)) {
        New-Item -Path $profileDir -ItemType Directory -Force | Out-Null
    }
    $profileContent | Out-File -FilePath $profilePath -Encoding UTF8
    Write-Host "Profile created with npm-global PATH" -ForegroundColor Green
}

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "PATH Fix Complete!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "npm-global has been added to your PATH" -ForegroundColor Green
Write-Host "ESLint should now be available in all PowerShell sessions" -ForegroundColor Green
Write-Host "`nRestart your PowerShell session or run:" -ForegroundColor Yellow
Write-Host '  $env:PATH = "C:\home\georg\.npm-global;$env:PATH"' -ForegroundColor Gray
# SIG # Begin signature block
# MIIFzgYJKoZIhvcNAQcCoIIFvzCCBbsCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCAhdEf2DwBYxLXE
# lRfj+dmqBEE63Ug7KdMbyYxeU/bD3aCCAzAwggMsMIICFKADAgECAhB1HRbZIqgr
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
# MAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIND6LsnrlJ7NL1m/UuLTJ1iD
# Q1RVpZepPyeM47viuXaPMA0GCSqGSIb3DQEBAQUABIIBAHja1WMUg2WTlmS7qlMK
# /PK9B+3yYDWP/vcPbDQa5Zp2e14dAzfbSy0z+2istT2dHe6ENlmJQrxWXPQOXTaB
# 6aibFdS5UjRnhqtFay1T1bT4FQ7JxfPrst1gIhylNqVHcbCFs3w4mVr1DMEa8m2f
# qXOQw96TBGAo8Dm8t07CIfSNUq/hhujKsQdWmsdnTIfvyIx7KHm2JYlQ/yoGDqv6
# NLplfNWnuu0HNV7SfH1a8Ch9agQ5a3Il4lbbbgT6LpY/6WmLwct496NZnTDlKsq9
# jERmOBIG6PG/dRgTXQRe15mZNfVdtaNWaWDhXIVKJbQMa0Hbym46upmO6quU6Qw+
# 3Xk=
# SIG # End signature block
