# Polling-FileWatcher.ps1
# Polls for new JSON files in Claude responses directory
# Runs as a complement to FileSystemWatcher

param(
    [string]$WatchPath = "C:\UnityProjects\Sound-and-Shoal\Unity-Claude-Automation\ClaudeResponses\Autonomous",
    [int]$PollIntervalSeconds = 5
)

Write-Host "[POLLING WATCHER] Starting polling watcher for: $WatchPath" -ForegroundColor Cyan
Write-Host "[POLLING WATCHER] Poll interval: $PollIntervalSeconds seconds" -ForegroundColor Gray

# Track processed files
$processedFiles = @{}
$pendingFile = Join-Path $WatchPath ".pending"

# Initial scan - mark existing files as processed
Get-ChildItem -Path $WatchPath -Filter "*.json" | ForEach-Object {
    $processedFiles[$_.FullName] = $true
}
Write-Host "[POLLING WATCHER] Initial scan found $($processedFiles.Count) existing files" -ForegroundColor Gray

while ($true) {
    try {
        # Check for new JSON files
        $currentFiles = Get-ChildItem -Path $WatchPath -Filter "*.json" -ErrorAction SilentlyContinue
        
        foreach ($file in $currentFiles) {
            if (-not $processedFiles.ContainsKey($file.FullName)) {
                # New file detected!
                Write-Host "[POLLING WATCHER] NEW FILE DETECTED: $($file.Name)" -ForegroundColor Green
                
                # Log detection
                $logEntry = "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss.fff')] [INFO] [PollingWatcher] New file detected: $($file.FullName)"
                Add-Content -Path "C:\UnityProjects\Sound-and-Shoal\Unity-Claude-Automation\unity_claude_automation.log" -Value $logEntry
                
                # Write to pending file for processing
                Set-Content -Path $pendingFile -Value $file.FullName -Force
                Write-Host "[POLLING WATCHER] Queued for processing: $($file.Name)" -ForegroundColor Yellow
                
                # Mark as processed
                $processedFiles[$file.FullName] = $true
            }
        }
    }
    catch {
        Write-Host "[POLLING WATCHER] Error: $_" -ForegroundColor Red
    }
    
    # Wait before next poll
    Start-Sleep -Seconds $PollIntervalSeconds
}

# SIG # Begin signature block
# MIIFqQYJKoZIhvcNAQcCoIIFmjCCBZYCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUU8bIAhdd5sDwtqhUtObwVmLd
# QFSgggMwMIIDLDCCAhSgAwIBAgIQdR0W2SKoK5VE8JId4ZxrRTANBgkqhkiG9w0B
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
# CQQxFgQUUztPjHpontqixHtRU35WOTj1KXAwDQYJKoZIhvcNAQEBBQAEggEAB32s
# 9Q4vnReDIHJZoDvSqB6m5vMU9hlwq8gTIYccqpygHHspBu/u7U//h7N2bppAAFJM
# qAgnRUsa9p1692n3oDHJYxIkwWYPk7F81P5wBLix1HmYxvDg+RiRigQvfF6N8oDu
# iEt0VJTme4KNcCqxgSHA2IKwTUJsXGe99Wba8lyOnKlm+otJFtZff0q4QQ+koBKP
# xCQVVCGU2sD28tWAu8Wa/N2r3D0dC3panO8MxpSn4DJ8C68wbLQVavzS8VcUGTlz
# 7OMzCYvBt+XPHDMj6/+//yPk//8zWmZg9imCB3ReptL8VhjnXDDQDnN4x/4nIg2f
# xGM3HtLWMbC2c+Ow5w==
# SIG # End signature block
