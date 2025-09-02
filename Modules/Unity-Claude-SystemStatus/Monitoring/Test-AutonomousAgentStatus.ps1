# Test-AutonomousAgentStatus.ps1
# Functions for monitoring and restarting the AutonomousAgent
# Date: 2025-08-21

function Test-AutonomousAgentStatus {
    <#
    .SYNOPSIS
    Tests if the AutonomousAgent is running
    
    .DESCRIPTION
    Checks if the AutonomousAgent process is alive and responding
    
    .OUTPUTS
    Boolean indicating if agent is running
    #>
    [CmdletBinding()]
    param()
    
    Write-SystemStatusLog "========== TEST-AUTONOMOUSAGENTSTATUS START ==========" -Level 'INFO'
    Write-SystemStatusLog "Testing AutonomousAgent status at $(Get-Date -Format 'HH:mm:ss.fff')..." -Level 'DEBUG'
    
    try {
        # Read current status
        Write-SystemStatusLog "Reading system status..." -Level 'DEBUG'
        $status = Read-SystemStatus
        
        if (-not $status) {
            Write-SystemStatusLog "Read-SystemStatus returned NULL" -Level 'ERROR'
            return $false
        }
        
        if (-not $status.Subsystems) {
            Write-SystemStatusLog "No Subsystems property in status" -Level 'ERROR'
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
            Write-SystemStatusLog "AutonomousAgent NOT FOUND in subsystems (checked both 'AutonomousAgent' and 'Unity-Claude-AutonomousAgent')" -Level 'WARN'
            Write-SystemStatusLog "Available subsystem keys: $($status.Subsystems.Keys -join ', ')" -Level 'WARN'
            return $false
        }
        
        $agentInfo = $status.Subsystems[$agentKey]
        Write-SystemStatusLog "Found AutonomousAgent registered as: '$agentKey'" -Level 'INFO'
        
        # Check if we have a process ID
        if (-not $agentInfo.ProcessId) {
            Write-SystemStatusLog "AutonomousAgent has no ProcessId recorded" -Level 'WARN'
            return $false
        }
        
        # Check if process is actually running
        $process = Get-Process -Id $agentInfo.ProcessId -ErrorAction SilentlyContinue
        
        if (-not $process) {
            Write-SystemStatusLog "AutonomousAgent process $($agentInfo.ProcessId) is not running" -Level 'WARN'
            return $false
        }
        
        # Check heartbeat (if it's been more than 5 minutes, consider it unhealthy)
        if ($agentInfo.LastHeartbeat) {
            $lastHeartbeat = [DateTime]::ParseExact($agentInfo.LastHeartbeat, 'yyyy-MM-dd HH:mm:ss.fff', $null)
            $timeSinceHeartbeat = (Get-Date) - $lastHeartbeat
            
            if ($timeSinceHeartbeat.TotalMinutes -gt 5) {
                Write-SystemStatusLog "AutonomousAgent heartbeat is stale (last: $($agentInfo.LastHeartbeat))" -Level 'WARN'
                return $false
            }
        }
        
        Write-SystemStatusLog "AutonomousAgent is RUNNING (PID: $($agentInfo.ProcessId))" -Level 'INFO'
        Write-SystemStatusLog "========== TEST-AUTONOMOUSAGENTSTATUS END (RUNNING) ==========" -Level 'INFO'
        return $true
    }
    catch {
        Write-SystemStatusLog "EXCEPTION testing AutonomousAgent status: $_" -Level 'ERROR'
        Write-SystemStatusLog "Exception type: $($_.Exception.GetType().FullName)" -Level 'ERROR'
        Write-SystemStatusLog "Stack trace: $($_.ScriptStackTrace)" -Level 'ERROR'
        Write-SystemStatusLog "========== TEST-AUTONOMOUSAGENTSTATUS END (ERROR) ==========" -Level 'ERROR'
        return $false
    }
}

function Start-AutonomousAgentSafe {
    <#
    .SYNOPSIS
    Safely starts or restarts the AutonomousAgent
    
    .DESCRIPTION
    Starts the AutonomousAgent in a new PowerShell window with proper error handling
    
    .OUTPUTS
    Boolean indicating if agent was started successfully
    #>
    [CmdletBinding()]
    param()
    
    Write-SystemStatusLog "========== START-AUTONOMOUSAGENTSAFE BEGIN ==========" -Level 'INFO'
    Write-SystemStatusLog "Starting AutonomousAgent at $(Get-Date -Format 'HH:mm:ss.fff')..." -Level 'INFO'
    
    try {
        # First check if it's already running
        if (Test-AutonomousAgentStatus) {
            Write-SystemStatusLog "AutonomousAgent is already running - no restart needed" -Level 'INFO'
            Write-SystemStatusLog "========== START-AUTONOMOUSAGENTSAFE END (ALREADY RUNNING) ==========" -Level 'INFO'
            return $true
        }
        
        Write-SystemStatusLog "AutonomousAgent is NOT running - proceeding with restart" -Level 'INFO'
        
        # Kill any zombie processes (check both naming conventions)
        $status = Read-SystemStatus
        $agentKey = $null
        if ($status -and $status.Subsystems) {
            if ($status.Subsystems.ContainsKey("AutonomousAgent")) {
                $agentKey = "AutonomousAgent"
            }
            elseif ($status.Subsystems.ContainsKey("Unity-Claude-AutonomousAgent")) {
                $agentKey = "Unity-Claude-AutonomousAgent"
            }
        }
        
        if ($agentKey) {
            $oldPid = $status.Subsystems[$agentKey].ProcessId
            if ($oldPid) {
                $oldProcess = Get-Process -Id $oldPid -ErrorAction SilentlyContinue
                if ($oldProcess) {
                    Write-SystemStatusLog "Killing old AutonomousAgent process: $oldPid" -Level 'WARN'
                    Stop-Process -Id $oldPid -Force -ErrorAction SilentlyContinue
                    Start-Sleep -Seconds 2
                }
            }
        }
        
        # Start new instance - try fixed version first, then fall back
        $scriptPath = "C:\UnityProjects\Sound-and-Shoal\Unity-Claude-Automation\Start-AutonomousMonitoring-Fixed.ps1"
        
        if (-not (Test-Path $scriptPath)) {
            Write-SystemStatusLog "Fixed version not found, trying simple version..." -Level 'WARN'
            $scriptPath = "C:\UnityProjects\Sound-and-Shoal\Unity-Claude-Automation\Start-AutonomousMonitoring-Simple.ps1"
            
            if (-not (Test-Path $scriptPath)) {
                Write-SystemStatusLog "Simple version not found, trying enhanced version..." -Level 'WARN'
                $scriptPath = "C:\UnityProjects\Sound-and-Shoal\Unity-Claude-Automation\Start-AutonomousMonitoring-Enhanced.ps1"
                
                if (-not (Test-Path $scriptPath)) {
                    Write-SystemStatusLog "Enhanced version not found, falling back to original..." -Level 'WARN'
                    $scriptPath = "C:\UnityProjects\Sound-and-Shoal\Unity-Claude-Automation\Start-AutonomousMonitoring.ps1"
                    
                    if (-not (Test-Path $scriptPath)) {
                        Write-SystemStatusLog "Cannot find any Start-AutonomousMonitoring script!" -Level 'ERROR'
                        return $false
                    }
                }
            }
        }
        
        Write-SystemStatusLog "Starting AutonomousAgent from: $scriptPath" -Level 'INFO'
        
        # Start in new window
        $startInfo = @{
            FilePath = "pwsh.exe"
            ArgumentList = @(
                "-NoExit",
                "-ExecutionPolicy", "Bypass",
                "-File", "`"$scriptPath`""
            )
            WorkingDirectory = "C:\UnityProjects\Sound-and-Shoal\Unity-Claude-Automation"
            PassThru = $true
        }
        
        $process = Start-Process @startInfo
        
        if ($process) {
            Write-SystemStatusLog "PowerShell wrapper started with PID: $($process.Id)" -Level 'INFO'
            Write-SystemStatusLog "Waiting for AutonomousAgent to self-register..." -Level 'INFO'
            
            # Wait for the script to self-register with its actual PID
            # The script calls Register-Subsystem which will update the PID correctly
            Start-Sleep -Seconds 5
            
            # Verify it registered successfully
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
                    $actualPid = $status.Subsystems[$agentKey].ProcessId
                    Write-SystemStatusLog "AutonomousAgent self-registered with PID: $actualPid" -Level 'INFO'
                    
                    # Verify the process is actually running
                    $agentProcess = Get-Process -Id $actualPid -ErrorAction SilentlyContinue
                    if ($agentProcess) {
                        Write-SystemStatusLog "Confirmed AutonomousAgent is running (PID: $actualPid)" -Level 'INFO'
                        Write-SystemStatusLog "========== START-AUTONOMOUSAGENTSAFE END (SUCCESS) ==========" -Level 'INFO'
                        return $true
                    }
                    else {
                        Write-SystemStatusLog "WARNING: Agent registered but process not found!" -Level 'WARN'
                    }
                }
                else {
                    Write-SystemStatusLog "WARNING: Agent did not self-register within timeout" -Level 'WARN'
                }
            }
            
            Write-SystemStatusLog "========== START-AUTONOMOUSAGENTSAFE END (UNCERTAIN) ==========" -Level 'WARN'
            return $true  # Return true since we started the process, even if registration is uncertain
        }
        else {
            Write-SystemStatusLog "Failed to start AutonomousAgent process" -Level 'ERROR'
            Write-SystemStatusLog "========== START-AUTONOMOUSAGENTSAFE END (FAILED) ==========" -Level 'ERROR'
            return $false
        }
    }
    catch {
        Write-SystemStatusLog "EXCEPTION starting AutonomousAgent: $_" -Level 'ERROR'
        Write-SystemStatusLog "Exception type: $($_.Exception.GetType().FullName)" -Level 'ERROR'
        Write-SystemStatusLog "Stack trace: $($_.ScriptStackTrace)" -Level 'ERROR'
        Write-SystemStatusLog "========== START-AUTONOMOUSAGENTSAFE END (EXCEPTION) ==========" -Level 'ERROR'
        return $false
    }
}

# Export functions
Export-ModuleMember -Function @(
    'Test-AutonomousAgentStatus',
    'Start-AutonomousAgentSafe'
)
# SIG # Begin signature block
# MIIFzgYJKoZIhvcNAQcCoIIFvzCCBbsCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCDjuzV2a9IqNyJB
# x9G7o16yi5h5a7g84e+lpgkKzvC68qCCAzAwggMsMIICFKADAgECAhB1HRbZIqgr
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
# MAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIET0yGVFDTMW9Fq1DlgykU0S
# zSJ8hFENWnbuzOHHs+WoMA0GCSqGSIb3DQEBAQUABIIBACQfvcOuGydrPYADDmDp
# vMFsgDDwTEGVxEVfKfTGWssvF8+gO9zo03M6WDqiEGSl9cTGHF19hd8CaL69139R
# 8xigH4EOAz1MGq4XbUeOOr3pFzwv6WXfERMGQrhjiX3jrs9lHY5ijxCpPzLaUphT
# iQoGCs0gaN7ha6BuDOCXYqq46Yx7b3Yxd8qIaonp4dQ4ZhFQI6t1fSx6seVXqAnd
# 0QZgScRlVUNIkZRNjxfE4jvCysapp8sFnuzC3pOCxjGjD8xwi/Vf6/kSaIQ13z5i
# w/4jKFqlGxWRwPDk1Kww1j4YGjlcvvoRFRiSl+LY8yXmGLJXg5p4PKYcaNRL/rkX
# XRc=
# SIG # End signature block
