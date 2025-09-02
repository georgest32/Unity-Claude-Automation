# Unity-Claude-IntegratedWorkflow Refactored Orchestrator Module
# Main orchestrator that loads and coordinates all refactored components
# Version: 2.0.0 (Refactored)
# Date: 2025-08-25

$ErrorActionPreference = "Stop"

# Log that we're using the refactored version
Write-Host "[Unity-Claude-IntegratedWorkflow] Loading REFACTORED VERSION 2.0.0 with modular components..." -ForegroundColor Green

# Module base path
$ModuleBasePath = $PSScriptRoot
$ComponentPath = Join-Path $ModuleBasePath "Core"

# Load component modules in dependency order
$componentsToLoad = @(
    'WorkflowCore.psm1',
    'DependencyManagement.psm1',
    'WorkflowOrchestration.psm1',
    'WorkflowMonitoring.psm1',
    'PerformanceOptimization.psm1',
    'PerformanceAnalysis.psm1'
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
            throw "Component file not found: $componentFullPath"
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
Write-Host "`n[Unity-Claude-IntegratedWorkflow] Component Loading Summary:" -ForegroundColor Cyan
Write-Host "  Loaded: $($loadedComponents.Count)/$($componentsToLoad.Count) components" -ForegroundColor $(if ($loadedComponents.Count -eq $componentsToLoad.Count) { "Green" } else { "Yellow" })

if ($failedComponents.Count -gt 0) {
    Write-Warning "  Failed components:"
    foreach ($failed in $failedComponents) {
        Write-Warning "    - $($failed.Component): $($failed.Error)"
    }
}

# Initialize required modules path  
$ModulesPath = Split-Path (Split-Path $ModuleBasePath -Parent) -Parent | Join-Path -ChildPath "Modules"

# Check if dependency management functions are available
if (Get-Command Initialize-RequiredModules -ErrorAction SilentlyContinue) {
    try {
        $moduleAvailability = Initialize-RequiredModules -ModulesPath $ModulesPath
        $allDependenciesLoaded = Test-ModuleDependencies
        
        if (-not $allDependenciesLoaded) {
            Write-Warning "[Unity-Claude-IntegratedWorkflow] Module loaded with missing dependencies. Some functions may not work properly."
        } else {
            Write-Host "[Unity-Claude-IntegratedWorkflow] All dependencies loaded successfully" -ForegroundColor Green
        }
    } catch {
        Write-Warning "[Unity-Claude-IntegratedWorkflow] Failed to initialize dependencies: $($_.Exception.Message)"
    }
} else {
    Write-Warning "[Unity-Claude-IntegratedWorkflow] Dependency management functions not available - some features may be limited"
}

# Module loading notification
if (Get-Command Write-IntegratedWorkflowLog -ErrorAction SilentlyContinue) {
    Write-IntegratedWorkflowLog -Message "Loading Unity-Claude-IntegratedWorkflow module (REFACTORED VERSION)..." -Level "DEBUG"
} else {
    Write-Host "[Unity-Claude-IntegratedWorkflow] Loading module (logging function not yet available)..." -ForegroundColor Gray
}

# Validate function definitions before export
# Validate logging function is available before using it
if (Get-Command Write-IntegratedWorkflowLog -ErrorAction SilentlyContinue) {
    Write-IntegratedWorkflowLog -Message "Validating function definitions before export..." -Level "DEBUG"
} else {
    Write-Verbose "[Unity-Claude-IntegratedWorkflow] Validating function definitions before export..."
}

$definedFunctions = @()
$functionsToExport = @(
    # From DependencyManagement
    'Test-ModuleDependencyAvailability',
    # From WorkflowOrchestration
    'New-IntegratedWorkflow',
    'Start-IntegratedWorkflow',
    # From WorkflowMonitoring
    'Get-IntegratedWorkflowStatus',
    'Stop-IntegratedWorkflow',
    # From PerformanceOptimization
    'Initialize-AdaptiveThrottling',
    'Update-AdaptiveThrottling',
    'New-IntelligentJobBatching',
    # From PerformanceAnalysis
    'Get-WorkflowPerformanceAnalysis'
)

# Validate each function exists before export
foreach ($functionName in $functionsToExport) {
    if (Test-Path "Function:\$functionName") {
        $definedFunctions += $functionName
        if (Get-Command Write-IntegratedWorkflowLog -ErrorAction SilentlyContinue) {
            Write-IntegratedWorkflowLog -Message "Function validated: $functionName" -Level "DEBUG"
        }
    } else {
        if (Get-Command Write-IntegratedWorkflowLog -ErrorAction SilentlyContinue) {
            Write-IntegratedWorkflowLog -Message "Function NOT FOUND: $functionName" -Level "ERROR"
        } else {
            Write-Warning "[Unity-Claude-IntegratedWorkflow] Function NOT FOUND: $functionName"
        }
    }
}

if (Get-Command Write-IntegratedWorkflowLog -ErrorAction SilentlyContinue) {
    Write-IntegratedWorkflowLog -Message "Function validation complete: $($definedFunctions.Count)/$($functionsToExport.Count) functions defined" -Level "INFO"
} else {
    Write-Verbose "[Unity-Claude-IntegratedWorkflow] Function validation complete: $($definedFunctions.Count)/$($functionsToExport.Count) functions defined"
}

# Export only validated functions
Export-ModuleMember -Function $definedFunctions

# Module loading complete with detailed status
if (Get-Command Write-IntegratedWorkflowLog -ErrorAction SilentlyContinue) {
    Write-IntegratedWorkflowLog -Message "Export-ModuleMember completed for $($definedFunctions.Count) functions" -Level "DEBUG"
    Write-IntegratedWorkflowLog -Message "Unity-Claude-IntegratedWorkflow REFACTORED module loaded successfully" -Level "INFO"
} else {
    Write-Verbose "[Unity-Claude-IntegratedWorkflow] Export-ModuleMember completed for $($definedFunctions.Count) functions"
    Write-Verbose "[Unity-Claude-IntegratedWorkflow] Unity-Claude-IntegratedWorkflow REFACTORED module loaded successfully"
}

# Display final module status
Write-Host "`n================================================================" -ForegroundColor Cyan
Write-Host "Unity-Claude-IntegratedWorkflow Module (REFACTORED)" -ForegroundColor Green
Write-Host "================================================================" -ForegroundColor Cyan
Write-Host "Version: 2.0.0 (Modular Architecture)" -ForegroundColor White
Write-Host "Components Loaded: $($loadedComponents.Count)/$($componentsToLoad.Count)" -ForegroundColor White
Write-Host "Functions Exported: $($definedFunctions.Count)" -ForegroundColor White
Write-Host "Status: $(if ($loadedComponents.Count -eq $componentsToLoad.Count -and $definedFunctions.Count -eq $functionsToExport.Count) { 'FULLY OPERATIONAL' } else { 'PARTIALLY LOADED' })" -ForegroundColor $(if ($loadedComponents.Count -eq $componentsToLoad.Count) { "Green" } else { "Yellow" })
Write-Host "================================================================`n" -ForegroundColor Cyan

# SIG # Begin signature block
# MIIFzgYJKoZIhvcNAQcCoIIFvzCCBbsCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCD+/V92W9Yp5PFA
# Pm/kkLOBavuFKiBba7ahR23aBjvZkaCCAzAwggMsMIICFKADAgECAhB1HRbZIqgr
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
# MAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIJ38gkEG1Ahj9wZ/T+IOFEEx
# UOi83k3MCKCCfdVviFmfMA0GCSqGSIb3DQEBAQUABIIBAITJBDnAxsPUK9Q0tB0I
# 92TzzSlvaKP5/4Ep9yjUqV9NoCtDyr0KfBPTdH8W3d5leWMR6MGH3y5g23u6QkTl
# fUh6eD3RN2QVTdFjtlpmTXltUDSy4mcoC2/dxogttyRz5jP6vRCjfVfJOMFjBaPu
# WwBWj6qCEalha5gzL/W9oKUSdYS1OeJT2j1OotqmEsaSNttfbSDoc+XljQIvZFG0
# 12ZcnuULGoTMLWoDSlxG6LpXj20kKuaIsi7NolJdKc7Cens9E0KaM9HpTubd5f4k
# X2ySN6cr8YgDjHYRL62EiWaLB37HVHZD6uot9Kfk3lOYfvH+M6rX4sT4GfmCrDAg
# aBo=
# SIG # End signature block
