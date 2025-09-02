@{
    RootModule = 'Unity-Claude-ScalabilityEnhancements-Refactored.psm1'
    ModuleVersion = '2.0.0'
    GUID = 'a1b2c3d4-e5f6-4a5b-8c9d-0e1f2a3b4c5d'
    Author = 'Unity-Claude-Automation'
    CompanyName = 'Unity-Claude Development'
    Copyright = '(c) 2025 Unity-Claude-Automation. All rights reserved.'
    Description = @'
Unity-Claude-ScalabilityEnhancements - Refactored Component-Based Architecture v2.0.0

Enterprise-scale code analysis with advanced optimization techniques. This module provides comprehensive
scalability enhancements including graph optimization, pagination, background job processing, progress
tracking, memory management, and horizontal scaling preparation.

REFACTORING BENEFITS:
- Reduced complexity: 6 focused components (avg 263 lines) vs 1,580-line monolith
- 83% complexity reduction per component 
- Enhanced maintainability and testability
- Improved separation of concerns
- Better error isolation and debugging
- Modular development and deployment

COMPONENT ARCHITECTURE:
- GraphOptimizer.psm1: Graph pruning, compression, and structure optimization
- PaginationProvider.psm1: Result pagination and data navigation
- BackgroundJobQueue.psm1: Concurrent job processing with prioritization
- ProgressTracker.psm1: Progress monitoring and cancellation tokens
- MemoryManager.psm1: Memory optimization and pressure monitoring  
- HorizontalScaling.psm1: Scaling configuration and distributed mode preparation

CAPABILITIES:
✓ Graph pruning with configurable preservation patterns
✓ Intelligent data compression and memory optimization
✓ Concurrent background job processing with priority queues
✓ Real-time progress tracking with ETAs and callbacks
✓ Advanced memory management with pressure monitoring
✓ Horizontal scaling readiness assessment and partitioning
✓ Enterprise-grade error handling and logging
✓ Thread-safe collections and cancellation support
'@
    
    PowerShellVersion = '5.1'
    DotNetFrameworkVersion = '4.7.2'
    RequiredModules = @()
    
    # Functions to export
    FunctionsToExport = @(
        # Enhanced Orchestration Functions
        'Initialize-ScalabilityEnhancements',
        'Test-ScalabilityComponents',
        'Get-ScalabilityInfo', 
        'Update-ScalabilityStatistics',
        
        # Graph Optimizer Functions
        'Start-GraphPruning',
        'Remove-UnusedNodes',
        'Optimize-GraphStructure',
        'Compress-GraphData',
        'Get-PruningReport',
        
        # Pagination Provider Functions  
        'New-PaginationProvider',
        'Get-PaginatedResults',
        'Set-PageSize',
        'Navigate-ResultPages',
        'Export-PagedData',
        
        # Background Job Queue Functions
        'New-BackgroundJobQueue',
        'Add-JobToQueue', 
        'Start-QueueProcessor',
        'Stop-QueueProcessor',
        'Get-QueueStatus',
        'Get-JobResults',
        'Remove-CompletedJobs',
        'Invoke-JobPriorityUpdate',
        
        # Progress Tracker Functions
        'New-ProgressTracker',
        'Update-OperationProgress',
        'Get-ProgressReport', 
        'New-CancellationToken',
        'Test-CancellationRequested',
        'Cancel-Operation',
        'Register-ProgressCallback',
        
        # Memory Manager Functions
        'Start-MemoryOptimization',
        'Get-MemoryUsageReport',
        'Force-GarbageCollection',
        'Optimize-ObjectLifecycles',
        'Monitor-MemoryPressure',
        
        # Horizontal Scaling Functions
        'New-ScalingConfiguration',
        'Test-HorizontalReadiness',
        'Export-ScalabilityMetrics',
        'Prepare-DistributedMode'
    )
    
    CmdletsToExport = @()
    VariablesToExport = @()
    AliasesToExport = @()
    
    # Module metadata
    PrivateData = @{
        PSData = @{
            Tags = @(
                'Unity-Claude-Automation',
                'Scalability',
                'Performance',
                'GraphOptimization', 
                'MemoryManagement',
                'BackgroundJobs',
                'ProgressTracking',
                'HorizontalScaling',
                'Enterprise',
                'CodeAnalysis',
                'Refactored'
            )
            LicenseUri = ''
            ProjectUri = ''
            ReleaseNotes = @'
Version 2.0.0 - Component-Based Refactored Architecture
- Refactored monolithic 1,580-line module into 6 focused components
- Enhanced error handling and logging throughout all components
- Improved thread safety with concurrent collections
- Advanced memory management with pressure monitoring
- Comprehensive progress tracking with real-time ETAs
- Enterprise-grade background job processing
- Horizontal scaling readiness assessment
- 83% complexity reduction per component
- Full backward compatibility maintained
- Enhanced testability and maintainability
'@
        }
        
        RefactoringInfo = @{
            OriginalModuleSize = 1580
            ComponentCount = 6
            AverageComponentSize = 263
            ComplexityReduction = '83%'
            RefactoredDate = '2025-08-25'
            RefactoringVersion = '2.0.0'
            BackwardCompatible = $true
            Components = @(
                @{
                    Name = 'GraphOptimizer.psm1'
                    Lines = 309
                    Purpose = 'Graph pruning, compression, and structure optimization'
                    Functions = 5
                },
                @{
                    Name = 'PaginationProvider.psm1'
                    Lines = 204  
                    Purpose = 'Result pagination and data navigation'
                    Functions = 5
                },
                @{
                    Name = 'BackgroundJobQueue.psm1'
                    Lines = 323
                    Purpose = 'Concurrent job processing with prioritization' 
                    Functions = 8
                },
                @{
                    Name = 'ProgressTracker.psm1'
                    Lines = 209
                    Purpose = 'Progress monitoring and cancellation tokens'
                    Functions = 7
                },
                @{
                    Name = 'MemoryManager.psm1'
                    Lines = 227
                    Purpose = 'Memory optimization and pressure monitoring'
                    Functions = 5
                },
                @{
                    Name = 'HorizontalScaling.psm1'
                    Lines = 257
                    Purpose = 'Scaling configuration and distributed mode preparation'
                    Functions = 4
                }
            )
        }
    }
    
    HelpInfoURI = ''
    DefaultCommandPrefix = ''
}
# SIG # Begin signature block
# MIIFzgYJKoZIhvcNAQcCoIIFvzCCBbsCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCC7kKZEamc4X+0s
# dPE23IcbWzDLWIrvXipyYJZqLURNOKCCAzAwggMsMIICFKADAgECAhB1HRbZIqgr
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
# MAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIBYtesVVNLyiCNA8pmP5+5RZ
# GBMvinAU+G/gnUbH7xM0MA0GCSqGSIb3DQEBAQUABIIBAGqJSRuGAkTTv705V1pc
# i3twsCs7MLhb/Y95HbAQ7sedGkuDtHEHQmXQs7M/ByAd0Mx4ZgOA2g/EoXYhJJ4m
# qTR3ogQOesURjNuFkvNpgvHRHiiIxMrX1KNLROCb3Ik73JhlK7dIAia32M27KMtq
# rZw6PWs9+bf5dVS67aPcbwZbjZ0vS54gJRtqm7nD/1L1MIhtB2ZcJSIAoKlzfqsf
# T4lGvMRpMNOM89ZDAQaKNQffVfjlmo4C1ZqMJqX38LIKPCd0BwAqZ05et+syUiLq
# aZlf6P5lF3X/9wnqBJ9ENww0HErx+UA0s7Xje4r2SVq0OHu6NoGEeDMZ+5ujYa0o
# J0g=
# SIG # End signature block
