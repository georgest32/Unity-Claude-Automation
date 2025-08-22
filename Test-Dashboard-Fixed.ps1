# Simple test dashboard to verify UD is working
param(
    [int]$Port = 8080
)

Write-Host "Starting test dashboard on port $Port..." -ForegroundColor Yellow

# Import modules
Import-Module UniversalDashboard.Community -ErrorAction Stop
Import-Module './Modules/Unity-Claude-Learning/Unity-Claude-Learning.psm1' -Force
Import-Module './Modules/Unity-Claude-Learning/Unity-Claude-Learning-Analytics.psm1' -Force

Write-Host "Modules loaded" -ForegroundColor Green

# Create simple dashboard
$Dashboard = New-UDDashboard -Title "Test Analytics" -Content {
    New-UDHeading -Text "Unity-Claude Learning Analytics" -Size 1
    
    New-UDRow {
        New-UDColumn -Size 12 {
            New-UDCard -Title "System Status" -Content {
                $metrics = Get-MetricsFromJSON -StoragePath (Join-Path (Get-Location) "Storage\JSON")
                New-UDParagraph -Text "Total Metrics: $($metrics.Count)"
                New-UDParagraph -Text "Time: $(Get-Date -Format 'HH:mm:ss')"
            }
        }
    }
}

# Start dashboard
Get-UDDashboard | Where-Object { $_.Port -eq $Port } | Stop-UDDashboard
Start-UDDashboard -Dashboard $Dashboard -Port $Port

Write-Host "Dashboard running at http://localhost:$Port" -ForegroundColor Green
Write-Host "Press Ctrl+C to stop" -ForegroundColor Gray

# Keep running
while ($true) {
    Start-Sleep -Seconds 10
}
# SIG # Begin signature block
# MIIFqQYJKoZIhvcNAQcCoIIFmjCCBZYCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUuCZv7WcYeAX6+QlPfItvrKJJ
# SR+gggMwMIIDLDCCAhSgAwIBAgIQdR0W2SKoK5VE8JId4ZxrRTANBgkqhkiG9w0B
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
# CQQxFgQU/GIImTTSjPlgh95LQXiEEplSe1gwDQYJKoZIhvcNAQEBBQAEggEAZihB
# SFeLnPrHuJZVx9WPfGEFAmbWMW1Jho2A7aEeFhyD+N+LHaDJezHvXvh+ET9KNmXQ
# 7801KMwlbYfzoLiOis7bpa8utGMfsO1HxNCeUELQsYPG2jeCREQXUNkyrqA9evUH
# 8+W/pGEPPGSPpQQfcRpeHvPfnmipc7pw5RZo2Pue9l7onsGecNWZUxLM07D1sZuJ
# ymDGtrHArdRviBsqZTOW3l4MJLZTa4EwIxdaytlPEVjNv8sWrmWwxMdbUnVU1Inu
# NlknymbfP2IiFVsr8MUVIj/T4uQ9kHK+H2P7CZz9Tv5aWN/pjF6Hxz7SU9VfGv3O
# VpUGNkJpjLJqmpTjMQ==
# SIG # End signature block
