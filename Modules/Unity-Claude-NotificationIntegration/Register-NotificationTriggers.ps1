function Register-NotificationTriggers {
    <#
    .SYNOPSIS
    Registers event-driven notification triggers throughout the Unity-Claude autonomous workflow
    
    .DESCRIPTION
    Implements comprehensive event-driven notification triggers using Register-ObjectEvent patterns
    integrated with the Bootstrap Orchestrator system. Supports:
    - Unity compilation monitoring via FileSystemWatcher
    - Claude submission status monitoring
    - Error resolution tracking
    - System health monitoring integration
    - Autonomous agent status monitoring
    
    .PARAMETER Configuration
    Notification configuration object from Get-NotificationConfiguration
    
    .PARAMETER TriggerTypes
    Array of trigger types to register (UnityCompilation, ClaudeSubmission, ErrorResolution, SystemHealth, AutonomousAgent, All)
    
    .EXAMPLE
    Register-NotificationTriggers -Configuration $config
    
    .EXAMPLE
    Register-NotificationTriggers -Configuration $config -TriggerTypes @("UnityCompilation", "SystemHealth")
    #>
    [CmdletBinding()]
    param(
        [hashtable]$Configuration,
        [ValidateSet("UnityCompilation", "ClaudeSubmission", "ErrorResolution", "SystemHealth", "AutonomousAgent", "All")]
        [string[]]$TriggerTypes = @("All")
    )
    
    Write-SystemStatusLog "Registering notification triggers: $($TriggerTypes -join ', ')" -Level 'INFO'
    
    try {
        if (-not $Configuration) {
            $Configuration = Get-NotificationConfiguration
        }
        
        # Get trigger configuration
        $triggerConfig = $Configuration.NotificationTriggers
        if (-not $triggerConfig) {
            Write-SystemStatusLog "No notification trigger configuration found" -Level 'WARN'
            return
        }
        
        # Determine which triggers to register
        $triggersToRegister = @()
        if ($TriggerTypes -contains "All") {
            $triggersToRegister = @("UnityCompilation", "ClaudeSubmission", "ErrorResolution", "SystemHealth", "AutonomousAgent")
        } else {
            $triggersToRegister = $TriggerTypes
        }
        
        $registeredTriggers = @()
        
        foreach ($triggerType in $triggersToRegister) {
            try {
                switch ($triggerType) {
                    "UnityCompilation" {
                        if ($triggerConfig.UnityCompilation) {
                            $result = Register-UnityCompilationTrigger -Configuration $Configuration
                            if ($result) { $registeredTriggers += $result }
                        }
                    }
                    "ClaudeSubmission" {
                        if ($triggerConfig.ClaudeSubmission) {
                            $result = Register-ClaudeSubmissionTrigger -Configuration $Configuration
                            if ($result) { $registeredTriggers += $result }
                        }
                    }
                    "ErrorResolution" {
                        if ($triggerConfig.FixApplication) {
                            $result = Register-ErrorResolutionTrigger -Configuration $Configuration
                            if ($result) { $registeredTriggers += $result }
                        }
                    }
                    "SystemHealth" {
                        if ($triggerConfig.SystemHealth) {
                            $result = Register-SystemHealthTrigger -Configuration $Configuration
                            if ($result) { $registeredTriggers += $result }
                        }
                    }
                    "AutonomousAgent" {
                        if ($triggerConfig.AutonomousAgent) {
                            $result = Register-AutonomousAgentTrigger -Configuration $Configuration
                            if ($result) { $registeredTriggers += $result }
                        }
                    }
                }
            } catch {
                Write-SystemStatusLog "Failed to register $triggerType trigger: $($_.Exception.Message)" -Level 'ERROR'
            }
        }
        
        Write-SystemStatusLog "Successfully registered $($registeredTriggers.Count) notification triggers" -Level 'INFO'
        return $registeredTriggers
        
    } catch {
        $errorMessage = "Failed to register notification triggers: $($_.Exception.Message)"
        Write-SystemStatusLog $errorMessage -Level 'ERROR'
        throw $_
    }
}

function Register-UnityCompilationTrigger {
    <#
    .SYNOPSIS
    Registers Unity compilation monitoring triggers using FileSystemWatcher
    #>
    [CmdletBinding()]
    param([hashtable]$Configuration)
    
    Write-SystemStatusLog "Registering Unity compilation notification triggers" -Level 'DEBUG'
    
    try {
        $triggerConfig = $Configuration.NotificationTriggers.UnityCompilation
        $registeredEvents = @()
        
        # Monitor Unity console log for compilation results
        $unityLogPath = "C:\Users\georg\AppData\Local\Unity\Editor\Editor.log"
        if (Test-Path $unityLogPath) {
            $logDir = Split-Path $unityLogPath -Parent
            $logFileName = Split-Path $unityLogPath -Leaf
            
            # Create FileSystemWatcher for Unity log changes
            $unityLogWatcher = New-Object System.IO.FileSystemWatcher
            $unityLogWatcher.Path = $logDir
            $unityLogWatcher.Filter = $logFileName
            $unityLogWatcher.NotifyFilter = [System.IO.NotifyFilters]::LastWrite
            $unityLogWatcher.EnableRaisingEvents = $true
            
            # Register event handler for Unity log changes
            $unityLogAction = {
                param($sender, $eventArgs)
                
                try {
                    # Debounce mechanism
                    $debounceKey = "UnityLogChange_$(Get-Date -Format 'yyyyMMddHHmmss')"
                    if ($script:LastUnityLogEvent -and ((Get-Date) - $script:LastUnityLogEvent).TotalSeconds -lt $using:triggerConfig.DebounceSeconds) {
                        return
                    }
                    $script:LastUnityLogEvent = Get-Date
                    
                    # Read recent log entries to detect compilation status
                    $logContent = Get-Content $eventArgs.FullPath -Tail 50 -ErrorAction SilentlyContinue
                    if ($logContent) {
                        $compilationMessages = $logContent | Where-Object { 
                            $_ -match "Compilation finished|CompilerMessages|Assembly-CSharp|UnityEngine.Debug" 
                        }
                        
                        $hasErrors = $logContent | Where-Object { $_ -match "error CS\d{4}|compilation failed" }
                        $hasWarnings = $logContent | Where-Object { $_ -match "warning CS\d{4}" }
                        $compilationSuccess = $logContent | Where-Object { $_ -match "Compilation finished successfully|Refresh completed" }
                        
                        $notificationData = @{
                            Source = "UnityCompilation"
                            Timestamp = Get-Date
                            LogFile = $eventArgs.FullPath
                            HasErrors = ($hasErrors.Count -gt 0)
                            HasWarnings = ($hasWarnings.Count -gt 0)
                            CompilationSuccess = ($compilationSuccess.Count -gt 0)
                            ErrorCount = $hasErrors.Count
                            WarningCount = $hasWarnings.Count
                        }
                        
                        # Trigger notifications based on configuration
                        if ($notificationData.HasErrors -and $using:triggerConfig.TriggerOnError) {
                            Send-UnityErrorNotificationEvent -NotificationData $notificationData -Configuration $using:Configuration
                        }
                        
                        if ($notificationData.HasWarnings -and $using:triggerConfig.TriggerOnWarning) {
                            Send-UnityWarningNotification -NotificationData $notificationData -Configuration $using:Configuration
                        }
                        
                        if ($notificationData.CompilationSuccess -and $using:triggerConfig.TriggerOnSuccess) {
                            Send-UnitySuccessNotification -NotificationData $notificationData -Configuration $using:Configuration
                        }
                    }
                } catch {
                    Write-SystemStatusLog "Error in Unity compilation trigger: $($_.Exception.Message)" -Level 'ERROR'
                }
            }
            
            $unityLogEvent = Register-ObjectEvent -InputObject $unityLogWatcher -EventName "Changed" -Action $unityLogAction -SourceIdentifier "UnityCompilationMonitor"
            $registeredEvents += @{
                Type = "UnityCompilation"
                SourceIdentifier = "UnityCompilationMonitor"
                EventRegistration = $unityLogEvent
                FileWatcher = $unityLogWatcher
            }
            
            Write-SystemStatusLog "Unity compilation trigger registered for $unityLogPath" -Level 'DEBUG'
        }
        
        # Monitor current_errors.json for exported Unity errors
        $currentErrorsPath = Join-Path $PSScriptRoot "..\..\current_errors.json"
        if (Test-Path $currentErrorsPath) {
            $errorDir = Split-Path $currentErrorsPath -Parent
            $errorFileName = Split-Path $currentErrorsPath -Leaf
            
            $errorWatcher = New-Object System.IO.FileSystemWatcher
            $errorWatcher.Path = $errorDir
            $errorWatcher.Filter = $errorFileName
            $errorWatcher.NotifyFilter = [System.IO.NotifyFilters]::LastWrite
            $errorWatcher.EnableRaisingEvents = $true
            
            $errorAction = {
                param($sender, $eventArgs)
                
                try {
                    # Debounce mechanism
                    if ($script:LastErrorFileEvent -and ((Get-Date) - $script:LastErrorFileEvent).TotalSeconds -lt $using:triggerConfig.DebounceSeconds) {
                        return
                    }
                    $script:LastErrorFileEvent = Get-Date
                    
                    # Read and parse error file
                    $errorContent = Get-Content $eventArgs.FullPath -Raw -ErrorAction SilentlyContinue
                    if ($errorContent) {
                        try {
                            $errorData = $errorContent | ConvertFrom-Json
                            
                            $notificationData = @{
                                Source = "UnityErrorExport"
                                Timestamp = Get-Date
                                ErrorFile = $eventArgs.FullPath
                                ErrorCount = $errorData.Count
                                Errors = $errorData
                            }
                            
                            if ($notificationData.ErrorCount -gt 0 -and $using:triggerConfig.TriggerOnError) {
                                Send-UnityErrorNotificationEvent -NotificationData $notificationData -Configuration $using:Configuration
                            }
                        } catch {
                            Write-SystemStatusLog "Failed to parse Unity error file: $($_.Exception.Message)" -Level 'WARN'
                        }
                    }
                } catch {
                    Write-SystemStatusLog "Error in Unity error file trigger: $($_.Exception.Message)" -Level 'ERROR'
                }
            }
            
            $errorEvent = Register-ObjectEvent -InputObject $errorWatcher -EventName "Changed" -Action $errorAction -SourceIdentifier "UnityErrorFileMonitor"
            $registeredEvents += @{
                Type = "UnityErrorFile"
                SourceIdentifier = "UnityErrorFileMonitor"
                EventRegistration = $errorEvent
                FileWatcher = $errorWatcher
            }
            
            Write-SystemStatusLog "Unity error file trigger registered for $currentErrorsPath" -Level 'DEBUG'
        }
        
        return $registeredEvents
        
    } catch {
        Write-SystemStatusLog "Failed to register Unity compilation trigger: $($_.Exception.Message)" -Level 'ERROR'
        throw $_
    }
}

function Register-ClaudeSubmissionTrigger {
    <#
    .SYNOPSIS
    Registers Claude submission monitoring triggers using FileSystemWatcher for response files
    #>
    [CmdletBinding()]
    param([hashtable]$Configuration)
    
    Write-SystemStatusLog "Registering Claude submission notification triggers" -Level 'DEBUG'
    
    try {
        $triggerConfig = $Configuration.NotificationTriggers.ClaudeSubmission
        $registeredEvents = @()
        
        # Monitor Claude response directory
        $responseDir = Join-Path $PSScriptRoot "..\..\ClaudeResponses\Autonomous"
        if (Test-Path $responseDir) {
            $responseWatcher = New-Object System.IO.FileSystemWatcher
            $responseWatcher.Path = $responseDir
            $responseWatcher.Filter = "*.json"
            $responseWatcher.NotifyFilter = [System.IO.NotifyFilters]::Created -bor [System.IO.NotifyFilters]::LastWrite
            $responseWatcher.EnableRaisingEvents = $true
            
            $responseAction = {
                param($sender, $eventArgs)
                
                try {
                    # Debounce mechanism
                    if ($script:LastClaudeResponseEvent -and ((Get-Date) - $script:LastClaudeResponseEvent).TotalSeconds -lt $using:triggerConfig.DebounceSeconds) {
                        return
                    }
                    $script:LastClaudeResponseEvent = Get-Date
                    
                    # Analyze Claude response file
                    $responseContent = Get-Content $eventArgs.FullPath -Raw -ErrorAction SilentlyContinue
                    if ($responseContent) {
                        try {
                            $responseData = $responseContent | ConvertFrom-Json
                            
                            $notificationData = @{
                                Source = "ClaudeSubmission"
                                Timestamp = Get-Date
                                ResponseFile = $eventArgs.FullPath
                                ResponseType = $eventArgs.ChangeType
                                HasContent = ($responseContent.Length -gt 0)
                                Success = $true  # Default to success if file created
                            }
                            
                            # Check for Claude submission success/failure indicators
                            if ($responseContent -match "error|failed|rate limit|timeout") {
                                $notificationData.Success = $false
                                
                                if ($using:triggerConfig.TriggerOnFailure) {
                                    Send-ClaudeSubmissionNotificationEvent -NotificationData $notificationData -Configuration $using:Configuration
                                }
                            } elseif ($responseContent -match "RECOMMENDATION|success|completed") {
                                $notificationData.Success = $true
                                
                                if ($using:triggerConfig.TriggerOnSuccess) {
                                    Send-ClaudeSubmissionNotificationEvent -NotificationData $notificationData -Configuration $using:Configuration
                                }
                            }
                            
                            # Check for rate limiting
                            if ($responseContent -match "rate limit|429|too many requests") {
                                if ($using:triggerConfig.TriggerOnRateLimit) {
                                    Send-ClaudeRateLimitNotification -NotificationData $notificationData -Configuration $using:Configuration
                                }
                            }
                        } catch {
                            Write-SystemStatusLog "Failed to parse Claude response file: $($_.Exception.Message)" -Level 'WARN'
                        }
                    }
                } catch {
                    Write-SystemStatusLog "Error in Claude submission trigger: $($_.Exception.Message)" -Level 'ERROR'
                }
            }
            
            $responseEvent = Register-ObjectEvent -InputObject $responseWatcher -EventName "Created" -Action $responseAction -SourceIdentifier "ClaudeResponseMonitor"
            $registeredEvents += @{
                Type = "ClaudeSubmission"
                SourceIdentifier = "ClaudeResponseMonitor"
                EventRegistration = $responseEvent
                FileWatcher = $responseWatcher
            }
            
            Write-SystemStatusLog "Claude submission trigger registered for $responseDir" -Level 'DEBUG'
        }
        
        return $registeredEvents
        
    } catch {
        Write-SystemStatusLog "Failed to register Claude submission trigger: $($_.Exception.Message)" -Level 'ERROR'
        throw $_
    }
}

function Register-ErrorResolutionTrigger {
    <#
    .SYNOPSIS
    Registers error resolution monitoring triggers for fix application tracking
    #>
    [CmdletBinding()]
    param([hashtable]$Configuration)
    
    Write-SystemStatusLog "Registering error resolution notification triggers" -Level 'DEBUG'
    
    try {
        $triggerConfig = $Configuration.NotificationTriggers.FixApplication
        $registeredEvents = @()
        
        # Monitor fix application results via log file analysis
        $logFile = ".\unity_claude_automation.log"
        if (Test-Path $logFile) {
            $logDir = Split-Path $logFile -Parent
            $logFileName = Split-Path $logFile -Leaf
            
            $logWatcher = New-Object System.IO.FileSystemWatcher
            $logWatcher.Path = if ($logDir) { $logDir } else { "." }
            $logWatcher.Filter = $logFileName
            $logWatcher.NotifyFilter = [System.IO.NotifyFilters]::LastWrite
            $logWatcher.EnableRaisingEvents = $true
            
            $logAction = {
                param($sender, $eventArgs)
                
                try {
                    # Debounce mechanism
                    if ($script:LastFixApplicationEvent -and ((Get-Date) - $script:LastFixApplicationEvent).TotalSeconds -lt $using:triggerConfig.DebounceSeconds) {
                        return
                    }
                    $script:LastFixApplicationEvent = Get-Date
                    
                    # Read recent log entries for fix application events
                    $logContent = Get-Content $eventArgs.FullPath -Tail 20 -ErrorAction SilentlyContinue
                    if ($logContent) {
                        $fixSuccessEvents = $logContent | Where-Object { $_ -match "fix applied successfully|compilation passed|error resolved" }
                        $fixFailureEvents = $logContent | Where-Object { $_ -match "fix failed|compilation failed|error persists" }
                        $fixValidationEvents = $logContent | Where-Object { $_ -match "fix validation|post-fix verification" }
                        
                        if ($fixSuccessEvents.Count -gt 0 -and $using:triggerConfig.TriggerOnSuccess) {
                            $notificationData = @{
                                Source = "ErrorResolution"
                                Timestamp = Get-Date
                                Type = "Success"
                                Message = $fixSuccessEvents[-1]
                                LogFile = $eventArgs.FullPath
                            }
                            Send-ErrorResolutionNotification -NotificationData $notificationData -Configuration $using:Configuration
                        }
                        
                        if ($fixFailureEvents.Count -gt 0 -and $using:triggerConfig.TriggerOnFailure) {
                            $notificationData = @{
                                Source = "ErrorResolution"
                                Timestamp = Get-Date
                                Type = "Failure"
                                Message = $fixFailureEvents[-1]
                                LogFile = $eventArgs.FullPath
                            }
                            Send-ErrorResolutionNotification -NotificationData $notificationData -Configuration $using:Configuration
                        }
                        
                        if ($fixValidationEvents.Count -gt 0 -and $using:triggerConfig.TriggerOnValidation) {
                            $notificationData = @{
                                Source = "ErrorResolution"
                                Timestamp = Get-Date
                                Type = "Validation"
                                Message = $fixValidationEvents[-1]
                                LogFile = $eventArgs.FullPath
                            }
                            Send-ErrorResolutionNotification -NotificationData $notificationData -Configuration $using:Configuration
                        }
                    }
                } catch {
                    Write-SystemStatusLog "Error in error resolution trigger: $($_.Exception.Message)" -Level 'ERROR'
                }
            }
            
            $logEvent = Register-ObjectEvent -InputObject $logWatcher -EventName "Changed" -Action $logAction -SourceIdentifier "ErrorResolutionMonitor"
            $registeredEvents += @{
                Type = "ErrorResolution"
                SourceIdentifier = "ErrorResolutionMonitor"
                EventRegistration = $logEvent
                FileWatcher = $logWatcher
            }
            
            Write-SystemStatusLog "Error resolution trigger registered for $logFile" -Level 'DEBUG'
        }
        
        return $registeredEvents
        
    } catch {
        Write-SystemStatusLog "Failed to register error resolution trigger: $($_.Exception.Message)" -Level 'ERROR'
        throw $_
    }
}

function Register-SystemHealthTrigger {
    <#
    .SYNOPSIS
    Registers system health monitoring triggers using SystemStatus integration
    #>
    [CmdletBinding()]
    param([hashtable]$Configuration)
    
    Write-SystemStatusLog "Registering system health notification triggers" -Level 'DEBUG'
    
    try {
        $triggerConfig = $Configuration.NotificationTriggers.SystemHealth
        $registeredEvents = @()
        
        # Create a timer for periodic health checks
        $healthTimer = New-Object System.Timers.Timer
        $healthTimer.Interval = 60000  # 1 minute
        $healthTimer.AutoReset = $true
        $healthTimer.Enabled = $true
        
        $healthAction = {
            try {
                # Perform system health check
                $systemHealth = Test-CriticalSubsystemHealth -ErrorAction SilentlyContinue
                if ($systemHealth) {
                    $criticalIssues = $systemHealth | Where-Object { $_.Status -eq "Critical" -or $_.Status -eq "Error" }
                    $warningIssues = $systemHealth | Where-Object { $_.Status -eq "Warning" -or $_.Status -eq "Degraded" }
                    $recoveredIssues = $systemHealth | Where-Object { $_.Status -eq "Recovered" }
                    
                    if ($criticalIssues.Count -gt 0 -and $using:triggerConfig.TriggerOnCritical) {
                        $notificationData = @{
                            Source = "SystemHealth"
                            Timestamp = Get-Date
                            Type = "Critical"
                            Issues = $criticalIssues
                            Count = $criticalIssues.Count
                        }
                        Send-SystemHealthNotification -NotificationData $notificationData -Configuration $using:Configuration
                    }
                    
                    if ($warningIssues.Count -gt 0 -and $using:triggerConfig.TriggerOnWarning) {
                        $notificationData = @{
                            Source = "SystemHealth"
                            Timestamp = Get-Date
                            Type = "Warning"
                            Issues = $warningIssues
                            Count = $warningIssues.Count
                        }
                        Send-SystemHealthNotification -NotificationData $notificationData -Configuration $using:Configuration
                    }
                    
                    if ($recoveredIssues.Count -gt 0 -and $using:triggerConfig.TriggerOnRecovery) {
                        $notificationData = @{
                            Source = "SystemHealth"
                            Timestamp = Get-Date
                            Type = "Recovery"
                            Issues = $recoveredIssues
                            Count = $recoveredIssues.Count
                        }
                        Send-SystemHealthNotification -NotificationData $notificationData -Configuration $using:Configuration
                    }
                }
            } catch {
                Write-SystemStatusLog "Error in system health trigger: $($_.Exception.Message)" -Level 'ERROR'
            }
        }
        
        $healthEvent = Register-ObjectEvent -InputObject $healthTimer -EventName "Elapsed" -Action $healthAction -SourceIdentifier "SystemHealthMonitor"
        $registeredEvents += @{
            Type = "SystemHealth"
            SourceIdentifier = "SystemHealthMonitor"
            EventRegistration = $healthEvent
            Timer = $healthTimer
        }
        
        Write-SystemStatusLog "System health trigger registered with 60-second interval" -Level 'DEBUG'
        
        return $registeredEvents
        
    } catch {
        Write-SystemStatusLog "Failed to register system health trigger: $($_.Exception.Message)" -Level 'ERROR'
        throw $_
    }
}

function Register-AutonomousAgentTrigger {
    <#
    .SYNOPSIS
    Registers autonomous agent monitoring triggers for agent status changes
    #>
    [CmdletBinding()]
    param([hashtable]$Configuration)
    
    Write-SystemStatusLog "Registering autonomous agent notification triggers" -Level 'DEBUG'
    
    try {
        $triggerConfig = $Configuration.NotificationTriggers.AutonomousAgent
        $registeredEvents = @()
        
        # Monitor autonomous agent status via SystemStatus
        $agentTimer = New-Object System.Timers.Timer
        $agentTimer.Interval = 30000  # 30 seconds
        $agentTimer.AutoReset = $true
        $agentTimer.Enabled = $true
        
        $agentAction = {
            try {
                # Check autonomous agent status
                $agentStatus = Test-AutonomousAgentStatus -ErrorAction SilentlyContinue
                if ($agentStatus) {
                    # Track status changes (this would need persistent state)
                    $currentStatus = $agentStatus.Status
                    $previousStatus = $script:LastAgentStatus
                    
                    if ($currentStatus -ne $previousStatus) {
                        $script:LastAgentStatus = $currentStatus
                        
                        $notificationData = @{
                            Source = "AutonomousAgent"
                            Timestamp = Get-Date
                            CurrentStatus = $currentStatus
                            PreviousStatus = $previousStatus
                            StatusData = $agentStatus
                        }
                        
                        # Trigger notifications based on status changes
                        if ($currentStatus -eq "Failed" -and $using:triggerConfig.TriggerOnFailure) {
                            Send-AutonomousAgentNotification -NotificationData $notificationData -Configuration $using:Configuration
                        }
                        
                        if ($currentStatus -eq "Restarting" -and $using:triggerConfig.TriggerOnRestart) {
                            Send-AutonomousAgentNotification -NotificationData $notificationData -Configuration $using:Configuration
                        }
                        
                        if ($currentStatus -eq "InterventionRequired" -and $using:triggerConfig.TriggerOnIntervention) {
                            Send-AutonomousAgentNotification -NotificationData $notificationData -Configuration $using:Configuration
                        }
                    }
                }
            } catch {
                Write-SystemStatusLog "Error in autonomous agent trigger: $($_.Exception.Message)" -Level 'ERROR'
            }
        }
        
        $agentEvent = Register-ObjectEvent -InputObject $agentTimer -EventName "Elapsed" -Action $agentAction -SourceIdentifier "AutonomousAgentMonitor"
        $registeredEvents += @{
            Type = "AutonomousAgent"
            SourceIdentifier = "AutonomousAgentMonitor"
            EventRegistration = $agentEvent
            Timer = $agentTimer
        }
        
        Write-SystemStatusLog "Autonomous agent trigger registered with 30-second interval" -Level 'DEBUG'
        
        return $registeredEvents
        
    } catch {
        Write-SystemStatusLog "Failed to register autonomous agent trigger: $($_.Exception.Message)" -Level 'ERROR'
        throw $_
    }
}

function Unregister-NotificationTriggers {
    <#
    .SYNOPSIS
    Unregisters all notification triggers and cleans up resources
    #>
    [CmdletBinding()]
    param()
    
    Write-SystemStatusLog "Unregistering all notification triggers" -Level 'INFO'
    
    try {
        $sourceIdentifiers = @(
            "UnityCompilationMonitor",
            "UnityErrorFileMonitor", 
            "ClaudeResponseMonitor",
            "ErrorResolutionMonitor",
            "SystemHealthMonitor",
            "AutonomousAgentMonitor"
        )
        
        $unregisteredCount = 0
        
        foreach ($identifier in $sourceIdentifiers) {
            try {
                $event = Get-EventSubscriber -SourceIdentifier $identifier -ErrorAction SilentlyContinue
                if ($event) {
                    Unregister-Event -SourceIdentifier $identifier
                    $unregisteredCount++
                    Write-SystemStatusLog "Unregistered event: $identifier" -Level 'DEBUG'
                }
            } catch {
                Write-SystemStatusLog "Warning: Failed to unregister event $identifier : $($_.Exception.Message)" -Level 'WARN'
            }
        }
        
        # Clean up any remaining resources (FileSystemWatchers, Timers)
        # This would require tracking of these resources in the module scope
        
        Write-SystemStatusLog "Successfully unregistered $unregisteredCount notification triggers" -Level 'INFO'
        
    } catch {
        Write-SystemStatusLog "Error unregistering notification triggers: $($_.Exception.Message)" -Level 'ERROR'
        throw $_
    }
}

# Functions available for dot-sourcing in main module
# Register-NotificationTriggers, Register-UnityCompilationTrigger, Register-ClaudeSubmissionTrigger, Register-ErrorResolutionTrigger, Register-SystemHealthTrigger, Register-AutonomousAgentTrigger, Unregister-NotificationTriggers