function Write-UCEventLog {
    <#
    .SYNOPSIS
    Writes an event to the Unity-Claude Event Log
    
    .DESCRIPTION
    Cross-version compatible function to write events to Windows Event Log.
    Falls back to file logging if event source is not available.
    
    .PARAMETER Message
    The message to write to the event log
    
    .PARAMETER EntryType
    The type of event (Information, Warning, Error, Critical)
    
    .PARAMETER EventId
    The event ID (defaults based on EntryType and Component)
    
    .PARAMETER Component
    The component generating the event (Unity, Claude, Agent, Monitor, etc.)
    
    .PARAMETER Action
    The action being performed (CompilationStart, SubmissionComplete, etc.)
    
    .PARAMETER Details
    Additional structured data as a hashtable
    
    .PARAMETER CorrelationId
    A GUID to correlate related events
    
    .PARAMETER NoFallback
    Do not fall back to file logging if event log is unavailable
    
    .EXAMPLE
    Write-UCEventLog -Message "Unity compilation completed" -EntryType Information -Component Unity
    
    .EXAMPLE
    Write-UCEventLog -Message "Error submitting to Claude" -EntryType Error -Component Claude -Details @{ErrorCode=500; Retry=3}
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Message,
        
        [Parameter()]
        [ValidateSet('Information', 'Warning', 'Error', 'Critical', 'SuccessAudit', 'FailureAudit')]
        [string]$EntryType = 'Information',
        
        [Parameter()]
        [int]$EventId = 0,
        
        [Parameter()]
        [ValidateSet('Unity', 'Claude', 'Agent', 'Monitor', 'IPC', 'Dashboard', 'EventLog', 'General')]
        [string]$Component = 'General',
        
        [Parameter()]
        [string]$Action = '',
        
        [Parameter()]
        [hashtable]$Details = @{},
        
        [Parameter()]
        [guid]$CorrelationId = [guid]::Empty,
        
        [Parameter()]
        [switch]$NoFallback
    )
    
    begin {
        Write-UCDebugLog "Write-UCEventLog started - Component: $Component, EntryType: $EntryType"
        
        # Generate event ID if not provided
        if ($EventId -eq 0) {
            # Use configured ranges from module config
            $eventIdRange = switch ($EntryType) {
                'Information' { $script:ModuleConfig.EventIdRanges.Information }
                'Warning' { $script:ModuleConfig.EventIdRanges.Warning }
                'Error' { $script:ModuleConfig.EventIdRanges.Error }
                'Critical' { $script:ModuleConfig.EventIdRanges.Critical }
                'SuccessAudit' { @{ Start = 6000 } }
                'FailureAudit' { @{ Start = 7000 } }
                default { @{ Start = 1000 } }
            }
            
            # Generate ID based on component
            $componentIndex = switch ($Component) {
                'Unity' { 0 }
                'Claude' { 100 }
                'Agent' { 200 }
                'Monitor' { 300 }
                'IPC' { 400 }
                'Dashboard' { 500 }
                'EventLog' { 600 }
                default { 900 }
            }
            
            $EventId = $eventIdRange.Start + $componentIndex
            Write-UCDebugLog "Generated EventId: $EventId"
        }
        
        # Map Critical to Error for EventLogEntryType (which doesn't have Critical)
        $logEntryType = switch ($EntryType) {
            'Critical' { [System.Diagnostics.EventLogEntryType]::Error }
            'SuccessAudit' { [System.Diagnostics.EventLogEntryType]::SuccessAudit }
            'FailureAudit' { [System.Diagnostics.EventLogEntryType]::FailureAudit }
            default { [System.Diagnostics.EventLogEntryType]::$EntryType }
        }
    }
    
    process {
        $eventWritten = $false
        $startTime = Get-Date
        
        try {
            # Build structured message
            $structuredMessage = $Message
            
            # Add metadata
            $metadata = @{
                Component = $Component
                Action = $Action
                Timestamp = $startTime.ToString('yyyy-MM-dd HH:mm:ss.fff')
                PSVersion = $PSVersionTable.PSVersion.ToString()
                PSEdition = $PSVersionTable.PSEdition
            }
            
            if ($CorrelationId -ne [guid]::Empty) {
                $metadata.CorrelationId = $CorrelationId.ToString()
            }
            
            if ($Details.Count -gt 0) {
                $metadata.Details = $Details
            }
            
            # Format the full message
            $fullMessage = @"
$Message

=== Event Metadata ===
Component: $Component
Action: $Action
Timestamp: $($metadata.Timestamp)
PowerShell: $($metadata.PSVersion) ($($metadata.PSEdition))
"@
            
            if ($CorrelationId -ne [guid]::Empty) {
                $fullMessage += "`nCorrelation ID: $($CorrelationId.ToString())"
            }
            
            if ($Details.Count -gt 0) {
                $fullMessage += "`n`n=== Additional Details ==="
                foreach ($key in $Details.Keys) {
                    $value = $Details[$key]
                    $fullMessage += "`n${key}: $value"
                }
            }
            
            # Try to write to event log
            try {
                # Check if source exists
                $sourceExists = Test-UCEventSource -SourceName $script:SourceName
                
                if ($sourceExists) {
                    Write-UCDebugLog "Event source exists, writing to event log"
                    
                    # Use System.Diagnostics.EventLog (works in both PS 5.1 and 7)
                    $eventLog = New-Object System.Diagnostics.EventLog($script:LogName)
                    $eventLog.Source = $script:SourceName
                    
                    # Write the event
                    $eventLog.WriteEntry($fullMessage, $logEntryType, $EventId)
                    $eventLog.Dispose()
                    
                    $duration = ((Get-Date) - $startTime).TotalMilliseconds
                    Write-UCDebugLog "Event written successfully in $duration ms"
                    $eventWritten = $true
                    
                    # Also write to verbose stream
                    Write-Verbose "[$EntryType] $Message"
                }
                else {
                    Write-UCDebugLog "Event source does not exist" -Level 'WARNING'
                    
                    if (-not $NoFallback) {
                        Write-Warning "Event source not initialized. Run Initialize-UCEventSource as Administrator."
                    }
                }
            }
            catch {
                Write-UCDebugLog "Failed to write to event log: $_" -Level 'ERROR'
                
                # Check if it's a PowerShell 7 compatibility issue
                if ($script:IsPSCore -and $_.Exception.Message -like "*not supported*") {
                    Write-UCDebugLog "PowerShell 7 compatibility issue detected" -Level 'WARNING'
                    
                    # Try alternative approach for PS7
                    try {
                        # Use static method as fallback
                        [System.Diagnostics.EventLog]::WriteEntry(
                            $script:SourceName,
                            $fullMessage,
                            $logEntryType,
                            $EventId
                        )
                        $eventWritten = $true
                        Write-UCDebugLog "Event written using static method"
                    }
                    catch {
                        Write-UCDebugLog "Static method also failed: $_" -Level 'ERROR'
                    }
                }
            }
            
            # Fallback to file logging if event log write failed
            if (-not $eventWritten -and -not $NoFallback) {
                Write-UCDebugLog "Falling back to file logging"
                
                # Write to debug log with full details
                $logEntry = @{
                    Timestamp = $startTime
                    Level = $EntryType
                    EventId = $EventId
                    Component = $Component
                    Action = $Action
                    Message = $Message
                    Details = $Details
                    CorrelationId = $CorrelationId
                } | ConvertTo-Json -Compress
                
                Add-Content -Path $script:DebugLogPath -Value $logEntry -ErrorAction SilentlyContinue
                
                # Write to appropriate PowerShell stream
                switch ($EntryType) {
                    'Error' { Write-Error $Message }
                    'Warning' { Write-Warning $Message }
                    'Critical' { Write-Error "CRITICAL: $Message" }
                    default { Write-Information $Message -InformationAction Continue }
                }
            }
            
            # Return result
            return @{
                Success = $eventWritten
                EventId = $EventId
                EntryType = $EntryType
                Component = $Component
                Duration = ((Get-Date) - $startTime).TotalMilliseconds
                FallbackUsed = (-not $eventWritten -and -not $NoFallback)
            }
        }
        catch {
            Write-UCDebugLog "Write-UCEventLog failed: $_" -Level 'ERROR'
            Write-Error $_
            
            return @{
                Success = $false
                EventId = $EventId
                Error = $_.Exception.Message
            }
        }
    }
    
    end {
        Write-UCDebugLog "Write-UCEventLog completed"
    }
}