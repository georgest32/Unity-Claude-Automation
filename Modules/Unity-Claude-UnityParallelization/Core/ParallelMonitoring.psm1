#Requires -Version 5.1
<#
.SYNOPSIS
    Parallel Unity monitoring architecture for UnityParallelization module.

.DESCRIPTION
    Provides parallel monitoring infrastructure using runspace pools
    for multiple Unity project monitoring.

.NOTES
    Part of Unity-Claude-UnityParallelization refactored architecture
    Originally from Unity-Claude-UnityParallelization.psm1 (lines 463-970)
    Refactoring Date: 2025-08-25
#>

# Import required modules
Import-Module "$PSScriptRoot\ParallelizationCore.psm1" -Force
Import-Module "$PSScriptRoot\ProjectConfiguration.psm1" -Force

#region Parallel Unity Monitoring Architecture

function New-UnityParallelMonitor {
    <#
    .SYNOPSIS
    Creates a new Unity parallel monitoring system
    .DESCRIPTION
    Creates parallel Unity monitoring infrastructure using runspace pools for multiple project monitoring
    .PARAMETER MonitorName
    Name for the parallel monitoring system
    .PARAMETER ProjectNames
    Array of registered Unity project names to monitor
    .PARAMETER MaxRunspaces
    Maximum number of runspaces for parallel monitoring
    .PARAMETER EnableResourceMonitoring
    Enable CPU and memory monitoring during parallel operations
    .EXAMPLE
    $monitor = New-UnityParallelMonitor -MonitorName "UnityCompilationMonitor" -ProjectNames @("MyGame1", "MyGame2") -MaxRunspaces 3
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$MonitorName,
        [Parameter(Mandatory)]
        [string[]]$ProjectNames,
        [int]$MaxRunspaces = 3,
        [switch]$EnableResourceMonitoring
    )
    
    Write-UnityParallelLog -Message "Creating Unity parallel monitoring system '$MonitorName'..." -Level "INFO"
    
    try {
        # Debug module availability checking
        Write-UnityParallelLog -Message "DEBUG: Checking module availability..." -Level "DEBUG"
        Write-UnityParallelLog -Message "DEBUG: RequiredModulesAvailable hashtable type: $($script:RequiredModulesAvailable.GetType().Name)" -Level "DEBUG"
        Write-UnityParallelLog -Message "DEBUG: RequiredModulesAvailable contains RunspaceManagement: $($script:RequiredModulesAvailable.ContainsKey('RunspaceManagement'))" -Level "DEBUG"
        
        if ($script:RequiredModulesAvailable.ContainsKey('RunspaceManagement')) {
            Write-UnityParallelLog -Message "DEBUG: RunspaceManagement availability: $($script:RequiredModulesAvailable['RunspaceManagement'])" -Level "DEBUG"
        }
        
        # Validate required modules with hybrid checking (import tracking + actual availability)
        $runspaceModuleAvailable = $false
        
        if ($script:RequiredModulesAvailable.ContainsKey('RunspaceManagement') -and $script:RequiredModulesAvailable['RunspaceManagement']) {
            # Import tracking shows available
            $runspaceModuleAvailable = $true
            Write-UnityParallelLog -Message "DEBUG: RunspaceManagement available via import tracking" -Level "DEBUG"
        } else {
            # Check actual module availability as fallback
            $actualModule = Get-Module -Name Unity-Claude-RunspaceManagement -ErrorAction SilentlyContinue
            if ($actualModule) {
                $runspaceModuleAvailable = $true
                Write-UnityParallelLog -Message "DEBUG: RunspaceManagement available via Get-Module fallback ($($actualModule.ExportedCommands.Count) commands)" -Level "DEBUG"
            }
        }
        
        if (-not $runspaceModuleAvailable) {
            Write-UnityParallelLog -Message "ERROR: Unity-Claude-RunspaceManagement module required but not available" -Level "ERROR"
            throw "Unity-Claude-RunspaceManagement module required but not available"
        }
        
        Write-UnityParallelLog -Message "DEBUG: Module availability check passed" -Level "DEBUG"
        
        # Validate registered projects with debug logging
        Write-UnityParallelLog -Message "DEBUG: Validating $($ProjectNames.Count) project names..." -Level "DEBUG"
        $validProjects = @()
        
        foreach ($projectName in $ProjectNames) {
            Write-UnityParallelLog -Message "DEBUG: Testing availability for project: $projectName" -Level "DEBUG"
            
            try {
                $availability = Test-UnityProjectAvailability -ProjectName $projectName
                Write-UnityParallelLog -Message "DEBUG: Availability result for $projectName : Available: $($availability.Available)" -Level "DEBUG"
                
                if ($availability.Available) {
                    $validProjects += $projectName
                    Write-UnityParallelLog -Message "Project validated for monitoring: $projectName" -Level "DEBUG"
                } else {
                    Write-UnityParallelLog -Message "Project not available for monitoring: $projectName - $($availability.Reason)" -Level "WARNING"
                }
            } catch {
                Write-UnityParallelLog -Message "ERROR: Failed to test project availability for $projectName : $($_.Exception.Message)" -Level "ERROR"
            }
        }
        
        Write-UnityParallelLog -Message "DEBUG: Valid projects count: $($validProjects.Count)" -Level "DEBUG"
        Write-UnityParallelLog -Message "DEBUG: Valid projects: $($validProjects -join ', ')" -Level "DEBUG"
        
        if ($validProjects.Count -eq 0) {
            throw "No valid Unity projects available for monitoring"
        }
        
        # Create session state for Unity monitoring with debug logging
        Write-UnityParallelLog -Message "DEBUG: Creating session state..." -Level "DEBUG"
        
        try {
            $sessionConfig = New-RunspaceSessionState -LanguageMode 'FullLanguage' -ExecutionPolicy 'Bypass'
            Write-UnityParallelLog -Message "DEBUG: Session state created successfully" -Level "DEBUG"
        } catch {
            Write-UnityParallelLog -Message "ERROR: Failed to create session state: $($_.Exception.Message)" -Level "ERROR"
            throw "Failed to create session state: $($_.Exception.Message)"
        }
        
        try {
            Initialize-SessionStateVariables -SessionStateConfig $sessionConfig | Out-Null
            Write-UnityParallelLog -Message "DEBUG: Session state variables initialized" -Level "DEBUG"
        } catch {
            Write-UnityParallelLog -Message "ERROR: Failed to initialize session state variables: $($_.Exception.Message)" -Level "ERROR"
            throw "Failed to initialize session state variables: $($_.Exception.Message)"
        }
        
        # Create shared monitoring state with debug logging
        Write-UnityParallelLog -Message "DEBUG: Creating shared monitoring state..." -Level "DEBUG"
        Write-UnityParallelLog -Message "DEBUG: validProjects type: $($validProjects.GetType().Name), count: $($validProjects.Count)" -Level "DEBUG"
        
        try {
            $monitoringState = [hashtable]::Synchronized(@{
                ActiveProjects = [System.Collections.ArrayList]::Synchronized($validProjects)
                CompilationEvents = [System.Collections.ArrayList]::Synchronized(@())
                DetectedErrors = [System.Collections.ArrayList]::Synchronized(@())
                ExportResults = [System.Collections.ArrayList]::Synchronized(@())
            })
            Write-UnityParallelLog -Message "DEBUG: Monitoring state created successfully" -Level "DEBUG"
        } catch {
            Write-UnityParallelLog -Message "ERROR: Failed to create monitoring state: $($_.Exception.Message)" -Level "ERROR"
            throw "Failed to create monitoring state: $($_.Exception.Message)"
        }
        
        try {
            Add-SharedVariable -SessionStateConfig $sessionConfig -Name "UnityMonitoringState" -Value $monitoringState -MakeThreadSafe
            Write-UnityParallelLog -Message "DEBUG: Shared variable added successfully" -Level "DEBUG"
        } catch {
            Write-UnityParallelLog -Message "ERROR: Failed to add shared variable: $($_.Exception.Message)" -Level "ERROR"
            throw "Failed to add shared variable: $($_.Exception.Message)"
        }
        
        # Create production runspace pool for Unity monitoring with debug logging
        Write-UnityParallelLog -Message "DEBUG: Creating production runspace pool..." -Level "DEBUG"
        
        try {
            $monitoringPool = New-ProductionRunspacePool -SessionStateConfig $sessionConfig -MaxRunspaces $MaxRunspaces -Name $MonitorName -EnableResourceMonitoring:$EnableResourceMonitoring
            Write-UnityParallelLog -Message "DEBUG: Production runspace pool created successfully" -Level "DEBUG"
        } catch {
            Write-UnityParallelLog -Message "ERROR: Failed to create production runspace pool: $($_.Exception.Message)" -Level "ERROR"
            throw "Failed to create production runspace pool: $($_.Exception.Message)"
        }
        
        # Create Unity parallel monitor object
        $unityMonitor = @{
            MonitorName = $MonitorName
            ProjectNames = $validProjects
            RunspacePool = $monitoringPool
            SessionConfig = $sessionConfig
            MonitoringState = $monitoringState
            MaxRunspaces = $MaxRunspaces
            Created = Get-Date
            Status = 'Created'
            
            # Monitoring jobs tracking
            ActiveJobs = @()
            MonitoringJobs = @()
            CompilationJobs = @()
            ErrorDetectionJobs = @()
            
            # Performance tracking
            Statistics = @{
                ProjectsMonitored = $validProjects.Count
                CompilationsDetected = 0
                ErrorsDetected = 0
                ErrorsExported = 0
                TotalMonitoringTime = 0
                AverageProcessingTime = 0
            }
        }
        
        # Register monitor
        $script:ActiveUnityMonitors[$MonitorName] = $unityMonitor
        
        Write-UnityParallelLog -Message "Unity parallel monitor '$MonitorName' created successfully for $($validProjects.Count) projects" -Level "INFO"
        
        return $unityMonitor
        
    } catch {
        Write-UnityParallelLog -Message "Failed to create Unity parallel monitor '$MonitorName': $($_.Exception.Message)" -Level "ERROR"
        throw
    }
}

function Start-UnityParallelMonitoring {
    <#
    .SYNOPSIS
    Starts Unity parallel monitoring system
    .DESCRIPTION
    Starts parallel monitoring for Unity compilation across multiple projects using runspace pools
    .PARAMETER Monitor
    Unity monitor object from New-UnityParallelMonitor
    .PARAMETER MonitoringMode
    Type of monitoring (Compilation, Errors, Both)
    .EXAMPLE
    Start-UnityParallelMonitoring -Monitor $monitor -MonitoringMode "Both"
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [hashtable]$Monitor,
        [ValidateSet('Compilation', 'Errors', 'Both')]
        [string]$MonitoringMode = 'Both'
    )
    
    $monitorName = $Monitor.MonitorName
    Write-UnityParallelLog -Message "Starting Unity parallel monitoring '$monitorName' in $MonitoringMode mode..." -Level "INFO"
    
    try {
        # Open runspace pool
        $openResult = Open-RunspacePool -PoolManager $Monitor.RunspacePool
        if (-not $openResult.Success) {
            throw "Failed to open runspace pool for Unity monitor '$monitorName'"
        }
        
        # Create monitoring jobs for each project
        foreach ($projectName in $Monitor.ProjectNames) {
            $projectConfig = Get-UnityProjectConfiguration -ProjectName $projectName
            
            # Unity compilation monitoring job
            if ($MonitoringMode -eq 'Compilation' -or $MonitoringMode -eq 'Both') {
                $compilationScript = {
                    param([ref]$MonitoringState, $ProjectName, $ProjectPath, $LogPath)
                    
                    try {
                        # Monitor Unity project for compilation activity
                        $watcher = New-Object System.IO.FileSystemWatcher
                        $watcher.Path = $ProjectPath
                        $watcher.Filter = "*.cs"
                        $watcher.IncludeSubdirectories = $true
                        $watcher.EnableRaisingEvents = $true
                        
                        # Simple monitoring loop (replace with proper FileSystemWatcher event handling)
                        $startTime = Get-Date
                        $timeout = (Get-Date).AddMinutes(5) # 5 minute monitoring window
                        
                        while ((Get-Date) -lt $timeout) {
                            # Check for compilation activity indicators
                            $logExists = Test-Path $LogPath
                            
                            if ($logExists) {
                                $compilationEvent = @{
                                    ProjectName = $ProjectName
                                    EventType = "CompilationDetected"
                                    Timestamp = Get-Date
                                    LogPath = $LogPath
                                }
                                
                                $MonitoringState.Value.CompilationEvents.Add($compilationEvent)
                            }
                            
                            Start-Sleep -Milliseconds 1000 # 1 second polling
                        }
                        
                        $watcher.Dispose()
                        return "Unity compilation monitoring completed for $ProjectName"
                        
                    } catch {
                        return "Unity compilation monitoring error for $ProjectName : $($_.Exception.Message)"
                    }
                }
                
                # Submit compilation monitoring job using reference parameter passing (Learning #196)
                $ps = [powershell]::Create()
                $ps.RunspacePool = $Monitor.RunspacePool.RunspacePool
                $ps.AddScript($compilationScript)
                $ps.AddArgument([ref]$Monitor.MonitoringState)
                $ps.AddArgument($projectName)
                $ps.AddArgument($projectConfig.Path)
                $ps.AddArgument($projectConfig.LogPath)
                
                $asyncResult = $ps.BeginInvoke()
                
                $monitoringJob = @{
                    JobType = "CompilationMonitoring"
                    ProjectName = $projectName
                    PowerShell = $ps
                    AsyncResult = $asyncResult
                    StartTime = Get-Date
                }
                
                $Monitor.MonitoringJobs += $monitoringJob
                
                Write-UnityParallelLog -Message "Started compilation monitoring for project: $projectName" -Level "DEBUG"
            }
            
            # Unity error detection monitoring job  
            if ($MonitoringMode -eq 'Errors' -or $MonitoringMode -eq 'Both') {
                $errorDetectionScript = {
                    param([ref]$MonitoringState, $ProjectName, $LogPath, $ErrorPatterns)
                    
                    try {
                        # Monitor Unity Editor.log for errors using Get-Content -Wait pattern
                        if (Test-Path $LogPath) {
                            $errorCount = 0
                            $startTime = Get-Date
                            $timeout = (Get-Date).AddMinutes(5)
                            
                            # Simple log monitoring (replace with Get-Content -Wait in production)
                            while ((Get-Date) -lt $timeout) {
                                $logContent = Get-Content $LogPath -ErrorAction SilentlyContinue
                                
                                if ($logContent) {
                                    # Check for compilation errors
                                    $errors = $logContent | Where-Object { $_ -match $ErrorPatterns.CompilationError }
                                    
                                    foreach ($error in $errors) {
                                        $errorEvent = @{
                                            ProjectName = $ProjectName
                                            ErrorType = "CompilationError"
                                            ErrorText = $error
                                            Timestamp = Get-Date
                                            LogPath = $LogPath
                                        }
                                        
                                        $MonitoringState.Value.DetectedErrors.Add($errorEvent)
                                        $errorCount++
                                    }
                                }
                                
                                Start-Sleep -Milliseconds 500 # 500ms polling for error detection
                            }
                            
                            return "Unity error detection completed for $ProjectName : $errorCount errors found"
                        } else {
                            return "Unity log file not found for $ProjectName : $LogPath"
                        }
                        
                    } catch {
                        return "Unity error detection error for $ProjectName : $($_.Exception.Message)"
                    }
                }
                
                # Submit error detection job using reference parameter passing
                $ps = [powershell]::Create()
                $ps.RunspacePool = $Monitor.RunspacePool.RunspacePool
                $ps.AddScript($errorDetectionScript)
                $ps.AddArgument([ref]$Monitor.MonitoringState)
                $ps.AddArgument($projectName)
                $ps.AddArgument($projectConfig.LogPath)
                $ps.AddArgument($script:UnityParallelizationConfig.ErrorPatterns)
                
                $asyncResult = $ps.BeginInvoke()
                
                $errorJob = @{
                    JobType = "ErrorDetection"
                    ProjectName = $projectName
                    PowerShell = $ps
                    AsyncResult = $asyncResult
                    StartTime = Get-Date
                }
                
                $Monitor.MonitoringJobs += $errorJob
                
                Write-UnityParallelLog -Message "Started error detection for project: $projectName" -Level "DEBUG"
            }
        }
        
        # Update monitor status
        $Monitor.Status = 'Running'
        $Monitor.StartTime = Get-Date
        
        Write-UnityParallelLog -Message "Unity parallel monitoring '$monitorName' started successfully for $($Monitor.ProjectNames.Count) projects" -Level "INFO"
        
        return @{
            Success = $true
            MonitoringJobs = $Monitor.MonitoringJobs.Count
            ProjectsMonitored = $Monitor.ProjectNames.Count
            MonitoringMode = $MonitoringMode
        }
        
    } catch {
        Write-UnityParallelLog -Message "Failed to start Unity parallel monitoring '$monitorName': $($_.Exception.Message)" -Level "ERROR"
        throw
    }
}

function Stop-UnityParallelMonitoring {
    <#
    .SYNOPSIS
    Stops Unity parallel monitoring system
    .DESCRIPTION
    Stops all parallel monitoring jobs and cleans up resources
    .PARAMETER Monitor
    Unity monitor object
    .PARAMETER Force
    Force stop even if jobs are running
    .EXAMPLE
    Stop-UnityParallelMonitoring -Monitor $monitor
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [hashtable]$Monitor,
        [switch]$Force
    )
    
    $monitorName = $Monitor.MonitorName
    Write-UnityParallelLog -Message "Stopping Unity parallel monitoring '$monitorName'..." -Level "INFO"
    
    try {
        # Stop all monitoring jobs
        $stoppedJobs = 0
        foreach ($job in $Monitor.MonitoringJobs) {
            try {
                if (-not $job.AsyncResult.IsCompleted) {
                    $job.PowerShell.Stop()
                }
                
                $result = $job.PowerShell.EndInvoke($job.AsyncResult)
                Write-UnityParallelLog -Message "Monitoring job result for $($job.ProjectName): $result" -Level "DEBUG"
                
                $job.PowerShell.Dispose()
                $stoppedJobs++
                
            } catch {
                Write-UnityParallelLog -Message "Error stopping monitoring job for $($job.ProjectName): $($_.Exception.Message)" -Level "WARNING"
            }
        }
        
        # Close runspace pool
        $closeResult = Close-RunspacePool -PoolManager $Monitor.RunspacePool -Force:$Force
        
        # Update monitor status
        $Monitor.Status = 'Stopped'
        $Monitor.StopTime = Get-Date
        
        if ($Monitor.StartTime) {
            $Monitor.Statistics.TotalMonitoringTime = [math]::Round(($Monitor.StopTime - $Monitor.StartTime).TotalMinutes, 2)
        }
        
        Write-UnityParallelLog -Message "Unity parallel monitoring '$monitorName' stopped successfully ($stoppedJobs jobs stopped)" -Level "INFO"
        
        return @{
            Success = $closeResult.Success
            JobsStopped = $stoppedJobs
            MonitoringTime = $Monitor.Statistics.TotalMonitoringTime
        }
        
    } catch {
        Write-UnityParallelLog -Message "Failed to stop Unity parallel monitoring '$monitorName': $($_.Exception.Message)" -Level "ERROR"
        throw
    }
}

function Get-UnityMonitoringStatus {
    <#
    .SYNOPSIS
    Gets status of Unity parallel monitoring system
    .DESCRIPTION
    Returns monitoring status, statistics, and active job information
    .PARAMETER MonitorName
    Name of the Unity parallel monitor
    .EXAMPLE
    $status = Get-UnityMonitoringStatus -MonitorName "UnityCompilationMonitor"
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$MonitorName
    )
    
    try {
        if (-not $script:ActiveUnityMonitors.ContainsKey($MonitorName)) {
            throw "Unity monitor not found: $MonitorName"
        }
        
        $monitor = $script:ActiveUnityMonitors[$MonitorName]
        
        # Collect job statuses
        $activeJobs = @()
        $completedJobs = @()
        
        foreach ($job in $monitor.MonitoringJobs) {
            $jobStatus = @{
                JobType = $job.JobType
                ProjectName = $job.ProjectName
                StartTime = $job.StartTime
                IsCompleted = $job.AsyncResult.IsCompleted
                ElapsedTime = if ($job.StartTime) { [math]::Round(((Get-Date) - $job.StartTime).TotalSeconds, 2) } else { 0 }
            }
            
            if ($job.AsyncResult.IsCompleted) {
                $completedJobs += $jobStatus
            } else {
                $activeJobs += $jobStatus
            }
        }
        
        # Update statistics from monitoring state
        if ($monitor.MonitoringState) {
            $monitor.Statistics.CompilationsDetected = $monitor.MonitoringState.CompilationEvents.Count
            $monitor.Statistics.ErrorsDetected = $monitor.MonitoringState.DetectedErrors.Count
            $monitor.Statistics.ErrorsExported = $monitor.MonitoringState.ExportResults.Count
        }
        
        $status = @{
            MonitorName = $MonitorName
            Status = $monitor.Status
            ProjectsMonitored = $monitor.ProjectNames.Count
            MaxRunspaces = $monitor.MaxRunspaces
            Created = $monitor.Created
            ActiveJobs = $activeJobs
            CompletedJobs = $completedJobs
            Statistics = $monitor.Statistics
        }
        
        Write-UnityParallelLog -Message "Retrieved monitoring status for '$MonitorName'" -Level "DEBUG"
        
        return $status
        
    } catch {
        Write-UnityParallelLog -Message "Failed to get monitoring status for '$MonitorName': $($_.Exception.Message)" -Level "ERROR"
        throw
    }
}

#endregion

#region Module Exports

Export-ModuleMember -Function @(
    'New-UnityParallelMonitor',
    'Start-UnityParallelMonitoring',
    'Stop-UnityParallelMonitoring',
    'Get-UnityMonitoringStatus'
)

#endregion

# REFACTORING MARKER: This module was refactored from Unity-Claude-UnityParallelization.psm1 on 2025-08-25
# Original file size: 2084 lines
# This component: Parallel Unity monitoring architecture (lines 463-970, ~508 lines)
# SIG # Begin signature block
# MIIFzgYJKoZIhvcNAQcCoIIFvzCCBbsCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCB9tmMzVkw91VuN
# acvsClHOPLFWbCuUjnI+xubUFf1KpKCCAzAwggMsMIICFKADAgECAhB1HRbZIqgr
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
# MAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIKCoq6GPWBe6r0yMYuUkXw6w
# ASO81KTleoUdFbhgW98+MA0GCSqGSIb3DQEBAQUABIIBAEYGu/BI7kJJ23Al+bud
# +/88teNtvb/6F4Is48M+dq14wAhKQqyPuvnKSOPIX3FvPZC2Y4GaRXWxT/3n9dTn
# OsCBojZiKDcb78I2Mgf57oxOrRkmQFmwypfq3uBkywD1WVafXOUHVSj3q2QE6bhf
# DkG3t9EaJKTf8wu3T7DkmdQaMEL0Eaj6no+Q4N+dwQ6Am7WTs0oFuROcZqYAAQj3
# KJwc4yujGv91a1s42UMiHnDhNlc9pnXxTzUEBtIvkV0DBgh/y+cCfxVe7tQVz6um
# 1PfQQ0vsFcO8QPtHiyNnDFxSx484vLdXITp/aZdFS0fyP5SHOODH6HMQaGpK0RSt
# 7/Q=
# SIG # End signature block
