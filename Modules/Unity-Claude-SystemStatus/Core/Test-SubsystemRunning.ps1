function Test-SubsystemRunning {
    <#
    .SYNOPSIS
    Tests if a subsystem is already running by checking mutex and process status
    
    .DESCRIPTION
    Checks if a subsystem is already running by:
    1. Checking if its mutex is held
    2. Verifying the process is still alive
    3. Checking system status data
    
    .PARAMETER SubsystemName
    Name of the subsystem to check
    
    .PARAMETER MutexName
    Optional mutex name to check. If not provided, uses default pattern
    
    .OUTPUTS
    Boolean indicating if subsystem is running
    
    .EXAMPLE
    Test-SubsystemRunning -SubsystemName "SystemMonitoring"
    #>
    
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$SubsystemName,
        
        [string]$MutexName
    )
    
    # Default mutex name if not provided
    if (-not $MutexName) {
        $MutexName = "Global\UnityClaudeSubsystem_$SubsystemName"
    }
    
    # Method 1: Check if mutex exists and is held
    $mutexHeld = $false
    try {
        $mutex = [System.Threading.Mutex]::OpenExisting($MutexName)
        # Try to acquire with no wait
        $acquired = $mutex.WaitOne(0)
        if ($acquired) {
            # We got it, so it wasn't held
            $mutex.ReleaseMutex()
            $mutexHeld = $false
        } else {
            # Couldn't acquire, so it's held
            $mutexHeld = $true
        }
        $mutex.Dispose()
    } catch {
        # Mutex doesn't exist
        $mutexHeld = $false
    }
    
    if ($mutexHeld) {
        Write-SystemStatusLog "Subsystem $SubsystemName mutex is held" -Level 'DEBUG'
        return $true
    }
    
    # Method 2: Check system status for registered process
    try {
        $status = Read-SystemStatus
        if ($status -and $status.subsystems -and $status.subsystems.ContainsKey($SubsystemName)) {
            $subsystem = $status.subsystems[$SubsystemName]
            if ($subsystem.ProcessId) {
                # Check if process is still running
                $process = Get-Process -Id $subsystem.ProcessId -ErrorAction SilentlyContinue
                if ($process) {
                    Write-SystemStatusLog "Subsystem $SubsystemName process is running (PID: $($subsystem.ProcessId))" -Level 'DEBUG'
                    return $true
                }
            }
        }
    } catch {
        Write-SystemStatusLog "Error checking system status for $SubsystemName - $_" -Level 'DEBUG'
    }
    
    Write-SystemStatusLog "Subsystem $SubsystemName is not running" -Level 'DEBUG'
    return $false
}

# Export the function
Export-ModuleMember -Function Test-SubsystemRunning