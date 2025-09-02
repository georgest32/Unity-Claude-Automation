# Unity-Claude-IntegratedWorkflow Monitoring Component  
# Workflow status and monitoring functions
# Part of refactored IntegratedWorkflow module

$ErrorActionPreference = "Stop"

# Import core component
$CorePath = Join-Path $PSScriptRoot "WorkflowCore.psm1"
Import-Module $CorePath -Force

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
        $workflowState = Get-IntegratedWorkflowState
        if ($workflowState.ActiveWorkflows.ContainsKey($workflowName)) {
            $workflowState.ActiveWorkflows.Remove($workflowName)
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

# Export functions
Export-ModuleMember -Function @(
    'Get-IntegratedWorkflowStatus',
    'Stop-IntegratedWorkflow'
)

Write-IntegratedWorkflowLog -Message "WorkflowMonitoring component loaded successfully" -Level "DEBUG"
# SIG # Begin signature block
# MIIFzgYJKoZIhvcNAQcCoIIFvzCCBbsCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCCU0XOoR1Dx0DFg
# a8k2hxUz/YcS/e+pmnwSsJrBcAPcWqCCAzAwggMsMIICFKADAgECAhB1HRbZIqgr
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
# MAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEID1w6rx91P+Nmt9k909MCp0v
# AvjCEejAoxP3lEFHcQj9MA0GCSqGSIb3DQEBAQUABIIBAI6ps+rGq/93oJzKEBl9
# fv60zkPbMv1C+/+wcdXIrsaT97+TiqSW2uvdfjsKXnINaUNF0/8ALxPVFcbYeDY3
# bWw7ge6j6FL5DUrwK8lCrhRxfZ6wXf9u1A5uBA1QEFbf47Cf6C8LdBdOzCuw/auN
# BbbmSghBNkxZOiNQ9InvrKEoWGKqj9VZ8hElfm81V1Aum1zR28fr7FRJXRz0glCI
# bbLZoVs8Sdvjg4TnKOle1a/L3G0vPB6QcBUb7tE9jxwNzE7fKio9yuSxdU4bffmp
# sBmLGvFsrwz3HCwylrzHlh6mWCSBGOMkG2H7VgM1L5ZpA9wnpdfmQcx+eaFNgAJT
# qNo=
# SIG # End signature block
