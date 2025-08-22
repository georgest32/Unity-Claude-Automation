@{
    RootModule = 'Unity-Claude-NotificationIntegration.psm1'
    ModuleVersion = '1.0.0'
    GUID = 'a8f9c2d4-b5e6-4f7a-9c8d-1e2f3a4b5c6d'
    Author = 'Unity-Claude-Automation'
    CompanyName = 'Unity-Claude-Automation'
    Copyright = '(c) 2025. All rights reserved.'
    Description = 'Week 6 Days 1-2: System Integration - Notification triggers for Unity-Claude autonomous workflow'
    PowerShellVersion = '5.1'
    RequiredModules = @(
        'Unity-Claude-EmailNotifications',
        'Unity-Claude-WebhookNotifications', 
        'Unity-Claude-NotificationContentEngine',
        'Unity-Claude-SystemStatus'
    )
    FunctionsToExport = @(
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
    CmdletsToExport = @()
    VariablesToExport = @()
    AliasesToExport = @()
}

# SIG # Begin signature block
# MIIFqQYJKoZIhvcNAQcCoIIFmjCCBZYCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUwyUSQrtmRFMfNlvymB505znt
# MLCgggMwMIIDLDCCAhSgAwIBAgIQdR0W2SKoK5VE8JId4ZxrRTANBgkqhkiG9w0B
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
# CQQxFgQUifZRXkI5jaaxIuE2QXkkbC2NKjwwDQYJKoZIhvcNAQEBBQAEggEAAeIK
# 9HPYwOaOZfRXe5EXD2PSEV6MmZMeZ5YZfn3TRZlRZE0MISZY7QJvG507aVwC/A5W
# r4m0/fQHf7+hnGQXlJ2sxly9Iwh6YKzU7XPvgt4QdEoA4wMFfqBWMicRG+TJkm3M
# eI1D4W4r9BQeVuCk7QBt051h0yzFJJmMRsX5BgqMxftV/UnwovLmAMotnCzvX4DH
# DzRzPcPDuvItuvlubj+WkPVksnhyYZ6JovnTXvki4DLdp6CPM08UWsOkEpmZ1cYo
# 2XlFbEfG+z/VyunUI68Co0eB+aZOyl4SkI66JztsLT+QoDlWHQgJmceV8LiIKnW8
# Ye5CW6mud+7EcWWZCA==
# SIG # End signature block
