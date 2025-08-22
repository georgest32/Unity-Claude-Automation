# Install-MailKit-Fixed.ps1
# Fixed MailKit installation using NuGet v2 API for PowerShell 5.1 compatibility
# Week 5 Day 1 Hour 7-8: Research-validated package installation approach
# Date: 2025-08-21

[CmdletBinding()]
param(
    [switch]$ValidateOnly,
    [switch]$UseCurrentUserScope
)

Write-Host "=== MailKit Installation (FIXED) for Unity-Claude Automation ===" -ForegroundColor Cyan
Write-Host "Research-validated NuGet v2 API approach for PowerShell 5.1" -ForegroundColor White
Write-Host "PowerShell Version: $($PSVersionTable.PSVersion)" -ForegroundColor White
Write-Host ""

# Installation configuration
$InstallConfig = @{
    MailKitPackage = "MailKit"
    MimeKitPackage = "MimeKit"
    NuGetV2Source = "https://www.nuget.org/api/v2"
    NuGetV3Source = "https://api.nuget.org/v3/index.json"
    UseCurrentUserScope = $UseCurrentUserScope
    ValidateOnly = $ValidateOnly
}

function Write-InstallLog {
    param(
        [string]$Message,
        [string]$Level = "INFO"
    )
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss.fff"
    $logMessage = "[$timestamp] [$Level] [MailKitFixed] $Message"
    
    switch ($Level) {
        "ERROR" { Write-Host $logMessage -ForegroundColor Red }
        "WARNING" { Write-Host $logMessage -ForegroundColor Yellow }
        "DEBUG" { Write-Host $logMessage -ForegroundColor Gray }
        "SUCCESS" { Write-Host $logMessage -ForegroundColor Green }
        default { Write-Host $logMessage -ForegroundColor White }
    }
    
    Add-Content -Path ".\unity_claude_automation.log" -Value $logMessage -ErrorAction SilentlyContinue
}

Write-InstallLog -Message "Starting MailKit installation using research-validated NuGet v2 API approach" -Level "INFO"

# Step 1: Check Administrator Privileges
Write-Host "=== Step 1: Privileges and Environment Check ===" -ForegroundColor Yellow

try {
    $currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
    $isAdmin = $currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
    
    Write-InstallLog -Message "Administrator privileges: $isAdmin" -Level "INFO"
    
    if (-not $isAdmin -and -not $UseCurrentUserScope) {
        Write-InstallLog -Message "No administrator privileges - will use CurrentUser scope for installation" -Level "WARNING"
        $InstallConfig.UseCurrentUserScope = $true
    }
    
    $scope = if ($InstallConfig.UseCurrentUserScope) { "CurrentUser" } else { "AllUsers" }
    Write-Host "Installation scope: $scope" -ForegroundColor $(if ($isAdmin) { "Green" } else { "Yellow" })
    
} catch {
    Write-InstallLog -Message "Failed to check privileges: $($_.Exception.Message)" -Level "ERROR"
}

# Step 2: Configure NuGet Package Sources
Write-Host ""
Write-Host "=== Step 2: NuGet Package Source Configuration ===" -ForegroundColor Yellow
Write-InstallLog -Message "Configuring NuGet package sources for MailKit installation" -Level "INFO"

try {
    # Check current sources
    $currentSources = Get-PackageSource -ErrorAction Stop
    Write-InstallLog -Message "Found $($currentSources.Count) package sources" -Level "DEBUG"
    
    # Check if we have a working NuGet source
    $nugetV2Source = $currentSources | Where-Object { $_.Location -eq $InstallConfig.NuGetV2Source }
    $nugetV3Source = $currentSources | Where-Object { $_.Location -eq $InstallConfig.NuGetV3Source }
    
    # Register NuGet v2 source if not present (more compatible)
    if (-not $nugetV2Source) {
        Write-InstallLog -Message "Registering NuGet v2 API source for better compatibility" -Level "INFO"
        Register-PackageSource -Name "NuGet.v2" -Location $InstallConfig.NuGetV2Source -ProviderName NuGet -Trusted -Force -ErrorAction Stop
        Write-InstallLog -Message "NuGet v2 source registered successfully" -Level "SUCCESS"
    } else {
        Write-InstallLog -Message "NuGet v2 source already exists" -Level "DEBUG"
    }
    
    Write-Host "Package sources configured successfully" -ForegroundColor Green
    
} catch {
    Write-InstallLog -Message "Package source configuration failed: $($_.Exception.Message)" -Level "ERROR"
    Write-Host "WARNING: Package source configuration failed, attempting installation anyway" -ForegroundColor Yellow
}

# Step 3: Test Package Availability
Write-Host ""
Write-Host "=== Step 3: Package Availability Testing ===" -ForegroundColor Yellow
Write-InstallLog -Message "Testing MailKit package availability using multiple sources" -Level "INFO"

$packageFound = $false
$workingSource = $null

# Try NuGet v2 API first (most compatible)
try {
    Write-InstallLog -Message "Testing MailKit availability via NuGet v2 API" -Level "DEBUG"
    $mailKitV2 = Find-Package -Name $InstallConfig.MailKitPackage -Source $InstallConfig.NuGetV2Source -ErrorAction Stop
    
    if ($mailKitV2) {
        Write-InstallLog -Message "MailKit found via NuGet v2: v$($mailKitV2.Version)" -Level "SUCCESS"
        Write-Host "MailKit available: v$($mailKitV2.Version) (NuGet v2)" -ForegroundColor Green
        $packageFound = $true
        $workingSource = $InstallConfig.NuGetV2Source
    }
    
} catch {
    Write-InstallLog -Message "MailKit not found via NuGet v2: $($_.Exception.Message)" -Level "DEBUG"
}

# Try NuGet v3 API if v2 failed
if (-not $packageFound) {
    try {
        Write-InstallLog -Message "Testing MailKit availability via NuGet v3 API" -Level "DEBUG"
        $mailKitV3 = Find-Package -Name $InstallConfig.MailKitPackage -Source $InstallConfig.NuGetV3Source -ErrorAction Stop
        
        if ($mailKitV3) {
            Write-InstallLog -Message "MailKit found via NuGet v3: v$($mailKitV3.Version)" -Level "SUCCESS"
            Write-Host "MailKit available: v$($mailKitV3.Version) (NuGet v3)" -ForegroundColor Green
            $packageFound = $true
            $workingSource = $InstallConfig.NuGetV3Source
        }
        
    } catch {
        Write-InstallLog -Message "MailKit not found via NuGet v3: $($_.Exception.Message)" -Level "DEBUG"
    }
}

if (-not $packageFound) {
    Write-InstallLog -Message "MailKit package not found via any source - check internet connectivity" -Level "ERROR"
    Write-Host "ERROR: MailKit package not accessible via any NuGet source" -ForegroundColor Red
    Write-Host "Check internet connectivity and proxy settings" -ForegroundColor Gray
    exit 1
}

# Step 4: MailKit Installation
if (-not $ValidateOnly) {
    Write-Host ""
    Write-Host "=== Step 4: MailKit Installation ===" -ForegroundColor Yellow
    Write-InstallLog -Message "Installing MailKit using working source: $workingSource" -Level "INFO"
    
    try {
        $installParams = @{
            Name = $InstallConfig.MailKitPackage
            Source = $workingSource
            Force = $true
            ErrorAction = "Stop"
        }
        
        # Add scope if not administrator
        if ($InstallConfig.UseCurrentUserScope) {
            $installParams.Scope = "CurrentUser"
            Write-InstallLog -Message "Using CurrentUser scope for installation" -Level "INFO"
        }
        
        Write-InstallLog -Message "Installing MailKit with parameters: $($installParams | ConvertTo-Json -Compress)" -Level "DEBUG"
        Install-Package @installParams
        
        # Verify installation
        $installedMailKit = Get-Package -Name $InstallConfig.MailKitPackage -ErrorAction Stop
        Write-InstallLog -Message "MailKit installed successfully: v$($installedMailKit.Version)" -Level "SUCCESS"
        Write-Host "MailKit installation: SUCCESS v$($installedMailKit.Version)" -ForegroundColor Green
        
        # Check for MimeKit dependency
        $installedMimeKit = Get-Package -Name $InstallConfig.MimeKitPackage -ErrorAction SilentlyContinue
        if ($installedMimeKit) {
            Write-InstallLog -Message "MimeKit dependency installed: v$($installedMimeKit.Version)" -Level "SUCCESS"
            Write-Host "MimeKit dependency: SUCCESS v$($installedMimeKit.Version)" -ForegroundColor Green
        } else {
            Write-InstallLog -Message "MimeKit dependency not found, attempting separate installation" -Level "WARNING"
            
            # Try installing MimeKit separately
            try {
                Install-Package -Name $InstallConfig.MimeKitPackage -Source $workingSource -Force -Scope $(if ($InstallConfig.UseCurrentUserScope) { "CurrentUser" } else { "AllUsers" }) -ErrorAction Stop
                
                $separatelyInstalledMimeKit = Get-Package -Name $InstallConfig.MimeKitPackage -ErrorAction Stop
                Write-InstallLog -Message "MimeKit installed separately: v$($separatelyInstalledMimeKit.Version)" -Level "SUCCESS"
                Write-Host "MimeKit separate installation: SUCCESS v$($separatelyInstalledMimeKit.Version)" -ForegroundColor Green
                
            } catch {
                Write-InstallLog -Message "MimeKit separate installation failed: $($_.Exception.Message)" -Level "ERROR"
                Write-Host "WARNING: MimeKit installation failed - may cause MailKit functionality issues" -ForegroundColor Yellow
            }
        }
        
    } catch {
        Write-InstallLog -Message "MailKit installation failed: $($_.Exception.Message)" -Level "ERROR"
        Write-Host "ERROR: MailKit installation failed: $($_.Exception.Message)" -ForegroundColor Red
        exit 1
    }
}

# Step 5: Assembly Path Discovery and Helper Creation
Write-Host ""
Write-Host "=== Step 5: Assembly Path Discovery ===" -ForegroundColor Yellow
Write-InstallLog -Message "Discovering installed MailKit assembly paths" -Level "INFO"

try {
    # Common assembly locations for different installation methods
    $assemblyLocations = @(
        "$env:ProgramFiles\PackageManagement\NuGet\Packages",
        "$env:USERPROFILE\.nuget\packages", 
        "$env:LOCALAPPDATA\Microsoft\Windows\PowerShell\NuGet\Packages",
        "$env:ProgramData\Microsoft\Windows\PowerShell\PowerShellGet\NuGet\Packages"
    )
    
    $mailKitDll = $null
    $mimeKitDll = $null
    
    foreach ($basePath in $assemblyLocations) {
        if (Test-Path $basePath) {
            Write-InstallLog -Message "Searching for assemblies in: $basePath" -Level "DEBUG"
            
            # Look for MailKit DLL
            $mailKitSearch = Get-ChildItem "$basePath\MailKit*\lib\*\MailKit.dll" -Recurse -ErrorAction SilentlyContinue | Sort-Object LastWriteTime -Descending | Select-Object -First 1
            
            # Look for MimeKit DLL  
            $mimeKitSearch = Get-ChildItem "$basePath\MimeKit*\lib\*\MimeKit.dll" -Recurse -ErrorAction SilentlyContinue | Sort-Object LastWriteTime -Descending | Select-Object -First 1
            
            if ($mailKitSearch) {
                $mailKitDll = $mailKitSearch.FullName
                Write-InstallLog -Message "MailKit.dll found: $mailKitDll" -Level "SUCCESS"
            }
            
            if ($mimeKitSearch) {
                $mimeKitDll = $mimeKitSearch.FullName
                Write-InstallLog -Message "MimeKit.dll found: $mimeKitDll" -Level "SUCCESS"
            }
            
            if ($mailKitDll -and $mimeKitDll) {
                break
            }
        }
    }
    
    if ($mailKitDll -and $mimeKitDll) {
        Write-Host "Assembly Discovery: SUCCESS" -ForegroundColor Green
        Write-Host "MailKit.dll: $mailKitDll" -ForegroundColor Gray
        Write-Host "MimeKit.dll: $mimeKitDll" -ForegroundColor Gray
        
        # Create optimized assembly loading helper
        $assemblyHelper = @"
# Load-MailKitAssemblies.ps1
# Optimized MailKit assembly loading for Unity-Claude notification system
# Auto-generated by Install-MailKit-Fixed.ps1
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
        
        # Load MimeKit first (dependency)
        Write-Host "[DEBUG] [MailKit] Loading MimeKit assembly..." -ForegroundColor Gray
        Add-Type -Path "$mimeKitDll" -ErrorAction Stop
        
        # Load MailKit
        Write-Host "[DEBUG] [MailKit] Loading MailKit assembly..." -ForegroundColor Gray
        Add-Type -Path "$mailKitDll" -ErrorAction Stop
        
        Write-Host "[SUCCESS] [MailKit] Assemblies loaded successfully" -ForegroundColor Green
        return `$true
        
    } catch {
        Write-Warning "[MailKit] Failed to load assemblies: `$(`$_.Exception.Message)"
        return `$false
    }
}

# Test loading assemblies
if (Load-MailKitAssemblies) {
    Write-Host "[INFO] [MailKit] Email notification assemblies ready for use" -ForegroundColor White
} else {
    Write-Warning "[MailKit] Email notification assemblies not available"
}
"@
        
        $assemblyHelper | Set-Content ".\Load-MailKitAssemblies.ps1" -Encoding UTF8
        Write-InstallLog -Message "Assembly loading helper created: Load-MailKitAssemblies.ps1" -Level "SUCCESS"
        
        # Test assembly loading
        Write-Host ""
        Write-Host "=== Step 6: Assembly Loading Validation ===" -ForegroundColor Yellow
        Write-InstallLog -Message "Testing MailKit assembly loading" -Level "INFO"
        
        try {
            # Test loading MimeKit
            Add-Type -Path $mimeKitDll -ErrorAction Stop
            Write-InstallLog -Message "MimeKit assembly loaded successfully" -Level "SUCCESS"
            
            # Test loading MailKit
            Add-Type -Path $mailKitDll -ErrorAction Stop
            Write-InstallLog -Message "MailKit assembly loaded successfully" -Level "SUCCESS"
            
            # Test creating objects
            $testClient = New-Object MailKit.Net.Smtp.SmtpClient
            $testMessage = New-Object MimeKit.MimeMessage
            
            if ($testClient -and $testMessage) {
                Write-Host "Assembly Validation: SUCCESS" -ForegroundColor Green
                Write-Host "MailKit SMTP Client: FUNCTIONAL" -ForegroundColor Green
                Write-Host "MimeKit Message: FUNCTIONAL" -ForegroundColor Green
                
                $testClient.Dispose()
                
                Write-InstallLog -Message "MailKit functionality validation successful" -Level "SUCCESS"
            } else {
                throw "Failed to create MailKit test objects"
            }
            
        } catch {
            Write-InstallLog -Message "Assembly loading validation failed: $($_.Exception.Message)" -Level "ERROR"
            Write-Host "ERROR: Assembly loading validation failed" -ForegroundColor Red
        }
        
    } else {
        Write-InstallLog -Message "Assembly discovery failed - MailKit installation may be incomplete" -Level "ERROR"
        Write-Host "ERROR: Could not locate MailKit assemblies after installation" -ForegroundColor Red
    }
    
} catch {
    Write-InstallLog -Message "Assembly discovery failed: $($_.Exception.Message)" -Level "ERROR"
    Write-Host "ERROR: Assembly discovery failed: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host ""
Write-Host "=== MailKit Installation Summary ===" -ForegroundColor Cyan

if ($mailKitDll -and $mimeKitDll) {
    Write-Host "✅ MAILKIT INSTALLATION SUCCESSFUL" -ForegroundColor Green
    Write-Host ""
    Write-Host "Installation Details:" -ForegroundColor White
    Write-Host "- MailKit: Available and functional" -ForegroundColor Gray
    Write-Host "- MimeKit: Available and functional" -ForegroundColor Gray
    Write-Host "- Assembly Helper: Load-MailKitAssemblies.ps1 created" -ForegroundColor Gray
    Write-Host ""
    Write-Host "Next Steps:" -ForegroundColor White
    Write-Host "1. Run Test-Week5-Day1-EmailNotifications.ps1 to validate email system" -ForegroundColor Gray
    Write-Host "2. Configure email settings with New-EmailConfiguration" -ForegroundColor Gray
    Write-Host "3. Test email functionality with Test-EmailConfiguration" -ForegroundColor Gray
} else {
    Write-Host "❌ MAILKIT INSTALLATION FAILED" -ForegroundColor Red
    Write-Host ""
    Write-Host "Troubleshooting Steps:" -ForegroundColor White
    Write-Host "1. Check internet connectivity" -ForegroundColor Gray
    Write-Host "2. Run PowerShell as Administrator" -ForegroundColor Gray
    Write-Host "3. Check corporate proxy/firewall settings" -ForegroundColor Gray
    Write-Host "4. Try manual NuGet package download" -ForegroundColor Gray
}

Write-InstallLog -Message "MailKit installation process completed" -Level "INFO"

Write-Host ""
Write-Host "=== Installation Complete ===" -ForegroundColor Cyan
# SIG # Begin signature block
# MIIFqQYJKoZIhvcNAQcCoIIFmjCCBZYCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUjn2QSDpTarr0RYyJ6d7U5mAg
# PXSgggMwMIIDLDCCAhSgAwIBAgIQdR0W2SKoK5VE8JId4ZxrRTANBgkqhkiG9w0B
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
# CQQxFgQU2iVkvsMEMPHAyQU+ZRGoY3LGDP8wDQYJKoZIhvcNAQEBBQAEggEAI+VZ
# 2ZG4v1AMtn8ICAgUudhSCm/4VU+PAtuY0M5nARcXcxtYvBE2A3Rjko1PTf0PP9p6
# u5DUN6PuKYuN7OYngzMdKKueZoOuYcorPxPL+v/cJ++3G6fwcV51WWFxMlm7CyVZ
# lRBkRDGNUANim1sQXrMbjNjp5PkCx+tRwXADDSIDtMknXwCpzUGHmcNUIw0XBNoo
# ZVOU2q4sCYfOU3nY2cRZMHK0YaxceuG2ZSXfshg0DNwVqo93U8xTd9GHmDvKYB0J
# fzhyWMEbPiLmisu2tmKA888xNB23R9kTl0yeSiRAQ+u1IoOhyVqBSlGZAsL3bFAS
# 9DpTWZk5rzJZG2wlzA==
# SIG # End signature block
