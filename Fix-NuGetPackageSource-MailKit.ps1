# Fix-NuGetPackageSource-MailKit.ps1
# Fix NuGet package source configuration for MailKit installation
# Week 5 Day 1 Hour 7-8: Credential Management - Package Source Fix
# Date: 2025-08-21

[CmdletBinding()]
param(
    [switch]$TestInstallation
)

Write-Host "=== NuGet Package Source Fix for MailKit ===" -ForegroundColor Cyan
Write-Host "Configuring NuGet package sources for MailKit installation" -ForegroundColor White
Write-Host ""

Write-Host "[DEBUG] [PackageSourceFix] Checking current package sources..." -ForegroundColor Gray

try {
    # Check current package sources
    $currentSources = Get-PackageSource -ErrorAction Stop
    Write-Host "[INFO] [PackageSourceFix] Current package sources:" -ForegroundColor White
    
    foreach ($source in $currentSources) {
        $status = if ($source.IsTrusted) { "TRUSTED" } else { "UNTRUSTED" }
        $color = if ($source.IsTrusted) { "Green" } else { "Yellow" }
        Write-Host "  [$status] $($source.Name): $($source.Location)" -ForegroundColor $color
    }
    
    # Check if NuGet.org source exists and is trusted
    $nugetSource = $currentSources | Where-Object { $_.Name -eq "nuget.org" -or $_.Location -like "*nuget.org*" }
    
    if (-not $nugetSource) {
        Write-Host ""
        Write-Host "[WARNING] [PackageSourceFix] NuGet.org package source not found, registering..." -ForegroundColor Yellow
        
        # Register NuGet.org package source
        Register-PackageSource -Name "nuget.org" -Location "https://api.nuget.org/v3/index.json" -ProviderName NuGet -Trusted -Force
        Write-Host "[SUCCESS] [PackageSourceFix] NuGet.org package source registered" -ForegroundColor Green
        
    } elseif (-not $nugetSource.IsTrusted) {
        Write-Host ""
        Write-Host "[WARNING] [PackageSourceFix] NuGet.org source found but not trusted, updating..." -ForegroundColor Yellow
        
        # Set as trusted
        Set-PackageSource -Name $nugetSource.Name -Trusted -Force
        Write-Host "[SUCCESS] [PackageSourceFix] NuGet.org package source set as trusted" -ForegroundColor Green
        
    } else {
        Write-Host ""
        Write-Host "[SUCCESS] [PackageSourceFix] NuGet.org package source already configured correctly" -ForegroundColor Green
    }
    
} catch {
    Write-Host "[ERROR] [PackageSourceFix] Failed to configure package sources: $($_.Exception.Message)" -ForegroundColor Red
    throw
}

Write-Host ""
Write-Host "[DEBUG] [PackageSourceFix] Testing MailKit package availability..." -ForegroundColor Gray

try {
    # Test if MailKit package can be found
    $mailKitPackage = Find-Package -Name "MailKit" -Source "nuget.org" -ErrorAction Stop
    
    if ($mailKitPackage) {
        Write-Host "[SUCCESS] [PackageSourceFix] MailKit package found: v$($mailKitPackage.Version)" -ForegroundColor Green
        Write-Host "[INFO] [PackageSourceFix] Package source: $($mailKitPackage.Source)" -ForegroundColor White
        Write-Host "[INFO] [PackageSourceFix] Package summary: $($mailKitPackage.Summary)" -ForegroundColor White
    }
    
} catch {
    Write-Host "[ERROR] [PackageSourceFix] MailKit package not found: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "[INFO] [PackageSourceFix] You may need to check internet connectivity or NuGet configuration" -ForegroundColor Gray
}

# Test installation if requested
if ($TestInstallation) {
    Write-Host ""
    Write-Host "[DEBUG] [PackageSourceFix] Testing MailKit installation..." -ForegroundColor Gray
    
    try {
        Write-Host "[INFO] [PackageSourceFix] Installing MailKit package..." -ForegroundColor White
        Install-Package -Name "MailKit" -Source "nuget.org" -Force -Scope CurrentUser -ErrorAction Stop
        
        $installedPackage = Get-Package -Name "MailKit" -ErrorAction Stop
        Write-Host "[SUCCESS] [PackageSourceFix] MailKit installed successfully: v$($installedPackage.Version)" -ForegroundColor Green
        
        # Check for MimeKit dependency
        $mimeKitPackage = Get-Package -Name "MimeKit" -ErrorAction SilentlyContinue
        if ($mimeKitPackage) {
            Write-Host "[SUCCESS] [PackageSourceFix] MimeKit dependency installed: v$($mimeKitPackage.Version)" -ForegroundColor Green
        }
        
    } catch {
        Write-Host "[ERROR] [PackageSourceFix] MailKit installation failed: $($_.Exception.Message)" -ForegroundColor Red
    }
}

Write-Host ""
Write-Host "=== Package Source Fix Summary ===" -ForegroundColor Cyan

# Final package source validation
$finalSources = Get-PackageSource
$nugetFinalSource = $finalSources | Where-Object { $_.Name -eq "nuget.org" -or $_.Location -like "*nuget.org*" }

if ($nugetFinalSource -and $nugetFinalSource.IsTrusted) {
    Write-Host "[SUCCESS] NuGet.org package source properly configured" -ForegroundColor Green
    Write-Host ""
    Write-Host "Next Steps:" -ForegroundColor White
    Write-Host "1. Run Install-MailKitForUnityClaudeAutomation.ps1 to install MailKit" -ForegroundColor Gray
    Write-Host "2. Or use -TestInstallation switch to test installation now" -ForegroundColor Gray
    Write-Host "3. After installation, run Test-Week5-Day1-EmailNotifications.ps1" -ForegroundColor Gray
} else {
    Write-Host "[WARNING] NuGet.org package source may need manual configuration" -ForegroundColor Yellow
    Write-Host "You may need to check internet connectivity or proxy settings" -ForegroundColor Gray
}

Write-Host ""
Write-Host "=== Package Source Fix Complete ===" -ForegroundColor Cyan
# SIG # Begin signature block
# MIIFqQYJKoZIhvcNAQcCoIIFmjCCBZYCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUppsmIY8AejagLcqyiOqxnnac
# XLOgggMwMIIDLDCCAhSgAwIBAgIQdR0W2SKoK5VE8JId4ZxrRTANBgkqhkiG9w0B
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
# CQQxFgQUSGkYHibGb+hNO2n2YIbLQj+QqAMwDQYJKoZIhvcNAQEBBQAEggEAQVBp
# l6ViNxKKw4RwRFWS+1j61h5XovJGKOSmThNEoBKeMhXC+lCFXWwaBfCzB/3PxbHr
# zwH8GlaLg11/jeGg4QSA5j5MIttxKcUnbggIKHIByB6bDPWAq51u/qyZ/Wb7YCuB
# X0vNNkxrFXhfVPFTPrgFpPU80JLJGoBpmVrxpelHCZiOFoZZItRxBpjGZma5YPzf
# W/haPgTjyerelMra6HqOhHNJkah4pKGeNnpijmb5DYDVjshmzRX4z8O+6eWryrJQ
# VFB0XHalILAc4H7alw+4WkqZnle3llkZqUsQYo/m9Au6/jLkqK8CZM7xZmKIkT1R
# 7kG4eX/tdnYylGGDLg==
# SIG # End signature block
