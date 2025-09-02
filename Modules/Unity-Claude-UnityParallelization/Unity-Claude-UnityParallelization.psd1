# Unity-Claude-UnityParallelization Module Manifest
# Phase 1 Week 3 Days 1-2: Unity Compilation Parallelization
# Date: 2025-08-21

@{
    RootModule = 'Unity-Claude-UnityParallelization-Refactored.psm1'
    ModuleVersion = '2.0.0'
    GUID = '87654321-4321-4321-4321-210987654321'
    Author = 'Unity-Claude-Automation'
    CompanyName = 'Unity-Claude-Automation'
    Copyright = '(c) 2025'
    Description = 'Unity compilation parallelization with concurrent error detection and export'
    
    PowerShellVersion = '5.1'
    
    # Required modules for dependency management - COMMENTED OUT to prevent nesting limit issues
    # RequiredModules = @(
    #     'Unity-Claude-RunspaceManagement'
    #     # Note: ParallelProcessing included transitively through RunspaceManagement
    # )
    
    # Nested modules for enhanced functionality
    NestedModules = @()
    
    # Functions to export from this module
    FunctionsToExport = @(
        # Unity Project Discovery and Configuration (Hour 1-2)
        'Find-UnityProjects',
        'Register-UnityProject',
        'Get-UnityProjectConfiguration',
        'Set-UnityProjectConfiguration',
        'Test-UnityProjectAvailability',
        
        # Parallel Unity Monitoring Architecture (Hour 1-2)
        'New-UnityParallelMonitor',
        'Start-UnityParallelMonitoring',
        'Stop-UnityParallelMonitoring',
        'Get-UnityMonitoringStatus',
        
        # Unity Compilation Process Integration (Hour 3-4)
        'Start-UnityCompilationJob',
        'Monitor-UnityCompilation',
        'Wait-UnityCompilationCompletion',
        'Stop-UnityCompilationJob',
        'Get-UnityCompilationResults',
        
        # Unity Log File Monitoring (Hour 3-4)  
        'Start-UnityLogMonitoring',
        'Parse-UnityEditorLog',
        'Extract-UnityCompilationErrors',
        'Stop-UnityLogMonitoring',
        
        # Concurrent Error Detection (Hour 5-6)
        'Start-ConcurrentErrorDetection',
        'Classify-UnityCompilationError',
        'Aggregate-UnityErrors',
        'Deduplicate-UnityErrors',
        'Get-UnityErrorStatistics',
        
        # Concurrent Error Export (Hour 7-8)
        'Export-UnityErrorsConcurrently',
        'Format-UnityErrorsForClaude',
        'Optimize-UnityErrorExport',
        'Integrate-UnitySystemStatus',
        'Test-UnityParallelizationPerformance'
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
            Tags = @('Unity', 'Claude', 'Automation', 'Parallelization', 'Compilation', 'Monitoring')
            LicenseUri = ''
            ProjectUri = ''
            IconUri = ''
            ReleaseNotes = 'Phase 1 Week 3 Days 1-2: Unity Compilation Parallelization implementation'
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
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCDLyJtu82TNBu+x
# sKbrGZMb53sMP578+ccuQy9+tJeTg6CCAzAwggMsMIICFKADAgECAhB1HRbZIqgr
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
# MAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIHtqM791U3Z/l5yyAxYWo/fU
# uDum2J+VzdtMilJ/+nCNMA0GCSqGSIb3DQEBAQUABIIBAJdUnUXYDIV6rHhTkWCu
# 3CzSS5pXHxR+v8rDV1iBACZYeEqbwrbv6YoWS+b8jbOXwYwT/rR3iVHk75gAU16A
# L820lmkKBl4+yDSoALRJpRUIirsfz7AmyouINaGlARHzy3EeMW+vyy4mcvp0ujfN
# QGV5BgNdZ0Ri480dUen3TstrnsY2qbNLgjMW4KEwBmBFhrlgcOxm65pybOK1GlYH
# u668qaIDJ6u9FCsZqrkMILfifKEWkPdrG5zH8hWjgcw2dYMpdD/Rgo4jAQNmUqU6
# cuEyJEOyZhxo/R2JyLRjrka8FuWlyraI0Sa+2pit8WFuf/fvoBhAmgWtc7YHEVIN
# b6o=
# SIG # End signature block
