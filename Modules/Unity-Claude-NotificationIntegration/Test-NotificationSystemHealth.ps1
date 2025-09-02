function Test-EmailNotificationHealth {
    <#
    .SYNOPSIS
    Health check function for EmailNotifications subsystem
    
    .DESCRIPTION
    Performs comprehensive health checking for the EmailNotifications subsystem including:
    - Service process validation
    - Configuration validation
    - SMTP connectivity testing
    - Queue status monitoring
    - Performance metrics collection
    
    .PARAMETER Detailed
    Return detailed health information including performance metrics
    
    .EXAMPLE
    Test-EmailNotificationHealth
    
    .EXAMPLE
    Test-EmailNotificationHealth -Detailed
    #>
    [CmdletBinding()]
    param(
        [switch]$Detailed
    )
    
    Write-SystemStatusLog "Performing EmailNotifications health check" -Level 'DEBUG'
    
    try {
        $healthResult = @{
            SubsystemName = "EmailNotifications"
            IsHealthy = $true
            Status = "Healthy"
            LastCheck = Get-Date
            Errors = @()
            Warnings = @()
            Metrics = @{}
        }
        
        # Check if EmailNotifications module is loaded
        $emailModule = Get-Module -Name "Unity-Claude-EmailNotifications" -ErrorAction SilentlyContinue
        if (-not $emailModule) {
            $healthResult.IsHealthy = $false
            $healthResult.Status = "Unhealthy"
            $healthResult.Errors += "Unity-Claude-EmailNotifications module not loaded"
        } else {
            $healthResult.Metrics.ModuleVersion = $emailModule.Version
            Write-SystemStatusLog "EmailNotifications module version: $($emailModule.Version)" -Level 'DEBUG'
        }
        
        # Load notification configuration
        try {
            $config = Get-NotificationConfiguration -NotificationService "EmailNotifications"
            $emailConfig = $config.EmailNotifications
            
            if (-not $emailConfig.Enabled) {
                $healthResult.Status = "Disabled"
                $healthResult.Warnings += "Email notifications are disabled in configuration"
            } else {
                # Validate SMTP configuration
                if (-not $emailConfig.SMTPServer) {
                    $healthResult.IsHealthy = $false
                    $healthResult.Errors += "SMTP Server not configured"
                }
                
                if (-not $emailConfig.FromAddress) {
                    $healthResult.IsHealthy = $false
                    $healthResult.Errors += "From Address not configured"
                }
                
                if (-not $emailConfig.ToAddresses -or $emailConfig.ToAddresses.Count -eq 0) {
                    $healthResult.IsHealthy = $false
                    $healthResult.Errors += "No recipient addresses configured"
                }
                
                # Test SMTP connectivity (if configuration is valid)
                if ($healthResult.IsHealthy -and $emailConfig.SMTPServer) {
                    try {
                        $testStart = Get-Date
                        $tcpClient = New-Object System.Net.Sockets.TcpClient
                        $tcpClient.ReceiveTimeout = 5000
                        $tcpClient.SendTimeout = 5000
                        $connectResult = $tcpClient.ConnectAsync($emailConfig.SMTPServer, $emailConfig.SMTPPort)
                        
                        # Wait for connection with timeout
                        $waitTime = 0
                        while (-not $connectResult.IsCompleted -and $waitTime -lt 5000) {
                            Start-Sleep -Milliseconds 100
                            $waitTime += 100
                        }
                        
                        if ($connectResult.IsCompleted -and -not $connectResult.IsFaulted) {
                            $testEnd = Get-Date
                            $connectionTime = ($testEnd - $testStart).TotalMilliseconds
                            $healthResult.Metrics.SMTPConnectionTime = $connectionTime
                            Write-SystemStatusLog "SMTP connectivity test passed: $($connectionTime)ms" -Level 'DEBUG'
                        } else {
                            $healthResult.Warnings += "SMTP connectivity test failed or timed out"
                        }
                        
                        $tcpClient.Close()
                    } catch {
                        $healthResult.Warnings += "SMTP connectivity test error: $($_.Exception.Message)"
                    }
                }
            }
        } catch {
            $healthResult.IsHealthy = $false
            $healthResult.Errors += "Configuration loading failed: $($_.Exception.Message)"
        }
        
        # Check notification queue status (if NotificationIntegration is available)
        try {
            $queueStatus = Get-NotificationQueueStatus -ErrorAction SilentlyContinue
            if ($queueStatus) {
                $healthResult.Metrics.QueueLength = $queueStatus.QueueLength
                $healthResult.Metrics.PendingNotifications = $queueStatus.PendingCount
                $healthResult.Metrics.FailedNotifications = $queueStatus.FailedCount
                
                if ($queueStatus.QueueLength -gt 100) {
                    $healthResult.Warnings += "Email notification queue is large: $($queueStatus.QueueLength) items"
                }
                
                if ($queueStatus.FailedCount -gt 10) {
                    $healthResult.Warnings += "High number of failed email notifications: $($queueStatus.FailedCount)"
                }
            }
        } catch {
            Write-SystemStatusLog "Unable to check notification queue status: $($_.Exception.Message)" -Level 'DEBUG'
        }
        
        # Check memory and CPU usage if detailed metrics requested
        if ($Detailed) {
            try {
                $process = Get-Process -Name "powershell*" | Where-Object { $_.MainWindowTitle -like "*EmailNotifications*" } | Select-Object -First 1
                if ($process) {
                    $healthResult.Metrics.MemoryUsageMB = [math]::Round($process.WorkingSet64 / 1MB, 2)
                    $healthResult.Metrics.CPUTime = $process.TotalProcessorTime.TotalSeconds
                    $healthResult.Metrics.ProcessId = $process.Id
                }
            } catch {
                Write-SystemStatusLog "Unable to collect process metrics: $($_.Exception.Message)" -Level 'DEBUG'
            }
        }
        
        # Determine final health status
        if ($healthResult.Errors.Count -eq 0 -and $emailConfig.Enabled) {
            $healthResult.Status = "Healthy"
        } elseif ($healthResult.Errors.Count -eq 0 -and -not $emailConfig.Enabled) {
            $healthResult.Status = "Disabled"
        } else {
            $healthResult.Status = "Unhealthy"
            $healthResult.IsHealthy = $false
        }
        
        Write-SystemStatusLog "EmailNotifications health check completed: $($healthResult.Status)" -Level 'INFO'
        return $healthResult
        
    } catch {
        $errorMessage = "EmailNotifications health check failed: $($_.Exception.Message)"
        Write-SystemStatusLog $errorMessage -Level 'ERROR'
        
        return @{
            SubsystemName = "EmailNotifications"
            IsHealthy = $false
            Status = "Error"
            LastCheck = Get-Date
            Errors = @($errorMessage)
            Warnings = @()
            Metrics = @{}
        }
    }
}

function Test-WebhookNotificationHealth {
    <#
    .SYNOPSIS
    Health check function for WebhookNotifications subsystem
    
    .DESCRIPTION
    Performs comprehensive health checking for the WebhookNotifications subsystem including:
    - Service process validation
    - Configuration validation
    - Webhook endpoint connectivity testing
    - Queue status monitoring
    - Performance metrics collection
    
    .PARAMETER Detailed
    Return detailed health information including performance metrics
    
    .EXAMPLE
    Test-WebhookNotificationHealth
    
    .EXAMPLE
    Test-WebhookNotificationHealth -Detailed
    #>
    [CmdletBinding()]
    param(
        [switch]$Detailed
    )
    
    Write-SystemStatusLog "Performing WebhookNotifications health check" -Level 'DEBUG'
    
    try {
        $healthResult = @{
            SubsystemName = "WebhookNotifications"
            IsHealthy = $true
            Status = "Healthy"
            LastCheck = Get-Date
            Errors = @()
            Warnings = @()
            Metrics = @{}
        }
        
        # Check if WebhookNotifications module is loaded
        $webhookModule = Get-Module -Name "Unity-Claude-WebhookNotifications" -ErrorAction SilentlyContinue
        if (-not $webhookModule) {
            $healthResult.IsHealthy = $false
            $healthResult.Status = "Unhealthy"
            $healthResult.Errors += "Unity-Claude-WebhookNotifications module not loaded"
        } else {
            $healthResult.Metrics.ModuleVersion = $webhookModule.Version
            Write-SystemStatusLog "WebhookNotifications module version: $($webhookModule.Version)" -Level 'DEBUG'
        }
        
        # Load notification configuration
        try {
            $config = Get-NotificationConfiguration -NotificationService "WebhookNotifications"
            $webhookConfig = $config.WebhookNotifications
            
            if (-not $webhookConfig.Enabled) {
                $healthResult.Status = "Disabled"
                $healthResult.Warnings += "Webhook notifications are disabled in configuration"
            } else {
                # Validate webhook configuration
                if (-not $webhookConfig.WebhookURLs -or $webhookConfig.WebhookURLs.Count -eq 0) {
                    $healthResult.IsHealthy = $false
                    $healthResult.Errors += "No webhook URLs configured"
                } else {
                    $healthResult.Metrics.ConfiguredWebhooks = $webhookConfig.WebhookURLs.Count
                }
                
                # Validate authentication configuration
                $authMethod = $webhookConfig.AuthenticationMethod
                switch ($authMethod) {
                    "Bearer" {
                        if (-not $webhookConfig.BearerToken) {
                            $healthResult.IsHealthy = $false
                            $healthResult.Errors += "Bearer token not configured"
                        }
                    }
                    "Basic" {
                        if (-not $webhookConfig.BasicAuthUsername -or -not $webhookConfig.BasicAuthPassword) {
                            $healthResult.IsHealthy = $false
                            $healthResult.Errors += "Basic authentication credentials not configured"
                        }
                    }
                    "APIKey" {
                        if (-not $webhookConfig.APIKeyHeader -or -not $webhookConfig.APIKey) {
                            $healthResult.IsHealthy = $false
                            $healthResult.Errors += "API Key authentication not configured"
                        }
                    }
                }
                
                # Test webhook connectivity (if configuration is valid and URLs are provided)
                if ($healthResult.IsHealthy -and $webhookConfig.WebhookURLs.Count -gt 0) {
                    $testableUrls = @()
                    $connectionTests = @()
                    
                    foreach ($url in $webhookConfig.WebhookURLs) {
                        if ($url -and $url -ne "") {
                            $testableUrls += $url
                        }
                    }
                    
                    if ($testableUrls.Count -gt 0) {
                        foreach ($url in $testableUrls) {
                            try {
                                $testStart = Get-Date
                                
                                # Create basic test request
                                $testPayload = @{
                                    test = $true
                                    timestamp = (Get-Date).ToString("yyyy-MM-ddTHH:mm:ssZ")
                                    source = "Unity-Claude-Automation-HealthCheck"
                                } | ConvertTo-Json
                                
                                $headers = @{
                                    "Content-Type" = $webhookConfig.ContentType
                                    "User-Agent" = $webhookConfig.UserAgent
                                }
                                
                                # Add authentication headers based on method
                                switch ($authMethod) {
                                    "Bearer" { $headers["Authorization"] = "Bearer $($webhookConfig.BearerToken)" }
                                    "Basic" { 
                                        $credentials = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes("$($webhookConfig.BasicAuthUsername):$($webhookConfig.BasicAuthPassword)"))
                                        $headers["Authorization"] = "Basic $credentials"
                                    }
                                    "APIKey" { $headers[$webhookConfig.APIKeyHeader] = $webhookConfig.APIKey }
                                }
                                
                                # Perform connectivity test (HEAD request to avoid side effects)
                                $response = Invoke-WebRequest -Uri $url -Method HEAD -Headers $headers -TimeoutSec 10 -ErrorAction Stop
                                $testEnd = Get-Date
                                $responseTime = ($testEnd - $testStart).TotalMilliseconds
                                
                                $connectionTests += @{
                                    Url = $url
                                    Success = $true
                                    ResponseTime = $responseTime
                                    StatusCode = $response.StatusCode
                                }
                                
                                Write-SystemStatusLog "Webhook connectivity test passed for $url : $($responseTime)ms" -Level 'DEBUG'
                                
                            } catch {
                                $connectionTests += @{
                                    Url = $url
                                    Success = $false
                                    Error = $_.Exception.Message
                                }
                                $healthResult.Warnings += "Webhook connectivity test failed for $url : $($_.Exception.Message)"
                            }
                        }
                        
                        $successfulTests = $connectionTests | Where-Object { $_.Success }
                        $healthResult.Metrics.WebhookConnectivityTests = $connectionTests.Count
                        $healthResult.Metrics.SuccessfulConnectivityTests = $successfulTests.Count
                        
                        if ($successfulTests.Count -gt 0) {
                            $healthResult.Metrics.AverageResponseTime = ($successfulTests | Measure-Object -Property ResponseTime -Average).Average
                        }
                        
                        if ($successfulTests.Count -eq 0) {
                            $healthResult.Warnings += "All webhook connectivity tests failed"
                        }
                    }
                }
            }
        } catch {
            $healthResult.IsHealthy = $false
            $healthResult.Errors += "Configuration loading failed: $($_.Exception.Message)"
        }
        
        # Check notification queue status (if NotificationIntegration is available)
        try {
            $queueStatus = Get-NotificationQueueStatus -ErrorAction SilentlyContinue
            if ($queueStatus) {
                $healthResult.Metrics.QueueLength = $queueStatus.QueueLength
                $healthResult.Metrics.PendingNotifications = $queueStatus.PendingCount
                $healthResult.Metrics.FailedNotifications = $queueStatus.FailedCount
                
                if ($queueStatus.QueueLength -gt 100) {
                    $healthResult.Warnings += "Webhook notification queue is large: $($queueStatus.QueueLength) items"
                }
                
                if ($queueStatus.FailedCount -gt 10) {
                    $healthResult.Warnings += "High number of failed webhook notifications: $($queueStatus.FailedCount)"
                }
            }
        } catch {
            Write-SystemStatusLog "Unable to check notification queue status: $($_.Exception.Message)" -Level 'DEBUG'
        }
        
        # Check memory and CPU usage if detailed metrics requested
        if ($Detailed) {
            try {
                $process = Get-Process -Name "powershell*" | Where-Object { $_.MainWindowTitle -like "*WebhookNotifications*" } | Select-Object -First 1
                if ($process) {
                    $healthResult.Metrics.MemoryUsageMB = [math]::Round($process.WorkingSet64 / 1MB, 2)
                    $healthResult.Metrics.CPUTime = $process.TotalProcessorTime.TotalSeconds
                    $healthResult.Metrics.ProcessId = $process.Id
                }
            } catch {
                Write-SystemStatusLog "Unable to collect process metrics: $($_.Exception.Message)" -Level 'DEBUG'
            }
        }
        
        # Determine final health status
        if ($healthResult.Errors.Count -eq 0 -and $webhookConfig.Enabled) {
            $healthResult.Status = "Healthy"
        } elseif ($healthResult.Errors.Count -eq 0 -and -not $webhookConfig.Enabled) {
            $healthResult.Status = "Disabled"
        } else {
            $healthResult.Status = "Unhealthy"
            $healthResult.IsHealthy = $false
        }
        
        Write-SystemStatusLog "WebhookNotifications health check completed: $($healthResult.Status)" -Level 'INFO'
        return $healthResult
        
    } catch {
        $errorMessage = "WebhookNotifications health check failed: $($_.Exception.Message)"
        Write-SystemStatusLog $errorMessage -Level 'ERROR'
        
        return @{
            SubsystemName = "WebhookNotifications"
            IsHealthy = $false
            Status = "Error"
            LastCheck = Get-Date
            Errors = @($errorMessage)
            Warnings = @()
            Metrics = @{}
        }
    }
}

function Test-NotificationIntegrationHealth {
    <#
    .SYNOPSIS
    Comprehensive health check for the unified NotificationIntegration subsystem
    
    .DESCRIPTION
    Performs end-to-end health checking for the entire notification integration system including:
    - Individual service health validation
    - Cross-service integration testing
    - Configuration consistency validation
    - Performance metrics aggregation
    
    .PARAMETER Detailed
    Return detailed health information including performance metrics
    
    .EXAMPLE
    Test-NotificationIntegration
    
    .EXAMPLE
    Test-NotificationIntegration -Detailed
    #>
    [CmdletBinding()]
    param(
        [switch]$Detailed
    )
    
    Write-SystemStatusLog "Performing comprehensive NotificationIntegration health check" -Level 'INFO'
    
    try {
        $healthResult = @{
            SubsystemName = "NotificationIntegration"
            IsHealthy = $true
            Status = "Healthy"
            LastCheck = Get-Date
            Errors = @()
            Warnings = @()
            Metrics = @{}
            ServiceHealth = @{}
        }
        
        # Test individual notification services
        $emailHealth = Test-EmailNotificationHealth -Detailed:$Detailed
        $webhookHealth = Test-WebhookNotificationHealth -Detailed:$Detailed
        
        $healthResult.ServiceHealth.EmailNotifications = $emailHealth
        $healthResult.ServiceHealth.WebhookNotifications = $webhookHealth
        
        # Aggregate errors and warnings from individual services
        $healthResult.Errors += $emailHealth.Errors
        $healthResult.Errors += $webhookHealth.Errors
        $healthResult.Warnings += $emailHealth.Warnings
        $healthResult.Warnings += $webhookHealth.Warnings
        
        # Check if NotificationIntegration module is loaded
        $integrationModule = Get-Module -Name "Unity-Claude-NotificationIntegration" -ErrorAction SilentlyContinue
        if (-not $integrationModule) {
            $healthResult.IsHealthy = $false
            $healthResult.Errors += "Unity-Claude-NotificationIntegration module not loaded"
        } else {
            $healthResult.Metrics.IntegrationModuleVersion = $integrationModule.Version
        }
        
        # Test configuration integration
        try {
            $config = Get-NotificationConfiguration
            $healthResult.Metrics.ConfigurationLoaded = $true
            $healthResult.Metrics.NotificationServicesConfigured = @()
            
            if ($config.EmailNotifications.Enabled) {
                $healthResult.Metrics.NotificationServicesConfigured += "Email"
            }
            if ($config.WebhookNotifications.Enabled) {
                $healthResult.Metrics.NotificationServicesConfigured += "Webhook"
            }
            
            # Validate integration-specific configuration
            if ($config.Notifications) {
                $healthResult.Metrics.BatchNotificationsEnabled = $config.Notifications.BatchNotifications
                $healthResult.Metrics.NotificationLevel = $config.Notifications.DefaultNotificationLevel
            }
        } catch {
            $healthResult.IsHealthy = $false
            $healthResult.Errors += "Integration configuration validation failed: $($_.Exception.Message)"
        }
        
        # Test notification queue integration
        try {
            $overallQueueStatus = Get-NotificationQueueStatus -ErrorAction SilentlyContinue
            if ($overallQueueStatus) {
                $healthResult.Metrics.TotalQueueLength = $overallQueueStatus.TotalQueueLength
                $healthResult.Metrics.TotalPendingNotifications = $overallQueueStatus.TotalPendingCount
                $healthResult.Metrics.TotalFailedNotifications = $overallQueueStatus.TotalFailedCount
                
                if ($overallQueueStatus.TotalQueueLength -gt 200) {
                    $healthResult.Warnings += "Overall notification queue is very large: $($overallQueueStatus.TotalQueueLength) items"
                }
            }
        } catch {
            Write-SystemStatusLog "Unable to check overall notification queue status: $($_.Exception.Message)" -Level 'DEBUG'
        }
        
        # Check Bootstrap Orchestrator integration
        try {
            $manifests = Get-SubsystemManifests -ErrorAction SilentlyContinue
            if ($manifests) {
                $notificationManifests = $manifests | Where-Object { $_.Name -like "*Notification*" }
                $healthResult.Metrics.BootstrapManifestsFound = $notificationManifests.Count
                
                $manifestNames = $notificationManifests | ForEach-Object { $_.Name }
                $healthResult.Metrics.BootstrapManifestNames = $manifestNames
            }
        } catch {
            $healthResult.Warnings += "Unable to check Bootstrap Orchestrator integration: $($_.Exception.Message)"
        }
        
        # Determine overall health status
        $criticalErrors = $healthResult.Errors | Where-Object { $_ -notlike "*disabled*" -and $_ -notlike "*connectivity test*" }
        if ($criticalErrors.Count -eq 0) {
            if (-not $emailHealth.IsHealthy -and -not $webhookHealth.IsHealthy) {
                $healthResult.Status = "Degraded"
                $healthResult.IsHealthy = $false
                $healthResult.Warnings += "All notification services are unhealthy or disabled"
            } else {
                $healthResult.Status = "Healthy"
                $healthResult.IsHealthy = $true
            }
        } else {
            $healthResult.Status = "Unhealthy"
            $healthResult.IsHealthy = $false
        }
        
        Write-SystemStatusLog "NotificationIntegration comprehensive health check completed: $($healthResult.Status)" -Level 'INFO'
        return $healthResult
        
    } catch {
        $errorMessage = "NotificationIntegration health check failed: $($_.Exception.Message)"
        Write-SystemStatusLog $errorMessage -Level 'ERROR'
        
        return @{
            SubsystemName = "NotificationIntegration"
            IsHealthy = $false
            Status = "Error"
            LastCheck = Get-Date
            Errors = @($errorMessage)
            Warnings = @()
            Metrics = @{}
            ServiceHealth = @{}
        }
    }
}

# Functions available for dot-sourcing in main module  
# Test-EmailNotificationHealth, Test-WebhookNotificationHealth, Test-NotificationIntegrationHealth
# SIG # Begin signature block
# MIIFzgYJKoZIhvcNAQcCoIIFvzCCBbsCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCBqYTVch0R3+WYA
# y1008S4VwX0r7hbsTf4cbdRG1ZVw1aCCAzAwggMsMIICFKADAgECAhB1HRbZIqgr
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
# MAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIO27CsAy2zQxiK0K1e1JXhOG
# g+DexR6fllo63mjUqboQMA0GCSqGSIb3DQEBAQUABIIBAEo2YsFa6u0G6dan0xQb
# O1RtpMm65gvlmZnV3PYX45c+hO6av88a1D9SORF0j3K2ZHse7AsUPLYEYbWgXVp2
# FhCMPwmvmaGoNnwgbi/0AQXPqU7MamwIhhcF9+RCdCgrjjn0o8YvLvV9VRpXvIlP
# GRxWTf2WKZMXfALF52VGTl9/Xvdvcx/cRuHvfjXnrxcyi12nuBdN3E66ON/2nwMQ
# 40UjxPkzJHXbTrTzVIURfYkV2cANSafdixZwxXSuArFaADazbWBbpF6XeS9Fifux
# 3XZlfx+iTsxly0AiDupPYH6x1BjHRHfmAPXsi9z/6zWHLh3brAKEghW5e8dOkBfJ
# l9s=
# SIG # End signature block
