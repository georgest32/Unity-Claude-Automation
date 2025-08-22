# AgentCore.psm1
# Core configuration and state management for Unity-Claude Autonomous Agent
# Extracted from main module during refactoring
# Date: 2025-08-18

#region Module Configuration and State

$script:AgentConfig = @{
    # Claude Code CLI Integration
    ClaudeOutputDirectory = Join-Path (Split-Path $PSScriptRoot -Parent) "..\..\ClaudeResponses\Autonomous"
    ConversationHistoryPath = "$env:USERPROFILE\.claude\projects"
    
    # Response Processing
    ResponseTimeoutMs = 30000  # 30 seconds to wait for Claude response
    DebounceMs = 500  # Wait 0.5 seconds after file change before processing (reduced from 2000ms)
    MaxRetries = 3
    
    # Command Execution
    CommandTimeoutMs = 300000  # 5 minutes for command execution
    MaxConcurrentCommands = 3
    
    # Safety and Security
    ConfidenceThreshold = 0.7  # Minimum confidence for autonomous execution
    DryRunMode = $false  # Set to true for testing
    RequireHumanApproval = $false  # Override for sensitive operations
    
    # Conversation Management
    MaxConversationRounds = 10  # Maximum autonomous conversation rounds
    ContextPreservationDepth = 5  # Number of previous interactions to preserve
}

$script:AgentState = @{
    # Monitoring State
    IsMonitoring = $false
    FileWatcher = $null
    LastProcessedFile = ""
    
    # Conversation State
    CurrentConversationId = ""
    ConversationRound = 0
    ConversationContext = @()
    LastClaudeResponse = ""
    
    # Enhanced Day 2 State
    LastResponseClassification = $null
    LastConversationContext = $null
    LastConversationState = $null
    
    # Execution State  
    IsExecutingCommand = $false
    PendingCommands = [System.Collections.Queue]::new()
    ExecutionResults = @()
    
    # Statistics
    TotalConversationRounds = 0
    SuccessfulExecutions = 0
    FailedExecutions = 0
    HumanInterventions = 0
}

#endregion

#region Core Functions

function Initialize-AgentCore {
    <#
    .SYNOPSIS
    Initializes the agent core configuration and state
    
    .DESCRIPTION
    Sets up the core agent configuration, creates necessary directories, and initializes state
    #>
    [CmdletBinding()]
    param()
    
    # Create output directory if it doesn't exist
    if (-not (Test-Path $script:AgentConfig.ClaudeOutputDirectory)) {
        New-Item -ItemType Directory -Path $script:AgentConfig.ClaudeOutputDirectory -Force | Out-Null
    }
    
    # Initialize or reset state
    $script:AgentState.IsMonitoring = $false
    $script:AgentState.ConversationRound = 0
    $script:AgentState.PendingCommands.Clear()
    
    # Return initialization status
    return @{
        Success = $true
        Config = $script:AgentConfig
        State = $script:AgentState
    }
}

function Get-AgentConfig {
    <#
    .SYNOPSIS
    Gets the current agent configuration
    
    .DESCRIPTION
    Returns the current agent configuration settings
    
    .PARAMETER Setting
    Optional specific setting to retrieve
    #>
    [CmdletBinding()]
    param(
        [string]$Setting
    )
    
    if ($Setting) {
        return $script:AgentConfig[$Setting]
    }
    
    return $script:AgentConfig
}

function Set-AgentConfig {
    <#
    .SYNOPSIS
    Updates agent configuration settings
    
    .DESCRIPTION
    Updates one or more agent configuration settings
    
    .PARAMETER Settings
    Hashtable of settings to update
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [hashtable]$Settings
    )
    
    foreach ($key in $Settings.Keys) {
        if ($script:AgentConfig.ContainsKey($key)) {
            $script:AgentConfig[$key] = $Settings[$key]
        } else {
            Write-Warning "Unknown configuration setting: $key"
        }
    }
    
    return $script:AgentConfig
}

function Get-AgentState {
    <#
    .SYNOPSIS
    Gets the current agent state
    
    .DESCRIPTION
    Returns the current agent operational state
    
    .PARAMETER Property
    Optional specific state property to retrieve
    #>
    [CmdletBinding()]
    param(
        [string]$Property
    )
    
    if ($Property) {
        return $script:AgentState[$Property]
    }
    
    return $script:AgentState
}

function Set-AgentState {
    <#
    .SYNOPSIS
    Updates agent state properties
    
    .DESCRIPTION
    Updates one or more agent state properties
    
    .PARAMETER Properties
    Hashtable of properties to update
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [hashtable]$Properties
    )
    
    foreach ($key in $Properties.Keys) {
        if ($script:AgentState.ContainsKey($key)) {
            $script:AgentState[$key] = $Properties[$key]
        } else {
            Write-Warning "Unknown state property: $key"
        }
    }
    
    return $script:AgentState
}

function Reset-AgentState {
    <#
    .SYNOPSIS
    Resets the agent state to defaults
    
    .DESCRIPTION
    Resets all agent state properties to their initial values
    
    .PARAMETER KeepStatistics
    If specified, preserves execution statistics
    #>
    [CmdletBinding()]
    param(
        [switch]$KeepStatistics
    )
    
    # Save statistics if requested
    $stats = $null
    if ($KeepStatistics) {
        $stats = @{
            TotalConversationRounds = $script:AgentState.TotalConversationRounds
            SuccessfulExecutions = $script:AgentState.SuccessfulExecutions
            FailedExecutions = $script:AgentState.FailedExecutions
            HumanInterventions = $script:AgentState.HumanInterventions
        }
    }
    
    # Reset state
    $script:AgentState.IsMonitoring = $false
    $script:AgentState.FileWatcher = $null
    $script:AgentState.LastProcessedFile = ""
    $script:AgentState.CurrentConversationId = ""
    $script:AgentState.ConversationRound = 0
    $script:AgentState.ConversationContext = @()
    $script:AgentState.LastClaudeResponse = ""
    $script:AgentState.LastResponseClassification = $null
    $script:AgentState.LastConversationContext = $null
    $script:AgentState.LastConversationState = $null
    $script:AgentState.IsExecutingCommand = $false
    $script:AgentState.PendingCommands.Clear()
    $script:AgentState.ExecutionResults = @()
    
    # Restore or reset statistics
    if ($stats) {
        foreach ($key in $stats.Keys) {
            $script:AgentState[$key] = $stats[$key]
        }
    } else {
        $script:AgentState.TotalConversationRounds = 0
        $script:AgentState.SuccessfulExecutions = 0
        $script:AgentState.FailedExecutions = 0
        $script:AgentState.HumanInterventions = 0
    }
    
    return $script:AgentState
}

#endregion

# Export module functions
Export-ModuleMember -Function @(
    'Initialize-AgentCore',
    'Get-AgentConfig',
    'Set-AgentConfig',
    'Get-AgentState',
    'Set-AgentState',
    'Reset-AgentState'
) -Variable @(
    'AgentConfig',
    'AgentState'
)
# SIG # Begin signature block
# MIIFqQYJKoZIhvcNAQcCoIIFmjCCBZYCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQU6ab8uWPXB4C48Ay7JfGTNj1M
# /AugggMwMIIDLDCCAhSgAwIBAgIQdR0W2SKoK5VE8JId4ZxrRTANBgkqhkiG9w0B
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
# CQQxFgQUap2jft3d0V++y6/arT2z8HJ8xvQwDQYJKoZIhvcNAQEBBQAEggEAhFcs
# tT8X16TjQW40ixjmKIyaSizhw/PbVy7Nw/QIHrpViXiU22AsQYFnp3+LbI9IDHXv
# v6wDH7hfJ6LlsAjW9u22uTRR3AjzF5kcK/99t7XxclztBm851yqzuUU58FJ4GvvK
# 1Mxk4185LRMdyUCxp/gAcDjb0Tiqy948M9YVGjJftahkR7RqhwbFsq17RJhxbTvg
# xKSmxK2BQiZGICmLlS4Ub5NJOm96VeavLpPvhAMlLDRBsVWFte44WKgthfTynLvV
# wu85HnInTy+yww7WkyBx53zHaq5itdHk9bN4g9mASXcjhewk4xaroTYJ6twx5a7w
# c5k5sv3BHsMb1JDPCw==
# SIG # End signature block
