@{
    # Module manifest for IntelligentPromptEngine module
    
    # Script module or binary module file associated with this manifest
    RootModule = 'IntelligentPromptEngine.psm1'
    
    # Version number of this module
    ModuleVersion = '1.0.0'
    
    # ID used to uniquely identify this module
    GUID = 'f1e2d3c4-b5a6-7890-1234-56789abcdef0'
    
    # Author of this module
    Author = 'Unity-Claude Automation System'
    
    # Company or vendor of this module
    CompanyName = 'Sound and Shoal'
    
    # Copyright statement for this module
    Copyright = '(c) 2025 Sound and Shoal. All rights reserved.'
    
    # Description of the functionality provided by this module
    Description = 'Phase 2 Intelligent Prompt Generation Engine providing result analysis, prompt type selection, and template system for autonomous Claude interaction'
    
    # Minimum version of the PowerShell engine required by this module
    PowerShellVersion = '5.1'
    
    # Functions to export from this module
    FunctionsToExport = @(
        # Result Analysis Framework
        'Invoke-CommandResultAnalysis',
        'Get-ResultClassification',
        'Get-ResultSeverity',
        'Find-ResultPatterns',
        'Get-HistoricalPatterns',
        'Get-NextActionRecommendations',
        
        # Prompt Type Selection Logic
        'Invoke-PromptTypeSelection',
        'New-PromptTypeDecisionTree',
        'Invoke-DecisionTreeAnalysis',
        'Invoke-NodeEvaluation',
        
        # Prompt Template System
        'New-PromptTemplate',
        'Get-BasePromptTemplate',
        'Get-TypeSpecificVariables',
        'Invoke-TemplateRendering'
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
            Tags = @('Intelligence', 'Automation', 'Claude', 'PromptGeneration', 'DecisionTree', 'Templates')
            ProjectUri = 'https://github.com/sound-and-shoal/unity-claude-automation'
            ReleaseNotes = 'Initial release of IntelligentPromptEngine module for Phase 2 Day 8 implementation with result analysis, prompt type selection, and template system'
        }
    }
}
# SIG # Begin signature block
# MIIFqQYJKoZIhvcNAQcCoIIFmjCCBZYCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUga998IJVm+u7RlB3NIf2P36q
# HrWgggMwMIIDLDCCAhSgAwIBAgIQdR0W2SKoK5VE8JId4ZxrRTANBgkqhkiG9w0B
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
# CQQxFgQUsv95hXyzuWoouET2CQetDVUgX5wwDQYJKoZIhvcNAQEBBQAEggEADC7n
# 6KYrPWyTd+6KXxnoF67VErDLGHidNypqFm/46JbaJC6918lQzZ4Ar/af9mYtw3iL
# G+rJl0nICF84MxPbrIhS5BGOqFjLrsqegK4I//OhA93hc2YA4sU9fXhFrCj+fWIA
# XyRx6v0jC/aY1TPdXJN183GsL9mpWcLoVlKEAWqfkgpEKAu5IanC55c0dZFNK1ku
# P3Hvu5C1SvveKjSwqGR7PDlGQ238aw2Y95Ozvq4SFWLcVkeP6om1CYclZ+U4PaRF
# h0lqe6hWxSFkoTwL3RpfhX92uadn0cDnBRP82HB8dK3tzb5PoU9Y8uFYFEeXzXkX
# ytEd1pkZh6VHNkvYOg==
# SIG # End signature block
