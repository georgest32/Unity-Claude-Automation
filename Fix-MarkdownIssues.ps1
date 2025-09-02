# Fix-MarkdownIssues.ps1
# Auto-fixes markdown linting issues

param(
    [Parameter(Mandatory=$false)]
    [string]$Path = "docs",
    
    [Parameter(Mandatory=$false)]
    [switch]$DryRun
)

Write-Host "Running markdownlint auto-fix..." -ForegroundColor Cyan

$mdFiles = Get-ChildItem -Path $Path -Filter "*.md" -Recurse

if ($DryRun) {
    Write-Host "DRY RUN - No changes will be made" -ForegroundColor Yellow
    markdownlint $Path --config .markdownlintrc
}
else {
    Write-Host "Fixing markdown issues in $($mdFiles.Count) files..." -ForegroundColor Yellow
    
    # Run markdownlint with fix flag
    markdownlint $Path --config .markdownlintrc --fix
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✓ All markdown issues fixed!" -ForegroundColor Green
    }
    else {
        Write-Host "⚠ Some issues could not be auto-fixed" -ForegroundColor Yellow
        Write-Host "Run 'markdownlint $Path' to see remaining issues" -ForegroundColor Cyan
    }
}

# Additional custom fixes
Write-Host "`nApplying custom fixes..." -ForegroundColor Cyan

foreach ($file in $mdFiles) {
    $content = Get-Content $file.FullName -Raw
    $changed = $false
    
    # Fix trailing whitespace
    if ($content -match '\s+$') {
        $content = $content -replace '\s+$', ''
        $changed = $true
    }
    
    # Ensure file ends with single newline
    if (-not $content.EndsWith("`n")) {
        $content += "`n"
        $changed = $true
    }
    
    # Fix multiple consecutive blank lines
    if ($content -match '\n{3,}') {
        $content = $content -replace '\n{3,}', "`n`n"
        $changed = $true
    }
    
    if ($changed -and -not $DryRun) {
        Set-Content -Path $file.FullName -Value $content -NoNewline -Encoding UTF8
        Write-Host "  Fixed: $($file.Name)" -ForegroundColor Green
    }
}

Write-Host "`n✓ Markdown auto-fix complete!" -ForegroundColor Green
# SIG # Begin signature block
# MIIFzgYJKoZIhvcNAQcCoIIFvzCCBbsCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCA1g5BeKqBvNoMg
# cAG/iLykX8CEsFEfu94cvUW+6HNGs6CCAzAwggMsMIICFKADAgECAhB1HRbZIqgr
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
# MAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIHtFR5yj22s27uQpsYg0VmtE
# HlXOA7ehX8qpzveKo2NyMA0GCSqGSIb3DQEBAQUABIIBAI67Rd/60FBa7DjXAYr1
# IeSW03OpH/zILMzkKlG/yO9W2/+MP6la7h94rgAoE7o6nfSdIkzwKjyleeLl5tCZ
# wSWAIWq/aipcM1pbgTeQUehUptPWOemOtCXTRWlYJjZ5f+llPuyqOkhhaSU6m2oG
# h+SdXE2yIVbZJS5yg8eHsnETQjmhbnD4Op19xLZDcYQSPfSuERibCS6dQWXkuGvf
# M6HPkAkM5IOcftjShHrbANY59Y1odPbmjHfsLiGc6WJGSKEBNWBzDHaIEK6gWKan
# +8G9WABWLR3sdQpAHA0dBqj6lGpypawkan0Lk7wt8F/MMhs3eN1sAbzFgtYF22LJ
# Nd0=
# SIG # End signature block
