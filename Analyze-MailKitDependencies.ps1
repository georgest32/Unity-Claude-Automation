# Analyze-MailKitDependencies.ps1
# Analyze MailKit assembly loading issues and dependency requirements
# Investigate LoaderExceptions for detailed error information
# Date: 2025-08-21

[CmdletBinding()]
param()

Write-Host "=== MailKit Dependency Analysis ===" -ForegroundColor Cyan
Write-Host "Investigating assembly loading issues and dependency requirements" -ForegroundColor White
Write-Host ""

# Clear any previous errors
$Error.Clear()

Write-Host "=== Step 1: Detailed LoaderException Analysis ===" -ForegroundColor Yellow

try {
    # Find .NET Framework assemblies
    $basePath = "$env:ProgramFiles\PackageManagement\NuGet\Packages"
    $mailKitNet48 = "$basePath\MailKit.4.13.0\lib\net48\MailKit.dll"
    $mimeKitNet48 = "$basePath\MimeKit.4.13.0\lib\net48\MimeKit.dll"
    
    Write-Host "[DEBUG] Attempting to load MimeKit (.NET Framework 4.8)..." -ForegroundColor Gray
    Write-Host "Path: $mimeKitNet48" -ForegroundColor Gray
    
    try {
        Add-Type -Path $mimeKitNet48 -ErrorAction Stop
        Write-Host "[SUCCESS] MimeKit loaded successfully" -ForegroundColor Green
    } catch {
        Write-Host "[ERROR] MimeKit loading failed: $($_.Exception.Message)" -ForegroundColor Red
        
        # Analyze LoaderExceptions if available
        if ($Error[0].Exception.InnerException -and $Error[0].Exception.InnerException.LoaderExceptions) {
            Write-Host ""
            Write-Host "MimeKit LoaderExceptions:" -ForegroundColor Yellow
            foreach ($loaderEx in $Error[0].Exception.InnerException.LoaderExceptions) {
                Write-Host "  - $($loaderEx.Message)" -ForegroundColor Red
            }
        }
    }
    
    Write-Host ""
    Write-Host "[DEBUG] Attempting to load MailKit (.NET Framework 4.8)..." -ForegroundColor Gray
    Write-Host "Path: $mailKitNet48" -ForegroundColor Gray
    
    try {
        Add-Type -Path $mailKitNet48 -ErrorAction Stop
        Write-Host "[SUCCESS] MailKit loaded successfully" -ForegroundColor Green
    } catch {
        Write-Host "[ERROR] MailKit loading failed: $($_.Exception.Message)" -ForegroundColor Red
        
        # Analyze LoaderExceptions if available
        if ($Error[0].Exception.InnerException -and $Error[0].Exception.InnerException.LoaderExceptions) {
            Write-Host ""
            Write-Host "MailKit LoaderExceptions:" -ForegroundColor Yellow
            foreach ($loaderEx in $Error[0].Exception.InnerException.LoaderExceptions) {
                Write-Host "  - $($loaderEx.Message)" -ForegroundColor Red
            }
        }
    }
    
} catch {
    Write-Host "[ERROR] General assembly loading error: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host ""
Write-Host "=== Step 2: Dependency Package Analysis ===" -ForegroundColor Yellow

# Check what packages are installed and their dependencies
try {
    $installedPackages = Get-Package | Where-Object { $_.Name -like "*Mail*" -or $_.Name -like "*Mime*" }
    
    Write-Host "Installed Mail/Mime-related packages:" -ForegroundColor White
    foreach ($pkg in $installedPackages) {
        Write-Host "  $($pkg.Name) v$($pkg.Version) - $($pkg.Source)" -ForegroundColor Gray
    }
    
    # Check for other installed packages that might be dependencies
    $allPackages = Get-Package
    Write-Host ""
    Write-Host "Total installed packages: $($allPackages.Count)" -ForegroundColor White
    
    $systemPackages = $allPackages | Where-Object { $_.Name -like "System.*" }
    if ($systemPackages) {
        Write-Host "System.* packages found: $($systemPackages.Count)" -ForegroundColor White
        foreach ($sysPkg in $systemPackages) {
            Write-Host "  $($sysPkg.Name) v$($sysPkg.Version)" -ForegroundColor Gray
        }
    }
    
} catch {
    Write-Host "[ERROR] Package analysis failed: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host ""
Write-Host "=== Step 3: Alternative Solutions Analysis ===" -ForegroundColor Yellow

Write-Host "Analysis Results:" -ForegroundColor White
Write-Host ""

Write-Host "Issue Identified:" -ForegroundColor Red
Write-Host "- MailKit 4.13.0 assemblies may have unresolved .NET dependencies" -ForegroundColor Gray
Write-Host "- PowerShell 5.1 cannot load assemblies with missing dependencies" -ForegroundColor Gray
Write-Host "- .NET Framework vs .NET 8.0 dependency conflicts" -ForegroundColor Gray

Write-Host ""
Write-Host "Recommended Solutions:" -ForegroundColor Green

Write-Host "1. Install Older MailKit Version (RECOMMENDED):" -ForegroundColor Yellow
Write-Host "   Uninstall-Package MailKit -Force" -ForegroundColor Gray
Write-Host "   Install-Package MailKit -RequiredVersion 3.4.3 -Source https://www.nuget.org/api/v2" -ForegroundColor Gray
Write-Host "   (Version 3.4.3 has better PowerShell 5.1 compatibility)" -ForegroundColor Gray

Write-Host ""
Write-Host "2. Use Alternative Email Method:" -ForegroundColor Yellow
Write-Host "   System.Net.Mail.SmtpClient (deprecated but functional)" -ForegroundColor Gray
Write-Host "   Direct Invoke-RestMethod to email service APIs" -ForegroundColor Gray

Write-Host ""
Write-Host "3. Upgrade to PowerShell 7 (if possible):" -ForegroundColor Yellow
Write-Host "   Modern PowerShell has better .NET assembly support" -ForegroundColor Gray
Write-Host "   But this changes system requirements significantly" -ForegroundColor Gray

Write-Host ""
Write-Host "=== Analysis Complete ===" -ForegroundColor Cyan

Write-Host ""
Write-Host "Next Steps:" -ForegroundColor White
Write-Host "1. Try installing MailKit 3.4.3 for better PowerShell 5.1 compatibility" -ForegroundColor Gray
Write-Host "2. Or implement alternative email solution using System.Net.Mail" -ForegroundColor Gray
Write-Host "3. Proceed with webhook notifications (which work fine in PowerShell 5.1)" -ForegroundColor Gray
# SIG # Begin signature block
# MIIFqQYJKoZIhvcNAQcCoIIFmjCCBZYCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUE9xhYN457x5CaXwzBtS/ITB5
# ZXKgggMwMIIDLDCCAhSgAwIBAgIQdR0W2SKoK5VE8JId4ZxrRTANBgkqhkiG9w0B
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
# CQQxFgQU0cBe38RiThUZttCcTwqWvQIcY0YwDQYJKoZIhvcNAQEBBQAEggEAD448
# Ex4RH+Zmqe9hcIo+Ceb6Az7hzYzP2YCUej0VAMBVNyisc24KFRzFTpK+NQnnmV24
# tFigV8hR5FCL6oPt3foqaChzEbx8YN//hQNXBJwRjCGYOvSFOj23wJW8JcKL/ifj
# xT44TicBJV29+fbUd/FF7acIcC+AS82kF8LDdA4DJcTiqDxxS/K+8oxBA/Vfypd1
# cbr3kUooaczuegKC60LmYBwlIwHvHWKhkZke9Mtj41GX4zs1cZsLxLeLu0xuHWPf
# y4RQ+Rw4nCioRj4EI40vJCShgJHIqblwIHV2YbrP77nZCi4o0mAzUkjZWrLu00SJ
# B5s3Hzcemxu/S6moPA==
# SIG # End signature block
