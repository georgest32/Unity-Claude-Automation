# Test-ConcurrentCollections-Simple.ps1
# Simple test after fixing module-scope execution issue

$ErrorActionPreference = "Continue"
Set-Location "C:\UnityProjects\Sound-and-Shoal\Unity-Claude-Automation"

Write-Host "=== Testing Fixed ConcurrentCollections ===" -ForegroundColor Cyan

try {
    # Clean module load
    Remove-Module Unity-Claude-ConcurrentCollections -ErrorAction SilentlyContinue
    Import-Module ".\Modules\Unity-Claude-ParallelProcessing\Unity-Claude-ConcurrentCollections.psd1" -Force
    
    # Test ConcurrentQueue
    Write-Host "`nTesting ConcurrentQueue..." -ForegroundColor Yellow
    $queue = New-ConcurrentQueue
    Write-Host "Queue created: $($queue -ne $null)" -ForegroundColor $(if ($queue) { "Green" } else { "Red" })
    
    if ($queue) {
        Write-Host "Type: $($queue.GetType().FullName)" -ForegroundColor Gray
        
        # Test basic operations
        $addResult = Add-ConcurrentQueueItem -Queue $queue -Item "Test Item 1"
        Write-Host "Add item: $addResult" -ForegroundColor $(if ($addResult) { "Green" } else { "Red" })
        
        $count = Get-ConcurrentQueueCount -Queue $queue
        Write-Host "Queue count: $count" -ForegroundColor Gray
        
        $item = Get-ConcurrentQueueItem -Queue $queue
        Write-Host "Retrieved item: '$item'" -ForegroundColor Gray
    }
    
    # Test ConcurrentBag
    Write-Host "`nTesting ConcurrentBag..." -ForegroundColor Yellow
    $bag = New-ConcurrentBag
    Write-Host "Bag created: $($bag -ne $null)" -ForegroundColor $(if ($bag) { "Green" } else { "Red" })
    
    if ($bag) {
        Write-Host "Type: $($bag.GetType().FullName)" -ForegroundColor Gray
        
        # Test basic operations
        $addResult = Add-ConcurrentBagItem -Bag $bag -Item "Test Item 1"
        Write-Host "Add item: $addResult" -ForegroundColor $(if ($addResult) { "Green" } else { "Red" })
        
        $count = Get-ConcurrentBagCount -Bag $bag
        Write-Host "Bag count: $count" -ForegroundColor Gray
        
        $item = Get-ConcurrentBagItem -Bag $bag
        Write-Host "Retrieved item: '$item'" -ForegroundColor Gray
    }
    
    Write-Host "`n=== Test Results ===" -ForegroundColor Cyan
    Write-Host "ConcurrentQueue: $(if ($queue) { 'SUCCESS' } else { 'FAILED' })" -ForegroundColor $(if ($queue) { "Green" } else { "Red" })
    Write-Host "ConcurrentBag: $(if ($bag) { 'SUCCESS' } else { 'FAILED' })" -ForegroundColor $(if ($bag) { "Green" } else { "Red" })
    
} catch {
    Write-Host "Test failed: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "Stack: $($_.ScriptStackTrace)" -ForegroundColor Red
}
# SIG # Begin signature block
# MIIFqQYJKoZIhvcNAQcCoIIFmjCCBZYCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUxAyPb02XY7ph1rlGPJXVgJGe
# K+CgggMwMIIDLDCCAhSgAwIBAgIQdR0W2SKoK5VE8JId4ZxrRTANBgkqhkiG9w0B
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
# CQQxFgQUUtMXJK4WtxWxL1W8CSLLZPrqo28wDQYJKoZIhvcNAQEBBQAEggEAWkRQ
# OzLbxD4NEI/joC/pKzj46HNkstNbAOjFWfgIc5+h6AxBOXGdLD9isT2yMwGvt4p7
# +wO5weMlnt6CXrMY9+femY3LBhEq5O61EcdadIQc+niMjJ8DSbTWOfXBBZOsnEbd
# Wv7/qq75RHouP4/HZDREqiZTkvL05/m9HLDfVjJsvCTBUsuES8C+SQZcx5supc/p
# cuUkpxP2c/i/Yhn5HIec6Fl6AXlZQDLc9z6WLthfGQVZhwLksFjBXDYuEB5bolic
# GjmNfdkS0Jj6H8k9vCr2lQs84VystZe/yM/vI9fnGSuxq1h/CP7oukEBeIuTJ4LF
# xG1PE4QzdCE1x9jIPA==
# SIG # End signature block
