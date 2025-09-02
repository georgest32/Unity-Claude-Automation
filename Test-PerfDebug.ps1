# Performance test debug

# Import module
$modulePath = Join-Path $PSScriptRoot "Modules\Unity-Claude-MessageQueue"
Import-Module (Join-Path $modulePath "Unity-Claude-MessageQueue.psm1") -Force

Write-Host "Starting performance test..." -ForegroundColor Cyan

$iterations = 10

# Benchmark enqueue
Write-Host "`nEnqueuing $iterations messages..." -ForegroundColor Yellow
for ($i = 1; $i -le $iterations; $i++) {
    Add-MessageToQueue -QueueName "BenchmarkQueue" -Message @{
        Index = $i
        Timestamp = Get-Date
    } -MessageType "Benchmark" -Priority 5
}

# Check if messages are actually in the queue
Write-Host "`nChecking queue state..." -ForegroundColor Yellow
if ($script:MessageQueue) {
    Write-Host "ERROR: Cannot access script scope from here" -ForegroundColor Red
} else {
    Write-Host "Script scope not accessible (expected)" -ForegroundColor Gray
}

# Try to get messages using the same timeout as the test
Write-Host "`nRetrieving messages with 0.1 second timeout..." -ForegroundColor Yellow
$retrieved = 0
for ($i = 1; $i -le $iterations; $i++) {
    Write-Host "Attempt $i..." -NoNewline
    $msg = Get-MessageFromQueue -QueueName "BenchmarkQueue" -TimeoutSeconds 0.1
    if ($msg) { 
        $retrieved++
        Write-Host " SUCCESS" -ForegroundColor Green
    } else {
        Write-Host " FAILED" -ForegroundColor Red
    }
}

Write-Host "`nResult: Retrieved $retrieved out of $iterations messages" -ForegroundColor $(if ($retrieved -eq $iterations) { "Green" } else { "Red" })
# SIG # Begin signature block
# MIIFzgYJKoZIhvcNAQcCoIIFvzCCBbsCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCAt0QQZqqbsG6Mp
# ztvqRrOg9/mASQCmUKAGepWce3mG2qCCAzAwggMsMIICFKADAgECAhB1HRbZIqgr
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
# MAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIFnO4gKDb1vTxB/rguPAXjkt
# 7MHnh226IU5X0ATGmSdhMA0GCSqGSIb3DQEBAQUABIIBAF9ah1VLwApx4A0E9AsU
# P8yTuLGUpsmJVhOERDOxD/0GAKqhjn/0XyvmducTmdvnhtwJSjN7jfgSqKuHbCd0
# ZHmk7ZITOvZXR1Oj1ZHUkgvgTDeDvg1uwcjnt8eVnvSn7t//T6v+xf0RNo4wwinH
# UJGifVuqeP+wjD2aXaLxuTfCqVf/hogzCwzNrPhrOxdQufedT8Y8lDrR2A8bb06B
# 8sld85c5Uub5IBcapn+l61dmJ4nrjNMkdmtAaHFuyeDivAiU2homxRd8atUPlwsn
# 3JqzaegE8+FMLute0orXh4KpQotVo5MZN5CBCPGSOJtsU+NgcdFtdga///N5qUgu
# H7A=
# SIG # End signature block
