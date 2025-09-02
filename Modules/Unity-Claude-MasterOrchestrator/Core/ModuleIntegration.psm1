#Requires -Version 5.1
<#
.SYNOPSIS
    Module integration and dependency management for Unity-Claude-MasterOrchestrator.

.DESCRIPTION
    Handles module loading, dependency resolution, integration points identification,
    and module availability testing for the master orchestrator system.

.NOTES
    Part of Unity-Claude-MasterOrchestrator refactored architecture
    Originally from Unity-Claude-MasterOrchestrator.psm1 (lines 120-378)
    Refactoring Date: 2025-08-25
#>

# Import the core orchestrator for logging and configuration
Import-Module "$PSScriptRoot\OrchestratorCore.psm1" -Force

function Test-ModuleAvailability {
    <#
    .SYNOPSIS
    Tests if a PowerShell module is available and can be loaded.
    #>
    [CmdletBinding()]
    [OutputType([bool])]
    param(
        [Parameter(Mandatory = $true)]
        [string]$ModuleName
    )
    
    try {
        $module = Get-Module -Name $ModuleName -ErrorAction SilentlyContinue
        if (-not $module) {
            # Define potential module paths for legacy modules
            $basePath = "C:\UnityProjects\Sound-and-Shoal\Unity-Claude-Automation\Modules"
            $potentialPaths = @(
                # Direct module folder with manifest
                "$basePath\$ModuleName\$ModuleName.psd1"
                # Direct psm1 file in Modules root
                "$basePath\$ModuleName.psm1"
                # Execution folder
                "$basePath\Execution\$ModuleName.psd1"
                "$basePath\Execution\$ModuleName.psm1"
                # Nested in AutonomousAgent folder structure
                "$basePath\Unity-Claude-AutonomousAgent\$ModuleName.psm1"
                # Nested in sub-folders
                "$basePath\Unity-Claude-AutonomousAgent\Core\$ModuleName.psm1"
                "$basePath\Unity-Claude-AutonomousAgent\Execution\$ModuleName.psm1"
                "$basePath\Unity-Claude-AutonomousAgent\Integration\$ModuleName.psm1"
                "$basePath\Unity-Claude-AutonomousAgent\Monitoring\$ModuleName.psm1"
                "$basePath\Unity-Claude-AutonomousAgent\Parsing\$ModuleName.psm1"
            )
            
            # Try each potential path
            foreach ($path in $potentialPaths) {
                if (Test-Path $path) {
                    Write-OrchestratorLog -Message "Found module '$ModuleName' at: $path" -Level "DEBUG"
                    try {
                        Import-Module $path -Force -ErrorAction Stop
                        $module = Get-Module -Name $ModuleName -ErrorAction SilentlyContinue
                        if ($module) {
                            Write-OrchestratorLog -Message "Successfully loaded module '$ModuleName' from: $path" -Level "DEBUG"
                            break
                        }
                    } catch {
                        Write-OrchestratorLog -Message "Failed to load module '$ModuleName' from $path : $_" -Level "DEBUG"
                        continue
                    }
                }
            }
            
            # Final fallback - try importing by name
            if (-not $module) {
                try {
                    Import-Module $ModuleName -Force -ErrorAction SilentlyContinue
                    $module = Get-Module -Name $ModuleName -ErrorAction SilentlyContinue
                } catch {
                    # Silently continue
                }
            }
        }
        
        if ($module) {
            Write-OrchestratorLog -Message "Module '$ModuleName' is available with $($module.ExportedCommands.Count) functions" -Level "DEBUG"
            return $true
        } else {
            Write-OrchestratorLog -Message "Module '$ModuleName' not available" -Level "WARN"
            return $false
        }
    }
    catch {
        Write-OrchestratorLog -Message "Error checking module '$ModuleName': $_" -Level "ERROR"
        return $false
    }
}

function Initialize-ModuleIntegration {
    <#
    .SYNOPSIS
    Initializes the unified module integration system.
    #>
    [CmdletBinding()]
    param(
        [Parameter()]
        [switch]$Force
    )
    
    Write-OrchestratorLog -Message "Initializing unified module integration" -Level "INFO"
    
    $initializationResult = @{
        Success = $true
        LoadedModules = @()
        FailedModules = @()
        IntegrationMap = @{}
        Timestamp = Get-Date
    }
    
    try {
        # Get current orchestrator state
        $state = Get-OrchestratorState
        $architecture = Get-ModuleArchitecture
        
        # Clear existing integration state if forcing
        if ($Force) {
            $state.IntegratedModules.Clear()
            Write-OrchestratorLog -Message "Cleared existing module integration state" -Level "DEBUG"
        }
        
        # Load modules in dependency order based on 2025 research patterns
        $moduleLoadOrder = @()
        $moduleLoadOrder += $architecture.CoreModules
        $moduleLoadOrder += $architecture.IntegrationModules  
        $moduleLoadOrder += $architecture.AgentModules
        $moduleLoadOrder += $architecture.ExecutionModules
        $moduleLoadOrder += $architecture.CommunicationModules
        $moduleLoadOrder += $architecture.ProcessingModules
        
        Write-OrchestratorLog -Message "Loading $($moduleLoadOrder.Count) modules in sequential order" -Level "INFO"
        
        foreach ($moduleName in $moduleLoadOrder) {
            try {
                $moduleInfo = Initialize-SingleModule -ModuleName $moduleName
                
                if ($moduleInfo.Success) {
                    $initializationResult.LoadedModules += $moduleName
                    $initializationResult.IntegrationMap[$moduleName] = $moduleInfo
                    Write-OrchestratorLog -Message "Successfully integrated module: $moduleName" -Level "DEBUG"
                } else {
                    $initializationResult.FailedModules += @{
                        ModuleName = $moduleName
                        Error = $moduleInfo.Error
                    }
                    Write-OrchestratorLog -Message "Failed to integrate module '$moduleName': $($moduleInfo.Error)" -Level "WARN"
                }
            }
            catch {
                $initializationResult.FailedModules += @{
                    ModuleName = $moduleName
                    Error = $_.Exception.Message
                }
                Write-OrchestratorLog -Message "Exception integrating module '$moduleName': $_" -Level "ERROR"
            }
        }
        
        # Validate critical modules are loaded
        $criticalModules = @('Unity-Claude-ResponseMonitor', 'Unity-Claude-DecisionEngine', 'Unity-Claude-Safety')
        $criticalModulesLoaded = 0
        
        foreach ($criticalModule in $criticalModules) {
            if ($initializationResult.LoadedModules -contains $criticalModule) {
                $criticalModulesLoaded++
            }
        }
        
        if ($criticalModulesLoaded -lt 2) {
            $initializationResult.Success = $false
            Write-OrchestratorLog -Message "Insufficient critical modules loaded ($criticalModulesLoaded/3)" -Level "ERROR"
        }
        
        Write-OrchestratorLog -Message "Module integration completed: $($initializationResult.LoadedModules.Count) loaded, $($initializationResult.FailedModules.Count) failed" -Level "INFO"
        
        return $initializationResult
    }
    catch {
        Write-OrchestratorLog -Message "Critical error in module integration: $_" -Level "ERROR"
        $initializationResult.Success = $false
        $initializationResult.Error = $_.Exception.Message
        return $initializationResult
    }
}

function Initialize-SingleModule {
    <#
    .SYNOPSIS
    Initializes a single module and collects its integration information.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$ModuleName
    )
    
    Write-OrchestratorLog -Message "Initializing module: $ModuleName" -Level "DEBUG"
    
    try {
        # Check if module is available and load it
        $isAvailable = Test-ModuleAvailability -ModuleName $ModuleName
        
        if (-not $isAvailable) {
            return @{
                Success = $false
                ModuleName = $ModuleName
                Error = "Module not available or failed to load"
                Functions = @()
            }
        }
        
        # Get module information
        $module = Get-Module -Name $ModuleName
        $moduleInfo = @{
            Success = $true
            ModuleName = $ModuleName
            Version = $module.Version.ToString()
            Functions = @()
            IntegrationPoints = @()
            InitializationTime = Get-Date
        }
        
        # Collect exported functions
        if ($module.ExportedCommands) {
            $moduleInfo.Functions = $module.ExportedCommands.Keys | Sort-Object
        }
        
        # Identify integration points based on function names
        $moduleInfo.IntegrationPoints = Get-ModuleIntegrationPoints -ModuleName $ModuleName -Functions $moduleInfo.Functions
        
        Write-OrchestratorLog -Message "Module '$ModuleName' initialized with $($moduleInfo.Functions.Count) functions" -Level "DEBUG"
        
        return $moduleInfo
    }
    catch {
        Write-OrchestratorLog -Message "Error initializing module '$ModuleName': $_" -Level "ERROR"
        return @{
            Success = $false
            ModuleName = $ModuleName
            Error = $_.Exception.Message
            Functions = @()
        }
    }
}

function Get-ModuleIntegrationPoints {
    <#
    .SYNOPSIS
    Analyzes module functions to identify integration points.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$ModuleName,
        
        [Parameter(Mandatory = $true)]
        [array]$Functions
    )
    
    $integrationPoints = @()
    
    # Define integration patterns based on function names
    $integrationPatterns = @{
        "EventHandlers" = @("*-Event", "*-Handler", "On*", "Handle*")
        "StateManagement" = @("Get-*State", "Set-*State", "*-State", "*-Status")
        "Configuration" = @("Get-*Config", "Set-*Config", "*-Configuration")
        "Processing" = @("Invoke-*", "Process-*", "Execute-*")
        "Monitoring" = @("Start-*", "Stop-*", "Monitor-*", "Watch-*")
        "Analysis" = @("Analyze-*", "Parse-*", "Extract-*", "Classify-*")
        "Testing" = @("Test-*", "Validate-*", "Check-*")
    }
    
    foreach ($function in $Functions) {
        foreach ($patternType in $integrationPatterns.Keys) {
            $patterns = $integrationPatterns[$patternType]
            foreach ($pattern in $patterns) {
                if ($function -like $pattern) {
                    $integrationPoints += @{
                        Type = $patternType
                        Function = $function
                        Pattern = $pattern
                    }
                    break
                }
            }
        }
    }
    
    return $integrationPoints
}

Export-ModuleMember -Function @(
    'Test-ModuleAvailability',
    'Initialize-ModuleIntegration',
    'Initialize-SingleModule',
    'Get-ModuleIntegrationPoints'
)

# REFACTORING MARKER: This module was refactored from Unity-Claude-MasterOrchestrator.psm1 on 2025-08-25
# Original file size: 1276 lines
# This component: Module integration and dependency management (lines 120-378)
# SIG # Begin signature block
# MIIFzgYJKoZIhvcNAQcCoIIFvzCCBbsCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCA4fpLCLZ97enOU
# zFdoiFTUz8FpXocsCS5BuRxcO2KLX6CCAzAwggMsMIICFKADAgECAhB1HRbZIqgr
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
# MAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIE9jPLj9H9Ahd88iB5Vl/IRT
# 2Uda1KtMAKzYX50BAoFnMA0GCSqGSIb3DQEBAQUABIIBAI8uGUJcJwAIqtENwLg/
# SMZsJhrH48IhV2R7g+z49nnVaD9/9g4mf1qwe4wq8a45cK1THE375PNdJJl6Nl61
# nLT9tsZY7XiWNFxVN1KnRg6JaWa8ATFwPOXIgLxPypP6FA6pQGkkTzcXM+GiTnon
# 3d28aVM+3FQgSVmf7IxF2ICVqRKX3Ak+dXoeHEtYgj5jhLZjSdzkF/DD2+IPQYSH
# UXKsI/tS0wDiwVHha8SyW6e/p3SyVvrlTHFlL5bB29gDpKQp7p6cAEj/XG4yPxKP
# LOsvLGlFbYdao9tQ8SEe3GYXh6zMJE+IK6XcPPrc/OX8ydfvlylTCz8I7b4GYOco
# hkc=
# SIG # End signature block
