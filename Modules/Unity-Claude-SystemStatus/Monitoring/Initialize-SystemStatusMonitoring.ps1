
function Initialize-SystemStatusMonitoring {
    <#
    .SYNOPSIS
    Initializes system status monitoring with manifest-driven subsystem discovery and dependency resolution.
    
    .DESCRIPTION
    Enhanced initialization supporting both legacy hardcoded subsystems and new manifest-based
    configuration with intelligent startup sequencing and parallel execution capabilities.
    
    .PARAMETER ProjectPath
    Root path for the Unity-Claude-Automation project.
    
    .PARAMETER EnableCommunication
    Enable cross-subsystem communication features.
    
    .PARAMETER EnableFileWatcher
    Enable real-time file monitoring capabilities.
    
    .PARAMETER UseManifestDrivenStartup
    Use manifest-based subsystem discovery and dependency resolution (recommended).
    
    .PARAMETER EnableParallelStartup
    Enable parallel subsystem startup where dependencies allow.
    
    .PARAMETER StartupAlgorithm
    Algorithm for dependency resolution: 'DFS' or 'Kahn'.
    
    .PARAMETER LegacyCompatibility
    Force use of legacy hardcoded subsystem initialization.
    #>
    [CmdletBinding()]
    param(
        [string]$ProjectPath = "C:\UnityProjects\Sound-and-Shoal\Unity-Claude-Automation",
        
        [switch]$EnableCommunication = $false,  # Default to false to prevent crashes
        
        [switch]$EnableFileWatcher = $false,    # Default to false to prevent crashes
        
        [switch]$UseManifestDrivenStartup = $true,  # New manifest-based approach
        
        [switch]$EnableParallelStartup = $false,  # Parallel startup capability
        
        [ValidateSet('DFS', 'Kahn')]
        [string]$StartupAlgorithm = 'Kahn',  # Default to Kahn for better parallel detection
        
        [switch]$LegacyCompatibility = $false  # Force legacy mode
    )
    
    Write-SystemStatusLog "Initializing System Status Monitoring..." -Level 'INFO'
    Write-SystemStatusLog "Mode: $(if ($UseManifestDrivenStartup -and -not $LegacyCompatibility) { 'Manifest-Driven' } else { 'Legacy' }), Parallel: $EnableParallelStartup, Algorithm: $StartupAlgorithm" -Level 'DEBUG'
    
    try {
        # Update system info with current data
        $script:SystemStatusData.SystemInfo.HostName = $env:COMPUTERNAME
        $script:SystemStatusData.SystemInfo.SystemUptime = Get-SystemUptime
        
        # Choose initialization approach
        if ($UseManifestDrivenStartup -and -not $LegacyCompatibility) {
            # New manifest-driven approach
            $initResult = Initialize-SubsystemsFromManifests -ProjectPath $ProjectPath -EnableParallelStartup:$EnableParallelStartup -Algorithm $StartupAlgorithm
            
            if (-not $initResult.Success) {
                Write-SystemStatusLog "Manifest-driven initialization failed: $($initResult.Error). Falling back to legacy mode." -Level 'WARN'
                $initResult = Initialize-SubsystemsLegacy
            } else {
                Write-SystemStatusLog "Manifest-driven initialization completed: $($initResult.SubsystemsInitialized) subsystems in $($initResult.ExecutionTime)s" -Level 'INFO'
            }
        } else {
            # Legacy hardcoded approach  
            Write-SystemStatusLog "Using legacy hardcoded subsystem initialization" -Level 'INFO'
            $initResult = Initialize-SubsystemsLegacy
        }
        
        if (-not $initResult.Success) {
            Write-SystemStatusLog "Subsystem initialization failed: $($initResult.Error)" -Level 'ERROR'
            return $false
        }
        
        # Initialize communication features if enabled (Hour 2.5 Enhanced)
        if ($EnableCommunication) {
            Write-SystemStatusLog "Initializing Hour 2.5 Cross-Subsystem Communication Protocol..." -Level 'INFO'
            
            # Initialize cross-module engine events first
            $engineEventResult = Initialize-CrossModuleEvents
            if ($engineEventResult) {
                Write-SystemStatusLog "Cross-module engine events initialized" -Level 'OK'
            }
            
            # Try to initialize named pipe server with research-validated patterns
            $namedPipeResult = Initialize-NamedPipeServer -PipeName $script:SystemStatusConfig.NamedPipeName -TimeoutSeconds 30
            if ($namedPipeResult) {
                Write-SystemStatusLog "Research-validated named pipe communication enabled" -Level 'OK'
            } else {
                Write-SystemStatusLog "Using JSON fallback communication (research-validated patterns)" -Level 'WARN'
            }
            
            # Start background message processor
            $processorResult = Start-MessageProcessor
            if ($processorResult) {
                Write-SystemStatusLog "Background message processor started" -Level 'OK'
            }
            
            # Register default message handlers
            Register-MessageHandler -MessageType "HeartbeatRequest" -Handler {
                param($Message)
                Write-SystemStatusLog "Processing heartbeat request from: $($Message.source)" -Level 'DEBUG'
                
                # Send heartbeat response
                $responseMessage = New-SystemStatusMessage -MessageType "StatusUpdate" -Source "Unity-Claude-SystemStatus" -Target $Message.source
                $responseMessage.payload = @{
                    status = "Healthy"
                    timestamp = (Get-Date).psobject.BaseObject
                    respondingTo = $Message.correlationId
                    healthScore = 1.0
                }
                Send-SystemStatusMessage -Message $responseMessage | Out-Null
            }
            
            Register-MessageHandler -MessageType "HealthCheck" -Handler {
                param($Message)
                Write-SystemStatusLog "Processing health check request from: $($Message.source)" -Level 'DEBUG'
                
                # Perform comprehensive health check
                $healthResults = Test-AllSubsystemHeartbeats
                
                $responseMessage = New-SystemStatusMessage -MessageType "StatusUpdate" -Source "Unity-Claude-SystemStatus" -Target $Message.source
                $responseMessage.payload = @{
                    healthCheckResults = $healthResults
                    timestamp = (Get-Date).psobject.BaseObject
                    respondingTo = $Message.correlationId
                }
                Send-SystemStatusMessage -Message $responseMessage | Out-Null
            }
            
            # Start file watcher for real-time updates if enabled
            if ($EnableFileWatcher) {
                $fileWatcherResult = Start-SystemStatusFileWatcher
                if ($fileWatcherResult) {
                    Write-SystemStatusLog "Real-time file monitoring enabled with debouncing" -Level 'OK'
                } else {
                    Write-SystemStatusLog "File monitoring disabled due to initialization error" -Level 'WARN'
                }
            }
        }
        
        # Write initial system status
        $writeResult = Write-SystemStatus -StatusData $script:SystemStatusData
        if ($writeResult) {
            Write-SystemStatusLog "System status monitoring initialized successfully" -Level 'OK'
            return $true
        } else {
            Write-SystemStatusLog "Failed to write initial system status" -Level 'ERROR'
            return $false
        }
        
    } catch {
        Write-SystemStatusLog "Error initializing system status monitoring: $($_.Exception.Message)" -Level 'ERROR'
        return $false
    }
}

function Initialize-SubsystemsFromManifests {
    <#
    .SYNOPSIS
    Initializes subsystems using manifest-driven discovery and dependency resolution.
    #>
    [CmdletBinding()]
    param(
        [string]$ProjectPath,
        [switch]$EnableParallelStartup,
        [string]$Algorithm
    )
    
    $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
    
    try {
        Write-SystemStatusLog "Starting manifest-driven subsystem initialization" -Level 'DEBUG'
        
        # Step 1: Discover manifests
        Write-SystemStatusLog "Discovering subsystem manifests..." -Level 'DEBUG'
        $manifests = Get-SubsystemManifests -Force
        
        if (-not $manifests -or $manifests.Count -eq 0) {
            return @{
                Success = $false
                Error = "No valid manifests found"
                SubsystemsInitialized = 0
                ExecutionTime = $stopwatch.ElapsedMilliseconds / 1000
            }
        }
        
        Write-SystemStatusLog "Found $($manifests.Count) valid manifests" -Level 'INFO'
        
        # Step 2: Calculate startup order
        Write-SystemStatusLog "Calculating startup order..." -Level 'DEBUG'
        $startupPlan = Get-SubsystemStartupOrder -Manifests $manifests -EnableParallelExecution:$EnableParallelStartup -Algorithm $Algorithm -IncludeValidation
        
        if (-not $startupPlan.ValidationResults.IsValid) {
            return @{
                Success = $false
                Error = "Manifest validation failed: $($startupPlan.ValidationResults.Errors -join '; ')"
                SubsystemsInitialized = 0
                ExecutionTime = $stopwatch.ElapsedMilliseconds / 1000
            }
        }
        
        Write-SystemStatusLog "Startup plan: $($startupPlan.ExecutionPlan.TotalSubsystems) subsystems, estimated time: $($startupPlan.ExecutionPlan.EstimatedStartupTime)s" -Level 'INFO'
        
        # Step 3: Initialize subsystems according to plan
        $subsystemsInitialized = 0
        
        if ($EnableParallelStartup -and $startupPlan.ParallelGroups.Count -gt 0) {
            # Parallel initialization
            Write-SystemStatusLog "Using parallel subsystem initialization" -Level 'INFO'
            
            foreach ($group in $startupPlan.ParallelGroups) {
                Write-SystemStatusLog "Initializing parallel group: $($group -join ', ')" -Level 'DEBUG'
                
                # Initialize all subsystems in this group
                foreach ($subsystemName in $group) {
                    $manifest = $manifests | Where-Object { $_.Name -eq $subsystemName }
                    if ($manifest) {
                        $initSuccess = Initialize-SubsystemFromManifest -Manifest $manifest
                        if ($initSuccess) {
                            $subsystemsInitialized++
                        }
                    }
                }
                
                # Small delay between parallel groups to allow dependencies to stabilize
                Start-Sleep -Milliseconds 500
            }
        } else {
            # Sequential initialization
            Write-SystemStatusLog "Using sequential subsystem initialization" -Level 'INFO'
            
            foreach ($subsystemName in $startupPlan.StartupOrder) {
                Write-SystemStatusLog "Initializing subsystem: $subsystemName" -Level 'DEBUG'
                
                $manifest = $manifests | Where-Object { $_.Name -eq $subsystemName }
                if ($manifest) {
                    $initSuccess = Initialize-SubsystemFromManifest -Manifest $manifest
                    if ($initSuccess) {
                        $subsystemsInitialized++
                    }
                }
                
                # Small delay between subsystems
                Start-Sleep -Milliseconds 200
            }
        }
        
        $stopwatch.Stop()
        
        Write-SystemStatusLog "Manifest-driven initialization completed: $subsystemsInitialized/$($manifests.Count) subsystems initialized" -Level 'INFO'
        
        return @{
            Success = $true
            SubsystemsInitialized = $subsystemsInitialized
            TotalManifests = $manifests.Count
            ExecutionTime = $stopwatch.ElapsedMilliseconds / 1000
            StartupPlan = $startupPlan
        }
        
    } catch {
        $stopwatch.Stop()
        Write-SystemStatusLog "Error in manifest-driven initialization: $($_.Exception.Message)" -Level 'ERROR'
        
        return @{
            Success = $false
            Error = $_.Exception.Message
            SubsystemsInitialized = 0
            ExecutionTime = $stopwatch.ElapsedMilliseconds / 1000
        }
    }
}

function Initialize-SubsystemFromManifest {
    <#
    .SYNOPSIS
    Initializes a single subsystem from its manifest configuration.
    #>
    [CmdletBinding()]
    param(
        [PSCustomObject]$Manifest
    )
    
    try {
        $subsystemName = $Manifest.Name
        Write-SystemStatusLog "Initializing subsystem $subsystemName from manifest" -Level 'DEBUG'
        
        # Create subsystem entry in system status
        $script:SystemStatusData.Subsystems[$subsystemName] = @{
            ProcessId = $null
            Status = "Initializing"
            LastHeartbeat = (Get-Date -Format 'yyyy-MM-dd HH:mm:ss.fff')
            HealthScore = 0.0
            Performance = @{
                CpuPercent = 0.0
                MemoryMB = 0.0
                ResponseTimeMs = 0.0
            }
            ModuleInfo = @{
                Version = $Manifest.Version
                Path = $Manifest.StartScript
                ExportedFunctions = @()
            }
            ManifestInfo = @{
                ManifestPath = $Manifest._ManifestPath
                RestartPolicy = $Manifest.RestartPolicy
                MaxRestarts = $Manifest.MaxRestarts
                ResourceLimits = @{
                    MaxMemoryMB = $Manifest.MaxMemoryMB
                    MaxCpuPercent = $Manifest.MaxCpuPercent
                }
                HealthCheck = @{
                    Function = $Manifest.HealthCheckFunction
                    Interval = $Manifest.HealthCheckInterval
                    Timeout = $Manifest.HealthCheckTimeout
                }
            }
        }
        
        # Set up dependencies from manifest
        $dependencies = @()
        if ($Manifest.DependsOn) {
            $dependencies += $Manifest.DependsOn
        }
        if ($Manifest.RequiredModules) {
            $dependencies += $Manifest.RequiredModules
        }
        $script:SystemStatusData.Dependencies[$subsystemName] = $dependencies | Sort-Object -Unique
        
        Write-SystemStatusLog "Subsystem $subsystemName initialized from manifest v$($Manifest.Version)" -Level 'OK'
        return $true
        
    } catch {
        Write-SystemStatusLog "Error initializing subsystem $($Manifest.Name): $($_.Exception.Message)" -Level 'ERROR'
        return $false
    }
}

function Initialize-SubsystemsLegacy {
    <#
    .SYNOPSIS
    Legacy initialization using hardcoded subsystem definitions.
    #>
    [CmdletBinding()]
    param()
    
    $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
    
    try {
        Write-SystemStatusLog "Using legacy hardcoded subsystem initialization" -Level 'DEBUG'
        
        # Check if CriticalSubsystems exists
        if (-not $script:CriticalSubsystems) {
            $stopwatch.Stop()
            return @{
                Success = $false
                Error = "Legacy CriticalSubsystems not defined"
                SubsystemsInitialized = 0
                ExecutionTime = $stopwatch.ElapsedMilliseconds / 1000
            }
        }
        
        # Initialize subsystems with critical modules
        $subsystemsInitialized = 0
        foreach ($subsystemName in $script:CriticalSubsystems.Keys) {
            $subsystemInfo = $script:CriticalSubsystems[$subsystemName]
            
            $script:SystemStatusData.Subsystems[$subsystemName] = @{
                ProcessId = $null
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
                    Path = $subsystemInfo.Path
                    ExportedFunctions = @()
                }
            }
            
            # Set up dependencies
            $script:SystemStatusData.Dependencies[$subsystemName] = $subsystemInfo.Dependencies
            $subsystemsInitialized++
        }
        
        $stopwatch.Stop()
        
        Write-SystemStatusLog "Legacy initialization completed: $subsystemsInitialized subsystems initialized" -Level 'INFO'
        
        return @{
            Success = $true
            SubsystemsInitialized = $subsystemsInitialized
            ExecutionTime = $stopwatch.ElapsedMilliseconds / 1000
        }
        
    } catch {
        $stopwatch.Stop()
        Write-SystemStatusLog "Error in legacy initialization: $($_.Exception.Message)" -Level 'ERROR'
        
        return @{
            Success = $false
            Error = $_.Exception.Message
            SubsystemsInitialized = 0
            ExecutionTime = $stopwatch.ElapsedMilliseconds / 1000
        }
    }
}
# SIG # Begin signature block
# MIIFqQYJKoZIhvcNAQcCoIIFmjCCBZYCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUTfCdQrYozpV4IkHcr4KutEXP
# pBOgggMwMIIDLDCCAhSgAwIBAgIQdR0W2SKoK5VE8JId4ZxrRTANBgkqhkiG9w0B
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
# CQQxFgQUuL+QtYVzx5Z5+DcdVKpAMm+FAUIwDQYJKoZIhvcNAQEBBQAEggEAImX3
# XBEAXIHPA3X9NmLlByYMqKYIOTT/tawfrwRMDD837J4RuuDGZkq8WuEkqfBGq2Gq
# 9rv+GAXfFr5PpGjAF/+NkJpiEqBjw2vcLPnKnGKuzt+q3qHSz9E9rmao5jAGts4J
# JCaevq+azVTBJyJAb6gIP1Fb35e408hHUEbzMTuqexZ0apy0jo/i5iLp3uthRkIK
# PklXK9RgUL3OY3Igr+FIaufnkUQKbNplGQ4WhHyZJWyclUubiR2K+Blvp9HJS3of
# HalmN/CTQJjm1p279BrcsnJPwOhvDoGNwnxIUPgotZ1CJs423wPEd2NwfS+5V+eL
# MunbZag4g76p2RsNpQ==
# SIG # End signature block
