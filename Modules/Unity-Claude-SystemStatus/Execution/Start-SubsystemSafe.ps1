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
# MIIFzgYJKoZIhvcNAQcCoIIFvzCCBbsCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCBGOyotaiwTjiUV
# DmWsbWXPql6bwzBzxJnE728pgehxmaCCAzAwggMsMIICFKADAgECAhB1HRbZIqgr
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
# MAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIEk7KzN0D+QH9fCoYooeuv/0
# RTuD0AVreWZ9w8YE2jLbMA0GCSqGSIb3DQEBAQUABIIBAH13UgjYkuxqEae2uXmf
# 8NPf9AHFie6gJaohJ0JArQ38+MPSz47B9O2yO42JKZrsEK6YguQzfnAUiPxpFC6r
# N+N4OWAGJ7KhfLCXYi225vyDT1kenjkEAvapyAx/H40KRtBG/WRLl3cP0pUCNzDj
# MFsz6Wua9YFxMfxiTItBRN9AtxApwipNg7hmGdBP4MeflbcU1LooMGKV0I42HIWS
# 8hMXTlWk2mPVy3eN90O5RXz03/YN7yrEIJID11wlfVrivVQOg1cXvyVJUgKWv/9a
# 8cbDSQRix0DIR5HDchwdsuM1/HeR3dvQRY6mukqD5R1M0kJ4u+Z6T7B2xhiDwJ9o
# IK0=
# SIG # End signature block
