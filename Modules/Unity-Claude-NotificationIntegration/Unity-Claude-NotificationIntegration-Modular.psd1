# Unity-Claude-NotificationIntegration Module Manifest (Modular Version)
# Phase 2 Week 6: Integration & Testing Implementation - Refactored
# Date: 2025-08-21

@{
    RootModule = 'Unity-Claude-NotificationIntegration-Modular.psm1'
    ModuleVersion = '1.1.0'
    GUID = 'c3d4e5f6-a7b8-9012-c3d4-e5f6a7b89012'
    Author = 'Unity-Claude-Automation'
    CompanyName = 'Unity-Claude-Automation'
    Copyright = '(c) 2025'
    Description = 'Modular integration system for Unity-Claude workflow notifications with autonomous operation triggers'
    
    PowerShellVersion = '5.1'
    
    # Required modules for notification functionality
    RequiredModules = @()
    
    # Nested modules for enhanced functionality - now using modular structure
    NestedModules = @(
        'Core\NotificationCore.psm1',
        'Integration\WorkflowIntegration.psm1',
        'Integration\ContextManagement.psm1',
        'Reliability\RetryLogic.psm1',
        'Reliability\FallbackMechanisms.psm1',
        'Queue\QueueManagement.psm1',
        'Configuration\ConfigurationManagement.psm1',
        'Monitoring\MetricsAndHealthCheck.psm1'
    )
    
    # Functions to export from this module - all functions from submodules
    FunctionsToExport = @(
        # Core Functions
        'Initialize-NotificationIntegration',
        'Register-NotificationHook',
        'Unregister-NotificationHook', 
        'Get-NotificationHooks',
        'Clear-NotificationHooks',
        'Send-IntegratedNotification',
        
        # Workflow Integration Functions
        'Invoke-NotificationHook',
        'Add-WorkflowNotificationTrigger',
        'Remove-WorkflowNotificationTrigger',
        'Enable-WorkflowNotifications',
        'Disable-WorkflowNotifications',
        'Get-WorkflowNotificationStatus',
        
        # Context Management Functions
        'New-NotificationContext',
        'Add-NotificationContextData',
        'Get-NotificationContext',
        'Clear-NotificationContext',
        'Format-NotificationContext',
        
        # Reliability Functions
        'New-NotificationRetryPolicy',
        'Invoke-NotificationWithRetry',
        'Test-NotificationDelivery',
        'Get-NotificationDeliveryStatus',
        'Reset-NotificationRetryState',
        
        # Fallback Functions
        'New-NotificationFallbackChain',
        'Invoke-NotificationFallback',
        'Test-NotificationFallback',
        'Get-FallbackStatus',
        'Reset-FallbackState',
        
        # Queue Management Functions
        'Initialize-NotificationQueue',
        'Add-NotificationToQueue',
        'Process-NotificationQueue',
        'Get-QueueStatus',
        'Clear-NotificationQueue',
        'Get-FailedNotifications',
        
        # Configuration Functions
        'New-NotificationConfiguration',
        'Import-NotificationConfiguration',
        'Export-NotificationConfiguration',
        'Test-NotificationConfiguration',
        'Get-NotificationConfiguration',
        'Set-NotificationConfiguration',
        
        # Monitoring Functions
        'Get-NotificationMetrics',
        'Get-NotificationHealthCheck',
        'New-NotificationReport',
        'Export-NotificationAnalytics',
        'Reset-NotificationMetrics'
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
            Tags = @('Unity', 'Claude', 'Automation', 'Notifications', 'Integration', 'Workflow', 'Reliability', 'Modular')
            LicenseUri = ''
            ProjectUri = ''
            IconUri = ''
            ReleaseNotes = @'
Unity-Claude-NotificationIntegration v1.1.0 Release Notes (Modular Refactor)

## Modular Architecture Improvements:

### Module Structure:
- **Core/**: Foundation functionality with state management and core hooks
- **Integration/**: Workflow integration and context management
- **Reliability/**: Retry logic and fallback mechanisms  
- **Queue/**: Queue management and processing
- **Configuration/**: Configuration management and validation
- **Monitoring/**: Metrics, health checks, and reporting

### Benefits of Modular Design:
- **Maintainability**: Each module focuses on specific functionality
- **Testability**: Individual modules can be tested in isolation
- **Extensibility**: New functionality can be added as separate modules
- **Performance**: Only required modules need to be loaded
- **Code Organization**: Clear separation of concerns

### Integration Features (Unchanged):
- Hook-based notification system for non-invasive workflow integration
- Observer pattern implementation for event-driven notifications
- Context building for rich notification data
- Configurable notification triggers throughout Unity-Claude workflow

### Reliability Features (Unchanged):
- Retry logic with exponential backoff and jitter
- Circuit breaker pattern implementation
- Fallback mechanism with channel switching
- Dead letter queue for failed notifications
- Comprehensive error handling and recovery

### Dependencies:
- Unity-Claude-EmailNotifications module
- Unity-Claude-WebhookNotifications module  
- Unity-Claude-NotificationContentEngine module
- PowerShell 5.1+ with native async capabilities

This modular refactor maintains 100% API compatibility while improving
code organization, maintainability, and extensibility for future development.
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
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUS+FWEHaP8Csw0jCORpm16eft
# QTygggMwMIIDLDCCAhSgAwIBAgIQdR0W2SKoK5VE8JId4ZxrRTANBgkqhkiG9w0B
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
# CQQxFgQU5QwE2i5AQ7Bp7XjlR3ETeaB6yxcwDQYJKoZIhvcNAQEBBQAEggEAEHLn
# 533Ti8KtHxMpAb3M4CQWIxvKAV+tjwkROFT/6GdGDmMFzx/+JtvB7BaQF0PwGEq4
# +lwFQOHe+THVIahnhSsJ1jHvl6CUNB30pNFjBCHX2y8p9EhtcZVMWzTSVVjHkHR8
# dhFHUnoYKQV7MnxIhdixesrgFqMwZ3TvPLsW8SKyib3tr4XHA3Nctbe5ve2wLncq
# VrfBkWuXAoxsePH8MOhvXEkuexvBx7GDcTlIvy0E1sudxfYZKJ2PsrTV3YCW/qmI
# 9pHPJY81GGW89VVE42xaNzQ2NMoXfuXHCNXsTd6qvJ1Hn7DmC6vp/ZF87bOBMXhK
# yIw7HsMhQy/9hHgdrw==
# SIG # End signature block
