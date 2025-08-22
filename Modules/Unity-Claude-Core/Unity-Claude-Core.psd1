@{
    # Module manifest for Unity-Claude-Core
    ModuleVersion = '1.0.0'
    GUID = 'a7c4d8f2-9e3b-4f2a-8c1d-6e5f4a3b2c1d'
    Author = 'Unity Claude Automation'
    CompanyName = 'Sound and Shoal Project'
    Copyright = '(c) 2025. All rights reserved.'
    Description = 'Core module for Unity-Claude automation system - orchestrates Unity compilation testing and error resolution'
    
    # Module components
    RootModule = 'Unity-Claude-Core.psm1'
    
    # PowerShell requirements
    PowerShellVersion = '5.1'
    CompatiblePSEditions = @('Desktop', 'Core')
    
    # Functions to export
    FunctionsToExport = @(
        'Start-UnityAutomation',
        'Test-UnityCompilation',
        'Export-UnityConsole',
        'Install-AutoRecompileScript',
        'Write-Log',
        'Get-FileTailAsString',
        'Test-EditorSuccess',
        'Get-CurrentPromptType',
        'Initialize-AutomationContext'
    )
    
    # Variables to export
    VariablesToExport = @()
    
    # Aliases to export  
    AliasesToExport = @()
    
    # Dependencies
    RequiredModules = @()
    
    # Private data
    PrivateData = @{
        PSData = @{
            Tags = @('Unity', 'Automation', 'Claude', 'CI/CD', 'PowerShell')
            LicenseUri = ''
            ProjectUri = 'https://github.com/UnityProjects/Sound-and-Shoal'
            ReleaseNotes = 'Initial modular release of Unity-Claude automation system'
            Prerelease = ''
            RequireLicenseAcceptance = $false
        }
        
        # Module configuration
        ModuleConfig = @{
            LogDirectory = 'AutomationLogs'
            DefaultTimeout = 300
            MaxRetries = 5
        }
    }
}
# SIG # Begin signature block
# MIIFqQYJKoZIhvcNAQcCoIIFmjCCBZYCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUT1Y80NIT6qUQ3V83yr3JjLEG
# nrygggMwMIIDLDCCAhSgAwIBAgIQdR0W2SKoK5VE8JId4ZxrRTANBgkqhkiG9w0B
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
# CQQxFgQU+yg803KjdtT2SFYbqOH/Li7XEcUwDQYJKoZIhvcNAQEBBQAEggEAYzqZ
# xtIoVVRqZENKsEbaWTqQeMOsNI20WxHem5VRGPKr9yTdjujkaaWCMILPf9agSx25
# z2LvVy+WbFsmZCVqbyDBPWdTlX8pkgJI2thR8Fi137rerTb6QoHb91pFG9q9z2rd
# JOuO0aA6oqs0HvTsHKU/6kMa08sI3IBTNgEgvnvanUbb3/KA9Obay+q3FBPPVEdu
# bO9zxD643YrrJM0ZmL6K4wEIMctTn22zHIK/ag4+lcDwAUpfij+RVb/ERASBUJmI
# Y+TMW+hsk1N7hLL+tTYgghLy5SRHkihD0o7YKitBeJMdHQYv910TsUQ964G0n+bN
# M1xnx1eewiaTqtr1Yw==
# SIG # End signature block
