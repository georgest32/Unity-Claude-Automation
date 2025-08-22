@{
    # Script module or binary module file associated with this manifest.
    RootModule = 'Unity-Claude-ErrorHandling.psm1'

    # Version number of this module.
    ModuleVersion = '1.0.0'

    # ID used to uniquely identify this module
    GUID = 'a1b2c3d4-e5f6-7890-1234-567890abcdef'

    # Author of this module
    Author = 'Unity-Claude Automation System'

    # Company or vendor of this module
    CompanyName = 'Unity-Claude Automation'

    # Copyright statement for this module
    Copyright = '(c) 2025 Unity-Claude Automation. All rights reserved.'

    # Description of the functionality provided by this module
    Description = 'Error handling framework for Unity-Claude parallel processing. Provides BeginInvoke/EndInvoke error management, circuit breaker patterns, exponential backoff retry logic, and comprehensive error aggregation for runspace pool operations in PowerShell 5.1.'

    # Minimum version of the PowerShell engine required by this module
    PowerShellVersion = '5.1'

    # Minimum version of Microsoft .NET Framework required by this module
    DotNetFrameworkVersion = '4.5'

    # Modules that must be imported into the global environment prior to importing this module
    RequiredModules = @(
        'Unity-Claude-ParallelProcessing'
    )

    # Functions to export from this module
    FunctionsToExport = @(
        # BeginInvoke/EndInvoke Error Handling Framework
        'Invoke-AsyncWithErrorHandling',
        'New-ParallelErrorAggregator',
        
        # Error Aggregation and Classification System
        'Get-ParallelErrorClassification',
        'Get-ParallelErrorReport',
        
        # Circuit Breaker and Resilience Framework
        'Initialize-CircuitBreaker',
        'Test-CircuitBreakerState', 
        'Update-CircuitBreakerState',
        
        # Integration and Monitoring
        'Initialize-ParallelErrorHandling',
        'Get-ParallelErrorHandlingStats'
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
            # Tags applied to this module
            Tags = @('Unity', 'Claude', 'Automation', 'ErrorHandling', 'Parallel', 'BeginInvoke', 'CircuitBreaker', 'Resilience')

            # Release notes
            ReleaseNotes = 'Unity-Claude Error Handling Framework v1.0.0

Features:
- BeginInvoke/EndInvoke error handling wrapper for async runspace operations
- Comprehensive error stream monitoring and aggregation
- Circuit breaker pattern implementation for service protection
- Exponential backoff retry logic with error classification
- ConcurrentBag-based thread-safe error collection
- Integration with existing ErrorHandling.psm1 classification patterns
- Performance monitoring with minimal overhead async patterns

Implementation Details:
- PowerShell 5.1 compatible (.NET Framework 4.5)
- Thread-safe operations using ConcurrentBag and synchronized hashtables
- Proper resource disposal with try-catch-finally patterns
- Error classification: Transient, Permanent, RateLimited, Unity
- Circuit breaker states: Closed, Open, Half-Open with automatic recovery
- High-performance error aggregation designed for runspace pool scenarios

Thread Safety:
- All operations are thread-safe using concurrent collections
- Supports multiple runspace error aggregation
- Comprehensive resource disposal and cleanup
- Designed for 75-93% performance improvement scenarios with robust error handling'
        }
    }
}
# SIG # Begin signature block
# MIIFqQYJKoZIhvcNAQcCoIIFmjCCBZYCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQU4oaw+u0txurXYF8rpFqO/PZB
# +zKgggMwMIIDLDCCAhSgAwIBAgIQdR0W2SKoK5VE8JId4ZxrRTANBgkqhkiG9w0B
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
# CQQxFgQU96GXQGGfOZ1oyJa2rTXu5h0wU3UwDQYJKoZIhvcNAQEBBQAEggEAdsRS
# 3iBclgCyXwNLTERcWmy9TMBZ3Tnqd6HkQ7B+HMOPxBOCRBt3FkSwXeoTiwpwOpb6
# LuHDFm3gED5tYIqs3r8WEnd0SEoZhrGjarj65t+NbCMyY6ar1iWkNys10BPg2VUZ
# 350r4GKaMM9Tste8xYyIWSvIxhECjS2xhHrfKG5j9AteR4QD1vt2ZseWloookVK+
# mc2maPqM1ij0Vi08AEgdZcgnTV4D2wJpo5uHxB/xltuQRNKjSRNZ5/at1HwYpjGn
# s4Qq0+ZCG9pV/J82cOymBtm/WLSE3IePQU3/xYbQqDPa839ci9p/+cQyTaIE5ZCz
# xYMEmqbxCtXaRvXVSw==
# SIG # End signature block
