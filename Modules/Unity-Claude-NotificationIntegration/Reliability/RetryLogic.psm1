# RetryLogic.psm1
# Retry logic and reliability features for notifications
# Date: 2025-08-21

#region Retry Logic Functions

function New-NotificationRetryPolicy {
    [CmdletBinding()]
    param(
        [Parameter()]
        [int]$MaxRetries = 3,
        
        [Parameter()]
        [int]$BaseDelay = 1000,  # milliseconds
        
        [Parameter()]
        [int]$MaxDelay = 30000,  # milliseconds
        
        [Parameter()]
        [double]$BackoffMultiplier = 2.0,
        
        [Parameter()]
        [switch]$UseJitter
    )
    
    Write-Verbose "Creating notification retry policy (MaxRetries: $MaxRetries, BaseDelay: $BaseDelay ms)"
    
    $policy = @{
        MaxRetries = $MaxRetries
        BaseDelay = $BaseDelay
        MaxDelay = $MaxDelay
        BackoffMultiplier = $BackoffMultiplier
        UseJitter = $UseJitter.IsPresent
        CreatedAt = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
    }
    
    return $policy
}

function Invoke-NotificationWithRetry {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [scriptblock]$ScriptBlock,
        
        [Parameter()]
        [hashtable]$RetryPolicy = @{},
        
        [Parameter()]
        [hashtable]$Parameters = @{}
    )
    
    Write-Verbose "Invoking notification with retry logic"
    
    # Apply default retry policy if not provided
    if ($RetryPolicy.Count -eq 0) {
        $RetryPolicy = @{
            MaxRetries = $script:NotificationConfig.MaxRetries
            BaseDelay = $script:NotificationConfig.RetryBaseDelay
            MaxDelay = $script:NotificationConfig.RetryMaxDelay
            BackoffMultiplier = 2.0
            UseJitter = $true
        }
    }
    
    $attempt = 0
    $lastError = $null
    
    while ($attempt -le $RetryPolicy.MaxRetries) {
        try {
            Write-Verbose "Attempt $attempt of $($RetryPolicy.MaxRetries)"
            
            $result = & $ScriptBlock @Parameters
            
            if ($attempt -gt 0) {
                $script:NotificationMetrics.TotalRetries++
            }
            
            Write-Verbose "Notification succeeded on attempt $attempt"
            return $result
        }
        catch {
            $lastError = $_
            $attempt++
            
            if ($attempt -le $RetryPolicy.MaxRetries) {
                $delay = Calculate-RetryDelay -RetryPolicy $RetryPolicy -Attempt $attempt
                Write-Verbose "Attempt $attempt failed: $($_.Exception.Message). Retrying in $delay ms..."
                Start-Sleep -Milliseconds $delay
            }
            else {
                Write-Error "All retry attempts failed. Last error: $($_.Exception.Message)"
                $script:NotificationMetrics.TotalFailed++
                throw $lastError
            }
        }
    }
}

function Test-NotificationDelivery {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [hashtable]$TestContext,
        
        [Parameter()]
        [int]$Timeout = 30000  # milliseconds
    )
    
    Write-Verbose "Testing notification delivery"
    
    $startTime = Get-Date
    
    try {
        $result = Send-IntegratedNotification -TemplateName 'TestNotification' -Severity 'Info' -Data $TestContext.Data -Channels $TestContext.Channels
        
        $deliveryTime = ((Get-Date) - $startTime).TotalMilliseconds
        
        if ($result.Status -eq 'Success' -or $result.Status -eq 'Fallback') {
            Write-Verbose "Notification delivery test successful (${deliveryTime}ms)"
            return @{
                Success = $true
                DeliveryTime = $deliveryTime
                Result = $result
                TestTime = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
            }
        }
        else {
            Write-Warning "Notification delivery test failed: $($result.Error)"
            return @{
                Success = $false
                DeliveryTime = $deliveryTime
                Error = $result.Error
                TestTime = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
            }
        }
    }
    catch {
        $deliveryTime = ((Get-Date) - $startTime).TotalMilliseconds
        Write-Error "Notification delivery test failed: $_"
        return @{
            Success = $false
            DeliveryTime = $deliveryTime
            Error = $_.Exception.Message
            TestTime = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
        }
    }
}

function Get-NotificationDeliveryStatus {
    [CmdletBinding()]
    param()
    
    Write-Verbose "Getting notification delivery status"
    
    return @{
        CircuitBreakerState = $script:CircuitBreaker.State
        TotalSent = $script:NotificationMetrics.TotalSent
        TotalFailed = $script:NotificationMetrics.TotalFailed
        TotalRetries = $script:NotificationMetrics.TotalRetries
        SuccessRate = if ($script:NotificationMetrics.TotalSent -gt 0) { 
            [math]::Round((($script:NotificationMetrics.TotalSent - $script:NotificationMetrics.TotalFailed) / $script:NotificationMetrics.TotalSent) * 100, 2)
        } else { 0 }
        LastDeliveryTime = $script:NotificationMetrics.LastDeliveryTime
        QueueSize = $script:NotificationMetrics.QueueSize
        FailedQueueSize = $script:NotificationMetrics.FailedQueueSize
    }
}

function Reset-NotificationRetryState {
    [CmdletBinding()]
    param()
    
    Write-Verbose "Resetting notification retry state"
    
    # Reset circuit breaker
    $script:CircuitBreaker.State = 'Closed'
    $script:CircuitBreaker.FailureCount = 0
    $script:CircuitBreaker.LastFailureTime = $null
    $script:CircuitBreaker.NextRetryTime = $null
    
    # Reset retry metrics
    $script:NotificationMetrics.TotalRetries = 0
    
    Write-Verbose "Retry state reset successfully"
}

#endregion

#region Helper Functions

function Calculate-RetryDelay {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [hashtable]$RetryPolicy,
        
        [Parameter(Mandatory = $true)]
        [int]$Attempt
    )
    
    $delay = $RetryPolicy.BaseDelay * [math]::Pow($RetryPolicy.BackoffMultiplier, $Attempt - 1)
    
    # Cap at maximum delay
    $delay = [math]::Min($delay, $RetryPolicy.MaxDelay)
    
    # Add jitter if enabled
    if ($RetryPolicy.UseJitter) {
        $jitter = Get-Random -Minimum 0 -Maximum ($delay * 0.1)
        $delay += $jitter
    }
    
    return [int]$delay
}

#endregion

# Export functions
Export-ModuleMember -Function @(
    'New-NotificationRetryPolicy',
    'Invoke-NotificationWithRetry',
    'Test-NotificationDelivery',
    'Get-NotificationDeliveryStatus',
    'Reset-NotificationRetryState'
)

Write-Verbose "RetryLogic module loaded successfully"
# SIG # Begin signature block
# MIIFqQYJKoZIhvcNAQcCoIIFmjCCBZYCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUu3SVahFmEr7jGqCItc18/Iua
# RHagggMwMIIDLDCCAhSgAwIBAgIQdR0W2SKoK5VE8JId4ZxrRTANBgkqhkiG9w0B
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
# CQQxFgQUYWFEtm+5S7mPBP6kRXagebwc1iwwDQYJKoZIhvcNAQEBBQAEggEACX6N
# MdcMw7w3337kIJA9DKhsrDJ3gUKY/EN2MUGXOj+FDdOdAzloTFuA9sUI9i4lYF0A
# DShm+StfD+bfLLIWVxXSOGCXtidjHcScxy2y/2frs5ay0qsLQ7vJu1UKjCfFjJnh
# DRnGjk4G6u7p7Ctfq0nlnrO0LqZ3Rzvr+7SIQX14UG4O4yRVD6AXrV1c1x5xgEtb
# eZsW6V4kbryzORI02b4uK20c8KClp6IoF/xqx/nb6QyHQ2DHsnwoxoACtPxiy2br
# 3ng7Hc+PBLWcJAR/MNp7c/sVFsEcA1MnioICJNFuNVsUo+q7mAaskwQv7SUeBlIc
# XGZui0IdOWMrqlEMng==
# SIG # End signature block
