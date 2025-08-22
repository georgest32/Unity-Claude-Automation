# Fix-FileWatcherDetection.ps1
# Enhances FileSystemWatcher to detect files created by Claude Code Write tool
# Date: 2025-08-21

Write-Host ""
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "FILEWATCHER DETECTION FIX" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host ""

Write-Host "This fix creates a secondary watcher that polls for new files" -ForegroundColor Yellow
Write-Host "It runs alongside the FileSystemWatcher as a fallback mechanism" -ForegroundColor Yellow
Write-Host ""

# Create a polling watcher script
$pollingScript = @'
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
'@

$scriptPath = ".\Polling-FileWatcher.ps1"
Set-Content -Path $scriptPath -Value $pollingScript -Force
Write-Host "Created polling watcher script: $scriptPath" -ForegroundColor Green

# Option to start the polling watcher
Write-Host ""
Write-Host "To start the polling watcher:" -ForegroundColor Cyan
Write-Host "  Option 1 - In new window:" -ForegroundColor Yellow
Write-Host "    Start-Process powershell -ArgumentList '-NoExit', '-File', '$scriptPath'" -ForegroundColor White
Write-Host ""
Write-Host "  Option 2 - As background job:" -ForegroundColor Yellow
Write-Host "    Start-Job -Name 'PollingWatcher' -FilePath '$scriptPath'" -ForegroundColor White
Write-Host ""

$startNow = Read-Host "Start polling watcher now? (Y/N)"
if ($startNow -eq 'Y') {
    Write-Host ""
    Write-Host "Starting polling watcher in new window..." -ForegroundColor Cyan
    Start-Process powershell -ArgumentList "-NoExit", "-ExecutionPolicy", "Bypass", "-File", $scriptPath
    Write-Host "Polling watcher started!" -ForegroundColor Green
}

Write-Host ""
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "FIX DEPLOYED" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "The polling watcher will detect ALL new JSON files" -ForegroundColor Green
Write-Host "regardless of how they are created." -ForegroundColor Green
# SIG # Begin signature block
# MIIFqQYJKoZIhvcNAQcCoIIFmjCCBZYCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUxeAIjLNUVRNbY0S6hXV479qM
# H1ugggMwMIIDLDCCAhSgAwIBAgIQdR0W2SKoK5VE8JId4ZxrRTANBgkqhkiG9w0B
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
# CQQxFgQUkUUJhb7+f9LEC3qguP9+gNAG7qYwDQYJKoZIhvcNAQEBBQAEggEAfaJF
# o9+cNNggj5QXZXKisAHz6VGuGfmujK++Q9NjETQLvbrT6L74ED5cPSSGYC6oc5m+
# ujVUonvFy44PnX275hxt0LXBYPhiJYHTME9qYioi4PPvBgrBazDt7gapaclh82d3
# 819Tm6Rx0/HVGkUD2Y5Lt/k42uGLLbmgQbyyGJCJ8/WjWhmOdMjIKhC+KMXe6TP8
# kTweudSGfvnudPudW53E/ZoCnfCOwmmuGIIl6g632d1QJEh4vn/nn1pC0PAKdA5i
# WCayQvwBkz1w0VFJ5uEbs58uYBPoa9uJeHE2TKsq9Ht+4fyUtyeYTeep2tgZJ4TR
# y7owg2dkPYc7y0vtAQ==
# SIG # End signature block
