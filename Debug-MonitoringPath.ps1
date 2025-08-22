Set-Location 'C:\UnityProjects\Sound-and-Shoal\Unity-Claude-Automation'
Import-Module '.\Modules\Unity-Claude-AutonomousAgent\Unity-Claude-AutonomousAgent-Refactored.psd1' -Force

Write-Host "=== MONITORING PATH DEBUG ===" -ForegroundColor Cyan

try {
    $config = Get-AgentConfig
    $monitoringDir = $config.ClaudeOutputDirectory
    
    Write-Host "Configured monitoring directory: $monitoringDir" -ForegroundColor Yellow
    Write-Host "Resolved path: $(Resolve-Path $monitoringDir -ErrorAction SilentlyContinue)" -ForegroundColor Yellow
    Write-Host "Directory exists: $(Test-Path $monitoringDir)" -ForegroundColor Yellow
    
    if (Test-Path $monitoringDir) {
        Write-Host "Files in monitoring directory:" -ForegroundColor Green
        Get-ChildItem -Path $monitoringDir | ForEach-Object {
            Write-Host "  $($_.Name) (Modified: $($_.LastWriteTime))" -ForegroundColor Gray
        }
    }
    
    Write-Host ""
    Write-Host "File we created: C:\UnityProjects\Sound-and-Shoal\Unity-Claude-Automation\ClaudeResponses\Autonomous\response_20250819_200545.json" -ForegroundColor Cyan
    Write-Host "File exists: $(Test-Path 'C:\UnityProjects\Sound-and-Shoal\Unity-Claude-Automation\ClaudeResponses\Autonomous\response_20250819_200545.json')" -ForegroundColor Cyan
    
} catch {
    Write-Host "Error getting config: $($_.Exception.Message)" -ForegroundColor Red
}

Read-Host 'Press Enter to continue'
# SIG # Begin signature block
# MIIFqQYJKoZIhvcNAQcCoIIFmjCCBZYCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUdjiXDYJLtuKCCIE1UADnpmuA
# 6kOgggMwMIIDLDCCAhSgAwIBAgIQdR0W2SKoK5VE8JId4ZxrRTANBgkqhkiG9w0B
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
# CQQxFgQUQJ9WwUonLpErVLAKvN4E3AGyN6IwDQYJKoZIhvcNAQEBBQAEggEArBzP
# fqwR2dVtTgsfER+xMyFrqqUQPX7rPIfQhRh1Nz948Z2ZrjcfvrZ2Mu1HrQTwO9Oe
# kxi2jEnUjdYB0E2ylz0aBNm9stCL8S2fkzQfIswAyV59I2gWhZduQ5JdzSiEryU+
# DcPPIdDVAbndVGJ2RTnPMs0qfHPqjDaptK6Ch5adKCtdgHCvs0dF/DChBHqdpvSU
# ZvZPIFdum4zjiOO8qCeshBA9zuE9UTs/5QKfx7xfZK5VumVCSnrdBN+87Dp2OA2Y
# AOrBTfDvFU4O23FIfiPcsRygTz9UeLUhargqSWBIlyL3nQMJOz20FDLIRYVRopU7
# T6T9U3dLvbxabreJYQ==
# SIG # End signature block
