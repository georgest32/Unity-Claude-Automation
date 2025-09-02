@{
    # Module manifest for Unity-Claude-FileMonitor

    # Script module or binary module file associated with this manifest.
    RootModule = 'Unity-Claude-FileMonitor.psm1'

    # Version number of this module.
    ModuleVersion = '1.0.0'

    # Supported PSEditions
    CompatiblePSEditions = @('Desktop', 'Core')

    # ID used to uniquely identify this module
    GUID = 'a7f3d8e2-9b4c-4a6e-8d2f-1c5e9f7a3b8d'

    # Author of this module
    Author = 'Unity-Claude-Automation System'

    # Company or vendor of this module
    CompanyName = 'Unity-Claude-Automation'

    # Copyright statement for this module
    Copyright = '(c) 2025 Unity-Claude-Automation. All rights reserved.'

    # Description of the functionality provided by this module
    Description = 'Real-time file monitoring with debouncing and change classification for documentation updates'

    # Minimum version of the PowerShell engine required by this module
    PowerShellVersion = '5.1'

    # Functions to export from this module
    FunctionsToExport = @(
        'New-FileMonitor',
        'Start-FileMonitor',
        'Stop-FileMonitor',
        'Register-FileChangeHandler',
        'Get-FileMonitorStatus',
        'Get-PendingChanges',
        'Clear-ChangeQueue',
        'Set-DebounceInterval',
        'Add-MonitorPath',
        'Remove-MonitorPath',
        'Get-MonitoredPaths',
        'Test-FileChangeClassification'
    )

    # Cmdlets to export from this module
    CmdletsToExport = @()

    # Variables to export from this module
    VariablesToExport = @()

    # Aliases to export from this module
    AliasesToExport = @()

    # List of all files packaged with this module
    FileList = @(
        'Unity-Claude-FileMonitor.psd1',
        'Unity-Claude-FileMonitor.psm1'
    )

    # Private data to pass to the module specified in RootModule/ModuleToProcess
    PrivateData = @{
        PSData = @{
            # Tags applied to this module
            Tags = @('FileSystemWatcher', 'Monitoring', 'Debouncing', 'Documentation', 'Automation')

            # A URL to the license for this module.
            LicenseUri = ''

            # A URL to the main website for this project.
            ProjectUri = ''

            # A URL to an icon representing this module.
            IconUri = ''

            # ReleaseNotes of this module
            ReleaseNotes = 'Initial release with FileSystemWatcher debouncing and change classification'
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
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCBFhfFOhWfbycRF
# BLtTzjRLr+tOgmHctVRPyH7ZbkHN/qCCAzAwggMsMIICFKADAgECAhB1HRbZIqgr
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
# MAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIBlP/j+TjAT7Mi9ruZkqG6qi
# ghsGM7KWahNIW9lo9oXQMA0GCSqGSIb3DQEBAQUABIIBAHfJGXG0nmpCISLiZ3GU
# u+GC0+LTMYwbJfp54shl4z53DYv6AZl6UpSY4E+/mcWqRSTaimMsrnlmh8Vb585h
# BX0jakQexY4uyAQ/exlbkH2yCsBjY2LC408DXh69mDhrVfpIFop+GqTx47CKQCum
# MHYiN5hMCBUaIxze7kzrJ8NctHgNl+PTTpF7vI1ZUTFSbpBf7VPU+6fZDaYBJRqC
# ejN334vniVALLps2g3dVC3zRWl5W4iFxfwzTjpPzQRlCl4b4fmRgk65kMTUJ9WRm
# 1tR+tPYXeJaUl3AyoGWNXf1W8kojXRZPH5n4/hDBK83slsbjrkme0CkSRWffJ132
# 188=
# SIG # End signature block
