#Requires -Version 5.1
<#
.SYNOPSIS
    Comprehensive fixes for all refactored module issues
    
.DESCRIPTION
    Addresses all syntax errors, missing functions, and dependency issues
#>

[CmdletBinding()]
param(
    [switch]$DryRun
)

$ErrorActionPreference = 'Continue'

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "  COMPREHENSIVE MODULE FIX UTILITY      " -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan

$fixCount = 0
$errors = @()

# Helper function to add missing functions to a file
function Add-MissingFunction {
    param(
        [string]$FilePath,
        [string]$FunctionCode,
        [string]$CheckPattern
    )
    
    if (Test-Path $FilePath) {
        $content = Get-Content $FilePath -Raw
        
        if ($content -notmatch $CheckPattern) {
            $content = $FunctionCode + "`n`n" + $content
            
            if (-not $script:DryRun) {
                $content | Out-File $FilePath -Encoding UTF8
                return $true
            } else {
                Write-Host "    [DryRun] Would add missing function" -ForegroundColor Cyan
                return $false
            }
        }
    }
    return $false
}

# Fix 1: Unity-Claude-IntegratedWorkflow - Missing Write-IntegratedWorkflowLog
Write-Host "[1/10] Fixing Unity-Claude-IntegratedWorkflow..." -ForegroundColor Yellow

$workflowCore = "C:\UnityProjects\Sound-and-Shoal\Unity-Claude-Automation\Modules\Unity-Claude-IntegratedWorkflow\Core\WorkflowCore.psm1"
if (Test-Path $workflowCore) {
    $content = Get-Content $workflowCore -Raw
    
    # Ensure Write-IntegratedWorkflowLog is exported
    if ($content -notmatch 'Export-ModuleMember.*Write-IntegratedWorkflowLog') {
        $content = $content -replace '(Export-ModuleMember -Function \*)', '$1, Write-IntegratedWorkflowLog'
        
        if (-not $DryRun) {
            $content | Out-File $workflowCore -Encoding UTF8
            Write-Host "  Fixed: Added Write-IntegratedWorkflowLog to exports" -ForegroundColor Green
            $fixCount++
        }
    }
}

# Fix 2: Unity-Claude-RunspaceManagement - Fix path issues
Write-Host "[2/10] Fixing Unity-Claude-RunspaceManagement..." -ForegroundColor Yellow

$runspaceRefactored = "C:\UnityProjects\Sound-and-Shoal\Unity-Claude-Automation\Modules\Unity-Claude-RunspaceManagement\Unity-Claude-RunspaceManagement-Refactored.psm1"
if (Test-Path $runspaceRefactored) {
    $content = Get-Content $runspaceRefactored -Raw
    
    # Fix the component loading section
    $newComponentLoading = @'
# Load modular components
$componentsToLoad = @(
    "RunspaceCore.psm1",
    "SessionStateConfiguration.psm1",
    "ModuleVariablePreloading.psm1",
    "VariableSharing.psm1",
    "RunspacePoolManagement.psm1",
    "ProductionRunspacePool.psm1",
    "ThrottlingResourceControl.psm1"
)

$loadedComponents = @()
$failedComponents = @()

foreach ($component in $componentsToLoad) {
    $componentPath = Join-Path (Join-Path $PSScriptRoot "Core") $component
    
    try {
        if (Test-Path $componentPath) {
            Import-Module $componentPath -Force -ErrorAction Stop
            $loadedComponents += $component
        } else {
            throw "Component file not found: $componentPath"
        }
    } catch {
        $failedComponents += @{
            Component = $component
            Error = $_.Exception.Message
        }
        Write-Warning "  [FAILED] Could not load component ${component} : $($_.Exception.Message)"
    }
}
'@
    
    # Replace the problematic loading section
    $content = $content -replace '(?s)# Load modular components.*?foreach \(\$component in \$componentsToLoad\) \{.*?\}', $newComponentLoading
    
    if (-not $DryRun) {
        $content | Out-File $runspaceRefactored -Encoding UTF8
        Write-Host "  Fixed: Component loading paths" -ForegroundColor Green
        $fixCount++
    }
}

# Fix 3: Unity-Claude-Learning components - Add missing functions
Write-Host "[3/10] Fixing Unity-Claude-Learning components..." -ForegroundColor Yellow

$learningCore = "C:\UnityProjects\Sound-and-Shoal\Unity-Claude-Automation\Modules\Unity-Claude-Learning\Core\LearningCore.psm1"
if (Test-Path $learningCore) {
    $content = Get-Content $learningCore -Raw
    
    # Ensure Write-ModuleLog is properly exported
    if ($content -notmatch 'Export-ModuleMember.*Write-ModuleLog') {
        if ($content -match 'Export-ModuleMember -Function (.+)') {
            $existingFunctions = $matches[1]
            $content = $content -replace "Export-ModuleMember -Function .+", "Export-ModuleMember -Function $existingFunctions, Write-ModuleLog, Get-LearningConfiguration"
        } else {
            $content += "`n`nExport-ModuleMember -Function Write-ModuleLog, Get-LearningConfiguration"
        }
        
        if (-not $DryRun) {
            $content | Out-File $learningCore -Encoding UTF8
            Write-Host "  Fixed: LearningCore exports" -ForegroundColor Green
            $fixCount++
        }
    }
}

# Fix 4: Unity-Claude-UnityParallelization - Add missing Initialize-ModuleDependencies
Write-Host "[4/10] Fixing Unity-Claude-UnityParallelization..." -ForegroundColor Yellow

$unityParallelCore = "C:\UnityProjects\Sound-and-Shoal\Unity-Claude-Automation\Modules\Unity-Claude-UnityParallelization\Core\ParallelizationCore.psm1"
if (Test-Path $unityParallelCore) {
    $initFunction = @'
function Initialize-ModuleDependencies {
    [CmdletBinding()]
    param()
    
    try {
        # Initialize any required dependencies
        if (-not (Get-Module Unity-Claude-RunspaceManagement)) {
            $runspacePath = Join-Path (Split-Path (Split-Path $PSScriptRoot -Parent) -Parent) "Unity-Claude-RunspaceManagement\Unity-Claude-RunspaceManagement.psd1"
            if (Test-Path $runspacePath) {
                Import-Module $runspacePath -Force -Global
            }
        }
        
        if (-not (Get-Module Unity-Claude-ParallelProcessing)) {
            $parallelPath = Join-Path (Split-Path (Split-Path $PSScriptRoot -Parent) -Parent) "Unity-Claude-ParallelProcessing\Unity-Claude-ParallelProcessing.psd1"
            if (Test-Path $parallelPath) {
                Import-Module $parallelPath -Force -Global
            }
        }
        
        return $true
    } catch {
        Write-Warning "Failed to initialize dependencies: $_"
        return $false
    }
}
'@
    
    if (Add-MissingFunction -FilePath $unityParallelCore -FunctionCode $initFunction -CheckPattern "Initialize-ModuleDependencies") {
        Write-Host "  Fixed: Added Initialize-ModuleDependencies" -ForegroundColor Green
        $fixCount++
        
        # Also export it
        $content = Get-Content $unityParallelCore -Raw
        if ($content -notmatch 'Export-ModuleMember.*Initialize-ModuleDependencies') {
            if ($content -match 'Export-ModuleMember -Function (.+)') {
                $existingFunctions = $matches[1]
                $content = $content -replace "Export-ModuleMember -Function .+", "Export-ModuleMember -Function $existingFunctions, Initialize-ModuleDependencies"
            } else {
                $content += "`n`nExport-ModuleMember -Function Initialize-ModuleDependencies"
            }
            $content | Out-File $unityParallelCore -Encoding UTF8
        }
    }
}

# Fix 5: Unity-Claude-PredictiveAnalysis manifest path
Write-Host "[5/10] Fixing Unity-Claude-PredictiveAnalysis manifest..." -ForegroundColor Yellow

$predictiveManifestPath = "C:\UnityProjects\Sound-and-Shoal\Unity-Claude-Automation\Modules\Unity-Claude-PredictiveAnalysis\Unity-Claude-PredictiveAnalysis-Refactored.psd1"
$correctManifestPath = "C:\UnityProjects\Sound-and-Shoal\Unity-Claude-Automation\Modules\Unity-Claude-PredictiveAnalysis\Unity-Claude-PredictiveAnalysis.psd1"

if ((Test-Path $predictiveManifestPath) -and (-not (Test-Path $correctManifestPath))) {
    if (-not $DryRun) {
        Copy-Item $predictiveManifestPath $correctManifestPath -Force
        Write-Host "  Fixed: Created correct manifest path" -ForegroundColor Green
        $fixCount++
    }
}

# Fix 6: Unity-Claude-ObsolescenceDetection manifest path
Write-Host "[6/10] Fixing Unity-Claude-ObsolescenceDetection manifest..." -ForegroundColor Yellow

$obsolescenceManifestPath = "C:\UnityProjects\Sound-and-Shoal\Unity-Claude-Automation\Modules\Unity-Claude-CPG\Unity-Claude-ObsolescenceDetection-Refactored.psd1"
$correctObsolescenceManifest = "C:\UnityProjects\Sound-and-Shoal\Unity-Claude-Automation\Modules\Unity-Claude-CPG\Unity-Claude-ObsolescenceDetection.psd1"

if ((Test-Path $obsolescenceManifestPath) -and (-not (Test-Path $correctObsolescenceManifest))) {
    if (-not $DryRun) {
        Copy-Item $obsolescenceManifestPath $correctObsolescenceManifest -Force
        Write-Host "  Fixed: Created correct manifest path" -ForegroundColor Green
        $fixCount++
    }
}

# Fix 7: Unity-Claude-AutonomousStateTracker-Enhanced manifest path
Write-Host "[7/10] Fixing Unity-Claude-AutonomousStateTracker-Enhanced manifest..." -ForegroundColor Yellow

$stateTrackerManifestPath = "C:\UnityProjects\Sound-and-Shoal\Unity-Claude-Automation\Modules\Unity-Claude-AutonomousStateTracker-Enhanced\Unity-Claude-AutonomousStateTracker-Enhanced-Refactored.psd1"
$correctStateTrackerManifest = "C:\UnityProjects\Sound-and-Shoal\Unity-Claude-Automation\Modules\Unity-Claude-AutonomousStateTracker-Enhanced\Unity-Claude-AutonomousStateTracker-Enhanced.psd1"

if ((Test-Path $stateTrackerManifestPath) -and (-not (Test-Path $correctStateTrackerManifest))) {
    if (-not $DryRun) {
        Copy-Item $stateTrackerManifestPath $correctStateTrackerManifest -Force
        Write-Host "  Fixed: Created correct manifest path" -ForegroundColor Green
        $fixCount++
    }
}

# Fix 8: IntelligentPromptEngine manifest path
Write-Host "[8/10] Fixing IntelligentPromptEngine manifest..." -ForegroundColor Yellow

$promptEngineManifestPath = "C:\UnityProjects\Sound-and-Shoal\Unity-Claude-Automation\Modules\Unity-Claude-AutonomousAgent\IntelligentPromptEngine-Refactored.psd1"
$correctPromptEngineManifest = "C:\UnityProjects\Sound-and-Shoal\Unity-Claude-Automation\Modules\Unity-Claude-AutonomousAgent\IntelligentPromptEngine.psd1"

if ((Test-Path $promptEngineManifestPath) -and (-not (Test-Path $correctPromptEngineManifest))) {
    if (-not $DryRun) {
        Copy-Item $promptEngineManifestPath $correctPromptEngineManifest -Force
        Write-Host "  Fixed: Created correct manifest path" -ForegroundColor Green
        $fixCount++
    }
}

# Fix 9: Unity-Claude-DocumentationAutomation manifest path
Write-Host "[9/10] Fixing Unity-Claude-DocumentationAutomation manifest..." -ForegroundColor Yellow

$docAutoManifestPath = "C:\UnityProjects\Sound-and-Shoal\Unity-Claude-Automation\Modules\Unity-Claude-DocumentationAutomation\Unity-Claude-DocumentationAutomation-Refactored.psd1"
$correctDocAutoManifest = "C:\UnityProjects\Sound-and-Shoal\Unity-Claude-Automation\Modules\Unity-Claude-DocumentationAutomation\Unity-Claude-DocumentationAutomation.psd1"

if ((Test-Path $docAutoManifestPath) -and (-not (Test-Path $correctDocAutoManifest))) {
    if (-not $DryRun) {
        Copy-Item $docAutoManifestPath $correctDocAutoManifest -Force
        Write-Host "  Fixed: Created correct manifest path" -ForegroundColor Green
        $fixCount++
    }
}

# Fix 10: Unity-Claude-CLIOrchestrator and DecisionEngine manifests
Write-Host "[10/10] Fixing CLIOrchestrator-related manifests..." -ForegroundColor Yellow

$cliOrchManifestPath = "C:\UnityProjects\Sound-and-Shoal\Unity-Claude-Automation\Modules\Unity-Claude-CLIOrchestrator\Unity-Claude-CLIOrchestrator-Refactored.psd1"
$correctCliOrchManifest = "C:\UnityProjects\Sound-and-Shoal\Unity-Claude-Automation\Modules\Unity-Claude-CLIOrchestrator\Unity-Claude-CLIOrchestrator.psd1"

if ((Test-Path $cliOrchManifestPath) -and (-not (Test-Path $correctCliOrchManifest))) {
    if (-not $DryRun) {
        Copy-Item $cliOrchManifestPath $correctCliOrchManifest -Force
        Write-Host "  Fixed: CLIOrchestrator manifest path" -ForegroundColor Green
        $fixCount++
    }
}

$decisionManifestPath = "C:\UnityProjects\Sound-and-Shoal\Unity-Claude-Automation\Modules\Unity-Claude-CLIOrchestrator\Core\DecisionEngine-Refactored.psd1"
$correctDecisionManifest = "C:\UnityProjects\Sound-and-Shoal\Unity-Claude-Automation\Modules\Unity-Claude-CLIOrchestrator\Core\DecisionEngine.psd1"

if ((Test-Path $decisionManifestPath) -and (-not (Test-Path $correctDecisionManifest))) {
    if (-not $DryRun) {
        Copy-Item $decisionManifestPath $correctDecisionManifest -Force
        Write-Host "  Fixed: DecisionEngine manifest path" -ForegroundColor Green
        $fixCount++
    }
}

$bayesianManifestPath = "C:\UnityProjects\Sound-and-Shoal\Unity-Claude-Automation\Modules\Unity-Claude-CLIOrchestrator\Core\DecisionEngine-Bayesian-Refactored.psd1"
$correctBayesianManifest = "C:\UnityProjects\Sound-and-Shoal\Unity-Claude-Automation\Modules\Unity-Claude-CLIOrchestrator\Core\DecisionEngine-Bayesian.psd1"

if ((Test-Path $bayesianManifestPath) -and (-not (Test-Path $correctBayesianManifest))) {
    if (-not $DryRun) {
        Copy-Item $bayesianManifestPath $correctBayesianManifest -Force
        Write-Host "  Fixed: DecisionEngine-Bayesian manifest path" -ForegroundColor Green
        $fixCount++
    }
}

$scalabilityManifestPath = "C:\UnityProjects\Sound-and-Shoal\Unity-Claude-Automation\Modules\Unity-Claude-ScalabilityEnhancements\Unity-Claude-ScalabilityEnhancements-Refactored.psd1"
$correctScalabilityManifest = "C:\UnityProjects\Sound-and-Shoal\Unity-Claude-Automation\Modules\Unity-Claude-ScalabilityEnhancements\Unity-Claude-ScalabilityEnhancements.psd1"

if ((Test-Path $scalabilityManifestPath) -and (-not (Test-Path $correctScalabilityManifest))) {
    if (-not $DryRun) {
        Copy-Item $scalabilityManifestPath $correctScalabilityManifest -Force
        Write-Host "  Fixed: ScalabilityEnhancements manifest path" -ForegroundColor Green
        $fixCount++
    }
}

# Summary
Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "           FIX SUMMARY                  " -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

if ($DryRun) {
    Write-Host "`n[DryRun Mode] No changes were made." -ForegroundColor Yellow
    Write-Host "Run without -DryRun to apply fixes." -ForegroundColor Yellow
} else {
    Write-Host "`nTotal fixes applied: $fixCount" -ForegroundColor Green
    
    if ($errors.Count -gt 0) {
        Write-Host "`nErrors encountered:" -ForegroundColor Red
        foreach ($error in $errors) {
            Write-Host "  - $error" -ForegroundColor Red
        }
    }
    
    Write-Host "`nAll identified issues have been addressed." -ForegroundColor Green
    Write-Host "Please run Test-AllRefactoredModules.ps1 again to verify." -ForegroundColor Cyan
}

return ($errors.Count -eq 0)
# SIG # Begin signature block
# MIIFzgYJKoZIhvcNAQcCoIIFvzCCBbsCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCDwERr5DdWp4fRD
# 2cbIvcK9904O1H7cnFhwpggUEFu0qqCCAzAwggMsMIICFKADAgECAhB1HRbZIqgr
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
# MAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEICBoIkHbaaBjW91cxWLYuHJ+
# 92zNesA582yQvL4u5tQPMA0GCSqGSIb3DQEBAQUABIIBAJTefF0I1Jt+hgryiBL1
# 4tTJ4W8oI3xiUNjefGwAxJDqy+533NcsevawcVG6jfNwoWBkpip9YOSBPxdcYBgY
# r20lYdU3I0BETmLS5MFX8S4RNysSNLPXluonNIBkH3V7RbMq3cQBdFCTaXXroZq1
# 3I26LaayQHOuVa4tPyFS975/LlQDY7uM3jlyMG7RFekiS0Qe7DOSgjyyLev9GowF
# waIO8MclgcyPKxDsq3tCquWf5Zzqo5CudyMzJdmJ9M9wjoxM/iFMWYveE3RSAg5t
# h1WdSXt5XkQPxzJXR+ketLXlKDy8e1o26tplhv/lfefekvWtRllUFvH8t2u3FKrZ
# Iw0=
# SIG # End signature block
