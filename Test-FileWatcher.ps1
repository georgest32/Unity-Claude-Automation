Set-Location 'C:\UnityProjects\Sound-and-Shoal\Unity-Claude-Automation'

Write-Host "=== TESTING FILESYSTEMWATCHER DIRECTLY ===" -ForegroundColor Cyan

$watcherPath = "C:\UnityProjects\Sound-and-Shoal\Unity-Claude-Automation\ClaudeResponses\Autonomous"
Write-Host "Creating FileSystemWatcher for: $watcherPath" -ForegroundColor Yellow

$watcher = New-Object System.IO.FileSystemWatcher
$watcher.Path = $watcherPath
$watcher.Filter = "*.json"
$watcher.IncludeSubdirectories = $false
$watcher.NotifyFilter = [System.IO.NotifyFilters]::Creation -bor [System.IO.NotifyFilters]::LastWrite

Write-Host "FileSystemWatcher configured" -ForegroundColor Green

$createdEvent = Register-ObjectEvent -InputObject $watcher -EventName "Created" -Action {
    $filePath = $Event.SourceEventArgs.FullPath
    $timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss.fff'
    Write-Host "[$timestamp] DETECTED FILE CREATED: $filePath" -ForegroundColor Green
    
    # Create pending file
    [System.IO.File]::WriteAllText("C:\UnityProjects\Sound-and-Shoal\Unity-Claude-Automation\ClaudeResponses\Autonomous\.pending", $filePath)
    Write-Host "Created .pending file with: $filePath" -ForegroundColor Green
}

$watcher.EnableRaisingEvents = $true
Write-Host "FileSystemWatcher started - monitoring for file creation..." -ForegroundColor Green
Write-Host "Press Ctrl+C to stop" -ForegroundColor Yellow

try {
    while ($true) {
        Start-Sleep -Seconds 5
        Write-Host "." -NoNewline -ForegroundColor DarkGray
    }
} catch {
    Write-Host "Monitoring stopped" -ForegroundColor Yellow
}

$watcher.EnableRaisingEvents = $false
$watcher.Dispose()
Write-Host "FileSystemWatcher disposed" -ForegroundColor Gray
# SIG # Begin signature block
# MIIFqQYJKoZIhvcNAQcCoIIFmjCCBZYCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUuTL5oFi0aE2A6ASeIucnGOKj
# QGOgggMwMIIDLDCCAhSgAwIBAgIQdR0W2SKoK5VE8JId4ZxrRTANBgkqhkiG9w0B
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
# CQQxFgQU1sO9151V0RIG+5wE2bOjBbO7re0wDQYJKoZIhvcNAQEBBQAEggEAEmsl
# 7NJAT0yP4tdy3wuTurdlqXHwmGvOva3ZKYOZWRsAR7m+Q0sD6JZjG5moHtUv8PP8
# z26WztCYJw49XIAVA8yzgVTS+wKgdq8LjeN3cyfhP+6twhlEU1qD3gtLQ8LJb49B
# dq4+IBCvLm25nVrGf/vd2de3TBWAdnE0OuKUgLWycrM65RBA7TmKrIiK+K/ojtl7
# as5+JMOuqXd1Ingyj6G1Wf5aq6HJt2C1jz7BU994qKH324NiKnWiCMcIys5/fs4Y
# b6zddUvt0hMgAlllSVOUWK7uEO+kxVxBwnjEfPH/VwoLqckP1gT+OSp+4zpJWup8
# geRSIOzPAZKDtLxUMQ==
# SIG # End signature block
