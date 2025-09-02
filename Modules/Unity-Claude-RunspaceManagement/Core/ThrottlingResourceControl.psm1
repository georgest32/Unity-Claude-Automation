# Unity-Claude-RunspaceManagement Throttling and Resource Control Component
# Resource monitoring and adaptive throttling for runspace pools
# Part of refactored RunspaceManagement module

$ErrorActionPreference = "Stop"

# Load core components with circular dependency resolution
$CorePath = Join-Path $PSScriptRoot "RunspaceCore.psm1"
$ProductionPoolPath = Join-Path $PSScriptRoot "ProductionRunspacePool.psm1"

# Check for and load required functions with fallback
try {
    if (-not (Get-Command Write-ModuleLog -ErrorAction SilentlyContinue)) {
        . $CorePath
    }
    # ProductionRunspacePool not needed here - avoid circular reference
} catch {
    Write-Host "[ThrottlingResourceControl] Warning: Could not load RunspaceCore, using fallback logging" -ForegroundColor Yellow
    function Write-ModuleLog {
        param([string]$Message, [string]$Level = "INFO")
        $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        Write-Host "[$timestamp] [ThrottlingResourceControl] [$Level] $Message"
    }
}

function Test-RunspacePoolResources {
    <#
    .SYNOPSIS
    Monitors resource usage for runspace pool operations
    .DESCRIPTION
    Uses Get-Counter to monitor CPU and memory usage during runspace pool operations
    .PARAMETER PoolManager
    Pool manager object with resource monitoring configuration
    .EXAMPLE
    Test-RunspacePoolResources -PoolManager $pool
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [hashtable]$PoolManager
    )
    
    if (-not $PoolManager.ResourceMonitoring.Enabled) {
        return @{Enabled = $false}
    }
    
    $poolName = $PoolManager.Name
    
    try {
        $resourceInfo = @{
            Enabled = $true
            Timestamp = Get-Date
            CpuPercent = 0
            MemoryUsedMB = 0
            AvailableMemoryMB = 0
            ThresholdExceeded = $false
            Warnings = @()
        }
        
        # Get CPU usage (research-validated Get-Counter pattern)
        try {
            $cpuCounter = Get-Counter -Counter "\Processor(_Total)\% Processor Time" -SampleInterval 1 -MaxSamples 1 -ErrorAction SilentlyContinue
            $resourceInfo.CpuPercent = [math]::Round($cpuCounter.CounterSamples[0].CookedValue, 2)
            $PoolManager.ResourceMonitoring.LastCpuCheck = Get-Date
            
            # Update peak CPU usage
            if ($resourceInfo.CpuPercent -gt $PoolManager.Statistics.PeakCpuPercent) {
                $PoolManager.Statistics.PeakCpuPercent = $resourceInfo.CpuPercent
            }
            
            # Check CPU threshold
            if ($resourceInfo.CpuPercent -gt $PoolManager.ResourceMonitoring.CpuThreshold) {
                $resourceInfo.ThresholdExceeded = $true
                $resourceInfo.Warnings += "CPU usage ($($resourceInfo.CpuPercent)%) exceeds threshold ($($PoolManager.ResourceMonitoring.CpuThreshold)%)"
            }
            
        } catch {
            Write-ModuleLog -Message "Failed to get CPU counter: $($_.Exception.Message)" -Level "DEBUG"
        }
        
        # Get memory usage (research-validated pattern)
        try {
            $memoryCounter = Get-Counter -Counter "\Memory\Available MBytes" -SampleInterval 1 -MaxSamples 1 -ErrorAction SilentlyContinue
            $resourceInfo.AvailableMemoryMB = [math]::Round($memoryCounter.CounterSamples[0].CookedValue, 2)
            
            # Calculate used memory (approximate)
            $processCounter = Get-Counter -Counter "\Process(powershell*)\Working Set - Private" -SampleInterval 1 -MaxSamples 1 -ErrorAction SilentlyContinue
            $resourceInfo.MemoryUsedMB = [math]::Round(($processCounter.CounterSamples | Measure-Object -Property CookedValue -Sum).Sum / 1MB, 2)
            $PoolManager.ResourceMonitoring.LastMemoryCheck = Get-Date
            
            # Update peak memory usage
            if ($resourceInfo.MemoryUsedMB -gt $PoolManager.Statistics.PeakMemoryUsageMB) {
                $PoolManager.Statistics.PeakMemoryUsageMB = $resourceInfo.MemoryUsedMB
            }
            
            # Check memory threshold
            if ($resourceInfo.MemoryUsedMB -gt $PoolManager.ResourceMonitoring.MemoryThresholdMB) {
                $resourceInfo.ThresholdExceeded = $true
                $resourceInfo.Warnings += "Memory usage ($($resourceInfo.MemoryUsedMB)MB) exceeds threshold ($($PoolManager.ResourceMonitoring.MemoryThresholdMB)MB)"
            }
            
        } catch {
            Write-ModuleLog -Message "Failed to get memory counter: $($_.Exception.Message)" -Level "DEBUG"
        }
        
        # Log warnings if thresholds exceeded
        if ($resourceInfo.ThresholdExceeded) {
            foreach ($warning in $resourceInfo.Warnings) {
                Write-ModuleLog -Message "Resource threshold warning for pool '$poolName': $warning" -Level "WARNING"
            }
        }
        
        return $resourceInfo
        
    } catch {
        Write-ModuleLog -Message "Failed to monitor resources for pool '$poolName': $($_.Exception.Message)" -Level "ERROR"
        return @{Enabled = $true; Error = $_.Exception.Message}
    }
}

function Set-AdaptiveThrottling {
    <#
    .SYNOPSIS
    Implements adaptive throttling based on system performance
    .DESCRIPTION
    Adjusts runspace pool throttling based on CPU and memory usage patterns
    .PARAMETER PoolManager
    Pool manager object
    .PARAMETER CpuThreshold
    CPU threshold for throttling adjustment (default: 80%)
    .PARAMETER MemoryThresholdMB
    Memory threshold for throttling adjustment (default: 1000MB)
    .EXAMPLE
    Set-AdaptiveThrottling -PoolManager $pool -CpuThreshold 70
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [hashtable]$PoolManager,
        [int]$CpuThreshold = 80,
        [int]$MemoryThresholdMB = 1000
    )
    
    $poolName = $PoolManager.Name
    Write-ModuleLog -Message "Setting adaptive throttling for pool '$poolName'..." -Level "INFO"
    
    try {
        # Update resource monitoring configuration
        $PoolManager.ResourceMonitoring.CpuThreshold = $CpuThreshold
        $PoolManager.ResourceMonitoring.MemoryThresholdMB = $MemoryThresholdMB
        $PoolManager.ResourceMonitoring.Enabled = $true
        
        # Get current resource usage
        $resourceInfo = Test-RunspacePoolResources -PoolManager $PoolManager
        
        $adaptiveConfig = @{
            OriginalMaxRunspaces = $PoolManager.MaxRunspaces
            RecommendedMaxRunspaces = $PoolManager.MaxRunspaces
            CpuBasedAdjustment = 0
            MemoryBasedAdjustment = 0
            Reasoning = @()
        }
        
        # CPU-based throttling adjustment
        if ($resourceInfo.CpuPercent -gt $CpuThreshold) {
            $cpuAdjustment = -[math]::Ceiling($PoolManager.MaxRunspaces * 0.2) # Reduce by 20%
            $adaptiveConfig.CpuBasedAdjustment = $cpuAdjustment
            $adaptiveConfig.Reasoning += "High CPU usage ($($resourceInfo.CpuPercent)%) - reduce runspaces"
        } elseif ($resourceInfo.CpuPercent -lt ($CpuThreshold * 0.5)) {
            $cpuAdjustment = [math]::Min(2, [Environment]::ProcessorCount - $PoolManager.MaxRunspaces) # Increase by up to 2
            $adaptiveConfig.CpuBasedAdjustment = $cpuAdjustment
            $adaptiveConfig.Reasoning += "Low CPU usage ($($resourceInfo.CpuPercent)%) - can increase runspaces"
        }
        
        # Memory-based throttling adjustment
        if ($resourceInfo.MemoryUsedMB -gt $MemoryThresholdMB) {
            $memoryAdjustment = -[math]::Ceiling($PoolManager.MaxRunspaces * 0.3) # Reduce by 30%
            $adaptiveConfig.MemoryBasedAdjustment = $memoryAdjustment
            $adaptiveConfig.Reasoning += "High memory usage ($($resourceInfo.MemoryUsedMB)MB) - reduce runspaces"
        }
        
        # Calculate recommended adjustment (take most conservative)
        $totalAdjustment = [math]::Min($adaptiveConfig.CpuBasedAdjustment, $adaptiveConfig.MemoryBasedAdjustment)
        $adaptiveConfig.RecommendedMaxRunspaces = [math]::Max(1, $PoolManager.MaxRunspaces + $totalAdjustment)
        
        Write-ModuleLog -Message "Adaptive throttling analysis for pool '$poolName': Current: $($PoolManager.MaxRunspaces), Recommended: $($adaptiveConfig.RecommendedMaxRunspaces)" -Level "INFO"
        
        return $adaptiveConfig
        
    } catch {
        Write-ModuleLog -Message "Failed to set adaptive throttling for pool '$poolName': $($_.Exception.Message)" -Level "ERROR"
        throw
    }
}

function Invoke-RunspacePoolCleanup {
    <#
    .SYNOPSIS
    Forces garbage collection and cleanup for memory management
    .DESCRIPTION
    Implements research-validated garbage collection patterns for long-running runspace pool operations
    .PARAMETER PoolManager
    Pool manager object
    .PARAMETER Force
    Force garbage collection even if not recommended
    .EXAMPLE
    Invoke-RunspacePoolCleanup -PoolManager $pool -Force
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [hashtable]$PoolManager,
        [switch]$Force
    )
    
    $poolName = $PoolManager.Name
    Write-ModuleLog -Message "Performing cleanup for runspace pool '$poolName'..." -Level "INFO"
    
    try {
        $cleanupStats = @{
            StartTime = Get-Date
            InitialMemoryMB = 0
            FinalMemoryMB = 0
            MemoryFreedMB = 0
            DisposalStats = $PoolManager.DisposalTracking.Clone()
        }
        
        # Get initial memory usage
        try {
            $process = Get-Process -Id $PID
            $cleanupStats.InitialMemoryMB = [math]::Round($process.WorkingSet64 / 1MB, 2)
        } catch {
            Write-ModuleLog -Message "Could not get initial memory usage" -Level "DEBUG"
        }
        
        # Clear completed job collections to free memory
        $completedCount = $PoolManager.CompletedJobs.Count
        $failedCount = $PoolManager.FailedJobs.Count
        
        $PoolManager.CompletedJobs.Clear()
        $PoolManager.FailedJobs.Clear()
        
        Write-ModuleLog -Message "Cleared $completedCount completed jobs and $failedCount failed jobs from memory" -Level "DEBUG"
        
        # Force garbage collection (research: manual GC for long-running processes)
        if ($Force -or $completedCount -gt 10 -or $failedCount -gt 5) {
            Write-ModuleLog -Message "Forcing garbage collection..." -Level "DEBUG"
            [System.GC]::Collect()
            [System.GC]::WaitForPendingFinalizers()
            [System.GC]::Collect()
        }
        
        # Get final memory usage
        try {
            Start-Sleep -Milliseconds 500 # Allow GC to complete
            $process = Get-Process -Id $PID
            $cleanupStats.FinalMemoryMB = [math]::Round($process.WorkingSet64 / 1MB, 2)
            $cleanupStats.MemoryFreedMB = $cleanupStats.InitialMemoryMB - $cleanupStats.FinalMemoryMB
        } catch {
            Write-ModuleLog -Message "Could not get final memory usage" -Level "DEBUG"
        }
        
        $cleanupStats.Duration = ((Get-Date) - $cleanupStats.StartTime).TotalMilliseconds
        
        Write-ModuleLog -Message "Cleanup completed for pool '$poolName': Freed $($cleanupStats.MemoryFreedMB)MB memory in $($cleanupStats.Duration)ms" -Level "INFO"
        
        return $cleanupStats
        
    } catch {
        Write-ModuleLog -Message "Failed to cleanup pool '$poolName': $($_.Exception.Message)" -Level "ERROR"
        throw
    }
}

function Get-ResourceMonitoringStatus {
    <#
    .SYNOPSIS
    Gets current resource monitoring status for all pools
    .DESCRIPTION
    Returns comprehensive resource monitoring information for all active runspace pools
    .EXAMPLE
    Get-ResourceMonitoringStatus
    #>
    [CmdletBinding()]
    param()
    
    Write-ModuleLog -Message "Getting resource monitoring status for all pools..." -Level "DEBUG"
    
    $status = @{
        Timestamp = Get-Date
        SystemResources = @{
            CpuPercent = 0
            MemoryAvailableMB = 0
            ProcessCount = 0
        }
        Pools = @()
    }
    
    # Get system-wide resources
    try {
        $cpuCounter = Get-Counter -Counter "\Processor(_Total)\% Processor Time" -SampleInterval 1 -MaxSamples 1 -ErrorAction SilentlyContinue
        $status.SystemResources.CpuPercent = [math]::Round($cpuCounter.CounterSamples[0].CookedValue, 2)
        
        $memoryCounter = Get-Counter -Counter "\Memory\Available MBytes" -SampleInterval 1 -MaxSamples 1 -ErrorAction SilentlyContinue
        $status.SystemResources.MemoryAvailableMB = [math]::Round($memoryCounter.CounterSamples[0].CookedValue, 2)
        
        $status.SystemResources.ProcessCount = (Get-Process).Count
    } catch {
        Write-ModuleLog -Message "Failed to get system resource counters: $($_.Exception.Message)" -Level "DEBUG"
    }
    
    # Get pool-specific monitoring status
    $poolRegistry = Get-RunspacePoolRegistry
    foreach ($poolName in $poolRegistry.Keys) {
        $pool = $poolRegistry[$poolName]
        if ($pool.ResourceMonitoring -and $pool.ResourceMonitoring.Enabled) {
            $status.Pools += @{
                Name = $poolName
                Enabled = $true
                CpuThreshold = $pool.ResourceMonitoring.CpuThreshold
                MemoryThresholdMB = $pool.ResourceMonitoring.MemoryThresholdMB
                PeakCpuPercent = $pool.Statistics.PeakCpuPercent
                PeakMemoryUsageMB = $pool.Statistics.PeakMemoryUsageMB
                LastCpuCheck = $pool.ResourceMonitoring.LastCpuCheck
                LastMemoryCheck = $pool.ResourceMonitoring.LastMemoryCheck
            }
        }
    }
    
    Write-ModuleLog -Message "Resource monitoring status retrieved for $($status.Pools.Count) pools" -Level "INFO"
    
    return $status
}

# Export functions
Export-ModuleMember -Function @(
    'Test-RunspacePoolResources',
    'Set-AdaptiveThrottling',
    'Invoke-RunspacePoolCleanup',
    'Get-ResourceMonitoringStatus'
)

Write-ModuleLog -Message "ThrottlingResourceControl component loaded successfully" -Level "DEBUG"
# SIG # Begin signature block
# MIIFzgYJKoZIhvcNAQcCoIIFvzCCBbsCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCDePSrliTDna+/X
# 52ep9I8l0djn6GXQeJUXBBlpEQATtqCCAzAwggMsMIICFKADAgECAhB1HRbZIqgr
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
# MAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIKJvGtKqkCIvCNnd7j8Lgxh2
# 6Bhy562ja8aR4iAnm2D4MA0GCSqGSIb3DQEBAQUABIIBAHllaLFXyIqmhDBUVWJB
# MrFPxNB1rgXlhJP0z0A6CRyAc++ZfskdebopJHhNa48GX2UXckgfHwPl9m6hmLpu
# BqcAhKhiIyULVFGmTzncLbXpuKeBOwXREV24JBIwIBMP6kt9JGVW7jM75ACqj9f4
# tX+Q9fZmMzj16/LD0edacburLjEquNcGW2BWO9CkZKFpknJ/7l3MALK9fkZnk0BU
# zAfT9zZ8xvsanA0DHsQDqp22Nw+jID0J0en2J0jvZBsUbyJtNBuT3/tFIKH9SG7o
# jntTnz3dWCpnnoIiD9QMcT7jV0+U2MzsWluv1u49ziYJhH/odRf4os7UNYqsesxF
# TCg=
# SIG # End signature block
