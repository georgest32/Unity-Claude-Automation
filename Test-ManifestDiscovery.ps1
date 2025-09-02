# Test-ManifestDiscovery.ps1
# Test that manifest discovery properly excludes backup directories

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "TEST: Manifest Discovery (Exclude Backups)" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan

$projectRoot = "C:\UnityProjects\Sound-and-Shoal\Unity-Claude-Automation"
Set-Location $projectRoot

# Load the SystemStatus module
Write-Host "Loading SystemStatus module..." -ForegroundColor Yellow
Import-Module ".\Modules\Unity-Claude-SystemStatus\Unity-Claude-SystemStatus.psm1" -Force
Write-Host "  Module loaded" -ForegroundColor Green

# Test manifest discovery
Write-Host "`nDiscovering manifests..." -ForegroundColor Yellow
$manifests = Get-SubsystemManifests -Path @(".\Manifests", ".")

Write-Host "`nResults:" -ForegroundColor Cyan
Write-Host "  Total manifests found: $($manifests.Count)" -ForegroundColor White

# Check for duplicates
$names = $manifests | ForEach-Object { $_.Name }
$uniqueNames = $names | Select-Object -Unique
if ($names.Count -ne $uniqueNames.Count) {
    Write-Host "  [WARNING] Duplicate subsystem names detected!" -ForegroundColor Yellow
    $duplicates = $names | Group-Object | Where-Object { $_.Count -gt 1 }
    foreach ($dup in $duplicates) {
        Write-Host "    - $($dup.Name): $($dup.Count) instances" -ForegroundColor Yellow
    }
} else {
    Write-Host "  [OK] No duplicate subsystem names" -ForegroundColor Green
}

# List manifests
Write-Host "`nManifests discovered:" -ForegroundColor Cyan
foreach ($manifest in $manifests) {
    $color = if ($manifest.IsValid) { "Green" } else { "Red" }
    $status = if ($manifest.IsValid) { "VALID" } else { "INVALID" }
    Write-Host "  - $($manifest.Name) v$($manifest.Version) [$status]" -ForegroundColor $color
    
    # Check if from backup directory (should not happen with fix)
    if ($manifest.Path -match "\\Backups\\" -or $manifest.Path -match "/Backups/") {
        Write-Host "    [ERROR] This manifest is from a backup directory!" -ForegroundColor Red
        Write-Host "    Path: $($manifest.Path)" -ForegroundColor Red
    }
}

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "TEST COMPLETE" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan

if ($manifests.Count -eq 3) {
    Write-Host "SUCCESS: Expected 3 manifests (no backups included)" -ForegroundColor Green
} else {
    Write-Host "WARNING: Expected 3 manifests but found $($manifests.Count)" -ForegroundColor Yellow
}
# SIG # Begin signature block
# MIIFzgYJKoZIhvcNAQcCoIIFvzCCBbsCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCDEsoHtlo0x+2um
# 7Y8G7oL7/ZXPDD+h+V1YkrLGs1fuIaCCAzAwggMsMIICFKADAgECAhB1HRbZIqgr
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
# MAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIJZs+jwUg3YxA/qYRhWtYKWd
# mdc8J93mLY5YttsTuapDMA0GCSqGSIb3DQEBAQUABIIBAEL6GKPUshL8H51X5Nty
# Jr4jVVZiH/XqgRq3ap6/ti7c75f+tHT4jnW4TOYLpJfJKWv3UEIOo281Yxoa5aSh
# Uw5XrgwE3ce5VocCgYwwBWqLlLNBTn6dJvMDfuxOX4hpoWNSiWbV2oVaf8fKLkkx
# OlwWEm9eGHVBUa5umr5qLznDcIL6Z4YsC4ygRfmnJePc75ByuA6hYu6lp8orFUA+
# Upg8BlNGVcfAcOku/y7BHHeTJd11nczD8+xepzt7leeCCdyXz+n37wENan3FtrFr
# It3EG4Js6qvKBMBioPjE69ZjXXaKkJ6KFbNa7cIsKO1w8pMbLDvwq6vzNjy7FEAT
# 7Gk=
# SIG # End signature block
