
function Register-Subsystem {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$SubsystemName,
        
        [Parameter(Mandatory)]
        [string]$ModulePath,
        
        [string[]]$Dependencies = @(),
        
        [ValidateSet("Minimal", "Standard", "Comprehensive", "Intensive")]
        [string]$HealthCheckLevel = "Standard",
        
        [int]$RestartPriority = 10,
        
        [hashtable]$StatusData = $script:SystemStatusData,
        
        [int]$ProcessId = $PID  # Optional: specify the PID of the registering process
    )
    
    Write-SystemStatusLog "Registering subsystem: $SubsystemName" -Level 'INFO'
    
    # Ensure configuration is initialized
    if (-not $script:SystemStatusConfig) {
        Initialize-SystemStatusConfig
    }
    
    try {
        # Build on existing module loading patterns from Integration Engine
        # Convert relative path to absolute if needed
        if (-not [System.IO.Path]::IsPathRooted($ModulePath)) {
            $ModulePath = [System.IO.Path]::GetFullPath($ModulePath)
        }
        
        if (-not (Test-Path $ModulePath)) {
            Write-SystemStatusLog "Module path not found: $ModulePath" -Level 'ERROR'
            return $false
        }
        
        # CRITICAL: Read current status from file to check for duplicates
        # This ensures we see registrations from other processes
        $currentFileStatus = Read-SystemStatus
        if ($currentFileStatus) {
            $StatusData = $currentFileStatus
            Write-SystemStatusLog "Loaded current status from file for duplicate check" -Level 'DEBUG'
        }
        
        # Initialize subsystem entry in status data (ensure subsystems hashtable exists)
        if (-not $StatusData.ContainsKey("subsystems")) {
            $StatusData["subsystems"] = @{}
        }
        
        # ENHANCED: Use mutex-based singleton enforcement for critical subsystems
        $mutexResult = $null
        $useMutex = $false
        
        # Determine if this subsystem should use mutex enforcement
        # For now, we'll use it for AutonomousAgent, but this can be expanded
        if ($SubsystemName -eq "AutonomousAgent") {
            $useMutex = $true
            Write-SystemStatusLog "Using mutex-based singleton enforcement for $SubsystemName" -Level 'INFO'
            
            # Try to acquire mutex for this subsystem
            $mutexResult = New-SubsystemMutex -SubsystemName $SubsystemName -TimeoutMs 1000
            
            if (-not $mutexResult.Acquired) {
                Write-SystemStatusLog "MUTEX PREVENTION: Cannot register $SubsystemName - mutex held by another process" -Level 'WARN'
                Write-SystemStatusLog "Mutex status: $($mutexResult.Message)" -Level 'DEBUG'
                
                # Check if we should kill the existing process
                if ($StatusData.subsystems.ContainsKey($SubsystemName)) {
                    $existingSubsystem = $StatusData.subsystems[$SubsystemName]
                    $existingPID = if ($existingSubsystem.ProcessId) { $existingSubsystem.ProcessId } else { $existingSubsystem.process_id }
                    
                    if ($existingPID) {
                        Write-SystemStatusLog "Attempting to kill existing process (PID: $existingPID) to claim mutex..." -Level 'WARN'
                        try {
                            Stop-Process -Id $existingPID -Force -ErrorAction Stop
                            Write-SystemStatusLog "Successfully killed existing process" -Level 'INFO'
                            Start-Sleep -Milliseconds 1000
                            
                            # Try to acquire mutex again
                            $mutexResult = New-SubsystemMutex -SubsystemName $SubsystemName -TimeoutMs 5000
                            if (-not $mutexResult.Acquired) {
                                Write-SystemStatusLog "Still cannot acquire mutex after killing process" -Level 'ERROR'
                                return $false
                            }
                        } catch {
                            Write-SystemStatusLog "Failed to kill existing process: $_" -Level 'ERROR'
                            return $false
                        }
                    }
                } else {
                    Write-SystemStatusLog "Another instance holds the mutex but is not registered - cannot proceed" -Level 'ERROR'
                    return $false
                }
            }
            
            Write-SystemStatusLog "Successfully acquired mutex for $SubsystemName" -Level 'OK'
        }
        
        # FALLBACK: Original PID-based checking for non-mutex subsystems or as secondary check
        if ($StatusData.subsystems.ContainsKey($SubsystemName)) {
            $existingSubsystem = $StatusData.subsystems[$SubsystemName]
            $existingPID = if ($existingSubsystem.ProcessId) { $existingSubsystem.ProcessId } else { $existingSubsystem.process_id }
            
            if ($existingPID -and $existingPID -ne $ProcessId) {
                # Check if the registered process is still alive
                $existingProcess = Get-Process -Id $existingPID -ErrorAction SilentlyContinue
                if ($existingProcess) {
                    Write-SystemStatusLog "PID CHECK: Active $SubsystemName already running (PID: $existingPID)" -Level 'WARN'
                    
                    if (-not $useMutex) {
                        # Only kill if we're not using mutex (mutex already handled this)
                        Write-SystemStatusLog "Killing existing process to prevent duplicates..." -Level 'WARN'
                        try {
                            Stop-Process -Id $existingPID -Force
                            Write-SystemStatusLog "Successfully killed existing process (PID: $existingPID)" -Level 'INFO'
                            Start-Sleep -Milliseconds 500
                        } catch {
                            Write-SystemStatusLog "Failed to kill existing process: $_" -Level 'ERROR'
                        }
                    }
                } else {
                    Write-SystemStatusLog "Previous registration found but process $existingPID is dead - proceeding" -Level 'INFO'
                }
            } elseif ($existingPID -eq $ProcessId) {
                Write-SystemStatusLog "Re-registering same $SubsystemName (PID: $ProcessId)" -Level 'DEBUG'
            }
        }
        $StatusData.subsystems[$SubsystemName] = @{
            ProcessId = $ProcessId
            Status = "Unknown"
            LastHeartbeat = (Get-Date -Format 'yyyy-MM-dd HH:mm:ss.fff')
            HealthScore = 0.0
            Performance = @{
                CpuPercent = 0.0
                MemoryMB = 0.0
                ResponseTimeMs = 0.0
            }
            ModuleInfo = @{
                Version = "1.0.0"
                Path = $ModulePath
                ExportedFunctions = @()
            }
            # Store mutex info if we're using mutex enforcement
            MutexInfo = if ($mutexResult -and $mutexResult.Acquired) {
                @{
                    HasMutex = $true
                    MutexName = "Global\UnityClaudeSubsystem_$SubsystemName"
                    AcquiredAt = (Get-Date -Format 'yyyy-MM-dd HH:mm:ss.fff')
                }
            } else {
                @{
                    HasMutex = $false
                    MutexName = $null
                    AcquiredAt = $null
                }
            }
        }
        
        # IMPORTANT: Store the mutex object in script scope for cleanup
        # The mutex must be held for the lifetime of the subsystem
        if ($mutexResult -and $mutexResult.Acquired) {
            if (-not $script:SubsystemMutexes) {
                $script:SubsystemMutexes = @{}
            }
            $script:SubsystemMutexes[$SubsystemName] = $mutexResult.Mutex
            Write-SystemStatusLog "Stored mutex reference for $SubsystemName for lifetime management" -Level 'DEBUG'
        }
        
        # Set up dependencies (ensure Dependencies hashtable exists)
        if (-not $StatusData.ContainsKey("Dependencies")) {
            $StatusData["Dependencies"] = @{}
        }
        $StatusData.Dependencies[$SubsystemName] = $Dependencies
        
        # Update critical subsystems registry
        $script:CriticalSubsystems[$SubsystemName] = @{
            Path = $ModulePath
            Dependencies = $Dependencies
            HealthCheckLevel = $HealthCheckLevel
            RestartPriority = $RestartPriority
        }
        
        # Try to get module information
        try {
            if (Get-Module -Name $SubsystemName -ErrorAction SilentlyContinue) {
                $moduleInfo = Get-Module -Name $SubsystemName
                $StatusData.subsystems[$SubsystemName].ModuleInfo.Version = $moduleInfo.Version.ToString()
                $StatusData.subsystems[$SubsystemName].ModuleInfo.ExportedFunctions = @($moduleInfo.ExportedFunctions.Keys)
                
                Write-SystemStatusLog "Retrieved module information for $SubsystemName" -Level 'DEBUG'
            }
        } catch {
            Write-SystemStatusLog "Could not retrieve module information for $SubsystemName - $($_.Exception.Message)" -Level 'WARN'
        }
        
        # Update process information
        Update-SubsystemProcessInfo -SubsystemName $SubsystemName -StatusData $StatusData | Out-Null
        
        # Write updated status data to file
        $writeResult = Write-SystemStatus -StatusData $StatusData
        if ($writeResult) {
            Write-SystemStatusLog "Successfully registered and persisted subsystem: $SubsystemName" -Level 'OK'
        } else {
            Write-SystemStatusLog "Subsystem registered but persistence failed: $SubsystemName" -Level 'WARN'
        }
        
        return $true
        
    } catch {
        Write-SystemStatusLog "Error registering subsystem $SubsystemName - $($_.Exception.Message)" -Level 'ERROR'
        return $false
    }
}
# SIG # Begin signature block
# MIIFqQYJKoZIhvcNAQcCoIIFmjCCBZYCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUGgpW2ngAodWx3SgWEByjNcVi
# wMSgggMwMIIDLDCCAhSgAwIBAgIQdR0W2SKoK5VE8JId4ZxrRTANBgkqhkiG9w0B
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
# CQQxFgQUtd5sImtbiK1yB/CR1yq2Xjc6GQkwDQYJKoZIhvcNAQEBBQAEggEAi64d
# 9xTHCU1GqRox9D9t64MHWBapIzBOnuKwa7ctSxQw1ip63bWCQoH99HtsBYrmWgYC
# YGapH4+pCMB+VjNcdh4t6p97JWFtyX1fLrEQkyZjKsRXdsv2ID18S1oc+l3xFWqO
# 1Q26FPHV2vKjyOp0MPSZ0LMk/7Ipw3rnYQuT0namWWd9lCVw1IoG9jD25/U+L6BH
# uClqeOtbjQWHl4T97h6BkvMRjJ6hflsD9hykSMjjopo7vNvmt3KNwo62abUlXhCC
# YfLWJrFY3X06yl9qp0lIfVOfr2UpDEJ5jS0FQFumsDtTR1l8VGIAellip4ImWD1G
# T3fdYtMvaP02TF7OLw==
# SIG # End signature block
