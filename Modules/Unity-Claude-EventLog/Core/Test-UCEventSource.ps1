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
# SIG # Begin signature block
# MIIFzgYJKoZIhvcNAQcCoIIFvzCCBbsCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCDFQqBBcBtXJOGG
# FQVJm0WvEhvcmFB2N+thnEEZAFllD6CCAzAwggMsMIICFKADAgECAhB1HRbZIqgr
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
# MAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEILeMMsVxe3nSeqSo5yEpgagK
# txzJ3HRToHyf1P5pbn9sMA0GCSqGSIb3DQEBAQUABIIBAHkFqxa31TIjKpP9+yvm
# RliqBNisroUTfrzmgrcvE/lAI8HBqT+yupz++DnORrRc701ZO/c81MUQV1rvnARd
# SMBFTEavqmAIwDyGfwVqGPMqrFrKMmkl5P71BoKc/obz5jxGKfDHKjJnkroZbQyR
# dMBvlCA4HfkcuDOacpgAIMxXq/5I8fmlU290jLAvS7lmcjn1wS1u4A4E5OOnsEoq
# BRX5YnI+VhXkDkzdmF/FVh094MV4x3M5E6o1rl26tvTEXmgdLSME+6XmvhFndy2b
# AiQ/s/0fb1DEEw1cFHCrKOGa1qdFFrXHqT8IPD09T8IbNJ7Ss6jvek2sE31I1YYo
# w1A=
# SIG # End signature block
