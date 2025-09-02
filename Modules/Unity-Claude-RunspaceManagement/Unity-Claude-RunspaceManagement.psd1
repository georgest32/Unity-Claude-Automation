# Unity-Claude-RunspaceManagement Module Manifest
# Phase 1 Week 2 Days 1-2: Session State Configuration
# Date: 2025-08-21

@{
    # REFACTORED: Now using modular architecture version
    RootModule = 'Unity-Claude-RunspaceManagement-Refactored.psm1'
    ModuleVersion = '2.0.0'
    GUID = '12345678-1234-1234-1234-123456789abc'
    Author = 'Unity-Claude-Automation'
    CompanyName = 'Unity-Claude-Automation'
    Copyright = '(c) 2025'
    Description = 'PowerShell 5.1 compatible runspace pool management with InitialSessionState configuration'
    
    PowerShellVersion = '5.1'
    
    # Required modules for dependency management - COMMENTED OUT to prevent nesting limit issues
    # RequiredModules = @(
    #     'Unity-Claude-ParallelProcessing'
    # )
    
    # Nested modules for enhanced functionality
    NestedModules = @()
    
    # Functions to export from this module
    FunctionsToExport = @(
        # Core functions
        'Write-ModuleLog',
        'Get-RunspacePoolRegistry',
        'Get-SharedVariablesDictionary',
        'Get-SessionStatesRegistry',
        
        # InitialSessionState Configuration (Hour 1-3)
        'New-RunspaceSessionState',
        'Set-SessionStateConfiguration',
        'Add-SessionStateModule',
        'Add-SessionStateVariable',
        'Test-SessionStateConfiguration',
        
        # Module/Variable Pre-loading (Hour 4-6)
        'Import-SessionStateModules',
        'Initialize-SessionStateVariables',
        'Get-SessionStateModules',
        'Get-SessionStateVariables',
        
        # SessionStateVariableEntry Sharing (Hour 7-8)
        'New-SessionStateVariableEntry',
        'Add-SharedVariable',
        'Get-SharedVariable',
        'Set-SharedVariable',
        'Remove-SharedVariable',
        'Test-SharedVariableAccess',
        'Get-AllSharedVariables',
        
        # Basic Runspace Pool Management (Days 1-2)
        'New-ManagedRunspacePool',
        'Open-RunspacePool',
        'Close-RunspacePool',
        'Get-RunspacePoolStatus',
        'Test-RunspacePoolHealth',
        'Get-AllRunspacePools',
        
        # Production Runspace Pool Infrastructure (Days 3-4 Hour 1-2)
        'New-ProductionRunspacePool',
        'Submit-RunspaceJob',
        'Update-RunspaceJobStatus',
        'Wait-RunspaceJobs',
        'Get-RunspaceJobResults',
        
        # Throttling and Resource Control (Days 3-4 Hour 5-6)
        'Test-RunspacePoolResources',
        'Set-AdaptiveThrottling',
        'Invoke-RunspacePoolCleanup',
        'Get-ResourceMonitoringStatus',
        
        # High-level orchestrator functions
        'Initialize-RunspaceManagement',
        'Get-RunspaceManagementStatus',
        'Stop-RunspaceManagement'
    )
    
    # Cmdlets to export from this module
    CmdletsToExport = @()
    
    # Variables to export from this module
    VariablesToExport = @()
    
    # Aliases to export from this module
    AliasesToExport = @()
    
    # Private data to pass to the module
    PrivateData = @{
        PSData = @{
            Tags = @('Unity', 'Claude', 'Automation', 'Runspace', 'Parallel', 'Threading')
            LicenseUri = ''
            ProjectUri = ''
            IconUri = ''
            ReleaseNotes = 'Phase 1 Week 2 Days 1-2: Session State Configuration implementation'
        }
    }
    
    # Minimum version of the PowerShell host required by this module
    PowerShellHostName = ''
    PowerShellHostVersion = ''
    
    # Minimum version of Microsoft .NET Framework required by this module
    DotNetFrameworkVersion = '4.5'
    
    # Minimum version of the common language runtime (CLR) required by this module
    CLRVersion = '4.0'
    
    # Script files (.ps1) that are run in the caller's environment prior to importing this module
    ScriptsToProcess = @()
    
    # Type files (.ps1xml) to be loaded when importing this module
    TypesToProcess = @()
    
    # Format files (.ps1xml) to be loaded when importing this module
    FormatsToProcess = @()
    
    # Assembly files (.dll) to be loaded when importing this module
    RequiredAssemblies = @()
}

# SIG # Begin signature block
# MIIFzgYJKoZIhvcNAQcCoIIFvzCCBbsCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCC19woccen88KYW
# W8Y+hzw1bvL72AdWcU0lKRQdtgsfeKCCAzAwggMsMIICFKADAgECAhB1HRbZIqgr
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
# MAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIGLxj5dMF8KO7a2c/ii/p9BN
# BBLBs5N56ARg7bBOkrALMA0GCSqGSIb3DQEBAQUABIIBAKU1Nq2Rfzq6f/gwF862
# Ma1q/ZJuFLQyG+7g5IzvpfWxN0Bf8wNtZpoFjl+iz/p4NdwNVxDVtsXIbDlI1i7V
# sK6AaXthQwktF381L5ShNmdtfE+qXM/BtjUM3ry0fq9FSYQEJeR5i2aWqhPstAgP
# 4ufPXQf4Xm1VTgjz7OVG1hBCGy4Z4qVMXbUmMKXDAW5ZRGado42YcaTZG0688v2e
# H5+AFo9/l3iTqvnQSgDJXp3/7YiDS0TfW/J5ZzcDa+lDv1WWzaAw49uBRL1Pq3mv
# 7ASQd6FyAO+ZKk58B+ljcUM7rT+BsXEnGNwir7iq6zZypmTfCWXSlbPMZ41p7itv
# qPg=
# SIG # End signature block
