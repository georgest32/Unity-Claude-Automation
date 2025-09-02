#Requires -Version 5.1
<#
.SYNOPSIS
    Fixes common issues in refactored modules
    
.DESCRIPTION
    Addresses syntax errors and dependency issues found in refactored modules
#>

[CmdletBinding()]
param(
    [switch]$DryRun
)

$ErrorActionPreference = 'Continue'

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "  FIXING REFACTORED MODULE ISSUES       " -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan

# Fix 1: Unity-Claude-UnityParallelization-Refactored.psm1 - Invalid variable reference
$file1 = "C:\UnityProjects\Sound-and-Shoal\Unity-Claude-Automation\Modules\Unity-Claude-UnityParallelization\Unity-Claude-UnityParallelization-Refactored.psm1"
if (Test-Path $file1) {
    Write-Host "Fixing Unity-Claude-UnityParallelization..." -ForegroundColor Yellow
    
    $content = Get-Content $file1 -Raw
    # Fix the invalid variable reference at line 145
    $content = $content -replace 'Write-Host "`n\$category:" -ForegroundColor Yellow', 'Write-Host "`n${category}:" -ForegroundColor Yellow'
    
    if (-not $DryRun) {
        $content | Out-File $file1 -Encoding UTF8
        Write-Host "  Fixed variable reference issue" -ForegroundColor Green
    } else {
        Write-Host "  Would fix variable reference issue (DryRun)" -ForegroundColor Cyan
    }
}

# Fix 2: Unity-Claude-IntegratedWorkflow - Missing Write-IntegratedWorkflowLog function
$file2 = "C:\UnityProjects\Sound-and-Shoal\Unity-Claude-Automation\Modules\Unity-Claude-IntegratedWorkflow\Unity-Claude-IntegratedWorkflow-Refactored.psm1"
if (Test-Path $file2) {
    Write-Host "Fixing Unity-Claude-IntegratedWorkflow..." -ForegroundColor Yellow
    
    $content = Get-Content $file2 -Raw
    
    # Add the missing logging function at the beginning
    $loggingFunction = @'
# Fallback logging function if component not loaded
if (-not (Get-Command Write-IntegratedWorkflowLog -ErrorAction SilentlyContinue)) {
    function Write-IntegratedWorkflowLog {
        param(
            [string]$Message,
            [ValidateSet('Info', 'Warning', 'Error', 'Debug', 'Verbose')]
            [string]$Level = 'Info'
        )
        
        $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        $logMessage = "[$timestamp] [$Level] [IntegratedWorkflow] $Message"
        
        switch ($Level) {
            'Warning' { Write-Warning $logMessage }
            'Error' { Write-Error $logMessage }
            'Debug' { Write-Debug $logMessage }
            'Verbose' { Write-Verbose $logMessage }
            default { Write-Host $logMessage }
        }
    }
}

'@
    
    if ($content -notmatch 'Write-IntegratedWorkflowLog') {
        $content = $loggingFunction + "`n" + $content
    }
    
    if (-not $DryRun) {
        $content | Out-File $file2 -Encoding UTF8
        Write-Host "  Added missing logging function" -ForegroundColor Green
    } else {
        Write-Host "  Would add missing logging function (DryRun)" -ForegroundColor Cyan
    }
}

# Fix 3: Unity-Claude-RunspaceManagement - Invalid path concatenation
$file3 = "C:\UnityProjects\Sound-and-Shoal\Unity-Claude-Automation\Modules\Unity-Claude-RunspaceManagement\Unity-Claude-RunspaceManagement-Refactored.psm1"
if (Test-Path $file3) {
    Write-Host "Fixing Unity-Claude-RunspaceManagement..." -ForegroundColor Yellow
    
    $content = Get-Content $file3 -Raw
    
    # Fix the invalid backslash in path concatenation
    $content = $content -replace '\$componentPath = \$PSScriptRoot \+ "\\Core\\" \+ \$component', '$componentPath = Join-Path $PSScriptRoot "Core\$component"'
    
    if (-not $DryRun) {
        $content | Out-File $file3 -Encoding UTF8
        Write-Host "  Fixed path concatenation issue" -ForegroundColor Green
    } else {
        Write-Host "  Would fix path concatenation issue (DryRun)" -ForegroundColor Cyan
    }
}

# Fix 4: Unity-Claude-Learning - Missing Write-ModuleLog function in components
$learningComponents = @(
    "C:\UnityProjects\Sound-and-Shoal\Unity-Claude-Automation\Modules\Unity-Claude-Learning\Core\StringSimilarity.psm1"
    "C:\UnityProjects\Sound-and-Shoal\Unity-Claude-Automation\Modules\Unity-Claude-Learning\Core\ASTAnalysis.psm1"
    "C:\UnityProjects\Sound-and-Shoal\Unity-Claude-Automation\Modules\Unity-Claude-Learning\Core\PatternRecognition.psm1"
    "C:\UnityProjects\Sound-and-Shoal\Unity-Claude-Automation\Modules\Unity-Claude-Learning\Core\SelfPatching.psm1"
    "C:\UnityProjects\Sound-and-Shoal\Unity-Claude-Automation\Modules\Unity-Claude-Learning\Core\ConfigurationManagement.psm1"
)

Write-Host "Fixing Unity-Claude-Learning components..." -ForegroundColor Yellow
foreach ($componentFile in $learningComponents) {
    if (Test-Path $componentFile) {
        $content = Get-Content $componentFile -Raw
        
        # Add fallback logging function
        $fallbackLog = @'
# Import core module for shared functions
$corePath = Join-Path (Split-Path $PSScriptRoot -Parent) "Core\LearningCore.psm1"
if (Test-Path $corePath) {
    Import-Module $corePath -Force
}

# Fallback if Write-ModuleLog not available
if (-not (Get-Command Write-ModuleLog -ErrorAction SilentlyContinue)) {
    function Write-ModuleLog {
        param([string]$Message, [string]$Level = 'Info')
        Write-Verbose "[Learning] $Message"
    }
}

'@
        
        if ($content -notmatch 'Write-ModuleLog' -or $content -match 'The term .Write-ModuleLog.') {
            $content = $fallbackLog + "`n" + $content
            
            if (-not $DryRun) {
                $content | Out-File $componentFile -Encoding UTF8
                Write-Host "  Fixed $(Split-Path $componentFile -Leaf)" -ForegroundColor Green
            } else {
                Write-Host "  Would fix $(Split-Path $componentFile -Leaf) (DryRun)" -ForegroundColor Cyan
            }
        }
    }
}

# Fix 5: Unity-Claude-Learning - Fix circular dependencies in SuccessTracking and MetricsCollection
$successTrackingFile = "C:\UnityProjects\Sound-and-Shoal\Unity-Claude-Automation\Modules\Unity-Claude-Learning\Core\SuccessTracking.psm1"
$metricsFile = "C:\UnityProjects\Sound-and-Shoal\Unity-Claude-Automation\Modules\Unity-Claude-Learning\Core\MetricsCollection.psm1"

foreach ($file in @($successTrackingFile, $metricsFile)) {
    if (Test-Path $file) {
        $content = Get-Content $file -Raw
        
        # Fix circular dependency by importing LearningCore first
        $importFix = @'
# Import core module for configuration
$corePath = Join-Path (Split-Path $PSScriptRoot -Parent) "Core\LearningCore.psm1"
if (Test-Path $corePath) {
    Import-Module $corePath -Force
}

# Fallback configuration if not available
if (-not (Get-Command Get-LearningConfiguration -ErrorAction SilentlyContinue)) {
    function Get-LearningConfiguration {
        return @{
            DatabasePath = Join-Path $env:APPDATA "Unity-Claude\learning.db"
            MaxPatterns = 1000
            EnableLogging = $true
            LogPath = Join-Path $env:APPDATA "Unity-Claude\Logs"
        }
    }
}

'@
        
        if ($content -notmatch 'Get-LearningConfiguration' -or $content -match 'The term .Get-LearningConfiguration.') {
            $content = $importFix + "`n" + $content
            
            if (-not $DryRun) {
                $content | Out-File $file -Encoding UTF8
                Write-Host "  Fixed $(Split-Path $file -Leaf)" -ForegroundColor Green
            } else {
                Write-Host "  Would fix $(Split-Path $file -Leaf) (DryRun)" -ForegroundColor Cyan
            }
        }
    }
}

# Fix 6: Update manifests to ensure correct module version loading
Write-Host "`nUpdating module manifests..." -ForegroundColor Yellow

$manifests = @(
    @{
        Path = "C:\UnityProjects\Sound-and-Shoal\Unity-Claude-Automation\Modules\Unity-Claude-UnityParallelization\Unity-Claude-UnityParallelization.psd1"
        RootModule = "Unity-Claude-UnityParallelization-Refactored.psm1"
    }
    @{
        Path = "C:\UnityProjects\Sound-and-Shoal\Unity-Claude-Automation\Modules\Unity-Claude-IntegratedWorkflow\Unity-Claude-IntegratedWorkflow.psd1"
        RootModule = "Unity-Claude-IntegratedWorkflow-Refactored.psm1"
    }
    @{
        Path = "C:\UnityProjects\Sound-and-Shoal\Unity-Claude-Automation\Modules\Unity-Claude-Learning\Unity-Claude-Learning.psd1"
        RootModule = "Unity-Claude-Learning-Refactored.psm1"
    }
    @{
        Path = "C:\UnityProjects\Sound-and-Shoal\Unity-Claude-Automation\Modules\Unity-Claude-RunspaceManagement\Unity-Claude-RunspaceManagement.psd1"
        RootModule = "Unity-Claude-RunspaceManagement-Refactored.psm1"
    }
)

foreach ($manifest in $manifests) {
    if (Test-Path $manifest.Path) {
        $content = Get-Content $manifest.Path -Raw
        
        # Update RootModule to use refactored version
        if ($content -match "RootModule\s*=\s*'[^']+'" -and $content -notmatch $manifest.RootModule) {
            $content = $content -replace "RootModule\s*=\s*'[^']+'", "RootModule = '$($manifest.RootModule)'"
            
            if (-not $DryRun) {
                $content | Out-File $manifest.Path -Encoding UTF8
                Write-Host "  Updated $(Split-Path $manifest.Path -Leaf) to use refactored module" -ForegroundColor Green
            } else {
                Write-Host "  Would update $(Split-Path $manifest.Path -Leaf) (DryRun)" -ForegroundColor Cyan
            }
        }
    }
}

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "           FIX COMPLETE                 " -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

if ($DryRun) {
    Write-Host "`n[DryRun Mode] No changes were made." -ForegroundColor Yellow
    Write-Host "Run without -DryRun to apply fixes." -ForegroundColor Yellow
} else {
    Write-Host "`nAll identified issues have been fixed." -ForegroundColor Green
    Write-Host "Please run Test-AllRefactoredModules.ps1 again to verify." -ForegroundColor Cyan
}

return $true
# SIG # Begin signature block
# MIIFzgYJKoZIhvcNAQcCoIIFvzCCBbsCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCDxOdokqIf8eE92
# XdtJaov+5RryYe9GyTN2WOHvZBWQhKCCAzAwggMsMIICFKADAgECAhB1HRbZIqgr
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
# MAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIBvasjpcCI/+9fPS9s4MHY8+
# Wpt6PVcIBSn4mfjwE5j1MA0GCSqGSIb3DQEBAQUABIIBAHkBkpzrnwh1uKOLimsh
# vzMD4JHju6E7ZTTnJbUtPfq5SJVirMxHv9tSfnYZJOQA96P0Cy4oCdkn4So7ACNw
# TRInjLA2miPnp1sbbqnEaTymGDPBVDcV7r4IgBhtOQogI89Eeq2tMHI10CtgnDLR
# qBdNSjsFzRoKHK3jlFeZawCq4ymzEIie/xtvmEquISa4xkQqiHwyWGFY6MTCvTql
# BixUILNVr9Wijgj6rCQoY0gQRaEM3Jr5HN7m8Cn3U7IzHXoamlsol2UWwQ+MWCGE
# VeaL0MvoG4fIVPGIu7e9RrilHRMSqf/J9g58CZDzqEJemW3GJNFvesoLmutGBh7+
# qis=
# SIG # End signature block
