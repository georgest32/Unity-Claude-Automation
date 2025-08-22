# Debug-ConcurrentQueue.ps1
# Simple test to debug ConcurrentQueue creation issue

Write-Host "=== ConcurrentQueue Debug Test ===" -ForegroundColor Cyan

# Test 1: Direct New-Object call
Write-Host "`nTest 1: Direct New-Object creation" -ForegroundColor Yellow
try {
    $directQueue = New-Object 'System.Collections.Concurrent.ConcurrentQueue[object]'
    Write-Host "  Direct creation: SUCCESS" -ForegroundColor Green
    Write-Host "  Type: $($directQueue.GetType().FullName)" -ForegroundColor Gray
    Write-Host "  Is null: $($null -eq $directQueue)" -ForegroundColor Gray
} catch {
    Write-Host "  Direct creation FAILED: $($_.Exception.Message)" -ForegroundColor Red
}

# Test 2: Module function call
Write-Host "`nTest 2: Module function creation" -ForegroundColor Yellow
try {
    Import-Module ".\Modules\Unity-Claude-ParallelProcessing\Unity-Claude-ConcurrentCollections.psd1" -Force
    Write-Host "  Module imported successfully" -ForegroundColor Green
    
    $moduleQueue = New-ConcurrentQueue
    Write-Host "  Module creation result: $moduleQueue" -ForegroundColor Gray
    Write-Host "  Is null: $($null -eq $moduleQueue)" -ForegroundColor Gray
    
    if ($moduleQueue) {
        Write-Host "  Type: $($moduleQueue.GetType().FullName)" -ForegroundColor Gray
        Write-Host "  Module creation: SUCCESS" -ForegroundColor Green
    } else {
        Write-Host "  Module creation: FAILED (returned null)" -ForegroundColor Red
    }
} catch {
    Write-Host "  Module creation FAILED: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "  Stack trace: $($_.ScriptStackTrace)" -ForegroundColor Red
}

# Test 3: ::new() syntax for comparison
Write-Host "`nTest 3: ::new() syntax (for comparison)" -ForegroundColor Yellow
try {
    $newQueue = [System.Collections.Concurrent.ConcurrentQueue[object]]::new()
    Write-Host "  ::new() creation: SUCCESS" -ForegroundColor Green
    Write-Host "  Type: $($newQueue.GetType().FullName)" -ForegroundColor Gray
    Write-Host "  Is null: $($null -eq $newQueue)" -ForegroundColor Gray
} catch {
    Write-Host "  ::new() creation FAILED: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host "`n=== End Debug Test ===" -ForegroundColor Cyan
# SIG # Begin signature block
# MIIFqQYJKoZIhvcNAQcCoIIFmjCCBZYCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUrNJSVEjh3Wexcy+Q/eQv/U2W
# 2D+gggMwMIIDLDCCAhSgAwIBAgIQdR0W2SKoK5VE8JId4ZxrRTANBgkqhkiG9w0B
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
# CQQxFgQUP19S0HDaSIByzAofQeOmWaFo6iQwDQYJKoZIhvcNAQEBBQAEggEAadKu
# 8iZnvKS61b1b5ekTDv4oZF7PCBtbxl5cjNJqzOgz3r9xU9kHhwtlK0xveH7e6F6c
# wUfQY3YoYv5A7alIf+awhzzktDTzBCvg60FyAzjtbramocgYlsCVCqtF7UenhCLJ
# HHPxUZO7J4yF1ZGO66IQnKg2u5ZPTkW/K2ymdGCKfo8HtaSzlxU+bHUNo9Iu8K7x
# R1FRABZSzZoI9A3ieaDUKRrf0isBT4s02lFlEN3hoFP6qOwjtSV8r5YcW6kY9vQ4
# X8CV96C2k6wxfXbN9roO60eJDrHuK9+jYrmb5qaAQowGkYz8M3+0Iuy8Z+K8dkzy
# NsLBnhbqM4Ab8JJZYA==
# SIG # End signature block
