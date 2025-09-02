@{
    # Module Manifest for Unity-Claude-Cache

    # Script module or binary module file associated with this manifest
    RootModule = 'Unity-Claude-Cache.psm1'

    # Version number of this module
    ModuleVersion = '1.0.0'

    # ID used to uniquely identify this module
    GUID = 'e8f4d3a2-9c5b-4e87-b123-456789abcdef'

    # Author of this module
    Author = 'Unity Claude Automation System'

    # Company or vendor of this module
    CompanyName = 'Unity Claude Automation'

    # Copyright statement for this module
    Copyright = '(c) 2025 Unity Claude Automation. All rights reserved.'

    # Description of the functionality provided by this module
    Description = 'Redis-like in-memory cache implementation with TTL management, LRU eviction, and thread-safe operations for high-performance documentation system'

    # Minimum version of the PowerShell engine required by this module
    PowerShellVersion = '5.1'

    # Functions to export from this module
    FunctionsToExport = @(
        'New-CacheManager',
        'Set-CacheItem',
        'Get-CacheItem',
        'Remove-CacheItem',
        'Clear-Cache',
        'Get-CacheStatistics',
        'Test-CacheKey',
        'Get-CacheKeys',
        'Save-CacheToDisk',
        'Start-CacheCleanup'
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
            # Tags applied to this module
            Tags = @('Cache', 'Performance', 'InMemory', 'LRU', 'TTL', 'Redis-like')

            # A URL to the license for this module
            LicenseUri = ''

            # A URL to the main website for this project
            ProjectUri = ''

            # A URL to an icon representing this module
            IconUri = ''

            # ReleaseNotes of this module
            ReleaseNotes = @'
## Version 1.0.0
- Initial release
- Redis-like in-memory caching
- TTL (Time To Live) support
- LRU (Least Recently Used) eviction
- Thread-safe operations
- Priority-based caching
- Statistics tracking
- Persistence to disk
- Automatic cleanup of expired items
'@
        }
    }
}
# SIG # Begin signature block
# MIIFzgYJKoZIhvcNAQcCoIIFvzCCBbsCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCDkAkabmF5OoCyk
# o2EiIVDb1BQK40E85c+BwyhummmhA6CCAzAwggMsMIICFKADAgECAhB1HRbZIqgr
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
# MAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIOHH1ntpDZEo4zGrHxiE0JFM
# PNChOsrgL4evhCaCPX9KMA0GCSqGSIb3DQEBAQUABIIBAFsxctfS8JPt/FzLqgCN
# 3TCYTVXSpsK6CW1MgG0pJ+yKJJhtql7mWa2Xgn4Ht/0dvkcmD71GcPjNchIGvHEh
# RZxMkJGxfLfVsVe16n/hrMLgDpvdJLH/y5h0RMZYGmvgxf1FPyggy9JVO4WRzfDH
# vGjy+jjGkRLtiiWXdd2t2pNuVF6H+ezqKoOuozrLWVO6fw4OacXoP/oyNLuFpeJb
# stbuz7sKzdRjnEKtAWcssT8aOm3kiojVswB1MdiunUcdkytmIMUqaf4IQuKn6lBP
# 0eXwNJZmuJhpco6ixzoRmpQ05OqiqeP1YVPQjRlIEUMmo6qNNlMTKeHTtISQG2o7
# 3vc=
# SIG # End signature block
