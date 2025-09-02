# Unity-Claude-Learning Metrics Collection Component
# Comprehensive metrics and performance tracking
# Part of refactored Learning module

$ErrorActionPreference = "Stop"

# Import dependencies with fallback logging
$CorePath = Join-Path $PSScriptRoot "LearningCore.psm1"
$SuccessPath = Join-Path $PSScriptRoot "SuccessTracking.psm1"

# Ensure Write-ModuleLog is available - define fallback first
if (-not (Get-Command Write-ModuleLog -ErrorAction SilentlyContinue)) {
    function Write-ModuleLog {
        param([string]$Message, [string]$Level = "INFO")
        $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        Write-Host "[$timestamp] [MetricsCollection] [$Level] $Message"
    }
}

# Check for and load required functions
try {
    Import-Module $CorePath -Force -ErrorAction SilentlyContinue
    Import-Module $SuccessPath -Force -ErrorAction SilentlyContinue
} catch {
    Write-Host "[MetricsCollection] Warning: Could not load dependencies" -ForegroundColor Yellow
}

# Performance metrics storage
$script:PerformanceMetrics = @{
    OperationTimings = @{}
    ResourceUsage = @{}
    CacheHitRate = 0
    CacheAttempts = 0
    CacheHits = 0
}

function Start-PerformanceTimer {
    <#
    .SYNOPSIS
    Starts a performance timer for an operation
    .DESCRIPTION
    Begins tracking execution time for a named operation
    .PARAMETER OperationName
    Name of the operation to track
    .EXAMPLE
    Start-PerformanceTimer -OperationName "PatternSearch"
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$OperationName
    )
    
    if (-not $script:PerformanceMetrics.OperationTimings.ContainsKey($OperationName)) {
        $script:PerformanceMetrics.OperationTimings[$OperationName] = @{
            StartTime = $null
            EndTime = $null
            Duration = $null
            Count = 0
            TotalDuration = [TimeSpan]::Zero
            AverageDuration = [TimeSpan]::Zero
        }
    }
    
    $script:PerformanceMetrics.OperationTimings[$OperationName].StartTime = Get-Date
    
    Write-ModuleLog -Message "Performance timer started for: $OperationName" -Level "DEBUG"
}

function Stop-PerformanceTimer {
    <#
    .SYNOPSIS
    Stops a performance timer and records metrics
    .DESCRIPTION
    Ends tracking and calculates duration for an operation
    .PARAMETER OperationName
    Name of the operation
    .EXAMPLE
    Stop-PerformanceTimer -OperationName "PatternSearch"
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$OperationName
    )
    
    if (-not $script:PerformanceMetrics.OperationTimings.ContainsKey($OperationName)) {
        Write-Warning "No timer found for operation: $OperationName"
        return
    }
    
    $timing = $script:PerformanceMetrics.OperationTimings[$OperationName]
    
    if ($null -eq $timing.StartTime) {
        Write-Warning "Timer was not started for operation: $OperationName"
        return
    }
    
    $timing.EndTime = Get-Date
    $timing.Duration = $timing.EndTime - $timing.StartTime
    $timing.Count++
    $timing.TotalDuration += $timing.Duration
    $timing.AverageDuration = [TimeSpan]::FromTicks($timing.TotalDuration.Ticks / $timing.Count)
    
    Write-ModuleLog -Message "Performance timer stopped for $OperationName : Duration = $($timing.Duration.TotalMilliseconds)ms" -Level "DEBUG"
    
    return @{
        OperationName = $OperationName
        Duration = $timing.Duration
        TotalDuration = $timing.TotalDuration
        Count = $timing.Count
        AverageDuration = $timing.AverageDuration
    }
}

function Get-PerformanceMetrics {
    <#
    .SYNOPSIS
    Gets comprehensive performance metrics
    .DESCRIPTION
    Returns detailed performance statistics
    .PARAMETER OperationName
    Specific operation to get metrics for (optional)
    .EXAMPLE
    Get-PerformanceMetrics -OperationName "PatternSearch"
    #>
    [CmdletBinding()]
    param(
        [string]$OperationName = ""
    )
    
    if ($OperationName) {
        if ($script:PerformanceMetrics.OperationTimings.ContainsKey($OperationName)) {
            return $script:PerformanceMetrics.OperationTimings[$OperationName]
        } else {
            Write-Warning "No metrics found for operation: $OperationName"
            return $null
        }
    }
    
    # Return all metrics
    $metrics = @{
        OperationTimings = $script:PerformanceMetrics.OperationTimings
        ResourceUsage = $script:PerformanceMetrics.ResourceUsage
        CacheStatistics = @{
            HitRate = if ($script:PerformanceMetrics.CacheAttempts -gt 0) {
                ($script:PerformanceMetrics.CacheHits / $script:PerformanceMetrics.CacheAttempts) * 100
            } else { 0 }
            Attempts = $script:PerformanceMetrics.CacheAttempts
            Hits = $script:PerformanceMetrics.CacheHits
        }
    }
    
    return $metrics
}

function Update-CacheMetrics {
    <#
    .SYNOPSIS
    Updates cache performance metrics
    .DESCRIPTION
    Records cache hit/miss statistics
    .PARAMETER Hit
    Whether the cache lookup was successful
    .EXAMPLE
    Update-CacheMetrics -Hit $true
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [bool]$Hit
    )
    
    $script:PerformanceMetrics.CacheAttempts++
    
    if ($Hit) {
        $script:PerformanceMetrics.CacheHits++
    }
    
    $script:PerformanceMetrics.CacheHitRate = if ($script:PerformanceMetrics.CacheAttempts -gt 0) {
        ($script:PerformanceMetrics.CacheHits / $script:PerformanceMetrics.CacheAttempts) * 100
    } else { 0 }
    
    Write-ModuleLog -Message "Cache metrics updated: Hit=$Hit, Rate=$($script:PerformanceMetrics.CacheHitRate)%" -Level "DEBUG"
}

function Measure-ResourceUsage {
    <#
    .SYNOPSIS
    Measures current resource usage
    .DESCRIPTION
    Captures memory and CPU usage statistics
    .EXAMPLE
    Measure-ResourceUsage
    #>
    [CmdletBinding()]
    param()
    
    try {
        $process = Get-Process -Id $PID
        
        $usage = @{
            Timestamp = Get-Date
            WorkingSetMB = [Math]::Round($process.WorkingSet64 / 1MB, 2)
            PrivateMemoryMB = [Math]::Round($process.PrivateMemorySize64 / 1MB, 2)
            VirtualMemoryMB = [Math]::Round($process.VirtualMemorySize64 / 1MB, 2)
            CPUSeconds = [Math]::Round($process.TotalProcessorTime.TotalSeconds, 2)
            ThreadCount = $process.Threads.Count
            HandleCount = $process.HandleCount
        }
        
        # Store in metrics
        $script:PerformanceMetrics.ResourceUsage = $usage
        
        Write-ModuleLog -Message "Resource usage measured: Memory=$($usage.WorkingSetMB)MB, CPU=$($usage.CPUSeconds)s" -Level "DEBUG"
        
        return $usage
        
    } catch {
        Write-ModuleLog -Message "Failed to measure resource usage: $_" -Level "WARNING"
        return $null
    }
}

function Get-LearningStatistics {
    <#
    .SYNOPSIS
    Gets comprehensive learning system statistics
    .DESCRIPTION
    Returns detailed statistics about the learning system
    .PARAMETER IncludeHistory
    Include historical data
    .EXAMPLE
    Get-LearningStatistics -IncludeHistory
    #>
    [CmdletBinding()]
    param(
        [switch]$IncludeHistory
    )
    
    $config = Get-LearningConfig
    $successMetrics = Get-SuccessMetrics -IncludeRates
    $performanceMetrics = Get-PerformanceMetrics
    
    $stats = @{
        Configuration = @{
            StorageBackend = $config.StorageBackend
            DatabasePath = $config.DatabasePath
            EnableAutoFix = $config.EnableAutoFix
            MinConfidence = $config.MinConfidence
            MaxPatternAge = $config.MaxPatternAge
        }
        Success = $successMetrics
        Performance = $performanceMetrics
        ResourceUsage = Measure-ResourceUsage
        Timestamp = Get-Date
    }
    
    if ($IncludeHistory) {
        $stats.History = Get-HistoricalMetrics
    }
    
    # Add database statistics if available
    if ($config.StorageBackend -eq "SQLite") {
        $stats.DatabaseStats = Get-DatabaseStatistics
    }
    
    return $stats
}

function Get-DatabaseStatistics {
    <#
    .SYNOPSIS
    Gets database storage statistics
    .DESCRIPTION
    Returns information about database size and content
    #>
    [CmdletBinding()]
    param()
    
    $config = Get-LearningConfig
    
    if ($config.StorageBackend -ne "SQLite") {
        return @{ Available = $false }
    }
    
    if (-not (Test-Path $config.DatabasePath)) {
        return @{ Available = $false; Reason = "Database file not found" }
    }
    
    $dbFile = Get-Item $config.DatabasePath
    
    $stats = @{
        Available = $true
        FilePath = $config.DatabasePath
        SizeMB = [Math]::Round($dbFile.Length / 1MB, 2)
        LastModified = $dbFile.LastWriteTime
        CreatedDate = $dbFile.CreationTime
    }
    
    # Get table statistics
    try {
        $connection = New-Object System.Data.SQLite.SQLiteConnection
        $connection.ConnectionString = "Data Source=$($config.DatabasePath);Version=3;"
        $connection.Open()
        
        # Count patterns
        $cmd = $connection.CreateCommand()
        $cmd.CommandText = "SELECT COUNT(*) FROM ErrorPatterns"
        $stats.PatternCount = $cmd.ExecuteScalar()
        
        # Count fixes
        $cmd.CommandText = "SELECT COUNT(*) FROM FixPatterns"
        $stats.FixCount = $cmd.ExecuteScalar()
        
        # Count similarity cache
        $cmd.CommandText = "SELECT COUNT(*) FROM PatternSimilarity"
        $stats.SimilarityCacheCount = $cmd.ExecuteScalar()
        
        $connection.Close()
        
    } catch {
        Write-ModuleLog -Message "Failed to get database statistics: $_" -Level "WARNING"
    } finally {
        if ($connection -and $connection.State -eq 'Open') {
            $connection.Close()
        }
        if ($connection) {
            $connection.Dispose()
        }
    }
    
    return $stats
}

function Get-HistoricalMetrics {
    <#
    .SYNOPSIS
    Retrieves historical metrics data
    .DESCRIPTION
    Returns stored historical performance data
    #>
    [CmdletBinding()]
    param()
    
    $config = Get-LearningConfig
    $historyPath = Join-Path $config.StoragePath "metrics_history.json"
    
    if (Test-Path $historyPath) {
        try {
            $history = Get-Content -Path $historyPath -Raw | ConvertFrom-Json
            return $history
        } catch {
            Write-ModuleLog -Message "Failed to load historical metrics: $_" -Level "WARNING"
            return @()
        }
    }
    
    return @()
}

function Export-LearningMetrics {
    <#
    .SYNOPSIS
    Exports all metrics to a file
    .DESCRIPTION
    Saves comprehensive metrics data for analysis
    .PARAMETER Path
    Output file path
    .PARAMETER Format
    Export format (JSON or CSV)
    .EXAMPLE
    Export-LearningMetrics -Path "metrics.json" -Format JSON
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Path,
        
        [ValidateSet('JSON', 'CSV')]
        [string]$Format = 'JSON'
    )
    
    $stats = Get-LearningStatistics -IncludeHistory
    
    try {
        switch ($Format) {
            'JSON' {
                $stats | ConvertTo-Json -Depth 10 | Set-Content -Path $Path -Encoding UTF8
            }
            'CSV' {
                # Flatten for CSV export
                $flat = @()
                
                # Success metrics
                foreach ($key in $stats.Success.Keys) {
                    $flat += [PSCustomObject]@{
                        Category = 'Success'
                        Metric = $key
                        Value = $stats.Success[$key]
                    }
                }
                
                # Performance metrics
                foreach ($op in $stats.Performance.OperationTimings.Keys) {
                    $timing = $stats.Performance.OperationTimings[$op]
                    $flat += [PSCustomObject]@{
                        Category = 'Performance'
                        Metric = "$op.AverageDuration"
                        Value = $timing.AverageDuration.TotalMilliseconds
                    }
                }
                
                $flat | Export-Csv -Path $Path -NoTypeInformation
            }
        }
        
        Write-Host "Metrics exported to: $Path"
        return $true
        
    } catch {
        Write-Error "Failed to export metrics: $_"
        return $false
    }
}

function Reset-PerformanceMetrics {
    <#
    .SYNOPSIS
    Resets performance metrics
    .DESCRIPTION
    Clears all performance tracking data
    #>
    [CmdletBinding()]
    param()
    
    $script:PerformanceMetrics = @{
        OperationTimings = @{}
        ResourceUsage = @{}
        CacheHitRate = 0
        CacheAttempts = 0
        CacheHits = 0
    }
    
    Write-ModuleLog -Message "Performance metrics reset" -Level "INFO"
}

# Export functions
Export-ModuleMember -Function @(
    'Start-PerformanceTimer',
    'Stop-PerformanceTimer',
    'Get-PerformanceMetrics',
    'Update-CacheMetrics',
    'Measure-ResourceUsage',
    'Get-LearningStatistics',
    'Get-DatabaseStatistics',
    'Get-HistoricalMetrics',
    'Export-LearningMetrics',
    'Reset-PerformanceMetrics'
)

Write-ModuleLog -Message "MetricsCollection component loaded successfully" -Level "DEBUG"
# SIG # Begin signature block
# MIIFzgYJKoZIhvcNAQcCoIIFvzCCBbsCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCA3+4Zici6QDTu4
# r4iIPEJ3opwf/XivNMhG3NN4YkeHvqCCAzAwggMsMIICFKADAgECAhB1HRbZIqgr
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
# MAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEINAL914IrZenA9kOV75OCQpt
# h2fH5j69Aj4hoI6bMmNlMA0GCSqGSIb3DQEBAQUABIIBAB0e8AuiimpMwI2Co52E
# 50T8QmN3qJrik8xAkccDNF/smbDdHhXv2OFnG70ZP8BWkDEHZAGuKZ79no9WKZXt
# xIAEht4vc3GxmMufDHh3/aO41f/sSC6xX+yR4vg6irr4JhC01B3odPnkK0Q96zn5
# Qjnt2YCDjUz3ya6HRZ4B4YNP/gfRi2PCVpDqdAIphwuMx2fv1jMRkafTpq9eHq/m
# f69hjiamq33ixKVjxHYWFkzhLQmrMpOEDGGJ1xGEhsw1+kHrcesmW7Pmal7Je5mr
# pbcxK7k5pCFS2svt2W2OKRReW9LHluGlWHTDeCE5vgSJTU/Xko3p/KmY3c+fUwXs
# qRE=
# SIG # End signature block
