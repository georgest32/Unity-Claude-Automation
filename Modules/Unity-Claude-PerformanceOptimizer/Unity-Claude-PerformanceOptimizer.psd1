@{
    # Module Manifest for Unity-Claude-PerformanceOptimizer
    # Phase 3 Day 1-2: Performance Optimization Integration
    # Version 2.0.0 - REFACTORED into modular components
    # Generated: 2025-08-25
    # Updated: 2025-08-26

    RootModule = 'Unity-Claude-PerformanceOptimizer-Refactored.psm1'
    ModuleVersion = '2.0.0'
    GUID = 'b9c8d7e6-f4a3-5b29-e678-901234567890'
    Author = 'Unity-Claude-Automation'
    CompanyName = 'Unity-Claude'
    Copyright = '(c) 2025 Unity-Claude. All rights reserved.'
    Description = 'REFACTORED: Performance optimization integration module combining caching, incremental processing, and parallel execution to achieve 100+ files/second processing for large codebases. Now uses modular component architecture.'
    PowerShellVersion = '5.1'
    
    # Required modules
    RequiredModules = @(
        'Unity-Claude-Cache',
        'Unity-Claude-IncrementalProcessor', 
        'Unity-Claude-ParallelProcessor',
        'Unity-Claude-CPG'
    )
    
    # Component modules (internal)
    NestedModules = @(
        'Core\OptimizerConfiguration.psm1',
        'Core\FileSystemMonitoring.psm1',
        'Core\PerformanceMonitoring.psm1',
        'Core\PerformanceOptimization.psm1',
        'Core\FileProcessing.psm1',
        'Core\ReportingExport.psm1'
    )
    
    # Functions to export from main module
    FunctionsToExport = @(
        # Core Performance Optimization
        'New-PerformanceOptimizer',
        'Start-OptimizedProcessing',
        'Stop-OptimizedProcessing',
        'Get-PerformanceMetrics',
        'Get-ThroughputMetrics',
        
        # Batch Processing
        'Start-BatchProcessor',
        
        # Performance Reporting
        'Export-PerformanceReport',
        
        # Component Health Monitoring
        'Get-PerformanceOptimizerComponents',
        'Test-PerformanceOptimizerHealth'
    )
    
    # Variables to export
    VariablesToExport = @()
    
    # Aliases to export
    AliasesToExport = @()
    
    # Private data
    PrivateData = @{
        PSData = @{
            Tags = @('Performance', 'Optimization', 'Cache', 'Incremental', 'Parallel', 'Batch', 'CPG', 'Unity', 'Claude', 'Refactored')
            ProjectUri = 'https://github.com/unity-claude/performance-optimizer'
            ReleaseNotes = @'
Version 2.0.0 - Major refactoring into modular component architecture
- Broke 891-line monolithic module into 6 focused components
- OptimizerConfiguration: Configuration and initialization (~200 lines)
- FileSystemMonitoring: File system watcher functionality (~150 lines)
- PerformanceMonitoring: Metrics tracking and analysis (~250 lines)
- PerformanceOptimization: Dynamic optimization strategies (~260 lines)
- FileProcessing: File processing engine (~270 lines)
- ReportingExport: Performance reporting utilities (~310 lines)
- Main orchestrator imports and coordinates all components
- Added component health monitoring functions
- Maintained backward compatibility with all original exports
- Improved maintainability and testability
'@
        }
        Configuration = @{
            TargetThroughput = 100  # files/second
            DefaultCacheSize = 5000
            DefaultBatchSize = 50
            MaxConcurrentJobs = 32  # 4x typical CPU cores
            CacheEvictionPolicy = 'LRU'
            IncrementalCheckInterval = 500  # milliseconds
            PerformanceReportingInterval = 30  # seconds
        }
        RefactoringInfo = @{
            RefactoredDate = '2025-08-26'
            ComponentCount = 6
            OriginalLineCount = 891
            RefactoredTotalLines = 1433  # Includes orchestrator
            AverageComponentSize = 240
        }
    }
}
# SIG # Begin signature block
# MIIFzgYJKoZIhvcNAQcCoIIFvzCCBbsCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCCXEVqCfRQ9n4Ht
# as9F+pzprguMvOtUTACROYb//nZDuKCCAzAwggMsMIICFKADAgECAhB1HRbZIqgr
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
# MAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIAnqFDmdHkg5kbTgzl510sp9
# VcsTZ0wkjKGIHUz2mILyMA0GCSqGSIb3DQEBAQUABIIBAJJ8ZP9UgH6aeSWWXOoG
# YAXtduEtmsSACziqyuMa5QC9BhylxjfixXcs15Ux713ymkhjCEAwBbzwFtjFOglC
# RBHhc9zXzVoKYT4MrD42ZZGH5rrSEX68a8JOZcg7LwQ4U3a8fA/xw23ijWmCH3qj
# RPD8sQV9Gbzr6Fv8qA/m2KDJB4lEF1XSjyAv2VsiVSCoY5Xzuu11QpFARnupE6gj
# D4AAZAqMyGIyNagicMsU9N1c/dn8JoELIeOcpDSozcJbzEjWy6Y+KUp3R+VQRrbR
# jB9MDJYKRjGdpXs63w3KRm+z0Adwup/zDwtmj2KFogLkQekBdJE0xGSYAplzKZFl
# pgs=
# SIG # End signature block
