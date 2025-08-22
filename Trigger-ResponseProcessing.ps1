# Trigger-ResponseProcessing.ps1
# Manually triggers processing of Claude response files
# Works around FileSystemWatcher not detecting files created by Claude Code Write tool
# Date: 2025-08-21

param(
    [string]$ResponseFile
)

Write-Host ""
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "MANUAL RESPONSE TRIGGER" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host ""

# If no file specified, look for the latest recommendation file
if (-not $ResponseFile) {
    Write-Host "Looking for latest recommendation file..." -ForegroundColor Yellow
    $latestFile = Get-ChildItem ".\ClaudeResponses\Autonomous\*recommendation*.json" | 
                  Sort-Object LastWriteTime -Descending | 
                  Select-Object -First 1
    
    if ($latestFile) {
        $ResponseFile = $latestFile.FullName
        Write-Host "  Found: $(Split-Path $ResponseFile -Leaf)" -ForegroundColor Green
    } else {
        Write-Host "  No recommendation files found!" -ForegroundColor Red
        exit 1
    }
}

# Check if file exists
if (-not (Test-Path $ResponseFile)) {
    Write-Host "Error: File not found - $ResponseFile" -ForegroundColor Red
    exit 1
}

Write-Host "Response file: $(Split-Path $ResponseFile -Leaf)" -ForegroundColor Cyan

# Method 1: Write to .pending file (what the FileSystemWatcher should do)
$pendingFile = ".\ClaudeResponses\Autonomous\.pending"
Write-Host ""
Write-Host "Method 1: Creating .pending file..." -ForegroundColor Yellow
Set-Content -Path $pendingFile -Value $ResponseFile -Force
Write-Host "  Created: $pendingFile" -ForegroundColor Green
Write-Host "  Content: $ResponseFile" -ForegroundColor Gray
Write-Host ""
Write-Host "The AutonomousAgent should now process this file!" -ForegroundColor Cyan

# Method 2: Also try triggering a file change event
Write-Host ""
Write-Host "Method 2: Triggering file change event..." -ForegroundColor Yellow
$currentContent = Get-Content $ResponseFile -Raw
# Add a space to trigger change event
Set-Content -Path $ResponseFile -Value "$currentContent " -NoNewline
Start-Sleep -Milliseconds 500
# Remove the space
Set-Content -Path $ResponseFile -Value $currentContent -NoNewline
Write-Host "  Triggered change events on file" -ForegroundColor Green

Write-Host ""
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "TRIGGER COMPLETE" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Check the AutonomousAgent window for processing activity." -ForegroundColor Yellow
# SIG # Begin signature block
# MIIFqQYJKoZIhvcNAQcCoIIFmjCCBZYCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUnM+MpKnJAEDnMmyAEUu+gI0B
# ARCgggMwMIIDLDCCAhSgAwIBAgIQdR0W2SKoK5VE8JId4ZxrRTANBgkqhkiG9w0B
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
# CQQxFgQUh1hLoSAaAZLnthEw57U7ZzjXnwEwDQYJKoZIhvcNAQEBBQAEggEAR4+r
# bzH2kfhn+HriKQeKLSR8n4i+gKinJKLqO8uEg5jloEIIbvJV42QuQBTTgfO+e00Q
# yRihaR5/VJ5FCDHgPITuxaHsKY184sYMXq9dR+lSYEAX70zYA0C5p/Kfyph0wpQq
# +T9kPEdAGY1fZg7aTqmvA9iwOfo0solvOYlHQTquK1l4KJmm6QBZS2EXzr1zqHdD
# 2oelNPo7JRdPzqhBzv6DexRMahGROkiXgiCOcs5c3qN+FbXZI2wyPGwoiqoDbIq6
# 5Ijm6ywzvqAziLsmGbfFUyG4qCub0tIuMCEDxpXlhyh41/P8loAvJHDN/7ZIy1bR
# TvUpgQvy2BRwXSh1QA==
# SIG # End signature block
