# Test-Wrapper-Functions.ps1
# Test the wrapper functions specifically

Write-Host "=== Wrapper Functions Test ===" -ForegroundColor Cyan

try {
    # Import module
    Import-Module ".\Modules\Unity-Claude-ParallelProcessing\Unity-Claude-ConcurrentCollections.psd1" -Force
    Write-Host "Module imported successfully" -ForegroundColor Green
    
    # Test queue creation
    Write-Host "`nTest 1: Queue Creation" -ForegroundColor Yellow
    $queue = New-ConcurrentQueue
    if ($queue) {
        Write-Host "  Queue creation: SUCCESS" -ForegroundColor Green
        Write-Host "  Queue type: $($queue.Type)" -ForegroundColor Gray
        Write-Host "  Queue created: $($queue.Created)" -ForegroundColor Gray
    } else {
        Write-Host "  Queue creation: FAILED" -ForegroundColor Red
    }
    
    # Test empty check
    Write-Host "`nTest 2: Empty Check" -ForegroundColor Yellow
    $isEmpty = Test-ConcurrentQueueEmpty -Queue $queue
    Write-Host "  Empty check result: $isEmpty" -ForegroundColor Gray
    if ($isEmpty -eq $true) {
        Write-Host "  Empty check: SUCCESS" -ForegroundColor Green
    } else {
        Write-Host "  Empty check: FAILED" -ForegroundColor Red
    }
    
    # Test count
    Write-Host "`nTest 3: Count Check" -ForegroundColor Yellow
    $count = Get-ConcurrentQueueCount -Queue $queue
    Write-Host "  Count result: $count" -ForegroundColor Gray
    if ($count -eq 0) {
        Write-Host "  Count check: SUCCESS" -ForegroundColor Green
    } else {
        Write-Host "  Count check: FAILED (expected 0, got $count)" -ForegroundColor Red
    }
    
    # Test add item
    Write-Host "`nTest 4: Add Item" -ForegroundColor Yellow
    $addResult = Add-ConcurrentQueueItem -Queue $queue -Item "Test Item"
    Write-Host "  Add result: $addResult" -ForegroundColor Gray
    if ($addResult) {
        Write-Host "  Add item: SUCCESS" -ForegroundColor Green
    } else {
        Write-Host "  Add item: FAILED" -ForegroundColor Red
    }
    
    # Test count after add
    Write-Host "`nTest 5: Count After Add" -ForegroundColor Yellow
    $newCount = Get-ConcurrentQueueCount -Queue $queue
    Write-Host "  New count: $newCount" -ForegroundColor Gray
    if ($newCount -eq 1) {
        Write-Host "  Count after add: SUCCESS" -ForegroundColor Green
    } else {
        Write-Host "  Count after add: FAILED (expected 1, got $newCount)" -ForegroundColor Red
    }
    
    # Test get item
    Write-Host "`nTest 6: Get Item" -ForegroundColor Yellow
    $item = Get-ConcurrentQueueItem -Queue $queue
    Write-Host "  Retrieved item: '$item'" -ForegroundColor Gray
    if ($item -eq "Test Item") {
        Write-Host "  Get item: SUCCESS" -ForegroundColor Green
    } else {
        Write-Host "  Get item: FAILED (expected 'Test Item', got '$item')" -ForegroundColor Red
    }
    
} catch {
    Write-Host "ERROR: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host "`n=== End Wrapper Test ===" -ForegroundColor Cyan
# SIG # Begin signature block
# MIIFqQYJKoZIhvcNAQcCoIIFmjCCBZYCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUazWt8m0+67XrXRDxVyEPhNOC
# LVSgggMwMIIDLDCCAhSgAwIBAgIQdR0W2SKoK5VE8JId4ZxrRTANBgkqhkiG9w0B
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
# CQQxFgQUb6uZex4NpM6Pai7MXedd15agk60wDQYJKoZIhvcNAQEBBQAEggEAK2+L
# 0n4IpObpBfky5UDIQTjCe5iprsGKSahoTWkg2vsZ51MMgnMeUvlIgGTezyCMkWLs
# 13pwzgiMVL2EZIrOduhps78J0BG+JjnE/XX4uggdcqDURHmvrIYvGsaP4fDPUITl
# jbJCDvFMKjccDL/E5lQA80dxAOdJc0aZcA4XottBeu6wdXeXx6+0PteEwm3XwrSl
# OQzTE+qeO+MAhXeIvibQOZl7u5vdpXCWUw5xQlcInzwFNryylXT4joc34ef7Yeg6
# J4o4vpRP71CI8Z8AsiV/lyhnvsdam6R8VfKjApDbkm7hR7WHR6RxYcBiM9VUoztD
# CyWhOYChubOM4KlcaQ==
# SIG # End signature block
