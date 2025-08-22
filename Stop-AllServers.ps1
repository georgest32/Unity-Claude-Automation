# Stop-AllServers.ps1
# Cleanup script to stop all test servers and free ports

Write-Host "Stopping all Unity-Claude test servers..." -ForegroundColor Yellow

# Stop all PowerShell jobs
Write-Host "`nStopping background jobs..." -ForegroundColor Cyan
Get-Job | Where-Object { $_.State -eq 'Running' } | ForEach-Object {
    Write-Host "  Stopping job: $($_.Name) (ID: $($_.Id))" -ForegroundColor Gray
    Stop-Job -Id $_.Id
}
Get-Job | Remove-Job -Force -ErrorAction SilentlyContinue

# Try to release HTTP.sys reservations
Write-Host "`nAttempting to release HTTP reservations..." -ForegroundColor Cyan

# Check for reservations on our ports
$ports = @(5556, 5557, 5558)
foreach ($port in $ports) {
    Write-Host "  Checking port $port..." -ForegroundColor Gray
    
    # Try to delete URL reservations (requires admin for global ones)
    $urlAcl = "http://localhost:$port/"
    try {
        # This will fail if not admin, but worth trying
        $result = netsh http delete urlacl url=$urlAcl 2>&1
        if ($LASTEXITCODE -eq 0) {
            Write-Host "    Removed reservation for $urlAcl" -ForegroundColor Green
        }
    } catch {
        # Ignore - probably not admin
    }
    
    # Alternative: try to stop any listeners we might have created
    $urlAcl2 = "http://+:$port/"
    try {
        $result = netsh http delete urlacl url=$urlAcl2 2>&1
        if ($LASTEXITCODE -eq 0) {
            Write-Host "    Removed reservation for $urlAcl2" -ForegroundColor Green
        }
    } catch {
        # Ignore
    }
}

# Clean up module state
Write-Host "`nCleaning up module state..." -ForegroundColor Cyan
if (Get-Module Unity-Claude-IPC-Bidirectional) {
    Remove-Module Unity-Claude-IPC-Bidirectional -Force
    Write-Host "  Module removed" -ForegroundColor Green
}

# Kill any orphaned PowerShell processes that might be holding ports
Write-Host "`nChecking for orphaned PowerShell processes..." -ForegroundColor Cyan
$currentPid = $PID
Get-Process powershell* | Where-Object { $_.Id -ne $currentPid } | ForEach-Object {
    $proc = $_
    # Check if it's one of our test processes (has our module loaded or running our scripts)
    try {
        $modules = Get-Process -Id $proc.Id -Module -ErrorAction SilentlyContinue
        if ($modules.ModuleName -like "*Unity-Claude*" -or $proc.MainWindowTitle -like "*Test*Server*") {
            Write-Host "  Stopping process: $($proc.ProcessName) (PID: $($proc.Id))" -ForegroundColor Yellow
            Stop-Process -Id $proc.Id -Force
        }
    } catch {
        # Process might have already exited
    }
}

Write-Host "`n=== Cleanup Complete ===" -ForegroundColor Green
Write-Host "`nChecking port status..." -ForegroundColor Cyan
foreach ($port in $ports) {
    $listening = netstat -an | Select-String ":$port.*LISTENING"
    if ($listening) {
        Write-Host "  Port ${port}: Still in use (may need manual cleanup or restart)" -ForegroundColor Yellow
    } else {
        Write-Host "  Port ${port}: Free" -ForegroundColor Green
    }
}

Write-Host "`nRecommendations:" -ForegroundColor Cyan
Write-Host "1. If ports are still in use, you may need to:" -ForegroundColor White
Write-Host "   - Run this script as Administrator" -ForegroundColor Gray
Write-Host "   - Restart PowerShell" -ForegroundColor Gray
Write-Host "   - Or wait a few minutes for Windows to release the ports" -ForegroundColor Gray
Write-Host "2. To start fresh:" -ForegroundColor White
Write-Host "   - Run: .\Start-TestServer.ps1" -ForegroundColor Gray
Write-Host "   - Then run your tests" -ForegroundColor Gray
# SIG # Begin signature block
# MIIFqQYJKoZIhvcNAQcCoIIFmjCCBZYCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUGg4e8j30gA2Ad/m85tCdcc+n
# l9GgggMwMIIDLDCCAhSgAwIBAgIQdR0W2SKoK5VE8JId4ZxrRTANBgkqhkiG9w0B
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
# CQQxFgQUn84zuUlP6Ckj28ROM2ng1J4gr54wDQYJKoZIhvcNAQEBBQAEggEAA2aj
# 0YkJItsg998vbkn/GgoHM9lKnWYapTqAjZV4x6kx8nql6PzQCxykfmxuwICKiBxv
# 6NvhnA6hKg5nSoB9JbC9OoZu2V97zTXpcv5vqsWmTS9zGaIcp6ZH8sy8BCvSMSar
# VVt577kQ968USmRdiw5pg+7zJ/eaYTGvYi0aOQpFaxlxcfyd8KaE7gWdaGNOfacz
# LI4to3RVrDTu8zOay6vRnn2XWzQ5m0isAgd08ZzLOu6KwURItO/3dHSTVFmhQIOH
# JbzycO5yYUJbf2pstxgd5Df3H4fa3UEFQKSXXlYNpMKbHHjkmWp2Vl4TlW4SM8Kg
# ZmRIFCYPg5yn834Q4w==
# SIG # End signature block
