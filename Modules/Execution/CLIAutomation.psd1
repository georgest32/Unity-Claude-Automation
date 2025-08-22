# CLIAutomation.psd1
# Module manifest for CLI Input Automation module
# Day 13 Implementation - 2025-08-18

@{
    # Module Information
    ModuleVersion = '1.0.0'
    GUID = '7f3c9e2d-8a4b-4d5e-9f6a-1b2c3d4e5f6g'
    Author = 'Unity-Claude Automation System'
    CompanyName = 'Unity-Claude'
    Copyright = '(c) 2025 Unity-Claude. All rights reserved.'
    Description = 'CLI Input Automation module for Claude Code CLI interaction using SendKeys and file-based messaging'
    
    # Module Requirements
    PowerShellVersion = '5.1'
    CLRVersion = '4.0'
    ProcessorArchitecture = 'None'
    
    # Module Components
    RootModule = 'CLIAutomation.psm1'
    
    # Exported Functions
    FunctionsToExport = @(
        # SendKeys Functions
        'Submit-ClaudeCLIInput',
        'Get-ClaudeWindow',
        'Set-WindowFocus',
        'Send-KeysToWindow',
        
        # File-Based Functions
        'Submit-ClaudeFileInput',
        'Write-ClaudeMessageFile',
        
        # Queue Management
        'Add-InputToQueue',
        'Process-InputQueue',
        'Get-InputQueueStatus',
        
        # Utilities
        'Format-ClaudePrompt',
        'Test-InputDelivery',
        'Submit-ClaudeInputWithFallback'
    )
    
    # Type and Format Files
    TypesToProcess = @()
    FormatsToProcess = @()
    
    # Nested Modules
    NestedModules = @()
    
    # Private Data
    PrivateData = @{
        PSData = @{
            Tags = @('CLI', 'Automation', 'Claude', 'SendKeys', 'IPC')
            ProjectUri = ''
            ReleaseNotes = 'Day 13: CLI Input Automation implementation with SendKeys and file-based approaches'
        }
    }
}
# SIG # Begin signature block
# MIIFqQYJKoZIhvcNAQcCoIIFmjCCBZYCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQURNWaPFH2seOVP4DXf40xPHEv
# i5CgggMwMIIDLDCCAhSgAwIBAgIQdR0W2SKoK5VE8JId4ZxrRTANBgkqhkiG9w0B
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
# CQQxFgQUAAbns8c6zrRG3hzVieAFyTTeAPgwDQYJKoZIhvcNAQEBBQAEggEAK/Xq
# FfDjK3ZpqcPGXpFUE1X/f6oGZiWUvi9npwHK3rnOeQT2O2fpKfNrWauh9NTn3Mq3
# UpE+IQIy5vI2hP9Gi3BHtrM7CRO2XX9H5OxA2PtIhnp9ciU0h5sYvGhYwsAKsxj5
# TyPgxN0ETqkMBANMxZQGFvDZB22obEAPIqT1iScQ9yDYOHB+6TwnKxvrq/kq/Gln
# UikcNEA2G1cuv9MgJx2Jyc3V60lfd9avW66sYHf+BXQwdIV/JcRNI6QAVS5jsZeH
# nW6BfRbCcnT3cc3N7DPaooUY3Zq3YEiruMuPiXewlbdzxRV4/bxdpif8zeaNh0Mj
# LxUNGOqmIGuagUrXww==
# SIG # End signature block
