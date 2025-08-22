# Test-PIDInheritance.ps1
# Tests how PIDs work when scripts are launched

Write-Host "Script PID: $PID"
Write-Host "Parent Process ID: $((Get-Process -Id $PID).Parent.Id)" -ErrorAction SilentlyContinue

# Try to get parent process info
try {
    $currentProcess = Get-WmiObject Win32_Process -Filter "ProcessId = $PID"
    Write-Host "WMI Parent PID: $($currentProcess.ParentProcessId)"
    
    $parentProcess = Get-Process -Id $currentProcess.ParentProcessId -ErrorAction SilentlyContinue
    if ($parentProcess) {
        Write-Host "Parent Process Name: $($parentProcess.ProcessName)"
    }
} catch {
    Write-Host "Could not get parent info: $_"
}

# Wait so we can see the window
Start-Sleep -Seconds 10
# SIG # Begin signature block
# MIIFqQYJKoZIhvcNAQcCoIIFmjCCBZYCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUKtTprU9pUxIdheIhZhqaXQx3
# KG2gggMwMIIDLDCCAhSgAwIBAgIQdR0W2SKoK5VE8JId4ZxrRTANBgkqhkiG9w0B
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
# CQQxFgQUl48EdgGYLg5GMOjMnFOxXDV+gbowDQYJKoZIhvcNAQEBBQAEggEAp5uG
# 0iAgHnB9Wo4ngMgvEBhDsFucRnxFfsF98+Vt/CpvrSE61GvXgmFC6yxKFYY7Hgxo
# J4sIS5lSfMZeUwIgc3lzHyvGQeyzaTVcjRB/rv/UAVQfOW0wUL/cyKwTV9DM8aXv
# H4oFFudv+iqdhHkvY8KzT2jq/8czKbrB7K+JDZ016xly+tTHAjYkSAdLfK9OVFyw
# wnzuirPOOWye3mkrmVr/ci0+LocVIBTibMz9DGus1fF5KwNwsQOtAWgNMUXxTp3d
# BnjvERn9RludH9qtce3YEPELUGWrp0LkV4AUHSiEhvhXlD9DLu2OpMh7sX8lt0rA
# unUoolE5XjHBfydVIA==
# SIG # End signature block
