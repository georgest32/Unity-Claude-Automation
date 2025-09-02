#
# Module manifest for Unity-Claude-MasterOrchestrator
# Unified Module Integration Framework for Day 17 Complete Autonomous Feedback Loop
# Sequential orchestration with event-driven architecture and centralized command routing
#

@{
    # Script module or binary module file associated with this manifest
    RootModule = 'Unity-Claude-MasterOrchestrator-Refactored.psm1'
    
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
        'Unity-Claude-MasterOrchestrator-Refactored.psm1',
        'Unity-Claude-MasterOrchestrator.psm1',
        'Unity-Claude-MasterOrchestrator.psd1',
        'Core\OrchestratorCore.psm1',
        'Core\ModuleIntegration.psm1', 
        'Core\EventProcessing.psm1',
        'Core\DecisionExecution.psm1',
        'Core\AutonomousFeedbackLoop.psm1',
        'Core\OrchestratorManagement.psm1'
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
# MIIFzgYJKoZIhvcNAQcCoIIFvzCCBbsCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCDgFCC4+ayK31R7
# WhCFeJbP8aAV/rgyI6yUfWEtXa9QDKCCAzAwggMsMIICFKADAgECAhB1HRbZIqgr
# lUTwkh3hnGtFMA0GCSqGSIb3DQEBCwUAMC4xLDAqBgNVBAMMI1VuaXR5LUNsYXVk
# ZS1BdXRvbWF0aW9uLURldmVsb3BtZW50MB4XDTI1MDgyMDIxMTUxN1oXDTI2MDgy
# MDIxMzUxN1owLjEsMCoGA1UEAwwjVW5pdHktQ2xhdWRlLUF1dG9tYXRpb24tRGV2
# ZWxvcG1lbnQwggEiMA0GCSqGSIb3DQEBAQUAA4IBDwAwggEKAoIBAQCx4feqKdUQ
# 6GufY4umNzlM1Pi8aHUGR8HlfhIWFjsrRAxCxhieRlWbHe0Hw+pVBeX76X57e5Pu
# 4Kxxzu+MxMry0NJYf3yOLRTfhYskHBcLraXUCtrMwqnhPKvul6Sx6Lu8vilk605W
# ADJNifl3WFuexVCYJJM9G2mfuYIDN+rZ5zmpn0qCXum49bm629h+HyJ205Zrn9aB
# hIrA4i/JlrAh1kosWnCo62psl7ixbNVqFqwWEt+gAqSeIo4ChwkOQl7GHmk78Q5I
# oRneY4JTVlKzhdZEYhJGFXeoZml/5jcmUcox4UNYrKdokE7z8ZTmyowBOUNS+sHI
# G1TY5DZSb8vdAgMBAAGjRjBEMA4GA1UdDwEB/wQEAwIHgDATBgNVHSUEDDAKBggr
# BgEFBQcDAzAdBgNVHQ4EFgQUfDms7LrGVboHjmwlSyIjYD/JLQwwDQYJKoZIhvcN
# AQELBQADggEBABRMsfT7DzKy+aFi4HDg0MpxmbjQxOH1lzUzanaECRiyA0sn7+sA
# /4jvis1+qC5NjDGkLKOTCuDzIXnBWLCCBugukXbIO7g392ANqKdHjBHw1WlLvMVk
# 4WSmY096lzpvDd3jJApr/Alcp4KmRGNLnQ3vv+F9Uj58Uo1qjs85vt6fl9xe5lo3
# rFahNHL4ngjgyF8emNm7FItJeNtVe08PhFn0caOX0FTzXrZxGGO6Ov8tzf91j/qK
# QdBifG7Fx3FF7DifNqoBBo55a7q0anz30k8p+V0zllrLkgGXfOzXmA1L37Qmt3QB
# FCdJVigjQMuHcrJsWd8rg857Og0un91tfZIxggH0MIIB8AIBATBCMC4xLDAqBgNV
# BAMMI1VuaXR5LUNsYXVkZS1BdXRvbWF0aW9uLURldmVsb3BtZW50AhB1HRbZIqgr
# lUTwkh3hnGtFMA0GCWCGSAFlAwQCAQUAoIGEMBgGCisGAQQBgjcCAQwxCjAIoAKA
# AKECgAAwGQYJKoZIhvcNAQkDMQwGCisGAQQBgjcCAQQwHAYKKwYBBAGCNwIBCzEO
# MAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIPkHQ5f3F7w4FmjZVqisdpsh
# 9XOjy05bMrMhUIHnEliXMA0GCSqGSIb3DQEBAQUABIIBAFB1etHto+YxNZjogaiz
# u3+OjKulXPXqbufH+TGPzpfhYKV7DA+sjFRcl63sys9jr5f3VKJfXaii4cUBrYH8
# L1wpepVEQGMJPDf/PandV9J7qvzFvQ4CUhDoeh67BWaHHfAPYvN40pTsHrI5i46F
# PyIQtzkbsIwLTyCXGnoIydgZ5R6Cb0rn3rz/XuAisYORGIhyrGIJbahDa+dVxuV2
# BpTKkeN3dWnTNmmyqmKimmHr32A+AUT561ev/RlPG8KY8skm5DuHK3+Q34YLSJ3r
# TV7B+9Lf9jOvuGu1a6jjdh4TIuS2XkdwxysujknFrWWNkDZqVaLNqwx22xQj49L1
# FkM=
# SIG # End signature block
