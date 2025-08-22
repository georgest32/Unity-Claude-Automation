# Debug-ConcurrentCollections.ps1
# Simple test to debug the ConcurrentCollections issue
# Date: 2025-08-20

$ErrorActionPreference = "Continue"
Set-Location "C:\UnityProjects\Sound-and-Shoal\Unity-Claude-Automation"

Write-Host "=== Debug ConcurrentCollections ===" -ForegroundColor Cyan
Write-Host "PowerShell Version: $($PSVersionTable.PSVersion)"

# Test 1: Direct construction
Write-Host "`nTest 1: Direct Construction" -ForegroundColor Yellow
try {
    $directQueue = [System.Collections.Concurrent.ConcurrentQueue[object]]::new()
    Write-Host "  Direct ConcurrentQueue: $($directQueue -ne $null)" -ForegroundColor $(if ($directQueue) { "Green" } else { "Red" })
    Write-Host "  Type: $($directQueue.GetType().FullName)"
    
    $directBag = [System.Collections.Concurrent.ConcurrentBag[object]]::new()
    Write-Host "  Direct ConcurrentBag: $($directBag -ne $null)" -ForegroundColor $(if ($directBag) { "Green" } else { "Red" })
    Write-Host "  Type: $($directBag.GetType().FullName)"
} catch {
    Write-Host "  Direct construction failed: $($_.Exception.Message)" -ForegroundColor Red
}

# Test 2: Module function calls
Write-Host "`nTest 2: Module Functions" -ForegroundColor Yellow
try {
    # Remove module if already loaded to avoid scope issues
    Remove-Module Unity-Claude-ConcurrentCollections -ErrorAction SilentlyContinue
    Import-Module ".\Modules\Unity-Claude-ParallelProcessing\Unity-Claude-ConcurrentCollections.psd1" -Force -Verbose
    
    Write-Host "  Calling New-ConcurrentQueue..."
    $moduleQueue = New-ConcurrentQueue -Verbose
    Write-Host "  Module ConcurrentQueue: $($moduleQueue -ne $null)" -ForegroundColor $(if ($moduleQueue) { "Green" } else { "Red" })
    Write-Host "  Return value: '$moduleQueue'"
    $queueType = if ($moduleQueue) { $moduleQueue.GetType().FullName } else { "null" }
    Write-Host "  Type: $queueType"
    
    Write-Host "  Calling New-ConcurrentBag..."
    $moduleBag = New-ConcurrentBag -Verbose
    Write-Host "  Module ConcurrentBag: $($moduleBag -ne $null)" -ForegroundColor $(if ($moduleBag) { "Green" } else { "Red" })
    Write-Host "  Return value: '$moduleBag'"
    $bagType = if ($moduleBag) { $moduleBag.GetType().FullName } else { "null" }
    Write-Host "  Type: $bagType"
    
} catch {
    Write-Host "  Module function failed: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host "`n=== Debug Complete ===" -ForegroundColor Cyan

Write-Host "Debugging ConcurrentCollections module..." -ForegroundColor Cyan

# Test .NET type availability first
Write-Host "Testing .NET Framework concurrent types..." -ForegroundColor Yellow
try {
    Add-Type -AssemblyName "System.Collections.Concurrent"
    Write-Host "  System.Collections.Concurrent assembly: LOADED" -ForegroundColor Green
    
    # Test direct instantiation
    $testQueue = New-Object 'System.Collections.Concurrent.ConcurrentQueue[object]'
    if ($testQueue) {
        Write-Host "  Direct ConcurrentQueue creation: PASS" -ForegroundColor Green
        Write-Host "  Type: $($testQueue.GetType().FullName)" -ForegroundColor Gray
    } else {
        Write-Host "  Direct ConcurrentQueue creation: FAIL" -ForegroundColor Red
    }
    
    $testBag = New-Object 'System.Collections.Concurrent.ConcurrentBag[object]'
    if ($testBag) {
        Write-Host "  Direct ConcurrentBag creation: PASS" -ForegroundColor Green
        Write-Host "  Type: $($testBag.GetType().FullName)" -ForegroundColor Gray
    } else {
        Write-Host "  Direct ConcurrentBag creation: FAIL" -ForegroundColor Red
    }
    
} catch {
    Write-Host "  .NET type loading error: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host ""
Write-Host "Testing module functions..." -ForegroundColor Yellow

# Load module
Import-Module .\Modules\Unity-Claude-ParallelProcessing\Unity-Claude-ConcurrentCollections.psd1 -Force

# Test functions
try {
    Write-Host "  Testing New-ConcurrentQueue..." -ForegroundColor Gray
    $queue = New-ConcurrentQueue
    Write-Host "  Queue variable type: $(if ($queue) { $queue.GetType().FullName } else { 'null' })" -ForegroundColor Gray
    Write-Host "  Queue is null: $($queue -eq $null)" -ForegroundColor Gray
    Write-Host "  Queue object: $($queue -as [string])" -ForegroundColor Gray
    
    if ($queue -and $queue.GetType().Name -like "*ConcurrentQueue*") {
        Write-Host "  New-ConcurrentQueue: PASS" -ForegroundColor Green
        
        # Test basic operations
        try {
            $queue.Enqueue("test")
            $item = $null
            $result = $queue.TryDequeue([ref]$item)
            if ($result -and $item -eq "test") {
                Write-Host "  Queue operations: PASS" -ForegroundColor Green
            } else {
                Write-Host "  Queue operations: FAIL" -ForegroundColor Red
            }
        } catch {
            Write-Host "  Queue operations error: $($_.Exception.Message)" -ForegroundColor Red
        }
    } else {
        Write-Host "  New-ConcurrentQueue: FAIL (returned null or wrong type)" -ForegroundColor Red
    }
} catch {
    Write-Host "  New-ConcurrentQueue error: $($_.Exception.Message)" -ForegroundColor Red
}

try {
    Write-Host "  Testing New-ConcurrentBag..." -ForegroundColor Gray
    $bag = New-ConcurrentBag
    Write-Host "  Bag variable type: $(if ($bag) { $bag.GetType().FullName } else { 'null' })" -ForegroundColor Gray
    Write-Host "  Bag is null: $($bag -eq $null)" -ForegroundColor Gray
    
    if ($bag -and $bag.GetType().Name -like "*ConcurrentBag*") {
        Write-Host "  New-ConcurrentBag: PASS" -ForegroundColor Green
        
        # Test basic operations
        try {
            $bag.Add("test")
            $item = $null
            $result = $bag.TryTake([ref]$item)
            if ($result -and $item -eq "test") {
                Write-Host "  Bag operations: PASS" -ForegroundColor Green
            } else {
                Write-Host "  Bag operations: FAIL" -ForegroundColor Red
            }
        } catch {
            Write-Host "  Bag operations error: $($_.Exception.Message)" -ForegroundColor Red
        }
    } else {
        Write-Host "  New-ConcurrentBag: FAIL (returned null or wrong type)" -ForegroundColor Red
    }
} catch {
    Write-Host "  New-ConcurrentBag error: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host ""
Write-Host "Debug complete!" -ForegroundColor Cyan
# SIG # Begin signature block
# MIIFqQYJKoZIhvcNAQcCoIIFmjCCBZYCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQU2/nY3x+zfCmK1qI1I/2KSm3R
# AsegggMwMIIDLDCCAhSgAwIBAgIQdR0W2SKoK5VE8JId4ZxrRTANBgkqhkiG9w0B
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
# CQQxFgQUWMJEC9Wwd1/1RtHuMgxkmPj5dY8wDQYJKoZIhvcNAQEBBQAEggEAK7o+
# a5PbKNVFNw+d/Lv5GXygI3g50fxh7RNd236/Py05PjaJrGo81QXkvkuh9ro6X5RV
# F5eKQcqDkRHMucIUnvEn5DRN0xBFmuHwGiby1iI6ElUJQxqn7q77bo1+PIwMl2cA
# nfnJVCNIjUxlDJt/eNk326bmaX3sqI/o0n29S71O1e03luPjhdGhLn0qHpyp+0ZU
# MRSWjBp3XU6dWQhAEQInhCf7kvsWVtQmvS8tffwwXDqBLlSYO468RA/AevOZTREN
# 4M/4L6mQQcOiL6P9gSwsNpmAhhisZCnhSM0cUDiiQOI6Bc69NO435sZZndFp/gEy
# nWEaVihj7NA3BKA4HA==
# SIG # End signature block
