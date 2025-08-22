# Force-UnityRefresh.ps1
# Forces Unity to refresh and recompile using keyboard shortcuts
# Works when Unity is the active window
# Date: 2025-08-17

[CmdletBinding()]
param(
    [Parameter()]
    [switch]$ForceReimport
)

Write-Host "=== Unity Force Refresh ===" -ForegroundColor Cyan
Write-Host "Sending refresh command to Unity..." -ForegroundColor Yellow

# Check if Unity is running
$unity = Get-Process Unity* -ErrorAction SilentlyContinue | 
         Where-Object { $_.MainWindowTitle -match "Unity" -or $_.ProcessName -eq "Unity" } |
         Select-Object -First 1

if (-not $unity) {
    Write-Host "[ERROR] Unity is not running!" -ForegroundColor Red
    exit 1
}

Write-Host "[OK] Found Unity process (PID: $($unity.Id))" -ForegroundColor Green

# Load SendKeys assembly
Add-Type -AssemblyName System.Windows.Forms

# Get Editor.log info before refresh
$editorLog = Join-Path $env:LOCALAPPDATA 'Unity\Editor\Editor.log'
$beforeSize = 0
$beforeTime = $null
if (Test-Path $editorLog) {
    $beforeSize = (Get-Item $editorLog).Length
    $beforeTime = (Get-Item $editorLog).LastWriteTime
    Write-Host "[INFO] Editor.log size before: $beforeSize bytes" -ForegroundColor Gray
}

Write-Host ""
Write-Host "Sending keyboard commands to Unity..." -ForegroundColor Yellow

if ($ForceReimport) {
    # Ctrl+Alt+Shift+R = Reimport All (forces full recompilation)
    Write-Host "  Sending: Ctrl+Alt+Shift+R (Reimport All)" -ForegroundColor Cyan
    [System.Windows.Forms.SendKeys]::SendWait("^%+r")
    Write-Host "  [OK] Reimport All triggered" -ForegroundColor Green
}
else {
    # Ctrl+R = Refresh (standard refresh)
    Write-Host "  Sending: Ctrl+R (Refresh)" -ForegroundColor Cyan
    [System.Windows.Forms.SendKeys]::SendWait("^r")
    Write-Host "  [OK] Refresh triggered" -ForegroundColor Green
    
    # Small delay then send again to ensure it's processed
    Start-Sleep -Milliseconds 500
    
    # Also try Assets menu refresh: Alt+A, then R
    Write-Host "  Sending: Alt+A, R (Assets > Refresh)" -ForegroundColor Cyan
    [System.Windows.Forms.SendKeys]::SendWait("%a")
    Start-Sleep -Milliseconds 200
    [System.Windows.Forms.SendKeys]::SendWait("r")
    Write-Host "  [OK] Assets menu refresh triggered" -ForegroundColor Green
}

Write-Host ""
Write-Host "Waiting for Unity to process..." -ForegroundColor Yellow
Start-Sleep -Seconds 3

# Check if Editor.log was updated
if (Test-Path $editorLog) {
    $afterSize = (Get-Item $editorLog).Length
    $afterTime = (Get-Item $editorLog).LastWriteTime
    
    if ($afterTime -gt $beforeTime) {
        Write-Host "[OK] Editor.log was updated" -ForegroundColor Green
        Write-Host "  Size: $beforeSize -> $afterSize bytes" -ForegroundColor Gray
        Write-Host "  Time: $beforeTime -> $afterTime" -ForegroundColor Gray
        
        # Check for compilation markers
        $tail = Get-Content $editorLog -Tail 20
        if ($tail -match "Refresh completed|Compilation|ImportManager") {
            Write-Host "[OK] Compilation activity detected in log" -ForegroundColor Green
        }
    }
    else {
        Write-Host "[WARNING] Editor.log was not updated" -ForegroundColor Yellow
        Write-Host "Unity may not have detected changes or may still be processing" -ForegroundColor Gray
    }
}

Write-Host ""
Write-Host "=== Refresh Complete ===" -ForegroundColor Green
Write-Host ""
Write-Host "Note: If Unity was not the active window, the commands may not have worked." -ForegroundColor Gray
Write-Host "Make sure Unity is focused before running this script." -ForegroundColor Gray
Write-Host ""

exit 0
# SIG # Begin signature block
# MIIFqQYJKoZIhvcNAQcCoIIFmjCCBZYCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUEOpPJRKcpvRb185kbUyPWohh
# wnSgggMwMIIDLDCCAhSgAwIBAgIQdR0W2SKoK5VE8JId4ZxrRTANBgkqhkiG9w0B
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
# CQQxFgQUB1QwlCJkoGdZg7A8QyoCa3Ej9IgwDQYJKoZIhvcNAQEBBQAEggEAn+GU
# ywawEBTpNGI9MdYifULeVR6CADlQ+SPDvJ1KnCyNtgk0scZ2G3cwC/Oz26y7RuFO
# plIuXJkQ/N+V/1qIHcUEktNtKevYVTgauOlqHy4aCBoDEAeWuehar7z4YBoeTjyH
# Q+jWhJy0FSN9plf9glGyUgFlyDljH8Nkd0g16hD/NKl4c3tIACKwibgrEXKmAa07
# a6yPQmMOl18XR3BdmHDwioRMHbBjhvHv+JGub5ZKwSTYmz5jzrgXMzCRy2ANRUzQ
# dyKzcnF8yskO5GVev4VpfaMTVC++9nC3TZy2yNQAbdDUMhwyAaNwQQcPAC24wQzU
# 5Cz6YCfXYKfGjDR13g==
# SIG # End signature block
