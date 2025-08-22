# Check-Jobs.ps1
# Quick check of background jobs and Unity errors
# Date: 2025-08-18

Write-Host "CHECKING AUTONOMOUS SYSTEM STATUS" -ForegroundColor Cyan
Write-Host "==================================" -ForegroundColor Cyan

# Check all background jobs
Write-Host "Background Jobs:" -ForegroundColor Yellow
$allJobs = Get-Job
if ($allJobs) {
    foreach ($job in $allJobs) {
        Write-Host "  Job ID: $($job.Id) | Name: $($job.Name) | State: $($job.State)" -ForegroundColor Gray
        
        if ($job.Name -eq "UnityErrorMonitor") {
            Write-Host "    This is our Unity monitoring job!" -ForegroundColor Green
            if ($job.HasMoreData) {
                Write-Host "    Recent output:" -ForegroundColor Cyan
                $output = Receive-Job $job -Keep
                $output | Select-Object -Last 5 | ForEach-Object { Write-Host "      $_" -ForegroundColor DarkGray }
            } else {
                Write-Host "    No recent output from job" -ForegroundColor Yellow
            }
        }
    }
} else {
    Write-Host "  No background jobs found" -ForegroundColor Red
}

# Check Unity log for errors NOW
Write-Host "" -ForegroundColor White
Write-Host "Unity Editor.log (last 10 lines):" -ForegroundColor Yellow
$logPath = "C:\Users\georg\AppData\Local\Unity\Editor\Editor.log"
$recentLog = Get-Content $logPath -Tail 10

foreach ($line in $recentLog) {
    if ($line -match "CS\d+:") {
        Write-Host "  ERROR: $line" -ForegroundColor Red
    } else {
        Write-Host "  $line" -ForegroundColor Gray
    }
}

Write-Host "" -ForegroundColor White
Write-Host "Press Enter to exit..." -ForegroundColor Yellow
Read-Host
# SIG # Begin signature block
# MIIFqQYJKoZIhvcNAQcCoIIFmjCCBZYCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUdPRIx1mpkCpASX89Ft7vdPlZ
# ALGgggMwMIIDLDCCAhSgAwIBAgIQdR0W2SKoK5VE8JId4ZxrRTANBgkqhkiG9w0B
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
# CQQxFgQUe4GCjRgUE9Fjp89a2TklIOEKNjswDQYJKoZIhvcNAQEBBQAEggEAYVqQ
# LEC1/rOo1DG4ACRJ/soeSU3ytY6JkO1uyc0bSzqpaFZQsu5CYwTP/gRj6FarqYvW
# vFYBe3gfqPk7vij0FArZ1upO6AQFzWBvjSYQymZ0ULsVBjuOLRXy/n9wnBkZiXFA
# +HvOVMkFwNTe0rFZ2xr+ZT7ibECdzS045p9zoquTSoZx6meVlbf5L/0sTGXNvMr0
# uYAu0cV+NmX4x6+yuNye7/vGonRxsZB12oli0OxmuR97cs+MtWt8xjkaPtipy5y+
# Uk4mDSn+p61MSCGFlWpgOcKLK2FeHCNHJ/EyMkoMAwRi9hy2nSXPwODfNcdo/6Yq
# Myrf2g6rJmgyUMmovQ==
# SIG # End signature block
