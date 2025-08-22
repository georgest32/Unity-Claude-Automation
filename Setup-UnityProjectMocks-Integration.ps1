# Setup-UnityProjectMocks-Integration.ps1
# Phase 2: Unity Project Mock Infrastructure - Integration with UnityParallelization module
# Registers mock Unity projects using the actual UnityParallelization registration system
# Date: 2025-08-21

[CmdletBinding()]
param(
    [switch]$DetailedOutput
)

Write-Host "=== Unity Project Mocks Integration Setup ===" -ForegroundColor Cyan
Write-Host "Phase 2: Integrating with UnityParallelization project registration system" -ForegroundColor White
Write-Host ""

# Create mock project directories and structure
Write-Host "1. Creating Mock Unity Project Directories..." -ForegroundColor Yellow

$mockProjectsBasePath = "C:\MockProjects"
$mockProjects = @(
    @{
        Name = "Unity-Project-1"
        Path = "$mockProjectsBasePath\Unity-Project-1"
    },
    @{
        Name = "Unity-Project-2"  
        Path = "$mockProjectsBasePath\Unity-Project-2"
    },
    @{
        Name = "Unity-Project-3"
        Path = "$mockProjectsBasePath\Unity-Project-3"
    }
)

# Create base mock projects directory
if (-not (Test-Path $mockProjectsBasePath)) {
    New-Item -Path $mockProjectsBasePath -ItemType Directory -Force | Out-Null
    Write-Host "   Created mock projects base directory: $mockProjectsBasePath" -ForegroundColor Green
} else {
    Write-Host "   Mock projects base directory exists: $mockProjectsBasePath" -ForegroundColor Gray
}

# Create individual mock project directories with minimal Unity structure
foreach ($project in $mockProjects) {
    Write-Host "   [PROCESSING] $($project.Name)..." -ForegroundColor Cyan
    
    if (-not (Test-Path $project.Path)) {
        New-Item -Path $project.Path -ItemType Directory -Force | Out-Null
        Write-Host "     Created directory: $($project.Path)" -ForegroundColor Green
    } else {
        Write-Host "     Directory exists: $($project.Path)" -ForegroundColor Gray
    }
    
    # Create minimal Unity project structure
    $assetsPath = Join-Path $project.Path "Assets"
    $projectSettingsPath = Join-Path $project.Path "ProjectSettings"
    
    if (-not (Test-Path $assetsPath)) {
        New-Item -Path $assetsPath -ItemType Directory -Force | Out-Null
        Write-Host "     Created Assets directory" -ForegroundColor Gray
    }
    
    if (-not (Test-Path $projectSettingsPath)) {
        New-Item -Path $projectSettingsPath -ItemType Directory -Force | Out-Null
        Write-Host "     Created ProjectSettings directory" -ForegroundColor Gray
    }
    
    # Create minimal ProjectSettings.asset file to make it look like a Unity project
    $projectSettingsFile = Join-Path $projectSettingsPath "ProjectVersion.txt"
    if (-not (Test-Path $projectSettingsFile)) {
        @"
m_EditorVersion: 2021.1.14f1
m_EditorVersionWithRevision: 2021.1.14f1 (54ba63c7b9e8)
"@ | Set-Content $projectSettingsFile -Encoding UTF8
        Write-Host "     Created ProjectVersion.txt" -ForegroundColor Gray
    }
}

Write-Host ""
Write-Host "2. Testing UnityParallelization Module Functions..." -ForegroundColor Yellow

# Check if UnityParallelization module is available
$unityModule = Get-Module Unity-Claude-UnityParallelization -ErrorAction SilentlyContinue
if (-not $unityModule) {
    Write-Host "   [WARNING] Unity-Claude-UnityParallelization module not loaded" -ForegroundColor Yellow
    Write-Host "   Attempting to load module..." -ForegroundColor Gray
    
    try {
        $moduleBasePath = "C:\UnityProjects\Sound-and-Shoal\Unity-Claude-Automation\Modules"
        Import-Module "$moduleBasePath\Unity-Claude-ParallelProcessing\Unity-Claude-ParallelProcessing.psm1" -Force -Global -ErrorAction Stop
        Import-Module "$moduleBasePath\Unity-Claude-RunspaceManagement\Unity-Claude-RunspaceManagement.psm1" -Force -Global -ErrorAction Stop
        Import-Module "$moduleBasePath\Unity-Claude-UnityParallelization\Unity-Claude-UnityParallelization.psm1" -Force -Global -ErrorAction Stop
        
        Write-Host "   [SUCCESS] UnityParallelization module loaded" -ForegroundColor Green
    } catch {
        Write-Host "   [ERROR] Failed to load UnityParallelization module: $($_.Exception.Message)" -ForegroundColor Red
        exit 1
    }
}

# Check if Register-UnityProject function is available
$registerFunction = Get-Command Register-UnityProject -ErrorAction SilentlyContinue
if (-not $registerFunction) {
    Write-Host "   [ERROR] Register-UnityProject function not available" -ForegroundColor Red
    exit 1
} else {
    Write-Host "   [SUCCESS] Register-UnityProject function available" -ForegroundColor Green
}

Write-Host ""
Write-Host "3. Registering Mock Unity Projects..." -ForegroundColor Yellow

$successfulRegistrations = 0
foreach ($project in $mockProjects) {
    Write-Host "   [PROCESSING] Registering $($project.Name)..." -ForegroundColor Cyan
    
    try {
        # Register using the actual UnityParallelization function
        Write-Host "     Calling Register-UnityProject for $($project.Name)..." -ForegroundColor Gray
        $registrationResult = Register-UnityProject -ProjectPath $project.Path -ProjectName $project.Name -MonitoringEnabled
        
        if ($registrationResult) {
            Write-Host "     [SUCCESS] $($project.Name) registered successfully" -ForegroundColor Green
            $successfulRegistrations++
            
            # Test the registration
            Write-Host "     Testing availability..." -ForegroundColor Gray
            $availability = Test-UnityProjectAvailability -ProjectName $project.Name
            Write-Host "     Availability test result: Available=$($availability.Available)" -ForegroundColor $(if ($availability.Available) { "Green" } else { "Red" })
            
        } else {
            Write-Host "     [WARNING] $($project.Name) registration returned false" -ForegroundColor Yellow
        }
        
    } catch {
        Write-Host "     [ERROR] Failed to register $($project.Name): $($_.Exception.Message)" -ForegroundColor Red
        Write-Host "     Error details: $($_.ScriptStackTrace)" -ForegroundColor Red
    }
}

Write-Host ""
Write-Host "4. Validation Summary..." -ForegroundColor Yellow

Write-Host "   Mock projects created: $($mockProjects.Count)" -ForegroundColor White
Write-Host "   Successful registrations: $successfulRegistrations" -ForegroundColor $(if ($successfulRegistrations -eq $mockProjects.Count) { "Green" } else { "Red" })

# Test overall project availability
Write-Host ""
Write-Host "5. Final Availability Testing..." -ForegroundColor Yellow

$availableProjects = 0
foreach ($project in $mockProjects) {
    try {
        $availability = Test-UnityProjectAvailability -ProjectName $project.Name
        $status = if ($availability.Available) { "AVAILABLE" } else { "NOT_AVAILABLE" }
        $color = if ($availability.Available) { "Green" } else { "Red" }
        
        Write-Host "   [$status] $($project.Name)" -ForegroundColor $color
        if (-not $availability.Available) {
            Write-Host "     Reason: $($availability.Reason)" -ForegroundColor Gray
        }
        
        if ($availability.Available) {
            $availableProjects++
        }
        
    } catch {
        Write-Host "   [ERROR] $($project.Name) - $($_.Exception.Message)" -ForegroundColor Red
    }
}

Write-Host ""
Write-Host "=== Unity Project Mocks Integration Summary ===" -ForegroundColor Cyan

if ($availableProjects -eq $mockProjects.Count) {
    Write-Host "[SUCCESS] All $availableProjects/$($mockProjects.Count) mock Unity projects available for testing" -ForegroundColor Green
    Write-Host ""
    Write-Host "Next Steps:" -ForegroundColor White
    Write-Host "1. Run Test-Week3-Day5-EndToEndIntegration-Optimized.ps1" -ForegroundColor Gray
    Write-Host "2. Expected: Workflow creation should now succeed" -ForegroundColor Gray
    Write-Host "3. Target: >90% test pass rate" -ForegroundColor Gray
} else {
    Write-Host "[PARTIAL] Only $availableProjects/$($mockProjects.Count) mock Unity projects available" -ForegroundColor Yellow
    Write-Host "Some Unity project registrations may have failed" -ForegroundColor Gray
}

Write-Host ""
Write-Host "=== Mock Setup Complete ===" -ForegroundColor Cyan
# SIG # Begin signature block
# MIIFqQYJKoZIhvcNAQcCoIIFmjCCBZYCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUnXhTOu6ddq3925ax1CTr58Uj
# lhKgggMwMIIDLDCCAhSgAwIBAgIQdR0W2SKoK5VE8JId4ZxrRTANBgkqhkiG9w0B
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
# CQQxFgQUINkth33/BG+qsskDYF+m4FauXFwwDQYJKoZIhvcNAQEBBQAEggEAD6+b
# R+7/lk6i/tj2jKMfch8KP2k7nMZ66i2clR1KSse1XK8kvujPUIHL7UseOmrjFGiN
# XgtvqPekOUHJjdaBc07ikuaBzJmuaImJvmDM7onpiZ999yQorNZ84QjMPGUfdasY
# ER8c1MTvc7bSSTdHOd643wo2fhRDQUkYZrntTFXtlO04lg4KrVDv2FTwRaLHkdvG
# N4UR4/Vr+Ozk03aDIArv8HU94MeNzzXoe4GXdhtl3hslMY3HB3CquWQBvSUwwdqH
# tr3HA1/Mvb992uLyN0JelHGzEn9MVET27SrXmfSzJzefum5D9xnO2rQ3upil7Ouc
# SRqDmBnH3BEgAS5pKQ==
# SIG # End signature block
