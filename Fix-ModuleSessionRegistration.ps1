#requires -Version 5.1
<#
.SYNOPSIS
    Fixes module session registration issues for refactored modules
    
.DESCRIPTION
    Resolves "Module imported but not found in session" errors by ensuring
    manifest files point to correctly named module files
#>

[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'

Write-Host "Fixing Module Session Registration Issues" -ForegroundColor Cyan
Write-Host "=" * 50 -ForegroundColor Cyan

# Define modules that need fixing
$ModulesToFix = @(
    @{
        Name = 'Unity-Claude-PredictiveAnalysis'
        Path = 'Modules\Unity-Claude-PredictiveAnalysis'
        RefactoredFile = 'Unity-Claude-PredictiveAnalysis-Refactored.psm1'
        MainFile = 'Unity-Claude-PredictiveAnalysis.psm1'
        ManifestFile = 'Unity-Claude-PredictiveAnalysis.psd1'
    },
    @{
        Name = 'Unity-Claude-ObsolescenceDetection'
        Path = 'Modules\Unity-Claude-CPG'
        RefactoredFile = 'Unity-Claude-ObsolescenceDetection-Refactored.psm1'
        MainFile = 'Unity-Claude-ObsolescenceDetection.psm1'
        ManifestFile = 'Unity-Claude-ObsolescenceDetection-Refactored.psd1'
        NewManifestFile = 'Unity-Claude-ObsolescenceDetection.psd1'
    },
    @{
        Name = 'Unity-Claude-AutonomousStateTracker-Enhanced'
        Path = 'Modules\Unity-Claude-AutonomousStateTracker-Enhanced'
        RefactoredFile = 'Unity-Claude-AutonomousStateTracker-Enhanced-Refactored.psm1'
        MainFile = 'Unity-Claude-AutonomousStateTracker-Enhanced.psm1'
        ManifestFile = 'Unity-Claude-AutonomousStateTracker-Enhanced-Refactored.psd1'
        NewManifestFile = 'Unity-Claude-AutonomousStateTracker-Enhanced.psd1'
    },
    @{
        Name = 'IntelligentPromptEngine'
        Path = 'Modules\Unity-Claude-AutonomousAgent'
        RefactoredFile = 'IntelligentPromptEngine-Refactored.psm1'
        MainFile = 'IntelligentPromptEngine.psm1'
        ManifestFile = 'IntelligentPromptEngine-Refactored.psd1'
        NewManifestFile = 'IntelligentPromptEngine.psd1'
    },
    @{
        Name = 'Unity-Claude-DocumentationAutomation'
        Path = 'Modules\Unity-Claude-DocumentationAutomation'
        RefactoredFile = 'Unity-Claude-DocumentationAutomation-Refactored.psm1'
        MainFile = 'Unity-Claude-DocumentationAutomation.psm1'
        ManifestFile = 'Unity-Claude-DocumentationAutomation-Refactored.psd1'
        NewManifestFile = 'Unity-Claude-DocumentationAutomation.psd1'
    },
    @{
        Name = 'Unity-Claude-ScalabilityEnhancements'
        Path = 'Modules\Unity-Claude-ScalabilityEnhancements'
        RefactoredFile = 'Unity-Claude-ScalabilityEnhancements-Refactored.psm1'
        MainFile = 'Unity-Claude-ScalabilityEnhancements.psm1'
        ManifestFile = 'Unity-Claude-ScalabilityEnhancements-Refactored.psd1'
        NewManifestFile = 'Unity-Claude-ScalabilityEnhancements.psd1'
    },
    @{
        Name = 'Unity-Claude-DecisionEngine-Bayesian'
        Path = 'Modules\Unity-Claude-CLIOrchestrator\Core\DecisionEngine-Bayesian'
        RefactoredFile = 'Unity-Claude-DecisionEngine-Bayesian.psm1'
        MainFile = 'Unity-Claude-DecisionEngine-Bayesian.psm1'
        ManifestFile = 'Unity-Claude-DecisionEngine-Bayesian.psd1'
        IsAlreadyCorrect = $true
    }
)

$BaseDir = Split-Path $PSCommandPath -Parent
$FixedCount = 0
$FailedCount = 0

foreach ($Module in $ModulesToFix) {
    Write-Host "`nProcessing: $($Module.Name)" -ForegroundColor Yellow
    
    try {
        $ModulePath = Join-Path $BaseDir $Module.Path
        
        # Skip if already correct
        if ($Module.IsAlreadyCorrect) {
            Write-Host "  Module already has correct structure, checking manifest..." -ForegroundColor Gray
            $ManifestPath = Join-Path $ModulePath $Module.ManifestFile
            if (Test-Path $ManifestPath) {
                Write-Host "  Manifest exists at: $ManifestPath" -ForegroundColor Green
                $FixedCount++
                continue
            } else {
                Write-Host "  Manifest missing, needs creation" -ForegroundColor Yellow
            }
        }
        
        # Check if refactored file exists
        $RefactoredPath = Join-Path $ModulePath $Module.RefactoredFile
        if (-not (Test-Path $RefactoredPath)) {
            Write-Warning "  Refactored file not found: $RefactoredPath"
            $FailedCount++
            continue
        }
        
        # Copy refactored file to main file
        $MainPath = Join-Path $ModulePath $Module.MainFile
        Write-Host "  Copying $($Module.RefactoredFile) to $($Module.MainFile)"
        Copy-Item -Path $RefactoredPath -Destination $MainPath -Force
        
        # Handle manifest
        $ManifestPath = Join-Path $ModulePath $Module.ManifestFile
        
        if ($Module.NewManifestFile) {
            # Need to rename manifest
            $NewManifestPath = Join-Path $ModulePath $Module.NewManifestFile
            
            if (Test-Path $ManifestPath) {
                Write-Host "  Copying manifest from $($Module.ManifestFile) to $($Module.NewManifestFile)"
                Copy-Item -Path $ManifestPath -Destination $NewManifestPath -Force
                $ManifestPath = $NewManifestPath
            } else {
                Write-Host "  Creating new manifest: $($Module.NewManifestFile)"
                $ManifestPath = $NewManifestPath
            }
        }
        
        # Update or create manifest
        if (Test-Path $ManifestPath) {
            Write-Host "  Updating manifest RootModule reference"
            $ManifestContent = Get-Content $ManifestPath -Raw
            $ManifestContent = $ManifestContent -replace "RootModule\s*=\s*'[^']+\.psm1'", "RootModule = '$($Module.MainFile)'"
            Set-Content -Path $ManifestPath -Value $ManifestContent -Encoding UTF8
        } else {
            Write-Host "  Creating new manifest for $($Module.Name)"
            $ManifestContent = @"
@{
    RootModule = '$($Module.MainFile)'
    ModuleVersion = '2.0.0'
    GUID = [guid]::NewGuid().ToString()
    Author = 'Unity-Claude-Automation Framework'
    CompanyName = 'Unity-Claude-Automation'
    Copyright = '(c) Unity-Claude-Automation Framework. All rights reserved.'
    Description = 'Refactored $($Module.Name) Module'
    PowerShellVersion = '5.1'
    FunctionsToExport = '*'
    CmdletsToExport = @()
    VariablesToExport = '*'
    AliasesToExport = '*'
}
"@
            Set-Content -Path $ManifestPath -Value $ManifestContent -Encoding UTF8
        }
        
        Write-Host "  Successfully fixed: $($Module.Name)" -ForegroundColor Green
        $FixedCount++
    }
    catch {
        Write-Host "  Failed to fix $($Module.Name): $_" -ForegroundColor Red
        $FailedCount++
    }
}

Write-Host "`n" + ("=" * 50) -ForegroundColor Cyan
Write-Host "Module Registration Fix Complete" -ForegroundColor Cyan
Write-Host "Fixed: $FixedCount modules" -ForegroundColor Green
if ($FailedCount -gt 0) {
    Write-Host "Failed: $FailedCount modules" -ForegroundColor Red
}

Write-Host "`nTo verify fixes, run:" -ForegroundColor Cyan
Write-Host "  .\Test-AllRefactoredModules-Fixed.ps1" -ForegroundColor Yellow
# SIG # Begin signature block
# MIIFzgYJKoZIhvcNAQcCoIIFvzCCBbsCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCDqLFphZxw9J1u0
# m9WyDGoEL5uvs5bT9D3V+DHUEwYujqCCAzAwggMsMIICFKADAgECAhB1HRbZIqgr
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
# MAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIMAV1E3V2ue6JMfew7aAl9DM
# CtWyiWOu4MtR0R5N1BECMA0GCSqGSIb3DQEBAQUABIIBAEpbPIaqx5C0d2UFEVc5
# /8klgQ5N8vNDz5/grof+HIIvczQo3fN6B9XZenAuP2HfF3tpc6UeIVdDHnybwPKF
# dMr7Tjg6UVl98u2aO0+Xljf2P+lBkeevixiQnu8uMDZhRbUSbWOqKFj2t7zLoK2I
# WDYaJ9zuUb/737D2bbdT7Eia7/M2GPBnM02VSQYdxRtulDTVxIfIoI54Rec4vSp4
# 8UWnWBlroK21wXU9BupHGPu9EE0/EMu2ySI6YD8rEJURgf//KcW9KIOObkZ8g4cO
# gnAT6yG6rWN+0cyL1AFlQDC9h1Nk/oKruTeeoJrJ+vdeOI1f0nor+DBSmbYGXjFK
# 1sc=
# SIG # End signature block
