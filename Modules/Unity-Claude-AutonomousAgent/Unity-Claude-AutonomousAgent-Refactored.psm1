# Unity-Claude-AutonomousAgent-Refactored.psm1
# Main loader module for Unity-Claude Autonomous Agent
# Refactored modular architecture - loads all sub-modules
# Date: 2025-08-18

#region Module Information

$script:ModuleVersion = "2.0.0"
$script:ModuleName = "Unity-Claude-AutonomousAgent"
$script:ModuleDescription = "Autonomous agent for Unity-Claude integration with modular architecture"

#endregion

#region Module Loading

Write-Host "Loading $script:ModuleName v$script:ModuleVersion..." -ForegroundColor Cyan

# Define sub-modules to load in order
$subModules = @(
    # Core modules (load first)
    @{ Path = "Core\AgentCore.psm1"; Required = $true },
    @{ Path = "Core\AgentLogging.psm1"; Required = $true },
    
    # Monitoring modules
    @{ Path = "Monitoring\FileSystemMonitoring.psm1"; Required = $true },
    
    # Intelligence modules (already separate)
    @{ Path = "IntelligentPromptEngine.psm1"; Required = $false },
    @{ Path = "ConversationStateManager.psm1"; Required = $true },
    @{ Path = "ContextOptimization.psm1"; Required = $true }
    
    # Additional modules will be added as we refactor them:
    # "Monitoring\ResponseMonitoring.psm1"
    # "Parsing\ResponseParsing.psm1"
    # "Parsing\Classification.psm1"
    # "Parsing\ContextExtraction.psm1"
    # "Execution\SafeExecution.psm1"
    # "Execution\CommandQueue.psm1"
    # "Execution\CommandValidation.psm1"
    # "Commands\TestCommands.psm1"
    # "Commands\BuildCommands.psm1"
    # "Commands\AnalyzeCommands.psm1"
    # "Integration\ClaudeIntegration.psm1"
    # "Integration\UnityIntegration.psm1"
)

$loadedModules = @()
$failedModules = @()

foreach ($module in $subModules) {
    $modulePath = Join-Path $PSScriptRoot $module.Path
    
    Write-Host "DEBUG: Checking module: $($module.Path)" -ForegroundColor Cyan
    Write-Host "DEBUG: Full path: $modulePath" -ForegroundColor Gray
    
    if (Test-Path $modulePath) {
        Write-Host "DEBUG: File exists, attempting import..." -ForegroundColor Green
        try {
            # Use Import-Module for better isolation
            Import-Module $modulePath -Force -DisableNameChecking
            
            # Check what functions were imported
            $moduleBaseName = [System.IO.Path]::GetFileNameWithoutExtension($modulePath)
            $importedModule = Get-Module $moduleBaseName -ErrorAction SilentlyContinue
            if ($importedModule) {
                $functionCount = $importedModule.ExportedCommands.Count
                Write-Host "DEBUG: Imported $functionCount functions from $($module.Path)" -ForegroundColor Green
            }
            
            $loadedModules += $module.Path
            Write-Host "  + Loaded: $($module.Path)" -ForegroundColor Green
        }
        catch {
            Write-Host "ERROR: Import failed: $_" -ForegroundColor Red
            if ($module.Required) {
                Write-Host "  - Failed to load required module: $($module.Path)" -ForegroundColor Red
                Write-Host "    Error: $_" -ForegroundColor Red
                $failedModules += $module.Path
            } else {
                Write-Host "  ! Failed to load optional module: $($module.Path)" -ForegroundColor Yellow
            }
        }
    }
    else {
        Write-Host "ERROR: File not found: $modulePath" -ForegroundColor Red
        if ($module.Required) {
            Write-Host "  - Required module not found: $($module.Path)" -ForegroundColor Red
            $failedModules += $module.Path
        } else {
            Write-Host "  ! Optional module not found: $($module.Path)" -ForegroundColor Yellow
        }
    }
}

#endregion

#region Module Initialization

if ($failedModules.Count -eq 0) {
    try {
        # Initialize core systems
        Initialize-AgentCore
        Initialize-AgentLogging
        
        # Initialize conversation management
        Initialize-ConversationState | Out-Null
        Initialize-WorkingMemory | Out-Null
        
        Write-Host ""
        Write-Host "$script:ModuleName loaded successfully!" -ForegroundColor Green
        Write-Host "Loaded $($loadedModules.Count) sub-modules" -ForegroundColor Gray
        
        Write-AgentLog -Message "$script:ModuleName v$script:ModuleVersion initialized" -Level "INFO"
    }
    catch {
        Write-Host "Module initialization failed: $_" -ForegroundColor Red
        throw
    }
} else {
    $errorMsg = "Failed to load required modules: $($failedModules -join ', ')"
    Write-Host $errorMsg -ForegroundColor Red
    throw $errorMsg
}

#endregion

#region Temporary Compatibility Layer

# For backward compatibility, we'll create wrapper functions for the most commonly used functions
# These will be removed once all references are updated to use the new module structure

# Note: Start-ClaudeResponseMonitoring and Stop-ClaudeResponseMonitoring 
# are now directly exported from FileSystemMonitoring module
# No wrappers needed as functions are already available globally

# Note: Write-AgentLog is now directly exported from AgentLogging module
# No wrapper needed as the function is already available globally

#endregion

#region Module Status

function Get-ModuleStatus {
    <#
    .SYNOPSIS
    Gets the status of all loaded sub-modules
    
    .DESCRIPTION
    Returns information about loaded modules and their functions
    #>
    [CmdletBinding()]
    param()
    
    $status = @{
        Version = $script:ModuleVersion
        LoadedModules = $loadedModules
        FailedModules = $failedModules
        TotalFunctions = 0
        Functions = @{}
    }
    
    # Get exported functions from each module
    foreach ($moduleName in $loadedModules) {
        $moduleCommands = Get-Command -Module $moduleName -ErrorAction SilentlyContinue
        if ($moduleCommands) {
            $status.Functions[$moduleName] = $moduleCommands.Name
            $status.TotalFunctions += $moduleCommands.Count
        }
    }
    
    return $status
}

#endregion

# Note: We're not exporting functions here because each sub-module exports its own functions
# The manifest file (psd1) should be updated to include all sub-modules in NestedModules

Write-Host ""
Write-Host "Module refactoring status:" -ForegroundColor Cyan
Write-Host "  * Core modules: Extracted and loaded" -ForegroundColor Green
Write-Host "  * Monitoring: FileSystemMonitoring extracted" -ForegroundColor Green
Write-Host "  * Intelligence: Already modularized (Day 8-10)" -ForegroundColor Green
Write-Host "  * Remaining: Parsing, Execution, Commands, Integration" -ForegroundColor Yellow
Write-Host ""
Write-Host "Use Get-ModuleStatus for detailed information" -ForegroundColor Gray
# SIG # Begin signature block
# MIIFqQYJKoZIhvcNAQcCoIIFmjCCBZYCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUF6FUIZ7pqzmdW/uD/TEQ64wG
# ArSgggMwMIIDLDCCAhSgAwIBAgIQdR0W2SKoK5VE8JId4ZxrRTANBgkqhkiG9w0B
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
# CQQxFgQUvdEkPZerqPF7NMqgKvODv8yup84wDQYJKoZIhvcNAQEBBQAEggEAaroN
# nPYIKj3IWt6dIDeU1GgC18BePAFm+h0HeEYFwUXbztu2tSCQlVH9qS/GOS8tI15K
# FS0kHk7kJAkTTOaYl/qRnZRPugvJq9oIp7kTAnzrXJSs+O1+GM2TnA1AYQ9c888g
# NsaIlJPdTi1MIEJg/4bCUrNc3GW6EIlCuXCGiURd5JOCWYcz8L05soT2/5Kx6wd+
# 3iWOOpuOmUB7VSkzSYxRdq/saPTVVE3iqiRjNb7fhoD5LVV+ycNhIggAWoOe2dlw
# yx684QfcVNdKp2+7p4CBrw3nM+hg8/EwU+PUbsxNWXbx0iQJ1WZs1hlD1k8kxHAn
# GxuGqlXAQw31qBJ+2g==
# SIG # End signature block
