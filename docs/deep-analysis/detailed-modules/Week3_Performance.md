# Week3-Performance - Detailed Module Analysis
**Enhanced Documentation System v2.0.0**
**Generated**: 2025-08-29 12:31:39
**Module Count**: 5
**Total Lines**: 1879
**Total Functions**: 28

## Category Overview
Supporting infrastructure component for Enhanced Documentation System operations

## Detailed Module Analysis

### Unity-Claude-UnityParallelization-Refactored 🟢
- **Path**: $(@{ModuleName=Unity-Claude-UnityParallelization-Refactored; DetailedCategory=Week3-Performance; SystemRole=Supporting infrastructure component for Enhanced Documentation System operations; RelativePath=Modules\Unity-Claude-UnityParallelization\Unity-Claude-UnityParallelization-Refactored.psm1; LineCount=262; FunctionCount=2; Functions=System.Object[]; ClassCount=0; Classes=System.Object[]; ExportCount=0; Exports=System.Object[]; Dependencies=System.Object[]; FileSizeKB=10.72; LastModified=08/26/2025 11:46:19; Complexity=6.62; Importance=Support}.RelativePath)
- **System Role**: Supporting infrastructure component for Enhanced Documentation System operations
- **Metrics**: 10.72 KB, 262 lines, 2 functions, 0 classes
- **Complexity Score**: 6.6
- **Last Modified**: 2025-08-26 11:46:19
- **Importance**: Support

#### Functions (2 total)
- **Get-UnityParallelizationModuleInfo** (Line 102) - **Show-UnityParallelizationFunctions** (Line 117)



#### Dependencies
- $modulePath



--- ### Unity-Claude-UnityParallelization 🟢
- **Path**: $(@{ModuleName=Unity-Claude-UnityParallelization; DetailedCategory=Week3-Performance; SystemRole=Supporting infrastructure component for Enhanced Documentation System operations; RelativePath=Modules\Unity-Claude-UnityParallelization\Unity-Claude-UnityParallelization.psm1; LineCount=262; FunctionCount=2; Functions=System.Object[]; ClassCount=0; Classes=System.Object[]; ExportCount=0; Exports=System.Object[]; Dependencies=System.Object[]; FileSizeKB=10.72; LastModified=08/26/2025 11:46:19; Complexity=6.62; Importance=Support}.RelativePath)
- **System Role**: Supporting infrastructure component for Enhanced Documentation System operations
- **Metrics**: 10.72 KB, 262 lines, 2 functions, 0 classes
- **Complexity Score**: 6.6
- **Last Modified**: 2025-08-26 11:46:19
- **Importance**: Support

#### Functions (2 total)
- **Get-UnityParallelizationModuleInfo** (Line 102) - **Show-UnityParallelizationFunctions** (Line 117)



#### Dependencies
- $modulePath



--- ### Unity-Claude-ParallelProcessor-Refactored 🟢
- **Path**: $(@{ModuleName=Unity-Claude-ParallelProcessor-Refactored; DetailedCategory=Week3-Performance; SystemRole=Supporting infrastructure component for Enhanced Documentation System operations; RelativePath=Modules\Unity-Claude-ParallelProcessor\Unity-Claude-ParallelProcessor-Refactored.psm1; LineCount=250; FunctionCount=1; Functions=System.Object[]; ClassCount=0; Classes=System.Object[]; ExportCount=0; Exports=System.Object[]; Dependencies=System.Object[]; FileSizeKB=10.43; LastModified=08/26/2025 11:46:19; Complexity=4.5; Importance=Support}.RelativePath)
- **System Role**: Supporting infrastructure component for Enhanced Documentation System operations
- **Metrics**: 10.43 KB, 250 lines, 1 functions, 0 classes
- **Complexity Score**: 4.5
- **Last Modified**: 2025-08-26 11:46:19
- **Importance**: Support

#### Functions (1 total)
- **Get-UnityClaudeParallelProcessorInfo** (Line 117)



#### Dependencies
- $ComponentPath\ParallelProcessorCore.psm1 - $ComponentPath\RunspacePoolManager.psm1 - $ComponentPath\StatisticsTracker.psm1 - $ComponentPath\JobScheduler.psm1 - $ComponentPath\BatchProcessingEngine.psm1 - $ComponentPath\ModuleFunctions.psm1



--- ### Unity-Claude-ParallelProcessor 🟢
- **Path**: $(@{ModuleName=Unity-Claude-ParallelProcessor; DetailedCategory=Week3-Performance; SystemRole=Supporting infrastructure component for Enhanced Documentation System operations; RelativePath=Modules\Unity-Claude-ParallelProcessor\Unity-Claude-ParallelProcessor.psm1; LineCount=250; FunctionCount=1; Functions=System.Object[]; ClassCount=0; Classes=System.Object[]; ExportCount=0; Exports=System.Object[]; Dependencies=System.Object[]; FileSizeKB=10.43; LastModified=08/26/2025 11:46:19; Complexity=4.5; Importance=Support}.RelativePath)
- **System Role**: Supporting infrastructure component for Enhanced Documentation System operations
- **Metrics**: 10.43 KB, 250 lines, 1 functions, 0 classes
- **Complexity Score**: 4.5
- **Last Modified**: 2025-08-26 11:46:19
- **Importance**: Support

#### Functions (1 total)
- **Get-UnityClaudeParallelProcessorInfo** (Line 117)



#### Dependencies
- $ComponentPath\ParallelProcessorCore.psm1 - $ComponentPath\RunspacePoolManager.psm1 - $ComponentPath\StatisticsTracker.psm1 - $ComponentPath\JobScheduler.psm1 - $ComponentPath\BatchProcessingEngine.psm1 - $ComponentPath\ModuleFunctions.psm1



--- ### Unity-Claude-PerformanceOptimizer 🟢
- **Path**: $(@{ModuleName=Unity-Claude-PerformanceOptimizer; DetailedCategory=Week3-Performance; SystemRole=Supporting infrastructure component for Enhanced Documentation System operations; RelativePath=Modules\Unity-Claude-PerformanceOptimizer.psm1; LineCount=855; FunctionCount=22; Functions=System.Object[]; ClassCount=0; Classes=System.Object[]; ExportCount=0; Exports=System.Object[]; Dependencies=System.Object[]; FileSizeKB=27.63; LastModified=08/20/2025 17:25:22; Complexity=52.55; Importance=Medium}.RelativePath)
- **System Role**: Supporting infrastructure component for Enhanced Documentation System operations
- **Metrics**: 27.63 KB, 855 lines, 22 functions, 0 classes
- **Complexity Score**: 52.6
- **Last Modified**: 2025-08-20 17:25:22
- **Importance**: Medium

#### Functions (22 total)
- **Write-PerfLog** (Line 73) - **Get-PerfTimestamp** (Line 105) - **New-PerformanceId** (Line 109) - **Start-OperationProfile** (Line 117) - **Stop-OperationProfile** (Line 149) - **Measure-OperationPerformance** (Line 192) - **Update-PerformanceMetrics** (Line 223) - **Record-Bottleneck** (Line 249) - **Save-ProfileData** (Line 271) - **Get-CachedFileContent** (Line 300) - **Read-FileDirectly** (Line 359) - **Get-CachedComputationResult** (Line 384) - **Manage-CacheSize** (Line 425) - **Clear-PerformanceCache** (Line 445) - **Get-OptimizedRegex** (Line 491) - **Invoke-OptimizedRegexMatch** (Line 513) - **Optimize-JsonProcessing** (Line 544) - **Invoke-OptimizedBatchProcessing** (Line 584) - **Optimize-MemoryUsage** (Line 639) - **Clear-ExpiredCacheEntries** (Line 690) - **Get-PerformanceReport** (Line 716) - **Test-PerformanceThresholds** (Line 751)







---

## Week3-Performance Summary Statistics
- **Average Module Size**: 14 KB
- **Average Functions per Module**: 5.6
- **Most Complex Module**: Unity-Claude-PerformanceOptimizer (52.6 complexity)
- **Critical Modules**: 0
- **High Priority Modules**: 0

*Detailed analysis of Week3-Performance modules in Enhanced Documentation System v2.0.0*
