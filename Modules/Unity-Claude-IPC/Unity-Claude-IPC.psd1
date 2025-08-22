@{
    # Module manifest for Unity-Claude-IPC
    ModuleVersion = '1.0.0'
    GUID = 'b8d5e9f3-0f4c-5e3b-9d2e-7f6a5b4c3d2e'
    Author = 'Unity Claude Automation'
    CompanyName = 'Sound and Shoal Project'
    Copyright = '(c) 2025. All rights reserved.'
    Description = 'Inter-Process Communication module for Unity-Claude automation - handles Claude CLI integration and bidirectional messaging'
    
    # Module components
    RootModule = 'Unity-Claude-IPC.psm1'
    
    # PowerShell requirements
    PowerShellVersion = '5.1'
    CompatiblePSEditions = @('Desktop', 'Core')
    
    # Functions to export
    FunctionsToExport = @(
        'Invoke-ClaudeAnalysis',
        'Start-BidirectionalPipe',
        'Send-ClaudePrompt',
        'Receive-ClaudeResponse',
        'Split-ConsoleLog',
        'Format-ErrorContext',
        'Get-PromptBoilerplate',
        'Test-ClaudeAvailable'
    )
    
    # Variables to export
    VariablesToExport = @()
    
    # Aliases to export  
    AliasesToExport = @()
    
    # Dependencies
    RequiredModules = @(
        @{ModuleName = 'Unity-Claude-Core'; ModuleVersion = '1.0.0'}
    )
    
    # Private data
    PrivateData = @{
        PSData = @{
            Tags = @('IPC', 'Claude', 'NamedPipes', 'Communication')
            LicenseUri = ''
            ProjectUri = 'https://github.com/UnityProjects/Sound-and-Shoal'
            ReleaseNotes = 'Initial IPC module for Claude integration'
        }
        
        # Module configuration
        ModuleConfig = @{
            DefaultModel = 'sonnet-3.5'
            ClaudeTimeout = 3600
            MaxPromptSize = 200000
            PipeName = 'Unity-Claude-Bridge'
        }
    }
}
# SIG # Begin signature block
# MIIFqQYJKoZIhvcNAQcCoIIFmjCCBZYCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUslfpr8Uw+hXYYXrvgrEisNi9
# pXCgggMwMIIDLDCCAhSgAwIBAgIQdR0W2SKoK5VE8JId4ZxrRTANBgkqhkiG9w0B
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
# CQQxFgQUs/2ICW2ETUYoiTIAjL3o4AlvEwgwDQYJKoZIhvcNAQEBBQAEggEAaFl5
# uUSAeCtdn9dCtAmCq2QIKSfbKdWtRNkkqhdmybVAQUhfBhr6mTXIEZupLs3/Ko1C
# 1AMqNuFzaVLEtm+uz/WW+pUQnqyeoQO2Q+JKkkOzuU5MZEEo20xoV4HdmenY5nyz
# 675tgKQEpE6obw65KfYvGrjSte469mictFg7XMadPhp7dYTV2RuTNE7rzjd4Edqo
# mE3WDg5AyOu609YSlqAWuquALu5k9QokekqyxkjjxsJYNs0ucsEnkz4uNMEF/QRA
# NlDzZYSk/WU0iSynaUVqKsBXjqnK55wGmIYhllY4R0/qmwpl82ZUupsPZBwF5tVG
# 47t48J8FEZ6Sv7vYLA==
# SIG # End signature block
