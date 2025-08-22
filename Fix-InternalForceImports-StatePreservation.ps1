# Fix-InternalForceImports-StatePreservation.ps1
# Replace all internal Import-Module -Force calls with conditional imports to preserve script variables
# Addresses root cause of Unity project registration state reset issue
# Date: 2025-08-21

[CmdletBinding()]
param(
    [switch]$CreateBackups = $true,
    [switch]$TestFix
)

Write-Host "=== Fix Internal Force Imports - State Preservation ===" -ForegroundColor Cyan
Write-Host "ROOT CAUSE: Import-Module -Force calls reset script-level variables" -ForegroundColor Yellow
Write-Host "SOLUTION: Replace with conditional imports that preserve module state" -ForegroundColor White
Write-Host ""

# Modules to fix based on grep results
$modulesToFix = @(
    @{
        Name = "Unity-Claude-UnityParallelization"
        Path = "C:\UnityProjects\Sound-and-Shoal\Unity-Claude-Automation\Modules\Unity-Claude-UnityParallelization\Unity-Claude-UnityParallelization.psm1"
        ForceImports = @(
            "Import-Module Unity-Claude-RunspaceManagement -Force -ErrorAction Stop",
            "Import-Module Unity-Claude-ParallelProcessing -Force -ErrorAction Stop"
        )
    },
    @{
        Name = "Unity-Claude-IntegratedWorkflow" 
        Path = "C:\UnityProjects\Sound-and-Shoal\Unity-Claude-Automation\Modules\Unity-Claude-IntegratedWorkflow\Unity-Claude-IntegratedWorkflow.psm1"
        ForceImports = @(
            "Import-Module `$RunspaceManagementPath -Force -ErrorAction Stop",
            "Import-Module `$UnityParallelizationPath -Force -ErrorAction Stop", 
            "Import-Module `$ClaudeParallelizationPath -Force -ErrorAction Stop"
        )
    },
    @{
        Name = "Unity-Claude-ClaudeParallelization"
        Path = "C:\UnityProjects\Sound-and-Shoal\Unity-Claude-Automation\Modules\Unity-Claude-ClaudeParallelization\Unity-Claude-ClaudeParallelization.psm1"
        ForceImports = @(
            "Import-Module Unity-Claude-RunspaceManagement -Force -ErrorAction Stop",
            "Import-Module Unity-Claude-ParallelProcessing -Force -ErrorAction Stop"
        )
    },
    @{
        Name = "Unity-Claude-RunspaceManagement"
        Path = "C:\UnityProjects\Sound-and-Shoal\Unity-Claude-Automation\Modules\Unity-Claude-RunspaceManagement\Unity-Claude-RunspaceManagement.psm1"
        ForceImports = @(
            "Import-Module Unity-Claude-ParallelProcessing -Force -ErrorAction Stop"
        )
    }
)

# Create backups if requested
if ($CreateBackups) {
    $backupTimestamp = Get-Date -Format "yyyyMMdd_HHmmss"
    $backupDir = ".\ModuleStatePreservation_Backups_$backupTimestamp"
    New-Item -Path $backupDir -ItemType Directory -Force | Out-Null
    
    Write-Host "1. Creating Backups..." -ForegroundColor Yellow
    
    foreach ($module in $modulesToFix) {
        if (Test-Path $module.Path) {
            $backupFile = Join-Path $backupDir "$($module.Name).psm1.backup"
            Copy-Item $module.Path $backupFile -Force
            Write-Host "   Backed up: $($module.Name)" -ForegroundColor Green
        }
    }
    Write-Host "   Backups completed in: $backupDir" -ForegroundColor Green
}

Write-Host ""
Write-Host "2. Fixing Internal Import-Module -Force Calls..." -ForegroundColor Yellow

$modulesFixed = 0
foreach ($module in $modulesToFix) {
    if (-not (Test-Path $module.Path)) {
        Write-Host "   [SKIP] $($module.Name) - Module file not found" -ForegroundColor Red
        continue
    }
    
    Write-Host "   [PROCESSING] $($module.Name)..." -ForegroundColor Cyan
    
    try {
        # Read current module content
        $moduleContent = Get-Content $module.Path -Raw -Encoding UTF8
        $updatedContent = $moduleContent
        $changesApplied = 0
        
        # Fix each Force import pattern
        foreach ($forceImport in $module.ForceImports) {
            Write-Host "     Searching for: $forceImport" -ForegroundColor Gray
            
            # Create conditional import replacement
            if ($forceImport -match 'Import-Module\s+(.+?)\s+-Force\s+-ErrorAction\s+Stop') {
                $moduleName = $matches[1]
                
                # Handle variable paths vs module names
                if ($moduleName.StartsWith('$')) {
                    # Variable path (like $RunspaceManagementPath)
                    $conditionalImport = @"
if (-not (Get-Module Unity-Claude-RunspaceManagement -ErrorAction SilentlyContinue)) {
        Import-Module $moduleName -ErrorAction Stop
    } else {
        Write-Host "[DEBUG] [StatePreservation] Module already loaded, skipping import to preserve state" -ForegroundColor Gray
    }"
"@
                } else {
                    # Direct module name
                    $conditionalImport = @"
if (-not (Get-Module $moduleName -ErrorAction SilentlyContinue)) {
        Import-Module $moduleName -ErrorAction Stop
    } else {
        Write-Host "[DEBUG] [StatePreservation] Module $moduleName already loaded, skipping import to preserve state" -ForegroundColor Gray
    }"
"@
                }
                
                # Replace the Force import with conditional import
                if ($updatedContent -match [regex]::Escape($forceImport)) {
                    $updatedContent = $updatedContent -replace [regex]::Escape($forceImport), $conditionalImport
                    $changesApplied++
                    Write-Host "     [FIXED] Replaced Force import with conditional import" -ForegroundColor Green
                }
            }
        }
        
        # Write updated content if changes were made
        if ($changesApplied -gt 0) {
            $updatedContent | Set-Content $module.Path -Encoding UTF8 -Force
            Write-Host "     [SUCCESS] Applied $changesApplied fix(es) to preserve script variables" -ForegroundColor Green
            $modulesFixed++
        } else {
            Write-Host "     [INFO] No Force imports found or already fixed" -ForegroundColor Yellow
        }
        
    } catch {
        Write-Host "     [ERROR] Failed to fix module: $($_.Exception.Message)" -ForegroundColor Red
    }
}

Write-Host ""
Write-Host "=== Fix Summary ===" -ForegroundColor Cyan

Write-Host "Modules processed: $($modulesToFix.Count)" -ForegroundColor White
Write-Host "Modules fixed: $modulesFixed" -ForegroundColor $(if ($modulesFixed -eq $modulesToFix.Count) { "Green" } else { "Yellow" })

Write-Host ""
Write-Host "Expected Result:" -ForegroundColor White
Write-Host "- No more module nesting limit warnings" -ForegroundColor Gray
Write-Host "- Unity project registration state preserved throughout test execution" -ForegroundColor Gray
Write-Host "- Test pass rate should improve to 90%+ due to state preservation" -ForegroundColor Gray

if ($TestFix) {
    Write-Host ""
    Write-Host "3. Testing Fix..." -ForegroundColor Yellow
    try {
        Write-Host "   Running end-to-end integration test..." -ForegroundColor Gray
        & ".\Test-Week3-Day5-EndToEndIntegration-Final.ps1" -SaveResults
        Write-Host "   Test completed - check results for improvement" -ForegroundColor Green
    } catch {
        Write-Host "   Test execution failed: $($_.Exception.Message)" -ForegroundColor Red
    }
}

Write-Host ""
Write-Host "Next Steps:" -ForegroundColor White
Write-Host "1. Run Test-Week3-Day5-EndToEndIntegration-Final.ps1 to validate fix" -ForegroundColor Gray
Write-Host "2. Expected: Unity project registration should persist during workflow creation" -ForegroundColor Gray
Write-Host "3. Target: 90%+ test pass rate with state preservation" -ForegroundColor Gray

Write-Host ""
Write-Host "=== Force Import Fix Complete ===" -ForegroundColor Cyan
# SIG # Begin signature block
# MIIFqQYJKoZIhvcNAQcCoIIFmjCCBZYCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUyAlesqzzjKlFjwDY38g923/w
# hYSgggMwMIIDLDCCAhSgAwIBAgIQdR0W2SKoK5VE8JId4ZxrRTANBgkqhkiG9w0B
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
# CQQxFgQUVgdwmAnZpcrWRYdjM7BjZ6Afcj4wDQYJKoZIhvcNAQEBBQAEggEAmsh+
# e29FUtdQ+IbNfEkZSdsOgDUtVGTUbXZB1hW3JPVAm5QOO6b4Y3cJedRKnUeBxEmu
# zC5hn8q8Gh17s0nOdhG4MyNHyg1EkCguWwG0xHY4eWgAWuy8Buy9qHZu/v7Z7LI8
# 6Ug3m0BXsFkIxu7psLeVkkN49ywsyizlC7000U44SVfUOej35YRtnKTyM41+Xjq7
# 5V41K6UwkVPkrOPb8ud0/IxWRxy5EQuHELDrL7AEB39qn3wFlHzaDi9HIhvl045c
# FJvxgspG1KdL2TEaAMpnwA8BDLNEfG6Pqbm9qIV1SnAiKwh0zElD+tlZaPFI2kD8
# bJXIdc0pfHVeYzxUTQ==
# SIG # End signature block
