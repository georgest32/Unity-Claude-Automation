# Unity-Claude-AutonomousStateTracker-Enhanced-Refactored.psm1
# Refactored autonomous operation state tracking for Phase 3 Day 15
# Comprehensive state machine with persistence, recovery, and human intervention
# 
# REFACTORED VERSION 2.0.0 - Component-Based Architecture
# Original: Unity-Claude-AutonomousStateTracker-Enhanced.psm1 (1,465 lines)
# Refactored: 6 focused components (115-400 lines each, all under 800-line limit)
#
# Components:
# - StateConfiguration: Configuration and state definitions (220 lines)
# - CoreUtilities: Core utilities and helper functions (220 lines)  
# - StateMachineCore: State machine core functions (400 lines)
# - StatePersistence: State persistence and recovery (200 lines)
# - HumanIntervention: Human intervention system (240 lines)
# - HealthMonitoring: Performance and health monitoring (115 lines)

# Module self-registration for session visibility
if (-not $ExecutionContext.SessionState.Module) {
    $ModuleName = 'Unity-Claude-AutonomousStateTracker-Enhanced'
    if (-not (Get-Module -Name $ModuleName)) {
        # Module is being imported but not yet visible in session
        Write-Verbose "[$ModuleName] Ensuring module registration in session" -Verbose:$false
    }
} else {
    # Module context is properly established
    Write-Verbose "[$($ExecutionContext.SessionState.Module.Name)] Module context established" -Verbose:$false
}

$ErrorActionPreference = "Stop"

Write-Host "[Enhanced-StateTracker-Refactored] Loading Phase 3 autonomous state management v2.0.0..." -ForegroundColor Cyan

#region Component Imports

# Import all core components
$coreModules = @(
    'StateConfiguration',
    'CoreUtilities',
    'StateMachineCore', 
    'StatePersistence',
    'HumanIntervention',
    'HealthMonitoring'
)

foreach ($module in $coreModules) {
    $modulePath = Join-Path $PSScriptRoot "Core\$module.psm1"
    if (Test-Path $modulePath) {
        try {
            Import-Module $modulePath -Force -Global
            Write-Host "[Enhanced-StateTracker] Loaded component: $module" -ForegroundColor Gray
        } catch {
            Write-Warning "Failed to load component $module`: $($_.Exception.Message)"
            throw "Critical component failure: $module"
        }
    } else {
        throw "Required component not found: $modulePath"
    }
}

#endregion

#region Enhanced Public Interface and Orchestration Functions

function Get-AutonomousStateTrackerComponents {
    <#
    .SYNOPSIS
    Get information about all loaded components and their health
    #>
    [CmdletBinding()]
    param()
    
    try {
        $components = @()
        
        foreach ($module in $coreModules) {
            $modulePath = Join-Path $PSScriptRoot "Core\$module.psm1"
            
            $componentInfo = @{
                Name = $module
                Status = "Loaded"
                FilePath = $modulePath
                FileExists = Test-Path $modulePath
                LoadError = $null
            }
            
            # Test component health by calling a key function if available
            try {
                switch ($module) {
                    'StateConfiguration' { 
                        $config = Get-EnhancedStateConfig
                        $componentInfo.HealthCheck = if ($config) { "Healthy" } else { "Warning" }
                    }
                    'CoreUtilities' {
                        $testHash = ConvertTo-HashTable -Object @{Test = "Value"}
                        $componentInfo.HealthCheck = if ($testHash.Test -eq "Value") { "Healthy" } else { "Warning" }
                    }
                    'StateMachineCore' {
                        $states = Get-EnhancedAutonomousStates
                        $componentInfo.HealthCheck = if ($states -and $states.Count -gt 0) { "Healthy" } else { "Warning" }
                    }
                    'StatePersistence' {
                        # Test checkpoint functionality is available
                        $componentInfo.HealthCheck = if (Get-Command New-StateCheckpoint -ErrorAction SilentlyContinue) { "Healthy" } else { "Warning" }
                    }
                    'HumanIntervention' {
                        # Test intervention functionality is available
                        $componentInfo.HealthCheck = if (Get-Command Request-HumanIntervention -ErrorAction SilentlyContinue) { "Healthy" } else { "Warning" }
                    }
                    'HealthMonitoring' {
                        # Test monitoring functionality is available
                        $componentInfo.HealthCheck = if (Get-Command Start-EnhancedHealthMonitoring -ErrorAction SilentlyContinue) { "Healthy" } else { "Warning" }
                    }
                    default {
                        $componentInfo.HealthCheck = "Unknown"
                    }
                }
            } catch {
                $componentInfo.HealthCheck = "Error"
                $componentInfo.LoadError = $_.Exception.Message
            }
            
            $components += $componentInfo
        }
        
        return @{
            TotalComponents = $components.Count
            HealthyComponents = ($components | Where-Object { $_.HealthCheck -eq "Healthy" }).Count
            Components = $components
            OverallHealth = if (($components | Where-Object { $_.HealthCheck -ne "Healthy" }).Count -eq 0) { "Healthy" } else { "Warning" }
        }
        
    } catch {
        Write-EnhancedStateLog -Message "Failed to get component information: $($_.Exception.Message)" -Level "ERROR"
        throw
    }
}

function Test-AutonomousStateTrackerHealth {
    <#
    .SYNOPSIS
    Comprehensive health test of the autonomous state tracker system
    #>
    [CmdletBinding()]
    param(
        [string]$AgentId = "HealthTest-$(Get-Date -Format 'yyyyMMdd-HHmmss')"
    )
    
    try {
        Write-EnhancedStateLog -Message "Starting comprehensive health test with agent: $AgentId" -Level "INFO"
        
        $healthResults = @{
            TestStartTime = Get-Date
            AgentId = $AgentId
            ComponentTests = @()
            IntegrationTests = @()
            OverallResult = "Unknown"
            TestErrors = @()
        }
        
        # Test 1: Component Health
        $componentHealth = Get-AutonomousStateTrackerComponents
        $healthResults.ComponentTests = $componentHealth.Components
        
        # Test 2: Initialize agent state
        try {
            $agentState = Initialize-EnhancedAutonomousStateTracking -AgentId $AgentId
            $healthResults.IntegrationTests += @{
                Test = "Agent State Initialization"
                Result = "Pass"
                Details = "Successfully initialized agent state"
            }
        } catch {
            $healthResults.IntegrationTests += @{
                Test = "Agent State Initialization"
                Result = "Fail"
                Error = $_.Exception.Message
            }
            $healthResults.TestErrors += "Agent initialization failed"
        }
        
        # Test 3: State transition
        try {
            Set-EnhancedAutonomousState -AgentId $AgentId -NewState "Initializing" -Reason "Health test transition"
            $healthResults.IntegrationTests += @{
                Test = "State Transition"
                Result = "Pass"
                Details = "Successfully transitioned from Idle to Initializing"
            }
        } catch {
            $healthResults.IntegrationTests += @{
                Test = "State Transition"
                Result = "Fail"
                Error = $_.Exception.Message
            }
            $healthResults.TestErrors += "State transition failed"
        }
        
        # Test 4: State persistence
        try {
            $retrievedState = Get-EnhancedAutonomousState -AgentId $AgentId
            if ($retrievedState -and $retrievedState.CurrentState -eq "Initializing") {
                $healthResults.IntegrationTests += @{
                    Test = "State Persistence"
                    Result = "Pass"
                    Details = "Successfully persisted and retrieved agent state"
                }
            } else {
                $healthResults.IntegrationTests += @{
                    Test = "State Persistence"
                    Result = "Fail"
                    Error = "Retrieved state does not match expected state"
                }
                $healthResults.TestErrors += "State persistence verification failed"
            }
        } catch {
            $healthResults.IntegrationTests += @{
                Test = "State Persistence"
                Result = "Fail"
                Error = $_.Exception.Message
            }
            $healthResults.TestErrors += "State persistence test failed"
        }
        
        # Test 5: Checkpoint creation
        try {
            $checkpointId = New-StateCheckpoint -AgentState $agentState -Reason "Health test checkpoint"
            if ($checkpointId) {
                $healthResults.IntegrationTests += @{
                    Test = "Checkpoint Creation"
                    Result = "Pass"
                    Details = "Successfully created checkpoint: $checkpointId"
                }
            } else {
                $healthResults.IntegrationTests += @{
                    Test = "Checkpoint Creation"
                    Result = "Fail"
                    Error = "Checkpoint ID not returned"
                }
                $healthResults.TestErrors += "Checkpoint creation returned null"
            }
        } catch {
            $healthResults.IntegrationTests += @{
                Test = "Checkpoint Creation"
                Result = "Fail"
                Error = $_.Exception.Message
            }
            $healthResults.TestErrors += "Checkpoint creation failed"
        }
        
        # Test 6: Performance metrics collection
        try {
            $performanceMetrics = Get-SystemPerformanceMetrics
            if ($performanceMetrics -and $performanceMetrics.Count -gt 0) {
                $healthResults.IntegrationTests += @{
                    Test = "Performance Metrics Collection"
                    Result = "Pass"
                    Details = "Successfully collected $($performanceMetrics.Count) performance metrics"
                }
            } else {
                $healthResults.IntegrationTests += @{
                    Test = "Performance Metrics Collection"
                    Result = "Fail"
                    Error = "No performance metrics collected"
                }
                $healthResults.TestErrors += "Performance metrics collection returned empty"
            }
        } catch {
            $healthResults.IntegrationTests += @{
                Test = "Performance Metrics Collection"
                Result = "Fail"
                Error = $_.Exception.Message
            }
            $healthResults.TestErrors += "Performance metrics collection failed"
        }
        
        # Clean up test agent
        try {
            $stateConfig = Get-EnhancedStateConfig
            $stateFile = Join-Path $stateConfig.StateDataPath "$AgentId.json"
            if (Test-Path $stateFile) {
                Remove-Item $stateFile -Force
            }
        } catch {
            Write-EnhancedStateLog -Message "Failed to clean up test agent: $($_.Exception.Message)" -Level "WARNING"
        }
        
        # Determine overall result
        $failedTests = $healthResults.IntegrationTests | Where-Object { $_.Result -eq "Fail" }
        $unhealthyComponents = $healthResults.ComponentTests | Where-Object { $_.HealthCheck -ne "Healthy" }
        
        if ($failedTests.Count -eq 0 -and $unhealthyComponents.Count -eq 0) {
            $healthResults.OverallResult = "Healthy"
        } elseif ($failedTests.Count -eq 0 -and $unhealthyComponents.Count -le 1) {
            $healthResults.OverallResult = "Warning"
        } else {
            $healthResults.OverallResult = "Critical"
        }
        
        $healthResults.TestEndTime = Get-Date
        $healthResults.TotalTestTime = $healthResults.TestEndTime - $healthResults.TestStartTime
        
        Write-EnhancedStateLog -Message "Health test completed: $($healthResults.OverallResult)" -Level "INFO" -AdditionalData @{
            ComponentsHealthy = ($healthResults.ComponentTests | Where-Object { $_.HealthCheck -eq "Healthy" }).Count
            IntegrationTestsPassed = ($healthResults.IntegrationTests | Where-Object { $_.Result -eq "Pass" }).Count
            TotalErrors = $healthResults.TestErrors.Count
        }
        
        return $healthResults
        
    } catch {
        Write-EnhancedStateLog -Message "Health test failed with exception: $($_.Exception.Message)" -Level "ERROR"
        throw
    }
}

function Invoke-ComprehensiveAutonomousAnalysis {
    <#
    .SYNOPSIS
    Perform comprehensive analysis of autonomous state tracking system
    #>
    [CmdletBinding()]
    param(
        [string]$AgentId,
        [switch]$IncludePerformanceAnalysis,
        [switch]$IncludeHealthAnalysis,
        [switch]$GenerateActionPlan
    )
    
    try {
        Write-EnhancedStateLog -Message "Starting comprehensive autonomous analysis" -Level "INFO"
        
        $analysis = @{
            AnalysisStartTime = Get-Date
            AgentId = $AgentId
            ComponentStatus = Get-AutonomousStateTrackerComponents
            SystemHealth = $null
            AgentAnalysis = $null
            PerformanceAnalysis = $null
            ActionPlan = $null
        }
        
        # System health analysis
        if ($IncludeHealthAnalysis) {
            $analysis.SystemHealth = Test-AutonomousStateTrackerHealth
        }
        
        # Agent-specific analysis
        if ($AgentId) {
            $agentState = Get-EnhancedAutonomousState -AgentId $AgentId -IncludeHistory -IncludePerformanceMetrics
            if ($agentState) {
                $analysis.AgentAnalysis = @{
                    CurrentState = $agentState.CurrentState
                    IsOperational = $agentState.IsOperational
                    SuccessRate = $agentState.SuccessRate
                    ConsecutiveFailures = $agentState.ConsecutiveFailures
                    UptimeMinutes = $agentState.UptimeMinutes
                    CircuitBreakerState = $agentState.CircuitBreakerState
                    RecentStateHistory = $agentState.StateHistory | Select-Object -Last 5
                    PerformanceMetrics = if ($IncludePerformanceAnalysis) { $agentState.CurrentPerformanceMetrics } else { $null }
                }
            }
        }
        
        # Generate action plan if requested
        if ($GenerateActionPlan) {
            $actions = @()
            
            # Component-based actions
            $unhealthyComponents = $analysis.ComponentStatus.Components | Where-Object { $_.HealthCheck -ne "Healthy" }
            foreach ($component in $unhealthyComponents) {
                $actions += @{
                    Priority = "High"
                    Category = "Component Health"
                    Action = "Investigate and resolve issues with component: $($component.Name)"
                    Details = $component.LoadError
                }
            }
            
            # Agent-specific actions
            if ($analysis.AgentAnalysis) {
                if ($analysis.AgentAnalysis.SuccessRate -lt 0.8) {
                    $actions += @{
                        Priority = "Medium"
                        Category = "Agent Performance"
                        Action = "Investigate low success rate: $($analysis.AgentAnalysis.SuccessRate)"
                        Details = "Agent has $($analysis.AgentAnalysis.ConsecutiveFailures) consecutive failures"
                    }
                }
                
                if ($analysis.AgentAnalysis.CircuitBreakerState -eq "Open") {
                    $actions += @{
                        Priority = "Critical"
                        Category = "Circuit Breaker"
                        Action = "Address circuit breaker activation"
                        Details = "Circuit breaker is open, indicating repeated failures"
                    }
                }
            }
            
            $analysis.ActionPlan = @{
                TotalActions = $actions.Count
                CriticalActions = ($actions | Where-Object { $_.Priority -eq "Critical" }).Count
                HighActions = ($actions | Where-Object { $_.Priority -eq "High" }).Count
                MediumActions = ($actions | Where-Object { $_.Priority -eq "Medium" }).Count
                Actions = $actions
            }
        }
        
        $analysis.AnalysisEndTime = Get-Date
        $analysis.TotalAnalysisTime = $analysis.AnalysisEndTime - $analysis.AnalysisStartTime
        
        Write-EnhancedStateLog -Message "Comprehensive analysis completed" -Level "INFO" -AdditionalData @{
            ComponentsAnalyzed = $analysis.ComponentStatus.TotalComponents
            ActionsGenerated = if ($analysis.ActionPlan) { $analysis.ActionPlan.TotalActions } else { 0 }
            AnalysisTimeSeconds = [math]::Round($analysis.TotalAnalysisTime.TotalSeconds, 2)
        }
        
        return $analysis
        
    } catch {
        Write-EnhancedStateLog -Message "Comprehensive analysis failed: $($_.Exception.Message)" -Level "ERROR"
        throw
    }
}

#endregion

#region Public Interface

# Export enhanced public functions (maintaining backward compatibility)
Export-ModuleMember -Function @(
    # Core state management (from StateMachineCore)
    'Initialize-EnhancedAutonomousStateTracking',
    'Set-EnhancedAutonomousState',
    'Get-EnhancedAutonomousState',
    'Get-AgentState',
    'Save-AgentState',
    
    # State persistence and recovery (from StatePersistence)
    'New-StateCheckpoint',
    'Restore-AgentStateFromCheckpoint',
    'Get-CheckpointHistory',
    'Remove-OldCheckpoints',
    'Test-CheckpointIntegrity',
    
    # Human intervention (from HumanIntervention)
    'Request-HumanIntervention',
    'Approve-AgentIntervention',
    'Deny-AgentIntervention',
    'Get-PendingInterventions',
    'Clear-ResolvedInterventions',
    
    # Health and performance monitoring (from HealthMonitoring)
    'Start-EnhancedHealthMonitoring',
    'Stop-EnhancedHealthMonitoring',
    'Get-HealthMonitoringStatus',
    'Test-AgentHealth',
    
    # Utilities and compatibility (from CoreUtilities)
    'Write-EnhancedStateLog',
    'ConvertTo-HashTable',
    'Get-SafeDateTime',
    'Get-UptimeMinutes',
    'Get-SystemPerformanceMetrics',
    'Test-SystemHealthThresholds',
    
    # Configuration access (from StateConfiguration)
    'Get-EnhancedStateConfig',
    'Initialize-StateDirectories',
    'Get-EnhancedAutonomousStates',
    'Get-PerformanceCounters',
    
    # Enhanced orchestration functions (new in v2.0.0)
    'Get-AutonomousStateTrackerComponents',
    'Test-AutonomousStateTrackerHealth',
    'Invoke-ComprehensiveAutonomousAnalysis'
)

Write-Host "[Enhanced-StateTracker-Refactored] Phase 3 autonomous state management v2.0.0 loaded successfully" -ForegroundColor Green
Write-Host "[Enhanced-StateTracker-Refactored] Features: Component-based architecture, enhanced orchestration, comprehensive health testing" -ForegroundColor Gray
Write-Host "[Enhanced-StateTracker-Refactored] Components: 6 modular components (all under 800 lines), improved maintainability" -ForegroundColor Gray

#endregion

# SIG # Begin signature block
# MIIFzgYJKoZIhvcNAQcCoIIFvzCCBbsCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCCIx74kwc5nhxsR
# TWElSN6RNLZBh6OlNQqVr4MIZaVTrKCCAzAwggMsMIICFKADAgECAhB1HRbZIqgr
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
# MAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEII8KYJo4a2CULWAjibLYjbcq
# bAUSDro7DHWPWEH2qxKaMA0GCSqGSIb3DQEBAQUABIIBAGesIhUYuIQYeX5OmlhC
# iFNVIrLXdIQKP04J7FA0io2s22TM/BUNsX9xMwmWVs45+qrKIJbkoij3QoXlkE7c
# jciZqEFpQBjeBM3e4VS8shbYcuCxmzwRqCj1BQwJYVCaU+VFnAvGFGJHYXxoqreg
# trb4LP7ZWYdOXPQr9ocXDnOI6lh9ndJtGp0WrehQjs4zEMO7Mvd/8Z/lRngUEn/6
# HH8CgGu/B6B2+2lZhP3DZOneZAyNo3sU90DroqIJAtWz8n/jas52+Xp4rqUNvTO+
# 4CIhKZ38hBewpegVYvzcKAnuT5fBQkuAYBCNPQd14RG4FYkioLcYOr89wW8b7MiZ
# oU8=
# SIG # End signature block
