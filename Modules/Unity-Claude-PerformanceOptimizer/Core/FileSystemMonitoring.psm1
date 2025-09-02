# FileSystemMonitoring.psm1
# File system monitoring and change detection components

using namespace System.IO
using namespace System.Collections.Concurrent

# Initialize file system watcher
function Initialize-FileSystemWatcher {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$BasePath,
        
        [string]$Filter = "*",
        [switch]$IncludeSubdirectories
    )
    
    Write-Verbose "[FileSystemMonitoring] Starting file system watcher for: $BasePath"
    
    $watcher = [FileSystemWatcher]::new($BasePath)
    $watcher.IncludeSubdirectories = $IncludeSubdirectories
    $watcher.Filter = $Filter
    $watcher.NotifyFilter = [NotifyFilters]::FileName -bor [NotifyFilters]::LastWrite
    
    Write-Verbose "[FileSystemMonitoring] File system watcher configured"
    return $watcher
}

# Register file change event handler
function Register-FileChangeHandler {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [FileSystemWatcher]$Watcher,
        
        [Parameter(Mandatory)]
        [scriptblock]$Handler,
        
        [object]$MessageData
    )
    
    Register-ObjectEvent -InputObject $Watcher -EventName Changed -Action $Handler -MessageData $MessageData | Out-Null
    Register-ObjectEvent -InputObject $Watcher -EventName Created -Action $Handler -MessageData $MessageData | Out-Null
    Register-ObjectEvent -InputObject $Watcher -EventName Renamed -Action $Handler -MessageData $MessageData | Out-Null
    
    Write-Verbose "[FileSystemMonitoring] File change handlers registered"
}

# Start file system monitoring
function Start-FileSystemMonitoring {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [FileSystemWatcher]$Watcher
    )
    
    $Watcher.EnableRaisingEvents = $true
    Write-Information "[FileSystemMonitoring] File system monitoring started"
}

# Stop file system monitoring
function Stop-FileSystemMonitoring {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [FileSystemWatcher]$Watcher
    )
    
    if ($Watcher) {
        $Watcher.EnableRaisingEvents = $false
        $Watcher.Dispose()
        Write-Information "[FileSystemMonitoring] File system monitoring stopped"
    }
}

# Process file change event
function New-FileChangeInfo {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$FilePath,
        
        [Parameter(Mandatory)]
        [string]$ChangeType,
        
        [int]$Priority = 5
    )
    
    return [PSCustomObject]@{
        FilePath = $FilePath
        ChangeType = $ChangeType
        Timestamp = [datetime]::Now
        Priority = $Priority
        ProcessingStatus = 'Pending'
        RetryCount = 0
    }
}

# Get dependent files for incremental processing
function Get-DependentFiles {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$FilePath,
        
        [object]$IncrementalProcessor
    )
    
    $dependentFiles = @()
    
    if ($IncrementalProcessor) {
        try {
            $dependentFiles = $IncrementalProcessor.GetDependentFiles($FilePath)
            Write-Debug "[FileSystemMonitoring] Found $($dependentFiles.Count) dependent files for $FilePath"
        }
        catch {
            Write-Warning "[FileSystemMonitoring] Failed to get dependent files for $FilePath : $_"
        }
    }
    
    return $dependentFiles
}

# Queue dependent files for processing
function Add-DependentFilesToQueue {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$SourceFilePath,
        
        [Parameter(Mandatory)]
        [System.Collections.Concurrent.ConcurrentQueue[PSCustomObject]]$ProcessingQueue,
        
        [object]$IncrementalProcessor
    )
    
    $dependentFiles = Get-DependentFiles -FilePath $SourceFilePath -IncrementalProcessor $IncrementalProcessor
    
    foreach ($dependentFile in $dependentFiles) {
        $changeInfo = New-FileChangeInfo -FilePath $dependentFile -ChangeType 'Dependent' -Priority 3
        $ProcessingQueue.Enqueue($changeInfo)
    }
    
    if ($dependentFiles.Count -gt 0) {
        Write-Debug "[FileSystemMonitoring] Queued $($dependentFiles.Count) dependent files for processing"
    }
}

# Monitor queue health
function Get-QueueHealth {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [System.Collections.Concurrent.ConcurrentQueue[PSCustomObject]]$ProcessingQueue,
        
        [int]$WarningThreshold = 100,
        [int]$CriticalThreshold = 500
    )
    
    $queueLength = $ProcessingQueue.Count
    
    $health = [PSCustomObject]@{
        QueueLength = $queueLength
        Status = 'Healthy'
        Message = "Queue contains $queueLength items"
        Timestamp = [datetime]::Now
    }
    
    if ($queueLength -gt $CriticalThreshold) {
        $health.Status = 'Critical'
        $health.Message = "Queue critically overloaded with $queueLength items (threshold: $CriticalThreshold)"
    }
    elseif ($queueLength -gt $WarningThreshold) {
        $health.Status = 'Warning'
        $health.Message = "Queue backlog detected with $queueLength items (threshold: $WarningThreshold)"
    }
    
    return $health
}

Export-ModuleMember -Function @(
    'Initialize-FileSystemWatcher',
    'Register-FileChangeHandler',
    'Start-FileSystemMonitoring',
    'Stop-FileSystemMonitoring',
    'New-FileChangeInfo',
    'Get-DependentFiles',
    'Add-DependentFilesToQueue',
    'Get-QueueHealth'
)
# SIG # Begin signature block
# MIIFzgYJKoZIhvcNAQcCoIIFvzCCBbsCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCAqGak0fCa+Dymt
# /VRHFJAO+uG/G26OepgVjmoRgFW0H6CCAzAwggMsMIICFKADAgECAhB1HRbZIqgr
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
# MAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIN2YIIEEJkA3kDmRU5IS7XF7
# Qg9FcwaOvTeWx+2+Ywm+MA0GCSqGSIb3DQEBAQUABIIBAHeB6ePAEHypkLHWte3a
# ZULC2AD0PVfRruRDP81crz5ALEZk7CwUCk5xQByYc/qb059sUar/dDCttoHT97oJ
# l+ArI3TS4do7Tv8UDLrTO/Yqvpm+7HBiWicA8wWWERDTd8aRjW6AfbFLbrhY9jNI
# W0BwbONoCLgBlRAwBceaZySoEFtmnONMTH0eqE88I9jZ1xWYud+q07SspBy72idq
# cA8rK/SVTQoXCX19RMAYnEK15D7/tf6UG0EiRoiw4hNfH46CAfRjmEDFx3wO+UI8
# s2QL3lNygTHGMKDwPwio8laOXSe/OdAcUetfW0zAiWs/Ozz6+0rkeTZxoa2BjSXx
# cVs=
# SIG # End signature block
