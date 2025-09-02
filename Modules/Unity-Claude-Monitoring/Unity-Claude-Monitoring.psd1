# Module manifest for Unity-Claude-Monitoring
# Generated: 2025-08-24

@{
    # Module information
    RootModule = 'Unity-Claude-Monitoring.psm1'
    ModuleVersion = '1.0.0'
    GUID = 'e8f4c3d2-9a1b-4f5e-8c7d-2b6a4e9f1c3d'
    Author = 'Unity-Claude Automation Team'
    CompanyName = 'Unity-Claude'
    Copyright = '(c) 2025 Unity-Claude. All rights reserved.'
    Description = 'Monitoring and alerting module for Unity-Claude Automation platform'
    PowerShellVersion = '7.0'

    # Functions to export
    FunctionsToExport = @(
        'Get-ServiceHealth',
        'Test-ServiceLiveness',
        'Test-ServiceReadiness',
        'Get-PrometheusMetrics',
        'Get-ContainerMetrics',
        'Search-Logs',
        'Get-ServiceLogs',
        'Send-Alert',
        'Get-ActiveAlerts',
        'Start-MonitoringStack',
        'Stop-MonitoringStack'
    )

    # Cmdlets to export
    CmdletsToExport = @()

    # Variables to export
    VariablesToExport = @()

    # Aliases to export
    AliasesToExport = @()

    # Private data
    PrivateData = @{
        PSData = @{
            Tags = @('Monitoring', 'Observability', 'Prometheus', 'Grafana', 'Loki', 'Docker', 'Unity-Claude')
            LicenseUri = 'https://github.com/unity-claude/automation/LICENSE'
            ProjectUri = 'https://github.com/unity-claude/automation'
            IconUri = ''
            ReleaseNotes = @"
# Release Notes

## Version 1.0.0 (2025-08-24)
- Initial release
- Health check functions for all services
- Prometheus metrics integration
- Loki log search capabilities
- Alertmanager integration
- Docker Compose management
- Comprehensive monitoring dashboards
"@
        }
    }

    # Module dependencies
    RequiredModules = @()

    # Script files to run in the caller's environment
    ScriptsToProcess = @()

    # Type files (.ps1xml) to load
    TypesToProcess = @()

    # Format files (.ps1xml) to load
    FormatsToProcess = @()

    # Modules to import as nested modules
    NestedModules = @()

    # DSC resources to export
    DscResourcesToExport = @()

    # List of all files packaged with this module
    FileList = @(
        'Unity-Claude-Monitoring.psm1',
        'Unity-Claude-Monitoring.psd1'
    )
}
# SIG # Begin signature block
# MIIFzgYJKoZIhvcNAQcCoIIFvzCCBbsCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCCFyhz9Jz4hYE2i
# lR3QIFVVi7u6hz4mrHd9TdlEw4oTnaCCAzAwggMsMIICFKADAgECAhB1HRbZIqgr
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
# MAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIKgrC7PashOjLNFKYqhvTBsi
# jQcR6xvHOGl+VLPz1rKJMA0GCSqGSIb3DQEBAQUABIIBADSrL7c8Q3KvcoI3OJlg
# LncBULlxpEr7mnQFkU4fiLIMflLevOyRZ+dzV/TYQE1X57sIMBmUFnh1ZH26E5CA
# kp37qPckRzpNFdfldO9g6Wx0dxFIiyow0RDhHX4R3HWjbSpSo+9zVAmp6i5oRyyK
# +nD4krxS4dmYAPoQlZsy8UI2k9PT+Mvpjg4Vs5bzlgLBuCM7wPnEKodR2NjSxlhb
# fbKshnajS6Z2xI8o+X9i0MmcfqTlRwgmNqLTBdErkNs/FDHXlNrStaTVYQvgaX30
# GbLgfag5YLAMbaYSVNbAlV4aHmBy520Mksrc1JWsKjs9G1xmJIAnwpmDgxDkLnh4
# 2No=
# SIG # End signature block
