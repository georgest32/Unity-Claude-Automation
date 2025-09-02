# HealthMonitoring.psm1
# Performance and health monitoring for autonomous state tracking
# Refactored component from Unity-Claude-AutonomousStateTracker-Enhanced.psm1
# Component: Performance and health monitoring (115 lines)

#region Performance and Health Monitoring

function Start-EnhancedHealthMonitoring {
    <#
    .SYNOPSIS
    Start enhanced health monitoring with performance counters and thresholds
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$AgentId
    )
    
    try {
        Write-EnhancedStateLog -Message "Starting enhanced health monitoring for agent: $AgentId" -Level "INFO"
        
        # Get configurations
        $stateConfig = Get-EnhancedStateConfig
        $performanceCounters = Get-PerformanceCounters
        $autonomousStates = Get-EnhancedAutonomousStates
        
        # Create monitoring job
        $monitoringScript = {
            param($AgentId, $StateConfig, $PerformanceCounters, $EnhancedAutonomousStates)
            
            # Import module functions in job context
            $modulePath = Split-Path $PSScriptRoot -Parent
            Import-Module (Join-Path $modulePath "Unity-Claude-AutonomousStateTracker-Enhanced.psm1") -Force
            
            while ($true) {
                try {
                    # Get current agent state
                    $agentState = Get-AgentState -AgentId $AgentId
                    if (-not $agentState) {
                        Start-Sleep -Seconds $StateConfig.HealthCheckIntervalSeconds
                        continue
                    }
                    
                    # Skip monitoring if not required
                    $stateDefinition = $EnhancedAutonomousStates[$agentState.CurrentState]
                    if (-not $stateDefinition.RequiresMonitoring) {
                        Start-Sleep -Seconds $StateConfig.HealthCheckIntervalSeconds
                        continue
                    }
                    
                    # Collect performance metrics
                    $performanceMetrics = Get-SystemPerformanceMetrics
                    
                    # Test health thresholds
                    $healthAssessment = Test-SystemHealthThresholds -PerformanceMetrics $performanceMetrics
                    
                    # Update agent state with health data
                    $agentState.HealthMetrics = $performanceMetrics
                    $agentState.LastHealthCheck = Get-Date
                    
                    # Handle health issues
                    if ($healthAssessment.RequiresIntervention) {
                        $reasons = $healthAssessment.CriticalIssues -join "; "
                        Request-HumanIntervention -AgentId $AgentId -Reason "Critical system health issues: $reasons" -Priority "Critical"
                        
                        # Transition to error state
                        Set-EnhancedAutonomousState -AgentId $AgentId -NewState "Error" -Reason "Critical health threshold exceeded"
                    } elseif ($healthAssessment.RequiresAttention) {
                        $reasons = $healthAssessment.HealthIssues -join "; "
                        Write-EnhancedStateLog -Message "Health warning: $reasons" -Level "WARNING" -Component "HealthMonitor"
                    }
                    
                    # Save updated state
                    Save-AgentState -AgentState $agentState
                    
                    # Log performance data
                    Write-EnhancedStateLog -Message "Health check completed" -Level "PERFORMANCE" -AdditionalData $performanceMetrics
                    
                } catch {
                    Write-EnhancedStateLog -Message "Health monitoring error: $($_.Exception.Message)" -Level "ERROR" -Component "HealthMonitor"
                }
                
                Start-Sleep -Seconds $StateConfig.HealthCheckIntervalSeconds
            }
        }
        
        # Start monitoring job
        $job = Start-Job -ScriptBlock $monitoringScript -ArgumentList $AgentId, $stateConfig, $performanceCounters, $autonomousStates
        
        Write-EnhancedStateLog -Message "Enhanced health monitoring started (Job ID: $($job.Id))" -Level "INFO"
        
        return $job
        
    } catch {
        Write-EnhancedStateLog -Message "Failed to start health monitoring: $($_.Exception.Message)" -Level "ERROR"
        throw
    }
}

function Stop-EnhancedHealthMonitoring {
    <#
    .SYNOPSIS
    Stop enhanced health monitoring jobs
    #>
    [CmdletBinding()]
    param(
        [string]$AgentId
    )
    
    try {
        # Find and stop monitoring jobs
        $jobs = Get-Job | Where-Object { $_.Command -like "*HealthMonitoring*" }
        
        foreach ($job in $jobs) {
            Stop-Job $job -ErrorAction SilentlyContinue
            Remove-Job $job -Force -ErrorAction SilentlyContinue
        }
        
        Write-EnhancedStateLog -Message "Enhanced health monitoring stopped" -Level "INFO"
        
    } catch {
        Write-EnhancedStateLog -Message "Failed to stop health monitoring: $($_.Exception.Message)" -Level "ERROR"
    }
}

function Get-HealthMonitoringStatus {
    <#
    .SYNOPSIS
    Get status of health monitoring jobs
    #>
    [CmdletBinding()]
    param()
    
    try {
        $jobs = Get-Job | Where-Object { $_.Command -like "*HealthMonitoring*" }
        
        $status = @()
        foreach ($job in $jobs) {
            $status += @{
                JobId = $job.Id
                State = $job.State
                HasMoreData = $job.HasMoreData
                StartTime = $job.PSBeginTime
                Command = $job.Command
            }
        }
        
        return $status
        
    } catch {
        Write-EnhancedStateLog -Message "Failed to get health monitoring status: $($_.Exception.Message)" -Level "ERROR"
        return @()
    }
}

function Test-AgentHealth {
    <#
    .SYNOPSIS
    Perform immediate health check on an agent
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$AgentId
    )
    
    try {
        # Get agent state
        $agentState = Get-AgentState -AgentId $AgentId
        if (-not $agentState) {
            return @{
                AgentId = $AgentId
                HealthStatus = "Unknown"
                Reason = "Agent state not found"
            }
        }
        
        # Get current performance metrics
        $performanceMetrics = Get-SystemPerformanceMetrics
        
        # Test health thresholds
        $healthAssessment = Test-SystemHealthThresholds -PerformanceMetrics $performanceMetrics
        
        # Determine overall health status
        $healthStatus = if ($healthAssessment.RequiresIntervention) {
            "Critical"
        } elseif ($healthAssessment.RequiresAttention) {
            "Warning"
        } else {
            "Healthy"
        }
        
        return @{
            AgentId = $AgentId
            HealthStatus = $healthStatus
            CurrentState = $agentState.CurrentState
            LastHealthCheck = $agentState.LastHealthCheck
            PerformanceMetrics = $performanceMetrics
            HealthIssues = $healthAssessment.HealthIssues
            CriticalIssues = $healthAssessment.CriticalIssues
            UptimeMinutes = [math]::Round((Get-UptimeMinutes -StartTime $agentState.StartTime), 2)
        }
        
    } catch {
        Write-EnhancedStateLog -Message "Failed to test agent health: $($_.Exception.Message)" -Level "ERROR"
        return @{
            AgentId = $AgentId
            HealthStatus = "Error"
            Reason = $_.Exception.Message
        }
    }
}

# Export functions
Export-ModuleMember -Function @(
    'Start-EnhancedHealthMonitoring',
    'Stop-EnhancedHealthMonitoring',
    'Get-HealthMonitoringStatus',
    'Test-AgentHealth'
)

#endregion
# SIG # Begin signature block
# MIIFzgYJKoZIhvcNAQcCoIIFvzCCBbsCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCDFkQpo5sVUzzD/
# diLL1r8nBZjp8xiYQh5bcSAL0i6VX6CCAzAwggMsMIICFKADAgECAhB1HRbZIqgr
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
# MAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEINqFnkaqQ5OSHkYdjMpn4/HT
# 2F9u4cLe6NSti+4sxULjMA0GCSqGSIb3DQEBAQUABIIBABbKKUQp51nmukgrwuRn
# +sApmeVZ3r1eajxGvYc+bdGMTjp1YcX70QvdICsUe6ceKZngGgRYzek7ENOjuLno
# zUw3ptXPtaPZ6gtQmOrdLniG9DsK3NNMxZqnDJSFXOdaH9JSz+06lVjbzjRhtBVm
# Tk68zEfC6O2IvV8h4rcnaCv6sPOxKDBKr/fft1ZqUzTI/ZVxJ5pz4dr/vZAvqt/B
# w/fT4UBksx+jEusKvMr+QX8bGPjmAveNhVp4h48l+EjQC3HhMwrFv+DbXA9o12Ap
# CM0Rv0Ibn3Qsb+tuKF21cWHupw7oAgUx2oxTbwq0sCqfRfKA7Eee55bmCS+GjsDe
# eJ0=
# SIG # End signature block
