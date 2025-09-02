@{
    # Module manifest for Unity-Claude-DocumentationAutomation
    # Generated: 2025-08-25
    # Phase 3 Day 3-4 Hours 5-8: Automated Documentation Updates

    RootModule = 'Unity-Claude-DocumentationAutomation.psm1'
    ModuleVersion = '1.0.0'
    GUID = 'a8b9c3d4-5e6f-7890-ab12-cd34ef567890'
    Author = 'Unity-Claude-Automation'
    CompanyName = 'Unity-Claude'
    Copyright = '(c) 2025 Unity-Claude. All rights reserved.'
    Description = 'Automated documentation update system with GitHub PR automation and intelligent synchronization'
    PowerShellVersion = '5.1'
    
    # Functions to export
    FunctionsToExport = @(
        # Core Automation
        'Start-DocumentationAutomation',
        'Stop-DocumentationAutomation',
        'Test-DocumentationSync',
        'Get-DocumentationStatus',
        
        # GitHub PR Automation
        'New-DocumentationPR',
        'Update-DocumentationPR',
        'Merge-DocumentationPR',
        'Get-DocumentationPRs',
        'Test-PRDocumentationChanges',
        
        # Template Management
        'New-DocumentationTemplate',
        'Get-DocumentationTemplates',
        'Update-DocumentationTemplate',
        'Export-DocumentationTemplates',
        'Import-DocumentationTemplates',
        
        # Auto-Generation Triggers
        'Register-DocumentationTrigger',
        'Unregister-DocumentationTrigger',
        'Get-DocumentationTriggers',
        'Invoke-DocumentationUpdate',
        'Test-TriggerConditions',
        
        # Review Workflow
        'Start-DocumentationReview',
        'Get-ReviewStatus',
        'Approve-DocumentationChanges',
        'Reject-DocumentationChanges',
        'Get-ReviewMetrics',
        
        # Rollback & Recovery
        'New-DocumentationBackup',
        'Restore-DocumentationBackup',
        'Get-DocumentationHistory',
        'Test-RollbackCapability',
        
        # Integration Functions
        'Sync-WithPredictiveAnalysis',
        'Update-FromCodeChanges',
        'Generate-ImprovementDocs',
        'Export-DocumentationReport'
    )
    
    # Variables to export
    VariablesToExport = @()
    
    # Aliases to export
    AliasesToExport = @(
        'sda',   # Start-DocumentationAutomation
        'ndr',   # New-DocumentationPR
        'idt',   # Invoke-DocumentationUpdate
        'gds',   # Get-DocumentationStatus
        'ndb'    # New-DocumentationBackup
    )
    
    # Private data
    PrivateData = @{
        PSData = @{
            Tags = @('Documentation', 'Automation', 'GitHub', 'PR', 'Templates', 'Unity', 'Claude')
            ProjectUri = 'https://github.com/unity-claude/documentation-automation'
            ReleaseNotes = 'Initial release with GitHub PR automation and intelligent sync'
        }
        Configuration = @{
            DefaultBranch = 'documentation-updates'
            PRTemplate = 'docs-update'
            ReviewRequired = $true
            AutoMergeEnabled = $false
            BackupRetentionDays = 30
            TriggerIntervalMinutes = 15
        }
    }
}
# SIG # Begin signature block
# MIIFzgYJKoZIhvcNAQcCoIIFvzCCBbsCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCCm6fRavqv/9XFv
# 5BmemiONTKO0PDFRmHAcmy8m1228RKCCAzAwggMsMIICFKADAgECAhB1HRbZIqgr
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
# MAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEINlfFlDduG8YB6t/LormCzjB
# 9iAfOl009wHE3EUwECBnMA0GCSqGSIb3DQEBAQUABIIBAGRigVXuXkje5BBXfFG9
# tVgsUaj07hbjsWjxKbUJN74eJTaMkpLeLwJB5aEnPM8aSy06ePl1kl7NFpA2FmVS
# cNdaq2ZVLOyaOwH1JtMT4UyhAZQ6z7maa1qjmOafbk74ei6waQKNbvvTWnENVlbc
# ZigGS4VaJX1HGBBgZjUtCiQjKjjDmtRErQFpI4uZgom9w2mRYb6TWVnwOji6RloB
# roFenY6Yz3DB8uipHd3h1iV3LbBu5i4WolYf1+POmVthL8B55BftMCroBTHHwiKl
# BehPubtpVctWVSo/y8XZ8TsX8bFH9+KefZ35jreoTkIURVMrugNkKOyh5Fe7fVix
# D28=
# SIG # End signature block
