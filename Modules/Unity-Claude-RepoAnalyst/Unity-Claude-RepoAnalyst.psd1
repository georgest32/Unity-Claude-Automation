@{
    # Module metadata
    ModuleVersion = '1.0.0'
    GUID = 'a7c3d9f1-8b2e-4d5f-9c1a-3e7b5d4f8a2c'
    Author = 'Unity-Claude-Automation'
    CompanyName = 'Unity-Claude-Automation Project'
    Copyright = '(c) 2025 Unity-Claude-Automation. All rights reserved.'
    Description = 'Multi-agent repository analysis and documentation system with LangGraph orchestration and MCP tool integration'
    
    # PowerShell version requirements
    PowerShellVersion = '5.1'
    
    # Root module file
    RootModule = 'Unity-Claude-RepoAnalyst.psm1'
    
    # Nested modules
    NestedModules = @()
    
    # Required modules - commenting out for initial setup
    RequiredModules = @()
    
    # Functions to export
    FunctionsToExport = @(
        # Code Analysis Functions - Ripgrep
        'Invoke-RipgrepSearch',
        'Get-CodeChanges',
        'Search-CodePattern',
        
        # Code Analysis Functions - CTags
        'Get-CtagsIndex',
        'Read-CtagsIndex',
        'Find-Symbol',
        'Update-CtagsIndex',
        
        # Code Analysis Functions - AST
        'Get-PowerShellAST',
        'Get-FunctionDependencies',
        'Find-ASTPattern',
        
        # Code Graph Functions
        'New-CodeGraph',
        'Update-CodeGraph',
        'Get-FileLanguage',
        
        # Documentation Functions
        'New-DocumentationUpdate',
        'Test-DocumentationDrift',
        'Invoke-DocGeneration',
        
        # MCP Server Functions
        'Start-MCPServer',
        'Stop-MCPServer',
        'Get-MCPServerStatus',
        'Invoke-MCPServerCommand',
        
        # Agent Coordination Functions
        'Start-RepoAnalystAgent',
        'Get-AgentStatus',
        'Send-AgentMessage',
        
        # Python Bridge Functions
        'Start-PythonBridge',
        'Invoke-PythonBridgeCommand',
        'Test-PythonBridge',
        'Stop-PythonBridge',
        'Invoke-PythonScript',
        'Get-PythonBridgeStatus',
        
        # Static Analysis Functions - Phase 2 Integration
        'Invoke-StaticAnalysis',
        'Invoke-ESLintAnalysis',
        'Invoke-PylintAnalysis',
        'Invoke-PSScriptAnalyzerEnhanced',
        'Invoke-BanditAnalysis',
        'Invoke-SemgrepAnalysis',
        'Merge-SarifResults',
        
        # Analysis Reporting Functions
        'New-AnalysisTrendReport',
        'New-AnalysisSummaryReport',
        
        # Initialization Functions
        'Initialize-RepoAnalyst',
        'Write-RepoAnalystLog'
    )
    
    # Variables to export
    VariablesToExport = @('ASTPatterns')
    
    # Aliases to export
    AliasesToExport = @('mcp')
    
    # Private data
    PrivateData = @{
        PSData = @{
            Tags = @('Repository', 'Analysis', 'Documentation', 'Multi-Agent', 'AI', 'MCP', 'LangGraph')
            LicenseUri = ''
            ProjectUri = 'https://github.com/Unity-Claude-Automation'
            ReleaseNotes = 'v1.0.0: Initial release with code analysis, documentation generation, and multi-agent coordination'
        }
    }
}
# SIG # Begin signature block
# MIIFzgYJKoZIhvcNAQcCoIIFvzCCBbsCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCCmoa6kRKBQwfgH
# zbaauY9UfDYTbjph/WT0ITd0hiAtV6CCAzAwggMsMIICFKADAgECAhB1HRbZIqgr
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
# MAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIA5c0vc0cVGlsOqXp/LgsooV
# AnYgdkCQyLu6bjDdifYlMA0GCSqGSIb3DQEBAQUABIIBAFzJGoZXVO6JW6uEOgHw
# oYolwpce6AisYDzsZyXNyh++JsprrysXPBGQCjh5kkFXbUffpTKLp35LoDO/I2V7
# 1mGXJ3WeNhEOuPbsA/KR8Fq+vtCOnf1kUAozDmGsQVquop21XRrCEzMucrbRclSo
# T6h7eqTtAwBKZbXu9UQU/IHRrY2y5pGU046ywEcxsIlCe3SZBGR7daADacsazMMH
# RPLszACI5l4k+TVpimOVObl07izfqaw74LkCLu150fdJUEJTSfaf3Rb7fb92LE8z
# kJSHkXyyS0WsbZuYjYwG/5dS141aE0AsvP2KC+A6tfFwt6sLxb8tjG2ti1O1A4if
# kzA=
# SIG # End signature block
