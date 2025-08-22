
# Dependency validation function - added by Fix-ModuleNestingLimit-Phase1.ps1
function Test-ModuleDependencyAvailability {
    param(
        [string[]]$RequiredModules,
        [string]$ModuleName = "Unknown"
    )
    
    $missingModules = @()
    foreach ($reqModule in $RequiredModules) {
        $module = Get-Module $reqModule -ErrorAction SilentlyContinue
        if (-not $module) {
            $missingModules += $reqModule
        }
    }
    
    if ($missingModules.Count -gt 0) {
        Write-Warning "[$ModuleName] Missing required modules: $($missingModules -join ', '). Import them explicitly before using this module."
        return $false
    }
    
    return $true
}

# Unity-Claude-IntegratedWorkflow.psm1
# Phase 1 Week 3 Day 5: End-to-End Integration and Performance Optimization
# Complete Unity-Claude parallel processing workflow orchestration
# Date: 2025-08-21

$ErrorActionPreference = "Stop"

# Import required modules with fallback logging
$script:RequiredModulesAvailable = @{}
$script:WriteModuleLogAvailable = $false

$ModulesPath = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent | Join-Path -ChildPath "Modules"

try {
    $RunspaceManagementPath = Join-Path $ModulesPath "Unity-Claude-RunspaceManagement"
    # Conditional import to preserve script variables - fixes state reset issue
    if (-not (Get-Module Unity-Claude-RunspaceManagement -ErrorAction SilentlyContinue)) {
        Import-Module $RunspaceManagementPath -ErrorAction Stop
        Write-Host "[DEBUG] [StatePreservation] Loaded Unity-Claude-RunspaceManagement module" -ForegroundColor Gray
    } else {
        Write-Host "[DEBUG] [StatePreservation] Unity-Claude-RunspaceManagement already loaded, preserving state" -ForegroundColor Gray
    }
    $script:RequiredModulesAvailable['RunspaceManagement'] = $true
    $script:WriteModuleLogAvailable = $true
} catch {
    Write-Warning "Failed to import Unity-Claude-RunspaceManagement: $($_.Exception.Message)"
    $script:RequiredModulesAvailable['RunspaceManagement'] = $false
}

try {
    $UnityParallelizationPath = Join-Path $ModulesPath "Unity-Claude-UnityParallelization"
    # CRITICAL: Conditional import to preserve Unity project registration state
    if (-not (Get-Module Unity-Claude-UnityParallelization -ErrorAction SilentlyContinue)) {
        Import-Module $UnityParallelizationPath -ErrorAction Stop
        Write-Host "[DEBUG] [StatePreservation] Loaded Unity-Claude-UnityParallelization module" -ForegroundColor Gray
    } else {
        Write-Host "[DEBUG] [StatePreservation] Unity-Claude-UnityParallelization already loaded, PRESERVING REGISTRATION STATE" -ForegroundColor Green
    }
    $script:RequiredModulesAvailable['UnityParallelization'] = $true
} catch {
    Write-Warning "Failed to import Unity-Claude-UnityParallelization: $($_.Exception.Message)"
    $script:RequiredModulesAvailable['UnityParallelization'] = $false
}

try {
    $ClaudeParallelizationPath = Join-Path $ModulesPath "Unity-Claude-ClaudeParallelization"
    # Conditional import to preserve script variables - fixes state reset issue
    if (-not (Get-Module Unity-Claude-ClaudeParallelization -ErrorAction SilentlyContinue)) {
        Import-Module $ClaudeParallelizationPath -ErrorAction Stop
        Write-Host "[DEBUG] [StatePreservation] Loaded Unity-Claude-ClaudeParallelization module" -ForegroundColor Gray
    } else {
        Write-Host "[DEBUG] [StatePreservation] Unity-Claude-ClaudeParallelization already loaded, preserving state" -ForegroundColor Gray
    }
    $script:RequiredModulesAvailable['ClaudeParallelization'] = $true
} catch {
    Write-Warning "Failed to import Unity-Claude-ClaudeParallelization: $($_.Exception.Message)"
    $script:RequiredModulesAvailable['ClaudeParallelization'] = $false
}

# Comprehensive dependency validation
function Test-ModuleDependencies {
    $totalDependencies = $script:RequiredModulesAvailable.Count
    $loadedDependencies = ($script:RequiredModulesAvailable.Values | Where-Object { $_ -eq $true }).Count
    
    Write-Host "Module Dependencies: $loadedDependencies/$totalDependencies loaded" -ForegroundColor $(if ($loadedDependencies -eq $totalDependencies) { "Green" } else { "Yellow" })
    
    foreach ($dep in $script:RequiredModulesAvailable.GetEnumerator()) {
        $status = if ($dep.Value) { "LOADED" } else { "FAILED" }
        Write-Host "  $($dep.Key): $status" -ForegroundColor $(if ($dep.Value) { "Green" } else { "Red" })
    }
    
    return $loadedDependencies -eq $totalDependencies
}

# Validate dependencies during module import
$allDependenciesLoaded = Test-ModuleDependencies
if (-not $allDependenciesLoaded) {
    Write-Warning "IntegratedWorkflow module loaded with missing dependencies. Some functions may not work properly."
}

# Fallback logging function
function Write-FallbackLog {
    param(
        [string]$Message,
        [string]$Level = "INFO",
        [string]$Component = "IntegratedWorkflow"
    )
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss.fff"
    $logMessage = "[$timestamp] [$Level] [$Component] $Message"
    
    switch ($Level) {
        "ERROR" { Write-Host $logMessage -ForegroundColor Red }
        "WARNING" { Write-Host $logMessage -ForegroundColor Yellow }
        "DEBUG" { Write-Host $logMessage -ForegroundColor Gray }
        default { Write-Host $logMessage -ForegroundColor White }
    }
    
    # Write to centralized log
    Add-Content -Path ".\unity_claude_automation.log" -Value $logMessage -ErrorAction SilentlyContinue
}

# Wrapper function for logging with fallback
function Write-IntegratedWorkflowLog {
    param(
        [string]$Message,
        [string]$Level = "INFO", 
        [string]$Component = "IntegratedWorkflow"
    )
    
    Write-FallbackLog -Message "[$Level] [$Component] $Message" -Level $Level -Component $Component
    
    # Debug logging for troubleshooting
    if ($Level -eq "DEBUG") {
        Write-Verbose "IntegratedWorkflow Debug: $Message" -Verbose
    }
}

# Module-level variables for integrated workflow
$script:IntegratedWorkflowState = @{
    ActiveWorkflows = [hashtable]::Synchronized(@{})
    WorkflowScheduler = [System.Collections.ArrayList]::Synchronized(@())
    CrossStageErrors = [System.Collections.ArrayList]::Synchronized(@())
    PerformanceMetrics = [hashtable]::Synchronized(@{})
    SharedResources = [hashtable]::Synchronized(@{})
}

# Dependency validation helper for functions
function Assert-Dependencies {
    param(
        [string[]]$RequiredDependencies
    )
    
    foreach ($dep in $RequiredDependencies) {
        if (-not $script:RequiredModulesAvailable[$dep]) {
            throw "Required dependency '$dep' is not available. Function cannot execute."
        }
    }
}

# Module loading notification
Write-IntegratedWorkflowLog -Message "Loading Unity-Claude-IntegratedWorkflow module..." -Level "DEBUG"

#region End-to-End Workflow Integration (Hour 1-2)

<#
.SYNOPSIS
Creates a new integrated Unity-Claude workflow orchestrator
.DESCRIPTION
Creates complete end-to-end workflow combining Unity parallelization with Claude parallelization
.PARAMETER WorkflowName
Name for the integrated workflow system
.PARAMETER MaxUnityProjects
Maximum number of Unity projects to monitor simultaneously
.PARAMETER MaxClaudeSubmissions
Maximum number of concurrent Claude submissions
.PARAMETER EnableResourceOptimization
Enable adaptive resource management across workflow stages
.PARAMETER EnableErrorPropagation
Enable comprehensive error propagation across all stages
.EXAMPLE
$workflow = New-IntegratedWorkflow -WorkflowName "UnityClaudeProduction" -MaxUnityProjects 3 -MaxClaudeSubmissions 8 -EnableResourceOptimization -EnableErrorPropagation
#>
function New-IntegratedWorkflow {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$WorkflowName,
        [int]$MaxUnityProjects = 3,
        [int]$MaxClaudeSubmissions = 8,
        [switch]$EnableResourceOptimization,
        [switch]$EnableErrorPropagation
    )
    
    # Validate all required dependencies
    Assert-Dependencies -RequiredDependencies @('RunspaceManagement', 'UnityParallelization', 'ClaudeParallelization')
    
    Write-IntegratedWorkflowLog -Message "Creating integrated Unity-Claude workflow '$WorkflowName'..." -Level "INFO"
    
    try {
        # Validate required modules with hybrid checking (Learning #198)
        $missingModules = @()
        
        @('RunspaceManagement', 'UnityParallelization', 'ClaudeParallelization') | ForEach-Object {
            $module = $_
            $moduleAvailable = $false
            
            if ($script:RequiredModulesAvailable.ContainsKey($module) -and $script:RequiredModulesAvailable[$module]) {
                $moduleAvailable = $true
            } else {
                $actualModule = Get-Module -Name "Unity-Claude-$module" -ErrorAction SilentlyContinue
                if ($actualModule) {
                    $moduleAvailable = $true
                    Write-IntegratedWorkflowLog -Message "$module available via Get-Module fallback ($($actualModule.ExportedCommands.Count) commands)" -Level "DEBUG"
                }
            }
            
            if (-not $moduleAvailable) {
                $missingModules += $module
            }
        }
        
        if ($missingModules.Count -gt 0) {
            throw "Required modules not available: $($missingModules -join ', ')"
        }
        
        Write-IntegratedWorkflowLog -Message "All required modules validated for integrated workflow" -Level "DEBUG"
        
        # Create Unity parallel monitor
        Write-IntegratedWorkflowLog -Message "Creating Unity parallel monitor with $MaxUnityProjects concurrent projects..." -Level "DEBUG"
        
        # Get registered Unity projects
        $registeredProjects = @()
        if (Get-Command Get-RegisteredUnityProjects -ErrorAction SilentlyContinue) {
            $projects = Get-RegisteredUnityProjects
            if ($projects -and $projects.Count -gt 0) {
                $registeredProjects = $projects.Keys | Select-Object -First $MaxUnityProjects
                Write-IntegratedWorkflowLog -Message "Using registered Unity projects: $($registeredProjects -join ', ')" -Level "DEBUG"
            }
        }
        
        # Fall back to default project names if no registered projects found
        if ($registeredProjects.Count -eq 0) {
            $registeredProjects = @("Unity-Project-1", "Unity-Project-2")
            Write-IntegratedWorkflowLog -Message "No registered Unity projects found, using defaults: $($registeredProjects -join ', ')" -Level "WARNING"
        }
        
        $unityMonitor = New-UnityParallelMonitor -MonitorName "$WorkflowName-Unity" -ProjectNames $registeredProjects -MaxRunspaces $MaxUnityProjects -EnableResourceMonitoring:$EnableResourceOptimization
        
        # Create Claude parallel submitter
        Write-IntegratedWorkflowLog -Message "Creating Claude parallel submitter with $MaxClaudeSubmissions concurrent submissions..." -Level "DEBUG"
        $claudeSubmitter = New-ClaudeParallelSubmitter -SubmitterName "$WorkflowName-Claude" -MaxConcurrentRequests $MaxClaudeSubmissions -EnableRateLimiting -EnableResourceMonitoring:$EnableResourceOptimization
        
        # Create shared workflow state
        $workflowState = [hashtable]::Synchronized(@{
            # Workflow coordination
            WorkflowStages = [hashtable]::Synchronized(@{
                UnityMonitoring = @{Status = 'Ready'; LastUpdate = Get-Date; Errors = 0}
                ErrorProcessing = @{Status = 'Ready'; LastUpdate = Get-Date; Errors = 0}
                ClaudeSubmission = @{Status = 'Ready'; LastUpdate = Get-Date; Errors = 0}
                ResponseProcessing = @{Status = 'Ready'; LastUpdate = Get-Date; Errors = 0}
                FixApplication = @{Status = 'Ready'; LastUpdate = Get-Date; Errors = 0}
            })
            
            # Job scheduling and dependencies
            JobQueue = [System.Collections.ArrayList]::Synchronized(@())
            ActiveJobs = [hashtable]::Synchronized(@{})
            CompletedJobs = [System.Collections.ArrayList]::Synchronized(@())
            FailedJobs = [System.Collections.ArrayList]::Synchronized(@())
            
            # Cross-stage communication
            UnityErrorQueue = [System.Collections.ArrayList]::Synchronized(@())
            ClaudePromptQueue = [System.Collections.ArrayList]::Synchronized(@())
            ClaudeResponseQueue = [System.Collections.ArrayList]::Synchronized(@())
            FixQueue = [System.Collections.ArrayList]::Synchronized(@())
            
            # Error propagation
            CrossStageErrors = [System.Collections.ArrayList]::Synchronized(@())
            ErrorRecovery = [hashtable]::Synchronized(@{})
            
            # Performance tracking
            StagePerformance = [hashtable]::Synchronized(@{})
            ResourceUsage = [hashtable]::Synchronized(@{})
            WorkflowMetrics = [hashtable]::Synchronized(@{
                TotalWorkflows = 0
                SuccessfulWorkflows = 0
                FailedWorkflows = 0
                AverageWorkflowTime = 0
                UnityErrorsProcessed = 0
                ClaudeResponsesReceived = 0
                FixesApplied = 0
            })
        })
        
        # Create session state for workflow coordination
        $sessionConfig = New-RunspaceSessionState -LanguageMode 'FullLanguage' -ExecutionPolicy 'Bypass'
        Initialize-SessionStateVariables -SessionStateConfig $sessionConfig | Out-Null
        Add-SharedVariable -SessionStateConfig $sessionConfig -Name "WorkflowState" -Value $workflowState -MakeThreadSafe
        
        # Create workflow orchestration runspace pool
        $orchestrationPool = New-ProductionRunspacePool -SessionStateConfig $sessionConfig -MaxRunspaces 5 -Name "$WorkflowName-Orchestration" -EnableResourceMonitoring:$EnableResourceOptimization
        
        # Create integrated workflow object
        $integratedWorkflow = @{
            WorkflowName = $WorkflowName
            MaxUnityProjects = $MaxUnityProjects
            MaxClaudeSubmissions = $MaxClaudeSubmissions
            EnableResourceOptimization = $EnableResourceOptimization
            EnableErrorPropagation = $EnableErrorPropagation
            Created = Get-Date
            Status = 'Created'
            
            # Component systems
            UnityMonitor = $unityMonitor
            ClaudeSubmitter = $claudeSubmitter
            
            # Workflow coordination
            OrchestrationPool = $orchestrationPool
            SessionConfig = $sessionConfig
            WorkflowState = $workflowState
            
            # Performance and health
            HealthStatus = @{
                OverallHealth = 'Healthy'
                ComponentHealth = @{
                    Unity = 'Healthy'
                    Claude = 'Healthy'
                    Orchestration = 'Healthy'
                }
                LastHealthCheck = Get-Date
            }
            
            # Statistics
            Statistics = @{
                WorkflowsStarted = 0
                WorkflowsCompleted = 0
                WorkflowsFailed = 0
                AverageWorkflowDuration = 0
                UnityErrorsDetected = 0
                ClaudeSubmissionsCompleted = 0
                FixesAppliedSuccessfully = 0
            }
        }
        
        # Store in module-level tracking
        $script:IntegratedWorkflowState.ActiveWorkflows[$WorkflowName] = $integratedWorkflow
        
        Write-IntegratedWorkflowLog -Message "Integrated Unity-Claude workflow '$WorkflowName' created successfully (Unity: $MaxUnityProjects, Claude: $MaxClaudeSubmissions)" -Level "INFO"
        
        return $integratedWorkflow
        
    } catch {
        Write-IntegratedWorkflowLog -Message "Failed to create integrated workflow '$WorkflowName': $($_.Exception.Message)" -Level "ERROR"
        throw
    }
}

<#
.SYNOPSIS
Starts the integrated Unity-Claude workflow orchestration
.DESCRIPTION
Begins coordinated Unity error monitoring and Claude processing workflow
.PARAMETER IntegratedWorkflow
The integrated workflow object from New-IntegratedWorkflow
.PARAMETER UnityProjects
Array of Unity project paths to monitor
.PARAMETER WorkflowMode
Type of workflow operation (Continuous, OnDemand, Batch)
.PARAMETER MonitoringInterval
Interval in seconds for Unity error monitoring
.EXAMPLE
Start-IntegratedWorkflow -IntegratedWorkflow $workflow -UnityProjects @("C:\UnityProject1", "C:\UnityProject2") -WorkflowMode "Continuous" -MonitoringInterval 30
#>
function Start-IntegratedWorkflow {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [hashtable]$IntegratedWorkflow,
        [Parameter(Mandatory)]
        [string[]]$UnityProjects,
        [ValidateSet('Continuous', 'OnDemand', 'Batch')]
        [string]$WorkflowMode = 'Continuous',
        [int]$MonitoringInterval = 30
    )
    
    $workflowName = $IntegratedWorkflow.WorkflowName
    Write-IntegratedWorkflowLog -Message "Starting integrated workflow '$workflowName' in $WorkflowMode mode for $($UnityProjects.Count) Unity projects..." -Level "INFO"
    
    try {
        # Validate Unity projects
        Write-IntegratedWorkflowLog -Message "Validating Unity projects..." -Level "DEBUG"
        $validUnityProjects = @()
        
        foreach ($project in $UnityProjects) {
            if (Test-Path $project) {
                $validUnityProjects += $project
                Write-IntegratedWorkflowLog -Message "Unity project validated: $project" -Level "DEBUG"
            } else {
                Write-IntegratedWorkflowLog -Message "Unity project not found: $project" -Level "WARNING"
            }
        }
        
        if ($validUnityProjects.Count -eq 0) {
            throw "No valid Unity projects found"
        }
        
        Write-IntegratedWorkflowLog -Message "$($validUnityProjects.Count)/$($UnityProjects.Count) Unity projects validated" -Level "INFO"
        
        # Open orchestration runspace pool
        if ($IntegratedWorkflow.OrchestrationPool.Status -ne 'Open') {
            Write-IntegratedWorkflowLog -Message "Opening orchestration runspace pool..." -Level "DEBUG"
            $openResult = Open-RunspacePool -PoolManager $IntegratedWorkflow.OrchestrationPool
            if (-not $openResult.Success) {
                throw "Failed to open orchestration runspace pool: $($openResult.Message)"
            }
        }
        
        # Start Unity monitoring
        Write-IntegratedWorkflowLog -Message "Starting Unity parallel monitoring..." -Level "DEBUG"
        $unityMonitoringResult = Start-UnityParallelMonitoring -UnityMonitor $IntegratedWorkflow.UnityMonitor -UnityProjects $validUnityProjects -MonitoringMode "RealTime" -MonitoringInterval $MonitoringInterval
        
        if (-not $unityMonitoringResult.Success) {
            throw "Failed to start Unity parallel monitoring: $($unityMonitoringResult.Message)"
        }
        
        # Create workflow orchestration script
        $orchestrationScript = {
            param([ref]$WorkflowState, $IntegratedWorkflowConfig, $MonitoringInterval, $WorkflowMode, $WorkflowName)
            
            try {
                Write-Host "[$($WorkflowName)] Starting workflow orchestration in $WorkflowMode mode..." -ForegroundColor Green
                
                $orchestrationStartTime = Get-Date
                $lastUnityCheck = Get-Date
                $workflowCycle = 0
                
                # Main orchestration loop
                while ($true) {
                    $workflowCycle++
                    $cycleStartTime = Get-Date
                    
                    Write-Host "[$($WorkflowName)] Orchestration cycle $workflowCycle started at $($cycleStartTime.ToString('HH:mm:ss.fff'))" -ForegroundColor Gray
                    
                    # Stage 1: Check for Unity errors
                    if (($cycleStartTime - $lastUnityCheck).TotalSeconds -ge $MonitoringInterval) {
                        Write-Host "[$($WorkflowName)] Checking Unity errors..." -ForegroundColor Cyan
                        
                        # Simulate Unity error detection (in real implementation, this would check Unity monitors)
                        $unityErrors = @()
                        $errorSimulation = Get-Random -Maximum 100
                        
                        if ($errorSimulation -lt 30) { # 30% chance of Unity errors
                            $numErrors = Get-Random -Minimum 1 -Maximum 4
                            for ($i = 0; $i -lt $numErrors; $i++) {
                                $unityErrors += @{
                                    ErrorId = "Unity-Error-$(Get-Date -Format 'yyyyMMdd-HHmmss')-$i"
                                    ProjectPath = "C:\UnityProject$((Get-Random -Maximum 3) + 1)"
                                    ErrorType = @("CS0246", "CS0103", "CS1061", "CS0029")[(Get-Random -Maximum 4)]
                                    ErrorMessage = "Simulated Unity compilation error $i"
                                    DetectedTime = Get-Date
                                    ProcessingStatus = "Pending"
                                }
                            }
                            
                            Write-Host "[$($WorkflowName)] $($unityErrors.Count) Unity errors detected" -ForegroundColor Yellow
                        }
                        
                        # Add errors to workflow state
                        foreach ($error in $unityErrors) {
                            $WorkflowState.Value.UnityErrorQueue.Add($error)
                            $WorkflowState.Value.WorkflowMetrics.UnityErrorsProcessed++
                        }
                        
                        $lastUnityCheck = $cycleStartTime
                    }
                    
                    # Stage 2: Process Unity errors for Claude submission
                    $errorsToProcess = @($WorkflowState.Value.UnityErrorQueue | Where-Object { $_.ProcessingStatus -eq "Pending" })
                    
                    if ($errorsToProcess.Count -gt 0) {
                        Write-Host "[$($WorkflowName)] Processing $($errorsToProcess.Count) Unity errors for Claude submission..." -ForegroundColor Cyan
                        
                        foreach ($error in $errorsToProcess) {
                            # Create Claude prompt from Unity error
                            $claudePrompt = @{
                                PromptId = "Claude-Prompt-$(Get-Date -Format 'yyyyMMdd-HHmmss')-$($error.ErrorId)"
                                SourceError = $error
                                PromptText = "Please analyze and provide a fix for this Unity compilation error: $($error.ErrorType) - $($error.ErrorMessage) in project $($error.ProjectPath)"
                                CreatedTime = Get-Date
                                SubmissionStatus = "Ready"
                            }
                            
                            $WorkflowState.Value.ClaudePromptQueue.Add($claudePrompt)
                            $error.ProcessingStatus = "Queued"
                        }
                    }
                    
                    # Stage 3: Submit prompts to Claude (simulation)
                    $promptsToSubmit = @($WorkflowState.Value.ClaudePromptQueue | Where-Object { $_.SubmissionStatus -eq "Ready" })
                    
                    if ($promptsToSubmit.Count -gt 0) {
                        Write-Host "[$($WorkflowName)] Submitting $($promptsToSubmit.Count) prompts to Claude..." -ForegroundColor Cyan
                        
                        foreach ($prompt in $promptsToSubmit) {
                            # Simulate Claude processing time
                            Start-Sleep -Milliseconds (Get-Random -Minimum 500 -Maximum 2000)
                            
                            # Create simulated Claude response
                            $claudeResponse = @{
                                ResponseId = "Claude-Response-$(Get-Date -Format 'yyyyMMdd-HHmmss')-$($prompt.PromptId)"
                                SourcePrompt = $prompt
                                ResponseText = "RECOMMENDED: FIX - Update using directive for $($prompt.SourceError.ErrorType) error"
                                ResponseTime = Get-Date
                                ProcessingStatus = "Ready"
                            }
                            
                            $WorkflowState.Value.ClaudeResponseQueue.Add($claudeResponse)
                            $WorkflowState.Value.WorkflowMetrics.ClaudeResponsesReceived++
                            $prompt.SubmissionStatus = "Completed"
                        }
                    }
                    
                    # Stage 4: Process Claude responses for fix application
                    $responsesToProcess = @($WorkflowState.Value.ClaudeResponseQueue | Where-Object { $_.ProcessingStatus -eq "Ready" })
                    
                    if ($responsesToProcess.Count -gt 0) {
                        Write-Host "[$($WorkflowName)] Processing $($responsesToProcess.Count) Claude responses for fix application..." -ForegroundColor Cyan
                        
                        foreach ($response in $responsesToProcess) {
                            # Create fix application record
                            $fixApplication = @{
                                FixId = "Fix-Application-$(Get-Date -Format 'yyyyMMdd-HHmmss')-$($response.ResponseId)"
                                SourceResponse = $response
                                FixDescription = "Apply fix based on Claude recommendation: $($response.ResponseText)"
                                ApplicationTime = Get-Date
                                ApplicationStatus = "Applied"
                                Success = $true
                            }
                            
                            $WorkflowState.Value.FixQueue.Add($fixApplication)
                            $WorkflowState.Value.WorkflowMetrics.FixesApplied++
                            $response.ProcessingStatus = "Completed"
                            
                            # Mark original error as resolved
                            $response.SourcePrompt.SourceError.ProcessingStatus = "Resolved"
                        }
                    }
                    
                    # Update workflow metrics
                    $cycleEndTime = Get-Date
                    $cycleDuration = ($cycleEndTime - $cycleStartTime).TotalMilliseconds
                    
                    $WorkflowState.Value.StagePerformance["Cycle-$workflowCycle"] = @{
                        Duration = $cycleDuration
                        UnityErrors = $errorsToProcess.Count
                        ClaudePrompts = $promptsToSubmit.Count
                        ClaudeResponses = $responsesToProcess.Count
                        FixesApplied = $responsesToProcess.Count
                    }
                    
                    Write-Host "[$($WorkflowName)] Orchestration cycle $workflowCycle completed in ${cycleDuration}ms" -ForegroundColor Gray
                    
                    # Break conditions for different modes
                    if ($WorkflowMode -eq "OnDemand") {
                        if ($WorkflowState.Value.UnityErrorQueue.Count -eq 0 -and 
                            $WorkflowState.Value.ClaudePromptQueue.Count -eq 0 -and 
                            $WorkflowState.Value.ClaudeResponseQueue.Count -eq 0) {
                            Write-Host "[$($WorkflowName)] OnDemand workflow completed - all queues empty" -ForegroundColor Green
                            break
                        }
                    } elseif ($WorkflowMode -eq "Batch") {
                        if ($workflowCycle -ge 10) { # Process 10 cycles for batch mode
                            Write-Host "[$($WorkflowName)] Batch workflow completed - maximum cycles reached" -ForegroundColor Green
                            break
                        }
                    }
                    
                    # Sleep between cycles for continuous mode
                    if ($WorkflowMode -eq "Continuous") {
                        Start-Sleep -Seconds 5
                    } else {
                        Start-Sleep -Seconds 1
                    }
                    
                    # Safety exit after 5 minutes
                    if (($cycleEndTime - $orchestrationStartTime).TotalMinutes -ge 5) {
                        Write-Host "[$($WorkflowName)] Workflow orchestration stopped - maximum runtime reached" -ForegroundColor Yellow
                        break
                    }
                }
                
                $totalDuration = ((Get-Date) - $orchestrationStartTime).TotalMilliseconds
                Write-Host "[$($WorkflowName)] Workflow orchestration completed: $workflowCycle cycles in ${totalDuration}ms" -ForegroundColor Green
                
                return "Workflow orchestration successful: $workflowCycle cycles completed in ${totalDuration}ms"
                
            } catch {
                Write-Host "[$($WorkflowName)] Workflow orchestration error: $($_.Exception.Message)" -ForegroundColor Red
                return "Workflow orchestration failed: $($_.Exception.Message)"
            }
        }
        
        # Start workflow orchestration
        Write-IntegratedWorkflowLog -Message "Starting workflow orchestration..." -Level "INFO"
        
        $ps = [powershell]::Create()
        $ps.RunspacePool = $IntegratedWorkflow.OrchestrationPool.RunspacePool
        $ps.AddScript($orchestrationScript)
        $ps.AddArgument([ref]$IntegratedWorkflow.WorkflowState)
        $ps.AddArgument(@{
            WorkflowName = $workflowName
            WorkflowMode = $WorkflowMode
            MonitoringInterval = $MonitoringInterval
            UnityProjects = $validUnityProjects
        })
        $ps.AddArgument($MonitoringInterval)
        $ps.AddArgument($WorkflowMode)
        $ps.AddArgument($workflowName)
        
        $asyncResult = $ps.BeginInvoke()
        
        # Store orchestration job reference
        $IntegratedWorkflow.OrchestrationJob = @{
            PowerShell = $ps
            AsyncResult = $asyncResult
            StartTime = Get-Date
            Status = 'Running'
        }
        
        # Update workflow status
        $IntegratedWorkflow.Status = 'Running'
        $IntegratedWorkflow.WorkflowState.WorkflowStages.UnityMonitoring.Status = 'Active'
        $IntegratedWorkflow.Statistics.WorkflowsStarted++
        
        Write-IntegratedWorkflowLog -Message "Integrated workflow '$workflowName' started successfully in $WorkflowMode mode" -Level "INFO"
        
        return @{
            Success = $true
            Message = "Integrated workflow started successfully"
            WorkflowName = $workflowName
            WorkflowMode = $WorkflowMode
            UnityProjects = $validUnityProjects.Count
            OrchestrationStatus = 'Running'
        }
        
    } catch {
        Write-IntegratedWorkflowLog -Message "Failed to start integrated workflow '$workflowName': $($_.Exception.Message)" -Level "ERROR"
        throw
    }
}

<#
.SYNOPSIS
Gets the status and performance metrics of an integrated workflow
.DESCRIPTION
Returns comprehensive status information about workflow stages, performance, and health
.PARAMETER IntegratedWorkflow
The integrated workflow object to query
.PARAMETER IncludeDetailedMetrics
Include detailed performance metrics for each stage
.EXAMPLE
$status = Get-IntegratedWorkflowStatus -IntegratedWorkflow $workflow -IncludeDetailedMetrics
#>
function Get-IntegratedWorkflowStatus {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [hashtable]$IntegratedWorkflow,
        [switch]$IncludeDetailedMetrics
    )
    
    try {
        $workflowName = $IntegratedWorkflow.WorkflowName
        Write-IntegratedWorkflowLog -Message "Getting status for integrated workflow '$workflowName'..." -Level "DEBUG"
        
        # Get current orchestration status
        $orchestrationStatus = 'Stopped'
        $orchestrationDuration = 0
        
        if ($IntegratedWorkflow.ContainsKey('OrchestrationJob') -and $IntegratedWorkflow.OrchestrationJob) {
            if ($IntegratedWorkflow.OrchestrationJob.AsyncResult.IsCompleted) {
                $orchestrationStatus = 'Completed'
            } else {
                $orchestrationStatus = 'Running'
            }
            
            $orchestrationDuration = ((Get-Date) - $IntegratedWorkflow.OrchestrationJob.StartTime).TotalSeconds
        }
        
        # Build status summary
        $workflowStatus = @{
            WorkflowName = $workflowName
            OverallStatus = $IntegratedWorkflow.Status
            OrchestrationStatus = $orchestrationStatus
            OrchestrationDuration = $orchestrationDuration
            CreatedTime = $IntegratedWorkflow.Created
            LastUpdate = Get-Date
            
            # Component status
            Components = @{
                UnityMonitor = @{
                    Status = if ($IntegratedWorkflow.UnityMonitor) { 'Available' } else { 'Not Available' }
                    MaxConcurrentProjects = $IntegratedWorkflow.MaxUnityProjects
                }
                ClaudeSubmitter = @{
                    Status = if ($IntegratedWorkflow.ClaudeSubmitter) { 'Available' } else { 'Not Available' }
                    MaxConcurrentSubmissions = $IntegratedWorkflow.MaxClaudeSubmissions
                }
                OrchestrationPool = @{
                    Status = $IntegratedWorkflow.OrchestrationPool.Status
                    MaxRunspaces = $IntegratedWorkflow.OrchestrationPool.MaxRunspaces
                }
            }
            
            # Workflow stage status
            StageStatus = $IntegratedWorkflow.WorkflowState.WorkflowStages
            
            # Queue lengths (current work)
            Queues = @{
                UnityErrors = $IntegratedWorkflow.WorkflowState.UnityErrorQueue.Count
                ClaudePrompts = $IntegratedWorkflow.WorkflowState.ClaudePromptQueue.Count
                ClaudeResponses = $IntegratedWorkflow.WorkflowState.ClaudeResponseQueue.Count
                Fixes = $IntegratedWorkflow.WorkflowState.FixQueue.Count
                ActiveJobs = $IntegratedWorkflow.WorkflowState.ActiveJobs.Count
                CompletedJobs = $IntegratedWorkflow.WorkflowState.CompletedJobs.Count
                FailedJobs = $IntegratedWorkflow.WorkflowState.FailedJobs.Count
            }
            
            # Workflow metrics
            Metrics = $IntegratedWorkflow.WorkflowState.WorkflowMetrics
            
            # Health status
            Health = $IntegratedWorkflow.HealthStatus
        }
        
        # Add detailed performance metrics if requested
        if ($IncludeDetailedMetrics) {
            $workflowStatus.DetailedMetrics = @{
                StagePerformance = $IntegratedWorkflow.WorkflowState.StagePerformance
                ResourceUsage = $IntegratedWorkflow.WorkflowState.ResourceUsage
                ErrorHistory = $IntegratedWorkflow.WorkflowState.CrossStageErrors
            }
        }
        
        Write-IntegratedWorkflowLog -Message "Status retrieved for workflow '$workflowName': $orchestrationStatus ($($orchestrationDuration)s)" -Level "DEBUG"
        
        return $workflowStatus
        
    } catch {
        Write-IntegratedWorkflowLog -Message "Failed to get workflow status: $($_.Exception.Message)" -Level "ERROR"
        throw
    }
}

<#
.SYNOPSIS
Stops an integrated workflow and cleans up resources
.DESCRIPTION
Gracefully stops workflow orchestration and disposes of all resources
.PARAMETER IntegratedWorkflow
The integrated workflow object to stop
.PARAMETER WaitForCompletion
Wait for current operations to complete before stopping
.PARAMETER TimeoutSeconds
Maximum time to wait for graceful shutdown
.EXAMPLE
Stop-IntegratedWorkflow -IntegratedWorkflow $workflow -WaitForCompletion -TimeoutSeconds 60
#>
function Stop-IntegratedWorkflow {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [hashtable]$IntegratedWorkflow,
        [switch]$WaitForCompletion,
        [int]$TimeoutSeconds = 30
    )
    
    $workflowName = $IntegratedWorkflow.WorkflowName
    Write-IntegratedWorkflowLog -Message "Stopping integrated workflow '$workflowName'..." -Level "INFO"
    
    try {
        $stopStartTime = Get-Date
        
        # Stop orchestration job if running
        if ($IntegratedWorkflow.ContainsKey('OrchestrationJob') -and $IntegratedWorkflow.OrchestrationJob) {
            Write-IntegratedWorkflowLog -Message "Stopping workflow orchestration job..." -Level "DEBUG"
            
            if (-not $IntegratedWorkflow.OrchestrationJob.AsyncResult.IsCompleted) {
                if ($WaitForCompletion) {
                    Write-IntegratedWorkflowLog -Message "Waiting for orchestration job to complete (timeout: $TimeoutSeconds seconds)..." -Level "DEBUG"
                    
                    $waitStart = Get-Date
                    while (-not $IntegratedWorkflow.OrchestrationJob.AsyncResult.IsCompleted) {
                        if (((Get-Date) - $waitStart).TotalSeconds -ge $TimeoutSeconds) {
                            Write-IntegratedWorkflowLog -Message "Timeout waiting for orchestration job completion" -Level "WARNING"
                            break
                        }
                        Start-Sleep -Milliseconds 500
                    }
                }
                
                # Force stop if still running
                if (-not $IntegratedWorkflow.OrchestrationJob.AsyncResult.IsCompleted) {
                    Write-IntegratedWorkflowLog -Message "Force stopping orchestration job..." -Level "WARNING"
                    try {
                        $IntegratedWorkflow.OrchestrationJob.PowerShell.Stop()
                    } catch {
                        Write-IntegratedWorkflowLog -Message "Error force stopping job: $($_.Exception.Message)" -Level "WARNING"
                    }
                }
            }
            
            # Collect final results and dispose
            try {
                if ($IntegratedWorkflow.OrchestrationJob.AsyncResult.IsCompleted) {
                    $result = $IntegratedWorkflow.OrchestrationJob.PowerShell.EndInvoke($IntegratedWorkflow.OrchestrationJob.AsyncResult)
                    Write-IntegratedWorkflowLog -Message "Orchestration job result: $result" -Level "DEBUG"
                }
                $IntegratedWorkflow.OrchestrationJob.PowerShell.Dispose()
            } catch {
                Write-IntegratedWorkflowLog -Message "Error disposing orchestration job: $($_.Exception.Message)" -Level "WARNING"
            }
            
            $IntegratedWorkflow.Remove('OrchestrationJob')
        }
        
        # Close runspace pools
        Write-IntegratedWorkflowLog -Message "Closing orchestration runspace pool..." -Level "DEBUG"
        if ($IntegratedWorkflow.OrchestrationPool.Status -eq 'Open') {
            Close-RunspacePool -PoolManager $IntegratedWorkflow.OrchestrationPool | Out-Null
        }
        
        # Stop Unity monitoring
        if ($IntegratedWorkflow.UnityMonitor) {
            Write-IntegratedWorkflowLog -Message "Stopping Unity parallel monitoring..." -Level "DEBUG"
            try {
                Stop-UnityParallelMonitoring -UnityMonitor $IntegratedWorkflow.UnityMonitor | Out-Null
            } catch {
                Write-IntegratedWorkflowLog -Message "Error stopping Unity monitoring: $($_.Exception.Message)" -Level "WARNING"
            }
        }
        
        # Close Claude submitter resources
        if ($IntegratedWorkflow.ClaudeSubmitter -and $IntegratedWorkflow.ClaudeSubmitter.RunspacePool) {
            Write-IntegratedWorkflowLog -Message "Closing Claude submitter runspace pool..." -Level "DEBUG"
            try {
                Close-RunspacePool -PoolManager $IntegratedWorkflow.ClaudeSubmitter.RunspacePool | Out-Null
            } catch {
                Write-IntegratedWorkflowLog -Message "Error closing Claude submitter: $($_.Exception.Message)" -Level "WARNING"
            }
        }
        
        # Update workflow status
        $IntegratedWorkflow.Status = 'Stopped'
        $IntegratedWorkflow.WorkflowState.WorkflowStages.UnityMonitoring.Status = 'Stopped'
        $IntegratedWorkflow.WorkflowState.WorkflowStages.ErrorProcessing.Status = 'Stopped'
        $IntegratedWorkflow.WorkflowState.WorkflowStages.ClaudeSubmission.Status = 'Stopped'
        $IntegratedWorkflow.WorkflowState.WorkflowStages.ResponseProcessing.Status = 'Stopped'
        $IntegratedWorkflow.WorkflowState.WorkflowStages.FixApplication.Status = 'Stopped'
        
        # Calculate final statistics
        $stopDuration = ((Get-Date) - $stopStartTime).TotalMilliseconds
        $IntegratedWorkflow.Statistics.WorkflowsCompleted++
        
        # Remove from module tracking
        if ($script:IntegratedWorkflowState.ActiveWorkflows.ContainsKey($workflowName)) {
            $script:IntegratedWorkflowState.ActiveWorkflows.Remove($workflowName)
        }
        
        Write-IntegratedWorkflowLog -Message "Integrated workflow '$workflowName' stopped successfully (shutdown time: ${stopDuration}ms)" -Level "INFO"
        
        return @{
            Success = $true
            Message = "Workflow stopped successfully"
            WorkflowName = $workflowName
            ShutdownDuration = $stopDuration
            FinalMetrics = $IntegratedWorkflow.WorkflowState.WorkflowMetrics
        }
        
    } catch {
        Write-IntegratedWorkflowLog -Message "Failed to stop integrated workflow '$workflowName': $($_.Exception.Message)" -Level "ERROR"
        throw
    }
}

#endregion

#region Performance Optimization Framework (Hour 3-4)

<#
.SYNOPSIS
Creates an adaptive throttling system for integrated workflow performance optimization
.DESCRIPTION
Monitors system resources and automatically adjusts concurrent operations for optimal performance
.PARAMETER IntegratedWorkflow
The integrated workflow object to optimize
.PARAMETER EnableCPUThrottling
Enable CPU usage-based throttling
.PARAMETER EnableMemoryThrottling
Enable memory usage-based throttling
.PARAMETER CPUThreshold
CPU usage percentage threshold for throttling (default: 80)
.PARAMETER MemoryThreshold
Memory usage percentage threshold for throttling (default: 85)
.EXAMPLE
Initialize-AdaptiveThrottling -IntegratedWorkflow $workflow -EnableCPUThrottling -EnableMemoryThrottling -CPUThreshold 75 -MemoryThreshold 80
#>
function Initialize-AdaptiveThrottling {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [hashtable]$IntegratedWorkflow,
        [switch]$EnableCPUThrottling,
        [switch]$EnableMemoryThrottling,
        [int]$CPUThreshold = 80,
        [int]$MemoryThreshold = 85
    )
    
    $workflowName = $IntegratedWorkflow.WorkflowName
    Write-IntegratedWorkflowLog -Message "Initializing adaptive throttling for workflow '$workflowName' (CPU: $CPUThreshold%, Memory: $MemoryThreshold%)..." -Level "INFO"
    
    try {
        # Create adaptive throttling configuration
        $throttlingConfig = @{
            EnableCPUThrottling = $EnableCPUThrottling
            EnableMemoryThrottling = $EnableMemoryThrottling
            CPUThreshold = $CPUThreshold
            MemoryThreshold = $MemoryThreshold
            LastResourceCheck = Get-Date
            ResourceCheckInterval = 5  # seconds
            
            # Throttling state
            CurrentCPUUsage = 0
            CurrentMemoryUsage = 0
            ThrottlingActive = $false
            ThrottlingHistory = [System.Collections.ArrayList]::Synchronized(@())
            
            # Performance counters for monitoring
            PerformanceCounters = @{
                CPU = if (Get-Command Get-Counter -ErrorAction SilentlyContinue) { 
                    @{
                        Available = $true
                        CounterPath = '\Processor(_Total)\% Processor Time'
                    }
                } else { 
                    @{Available = $false} 
                }
                Memory = if (Get-Command Get-Counter -ErrorAction SilentlyContinue) { 
                    @{
                        Available = $true
                        CounterPath = '\Memory\Available MBytes'
                        TotalMemoryMB = [math]::Round((Get-CimInstance Win32_ComputerSystem).TotalPhysicalMemory / 1MB, 0)
                    }
                } else { 
                    @{Available = $false} 
                }
            }
            
            # Adaptive adjustments
            AdaptiveAdjustments = @{
                UnityMaxProjects = $IntegratedWorkflow.MaxUnityProjects
                ClaudeMaxSubmissions = $IntegratedWorkflow.MaxClaudeSubmissions
                OriginalUnityMax = $IntegratedWorkflow.MaxUnityProjects
                OriginalClaudeMax = $IntegratedWorkflow.MaxClaudeSubmissions
            }
        }
        
        # Add throttling config to workflow state
        $IntegratedWorkflow.WorkflowState.AdaptiveThrottling = $throttlingConfig
        
        Write-IntegratedWorkflowLog -Message "Adaptive throttling initialized for workflow '$workflowName'" -Level "DEBUG"
        Write-IntegratedWorkflowLog -Message "Performance counters available - CPU: $($throttlingConfig.PerformanceCounters.CPU.Available), Memory: $($throttlingConfig.PerformanceCounters.Memory.Available)" -Level "DEBUG"
        
        return @{
            Success = $true
            Message = "Adaptive throttling initialized successfully"
            Configuration = $throttlingConfig
        }
        
    } catch {
        Write-IntegratedWorkflowLog -Message "Failed to initialize adaptive throttling: $($_.Exception.Message)" -Level "ERROR"
        throw
    }
}

<#
.SYNOPSIS
Updates adaptive throttling based on current system resource usage
.DESCRIPTION
Monitors CPU and memory usage and adjusts workflow concurrency settings
.PARAMETER IntegratedWorkflow
The integrated workflow object to update
.EXAMPLE
Update-AdaptiveThrottling -IntegratedWorkflow $workflow
#>
function Update-AdaptiveThrottling {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [hashtable]$IntegratedWorkflow
    )
    
    try {
        if (-not $IntegratedWorkflow.WorkflowState.ContainsKey('AdaptiveThrottling')) {
            Write-IntegratedWorkflowLog -Message "Adaptive throttling not initialized - skipping update" -Level "DEBUG"
            return $false
        }
        
        $throttlingConfig = $IntegratedWorkflow.WorkflowState.AdaptiveThrottling
        $currentTime = Get-Date
        
        # Check if it's time for resource monitoring
        if (($currentTime - $throttlingConfig.LastResourceCheck).TotalSeconds -lt $throttlingConfig.ResourceCheckInterval) {
            return $false  # Not time for update yet
        }
        
        $workflowName = $IntegratedWorkflow.WorkflowName
        Write-IntegratedWorkflowLog -Message "Updating adaptive throttling for workflow '$workflowName'..." -Level "DEBUG"
        
        $resourceSnapshot = @{
            Timestamp = $currentTime
            CPU = 0
            Memory = 0
            ThrottlingApplied = $false
            Adjustments = @{}
        }
        
        # Get current CPU usage
        if ($throttlingConfig.EnableCPUThrottling -and $throttlingConfig.PerformanceCounters.CPU.Available) {
            try {
                $cpuCounter = Get-Counter $throttlingConfig.PerformanceCounters.CPU.CounterPath -SampleInterval 1 -MaxSamples 1 -ErrorAction Stop
                $throttlingConfig.CurrentCPUUsage = [math]::Round($cpuCounter.CounterSamples[0].CookedValue, 2)
                $resourceSnapshot.CPU = $throttlingConfig.CurrentCPUUsage
                
                Write-IntegratedWorkflowLog -Message "Current CPU usage: $($throttlingConfig.CurrentCPUUsage)%" -Level "DEBUG"
            } catch {
                Write-IntegratedWorkflowLog -Message "Failed to get CPU usage: $($_.Exception.Message)" -Level "WARNING"
            }
        }
        
        # Get current memory usage
        if ($throttlingConfig.EnableMemoryThrottling -and $throttlingConfig.PerformanceCounters.Memory.Available) {
            try {
                $memoryCounter = Get-Counter $throttlingConfig.PerformanceCounters.Memory.CounterPath -SampleInterval 1 -MaxSamples 1 -ErrorAction Stop
                $availableMemoryMB = $memoryCounter.CounterSamples[0].CookedValue
                $usedMemoryPercent = [math]::Round((($throttlingConfig.PerformanceCounters.Memory.TotalMemoryMB - $availableMemoryMB) / $throttlingConfig.PerformanceCounters.Memory.TotalMemoryMB) * 100, 2)
                $throttlingConfig.CurrentMemoryUsage = $usedMemoryPercent
                $resourceSnapshot.Memory = $usedMemoryPercent
                
                Write-IntegratedWorkflowLog -Message "Current memory usage: $($throttlingConfig.CurrentMemoryUsage)% (Available: ${availableMemoryMB}MB)" -Level "DEBUG"
            } catch {
                Write-IntegratedWorkflowLog -Message "Failed to get memory usage: $($_.Exception.Message)" -Level "WARNING"
            }
        }
        
        # Determine if throttling is needed
        $shouldThrottle = $false
        $throttleReason = @()
        
        if ($throttlingConfig.EnableCPUThrottling -and $throttlingConfig.CurrentCPUUsage -gt $throttlingConfig.CPUThreshold) {
            $shouldThrottle = $true
            $throttleReason += "CPU: $($throttlingConfig.CurrentCPUUsage)% > $($throttlingConfig.CPUThreshold)%"
        }
        
        if ($throttlingConfig.EnableMemoryThrottling -and $throttlingConfig.CurrentMemoryUsage -gt $throttlingConfig.MemoryThreshold) {
            $shouldThrottle = $true
            $throttleReason += "Memory: $($throttlingConfig.CurrentMemoryUsage)% > $($throttlingConfig.MemoryThreshold)%"
        }
        
        # Apply throttling adjustments
        if ($shouldThrottle -and -not $throttlingConfig.ThrottlingActive) {
            Write-IntegratedWorkflowLog -Message "Applying throttling due to: $($throttleReason -join ', ')" -Level "WARNING"
            
            # Reduce concurrent operations by 50%
            $newUnityMax = [math]::Max(1, [math]::Floor($throttlingConfig.AdaptiveAdjustments.UnityMaxProjects * 0.5))
            $newClaudeMax = [math]::Max(1, [math]::Floor($throttlingConfig.AdaptiveAdjustments.ClaudeMaxSubmissions * 0.5))
            
            $throttlingConfig.AdaptiveAdjustments.UnityMaxProjects = $newUnityMax
            $throttlingConfig.AdaptiveAdjustments.ClaudeMaxSubmissions = $newClaudeMax
            $throttlingConfig.ThrottlingActive = $true
            
            $resourceSnapshot.ThrottlingApplied = $true
            $resourceSnapshot.Adjustments = @{
                UnityProjects = "$($IntegratedWorkflow.MaxUnityProjects) -> $newUnityMax"
                ClaudeSubmissions = "$($IntegratedWorkflow.MaxClaudeSubmissions) -> $newClaudeMax"
                Reason = $throttleReason -join ', '
            }
            
            Write-IntegratedWorkflowLog -Message "Throttling applied: Unity $($IntegratedWorkflow.MaxUnityProjects)->$newUnityMax, Claude $($IntegratedWorkflow.MaxClaudeSubmissions)->$newClaudeMax" -Level "INFO"
            
        } elseif (-not $shouldThrottle -and $throttlingConfig.ThrottlingActive) {
            Write-IntegratedWorkflowLog -Message "Resource usage normalized - removing throttling restrictions" -Level "INFO"
            
            # Gradually restore original limits (75% of original)
            $restoreUnityMax = [math]::Min($throttlingConfig.AdaptiveAdjustments.OriginalUnityMax, [math]::Ceiling($throttlingConfig.AdaptiveAdjustments.OriginalUnityMax * 0.75))
            $restoreClaudeMax = [math]::Min($throttlingConfig.AdaptiveAdjustments.OriginalClaudeMax, [math]::Ceiling($throttlingConfig.AdaptiveAdjustments.OriginalClaudeMax * 0.75))
            
            $throttlingConfig.AdaptiveAdjustments.UnityMaxProjects = $restoreUnityMax
            $throttlingConfig.AdaptiveAdjustments.ClaudeMaxSubmissions = $restoreClaudeMax
            $throttlingConfig.ThrottlingActive = $false
            
            $resourceSnapshot.Adjustments = @{
                UnityProjects = "Restored to $restoreUnityMax"
                ClaudeSubmissions = "Restored to $restoreClaudeMax"
                Reason = "Resource usage normalized"
            }
            
            Write-IntegratedWorkflowLog -Message "Throttling removed: Unity restored to $restoreUnityMax, Claude restored to $restoreClaudeMax" -Level "INFO"
        }
        
        # Update last check time
        $throttlingConfig.LastResourceCheck = $currentTime
        
        # Add to history
        $throttlingConfig.ThrottlingHistory.Add($resourceSnapshot)
        
        # Limit history to last 100 entries
        if ($throttlingConfig.ThrottlingHistory.Count -gt 100) {
            $throttlingConfig.ThrottlingHistory.RemoveAt(0)
        }
        
        return $resourceSnapshot.ThrottlingApplied
        
    } catch {
        Write-IntegratedWorkflowLog -Message "Failed to update adaptive throttling: $($_.Exception.Message)" -Level "ERROR"
        return $false
    }
}

<#
.SYNOPSIS
Creates intelligent job batching for optimal parallel processing performance
.DESCRIPTION
Analyzes workload characteristics and creates optimized job batches for maximum throughput
.PARAMETER IntegratedWorkflow
The integrated workflow to optimize
.PARAMETER JobQueue
Array of jobs to batch for processing
.PARAMETER BatchingStrategy
Strategy for job batching (BySize, ByType, ByPriority, Hybrid)
.PARAMETER MaxBatchSize
Maximum number of jobs per batch
.EXAMPLE
$batches = New-IntelligentJobBatching -IntegratedWorkflow $workflow -JobQueue $jobs -BatchingStrategy "Hybrid" -MaxBatchSize 10
#>
function New-IntelligentJobBatching {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [hashtable]$IntegratedWorkflow,
        [Parameter(Mandatory)]
        [array]$JobQueue,
        [ValidateSet('BySize', 'ByType', 'ByPriority', 'Hybrid')]
        [string]$BatchingStrategy = 'Hybrid',
        [int]$MaxBatchSize = 10
    )
    
    $workflowName = $IntegratedWorkflow.WorkflowName
    Write-IntegratedWorkflowLog -Message "Creating intelligent job batching for workflow '$workflowName' with $($JobQueue.Count) jobs using $BatchingStrategy strategy..." -Level "INFO"
    
    try {
        if ($JobQueue.Count -eq 0) {
            Write-IntegratedWorkflowLog -Message "No jobs to batch - returning empty result" -Level "DEBUG"
            return @{
                Batches = @()
                BatchingStrategy = $BatchingStrategy
                TotalJobs = 0
                TotalBatches = 0
            }
        }
        
        $batchingStartTime = Get-Date
        $batches = @()
        
        # Analyze job characteristics
        $jobAnalysis = @{
            TotalJobs = $JobQueue.Count
            JobTypes = @{}
            JobSizes = @()
            JobPriorities = @{}
            AverageJobSize = 0
        }
        
        foreach ($job in $JobQueue) {
            # Analyze job type
            $jobType = if ($job.ContainsKey('Type')) { $job.Type } else { 'Unknown' }
            if (-not $jobAnalysis.JobTypes.ContainsKey($jobType)) {
                $jobAnalysis.JobTypes[$jobType] = 0
            }
            $jobAnalysis.JobTypes[$jobType]++
            
            # Analyze job size (estimated processing time or complexity)
            $jobSize = if ($job.ContainsKey('EstimatedDuration')) { 
                $job.EstimatedDuration 
            } elseif ($job.ContainsKey('Complexity')) { 
                $job.Complexity 
            } else { 
                1  # Default size
            }
            $jobAnalysis.JobSizes += $jobSize
            
            # Analyze job priority
            $jobPriority = if ($job.ContainsKey('Priority')) { $job.Priority } else { 'Normal' }
            if (-not $jobAnalysis.JobPriorities.ContainsKey($jobPriority)) {
                $jobAnalysis.JobPriorities[$jobPriority] = 0
            }
            $jobAnalysis.JobPriorities[$jobPriority]++
        }
        
        $jobAnalysis.AverageJobSize = if ($jobAnalysis.JobSizes.Count -gt 0) { 
            ($jobAnalysis.JobSizes | Measure-Object -Average).Average 
        } else { 
            1 
        }
        
        Write-IntegratedWorkflowLog -Message "Job analysis: Types: $($jobAnalysis.JobTypes.Count), Avg Size: $($jobAnalysis.AverageJobSize), Priorities: $($jobAnalysis.JobPriorities.Count)" -Level "DEBUG"
        
        # Create batches based on strategy
        switch ($BatchingStrategy) {
            'BySize' {
                Write-IntegratedWorkflowLog -Message "Creating batches by size..." -Level "DEBUG"
                
                # Sort jobs by size and create balanced batches
                $sortedJobs = $JobQueue | Sort-Object { 
                    if ($_.ContainsKey('EstimatedDuration')) { $_.EstimatedDuration }
                    elseif ($_.ContainsKey('Complexity')) { $_.Complexity }
                    else { 1 }
                } -Descending
                
                $currentBatch = @()
                $currentBatchSize = 0
                $targetBatchSize = $jobAnalysis.AverageJobSize * $MaxBatchSize
                
                foreach ($job in $sortedJobs) {
                    $jobSize = if ($job.ContainsKey('EstimatedDuration')) { 
                        $job.EstimatedDuration 
                    } elseif ($job.ContainsKey('Complexity')) { 
                        $job.Complexity 
                    } else { 
                        1 
                    }
                    
                    if ($currentBatch.Count -ge $MaxBatchSize -or 
                        ($currentBatchSize + $jobSize -gt $targetBatchSize -and $currentBatch.Count -gt 0)) {
                        $batches += @{
                            BatchId = "SizeBatch-$($batches.Count + 1)"
                            Jobs = $currentBatch
                            TotalSize = $currentBatchSize
                            JobCount = $currentBatch.Count
                        }
                        $currentBatch = @()
                        $currentBatchSize = 0
                    }
                    
                    $currentBatch += $job
                    $currentBatchSize += $jobSize
                }
                
                # Add final batch if not empty
                if ($currentBatch.Count -gt 0) {
                    $batches += @{
                        BatchId = "SizeBatch-$($batches.Count + 1)"
                        Jobs = $currentBatch
                        TotalSize = $currentBatchSize
                        JobCount = $currentBatch.Count
                    }
                }
            }
            
            'ByType' {
                Write-IntegratedWorkflowLog -Message "Creating batches by type..." -Level "DEBUG"
                
                # Group jobs by type
                $jobGroups = $JobQueue | Group-Object { 
                    if ($_.ContainsKey('Type')) { $_.Type } else { 'Unknown' }
                }
                
                foreach ($group in $jobGroups) {
                    $groupJobs = @($group.Group)
                    
                    # Split large groups into multiple batches
                    for ($i = 0; $i -lt $groupJobs.Count; $i += $MaxBatchSize) {
                        $batchJobs = $groupJobs[$i..[math]::Min($i + $MaxBatchSize - 1, $groupJobs.Count - 1)]
                        
                        $batches += @{
                            BatchId = "TypeBatch-$($group.Name)-$([math]::Floor($i / $MaxBatchSize) + 1)"
                            Jobs = $batchJobs
                            JobType = $group.Name
                            JobCount = $batchJobs.Count
                        }
                    }
                }
            }
            
            'ByPriority' {
                Write-IntegratedWorkflowLog -Message "Creating batches by priority..." -Level "DEBUG"
                
                # Sort by priority (High, Normal, Low) and create batches
                $priorityOrder = @('High', 'Critical', 'Normal', 'Low')
                $sortedJobs = $JobQueue | Sort-Object { 
                    $priority = if ($_.ContainsKey('Priority')) { $_.Priority } else { 'Normal' }
                    $priorityIndex = $priorityOrder.IndexOf($priority)
                    if ($priorityIndex -eq -1) { 2 } else { $priorityIndex }  # Default to Normal
                }
                
                # Create batches preserving priority order
                for ($i = 0; $i -lt $sortedJobs.Count; $i += $MaxBatchSize) {
                    $batchJobs = $sortedJobs[$i..[math]::Min($i + $MaxBatchSize - 1, $sortedJobs.Count - 1)]
                    
                    $batches += @{
                        BatchId = "PriorityBatch-$([math]::Floor($i / $MaxBatchSize) + 1)"
                        Jobs = $batchJobs
                        JobCount = $batchJobs.Count
                        PriorityRange = "$($batchJobs[0].Priority) to $($batchJobs[-1].Priority)"
                    }
                }
            }
            
            'Hybrid' {
                Write-IntegratedWorkflowLog -Message "Creating hybrid optimized batches..." -Level "DEBUG"
                
                # Hybrid approach: prioritize high-priority jobs, then balance by size and type
                $highPriorityJobs = @($JobQueue | Where-Object { 
                    $_.ContainsKey('Priority') -and $_.Priority -in @('High', 'Critical', 'Urgent') 
                })
                $normalJobs = @($JobQueue | Where-Object { 
                    -not $_.ContainsKey('Priority') -or $_.Priority -notin @('High', 'Critical', 'Urgent') 
                })
                
                # Create high-priority batches first
                if ($highPriorityJobs.Count -gt 0) {
                    for ($i = 0; $i -lt $highPriorityJobs.Count; $i += $MaxBatchSize) {
                        $batchJobs = $highPriorityJobs[$i..[math]::Min($i + $MaxBatchSize - 1, $highPriorityJobs.Count - 1)]
                        
                        $batches += @{
                            BatchId = "HybridPriority-$([math]::Floor($i / $MaxBatchSize) + 1)"
                            Jobs = $batchJobs
                            JobCount = $batchJobs.Count
                            BatchType = "HighPriority"
                        }
                    }
                }
                
                # Create balanced batches for normal jobs
                if ($normalJobs.Count -gt 0) {
                    # Group by type, then create size-balanced batches within types
                    $typeGroups = $normalJobs | Group-Object { 
                        if ($_.ContainsKey('Type')) { $_.Type } else { 'Normal' }
                    }
                    
                    foreach ($group in $typeGroups) {
                        $groupJobs = @($group.Group | Sort-Object { 
                            if ($_.ContainsKey('EstimatedDuration')) { $_.EstimatedDuration }
                            elseif ($_.ContainsKey('Complexity')) { $_.Complexity }
                            else { 1 }
                        })
                        
                        for ($i = 0; $i -lt $groupJobs.Count; $i += $MaxBatchSize) {
                            $batchJobs = $groupJobs[$i..[math]::Min($i + $MaxBatchSize - 1, $groupJobs.Count - 1)]
                            
                            $batches += @{
                                BatchId = "HybridType-$($group.Name)-$([math]::Floor($i / $MaxBatchSize) + 1)"
                                Jobs = $batchJobs
                                JobCount = $batchJobs.Count
                                BatchType = "TypeBalanced"
                                JobType = $group.Name
                            }
                        }
                    }
                }
            }
        }
        
        $batchingDuration = ((Get-Date) - $batchingStartTime).TotalMilliseconds
        
        $batchingSummary = @{
            Batches = $batches
            BatchingStrategy = $BatchingStrategy
            TotalJobs = $JobQueue.Count
            TotalBatches = $batches.Count
            AverageJobsPerBatch = if ($batches.Count -gt 0) { [math]::Round($JobQueue.Count / $batches.Count, 2) } else { 0 }
            JobAnalysis = $jobAnalysis
            BatchingDuration = $batchingDuration
        }
        
        Write-IntegratedWorkflowLog -Message "Intelligent job batching completed: $($batches.Count) batches created for $($JobQueue.Count) jobs in ${batchingDuration}ms" -Level "INFO"
        Write-IntegratedWorkflowLog -Message "Batching efficiency: $($batchingSummary.AverageJobsPerBatch) jobs per batch (max: $MaxBatchSize)" -Level "DEBUG"
        
        return $batchingSummary
        
    } catch {
        Write-IntegratedWorkflowLog -Message "Failed to create intelligent job batching: $($_.Exception.Message)" -Level "ERROR"
        throw
    }
}

<#
.SYNOPSIS
Monitors and analyzes performance across all workflow stages
.DESCRIPTION
Collects detailed performance metrics and provides optimization recommendations
.PARAMETER IntegratedWorkflow
The integrated workflow to monitor
.PARAMETER MonitoringDuration
Duration in seconds to collect performance data
.PARAMETER IncludeSystemMetrics
Include system-level CPU, memory, and I/O metrics
.EXAMPLE
$performance = Get-WorkflowPerformanceAnalysis -IntegratedWorkflow $workflow -MonitoringDuration 300 -IncludeSystemMetrics
#>
function Get-WorkflowPerformanceAnalysis {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [hashtable]$IntegratedWorkflow,
        [int]$MonitoringDuration = 60,
        [switch]$IncludeSystemMetrics
    )
    
    $workflowName = $IntegratedWorkflow.WorkflowName
    Write-IntegratedWorkflowLog -Message "Starting performance analysis for workflow '$workflowName' ($MonitoringDuration seconds)..." -Level "INFO"
    
    try {
        $analysisStartTime = Get-Date
        $performanceData = @{
            AnalysisStartTime = $analysisStartTime
            WorkflowName = $workflowName
            MonitoringDuration = $MonitoringDuration
            
            # Stage-specific metrics
            StageMetrics = @{
                UnityMonitoring = @{
                    AverageProcessingTime = 0
                    TotalOperations = 0
                    ErrorRate = 0
                    ThroughputPerMinute = 0
                }
                ClaudeSubmission = @{
                    AverageResponseTime = 0
                    TotalSubmissions = 0
                    SuccessRate = 0
                    ConcurrentUtilization = 0
                }
                ResponseProcessing = @{
                    AverageParsingTime = 0
                    TotalResponses = 0
                    ClassificationAccuracy = 0
                    ProcessingEfficiency = 0
                }
                OverallWorkflow = @{
                    EndToEndLatency = 0
                    TotalWorkflowsCompleted = 0
                    WorkflowSuccessRate = 0
                    ResourceUtilizationEfficiency = 0
                }
            }
            
            # System metrics (if enabled)
            SystemMetrics = @{
                Enabled = $IncludeSystemMetrics
                CPUMetrics = @{}
                MemoryMetrics = @{}
                IOMetrics = @{}
            }
            
            # Performance trends
            PerformanceTrends = @{
                ThroughputTrend = @()
                LatencyTrend = @()
                ResourceUsageTrend = @()
                ErrorRateTrend = @()
            }
            
            # Optimization recommendations
            OptimizationRecommendations = @()
        }
        
        Write-IntegratedWorkflowLog -Message "Collecting performance data..." -Level "DEBUG"
        
        # Collect current workflow metrics
        if ($IntegratedWorkflow.WorkflowState.ContainsKey('WorkflowMetrics')) {
            $workflowMetrics = $IntegratedWorkflow.WorkflowState.WorkflowMetrics
            
            # Unity monitoring metrics
            if ($workflowMetrics.UnityErrorsProcessed -gt 0) {
                $performanceData.StageMetrics.UnityMonitoring.TotalOperations = $workflowMetrics.UnityErrorsProcessed
                $performanceData.StageMetrics.UnityMonitoring.ThroughputPerMinute = $workflowMetrics.UnityErrorsProcessed / ([math]::Max(1, ((Get-Date) - $IntegratedWorkflow.Created).TotalMinutes))
            }
            
            # Claude submission metrics
            if ($workflowMetrics.ClaudeResponsesReceived -gt 0) {
                $performanceData.StageMetrics.ClaudeSubmission.TotalSubmissions = $workflowMetrics.ClaudeResponsesReceived
                $performanceData.StageMetrics.ClaudeSubmission.SuccessRate = $workflowMetrics.ClaudeResponsesReceived / [math]::Max(1, $workflowMetrics.UnityErrorsProcessed) * 100
                
                # Calculate average response time if available
                if ($IntegratedWorkflow.ClaudeSubmitter -and $IntegratedWorkflow.ClaudeSubmitter.Statistics.AverageResponseTime -gt 0) {
                    $performanceData.StageMetrics.ClaudeSubmission.AverageResponseTime = $IntegratedWorkflow.ClaudeSubmitter.Statistics.AverageResponseTime
                }
            }
            
            # Overall workflow metrics
            if ($workflowMetrics.FixesApplied -gt 0) {
                $performanceData.StageMetrics.OverallWorkflow.TotalWorkflowsCompleted = $workflowMetrics.FixesApplied
                $performanceData.StageMetrics.OverallWorkflow.WorkflowSuccessRate = $workflowMetrics.FixesApplied / [math]::Max(1, $workflowMetrics.UnityErrorsProcessed) * 100
            }
        }
        
        # Collect stage performance data from workflow state
        if ($IntegratedWorkflow.WorkflowState.ContainsKey('StagePerformance')) {
            $stagePerformance = $IntegratedWorkflow.WorkflowState.StagePerformance
            
            if ($stagePerformance.Count -gt 0) {
                $allCycleDurations = @()
                $totalUnityErrors = 0
                $totalClaudePrompts = 0
                $totalClaudeResponses = 0
                
                foreach ($cycleKey in $stagePerformance.Keys) {
                    $cycle = $stagePerformance[$cycleKey]
                    
                    if ($cycle.ContainsKey('Duration')) {
                        $allCycleDurations += $cycle.Duration
                    }
                    
                    if ($cycle.ContainsKey('UnityErrors')) {
                        $totalUnityErrors += $cycle.UnityErrors
                    }
                    
                    if ($cycle.ContainsKey('ClaudePrompts')) {
                        $totalClaudePrompts += $cycle.ClaudePrompts
                    }
                    
                    if ($cycle.ContainsKey('ClaudeResponses')) {
                        $totalClaudeResponses += $cycle.ClaudeResponses
                    }
                }
                
                if ($allCycleDurations.Count -gt 0) {
                    $performanceData.StageMetrics.OverallWorkflow.EndToEndLatency = ($allCycleDurations | Measure-Object -Average).Average
                }
                
                # Calculate processing rates
                $totalCycles = $allCycleDurations.Count
                if ($totalCycles -gt 0) {
                    $performanceData.StageMetrics.UnityMonitoring.AverageProcessingTime = [math]::Round($totalUnityErrors / $totalCycles, 2)
                    $performanceData.StageMetrics.ClaudeSubmission.ConcurrentUtilization = [math]::Round($totalClaudePrompts / $totalCycles, 2)
                    $performanceData.StageMetrics.ResponseProcessing.ProcessingEfficiency = if ($totalClaudePrompts -gt 0) { [math]::Round($totalClaudeResponses / $totalClaudePrompts * 100, 2) } else { 0 }
                }
            }
        }
        
        # Collect system metrics if enabled
        if ($IncludeSystemMetrics) {
            Write-IntegratedWorkflowLog -Message "Collecting system performance metrics..." -Level "DEBUG"
            
            try {
                # CPU metrics
                if (Get-Command Get-Counter -ErrorAction SilentlyContinue) {
                    $cpuSample = Get-Counter '\Processor(_Total)\% Processor Time' -SampleInterval 2 -MaxSamples 3 -ErrorAction SilentlyContinue
                    if ($cpuSample) {
                        $performanceData.SystemMetrics.CPUMetrics = @{
                            AverageCPUUsage = [math]::Round(($cpuSample.CounterSamples | Measure-Object CookedValue -Average).Average, 2)
                            MaxCPUUsage = [math]::Round(($cpuSample.CounterSamples | Measure-Object CookedValue -Maximum).Maximum, 2)
                            CPUSamples = $cpuSample.CounterSamples.Count
                        }
                    }
                    
                    # Memory metrics
                    $memorySample = Get-Counter '\Memory\Available MBytes' -SampleInterval 2 -MaxSamples 3 -ErrorAction SilentlyContinue
                    if ($memorySample) {
                        $totalMemoryMB = [math]::Round((Get-CimInstance Win32_ComputerSystem -ErrorAction SilentlyContinue).TotalPhysicalMemory / 1MB, 0)
                        $avgAvailableMB = ($memorySample.CounterSamples | Measure-Object CookedValue -Average).Average
                        
                        $performanceData.SystemMetrics.MemoryMetrics = @{
                            TotalMemoryMB = $totalMemoryMB
                            AverageAvailableMB = [math]::Round($avgAvailableMB, 2)
                            AverageMemoryUsagePercent = if ($totalMemoryMB -gt 0) { [math]::Round((($totalMemoryMB - $avgAvailableMB) / $totalMemoryMB) * 100, 2) } else { 0 }
                            MemorySamples = $memorySample.CounterSamples.Count
                        }
                    }
                }
            } catch {
                Write-IntegratedWorkflowLog -Message "Failed to collect system metrics: $($_.Exception.Message)" -Level "WARNING"
            }
        }
        
        # Generate optimization recommendations based on analysis
        $recommendations = @()
        
        # CPU-based recommendations
        if ($performanceData.SystemMetrics.CPUMetrics.ContainsKey('AverageCPUUsage')) {
            if ($performanceData.SystemMetrics.CPUMetrics.AverageCPUUsage -gt 80) {
                $recommendations += "High CPU usage detected ($($performanceData.SystemMetrics.CPUMetrics.AverageCPUUsage)%) - consider reducing concurrent operations"
            } elseif ($performanceData.SystemMetrics.CPUMetrics.AverageCPUUsage -lt 30) {
                $recommendations += "Low CPU utilization ($($performanceData.SystemMetrics.CPUMetrics.AverageCPUUsage)%) - consider increasing concurrent operations for better throughput"
            }
        }
        
        # Memory-based recommendations
        if ($performanceData.SystemMetrics.MemoryMetrics.ContainsKey('AverageMemoryUsagePercent')) {
            if ($performanceData.SystemMetrics.MemoryMetrics.AverageMemoryUsagePercent -gt 85) {
                $recommendations += "High memory usage detected ($($performanceData.SystemMetrics.MemoryMetrics.AverageMemoryUsagePercent)%) - consider memory optimization"
            }
        }
        
        # Workflow efficiency recommendations
        if ($performanceData.StageMetrics.ClaudeSubmission.SuccessRate -gt 0 -and $performanceData.StageMetrics.ClaudeSubmission.SuccessRate -lt 95) {
            $recommendations += "Claude submission success rate is $($performanceData.StageMetrics.ClaudeSubmission.SuccessRate)% - investigate error patterns"
        }
        
        if ($performanceData.StageMetrics.ResponseProcessing.ProcessingEfficiency -gt 0 -and $performanceData.StageMetrics.ResponseProcessing.ProcessingEfficiency -lt 90) {
            $recommendations += "Response processing efficiency is $($performanceData.StageMetrics.ResponseProcessing.ProcessingEfficiency)% - optimize response parsing"
        }
        
        if ($performanceData.StageMetrics.OverallWorkflow.EndToEndLatency -gt 10000) { # > 10 seconds
            $recommendations += "High end-to-end latency ($($performanceData.StageMetrics.OverallWorkflow.EndToEndLatency)ms) - investigate bottlenecks"
        }
        
        # Throughput recommendations
        if ($performanceData.StageMetrics.UnityMonitoring.ThroughputPerMinute -gt 0 -and $performanceData.StageMetrics.UnityMonitoring.ThroughputPerMinute -lt 1) {
            $recommendations += "Low Unity error processing throughput ($($performanceData.StageMetrics.UnityMonitoring.ThroughputPerMinute) errors/min) - optimize Unity monitoring"
        }
        
        $performanceData.OptimizationRecommendations = $recommendations
        
        $analysisEndTime = Get-Date
        $performanceData.AnalysisEndTime = $analysisEndTime
        $performanceData.AnalysisDuration = ($analysisEndTime - $analysisStartTime).TotalMilliseconds
        
        Write-IntegratedWorkflowLog -Message "Performance analysis completed for workflow '$workflowName' in $($performanceData.AnalysisDuration)ms" -Level "INFO"
        Write-IntegratedWorkflowLog -Message "Generated $($recommendations.Count) optimization recommendations" -Level "DEBUG"
        
        return $performanceData
        
    } catch {
        Write-IntegratedWorkflowLog -Message "Failed to analyze workflow performance: $($_.Exception.Message)" -Level "ERROR"
        throw
    }
}

#endregion

# Export functions
# Debug logging: Function definition validation
Write-IntegratedWorkflowLog -Message "Validating function definitions before export..." -Level "DEBUG"

$definedFunctions = @()
$functionsToExport = @(
    'New-IntegratedWorkflow',
    'Start-IntegratedWorkflow', 
    'Get-IntegratedWorkflowStatus',
    'Stop-IntegratedWorkflow',
    'Initialize-AdaptiveThrottling',
    'Update-AdaptiveThrottling',
    'New-IntelligentJobBatching',
    'Get-WorkflowPerformanceAnalysis'
)

# Validate each function exists before export
foreach ($functionName in $functionsToExport) {
    if (Test-Path "Function:\$functionName") {
        $definedFunctions += $functionName
        Write-IntegratedWorkflowLog -Message "Function validated: $functionName" -Level "DEBUG"
    } else {
        Write-IntegratedWorkflowLog -Message "Function NOT FOUND: $functionName" -Level "ERROR"
    }
}

Write-IntegratedWorkflowLog -Message "Function validation complete: $($definedFunctions.Count)/$($functionsToExport.Count) functions defined" -Level "INFO"

# Export only validated functions
Export-ModuleMember -Function $definedFunctions

# Module loading complete with detailed status
Write-IntegratedWorkflowLog -Message "Export-ModuleMember completed for $($definedFunctions.Count) functions" -Level "DEBUG"
Write-IntegratedWorkflowLog -Message "Unity-Claude-IntegratedWorkflow module loaded successfully" -Level "INFO"

# SIG # Begin signature block
# MIIFqQYJKoZIhvcNAQcCoIIFmjCCBZYCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUXghzd79r5q5aojgpqC+NEjae
# 3+SgggMwMIIDLDCCAhSgAwIBAgIQdR0W2SKoK5VE8JId4ZxrRTANBgkqhkiG9w0B
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
# CQQxFgQUWJ0eruibZsK9boaep0j+HZYmeQcwDQYJKoZIhvcNAQEBBQAEggEAJwG+
# RrnzOzcFIpskxNJxTiDITr62diBQ8c3uWime+IA6XKo4h647mD+sAO+mmfGzFaxj
# azNAr1lfw3ykdYPUvv/FhGQMZ/eXfkRRePZ8Zj9v/VAGyT4aZyJAttbNIE4S0v/F
# pniadxUw6Ry+ZH09DQHpZhYBhMTiKmHtKaF+4iEaTazzN7U5BDjyhH2xoxkVs4Xn
# mMZNr+esi1wunpVQ9TeRMpj8hgMvvA//934tUV+Gf7nTG0FSiRX1TheYG3kUk2s0
# dHyDa7Rgcojuhk1yd4rxOJpzcfXz2qt4ztPwnQWckdTW4SM99zUkJfkoBeSkpZJJ
# h4hgDQZqBrfBt2ox4A==
# SIG # End signature block
