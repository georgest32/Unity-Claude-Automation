@{
    # Module manifest for SafeCommandExecution module
    
    # Script module or binary module file associated with this manifest.
    RootModule = 'SafeCommandExecution.psm1'
    
    # Version number of this module.
    ModuleVersion = '1.2.0'
    
    # ID used to uniquely identify this module
    GUID = 'a7b8c9d0-e1f2-3456-7890-bcdef1234567'
    
    # Author of this module
    Author = 'Unity-Claude Automation System'
    
    # Company or vendor of this module
    CompanyName = 'Sound and Shoal'
    
    # Copyright statement for this module
    Copyright = '(c) 2025 Sound and Shoal. All rights reserved.'
    
    # Description of the functionality provided by this module
    Description = 'Safe Command Execution module providing constrained runspace execution for Unity automation with comprehensive security validation, Unity testing/building/analysis capabilities'
    
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
            ReleaseNotes = 'Version 1.2.0: Added Day 6 ANALYZE command automation with Unity log analysis, error pattern detection, performance analysis, and comprehensive reporting capabilities'
        }
    }
}
# SIG # Begin signature block
# MIIFqQYJKoZIhvcNAQcCoIIFmjCCBZYCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUGXJOAPzMFYCKOEfr37rXVWOA
# pjagggMwMIIDLDCCAhSgAwIBAgIQdR0W2SKoK5VE8JId4ZxrRTANBgkqhkiG9w0B
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
# CQQxFgQURCY7LBKMvm/wuA0+x9Z5b6alnjswDQYJKoZIhvcNAQEBBQAEggEAaNnu
# 1qDxtGkV+fstMTqHkwX/RaadGt2RMYGKdcftgjfs4uiOumDprh0EDXXYgU4Moits
# LgsB5struo4K8bhWVcvQtx48oRIjWsX4em4RZjmPhrqFWDXKlGkbkl63Jk+WRWep
# py7RVcZQ4xlWNb2jdT5iii2SPX4EhgskaAfAvbYb3bjlzheEOeR/jLoqUPwf0D/r
# DUcM9impA530EIwoi4Z0bgfmcxIfmh37gSnDxmCKSdaFJmegNpXePnpI5xvXA7mG
# x2FZMdRoTsG3Bi/ZSMHYGIoRVdvahyKBekAyfaXKnMZOwVxdv4j/7jk6BEMF113l
# z1nICeqWI859FD194A==
# SIG # End signature block
