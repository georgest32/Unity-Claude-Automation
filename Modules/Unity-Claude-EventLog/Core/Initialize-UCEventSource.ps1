function Initialize-UCEventSource {
    <#
    .SYNOPSIS
    Initializes the Windows Event Log source for Unity-Claude Automation
    
    .DESCRIPTION
    Creates a custom event source in Windows Event Log if it doesn't exist.
    Requires Administrator privileges for first-time creation.
    Supports both PowerShell 5.1 and PowerShell 7+
    
    .PARAMETER LogName
    The name of the event log (default: Unity-Claude-Automation)
    
    .PARAMETER SourceName
    The name of the event source (default: Unity-Claude-Agent)
    
    .PARAMETER Force
    Force recreation of the event source even if it exists
    
    .EXAMPLE
    Initialize-UCEventSource
    
    .EXAMPLE
    Initialize-UCEventSource -Force
    #>
    [CmdletBinding()]
    param(
        [string]$LogName = $script:LogName,
        [string]$SourceName = $script:SourceName,
        [switch]$Force
    )
    
    begin {
        Write-UCDebugLog "Initialize-UCEventSource started - LogName: $LogName, SourceName: $SourceName, Force: $Force"
        
        # Check if running as administrator
        $isAdmin = [bool]([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]'Administrator')
        Write-UCDebugLog "Administrator check: $isAdmin"
    }
    
    process {
        try {
            # Check if source already exists
            $sourceExists = $false
            try {
                $sourceExists = [System.Diagnostics.EventLog]::SourceExists($SourceName)
                Write-UCDebugLog "Event source exists check: $sourceExists"
            }
            catch {
                Write-UCDebugLog "Error checking if source exists: $_" -Level 'ERROR'
                # If we can't check, assume it doesn't exist
            }
            
            if ($sourceExists -and -not $Force) {
                Write-UCDebugLog "Event source '$SourceName' already exists"
                Write-Verbose "Event source '$SourceName' already exists"
                
                # Verify the source is associated with the correct log
                try {
                    $currentLog = [System.Diagnostics.EventLog]::LogNameFromSourceName($SourceName, ".")
                    if ($currentLog -ne $LogName) {
                        Write-Warning "Event source '$SourceName' exists but is associated with log '$currentLog' instead of '$LogName'"
                        Write-UCDebugLog "Source/Log mismatch - Current: $currentLog, Expected: $LogName" -Level 'WARNING'
                        
                        if ($isAdmin) {
                            Write-Verbose "Attempting to recreate source with correct log association..."
                            [System.Diagnostics.EventLog]::DeleteEventSource($SourceName)
                            [System.Diagnostics.EventLog]::CreateEventSource($SourceName, $LogName)
                            Write-UCDebugLog "Successfully recreated event source with correct log"
                            Write-Information "Event source recreated successfully"
                        }
                        else {
                            throw "Administrator privileges required to fix event source association"
                        }
                    }
                    else {
                        Write-UCDebugLog "Event source correctly associated with log"
                    }
                }
                catch {
                    Write-UCDebugLog "Error verifying source/log association: $_" -Level 'ERROR'
                }
                
                return @{
                    Success = $true
                    Message = "Event source already exists"
                    LogName = $LogName
                    SourceName = $SourceName
                    RequiredAdmin = $false
                }
            }
            
            # Remove source if Force is specified
            if ($sourceExists -and $Force) {
                if (-not $isAdmin) {
                    throw "Administrator privileges required to recreate event source"
                }
                
                Write-UCDebugLog "Force flag set - removing existing source"
                Write-Verbose "Removing existing event source '$SourceName'..."
                
                try {
                    [System.Diagnostics.EventLog]::DeleteEventSource($SourceName)
                    Write-UCDebugLog "Successfully removed existing event source"
                    Start-Sleep -Milliseconds 500  # Brief pause for cleanup
                }
                catch {
                    Write-UCDebugLog "Error removing event source: $_" -Level 'ERROR'
                    throw "Failed to remove existing event source: $_"
                }
            }
            
            # Create the event source
            if (-not $isAdmin) {
                Write-UCDebugLog "Admin privileges required but not available" -Level 'WARNING'
                Write-Warning "Administrator privileges required to create event source"
                Write-Warning "Please run the following command as Administrator:"
                Write-Warning "  Initialize-UCEventSource -LogName '$LogName' -SourceName '$SourceName'"
                
                return @{
                    Success = $false
                    Message = "Administrator privileges required"
                    LogName = $LogName
                    SourceName = $SourceName
                    RequiredAdmin = $true
                }
            }
            
            # Create the event source using .NET method (works in both PS 5.1 and 7)
            Write-UCDebugLog "Creating event source..."
            Write-Verbose "Creating event source '$SourceName' in log '$LogName'..."
            
            try {
                # Create event source
                [System.Diagnostics.EventLog]::CreateEventSource($SourceName, $LogName)
                Write-UCDebugLog "Event source created successfully"
                
                # Configure the event log settings if possible
                try {
                    $eventLog = New-Object System.Diagnostics.EventLog($LogName)
                    
                    # Set maximum log size (20MB)
                    if ($script:ModuleConfig -and $script:ModuleConfig.MaximumKilobytes) {
                        $eventLog.MaximumKilobytes = $script:ModuleConfig.MaximumKilobytes
                        Write-UCDebugLog "Set maximum log size to $($script:ModuleConfig.MaximumKilobytes) KB"
                    }
                    
                    # Set overflow action
                    if ($script:ModuleConfig -and $script:ModuleConfig.OverflowAction) {
                        $eventLog.ModifyOverflowPolicy(
                            [System.Diagnostics.OverflowAction]::OverwriteOlder,
                            $script:ModuleConfig.RetentionDays
                        )
                        Write-UCDebugLog "Set overflow policy to OverwriteOlder with $($script:ModuleConfig.RetentionDays) day retention"
                    }
                    
                    $eventLog.Dispose()
                }
                catch {
                    Write-UCDebugLog "Warning: Could not configure log settings: $_" -Level 'WARNING'
                    Write-Verbose "Could not configure advanced log settings: $_"
                }
                
                # Write an initialization event
                try {
                    $initEvent = New-Object System.Diagnostics.EventLog($LogName)
                    $initEvent.Source = $SourceName
                    $initEvent.WriteEntry(
                        "Unity-Claude Event Log initialized successfully`nModule Version: $script:ModuleVersion`nPowerShell Version: $($PSVersionTable.PSVersion)",
                        [System.Diagnostics.EventLogEntryType]::Information,
                        1000
                    )
                    $initEvent.Dispose()
                    Write-UCDebugLog "Wrote initialization event to log"
                }
                catch {
                    Write-UCDebugLog "Warning: Could not write initialization event: $_" -Level 'WARNING'
                }
                
                Write-Information "Event source '$SourceName' created successfully in log '$LogName'"
                
                return @{
                    Success = $true
                    Message = "Event source created successfully"
                    LogName = $LogName
                    SourceName = $SourceName
                    RequiredAdmin = $true
                }
            }
            catch {
                Write-UCDebugLog "Failed to create event source: $_" -Level 'ERROR'
                throw "Failed to create event source: $_"
            }
        }
        catch {
            Write-UCDebugLog "Initialize-UCEventSource failed: $_" -Level 'ERROR'
            Write-Error $_
            
            return @{
                Success = $false
                Message = $_.Exception.Message
                LogName = $LogName
                SourceName = $SourceName
                RequiredAdmin = $isAdmin
            }
        }
    }
    
    end {
        Write-UCDebugLog "Initialize-UCEventSource completed"
    }
}
# SIG # Begin signature block
# MIIFzgYJKoZIhvcNAQcCoIIFvzCCBbsCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCDZJW7wdq0REapm
# CbzHhBWJIuBtkF++MJ8lWNMxb1FTbqCCAzAwggMsMIICFKADAgECAhB1HRbZIqgr
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
# MAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIMDHg0CZ4D4Ko92KI9Ef22QQ
# 9B07otqtHwg8Imf/gxs9MA0GCSqGSIb3DQEBAQUABIIBAC1WLgRAKfsFtqwiMq4t
# yOq2wFNtmKQ0JuZy2fTrouTu7DzcHtdAZJaInQiNXHOG0FonXzSv6toMD9DXvLOO
# 2i6J6o2woA/uzKULfkfxR96ZYYXrC10trMyERTKO/xOfVkK56koFXDNakIZoWIXh
# 9fYO1UvENJq1OCBSffjtrKRBDRtDA8EesNYrc86lqZXcWjYLUMoN6HHQspomaN/C
# is4vuOvLE8d57cYjyLunt8h3REB6trFLeeb8PzxfSBafYeZCGWurHFeI8OtiTXcV
# afYUVsOlVF1KKYZ+qCkoHyYQkEcwVQWJ6o2JQ3czAOqfb2XznCDXxim+YwkZiS+J
# 4Y0=
# SIG # End signature block
