# Trigger-UnityRecompile.ps1
# Triggers Unity recompilation by creating a trigger file that the AutoRecompileWatcher detects
# Date: 2025-08-17

[CmdletBinding()]
param(
    [Parameter()]
    [string]$ProjectPath = "C:\UnityProjects\Sound-and-Shoal\Dithering",
    
    [Parameter()]
    [switch]$WaitForCompletion,
    
    [Parameter()]
    [switch]$ShowErrors
)

Write-Host "=== Unity Recompilation Trigger ===" -ForegroundColor Cyan
Write-Host "Using file watcher trigger method" -ForegroundColor Yellow

# Set up paths
$automationDir = Join-Path $ProjectPath "AutomationLogs"
$triggerFile = Join-Path $automationDir "recompile.trigger"
$logFile = Join-Path $automationDir "recompilation.log"
$errorFile = Join-Path $automationDir "current_errors.json"

# Ensure directory exists
if (-not (Test-Path $automationDir)) {
    New-Item -ItemType Directory -Path $automationDir -Force | Out-Null
    Write-Host "[OK] Created automation directory" -ForegroundColor Green
}

# Check if Unity is running
$unityProcess = Get-Process Unity* -ErrorAction SilentlyContinue | 
                Where-Object { $_.MainWindowTitle -match "Unity" -or $_.ProcessName -eq "Unity" } |
                Select-Object -First 1

if (-not $unityProcess) {
    Write-Host "[WARNING] Unity doesn't appear to be running" -ForegroundColor Yellow
    Write-Host "The AutoRecompileWatcher needs Unity to be running to work" -ForegroundColor Yellow
}
else {
    Write-Host "[OK] Unity is running (PID: $($unityProcess.Id))" -ForegroundColor Green
}

# Get current log size for comparison
$logSizeBefore = 0
if (Test-Path $logFile) {
    $logSizeBefore = (Get-Item $logFile).Length
}

Write-Host ""
Write-Host "Creating trigger file..." -ForegroundColor Yellow

# Create the trigger file with timestamp
$timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss.fff"
$triggerContent = @"
Triggered by: Trigger-UnityRecompile.ps1
Time: $timestamp
Purpose: Force Unity recompilation
"@

Set-Content -Path $triggerFile -Value $triggerContent -Force

Write-Host "[OK] Trigger file created: $triggerFile" -ForegroundColor Green

# Wait a moment for the watcher to detect it
Start-Sleep -Milliseconds 500

# Check if trigger file was consumed (deleted by watcher)
if (-not (Test-Path $triggerFile)) {
    Write-Host "[OK] Trigger file was consumed by Unity watcher" -ForegroundColor Green
}
else {
    Write-Host "[WARNING] Trigger file still exists - watcher may not be running" -ForegroundColor Yellow
    Write-Host "Make sure AutoRecompileWatcher.cs is compiled in Unity" -ForegroundColor Yellow
}

# Monitor the log file for updates
if ($WaitForCompletion) {
    Write-Host ""
    Write-Host "Waiting for compilation to complete..." -ForegroundColor Yellow
    
    $maxWait = 30
    $waited = 0
    $compilationDetected = $false
    
    while ($waited -lt $maxWait) {
        Start-Sleep -Seconds 1
        $waited++
        
        if (Test-Path $logFile) {
            $logSizeAfter = (Get-Item $logFile).Length
            if ($logSizeAfter -gt $logSizeBefore) {
                if (-not $compilationDetected) {
                    Write-Host "[OK] Compilation activity detected" -ForegroundColor Green
                    $compilationDetected = $true
                }
                
                # Check for completion marker
                $lastLines = Get-Content $logFile -Tail 5
                if ($lastLines -match "COMPILATION FINISHED") {
                    Write-Host "[OK] Compilation completed!" -ForegroundColor Green
                    break
                }
            }
        }
        
        if ($waited % 5 -eq 0) {
            Write-Host "  Still waiting... ($waited/$maxWait seconds)" -ForegroundColor Gray
        }
    }
}

# Show recent log entries
if (Test-Path $logFile) {
    Write-Host ""
    Write-Host "Recent compilation events:" -ForegroundColor Cyan
    Get-Content $logFile -Tail 10 | ForEach-Object {
        if ($_ -match "ERROR") {
            Write-Host "  $_" -ForegroundColor Red
        }
        elseif ($_ -match "STARTED|FINISHED|TRIGGER") {
            Write-Host "  $_" -ForegroundColor Yellow
        }
        else {
            Write-Host "  $_" -ForegroundColor Gray
        }
    }
}

# Show errors if requested
if ($ShowErrors -and (Test-Path $errorFile)) {
    Write-Host ""
    Write-Host "Current compilation errors:" -ForegroundColor Cyan
    
    try {
        $errorData = Get-Content $errorFile | ConvertFrom-Json
        if ($errorData.count -gt 0) {
            Write-Host "Found $($errorData.count) errors:" -ForegroundColor Red
            $errorData.errors | Select-Object -First 5 | ForEach-Object {
                Write-Host "  $($_.file)($($_.line),$($_.column)): $($_.message)" -ForegroundColor Red
            }
            if ($errorData.count -gt 5) {
                Write-Host "  ... and $($errorData.count - 5) more errors" -ForegroundColor Gray
            }
        }
        else {
            Write-Host "No compilation errors!" -ForegroundColor Green
        }
    }
    catch {
        Write-Host "Could not parse error file" -ForegroundColor Yellow
    }
}

Write-Host ""
Write-Host "=== Trigger Complete ===" -ForegroundColor Green
Write-Host ""
Write-Host "Logs located at:" -ForegroundColor Gray
Write-Host "  Recompilation: $logFile" -ForegroundColor Gray
Write-Host "  Errors: $errorFile" -ForegroundColor Gray
Write-Host ""

exit 0
# SIG # Begin signature block
# MIIFqQYJKoZIhvcNAQcCoIIFmjCCBZYCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUAPqj/s0ckpFfa0870Q+G8n6D
# 8OSgggMwMIIDLDCCAhSgAwIBAgIQdR0W2SKoK5VE8JId4ZxrRTANBgkqhkiG9w0B
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
# CQQxFgQULNza0W+4ccWQ44GSMYLmntrW/lwwDQYJKoZIhvcNAQEBBQAEggEAbC2/
# VMyQ5TNbC+6Ebu3kCAwZVFlTRNsSBBf3C0VunZljNxo8+h06MjRWU+dqdV7zv5Ei
# wtWwN29eBhxXUYHyW0DhUT6Js9tCsmuo5Kkz6RWtlKBP8agpH53ic3H2JlxFiXlF
# sFiGKwCl1I6yv2TyEMrbkAbXIPz9kKnsiQjcYbWb5SvUw1Q1Lau/OZtWoqyt4fxu
# w9zEHtmYDcqMuhEp66MEwZ8uGX+S1FKO12FrP60RuQkomayDXhGl3n1Fx3Y+m8xF
# ijxKfzZb4A7wTb1nCRYM96wfDL4oi5dUKa0RsT11FwFND2yYiuu4Ya2RelsDeqoS
# Rncuymgrl6YLUlfOLA==
# SIG # End signature block
