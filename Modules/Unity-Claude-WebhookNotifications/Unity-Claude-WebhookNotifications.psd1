# Unity-Claude-WebhookNotifications Module Manifest
# Phase 2 Week 5 Days 3-4: Webhook System Implementation
# Date: 2025-08-21

@{
    RootModule = 'Unity-Claude-WebhookNotifications.psm1'
    ModuleVersion = '1.0.0'
    GUID = 'b2c3d4e5-f6a7-4901-b2c3-d4e5f6a78901'
    Author = 'Unity-Claude-Automation'
    CompanyName = 'Unity-Claude-Automation'
    Copyright = '(c) 2025'
    Description = 'Webhook notification delivery system using Invoke-RestMethod for Unity-Claude autonomous operation alerting'
    
    PowerShellVersion = '5.1'
    
    # No required modules - self-contained with native PowerShell capabilities
    RequiredModules = @()
    
    # Nested modules for enhanced functionality
    NestedModules = @()
    
    # Functions to export from this module
    FunctionsToExport = @(
        # Webhook Configuration and Setup (Week 5 Day 3 Hour 1-3)
        'New-WebhookConfiguration',
        'Set-WebhookAuthentication',
        'Test-WebhookConfiguration',
        'Get-WebhookConfiguration',
        
        # Authentication Methods (Week 5 Day 3 Hour 4-6)
        'New-BearerTokenAuth',
        'New-BasicAuthentication',
        'New-APIKeyAuthentication',
        'Test-WebhookAuthentication',
        
        # Webhook Delivery System (Week 5 Day 3 Hour 1-3)
        'Send-WebhookNotification',
        'Invoke-WebhookDelivery',
        'Test-WebhookDelivery',
        
        # Reliability and Retry Logic (Week 5 Day 4 Hour 7-8)
        'Send-WebhookWithRetry',
        'Get-WebhookDeliveryStatus',
        'Test-WebhookConnectivity',
        
        # Integration Functions (Week 5 Day 4)
        'Register-WebhookNotificationTrigger',
        'Invoke-WebhookNotificationTrigger',
        'Get-WebhookNotificationTriggers',
        
        # Analytics and Monitoring
        'Get-WebhookDeliveryStats',
        'Get-WebhookDeliveryAnalytics'
    )
    
    # Cmdlets to export from this module
    CmdletsToExport = @()
    
    # Variables to export from this module
    VariablesToExport = @()
    
    # Aliases to export from this module
    AliasesToExport = @()
    
    # Private data to pass to the module
    PrivateData = @{
        PSData = @{
            Tags = @('Unity', 'Claude', 'Automation', 'Webhook', 'Notifications', 'REST', 'HTTP')
            LicenseUri = ''
            ProjectUri = ''
            IconUri = ''
            ReleaseNotes = @'
Unity-Claude-WebhookNotifications v1.0.0 Release Notes

## Phase 2 Week 5 Days 3-4: Webhook System Implementation

### New Features:
- Webhook notification delivery system using native PowerShell Invoke-RestMethod
- Multiple authentication methods: Bearer Token, Basic Auth, API Keys
- JSON payload construction with automatic Content-Type header management
- Comprehensive retry logic with exponential backoff for webhook delivery failures
- Integration with Unity-Claude autonomous workflow system

### Authentication Features:
- Bearer Token authentication for modern webhook services (most common)
- Basic Authentication with Base64 encoding for legacy services
- API Key authentication with custom header management
- Secure credential storage compatible with existing email system architecture

### Delivery System:
- HTTP POST webhook delivery with JSON payload formatting
- HTTPS validation and security enforcement
- Webhook URL validation and sanitization
- Comprehensive delivery status tracking and analytics

### Integration Capabilities:
- Unity compilation error webhook notifications
- Claude response failure webhook alerts
- Workflow status change webhook notifications
- System health and performance webhook alerts
- Autonomous agent webhook notifications for critical events

### Reliability Features:
- Webhook delivery retry logic with exponential backoff
- HTTP connection fallback mechanisms and timeout handling
- Comprehensive logging and error reporting
- Webhook delivery status tracking and success rate analytics

### Dependencies:
- PowerShell 5.1+ with native Invoke-RestMethod support
- No external dependencies - uses built-in PowerShell HTTP capabilities
- Compatible with existing Unity-Claude parallel processing infrastructure
- Designed to complement email notification system

This module provides enterprise-grade webhook notification capabilities essential for
comprehensive autonomous Unity-Claude operation and production deployment scenarios.
'@
        }
    }
    
    # Minimum version of Microsoft .NET Framework required by this module
    DotNetFrameworkVersion = '4.5'
    
    # Minimum version of the common language runtime (CLR) required by this module
    CLRVersion = '4.0'
}
# SIG # Begin signature block
# MIIFqQYJKoZIhvcNAQcCoIIFmjCCBZYCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUGNOUviZjKCockmcyVP1tXyYu
# t/mgggMwMIIDLDCCAhSgAwIBAgIQdR0W2SKoK5VE8JId4ZxrRTANBgkqhkiG9w0B
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
# CQQxFgQURP/ixoaAwfl09smH7rwvnXGqXs8wDQYJKoZIhvcNAQEBBQAEggEAjZ0f
# 4vNigADiCi4QZe3X9gk+xQusPvxxoE//h5mrrUpuSyWnvWezdiXN0VZGRTzYX9SE
# +tbLV/W8ce+YocGn9+4rTJLDFvE+lVRrL5sU9ZLqk1zmfsCoiznMmaFVQmA2ZcGp
# w/mb33t+LcKZX9QHMtWPkmC/8qqYKZSH+Axe2rsXCIFEx5OyHaQ0TtF9BXYiKUtv
# 3pRrXP8XHTJp7eeMa3HUsGypZRuabG661+gmonGnfWPViGSDFmhL6EPmqEI2EJiV
# JEw8IAgcHthbY97rKzmoxtgd+88YgIICzQeq/89ZO/w9kojIkVI8oWeizCjeMj6V
# TMgZzSu5evU/bvaneQ==
# SIG # End signature block
