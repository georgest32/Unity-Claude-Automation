# Unity-Claude-ParallelProcessing.psm1
# Parallel processing infrastructure with thread-safe data structures
# Phase 1 Week 1 Day 3-4: Thread Safety Infrastructure Implementation
# Date: 2025-08-20

$ErrorActionPreference = "Stop"

# Fallback logging function for when Write-AgentLog is not available
function Write-AgentLog {
    param(
        [string]$Message,
        [string]$Level = "INFO",
        [string]$Component = "ParallelProcessing"
    )
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss.fff"
    $logMessage = "[$timestamp] [$Level] [$Component] $Message"
    
    switch ($Level) {
        "ERROR" { Write-Host $logMessage -ForegroundColor Red }
        "WARNING" { Write-Host $logMessage -ForegroundColor Yellow }
        "DEBUG" { Write-Host $logMessage -ForegroundColor Gray }
        default { Write-Host $logMessage -ForegroundColor White }
    }
}

# Module-level variables for global state management
$script:GlobalStatusManager = $null
$script:ThreadSafetyStats = @{
    OperationCount = 0
    LockCount = 0
    ErrorCount = 0
    AverageOperationTimeMs = 0
    LastOperationTime = $null
}

# Module loading notification with fallback logging
try {
    if (Get-Command Write-AgentLog -ErrorAction SilentlyContinue) {
        Write-AgentLog -Message "Loading Unity-Claude-ParallelProcessing module..." -Level "DEBUG" -Component "ParallelProcessing"
    } else {
        Write-Host "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss.fff')] [DEBUG] [ParallelProcessing] Loading Unity-Claude-ParallelProcessing module..." -ForegroundColor Gray
    }
} catch {
    Write-Host "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss.fff')] [DEBUG] [ParallelProcessing] Loading Unity-Claude-ParallelProcessing module..." -ForegroundColor Gray
}

#region Synchronized Data Structures

<#
.SYNOPSIS
Creates a new thread-safe synchronized hashtable
.DESCRIPTION
Creates a synchronized hashtable that can be safely accessed from multiple threads
.PARAMETER InitialData
Initial data to populate the hashtable
.PARAMETER EnableStats
Enable operation statistics tracking
.EXAMPLE
$syncHash = New-SynchronizedHashtable -EnableStats
#>
function New-SynchronizedHashtable {
    [CmdletBinding()]
    param(
        [hashtable]$InitialData = @{},
        [switch]$EnableStats
    )
    
    Write-AgentLog -Message "Creating new synchronized hashtable..." -Level "DEBUG" -Component "ParallelProcessing"
    
    try {
        # Create synchronized hashtable
        $syncHash = [hashtable]::Synchronized($InitialData.Clone())
        
        # Add metadata
        $syncHash['_Metadata'] = @{
            Created = Get-Date
            ThreadSafe = $true
            EnableStats = $EnableStats.IsPresent
            LockCount = 0
            OperationCount = 0
        }
        
        Write-AgentLog -Message "Synchronized hashtable created successfully (Thread-safe: True, Stats enabled: $($EnableStats.IsPresent))" -Level "INFO" -Component "ParallelProcessing"
        
        return $syncHash
    }
    catch {
        Write-AgentLog -Message "ERROR creating synchronized hashtable: $($_.Exception.Message)" -Level "ERROR" -Component "ParallelProcessing"
        throw
    }
}

<#
.SYNOPSIS
Safely retrieves a value from a synchronized hashtable
.DESCRIPTION
Thread-safe value retrieval with optional default value
.PARAMETER SyncHash
The synchronized hashtable
.PARAMETER Key
The key to retrieve
.PARAMETER DefaultValue
Default value if key doesn't exist
.EXAMPLE
$value = Get-SynchronizedValue -SyncHash $syncHash -Key "status" -DefaultValue "Unknown"
#>
function Get-SynchronizedValue {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [hashtable]$SyncHash,
        [Parameter(Mandatory)]
        [string]$Key,
        [object]$DefaultValue = $null
    )
    
    $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
    
    try {
        [System.Threading.Monitor]::Enter($SyncHash.SyncRoot)
        
        $value = if ($SyncHash.ContainsKey($Key)) {
            $SyncHash[$Key]
        } else {
            $DefaultValue
        }
        
        # Update stats if enabled
        if ($SyncHash._Metadata -and $SyncHash._Metadata.EnableStats) {
            $SyncHash._Metadata.OperationCount++
        }
        
        $script:ThreadSafetyStats.OperationCount++
        
        return $value
    }
    finally {
        [System.Threading.Monitor]::Exit($SyncHash.SyncRoot)
        $stopwatch.Stop()
        
        # Update average operation time
        $script:ThreadSafetyStats.AverageOperationTimeMs = 
            ($script:ThreadSafetyStats.AverageOperationTimeMs + $stopwatch.ElapsedMilliseconds) / 2
        $script:ThreadSafetyStats.LastOperationTime = Get-Date
    }
}

<#
.SYNOPSIS
Safely sets a value in a synchronized hashtable
.DESCRIPTION
Thread-safe value setting with operation tracking
.PARAMETER SyncHash
The synchronized hashtable
.PARAMETER Key
The key to set
.PARAMETER Value
The value to set
.PARAMETER UpdateTimestamp
Add/update timestamp for the operation
.EXAMPLE
Set-SynchronizedValue -SyncHash $syncHash -Key "status" -Value "Running" -UpdateTimestamp
#>
function Set-SynchronizedValue {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [hashtable]$SyncHash,
        [Parameter(Mandatory)]
        [string]$Key,
        [Parameter(Mandatory)]
        [object]$Value,
        [switch]$UpdateTimestamp
    )
    
    $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
    
    try {
        [System.Threading.Monitor]::Enter($SyncHash.SyncRoot)
        
        $SyncHash[$Key] = $Value
        
        if ($UpdateTimestamp) {
            $SyncHash["${Key}_Timestamp"] = Get-Date
        }
        
        # Update stats if enabled
        if ($SyncHash._Metadata -and $SyncHash._Metadata.EnableStats) {
            $SyncHash._Metadata.OperationCount++
        }
        
        $script:ThreadSafetyStats.OperationCount++
        
        Write-AgentLog -Message "Set synchronized value: $Key = $Value" -Level "DEBUG" -Component "ParallelProcessing"
    }
    finally {
        [System.Threading.Monitor]::Exit($SyncHash.SyncRoot)
        $stopwatch.Stop()
        
        $script:ThreadSafetyStats.AverageOperationTimeMs = 
            ($script:ThreadSafetyStats.AverageOperationTimeMs + $stopwatch.ElapsedMilliseconds) / 2
        $script:ThreadSafetyStats.LastOperationTime = Get-Date
    }
}

<#
.SYNOPSIS
Safely removes a value from a synchronized hashtable
.DESCRIPTION
Thread-safe key removal with confirmation
.PARAMETER SyncHash
The synchronized hashtable
.PARAMETER Key
The key to remove
.EXAMPLE
$removed = Remove-SynchronizedValue -SyncHash $syncHash -Key "oldStatus"
#>
function Remove-SynchronizedValue {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [hashtable]$SyncHash,
        [Parameter(Mandatory)]
        [string]$Key
    )
    
    $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
    
    try {
        [System.Threading.Monitor]::Enter($SyncHash.SyncRoot)
        
        $existed = $SyncHash.ContainsKey($Key)
        if ($existed) {
            $SyncHash.Remove($Key)
            # Also remove timestamp if it exists
            $timestampKey = "${Key}_Timestamp"
            if ($SyncHash.ContainsKey($timestampKey)) {
                $SyncHash.Remove($timestampKey)
            }
        }
        
        # Update stats if enabled
        if ($SyncHash._Metadata -and $SyncHash._Metadata.EnableStats) {
            $SyncHash._Metadata.OperationCount++
        }
        
        $script:ThreadSafetyStats.OperationCount++
        
        Write-AgentLog -Message "Removed synchronized value: $Key (existed: $existed)" -Level "DEBUG" -Component "ParallelProcessing"
        return $existed
    }
    finally {
        [System.Threading.Monitor]::Exit($SyncHash.SyncRoot)
        $stopwatch.Stop()
        
        $script:ThreadSafetyStats.AverageOperationTimeMs = 
            ($script:ThreadSafetyStats.AverageOperationTimeMs + $stopwatch.ElapsedMilliseconds) / 2
        $script:ThreadSafetyStats.LastOperationTime = Get-Date
    }
}

<#
.SYNOPSIS
Manually locks a synchronized hashtable for exclusive access
.DESCRIPTION
Provides manual lock control for complex operations. Must be paired with Unlock-SynchronizedHashtable
.PARAMETER SyncHash
The synchronized hashtable to lock
.EXAMPLE
Lock-SynchronizedHashtable -SyncHash $syncHash
try { # complex operations } finally { Unlock-SynchronizedHashtable -SyncHash $syncHash }
#>
function Lock-SynchronizedHashtable {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [hashtable]$SyncHash
    )
    
    Write-AgentLog -Message "Acquiring lock on synchronized hashtable..." -Level "DEBUG" -Component "ParallelProcessing"
    [System.Threading.Monitor]::Enter($SyncHash.SyncRoot)
    
    # Update stats
    if ($SyncHash._Metadata) {
        $SyncHash._Metadata.LockCount++
    }
    $script:ThreadSafetyStats.LockCount++
    
    Write-AgentLog -Message "Lock acquired successfully" -Level "DEBUG" -Component "ParallelProcessing"
}

<#
.SYNOPSIS
Manually unlocks a synchronized hashtable
.DESCRIPTION
Releases manual lock acquired with Lock-SynchronizedHashtable
.PARAMETER SyncHash
The synchronized hashtable to unlock
.EXAMPLE
Unlock-SynchronizedHashtable -SyncHash $syncHash
#>
function Unlock-SynchronizedHashtable {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [hashtable]$SyncHash
    )
    
    Write-AgentLog -Message "Releasing lock on synchronized hashtable..." -Level "DEBUG" -Component "ParallelProcessing"
    [System.Threading.Monitor]::Exit($SyncHash.SyncRoot)
    Write-AgentLog -Message "Lock released successfully" -Level "DEBUG" -Component "ParallelProcessing"
}

#endregion

#region Status Management System

<#
.SYNOPSIS
Initializes the parallel status management system
.DESCRIPTION
Creates a global thread-safe status manager to replace JSON file operations
.PARAMETER EnablePersistence
Enable periodic persistence to disk
.PARAMETER PersistenceIntervalSeconds
How often to persist to disk
.EXAMPLE
Initialize-ParallelStatusManager -EnablePersistence -PersistenceIntervalSeconds 30
#>
function Initialize-ParallelStatusManager {
    [CmdletBinding()]
    param(
        [switch]$EnablePersistence,
        [int]$PersistenceIntervalSeconds = 60
    )
    
    Write-Host "Initializing parallel status manager..." -ForegroundColor Yellow
    
    try {
        # Create global synchronized status hashtable
        $script:GlobalStatusManager = New-SynchronizedHashtable -EnableStats
        
        # Initialize core status structure
        $coreStatus = @{
            SystemInfo = @{
                InitializedAt = Get-Date
                ParallelProcessingEnabled = $true
                PersistenceEnabled = $EnablePersistence.IsPresent
                PersistenceInterval = $PersistenceIntervalSeconds
            }
            Subsystems = @{}
            Performance = @{
                TotalOperations = 0
                AverageResponseTime = 0
                LastUpdateTime = Get-Date
            }
            Threads = @{
                ActiveRunspaces = 0
                QueuedOperations = 0
                CompletedOperations = 0
            }
        }
        
        # Populate with thread-safe operations
        foreach ($key in $coreStatus.Keys) {
            Set-SynchronizedValue -SyncHash $script:GlobalStatusManager -Key $key -Value $coreStatus[$key] -UpdateTimestamp
        }
        
        Write-Host "  Global status manager initialized successfully" -ForegroundColor Green
        Write-Host "  Persistence enabled: $($EnablePersistence.IsPresent)" -ForegroundColor Gray
        Write-Host "  Core subsystems initialized" -ForegroundColor Gray
        
        return $script:GlobalStatusManager
    }
    catch {
        Write-Host "  ERROR initializing status manager: $($_.Exception.Message)" -ForegroundColor Red
        throw
    }
}

<#
.SYNOPSIS
Retrieves status information from the parallel status manager
.DESCRIPTION
Thread-safe status retrieval with optional filtering
.PARAMETER Subsystem
Specific subsystem to retrieve (optional)
.PARAMETER IncludeMetadata
Include metadata in results
.EXAMPLE
$status = Get-ParallelStatus
$agentStatus = Get-ParallelStatus -Subsystem "Unity-Claude-AutonomousAgent"
#>
function Get-ParallelStatus {
    [CmdletBinding()]
    param(
        [string]$Subsystem,
        [switch]$IncludeMetadata
    )
    
    if (-not $script:GlobalStatusManager) {
        Write-Host "  Warning: Status manager not initialized. Call Initialize-ParallelStatusManager first." -ForegroundColor Yellow
        return $null
    }
    
    try {
        if ($Subsystem) {
            # Get specific subsystem status
            $subsystems = Get-SynchronizedValue -SyncHash $script:GlobalStatusManager -Key "Subsystems" -DefaultValue @{}
            $subsystemStatus = $subsystems[$Subsystem]
            
            if ($IncludeMetadata) {
                $metadata = Get-SynchronizedValue -SyncHash $script:GlobalStatusManager -Key "_Metadata"
                return @{
                    Subsystem = $Subsystem
                    Status = $subsystemStatus
                    Metadata = $metadata
                }
            }
            
            return $subsystemStatus
        }
        else {
            # Get full status
            $fullStatus = @{}
            
            Lock-SynchronizedHashtable -SyncHash $script:GlobalStatusManager
            try {
                foreach ($key in $script:GlobalStatusManager.Keys) {
                    if ($key -ne "_Metadata" -or $IncludeMetadata) {
                        $fullStatus[$key] = $script:GlobalStatusManager[$key]
                    }
                }
            }
            finally {
                Unlock-SynchronizedHashtable -SyncHash $script:GlobalStatusManager
            }
            
            return $fullStatus
        }
    }
    catch {
        Write-Host "  ERROR retrieving parallel status: $($_.Exception.Message)" -ForegroundColor Red
        $script:ThreadSafetyStats.ErrorCount++
        throw
    }
}

<#
.SYNOPSIS
Sets status information in the parallel status manager
.DESCRIPTION
Thread-safe status setting with subsystem support
.PARAMETER Subsystem
The subsystem name
.PARAMETER StatusData
The status data to set
.PARAMETER UpdateGlobalStats
Update global performance statistics
.EXAMPLE
Set-ParallelStatus -Subsystem "Unity-Claude-AutonomousAgent" -StatusData @{Status="Running"; PID=1234}
#>
function Set-ParallelStatus {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Subsystem,
        [Parameter(Mandatory)]
        [hashtable]$StatusData,
        [switch]$UpdateGlobalStats
    )
    
    if (-not $script:GlobalStatusManager) {
        Write-Host "  Warning: Status manager not initialized. Initializing with defaults..." -ForegroundColor Yellow
        Initialize-ParallelStatusManager
    }
    
    try {
        # Get current subsystems
        $subsystems = Get-SynchronizedValue -SyncHash $script:GlobalStatusManager -Key "Subsystems" -DefaultValue @{}
        
        # Update subsystem data
        $subsystems[$Subsystem] = $StatusData.Clone()
        $subsystems[$Subsystem]["LastUpdated"] = Get-Date
        
        # Set back to manager
        Set-SynchronizedValue -SyncHash $script:GlobalStatusManager -Key "Subsystems" -Value $subsystems -UpdateTimestamp
        
        # Update global stats if requested
        if ($UpdateGlobalStats) {
            $performance = Get-SynchronizedValue -SyncHash $script:GlobalStatusManager -Key "Performance" -DefaultValue @{}
            $performance.TotalOperations++
            $performance.LastUpdateTime = Get-Date
            Set-SynchronizedValue -SyncHash $script:GlobalStatusManager -Key "Performance" -Value $performance -UpdateTimestamp
        }
        
        Write-Host "  Status updated for subsystem: $Subsystem" -ForegroundColor Gray
    }
    catch {
        Write-Host "  ERROR setting parallel status: $($_.Exception.Message)" -ForegroundColor Red
        $script:ThreadSafetyStats.ErrorCount++
        throw
    }
}

<#
.SYNOPSIS
Updates specific fields in subsystem status
.DESCRIPTION
Thread-safe partial status updates
.PARAMETER Subsystem
The subsystem name
.PARAMETER Updates
Hashtable of fields to update
.EXAMPLE
Update-ParallelStatus -Subsystem "SystemMonitoring" -Updates @{HealthScore=0.95; LastHeartbeat=(Get-Date)}
#>
function Update-ParallelStatus {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Subsystem,
        [Parameter(Mandatory)]
        [hashtable]$Updates
    )
    
    if (-not $script:GlobalStatusManager) {
        Write-Host "  Warning: Status manager not initialized. Initializing with defaults..." -ForegroundColor Yellow
        Initialize-ParallelStatusManager
    }
    
    try {
        # Get current subsystem status
        $subsystemStatus = Get-ParallelStatus -Subsystem $Subsystem
        if (-not $subsystemStatus) {
            $subsystemStatus = @{}
        }
        
        # Apply updates
        foreach ($key in $Updates.Keys) {
            $subsystemStatus[$key] = $Updates[$key]
        }
        
        # Save back
        Set-ParallelStatus -Subsystem $Subsystem -StatusData $subsystemStatus -UpdateGlobalStats
        
        Write-Host "  Updated $($Updates.Keys.Count) fields for subsystem: $Subsystem" -ForegroundColor Gray
    }
    catch {
        Write-Host "  ERROR updating parallel status: $($_.Exception.Message)" -ForegroundColor Red
        $script:ThreadSafetyStats.ErrorCount++
        throw
    }
}

<#
.SYNOPSIS
Clears status data for a subsystem or entire manager
.DESCRIPTION
Thread-safe status clearing
.PARAMETER Subsystem
Specific subsystem to clear (if not specified, clears all)
.EXAMPLE
Clear-ParallelStatus -Subsystem "OldSubsystem"
Clear-ParallelStatus  # Clears all
#>
function Clear-ParallelStatus {
    [CmdletBinding()]
    param(
        [string]$Subsystem
    )
    
    if (-not $script:GlobalStatusManager) {
        Write-Host "  Status manager not initialized - nothing to clear" -ForegroundColor Gray
        return
    }
    
    try {
        if ($Subsystem) {
            # Clear specific subsystem
            $subsystems = Get-SynchronizedValue -SyncHash $script:GlobalStatusManager -Key "Subsystems" -DefaultValue @{}
            if ($subsystems.ContainsKey($Subsystem)) {
                $subsystems.Remove($Subsystem)
                Set-SynchronizedValue -SyncHash $script:GlobalStatusManager -Key "Subsystems" -Value $subsystems
                Write-Host "  Cleared status for subsystem: $Subsystem" -ForegroundColor Gray
            }
        }
        else {
            # Clear entire manager
            Lock-SynchronizedHashtable -SyncHash $script:GlobalStatusManager
            try {
                $keysToRemove = @()
                foreach ($key in $script:GlobalStatusManager.Keys) {
                    if ($key -ne "_Metadata") {
                        $keysToRemove += $key
                    }
                }
                foreach ($key in $keysToRemove) {
                    $script:GlobalStatusManager.Remove($key)
                }
            }
            finally {
                Unlock-SynchronizedHashtable -SyncHash $script:GlobalStatusManager
            }
            Write-AgentLog -Message "Cleared all status data" -Level "INFO" -Component "ParallelProcessing"
        }
    }
    catch {
        Write-AgentLog -Message "ERROR clearing parallel status: $($_.Exception.Message)" -Level "ERROR" -Component "ParallelProcessing"
        $script:ThreadSafetyStats.ErrorCount++
        throw
    }
}

#endregion

#region Thread-Safe Operations

<#
.SYNOPSIS
Executes an operation in a thread-safe manner
.DESCRIPTION
Wrapper for thread-safe operation execution with error handling and timing
.PARAMETER ScriptBlock
The script block to execute
.PARAMETER SyncHash
Optional synchronized hashtable for data access
.PARAMETER TimeoutMs
Timeout in milliseconds (default: 30000)
.EXAMPLE
$result = Invoke-ThreadSafeOperation -ScriptBlock { Get-Process | Select-Object -First 5 }
#>
function Invoke-ThreadSafeOperation {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [scriptblock]$ScriptBlock,
        [hashtable]$SyncHash,
        [int]$TimeoutMs = 30000
    )
    
    $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
    $operationId = [System.Guid]::NewGuid().ToString().Substring(0,8)
    
    Write-Host "  Starting thread-safe operation [$operationId]..." -ForegroundColor Gray
    
    try {
        if ($SyncHash) {
            Lock-SynchronizedHashtable -SyncHash $SyncHash
        }
        
        # Execute with timeout protection
        $job = Start-Job -ScriptBlock $ScriptBlock
        $result = $job | Wait-Job -Timeout ($TimeoutMs / 1000)
        
        if ($result) {
            $output = Receive-Job $job
            Remove-Job $job
            
            $stopwatch.Stop()
            Write-Host "  Thread-safe operation [$operationId] completed in $($stopwatch.ElapsedMilliseconds)ms" -ForegroundColor Green
            
            $script:ThreadSafetyStats.OperationCount++
            return $output
        }
        else {
            Remove-Job $job -Force
            throw "Operation timed out after $TimeoutMs ms"
        }
    }
    catch {
        $stopwatch.Stop()
        Write-Host "  Thread-safe operation [$operationId] FAILED after $($stopwatch.ElapsedMilliseconds)ms: $($_.Exception.Message)" -ForegroundColor Red
        $script:ThreadSafetyStats.ErrorCount++
        throw
    }
    finally {
        if ($SyncHash) {
            Unlock-SynchronizedHashtable -SyncHash $SyncHash
        }
    }
}

<#
.SYNOPSIS
Tests thread safety of operations using runspace pools
.DESCRIPTION
Runs concurrent operations to validate thread safety using proper runspace-based threading
.PARAMETER Iterations
Number of test iterations
.PARAMETER ConcurrencyLevel
Number of concurrent operations
.EXAMPLE
$testResults = Test-ThreadSafety -Iterations 100 -ConcurrencyLevel 5
#>
function Test-ThreadSafety {
    [CmdletBinding()]
    param(
        [int]$Iterations = 50,
        [int]$ConcurrencyLevel = 3
    )
    
    Write-Host "Testing thread safety with $Iterations iterations and $ConcurrencyLevel concurrent operations using runspaces..." -ForegroundColor Yellow
    
    try {
        $testHash = New-SynchronizedHashtable -EnableStats
        $testResults = @{
            StartTime = Get-Date
            Iterations = $Iterations
            ConcurrencyLevel = $ConcurrencyLevel
            Errors = @()
            CompletedOperations = 0
            TotalTimeMs = 0
            ThreadingModel = "Runspaces"
        }
        
        Write-Host "  Creating runspace pool for concurrent testing..." -ForegroundColor Gray
        
        # Create runspace pool for true thread-based parallel execution
        $initialSessionState = [System.Management.Automation.Runspaces.InitialSessionState]::CreateDefault()
        $runspacePool = [System.Management.Automation.Runspaces.RunspaceFactory]::CreateRunspacePool(1, $ConcurrencyLevel, $initialSessionState, $Host)
        $runspacePool.Open()
        
        Write-Host "    Runspace pool created successfully with $ConcurrencyLevel runspaces" -ForegroundColor Gray
        
        $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
        
        # Run concurrent operations using runspaces
        $runspaceJobs = @()
        for ($i = 1; $i -le $ConcurrencyLevel; $i++) {
            Write-Host "  Starting runspace $i..." -ForegroundColor Gray
            
            $ps = [System.Management.Automation.PowerShell]::Create()
            $ps.RunspacePool = $runspacePool
            
            # Add the script block with parameters for concurrent operations
            $ps.AddScript({
                param($SyncHash, $Iterations, $ThreadId)
                $results = @{
                    Success = $true
                    ThreadId = $ThreadId
                    Operations = 0
                    Errors = @()
                }
                
                Write-Host "    Runspace ${ThreadId}: Starting $Iterations operations" -ForegroundColor Gray
                
                for ($j = 1; $j -le $Iterations; $j++) {
                    try {
                        # Simulate thread-safe operations with proper locking
                        $key = "thread_${ThreadId}_operation_$j"
                        $value = "value_${ThreadId}_$j"
                        
                        # Set value with proper locking
                        [System.Threading.Monitor]::Enter($SyncHash.SyncRoot)
                        try {
                            $SyncHash[$key] = $value
                        }
                        finally {
                            [System.Threading.Monitor]::Exit($SyncHash.SyncRoot)
                        }
                        
                        # Read value with proper locking
                        [System.Threading.Monitor]::Enter($SyncHash.SyncRoot)
                        try {
                            $readValue = $SyncHash[$key]
                        }
                        finally {
                            [System.Threading.Monitor]::Exit($SyncHash.SyncRoot)
                        }
                        
                        # Verify consistency
                        if ($readValue -ne $value) {
                            throw "Thread safety violation: Expected '$value', got '$readValue'"
                        }
                        
                        $results.Operations++
                        
                        # Small delay to increase concurrency pressure
                        Start-Sleep -Milliseconds (Get-Random -Minimum 1 -Maximum 3)
                    }
                    catch {
                        $results.Errors += @{
                            Error = $_.Exception.Message
                            ThreadId = $ThreadId
                            Operation = $j
                        }
                        $results.Success = $false
                    }
                }
                
                Write-Host "    Runspace ${ThreadId}: Completed $($results.Operations) operations" -ForegroundColor Gray
                return $results
            })
            
            # Add parameters for the script block
            $ps.AddParameters(@($testHash, $Iterations, $i))
            
            # Start the runspace execution
            $handle = $ps.BeginInvoke()
            $runspaceJobs += @{ PowerShell = $ps; Handle = $handle; ThreadId = $i }
        }
        
        Write-Host "  Waiting for all runspaces to complete..." -ForegroundColor Gray
        
        # Wait for all runspaces to complete and collect results
        $results = @()
        foreach ($job in $runspaceJobs) {
            try {
                $result = $job.PowerShell.EndInvoke($job.Handle)
                $results += $result
                Write-Host "    Runspace $($job.ThreadId) completed successfully" -ForegroundColor Green
            }
            catch {
                Write-Host "    Runspace $($job.ThreadId) failed: $($_.Exception.Message)" -ForegroundColor Red
                $testResults.Errors += @{
                    Error = $_.Exception.Message
                    ThreadId = $job.ThreadId
                    Source = "RunspaceExecution"
                }
            }
            finally {
                $job.PowerShell.Dispose()
            }
        }
        
        # Close runspace pool
        $runspacePool.Close()
        $runspacePool.Dispose()
        
        $stopwatch.Stop()
        $testResults.TotalTimeMs = $stopwatch.ElapsedMilliseconds
        
        Write-Host "  Analyzing results..." -ForegroundColor Gray
        
        # Analyze results
        foreach ($result in $results) {
            if ($result.Errors -and $result.Errors.Count -gt 0) {
                $testResults.Errors += $result.Errors
            }
            $testResults.CompletedOperations += $result.Operations
        }
        
        $testResults.EndTime = Get-Date
        $testResults.Success = ($testResults.Errors.Count -eq 0)
        $testResults.HashTableFinalCount = $testHash.Count - 1  # Subtract metadata
        $testResults.ExpectedCount = $Iterations * $ConcurrencyLevel
        $testResults.ConsistencyCheck = ($testResults.HashTableFinalCount -eq $testResults.ExpectedCount)
        
        Write-Host "  Thread safety test completed:" -ForegroundColor $(if ($testResults.Success -and $testResults.ConsistencyCheck) { "Green" } else { "Yellow" })
        Write-Host "    Threading model: $($testResults.ThreadingModel)" -ForegroundColor Gray
        Write-Host "    Operations completed: $($testResults.CompletedOperations)" -ForegroundColor Gray
        Write-Host "    Errors: $($testResults.Errors.Count)" -ForegroundColor Gray
        Write-Host "    Final hashtable count: $($testResults.HashTableFinalCount)" -ForegroundColor Gray
        Write-Host "    Expected count: $($testResults.ExpectedCount)" -ForegroundColor Gray
        Write-Host "    Consistency check: $($testResults.ConsistencyCheck)" -ForegroundColor Gray
        Write-Host "    Total time: $($testResults.TotalTimeMs)ms" -ForegroundColor Gray
        
        return $testResults
    }
    catch {
        Write-Host "  ERROR in thread safety test: $($_.Exception.Message)" -ForegroundColor Red
        $script:ThreadSafetyStats.ErrorCount++
        throw
    }
}

<#
.SYNOPSIS
Gets current thread safety statistics
.DESCRIPTION
Returns statistics about thread-safe operations performed
.EXAMPLE
$stats = Get-ThreadSafetyStats
#>
function Get-ThreadSafetyStats {
    [CmdletBinding()]
    param()
    
    $stats = $script:ThreadSafetyStats.Clone()
    
    # Add global status manager stats if available
    if ($script:GlobalStatusManager -and $script:GlobalStatusManager._Metadata) {
        $stats.GlobalManagerStats = $script:GlobalStatusManager._Metadata
    }
    
    return $stats
}

#endregion

#region Concurrent Logging Infrastructure (Hours 7-8)

# Module-level concurrent logging infrastructure
$script:LoggingQueue = $null
$script:LoggingProcessor = $null
$script:LoggingEnabled = $false

<#
.SYNOPSIS
Initializes high-performance concurrent logging system for runspace pools

.DESCRIPTION
Creates a buffered logging system using ConcurrentQueue to minimize mutex contention
in high-throughput parallel processing scenarios. Uses producer-consumer pattern
with dedicated background logging processor.

.PARAMETER BufferSize
Maximum number of log entries to buffer before forcing flush

.PARAMETER ProcessorIntervalMs  
Interval in milliseconds for background log processor

.EXAMPLE
Initialize-ConcurrentLogging -BufferSize 1000 -ProcessorIntervalMs 100
#>
function Initialize-ConcurrentLogging {
    [CmdletBinding()]
    param(
        [int]$BufferSize = 500,
        [int]$ProcessorIntervalMs = 50
    )
    
    try {
        Write-AgentLog -Message "Initializing concurrent logging system (BufferSize: $BufferSize, Interval: ${ProcessorIntervalMs}ms)" -Level "INFO" -Component "ParallelProcessing"
        
        # Create buffered logging queue using our ConcurrentQueue wrapper
        $script:LoggingQueue = New-ConcurrentQueue
        
        # Start background logging processor
        $script:LoggingProcessor = Start-Job -ScriptBlock {
            param($LogQueue, $IntervalMs, $AgentLoggingPath)
            
            # Import AgentLogging in background job
            Import-Module $AgentLoggingPath -Force
            
            $batchSize = 10
            $logBatch = @()
            
            while ($true) {
                try {
                    # Process batch of log entries to reduce mutex contention
                    for ($i = 0; $i -lt $batchSize; $i++) {
                        $logEntry = $null
                        if ($LogQueue.InternalQueue.TryDequeue([ref]$logEntry)) {
                            $logBatch += $logEntry
                        } else {
                            break  # No more items in queue
                        }
                    }
                    
                    # Write batch to log file (single mutex operation)
                    if ($logBatch.Count -gt 0) {
                        foreach ($entry in $logBatch) {
                            Write-AgentLog -Message $entry.Message -Level $entry.Level -Component $entry.Component -NoConsole
                        }
                        $logBatch = @()  # Clear batch
                    }
                    
                    Start-Sleep -Milliseconds $IntervalMs
                } catch {
                    # Background logging should not fail catastrophically
                    Write-Warning "Background logging processor error: $_"
                    Start-Sleep -Milliseconds 1000  # Longer delay on error
                }
            }
        } -ArgumentList $script:LoggingQueue, $ProcessorIntervalMs, "$PSScriptRoot\..\Unity-Claude-AutonomousAgent\Core\AgentLogging.psm1"
        
        $script:LoggingEnabled = $true
        Write-AgentLog -Message "Concurrent logging system initialized successfully" -Level "SUCCESS" -Component "ParallelProcessing"
        
    } catch {
        Write-AgentLog -Message "Failed to initialize concurrent logging: $($_.Exception.Message)" -Level "ERROR" -Component "ParallelProcessing"
        throw
    }
}

<#
.SYNOPSIS
High-performance thread-safe logging for runspace pool operations

.DESCRIPTION
Queues log entries for background processing to minimize mutex contention.
Falls back to direct AgentLog if concurrent logging not initialized.

.PARAMETER Message
The log message to write

.PARAMETER Level
Log level (DEBUG, INFO, WARNING, ERROR, SUCCESS)

.PARAMETER Component
Component name for categorization

.EXAMPLE
Write-ConcurrentLog -Message "Processing Unity error in runspace 3" -Level "INFO" -Component "ParallelProcessing"
#>
function Write-ConcurrentLog {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Message,
        
        [ValidateSet("DEBUG", "INFO", "WARNING", "ERROR", "SUCCESS")]
        [string]$Level = "INFO",
        
        [string]$Component = "ParallelProcessing"
    )
    
    if ($script:LoggingEnabled -and $script:LoggingQueue) {
        # Queue log entry for background processing (minimal contention)
        $logEntry = @{
            Message = $Message
            Level = $Level
            Component = $Component
            Timestamp = Get-Date
        }
        
        Add-ConcurrentQueueItem -Queue $script:LoggingQueue -Item $logEntry | Out-Null
    } else {
        # Fallback to direct logging if concurrent logging not available
        Write-AgentLog -Message $Message -Level $Level -Component $Component
    }
}

<#
.SYNOPSIS
Stops concurrent logging system and flushes remaining entries

.DESCRIPTION
Gracefully shuts down background logging processor and ensures all
queued log entries are written to the log file.

.EXAMPLE
Stop-ConcurrentLogging
#>
function Stop-ConcurrentLogging {
    [CmdletBinding()]
    param()
    
    try {
        if ($script:LoggingProcessor) {
            Write-AgentLog -Message "Stopping concurrent logging processor..." -Level "INFO" -Component "ParallelProcessing"
            
            # Stop background processor
            Stop-Job -Job $script:LoggingProcessor -ErrorAction SilentlyContinue
            Remove-Job -Job $script:LoggingProcessor -Force -ErrorAction SilentlyContinue
            
            # Flush remaining queued entries
            if ($script:LoggingQueue) {
                $remainingCount = Get-ConcurrentQueueCount -Queue $script:LoggingQueue
                Write-AgentLog -Message "Flushing $remainingCount remaining log entries..." -Level "INFO" -Component "ParallelProcessing"
                
                while (-not (Test-ConcurrentQueueEmpty -Queue $script:LoggingQueue)) {
                    $logEntry = Get-ConcurrentQueueItem -Queue $script:LoggingQueue
                    if ($logEntry) {
                        Write-AgentLog -Message $logEntry.Message -Level $logEntry.Level -Component $logEntry.Component
                    }
                }
            }
            
            $script:LoggingEnabled = $false
            Write-AgentLog -Message "Concurrent logging system stopped successfully" -Level "SUCCESS" -Component "ParallelProcessing"
        }
    } catch {
        Write-AgentLog -Message "Error stopping concurrent logging: $($_.Exception.Message)" -Level "ERROR" -Component "ParallelProcessing"
    }
}

#endregion

#region Module Initialization and Export Management

# Initialize module and report successful loading
Write-AgentLog -Message "Unity-Claude-ParallelProcessing module loaded successfully (Synchronized data structures, Status management, Thread-safe operations available)" -Level "SUCCESS" -Component "ParallelProcessing"

# Explicitly export nested module functions for external access
# NestedModules make functions available within module scope but require explicit export
Export-ModuleMember -Function @(
    # Synchronized Data Structures
    'New-SynchronizedHashtable',
    'Get-SynchronizedValue',
    'Set-SynchronizedValue',
    'Remove-SynchronizedValue',
    'Lock-SynchronizedHashtable',
    'Unlock-SynchronizedHashtable',
    
    # Status Management
    'Initialize-ParallelStatusManager',
    'Get-ParallelStatus',
    'Set-ParallelStatus',
    'Update-ParallelStatus',
    'Clear-ParallelStatus',
    
    # Thread-Safe Operations
    'Invoke-ThreadSafeOperation',
    'Test-ThreadSafety',
    'Get-ThreadSafetyStats',
    
    # Concurrent Logging Infrastructure  
    'Initialize-ConcurrentLogging',
    'Write-ConcurrentLog',
    'Stop-ConcurrentLogging',
    
    # AgentLogging Functions (re-exported from NestedModule)
    'Write-AgentLog',
    'Initialize-AgentLogging',
    'Invoke-LogRotation',
    'Remove-OldLogFiles',
    'Get-AgentLogPath',
    'Get-AgentLogStatistics',
    'Clear-AgentLog'
)

#endregion
# SIG # Begin signature block
# MIIFqQYJKoZIhvcNAQcCoIIFmjCCBZYCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUZnYWaoV/9rKozO052ziX2eln
# q8mgggMwMIIDLDCCAhSgAwIBAgIQdR0W2SKoK5VE8JId4ZxrRTANBgkqhkiG9w0B
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
# CQQxFgQUSjN6YY6qQiv2OdAbOIvFLtYrd+YwDQYJKoZIhvcNAQEBBQAEggEAhDAj
# l28xaJJPGlwLuKds/CfrD3qy/LlabOw+L7rkTJ4m2+S0tSErRW0dS/bPTtEXCr2P
# gqWTr0B6pEYTZyKjBYsXxwYOdu2X+LANbVXU0+27Top43tSNbJQjrHb7WEzHjRha
# r1aW7iXWok2t5RTlOV1iL7VfecaXwx3vGmseGfBonez/kYWvXkaiGnDfcECjfStu
# o8ou1MdgbdRvln3Gm7YMOdTHgWJ7AvsC55l4dM29wylu/FGgUK4cwZjoPT0NrPAF
# y6AMcSURSjkV84Ol2lkZmnBCqGGWZE9R/ORo3oJN241Hm1XYSbkMR65/zmVx+Cbh
# 59GS28DJuYxe1cLHjw==
# SIG # End signature block
