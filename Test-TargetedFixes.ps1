# Test-TargetedFixes.ps1
# Test the specific fixes for ConcurrentBag ToArray and performance metrics

Write-Host "=== Targeted Fixes Test ===" -ForegroundColor Cyan

try {
    # Import module
    Import-Module ".\Modules\Unity-Claude-ParallelProcessing\Unity-Claude-ConcurrentCollections.psd1" -Force
    Write-Host "Module imported successfully" -ForegroundColor Green
    
    # Test 1: ConcurrentBag ToArray fix
    Write-Host "`nTest 1: ConcurrentBag ToArray Fix" -ForegroundColor Yellow
    $bag = New-ConcurrentBag
    
    # Add some items
    $null = Add-ConcurrentBagItem -Bag $bag -Item "Item1"
    $null = Add-ConcurrentBagItem -Bag $bag -Item "Item2" 
    $null = Add-ConcurrentBagItem -Bag $bag -Item "Item3"
    
    # Test ToArray method
    $allItems = Get-ConcurrentBagItems -Bag $bag
    Write-Host "  ToArray result: $($allItems.Count) items" -ForegroundColor Gray
    Write-Host "  Items: $($allItems -join ', ')" -ForegroundColor Gray
    
    if ($allItems.Count -eq 3) {
        Write-Host "  ConcurrentBag ToArray: SUCCESS" -ForegroundColor Green
    } else {
        Write-Host "  ConcurrentBag ToArray: FAILED (expected 3, got $($allItems.Count))" -ForegroundColor Red
    }
    
    # Test 2: Performance metrics fix
    Write-Host "`nTest 2: Performance Metrics Fix" -ForegroundColor Yellow
    $queue = New-ConcurrentQueue
    
    # Add items to both collections
    for ($i = 1; $i -le 5; $i++) {
        $null = Add-ConcurrentQueueItem -Queue $queue -Item "QueueItem$i"
    }
    
    # Get metrics
    $metrics = Get-ConcurrentCollectionMetrics -Collections @{
        TestQueue = $queue
        TestBag = $bag
    }
    
    Write-Host "  Total items: $($metrics.TotalItems)" -ForegroundColor Gray
    Write-Host "  Queue count: $($metrics.Collections.TestQueue.Count)" -ForegroundColor Gray
    Write-Host "  Bag count: $($metrics.Collections.TestBag.Count)" -ForegroundColor Gray
    
    $expectedTotal = 8  # 5 in queue + 3 in bag
    if ($metrics.TotalItems -eq $expectedTotal) {
        Write-Host "  Performance Metrics: SUCCESS" -ForegroundColor Green
    } else {
        Write-Host "  Performance Metrics: FAILED (expected $expectedTotal, got $($metrics.TotalItems))" -ForegroundColor Red
    }
    
} catch {
    Write-Host "ERROR: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host "`n=== End Targeted Test ===" -ForegroundColor Cyan
# SIG # Begin signature block
# MIIFqQYJKoZIhvcNAQcCoIIFmjCCBZYCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUtSSYX6Xe7Nc91pLBi8VIKJMJ
# 3aqgggMwMIIDLDCCAhSgAwIBAgIQdR0W2SKoK5VE8JId4ZxrRTANBgkqhkiG9w0B
# AQsFADAuMSwwKgYDVQQDDCNVbml0eS1DbGF1ZGUtQXV0b21hdGlvbi1EZXZlbG9w
# bWVudDAeFw0yNTA4MjAyMTE1MTdaFw0yNjA4MjAyMTM1MTdaMC4xLDAqBgNVBAMM
# I1VuaXR5LUNsYXVkZS1BdXRvbWF0aW9uLURldmVsb3BtZW50MIIBIjANBgkqhkiG
# 9w0BAQEFAAOCAQ8AMIIBCgKCAQEAseH3qinVEOhrn2OLpjc5TNT4vGh1BkfB5X4S
# FhY7K0QMQsYYnkZVmx3tB8PqVQXl++l+e3uT7uCscc7vjMTK8tDSWH98ji0U34WL
# JBwXC62l1ArazMKp4Tyr7peksei7vL4pZOtOVgAyTYn5d1hbnsVQmCSTPRtpn7mC
# Azfq2ec5qZ9Kgl7puPW5utvYfh8idtOWa5/WgYSKwOIvyZawIdZKLFpwqOtqbJe4
# sWzVahasFhLfoAKkniKOAocJDkJexh5pO/EOSKEZ3mOCU1ZSs4XWRGISRhV3qGZp
# f+Y3JlHKMeFDWKynaJBO8/GU5sqMATlDUvrByBtU2OQ2Um/L3QIDAQABo0YwRDAO
# BgNVHQ8BAf8EBAMCB4AwEwYDVR0lBAwwCgYIKwYBBQUHAwMwHQYDVR0OBBYEFHw5
# rOy6xlW6B45sJUsiI2A/yS0MMA0GCSqGSIb3DQEBCwUAA4IBAQAUTLH0+w8ysvmh
# YuBw4NDKcZm40MTh9Zc1M2p2hAkYsgNLJ+/rAP+I74rNfqguTYwxpCyjkwrg8yF5
# wViwggboLpF2yDu4N/dgDainR4wR8NVpS7zFZOFkpmNPepc6bw3d4yQKa/wJXKeC
# pkRjS50N77/hfVI+fFKNao7POb7en5fcXuZaN6xWoTRy+J4I4MhfHpjZuxSLSXjb
# VXtPD4RZ9HGjl9BU8162cRhjujr/Lc3/dY/6ikHQYnxuxcdxRew4nzaqAQaOeWu6
# tGp899JPKfldM5Zay5IBl3zs15gNS9+0Jrd0ARQnSVYoI0DLh3KybFnfK4POezoN
# Lp/dbX2SMYIB4zCCAd8CAQEwQjAuMSwwKgYDVQQDDCNVbml0eS1DbGF1ZGUtQXV0
# b21hdGlvbi1EZXZlbG9wbWVudAIQdR0W2SKoK5VE8JId4ZxrRTAJBgUrDgMCGgUA
# oHgwGAYKKwYBBAGCNwIBDDEKMAigAoAAoQKAADAZBgkqhkiG9w0BCQMxDAYKKwYB
# BAGCNwIBBDAcBgorBgEEAYI3AgELMQ4wDAYKKwYBBAGCNwIBFTAjBgkqhkiG9w0B
# CQQxFgQUZtyjJ7bv4ulreGZXBgn2UxE3VRQwDQYJKoZIhvcNAQEBBQAEggEArTpS
# 0VhfEKnLkNquUwkYVSF5v4ABVH8yDBWbL+8G1ZLfBkYeXKtC9zJkfhnkgPApUngf
# qKJJq5CxVgn6952ukB8QG8cE1RNYSNWveQmBwM32SgzWkCg5YIoPOY0rrkXNTAUw
# UYDEz7E+izXa0ZaiVvwC+wmsKDyMdC4+VaN0XAEC8s/VqWCv1+LlOB2H+hix7I4S
# EWXvsMsgWtJV2Vr9whlla+4QvheakwS1plfn5sCNTngwugQiYO1sT9AQJXftlrEz
# L121rU3+S1xABU+/w85kM8UZ6qa/ngirlcmebE4mzMnwtzCaqcp2cTcKKFfEwyYh
# DuFlC1wjNX5+jPiIjQ==
# SIG # End signature block
