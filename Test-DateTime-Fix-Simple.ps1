# Simple test to validate DateTime fixes
Import-Module ".\Modules\Unity-Claude-AutonomousStateTracker-Enhanced.psm1" -Force

Write-Host "Testing DateTime fixes..." -ForegroundColor Cyan

try {
    # Initialize tracking
    $result = Initialize-EnhancedAutonomousStateTracking -AgentId "DateTime-Test"
    Write-Host "[+] Initialized agent: $($result.AgentId)" -ForegroundColor Green
    
    # Test DateTime operations
    $state = Get-EnhancedAutonomousState -AgentId "DateTime-Test" -IncludePerformanceMetrics
    
    if ($state.Success) {
        Write-Host "[+] SUCCESS: No DateTime op_Subtraction errors!" -ForegroundColor Green
        Write-Host "[+] Uptime: $($state.UptimeMinutes) minutes" -ForegroundColor Green
    } else {
        Write-Host "[-] ERROR: $($state.Error)" -ForegroundColor Red
    }
}
catch {
    Write-Host "[-] Exception: $_" -ForegroundColor Red
}
# SIG # Begin signature block
# MIIFqQYJKoZIhvcNAQcCoIIFmjCCBZYCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQU6gASITSHMu95jpJScaQhfqmS
# c8ygggMwMIIDLDCCAhSgAwIBAgIQdR0W2SKoK5VE8JId4ZxrRTANBgkqhkiG9w0B
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
# CQQxFgQUoecRIrAbgZ9WLinQnZuKg76k++cwDQYJKoZIhvcNAQEBBQAEggEAIsHx
# qSOtZFdmFe8fqI04vugsBilhugO3q3rLB3DpPpcJrLiNmJIMvZK050DKhWEdIZp4
# 1mrRoHWOv+fv74V3L9qMoe110uGdjdKLsPBSggggQhqdLUOl08Bih8loCqDyDVvs
# xs4yM/V2cFkzjgWmvpaaFcZ+KkS4OxpdpoioPdeg7wVPmxV+BaoHMw0gehHSqTg/
# MErwUDOGzBPB55vdvI+5BxNjpCfkR/lscCHUFmDxdhRu3mthxgek6B7QY5qohLAO
# 6OWRUwYwm6uhmifqm8ofO2Dfr5bw03gIOhCCyLiFihxh/6S4SBprNksAKkgwI2Cd
# KcbOAABudNFivDKIAw==
# SIG # End signature block
