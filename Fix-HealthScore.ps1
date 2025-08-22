# Fix-HealthScore.ps1
# Adds missing HealthScore property to subsystems in system_status.json

$statusFile = "C:\UnityProjects\Sound-and-Shoal\Unity-Claude-Automation\system_status.json"

try {
    # Read current status
    $status = Get-Content $statusFile | ConvertFrom-Json
    
    # Add HealthScore to all subsystems that don't have it
    if ($status.Subsystems) {
        foreach ($subsystemName in @($status.Subsystems.PSObject.Properties.Name)) {
            $subsystem = $status.Subsystems.$subsystemName
            if (-not ($subsystem.PSObject.Properties.Name -contains 'HealthScore')) {
                $subsystem | Add-Member -MemberType NoteProperty -Name 'HealthScore' -Value 1.0 -Force
                Write-Host "Added HealthScore to $subsystemName"
            }
        }
    }
    
    # Save the updated status
    $status | ConvertTo-Json -Depth 10 | Set-Content $statusFile -Encoding UTF8
    Write-Host "Successfully updated system_status.json with HealthScore values" -ForegroundColor Green
    
} catch {
    Write-Host "Error updating system_status.json: $_" -ForegroundColor Red
}
# SIG # Begin signature block
# MIIFqQYJKoZIhvcNAQcCoIIFmjCCBZYCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUxizLHWkKy8wuuFG5vMzpS7Wa
# aq6gggMwMIIDLDCCAhSgAwIBAgIQdR0W2SKoK5VE8JId4ZxrRTANBgkqhkiG9w0B
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
# CQQxFgQU49bNYkDA+MAlyGFUyT/T8IFRM1MwDQYJKoZIhvcNAQEBBQAEggEAbhM8
# D7Lj4gH4mSGJIQ+WV5LH3UbXe7GKFryj2dkHNjzcuNJnlhSppmw7BtK0BurJOVLY
# tUVhmOO3IipdSkF30mUbCy2ioY0ATaOh2jbwH1KZnf/129Vg6bCAhKo/ChKwWuec
# hq45FAg+VfsB3bOiTleJVC74EhKjceW8Fm0YE1t3+2Eqw7FG0SpIr5ohXWKE6YRu
# LNrTW80uTM3m9Bl31SKt1h9WPLS11eU6Sjbazh+Ta0V4r9/tsFmtnJ8ULpIz5MmB
# 1HKKYfBs6UFnVpMtQpb/macYvYhtCG+pmJubO0QQ4jvF5JzaApvzEFv8WTce+NVt
# oxU1uUHz3Y2RG25/eA==
# SIG # End signature block
