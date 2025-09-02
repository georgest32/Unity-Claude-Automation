@{
    # Module Manifest for Unity-Claude-IncrementalProcessor

    # Script module or binary module file associated with this manifest
    RootModule = 'Unity-Claude-IncrementalProcessor.psm1'

    # Version number of this module
    ModuleVersion = '1.0.0'

    # ID used to uniquely identify this module
    GUID = 'f9a5e4b3-8d6c-5f98-c234-567890abcdef'

    # Author of this module
    Author = 'Unity Claude Automation System'

    # Company or vendor of this module
    CompanyName = 'Unity Claude Automation'

    # Copyright statement for this module
    Copyright = '(c) 2025 Unity Claude Automation. All rights reserved.'

    # Description of the functionality provided by this module
    Description = 'Incremental update engine for efficient CPG updates on file changes with diff-based AST comparison, partial graph reconstruction, and change propagation'

    # Minimum version of the PowerShell engine required by this module
    PowerShellVersion = '5.1'

    # Functions to export from this module
    FunctionsToExport = @(
        'New-IncrementalProcessor',
        'Start-IncrementalProcessing',
        'Stop-IncrementalProcessing',
        'Get-IncrementalProcessorStatistics',
        'New-ProcessorCheckpoint',
        'Restore-ProcessorCheckpoint',
        'Update-CPGIncremental',
        'Build-DependencyGraph'
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
            Tags = @('IncrementalProcessing', 'FileWatcher', 'CPG', 'AST', 'DiffCalculation', 'ChangePropagation')

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
- File system monitoring with FileSystemWatcher
- Incremental CPG updates on file changes
- Diff-based AST comparison
- Partial graph reconstruction
- Change propagation to dependent files
- Dependency graph building
- Checkpoint and restore functionality
- Batch processing of changes
- Statistics tracking
'@
        }
    }
}
# SIG # Begin signature block
# MIIFzgYJKoZIhvcNAQcCoIIFvzCCBbsCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCDu23qQ7jCRNpSM
# 3TFI13lXG1UwgREa2xReFgIY6AUnR6CCAzAwggMsMIICFKADAgECAhB1HRbZIqgr
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
# MAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIEU0l1tcrU+6hl5g52y9MzaM
# ADaF2PO/m8QKj3CMR6fPMA0GCSqGSIb3DQEBAQUABIIBABBJC3ccZMu7nl4z6Uq6
# UBMREXlAh7GD9MSMd71LQN/QKWCczoCvNsngPoMaQC9vvFkuclLyqLJGP5uAm+a0
# EGaY1XqNtudBzQAGp5ZKsmXl7BJmkQlP8z9GlVA2KJ3p5p0OWqdhjGNIQ5c79NPQ
# otM/3d6AJML+Y+KF/7OgtbAf8FKvlcdZ2SGgjFPgnz00aJND2h89Ui3i8egNt+6I
# VSZ/6OKAeHLGz/EbtfozirOt2EP60+Fgj44HfRXGD199n8UYmNmpVxOcWAYpBqaX
# 0NToBkIp5sYr4gCft6XTQT6m+xp7U3ncGXODgY3IAFsYpD+2kah8f2ekVu2LX9id
# 12E=
# SIG # End signature block
