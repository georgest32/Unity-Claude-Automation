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
                    FilePath = "C:\Program Files\PowerShell\7\pwsh.exe"
                }
                
                if ($manifestData.WorkingDirectory) {
                    $startParams.WorkingDirectory = $manifestData.WorkingDirectory
                    # Convert script path to absolute path for proper resolution
                    $absoluteScriptPath = $startScriptPath
                    if (-not [System.IO.Path]::IsPathRooted($absoluteScriptPath)) {
                        $absoluteScriptPath = Join-Path $manifestData.WorkingDirectory $startScriptPath
                    }
                    
                    # Create a command that sets working directory and PSModulePath before executing script
                    $workDir = $manifestData.WorkingDirectory
                    $modulesPath = Join-Path $workDir "Modules"
                    $command = @"
Set-Location -Path '$workDir'
`$env:PSModulePath = '$modulesPath;' + `$env:PSModulePath
Write-Host 'WebhookNotificationService PWD:' `$PWD.Path
Write-Host 'WebhookNotificationService PSModulePath:' (`$env:PSModulePath -split ';' | Select-Object -First 3)
& '$absoluteScriptPath'
"@
                    $startParams.ArgumentList = "-ExecutionPolicy Bypass -NoProfile -Command `"$command`""
                } else {
                    $startParams.ArgumentList = "-ExecutionPolicy Bypass -File `"$startScriptPath`""
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
# MIIFzgYJKoZIhvcNAQcCoIIFvzCCBbsCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCDoVXha9mKfgbdp
# 6KKTTrgJWMV4mX9rWSFMGfj2/cFI3aCCAzAwggMsMIICFKADAgECAhB1HRbZIqgr
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
# MAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIKrelgShWnF8dow9x7u60Iee
# al2aDF/LvxPdUIwNTWo7MA0GCSqGSIb3DQEBAQUABIIBAEomUD8Tel21Y8SH+DFe
# Qn880+r8LFRfqVgbIbNxMJf/EnLm25/4wCS3ZokhDn1KlnwMMdCkoxr1HzWmT184
# 8ldHwRBlylCa7s6QKBqsFEHABOtrqQ9SlqgOg4DZbo+2KqXnZzMSTq9h6S79ITHZ
# i0Alzoraxx644GlFodiO3drpXm6XIK4ttuG6oCqC2JQyRBPmUNyqWCY2tw8Gnc0E
# VHwbPMjcqkkZCSEgLYVMMagwrMhIiuHvjdO3nL0sqdrHt3Zb3QfBWXUeUcK9GXia
# 35JE6mkXVyoisbherhz9MqBGlb46I8Ke6X5dJ9K5gDM+XIrbQwFpinSm0ikuZ7gy
# IrE=
# SIG # End signature block
