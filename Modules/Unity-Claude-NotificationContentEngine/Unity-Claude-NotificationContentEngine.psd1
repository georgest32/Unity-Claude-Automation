# Unity-Claude-NotificationContentEngine Module Manifest
# Phase 2 Week 5 Day 5: Notification Content Engine Implementation
# Date: 2025-08-21

@{
    RootModule = 'Unity-Claude-NotificationContentEngine.psm1'
    ModuleVersion = '1.0.0'
    GUID = 'c3d4e5f6-a7b8-9012-c3d4-e5f6a7b89012'
    Author = 'Unity-Claude-Automation'
    CompanyName = 'Unity-Claude-Automation'
    Copyright = '(c) 2025'
    Description = 'Unified notification content engine with severity-based routing for Unity-Claude autonomous operation'
    
    PowerShellVersion = '5.1'
    
    # No required modules - designed to integrate with existing email and webhook modules
    RequiredModules = @()
    
    # Nested modules for enhanced functionality
    NestedModules = @()
    
    # Functions to export from this module
    FunctionsToExport = @(
        # Unified Template System (Week 5 Day 5 Hour 1-4)
        'New-UnifiedNotificationTemplate',
        'Set-NotificationTemplate',
        'Get-NotificationTemplate',
        'Test-NotificationTemplate',
        'Remove-NotificationTemplate',
        'Export-NotificationTemplate',
        'Import-NotificationTemplate',
        
        # Template Components and Management (Week 5 Day 5 Hour 1-4)
        'New-TemplateComponent',
        'Get-TemplateComponent',
        'Set-TemplateComponent',
        'Format-UnifiedNotificationContent',
        'Validate-NotificationContent',
        'Preview-NotificationTemplate',
        
        # Severity-Based Routing (Week 5 Day 5 Hour 5-8)
        'New-NotificationRoutingRule',
        'Set-NotificationRouting',
        'Get-NotificationRouting',
        'Invoke-SeverityBasedRouting',
        'Test-NotificationRouting',
        
        # Channel Selection and Management (Week 5 Day 5 Hour 5-8)
        'Select-NotificationChannels',
        'New-ChannelPreferences',
        'Set-ChannelPreferences',
        'Get-ChannelPreferences',
        'Invoke-ChannelSelection',
        
        # Notification Processing and Delivery (Week 5 Day 5 Hour 5-8)
        'Send-UnifiedNotification',
        'Invoke-NotificationDelivery',
        'Get-NotificationStatus',
        'Get-NotificationAnalytics',
        
        # Content Engine Configuration
        'Initialize-NotificationContentEngine',
        'Get-ContentEngineConfiguration',
        'Set-ContentEngineConfiguration'
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
            Tags = @('Unity', 'Claude', 'Automation', 'Notifications', 'ContentEngine', 'Templates', 'Routing')
            LicenseUri = ''
            ProjectUri = ''
            IconUri = ''
            ReleaseNotes = @'
Unity-Claude-NotificationContentEngine v1.0.0 Release Notes

## Phase 2 Week 5 Day 5: Notification Content Engine Implementation

### New Features:
- Unified notification content engine supporting both email and webhook delivery
- Template versioning and management system with composable template components
- Severity-based notification routing with intelligent channel selection
- Content validation and testing framework with template preview capabilities
- Integration with existing Unity-Claude email and webhook notification systems

### Template System:
- Unified template architecture serving both email and webhook notifications
- Variable substitution with PowerShell-based token replacement using hashtables
- Composable template components for reusable content across notification types
- Template versioning with import/export capabilities and conflict management
- Content validation and consistency enforcement with preview functionality

### Severity-Based Routing:
- Industry-standard severity levels: Critical, Error, Warning, Info
- Intelligent channel selection algorithms based on severity and urgency mapping
- Routing rules: Critical/Error → Email+Webhook, Warning → Email, Info → Webhook
- Notification throttling and deduplication to prevent notification spam
- Escalation policies and channel preference management

### Content Management:
- Unified content standardization across email and webhook channels
- Template testing with sample data validation before deployment
- Content adaptation for different delivery channel requirements
- Comprehensive analytics and delivery status tracking across all channels

### Integration Capabilities:
- Seamless integration with Unity-Claude-EmailNotifications module
- Compatible with Unity-Claude-WebhookNotifications module
- Unified notification workflow supporting Unity compilation errors, Claude failures
- System health alerts, workflow status changes, and autonomous agent notifications

### Production Features:
- Template validation and testing framework ensuring content quality
- Severity-based routing ensuring appropriate urgency and channel selection
- Content engine configuration management with backup and restore capabilities
- Comprehensive logging and analytics for notification content and delivery performance

### Dependencies:
- Compatible with existing Unity-Claude email notification system (13 functions)
- Compatible with existing Unity-Claude webhook notification system (11 functions)
- PowerShell 5.1+ with native template processing and routing capabilities
- No external dependencies - uses built-in PowerShell content management

This module provides enterprise-grade notification content management and routing
capabilities essential for comprehensive autonomous Unity-Claude operation.
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
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQU/ho4NP8UCTEf/GfgDenmNgWH
# 5NGgggMwMIIDLDCCAhSgAwIBAgIQdR0W2SKoK5VE8JId4ZxrRTANBgkqhkiG9w0B
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
# CQQxFgQUvYaCUIuBWYVk/gCXynPcYuDzrsswDQYJKoZIhvcNAQEBBQAEggEAYkwY
# 11IWmTjNIKOtl+5HQX59KORDe+Sl5DSU5zzmPSqyG2aN1ShGBysbh3wWq10hpUz7
# B1YrSrAKnYzCEJwThDVibqu9lcDsM27YAsec2JKw+K/QuwN2VTLi3qh+8H72MZZm
# rbkx3y29tkqec2qwCll5n4UBWS+xZ6jaquw5TbvYxjl1iRpL2MzroOy4AZiP0JBn
# DhpS18S39ZCcmv7KI9ggyZXg4Z7QInbG41pPiB7XpGH13lXf1Nn5vWTGMJEjXSzo
# 5z+Z9AaJkKlG08ohys8pOH/w+wEIyjSZJuv5q/khBnQACJccFrxmsLJl47e5Npst
# QHD4Aps+oXrxcAqzwg==
# SIG # End signature block
