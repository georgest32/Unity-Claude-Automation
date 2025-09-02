#Requires -Version 7.0
<#
.SYNOPSIS
    Checks PowerShell 7 compatibility for Unity-Claude-Automation
#>

Write-Host "PowerShell 7 Compatibility Check" -ForegroundColor Cyan
Write-Host "=================================" -ForegroundColor Cyan

# Check version
$version = $PSVersionTable.PSVersion
Write-Host "PowerShell Version: $version" -ForegroundColor Green

# Check important modules
$modules = @(
    'Unity-Claude-SystemStatus',
    'Unity-Claude-ParallelProcessing',
    'Unity-Claude-RunspaceManagement'
)

foreach ($module in $modules) {
    try {
        Import-Module ".\Modules\$module" -ErrorAction Stop
        Write-Host "  [OK] $module" -ForegroundColor Green
    } catch {
        Write-Host "  [FAIL] $module - $_" -ForegroundColor Red
    }
}

# Check concurrent collections
try {
    $queue = [System.Collections.Concurrent.ConcurrentQueue[object]]::new()
    $queue.Enqueue("test")
    $result = $null
    if ($queue.TryDequeue([ref]$result)) {
        Write-Host "  [OK] ConcurrentQueue works" -ForegroundColor Green
    }
} catch {
    Write-Host "  [FAIL] ConcurrentQueue - $_" -ForegroundColor Red
}

Write-Host "`nCompatibility check complete!" -ForegroundColor Cyan

# SIG # Begin signature block
# MIIFzgYJKoZIhvcNAQcCoIIFvzCCBbsCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCCYBNc/C1mJeo0U
# 5H4jrXx2fTBjRnjqITMLOnxv5ybX5qCCAzAwggMsMIICFKADAgECAhB1HRbZIqgr
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
# MAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEINT/YkhVePSV1RXp63HzvPPS
# d+kJg7pLedSXJPAH/eniMA0GCSqGSIb3DQEBAQUABIIBAHfLPXyj8baZ6w7S+uae
# 93SNVcht6AUmeqvNr9OGzncS9TQmRlDS7y2iGbHWvJq7BRgZHPyh5gsVKKkA/Rsp
# AfWrXbSRn6zD/Xe4dpxZ8dJuy4mQf+vgA5AUbjOOjVbQHsDliBFbhkq7RBWwyIoI
# VYEAHzCHx5VCgWN6C+yI9m8wjslX6+vJ5uIpMJMQXp4wFrdSdYawc0RjtJh/cRA8
# rhwXsBsTR/RqFW8ShNqv8zuZQgyrfBfBo7tJ9UMRl01iF2sehoC+TGGqdA7B7bMG
# sL2Wedw23emV4oqFQIy7uNHsJhoQrdD5Uduxz84Iy0M6+qemB4YOyXgliCHziUkh
# dkE=
# SIG # End signature block
