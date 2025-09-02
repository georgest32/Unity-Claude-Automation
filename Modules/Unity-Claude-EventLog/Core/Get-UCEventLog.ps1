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
# SIG # Begin signature block
# MIIFzgYJKoZIhvcNAQcCoIIFvzCCBbsCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCCHHAhc8SW7IPg8
# bN2uEax7LignHbPmBfk50ACJWlUmRqCCAzAwggMsMIICFKADAgECAhB1HRbZIqgr
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
# MAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIARvamM1N3O7wczhk7rRsfem
# Q7pQzu4qiQePuI+GJw83MA0GCSqGSIb3DQEBAQUABIIBALEg1QseMAMi6CTXLOcC
# ndxihmyo0T9wNvZnmb+IOygZk5wsGyDbs3c6soJZWaQgOvj6KdP1sMzzZ7DW29m/
# RKt0HjDUfTARreY7vMtvHIxb5i4oEAK/TTLx6wMqjFauuu4b4/9FAYvQdap96PuT
# JhszQkj+YWQUSpnQmma4KYT4yknwbqy8RNTREymPJmX8TOvC9JdPf500fLkNuoP1
# eRfq214T0aM5ovxhtjL0mA1CSh5DECRXA1gj/KTpYsCn4AFrwct0C966eAonlNao
# Qn4cbd9+iz1mx0r0hN9o9V+/tJ2a52W99jq57iouVATsQI+qOxOCZrWe8ayKpSvg
# cEE=
# SIG # End signature block
