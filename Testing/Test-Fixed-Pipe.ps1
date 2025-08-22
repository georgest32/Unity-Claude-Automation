# Test-Fixed-Pipe.ps1
# Quick test of fixed pipe implementation

# Add module path
$modulePath = Join-Path (Split-Path $PSScriptRoot) 'Modules'
if ($env:PSModulePath -notlike "*$modulePath*") {
    $env:PSModulePath = "$modulePath;$env:PSModulePath"
}

Write-Host "Testing Fixed Named Pipe Implementation" -ForegroundColor Cyan

# Import module
Import-Module Unity-Claude-IPC-Bidirectional -Force

Write-Host "`n1. Starting async pipe server..." -ForegroundColor Yellow
$result = Start-NamedPipeServer -PipeName "TestFixed" -Async

if ($result.Success) {
    Write-Host "  Server started successfully (Job ID: $($result.JobId))" -ForegroundColor Green
    
    # Give server time to start
    Start-Sleep -Seconds 1
    
    Write-Host "`n2. Sending test message..." -ForegroundColor Yellow
    $msg = Send-PipeMessage -PipeName "TestFixed" -Message "PING:Test"
    
    if ($msg.Success) {
        Write-Host "  Response received: $($msg.Response)" -ForegroundColor Green
        Write-Host "`n  TEST PASSED!" -ForegroundColor Green
    } else {
        Write-Host "  Send failed: $($msg.Error)" -ForegroundColor Red
    }
    
    # Check job status
    $job = Get-Job -Id $result.JobId -ErrorAction SilentlyContinue
    if ($job) {
        Write-Host "`n3. Job Status: $($job.State)" -ForegroundColor Cyan
        
        # Get any output
        $output = Receive-Job -Id $result.JobId -ErrorAction SilentlyContinue
        if ($output) {
            Write-Host "  Job output:" -ForegroundColor Yellow
            $output | ForEach-Object { Write-Host "    $_" -ForegroundColor Gray }
        }
        
        # Cleanup
        Stop-Job -Id $result.JobId -ErrorAction SilentlyContinue
        Remove-Job -Id $result.JobId -ErrorAction SilentlyContinue
    }
} else {
    Write-Host "  Failed to start server: $($result.Error)" -ForegroundColor Red
}

Write-Host "`nCleanup complete" -ForegroundColor Cyan
# SIG # Begin signature block
# MIIFqQYJKoZIhvcNAQcCoIIFmjCCBZYCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUFFPcJOmnGwLL032zY5QzH233
# 4NSgggMwMIIDLDCCAhSgAwIBAgIQdR0W2SKoK5VE8JId4ZxrRTANBgkqhkiG9w0B
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
# CQQxFgQUk9sb/oA+bLRIUXRx0EQ/oteSz2owDQYJKoZIhvcNAQEBBQAEggEAkulm
# XF9dDBRDmMouKTY1goFLfn8ZOLvqjwQV7qD3SqFu0QgfIr8gthGTkOaXWMhvbyS8
# iRrtYRF5KxYhWYtBXI/4aswL6UMWzqPGdClxQtepf4pzaYuH2bixyS8NUeO/rdwT
# ZBnK7y0yvzJ0k79B6W+5tv/nLty5MToyMIlUd2y2wKIkj+LEs9jCO8/qCIqAFGfR
# 0OvaKfeWDWvE3ydjlJn7yv7AXhlK0t9KJ9A4KS08nzmG7Ngahg8AyJjb64J/kdWU
# 8aHyM+Zdg+SynlyNlLTZ1ksF7XeJG3/roJ4fPKGah11tz5kaY+oRVFrCiwzsT3R/
# OWKw8PgrcKABX+F8nA==
# SIG # End signature block
