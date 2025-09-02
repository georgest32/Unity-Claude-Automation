# Unity-Claude-AgentIntegration.psm1
# Integration module for connecting MessageQueue with Unity-Claude-AutonomousAgent

# Import required modules
$messageQueuePath = Join-Path $PSScriptRoot "Unity-Claude-MessageQueue.psm1"
Import-Module $messageQueuePath -Force -Global

# Module-level variables
$script:AgentQueues = @{}
$script:AgentHandlers = @{}
$script:SupervisorConfig = $null

function Initialize-AgentMessageSystem {
    [CmdletBinding()]
    param(
        [string]$AgentName = "Unity-Claude-AutonomousAgent",
        [string]$WatchPath = "C:\Users\georg\AppData\Local\Unity\Editor",
        [hashtable]$AgentConfig = @{}
    )
    
    Write-Debug "[AgentIntegration] Initializing agent message system for: $AgentName"
    
    # Initialize queues for different message types
    $queues = @{
        Tasks = Unity-Claude-MessageQueue\Initialize-MessageQueue -QueueName "$AgentName-Tasks" -MaxMessages 1000
        Responses = Unity-Claude-MessageQueue\Initialize-MessageQueue -QueueName "$AgentName-Responses" -MaxMessages 1000
        Errors = Unity-Claude-MessageQueue\Initialize-MessageQueue -QueueName "$AgentName-Errors" -MaxMessages 500
        State = Unity-Claude-MessageQueue\Initialize-MessageQueue -QueueName "$AgentName-State" -MaxMessages 100
        Control = Unity-Claude-MessageQueue\Initialize-MessageQueue -QueueName "$AgentName-Control" -MaxMessages 50
    }
    
    # Initialize circuit breakers for external services
    Unity-Claude-MessageQueue\Initialize-CircuitBreaker -ServiceName "Unity-Editor" -FailureThreshold 3 -ResetTimeoutSeconds 60
    Unity-Claude-MessageQueue\Initialize-CircuitBreaker -ServiceName "Claude-API" -FailureThreshold 5 -ResetTimeoutSeconds 120
    Unity-Claude-MessageQueue\Initialize-CircuitBreaker -ServiceName "Python-Bridge" -FailureThreshold 3 -ResetTimeoutSeconds 30
    
    # Register FileSystemWatcher for Unity Editor logs
    if (Test-Path $WatchPath) {
        Unity-Claude-MessageQueue\Register-FileSystemWatcher -Path $WatchPath -QueueName "$AgentName-Tasks" `
                                  -Filter "Editor.log" -DebounceMilliseconds 500
        Write-Debug "[AgentIntegration] FileSystemWatcher registered for: $WatchPath"
    }
    
    # Store configuration
    $script:AgentQueues[$AgentName] = $queues
    
    # Register default handlers
    Register-DefaultHandlers -AgentName $AgentName
    
    Write-Debug "[AgentIntegration] Agent message system initialized successfully"
    
    return @{
        AgentName = $AgentName
        Queues = $queues
        WatchPath = $WatchPath
        Config = $AgentConfig
        Initialized = Get-Date
    }
}

function Register-DefaultHandlers {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$AgentName
    )
    
    # Task handler
    Unity-Claude-MessageQueue\Register-MessageHandler -QueueName "$AgentName-Tasks" -Handler {
        param($message)
        
        Write-Debug "[TaskHandler] Processing task: $($message.Id)"
        
        # Route based on message type
        switch ($message.Type) {
            "FileSystemChange" {
                # Unity Editor log changed
                $logContent = Get-Content $message.Content.Path -Tail 100
                
                # Check for compilation errors
                $errors = $logContent | Where-Object { $_ -match "error CS\d+" }
                
                if ($errors) {
                    # Queue error message
                    Unity-Claude-MessageQueue\Add-MessageToQueue -QueueName "$AgentName-Errors" `
                                      -Message @{
                                          Source = "Unity"
                                          Errors = $errors
                                          LogPath = $message.Content.Path
                                      } -MessageType "CompilationError" -Priority 9
                }
            }
            
            "UserRequest" {
                # Process user request
                Write-Debug "[TaskHandler] User request: $($message.Content.Request)"
                
                # Add response to response queue
                Unity-Claude-MessageQueue\Add-MessageToQueue -QueueName "$AgentName-Responses" `
                                  -Message @{
                                      RequestId = $message.Id
                                      Status = "Processing"
                                      StartTime = Get-Date
                                  } -MessageType "RequestAcknowledged" -Priority 7
            }
            
            default {
                Write-Debug "[TaskHandler] Unknown task type: $($message.Type)"
            }
        }
    }
    
    # Error handler
    Unity-Claude-MessageQueue\Register-MessageHandler -QueueName "$AgentName-Errors" -Handler {
        param($message)
        
        Write-Warning "[ErrorHandler] Error detected: $($message.Content.Source)"
        
        # Implement error recovery based on source
        switch ($message.Content.Source) {
            "Unity" {
                # Trigger Unity error recovery workflow
                Write-Debug "[ErrorHandler] Initiating Unity error recovery"
            }
            
            "Claude" {
                # Handle Claude API errors
                Write-Debug "[ErrorHandler] Claude API error, checking circuit breaker"
            }
            
            default {
                Write-Debug "[ErrorHandler] Generic error recovery"
            }
        }
    }
    
    # State handler
    Unity-Claude-MessageQueue\Register-MessageHandler -QueueName "$AgentName-State" -Handler {
        param($message)
        
        Write-Debug "[StateHandler] State update: $($message.Content.State)"
        
        # Update agent state tracking
        if ($script:SupervisorConfig) {
            # Notify supervisor of state change
            Send-SupervisorMessage -MessageType "StateUpdate" -Content $message.Content
        }
    }
}

function Initialize-SupervisorOrchestration {
    [CmdletBinding()]
    param(
        [string[]]$AgentNames = @("AnalysisAgent", "ResearchAgent", "ImplementationAgent"),
        [string]$SupervisorName = "SupervisorAgent"
    )
    
    Write-Debug "[Supervisor] Initializing supervisor orchestration"
    
    # Initialize supervisor queue
    $supervisorQueue = Unity-Claude-MessageQueue\Initialize-MessageQueue -QueueName "$SupervisorName-Control" -MaxMessages 500
    
    # Initialize agent queues
    $agentConfigs = @{}
    foreach ($agentName in $AgentNames) {
        $agentConfigs[$agentName] = @{
            TaskQueue = Unity-Claude-MessageQueue\Initialize-MessageQueue -QueueName "$agentName-Tasks" -MaxMessages 200
            StatusQueue = Unity-Claude-MessageQueue\Initialize-MessageQueue -QueueName "$agentName-Status" -MaxMessages 100
            State = "Idle"
            LastActivity = Get-Date
        }
    }
    
    # Configure supervisor
    $script:SupervisorConfig = @{
        Name = $SupervisorName
        Queue = $supervisorQueue
        Agents = $agentConfigs
        RoutingRules = @()
        Statistics = @{
            TasksAssigned = 0
            TasksCompleted = 0
            Errors = 0
            StartTime = Get-Date
        }
    }
    
    # Register supervisor handler
    Unity-Claude-MessageQueue\Register-MessageHandler -QueueName "$SupervisorName-Control" -Handler {
        param($message)
        
        Write-Debug "[Supervisor] Processing control message: $($message.Type)"
        
        switch ($message.Type) {
            "AssignTask" {
                # Determine best agent for task
                $targetAgent = Select-BestAgent -TaskType $message.Content.TaskType
                
                if ($targetAgent) {
                    # Assign task to agent
                    Unity-Claude-MessageQueue\Add-MessageToQueue -QueueName "$targetAgent-Tasks" `
                                      -Message $message.Content `
                                      -MessageType "TaskAssignment" `
                                      -Priority $message.Priority
                    
                    # Update statistics
                    $script:SupervisorConfig.Statistics.TasksAssigned++
                    
                    # Update agent state
                    $script:SupervisorConfig.Agents[$targetAgent].State = "Working"
                    $script:SupervisorConfig.Agents[$targetAgent].LastActivity = Get-Date
                }
            }
            
            "GetStatus" {
                # Return supervisor status
                return $script:SupervisorConfig.Statistics
            }
            
            "Emergency" {
                # Handle emergency coordination
                Write-Warning "[Supervisor] Emergency coordination triggered"
                
                # Pause all agents
                foreach ($agent in $script:SupervisorConfig.Agents.Keys) {
                    Unity-Claude-MessageQueue\Add-MessageToQueue -QueueName "$agent-Tasks" `
                                      -Message @{ Command = "Pause" } `
                                      -MessageType "Control" `
                                      -Priority 10
                }
            }
        }
    }
    
    Write-Debug "[Supervisor] Orchestration initialized with $($AgentNames.Count) agents"
    
    return $script:SupervisorConfig
}

function Select-BestAgent {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$TaskType
    )
    
    # Simple agent selection logic based on task type and agent state
    $availableAgents = $script:SupervisorConfig.Agents.GetEnumerator() | 
        Where-Object { $_.Value.State -eq "Idle" }
    
    if ($availableAgents) {
        # Select based on task type affinity
        switch ($TaskType) {
            "Analysis" { 
                $preferred = $availableAgents | Where-Object { $_.Key -like "*Analysis*" }
                if ($preferred) { return $preferred[0].Key }
            }
            "Research" {
                $preferred = $availableAgents | Where-Object { $_.Key -like "*Research*" }
                if ($preferred) { return $preferred[0].Key }
            }
            "Implementation" {
                $preferred = $availableAgents | Where-Object { $_.Key -like "*Implementation*" }
                if ($preferred) { return $preferred[0].Key }
            }
        }
        
        # Return any available agent if no preference match
        return $availableAgents[0].Key
    }
    
    # Find least busy agent if none idle
    $leastBusy = $script:SupervisorConfig.Agents.GetEnumerator() | 
        Sort-Object { $_.Value.LastActivity } | 
        Select-Object -First 1
    
    return $leastBusy.Key
}

function Send-SupervisorMessage {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$MessageType,
        
        [Parameter(Mandatory)]
        [object]$Content,
        
        [int]$Priority = 5
    )
    
    if (-not $script:SupervisorConfig) {
        Write-Warning "Supervisor not initialized"
        return
    }
    
    & (Get-Command Add-MessageToQueue -Module Unity-Claude-MessageQueue) -QueueName "$($script:SupervisorConfig.Name)-Control" `
                      -Message $Content `
                      -MessageType $MessageType `
                      -Priority $Priority
}

function Start-AgentOrchestration {
    [CmdletBinding()]
    param(
        [string]$SupervisorName = "SupervisorAgent",
        [switch]$Continuous
    )
    
    Write-Host "Starting agent orchestration..." -ForegroundColor Green
    
    if (-not $script:SupervisorConfig) {
        Initialize-SupervisorOrchestration
    }
    
    # Start supervisor processor
    $supervisorJob = Start-Job -ScriptBlock {
        param($ModulePath, $SupervisorName, $Continuous)
        
        Import-Module $ModulePath -Force
        Start-MessageProcessor -QueueName "$SupervisorName-Control" -Continuous:$Continuous
    } -ArgumentList (Join-Path $PSScriptRoot "Unity-Claude-MessageQueue.psm1"), $SupervisorName, $Continuous
    
    # Start agent processors
    $agentJobs = @()
    foreach ($agent in $script:SupervisorConfig.Agents.Keys) {
        $agentJobs += Start-Job -ScriptBlock {
            param($ModulePath, $AgentName)
            
            Import-Module $ModulePath -Force
            Start-MessageProcessor -QueueName "$AgentName-Tasks"
        } -ArgumentList (Join-Path $PSScriptRoot "Unity-Claude-MessageQueue.psm1"), $agent
    }
    
    Write-Host "Orchestration started with:" -ForegroundColor Cyan
    Write-Host "  - 1 Supervisor ($SupervisorName)" -ForegroundColor Cyan
    Write-Host "  - $($agentJobs.Count) Agents" -ForegroundColor Cyan
    
    return @{
        SupervisorJob = $supervisorJob
        AgentJobs = $agentJobs
        StartTime = Get-Date
    }
}

function Get-OrchestrationStatus {
    [CmdletBinding()]
    param()
    
    if (-not $script:SupervisorConfig) {
        Write-Warning "Orchestration not initialized"
        return $null
    }
    
    $status = @{
        Supervisor = @{
            Name = $script:SupervisorConfig.Name
            Queue = $script:SupervisorConfig.Queue
            Statistics = $script:SupervisorConfig.Statistics
        }
        Agents = @{}
    }
    
    foreach ($agent in $script:SupervisorConfig.Agents.GetEnumerator()) {
        $queueStats = Get-QueueStatistics -QueueName "$($agent.Key)-Tasks"
        $status.Agents[$agent.Key] = @{
            State = $agent.Value.State
            LastActivity = $agent.Value.LastActivity
            QueueStats = $queueStats
        }
    }
    
    return $status
}

# Export functions
Export-ModuleMember -Function @(
    'Initialize-AgentMessageSystem',
    'Initialize-SupervisorOrchestration',
    'Send-SupervisorMessage',
    'Start-AgentOrchestration',
    'Get-OrchestrationStatus',
    'Select-BestAgent'
)
# SIG # Begin signature block
# MIIFzgYJKoZIhvcNAQcCoIIFvzCCBbsCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCDBlFs0alCh3+Ex
# IiyCZdr2J/GQSYQbBdFTCGxv4DJbmqCCAzAwggMsMIICFKADAgECAhB1HRbZIqgr
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
# MAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIAUC+EfiUhL9+TMWtr0niLiU
# a5Xcy8uDUen64wQCgKFVMA0GCSqGSIb3DQEBAQUABIIBAD+DmRjtpX5fFshDcY2S
# 08xHjGtUfyz9AK+cXdot+dZOnkJAusWM+UpYEmSkpru4El58tdCwgFdKSfUl7N1Y
# +Y3RFQQOP3eI8beI5CcZuvANPakYHk4QVgLXoummgMImwlDwJ55VvmDTmdy96HQ4
# Ip4GEtltxeIsgfseBGIoRPSJb+M+AGZ5wPaaBRgIv76fC/FhPuOsqmzMN57lz4UE
# pJdHd8PwklMd+OD2nE86Ce83jUKnKViiwgb+W+qSxelIcUbK9Rs85Bf8VxoSKjSi
# YAPZFGXEXIEXFxr+kL9ZHgVvV3uBGUXi8bU2qyeBNdyzp/fBjOpv1duabaYW6Ezd
# vAk=
# SIG # End signature block
