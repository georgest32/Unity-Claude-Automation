@{
    # Script module or binary module file associated with this manifest.
    RootModule = 'Unity-Claude-ConcurrentCollections.psm1'

    # Version number of this module.
    ModuleVersion = '1.0.0'

    # ID used to uniquely identify this module
    GUID = 'f1e2d3c4-b5a6-9786-5432-1098fedcba87'

    # Author of this module
    Author = 'Unity-Claude Automation System'

    # Company or vendor of this module
    CompanyName = 'Unity-Claude Automation'

    # Copyright statement for this module
    Copyright = '(c) 2025 Unity-Claude Automation. All rights reserved.'

    # Description of the functionality provided by this module
    Description = 'Thread-safe collection wrappers for Unity-Claude parallel processing. Provides ConcurrentQueue and ConcurrentBag functionality compatible with PowerShell 5.1 (.NET Framework 4.5) for high-performance producer-consumer patterns in Unity automation workflows.'

    # Minimum version of the PowerShell engine required by this module
    PowerShellVersion = '5.1'

    # Minimum version of Microsoft .NET Framework required by this module
    DotNetFrameworkVersion = '4.5'

    # Functions to export from this module
    FunctionsToExport = @(
        # ConcurrentQueue functions
        'New-ConcurrentQueue',
        'Add-ConcurrentQueueItem',
        'Get-ConcurrentQueueItem', 
        'Test-ConcurrentQueueEmpty',
        'Get-ConcurrentQueueCount',
        
        # ConcurrentBag functions
        'New-ConcurrentBag',
        'Add-ConcurrentBagItem',
        'Get-ConcurrentBagItem',
        'Test-ConcurrentBagEmpty', 
        'Get-ConcurrentBagCount',
        'Get-ConcurrentBagItems',
        
        # Producer-Consumer pattern helpers
        'Start-ProducerConsumerQueue',
        'Stop-ProducerConsumerQueue',
        
        # Performance monitoring
        'Get-ConcurrentCollectionMetrics'
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
            Tags = @('Unity', 'Claude', 'Automation', 'Parallel', 'Threading', 'ConcurrentCollections', 'Performance', 'PowerShell')

            # Release notes
            ReleaseNotes = 'Unity-Claude Concurrent Collections Module v1.0.0

Features:
- Thread-safe ConcurrentQueue wrapper functions for FIFO processing
- Thread-safe ConcurrentBag wrapper functions for unordered high-performance scenarios
- Producer-Consumer pattern helpers with cancellation token support
- Performance monitoring and metrics collection
- PowerShell 5.1 compatible (.NET Framework 4.5)
- Optimized for Unity compilation + Claude submission + response processing workflows

Implementation Details:
- Lock-free operations using .NET System.Collections.Concurrent
- TryDequeue/TryTake patterns for non-blocking operations
- Timeout support with retry logic for reliability
- Comprehensive error handling and logging
- Performance monitoring with memory usage estimation
- Designed for 75-93% performance improvement over sequential processing

Thread Safety:
- All operations are thread-safe and lock-free
- Supports multiple producer and consumer threads
- Graceful shutdown with cancellation token support
- No deadlock risk in properly implemented workflows'
        }
    }
}
# SIG # Begin signature block
# MIIFqQYJKoZIhvcNAQcCoIIFmjCCBZYCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUcT8lqF7rS/y3IgFcSRUBfbBm
# nrSgggMwMIIDLDCCAhSgAwIBAgIQdR0W2SKoK5VE8JId4ZxrRTANBgkqhkiG9w0B
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
# CQQxFgQUlHLzWh6nyQrtk++oTK/TSzbt3AAwDQYJKoZIhvcNAQEBBQAEggEAeu6B
# 0kQZ9f7CNCmT/0wNLQmNmFapjLgMsVraZWaFbFOjLPFHB3z+m19jUJl+5WD1lFd4
# /x0GXVzAZCaoQhU9nziOIbHEB7MG4ZvV+tTqwQvpObBp+wJMjVkLTy+ACGRW1Te9
# AiDTRwFq90Vn+HYByNrnhJ+8FQk3OwDHWtotKURFCeB9tOgjBPVsbji5Wlsh9iYr
# Svs1B/aXPxtnwlDwBRVHJrma5eViuuPpoJGGUClTuWB64Au5DUJTLT2zq5s3s9Pm
# hqYmh8PSDLj6H0msCTKpfDN9hWwiLBYYyXK2hM4VLDe41bPCJD/ooCXclwjJ0Fvw
# U6DH0vxyhXGe38fSJw==
# SIG # End signature block
