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
# SIG # Begin signature block
# MIIFzgYJKoZIhvcNAQcCoIIFvzCCBbsCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCC6QepPYuCoCNHS
# 8zzAmR5OxDxtB6XfL8MdLaOB7nySYqCCAzAwggMsMIICFKADAgECAhB1HRbZIqgr
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
# MAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIANcd8ZGu1UIym+KxA1XHRRh
# /KvuB9hdtPtr2D12oLRNMA0GCSqGSIb3DQEBAQUABIIBAK866Z90d8iJDW8mSnlo
# vLQ22feTXGOcKKbxSH9iPJPRWtBhQxCt0TOyqHI4zGxQlKhpLjF1FPdSs3epuXSm
# dxheJPz8pmANy1uCk8eyF3niseaOLblIFafHTQKPswzMptjgkYnrT0+Y5paF8Tac
# SbkH03Uo45ZzexxVx6nmCcja/x8dLWNFlapxyLkegGKI3sDbCKdm0cJUfABHi6RN
# oUjd/THPVsGI/pa34y3h/VhRnUwZZBAKBedhAdfo9qrG0Ba7G5J/X31zZ3b8F3Pd
# zlzCcZ4BRcV+JrAi/fUrdqTPAdgzQgK88kJpqd1KQOorzJH8WAPPlbwLIXdftafI
# vc8=
# SIG # End signature block
