# Unity-Claude-NotificationIntegration.psm1
# Week 6 Days 1-2: System Integration - Notification triggers for Unity-Claude autonomous workflow
# Integrates notification system with existing autonomous agent workflow
# Date: 2025-08-21

$ErrorActionPreference = "Stop"

# Module-level variables
$script:NotificationIntegrationConfig = @{
    Enabled = $false
    EmailEnabled = $true
    WebhookEnabled = $true
    DefaultSeverity = "Info"
    MaxRetries = 3
    RetryDelay = 5000
    ExponentialBackoffEnabled = $true
    BackoffMultiplier = 2
    MaxBackoffDelay = 300000  # 5 minutes
    ChannelSwitchingEnabled = $true
    QueuePersistenceEnabled = $true
    NotificationQueue = @()
    FailedNotificationQueue = @()
    DeadLetterQueue = @()
    TriggerPoints = @{}
    CircuitBreaker = @{
        EmailState = "Closed"  # Closed, Open, HalfOpen
        WebhookState = "Closed"
        EmailFailureCount = 0
        WebhookFailureCount = 0
        EmailLastFailure = $null
        WebhookLastFailure = $null
        FailureThreshold = 5
        RecoveryTimeout = 300000  # 5 minutes
    }
}

$script:IntegrationStats = @{
    NotificationsSent = 0
    NotificationsFailed = 0
    EmailNotifications = 0
    WebhookNotifications = 0
    CriticalNotifications = 0
    LastNotification = $null
}

# Dot-source additional function files (PowerShell 5.1 compatible)
$AdditionalFunctions = @(
    "Get-NotificationConfiguration.ps1",
    "Test-NotificationSystemHealth.ps1", 
    "Register-NotificationTriggers.ps1",
    "Send-NotificationEvents.ps1",
    "Enhanced-NotificationReliability.ps1"
)

foreach ($FunctionFile in $AdditionalFunctions) {
    $FunctionPath = Join-Path -Path $PSScriptRoot -ChildPath $FunctionFile
    if (Test-Path $FunctionPath) {
        try {
            . $FunctionPath
            Write-SystemStatusLog "Successfully loaded functions from $FunctionFile" -Level 'DEBUG'
        } catch {
            Write-SystemStatusLog "Failed to load functions from $FunctionFile : $($_.Exception.Message)" -Level 'ERROR'
        }
    } else {
        Write-SystemStatusLog "Function file not found: $FunctionPath" -Level 'WARN'
    }
}

# Import required modules with error handling
try {
    Import-Module Unity-Claude-EmailNotifications -ErrorAction Stop
    Import-Module Unity-Claude-WebhookNotifications -ErrorAction Stop
    Import-Module Unity-Claude-NotificationContentEngine -ErrorAction Stop
    Import-Module Unity-Claude-SystemStatus -ErrorAction Stop
    Write-Host "[NotificationIntegration] Required notification modules imported successfully" -ForegroundColor Green
} catch {
    Write-Warning "[NotificationIntegration] Failed to import required modules: $($_.Exception.Message)"
}

function Initialize-NotificationIntegration {
    [CmdletBinding()]
    param(
        [hashtable]$EmailConfig = @{},
        [hashtable]$WebhookConfig = @{},
        [string[]]$EnabledTriggers = @("UnityError", "ClaudeSubmission", "WorkflowStatus", "SystemHealth")
    )
    
    Write-Host "[NotificationIntegration] Initializing notification integration system..." -ForegroundColor Cyan
    
    try {
        $emailAvailable = Get-Command Send-EmailNotification -ErrorAction SilentlyContinue
        $webhookAvailable = Get-Command Send-WebhookNotification -ErrorAction SilentlyContinue
        
        if (-not $emailAvailable) {
            Write-Warning "[NotificationIntegration] Email notification module not available"
            $script:NotificationIntegrationConfig.EmailEnabled = $false
        }
        
        if (-not $webhookAvailable) {
            Write-Warning "[NotificationIntegration] Webhook notification module not available"
            $script:NotificationIntegrationConfig.WebhookEnabled = $false
        }
        
        foreach ($trigger in $EnabledTriggers) {
            $script:NotificationIntegrationConfig.TriggerPoints[$trigger] = @{
                Enabled = $true
                Count = 0
                LastTriggered = $null
            }
            Write-Host "[NotificationIntegration] Enabled trigger: $trigger" -ForegroundColor Green
        }
        
        $script:NotificationIntegrationConfig.Enabled = $true
        
        if (Get-Command Write-SystemStatus -ErrorAction SilentlyContinue) {
            $status = Read-SystemStatus
            if ($status) {
                if (-not $status.Subsystems) { $status.Subsystems = @{} }
                $status.Subsystems["NotificationIntegration"] = @{
                    Status = "Running"
                    HealthScore = 100
                    LastStarted = Get-Date -Format 'yyyy-MM-dd HH:mm:ss.fff'
                    EnabledTriggers = $EnabledTriggers -join ', '
                    EmailEnabled = $script:NotificationIntegrationConfig.EmailEnabled
                    WebhookEnabled = $script:NotificationIntegrationConfig.WebhookEnabled
                }
                Write-SystemStatus -StatusData $status
            }
        }
        
        Write-Host "[NotificationIntegration] Notification integration initialized successfully" -ForegroundColor Green
        return @{
            Success = $true
            EmailEnabled = $script:NotificationIntegrationConfig.EmailEnabled
            WebhookEnabled = $script:NotificationIntegrationConfig.WebhookEnabled
            EnabledTriggers = $EnabledTriggers
        }
        
    } catch {
        Write-Error "[NotificationIntegration] Failed to initialize: $($_.Exception.Message)"
        return @{ Success = $false; Error = $_.Exception.Message }
    }
}

function Send-UnityErrorNotification {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [hashtable]$ErrorDetails,
        [ValidateSet("Critical", "Error", "Warning")]
        [string]$Severity = "Error"
    )
    
    if (-not $script:NotificationIntegrationConfig.Enabled -or 
        -not $script:NotificationIntegrationConfig.TriggerPoints.ContainsKey("UnityError")) {
        return
    }
    
    try {
        $content = @{
            Subject = "Unity Compilation Error Detected"
            Body = "Unity compilation error: $($ErrorDetails.ErrorType) - $($ErrorDetails.Message)"
            Severity = $Severity
            Category = "UnityError"
            Timestamp = Get-Date
            Details = $ErrorDetails
        }
        
        $result = Send-IntegratedNotification -Content $content
        
        $script:NotificationIntegrationConfig.TriggerPoints["UnityError"].Count++
        $script:NotificationIntegrationConfig.TriggerPoints["UnityError"].LastTriggered = Get-Date
        
        return $result
        
    } catch {
        Write-Error "[NotificationIntegration] Failed to send Unity error notification: $($_.Exception.Message)"
        $script:IntegrationStats.NotificationsFailed++
    }
}

function Send-ClaudeSubmissionNotification {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [hashtable]$SubmissionResult,
        [bool]$IsSuccess = $true
    )
    
    if (-not $script:NotificationIntegrationConfig.Enabled -or 
        -not $script:NotificationIntegrationConfig.TriggerPoints.ContainsKey("ClaudeSubmission")) {
        return
    }
    
    try {
        $severity = if ($IsSuccess) { "Info" } else { "Error" }
        $subject = if ($IsSuccess) { "Claude Submission Successful" } else { "Claude Submission Failed" }
        $body = if ($IsSuccess) { 
            "Claude successfully processed submission: $($SubmissionResult.Response)" 
        } else { 
            "Claude submission failed: $($SubmissionResult.Error)" 
        }
        
        $content = @{
            Subject = $subject
            Body = $body
            Severity = $severity
            Category = "ClaudeSubmission"
            Timestamp = Get-Date
            Details = $SubmissionResult
        }
        
        $result = Send-IntegratedNotification -Content $content
        
        $script:NotificationIntegrationConfig.TriggerPoints["ClaudeSubmission"].Count++
        $script:NotificationIntegrationConfig.TriggerPoints["ClaudeSubmission"].LastTriggered = Get-Date
        
        return $result
        
    } catch {
        Write-Error "[NotificationIntegration] Failed to send Claude submission notification: $($_.Exception.Message)"
        $script:IntegrationStats.NotificationsFailed++
    }
}

function Send-IntegratedNotification {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [hashtable]$Content,
        [switch]$ForceAllChannels
    )
    
    $results = @{}
    
    try {
        if (Get-Command New-NotificationContent -ErrorAction SilentlyContinue) {
            $notificationContent = New-NotificationContent -Subject $Content.Subject -Body $Content.Body -Severity $Content.Severity -Category $Content.Category
        } else {
            $notificationContent = @{
                Subject = $Content.Subject
                Body = $Content.Body
                Severity = $Content.Severity
                Category = $Content.Category
            }
        }
        
        if ($script:NotificationIntegrationConfig.EmailEnabled -or $ForceAllChannels) {
            try {
                if (Get-Command Send-EmailNotification -ErrorAction SilentlyContinue) {
                    $emailResult = Send-EmailNotification -Subject $notificationContent.Subject -Body $notificationContent.Body
                    $results.Email = $emailResult
                    $script:IntegrationStats.EmailNotifications++
                }
            } catch {
                Write-Warning "[NotificationIntegration] Email notification failed: $($_.Exception.Message)"
                $results.Email = @{ Success = $false; Error = $_.Exception.Message }
            }
        }
        
        if ($script:NotificationIntegrationConfig.WebhookEnabled -or $ForceAllChannels) {
            try {
                if (Get-Command Send-WebhookNotification -ErrorAction SilentlyContinue) {
                    $webhookResult = Send-WebhookNotification -ConfigurationName "DefaultWebhook" -EventType "Integration" -EventData $notificationContent
                    $results.Webhook = $webhookResult
                    $script:IntegrationStats.WebhookNotifications++
                }
            } catch {
                Write-Warning "[NotificationIntegration] Webhook notification failed: $($_.Exception.Message)"
                $results.Webhook = @{ Success = $false; Error = $_.Exception.Message }
            }
        }
        
        $script:IntegrationStats.NotificationsSent++
        $script:IntegrationStats.LastNotification = Get-Date
        
        return $results
        
    } catch {
        Write-Error "[NotificationIntegration] Failed to send integrated notification: $($_.Exception.Message)"
        $script:IntegrationStats.NotificationsFailed++
        throw
    }
}

function Test-NotificationReliability {
    [CmdletBinding()]
    param(
        [int]$ConcurrentNotifications = 10,
        [int]$TestDuration = 60,
        [switch]$SimulateFailures
    )
    
    Write-Host "[NotificationIntegration] Starting notification reliability test..." -ForegroundColor Cyan
    Write-Host "Test parameters: $ConcurrentNotifications concurrent notifications, ${TestDuration}s duration" -ForegroundColor Gray
    
    $testResults = @{
        StartTime = Get-Date
        TotalNotifications = 0
        SuccessfulNotifications = 0
        FailedNotifications = 0
        AverageResponseTime = 0
        ResponseTimes = @()
    }
    
    $endTime = (Get-Date).AddSeconds($TestDuration)
    
    while ((Get-Date) -lt $endTime) {
        # Send test notifications
        for ($i = 0; $i -lt $ConcurrentNotifications; $i++) {
            $startTime = Get-Date
            try {
                $result = Send-UnityErrorNotification -ErrorDetails @{
                    ErrorType = "TEST_RELIABILITY"
                    Message = "Reliability test notification $(Get-Random)"
                    File = "TestFile.cs"
                    Line = (Get-Random -Minimum 1 -Maximum 100)
                } -Severity "Warning"
                
                $endTime = Get-Date
                $responseTime = ($endTime - $startTime).TotalMilliseconds
                
                $testResults.TotalNotifications++
                $testResults.ResponseTimes += $responseTime
                
                if ($result) {
                    $testResults.SuccessfulNotifications++
                } else {
                    $testResults.FailedNotifications++
                }
            } catch {
                $testResults.TotalNotifications++
                $testResults.FailedNotifications++
            }
        }
        
        Start-Sleep -Milliseconds 100
    }
    
    # Calculate averages
    if ($testResults.ResponseTimes.Count -gt 0) {
        $testResults.AverageResponseTime = ($testResults.ResponseTimes | Measure-Object -Average).Average
    }
    
    $testResults.EndTime = Get-Date
    $testResults.TestDuration = ($testResults.EndTime - $testResults.StartTime).TotalSeconds
    $testResults.SuccessRate = if ($testResults.TotalNotifications -gt 0) {
        [math]::Round(($testResults.SuccessfulNotifications / $testResults.TotalNotifications) * 100, 2)
    } else { 0 }
    
    Write-Host "[NotificationIntegration] Reliability test completed" -ForegroundColor Green
    Write-Host "Results: $($testResults.SuccessfulNotifications)/$($testResults.TotalNotifications) successful ($($testResults.SuccessRate)%)" -ForegroundColor Green
    Write-Host "Average response time: $([math]::Round($testResults.AverageResponseTime, 2))ms" -ForegroundColor Green
    
    return $testResults
}

function Get-NotificationQueueStatus {
    [CmdletBinding()]
    param()
    
    return @{
        ActiveQueue = $script:NotificationIntegrationConfig.NotificationQueue.Count
        FailedQueue = $script:NotificationIntegrationConfig.FailedNotificationQueue.Count
        DeadLetterQueue = $script:NotificationIntegrationConfig.DeadLetterQueue.Count
        CircuitBreakerStates = @{
            Email = $script:NotificationIntegrationConfig.CircuitBreaker.EmailState
            Webhook = $script:NotificationIntegrationConfig.CircuitBreaker.WebhookState
        }
        FailureCounts = @{
            Email = $script:NotificationIntegrationConfig.CircuitBreaker.EmailFailureCount
            Webhook = $script:NotificationIntegrationConfig.CircuitBreaker.WebhookFailureCount
        }
    }
}

function Test-NotificationIntegration {
    [CmdletBinding()]
    param()
    
    Write-Host "[NotificationIntegration] Testing notification integration system..." -ForegroundColor Cyan
    
    try {
        $testResults = @{}
        
        $testResults.UnityError = Send-UnityErrorNotification -ErrorDetails @{
            ErrorType = "TEST"
            Message = "Test Unity error notification"
            File = "TestScript.cs"
            Line = 42
        } -Severity "Warning"
        
        $testResults.ClaudeSubmission = Send-ClaudeSubmissionNotification -SubmissionResult @{
            Response = "Test Claude submission successful"
            Timestamp = Get-Date
        } -IsSuccess $true
        
        Write-Host "[NotificationIntegration] Notification integration test completed" -ForegroundColor Green
        return $testResults
        
    } catch {
        Write-Error "[NotificationIntegration] Test failed: $($_.Exception.Message)"
        throw
    }
}

function Test-NotificationReliability {
    [CmdletBinding()]
    param(
        [int]$ConcurrentNotifications = 10,
        [int]$TestDuration = 60,
        [switch]$SimulateFailures
    )
    
    Write-Host "[NotificationIntegration] Starting notification reliability test..." -ForegroundColor Cyan
    Write-Host "Test parameters: $ConcurrentNotifications concurrent notifications, ${TestDuration}s duration" -ForegroundColor Gray
    
    $testResults = @{
        StartTime = Get-Date
        TotalNotifications = 0
        SuccessfulNotifications = 0
        FailedNotifications = 0
        RetryAttempts = 0
        CircuitBreakerTriggered = $false
        AverageResponseTime = 0
        ResponseTimes = @()
    }
    
    $endTime = (Get-Date).AddSeconds($TestDuration)
    
    while ((Get-Date) -lt $endTime) {
        $jobs = @()
        
        # Start concurrent notification jobs
        for ($i = 0; $i -lt $ConcurrentNotifications; $i++) {
            $job = Start-Job -ScriptBlock {
                param($NotificationData, $SimulateFailures)
                
                $startTime = Get-Date
                try {
                    # Simulate random failures if requested
                    if ($SimulateFailures -and (Get-Random -Maximum 100) -lt 20) {
                        throw "Simulated failure for testing"
                    }
                    
                    # Send test notification
                    $result = Send-UnityErrorNotification -ErrorDetails $NotificationData -Severity "Warning"
                    $endTime = Get-Date
                    
                    return @{
                        Success = $true
                        ResponseTime = ($endTime - $startTime).TotalMilliseconds
                        Result = $result
                    }
                } catch {
                    $endTime = Get-Date
                    return @{
                        Success = $false
                        ResponseTime = ($endTime - $startTime).TotalMilliseconds
                        Error = $_.Exception.Message
                    }
                }
            } -ArgumentList @(@{
                ErrorType = "TEST_RELIABILITY"
                Message = "Reliability test notification $(Get-Random)"
                File = "TestFile.cs"
                Line = (Get-Random -Minimum 1 -Maximum 100)
            }, $SimulateFailures)
            
            $jobs += $job
        }
        
        # Wait for jobs to complete
        $jobResults = $jobs | Wait-Job | Receive-Job
        $jobs | Remove-Job
        
        # Process results
        foreach ($result in $jobResults) {
            $testResults.TotalNotifications++
            $testResults.ResponseTimes += $result.ResponseTime
            
            if ($result.Success) {
                $testResults.SuccessfulNotifications++
            } else {
                $testResults.FailedNotifications++
            }
        }
        
        Start-Sleep -Milliseconds 500
    }
    
    # Calculate averages
    if ($testResults.ResponseTimes.Count -gt 0) {
        $testResults.AverageResponseTime = ($testResults.ResponseTimes | Measure-Object -Average).Average
    }
    
    $testResults.EndTime = Get-Date
    $testResults.TestDuration = ($testResults.EndTime - $testResults.StartTime).TotalSeconds
    $testResults.SuccessRate = if ($testResults.TotalNotifications -gt 0) {
        [math]::Round(($testResults.SuccessfulNotifications / $testResults.TotalNotifications) * 100, 2)
    } else { 0 }
    
    Write-Host "[NotificationIntegration] Reliability test completed" -ForegroundColor Green
    Write-Host "Results: $($testResults.SuccessfulNotifications)/$($testResults.TotalNotifications) successful ($($testResults.SuccessRate)%)" -ForegroundColor Green
    Write-Host "Average response time: $([math]::Round($testResults.AverageResponseTime, 2))ms" -ForegroundColor Green
    
    return $testResults
}

function Get-NotificationQueueStatus {
    [CmdletBinding()]
    param()
    
    return @{
        ActiveQueue = $script:NotificationIntegrationConfig.NotificationQueue.Count
        FailedQueue = $script:NotificationIntegrationConfig.FailedNotificationQueue.Count
        DeadLetterQueue = $script:NotificationIntegrationConfig.DeadLetterQueue.Count
        CircuitBreakerStates = @{
            Email = $script:NotificationIntegrationConfig.CircuitBreaker.EmailState
            Webhook = $script:NotificationIntegrationConfig.CircuitBreaker.WebhookState
        }
        FailureCounts = @{
            Email = $script:NotificationIntegrationConfig.CircuitBreaker.EmailFailureCount
            Webhook = $script:NotificationIntegrationConfig.CircuitBreaker.WebhookFailureCount
        }
    }
}

Export-ModuleMember -Function @(
    # Original functions
    'Initialize-NotificationIntegration',
    'Send-UnityErrorNotification',
    'Send-ClaudeSubmissionNotification',
    'Test-NotificationIntegration',
    'Test-NotificationReliability',
    'Start-NotificationRetryProcessor',
    'Get-NotificationQueueStatus',
    
    # Configuration functions (from Get-NotificationConfiguration.ps1)
    'Get-NotificationConfiguration',
    'Test-NotificationConfiguration',
    
    # Health check functions (from Test-NotificationSystemHealth.ps1)
    'Test-EmailNotificationHealth',
    'Test-WebhookNotificationHealth',
    'Test-NotificationIntegrationHealth',
    
    # Trigger registration functions (from Register-NotificationTriggers.ps1)
    'Register-NotificationTriggers',
    'Register-UnityCompilationTrigger',
    'Register-ClaudeSubmissionTrigger',
    'Register-ErrorResolutionTrigger',
    'Register-SystemHealthTrigger',
    'Register-AutonomousAgentTrigger',
    'Unregister-NotificationTriggers',
    
    # Event notification functions (from Send-NotificationEvents.ps1) - renamed to avoid conflicts
    'Send-UnityErrorNotificationEvent',
    'Send-UnityWarningNotification',
    'Send-UnitySuccessNotification',
    'Send-ClaudeSubmissionNotificationEvent',
    'Send-ClaudeRateLimitNotification',
    'Send-ErrorResolutionNotification',
    'Send-SystemHealthNotification',
    'Send-AutonomousAgentNotification',
    
    # Enhanced reliability functions (from Enhanced-NotificationReliability.ps1)
    'Initialize-NotificationReliabilitySystem',
    'Test-CircuitBreakerState',
    'Add-NotificationToDeadLetterQueue',
    'Start-DeadLetterQueueProcessor',
    'Invoke-FallbackNotificationDelivery',
    'Get-NotificationReliabilityMetrics',
    'Send-EmailNotificationWithReliability',
    'Send-WebhookNotificationWithReliability'
)

Write-Host "[NotificationIntegration] Unity-Claude-NotificationIntegration module loaded successfully" -ForegroundColor Green

# SIG # Begin signature block
# MIIFqQYJKoZIhvcNAQcCoIIFmjCCBZYCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUTau/rK/wQL4LJSjtJhlpp7x5
# Ob+gggMwMIIDLDCCAhSgAwIBAgIQdR0W2SKoK5VE8JId4ZxrRTANBgkqhkiG9w0B
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
# CQQxFgQU0nvS9ZKmY9WoVP1KU/TzpwwoewgwDQYJKoZIhvcNAQEBBQAEggEALvHY
# 4VdhYRzJSjmc6ip+rWeeGrD01yVZkrSAOCeBPWR7XqosyCC64vEKZgy5XADIzNeA
# F65xBmAJzBWrImxLaxaLibLuqdE8FmM2ao27iPgiZZvXynYP11DgH274tx1I4AHv
# TW1wsnmxDpxEgSd22FZtcEqqwhqJV48jrvzpKllRgPjNXzT0LBcMdewQYVzAHIZ2
# PSHUTdmcOmELNZxddon8Pw3CgKCakc+ugc1+PierT/F2QwBvGfetBRtG3TJT4H5q
# kujvZB954070QKjyaGpWFkr0k//7ornvoa8UyDpSrP36qCWOLDq78M9CGkOgv/na
# eOgBkRYDlGUpUbDlEQ==
# SIG # End signature block
