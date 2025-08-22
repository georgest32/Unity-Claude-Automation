# Module manifest for Unity-Claude-Safety module

@{
    # Script module or binary module file associated with this manifest
    RootModule = 'Unity-Claude-Safety.psm1'
    
    # Version number of this module
    ModuleVersion = '1.0.0'
    
    # ID used to uniquely identify this module
    GUID = 'c8f9a2d1-7b3e-4a89-b2c1-9d8e7f6a5b4c'
    
    # Author of this module
    Author = 'Unity-Claude Automation System'
    
    # Company or vendor of this module
    CompanyName = 'Sound and Shoal'
    
    # Copyright statement for this module
    Copyright = '(c) 2025. All rights reserved.'
    
    # Description of the functionality provided by this module
    Description = 'Safety framework for Unity-Claude automated fix application with confidence thresholds, dry-run capabilities, and critical file protection'
    
    # Minimum version of the Windows PowerShell engine required by this module
    PowerShellVersion = '5.1'
    
    # Functions to export from this module
    FunctionsToExport = @(
        'Initialize-SafetyFramework',
        'Test-FixSafety',
        'Invoke-SafetyBackup',
        'Invoke-DryRun',
        'Set-SafetyConfiguration',
        'Get-SafetyConfiguration',
        'Test-CriticalFile',
        'Add-SafetyLog',
        'Invoke-SafeFixApplication'
    )
    
    # Cmdlets to export from this module
    CmdletsToExport = @()
    
    # Variables to export from this module
    VariablesToExport = @()
    
    # Aliases to export from this module
    AliasesToExport = @()
    
    # Private data to pass to the module specified in RootModule/ModuleToProcess
    PrivateData = @{
        PSData = @{
            # Tags applied to this module
            Tags = @('Unity', 'Automation', 'Safety', 'ErrorHandling', 'Backup')
            
            # A URL to the license for this module
            LicenseUri = ''
            
            # A URL to the main website for this project
            ProjectUri = ''
            
            # ReleaseNotes of this module
            ReleaseNotes = 'Initial release of Unity-Claude Safety Framework module'
        }
    }
}
# SIG # Begin signature block
# MIIFqQYJKoZIhvcNAQcCoIIFmjCCBZYCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQU60XjDt+esUP1KDGfjCbmAIJ0
# EJKgggMwMIIDLDCCAhSgAwIBAgIQdR0W2SKoK5VE8JId4ZxrRTANBgkqhkiG9w0B
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
# CQQxFgQUpO7n7VVkenOKwSN7Y0REbuObF7swDQYJKoZIhvcNAQEBBQAEggEAMl6T
# hgZ7nTxCKO/4Fk2Ac5sJZzbwaPy6f5cFEaZE58YQ4iIbJoFJhLA9nqTH8XBzFt5N
# kh4T9XkQDEVG0OV8mlFzUAckkrUvvQWUwqyWGfR5XnytH6Cdxr7+a45KB6SlWKB+
# rIQDH4TZXmkXynnXVvle5UUExBalS2iRiFVTWQ3MCUQxhbu3FTH7cZJ3wCitnj+z
# AdNjBdx2FNObIi4qvE0UhWqU4m0vAL5CcGnNVMoYa+eNB22b1VVoecV6mSIRGrxR
# h3de3Oz+mMQ3eMdZukzV/o6fkkruAt2PxU3POPNp6+egkgNZL4ZE26kYZONbuwKl
# DmxAEVXr18mAi/beJA==
# SIG # End signature block
