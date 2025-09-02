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
# SIG # Begin signature block
# MIIFzgYJKoZIhvcNAQcCoIIFvzCCBbsCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCDHqn/ItZ+1B3oA
# IsUw2u0FpTURluPw4tXUZBES+62QD6CCAzAwggMsMIICFKADAgECAhB1HRbZIqgr
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
# MAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIEw0GYmGG3h/3I+t3m8SXqxy
# mbkmSfCPEN2kn2CpqtFZMA0GCSqGSIb3DQEBAQUABIIBADKvqztkIp/ysBg1fW7W
# CYg7PYn9KdYPM9X5x85dOdEud/hcbAvQVOq7Chk9VZP4cMK/gdGeFyCZASKcMbjA
# ruSLKeTyO0pa/uMjVfFtaMaYnla4MLLFEgvc+Zy09dQPeSyoNh45/o7/B/3layOP
# E13/tc913mxm4C2yGY0liPpuOh3jn60bufv6wMnAeTnWOOcnN5v9i+nfjSkwTCLr
# KAAqJbrg9FpjXuyHwuuv6ThL64+godhqOVai299TXSb4JmUtAgLXAhDaauQ1t9o/
# +hrhL5S0tFvVAY708siRHXdmlrhq4WYKOz01nPRhda7+1DG8pk5MA05+xa369/4K
# 2h4=
# SIG # End signature block
