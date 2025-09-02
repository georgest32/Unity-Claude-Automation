# CrossLanguage-GraphMerger

**Type:** PowerShell Module  
**Path:** `Modules\Unity-Claude-CPG\Core\CrossLanguage-GraphMerger.psm1`  
**Size:** 39.26 KB  
**Last Modified:** 08/28/2025 12:05:31  

## Statistics

- **Total Functions:** 56
- **Total Lines:** 1184
- **Average Function Size:** 16.5 lines

## Functions


### AddNode

- **Location:** Line 28
- **Size:** 4 lines
- **Parameters:** node
 
### AddRelation

- **Location:** Line 34
- **Size:** 2 lines
- **Parameters:** relation
 
### AttemptConflictMerge

- **Location:** Line 707
- **Size:** 3 lines
- **Parameters:** conflict
 
### CalculateNodeSimilarity

- **Location:** Line 917
- **Size:** 7 lines
- **Parameters:** node1, node2
 
### CalculateNodeSimilarity

- **Location:** Line 420
- **Size:** 27 lines
- **Parameters:** node1, node2
 
### CalculateSignatureSimilarity

- **Location:** Line 485
- **Size:** 13 lines
- **Parameters:** node1, node2
 
### CalculateStringSimilarity

- **Location:** Line 449
- **Size:** 9 lines
- **Parameters:** str1, str2
 
### ConflictDetector

- **Location:** Line 799
- **Size:** 2 lines

 
### ConsolidateDuplicateRelationships

- **Location:** Line 751
- **Size:** 20 lines

 
### Create-MergedCPG

- **Location:** Line 1123
- **Size:** 35 lines

 
### CreateUnifiedNode

- **Location:** Line 401
- **Size:** 3 lines
- **Parameters:** originalNode, language
 
### Detect-Duplicates

- **Location:** Line 1067
- **Size:** 54 lines

 
### DetectDuplicateNodes

- **Location:** Line 888
- **Size:** 27 lines
- **Parameters:** languageGraphs
 
### DetectNamingConflicts

- **Location:** Line 803
- **Size:** 33 lines
- **Parameters:** languageGraphs
 
### DetectSignatureConflicts

- **Location:** Line 845
- **Size:** 5 lines
- **Parameters:** languageGraphs
 
### DetectTypeConflicts

- **Location:** Line 838
- **Size:** 5 lines
- **Parameters:** languageGraphs
 
### DuplicateDetector

- **Location:** Line 884
- **Size:** 2 lines
- **Parameters:** threshold
 
### ExtractNamespaces

- **Location:** Line 295
- **Size:** 12 lines
- **Parameters:** graph, language
 
### FindEquivalentNodes

- **Location:** Line 406
- **Size:** 12 lines
- **Parameters:** targetNode
 
### FlagForManualReview

- **Location:** Line 594
- **Size:** 16 lines
- **Parameters:** existingNode, newNode, confidence
 
### GetAllNodes

- **Location:** Line 38
- **Size:** 2 lines

 
### GetAllRelations

- **Location:** Line 42
- **Size:** 2 lines

 
### GetMergeReport

- **Location:** Line 784
- **Size:** 8 lines

 
### GraphMerger

- **Location:** Line 206
- **Size:** 16 lines
- **Parameters:** languageGraphs, strategy
 
### HandleNodeEquivalents

- **Location:** Line 500
- **Size:** 58 lines
- **Parameters:** newNode, equivalents, language
 
### HasDuplicateRelationship

- **Location:** Line 670
- **Size:** 9 lines
- **Parameters:** relationship
 
### InitializeStatistics

- **Location:** Line 224
- **Size:** 17 lines

 
### LanguageMapper

- **Location:** Line 139
- **Size:** 2 lines
- **Parameters:** language
 
### LevenshteinDistance

- **Location:** Line 460
- **Size:** 23 lines
- **Parameters:** s, t
 
### MapNamespace

- **Location:** Line 309
- **Size:** 20 lines
- **Parameters:** originalNamespace, language
 
### MapToUnified

- **Location:** Line 143
- **Size:** 25 lines
- **Parameters:** originalNode
 
### Merge-LanguageGraphs

- **Location:** Line 928
- **Size:** 53 lines

 
### Merge-Namespaces

- **Location:** Line 1048
- **Size:** 17 lines

 
### MergeAllNodes

- **Location:** Line 331
- **Size:** 25 lines

 
### MergeAllRelationships

- **Location:** Line 627
- **Size:** 16 lines

 
### MergeGraphs

- **Location:** Line 243
- **Size:** 32 lines

 
### MergeNamespaces

- **Location:** Line 863
- **Size:** 9 lines
- **Parameters:** languageGraphs
 
### MergeNode

- **Location:** Line 358
- **Size:** 41 lines
- **Parameters:** node, sourceLanguage
 
### MergeNodes

- **Location:** Line 560
- **Size:** 32 lines
- **Parameters:** existingNode, newNode
 
### MergeRelationship

- **Location:** Line 645
- **Size:** 23 lines
- **Parameters:** relationship, language
 
### NamespaceMerger

- **Location:** Line 858
- **Size:** 3 lines
- **Parameters:** strategy
 
### OptimizeMergedGraph

- **Location:** Line 712
- **Size:** 11 lines

 
### PrepareNamespaces

- **Location:** Line 277
- **Size:** 16 lines

 
### ProcessLanguageNamespaces

- **Location:** Line 874
- **Size:** 3 lines
- **Parameters:** language, graph
 
### RemoveNode

- **Location:** Line 46
- **Size:** 2 lines
- **Parameters:** nodeId
 
### RemoveOrphanedNodes

- **Location:** Line 725
- **Size:** 24 lines

 
### RemoveRelation

- **Location:** Line 50
- **Size:** 5 lines
- **Parameters:** relationId
 
### Resolve-NamingConflicts

- **Location:** Line 983
- **Size:** 63 lines

 
### ResolveByBestConfidence

- **Location:** Line 702
- **Size:** 3 lines
- **Parameters:** conflict
 
### ResolveConflicts

- **Location:** Line 681
- **Size:** 19 lines

 
### UnifiedCPG

- **Location:** Line 21
- **Size:** 5 lines
- **Parameters:** name
 
### UnifiedNode

- **Location:** Line 107
- **Size:** 6 lines
- **Parameters:** name, type, sourceLanguage
 
### UnifiedRelation

- **Location:** Line 125
- **Size:** 7 lines
- **Parameters:** type, sourceId, targetId, sourceLanguage
 
### UpdateConfidenceStats

- **Location:** Line 612
- **Size:** 13 lines
- **Parameters:** confidence
 
### UpdateGraphMetrics

- **Location:** Line 773
- **Size:** 9 lines

 
### Write-CPGDebug

- **Location:** Line 1161
- **Size:** 14 lines



---
*Generated on 2025-08-30 23:48:03*
