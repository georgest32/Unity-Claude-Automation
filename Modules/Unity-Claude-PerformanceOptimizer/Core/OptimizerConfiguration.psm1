# OptimizerConfiguration.psm1
# Core configuration and initialization for Performance Optimizer

using namespace System.Collections.Concurrent
using namespace System.Threading

# Performance metrics tracking structure
function Initialize-PerformanceMetrics {
    [CmdletBinding()]
    param()
    
    return [hashtable]::Synchronized(@{
        TotalFilesProcessed = 0
        FilesPerSecond = 0.0
        AverageProcessingTime = 0.0
        CacheHitRate = 0.0
        QueueLength = 0
        ActiveThreads = 0
        MemoryUsage = 0
        LastUpdate = [datetime]::Now
        ProcessingErrors = 0
        ThroughputHistory = [System.Collections.Generic.List[double]]::new()
        BottleneckAnalysis = @{}
    })
}

# Calculate optimal thread count based on system resources
function Get-OptimalThreadCount {
    [CmdletBinding()]
    param(
        [decimal]$MemoryThresholdGB = 8
    )
    
    $cpuCores = [Environment]::ProcessorCount
    $optimalThreads = [Math]::Min($cpuCores * 4, 32)  # 4x CPU cores, max 32
    
    # Adjust based on available memory
    $availableMemoryGB = (Get-CimInstance -ClassName Win32_ComputerSystem).TotalPhysicalMemory / 1GB
    if ($availableMemoryGB -lt $MemoryThresholdGB) {
        $optimalThreads = [Math]::Max($optimalThreads / 2, 4)
    }
    
    Write-Verbose "[OptimizerConfiguration] Calculated optimal thread count: $optimalThreads"
    return $optimalThreads
}

# Calculate file processing priority
function Get-FilePriority {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$FilePath
    )
    
    # Higher priority for critical files
    if ($FilePath -match '\.(ps1|psm1|psd1)$') { return 10 }
    if ($FilePath -match '\.(cs|py|js|ts)$') { return 8 }
    if ($FilePath -match '\.(md|txt)$') { return 3 }
    return 5  # default priority
}

# Initialize optimizer components
function Initialize-OptimizerComponents {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [hashtable]$Configuration,
        
        [Parameter(Mandatory)]
        [string]$BasePath
    )
    
    Write-Verbose "[OptimizerConfiguration] Initializing performance components"
    
    $components = @{}
    
    try {
        # Initialize cache manager with optimized settings
        $cacheConfig = @{
            MaxSize = $Configuration.CacheSize
            EnablePersistence = $true
            PersistencePath = Join-Path $BasePath ".cache"
        }
        $components.CacheManager = New-CacheManager @cacheConfig
        
        # Initialize incremental processor
        $incrementalConfig = @{
            BasePath = $BasePath
            ChangeDetectionInterval = $Configuration.IncrementalCheckInterval
        }
        $components.IncrementalProcessor = New-IncrementalProcessor @incrementalConfig
        
        # Initialize parallel processor with optimal thread count
        $optimalThreads = Get-OptimalThreadCount
        $parallelConfig = @{
            MaxThreads = $optimalThreads
            BatchSize = $Configuration.BatchSize
        }
        $components.ParallelProcessor = New-ParallelProcessor @parallelConfig
        
        Write-Verbose "[OptimizerConfiguration] Components initialized successfully"
        return $components
    }
    catch {
        Write-Error "[OptimizerConfiguration] Failed to initialize components: $_"
        throw
    }
}

# Create default configuration
function Get-DefaultOptimizerConfiguration {
    [CmdletBinding()]
    param()
    
    return @{
        TargetThroughput = 100
        CacheSize = 5000
        BatchSize = 50
        IncrementalCheckInterval = 500
        PerformanceReportingInterval = 30
        MaxQueueLength = 1000
        MemoryThresholdMB = 1000
        EnableAutoOptimization = $true
        EnableBottleneckAnalysis = $true
    }
}

# Validate configuration parameters
function Test-OptimizerConfiguration {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [hashtable]$Configuration
    )
    
    $isValid = $true
    $errors = @()
    
    if ($Configuration.TargetThroughput -le 0) {
        $errors += "TargetThroughput must be greater than 0"
        $isValid = $false
    }
    
    if ($Configuration.CacheSize -le 0) {
        $errors += "CacheSize must be greater than 0"
        $isValid = $false
    }
    
    if ($Configuration.BatchSize -le 0 -or $Configuration.BatchSize -gt 500) {
        $errors += "BatchSize must be between 1 and 500"
        $isValid = $false
    }
    
    if ($errors.Count -gt 0) {
        Write-Warning "Configuration validation errors: $($errors -join '; ')"
    }
    
    return $isValid
}

Export-ModuleMember -Function @(
    'Initialize-PerformanceMetrics',
    'Get-OptimalThreadCount',
    'Get-FilePriority',
    'Initialize-OptimizerComponents',
    'Get-DefaultOptimizerConfiguration',
    'Test-OptimizerConfiguration'
)
# SIG # Begin signature block
# MIIFzgYJKoZIhvcNAQcCoIIFvzCCBbsCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCAHwlbxuFl2cwOH
# +xI4QZFtPeJj2j3sCqVxhzXtvyuSj6CCAzAwggMsMIICFKADAgECAhB1HRbZIqgr
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
# MAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEINyUfxrmzf8B92lNpGyhk//d
# rFHz66RqoggTU8V3l3uDMA0GCSqGSIb3DQEBAQUABIIBAIuXjbiwMDB30eBPAs5P
# QAIX2nLu3WVIv8C2zzBjPvtx4uXW7Q/ThG/cmeG7aL4UfDgh9gJ6HJ+gh+t/R8PR
# 5/8A++YzK9GkPGenGmcIEBnSwQK56mZYEaVEgjMYSVNecz9Z1Yc0GZSGZzpaJHQV
# w4esJsaooxxmGdUnFjLFzC8Bd3S2STgIpNOc/NVwmeVRkgst1m8Von8/gpsadEPM
# MC1Zoc9i0ThWcTWtf6Zk+EEea4PvEMtDX4hVMsksDsde1LqPyDRkuEmzRxR0iu0e
# YXcNzGVlAO3Jm5EcecRC4YW2sF7Lh8tbZn7MBBPMHxydkdK28hiqLEjdZsVz+MtK
# Egk=
# SIG # End signature block
