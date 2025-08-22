#
# Module manifest for Unity-Claude-MasterOrchestrator
# Unified Module Integration Framework for Day 17 Complete Autonomous Feedback Loop
# Sequential orchestration with event-driven architecture and centralized command routing
#

@{
    # Script module or binary module file associated with this manifest
    RootModule = 'Unity-Claude-MasterOrchestrator.psm1'
    
    # Version number of this module
    ModuleVersion = '1.0.0'
    
    # Supported PSEditions
    CompatiblePSEditions = @('Desktop')
    
    # ID used to uniquely identify this module
    GUID = 'c9e4f7d3-6a8b-5e9c-2f3d-9b6a7c4e8f2d'
    
    # Author of this module
    Author = 'Unity-Claude Automation System'
    
    # Company or vendor of this module
    CompanyName = 'Unity-Claude Automation'
    
    # Copyright statement for this module
    Copyright = '(c) 2025 Unity-Claude Automation. All rights reserved.'
    
    # Description of the functionality provided by this module
    Description = 'Master Orchestrator for unified module integration with event-driven architecture, autonomous feedback loop management, and centralized command routing'
    
    # Minimum version of the Windows PowerShell engine required by this module
    PowerShellVersion = '5.1'
    
    # Minimum version of Microsoft .NET Framework required by this module
    DotNetFrameworkVersion = '4.5'
    
    # Modules that must be imported into the global environment prior to importing this module
    RequiredModules = @()
    
    # Functions to export from this module
    FunctionsToExport = @(
        # Core Integration Functions
        'Initialize-ModuleIntegration'
        'Initialize-SingleModule'
        'Get-ModuleIntegrationPoints'
        
        # Event-Driven Architecture
        'Start-EventDrivenProcessing'
        'Register-ResponseMonitorEvents'
        'Register-DecisionEngineEvents'
        'Add-EventToQueue'
        'Start-EventProcessingLoop'
        'Invoke-EventProcessing'
        
        # Specialized Event Processors
        'Invoke-ResponseEventProcessing'
        'Invoke-DecisionEventProcessing'
        'Invoke-ErrorEventProcessing'
        'Invoke-TestEventProcessing'
        'Invoke-SafetyEventProcessing'
        
        # Decision Execution System
        'Invoke-DecisionExecution'
        'Invoke-SafetyValidation'
        'Invoke-RecommendationExecution'
        'Invoke-TestExecution'
        'Invoke-CommandExecution'
        'Invoke-CommandValidation'
        'Invoke-ConversationContinuation'
        'Invoke-ResponseGeneration'
        'Invoke-ErrorAnalysis'
        'Invoke-WorkflowContinuation'
        'Invoke-ApprovalRequest'
        'Invoke-MonitoringContinuation'
        
        # Autonomous Feedback Loop Management
        'Start-AutonomousFeedbackLoop'
        'Stop-AutonomousFeedbackLoop'
        
        # Status and Management Functions
        'Get-OrchestratorStatus'
        'Test-OrchestratorIntegration'
        'Get-OperationHistory'
        'Clear-OrchestratorState'
        
        # Utility Functions
        'Test-ModuleAvailability'
    )
    
    # Cmdlets to export from this module
    CmdletsToExport = @()
    
    # Variables to export from this module
    VariablesToExport = @()
    
    # Aliases to export from this module
    AliasesToExport = @()
    
    # List of all files packaged with this module
    FileList = @(
        'Unity-Claude-MasterOrchestrator.psm1'
        'Unity-Claude-MasterOrchestrator.psd1'
    )
    
    # Private data to pass to the module specified in RootModule/ModuleToProcess
    PrivateData = @{
        PSData = @{
            # Tags applied to This module
            Tags = @('Unity', 'Claude', 'Orchestration', 'Integration', 'EventDriven', 'AutonomousFeedbackLoop', 'PowerShell')
            
            # ReleaseNotes of this module
            ReleaseNotes = @'
Version 1.0.0:
- Unified module integration framework with 18+ module support
- Event-driven architecture with priority-based queue processing
- Sequential orchestration pattern with dependency management
- Autonomous feedback loop with conversation round management
- Safety validation system with high-risk action protection
- Decision execution routing with specialized handlers
- Centralized logging with unity_claude_automation.log integration
- Research-validated 2025 integration patterns and best practices
- PowerShell 5.1 compatibility with .NET Framework 4.5 support
- Comprehensive status monitoring and operation history tracking
'@
        }
    }
}
# SIG # Begin signature block
# MIIFqQYJKoZIhvcNAQcCoIIFmjCCBZYCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUuFer0O4EOF7iC7JqCDPMl8bR
# FP6gggMwMIIDLDCCAhSgAwIBAgIQdR0W2SKoK5VE8JId4ZxrRTANBgkqhkiG9w0B
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
# CQQxFgQUl7HCkl/FW/atWEgvECviTzK4tIAwDQYJKoZIhvcNAQEBBQAEggEAaNWW
# RUDXdWejQsAGvWppmGlM31WZdnFLt5a6wwUmeirBuiV9UBSf0kEI2XfQ2lT+5bNW
# JxxPpbha3tB7TvQy/ku8Gz8KKvvlIRutnWGeqDwZAZUrSyPb9ktYI96oIMK731nP
# E4uxlwd0BdozIOxaiSduDogdVZXXjDb070xCXg3/YGzPGDc9l+Q+mNXTwj1poTFu
# HWjmQpS5PxcExvrQMrwvPX3nxO/PC9gRZruIlHY7bsr7OdaJTIn6TInu8jKDAj6B
# OEhJMda2m64Iv+w+4nxBAo6gOoSkrv6SxJr5pCgQpLsoGkc0BYkqg4oh9qEDQBFF
# BOT4U8wcjYhcLIXYMw==
# SIG # End signature block
