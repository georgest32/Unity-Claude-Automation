# Debug-SpecificLog.ps1
# Debug the specific Unity Editor.log path
# Date: 2025-08-18

$logPath = "C:\Users\georg\AppData\Local\Unity\Editor\Editor.log"

Write-Host "DEBUGGING SPECIFIC UNITY LOG PATH" -ForegroundColor Cyan
Write-Host "==================================" -ForegroundColor Cyan
Write-Host "Path: $logPath" -ForegroundColor White

# Test 1: File existence and basic info
Write-Host "Test 1: File information..." -ForegroundColor Yellow
if (Test-Path $logPath) {
    $logInfo = Get-Item $logPath
    Write-Host "  ✓ File exists" -ForegroundColor Green
    Write-Host "  Size: $($logInfo.Length) bytes" -ForegroundColor Gray
    Write-Host "  Last modified: $($logInfo.LastWriteTime)" -ForegroundColor Gray
    Write-Host "  Created: $($logInfo.CreationTime)" -ForegroundColor Gray
} else {
    Write-Host "  ✗ File does not exist at this path" -ForegroundColor Red
    return
}

# Test 2: Recent log content
Write-Host "" -ForegroundColor White
Write-Host "Test 2: Recent log content (last 15 lines)..." -ForegroundColor Yellow
$recentLines = Get-Content $logPath -Tail 15
$foundErrors = @()

foreach ($line in $recentLines) {
    if ($line -match "CS\d+:") {
        Write-Host "  COMPILATION ERROR: $line" -ForegroundColor Red
        $foundErrors += $line
    } elseif ($line -match "error") {
        Write-Host "  ERROR: $line" -ForegroundColor Yellow
    } else {
        Write-Host "  $line" -ForegroundColor Gray
    }
}

if ($foundErrors.Count -eq 0) {
    Write-Host "  ! No compilation errors found in recent log" -ForegroundColor Yellow
}

# Test 3: Monitor for changes in real-time
Write-Host "" -ForegroundColor White
Write-Host "Test 3: Real-time monitoring test..." -ForegroundColor Yellow
Write-Host "Monitoring $logPath for changes..." -ForegroundColor Gray
Write-Host "Make a change in Unity now and watch for detection!" -ForegroundColor Cyan

$initialSize = (Get-Item $logPath).Length
$startTime = Get-Date
$timeout = 30

Write-Host "Initial size: $initialSize bytes" -ForegroundColor Gray
Write-Host "Watching for $timeout seconds..." -ForegroundColor Gray

for ($i = 0; $i -lt $timeout; $i++) {
    Start-Sleep 1
    
    $currentSize = (Get-Item $logPath).Length
    if ($currentSize -ne $initialSize) {
        Write-Host "" -ForegroundColor White
        Write-Host "✓ LOG FILE CHANGED!" -ForegroundColor Green
        Write-Host "New size: $currentSize bytes (+$($currentSize - $initialSize))" -ForegroundColor Green
        
        # Read the new content
        $allContent = Get-Content $logPath -Raw
        $newContent = $allContent.Substring($initialSize)
        
        Write-Host "New content:" -ForegroundColor Cyan
        $newLines = $newContent -split "`n"
        foreach ($newLine in $newLines) {
            if ($newLine.Trim() -ne "") {
                if ($newLine -match "CS\d+:") {
                    Write-Host "  NEW COMPILATION ERROR: $newLine" -ForegroundColor Red
                } else {
                    Write-Host "  $newLine" -ForegroundColor White
                }
            }
        }
        
        # Check if autonomous system should detect this
        $errorPatterns = @("CS0103:", "CS0246:", "CS1061:", "CS0029:", "CS1002:")
        $detectedErrors = @()
        
        foreach ($pattern in $errorPatterns) {
            if ($newContent -match $pattern) {
                $matchingLines = $newLines | Where-Object { $_ -match $pattern }
                $detectedErrors += $matchingLines
            }
        }
        
        if ($detectedErrors.Count -gt 0) {
            Write-Host "" -ForegroundColor White
            Write-Host "🎯 AUTONOMOUS SYSTEM SHOULD DETECT THESE ERRORS:" -ForegroundColor Green
            foreach ($error in $detectedErrors) {
                Write-Host "  $error" -ForegroundColor Red
            }
        } else {
            Write-Host "" -ForegroundColor White
            Write-Host "⚠️  No compilation errors in new content - autonomous system won't trigger" -ForegroundColor Yellow
        }
        
        break
    }
    
    Write-Host "." -NoNewline -ForegroundColor Gray
    if ($i % 10 -eq 9) { Write-Host "" }
}

if ($currentSize -eq $initialSize) {
    Write-Host "" -ForegroundColor White
    Write-Host "No changes detected in $timeout seconds" -ForegroundColor Yellow
    Write-Host "Unity may not be writing to this log file" -ForegroundColor Yellow
}

Write-Host "" -ForegroundColor White
Write-Host "NEXT STEPS:" -ForegroundColor Cyan
Write-Host "1. If no changes detected: Unity isn't writing to this log" -ForegroundColor White
Write-Host "2. If changes but no errors: Create syntax errors in Unity scripts" -ForegroundColor White  
Write-Host "3. If errors detected: The autonomous system should work!" -ForegroundColor White

Write-Host "" -ForegroundColor White
Write-Host "Press Enter to exit..." -ForegroundColor Yellow
Read-Host
# SIG # Begin signature block
# MIIFqQYJKoZIhvcNAQcCoIIFmjCCBZYCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUNefyYEf72+S9JU7zrPpMwFKS
# /b+gggMwMIIDLDCCAhSgAwIBAgIQdR0W2SKoK5VE8JId4ZxrRTANBgkqhkiG9w0B
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
# CQQxFgQUjpgBxdIFbaPyxgbP6D7lSikthO4wDQYJKoZIhvcNAQEBBQAEggEAmOEM
# vWnKcoLtVFaeJhW7RUzALnwNBN5CzYV7ppQ2aRHy3Hj7npmAi0oF6V0OZPskU5Di
# gcRCWPI5P8mIztsCQlmoq/OX4PIGUitPdvftvQb6sYNMhVkrhhStZyiS7GOeCMSK
# TT3F161lnjbepVLCa+GGadMcmE3nugeskU6KIaXWdonPs9V5dpaYNuIiFA6zg3n9
# yVsSv/SGdvlBQFY2OpFH/6rL/4BOB+iIkpGuQKb/oELSkoVks9EAQraKsH9F9Afy
# xKpzxmbQZXiOZX/gYcUpLgN33EUTUS1b4PM/ySTVBpGQwtCZlHGYN3rOoqGWdeLm
# ElHMOm+oARGyB2C1/Q==
# SIG # End signature block
