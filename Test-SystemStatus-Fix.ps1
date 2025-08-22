# Test SystemStatus module fix
# Quick test to verify our Configuration and StatusFileManager fixes
# Date: 2025-08-20

$ErrorActionPreference = "Continue"

Write-Host "Testing SystemStatus Module Configuration Fix..." -ForegroundColor Cyan
Write-Host ""

# Set working directory
Set-Location "C:\UnityProjects\Sound-and-Shoal\Unity-Claude-Automation"

# Load the module from Modules directory
$modulePath = ".\Modules\Unity-Claude-SystemStatus\Unity-Claude-SystemStatus.psd1"
if (Test-Path $modulePath) {
    Write-Host "Loading SystemStatus module..." -ForegroundColor Yellow
    Import-Module $modulePath -Force -Global
    
    Write-Host "Module loaded successfully" -ForegroundColor Green
    Write-Host ""
    
    # Test 1: Check if configuration variables are populated
    Write-Host "Test 1: Configuration Variables" -ForegroundColor Yellow
    try {
        $config = Get-Variable -Scope Script -Name "SystemStatusConfig" -ErrorAction SilentlyContinue
        if ($config) {
            Write-Host "  SystemStatusConfig exists: " -NoNewline
            Write-Host "PASS" -ForegroundColor Green
            
            Write-Host "  SystemStatusFile path: $($config.Value.SystemStatusFile)" -ForegroundColor Gray
            Write-Host "  SystemStatusFile exists: " -NoNewline
            if (Test-Path $config.Value.SystemStatusFile) {
                Write-Host "YES" -ForegroundColor Green
            } else {
                Write-Host "NO (will be created)" -ForegroundColor Yellow
            }
        } else {
            Write-Host "  SystemStatusConfig: MISSING" -ForegroundColor Red
        }
    } catch {
        Write-Host "  Error checking configuration: $($_.Exception.Message)" -ForegroundColor Red
    }
    Write-Host ""
    
    # Test 2: Try Read-SystemStatus function
    Write-Host "Test 2: Read-SystemStatus Function" -ForegroundColor Yellow
    try {
        $status = Read-SystemStatus
        if ($status) {
            Write-Host "  Read-SystemStatus: " -NoNewline
            Write-Host "PASS" -ForegroundColor Green
            Write-Host "  Status data type: $($status.GetType().Name)" -ForegroundColor Gray
            Write-Host "  Status keys: $($status.Keys -join ', ')" -ForegroundColor Gray
        } else {
            Write-Host "  Read-SystemStatus returned null" -ForegroundColor Yellow
        }
    } catch {
        Write-Host "  Read-SystemStatus error: $($_.Exception.Message)" -ForegroundColor Red
    }
    Write-Host ""
    
    # Test 3: Try Write-SystemStatus function
    Write-Host "Test 3: Write-SystemStatus Function" -ForegroundColor Yellow
    try {
        $testData = @{
            timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss.fff'
            subsystems = @{
                TestSubsystem = @{
                    Status = "Running"
                    LastHeartbeat = Get-Date -Format 'yyyy-MM-dd HH:mm:ss.fff'
                    HealthScore = 1.0
                }
            }
            overall_health = "Good"
            SystemInfo = @{
                TestMode = $true
                LastUpdate = Get-Date -Format 'yyyy-MM-dd HH:mm:ss.fff'
            }
        }
        
        $writeResult = Write-SystemStatus -StatusData $testData
        if ($writeResult) {
            Write-Host "  Write-SystemStatus: " -NoNewline
            Write-Host "PASS" -ForegroundColor Green
        } else {
            Write-Host "  Write-SystemStatus: " -NoNewline
            Write-Host "FAILED" -ForegroundColor Red
        }
    } catch {
        Write-Host "  Write-SystemStatus error: $($_.Exception.Message)" -ForegroundColor Red
    }
    Write-Host ""
    
    # Test 4: Verify file was written correctly
    Write-Host "Test 4: File Write Verification" -ForegroundColor Yellow
    try {
        $config = Get-Variable -Scope Script -Name "SystemStatusConfig" -ErrorAction SilentlyContinue
        if ($config -and (Test-Path $config.Value.SystemStatusFile)) {
            $fileContent = Get-Content $config.Value.SystemStatusFile -Raw
            $parsedContent = $fileContent | ConvertFrom-Json
            
            if ($parsedContent.subsystems.TestSubsystem) {
                Write-Host "  File verification: " -NoNewline
                Write-Host "PASS" -ForegroundColor Green
                Write-Host "  TestSubsystem found in file" -ForegroundColor Gray
            } else {
                Write-Host "  File verification: " -NoNewline
                Write-Host "FAILED - TestSubsystem not found" -ForegroundColor Red
            }
        } else {
            Write-Host "  File not found for verification" -ForegroundColor Yellow
        }
    } catch {
        Write-Host "  File verification error: $($_.Exception.Message)" -ForegroundColor Red
    }
    
} else {
    Write-Host "SystemStatus module not found at: $modulePath" -ForegroundColor Red
}

Write-Host ""
Write-Host "Test complete!" -ForegroundColor Cyan
# SIG # Begin signature block
# MIIFqQYJKoZIhvcNAQcCoIIFmjCCBZYCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQU+FV3/dDt51Zxe8+/rp9VGjU5
# BSegggMwMIIDLDCCAhSgAwIBAgIQdR0W2SKoK5VE8JId4ZxrRTANBgkqhkiG9w0B
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
# CQQxFgQUZoBai7BtdAEXAypxlOUQWoK9j0swDQYJKoZIhvcNAQEBBQAEggEAOztY
# Lsdyzo9MYSSAHw3nXwVx+k5jbB2oFPzfWODHyv61/GwvlY0wfnYl6uqn9v5E9uHH
# lvp+dW4v3ViRPHNB+aeNcQSPmCrWyIO71V50Qd5/rSiD0X8NNGfJ/ySCd1DsISA6
# 3w9MsEwRL52K/qU75u57WY2RKDZeIkF62MHYA3ceDOC0j2o7MfWx/HlzsYsoJMm4
# 7SJWawpXKTPtoNAS171PyziEUqd3/G6perW/dXLqQnSXB7wbMo1ngknSeXCXcJXm
# a3ZeXkU62eNDoaGsPy+7KQtDfVsx1V4CMgKj66VQrjc+s2DXB5/dNJBcsl/fngwh
# kZfZT5+XqggokGpNoA==
# SIG # End signature block
