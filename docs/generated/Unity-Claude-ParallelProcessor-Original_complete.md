# Unity-Claude-ParallelProcessor-Original

**Type:** PowerShell Module  
**Path:** `Modules\Unity-Claude-ParallelProcessor\Unity-Claude-ParallelProcessor-Original.psm1`  
**Size:** 32.43 KB  
**Last Modified:** 08/26/2025 12:30:44  

## Statistics

- **Total Functions:** 35
- **Total Lines:** 923
- **Average Function Size:** 20.8 lines

## Functions


### AddItems

- **Location:** Line 650
- **Size:** 7 lines
- **Parameters:** items
 
### BatchProcessor

- **Location:** Line 538
- **Size:** 30 lines
- **Parameters:** batchSize, consumerCount, processingScript
 
### CalculateOptimalThreads

- **Location:** Line 98
- **Size:** 13 lines

 
### CancelAllJobs

- **Location:** Line 378
- **Size:** 8 lines

 
### CancelJob

- **Location:** Line 360
- **Size:** 15 lines
- **Parameters:** jobId
 
### CollectJobResult

- **Location:** Line 284
- **Size:** 45 lines
- **Parameters:** job
 
### CompleteAdding

- **Location:** Line 660
- **Size:** 3 lines

 
### CreateRunspacePool

- **Location:** Line 114
- **Size:** 28 lines

 
### Dispose

- **Location:** Line 725
- **Size:** 18 lines

 
### Dispose

- **Location:** Line 505
- **Size:** 18 lines

 
### Get-JobStatus

- **Location:** Line 866
- **Size:** 12 lines

 
### Get-ParallelProcessorStatistics

- **Location:** Line 855
- **Size:** 9 lines

 
### GetJobStatus

- **Location:** Line 488
- **Size:** 14 lines
- **Parameters:** jobId
 
### GetResults

- **Location:** Line 666
- **Size:** 20 lines
- **Parameters:** timeoutSeconds
 
### GetStatistics

- **Location:** Line 710
- **Size:** 3 lines

 
### GetStatistics

- **Location:** Line 468
- **Size:** 17 lines

 
### Initialize

- **Location:** Line 53
- **Size:** 42 lines
- **Parameters:** minThreads, maxThreads, initScript
 
### Invoke-ParallelProcessing

- **Location:** Line 782
- **Size:** 32 lines

 
### InvokeParallel

- **Location:** Line 407
- **Size:** 26 lines
- **Parameters:** InputObjects, ScriptBlock, ThrottleLimit
 
### New-ParallelProcessor

- **Location:** Line 748
- **Size:** 32 lines

 
### ParallelProcessor

- **Location:** Line 41
- **Size:** 2 lines

 
### ParallelProcessor

- **Location:** Line 45
- **Size:** 2 lines
- **Parameters:** minThreads, maxThreads
 
### ParallelProcessor

- **Location:** Line 49
- **Size:** 2 lines
- **Parameters:** minThreads, maxThreads, initScript
 
### RetryJob

- **Location:** Line 332
- **Size:** 25 lines
- **Parameters:** job
 
### Start

- **Location:** Line 571
- **Size:** 76 lines

 
### Start-BatchProcessing

- **Location:** Line 816
- **Size:** 37 lines

 
### StartProducerConsumer

- **Location:** Line 436
- **Size:** 29 lines
- **Parameters:** Producer, Consumer, ConsumerCount
 
### Stop

- **Location:** Line 716
- **Size:** 6 lines

 
### SubmitJob

- **Location:** Line 145
- **Size:** 47 lines
- **Parameters:** scriptBlock, parameters
 
### SubmitJobs

- **Location:** Line 195
- **Size:** 12 lines
- **Parameters:** scriptBlock, parameterSets
 
### UpdateExecutionStatistics

- **Location:** Line 389
- **Size:** 15 lines
- **Parameters:** executionTime
 
### UpdateStatistics

- **Location:** Line 700
- **Size:** 7 lines

 
### WaitForAllJobs

- **Location:** Line 240
- **Size:** 41 lines
- **Parameters:** timeoutSeconds
 
### WaitForCompletion

- **Location:** Line 689
- **Size:** 8 lines

 
### WaitForJob

- **Location:** Line 210
- **Size:** 27 lines
- **Parameters:** jobId, timeoutSeconds


---
*Generated on 2025-08-30 23:48:03*
