# Day 18: System Status Monitoring Prerequisites Validation
# PowerShell 5.1 compatibility and system readiness check
# Date: 2025-08-19

Write-Host "=== Day 18 Prerequisites Validation ===" -ForegroundColor Cyan
Write-Host "Checking system readiness for System Status Monitoring implementation..." -ForegroundColor White

# 1. PowerShell Version Check
Write-Host "`n1. PowerShell Version Check:" -ForegroundColor Yellow
$psVersion = $PSVersionTable.PSVersion
Write-Host "   PowerShell Version: $($psVersion.ToString())" -ForegroundColor White
if ($psVersion.Major -ge 5) {
    Write-Host "   [OK] PowerShell 5.1+ requirement met" -ForegroundColor Green
} else {
    Write-Host "   [FAIL] PowerShell 5.1+ required for compatibility" -ForegroundColor Red
}

# 2. Test-Json Cmdlet Availability (PowerShell 6.1+ feature)
Write-Host "`n2. JSON Validation Capability:" -ForegroundColor Yellow
$testJsonCmd = Get-Command Test-Json -ErrorAction SilentlyContinue
if ($testJsonCmd) {
    Write-Host "   [OK] Test-Json cmdlet available (PowerShell 6.1+)" -ForegroundColor Green
    Write-Host "   Version: $($testJsonCmd.Version)" -ForegroundColor White
    Write-Host "   Source: $($testJsonCmd.Source)" -ForegroundColor White
} else {
    # Test-Json is not available in PowerShell 5.1, but we have a fallback
    Write-Host "   [INFO] Test-Json cmdlet not available in PowerShell 5.1" -ForegroundColor Cyan
    Write-Host "   [OK] Using PowerShell 5.1 compatible structural validation instead" -ForegroundColor Green
    
    # Test our fallback validation works
    try {
        $testJson = '{"test":"value"}' | ConvertFrom-Json
        $testHashtable = @{test="value"}
        $testJsonString = $testHashtable | ConvertTo-Json -Depth 10
        $testParse = $testJsonString | ConvertFrom-Json
        Write-Host "   [OK] JSON parsing and validation fallback operational" -ForegroundColor Green
    } catch {
        Write-Host "   [FAIL] JSON parsing fallback failed: $($_.Exception.Message)" -ForegroundColor Red
    }
}

# 3. Existing Module Dependencies Check
Write-Host "`n3. Unity-Claude Module Dependencies:" -ForegroundColor Yellow
$projectRoot = "C:\UnityProjects\Sound-and-Shoal\Unity-Claude-Automation"
$modulesPath = Join-Path $projectRoot "Modules"

$criticalModules = @(
    "Unity-Claude-Core\Unity-Claude-Core.psm1",
    "Unity-Claude-AutonomousStateTracker-Enhanced.psm1", 
    "Unity-Claude-IntegrationEngine.psm1",
    "Unity-Claude-IPC-Bidirectional\Unity-Claude-IPC-Bidirectional.psm1",
    "Unity-Claude-Errors\Unity-Claude-Errors.psm1"
)

foreach ($module in $criticalModules) {
    $modulePath = Join-Path $modulesPath $module
    if (Test-Path $modulePath) {
        Write-Host "   [OK] $module found" -ForegroundColor Green
        try {
            # Try to get module info without importing to avoid conflicts
            $moduleInfo = Test-ModuleManifest -Path $modulePath -ErrorAction SilentlyContinue
            if ($moduleInfo) {
                Write-Host "      Version: $($moduleInfo.Version)" -ForegroundColor Gray
            }
        } catch {
            Write-Host "      (Module manifest check skipped)" -ForegroundColor Gray
        }
    } else {
        Write-Host "   [FAIL] $module NOT FOUND" -ForegroundColor Red
    }
}

# 4. File System Readiness Check
Write-Host "`n4. File System Readiness:" -ForegroundColor Yellow

# Check SessionData directory
$sessionDataPath = Join-Path $projectRoot "SessionData"
if (Test-Path $sessionDataPath) {
    Write-Host "   [OK] SessionData directory exists" -ForegroundColor Green
    
    # Check subdirectories
    $subdirs = @("States", "Sessions", "Checkpoints")
    foreach ($subdir in $subdirs) {
        $subdirPath = Join-Path $sessionDataPath $subdir
        if (Test-Path $subdirPath) {
            Write-Host "   [OK] SessionData\$subdir exists" -ForegroundColor Green
        } else {
            Write-Host "   [FAIL] SessionData\$subdir missing" -ForegroundColor Red
        }
    }
    
    # Check if we need to create new directories
    $newDirs = @("Health", "Watchdog")
    foreach ($newDir in $newDirs) {
        $newDirPath = Join-Path $sessionDataPath $newDir
        if (Test-Path $newDirPath) {
            Write-Host "   [OK] SessionData\$newDir already exists" -ForegroundColor Green
        } else {
            Write-Host "   [INFO] SessionData\$newDir will be created" -ForegroundColor Cyan
        }
    }
} else {
    Write-Host "   [FAIL] SessionData directory missing (required for status monitoring)" -ForegroundColor Red
}

# Check disk space on C: drive
Write-Host "`n5. Disk Space Check:" -ForegroundColor Yellow
try {
    $disk = Get-WmiObject -Class Win32_LogicalDisk | Where-Object {$_.DeviceID -eq "C:"}
    $freeSpaceGB = [math]::Round($disk.FreeSpace / 1GB, 2)
    Write-Host "   Free space on C: drive: $freeSpaceGB GB" -ForegroundColor White
    if ($freeSpaceGB -gt 1) {
        Write-Host "   [OK] Sufficient disk space available" -ForegroundColor Green
    } else {
        Write-Host "   [WARN] Low disk space - recommend cleanup" -ForegroundColor Yellow
    }
} catch {
    Write-Host "   [WARN] Could not check disk space: $($_.Exception.Message)" -ForegroundColor Yellow
}

# 6. JSON File Format Compatibility Check
Write-Host "`n6. Existing JSON File Compatibility:" -ForegroundColor Yellow
$unityErrorsJson = Join-Path $projectRoot "unity_errors_safe.json"
if (Test-Path $unityErrorsJson) {
    Write-Host "   [OK] unity_errors_safe.json exists (reference format)" -ForegroundColor Green
    try {
        $jsonContent = Get-Content $unityErrorsJson -Raw | ConvertFrom-Json
        Write-Host "   [OK] JSON parsing successful" -ForegroundColor Green
        if ($jsonContent.exportTime) {
            Write-Host "   [OK] DateTime format pattern found: $($jsonContent.exportTime)" -ForegroundColor Green
        }
    } catch {
        Write-Host "   [WARN] JSON parsing issue: $($_.Exception.Message)" -ForegroundColor Yellow
    }
} else {
    Write-Host "   [WARN] unity_errors_safe.json not found (reference file for format compatibility)" -ForegroundColor Yellow
}

# 7. Write Permissions Test
Write-Host "`n7. Write Permissions Test:" -ForegroundColor Yellow
$testFile = Join-Path $projectRoot "test_write_permissions.tmp"
try {
    "test" | Out-File -FilePath $testFile -ErrorAction Stop
    Remove-Item $testFile -ErrorAction SilentlyContinue
    Write-Host "   [OK] Write permissions confirmed" -ForegroundColor Green
} catch {
    Write-Host "   [FAIL] Write permission denied: $($_.Exception.Message)" -ForegroundColor Red
}

# Summary
Write-Host "`n=== Prerequisites Validation Summary ===" -ForegroundColor Cyan
Write-Host "System readiness assessment complete." -ForegroundColor White
Write-Host "Review any [FAIL] or [WARN] items above before proceeding with Day 18 implementation." -ForegroundColor White
Write-Host "`nIf all critical items show [OK], system is ready for Day 18 System Status Monitoring implementation." -ForegroundColor Green
# SIG # Begin signature block
# MIIFqQYJKoZIhvcNAQcCoIIFmjCCBZYCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUd7kOSS/belMNI5/kiKZdx/b3
# UWOgggMwMIIDLDCCAhSgAwIBAgIQdR0W2SKoK5VE8JId4ZxrRTANBgkqhkiG9w0B
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
# CQQxFgQU8B0myLJvbwCBPXwnEwU/tAGBR3kwDQYJKoZIhvcNAQEBBQAEggEAmyqD
# 50guE8d6CfEIDRPTDA8Z9adhtJauC2dJUNKpTgQWxD217kau1IeCZ1lH9g6psNTW
# Eqbyw9rISKO+BDaFVTvkLAWY8ILZ/RLa+Plvv7kxAx3dvpiv6wQB+baohEYr1W5x
# 3RiLfoIuah5eJxAWYBaAtiC/748yriptig4b9Eob4ZfhFcjYBfU1zUUrDpAk7CXF
# 5XhqhRv8OpZ6gLpZVMSvqki1qruiyEsDGtYciHDXF0cRFxo9gjAl0Vvdzb4jRJT/
# vTTIH+OOQKRiAcCgN8AqjNLIg/5p69vBS9CKlrho/fflEJ5ObVpJpdj5qEhSuIk+
# ly1Y0UykN2WxXxbsfQ==
# SIG # End signature block
