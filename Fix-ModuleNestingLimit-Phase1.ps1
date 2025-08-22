# Fix-ModuleNestingLimit-Phase1.ps1
# Phase 1: Module Dependency Simplification - Remove RequiredModules causing nesting limit issues
# Implementation of granular plan Hours 1-2: Module Manifest Cleanup
# Date: 2025-08-21

[CmdletBinding()]
param(
    [switch]$TestFix,
    [switch]$CreateBackups = $true
)

Write-Host "=== Fix Module Nesting Limit - Phase 1 ===" -ForegroundColor Cyan
Write-Host "Hour 1-2: Module Manifest Cleanup (Remove RequiredModules)" -ForegroundColor White
Write-Host ""

# Phase 1 Hour 1-2: Module Manifest Cleanup
Write-Host "1. Analyzing Module Dependency Chain..." -ForegroundColor Yellow

$moduleBasePath = "C:\UnityProjects\Sound-and-Shoal\Unity-Claude-Automation\Modules"
$modulesToFix = @(
    @{
        Name = "Unity-Claude-IntegratedWorkflow"
        ManifestPath = "$moduleBasePath\Unity-Claude-IntegratedWorkflow\Unity-Claude-IntegratedWorkflow.psd1"
        RequiredModules = @('Unity-Claude-RunspaceManagement', 'Unity-Claude-UnityParallelization', 'Unity-Claude-ClaudeParallelization')
        ModulePath = "$moduleBasePath\Unity-Claude-IntegratedWorkflow\Unity-Claude-IntegratedWorkflow.psm1"
    },
    @{
        Name = "Unity-Claude-RunspaceManagement"  
        ManifestPath = "$moduleBasePath\Unity-Claude-RunspaceManagement\Unity-Claude-RunspaceManagement.psd1"
        RequiredModules = @('Unity-Claude-ParallelProcessing')
        ModulePath = "$moduleBasePath\Unity-Claude-RunspaceManagement\Unity-Claude-RunspaceManagement.psm1"
    },
    @{
        Name = "Unity-Claude-UnityParallelization"
        ManifestPath = "$moduleBasePath\Unity-Claude-UnityParallelization\Unity-Claude-UnityParallelization.psd1"
        RequiredModules = @('Unity-Claude-RunspaceManagement', 'Unity-Claude-ParallelProcessing')
        ModulePath = "$moduleBasePath\Unity-Claude-UnityParallelization\Unity-Claude-UnityParallelization.psm1"
    },
    @{
        Name = "Unity-Claude-ClaudeParallelization"
        ManifestPath = "$moduleBasePath\Unity-Claude-ClaudeParallelization\Unity-Claude-ClaudeParallelization.psd1"
        RequiredModules = @('Unity-Claude-RunspaceManagement', 'Unity-Claude-ParallelProcessing')
        ModulePath = "$moduleBasePath\Unity-Claude-ClaudeParallelization\Unity-Claude-ClaudeParallelization.psm1"
    }
)

# Analyze current dependency chain
foreach ($module in $modulesToFix) {
    Write-Host "   Module: $($module.Name)" -ForegroundColor White
    Write-Host "     Manifest: $(if (Test-Path $module.ManifestPath) { 'EXISTS' } else { 'MISSING' })" -ForegroundColor $(if (Test-Path $module.ManifestPath) { 'Green' } else { 'Red' })
    Write-Host "     Required Dependencies: $($module.RequiredModules -join ', ')" -ForegroundColor Gray
}

Write-Host ""
Write-Host "2. Creating Backups (if requested)..." -ForegroundColor Yellow

if ($CreateBackups) {
    $backupTimestamp = Get-Date -Format "yyyyMMdd_HHmmss"
    $backupDir = ".\ModuleBackups_$backupTimestamp"
    New-Item -Path $backupDir -ItemType Directory -Force | Out-Null
    
    foreach ($module in $modulesToFix) {
        if (Test-Path $module.ManifestPath) {
            $backupFile = Join-Path $backupDir "$($module.Name).psd1.backup"
            Copy-Item $module.ManifestPath $backupFile -Force
            Write-Host "   Backed up: $($module.Name) → $backupFile" -ForegroundColor Green
        }
    }
    Write-Host "   Backups completed in: $backupDir" -ForegroundColor Green
} else {
    Write-Host "   Backup creation skipped" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "3. Removing RequiredModules from Manifests..." -ForegroundColor Yellow

$manifestsFixed = 0
foreach ($module in $modulesToFix) {
    if (-not (Test-Path $module.ManifestPath)) {
        Write-Host "   [SKIP] $($module.Name) - Manifest not found" -ForegroundColor Red
        continue
    }
    
    Write-Host "   [PROCESSING] $($module.Name)..." -ForegroundColor Cyan
    
    try {
        # Read current manifest content
        $manifestContent = Get-Content $module.ManifestPath -Raw -Encoding UTF8
        
        # Check if RequiredModules exists
        if ($manifestContent -match 'RequiredModules\s*=\s*@\([^)]*\)') {
            Write-Host "     Found RequiredModules declaration" -ForegroundColor Gray
            
            # Comment out RequiredModules section instead of removing (safer)
            $updatedContent = $manifestContent -replace '(\s*)(RequiredModules\s*=\s*@\([^)]*\))', '$1# $2 # COMMENTED OUT: Causing module nesting limit issues'
            
            # Write updated content
            $updatedContent | Set-Content $module.ManifestPath -Encoding UTF8 -Force
            
            Write-Host "     [SUCCESS] RequiredModules commented out" -ForegroundColor Green
            $manifestsFixed++
        } else {
            Write-Host "     [INFO] No RequiredModules found" -ForegroundColor Yellow
        }
        
    } catch {
        Write-Host "     [ERROR] Failed to process manifest: $($_.Exception.Message)" -ForegroundColor Red
    }
}

Write-Host ""
Write-Host "4. Adding Explicit Import Validation to Modules..." -ForegroundColor Yellow

# Create a dependency validation function that can be added to modules
$dependencyValidationFunction = @'

# Dependency validation function - added by Fix-ModuleNestingLimit-Phase1.ps1
function Test-ModuleDependencyAvailability {
    param(
        [string[]]$RequiredModules,
        [string]$ModuleName = "Unknown"
    )
    
    $missingModules = @()
    foreach ($reqModule in $RequiredModules) {
        $module = Get-Module $reqModule -ErrorAction SilentlyContinue
        if (-not $module) {
            $missingModules += $reqModule
        }
    }
    
    if ($missingModules.Count -gt 0) {
        Write-Warning "[$ModuleName] Missing required modules: $($missingModules -join ', '). Import them explicitly before using this module."
        return $false
    }
    
    return $true
}
'@

$modulesUpdated = 0
foreach ($module in $modulesToFix) {
    if (-not (Test-Path $module.ModulePath)) {
        Write-Host "   [SKIP] $($module.Name) - Module file not found" -ForegroundColor Red
        continue
    }
    
    Write-Host "   [PROCESSING] $($module.Name) module file..." -ForegroundColor Cyan
    
    try {
        # Read current module content
        $moduleContent = Get-Content $module.ModulePath -Raw -Encoding UTF8
        
        # Check if validation function already exists
        if ($moduleContent -notmatch 'Test-ModuleDependencyAvailability') {
            # Add validation function at the beginning of the module
            $updatedModuleContent = $dependencyValidationFunction + "`n`n" + $moduleContent
            
            # Write updated content
            $updatedModuleContent | Set-Content $module.ModulePath -Encoding UTF8 -Force
            
            Write-Host "     [SUCCESS] Added dependency validation function" -ForegroundColor Green
            $modulesUpdated++
        } else {
            Write-Host "     [INFO] Validation function already exists" -ForegroundColor Yellow
        }
        
    } catch {
        Write-Host "     [ERROR] Failed to update module: $($_.Exception.Message)" -ForegroundColor Red
    }
}

Write-Host ""
Write-Host "=== Phase 1 Fix Summary ===" -ForegroundColor Cyan

Write-Host "Manifests processed: $manifestsFixed/$($modulesToFix.Count)" -ForegroundColor White
Write-Host "Module files updated: $modulesUpdated/$($modulesToFix.Count)" -ForegroundColor White

if ($TestFix) {
    Write-Host ""
    Write-Host "5. Testing Import Without RequiredModules..." -ForegroundColor Yellow
    
    try {
        # Test importing IntegratedWorkflow module without automatic dependencies
        Write-Host "   Testing Unity-Claude-IntegratedWorkflow import..." -ForegroundColor Gray
        
        # Remove any existing module first
        Remove-Module Unity-Claude-IntegratedWorkflow -Force -ErrorAction SilentlyContinue
        
        # Try importing without dependencies (should work but may show warnings)
        Import-Module "$moduleBasePath\Unity-Claude-IntegratedWorkflow\Unity-Claude-IntegratedWorkflow.psm1" -Force -ErrorAction Stop
        
        $loadedModule = Get-Module Unity-Claude-IntegratedWorkflow -ErrorAction SilentlyContinue
        if ($loadedModule) {
            Write-Host "   [SUCCESS] Module imports without RequiredModules dependency chain" -ForegroundColor Green
            Write-Host "   Exported functions: $($loadedModule.ExportedFunctions.Count)" -ForegroundColor Gray
        } else {
            Write-Host "   [ERROR] Module failed to import" -ForegroundColor Red
        }
        
    } catch {
        Write-Host "   [ERROR] Import test failed: $($_.Exception.Message)" -ForegroundColor Red
    }
}

Write-Host ""
Write-Host "Next Steps:" -ForegroundColor White
Write-Host "1. Test end-to-end integration with explicit import strategy" -ForegroundColor Gray
Write-Host "2. Implement Unity project mocking (Phase 2)" -ForegroundColor Gray  
Write-Host "3. Optimize test script module loading sequence" -ForegroundColor Gray

Write-Host ""
Write-Host "=== Phase 1 Complete ===" -ForegroundColor Cyan
# SIG # Begin signature block
# MIIFqQYJKoZIhvcNAQcCoIIFmjCCBZYCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUSkaVuKiaJy4i0CNqpDz2xBfT
# 6DCgggMwMIIDLDCCAhSgAwIBAgIQdR0W2SKoK5VE8JId4ZxrRTANBgkqhkiG9w0B
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
# CQQxFgQUJbnhk27XlOP14aPhfmEuc3aoyccwDQYJKoZIhvcNAQEBBQAEggEAHeGu
# YuXocqvFvc5btjn+X1riTs4co0qWAwRqeIkL0mXeuaG1WCZ5HwOuz9gIDoMzPIA3
# //gx3tZ/AXthc51a87LYFUiczpr33GOG7XgLKP4bW/72E2b6ckCSvZI78EVloi7P
# q27GBCKlKRnVBHW40Y+irVOI9R5/UEylJZNx8R4pmlMSWUahSqd3duaP6cu9XCzM
# eWINIadzLuJQ20Xuy0vXVwVKYfvgYlJnK1n2H8dr67df1wpHBf+3yKa5teDYLjDy
# 97HaEnZPo19Qx4kdJr5hzcYy7XrWq4pcr7GQr9MQTPd5jVmDSGtS+vyzX1Vw0bcb
# ExKU41PXqF3jeIlPJw==
# SIG # End signature block
