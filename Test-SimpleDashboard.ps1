# Simple Test Dashboard for Universal Dashboard Community
# Tests basic functionality before running the full analytics dashboard

Write-Host "=== Simple Test Dashboard ===" -ForegroundColor Yellow

# Import module
try {
    Import-Module UniversalDashboard.Community -ErrorAction Stop
    Write-Host "✓ Module loaded successfully" -ForegroundColor Green
} catch {
    Write-Error "Failed to load UniversalDashboard.Community: $_"
    Write-Host "Run Install-UniversalDashboard.ps1 first" -ForegroundColor Yellow
    exit 1
}

# Create a simple dashboard
$Dashboard = New-UDDashboard -Title "Test Dashboard" -Content {
    New-UDHeading -Text "Universal Dashboard Test" -Size 1
    
    New-UDRow {
        New-UDColumn -Size 4 {
            New-UDCard -Title "System Info" -Content {
                New-UDParagraph -Text "PowerShell Version: $($PSVersionTable.PSVersion)"
                New-UDParagraph -Text "Time: $(Get-Date -Format 'HH:mm:ss')"
            }
        }
        
        New-UDColumn -Size 4 {
            New-UDCard -Title "Test Counter" -Content {
                New-UDCounter -Title "Random Number" -Endpoint {
                    Get-Random -Minimum 1 -Maximum 100
                } -RefreshInterval 5
            }
        }
        
        New-UDColumn -Size 4 {
            New-UDCard -Title "Test Chart" -Content {
                New-UDChart -Title "Sample Data" -Type Bar -Endpoint {
                    @(
                        [PSCustomObject]@{ Label = "Item 1"; Value = 25 }
                        [PSCustomObject]@{ Label = "Item 2"; Value = 50 }
                        [PSCustomObject]@{ Label = "Item 3"; Value = 75 }
                    ) | Out-UDChartData -DataProperty "Value" -LabelProperty "Label"
                }
            }
        }
    }
    
    New-UDRow {
        New-UDColumn -Size 12 {
            New-UDCard -Title "Dashboard Status" -Content {
                New-UDParagraph -Text "If you can see this, the dashboard is working correctly!"
                New-UDParagraph -Text "The counter should update every 5 seconds."
            } -BackgroundColor "#4CAF50" -FontColor "white"
        }
    }
}

# Start the dashboard
$Port = 8090
try {
    Write-Host "Starting test dashboard on port $Port..." -ForegroundColor Cyan
    
    # Stop any existing dashboard
    Get-UDDashboard | Where-Object { $_.Port -eq $Port } | Stop-UDDashboard
    
    # Start dashboard
    Start-UDDashboard -Dashboard $Dashboard -Port $Port
    
    Write-Host "✓ Test dashboard started!" -ForegroundColor Green
    Write-Host "Access at: http://localhost:$Port" -ForegroundColor Yellow
    Write-Host "Press Ctrl+C to stop" -ForegroundColor Gray
    
    # Open browser
    Start-Process "http://localhost:$Port"
    
    # Keep running
    while ($true) {
        Start-Sleep -Seconds 10
    }
    
} catch {
    Write-Error "Failed to start dashboard: $_"
}
# SIG # Begin signature block
# MIIFqQYJKoZIhvcNAQcCoIIFmjCCBZYCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQU8g+viI6zWjbT1Z9kHP7bfBj0
# wtigggMwMIIDLDCCAhSgAwIBAgIQdR0W2SKoK5VE8JId4ZxrRTANBgkqhkiG9w0B
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
# CQQxFgQUfFEC2IFY+oA6DOY6NTNsYjlWcLowDQYJKoZIhvcNAQEBBQAEggEAQw7x
# kSovebJfLxb/iN5H0VlC4Da2oor5EmQQDx0yp4J3CWMNwfzj7ED47vCA+0SjNlgf
# zkxz+WNyQWjgJNl/PMMf0UmMXly3jGwRNwBiIovg/JuwoN3z6oGkvgOgJdTWCcbB
# LFyezSevAnn+houUS71cWgZD8DoMy8PkXCdwuSt0fXgJI4kTdP7pWhaUtAzM5mv9
# UwN5rmTdH3tvFWLcMtfLHmk0bXpqW/9LcWCSKMUZfxH122WYlhXDUoYTDVd5af2W
# Dvl8TlR8+DJrmWDxHcz8xhlAwD9u0jIvG4pa/ypAocjKCgSbaA3RW4H/AcAptpeS
# TN1vCjk0PtJ/oJu4iw==
# SIG # End signature block
