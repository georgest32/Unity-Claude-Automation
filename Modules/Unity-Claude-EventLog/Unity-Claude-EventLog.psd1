@{
    # Module manifest for Unity-Claude-EventLog
    ModuleVersion = '1.0.0'
    GUID = 'e7c8f9a2-3b4d-4e6f-9a1b-2c3d4e5f6789'
    Author = 'Unity-Claude Automation Team'
    CompanyName = 'Unity-Claude'
    Copyright = '(c) 2025 Unity-Claude. All rights reserved.'
    Description = 'Windows Event Log integration for Unity-Claude Automation System'
    PowerShellVersion = '5.1'
    
    # Module components
    RootModule = 'Unity-Claude-EventLog.psm1'
    
    # Functions to export
    FunctionsToExport = @(
        'Initialize-UCEventSource',
        'Write-UCEventLog',
        'Get-UCEventLog',
        'Test-UCEventSource',
        'Get-UCEventCorrelation',
        'Get-UCEventPatterns'
    )
    
    # Variables to export
    VariablesToExport = @()
    
    # Aliases to export
    AliasesToExport = @()
    
    # Cmdlets to export
    CmdletsToExport = @()
    
    # Private data
    PrivateData = @{
        PSData = @{
            Tags = @('EventLog', 'Unity', 'Claude', 'Automation', 'Logging')
            ProjectUri = 'https://github.com/unity-claude/automation'
            ReleaseNotes = 'Initial release with cross-version Event Log support'
        }
        
        # Event Log Configuration
        EventLogConfig = @{
            LogName = 'Unity-Claude-Automation'
            SourceName = 'Unity-Claude-Agent'
            MaximumKilobytes = 20480  # 20MB
            OverflowAction = 'OverwriteOlder'
            RetentionDays = 30
            
            # Event ID Ranges
            EventIdRanges = @{
                Information = @{ Start = 1000; End = 1999 }
                Warning = @{ Start = 2000; End = 2999 }
                Error = @{ Start = 3000; End = 3999 }
                Critical = @{ Start = 4000; End = 4999 }
                Performance = @{ Start = 5000; End = 5999 }
            }
            
            # Component Identifiers
            Components = @(
                'Unity',
                'Claude',
                'Agent',
                'Monitor',
                'IPC',
                'Dashboard'
            )
        }
    }
}