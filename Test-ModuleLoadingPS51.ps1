# Test-ModuleLoadingPS51.ps1
# Test script to verify all modules load without syntax errors in PowerShell 5.1
# Date: 2025-08-18

param(
    [switch]$Verbose
)

$ErrorActionPreference = "Continue"
$modules = @(
    "Unity-Claude-IntegrationEngine",
    "Unity-Claude-SessionManager", 
    "Unity-Claude-AutonomousStateTracker",
    "Unity-Claude-PerformanceOptimizer",
    "Unity-Claude-ConcurrentProcessor",
    "Unity-Claude-ResourceOptimizer"
)

Write-Host "Testing PowerShell 5.1 compatibility for Unity-Claude-Automation modules..." -ForegroundColor Cyan
Write-Host "PowerShell Version: $($PSVersionTable.PSVersion)" -ForegroundColor Yellow

$results = @()
$loadedModules = @()

foreach ($moduleName in $modules) {
    Write-Host "`nTesting module: $moduleName" -ForegroundColor White
    
    try {
        $modulePath = Join-Path $PSScriptRoot "Modules\$moduleName.psm1"
        
        if (-not (Test-Path $modulePath)) {
            Write-Host "  ❌ Module file not found: $modulePath" -ForegroundColor Red
            $results += @{ Module = $moduleName; Success = $false; Error = "File not found" }
            continue
        }
        
        # Try to import the module
        Import-Module $modulePath -Force -DisableNameChecking -ErrorAction Stop
        
        Write-Host "  ✅ Successfully loaded $moduleName" -ForegroundColor Green
        $loadedModules += $moduleName
        $results += @{ Module = $moduleName; Success = $true; Error = $null }
        
    } catch {
        Write-Host "  ❌ Failed to load $moduleName" -ForegroundColor Red
        Write-Host "     Error: $($_.Exception.Message)" -ForegroundColor Red
        
        if ($Verbose) {
            Write-Host "     Full Error:" -ForegroundColor Yellow
            Write-Host "     $($_.Exception.ToString())" -ForegroundColor Yellow
        }
        
        $results += @{ Module = $moduleName; Success = $false; Error = $_.Exception.Message }
    }
}

# Summary
Write-Host "`n" + "="*60 -ForegroundColor Cyan
Write-Host "SUMMARY" -ForegroundColor Cyan
Write-Host "="*60 -ForegroundColor Cyan

$successCount = ($results | Where-Object { $_.Success }).Count
$totalCount = $results.Count

Write-Host "Modules tested: $totalCount" -ForegroundColor White
Write-Host "Successfully loaded: $successCount" -ForegroundColor Green
Write-Host "Failed to load: $($totalCount - $successCount)" -ForegroundColor Red

if ($successCount -eq $totalCount) {
    Write-Host "`n🎉 ALL MODULES LOADED SUCCESSFULLY!" -ForegroundColor Green
    Write-Host "PowerShell 5.1 syntax errors have been fixed." -ForegroundColor Green
} else {
    Write-Host "`n⚠️ Some modules failed to load:" -ForegroundColor Yellow
    $results | Where-Object { -not $_.Success } | ForEach-Object {
        Write-Host "  - $($_.Module): $($_.Error)" -ForegroundColor Red
    }
}

# Cleanup - remove loaded modules
foreach ($module in $loadedModules) {
    try {
        Remove-Module $module -Force -ErrorAction SilentlyContinue
    } catch {
        # Ignore cleanup errors
    }
}

Write-Host "`nTest completed." -ForegroundColor Cyan
# SIG # Begin signature block
# MIIFqQYJKoZIhvcNAQcCoIIFmjCCBZYCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQU6x/hcgbF3TmHsDkbv9h8sdtu
# jUWgggMwMIIDLDCCAhSgAwIBAgIQdR0W2SKoK5VE8JId4ZxrRTANBgkqhkiG9w0B
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
# CQQxFgQUmvQlFGIr9zwGe2CfssdApLvcbaYwDQYJKoZIhvcNAQEBBQAEggEAh1FI
# W3BndBW+4hQ/L90BeM3o8b7HkXAw6cm+TpeVQ7Zbs7dvfCiHTLG1bTsz3LiQxi/s
# g55BNimZQmBduaoKMyPLcrniEaJy3z4UbDY+qamJ5UwZZADNXHdppg+DRWq7FGkx
# gWNUUkNW6iY/ymMKJ7eUt0qKiDnCzgXfL+Ic5uKD6sK+xL8v0ndc2c76XuseOeRC
# krProp7zVPz38opgaF5sfmuXb8gobFn/hOlUKOgPwaiSb/va43U1ZP49On9Eod8C
# 3T/4ckdKjbjZKWHILv5taTNa1tCqVPlrjYTs4W1V4PoZ1Nr15dscyskfjog83C6O
# +mibTY2J3RMHKCUW0Q==
# SIG # End signature block
