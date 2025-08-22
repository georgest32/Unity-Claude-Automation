@{
    # Module manifest for Unity-TestAutomation module
    
    # Script module or binary module file associated with this manifest.
    RootModule = 'Unity-TestAutomation.psm1'
    
    # Version number of this module.
    ModuleVersion = '1.0.0'
    
    # ID used to uniquely identify this module
    GUID = 'f1e2d3c4-b5a6-7890-abcd-ef1234567890'
    
    # Author of this module
    Author = 'Unity-Claude Automation System'
    
    # Company or vendor of this module
    CompanyName = 'Sound and Shoal'
    
    # Copyright statement for this module
    Copyright = '(c) 2025 Sound and Shoal. All rights reserved.'
    
    # Description of the functionality provided by this module
    Description = 'Unity Test Automation module providing comprehensive test execution, result parsing, and reporting capabilities with enhanced security integration'
    
    # Minimum version of the PowerShell engine required by this module
    PowerShellVersion = '5.1'
    
    # Modules that must be imported into the global environment prior to importing this module
    RequiredModules = @('SafeCommandExecution')
    
    # Functions to export from this module
    FunctionsToExport = @(
        'Invoke-UnityEditModeTests',
        'Invoke-UnityPlayModeTests',
        'Get-UnityTestResults',
        'Get-UnityTestCategories',
        'New-UnityTestFilter',
        'Invoke-PowerShellTests',
        'Find-CustomTestScripts',
        'Get-TestResultAggregation',
        'Export-TestReport'
    )
    
    # Cmdlets to export from this module
    CmdletsToExport = @()
    
    # Variables to export from this module
    VariablesToExport = @()
    
    # Aliases to export from this module
    AliasesToExport = @()
    
    # Private data to pass to the module specified in RootModule/ModuleToProcess
    PrivateData = @{
        PSData = @{
            Tags = @('Unity', 'Testing', 'Automation', 'TestRunner', 'Pester', 'XML', 'Reporting')
            ProjectUri = 'https://github.com/sound-and-shoal/unity-claude-automation'
            ReleaseNotes = 'Phase 1 Day 4: Complete Unity Test Automation implementation with EditMode, PlayMode, Pester integration, and multi-format reporting'
        }
    }
}
# SIG # Begin signature block
# MIIFqQYJKoZIhvcNAQcCoIIFmjCCBZYCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQU9Hw5FikAuk7e6H8WbX0oVLQw
# GNegggMwMIIDLDCCAhSgAwIBAgIQdR0W2SKoK5VE8JId4ZxrRTANBgkqhkiG9w0B
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
# CQQxFgQUDROZvBd8zHY2o5l8o6Ra9mrUQ8UwDQYJKoZIhvcNAQEBBQAEggEAHIgB
# TYsajA8FshHeN3tnAEORp3RpIPpOLeYtpq+QhRy0odoYsr0a0zpWf4t4XFHt2s0a
# FVjozveb8SlWf89OZlb3pYrJ7V/XeBjDplL6gJCyqbQ7q2axQ8FwIZm6wAfI+JUJ
# fQeEbEJ1xIm1ycQZwUKVc8QDXyKhMtlfGjcutVrB2co6oXfPGGJPlyGWHAjDD/61
# k8ensC3TKuqtN61JPDvTefl6oE83CLrQVCGIrq8A1N0u55SmgQKIQNbcRFjPQGIK
# BGwSQ2XRk0QlA04GpFCIcpP4p+n8PplDxWdh1Z9NXbC6VKpWp1CTiNw+nYVgPeP7
# D1BYHbTKKxLGqaKt6Q==
# SIG # End signature block
