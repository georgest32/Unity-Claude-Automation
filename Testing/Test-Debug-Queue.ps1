# Test-Debug-Queue.ps1
# Debug script for queue issue

# Add module path
$modulePath = Join-Path (Split-Path $PSScriptRoot) 'Modules'
if ($env:PSModulePath -notlike "*$modulePath*") {
    $env:PSModulePath = "$modulePath;$env:PSModulePath"
}

Write-Host "Debug Queue Test" -ForegroundColor Cyan
Write-Host "Module Path: $modulePath" -ForegroundColor Yellow

# Import with verbose
try {
    Import-Module Unity-Claude-IPC-Bidirectional -Force -Verbose
    Write-Host "Module imported successfully" -ForegroundColor Green
} catch {
    Write-Host "Module import failed: $_" -ForegroundColor Red
    exit 1
}

# Test direct queue creation
Write-Host "`nTesting direct queue creation..." -ForegroundColor Cyan
try {
    $testQueue = [System.Collections.Concurrent.ConcurrentQueue[PSObject]]::new()
    Write-Host "Direct queue creation: OK" -ForegroundColor Green
    
    # Test enqueue
    $testObj = [PSCustomObject]@{ Test = "Value" }
    $testQueue.Enqueue($testObj)
    Write-Host "Direct enqueue: OK" -ForegroundColor Green
    
    # Test dequeue
    $result = $null
    $success = $testQueue.TryDequeue([ref]$result)
    if ($success -and $result.Test -eq "Value") {
        Write-Host "Direct dequeue: OK" -ForegroundColor Green
    } else {
        Write-Host "Direct dequeue: FAILED" -ForegroundColor Red
    }
} catch {
    Write-Host "Direct queue test failed: $_" -ForegroundColor Red
}

# Test module functions
Write-Host "`nTesting module functions..." -ForegroundColor Cyan
try {
    # Initialize
    $queues = Initialize-MessageQueues -Verbose
    Write-Host "Initialize-MessageQueues returned: $($queues.GetType().Name)" -ForegroundColor Yellow
    
    if ($null -eq $queues) {
        Write-Host "Queues is null!" -ForegroundColor Red
    } elseif ($null -eq $queues.MessageQueue) {
        Write-Host "MessageQueue is null!" -ForegroundColor Red
    } else {
        Write-Host "MessageQueue type: $($queues.MessageQueue.GetType().FullName)" -ForegroundColor Yellow
    }
    
    # Try to add message directly through the function
    Write-Host "`nTrying Add-MessageToQueue..." -ForegroundColor Cyan
    $testMsg = [PSCustomObject]@{
        Type = "Test"
        Data = "Test data"
    }
    
    Add-MessageToQueue -Message $testMsg -Verbose
    Write-Host "Add-MessageToQueue completed" -ForegroundColor Green
    
    # Get status
    Write-Host "`nGetting queue status..." -ForegroundColor Cyan
    $status = Get-QueueStatus -Verbose
    Write-Host "Status: $($status | ConvertTo-Json -Compress)" -ForegroundColor Yellow
    
} catch {
    Write-Host "Module function test failed: $_" -ForegroundColor Red
    Write-Host "Exception type: $($_.Exception.GetType().FullName)" -ForegroundColor Yellow
    Write-Host "Stack trace: $($_.ScriptStackTrace)" -ForegroundColor Gray
}
# SIG # Begin signature block
# MIIFqQYJKoZIhvcNAQcCoIIFmjCCBZYCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQU0NktQn55+h2STt9LdhkSdVw8
# v26gggMwMIIDLDCCAhSgAwIBAgIQdR0W2SKoK5VE8JId4ZxrRTANBgkqhkiG9w0B
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
# CQQxFgQUJA7gUATE8FVfFyaGBd1zvlwFBqcwDQYJKoZIhvcNAQEBBQAEggEAdArE
# PMKR+5Lk441tjkEedU5QzzHCmeUmvDTmAqxmVBaMEtduAFaP9CJcL0u4ec1dAUFn
# 8bgU63/a8rMZyrfDjnVu4BXFFkjvppA3cr65L4z401OmYzz4jBpH6MIJ4VpJiHTo
# azYoHNlT8b0qMtCpFts96c3loDLaY/51vU9SK7A7X+bTOcbAlfYNXR+MKUTRxBUZ
# 8yGWO0+Kk86p2SUP41YipoS45GIRyHHhIbg6WRN8bRC12c2HIs7bxO3jXUj2dBuN
# VydoNabJ3H4DYIWXrC3hGU/vVJI9ImlGGPICD51+82k7Jp+hE6071RAUTF976xPr
# daziFLAFnf2HET0EHA==
# SIG # End signature block
