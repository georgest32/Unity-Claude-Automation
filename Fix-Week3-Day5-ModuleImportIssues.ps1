# Fix-Week3-Day5-ModuleImportIssues.ps1
# Phase 1 Implementation: Fix module import and function availability issues
# Date: 2025-08-21

[CmdletBinding()]
param(
    [switch]$TestFix,
    [switch]$DetailedOutput
)

Write-Host "=== Week 3 Day 5 Module Import Issues Fix ===" -ForegroundColor Cyan
Write-Host "Phase 1 Hour 1-2: Module Path Resolution and Function Export Validation" -ForegroundColor White
Write-Host ""

# Phase 1 Hour 1-2: Module Path Resolution
Write-Host "1. Checking PSModulePath Configuration..." -ForegroundColor Yellow

$moduleBasePath = "C:\UnityProjects\Sound-and-Shoal\Unity-Claude-Automation\Modules"
$currentPSModulePath = $env:PSModulePath -split ';'

Write-Host "   Current PSModulePath entries:" -ForegroundColor Gray
foreach ($path in $currentPSModulePath) {
    $exists = Test-Path $path
    $color = if ($exists) { "Green" } else { "Red" }
    $status = if ($exists) { "EXISTS" } else { "MISSING" }
    Write-Host "     [$status] $path" -ForegroundColor $color
}

# Check if our Modules directory is in PSModulePath
$modulePathInPSPath = $currentPSModulePath -contains $moduleBasePath
Write-Host ""
Write-Host "2. Modules Directory Status:" -ForegroundColor Yellow
Write-Host "   Modules Path: $moduleBasePath" -ForegroundColor White
Write-Host "   Path Exists: $(Test-Path $moduleBasePath)" -ForegroundColor $(if (Test-Path $moduleBasePath) { "Green" } else { "Red" })
Write-Host "   In PSModulePath: $modulePathInPSPath" -ForegroundColor $(if ($modulePathInPSPath) { "Green" } else { "Red" })

# Add to PSModulePath if not present
if (-not $modulePathInPSPath -and (Test-Path $moduleBasePath)) {
    Write-Host ""
    Write-Host "3. Adding Modules directory to PSModulePath..." -ForegroundColor Yellow
    $env:PSModulePath = "$moduleBasePath;$($env:PSModulePath)"
    Write-Host "   Added: $moduleBasePath" -ForegroundColor Green
    
    # Verify addition
    $newPSModulePath = $env:PSModulePath -split ';'
    $nowInPath = $newPSModulePath -contains $moduleBasePath
    Write-Host "   Verification: $nowInPath" -ForegroundColor $(if ($nowInPath) { "Green" } else { "Red" })
}

Write-Host ""
Write-Host "4. Testing Module Discovery..." -ForegroundColor Yellow

# Test critical modules can be found by name
$criticalModules = @(
    'Unity-Claude-ParallelProcessing',
    'Unity-Claude-RunspaceManagement', 
    'Unity-Claude-UnityParallelization',
    'Unity-Claude-ClaudeParallelization',
    'Unity-Claude-IntegratedWorkflow'
)

$moduleDiscoveryResults = @{}
foreach ($moduleName in $criticalModules) {
    try {
        # Try to find module by name (without Import-Module)
        $moduleInfo = Get-Module -ListAvailable -Name $moduleName -ErrorAction SilentlyContinue
        if ($moduleInfo) {
            $moduleDiscoveryResults[$moduleName] = @{
                Status = "DISCOVERABLE"
                Path = $moduleInfo.Path
                Version = $moduleInfo.Version
                Functions = $moduleInfo.ExportedFunctions.Count
            }
            Write-Host "   [DISCOVERABLE] $moduleName v$($moduleInfo.Version) ($($moduleInfo.ExportedFunctions.Count) functions)" -ForegroundColor Green
        } else {
            # Try direct path lookup
            $directPath = Join-Path $moduleBasePath "$moduleName\$moduleName.psd1"
            if (Test-Path $directPath) {
                $moduleDiscoveryResults[$moduleName] = @{
                    Status = "PATH_ONLY"
                    Path = $directPath
                    Version = "Unknown"
                    Functions = "Unknown"
                }
                Write-Host "   [PATH_ONLY] $moduleName (found at $directPath)" -ForegroundColor Yellow
            } else {
                $moduleDiscoveryResults[$moduleName] = @{
                    Status = "NOT_FOUND"
                    Path = $null
                    Version = $null
                    Functions = 0
                }
                Write-Host "   [NOT_FOUND] $moduleName" -ForegroundColor Red
            }
        }
    } catch {
        Write-Host "   [ERROR] $moduleName - $($_.Exception.Message)" -ForegroundColor Red
        $moduleDiscoveryResults[$moduleName] = @{
            Status = "ERROR"
            Error = $_.Exception.Message
        }
    }
}

# Phase 1 Hour 3-4: Function Export Validation Fix
Write-Host ""
Write-Host "5. Testing Function Export Validation (IntegratedWorkflow Focus)..." -ForegroundColor Yellow

try {
    # Import IntegratedWorkflow module with verbose debugging
    Write-Host "   Importing Unity-Claude-IntegratedWorkflow with debug output..." -ForegroundColor Gray
    
    # Clear any existing module first
    Remove-Module Unity-Claude-IntegratedWorkflow -Force -ErrorAction SilentlyContinue
    
    # Import with verbose output to see validation process
    $integratedWorkflowPath = Join-Path $moduleBasePath "Unity-Claude-IntegratedWorkflow\Unity-Claude-IntegratedWorkflow.psm1"
    if (Test-Path $integratedWorkflowPath) {
        Import-Module $integratedWorkflowPath -Force -Global -Verbose
        
        # Check what functions actually got exported
        $loadedModule = Get-Module Unity-Claude-IntegratedWorkflow -ErrorAction SilentlyContinue
        if ($loadedModule) {
            Write-Host "   Module loaded successfully:" -ForegroundColor Green
            Write-Host "     Name: $($loadedModule.Name)" -ForegroundColor White
            Write-Host "     Version: $($loadedModule.Version)" -ForegroundColor White
            Write-Host "     Path: $($loadedModule.Path)" -ForegroundColor White
            Write-Host "     Exported Functions: $($loadedModule.ExportedFunctions.Count)" -ForegroundColor White
            
            # Test each expected function
            $expectedFunctions = @(
                'New-IntegratedWorkflow',
                'Start-IntegratedWorkflow',
                'Get-IntegratedWorkflowStatus',
                'Stop-IntegratedWorkflow',
                'Initialize-AdaptiveThrottling',
                'Update-AdaptiveThrottling', 
                'New-IntelligentJobBatching',
                'Get-WorkflowPerformanceAnalysis'
            )
            
            Write-Host ""
            Write-Host "6. Function Availability Test:" -ForegroundColor Yellow
            $availableFunctions = 0
            foreach ($func in $expectedFunctions) {
                $command = Get-Command $func -ErrorAction SilentlyContinue
                if ($command) {
                    $availableFunctions++
                    Write-Host "     [AVAILABLE] $func" -ForegroundColor Green
                } else {
                    Write-Host "     [MISSING] $func" -ForegroundColor Red
                }
            }
            
            $successRate = [math]::Round(($availableFunctions / $expectedFunctions.Count) * 100, 1)
            Write-Host ""
            Write-Host "   Function Availability: $availableFunctions/$($expectedFunctions.Count) ($successRate%)" -ForegroundColor $(if ($successRate -ge 90) { "Green" } else { "Red" })
            
        } else {
            Write-Host "   [ERROR] Module did not load into session" -ForegroundColor Red
        }
    } else {
        Write-Host "   [ERROR] IntegratedWorkflow module file not found at: $integratedWorkflowPath" -ForegroundColor Red
    }
    
} catch {
    Write-Host "   [ERROR] Failed to test IntegratedWorkflow module: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "   Error Details: $($_.ScriptStackTrace)" -ForegroundColor Red
}

# Summary and Next Steps
Write-Host ""
Write-Host "=== Fix Summary ===" -ForegroundColor Cyan

$discoverableCount = ($moduleDiscoveryResults.Values | Where-Object { $_.Status -eq "DISCOVERABLE" }).Count
$totalModules = $moduleDiscoveryResults.Count

Write-Host "Module Discovery: $discoverableCount/$totalModules modules discoverable by name" -ForegroundColor White
Write-Host "PSModulePath: $(if ($env:PSModulePath.Contains($moduleBasePath)) { 'CONFIGURED' } else { 'NEEDS_FIX' })" -ForegroundColor $(if ($env:PSModulePath.Contains($moduleBasePath)) { "Green" } else { "Red" })

if ($TestFix) {
    Write-Host ""
    Write-Host "7. Running End-to-End Integration Test..." -ForegroundColor Yellow
    try {
        & ".\Test-Week3-Day5-EndToEndIntegration.ps1" -SaveResults
        Write-Host "   Test completed - check results file for details" -ForegroundColor Green
    } catch {
        Write-Host "   Test execution failed: $($_.Exception.Message)" -ForegroundColor Red
    }
}

Write-Host ""
Write-Host "Next Steps:" -ForegroundColor White
Write-Host "1. If modules are not discoverable, check module manifest RootModule settings" -ForegroundColor Gray
Write-Host "2. If functions are missing, debug function validation in module files" -ForegroundColor Gray  
Write-Host "3. Run with -TestFix to validate fixes" -ForegroundColor Gray
Write-Host "4. Check dependency modules (ParallelProcessing, RunspaceManagement, etc.)" -ForegroundColor Gray

Write-Host ""
Write-Host "=== Fix Complete ===" -ForegroundColor Cyan
# SIG # Begin signature block
# MIIFqQYJKoZIhvcNAQcCoIIFmjCCBZYCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUeHpXoJNInnG03DxONyTo9gwC
# K2SgggMwMIIDLDCCAhSgAwIBAgIQdR0W2SKoK5VE8JId4ZxrRTANBgkqhkiG9w0B
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
# CQQxFgQU6R1ggk5munYhQfNsputixOhT7oowDQYJKoZIhvcNAQEBBQAEggEABYeY
# DROaqz6h7YzL3peltYXRPxT7OkNfKOvTiDF0sQ1idGX2oc84hWkDThFEnCWtKFPB
# 8yXgtz1dv0LZTDrZcC/u7fBPC53uulJ6Rw3h1TeqW0O9MK07vYRMl3Ft4qcfktkI
# Mdex1+O69UGniPLr+VFMiGaNFI5VsVoj/nXyEikfqZoQKZF4BQrPwSv64M9nv1/L
# uQ75Qg9ulGaxvRpZHQEIb014GXoL31a4CGMfV5UikavuPeiDU3hq90VIa5V3Rmwm
# uJYwOMnPjDT85Jar/EyiLrGkpJosuQvxHXLQCnaFt4OAbG7Zi6bi1u91XoxxSSZJ
# QPs+VF93qSJwo3oaoA==
# SIG # End signature block
