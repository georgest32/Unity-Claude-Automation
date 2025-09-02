# Debug benchmark test

# Import module
$modulePath = Join-Path $PSScriptRoot "Modules\Unity-Claude-MessageQueue"
Import-Module (Join-Path $modulePath "Unity-Claude-MessageQueue.psm1") -Force

Write-Host "Testing benchmark operations..." -ForegroundColor Cyan

# Enqueue messages
$iterations = 10
for ($i = 1; $i -le $iterations; $i++) {
    Add-MessageToQueue -QueueName "BenchmarkQueue" -Message @{
        Index = $i
        Timestamp = Get-Date
    } -MessageType "Benchmark" -Priority 5
}

Write-Host "Enqueued $iterations messages" -ForegroundColor Green

# Try to retrieve
$retrieved = 0
for ($i = 1; $i -le $iterations; $i++) {
    Write-Host "Attempting to retrieve message $i..." -ForegroundColor Cyan
    $msg = Get-MessageFromQueue -QueueName "BenchmarkQueue" -TimeoutSeconds 0.1
    if ($msg) { 
        $retrieved++
        Write-Host "  SUCCESS: Retrieved message with Index=$($msg.Content.Index)" -ForegroundColor Green
    } else {
        Write-Host "  FAILED: No message retrieved" -ForegroundColor Red
    }
}

Write-Host "`nSummary:" -ForegroundColor Yellow
Write-Host "  Enqueued: $iterations"
Write-Host "  Retrieved: $retrieved"
# SIG # Begin signature block
# MIIFzgYJKoZIhvcNAQcCoIIFvzCCBbsCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCBEhOi3w59XXA7Y
# 0vwLysasDKrQTSRZg0rjDpHwfVxUQKCCAzAwggMsMIICFKADAgECAhB1HRbZIqgr
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
# MAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIMova6sVegAJVvOXZ9eX2ns4
# pa8iymMsuY/PzCzBJ6IxMA0GCSqGSIb3DQEBAQUABIIBAEriSyRVnM2lTryQLdr/
# 3p1gNXehllgr1UdBktQshjqAMGRGdd6H4NTiV67zgD0/AshVzUmJpn3KcRxQd9wm
# huK5hNu6IZbiK2LwhXGF9fGoKmthldKgaj3hyq0gOcB5qreIwWkf1EnDmGomjKI/
# xTx1eJxSnWl7lz1xVDWJRR7Hojbk7uwD/OxsNzhdCUYusZjl5jGOai83Qrc7hg1w
# 72oPsPS2lSzjjiA4JYXhlAmQ2v5jZ66qdguzIEDoNQDXgMdpX2phMPaNOkOakW8c
# wZprlJlCqqpJt4ZwfBqIWe46Y5CRVwrpqH19XWRv9UoraXXZTnShn0XaVi4jMtsP
# 7Zs=
# SIG # End signature block
