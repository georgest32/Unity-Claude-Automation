# Unity-Claude-ConcurrentCollections.psm1
# Thread-safe collection wrappers for parallel processing
# Clean modular loader based on Unity-Claude-SystemStatus pattern
# Date: 2025-08-20

$script:ModuleRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$ErrorActionPreference = "Stop"

# Load all function files (when we split functions into separate .ps1 files)
# For now, all functions are in this single file

#region ConcurrentQueue Wrapper Functions

function New-ConcurrentQueue {
    <#
    .SYNOPSIS
    Creates a new thread-safe FIFO queue for Unity-Claude processing
    
    .DESCRIPTION
    Creates a ConcurrentQueue[object] instance optimized for producer-consumer scenarios
    in the Unity-Claude automation system. Supports high-throughput enqueueing and
    thread-safe dequeueing operations.
    
    .PARAMETER InitialCapacity
    Optional hint for initial capacity (performance optimization)
    
    .EXAMPLE
    $errorQueue = New-ConcurrentQueue
    Add-ConcurrentQueueItem -Queue $errorQueue -Item $unityError
    
    .EXAMPLE
    $responseQueue = New-ConcurrentQueue -InitialCapacity 100
    #>
    [CmdletBinding()]
    param(
        [int]$InitialCapacity = 16
    )
    
    # ConcurrentQueue is part of mscorlib.dll - no assembly loading required
    # Use New-Object syntax for maximum PowerShell 5.1 compatibility
    # Research shows ::new() can hang in some PowerShell 5.1 environments
    $queue = New-Object 'System.Collections.Concurrent.ConcurrentQueue[object]'
    
    # Validate queue creation succeeded
    if ($null -eq $queue) {
        throw "ConcurrentQueue creation returned null - possible .NET Framework incompatibility"
    }
    
    # PowerShell 5.1 serialization workaround - create wrapper object
    # ConcurrentQueue displays as empty string due to serialization issues
    $wrapper = New-Object PSObject -Property @{
        InternalQueue = $queue
        Type = "ConcurrentQueue"
        Created = Get-Date
    }
    
    # Add methods to wrapper for transparent usage
    $wrapper | Add-Member -MemberType ScriptMethod -Name "Enqueue" -Value {
        param($item)
        $this.InternalQueue.Enqueue($item)
    }
    
    $wrapper | Add-Member -MemberType ScriptMethod -Name "TryDequeue" -Value {
        param([ref]$result)
        return $this.InternalQueue.TryDequeue($result)
    }
    
    $wrapper | Add-Member -MemberType ScriptProperty -Name "Count" -Value {
        return $this.InternalQueue.Count
    }
    
    $wrapper | Add-Member -MemberType ScriptProperty -Name "IsEmpty" -Value {
        return $this.InternalQueue.IsEmpty
    }
    
    # Return wrapper object that serializes properly
    $wrapper
}

function Add-ConcurrentQueueItem {
    <#
    .SYNOPSIS
    Thread-safely adds an item to a ConcurrentQueue
    
    .DESCRIPTION
    Enqueues an item to the specified ConcurrentQueue in a thread-safe manner.
    This operation is lock-free and optimized for high-throughput scenarios.
    
    .PARAMETER Queue
    The ConcurrentQueue instance to add the item to
    
    .PARAMETER Item
    The object to enqueue (Unity errors, Claude responses, processing tasks)
    
    .EXAMPLE
    Add-ConcurrentQueueItem -Queue $errorQueue -Item @{
        Error = "CS0120: An object reference is required"
        File = "PlayerController.cs"
        Line = 42
        Timestamp = Get-Date
    }
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [object]$Queue,
        
        [Parameter(Mandatory)]
        [object]$Item
    )
    
    try {
        # Use wrapper object's InternalQueue property
        if ($Queue.InternalQueue) {
            $Queue.InternalQueue.Enqueue($Item)
            Write-Verbose "[ConcurrentQueue] Enqueued item. Queue count: $($Queue.InternalQueue.Count)"
        } else {
            throw "Queue parameter does not contain InternalQueue property. Expected wrapper object from New-ConcurrentQueue."
        }
        return $true
    } catch {
        $null = Write-Error "[ConcurrentQueue] Failed to enqueue item: $($_.Exception.Message)" -ErrorAction Continue
        return $false
    }
}

function Get-ConcurrentQueueItem {
    <#
    .SYNOPSIS
    Thread-safely retrieves and removes an item from a ConcurrentQueue
    
    .DESCRIPTION
    Attempts to dequeue an item from the specified ConcurrentQueue using TryDequeue pattern.
    Returns $null if queue is empty. This operation is thread-safe and lock-free.
    
    .PARAMETER Queue
    The ConcurrentQueue instance to retrieve from
    
    .PARAMETER TimeoutMs
    Optional timeout in milliseconds for retry attempts
    
    .EXAMPLE
    $nextError = Get-ConcurrentQueueItem -Queue $errorQueue
    if ($nextError) {
        Process-UnityError -Error $nextError
    }
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [object]$Queue,
        
        [int]$TimeoutMs = 0
    )
    
    $item = $null
    $result = $false
    
    try {
        # Use wrapper object's InternalQueue property
        if (-not $Queue.InternalQueue) {
            throw "Queue parameter does not contain InternalQueue property. Expected wrapper object from New-ConcurrentQueue."
        }
        
        if ($TimeoutMs -gt 0) {
            # Retry pattern for timeout scenarios
            $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
            while ($stopwatch.ElapsedMilliseconds -lt $TimeoutMs) {
                $result = $Queue.InternalQueue.TryDequeue([ref]$item)
                if ($result) { break }
                Start-Sleep -Milliseconds 10
            }
            $stopwatch.Stop()
        } else {
            # Single attempt
            $result = $Queue.InternalQueue.TryDequeue([ref]$item)
        }
        
        if ($result) {
            Write-Verbose "[ConcurrentQueue] Dequeued item. Remaining count: $($Queue.InternalQueue.Count)"
            return $item
        } else {
            Write-Verbose "[ConcurrentQueue] Queue empty or timeout reached"
            return $null
        }
    } catch {
        $null = Write-Error "[ConcurrentQueue] Failed to dequeue item: $($_.Exception.Message)" -ErrorAction Continue
        return $null
    }
}

function Test-ConcurrentQueueEmpty {
    <#
    .SYNOPSIS
    Thread-safely checks if a ConcurrentQueue is empty
    
    .DESCRIPTION
    Returns $true if the queue is empty, $false otherwise.
    This is a snapshot in time - queue state may change immediately after check.
    
    .PARAMETER Queue
    The ConcurrentQueue instance to check
    
    .EXAMPLE
    if (-not (Test-ConcurrentQueueEmpty -Queue $errorQueue)) {
        $error = Get-ConcurrentQueueItem -Queue $errorQueue
    }
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [object]$Queue
    )
    
    # Use wrapper object's InternalQueue property
    if ($Queue.InternalQueue) {
        return $Queue.InternalQueue.IsEmpty
    } else {
        throw "Queue parameter does not contain InternalQueue property. Expected wrapper object from New-ConcurrentQueue."
    }
}

function Get-ConcurrentQueueCount {
    <#
    .SYNOPSIS
    Gets the current count of items in a ConcurrentQueue
    
    .DESCRIPTION
    Returns the approximate number of items in the queue. This is a snapshot
    value and may change immediately after the call in multi-threaded scenarios.
    
    .PARAMETER Queue
    The ConcurrentQueue instance to count
    
    .EXAMPLE
    $pendingErrors = Get-ConcurrentQueueCount -Queue $errorQueue
    Write-Host "Processing queue: $pendingErrors items remaining"
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [object]$Queue
    )
    
    # Use wrapper object's InternalQueue property
    if ($Queue.InternalQueue) {
        return $Queue.InternalQueue.Count
    } else {
        throw "Queue parameter does not contain InternalQueue property. Expected wrapper object from New-ConcurrentQueue."
    }
}

#endregion

#region ConcurrentBag Wrapper Functions

function New-ConcurrentBag {
    <#
    .SYNOPSIS
    Creates a new thread-safe unordered collection for Unity-Claude processing
    
    .DESCRIPTION
    Creates a ConcurrentBag[object] instance optimized for scenarios where order
    doesn't matter but thread-safe adding and retrieving is required. Better
    performance than ConcurrentQueue when order is not important.
    
    .EXAMPLE
    $responsesBag = New-ConcurrentBag
    Add-ConcurrentBagItem -Bag $responsesBag -Item $claudeResponse
    #>
    [CmdletBinding()]
    param()
    
    # ConcurrentBag is part of mscorlib.dll - no assembly loading required
    # Use New-Object syntax for maximum PowerShell 5.1 compatibility
    # Research shows ::new() can hang in some PowerShell 5.1 environments
    $bag = New-Object 'System.Collections.Concurrent.ConcurrentBag[object]'
    
    # Validate bag creation succeeded
    if ($null -eq $bag) {
        throw "ConcurrentBag creation returned null - possible .NET Framework incompatibility"
    }
    
    # PowerShell 5.1 serialization workaround - create wrapper object
    # ConcurrentBag displays as empty string due to serialization issues
    $wrapper = New-Object PSObject -Property @{
        InternalBag = $bag
        Type = "ConcurrentBag"
        Created = Get-Date
    }
    
    # Add methods to wrapper for transparent usage
    $wrapper | Add-Member -MemberType ScriptMethod -Name "Add" -Value {
        param($item)
        $this.InternalBag.Add($item)
    }
    
    $wrapper | Add-Member -MemberType ScriptMethod -Name "TryTake" -Value {
        param([ref]$result)
        return $this.InternalBag.TryTake($result)
    }
    
    $wrapper | Add-Member -MemberType ScriptMethod -Name "ToArray" -Value {
        return $this.InternalBag.ToArray()
    }
    
    $wrapper | Add-Member -MemberType ScriptProperty -Name "Count" -Value {
        return $this.InternalBag.Count
    }
    
    $wrapper | Add-Member -MemberType ScriptProperty -Name "IsEmpty" -Value {
        return $this.InternalBag.IsEmpty
    }
    
    # Return wrapper object that serializes properly
    $wrapper
}

function Add-ConcurrentBagItem {
    <#
    .SYNOPSIS
    Thread-safely adds an item to a ConcurrentBag
    
    .DESCRIPTION
    Adds an item to the specified ConcurrentBag in a thread-safe manner.
    Order is not preserved but performance is optimized for high-throughput scenarios.
    
    .PARAMETER Bag
    The ConcurrentBag instance to add the item to
    
    .PARAMETER Item
    The object to add (Unity compilation results, Claude responses, metrics data)
    
    .EXAMPLE
    Add-ConcurrentBagItem -Bag $resultsBag -Item @{
        Success = $true
        Duration = "00:00:02.157"
        Output = "Compilation successful"
        Timestamp = Get-Date
    }
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [object]$Bag,
        
        [Parameter(Mandatory)]
        [object]$Item
    )
    
    try {
        # Use wrapper object's InternalBag property
        if ($Bag.InternalBag) {
            $Bag.InternalBag.Add($Item)
            Write-Verbose "[ConcurrentBag] Added item. Bag count: $($Bag.InternalBag.Count)"
        } else {
            throw "Bag parameter does not contain InternalBag property. Expected wrapper object from New-ConcurrentBag."
        }
        return $true
    } catch {
        $null = Write-Error "[ConcurrentBag] Failed to add item: $($_.Exception.Message)" -ErrorAction Continue
        return $false
    }
}

function Get-ConcurrentBagItem {
    <#
    .SYNOPSIS
    Thread-safely retrieves and removes an item from a ConcurrentBag
    
    .DESCRIPTION
    Attempts to take an item from the specified ConcurrentBag using TryTake pattern.
    Returns $null if bag is empty. Order is not guaranteed.
    
    .PARAMETER Bag
    The ConcurrentBag instance to retrieve from
    
    .PARAMETER TimeoutMs
    Optional timeout in milliseconds for retry attempts
    
    .EXAMPLE
    $result = Get-ConcurrentBagItem -Bag $resultsBag
    if ($result) {
        Process-CompilationResult -Result $result
    }
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [object]$Bag,
        
        [int]$TimeoutMs = 0
    )
    
    $item = $null
    $result = $false
    
    try {
        # Use wrapper object's InternalBag property
        if (-not $Bag.InternalBag) {
            throw "Bag parameter does not contain InternalBag property. Expected wrapper object from New-ConcurrentBag."
        }
        
        if ($TimeoutMs -gt 0) {
            # Retry pattern for timeout scenarios
            $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
            while ($stopwatch.ElapsedMilliseconds -lt $TimeoutMs) {
                $result = $Bag.InternalBag.TryTake([ref]$item)
                if ($result) { break }
                Start-Sleep -Milliseconds 10
            }
            $stopwatch.Stop()
        } else {
            # Single attempt
            $result = $Bag.InternalBag.TryTake([ref]$item)
        }
        
        if ($result) {
            Write-Verbose "[ConcurrentBag] Retrieved item. Remaining count: $($Bag.InternalBag.Count)"
            return $item
        } else {
            Write-Verbose "[ConcurrentBag] Bag empty or timeout reached"
            return $null
        }
    } catch {
        $null = Write-Error "[ConcurrentBag] Failed to retrieve item: $($_.Exception.Message)" -ErrorAction Continue
        return $null
    }
}

function Test-ConcurrentBagEmpty {
    <#
    .SYNOPSIS
    Thread-safely checks if a ConcurrentBag is empty
    
    .DESCRIPTION
    Returns $true if the bag is empty, $false otherwise.
    This is a snapshot in time - bag state may change immediately after check.
    
    .PARAMETER Bag
    The ConcurrentBag instance to check
    
    .EXAMPLE
    if (-not (Test-ConcurrentBagEmpty -Bag $resultsBag)) {
        $result = Get-ConcurrentBagItem -Bag $resultsBag
    }
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [object]$Bag
    )
    
    # Use wrapper object's InternalBag property
    if ($Bag.InternalBag) {
        return $Bag.InternalBag.IsEmpty
    } else {
        throw "Bag parameter does not contain InternalBag property. Expected wrapper object from New-ConcurrentBag."
    }
}

function Get-ConcurrentBagCount {
    <#
    .SYNOPSIS
    Gets the current count of items in a ConcurrentBag
    
    .DESCRIPTION
    Returns the approximate number of items in the bag. This is a snapshot
    value and may change immediately after the call in multi-threaded scenarios.
    
    .PARAMETER Bag
    The ConcurrentBag instance to count
    
    .EXAMPLE
    $pendingResults = Get-ConcurrentBagCount -Bag $resultsBag
    Write-Host "Processing results: $pendingResults items remaining"
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [object]$Bag
    )
    
    # Use wrapper object's InternalBag property
    if ($Bag.InternalBag) {
        return $Bag.InternalBag.Count
    } else {
        throw "Bag parameter does not contain InternalBag property. Expected wrapper object from New-ConcurrentBag."
    }
}

function Get-ConcurrentBagItems {
    <#
    .SYNOPSIS
    Thread-safely copies all items from a ConcurrentBag to an array
    
    .DESCRIPTION
    Creates a snapshot array of all items in the bag without removing them.
    Useful for inspection and batch processing scenarios.
    
    .PARAMETER Bag
    The ConcurrentBag instance to copy from
    
    .EXAMPLE
    $allResults = Get-ConcurrentBagItems -Bag $resultsBag
    foreach ($result in $allResults) {
        Write-Host "Result: $($result.Output)"
    }
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [object]$Bag
    )
    
    try {
        # Use wrapper object's ToArray method (delegates to InternalBag)
        $items = $Bag.ToArray()
        Write-Verbose "[ConcurrentBag] Copied $($items.Length) items to array"
        return $items
    } catch {
        $null = Write-Error "[ConcurrentBag] Failed to copy items: $($_.Exception.Message)" -ErrorAction Continue
        return @()
    }
}

#endregion

#region Producer-Consumer Pattern Helpers

function Start-ProducerConsumerQueue {
    <#
    .SYNOPSIS
    Creates a producer-consumer queue system for Unity-Claude parallel processing
    
    .DESCRIPTION
    Sets up a complete producer-consumer pattern with:
    - ConcurrentQueue for work items
    - CancellationToken for graceful shutdown
    - Performance metrics tracking
    - Error handling and logging
    
    .PARAMETER QueueName
    Name identifier for the queue (for logging and metrics)
    
    .PARAMETER MaxConsumers
    Maximum number of consumer threads to create
    
    .EXAMPLE
    $system = Start-ProducerConsumerQueue -QueueName "UnityErrors" -MaxConsumers 3
    Add-ConcurrentQueueItem -Queue $system.Queue -Item $error
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$QueueName,
        
        [int]$MaxConsumers = 2
    )
    
    try {
        $system = [PSCustomObject]@{
            QueueName = $QueueName
            Queue = New-ConcurrentQueue
            CancellationToken = New-Object System.Threading.CancellationTokenSource
            MaxConsumers = $MaxConsumers
            ActiveConsumers = 0
            TotalProcessed = 0
            TotalErrors = 0
            StartTime = Get-Date
            LastActivity = Get-Date
        }
        
        Write-Verbose "[ProducerConsumer] Created system '$QueueName' with $MaxConsumers max consumers"
        return $system
    } catch {
        Write-Error "[ProducerConsumer] Failed to create system '$QueueName': $($_.Exception.Message)"
        throw
    }
}

function Stop-ProducerConsumerQueue {
    <#
    .SYNOPSIS
    Gracefully stops a producer-consumer queue system
    
    .DESCRIPTION
    Signals cancellation and waits for consumers to finish processing.
    Provides graceful shutdown with timeout protection.
    
    .PARAMETER System
    The producer-consumer system returned by Start-ProducerConsumerQueue
    
    .PARAMETER TimeoutSeconds
    Maximum time to wait for graceful shutdown
    
    .EXAMPLE
    Stop-ProducerConsumerQueue -System $errorProcessingSystem -TimeoutSeconds 30
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [PSCustomObject]$System,
        
        [int]$TimeoutSeconds = 10
    )
    
    try {
        Write-Verbose "[ProducerConsumer] Stopping system '$($System.QueueName)'..."
        
        # Signal cancellation
        $System.CancellationToken.Cancel()
        
        # Wait for graceful shutdown
        $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
        while ($System.ActiveConsumers -gt 0 -and $stopwatch.ElapsedMilliseconds -lt ($TimeoutSeconds * 1000)) {
            Start-Sleep -Milliseconds 100
        }
        $stopwatch.Stop()
        
        # Dispose resources
        $System.CancellationToken.Dispose()
        
        $duration = (Get-Date) - $System.StartTime
        Write-Verbose "[ProducerConsumer] System '$($System.QueueName)' stopped. Total processed: $($System.TotalProcessed), Duration: $($duration.TotalSeconds)s"
        
        return $true
    } catch {
        Write-Error "[ProducerConsumer] Failed to stop system '$($System.QueueName)': $($_.Exception.Message)"
        return $false
    }
}

#endregion

#region Performance Monitoring

function Get-ConcurrentCollectionMetrics {
    <#
    .SYNOPSIS
    Gets performance metrics for concurrent collections
    
    .DESCRIPTION
    Provides detailed metrics about queue/bag performance including:
    - Current item counts
    - Throughput estimates
    - Memory usage approximation
    
    .PARAMETER Collections
    Hashtable of named collections to analyze
    
    .EXAMPLE
    $metrics = Get-ConcurrentCollectionMetrics -Collections @{
        ErrorQueue = $errorQueue
        ResponseBag = $responseBag
    }
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [hashtable]$Collections
    )
    
    $metrics = @{
        Timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss.fff'
        Collections = @{}
        TotalItems = 0
        EstimatedMemoryKB = 0
    }
    
    foreach ($name in $Collections.Keys) {
        $collection = $Collections[$name]
        $count = 0
        $type = "Unknown"
        
        try {
            # Handle wrapper objects from New-ConcurrentQueue/New-ConcurrentBag
            if ($collection.Type -eq "ConcurrentQueue" -and $collection.InternalQueue) {
                $count = $collection.InternalQueue.Count
                $type = "ConcurrentQueue"
                $isEmpty = $collection.InternalQueue.IsEmpty
            } elseif ($collection.Type -eq "ConcurrentBag" -and $collection.InternalBag) {
                $count = $collection.InternalBag.Count
                $type = "ConcurrentBag"
                $isEmpty = $collection.InternalBag.IsEmpty
            } elseif ($collection -is [System.Collections.Concurrent.ConcurrentQueue[object]]) {
                # Handle raw ConcurrentQueue objects (legacy support)
                $count = $collection.Count
                $type = "ConcurrentQueue"
                $isEmpty = $collection.IsEmpty
            } elseif ($collection -is [System.Collections.Concurrent.ConcurrentBag[object]]) {
                # Handle raw ConcurrentBag objects (legacy support)
                $count = $collection.Count
                $type = "ConcurrentBag"
                $isEmpty = $collection.IsEmpty
            } else {
                $count = 0
                $type = "Unknown"
                $isEmpty = $true
            }
            
            $metrics.Collections[$name] = @{
                Type = $type
                Count = $count
                IsEmpty = $isEmpty
                EstimatedMemoryKB = [math]::Round($count * 0.5, 2) # Rough estimate
            }
            
            $metrics.TotalItems += $count
            $metrics.EstimatedMemoryKB += $metrics.Collections[$name].EstimatedMemoryKB
            
        } catch {
            Write-Warning "[Metrics] Failed to analyze collection '$name': $($_.Exception.Message)"
            $metrics.Collections[$name] = @{
                Type = "Error"
                Count = 0
                IsEmpty = $true
                EstimatedMemoryKB = 0
                Error = $_.Exception.Message
            }
        }
    }
    
    Write-Verbose "[Metrics] Analyzed $($Collections.Count) collections, $($metrics.TotalItems) total items"
    return $metrics
}

#endregion

# Export all functions
Export-ModuleMember -Function @(
    # ConcurrentQueue functions
    'New-ConcurrentQueue',
    'Add-ConcurrentQueueItem',
    'Get-ConcurrentQueueItem', 
    'Test-ConcurrentQueueEmpty',
    'Get-ConcurrentQueueCount',
    
    # ConcurrentBag functions
    'New-ConcurrentBag',
    'Add-ConcurrentBagItem',
    'Get-ConcurrentBagItem',
    'Test-ConcurrentBagEmpty', 
    'Get-ConcurrentBagCount',
    'Get-ConcurrentBagItems',
    
    # Producer-Consumer pattern helpers
    'Start-ProducerConsumerQueue',
    'Stop-ProducerConsumerQueue',
    
    # Performance monitoring
    'Get-ConcurrentCollectionMetrics'
)
# SIG # Begin signature block
# MIIFqQYJKoZIhvcNAQcCoIIFmjCCBZYCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUMycTkSh2kwxPcPL8wwTHFZnR
# 0OmgggMwMIIDLDCCAhSgAwIBAgIQdR0W2SKoK5VE8JId4ZxrRTANBgkqhkiG9w0B
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
# CQQxFgQU1hY4eSANhGgL1B7ddGRZ6U8C820wDQYJKoZIhvcNAQEBBQAEggEAqoDE
# yzNIp7YWwOkJqe0ddcU0h2eC42eioF3qPlc0STJBXaeTfzj0my3rxZWsw0Xz9ioZ
# o+WjyBvbNvskb6AhBrQ3M6eA5O5P0NWiY0boq/tWVkf1iIGpk7MsBcz3zP+S1kze
# 4hHmNcqjfZ3+JitFj+O8OhcgP0wugpE9m6seT0g6BrycPBn13UQp6VRSyz51k/ni
# sBlYrcFKKXxZ6JpjK6ICNb+tnKZPTG+AyQ4dMgV/AUb1I2U2H05zwBOnIahRpt5Z
# wSCjZmdKp6AY/Hjbq62IWlhjBTBkfsvec4ovNg/uMBMOF0J0zCez4gj7BgPKCGhy
# ZuL3KF9HxTVuHW0cig==
# SIG # End signature block
