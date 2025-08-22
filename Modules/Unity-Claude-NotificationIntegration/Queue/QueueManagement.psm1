# QueueManagement.psm1
# Queue management and processing for notifications
# Date: 2025-08-21

#region Queue Management Functions

function Initialize-NotificationQueue {
    [CmdletBinding()]
    param(
        [Parameter()]
        [int]$MaxSize = 1000,
        
        [Parameter()]
        [switch]$EnablePersistence
    )
    
    Write-Verbose "Initializing notification queue (MaxSize: $MaxSize, Persistence: $($EnablePersistence.IsPresent))"
    Write-Host "[QUEUE MODULE] Initializing queue with MaxSize: $MaxSize" -ForegroundColor Magenta
    
    # Access parent module state using Get-Module and scriptblock invocation
    $parentModule = Get-Module 'Unity-Claude-NotificationIntegration-Modular'
    Write-Host "[QUEUE MODULE] Parent module found: $($parentModule.Name)" -ForegroundColor DarkMagenta
    
    # Clear queues using parent module state
    & $parentModule { 
        Write-Host "[QUEUE MODULE->PARENT] Clearing NotificationQueue" -ForegroundColor DarkMagenta
        Set-NotificationState -StateType 'Queue' -Value @() 
    }
    & $parentModule { 
        Write-Host "[QUEUE MODULE->PARENT] Clearing FailedNotifications" -ForegroundColor DarkMagenta
        Set-NotificationState -StateType 'FailedNotifications' -Value @() 
    }
    & $parentModule { 
        param($maxSize)
        Write-Host "[QUEUE MODULE->PARENT] Setting QueueMaxSize to $maxSize" -ForegroundColor DarkMagenta
        Set-NotificationState -StateType 'Config' -Property 'QueueMaxSize' -Value $maxSize 
    } -maxSize $MaxSize
    
    $queueStatus = @{
        QueueSize = 0
        MaxSize = $MaxSize
        PersistenceEnabled = $EnablePersistence.IsPresent
        FailedSize = 0
        QueuedItems = @()
        OldestQueued = $null
    }
    
    Write-Verbose "Notification queue initialized successfully"
    return $queueStatus
}

function Add-NotificationToQueue {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [hashtable]$Hook,
        
        [Parameter(Mandatory = $true)]
        [hashtable]$Context,
        
        [Parameter()]
        [ValidateSet('Critical', 'High', 'Normal', 'Low')]
        [string]$Priority = 'Normal'
    )
    
    Write-Verbose "Adding notification to queue with priority: $Priority"
    
    if ($script:NotificationQueue.Count -ge $script:NotificationConfig.QueueMaxSize) {
        Write-Warning "Queue is at maximum capacity ($($script:NotificationConfig.QueueMaxSize)). Removing oldest item."
        $script:NotificationQueue = $script:NotificationQueue[1..($script:NotificationQueue.Count - 1)]
    }
    
    $queueItem = @{
        Hook = $Hook.Clone()
        Context = $Context.Clone()
        Priority = $Priority
        QueuedAt = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
        Attempts = 0
        Status = 'Queued'
        LastAttempt = $null
        Error = $null
        Result = $null
    }
    
    # Insert based on priority
    $priorityValue = switch ($Priority) {
        'Critical' { 4 }
        'High' { 3 }
        'Normal' { 2 }
        'Low' { 1 }
    }
    
    $insertIndex = 0
    for ($i = 0; $i -lt $script:NotificationQueue.Count; $i++) {
        $itemPriority = switch ($script:NotificationQueue[$i].Priority) {
            'Critical' { 4 }
            'High' { 3 }
            'Normal' { 2 }
            'Low' { 1 }
        }
        
        if ($priorityValue -le $itemPriority) {
            $insertIndex = $i + 1
        }
        else {
            break
        }
    }
    
    if ($insertIndex -eq $script:NotificationQueue.Count) {
        $script:NotificationQueue += $queueItem
    }
    else {
        $newQueue = @()
        $newQueue += $script:NotificationQueue[0..($insertIndex - 1)]
        $newQueue += $queueItem
        $newQueue += $script:NotificationQueue[$insertIndex..($script:NotificationQueue.Count - 1)]
        $script:NotificationQueue = $newQueue
    }
    
    $script:NotificationMetrics.QueueSize = $script:NotificationQueue.Count
    
    Write-Verbose "Added notification to queue at position $insertIndex (Priority: $Priority)"
    return $insertIndex
}

function Process-NotificationQueue {
    [CmdletBinding()]
    param(
        [Parameter()]
        [int]$BatchSize = 5,
        
        [Parameter()]
        [int]$MaxProcessingTime = 300000  # 5 minutes in milliseconds
    )
    
    Write-Verbose "Processing notification queue (Batch size: $BatchSize)"
    
    if ($script:NotificationQueue.Count -eq 0) {
        Write-Verbose "Queue is empty"
        return @{ Processed = 0; Failed = 0; Remaining = 0 }
    }
    
    $processed = 0
    $failed = 0
    $startTime = Get-Date
    
    while ($script:NotificationQueue.Count -gt 0 -and $processed -lt $BatchSize) {
        # Check processing time limit
        if (((Get-Date) - $startTime).TotalMilliseconds -gt $MaxProcessingTime) {
            Write-Warning "Queue processing time limit reached"
            break
        }
        
        $item = $script:NotificationQueue[0]
        $script:NotificationQueue = $script:NotificationQueue[1..($script:NotificationQueue.Count - 1)]
        
        $item.Attempts++
        $item.LastAttempt = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
        $item.Status = 'Processing'
        
        try {
            Write-Verbose "Processing queued notification: $($item.Hook.Name)"
            
            $result = & $item.Hook.Action -Context $item.Context
            
            $item.Status = 'Completed'
            $item.Result = $result
            $processed++
            
            Write-Verbose "Successfully processed notification: $($item.Hook.Name)"
        }
        catch {
            Write-Warning "Failed to process notification $($item.Hook.Name): $_"
            
            $item.Status = 'Failed'
            $item.Error = $_.Exception.Message
            $failed++
            
            # Move to failed notifications
            $script:FailedNotifications += $item
            $script:NotificationMetrics.FailedQueueSize = $script:FailedNotifications.Count
        }
    }
    
    $script:NotificationMetrics.QueueSize = $script:NotificationQueue.Count
    
    Write-Verbose "Queue processing completed. Processed: $processed, Failed: $failed, Remaining: $($script:NotificationQueue.Count)"
    
    return @{
        Processed = $processed
        Failed = $failed
        Remaining = $script:NotificationQueue.Count
        ProcessingTime = ((Get-Date) - $startTime).TotalMilliseconds
    }
}

function Get-QueueStatus {
    [CmdletBinding()]
    param()
    
    Write-Verbose "Getting queue status"
    Write-Host "[QUEUE MODULE] Getting queue status..." -ForegroundColor Magenta
    
    # Access parent module state using Get-Module and scriptblock invocation
    $parentModule = Get-Module 'Unity-Claude-NotificationIntegration-Modular'
    Write-Host "[QUEUE MODULE] Parent module found: $($parentModule.Name)" -ForegroundColor DarkMagenta
    
    # Get queue data from parent module
    $queue = & $parentModule { Get-NotificationState -StateType 'Queue' }
    Write-Host "[QUEUE MODULE] Queue count from parent: $($queue.Count)" -ForegroundColor DarkMagenta
    
    $maxSize = & $parentModule { Get-NotificationState -StateType 'Config' -Property 'QueueMaxSize' }
    Write-Host "[QUEUE MODULE] MaxSize from parent: $maxSize" -ForegroundColor DarkMagenta
    
    $failedNotifications = & $parentModule { Get-NotificationState -StateType 'FailedNotifications' }
    Write-Host "[QUEUE MODULE] Failed notifications count from parent: $($failedNotifications.Count)" -ForegroundColor DarkMagenta
    
    $status = @{
        QueueSize = $queue.Count
        MaxSize = $maxSize
        FailedSize = $failedNotifications.Count
        PersistenceEnabled = $false  # Not implemented yet
        QueuedItems = @()
        OldestQueued = $null
    }
    
    if ($queue.Count -gt 0) {
        $status.OldestQueued = $queue[0].QueuedAt
        
        foreach ($item in $queue) {
            $status.QueuedItems += @{
                HookName = $item.Hook.Name
                Priority = $item.Priority
                QueuedAt = $item.QueuedAt
                Attempts = $item.Attempts
                Status = $item.Status
            }
        }
    }
    
    return $status
}

function Clear-NotificationQueue {
    [CmdletBinding()]
    param(
        [Parameter()]
        [switch]$IncludeFailed
    )
    
    Write-Verbose "Clearing notification queue"
    
    $queuedCount = $script:NotificationQueue.Count
    $failedCount = $script:FailedNotifications.Count
    
    $script:NotificationQueue = @()
    $script:NotificationMetrics.QueueSize = 0
    
    if ($IncludeFailed) {
        $script:FailedNotifications = @()
        $script:NotificationMetrics.FailedQueueSize = 0
        Write-Verbose "Cleared $queuedCount queued and $failedCount failed notifications"
    }
    else {
        Write-Verbose "Cleared $queuedCount queued notifications"
    }
    
    return @{
        ClearedQueued = $queuedCount
        ClearedFailed = if ($IncludeFailed) { $failedCount } else { 0 }
    }
}

function Get-FailedNotifications {
    [CmdletBinding()]
    param(
        [Parameter()]
        [int]$Limit = 50
    )
    
    Write-Verbose "Getting failed notifications (Limit: $Limit)"
    
    $failed = $script:FailedNotifications
    
    if ($Limit -gt 0 -and $failed.Count -gt $Limit) {
        $failed = $failed[-$Limit..-1]  # Get most recent failures
    }
    
    return $failed
}

#endregion

# Export functions
Export-ModuleMember -Function @(
    'Initialize-NotificationQueue',
    'Add-NotificationToQueue',
    'Process-NotificationQueue',
    'Get-QueueStatus',
    'Clear-NotificationQueue',
    'Get-FailedNotifications'
)

Write-Verbose "QueueManagement module loaded successfully"
# SIG # Begin signature block
# MIIFqQYJKoZIhvcNAQcCoIIFmjCCBZYCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUDQVKSae/VSyh4xzm93V2VWVs
# 46ygggMwMIIDLDCCAhSgAwIBAgIQdR0W2SKoK5VE8JId4ZxrRTANBgkqhkiG9w0B
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
# CQQxFgQUUZJzhczPo9EbRFfPnWKz2X/ax/cwDQYJKoZIhvcNAQEBBQAEggEAh71M
# m7unwINMH/uO6K1h83IlGXBY3mfzd4wghS+SraxHhhzs5IrPg32ffcNBktWFh1Dg
# ZTykMdn3m1XcmLHFCDHnpKnLp1mR8lUOPvUDYZbBAq2rZzR4aPeJXBF7zgXVyhmF
# W4/kb9QGIUNNUbxKuvqQFHMS3rTRK1zp+2rEUZ6372dRAavkuiQ8/Oo5y9S/uT+r
# DMo3CrKyzwbEoU76o9LNRbmv8Lp2y4yGZavjR2CiRg89WozxpxeRzPZsxQyRKq3n
# gwGGnNHpdyRqL8OP6D0pr2v/uXM3x+jBOFyRqKiMXjaQzL/wceAEYaYUgL6PY3Lr
# KUUBRHcOYsu8cjI0vg==
# SIG # End signature block
