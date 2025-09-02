# Unity-Claude-Learning Refactored Orchestrator Module
# Main orchestrator that loads and coordinates all refactored components
# Version: 2.0.0 (Refactored)
# Date: 2025-08-25

$ErrorActionPreference = "Stop"

# Log that we're using the refactored version
Write-Host "[Unity-Claude-Learning] Loading REFACTORED VERSION 2.0.0 with modular components..." -ForegroundColor Green

# Module base path
$ModuleBasePath = $PSScriptRoot
$ComponentPath = Join-Path $ModuleBasePath "Core"

# Load component modules in dependency order
$componentsToLoad = @(
    'LearningCore.psm1',
    'DatabaseManagement.psm1',
    'StringSimilarity.psm1',
    'ASTAnalysis.psm1',
    'PatternRecognition.psm1',
    'SelfPatching.psm1',
    'SuccessTracking.psm1',
    'MetricsCollection.psm1',
    'ConfigurationManagement.psm1'
)

$loadedComponents = @()
$failedComponents = @()

foreach ($component in $componentsToLoad) {
    $componentFullPath = Join-Path $ComponentPath $component
    try {
        if (Test-Path $componentFullPath) {
            Import-Module $componentFullPath -Force -Global
            $loadedComponents += $component
            Write-Host "  [✓] Loaded component: $component" -ForegroundColor Green
        } else {
            # Component not yet created - log but continue
            Write-Host "  [○] Component pending: $component" -ForegroundColor Yellow
        }
    } catch {
        $failedComponents += @{
            Component = $component
            Error = $_.Exception.Message
        }
        Write-Warning "  [✗] Failed to load component: $component - $($_.Exception.Message)"
    }
}

# Display loading summary
Write-Host "`n[Unity-Claude-Learning] Component Loading Summary:" -ForegroundColor Cyan
Write-Host "  Loaded: $($loadedComponents.Count)/$($componentsToLoad.Count) components" -ForegroundColor $(if ($loadedComponents.Count -eq $componentsToLoad.Count) { "Green" } else { "Yellow" })

if ($failedComponents.Count -gt 0) {
    Write-Warning "  Failed components:"
    foreach ($failed in $failedComponents) {
        Write-Warning "    - $($failed.Component): $($failed.Error)"
    }
}

# Log module loading status
if (Get-Command Write-LearningLog -ErrorAction SilentlyContinue) {
    Write-LearningLog -Message "Unity-Claude-Learning REFACTORED module loading..." -Level "DEBUG"
} else {
    Write-Host "[Unity-Claude-Learning] Loading module (logging function not yet available)..." -ForegroundColor Gray
}

# Define functions to export - these will be available from loaded components
$functionsToExport = @(
    # Core configuration
    'Get-LearningConfig',
    'Set-LearningConfig',
    
    # Database management
    'Initialize-LearningDatabase',
    
    # String similarity
    'Get-StringSimilarity',
    'Get-LevenshteinDistance',
    'Get-ErrorSignature',
    
    # Pattern recognition
    'Find-SimilarPatterns',
    'Add-ErrorPattern',
    'Calculate-ConfidenceScore',
    
    # AST Analysis
    'Get-CodeAST',
    'Find-CodePattern',
    
    # Self-patching
    'Get-SuggestedFixes',
    'Apply-AutoFix',
    
    # Success tracking
    'Update-PatternSuccess',
    'Get-LearningReport',
    
    # Metrics collection
    'Record-PatternApplicationMetric',
    'Get-LearningMetrics',
    'Get-PatternUsageAnalytics'
)

# Validate and export available functions
$definedFunctions = @()
foreach ($functionName in $functionsToExport) {
    if (Test-Path "Function:\$functionName") {
        $definedFunctions += $functionName
        if (Get-Command Write-LearningLog -ErrorAction SilentlyContinue) {
            Write-LearningLog -Message "Function validated: $functionName" -Level "DEBUG"
        }
    } else {
        if (Get-Command Write-LearningLog -ErrorAction SilentlyContinue) {
            Write-LearningLog -Message "Function NOT FOUND: $functionName" -Level "WARNING"
        }
    }
}

# Export validated functions
Export-ModuleMember -Function $definedFunctions

# Module loading complete notification
if (Get-Command Write-LearningLog -ErrorAction SilentlyContinue) {
    Write-LearningLog -Message "Unity-Claude-Learning REFACTORED module loaded with $($definedFunctions.Count)/$($functionsToExport.Count) functions" -Level "INFO"
}

# Display final module status
Write-Host "`n================================================================" -ForegroundColor Cyan
Write-Host "Unity-Claude-Learning Module (REFACTORED)" -ForegroundColor Green
Write-Host "================================================================" -ForegroundColor Cyan
Write-Host "Version: 2.0.0 (Modular Architecture)" -ForegroundColor White
Write-Host "Components Loaded: $($loadedComponents.Count)/$($componentsToLoad.Count)" -ForegroundColor White
Write-Host "Functions Exported: $($definedFunctions.Count)" -ForegroundColor White
Write-Host "Status: $(if ($loadedComponents.Count -eq $componentsToLoad.Count -and $definedFunctions.Count -eq $functionsToExport.Count) { 'FULLY OPERATIONAL' } else { 'PARTIALLY LOADED' })" -ForegroundColor $(if ($loadedComponents.Count -eq $componentsToLoad.Count) { "Green" } else { "Yellow" })
Write-Host "================================================================`n" -ForegroundColor Cyan
# SIG # Begin signature block
# MIIFzgYJKoZIhvcNAQcCoIIFvzCCBbsCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCCJzNl31QaMhH9X
# UJJ0w/2xd0c80MFf2F9uBKbMU8j1TaCCAzAwggMsMIICFKADAgECAhB1HRbZIqgr
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
# MAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIBzKvzvncixlzWlDiWliwVTt
# hel6YDvdmAuGDvJ1tiG9MA0GCSqGSIb3DQEBAQUABIIBACECB/wFQnE//I49XaIO
# 0aBd6c50uKNPUm1VIQXt1pP45D7uM9OkC8mRe7NxmLfsTtMxwCopeLQrCmgdF0En
# IPVIHrL17HOEZJhPjWf+dco6Mz9WRcV0F7uwFNyXlBlCFbudCCVxaoCjN7Kj8rzH
# 6M04h3Xx5kDD/GimVZFHfqA7PyVxlAicQG18+7xR/YD8AIkIxG4JM5vJQ7mLHKgF
# oewos5aPshFPhKoXM6dJ444xWVkj2C1LD5X0QCgNu17MztqmGrOQrmX3YFkN21Wf
# GV5ChS2Wa/GC59Uy+3XNCd7cGr0r2114OfHIkUq2FNqQCvvOsmfI2NPP0n2o9FxC
# 6Sk=
# SIG # End signature block
