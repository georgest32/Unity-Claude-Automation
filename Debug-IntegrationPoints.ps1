# Debug-IntegrationPoints.ps1
# Detailed diagnostic to understand why integration point tests are failing

Write-Host "=== Integration Point Debug Diagnostics ===" -ForegroundColor Cyan
Write-Host "Starting at: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss.fff')" -ForegroundColor Gray
Write-Host "Current Directory: $(Get-Location)" -ForegroundColor Gray
Write-Host "PowerShell Version: $($PSVersionTable.PSVersion)" -ForegroundColor Gray
Write-Host ""

# IP1: Check JSON file
Write-Host "IP1 - JSON Format Check:" -ForegroundColor Yellow
$jsonFile = ".\system_status.json"
$fullPath = (Resolve-Path $jsonFile -ErrorAction SilentlyContinue)
Write-Host "  Looking for: $jsonFile" -ForegroundColor Gray
Write-Host "  Full path would be: $fullPath" -ForegroundColor Gray
if (Test-Path $jsonFile) {
    Write-Host "  ✓ File exists: $jsonFile" -ForegroundColor Green
    $fileInfo = Get-Item $jsonFile
    Write-Host "  File size: $($fileInfo.Length) bytes" -ForegroundColor Gray
    Write-Host "  Last modified: $($fileInfo.LastWriteTime)" -ForegroundColor Gray
    try {
        $content = Get-Content $jsonFile -Raw
        Write-Host "  Content length: $($content.Length) chars" -ForegroundColor Gray
        $json = $content | ConvertFrom-Json
        Write-Host "  ✓ JSON valid: Yes" -ForegroundColor Green
        Write-Host "  Has systemInfo: $($json.systemInfo -ne $null)" -ForegroundColor Cyan
        if ($json.systemInfo) {
            Write-Host "    - Keys: $($json.systemInfo.PSObject.Properties.Name -join ', ')" -ForegroundColor Gray
        }
        Write-Host "  Has subsystems: $($json.subsystems -ne $null)" -ForegroundColor Cyan
        if ($json.subsystems) {
            Write-Host "    - Type: $($json.subsystems.GetType().Name)" -ForegroundColor Gray
        }
        $result = ($json.systemInfo -ne $null -and $json.subsystems -ne $null)
        Write-Host "  Test evaluation: ($($json.systemInfo -ne $null)) AND ($($json.subsystems -ne $null)) = $result" -ForegroundColor Magenta
        Write-Host "  Would return: $result" -ForegroundColor $(if($result){"Green"}else{"Red"})
    } catch {
        Write-Host "  ✗ JSON parse error: $_" -ForegroundColor Red
        Write-Host "  Would return: False" -ForegroundColor Red
    }
} else {
    Write-Host "  ✗ File NOT found: $jsonFile" -ForegroundColor Red
    Write-Host "  Script would create the file and return: True" -ForegroundColor Yellow
}
Write-Host ""

# IP2: Check directories
Write-Host "IP2 - Directory Structure Check:" -ForegroundColor Yellow
$dirs = @(".\SessionData\Health", ".\SessionData\Watchdog")
$allExist = $true
foreach ($dir in $dirs) {
    $exists = Test-Path $dir
    $fullPath = (Resolve-Path $dir -ErrorAction SilentlyContinue)
    $symbol = if($exists){"✓"}else{"✗"}
    Write-Host "  $symbol $dir : $exists" -ForegroundColor $(if($exists){"Green"}else{"Red"})
    if ($fullPath) {
        Write-Host "    Full path: $fullPath" -ForegroundColor Gray
    } else {
        Write-Host "    Would be created at: $(Join-Path (Get-Location) $dir)" -ForegroundColor Gray
    }
    $allExist = $allExist -and $exists
}
Write-Host "  All directories exist: $allExist" -ForegroundColor Magenta
Write-Host "  Would return: $allExist" -ForegroundColor $(if($allExist){"Green"}else{"Red"})
Write-Host ""

# IP3: Check Write-SystemStatusLog
Write-Host "IP3 - Write-SystemStatusLog Check:" -ForegroundColor Yellow
Write-Host "  Importing module..." -ForegroundColor Gray
try {
    Import-Module ".\Modules\Unity-Claude-SystemStatus\Unity-Claude-SystemStatus.psd1" -Force -ErrorAction Stop
    Write-Host "  ✓ Module imported successfully" -ForegroundColor Green
} catch {
    Write-Host "  ✗ Module import failed: $_" -ForegroundColor Red
}
$cmd = Get-Command -Name "Write-SystemStatusLog" -ErrorAction SilentlyContinue
$result = ($cmd -ne $null)
Write-Host "  Command found: $result" -ForegroundColor $(if($result){"Green"}else{"Red"})
if ($cmd) {
    Write-Host "  Command type: $($cmd.CommandType)" -ForegroundColor Cyan
    Write-Host "  Module: $($cmd.Module.Name)" -ForegroundColor Cyan
    Write-Host "  Definition: $($cmd.Definition.Substring(0, [Math]::Min(100, $cmd.Definition.Length)))..." -ForegroundColor Gray
} else {
    # Check what functions ARE available
    $module = Get-Module "Unity-Claude-SystemStatus"
    if ($module) {
        $funcs = $module.ExportedFunctions.Keys | Select-Object -First 5
        Write-Host "  Module IS loaded, sample functions: $($funcs -join ', ')" -ForegroundColor Yellow
    }
}
Write-Host "  Test expression: \$null -ne (Get-Command 'Write-SystemStatusLog' -ErrorAction SilentlyContinue)" -ForegroundColor Gray
Write-Host "  Would return: $result" -ForegroundColor $(if($result){"Green"}else{"Red"})
Write-Host ""

# IP4: Check PID tracking
Write-Host "IP4 - PID Tracking Check:" -ForegroundColor Yellow
$currentPid = $PID
Write-Host "  Current PID: $currentPid" -ForegroundColor Cyan
$process = Get-Process -Id $currentPid -ErrorAction SilentlyContinue
$result = ($process -ne $null)
Write-Host "  Process found: $result" -ForegroundColor $(if($result){"Green"}else{"Red"})
if ($process) {
    Write-Host "  Process name: $($process.ProcessName)" -ForegroundColor Gray
    Write-Host "  Working set: $([Math]::Round($process.WorkingSet64/1MB, 2)) MB" -ForegroundColor Gray
} else {
    Write-Host "  ✗ Get-Process failed for PID $currentPid" -ForegroundColor Red
}
Write-Host "  Would return: $result" -ForegroundColor $(if($result){"Green"}else{"Red"})
Write-Host ""

# IP5: Module discovery (this one passes)
Write-Host "IP5 - Module Discovery Check:" -ForegroundColor Yellow
$modules = Get-Module -Name "Unity-Claude-*" -ListAvailable
Write-Host "  Modules found: $($modules.Count)" -ForegroundColor Green
Write-Host ""

# IP6: Timer creation
Write-Host "IP6 - Timer Pattern Check:" -ForegroundColor Yellow
try {
    $timer = New-Object System.Timers.Timer
    $timer.Interval = 1000
    Write-Host "  Timer created: $($timer -ne $null)" -ForegroundColor $(if($timer){"Green"}else{"Red"})
    if ($timer) {
        Write-Host "  Timer type: $($timer.GetType().Name)" -ForegroundColor Cyan
    }
} catch {
    Write-Host "  Timer creation error: $_" -ForegroundColor Red
}
Write-Host ""

# IP7: Named Pipes
Write-Host "IP7 - Named Pipes Check:" -ForegroundColor Yellow
try {
    Add-Type -AssemblyName System.Core
    Write-Host "  Assembly loaded: True" -ForegroundColor Green
} catch {
    Write-Host "  Assembly load error: $_" -ForegroundColor Red
}
Write-Host ""

# IP8: JSON conversion
Write-Host "IP8 - Message Protocol Check:" -ForegroundColor Yellow
$message = @{
    messageType = "Test"
    timestamp = (Get-Date -Format 'yyyy-MM-dd HH:mm:ss.fff')
    source = "TestScript"
    target = "SystemStatus"
    payload = @{ test = $true }
}
$json = $message | ConvertTo-Json
Write-Host "  JSON created: $($json -ne $null)" -ForegroundColor $(if($json){"Green"}else{"Red"})
if ($json) {
    Write-Host "  JSON length: $($json.Length) chars" -ForegroundColor Cyan
}
Write-Host ""

# IP9: FileSystemWatcher
Write-Host "IP9 - FileSystemWatcher Check:" -ForegroundColor Yellow
try {
    $watcher = New-Object System.IO.FileSystemWatcher
    $watcher.Path = ".\"
    Write-Host "  Watcher created: $($watcher -ne $null)" -ForegroundColor $(if($watcher){"Green"}else{"Red"})
} catch {
    Write-Host "  Watcher creation error: $_" -ForegroundColor Red
}
Write-Host ""

# IP10-14, 16: Check specific functions
Write-Host "Function Existence Checks:" -ForegroundColor Yellow
$functionsToCheck = @(
    "Send-HeartbeatRequest",      # IP10
    "Test-ProcessPerformanceHealth", # IP12
    "Invoke-CircuitBreakerCheck",   # IP13
    "Get-ServiceDependencyGraph",   # IP14
    "Initialize-SubsystemRunspaces" # IP16
)

foreach ($func in $functionsToCheck) {
    $cmd = Get-Command -Name $func -ErrorAction SilentlyContinue
    Write-Host "  $func : $($cmd -ne $null)" -ForegroundColor $(if($cmd){"Green"}else{"Red"})
}
Write-Host ""

# IP11: Threshold check (simple)
Write-Host "IP11 - Threshold Check:" -ForegroundColor Yellow
$thresholds = @{
    CriticalCpuPercentage = 70
    CriticalMemoryMB = 800
    WarningCpuPercentage = 50
}
$result = ($thresholds.CriticalCpuPercentage -eq 70)
Write-Host "  Threshold test: $result" -ForegroundColor $(if($result){"Green"}else{"Red"})
Write-Host ""

# IP15: SafeCommandExecution (should always pass)
Write-Host "IP15 - SafeCommandExecution Check:" -ForegroundColor Yellow
$safeExec = Get-Module -Name "SafeCommandExecution" -ListAvailable -ErrorAction SilentlyContinue
Write-Host "  Module exists: $($safeExec -ne $null)" -ForegroundColor Cyan
Write-Host "  Test always returns: True (graceful fallback design)" -ForegroundColor Green
# But let's check what the actual test does
Write-Host "  Actual test code just returns: \$true" -ForegroundColor Gray
Write-Host "  BUT the test is returning: False (WHY?)" -ForegroundColor Red
Write-Host ""

# Summary
Write-Host "=== Summary ===" -ForegroundColor Cyan
Write-Host "Tests that SHOULD pass but are failing:" -ForegroundColor Yellow
Write-Host "  - IP4: PID tracking (basic PowerShell functionality)" -ForegroundColor Red
Write-Host "  - IP6: Timer creation (basic .NET functionality)" -ForegroundColor Red
Write-Host "  - IP7: System.Core assembly (should already be loaded)" -ForegroundColor Red
Write-Host "  - IP8: JSON conversion (basic PowerShell functionality)" -ForegroundColor Red
Write-Host "  - IP9: FileSystemWatcher (basic .NET functionality)" -ForegroundColor Red
Write-Host "  - IP11: Simple hashtable comparison" -ForegroundColor Red
Write-Host "  - IP15: Hardcoded to return true" -ForegroundColor Red
Write-Host ""
Write-Host "Hypothesis: The test scriptblocks may be executing in a different context" -ForegroundColor Magenta
Write-Host "          or the return values are being lost/modified somehow." -ForegroundColor Magenta
Write-Host ""
Write-Host "=== End Diagnostics ===" -ForegroundColor Cyan
# SIG # Begin signature block
# MIIFqQYJKoZIhvcNAQcCoIIFmjCCBZYCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUR1eZvkNHHUpApRbtQ79en+Bx
# evGgggMwMIIDLDCCAhSgAwIBAgIQdR0W2SKoK5VE8JId4ZxrRTANBgkqhkiG9w0B
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
# CQQxFgQU/E91iXT5hOXEqlTlJ9xQXPCcnOcwDQYJKoZIhvcNAQEBBQAEggEAEqP6
# CYcHBbqd4/m6mXWdM35n4HY0Zrb+i5rzWCER1MAk2hcTmT4R+/h5ega3GtljrzSv
# eMU2LBpzsbQu1bq14O+qrUAtux8Edtd/tESQj2zE1O30gnciiojEWWfFDBlZ5YGR
# CgPNy0cx055axxql7by+dUPPlgjD29xBQVFJjG/1pIu8cXw1q3yKmu2kK8XlZ9Vo
# CH+uqSpXgejAFo5bjSYUv3gDL+PvQ+C/D+NoaP8T340R/5H8D/0TFwQ/PwRDp0nS
# fL3+0bof53X7FKByBvgz2xHvOAHNLUeYN3BT8qUeU35ZktSxWW7Me7ppg6uX4UW7
# 6PvuSf9/k3WB/BVJXg==
# SIG # End signature block
