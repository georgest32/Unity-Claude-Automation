# Unity-Claude-ClaudeParallelization Module Manifest
# Phase 1 Week 3 Days 3-4: Claude Integration Parallelization
# Date: 2025-08-21

@{
    RootModule = 'Unity-Claude-ClaudeParallelization.psm1'
    ModuleVersion = '1.0.0'
    GUID = '11223344-5566-7788-9900-aabbccddeeff'
    Author = 'Unity-Claude-Automation'
    CompanyName = 'Unity-Claude-Automation'
    Copyright = '(c) 2025'
    Description = 'Claude API/CLI parallelization with concurrent submission and response processing'
    
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
        # Parallel Claude API Submission (Hour 1-2)
        'New-ClaudeParallelSubmitter',
        'Submit-ClaudeAPIParallel',
        'Get-ClaudeAPIRateLimit',
        'Set-ClaudeAPIThrottling',
        'Monitor-ClaudeAPIUsage',
        
        # Parallel Claude CLI Automation (Hour 3-4)
        'New-ClaudeCLIParallelManager',
        'Submit-ClaudeCLIParallel',
        'Coordinate-ClaudeCLIWindows',
        'Queue-ClaudeCLIJobs',
        'Capture-ClaudeCLIResponses',
        
        # Concurrent Response Processing (Hour 5-6)
        'Start-ConcurrentResponseMonitoring',
        'Parse-ClaudeResponseParallel',
        'Process-ClaudeJSONResponse',
        'Aggregate-ClaudeResponses',
        'Extract-ClaudeRecommendations',
        
        # Performance Optimization (Hour 7-8)
        'Monitor-ClaudePerformance',
        'Optimize-ClaudeThrottling',
        'Integrate-ClaudeUnityWorkflow',
        'Handle-ClaudeErrors',
        'Test-ClaudeParallelizationPerformance'
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
            Tags = @('Unity', 'Claude', 'Automation', 'Parallelization', 'API', 'CLI')
            LicenseUri = ''
            ProjectUri = ''
            IconUri = ''
            ReleaseNotes = 'Phase 1 Week 3 Days 3-4: Claude Integration Parallelization implementation'
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
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUnLjbeH3niO5O/rnz7uoBg2qZ
# 27+gggMwMIIDLDCCAhSgAwIBAgIQdR0W2SKoK5VE8JId4ZxrRTANBgkqhkiG9w0B
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
# CQQxFgQUp3Uov7WBjv9Gnx1YKTyOJxRRHLQwDQYJKoZIhvcNAQEBBQAEggEAQNN1
# 5599ajjvVQnG6vDUwVR3Z+/tW+2qKsElBILw0FwPi/Ebr9Hzp/cEdwQUnB0i0M0p
# tlHtbxSZ9Fz5fBs2q/7WcRcK6VwN89oHgSDLKXwvfWX8c0YmTFYZ21wFRFPCl7sV
# oEkGzCzbpFSIji8Bw3g03Fhd4Acx1kpYRGA2Dhdyoxf0DR4doZVZiS5jIdnADp7I
# AXPS1X2FFXXdGNs5Gli6lUWPqLylzFahNjCzEnbfZzuze0w6rkU6UyJ3qc7ObBEZ
# yxosx/nIv5VWoJfxOgaORJx4G+IVenpXefbzKl96OK2ctcUgnUdTp+Yz0KoUL/nr
# 6ryu6So0iykeMPlcrg==
# SIG # End signature block
