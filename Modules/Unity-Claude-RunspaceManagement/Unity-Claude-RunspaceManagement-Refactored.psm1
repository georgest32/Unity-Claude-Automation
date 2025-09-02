# Unity-Claude-RunspaceManagement Refactored Orchestrator Module
# Loads and coordinates all refactored components
# Version 2.0.0 - Modular Architecture

$ErrorActionPreference = "Stop"

# Module base path
$ModuleBase = $PSScriptRoot
$CorePath = Join-Path $ModuleBase "Core"

Write-Host "[Unity-Claude-RunspaceManagement] Loading REFACTORED VERSION (modular)" -ForegroundColor Green

# Load core components in dependency order
$components = @(
    'RunspaceCore.psm1',
    'SessionStateConfiguration.psm1',
    'ModuleVariablePreloading.psm1',
    'VariableSharing.psm1',
    'RunspacePoolManagement.psm1',
    'ProductionRunspacePool.psm1',
    'ThrottlingResourceControl.psm1'
)

$loadedComponents = @()
$failedComponents = @()

foreach ($component in $components) {
    $componentPath = Join-Path $CorePath $component
    try {
        if (Test-Path $componentPath) {
            Import-Module $componentPath -Force -Global
            $loadedComponents += $component
            Write-Host "  [OK] Loaded component: $component" -ForegroundColor Gray
        } else {
            throw "Component file not found: $componentPath"
        }
    } catch {
        $failedComponents += $component
        Write-Warning "  [FAILED] Could not load component $component : $($_.Exception.Message)"
    }
}

# Summary
Write-Host "[Unity-Claude-RunspaceManagement] Component loading complete:" -ForegroundColor Green
Write-Host "  Loaded: $($loadedComponents.Count)/$($components.Count) components" -ForegroundColor $(if($failedComponents.Count -eq 0){'Green'}else{'Yellow'})

if ($failedComponents.Count -gt 0) {
    Write-Warning "  Failed components: $($failedComponents -join ', ')"
    Write-Warning "  Some functionality may be limited"
}

# Module-level variables for state preservation
$script:ModuleState = @{
    Version = '2.0.0'
    Architecture = 'Modular'
    LoadedComponents = $loadedComponents
    FailedComponents = $failedComponents
    InitializedTime = Get-Date
}

# High-level wrapper functions that coordinate components

function Initialize-RunspaceManagement {
    <#
    .SYNOPSIS
    Initializes the runspace management system with all components
    .DESCRIPTION
    Sets up the complete runspace management infrastructure with session state, pools, and monitoring
    .PARAMETER EnableResourceMonitoring
    Enable CPU and memory monitoring
    .PARAMETER MaxRunspaces
    Maximum number of runspaces to allow
    .EXAMPLE
    Initialize-RunspaceManagement -EnableResourceMonitoring -MaxRunspaces 5
    #>
    [CmdletBinding()]
    param(
        [switch]$EnableResourceMonitoring,
        [int]$MaxRunspaces = [Environment]::ProcessorCount
    )
    
    Write-Host "[RunspaceManagement] Initializing runspace management system..." -ForegroundColor Cyan
    
    try {
        # Create session state configuration
        $sessionState = New-RunspaceSessionState -UseCreateDefault -LanguageMode FullLanguage -ExecutionPolicy Bypass
        
        # Import critical modules
        Import-SessionStateModules -SessionStateConfig $sessionState
        
        # Initialize variables
        Initialize-SessionStateVariables -SessionStateConfig $sessionState
        
        # Create production pool
        $poolManager = New-ProductionRunspacePool -SessionStateConfig $sessionState -MaxRunspaces $MaxRunspaces -EnableResourceMonitoring:$EnableResourceMonitoring
        
        # Open the pool
        Open-RunspacePool -PoolManager $poolManager
        
        Write-Host "[RunspaceManagement] Initialization complete" -ForegroundColor Green
        
        return $poolManager
        
    } catch {
        Write-Error "[RunspaceManagement] Initialization failed: $($_.Exception.Message)"
        throw
    }
}

function Get-RunspaceManagementStatus {
    <#
    .SYNOPSIS
    Gets the current status of the runspace management system
    .DESCRIPTION
    Returns comprehensive status information about all pools, jobs, and resources
    .EXAMPLE
    Get-RunspaceManagementStatus
    #>
    [CmdletBinding()]
    param()
    
    $status = @{
        ModuleVersion = $script:ModuleState.Version
        Architecture = $script:ModuleState.Architecture
        InitializedTime = $script:ModuleState.InitializedTime
        Uptime = if($script:ModuleState.InitializedTime) { ((Get-Date) - $script:ModuleState.InitializedTime).ToString() } else { "Not initialized" }
        Components = @{
            Loaded = $script:ModuleState.LoadedComponents
            Failed = $script:ModuleState.FailedComponents
        }
        Pools = @()
        ResourceMonitoring = @{}
    }
    
    # Get all pool statuses
    if (Get-Command Get-AllRunspacePools -ErrorAction SilentlyContinue) {
        $status.Pools = Get-AllRunspacePools
    }
    
    # Get resource monitoring status
    if (Get-Command Get-ResourceMonitoringStatus -ErrorAction SilentlyContinue) {
        $status.ResourceMonitoring = Get-ResourceMonitoringStatus
    }
    
    return $status
}

function Stop-RunspaceManagement {
    <#
    .SYNOPSIS
    Stops all runspace pools and cleans up resources
    .DESCRIPTION
    Gracefully shuts down the runspace management system
    .PARAMETER Force
    Force shutdown even if jobs are running
    .EXAMPLE
    Stop-RunspaceManagement -Force
    #>
    [CmdletBinding()]
    param(
        [switch]$Force
    )
    
    Write-Host "[RunspaceManagement] Shutting down runspace management system..." -ForegroundColor Yellow
    
    try {
        # Get all active pools
        $poolRegistry = Get-RunspacePoolRegistry
        $closedCount = 0
        
        foreach ($poolName in $poolRegistry.Keys) {
            try {
                $pool = $poolRegistry[$poolName]
                
                # Cleanup resources
                if (Get-Command Invoke-RunspacePoolCleanup -ErrorAction SilentlyContinue) {
                    Invoke-RunspacePoolCleanup -PoolManager $pool -Force:$Force
                }
                
                # Close pool
                if (Get-Command Close-RunspacePool -ErrorAction SilentlyContinue) {
                    Close-RunspacePool -PoolManager $pool -Force:$Force
                    $closedCount++
                }
                
            } catch {
                Write-Warning "Failed to close pool '$poolName': $($_.Exception.Message)"
            }
        }
        
        Write-Host "[RunspaceManagement] Shutdown complete. Closed $closedCount pools" -ForegroundColor Green
        
        return @{
            Success = $true
            PoolsClosed = $closedCount
            Timestamp = Get-Date
        }
        
    } catch {
        Write-Error "[RunspaceManagement] Shutdown failed: $($_.Exception.Message)"
        throw
    }
}

# Export all functions from loaded components plus orchestrator functions
$exportedFunctions = @(
    # Core functions
    'Write-ModuleLog',
    'Get-RunspacePoolRegistry',
    'Get-SharedVariablesDictionary',
    'Get-SessionStatesRegistry',
    
    # Session State Configuration
    'New-RunspaceSessionState',
    'Set-SessionStateConfiguration',
    'Add-SessionStateModule',
    'Add-SessionStateVariable',
    'Test-SessionStateConfiguration',
    
    # Module/Variable Preloading
    'Import-SessionStateModules',
    'Initialize-SessionStateVariables',
    'Get-SessionStateModules',
    'Get-SessionStateVariables',
    
    # Variable Sharing
    'New-SessionStateVariableEntry',
    'Add-SharedVariable',
    'Get-SharedVariable',
    'Set-SharedVariable',
    'Remove-SharedVariable',
    'Test-SharedVariableAccess',
    'Get-AllSharedVariables',
    
    # Runspace Pool Management
    'New-ManagedRunspacePool',
    'Open-RunspacePool',
    'Close-RunspacePool',
    'Get-RunspacePoolStatus',
    'Test-RunspacePoolHealth',
    'Get-AllRunspacePools',
    
    # Production Runspace Pool
    'New-ProductionRunspacePool',
    'Submit-RunspaceJob',
    'Update-RunspaceJobStatus',
    'Wait-RunspaceJobs',
    'Get-RunspaceJobResults',
    
    # Throttling and Resource Control
    'Test-RunspacePoolResources',
    'Set-AdaptiveThrottling',
    'Invoke-RunspacePoolCleanup',
    'Get-ResourceMonitoringStatus',
    
    # Orchestrator functions
    'Initialize-RunspaceManagement',
    'Get-RunspaceManagementStatus',
    'Stop-RunspaceManagement'
)

# Only export functions that are actually available
$availableFunctions = @()
foreach ($func in $exportedFunctions) {
    if (Get-Command $func -ErrorAction SilentlyContinue) {
        $availableFunctions += $func
    }
}

Export-ModuleMember -Function $availableFunctions

Write-Host "[Unity-Claude-RunspaceManagement] Module loaded with $($availableFunctions.Count) functions" -ForegroundColor Green


# SIG # Begin signature block
# MIIFzgYJKoZIhvcNAQcCoIIFvzCCBbsCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCBCIr8I9qCGsDgR
# d4nwfb+O8TUXVfbVhNHi7B2AhoEruaCCAzAwggMsMIICFKADAgECAhB1HRbZIqgr
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
# MAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIN8zuxG1ujC5ZcJR37NQSMh3
# JZ58EO/K7UucsxwBTYKBMA0GCSqGSIb3DQEBAQUABIIBAImslPpjHo4pjHMdgHMg
# zFxkjru8Dlgksii8XTyzGXb36DhGtq9vbNW2MVQaWmlhWDlE4iDi/vxh2JyZpQtU
# ICzfO/vaIL1yPpLcmbSzh11iGmtSqcY/5s9skm4SfUQDPKRjWgp547FuCFsiZpJk
# lSHOqr6Ul+tPxW0nk6JRF7MIXInCPSTTkL2H5M/TPgJNyZNuvmU003jOifXsZwGJ
# 2Uk1e66ThzartW8S3/uOatVFaahGvz8UOiQjOYjW3tLM3ZZC/k8s1tnQ2hehU0nP
# QKssoLUZ2n6cW9qns/Qny9F5Jc/RoXmYyUSFPAemn94GOWIdgC+PfmoiNAzmnFrh
# ens=
# SIG # End signature block
