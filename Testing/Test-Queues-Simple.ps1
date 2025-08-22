# Test-Queues-Simple.ps1
# Simple test for queue management

# Add module path
$modulePath = Join-Path (Split-Path $PSScriptRoot) 'Modules'
if ($env:PSModulePath -notlike "*$modulePath*") {
    $env:PSModulePath = "$modulePath;$env:PSModulePath"
}

Write-Host "Testing Queue Management..." -ForegroundColor Cyan

try {
    # Import module
    Import-Module Unity-Claude-IPC-Bidirectional -Force -ErrorAction Stop
    Write-Host "[OK] Module loaded" -ForegroundColor Green
    
    # Initialize queues
    $queues = Initialize-MessageQueues
    if ($queues.MessageQueue -and $queues.ResponseQueue) {
        Write-Host "[OK] Queues initialized" -ForegroundColor Green
    } else {
        Write-Host "[FAIL] Queue initialization failed" -ForegroundColor Red
        exit 1
    }
    
    # Add message
    $testMessage = @{
        Type = "Test"
        Data = "Test message"
        Timestamp = Get-Date
    }
    
    Add-MessageToQueue -Message $testMessage
    Write-Host "[OK] Message added to queue" -ForegroundColor Green
    
    # Get status
    $status = Get-QueueStatus
    if ($status.MessageQueue.Count -gt 0) {
        Write-Host "[OK] Queue has messages: $($status.MessageQueue.Count)" -ForegroundColor Green
    } else {
        Write-Host "[FAIL] Queue is empty" -ForegroundColor Red
        exit 1
    }
    
    # Get message
    $retrieved = Get-NextMessage -QueueType Message
    if ($retrieved -and $retrieved.Type -eq "Test") {
        Write-Host "[OK] Message retrieved successfully" -ForegroundColor Green
    } else {
        Write-Host "[FAIL] Failed to retrieve message" -ForegroundColor Red
        exit 1
    }
    
    # Clear queue
    Clear-MessageQueue -QueueType All
    $status = Get-QueueStatus
    if ($status.MessageQueue.Count -eq 0) {
        Write-Host "[OK] Queue cleared" -ForegroundColor Green
    } else {
        Write-Host "[FAIL] Queue not cleared" -ForegroundColor Red
        exit 1
    }
    
    Write-Host ""
    Write-Host "All queue tests passed!" -ForegroundColor Green
    exit 0
    
} catch {
    Write-Host "[ERROR] $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}
# SIG # Begin signature block
# MIIFqQYJKoZIhvcNAQcCoIIFmjCCBZYCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQU5neKyZOQ5epBruybJBC/Bgi8
# UVigggMwMIIDLDCCAhSgAwIBAgIQdR0W2SKoK5VE8JId4ZxrRTANBgkqhkiG9w0B
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
# CQQxFgQUqmj0VWWTNkKMwT6FdYBPhl1SoyIwDQYJKoZIhvcNAQEBBQAEggEAr4FX
# 1w28zmz3Px8tCUN9g9bDrENd431ETuZVP6fwodQ7xuB+RCugIOhYgzRHVW3xuufo
# PDPcE5bmqVIYMN5rRU24bRtS7MdWpAuxC63/1dbtWKoARo3SPfM1CQABc56XMfqK
# //wjdUX7YcjC2gAvj+01a9340wONcJxweSI6Kl5jNFHwVYdnUYBQExl0IQjizBXL
# OLwqlcCUhbJFmJgaByxKo+0B4n5gc+OWxpO2GEcNqQj7htaGCuEf2XoVuGaDVfqM
# /acSy/AWhamL0ydjoHhsr0+Cooy7yUUZXBdNLiXBYOAdR4jZV2vWqyL3XoIM/hqE
# XT60Fp0rVbmyv7wWaQ==
# SIG # End signature block
