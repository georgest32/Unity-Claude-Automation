# Unity-Claude-UnityParallelization Module Manifest
# Phase 1 Week 3 Days 1-2: Unity Compilation Parallelization
# Date: 2025-08-21

@{
    RootModule = 'Unity-Claude-UnityParallelization.psm1'
    ModuleVersion = '1.0.0'
    GUID = '87654321-4321-4321-4321-210987654321'
    Author = 'Unity-Claude-Automation'
    CompanyName = 'Unity-Claude-Automation'
    Copyright = '(c) 2025'
    Description = 'Unity compilation parallelization with concurrent error detection and export'
    
    PowerShellVersion = '5.1'
    
    # Required modules for dependency management - COMMENTED OUT to prevent nesting limit issues
    # RequiredModules = @(
    #     'Unity-Claude-RunspaceManagement'
    #     # Note: ParallelProcessing included transitively through RunspaceManagement
    # )
    
    # Nested modules for enhanced functionality
    NestedModules = @()
    
    # Functions to export from this module
    FunctionsToExport = @(
        # Unity Project Discovery and Configuration (Hour 1-2)
        'Find-UnityProjects',
        'Register-UnityProject',
        'Get-UnityProjectConfiguration',
        'Set-UnityProjectConfiguration',
        'Test-UnityProjectAvailability',
        
        # Parallel Unity Monitoring Architecture (Hour 1-2)
        'New-UnityParallelMonitor',
        'Start-UnityParallelMonitoring',
        'Stop-UnityParallelMonitoring',
        'Get-UnityMonitoringStatus',
        
        # Unity Compilation Process Integration (Hour 3-4)
        'Start-UnityCompilationJob',
        'Monitor-UnityCompilation',
        'Wait-UnityCompilationCompletion',
        'Stop-UnityCompilationJob',
        'Get-UnityCompilationResults',
        
        # Unity Log File Monitoring (Hour 3-4)  
        'Start-UnityLogMonitoring',
        'Parse-UnityEditorLog',
        'Extract-UnityCompilationErrors',
        'Stop-UnityLogMonitoring',
        
        # Concurrent Error Detection (Hour 5-6)
        'Start-ConcurrentErrorDetection',
        'Classify-UnityCompilationError',
        'Aggregate-UnityErrors',
        'Deduplicate-UnityErrors',
        'Get-UnityErrorStatistics',
        
        # Concurrent Error Export (Hour 7-8)
        'Export-UnityErrorsConcurrently',
        'Format-UnityErrorsForClaude',
        'Optimize-UnityErrorExport',
        'Integrate-UnitySystemStatus',
        'Test-UnityParallelizationPerformance'
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
            Tags = @('Unity', 'Claude', 'Automation', 'Parallelization', 'Compilation', 'Monitoring')
            LicenseUri = ''
            ProjectUri = ''
            IconUri = ''
            ReleaseNotes = 'Phase 1 Week 3 Days 1-2: Unity Compilation Parallelization implementation'
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
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUV1MMwdJg0BRomgXawm+fctEU
# K4qgggMwMIIDLDCCAhSgAwIBAgIQdR0W2SKoK5VE8JId4ZxrRTANBgkqhkiG9w0B
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
# CQQxFgQU9rt+itLdtK21hzQ3BwwXtDu0tTUwDQYJKoZIhvcNAQEBBQAEggEAP0G/
# Ycyo4hXak22kEHGSn7b0gru+YPnW7OronC4XPPurdLTTgELUKIJnCfvbEQypiqAA
# fYzyUZjBaJu7DBuQt98Rm4fGbpI7fhrFqLiHHJyfWVXU0v34zKaylSqi6TbLFFph
# i5jsFD/LaFVSvuFkcGV1Xbr7bzMAeJb7Hl/qEbjNMtUhj27/Wiv1YOi7teQw87rb
# b9IyX4bpVqQWiSsqCELtkjz9w0XLD1TPNYnaGu06hZliUGgNjxV0DyvuNL+q8xgB
# /lGFbQdWJ+Yn7xsTii1UOWafP8R+/GAUFyaP5f6L84Dbbf3YkfDo5W6J0qXxXjjT
# FfUuY6mJErhLLw42iw==
# SIG # End signature block
