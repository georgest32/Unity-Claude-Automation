function Start-SubsystemSafe {
    <#
    .SYNOPSIS
    Generic subsystem startup with mutex-based singleton enforcement
    
    .DESCRIPTION
    Safely starts any subsystem using manifest configuration:
    - Mutex acquisition for singleton enforcement
    - Process startup from manifest StartScript
    - Self-registration verification with timeout
    - Comprehensive error handling and rollback
    
    .PARAMETER SubsystemName
    Name of the subsystem to start
    
    .PARAMETER Manifest
    Subsystem manifest containing startup configuration
    
    .PARAMETER TimeoutSeconds
    Maximum time to wait for subsystem self-registration (default: 30)
    
    .EXAMPLE
    Start-SubsystemSafe -SubsystemName "AutonomousAgent" -Manifest $manifest
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$SubsystemName,
        
        [Parameter(Mandatory=$true)]
        [hashtable]$Manifest,
        
        [int]$TimeoutSeconds = 30
    )
    
    Write-SystemStatusLog "Starting subsystem: $SubsystemName" -Level 'INFO'
    
    try {
        # Step 1: Acquire mutex for singleton enforcement
        $mutexResult = New-SubsystemMutex -SubsystemName $SubsystemName
        if (-not $mutexResult.Success) {
            Write-SystemStatusLog "Cannot start $SubsystemName - already running (mutex blocked)" -Level 'WARN'
            return @{
                Success = $false
                ProcessId = $null
                ErrorMessage = "Subsystem already running (mutex blocked)"
                MutexAcquired = $false
            }
        }
        
        Write-SystemStatusLog "Mutex acquired for $SubsystemName" -Level 'DEBUG'
        
        try {
            # Step 2: Validate start script exists
            $startScript = $Manifest.StartScript
            if (-not $startScript) {
                throw "No StartScript specified in manifest"
            }
            
            # Convert relative path to absolute if needed
            if (-not [System.IO.Path]::IsPathRooted($startScript)) {
                $startScript = Join-Path $PSScriptRoot "..\..\..\" $startScript
            }
            
            if (-not (Test-Path $startScript)) {
                throw "Start script not found: $startScript"
            }
            
            Write-SystemStatusLog "Starting process: $startScript" -Level 'DEBUG'
            
            # Step 3: Start the subsystem process
            $processArgs = @{
                FilePath = "pwsh.exe"
                ArgumentList = @("-ExecutionPolicy", "Bypass", "-File", $startScript)
                WindowStyle = "Hidden"
                PassThru = $true
            }
            
            $process = Start-Process @processArgs
            
            if (-not $process) {
                throw "Failed to start process"
            }
            
            Write-SystemStatusLog "Process started with PID: $($process.Id)" -Level 'INFO'
            
            # Step 4: Wait for self-registration with timeout
            $startTime = Get-Date
            $registered = $false
            
            while (((Get-Date) - $startTime).TotalSeconds -lt $TimeoutSeconds) {
                Start-Sleep -Seconds 1
                
                # Check if subsystem has registered itself
                $systemStatus = Read-SystemStatus
                if ($systemStatus.Subsystems.ContainsKey($SubsystemName)) {
                    $registeredPid = $systemStatus.Subsystems[$SubsystemName].ProcessId
                    if ($registeredPid -eq $process.Id) {
                        $registered = $true
                        Write-SystemStatusLog "Subsystem $SubsystemName registered successfully" -Level 'INFO'
                        break
                    }
                }
                
                # Check if process is still running
                if ($process.HasExited) {
                    throw "Process exited during startup (Exit Code: $($process.ExitCode))"
                }
            }
            
            if (-not $registered) {
                # Kill the process if it didn't register
                if (-not $process.HasExited) {
                    $process.Kill()
                    $process.WaitForExit(5000)
                }
                throw "Subsystem failed to register within $TimeoutSeconds seconds"
            }
            
            # Step 5: Verify health after startup
            $healthResult = Test-SubsystemStatus -SubsystemName $SubsystemName -Manifest $Manifest
            if (-not $healthResult.OverallHealthy) {
                throw "Health check failed after startup: $($healthResult.ErrorDetails -join '; ')"
            }
            
            Write-SystemStatusLog "Subsystem $SubsystemName started successfully" -Level 'INFO'
            
            return @{
                Success = $true
                ProcessId = $process.Id
                ErrorMessage = $null
                MutexAcquired = $true
                HealthResult = $healthResult
            }
            
        } catch {
            Write-SystemStatusLog "Error starting $SubsystemName`: $($_.Exception.Message)" -Level 'ERROR'
            
            # Clean up on failure
            if ($process -and -not $process.HasExited) {
                try {
                    $process.Kill()
                    $process.WaitForExit(5000)
                    Write-SystemStatusLog "Cleaned up failed process $($process.Id)" -Level 'DEBUG'
                } catch {
                    Write-SystemStatusLog "Could not clean up process: $($_.Exception.Message)" -Level 'WARN'
                }
            }
            
            return @{
                Success = $false
                ProcessId = $null
                ErrorMessage = $_.Exception.Message
                MutexAcquired = $true
            }
        }
        
    } finally {
        # Release mutex on failure (success case keeps it acquired)
        if ($mutexResult.Success -and -not $registered) {
            try {
                Remove-SubsystemMutex -SubsystemName $SubsystemName
                Write-SystemStatusLog "Released mutex for failed startup" -Level 'DEBUG'
            } catch {
                Write-SystemStatusLog "Could not release mutex: $($_.Exception.Message)" -Level 'WARN'
            }
        }
    }
}
# SIG # Begin signature block
# MIIFqQYJKoZIhvcNAQcCoIIFmjCCBZYCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQU65octcJ6lin7kDnE+yyHJPYp
# ae6gggMwMIIDLDCCAhSgAwIBAgIQdR0W2SKoK5VE8JId4ZxrRTANBgkqhkiG9w0B
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
# CQQxFgQUCyh3ue2Lc2S4N2u66rilfzO2XLQwDQYJKoZIhvcNAQEBBQAEggEAWk+Q
# FEiWr8JFOw8ZHFUze9felJ6PiA6veELdDYUlV6sqGGFHqi2mK1A8Z4kjVheYd0Mr
# ZuC8HytqP/OkBQOnmREU6FlvNG2yHlcfEt8N6EMdM+apxWXAwSEW/DFLTFz0ecRN
# S6My+Mrn76w5Z4JmHWxO9nyfpgv0r6FmqJmL2YZglVUESp0TXyjFXkOQNdLe/gUC
# Un66c6OKf9Jr+57T2lsp1nDIOebSYKK61sVUlv1RDcG64qSiI48JSsfHNxCI8pZ7
# UFNcqygpS0jAcbty9nc0tTYq/m4d/c5AsqNZvbVoUKSw8k2rfmHCcSW57D5bY7oS
# 8H9GZ2it/7UmMHhK6g==
# SIG # End signature block

