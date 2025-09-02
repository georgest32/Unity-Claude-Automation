@{
    # Module manifest for Unity-Claude-TriggerManager

    # Script module or binary module file associated with this manifest.
    RootModule = 'Unity-Claude-TriggerManager.psm1'

    # Version number of this module.
    ModuleVersion = '1.0.0'

    # Supported PSEditions
    CompatiblePSEditions = @('Desktop', 'Core')

    # ID used to uniquely identify this module
    GUID = 'b8e4f5d2-3a6c-4f7e-9d3e-2c7f8a9b5e4d'

    # Author of this module
    Author = 'Unity-Claude-Automation System'

    # Company or vendor of this module
    CompanyName = 'Unity-Claude-Automation'

    # Copyright statement for this module
    Copyright = '(c) 2025 Unity-Claude-Automation. All rights reserved.'

    # Description of the functionality provided by this module
    Description = 'Advanced trigger management with priority-based processing and exclusion patterns for file change automation'

    # Minimum version of the PowerShell engine required by this module
    PowerShellVersion = '5.1'

    # Functions to export from this module
    FunctionsToExport = @(
        'Initialize-TriggerManager',
        'Process-FileChange',
        'Register-TriggerHandler',
        'Unregister-TriggerHandler',
        'Get-TriggerStatus',
        'Get-ProcessingQueueStatus',
        'Clear-TriggerQueue',
        'Add-ExclusionPattern',
        'Remove-ExclusionPattern',
        'Get-ExclusionPatterns',
        'Test-FileExclusion'
    )

    # Cmdlets to export from this module
    CmdletsToExport = @()

    # Variables to export from this module
    VariablesToExport = @()

    # Aliases to export from this module
    AliasesToExport = @()

    # List of all files packaged with this module
    FileList = @(
        'Unity-Claude-TriggerManager.psd1',
        'Unity-Claude-TriggerManager.psm1'
    )

    # Private data to pass to the module specified in RootModule/ModuleToProcess
    PrivateData = @{
        PSData = @{
            # Tags applied to this module
            Tags = @('TriggerManagement', 'FileProcessing', 'PriorityQueue', 'Automation', 'Exclusions')

            # A URL to the license for this module.
            LicenseUri = ''

            # A URL to the main website for this project.
            ProjectUri = ''

            # A URL to an icon representing this module.
            IconUri = ''

            # ReleaseNotes of this module
            ReleaseNotes = 'Initial release with trigger conditions, priority processing, and exclusion patterns'
        }
    }

    # HelpInfo URI of this module
    HelpInfoURI = ''

    # Default prefix for commands exported from this module
    DefaultCommandPrefix = ''
}
# SIG # Begin signature block
# MIIFzgYJKoZIhvcNAQcCoIIFvzCCBbsCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCB6fVQcqTEd2ZeW
# pT2j7mqIoZFQ7KENRbW+dYzS27Z6xaCCAzAwggMsMIICFKADAgECAhB1HRbZIqgr
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
# MAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIK0OVwnGH9Pjs4dMGXh8meel
# E2u0J6L2TZWak0HZPZk1MA0GCSqGSIb3DQEBAQUABIIBAEbDzr2LLXFODEcfp079
# uibTPXpTQmlylQnIJNgmC2CI1O2POs2z39fBHABxqmowaPtHvgiVy/Xq0DW1pnNk
# 7naF2ghiHS02xX2009C+thtdps1tE8bGf27FV1vuwweuyiTV6gKGUEJNWchgZzC7
# H0I+JrFYe3zcwxReFypt8I3yk2hy8XzvWzFznSovDJ6gYev0iPZmV4PZ3x0sVOfv
# x8sy5X1V6TnPixpkATwJ9boO4ZFFF34hZrLdCKa4ZSyXkknM4F3BiQSOgR/JAd1/
# ifwr+YjfuXSvTf8WxtXm3/k/HXEs0O7kH9JLoObRuNhe7kmdmzvnQzOpGfjLNgx1
# wuc=
# SIG # End signature block
