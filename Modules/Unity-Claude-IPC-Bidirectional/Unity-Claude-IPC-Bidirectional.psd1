@{
    # Module manifest for Unity-Claude-IPC-Bidirectional
    
    # Script module or binary module file associated with this manifest
    RootModule = 'Unity-Claude-IPC-Bidirectional.psm1'
    
    # Version number of this module
    ModuleVersion = '2.0.0'
    
    # ID used to uniquely identify this module
    GUID = 'a7c4d8e3-9b2f-4e6a-8d5c-1f3e7a9b2c4d'
    
    # Author of this module
    Author = 'Unity-Claude Automation Team'
    
    # Company or vendor of this module
    CompanyName = 'Sound-and-Shoal Project'
    
    # Copyright statement for this module
    Copyright = '(c) 2025. All rights reserved.'
    
    # Description of the functionality provided by this module
    Description = 'Bidirectional communication module implementing named pipes, TCP/HTTP REST API, and WebSocket support for Unity-Claude automation'
    
    # Minimum version of the PowerShell engine required by this module
    PowerShellVersion = '5.1'
    
    # Modules that must be imported into the global environment prior to importing this module
    RequiredModules = @()
    
    # Functions to export from this module
    FunctionsToExport = @(
        # Named Pipes
        'Start-NamedPipeServer',
        'Send-PipeMessage',
        
        # HTTP API
        'Start-HttpApiServer',
        
        # Queue Management
        'Initialize-MessageQueues',
        'Add-MessageToQueue',
        'Get-NextMessage',
        'Get-QueueStatus',
        'Clear-MessageQueue',
        
        # Server Management
        'Start-BidirectionalServers',
        'Stop-BidirectionalServers'
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
            Tags = @('IPC', 'NamedPipes', 'REST', 'API', 'Unity', 'Claude', 'Automation', 'Bidirectional')
            
            # A URL to the main website for this project
            ProjectUri = 'https://github.com/Sound-and-Shoal/Unity-Claude-Automation'
            
            # ReleaseNotes of this module
            ReleaseNotes = @'
Version 2.0.0:
- Initial release of bidirectional communication module
- Named pipe server implementation with full duplex support
- HTTP REST API server using HttpListener
- Thread-safe queue management with ConcurrentQueue
- Async operation support for all servers
- Message routing and processing system
'@
        }
    }
}
# SIG # Begin signature block
# MIIFqQYJKoZIhvcNAQcCoIIFmjCCBZYCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQU07+VFfe7D/G1mnLxvw/uzBEq
# QiqgggMwMIIDLDCCAhSgAwIBAgIQdR0W2SKoK5VE8JId4ZxrRTANBgkqhkiG9w0B
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
# CQQxFgQUoWeY0ZJ+Ff53iJapT4ieEdBjVVAwDQYJKoZIhvcNAQEBBQAEggEAidgm
# dvRpa00Hrg3kWQU1kY5P1yRmp0Bs1DJIXJF9tR2QTJRgcvCxcV1U9Sd4EgXbKYyb
# r65QwdaCXhFsAn+dCahXaDnJkEA9wBYXyQd1v+Mrbm8rFZF26pl9nzpJT1LCoEuV
# NKzc2bSoFUkbYevo0H4JgDQSSPsHGqT5X+/IJ2eHpFsxEl/dhpHey9vvRWa6XMGM
# c/3Wb79TlBfsKTlRHrLxpuwOi10J7Jyu2lB3ai28epPa3ZnkecA0++DwzQ/saFgA
# 9wrZ/RGm9Ala+/N3G9oqvHu0LZHy87uUdzQBnXVlZ82bXjNld2etw3ZO2rRWFv0P
# 6O07fPAS8MENmBKmUA==
# SIG # End signature block
