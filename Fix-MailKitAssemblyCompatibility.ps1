# Fix-MailKitAssemblyCompatibility.ps1
# Fix MailKit assembly loading for PowerShell 5.1 .NET Framework compatibility
# Use .NET Framework assemblies instead of .NET 8.0 assemblies
# Date: 2025-08-21

[CmdletBinding()]
param()

Write-Host "=== MailKit Assembly Compatibility Fix ===" -ForegroundColor Cyan
Write-Host "Fixing .NET Framework compatibility for PowerShell 5.1" -ForegroundColor White
Write-Host ""

Write-Host "[DEBUG] [CompatibilityFix] PowerShell Version: $($PSVersionTable.PSVersion)" -ForegroundColor Gray
Write-Host "[DEBUG] [CompatibilityFix] CLR Version: $($PSVersionTable.CLRVersion)" -ForegroundColor Gray
Write-Host "[DEBUG] [CompatibilityFix] .NET Framework: $([System.Runtime.InteropServices.RuntimeInformation]::FrameworkDescription)" -ForegroundColor Gray

Write-Host ""
Write-Host "=== Step 1: Assembly Path Analysis ===" -ForegroundColor Yellow

try {
    # Search for MailKit installations
    $packageLocations = @(
        "$env:ProgramFiles\PackageManagement\NuGet\Packages",
        "$env:USERPROFILE\.nuget\packages",
        "$env:LOCALAPPDATA\Microsoft\Windows\PowerShell\NuGet\Packages"
    )
    
    $foundMailKitVersions = @()
    $foundMimeKitVersions = @()
    
    foreach ($location in $packageLocations) {
        if (Test-Path $location) {
            Write-Host "[DEBUG] [CompatibilityFix] Searching in: $location" -ForegroundColor Gray
            
            # Find all MailKit versions and target frameworks
            $mailKitDirs = Get-ChildItem "$location\MailKit*" -Directory -ErrorAction SilentlyContinue
            foreach ($mailKitDir in $mailKitDirs) {
                $libPath = Join-Path $mailKitDir.FullName "lib"
                if (Test-Path $libPath) {
                    $frameworks = Get-ChildItem $libPath -Directory -ErrorAction SilentlyContinue
                    foreach ($framework in $frameworks) {
                        $dllPath = Join-Path $framework.FullName "MailKit.dll"
                        if (Test-Path $dllPath) {
                            $foundMailKitVersions += @{
                                Version = $mailKitDir.Name.Replace("MailKit.", "")
                                Framework = $framework.Name
                                Path = $dllPath
                                Compatible = $framework.Name -match "^net4[6-8]"
                            }
                            Write-Host "[INFO] [CompatibilityFix] Found MailKit: $($mailKitDir.Name) ($($framework.Name))" -ForegroundColor White
                        }
                    }
                }
            }
            
            # Find all MimeKit versions and target frameworks
            $mimeKitDirs = Get-ChildItem "$location\MimeKit*" -Directory -ErrorAction SilentlyContinue
            foreach ($mimeKitDir in $mimeKitDirs) {
                $libPath = Join-Path $mimeKitDir.FullName "lib"
                if (Test-Path $libPath) {
                    $frameworks = Get-ChildItem $libPath -Directory -ErrorAction SilentlyContinue
                    foreach ($framework in $frameworks) {
                        $dllPath = Join-Path $framework.FullName "MimeKit.dll"
                        if (Test-Path $dllPath) {
                            $foundMimeKitVersions += @{
                                Version = $mimeKitDir.Name.Replace("MimeKit.", "")
                                Framework = $framework.Name
                                Path = $dllPath
                                Compatible = $framework.Name -match "^net4[6-8]"
                            }
                            Write-Host "[INFO] [CompatibilityFix] Found MimeKit: $($mimeKitDir.Name) ($($framework.Name))" -ForegroundColor White
                        }
                    }
                }
            }
        }
    }
    
    Write-Host ""
    Write-Host "=== Step 2: .NET Framework Compatible Assembly Selection ===" -ForegroundColor Yellow
    
    # Find .NET Framework compatible assemblies
    $compatibleMailKit = $foundMailKitVersions | Where-Object { $_.Compatible } | Sort-Object Version -Descending | Select-Object -First 1
    $compatibleMimeKit = $foundMimeKitVersions | Where-Object { $_.Compatible } | Sort-Object Version -Descending | Select-Object -First 1
    
    if ($compatibleMailKit) {
        Write-Host "[SUCCESS] [CompatibilityFix] Compatible MailKit found: v$($compatibleMailKit.Version) ($($compatibleMailKit.Framework))" -ForegroundColor Green
        Write-Host "[INFO] [CompatibilityFix] Path: $($compatibleMailKit.Path)" -ForegroundColor Gray
    } else {
        Write-Host "[ERROR] [CompatibilityFix] No .NET Framework compatible MailKit found" -ForegroundColor Red
        Write-Host "[INFO] [CompatibilityFix] Available frameworks: $($foundMailKitVersions.Framework -join ', ')" -ForegroundColor Gray
    }
    
    if ($compatibleMimeKit) {
        Write-Host "[SUCCESS] [CompatibilityFix] Compatible MimeKit found: v$($compatibleMimeKit.Version) ($($compatibleMimeKit.Framework))" -ForegroundColor Green
        Write-Host "[INFO] [CompatibilityFix] Path: $($compatibleMimeKit.Path)" -ForegroundColor Gray
    } else {
        Write-Host "[ERROR] [CompatibilityFix] No .NET Framework compatible MimeKit found" -ForegroundColor Red
        Write-Host "[INFO] [CompatibilityFix] Available frameworks: $($foundMimeKitVersions.Framework -join ', ')" -ForegroundColor Gray
    }
    
    # Create fixed assembly loading helper if compatible assemblies found
    if ($compatibleMailKit -and $compatibleMimeKit) {
        Write-Host ""
        Write-Host "=== Step 3: Creating Fixed Assembly Loading Helper ===" -ForegroundColor Yellow
        
        $fixedAssemblyHelper = @"
# Load-MailKitAssemblies-Fixed.ps1
# Fixed MailKit assembly loading for PowerShell 5.1 .NET Framework compatibility
# Uses .NET Framework assemblies instead of .NET 8.0 assemblies
# Auto-generated by Fix-MailKitAssemblyCompatibility.ps1
# Date: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')

function Load-MailKitAssemblies {
    [CmdletBinding()]
    param()
    
    try {
        # Check if assemblies are already loaded
        if ([System.AppDomain]::CurrentDomain.GetAssemblies() | Where-Object { `$_.GetName().Name -eq "MimeKit" }) {
            Write-Host "[DEBUG] [MailKit] Assemblies already loaded" -ForegroundColor Gray
            return `$true
        }
        
        # Load .NET Framework compatible assemblies
        Write-Host "[DEBUG] [MailKit] Loading MimeKit assembly (.NET Framework $($compatibleMimeKit.Framework))..." -ForegroundColor Gray
        Add-Type -Path "$($compatibleMimeKit.Path)" -ErrorAction Stop
        
        Write-Host "[DEBUG] [MailKit] Loading MailKit assembly (.NET Framework $($compatibleMailKit.Framework))..." -ForegroundColor Gray
        Add-Type -Path "$($compatibleMailKit.Path)" -ErrorAction Stop
        
        Write-Host "[SUCCESS] [MailKit] .NET Framework compatible assemblies loaded successfully" -ForegroundColor Green
        return `$true
        
    } catch {
        Write-Warning "[MailKit] Failed to load .NET Framework assemblies: `$(`$_.Exception.Message)"
        return `$false
    }
}

# Test loading assemblies immediately
if (Load-MailKitAssemblies) {
    Write-Host "[INFO] [MailKit] Email notification assemblies ready (.NET Framework compatible)" -ForegroundColor White
    
    # Test creating MailKit objects
    try {
        `$testClient = New-Object MailKit.Net.Smtp.SmtpClient
        `$testMessage = New-Object MimeKit.MimeMessage
        
        if (`$testClient -and `$testMessage) {
            Write-Host "[SUCCESS] [MailKit] MailKit objects created successfully" -ForegroundColor Green
            `$testClient.Dispose()
        }
    } catch {
        Write-Warning "[MailKit] Object creation test failed: `$(`$_.Exception.Message)"
    }
} else {
    Write-Warning "[MailKit] Email notification assemblies not available"
}
"@
        
        $fixedAssemblyHelper | Set-Content ".\Load-MailKitAssemblies-Fixed.ps1" -Encoding UTF8
        Write-Host "[SUCCESS] [CompatibilityFix] Fixed assembly helper created: Load-MailKitAssemblies-Fixed.ps1" -ForegroundColor Green
        
        # Test the fixed assembly loading
        Write-Host ""
        Write-Host "=== Step 4: Testing Fixed Assembly Loading ===" -ForegroundColor Yellow
        
        try {
            # Test loading .NET Framework compatible assemblies
            Write-Host "[DEBUG] [CompatibilityFix] Testing MimeKit (.NET Framework)..." -ForegroundColor Gray
            Add-Type -Path $compatibleMimeKit.Path -ErrorAction Stop
            Write-Host "[SUCCESS] [CompatibilityFix] MimeKit loaded successfully" -ForegroundColor Green
            
            Write-Host "[DEBUG] [CompatibilityFix] Testing MailKit (.NET Framework)..." -ForegroundColor Gray
            Add-Type -Path $compatibleMailKit.Path -ErrorAction Stop
            Write-Host "[SUCCESS] [CompatibilityFix] MailKit loaded successfully" -ForegroundColor Green
            
            # Test object creation
            $testClient = New-Object MailKit.Net.Smtp.SmtpClient
            $testMessage = New-Object MimeKit.MimeMessage
            
            if ($testClient -and $testMessage) {
                Write-Host "[SUCCESS] [CompatibilityFix] MailKit objects created successfully" -ForegroundColor Green
                $testClient.Dispose()
            }
            
        } catch {
            Write-Host "[ERROR] [CompatibilityFix] Fixed assembly loading failed: $($_.Exception.Message)" -ForegroundColor Red
        }
        
    } else {
        Write-Host "[ERROR] [CompatibilityFix] No .NET Framework compatible assemblies found" -ForegroundColor Red
        Write-Host ""
        Write-Host "Available Assemblies:" -ForegroundColor White
        Write-Host "MailKit Frameworks: $($foundMailKitVersions.Framework -join ', ')" -ForegroundColor Gray
        Write-Host "MimeKit Frameworks: $($foundMimeKitVersions.Framework -join ', ')" -ForegroundColor Gray
        Write-Host ""
        Write-Host "Issue: MailKit 4.13.0 only provides .NET 8.0 assemblies" -ForegroundColor Red
        Write-Host "Solution: Install an older MailKit version with .NET Framework support" -ForegroundColor Yellow
    }
    
} catch {
    Write-Host "[ERROR] [CompatibilityFix] Assembly analysis failed: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host ""
Write-Host "=== Compatibility Fix Summary ===" -ForegroundColor Cyan

if ($compatibleMailKit -and $compatibleMimeKit) {
    Write-Host "✅ .NET FRAMEWORK ASSEMBLIES FOUND AND TESTED" -ForegroundColor Green
    Write-Host ""
    Write-Host "Fixed Configuration:" -ForegroundColor White
    Write-Host "- MailKit: v$($compatibleMailKit.Version) ($($compatibleMailKit.Framework))" -ForegroundColor Gray
    Write-Host "- MimeKit: v$($compatibleMimeKit.Version) ($($compatibleMimeKit.Framework))" -ForegroundColor Gray
    Write-Host "- Assembly Helper: Load-MailKitAssemblies-Fixed.ps1" -ForegroundColor Gray
    Write-Host ""
    Write-Host "Next Steps:" -ForegroundColor White
    Write-Host "1. Use Load-MailKitAssemblies-Fixed.ps1 for assembly loading" -ForegroundColor Gray
    Write-Host "2. Update Unity-Claude-EmailNotifications module to use fixed helper" -ForegroundColor Gray
    Write-Host "3. Run Test-Week5-Day1-EmailNotifications.ps1 to validate" -ForegroundColor Gray
} else {
    Write-Host "❌ NO .NET FRAMEWORK COMPATIBLE ASSEMBLIES" -ForegroundColor Red
    Write-Host ""
    Write-Host "Current MailKit version (4.13.0) only provides .NET 8.0 assemblies" -ForegroundColor Red
    Write-Host "PowerShell 5.1 requires .NET Framework assemblies (net462, net47, net48)" -ForegroundColor Gray
    Write-Host ""
    Write-Host "Recommended Solution:" -ForegroundColor White
    Write-Host "Install an older MailKit version with .NET Framework support:" -ForegroundColor Gray
    Write-Host "Install-Package MailKit -RequiredVersion 3.4.3 -Source https://www.nuget.org/api/v2" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "=== Compatibility Fix Complete ===" -ForegroundColor Cyan
# SIG # Begin signature block
# MIIFqQYJKoZIhvcNAQcCoIIFmjCCBZYCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUyeUK4Z1ApmtmmL7/cOjWretb
# MmygggMwMIIDLDCCAhSgAwIBAgIQdR0W2SKoK5VE8JId4ZxrRTANBgkqhkiG9w0B
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
# CQQxFgQUXh0SeXPQFjWrzrDOuIvr2UbpYMcwDQYJKoZIhvcNAQEBBQAEggEAMkwB
# 8j/RkQi4gc1BaRzFLKAjEArtcFYiwcFQxmQe2xVyo/Q/hQUKOKzRTlDpFQrB8Osq
# tqZlkPJqjE+E+5qFQ9LQ8J0fTX27pJzvZhNgM8odFNiZ2uBYrwqs1vInCuIdrcFE
# RBiQXIZ7YSyjIboLxvInxQL67AwTJGCeKM9lE220cUuaCU+5JVjm0tqGhWfE4HJD
# yOCDfUMlOxtbnhjWrAShUIlb3ILST60TYju3KpP4wiIBncTsKzZNIPQ5X3BLMlGa
# E/PDhFzM6Dw2Yug9rXmaIz11RdvtkfmUx/qbVVwgMzYPtSeU4uL2E5c93L/nhqjM
# T+72O6W1HrTnnUmhag==
# SIG # End signature block
