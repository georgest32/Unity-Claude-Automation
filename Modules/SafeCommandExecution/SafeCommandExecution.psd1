@{
    # Module manifest for SafeCommandExecution module
    
    # Script module or binary module file associated with this manifest.
    RootModule = 'SafeCommandExecution-Refactored.psm1'
    
    # Version number of this module.
    ModuleVersion = '2.0.0'
    
    # ID used to uniquely identify this module
    GUID = 'a7b8c9d0-e1f2-3456-7890-bcdef1234567'
    
    # Author of this module
    Author = 'Unity-Claude Automation System'
    
    # Company or vendor of this module
    CompanyName = 'Sound and Shoal'
    
    # Copyright statement for this module
    Copyright = '(c) 2025 Sound and Shoal. All rights reserved.'
    
    # Description of the functionality provided by this module
    Description = 'Safe Command Execution module (v2.0 Refactored) providing constrained runspace execution for Unity automation with modular architecture. Features 10 focused components for security validation, Unity testing/building/analysis, and comprehensive reporting'
    
    # Minimum version of the PowerShell engine required by this module
    PowerShellVersion = '5.1'
    
    # Functions to export from this module
    FunctionsToExport = @(
        # Core Security Functions (Day 3-4)
        'Invoke-SafeCommand',
        'New-ConstrainedRunspace',
        'Test-CommandSafety',
        'Test-PathSafety',
        'Remove-DangerousCharacters',
        'Set-SafeCommandConfiguration',
        'Get-SafeCommandConfiguration',
        'Write-SafeLog',
        
        # Unity Command Execution Functions (Day 4-5)
        'Invoke-UnityCommand',
        'Invoke-TestCommand',
        'Invoke-PowerShellCommand',
        'Invoke-BuildCommand',
        'Invoke-UnityPlayerBuild',
        'New-UnityBuildScript',
        'Test-UnityBuildResult',
        'Invoke-UnityAssetImport',
        'New-UnityAssetImportScript',
        'Invoke-UnityCustomMethod',
        'Invoke-UnityProjectValidation',
        'Invoke-UnityScriptCompilation',
        'Test-UnityCompilationResult',
        'Find-UnityExecutable',
        
        # ANALYZE Command Functions (Day 6)
        'Invoke-AnalysisCommand',
        'Invoke-UnityLogAnalysis',
        'Invoke-UnityErrorPatternAnalysis',
        'Invoke-UnityPerformanceAnalysis',
        'Invoke-UnityTrendAnalysis',
        'Invoke-UnityReportGeneration',
        'Export-UnityAnalysisData',
        'Get-UnityAnalyticsMetrics'
    )
    
    # Cmdlets to export from this module
    CmdletsToExport = @()
    
    # Variables to export from this module
    VariablesToExport = @()
    
    # Aliases to export from this module
    AliasesToExport = @()
    
    # Private data to pass to the module specified in RootModule/ModuleToProcess
    PrivateData = @{
        PSData = @{
            Tags = @('Security', 'Unity', 'Automation', 'ConstrainedRunspace', 'SafeExecution')
            ProjectUri = 'https://github.com/sound-and-shoal/unity-claude-automation'
            ReleaseNotes = 'Version 2.0.0: MAJOR REFACTORING - Modularized 2860-line monolithic module into 10 focused components (~315 lines each) in Core/ subdirectory. Improved maintainability, testability, and performance while preserving all functionality'
        }
    }
}
# SIG # Begin signature block
# MIIFzgYJKoZIhvcNAQcCoIIFvzCCBbsCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCC0lmszYZwhEu/w
# fbeTHOifp+7WPxGQLml+Szfdv1Z/jqCCAzAwggMsMIICFKADAgECAhB1HRbZIqgr
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
# MAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIHSV7Kx6govQzrjr1kksiEdg
# 47Nz+mQDp5Vk11H0uVr9MA0GCSqGSIb3DQEBAQUABIIBAEtX9gYWdbmJFxwbiuiS
# hnlUzhECpnUqcS+ZHZHFVqY++pvtTTOjM7hy3ev/MVsrkBAk1VgBd8JGlikATpaN
# cjdIUgTQz8qCddISHu6eD/o5a/kSbrRHtr/SksrJPcGt8opVoFvjmx7ore7XnfmW
# uT7M82T8O4Jd89LE6ZaL/Am68bS2z3xSkDy8kRZzV4VBRE/arEC8g0yMBQ3POS3r
# Nw70DEsYKWI/yA/d3bGTGXTlaI32c1EVLVfkSYJoNOFj1mwe3eeKU81ODlKKjiQV
# vkxyv8yjvvoN+e1Zub2xDXplg432Z6CtmnNlibGrhORlVnbXerSDyMI6gFA0Mn/i
# Ea8=
# SIG # End signature block
