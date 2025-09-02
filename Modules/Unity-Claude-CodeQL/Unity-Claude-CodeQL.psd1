@{
    # Module manifest for Unity-Claude-CodeQL
    # Generated: 2025-08-25
    # Phase 3 Day 5: CodeQL Integration & Security

    RootModule = 'Unity-Claude-CodeQL.psm1'
    ModuleVersion = '1.0.0'
    GUID = 'f5e8c9a3-7b4d-4e89-9f71-2a5e8d6c4b31'
    Author = 'Unity-Claude-Automation'
    CompanyName = 'Unity-Claude'
    Copyright = '(c) 2025 Unity-Claude. All rights reserved.'
    Description = 'CodeQL integration module for security analysis of PowerShell, C#, and Unity code'
    PowerShellVersion = '5.1'
    
    # Dependencies
    RequiredModules = @()
    
    # Functions to export
    FunctionsToExport = @(
        # CodeQL CLI Management
        'Install-CodeQLCLI',
        'Test-CodeQLInstallation',
        'Update-CodeQLDatabase',
        
        # Database Creation
        'New-CodeQLDatabase',
        'Initialize-PowerShellCodeQLDB',
        'Initialize-CSharpCodeQLDB',
        'Update-CodeQLDatabase',
        
        # Query Execution
        'Invoke-CodeQLQuery',
        'Invoke-PowerShellSecurityScan',
        'Invoke-CSharpSecurityScan',
        'Get-CodeQLQuerySuite',
        
        # Custom Query Management
        'New-PowerShellSecurityQuery',
        'New-CSharpSecurityQuery',
        'Test-CodeQLQuery',
        'Install-CustomQueries',
        
        # Results Processing
        'Export-CodeQLResults',
        'ConvertTo-SecurityReport',
        'Get-VulnerabilityMetrics',
        'Format-SecurityFindings',
        
        # Integration
        'Register-SecurityCallback',
        'Send-SecurityAlert',
        'Update-SecurityDashboard',
        
        # Utility Functions
        'Get-CodeQLVersion',
        'Get-SupportedLanguages',
        'Clear-CodeQLCache'
    )
    
    # Variables to export
    VariablesToExport = @()
    
    # Aliases to export
    AliasesToExport = @(
        'cql-scan',     # Invoke-PowerShellSecurityScan
        'cql-db',       # New-CodeQLDatabase
        'cql-query',    # Invoke-CodeQLQuery
        'cql-report',   # Export-CodeQLResults
        'sec-scan'      # Invoke-PowerShellSecurityScan
    )
    
    # Private data
    PrivateData = @{
        PSData = @{
            Tags = @('CodeQL', 'Security', 'StaticAnalysis', 'PowerShell', 'CSharp', 'Unity', 'SAST')
            ProjectUri = 'https://github.com/unity-claude/codeql-integration'
            ReleaseNotes = 'Initial release with PowerShell and C# security analysis integration'
        }
        Configuration = @{
            DefaultCodeQLPath = "$env:USERPROFILE\codeql-home"
            DefaultDatabasePath = "$env:TEMP\codeql-databases"
            DefaultQueryPath = ".\queries"
            SecurityThreshold = 'medium'
            EnableRealTimeScanning = $false
            MaxDatabaseSize = '10GB'
            QueryTimeout = 300
        }
        QuerySuites = @{
            PowerShell = @(
                'script-injection',
                'credential-exposure', 
                'path-traversal',
                'command-injection',
                'unsafe-deserialization'
            )
            CSharp = @(
                'sql-injection',
                'xss',
                'path-injection',
                'unsafe-reflection',
                'insecure-randomness'
            )
        }
    }
}
# SIG # Begin signature block
# MIIFzgYJKoZIhvcNAQcCoIIFvzCCBbsCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCCwRbdlKV9YzQfW
# T8MSOu9XlGBmOxTM+ZXsLsGrJxj2PqCCAzAwggMsMIICFKADAgECAhB1HRbZIqgr
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
# MAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIJ5XoLD1Y1wszu7DIuiCDp/H
# V5RdzrpayGbuR+J1chr3MA0GCSqGSIb3DQEBAQUABIIBABZHZp8HBIMKndg32rFK
# cZ4Ll1ODuZLylOPjtU63BWtFD/CSYSm3KGULhUGcE3cZF8qhR392LfwJ3z0PO3zs
# Uzj1x3xyU1xnlJ0YDVzRHC6uZgMdP6c9kOBXiAMRTYkRzGLJiYc29xkbk9HXE/Wa
# PLL5IoRUikcuW5DOd1TXuILymlGqifXi/Qp7jzsuQXku7snKiciYJBCwiZIPKXjq
# yf0KoeqnhtnGjBvZAc+qLidIpi16ek/5k5lseMtw9O04cSR+RaiR94wIgAYAXxA9
# QmCh57zex47y0aUIuxzQUnD0fAeA8UOlENKEPvZumAGj7RHXzP+FXcgwxhu8m5qA
# EF4=
# SIG # End signature block
