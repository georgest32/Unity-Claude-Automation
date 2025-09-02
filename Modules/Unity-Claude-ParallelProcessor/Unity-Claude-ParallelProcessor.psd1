@{
    # Module Manifest for Unity-Claude-ParallelProcessor

    # Script module or binary module file associated with this manifest
    RootModule = 'Unity-Claude-ParallelProcessor-Refactored.psm1'

    # Version number of this module
    ModuleVersion = '2.0.0'

    # ID used to uniquely identify this module
    GUID = 'a7b6c5d8-9e0f-1a2b-d345-678901bcdef0'

    # Author of this module
    Author = 'Unity Claude Automation System'

    # Company or vendor of this module
    CompanyName = 'Unity Claude Automation'

    # Copyright statement for this module
    Copyright = '(c) 2025 Unity Claude Automation. All rights reserved.'

    # Description of the functionality provided by this module
    Description = 'REFACTORED: Modular parallel processing framework with 6-component architecture - runspace pools, job scheduling, batch processing, statistics tracking, and optimized performance'

    # Minimum version of the PowerShell engine required by this module
    PowerShellVersion = '5.1'

    # Functions to export from this module
    FunctionsToExport = '*'

    # Cmdlets to export from this module
    CmdletsToExport = @()

    # Variables to export from this module
    VariablesToExport = @()

    # Aliases to export from this module
    AliasesToExport = @()

    # Private data to pass to the module specified in RootModule
    PrivateData = @{
        PSData = @{
            # Tags applied to this module
            Tags = @('ParallelProcessing', 'Runspace', 'Performance', 'Threading', 'BatchProcessing', 'ProducerConsumer', 'Refactored', 'Modular', 'ComponentBased')

            # A URL to the license for this module
            LicenseUri = ''

            # A URL to the main website for this project
            ProjectUri = ''

            # A URL to an icon representing this module
            IconUri = ''

            # ReleaseNotes of this module
            ReleaseNotes = @'
## Version 2.0.0 (Refactored)
- BREAKING CHANGE: Modular component-based architecture
- Split monolithic 907-line module into 6 focused components:
  * ParallelProcessorCore - Core utilities and configuration
  * RunspacePoolManager - Runspace pool lifecycle management
  * JobScheduler - Job submission, execution and tracking
  * StatisticsTracker - Performance statistics and monitoring
  * BatchProcessingEngine - Batch processing with producer-consumer patterns
  * ModuleFunctions - Public API and main processor class
- Improved maintainability and testability
- Enhanced error handling and logging
- Full backward compatibility maintained
- Added module health checking and diagnostics
- Enhanced statistics and reporting capabilities
- Optimized for PowerShell 5.1+ with thread-safety improvements

## Version 1.0.0
- Initial release
- Runspace pool management  
- Optimal thread calculation (2-4x CPU cores)
- Job scheduling and retry logic
- Result aggregation
- Error handling with configurable retries
- Producer-consumer pattern implementation
- Batch processing pipeline
- Progress reporting
- Cancellation token support
- Comprehensive statistics tracking
'@
        }
    }
}
# SIG # Begin signature block
# MIIFzgYJKoZIhvcNAQcCoIIFvzCCBbsCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCDxmtp0+JLdGu9Q
# +F6Q0fwBg96emipj9X089tVndAmAoKCCAzAwggMsMIICFKADAgECAhB1HRbZIqgr
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
# MAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIH5bsPLRd8H8YWQVZOdMCx87
# Nj1pvKTY3+SmL2j4uPQ0MA0GCSqGSIb3DQEBAQUABIIBADsmnYOadY2gcsWO0b7m
# c/lDM6Zfwm3epRLCv6UGMbymRj7FGML6UrlVXqJCNKdx20cYGxs+vgbljFJ1EQz+
# rCWES/RbJFRcnil1+YuXuQSL+IcIfWLb4tYpjTUqqVrLn8/tQ68aJD0esiwCs8Rw
# S2H5fGm0robEvFOO8foQZnsOtr2RzDAQERp+qX0Dwrj+aUkopCeh0x5jnlmYoBtV
# x7ujHdXJ03KPP/q+ofzcQYqURgmF3Y2u50R2CPV9Com/YPrYOPDe0JqMBNqmBCnZ
# B1KbtecE8MdPtKCLBTK1ZCNhVp4jaFNArIcSJUj4ZsU3vL1BPtgitF5O8rFQIqZA
# 5LU=
# SIG # End signature block
