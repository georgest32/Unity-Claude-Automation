function New-SubsystemMutex {
    <#
    .SYNOPSIS
    Creates or acquires a mutex for a subsystem to ensure singleton operation.
    
    .DESCRIPTION
    Creates a named mutex for a subsystem using System.Threading.Mutex with Global\ prefix
    for system-wide singleton enforcement. Handles abandoned mutex exceptions gracefully.
    
    .PARAMETER SubsystemName
    The name of the subsystem to create a mutex for.
    
    .PARAMETER MutexName
    Optional custom mutex name. Defaults to "Global\UnityClaudeSubsystem_$SubsystemName"
    
    .PARAMETER TimeoutMs
    Timeout in milliseconds for acquiring the mutex. Default is 0 (non-blocking).
    
    .OUTPUTS
    PSCustomObject with properties:
    - Mutex: The mutex object (or null if not acquired)
    - Acquired: Boolean indicating if mutex was acquired
    - IsNew: Boolean indicating if this is a new mutex
    - Message: Status message
    
    .EXAMPLE
    $mutexResult = New-SubsystemMutex -SubsystemName "AutonomousAgent"
    if ($mutexResult.Acquired) {
        # Subsystem can start
    }
    #>
    
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$SubsystemName,
        
        [Parameter()]
        [string]$MutexName = "Global\UnityClaudeSubsystem_$SubsystemName",
        
        [Parameter()]
        [int]$TimeoutMs = 0
    )
    
    Write-SystemStatusLog "Attempting to create/acquire mutex for subsystem: $SubsystemName" -Level 'DEBUG'
    Write-SystemStatusLog "Mutex name: $MutexName" -Level 'TRACE'
    
    $result = [PSCustomObject]@{
        Mutex = $null
        Acquired = $false
        IsNew = $false
        Message = ""
    }
    
    try {
        # Create mutex (second parameter false means we don't request initial ownership)
        $createdNew = $false
        $mutex = New-Object System.Threading.Mutex($false, $MutexName, [ref]$createdNew)
        $result.IsNew = $createdNew
        
        if ($createdNew) {
            Write-SystemStatusLog "Created new mutex for $SubsystemName" -Level 'INFO'
        } else {
            Write-SystemStatusLog "Mutex already exists for $SubsystemName, attempting to acquire..." -Level 'DEBUG'
        }
        
        # Try to acquire the mutex
        $acquired = $false
        
        try {
            Write-SystemStatusLog "Calling WaitOne with timeout: $TimeoutMs ms" -Level 'TRACE'
            $acquired = $mutex.WaitOne($TimeoutMs)
            
            if ($acquired) {
                Write-SystemStatusLog "Successfully acquired mutex for $SubsystemName" -Level 'OK'
                $result.Mutex = $mutex
                $result.Acquired = $true
                $result.Message = "Mutex acquired successfully"
            } else {
                Write-SystemStatusLog "Could not acquire mutex for $SubsystemName - another instance is running" -Level 'WARN'
                $result.Message = "Mutex is held by another process"
                
                # Clean up the mutex object since we didn't acquire it
                $mutex.Dispose()
            }
        }
        catch [System.Threading.AbandonedMutexException] {
            # An abandoned mutex means another process crashed while holding it
            # We now own the mutex and should continue
            Write-SystemStatusLog "Acquired abandoned mutex for $SubsystemName - previous holder crashed" -Level 'WARN'
            Write-SystemStatusLog "Cleaning up potentially inconsistent state..." -Level 'INFO'
            
            $result.Mutex = $mutex
            $result.Acquired = $true
            $result.Message = "Acquired abandoned mutex (previous holder crashed)"
            
            # Note: The mutex is now owned by this thread despite the exception
            # We should clean up any potentially inconsistent state here
        }
        
    }
    catch {
        Write-SystemStatusLog "Error creating/acquiring mutex for ${SubsystemName}: $_" -Level 'ERROR'
        $result.Message = "Error: $_"
        
        # Clean up any partial mutex creation
        if ($mutex -and -not $result.Acquired) {
            try {
                $mutex.Dispose()
            } catch {
                Write-SystemStatusLog "Error disposing mutex: $_" -Level 'TRACE'
            }
        }
    }
    
    return $result
}

function Test-SubsystemMutex {
    <#
    .SYNOPSIS
    Tests if a mutex for a subsystem exists and is currently held.
    
    .DESCRIPTION
    Checks if a mutex exists for the specified subsystem without acquiring it.
    This is useful for checking if another instance is running.
    
    .PARAMETER SubsystemName
    The name of the subsystem to check.
    
    .PARAMETER MutexName
    Optional custom mutex name. Defaults to "Global\UnityClaudeSubsystem_$SubsystemName"
    
    .OUTPUTS
    PSCustomObject with properties:
    - Exists: Boolean indicating if mutex exists
    - IsHeld: Boolean indicating if mutex is currently held
    - Message: Status message
    
    .EXAMPLE
    $status = Test-SubsystemMutex -SubsystemName "AutonomousAgent"
    if ($status.IsHeld) {
        Write-Host "Another instance is running"
    }
    #>
    
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$SubsystemName,
        
        [Parameter()]
        [string]$MutexName = "Global\UnityClaudeSubsystem_$SubsystemName"
    )
    
    Write-SystemStatusLog "Testing mutex status for subsystem: $SubsystemName" -Level 'TRACE'
    
    $result = [PSCustomObject]@{
        Exists = $false
        IsHeld = $false
        Message = ""
    }
    
    try {
        # Try to open existing mutex
        $mutex = $null
        try {
            $mutex = [System.Threading.Mutex]::OpenExisting($MutexName)
            $result.Exists = $true
            Write-SystemStatusLog "Mutex exists for $SubsystemName" -Level 'TRACE'
            
            # Try to acquire with zero timeout to check if it's held
            try {
                $acquired = $mutex.WaitOne(0)
                if ($acquired) {
                    # We got it, so it wasn't held
                    $result.IsHeld = $false
                    $result.Message = "Mutex exists but is not held"
                    Write-SystemStatusLog "Mutex for $SubsystemName exists but is not held" -Level 'DEBUG'
                    
                    # Release it immediately since we were just testing
                    $mutex.ReleaseMutex()
                } else {
                    # Couldn't get it, so it's held by another process
                    $result.IsHeld = $true
                    $result.Message = "Mutex exists and is held by another process"
                    Write-SystemStatusLog "Mutex for $SubsystemName is held by another process" -Level 'DEBUG'
                }
            }
            catch [System.Threading.AbandonedMutexException] {
                # Mutex was abandoned
                $result.IsHeld = $false
                $result.Message = "Mutex exists but was abandoned"
                Write-SystemStatusLog "Mutex for $SubsystemName was abandoned" -Level 'WARN'
                
                # Release the abandoned mutex we just acquired
                $mutex.ReleaseMutex()
            }
        }
        catch [System.Threading.WaitHandleCannotBeOpenedException] {
            # Mutex doesn't exist
            $result.Exists = $false
            $result.IsHeld = $false
            $result.Message = "Mutex does not exist"
            Write-SystemStatusLog "Mutex does not exist for $SubsystemName" -Level 'TRACE'
        }
    }
    catch {
        Write-SystemStatusLog "Error testing mutex for ${SubsystemName}: $_" -Level 'ERROR'
        $result.Message = "Error: $_"
    }
    finally {
        # Clean up
        if ($mutex) {
            try {
                $mutex.Dispose()
            } catch {
                Write-SystemStatusLog "Error disposing mutex in test: $_" -Level 'TRACE'
            }
        }
    }
    
    return $result
}

function Remove-SubsystemMutex {
    <#
    .SYNOPSIS
    Releases and disposes a subsystem mutex.
    
    .DESCRIPTION
    Properly releases and disposes a mutex object to prevent resource leaks.
    Handles cases where the mutex may not be owned by the current thread.
    
    .PARAMETER MutexObject
    The mutex object to release and dispose.
    
    .PARAMETER SubsystemName
    Optional name of the subsystem for logging purposes.
    
    .EXAMPLE
    Remove-SubsystemMutex -MutexObject $mutexResult.Mutex -SubsystemName "AutonomousAgent"
    #>
    
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [System.Threading.Mutex]$MutexObject,
        
        [Parameter()]
        [string]$SubsystemName = "Unknown"
    )
    
    Write-SystemStatusLog "Releasing mutex for subsystem: $SubsystemName" -Level 'DEBUG'
    
    if (-not $MutexObject) {
        Write-SystemStatusLog "Mutex object is null, nothing to release" -Level 'TRACE'
        return
    }
    
    try {
        # Try to release the mutex
        # This will throw if we don't own it
        $MutexObject.ReleaseMutex()
        Write-SystemStatusLog "Successfully released mutex for $SubsystemName" -Level 'OK'
    }
    catch [System.ApplicationException] {
        # This happens if we try to release a mutex we don't own
        Write-SystemStatusLog "Cannot release mutex for $SubsystemName - not owned by current thread" -Level 'DEBUG'
    }
    catch {
        Write-SystemStatusLog "Error releasing mutex for ${SubsystemName}: $_" -Level 'ERROR'
    }
    
    try {
        # Dispose the mutex object to free resources
        $MutexObject.Dispose()
        Write-SystemStatusLog "Successfully disposed mutex object for $SubsystemName" -Level 'TRACE'
    }
    catch {
        Write-SystemStatusLog "Error disposing mutex for ${SubsystemName}: $_" -Level 'ERROR'
    }
}

# Functions are exported by the module manifest
# SIG # Begin signature block
# MIIFqQYJKoZIhvcNAQcCoIIFmjCCBZYCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUUqvXs/0wY5OeJMRKSZjkrs5Y
# UR6gggMwMIIDLDCCAhSgAwIBAgIQdR0W2SKoK5VE8JId4ZxrRTANBgkqhkiG9w0B
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
# CQQxFgQUHH+6/B2ZSAnzeO+Sc7Nb6+abyDYwDQYJKoZIhvcNAQEBBQAEggEAjXEd
# Hu3vOzMxi7YUUehRzew/q/IRlLGOHB4VMAt+5sf+hrz960vJ5QvvCHc8JbGpKx5s
# TBbmGMrX7pLqhNMzNlI1TD1iMc0xHjHEzljTIljLRM5oqTl2PWbVFyDfnLjfr9tE
# vHq6QdT8z+gXuduvFjdAolWDHGCn3Ownkf46sLPjfavLnCk/Z1QPOfW2dzJix2dV
# t6Ai/cES+SgeKgLvkrRGhbY6s0EMUaotiJE5EC7NdonMwnFsaiohq8FQUCbTPZpO
# 6xkDB03pY1q1EuYjoEz5+6YozNavcBe/pJi7PAKNLRDQcLJ8Y7907XlN2BoMzn82
# 6Sb0+A6/o3DQVF0nUg==
# SIG # End signature block
