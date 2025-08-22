function Register-SubsystemFromManifest {
    <#
    .SYNOPSIS
    Registers a subsystem using configuration from a manifest file.
    
    .DESCRIPTION
    Loads a subsystem manifest, validates it, and registers the subsystem
    with all configured settings including mutex enforcement, health checks,
    and resource limits.
    
    .PARAMETER ManifestPath
    Path to the manifest file.
    
    .PARAMETER Manifest
    A manifest object returned from Get-SubsystemManifests.
    
    .PARAMETER ProcessId
    Optional process ID to register. If not provided, will start the subsystem.
    
    .PARAMETER Force
    Force registration even if validation warnings exist.
    
    .EXAMPLE
    Register-SubsystemFromManifest -ManifestPath ".\AutonomousAgent.manifest.psd1"
    
    .EXAMPLE
    Get-SubsystemManifests | Where-Object Name -eq "AutonomousAgent" | Register-SubsystemFromManifest
    #>
    
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, ParameterSetName = 'Path')]
        [string]$ManifestPath,
        
        [Parameter(Mandatory = $true, ParameterSetName = 'Object', ValueFromPipeline = $true)]
        [PSCustomObject]$Manifest,
        
        [Parameter()]
        [int]$ProcessId,
        
        [Parameter()]
        [switch]$Force
    )
    
    Process {
        Write-SystemStatusLog "Registering subsystem from manifest" -Level 'INFO'
        
        # Load and validate manifest if path provided
        if ($PSCmdlet.ParameterSetName -eq 'Path') {
            if (-not (Test-Path $ManifestPath)) {
                Write-SystemStatusLog "Manifest file not found: $ManifestPath" -Level 'ERROR'
                throw "Manifest file not found: $ManifestPath"
            }
            
            # Validate manifest
            $validation = Test-SubsystemManifest -Path $ManifestPath
            if (-not $validation.IsValid) {
                Write-SystemStatusLog "Manifest validation failed: $($validation.Errors -join '; ')" -Level 'ERROR'
                throw "Manifest validation failed: $($validation.Errors -join '; ')"
            }
            
            if ($validation.Warnings.Count -gt 0 -and -not $Force) {
                Write-SystemStatusLog "Manifest has warnings: $($validation.Warnings -join '; ')" -Level 'WARN'
                Write-Warning "Manifest has warnings. Use -Force to register anyway."
                return
            }
            
            $manifestData = $validation.ManifestData
            $manifestDir = Split-Path $ManifestPath -Parent
        } else {
            # Use provided manifest object
            if (-not $Manifest.IsValid -and -not $Force) {
                Write-SystemStatusLog "Manifest is not valid: $($Manifest.Errors -join '; ')" -Level 'ERROR'
                throw "Manifest is not valid: $($Manifest.Errors -join '; ')"
            }
            
            $manifestData = $Manifest.Data
            $manifestDir = $Manifest.Directory
        }
        
        $subsystemName = $manifestData.Name
        Write-SystemStatusLog "Registering subsystem: $subsystemName" -Level 'INFO'
        
        # Handle mutex if configured
        $mutexAcquired = $false
        $mutexObject = $null
        
        # Check if mutex is configured (either UseMutex flag or MutexName specified)
        if ($manifestData.UseMutex -or $manifestData.MutexName) {
            $mutexName = if ($manifestData.MutexName) { 
                $manifestData.MutexName 
            } else { 
                "Global\UnityClaudeSubsystem_$subsystemName" 
            }
            
            $mutexTimeout = if ($manifestData.MutexTimeout) { 
                $manifestData.MutexTimeout 
            } else { 
                5000 
            }
            
            Write-SystemStatusLog "Attempting to acquire mutex: $mutexName" -Level 'DEBUG'
            
            # Try to acquire mutex
            $mutexResult = New-SubsystemMutex -SubsystemName $subsystemName -MutexName $mutexName -TimeoutMs $mutexTimeout
            
            if ($mutexResult.Acquired) {
                $mutexAcquired = $true
                $mutexObject = $mutexResult.Mutex
                Write-SystemStatusLog "Mutex acquired for $subsystemName" -Level 'OK'
                
                # Store mutex in script scope for lifetime management
                if (-not $script:SubsystemMutexes) {
                    $script:SubsystemMutexes = @{}
                }
                $script:SubsystemMutexes[$subsystemName] = $mutexObject
                
            } else {
                Write-SystemStatusLog "Failed to acquire mutex for ${subsystemName}: $($mutexResult.Message)" -Level 'ERROR'
                
                if ($manifestData.KillExistingOnConflict) {
                    Write-SystemStatusLog "Attempting to kill existing instance" -Level 'WARN'
                    
                    # Try to find and kill existing process
                    $statusData = Read-SystemStatus
                    if ($statusData.subsystems.ContainsKey($subsystemName)) {
                        $existingPid = $statusData.subsystems[$subsystemName].ProcessId
                        if ($existingPid) {
                            try {
                                Stop-Process -Id $existingPid -Force
                                Write-SystemStatusLog "Killed existing process: $existingPid" -Level 'WARN'
                                Start-Sleep -Milliseconds 500
                                
                                # Try again
                                $mutexResult = New-SubsystemMutex -SubsystemName $subsystemName -MutexName $mutexName -TimeoutMs $mutexTimeout
                                if ($mutexResult.Acquired) {
                                    $mutexAcquired = $true
                                    $mutexObject = $mutexResult.Mutex
                                    $script:SubsystemMutexes[$subsystemName] = $mutexObject
                                }
                            } catch {
                                Write-SystemStatusLog "Failed to kill existing process: $_" -Level 'ERROR'
                            }
                        }
                    }
                }
                
                if (-not $mutexAcquired) {
                    # Don't throw - just log and return a "skipped" status
                    Write-SystemStatusLog "Subsystem $subsystemName appears to be already running (mutex held)" -Level 'WARN'
                    return @{
                        Success = $false
                        Skipped = $true
                        SubsystemName = $subsystemName
                        Message = "Subsystem already running (mutex held by another process)"
                    }
                }
            }
        }
        
        # Start process if no PID provided
        if (-not $ProcessId) {
            if ($manifestData.StartScript) {
                $startScriptPath = if ([System.IO.Path]::IsPathRooted($manifestData.StartScript)) {
                    $manifestData.StartScript
                } else {
                    # Resolve relative paths from project root, not manifest directory
                    # Get project root (parent of Manifests directory)
                    $projectRoot = Split-Path $manifestDir -Parent
                    $testPath = Join-Path $projectRoot $manifestData.StartScript
                    
                    # If the script exists relative to project root, use that
                    if (Test-Path $testPath) {
                        $testPath
                    } else {
                        # Fall back to manifest directory (for backward compatibility)
                        Join-Path $manifestDir $manifestData.StartScript
                    }
                }
                
                if (-not (Test-Path $startScriptPath)) {
                    Write-SystemStatusLog "Start script not found: $startScriptPath" -Level 'ERROR'
                    
                    # Release mutex if acquired
                    if ($mutexAcquired -and $mutexObject) {
                        Remove-SubsystemMutex -SubsystemName $subsystemName
                    }
                    
                    throw "Start script not found: $startScriptPath"
                }
                
                Write-SystemStatusLog "Starting subsystem with script: $startScriptPath" -Level 'INFO'
                
                # Prepare start parameters
                $startParams = @{
                    FilePath = "powershell.exe"
                    ArgumentList = "-ExecutionPolicy Bypass -File `"$startScriptPath`""
                }
                
                if ($manifestData.WorkingDirectory) {
                    $startParams.WorkingDirectory = $manifestData.WorkingDirectory
                }
                
                if ($manifestData.WindowStyle) {
                    $startParams.WindowStyle = $manifestData.WindowStyle
                }
                
                if ($manifestData.RunAsJob) {
                    # Start as job
                    $job = Start-Job -ScriptBlock {
                        param($Path, $WorkDir)
                        if ($WorkDir) { Set-Location $WorkDir }
                        & $Path
                    } -ArgumentList $startScriptPath, $manifestData.WorkingDirectory
                    
                    $ProcessId = $job.Id
                    Write-SystemStatusLog "Started subsystem as job: $ProcessId" -Level 'OK'
                } else {
                    # Start as process
                    $process = Start-Process @startParams -PassThru
                    $ProcessId = $process.Id
                    Write-SystemStatusLog "Started subsystem process: $ProcessId" -Level 'OK'
                }
                
                # Wait a moment for process to initialize
                Start-Sleep -Milliseconds 500
            } else {
                Write-SystemStatusLog "No start script defined in manifest" -Level 'WARN'
            }
        }
        
        # Register with standard function (backward compatibility)
        try {
            # Use start script as module path, or a default if not available
            $modulePath = if ($manifestData.StartScript) {
                $manifestData.StartScript
            } else {
                # Default to a placeholder path for subsystems without scripts
                ".\Modules\Unity-Claude-$subsystemName\Unity-Claude-$subsystemName.psm1"
            }
            
            Register-Subsystem -SubsystemName $subsystemName -ModulePath $modulePath -ProcessId $ProcessId
            
            # Update registration with manifest data
            $statusData = Read-SystemStatus
            if ($statusData.subsystems.ContainsKey($subsystemName)) {
                # Add manifest-specific data
                $statusData.subsystems[$subsystemName].ManifestPath = if ($ManifestPath) { $ManifestPath } else { $Manifest.Path }
                $statusData.subsystems[$subsystemName].ManifestVersion = $manifestData.Version
                $statusData.subsystems[$subsystemName].RestartPolicy = $manifestData.RestartPolicy
                $statusData.subsystems[$subsystemName].MaxRestarts = $manifestData.MaxRestarts
                $statusData.subsystems[$subsystemName].ResourceLimits = @{
                    MaxMemoryMB = $manifestData.MaxMemoryMB
                    MaxCpuPercent = $manifestData.MaxCpuPercent
                    EnforceResourceLimits = $manifestData.EnforceResourceLimits
                }
                $statusData.subsystems[$subsystemName].HealthCheck = @{
                    Function = $manifestData.HealthCheckFunction
                    Interval = $manifestData.HealthCheckInterval
                    Timeout = $manifestData.HealthCheckTimeout
                }
                $statusData.subsystems[$subsystemName].CustomProperties = $manifestData.CustomProperties
                
                Write-SystemStatus -StatusData $statusData
                Write-SystemStatusLog "Updated subsystem registration with manifest data" -Level 'DEBUG'
            }
            
            Write-SystemStatusLog "Successfully registered subsystem $subsystemName from manifest" -Level 'OK'
            
            return @{
                Success = $true
                SubsystemName = $subsystemName
                ProcessId = $ProcessId
                MutexAcquired = $mutexAcquired
                ManifestVersion = $manifestData.Version
            }
            
        } catch {
            Write-SystemStatusLog "Failed to register subsystem: $_" -Level 'ERROR'
            
            # Release mutex if acquired
            if ($mutexAcquired -and $mutexObject) {
                Remove-SubsystemMutex -SubsystemName $subsystemName
            }
            
            throw
        }
    }
}
# SIG # Begin signature block
# MIIFqQYJKoZIhvcNAQcCoIIFmjCCBZYCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQU8MtB7rpzsSyQPlc1Fy1+/hAk
# 3SCgggMwMIIDLDCCAhSgAwIBAgIQdR0W2SKoK5VE8JId4ZxrRTANBgkqhkiG9w0B
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
# CQQxFgQU/LmlVQtUOzEjEbfodOtuxedgE/4wDQYJKoZIhvcNAQEBBQAEggEAIlxK
# bpnCCe/HEQRdN7vVOOihG1I9+TVtDkcqznOyd3CJRhhKCJ+s4lCbVRYXMrVnK/xC
# 3IBojd54I0yKvK26hrYyb+44lMY6DGq5tAViD7jD8uF6xwvqNWQfuRQlnnDzpsAN
# jB2hyKf3xuqT39rXih90ynpNO9GpR9g4cuwFVlzMpSotiXMi++H97QClRrA8KumV
# QVvnLVMqBKaAsvKsB1YDihTQGHFrZ2SjpVrVIy3U4ug9LvS6kFAdSdtxn4Y8schW
# /6Kwj8nGDfEbK/guTM8Wj5asM+M5BiE+LHzTDPceo8xr13boikSJsTzsMupuEF0a
# xXMCazqdOrE51mkrDw==
# SIG # End signature block
