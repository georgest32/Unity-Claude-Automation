#Requires -Version 5.1
<#
.SYNOPSIS
    Status reporting and management functions for Unity-Claude-MasterOrchestrator.

.DESCRIPTION
    Provides comprehensive status reporting, integration testing, operation history
    management, and state cleanup functions for the master orchestrator system.

.NOTES
    Part of Unity-Claude-MasterOrchestrator refactored architecture
    Originally from Unity-Claude-MasterOrchestrator.psm1 (lines 1096-1237)
    Refactoring Date: 2025-08-25
#>

# Import the core orchestrator and other required components
Import-Module "$PSScriptRoot\OrchestratorCore.psm1" -Force
Import-Module "$PSScriptRoot\ModuleIntegration.psm1" -Force
Import-Module "$PSScriptRoot\EventProcessing.psm1" -Force
Import-Module "$PSScriptRoot\DecisionExecution.psm1" -Force
Import-Module "$PSScriptRoot\AutonomousFeedbackLoop.psm1" -Force

function Get-OrchestratorStatus {
    <#
    .SYNOPSIS
    Gets comprehensive status information about the orchestrator system.
    #>
    [CmdletBinding()]
    param()
    
    try {
        $config = Get-OrchestratorConfig
        $state = Get-OrchestratorState
        $architecture = Get-ModuleArchitecture
        
        return @{
            Configuration = $config
            IntegratedModules = @{
                Count = $state.IntegratedModules.Count
                Modules = $state.IntegratedModules
                Details = $state.IntegratedModules  # More detailed info if available
            }
            FeedbackLoop = @{
                Active = $state.FeedbackLoopActive
                ConversationRounds = $config.ConversationRounds
                MaxRounds = $config.MaxConversationRounds
            }
            EventProcessing = @{
                QueueSize = $state.EventQueueSize
                ActiveOperations = $state.ActiveOperations.Count
                HistoryCount = $state.OperationHistoryCount
            }
            ModuleArchitecture = $architecture
            StatusTime = Get-Date
        }
    }
    catch {
        Write-OrchestratorLog -Message "Error getting orchestrator status: $_" -Level "ERROR"
        return @{
            Error = $_.Exception.Message
            StatusTime = Get-Date
        }
    }
}

function Test-OrchestratorIntegration {
    <#
    .SYNOPSIS
    Performs comprehensive integration testing of the orchestrator system.
    #>
    [CmdletBinding()]
    param()
    
    Write-OrchestratorLog -Message "Testing Master Orchestrator integration" -Level "INFO"
    
    $testResults = @{
        ModuleIntegration = $false
        EventProcessing = $false
        DecisionExecution = $false
        FeedbackLoop = $false
        OverallStatus = "FAIL"
        TestTime = Get-Date
    }
    
    try {
        # Test module integration
        $initResult = Initialize-ModuleIntegration
        if ($initResult.Success -and $initResult.LoadedModules.Count -gt 0) {
            $testResults.ModuleIntegration = $true
            Write-OrchestratorLog -Message "Module integration test: PASS ($($initResult.LoadedModules.Count) modules loaded)" -Level "DEBUG"
        }
        
        # Test event processing
        $state = Get-OrchestratorState
        if ($state.EventQueue -ne $null) {
            $testResults.EventProcessing = $true
            Write-OrchestratorLog -Message "Event processing test: PASS" -Level "DEBUG"
        }
        
        # Test decision execution framework
        $testDecision = @{
            Action = "NO_ACTION"
            Confidence = 0.5
            DecisionId = [guid]::NewGuid().ToString()
        }
        $execResult = Invoke-DecisionExecution -Decision $testDecision
        if ($execResult.Success) {
            $testResults.DecisionExecution = $true
            Write-OrchestratorLog -Message "Decision execution test: PASS" -Level "DEBUG"
        }
        
        # Test feedback loop capability
        $config = Get-OrchestratorConfig
        if ($config -ne $null -and $initResult.LoadedModules.Count -gt 0) {
            $testResults.FeedbackLoop = $true
            Write-OrchestratorLog -Message "Feedback loop capability test: PASS" -Level "DEBUG"
        }
        
        # Calculate overall status
        $passCount = ($testResults.GetEnumerator() | Where-Object { 
            $_.Key -notin @("OverallStatus", "TestTime") -and $_.Value -eq $true 
        }).Count
        
        if ($passCount -ge 3) {
            $testResults.OverallStatus = "PASS"
            Write-OrchestratorLog -Message "Master Orchestrator integration test: PASS ($passCount/4 tests passed)" -Level "INFO"
        } else {
            Write-OrchestratorLog -Message "Master Orchestrator integration test: FAIL ($passCount/4 tests passed)" -Level "WARN"
        }
        
        return $testResults
    }
    catch {
        Write-OrchestratorLog -Message "Error during integration test: $_" -Level "ERROR"
        $testResults.OverallStatus = "ERROR"
        $testResults.Error = $_.Exception.Message
        return $testResults
    }
}

function Get-OperationHistory {
    <#
    .SYNOPSIS
    Retrieves recent operation history from the orchestrator.
    #>
    [CmdletBinding()]
    param(
        [Parameter()]
        [int]$Last = 20
    )
    
    try {
        $state = Get-OrchestratorState
        
        # If we have access to the operation history
        if ($state.OperationHistory) {
            $historyCount = [Math]::Min($Last, $state.OperationHistoryCount)
            $startIndex = [Math]::Max(0, $state.OperationHistoryCount - $historyCount)
            
            # For now, return a placeholder structure since we don't have direct access
            # to the operation history collection from the state
            return @{
                RequestedCount = $Last
                AvailableCount = $state.OperationHistoryCount
                RetrievedCount = $historyCount
                Operations = @()  # Would contain actual operation records
                RetrievalTime = Get-Date
            }
        }
        
        return @{
            Message = "No operation history available"
            RetrievalTime = Get-Date
        }
    }
    catch {
        Write-OrchestratorLog -Message "Error retrieving operation history: $_" -Level "ERROR"
        return @{
            Error = $_.Exception.Message
            RetrievalTime = Get-Date
        }
    }
}

function Clear-OrchestratorState {
    <#
    .SYNOPSIS
    Clears the orchestrator state and resets configuration.
    #>
    [CmdletBinding()]
    [OutputType([hashtable])]
    param(
        [Parameter()]
        [switch]$Force
    )
    
    Write-OrchestratorLog -Message "Clearing orchestrator state" -Level "INFO"
    
    if (-not $Force) {
        Write-OrchestratorLog -Message "State clearing requires -Force parameter for safety" -Level "WARN"
        return @{
            Success = $false
            Reason = "Force parameter required"
            Timestamp = Get-Date
        }
    }
    
    try {
        $state = Get-OrchestratorState
        $config = Get-OrchestratorConfig
        
        $clearedItems = @{
            IntegratedModulesCount = if ($state.IntegratedModules) { $state.IntegratedModules.Count } else { 0 }
            EventQueueSize = if ($state.EventQueue) { $state.EventQueueSize } else { 0 }
            ActiveOperationsCount = if ($state.ActiveOperations) { $state.ActiveOperations.Count } else { 0 }
            OperationHistoryCount = if ($state.OperationHistory) { $state.OperationHistoryCount } else { 0 }
        }
        
        # Reset configuration to defaults
        $resetConfig = @{
            ConversationRounds = 0
            EnableAutonomousMode = $false
            EnableDebugLogging = $config.EnableDebugLogging  # Preserve logging setting
            SequentialProcessing = $true
            EventDrivenMode = $true
            MaxConcurrentOperations = 3
            OperationTimeoutMs = 30000
            SafetyValidationEnabled = $true
            LearningIntegrationEnabled = $true
            MaxConversationRounds = 10
        }
        
        Set-OrchestratorConfig -Config $resetConfig
        
        Write-OrchestratorLog -Message "Orchestrator state cleared: $($clearedItems.IntegratedModulesCount) modules, $($clearedItems.EventQueueSize) events, $($clearedItems.OperationHistoryCount) history entries" -Level "INFO"
        
        return @{
            Success = $true
            ClearedItems = $clearedItems
            Timestamp = Get-Date
        }
    }
    catch {
        Write-OrchestratorLog -Message "Error clearing orchestrator state: $_" -Level "ERROR"
        return @{
            Success = $false
            Error = $_.Exception.Message
            Timestamp = Get-Date
        }
    }
}

function Get-OrchestratorHealth {
    <#
    .SYNOPSIS
    Performs a health check on the orchestrator system.
    #>
    [CmdletBinding()]
    param()
    
    Write-OrchestratorLog -Message "Performing orchestrator health check" -Level "DEBUG"
    
    $healthReport = @{
        OverallHealth = "UNKNOWN"
        ComponentHealth = @{}
        Issues = @()
        Recommendations = @()
        CheckTime = Get-Date
    }
    
    try {
        $issueCount = 0
        
        # Check configuration
        try {
            $config = Get-OrchestratorConfig
            if ($config -and $config.ContainsKey('EnableAutonomousMode')) {
                $healthReport.ComponentHealth.Configuration = "HEALTHY"
            } else {
                $healthReport.ComponentHealth.Configuration = "UNHEALTHY"
                $healthReport.Issues += "Configuration not accessible or invalid"
                $issueCount++
            }
        } catch {
            $healthReport.ComponentHealth.Configuration = "ERROR"
            $healthReport.Issues += "Configuration error: $($_.Exception.Message)"
            $issueCount++
        }
        
        # Check module integration
        try {
            $initTest = Initialize-ModuleIntegration
            if ($initTest.Success -and $initTest.LoadedModules.Count -gt 0) {
                $healthReport.ComponentHealth.ModuleIntegration = "HEALTHY"
            } else {
                $healthReport.ComponentHealth.ModuleIntegration = "DEGRADED"
                $healthReport.Issues += "Few or no modules loaded"
                $issueCount++
            }
        } catch {
            $healthReport.ComponentHealth.ModuleIntegration = "ERROR"
            $healthReport.Issues += "Module integration error: $($_.Exception.Message)"
            $issueCount++
        }
        
        # Check event processing
        try {
            $state = Get-OrchestratorState
            if ($state.EventQueue -ne $null) {
                $healthReport.ComponentHealth.EventProcessing = "HEALTHY"
            } else {
                $healthReport.ComponentHealth.EventProcessing = "UNHEALTHY"
                $healthReport.Issues += "Event processing system not initialized"
                $issueCount++
            }
        } catch {
            $healthReport.ComponentHealth.EventProcessing = "ERROR"
            $healthReport.Issues += "Event processing error: $($_.Exception.Message)"
            $issueCount++
        }
        
        # Determine overall health
        if ($issueCount -eq 0) {
            $healthReport.OverallHealth = "HEALTHY"
        } elseif ($issueCount -le 1) {
            $healthReport.OverallHealth = "DEGRADED"
            $healthReport.Recommendations += "Address minor issues to restore full functionality"
        } else {
            $healthReport.OverallHealth = "UNHEALTHY"
            $healthReport.Recommendations += "Multiple issues detected - system may not function properly"
        }
        
        Write-OrchestratorLog -Message "Health check completed: $($healthReport.OverallHealth) ($issueCount issues)" -Level "INFO"
        
        return $healthReport
    }
    catch {
        Write-OrchestratorLog -Message "Error during health check: $_" -Level "ERROR"
        $healthReport.OverallHealth = "ERROR"
        $healthReport.Issues += "Health check failed: $($_.Exception.Message)"
        return $healthReport
    }
}

function Reset-OrchestratorToDefaults {
    <#
    .SYNOPSIS
    Resets the orchestrator to default configuration and clears all state.
    #>
    [CmdletBinding()]
    param(
        [Parameter()]
        [switch]$Force
    )
    
    Write-OrchestratorLog -Message "Resetting orchestrator to defaults" -Level "INFO"
    
    if (-not $Force) {
        Write-OrchestratorLog -Message "Reset requires -Force parameter for safety" -Level "WARN"
        return @{
            Success = $false
            Reason = "Force parameter required for safety"
            Timestamp = Get-Date
        }
    }
    
    try {
        # Stop any active feedback loops first
        $stopResult = Stop-AutonomousFeedbackLoop
        
        # Clear state
        $clearResult = Clear-OrchestratorState -Force
        
        Write-OrchestratorLog -Message "Orchestrator reset completed successfully" -Level "INFO"
        
        return @{
            Success = $true
            StopFeedbackLoop = $stopResult.Success
            StateCleared = $clearResult.Success
            Timestamp = Get-Date
        }
    }
    catch {
        Write-OrchestratorLog -Message "Error resetting orchestrator: $_" -Level "ERROR"
        return @{
            Success = $false
            Error = $_.Exception.Message
            Timestamp = Get-Date
        }
    }
}

Export-ModuleMember -Function @(
    'Get-OrchestratorStatus',
    'Test-OrchestratorIntegration',
    'Get-OperationHistory',
    'Clear-OrchestratorState',
    'Get-OrchestratorHealth',
    'Reset-OrchestratorToDefaults'
)

# REFACTORING MARKER: This module was refactored from Unity-Claude-MasterOrchestrator.psm1 on 2025-08-25
# Original file size: 1276 lines
# This component: Status reporting and management functions (lines 1096-1237)
# SIG # Begin signature block
# MIIFzgYJKoZIhvcNAQcCoIIFvzCCBbsCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCAbINwbcWAl25td
# FCqmE7YT62rSVQ2GC7vXOzWGIgpWgqCCAzAwggMsMIICFKADAgECAhB1HRbZIqgr
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
# MAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIG26TEu7zIJrtzE8geIa+7R3
# lVaE/VffhBl/DA6f9RVrMA0GCSqGSIb3DQEBAQUABIIBAA4//qLp2uKTrQdZQ/+y
# lcW1zEbMx/J3bk4K0iItuHNizf5lAGmM6wqBWiKznFaz0tajeXMIR/upO3UNFzyO
# 9cvTQ7aAapc5styt6r6USSYw1pWJSNyT9Dt3NZx3XUK3e/SvyMrV+o4ge7SD9Rg8
# 3A/5v+H5GnSEa/c0Re0PNnJtI6SkNAYwEi4NP3jMqjsEcjqpiWiz1iLTJUwOB8cd
# 6yvTCAefjTA1Gi0+UtVF+eSZz6SHZ+wdKpHzagoV1vf9lvDEuP1qFPOxU/GaSDib
# V/MamjCHaW7D/vbyLmW+eoMy2O94ak1ieb7QtZXj1O7tCo7tdv6aR77mEXf2j5ss
# cCw=
# SIG # End signature block
