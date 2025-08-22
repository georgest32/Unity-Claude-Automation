# Unity-Claude-RunspaceManagement Module Manifest
# Phase 1 Week 2 Days 1-2: Session State Configuration
# Date: 2025-08-21

@{
    RootModule = 'Unity-Claude-RunspaceManagement.psm1'
    ModuleVersion = '1.0.0'
    GUID = '12345678-1234-1234-1234-123456789abc'
    Author = 'Unity-Claude-Automation'
    CompanyName = 'Unity-Claude-Automation'
    Copyright = '(c) 2025'
    Description = 'PowerShell 5.1 compatible runspace pool management with InitialSessionState configuration'
    
    PowerShellVersion = '5.1'
    
    # Required modules for dependency management - COMMENTED OUT to prevent nesting limit issues
    # RequiredModules = @(
    #     'Unity-Claude-ParallelProcessing'
    # )
    
    # Nested modules for enhanced functionality
    NestedModules = @()
    
    # Functions to export from this module
    FunctionsToExport = @(
        # InitialSessionState Configuration (Hour 1-3)
        'New-RunspaceSessionState',
        'Set-SessionStateConfiguration',
        'Add-SessionStateModule',
        'Add-SessionStateVariable',
        'Test-SessionStateConfiguration',
        
        # Module/Variable Pre-loading (Hour 4-6)
        'Import-SessionStateModules',
        'Initialize-SessionStateVariables',
        'Get-SessionStateModules',
        'Get-SessionStateVariables',
        
        # SessionStateVariableEntry Sharing (Hour 7-8)
        'New-SessionStateVariableEntry',
        'Add-SharedVariable',
        'Get-SharedVariable',
        'Set-SharedVariable',
        'Remove-SharedVariable',
        
        # Basic Runspace Pool Management (Days 1-2)
        'New-ManagedRunspacePool',
        'Open-RunspacePool',
        'Close-RunspacePool',
        'Get-RunspacePoolStatus',
        'Test-RunspacePoolHealth',
        
        # Production Runspace Pool Infrastructure (Days 3-4 Hour 1-2)
        'New-ProductionRunspacePool',
        'Submit-RunspaceJob',
        'Update-RunspaceJobStatus',
        'Wait-RunspaceJobs',
        'Get-RunspaceJobResults',
        
        # Throttling and Resource Control (Days 3-4 Hour 5-6)
        'Test-RunspacePoolResources',
        'Set-AdaptiveThrottling',
        'Invoke-RunspacePoolCleanup'
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
            Tags = @('Unity', 'Claude', 'Automation', 'Runspace', 'Parallel', 'Threading')
            LicenseUri = ''
            ProjectUri = ''
            IconUri = ''
            ReleaseNotes = 'Phase 1 Week 2 Days 1-2: Session State Configuration implementation'
        }
    }
    
    # Minimum version of the PowerShell host required by this module
    PowerShellHostName = ''
    PowerShellHostVersion = ''
    
    # Minimum version of Microsoft .NET Framework required by this module
    DotNetFrameworkVersion = '4.5'
    
    # Minimum version of the common language runtime (CLR) required by this module
    CLRVersion = '4.0'
    
    # Script files (.ps1) that are run in the caller's environment prior to importing this module
    ScriptsToProcess = @()
    
    # Type files (.ps1xml) to be loaded when importing this module
    TypesToProcess = @()
    
    # Format files (.ps1xml) to be loaded when importing this module
    FormatsToProcess = @()
    
    # Assembly files (.dll) to be loaded when importing this module
    RequiredAssemblies = @()
}

# SIG # Begin signature block
# MIIFqQYJKoZIhvcNAQcCoIIFmjCCBZYCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUjwkTnF1poHnCSBmg6M1V/VaH
# ZtqgggMwMIIDLDCCAhSgAwIBAgIQdR0W2SKoK5VE8JId4ZxrRTANBgkqhkiG9w0B
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
# CQQxFgQUjW29ijzI9jndzGjalw0Gd+SsbWMwDQYJKoZIhvcNAQEBBQAEggEAcFS+
# MO3aUFBEIVW4M0o+N8b4LtqgRyWzDyPXGFLfXMWPP41ZQAb1fRkfMfNBnwtYoVEx
# zRFydOfhQH0knKKk5BiMpjYVvDsNQLFPJpV43aDeXjc5A1A6Tg0tM0XiuIIrumwQ
# i36L7nHrQbGc9wZd7tWXbYsVQiJSXUKh3Y8DyAwtNfSYNLYB1QWUCE/Vwq8kZ0ty
# 5bsmv/02hentgmmV8/tSAl3t7s+2Rl133pI9p8ryP+T5lhE3zgyzB8HFJbPVgFP1
# G6pSbtMA9cFg3n8wIuwBdqrZiVPO7N7xOzGg6vGfI+tdlWi1Kk+cd+JUaxqnPLB2
# U5GPLjML4EOaZgqodA==
# SIG # End signature block
