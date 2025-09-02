@{
    # Module manifest for Unity-Claude-NotificationConfiguration
    # Generated: 2025-08-22
    # Purpose: Configuration management for notification settings

    # Script module or binary module file associated with this manifest
    RootModule = 'Unity-Claude-NotificationConfiguration.psm1'
    
    # Version number of this module
    ModuleVersion = '1.0.0'
    
    # ID used to uniquely identify this module
    GUID = 'a8f3c2d5-9e7b-4f6a-8c3e-2d5a7b9c1e4f'
    
    # Author of this module
    Author = 'Unity-Claude Automation Team'
    
    # Company or vendor of this module
    CompanyName = 'Auto-m8'
    
    # Copyright statement for this module
    Copyright = '(c) 2025 Auto-m8. All rights reserved.'
    
    # Description of the functionality provided by this module
    Description = 'Configuration management system for Unity-Claude notification settings. Provides tools for managing, validating, and testing notification configurations.'
    
    # Minimum version of the PowerShell engine required by this module
    PowerShellVersion = '5.1'
    
    # Functions to export from this module
    FunctionsToExport = @(
        # Configuration Management
        'Get-NotificationConfig',
        'Set-NotificationConfig',
        'Test-NotificationConfig',
        'Reset-NotificationConfig',
        
        # Backup and Restore
        'Backup-NotificationConfig',
        'Restore-NotificationConfig',
        'Get-ConfigBackupHistory',
        
        # Configuration Wizard
        'Start-NotificationConfigWizard',
        'Test-EmailConfiguration',
        'Test-WebhookConfiguration',
        
        # Validation
        'Test-ConfigurationSchema',
        'Get-ConfigurationDefaults',
        'Merge-ConfigurationSources',
        
        # Utilities
        'Export-NotificationConfig',
        'Import-NotificationConfig',
        'Compare-NotificationConfig',
        'Get-ConfigurationReport'
    )
    
    # Cmdlets to export from this module
    CmdletsToExport = @()
    
    # Variables to export from this module
    VariablesToExport = @()
    
    # Aliases to export from this module
    AliasesToExport = @()
    
    # Private data to pass to the module specified in RootModule
    PrivateData = @{
        PSData = @{
            Tags = @('Unity', 'Claude', 'Automation', 'Configuration', 'Notifications')
            ProjectUri = 'https://github.com/auto-m8/unity-claude-automation'
            IconUri = ''
            ReleaseNotes = 'Initial release - Week 6 Day 5 Implementation'
        }
    }
    
    # Modules that must be imported into the global environment prior to importing this module
    RequiredModules = @(
        'Unity-Claude-SystemStatus',
        'Unity-Claude-EmailNotifications',
        'Unity-Claude-WebhookNotifications'
    )
}
# SIG # Begin signature block
# MIIFzgYJKoZIhvcNAQcCoIIFvzCCBbsCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCDVmA2r2OQdJEUA
# +94OV1dbcK536JJYlQ6pO6lN8mPH/qCCAzAwggMsMIICFKADAgECAhB1HRbZIqgr
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
# MAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIAqmFkdLNS7MTFOREJk+52to
# +yRvgPAfRRMn9ZMMkU5+MA0GCSqGSIb3DQEBAQUABIIBADY1BcJs1wgKC/LWWXSu
# 5xAdwNYEygFdXGFWFKGDw+kea4iZ/jH1GdFnPjozL2VvtP8fbrKfuoWzSuEd/pF3
# mxlWCRAyl0ZPgihp1vZVqU6dqnNY+lZvJFplPnKg+1Xtd4s4UtnKF846bLMgJx05
# sffx6PU6NQGcEq3Fs0/09V/gzA1mI54JXYJMLEHAhgslxRNRnxBp8z+uHZ8mEIDg
# 8/d7IDNIVkZcHTlK38/fGa00RhOkT4AE5KwdDG5MrfeGcqjsCEe3HQAIMalxJAHF
# +PZTVPTkOc4UHSbBGo7EkF78QCiW8iHTu9qIVQzricFjhI4mdnDMFjil1WhRL3cb
# ESc=
# SIG # End signature block
