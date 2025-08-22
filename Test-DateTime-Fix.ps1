# Quick test to verify DateTime fix
try {
    Import-Module .\Modules\Unity-Claude-AutonomousStateTracker-Enhanced.psm1 -Force

    Write-Host "Testing DateTime fix..." -ForegroundColor Yellow
    
    # Initialize a test agent
    $testAgent = Initialize-EnhancedAutonomousStateTracking -AgentId 'TestFix-012400'
    Write-Host "  [+] Agent initialized" -ForegroundColor Green
    
    # Get state with performance metrics (this triggers the DateTime calculation)
    $state = Get-EnhancedAutonomousState -AgentId 'TestFix-012400' -IncludePerformanceMetrics
    Write-Host "  [+] State retrieved" -ForegroundColor Green
    
    # Test the uptime calculation that was previously failing
    Write-Host "  [+] Uptime calculation: $($state.UptimeMinutes) minutes" -ForegroundColor Green
    
    # Test state persistence and retrieval
    # Save-AgentState -AgentState $testAgent  # This is already done internally
    $loadedState = Get-AgentState -AgentId 'TestFix-012400'
    if ($loadedState) {
        Write-Host "  [+] State persistence working" -ForegroundColor Green
    } else {
        Write-Host "  [-] State persistence failed" -ForegroundColor Red
    }
    
    Write-Host "SUCCESS: All DateTime operations completed without errors!" -ForegroundColor Green
    
} catch {
    Write-Host "ERROR: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "Stack trace: $($_.ScriptStackTrace)" -ForegroundColor Red
}
# SIG # Begin signature block
# MIIFqQYJKoZIhvcNAQcCoIIFmjCCBZYCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUlI8ecwLNjc4H5iHDz0G6xp54
# kPKgggMwMIIDLDCCAhSgAwIBAgIQdR0W2SKoK5VE8JId4ZxrRTANBgkqhkiG9w0B
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
# CQQxFgQUsr2OTIo6doQ9vmEsjY7ZIe0Ya0QwDQYJKoZIhvcNAQEBBQAEggEAGtdd
# UBRmnl6sm0rE4ZIcm4DI/5ryc9dISbkgxE3+ffPtIDhRsK8ReOzJZx+FrOHo2C01
# x0fzWr8XjVdXbI6INdUTqarGVRsVuPUAqF0qoR0vKuKQs5Cqg6u2tIyaHR5qO7kL
# OeN3vtgA+f1uz/Yf9lxscAa160Z1E8b/xics16naSUnz8srqUc2WhkRdM6DpggWx
# JpBxrjTc5vAMEpGpuJjdhgvted9yxQrU09nOyLogxKVvqU1jZMN9Bf2WT/y5dJkc
# sRcxtCUhb541l3Qyqhp8mzFYfxaFsszQ0J64q7VQsuqrPXzWPsZkEqIIm0DFEOzz
# ttj83hnFFzeo437Nsw==
# SIG # End signature block
