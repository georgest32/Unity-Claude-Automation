#Requires -Version 5.1
<#
.SYNOPSIS
    Thread-safe operations for Code Property Graph (CPG) manipulation.

.DESCRIPTION
    Provides thread-safe wrappers for CPG operations using synchronized hashtables
    and reader-writer locks. Ensures concurrent access safety for multi-threaded
    CPG analysis operations.

.NOTES
    Part of Unity-Claude-CPG Enhanced Documentation System
    Week 1, Day 1 Implementation - Thread Safety
    Date: 2025-08-28
#>

# Import required modules
Import-Module "$PSScriptRoot\CPG-DataStructures.psm1" -Force
Import-Module "$PSScriptRoot\..\..\Unity-Claude-ParallelProcessing\Unity-Claude-ParallelProcessing.psm1" -Force -ErrorAction SilentlyContinue

# Module-level thread safety tracking
$script:ThreadSafeOperations = [hashtable]::Synchronized(@{
    TotalOperations = 0
    ReadOperations = 0
    WriteOperations = 0
    LockTimeouts = 0
    Contentions = 0
    LastOperation = $null
    ThreadStats = @{}
})

# Lock timeout configuration (milliseconds)
$script:LockTimeoutMs = 5000
$script:ReadLockTimeoutMs = 1000

#region Logging Functions

function Write-CPGLog {
    [CmdletBinding()]
    param(
        [string]$Message,
        [ValidateSet('DEBUG', 'INFO', 'WARNING', 'ERROR')]
        [string]$Level = 'INFO',
        [string]$ThreadId = [System.Threading.Thread]::CurrentThread.ManagedThreadId
    )
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss.fff"
    $logMessage = "[$timestamp] [TID:$ThreadId] [$Level] [CPG-ThreadSafe] $Message"
    
    switch ($Level) {
        'ERROR'   { Write-Host $logMessage -ForegroundColor Red }
        'WARNING' { Write-Host $logMessage -ForegroundColor Yellow }
        'DEBUG'   { Write-Host $logMessage -ForegroundColor Gray }
        default   { Write-Host $logMessage }
    }
}

#endregion

#region Thread-Safe Graph Wrapper

<#
.SYNOPSIS
    Creates a new thread-safe CPG instance
.DESCRIPTION
    Initializes a thread-safe Code Property Graph with synchronized storage
    and reader-writer lock protection
#>
function New-ThreadSafeCPG {
    [CmdletBinding()]
    param(
        [string]$Name = "ThreadSafeCPG",
        [string]$Description = "Thread-safe Code Property Graph"
    )
    
    Write-CPGLog -Message "Creating new thread-safe CPG: $Name" -Level "INFO"
    
    try {
        $cpg = @{
            Name = $Name
            Description = $Description
            Nodes = [hashtable]::Synchronized(@{})
            Edges = [hashtable]::Synchronized(@{})
            NodesByType = [hashtable]::Synchronized(@{})
            EdgesByType = [hashtable]::Synchronized(@{})
            Lock = [System.Threading.ReaderWriterLockSlim]::new()
            Statistics = [hashtable]::Synchronized(@{
                NodeCount = 0
                EdgeCount = 0
                CreateTime = Get-Date
                LastModified = Get-Date
                ReadOperations = 0
                WriteOperations = 0
            })
        }
        
        Write-CPGLog -Message "Thread-safe CPG created successfully" -Level "DEBUG"
        return [PSCustomObject]$cpg
    }
    catch {
        Write-CPGLog -Message "Failed to create thread-safe CPG: $_" -Level "ERROR"
        throw
    }
}

#endregion

#region Thread-Safe Node Operations

<#
.SYNOPSIS
    Adds a node to the CPG with thread safety
.DESCRIPTION
    Thread-safe node addition with write lock protection
#>
function Add-CPGNodeThreadSafe {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [PSCustomObject]$CPG,
        
        [Parameter(Mandatory)]
        [PSCustomObject]$Node,
        
        [int]$TimeoutMs = $script:LockTimeoutMs
    )
    
    $threadId = [System.Threading.Thread]::CurrentThread.ManagedThreadId
    Write-CPGLog -Message "Adding node: $($Node.Name) (Type: $($Node.Type))" -Level "DEBUG" -ThreadId $threadId
    
    $acquired = $false
    try {
        # Acquire write lock with timeout
        $acquired = $CPG.Lock.TryEnterWriteLock($TimeoutMs)
        if (-not $acquired) {
            $script:ThreadSafeOperations.LockTimeouts++
            throw "Failed to acquire write lock within ${TimeoutMs}ms"
        }
        
        # Check for duplicate
        if ($CPG.Nodes.ContainsKey($Node.Id)) {
            Write-CPGLog -Message "Node already exists: $($Node.Id)" -Level "WARNING" -ThreadId $threadId
            return $false
        }
        
        # Add node to main collection
        $CPG.Nodes[$Node.Id] = $Node
        
        # Index by type
        if (-not $CPG.NodesByType.ContainsKey($Node.Type.ToString())) {
            $CPG.NodesByType[$Node.Type.ToString()] = [hashtable]::Synchronized(@{})
        }
        $CPG.NodesByType[$Node.Type.ToString()][$Node.Id] = $Node
        
        # Update statistics
        $CPG.Statistics.NodeCount++
        $CPG.Statistics.LastModified = Get-Date
        $CPG.Statistics.WriteOperations++
        
        # Update thread tracking
        $script:ThreadSafeOperations.TotalOperations++
        $script:ThreadSafeOperations.WriteOperations++
        $script:ThreadSafeOperations.LastOperation = "AddNode:$($Node.Name)"
        
        if (-not $script:ThreadSafeOperations.ThreadStats.ContainsKey($threadId)) {
            $script:ThreadSafeOperations.ThreadStats[$threadId] = @{ Operations = 0; LastAccess = Get-Date }
        }
        $script:ThreadSafeOperations.ThreadStats[$threadId].Operations++
        $script:ThreadSafeOperations.ThreadStats[$threadId].LastAccess = Get-Date
        
        Write-CPGLog -Message "Node added successfully: $($Node.Name)" -Level "DEBUG" -ThreadId $threadId
        return $true
    }
    catch {
        Write-CPGLog -Message "Error adding node: $_" -Level "ERROR" -ThreadId $threadId
        throw
    }
    finally {
        if ($acquired) {
            $CPG.Lock.ExitWriteLock()
        }
    }
}

<#
.SYNOPSIS
    Retrieves a node from the CPG with thread safety
.DESCRIPTION
    Thread-safe node retrieval with read lock protection
#>
function Get-CPGNodeThreadSafe {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [PSCustomObject]$CPG,
        
        [Parameter(Mandatory)]
        [string]$NodeId,
        
        [int]$TimeoutMs = $script:ReadLockTimeoutMs
    )
    
    $threadId = [System.Threading.Thread]::CurrentThread.ManagedThreadId
    Write-CPGLog -Message "Getting node: $NodeId" -Level "DEBUG" -ThreadId $threadId
    
    $acquired = $false
    try {
        # Acquire read lock with timeout
        $acquired = $CPG.Lock.TryEnterReadLock($TimeoutMs)
        if (-not $acquired) {
            $script:ThreadSafeOperations.LockTimeouts++
            throw "Failed to acquire read lock within ${TimeoutMs}ms"
        }
        
        # Retrieve node
        $node = $null
        if ($CPG.Nodes.ContainsKey($NodeId)) {
            $node = $CPG.Nodes[$NodeId]
        }
        
        # Update statistics
        $CPG.Statistics.ReadOperations++
        $script:ThreadSafeOperations.TotalOperations++
        $script:ThreadSafeOperations.ReadOperations++
        $script:ThreadSafeOperations.LastOperation = "GetNode:$NodeId"
        
        if ($node) {
            Write-CPGLog -Message "Node retrieved: $($node.Name)" -Level "DEBUG" -ThreadId $threadId
        } else {
            Write-CPGLog -Message "Node not found: $NodeId" -Level "DEBUG" -ThreadId $threadId
        }
        
        return $node
    }
    catch {
        Write-CPGLog -Message "Error getting node: $_" -Level "ERROR" -ThreadId $threadId
        throw
    }
    finally {
        if ($acquired) {
            $CPG.Lock.ExitReadLock()
        }
    }
}

<#
.SYNOPSIS
    Updates a node in the CPG with thread safety
.DESCRIPTION
    Thread-safe node update with write lock protection
#>
function Update-CPGNodeThreadSafe {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [PSCustomObject]$CPG,
        
        [Parameter(Mandatory)]
        [string]$NodeId,
        
        [hashtable]$Updates,
        
        [int]$TimeoutMs = $script:LockTimeoutMs
    )
    
    $threadId = [System.Threading.Thread]::CurrentThread.ManagedThreadId
    Write-CPGLog -Message "Updating node: $NodeId" -Level "DEBUG" -ThreadId $threadId
    
    $acquired = $false
    try {
        # Acquire write lock with timeout
        $acquired = $CPG.Lock.TryEnterWriteLock($TimeoutMs)
        if (-not $acquired) {
            $script:ThreadSafeOperations.LockTimeouts++
            throw "Failed to acquire write lock within ${TimeoutMs}ms"
        }
        
        # Check if node exists
        if (-not $CPG.Nodes.ContainsKey($NodeId)) {
            Write-CPGLog -Message "Node not found: $NodeId" -Level "WARNING" -ThreadId $threadId
            return $false
        }
        
        # Update node properties
        $node = $CPG.Nodes[$NodeId]
        foreach ($key in $Updates.Keys) {
            if ($node.PSObject.Properties.Name -contains $key) {
                $oldValue = $node.$key
                $node.$key = $Updates[$key]
                Write-CPGLog -Message "Updated $key from '$oldValue' to '$($Updates[$key])'" -Level "DEBUG" -ThreadId $threadId
            } else {
                Write-CPGLog -Message "Property not found on node: $key" -Level "WARNING" -ThreadId $threadId
            }
        }
        
        # Update modification time
        if ($node.PSObject.Properties.Name -contains 'ModifiedAt') {
            $node.ModifiedAt = Get-Date
        }
        
        # Update statistics
        $CPG.Statistics.LastModified = Get-Date
        $CPG.Statistics.WriteOperations++
        $script:ThreadSafeOperations.TotalOperations++
        $script:ThreadSafeOperations.WriteOperations++
        $script:ThreadSafeOperations.LastOperation = "UpdateNode:$NodeId"
        
        Write-CPGLog -Message "Node updated successfully: $NodeId" -Level "DEBUG" -ThreadId $threadId
        return $true
    }
    catch {
        Write-CPGLog -Message "Error updating node: $_" -Level "ERROR" -ThreadId $threadId
        throw
    }
    finally {
        if ($acquired) {
            $CPG.Lock.ExitWriteLock()
        }
    }
}

<#
.SYNOPSIS
    Removes a node from the CPG with thread safety
.DESCRIPTION
    Thread-safe node removal with write lock protection
#>
function Remove-CPGNodeThreadSafe {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [PSCustomObject]$CPG,
        
        [Parameter(Mandatory)]
        [string]$NodeId,
        
        [switch]$RemoveConnectedEdges,
        
        [int]$TimeoutMs = $script:LockTimeoutMs
    )
    
    $threadId = [System.Threading.Thread]::CurrentThread.ManagedThreadId
    Write-CPGLog -Message "Removing node: $NodeId" -Level "DEBUG" -ThreadId $threadId
    
    $acquired = $false
    try {
        # Acquire write lock with timeout
        $acquired = $CPG.Lock.TryEnterWriteLock($TimeoutMs)
        if (-not $acquired) {
            $script:ThreadSafeOperations.LockTimeouts++
            throw "Failed to acquire write lock within ${TimeoutMs}ms"
        }
        
        # Check if node exists
        if (-not $CPG.Nodes.ContainsKey($NodeId)) {
            Write-CPGLog -Message "Node not found: $NodeId" -Level "WARNING" -ThreadId $threadId
            return $false
        }
        
        $node = $CPG.Nodes[$NodeId]
        
        # Remove connected edges if requested
        if ($RemoveConnectedEdges) {
            $edgesToRemove = @()
            foreach ($edgeId in $CPG.Edges.Keys) {
                $edge = $CPG.Edges[$edgeId]
                if ($edge.SourceId -eq $NodeId -or $edge.TargetId -eq $NodeId) {
                    $edgesToRemove += $edgeId
                }
            }
            
            foreach ($edgeId in $edgesToRemove) {
                $CPG.Edges.Remove($edgeId)
                Write-CPGLog -Message "Removed connected edge: $edgeId" -Level "DEBUG" -ThreadId $threadId
            }
            
            $CPG.Statistics.EdgeCount -= $edgesToRemove.Count
        }
        
        # Remove from type index
        if ($CPG.NodesByType.ContainsKey($node.Type.ToString())) {
            $CPG.NodesByType[$node.Type.ToString()].Remove($NodeId)
        }
        
        # Remove node
        $CPG.Nodes.Remove($NodeId)
        
        # Update statistics
        $CPG.Statistics.NodeCount--
        $CPG.Statistics.LastModified = Get-Date
        $CPG.Statistics.WriteOperations++
        $script:ThreadSafeOperations.TotalOperations++
        $script:ThreadSafeOperations.WriteOperations++
        $script:ThreadSafeOperations.LastOperation = "RemoveNode:$NodeId"
        
        Write-CPGLog -Message "Node removed successfully: $NodeId" -Level "DEBUG" -ThreadId $threadId
        return $true
    }
    catch {
        Write-CPGLog -Message "Error removing node: $_" -Level "ERROR" -ThreadId $threadId
        throw
    }
    finally {
        if ($acquired) {
            $CPG.Lock.ExitWriteLock()
        }
    }
}

#endregion

#region Thread-Safe Edge Operations

<#
.SYNOPSIS
    Adds an edge to the CPG with thread safety
.DESCRIPTION
    Thread-safe edge addition with write lock protection
#>
function Add-CPGEdgeThreadSafe {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [PSCustomObject]$CPG,
        
        [Parameter(Mandatory)]
        [PSCustomObject]$Edge,
        
        [int]$TimeoutMs = $script:LockTimeoutMs
    )
    
    $threadId = [System.Threading.Thread]::CurrentThread.ManagedThreadId
    Write-CPGLog -Message "Adding edge: $($Edge.Id) (Type: $($Edge.Type))" -Level "DEBUG" -ThreadId $threadId
    
    $acquired = $false
    try {
        # Acquire write lock with timeout
        $acquired = $CPG.Lock.TryEnterWriteLock($TimeoutMs)
        if (-not $acquired) {
            $script:ThreadSafeOperations.LockTimeouts++
            throw "Failed to acquire write lock within ${TimeoutMs}ms"
        }
        
        # Validate source and target nodes exist
        if (-not $CPG.Nodes.ContainsKey($Edge.SourceId)) {
            throw "Source node not found: $($Edge.SourceId)"
        }
        if (-not $CPG.Nodes.ContainsKey($Edge.TargetId)) {
            throw "Target node not found: $($Edge.TargetId)"
        }
        
        # Check for duplicate
        if ($CPG.Edges.ContainsKey($Edge.Id)) {
            Write-CPGLog -Message "Edge already exists: $($Edge.Id)" -Level "WARNING" -ThreadId $threadId
            return $false
        }
        
        # Add edge to main collection
        $CPG.Edges[$Edge.Id] = $Edge
        
        # Index by type
        if (-not $CPG.EdgesByType.ContainsKey($Edge.Type.ToString())) {
            $CPG.EdgesByType[$Edge.Type.ToString()] = [hashtable]::Synchronized(@{})
        }
        $CPG.EdgesByType[$Edge.Type.ToString()][$Edge.Id] = $Edge
        
        # Update statistics
        $CPG.Statistics.EdgeCount++
        $CPG.Statistics.LastModified = Get-Date
        $CPG.Statistics.WriteOperations++
        $script:ThreadSafeOperations.TotalOperations++
        $script:ThreadSafeOperations.WriteOperations++
        $script:ThreadSafeOperations.LastOperation = "AddEdge:$($Edge.Id)"
        
        Write-CPGLog -Message "Edge added successfully: $($Edge.Id)" -Level "DEBUG" -ThreadId $threadId
        return $true
    }
    catch {
        Write-CPGLog -Message "Error adding edge: $_" -Level "ERROR" -ThreadId $threadId
        throw
    }
    finally {
        if ($acquired) {
            $CPG.Lock.ExitWriteLock()
        }
    }
}

<#
.SYNOPSIS
    Removes an edge from the CPG with thread safety
.DESCRIPTION
    Thread-safe edge removal with write lock protection
#>
function Remove-CPGEdgeThreadSafe {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [PSCustomObject]$CPG,
        
        [Parameter(Mandatory)]
        [string]$EdgeId,
        
        [int]$TimeoutMs = $script:LockTimeoutMs
    )
    
    $threadId = [System.Threading.Thread]::CurrentThread.ManagedThreadId
    Write-CPGLog -Message "Removing edge: $EdgeId" -Level "DEBUG" -ThreadId $threadId
    
    $acquired = $false
    try {
        # Acquire write lock with timeout
        $acquired = $CPG.Lock.TryEnterWriteLock($TimeoutMs)
        if (-not $acquired) {
            $script:ThreadSafeOperations.LockTimeouts++
            throw "Failed to acquire write lock within ${TimeoutMs}ms"
        }
        
        # Check if edge exists
        if (-not $CPG.Edges.ContainsKey($EdgeId)) {
            Write-CPGLog -Message "Edge not found: $EdgeId" -Level "WARNING" -ThreadId $threadId
            return $false
        }
        
        $edge = $CPG.Edges[$EdgeId]
        
        # Remove from type index
        if ($CPG.EdgesByType.ContainsKey($edge.Type.ToString())) {
            $CPG.EdgesByType[$edge.Type.ToString()].Remove($EdgeId)
        }
        
        # Remove edge
        $CPG.Edges.Remove($EdgeId)
        
        # Update statistics
        $CPG.Statistics.EdgeCount--
        $CPG.Statistics.LastModified = Get-Date
        $CPG.Statistics.WriteOperations++
        $script:ThreadSafeOperations.TotalOperations++
        $script:ThreadSafeOperations.WriteOperations++
        $script:ThreadSafeOperations.LastOperation = "RemoveEdge:$EdgeId"
        
        Write-CPGLog -Message "Edge removed successfully: $EdgeId" -Level "DEBUG" -ThreadId $threadId
        return $true
    }
    catch {
        Write-CPGLog -Message "Error removing edge: $_" -Level "ERROR" -ThreadId $threadId
        throw
    }
    finally {
        if ($acquired) {
            $CPG.Lock.ExitWriteLock()
        }
    }
}

#endregion

#region Concurrent Access Controls

<#
.SYNOPSIS
    Executes a read operation with proper locking
.DESCRIPTION
    Wraps any read operation in appropriate read lock
#>
function Invoke-CPGReadOperation {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [PSCustomObject]$CPG,
        
        [Parameter(Mandatory)]
        [scriptblock]$Operation,
        
        [int]$TimeoutMs = $script:ReadLockTimeoutMs
    )
    
    $threadId = [System.Threading.Thread]::CurrentThread.ManagedThreadId
    $acquired = $false
    
    try {
        # Acquire read lock
        $acquired = $CPG.Lock.TryEnterReadLock($TimeoutMs)
        if (-not $acquired) {
            $script:ThreadSafeOperations.LockTimeouts++
            throw "Failed to acquire read lock within ${TimeoutMs}ms"
        }
        
        # Execute operation
        $result = & $Operation
        
        # Update statistics
        $CPG.Statistics.ReadOperations++
        $script:ThreadSafeOperations.ReadOperations++
        
        return $result
    }
    catch {
        Write-CPGLog -Message "Error in read operation: $_" -Level "ERROR" -ThreadId $threadId
        throw
    }
    finally {
        if ($acquired) {
            $CPG.Lock.ExitReadLock()
        }
    }
}

<#
.SYNOPSIS
    Executes a write operation with proper locking
.DESCRIPTION
    Wraps any write operation in appropriate write lock
#>
function Invoke-CPGWriteOperation {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [PSCustomObject]$CPG,
        
        [Parameter(Mandatory)]
        [scriptblock]$Operation,
        
        [int]$TimeoutMs = $script:LockTimeoutMs
    )
    
    $threadId = [System.Threading.Thread]::CurrentThread.ManagedThreadId
    $acquired = $false
    
    try {
        # Acquire write lock
        $acquired = $CPG.Lock.TryEnterWriteLock($TimeoutMs)
        if (-not $acquired) {
            $script:ThreadSafeOperations.LockTimeouts++
            throw "Failed to acquire write lock within ${TimeoutMs}ms"
        }
        
        # Execute operation
        $result = & $Operation
        
        # Update statistics
        $CPG.Statistics.WriteOperations++
        $CPG.Statistics.LastModified = Get-Date
        $script:ThreadSafeOperations.WriteOperations++
        
        return $result
    }
    catch {
        Write-CPGLog -Message "Error in write operation: $_" -Level "ERROR" -ThreadId $threadId
        throw
    }
    finally {
        if ($acquired) {
            $CPG.Lock.ExitWriteLock()
        }
    }
}

#endregion

#region Thread Safety Statistics

<#
.SYNOPSIS
    Gets thread safety statistics
.DESCRIPTION
    Returns statistics about thread-safe operations
#>
function Get-CPGThreadStatistics {
    [CmdletBinding()]
    param(
        [PSCustomObject]$CPG
    )
    
    $stats = @{
        GlobalStatistics = $script:ThreadSafeOperations.Clone()
    }
    
    if ($CPG) {
        $stats.CPGStatistics = @{
            NodeCount = $CPG.Statistics.NodeCount
            EdgeCount = $CPG.Statistics.EdgeCount
            ReadOperations = $CPG.Statistics.ReadOperations
            WriteOperations = $CPG.Statistics.WriteOperations
            CreateTime = $CPG.Statistics.CreateTime
            LastModified = $CPG.Statistics.LastModified
        }
    }
    
    return [PSCustomObject]$stats
}

<#
.SYNOPSIS
    Tests concurrent access safety
.DESCRIPTION
    Runs concurrent operations to verify thread safety
#>
function Test-CPGThreadSafety {
    [CmdletBinding()]
    param(
        [int]$ThreadCount = 10,
        [int]$OperationsPerThread = 100
    )
    
    Write-CPGLog -Message "Starting thread safety test with $ThreadCount threads" -Level "INFO"
    
    # Create test CPG
    $cpg = New-ThreadSafeCPG -Name "TestCPG"
    
    # Create runspace pool
    $runspacePool = [runspacefactory]::CreateRunspacePool(1, $ThreadCount)
    $runspacePool.Open()
    
    $jobs = @()
    
    # Create test jobs
    for ($i = 0; $i -lt $ThreadCount; $i++) {
        $powershell = [powershell]::Create()
        $powershell.RunspacePool = $runspacePool
        
        $script = {
            param($CPG, $ThreadId, $Operations)
            
            $results = @{
                ThreadId = $ThreadId
                Success = 0
                Errors = 0
            }
            
            for ($j = 0; $j -lt $Operations; $j++) {
                try {
                    # Random operation
                    $operation = Get-Random -Minimum 0 -Maximum 3
                    
                    switch ($operation) {
                        0 { 
                            # Add node
                            $node = [PSCustomObject]@{
                                Id = [guid]::NewGuid().ToString()
                                Name = "TestNode_${ThreadId}_${j}"
                                Type = 'Function'
                            }
                            Add-CPGNodeThreadSafe -CPG $CPG -Node $node
                        }
                        1 {
                            # Get node
                            $nodes = $CPG.Nodes.Keys | Get-Random -Count 1
                            if ($nodes) {
                                Get-CPGNodeThreadSafe -CPG $CPG -NodeId $nodes
                            }
                        }
                        2 {
                            # Update node
                            $nodes = $CPG.Nodes.Keys | Get-Random -Count 1
                            if ($nodes) {
                                Update-CPGNodeThreadSafe -CPG $CPG -NodeId $nodes -Updates @{
                                    ModifiedAt = Get-Date
                                }
                            }
                        }
                    }
                    $results.Success++
                }
                catch {
                    $results.Errors++
                }
            }
            
            return $results
        }
        
        $null = $powershell.AddScript($script)
        $null = $powershell.AddParameter('CPG', $cpg)
        $null = $powershell.AddParameter('ThreadId', $i)
        $null = $powershell.AddParameter('Operations', $OperationsPerThread)
        
        $jobs += @{
            PowerShell = $powershell
            Handle = $powershell.BeginInvoke()
        }
    }
    
    # Wait for completion
    Write-CPGLog -Message "Waiting for all threads to complete..." -Level "INFO"
    
    $results = @()
    foreach ($job in $jobs) {
        $result = $job.PowerShell.EndInvoke($job.Handle)
        $results += $result
        $job.PowerShell.Dispose()
    }
    
    $runspacePool.Close()
    $runspacePool.Dispose()
    
    # Aggregate results
    $totalSuccess = ($results | Measure-Object -Property Success -Sum).Sum
    $totalErrors = ($results | Measure-Object -Property Errors -Sum).Sum
    
    Write-CPGLog -Message "Thread safety test complete" -Level "INFO"
    Write-CPGLog -Message "Total operations: $($totalSuccess + $totalErrors)" -Level "INFO"
    Write-CPGLog -Message "Successful: $totalSuccess" -Level "INFO"
    Write-CPGLog -Message "Errors: $totalErrors" -Level "INFO"
    Write-CPGLog -Message "CPG final state - Nodes: $($cpg.Statistics.NodeCount), Edges: $($cpg.Statistics.EdgeCount)" -Level "INFO"
    
    return @{
        Success = $totalSuccess
        Errors = $totalErrors
        CPG = $cpg
        ThreadResults = $results
    }
}

#endregion

# Export functions
Export-ModuleMember -Function @(
    'New-ThreadSafeCPG',
    'Add-CPGNodeThreadSafe',
    'Get-CPGNodeThreadSafe',
    'Update-CPGNodeThreadSafe',
    'Remove-CPGNodeThreadSafe',
    'Add-CPGEdgeThreadSafe',
    'Remove-CPGEdgeThreadSafe',
    'Invoke-CPGReadOperation',
    'Invoke-CPGWriteOperation',
    'Get-CPGThreadStatistics',
    'Test-CPGThreadSafety',
    'Write-CPGLog'
)