#
# Module manifest for Unity-Claude-FixEngine
# Fix Application Engine for automated Unity error resolution
# Day 17-18 Implementation - Phase 3 Week 3
#

@{
    # Script module or binary module file associated with this manifest
    RootModule = 'Unity-Claude-FixEngine.psm1'
    
    # Version number of this module
    ModuleVersion = '1.0.0'
    
    # Supported PSEditions
    CompatiblePSEditions = @('Desktop')
    
    # ID used to uniquely identify this module
    GUID = 'f8a2c1d5-9b3e-4a7c-8f1d-2e6b7c9a4d8f'
    
    # Author of this module
    Author = 'Unity-Claude Automation System'
    
    # Company or vendor of this module
    CompanyName = 'Unity-Claude Automation'
    
    # Copyright statement for this module
    Copyright = '(c) 2025 Unity-Claude Automation. All rights reserved.'
    
    # Description of the functionality provided by this module
    Description = 'Automated fix application engine for Unity compilation errors with AST-based code generation and safety integration'
    
    # Minimum version of the Windows PowerShell engine required by this module
    PowerShellVersion = '5.1'
    
    # Name of the Windows PowerShell host required by this module
    # PowerShellHostName = ''
    
    # Minimum version of the Windows PowerShell host required by this module
    # PowerShellHostVersion = ''
    
    # Minimum version of Microsoft .NET Framework required by this module
    DotNetFrameworkVersion = '4.5'
    
    # Minimum version of the common language runtime (CLR) required by this module
    # CLRVersion = ''
    
    # Processor architecture (None, X86, Amd64) required by this module
    # ProcessorArchitecture = ''
    
    # Modules that must be imported into the global environment prior to importing this module
    RequiredModules = @()
    
    # Assemblies that must be loaded prior to importing this module
    # RequiredAssemblies = @()
    
    # Script files (.ps1) that are run in the caller's environment prior to importing this module
    # ScriptsToProcess = @()
    
    # Type files (.ps1xml) to be loaded when importing this module
    # TypesToProcess = @()
    
    # Format files (.ps1xml) to be loaded when importing this module
    # FormatsToProcess = @()
    
    # Modules to import as nested modules of the module specified in RootModule/ModuleToProcess
    # NestedModules = @()
    
    # Functions to export from this module
    FunctionsToExport = @(
        # Core Fix Application Functions
        'Invoke-FixApplication'
        'New-CodeFix'
        'Test-FixValidation'
        'Invoke-CompilationVerification'
        
        # Code Modification Functions
        'Invoke-AtomicFileReplace'
        'New-BackupFile'
        'Restore-BackupFile'
        
        # AST and Pattern Functions
        'Get-CSharpAST'
        'Get-CodePattern'
        'New-FixTemplate'
        'Invoke-TemplateApplication'
        
        # Integration Functions
        'Connect-SafetyFramework'
        'Connect-LearningModule'
        'Send-FixMetrics'
        
        # Verification Functions
        'Test-UnityCompilation'
        'Get-CompilationErrors'
        'Test-FixSuccess'
        
        # Configuration Functions
        'Get-FixEngineConfig'
        'Set-FixEngineConfig'
    )
    
    # Cmdlets to export from this module
    CmdletsToExport = @()
    
    # Variables to export from this module
    VariablesToExport = @()
    
    # Aliases to export from this module
    AliasesToExport = @()
    
    # DSC resources to export from this module
    # DscResourcesToExport = @()
    
    # List of all modules packaged with this module
    # ModuleList = @()
    
    # List of all files packaged with this module
    FileList = @(
        'Unity-Claude-FixEngine.psm1'
        'Unity-Claude-FixEngine.psd1'
    )
    
    # Private data to pass to the module specified in RootModule/ModuleToProcess
    PrivateData = @{
        PSData = @{
            # Tags applied to this module
            Tags = @('Unity', 'Automation', 'CodeGeneration', 'ErrorFix', 'AST', 'PowerShell')
            
            # A URL to the license for this module
            # LicenseUri = ''
            
            # A URL to the main website for this project
            # ProjectUri = ''
            
            # A URL to an icon representing this module
            # IconUri = ''
            
            # ReleaseNotes of this module
            ReleaseNotes = @'
Version 1.0.0:
- Initial implementation of Fix Application Engine
- AST-based code generation with C# 7.3 compatibility
- Integration with Unity-Claude-Safety framework
- Atomic file operations with backup and rollback
- Template-based fix generation
- Unity compilation verification
- Learning module integration for metrics tracking
'@
        }
    }
    
    # HelpInfo URI of this module
    # HelpInfoURI = ''
    
    # Default prefix for commands exported from this module
    # DefaultCommandPrefix = ''
}
# SIG # Begin signature block
# MIIFqQYJKoZIhvcNAQcCoIIFmjCCBZYCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUu6wxtzHEyZuAk7+q5wf9mJwT
# r7OgggMwMIIDLDCCAhSgAwIBAgIQdR0W2SKoK5VE8JId4ZxrRTANBgkqhkiG9w0B
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
# CQQxFgQUE1e4FLSVPWfqqwCZDAF4JXzVdoEwDQYJKoZIhvcNAQEBBQAEggEAnJjD
# kIz97XvYFeXLiQIKq5s2P071yGxzZ1RxFX7r3j5+YH33WKOkCgmv82vkxTn8sq14
# vAWevf5z2PDP26fWPpL7FURF+GXkaBze5EftWBt+/d+AiVtY46uRh1UBFP61t6Jz
# gbWgc5xV7Lj+pJt87zgLS8apA2E8zkDDHeGUwQcDOJiklie5AJjRm7ShAAUbjUpX
# 5hoNsZmv6GoosDdDqHHoVGB+RAcIZ/UTthKLRFT53sdH78pwrrKrWZ1qamnO4pRZ
# UXH9GoYIQi1qXvjW5YhOYt4N8pQKZWqiYcEaveIPI47VlegvUZ0bYrbBfe/+EvWY
# RKQfisi7KwOB0Wlaag==
# SIG # End signature block
