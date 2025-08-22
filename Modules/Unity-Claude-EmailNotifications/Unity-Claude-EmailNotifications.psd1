# Unity-Claude-EmailNotifications Module Manifest
# Phase 2 Week 5 Days 1-2: Email System Implementation
# Date: 2025-08-21

@{
    RootModule = 'Unity-Claude-EmailNotifications.psm1'
    ModuleVersion = '1.0.0'
    GUID = 'a1b2c3d4-e5f6-7890-a1b2-c3d4e5f67890'
    Author = 'Unity-Claude-Automation'
    CompanyName = 'Unity-Claude-Automation'
    Copyright = '(c) 2025'
    Description = 'Secure email notification system using MailKit for Unity-Claude autonomous operation alerting'
    
    PowerShellVersion = '5.1'
    
    # No required modules - self-contained with MailKit assembly loading
    RequiredModules = @()
    
    # Nested modules for enhanced functionality
    NestedModules = @()
    
    # Functions to export from this module
    FunctionsToExport = @(
        # Assembly Loading (Week 5 Day 1 Hour 1-2)
        'Load-MailKitAssemblies',
        
        # Email Configuration and Setup (Week 5 Day 1 Hour 3-4)
        'New-EmailConfiguration',
        'Set-EmailCredentials',
        'Test-EmailConfiguration',
        'Get-EmailConfiguration',
        
        # Email Template System (Week 5 Day 1 Hour 5-6)
        'New-EmailTemplate',
        'Set-EmailTemplate',
        'Get-EmailTemplate',
        'Format-NotificationContent',
        
        # Email Delivery System (Week 5 Day 2 Hour 1-2)
        'Send-UnityClaudeNotification',
        'Send-EmailNotification',
        'Test-EmailDelivery',
        
        # Reliability and Error Handling (Week 5 Day 2 Hour 3-4)
        'Send-EmailWithRetry',
        'Get-EmailDeliveryStatus',
        'Test-EmailConnectivity',
        
        # Integration Functions (Week 5 Day 2 Hour 5-6)
        'Register-EmailNotificationTrigger',
        'Invoke-EmailNotificationTrigger',
        'Get-EmailNotificationTriggers'
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
            Tags = @('Unity', 'Claude', 'Automation', 'Email', 'Notifications', 'MailKit', 'SMTP')
            LicenseUri = ''
            ProjectUri = ''
            IconUri = ''
            ReleaseNotes = @'
Unity-Claude-EmailNotifications v1.0.0 Release Notes

## Phase 2 Week 5 Days 1-2: Email System Implementation

### New Features:
- Secure email notification system using MailKit library
- SMTP configuration with TLS/SSL support and SecureString credential management
- Email template engine with variable substitution and severity-based formatting
- Comprehensive retry logic and error handling for reliable email delivery
- Integration with Unity-Claude autonomous workflow system

### Security Features:
- SecureString-based credential storage with DPAPI encryption
- TLS/SSL SMTP connection support with modern encryption protocols
- Secure configuration file management with encrypted credential storage
- Comprehensive authentication validation and connection testing

### Template System:
- HTML and plain text email template support
- Severity-based formatting (Critical, Error, Warning, Informational)
- Unity-specific error context templates with dynamic content
- Variable substitution system for notification customization

### Integration Capabilities:
- Unity compilation error notification triggers
- Claude response failure and success alerting
- Workflow status change notifications
- System health and performance threshold alerting

### Reliability Features:
- Email delivery retry logic with exponential backoff
- SMTP connection fallback mechanisms
- Comprehensive logging and error reporting
- Email delivery status tracking and analytics

### Dependencies:
- MailKit NuGet package (latest version)
- MimeKit dependency (automatic with MailKit)
- PowerShell 5.1+ with .NET Framework 4.5+
- Administrator privileges for initial MailKit installation

This module provides enterprise-grade email notification capabilities essential for
autonomous Unity-Claude operation and production deployment scenarios.
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
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQU4QIBBCWkEXqy1hWA36eM7u+K
# EeegggMwMIIDLDCCAhSgAwIBAgIQdR0W2SKoK5VE8JId4ZxrRTANBgkqhkiG9w0B
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
# CQQxFgQUwFs8yR0pZfNV76Vx+fVTDkjdkAUwDQYJKoZIhvcNAQEBBQAEggEAjJvA
# IBSn/T98z9IKI3dYNDpnVfMnuCFWWs/34wvnh+m6bhjuMduiHvNovI0jftT0tJJl
# XBCqrhd+G/ptR1fztoW10dsSBJxv8RcNivpGyi+F098sb6eFhl3RgaMdne/rpdPz
# SyGplMbyN/jSmlvjiZ68cfiGaeYOdOzcKz3ERxzIlz16/UXS0uz0nhj1q2r7/PJt
# 1thTj9m77rGL2AId8YLXTJqe/OnhZ9hRFsddidaY7czFI3NMvULjLYlC8JcjC6P4
# LhnZWzRGUNQnsJIv/oyDOPgkfrVUdXmK4jXKVva+iDXVgleU0UBSJbNVNEG3f5S3
# U9I2rn7o7FWBLPvWZQ==
# SIG # End signature block
