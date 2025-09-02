# Unity-Claude-RunspaceManagement Pool Management Component
# Core runspace pool management functionality
# Part of refactored RunspaceManagement module

$ErrorActionPreference = "Stop"

# Load core components with circular dependency resolution
$CorePath = Join-Path $PSScriptRoot "RunspaceCore.psm1"
$SessionStatePath = Join-Path $PSScriptRoot "SessionStateConfiguration.psm1"

# Check for and load required functions with fallback
try {
    if (-not (Get-Command Write-ModuleLog -ErrorAction SilentlyContinue)) {
        . $CorePath
    }
    if (-not (Get-Command New-RunspaceSessionState -ErrorAction SilentlyContinue)) {
        . $SessionStatePath
    }
} catch {
    Write-Host "[RunspacePoolManagement] Warning: Could not load dependencies, using fallback logging" -ForegroundColor Yellow
    function Write-ModuleLog {
        param([string]$Message, [string]$Level = "INFO")
        $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        Write-Host "[$timestamp] [RunspacePoolManagement] [$Level] $Message"
    }
    function Update-RunspacePoolRegistry { param($PoolName, $Pool) }
    function Get-RunspacePoolRegistry { return @{} }
}

# Active runspace pools registry
$script:ActiveRunspacePools = @{}

function New-ManagedRunspacePool {
    <#
    .SYNOPSIS
    Creates a new managed runspace pool with configured session state
    .DESCRIPTION
    Creates a runspace pool using research-validated patterns with proper session state configuration
    .PARAMETER SessionStateConfig
    Session state configuration object
    .PARAMETER MinRunspaces
    Minimum number of runspaces in the pool
    .PARAMETER MaxRunspaces
    Maximum number of runspaces in the pool
    .PARAMETER Name
    Optional name for the runspace pool
    .EXAMPLE
    $pool = New-ManagedRunspacePool -SessionStateConfig $config -MinRunspaces 1 -MaxRunspaces 5
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [hashtable]$SessionStateConfig,
        [int]$MinRunspaces = 1,
        [int]$MaxRunspaces = 5,
        [string]$Name = "Unity-Claude-Pool-$(Get-Date -Format 'yyyyMMdd-HHmmss')"
    )
    
    Write-ModuleLog -Message "Creating managed runspace pool '$Name' with $MinRunspaces-$MaxRunspaces runspaces..." -Level "INFO"
    
    try {
        $sessionState = $SessionStateConfig.SessionState
        
        # Create runspace pool using research-validated pattern
        $runspacePool = [runspacefactory]::CreateRunspacePool($MinRunspaces, $MaxRunspaces, $sessionState, $Host)
        
        # Create pool management object
        $poolManager = @{
            RunspacePool = $runspacePool
            Name = $Name
            MinRunspaces = $MinRunspaces
            MaxRunspaces = $MaxRunspaces
            SessionStateConfig = $SessionStateConfig
            Created = Get-Date
            Status = 'Created'
            ActiveJobs = @()
            CompletedJobs = @()
            Statistics = @{
                JobsSubmitted = 0
                JobsCompleted = 0
                JobsFailed = 0
                AverageExecutionTimeMs = 0
            }
        }
        
        # Register pool in both local and core registries
        $script:ActiveRunspacePools[$Name] = $poolManager
        Update-RunspacePoolRegistry -PoolName $Name -Pool $poolManager
        
        Write-ModuleLog -Message "Managed runspace pool '$Name' created successfully" -Level "INFO"
        
        return $poolManager
        
    } catch {
        Write-ModuleLog -Message "Failed to create managed runspace pool '$Name': $($_.Exception.Message)" -Level "ERROR"
        throw
    }
}

function Open-RunspacePool {
    <#
    .SYNOPSIS
    Opens a runspace pool for use
    .DESCRIPTION
    Opens the runspace pool and makes it available for job execution
    .PARAMETER PoolManager
    Pool manager object from New-ManagedRunspacePool
    .EXAMPLE
    Open-RunspacePool -PoolManager $poolManager
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [hashtable]$PoolManager
    )
    
    $poolName = $PoolManager.Name
    Write-ModuleLog -Message "Opening runspace pool '$poolName'..." -Level "INFO"
    
    try {
        $runspacePool = $PoolManager.RunspacePool
        
        # Open the pool
        $runspacePool.Open()
        
        # Update status
        $PoolManager.Status = 'Open'
        $PoolManager.Opened = Get-Date
        
        Write-ModuleLog -Message "Runspace pool '$poolName' opened successfully (State: $($runspacePool.RunspacePoolStateInfo.State))" -Level "INFO"
        
        return @{
            Success = $true
            State = $runspacePool.RunspacePoolStateInfo.State
            AvailableRunspaces = $runspacePool.GetAvailableRunspaces()
            MaxRunspaces = $runspacePool.GetMaxRunspaces()
        }
        
    } catch {
        Write-ModuleLog -Message "Failed to open runspace pool '$poolName': $($_.Exception.Message)" -Level "ERROR"
        $PoolManager.Status = 'Failed'
        throw
    }
}

function Close-RunspacePool {
    <#
    .SYNOPSIS
    Closes a runspace pool
    .DESCRIPTION
    Closes the runspace pool and cleans up resources
    .PARAMETER PoolManager
    Pool manager object
    .PARAMETER Force
    Force close even if jobs are running
    .EXAMPLE
    Close-RunspacePool -PoolManager $poolManager
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [hashtable]$PoolManager,
        [switch]$Force
    )
    
    $poolName = $PoolManager.Name
    Write-ModuleLog -Message "Closing runspace pool '$poolName'..." -Level "INFO"
    
    try {
        $runspacePool = $PoolManager.RunspacePool
        
        # Check for active jobs
        if ($PoolManager.ActiveJobs.Count -gt 0 -and -not $Force) {
            Write-ModuleLog -Message "Cannot close pool '$poolName' - $($PoolManager.ActiveJobs.Count) active jobs running. Use -Force to override." -Level "WARNING"
            return @{
                Success = $false
                Reason = "ActiveJobs"
                ActiveJobCount = $PoolManager.ActiveJobs.Count
            }
        }
        
        # Close the pool
        $runspacePool.Close()
        
        # Update status
        $PoolManager.Status = 'Closed'
        $PoolManager.Closed = Get-Date
        
        # Remove from active pools
        $script:ActiveRunspacePools.Remove($poolName)
        
        # Update core registry
        $coreRegistry = Get-RunspacePoolRegistry
        if ($coreRegistry.ContainsKey($poolName)) {
            $coreRegistry.Remove($poolName)
        }
        
        Write-ModuleLog -Message "Runspace pool '$poolName' closed successfully" -Level "INFO"
        
        return @{
            Success = $true
            State = $runspacePool.RunspacePoolStateInfo.State
            Statistics = $PoolManager.Statistics
        }
        
    } catch {
        Write-ModuleLog -Message "Failed to close runspace pool '$poolName': $($_.Exception.Message)" -Level "ERROR"
        throw
    }
}

function Get-RunspacePoolStatus {
    <#
    .SYNOPSIS
    Gets runspace pool status
    .DESCRIPTION
    Returns current status and statistics for a runspace pool
    .PARAMETER PoolManager
    Pool manager object
    .EXAMPLE
    Get-RunspacePoolStatus -PoolManager $poolManager
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [hashtable]$PoolManager
    )
    
    try {
        $runspacePool = $PoolManager.RunspacePool
        $poolName = $PoolManager.Name
        
        $status = @{
            Name = $poolName
            Status = $PoolManager.Status
            State = $runspacePool.RunspacePoolStateInfo.State
            Created = $PoolManager.Created
            MinRunspaces = $PoolManager.MinRunspaces
            MaxRunspaces = $PoolManager.MaxRunspaces
            AvailableRunspaces = 0
            ActiveJobs = $PoolManager.ActiveJobs.Count
            Statistics = $PoolManager.Statistics
            SessionStateInfo = @{
                ModulesCount = $PoolManager.SessionStateConfig.Metadata.ModulesCount
                VariablesCount = $PoolManager.SessionStateConfig.Metadata.VariablesCount
                LanguageMode = $PoolManager.SessionStateConfig.Metadata.LanguageMode
            }
        }
        
        # Get available runspaces if pool is open
        if ($PoolManager.Status -eq 'Open') {
            try {
                $status.AvailableRunspaces = $runspacePool.GetAvailableRunspaces()
            } catch {
                $status.AvailableRunspaces = "Unknown"
            }
        }
        
        return $status
        
    } catch {
        Write-ModuleLog -Message "Failed to get runspace pool status: $($_.Exception.Message)" -Level "ERROR"
        throw
    }
}

function Test-RunspacePoolHealth {
    <#
    .SYNOPSIS
    Tests runspace pool health
    .DESCRIPTION
    Performs health checks on a runspace pool to ensure it's functioning properly
    .PARAMETER PoolManager
    Pool manager object
    .EXAMPLE
    Test-RunspacePoolHealth -PoolManager $poolManager
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [hashtable]$PoolManager
    )
    
    $poolName = $PoolManager.Name
    Write-ModuleLog -Message "Testing health of runspace pool '$poolName'..." -Level "INFO"
    
    try {
        $runspacePool = $PoolManager.RunspacePool
        
        $healthChecks = @{
            PoolExists = $null -ne $runspacePool
            StateValid = $runspacePool.RunspacePoolStateInfo.State -in @('Opened', 'Opening')
            NoErrors = $null -eq $runspacePool.RunspacePoolStateInfo.Reason
            HasAvailableRunspaces = $false
            SessionStateConfigured = $null -ne $PoolManager.SessionStateConfig
            ManagerStatusConsistent = $PoolManager.Status -eq 'Open'
        }
        
        # Check available runspaces
        if ($healthChecks.StateValid) {
            try {
                $availableRunspaces = $runspacePool.GetAvailableRunspaces()
                $healthChecks.HasAvailableRunspaces = $availableRunspaces -gt 0
                $healthChecks.AvailableRunspaces = $availableRunspaces
            } catch {
                $healthChecks.HasAvailableRunspaces = $false
                $healthChecks.AvailableRunspaces = 0
            }
        }
        
        # Calculate health score
        $healthScore = ($healthChecks.GetEnumerator() | Where-Object { $_.Value -eq $true }).Count
        $totalChecks = ($healthChecks.GetEnumerator() | Where-Object { $_.Key -notlike "*Runspaces" }).Count
        $healthPercentage = [math]::Round(($healthScore / $totalChecks) * 100, 2)
        
        $healthChecks.HealthScore = $healthPercentage
        $healthChecks.IsHealthy = $healthPercentage -ge 80
        
        $healthStatus = if ($healthChecks.IsHealthy) { "Healthy" } else { "Unhealthy" }
        Write-ModuleLog -Message "Runspace pool '$poolName' health check completed: $healthStatus ($healthPercentage%)" -Level "INFO"
        
        return $healthChecks
        
    } catch {
        Write-ModuleLog -Message "Failed to test runspace pool health for '$poolName': $($_.Exception.Message)" -Level "ERROR"
        return @{
            PoolExists = $false
            IsHealthy = $false
            HealthScore = 0
            Error = $_.Exception.Message
        }
    }
}

function Get-AllRunspacePools {
    <#
    .SYNOPSIS
    Gets all active runspace pools
    .DESCRIPTION
    Returns information about all currently active runspace pools
    .EXAMPLE
    Get-AllRunspacePools
    #>
    [CmdletBinding()]
    param()
    
    Write-ModuleLog -Message "Getting all active runspace pools..." -Level "DEBUG"
    
    $pools = @()
    foreach ($poolName in $script:ActiveRunspacePools.Keys) {
        try {
            $status = Get-RunspacePoolStatus -PoolManager $script:ActiveRunspacePools[$poolName]
            $pools += $status
        } catch {
            Write-ModuleLog -Message "Failed to get status for pool '$poolName': $($_.Exception.Message)" -Level "WARNING"
        }
    }
    
    Write-ModuleLog -Message "Found $($pools.Count) active runspace pools" -Level "INFO"
    return $pools
}

# Export functions
Export-ModuleMember -Function @(
    'New-ManagedRunspacePool',
    'Open-RunspacePool',
    'Close-RunspacePool',
    'Get-RunspacePoolStatus',
    'Test-RunspacePoolHealth',
    'Get-AllRunspacePools'
)

Write-ModuleLog -Message "RunspacePoolManagement component loaded successfully" -Level "DEBUG"
# SIG # Begin signature block
# MIIFzgYJKoZIhvcNAQcCoIIFvzCCBbsCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCC7GzDvL7oVnZVQ
# WVw3dWP5flpbKiP+N+IVFELDa5an46CCAzAwggMsMIICFKADAgECAhB1HRbZIqgr
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
# MAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEICSFQsA2N2+1drj+k4G5QjZh
# eE1M8BUCICVm2IiG2OneMA0GCSqGSIb3DQEBAQUABIIBAGh9D4groMOUWT+wKzaf
# eApGPIEp5FukM6wSty1G1pFPdf9F2LBtLY39A2MYUVZhh52zXPwy/KgU93c0Ohfq
# NjH2dixcvdD9AT7lPq1UnkGPGH+6DQLgVOCiFJdPNfbXLgElTQPky2QV+QUaRCfb
# lF2OFQ7Zn1ANeFOy5avO3AzzfKDfy+DPKjFp5wlVoS1jyO/W6otnH7DnNp9A5XN1
# UbPFOjQpUcNc/2ZQ2QxAqnJL+WGlAjSMHqrN+mlERQymt+UZlHaaCCUuAuEUK4kD
# 28D4J8c02ubUWwY7to+yz6Qz9Ks+Q5sef2A2kAWdbrRkKROQ1KVbdg9r9QoVWXij
# ts0=
# SIG # End signature block
