# Fix-PythonWSL.ps1
# Script to fix Python package corruption in WSL Ubuntu

Write-Host "=== Fixing Python Package Issues in WSL ===" -ForegroundColor Cyan
Write-Host ""

Write-Host "This script will fix the Python package corruption issue." -ForegroundColor Yellow
Write-Host "You will be prompted for your Ubuntu sudo password." -ForegroundColor Yellow
Write-Host ""

# Step 1: Clear Python cache files
Write-Host "Step 1: Clearing Python cache files..." -ForegroundColor Yellow
$clearCacheCmd = @"
echo 'Clearing Python cache files...'
sudo find /usr -name '*.pyc' -delete 2>/dev/null
sudo find /usr -name '__pycache__' -type d -exec rm -rf {} + 2>/dev/null
echo 'Cache cleared'
"@

wsl -d Ubuntu -- bash -c $clearCacheCmd

# Step 2: Fix dpkg configuration
Write-Host ""
Write-Host "Step 2: Fixing package configuration..." -ForegroundColor Yellow
wsl -d Ubuntu -- bash -c "sudo dpkg --configure -a"

# Step 3: Try to reinstall python3-pip
Write-Host ""
Write-Host "Step 3: Reinstalling python3-pip..." -ForegroundColor Yellow
wsl -d Ubuntu -- bash -c "sudo apt-get install --reinstall python3-pip -y"

# Step 4: Verify Python and pip
Write-Host ""
Write-Host "Step 4: Verifying Python and pip installation..." -ForegroundColor Yellow
$pythonVersion = wsl -d Ubuntu -e bash -c "python3 --version" 2>&1
$pipVersion = wsl -d Ubuntu -e bash -c "pip3 --version" 2>&1

if ($LASTEXITCODE -eq 0) {
    Write-Host "Python: $pythonVersion" -ForegroundColor Green
    Write-Host "Pip: $pipVersion" -ForegroundColor Green
    Write-Host ""
    Write-Host "Python environment fixed successfully!" -ForegroundColor Green
} else {
    Write-Host "There may still be issues with Python/pip installation" -ForegroundColor Yellow
    Write-Host "Python check: $pythonVersion"
    Write-Host "Pip check: $pipVersion"
}

Write-Host ""
Write-Host "Next step: Run ./Install-RepoAnalystTools.ps1 to complete the setup" -ForegroundColor Cyan
# SIG # Begin signature block
# MIIFzgYJKoZIhvcNAQcCoIIFvzCCBbsCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCCQwm8L5t3UWM18
# 19zwmn5ySryqMMuU4le/63u6urhnT6CCAzAwggMsMIICFKADAgECAhB1HRbZIqgr
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
# MAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEILkfGIw3OHzfNI7UPv4snEt4
# RrwO6uYUGJP777oUdfdlMA0GCSqGSIb3DQEBAQUABIIBACkkeklJzt/CnM5mZPA3
# Ko7hxA4dpDOUuJqbRdTBfCf7zkg5maXYI4qh4OGA85XfdSAbHdsdVZnec6Ya9NQt
# UR3N+1zHfz+yuN5NVC0i5Oe/uEMy/i9PhytHVbcFEEQlUEGVOqC320s8V81H2xad
# SxtjhoAjXDX9bW+K9y76ZLJi2j+ASze24MXq5oObHpwSAbX5ix4icFRGDI+Wmbqk
# c4mOUTj1b4aaKSs63ndqzcI51sKXe0pfK55i10q9zxeAmnA5PtxuHuak30DsvZmH
# 2t4a4nbscBtk2ZlAb3SL+XiHAKbAm/CayXMoJvGQPE2FP/r0f9n6uBe8FYCOWctd
# HMU=
# SIG # End signature block
