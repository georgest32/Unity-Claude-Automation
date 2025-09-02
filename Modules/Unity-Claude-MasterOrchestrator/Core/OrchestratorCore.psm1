#Requires -Version 5.1
<#
.SYNOPSIS
    Core configuration and logging functionality for Unity-Claude-MasterOrchestrator.

.DESCRIPTION
    Contains core configuration management, logging functions, and basic utilities
    for the master orchestrator system.

.NOTES
    Part of Unity-Claude-MasterOrchestrator refactored architecture
    Originally from Unity-Claude-MasterOrchestrator.psm1 (lines 1-120)
    Refactoring Date: 2025-08-25
#>

# Module-level variables
$script:OrchestratorConfig = @{
    EnableDebugLogging = $true
    EnableAutonomousMode = $false
    SequentialProcessing = $true
    EventDrivenMode = $true
    MaxConcurrentOperations = 3
    OperationTimeoutMs = 30000
    SafetyValidationEnabled = $true
    LearningIntegrationEnabled = $true
    ConversationRounds = 0
    MaxConversationRounds = 10
}

$script:LogPath = "C:\UnityProjects\Sound-and-Shoal\Unity-Claude-Automation\unity_claude_automation.log"

# Orchestration state management
$script:IntegratedModules = @{}
$script:ActiveOperations = @{}
$script:EventQueue = [System.Collections.Queue]::new()
$script:OperationHistory = [System.Collections.Generic.List[hashtable]]::new()
$script:FeedbackLoopActive = $false

# Define the unified module architecture based on research findings
$script:ModuleArchitecture = @{
    # Core Foundation Modules
    CoreModules = @(
        'Unity-Claude-Core'
        'Unity-Claude-Errors'
        'Unity-Claude-Learning'
        'Unity-Claude-Safety'
    )
    
    # Day 17 New Integration Modules
    IntegrationModules = @(
        'Unity-Claude-ResponseMonitor'
        'Unity-Claude-DecisionEngine'
    )
    
    # Existing Autonomous Agent Modules
    AgentModules = @(
        'Unity-Claude-AutonomousStateTracker-Enhanced'
        'ConversationStateManager'
        'ContextOptimization'
        'IntelligentPromptEngine'
    )
    
    # Command Execution Modules
    ExecutionModules = @(
        'Unity-Claude-FixEngine'
        'SafeCommandExecution'
        'Unity-TestAutomation'
    )
    
    # Communication Modules
    CommunicationModules = @(
        'Unity-Claude-IPC-Bidirectional'
        'CLIAutomation'
    )
    
    # Processing Modules  
    ProcessingModules = @(
        'ResponseParsing'
        'Classification'
        'ContextExtraction'
    )
}

function Write-OrchestratorLog {
    <#
    .SYNOPSIS
    Writes log messages for the orchestrator system.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Message,
        
        [Parameter()]
        [ValidateSet("INFO", "WARN", "ERROR", "DEBUG")]
        [string]$Level = "INFO"
    )
    
    if (-not $script:OrchestratorConfig.EnableDebugLogging -and $Level -eq "DEBUG") {
        return
    }
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logEntry = "[$timestamp] [$Level] [MasterOrchestrator] $Message"
    
    try {
        Add-Content -Path $script:LogPath -Value $logEntry -Encoding UTF8 -ErrorAction SilentlyContinue
    } catch {
        # Silently continue if logging fails
    }
    
    if ($Level -eq "ERROR") {
        Write-Error $Message
    } elseif ($Level -eq "WARN") {
        Write-Warning $Message
    } elseif ($script:OrchestratorConfig.EnableDebugLogging -or $Level -eq "INFO") {
        Write-Host $logEntry -ForegroundColor $(
            switch ($Level) {
                "ERROR" { "Red" }
                "WARN" { "Yellow" }
                "INFO" { "Green" }
                "DEBUG" { "Cyan" }
                default { "White" }
            }
        )
    }
}

function Get-OrchestratorConfig {
    <#
    .SYNOPSIS
    Gets the current orchestrator configuration.
    #>
    return $script:OrchestratorConfig.Clone()
}

function Set-OrchestratorConfig {
    <#
    .SYNOPSIS
    Updates orchestrator configuration settings.
    #>
    [CmdletBinding()]
    param(
        [hashtable]$Config
    )
    
    foreach ($key in $Config.Keys) {
        if ($script:OrchestratorConfig.ContainsKey($key)) {
            $script:OrchestratorConfig[$key] = $Config[$key]
            Write-OrchestratorLog "Updated config: $key = $($Config[$key])" -Level "DEBUG"
        }
    }
}

function Get-ModuleArchitecture {
    <#
    .SYNOPSIS
    Returns the defined module architecture.
    #>
    return $script:ModuleArchitecture
}

function Get-OrchestratorState {
    <#
    .SYNOPSIS
    Gets the current orchestrator state information.
    #>
    return @{
        Config = $script:OrchestratorConfig
        IntegratedModules = $script:IntegratedModules.Keys
        ActiveOperations = $script:ActiveOperations.Keys
        EventQueueSize = $script:EventQueue.Count
        OperationHistoryCount = $script:OperationHistory.Count
        FeedbackLoopActive = $script:FeedbackLoopActive
        LogPath = $script:LogPath
    }
}

Export-ModuleMember -Function @(
    'Write-OrchestratorLog',
    'Get-OrchestratorConfig',
    'Set-OrchestratorConfig', 
    'Get-ModuleArchitecture',
    'Get-OrchestratorState'
) -Variable @(
    'OrchestratorConfig',
    'LogPath',
    'IntegratedModules',
    'ActiveOperations', 
    'EventQueue',
    'OperationHistory',
    'FeedbackLoopActive',
    'ModuleArchitecture'
)

# REFACTORING MARKER: This module was refactored from Unity-Claude-MasterOrchestrator.psm1 on 2025-08-25
# Original file size: 1276 lines
# This component: Core configuration, logging, and state management
# SIG # Begin signature block
# MIIFzgYJKoZIhvcNAQcCoIIFvzCCBbsCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCC9KZG8xv3KDbk0
# wQlPFozltFadfxdocDdMZJkUE+c39qCCAzAwggMsMIICFKADAgECAhB1HRbZIqgr
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
# MAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIE1iGxYsac1FzNslENC3mxnD
# wsdqbZLtAsVlsYTQfK+kMA0GCSqGSIb3DQEBAQUABIIBAHtV6RZOBtNhxQkycUXb
# Nvz0P3XntOyJjO0Riz6587X/deCgAR2dNe9F2l3v8afLa20ZSI4IZpHk3d5fL3Df
# CP8yG6i8/bfVZBze69zFAILNV/j677YUtoB5zoJ6guKyhSyufEO5p3X4fsxH+K3q
# NhC6Cn+l7DTzKrS6Oa2E6MyAEXp73AhxHIawt/95Giyzsv18QZ6YKfUceVA6fhWm
# UkQERk4mK2Ro7JU6GAg7l92Un+uhnMJ0gMtYdjLIVAudLoqCU/pKYEcdh0JY3907
# 2k5ACiYNj25/VE1dXlUGvKjnI92r+K8D3weYveCRGH3BasBloxmXqmePGNJP5jgW
# ZJ4=
# SIG # End signature block
