# Unity-Claude-IntegratedWorkflow Performance Analysis Component
# Performance monitoring and analysis functions
# Part of refactored IntegratedWorkflow module

$ErrorActionPreference = "Stop"

# Import core component
$CorePath = Join-Path $PSScriptRoot "WorkflowCore.psm1"
Import-Module $CorePath -Force

<#
.SYNOPSIS
Monitors and analyzes performance across all workflow stages
.DESCRIPTION
Collects detailed performance metrics and provides optimization recommendations
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
        $recommendations = Get-OptimizationRecommendations -PerformanceData $performanceData
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

# Helper function to generate optimization recommendations
function Get-OptimizationRecommendations {
    param(
        [hashtable]$PerformanceData
    )
    
    $recommendations = @()
    
    # CPU-based recommendations
    if ($PerformanceData.SystemMetrics.CPUMetrics.ContainsKey('AverageCPUUsage')) {
        if ($PerformanceData.SystemMetrics.CPUMetrics.AverageCPUUsage -gt 80) {
            $recommendations += "High CPU usage detected ($($PerformanceData.SystemMetrics.CPUMetrics.AverageCPUUsage)%) - consider reducing concurrent operations"
        } elseif ($PerformanceData.SystemMetrics.CPUMetrics.AverageCPUUsage -lt 30) {
            $recommendations += "Low CPU utilization ($($PerformanceData.SystemMetrics.CPUMetrics.AverageCPUUsage)%) - consider increasing concurrent operations for better throughput"
        }
    }
    
    # Memory-based recommendations
    if ($PerformanceData.SystemMetrics.MemoryMetrics.ContainsKey('AverageMemoryUsagePercent')) {
        if ($PerformanceData.SystemMetrics.MemoryMetrics.AverageMemoryUsagePercent -gt 85) {
            $recommendations += "High memory usage detected ($($PerformanceData.SystemMetrics.MemoryMetrics.AverageMemoryUsagePercent)%) - consider memory optimization"
        }
    }
    
    # Workflow efficiency recommendations
    if ($PerformanceData.StageMetrics.ClaudeSubmission.SuccessRate -gt 0 -and $PerformanceData.StageMetrics.ClaudeSubmission.SuccessRate -lt 95) {
        $recommendations += "Claude submission success rate is $($PerformanceData.StageMetrics.ClaudeSubmission.SuccessRate)% - investigate error patterns"
    }
    
    if ($PerformanceData.StageMetrics.ResponseProcessing.ProcessingEfficiency -gt 0 -and $PerformanceData.StageMetrics.ResponseProcessing.ProcessingEfficiency -lt 90) {
        $recommendations += "Response processing efficiency is $($PerformanceData.StageMetrics.ResponseProcessing.ProcessingEfficiency)% - optimize response parsing"
    }
    
    if ($PerformanceData.StageMetrics.OverallWorkflow.EndToEndLatency -gt 10000) { # > 10 seconds
        $recommendations += "High end-to-end latency ($($PerformanceData.StageMetrics.OverallWorkflow.EndToEndLatency)ms) - investigate bottlenecks"
    }
    
    # Throughput recommendations
    if ($PerformanceData.StageMetrics.UnityMonitoring.ThroughputPerMinute -gt 0 -and $PerformanceData.StageMetrics.UnityMonitoring.ThroughputPerMinute -lt 1) {
        $recommendations += "Low Unity error processing throughput ($($PerformanceData.StageMetrics.UnityMonitoring.ThroughputPerMinute) errors/min) - optimize Unity monitoring"
    }
    
    return $recommendations
}

# Export functions
Export-ModuleMember -Function @(
    'Get-WorkflowPerformanceAnalysis',
    'Get-OptimizationRecommendations'
)

Write-IntegratedWorkflowLog -Message "PerformanceAnalysis component loaded successfully" -Level "DEBUG"
# SIG # Begin signature block
# MIIFzgYJKoZIhvcNAQcCoIIFvzCCBbsCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCC1YvCimOxXyl2N
# eblVkpB3Dvonc/A5/mVBU1cJsVHwg6CCAzAwggMsMIICFKADAgECAhB1HRbZIqgr
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
# MAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIKi2Q0j0m7OWgV/WWhM6AsS7
# VDMToAtmZVS8agSNl2hOMA0GCSqGSIb3DQEBAQUABIIBAFElsRxqTc146onZOxlC
# MlHa6GDxX7U8lMod8iLOJ9YI5iR/W5GqbOnhRu71mcMJAQykw/tlygaj/z645yjR
# Q7lPhuxxi901J3f5psM3gixIvxY4ARFdl6GoKY/WkjySqvMQxbN2kZWZTRYkds99
# dZZfEymiHvafQRlReA+NL9/LC2ERgxcMj9unxPYaY/QbhuLo9FxmsTFWzM/76nKO
# SC9bULg0iLHzSVpzLPDX3SDOU94/KwcP5GmhjBZasCiFv4nqQhIKMKNkICMcttlA
# 7Ytqu1+nyrxAMmisYnAHk3hqevLKcPo1dJzYYo+1LFuI2NvFyJ+hXrs+xKBvpXDY
# F4g=
# SIG # End signature block
