# StateMachineCore.psm1
# Core state machine functions for autonomous state tracking
# Refactored component from Unity-Claude-AutonomousStateTracker-Enhanced.psm1
# Component: State machine core functions (400 lines)

#region State Machine Core Functions

function Initialize-EnhancedAutonomousStateTracking {
    <#
    .SYNOPSIS
    Initialize enhanced autonomous state tracking with persistence and recovery
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$AgentId,
        
        [string]$InitialState = "Idle",
        
        [switch]$RestoreFromCheckpoint
    )
    
    try {
        Write-EnhancedStateLog -Message "Initializing enhanced autonomous state tracking for agent: $AgentId" -Level "INFO"
        
        # Get state configurations
        $stateConfig = Get-EnhancedStateConfig
        $autonomousStates = Get-EnhancedAutonomousStates
        
        # Create agent state structure with proper DateTime handling
        $currentTime = Get-Date
        $agentState = @{
            AgentId = $AgentId
            CurrentState = $InitialState
            PreviousState = $null
            StateHistory = @()
            StartTime = $currentTime
            LastStateChange = $currentTime
            LastHealthCheck = $currentTime
            HealthMetrics = @{}
            InterventionHistory = @()
            CheckpointHistory = @()
            ConsecutiveFailures = 0
            SuccessfulOperations = 0
            TotalOperations = 0
            CircuitBreakerState = "Closed"
            HumanInterventionRequested = $false
            PerformanceBaseline = @{}
        }
        
        # Attempt to restore from checkpoint if requested
        if ($RestoreFromCheckpoint) {
            $restored = Restore-AgentStateFromCheckpoint -AgentId $AgentId
            if ($restored) {
                $agentState = $restored
                Write-EnhancedStateLog -Message "Agent state restored from checkpoint" -Level "INFO"
            }
        }
        
        # Validate initial state
        if (-not $autonomousStates.ContainsKey($agentState.CurrentState)) {
            throw "Invalid initial state: $($agentState.CurrentState)"
        }
        
        # Save initial state
        Save-AgentState -AgentState $agentState
        
        # Create initial checkpoint
        New-StateCheckpoint -AgentState $agentState -Reason "Initial state tracking initialization"
        
        Write-EnhancedStateLog -Message "Enhanced autonomous state tracking initialized successfully" -Level "INFO" -AdditionalData @{
            AgentId = $AgentId
            InitialState = $agentState.CurrentState
            RestoreRequested = $RestoreFromCheckpoint.IsPresent
        }
        
        return $agentState
        
    } catch {
        Write-EnhancedStateLog -Message "Failed to initialize enhanced state tracking: $($_.Exception.Message)" -Level "ERROR"
        throw
    }
}

function Set-EnhancedAutonomousState {
    <#
    .SYNOPSIS
    Set autonomous agent state with enhanced validation and persistence
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$AgentId,
        
        [Parameter(Mandatory = $true)]
        [string]$NewState,
        
        [string]$Reason = "State transition",
        
        [hashtable]$AdditionalData = @{},
        
        [switch]$Force
    )
    
    try {
        # Get configurations
        $stateConfig = Get-EnhancedStateConfig
        $autonomousStates = Get-EnhancedAutonomousStates
        
        # Load current agent state
        $agentState = Get-AgentState -AgentId $AgentId
        if (-not $agentState) {
            throw "Agent state not found for AgentId: $AgentId"
        }
        
        $currentState = $agentState.CurrentState
        
        # Validate state transition unless forced
        if (-not $Force) {
            $allowedTransitions = $autonomousStates[$currentState].AllowedTransitions
            if ($NewState -notin $allowedTransitions) {
                throw "Invalid state transition from '$currentState' to '$NewState'. Allowed transitions: $($allowedTransitions -join ', ')"
            }
        }
        
        # Validate new state exists
        if (-not $autonomousStates.ContainsKey($NewState)) {
            throw "Invalid state: $NewState"
        }
        
        Write-EnhancedStateLog -Message "State transition: $currentState -> $NewState | Reason: $Reason" -Level "INFO" -AdditionalData $AdditionalData
        
        # Update agent state with proper DateTime handling
        $changeTime = Get-Date
        $agentState.PreviousState = $currentState
        $agentState.CurrentState = $NewState
        $agentState.LastStateChange = $changeTime
        
        # Add to state history
        $stateTransition = @{
            FromState = $currentState
            ToState = $NewState
            Timestamp = $changeTime
            Reason = $Reason
            AdditionalData = $AdditionalData
            Forced = $Force.IsPresent
        }
        
        $agentState.StateHistory = @($agentState.StateHistory) + @($stateTransition)
        
        # Trim state history if needed
        if ($agentState.StateHistory.Count -gt $stateConfig.StateHistoryRetention) {
            $agentState.StateHistory = $agentState.StateHistory | Select-Object -Last $stateConfig.StateHistoryRetention
        }
        
        # Handle special state transitions
        switch ($NewState) {
            "Error" {
                $agentState.ConsecutiveFailures++
                
                # Check for circuit breaker activation
                if ($agentState.ConsecutiveFailures -ge $stateConfig.CircuitBreakerFailureThreshold -and 
                    $agentState.CircuitBreakerState -eq "Closed") {
                    
                    Write-EnhancedStateLog -Message "Circuit breaker opened due to consecutive failures: $($agentState.ConsecutiveFailures)" -Level "WARNING"
                    $agentState.CircuitBreakerState = "Open"
                    $NewState = "CircuitBreakerOpen"  # Override the state to circuit breaker
                    
                    # Request human intervention for circuit breaker
                    Request-HumanIntervention -AgentId $AgentId -Reason "Circuit breaker activated" -Priority "High"
                }
            }
            "Active" {
                if ($agentState.PreviousState -eq "Error" -or $agentState.PreviousState -eq "Recovering") {
                    $agentState.ConsecutiveFailures = 0  # Reset failure count on successful recovery
                    $agentState.CircuitBreakerState = "Closed"
                }
                $agentState.SuccessfulOperations++
            }
            "HumanApprovalRequired" {
                Request-HumanIntervention -AgentId $AgentId -Reason $Reason -Priority "Medium"
            }
        }
        
        $agentState.TotalOperations++
        
        # Save updated state
        Save-AgentState -AgentState $agentState
        
        # Create checkpoint for critical state changes
        if ($NewState -in @("Error", "CircuitBreakerOpen", "HumanApprovalRequired", "Stopped")) {
            New-StateCheckpoint -AgentState $agentState -Reason "Critical state change: $NewState"
        }
        
        return $agentState
        
    } catch {
        Write-EnhancedStateLog -Message "Failed to set autonomous state: $($_.Exception.Message)" -Level "ERROR"
        throw
    }
}

function Get-EnhancedAutonomousState {
    <#
    .SYNOPSIS
    Get current autonomous agent state with enhanced information
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$AgentId,
        
        [switch]$IncludeHistory,
        
        [switch]$IncludePerformanceMetrics
    )
    
    try {
        $agentState = Get-AgentState -AgentId $AgentId
        if (-not $agentState) {
            return $null
        }
        
        # Get autonomous states configuration
        $autonomousStates = Get-EnhancedAutonomousStates
        
        # Calculate current success rate
        $successRate = if ($agentState.TotalOperations -gt 0) {
            [math]::Round($agentState.SuccessfulOperations / $agentState.TotalOperations, 3)
        } else {
            0
        }
        
        # Get current state definition
        $stateDefinition = $autonomousStates[$agentState.CurrentState]
        
        # Build response object
        $response = @{
            AgentId = $agentState.AgentId
            CurrentState = $agentState.CurrentState
            PreviousState = $agentState.PreviousState
            StateDescription = $stateDefinition.Description
            IsOperational = $stateDefinition.IsOperational
            RequiresMonitoring = $stateDefinition.RequiresMonitoring
            HumanInterventionRequired = $stateDefinition.HumanInterventionRequired
            LastStateChange = $agentState.LastStateChange
            UptimeMinutes = if ($agentState.StartTime) { 
                [math]::Round((Get-UptimeMinutes -StartTime $agentState.StartTime), 2) 
            } else { 
                0.0 
            }
            SuccessRate = $successRate
            ConsecutiveFailures = $agentState.ConsecutiveFailures
            TotalOperations = $agentState.TotalOperations
            CircuitBreakerState = $agentState.CircuitBreakerState
            HumanInterventionRequested = $agentState.HumanInterventionRequested
        }
        
        # Add history if requested
        if ($IncludeHistory) {
            $response.StateHistory = $agentState.StateHistory | Select-Object -Last 20
            $response.InterventionHistory = $agentState.InterventionHistory | Select-Object -Last 10
        }
        
        # Add performance metrics if requested
        if ($IncludePerformanceMetrics) {
            $response.CurrentPerformanceMetrics = Get-SystemPerformanceMetrics
            $response.HealthMetrics = $agentState.HealthMetrics
        }
        
        return $response
        
    } catch {
        Write-EnhancedStateLog -Message "Failed to get autonomous state: $($_.Exception.Message)" -Level "ERROR"
        throw
    }
}

function Save-AgentState {
    <#
    .SYNOPSIS
    Save agent state to JSON with backup rotation
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [hashtable]$AgentState
    )
    
    try {
        $stateConfig = Get-EnhancedStateConfig
        $agentId = $AgentState.AgentId
        $stateFile = Join-Path $stateConfig.StateDataPath "$agentId.json"
        
        # Create backup of existing state
        if (Test-Path $stateFile) {
            $backupFile = Join-Path $stateConfig.BackupPath "$agentId-$(Get-Date -Format 'yyyyMMdd-HHmmss').json"
            Copy-Item $stateFile $backupFile -ErrorAction SilentlyContinue
        }
        
        # Save current state
        $AgentState | ConvertTo-Json -Depth 10 | Out-File -FilePath $stateFile -Encoding UTF8
        
        Write-EnhancedStateLog -Message "Agent state saved successfully" -Level "DEBUG" -AdditionalData @{ AgentId = $agentId }
        
    } catch {
        Write-EnhancedStateLog -Message "Failed to save agent state: $($_.Exception.Message)" -Level "ERROR"
        throw
    }
}

function Get-AgentState {
    <#
    .SYNOPSIS
    Load agent state from JSON
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$AgentId
    )
    
    try {
        $stateConfig = Get-EnhancedStateConfig
        $stateFile = Join-Path $stateConfig.StateDataPath "$AgentId.json"
        
        if (-not (Test-Path $stateFile)) {
            return $null
        }
        
        $stateJson = Get-Content $stateFile -Raw
        $agentState = ConvertTo-HashTable -Object ($stateJson | ConvertFrom-Json) -Recurse
        
        return $agentState
        
    } catch {
        Write-EnhancedStateLog -Message "Failed to load agent state: $($_.Exception.Message)" -Level "ERROR"
        return $null
    }
}

# Export functions
Export-ModuleMember -Function @(
    'Initialize-EnhancedAutonomousStateTracking',
    'Set-EnhancedAutonomousState',
    'Get-EnhancedAutonomousState',
    'Save-AgentState',
    'Get-AgentState'
)

#endregion
# SIG # Begin signature block
# MIIFzgYJKoZIhvcNAQcCoIIFvzCCBbsCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCAD2LASdE3gXvGc
# y/ikW9sGaBDNLWYsO5/1oIEq/yujoqCCAzAwggMsMIICFKADAgECAhB1HRbZIqgr
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
# MAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIAv7Izvzp9tortawv79mkolI
# vfQnAwmwDIs1/K33ciuIMA0GCSqGSIb3DQEBAQUABIIBABFq1VjWs9r5Mn5OTVpl
# hK280gFlL8ZtCzTHnAOYmNfTclWoS/vsAHSCGJI9G5OZnJGOgUnpMvj+wo+kWV2f
# XCikDbylQAQJhvKI6WSjhEn66e4h9TQaVWBNE4JJhLYCu59fnzeKIUer/Iwq2lzZ
# 9Evy+st8pw6XDa4F/ojC3RhNGMYGFTtYd2jUDjNuNrv1/20QUX0t8GC65zbtAN+L
# FAD23JaTLWDxm/LewCNkceAI2weeIPsrJy1UIZJGNODU3JLMjXjJELARYA+WOGAC
# o1XhRjfgoGpoiVZN7fGmzSUmx4fXJiqVyBRr08Ynre3fnZybpz4XYn+uptbhnWI1
# yxo=
# SIG # End signature block
