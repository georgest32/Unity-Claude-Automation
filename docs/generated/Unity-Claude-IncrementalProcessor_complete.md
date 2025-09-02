# Unity-Claude-IncrementalProcessor

**Type:** PowerShell Module  
**Path:** `Modules\Unity-Claude-IncrementalProcessor\Unity-Claude-IncrementalProcessor.psm1`  
**Size:** 28.41 KB  
**Last Modified:** 08/25/2025 13:45:24  

## Statistics

- **Total Functions:** 34
- **Total Lines:** 813
- **Average Function Size:** 19 lines

## Functions


### Build-DependencyGraph

- **Location:** Line 745
- **Size:** 9 lines

 
### BuildDependencyGraph

- **Location:** Line 501
- **Size:** 13 lines

 
### CalculateASTDiff

- **Location:** Line 403
- **Size:** 35 lines
- **Parameters:** oldAst, newAst
 
### CalculateDiff

- **Location:** Line 356
- **Size:** 44 lines
- **Parameters:** oldSnapshot, newSnapshot
 
### CreateCheckpoint

- **Location:** Line 591
- **Size:** 9 lines

 
### CreateFileSnapshot

- **Location:** Line 133
- **Size:** 37 lines
- **Parameters:** filePath
 
### CreateInitialSnapshots

- **Location:** Line 111
- **Size:** 19 lines
- **Parameters:** path
 
### Dispose

- **Location:** Line 613
- **Size:** 14 lines

 
### ExtractDependencies

- **Location:** Line 517
- **Size:** 26 lines
- **Parameters:** snapshot
 
### Get-IncrementalProcessorStatistics

- **Location:** Line 695
- **Size:** 9 lines

 
### GetContentHash

- **Location:** Line 173
- **Size:** 5 lines
- **Parameters:** content
 
### GetDependentFiles

- **Location:** Line 492
- **Size:** 6 lines
- **Parameters:** filePath
 
### GetStatistics

- **Location:** Line 574
- **Size:** 14 lines

 
### HandleFileChange

- **Location:** Line 181
- **Size:** 22 lines
- **Parameters:** filePath, changeType
 
### IncrementalProcessor

- **Location:** Line 25
- **Size:** 29 lines
- **Parameters:** watchPath, cpgManager, cacheManager
 
### InvalidateCacheForFile

- **Location:** Line 546
- **Size:** 25 lines
- **Parameters:** filePath
 
### New-IncrementalProcessor

- **Location:** Line 632
- **Size:** 39 lines

 
### New-ProcessorCheckpoint

- **Location:** Line 706
- **Size:** 9 lines

 
### ProcessChangeQueue

- **Location:** Line 206
- **Size:** 46 lines

 
### ProcessFileChange

- **Location:** Line 255
- **Size:** 14 lines
- **Parameters:** change
 
### ProcessFileCreated

- **Location:** Line 272
- **Size:** 20 lines
- **Parameters:** filePath
 
### ProcessFileDeleted

- **Location:** Line 335
- **Size:** 18 lines
- **Parameters:** filePath
 
### ProcessFileModified

- **Location:** Line 295
- **Size:** 37 lines
- **Parameters:** filePath
 
### PropagateChanges

- **Location:** Line 471
- **Size:** 18 lines
- **Parameters:** filePath, diff
 
### Restore-ProcessorCheckpoint

- **Location:** Line 717
- **Size:** 12 lines

 
### RestoreCheckpoint

- **Location:** Line 603
- **Size:** 7 lines
- **Parameters:** checkpoint
 
### SetupFileWatcher

- **Location:** Line 57
- **Size:** 34 lines
- **Parameters:** path
 
### Start

- **Location:** Line 94
- **Size:** 7 lines

 
### Start-IncrementalProcessing

- **Location:** Line 673
- **Size:** 9 lines

 
### Start-ProcessChangeQueue

- **Location:** Line 756
- **Size:** 9 lines

 
### Stop

- **Location:** Line 104
- **Size:** 4 lines

 
### Stop-IncrementalProcessing

- **Location:** Line 684
- **Size:** 9 lines

 
### Update-CPGIncremental

- **Location:** Line 731
- **Size:** 12 lines

 
### UpdateCPGForFile

- **Location:** Line 441
- **Size:** 27 lines
- **Parameters:** filePath, snapshot, operation, diff


---
*Generated on 2025-08-30 23:48:03*
