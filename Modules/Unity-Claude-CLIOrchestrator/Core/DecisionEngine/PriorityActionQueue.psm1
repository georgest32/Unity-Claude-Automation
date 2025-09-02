# PriorityActionQueue.psm1
# Priority-based action queue management for DecisionEngine
# Part of Unity-Claude-CLIOrchestrator refactored architecture
# Date: 2025-08-25

#region Priority-Based Action Queue

# Action queue management
$script:ActionQueue = @()
$script:QueueLock = New-Object System.Threading.Mutex($false, "CLIOrchestratorQueue")

# Test action queue capacity
function Test-ActionQueueCapacity {
    [CmdletBinding()]
    param()
    
    # Get configuration
    $decisionConfig = Get-DecisionEngineConfiguration
    
    $currentSize = $script:ActionQueue.Count
    $maxSize = $decisionConfig.ActionQueue.MaxQueueSize
    
    return @{
        HasCapacity = $currentSize -lt $maxSize
        CurrentSize = $currentSize
        MaxSize = $maxSize
        AvailableSlots = [Math]::Max(0, $maxSize - $currentSize)
    }
}

# Create new action queue item
function New-ActionQueueItem {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [hashtable]$Decision,
        
        [Parameter(Mandatory = $true)]
        [hashtable]$AnalysisResult,
        
        [Parameter()]
        [switch]$DryRun
    )
    
    Write-DecisionLog "Creating action queue item for: $($Decision.RecommendationType)" "DEBUG"
    
    try {
        # Get configuration
        $decisionConfig = Get-DecisionEngineConfiguration
        
        # Get decision matrix entry
        $matrixEntry = $decisionConfig.DecisionMatrix[$Decision.RecommendationType]
        if (-not $matrixEntry) {
            throw "Unknown recommendation type: $($Decision.RecommendationType)"
        }
        
        # Calculate estimated execution time
        $baseTime = $matrixEntry.TimeoutSeconds
        $complexityMultiplier = switch ($Decision.SafetyLevel) {
            "High" { 1.5 }
            "Medium" { 1.2 }
            "Low" { 1.0 }
            default { 1.0 }
        }
        $estimatedTime = [int]($baseTime * $complexityMultiplier)
        
        # Generate unique action ID
        $actionId = "CLIOrchestratorAction_$($Decision.RecommendationType)_$(Get-Date -Format 'yyyyMMdd_HHmmss_fff')"
        
        $queueItem = @{
            # Core Identification
            ActionId = $actionId
            RecommendationType = $Decision.RecommendationType
            ActionType = $Decision.ActionType
            
            # Execution Parameters
            Action = $Decision.Action
            Priority = $Decision.Priority
            SafetyLevel = $Decision.SafetyLevel
            MaxRetryAttempts = $matrixEntry.MaxRetryAttempts
            TimeoutSeconds = $matrixEntry.TimeoutSeconds
            EstimatedExecutionTime = $estimatedTime
            
            # Context Information
            SourceAnalysis = $AnalysisResult
            ConfidenceScore = $Decision.Confidence
            
            # Queue Management
            QueuedTime = Get-Date
            QueuePosition = $script:ActionQueue.Count + 1
            Status = "Queued"
            DryRun = $DryRun.IsPresent
            
            # Retry Logic
            RetryCount = 0
            LastAttempt = $null
            LastError = $null
        }
        
        # Add to queue if not dry run
        if (-not $DryRun) {
            try {
                $script:QueueLock.WaitOne(1000) | Out-Null
                $script:ActionQueue += $queueItem
                Write-DecisionLog "Action queued: $actionId (Position: $($queueItem.QueuePosition))" "SUCCESS"
            } finally {
                $script:QueueLock.ReleaseMutex()
            }
        } else {
            Write-DecisionLog "DRY RUN: Action would be queued: $actionId" "INFO"
        }
        
        return $queueItem
        
    } catch {
        Write-DecisionLog "Failed to create queue item: $($_.Exception.Message)" "ERROR"
        throw
    }
}

# Get current action queue status
function Get-ActionQueueStatus {
    [CmdletBinding()]
    param(
        [Parameter()]
        [switch]$IncludeDetails
    )
    
    try {
        $script:QueueLock.WaitOne(1000) | Out-Null
        
        $queueStatus = @{
            TotalItems = $script:ActionQueue.Count
            QueuedItems = ($script:ActionQueue | Where-Object { $_.Status -eq "Queued" }).Count
            ExecutingItems = ($script:ActionQueue | Where-Object { $_.Status -eq "Executing" }).Count
            CompletedItems = ($script:ActionQueue | Where-Object { $_.Status -eq "Completed" }).Count
            FailedItems = ($script:ActionQueue | Where-Object { $_.Status -eq "Failed" }).Count
            Capacity = Test-ActionQueueCapacity
            LastUpdate = Get-Date -Format "yyyy-MM-dd HH:mm:ss.fff"
        }
        
        if ($IncludeDetails -and $script:ActionQueue.Count -gt 0) {
            $queueStatus.QueueDetails = $script:ActionQueue | ForEach-Object {
                @{
                    ActionId = $_.ActionId
                    Type = $_.RecommendationType
                    Priority = $_.Priority
                    Status = $_.Status
                    QueuedTime = $_.QueuedTime
                    EstimatedTime = $_.EstimatedExecutionTime
                }
            }
        }
        
        return $queueStatus
        
    } finally {
        $script:QueueLock.ReleaseMutex()
    }
}

# Clear completed or failed actions from queue
function Clear-ActionQueue {
    [CmdletBinding()]
    param(
        [Parameter()]
        [ValidateSet("Completed", "Failed", "All")]
        [string]$Status = "Completed"
    )
    
    try {
        $script:QueueLock.WaitOne(1000) | Out-Null
        
        $originalCount = $script:ActionQueue.Count
        
        if ($Status -eq "All") {
            $script:ActionQueue = @()
        } else {
            $script:ActionQueue = @($script:ActionQueue | Where-Object { $_.Status -ne $Status })
        }
        
        $clearedCount = $originalCount - $script:ActionQueue.Count
        Write-DecisionLog "Cleared $clearedCount actions with status '$Status' from queue" "INFO"
        
        return @{
            ClearedCount = $clearedCount
            RemainingCount = $script:ActionQueue.Count
            Status = $Status
        }
        
    } finally {
        $script:QueueLock.ReleaseMutex()
    }
}

# Update action status
function Update-ActionStatus {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$ActionId,
        
        [Parameter(Mandatory = $true)]
        [ValidateSet("Queued", "Executing", "Completed", "Failed")]
        [string]$Status,
        
        [Parameter()]
        [string]$ErrorMessage
    )
    
    try {
        $script:QueueLock.WaitOne(1000) | Out-Null
        
        $action = $script:ActionQueue | Where-Object { $_.ActionId -eq $ActionId }
        if ($action) {
            $action.Status = $Status
            $action.LastAttempt = Get-Date
            
            if ($ErrorMessage) {
                $action.LastError = $ErrorMessage
                $action.RetryCount++
            }
            
            Write-DecisionLog "Updated action $ActionId status to '$Status'" "DEBUG"
            return $true
        } else {
            Write-DecisionLog "Action $ActionId not found in queue" "WARN"
            return $false
        }
        
    } finally {
        $script:QueueLock.ReleaseMutex()
    }
}

# Export functions
Export-ModuleMember -Function @(
    'Test-ActionQueueCapacity',
    'New-ActionQueueItem',
    'Get-ActionQueueStatus',
    'Clear-ActionQueue',
    'Update-ActionStatus'
)

#endregion
# SIG # Begin signature block
# MIIFzgYJKoZIhvcNAQcCoIIFvzCCBbsCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCA6DY0kAuovhSBR
# 9K08CE+sReKKuezoVtQXaSDRLl/6yKCCAzAwggMsMIICFKADAgECAhB1HRbZIqgr
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
# MAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIM7r/nrTynZS4r+WPHIFAm0e
# KfGZZWdFCLIblEgQoqXoMA0GCSqGSIb3DQEBAQUABIIBAEsUXXebnhA900RXHlaQ
# K1oS0p8cYvUqbKuv/AgDgSo11CqxjaJT0Zk4O4Vpb0q6filvtcNOhVe9bKd2JEHq
# phiDPI7Fz6PzTTrbgA2K++AwjAujCWbHqi1tqd3LBxTvLeyMjLG6JLosFDG197UZ
# Ljs/5m8xEN+8fhoSAdapSDwANdEgMZYtOHsChBly0TaGK2Hr6ogXl6rwXmoqRxwz
# 5qrZL2YFwX+4Kfmy3atEvnUiUlsta/1DQrIDrcXDbmdCMWEvhxOfgxPFjG4fa6Tr
# 3sYdVte2eMZVS7l51lSul/0rZcZL/DUIGIEKNZCCsmYu31CLvWSu1dqDABpilmzo
# heA=
# SIG # End signature block
