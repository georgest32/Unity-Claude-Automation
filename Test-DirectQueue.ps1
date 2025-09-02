# Direct queue test

# Import module
$modulePath = Join-Path $PSScriptRoot "Modules\Unity-Claude-MessageQueue"
Import-Module (Join-Path $modulePath "Unity-Claude-MessageQueue.psm1") -Force

Write-Host "Testing direct queue operations..." -ForegroundColor Cyan

# Initialize queue
$queue = Initialize-MessageQueue -QueueName "DirectTest" -MaxMessages 10

Write-Host "Queue initialized: $($queue.Name)" -ForegroundColor Green

# Add 5 messages
for ($i = 1; $i -le 5; $i++) {
    $result = Add-MessageToQueue -QueueName "DirectTest" -Message @{
        Data = "Message $i"
    } -MessageType "Test" -Priority $i
    Write-Host "Added message $i with ID: $($result.Id)" -ForegroundColor Cyan
}

# Check queue statistics
$stats = Get-QueueStatistics -QueueName "DirectTest"
Write-Host "`nQueue stats after adding:" -ForegroundColor Yellow
Write-Host "  Queue length: $($stats.QueueLength)"
Write-Host "  Total received: $($stats.TotalReceived)"
Write-Host "  Total processed: $($stats.TotalProcessed)"

# Try to retrieve messages
Write-Host "`nRetrieving messages..." -ForegroundColor Yellow
for ($i = 1; $i -le 5; $i++) {
    $msg = Get-MessageFromQueue -QueueName "DirectTest" -TimeoutSeconds 1
    if ($msg) {
        Write-Host "Retrieved message: ID=$($msg.Id), Data=$($msg.Content.Data)" -ForegroundColor Green
    } else {
        Write-Host "Failed to retrieve message $i" -ForegroundColor Red
    }
}

# Final stats
$finalStats = Get-QueueStatistics -QueueName "DirectTest"
Write-Host "`nFinal queue stats:" -ForegroundColor Yellow
Write-Host "  Queue length: $($finalStats.QueueLength)"
Write-Host "  Total received: $($finalStats.TotalReceived)"
Write-Host "  Total processed: $($finalStats.TotalProcessed)"
# SIG # Begin signature block
# MIIFzgYJKoZIhvcNAQcCoIIFvzCCBbsCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCDWBIxicFCsI8Lg
# eDsj9oO9OY9aLu/StMo2H8IIIlUsZ6CCAzAwggMsMIICFKADAgECAhB1HRbZIqgr
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
# MAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIClAtie8uSXTL13EkjwoEvHk
# H2FrJVqSZMTL32+s3nCnMA0GCSqGSIb3DQEBAQUABIIBAK488eJh/jGf9j+mLdm9
# VN6MxWt+jbw1EvyhGosS/A4T7qF8Y4MWrZi+cYSZltOBfV7sbMb1cc4vEvZrmhZR
# Sz/uAw3/gcvG2kW/8BSXEHC2zMZIQERpMRNkvVOaF/s4ufIoR/nEtpaFJtLDG904
# AeFGVL1XHYl/uEP+99umytrWF9haoXuAsBoqzwgW5m5ZDXY6WJckY5FVMdEkjzDG
# 7feJOlO3/v4qB7ni4dqo5yZtW/jBtWTpHNT+2nGlDXFQGlSecZ7NMKoVhFO1LX1X
# 78ZL8cR06SspwKHCb/yMPBTUOs3Ud8lihEIHInyX8bbfTzE/w28WPV08UmGigHGq
# 5ic=
# SIG # End signature block
