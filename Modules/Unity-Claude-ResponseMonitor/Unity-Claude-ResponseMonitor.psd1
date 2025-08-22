#
# Module manifest for Unity-Claude-ResponseMonitor
# Claude Code CLI Output Monitoring System for Day 17 Integration
# Real-time response detection with FileSystemWatcher and autonomous conversation management
#

@{
    # Script module or binary module file associated with this manifest
    RootModule = 'Unity-Claude-ResponseMonitor.psm1'
    
    # Version number of this module
    ModuleVersion = '1.0.0'
    
    # Supported PSEditions
    CompatiblePSEditions = @('Desktop')
    
    # ID used to uniquely identify this module
    GUID = 'a7e9c2f4-1b8d-4c5e-9a3f-6d2b8e1c4a7f'
    
    # Author of this module
    Author = 'Unity-Claude Automation System'
    
    # Company or vendor of this module
    CompanyName = 'Unity-Claude Automation'
    
    # Copyright statement for this module
    Copyright = '(c) 2025 Unity-Claude Automation. All rights reserved.'
    
    # Description of the functionality provided by this module
    Description = 'Real-time Claude Code CLI output monitoring system with FileSystemWatcher, autonomous response handling, and conversation management integration'
    
    # Minimum version of the Windows PowerShell engine required by this module
    PowerShellVersion = '5.1'
    
    # Minimum version of Microsoft .NET Framework required by this module
    DotNetFrameworkVersion = '4.5'
    
    # Modules that must be imported into the global environment prior to importing this module
    RequiredModules = @()
    
    # Functions to export from this module
    FunctionsToExport = @(
        # Core Monitoring Functions
        'Start-ClaudeResponseMonitoring'
        'Stop-ClaudeResponseMonitoring'
        'Get-MonitoringStatus'
        'Test-ResponseMonitorIntegration'
        
        # Configuration Functions
        'Get-ResponseMonitorConfig'
        'Set-ResponseMonitorConfig'
        
        # FileSystemWatcher Management
        'Initialize-FileSystemWatcher'
        'Stop-FileSystemWatcher'
        
        # Response Processing Functions
        'Invoke-ResponseProcessing'
        'Invoke-AutonomousResponseHandling'
        'Get-ActionableItems'
        
        # Action Handlers
        'Invoke-RecommendationHandler'
        'Invoke-TestHandler'
        'Invoke-ContinuationHandler'
        'Invoke-ExecutionHandler'
        
        # Queue Management Functions
        'Add-PendingRecommendation'
        'Add-PendingTest'
        'Add-PendingContinuation'
        'Add-PendingExecution'
        'Get-ResponseQueue'
        'Clear-ResponseQueue'
        
        # Utility Functions
        'Invoke-DebouncedResponseHandler'
    )
    
    # Cmdlets to export from this module
    CmdletsToExport = @()
    
    # Variables to export from this module
    VariablesToExport = @()
    
    # Aliases to export from this module
    AliasesToExport = @()
    
    # List of all files packaged with this module
    FileList = @(
        'Unity-Claude-ResponseMonitor.psm1'
        'Unity-Claude-ResponseMonitor.psd1'
    )
    
    # Private data to pass to the module specified in RootModule/ModuleToProcess
    PrivateData = @{
        PSData = @{
            # Tags applied to this module
            Tags = @('Unity', 'Claude', 'Automation', 'FileSystemWatcher', 'ResponseMonitoring', 'PowerShell')
            
            # ReleaseNotes of this module
            ReleaseNotes = @'
Version 1.0.0:
- Real-time Claude Code CLI output monitoring with FileSystemWatcher
- Research-validated debouncing with 500ms delay for event handling
- Autonomous response processing with actionable item extraction
- Integration with ConversationStateManager for state transitions
- Queue-based response handling with proper resource management
- Support for RECOMMENDED, TEST, CONTINUE, and EXECUTE action types
- Comprehensive logging with unity_claude_automation.log integration
- PowerShell 5.1 compatibility with .NET Framework 4.5 support
'@
        }
    }
}
# SIG # Begin signature block
# MIIFqQYJKoZIhvcNAQcCoIIFmjCCBZYCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUIL5tuRkTJhpnS8GPG5otEHXM
# hFWgggMwMIIDLDCCAhSgAwIBAgIQdR0W2SKoK5VE8JId4ZxrRTANBgkqhkiG9w0B
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
# CQQxFgQUUi/Ujwzqtrpug8XuncsdaM6hiBowDQYJKoZIhvcNAQEBBQAEggEAPaKZ
# Itw/XWQsFO3TtHNssYEhfpqAZW1Qfz9sNCjyQE8hJr7POKQkINb6Egwe5/CjlxkQ
# iJfz2RIvEW03wFXiYtuoQ9KXMMxExhOQopK0GGYaKMyIzeZa1KxXPjDjsqRVJcW+
# V+o+kecQ/4w05KV/tRPOuftdvs7GZIPn+jcWVa87PKryx1OWlQ8aBmLECWws/8uW
# 3brK8pCmbh0J5asZ6t8cq23rrG97EVkwA2cVqhVPLpb1AKImxD7oq2hGDIAWM0kC
# vEpSSK6gZfDcHgtsQ5Ks3Wlks/RxY0c9Hpwe3aqb9CObIGdrIRj0+PMumAFpVNDq
# YPCF0z+/h2mtjHvEcw==
# SIG # End signature block
