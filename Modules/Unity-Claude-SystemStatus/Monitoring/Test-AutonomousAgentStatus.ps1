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
# MIIFqQYJKoZIhvcNAQcCoIIFmjCCBZYCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUxVmWGZnRJhlpdTMmWUexMOM+
# TuKgggMwMIIDLDCCAhSgAwIBAgIQdR0W2SKoK5VE8JId4ZxrRTANBgkqhkiG9w0B
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
# CQQxFgQUM7yzBr1Y/7WIadfv0FQF6NFgo68wDQYJKoZIhvcNAQEBBQAEggEALRbt
# cnBoKB2a0veNSN03YeQQL1rraTbjTyl0p2To8AE9TZbW9A9V3kX2QRKl6oxWHWHz
# nQwwu0y3+DYtKdaBijl5PAOnyO4DPQo/nuGPdWPBy1Iv4xqTdZ0ZWHA8RCBcpY9A
# Iaex99KUrRqMXcGxYy5JksM7yf90nQdPhon/4SPjaTSY/Epb7IPI3OWDM06i0HnE
# TCfx+ZjYeWaaDUamqBydZkv/Tjt9rCSVUUaxCTDx06RmKISdMeivHjihkEKeKyNr
# coYhB5XlK8xsQts1WNUaHr+xwy2tZ33+iw3fOaG/flFoxsWbDZeCFHgkbxR6FTj6
# xD91DZgq+DYuC7CuWA==
# SIG # End signature block

