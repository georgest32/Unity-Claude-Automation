# Install Universal Dashboard Community Edition
# For PowerShell 5.1 compatibility
# Week 2 Day 12-14 Implementation

Write-Host "=== Installing Universal Dashboard Community Edition ===" -ForegroundColor Yellow
Write-Host "This will install the free community edition for PowerShell 5.1" -ForegroundColor Cyan

# Check PowerShell version
$psVersion = $PSVersionTable.PSVersion
Write-Host "PowerShell Version: $($psVersion.Major).$($psVersion.Minor)" -ForegroundColor Gray

if ($psVersion.Major -lt 5) {
    Write-Error "PowerShell 5.0 or higher is required"
    exit 1
}

# Check if module is already installed
$existingModule = Get-Module -ListAvailable -Name UniversalDashboard.Community
if ($existingModule) {
    Write-Host "UniversalDashboard.Community is already installed:" -ForegroundColor Green
    Write-Host "  Version: $($existingModule.Version)" -ForegroundColor Gray
    Write-Host "  Path: $($existingModule.ModuleBase)" -ForegroundColor Gray
    
    $response = Read-Host "Do you want to update/reinstall? (Y/N)"
    if ($response -ne 'Y') {
        Write-Host "Installation skipped" -ForegroundColor Yellow
        exit 0
    }
}

# Set TLS to 1.2 for secure download
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

# Install NuGet provider if needed
$nugetProvider = Get-PackageProvider -Name NuGet -ErrorAction SilentlyContinue
if (-not $nugetProvider) {
    Write-Host "Installing NuGet provider..." -ForegroundColor Gray
    Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force -Scope CurrentUser
}

# Trust PSGallery repository
$psGallery = Get-PSRepository -Name PSGallery
if ($psGallery.InstallationPolicy -ne 'Trusted') {
    Write-Host "Setting PSGallery as trusted repository..." -ForegroundColor Gray
    Set-PSRepository -Name PSGallery -InstallationPolicy Trusted
}

# Install the module
try {
    Write-Host "`nInstalling UniversalDashboard.Community module..." -ForegroundColor Cyan
    Write-Host "This may take a few minutes..." -ForegroundColor Gray
    
    # Install for current user to avoid admin requirements
    Install-Module -Name UniversalDashboard.Community -Scope CurrentUser -Force -AllowClobber -SkipPublisherCheck
    
    # Verify installation
    $installed = Get-Module -ListAvailable -Name UniversalDashboard.Community
    if ($installed) {
        Write-Host "`n✓ UniversalDashboard.Community installed successfully!" -ForegroundColor Green
        Write-Host "  Version: $($installed.Version)" -ForegroundColor Gray
        Write-Host "  Path: $($installed.ModuleBase)" -ForegroundColor Gray
        
        # Import the module to verify it works
        Write-Host "`nTesting module import..." -ForegroundColor Cyan
        Import-Module UniversalDashboard.Community -ErrorAction Stop
        
        # List available commands
        $commands = Get-Command -Module UniversalDashboard.Community | Select-Object -First 10
        Write-Host "`nSample commands available:" -ForegroundColor Green
        $commands | ForEach-Object {
            Write-Host "  - $($_.Name)" -ForegroundColor Gray
        }
        
        Write-Host "`n✓ Module is ready to use!" -ForegroundColor Green
        Write-Host "Run Start-LearningDashboard.ps1 to launch the analytics dashboard" -ForegroundColor Yellow
        
    } else {
        Write-Error "Installation verification failed"
    }
    
} catch {
    Write-Error "Failed to install UniversalDashboard.Community: $_"
    Write-Host "`nTroubleshooting steps:" -ForegroundColor Yellow
    Write-Host "1. Run PowerShell as Administrator" -ForegroundColor Gray
    Write-Host "2. Check internet connectivity" -ForegroundColor Gray
    Write-Host "3. Clear module cache: Remove-Module UniversalDashboard.Community -Force" -ForegroundColor Gray
    Write-Host "4. Try manual installation from: https://www.powershellgallery.com/packages/UniversalDashboard.Community" -ForegroundColor Gray
    exit 1
}
# SIG # Begin signature block
# MIIFqQYJKoZIhvcNAQcCoIIFmjCCBZYCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUvI0xL2+rjw47R0SLtjRoLaVZ
# sJugggMwMIIDLDCCAhSgAwIBAgIQdR0W2SKoK5VE8JId4ZxrRTANBgkqhkiG9w0B
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
# CQQxFgQUbouIQMU/uqtx5CI5Y2gujnt7NvowDQYJKoZIhvcNAQEBBQAEggEAZf36
# DUUAHuWX+iPw6bDvVyR7IKRoUehCfhuWu98N4nWuq5yEKFW5lEpuVb5jqIbylJdV
# Y2ZyI1BQg5dJFnLPbuQkiHc0Car+QBwvTS1vsCXDuU47JCYy+i+FrU9NrUHKZehw
# lnglJn8eDFpZHHGBs1YpsamkJU5LtfprtKxAoUzDZeP7oEcz55tY8XFogYmws8FZ
# GIK3G2j79KphsdEdrPpO19SfKQKK0mVEiyJbfeRh37SK/eXhz1xdy8usWb6n5n1i
# sz8zT7Zp0pahjtmtOO0Oz1AMBRN57j9CJyb93nHox0U2HfG8tvFILUWa43C6tNMd
# 0uu9IX65az6f0w/qLw==
# SIG # End signature block
