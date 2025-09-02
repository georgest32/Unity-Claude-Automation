function Test-SubsystemRunning {
    <#
    .SYNOPSIS
    Tests if a subsystem is already running by checking mutex and process status
    
    .DESCRIPTION
    Checks if a subsystem is already running by:
    1. Checking if its mutex is held
    2. Verifying the process is still alive
    3. Checking system status data
    
    .PARAMETER SubsystemName
    Name of the subsystem to check
    
    .PARAMETER MutexName
    Optional mutex name to check. If not provided, uses default pattern
    
    .OUTPUTS
    Boolean indicating if subsystem is running
    
    .EXAMPLE
    Test-SubsystemRunning -SubsystemName "SystemMonitoring"
    #>
    
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$SubsystemName,
        
        [string]$MutexName
    )
    
    # Default mutex name if not provided
    if (-not $MutexName) {
        $MutexName = "Global\UnityClaudeSubsystem_$SubsystemName"
    }
    
    # Method 1: Check if mutex exists and is held
    $mutexHeld = $false
    try {
        $mutex = [System.Threading.Mutex]::OpenExisting($MutexName)
        # Try to acquire with no wait
        $acquired = $mutex.WaitOne(0)
        if ($acquired) {
            # We got it, so it wasn't held
            $mutex.ReleaseMutex()
            $mutexHeld = $false
        } else {
            # Couldn't acquire, so it's held
            $mutexHeld = $true
        }
        $mutex.Dispose()
    } catch {
        # Mutex doesn't exist
        $mutexHeld = $false
    }
    
    if ($mutexHeld) {
        Write-SystemStatusLog "Subsystem $SubsystemName mutex is held" -Level 'DEBUG'
        return $true
    }
    
    # Method 2: Check system status for registered process
    try {
        $status = Read-SystemStatus
        if ($status -and $status.subsystems -and $status.subsystems.ContainsKey($SubsystemName)) {
            $subsystem = $status.subsystems[$SubsystemName]
            if ($subsystem.ProcessId) {
                # Check if process is still running
                $process = Get-Process -Id $subsystem.ProcessId -ErrorAction SilentlyContinue
                if ($process) {
                    Write-SystemStatusLog "Subsystem $SubsystemName process is running (PID: $($subsystem.ProcessId))" -Level 'DEBUG'
                    return $true
                }
            }
        }
    } catch {
        Write-SystemStatusLog "Error checking system status for $SubsystemName - $_" -Level 'DEBUG'
    }
    
    Write-SystemStatusLog "Subsystem $SubsystemName is not running" -Level 'DEBUG'
    return $false
}

# Export the function
Export-ModuleMember -Function Test-SubsystemRunning
# SIG # Begin signature block
# MIIFzgYJKoZIhvcNAQcCoIIFvzCCBbsCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCAIM1qTBxziLOwc
# aIeATAJ3QIE6a1xPPzk96gzBPomphKCCAzAwggMsMIICFKADAgECAhB1HRbZIqgr
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
# MAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIILsgLbwqq5lWFYIL0ZV2GSq
# DBeTjPJ1WaqxcWZVueF2MA0GCSqGSIb3DQEBAQUABIIBAHjOLtkC+KN9Efqwtz2/
# 0Nk6DXa/H1Kj4XTvkqTCrzwnyZqgqhVS+jg0pH23DhM7o283jU1GzknQ7/rMBCM5
# cQFa2d2JSY2iSkQVW8jmEWPY1wGKJLpHBp2gbjIqTI+88OokNDLhNzVp4RIZjhvg
# 8utQLcdgppv/XkfzVfQFi/qiUdcLAyb/Y8XJC1H+p4fPrMHyp4J/aLRRrTmczyrx
# 306ZCnSkRZsyAB8FYQVAtaxYjT5nFv/rguQ0KfiW74AsVT+G8ucQ0AFf2QT/1r8s
# 5QXByn77RmzmwnjLOaEMk/9vt82ZCntf8xL5/gz06iF0IoLdgJduGYt0dvJ6T5XQ
# EnQ=
# SIG # End signature block
