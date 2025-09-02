# Test-AutonomousAgentStatus-EventLog.ps1
# Enhanced version with Windows Event Log integration
# Functions for monitoring and restarting the AutonomousAgent
# Date: 2025-08-22

# Ensure Write-SystemStatusLog is available
if (-not (Get-Command Write-SystemStatusLog -ErrorAction SilentlyContinue)) {
    # Define a minimal version if not available
    function Write-SystemStatusLog {
        param(
            [string]$Message,
            [string]$Level = 'INFO'
        )
        
        $timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss.fff'
        $logEntry = "[$timestamp] [$Level] $Message"
        
        # Write to verbose stream
        Write-Verbose $logEntry
        
        # Optionally write to file
        $logPath = "$PSScriptRoot\..\..\unity_claude_automation.log"
        try {
            Add-Content -Path $logPath -Value $logEntry -ErrorAction SilentlyContinue
        }
        catch {
            # Silent fail
        }
    }
}

# Ensure Read-SystemStatus is available
if (-not (Get-Command Read-SystemStatus -ErrorAction SilentlyContinue)) {
    function Read-SystemStatus {
        # Try to read from the system status file
        $statusPath = "$PSScriptRoot\..\..\system_status.json"
        if (Test-Path $statusPath) {
            try {
                return Get-Content $statusPath -Raw | ConvertFrom-Json
            }
            catch {
                return $null
            }
        }
        return $null
    }
}

# Ensure Write-SystemStatus is available
if (-not (Get-Command Write-SystemStatus -ErrorAction SilentlyContinue)) {
    function Write-SystemStatus {
        param([PSObject]$Status)
        
        $statusPath = "$PSScriptRoot\..\..\system_status.json"
        try {
            $Status | ConvertTo-Json -Depth 10 | Set-Content $statusPath -Force
        }
        catch {
            # Silent fail
        }
    }
}

function Test-AutonomousAgentStatus {
    <#
    .SYNOPSIS
    Tests if the AutonomousAgent is running with event logging
    
    .DESCRIPTION
    Checks if the AutonomousAgent process is alive and responding,
    logging all state changes and issues to Windows Event Log
    
    .PARAMETER NoEventLog
    Disable event logging
    
    .PARAMETER CorrelationId
    Correlation ID for tracking related events
    
    .OUTPUTS
    Boolean indicating if agent is running
    #>
    [CmdletBinding()]
    param(
        [switch]$NoEventLog,
        [guid]$CorrelationId = [guid]::NewGuid()
    )
    
    # Import Event Log module
    $eventLogAvailable = $false
    if (-not $NoEventLog) {
        try {
            Import-Module "$PSScriptRoot\..\..\Unity-Claude-EventLog" -ErrorAction SilentlyContinue
            $eventLogAvailable = $true
        }
        catch {
            # Silent fail - continue without event logging
        }
    }
    
    Write-SystemStatusLog "========== TEST-AUTONOMOUSAGENTSTATUS START ==========" -Level 'INFO'
    Write-SystemStatusLog "Testing AutonomousAgent status at $(Get-Date -Format 'HH:mm:ss.fff')..." -Level 'DEBUG'
    
    # Log status check start
    if ($eventLogAvailable) {
        Write-UCEventLog -Message "Autonomous Agent status check initiated" `
            -EntryType Information `
            -Component Agent `
            -Action "StatusCheckStart" `
            -CorrelationId $CorrelationId
    }
    
    try {
        # Read current status
        Write-SystemStatusLog "Reading system status..." -Level 'DEBUG'
        $status = Read-SystemStatus
        
        if (-not $status) {
            Write-SystemStatusLog "Read-SystemStatus returned NULL" -Level 'ERROR'
            
            if ($eventLogAvailable) {
                Write-UCEventLog -Message "System status read failed - NULL returned" `
                    -EntryType Error `
                    -Component Agent `
                    -Action "StatusReadFailed" `
                    -Details @{
                        Reason = "Read-SystemStatus returned NULL"
                    } `
                    -CorrelationId $CorrelationId
            }
            
            return $false
        }
        
        if (-not $status.Subsystems) {
            Write-SystemStatusLog "No Subsystems property in status" -Level 'ERROR'
            
            if ($eventLogAvailable) {
                Write-UCEventLog -Message "System status invalid - no subsystems" `
                    -EntryType Error `
                    -Component Agent `
                    -Action "StatusInvalid" `
                    -Details @{
                        Reason = "No Subsystems property"
                    } `
                    -CorrelationId $CorrelationId
            }
            
            return $false
        }
        
        Write-SystemStatusLog "Status has $($status.Subsystems.Count) subsystems registered" -Level 'DEBUG'
        Write-SystemStatusLog "Subsystem keys: $($status.Subsystems.Keys -join ', ')" -Level 'DEBUG'
        
        # Check if AutonomousAgent is registered (try both naming conventions)
        $agentKey = $null
        if ($status.Subsystems.ContainsKey("AutonomousAgent")) {
            $agentKey = "AutonomousAgent"
            Write-SystemStatusLog "Found key 'AutonomousAgent'" -Level 'DEBUG'
        }
        elseif ($status.Subsystems.ContainsKey("Unity-Claude-AutonomousAgent")) {
            $agentKey = "Unity-Claude-AutonomousAgent"
            Write-SystemStatusLog "Found key 'Unity-Claude-AutonomousAgent'" -Level 'DEBUG'
        }
        
        if (-not $agentKey) {
            Write-SystemStatusLog "AutonomousAgent not registered in system status" -Level 'WARNING'
            
            if ($eventLogAvailable) {
                Write-UCEventLog -Message "Autonomous Agent not registered" `
                    -EntryType Warning `
                    -Component Agent `
                    -Action "NotRegistered" `
                    -Details @{
                        RegisteredSubsystems = $status.Subsystems.Keys -join ', '
                    } `
                    -CorrelationId $CorrelationId
            }
            
            return $false
        }
        
        # Get agent info
        $agentInfo = $status.Subsystems[$agentKey]
        Write-SystemStatusLog "Agent info retrieved: ProcessId=$($agentInfo.ProcessId), Status=$($agentInfo.Status)" -Level 'DEBUG'
        
        # Check process ID
        if (-not $agentInfo.ProcessId -or $agentInfo.ProcessId -eq 0) {
            Write-SystemStatusLog "AutonomousAgent has no valid process ID" -Level 'WARNING'
            
            if ($eventLogAvailable) {
                Write-UCEventLog -Message "Autonomous Agent has no valid process ID" `
                    -EntryType Warning `
                    -Component Agent `
                    -Action "NoProcessId" `
                    -Details @{
                        Status = $agentInfo.Status
                        LastHeartbeat = if ($agentInfo.LastHeartbeat) { $agentInfo.LastHeartbeat.ToString() } else { "N/A" }
                    } `
                    -CorrelationId $CorrelationId
            }
            
            return $false
        }
        
        # Check if process exists
        $process = Get-Process -Id $agentInfo.ProcessId -ErrorAction SilentlyContinue
        if (-not $process) {
            Write-SystemStatusLog "AutonomousAgent process $($agentInfo.ProcessId) not found" -Level 'ERROR'
            
            if ($eventLogAvailable) {
                Write-UCEventLog -Message "Autonomous Agent process not found" `
                    -EntryType Error `
                    -Component Agent `
                    -Action "ProcessNotFound" `
                    -Details @{
                        ProcessId = $agentInfo.ProcessId
                        LastStatus = $agentInfo.Status
                    } `
                    -CorrelationId $CorrelationId
            }
            
            return $false
        }
        
        Write-SystemStatusLog "Process found: $($process.ProcessName) (PID: $($process.Id))" -Level 'DEBUG'
        
        # Check heartbeat (if available)
        if ($agentInfo.LastHeartbeat) {
            $lastHeartbeat = [DateTime]$agentInfo.LastHeartbeat
            $timeSinceHeartbeat = (Get-Date) - $lastHeartbeat
            
            Write-SystemStatusLog "Last heartbeat: $($lastHeartbeat.ToString('HH:mm:ss.fff')), $([int]$timeSinceHeartbeat.TotalSeconds) seconds ago" -Level 'DEBUG'
            
            if ($timeSinceHeartbeat.TotalMinutes -gt 5) {
                Write-SystemStatusLog "AutonomousAgent heartbeat is stale (>5 minutes)" -Level 'WARNING'
                
                if ($eventLogAvailable) {
                    Write-UCEventLog -Message "Autonomous Agent heartbeat stale" `
                        -EntryType Warning `
                        -Component Agent `
                        -Action "HeartbeatStale" `
                        -Details @{
                            LastHeartbeat = $lastHeartbeat.ToString()
                            MinutesSince = [int]$timeSinceHeartbeat.TotalMinutes
                            ProcessId = $agentInfo.ProcessId
                        } `
                        -CorrelationId $CorrelationId
                }
                
                return $false
            }
        }
        
        # Check status
        if ($agentInfo.Status -ne 'Running' -and $agentInfo.Status -ne 'Active') {
            Write-SystemStatusLog "AutonomousAgent status is not Running/Active: $($agentInfo.Status)" -Level 'WARNING'
            
            if ($eventLogAvailable) {
                Write-UCEventLog -Message "Autonomous Agent not in running state" `
                    -EntryType Warning `
                    -Component Agent `
                    -Action "NotRunning" `
                    -Details @{
                        CurrentStatus = $agentInfo.Status
                        ProcessId = $agentInfo.ProcessId
                    } `
                    -CorrelationId $CorrelationId
            }
            
            return $false
        }
        
        Write-SystemStatusLog "AutonomousAgent is running (PID: $($agentInfo.ProcessId), Status: $($agentInfo.Status))" -Level 'INFO'
        
        # Log successful status check
        if ($eventLogAvailable) {
            Write-UCEventLog -Message "Autonomous Agent status check successful" `
                -EntryType Information `
                -Component Agent `
                -Action "StatusCheckSuccess" `
                -Details @{
                    ProcessId = $agentInfo.ProcessId
                    Status = $agentInfo.Status
                    ProcessName = $process.ProcessName
                    WorkingSet = [math]::Round($process.WorkingSet64 / 1MB, 2)
                    CPU = if ($process.CPU) { [math]::Round($process.CPU, 2) } else { 0 }
                } `
                -CorrelationId $CorrelationId
        }
        
        return $true
    }
    catch {
        Write-SystemStatusLog "Error checking AutonomousAgent status: $_" -Level 'ERROR'
        Write-SystemStatusLog "Stack trace: $($_.ScriptStackTrace)" -Level 'DEBUG'
        
        if ($eventLogAvailable) {
            Write-UCEventLog -Message "Autonomous Agent status check failed with exception" `
                -EntryType Error `
                -Component Agent `
                -Action "StatusCheckException" `
                -Details @{
                    Error = $_.Exception.Message
                    ScriptLine = $_.InvocationInfo.ScriptLineNumber
                    Command = $_.InvocationInfo.MyCommand
                } `
                -CorrelationId $CorrelationId
        }
        
        return $false
    }
    finally {
        Write-SystemStatusLog "========== TEST-AUTONOMOUSAGENTSTATUS END ==========" -Level 'INFO'
    }
}

function Restart-AutonomousAgent {
    <#
    .SYNOPSIS
    Restarts the AutonomousAgent with event logging
    
    .DESCRIPTION
    Stops the current agent process if running and starts a new instance,
    logging all actions to Windows Event Log
    
    .PARAMETER Force
    Force restart even if agent appears to be running
    
    .PARAMETER NoEventLog
    Disable event logging
    
    .PARAMETER CorrelationId
    Correlation ID for tracking related events
    
    .OUTPUTS
    Boolean indicating if restart was successful
    #>
    [CmdletBinding()]
    param(
        [switch]$Force,
        [switch]$NoEventLog,
        [guid]$CorrelationId = [guid]::NewGuid()
    )
    
    # Import Event Log module
    $eventLogAvailable = $false
    if (-not $NoEventLog) {
        try {
            Import-Module "$PSScriptRoot\..\..\Unity-Claude-EventLog" -ErrorAction SilentlyContinue
            $eventLogAvailable = $true
        }
        catch {
            # Silent fail - continue without event logging
        }
    }
    
    Write-SystemStatusLog "========== RESTART-AUTONOMOUSAGENT START ==========" -Level 'INFO'
    
    # Log restart initiated
    if ($eventLogAvailable) {
        Write-UCEventLog -Message "Autonomous Agent restart initiated" `
            -EntryType Information `
            -Component Agent `
            -Action "RestartInitiated" `
            -Details @{
                Force = $Force.IsPresent
                InitiatedBy = $env:USERNAME
                Reason = if ($Force) { "Forced restart" } else { "Agent not responding" }
            } `
            -CorrelationId $CorrelationId
    }
    
    try {
        # Check current status
        if (-not $Force) {
            $isRunning = Test-AutonomousAgentStatus -NoEventLog:$NoEventLog -CorrelationId $CorrelationId
            if ($isRunning) {
                Write-SystemStatusLog "AutonomousAgent is already running, skipping restart" -Level 'INFO'
                
                if ($eventLogAvailable) {
                    Write-UCEventLog -Message "Autonomous Agent restart skipped - already running" `
                        -EntryType Information `
                        -Component Agent `
                        -Action "RestartSkipped" `
                        -Details @{
                            Reason = "Agent already running"
                        } `
                        -CorrelationId $CorrelationId
                }
                
                return $true
            }
        }
        
        # Stop existing agent process
        Write-SystemStatusLog "Stopping existing AutonomousAgent process..." -Level 'INFO'
        $status = Read-SystemStatus
        
        if ($status -and $status.Subsystems) {
            $agentKey = $null
            if ($status.Subsystems.ContainsKey("AutonomousAgent")) {
                $agentKey = "AutonomousAgent"
            }
            elseif ($status.Subsystems.ContainsKey("Unity-Claude-AutonomousAgent")) {
                $agentKey = "Unity-Claude-AutonomousAgent"
            }
            
            if ($agentKey -and $status.Subsystems[$agentKey].ProcessId) {
                $processId = $status.Subsystems[$agentKey].ProcessId
                $process = Get-Process -Id $processId -ErrorAction SilentlyContinue
                
                if ($process) {
                    Write-SystemStatusLog "Stopping process $processId..." -Level 'DEBUG'
                    Stop-Process -Id $processId -Force -ErrorAction SilentlyContinue
                    Start-Sleep -Seconds 2
                    
                    if ($eventLogAvailable) {
                        Write-UCEventLog -Message "Autonomous Agent process stopped" `
                            -EntryType Information `
                            -Component Agent `
                            -Action "ProcessStopped" `
                            -Details @{
                                ProcessId = $processId
                                ProcessName = $process.ProcessName
                            } `
                            -CorrelationId $CorrelationId
                    }
                }
            }
        }
        
        # Start new agent
        Write-SystemStatusLog "Starting new AutonomousAgent instance..." -Level 'INFO'
        $scriptPath = Join-Path (Split-Path $PSScriptRoot -Parent -Parent) "Start-AutonomousMonitoring.ps1"
        
        if (-not (Test-Path $scriptPath)) {
            # Try alternative locations
            $alternativePaths = @(
                "C:\UnityProjects\Sound-and-Shoal\Unity-Claude-Automation\Start-AutonomousMonitoring.ps1",
                "C:\UnityProjects\Sound-and-Shoal\Unity-Claude-Automation\Start-AutonomousMonitoring-Fixed.ps1",
                "C:\UnityProjects\Sound-and-Shoal\Unity-Claude-Automation\Start-AutonomousMonitoring-Enhanced.ps1"
            )
            
            foreach ($altPath in $alternativePaths) {
                if (Test-Path $altPath) {
                    $scriptPath = $altPath
                    break
                }
            }
        }
        
        if (Test-Path $scriptPath) {
            Write-SystemStatusLog "Starting agent from: $scriptPath" -Level 'DEBUG'
            
            $startInfo = New-Object System.Diagnostics.ProcessStartInfo
            $startInfo.FileName = "powershell.exe"
            $startInfo.Arguments = "-NoProfile -ExecutionPolicy Bypass -File `"$scriptPath`""
            $startInfo.WindowStyle = [System.Diagnostics.ProcessWindowStyle]::Minimized
            $startInfo.CreateNoWindow = $false
            $startInfo.UseShellExecute = $true
            
            $newProcess = [System.Diagnostics.Process]::Start($startInfo)
            Start-Sleep -Seconds 3
            
            if ($newProcess -and -not $newProcess.HasExited) {
                Write-SystemStatusLog "AutonomousAgent started with PID: $($newProcess.Id)" -Level 'INFO'
                
                # Update system status
                $status = Read-SystemStatus
                if ($status) {
                    if (-not $status.Subsystems) {
                        $status.Subsystems = @{}
                    }
                    
                    $status.Subsystems["AutonomousAgent"] = @{
                        ProcessId = $newProcess.Id
                        Status = 'Running'
                        StartTime = (Get-Date).ToString('o')
                        LastHeartbeat = (Get-Date).ToString('o')
                    }
                    
                    Write-SystemStatus -Status $status
                }
                
                if ($eventLogAvailable) {
                    Write-UCEventLog -Message "Autonomous Agent started successfully" `
                        -EntryType Information `
                        -Component Agent `
                        -Action "RestartSuccess" `
                        -Details @{
                            NewProcessId = $newProcess.Id
                            ScriptPath = $scriptPath
                            StartTime = (Get-Date).ToString('o')
                        } `
                        -CorrelationId $CorrelationId
                }
                
                return $true
            }
            else {
                Write-SystemStatusLog "Failed to start AutonomousAgent process" -Level 'ERROR'
                
                if ($eventLogAvailable) {
                    Write-UCEventLog -Message "Autonomous Agent failed to start" `
                        -EntryType Error `
                        -Component Agent `
                        -Action "RestartFailed" `
                        -Details @{
                            ScriptPath = $scriptPath
                            Reason = "Process exited immediately"
                        } `
                        -CorrelationId $CorrelationId
                }
                
                return $false
            }
        }
        else {
            Write-SystemStatusLog "AutonomousAgent script not found at: $scriptPath" -Level 'ERROR'
            
            if ($eventLogAvailable) {
                Write-UCEventLog -Message "Autonomous Agent script not found" `
                    -EntryType Error `
                    -Component Agent `
                    -Action "ScriptNotFound" `
                    -Details @{
                        ExpectedPath = $scriptPath
                        SearchedPaths = $alternativePaths -join '; '
                    } `
                    -CorrelationId $CorrelationId
            }
            
            return $false
        }
    }
    catch {
        Write-SystemStatusLog "Error restarting AutonomousAgent: $_" -Level 'ERROR'
        Write-SystemStatusLog "Stack trace: $($_.ScriptStackTrace)" -Level 'DEBUG'
        
        if ($eventLogAvailable) {
            Write-UCEventLog -Message "Autonomous Agent restart failed with exception" `
                -EntryType Error `
                -Component Agent `
                -Action "RestartException" `
                -Details @{
                    Error = $_.Exception.Message
                    ScriptLine = $_.InvocationInfo.ScriptLineNumber
                    Command = $_.InvocationInfo.MyCommand
                } `
                -CorrelationId $CorrelationId
        }
        
        return $false
    }
    finally {
        Write-SystemStatusLog "========== RESTART-AUTONOMOUSAGENT END ==========" -Level 'INFO'
    }
}

# Export functions - only if loaded as module
if ($ExecutionContext.SessionState.Module) {
    Export-ModuleMember -Function Test-AutonomousAgentStatus, Restart-AutonomousAgent
}
# SIG # Begin signature block
# MIIFzgYJKoZIhvcNAQcCoIIFvzCCBbsCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCDkgn4fraFf62sr
# OIn2ZD4lX5e9xUPed58pd219YkK3DKCCAzAwggMsMIICFKADAgECAhB1HRbZIqgr
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
# MAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIABU2yKJ38cgwHLRCqBTyu99
# qbpckql7/9c2cQ4bEAWKMA0GCSqGSIb3DQEBAQUABIIBAFIr/ODRi6WpbFH8RO2l
# +aF3ube8pkKTG2Lph2H92sBxBt2GZU0zRkEY6JBqCPrZIeyOSe9/YXqYykOk3vw6
# au6Su9FrBOi/5D3KTJWAWXnW+a4AKabmMgqjLN6G0oX9UUocarKDpTbNGWiiTLsu
# 5TM8fjc8wr7YYYITC+nhWT4+VI3Q+1aaNsnyE6cuvTw2ZzzpSfWpgBrr3mR1KP63
# Gw8QRT2DCHDVKCQSWbJLqSDJGabGxtb+pRDk7Av+KqWYx+z79QI7qYEhLiVM+rRx
# H2LziWcv88d8tBpRKI7wpBsNeeJEyMc7MQ3684GZRInwoek3ikiH90def40QngIV
# xMI=
# SIG # End signature block
