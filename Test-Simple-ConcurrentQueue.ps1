# Test-Simple-ConcurrentQueue.ps1
# Simple standalone test to isolate the ConcurrentQueue issue

$ErrorActionPreference = "Stop"

Write-Host "=== Simple ConcurrentQueue Test ===" -ForegroundColor Cyan

# Test the actual function code directly (not through module)
function Test-ConcurrentQueue-Direct {
    [CmdletBinding()]
    param([int]$InitialCapacity = 16)
    
    try {
        Write-Host "Creating queue directly in function..."
        $queue = [System.Collections.Concurrent.ConcurrentQueue[object]]::new()
        Write-Host "Queue created. Type: $($queue.GetType().FullName)"
        return $queue
    } catch {
        Write-Error "Failed to create queue: $($_.Exception.Message)"
        throw
    }
}

# Test 1: Direct function call
Write-Host "`nTest 1: Direct function call"
$directQueue = Test-ConcurrentQueue-Direct
Write-Host "Result: $($directQueue -ne $null)"
$directType = if ($directQueue) { $directQueue.GetType().FullName } else { "null" }
Write-Host "Type: $directType"

# Test 2: Load and test module function
Write-Host "`nTest 2: Module function test"
try {
    # Load just the .psm1 file directly
    . ".\Modules\Unity-Claude-ParallelProcessing\Unity-Claude-ConcurrentCollections.psm1"
    
    Write-Host "Calling New-ConcurrentQueue function..."
    $moduleQueue = New-ConcurrentQueue
    Write-Host "Result: $($moduleQueue -ne $null)"
    $moduleType = if ($moduleQueue) { $moduleQueue.GetType().FullName } else { "null" }
    Write-Host "Type: $moduleType"
    
} catch {
    Write-Host "Module test failed: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host "`n=== Test Complete ===" -ForegroundColor Cyan
# SIG # Begin signature block
# MIIFqQYJKoZIhvcNAQcCoIIFmjCCBZYCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUI1JdS58LLkvUj78Hq5q4G9Qi
# Ol+gggMwMIIDLDCCAhSgAwIBAgIQdR0W2SKoK5VE8JId4ZxrRTANBgkqhkiG9w0B
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
# CQQxFgQU8A0wjJ+kGSQblfsZ2iTQiIfYzucwDQYJKoZIhvcNAQEBBQAEggEAhr/K
# 5l74j0cF2W3wXAyJszHbP+W75GzORSSV66FY6Ux5bKnN82meRq3yiAGJtDALeJui
# 0fUfA+82dpPiwDBXYlK2zkOxAzNOV9v9bAEjuEOG/+MpbSrQTDM/Fyx+uGVi2e55
# HhSBvJLeDZXQkxxZOAg4e8dmG+DDYdNxiukT9IXnL89Q4+W+7eFQTfyju0G+17IH
# AHaPWA0BqjS6K/JjVjiGO67z2tmintPP8Qdys2tKT9Myiettek/mBmOdhyrM4etT
# Jt1PPW9yjG4PngOCj29dDH622MNOrSg3H7BfUi9g7jljyVavvywhBiysBzDuyJNK
# 8lus/f3rcwKq6V2HKg==
# SIG # End signature block
