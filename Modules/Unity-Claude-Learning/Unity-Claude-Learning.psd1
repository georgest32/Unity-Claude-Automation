@{
    # Module manifest for Unity-Claude-Learning
    ModuleVersion = '1.0.0'
    GUID = 'a7c4f8d9-3e2b-4f1a-9c8d-5b6e7a9f2c3d'
    Author = 'Unity-Claude Automation'
    CompanyName = 'Unity-Claude'
    Copyright = '(c) 2025 Unity-Claude. All rights reserved.'
    Description = 'Self-improvement and pattern recognition module for Unity-Claude Automation - Phase 3'
    PowerShellVersion = '5.1'
    
    # Module components
    RootModule = 'Unity-Claude-Learning.psm1'
    
    # Functions to export
    FunctionsToExport = @(
        'Initialize-LearningDatabase',
        'Get-CodeAST',
        'Find-CodePattern',
        'Add-ErrorPattern',
        'Get-SuggestedFixes',
        'Apply-AutoFix',
        'Update-PatternSuccess',
        'Get-LearningReport',
        'Set-LearningConfig',
        'Get-LearningConfig'
    )
    
    # Required modules
    RequiredModules = @()
    
    # Required assemblies for SQLite - Made optional for compatibility
    # RequiredAssemblies = @(
    #     'System.Data.SQLite.dll'
    # )
    
    # Private data
    PrivateData = @{
        PSData = @{
            Tags = @('Unity', 'Claude', 'Automation', 'Learning', 'AI', 'Pattern-Recognition')
            ProjectUri = 'https://github.com/unity-claude/automation'
            ReleaseNotes = 'Phase 3 implementation - Self-improvement mechanism with pattern recognition'
        }
    }
}
# SIG # Begin signature block
# MIIFqQYJKoZIhvcNAQcCoIIFmjCCBZYCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUZ9sb8V/EJ80UKEHPSXJg1t74
# fSSgggMwMIIDLDCCAhSgAwIBAgIQdR0W2SKoK5VE8JId4ZxrRTANBgkqhkiG9w0B
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
# CQQxFgQUU796QSFBwKDawW7qlvP1oY93EcQwDQYJKoZIhvcNAQEBBQAEggEAq9Qb
# 79EUBeafIo6rPAmxp+TgHcUNuOgaTi7vM3L2pGNZGwORethtyO5xHGasqW/P6FFA
# pjH1ZPXrsc2Gm7hEmGJDxR7U43JHUe646ECCEE16SOWAGHGq9nsnQekxJyqzAThN
# WbvdvHH9mswaqoT4ku5fp5T6v/sBAmQtluPAph208yW5zo5vqb0Y4TaLTOW7N5kj
# rSUwFPyVNLQPQzaJDTC56B8V1E56IR6iAMhRcvru7QCISafwcVSzOyg574dAGOP0
# EBtFrMBrAmKTeThXC6scar0exD8L7LUsqUcO+XTEZzs18vmrfmFbl4uuKHXe6bvi
# J7YMwkCJdRhGulfFTw==
# SIG # End signature block
