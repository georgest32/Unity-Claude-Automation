@{
    # Module manifest for Unity-Claude-Errors
    ModuleVersion = '1.0.0'
    GUID = 'c9e6f0a4-1a5d-6f4d-0e3f-8a7b6c5d4e3f'
    Author = 'Unity Claude Automation'
    CompanyName = 'Sound and Shoal Project'
    Copyright = '(c) 2025. All rights reserved.'
    Description = 'Error handling and pattern recognition module for Unity-Claude automation'
    
    # Module components
    RootModule = 'Unity-Claude-Errors.psm1'
    
    # PowerShell requirements
    PowerShellVersion = '5.1'
    CompatiblePSEditions = @('Desktop', 'Core')
    
    # Functions to export
    FunctionsToExport = @(
        'Initialize-ErrorDatabase',
        'Add-ErrorPattern',
        'Get-ErrorPattern',
        'Find-SimilarErrors',
        'Update-ErrorSolution',
        'Get-ErrorStatistics',
        'Export-ErrorReport',
        'Parse-UnityError',
        'Get-ErrorSeverity'
    )
    
    # Dependencies - Removed to avoid circular dependency issues during integration
    RequiredModules = @()
    
    # Private data
    PrivateData = @{
        PSData = @{
            Tags = @('ErrorHandling', 'PatternRecognition', 'Database')
            ProjectUri = 'https://github.com/UnityProjects/Sound-and-Shoal'
            ReleaseNotes = 'Initial error handling module with pattern recognition'
        }
    }
}
# SIG # Begin signature block
# MIIFqQYJKoZIhvcNAQcCoIIFmjCCBZYCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQU9+Y29/u5j5Hy1/u44MKJ9or3
# 23qgggMwMIIDLDCCAhSgAwIBAgIQdR0W2SKoK5VE8JId4ZxrRTANBgkqhkiG9w0B
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
# CQQxFgQUwaFM4I5uy7GxjIHZSLicWB8V7wkwDQYJKoZIhvcNAQEBBQAEggEAiz6R
# cvDKl5cuDNccab2F0FGabPDaQNPTgqAa+DwepekDlA6jZAtNgBOI1vO6KYlZ1IhD
# Xch3N/rugjnI4HZm/BBCRM6Rl7YGTcmPfrDBWrWzrJ1Fj8gJhjm7VoelHpcmL8f8
# 2qmloAaxtkEXY1yyBqH0os2OfnGL4ZGWL529HFHHnPqBjcGgOiYrC8NvvtUdHT0N
# JgMs3LQiVUkCmjbIMlt0/RbMWVQmnn37ovsBCLZs+0fwcpaKx8CDUCHYaEoBYWIe
# AxfahiFDArBUNMjKhknpy+RRIKxo70p/hUAIO0w5IsgoUepWJQ+oI1YP9mswIjB1
# y/eEZIRCYeU3KAc8ZQ==
# SIG # End signature block
