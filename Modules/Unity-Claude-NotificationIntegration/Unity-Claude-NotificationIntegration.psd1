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
# MIIFzgYJKoZIhvcNAQcCoIIFvzCCBbsCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCDc6GbpfJOFU9kO
# Mk+ZmcWdPbrcBZjqgU54Sfn0C43znaCCAzAwggMsMIICFKADAgECAhB1HRbZIqgr
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
# MAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIKfACRlhjoEXmbcWfM/uyHEA
# R/K6Vd0p3btTYHXyu3jKMA0GCSqGSIb3DQEBAQUABIIBAIUk3M6SM1ct9TIBohWn
# 2W37mWoFs+TjQzUBWCM8+WaimkwrtmvDpTjYyVVy2DpVIdmgLNERAtPIhFxDdjJN
# 6/DMTYxXJ8WQE4+pe5aBylv3fJR/qAKSPcJJf4raHoNmPbk6Gj6JIo6JdMAqKh4R
# gzf6OlSPwY88heRRW5uguKSISTyD5yDH0v74bh0tPH4OmTNiZ8stkUUwlFNVEv8d
# LTglK3nKA1it6+PmPyqDq83jhs4C0yV4vmjEXMwx3h+811asCY0tTiOW6fF5PHI7
# exuogIv0pmFledvrd21Y9KNDV+PgLz5yuEfdVzQBBBkZrkowzKsi1ZxwLZY3vdYM
# q1M=
# SIG # End signature block
