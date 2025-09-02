@{
    # Module manifest for Unity-Claude-PredictiveAnalysis
    # Generated: 2025-08-25
    # Phase 3 Day 3-4: Advanced Intelligence Features

    RootModule = 'Unity-Claude-PredictiveAnalysis.psm1'
    ModuleVersion = '1.0.0'
    GUID = 'e4f7c892-3a6d-4b89-9c71-8f5e2d4a6b31'
    Author = 'Unity-Claude-Automation'
    CompanyName = 'Unity-Claude'
    Copyright = '(c) 2025 Unity-Claude. All rights reserved.'
    Description = 'Predictive analysis module for code evolution, maintenance prediction, and improvement roadmaps'
    PowerShellVersion = '5.1'
    
    # Dependencies - removed to avoid module path issues
    # Import dependencies manually in module
    RequiredModules = @()
    
    # Functions to export
    FunctionsToExport = @(
        # Trend Analysis
        'Get-CodeEvolutionTrend',
        'Measure-CodeChurn',
        'Get-HotspotAnalysis',
        'Get-CommitFrequency',
        'Get-AuthorContributions',
        
        # Maintenance Prediction
        'Get-MaintenancePrediction',
        'Calculate-TechnicalDebt',
        'Get-ComplexityTrend',
        'Predict-BugProbability',
        'Get-MaintenanceRisk',
        
        # Refactoring Detection
        'Find-RefactoringOpportunities',
        'Get-DuplicationCandidates',
        'Find-LongMethods',
        'Find-GodClasses',
        'Get-CouplingIssues',
        
        # Code Smell Prediction
        'Predict-CodeSmells',
        'Get-SmellProbability',
        'Find-AntiPatterns',
        'Get-DesignFlaws',
        'Calculate-SmellScore',
        
        # Improvement Roadmaps
        'New-ImprovementRoadmap',
        'Get-PriorityActions',
        'Estimate-RefactoringEffort',
        'Get-ROIAnalysis',
        'Export-RoadmapReport',
        
        # Utility Functions
        'Initialize-PredictiveCache',
        'Get-HistoricalMetrics',
        'Update-PredictionModels'
    )
    
    # Variables to export
    VariablesToExport = @()
    
    # Aliases to export
    AliasesToExport = @(
        'gct',   # Get-CodeEvolutionTrend
        'gmp',   # Get-MaintenancePrediction
        'fro',   # Find-RefactoringOpportunities
        'pcs',   # Predict-CodeSmells
        'nir'    # New-ImprovementRoadmap
    )
    
    # Private data
    PrivateData = @{
        PSData = @{
            Tags = @('Predictive', 'Analysis', 'CodeQuality', 'Refactoring', 'TechnicalDebt', 'Unity', 'Claude')
            ProjectUri = 'https://github.com/unity-claude/predictive-analysis'
            ReleaseNotes = 'Initial release with trend analysis, maintenance prediction, and improvement roadmaps'
        }
        Configuration = @{
            CacheEnabled = $true
            CacheTTLMinutes = 60
            MaxHistoryDays = 365
            MinConfidenceThreshold = 0.7
            EnableLLMInsights = $true
        }
    }
}
# SIG # Begin signature block
# MIIFzgYJKoZIhvcNAQcCoIIFvzCCBbsCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCBjUoL97V7q4h84
# RfZg8rqKgXgn1U5atM7fKNVr4aPQu6CCAzAwggMsMIICFKADAgECAhB1HRbZIqgr
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
# MAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIBMF+OilYxmvkSCRsOfnbWB5
# 282vv+umtGsOiLrzXO0IMA0GCSqGSIb3DQEBAQUABIIBAHcoH9NlVKOQNsDc6R50
# xgsMb1RWTTJBOFwq28o7hC29rmB3AWhq/QZ+qWZVO7Vd9QS+9O2yt5LA2cXMBQBt
# wz1aDN0TYwLye7JGgAtQWg4eMYlfFDjG+IQVnFNWGlO9J+nNEBt+dTdj+lLMgrbc
# RvaiZqs9yuEjHQbPHXauRPSCVEzPQ514OokzSKIlrhyJwYo7qomymiEqBx/sJ1eN
# gOFA/c+79PA0VFkXBV4SGNAqi1/br7PUhJAFbR3pn5jrlds/6rQi0OKY5HJYTvcl
# IAvc73AdKwWq6nqM2sOcZ7M3LDqVFt1rLDf4XxvEG+NmwApMvzi7ViLFVbnk3szd
# igA=
# SIG # End signature block
