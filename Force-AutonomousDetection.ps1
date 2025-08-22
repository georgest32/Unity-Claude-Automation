# Force-AutonomousDetection.ps1
# Force the autonomous system to detect current Unity errors
# Date: 2025-08-18

Set-Location "C:\UnityProjects\Sound-and-Shoal\Unity-Claude-Automation"

Write-Host "FORCING AUTONOMOUS DETECTION" -ForegroundColor Cyan
Write-Host "============================" -ForegroundColor Cyan

# Read current error file
$errorFile = ".\unity_errors_safe.json"
if (Test-Path $errorFile) {
    $content = Get-Content $errorFile -Raw | ConvertFrom-Json
    
    Write-Host "Current error file status:" -ForegroundColor Yellow
    Write-Host "  Total errors: $($content.totalErrors)" -ForegroundColor Gray
    Write-Host "  Export time: $($content.exportTime)" -ForegroundColor Gray
    Write-Host "  File timestamp: $((Get-Item $errorFile).LastWriteTime)" -ForegroundColor Gray
    
    # Create a completely new file with fresh timestamp
    $newContent = @{
        errors = @()
        totalErrors = 0
        exportTime = Get-Date -Format "yyyy-MM-dd HH:mm:ss.fff"
        isCompiling = $false
        triggerTimestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss.fff"
    }
    
    # Add current errors with fresh timestamps
    foreach ($error in $content.errors) {
        $newError = @{
            message = $error.message
            stackTrace = $error.stackTrace
            type = $error.type
            timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss.fff"  # Fresh timestamp
            source = "ForcedDetection"
        }
        $newContent.errors += $newError
    }
    
    # Add a trigger error to ensure detection
    $triggerError = @{
        message = "AUTONOMOUS SYSTEM TRIGGER - Please process these Unity errors immediately"
        stackTrace = ""
        type = "TriggerError"
        timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss.fff"
        source = "AutonomousTrigger"
    }
    $newContent.errors += $triggerError
    $newContent.totalErrors = $newContent.errors.Count
    
    # Multiple file operations to ensure detection
    Write-Host "" -ForegroundColor White
    Write-Host "Triggering autonomous system detection..." -ForegroundColor Yellow
    
    # Method 1: Overwrite with new content
    $json1 = $newContent | ConvertTo-Json -Depth 4
    [System.IO.File]::WriteAllText($errorFile, $json1, [System.Text.Encoding]::UTF8)
    Write-Host "[1] Updated file with fresh content" -ForegroundColor Green
    Start-Sleep 1
    
    # Method 2: Touch the file to update timestamp
    (Get-Item $errorFile).LastWriteTime = Get-Date
    Write-Host "[2] Updated file timestamp" -ForegroundColor Green
    Start-Sleep 1
    
    # Method 3: Add another timestamp update
    $newContent.lastTrigger = Get-Date -Format "yyyy-MM-dd HH:mm:ss.fff"
    $json2 = $newContent | ConvertTo-Json -Depth 4
    [System.IO.File]::WriteAllText($errorFile, $json2, [System.Text.Encoding]::UTF8)
    Write-Host "[3] Added final trigger timestamp" -ForegroundColor Green
    
    $finalInfo = Get-Item $errorFile
    Write-Host "" -ForegroundColor White
    Write-Host "FINAL FILE STATUS:" -ForegroundColor Cyan
    Write-Host "  File size: $($finalInfo.Length) bytes" -ForegroundColor Gray
    Write-Host "  Modified: $($finalInfo.LastWriteTime)" -ForegroundColor Gray
    Write-Host "  Total errors: $($newContent.totalErrors)" -ForegroundColor Gray
    
    Write-Host "" -ForegroundColor White
    Write-Host "[>] AUTONOMOUS SYSTEM SHOULD NOW ACTIVATE!" -ForegroundColor Green
    Write-Host "Watch your autonomous system window for immediate activity..." -ForegroundColor Yellow
    Write-Host "" -ForegroundColor White
    Write-Host "Expected behavior:" -ForegroundColor Cyan
    Write-Host "1. Autonomous system detects file change" -ForegroundColor Gray
    Write-Host "2. Generates intelligent prompt for $($newContent.totalErrors) errors" -ForegroundColor Gray
    Write-Host "3. Switches to Claude Code CLI window" -ForegroundColor Gray
    Write-Host "4. Submits prompt automatically" -ForegroundColor Gray
    Write-Host "5. Begins monitoring for Claude response" -ForegroundColor Gray
    
} else {
    Write-Host "[-] Unity error file not found: $errorFile" -ForegroundColor Red
}

Write-Host "" -ForegroundColor White
Write-Host "Press Enter to continue..." -ForegroundColor Gray
Read-Host
# SIG # Begin signature block
# MIIFqQYJKoZIhvcNAQcCoIIFmjCCBZYCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUgX4ve8ayeal57qu9SMm/EExJ
# 8GygggMwMIIDLDCCAhSgAwIBAgIQdR0W2SKoK5VE8JId4ZxrRTANBgkqhkiG9w0B
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
# CQQxFgQU8MYKDnZbZepvIkRCua6MH/70I8UwDQYJKoZIhvcNAQEBBQAEggEANXrh
# 7nTMxscdR1fQr624WgrW2LKNWgs0SJ83j0/TbWmGIDxgSrnundvItlL6sVmyz4PP
# UpmfA9gNNtL3sxel5OiKmm0IlM5htVBNF0qOswXkWZWGJ01JisQIP6jazb4ksYMx
# rlQamkDFEoQ0BB6rjW4V9KwvYF0Ax2NDMigVTzdX4v4+SuFu+4Zn3hlos0Gm1eE/
# o3ojNPznKLKdbWfjC5UAz5uc2mzoPCMle6xs1t/YZRDwsqn80+rhp+yonimP6QR0
# lS1jVEtm4kYxwW54WWJkj91l6Q0Gqg0C17pv+rdNTpjnJnhNXJp5cyhNU56E0X7Q
# oNUXiM/O+XVa6oRLFA==
# SIG # End signature block
