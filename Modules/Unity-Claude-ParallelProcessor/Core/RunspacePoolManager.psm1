# RunspacePoolManager.psm1
# Runspace pool creation, management, and lifecycle operations for parallel processing

using namespace System.Management.Automation.Runspaces
using namespace System.Collections.Concurrent
using namespace System.Threading

Write-Debug "[RunspacePoolManager] Module loaded - REFACTORED VERSION"

# Core functions are available from parent module import - no local import needed
# Import-Module "$PSScriptRoot\ParallelProcessorCore.psm1" -Force

#region Runspace Pool Management

class RunspacePoolManager {
    [RunspacePool]$RunspacePool
    [int]$MinThreads
    [int]$MaxThreads
    [scriptblock]$InitializationScript
    [bool]$IsOpen
    [string]$ProcessorId
    [InitialSessionState]$SessionState
    
    RunspacePoolManager([int]$minThreads, [int]$maxThreads, [scriptblock]$initScript, [string]$processorId) {
        Write-ParallelProcessorLog "Initializing RunspacePoolManager" -Level Debug -ProcessorId $processorId -Component "RunspacePoolManager"
        
        $this.MinThreads = [Math]::Max(1, $minThreads)
        $this.MaxThreads = $maxThreads
        $this.InitializationScript = $initScript
        $this.ProcessorId = $processorId
        $this.IsOpen = $false
        
        $this.CreateInitialSessionState()
        $this.CreateRunspacePool()
    }
    
    # Create initial session state with modules and variables
    hidden [void]CreateInitialSessionState() {
        Write-ParallelProcessorLog "Creating initial session state" -Level Debug -ProcessorId $this.ProcessorId -Component "RunspacePoolManager"
        
        # Use CreateDefault for better compatibility
        $this.SessionState = [InitialSessionState]::CreateDefault()
        
        # Import essential modules
        try {
            # Add core PowerShell modules that are commonly needed
            $essentialModules = @('Microsoft.PowerShell.Utility', 'Microsoft.PowerShell.Core')
            foreach ($moduleName in $essentialModules) {
                try {
                    $moduleInfo = Get-Module -Name $moduleName -ListAvailable | Select-Object -First 1
                    if ($moduleInfo) {
                        $this.SessionState.ImportPSModule($moduleName)
                        Write-ParallelProcessorLog "Imported module: $moduleName" -Level Debug -ProcessorId $this.ProcessorId -Component "RunspacePoolManager"
                    }
                } catch {
                    Write-ParallelProcessorLog "Failed to import module $moduleName : $_" -Level Warning -ProcessorId $this.ProcessorId -Component "RunspacePoolManager"
                }
            }
        } catch {
            Write-ParallelProcessorLog "Error setting up session state: $_" -Level Warning -ProcessorId $this.ProcessorId -Component "RunspacePoolManager"
        }
        
        # Add initialization script if provided
        if ($this.InitializationScript) {
            try {
                $this.SessionState.StartupScripts.Add($this.InitializationScript)
                Write-ParallelProcessorLog "Added initialization script" -Level Debug -ProcessorId $this.ProcessorId -Component "RunspacePoolManager"
            } catch {
                Write-ParallelProcessorLog "Failed to add initialization script: $_" -Level Warning -ProcessorId $this.ProcessorId -Component "RunspacePoolManager"
            }
        }
    }
    
    # Create and configure runspace pool
    hidden [void]CreateRunspacePool() {
        Write-ParallelProcessorLog "Creating runspace pool (Min: $($this.MinThreads), Max: $($this.MaxThreads))" -Level Debug -ProcessorId $this.ProcessorId -Component "RunspacePoolManager"
        
        try {
            # Create runspace pool with session state
            $this.RunspacePool = [RunspaceFactory]::CreateRunspacePool(
                $this.MinThreads,
                $this.MaxThreads,
                $this.SessionState,
                [System.Management.Automation.Host.PSHost]$global:Host
            )
            
            # Configure the pool for optimal performance
            $this.ConfigureRunspacePool()
            
            Write-ParallelProcessorLog "Runspace pool created successfully" -Level Debug -ProcessorId $this.ProcessorId -Component "RunspacePoolManager"
        } catch {
            Write-ParallelProcessorLog "Failed to create runspace pool: $_" -Level Error -ProcessorId $this.ProcessorId -Component "RunspacePoolManager"
            throw
        }
    }
    
    # Configure runspace pool settings
    hidden [void]ConfigureRunspacePool() {
        Write-ParallelProcessorLog "Configuring runspace pool" -Level Debug -ProcessorId $this.ProcessorId -Component "RunspacePoolManager"
        
        try {
            # Set apartment state - MTA is preferred for performance
            $this.RunspacePool.ApartmentState = [System.Threading.ApartmentState]::MTA
            
            # Set thread options - ReuseThread for efficiency
            $this.RunspacePool.ThreadOptions = [PSThreadOptions]::ReuseThread
            
            # Set cleanup interval (PowerShell 7+ feature)
            try {
                if ($global:PSVersionTable.PSVersion.Major -ge 7) {
                    try {
                        $this.RunspacePool.CleanupInterval = [TimeSpan]::FromMinutes(5)
                        Write-ParallelProcessorLog "CleanupInterval set to 5 minutes" -Level Debug -ProcessorId $this.ProcessorId -Component "RunspacePoolManager"
                    } catch {
                        # Ignore if not supported
                        Write-ParallelProcessorLog "CleanupInterval not supported in this PowerShell version" -Level Debug -ProcessorId $this.ProcessorId -Component "RunspacePoolManager"
                    }
                }
            } catch {
                Write-ParallelProcessorLog "PSVersionTable not accessible, skipping cleanup interval" -Level Debug -ProcessorId $this.ProcessorId -Component "RunspacePoolManager"
            }
            
            Write-ParallelProcessorLog "Runspace pool configuration completed" -Level Debug -ProcessorId $this.ProcessorId -Component "RunspacePoolManager"
        } catch {
            Write-ParallelProcessorLog "Warning: Some runspace pool configuration failed: $_" -Level Warning -ProcessorId $this.ProcessorId -Component "RunspacePoolManager"
        }
    }
    
    # Open runspace pool
    [void]Open() {
        if ($this.IsOpen) {
            Write-ParallelProcessorLog "Runspace pool is already open" -Level Debug -ProcessorId $this.ProcessorId -Component "RunspacePoolManager"
            return
        }
        
        Write-ParallelProcessorLog "Opening runspace pool" -Level Debug -ProcessorId $this.ProcessorId -Component "RunspacePoolManager"
        
        try {
            $this.RunspacePool.Open()
            $this.IsOpen = $true
            Write-ParallelProcessorLog "Runspace pool opened successfully" -Level Debug -ProcessorId $this.ProcessorId -Component "RunspacePoolManager"
        } catch {
            Write-ParallelProcessorLog "Failed to open runspace pool: $_" -Level Error -ProcessorId $this.ProcessorId -Component "RunspacePoolManager"
            throw
        }
    }
    
    # Close runspace pool
    [void]Close() {
        if (-not $this.IsOpen) {
            Write-ParallelProcessorLog "Runspace pool is already closed" -Level Debug -ProcessorId $this.ProcessorId -Component "RunspacePoolManager"
            return
        }
        
        Write-ParallelProcessorLog "Closing runspace pool" -Level Debug -ProcessorId $this.ProcessorId -Component "RunspacePoolManager"
        
        try {
            $this.RunspacePool.Close()
            $this.IsOpen = $false
            Write-ParallelProcessorLog "Runspace pool closed successfully" -Level Debug -ProcessorId $this.ProcessorId -Component "RunspacePoolManager"
        } catch {
            Write-ParallelProcessorLog "Error closing runspace pool: $_" -Level Warning -ProcessorId $this.ProcessorId -Component "RunspacePoolManager"
        }
    }
    
    # Dispose runspace pool
    [void]Dispose() {
        Write-ParallelProcessorLog "Disposing runspace pool manager" -Level Debug -ProcessorId $this.ProcessorId -Component "RunspacePoolManager"
        
        try {
            if ($this.IsOpen) {
                $this.Close()
            }
            
            if ($this.RunspacePool) {
                $this.RunspacePool.Dispose()
                Write-ParallelProcessorLog "Runspace pool disposed" -Level Debug -ProcessorId $this.ProcessorId -Component "RunspacePoolManager"
            }
        } catch {
            Write-ParallelProcessorLog "Error disposing runspace pool: $_" -Level Warning -ProcessorId $this.ProcessorId -Component "RunspacePoolManager"
        }
    }
    
    # Update runspace pool size
    [void]SetRunspacePoolSize([int]$minThreads, [int]$maxThreads) {
        Write-ParallelProcessorLog "Updating runspace pool size (Min: $minThreads, Max: $maxThreads)" -Level Debug -ProcessorId $this.ProcessorId -Component "RunspacePoolManager"
        
        try {
            if ($this.IsOpen) {
                $this.RunspacePool.SetMinRunspaces($minThreads)
                $this.RunspacePool.SetMaxRunspaces($maxThreads)
                $this.MinThreads = $minThreads
                $this.MaxThreads = $maxThreads
                Write-ParallelProcessorLog "Runspace pool size updated" -Level Debug -ProcessorId $this.ProcessorId -Component "RunspacePoolManager"
            }
        } catch {
            Write-ParallelProcessorLog "Failed to update runspace pool size: $_" -Level Warning -ProcessorId $this.ProcessorId -Component "RunspacePoolManager"
        }
    }
    
    # Get runspace pool information
    [hashtable]GetRunspacePoolInfo() {
        return @{
            IsOpen = $this.IsOpen
            MinThreads = $this.MinThreads
            MaxThreads = $this.MaxThreads
            ApartmentState = if ($this.RunspacePool) { $this.RunspacePool.ApartmentState.ToString() } else { 'Unknown' }
            ThreadOptions = if ($this.RunspacePool) { $this.RunspacePool.ThreadOptions.ToString() } else { 'Unknown' }
            RunspacePoolState = if ($this.RunspacePool) { $this.RunspacePool.RunspacePoolStateInfo.State.ToString() } else { 'Unknown' }
            HasInitializationScript = $null -ne $this.InitializationScript
        }
    }
}

#endregion

#region Helper Functions

function New-RunspacePoolManager {
    [CmdletBinding()]
    param(
        [Parameter()]
        [int]$MinThreads = 1,
        
        [Parameter()]
        [int]$MaxThreads = 0,
        
        [Parameter()]
        [scriptblock]$InitializationScript,
        
        [Parameter(Mandatory)]
        [string]$ProcessorId
    )
    
    # Calculate optimal thread count if not specified
    if ($MaxThreads -eq 0) {
        $MaxThreads = Get-OptimalThreadCount -WorkloadType 'Mixed'
    }
    
    Write-ParallelProcessorLog "Creating RunspacePoolManager" -Level Debug -ProcessorId $ProcessorId -Component "RunspacePoolManager"
    
    try {
        $manager = [RunspacePoolManager]::new($MinThreads, $MaxThreads, $InitializationScript, $ProcessorId)
        $manager.Open()
        
        Write-ParallelProcessorLog "RunspacePoolManager created and opened" -Level Debug -ProcessorId $ProcessorId -Component "RunspacePoolManager"
        return $manager
    } catch {
        Write-ParallelProcessorLog "Failed to create RunspacePoolManager: $_" -Level Error -ProcessorId $ProcessorId -Component "RunspacePoolManager"
        throw
    }
}

function Test-RunspacePoolHealth {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [RunspacePoolManager]$PoolManager
    )
    
    try {
        $info = $PoolManager.GetRunspacePoolInfo()
        
        $healthStatus = @{
            IsHealthy = $true
            Issues = @()
            Info = $info
        }
        
        # Check if pool is open
        if (-not $info.IsOpen) {
            $healthStatus.IsHealthy = $false
            $healthStatus.Issues += "Runspace pool is not open"
        }
        
        # Check pool state
        if ($info.RunspacePoolState -notin @('Opened', 'Opening')) {
            $healthStatus.IsHealthy = $false
            $healthStatus.Issues += "Runspace pool state is: $($info.RunspacePoolState)"
        }
        
        return $healthStatus
    } catch {
        return @{
            IsHealthy = $false
            Issues = @("Error checking runspace pool health: $_")
            Info = @{}
        }
    }
}

#endregion

# Export functions
Export-ModuleMember -Function @(
    'New-RunspacePoolManager',
    'Test-RunspacePoolHealth'
) -Variable @() -Alias @()
# Added by Fix-ParallelProcessorExports
Export-ModuleMember -Function New-RunspacePoolManager


# Added by Fix-ParallelProcessorExports
Export-ModuleMember -Function Test-RunspacePoolHealth


# SIG # Begin signature block
# MIIFzgYJKoZIhvcNAQcCoIIFvzCCBbsCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCC5lvprsw6VD5fS
# /aYNz+r+mbepOjra5uXsloLOIOejHKCCAzAwggMsMIICFKADAgECAhB1HRbZIqgr
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
# MAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIPWu39l5sransEUlL//17/XK
# LFgMjXAd4/MeMPwAMN9pMA0GCSqGSIb3DQEBAQUABIIBADQkR98o1uZGs0CGcRJ9
# rj2Gu9FA52KPsCASNNWGlFHxjPaGagWzqzaX9chv7Nt8RyjcIeqBmqbPd5QWQIMk
# HPfweCboh8ahe0hbsUwuBXJVHl66QOm0De+oB5a/kkaZW35+OQaengfJlmLfwvWV
# idXNK2yA6h77RvIa+y6N/pgVQWNWD5L8ibMpZHNCDxKQLrbUlk4QqaT04iypkw8R
# 5dS5aiziANJNkwYmiD42ZfY1+Pu3Qu6jGRKPL8jHryfTlCrl4B10odGLrvivR7kZ
# C0L6lLCBLyImoogzAxxRYReSVHvyGBzBZLx706ISAi/TXYmj+zEY44nNyyZeOeTb
# X7o=
# SIG # End signature block
