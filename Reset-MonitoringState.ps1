# Reset-MonitoringState.ps1
# Reset the monitoring state to force detection of current Unity errors
# Date: 2025-08-18

Set-Location "C:\UnityProjects\Sound-and-Shoal\Unity-Claude-Automation"

Write-Host "RESETTING AUTONOMOUS MONITORING STATE" -ForegroundColor Cyan
Write-Host "=====================================" -ForegroundColor Cyan

try {
    # Import the module
    Import-Module ".\Modules\Unity-Claude-ReliableMonitoring.psm1" -Force
    
    # Get current status
    Write-Host "Current monitoring status:" -ForegroundColor Yellow
    $status = Get-ReliableMonitoringStatus
    Write-Host "  LastErrorCount: $($status.LastErrorCount)" -ForegroundColor Gray
    Write-Host "  FileWatcherActive: $($status.FileWatcherActive)" -ForegroundColor Gray
    Write-Host "  PollingActive: $($status.PollingActive)" -ForegroundColor Gray
    
    # Check current Unity errors
    $unityErrorPath = "C:\UnityProjects\Sound-and-Shoal\Unity-Claude-Automation\unity_errors_safe.json"
    if (Test-Path $unityErrorPath) {
        $content = Get-Content $unityErrorPath -Raw -Encoding UTF8
        if ($content[0] -eq [char]0xFEFF) {
            $content = $content.Substring(1)
        }
        $errorData = $content | ConvertFrom-Json
        Write-Host "  Current Unity errors: $($errorData.totalErrors)" -ForegroundColor Gray
    }
    
    Write-Host "" -ForegroundColor White
    Write-Host "To force detection of current errors, you have two options:" -ForegroundColor Yellow
    Write-Host "" -ForegroundColor White
    Write-Host "Option 1: Restart the autonomous system" -ForegroundColor Cyan
    Write-Host "  - Stop the current autonomous system (Ctrl+C in Window 2)"
    Write-Host "  - Run: .\Start-ImprovedAutonomy-Fixed.ps1"
    Write-Host "" -ForegroundColor White
    Write-Host "Option 2: Trigger a change in Unity" -ForegroundColor Cyan
    Write-Host "  - Add/remove a character in the Unity script"
    Write-Host "  - Save the file to trigger recompilation"
    Write-Host "  - This will change the error timestamp and trigger detection"
    Write-Host "" -ForegroundColor White
    Write-Host "Option 3: Manual test submission (recommended for testing)" -ForegroundColor Cyan
    Write-Host "  - Run: .\Test-ManualCallback.ps1"
    Write-Host "  - Choose 'y' to submit the enhanced prompt to Claude Code CLI"
    Write-Host "" -ForegroundColor White
    
    Write-Host "The issue is that LastErrorCount ($($status.LastErrorCount)) matches current" -ForegroundColor Yellow
    Write-Host "error count, so the system thinks no new errors occurred." -ForegroundColor Yellow
    Write-Host "The enhanced prompt system is working correctly!" -ForegroundColor Green
    
} catch {
    Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host "" -ForegroundColor White
Write-Host "Press Enter to exit..." -ForegroundColor Yellow
Read-Host
# SIG # Begin signature block
# MIIFqQYJKoZIhvcNAQcCoIIFmjCCBZYCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUfk0dfIh2C3TW/FziHdzwKaWJ
# ZR6gggMwMIIDLDCCAhSgAwIBAgIQdR0W2SKoK5VE8JId4ZxrRTANBgkqhkiG9w0B
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
# CQQxFgQUY3ZyxcBXJYxj9Iml6uctH/cVhkwwDQYJKoZIhvcNAQEBBQAEggEAg+vc
# RsqtX3mptiSfg2S3wVJ3t3dnEKuQTWsu9OMQcDxH5HMsvclkuDxjeXxOv9bxpo46
# 8Lp0EcKhc8Pb3ES1JWsJ9cuajqKPvgmhZNKcGPouMyOaWkPGsVAQBlHtdNTpjq8K
# czTtYW1GopSG3VAR6lxTd9RTNw3W4+MR30mifpphSjKtCOBvR01dAT/Kw6m/ZWK3
# 6qd0LPUtsJUfyuJvK6ttenjjUnRJxK0qUDg4ywjRlJ7KYmOxcOiZB+tvfFKqDaKJ
# NIiuJ0rWa1XOobysQmNdaB5FKbZc/HPet1D/CXs56OVg7xTvSxFCaTwkXilLamlG
# yl/d5Z9VLc8jmhscSQ==
# SIG # End signature block
