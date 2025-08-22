# Start-ProductionIntegratedWorkflow.ps1
# Production deployment script for Unity-Claude integrated workflow system
# Phase 1 Week 3 Day 5: Production Readiness and Monitoring
# Date: 2025-08-21

[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [string[]]$UnityProjects,
    [string]$WorkflowName = "Production-Unity-Claude-Workflow",
    [int]$MaxUnityProjects = 4,
    [int]$MaxClaudeSubmissions = 8,
    [ValidateSet('Continuous', 'OnDemand', 'Batch')]
    [string]$WorkflowMode = 'Continuous',
    [int]$MonitoringInterval = 30,
    [switch]$EnableResourceOptimization,
    [switch]$EnableHealthMonitoring,
    [switch]$EnablePerformanceReporting,
    [string]$LogLevel = 'INFO',
    [string]$ConfigurationFile,
    [switch]$DaemonMode
)

$ErrorActionPreference = "Stop"

# Production configuration
$ProductionConfig = @{
    WorkflowName = $WorkflowName
    UnityProjects = $UnityProjects
    MaxUnityProjects = $MaxUnityProjects
    MaxClaudeSubmissions = $MaxClaudeSubmissions
    WorkflowMode = $WorkflowMode
    MonitoringInterval = $MonitoringInterval
    EnableResourceOptimization = $EnableResourceOptimization
    EnableHealthMonitoring = $EnableHealthMonitoring
    EnablePerformanceReporting = $EnablePerformanceReporting
    LogLevel = $LogLevel
    ConfigurationFile = $ConfigurationFile
    DaemonMode = $DaemonMode
    StartTime = Get-Date
    
    # Production paths
    LogDirectory = ".\Logs"
    ConfigDirectory = ".\Config"
    DataDirectory = ".\Data"
    BackupDirectory = ".\Backup"
    
    # Performance and health thresholds
    HealthCheck = @{
        Interval = 60  # seconds
        CPUThreshold = 85
        MemoryThreshold = 90
        ErrorRateThreshold = 10  # percent
        ResponseTimeThreshold = 30000  # ms
    }
    
    # Alerting configuration
    Alerting = @{
        EnableEmailAlerts = $false
        EnableLogAlerts = $true
        CriticalThreshold = 5  # minutes of continuous issues
        WarningThreshold = 2   # minutes of continuous issues
    }
}

# Enhanced production logging
function Write-ProductionLog {
    param(
        [string]$Message,
        [string]$Level = "INFO",
        [string]$Component = "ProductionWorkflow",
        [string]$Category = "General"
    )
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss.fff"
    $logMessage = "[$timestamp] [$Level] [$Component] [$Category] $Message"
    
    # Console output with colors
    $color = switch ($Level) {
        "CRITICAL" { "Magenta" }
        "ERROR" { "Red" }
        "WARNING" { "Yellow" }
        "SUCCESS" { "Green" }
        "DEBUG" { "Gray" }
        default { "White" }
    }
    
    if ($ProductionConfig.LogLevel -eq "DEBUG" -or $Level -ne "DEBUG") {
        Write-Host $logMessage -ForegroundColor $color
    }
    
    # Write to centralized log
    try {
        Add-Content -Path ".\unity_claude_automation.log" -Value $logMessage -ErrorAction SilentlyContinue
        
        # Write to production log directory
        $logFile = Join-Path $ProductionConfig.LogDirectory "production_workflow_$(Get-Date -Format 'yyyyMMdd').log"
        Add-Content -Path $logFile -Value $logMessage -ErrorAction SilentlyContinue
        
        # Write component-specific log
        $componentLog = Join-Path $ProductionConfig.LogDirectory "${Component}_$(Get-Date -Format 'yyyyMMdd').log"
        Add-Content -Path $componentLog -Value $logMessage -ErrorAction SilentlyContinue
        
    } catch {
        # Fallback logging if directory issues
        Write-Warning "Failed to write to production logs: $($_.Exception.Message)"
    }
}

# Create production directory structure
function Initialize-ProductionEnvironment {
    Write-ProductionLog -Message "Initializing production environment..." -Level "INFO"
    
    try {
        # Create directories
        $directories = @(
            $ProductionConfig.LogDirectory,
            $ProductionConfig.ConfigDirectory,
            $ProductionConfig.DataDirectory,
            $ProductionConfig.BackupDirectory,
            (Join-Path $ProductionConfig.DataDirectory "Metrics"),
            (Join-Path $ProductionConfig.DataDirectory "Health"),
            (Join-Path $ProductionConfig.DataDirectory "Performance")
        )
        
        foreach ($dir in $directories) {
            if (-not (Test-Path $dir)) {
                New-Item -ItemType Directory -Path $dir -Force | Out-Null
                Write-ProductionLog -Message "Created directory: $dir" -Level "DEBUG" -Component "Environment"
            }
        }
        
        # Create production configuration backup
        $configBackup = Join-Path $ProductionConfig.BackupDirectory "production_config_$(Get-Date -Format 'yyyyMMdd_HHmmss').json"
        $ProductionConfig | ConvertTo-Json -Depth 10 | Out-File -FilePath $configBackup -Encoding ASCII
        
        Write-ProductionLog -Message "Production environment initialized successfully" -Level "SUCCESS" -Component "Environment"
        return $true
        
    } catch {
        Write-ProductionLog -Message "Failed to initialize production environment: $($_.Exception.Message)" -Level "ERROR" -Component "Environment"
        return $false
    }
}

# System health monitoring
function Start-HealthMonitoring {
    param([hashtable]$IntegratedWorkflow)
    
    Write-ProductionLog -Message "Starting health monitoring..." -Level "INFO" -Component "HealthMonitor"
    
    $healthScript = {
        param([ref]$WorkflowRef, $HealthConfig, $WorkflowName, $LogDirectory)
        
        try {
            $healthStartTime = Get-Date
            $consecutiveIssues = 0
            $lastHealthCheck = $healthStartTime
            
            while ($true) {
                $currentTime = Get-Date
                
                # Check if it's time for health check
                if (($currentTime - $lastHealthCheck).TotalSeconds -ge $HealthConfig.Interval) {
                    $healthStatus = @{
                        Timestamp = $currentTime
                        WorkflowName = $WorkflowName
                        OverallHealth = "Healthy"
                        Issues = @()
                        Metrics = @{
                            CPUUsage = 0
                            MemoryUsage = 0
                            ErrorRate = 0
                            ResponseTime = 0
                        }
                    }
                    
                    # Get system metrics
                    try {
                        if (Get-Command Get-Counter -ErrorAction SilentlyContinue) {
                            # CPU usage
                            $cpuSample = Get-Counter '\Processor(_Total)\% Processor Time' -SampleInterval 1 -MaxSamples 1 -ErrorAction SilentlyContinue
                            if ($cpuSample) {
                                $healthStatus.Metrics.CPUUsage = [math]::Round($cpuSample.CounterSamples[0].CookedValue, 2)
                            }
                            
                            # Memory usage
                            $memorySample = Get-Counter '\Memory\Available MBytes' -SampleInterval 1 -MaxSamples 1 -ErrorAction SilentlyContinue
                            if ($memorySample) {
                                $totalMemoryMB = [math]::Round((Get-CimInstance Win32_ComputerSystem -ErrorAction SilentlyContinue).TotalPhysicalMemory / 1MB, 0)
                                $availableMemoryMB = $memorySample.CounterSamples[0].CookedValue
                                $healthStatus.Metrics.MemoryUsage = if ($totalMemoryMB -gt 0) { 
                                    [math]::Round((($totalMemoryMB - $availableMemoryMB) / $totalMemoryMB) * 100, 2) 
                                } else { 0 }
                            }
                        }
                    } catch {
                        $healthStatus.Issues += "Failed to collect system metrics: $($_.Exception.Message)"
                    }
                    
                    # Get workflow metrics
                    try {
                        if ($WorkflowRef.Value -and $WorkflowRef.Value.WorkflowState) {
                            $workflowMetrics = $WorkflowRef.Value.WorkflowState.WorkflowMetrics
                            
                            # Calculate error rate
                            $totalProcessed = $workflowMetrics.UnityErrorsProcessed
                            $totalFailed = if ($WorkflowRef.Value.WorkflowState.FailedJobs) { $WorkflowRef.Value.WorkflowState.FailedJobs.Count } else { 0 }
                            
                            if ($totalProcessed -gt 0) {
                                $healthStatus.Metrics.ErrorRate = [math]::Round(($totalFailed / $totalProcessed) * 100, 2)
                            }
                            
                            # Check queue lengths for potential bottlenecks
                            $queueLengths = @{
                                Unity = $WorkflowRef.Value.WorkflowState.UnityErrorQueue.Count
                                Claude = $WorkflowRef.Value.WorkflowState.ClaudePromptQueue.Count
                                Responses = $WorkflowRef.Value.WorkflowState.ClaudeResponseQueue.Count
                            }
                            
                            if ($queueLengths.Unity -gt 50) {
                                $healthStatus.Issues += "Unity error queue backlog: $($queueLengths.Unity) items"
                            }
                            
                            if ($queueLengths.Claude -gt 30) {
                                $healthStatus.Issues += "Claude prompt queue backlog: $($queueLengths.Claude) items"
                            }
                        }
                    } catch {
                        $healthStatus.Issues += "Failed to collect workflow metrics: $($_.Exception.Message)"
                    }
                    
                    # Evaluate health thresholds
                    $criticalIssues = @()
                    $warningIssues = @()
                    
                    if ($healthStatus.Metrics.CPUUsage -gt $HealthConfig.CPUThreshold) {
                        $criticalIssues += "High CPU usage: $($healthStatus.Metrics.CPUUsage)%"
                    }
                    
                    if ($healthStatus.Metrics.MemoryUsage -gt $HealthConfig.MemoryThreshold) {
                        $criticalIssues += "High memory usage: $($healthStatus.Metrics.MemoryUsage)%"
                    }
                    
                    if ($healthStatus.Metrics.ErrorRate -gt $HealthConfig.ErrorRateThreshold) {
                        $criticalIssues += "High error rate: $($healthStatus.Metrics.ErrorRate)%"
                    }
                    
                    # Determine overall health
                    if ($criticalIssues.Count -gt 0) {
                        $healthStatus.OverallHealth = "Critical"
                        $healthStatus.Issues += $criticalIssues
                        $consecutiveIssues++
                    } elseif ($warningIssues.Count -gt 0 -or $healthStatus.Issues.Count -gt 0) {
                        $healthStatus.OverallHealth = "Warning"
                        $consecutiveIssues++
                    } else {
                        $healthStatus.OverallHealth = "Healthy"
                        $consecutiveIssues = 0
                    }
                    
                    # Log health status
                    $healthLogLevel = switch ($healthStatus.OverallHealth) {
                        "Critical" { "CRITICAL" }
                        "Warning" { "WARNING" }
                        default { "INFO" }
                    }
                    
                    $healthMessage = "Health check: $($healthStatus.OverallHealth) - CPU:$($healthStatus.Metrics.CPUUsage)%, Mem:$($healthStatus.Metrics.MemoryUsage)%, Errors:$($healthStatus.Metrics.ErrorRate)%"
                    if ($healthStatus.Issues.Count -gt 0) {
                        $healthMessage += " - Issues: $($healthStatus.Issues -join '; ')"
                    }
                    
                    Write-Host "[$((Get-Date).ToString('yyyy-MM-dd HH:mm:ss.fff'))] [$healthLogLevel] [HealthMonitor] $healthMessage" -ForegroundColor $(
                        switch ($healthLogLevel) {
                            "CRITICAL" { "Magenta" }
                            "WARNING" { "Yellow" }
                            default { "Green" }
                        }
                    )
                    
                    # Save health data
                    $healthFile = Join-Path $LogDirectory "health_$(Get-Date -Format 'yyyyMMdd').json"
                    $healthStatus | ConvertTo-Json -Compress | Add-Content -Path $healthFile -ErrorAction SilentlyContinue
                    
                    $lastHealthCheck = $currentTime
                }
                
                # Sleep between checks
                Start-Sleep -Seconds 10
                
                # Safety break after extended runtime
                if (((Get-Date) - $healthStartTime).TotalHours -ge 24) {
                    Write-Host "[$((Get-Date).ToString('yyyy-MM-dd HH:mm:ss.fff'))] [INFO] [HealthMonitor] Health monitoring cycle completed (24 hours)" -ForegroundColor Cyan
                    break
                }
            }
            
        } catch {
            Write-Host "[$((Get-Date).ToString('yyyy-MM-dd HH:mm:ss.fff'))] [ERROR] [HealthMonitor] Health monitoring error: $($_.Exception.Message)" -ForegroundColor Red
        }
    }
    
    # Start health monitoring in background
    $ps = [powershell]::Create()
    $ps.AddScript($healthScript)
    $ps.AddArgument([ref]$IntegratedWorkflow)
    $ps.AddArgument($ProductionConfig.HealthCheck)
    $ps.AddArgument($ProductionConfig.WorkflowName)
    $ps.AddArgument($ProductionConfig.LogDirectory)
    
    $healthMonitorJob = @{
        PowerShell = $ps
        AsyncResult = $ps.BeginInvoke()
        StartTime = Get-Date
    }
    
    Write-ProductionLog -Message "Health monitoring started in background" -Level "SUCCESS" -Component "HealthMonitor"
    return $healthMonitorJob
}

# Performance reporting
function Start-PerformanceReporting {
    param([hashtable]$IntegratedWorkflow)
    
    Write-ProductionLog -Message "Starting performance reporting..." -Level "INFO" -Component "PerformanceReporter"
    
    $reportingScript = {
        param([ref]$WorkflowRef, $WorkflowName, $LogDirectory, $DataDirectory)
        
        try {
            $reportingStartTime = Get-Date
            $reportInterval = 300  # 5 minutes
            $lastReport = $reportingStartTime
            
            while ($true) {
                $currentTime = Get-Date
                
                if (($currentTime - $lastReport).TotalSeconds -ge $reportInterval) {
                    # Generate performance report
                    $performanceReport = @{
                        Timestamp = $currentTime
                        WorkflowName = $WorkflowName
                        ReportPeriod = $reportInterval
                        Metrics = @{}
                        Trends = @{}
                        Recommendations = @()
                    }
                    
                    # Collect workflow performance data
                    if ($WorkflowRef.Value -and $WorkflowRef.Value.WorkflowState) {
                        $workflowMetrics = $WorkflowRef.Value.WorkflowState.WorkflowMetrics
                        $stagePerformance = $WorkflowRef.Value.WorkflowState.StagePerformance
                        
                        $performanceReport.Metrics = @{
                            UnityErrorsProcessed = $workflowMetrics.UnityErrorsProcessed
                            ClaudeResponsesReceived = $workflowMetrics.ClaudeResponsesReceived
                            FixesApplied = $workflowMetrics.FixesApplied
                            ProcessingRate = if ($workflowMetrics.UnityErrorsProcessed -gt 0) {
                                [math]::Round($workflowMetrics.UnityErrorsProcessed / ([math]::Max(1, ((Get-Date) - $WorkflowRef.Value.Created).TotalMinutes)), 2)
                            } else { 0 }
                            SuccessRate = if ($workflowMetrics.UnityErrorsProcessed -gt 0) {
                                [math]::Round(($workflowMetrics.FixesApplied / $workflowMetrics.UnityErrorsProcessed) * 100, 2)
                            } else { 0 }
                        }
                        
                        # Calculate trends
                        if ($stagePerformance.Count -gt 0) {
                            $recentCycles = $stagePerformance.Values | Sort-Object { Get-Date } | Select-Object -Last 10
                            
                            if ($recentCycles.Count -gt 0) {
                                $avgCycleDuration = ($recentCycles | Measure-Object Duration -Average).Average
                                $performanceReport.Trends.AverageCycleDuration = [math]::Round($avgCycleDuration, 2)
                                
                                $totalThroughput = ($recentCycles | Measure-Object UnityErrors -Sum).Sum
                                $performanceReport.Trends.RecentThroughput = $totalThroughput
                            }
                        }
                        
                        # Generate recommendations
                        if ($performanceReport.Metrics.ProcessingRate -lt 1) {
                            $performanceReport.Recommendations += "Low processing rate - consider optimizing Unity monitoring"
                        }
                        
                        if ($performanceReport.Metrics.SuccessRate -lt 90) {
                            $performanceReport.Recommendations += "Success rate below 90% - investigate error patterns"
                        }
                    }
                    
                    # Log performance summary
                    $perfMessage = "Performance report: Rate=$($performanceReport.Metrics.ProcessingRate)/min, Success=$($performanceReport.Metrics.SuccessRate)%, Processed=$($performanceReport.Metrics.UnityErrorsProcessed)"
                    Write-Host "[$((Get-Date).ToString('yyyy-MM-dd HH:mm:ss.fff'))] [INFO] [PerformanceReporter] $perfMessage" -ForegroundColor Cyan
                    
                    # Save performance data
                    $perfFile = Join-Path $DataDirectory "Performance\performance_$(Get-Date -Format 'yyyyMMdd').json"
                    $performanceReport | ConvertTo-Json -Compress | Add-Content -Path $perfFile -ErrorAction SilentlyContinue
                    
                    $lastReport = $currentTime
                }
                
                Start-Sleep -Seconds 60  # Check every minute, report every 5 minutes
                
                # Safety break
                if (((Get-Date) - $reportingStartTime).TotalHours -ge 24) {
                    Write-Host "[$((Get-Date).ToString('yyyy-MM-dd HH:mm:ss.fff'))] [INFO] [PerformanceReporter] Performance reporting cycle completed (24 hours)" -ForegroundColor Cyan
                    break
                }
            }
            
        } catch {
            Write-Host "[$((Get-Date).ToString('yyyy-MM-dd HH:mm:ss.fff'))] [ERROR] [PerformanceReporter] Performance reporting error: $($_.Exception.Message)" -ForegroundColor Red
        }
    }
    
    # Start performance reporting in background
    $ps = [powershell]::Create()
    $ps.AddScript($reportingScript)
    $ps.AddArgument([ref]$IntegratedWorkflow)
    $ps.AddArgument($ProductionConfig.WorkflowName)
    $ps.AddArgument($ProductionConfig.LogDirectory)
    $ps.AddArgument($ProductionConfig.DataDirectory)
    
    $performanceReportJob = @{
        PowerShell = $ps
        AsyncResult = $ps.BeginInvoke()
        StartTime = Get-Date
    }
    
    Write-ProductionLog -Message "Performance reporting started in background" -Level "SUCCESS" -Component "PerformanceReporter"
    return $performanceReportJob
}

# Main production startup sequence
Write-ProductionLog -Message "Starting Unity-Claude Production Integrated Workflow..." -Level "SUCCESS" -Category "Startup"
Write-ProductionLog -Message "Configuration: $($ProductionConfig.WorkflowMode) mode, $($ProductionConfig.MaxUnityProjects) Unity projects, $($ProductionConfig.MaxClaudeSubmissions) Claude submissions" -Level "INFO" -Category "Configuration"

try {
    # Initialize production environment
    if (-not (Initialize-ProductionEnvironment)) {
        throw "Failed to initialize production environment"
    }
    
    # Load configuration from file if specified
    if ($ProductionConfig.ConfigurationFile -and (Test-Path $ProductionConfig.ConfigurationFile)) {
        Write-ProductionLog -Message "Loading configuration from: $($ProductionConfig.ConfigurationFile)" -Level "INFO" -Category "Configuration"
        $loadedConfig = Get-Content $ProductionConfig.ConfigurationFile | ConvertFrom-Json
        
        # Merge loaded configuration (implementation would merge config properties)
        Write-ProductionLog -Message "Configuration loaded successfully" -Level "SUCCESS" -Category "Configuration"
    }
    
    # Validate Unity projects
    Write-ProductionLog -Message "Validating Unity projects..." -Level "INFO" -Category "Validation"
    $validProjects = @()
    
    foreach ($project in $ProductionConfig.UnityProjects) {
        if (Test-Path $project) {
            $validProjects += $project
            Write-ProductionLog -Message "Unity project validated: $project" -Level "DEBUG" -Category "Validation"
        } else {
            Write-ProductionLog -Message "Unity project not found: $project" -Level "WARNING" -Category "Validation"
        }
    }
    
    if ($validProjects.Count -eq 0) {
        throw "No valid Unity projects found"
    }
    
    Write-ProductionLog -Message "$($validProjects.Count)/$($ProductionConfig.UnityProjects.Count) Unity projects validated" -Level "SUCCESS" -Category "Validation"
    
    # Import required modules
    Write-ProductionLog -Message "Importing Unity-Claude modules..." -Level "INFO" -Category "ModuleLoading"
    
    $requiredModules = @(
        'Unity-Claude-IntegratedWorkflow',
        'Unity-Claude-RunspaceManagement',
        'Unity-Claude-UnityParallelization',
        'Unity-Claude-ClaudeParallelization'
    )
    
    foreach ($module in $requiredModules) {
        try {
            Import-Module $module -Force -ErrorAction Stop
            Write-ProductionLog -Message "Module imported: $module" -Level "SUCCESS" -Category "ModuleLoading"
        } catch {
            Write-ProductionLog -Message "Failed to import module $module : $($_.Exception.Message)" -Level "ERROR" -Category "ModuleLoading"
            throw
        }
    }
    
    # Create integrated workflow
    Write-ProductionLog -Message "Creating integrated workflow..." -Level "INFO" -Category "WorkflowCreation"
    
    $integratedWorkflow = New-IntegratedWorkflow -WorkflowName $ProductionConfig.WorkflowName -MaxUnityProjects $ProductionConfig.MaxUnityProjects -MaxClaudeSubmissions $ProductionConfig.MaxClaudeSubmissions -EnableResourceOptimization:$ProductionConfig.EnableResourceOptimization -EnableErrorPropagation
    
    Write-ProductionLog -Message "Integrated workflow created: $($integratedWorkflow.WorkflowName)" -Level "SUCCESS" -Category "WorkflowCreation"
    
    # Initialize adaptive throttling
    if ($ProductionConfig.EnableResourceOptimization) {
        Write-ProductionLog -Message "Initializing adaptive throttling..." -Level "INFO" -Category "OptimizationSetup"
        Initialize-AdaptiveThrottling -IntegratedWorkflow $integratedWorkflow -EnableCPUThrottling -EnableMemoryThrottling -CPUThreshold $ProductionConfig.HealthCheck.CPUThreshold -MemoryThreshold $ProductionConfig.HealthCheck.MemoryThreshold | Out-Null
        Write-ProductionLog -Message "Adaptive throttling initialized" -Level "SUCCESS" -Category "OptimizationSetup"
    }
    
    # Start monitoring services
    $monitoringJobs = @{}
    
    if ($ProductionConfig.EnableHealthMonitoring) {
        $monitoringJobs.HealthMonitor = Start-HealthMonitoring -IntegratedWorkflow $integratedWorkflow
    }
    
    if ($ProductionConfig.EnablePerformanceReporting) {
        $monitoringJobs.PerformanceReporter = Start-PerformanceReporting -IntegratedWorkflow $integratedWorkflow
    }
    
    # Start integrated workflow
    Write-ProductionLog -Message "Starting integrated workflow..." -Level "INFO" -Category "WorkflowExecution"
    
    $workflowResult = Start-IntegratedWorkflow -IntegratedWorkflow $integratedWorkflow -UnityProjects $validProjects -WorkflowMode $ProductionConfig.WorkflowMode -MonitoringInterval $ProductionConfig.MonitoringInterval
    
    if ($workflowResult.Success) {
        Write-ProductionLog -Message "Integrated workflow started successfully: $($workflowResult.Message)" -Level "SUCCESS" -Category "WorkflowExecution"
    } else {
        throw "Failed to start integrated workflow: $($workflowResult.Message)"
    }
    
    # Production operational status
    Write-ProductionLog -Message "=== PRODUCTION OPERATIONAL ===" -Level "SUCCESS" -Category "Status"
    Write-ProductionLog -Message "Workflow: $($integratedWorkflow.WorkflowName)" -Level "INFO" -Category "Status"
    Write-ProductionLog -Message "Mode: $($ProductionConfig.WorkflowMode)" -Level "INFO" -Category "Status"
    Write-ProductionLog -Message "Unity Projects: $($validProjects.Count)" -Level "INFO" -Category "Status"
    Write-ProductionLog -Message "Monitoring Services: $($monitoringJobs.Keys.Count)" -Level "INFO" -Category "Status"
    Write-ProductionLog -Message "Health Monitoring: $($ProductionConfig.EnableHealthMonitoring)" -Level "INFO" -Category "Status"
    Write-ProductionLog -Message "Performance Reporting: $($ProductionConfig.EnablePerformanceReporting)" -Level "INFO" -Category "Status"
    
    # Store production state for management
    $productionState = @{
        IntegratedWorkflow = $integratedWorkflow
        MonitoringJobs = $monitoringJobs
        ProductionConfig = $ProductionConfig
        StartTime = Get-Date
        ValidProjects = $validProjects
        Status = 'Running'
    }
    
    # Save production state
    $stateFile = Join-Path $ProductionConfig.DataDirectory "production_state.json"
    $productionState | ConvertTo-Json -Depth 10 | Out-File -FilePath $stateFile -Encoding ASCII
    
    if ($ProductionConfig.DaemonMode) {
        Write-ProductionLog -Message "Running in daemon mode - press Ctrl+C to stop" -Level "INFO" -Category "DaemonMode"
        
        # Daemon mode - keep running until interrupted
        try {
            while ($true) {
                # Check workflow status periodically
                $status = Get-IntegratedWorkflowStatus -IntegratedWorkflow $integratedWorkflow
                
                if ($status.OrchestrationStatus -ne 'Running') {
                    Write-ProductionLog -Message "Workflow status changed to: $($status.OrchestrationStatus)" -Level "WARNING" -Category "DaemonMode"
                }
                
                # Update adaptive throttling if enabled
                if ($ProductionConfig.EnableResourceOptimization) {
                    Update-AdaptiveThrottling -IntegratedWorkflow $integratedWorkflow | Out-Null
                }
                
                Start-Sleep -Seconds 30
            }
        } catch {
            Write-ProductionLog -Message "Daemon mode interrupted: $($_.Exception.Message)" -Level "WARNING" -Category "DaemonMode"
        }
        
        # Graceful shutdown
        Write-ProductionLog -Message "Initiating graceful shutdown..." -Level "INFO" -Category "Shutdown"
        
        # Stop workflow
        Stop-IntegratedWorkflow -IntegratedWorkflow $integratedWorkflow -WaitForCompletion -TimeoutSeconds 60 | Out-Null
        
        # Stop monitoring jobs
        foreach ($jobName in $monitoringJobs.Keys) {
            try {
                $monitoringJobs[$jobName].PowerShell.Stop()
                $monitoringJobs[$jobName].PowerShell.Dispose()
                Write-ProductionLog -Message "Stopped monitoring job: $jobName" -Level "INFO" -Category "Shutdown"
            } catch {
                Write-ProductionLog -Message "Error stopping $jobName : $($_.Exception.Message)" -Level "WARNING" -Category "Shutdown"
            }
        }
        
        Write-ProductionLog -Message "Production shutdown completed" -Level "SUCCESS" -Category "Shutdown"
    } else {
        Write-ProductionLog -Message "Production workflow started - use Get-IntegratedWorkflowStatus to monitor" -Level "INFO" -Category "Interactive"
        Write-ProductionLog -Message "Use Stop-IntegratedWorkflow to stop gracefully" -Level "INFO" -Category "Interactive"
    }
    
    # Return production state for interactive use
    return $productionState
    
} catch {
    Write-ProductionLog -Message "Production startup failed: $($_.Exception.Message)" -Level "CRITICAL" -Category "StartupError"
    Write-ProductionLog -Message "Stack trace: $($_.ScriptStackTrace)" -Level "ERROR" -Category "StartupError"
    throw
}
# SIG # Begin signature block
# MIIFqQYJKoZIhvcNAQcCoIIFmjCCBZYCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUnbw1G/PELQCOeTgYGyn3eaK2
# 0rCgggMwMIIDLDCCAhSgAwIBAgIQdR0W2SKoK5VE8JId4ZxrRTANBgkqhkiG9w0B
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
# CQQxFgQUUJP4hwpa0SQhC298YmSBLwNhl6QwDQYJKoZIhvcNAQEBBQAEggEAHhtz
# rNvh4DGA/+ymIIoyLzntTefu4cEMKnHxMuCaeDUy5BsBD9tLnPjHo1KtwYn6tUx1
# +D7PGmF8Z6U6ZpOYEZTVcZt7DjOx3gGvMNwK2gn/p2nfMuEjLwlBrXiIBmDmm4DC
# OHred7lKaJ/OSvRfDN9hJJoFqzSxu5VqsNCKb7jKyFEJ2mPoLSkPwI4vKmggVpkn
# q1vnbnRitO8JSwyDIKD9QpkVHmRL4GaVTZvMp23hbxfbIP3S8zf3Jdh+9y4qujpo
# VcISQy/VMdYNCyF+yEJQhBph6ULr4IVvh9Igo4PIicLIsIkWMSiwS61LxexF9K2D
# XTuifDxesppE8aju9A==
# SIG # End signature block
