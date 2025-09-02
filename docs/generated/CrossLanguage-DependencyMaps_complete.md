# CrossLanguage-DependencyMaps

**Type:** PowerShell Module  
**Path:** `Modules\Unity-Claude-CPG\Core\CrossLanguage-DependencyMaps.psm1`  
**Size:** 46.43 KB  
**Last Modified:** 08/28/2025 11:34:01  

## Statistics

- **Total Functions:** 58
- **Total Lines:** 1344
- **Average Function Size:** 18.1 lines

## Functions


### AddNode

- **Location:** Line 102
- **Size:** 4 lines
- **Parameters:** node
 
### AddNode

- **Location:** Line 246
- **Size:** 4 lines
- **Parameters:** node
 
### AddReference

- **Location:** Line 252
- **Size:** 19 lines
- **Parameters:** reference
 
### AddRelation

- **Location:** Line 108
- **Size:** 2 lines
- **Parameters:** relation
 
### AnalyzeDependencyPatterns

- **Location:** Line 811
- **Size:** 22 lines

 
### BuildDependencyMatrix

- **Location:** Line 285
- **Size:** 21 lines

 
### BuildDependencyNodes

- **Location:** Line 425
- **Size:** 33 lines

 
### CalculateFunctionConfidence

- **Location:** Line 774
- **Size:** 23 lines
- **Parameters:** callNode, functionNode, sourceLang, targetLang
 
### CalculateGraphDensity

- **Location:** Line 308
- **Size:** 8 lines

 
### CalculateImportConfidence

- **Location:** Line 617
- **Size:** 18 lines
- **Parameters:** importNode, exportNode, sourceLang, targetLang
 
### CalculateStringSimilarity

- **Location:** Line 879
- **Size:** 9 lines
- **Parameters:** str1, str2
 
### CircularDependencyDetector

- **Location:** Line 921
- **Size:** 3 lines
- **Parameters:** graph
 
### CrossLanguageReference

- **Location:** Line 166
- **Size:** 10 lines
- **Parameters:** sourceLanguage, targetLanguage, sourceNode, targetNode, type
 
### CrossLanguageReferenceResolver

- **Location:** Line 360
- **Size:** 6 lines
- **Parameters:** languageGraphs
 
### DependencyGraph

- **Location:** Line 228
- **Size:** 16 lines
- **Parameters:** name
 
### DependencyNode

- **Location:** Line 194
- **Size:** 16 lines
- **Parameters:** id, name, language, type
 
### DependencyVisualizer

- **Location:** Line 1005
- **Size:** 9 lines
- **Parameters:** graph
 
### Detect-CircularDependencies

- **Location:** Line 1244
- **Size:** 23 lines

 
### DetectAllCycles

- **Location:** Line 926
- **Size:** 11 lines

 
### DetectCircularDependencies

- **Location:** Line 835
- **Size:** 17 lines

 
### DetectComplexCycles

- **Location:** Line 994
- **Size:** 3 lines

 
### DFSCycleDetection

- **Location:** Line 854
- **Size:** 23 lines
- **Parameters:** nodeId, visited, recursionStack, cycles
 
### Export-DependencyReport

- **Location:** Line 1269
- **Size:** 49 lines

 
### ExtractFunctionName

- **Location:** Line 744
- **Size:** 10 lines
- **Parameters:** callNode, language
 
### ExtractImportName

- **Location:** Line 552
- **Size:** 35 lines
- **Parameters:** importNode, language
 
### FindCallNodes

- **Location:** Line 701
- **Size:** 13 lines
- **Parameters:** graph, language
 
### FindImportNodes

- **Location:** Line 493
- **Size:** 27 lines
- **Parameters:** graph, language
 
### FindMatchingExports

- **Location:** Line 589
- **Size:** 26 lines
- **Parameters:** graph, language, importName
 
### FindMatchingFunctions

- **Location:** Line 756
- **Size:** 16 lines
- **Parameters:** graph, language, functionName
 
### Generate-DependencyGraph

- **Location:** Line 1213
- **Size:** 29 lines

 
### GenerateDotDiagram

- **Location:** Line 1067
- **Size:** 26 lines

 
### GenerateJsonGraph

- **Location:** Line 1095
- **Size:** 32 lines

 
### GenerateMermaidDiagram

- **Location:** Line 1027
- **Size:** 38 lines

 
### GenerateVisualization

- **Location:** Line 1016
- **Size:** 9 lines
- **Parameters:** format
 
### GetAllNodes

- **Location:** Line 112
- **Size:** 2 lines

 
### GetAllRelations

- **Location:** Line 116
- **Size:** 2 lines

 
### GetLanguageCompatibility

- **Location:** Line 637
- **Size:** 30 lines
- **Parameters:** lang1, lang2
 
### GetTopologicalOrdering

- **Location:** Line 318
- **Size:** 32 lines

 
### InitializeReferencePatterns

- **Location:** Line 368
- **Size:** 23 lines

 
### LevenshteinDistance

- **Location:** Line 890
- **Size:** 23 lines
- **Parameters:** s, t
 
### Resolve-CrossLanguageReferences

- **Location:** Line 1131
- **Size:** 33 lines

 
### ResolveAllReferences

- **Location:** Line 393
- **Size:** 30 lines

 
### ResolveDataFlowReferences

- **Location:** Line 805
- **Size:** 4 lines

 
### ResolveFunctionCallReferences

- **Location:** Line 669
- **Size:** 30 lines

 
### ResolveFunctionTarget

- **Location:** Line 716
- **Size:** 26 lines
- **Parameters:** callNode, sourceLanguage
 
### ResolveImportExportReferences

- **Location:** Line 460
- **Size:** 31 lines

 
### ResolveImportTarget

- **Location:** Line 522
- **Size:** 28 lines
- **Parameters:** importNode, sourceLanguage
 
### ResolveInheritanceReferences

- **Location:** Line 799
- **Size:** 4 lines

 
### StrongConnect

- **Location:** Line 953
- **Size:** 39 lines
- **Parameters:** nodeId, index, stack, indices, lowlinks, onStack
 
### TarjanSCC

- **Location:** Line 939
- **Size:** 12 lines

 
### ToString

- **Location:** Line 178
- **Size:** 2 lines

 
### Track-ImportExport

- **Location:** Line 1166
- **Size:** 45 lines

 
### UnifiedCPG

- **Location:** Line 95
- **Size:** 5 lines
- **Parameters:** name
 
### UnifiedNode

- **Location:** Line 60
- **Size:** 6 lines
- **Parameters:** name, type, sourceLanguage
 
### UnifiedRelation

- **Location:** Line 78
- **Size:** 7 lines
- **Parameters:** type, sourceId, targetId, sourceLanguage
 
### UpdateLanguageStats

- **Location:** Line 273
- **Size:** 10 lines
- **Parameters:** language
 
### UpdateMetrics

- **Location:** Line 212
- **Size:** 4 lines

 
### Write-CPGDebug

- **Location:** Line 1321
- **Size:** 14 lines



---
*Generated on 2025-08-30 23:48:03*
