# StateConfiguration.psm1
# Enhanced autonomous operation configuration and state definitions
# Refactored component from Unity-Claude-AutonomousStateTracker-Enhanced.psm1
# Component: Configuration and state definitions (220 lines)

#region Module Configuration and Enhanced Dependencies

$ErrorActionPreference = "Stop"

Write-Host "[StateConfiguration] Loading autonomous state configuration..." -ForegroundColor Cyan

# Enhanced state tracking configuration based on research findings
$script:EnhancedStateConfig = @{
    # Core state management paths
    StateDataPath = Join-Path $PSScriptRoot "..\..\..\..\SessionData\States"
    CheckpointPath = Join-Path $PSScriptRoot "..\..\..\..\SessionData\Checkpoints"
    HealthDataPath = Join-Path $PSScriptRoot "..\..\..\..\SessionData\Health"
    BackupPath = Join-Path $PSScriptRoot "..\..\..\..\SessionData\Backups"
    
    # State persistence settings (based on research)
    StateHistoryRetention = 2000
    CheckpointIntervalMinutes = 5     # Create checkpoints every 5 minutes
    BackupRetentionDays = 7
    IncrementalCheckpoints = $true    # Research finding: minimize checkpoint cost
    
    # Performance monitoring (Get-Counter integration)
    HealthCheckIntervalSeconds = 15   # More frequent for real-time monitoring
    PerformanceCounterInterval = 30   # Performance counter sampling
    MetricsCollectionIntervalSeconds = 60
    AlertThresholdMinutes = 3         # Faster alerts for autonomous operation
    CriticalThresholdMinutes = 10
    
    # Human intervention triggers (research-based thresholds)
    MaxConsecutiveFailures = 3        # Lower threshold for faster intervention
    MaxCycleTimeMinutes = 8           # Tighter cycle time monitoring
    MinSuccessRate = 0.75             # 75% success rate minimum
    MaxMemoryUsageMB = 800           # Higher threshold for complex operations
    MaxCpuPercentage = 70            # Conservative CPU usage
    
    # Performance counter thresholds (research findings)
    CriticalMemoryPercentage = 85
    CriticalDiskSpaceGB = 5
    NetworkLatencyThresholdMs = 1000
    
    # Circuit breaker enhancements
    CircuitBreakerFailureThreshold = 2  # More sensitive
    CircuitBreakerTimeoutMinutes = 5     # Faster recovery attempts
    CircuitBreakerRecoveryAttempts = 5   # More recovery attempts
    
    # Human intervention configuration
    HumanApprovalTimeout = 300        # 5 minutes for human response
    EscalationEnabled = $true
    NotificationMethods = @("Console", "File", "Event")  # Multiple notification methods
    
    # Logging enhancements
    VerboseLogging = $true
    LogFile = "autonomous_state_tracker_enhanced.log"
    PerformanceLogFile = "performance_metrics.log"
    InterventionLogFile = "human_interventions.log"
}

function Get-EnhancedStateConfig {
    <#
    .SYNOPSIS
    Get the enhanced state configuration
    #>
    return $script:EnhancedStateConfig
}

function Initialize-StateDirectories {
    <#
    .SYNOPSIS
    Ensure all required state directories exist
    #>
    [CmdletBinding()]
    param()
    
    # Ensure all directories exist
    foreach ($path in @($script:EnhancedStateConfig.StateDataPath, $script:EnhancedStateConfig.CheckpointPath, 
                       $script:EnhancedStateConfig.HealthDataPath, $script:EnhancedStateConfig.BackupPath)) {
        if (-not (Test-Path $path)) {
            New-Item -Path $path -ItemType Directory -Force | Out-Null
        }
    }
}

# Enhanced autonomous operation states (building on Day 14 implementation)
$script:EnhancedAutonomousStates = @{
    "Idle" = @{
        Description = "Agent is idle, awaiting triggers or initialization"
        AllowedTransitions = @("Initializing", "Stopped", "Error")
        IsOperational = $false
        RequiresMonitoring = $false
        HumanInterventionRequired = $false
        HealthCheckLevel = "Minimal"
    }
    "Initializing" = @{
        Description = "Agent is initializing components and performing startup checks"
        AllowedTransitions = @("Active", "Error", "Stopped")
        IsOperational = $false
        RequiresMonitoring = $true
        HumanInterventionRequired = $false
        HealthCheckLevel = "Standard"
    }
    "Active" = @{
        Description = "Agent is actively managing autonomous feedback loops"
        AllowedTransitions = @("Monitoring", "Processing", "Paused", "Error", "Stopped")
        IsOperational = $true
        RequiresMonitoring = $true
        HumanInterventionRequired = $false
        HealthCheckLevel = "Comprehensive"
    }
    "Monitoring" = @{
        Description = "Agent is monitoring Claude responses and system state"
        AllowedTransitions = @("Processing", "Active", "Paused", "Error", "Stopped")
        IsOperational = $true
        RequiresMonitoring = $true
        HumanInterventionRequired = $false
        HealthCheckLevel = "Comprehensive"
    }
    "Processing" = @{
        Description = "Agent is processing responses and executing safe commands"
        AllowedTransitions = @("Generating", "Active", "Error", "Stopped", "HumanApprovalRequired")
        IsOperational = $true
        RequiresMonitoring = $true
        HumanInterventionRequired = $false
        HealthCheckLevel = "Intensive"
    }
    "Generating" = @{
        Description = "Agent is generating intelligent follow-up prompts"
        AllowedTransitions = @("Submitting", "Active", "Error", "Stopped")
        IsOperational = $true
        RequiresMonitoring = $true
        HumanInterventionRequired = $false
        HealthCheckLevel = "Standard"
    }
    "Submitting" = @{
        Description = "Agent is submitting prompts to Claude Code CLI"
        AllowedTransitions = @("Monitoring", "Active", "Error", "Stopped")
        IsOperational = $true
        RequiresMonitoring = $true
        HumanInterventionRequired = $false
        HealthCheckLevel = "Standard"
    }
    "Paused" = @{
        Description = "Agent is paused, awaiting human intervention"
        AllowedTransitions = @("Active", "Stopped", "Error")
        IsOperational = $false
        RequiresMonitoring = $true
        HumanInterventionRequired = $true
        HealthCheckLevel = "Minimal"
    }
    "HumanApprovalRequired" = @{
        Description = "Agent requires human approval for high-impact operations"
        AllowedTransitions = @("Processing", "Active", "Paused", "Error", "Stopped")
        IsOperational = $false
        RequiresMonitoring = $true
        HumanInterventionRequired = $true
        HealthCheckLevel = "Standard"
    }
    "Error" = @{
        Description = "Agent encountered an error and requires attention"
        AllowedTransitions = @("Recovering", "Stopped", "Idle", "HumanApprovalRequired")
        IsOperational = $false
        RequiresMonitoring = $true
        HumanInterventionRequired = $false
        HealthCheckLevel = "Diagnostic"
    }
    "Recovering" = @{
        Description = "Agent is attempting autonomous recovery from error state"
        AllowedTransitions = @("Active", "Error", "Stopped", "HumanApprovalRequired")
        IsOperational = $false
        RequiresMonitoring = $true
        HumanInterventionRequired = $false
        HealthCheckLevel = "Intensive"
    }
    "CircuitBreakerOpen" = @{
        Description = "Circuit breaker activated due to repeated failures"
        AllowedTransitions = @("Recovering", "Stopped", "HumanApprovalRequired")
        IsOperational = $false
        RequiresMonitoring = $true
        HumanInterventionRequired = $true
        HealthCheckLevel = "Diagnostic"
    }
    "Stopped" = @{
        Description = "Agent has been safely stopped"
        AllowedTransitions = @("Idle", "Initializing")
        IsOperational = $false
        RequiresMonitoring = $false
        HumanInterventionRequired = $false
        HealthCheckLevel = "None"
    }
}

function Get-EnhancedAutonomousStates {
    <#
    .SYNOPSIS
    Get the enhanced autonomous states configuration
    #>
    return $script:EnhancedAutonomousStates
}

# Performance counter definitions (based on research findings)
$script:PerformanceCounters = @{
    "CPU" = @{
        CounterPath = "\Processor(_Total)\% Processor Time"
        ThresholdWarning = 60
        ThresholdCritical = 80
        Unit = "Percentage"
    }
    "Memory" = @{
        CounterPath = "\Memory\% Committed Bytes In Use"
        ThresholdWarning = 70
        ThresholdCritical = 85
        Unit = "Percentage"
    }
    "DiskSpace" = @{
        CounterPath = "\LogicalDisk(C:)\% Free Space"
        ThresholdWarning = 15
        ThresholdCritical = 10
        Unit = "Percentage"
    }
    "ProcessCount" = @{
        CounterPath = "\System\Processes"
        ThresholdWarning = 200
        ThresholdCritical = 300
        Unit = "Count"
    }
}

function Get-PerformanceCounters {
    <#
    .SYNOPSIS
    Get the performance counters configuration
    #>
    return $script:PerformanceCounters
}

# Initialize directories on module load
Initialize-StateDirectories

# Export functions
Export-ModuleMember -Function @(
    'Get-EnhancedStateConfig',
    'Initialize-StateDirectories', 
    'Get-EnhancedAutonomousStates',
    'Get-PerformanceCounters'
)

#endregion
# SIG # Begin signature block
# MIIFzgYJKoZIhvcNAQcCoIIFvzCCBbsCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCDWPj83XG3MUCkJ
# f/JQ33lliTJ/rGkBzefWBzw6S8x1aKCCAzAwggMsMIICFKADAgECAhB1HRbZIqgr
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
# MAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIPapwsIxALrnwegKcCQ8oCw7
# SrzDrZgk4K+7528JBa5cMA0GCSqGSIb3DQEBAQUABIIBAFXq7UchqtpZQ0Cii7PY
# B0LCZ8rYuAo1UMy+iQrCBxspsgGnEoafodTnejswoz9fqiT9o0AHiDwRbuFbdY7X
# 6RsaRWw/Onz2GJPq4m6C2+Rt9GyZVsmqrwUPgTlGgtVEGZhGcLx3oTBSQreV3Y8k
# N0asO5iX+XAiNZ2jrLrlF1+3i+F7ScEmRNSr1RL+MSvohbtGb8OmQPZfaY6xfueX
# CyiWqTWAQz8x11OutOfhJzlMcHGCOBeVntXgVDssCm6a0ja6z2hwy+mhqSCmmno7
# R2CdDBkUTUwB0AWtaCy4coYj/vlEUYyAAwnTr4Lnz9QEFr+/Rixh8PPuI1orJySI
# O9w=
# SIG # End signature block
