# Unity-Claude-ScalabilityEnhancements-Original

**Type:** PowerShell Module  
**Path:** `Modules\Unity-Claude-ScalabilityEnhancements\Unity-Claude-ScalabilityEnhancements-Original.psm1`  
**Size:** 48.16 KB  
**Last Modified:** 08/26/2025 11:46:19  

## Statistics

- **Total Functions:** 70
- **Total Lines:** 1582
- **Average Function Size:** 18.9 lines

## Functions


### Add-JobToQueue

- **Location:** Line 684
- **Size:** 27 lines

 
### AddJob

- **Location:** Line 544
- **Size:** 17 lines
- **Parameters:** jobScript, parameters, priority
 
### AssessScalabilityReadiness

- **Location:** Line 1339
- **Size:** 47 lines
- **Parameters:** graph
 
### BackgroundJobQueue

- **Location:** Line 534
- **Size:** 8 lines
- **Parameters:** maxConcurrentJobs
 
### CalculateGraphSize

- **Location:** Line 145
- **Size:** 5 lines
- **Parameters:** graph
 
### Cancel

- **Location:** Line 920
- **Size:** 2 lines

 
### Cancel-Operation

- **Location:** Line 1020
- **Size:** 15 lines

 
### Compress-GraphData

- **Location:** Line 258
- **Size:** 36 lines

 
### CompressGraphData

- **Location:** Line 118
- **Size:** 25 lines
- **Parameters:** graph
 
### CreatePartitionPlan

- **Location:** Line 1304
- **Size:** 33 lines
- **Parameters:** graph
 
### ExecuteJob

- **Location:** Line 597
- **Size:** 34 lines
- **Parameters:** job
 
### Export-PagedData

- **Location:** Line 482
- **Size:** 37 lines

 
### Export-ScalabilityMetrics

- **Location:** Line 1443
- **Size:** 49 lines

 
### Force-GarbageCollection

- **Location:** Line 1202
- **Size:** 24 lines

 
### Get-JobResults

- **Location:** Line 764
- **Size:** 25 lines

 
### Get-MemoryUsageReport

- **Location:** Line 1184
- **Size:** 16 lines

 
### Get-PaginatedResults

- **Location:** Line 405
- **Size:** 23 lines

 
### Get-ProgressReport

- **Location:** Line 969
- **Size:** 14 lines

 
### Get-PruningReport

- **Location:** Line 296
- **Size:** 17 lines

 
### Get-QueueStatus

- **Location:** Line 747
- **Size:** 15 lines

 
### GetMemoryUsageReport

- **Location:** Line 1105
- **Size:** 17 lines

 
### GetNextPage

- **Location:** Line 367
- **Size:** 5 lines

 
### GetPage

- **Location:** Line 336
- **Size:** 18 lines
- **Parameters:** pageNumber
 
### GetPageInfo

- **Location:** Line 356
- **Size:** 9 lines

 
### GetPreviousPage

- **Location:** Line 374
- **Size:** 5 lines

 
### GetProgressReport

- **Location:** Line 902
- **Size:** 12 lines

 
### GetQueueStatus

- **Location:** Line 650
- **Size:** 15 lines

 
### GraphPruner

- **Location:** Line 16
- **Size:** 11 lines
- **Parameters:** config
 
### HandleMemoryPressure

- **Location:** Line 1143
- **Size:** 4 lines

 
### Invoke-JobPriorityUpdate

- **Location:** Line 818
- **Size:** 26 lines

 
### IsCancellationRequested

- **Location:** Line 924
- **Size:** 2 lines

 
### MarkPreservedNodes

- **Location:** Line 67
- **Size:** 9 lines
- **Parameters:** graph, patterns
 
### MemoryManager

- **Location:** Line 1066
- **Size:** 10 lines
- **Parameters:** pressureThreshold
 
### Monitor-MemoryPressure

- **Location:** Line 1255
- **Size:** 28 lines

 
### Navigate-ResultPages

- **Location:** Line 455
- **Size:** 25 lines

 
### New-BackgroundJobQueue

- **Location:** Line 668
- **Size:** 14 lines

 
### New-CancellationToken

- **Location:** Line 985
- **Size:** 23 lines

 
### New-PaginationProvider

- **Location:** Line 382
- **Size:** 21 lines

 
### New-ProgressTracker

- **Location:** Line 929
- **Size:** 18 lines

 
### New-ScalingConfiguration

- **Location:** Line 1389
- **Size:** 23 lines

 
### Optimize-GraphStructure

- **Location:** Line 214
- **Size:** 42 lines

 
### Optimize-ObjectLifecycles

- **Location:** Line 1228
- **Size:** 25 lines

 
### OptimizeMemory

- **Location:** Line 1124
- **Size:** 17 lines

 
### PaginationProvider

- **Location:** Line 327
- **Size:** 7 lines
- **Parameters:** data, pageSize
 
### Prepare-DistributedMode

- **Location:** Line 1494
- **Size:** 47 lines

 
### ProcessJobs

- **Location:** Line 579
- **Size:** 16 lines

 
### ProgressTracker

- **Location:** Line 860
- **Size:** 13 lines
- **Parameters:** operationName, totalItems
 
### PruneGraph

- **Location:** Line 29
- **Size:** 36 lines
- **Parameters:** graph, preservePatterns
 
### Register-ProgressCallback

- **Location:** Line 1037
- **Size:** 18 lines

 
### RegisterCallback

- **Location:** Line 916
- **Size:** 2 lines
- **Parameters:** callback
 
### RegisterManagedObject

- **Location:** Line 1156
- **Size:** 3 lines
- **Parameters:** obj
 
### Remove-CompletedJobs

- **Location:** Line 791
- **Size:** 25 lines

 
### Remove-UnusedNodes

- **Location:** Line 182
- **Size:** 30 lines

 
### RemoveOrphanedEdges

- **Location:** Line 100
- **Size:** 16 lines
- **Parameters:** graph
 
### RemoveUnusedNodes

- **Location:** Line 78
- **Size:** 20 lines
- **Parameters:** graph
 
### ScalingConfiguration

- **Location:** Line 1296
- **Size:** 6 lines
- **Parameters:** config
 
### Set-PageSize

- **Location:** Line 430
- **Size:** 23 lines

 
### ShouldOptimize

- **Location:** Line 1149
- **Size:** 5 lines

 
### Start-GraphPruning

- **Location:** Line 153
- **Size:** 27 lines

 
### Start-MemoryOptimization

- **Location:** Line 1162
- **Size:** 20 lines

 
### Start-QueueProcessor

- **Location:** Line 713
- **Size:** 15 lines

 
### StartMonitoring

- **Location:** Line 1078
- **Size:** 12 lines

 
### StartProcessing

- **Location:** Line 563
- **Size:** 14 lines

 
### Stop-QueueProcessor

- **Location:** Line 730
- **Size:** 15 lines

 
### StopProcessing

- **Location:** Line 633
- **Size:** 15 lines

 
### Test-CancellationRequested

- **Location:** Line 1010
- **Size:** 8 lines

 
### Test-HorizontalReadiness

- **Location:** Line 1414
- **Size:** 27 lines

 
### Update-OperationProgress

- **Location:** Line 949
- **Size:** 18 lines

 
### UpdateMemoryStatistics

- **Location:** Line 1092
- **Size:** 11 lines

 
### UpdateProgress

- **Location:** Line 875
- **Size:** 25 lines
- **Parameters:** completedItems


---
*Generated on 2025-08-30 23:48:03*
