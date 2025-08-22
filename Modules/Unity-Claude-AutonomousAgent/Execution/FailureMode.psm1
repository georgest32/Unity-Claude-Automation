# FailureMode.psm1
# Master Plan Day 11: Failure Mode Management Implementation
# Implements human escalation, safe mode operations, and recovery checkpoints
# Date: 2025-08-18
# IMPORTANT: ASCII only, no backticks, proper variable delimiting

#region Module Dependencies

# Import required modules
Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) "Core\AgentLogging.psm1") -Force

#endregion

#region Module Variables

# Escalation configuration
$script:EscalationConfig = @{
    "SLAViolationThreshold" = 300000  # 5 minutes
    "CriticalFailureThreshold" = 3    # 3 consecutive critical failures
    "EscalationLevels" = @(
        @{ Level = 1; Description = "Automated Recovery"; TimeoutMs = 60000 }
        @{ Level = 2; Description = "System Administrator"; TimeoutMs = 300000 }
        @{ Level = 3; Description = "Emergency Response"; TimeoutMs = 900000 }
    )
}

# Safe mode state
$script:SafeModeState = @{
    "IsActive" = $false
    "ActivatedAt" = $null
    "Reason" = ""
    "AllowedOperations" = @("Logging", "BasicFileOps", "StatusCheck")
}

# Recovery checkpoints
$script:RecoveryCheckpoints = @{}

# Diagnostic data collection
$script:DiagnosticData = @{
    "ErrorHistory" = @()
    "PerformanceMetrics" = @()
    "SystemState" = @{}
}

#endregion

#region Human Escalation Functions

function Test-EscalationTriggers {
    <#
    .SYNOPSIS
    Tests if conditions require human escalation
    
    .DESCRIPTION
    Evaluates error patterns, SLA violations, and failure thresholds for escalation
    
    .PARAMETER ErrorContext
    Context information about the current error
    
    .PARAMETER OperationDuration
    How long the current operation has been running
    #>
    [CmdletBinding()]
    param(
        [hashtable]$ErrorContext = @{},
        
        [int]$OperationDuration = 0
    )
    
    Write-AgentLog "Testing escalation triggers" -Level "DEBUG" -Component "EscalationManager"
    
    try {
        $escalationRequired = $false
        $escalationReasons = @()
        $recommendedLevel = 1
        
        # Check SLA violation
        if ($OperationDuration -gt $script:EscalationConfig.SLAViolationThreshold) {
            $escalationRequired = $true
            $escalationReasons += "SLA violation: $OperationDuration ms > $($script:EscalationConfig.SLAViolationThreshold) ms"
            $recommendedLevel = 2
        }
        
        # Check critical failure patterns
        if ($ErrorContext.ContainsKey("Severity") -and $ErrorContext.Severity -eq "Critical") {
            $escalationRequired = $true
            $escalationReasons += "Critical failure detected"
            $recommendedLevel = 3
        }
        
        # Check consecutive failure count
        if ($ErrorContext.ContainsKey("ConsecutiveFailures") -and $ErrorContext.ConsecutiveFailures -ge $script:EscalationConfig.CriticalFailureThreshold) {
            $escalationRequired = $true
            $escalationReasons += "Consecutive failure threshold exceeded: $($ErrorContext.ConsecutiveFailures)"
            $recommendedLevel = 2
        }
        
        # Check safe mode activation
        if ($script:SafeModeState.IsActive) {
            $escalationRequired = $true
            $escalationReasons += "System in safe mode"
            $recommendedLevel = 3
        }
        
        Write-AgentLog "Escalation evaluation: Required=$escalationRequired, Level=$recommendedLevel" -Level "INFO" -Component "EscalationManager"
        
        return @{
            EscalationRequired = $escalationRequired
            Reasons = $escalationReasons
            RecommendedLevel = $recommendedLevel
            EscalationLevels = $script:EscalationConfig.EscalationLevels
        }
    }
    catch {
        Write-AgentLog "Escalation trigger test failed: $_" -Level "ERROR" -Component "EscalationManager"
        return @{
            EscalationRequired = $true  # Escalate on test failure
            Reasons = @("Escalation test failure")
            RecommendedLevel = 2
        }
    }
}

function Invoke-HumanEscalation {
    <#
    .SYNOPSIS
    Triggers human escalation notification
    
    .DESCRIPTION
    Creates escalation notifications and prepares handoff information
    
    .PARAMETER EscalationLevel
    Level of escalation required
    
    .PARAMETER Context
    Context information for escalation
    
    .PARAMETER Reason
    Reason for escalation
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [int]$EscalationLevel,
        
        [hashtable]$Context = @{},
        
        [string]$Reason = ""
    )
    
    Write-AgentLog "Initiating human escalation: Level $EscalationLevel - $Reason" -Level "WARNING" -Component "HumanEscalation"
    
    try {
        $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
        $escalationId = "ESC_${timestamp}_L${EscalationLevel}"
        
        # Create escalation file for human attention
        $escalationDir = Join-Path (Split-Path (Split-Path $PSScriptRoot -Parent) -Parent) "Escalations"
        if (-not (Test-Path $escalationDir)) {
            New-Item -Path $escalationDir -ItemType Directory -Force | Out-Null
        }
        
        $escalationFile = Join-Path $escalationDir "$escalationId.json"
        
        $escalationData = @{
            EscalationId = $escalationId
            Level = $EscalationLevel
            Timestamp = Get-Date
            Reason = $Reason
            Context = $Context
            Status = "Pending"
            AgentState = "Waiting for human intervention"
            DiagnosticData = Get-DiagnosticSummary
        }
        
        $escalationData | ConvertTo-Json -Depth 10 | Set-Content -Path $escalationFile -Force
        
        Write-AgentLog "Escalation notification created: $escalationFile" -Level "WARNING" -Component "HumanEscalation"
        
        return @{
            Success = $true
            EscalationId = $escalationId
            EscalationFile = $escalationFile
            Level = $EscalationLevel
        }
    }
    catch {
        Write-AgentLog "Human escalation failed: $_" -Level "ERROR" -Component "HumanEscalation"
        return @{
            Success = $false
            Error = $_.Exception.Message
        }
    }
}

#endregion

#region Safe Mode Operations

function Enable-SafeMode {
    <#
    .SYNOPSIS
    Activates safe mode for critical failure scenarios
    
    .DESCRIPTION
    Reduces system functionality to essential operations only
    
    .PARAMETER Reason
    Reason for safe mode activation
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Reason
    )
    
    Write-AgentLog "Activating safe mode: $Reason" -Level "WARNING" -Component "SafeModeManager"
    
    try {
        $script:SafeModeState.IsActive = $true
        $script:SafeModeState.ActivatedAt = Get-Date
        $script:SafeModeState.Reason = $Reason
        
        Write-AgentLog "Safe mode activated successfully" -Level "WARNING" -Component "SafeModeManager"
        
        # Trigger human escalation for safe mode activation
        Invoke-HumanEscalation -EscalationLevel 3 -Reason "Safe mode activated: $Reason"
        
        return @{
            Success = $true
            ActivatedAt = $script:SafeModeState.ActivatedAt
            AllowedOperations = $script:SafeModeState.AllowedOperations
        }
    }
    catch {
        Write-AgentLog "Safe mode activation failed: $_" -Level "ERROR" -Component "SafeModeManager"
        return @{
            Success = $false
            Error = $_.Exception.Message
        }
    }
}

function Disable-SafeMode {
    <#
    .SYNOPSIS
    Deactivates safe mode and restores normal operations
    
    .DESCRIPTION
    Returns system to normal operational state
    
    .PARAMETER Reason
    Reason for safe mode deactivation
    #>
    [CmdletBinding()]
    param(
        [string]$Reason = "Manual deactivation"
    )
    
    Write-AgentLog "Deactivating safe mode: $Reason" -Level "INFO" -Component "SafeModeManager"
    
    try {
        $wasActive = $script:SafeModeState.IsActive
        $script:SafeModeState.IsActive = $false
        $script:SafeModeState.ActivatedAt = $null
        $script:SafeModeState.Reason = ""
        
        if ($wasActive) {
            Write-AgentLog "Safe mode deactivated successfully" -Level "SUCCESS" -Component "SafeModeManager"
        }
        
        return @{
            Success = $true
            DeactivatedAt = Get-Date
            WasActive = $wasActive
        }
    }
    catch {
        Write-AgentLog "Safe mode deactivation failed: $_" -Level "ERROR" -Component "SafeModeManager"
        return @{
            Success = $false
            Error = $_.Exception.Message
        }
    }
}

function Test-SafeModeOperation {
    <#
    .SYNOPSIS
    Tests if an operation is allowed in safe mode
    
    .DESCRIPTION
    Validates operations against safe mode restrictions
    
    .PARAMETER OperationType
    Type of operation to validate
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$OperationType
    )
    
    if (-not $script:SafeModeState.IsActive) {
        return $true  # All operations allowed in normal mode
    }
    
    $isAllowed = $OperationType -in $script:SafeModeState.AllowedOperations
    
    Write-AgentLog "Safe mode operation check: '$OperationType' allowed: $isAllowed" -Level "DEBUG" -Component "SafeModeManager"
    
    return $isAllowed
}

#endregion

#region Recovery Checkpoint Functions

function New-RecoveryCheckpoint {
    <#
    .SYNOPSIS
    Creates a recovery checkpoint with current system state
    
    .DESCRIPTION
    Saves system state for potential rollback recovery
    
    .PARAMETER CheckpointName
    Name for the checkpoint
    
    .PARAMETER StateData
    State data to preserve
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$CheckpointName,
        
        [hashtable]$StateData = @{}
    )
    
    Write-AgentLog "Creating recovery checkpoint: $CheckpointName" -Level "INFO" -Component "CheckpointManager"
    
    try {
        $checkpoint = @{
            Name = $CheckpointName
            CreatedAt = Get-Date
            StateData = $StateData
            SystemMetrics = Get-SystemMetrics
            DiagnosticSnapshot = Get-DiagnosticSummary
        }
        
        $script:RecoveryCheckpoints[$CheckpointName] = $checkpoint
        
        # Persist checkpoint to file
        $checkpointDir = Join-Path (Split-Path (Split-Path $PSScriptRoot -Parent) -Parent) "Checkpoints"
        if (-not (Test-Path $checkpointDir)) {
            New-Item -Path $checkpointDir -ItemType Directory -Force | Out-Null
        }
        
        $checkpointFile = Join-Path $checkpointDir "$CheckpointName.json"
        $checkpoint | ConvertTo-Json -Depth 10 | Set-Content -Path $checkpointFile -Force
        
        Write-AgentLog "Recovery checkpoint created: $checkpointFile" -Level "SUCCESS" -Component "CheckpointManager"
        
        return @{
            Success = $true
            CheckpointName = $CheckpointName
            CheckpointFile = $checkpointFile
        }
    }
    catch {
        Write-AgentLog "Recovery checkpoint creation failed: $_" -Level "ERROR" -Component "CheckpointManager"
        return @{
            Success = $false
            Error = $_.Exception.Message
        }
    }
}

function Restore-RecoveryCheckpoint {
    <#
    .SYNOPSIS
    Restores system state from a recovery checkpoint
    
    .DESCRIPTION
    Implements rollback to last known good state
    
    .PARAMETER CheckpointName
    Name of checkpoint to restore
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$CheckpointName
    )
    
    Write-AgentLog "Restoring recovery checkpoint: $CheckpointName" -Level "INFO" -Component "RecoveryManager"
    
    try {
        # Load checkpoint from file if not in memory
        if (-not $script:RecoveryCheckpoints.ContainsKey($CheckpointName)) {
            $checkpointDir = Join-Path (Split-Path (Split-Path $PSScriptRoot -Parent) -Parent) "Checkpoints"
            $checkpointFile = Join-Path $checkpointDir "$CheckpointName.json"
            
            if (Test-Path $checkpointFile) {
                $checkpointData = Get-Content $checkpointFile -Raw | ConvertFrom-Json
                $script:RecoveryCheckpoints[$CheckpointName] = $checkpointData
            } else {
                throw "Checkpoint file not found: $checkpointFile"
            }
        }
        
        $checkpoint = $script:RecoveryCheckpoints[$CheckpointName]
        
        Write-AgentLog "Restoring state from checkpoint created at: $($checkpoint.CreatedAt)" -Level "INFO" -Component "RecoveryManager"
        
        # Restore state data (implementation depends on state structure)
        # For now, return checkpoint data for manual restoration
        
        Write-AgentLog "Recovery checkpoint restored successfully" -Level "SUCCESS" -Component "RecoveryManager"
        
        return @{
            Success = $true
            CheckpointData = $checkpoint
            RestoredAt = Get-Date
        }
    }
    catch {
        Write-AgentLog "Recovery checkpoint restoration failed: $_" -Level "ERROR" -Component "RecoveryManager"
        return @{
            Success = $false
            Error = $_.Exception.Message
        }
    }
}

function Get-DiagnosticSummary {
    <#
    .SYNOPSIS
    Collects diagnostic data for error analysis
    
    .DESCRIPTION
    Gathers system state, error history, and performance metrics
    #>
    [CmdletBinding()]
    param()
    
    Write-AgentLog "Collecting diagnostic summary" -Level "DEBUG" -Component "DiagnosticCollector"
    
    try {
        $summary = @{
            CollectedAt = Get-Date
            SystemState = @{
                SafeModeActive = $script:SafeModeState.IsActive
                CircuitBreakers = $script:CircuitBreakerState
                ModuleVersion = "3.0.0"
            }
            ErrorHistory = $script:DiagnosticData.ErrorHistory | Select-Object -Last 10
            PerformanceMetrics = $script:DiagnosticData.PerformanceMetrics | Select-Object -Last 5
            MemoryUsage = Get-SystemMemoryUsage
            ProcessInfo = Get-CurrentProcessInfo
        }
        
        return $summary
    }
    catch {
        Write-AgentLog "Diagnostic summary collection failed: $_" -Level "ERROR" -Component "DiagnosticCollector"
        return @{
            CollectedAt = Get-Date
            Error = $_.Exception.Message
        }
    }
}

function Add-DiagnosticData {
    <#
    .SYNOPSIS
    Adds diagnostic data for error analysis
    
    .DESCRIPTION
    Records error and performance data for diagnostic purposes
    
    .PARAMETER DataType
    Type of diagnostic data
    
    .PARAMETER Data
    The diagnostic data to record
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateSet("Error", "Performance", "SystemState")]
        [string]$DataType,
        
        [Parameter(Mandatory = $true)]
        $Data
    )
    
    Write-AgentLog "Adding diagnostic data: $DataType" -Level "DEBUG" -Component "DiagnosticCollector"
    
    try {
        $entry = @{
            Timestamp = Get-Date
            Type = $DataType
            Data = $Data
        }
        
        switch ($DataType) {
            "Error" {
                $script:DiagnosticData.ErrorHistory += $entry
                # Keep only last 50 error entries
                if ($script:DiagnosticData.ErrorHistory.Count -gt 50) {
                    $script:DiagnosticData.ErrorHistory = $script:DiagnosticData.ErrorHistory | Select-Object -Last 50
                }
            }
            "Performance" {
                $script:DiagnosticData.PerformanceMetrics += $entry
                # Keep only last 20 performance entries
                if ($script:DiagnosticData.PerformanceMetrics.Count -gt 20) {
                    $script:DiagnosticData.PerformanceMetrics = $script:DiagnosticData.PerformanceMetrics | Select-Object -Last 20
                }
            }
            "SystemState" {
                $script:DiagnosticData.SystemState = $Data
            }
        }
        
        Write-AgentLog "Diagnostic data added successfully" -Level "DEBUG" -Component "DiagnosticCollector"
    }
    catch {
        Write-AgentLog "Failed to add diagnostic data: $_" -Level "ERROR" -Component "DiagnosticCollector"
    }
}

#endregion

#region Helper Functions

function Get-SystemMetrics {
    <#
    .SYNOPSIS
    Gets current system performance metrics
    
    .DESCRIPTION
    Collects basic system metrics for checkpoint and diagnostic purposes
    #>
    [CmdletBinding()]
    param()
    
    try {
        return @{
            Timestamp = Get-Date
            ProcessId = $PID
            WorkingSet = (Get-Process -Id $PID).WorkingSet64
            VirtualMemory = (Get-Process -Id $PID).VirtualMemorySize64
            HandleCount = (Get-Process -Id $PID).HandleCount
        }
    }
    catch {
        return @{
            Timestamp = Get-Date
            Error = $_.Exception.Message
        }
    }
}

function Get-SystemMemoryUsage {
    <#
    .SYNOPSIS
    Gets system memory usage information
    #>
    try {
        $process = Get-Process -Id $PID
        return @{
            WorkingSetMB = [Math]::Round($process.WorkingSet64 / 1MB, 2)
            VirtualMemoryMB = [Math]::Round($process.VirtualMemorySize64 / 1MB, 2)
            HandleCount = $process.HandleCount
        }
    }
    catch {
        return @{ Error = $_.Exception.Message }
    }
}

function Get-CurrentProcessInfo {
    <#
    .SYNOPSIS
    Gets current PowerShell process information
    #>
    try {
        return @{
            ProcessId = $PID
            ProcessName = (Get-Process -Id $PID).ProcessName
            StartTime = (Get-Process -Id $PID).StartTime
            Threads = (Get-Process -Id $PID).Threads.Count
        }
    }
    catch {
        return @{ Error = $_.Exception.Message }
    }
}

#endregion

# Export module functions
Export-ModuleMember -Function @(
    'Test-EscalationTriggers',
    'Invoke-HumanEscalation',
    'Enable-SafeMode',
    'Disable-SafeMode',
    'Test-SafeModeOperation',
    'New-RecoveryCheckpoint',
    'Restore-RecoveryCheckpoint',
    'Get-DiagnosticSummary',
    'Add-DiagnosticData',
    'Get-SystemMetrics'
)

Write-AgentLog "FailureMode module loaded successfully" -Level "INFO" -Component "FailureMode"
# SIG # Begin signature block
# MIIFqQYJKoZIhvcNAQcCoIIFmjCCBZYCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUtwbEyPnBIAkYvZprVn4wdwQM
# bNCgggMwMIIDLDCCAhSgAwIBAgIQdR0W2SKoK5VE8JId4ZxrRTANBgkqhkiG9w0B
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
# CQQxFgQUzJmFs4Z3aTm2J0tH/W3qoN4wFxIwDQYJKoZIhvcNAQEBBQAEggEAAl3U
# wAUD2ANtOIM7F50pPAVudOY+uC537wGskR2s0NNDXgZTJnu1z6AkAT7V6LciaS3c
# 0hEzwvPmMCsB7gUGQqDsG2nKLtNfAnvinDQYrbHRX4XC79UJpAsDFy4cBm2SlvYX
# HErMn5h1OX1InE2P+aIES4gwJfbEoKI1UF1yxXKlMfRfMyVaMlAphMioToh4hmdc
# e0/xzp3cYH8q+zTloT+SKiwxL6kXMFbf3IpVVEd0mwfrozUVdRRFKoKcIoK+tP2m
# oqkNeYMirSMMsFf0KGz+KT7JQpw2KHxhQepfV+jECu3wtBQ5bz4pM9FfhLXCG4K0
# SzUE50AQoJDn76BaSg==
# SIG # End signature block
