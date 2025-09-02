# Test Queue Performance

# Import modules
$modulePath = Join-Path $PSScriptRoot "Modules\Unity-Claude-MessageQueue"
Import-Module (Join-Path $modulePath "Unity-Claude-MessageQueue.psm1") -Force

Write-Host "Testing queue performance..." -ForegroundColor Cyan

# Test enqueue
$iterations = 100
$startTime = Get-Date

for ($i = 1; $i -le $iterations; $i++) {
    Add-MessageToQueue -QueueName "PerfTestQueue" -Message @{
        Index = $i
        Data = "Test message $i"
    } -MessageType "Test" -Priority 5
}

$enqueueDuration = (Get-Date) - $startTime
$enqueueRate = $iterations / $enqueueDuration.TotalSeconds

Write-Host "Enqueue rate: $([Math]::Round($enqueueRate, 2)) msg/sec" -ForegroundColor Green

# Check queue status
$stats = Get-QueueStatistics -QueueName "PerfTestQueue"
Write-Host "Messages in queue: $($stats.QueueLength)" -ForegroundColor Cyan

# Test dequeue
$retrievalStart = Get-Date
$retrieved = 0

for ($i = 1; $i -le $iterations; $i++) {
    $msg = Get-MessageFromQueue -QueueName "PerfTestQueue" -TimeoutSeconds 0.01
    if ($msg) { 
        $retrieved++
        Write-Progress -Activity "Dequeuing" -Status "$retrieved/$iterations" -PercentComplete (($retrieved/$iterations)*100)
    } else {
        Write-Host "Failed to retrieve message $i" -ForegroundColor Red
        break
    }
}

$dequeueDuration = (Get-Date) - $retrievalStart
$dequeueRate = if ($dequeueDuration.TotalSeconds -gt 0) { $retrieved / $dequeueDuration.TotalSeconds } else { 0 }

Write-Host "`nResults:" -ForegroundColor Yellow
Write-Host "  Enqueued: $iterations messages in $([Math]::Round($enqueueDuration.TotalSeconds, 3)) seconds"
Write-Host "  Enqueue rate: $([Math]::Round($enqueueRate, 2)) msg/sec"
Write-Host "  Retrieved: $retrieved messages in $([Math]::Round($dequeueDuration.TotalSeconds, 3)) seconds"
Write-Host "  Dequeue rate: $([Math]::Round($dequeueRate, 2)) msg/sec"

# Final queue status
$finalStats = Get-QueueStatistics -QueueName "PerfTestQueue"
Write-Host "`nFinal queue status:" -ForegroundColor Cyan
Write-Host "  Messages remaining: $($finalStats.QueueLength)"
Write-Host "  Total received: $($finalStats.TotalReceived)"
Write-Host "  Total processed: $($finalStats.TotalProcessed)"
# SIG # Begin signature block
# MIIFzgYJKoZIhvcNAQcCoIIFvzCCBbsCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCDiEgUSJPq3mNka
# kvNMNJrrQZqSbw3oKWlPuYgRaYM5X6CCAzAwggMsMIICFKADAgECAhB1HRbZIqgr
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
# MAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIJPf36EQWTMXc0Ck+O7NiLsN
# aVI4T4Hk06PC0t0zwGviMA0GCSqGSIb3DQEBAQUABIIBAK25FXEHaRU2CVH776tu
# v9EfGyjB40oU17y73sPNyFHLme82YEzXtJ4gVcRH3IYIuP+0dA66vqFoT1QVQYmz
# A7OwpnXKdHUDQDahEd+DsrF1g3pGsI0pV3lgDKdm8pNYfQrkKbwUMAEubozok0rN
# GkLCij8uv/VPLKAeRzQSrKz8RvT+UI4nq0kUewWkQc1iHdPmGGjmKfLYG8PBRCCb
# nzfyog/sc0bExKL4Tx9gM3MQJn0e4OwQAlpGwB02lQ3R/KjxENs4jhnh2NbedOxT
# GOKBllZc1e2v3gZaCViUGMOYCLoCrnTM/MjH6HstsfDzg9AzLou2m6hMyQ1ayjiB
# yWE=
# SIG # End signature block
