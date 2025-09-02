#Requires -Version 5.1
<#
.SYNOPSIS
    Unity-Claude-MasterOrchestrator - Refactored modular orchestrator system.

.DESCRIPTION
    Main orchestrator module that coordinates all Unity-Claude automation systems
    through a modular, component-based architecture. This refactored version
    replaces the monolithic 1276-line Unity-Claude-MasterOrchestrator.psm1 with
    6 focused, maintainable components organized in the Core/ subdirectory.

.NOTES
    Refactored Architecture (2025-08-25):
    - OrchestratorCore.psm1 (198 lines) - Configuration, logging, state management
    - ModuleIntegration.psm1 (258 lines) - Module loading and dependency management  
    - EventProcessing.psm1 (270 lines) - Event-driven architecture implementation
    - DecisionExecution.psm1 (206 lines) - Decision routing and safety validation
    - AutonomousFeedbackLoop.psm1 (205 lines) - Feedback loop lifecycle management
    - OrchestratorManagement.psm1 (286 lines) - Status reporting and management
    
    Total: ~1423 lines across 6 components (~237 lines average)
    Original: 1276 lines in single file
    Complexity Reduction: ~84% per component
#>

# === REFACTORING DEBUG LOG ===
Write-Host "✅ LOADING REFACTORED VERSION: Unity-Claude-MasterOrchestrator-Refactored.psm1 with 6 modular components" -ForegroundColor Green
Write-Host "📦 Components: OrchestratorCore, ModuleIntegration, EventProcessing, DecisionExecution, AutonomousFeedbackLoop, OrchestratorManagement" -ForegroundColor Cyan

#region Module Configuration and Dependencies

# Component loading path
$script:ComponentPath = Join-Path $PSScriptRoot "Core"

# Required component modules in dependency order
$script:RequiredComponents = @(
    'OrchestratorCore',        # Must load first - provides base configuration and logging
    'ModuleIntegration',       # Module loading and dependency management
    'EventProcessing',         # Event-driven architecture implementation
    'DecisionExecution',       # Decision routing and safety validation
    'AutonomousFeedbackLoop',  # Feedback loop lifecycle management
    'OrchestratorManagement'   # Status reporting and management functions
)

# Load all component modules
foreach ($component in $script:RequiredComponents) {
    $componentFile = Join-Path $script:ComponentPath "$component.psm1"
    if (Test-Path $componentFile) {
        Import-Module $componentFile -Force -Global
        Write-Host "Loaded component: $component" -ForegroundColor Green
    } else {
        Write-Warning "Component not found: $componentFile"
    }
}

#endregion

#region Core Orchestrator Functions

function Initialize-MasterOrchestrator {
    <#
    .SYNOPSIS
    Initializes the complete master orchestrator system.
    #>
    [CmdletBinding()]
    param(
        [Parameter()]
        [hashtable]$Configuration = @{},
        
        [Parameter()]
        [switch]$Force
    )
    
    Write-Host "Initializing Master Orchestrator (Refactored Version)" -ForegroundColor Cyan
    
    try {
        # Initialize core configuration first
        $coreInit = Initialize-OrchestratorCore -Configuration $Configuration -Force:$Force
        if (-not $coreInit.Success) {
            throw "Core initialization failed: $($coreInit.Error)"
        }
        
        # Initialize module integration
        $moduleInit = Initialize-ModuleIntegration -Force:$Force
        if (-not $moduleInit.Success) {
            throw "Module integration failed: $($moduleInit.Error)"
        }
        
        # Start event processing system
        $eventInit = Start-EventDrivenProcessing
        if (-not $eventInit.Success) {
            throw "Event processing initialization failed: $($eventInit.Error)"
        }
        
        Write-OrchestratorLog -Message "Master Orchestrator initialized successfully" -Level "INFO"
        
        return @{
            Success = $true
            ComponentsLoaded = $script:RequiredComponents.Count
            ModulesIntegrated = $moduleInit.LoadedModules.Count
            EventProcessingActive = $eventInit.Success
            InitializationTime = Get-Date
        }
    }
    catch {
        Write-OrchestratorLog -Message "Master Orchestrator initialization failed: $_" -Level "ERROR"
        return @{
            Success = $false
            Error = $_.Exception.Message
        }
    }
}

function Get-MasterOrchestratorStatus {
    <#
    .SYNOPSIS
    Gets comprehensive status of the entire master orchestrator system.
    #>
    [CmdletBinding()]
    param()
    
    try {
        # Get status from all components
        $orchestratorStatus = Get-OrchestratorStatus
        $feedbackStatus = Get-FeedbackLoopStatus
        
        return @{
            OverallStatus = if ($orchestratorStatus.Configuration -and $feedbackStatus) { "HEALTHY" } else { "DEGRADED" }
            Components = @{
                Core = $orchestratorStatus
                FeedbackLoop = $feedbackStatus
            }
            Architecture = @{
                ComponentsLoaded = $script:RequiredComponents.Count
                RefactoredVersion = $true
                OriginalFileSize = "1276 lines"
                RefactoredTotalSize = "~1423 lines across 6 components"
                ComplexityReduction = "~84% per component"
            }
            StatusTime = Get-Date
        }
    }
    catch {
        Write-OrchestratorLog -Message "Error getting master orchestrator status: $_" -Level "ERROR"
        return @{
            OverallStatus = "ERROR"
            Error = $_.Exception.Message
            StatusTime = Get-Date
        }
    }
}

function Test-MasterOrchestratorIntegration {
    <#
    .SYNOPSIS
    Performs comprehensive integration testing across all orchestrator components.
    #>
    [CmdletBinding()]
    param()
    
    Write-OrchestratorLog -Message "Testing Master Orchestrator integration" -Level "INFO"
    
    $testResults = @{
        ComponentTests = @()
        OverallStatus = "UNKNOWN"
        TestTime = Get-Date
    }
    
    try {
        # Test each component
        $integrationTest = Test-OrchestratorIntegration
        $testResults.ComponentTests += @{
            Component = "OrchestratorCore"
            Result = $integrationTest
        }
        
        $feedbackTest = Test-AutonomousFeedbackLoop  
        $testResults.ComponentTests += @{
            Component = "AutonomousFeedbackLoop"
            Result = $feedbackTest
        }
        
        # Calculate overall status
        $passedTests = ($testResults.ComponentTests | Where-Object { $_.Result.OverallStatus -eq "PASS" }).Count
        $totalTests = $testResults.ComponentTests.Count
        
        if ($passedTests -eq $totalTests) {
            $testResults.OverallStatus = "PASS"
        } elseif ($passedTests -gt 0) {
            $testResults.OverallStatus = "PARTIAL"
        } else {
            $testResults.OverallStatus = "FAIL"
        }
        
        Write-OrchestratorLog -Message "Master Orchestrator integration test: $($testResults.OverallStatus) ($passedTests/$totalTests components passed)" -Level "INFO"
        
        return $testResults
    }
    catch {
        Write-OrchestratorLog -Message "Error during master orchestrator integration test: $_" -Level "ERROR"
        $testResults.OverallStatus = "ERROR"
        $testResults.Error = $_.Exception.Message
        return $testResults
    }
}

#endregion

#region Module Exports

# Export all functions from component modules
Export-ModuleMember -Function @(
    # Main orchestrator functions
    'Initialize-MasterOrchestrator',
    'Get-MasterOrchestratorStatus', 
    'Test-MasterOrchestratorIntegration',
    
    # Core functions (from OrchestratorCore.psm1)
    'Initialize-OrchestratorCore',
    'Get-OrchestratorConfig',
    'Set-OrchestratorConfig',
    'Get-OrchestratorState',
    'Write-OrchestratorLog',
    
    # Module integration functions (from ModuleIntegration.psm1)
    'Initialize-ModuleIntegration',
    'Get-ModuleArchitecture',
    'Test-ModuleDependencies',
    'Get-LoadedModuleDetails',
    
    # Event processing functions (from EventProcessing.psm1)
    'Start-EventDrivenProcessing',
    'Stop-EventDrivenProcessing',
    'Add-OrchestratorEvent',
    'Get-EventProcessingStatus',
    'Test-EventProcessing',
    
    # Decision execution functions (from DecisionExecution.psm1)
    'Invoke-DecisionExecution',
    'Get-DecisionExecutionStatus',
    'Test-DecisionExecution',
    'Get-SupportedDecisionTypes',
    
    # Autonomous feedback loop functions (from AutonomousFeedbackLoop.psm1)
    'Start-AutonomousFeedbackLoop',
    'Stop-AutonomousFeedbackLoop',
    'Get-FeedbackLoopStatus',
    'Test-AutonomousFeedbackLoop',
    'Resume-AutonomousFeedbackLoop',
    
    # Management functions (from OrchestratorManagement.psm1)
    'Get-OrchestratorStatus',
    'Test-OrchestratorIntegration',
    'Get-OperationHistory',
    'Clear-OrchestratorState',
    'Get-OrchestratorHealth',
    'Reset-OrchestratorToDefaults'
)

#endregion

# REFACTORING MARKER: This file replaces Unity-Claude-MasterOrchestrator.psm1 (1276 lines) on 2025-08-25
# New Architecture: 6 modular components in Core/ subdirectory totaling ~1423 lines
# Complexity Reduction: ~84% per component (average 237 lines vs 1276 lines)
# SIG # Begin signature block
# MIIFzgYJKoZIhvcNAQcCoIIFvzCCBbsCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCBmraVEC4j3w9ef
# fcgrphR2/7oUkPh6MammAtPxONdDnqCCAzAwggMsMIICFKADAgECAhB1HRbZIqgr
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
# MAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIN1oG6q9kPsPA2wUmMpQwJxP
# FAAJz0jJGwwZ63iHJG2PMA0GCSqGSIb3DQEBAQUABIIBAAJQ4KIEhurk7XXJRrb4
# +rC5bVQDbrVccaYp9ab3XUDR5WgQWeQlwD7lEVcA7MakOv/3fBxOZSnwobziSSmT
# KoZY1cbs9cQqudckhiOqb5PSF62Q7EA/cNjegMQx0zbZI03AolcMSAaQkogTmkGF
# OkSF0zqlN+wnv6MkKFYFKALXI7W/yU9IUhWgE0pNIbS72q9OptiDKmu/7UCm5O4L
# w6u3sR25wXnItv1xp2kHd3c1qTCjhy6WQP5sKH4+dI3wOobm7GCqhrBOL1zRaZgn
# JdAacpwLs+ym+UDqe1uB2dTblNd2PA4mlIUmfBkJP7wBOSRN2zt3EtsIi+2/YPa7
# wSc=
# SIG # End signature block
