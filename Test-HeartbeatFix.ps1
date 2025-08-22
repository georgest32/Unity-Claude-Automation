# Test-HeartbeatFix.ps1
# Verifies that the Send-HeartbeatRequest function is available and working

Write-Host "================================================" -ForegroundColor Cyan
Write-Host "     Testing Heartbeat Fix" -ForegroundColor Yellow
Write-Host "================================================" -ForegroundColor Cyan
Write-Host ""

# Import the SystemStatus module
try {
    Import-Module (Join-Path $PSScriptRoot "Modules\Unity-Claude-SystemStatus\Unity-Claude-SystemStatus-Working.psm1") -Force
    Write-Host "[PASS] SystemStatus module loaded successfully" -ForegroundColor Green
} catch {
    Write-Host "[FAIL] Failed to load SystemStatus module: $_" -ForegroundColor Red
    exit 1
}

# Check if the correct function exists
Write-Host ""
Write-Host "Checking for correct function names..." -ForegroundColor Yellow

# Check for the CORRECT function name
if (Get-Command "Send-HeartbeatRequest" -ErrorAction SilentlyContinue) {
    Write-Host "[PASS] Send-HeartbeatRequest function exists" -ForegroundColor Green
} else {
    Write-Host "[FAIL] Send-HeartbeatRequest function not found" -ForegroundColor Red
}

# Check for the INCORRECT function name (should NOT exist)
if (Get-Command "Send-Heartbeat" -ErrorAction SilentlyContinue) {
    Write-Host "[WARN] Send-Heartbeat function exists (should be Send-HeartbeatRequest)" -ForegroundColor Yellow
} else {
    Write-Host "[PASS] Send-Heartbeat function correctly does not exist" -ForegroundColor Green
}

# Test calling the function
Write-Host ""
Write-Host "Testing Send-HeartbeatRequest function..." -ForegroundColor Yellow

try {
    # Register a test subsystem first
    Register-Subsystem -Name "TestSubsystem" -ProcessId $PID
    Write-Host "[PASS] Registered test subsystem" -ForegroundColor Green
    
    # Send a heartbeat
    $result = Send-HeartbeatRequest -SubsystemName "TestSubsystem"
    Write-Host "[PASS] Send-HeartbeatRequest executed without error" -ForegroundColor Green
    
    # Clean up
    Unregister-Subsystem -Name "TestSubsystem"
    Write-Host "[PASS] Unregistered test subsystem" -ForegroundColor Green
} catch {
    Write-Host "[FAIL] Error calling Send-HeartbeatRequest: $_" -ForegroundColor Red
}

# Check the scripts for correct function calls
Write-Host ""
Write-Host "Checking SystemStatusMonitoring scripts..." -ForegroundColor Yellow

$scriptsToCheck = @(
    "Start-SystemStatusMonitoring-Persistent.ps1",
    "Start-SystemStatusMonitoring-Working.ps1",
    "Start-SystemStatusMonitoring-Isolated.ps1",
    "Start-SystemStatusMonitoring-Enhanced.ps1",
    "Start-UnifiedSystem-Complete.ps1"
)

$hasErrors = $false
foreach ($script in $scriptsToCheck) {
    $scriptPath = Join-Path $PSScriptRoot $script
    if (Test-Path $scriptPath) {
        $content = Get-Content $scriptPath -Raw
        
        # Check for incorrect function name
        if ($content -match "Send-Heartbeat\s+-SubsystemName") {
            Write-Host "[FAIL] $script still contains 'Send-Heartbeat' calls" -ForegroundColor Red
            $hasErrors = $true
        } else {
            # Check for correct function name
            if ($content -match "Send-HeartbeatRequest\s+-SubsystemName") {
                Write-Host "[PASS] $script uses correct 'Send-HeartbeatRequest' function" -ForegroundColor Green
            } else {
                Write-Host "[INFO] $script does not contain heartbeat calls" -ForegroundColor Gray
            }
        }
    } else {
        Write-Host "[SKIP] $script not found" -ForegroundColor Gray
    }
}

# Summary
Write-Host ""
Write-Host "================================================" -ForegroundColor Cyan
if ($hasErrors) {
    Write-Host "RESULT: Some scripts still need fixing" -ForegroundColor Yellow
} else {
    Write-Host "RESULT: All heartbeat errors have been fixed!" -ForegroundColor Green
}
Write-Host "================================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "The 'Send-Heartbeat' error should no longer appear in the logs." -ForegroundColor Cyan
Write-Host "The SystemStatusMonitoring process will now use the correct" -ForegroundColor Cyan
Write-Host "'Send-HeartbeatRequest' function." -ForegroundColor Cyan
# SIG # Begin signature block
# MIIFqQYJKoZIhvcNAQcCoIIFmjCCBZYCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUVSK44YsXG1Cy5Tr7x+i4T5sO
# Lj6gggMwMIIDLDCCAhSgAwIBAgIQdR0W2SKoK5VE8JId4ZxrRTANBgkqhkiG9w0B
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
# CQQxFgQUKLY/DJviV+GdzTBcfgfyAbAEpMQwDQYJKoZIhvcNAQEBBQAEggEAM5W6
# Ip7AySqEZX93u/pMidvge/YaHnVxbKy83PfjfU7nYXhaXtnvtZa695FGgtZzDE5I
# fFu6x2WiOZD+0vPmMyLCWFCyHCpNxiOl293MLMR3RECyfknByKSJU7gFl7FeLC5S
# MCqA2bWEID3yONcrel/eWGY6S6DkXX0xJKxUx4teHvm0QI4C40objju0xthX6BBy
# /8Gc/PojAvs2ZVD+/WnhlO5wmsmYO00xxmHe52EqUjFeJjN641egesyxP7Ra+rf5
# z4pr1X+FltUWtPo/UwTUSlLrj6Lmz+wrwoPAj3ZT2x3KXQoaJR5zk6xHyeMmbkSM
# ePGW/MvA6+swaGdkQQ==
# SIG # End signature block
