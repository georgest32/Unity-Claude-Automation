# Watch-SystemStatusWrites.ps1
# Monitors and logs all writes to system_status.json

param(
    [string]$StatusFile = "C:\UnityProjects\Sound-and-Shoal\Unity-Claude-Automation\system_status.json",
    [string]$LogFile = "C:\UnityProjects\Sound-and-Shoal\Unity-Claude-Automation\system_status_writes.log"
)

Write-Host "Starting System Status Write Monitor..." -ForegroundColor Cyan
Write-Host "Monitoring: $StatusFile" -ForegroundColor Gray
Write-Host "Logging to: $LogFile" -ForegroundColor Gray
Write-Host ""

# Initialize log
$timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss.fff'
Add-Content -Path $LogFile -Value "[$timestamp] [START] System Status Write Monitor started"

# Get initial state
if (Test-Path $StatusFile) {
    $initialContent = Get-Content $StatusFile -Raw
    $initialStatus = $initialContent | ConvertFrom-Json
    
    $hasClaudeCodeCLI = $false
    if ($initialStatus.SystemInfo -and $initialStatus.SystemInfo.ClaudeCodeCLI) {
        $hasClaudeCodeCLI = $true
        $claudePID = $initialStatus.SystemInfo.ClaudeCodeCLI.ProcessId
        Add-Content -Path $LogFile -Value "[$timestamp] [INITIAL] ClaudeCodeCLI present - PID: $claudePID"
        Write-Host "Initial state: ClaudeCodeCLI present - PID: $claudePID" -ForegroundColor Green
    } else {
        Add-Content -Path $LogFile -Value "[$timestamp] [INITIAL] ClaudeCodeCLI NOT present"
        Write-Host "Initial state: ClaudeCodeCLI NOT present" -ForegroundColor Yellow
    }
}

# Set up file watcher
$watcher = New-Object System.IO.FileSystemWatcher
$watcher.Path = Split-Path $StatusFile -Parent
$watcher.Filter = Split-Path $StatusFile -Leaf
$watcher.NotifyFilter = [System.IO.NotifyFilters]::LastWrite

# Register event handler
Register-ObjectEvent -InputObject $watcher -EventName "Changed" -Action {
    $timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss.fff'
    $logFile = $Event.MessageData.LogFile
    $statusFile = $Event.MessageData.StatusFile
    
    try {
        # Small delay to ensure write is complete
        Start-Sleep -Milliseconds 100
        
        # Read new content
        $content = Get-Content $statusFile -Raw -ErrorAction SilentlyContinue
        if ($content) {
            $status = $content | ConvertFrom-Json
            
            # Check for ClaudeCodeCLI field
            $hasClaudeCodeCLI = $false
            $claudeInfo = ""
            
            if ($status.SystemInfo -and $status.SystemInfo.ClaudeCodeCLI) {
                $hasClaudeCodeCLI = $true
                $claudePID = $status.SystemInfo.ClaudeCodeCLI.ProcessId
                $lastDetected = $status.SystemInfo.ClaudeCodeCLI.LastDetected
                $claudeInfo = "PID: $claudePID, LastDetected: $lastDetected"
            }
            
            # Get caller information (try to determine which process wrote to the file)
            $callStack = Get-PSCallStack
            $caller = if ($callStack.Count -gt 1) { $callStack[1].Command } else { "Unknown" }
            
            # Log the write
            if ($hasClaudeCodeCLI) {
                $logEntry = "[$timestamp] [WRITE] ClaudeCodeCLI PRESENT - $claudeInfo | Caller: $caller"
                Write-Host "[$timestamp] ClaudeCodeCLI PRESENT - $claudeInfo" -ForegroundColor Green
            } else {
                $logEntry = "[$timestamp] [WRITE] ClaudeCodeCLI MISSING! | Caller: $caller"
                Write-Host "[$timestamp] ClaudeCodeCLI MISSING!" -ForegroundColor Red
                
                # Log which fields ARE present in SystemInfo
                if ($status.SystemInfo) {
                    $fields = $status.SystemInfo.PSObject.Properties.Name -join ", "
                    $logEntry += " | SystemInfo fields: $fields"
                }
            }
            
            Add-Content -Path $logFile -Value $logEntry
            
            # Check for specific subsystem updates
            if ($status.Subsystems) {
                $subsystems = $status.Subsystems.PSObject.Properties.Name -join ", "
                Add-Content -Path $logFile -Value "[$timestamp] [SUBSYSTEMS] Active: $subsystems"
            }
        }
    } catch {
        Add-Content -Path $logFile -Value "[$timestamp] [ERROR] Failed to read status file: $_"
    }
} -MessageData @{LogFile = $LogFile; StatusFile = $StatusFile}

Write-Host "File watcher registered. Monitoring for changes..." -ForegroundColor Cyan
Write-Host "Press Ctrl+C to stop monitoring" -ForegroundColor Gray
Write-Host ""

# Keep the script running
try {
    while ($true) {
        Start-Sleep -Seconds 1
    }
} finally {
    Unregister-Event -SourceIdentifier FileChanged -ErrorAction SilentlyContinue
    $watcher.Dispose()
    Write-Host "`nMonitoring stopped" -ForegroundColor Yellow
}
# SIG # Begin signature block
# MIIFqQYJKoZIhvcNAQcCoIIFmjCCBZYCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUbQcDep5AmxuAlq6jFwVIZ4yk
# c4agggMwMIIDLDCCAhSgAwIBAgIQdR0W2SKoK5VE8JId4ZxrRTANBgkqhkiG9w0B
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
# CQQxFgQUecOPZ4x8YcOo6UpUc91WK4pYGCUwDQYJKoZIhvcNAQEBBQAEggEADxSA
# 5q1X8QcoBKEJiEE1SZwLKLYa4XTM93l4Eg8m6Aw5JKBwIn/Al1w38RW9fEqtE2cP
# h1Ct4NpJGW8ZlYTfxswD8x9uE07U/9rMcS8Vm/eRWz/0Alw3r5OjQqJgT9il6VkJ
# RcXf/INz7CCRcGXdlXFPs4Uge0nrIsR7FE5rr/zwVHBIoaSFn5OSa7LMik0IT+7c
# y3ZecdEhZZKL5b5W9XemTbzz0vGttIqpLplBzP6L/E9EF27VIQhlni/nhacDyAB7
# /clxqVV1+y/58PnhhBbzy/gW+1vC60hibs6/G5Y1o3Az0GQSr6rf61q52NOlf7Gb
# 9b5rnLj0vIi6XfsUtA==
# SIG # End signature block
