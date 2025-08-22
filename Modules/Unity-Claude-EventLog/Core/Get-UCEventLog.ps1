function Get-UCEventLog {
    <#
    .SYNOPSIS
    Retrieves events from the Unity-Claude Event Log
    
    .DESCRIPTION
    Uses Get-WinEvent with optimized XPath queries for performance.
    Supports filtering by time, component, level, and custom XPath.
    
    .PARAMETER MaxEvents
    Maximum number of events to return (default: 100)
    
    .PARAMETER StartTime
    Return events after this time
    
    .PARAMETER EndTime
    Return events before this time
    
    .PARAMETER EntryType
    Filter by entry type (Information, Warning, Error, etc.)
    
    .PARAMETER Component
    Filter by component (Unity, Claude, Agent, etc.)
    
    .PARAMETER EventId
    Filter by specific event ID or array of IDs
    
    .PARAMETER XPath
    Custom XPath query for advanced filtering
    
    .EXAMPLE
    Get-UCEventLog -MaxEvents 50 -EntryType Error
    
    .EXAMPLE
    Get-UCEventLog -Component Unity -StartTime (Get-Date).AddHours(-1)
    #>
    [CmdletBinding(DefaultParameterSetName = 'Standard')]
    param(
        [Parameter(ParameterSetName = 'Standard')]
        [int]$MaxEvents = 100,
        
        [Parameter(ParameterSetName = 'Standard')]
        [datetime]$StartTime,
        
        [Parameter(ParameterSetName = 'Standard')]
        [datetime]$EndTime,
        
        [Parameter(ParameterSetName = 'Standard')]
        [ValidateSet('Information', 'Warning', 'Error', 'Critical', 'All')]
        [string]$EntryType = 'All',
        
        [Parameter(ParameterSetName = 'Standard')]
        [ValidateSet('Unity', 'Claude', 'Agent', 'Monitor', 'IPC', 'Dashboard', 'All')]
        [string]$Component = 'All',
        
        [Parameter(ParameterSetName = 'Standard')]
        [int[]]$EventId,
        
        [Parameter(ParameterSetName = 'XPath', Mandatory = $true)]
        [string]$XPath
    )
    
    begin {
        Write-UCDebugLog "Get-UCEventLog started - MaxEvents: $MaxEvents, EntryType: $EntryType, Component: $Component"
    }
    
    process {
        try {
            # Build filter based on parameter set
            if ($PSCmdlet.ParameterSetName -eq 'Standard') {
                # Use hashtable filter for time-based queries (more reliable)
                if ($StartTime -or $EndTime) {
                    $filterHash = @{
                        LogName = $script:LogName
                    }
                    
                    if ($StartTime) {
                        $filterHash.StartTime = $StartTime
                        Write-UCDebugLog "Added start time filter: $StartTime"
                    }
                    
                    if ($EndTime) {
                        $filterHash.EndTime = $EndTime
                        Write-UCDebugLog "Added end time filter: $EndTime"
                    }
                    
                    # Add event ID filter if specified
                    if ($EventId) {
                        $filterHash.ID = $EventId
                        Write-UCDebugLog "Added event ID filter: $($EventId -join ', ')"
                    }
                    
                    Write-UCDebugLog "Using hashtable filter for time-based query"
                    
                    # Get events using hashtable filter
                    $getWinEventParams = @{
                        FilterHashtable = $filterHash
                        MaxEvents = $MaxEvents
                        ErrorAction = 'Stop'
                    }
                }
                else {
                    # Use XPath for non-time-based queries
                    $xpathConditions = @()
                    
                    # Add level filter
                    if ($EntryType -ne 'All') {
                        $level = switch ($EntryType) {
                            'Information' { 4 }
                            'Warning' { 3 }
                            'Error' { 2 }
                            'Critical' { 1 }
                        }
                        $xpathConditions += "Level=$level"
                        Write-UCDebugLog "Added level filter: $EntryType ($level)"
                    }
                    
                    # Add event ID filter
                    if ($EventId) {
                        if ($EventId.Count -eq 1) {
                            $xpathConditions += "EventID=$($EventId[0])"
                        }
                        else {
                            $idConditions = $EventId | ForEach-Object { "EventID=$_" }
                            $xpathConditions += "(" + ($idConditions -join " or ") + ")"
                        }
                        Write-UCDebugLog "Added event ID filter: $($EventId -join ', ')"
                    }
                    
                    # Build the XPath query
                    if ($xpathConditions.Count -gt 0) {
                        $XPath = "*[System[" + ($xpathConditions -join " and ") + "]]"
                    }
                    else {
                        $XPath = "*"
                    }
                    
                    Write-UCDebugLog "Built XPath query: $XPath"
                    
                    # Get events using XPath filter
                    $getWinEventParams = @{
                        LogName = $script:LogName
                        MaxEvents = $MaxEvents
                        ErrorAction = 'Stop'
                    }
                    
                    if ($XPath -and $XPath -ne "*") {
                        $getWinEventParams.FilterXPath = $XPath
                    }
                }
            }
            else {
                # Custom XPath provided
                $getWinEventParams = @{
                    LogName = $script:LogName
                    FilterXPath = $XPath
                    MaxEvents = $MaxEvents
                    ErrorAction = 'Stop'
                }
            }
            
            Write-UCDebugLog "Calling Get-WinEvent with parameters: $($getWinEventParams | ConvertTo-Json -Compress)"
            
            $events = Get-WinEvent @getWinEventParams
            
            Write-UCDebugLog "Retrieved $($events.Count) events"
            
            # Process and enrich events
            $processedEvents = foreach ($event in $events) {
                $eventData = @{
                    TimeCreated = $event.TimeCreated
                    Id = $event.Id
                    Level = $event.LevelDisplayName
                    Message = $event.Message
                    Source = $event.ProviderName
                    MachineName = $event.MachineName
                    UserId = $event.UserId
                    ProcessId = $event.ProcessId
                    ThreadId = $event.ThreadId
                }
                
                # Parse component from message if available
                if ($event.Message -match 'Component:\s*(\w+)') {
                    $eventData.Component = $Matches[1]
                }
                
                # Parse action from message if available
                if ($event.Message -match 'Action:\s*(\w+)') {
                    $eventData.Action = $Matches[1]
                }
                
                # Parse correlation ID if available
                if ($event.Message -match 'Correlation ID:\s*([\w-]+)') {
                    $eventData.CorrelationId = $Matches[1]
                }
                
                # Filter by component if specified
                if ($Component -ne 'All' -and $eventData.Component -and $eventData.Component -ne $Component) {
                    continue
                }
                
                [PSCustomObject]$eventData
            }
            
            Write-UCDebugLog "Processed $($processedEvents.Count) events after filtering"
            
            return $processedEvents
        }
        catch [Exception] {
            # Check if it's because the log doesn't exist
            if ($_.Exception.Message -like "*does not exist*") {
                Write-UCDebugLog "Event log does not exist" -Level 'WARNING'
                Write-Warning "Event log '$script:LogName' does not exist. Run Initialize-UCEventSource first."
                return @()
            }
            else {
                Write-UCDebugLog "Get-UCEventLog failed: $_" -Level 'ERROR'
                Write-Error $_
                return @()
            }
        }
    }
    
    end {
        Write-UCDebugLog "Get-UCEventLog completed"
    }
}