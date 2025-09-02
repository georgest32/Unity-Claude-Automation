# Unity-Claude-IntegratedWorkflow Orchestration Component
# Main workflow management functions (New-IntegratedWorkflow, Start-IntegratedWorkflow)
# Part of refactored IntegratedWorkflow module

$ErrorActionPreference = "Stop"

# Import required components
$CorePath = Join-Path $PSScriptRoot "WorkflowCore.psm1"
$DepsPath = Join-Path $PSScriptRoot "DependencyManagement.psm1"
Import-Module $CorePath -Force
Import-Module $DepsPath -Force

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
        $moduleAvailability = Get-ModuleAvailability
        
        @('RunspaceManagement', 'UnityParallelization', 'ClaudeParallelization') | ForEach-Object {
            $module = $_
            $moduleAvailable = $false
            
            if ($moduleAvailability.ContainsKey($module) -and $moduleAvailability[$module]) {
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
        $workflowState = Get-IntegratedWorkflowState
        $workflowState.ActiveWorkflows[$WorkflowName] = $integratedWorkflow
        
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
        
        # Create and start the main orchestration job
        $orchestrationScript = Get-WorkflowOrchestrationScript
        
        # Create orchestration job in runspace pool
        Write-IntegratedWorkflowLog -Message "Starting workflow orchestration job..." -Level "DEBUG"
        $orchestrationPowerShell = [powershell]::Create()
        $orchestrationPowerShell.RunspacePool = $IntegratedWorkflow.OrchestrationPool.Pool
        
        $orchestrationPowerShell.AddScript($orchestrationScript) | Out-Null
        $orchestrationPowerShell.AddArgument([ref]$IntegratedWorkflow.WorkflowState) | Out-Null
        $orchestrationPowerShell.AddArgument($IntegratedWorkflow) | Out-Null
        $orchestrationPowerShell.AddArgument($MonitoringInterval) | Out-Null
        $orchestrationPowerShell.AddArgument($WorkflowMode) | Out-Null
        $orchestrationPowerShell.AddArgument($workflowName) | Out-Null
        
        $orchestrationResult = $orchestrationPowerShell.BeginInvoke()
        
        # Store orchestration job for management
        $IntegratedWorkflow.OrchestrationJob = @{
            PowerShell = $orchestrationPowerShell
            AsyncResult = $orchestrationResult
            StartTime = Get-Date
        }
        
        # Update workflow status
        $IntegratedWorkflow.Status = 'Running'
        $IntegratedWorkflow.Statistics.WorkflowsStarted++
        
        Write-IntegratedWorkflowLog -Message "Integrated workflow '$workflowName' started successfully in $WorkflowMode mode" -Level "INFO"
        
        return @{
            Success = $true
            Message = "Workflow started successfully"
            WorkflowName = $workflowName
            Mode = $WorkflowMode
            UnityProjects = $validUnityProjects.Count
            MonitoringInterval = $MonitoringInterval
        }
        
    } catch {
        Write-IntegratedWorkflowLog -Message "Failed to start integrated workflow '$workflowName': $($_.Exception.Message)" -Level "ERROR"
        throw
    }
}

# Helper function to get the orchestration script
function Get-WorkflowOrchestrationScript {
    return {
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
                
                # Exit conditions based on workflow mode
                if ($WorkflowMode -eq 'OnDemand' -and $workflowCycle -ge 1) {
                    Write-Host "[$($WorkflowName)] OnDemand workflow completed" -ForegroundColor Green
                    break
                }
                
                if ($WorkflowMode -eq 'Batch' -and $WorkflowState.Value.UnityErrorQueue.Count -eq 0 -and $workflowCycle -gt 1) {
                    Write-Host "[$($WorkflowName)] Batch workflow completed - no more errors to process" -ForegroundColor Green
                    break
                }
                
                # Sleep before next cycle
                Start-Sleep -Seconds 5
            }
            
            $orchestrationEndTime = Get-Date
            $orchestrationDuration = ($orchestrationEndTime - $orchestrationStartTime).TotalMilliseconds
            
            Write-Host "[$($WorkflowName)] Workflow orchestration completed after $workflowCycle cycles (Duration: ${orchestrationDuration}ms)" -ForegroundColor Green
            
            return @{
                Success = $true
                Cycles = $workflowCycle
                Duration = $orchestrationDuration
                ProcessedErrors = $WorkflowState.Value.WorkflowMetrics.UnityErrorsProcessed
            }
            
        } catch {
            Write-Host "[$($WorkflowName)] Workflow orchestration error: $($_.Exception.Message)" -ForegroundColor Red
            throw
        }
    }
}

# Export functions
Export-ModuleMember -Function @(
    'New-IntegratedWorkflow',
    'Start-IntegratedWorkflow',
    'Get-WorkflowOrchestrationScript'
)

Write-IntegratedWorkflowLog -Message "WorkflowOrchestration component loaded successfully" -Level "DEBUG"
# SIG # Begin signature block
# MIIFzgYJKoZIhvcNAQcCoIIFvzCCBbsCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCCERZccb8jcGhtD
# mtewz/zFRPJdq6OZftXec6jy+TwRyaCCAzAwggMsMIICFKADAgECAhB1HRbZIqgr
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
# MAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIOvdNbItJHiQfH6lWLb9OnWM
# SzL0xWFlAXkKeA9ct6XsMA0GCSqGSIb3DQEBAQUABIIBAGEityBttOy5bNzsEiQ3
# OrVYq4BB+lbpYSRD3BT5eX/cdAdWtjMpnZFBHdDXzj8ykAgdn8B8oQ5gxCKqBKeM
# L/kUpDT1ZEerzf8SQTpnA2x1S/tkI/AzfxmbWphMR2hm5eEqeqC/CUSGGHD4Cbwg
# b2tGQU2PDYsFajFfAhR0KCPldiJf/FheYs1eW9N/P7o3GLYRIRPMaYVrNtHKF/xb
# zTNkGVnxqo0Jn9PHMvs6mqsdiuafR3YAloqHyeZ3QBzpN1Wmg0O6uYISSjuR05rk
# eQ7QCXg57K32VBQws8HECVmIS+VviAgsxDHJBOYpsoixwL7zv5wkZbt73Ol5dvxs
# vzU=
# SIG # End signature block
