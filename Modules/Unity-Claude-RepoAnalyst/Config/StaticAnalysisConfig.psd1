# Static Analysis Configuration Template
# Unity-Claude-RepoAnalyst Static Analysis Settings

@{
    # Global Configuration
    Version = '1.0.0'
    DefaultLinters = @('PSScriptAnalyzer', 'ESLint', 'Pylint')
    ParallelExecution = $true
    ThrottleLimit = 4
    MinSeverityLevel = 'Warning'
    
    # Output Settings
    OutputFormat = 'SARIF'
    GenerateReports = $true
    ReportOutputPath = '.\.ai\cache\analysis-reports'
    CacheResults = $true
    CachePath = '.\.ai\cache\linter-cache'
    
    # Global Exclusions
    ExcludePatterns = @(
        'node_modules/**/*'
        'vendor/**/*'
        '.venv/**/*'
        '__pycache__/**/*'
        'bin/**/*'
        'obj/**/*'
        '.git/**/*'
        '*.min.js'
        '*.min.css'
    )
    
    # File Type Mappings
    FileTypes = @{
        JavaScript = @('.js', '.jsx', '.mjs')
        TypeScript = @('.ts', '.tsx')
        PowerShell = @('.ps1', '.psm1', '.psd1')
        Python = @('.py', '.pyi')
        CSharp = @('.cs')
        JSON = @('.json')
        YAML = @('.yml', '.yaml')
    }
    
    # ESLint Configuration
    ESLint = @{
        Enabled = $true
        ConfigFile = '.eslintrc.json'
        Extensions = @('.js', '.jsx', '.ts', '.tsx')
        FixIssues = $false
        ExtraArgs = @('--format', 'json')
        Rules = @{
            'no-console' = 'warn'
            'no-unused-vars' = 'error'
            'no-debugger' = 'error'
        }
    }
    
    # Pylint Configuration  
    Pylint = @{
        Enabled = $true
        ConfigFile = '.pylintrc'
        OutputFormat = 'json'
        Extensions = @('.py')
        MaxLineLength = 120
        DisabledChecks = @('C0111', 'R0903')  # Missing docstring, Too few public methods
        EnabledChecks = @('all')
        SeverityMapping = @{
            'convention' = 'Info'
            'refactor' = 'Info'
            'warning' = 'Warning'
            'error' = 'Error'
            'fatal' = 'Error'
        }
    }
    
    # PowerShell Script Analyzer Configuration
    PSScriptAnalyzer = @{
        Enabled = $true
        ConfigFile = 'PSScriptAnalyzerSettings.psd1'
        Extensions = @('.ps1', '.psm1', '.psd1')
        Severity = @('Error', 'Warning', 'Information')
        IncludeRules = @()  # Empty means all rules
        ExcludeRules = @('PSAvoidUsingWriteHost')
        CustomRulePath = ''
        Settings = @{
            Rules = @{
                PSUseConsistentWhitespace = @{
                    Enable = $true
                    CheckInnerBrace = $true
                    CheckOpenBrace = $true
                    CheckOpenParen = $true
                    CheckOperator = $true
                    CheckPipe = $true
                    CheckSeparator = $true
                }
                PSUseConsistentIndentation = @{
                    Enable = $true
                    IndentationSize = 4
                    PipelineIndentation = 'IncreaseIndentationForFirstPipeline'
                    Kind = 'space'
                }
            }
        }
    }
    
    # Bandit Security Scanner Configuration
    Bandit = @{
        Enabled = $true
        Extensions = @('.py')
        OutputFormat = 'json'
        SeverityLevel = 'low'
        ConfidenceLevel = 'low'
        ExcludeTests = $true
        SkipChecks = @()  # B101, B601, etc.
        IncludeChecks = @()  # Empty means all checks
        ConfigFile = '.bandit'
        ReportFormat = 'json'
    }
    
    # Semgrep Security Scanner Configuration
    Semgrep = @{
        Enabled = $true
        Extensions = @('.js', '.jsx', '.ts', '.tsx', '.py', '.cs', '.java', '.go')
        OutputFormat = 'json'
        Rulesets = @(
            'auto'  # Auto-detect appropriate rulesets
            'p/security-audit'
            'p/owasp-top-10'
            'p/cwe-top-25'
        )
        ConfigFile = '.semgrep.yml'
        Timeout = 300  # 5 minutes
        MaxMemory = '4G'
        EnableSupplyChain = $true
        Severity = @('ERROR', 'WARNING', 'INFO')
    }
    
    # Performance Settings
    Performance = @{
        MaxConcurrentLinters = 4
        TimeoutSeconds = 300
        EnableCaching = $true
        CacheExpirationHours = 24
        MaxFileSize = 10MB  # Skip files larger than this
        MaxFilesPerLinter = 10000
    }
    
    # Reporting Configuration
    Reporting = @{
        GenerateHTML = $true
        GenerateJSON = $true
        GenerateSARIF = $true
        IncludeMetrics = $true
        IncludeTrends = $true
        TrendHistoryDays = 30
        GroupByLinter = $true
        GroupBySeverity = $true
        SuppressInfoLevel = $false
    }
    
    # Integration Settings
    Integration = @{
        UnityClaudeSystemStatus = @{
            Enabled = $true
            UpdateDashboard = $true
            NotifyOnErrors = $true
            NotifyOnWarnings = $false
        }
        
        MCP = @{
            Enabled = $false
            ServerPort = 8080
            ExposeAPI = $false
        }
        
        CI_CD = @{
            FailOnError = $true
            FailOnWarningThreshold = 50
            ExportResults = $true
            ExportPath = 'test-results/static-analysis'
        }
    }
    
    # Advanced Configuration
    Advanced = @{
        EnableDebugLogging = $false
        VerboseOutput = $false
        ProfileExecution = $false
        EnableDeduplication = $true
        CrossLinterCorrelation = $true
        HistoricalComparison = $true
        MachineLearningHints = $false
    }
}
# SIG # Begin signature block
# MIIFzgYJKoZIhvcNAQcCoIIFvzCCBbsCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCDG3ABsnVmH+QY9
# b7PdhfJzdDpVxev+ZmOd1/M5Xgmzu6CCAzAwggMsMIICFKADAgECAhB1HRbZIqgr
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
# MAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEINy1W4RKPTYaCPye3LsdqZi8
# Ig7lq2S/V/LurkO3xz1bMA0GCSqGSIb3DQEBAQUABIIBAGCrQJuPCWh7HkP7S6L6
# xx3bVw1mNL4u9cXwtATAEHOVORdAOFEdUTV/kkxqHyB5QvNg2gGq7Z77zZ0hDn2O
# RXYpGPuHrdG0bulDTtt9B6bHvCx4baricNsss9KgZRUsFvNq9g3/LQw48vTaNOPc
# yTLVTlSe1k7wpLL9ttbE3PMNv0QcHav68dbvCTW98dhwj9O7plrZc3LpvnX45N8m
# HEQUAd6S77Sz6TAsf6DJQCeawdSiMLQ0Nd1gWJJdFdmyHoyek1+8I4mZK+23Rn9E
# VpOov5pMRHF7/3dp5DrL1HWNvABfY96HsdiTwWNDSG1PigoT9j3YmelE6V+6Pzw5
# GmQ=
# SIG # End signature block
