# Fix Module Registration Issues - Phase 3E
# This script fixes the "Module imported but not found in session" errors

Write-Host "Phase 3E: Fixing Module Session Registration Issues" -ForegroundColor Cyan
Write-Host "=" * 60 -ForegroundColor Cyan

$modulesToFix = @(
    @{
        Name = 'Unity-Claude-PredictiveAnalysis'
        ManifestPath = 'Unity-Claude-PredictiveAnalysis.psd1'
        ModulePath = 'Unity-Claude-PredictiveAnalysis-Refactored.psm1'
        RequiresForce = $true
    },
    @{
        Name = 'Unity-Claude-ObsolescenceDetection'
        ParentModule = 'Unity-Claude-CPG'
        ManifestPath = 'Unity-Claude-ObsolescenceDetection-Refactored.psd1'
        ModulePath = 'Unity-Claude-ObsolescenceDetection-Refactored.psm1'
        RequiresForce = $true
    },
    @{
        Name = 'Unity-Claude-AutonomousStateTracker-Enhanced'
        ManifestPath = 'Unity-Claude-AutonomousStateTracker-Enhanced.psd1'
        ModulePath = 'Unity-Claude-AutonomousStateTracker-Enhanced-Refactored.psm1'
        RequiresForce = $true
    },
    @{
        Name = 'IntelligentPromptEngine'
        ParentModule = 'Unity-Claude-AutonomousAgent'
        ManifestPath = 'IntelligentPromptEngine-Refactored.psd1'
        ModulePath = 'IntelligentPromptEngine-Refactored.psm1'
        RequiresForce = $true
    },
    @{
        Name = 'Unity-Claude-DocumentationAutomation'
        ManifestPath = 'Unity-Claude-DocumentationAutomation.psd1'
        ModulePath = 'Unity-Claude-DocumentationAutomation-Refactored.psm1'
        RequiresForce = $true
    },
    @{
        Name = 'Unity-Claude-ScalabilityEnhancements'
        ManifestPath = 'Unity-Claude-ScalabilityEnhancements.psd1'
        ModulePath = 'Unity-Claude-ScalabilityEnhancements-Refactored.psm1'
        RequiresForce = $true
    },
    @{
        Name = 'DecisionEngine-Bayesian'
        ParentModule = 'Unity-Claude-CLIOrchestrator\Core\DecisionEngine-Bayesian'
        ManifestPath = 'Unity-Claude-DecisionEngine-Bayesian.psd1'
        ModulePath = 'Unity-Claude-DecisionEngine-Bayesian.psm1'
        RequiresForce = $true
    }
)

$fixCount = 0
$failCount = 0

foreach ($module in $modulesToFix) {
    Write-Host "`nProcessing: $($module.Name)" -ForegroundColor Yellow
    
    # Determine base path
    if ($module.ParentModule) {
        $basePath = Join-Path "C:\UnityProjects\Sound-and-Shoal\Unity-Claude-Automation\Modules" $module.ParentModule
    } else {
        $basePath = Join-Path "C:\UnityProjects\Sound-and-Shoal\Unity-Claude-Automation\Modules" $module.Name
    }
    
    $manifestFullPath = Join-Path $basePath $module.ManifestPath
    $moduleFullPath = Join-Path $basePath $module.ModulePath
    
    # Check if manifest exists
    if (Test-Path $manifestFullPath) {
        Write-Host "  Found manifest: $($module.ManifestPath)" -ForegroundColor Green
        
        # Read the manifest
        try {
            $manifestContent = Get-Content $manifestFullPath -Raw
            
            # Check if RootModule points to the correct file
            if ($manifestContent -match "RootModule\s*=\s*'([^']+)'") {
                $currentRootModule = $matches[1]
                
                # Check if the module file exists
                $moduleFileName = Split-Path $module.ModulePath -Leaf
                if (-not (Test-Path $moduleFullPath)) {
                    Write-Host "  Module file not found: $moduleFileName" -ForegroundColor Red
                    
                    # Look for alternative module files
                    $alternatives = @(
                        $moduleFileName -replace '-Refactored', ''
                        $moduleFileName -replace '\.psm1$', '-Refactored.psm1'
                        "$($module.Name).psm1"
                    )
                    
                    foreach ($alt in $alternatives) {
                        $altPath = Join-Path $basePath $alt
                        if (Test-Path $altPath) {
                            Write-Host "  Found alternative: $alt" -ForegroundColor Cyan
                            
                            # Update manifest to point to correct module
                            $manifestContent = $manifestContent -replace "RootModule\s*=\s*'[^']+'", "RootModule = '$alt'"
                            Set-Content $manifestFullPath $manifestContent -Encoding UTF8
                            Write-Host "  Updated manifest RootModule to: $alt" -ForegroundColor Green
                            $fixCount++
                            break
                        }
                    }
                } elseif ($currentRootModule -ne $moduleFileName) {
                    Write-Host "  RootModule mismatch - Current: $currentRootModule, Expected: $moduleFileName" -ForegroundColor Yellow
                    
                    # Update manifest
                    $manifestContent = $manifestContent -replace "RootModule\s*=\s*'[^']+'", "RootModule = '$moduleFileName'"
                    Set-Content $manifestFullPath $manifestContent -Encoding UTF8
                    Write-Host "  Updated manifest RootModule to: $moduleFileName" -ForegroundColor Green
                    $fixCount++
                } else {
                    Write-Host "  RootModule correctly set to: $currentRootModule" -ForegroundColor Green
                }
                
                # Ensure module exports are properly defined
                if ($manifestContent -notmatch "FunctionsToExport\s*=") {
                    Write-Host "  WARNING: No FunctionsToExport defined in manifest" -ForegroundColor Yellow
                    # We'll handle this in a moment
                }
            }
        } catch {
            Write-Host "  ERROR: Failed to process manifest - $_" -ForegroundColor Red
            $failCount++
        }
    } else {
        Write-Host "  Manifest not found: $manifestFullPath" -ForegroundColor Red
        
        # Check if there's a base manifest without -Refactored suffix
        $baseManifestPath = Join-Path $basePath "$($module.Name).psd1"
        if (Test-Path $baseManifestPath) {
            Write-Host "  Found base manifest: $($module.Name).psd1" -ForegroundColor Cyan
            
            # Check what it points to
            $baseContent = Get-Content $baseManifestPath -Raw
            if ($baseContent -match "RootModule\s*=\s*'([^']+)'") {
                $rootModule = $matches[1]
                
                # If it already points to refactored version, we're good
                if ($rootModule -like '*-Refactored.psm1') {
                    Write-Host "  Base manifest already points to refactored module: $rootModule" -ForegroundColor Green
                } else {
                    # Update to point to refactored version if it exists
                    $refactoredModule = $rootModule -replace '\.psm1$', '-Refactored.psm1'
                    $refactoredPath = Join-Path $basePath $refactoredModule
                    
                    if (Test-Path $refactoredPath) {
                        $baseContent = $baseContent -replace "RootModule\s*=\s*'[^']+'", "RootModule = '$refactoredModule'"
                        Set-Content $baseManifestPath $baseContent -Encoding UTF8
                        Write-Host "  Updated base manifest to use: $refactoredModule" -ForegroundColor Green
                        $fixCount++
                    }
                }
            }
        } else {
            Write-Host "  No manifest found at all for $($module.Name)" -ForegroundColor Red
            $failCount++
        }
    }
}

Write-Host "`n" + ("=" * 60) -ForegroundColor Cyan
Write-Host "Phase 3E Results:" -ForegroundColor Cyan
Write-Host "  Fixed: $fixCount modules" -ForegroundColor Green
Write-Host "  Failed: $failCount modules" -ForegroundColor $(if ($failCount -gt 0) { 'Red' } else { 'Green' })
Write-Host "`nPhase 3E Complete!" -ForegroundColor Cyan
# SIG # Begin signature block
# MIIFzgYJKoZIhvcNAQcCoIIFvzCCBbsCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCCGI7lW/dN/FH0n
# Bw4f5UFAxlM1CyEIN4wCPXGFPRa9lqCCAzAwggMsMIICFKADAgECAhB1HRbZIqgr
# lUTwkh3hnGtFMA0GCSqGSIb3DQEBCwUAMC4xLDAqBgNVBAMMI1VuaXR5LUNsYXVk
# ZS1BdXRvbWF0aW9uLURldmVsb3BtZW50MB4XDTI1MDgyMDIxMTUxN1oXDTI2MDgy
# MDIxMzUxN1owLjEsMCoGA1UEAwwjVW5pdHktQ2xhdWRlLUF1dG9tYXRpb24tRGV2
# ZWxvcG1lbnQwggEiMA0GCSqGSIb3DQEBAQUAA4IBDwAwggEKAoIBAQCx4feqKdUQ
# 6GufY4umNzlM1Pi8aHUGR8HlfhIWFjsrRAxCxhieRlWbHe0Hw+pVBeX76X57e5Pu
# 4Kxxzu+MxMry0NJYf3yOLRTfhYskHBcLraXUCtrMwqnhPKvul6Sx6Lu8vilk605W
# ADJNifl3WFuexVCYJJM9G2mfuYIDN+rZ5zmpn0qCXum49bm629h+HyJ205Zrn9aB
# hIrA4i/JlrAh1kosWnCo62psl7ixbNVqFqwWEt+gAqSeIo4ChwkOQl7GHmk78Q5I
# oRneY4JTVlKzhdZEYhJGFXeoZml/5jcmUcox4UNYrKdokE7z8ZTmyowBOUNS+sHI
# G1TY5DZSb8vdAgMBAAGjRjBEMA4GA1UdDwEB/wQEAwIHgDATBgNVHSUEDDAKBggr
# BgEFBQcDAzAdBgNVHQ4EFgQUfDms7LrGVboHjmwlSyIjYD/JLQwwDQYJKoZIhvcN
# AQELBQADggEBABRMsfT7DzKy+aFi4HDg0MpxmbjQxOH1lzUzanaECRiyA0sn7+sA
# /4jvis1+qC5NjDGkLKOTCuDzIXnBWLCCBugukXbIO7g392ANqKdHjBHw1WlLvMVk
# 4WSmY096lzpvDd3jJApr/Alcp4KmRGNLnQ3vv+F9Uj58Uo1qjs85vt6fl9xe5lo3
# rFahNHL4ngjgyF8emNm7FItJeNtVe08PhFn0caOX0FTzXrZxGGO6Ov8tzf91j/qK
# QdBifG7Fx3FF7DifNqoBBo55a7q0anz30k8p+V0zllrLkgGXfOzXmA1L37Qmt3QB
# FCdJVigjQMuHcrJsWd8rg857Og0un91tfZIxggH0MIIB8AIBATBCMC4xLDAqBgNV
# BAMMI1VuaXR5LUNsYXVkZS1BdXRvbWF0aW9uLURldmVsb3BtZW50AhB1HRbZIqgr
# lUTwkh3hnGtFMA0GCWCGSAFlAwQCAQUAoIGEMBgGCisGAQQBgjcCAQwxCjAIoAKA
# AKECgAAwGQYJKoZIhvcNAQkDMQwGCisGAQQBgjcCAQQwHAYKKwYBBAGCNwIBCzEO
# MAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIPviuwGnV2J8NrW++wcS+94V
# bFAAL4wn5L5OIa5bw1z/MA0GCSqGSIb3DQEBAQUABIIBAEM9k4A3kV7oKFzLcTKl
# oR4THRJxMP1hPFzAvPtyiW5XTmAllhgcvw4fSdqEiSNXO6OmWjEzlaFBvjCjJBzY
# M4diKZCKfMV3xsqFNyJvBYS9jHwaC0NebYzNDmDDGHawiIBGjZcNkzZqWcorIzQ4
# E62g92IZq/SbXdn4DEZqj90AF4H1pZmAfKtfLEnD9X9heS4paPLSl7bQjqnSImQz
# VEJgeSG4asLHWgV1NQNnEme/N8UsOf6dmepHYsDPz8HPFeFoMAlu3cx++N0vxRbo
# zrqDECfuSTjq1ujdC22fqaMKQ3VRcktjtv3v2cIzdGb5E3FcdepMrivgtiJruVKZ
# Inw=
# SIG # End signature block
