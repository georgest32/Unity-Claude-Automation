#
# Module manifest for Unity-Claude-Learning-Simple
# JSON-based storage version without SQLite dependencies
#

@{
    # Script module or binary module file associated with this manifest
    RootModule = 'Unity-Claude-Learning-Simple.psm1'
    
    # Version number of this module
    ModuleVersion = '1.1.0'
    
    # Supported PSEditions
    # CompatiblePSEditions = @()
    
    # ID used to uniquely identify this module
    GUID = 'b8f4c3d2-9e1a-4f7b-8c2d-5a3b7e9f1d6c'
    
    # Author of this module
    Author = 'Unity-Claude Automation Team'
    
    # Company or vendor of this module
    CompanyName = 'Unity-Claude Automation'
    
    # Copyright statement for this module
    Copyright = '(c) 2025. All rights reserved.'
    
    # Description of the functionality provided by this module
    Description = 'Phase 3 Self-Improvement Learning Module with Fuzzy Matching - JSON Storage Version (No SQLite Dependencies)'
    
    # Minimum version of the PowerShell engine required by this module
    PowerShellVersion = '5.1'
    
    # Functions to export from this module
    FunctionsToExport = @(
        'Initialize-LearningStorage',
        'Add-ErrorPattern',
        'Get-SuggestedFixes',
        'Apply-AutoFix',
        'Get-LearningReport',
        'Export-LearningReport',
        'Set-LearningConfig',
        'Get-LearningConfig',
        'Update-FixSuccess',  # Export for testing and external usage
        # AST Parsing Functions
        'Get-CodeAST',
        'Find-CodePattern',
        'Get-ASTElements',
        'Test-CodeSyntax',
        'Get-UnityErrorPattern',
        # Fuzzy Matching Functions (Levenshtein Distance)
        'Get-LevenshteinDistance',
        'Get-StringSimilarity',
        'Test-FuzzyMatch',
        'Find-SimilarPatterns',
        'Clear-LevenshteinCache',
        'Get-LevenshteinCacheInfo'
    )
    
    # Cmdlets to export from this module
    CmdletsToExport = @()
    
    # Variables to export from this module
    VariablesToExport = '*'
    
    # Aliases to export from this module
    AliasesToExport = @()
    
    # Private data to pass to the module specified in RootModule/ModuleToProcess
    PrivateData = @{
        PSData = @{
            # Tags applied to this module
            Tags = @('Unity', 'Claude', 'Learning', 'AI', 'Automation', 'JSON', 'NoSQLite')
            
            # A URL to the license for this module
            # LicenseUri = ''
            
            # A URL to the main website for this project
            # ProjectUri = ''
            
            # ReleaseNotes of this module
            ReleaseNotes = 'JSON-based storage implementation without SQLite dependencies'
        }
    }
}
# SIG # Begin signature block
# MIIFqQYJKoZIhvcNAQcCoIIFmjCCBZYCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUWWv4CbWNt1WNwt3y1LEAaHqV
# pOagggMwMIIDLDCCAhSgAwIBAgIQdR0W2SKoK5VE8JId4ZxrRTANBgkqhkiG9w0B
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
# CQQxFgQUncdhD0XgXXmTOna/L64x7TaYI6swDQYJKoZIhvcNAQEBBQAEggEANTN+
# GFRPatyVOJZiO1MfBc2oorKbTVrEjOmOTB2je3MNmowOWqslWa/IBWDtIYAuOBSG
# a0SWIhArZDW7kmOkdwt2eXDmRTBjxZoU2dUZRv9unk22jpXsEhngu0FP4Uf5PPAk
# 0KT1TcD7zKU5SDAnbc2XxmOQ98HIdUEP0K2GPEAePlrOeDiyBKKp76G9Vq/5QKNJ
# PygqX1aTpFf9zRnTN1uvfzKU9ZviRm6kVjzjxNNElVTx/WhtrsM8SF+bTDwhp6o5
# WHcg6DfIxn1oFKV/cYoiFqKfizWDaRQYh4RHLqCFaiVhvmkNWX2xasjWiVxz8GCW
# AoF5YPvHiW46Uw32YA==
# SIG # End signature block
