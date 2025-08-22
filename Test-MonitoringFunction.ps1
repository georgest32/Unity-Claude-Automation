Set-Location 'C:\UnityProjects\Sound-and-Shoal\Unity-Claude-Automation'
Import-Module '.\Modules\Unity-Claude-AutonomousAgent\Unity-Claude-AutonomousAgent-Refactored.psd1' -Force

Write-Host 'Testing Start-ClaudeResponseMonitoring function directly...' -ForegroundColor Yellow

try {
    $ErrorActionPreference = 'Stop'
    $result = Start-ClaudeResponseMonitoring
    
    Write-Host 'SUCCESS: Function completed' -ForegroundColor Green
    Write-Host "Result:" -ForegroundColor Cyan
    $result | Format-List
    
} catch {
    Write-Host 'ERROR DETAILS:' -ForegroundColor Red
    Write-Host "Error Type: $($_.Exception.GetType().Name)" -ForegroundColor Red
    Write-Host "Error Message: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "Line Number: $($_.InvocationInfo.ScriptLineNumber)" -ForegroundColor Red
    Write-Host "Script Name: $($_.InvocationInfo.ScriptName)" -ForegroundColor Red
    Write-Host "Stack Trace:" -ForegroundColor Red
    Write-Host $_.ScriptStackTrace -ForegroundColor Red
}

Read-Host 'Press Enter to continue'
# SIG # Begin signature block
# MIIFqQYJKoZIhvcNAQcCoIIFmjCCBZYCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUO/jDnycuPFDWvWw/1e5Wm4pf
# MLmgggMwMIIDLDCCAhSgAwIBAgIQdR0W2SKoK5VE8JId4ZxrRTANBgkqhkiG9w0B
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
# CQQxFgQUu5R1qIi5dkWLdGE3/08VdaMvwFEwDQYJKoZIhvcNAQEBBQAEggEAS9t9
# b2wxx3tTCNbFbqJjfu/4FX/GeashnyhrQWRyrVK8j3BBRzKJRum9rQkNILcMO86S
# 8oVXrZGRd0Rme0d/iKWfO4WAa605kfxo/czyYTi/TmNe1qG4Bi1QatWHaHl4T5TO
# ivFqNHaR2+UM7B/a4dsU3tKU3AtcVaLVnW/BhYDMfgu1xCAN3T//s+PCUgX4Kf2l
# u1L1eiuqlp7xRBmzWbJ5ek7JAZUtoihSSjDaqKxSIaXzLtE3gUIltq8hR0WHTovb
# oHcSTBQsByyf+g7iUjv1ZOBFjUrHf65O+6/TY9fYbUCbOvtwBZEkZqYxeW8xp/sW
# lki7lnPdjuKx7x3RUg==
# SIG # End signature block
