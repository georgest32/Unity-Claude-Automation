@{
    # Module manifest for Unity-Claude-Learning-Analytics
    
    # Script module or binary module file associated with this manifest
    RootModule = 'Unity-Claude-Learning-Analytics.psm1'
    
    # Version number of this module
    ModuleVersion = '1.0.0'
    
    # ID used to uniquely identify this module
    GUID = 'a8f4d3e2-7b9c-4d5e-8f6a-1c2d3e4f5a6b'
    
    # Author of this module
    Author = 'Unity-Claude Automation System'
    
    # Company or vendor of this module
    CompanyName = 'Unity-Claude'
    
    # Copyright statement for this module
    Copyright = '(c) 2025 Unity-Claude. All rights reserved.'
    
    # Description of the functionality provided by this module
    Description = 'Advanced learning analytics engine for pattern optimization and trend analysis'
    
    # Minimum version of the PowerShell engine required by this module
    PowerShellVersion = '5.1'
    
    # Functions to export from this module
    FunctionsToExport = @(
        'Get-PatternSuccessRate',
        'Get-AllPatternsSuccessRates',
        'Calculate-MovingAverage',
        'Get-LearningTrend',
        'Update-PatternConfidence',
        'Get-AdjustedConfidence',
        'Get-RecommendedPatterns',
        'Get-PatternEffectivenessRanking'
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
            Tags = @('Learning', 'Analytics', 'Trend', 'Pattern', 'Recommendation')
            ProjectUri = 'https://github.com/unity-claude/automation'
            IconUri = ''
            ReleaseNotes = 'Initial release of learning analytics engine'
        }
    }
    
    # Modules that must be imported into the global environment prior to importing this module
    RequiredModules = @('Unity-Claude-Learning')
    
    # Assemblies that must be loaded prior to importing this module
    RequiredAssemblies = @()
    
    # Script files (.ps1) that are run in the caller's environment prior to importing this module
    ScriptsToProcess = @()
    
    # Type files (.ps1xml) to be loaded when importing this module
    TypesToProcess = @()
    
    # Format files (.ps1xml) to be loaded when importing this module
    FormatsToProcess = @()
    
    # Modules to import as nested modules of the module specified in RootModule
    NestedModules = @()
}
# SIG # Begin signature block
# MIIFqQYJKoZIhvcNAQcCoIIFmjCCBZYCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUqnfYRLIAVRLPXNkySy2D0aI7
# wmagggMwMIIDLDCCAhSgAwIBAgIQdR0W2SKoK5VE8JId4ZxrRTANBgkqhkiG9w0B
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
# CQQxFgQUjCp5PyzESlUvIy5Q93GpfpI0f3cwDQYJKoZIhvcNAQEBBQAEggEAP6r4
# Tft0LpLhL/0oLdTLh6mG5c6Xqde47j0K4xNHA7I8waooyvP34HLeIQseaXpW/7e/
# yWXaSMOAYDUK4tOKx50uXiIk+1lT24gQirqN5y8GH+ixbSkKgG+dSLNBck90mmEE
# T5UVeQ5Uaenqwv5QjUjroqED3byy/TwPqvfGRxmhxCn+wk1RWs9407OxrXxfwxs6
# cRFF4o6gRxB0DCoomUD55SXVMS4M7n/B1ntiKfr0/htdqO7sYgk1G1S4i3fMFn/k
# pTrWwvaD/pq7E2dbNWjwP2YPwwn+jdtSgd1LDJdEa6MwyDjXvXjqPQWD484WM5QP
# JVLfw8s6WbFXfLYRIw==
# SIG # End signature block
