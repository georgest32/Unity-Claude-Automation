# Install-MailKitForUnityClaudeAutomation.ps1
# Week 5 Day 1 Hour 1-2: MailKit Integration Research and Setup
# Install and configure MailKit for secure email notifications in PowerShell 5.1
# Date: 2025-08-21

[CmdletBinding()]
param(
    [switch]$ValidateOnly,
    [switch]$ForceReinstall
)

Write-Host "=== MailKit Installation for Unity-Claude Automation ===" -ForegroundColor Cyan
Write-Host "Week 5 Day 1 Hour 1-2: MailKit Integration Setup" -ForegroundColor White
Write-Host "PowerShell Version: $($PSVersionTable.PSVersion)" -ForegroundColor White
Write-Host ".NET Framework: $([System.Runtime.InteropServices.RuntimeInformation]::FrameworkDescription)" -ForegroundColor White
Write-Host ""

# Installation results tracking
$InstallationResults = @{
    StartTime = Get-Date
    EndTime = $null
    Status = "In Progress"
    Steps = @()
    MailKitPath = $null
    MimeKitPath = $null
    TestResults = @{}
    Errors = @()
}

function Write-InstallLog {
    param(
        [string]$Message,
        [string]$Level = "INFO"
    )
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss.fff"
    $logMessage = "[$timestamp] [$Level] [MailKitInstall] $Message"
    
    switch ($Level) {
        "ERROR" { Write-Host $logMessage -ForegroundColor Red }
        "WARNING" { Write-Host $logMessage -ForegroundColor Yellow }
        "DEBUG" { Write-Host $logMessage -ForegroundColor Gray }
        "SUCCESS" { Write-Host $logMessage -ForegroundColor Green }
        default { Write-Host $logMessage -ForegroundColor White }
    }
    
    # Log to centralized automation log
    Add-Content -Path ".\unity_claude_automation.log" -Value $logMessage -ErrorAction SilentlyContinue
}

function Add-InstallStep {
    param(
        [string]$StepName,
        [string]$Status,
        [string]$Details = ""
    )
    
    $InstallationResults.Steps += @{
        StepName = $StepName
        Status = $Status
        Details = $Details
        Timestamp = Get-Date
    }
}

Write-InstallLog -Message "Starting MailKit installation for Unity-Claude notification system" -Level "INFO"

# Step 1: Check Administrator Privileges
Write-Host "=== Step 1: Administrator Privileges Check ===" -ForegroundColor Yellow
Write-InstallLog -Message "Checking administrator privileges for NuGet package installation" -Level "INFO"

try {
    $currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
    $isAdmin = $currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
    
    if (-not $isAdmin) {
        Write-InstallLog -Message "Administrator privileges required for NuGet package installation" -Level "WARNING"
        Write-Host "WARNING: Administrator privileges recommended for NuGet package installation" -ForegroundColor Yellow
        Write-Host "Consider running PowerShell as Administrator for best results" -ForegroundColor Gray
    } else {
        Write-InstallLog -Message "Administrator privileges confirmed" -Level "SUCCESS"
        Write-Host "Administrator privileges: CONFIRMED" -ForegroundColor Green
    }
    
    Add-InstallStep -StepName "Administrator Check" -Status "SUCCESS" -Details "Admin: $isAdmin"
    
} catch {
    Write-InstallLog -Message "Failed to check administrator privileges: $($_.Exception.Message)" -Level "ERROR"
    $InstallationResults.Errors += "Administrator Check: $($_.Exception.Message)"
}

# Step 2: Check Existing MailKit Installation
Write-Host ""
Write-Host "=== Step 2: Existing MailKit Installation Check ===" -ForegroundColor Yellow
Write-InstallLog -Message "Checking for existing MailKit installation" -Level "INFO"

try {
    # Check for existing MailKit package
    $existingMailKit = Get-Package -Name "MailKit" -ErrorAction SilentlyContinue
    $existingMimeKit = Get-Package -Name "MimeKit" -ErrorAction SilentlyContinue
    
    if ($existingMailKit) {
        Write-InstallLog -Message "Existing MailKit found: v$($existingMailKit.Version) at $($existingMailKit.Source)" -Level "INFO"
        Write-Host "Existing MailKit: v$($existingMailKit.Version)" -ForegroundColor Green
        
        if ($ForceReinstall) {
            Write-InstallLog -Message "Force reinstall requested, will reinstall MailKit" -Level "WARNING"
        }
    } else {
        Write-InstallLog -Message "No existing MailKit installation found" -Level "INFO"
        Write-Host "MailKit: Not installed" -ForegroundColor Red
    }
    
    if ($existingMimeKit) {
        Write-InstallLog -Message "Existing MimeKit found: v$($existingMimeKit.Version) at $($existingMimeKit.Source)" -Level "INFO"
        Write-Host "Existing MimeKit: v$($existingMimeKit.Version)" -ForegroundColor Green
    } else {
        Write-InstallLog -Message "No existing MimeKit installation found" -Level "INFO"
        Write-Host "MimeKit: Not installed" -ForegroundColor Red
    }
    
    Add-InstallStep -StepName "Existing Installation Check" -Status "SUCCESS" -Details "MailKit: $(if ($existingMailKit) { $existingMailKit.Version } else { 'Not installed' }), MimeKit: $(if ($existingMimeKit) { $existingMimeKit.Version } else { 'Not installed' })"
    
} catch {
    Write-InstallLog -Message "Failed to check existing installation: $($_.Exception.Message)" -Level "ERROR"
    $InstallationResults.Errors += "Existing Installation Check: $($_.Exception.Message)"
}

# Step 3: MailKit Installation (if needed)
if (-not $ValidateOnly -and (-not $existingMailKit -or $ForceReinstall)) {
    Write-Host ""
    Write-Host "=== Step 3: MailKit Installation ===" -ForegroundColor Yellow
    Write-InstallLog -Message "Installing MailKit from nuget.org repository" -Level "INFO"
    
    try {
        # Install MailKit package
        Write-InstallLog -Message "Installing MailKit NuGet package..." -Level "INFO"
        Install-Package -Name 'MailKit' -Source 'nuget.org' -Force:$ForceReinstall -ErrorAction Stop
        
        # Verify installation
        $installedMailKit = Get-Package -Name "MailKit" -ErrorAction Stop
        Write-InstallLog -Message "MailKit installed successfully: v$($installedMailKit.Version)" -Level "SUCCESS"
        Write-Host "MailKit installed: v$($installedMailKit.Version)" -ForegroundColor Green
        
        # MimeKit is a dependency and should be installed automatically
        $installedMimeKit = Get-Package -Name "MimeKit" -ErrorAction SilentlyContinue
        if ($installedMimeKit) {
            Write-InstallLog -Message "MimeKit dependency installed: v$($installedMimeKit.Version)" -Level "SUCCESS"
            Write-Host "MimeKit dependency: v$($installedMimeKit.Version)" -ForegroundColor Green
        } else {
            Write-InstallLog -Message "MimeKit dependency not found, may need manual installation" -Level "WARNING"
        }
        
        Add-InstallStep -StepName "MailKit Installation" -Status "SUCCESS" -Details "MailKit v$($installedMailKit.Version) installed"
        
    } catch {
        Write-InstallLog -Message "MailKit installation failed: $($_.Exception.Message)" -Level "ERROR"
        $InstallationResults.Errors += "MailKit Installation: $($_.Exception.Message)"
        Add-InstallStep -StepName "MailKit Installation" -Status "FAILED" -Details $_.Exception.Message
    }
}

# Step 4: Assembly Path Discovery
Write-Host ""
Write-Host "=== Step 4: Assembly Path Discovery ===" -ForegroundColor Yellow
Write-InstallLog -Message "Discovering MailKit and MimeKit assembly paths" -Level "INFO"

try {
    # Find MailKit assembly path
    $mailKitPackage = Get-Package -Name "MailKit" -ErrorAction Stop
    $mailKitPath = $mailKitPackage.Source
    
    # Try common NuGet package locations
    $possiblePaths = @(
        "$env:ProgramFiles\PackageManagement\NuGet\Packages",
        "$env:USERPROFILE\.nuget\packages",
        "$env:LOCALAPPDATA\Microsoft\Windows\PowerShell\NuGet\Packages"
    )
    
    $mailKitDll = $null
    $mimeKitDll = $null
    
    foreach ($basePath in $possiblePaths) {
        # Look for MailKit DLL
        $mailKitPattern = "$basePath\MailKit*\lib\*\MailKit.dll"
        $foundMailKit = Get-ChildItem $mailKitPattern -ErrorAction SilentlyContinue | Sort-Object LastWriteTime -Descending | Select-Object -First 1
        
        if ($foundMailKit) {
            $mailKitDll = $foundMailKit.FullName
            Write-InstallLog -Message "MailKit.dll found: $mailKitDll" -Level "SUCCESS"
            break
        }
    }
    
    foreach ($basePath in $possiblePaths) {
        # Look for MimeKit DLL
        $mimeKitPattern = "$basePath\MimeKit*\lib\*\MimeKit.dll"
        $foundMimeKit = Get-ChildItem $mimeKitPattern -ErrorAction SilentlyContinue | Sort-Object LastWriteTime -Descending | Select-Object -First 1
        
        if ($foundMimeKit) {
            $mimeKitDll = $foundMimeKit.FullName
            Write-InstallLog -Message "MimeKit.dll found: $mimeKitDll" -Level "SUCCESS"
            break
        }
    }
    
    if ($mailKitDll -and $mimeKitDll) {
        $InstallationResults.MailKitPath = $mailKitDll
        $InstallationResults.MimeKitPath = $mimeKitDll
        
        Write-Host "MailKit.dll: $mailKitDll" -ForegroundColor Green
        Write-Host "MimeKit.dll: $mimeKitDll" -ForegroundColor Green
        
        Add-InstallStep -StepName "Assembly Path Discovery" -Status "SUCCESS" -Details "Both assemblies located"
    } else {
        throw "Could not locate MailKit or MimeKit assemblies. Installation may have failed."
    }
    
} catch {
    Write-InstallLog -Message "Assembly path discovery failed: $($_.Exception.Message)" -Level "ERROR"
    $InstallationResults.Errors += "Assembly Path Discovery: $($_.Exception.Message)"
    Add-InstallStep -StepName "Assembly Path Discovery" -Status "FAILED" -Details $_.Exception.Message
}

# Step 5: Assembly Loading Test
Write-Host ""
Write-Host "=== Step 5: Assembly Loading Test ===" -ForegroundColor Yellow
Write-InstallLog -Message "Testing MailKit and MimeKit assembly loading" -Level "INFO"

try {
    if ($InstallationResults.MailKitPath -and $InstallationResults.MimeKitPath) {
        # Test loading MimeKit first (dependency)
        Write-InstallLog -Message "Loading MimeKit assembly: $($InstallationResults.MimeKitPath)" -Level "DEBUG"
        Add-Type -Path $InstallationResults.MimeKitPath -ErrorAction Stop
        Write-InstallLog -Message "MimeKit assembly loaded successfully" -Level "SUCCESS"
        
        # Test loading MailKit
        Write-InstallLog -Message "Loading MailKit assembly: $($InstallationResults.MailKitPath)" -Level "DEBUG"
        Add-Type -Path $InstallationResults.MailKitPath -ErrorAction Stop
        Write-InstallLog -Message "MailKit assembly loaded successfully" -Level "SUCCESS"
        
        # Test creating basic MailKit objects
        Write-InstallLog -Message "Testing MailKit object creation..." -Level "DEBUG"
        $testClient = New-Object MailKit.Net.Smtp.SmtpClient
        $testMessage = New-Object MimeKit.MimeMessage
        
        if ($testClient -and $testMessage) {
            Write-InstallLog -Message "MailKit objects created successfully" -Level "SUCCESS"
            Write-Host "Assembly Loading: SUCCESS" -ForegroundColor Green
            Write-Host "MailKit SMTP Client: OPERATIONAL" -ForegroundColor Green
            Write-Host "MimeKit Message: OPERATIONAL" -ForegroundColor Green
            
            # Cleanup test objects
            $testClient.Dispose()
        } else {
            throw "Failed to create MailKit test objects"
        }
        
        $InstallationResults.TestResults.AssemblyLoading = $true
        Add-InstallStep -StepName "Assembly Loading Test" -Status "SUCCESS" -Details "MailKit and MimeKit assemblies functional"
        
    } else {
        throw "Assembly paths not available for testing"
    }
    
} catch {
    Write-InstallLog -Message "Assembly loading test failed: $($_.Exception.Message)" -Level "ERROR"
    $InstallationResults.Errors += "Assembly Loading Test: $($_.Exception.Message)"
    $InstallationResults.TestResults.AssemblyLoading = $false
    Add-InstallStep -StepName "Assembly Loading Test" -Status "FAILED" -Details $_.Exception.Message
}

# Step 6: Create Assembly Loading Helper
Write-Host ""
Write-Host "=== Step 6: Assembly Loading Helper Creation ===" -ForegroundColor Yellow
Write-InstallLog -Message "Creating reusable assembly loading helper for Unity-Claude modules" -Level "INFO"

try {
    if ($InstallationResults.MailKitPath -and $InstallationResults.MimeKitPath) {
        $assemblyHelper = @"
# Load-MailKitAssemblies.ps1
# Helper script to load MailKit and MimeKit assemblies for Unity-Claude notification system
# Auto-generated by Install-MailKitForUnityClaudeAutomation.ps1
# Date: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')

function Load-MailKitAssemblies {
    [CmdletBinding()]
    param()
    
    try {
        # Load MimeKit first (dependency)
        Add-Type -Path "$($InstallationResults.MimeKitPath)" -ErrorAction Stop
        Write-Host "[DEBUG] [MailKit] MimeKit assembly loaded successfully" -ForegroundColor Gray
        
        # Load MailKit
        Add-Type -Path "$($InstallationResults.MailKitPath)" -ErrorAction Stop
        Write-Host "[DEBUG] [MailKit] MailKit assembly loaded successfully" -ForegroundColor Gray
        
        return `$true
        
    } catch {
        Write-Warning "[MailKit] Failed to load MailKit assemblies: `$(`$_.Exception.Message)"
        return `$false
    }
}

# Auto-load assemblies when helper is imported
if (-not (Load-MailKitAssemblies)) {
    Write-Warning "[MailKit] MailKit assemblies not available - email notifications will not function"
} else {
    Write-Host "[SUCCESS] [MailKit] Email notification assemblies loaded and ready" -ForegroundColor Green
}
"@
        
        $assemblyHelper | Set-Content ".\Load-MailKitAssemblies.ps1" -Encoding UTF8
        Write-InstallLog -Message "Assembly loading helper created: Load-MailKitAssemblies.ps1" -Level "SUCCESS"
        Write-Host "Assembly Helper: Load-MailKitAssemblies.ps1 created" -ForegroundColor Green
        
        Add-InstallStep -StepName "Assembly Helper Creation" -Status "SUCCESS" -Details "Load-MailKitAssemblies.ps1 created"
        
    } else {
        Write-InstallLog -Message "Cannot create assembly helper - assembly paths not available" -Level "WARNING"
        Add-InstallStep -StepName "Assembly Helper Creation" -Status "SKIPPED" -Details "Assembly paths not available"
    }
    
} catch {
    Write-InstallLog -Message "Assembly helper creation failed: $($_.Exception.Message)" -Level "ERROR"
    $InstallationResults.Errors += "Assembly Helper Creation: $($_.Exception.Message)"
    Add-InstallStep -StepName "Assembly Helper Creation" -Status "FAILED" -Details $_.Exception.Message
}

# Installation Summary
$InstallationResults.EndTime = Get-Date
$totalDuration = ($InstallationResults.EndTime - $InstallationResults.StartTime).TotalSeconds
$successfulSteps = ($InstallationResults.Steps | Where-Object { $_.Status -eq "SUCCESS" }).Count
$totalSteps = $InstallationResults.Steps.Count

if ($InstallationResults.Errors.Count -eq 0) {
    $InstallationResults.Status = "SUCCESS"
    $statusColor = "Green"
} elseif ($successfulSteps -gt 0) {
    $InstallationResults.Status = "PARTIAL_SUCCESS"
    $statusColor = "Yellow"
} else {
    $InstallationResults.Status = "FAILED"
    $statusColor = "Red"
}

Write-Host ""
Write-Host "=== MailKit Installation Summary ===" -ForegroundColor Cyan
Write-Host ""
Write-Host "Installation Status: $($InstallationResults.Status)" -ForegroundColor $statusColor
Write-Host "Total Duration: $([math]::Round($totalDuration, 2)) seconds" -ForegroundColor White
Write-Host "Successful Steps: $successfulSteps/$totalSteps" -ForegroundColor White

Write-Host ""
Write-Host "Step Results:" -ForegroundColor White
foreach ($step in $InstallationResults.Steps) {
    $color = switch ($step.Status) {
        "SUCCESS" { "Green" }
        "FAILED" { "Red" }
        default { "Yellow" }
    }
    Write-Host "  [$($step.Status)] $($step.StepName)" -ForegroundColor $color
    if ($step.Details) {
        Write-Host "    Details: $($step.Details)" -ForegroundColor Gray
    }
}

if ($InstallationResults.Errors.Count -gt 0) {
    Write-Host ""
    Write-Host "Errors Encountered:" -ForegroundColor Red
    foreach ($error in $InstallationResults.Errors) {
        Write-Host "  - $error" -ForegroundColor Red
    }
}

Write-Host ""
if ($InstallationResults.Status -eq "SUCCESS") {
    Write-Host "✅ MAILKIT INSTALLATION SUCCESSFUL" -ForegroundColor Green
    Write-Host ""
    Write-Host "Next Steps:" -ForegroundColor White
    Write-Host "1. Use Load-MailKitAssemblies.ps1 to load assemblies in scripts" -ForegroundColor Gray
    Write-Host "2. Proceed with Unity-Claude-EmailNotifications.psm1 module creation" -ForegroundColor Gray
    Write-Host "3. Test email functionality with secure SMTP configuration" -ForegroundColor Gray
} else {
    Write-Host "⚠️ MAILKIT INSTALLATION INCOMPLETE" -ForegroundColor Yellow
    Write-Host "Review errors and retry installation as Administrator" -ForegroundColor Gray
}

Write-InstallLog -Message "MailKit installation process completed with status: $($InstallationResults.Status)" -Level "INFO"

Write-Host ""
Write-Host "=== MailKit Installation Complete ===" -ForegroundColor Cyan

return $InstallationResults
# SIG # Begin signature block
# MIIFqQYJKoZIhvcNAQcCoIIFmjCCBZYCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUjFjx3tXNM50/TYSqa8FfAi/z
# X6igggMwMIIDLDCCAhSgAwIBAgIQdR0W2SKoK5VE8JId4ZxrRTANBgkqhkiG9w0B
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
# CQQxFgQUBCVfspq5/DofeT4QzEACbkKobwEwDQYJKoZIhvcNAQEBBQAEggEABiCS
# Cc2pPRCQeSLElgB/MurPHQ6Bww8ZaebbTRaczklhtoVXN1gQRs+w19WWeqDpFIlw
# EMLdkR4LTAH/Zc/dwleG+LEHGXxmOkWON+Xo4Mlk9bq9LxHVK9lIb4dstO8Wqaag
# PMvpamLW9CnU3WyaqJ87lPKMcZBRS+/rnO0nJrgkoaV0Vfn+VfYtfkE6mUEb+PxU
# anuqrz1NBAkwk5wWMldt3dEXt/4Bb2WnsEhpdDAGXjT4YJAvqv1n7+OzE3tp6Ke9
# V0bOnnZw4BLd41DkSEfOFfFtqat1vkoNz1zO6DjOXM7/YdLER+ijmRnDByFYqS5J
# VtA95yT4uIeU77/PLw==
# SIG # End signature block
