function Test-UCEventSource {
    <#
    .SYNOPSIS
    Tests if the Unity-Claude Event Log source exists
    
    .DESCRIPTION
    Checks if the event source has been created and is properly configured.
    Does not require Administrator privileges.
    
    .PARAMETER SourceName
    The name of the event source to test (default: Unity-Claude-Agent)
    
    .PARAMETER Detailed
    Return detailed information about the event source
    
    .EXAMPLE
    Test-UCEventSource
    
    .EXAMPLE
    Test-UCEventSource -Detailed
    #>
    [CmdletBinding()]
    param(
        [string]$SourceName = $script:SourceName,
        [switch]$Detailed
    )
    
    begin {
        Write-UCDebugLog "Test-UCEventSource started - SourceName: $SourceName, Detailed: $Detailed"
    }
    
    process {
        try {
            # Check if source exists
            $sourceExists = $false
            $logName = $null
            $errorMessage = $null
            
            try {
                $sourceExists = [System.Diagnostics.EventLog]::SourceExists($SourceName)
                Write-UCDebugLog "Source exists check: $sourceExists"
                
                if ($sourceExists) {
                    # Get the associated log name
                    $logName = [System.Diagnostics.EventLog]::LogNameFromSourceName($SourceName, ".")
                    Write-UCDebugLog "Source is associated with log: $logName"
                }
            }
            catch {
                $errorMessage = $_.Exception.Message
                Write-UCDebugLog "Error checking source: $errorMessage" -Level 'ERROR'
                
                # Check if it's a permission error
                if ($_.Exception.Message -like "*requested registry access*") {
                    $errorMessage = "Registry access denied. Event source may exist but cannot be verified without proper permissions."
                }
            }
            
            if ($Detailed) {
                $result = @{
                    Exists = $sourceExists
                    SourceName = $SourceName
                    LogName = $logName
                    ExpectedLogName = $script:LogName
                    IsCorrectLog = $logName -eq $script:LogName
                    ErrorMessage = $errorMessage
                }
                
                # Try to get additional information if source exists
                if ($sourceExists -and $logName) {
                    try {
                        # Check if we can write to the log
                        $canWrite = $false
                        try {
                            $testLog = New-Object System.Diagnostics.EventLog($logName)
                            $testLog.Source = $SourceName
                            # Don't actually write, just check if we can create the object
                            $canWrite = $true
                            $testLog.Dispose()
                        }
                        catch {
                            Write-UCDebugLog "Cannot create EventLog object: $_" -Level 'WARNING'
                        }
                        
                        $result.CanWrite = $canWrite
                        
                        # Get log information
                        try {
                            $logs = [System.Diagnostics.EventLog]::GetEventLogs()
                            $targetLog = $logs | Where-Object { $_.Log -eq $logName }
                            
                            if ($targetLog) {
                                $result.LogDisplayName = $targetLog.LogDisplayName
                                $result.MaximumKilobytes = $targetLog.MaximumKilobytes
                                $result.OverflowAction = $targetLog.OverflowAction
                                $result.MinimumRetentionDays = $targetLog.MinimumRetentionDays
                                $result.Entries = $targetLog.Entries.Count
                                
                                Write-UCDebugLog "Log details retrieved - Entries: $($result.Entries), MaxKB: $($result.MaximumKilobytes)"
                            }
                        }
                        catch {
                            Write-UCDebugLog "Could not retrieve log details: $_" -Level 'WARNING'
                        }
                    }
                    catch {
                        Write-UCDebugLog "Error getting additional information: $_" -Level 'WARNING'
                    }
                }
                
                # Check if running as admin
                $isAdmin = [bool]([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]'Administrator')
                $result.IsAdmin = $isAdmin
                
                Write-UCDebugLog "Detailed test complete - Exists: $($result.Exists), CanWrite: $($result.CanWrite)"
                return $result
            }
            else {
                # Simple boolean return
                Write-UCDebugLog "Simple test complete - Result: $sourceExists"
                return $sourceExists
            }
        }
        catch {
            Write-UCDebugLog "Test-UCEventSource failed: $_" -Level 'ERROR'
            Write-Error $_
            
            if ($Detailed) {
                return @{
                    Exists = $false
                    SourceName = $SourceName
                    ErrorMessage = $_.Exception.Message
                }
            }
            else {
                return $false
            }
        }
    }
    
    end {
        Write-UCDebugLog "Test-UCEventSource completed"
    }
}