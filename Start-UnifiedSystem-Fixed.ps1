# Start-UnifiedSystem-Fixed.ps1
# Fixed version - starts SystemStatusMonitoring in separate window

# PowerShell 7 Self-Elevation

param([switch])

if ($PSVersionTable.PSVersion.Major -lt 7) {
    $pwsh7 = "C:\Program Files\PowerShell\7\pwsh.exe"
    if (Test-Path $pwsh7) {
        Write-Host "Upgrading to PowerShell 7..." -ForegroundColor Yellow
        $arguments = @("-NoProfile", "-ExecutionPolicy", "Bypass", "-File", $MyInvocation.MyCommand.Path) + $args
        Start-Process -FilePath $pwsh7 -ArgumentList $arguments -NoNewWindow -Wait
        exit
    } else {
        Write-Warning "PowerShell 7 not found. Running in PowerShell $($PSVersionTable.PSVersion)"
    }
}

Clear-Host
Write-Host '==================================================' -ForegroundColor Cyan
Write-Host 'Unity-Claude Unified System Startup (Fixed)' -ForegroundColor Yellow
Write-Host '==================================================' -ForegroundColor Cyan

) { 

# Step 1: Load SystemStatus module
Write-Host 'Loading SystemStatus module...' -ForegroundColor Yellow
 'Modules\Unity-Claude-SystemStatus\Unity-Claude-SystemStatus-Complete.psm1'
if (Test-Path  -Force -Global
    Initialize-SystemStatusMonitoring
    Write-Host '  Module loaded and initialized' -ForegroundColor Green
}

# Step 2: Start monitoring in new window
Write-Host 'Starting SystemStatusMonitoring...' -ForegroundColor Yellow
 'Start-SystemStatusMonitoring-Persistent.ps1'
if (Test-Path  -WorkingDirectory  = Join-Path ) {
    Start-Sleep -Seconds 2
    Start-Process pwsh -ArgumentList '-NoExit', '-ExecutionPolicy', 'Bypass', '-File', 
    Write-Host '  Started in new window' -ForegroundColor Green
}

Write-Host ''
Write-Host 'All systems launched!' -ForegroundColor Green

# SIG # Begin signature block
# MIIFqQYJKoZIhvcNAQcCoIIFmjCCBZYCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQU8DPbns4JztcA0Na7dENFwuzp
# KmmgggMwMIIDLDCCAhSgAwIBAgIQdR0W2SKoK5VE8JId4ZxrRTANBgkqhkiG9w0B
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
# CQQxFgQUJmOJ6gckpehC/q9HBoVra73Jo4swDQYJKoZIhvcNAQEBBQAEggEAS+5R
# y2MLjOBXRp1qTzP+tdpKT0I6UCWXtlvzDv8hsVzKxiwJmu4lq3TRSUl4oL59Nhte
# b5luCbOFuCJBSHxzhKchfbSjjQezsSBWsiovIsFsHRZeMD7dVFkmYiTHGYRpRm5J
# zLalzKnT1/FMCmYrI0cWfD7rUmYIMBY2JC9aT4YRue4wc5u5lRrqv5SonzgOtvUn
# /zz4x0BAAkAnrvdXTgdQY+vcYOmtHEaJhRq3zGgNElkNasKc9lNgyfEUM0SMQCtI
# MLGqPxERBUNkI8lyvC/WNm1Wd58WIxlrQJLpLRsFFlBJVZkP6PDLq1JXCzy9yZWK
# IeNxd7O5ZWZuaVpnMw==
# SIG # End signature block



