# Unity-Claude Automation - Complete Code Documentation

**Generated:** 2025-08-30 23:48:02

## System Overview

- **Total Files:** 1064
- **Total Functions:** 6003
- **Total Lines of Code:** 487340

## Quick Statistics

| Category | Count | Functions | Lines of Code |
|----------|-------|-----------|---------------|
| Modules | 401 | 4347 | 253759 |
| Scripts | 663 | 1656 | 233581 |
| Manifests | 0 | 0 | 0 |

## Modules (401)

| Module | Functions | Size (KB) | Key Functions |
|--------|-----------|-----------|---------------|
| **ActionExecutionEngine** | 11 | 23.53 | `Write-ExecutionLog`, `Test-ActionSafety`, `Test-SafeFilePath` | | **AgentCore** | 6 | 9.11 | `Initialize-AgentCore`, `Get-AgentConfig`, `Set-AgentConfig` | | **AgentLogging** | 7 | 13.12 | `Write-AgentLog`, `Initialize-AgentLogging`, `Invoke-LogRotation` | | **AIAssessment** | 2 | 0.87 | `Parse-AIQualityResponse`, `Initialize-AIContentAssessor` | | **AnalysisLogging** | 4 | 5.72 | `Write-AnalysisLog`, `Set-AnalysisLogPath`, `Get-AnalysisLogPath` | | **AnalyticsReporting** | 9 | 24.71 | `Get-ROIAnalysis`, `Estimate-RefactoringEffort`, `Get-PriorityActions` | | **ApprovalRequests** | 5 | 10.46 | `New-ApprovalRequest`, `Get-ApprovalStatus`, `Set-ApprovalEscalation` | | **ASTAnalysis** | 4 | 10.33 | `Get-CodeAST`, `Find-CodePattern`, `Get-ASTStatistics` | | **AutoGenerationTriggers** | 11 | 25.08 | `Initialize-DocumentationTriggers`, `Start-FileWatcher`, `Stop-FileWatcher` | | **AutomationEngine** | 4 | 10.97 | `Start-DocumentationAutomation`, `Stop-DocumentationAutomation`, `Test-DocumentationSync` | | **AutonomousFeedbackLoop** | 5 | 12.19 | `Start-AutonomousFeedbackLoop`, `Stop-AutonomousFeedbackLoop`, `Get-FeedbackLoopStatus` | | **AutonomousOperations** | 4 | 34.64 | `New-AutonomousPrompt`, `Get-ActionResultSummary`, `Process-ResponseFile` | | **BackgroundJobQueue** | 15 | 11.85 | `BackgroundJobQueue`, `AddJob`, `StartProcessing` | | **BackupIntegration** | 8 | 30.36 | `New-DocumentationBackup`, `Restore-DocumentationBackup`, `Get-DocumentationHistory` | | **BatchProcessingEngine** | 13 | 22.88 | `BatchProcessingEngine`, `Start`, `AddItems` | | **BayesianConfidenceEngine** | 15 | 24.86 | `Calculate-OverallConfidence`, `Get-BayesianRecommendationConfidence`, `Get-BayesianConfidence` | | **BayesianInference** | 6 | 11.82 | `Invoke-BayesianConfidenceAdjustment`, `Get-BayesianPrior`, `Calculate-BayesianLikelihood` | | **CircuitBreaker** | 16 | 30.81 | `Write-CircuitBreakerLog`, `Get-CircuitBreaker`, `Test-CircuitBreakerState` | | **CircuitBreaker** | 8 | 11.48 | `Write-AnalysisLog`, `Test-CircuitBreakerState`, `Update-CircuitBreakerState` | | **Classification** | 8 | 28.04 | `Invoke-ResponseClassification`, `Invoke-DecisionTreeClassification`, `Test-NodeCondition` | | **ClaudeIntegration** | 4 | 12.77 | `Submit-PromptToClaude`, `New-FollowUpPrompt`, `Submit-ToClaude` | | **CLIAutomation** | 15 | 27.25 | `Write-CLILog`, `Test-ProcessExists`, `Get-ClaudeWindow` | | **CodeComplexityMetrics** | 11 | 19.43 | `Get-CodeComplexityMetrics`, `Get-FunctionComplexity`, `Get-ClassComplexity` | | **CodeRedundancyDetection** | 8 | 17.61 | `Test-CodeRedundancy`, `Find-DuplicateFunctions`, `Find-SimilarCodeBlocks` | | **CodeSmellPrediction** | 6 | 21.09 | `Predict-CodeSmells`, `Find-FeatureEnvy`, `Find-DataClumps` | | **CommandExecution** | 3 | 8.78 | `Invoke-SafeCommand`, `Test-ExecutionResult`, `Get-CommandExecutionStatistics` | | **CommandExecutionEngine** | 13 | 31.54 | `Add-CommandToQueue`, `Get-NextCommand`, `Get-QueueStatus` | | **CommandTypeHandlers** | 5 | 15.11 | `Invoke-UnityCommand`, `Invoke-TestCommand`, `Invoke-PowerShellCommand` | | **CompilationIntegration** | 3 | 11.59 | `Start-UnityCompilationJob`, `Find-UnityExecutablePath`, `Test-UnityCompilationResult` | | **ConfidenceBands** | 2 | 4.83 | `Get-ConfidenceBand`, `Calculate-PatternConfidence` | | **Configuration** | 5 | 12.68 | `Initialize-DocumentationDrift`, `Get-DocumentationDriftConfig`, `Set-DocumentationDriftConfig` | | **ConfigurationLogging** | 3 | 6.06 | `Get-DecisionEngineConfiguration`, `Set-DecisionEngineConfiguration`, `Write-DecisionLog` | | **ConfigurationManagement** | 9 | 10.66 | `Write-ModuleLog`, `Save-LearningConfiguration`, `Load-LearningConfiguration` | | **ConfigurationManagement** | 6 | 10.9 | `New-NotificationConfiguration`, `Import-NotificationConfiguration`, `Export-NotificationConfiguration` | | **ContentAnalysis** | 8 | 4.1 | `Assess-ContentCompleteness`, `Calculate-OverallQualityMetrics`, `Generate-ImprovementSuggestions` | | **ContextExtraction** | 6 | 25.92 | `Invoke-AdvancedContextExtraction`, `Get-ContextRelevanceScores`, `New-ContextItemsFromExtraction` | | **ContextManagement** | 5 | 7 | `New-NotificationContext`, `Add-NotificationContextData`, `Get-NotificationContext` | | **ContextOptimization** | 22 | 49.16 | `Write-ContextLog`, `Initialize-WorkingMemory`, `Add-ContextItem` | | **ConversationCore** | 1 | 4.18 | `Write-StateLog` | | **ConversationStateManager-Refactored** | 5 | 12.5 | `Get-ConversationStateManagerComponents`, `Test-ConversationStateManagerHealth`, `Invoke-ConversationStateManagerDiagnostics` | | **ConversationStateManager** | 22 | 46.97 | `Write-StateLog`, `Initialize-ConversationState`, `Set-ConversationState` | | **CoreUtilities** | 6 | 13.24 | `ConvertTo-HashTable`, `Get-SafeDateTime`, `Get-UptimeMinutes` | | **CPG-AdvancedEdges** | 30 | 25.39 | `DataFlowEdge`, `AddTransformation`, `AnalyzeFlow` | | **CPG-AnalysisOperations** | 5 | 9.03 | `Get-CPGStatistics`, `Test-CPGStronglyConnected`, `Get-CPGComplexityMetrics` | | **CPG-BasicOperations** | 5 | 6.78 | `New-CPGNode`, `New-CPGEdge`, `New-CPGraph` | | **CPG-CallGraphBuilder** | 16 | 24.92 | `Write-CPGDebug`, `CallNode`, `GetSignature` | | **CPG-DataFlowTracker** | 22 | 31.56 | `Write-CPGDebug`, `VariableDefinition`, `VariableUse` | | **CPG-DataStructures** | 13 | 8.78 | `CPGNode`, `CPGNode`, `ToString` | | **CPG-QueryOperations** | 4 | 11.65 | `Get-CPGNode`, `Get-CPGEdge`, `Get-CPGNeighbors` | | **CPG-SerializationOperations** | 4 | 10.24 | `Export-CPGraph`, `Import-CPGraph`, `Export-ToGraphML` | | **CPG-ThreadSafeOperations** | 12 | 25.68 | `Write-CPGLog`, `New-ThreadSafeCPG`, `Add-CPGNodeThreadSafe` | | **CPG-Unified** | 41 | 26.53 | `Write-CPGDebug`, `CPGNode`, `CPGNode` | | **CrossLanguage-DependencyMaps** | 58 | 46.43 | `UnifiedNode`, `UnifiedRelation`, `UnifiedCPG` | | **CrossLanguage-GraphMerger** | 56 | 39.26 | `UnifiedCPG`, `AddNode`, `AddRelation` | | **CrossLanguage-UnifiedModel** | 31 | 28.62 | `UnifiedNode`, `UnifiedNode`, `GetDisplayName` | | **DatabaseManagement** | 2 | 8.13 | `Initialize-ApprovalDatabase`, `Test-DatabaseConnection` | | **DatabaseManagement** | 1 | 7.55 | `Initialize-LearningDatabase` | | **DecisionEngine-Bayesian** | 20 | 45.26 | `Invoke-BayesianConfidenceAdjustment`, `Get-BayesianPrior`, `Calculate-BayesianLikelihood` | | **DecisionEngine-Refactored** | 4 | 13.89 | `Initialize-DecisionEngine`, `Test-DecisionEngineHealth`, `Get-DecisionEngineStatistics` | | **DecisionEngine** | 11 | 33.98 | `Write-DecisionLog`, `Invoke-RuleBasedDecision`, `Resolve-PriorityDecision` | | **DecisionEngineCore** | 7 | 6.91 | `Write-DecisionEngineLog`, `Test-RequiredModule`, `Get-DecisionEngineConfig` | | **DecisionEngineIntegration** | 12 | 23.33 | `Write-IntegrationLog`, `Invoke-IntegratedDecision`, `Get-CircuitBreakerName` | | **DecisionExecution-Fixed** | 2 | 4.86 | `Invoke-DecisionExecution`, `Execute-TestAction` | | **DecisionExecution** | 12 | 12.2 | `Invoke-DecisionExecution`, `Invoke-SafetyValidation`, `Invoke-RecommendationExecution` | | **DecisionExecution** | 6 | 10.67 | `Invoke-DecisionExecution`, `Execute-TestAction`, `Execute-ValidationAction` | | **DecisionMaking-Fixed** | 3 | 7.61 | `Invoke-ComprehensiveResponseAnalysis`, `Invoke-AutonomousDecisionMaking`, `Test-DecisionSafety` | | **DecisionMaking** | 4 | 14.17 | `Invoke-AutonomousDecision`, `Invoke-DecisionTree`, `Apply-ContextualAdjustments` | | **DecisionMaking** | 3 | 9.43 | `Invoke-ComprehensiveResponseAnalysis`, `Invoke-AutonomousDecisionMaking`, `Test-DecisionSafety` | | **DepaAlgorithm** | 3 | 13.6 | `Get-CodePerplexity`, `Get-LinePerplexity`, `Test-DeadProgramArtifacts` | | **DependencyManagement** | 5 | 7.8 | `Test-ModuleDependencyAvailability`, `Initialize-RequiredModules`, `Test-ModuleDependencies` | | **DocumentationAccuracy** | 10 | 25.41 | `Test-DocumentationAccuracy`, `Update-DocumentationSuggestions`, `Test-ParameterAccuracy` | | **DocumentationComparison** | 6 | 22.14 | `Compare-CodeToDocumentation`, `Find-UndocumentedFeatures`, `Get-NodeDocumentation` | | **EnhancedPatternIntegration** | 1 | 7.34 | `Invoke-EnhancedPatternAnalysis` | | **EntityContextEngine** | 14 | 24.74 | `Extract-ContextEntities`, `Get-TextSpans`, `Split-TextIntoSentences` | | **EntityRelationshipManagement** | 3 | 9.27 | `Build-EntityRelationshipGraph`, `Find-EntityCluster`, `Measure-EntityProximity` | | **ErrorDetection** | 6 | 28.25 | `Start-ConcurrentErrorDetection`, `Classify-UnityCompilationError`, `Aggregate-UnityErrors` | | **ErrorExport** | 3 | 16.9 | `Export-UnityErrorsConcurrently`, `Format-UnityErrorsForClaude`, `Test-UnityParallelizationPerformance` | | **ErrorHandling** | 11 | 22.55 | `Invoke-ExponentialBackoffRetry`, `Get-ExponentialBackoffDelay`, `Test-ErrorRetryability` | | **EscalationProtocol** | 16 | 37.63 | `Write-EscalationLog`, `New-Escalation`, `Invoke-EscalationIncrease` | | **EventProcessing** | 11 | 15.59 | `Start-EventDrivenProcessing`, `Register-ResponseMonitorEvents`, `Register-DecisionEngineEvents` | | **FailureMode** | 12 | 20.87 | `Test-EscalationTriggers`, `Invoke-HumanEscalation`, `Enable-SafeMode` | | **FallbackMechanisms** | 7 | 8.83 | `New-NotificationFallbackChain`, `Invoke-NotificationFallback`, `Test-NotificationFallback` | | **FallbackStrategies** | 4 | 9.11 | `Resolve-ConflictingRecommendations`, `Invoke-GracefulDegradation`, `Get-ConflictAnalysis` | | **FileProcessing** | 9 | 9.6 | `Invoke-FileProcessing`, `Invoke-FileTypeProcessing`, `Invoke-PowerShellFileProcessing` | | **FileSystemMonitoring** | 4 | 20.74 | `Start-ClaudeResponseMonitoring`, `Stop-ClaudeResponseMonitoring`, `Get-MonitoringStatus` | | **FileSystemMonitoring** | 8 | 7.67 | `Initialize-FileSystemWatcher`, `Register-FileChangeHandler`, `Start-FileSystemMonitoring` | | **GitHubPRManager** | 5 | 14.91 | `New-DocumentationPR`, `Update-DocumentationPR`, `Get-DocumentationPRs` | | **GoalManagement** | 8 | 15.85 | `Add-ConversationGoal`, `Update-ConversationGoal`, `Get-ConversationGoals` | | **GraphOptimizer** | 12 | 12.18 | `GraphPruner`, `PruneGraph`, `MarkPreservedNodes` | | **GraphTraversal** | 1 | 10.32 | `Find-UnreachableCode` | | **HealthMonitoring** | 4 | 10.12 | `Start-EnhancedHealthMonitoring`, `Stop-EnhancedHealthMonitoring`, `Get-HealthMonitoringStatus` | | **HistoryManagement** | 6 | 14.05 | `Add-ConversationHistoryItem`, `Get-ConversationHistory`, `Get-ConversationContext` | | **HITLCore** | 2 | 5.03 | `Set-HITLConfiguration`, `Get-HITLConfiguration` | | **HorizontalScaling** | 7 | 10.83 | `ScalingConfiguration`, `CreatePartitionPlan`, `AssessScalabilityReadiness` | | **HumanIntervention** | 6 | 13.89 | `Request-HumanIntervention`, `Approve-AgentIntervention`, `Deny-AgentIntervention` | | **ImpactAnalysis** | 7 | 14.86 | `Analyze-ChangeImpact`, `Analyze-NewFileImpact`, `Analyze-DeletedFileImpact` | | **ImprovementRoadmaps** | 12 | 36.86 | `New-ImprovementRoadmap`, `Create-CriticalPhase`, `Create-HighImpactPhase` | | **IntegratedNotifications** | 3 | 11.62 | `Send-IntegratedNotification`, `Test-IntegratedNotification`, `Validate-CrossModuleMessage` | | **IntegrationManagement** | 6 | 13.75 | `Connect-IntelligentPromptEngine`, `Connect-ConversationManager`, `Get-DecisionEngineStatus` | | **IntelligentPromptEngine-Refactored** | 5 | 17.39 | `Invoke-IntelligentPromptGeneration`, `New-FallbackPrompt`, `Get-PromptEngineStatus` | | **IntelligentPromptEngine** | 5 | 17.39 | `Invoke-IntelligentPromptGeneration`, `New-FallbackPrompt`, `Get-PromptEngineStatus` | | **JobScheduler** | 17 | 19.46 | `ParallelJob`, `GetDuration`, `GetSummary` | | **JsonProcessing** | 10 | 19.5 | `Write-AnalysisLog`, `Test-JsonTruncation`, `Repair-TruncatedJson` | | **LearningAdaptation** | 3 | 7.47 | `Update-BayesianLearning`, `Save-BayesianLearning`, `Initialize-BayesianLearning` | | **LearningCore** | 9 | 8.16 | `Write-LearningLog`, `Get-LearningConfig`, `Set-LearningConfig` | | **Legacy-Compatibility** | 9 | 28.16 | `Enable-LegacyMode`, `Disable-LegacyMode`, `Test-LegacyMode` | | **LLM-PromptTemplates** | 15 | 13.57 | `Get-FunctionDocumentationTemplate`, `Get-ModuleDocumentationTemplate`, `Get-ClassDocumentationTemplate` | | **LLM-ResponseCache** | 14 | 13.88 | `Get-CacheKey`, `Get-CachedResponse`, `Set-CachedResponse` | | **MaintenancePrediction** | 2 | 13.96 | `Get-MaintenancePrediction`, `Calculate-TechnicalDebt` | | **MemoryManager** | 13 | 9 | `MemoryManager`, `StartMonitoring`, `UpdateMemoryStatistics` | | **MetricsAndHealthCheck** | 13 | 20.09 | `Get-NotificationMetrics`, `Get-NotificationHealthCheck`, `New-NotificationReport` | | **MetricsCollection** | 11 | 15.74 | `Write-ModuleLog`, `Start-PerformanceTimer`, `Stop-PerformanceTimer` | | **ModuleFunctions** | 24 | 19.46 | `ParallelProcessor`, `ParallelProcessor`, `ParallelProcessor` | | **ModuleIntegration** | 4 | 13.68 | `Test-ModuleAvailability`, `Initialize-ModuleIntegration`, `Initialize-SingleModule` | | **ModuleVariablePreloading** | 7 | 11.65 | `Write-ModuleLog`, `Add-SessionStateVariable`, `Add-SessionStateModule` | | **MonitoringLoop** | 3 | 15.08 | `Start-MonitoringLoop`, `Invoke-SingleExecutionCycle`, `Process-SignalFile` | | **NotificationCore** | 6 | 16.34 | `Initialize-NotificationIntegration`, `Register-NotificationHook`, `Unregister-NotificationHook` | | **NotificationSystem** | 4 | 12.66 | `Send-ApprovalNotification`, `Build-ApprovalEmailTemplate`, `Send-ApprovalReminder` | | **OptimizerConfiguration** | 6 | 7.06 | `Initialize-PerformanceMetrics`, `Get-OptimalThreadCount`, `Get-FilePriority` | | **OrchestrationCore** | 3 | 9.09 | `Start-CLIOrchestration`, `Get-CLIOrchestrationStatus`, `Initialize-OrchestrationEnvironment` | | **OrchestrationManager** | 1 | 52.72 | `Start-CLIOrchestration` | | **OrchestratorCore** | 5 | 7.61 | `Write-OrchestratorLog`, `Get-OrchestratorConfig`, `Set-OrchestratorConfig` | | **OrchestratorManagement** | 6 | 16.16 | `Get-OrchestratorStatus`, `Test-OrchestratorIntegration`, `Get-OperationHistory` | | **PaginationProvider** | 10 | 8.05 | `PaginationProvider`, `GetPage`, `GetPageInfo` | | **ParallelizationCore** | 6 | 9.75 | `Test-ModuleDependencyAvailability`, `Initialize-ModuleDependencies`, `Write-FallbackLog` | | **ParallelMonitoring** | 4 | 26.79 | `New-UnityParallelMonitor`, `Start-UnityParallelMonitoring`, `Stop-UnityParallelMonitoring` | | **ParallelProcessorCore** | 11 | 10.13 | `Write-ParallelProcessorLog`, `Set-ParallelProcessorDebugMode`, `Get-OptimalThreadCount` | | **PatternAnalysis** | 3 | 8.57 | `Build-NGramModel`, `Calculate-PatternSimilarity`, `Get-LevenshteinDistance` | | **PatternRecognition** | 5 | 15.02 | `Add-ErrorPattern`, `Add-ErrorPatternSQLite`, `Find-SimilarPatterns` | | **PatternRecognitionEngine-Fixed** | 4 | 8.86 | `Write-PatternLog`, `Invoke-PatternRecognitionAnalysis`, `Get-CachedPattern` | | **PatternRecognitionEngine-New** | 4 | 11.06 | `Write-PatternLog`, `Invoke-PatternRecognitionAnalysis`, `Test-PatternRecognitionPerformance` | | **PatternRecognitionEngine-Original** | 33 | 89.32 | `Initialize-CompiledPatterns`, `Test-PatternValidation`, `Get-EnhancedPatternMatch` | | **PatternRecognitionEngine** | 4 | 11.03 | `Write-PatternLog`, `Invoke-PatternRecognitionAnalysis`, `Test-PatternRecognitionPerformance` | | **Performance-Cache** | 32 | 20.32 | `CacheItem`, `IsExpired`, `UpdateAccess` | | **Performance-IncrementalUpdates** | 23 | 27.26 | `FileChangeInfo`, `HasChanged`, `ComputeHash` | | **PerformanceAnalysis** | 2 | 15.12 | `Get-WorkflowPerformanceAnalysis`, `Get-OptimizationRecommendations` | | **PerformanceMonitoring** | 6 | 9.89 | `Update-PerformanceMetrics`, `Get-PerformanceBottlenecks`, `New-PerformanceTimer` | | **PerformanceOptimization** | 8 | 9.84 | `Optimize-Performance`, `Optimize-BatchSize`, `Optimize-CacheSettings` | | **PerformanceOptimization** | 4 | 20.68 | `Initialize-AdaptiveThrottling`, `Update-AdaptiveThrottling`, `New-IntelligentJobBatching` | | **PerformanceOptimizer** | 14 | 26.96 | `Get-CacheKey`, `Get-StringHash`, `Get-CachedResult` | | **PersistenceManagement** | 8 | 19.12 | `Save-ConversationState`, `Save-ConversationHistory`, `Save-ConversationGoals` | | **Predictive-Evolution** | 19 | 48.78 | `GitCommitInfo`, `CodeChurnMetrics`, `Get-GitCommitHistory` | | **Predictive-Maintenance** | 43 | 86.99 | `Get-SafeChildItems`, `TechnicalDebtItem`, `MaintenancePrediction` | | **PredictiveCore** | 7 | 9.52 | `Initialize-PredictiveCache`, `Get-PredictiveConfig`, `Set-PredictiveConfig` | | **PriorityActionQueue** | 5 | 9.74 | `Test-ActionQueueCapacity`, `New-ActionQueueItem`, `Get-ActionQueueStatus` | | **ProductionRunspacePool** | 8 | 24.32 | `Write-ModuleLog`, `Update-RunspacePoolRegistry`, `Test-RunspacePoolResources` | | **ProgressTracker** | 13 | 8.87 | `ProgressTracker`, `UpdateProgress`, `GetProgressReport` | | **ProjectConfiguration** | 6 | 15.66 | `Find-UnityProjects`, `Register-UnityProject`, `Get-UnityProjectConfiguration` | | **PromptConfiguration** | 1 | 4.4 | `Get-PromptEngineConfig` | | **PromptSubmissionEngine** | 2 | 14.55 | `Submit-ToClaudeViaTypeKeys`, `Execute-TestScript` | | **PromptTemplateSystem** | 7 | 18.22 | `New-PromptTemplate`, `New-DebuggingPromptTemplate`, `New-TestResultsPromptTemplate` | | **PromptTypeSelection** | 4 | 19.73 | `Invoke-PromptTypeSelection`, `New-PromptTypeDecisionTree`, `Invoke-DecisionTreeAnalysis` | | **PSGraph** | 23 | 48.11 | `ConvertTo-GraphVizAttribute`, `Format-KeyName`, `Format-Value` | | **QueueManagement** | 6 | 11.95 | `Initialize-NotificationQueue`, `Add-NotificationToQueue`, `Process-NotificationQueue` | | **ReadabilityAlgorithms** | 8 | 14.1 | `Calculate-ComprehensiveReadabilityScores`, `Analyze-TextStatistics`, `Estimate-SyllableCount` | | **RecommendationPatternEngine** | 2 | 11.93 | `Initialize-CompiledPatterns`, `Find-RecommendationPatterns` | | **RefactoringDetection** | 6 | 23.67 | `Find-RefactoringOpportunities`, `Find-LongMethods`, `Find-GodClasses` | | **ReportingExport** | 6 | 12.62 | `Export-PerformanceData`, `Export-ToJson`, `Export-ToCsv` | | **ResponseAnalysis** | 12 | 17.63 | `Invoke-HybridResponseAnalysis`, `Invoke-RegexBasedAnalysis`, `Invoke-AIEnhancedAnalysis` | | **ResponseAnalysisEngine-Broken** | 39 | 92.6 | `Write-AnalysisLog`, `Test-CircuitBreakerState`, `Update-CircuitBreakerState` | | **ResponseAnalysisEngine-Core-Fixed** | 4 | 13.52 | `Analyze-ResponseSentiment`, `Extract-ResponseEntities`, `Get-ResponseContext` | | **ResponseAnalysisEngine-Core** | 6 | 22.47 | `Analyze-ResponseSentiment`, `Invoke-EnhancedResponseAnalysis`, `Initialize-ResponseAnalysisEngine` | | **ResponseAnalysisEngine-Enhanced** | 12 | 28.2 | `Calculate-PatternConfidence`, `Get-ConfidenceBand`, `Invoke-BayesianConfidenceAdjustment` | | **ResponseAnalysisEngine** | 12 | 28.2 | `Calculate-PatternConfidence`, `Get-ConfidenceBand`, `Invoke-BayesianConfidenceAdjustment` | | **ResponseClassificationEngine** | 12 | 25.17 | `Get-EnhancedFeatureEngineering`, `Test-FeaturePattern`, `Classify-ResponseType` | | **ResponseMonitoring** | 5 | 15.06 | `Invoke-ProcessClaudeResponse`, `Find-ClaudeRecommendations`, `Add-RecommendationToQueue` | | **ResponseParsing** | 6 | 26.9 | `Invoke-EnhancedResponseParsing`, `Get-ResponseQualityScore`, `Extract-CommandsFromResponse` | | **ResultAnalysisEngine** | 6 | 26.47 | `Invoke-CommandResultAnalysis`, `Get-ResultClassification`, `Get-ResultSeverity` | | **RetryLogic** | 6 | 8.88 | `New-NotificationRetryPolicy`, `Invoke-NotificationWithRetry`, `Test-NotificationDelivery` | | **RiskAssessment** | 18 | 41.07 | `Predict-BugProbability`, `Get-BugPreventionActions`, `Get-MaintenanceRisk` | | **RoleAwareManagement** | 9 | 18.58 | `Add-RoleAwareHistoryItem`, `Get-RoleAwareHistory`, `Update-DialoguePatterns` | | **RuleBasedDecisionTrees** | 2 | 11.64 | `Invoke-RuleBasedDecision`, `Resolve-PriorityDecision` | | **RunspaceCore** | 8 | 6.92 | `Test-ModuleDependencyAvailability`, `Write-FallbackLog`, `Write-ModuleLog` | | **RunspaceManagement** | 3 | 7.01 | `New-ConstrainedRunspace`, `Remove-ConstrainedRunspace`, `Test-RunspaceHealth` | | **RunspacePoolManagement** | 9 | 14.72 | `Write-ModuleLog`, `Update-RunspacePoolRegistry`, `Get-RunspacePoolRegistry` | | **RunspacePoolManager** | 11 | 15.02 | `RunspacePoolManager`, `CreateInitialSessionState`, `CreateRunspacePool` | | **Safe-FileEnumeration** | 1 | 1.89 | `Get-SafeChildItems` | | **SafeCommandCore** | 4 | 7.33 | `Write-SafeLog`, `Get-SafeCommandConfig`, `Set-SafeCommandConfig` | | **SafeCommandExecution-Original** | 30 | 99.06 | `Write-SafeLog`, `New-ConstrainedRunspace`, `Test-CommandSafety` | | **SafeCommandExecution-Refactored** | 3 | 12.93 | `Initialize-SafeCommandExecution`, `Get-SafeCommandStatus`, `Test-SafeCommandIntegration` | | **SafeCommandExecution** | 3 | 12.93 | `Initialize-SafeCommandExecution`, `Get-SafeCommandStatus`, `Test-SafeCommandIntegration` | | **SafeExecution** | 7 | 22.26 | `New-ConstrainedRunspace`, `Test-CommandSafety`, `Test-ParameterSafety` | | **SafetyValidationFramework** | 3 | 12.53 | `Test-SafetyValidation`, `Test-SafeFilePath`, `Test-SafeCommand` | | **SecurityTokens** | 4 | 7.49 | `New-ApprovalToken`, `Test-ApprovalToken`, `Get-TokenMetadata` | | **SelfPatching** | 8 | 14.37 | `Write-ModuleLog`, `Apply-AutoFix`, `Apply-FixToFile` | | **SemanticAnalysis-Metrics** | 9 | 30.17 | `Get-CHMCohesionAtMessageLevel`, `Get-CHDCohesionAtDomainLevel`, `Get-CBOCouplingBetweenObjects` | | **SemanticAnalysis-PatternDetector-PS51Compatible** | 9 | 12.42 | `New-PatternSignature`, `New-PatternMatch`, `Get-SingletonPatternSignature` | | **SemanticAnalysis-PatternDetector** | 17 | 24.85 | `PatternSignature`, `PatternMatch`, `Get-SingletonPattern` | | **SessionStateConfiguration** | 7 | 14.79 | `Write-ModuleLog`, `Update-SessionStateRegistry`, `New-RunspaceSessionState` | | **StateConfiguration** | 4 | 11.35 | `Get-EnhancedStateConfig`, `Initialize-StateDirectories`, `Get-EnhancedAutonomousStates` | | **StateMachineCore** | 5 | 14.54 | `Initialize-EnhancedAutonomousStateTracking`, `Set-EnhancedAutonomousState`, `Get-EnhancedAutonomousState` | | **StateManagement** | 6 | 13.66 | `Initialize-ConversationState`, `Set-ConversationState`, `Get-ConversationState` | | **StatePersistence** | 5 | 11.54 | `New-StateCheckpoint`, `Restore-AgentStateFromCheckpoint`, `Get-CheckpointHistory` | | **StatisticsTracker** | 17 | 17.12 | `StatisticsTracker`, `RecordJobSubmission`, `RecordJobCompletion` | | **StringSimilarity** | 8 | 12.95 | `Get-StringSimilarity`, `Get-LevenshteinDistance`, `Get-LevenshteinSimilarity` | | **SuccessTracking** | 9 | 12.36 | `Write-ModuleLog`, `Update-SuccessMetrics`, `Get-SuccessMetrics` | | **SystemIntegration** | 6 | 9.2 | `Initialize-DocumentationQualityAssessment`, `Get-DefaultQualityAssessmentConfiguration`, `Discover-QualityAssessmentSystems` | | **Templates-PerLanguage** | 7 | 12.74 | `Get-PowerShellDocTemplate`, `Get-PythonDocTemplate`, `Get-CSharpDocTemplate` | | **TemplateSystem** | 6 | 16.47 | `New-DocumentationTemplate`, `Get-DocumentationTemplates`, `Update-DocumentationTemplate` | | **TemporalContextTracking** | 2 | 7.29 | `Add-TemporalContext`, `Get-TemporalContextRelevance` | | **Test-HealthUtilities** | 8 | 12.25 | `Initialize-HealthCheck`, `Write-TestLog`, `Add-TestResult` | | **Test-Minimal-Queue** | 1 | 0.32 | `Test-NewConcurrentQueue` | | **Test-Minimal-Queue** | 1 | 0.32 | `Test-NewConcurrentQueue` | | **TestModule1** | 2 | 0.31 | `Test-Function1`, `Test-Function2` | | **TestModule2** | 2 | 0.32 | `Test-Function3`, `Test-Function4` | | **ThrottlingResourceControl** | 5 | 16.31 | `Write-ModuleLog`, `Test-RunspacePoolResources`, `Set-AdaptiveThrottling` | | **TreeSitter-CSTConverter** | 24 | 23.98 | `CSTNode`, `CSTNode`, `ConvertToCPGNode` | | **TrendAnalysis** | 3 | 13.62 | `Get-CodeEvolutionTrend`, `Measure-CodeChurn`, `Get-HotspotAnalysis` | | **TriggerSystem** | 10 | 23.28 | `Register-DocumentationTrigger`, `Unregister-DocumentationTrigger`, `Get-DocumentationTriggers` | | **Unity-Claude-AgentIntegration** | 7 | 16.16 | `Initialize-AgentMessageSystem`, `Register-DefaultHandlers`, `Initialize-SupervisorOrchestration` | | **Unity-Claude-AI-Performance-Monitor** | 8 | 38.33 | `Start-PerformanceBottleneckAnalysis`, `Start-AIWorkflowMonitoring`, `Stop-AIWorkflowMonitoring` | | **Unity-Claude-AIAlertClassifier** | 19 | 32.8 | `Initialize-AIAlertClassifier`, `Test-AIConnection`, `Initialize-ClassificationEngine` | | **Unity-Claude-AlertAnalytics** | 22 | 33.31 | `Initialize-AlertAnalytics`, `Get-DefaultAnalyticsConfiguration`, `Load-TimeSeriesDatabase` | | **Unity-Claude-AlertFeedbackCollector** | 17 | 36.27 | `Initialize-AlertFeedbackCollector`, `Get-DefaultFeedbackConfiguration`, `Load-FeedbackDatabase` | | **Unity-Claude-AlertMLOptimizer** | 27 | 34.34 | `Initialize-AlertMLOptimizer`, `Initialize-PythonEnvironment`, `Get-DefaultMLOptimizerConfiguration` | | **Unity-Claude-AlertQualityReporting** | 40 | 36.02 | `Initialize-AlertQualityReporting`, `Get-DefaultQualityReportingConfiguration`, `Generate-QualityReport` | | **Unity-Claude-APIDocumentation** | 10 | 28.41 | `Write-DocLog`, `Install-PlatyPS`, `Initialize-DocumentationProject` | | **Unity-Claude-AST-Enhanced** | 15 | 23.43 | `Get-ModuleCallGraph`, `Get-CrossModuleRelationships`, `Get-FunctionCallAnalysis` | | **Unity-Claude-AutoGen** | 13 | 48.23 | `New-AutoGenAgent`, `Get-AutoGenAgent`, `New-AutoGenTeam` | | **Unity-Claude-AutoGenMonitoring** | 4 | 15.56 | `Start-AutoGenActivityMonitoring`, `Get-AutoGenPerformanceMetrics`, `Invoke-AgentPerformanceOptimization` | | **Unity-Claude-AutonomousAgent-ORIGINAL** | 33 | 90.13 | `Write-AgentLog`, `Initialize-AgentLogging`, `Start-ClaudeResponseMonitoring` | | **Unity-Claude-AutonomousAgent-Refactored** | 1 | 8.77 | `Get-ModuleStatus` | | **Unity-Claude-AutonomousDocumentationEngine** | 29 | 55.81 | `Initialize-AutonomousDocumentationEngine`, `Get-DefaultAutonomousDocConfiguration`, `Discover-DocumentationSystems` | | **Unity-Claude-AutonomousMonitoring** | 7 | 32.74 | `Update-ClaudeWindowInfo`, `Find-ClaudeWindow`, `Switch-ToWindow` | | **Unity-Claude-AutonomousMonitoring** | 7 | 32.74 | `Update-ClaudeWindowInfo`, `Find-ClaudeWindow`, `Switch-ToWindow` | | **Unity-Claude-AutonomousMonitoring** | 7 | 32.74 | `Update-ClaudeWindowInfo`, `Find-ClaudeWindow`, `Switch-ToWindow` | | **Unity-Claude-AutonomousStateTracker-Enhanced-Refactored** | 3 | 21.74 | `Get-AutonomousStateTrackerComponents`, `Test-AutonomousStateTrackerHealth`, `Invoke-ComprehensiveAutonomousAnalysis` | | **Unity-Claude-AutonomousStateTracker-Enhanced** | 19 | 56.6 | `ConvertTo-HashTable`, `Get-SafeDateTime`, `Get-UptimeMinutes` | | **Unity-Claude-AutonomousStateTracker-Enhanced** | 3 | 21.74 | `Get-AutonomousStateTrackerComponents`, `Test-AutonomousStateTrackerHealth`, `Invoke-ComprehensiveAutonomousAnalysis` | | **Unity-Claude-AutonomousStateTracker** | 18 | 30.86 | `Write-StateTrackerLog`, `Get-StateTimestamp`, `New-StateTrackingId` | | **Unity-Claude-Cache-Fixed** | 32 | 25.39 | `CacheManager`, `CacheManager`, `CacheManager` | | **Unity-Claude-Cache-Original** | 31 | 25.15 | `CacheManager`, `CacheManager`, `CacheManager` | | **Unity-Claude-Cache** | 32 | 25.32 | `CacheManager`, `CacheManager`, `CacheManager` | | **Unity-Claude-ChangeIntelligence** | 13 | 20.69 | `Initialize-ChangeIntelligence`, `Initialize-ClassificationRules`, `Get-ChangeClassification` | | **Unity-Claude-ClaudeParallelization** | 11 | 53.27 | `Test-ModuleDependencyAvailability`, `Write-FallbackLog`, `Write-ClaudeParallelLog` | | **Unity-Claude-CLIOrchestrator-Fixed-Simple** | 14 | 14.26 | `Initialize-CLIOrchestrator`, `Test-CLIOrchestratorComponents`, `Get-CLIOrchestratorInfo` | | **Unity-Claude-CLIOrchestrator-FullFeatured** | 2 | 10.46 | `Initialize-CLIOrchestrator`, `Find-ClaudeWindow` | | **Unity-Claude-CLIOrchestrator-Original-Backup** | 4 | 22.7 | `Initialize-CLIOrchestrator`, `Test-CLIOrchestratorComponents`, `Get-CLIOrchestratorInfo` | | **Unity-Claude-CLIOrchestrator-Original** | 15 | 74.96 | `Update-ClaudeWindowInfo`, `Find-ClaudeWindow`, `Switch-ToWindow` | | **Unity-Claude-CLIOrchestrator-Refactored-Fixed** | 4 | 15.12 | `Initialize-CLIOrchestrator`, `Test-CLIOrchestratorComponents`, `Get-CLIOrchestratorInfo` | | **Unity-Claude-CLIOrchestrator-Refactored** | 4 | 22.24 | `Initialize-CLIOrchestrator`, `Test-CLIOrchestratorComponents`, `Get-CLIOrchestratorInfo` | | **Unity-Claude-CLIOrchestrator** | 4 | 22.86 | `Initialize-CLIOrchestrator`, `Test-CLIOrchestratorComponents`, `Get-CLIOrchestratorInfo` | | **Unity-Claude-CLISubmission-Enhanced** | 6 | 16.43 | `Submit-ToClaudeWithInputLock`, `Start-InputLockProtection`, `Stop-InputLockProtection` | | **Unity-Claude-CLISubmission** | 7 | 45.44 | `Start-UnityErrorMonitoring`, `Stop-UnityErrorMonitoring`, `New-AutonomousPrompt` | | **Unity-Claude-CodeQL** | 10 | 24.37 | `Write-CodeQLLog`, `Install-CodeQLCLI`, `Test-CodeQLInstallation` | | **Unity-Claude-CodeReviewCoordination** | 6 | 16.68 | `New-CodeReviewAgentTeam`, `Invoke-AgentCollaborativeAnalysis`, `Invoke-IndependentAgentAnalysis` | | **Unity-Claude-ConcurrentCollections** | 14 | 25.57 | `New-ConcurrentQueue`, `Add-ConcurrentQueueItem`, `Get-ConcurrentQueueItem` | | **Unity-Claude-ConcurrentProcessor** | 17 | 34.36 | `Write-ConcurrentLog`, `New-JobId`, `Get-ConcurrentTimestamp` | | **Unity-Claude-Configuration-Fixed** | 10 | 23.68 | `ConvertTo-HashTable`, `Get-AutomationConfig`, `Set-AutomationConfig` | | **Unity-Claude-Configuration-Fixed** | 10 | 23.68 | `ConvertTo-HashTable`, `Get-AutomationConfig`, `Set-AutomationConfig` | | **Unity-Claude-Configuration** | 10 | 23.68 | `ConvertTo-HashTable`, `Get-AutomationConfig`, `Set-AutomationConfig` | | **Unity-Claude-Configuration** | 10 | 23.68 | `ConvertTo-HashTable`, `Get-AutomationConfig`, `Set-AutomationConfig` | | **Unity-Claude-Configuration** | 10 | 23.68 | `ConvertTo-HashTable`, `Get-AutomationConfig`, `Set-AutomationConfig` | | **Unity-Claude-Configuration** | 10 | 23.68 | `ConvertTo-HashTable`, `Get-AutomationConfig`, `Set-AutomationConfig` | | **Unity-Claude-Configuration** | 10 | 23.68 | `ConvertTo-HashTable`, `Get-AutomationConfig`, `Set-AutomationConfig` | | **Unity-Claude-Core** | 9 | 17.57 | `Initialize-AutomationContext`, `Write-Log`, `Get-FileTailAsString` | | **Unity-Claude-CPG-ASTConverter** | 20 | 37.8 | `Convert-ASTtoCPG`, `Process-ASTNode`, `Process-FunctionDefinition` | | **Unity-Claude-CPG-Original** | 33 | 31.05 | `CPGNode`, `CPGNode`, `ToString` | | **Unity-Claude-CPG-Refactored** | 1 | 8.38 | `ConvertTo-CPGFromScriptBlock` | | **Unity-Claude-CPG** | 1 | 8.38 | `ConvertTo-CPGFromScriptBlock` | | **Unity-Claude-CrossLanguage** | 9 | 22.28 | `Merge-LanguageGraphs`, `Resolve-CrossLanguageImports`, `Test-ImportMatch` | | **Unity-Claude-DecisionEngine-Original** | 27 | 46.72 | `Write-DecisionEngineLog`, `Test-RequiredModule`, `Get-DecisionEngineConfig` | | **Unity-Claude-DecisionEngine-Refactored** | 5 | 18.09 | `Import-DecisionEngineComponent`, `Get-DecisionEngineComponentStatus`, `Invoke-DecisionEngineAnalysis` | | **Unity-Claude-DecisionEngine** | 5 | 18.09 | `Import-DecisionEngineComponent`, `Get-DecisionEngineComponentStatus`, `Invoke-DecisionEngineAnalysis` | | **Unity-Claude-DocumentationAnalytics** | 14 | 44.08 | `Initialize-DocumentationAnalytics`, `Start-DocumentationAnalytics`, `Get-DocumentationUsageMetrics` | | **Unity-Claude-DocumentationAutomation-Original** | 20 | 54.38 | `Start-DocumentationAutomation`, `Stop-DocumentationAutomation`, `Test-DocumentationSync` | | **Unity-Claude-DocumentationAutomation-Refactored** | 3 | 16.62 | `Initialize-DocumentationAutomation`, `Test-ComponentHealth`, `Get-DocumentationAutomationInfo` | | **Unity-Claude-DocumentationAutomation** | 3 | 16.62 | `Initialize-DocumentationAutomation`, `Test-ComponentHealth`, `Get-DocumentationAutomationInfo` | | **Unity-Claude-DocumentationCrossReference** | 12 | 64.02 | `Initialize-DocumentationCrossReference`, `Get-ASTCrossReferences`, `Extract-MarkdownLinks` | | **Unity-Claude-DocumentationDrift-Refactored** | 3 | 9.91 | `Clear-DriftCache`, `Get-DriftDetectionResults`, `Test-DocumentationDrift` | | **Unity-Claude-DocumentationDrift** | 55 | 142.95 | `Initialize-DocumentationDrift`, `Get-DocumentationDriftConfig`, `Set-DocumentationDriftConfig` | | **Unity-Claude-DocumentationPipeline** | 6 | 13.73 | `New-EnhancedDocumentationPipeline`, `Invoke-SemanticAnalysisPipeline`, `Invoke-ArchitectureAnalysis` | | **Unity-Claude-DocumentationQualityAssessment_Original_20250830_193150** | 3 | 38.58 | `Initialize-DocumentationQualityAssessment`, `Get-DefaultQualityAssessmentConfiguration`, `Assess-DocumentationQuality` | | **Unity-Claude-DocumentationQualityAssessment** | 1 | 5.28 | `Assess-DocumentationQuality` | | **Unity-Claude-DocumentationQualityOrchestrator** | 24 | 37.23 | `Initialize-DocumentationQualityOrchestrator`, `Get-DefaultOrchestratorConfiguration`, `Start-DocumentationQualityWorkflow` | | **Unity-Claude-DocumentationSuggestions** | 15 | 43.47 | `Initialize-DocumentationSuggestions`, `Generate-RelatedContentSuggestions`, `Generate-ContentEmbedding` | | **Unity-Claude-DocumentationVersioning** | 25 | 25.49 | `Initialize-DocumentationVersioning`, `Get-DefaultVersioningConfiguration`, `Create-DocumentationVersion` | | **Unity-Claude-EmailNotifications-SystemNetMail** | 13 | 45.7 | `New-EmailConfiguration`, `Set-EmailCredentials`, `Test-EmailConfiguration` | | **Unity-Claude-EmailNotifications** | 7 | 27.9 | `Load-MailKitAssemblies`, `New-EmailConfiguration`, `Set-EmailCredentials` | | **Unity-Claude-ErrorHandling** | 9 | 28.54 | `Invoke-AsyncWithErrorHandling`, `New-ParallelErrorAggregator`, `Get-ParallelErrorClassification` | | **Unity-Claude-Errors** | 9 | 23.76 | `Initialize-ErrorDatabase`, `Add-ErrorPattern`, `Get-ErrorPattern` | | **Unity-Claude-EventLog** | 1 | 4.87 | `Write-UCDebugLog` | | **Unity-Claude-FileMonitor-Fixed** | 17 | 25.9 | `Write-FileMonitorLog`, `New-FileMonitor`, `Start-FileMonitor` | | **Unity-Claude-FileMonitor** | 15 | 24.06 | `New-FileMonitor`, `Start-FileMonitor`, `Stop-FileMonitor` | | **Unity-Claude-FixEngine** | 25 | 49.76 | `Write-FixEngineLog`, `Test-RequiredModule`, `Get-FixEngineConfig` | | **Unity-Claude-GitHub** | 1 | 7.07 | `ConvertTo-HashTable` | | **Unity-Claude-GovernanceIntegration** | 7 | 22.24 | `Test-GitHubGovernanceCompliance`, `New-GovernanceAwareApprovalRequest`, `Wait-GovernanceApproval` | | **Unity-Claude-HITL-Original** | 13 | 32.77 | `Initialize-ApprovalDatabase`, `New-ApprovalToken`, `Test-ApprovalToken` | | **Unity-Claude-HITL-Refactored** | 3 | 15.55 | `Get-HITLComponents`, `Test-HITLSystemIntegration`, `Invoke-ComprehensiveHITLAnalysis` | | **Unity-Claude-HITL** | 3 | 15.55 | `Get-HITLComponents`, `Test-HITLSystemIntegration`, `Invoke-ComprehensiveHITLAnalysis` | | **Unity-Claude-IncrementalProcessor-Fixed** | 34 | 28.41 | `IncrementalProcessor`, `SetupFileWatcher`, `Start` | | **Unity-Claude-IncrementalProcessor** | 34 | 28.41 | `IncrementalProcessor`, `SetupFileWatcher`, `Start` | | **Unity-Claude-IntegratedWorkflow-Original** | 13 | 82.62 | `Test-ModuleDependencyAvailability`, `Test-ModuleDependencies`, `Write-FallbackLog` | | **Unity-Claude-IntegrationEngine** | 20 | 29.48 | `Write-IntegrationLog`, `Get-CurrentTimestamp`, `New-CycleId` | | **Unity-Claude-IntelligentAlerting** | 14 | 21.6 | `Initialize-IntelligentAlerting`, `Connect-AvailableModules`, `Start-IntelligentAlerting` | | **Unity-Claude-IntelligentDocumentationTriggers** | 20 | 26.53 | `Initialize-IntelligentDocumentationTriggers`, `Get-DefaultIntelligentTriggersConfiguration`, `Evaluate-IntelligentTrigger` | | **Unity-Claude-IPC-Bidirectional-Fixed** | 12 | 20.33 | `Write-Log`, `Start-NamedPipeServer`, `Send-PipeMessage` | | **Unity-Claude-IPC-Bidirectional** | 12 | 20.33 | `Write-Log`, `Start-NamedPipeServer`, `Send-PipeMessage` | | **Unity-Claude-IPC** | 9 | 14.76 | `Test-ClaudeAvailable`, `Invoke-ClaudeAnalysis`, `Send-ClaudePrompt` | | **Unity-Claude-LangGraphBridge** | 8 | 11.73 | `New-LangGraphWorkflow`, `Submit-WorkflowTask`, `Get-WorkflowResult` | | **Unity-Claude-Learning-Analytics** | 8 | 24.52 | `Get-PatternSuccessRate`, `Get-AllPatternsSuccessRates`, `Calculate-MovingAverage` | | **Unity-Claude-Learning-Original** | 26 | 79.5 | `Initialize-LearningDatabase`, `Get-StringSimilarity`, `Get-LevenshteinDistance` | | **Unity-Claude-Learning-Simple** | 25 | 53.76 | `Write-LearningLog`, `ConvertFrom-JsonToHashtable`, `Initialize-LearningStorage` | | **Unity-Claude-LLM** | 10 | 16 | `Test-OllamaConnection`, `Get-OllamaModels`, `Invoke-OllamaGenerate` | | **Unity-Claude-MachineLearning** | 25 | 53.6 | `Initialize-MachineLearning`, `Initialize-PatternModels`, `Initialize-SyntheticTrainingData` | | **Unity-Claude-MasterOrchestrator-Original** | 34 | 46.06 | `Write-OrchestratorLog`, `Test-ModuleAvailability`, `Initialize-ModuleIntegration` | | **Unity-Claude-MasterOrchestrator-Refactored** | 3 | 11.45 | `Initialize-MasterOrchestrator`, `Get-MasterOrchestratorStatus`, `Test-MasterOrchestratorIntegration` | | **Unity-Claude-MasterOrchestrator** | 3 | 11.45 | `Initialize-MasterOrchestrator`, `Get-MasterOrchestratorStatus`, `Test-MasterOrchestratorIntegration` | | **Unity-Claude-MemoryAnalysis** | 6 | 16.55 | `Start-UnityMemoryMonitoring`, `Process-MemoryDataFile`, `Analyze-MemoryData` | | **Unity-Claude-MessageQueue** | 10 | 18.19 | `Initialize-MessageQueue`, `Add-MessageToQueue`, `Get-MessageFromQueue` | | **Unity-Claude-Monitoring** | 12 | 20.05 | `Get-ServiceHealth`, `Test-ServiceLiveness`, `Test-ServiceReadiness` | | **Unity-Claude-MultiStepOrchestrator** | 12 | 30.34 | `Invoke-MultiStepAnalysisOrchestration`, `Initialize-OrchestrationContext`, `Invoke-ParallelAnalysisWorkers` | | **Unity-Claude-NotificationContentEngine** | 35 | 50.83 | `New-UnifiedNotificationTemplate`, `Set-NotificationTemplate`, `Get-NotificationTemplate` | | **Unity-Claude-NotificationIntegration-Modular** | 3 | 13.61 | `Get-NotificationState`, `Set-NotificationState`, `Update-NotificationMetrics` | | **Unity-Claude-NotificationIntegration** | 20 | 47.5 | `Send-NotificationMultiChannel`, `Get-DeliveryChannelsForAlert`, `New-NotificationContent` | | **Unity-Claude-NotificationPreferences** | 24 | 37.57 | `Initialize-NotificationPreferences`, `Load-NotificationPreferences`, `Load-DeliveryRules` | | **Unity-Claude-ObsolescenceDetection-Refactored** | 5 | 22.22 | `Get-ObsolescenceDetectionComponents`, `Test-ObsolescenceDetectionHealth`, `Invoke-ComprehensiveObsolescenceAnalysis` | | **Unity-Claude-ObsolescenceDetection** | 5 | 22.22 | `Get-ObsolescenceDetectionComponents`, `Test-ObsolescenceDetectionHealth`, `Invoke-ComprehensiveObsolescenceAnalysis` | | **Unity-Claude-Ollama-Enhanced** | 13 | 26.84 | `Initialize-PowershAI`, `Invoke-PowershAIDocumentation`, `Start-IntelligentDocumentationPipeline` | | **Unity-Claude-Ollama-Optimized-Fixed** | 6 | 35.32 | `Get-OptimalContextWindow`, `Optimize-OllamaConfiguration`, `Start-OllamaBatchProcessing` | | **Unity-Claude-Ollama-Optimized** | 6 | 27.37 | `Get-OptimalContextWindow`, `Optimize-OllamaConfiguration`, `Start-OllamaBatchProcessing` | | **Unity-Claude-Ollama** | 13 | 34.17 | `Start-OllamaService`, `Stop-OllamaService`, `Test-OllamaConnectivity` | | **Unity-Claude-ParallelProcessing** | 18 | 40.62 | `Write-AgentLog`, `New-SynchronizedHashtable`, `Get-SynchronizedValue` | | **Unity-Claude-ParallelProcessor-Original** | 35 | 32.43 | `ParallelProcessor`, `ParallelProcessor`, `ParallelProcessor` | | **Unity-Claude-ParallelProcessor-Refactored** | 1 | 10.43 | `Get-UnityClaudeParallelProcessorInfo` | | **Unity-Claude-ParallelProcessor** | 1 | 10.43 | `Get-UnityClaudeParallelProcessorInfo` | | **Unity-Claude-PerformanceOptimizer-Original** | 34 | 34.33 | `PerformanceOptimizer`, `InitializeComponents`, `CalculateOptimalThreadCount` | | **Unity-Claude-PerformanceOptimizer-Refactored** | 22 | 19.43 | `PerformanceOptimizer`, `InitializeComponents`, `Start` | | **Unity-Claude-PerformanceOptimizer** | 22 | 27.63 | `Write-PerfLog`, `Get-PerfTimestamp`, `New-PerformanceId` | | **Unity-Claude-PerformanceOptimizer** | 22 | 19.43 | `PerformanceOptimizer`, `InitializeComponents`, `Start` | | **Unity-Claude-PredictiveAnalysis-Original** | 28 | 74.37 | `Initialize-PredictiveCache`, `Get-CodeEvolutionTrend`, `Measure-CodeChurn` | | **Unity-Claude-PredictiveAnalysis-Refactored** | 4 | 18.66 | `Initialize-PredictiveAnalysis`, `Get-ComprehensiveAnalysis`, `Calculate-OverallRisk` | | **Unity-Claude-PredictiveAnalysis** | 4 | 18.66 | `Initialize-PredictiveAnalysis`, `Get-ComprehensiveAnalysis`, `Calculate-OverallRisk` | | **Unity-Claude-ProactiveMaintenanceEngine** | 22 | 33.33 | `Initialize-ProactiveMaintenanceEngine`, `Connect-MaintenanceModules`, `Initialize-RecommendationEngine` | | **Unity-Claude-RealTimeAnalysis** | 15 | 22.22 | `Initialize-RealTimeAnalysisPipeline`, `Discover-ExistingModules`, `Start-RealTimeAnalysisPipeline` | | **Unity-Claude-RealTimeMonitoring** | 12 | 17.14 | `Initialize-RealTimeMonitoring`, `Start-FileSystemMonitoring`, `Register-FileSystemEventHandlers` | | **Unity-Claude-RealTimeOptimizer** | 22 | 26.14 | `Initialize-RealTimeOptimizer`, `Set-RTOptimizationMode`, `Initialize-RTResourceMonitor` | | **Unity-Claude-RecompileSignaling** | 4 | 11.62 | `Switch-ToUnityWindow`, `Process-RecompileSignal`, `Start-RecompileSignalMonitoring` | | **Unity-Claude-ReliabilityManager** | 20 | 43.51 | `Initialize-ReliabilityManager`, `Initialize-FaultToleranceSystem`, `Initialize-BackupRecoverySystem` | | **Unity-Claude-ReliableMonitoring** | 10 | 16.66 | `Read-SafeJsonFile`, `Test-ErrorFileChanged`, `Process-UnityErrors` | | **Unity-Claude-RepoAnalyst** | 20 | 13.83 | `Initialize-RepoAnalystLogging`, `Write-RepoAnalystLog`, `Initialize-RepoAnalyst` | | **Unity-Claude-ResourceOptimizer** | 12 | 33.53 | `Write-ResourceLog`, `Get-ResourceTimestamp`, `ConvertTo-HumanReadableSize` | | **Unity-Claude-ResponseMonitor** | 24 | 28.94 | `Write-ResponseMonitorLog`, `Test-RequiredModule`, `Get-ResponseMonitorConfig` | | **Unity-Claude-ResponseMonitoring** | 11 | 18 | `Read-SafeResponseFile`, `Test-ResponseFileChanged`, `Process-ClaudeResponse` | | **Unity-Claude-RunspaceManagement-Original** | 30 | 75.97 | `Test-ModuleDependencyAvailability`, `Write-FallbackLog`, `Write-ModuleLog` | | **Unity-Claude-RunspaceManagement-Refactored** | 3 | 10.91 | `Initialize-RunspaceManagement`, `Get-RunspaceManagementStatus`, `Stop-RunspaceManagement` | | **Unity-Claude-RunspaceManagement** | 3 | 10.91 | `Initialize-RunspaceManagement`, `Get-RunspaceManagementStatus`, `Stop-RunspaceManagement` | | **Unity-Claude-Safety** | 9 | 23.95 | `Initialize-SafetyFramework`, `Test-FixSafety`, `Invoke-SafetyBackup` | | **Unity-Claude-ScalabilityEnhancements-Original** | 70 | 48.16 | `GraphPruner`, `PruneGraph`, `MarkPreservedNodes` | | **Unity-Claude-ScalabilityEnhancements-Refactored** | 4 | 16.67 | `Initialize-ScalabilityEnhancements`, `Test-ScalabilityComponents`, `Get-ScalabilityInfo` | | **Unity-Claude-ScalabilityEnhancements** | 4 | 16.67 | `Initialize-ScalabilityEnhancements`, `Test-ScalabilityComponents`, `Get-ScalabilityInfo` | | **Unity-Claude-ScalabilityOptimizer** | 17 | 37.82 | `Initialize-ScalabilityOptimizer`, `Initialize-ScalingPolicies`, `Initialize-PerformanceBenchmarking` | | **Unity-Claude-SemanticAnalysis-Architecture** | 5 | 13.45 | `Recover-Architecture`, `Identify-SystemLayers`, `Analyze-ModuleDependencies` | | **Unity-Claude-SemanticAnalysis-Business** | 5 | 15.91 | `Extract-BusinessLogic`, `Find-ValidationRules`, `Find-BusinessRules` | | **Unity-Claude-SemanticAnalysis-Helpers** | 13 | 20.93 | `Test-IsCPGraph`, `Ensure-GraphDuckType`, `Ensure-Array` | | **Unity-Claude-SemanticAnalysis-Metrics** | 5 | 13.13 | `Get-CohesionMetrics`, `Calculate-ModuleCohesion`, `Calculate-SemanticCohesion` | | **Unity-Claude-SemanticAnalysis-New** | 1 | 8.38 | `ConvertTo-CPGFromScriptBlock` | | **Unity-Claude-SemanticAnalysis-Old** | 1 | 8.38 | `ConvertTo-CPGFromScriptBlock` | | **Unity-Claude-SemanticAnalysis-Patterns** | 8 | 19.41 | `Canonicalize-PatternTypes`, `Find-DesignPatterns`, `Find-SingletonPattern` | | **Unity-Claude-SemanticAnalysis-Purpose** | 3 | 14.99 | `Get-CodePurpose`, `Classify-CallablePurpose`, `Classify-ClassPurpose` | | **Unity-Claude-SemanticAnalysis-Quality** | 8 | 21.63 | `Test-DocumentationCompleteness`, `Analyze-FunctionDocumentation`, `Analyze-ClassDocumentation` | | **Unity-Claude-SemanticAnalysis** | 1 | 8.38 | `ConvertTo-CPGFromScriptBlock` | | **Unity-Claude-SemanticAnalysis** | 51 | 140 | `Test-IsCPGraph`, `Ensure-GraphDuckType`, `Find-DesignPatterns` | | **Unity-Claude-SessionManager** | 18 | 26.48 | `Write-SessionLog`, `New-SessionId`, `Get-SessionTimestamp` | | **Unity-Claude-SlackIntegration** | 10 | 18.86 | `Initialize-SlackIntegration`, `Send-SlackAlert`, `Format-SlackAlertMessage` | | **Unity-Claude-SystemCoordinator** | 21 | 40.22 | `Initialize-SystemCoordinator`, `Register-AvailableModules`, `Request-CoordinatedOperation` | | **Unity-Claude-SystemStatus.cleaned** | 50 | 129.31 | `Write-SystemStatusLog`, `Test-SystemStatusSchema`, `Read-SystemStatus` | | **Unity-Claude-SystemStatus.cleaned** | 50 | 129.31 | `Write-SystemStatusLog`, `Test-SystemStatusSchema`, `Read-SystemStatus` | | **Unity-Claude-TeamsIntegration** | 11 | 22.77 | `Initialize-TeamsIntegration`, `Test-TeamsMigrationStatus`, `Send-TeamsAlert` | | **Unity-Claude-TechnicalDebtAgents** | 4 | 22.4 | `Invoke-TechnicalDebtMultiAgentAnalysis`, `Invoke-MultiAgentPrioritization`, `New-RefactoringDecisionWorkflow` | | **Unity-Claude-TreeSitter** | 10 | 19.96 | `Initialize-TreeSitter`, `Install-TreeSitterParsers`, `Invoke-TreeSitterParse` | | **Unity-Claude-TriggerConditions** | 7 | 27.5 | `Initialize-TriggerConditions`, `Test-TriggerCondition`, `Add-ToProcessingQueue` | | **Unity-Claude-TriggerIntegration** | 8 | 23.33 | `Initialize-TriggerIntegration`, `Register-EventHandlers`, `Start-FileMonitoring` | | **Unity-Claude-TriggerManager** | 25 | 19.18 | `Initialize-TriggerManager`, `Test-FileExclusion`, `Find-MatchingTriggers` | | **Unity-Claude-UnityParallelization-Original** | 22 | 86.33 | `Test-ModuleDependencyAvailability`, `Write-FallbackLog`, `Write-UnityParallelLog` | | **Unity-Claude-UnityParallelization-Refactored** | 2 | 10.72 | `Get-UnityParallelizationModuleInfo`, `Show-UnityParallelizationFunctions` | | **Unity-Claude-UnityParallelization** | 2 | 10.72 | `Get-UnityParallelizationModuleInfo`, `Show-UnityParallelizationFunctions` | | **Unity-Claude-WebhookNotifications** | 11 | 40.8 | `New-WebhookConfiguration`, `Test-WebhookConfiguration`, `Invoke-WebhookDelivery` | | **Unity-Claude-WindowDetection-Enhanced** | 1 | 9.34 | `Find-ClaudeCodeCLIWindow-Enhanced` | | **Unity-Claude-WindowDetection** | 5 | 15.24 | `Get-DetailedWindowInfo`, `Test-ClaudeCodeWindow`, `Get-ForegroundWindow` | | **Unity-Project-TestMocks** | 6 | 7.86 | `Test-UnityProjectAvailability`, `Register-UnityProject`, `Get-UnityProjectStatus` | | **Unity-Project-TestMocks** | 6 | 7.86 | `Test-UnityProjectAvailability`, `Register-UnityProject`, `Get-UnityProjectStatus` | | **Unity-TestAutomation** | 9 | 41.42 | `Invoke-UnityEditModeTests`, `Invoke-UnityPlayModeTests`, `Get-UnityTestResults` | | **UnityBuildOperations** | 6 | 22.42 | `Invoke-UnityPlayerBuild`, `New-UnityBuildScript`, `Test-UnityBuildResult` | | **UnityCommands** | 7 | 15.5 | `Invoke-TestCommand`, `Invoke-UnityTests`, `Invoke-CompilationTest` | | **UnityIntegration** | 6 | 12.64 | `Get-PatternConfidence`, `Convert-TypeToStandard`, `Convert-ActionToType` | | **UnityLogAnalysis** | 2 | 14.77 | `Invoke-UnityLogAnalysis`, `Invoke-UnityErrorPatternAnalysis` | | **UnityPerformanceAnalysis** | 2 | 15.01 | `Invoke-UnityPerformanceAnalysis`, `Invoke-UnityTrendAnalysis` | | **UnityProjectOperations** | 3 | 14.34 | `Invoke-UnityProjectValidation`, `Invoke-UnityScriptCompilation`, `Test-UnityCompilationResult` | | **UnityReportingOperations** | 3 | 21.96 | `Invoke-UnityReportGeneration`, `Export-UnityAnalysisData`, `Get-UnityAnalyticsMetrics` | | **ValidationEngine** | 4 | 11.32 | `Test-CommandSafety`, `Test-PathSafety`, `Remove-DangerousCharacters` | | **VariableSharing** | 10 | 12.9 | `Write-ModuleLog`, `Add-SessionStateVariable`, `Get-SharedVariablesDictionary` | | **WindowManager-Enhanced** | 4 | 16.34 | `Update-ClaudeWindowInfo`, `Find-ClaudeWindow`, `Get-ClaudeWindowInfo` | | **WindowManager-NUGGETRON** | 4 | 6.27 | `Get-ClaudeWindowInfo`, `Update-ClaudeWindowInfo`, `Switch-ToClaudeWindow` | | **WindowManager-Original** | 4 | 16.34 | `Update-ClaudeWindowInfo`, `Find-ClaudeWindow`, `Get-ClaudeWindowInfo` | | **WindowManager** | 5 | 14.5 | `Get-ClaudeWindowInfo`, `Update-ProtectedRegistration`, `Update-ClaudeWindowInfo` | | **WorkflowCore** | 3 | 4.3 | `Write-FallbackLog`, `Write-IntegratedWorkflowLog`, `Get-IntegratedWorkflowState` | | **WorkflowIntegration** | 6 | 9.09 | `Invoke-NotificationHook`, `Add-WorkflowNotificationTrigger`, `Remove-WorkflowNotificationTrigger` | | **WorkflowIntegration** | 6 | 14.84 | `Wait-HumanApproval`, `Resume-WorkflowFromApproval`, `Invoke-HumanApprovalWorkflow` | | **WorkflowMonitoring** | 2 | 13.34 | `Get-IntegratedWorkflowStatus`, `Stop-IntegratedWorkflow` | | **WorkflowOrchestration** | 3 | 21.3 | `New-IntegratedWorkflow`, `Start-IntegratedWorkflow`, `Get-WorkflowOrchestrationScript` |

## Scripts (663)

| Script | Functions | Size (KB) | Purpose |
|--------|-----------|-----------|---------|
| Activate.ps1 | 4 | 8.82 | Automation | | Activate.ps1 | 4 | 8.82 | Automation | | Activate.ps1 | 4 | 8.82 | Automation | | Add-AIServices.ps1 | 1 | 6.81 | Automation | | Add-GitHubIssueComment.ps1 | 1 | 7.3 | Automation | | Analyze-ResponseSentiment.ps1 | 1 | 7.97 | Automation | | Apply-ClaudeFix.ps1 | 9 | 16.78 | Automation | | Backup-NotificationConfig.ps1 | 1 | 3.69 | Automation | | BidirectionalClient-Example.ps1 | 2 | 10.3 | Automation | | Block-InputDuringClaudeResponse.ps1 | 4 | 9.6 | Automation | | Block-InputDuringClaudeResponse.ps1 | 4 | 9.6 | Automation | | Build-APIDocs.ps1 | 1 | 8.74 | Build Process | | Build-TemplateDataFromUnityError.ps1 | 7 | 12.06 | Build Process | | CLAUDE_CRITICAL_DIRECTIVE.ps1 | 3 | 7.19 | Automation | | CLAUDE_CRITICAL_DIRECTIVE.ps1 | 3 | 7.19 | Automation | | Claude-ResponseExporter.ps1 | 2 | 11.22 | Automation | | Claude-ResponseExporter.ps1 | 2 | 11.22 | Automation | | Clean-And-Deploy.ps1 | 1 | 8.09 | Automation | | Clear-GitHubPAT.ps1 | 1 | 4.99 | Automation | | Close-GitHubIssueIfResolved.ps1 | 1 | 10.01 | Automation |

## Module Details


### ActionExecutionEngine

- **Path:** `Modules\Unity-Claude-CLIOrchestrator\Core\ActionExecutionEngine.psm1`
- **Size:** 23.53 KB
- **Functions:** 11
- **Lines:** 673
- **Last Modified:** 08/25/2025 13:45:24

**Functions:**
- `Add-ActionToQueue` (Line 579, 20 lines) - `Get-ActionExecutionScript` (Line 486, 87 lines) - `Get-ActionExecutionStatus` (Line 612, 10 lines) - `Get-NextQueuedAction` (Line 601, 9 lines) - `Invoke-ConstrainedExecution` (Line 309, 93 lines) - `Invoke-SafeAction` (Line 408, 76 lines) - `New-ConstrainedRunspace` (Line 263, 44 lines) - `Test-ActionSafety` (Line 104, 68 lines) - `Test-SafeCommand` (Line 215, 42 lines) - `Test-SafeFilePath` (Line 174, 39 lines) - `Write-ExecutionLog` (Line 70, 28 lines) 
### AgentCore

- **Path:** `Modules\Unity-Claude-AutonomousAgent\Core\AgentCore.psm1`
- **Size:** 9.11 KB
- **Functions:** 6
- **Lines:** 300
- **Last Modified:** 08/20/2025 17:25:20

**Functions:**
- `Get-AgentConfig` (Line 94, 21 lines) - `Get-AgentState` (Line 145, 21 lines) - `Initialize-AgentCore` (Line 65, 27 lines) - `Reset-AgentState` (Line 196, 55 lines) - `Set-AgentConfig` (Line 117, 26 lines) - `Set-AgentState` (Line 168, 26 lines) 
### AgentLogging

- **Path:** `Modules\Unity-Claude-AutonomousAgent\Core\AgentLogging.psm1`
- **Size:** 13.12 KB
- **Functions:** 7
- **Lines:** 399
- **Last Modified:** 08/26/2025 11:46:17

**Functions:**
- `Clear-AgentLog` (Line 317, 33 lines) - `Get-AgentLogPath` (Line 257, 12 lines) - `Get-AgentLogStatistics` (Line 271, 44 lines) - `Initialize-AgentLogging` (Line 147, 43 lines) - `Invoke-LogRotation` (Line 196, 27 lines) - `Remove-OldLogFiles` (Line 225, 30 lines) - `Write-AgentLog` (Line 31, 114 lines) 
### AIAssessment

- **Path:** `Modules\Unity-Claude-DocumentationQualityAssessment\Components\AIAssessment.psm1`
- **Size:** 0.87 KB
- **Functions:** 2
- **Lines:** 34
- **Last Modified:** 08/30/2025 19:31:50

**Functions:**
- `Initialize-AIContentAssessor` (Line 26, 3 lines) - `Parse-AIQualityResponse` (Line 13, 11 lines) 
### AnalysisLogging

- **Path:** `Modules\Unity-Claude-CLIOrchestrator\Core\Components\AnalysisLogging.psm1`
- **Size:** 5.72 KB
- **Functions:** 4
- **Lines:** 169
- **Last Modified:** 08/26/2025 11:46:17

**Functions:**
- `Get-AnalysisLogPath` (Line 68, 5 lines) - `Set-AnalysisLogPath` (Line 57, 9 lines) - `Test-AnalysisLogging` (Line 75, 46 lines) - `Write-AnalysisLog` (Line 15, 40 lines) 
### AnalyticsReporting

- **Path:** `Modules\Unity-Claude-PredictiveAnalysis\Core\AnalyticsReporting.psm1`
- **Size:** 24.71 KB
- **Functions:** 9
- **Lines:** 716
- **Last Modified:** 08/26/2025 11:46:19

**Functions:**
- `Estimate-RefactoringEffort` (Line 103, 68 lines) - `Get-AuthorContributions` (Line 423, 71 lines) - `Get-CommitFrequency` (Line 372, 49 lines) - `Get-ComplexityTrend` (Line 295, 75 lines) - `Get-CouplingIssues` (Line 576, 88 lines) - `Get-HistoricalMetrics` (Line 238, 55 lines) - `Get-PriorityActions` (Line 173, 59 lines) - `Get-ROIAnalysis` (Line 33, 68 lines) - `Update-PredictionModels` (Line 500, 70 lines) 
### ApprovalRequests

- **Path:** `Modules\Unity-Claude-HITL\Core\ApprovalRequests.psm1`
- **Size:** 10.46 KB
- **Functions:** 5
- **Lines:** 313
- **Last Modified:** 08/26/2025 11:46:18

**Functions:**
- `Get-ApprovalStatus` (Line 132, 28 lines) - `Get-PendingApprovals` (Line 203, 14 lines) - `New-ApprovalRequest` (Line 14, 116 lines) - `Set-ApprovalEscalation` (Line 162, 39 lines) - `Update-ApprovalStatus` (Line 219, 45 lines) 
### ASTAnalysis

- **Path:** `Modules\Unity-Claude-Learning\Core\ASTAnalysis.psm1`
- **Size:** 10.33 KB
- **Functions:** 4
- **Lines:** 313
- **Last Modified:** 08/26/2025 11:46:19

**Functions:**
- `Compare-ASTStructures` (Line 199, 65 lines) - `Find-CodePattern` (Line 85, 67 lines) - `Get-ASTStatistics` (Line 154, 43 lines) - `Get-CodeAST` (Line 11, 72 lines) 
### AutoGenerationTriggers

- **Path:** `Modules\Unity-Claude-Enhanced-DocumentationGenerators\Core\AutoGenerationTriggers.psm1`
- **Size:** 25.08 KB
- **Functions:** 11
- **Lines:** 772
- **Last Modified:** 08/28/2025 17:06:20

**Functions:**
- `Add-TriggerActivity` (Line 661, 32 lines) - `Get-TriggerActivity` (Line 696, 30 lines) - `Initialize-DocumentationTriggers` (Line 15, 58 lines) - `Install-GitHooks` (Line 212, 227 lines) - `Invoke-DocumentationGeneration` (Line 495, 104 lines) - `Remove-AllTriggers` (Line 729, 18 lines) - `Start-FileWatcher` (Line 76, 93 lines) - `Start-ScheduledDocumentationGeneration` (Line 602, 32 lines) - `Stop-FileWatcher` (Line 172, 37 lines) - `Stop-ScheduledDocumentationGeneration` (Line 637, 21 lines) - `Uninstall-GitHooks` (Line 442, 50 lines) 
### AutomationEngine

- **Path:** `Modules\Unity-Claude-DocumentationAutomation\Core\AutomationEngine.psm1`
- **Size:** 10.97 KB
- **Functions:** 4
- **Lines:** 308
- **Last Modified:** 08/26/2025 11:46:18

**Functions:**
- `Get-DocumentationStatus` (Line 224, 40 lines) - `Start-DocumentationAutomation` (Line 20, 80 lines) - `Stop-DocumentationAutomation` (Line 102, 38 lines) - `Test-DocumentationSync` (Line 142, 80 lines) 
### AutonomousFeedbackLoop

- **Path:** `Modules\Unity-Claude-MasterOrchestrator\Core\AutonomousFeedbackLoop.psm1`
- **Size:** 12.19 KB
- **Functions:** 5
- **Lines:** 333
- **Last Modified:** 08/26/2025 11:46:19

**Functions:**
- `Get-FeedbackLoopStatus` (Line 152, 30 lines) - `Resume-AutonomousFeedbackLoop` (Line 257, 29 lines) - `Start-AutonomousFeedbackLoop` (Line 22, 78 lines) - `Stop-AutonomousFeedbackLoop` (Line 102, 48 lines) - `Test-AutonomousFeedbackLoop` (Line 184, 71 lines) 
### AutonomousOperations

- **Path:** `Modules\Unity-Claude-CLIOrchestrator\Core\AutonomousOperations.psm1`
- **Size:** 34.64 KB
- **Functions:** 4
- **Lines:** 794
- **Last Modified:** 08/27/2025 14:32:24

**Functions:**
- `Get-ActionResultSummary` (Line 135, 171 lines) - `Invoke-AutonomousExecutionLoop` (Line 544, 206 lines) - `New-AutonomousPrompt` (Line 39, 94 lines) - `Process-ResponseFile` (Line 308, 234 lines) 
### BackgroundJobQueue

- **Path:** `Modules\Unity-Claude-ScalabilityEnhancements\Core\BackgroundJobQueue.psm1`
- **Size:** 11.85 KB
- **Functions:** 15
- **Lines:** 377
- **Last Modified:** 08/26/2025 11:46:19

**Functions:**
- `Add-JobToQueue` (Line 168, 27 lines) - `AddJob` (Line 28, 17 lines, 3 params) - `BackgroundJobQueue` (Line 18, 8 lines, 1 params) - `ExecuteJob` (Line 81, 34 lines, 1 params) - `Get-JobResults` (Line 248, 25 lines) - `Get-QueueStatus` (Line 231, 15 lines) - `GetQueueStatus` (Line 134, 15 lines) - `Invoke-JobPriorityUpdate` (Line 302, 26 lines) - `New-BackgroundJobQueue` (Line 152, 14 lines) - `ProcessJobs` (Line 63, 16 lines) - `Remove-CompletedJobs` (Line 275, 25 lines) - `Start-QueueProcessor` (Line 197, 15 lines) - `StartProcessing` (Line 47, 14 lines) - `Stop-QueueProcessor` (Line 214, 15 lines) - `StopProcessing` (Line 117, 15 lines) 
### BackupIntegration

- **Path:** `Modules\Unity-Claude-DocumentationAutomation\Core\BackupIntegration.psm1`
- **Size:** 30.36 KB
- **Functions:** 8
- **Lines:** 881
- **Last Modified:** 08/26/2025 11:46:18

**Functions:**
- `Export-DocumentationReport` (Line 664, 169 lines) - `Generate-ImprovementDocs` (Line 532, 130 lines) - `Get-DocumentationHistory` (Line 175, 61 lines) - `New-DocumentationBackup` (Line 20, 71 lines) - `Restore-DocumentationBackup` (Line 93, 80 lines) - `Sync-WithPredictiveAnalysis` (Line 355, 70 lines) - `Test-RollbackCapability` (Line 238, 111 lines) - `Update-FromCodeChanges` (Line 427, 103 lines) 
### BatchProcessingEngine

- **Path:** `Modules\Unity-Claude-ParallelProcessor\Core\BatchProcessingEngine.psm1`
- **Size:** 22.88 KB
- **Functions:** 13
- **Lines:** 499
- **Last Modified:** 08/26/2025 11:46:19

**Functions:**
- `AddItem` (Line 217, 2 lines, 1 params) - `AddItems` (Line 196, 18 lines, 1 params) - `BatchProcessingEngine` (Line 30, 33 lines, 5 params) - `CompleteAdding` (Line 222, 8 lines) - `Dispose` (Line 338, 20 lines) - `GetResults` (Line 233, 21 lines, 1 params) - `GetStatistics` (Line 303, 18 lines) - `New-BatchProcessingEngine` (Line 365, 34 lines) - `Start` (Line 66, 127 lines) - `Start-SimpleBatchProcessing` (Line 401, 55 lines) - `Stop` (Line 324, 11 lines) - `UpdateQueueStatistics` (Line 288, 12 lines) - `WaitForCompletion` (Line 257, 28 lines, 1 params) 
### BayesianConfidenceEngine

- **Path:** `Modules\Unity-Claude-CLIOrchestrator\Core\BayesianConfidenceEngine.psm1`
- **Size:** 24.86 KB
- **Functions:** 15
- **Lines:** 738
- **Last Modified:** 08/26/2025 11:46:17

**Functions:**
- `Calculate-OverallConfidence` (Line 71, 81 lines) - `Get-BayesianAdjustment` (Line 504, 35 lines) - `Get-BayesianConfidence` (Line 190, 53 lines) - `Get-BayesianRecommendationConfidence` (Line 154, 34 lines) - `Get-ConfidenceQualityRating` (Line 608, 13 lines) - `Get-EntityBasedConfidence` (Line 448, 54 lines) - `Get-KeySimilarityScore` (Line 298, 34 lines) - `Get-LongestCommonSubsequence` (Line 334, 28 lines) - `Get-PositionWeightMatrixScore` (Line 249, 47 lines) - `Get-StringToProbabilityScore` (Line 364, 36 lines) - `Get-UncertaintyQuantification` (Line 541, 36 lines) - `Invoke-CRPSCalibration` (Line 402, 44 lines) - `Invoke-FinalCalibration` (Line 579, 27 lines) - `Update-BayesianPrior` (Line 664, 26 lines) - `Update-ConfidenceLearning` (Line 623, 39 lines) 
### BayesianInference

- **Path:** `Modules\Unity-Claude-CLIOrchestrator\Core\DecisionEngine-Bayesian\BayesianInference.psm1`
- **Size:** 11.82 KB
- **Functions:** 6
- **Lines:** 307
- **Last Modified:** 08/26/2025 11:46:18

**Functions:**
- `Calculate-BayesianEvidence` (Line 157, 27 lines) - `Calculate-BayesianLikelihood` (Line 126, 28 lines) - `Calculate-BayesianUncertainty` (Line 235, 32 lines) - `Calculate-ContextualAdjustment` (Line 187, 45 lines) - `Get-BayesianPrior` (Line 95, 28 lines) - `Invoke-BayesianConfidenceAdjustment` (Line 9, 83 lines) 
### CircuitBreaker

- **Path:** `Modules\Unity-Claude-CLIOrchestrator\Core\CircuitBreaker.psm1`
- **Size:** 30.81 KB
- **Functions:** 16
- **Lines:** 957
- **Last Modified:** 08/25/2025 13:45:24

**Functions:**
- `Clear-OldCircuitBreakerMetrics` (Line 625, 28 lines) - `Export-CircuitBreakerConfiguration` (Line 795, 41 lines) - `Get-CircuitBreaker` (Line 84, 47 lines) - `Get-CircuitBreakerStatistics` (Line 561, 61 lines) - `Get-ExponentialBackoffDelay` (Line 478, 16 lines) - `Get-LinearBackoffDelay` (Line 497, 16 lines) - `Import-CircuitBreakerConfiguration` (Line 839, 48 lines) - `Invoke-CircuitBreakerAction` (Line 197, 86 lines) - `Invoke-GracefulDegradationWithCircuitBreaker` (Line 706, 82 lines) - `Register-CircuitBreakerFailure` (Line 417, 54 lines) - `Register-CircuitBreakerSuccess` (Line 384, 30 lines) - `Reset-CircuitBreaker` (Line 516, 38 lines) - `Set-CircuitBreakerState` (Line 290, 91 lines) - `Test-CircuitBreakerHealth` (Line 660, 39 lines) - `Test-CircuitBreakerState` (Line 134, 60 lines) - `Write-CircuitBreakerLog` (Line 58, 19 lines) 
### CircuitBreaker

- **Path:** `Modules\Unity-Claude-CLIOrchestrator\Core\Components\CircuitBreaker.psm1`
- **Size:** 11.48 KB
- **Functions:** 8
- **Lines:** 316
- **Last Modified:** 08/26/2025 11:46:17

**Functions:**
- `Get-CircuitBreakerState` (Line 112, 10 lines) - `Invoke-WithCircuitBreaker` (Line 148, 25 lines) - `Reset-CircuitBreakerState` (Line 101, 9 lines) - `Set-CircuitBreakerConfiguration` (Line 124, 22 lines) - `Test-CircuitBreakerComponent` (Line 175, 90 lines) - `Test-CircuitBreakerState` (Line 46, 25 lines) - `Update-CircuitBreakerState` (Line 73, 26 lines) - `Write-AnalysisLog` (Line 17, 3 lines) 
### Classification

- **Path:** `Modules\Unity-Claude-AutonomousAgent\Parsing\Classification.psm1`
- **Size:** 28.04 KB
- **Functions:** 8
- **Lines:** 760
- **Last Modified:** 08/20/2025 17:25:21

**Functions:**
- `Get-ClassificationMetrics` (Line 539, 86 lines) - `Get-ResponseIntent` (Line 375, 53 lines) - `Get-ResponseSentiment` (Line 430, 52 lines) - `Get-SimpleClassification` (Line 484, 53 lines) - `Invoke-DecisionTreeClassification` (Line 227, 79 lines) - `Invoke-ResponseClassification` (Line 147, 78 lines) - `Test-ClassificationEngine` (Line 627, 83 lines) - `Test-NodeCondition` (Line 308, 65 lines) 
### ClaudeIntegration

- **Path:** `Modules\Unity-Claude-AutonomousAgent\Integration\ClaudeIntegration.psm1`
- **Size:** 12.77 KB
- **Functions:** 4
- **Lines:** 322
- **Last Modified:** 08/20/2025 17:25:21

**Functions:**
- `Get-ClaudeResponseStatus` (Line 235, 41 lines) - `New-FollowUpPrompt` (Line 90, 72 lines) - `Submit-PromptToClaude` (Line 16, 72 lines) - `Submit-ToClaude` (Line 164, 69 lines) 
### CLIAutomation

- **Path:** `Modules\Execution\CLIAutomation.psm1`
- **Size:** 27.25 KB
- **Functions:** 15
- **Lines:** 839
- **Last Modified:** 08/20/2025 17:25:20

**Functions:**
- `Add-InputToQueue` (Line 472, 50 lines) - `Format-ClaudePrompt` (Line 648, 33 lines) - `Get-ClaudeWindow` (Line 101, 45 lines) - `Get-InputQueueStatus` (Line 615, 27 lines) - `Initialize-InputQueue` (Line 455, 15 lines) - `Process-InputQueue` (Line 524, 89 lines) - `Send-KeysToWindow` (Line 233, 29 lines) - `Set-WindowFocus` (Line 152, 79 lines) - `Submit-ClaudeCLIInput` (Line 264, 51 lines) - `Submit-ClaudeFileInput` (Line 352, 97 lines) - `Submit-ClaudeInputWithFallback` (Line 719, 56 lines) - `Test-InputDelivery` (Line 683, 30 lines) - `Test-ProcessExists` (Line 87, 12 lines) - `Write-ClaudeMessageFile` (Line 321, 29 lines) - `Write-CLILog` (Line 64, 21 lines) 
### CodeComplexityMetrics

- **Path:** `Modules\Unity-Claude-CPG\Core\CodeComplexityMetrics.psm1`
- **Size:** 19.43 KB
- **Functions:** 11
- **Lines:** 556
- **Last Modified:** 08/26/2025 11:46:18

**Functions:**
- `Get-ClassComplexity` (Line 199, 48 lines) - `Get-CodeComplexityMetrics` (Line 44, 104 lines) - `Get-CognitiveComplexity` (Line 278, 45 lines) - `Get-ComplexityRecommendations` (Line 479, 31 lines) - `Get-ComplexityRiskLevel` (Line 419, 25 lines) - `Get-ComplexityStatistics` (Line 446, 31 lines) - `Get-CyclomaticComplexity` (Line 249, 27 lines) - `Get-FunctionComplexity` (Line 150, 47 lines) - `Get-HalsteadMetrics` (Line 376, 41 lines) - `Get-MaintainabilityIndex` (Line 354, 20 lines) - `Get-MaxNestingDepth` (Line 325, 27 lines) 
### CodeRedundancyDetection

- **Path:** `Modules\Unity-Claude-CPG\Core\CodeRedundancyDetection.psm1`
- **Size:** 17.61 KB
- **Functions:** 8
- **Lines:** 498
- **Last Modified:** 08/26/2025 11:46:18

**Functions:**
- `Find-CloneGroups` (Line 265, 58 lines) - `Find-DuplicateFunctions` (Line 159, 48 lines) - `Find-SimilarCodeBlocks` (Line 209, 54 lines) - `Get-LevenshteinDistance` (Line 421, 30 lines) - `Get-SemanticSimilarity` (Line 394, 25 lines) - `Get-StructuralSimilarity` (Line 325, 41 lines) - `Get-TokenSimilarity` (Line 368, 24 lines) - `Test-CodeRedundancy` (Line 42, 115 lines) 
### CodeSmellPrediction

- **Path:** `Modules\Unity-Claude-PredictiveAnalysis\Core\CodeSmellPrediction.psm1`
- **Size:** 21.09 KB
- **Functions:** 6
- **Lines:** 541
- **Last Modified:** 08/26/2025 11:46:19

**Functions:**
- `Find-DataClumps` (Line 254, 76 lines) - `Find-ExcessiveParameters` (Line 381, 47 lines) - `Find-FeatureEnvy` (Line 193, 59 lines) - `Find-HighComplexityMethods` (Line 332, 47 lines) - `Get-SmellRecommendations` (Line 430, 64 lines) - `Predict-CodeSmells` (Line 15, 176 lines) 
### CommandExecution

- **Path:** `Modules\SafeCommandExecution\Core\CommandExecution.psm1`
- **Size:** 8.78 KB
- **Functions:** 3
- **Lines:** 266
- **Last Modified:** 08/26/2025 11:46:17

**Functions:**
- `Get-CommandExecutionStatistics` (Line 198, 17 lines) - `Invoke-SafeCommand` (Line 22, 137 lines) - `Test-ExecutionResult` (Line 161, 35 lines) 
### CommandExecutionEngine

- **Path:** `Modules\Unity-Claude-AutonomousAgent\Execution\CommandExecutionEngine.psm1`
- **Size:** 31.54 KB
- **Functions:** 13
- **Lines:** 894
- **Last Modified:** 08/20/2025 17:25:20

**Functions:**
- `Add-CommandToQueue` (Line 70, 78 lines) - `Clear-ExecutionQueue` (Line 221, 28 lines) - `Export-ExecutionResults` (Line 783, 56 lines) - `Get-ExecutionConfig` (Line 743, 12 lines) - `Get-ExecutionStatistics` (Line 761, 20 lines) - `Get-NextCommand` (Line 150, 41 lines) - `Get-PendingApprovals` (Line 669, 29 lines) - `Get-QueueStatus` (Line 193, 26 lines) - `Invoke-SafeCommandExecution` (Line 445, 142 lines) - `Request-HumanApproval` (Line 589, 78 lines) - `Set-ExecutionConfig` (Line 704, 37 lines) - `Start-ParallelExecution` (Line 255, 142 lines) - `Test-CommandDependencies` (Line 399, 40 lines) 
### CommandTypeHandlers

- **Path:** `Modules\SafeCommandExecution\Core\CommandTypeHandlers.psm1`
- **Size:** 15.11 KB
- **Functions:** 5
- **Lines:** 445
- **Last Modified:** 08/26/2025 11:46:17

**Functions:**
- `Invoke-AnalysisCommand` (Line 310, 82 lines) - `Invoke-BuildCommand` (Line 232, 72 lines) - `Invoke-PowerShellCommand` (Line 164, 62 lines) - `Invoke-TestCommand` (Line 93, 65 lines) - `Invoke-UnityCommand` (Line 23, 64 lines) 
### CompilationIntegration

- **Path:** `Modules\Unity-Claude-UnityParallelization\Core\CompilationIntegration.psm1`
- **Size:** 11.59 KB
- **Functions:** 3
- **Lines:** 300
- **Last Modified:** 08/26/2025 11:46:19

**Functions:**
- `Find-UnityExecutablePath` (Line 137, 44 lines) - `Start-UnityCompilationJob` (Line 22, 113 lines) - `Test-UnityCompilationResult` (Line 183, 66 lines) 
### ConfidenceBands

- **Path:** `Modules\Unity-Claude-CLIOrchestrator\Core\DecisionEngine-Bayesian\ConfidenceBands.psm1`
- **Size:** 4.83 KB
- **Functions:** 2
- **Lines:** 127
- **Last Modified:** 08/26/2025 11:46:18

**Functions:**
- `Calculate-PatternConfidence` (Line 32, 55 lines) - `Get-ConfidenceBand` (Line 9, 20 lines) 
### Configuration

- **Path:** `Modules\Unity-Claude-DocumentationDrift\Core\Configuration.psm1`
- **Size:** 12.68 KB
- **Functions:** 5
- **Lines:** 330
- **Last Modified:** 08/26/2025 11:46:18

**Functions:**
- `Export-DocumentationDriftConfig` (Line 250, 33 lines) - `Get-DocumentationDriftConfig` (Line 115, 22 lines) - `Initialize-DocumentationDrift` (Line 45, 68 lines) - `Reset-DocumentationDriftConfig` (Line 228, 20 lines) - `Set-DocumentationDriftConfig` (Line 139, 87 lines) 
### ConfigurationLogging

- **Path:** `Modules\Unity-Claude-CLIOrchestrator\Core\DecisionEngine\ConfigurationLogging.psm1`
- **Size:** 6.06 KB
- **Functions:** 3
- **Lines:** 179
- **Last Modified:** 08/26/2025 11:46:17

**Functions:**
- `Get-DecisionEngineConfiguration` (Line 95, 5 lines) - `Set-DecisionEngineConfiguration` (Line 103, 11 lines) - `Write-DecisionLog` (Line 117, 18 lines) 
### ConfigurationManagement

- **Path:** `Modules\Unity-Claude-Learning\Core\ConfigurationManagement.psm1`
- **Size:** 10.66 KB
- **Functions:** 9
- **Lines:** 328
- **Last Modified:** 08/26/2025 11:46:19

**Functions:**
- `Export-DatabaseContent` (Line 268, 3 lines) - `Export-JSONPatterns` (Line 273, 3 lines) - `Export-LearningConfiguration` (Line 166, 48 lines) - `Import-LearningConfiguration` (Line 216, 49 lines) - `Import-PatternData` (Line 278, 4 lines) - `Load-LearningConfiguration` (Line 58, 43 lines) - `Save-LearningConfiguration` (Line 26, 30 lines) - `Test-LearningConfiguration` (Line 103, 61 lines) - `Write-ModuleLog` (Line 12, 4 lines) 
### ConfigurationManagement

- **Path:** `Modules\Unity-Claude-NotificationIntegration\Configuration\ConfigurationManagement.psm1`
- **Size:** 10.9 KB
- **Functions:** 6
- **Lines:** 318
- **Last Modified:** 08/21/2025 17:45:27

**Functions:**
- `Export-NotificationConfiguration` (Line 113, 35 lines) - `Get-NotificationConfiguration` (Line 213, 23 lines) - `Import-NotificationConfiguration` (Line 65, 46 lines) - `New-NotificationConfiguration` (Line 7, 56 lines) - `Set-NotificationConfiguration` (Line 238, 32 lines) - `Test-NotificationConfiguration` (Line 150, 61 lines) 
### ContentAnalysis

- **Path:** `Modules\Unity-Claude-DocumentationQualityAssessment\Components\ContentAnalysis.psm1`
- **Size:** 4.1 KB
- **Functions:** 8
- **Lines:** 111
- **Last Modified:** 08/30/2025 19:31:50

**Functions:**
- `Assess-ContentCompleteness` (Line 5, 20 lines) - `Calculate-OverallQualityMetrics` (Line 27, 25 lines) - `Estimate-ImprovementImpact` (Line 103, 3 lines) - `Generate-ClarityRecommendations` (Line 83, 3 lines) - `Generate-CompletenessRecommendations` (Line 88, 3 lines) - `Generate-ImprovementSuggestions` (Line 54, 27 lines) - `Generate-StructureRecommendations` (Line 93, 3 lines) - `Get-PriorityActions` (Line 98, 3 lines) 
### ContextExtraction

- **Path:** `Modules\Unity-Claude-AutonomousAgent\Parsing\ContextExtraction.psm1`
- **Size:** 25.92 KB
- **Functions:** 6
- **Lines:** 707
- **Last Modified:** 08/20/2025 17:25:21

**Functions:**
- `Get-ContextRelevanceScores` (Line 215, 93 lines) - `Get-EntityClusters` (Line 570, 89 lines) - `Get-EntityRelationshipMap` (Line 472, 96 lines) - `Invoke-AdvancedContextExtraction` (Line 113, 100 lines) - `Invoke-ContextIntegration` (Line 399, 71 lines) - `New-ContextItemsFromExtraction` (Line 310, 87 lines) 
### ContextManagement

- **Path:** `Modules\Unity-Claude-NotificationIntegration\Integration\ContextManagement.psm1`
- **Size:** 7 KB
- **Functions:** 5
- **Lines:** 204
- **Last Modified:** 08/21/2025 17:45:27

**Functions:**
- `Add-NotificationContextData` (Line 51, 26 lines) - `Clear-NotificationContext` (Line 89, 11 lines) - `Format-NotificationContext` (Line 102, 55 lines) - `Get-NotificationContext` (Line 79, 8 lines) - `New-NotificationContext` (Line 7, 42 lines) 
### ContextOptimization

- **Path:** `Modules\Unity-Claude-AutonomousAgent\ContextOptimization.psm1`
- **Size:** 49.16 KB
- **Functions:** 22
- **Lines:** 1447
- **Last Modified:** 08/20/2025 17:25:21

**Functions:**
- `Add-ContextItem` (Line 121, 136 lines) - `Add-ConversationPattern` (Line 1056, 90 lines) - `Add-CrossConversationMemory` (Line 1229, 72 lines) - `Calculate-ContextRelevance` (Line 469, 74 lines) - `Calculate-MemoryRelevance` (Line 1324, 31 lines) - `Calculate-PatternSimilarity` (Line 1305, 17 lines) - `Clear-ExpiredSessions` (Line 754, 46 lines) - `Compress-Context` (Line 259, 88 lines) - `Get-ContextSummary` (Line 802, 43 lines) - `Get-CrossConversationMemory` (Line 1148, 79 lines) - `Get-OptimizedContext` (Line 349, 118 lines) - `Get-SessionList` (Line 691, 61 lines) - `Initialize-UserProfile` (Line 849, 105 lines) - `Initialize-WorkingMemory` (Line 54, 65 lines) - `New-SessionIdentifier` (Line 545, 31 lines) - `Restore-SessionState` (Line 629, 60 lines) - `Save-ConversationPatterns` (Line 1372, 8 lines) - `Save-CrossConversationMemory` (Line 1382, 8 lines) - `Save-SessionState` (Line 578, 49 lines) - `Save-UserProfile` (Line 1357, 13 lines) - `Update-UserProfile` (Line 956, 98 lines) - `Write-ContextLog` (Line 27, 25 lines) 
### ConversationCore

- **Path:** `Modules\Unity-Claude-AutonomousAgent\Core\ConversationCore.psm1`
- **Size:** 4.18 KB
- **Functions:** 1
- **Lines:** 89
- **Last Modified:** 08/26/2025 11:46:17

**Functions:**
- `Write-StateLog` (Line 26, 25 lines) 
### ConversationStateManager-Refactored

- **Path:** `Modules\Unity-Claude-AutonomousAgent\ConversationStateManager-Refactored.psm1`
- **Size:** 12.5 KB
- **Functions:** 5
- **Lines:** 329
- **Last Modified:** 08/26/2025 11:46:17

**Functions:**
- `Get-ConversationStateManagerComponents` (Line 23, 23 lines) - `Get-ConversationSummary` (Line 206, 40 lines) - `Initialize-CompleteConversationSystem` (Line 147, 57 lines) - `Invoke-ConversationStateManagerDiagnostics` (Line 95, 50 lines) - `Test-ConversationStateManagerHealth` (Line 48, 45 lines) 
### ConversationStateManager

- **Path:** `Modules\Unity-Claude-AutonomousAgent\ConversationStateManager.psm1`
- **Size:** 46.97 KB
- **Functions:** 22
- **Lines:** 1410
- **Last Modified:** 08/26/2025 11:46:17

**Functions:**
- `Add-ConversationGoal` (Line 832, 75 lines) - `Add-ConversationHistoryItem` (Line 385, 80 lines) - `Add-RoleAwareHistoryItem` (Line 909, 93 lines) - `Calculate-GoalRelevance` (Line 1237, 24 lines) - `Clear-ConversationHistory` (Line 632, 40 lines) - `Get-ConversationContext` (Line 530, 100 lines) - `Get-ConversationGoals` (Line 1169, 64 lines) - `Get-ConversationHistory` (Line 467, 61 lines) - `Get-ConversationState` (Line 288, 62 lines) - `Get-RoleAwareHistory` (Line 1098, 69 lines) - `Get-SessionMetadata` (Line 720, 55 lines) - `Get-ValidStateTransitions` (Line 352, 31 lines) - `Initialize-ConversationState` (Line 63, 132 lines) - `Reset-ConversationState` (Line 777, 51 lines) - `Save-ConversationGoals` (Line 1345, 8 lines) - `Save-ConversationHistory` (Line 696, 22 lines) - `Save-ConversationState` (Line 674, 20 lines) - `Set-ConversationState` (Line 197, 89 lines) - `Update-ConversationEffectiveness` (Line 1314, 29 lines) - `Update-ConversationGoal` (Line 1004, 92 lines) - `Update-DialoguePatterns` (Line 1263, 49 lines) - `Write-StateLog` (Line 36, 25 lines) 
### CoreUtilities

- **Path:** `Modules\Unity-Claude-AutonomousStateTracker-Enhanced\Core\CoreUtilities.psm1`
- **Size:** 13.24 KB
- **Functions:** 6
- **Lines:** 373
- **Last Modified:** 08/26/2025 11:46:17

**Functions:**
- `ConvertTo-HashTable` (Line 8, 57 lines) - `Get-SafeDateTime` (Line 67, 40 lines) - `Get-SystemPerformanceMetrics` (Line 217, 77 lines) - `Get-UptimeMinutes` (Line 109, 39 lines) - `Test-SystemHealthThresholds` (Line 296, 30 lines) - `Write-EnhancedStateLog` (Line 150, 65 lines) 
### CPG-AdvancedEdges

- **Path:** `Modules\Unity-Claude-CPG\Core\CPG-AdvancedEdges.psm1`
- **Size:** 25.39 KB
- **Functions:** 30
- **Lines:** 824
- **Last Modified:** 08/28/2025 01:39:17

**Functions:**
- `AddInheritedMember` (Line 193, 2 lines, 1 params) - `AddOverriddenMember` (Line 197, 2 lines, 1 params) - `AddTransformation` (Line 95, 3 lines, 1 params) - `AnalyzeComposition` (Line 317, 10 lines) - `AnalyzeControlFlow` (Line 151, 9 lines) - `AnalyzeFlow` (Line 100, 9 lines) - `AnalyzeImplementation` (Line 260, 11 lines) - `AnalyzeInheritance` (Line 201, 10 lines) - `Build-Hierarchy` (Line 569, 24 lines) - `CompositionEdge` (Line 292, 15 lines, 3 params) - `ControlFlowEdge` (Line 129, 15 lines, 3 params) - `ConvertTo-MermaidDiagram` (Line 699, 73 lines) - `DataFlowEdge` (Line 80, 13 lines, 3 params) - `Find-Path` (Line 467, 23 lines) - `Get-Components` (Line 661, 31 lines) - `Get-CompositionStructure` (Line 644, 52 lines) - `Get-ControlFlowGraph` (Line 496, 56 lines) - `Get-DataFlowPaths` (Line 454, 40 lines) - `Get-InheritanceHierarchy` (Line 554, 43 lines) - `Get-InterfaceCompliance` (Line 599, 43 lines) - `ImplementationEdge` (Line 232, 14 lines, 3 params) - `InheritanceEdge` (Line 181, 10 lines, 3 params) - `New-CompositionEdge` (Line 427, 24 lines) - `New-ControlFlowEdge` (Line 355, 20 lines) - `New-DataFlowEdge` (Line 331, 22 lines) - `New-ImplementationEdge` (Line 403, 22 lines) - `New-InheritanceEdge` (Line 377, 24 lines) - `SetCardinality` (Line 309, 6 lines, 1 params) - `SetCondition` (Line 146, 3 lines, 1 params) - `ValidateImplementation` (Line 248, 10 lines) 
### CPG-AnalysisOperations

- **Path:** `Modules\Unity-Claude-CPG\Core\CPG-AnalysisOperations.psm1`
- **Size:** 9.03 KB
- **Functions:** 5
- **Lines:** 284
- **Last Modified:** 08/26/2025 11:46:18

**Functions:**
- `Find-CPGCycles` (Line 183, 55 lines) - `Find-CyclesDFS` (Line 200, 29 lines, 2 params) - `Get-CPGComplexityMetrics` (Line 149, 32 lines) - `Get-CPGStatistics` (Line 19, 84 lines) - `Test-CPGStronglyConnected` (Line 105, 42 lines) 
### CPG-BasicOperations

- **Path:** `Modules\Unity-Claude-CPG\Core\CPG-BasicOperations.psm1`
- **Size:** 6.78 KB
- **Functions:** 5
- **Lines:** 220
- **Last Modified:** 08/26/2025 11:46:18

**Functions:**
- `Add-CPGEdge` (Line 132, 41 lines) - `Add-CPGNode` (Line 103, 27 lines) - `New-CPGEdge` (Line 55, 29 lines) - `New-CPGNode` (Line 19, 34 lines) - `New-CPGraph` (Line 86, 15 lines) 
### CPG-CallGraphBuilder

- **Path:** `Modules\Unity-Claude-CPG\Core\CPG-CallGraphBuilder.psm1`
- **Size:** 24.92 KB
- **Functions:** 16
- **Lines:** 670
- **Last Modified:** 08/28/2025 02:52:38

**Functions:**
- `AddCallEdge` (Line 177, 24 lines, 1 params) - `AddCallNode` (Line 169, 6 lines, 1 params) - `Build-PowerShellCallGraph` (Line 260, 147 lines) - `CallEdge` (Line 119, 9 lines, 3 params) - `CallGraph` (Line 149, 18 lines, 1 params) - `CallNode` (Line 83, 7 lines, 2 params) - `DetectRecursion` (Line 203, 32 lines, 1 params) - `Export-CallGraph` (Line 522, 104 lines) - `Get-CallGraphMetrics` (Line 456, 63 lines) - `GetCallStatistics` (Line 250, 6 lines) - `GetSignature` (Line 92, 9 lines) - `IncrementFrequency` (Line 130, 3 lines) - `MarkRecursive` (Line 237, 11 lines, 1 params) - `Resolve-VirtualMethodCalls` (Line 410, 43 lines) - `Test-Cycle` (Line 208, 24 lines) - `Write-CPGDebug` (Line 32, 9 lines) 
### CPG-DataFlowTracker

- **Path:** `Modules\Unity-Claude-CPG\Core\CPG-DataFlowTracker.psm1`
- **Size:** 31.56 KB
- **Functions:** 22
- **Lines:** 847
- **Last Modified:** 08/28/2025 03:02:56

**Functions:**
- `AddDefinition` (Line 203, 15 lines, 1 params) - `AddDefinition` (Line 134, 3 lines, 1 params) - `AddPropagation` (Line 161, 3 lines, 1 params) - `AddUse` (Line 115, 3 lines, 1 params) - `AddUse` (Line 220, 12 lines, 1 params) - `Analyze-DataSensitivity` (Line 565, 53 lines) - `Build-PowerShellDataFlow` (Line 314, 152 lines) - `Compute-LiveVariables` (Line 469, 93 lines) - `DataFlowGraph` (Line 182, 19 lines, 1 params) - `DefUseChain` (Line 107, 6 lines, 2 params) - `Export-DataFlow` (Line 678, 124 lines) - `Get-DataFlowMetrics` (Line 621, 54 lines) - `GetDataFlowStatistics` (Line 307, 3 lines) - `GetReachingDefinitions` (Line 253, 11 lines, 2 params) - `LinkUseWithDefinitions` (Line 234, 17 lines, 1 params) - `MarkTainted` (Line 266, 9 lines, 3 params) - `PropagateTaint` (Line 277, 28 lines, 1 params) - `TaintInfo` (Line 150, 9 lines, 3 params) - `UseDefChain` (Line 127, 5 lines, 2 params) - `VariableDefinition` (Line 70, 7 lines, 2 params) - `VariableUse` (Line 90, 7 lines, 3 params) - `Write-CPGDebug` (Line 21, 9 lines) 
### CPG-DataStructures

- **Path:** `Modules\Unity-Claude-CPG\Core\CPG-DataStructures.psm1`
- **Size:** 8.78 KB
- **Functions:** 13
- **Lines:** 279
- **Last Modified:** 08/26/2025 11:46:18

**Functions:**
- `CPGEdge` (Line 136, 7 lines) - `CPGEdge` (Line 145, 10 lines, 3 params) - `CPGNode` (Line 84, 6 lines) - `CPGNode` (Line 92, 8 lines, 2 params) - `CPGraph` (Line 187, 9 lines) - `CPGraph` (Line 198, 10 lines, 1 params) - `ToHashtable` (Line 106, 16 lines) - `ToHashtable` (Line 161, 12 lines) - `ToHashtable` (Line 219, 11 lines) - `ToString` (Line 102, 2 lines) - `ToString` (Line 157, 2 lines) - `ToString` (Line 215, 2 lines) - `UpdateModifiedTime` (Line 210, 3 lines) 
### CPG-QueryOperations

- **Path:** `Modules\Unity-Claude-CPG\Core\CPG-QueryOperations.psm1`
- **Size:** 11.65 KB
- **Functions:** 4
- **Lines:** 374
- **Last Modified:** 08/26/2025 11:46:18

**Functions:**
- `Find-CPGPath` (Line 219, 109 lines) - `Get-CPGEdge` (Line 74, 53 lines) - `Get-CPGNeighbors` (Line 129, 88 lines) - `Get-CPGNode` (Line 19, 53 lines) 
### CPG-SerializationOperations

- **Path:** `Modules\Unity-Claude-CPG\Core\CPG-SerializationOperations.psm1`
- **Size:** 10.24 KB
- **Functions:** 4
- **Lines:** 318
- **Last Modified:** 08/26/2025 11:46:18

**Functions:**
- `Export-CPGraph` (Line 19, 80 lines) - `Export-ToDOT` (Line 246, 28 lines) - `Export-ToGraphML` (Line 196, 48 lines) - `Import-CPGraph` (Line 101, 93 lines) 
### CPG-ThreadSafeOperations

- **Path:** `Modules\Unity-Claude-CPG\Core\CPG-ThreadSafeOperations.psm1`
- **Size:** 25.68 KB
- **Functions:** 12
- **Lines:** 832
- **Last Modified:** 08/28/2025 01:31:30

**Functions:**
- `Add-CPGEdgeThreadSafe` (Line 420, 67 lines) - `Add-CPGNodeThreadSafe` (Line 116, 67 lines) - `Get-CPGNodeThreadSafe` (Line 191, 53 lines) - `Get-CPGThreadStatistics` (Line 670, 22 lines) - `Invoke-CPGReadOperation` (Line 567, 41 lines) - `Invoke-CPGWriteOperation` (Line 616, 42 lines) - `New-ThreadSafeCPG` (Line 69, 35 lines) - `Remove-CPGEdgeThreadSafe` (Line 495, 60 lines) - `Remove-CPGNodeThreadSafe` (Line 328, 80 lines) - `Test-CPGThreadSafety` (Line 700, 114 lines) - `Update-CPGNodeThreadSafe` (Line 252, 68 lines) - `Write-CPGLog` (Line 38, 18 lines) 
### CPG-Unified

- **Path:** `Modules\Unity-Claude-CPG\Core\CPG-Unified.psm1`
- **Size:** 26.53 KB
- **Functions:** 41
- **Lines:** 818
- **Last Modified:** 08/28/2025 01:46:56

**Functions:**
- `AddInheritedMember` (Line 407, 2 lines, 1 params) - `AddOverriddenMember` (Line 411, 2 lines, 1 params) - `AddTransformation` (Line 333, 5 lines, 1 params) - `AnalyzeComposition` (Line 505, 10 lines) - `AnalyzeControlFlow` (Line 378, 9 lines) - `AnalyzeFlow` (Line 340, 9 lines) - `AnalyzeImplementation` (Line 461, 11 lines) - `AnalyzeInheritance` (Line 415, 10 lines) - `Clear-CPGDebugLog` (Line 740, 3 lines) - `CompositionEdge` (Line 485, 10 lines, 3 params) - `ControlFlowEdge` (Line 361, 10 lines, 3 params) - `CPGEdge` (Line 214, 7 lines) - `CPGEdge` (Line 223, 10 lines, 3 params) - `CPGNode` (Line 168, 9 lines, 2 params) - `CPGNode` (Line 159, 7 lines) - `CPGraph` (Line 266, 9 lines) - `CPGraph` (Line 277, 10 lines, 1 params) - `DataFlowEdge` (Line 322, 9 lines, 3 params) - `Get-CPGDebugLog` (Line 735, 2 lines) - `ImplementationEdge` (Line 438, 9 lines, 3 params) - `InheritanceEdge` (Line 400, 5 lines, 3 params) - `New-CompositionEdge` (Line 689, 24 lines) - `New-ControlFlowEdge` (Line 617, 20 lines) - `New-CPGEdge` (Line 558, 20 lines) - `New-CPGNode` (Line 520, 35 lines) - `New-CPGraph` (Line 717, 15 lines) - `New-DataFlowEdge` (Line 582, 33 lines) - `New-ImplementationEdge` (Line 665, 22 lines) - `New-InheritanceEdge` (Line 639, 24 lines) - `Set-CPGDebug` (Line 746, 7 lines) - `SetCardinality` (Line 497, 6 lines, 1 params) - `SetCondition` (Line 373, 3 lines, 1 params) - `ToHashtable` (Line 298, 11 lines) - `ToHashtable` (Line 239, 12 lines) - `ToHashtable` (Line 183, 16 lines) - `ToString` (Line 294, 2 lines) - `ToString` (Line 235, 2 lines) - `ToString` (Line 179, 2 lines) - `UpdateModifiedTime` (Line 289, 3 lines) - `ValidateImplementation` (Line 449, 10 lines) - `Write-CPGDebug` (Line 18, 24 lines) 
### CrossLanguage-DependencyMaps

- **Path:** `Modules\Unity-Claude-CPG\Core\CrossLanguage-DependencyMaps.psm1`
- **Size:** 46.43 KB
- **Functions:** 58
- **Lines:** 1344
- **Last Modified:** 08/28/2025 11:34:01

**Functions:**
- `AddNode` (Line 102, 4 lines, 1 params) - `AddNode` (Line 246, 4 lines, 1 params) - `AddReference` (Line 252, 19 lines, 1 params) - `AddRelation` (Line 108, 2 lines, 1 params) - `AnalyzeDependencyPatterns` (Line 811, 22 lines) - `BuildDependencyMatrix` (Line 285, 21 lines) - `BuildDependencyNodes` (Line 425, 33 lines) - `CalculateFunctionConfidence` (Line 774, 23 lines, 4 params) - `CalculateGraphDensity` (Line 308, 8 lines) - `CalculateImportConfidence` (Line 617, 18 lines, 4 params) - `CalculateStringSimilarity` (Line 879, 9 lines, 2 params) - `CircularDependencyDetector` (Line 921, 3 lines, 1 params) - `CrossLanguageReference` (Line 166, 10 lines, 5 params) - `CrossLanguageReferenceResolver` (Line 360, 6 lines, 1 params) - `DependencyGraph` (Line 228, 16 lines, 1 params) - `DependencyNode` (Line 194, 16 lines, 4 params) - `DependencyVisualizer` (Line 1005, 9 lines, 1 params) - `Detect-CircularDependencies` (Line 1244, 23 lines) - `DetectAllCycles` (Line 926, 11 lines) - `DetectCircularDependencies` (Line 835, 17 lines) - `DetectComplexCycles` (Line 994, 3 lines) - `DFSCycleDetection` (Line 854, 23 lines, 4 params) - `Export-DependencyReport` (Line 1269, 49 lines) - `ExtractFunctionName` (Line 744, 10 lines, 2 params) - `ExtractImportName` (Line 552, 35 lines, 2 params) - `FindCallNodes` (Line 701, 13 lines, 2 params) - `FindImportNodes` (Line 493, 27 lines, 2 params) - `FindMatchingExports` (Line 589, 26 lines, 3 params) - `FindMatchingFunctions` (Line 756, 16 lines, 3 params) - `Generate-DependencyGraph` (Line 1213, 29 lines) - `GenerateDotDiagram` (Line 1067, 26 lines) - `GenerateJsonGraph` (Line 1095, 32 lines) - `GenerateMermaidDiagram` (Line 1027, 38 lines) - `GenerateVisualization` (Line 1016, 9 lines, 1 params) - `GetAllNodes` (Line 112, 2 lines) - `GetAllRelations` (Line 116, 2 lines) - `GetLanguageCompatibility` (Line 637, 30 lines, 2 params) - `GetTopologicalOrdering` (Line 318, 32 lines) - `InitializeReferencePatterns` (Line 368, 23 lines) - `LevenshteinDistance` (Line 890, 23 lines, 2 params) - `Resolve-CrossLanguageReferences` (Line 1131, 33 lines) - `ResolveAllReferences` (Line 393, 30 lines) - `ResolveDataFlowReferences` (Line 805, 4 lines) - `ResolveFunctionCallReferences` (Line 669, 30 lines) - `ResolveFunctionTarget` (Line 716, 26 lines, 2 params) - `ResolveImportExportReferences` (Line 460, 31 lines) - `ResolveImportTarget` (Line 522, 28 lines, 2 params) - `ResolveInheritanceReferences` (Line 799, 4 lines) - `StrongConnect` (Line 953, 39 lines, 6 params) - `TarjanSCC` (Line 939, 12 lines) - `ToString` (Line 178, 2 lines) - `Track-ImportExport` (Line 1166, 45 lines) - `UnifiedCPG` (Line 95, 5 lines, 1 params) - `UnifiedNode` (Line 60, 6 lines, 3 params) - `UnifiedRelation` (Line 78, 7 lines, 4 params) - `UpdateLanguageStats` (Line 273, 10 lines, 1 params) - `UpdateMetrics` (Line 212, 4 lines) - `Write-CPGDebug` (Line 1321, 14 lines) 
### CrossLanguage-GraphMerger

- **Path:** `Modules\Unity-Claude-CPG\Core\CrossLanguage-GraphMerger.psm1`
- **Size:** 39.26 KB
- **Functions:** 56
- **Lines:** 1184
- **Last Modified:** 08/28/2025 12:05:31

**Functions:**
- `AddNode` (Line 28, 4 lines, 1 params) - `AddRelation` (Line 34, 2 lines, 1 params) - `AttemptConflictMerge` (Line 707, 3 lines, 1 params) - `CalculateNodeSimilarity` (Line 917, 7 lines, 2 params) - `CalculateNodeSimilarity` (Line 420, 27 lines, 2 params) - `CalculateSignatureSimilarity` (Line 485, 13 lines, 2 params) - `CalculateStringSimilarity` (Line 449, 9 lines, 2 params) - `ConflictDetector` (Line 799, 2 lines) - `ConsolidateDuplicateRelationships` (Line 751, 20 lines) - `Create-MergedCPG` (Line 1123, 35 lines) - `CreateUnifiedNode` (Line 401, 3 lines, 2 params) - `Detect-Duplicates` (Line 1067, 54 lines) - `DetectDuplicateNodes` (Line 888, 27 lines, 1 params) - `DetectNamingConflicts` (Line 803, 33 lines, 1 params) - `DetectSignatureConflicts` (Line 845, 5 lines, 1 params) - `DetectTypeConflicts` (Line 838, 5 lines, 1 params) - `DuplicateDetector` (Line 884, 2 lines, 1 params) - `ExtractNamespaces` (Line 295, 12 lines, 2 params) - `FindEquivalentNodes` (Line 406, 12 lines, 1 params) - `FlagForManualReview` (Line 594, 16 lines, 3 params) - `GetAllNodes` (Line 38, 2 lines) - `GetAllRelations` (Line 42, 2 lines) - `GetMergeReport` (Line 784, 8 lines) - `GraphMerger` (Line 206, 16 lines, 2 params) - `HandleNodeEquivalents` (Line 500, 58 lines, 3 params) - `HasDuplicateRelationship` (Line 670, 9 lines, 1 params) - `InitializeStatistics` (Line 224, 17 lines) - `LanguageMapper` (Line 139, 2 lines, 1 params) - `LevenshteinDistance` (Line 460, 23 lines, 2 params) - `MapNamespace` (Line 309, 20 lines, 2 params) - `MapToUnified` (Line 143, 25 lines, 1 params) - `Merge-LanguageGraphs` (Line 928, 53 lines) - `Merge-Namespaces` (Line 1048, 17 lines) - `MergeAllNodes` (Line 331, 25 lines) - `MergeAllRelationships` (Line 627, 16 lines) - `MergeGraphs` (Line 243, 32 lines) - `MergeNamespaces` (Line 863, 9 lines, 1 params) - `MergeNode` (Line 358, 41 lines, 2 params) - `MergeNodes` (Line 560, 32 lines, 2 params) - `MergeRelationship` (Line 645, 23 lines, 2 params) - `NamespaceMerger` (Line 858, 3 lines, 1 params) - `OptimizeMergedGraph` (Line 712, 11 lines) - `PrepareNamespaces` (Line 277, 16 lines) - `ProcessLanguageNamespaces` (Line 874, 3 lines, 2 params) - `RemoveNode` (Line 46, 2 lines, 1 params) - `RemoveOrphanedNodes` (Line 725, 24 lines) - `RemoveRelation` (Line 50, 5 lines, 1 params) - `Resolve-NamingConflicts` (Line 983, 63 lines) - `ResolveByBestConfidence` (Line 702, 3 lines, 1 params) - `ResolveConflicts` (Line 681, 19 lines) - `UnifiedCPG` (Line 21, 5 lines, 1 params) - `UnifiedNode` (Line 107, 6 lines, 3 params) - `UnifiedRelation` (Line 125, 7 lines, 4 params) - `UpdateConfidenceStats` (Line 612, 13 lines, 1 params) - `UpdateGraphMetrics` (Line 773, 9 lines) - `Write-CPGDebug` (Line 1161, 14 lines) 
### CrossLanguage-UnifiedModel

- **Path:** `Modules\Unity-Claude-CPG\Core\CrossLanguage-UnifiedModel.psm1`
- **Size:** 28.62 KB
- **Functions:** 31
- **Lines:** 871
- **Last Modified:** 08/28/2025 12:07:12

**Functions:**
- `ExtractImportTarget` (Line 654, 32 lines, 1 params) - `ExtractNamespace` (Line 645, 7 lines, 2 params) - `GenerateFullyQualifiedName` (Line 461, 12 lines, 2 params) - `Get-CrossLanguageRelations` (Line 799, 11 lines) - `Get-UnifiedNodes` (Line 763, 34 lines) - `GetDisplayName` (Line 149, 5 lines) - `GetMappingConfidence` (Line 360, 19 lines, 3 params) - `GetMetadata` (Line 223, 13 lines) - `GetMetadata` (Line 156, 12 lines) - `InitializeMappings` (Line 249, 80 lines) - `IsCrossLanguage` (Line 219, 2 lines) - `IsEquivalentTo` (Line 170, 15 lines, 1 params) - `LanguageMapper` (Line 245, 2 lines) - `MapToUnifiedType` (Line 331, 27 lines, 2 params) - `New-UnifiedCPG` (Line 690, 71 lines) - `New-UnifiedNode` (Line 812, 42 lines) - `NodeNormalizer` (Line 415, 2 lines) - `NormalizeNode` (Line 419, 32 lines, 1 params) - `NormalizeNodeCollection` (Line 453, 6 lines, 1 params) - `NormalizeTypeName` (Line 381, 27 lines, 2 params) - `RelationshipResolver` (Line 480, 2 lines) - `ResolveCallRelationships` (Line 564, 26 lines, 1 params) - `ResolveContainmentRelationships` (Line 503, 29 lines, 1 params) - `ResolveEquivalencyRelationships` (Line 617, 26 lines, 1 params) - `ResolveImportRelationships` (Line 592, 23 lines, 1 params) - `ResolveInheritanceRelationships` (Line 534, 28 lines, 1 params) - `ResolveRelationships` (Line 484, 17 lines, 1 params) - `UnifiedNode` (Line 137, 10 lines, 3 params) - `UnifiedNode` (Line 128, 7 lines) - `UnifiedRelation` (Line 208, 9 lines, 3 params) - `UnifiedRelation` (Line 200, 6 lines) 
### DatabaseManagement

- **Path:** `Modules\Unity-Claude-HITL\Core\DatabaseManagement.psm1`
- **Size:** 8.13 KB
- **Functions:** 2
- **Lines:** 215
- **Last Modified:** 08/26/2025 11:46:18

**Functions:**
- `Initialize-ApprovalDatabase` (Line 14, 116 lines) - `Test-DatabaseConnection` (Line 132, 37 lines) 
### DatabaseManagement

- **Path:** `Modules\Unity-Claude-Learning\Core\DatabaseManagement.psm1`
- **Size:** 7.55 KB
- **Functions:** 1
- **Lines:** 196
- **Last Modified:** 08/26/2025 11:46:19

**Functions:**
- `Initialize-LearningDatabase` (Line 11, 143 lines) 
### DecisionEngine-Bayesian

- **Path:** `Modules\Unity-Claude-CLIOrchestrator\Core\DecisionEngine-Bayesian.psm1`
- **Size:** 45.26 KB
- **Functions:** 20
- **Lines:** 1319
- **Last Modified:** 08/26/2025 11:46:17

**Functions:**
- `Add-TemporalContext` (Line 992, 68 lines) - `Build-EntityRelationshipGraph` (Line 755, 100 lines) - `Build-NGramModel` (Line 558, 61 lines) - `Calculate-BayesianEvidence` (Line 214, 27 lines) - `Calculate-BayesianLikelihood` (Line 183, 28 lines) - `Calculate-BayesianUncertainty` (Line 292, 32 lines) - `Calculate-ContextualAdjustment` (Line 244, 45 lines) - `Calculate-PatternConfidence` (Line 354, 55 lines) - `Calculate-PatternSimilarity` (Line 622, 83 lines) - `Find-EntityCluster` (Line 858, 37 lines) - `Get-BayesianPrior` (Line 152, 28 lines) - `Get-ConfidenceBand` (Line 331, 20 lines) - `Get-LevenshteinDistance` (Line 708, 40 lines) - `Get-TemporalContextRelevance` (Line 1063, 54 lines) - `Initialize-BayesianLearning` (Line 514, 37 lines) - `Invoke-BayesianConfidenceAdjustment` (Line 66, 83 lines) - `Invoke-EnhancedPatternAnalysis` (Line 1124, 111 lines) - `Measure-EntityProximity` (Line 898, 74 lines) - `Save-BayesianLearning` (Line 487, 24 lines) - `Update-BayesianLearning` (Line 416, 68 lines) 
### DecisionEngine-Refactored

- **Path:** `Modules\Unity-Claude-CLIOrchestrator\Core\DecisionEngine-Refactored.psm1`
- **Size:** 13.89 KB
- **Functions:** 4
- **Lines:** 362
- **Last Modified:** 08/26/2025 11:46:17

**Functions:**
- `Get-DecisionEngineStatistics` (Line 180, 50 lines) - `Initialize-DecisionEngine` (Line 43, 43 lines) - `Invoke-EnhancedDecisionProcessing` (Line 233, 60 lines) - `Test-DecisionEngineHealth` (Line 89, 88 lines) 
### DecisionEngine

- **Path:** `Modules\Unity-Claude-CLIOrchestrator\Core\DecisionEngine.psm1`
- **Size:** 33.98 KB
- **Functions:** 11
- **Lines:** 936
- **Last Modified:** 08/26/2025 22:10:29

**Functions:**
- `Get-ActionQueueStatus` (Line 733, 38 lines) - `Invoke-GracefulDegradation` (Line 831, 50 lines) - `Invoke-RuleBasedDecision` (Line 130, 103 lines) - `New-ActionQueueItem` (Line 646, 84 lines) - `Resolve-ConflictingRecommendations` (Line 778, 50 lines) - `Resolve-PriorityDecision` (Line 236, 103 lines) - `Test-ActionQueueCapacity` (Line 630, 13 lines) - `Test-SafeCommand` (Line 554, 65 lines) - `Test-SafeFilePath` (Line 484, 67 lines) - `Test-SafetyValidation` (Line 346, 135 lines) - `Write-DecisionLog` (Line 105, 18 lines) 
### DecisionEngineCore

- **Path:** `Modules\Unity-Claude-DecisionEngine\Core\DecisionEngineCore.psm1`
- **Size:** 6.91 KB
- **Functions:** 7
- **Lines:** 213
- **Last Modified:** 08/26/2025 11:46:18

**Functions:**
- `Add-DecisionToHistory` (Line 143, 16 lines) - `Clear-DecisionHistory` (Line 133, 8 lines) - `Get-DecisionEngineConfig` (Line 83, 6 lines) - `Get-DecisionHistory` (Line 116, 15 lines) - `Set-DecisionEngineConfig` (Line 91, 19 lines) - `Test-RequiredModule` (Line 64, 13 lines) - `Write-DecisionEngineLog` (Line 25, 37 lines) 
### DecisionEngineIntegration

- **Path:** `Modules\Unity-Claude-CLIOrchestrator\Core\DecisionEngineIntegration.psm1`
- **Size:** 23.33 KB
- **Functions:** 12
- **Lines:** 620
- **Last Modified:** 08/25/2025 13:45:24

**Functions:**
- `Get-CircuitBreakerName` (Line 367, 10 lines) - `Get-ConsecutiveFailureCount` (Line 424, 6 lines) - `Get-CurrentMetrics` (Line 380, 24 lines) - `Get-DegradedDecision` (Line 446, 13 lines) - `Get-EscalationLevelName` (Line 433, 10 lines) - `Get-FallbackDecision` (Line 462, 13 lines) - `Get-IntegrationStatistics` (Line 482, 42 lines) - `Get-RecentFailureCount` (Line 417, 4 lines) - `Get-SystemLoad` (Line 407, 7 lines) - `Invoke-IntegratedDecision` (Line 123, 237 lines) - `Reset-IntegrationMetrics` (Line 527, 16 lines) - `Write-IntegrationLog` (Line 97, 19 lines) 
### DecisionExecution-Fixed

- **Path:** `Modules\Unity-Claude-CLIOrchestrator\Core\OrchestrationComponents\DecisionExecution-Fixed.psm1`
- **Size:** 4.86 KB
- **Functions:** 2
- **Lines:** 147
- **Last Modified:** 08/27/2025 17:21:44

**Functions:**
- `Execute-TestAction` (Line 84, 61 lines) - `Invoke-DecisionExecution` (Line 4, 78 lines) 
### DecisionExecution

- **Path:** `Modules\Unity-Claude-MasterOrchestrator\Core\DecisionExecution.psm1`
- **Size:** 12.2 KB
- **Functions:** 12
- **Lines:** 341
- **Last Modified:** 08/26/2025 11:46:19

**Functions:**
- `Invoke-ApprovalRequest` (Line 260, 15 lines) - `Invoke-CommandExecution` (Line 175, 11 lines) - `Invoke-CommandValidation` (Line 188, 11 lines) - `Invoke-ConversationContinuation` (Line 201, 21 lines) - `Invoke-DecisionExecution` (Line 19, 90 lines) - `Invoke-ErrorAnalysis` (Line 236, 10 lines) - `Invoke-MonitoringContinuation` (Line 277, 10 lines) - `Invoke-RecommendationExecution` (Line 151, 10 lines) - `Invoke-ResponseGeneration` (Line 224, 10 lines) - `Invoke-SafetyValidation` (Line 111, 38 lines) - `Invoke-TestExecution` (Line 163, 10 lines) - `Invoke-WorkflowContinuation` (Line 248, 10 lines) 
### DecisionExecution

- **Path:** `Modules\Unity-Claude-CLIOrchestrator\Core\OrchestrationComponents\DecisionExecution.psm1`
- **Size:** 10.67 KB
- **Functions:** 6
- **Lines:** 369
- **Last Modified:** 08/27/2025 15:21:30

**Functions:**
- `Execute-RecommendedAction` (Line 254, 54 lines) - `Execute-SummaryAction` (Line 310, 56 lines) - `Execute-TestAction` (Line 99, 60 lines) - `Execute-ValidationAction` (Line 161, 47 lines) - `Invoke-DecisionExecution` (Line 4, 93 lines) - `Submit-TestResultsToClaude` (Line 210, 42 lines) 
### DecisionMaking-Fixed

- **Path:** `Modules\Unity-Claude-CLIOrchestrator\Core\OrchestrationComponents\DecisionMaking-Fixed.psm1`
- **Size:** 7.61 KB
- **Functions:** 3
- **Lines:** 218
- **Last Modified:** 08/27/2025 17:21:22

**Functions:**
- `Invoke-AutonomousDecisionMaking` (Line 103, 79 lines) - `Invoke-ComprehensiveResponseAnalysis` (Line 4, 97 lines) - `Test-DecisionSafety` (Line 185, 31 lines) 
### DecisionMaking

- **Path:** `Modules\Unity-Claude-DecisionEngine\Core\DecisionMaking.psm1`
- **Size:** 14.17 KB
- **Functions:** 4
- **Lines:** 386
- **Last Modified:** 08/26/2025 11:46:18

**Functions:**
- `Apply-ContextualAdjustments` (Line 186, 74 lines) - `Invoke-AutonomousDecision` (Line 13, 67 lines) - `Invoke-DecisionTree` (Line 86, 94 lines) - `Invoke-DecisionValidation` (Line 262, 79 lines) 
### DecisionMaking

- **Path:** `Modules\Unity-Claude-CLIOrchestrator\Core\OrchestrationComponents\DecisionMaking.psm1`
- **Size:** 9.43 KB
- **Functions:** 3
- **Lines:** 262
- **Last Modified:** 08/27/2025 15:21:21

**Functions:**
- `Invoke-AutonomousDecisionMaking` (Line 103, 106 lines) - `Invoke-ComprehensiveResponseAnalysis` (Line 4, 97 lines) - `Test-DecisionSafety` (Line 211, 48 lines) 
### DepaAlgorithm

- **Path:** `Modules\Unity-Claude-CPG\Core\DepaAlgorithm.psm1`
- **Size:** 13.6 KB
- **Functions:** 3
- **Lines:** 353
- **Last Modified:** 08/26/2025 11:46:18

**Functions:**
- `Get-CodePerplexity` (Line 42, 203 lines) - `Get-LinePerplexity` (Line 250, 23 lines) - `Test-DeadProgramArtifacts` (Line 275, 34 lines) 
### DependencyManagement

- **Path:** `Modules\Unity-Claude-IntegratedWorkflow\Core\DependencyManagement.psm1`
- **Size:** 7.8 KB
- **Functions:** 5
- **Lines:** 174
- **Last Modified:** 08/26/2025 11:46:18

**Functions:**
- `Assert-Dependencies` (Line 113, 10 lines) - `Get-ModuleAvailability` (Line 126, 2 lines) - `Initialize-RequiredModules` (Line 39, 56 lines) - `Test-ModuleDependencies` (Line 98, 12 lines) - `Test-ModuleDependencyAvailability` (Line 16, 20 lines) 
### DocumentationAccuracy

- **Path:** `Modules\Unity-Claude-CPG\Core\DocumentationAccuracy.psm1`
- **Size:** 25.41 KB
- **Functions:** 10
- **Lines:** 685
- **Last Modified:** 08/26/2025 11:46:18

**Functions:**
- `Generate-DocumentationActionPlan` (Line 558, 62 lines) - `Generate-ExampleSuggestion` (Line 534, 22 lines) - `Generate-NodeSuggestions` (Line 440, 92 lines) - `Get-NodeDocumentation` (Line 622, 16 lines) - `Test-BehaviorAccuracy` (Line 405, 33 lines) - `Test-DocumentationAccuracy` (Line 42, 143 lines) - `Test-ExampleAccuracy` (Line 365, 38 lines) - `Test-ParameterAccuracy` (Line 286, 45 lines) - `Test-ReturnTypeAccuracy` (Line 333, 30 lines) - `Update-DocumentationSuggestions` (Line 187, 95 lines) 
### DocumentationComparison

- **Path:** `Modules\Unity-Claude-CPG\Core\DocumentationComparison.psm1`
- **Size:** 22.14 KB
- **Functions:** 6
- **Lines:** 596
- **Last Modified:** 08/26/2025 11:46:18

**Functions:**
- `Compare-CodeToDocumentation` (Line 42, 168 lines) - `Find-UndocumentedFeatures` (Line 212, 126 lines) - `Get-DocumentationPriority` (Line 492, 39 lines) - `Get-DocumentationScore` (Line 442, 48 lines) - `Get-MissingDocumentationElements` (Line 533, 18 lines) - `Get-NodeDocumentation` (Line 340, 100 lines) 
### EnhancedPatternIntegration

- **Path:** `Modules\Unity-Claude-CLIOrchestrator\Core\DecisionEngine-Bayesian\EnhancedPatternIntegration.psm1`
- **Size:** 7.34 KB
- **Functions:** 1
- **Lines:** 160
- **Last Modified:** 08/26/2025 11:46:18

**Functions:**
- `Invoke-EnhancedPatternAnalysis` (Line 9, 111 lines) 
### EntityContextEngine

- **Path:** `Modules\Unity-Claude-CLIOrchestrator\Core\EntityContextEngine.psm1`
- **Size:** 24.74 KB
- **Functions:** 14
- **Lines:** 704
- **Last Modified:** 08/26/2025 11:46:17

**Functions:**
- `Add-EntityValidation` (Line 374, 41 lines) - `Build-EntityRelationshipGraph` (Line 417, 61 lines) - `Extract-ContextEntities` (Line 69, 60 lines) - `Get-ContextRelevanceScore` (Line 303, 43 lines) - `Get-EntityContext` (Line 348, 24 lines) - `Get-EntitySimilarity` (Line 569, 35 lines) - `Get-LevenshteinDistance` (Line 626, 29 lines) - `Get-SpanConfidenceScore` (Line 263, 38 lines) - `Get-StringSimilarity` (Line 606, 18 lines) - `Get-TextSpans` (Line 135, 46 lines) - `Invoke-JointEntityClassification` (Line 214, 47 lines) - `New-EntityNode` (Line 480, 49 lines) - `New-EntityRelationship` (Line 531, 36 lines) - `Split-TextIntoSentences` (Line 183, 29 lines) 
### EntityRelationshipManagement

- **Path:** `Modules\Unity-Claude-CLIOrchestrator\Core\DecisionEngine-Bayesian\EntityRelationshipManagement.psm1`
- **Size:** 9.27 KB
- **Functions:** 3
- **Lines:** 266
- **Last Modified:** 08/26/2025 11:46:18

**Functions:**
- `Build-EntityRelationshipGraph` (Line 9, 100 lines) - `Find-EntityCluster` (Line 112, 37 lines) - `Measure-EntityProximity` (Line 152, 74 lines) 
### ErrorDetection

- **Path:** `Modules\Unity-Claude-UnityParallelization\Core\ErrorDetection.psm1`
- **Size:** 28.25 KB
- **Functions:** 6
- **Lines:** 676
- **Last Modified:** 08/26/2025 11:46:19

**Functions:**
- `Aggregate-UnityErrors` (Line 264, 123 lines) - `Classify-UnityCompilationError` (Line 176, 86 lines) - `Deduplicate-UnityErrors` (Line 389, 100 lines) - `Get-StringSimilarity` (Line 600, 22 lines) - `Get-UnityErrorStatistics` (Line 491, 106 lines) - `Start-ConcurrentErrorDetection` (Line 22, 152 lines) 
### ErrorExport

- **Path:** `Modules\Unity-Claude-UnityParallelization\Core\ErrorExport.psm1`
- **Size:** 16.9 KB
- **Functions:** 3
- **Lines:** 406
- **Last Modified:** 08/26/2025 11:46:19

**Functions:**
- `Export-UnityErrorsConcurrently` (Line 23, 173 lines) - `Format-UnityErrorsForClaude` (Line 198, 73 lines) - `Test-UnityParallelizationPerformance` (Line 273, 82 lines) 
### ErrorHandling

- **Path:** `Modules\Unity-Claude-AutonomousAgent\Execution\ErrorHandling.psm1`
- **Size:** 22.55 KB
- **Functions:** 11
- **Lines:** 687
- **Last Modified:** 08/20/2025 17:25:21

**Functions:**
- `Get-CircuitBreakerState` (Line 315, 27 lines) - `Get-ErrorClassificationConfig` (Line 267, 12 lines) - `Get-ExponentialBackoffDelay` (Line 153, 41 lines) - `Invoke-ExponentialBackoffRetry` (Line 67, 84 lines) - `Invoke-OperationWithTimeout` (Line 525, 69 lines) - `Set-CircuitBreakerState` (Line 344, 63 lines) - `Set-ErrorClassificationConfig` (Line 281, 28 lines) - `Stop-OperationGracefully` (Line 596, 38 lines) - `Test-CircuitBreakerState` (Line 409, 51 lines) - `Test-ErrorRetryability` (Line 196, 69 lines) - `Update-CircuitBreakerMetrics` (Line 462, 57 lines) 
### EscalationProtocol

- **Path:** `Modules\Unity-Claude-CLIOrchestrator\Core\EscalationProtocol.psm1`
- **Size:** 37.63 KB
- **Functions:** 16
- **Lines:** 1146
- **Last Modified:** 08/25/2025 13:45:24

**Functions:**
- `Add-EscalationHistory` (Line 1008, 26 lines) - `Get-EscalationStatistics` (Line 900, 65 lines) - `Invoke-AutoRemediation` (Line 494, 82 lines) - `Invoke-EmergencyProcedures` (Line 1041, 38 lines) - `Invoke-EscalationActions` (Line 436, 55 lines) - `Invoke-EscalationDecrease` (Line 309, 62 lines) - `Invoke-EscalationIncrease` (Line 243, 63 lines) - `New-Escalation` (Line 172, 68 lines) - `Resolve-Escalation` (Line 374, 55 lines) - `Send-ConsoleNotification` (Line 658, 34 lines) - `Send-EscalationNotifications` (Line 583, 72 lines) - `Send-EventLogNotification` (Line 695, 48 lines) - `Send-ResolutionNotifications` (Line 746, 28 lines) - `Test-AutoResolution` (Line 972, 33 lines) - `Test-EscalationTriggers` (Line 781, 116 lines) - `Write-EscalationLog` (Line 144, 21 lines) 
### EventProcessing

- **Path:** `Modules\Unity-Claude-MasterOrchestrator\Core\EventProcessing.psm1`
- **Size:** 15.59 KB
- **Functions:** 11
- **Lines:** 491
- **Last Modified:** 08/26/2025 11:46:19

**Functions:**
- `Add-EventToQueue` (Line 128, 19 lines) - `Invoke-DecisionEventProcessing` (Line 292, 35 lines) - `Invoke-ErrorEventProcessing` (Line 329, 35 lines) - `Invoke-EventProcessing` (Line 176, 59 lines) - `Invoke-ResponseEventProcessing` (Line 237, 53 lines) - `Invoke-SafetyEventProcessing` (Line 403, 35 lines) - `Invoke-TestEventProcessing` (Line 366, 35 lines) - `Register-DecisionEngineEvents` (Line 100, 26 lines) - `Register-ResponseMonitorEvents` (Line 71, 27 lines) - `Start-EventDrivenProcessing` (Line 22, 47 lines) - `Start-EventProcessingLoop` (Line 149, 25 lines) 
### FailureMode

- **Path:** `Modules\Unity-Claude-AutonomousAgent\Execution\FailureMode.psm1`
- **Size:** 20.87 KB
- **Functions:** 12
- **Lines:** 653
- **Last Modified:** 08/20/2025 17:25:21

**Functions:**
- `Add-DiagnosticData` (Line 475, 58 lines) - `Disable-SafeMode` (Line 244, 41 lines) - `Enable-SafeMode` (Line 200, 42 lines) - `Get-CurrentProcessInfo` (Line 585, 16 lines) - `Get-DiagnosticSummary` (Line 437, 36 lines) - `Get-SystemMemoryUsage` (Line 567, 16 lines) - `Get-SystemMetrics` (Line 539, 26 lines) - `Invoke-HumanEscalation` (Line 124, 70 lines) - `New-RecoveryCheckpoint` (Line 319, 59 lines) - `Restore-RecoveryCheckpoint` (Line 380, 55 lines) - `Test-EscalationTriggers` (Line 49, 73 lines) - `Test-SafeModeOperation` (Line 287, 26 lines) 
### FallbackMechanisms

- **Path:** `Modules\Unity-Claude-NotificationIntegration\Reliability\FallbackMechanisms.psm1`
- **Size:** 8.83 KB
- **Functions:** 7
- **Lines:** 253
- **Last Modified:** 08/21/2025 17:45:27

**Functions:**
- `Get-FallbackStatus` (Line 109, 13 lines) - `Invoke-NotificationFallback` (Line 34, 53 lines) - `New-NotificationFallbackChain` (Line 7, 25 lines) - `Reset-FallbackState` (Line 124, 12 lines) - `Test-CircuitBreaker` (Line 142, 29 lines) - `Test-NotificationFallback` (Line 89, 18 lines) - `Update-CircuitBreaker` (Line 173, 33 lines) 
### FallbackStrategies

- **Path:** `Modules\Unity-Claude-CLIOrchestrator\Core\DecisionEngine\FallbackStrategies.psm1`
- **Size:** 9.11 KB
- **Functions:** 4
- **Lines:** 236
- **Last Modified:** 08/26/2025 11:46:17

**Functions:**
- `Get-ConflictAnalysis` (Line 118, 52 lines) - `Get-EmergencyFallback` (Line 173, 18 lines) - `Invoke-GracefulDegradation` (Line 65, 50 lines) - `Resolve-ConflictingRecommendations` (Line 9, 53 lines) 
### FileProcessing

- **Path:** `Modules\Unity-Claude-PerformanceOptimizer\Core\FileProcessing.psm1`
- **Size:** 9.6 KB
- **Functions:** 9
- **Lines:** 307
- **Last Modified:** 08/26/2025 11:46:19

**Functions:**
- `Invoke-BatchFileProcessing` (Line 231, 29 lines) - `Invoke-CSharpFileProcessing` (Line 111, 19 lines) - `Invoke-FileProcessing` (Line 7, 34 lines) - `Invoke-FileTypeProcessing` (Line 44, 31 lines) - `Invoke-GenericFileProcessing` (Line 183, 19 lines) - `Invoke-JavaScriptFileProcessing` (Line 155, 25 lines) - `Invoke-PowerShellFileProcessing` (Line 78, 30 lines) - `Invoke-PythonFileProcessing` (Line 133, 19 lines) - `New-ProcessingCompletionRecord` (Line 205, 23 lines) 
### FileSystemMonitoring

- **Path:** `Modules\Unity-Claude-AutonomousAgent\Monitoring\FileSystemMonitoring.psm1`
- **Size:** 20.74 KB
- **Functions:** 4
- **Lines:** 442
- **Last Modified:** 08/20/2025 17:25:21

**Functions:**
- `Get-MonitoringStatus` (Line 283, 40 lines) - `Start-ClaudeResponseMonitoring` (Line 16, 205 lines) - `Stop-ClaudeResponseMonitoring` (Line 223, 58 lines) - `Test-FileSystemMonitoring` (Line 325, 73 lines) 
### FileSystemMonitoring

- **Path:** `Modules\Unity-Claude-PerformanceOptimizer\Core\FileSystemMonitoring.psm1`
- **Size:** 7.67 KB
- **Functions:** 8
- **Lines:** 225
- **Last Modified:** 08/26/2025 11:46:19

**Functions:**
- `Add-DependentFilesToQueue` (Line 125, 22 lines) - `Get-DependentFiles` (Line 100, 22 lines) - `Get-QueueHealth` (Line 150, 29 lines) - `Initialize-FileSystemWatcher` (Line 8, 19 lines) - `New-FileChangeInfo` (Line 77, 20 lines) - `Register-FileChangeHandler` (Line 30, 17 lines) - `Start-FileSystemMonitoring` (Line 50, 9 lines) - `Stop-FileSystemMonitoring` (Line 62, 12 lines) 
### GitHubPRManager

- **Path:** `Modules\Unity-Claude-DocumentationAutomation\Core\GitHubPRManager.psm1`
- **Size:** 14.91 KB
- **Functions:** 5
- **Lines:** 456
- **Last Modified:** 08/26/2025 11:46:18

**Functions:**
- `Get-DocumentationPRs` (Line 252, 31 lines) - `Merge-DocumentationPR` (Line 285, 55 lines) - `New-DocumentationPR` (Line 20, 149 lines) - `Test-PRDocumentationChanges` (Line 342, 69 lines) - `Update-DocumentationPR` (Line 171, 79 lines) 
### GoalManagement

- **Path:** `Modules\Unity-Claude-AutonomousAgent\Core\GoalManagement.psm1`
- **Size:** 15.85 KB
- **Functions:** 8
- **Lines:** 463
- **Last Modified:** 08/26/2025 11:46:17

**Functions:**
- `Add-ConversationGoal` (Line 7, 77 lines) - `Calculate-GoalEffectiveness` (Line 332, 36 lines) - `Calculate-GoalRelevance` (Line 253, 76 lines) - `Get-ConversationGoals` (Line 184, 67 lines) - `Save-ConversationEffectiveness` (Line 414, 12 lines) - `Save-ConversationGoals` (Line 398, 14 lines) - `Update-ConversationEffectiveness` (Line 370, 26 lines) - `Update-ConversationGoal` (Line 86, 96 lines) 
### GraphOptimizer

- **Path:** `Modules\Unity-Claude-ScalabilityEnhancements\Core\GraphOptimizer.psm1`
- **Size:** 12.18 KB
- **Functions:** 12
- **Lines:** 358
- **Last Modified:** 08/26/2025 11:46:19

**Functions:**
- `CalculateGraphSize` (Line 144, 5 lines, 1 params) - `Compress-GraphData` (Line 257, 36 lines) - `CompressGraphData` (Line 117, 25 lines, 1 params) - `Get-PruningReport` (Line 295, 17 lines) - `GraphPruner` (Line 15, 11 lines, 1 params) - `MarkPreservedNodes` (Line 66, 9 lines, 2 params) - `Optimize-GraphStructure` (Line 213, 42 lines) - `PruneGraph` (Line 28, 36 lines, 2 params) - `Remove-UnusedNodes` (Line 181, 30 lines) - `RemoveOrphanedEdges` (Line 99, 16 lines, 1 params) - `RemoveUnusedNodes` (Line 77, 20 lines, 1 params) - `Start-GraphPruning` (Line 152, 27 lines) 
### GraphTraversal

- **Path:** `Modules\Unity-Claude-CPG\Core\GraphTraversal.psm1`
- **Size:** 10.32 KB
- **Functions:** 1
- **Lines:** 255
- **Last Modified:** 08/26/2025 11:46:18

**Functions:**
- `Find-UnreachableCode` (Line 42, 169 lines) 
### HealthMonitoring

- **Path:** `Modules\Unity-Claude-AutonomousStateTracker-Enhanced\Core\HealthMonitoring.psm1`
- **Size:** 10.12 KB
- **Functions:** 4
- **Lines:** 257
- **Last Modified:** 08/26/2025 11:46:17

**Functions:**
- `Get-HealthMonitoringStatus` (Line 126, 28 lines) - `Start-EnhancedHealthMonitoring` (Line 8, 90 lines) - `Stop-EnhancedHealthMonitoring` (Line 100, 24 lines) - `Test-AgentHealth` (Line 156, 56 lines) 
### HistoryManagement

- **Path:** `Modules\Unity-Claude-AutonomousAgent\Core\HistoryManagement.psm1`
- **Size:** 14.05 KB
- **Functions:** 6
- **Lines:** 390
- **Last Modified:** 08/26/2025 11:46:17

**Functions:**
- `Add-ConversationHistoryItem` (Line 7, 79 lines) - `Clear-ConversationHistory` (Line 234, 40 lines) - `Get-ConversationContext` (Line 151, 81 lines) - `Get-ConversationHistory` (Line 88, 61 lines) - `Get-SessionMetadata` (Line 276, 60 lines) - `Save-ConversationHistory` (Line 339, 14 lines) 
### HITLCore

- **Path:** `Modules\Unity-Claude-HITL\Core\HITLCore.psm1`
- **Size:** 5.03 KB
- **Functions:** 2
- **Lines:** 145
- **Last Modified:** 08/26/2025 11:46:18

**Functions:**
- `Get-HITLConfiguration` (Line 74, 12 lines) - `Set-HITLConfiguration` (Line 35, 37 lines) 
### HorizontalScaling

- **Path:** `Modules\Unity-Claude-ScalabilityEnhancements\Core\HorizontalScaling.psm1`
- **Size:** 10.83 KB
- **Functions:** 7
- **Lines:** 303
- **Last Modified:** 08/26/2025 11:46:19

**Functions:**
- `AssessScalabilityReadiness` (Line 56, 47 lines, 1 params) - `CreatePartitionPlan` (Line 21, 33 lines, 1 params) - `Export-ScalabilityMetrics` (Line 160, 49 lines) - `New-ScalingConfiguration` (Line 106, 23 lines) - `Prepare-DistributedMode` (Line 211, 47 lines) - `ScalingConfiguration` (Line 13, 6 lines, 1 params) - `Test-HorizontalReadiness` (Line 131, 27 lines) 
### HumanIntervention

- **Path:** `Modules\Unity-Claude-AutonomousStateTracker-Enhanced\Core\HumanIntervention.psm1`
- **Size:** 13.89 KB
- **Functions:** 6
- **Lines:** 371
- **Last Modified:** 08/26/2025 11:46:17

**Functions:**
- `Approve-AgentIntervention` (Line 103, 52 lines) - `Clear-ResolvedInterventions` (Line 280, 44 lines) - `Deny-AgentIntervention` (Line 157, 41 lines) - `Get-PendingInterventions` (Line 243, 35 lines) - `Request-HumanIntervention` (Line 8, 93 lines) - `Update-InterventionStatus` (Line 200, 41 lines) 
### ImpactAnalysis

- **Path:** `Modules\Unity-Claude-DocumentationDrift\Analysis\ImpactAnalysis.psm1`
- **Size:** 14.86 KB
- **Functions:** 7
- **Lines:** 432
- **Last Modified:** 08/26/2025 11:46:18

**Functions:**
- `Analyze-ChangeImpact` (Line 7, 101 lines) - `Analyze-DeletedFileImpact` (Line 163, 35 lines) - `Analyze-ModifiedFileImpact` (Line 200, 82 lines) - `Analyze-NewFileImpact` (Line 110, 51 lines) - `Analyze-RenamedFileImpact` (Line 284, 30 lines) - `Determine-OverallImpactLevel` (Line 316, 33 lines) - `Generate-ChangeRecommendations` (Line 351, 35 lines) 
### ImprovementRoadmaps

- **Path:** `Modules\Unity-Claude-PredictiveAnalysis\Core\ImprovementRoadmaps.psm1`
- **Size:** 36.86 KB
- **Functions:** 12
- **Lines:** 1024
- **Last Modified:** 08/26/2025 11:46:19

**Functions:**
- `Calculate-ExpectedROI` (Line 519, 39 lines) - `Create-ContinuousImprovementPhase` (Line 453, 64 lines) - `Create-CriticalPhase` (Line 146, 76 lines) - `Create-DocumentationPhase` (Line 375, 76 lines) - `Create-HighImpactPhase` (Line 224, 76 lines) - `Create-OptimizationPhase` (Line 302, 71 lines) - `Define-SuccessMetrics` (Line 560, 63 lines) - `Export-RoadmapReport` (Line 675, 52 lines) - `Generate-HTMLReport` (Line 823, 158 lines) - `Generate-MarkdownReport` (Line 729, 92 lines) - `Get-LLMRoadmapRecommendations` (Line 625, 48 lines) - `New-ImprovementRoadmap` (Line 21, 123 lines) 
### IntegratedNotifications

- **Path:** `Modules\Unity-Claude-NotificationIntegration\Integration\IntegratedNotifications.psm1`
- **Size:** 11.62 KB
- **Functions:** 3
- **Lines:** 323
- **Last Modified:** 08/21/2025 17:45:27

**Functions:**
- `Send-IntegratedNotification` (Line 5, 161 lines) - `Test-IntegratedNotification` (Line 168, 34 lines) - `Validate-CrossModuleMessage` (Line 204, 78 lines) 
### IntegrationManagement

- **Path:** `Modules\Unity-Claude-DecisionEngine\Core\IntegrationManagement.psm1`
- **Size:** 13.75 KB
- **Functions:** 6
- **Lines:** 360
- **Last Modified:** 08/26/2025 11:46:18

**Functions:**
- `Connect-ConversationManager` (Line 58, 35 lines) - `Connect-IntelligentPromptEngine` (Line 20, 36 lines) - `Get-DecisionEngineComponents` (Line 253, 26 lines) - `Get-DecisionEngineStatus` (Line 99, 57 lines) - `Test-DecisionEngineHealth` (Line 281, 32 lines) - `Test-DecisionEngineIntegration` (Line 158, 89 lines) 
### IntelligentPromptEngine-Refactored

- **Path:** `Modules\Unity-Claude-AutonomousAgent\IntelligentPromptEngine-Refactored.psm1`
- **Size:** 17.39 KB
- **Functions:** 5
- **Lines:** 426
- **Last Modified:** 08/26/2025 11:46:17

**Functions:**
- `Get-PromptEngineStatus` (Line 208, 64 lines) - `Initialize-IntelligentPromptEngine` (Line 290, 77 lines) - `Invoke-IntelligentPromptGeneration` (Line 41, 112 lines) - `New-FallbackPrompt` (Line 155, 51 lines) - `Test-ComponentAvailability` (Line 274, 14 lines) 
### IntelligentPromptEngine

- **Path:** `Modules\Unity-Claude-AutonomousAgent\IntelligentPromptEngine.psm1`
- **Size:** 17.39 KB
- **Functions:** 5
- **Lines:** 426
- **Last Modified:** 08/26/2025 11:46:17

**Functions:**
- `Get-PromptEngineStatus` (Line 208, 64 lines) - `Initialize-IntelligentPromptEngine` (Line 290, 77 lines) - `Invoke-IntelligentPromptGeneration` (Line 41, 112 lines) - `New-FallbackPrompt` (Line 155, 51 lines) - `Test-ComponentAvailability` (Line 274, 14 lines) 
### JobScheduler

- **Path:** `Modules\Unity-Claude-ParallelProcessor\Core\JobScheduler.psm1`
- **Size:** 19.46 KB
- **Functions:** 17
- **Lines:** 486
- **Last Modified:** 08/26/2025 11:46:19

**Functions:**
- `CancelAllJobs` (Line 347, 11 lines) - `CancelJob` (Line 325, 19 lines, 1 params) - `CleanupCompletedJobs` (Line 380, 17 lines) - `CollectJobResult` (Line 247, 38 lines, 1 params) - `Dispose` (Line 400, 19 lines) - `GetAllJobStatuses` (Line 371, 6 lines) - `GetDuration` (Line 42, 6 lines) - `GetJobStatus` (Line 361, 7 lines, 1 params) - `GetSummary` (Line 51, 12 lines) - `JobScheduler` (Line 76, 16 lines, 2 params) - `New-JobScheduler` (Line 426, 20 lines) - `ParallelJob` (Line 30, 9 lines, 4 params) - `RetryJob` (Line 288, 34 lines, 1 params) - `SubmitJob` (Line 95, 50 lines, 2 params) - `SubmitJobs` (Line 148, 19 lines, 2 params) - `WaitForAllJobs` (Line 200, 44 lines, 1 params) - `WaitForJob` (Line 170, 27 lines, 2 params) 
### JsonProcessing

- **Path:** `Modules\Unity-Claude-CLIOrchestrator\Core\Components\JsonProcessing.psm1`
- **Size:** 19.5 KB
- **Functions:** 10
- **Lines:** 523
- **Last Modified:** 08/26/2025 11:46:17

**Functions:**
- `ConvertFrom-JsonFast` (Line 128, 29 lines) - `Get-JsonProcessingConfiguration` (Line 364, 5 lines) - `Invoke-MultiParserJson` (Line 159, 68 lines) - `Repair-TruncatedJson` (Line 76, 46 lines) - `Set-JsonProcessingConfiguration` (Line 336, 26 lines) - `Test-AnthropicResponseSchema` (Line 274, 56 lines) - `Test-JsonProcessingComponent` (Line 375, 95 lines) - `Test-JsonSchema` (Line 233, 39 lines) - `Test-JsonTruncation` (Line 39, 35 lines) - `Write-AnalysisLog` (Line 17, 3 lines) 
### LearningAdaptation

- **Path:** `Modules\Unity-Claude-CLIOrchestrator\Core\DecisionEngine-Bayesian\LearningAdaptation.psm1`
- **Size:** 7.47 KB
- **Functions:** 3
- **Lines:** 184
- **Last Modified:** 08/26/2025 11:46:18

**Functions:**
- `Initialize-BayesianLearning` (Line 107, 37 lines) - `Save-BayesianLearning` (Line 80, 24 lines) - `Update-BayesianLearning` (Line 9, 68 lines) 
### LearningCore

- **Path:** `Modules\Unity-Claude-Learning\Core\LearningCore.psm1`
- **Size:** 8.16 KB
- **Functions:** 9
- **Lines:** 259
- **Last Modified:** 08/26/2025 11:46:19

**Functions:**
- `Clear-PatternCache` (Line 129, 10 lines) - `Get-LearningConfig` (Line 46, 12 lines) - `Get-PatternCache` (Line 106, 9 lines) - `Get-SuccessMetrics` (Line 142, 9 lines) - `Measure-ExecutionTime` (Line 166, 39 lines) - `Set-LearningConfig` (Line 61, 42 lines) - `Update-PatternCache` (Line 118, 8 lines) - `Update-SuccessMetrics` (Line 154, 9 lines) - `Write-LearningLog` (Line 26, 17 lines) 
### Legacy-Compatibility

- **Path:** `Migration\Legacy-Compatibility.psm1`
- **Size:** 28.16 KB
- **Functions:** 9
- **Lines:** 725
- **Last Modified:** 08/27/2025 00:06:45

**Functions:**
- `Disable-LegacyMode` (Line 63, 16 lines) - `Enable-LegacyMode` (Line 12, 49 lines) - `Invoke-LegacySystemStartup` (Line 138, 92 lines) - `Invoke-ManifestBasedSystemStartup` (Line 295, 236 lines) - `Show-DeprecationWarning` (Line 98, 38 lines) - `Start-SubsystemInWindow` (Line 232, 61 lines) - `Start-UnityClaudeSystem` (Line 533, 111 lines) - `Test-LegacyMode` (Line 81, 15 lines) - `Test-MigrationStatus` (Line 646, 67 lines) 
### LLM-PromptTemplates

- **Path:** `Modules\Unity-Claude-LLM\Core\LLM-PromptTemplates.psm1`
- **Size:** 13.57 KB
- **Functions:** 15
- **Lines:** 495
- **Last Modified:** 08/28/2025 13:58:46

**Functions:**
- `Get-APIDocumentationTemplate` (Line 104, 29 lines) - `Get-AvailableTemplates` (Line 466, 10 lines) - `Get-ClassDocumentationTemplate` (Line 73, 29 lines) - `Get-DependencyAnalysisTemplate` (Line 238, 27 lines) - `Get-FunctionDocumentationTemplate` (Line 12, 28 lines) - `Get-InheritanceAnalysisTemplate` (Line 267, 27 lines) - `Get-ModuleDocumentationTemplate` (Line 42, 29 lines) - `Get-PatternDetectionTemplate` (Line 300, 28 lines) - `Get-PerformanceAnalysisTemplate` (Line 171, 29 lines) - `Get-QualityAnalysisTemplate` (Line 202, 30 lines) - `Get-RefactoringTemplate` (Line 330, 29 lines) - `Get-SecurityAnalysisTemplate` (Line 139, 30 lines) - `Invoke-TemplateSubstitution` (Line 365, 38 lines) - `New-AnalysisPromptFromTemplate` (Line 434, 30 lines) - `New-DocumentationPromptFromTemplate` (Line 405, 27 lines) 
### LLM-ResponseCache

- **Path:** `Modules\Unity-Claude-LLM\Core\LLM-ResponseCache.psm1`
- **Size:** 13.88 KB
- **Functions:** 14
- **Lines:** 458
- **Last Modified:** 08/30/2025 19:47:36

**Functions:**
- `Clear-ExpiredCache` (Line 167, 39 lines) - `Get-CachedResponse` (Line 58, 47 lines) - `Get-CacheKey` (Line 35, 21 lines) - `Get-CacheStatistics` (Line 250, 30 lines) - `Get-LLMResponseFromCache` (Line 400, 17 lines) - `Invoke-CacheMaintenanceTask` (Line 373, 21 lines) - `Invoke-LRUEviction` (Line 208, 40 lines) - `Remove-CacheEntry` (Line 148, 17 lines) - `Reset-Cache` (Line 330, 22 lines) - `Set-CacheConfiguration` (Line 354, 17 lines) - `Set-CachedResponse` (Line 107, 39 lines) - `Set-LLMResponseToCache` (Line 419, 20 lines) - `Start-CacheCleanupJob` (Line 282, 35 lines) - `Stop-CacheCleanupJob` (Line 319, 9 lines) 
### MaintenancePrediction

- **Path:** `Modules\Unity-Claude-PredictiveAnalysis\Core\MaintenancePrediction.psm1`
- **Size:** 13.96 KB
- **Functions:** 2
- **Lines:** 362
- **Last Modified:** 08/26/2025 11:46:19

**Functions:**
- `Calculate-TechnicalDebt` (Line 180, 139 lines) - `Get-MaintenancePrediction` (Line 15, 163 lines) 
### MemoryManager

- **Path:** `Modules\Unity-Claude-ScalabilityEnhancements\Core\MemoryManager.psm1`
- **Size:** 9 KB
- **Functions:** 13
- **Lines:** 274
- **Last Modified:** 08/26/2025 11:46:19

**Functions:**
- `Force-GarbageCollection` (Line 147, 24 lines) - `Get-MemoryUsageReport` (Line 129, 16 lines) - `GetMemoryUsageReport` (Line 50, 17 lines) - `HandleMemoryPressure` (Line 88, 4 lines) - `MemoryManager` (Line 11, 10 lines, 1 params) - `Monitor-MemoryPressure` (Line 200, 28 lines) - `Optimize-ObjectLifecycles` (Line 173, 25 lines) - `OptimizeMemory` (Line 69, 17 lines) - `RegisterManagedObject` (Line 101, 3 lines, 1 params) - `ShouldOptimize` (Line 94, 5 lines) - `Start-MemoryOptimization` (Line 107, 20 lines) - `StartMonitoring` (Line 23, 12 lines) - `UpdateMemoryStatistics` (Line 37, 11 lines) 
### MetricsAndHealthCheck

- **Path:** `Modules\Unity-Claude-NotificationIntegration\Monitoring\MetricsAndHealthCheck.psm1`
- **Size:** 20.09 KB
- **Functions:** 13
- **Lines:** 569
- **Last Modified:** 08/21/2025 17:45:27

**Functions:**
- `Export-NotificationAnalytics` (Line 203, 43 lines) - `Format-ReportAsHtml` (Line 480, 42 lines) - `Format-ReportAsText` (Line 453, 25 lines) - `Get-NotificationHealthCheck` (Line 78, 66 lines) - `Get-NotificationMetrics` (Line 7, 69 lines) - `Get-PerformanceMetrics` (Line 435, 16 lines) - `Get-QueueAnalytics` (Line 410, 23 lines) - `New-NotificationReport` (Line 146, 55 lines) - `Reset-NotificationMetrics` (Line 248, 39 lines) - `Test-CircuitBreakerHealth` (Line 329, 29 lines) - `Test-ConfigurationHealth` (Line 391, 17 lines) - `Test-MetricsHealth` (Line 360, 29 lines) - `Test-QueueHealth` (Line 293, 34 lines) 
### MetricsCollection

- **Path:** `Modules\Unity-Claude-Learning\Core\MetricsCollection.psm1`
- **Size:** 15.74 KB
- **Functions:** 11
- **Lines:** 497
- **Last Modified:** 08/26/2025 11:46:19

**Functions:**
- `Export-LearningMetrics` (Line 362, 63 lines) - `Get-DatabaseStatistics` (Line 271, 63 lines) - `Get-HistoricalMetrics` (Line 336, 24 lines) - `Get-LearningStatistics` (Line 225, 44 lines) - `Get-PerformanceMetrics` (Line 116, 39 lines) - `Measure-ResourceUsage` (Line 187, 36 lines) - `Reset-PerformanceMetrics` (Line 427, 19 lines) - `Start-PerformanceTimer` (Line 37, 31 lines) - `Stop-PerformanceTimer` (Line 70, 44 lines) - `Update-CacheMetrics` (Line 157, 28 lines) - `Write-ModuleLog` (Line 13, 4 lines) 
### ModuleFunctions

- **Path:** `Modules\Unity-Claude-ParallelProcessor\Core\ModuleFunctions.psm1`
- **Size:** 19.46 KB
- **Functions:** 24
- **Lines:** 563
- **Last Modified:** 08/26/2025 11:46:19

**Functions:**
- `CancelAllJobs` (Line 260, 8 lines) - `CancelJob` (Line 254, 3 lines, 1 params) - `CleanupCompletedJobs` (Line 271, 2 lines) - `Dispose` (Line 276, 27 lines) - `Get-JobStatus` (Line 419, 12 lines) - `Get-ParallelProcessorStatistics` (Line 408, 9 lines) - `GetJobStatus` (Line 249, 2 lines, 1 params) - `GetStatistics` (Line 234, 12 lines) - `Initialize` (Line 44, 41 lines, 3 params) - `Invoke-ParallelProcessing` (Line 344, 34 lines) - `InvokeParallel` (Line 170, 27 lines, 3 params) - `New-ParallelProcessor` (Line 310, 32 lines) - `ParallelProcessor` (Line 32, 2 lines) - `ParallelProcessor` (Line 40, 2 lines, 3 params) - `ParallelProcessor` (Line 36, 2 lines, 2 params) - `Start-BatchProcessing` (Line 380, 26 lines) - `StartProducerConsumer` (Line 200, 31 lines, 3 params) - `Stop-ParallelProcessor` (Line 433, 26 lines) - `SubmitJob` (Line 88, 9 lines, 2 params) - `SubmitJobs` (Line 100, 9 lines, 2 params) - `Test-ParallelProcessorHealth` (Line 461, 46 lines) - `UpdateStatisticsFromJobResults` (Line 149, 18 lines) - `WaitForAllJobs` (Line 132, 14 lines, 1 params) - `WaitForJob` (Line 112, 17 lines, 2 params) 
### ModuleIntegration

- **Path:** `Modules\Unity-Claude-MasterOrchestrator\Core\ModuleIntegration.psm1`
- **Size:** 13.68 KB
- **Functions:** 4
- **Lines:** 342
- **Last Modified:** 08/26/2025 11:46:19

**Functions:**
- `Get-ModuleIntegrationPoints` (Line 252, 44 lines) - `Initialize-ModuleIntegration` (Line 97, 93 lines) - `Initialize-SingleModule` (Line 192, 58 lines) - `Test-ModuleAvailability` (Line 19, 76 lines) 
### ModuleVariablePreloading

- **Path:** `Modules\Unity-Claude-RunspaceManagement\Core\ModuleVariablePreloading.psm1`
- **Size:** 11.65 KB
- **Functions:** 7
- **Lines:** 297
- **Last Modified:** 08/26/2025 11:46:19

**Functions:**
- `Add-SessionStateModule` (Line 27, 0 lines) - `Add-SessionStateVariable` (Line 26, 0 lines) - `Get-SessionStateModules` (Line 166, 35 lines) - `Get-SessionStateVariables` (Line 203, 49 lines) - `Import-SessionStateModules` (Line 34, 64 lines) - `Initialize-SessionStateVariables` (Line 100, 64 lines) - `Write-ModuleLog` (Line 21, 4 lines) 
### MonitoringLoop

- **Path:** `Modules\Unity-Claude-CLIOrchestrator\Core\OrchestrationComponents\MonitoringLoop.psm1`
- **Size:** 15.08 KB
- **Functions:** 3
- **Lines:** 344
- **Last Modified:** 08/27/2025 19:19:14

**Functions:**
- `Invoke-SingleExecutionCycle` (Line 111, 78 lines) - `Process-SignalFile` (Line 191, 150 lines) - `Start-MonitoringLoop` (Line 4, 105 lines) 
### NotificationCore

- **Path:** `Modules\Unity-Claude-NotificationIntegration\Core\NotificationCore.psm1`
- **Size:** 16.34 KB
- **Functions:** 6
- **Lines:** 418
- **Last Modified:** 08/21/2025 17:45:27

**Functions:**
- `Clear-NotificationHooks` (Line 266, 19 lines) - `Get-NotificationHooks` (Line 222, 42 lines) - `Initialize-NotificationIntegration` (Line 18, 87 lines) - `Register-NotificationHook` (Line 107, 76 lines) - `Send-IntegratedNotification` (Line 287, 83 lines) - `Unregister-NotificationHook` (Line 185, 35 lines) 
### NotificationSystem

- **Path:** `Modules\Unity-Claude-HITL\Core\NotificationSystem.psm1`
- **Size:** 12.66 KB
- **Functions:** 4
- **Lines:** 322
- **Last Modified:** 08/26/2025 11:46:18

**Functions:**
- `Build-ApprovalEmailTemplate` (Line 98, 98 lines) - `Send-ApprovalNotification` (Line 14, 82 lines) - `Send-ApprovalReminder` (Line 198, 34 lines) - `Send-ApprovalResultNotification` (Line 234, 40 lines) 
### OptimizerConfiguration

- **Path:** `Modules\Unity-Claude-PerformanceOptimizer\Core\OptimizerConfiguration.psm1`
- **Size:** 7.06 KB
- **Functions:** 6
- **Lines:** 203
- **Last Modified:** 08/26/2025 11:46:19

**Functions:**
- `Get-DefaultOptimizerConfiguration` (Line 111, 15 lines) - `Get-FilePriority` (Line 48, 12 lines) - `Get-OptimalThreadCount` (Line 28, 17 lines) - `Initialize-OptimizerComponents` (Line 63, 45 lines) - `Initialize-PerformanceMetrics` (Line 8, 17 lines) - `Test-OptimizerConfiguration` (Line 129, 30 lines) 
### OrchestrationCore

- **Path:** `Modules\Unity-Claude-CLIOrchestrator\Core\OrchestrationComponents\OrchestrationCore.psm1`
- **Size:** 9.09 KB
- **Functions:** 3
- **Lines:** 226
- **Last Modified:** 08/27/2025 15:25:41

**Functions:**
- `Get-CLIOrchestrationStatus` (Line 114, 60 lines) - `Initialize-OrchestrationEnvironment` (Line 176, 47 lines) - `Start-CLIOrchestration` (Line 4, 108 lines) 
### OrchestrationManager

- **Path:** `Modules\Unity-Claude-CLIOrchestrator\Core\OrchestrationManager.psm1`
- **Size:** 52.72 KB
- **Functions:** 1
- **Lines:** 988
- **Last Modified:** 08/27/2025 19:57:01

**Functions:**
- `Start-CLIOrchestration` (Line 20, 967 lines) 
### OrchestratorCore

- **Path:** `Modules\Unity-Claude-MasterOrchestrator\Core\OrchestratorCore.psm1`
- **Size:** 7.61 KB
- **Functions:** 5
- **Lines:** 233
- **Last Modified:** 08/26/2025 11:46:19

**Functions:**
- `Get-ModuleArchitecture` (Line 155, 6 lines) - `Get-OrchestratorConfig` (Line 129, 6 lines) - `Get-OrchestratorState` (Line 163, 14 lines) - `Set-OrchestratorConfig` (Line 137, 16 lines) - `Write-OrchestratorLog` (Line 84, 43 lines) 
### OrchestratorManagement

- **Path:** `Modules\Unity-Claude-MasterOrchestrator\Core\OrchestratorManagement.psm1`
- **Size:** 16.16 KB
- **Functions:** 6
- **Lines:** 439
- **Last Modified:** 08/26/2025 11:46:19

**Functions:**
- `Clear-OrchestratorState` (Line 185, 66 lines) - `Get-OperationHistory` (Line 141, 42 lines) - `Get-OrchestratorHealth` (Line 253, 90 lines) - `Get-OrchestratorStatus` (Line 23, 41 lines) - `Reset-OrchestratorToDefaults` (Line 345, 46 lines) - `Test-OrchestratorIntegration` (Line 66, 73 lines) 
### PaginationProvider

- **Path:** `Modules\Unity-Claude-ScalabilityEnhancements\Core\PaginationProvider.psm1`
- **Size:** 8.05 KB
- **Functions:** 10
- **Lines:** 252
- **Last Modified:** 08/26/2025 11:46:19

**Functions:**
- `Export-PagedData` (Line 169, 37 lines) - `Get-PaginatedResults` (Line 92, 23 lines) - `GetNextPage` (Line 54, 5 lines) - `GetPage` (Line 23, 18 lines, 1 params) - `GetPageInfo` (Line 43, 9 lines) - `GetPreviousPage` (Line 61, 5 lines) - `Navigate-ResultPages` (Line 142, 25 lines) - `New-PaginationProvider` (Line 69, 21 lines) - `PaginationProvider` (Line 14, 7 lines, 2 params) - `Set-PageSize` (Line 117, 23 lines) 
### ParallelizationCore

- **Path:** `Modules\Unity-Claude-UnityParallelization\Core\ParallelizationCore.psm1`
- **Size:** 9.75 KB
- **Functions:** 6
- **Lines:** 274
- **Last Modified:** 08/26/2025 11:46:19

**Functions:**
- `Get-UnityParallelizationConfig` (Line 169, 11 lines) - `Initialize-ModuleDependencies` (Line 79, 36 lines) - `Set-UnityParallelizationConfig` (Line 182, 23 lines) - `Test-ModuleDependencyAvailability` (Line 46, 30 lines) - `Write-FallbackLog` (Line 121, 22 lines) - `Write-UnityParallelLog` (Line 145, 18 lines) 
### ParallelMonitoring

- **Path:** `Modules\Unity-Claude-UnityParallelization\Core\ParallelMonitoring.psm1`
- **Size:** 26.79 KB
- **Functions:** 4
- **Lines:** 592
- **Last Modified:** 08/26/2025 11:46:19

**Functions:**
- `Get-UnityMonitoringStatus` (Line 470, 70 lines) - `New-UnityParallelMonitor` (Line 22, 185 lines) - `Start-UnityParallelMonitoring` (Line 209, 191 lines) - `Stop-UnityParallelMonitoring` (Line 402, 66 lines) 
### ParallelProcessorCore

- **Path:** `Modules\Unity-Claude-ParallelProcessor\Core\ParallelProcessorCore.psm1`
- **Size:** 10.13 KB
- **Functions:** 11
- **Lines:** 328
- **Last Modified:** 08/26/2025 11:46:19

**Functions:**
- `Get-GlobalParallelProcessorStatistics` (Line 263, 9 lines) - `Get-OptimalThreadCount` (Line 88, 30 lines) - `Get-ParallelProcessorConfiguration` (Line 214, 5 lines) - `New-ProcessorId` (Line 120, 7 lines) - `Register-ParallelProcessor` (Line 129, 15 lines) - `Set-ParallelProcessorConfiguration` (Line 221, 40 lines) - `Set-ParallelProcessorDebugMode` (Line 73, 9 lines) - `Test-ParameterValidity` (Line 192, 16 lines) - `Test-ScriptBlockSafety` (Line 164, 26 lines) - `Unregister-ParallelProcessor` (Line 146, 12 lines) - `Write-ParallelProcessorLog` (Line 36, 35 lines) 
### PatternAnalysis

- **Path:** `Modules\Unity-Claude-CLIOrchestrator\Core\DecisionEngine-Bayesian\PatternAnalysis.psm1`
- **Size:** 8.57 KB
- **Functions:** 3
- **Lines:** 239
- **Last Modified:** 08/26/2025 11:46:18

**Functions:**
- `Build-NGramModel` (Line 9, 61 lines) - `Calculate-PatternSimilarity` (Line 73, 83 lines) - `Get-LevenshteinDistance` (Line 159, 40 lines) 
### PatternRecognition

- **Path:** `Modules\Unity-Claude-Learning\Core\PatternRecognition.psm1`
- **Size:** 15.02 KB
- **Functions:** 5
- **Lines:** 398
- **Last Modified:** 08/26/2025 11:46:19

**Functions:**
- `Add-ErrorPattern` (Line 18, 94 lines) - `Add-ErrorPatternSQLite` (Line 114, 79 lines) - `Calculate-ConfidenceScore` (Line 306, 42 lines) - `Find-SimilarPatterns` (Line 195, 45 lines) - `Find-SimilarPatternsMemory` (Line 242, 62 lines) 
### PatternRecognitionEngine-Fixed

- **Path:** `Modules\Unity-Claude-CLIOrchestrator\Core\PatternRecognitionEngine-Fixed.psm1`
- **Size:** 8.86 KB
- **Functions:** 4
- **Lines:** 273
- **Last Modified:** 08/27/2025 16:51:46

**Functions:**
- `Get-CachedPattern` (Line 206, 19 lines) - `Invoke-PatternRecognitionAnalysis` (Line 92, 106 lines) - `Set-CachedPattern` (Line 227, 32 lines) - `Write-PatternLog` (Line 63, 23 lines) 
### PatternRecognitionEngine-New

- **Path:** `Modules\Unity-Claude-CLIOrchestrator\Core\PatternRecognitionEngine-New.psm1`
- **Size:** 11.06 KB
- **Functions:** 4
- **Lines:** 283
- **Last Modified:** 08/25/2025 14:20:03

**Functions:**
- `Get-PatternRecognitionStatus` (Line 200, 39 lines) - `Invoke-PatternRecognitionAnalysis` (Line 70, 87 lines) - `Test-PatternRecognitionPerformance` (Line 163, 35 lines) - `Write-PatternLog` (Line 35, 29 lines) 
### PatternRecognitionEngine-Original

- **Path:** `Modules\Unity-Claude-CLIOrchestrator\Core\PatternRecognitionEngine-Original.psm1`
- **Size:** 89.32 KB
- **Functions:** 33
- **Lines:** 2444
- **Last Modified:** 08/25/2025 14:20:03

**Functions:**
- `Build-EntityRelationshipGraph` (Line 790, 61 lines) - `Calculate-OverallConfidence` (Line 2171, 155 lines) - `Classify-ResponseType` (Line 1404, 65 lines) - `Extract-ContextEntities` (Line 1020, 147 lines) - `Find-RecommendationPatterns` (Line 514, 115 lines) - `Get-BayesianConfidence` (Line 2036, 42 lines) - `Get-ClusterCoherence` (Line 982, 32 lines) - `Get-ConnectedNodes` (Line 918, 38 lines) - `Get-DeduplicatedEntities` (Line 1329, 38 lines) - `Get-EnhancedFeatureEngineering` (Line 1471, 67 lines) - `Get-EnhancedPatternMatch` (Line 401, 68 lines) - `Get-EntityClusterAnalysis` (Line 893, 23 lines) - `Get-EntityEnrichment` (Line 1249, 78 lines) - `Get-EntitySimilarity` (Line 746, 42 lines) - `Get-FeatureScore` (Line 1373, 29 lines) - `Get-MostConnectedNode` (Line 958, 22 lines) - `Get-PatternWeightedScore` (Line 2114, 55 lines) - `Get-TypeSpecificRelationship` (Line 853, 38 lines) - `Initialize-CompiledPatterns` (Line 316, 43 lines) - `Invoke-BayesianClassificationCalibration` (Line 1925, 53 lines) - `Invoke-DecisionTreeClassifier` (Line 1540, 76 lines) - `Invoke-EnsembleVoting` (Line 1833, 90 lines) - `Invoke-EntityContextClassifier` (Line 1758, 73 lines) - `Invoke-FeatureBasedClassifier` (Line 1618, 72 lines) - `Invoke-PatternRecognitionAnalysis` (Line 2332, 63 lines) - `Invoke-PlattScaling` (Line 2080, 32 lines) - `Invoke-RecommendationClassifier` (Line 1692, 64 lines) - `New-EntityNode` (Line 650, 49 lines) - `New-EntityRelationship` (Line 701, 43 lines) - `Test-EntityContextValidation` (Line 1169, 78 lines) - `Test-PatternValidation` (Line 361, 38 lines) - `Update-BayesianPriors` (Line 2010, 24 lines) - `Write-PatternLog` (Line 475, 33 lines) 
### PatternRecognitionEngine

- **Path:** `Modules\Unity-Claude-CLIOrchestrator\Core\PatternRecognitionEngine.psm1`
- **Size:** 11.03 KB
- **Functions:** 4
- **Lines:** 283
- **Last Modified:** 08/26/2025 22:06:28

**Functions:**
- `Get-PatternRecognitionStatus` (Line 200, 39 lines) - `Invoke-PatternRecognitionAnalysis` (Line 70, 87 lines) - `Test-PatternRecognitionPerformance` (Line 163, 35 lines) - `Write-PatternLog` (Line 35, 29 lines) 
### Performance-Cache

- **Path:** `Modules\Unity-Claude-CPG\Core\Performance-Cache.psm1`
- **Size:** 20.32 KB
- **Functions:** 32
- **Lines:** 679
- **Last Modified:** 08/28/2025 16:26:50

**Functions:**
- `CacheItem` (Line 19, 12 lines, 3 params) - `CacheWarmingStrategy` (Line 372, 4 lines, 1 params) - `CleanupExpiredItems` (Line 287, 40 lines) - `Clear` (Line 257, 14 lines) - `Clear-Cache` (Line 516, 9 lines) - `ContainsKey` (Line 238, 16 lines, 1 params) - `Dispose` (Line 353, 9 lines) - `EvictLRU` (Line 274, 10 lines) - `Get` (Line 155, 53 lines, 1 params) - `Get-CacheItem` (Line 488, 12 lines) - `Get-CacheStatistics` (Line 527, 20 lines) - `GetHitRatio` (Line 54, 3 lines) - `GetKeys` (Line 341, 9 lines) - `GetStatistics` (Line 336, 2 lines) - `GetUptime` (Line 59, 2 lines) - `InitializeCleanupTimer` (Line 94, 13 lines) - `IsExpired` (Line 33, 2 lines) - `New-CacheWarmingStrategy` (Line 549, 16 lines) - `New-PerformanceCache` (Line 439, 22 lines) - `PerformanceCache` (Line 77, 14 lines, 2 params) - `PredictiveWarm` (Line 415, 19 lines, 2 params) - `ProgressiveWarm` (Line 400, 12 lines, 1 params) - `Remove` (Line 211, 24 lines, 1 params) - `Remove-CacheItem` (Line 502, 12 lines) - `Set` (Line 114, 38 lines, 3 params) - `Set` (Line 110, 2 lines, 2 params) - `Set-CacheItem` (Line 463, 23 lines) - `Start-CacheWarming` (Line 567, 41 lines) - `Test-CachePerformance` (Line 610, 52 lines) - `UpdateAccess` (Line 37, 3 lines) - `UpdateMemoryEstimate` (Line 330, 3 lines) - `WarmCache` (Line 379, 18 lines, 1 params) 
### Performance-IncrementalUpdates

- **Path:** `Modules\Unity-Claude-CPG\Core\Performance-IncrementalUpdates.psm1`
- **Size:** 27.26 KB
- **Functions:** 23
- **Lines:** 752
- **Last Modified:** 08/28/2025 16:49:00

**Functions:**
- `Add-GraphUpdate` (Line 611, 22 lines) - `BatchProcessChanges` (Line 307, 32 lines, 2 params) - `ClearCache` (Line 342, 18 lines, 1 params) - `ComputeHash` (Line 54, 16 lines, 1 params) - `DetectChanges` (Line 131, 125 lines, 3 params) - `DiffResult` (Line 83, 8 lines, 2 params) - `FileChangeInfo` (Line 20, 12 lines, 1 params) - `FlushUpdates` (Line 422, 18 lines) - `Get-FileChanges` (Line 528, 33 lines) - `Get-IncrementalStatistics` (Line 583, 8 lines) - `Get-PendingGraphUpdates` (Line 635, 20 lines) - `GetStatistics` (Line 363, 13 lines) - `GraphUpdateOptimizer` (Line 386, 13 lines, 1 params) - `HasChanged` (Line 34, 18 lines, 1 params) - `IncrementalUpdateEngine` (Line 108, 20 lines, 2 params) - `New-GraphUpdateOptimizer` (Line 593, 16 lines) - `New-IncrementalUpdateEngine` (Line 451, 19 lines) - `Process-IncrementalUpdates` (Line 563, 18 lines) - `ProcessFileDiff` (Line 259, 45 lines, 3 params) - `QueueUpdate` (Line 402, 17 lines, 2 params) - `ShouldFlush` (Line 443, 3 lines) - `Start-IncrementalMonitoring` (Line 472, 54 lines) - `Test-IncrementalPerformance` (Line 657, 78 lines) 
### PerformanceAnalysis

- **Path:** `Modules\Unity-Claude-IntegratedWorkflow\Core\PerformanceAnalysis.psm1`
- **Size:** 15.12 KB
- **Functions:** 2
- **Lines:** 298
- **Last Modified:** 08/26/2025 11:46:18

**Functions:**
- `Get-OptimizationRecommendations` (Line 213, 42 lines) - `Get-WorkflowPerformanceAnalysis` (Line 17, 193 lines) 
### PerformanceMonitoring

- **Path:** `Modules\Unity-Claude-PerformanceOptimizer\Core\PerformanceMonitoring.psm1`
- **Size:** 9.89 KB
- **Functions:** 6
- **Lines:** 274
- **Last Modified:** 08/26/2025 11:46:19

**Functions:**
- `Get-PerformanceBottlenecks` (Line 62, 44 lines) - `Get-PerformanceRecommendations` (Line 197, 33 lines) - `Get-ThroughputAnalysis` (Line 130, 41 lines) - `New-PerformanceTimer` (Line 109, 18 lines) - `Test-PerformanceOptimizationNeeded` (Line 174, 20 lines) - `Update-PerformanceMetrics` (Line 8, 51 lines) 
### PerformanceOptimization

- **Path:** `Modules\Unity-Claude-PerformanceOptimizer\Core\PerformanceOptimization.psm1`
- **Size:** 9.84 KB
- **Functions:** 8
- **Lines:** 296
- **Last Modified:** 08/26/2025 11:46:19

**Functions:**
- `Clear-CompletedQueue` (Line 125, 29 lines) - `Get-AdaptiveThrottling` (Line 185, 32 lines) - `Get-DynamicBatchSize` (Line 220, 30 lines) - `Optimize-BatchSize` (Line 46, 20 lines) - `Optimize-CacheSettings` (Line 69, 33 lines) - `Optimize-MemoryUsage` (Line 105, 17 lines) - `Optimize-Performance` (Line 5, 38 lines) - `Optimize-ThreadCount` (Line 157, 25 lines) 
### PerformanceOptimization

- **Path:** `Modules\Unity-Claude-IntegratedWorkflow\Core\PerformanceOptimization.psm1`
- **Size:** 20.68 KB
- **Functions:** 4
- **Lines:** 455
- **Last Modified:** 08/26/2025 11:46:18

**Functions:**
- `Get-BatchesByStrategy` (Line 332, 78 lines) - `Initialize-AdaptiveThrottling` (Line 17, 76 lines) - `New-IntelligentJobBatching` (Line 233, 96 lines) - `Update-AdaptiveThrottling` (Line 101, 124 lines) 
### PerformanceOptimizer

- **Path:** `Modules\Unity-Claude-CLIOrchestrator\Core\PerformanceOptimizer.psm1`
- **Size:** 26.96 KB
- **Functions:** 14
- **Lines:** 784
- **Last Modified:** 08/29/2025 20:46:34

**Functions:**
- `Get-CachedResult` (Line 76, 31 lines) - `Get-CacheKey` (Line 37, 22 lines) - `Get-CompiledRegex` (Line 149, 33 lines) - `Get-PerformanceRecommendations` (Line 398, 31 lines) - `Get-PerformanceReport` (Line 364, 32 lines) - `Get-StringHash` (Line 61, 13 lines) - `Invoke-CacheCleanup` (Line 435, 84 lines) - `Invoke-OptimizedEntityExtraction` (Line 525, 96 lines) - `Invoke-OptimizedRegexMatch` (Line 184, 31 lines) - `Invoke-ParallelEntityExtraction` (Line 221, 88 lines) - `Set-CachedResult` (Line 109, 34 lines) - `Start-PerformanceMonitoring` (Line 315, 14 lines) - `Stop-PerformanceMonitoring` (Line 331, 31 lines) - `Test-PerformanceOptimization` (Line 623, 107 lines) 
### PersistenceManagement

- **Path:** `Modules\Unity-Claude-AutonomousAgent\Core\PersistenceManagement.psm1`
- **Size:** 19.12 KB
- **Functions:** 8
- **Lines:** 533
- **Last Modified:** 08/26/2025 11:46:17

**Functions:**
- `Export-ConversationSession` (Line 338, 83 lines) - `Import-ConversationSession` (Line 423, 71 lines) - `Load-ConversationGoals` (Line 297, 39 lines) - `Load-ConversationHistory` (Line 232, 63 lines) - `Load-ConversationState` (Line 168, 62 lines) - `Save-ConversationGoals` (Line 128, 38 lines) - `Save-ConversationHistory` (Line 67, 59 lines) - `Save-ConversationState` (Line 7, 58 lines) 
### Predictive-Evolution

- **Path:** `Modules\Unity-Claude-CPG\Core\Predictive-Evolution.psm1`
- **Size:** 48.78 KB
- **Functions:** 19
- **Lines:** 1377
- **Last Modified:** 08/29/2025 14:50:30

**Functions:**
- `CodeChurnMetrics` (Line 73, 2 lines) - `Format-EvolutionReport` (Line 893, 41 lines) - `Get-AuthorPatterns` (Line 730, 28 lines) - `Get-CodeChurnMetrics` (Line 230, 123 lines) - `Get-CommitPatterns` (Line 697, 12 lines) - `Get-ComplexityTrends` (Line 534, 98 lines) - `Get-FileComplexityEstimate` (Line 464, 39 lines) - `Get-FileHotspots` (Line 355, 107 lines) - `Get-FileTypeEvolution` (Line 711, 17 lines) - `Get-GitCommitHistory` (Line 80, 148 lines) - `Get-LangGraphEvolutionWorkflow` (Line 1075, 40 lines) - `Get-PatternEvolution` (Line 634, 61 lines) - `Get-RefactoringPriority` (Line 505, 27 lines) - `Get-TimePatterns` (Line 760, 37 lines) - `GitCommitInfo` (Line 58, 2 lines) - `Invoke-UnifiedPredictiveAnalysis` (Line 1191, 144 lines) - `New-EvolutionReport` (Line 799, 92 lines) - `Submit-EvolutionAnalysisToLangGraph` (Line 940, 133 lines) - `Test-LangGraphEvolutionIntegration` (Line 1117, 72 lines) 
### Predictive-Maintenance

- **Path:** `Modules\Unity-Claude-CPG\Core\Predictive-Maintenance.psm1`
- **Size:** 86.99 KB
- **Functions:** 43
- **Lines:** 2298
- **Last Modified:** 08/30/2025 22:37:51

**Functions:**
- `Add-EvolutionContext` (Line 519, 34 lines) - `Add-PredictionRiskAnalysis` (Line 1275, 33 lines) - `Format-DebtOutput` (Line 597, 26 lines) - `Format-MaintenanceReport` (Line 1734, 81 lines) - `Get-CodeSmells` (Line 625, 114 lines) - `Get-ComplexityDebtCosts` (Line 475, 22 lines) - `Get-CustomSmells` (Line 778, 96 lines) - `Get-DebtCosts` (Line 437, 36 lines) - `Get-DebtRecommendation` (Line 499, 18 lines) - `Get-DebtSummary` (Line 555, 40 lines) - `Get-EnhancedAnalysisResults` (Line 1907, 50 lines) - `Get-FileComplexityMetrics` (Line 357, 61 lines) - `Get-FileDebt` (Line 279, 76 lines) - `Get-FileHealthScore` (Line 1959, 30 lines) - `Get-FileRecommendations` (Line 1991, 30 lines) - `Get-HybridPredictions` (Line 1235, 38 lines) - `Get-LangGraphMaintenanceWorkflow` (Line 2162, 40 lines) - `Get-MaintenanceAction` (Line 1189, 14 lines) - `Get-MaintenanceActionPlan` (Line 1677, 55 lines) - `Get-MaintenancePrediction` (Line 932, 89 lines) - `Get-MaintenancePriority` (Line 1168, 19 lines) - `Get-MaintenanceTimeSeries` (Line 1023, 80 lines) - `Get-MetricTrend` (Line 1150, 16 lines) - `Get-MetricVariance` (Line 1310, 17 lines) - `Get-PSASmells` (Line 741, 35 lines) - `Get-RefactoringRecommendations` (Line 1329, 122 lines) - `Get-RegressionPredictions` (Line 1205, 28 lines) - `Get-RepositoryHealthScore` (Line 1652, 23 lines) - `Get-SafeChildItems` (Line 42, 11 lines) - `Get-SmellImpact` (Line 896, 18 lines) - `Get-SmellPriority` (Line 876, 18 lines) - `Get-SmellSortOrder` (Line 916, 14 lines) - `Get-TechnicalDebt` (Line 158, 119 lines) - `Get-TrendBasedPredictions` (Line 1105, 43 lines) - `Get-ViolationCategory` (Line 420, 15 lines) - `Invoke-PSScriptAnalyzerEnhanced` (Line 1817, 88 lines) - `MaintenancePrediction` (Line 119, 3 lines) - `New-FileRefactoringRecommendation` (Line 1453, 67 lines) - `New-MaintenanceReport` (Line 1522, 128 lines) - `RefactoringRecommendation` (Line 136, 2 lines) - `Submit-MaintenanceAnalysisToLangGraph` (Line 2027, 133 lines) - `TechnicalDebtItem` (Line 104, 2 lines) - `Test-LangGraphMaintenanceIntegration` (Line 2204, 72 lines) 
### PredictiveCore

- **Path:** `Modules\Unity-Claude-PredictiveAnalysis\Core\PredictiveCore.psm1`
- **Size:** 9.52 KB
- **Functions:** 7
- **Lines:** 323
- **Last Modified:** 08/26/2025 11:46:19

**Functions:**
- `Clear-PredictiveCache` (Line 211, 16 lines) - `Get-CacheItem` (Line 142, 28 lines) - `Get-PredictiveConfig` (Line 86, 13 lines) - `Initialize-PredictiveCache` (Line 14, 70 lines) - `New-CacheManager` (Line 229, 46 lines) - `Set-CacheItem` (Line 172, 37 lines) - `Set-PredictiveConfig` (Line 101, 39 lines) 
### PriorityActionQueue

- **Path:** `Modules\Unity-Claude-CLIOrchestrator\Core\DecisionEngine\PriorityActionQueue.psm1`
- **Size:** 9.74 KB
- **Functions:** 5
- **Lines:** 280
- **Last Modified:** 08/26/2025 11:46:17

**Functions:**
- `Clear-ActionQueue` (Line 163, 31 lines) - `Get-ActionQueueStatus` (Line 122, 38 lines) - `New-ActionQueueItem` (Line 32, 87 lines) - `Test-ActionQueueCapacity` (Line 13, 16 lines) - `Update-ActionStatus` (Line 197, 37 lines) 
### ProductionRunspacePool

- **Path:** `Modules\Unity-Claude-RunspaceManagement\Core\ProductionRunspacePool.psm1`
- **Size:** 24.32 KB
- **Functions:** 8
- **Lines:** 582
- **Last Modified:** 08/26/2025 11:46:19

**Functions:**
- `Get-RunspaceJobResults` (Line 469, 67 lines) - `New-ProductionRunspacePool` (Line 38, 98 lines) - `Submit-RunspaceJob` (Line 138, 92 lines) - `Test-RunspacePoolResources` (Line 35, 0 lines) - `Update-RunspaceJobStatus` (Line 232, 156 lines) - `Update-RunspacePoolRegistry` (Line 34, 0 lines) - `Wait-RunspaceJobs` (Line 390, 77 lines) - `Write-ModuleLog` (Line 28, 4 lines) 
### ProgressTracker

- **Path:** `Modules\Unity-Claude-ScalabilityEnhancements\Core\ProgressTracker.psm1`
- **Size:** 8.87 KB
- **Functions:** 13
- **Lines:** 261
- **Last Modified:** 08/26/2025 11:46:19

**Functions:**
- `Cancel` (Line 78, 2 lines) - `Cancel-Operation` (Line 178, 15 lines) - `Get-ProgressReport` (Line 127, 14 lines) - `GetProgressReport` (Line 60, 12 lines) - `IsCancellationRequested` (Line 82, 2 lines) - `New-CancellationToken` (Line 143, 23 lines) - `New-ProgressTracker` (Line 87, 18 lines) - `ProgressTracker` (Line 18, 13 lines, 2 params) - `Register-ProgressCallback` (Line 195, 18 lines) - `RegisterCallback` (Line 74, 2 lines, 1 params) - `Test-CancellationRequested` (Line 168, 8 lines) - `Update-OperationProgress` (Line 107, 18 lines) - `UpdateProgress` (Line 33, 25 lines, 1 params) 
### ProjectConfiguration

- **Path:** `Modules\Unity-Claude-UnityParallelization\Core\ProjectConfiguration.psm1`
- **Size:** 15.66 KB
- **Functions:** 6
- **Lines:** 412
- **Last Modified:** 08/26/2025 11:46:19

**Functions:**
- `Find-UnityProjects` (Line 21, 83 lines) - `Get-RegisteredUnityProjects` (Line 234, 19 lines) - `Get-UnityProjectConfiguration` (Line 200, 32 lines) - `Register-UnityProject` (Line 106, 92 lines) - `Set-UnityProjectConfiguration` (Line 255, 49 lines) - `Test-UnityProjectAvailability` (Line 306, 52 lines) 
### PromptConfiguration

- **Path:** `Modules\Unity-Claude-AutonomousAgent\Core\PromptConfiguration.psm1`
- **Size:** 4.4 KB
- **Functions:** 1
- **Lines:** 96
- **Last Modified:** 08/26/2025 11:46:17

**Functions:**
- `Get-PromptEngineConfig` (Line 45, 9 lines) 
### PromptSubmissionEngine

- **Path:** `Modules\Unity-Claude-CLIOrchestrator\Core\PromptSubmissionEngine.psm1`
- **Size:** 14.55 KB
- **Functions:** 2
- **Lines:** 366
- **Last Modified:** 08/26/2025 11:46:17

**Functions:**
- `Execute-TestScript` (Line 166, 159 lines) - `Submit-ToClaudeViaTypeKeys` (Line 19, 145 lines) 
### PromptTemplateSystem

- **Path:** `Modules\Unity-Claude-AutonomousAgent\Core\PromptTemplateSystem.psm1`
- **Size:** 18.22 KB
- **Functions:** 7
- **Lines:** 473
- **Last Modified:** 08/26/2025 11:46:17

**Functions:**
- `Invoke-TemplateRendering` (Line 376, 49 lines) - `New-ARPPromptTemplate` (Line 252, 71 lines) - `New-ContinuePromptTemplate` (Line 200, 50 lines) - `New-DebuggingPromptTemplate` (Line 76, 62 lines) - `New-DefaultPromptTemplate` (Line 325, 49 lines) - `New-PromptTemplate` (Line 8, 66 lines) - `New-TestResultsPromptTemplate` (Line 140, 58 lines) 
### PromptTypeSelection

- **Path:** `Modules\Unity-Claude-AutonomousAgent\Core\PromptTypeSelection.psm1`
- **Size:** 19.73 KB
- **Functions:** 4
- **Lines:** 499
- **Last Modified:** 08/26/2025 11:46:17

**Functions:**
- `Invoke-DecisionTreeAnalysis` (Line 247, 74 lines) - `Invoke-NodeEvaluation` (Line 323, 131 lines) - `Invoke-PromptTypeSelection` (Line 8, 66 lines) - `New-PromptTypeDecisionTree` (Line 76, 169 lines) 
### PSGraph

- **Path:** `Tools\PSGraph\2.1.38.27\PSGraph.psm1`
- **Size:** 48.11 KB
- **Functions:** 23
- **Lines:** 1819
- **Last Modified:** 03/16/2019 00:59:54

**Functions:**
- `ConvertTo-GraphVizAttribute` (Line 4, 101 lines) - `Edge` (Line 374, 209 lines) - `Entity` (Line 594, 120 lines) - `Export-PSGraph` (Line 717, 208 lines) - `Format-KeyName` (Line 108, 26 lines) - `Format-Value` (Line 136, 59 lines) - `Get-ArgumentLookupTable` (Line 198, 15 lines) - `Get-GraphVizArgument` (Line 216, 34 lines) - `Get-Indent` (Line 253, 13 lines) - `Get-LayoutEngine` (Line 269, 18 lines, 1 params) - `Get-OutputFormatFromPath` (Line 290, 22 lines, 1 params) - `Get-TranslatedArgument` (Line 315, 20 lines, 1 params) - `Graph` (Line 928, 150 lines) - `Inline` (Line 1081, 35 lines) - `Install-GraphViz` (Line 1119, 40 lines) - `Node` (Line 1162, 110 lines) - `Rank` (Line 1275, 101 lines) - `Record` (Line 1380, 126 lines) - `Row` (Line 1510, 95 lines) - `Set-NodeFormatScript` (Line 1607, 34 lines) - `Show-PSGraph` (Line 1644, 78 lines) - `SubGraph` (Line 1724, 92 lines) - `Update-DefaultArgument` (Line 338, 32 lines) 
### QueueManagement

- **Path:** `Modules\Unity-Claude-NotificationIntegration\Queue\QueueManagement.psm1`
- **Size:** 11.95 KB
- **Functions:** 6
- **Lines:** 339
- **Last Modified:** 08/21/2025 17:45:27

**Functions:**
- `Add-NotificationToQueue` (Line 52, 73 lines) - `Clear-NotificationQueue` (Line 245, 28 lines) - `Get-FailedNotifications` (Line 275, 16 lines) - `Get-QueueStatus` (Line 198, 45 lines) - `Initialize-NotificationQueue` (Line 7, 43 lines) - `Process-NotificationQueue` (Line 127, 69 lines) 
### ReadabilityAlgorithms

- **Path:** `Modules\Unity-Claude-DocumentationQualityAssessment\Components\ReadabilityAlgorithms.psm1`
- **Size:** 14.1 KB
- **Functions:** 8
- **Lines:** 402
- **Last Modified:** 08/30/2025 19:48:47

**Functions:**
- `Analyze-TextStatistics` (Line 92, 62 lines) - `Calculate-ComprehensiveReadabilityScores` (Line 23, 67 lines) - `Estimate-SyllableCount` (Line 156, 25 lines) - `Generate-ReadabilityRecommendations` (Line 394, 3 lines) - `Get-ReadabilityLevel` (Line 183, 9 lines) - `Measure-FleschKincaidScore` (Line 194, 69 lines) - `Measure-GunningFogScore` (Line 265, 63 lines) - `Measure-SMOGScore` (Line 330, 62 lines) 
### RecommendationPatternEngine

- **Path:** `Modules\Unity-Claude-CLIOrchestrator\Core\RecommendationPatternEngine.psm1`
- **Size:** 11.93 KB
- **Functions:** 2
- **Lines:** 307
- **Last Modified:** 08/25/2025 14:20:03

**Functions:**
- `Find-RecommendationPatterns` (Line 161, 103 lines) - `Initialize-CompiledPatterns` (Line 121, 38 lines) 
### RefactoringDetection

- **Path:** `Modules\Unity-Claude-PredictiveAnalysis\Core\RefactoringDetection.psm1`
- **Size:** 23.67 KB
- **Functions:** 6
- **Lines:** 602
- **Last Modified:** 08/26/2025 11:46:19

**Functions:**
- `Calculate-FunctionSimilarity` (Line 372, 93 lines) - `Find-GodClasses` (Line 203, 89 lines) - `Find-LongMethods` (Line 143, 58 lines) - `Find-RefactoringOpportunities` (Line 12, 129 lines) - `Get-CouplingIssues` (Line 467, 88 lines) - `Get-DuplicationCandidates` (Line 294, 76 lines) 
### ReportingExport

- **Path:** `Modules\Unity-Claude-PerformanceOptimizer\Core\ReportingExport.psm1`
- **Size:** 12.62 KB
- **Functions:** 6
- **Lines:** 352
- **Last Modified:** 08/26/2025 11:46:19

**Functions:**
- `Export-PerformanceData` (Line 5, 40 lines) - `Export-ToCsv` (Line 83, 29 lines) - `Export-ToHtml` (Line 115, 153 lines) - `Export-ToJson` (Line 48, 32 lines) - `Export-ToXml` (Line 271, 11 lines) - `Get-PerformanceSummary` (Line 285, 23 lines) 
### ResponseAnalysis

- **Path:** `Modules\Unity-Claude-DecisionEngine\Core\ResponseAnalysis.psm1`
- **Size:** 17.63 KB
- **Functions:** 12
- **Lines:** 541
- **Last Modified:** 08/26/2025 11:46:18

**Functions:**
- `Add-ContextualEnrichment` (Line 396, 37 lines) - `Calculate-SemanticConfidence` (Line 310, 29 lines) - `Get-ConversationConsistency` (Line 451, 21 lines) - `Get-ConversationFlowAnalysis` (Line 439, 10 lines) - `Get-IntentClassification` (Line 197, 29 lines) - `Get-LastSimilarResponse` (Line 474, 14 lines) - `Get-SemanticActions` (Line 277, 31 lines) - `Get-SemanticContext` (Line 228, 47 lines) - `Invoke-AIEnhancedAnalysis` (Line 156, 39 lines) - `Invoke-HybridResponseAnalysis` (Line 13, 52 lines) - `Invoke-RegexBasedAnalysis` (Line 71, 79 lines) - `Merge-AnalysisResults` (Line 345, 49 lines) 
### ResponseAnalysisEngine-Broken

- **Path:** `Modules\Unity-Claude-CLIOrchestrator\Core\ResponseAnalysisEngine-Broken.psm1`
- **Size:** 92.6 KB
- **Functions:** 39
- **Lines:** 2613
- **Last Modified:** 08/26/2025 22:17:52

**Functions:**
- `Add-TemporalContext` (Line 1367, 25 lines) - `Analyze-ResponseSentiment` (Line 612, 110 lines) - `Build-EntityRelationshipGraph` (Line 1177, 61 lines) - `Build-NGramModel` (Line 1019, 53 lines) - `Calculate-PatternConfidence` (Line 842, 125 lines) - `Calculate-PatternSimilarity` (Line 1074, 97 lines) - `ConvertFrom-JsonFast` (Line 222, 32 lines) - `Extract-ResponseEntities` (Line 503, 107 lines) - `Find-EntityClusters` (Line 1308, 47 lines) - `Get-ConfidenceBand` (Line 969, 11 lines) - `Get-ResponseContext` (Line 724, 86 lines) - `Get-ResponseMonitoringStatus` (Line 2290, 62 lines) - `Get-TemporalContextRelevance` (Line 1394, 61 lines) - `Initialize-ResponseMonitoring` (Line 1988, 80 lines) - `Invoke-BayesianConfidenceAdjustment` (Line 982, 31 lines) - `Invoke-EnhancedPatternAnalysis` (Line 1461, 78 lines) - `Invoke-EnhancedResponseAnalysis` (Line 397, 100 lines) - `Invoke-MultiParserJson` (Line 256, 59 lines) - `Invoke-ResponseCallbacks` (Line 2226, 19 lines) - `Invoke-UniversalResponseParser` (Line 1849, 121 lines) - `Measure-EntityProximity` (Line 1240, 66 lines) - `Parse-MixedFormatResponse` (Line 1639, 208 lines) - `Process-ResponseFile` (Line 2140, 66 lines) - `Register-ResponseCallback` (Line 2208, 16 lines) - `Repair-TruncatedJson` (Line 170, 46 lines) - `Start-ResponseProcessingWorker` (Line 2070, 68 lines) - `Stop-ResponseMonitoring` (Line 2247, 41 lines) - `Test-AnthropicResponseSchema` (Line 362, 29 lines) - `Test-CircuitBreakerState` (Line 73, 25 lines) - `Test-EnhancedParsingIntegration` (Line 2502, 37 lines) - `Test-FileProcessing` (Line 2433, 29 lines) - `Test-JsonSchema` (Line 321, 39 lines) - `Test-JsonTruncation` (Line 132, 36 lines) - `Test-MonitorInitialization` (Line 2410, 21 lines) - `Test-QueueProcessing` (Line 2464, 36 lines) - `Test-ResponseFormat` (Line 1545, 92 lines) - `Test-ResponseMonitoringIntegration` (Line 2354, 54 lines) - `Update-CircuitBreakerState` (Line 100, 26 lines) - `Write-AnalysisLog` (Line 33, 34 lines) 
### ResponseAnalysisEngine-Core-Fixed

- **Path:** `Modules\Unity-Claude-CLIOrchestrator\Core\Components\ResponseAnalysisEngine-Core-Fixed.psm1`
- **Size:** 13.52 KB
- **Functions:** 4
- **Lines:** 425
- **Last Modified:** 08/27/2025 16:57:38

**Functions:**
- `Analyze-ResponseSentiment` (Line 59, 71 lines) - `Extract-ResponseEntities` (Line 136, 54 lines) - `Get-ResponseContext` (Line 196, 81 lines) - `Invoke-EnhancedResponseAnalysis` (Line 283, 127 lines) 
### ResponseAnalysisEngine-Core

- **Path:** `Modules\Unity-Claude-CLIOrchestrator\Core\Components\ResponseAnalysisEngine-Core.psm1`
- **Size:** 22.47 KB
- **Functions:** 6
- **Lines:** 594
- **Last Modified:** 08/27/2025 15:39:53

**Functions:**
- `Analyze-ResponseSentiment` (Line 47, 115 lines) - `Extract-ResponseEntities` (Line 466, 110 lines) - `Get-ResponseAnalysisEngineStatus` (Line 360, 23 lines) - `Initialize-ResponseAnalysisEngine` (Line 326, 32 lines) - `Invoke-EnhancedResponseAnalysis` (Line 168, 156 lines) - `Test-ResponseAnalysisEngineCore` (Line 389, 71 lines) 
### ResponseAnalysisEngine-Enhanced

- **Path:** `Modules\Unity-Claude-CLIOrchestrator\Core\ResponseAnalysisEngine-Enhanced.psm1`
- **Size:** 28.2 KB
- **Functions:** 12
- **Lines:** 829
- **Last Modified:** 08/25/2025 13:45:24

**Functions:**
- `Add-TemporalContext` (Line 599, 25 lines) - `Build-EntityRelationshipGraph` (Line 409, 61 lines) - `Build-NGramModel` (Line 210, 56 lines) - `Calculate-PatternConfidence` (Line 33, 125 lines) - `Calculate-PatternSimilarity` (Line 306, 97 lines) - `Find-EntityClusters` (Line 540, 47 lines) - `Get-ConfidenceBand` (Line 160, 11 lines) - `Get-TemporalContextRelevance` (Line 626, 61 lines) - `Invoke-BayesianConfidenceAdjustment` (Line 173, 31 lines) - `Invoke-EnhancedPatternAnalysis` (Line 693, 78 lines) - `Measure-EntityProximity` (Line 472, 66 lines) - `Update-NGramDatabase` (Line 268, 36 lines) 
### ResponseAnalysisEngine

- **Path:** `Modules\Unity-Claude-CLIOrchestrator\Core\ResponseAnalysisEngine.psm1`
- **Size:** 28.2 KB
- **Functions:** 12
- **Lines:** 829
- **Last Modified:** 08/25/2025 13:45:24

**Functions:**
- `Add-TemporalContext` (Line 599, 25 lines) - `Build-EntityRelationshipGraph` (Line 409, 61 lines) - `Build-NGramModel` (Line 210, 56 lines) - `Calculate-PatternConfidence` (Line 33, 125 lines) - `Calculate-PatternSimilarity` (Line 306, 97 lines) - `Find-EntityClusters` (Line 540, 47 lines) - `Get-ConfidenceBand` (Line 160, 11 lines) - `Get-TemporalContextRelevance` (Line 626, 61 lines) - `Invoke-BayesianConfidenceAdjustment` (Line 173, 31 lines) - `Invoke-EnhancedPatternAnalysis` (Line 693, 78 lines) - `Measure-EntityProximity` (Line 472, 66 lines) - `Update-NGramDatabase` (Line 268, 36 lines) 
### ResponseClassificationEngine

- **Path:** `Modules\Unity-Claude-CLIOrchestrator\Core\ResponseClassificationEngine.psm1`
- **Size:** 25.17 KB
- **Functions:** 12
- **Lines:** 636
- **Last Modified:** 08/25/2025 14:20:04

**Functions:**
- `Classify-ResponseType` (Line 152, 49 lines) - `Get-BayesianPriorAdjustment` (Line 501, 39 lines) - `Get-EnhancedFeatureEngineering` (Line 56, 71 lines) - `Invoke-BayesianClassificationCalibration` (Line 428, 37 lines) - `Invoke-DecisionTreeClassifier` (Line 203, 47 lines) - `Invoke-EnsembleVoting` (Line 380, 46 lines) - `Invoke-EntityContextClassifier` (Line 342, 36 lines) - `Invoke-FeatureBasedClassifier` (Line 252, 52 lines) - `Invoke-PlattScaling` (Line 467, 32 lines) - `Invoke-RecommendationClassifier` (Line 306, 34 lines) - `Test-FeaturePattern` (Line 129, 17 lines) - `Update-ClassificationStatistics` (Line 542, 50 lines) 
### ResponseMonitoring

- **Path:** `Modules\Unity-Claude-AutonomousAgent\Monitoring\ResponseMonitoring.psm1`
- **Size:** 15.06 KB
- **Functions:** 5
- **Lines:** 368
- **Last Modified:** 08/20/2025 17:25:21

**Functions:**
- `Add-RecommendationToQueue` (Line 192, 40 lines) - `Find-ClaudeRecommendations` (Line 135, 55 lines) - `Invoke-ProcessClaudeResponse` (Line 15, 118 lines) - `Invoke-ProcessCommandQueue` (Line 234, 25 lines) - `Submit-PromptToClaude` (Line 261, 60 lines) 
### ResponseParsing

- **Path:** `Modules\Unity-Claude-AutonomousAgent\Parsing\ResponseParsing.psm1`
- **Size:** 26.9 KB
- **Functions:** 6
- **Lines:** 691
- **Last Modified:** 08/20/2025 17:25:21

**Functions:**
- `Extract-CommandsFromResponse` (Line 281, 73 lines) - `Get-ResponseCategorization` (Line 356, 130 lines) - `Get-ResponseEntities` (Line 488, 77 lines) - `Get-ResponseQualityScore` (Line 222, 57 lines) - `Invoke-EnhancedResponseParsing` (Line 115, 105 lines) - `Test-ResponseParsingModule` (Line 567, 76 lines) 
### ResultAnalysisEngine

- **Path:** `Modules\Unity-Claude-AutonomousAgent\Core\ResultAnalysisEngine.psm1`
- **Size:** 26.47 KB
- **Functions:** 6
- **Lines:** 650
- **Last Modified:** 08/26/2025 11:46:17

**Functions:**
- `Find-ResultPatterns` (Line 395, 90 lines) - `Get-HistoricalPatterns` (Line 487, 26 lines) - `Get-NextActionRecommendations` (Line 515, 88 lines) - `Get-ResultClassification` (Line 101, 167 lines) - `Get-ResultSeverity` (Line 270, 123 lines) - `Invoke-CommandResultAnalysis` (Line 8, 91 lines) 
### RetryLogic

- **Path:** `Modules\Unity-Claude-NotificationIntegration\Reliability\RetryLogic.psm1`
- **Size:** 8.88 KB
- **Functions:** 6
- **Lines:** 261
- **Last Modified:** 08/21/2025 17:45:27

**Functions:**
- `Calculate-RetryDelay` (Line 192, 22 lines) - `Get-NotificationDeliveryStatus` (Line 150, 18 lines) - `Invoke-NotificationWithRetry` (Line 40, 58 lines) - `New-NotificationRetryPolicy` (Line 7, 31 lines) - `Reset-NotificationRetryState` (Line 170, 16 lines) - `Test-NotificationDelivery` (Line 100, 48 lines) 
### RiskAssessment

- **Path:** `Modules\Unity-Claude-PredictiveAnalysis\Core\RiskAssessment.psm1`
- **Size:** 41.07 KB
- **Functions:** 18
- **Lines:** 1115
- **Last Modified:** 08/26/2025 11:46:19

**Functions:**
- `Find-AntiPatterns` (Line 310, 72 lines) - `Find-CircularDependencies` (Line 754, 36 lines) - `Find-CircularDependencyDFS` (Line 792, 33 lines) - `Find-CopyPasteProgramming` (Line 426, 56 lines) - `Find-DependencyViolations` (Line 874, 52 lines) - `Find-GoldenHammer` (Line 484, 61 lines) - `Find-InterfaceViolations` (Line 827, 45 lines) - `Find-MagicConstants` (Line 547, 42 lines) - `Find-ResponsibilityViolations` (Line 928, 40 lines) - `Find-ShotgunSurgery` (Line 591, 44 lines) - `Find-SpaghettiCode` (Line 384, 40 lines) - `Get-AntiPatternRecommendations` (Line 637, 45 lines) - `Get-ArchitecturalHealthScore` (Line 970, 53 lines) - `Get-BugPreventionActions` (Line 198, 56 lines) - `Get-DesignFlawRecommendations` (Line 1025, 45 lines) - `Get-DesignFlaws` (Line 684, 68 lines) - `Get-MaintenanceRisk` (Line 256, 52 lines) - `Predict-BugProbability` (Line 21, 175 lines) 
### RoleAwareManagement

- **Path:** `Modules\Unity-Claude-AutonomousAgent\Core\RoleAwareManagement.psm1`
- **Size:** 18.58 KB
- **Functions:** 9
- **Lines:** 478
- **Last Modified:** 08/26/2025 11:46:17

**Functions:**
- `Add-RoleAwareHistoryItem` (Line 7, 91 lines) - `Analyze-DialogueHistory` (Line 420, 21 lines) - `Analyze-Sentiment` (Line 361, 13 lines) - `Classify-DialogueAct` (Line 388, 15 lines) - `Detect-TopicShift` (Line 405, 13 lines) - `Extract-Keywords` (Line 376, 10 lines) - `Get-RoleAwareHistory` (Line 100, 63 lines) - `Update-ConversationEffectiveness` (Line 249, 109 lines) - `Update-DialoguePatterns` (Line 165, 82 lines) 
### RuleBasedDecisionTrees

- **Path:** `Modules\Unity-Claude-CLIOrchestrator\Core\DecisionEngine\RuleBasedDecisionTrees.psm1`
- **Size:** 11.64 KB
- **Functions:** 2
- **Lines:** 267
- **Last Modified:** 08/26/2025 11:46:17

**Functions:**
- `Invoke-RuleBasedDecision` (Line 9, 106 lines) - `Resolve-PriorityDecision` (Line 118, 106 lines) 
### RunspaceCore

- **Path:** `Modules\Unity-Claude-RunspaceManagement\Core\RunspaceCore.psm1`
- **Size:** 6.92 KB
- **Functions:** 8
- **Lines:** 202
- **Last Modified:** 08/26/2025 11:46:19

**Functions:**
- `Get-RunspacePoolRegistry` (Line 89, 9 lines) - `Get-SessionStatesRegistry` (Line 124, 9 lines) - `Get-SharedVariablesDictionary` (Line 112, 9 lines) - `Test-ModuleDependencyAvailability` (Line 14, 20 lines) - `Update-RunspacePoolRegistry` (Line 101, 8 lines) - `Update-SessionStateRegistry` (Line 136, 8 lines) - `Write-FallbackLog` (Line 51, 16 lines) - `Write-ModuleLog` (Line 70, 16 lines) 
### RunspaceManagement

- **Path:** `Modules\SafeCommandExecution\Core\RunspaceManagement.psm1`
- **Size:** 7.01 KB
- **Functions:** 3
- **Lines:** 195
- **Last Modified:** 08/26/2025 11:46:17

**Functions:**
- `New-ConstrainedRunspace` (Line 21, 81 lines) - `Remove-ConstrainedRunspace` (Line 104, 21 lines) - `Test-RunspaceHealth` (Line 127, 17 lines) 
### RunspacePoolManagement

- **Path:** `Modules\Unity-Claude-RunspaceManagement\Core\RunspacePoolManagement.psm1`
- **Size:** 14.72 KB
- **Functions:** 9
- **Lines:** 408
- **Last Modified:** 08/26/2025 11:46:19

**Functions:**
- `Close-RunspacePool` (Line 146, 64 lines) - `Get-AllRunspacePools` (Line 335, 26 lines) - `Get-RunspacePoolRegistry` (Line 27, 0 lines) - `Get-RunspacePoolStatus` (Line 212, 53 lines) - `New-ManagedRunspacePool` (Line 33, 65 lines) - `Open-RunspacePool` (Line 100, 44 lines) - `Test-RunspacePoolHealth` (Line 267, 66 lines) - `Update-RunspacePoolRegistry` (Line 26, 0 lines) - `Write-ModuleLog` (Line 21, 4 lines) 
### RunspacePoolManager

- **Path:** `Modules\Unity-Claude-ParallelProcessor\Core\RunspacePoolManager.psm1`
- **Size:** 15.02 KB
- **Functions:** 11
- **Lines:** 341
- **Last Modified:** 08/26/2025 11:46:19

**Functions:**
- `Close` (Line 149, 15 lines) - `ConfigureRunspacePool` (Line 98, 29 lines) - `CreateInitialSessionState` (Line 38, 34 lines) - `CreateRunspacePool` (Line 75, 20 lines) - `Dispose` (Line 167, 15 lines) - `GetRunspacePoolInfo` (Line 202, 10 lines) - `New-RunspacePoolManager` (Line 219, 33 lines) - `Open` (Line 130, 16 lines) - `RunspacePoolManager` (Line 24, 11 lines, 4 params) - `SetRunspacePoolSize` (Line 185, 14 lines, 2 params) - `Test-RunspacePoolHealth` (Line 254, 36 lines) 
### Safe-FileEnumeration

- **Path:** `Safe-FileEnumeration.psm1`
- **Size:** 1.89 KB
- **Functions:** 1
- **Lines:** 62
- **Last Modified:** 08/29/2025 18:05:57

**Functions:**
- `Get-SafeChildItems` (Line 17, 41 lines) 
### SafeCommandCore

- **Path:** `Modules\SafeCommandExecution\Core\SafeCommandCore.psm1`
- **Size:** 7.33 KB
- **Functions:** 4
- **Lines:** 223
- **Last Modified:** 08/26/2025 11:46:17

**Functions:**
- `Get-SafeCommandConfig` (Line 89, 9 lines) - `Set-SafeCommandConfig` (Line 100, 31 lines) - `Test-SafeCommandInitialization` (Line 133, 35 lines) - `Write-SafeLog` (Line 40, 43 lines) 
### SafeCommandExecution-Original

- **Path:** `Modules\SafeCommandExecution\SafeCommandExecution-Original.psm1`
- **Size:** 99.06 KB
- **Functions:** 30
- **Lines:** 2872
- **Last Modified:** 08/26/2025 11:46:17

**Functions:**
- `Export-UnityAnalysisData` (Line 2411, 142 lines) - `Find-UnityExecutable` (Line 2730, 25 lines) - `Get-SafeCommandConfiguration` (Line 2786, 5 lines) - `Get-UnityAnalyticsMetrics` (Line 2555, 169 lines) - `Invoke-AnalysisCommand` (Line 647, 75 lines) - `Invoke-BuildCommand` (Line 580, 65 lines) - `Invoke-PowerShellCommand` (Line 524, 54 lines) - `Invoke-SafeCommand` (Line 329, 72 lines) - `Invoke-TestCommand` (Line 465, 57 lines) - `Invoke-UnityAssetImport` (Line 1047, 103 lines) - `Invoke-UnityCommand` (Line 407, 56 lines) - `Invoke-UnityCustomMethod` (Line 1225, 100 lines) - `Invoke-UnityErrorPatternAnalysis` (Line 1776, 143 lines) - `Invoke-UnityLogAnalysis` (Line 1610, 164 lines) - `Invoke-UnityPerformanceAnalysis` (Line 1921, 183 lines) - `Invoke-UnityPlayerBuild` (Line 728, 131 lines) - `Invoke-UnityProjectValidation` (Line 1327, 113 lines) - `Invoke-UnityReportGeneration` (Line 2230, 179 lines) - `Invoke-UnityScriptCompilation` (Line 1442, 96 lines) - `Invoke-UnityTrendAnalysis` (Line 2106, 122 lines) - `New-ConstrainedRunspace` (Line 81, 64 lines) - `New-UnityAssetImportScript` (Line 1152, 71 lines) - `New-UnityBuildScript` (Line 861, 87 lines) - `Remove-DangerousCharacters` (Line 304, 19 lines) - `Set-SafeCommandConfiguration` (Line 2757, 27 lines) - `Test-CommandSafety` (Line 151, 114 lines) - `Test-PathSafety` (Line 267, 35 lines) - `Test-UnityBuildResult` (Line 950, 95 lines) - `Test-UnityCompilationResult` (Line 1540, 64 lines) - `Write-SafeLog` (Line 40, 35 lines) 
### SafeCommandExecution-Refactored

- **Path:** `Modules\SafeCommandExecution\SafeCommandExecution-Refactored.psm1`
- **Size:** 12.93 KB
- **Functions:** 3
- **Lines:** 353
- **Last Modified:** 08/26/2025 11:46:17

**Functions:**
- `Get-SafeCommandStatus` (Line 131, 33 lines) - `Initialize-SafeCommandExecution` (Line 77, 52 lines) - `Test-SafeCommandIntegration` (Line 166, 74 lines) 
### SafeCommandExecution

- **Path:** `Modules\SafeCommandExecution\SafeCommandExecution.psm1`
- **Size:** 12.93 KB
- **Functions:** 3
- **Lines:** 353
- **Last Modified:** 08/26/2025 11:46:17

**Functions:**
- `Get-SafeCommandStatus` (Line 131, 33 lines) - `Initialize-SafeCommandExecution` (Line 77, 52 lines) - `Test-SafeCommandIntegration` (Line 166, 74 lines) 
### SafeExecution

- **Path:** `Modules\Unity-Claude-AutonomousAgent\Execution\SafeExecution.psm1`
- **Size:** 22.26 KB
- **Functions:** 7
- **Lines:** 593
- **Last Modified:** 08/20/2025 17:25:21

**Functions:**
- `Invoke-SafeConstrainedCommand` (Line 325, 113 lines) - `Invoke-SafeRecommendedCommand` (Line 440, 57 lines) - `New-ConstrainedRunspace` (Line 63, 82 lines) - `Sanitize-ParameterValue` (Line 499, 45 lines) - `Test-CommandSafety` (Line 147, 72 lines) - `Test-ParameterSafety` (Line 221, 53 lines) - `Test-PathSafety` (Line 276, 47 lines) 
### SafetyValidationFramework

- **Path:** `Modules\Unity-Claude-CLIOrchestrator\Core\DecisionEngine\SafetyValidationFramework.psm1`
- **Size:** 12.53 KB
- **Functions:** 3
- **Lines:** 332
- **Last Modified:** 08/26/2025 11:46:18

**Functions:**
- `Test-SafeCommand` (Line 223, 65 lines) - `Test-SafeFilePath` (Line 150, 70 lines) - `Test-SafetyValidation` (Line 9, 138 lines) 
### SecurityTokens

- **Path:** `Modules\Unity-Claude-HITL\Core\SecurityTokens.psm1`
- **Size:** 7.49 KB
- **Functions:** 4
- **Lines:** 226
- **Last Modified:** 08/26/2025 11:46:18

**Functions:**
- `Get-TokenMetadata` (Line 114, 32 lines) - `New-ApprovalToken` (Line 14, 53 lines) - `Revoke-ApprovalToken` (Line 148, 30 lines) - `Test-ApprovalToken` (Line 69, 43 lines) 
### SelfPatching

- **Path:** `Modules\Unity-Claude-Learning\Core\SelfPatching.psm1`
- **Size:** 14.37 KB
- **Functions:** 8
- **Lines:** 458
- **Last Modified:** 08/26/2025 11:46:19

**Functions:**
- `Apply-AutoFix` (Line 32, 92 lines) - `Apply-FixToFile` (Line 126, 86 lines) - `Get-ErrorType` (Line 299, 19 lines) - `Get-PatternFix` (Line 214, 36 lines) - `Get-PatternFixSQLite` (Line 252, 45 lines) - `Update-PatternSuccess` (Line 320, 39 lines) - `Update-PatternSuccessSQLite` (Line 361, 49 lines) - `Write-ModuleLog` (Line 13, 4 lines) 
### SemanticAnalysis-Metrics

- **Path:** `Modules\Unity-Claude-CPG\Core\SemanticAnalysis-Metrics.psm1`
- **Size:** 30.17 KB
- **Functions:** 9
- **Lines:** 796
- **Last Modified:** 08/28/2025 15:45:46

**Functions:**
- `Get-CBOCouplingBetweenObjects` (Line 245, 84 lines) - `Get-CHDCohesionAtDomainLevel` (Line 154, 85 lines) - `Get-CHDCohesionAtDomainLevel` (Line 408, 96 lines) - `Get-CHMCohesionAtMessageLevel` (Line 32, 120 lines) - `Get-ComprehensiveQualityMetrics` (Line 601, 128 lines) - `Get-EnhancedMaintainabilityIndex` (Line 510, 85 lines) - `Get-LCOMCohesionInMethods` (Line 331, 75 lines) - `Get-QualityMetricsConfiguration` (Line 731, 23 lines) - `Set-QualityMetricsConfiguration` (Line 756, 22 lines) 
### SemanticAnalysis-PatternDetector-PS51Compatible

- **Path:** `Modules\Unity-Claude-CPG\Core\SemanticAnalysis-PatternDetector-PS51Compatible.psm1`
- **Size:** 12.42 KB
- **Functions:** 9
- **Lines:** 388
- **Last Modified:** 08/28/2025 15:27:36

**Functions:**
- `Find-FunctionDefinitionsCompatible` (Line 192, 34 lines) - `Get-AvailablePatternsCompatible` (Line 360, 16 lines) - `Get-FactoryPatternSignature` (Line 118, 14 lines) - `Get-PowerShellASTCompatible` (Line 138, 52 lines) - `Get-SingletonPatternSignature` (Line 102, 14 lines) - `Invoke-PatternDetectionCompatible` (Line 275, 83 lines) - `New-PatternMatch` (Line 64, 32 lines) - `New-PatternSignature` (Line 32, 30 lines) - `Test-SingletonPatternCompatible` (Line 232, 41 lines) 
### SemanticAnalysis-PatternDetector

- **Path:** `Modules\Unity-Claude-CPG\Core\SemanticAnalysis-PatternDetector.psm1`
- **Size:** 24.85 KB
- **Functions:** 17
- **Lines:** 754
- **Last Modified:** 08/28/2025 15:01:25

**Functions:**
- `Find-ClassDefinitions` (Line 222, 40 lines) - `Find-FunctionDefinitions` (Line 264, 34 lines) - `Get-AvailablePatterns` (Line 697, 14 lines) - `Get-FactoryPattern` (Line 102, 19 lines) - `Get-ObserverPattern` (Line 123, 20 lines) - `Get-PatternDetectionReport` (Line 611, 84 lines) - `Get-PowerShellAST` (Line 170, 50 lines) - `Get-SingletonPattern` (Line 81, 19 lines) - `Get-StrategyPattern` (Line 145, 19 lines) - `Invoke-PatternDetection` (Line 553, 56 lines) - `PatternMatch` (Line 60, 14 lines, 3 params) - `PatternSignature` (Line 39, 8 lines, 4 params) - `Set-PatternDetectionConfiguration` (Line 713, 22 lines) - `Test-FactoryPattern` (Line 386, 52 lines) - `Test-ObserverPattern` (Line 440, 54 lines) - `Test-SingletonPattern` (Line 304, 80 lines) - `Test-StrategyPattern` (Line 496, 51 lines) 
### SessionStateConfiguration

- **Path:** `Modules\Unity-Claude-RunspaceManagement\Core\SessionStateConfiguration.psm1`
- **Size:** 14.79 KB
- **Functions:** 7
- **Lines:** 378
- **Last Modified:** 08/26/2025 11:46:19

**Functions:**
- `Add-SessionStateModule` (Line 161, 55 lines) - `Add-SessionStateVariable` (Line 218, 52 lines) - `New-RunspaceSessionState` (Line 32, 90 lines) - `Set-SessionStateConfiguration` (Line 124, 35 lines) - `Test-SessionStateConfiguration` (Line 272, 60 lines) - `Update-SessionStateRegistry` (Line 20, 0 lines) - `Write-ModuleLog` (Line 15, 4 lines) 
### StateConfiguration

- **Path:** `Modules\Unity-Claude-AutonomousStateTracker-Enhanced\Core\StateConfiguration.psm1`
- **Size:** 11.35 KB
- **Functions:** 4
- **Lines:** 285
- **Last Modified:** 08/26/2025 11:46:17

**Functions:**
- `Get-EnhancedAutonomousStates` (Line 195, 6 lines) - `Get-EnhancedStateConfig` (Line 62, 6 lines) - `Get-PerformanceCounters` (Line 231, 6 lines) - `Initialize-StateDirectories` (Line 70, 15 lines) 
### StateMachineCore

- **Path:** `Modules\Unity-Claude-AutonomousStateTracker-Enhanced\Core\StateMachineCore.psm1`
- **Size:** 14.54 KB
- **Functions:** 5
- **Lines:** 386
- **Last Modified:** 08/26/2025 11:46:17

**Functions:**
- `Get-AgentState` (Line 312, 28 lines) - `Get-EnhancedAutonomousState` (Line 203, 74 lines) - `Initialize-EnhancedAutonomousStateTracking` (Line 8, 75 lines) - `Save-AgentState` (Line 279, 31 lines) - `Set-EnhancedAutonomousState` (Line 85, 116 lines) 
### StateManagement

- **Path:** `Modules\Unity-Claude-AutonomousAgent\Core\StateManagement.psm1`
- **Size:** 13.66 KB
- **Functions:** 6
- **Lines:** 382
- **Last Modified:** 08/26/2025 11:46:17

**Functions:**
- `Get-ConversationState` (Line 206, 35 lines) - `Get-ValidStateTransitions` (Line 243, 26 lines) - `Initialize-ConversationState` (Line 7, 102 lines) - `Reset-ConversationState` (Line 271, 59 lines) - `Save-ConversationState` (Line 333, 12 lines) - `Set-ConversationState` (Line 111, 93 lines) 
### StatePersistence

- **Path:** `Modules\Unity-Claude-AutonomousStateTracker-Enhanced\Core\StatePersistence.psm1`
- **Size:** 11.54 KB
- **Functions:** 5
- **Lines:** 323
- **Last Modified:** 08/26/2025 11:46:17

**Functions:**
- `Get-CheckpointHistory` (Line 129, 46 lines) - `New-StateCheckpoint` (Line 8, 60 lines) - `Remove-OldCheckpoints` (Line 177, 45 lines) - `Restore-AgentStateFromCheckpoint` (Line 70, 57 lines) - `Test-CheckpointIntegrity` (Line 224, 53 lines) 
### StatisticsTracker

- **Path:** `Modules\Unity-Claude-ParallelProcessor\Core\StatisticsTracker.psm1`
- **Size:** 17.12 KB
- **Functions:** 17
- **Lines:** 441
- **Last Modified:** 08/26/2025 11:46:19

**Functions:**
- `AddExecutionRecord` (Line 162, 7 lines, 1 params) - `CalculateThroughput` (Line 202, 7 lines) - `CalculateThroughputInternal` (Line 185, 14 lines) - `Dispose` (Line 319, 6 lines) - `Format-StatisticsReport` (Line 351, 39 lines) - `GetExecutionHistory` (Line 268, 16 lines, 1 params) - `GetPerformanceSummary` (Line 244, 21 lines) - `GetStatistics` (Line 212, 29 lines) - `New-StatisticsTracker` (Line 332, 17 lines) - `RecordJobCancellation` (Line 124, 17 lines) - `RecordJobCompletion` (Line 68, 28 lines, 2 params) - `RecordJobFailure` (Line 99, 22 lines, 2 params) - `RecordJobSubmission` (Line 57, 8 lines) - `ResetStatistics` (Line 287, 29 lines) - `StatisticsTracker` (Line 22, 32 lines, 1 params) - `UpdateExecutionTimeStatistics` (Line 144, 15 lines, 1 params) - `UpdateRates` (Line 172, 10 lines) 
### StringSimilarity

- **Path:** `Modules\Unity-Claude-Learning\Core\StringSimilarity.psm1`
- **Size:** 12.95 KB
- **Functions:** 8
- **Lines:** 436
- **Last Modified:** 08/26/2025 11:46:19

**Functions:**
- `Get-ErrorSignature` (Line 346, 35 lines) - `Get-JaroSimilarity` (Line 197, 72 lines) - `Get-JaroWinklerSimilarity` (Line 148, 47 lines) - `Get-LevenshteinDistance` (Line 62, 52 lines) - `Get-LevenshteinSimilarity` (Line 116, 30 lines) - `Get-NGrams` (Line 318, 26 lines) - `Get-NGramSimilarity` (Line 271, 45 lines) - `Get-StringSimilarity` (Line 13, 47 lines) 
### SuccessTracking

- **Path:** `Modules\Unity-Claude-Learning\Core\SuccessTracking.psm1`
- **Size:** 12.36 KB
- **Functions:** 9
- **Lines:** 400
- **Last Modified:** 08/26/2025 11:46:19

**Functions:**
- `Clear-PersistedMetrics` (Line 240, 15 lines) - `Get-PatternEffectiveness` (Line 257, 30 lines) - `Get-PatternEffectivenessSQLite` (Line 289, 59 lines) - `Get-SuccessMetrics` (Line 97, 44 lines) - `Load-SuccessMetrics` (Line 207, 31 lines) - `Reset-SuccessMetrics` (Line 143, 41 lines) - `Save-SuccessMetrics` (Line 186, 19 lines) - `Update-SuccessMetrics` (Line 37, 58 lines) - `Write-ModuleLog` (Line 12, 4 lines) 
### SystemIntegration

- **Path:** `Modules\Unity-Claude-DocumentationQualityAssessment\Components\SystemIntegration.psm1`
- **Size:** 9.2 KB
- **Functions:** 6
- **Lines:** 253
- **Last Modified:** 08/30/2025 19:31:50

**Functions:**
- `Discover-QualityAssessmentSystems` (Line 168, 47 lines) - `Get-DefaultQualityAssessmentConfiguration` (Line 101, 65 lines) - `Get-DocumentationQualityStatistics` (Line 227, 19 lines) - `Initialize-DocumentationQualityAssessment` (Line 27, 72 lines) - `Initialize-ReadabilityCalculator` (Line 217, 3 lines) - `Setup-QualitySystemIntegration` (Line 222, 3 lines) 
### Templates-PerLanguage

- **Path:** `Modules\Unity-Claude-Enhanced-DocumentationGenerators\Core\Templates-PerLanguage.psm1`
- **Size:** 12.74 KB
- **Functions:** 7
- **Lines:** 447
- **Last Modified:** 08/28/2025 17:05:33

**Functions:**
- `Get-CSharpDocTemplate` (Line 162, 71 lines) - `Get-DocumentationTemplate` (Line 329, 28 lines) - `Get-JavaScriptDocTemplate` (Line 236, 90 lines) - `Get-LanguageFromExtension` (Line 360, 21 lines) - `Get-LanguageTemplateConfig` (Line 384, 52 lines) - `Get-PowerShellDocTemplate` (Line 8, 65 lines) - `Get-PythonDocTemplate` (Line 76, 83 lines) 
### TemplateSystem

- **Path:** `Modules\Unity-Claude-DocumentationAutomation\Core\TemplateSystem.psm1`
- **Size:** 16.47 KB
- **Functions:** 6
- **Lines:** 466
- **Last Modified:** 08/26/2025 11:46:18

**Functions:**
- `Export-DocumentationTemplates` (Line 181, 74 lines) - `Get-DocumentationTemplates` (Line 83, 45 lines) - `Import-DocumentationTemplates` (Line 257, 104 lines) - `Invoke-TemplateRendering` (Line 363, 57 lines) - `New-DocumentationTemplate` (Line 20, 61 lines) - `Update-DocumentationTemplate` (Line 130, 49 lines) 
### TemporalContextTracking

- **Path:** `Modules\Unity-Claude-CLIOrchestrator\Core\DecisionEngine-Bayesian\TemporalContextTracking.psm1`
- **Size:** 7.29 KB
- **Functions:** 2
- **Lines:** 187
- **Last Modified:** 08/26/2025 11:46:18

**Functions:**
- `Add-TemporalContext` (Line 22, 68 lines) - `Get-TemporalContextRelevance` (Line 93, 54 lines) 
### Test-HealthUtilities

- **Path:** `Tests\health-checks\shared\Test-HealthUtilities.psm1`
- **Size:** 12.25 KB
- **Functions:** 8
- **Lines:** 407
- **Last Modified:** 08/25/2025 15:36:20

**Functions:**
- `Add-TestResult` (Line 87, 63 lines) - `Generate-HTMLReport` (Line 277, 77 lines) - `Get-TestResults` (Line 226, 6 lines) - `Initialize-HealthCheck` (Line 19, 28 lines) - `Save-TestResults` (Line 234, 41 lines) - `Show-TestSummary` (Line 356, 39 lines) - `Test-ServiceHealth` (Line 152, 72 lines) - `Write-TestLog` (Line 49, 36 lines) 
### Test-Minimal-Queue

- **Path:** `Backups\PS7Migration_20250822_162419\Test-Minimal-Queue.psm1`
- **Size:** 0.32 KB
- **Functions:** 1
- **Lines:** 12
- **Last Modified:** 08/20/2025 19:09:44

**Functions:**
- `Test-NewConcurrentQueue` (Line 4, 6 lines) 
### Test-Minimal-Queue

- **Path:** `Test-Minimal-Queue.psm1`
- **Size:** 0.32 KB
- **Functions:** 1
- **Lines:** 12
- **Last Modified:** 08/20/2025 19:09:44

**Functions:**
- `Test-NewConcurrentQueue` (Line 4, 6 lines) 
### TestModule1

- **Path:** `TestResults\TestModules\TestModule1.psm1`
- **Size:** 0.31 KB
- **Functions:** 2
- **Lines:** 17
- **Last Modified:** 08/30/2025 02:55:36

**Functions:**
- `Test-Function1` (Line 3, 5 lines) - `Test-Function2` (Line 10, 4 lines) 
### TestModule2

- **Path:** `TestResults\TestModules\TestModule2.psm1`
- **Size:** 0.32 KB
- **Functions:** 2
- **Lines:** 17
- **Last Modified:** 08/30/2025 02:55:36

**Functions:**
- `Test-Function3` (Line 5, 5 lines) - `Test-Function4` (Line 12, 2 lines) 
### ThrottlingResourceControl

- **Path:** `Modules\Unity-Claude-RunspaceManagement\Core\ThrottlingResourceControl.psm1`
- **Size:** 16.31 KB
- **Functions:** 5
- **Lines:** 378
- **Last Modified:** 08/26/2025 11:46:19

**Functions:**
- `Get-ResourceMonitoringStatus` (Line 275, 58 lines) - `Invoke-RunspacePoolCleanup` (Line 196, 77 lines) - `Set-AdaptiveThrottling` (Line 121, 73 lines) - `Test-RunspacePoolResources` (Line 26, 93 lines) - `Write-ModuleLog` (Line 19, 4 lines) 
### TreeSitter-CSTConverter

- **Path:** `Modules\Unity-Claude-CPG\Core\TreeSitter-CSTConverter.psm1`
- **Size:** 23.98 KB
- **Functions:** 24
- **Lines:** 738
- **Last Modified:** 08/28/2025 03:22:32

**Functions:**
- `CalculateMaxDepth` (Line 270, 14 lines, 2 params) - `Convert-CSTToCPG` (Line 582, 56 lines) - `Convert-TreeSitterToCST` (Line 525, 54 lines) - `ConvertToCPGEdge` (Line 182, 22 lines) - `ConvertToCPGNode` (Line 100, 22 lines) - `CSharpHandler` (Line 289, 8 lines) - `CSTEdge` (Line 167, 4 lines) - `CSTEdge` (Line 173, 7 lines, 3 params) - `CSTNode` (Line 86, 4 lines) - `CSTNode` (Line 92, 6 lines, 2 params) - `ExtractEdges` (Line 235, 17 lines, 1 params) - `ExtractNodes` (Line 228, 5 lines, 1 params) - `FindPattern` (Line 144, 11 lines, 1 params) - `GetDescendants` (Line 124, 18 lines) - `GetMetrics` (Line 254, 14 lines, 1 params) - `GetWeight` (Line 206, 2 lines) - `JavaScriptHandler` (Line 446, 9 lines) - `LanguageHandler` (Line 218, 4 lines, 2 params) - `Measure-TreeSitterPerformance` (Line 641, 75 lines) - `ParseFile` (Line 299, 64 lines, 1 params) - `ParseFile` (Line 378, 63 lines, 1 params) - `ParseFile` (Line 457, 64 lines, 1 params) - `ParseFile` (Line 224, 2 lines, 1 params) - `PythonHandler` (Line 368, 8 lines) 
### TrendAnalysis

- **Path:** `Modules\Unity-Claude-PredictiveAnalysis\Core\TrendAnalysis.psm1`
- **Size:** 13.62 KB
- **Functions:** 3
- **Lines:** 349
- **Last Modified:** 08/26/2025 11:46:19

**Functions:**
- `Get-CodeEvolutionTrend` (Line 12, 142 lines) - `Get-HotspotAnalysis` (Line 217, 88 lines) - `Measure-CodeChurn` (Line 156, 59 lines) 
### TriggerSystem

- **Path:** `Modules\Unity-Claude-DocumentationAutomation\Core\TriggerSystem.psm1`
- **Size:** 23.28 KB
- **Functions:** 10
- **Lines:** 691
- **Last Modified:** 08/26/2025 11:46:18

**Functions:**
- `Approve-DocumentationChanges` (Line 467, 60 lines) - `Get-DocumentationTriggers` (Line 118, 42 lines) - `Get-ReviewMetrics` (Line 587, 54 lines) - `Get-ReviewStatus` (Line 430, 35 lines) - `Invoke-DocumentationUpdate` (Line 232, 143 lines) - `Register-DocumentationTrigger` (Line 20, 60 lines) - `Reject-DocumentationChanges` (Line 529, 56 lines) - `Start-DocumentationReview` (Line 377, 51 lines) - `Test-TriggerConditions` (Line 162, 68 lines) - `Unregister-DocumentationTrigger` (Line 82, 34 lines) 
### Unity-Claude-AgentIntegration

- **Path:** `Modules\Unity-Claude-MessageQueue\Unity-Claude-AgentIntegration.psm1`
- **Size:** 16.16 KB
- **Functions:** 7
- **Lines:** 419
- **Last Modified:** 08/24/2025 12:06:11

**Functions:**
- `Get-OrchestrationStatus` (Line 346, 28 lines) - `Initialize-AgentMessageSystem` (Line 13, 46 lines) - `Initialize-SupervisorOrchestration` (Line 151, 87 lines) - `Register-DefaultHandlers` (Line 61, 88 lines) - `Select-BestAgent` (Line 240, 38 lines) - `Send-SupervisorMessage` (Line 280, 21 lines) - `Start-AgentOrchestration` (Line 303, 41 lines) 
### Unity-Claude-AI-Performance-Monitor

- **Path:** `Unity-Claude-AI-Performance-Monitor.psm1`
- **Size:** 38.33 KB
- **Functions:** 8
- **Lines:** 965
- **Last Modified:** 08/30/2025 01:11:59

**Functions:**
- `Get-CachedResponse` (Line 638, 84 lines) - `Get-ContentSimilarity` (Line 819, 30 lines) - `Get-PerformanceAlerts` (Line 855, 86 lines) - `Initialize-IntelligentCaching` (Line 572, 64 lines) - `Set-CachedResponse` (Line 724, 93 lines) - `Start-AIWorkflowMonitoring` (Line 296, 217 lines) - `Start-PerformanceBottleneckAnalysis` (Line 118, 172 lines) - `Stop-AIWorkflowMonitoring` (Line 515, 51 lines) 
### Unity-Claude-AIAlertClassifier

- **Path:** `Modules\Unity-Claude-AIAlertClassifier\Unity-Claude-AIAlertClassifier.psm1`
- **Size:** 32.8 KB
- **Functions:** 19
- **Lines:** 974
- **Last Modified:** 08/30/2025 21:58:40

**Functions:**
- `Add-AIClassification` (Line 480, 66 lines) - `Add-ContextualInformation` (Line 635, 77 lines) - `Calculate-AlertPriority` (Line 714, 40 lines) - `Calculate-CorrelationScore` (Line 832, 45 lines) - `Clear-OldCacheEntries` (Line 925, 13 lines) - `Get-AIAlertStatistics` (Line 940, 25 lines) - `Get-AlertCacheKey` (Line 900, 23 lines) - `Get-EscalationPlan` (Line 756, 37 lines) - `Get-RuleBasedClassification` (Line 368, 110 lines) - `Get-StringSimilarity` (Line 879, 19 lines) - `Initialize-AIAlertClassifier` (Line 101, 41 lines) - `Initialize-ClassificationEngine` (Line 175, 42 lines) - `Initialize-CorrelationEngine` (Line 219, 29 lines) - `Initialize-EscalationEngine` (Line 250, 27 lines) - `Invoke-AIAlertClassification` (Line 279, 87 lines) - `Invoke-OllamaClassification` (Line 548, 46 lines) - `Invoke-OllamaPriorityScore` (Line 596, 37 lines) - `Test-AIConnection` (Line 144, 29 lines) - `Test-AlertCorrelation` (Line 795, 35 lines) 
### Unity-Claude-AlertAnalytics

- **Path:** `Modules\Unity-Claude-AlertAnalytics\Unity-Claude-AlertAnalytics.psm1`
- **Size:** 33.31 KB
- **Functions:** 22
- **Lines:** 935
- **Last Modified:** 08/30/2025 14:58:55

**Functions:**
- `Analyze-AlertPatterns` (Line 280, 105 lines) - `Analyze-AnomalyPatterns` (Line 526, 74 lines) - `Analyze-CorrelationPatterns` (Line 849, 3 lines) - `Analyze-SeasonalityPatterns` (Line 602, 88 lines) - `Analyze-TrendPatterns` (Line 445, 79 lines) - `Discover-ConnectedAnalyticsSystems` (Line 859, 2 lines) - `Generate-AlertTrendReport` (Line 692, 90 lines) - `Generate-OverallTrendInsights` (Line 888, 3 lines) - `Generate-PatternSummary` (Line 854, 3 lines) - `Generate-ReportSummary` (Line 893, 3 lines) - `Generate-SourceRecommendations` (Line 883, 3 lines) - `Generate-SyntheticTimeSeriesData` (Line 868, 13 lines) - `Get-AlertAnalyticsStatistics` (Line 906, 20 lines) - `Get-DefaultAnalyticsConfiguration` (Line 165, 46 lines) - `Get-TimeSeriesDataForWindow` (Line 387, 56 lines) - `Initialize-AlertAnalytics` (Line 80, 83 lines) - `Initialize-PatternCache` (Line 863, 3 lines) - `Load-TimeSeriesDatabase` (Line 213, 34 lines) - `Save-TimeSeriesDatabase` (Line 249, 29 lines) - `Test-AlertAnalytics` (Line 784, 62 lines) - `Test-AnalyticsSystemIntegration` (Line 902, 2 lines) - `Test-TimeSeriesDataManagement` (Line 898, 2 lines) 
### Unity-Claude-AlertFeedbackCollector

- **Path:** `Modules\Unity-Claude-AlertFeedbackCollector\Unity-Claude-AlertFeedbackCollector.psm1`
- **Size:** 36.27 KB
- **Functions:** 17
- **Lines:** 1028
- **Last Modified:** 08/30/2025 14:54:36

**Functions:**
- `Calculate-AggregateQualityMetrics` (Line 845, 63 lines) - `Calculate-AlertEffectiveness` (Line 445, 70 lines) - `Collect-AlertFeedback` (Line 340, 103 lines) - `Create-FeedbackSurveyContent` (Line 595, 65 lines) - `Discover-ConnectedAlertSystems` (Line 272, 66 lines) - `Enable-AutomatedFeedbackCollection` (Line 992, 4 lines) - `Generate-AutomatedFeedbackSurvey` (Line 517, 76 lines) - `Get-AlertFeedbackStatistics` (Line 998, 20 lines) - `Get-AlertQualityMetrics` (Line 771, 72 lines) - `Get-DefaultFeedbackConfiguration` (Line 157, 46 lines) - `Get-TodaysSurveyCount` (Line 977, 7 lines) - `Initialize-AlertFeedbackCollector` (Line 69, 86 lines) - `Initialize-QualityMetrics` (Line 986, 4 lines) - `Load-FeedbackDatabase` (Line 205, 34 lines) - `Save-FeedbackDatabase` (Line 241, 29 lines) - `Test-AlertFeedbackSystem` (Line 910, 65 lines) - `Update-QualityMetrics` (Line 662, 107 lines) 
### Unity-Claude-AlertMLOptimizer

- **Path:** `Modules\Unity-Claude-AlertMLOptimizer\Unity-Claude-AlertMLOptimizer.psm1`
- **Size:** 34.34 KB
- **Functions:** 27
- **Lines:** 927
- **Last Modified:** 08/30/2025 14:56:48

**Functions:**
- `Analyze-FeedbackPatterns` (Line 871, 3 lines) - `Apply-ThresholdAdjustments` (Line 896, 3 lines) - `Calculate-FeedbackDrivenAdjustments` (Line 886, 3 lines) - `Calculate-FeedbackDrivenConfidence` (Line 891, 3 lines) - `Calculate-FeedbackQualityMetrics` (Line 876, 3 lines) - `Calculate-OptimizationConfidence` (Line 826, 3 lines) - `Calculate-ZScoreConfidence` (Line 911, 3 lines) - `Create-PythonOptimizationScripts` (Line 866, 3 lines) - `Determine-OptimizationStrategy` (Line 881, 3 lines) - `Discover-ConnectedOptimizationSystems` (Line 856, 3 lines) - `Generate-SyntheticAlertData` (Line 837, 17 lines) - `Get-CurrentThresholds` (Line 821, 3 lines) - `Get-DefaultMLOptimizerConfiguration` (Line 220, 50 lines) - `Get-FeedbackDataForSource` (Line 901, 3 lines) - `Get-HistoricalAlertData` (Line 816, 3 lines) - `Get-OverallAdjustmentRecommendation` (Line 831, 4 lines) - `Initialize-AlertMLOptimizer` (Line 57, 73 lines) - `Initialize-MLModelsStorage` (Line 861, 3 lines) - `Initialize-PythonEnvironment` (Line 132, 86 lines) - `Optimize-AdaptiveThreshold` (Line 365, 102 lines) - `Optimize-AlertThresholds` (Line 272, 91 lines) - `Optimize-FeedbackDrivenThreshold` (Line 564, 64 lines) - `Optimize-ZScoreThreshold` (Line 469, 93 lines) - `Prepare-TrainingDataForML` (Line 906, 3 lines) - `Test-AlertMLOptimizer` (Line 742, 71 lines) - `Test-QualityMetricsCalculation` (Line 916, 3 lines) - `Train-MLAlertModel` (Line 630, 110 lines) 
### Unity-Claude-AlertQualityReporting

- **Path:** `Modules\Unity-Claude-AlertQualityReporting\Unity-Claude-AlertQualityReporting.psm1`
- **Size:** 36.02 KB
- **Functions:** 40
- **Lines:** 1034
- **Last Modified:** 08/30/2025 15:01:14

**Functions:**
- `Assess-OverallQuality` (Line 890, 5 lines) - `Assess-ReportDataQuality` (Line 856, 3 lines) - `Calculate-AlertRate` (Line 945, 3 lines) - `Calculate-ComprehensiveQualityMetrics` (Line 362, 73 lines) - `Calculate-EffectivenessMetrics` (Line 861, 6 lines) - `Calculate-PrecisionRecallMetrics` (Line 437, 78 lines) - `Calculate-ResponseTimeMetrics` (Line 869, 6 lines) - `Calculate-SatisfactionMetrics` (Line 877, 6 lines) - `Calculate-TrendMetrics` (Line 885, 3 lines) - `Collect-QualityDataForReport` (Line 833, 6 lines) - `Convert-ReportToCSV` (Line 999, 3 lines) - `Convert-ReportToHTML` (Line 994, 3 lines) - `Create-DefaultReportTemplates` (Line 941, 2 lines) - `Discover-ConnectedQualitySystems` (Line 928, 2 lines) - `Export-QualityReport` (Line 687, 56 lines) - `Generate-AnalyticsInsights` (Line 841, 3 lines) - `Generate-DashboardData` (Line 517, 107 lines) - `Generate-EffectivenessHeatmapData` (Line 975, 3 lines) - `Generate-ExecutiveSummary` (Line 851, 3 lines) - `Generate-OptimizationRecommendations` (Line 846, 3 lines) - `Generate-QualityReport` (Line 231, 129 lines) - `Generate-QualityTrendData` (Line 965, 3 lines) - `Generate-SyntheticAlertData` (Line 914, 12 lines) - `Generate-SyntheticFeedbackData` (Line 897, 15 lines) - `Generate-VolumePatternData` (Line 970, 3 lines) - `Get-AlertQualityReportingStatistics` (Line 1004, 20 lines) - `Get-AvailableAlertSources` (Line 829, 2 lines) - `Get-DefaultQualityReportingConfiguration` (Line 174, 55 lines) - `Get-DurationTrend` (Line 960, 3 lines) - `Get-ErrorTrend` (Line 955, 3 lines) - `Get-RateTrend` (Line 950, 3 lines) - `Get-ReportPeriod` (Line 820, 7 lines) - `Initialize-AlertQualityReporting` (Line 79, 93 lines) - `Initialize-DashboardIntegration` (Line 932, 2 lines) - `Load-QualityReports` (Line 936, 3 lines) - `Test-AlertQualityReporting` (Line 745, 72 lines) - `Test-DashboardDataGeneration` (Line 980, 3 lines) - `Test-QualityMetricsCalculation` (Line 985, 2 lines) - `Test-ReportExportFunctionality` (Line 989, 3 lines) - `Update-QualityDashboard` (Line 626, 59 lines) 
### Unity-Claude-APIDocumentation

- **Path:** `Modules\Unity-Claude-APIDocumentation\Unity-Claude-APIDocumentation.psm1`
- **Size:** 28.41 KB
- **Functions:** 10
- **Lines:** 855
- **Last Modified:** 08/26/2025 11:46:17

**Functions:**
- `Export-HTMLDocumentation` (Line 650, 85 lines) - `Get-HTMLTemplate` (Line 737, 63 lines) - `Initialize-DocumentationProject` (Line 105, 73 lines) - `Install-PlatyPS` (Line 45, 58 lines) - `New-ComprehensiveAPIDocs` (Line 474, 95 lines) - `New-FunctionDocumentation` (Line 305, 105 lines) - `New-MasterAPIIndex` (Line 571, 73 lines) - `New-ModuleDocumentation` (Line 184, 119 lines) - `New-ModuleOverview` (Line 412, 56 lines) - `Write-DocLog` (Line 20, 19 lines) 
### Unity-Claude-AST-Enhanced

- **Path:** `Modules\Unity-Claude-AST-Enhanced\Unity-Claude-AST-Enhanced.psm1`
- **Size:** 23.43 KB
- **Functions:** 15
- **Lines:** 695
- **Last Modified:** 08/30/2025 02:47:22

**Functions:**
- `Calculate-DependencyStrength` (Line 542, 12 lines) - `Convert-ToCSV` (Line 648, 18 lines) - `Convert-ToD3JSFormat` (Line 573, 45 lines) - `Convert-ToGraphML` (Line 620, 26 lines) - `Export-CallGraphData` (Line 349, 52 lines) - `Get-CrossModuleFunctionCalls` (Line 503, 37 lines) - `Get-CrossModuleRelationships` (Line 155, 71 lines) - `Get-CyclomaticComplexity` (Line 674, 10 lines) - `Get-FunctionCallAnalysis` (Line 248, 79 lines) - `Get-ImportModuleFromModule` (Line 476, 25 lines) - `Get-MaxCallDepth` (Line 668, 4 lines) - `Get-ModuleAnalysisFromModule` (Line 438, 36 lines) - `Get-ModuleAnalysisFromPath` (Line 407, 29 lines) - `Get-ModuleCallGraph` (Line 62, 74 lines) - `Get-ModuleRelationships` (Line 556, 15 lines) 
### Unity-Claude-AutoGen

- **Path:** `Modules\Unity-Claude-AI-Integration\AutoGen\Unity-Claude-AutoGen.psm1`
- **Size:** 48.23 KB
- **Functions:** 13
- **Lines:** 1291
- **Last Modified:** 08/29/2025 21:03:11

**Functions:**
- `Clear-AutoGenRegistry` (Line 1037, 49 lines) - `Get-AutoGenAgent` (Line 286, 36 lines) - `Get-AutoGenConfiguration` (Line 1019, 16 lines) - `Get-AutoGenConversationHistory` (Line 935, 36 lines) - `Invoke-AutoGenAnalysisWorkflow` (Line 1088, 107 lines) - `Invoke-AutoGenConversation` (Line 412, 187 lines) - `New-AutoGenAgent` (Line 44, 240 lines) - `New-AutoGenTeam` (Line 324, 86 lines) - `Send-AutoGenMessage` (Line 700, 128 lines) - `Set-AutoGenConfiguration` (Line 973, 44 lines) - `Start-AutoGenNamedPipeServer` (Line 601, 97 lines) - `Stop-AutoGenServices` (Line 1197, 68 lines) - `Test-AutoGenConnectivity` (Line 830, 103 lines) 
### Unity-Claude-AutoGenMonitoring

- **Path:** `Modules\Unity-Claude-AI-Integration\AutoGen\Unity-Claude-AutoGenMonitoring.psm1`
- **Size:** 15.56 KB
- **Functions:** 4
- **Lines:** 379
- **Last Modified:** 08/29/2025 18:33:04

**Functions:**
- `Get-AutoGenPerformanceMetrics` (Line 159, 79 lines) - `Invoke-AgentPerformanceOptimization` (Line 240, 79 lines) - `Start-AutoGenActivityMonitoring` (Line 50, 107 lines) - `Stop-AutoGenActivityMonitoring` (Line 321, 43 lines) 
### Unity-Claude-AutonomousAgent-ORIGINAL

- **Path:** `Archive\Unity-Claude-AutonomousAgent-ORIGINAL.psm1`
- **Size:** 90.13 KB
- **Functions:** 33
- **Lines:** 2395
- **Last Modified:** 08/20/2025 17:25:20

**Functions:**
- `Add-RecommendationToQueue` (Line 1154, 40 lines) - `Classify-ClaudeResponse` (Line 815, 132 lines) - `Convert-ActionToType` (Line 676, 25 lines) - `Convert-TypeToStandard` (Line 638, 36 lines) - `Detect-ConversationState` (Line 1033, 115 lines) - `Extract-ConversationContext` (Line 949, 82 lines) - `Find-ClaudeRecommendations` (Line 442, 141 lines) - `Find-UnityExecutable` (Line 2005, 24 lines) - `Get-PatternConfidence` (Line 585, 51 lines) - `Get-StringSimilarity` (Line 779, 30 lines) - `Initialize-AgentLogging` (Line 154, 16 lines) - `Invoke-AnalyzeCommand` (Line 2291, 17 lines) - `Invoke-BuildCommand` (Line 2272, 17 lines) - `Invoke-CompilationTest` (Line 2234, 36 lines) - `Invoke-PowerShellTests` (Line 2215, 17 lines) - `Invoke-ProcessClaudeResponse` (Line 295, 145 lines) - `Invoke-ProcessCommandQueue` (Line 1196, 62 lines) - `Invoke-SafeConstrainedCommand` (Line 1551, 147 lines) - `Invoke-SafeRecommendedCommand` (Line 1739, 67 lines) - `Invoke-TestCommand` (Line 1808, 27 lines) - `Invoke-UnityTests` (Line 1837, 166 lines) - `New-ConstrainedRunspace` (Line 1317, 78 lines) - `New-FollowUpPrompt` (Line 2035, 97 lines) - `Normalize-RecommendationType` (Line 703, 28 lines) - `Remove-DuplicateRecommendations` (Line 733, 44 lines) - `Sanitize-ParameterValue` (Line 1700, 33 lines) - `Start-ClaudeResponseMonitoring` (Line 176, 81 lines) - `Stop-ClaudeResponseMonitoring` (Line 259, 30 lines) - `Submit-PromptToClaude` (Line 2134, 75 lines) - `Test-CommandSafety` (Line 1397, 47 lines) - `Test-ParameterSafety` (Line 1446, 45 lines) - `Test-PathSafety` (Line 1493, 56 lines) - `Write-AgentLog` (Line 104, 48 lines) 
### Unity-Claude-AutonomousAgent-Refactored

- **Path:** `Modules\Unity-Claude-AutonomousAgent\Unity-Claude-AutonomousAgent-Refactored.psm1`
- **Size:** 8.77 KB
- **Functions:** 1
- **Lines:** 220
- **Last Modified:** 08/20/2025 17:25:21

**Functions:**
- `Get-ModuleStatus` (Line 143, 29 lines) 
### Unity-Claude-AutonomousDocumentationEngine

- **Path:** `Modules\Unity-Claude-AutonomousDocumentationEngine\Unity-Claude-AutonomousDocumentationEngine.psm1`
- **Size:** 55.81 KB
- **Functions:** 29
- **Lines:** 1459
- **Last Modified:** 08/30/2025 19:47:36

**Functions:**
- `Analyze-CodeChangeForDocumentation` (Line 497, 69 lines) - `Analyze-PowerShellAST` (Line 568, 67 lines) - `Apply-AIContentOptimization` (Line 1206, 56 lines) - `Apply-DocumentationUpdates` (Line 960, 4 lines) - `Assess-DocumentationQuality` (Line 966, 3 lines) - `Calculate-AIContentQualityScore` (Line 977, 3 lines) - `Create-SelectiveDocumentationUpdates` (Line 955, 3 lines) - `Discover-DocumentationSystems` (Line 209, 80 lines) - `Enhance-ContentCompleteness` (Line 1162, 42 lines) - `Enhance-DocumentationContentIntelligently` (Line 1008, 105 lines) - `Generate-AIDocumentationContent` (Line 637, 109 lines) - `Generate-FreshnessRecommendations` (Line 982, 3 lines) - `Get-AutonomousDocumentationStatistics` (Line 1425, 20 lines) - `Get-DefaultAutonomousDocConfiguration` (Line 152, 55 lines) - `Get-DocumentationTargets` (Line 950, 3 lines) - `Get-TrendBasedRecommendations` (Line 1394, 29 lines) - `Initialize-AIDocumentationEngine` (Line 291, 108 lines) - `Initialize-AutonomousDocumentationEngine` (Line 75, 75 lines) - `Initialize-DocumentationVersioning` (Line 992, 3 lines) - `Initialize-QualityMonitoring` (Line 987, 3 lines) - `Monitor-ContentQualityTrends` (Line 1305, 87 lines) - `Monitor-DocumentationFreshness` (Line 748, 117 lines) - `Optimize-ContentReadability` (Line 1115, 45 lines) - `Process-AutonomousDocumentationUpdate` (Line 401, 94 lines) - `Record-QualityMetrics` (Line 971, 4 lines) - `Setup-AutonomousTriggers` (Line 997, 3 lines) - `Test-AutonomousDocumentationEngine` (Line 867, 80 lines) - `Test-AutonomousDocumentationIntegration` (Line 1002, 4 lines) - `Update-ContentFreshnessMarkers` (Line 1264, 39 lines) 
### Unity-Claude-AutonomousMonitoring

- **Path:** `Backup_20250824_233959\Unity-Claude-AutonomousMonitoring\Unity-Claude-AutonomousMonitoring.psm1`
- **Size:** 32.74 KB
- **Functions:** 7
- **Lines:** 732
- **Last Modified:** 08/24/2025 12:06:11

**Functions:**
- `Execute-TestScript` (Line 387, 98 lines) - `Find-ClaudeWindow` (Line 113, 89 lines) - `Process-ResponseFile` (Line 488, 82 lines) - `Start-AutonomousMonitoring` (Line 573, 113 lines) - `Submit-ToClaudeViaTypeKeys` (Line 252, 132 lines) - `Switch-ToWindow` (Line 205, 44 lines) - `Update-ClaudeWindowInfo` (Line 70, 40 lines) 
### Unity-Claude-AutonomousMonitoring

- **Path:** `Backup_20250824_233959\Modules\Unity-Claude-AutonomousMonitoring\Unity-Claude-AutonomousMonitoring.psm1`
- **Size:** 32.74 KB
- **Functions:** 7
- **Lines:** 732
- **Last Modified:** 08/24/2025 12:06:11

**Functions:**
- `Execute-TestScript` (Line 387, 98 lines) - `Find-ClaudeWindow` (Line 113, 89 lines) - `Process-ResponseFile` (Line 488, 82 lines) - `Start-AutonomousMonitoring` (Line 573, 113 lines) - `Submit-ToClaudeViaTypeKeys` (Line 252, 132 lines) - `Switch-ToWindow` (Line 205, 44 lines) - `Update-ClaudeWindowInfo` (Line 70, 40 lines) 
### Unity-Claude-AutonomousMonitoring

- **Path:** `Backup_20250824_233959\Backup_20250824_233959\Unity-Claude-AutonomousMonitoring\Unity-Claude-AutonomousMonitoring.psm1`
- **Size:** 32.74 KB
- **Functions:** 7
- **Lines:** 732
- **Last Modified:** 08/24/2025 12:06:11

**Functions:**
- `Execute-TestScript` (Line 387, 98 lines) - `Find-ClaudeWindow` (Line 113, 89 lines) - `Process-ResponseFile` (Line 488, 82 lines) - `Start-AutonomousMonitoring` (Line 573, 113 lines) - `Submit-ToClaudeViaTypeKeys` (Line 252, 132 lines) - `Switch-ToWindow` (Line 205, 44 lines) - `Update-ClaudeWindowInfo` (Line 70, 40 lines) 
### Unity-Claude-AutonomousStateTracker-Enhanced-Refactored

- **Path:** `Modules\Unity-Claude-AutonomousStateTracker-Enhanced\Unity-Claude-AutonomousStateTracker-Enhanced-Refactored.psm1`
- **Size:** 21.74 KB
- **Functions:** 3
- **Lines:** 519
- **Last Modified:** 08/26/2025 11:46:17

**Functions:**
- `Get-AutonomousStateTrackerComponents` (Line 64, 72 lines) - `Invoke-ComprehensiveAutonomousAnalysis` (Line 316, 108 lines) - `Test-AutonomousStateTrackerHealth` (Line 138, 176 lines) 
### Unity-Claude-AutonomousStateTracker-Enhanced

- **Path:** `Modules\Unity-Claude-AutonomousStateTracker-Enhanced.psm1`
- **Size:** 56.6 KB
- **Functions:** 19
- **Lines:** 1466
- **Last Modified:** 08/20/2025 17:25:22

**Functions:**
- `Approve-AgentIntervention` (Line 1138, 52 lines) - `ConvertTo-HashTable` (Line 216, 67 lines) - `Deny-AgentIntervention` (Line 1192, 41 lines) - `Get-AgentState` (Line 895, 27 lines) - `Get-EnhancedAutonomousState` (Line 786, 71 lines) - `Get-SafeDateTime` (Line 285, 96 lines) - `Get-SystemPerformanceMetrics` (Line 496, 65 lines) - `Get-UptimeMinutes` (Line 383, 52 lines) - `Initialize-EnhancedAutonomousStateTracking` (Line 599, 71 lines) - `New-StateCheckpoint` (Line 924, 58 lines) - `Request-HumanIntervention` (Line 1045, 91 lines) - `Restore-AgentStateFromCheckpoint` (Line 984, 55 lines) - `Save-AgentState` (Line 863, 30 lines) - `Set-EnhancedAutonomousState` (Line 672, 112 lines) - `Start-EnhancedHealthMonitoring` (Line 1281, 85 lines) - `Stop-EnhancedHealthMonitoring` (Line 1368, 24 lines) - `Test-SystemHealthThresholds` (Line 563, 30 lines) - `Update-InterventionStatus` (Line 1235, 40 lines) - `Write-EnhancedStateLog` (Line 437, 57 lines) 
### Unity-Claude-AutonomousStateTracker-Enhanced

- **Path:** `Modules\Unity-Claude-AutonomousStateTracker-Enhanced\Unity-Claude-AutonomousStateTracker-Enhanced.psm1`
- **Size:** 21.74 KB
- **Functions:** 3
- **Lines:** 519
- **Last Modified:** 08/26/2025 11:46:17

**Functions:**
- `Get-AutonomousStateTrackerComponents` (Line 64, 72 lines) - `Invoke-ComprehensiveAutonomousAnalysis` (Line 316, 108 lines) - `Test-AutonomousStateTrackerHealth` (Line 138, 176 lines) 
### Unity-Claude-AutonomousStateTracker

- **Path:** `Modules\Unity-Claude-AutonomousStateTracker.psm1`
- **Size:** 30.86 KB
- **Functions:** 18
- **Lines:** 888
- **Last Modified:** 08/20/2025 17:25:22

**Functions:**
- `Calculate-HealthStatus` (Line 484, 39 lines) - `Get-AutonomousOperationStatus` (Line 746, 56 lines) - `Get-AutonomousStateTracking` (Line 267, 25 lines) - `Get-StateTimestamp` (Line 161, 2 lines) - `Get-StateTransitionHistory` (Line 804, 15 lines) - `Get-SystemMetrics` (Line 455, 27 lines) - `Initialize-AutonomousStateTracking` (Line 173, 92 lines) - `Invoke-HealthCheck` (Line 407, 46 lines) - `Invoke-InterventionTrigger` (Line 569, 62 lines) - `New-StateTrackingId` (Line 165, 2 lines) - `Reset-CircuitBreaker` (Line 709, 31 lines) - `Save-StateTracking` (Line 294, 17 lines) - `Set-AutonomousState` (Line 313, 64 lines) - `Test-CircuitBreakerState` (Line 675, 32 lines) - `Test-InterventionTriggers` (Line 529, 38 lines) - `Test-StateTransition` (Line 379, 22 lines) - `Update-PerformanceMetrics` (Line 633, 36 lines) - `Write-StateTrackerLog` (Line 129, 30 lines) 
### Unity-Claude-Cache-Fixed

- **Path:** `Modules\Unity-Claude-Cache\Unity-Claude-Cache-Fixed.psm1`
- **Size:** 25.39 KB
- **Functions:** 32
- **Lines:** 802
- **Last Modified:** 08/25/2025 13:45:24

**Functions:**
- `CacheManager` (Line 24, 2 lines) - `CacheManager` (Line 28, 2 lines, 1 params) - `CacheManager` (Line 32, 2 lines, 3 params) - `CleanupExpired` (Line 334, 37 lines) - `Clear` (Line 265, 20 lines) - `Clear-Cache` (Line 680, 9 lines) - `ContainsKey` (Line 412, 22 lines, 1 params) - `Dispose` (Line 571, 16 lines) - `EvictLRU` (Line 301, 30 lines) - `Get` (Line 144, 65 lines, 1 params) - `Get-CacheItem` (Line 652, 12 lines) - `Get-CacheKeys` (Line 722, 9 lines) - `Get-CacheStatistics` (Line 691, 15 lines) - `GetItemSize` (Line 464, 16 lines, 1 params) - `GetKeys` (Line 437, 24 lines) - `GetStatistics` (Line 379, 30 lines) - `Initialize` (Line 36, 37 lines, 3 params) - `LoadFromDisk` (Line 521, 47 lines) - `NeedsCleanup` (Line 374, 2 lines) - `New-CacheManager` (Line 592, 24 lines) - `Remove` (Line 212, 23 lines, 1 params) - `Remove-CacheItem` (Line 666, 12 lines) - `RemoveInternal` (Line 238, 24 lines, 1 params) - `Save-CacheToDisk` (Line 733, 9 lines) - `SaveToDisk` (Line 483, 35 lines) - `Set` (Line 139, 2 lines, 3 params) - `Set` (Line 135, 2 lines, 2 params) - `Set` (Line 76, 56 lines, 4 params) - `Set-CacheItem` (Line 618, 32 lines) - `Start-CacheCleanup` (Line 744, 9 lines) - `Test-CacheKey` (Line 708, 12 lines) - `UpdateLRU` (Line 288, 10 lines, 1 params) 
### Unity-Claude-Cache-Original

- **Path:** `Modules\Unity-Claude-Cache\Unity-Claude-Cache-Original.psm1`
- **Size:** 25.15 KB
- **Functions:** 31
- **Lines:** 789
- **Last Modified:** 08/25/2025 13:45:24

**Functions:**
- `CacheManager` (Line 23, 2 lines) - `CacheManager` (Line 27, 2 lines, 1 params) - `CacheManager` (Line 31, 2 lines, 3 params) - `CleanupExpired` (Line 338, 34 lines) - `Clear` (Line 269, 20 lines) - `Clear-Cache` (Line 673, 9 lines) - `ContainsKey` (Line 408, 22 lines, 1 params) - `Dispose` (Line 567, 17 lines) - `EvictLRU` (Line 305, 30 lines) - `Get` (Line 148, 65 lines, 1 params) - `Get-CacheItem` (Line 645, 12 lines) - `Get-CacheKeys` (Line 709, 9 lines) - `Get-CacheStatistics` (Line 684, 9 lines) - `GetItemSize` (Line 460, 16 lines, 1 params) - `GetKeys` (Line 433, 24 lines) - `GetStatistics` (Line 375, 30 lines) - `Initialize` (Line 35, 42 lines, 3 params) - `LoadFromDisk` (Line 517, 47 lines) - `New-CacheManager` (Line 589, 24 lines) - `Remove` (Line 216, 23 lines, 1 params) - `Remove-CacheItem` (Line 659, 12 lines) - `RemoveInternal` (Line 242, 24 lines, 1 params) - `Save-CacheToDisk` (Line 720, 9 lines) - `SaveToDisk` (Line 479, 35 lines) - `Set` (Line 143, 2 lines, 3 params) - `Set` (Line 80, 56 lines, 4 params) - `Set` (Line 139, 2 lines, 2 params) - `Set-CacheItem` (Line 615, 28 lines) - `Start-CacheCleanup` (Line 731, 9 lines) - `Test-CacheKey` (Line 695, 12 lines) - `UpdateLRU` (Line 292, 10 lines, 1 params) 
### Unity-Claude-Cache

- **Path:** `Modules\Unity-Claude-Cache\Unity-Claude-Cache.psm1`
- **Size:** 25.32 KB
- **Functions:** 32
- **Lines:** 799
- **Last Modified:** 08/25/2025 13:45:24

**Functions:**
- `CacheManager` (Line 24, 2 lines) - `CacheManager` (Line 28, 2 lines, 1 params) - `CacheManager` (Line 32, 2 lines, 3 params) - `CleanupExpired` (Line 334, 37 lines) - `Clear` (Line 265, 20 lines) - `Clear-Cache` (Line 677, 9 lines) - `ContainsKey` (Line 413, 22 lines, 1 params) - `Dispose` (Line 572, 16 lines) - `EvictLRU` (Line 301, 30 lines) - `Get` (Line 144, 65 lines, 1 params) - `Get-CacheItem` (Line 649, 12 lines) - `Get-CacheKeys` (Line 719, 9 lines) - `Get-CacheStatistics` (Line 688, 15 lines) - `GetItemSize` (Line 465, 16 lines, 1 params) - `GetKeys` (Line 438, 24 lines) - `GetStatistics` (Line 379, 31 lines) - `Initialize` (Line 36, 37 lines, 3 params) - `LoadFromDisk` (Line 522, 47 lines) - `NeedsCleanup` (Line 374, 2 lines) - `New-CacheManager` (Line 593, 24 lines) - `Remove` (Line 212, 23 lines, 1 params) - `Remove-CacheItem` (Line 663, 12 lines) - `RemoveInternal` (Line 238, 24 lines, 1 params) - `Save-CacheToDisk` (Line 730, 9 lines) - `SaveToDisk` (Line 484, 35 lines) - `Set` (Line 139, 2 lines, 3 params) - `Set` (Line 135, 2 lines, 2 params) - `Set` (Line 76, 56 lines, 4 params) - `Set-CacheItem` (Line 619, 28 lines) - `Start-CacheCleanup` (Line 741, 9 lines) - `Test-CacheKey` (Line 705, 12 lines) - `UpdateLRU` (Line 288, 10 lines, 1 params) 
### Unity-Claude-ChangeIntelligence

- **Path:** `Modules\Unity-Claude-ChangeIntelligence\Unity-Claude-ChangeIntelligence.psm1`
- **Size:** 20.69 KB
- **Functions:** 13
- **Lines:** 605
- **Last Modified:** 08/30/2025 12:45:52

**Functions:**
- `Calculate-RiskLevel` (Line 409, 51 lines) - `Clear-ChangeIntelligenceCache` (Line 586, 9 lines) - `Get-AIEnhancedClassification` (Line 357, 50 lines) - `Get-ASTBasedClassification` (Line 276, 79 lines) - `Get-ChangeClassification` (Line 130, 64 lines) - `Get-ChangeHistory` (Line 560, 24 lines) - `Get-ChangeIntelligenceStatistics` (Line 543, 15 lines) - `Get-ContentBasedClassification` (Line 231, 43 lines) - `Get-ExtensionBasedClassification` (Line 196, 33 lines) - `Get-ImpactAssessment` (Line 462, 60 lines) - `Initialize-ChangeIntelligence` (Line 54, 26 lines) - `Initialize-ClassificationRules` (Line 82, 46 lines) - `Test-OllamaConnection` (Line 524, 17 lines) 
### Unity-Claude-ClaudeParallelization

- **Path:** `Modules\Unity-Claude-ClaudeParallelization\Unity-Claude-ClaudeParallelization.psm1`
- **Size:** 53.27 KB
- **Functions:** 11
- **Lines:** 1282
- **Last Modified:** 08/21/2025 17:45:27

**Functions:**
- `Get-ClaudeAPIRateLimit` (Line 513, 40 lines) - `New-ClaudeCLIParallelManager` (Line 573, 86 lines) - `New-ClaudeParallelSubmitter` (Line 149, 91 lines) - `Parse-ClaudeResponseParallel` (Line 1007, 131 lines) - `Start-ConcurrentResponseMonitoring` (Line 875, 116 lines) - `Submit-ClaudeAPIParallel` (Line 260, 241 lines) - `Submit-ClaudeCLIParallel` (Line 677, 178 lines) - `Test-ClaudeParallelizationPerformance` (Line 1158, 65 lines) - `Test-ModuleDependencyAvailability` (Line 3, 20 lines) - `Write-ClaudeParallelLog` (Line 85, 12 lines) - `Write-FallbackLog` (Line 66, 16 lines) 
### Unity-Claude-CLIOrchestrator-Fixed-Simple

- **Path:** `Modules\Unity-Claude-CLIOrchestrator\Unity-Claude-CLIOrchestrator-Fixed-Simple.psm1`
- **Size:** 14.26 KB
- **Functions:** 14
- **Lines:** 510
- **Last Modified:** 08/27/2025 23:42:18

**Functions:**
- `Analyze-ResponseSentiment` (Line 419, 14 lines) - `Extract-ResponseEntities` (Line 401, 16 lines) - `Find-ClaudeWindow` (Line 374, 21 lines) - `Find-RecommendationPatterns` (Line 435, 14 lines) - `Get-CLIOrchestratorInfo` (Line 102, 6 lines) - `Initialize-CLIOrchestrator` (Line 41, 29 lines) - `Invoke-AutonomousDecisionMaking` (Line 201, 72 lines) - `Invoke-DecisionExecution` (Line 275, 65 lines) - `Invoke-RuleBasedDecision` (Line 451, 14 lines) - `Process-ResponseFile` (Line 132, 67 lines) - `Submit-ToClaudeViaTypeKeys` (Line 342, 30 lines) - `Test-CLIOrchestratorComponents` (Line 72, 28 lines) - `Test-SafetyValidation` (Line 467, 14 lines) - `Update-CLISessionStats` (Line 110, 16 lines) 
### Unity-Claude-CLIOrchestrator-FullFeatured

- **Path:** `Modules\Unity-Claude-CLIOrchestrator\Unity-Claude-CLIOrchestrator-FullFeatured.psm1`
- **Size:** 10.46 KB
- **Functions:** 2
- **Lines:** 296
- **Last Modified:** 08/27/2025 18:03:56

**Functions:**
- `Find-ClaudeWindow` (Line 205, 11 lines) - `Initialize-CLIOrchestrator` (Line 186, 15 lines) 
### Unity-Claude-CLIOrchestrator-Original-Backup

- **Path:** `Modules\Unity-Claude-CLIOrchestrator\Unity-Claude-CLIOrchestrator-Original-Backup.psm1`
- **Size:** 22.7 KB
- **Functions:** 4
- **Lines:** 577
- **Last Modified:** 08/26/2025 11:46:17

**Functions:**
- `Get-CLIOrchestratorInfo` (Line 315, 70 lines) - `Initialize-CLIOrchestrator` (Line 95, 82 lines) - `Test-CLIOrchestratorComponents` (Line 179, 134 lines) - `Update-CLISessionStats` (Line 387, 33 lines) 
### Unity-Claude-CLIOrchestrator-Original

- **Path:** `Modules\Unity-Claude-CLIOrchestrator\Unity-Claude-CLIOrchestrator-Original.psm1`
- **Size:** 74.96 KB
- **Functions:** 15
- **Lines:** 1760
- **Last Modified:** 08/28/2025 12:37:44

**Functions:**
- `Convert-ToSerializedString` (Line 511, 132 lines) - `Execute-TestScript` (Line 410, 98 lines) - `Find-ClaudeWindow` (Line 136, 89 lines) - `Get-ActionResultSummary` (Line 752, 67 lines) - `Get-CLIOrchestrationStatus` (Line 1337, 83 lines) - `Invoke-AutonomousDecisionMaking` (Line 1423, 130 lines) - `Invoke-AutonomousExecutionLoop` (Line 978, 159 lines) - `Invoke-ComprehensiveResponseAnalysis` (Line 1259, 75 lines) - `Invoke-DecisionExecution` (Line 1556, 67 lines) - `New-AutonomousPrompt` (Line 646, 103 lines) - `Process-ResponseFile` (Line 822, 153 lines) - `Start-CLIOrchestration` (Line 1140, 114 lines) - `Submit-ToClaudeViaTypeKeys` (Line 275, 132 lines) - `Switch-ToWindow` (Line 228, 44 lines) - `Update-ClaudeWindowInfo` (Line 93, 40 lines) 
### Unity-Claude-CLIOrchestrator-Refactored-Fixed

- **Path:** `Modules\Unity-Claude-CLIOrchestrator\Unity-Claude-CLIOrchestrator-Refactored-Fixed.psm1`
- **Size:** 15.12 KB
- **Functions:** 4
- **Lines:** 429
- **Last Modified:** 08/27/2025 17:22:21

**Functions:**
- `Get-CLIOrchestratorInfo` (Line 295, 30 lines) - `Initialize-CLIOrchestrator` (Line 145, 71 lines) - `Test-CLIOrchestratorComponents` (Line 218, 75 lines) - `Update-CLISessionStats` (Line 327, 23 lines) 
### Unity-Claude-CLIOrchestrator-Refactored

- **Path:** `Modules\Unity-Claude-CLIOrchestrator\Unity-Claude-CLIOrchestrator-Refactored.psm1`
- **Size:** 22.24 KB
- **Functions:** 4
- **Lines:** 556
- **Last Modified:** 08/26/2025 22:32:37

**Functions:**
- `Get-CLIOrchestratorInfo` (Line 307, 70 lines) - `Initialize-CLIOrchestrator` (Line 87, 82 lines) - `Test-CLIOrchestratorComponents` (Line 171, 134 lines) - `Update-CLISessionStats` (Line 379, 33 lines) 
### Unity-Claude-CLIOrchestrator

- **Path:** `Modules\Unity-Claude-CLIOrchestrator\Unity-Claude-CLIOrchestrator.psm1`
- **Size:** 22.86 KB
- **Functions:** 4
- **Lines:** 568
- **Last Modified:** 08/26/2025 22:06:20

**Functions:**
- `Get-CLIOrchestratorInfo` (Line 319, 70 lines) - `Initialize-CLIOrchestrator` (Line 99, 82 lines) - `Test-CLIOrchestratorComponents` (Line 183, 134 lines) - `Update-CLISessionStats` (Line 391, 33 lines) 
### Unity-Claude-CLISubmission-Enhanced

- **Path:** `Modules\Unity-Claude-CLISubmission-Enhanced.psm1`
- **Size:** 16.43 KB
- **Functions:** 6
- **Lines:** 475
- **Last Modified:** 08/21/2025 20:16:39

**Functions:**
- `Get-CurrentWindowTitle` (Line 385, 46 lines) - `Start-InputLockProtection` (Line 144, 48 lines) - `Stop-InputLockProtection` (Line 194, 76 lines) - `Submit-ToClaude` (Line 352, 31 lines) - `Submit-ToClaudeWithInputLock` (Line 27, 115 lines) - `Wait-ForResponseCompletion` (Line 272, 78 lines) 
### Unity-Claude-CLISubmission

- **Path:** `Modules\Unity-Claude-CLISubmission.psm1`
- **Size:** 45.44 KB
- **Functions:** 7
- **Lines:** 975
- **Last Modified:** 08/20/2025 17:25:22

**Functions:**
- `New-AutonomousPrompt` (Line 150, 202 lines) - `Start-AutonomousFeedbackLoop` (Line 806, 89 lines) - `Start-ResponseMonitoring` (Line 739, 61 lines) - `Start-UnityErrorMonitoring` (Line 38, 89 lines) - `Stop-AutonomousFeedbackLoop` (Line 897, 20 lines) - `Stop-UnityErrorMonitoring` (Line 129, 15 lines) - `Submit-PromptToClaudeCode` (Line 358, 375 lines) 
### Unity-Claude-CodeQL

- **Path:** `Modules\Unity-Claude-CodeQL\Unity-Claude-CodeQL.psm1`
- **Size:** 24.37 KB
- **Functions:** 10
- **Lines:** 733
- **Last Modified:** 08/26/2025 11:46:18

**Functions:**
- `Export-CodeQLResults` (Line 476, 143 lines) - `Get-CodeQLVersion` (Line 649, 26 lines) - `Initialize-PowerShellCodeQLDB` (Line 259, 37 lines) - `Install-CodeQLCLI` (Line 46, 89 lines) - `Invoke-CodeQLQuery` (Line 302, 89 lines) - `Invoke-PowerShellSecurityScan` (Line 393, 77 lines) - `New-CodeQLDatabase` (Line 179, 78 lines) - `Register-SecurityCallback` (Line 625, 22 lines) - `Test-CodeQLInstallation` (Line 137, 36 lines) - `Write-CodeQLLog` (Line 21, 19 lines) 
### Unity-Claude-CodeReviewCoordination

- **Path:** `Unity-Claude-CodeReviewCoordination.psm1`
- **Size:** 16.68 KB
- **Functions:** 6
- **Lines:** 433
- **Last Modified:** 08/29/2025 20:20:41

**Functions:**
- `Invoke-AgentCollaborativeAnalysis` (Line 100, 73 lines) - `Invoke-AgentConsensusVoting` (Line 238, 97 lines) - `Invoke-AgentFindingsPresentation` (Line 337, 38 lines) - `Invoke-IndependentAgentAnalysis` (Line 175, 61 lines) - `Invoke-StructuredAgentDebate` (Line 377, 39 lines) - `New-CodeReviewAgentTeam` (Line 32, 66 lines) 
### Unity-Claude-ConcurrentCollections

- **Path:** `Modules\Unity-Claude-ParallelProcessing\Unity-Claude-ConcurrentCollections.psm1`
- **Size:** 25.57 KB
- **Functions:** 14
- **Lines:** 787
- **Last Modified:** 08/21/2025 17:45:27

**Functions:**
- `Add-ConcurrentBagItem` (Line 319, 45 lines) - `Add-ConcurrentQueueItem` (Line 80, 45 lines) - `Get-ConcurrentBagCount` (Line 462, 28 lines) - `Get-ConcurrentBagItem` (Line 366, 63 lines) - `Get-ConcurrentBagItems` (Line 492, 33 lines) - `Get-ConcurrentCollectionMetrics` (Line 638, 88 lines) - `Get-ConcurrentQueueCount` (Line 223, 28 lines) - `Get-ConcurrentQueueItem` (Line 127, 63 lines) - `New-ConcurrentBag` (Line 257, 60 lines) - `New-ConcurrentQueue` (Line 14, 64 lines) - `Start-ProducerConsumerQueue` (Line 531, 49 lines) - `Stop-ProducerConsumerQueue` (Line 582, 50 lines) - `Test-ConcurrentBagEmpty` (Line 431, 29 lines) - `Test-ConcurrentQueueEmpty` (Line 192, 29 lines) 
### Unity-Claude-ConcurrentProcessor

- **Path:** `Modules\Unity-Claude-ConcurrentProcessor.psm1`
- **Size:** 34.36 KB
- **Functions:** 17
- **Lines:** 999
- **Last Modified:** 08/20/2025 17:25:22

**Functions:**
- `Get-ConcurrentJobStatus` (Line 496, 41 lines) - `Get-ConcurrentProcessingReport` (Line 888, 40 lines) - `Get-ConcurrentTimestamp` (Line 147, 2 lines) - `Get-ProcessMutex` (Line 155, 18 lines) - `Get-SharedData` (Line 222, 20 lines) - `Invoke-JobCleanup` (Line 809, 77 lines) - `Invoke-ParallelDataProcessing` (Line 680, 123 lines) - `Invoke-ParallelFileProcessing` (Line 583, 95 lines) - `Invoke-WithMutex` (Line 175, 26 lines) - `New-JobId` (Line 143, 2 lines) - `Start-ConcurrentJob` (Line 332, 75 lines) - `Stop-ConcurrentJob` (Line 539, 38 lines) - `Test-ResourceAvailability` (Line 285, 41 lines) - `Update-ResourceMonitoring` (Line 248, 35 lines) - `Update-SharedData` (Line 203, 17 lines) - `Wait-ConcurrentJob` (Line 409, 85 lines) - `Write-ConcurrentLog` (Line 103, 38 lines) 
### Unity-Claude-Configuration-Fixed

- **Path:** `Unity-Claude-Configuration-Fixed.psm1`
- **Size:** 23.68 KB
- **Functions:** 10
- **Lines:** 639
- **Last Modified:** 08/20/2025 17:25:25

**Functions:**
- `ConvertTo-HashTable` (Line 16, 63 lines) - `Find-ConfigurationDifferences` (Line 462, 36 lines) - `Get-AutomationConfig` (Line 81, 51 lines) - `Get-ConfigurationKeys` (Line 573, 22 lines) - `Get-ConfigurationSummary` (Line 500, 71 lines) - `Load-ConfigurationFiles` (Line 326, 71 lines) - `Merge-Configuration` (Line 399, 29 lines) - `Save-ConfigurationFile` (Line 430, 30 lines) - `Set-AutomationConfig` (Line 134, 53 lines) - `Test-AutomationConfig` (Line 189, 135 lines) 
### Unity-Claude-Configuration-Fixed

- **Path:** `Backups\PS7Migration_20250822_162419\Unity-Claude-Configuration-Fixed.psm1`
- **Size:** 23.68 KB
- **Functions:** 10
- **Lines:** 639
- **Last Modified:** 08/20/2025 17:25:25

**Functions:**
- `ConvertTo-HashTable` (Line 16, 63 lines) - `Find-ConfigurationDifferences` (Line 462, 36 lines) - `Get-AutomationConfig` (Line 81, 51 lines) - `Get-ConfigurationKeys` (Line 573, 22 lines) - `Get-ConfigurationSummary` (Line 500, 71 lines) - `Load-ConfigurationFiles` (Line 326, 71 lines) - `Merge-Configuration` (Line 399, 29 lines) - `Save-ConfigurationFile` (Line 430, 30 lines) - `Set-AutomationConfig` (Line 134, 53 lines) - `Test-AutomationConfig` (Line 189, 135 lines) 
### Unity-Claude-Configuration

- **Path:** `Backups\PS7Migration_20250822_162419\Unity-Claude-Configuration.psm1`
- **Size:** 23.68 KB
- **Functions:** 10
- **Lines:** 639
- **Last Modified:** 08/20/2025 17:25:25

**Functions:**
- `ConvertTo-HashTable` (Line 16, 63 lines) - `Find-ConfigurationDifferences` (Line 462, 36 lines) - `Get-AutomationConfig` (Line 81, 51 lines) - `Get-ConfigurationKeys` (Line 573, 22 lines) - `Get-ConfigurationSummary` (Line 500, 71 lines) - `Load-ConfigurationFiles` (Line 326, 71 lines) - `Merge-Configuration` (Line 399, 29 lines) - `Save-ConfigurationFile` (Line 430, 30 lines) - `Set-AutomationConfig` (Line 134, 53 lines) - `Test-AutomationConfig` (Line 189, 135 lines) 
### Unity-Claude-Configuration

- **Path:** `Backups\Migration_20250822_020236\Unity-Claude-Configuration.psm1`
- **Size:** 23.68 KB
- **Functions:** 10
- **Lines:** 639
- **Last Modified:** 08/20/2025 17:25:25

**Functions:**
- `ConvertTo-HashTable` (Line 16, 63 lines) - `Find-ConfigurationDifferences` (Line 462, 36 lines) - `Get-AutomationConfig` (Line 81, 51 lines) - `Get-ConfigurationKeys` (Line 573, 22 lines) - `Get-ConfigurationSummary` (Line 500, 71 lines) - `Load-ConfigurationFiles` (Line 326, 71 lines) - `Merge-Configuration` (Line 399, 29 lines) - `Save-ConfigurationFile` (Line 430, 30 lines) - `Set-AutomationConfig` (Line 134, 53 lines) - `Test-AutomationConfig` (Line 189, 135 lines) 
### Unity-Claude-Configuration

- **Path:** `Backups\Migration_20250826_123820\Unity-Claude-Configuration.psm1`
- **Size:** 23.68 KB
- **Functions:** 10
- **Lines:** 639
- **Last Modified:** 08/20/2025 17:25:25

**Functions:**
- `ConvertTo-HashTable` (Line 16, 63 lines) - `Find-ConfigurationDifferences` (Line 462, 36 lines) - `Get-AutomationConfig` (Line 81, 51 lines) - `Get-ConfigurationKeys` (Line 573, 22 lines) - `Get-ConfigurationSummary` (Line 500, 71 lines) - `Load-ConfigurationFiles` (Line 326, 71 lines) - `Merge-Configuration` (Line 399, 29 lines) - `Save-ConfigurationFile` (Line 430, 30 lines) - `Set-AutomationConfig` (Line 134, 53 lines) - `Test-AutomationConfig` (Line 189, 135 lines) 
### Unity-Claude-Configuration

- **Path:** `Backups\Migration_20250822_020010\Unity-Claude-Configuration.psm1`
- **Size:** 23.68 KB
- **Functions:** 10
- **Lines:** 639
- **Last Modified:** 08/20/2025 17:25:25

**Functions:**
- `ConvertTo-HashTable` (Line 16, 63 lines) - `Find-ConfigurationDifferences` (Line 462, 36 lines) - `Get-AutomationConfig` (Line 81, 51 lines) - `Get-ConfigurationKeys` (Line 573, 22 lines) - `Get-ConfigurationSummary` (Line 500, 71 lines) - `Load-ConfigurationFiles` (Line 326, 71 lines) - `Merge-Configuration` (Line 399, 29 lines) - `Save-ConfigurationFile` (Line 430, 30 lines) - `Set-AutomationConfig` (Line 134, 53 lines) - `Test-AutomationConfig` (Line 189, 135 lines) 
### Unity-Claude-Configuration

- **Path:** `Unity-Claude-Configuration.psm1`
- **Size:** 23.68 KB
- **Functions:** 10
- **Lines:** 639
- **Last Modified:** 08/20/2025 17:25:25

**Functions:**
- `ConvertTo-HashTable` (Line 16, 63 lines) - `Find-ConfigurationDifferences` (Line 462, 36 lines) - `Get-AutomationConfig` (Line 81, 51 lines) - `Get-ConfigurationKeys` (Line 573, 22 lines) - `Get-ConfigurationSummary` (Line 500, 71 lines) - `Load-ConfigurationFiles` (Line 326, 71 lines) - `Merge-Configuration` (Line 399, 29 lines) - `Save-ConfigurationFile` (Line 430, 30 lines) - `Set-AutomationConfig` (Line 134, 53 lines) - `Test-AutomationConfig` (Line 189, 135 lines) 
### Unity-Claude-Core

- **Path:** `Modules\Unity-Claude-Core\Unity-Claude-Core.psm1`
- **Size:** 17.57 KB
- **Functions:** 9
- **Lines:** 556
- **Last Modified:** 08/20/2025 17:25:21

**Functions:**
- `Export-UnityConsole` (Line 180, 98 lines) - `Get-CurrentPromptType` (Line 493, 14 lines) - `Get-FileTailAsString` (Line 87, 29 lines) - `Initialize-AutomationContext` (Line 11, 33 lines) - `Install-AutoRecompileScript` (Line 280, 91 lines) - `Start-UnityAutomation` (Line 421, 70 lines) - `Test-EditorSuccess` (Line 373, 42 lines) - `Test-UnityCompilation` (Line 122, 56 lines) - `Write-Log` (Line 50, 31 lines) 
### Unity-Claude-CPG-ASTConverter

- **Path:** `Modules\Unity-Claude-CPG\Unity-Claude-CPG-ASTConverter.psm1`
- **Size:** 37.8 KB
- **Functions:** 20
- **Lines:** 1045
- **Last Modified:** 08/24/2025 23:42:55

**Functions:**
- `Build-ControlFlowEdges` (Line 848, 39 lines) - `Build-ControlFlowEdges` (Line 763, 30 lines) - `Build-DataFlowEdges` (Line 795, 51 lines) - `Build-DataFlowEdges` (Line 729, 32 lines) - `Convert-ASTtoCPG` (Line 19, 78 lines) - `ConvertTo-CPGFromFile` (Line 889, 43 lines) - `ConvertTo-CPGFromScriptBlock` (Line 934, 69 lines) - `Process-Assignment` (Line 433, 17 lines) - `Process-ASTNode` (Line 99, 132 lines) - `Process-ClassDefinition` (Line 452, 82 lines) - `Process-Command` (Line 324, 58 lines) - `Process-ForEachStatement` (Line 660, 22 lines) - `Process-FunctionDefinition` (Line 233, 89 lines) - `Process-IfStatement` (Line 636, 22 lines) - `Process-Parameters` (Line 566, 29 lines) - `Process-SwitchStatement` (Line 705, 22 lines) - `Process-TryCatch` (Line 597, 37 lines) - `Process-UsingStatement` (Line 536, 28 lines) - `Process-Variable` (Line 384, 47 lines) - `Process-WhileStatement` (Line 684, 19 lines) 
### Unity-Claude-CPG-Original

- **Path:** `Modules\Unity-Claude-CPG\Unity-Claude-CPG-Original.psm1`
- **Size:** 31.05 KB
- **Functions:** 33
- **Lines:** 1026
- **Last Modified:** 08/26/2025 11:46:18

**Functions:**
- `Add-CPGEdge` (Line 476, 32 lines) - `Add-CPGNode` (Line 450, 24 lines) - `AddEdge` (Line 242, 22 lines, 1 params) - `AddNode` (Line 231, 9 lines, 1 params) - `ConvertTo-CPGFromScriptBlock` (Line 906, 71 lines) - `CPGEdge` (Line 157, 7 lines) - `CPGEdge` (Line 166, 10 lines, 3 params) - `CPGNode` (Line 105, 6 lines) - `CPGNode` (Line 113, 8 lines, 2 params) - `CPGraph` (Line 208, 9 lines) - `CPGraph` (Line 219, 10 lines, 1 params) - `Export-CPGraph` (Line 783, 69 lines) - `Find-CPGPath` (Line 661, 65 lines) - `Get-CPGEdge` (Line 549, 48 lines) - `Get-CPGNeighbors` (Line 599, 60 lines) - `Get-CPGNode` (Line 510, 37 lines) - `Get-CPGStatistics` (Line 728, 34 lines) - `GetEdge` (Line 270, 2 lines, 1 params) - `GetEdgesByType` (Line 278, 2 lines, 1 params) - `GetNeighbors` (Line 282, 31 lines, 2 params) - `GetNode` (Line 266, 2 lines, 1 params) - `GetNodesByType` (Line 274, 2 lines, 1 params) - `GetStatistics` (Line 315, 17 lines) - `Import-CPGraph` (Line 854, 49 lines) - `New-CPGEdge` (Line 388, 34 lines) - `New-CPGNode` (Line 349, 37 lines) - `New-CPGraph` (Line 424, 24 lines) - `Test-CPGStronglyConnected` (Line 764, 17 lines) - `ToHashtable` (Line 182, 12 lines) - `ToHashtable` (Line 334, 12 lines) - `ToHashtable` (Line 127, 16 lines) - `ToString` (Line 123, 2 lines) - `ToString` (Line 178, 2 lines) 
### Unity-Claude-CPG-Refactored

- **Path:** `Modules\Unity-Claude-CPG\Unity-Claude-CPG-Refactored.psm1`
- **Size:** 8.38 KB
- **Functions:** 1
- **Lines:** 207
- **Last Modified:** 08/26/2025 11:46:18

**Functions:**
- `ConvertTo-CPGFromScriptBlock` (Line 75, 71 lines) 
### Unity-Claude-CPG

- **Path:** `Modules\Unity-Claude-CPG\Unity-Claude-CPG.psm1`
- **Size:** 8.38 KB
- **Functions:** 1
- **Lines:** 207
- **Last Modified:** 08/26/2025 11:46:18

**Functions:**
- `ConvertTo-CPGFromScriptBlock` (Line 75, 71 lines) 
### Unity-Claude-CrossLanguage

- **Path:** `Modules\Unity-Claude-CPG\Unity-Claude-CrossLanguage.psm1`
- **Size:** 22.28 KB
- **Functions:** 9
- **Lines:** 603
- **Last Modified:** 08/24/2025 23:42:55

**Functions:**
- `Export-UnifiedGraph` (Line 487, 74 lines) - `Get-CrossLanguageStatistics` (Line 428, 57 lines) - `Get-StringSimilarity` (Line 388, 38 lines) - `Merge-LanguageGraphs` (Line 13, 101 lines) - `Resolve-CrossLanguageImports` (Line 116, 70 lines) - `Resolve-DataModels` (Line 277, 56 lines) - `Resolve-SharedInterfaces` (Line 205, 70 lines) - `Test-DataModelSimilarity` (Line 335, 51 lines) - `Test-ImportMatch` (Line 188, 15 lines) 
### Unity-Claude-DecisionEngine-Original

- **Path:** `Modules\Unity-Claude-DecisionEngine\Unity-Claude-DecisionEngine-Original.psm1`
- **Size:** 46.72 KB
- **Functions:** 27
- **Lines:** 1340
- **Last Modified:** 08/26/2025 11:46:18

**Functions:**
- `Add-ContextualEnrichment` (Line 605, 49 lines) - `Add-DecisionToHistory` (Line 1064, 31 lines) - `Apply-ContextualAdjustments` (Line 978, 36 lines) - `Calculate-SemanticConfidence` (Line 519, 38 lines) - `Clear-DecisionHistory` (Line 1211, 15 lines) - `Connect-ConversationManager` (Line 1137, 32 lines) - `Connect-IntelligentPromptEngine` (Line 1101, 34 lines) - `Get-ConversationConsistency` (Line 701, 38 lines) - `Get-ConversationFlowAnalysis` (Line 656, 43 lines) - `Get-DecisionEngineConfig` (Line 101, 6 lines) - `Get-DecisionEngineStatus` (Line 1175, 16 lines) - `Get-DecisionHistory` (Line 1193, 16 lines) - `Get-IntentClassification` (Line 367, 40 lines) - `Get-LastSimilarResponse` (Line 741, 20 lines) - `Get-SemanticActions` (Line 468, 49 lines) - `Get-SemanticContext` (Line 409, 57 lines) - `Invoke-AIEnhancedAnalysis` (Line 317, 48 lines) - `Invoke-AutonomousDecision` (Line 767, 60 lines) - `Invoke-DecisionTree` (Line 829, 147 lines) - `Invoke-DecisionValidation` (Line 1016, 46 lines) - `Invoke-HybridResponseAnalysis` (Line 165, 49 lines) - `Invoke-RegexBasedAnalysis` (Line 216, 99 lines) - `Merge-AnalysisResults` (Line 559, 44 lines) - `Set-DecisionEngineConfig` (Line 109, 50 lines) - `Test-DecisionEngineIntegration` (Line 1228, 70 lines) - `Test-RequiredModule` (Line 82, 13 lines) - `Write-DecisionEngineLog` (Line 43, 37 lines) 
### Unity-Claude-DecisionEngine-Refactored

- **Path:** `Modules\Unity-Claude-DecisionEngine\Unity-Claude-DecisionEngine-Refactored.psm1`
- **Size:** 18.09 KB
- **Functions:** 5
- **Lines:** 489
- **Last Modified:** 08/26/2025 11:46:18

**Functions:**
- `Get-DecisionEngineComponentStatus` (Line 122, 44 lines) - `Import-DecisionEngineComponent` (Line 23, 40 lines) - `Invoke-DecisionEngineAnalysis` (Line 168, 80 lines) - `Reset-DecisionEngine` (Line 250, 35 lines) - `Test-DecisionEngineDeployment` (Line 287, 94 lines) 
### Unity-Claude-DecisionEngine

- **Path:** `Modules\Unity-Claude-DecisionEngine\Unity-Claude-DecisionEngine.psm1`
- **Size:** 18.09 KB
- **Functions:** 5
- **Lines:** 489
- **Last Modified:** 08/26/2025 11:46:18

**Functions:**
- `Get-DecisionEngineComponentStatus` (Line 122, 44 lines) - `Import-DecisionEngineComponent` (Line 23, 40 lines) - `Invoke-DecisionEngineAnalysis` (Line 168, 80 lines) - `Reset-DecisionEngine` (Line 250, 35 lines) - `Test-DecisionEngineDeployment` (Line 287, 94 lines) 
### Unity-Claude-DocumentationAnalytics

- **Path:** `Modules\Unity-Claude-DocumentationAnalytics\Unity-Claude-DocumentationAnalytics.psm1`
- **Size:** 44.08 KB
- **Functions:** 14
- **Lines:** 1042
- **Last Modified:** 08/30/2025 20:15:21

**Functions:**
- `Export-AnalyticsReport` (Line 936, 90 lines) - `Get-AccessPatternAnalysis` (Line 506, 7 lines) - `Get-ContentEffectivenessMetrics` (Line 497, 7 lines) - `Get-ContentOptimizationRecommendations` (Line 317, 156 lines) - `Get-DocumentationUsageMetrics` (Line 198, 117 lines) - `Get-OptimizationOpportunities` (Line 515, 7 lines) - `Get-UserJourneyAnalysis` (Line 487, 8 lines) - `Initialize-DocumentationAnalytics` (Line 46, 67 lines) - `Invoke-ContentFreshnessCheck` (Line 747, 109 lines) - `Measure-DocumentationEffectiveness` (Line 524, 152 lines) - `Remove-ObsoleteDocumentation` (Line 858, 76 lines) - `Save-AnalyticsData` (Line 476, 9 lines) - `Start-AutomatedDocumentationMaintenance` (Line 678, 67 lines) - `Start-DocumentationAnalytics` (Line 115, 81 lines) 
### Unity-Claude-DocumentationAutomation-Original

- **Path:** `Modules\Unity-Claude-DocumentationAutomation\Unity-Claude-DocumentationAutomation-Original.psm1`
- **Size:** 54.38 KB
- **Functions:** 20
- **Lines:** 1634
- **Last Modified:** 08/25/2025 13:45:24

**Functions:**
- `Export-DocumentationReport` (Line 1373, 169 lines) - `Get-DocumentationHistory` (Line 1235, 61 lines) - `Get-DocumentationPRs` (Line 520, 31 lines) - `Get-DocumentationStatus` (Line 243, 40 lines) - `Get-DocumentationTemplates` (Line 619, 45 lines) - `Get-DocumentationTriggers` (Line 818, 42 lines) - `Invoke-DocumentationUpdate` (Line 932, 143 lines) - `New-DocumentationBackup` (Line 1080, 71 lines) - `New-DocumentationPR` (Line 288, 149 lines) - `New-DocumentationTemplate` (Line 556, 61 lines) - `Register-DocumentationTrigger` (Line 720, 60 lines) - `Restore-DocumentationBackup` (Line 1153, 80 lines) - `Start-DocumentationAutomation` (Line 39, 80 lines) - `Stop-DocumentationAutomation` (Line 121, 38 lines) - `Sync-WithPredictiveAnalysis` (Line 1301, 70 lines) - `Test-DocumentationSync` (Line 161, 80 lines) - `Test-TriggerConditions` (Line 862, 68 lines) - `Unregister-DocumentationTrigger` (Line 782, 34 lines) - `Update-DocumentationPR` (Line 439, 79 lines) - `Update-DocumentationTemplate` (Line 666, 49 lines) 
### Unity-Claude-DocumentationAutomation-Refactored

- **Path:** `Modules\Unity-Claude-DocumentationAutomation\Unity-Claude-DocumentationAutomation-Refactored.psm1`
- **Size:** 16.62 KB
- **Functions:** 3
- **Lines:** 453
- **Last Modified:** 08/26/2025 11:46:18

**Functions:**
- `Get-DocumentationAutomationInfo` (Line 288, 55 lines) - `Initialize-DocumentationAutomation` (Line 84, 90 lines) - `Test-ComponentHealth` (Line 176, 110 lines) 
### Unity-Claude-DocumentationAutomation

- **Path:** `Modules\Unity-Claude-DocumentationAutomation\Unity-Claude-DocumentationAutomation.psm1`
- **Size:** 16.62 KB
- **Functions:** 3
- **Lines:** 453
- **Last Modified:** 08/26/2025 11:46:18

**Functions:**
- `Get-DocumentationAutomationInfo` (Line 288, 55 lines) - `Initialize-DocumentationAutomation` (Line 84, 90 lines) - `Test-ComponentHealth` (Line 176, 110 lines) 
### Unity-Claude-DocumentationCrossReference

- **Path:** `Modules\Unity-Claude-DocumentationCrossReference\Unity-Claude-DocumentationCrossReference.psm1`
- **Size:** 64.02 KB
- **Functions:** 12
- **Lines:** 1576
- **Last Modified:** 08/30/2025 19:08:12

**Functions:**
- `Build-DocumentationGraph` (Line 780, 341 lines) - `Calculate-DocumentationCentrality` (Line 1123, 112 lines) - `Connect-ExistingDocumentationSystems` (Line 1237, 71 lines) - `Extract-MarkdownLinks` (Line 433, 147 lines) - `Find-FunctionCalls` (Line 683, 95 lines) - `Find-FunctionDefinitions` (Line 582, 99 lines) - `Get-ASTCrossReferences` (Line 181, 250 lines) - `Get-DocumentationCrossReferenceStatistics` (Line 1538, 24 lines) - `Initialize-DocumentationCrossReference` (Line 70, 109 lines) - `Invoke-LinkValidation` (Line 1310, 115 lines) - `Test-DocumentationCrossReference` (Line 1427, 79 lines) - `Test-ExistingSystemIntegration` (Line 1508, 28 lines) 
### Unity-Claude-DocumentationDrift-Refactored

- **Path:** `Modules\Unity-Claude-DocumentationDrift\Unity-Claude-DocumentationDrift-Refactored.psm1`
- **Size:** 9.91 KB
- **Functions:** 3
- **Lines:** 270
- **Last Modified:** 08/26/2025 11:46:18

**Functions:**
- `Clear-DriftCache` (Line 33, 33 lines) - `Get-DriftDetectionResults` (Line 68, 23 lines) - `Test-DocumentationDrift` (Line 93, 116 lines) 
### Unity-Claude-DocumentationDrift

- **Path:** `Modules\Unity-Claude-DocumentationDrift\Unity-Claude-DocumentationDrift.psm1`
- **Size:** 142.95 KB
- **Functions:** 55
- **Lines:** 3709
- **Last Modified:** 08/24/2025 12:06:11

**Functions:**
- `Add-ImpactLevelRecommendations` (Line 1882, 27 lines) - `Analyze-CascadeEffects` (Line 1311, 20 lines) - `Analyze-ChangeImpact` (Line 796, 101 lines) - `Analyze-DeletedFileImpact` (Line 1103, 14 lines) - `Analyze-ModifiedFileImpact` (Line 1119, 41 lines) - `Analyze-NewFileImpact` (Line 1083, 18 lines) - `Analyze-RenamedFileImpact` (Line 1162, 10 lines) - `Apply-QualityRules` (Line 3408, 66 lines) - `Build-CodeToDocMapping` (Line 263, 229 lines) - `Clear-DriftCache` (Line 211, 30 lines) - `Compare-CodeASTs` (Line 1371, 41 lines) - `Determine-OverallImpactLevel` (Line 1174, 16 lines) - `Estimate-UpdateTime` (Line 1333, 20 lines) - `Execute-DocumentationActions` (Line 3370, 35 lines) - `Extract-Frontmatter` (Line 706, 40 lines) - `Find-OrphanedDocumentation` (Line 2005, 9 lines) - `Generate-ChangeRecommendations` (Line 1192, 23 lines) - `Generate-ChartData` (Line 3627, 16 lines) - `Generate-CurrencyRecommendations` (Line 1979, 24 lines) - `Generate-DeletedFileRecommendations` (Line 1845, 17 lines) - `Generate-DocumentationCommitMessage` (Line 2329, 220 lines) - `Generate-MetricsSummary` (Line 3585, 40 lines) - `Generate-ModifiedFileRecommendations` (Line 1794, 49 lines) - `Generate-NewFileRecommendations` (Line 1763, 29 lines) - `Generate-RenamedFileRecommendations` (Line 1864, 16 lines) - `Generate-UpdateRecommendations` (Line 1415, 120 lines) - `Get-AutomationMetrics` (Line 3553, 10 lines) - `Get-CommentBasedHelp` (Line 748, 45 lines) - `Get-CoverageMetrics` (Line 3543, 8 lines) - `Get-DependencyPriority` (Line 1276, 13 lines) - `Get-DocumentationDependencies` (Line 899, 181 lines) - `Get-DocumentationDriftConfig` (Line 145, 21 lines) - `Get-DocumentationMetrics` (Line 3208, 117 lines) - `Get-DocumentationTemplate` (Line 1911, 23 lines) - `Get-DocumentationType` (Line 695, 9 lines) - `Get-DriftDetectionResults` (Line 243, 17 lines) - `Get-FileCodeElements` (Line 1217, 57 lines) - `Get-GitPreviousContent` (Line 1355, 14 lines) - `Get-IndirectDocumentationDependencies` (Line 1291, 18 lines) - `Get-LinkType` (Line 3476, 12 lines) - `Get-PerformanceMetrics` (Line 3565, 8 lines) - `Get-QualityMetrics` (Line 3575, 8 lines) - `Initialize-DocumentationDrift` (Line 62, 81 lines) - `Invoke-DocumentationAutomation` (Line 2017, 185 lines) - `New-DocumentationBranch` (Line 2204, 123 lines) - `New-DocumentationPR` (Line 2551, 297 lines) - `Perform-DeepDocumentationAnalysis` (Line 1936, 41 lines) - `Process-AutomationApproval` (Line 3328, 40 lines) - `Set-DocumentationDriftConfig` (Line 168, 41 lines) - `Test-DocumentationCurrency` (Line 1537, 223 lines) - `Test-DocumentationQuality` (Line 2850, 161 lines) - `Test-ExcludedPath` (Line 684, 9 lines) - `Test-SingleLink` (Line 3490, 50 lines) - `Update-DocumentationIndex` (Line 494, 187 lines) - `Validate-DocumentationLinks` (Line 3013, 193 lines) 
### Unity-Claude-DocumentationPipeline

- **Path:** `Modules\Unity-Claude-LLM\Unity-Claude-DocumentationPipeline.psm1`
- **Size:** 13.73 KB
- **Functions:** 6
- **Lines:** 363
- **Last Modified:** 08/25/2025 03:00:14

**Functions:**
- `Build-DocumentationContext` (Line 179, 45 lines) - `Get-ComplexityMetrics` (Line 291, 27 lines) - `Invoke-ArchitectureAnalysis` (Line 152, 25 lines) - `Invoke-SemanticAnalysisPipeline` (Line 117, 33 lines) - `New-DocumentationIndex` (Line 226, 63 lines) - `New-EnhancedDocumentationPipeline` (Line 11, 104 lines) 
### Unity-Claude-DocumentationQualityAssessment_Original_20250830_193150

- **Path:** `Modules\Unity-Claude-DocumentationQualityAssessment\Unity-Claude-DocumentationQualityAssessment_Original_20250830_193150.psm1`
- **Size:** 38.58 KB
- **Functions:** 3
- **Lines:** 1024
- **Last Modified:** 08/30/2025 19:27:42

**Functions:**
- `Assess-DocumentationQuality` (Line 220, 804 lines) - `Get-DefaultQualityAssessmentConfiguration` (Line 153, 65 lines) - `Initialize-DocumentationQualityAssessment` (Line 79, 72 lines) 
### Unity-Claude-DocumentationQualityAssessment

- **Path:** `Modules\Unity-Claude-DocumentationQualityAssessment\Unity-Claude-DocumentationQualityAssessment.psm1`
- **Size:** 5.28 KB
- **Functions:** 1
- **Lines:** 133
- **Last Modified:** 08/30/2025 19:40:34

**Functions:**
- `Assess-DocumentationQuality` (Line 11, 87 lines) 
### Unity-Claude-DocumentationQualityOrchestrator

- **Path:** `Modules\Unity-Claude-DocumentationQualityOrchestrator\Unity-Claude-DocumentationQualityOrchestrator.psm1`
- **Size:** 37.23 KB
- **Functions:** 24
- **Lines:** 988
- **Last Modified:** 08/30/2025 18:38:42

**Functions:**
- `Analyze-ContentFreshness` (Line 813, 14 lines) - `Calculate-FinalQualityScore` (Line 849, 20 lines) - `Calculate-QualityROI` (Line 705, 20 lines) - `Create-CustomQualityRule` (Line 548, 88 lines) - `Discover-QualityModules` (Line 728, 43 lines) - `Evaluate-QualityRules` (Line 434, 56 lines) - `Execute-AutomatedOptimizationWorkflow` (Line 807, 4 lines) - `Execute-ComprehensiveReviewWorkflow` (Line 300, 132 lines) - `Execute-ContentEnhancementWorkflow` (Line 795, 4 lines) - `Execute-FreshnessMonitoringWorkflow` (Line 801, 4 lines) - `Execute-QualityAssessmentWorkflow` (Line 789, 4 lines) - `Generate-WorkflowRecommendations` (Line 829, 18 lines) - `Get-DefaultOrchestratorConfiguration` (Line 141, 35 lines) - `Get-DetailedQualityMetrics` (Line 895, 7 lines) - `Get-DocumentationQualityReport` (Line 638, 65 lines) - `Initialize-DocumentationQualityOrchestrator` (Line 60, 79 lines) - `Initialize-NoCodeRuleSystem` (Line 781, 2 lines) - `Initialize-PerformanceTracking` (Line 785, 2 lines) - `Initialize-WorkflowEngine` (Line 773, 6 lines) - `Load-DefaultQualityRules` (Line 492, 54 lines) - `Send-WorkflowCompletionNotification` (Line 889, 4 lines) - `Start-DocumentationQualityWorkflow` (Line 178, 120 lines) - `Test-DocumentationQualityOrchestrator` (Line 904, 75 lines) - `Update-PerformanceMetrics` (Line 871, 16 lines) 
### Unity-Claude-DocumentationSuggestions

- **Path:** `Modules\Unity-Claude-DocumentationSuggestions\Unity-Claude-DocumentationSuggestions.psm1`
- **Size:** 43.47 KB
- **Functions:** 15
- **Lines:** 1171
- **Last Modified:** 08/30/2025 19:47:36

**Functions:**
- `Calculate-CosineSimilarity` (Line 540, 59 lines) - `Connect-SuggestionSystems` (Line 995, 61 lines) - `ConvertTo-SimpleEmbedding` (Line 368, 72 lines) - `Find-MissingCrossReferences` (Line 601, 77 lines) - `Find-RelatedContent` (Line 442, 96 lines) - `Generate-AIContentSuggestions` (Line 680, 78 lines) - `Generate-ContentEmbedding` (Line 288, 78 lines) - `Generate-RelatedContentSuggestions` (Line 134, 152 lines) - `Generate-RuleBasedSuggestions` (Line 835, 65 lines) - `Get-AvailableFunctions` (Line 954, 39 lines) - `Get-DocumentationSuggestionStatistics` (Line 1134, 24 lines) - `Get-IndexedDocuments` (Line 902, 50 lines) - `Initialize-DocumentationSuggestions` (Line 49, 83 lines) - `Parse-AISuggestionResponse` (Line 760, 73 lines) - `Test-DocumentationSuggestions` (Line 1058, 74 lines) 
### Unity-Claude-DocumentationVersioning

- **Path:** `Modules\Unity-Claude-DocumentationVersioning\Unity-Claude-DocumentationVersioning.psm1`
- **Size:** 25.49 KB
- **Functions:** 25
- **Lines:** 720
- **Last Modified:** 08/30/2025 15:41:50

**Functions:**
- `Calculate-CorrelationStrength` (Line 678, 3 lines) - `Calculate-NextVersion` (Line 594, 19 lines) - `Create-ConventionalCommitMessage` (Line 615, 12 lines) - `Create-DocumentationRelease` (Line 394, 87 lines) - `Create-DocumentationVersion` (Line 204, 98 lines) - `Create-GitDocumentationTag` (Line 652, 3 lines) - `Find-RelatedDocumentationChanges` (Line 672, 4 lines) - `Generate-AutomatedReleaseNotes` (Line 634, 3 lines) - `Get-ChangesSinceLastRelease` (Line 647, 3 lines) - `Get-CurrentDocumentationQualityMetrics` (Line 643, 2 lines) - `Get-CurrentDocumentationVersion` (Line 589, 3 lines) - `Get-DefaultVersioningConfiguration` (Line 148, 54 lines) - `Get-DocumentationFilesSnapshot` (Line 639, 2 lines) - `Get-DocumentationVersioningStatistics` (Line 688, 20 lines) - `Initialize-DocumentationVersioning` (Line 68, 78 lines) - `Initialize-GitIntegration` (Line 583, 4 lines) - `Initialize-VersionTracking` (Line 572, 4 lines) - `Map-ChangeCorrelations` (Line 667, 3 lines) - `Perform-GitVersioningOperations` (Line 657, 8 lines) - `Setup-ChangeCorrelationSystem` (Line 578, 3 lines) - `Test-DocumentationVersioning` (Line 483, 80 lines) - `Test-GitIntegration` (Line 683, 3 lines) - `Test-GitRepository` (Line 566, 4 lines) - `Test-SemanticVersionFormat` (Line 629, 3 lines) - `Track-DocumentationChangeCorrelation` (Line 304, 88 lines) 
### Unity-Claude-EmailNotifications-SystemNetMail

- **Path:** `Modules\Unity-Claude-EmailNotifications\Unity-Claude-EmailNotifications-SystemNetMail.psm1`
- **Size:** 45.7 KB
- **Functions:** 13
- **Lines:** 1170
- **Last Modified:** 08/21/2025 17:45:27

**Functions:**
- `Format-NotificationContent` (Line 602, 78 lines) - `Get-EmailConfiguration` (Line 470, 68 lines) - `Get-EmailDeliveryStats` (Line 1102, 13 lines) - `Get-EmailDeliveryStatus` (Line 1031, 69 lines) - `Get-EmailNotificationTriggers` (Line 984, 45 lines) - `Invoke-EmailNotificationTrigger` (Line 856, 126 lines) - `New-EmailConfiguration` (Line 23, 81 lines) - `New-EmailTemplate` (Line 541, 59 lines) - `Register-EmailNotificationTrigger` (Line 774, 80 lines) - `Send-EmailNotification` (Line 331, 137 lines) - `Send-EmailWithRetry` (Line 682, 90 lines) - `Set-EmailCredentials` (Line 106, 83 lines) - `Test-EmailConfiguration` (Line 191, 138 lines) 
### Unity-Claude-EmailNotifications

- **Path:** `Modules\Unity-Claude-EmailNotifications\Unity-Claude-EmailNotifications.psm1`
- **Size:** 27.9 KB
- **Functions:** 7
- **Lines:** 679
- **Last Modified:** 08/21/2025 17:45:27

**Functions:**
- `Format-NotificationContent` (Line 542, 79 lines) - `Get-EmailConfiguration` (Line 408, 68 lines) - `Load-MailKitAssemblies` (Line 22, 59 lines) - `New-EmailConfiguration` (Line 84, 80 lines) - `New-EmailTemplate` (Line 479, 61 lines) - `Set-EmailCredentials` (Line 166, 85 lines) - `Test-EmailConfiguration` (Line 253, 153 lines) 
### Unity-Claude-ErrorHandling

- **Path:** `Modules\Unity-Claude-ParallelProcessing\Unity-Claude-ErrorHandling.psm1`
- **Size:** 28.54 KB
- **Functions:** 9
- **Lines:** 745
- **Last Modified:** 08/21/2025 17:45:27

**Functions:**
- `Get-ParallelErrorClassification` (Line 246, 55 lines) - `Get-ParallelErrorHandlingStats` (Line 643, 46 lines) - `Get-ParallelErrorReport` (Line 317, 59 lines) - `Initialize-CircuitBreaker` (Line 402, 34 lines) - `Initialize-ParallelErrorHandling` (Line 604, 26 lines) - `Invoke-AsyncWithErrorHandling` (Line 49, 124 lines) - `New-ParallelErrorAggregator` (Line 189, 34 lines) - `Test-CircuitBreakerState` (Line 452, 51 lines) - `Update-CircuitBreakerState` (Line 525, 59 lines) 
### Unity-Claude-Errors

- **Path:** `Modules\Unity-Claude-Errors\Unity-Claude-Errors.psm1`
- **Size:** 23.76 KB
- **Functions:** 9
- **Lines:** 727
- **Last Modified:** 08/20/2025 17:25:21

**Functions:**
- `Add-ErrorPattern` (Line 101, 62 lines) - `Export-ErrorReport` (Line 583, 95 lines) - `Find-SimilarErrors` (Line 213, 51 lines) - `Get-ErrorPattern` (Line 165, 46 lines) - `Get-ErrorSeverity` (Line 438, 47 lines) - `Get-ErrorStatistics` (Line 491, 90 lines) - `Initialize-ErrorDatabase` (Line 14, 81 lines) - `Parse-UnityError` (Line 397, 39 lines) - `Update-ErrorSolution` (Line 270, 121 lines) 
### Unity-Claude-EventLog

- **Path:** `Modules\Unity-Claude-EventLog\Unity-Claude-EventLog.psm1`
- **Size:** 4.87 KB
- **Functions:** 1
- **Lines:** 115
- **Last Modified:** 08/24/2025 12:06:11

**Functions:**
- `Write-UCDebugLog` (Line 35, 15 lines) 
### Unity-Claude-FileMonitor-Fixed

- **Path:** `Modules\Unity-Claude-FileMonitor\Unity-Claude-FileMonitor-Fixed.psm1`
- **Size:** 25.9 KB
- **Functions:** 17
- **Lines:** 735
- **Last Modified:** 08/24/2025 12:06:11

**Functions:**
- `Add-MonitorPath` (Line 583, 26 lines) - `Clear-ChangeQueue` (Line 550, 12 lines) - `Get-AggregatedChanges` (Line 306, 40 lines) - `Get-FileMonitorStatus` (Line 516, 18 lines) - `Get-MonitoredPaths` (Line 631, 17 lines) - `Get-PendingChanges` (Line 536, 12 lines) - `Get-SafeChangePriority` (Line 392, 25 lines) - `Get-SafeFileType` (Line 348, 42 lines) - `New-FileMonitor` (Line 52, 68 lines) - `Register-FileChangeHandler` (Line 504, 10 lines) - `Remove-MonitorPath` (Line 611, 18 lines) - `Set-DebounceInterval` (Line 564, 17 lines) - `Start-DebounceTimer` (Line 239, 65 lines) - `Start-FileMonitor` (Line 122, 115 lines) - `Stop-FileMonitor` (Line 419, 83 lines) - `Test-FileChangeClassification` (Line 650, 12 lines) - `Write-FileMonitorLog` (Line 28, 22 lines) 
### Unity-Claude-FileMonitor

- **Path:** `Modules\Unity-Claude-FileMonitor\Unity-Claude-FileMonitor.psm1`
- **Size:** 24.06 KB
- **Functions:** 15
- **Lines:** 650
- **Last Modified:** 08/24/2025 12:06:11

**Functions:**
- `Add-MonitorPath` (Line 511, 25 lines) - `Aggregate-Changes` (Line 328, 36 lines) - `Clear-ChangeQueue` (Line 478, 12 lines) - `Get-ChangePriority` (Line 393, 28 lines) - `Get-FileMonitorStatus` (Line 435, 19 lines) - `Get-FileType` (Line 366, 25 lines) - `Get-MonitoredPaths` (Line 557, 5 lines) - `Get-PendingChanges` (Line 456, 20 lines) - `New-FileMonitor` (Line 35, 64 lines) - `Register-FileChangeHandler` (Line 423, 10 lines) - `Remove-MonitorPath` (Line 538, 17 lines) - `Set-DebounceInterval` (Line 492, 17 lines) - `Start-FileMonitor` (Line 101, 169 lines) - `Stop-FileMonitor` (Line 272, 53 lines) - `Test-FileChangeClassification` (Line 564, 12 lines) 
### Unity-Claude-FixEngine

- **Path:** `Modules\Unity-Claude-FixEngine\Unity-Claude-FixEngine.psm1`
- **Size:** 49.76 KB
- **Functions:** 25
- **Lines:** 1438
- **Last Modified:** 08/20/2025 17:25:21

**Functions:**
- `Clear-OldBackups` (Line 232, 26 lines) - `Connect-LearningModule` (Line 1140, 46 lines) - `Connect-SafetyFramework` (Line 1104, 34 lines) - `Get-CodePattern` (Line 454, 97 lines) - `Get-CompilationErrors` (Line 973, 45 lines) - `Get-CSharpAST` (Line 376, 76 lines) - `Get-FixEngineConfig` (Line 106, 6 lines) - `Get-UnityEditorPath` (Line 1020, 23 lines) - `Invoke-AtomicFileReplace` (Line 300, 70 lines) - `Invoke-CompilationVerification` (Line 1045, 53 lines) - `Invoke-FixApplication` (Line 1226, 135 lines) - `Invoke-TemplateApplication` (Line 642, 82 lines) - `New-BackupFile` (Line 176, 54 lines) - `New-CodeFix` (Line 1363, 16 lines) - `New-FixTemplate` (Line 557, 83 lines) - `Restore-BackupFile` (Line 260, 38 lines) - `Send-FixMetrics` (Line 1188, 32 lines) - `Set-FixEngineConfig` (Line 114, 56 lines) - `Test-CompilationValidation` (Line 834, 47 lines) - `Test-FixSuccess` (Line 1381, 16 lines) - `Test-FixValidation` (Line 730, 46 lines) - `Test-RequiredModule` (Line 87, 13 lines) - `Test-SyntaxValidation` (Line 778, 54 lines) - `Test-UnityCompilation` (Line 887, 84 lines) - `Write-FixEngineLog` (Line 48, 37 lines) 
### Unity-Claude-GitHub

- **Path:** `Modules\Unity-Claude-GitHub\Unity-Claude-GitHub.psm1`
- **Size:** 7.07 KB
- **Functions:** 1
- **Lines:** 176
- **Last Modified:** 08/30/2025 23:15:35

**Functions:**
- `ConvertTo-HashTable` (Line 54, 28 lines) 
### Unity-Claude-GovernanceIntegration

- **Path:** `Modules\Unity-Claude-HITL\Unity-Claude-GovernanceIntegration.psm1`
- **Size:** 22.24 KB
- **Functions:** 7
- **Lines:** 583
- **Last Modified:** 08/24/2025 12:06:11

**Functions:**
- `Get-ChangeRiskAssessment` (Line 450, 44 lines) - `Get-CodeOwnersRequirements` (Line 410, 38 lines) - `New-GovernanceAwareApprovalRequest` (Line 178, 130 lines) - `Test-ApprovalGovernanceCompliance` (Line 525, 14 lines) - `Test-GitHubGovernanceCompliance` (Line 7, 169 lines) - `Test-GovernancePolicyViolations` (Line 496, 27 lines) - `Wait-GovernanceApproval` (Line 310, 94 lines) 
### Unity-Claude-HITL-Original

- **Path:** `Modules\Unity-Claude-HITL\Unity-Claude-HITL-Original.psm1`
- **Size:** 32.77 KB
- **Functions:** 13
- **Lines:** 946
- **Last Modified:** 08/26/2025 11:46:18

**Functions:**
- `Export-ApprovalMetrics` (Line 888, 13 lines) - `Get-ApprovalStatus` (Line 702, 28 lines) - `Get-PendingApprovals` (Line 872, 14 lines) - `Initialize-ApprovalDatabase` (Line 56, 116 lines) - `Invoke-ApprovalAction` (Line 819, 51 lines) - `New-ApprovalRequest` (Line 282, 116 lines) - `New-ApprovalToken` (Line 178, 53 lines) - `Resume-WorkflowFromApproval` (Line 644, 52 lines) - `Send-ApprovalNotification` (Line 404, 141 lines) - `Set-ApprovalEscalation` (Line 732, 38 lines) - `Set-HITLConfiguration` (Line 776, 37 lines) - `Test-ApprovalToken` (Line 233, 43 lines) - `Wait-HumanApproval` (Line 551, 91 lines) 
### Unity-Claude-HITL-Refactored

- **Path:** `Modules\Unity-Claude-HITL\Unity-Claude-HITL-Refactored.psm1`
- **Size:** 15.55 KB
- **Functions:** 3
- **Lines:** 425
- **Last Modified:** 08/26/2025 11:46:18

**Functions:**
- `Get-HITLComponents` (Line 43, 39 lines) - `Invoke-ComprehensiveHITLAnalysis` (Line 218, 96 lines) - `Test-HITLSystemIntegration` (Line 84, 132 lines) 
### Unity-Claude-HITL

- **Path:** `Modules\Unity-Claude-HITL\Unity-Claude-HITL.psm1`
- **Size:** 15.55 KB
- **Functions:** 3
- **Lines:** 425
- **Last Modified:** 08/26/2025 11:46:18

**Functions:**
- `Get-HITLComponents` (Line 43, 39 lines) - `Invoke-ComprehensiveHITLAnalysis` (Line 218, 96 lines) - `Test-HITLSystemIntegration` (Line 84, 132 lines) 
### Unity-Claude-IncrementalProcessor-Fixed

- **Path:** `Modules\Unity-Claude-IncrementalProcessor\Unity-Claude-IncrementalProcessor-Fixed.psm1`
- **Size:** 28.41 KB
- **Functions:** 34
- **Lines:** 813
- **Last Modified:** 08/25/2025 13:45:24

**Functions:**
- `Build-DependencyGraph` (Line 745, 9 lines) - `BuildDependencyGraph` (Line 501, 13 lines) - `CalculateASTDiff` (Line 403, 35 lines, 2 params) - `CalculateDiff` (Line 356, 44 lines, 2 params) - `CreateCheckpoint` (Line 591, 9 lines) - `CreateFileSnapshot` (Line 133, 37 lines, 1 params) - `CreateInitialSnapshots` (Line 111, 19 lines, 1 params) - `Dispose` (Line 613, 14 lines) - `ExtractDependencies` (Line 517, 26 lines, 1 params) - `Get-IncrementalProcessorStatistics` (Line 695, 9 lines) - `GetContentHash` (Line 173, 5 lines, 1 params) - `GetDependentFiles` (Line 492, 6 lines, 1 params) - `GetStatistics` (Line 574, 14 lines) - `HandleFileChange` (Line 181, 22 lines, 2 params) - `IncrementalProcessor` (Line 25, 29 lines, 3 params) - `InvalidateCacheForFile` (Line 546, 25 lines, 1 params) - `New-IncrementalProcessor` (Line 632, 39 lines) - `New-ProcessorCheckpoint` (Line 706, 9 lines) - `ProcessChangeQueue` (Line 206, 46 lines) - `ProcessFileChange` (Line 255, 14 lines, 1 params) - `ProcessFileCreated` (Line 272, 20 lines, 1 params) - `ProcessFileDeleted` (Line 335, 18 lines, 1 params) - `ProcessFileModified` (Line 295, 37 lines, 1 params) - `PropagateChanges` (Line 471, 18 lines, 2 params) - `Restore-ProcessorCheckpoint` (Line 717, 12 lines) - `RestoreCheckpoint` (Line 603, 7 lines, 1 params) - `SetupFileWatcher` (Line 57, 34 lines, 1 params) - `Start` (Line 94, 7 lines) - `Start-IncrementalProcessing` (Line 673, 9 lines) - `Start-ProcessChangeQueue` (Line 756, 9 lines) - `Stop` (Line 104, 4 lines) - `Stop-IncrementalProcessing` (Line 684, 9 lines) - `Update-CPGIncremental` (Line 731, 12 lines) - `UpdateCPGForFile` (Line 441, 27 lines, 4 params) 
### Unity-Claude-IncrementalProcessor

- **Path:** `Modules\Unity-Claude-IncrementalProcessor\Unity-Claude-IncrementalProcessor.psm1`
- **Size:** 28.41 KB
- **Functions:** 34
- **Lines:** 813
- **Last Modified:** 08/25/2025 13:45:24

**Functions:**
- `Build-DependencyGraph` (Line 745, 9 lines) - `BuildDependencyGraph` (Line 501, 13 lines) - `CalculateASTDiff` (Line 403, 35 lines, 2 params) - `CalculateDiff` (Line 356, 44 lines, 2 params) - `CreateCheckpoint` (Line 591, 9 lines) - `CreateFileSnapshot` (Line 133, 37 lines, 1 params) - `CreateInitialSnapshots` (Line 111, 19 lines, 1 params) - `Dispose` (Line 613, 14 lines) - `ExtractDependencies` (Line 517, 26 lines, 1 params) - `Get-IncrementalProcessorStatistics` (Line 695, 9 lines) - `GetContentHash` (Line 173, 5 lines, 1 params) - `GetDependentFiles` (Line 492, 6 lines, 1 params) - `GetStatistics` (Line 574, 14 lines) - `HandleFileChange` (Line 181, 22 lines, 2 params) - `IncrementalProcessor` (Line 25, 29 lines, 3 params) - `InvalidateCacheForFile` (Line 546, 25 lines, 1 params) - `New-IncrementalProcessor` (Line 632, 39 lines) - `New-ProcessorCheckpoint` (Line 706, 9 lines) - `ProcessChangeQueue` (Line 206, 46 lines) - `ProcessFileChange` (Line 255, 14 lines, 1 params) - `ProcessFileCreated` (Line 272, 20 lines, 1 params) - `ProcessFileDeleted` (Line 335, 18 lines, 1 params) - `ProcessFileModified` (Line 295, 37 lines, 1 params) - `PropagateChanges` (Line 471, 18 lines, 2 params) - `Restore-ProcessorCheckpoint` (Line 717, 12 lines) - `RestoreCheckpoint` (Line 603, 7 lines, 1 params) - `SetupFileWatcher` (Line 57, 34 lines, 1 params) - `Start` (Line 94, 7 lines) - `Start-IncrementalProcessing` (Line 673, 9 lines) - `Start-ProcessChangeQueue` (Line 756, 9 lines) - `Stop` (Line 104, 4 lines) - `Stop-IncrementalProcessing` (Line 684, 9 lines) - `Update-CPGIncremental` (Line 731, 12 lines) - `UpdateCPGForFile` (Line 441, 27 lines, 4 params) 
### Unity-Claude-IntegratedWorkflow-Original

- **Path:** `Modules\Unity-Claude-IntegratedWorkflow\Unity-Claude-IntegratedWorkflow-Original.psm1`
- **Size:** 82.62 KB
- **Functions:** 13
- **Lines:** 1723
- **Last Modified:** 08/26/2025 11:46:18

**Functions:**
- `Assert-Dependencies` (Line 160, 10 lines) - `Get-IntegratedWorkflowStatus` (Line 675, 89 lines) - `Get-WorkflowPerformanceAnalysis` (Line 1422, 228 lines) - `Initialize-AdaptiveThrottling` (Line 919, 76 lines) - `New-IntegratedWorkflow` (Line 195, 172 lines) - `New-IntelligentJobBatching` (Line 1157, 249 lines) - `Start-IntegratedWorkflow` (Line 385, 276 lines) - `Stop-IntegratedWorkflow` (Line 780, 115 lines) - `Test-ModuleDependencies` (Line 92, 12 lines) - `Test-ModuleDependencyAvailability` (Line 3, 20 lines) - `Update-AdaptiveThrottling` (Line 1007, 132 lines) - `Write-FallbackLog` (Line 113, 19 lines) - `Write-IntegratedWorkflowLog` (Line 135, 13 lines) 
### Unity-Claude-IntegrationEngine

- **Path:** `Modules\Unity-Claude-IntegrationEngine.psm1`
- **Size:** 29.48 KB
- **Functions:** 20
- **Lines:** 807
- **Last Modified:** 08/20/2025 17:25:22

**Functions:**
- `Complete-FeedbackCycle` (Line 275, 23 lines) - `Get-CurrentTimestamp` (Line 113, 2 lines) - `Get-FeedbackLoopStatus` (Line 685, 24 lines) - `Get-IntegrationState` (Line 158, 14 lines) - `Initialize-IntegrationState` (Line 125, 31 lines) - `Invoke-CompleteFeedbackCycle` (Line 601, 59 lines) - `Invoke-FeedbackCyclePhase1Monitor` (Line 304, 26 lines) - `Invoke-FeedbackCyclePhase2Parse` (Line 332, 26 lines) - `Invoke-FeedbackCyclePhase3Analyze` (Line 360, 26 lines) - `Invoke-FeedbackCyclePhase4Execute` (Line 388, 40 lines) - `Invoke-FeedbackCyclePhase5Generate` (Line 430, 32 lines) - `Invoke-FeedbackCyclePhase6Submit` (Line 464, 26 lines) - `New-CycleId` (Line 117, 2 lines) - `New-FeedbackCycle` (Line 208, 32 lines) - `Resume-FeedbackLoopSession` (Line 711, 34 lines) - `Start-AutonomousFeedbackLoop` (Line 496, 103 lines) - `Stop-AutonomousFeedbackLoop` (Line 662, 21 lines) - `Update-CyclePhase` (Line 242, 31 lines) - `Update-IntegrationState` (Line 174, 28 lines) - `Write-IntegrationLog` (Line 81, 30 lines) 
### Unity-Claude-IntelligentAlerting

- **Path:** `Modules\Unity-Claude-IntelligentAlerting\Unity-Claude-IntelligentAlerting.psm1`
- **Size:** 21.6 KB
- **Functions:** 14
- **Lines:** 648
- **Last Modified:** 08/30/2025 13:44:48

**Functions:**
- `Check-EscalationTimeouts` (Line 515, 29 lines) - `Connect-AvailableModules` (Line 90, 75 lines) - `Create-AlertNotificationContent` (Line 426, 56 lines) - `Execute-AlertEscalation` (Line 546, 25 lines) - `Get-IntelligentAlertingStatistics` (Line 623, 16 lines) - `Initialize-IntelligentAlerting` (Line 57, 31 lines) - `Process-IntelligentAlert` (Line 262, 61 lines) - `Send-ClassifiedNotification` (Line 345, 79 lines) - `Setup-AlertEscalation` (Line 484, 29 lines) - `Start-AlertProcessingThread` (Line 193, 67 lines) - `Start-IntelligentAlerting` (Line 167, 24 lines) - `Stop-IntelligentAlerting` (Line 601, 20 lines) - `Submit-Alert` (Line 573, 26 lines) - `Test-AlertDeduplication` (Line 325, 18 lines) 
### Unity-Claude-IntelligentDocumentationTriggers

- **Path:** `Modules\Unity-Claude-IntelligentDocumentationTriggers\Unity-Claude-IntelligentDocumentationTriggers.psm1`
- **Size:** 26.53 KB
- **Functions:** 20
- **Lines:** 729
- **Last Modified:** 08/30/2025 15:41:02

**Functions:**
- `Analyze-ChangeImpact` (Line 275, 72 lines) - `Calculate-ChangeAnalysisConfidence` (Line 664, 9 lines) - `Determine-FinalTriggerDecision` (Line 646, 16 lines) - `Discover-TriggerSystems` (Line 619, 5 lines) - `Evaluate-IntelligentTrigger` (Line 188, 85 lines) - `Evaluate-QualityBasedTrigger` (Line 641, 3 lines) - `Get-DefaultIntelligentTriggersConfiguration` (Line 143, 43 lines) - `Get-IntelligentTriggersStatistics` (Line 701, 19 lines) - `Get-ProjectContext` (Line 680, 3 lines) - `Get-RecentFileActivity` (Line 675, 3 lines) - `Initialize-AIDecisionMaker` (Line 626, 3 lines) - `Initialize-ChangeAnalyzer` (Line 631, 3 lines) - `Initialize-IntelligentDocumentationTriggers` (Line 67, 74 lines) - `Make-AITriggerDecision` (Line 443, 95 lines) - `Make-FallbackTriggerDecision` (Line 690, 3 lines) - `Parse-AIDecisionResponse` (Line 685, 3 lines) - `Perform-ASTChangeAnalysis` (Line 349, 92 lines) - `Setup-TriggerSystemIntegration` (Line 636, 3 lines) - `Test-IntelligentDocumentationTriggers` (Line 540, 76 lines) - `Test-TriggerSystemIntegration` (Line 695, 4 lines) 
### Unity-Claude-IPC-Bidirectional-Fixed

- **Path:** `Modules\Unity-Claude-IPC-Bidirectional\Unity-Claude-IPC-Bidirectional-Fixed.psm1`
- **Size:** 20.33 KB
- **Functions:** 12
- **Lines:** 680
- **Last Modified:** 08/20/2025 17:25:21

**Functions:**
- `Add-MessageToQueue` (Line 401, 23 lines) - `Clear-MessageQueue` (Line 512, 20 lines) - `Get-NextMessage` (Line 426, 42 lines) - `Get-QueueStatus` (Line 470, 40 lines) - `Initialize-MessageQueues` (Line 384, 15 lines) - `Send-PipeMessage` (Line 173, 55 lines) - `Start-BidirectionalServers` (Line 538, 37 lines) - `Start-HttpApiServer` (Line 234, 69 lines) - `Start-HttpRequestHandler` (Line 305, 73 lines) - `Start-NamedPipeServer` (Line 29, 142 lines) - `Stop-BidirectionalServers` (Line 577, 43 lines) - `Write-Log` (Line 6, 7 lines) 
### Unity-Claude-IPC-Bidirectional

- **Path:** `Modules\Unity-Claude-IPC-Bidirectional\Unity-Claude-IPC-Bidirectional.psm1`
- **Size:** 20.33 KB
- **Functions:** 12
- **Lines:** 680
- **Last Modified:** 08/20/2025 17:25:21

**Functions:**
- `Add-MessageToQueue` (Line 401, 23 lines) - `Clear-MessageQueue` (Line 512, 20 lines) - `Get-NextMessage` (Line 426, 42 lines) - `Get-QueueStatus` (Line 470, 40 lines) - `Initialize-MessageQueues` (Line 384, 15 lines) - `Send-PipeMessage` (Line 173, 55 lines) - `Start-BidirectionalServers` (Line 538, 37 lines) - `Start-HttpApiServer` (Line 234, 69 lines) - `Start-HttpRequestHandler` (Line 305, 73 lines) - `Start-NamedPipeServer` (Line 29, 142 lines) - `Stop-BidirectionalServers` (Line 577, 43 lines) - `Write-Log` (Line 6, 7 lines) 
### Unity-Claude-IPC

- **Path:** `Modules\Unity-Claude-IPC\Unity-Claude-IPC.psm1`
- **Size:** 14.76 KB
- **Functions:** 9
- **Lines:** 475
- **Last Modified:** 08/20/2025 17:25:21

**Functions:**
- `Build-ClaudePrompt` (Line 146, 28 lines) - `Format-ErrorContext` (Line 345, 40 lines) - `Get-PromptBoilerplate` (Line 387, 40 lines) - `Invoke-ClaudeAnalysis` (Line 37, 33 lines) - `Receive-ClaudeResponse` (Line 232, 38 lines) - `Send-ClaudePrompt` (Line 72, 72 lines) - `Split-ConsoleLog` (Line 276, 67 lines) - `Start-BidirectionalPipe` (Line 180, 50 lines) - `Test-ClaudeAvailable` (Line 18, 17 lines) 
### Unity-Claude-LangGraphBridge

- **Path:** `Modules\Unity-Claude-AI-Integration\LangGraph\Unity-Claude-LangGraphBridge.psm1`
- **Size:** 11.73 KB
- **Functions:** 8
- **Lines:** 414
- **Last Modified:** 08/29/2025 15:17:11

**Functions:**
- `Get-LangGraphConfig` (Line 297, 16 lines) - `Get-LangGraphWorkflows` (Line 228, 24 lines) - `Get-WorkflowResult` (Line 127, 57 lines) - `New-LangGraphWorkflow` (Line 30, 46 lines) - `Set-LangGraphConfig` (Line 254, 41 lines) - `Submit-WorkflowTask` (Line 78, 47 lines) - `Test-LangGraphServer` (Line 186, 40 lines) - `Test-LangGraphWorkflow` (Line 315, 78 lines) 
### Unity-Claude-Learning-Analytics

- **Path:** `Modules\Unity-Claude-Learning\Unity-Claude-Learning-Analytics.psm1`
- **Size:** 24.52 KB
- **Functions:** 8
- **Lines:** 688
- **Last Modified:** 08/20/2025 17:25:21

**Functions:**
- `Calculate-MovingAverage` (Line 127, 46 lines) - `Get-AdjustedConfidence` (Line 376, 67 lines) - `Get-AllPatternsSuccessRates` (Line 83, 38 lines) - `Get-LearningTrend` (Line 175, 109 lines) - `Get-PatternEffectivenessRanking` (Line 553, 83 lines) - `Get-PatternSuccessRate` (Line 7, 74 lines) - `Get-RecommendedPatterns` (Line 449, 102 lines) - `Update-PatternConfidence` (Line 290, 84 lines) 
### Unity-Claude-Learning-Original

- **Path:** `Modules\Unity-Claude-Learning\Unity-Claude-Learning-Original.psm1`
- **Size:** 79.5 KB
- **Functions:** 26
- **Lines:** 2294
- **Last Modified:** 08/26/2025 11:46:18

**Functions:**
- `Add-ErrorPattern` (Line 1033, 88 lines) - `Add-ErrorPatternSQLite` (Line 1123, 78 lines) - `Apply-AutoFix` (Line 1288, 81 lines) - `Calculate-ConfidenceScore` (Line 751, 130 lines) - `Find-CodePattern` (Line 962, 65 lines) - `Find-SimilarPatterns` (Line 348, 51 lines) - `Find-SimilarPatterns` (Line 401, 50 lines) - `Find-SimilarPatternsJSON` (Line 618, 67 lines) - `Find-SimilarPatternsMemory` (Line 687, 62 lines) - `Find-SimilarPatternsSQLite` (Line 453, 163 lines) - `Get-CodeAST` (Line 887, 73 lines) - `Get-ErrorSignature` (Line 296, 50 lines) - `Get-LearningConfig` (Line 2167, 9 lines) - `Get-LearningMetrics` (Line 1683, 159 lines) - `Get-LearningReport` (Line 1461, 76 lines) - `Get-LevenshteinDistance` (Line 238, 56 lines) - `Get-MetricsFromJSON` (Line 1844, 106 lines) - `Get-PatternUsageAnalytics` (Line 2006, 126 lines) - `Get-StringSimilarity` (Line 181, 55 lines) - `Get-SuggestedFixes` (Line 1203, 79 lines) - `Initialize-LearningDatabase` (Line 32, 143 lines) - `Measure-ExecutionTime` (Line 1952, 52 lines) - `Record-PatternApplicationMetric` (Line 1543, 93 lines) - `Save-MetricToJSON` (Line 1638, 43 lines) - `Set-LearningConfig` (Line 2138, 27 lines) - `Update-PatternSuccess` (Line 1375, 84 lines) 
### Unity-Claude-Learning-Simple

- **Path:** `Modules\Unity-Claude-Learning-Simple\Unity-Claude-Learning-Simple.psm1`
- **Size:** 53.76 KB
- **Functions:** 25
- **Lines:** 1739
- **Last Modified:** 08/20/2025 17:25:21

**Functions:**
- `Add-ErrorPattern` (Line 261, 93 lines) - `Analyze-ErrorPattern` (Line 1174, 39 lines) - `Apply-AutoFix` (Line 481, 100 lines) - `Clear-LevenshteinCache` (Line 1633, 16 lines) - `ConvertFrom-JsonToHashtable` (Line 94, 34 lines) - `Export-LearningReport` (Line 683, 101 lines) - `Find-CodePattern` (Line 955, 89 lines) - `Find-SimilarPatterns` (Line 1545, 86 lines) - `Get-ASTElements` (Line 1046, 73 lines) - `Get-CodeAST` (Line 880, 73 lines) - `Get-LearningConfig` (Line 872, 2 lines) - `Get-LearningReport` (Line 630, 51 lines) - `Get-LevenshteinCacheInfo` (Line 1651, 18 lines) - `Get-LevenshteinDistance` (Line 1294, 149 lines) - `Get-StringSimilarity` (Line 1445, 56 lines) - `Get-SuggestedFixes` (Line 356, 119 lines) - `Get-UnityErrorPattern` (Line 1267, 17 lines) - `Initialize-LearningStorage` (Line 134, 83 lines) - `Save-Metrics` (Line 238, 17 lines) - `Save-Patterns` (Line 219, 17 lines) - `Set-LearningConfig` (Line 790, 80 lines) - `Test-CodeSyntax` (Line 1121, 51 lines) - `Test-FuzzyMatch` (Line 1503, 40 lines) - `Update-FixSuccess` (Line 583, 41 lines) - `Write-LearningLog` (Line 37, 51 lines) 
### Unity-Claude-LLM

- **Path:** `Modules\Unity-Claude-LLM\Unity-Claude-LLM.psm1`
- **Size:** 16 KB
- **Functions:** 10
- **Lines:** 522
- **Last Modified:** 08/30/2025 19:47:36

**Functions:**
- `Get-LLMConfiguration` (Line 412, 5 lines) - `Get-OllamaModels` (Line 48, 21 lines) - `Invoke-CodeAnalysis` (Line 347, 59 lines) - `Invoke-DocumentationGeneration` (Line 180, 57 lines) - `Invoke-OllamaGenerate` (Line 71, 47 lines) - `New-CodeAnalysisPrompt` (Line 243, 102 lines) - `New-DocumentationPrompt` (Line 124, 54 lines) - `Set-LLMConfiguration` (Line 419, 23 lines) - `Test-LLMAvailability` (Line 444, 28 lines) - `Test-OllamaConnection` (Line 25, 21 lines) 
### Unity-Claude-MachineLearning

- **Path:** `Modules\Unity-Claude-MachineLearning\Unity-Claude-MachineLearning.psm1`
- **Size:** 53.6 KB
- **Functions:** 25
- **Lines:** 1428
- **Last Modified:** 08/30/2025 20:27:30

**Functions:**
- `Analyze-HistoricalPatterns` (Line 1116, 34 lines) - `Calculate-EuclideanDistance` (Line 1299, 12 lines) - `Calculate-PredictionConfidence` (Line 1290, 7 lines) - `Calculate-SilhouetteScore` (Line 1313, 5 lines) - `Calculate-SyntheticPerformance` (Line 280, 12 lines) - `Calculate-TrendSlope` (Line 1320, 20 lines) - `Generate-IntelligentRecommendations` (Line 1152, 117 lines) - `Get-ClassificationPrediction` (Line 1272, 16 lines) - `Get-IntelligentRecommendations` (Line 1026, 88 lines) - `Get-MachineLearningStatus` (Line 1342, 71 lines) - `Get-MaintenancePrediction` (Line 929, 50 lines) - `Get-PerformanceOptimizationPrediction` (Line 797, 58 lines) - `Get-PredictiveAnalysis` (Line 651, 93 lines) - `Get-SyntheticClassification` (Line 267, 11 lines) - `Get-SystemBehaviorPrediction` (Line 746, 49 lines) - `Get-UsagePatternsPrediction` (Line 857, 70 lines) - `Initialize-MachineLearning` (Line 70, 87 lines) - `Initialize-PatternModels` (Line 159, 50 lines) - `Initialize-SyntheticTrainingData` (Line 211, 54 lines) - `Start-AdaptiveLearning` (Line 981, 43 lines) - `Train-MaintenanceModel` (Line 599, 50 lines) - `Train-PerformanceModel` (Line 440, 69 lines) - `Train-PredictiveModels` (Line 294, 78 lines) - `Train-SystemBehaviorModel` (Line 374, 64 lines) - `Train-UsagePatternsModel` (Line 511, 86 lines) 
### Unity-Claude-MasterOrchestrator-Original

- **Path:** `Modules\Unity-Claude-MasterOrchestrator\Unity-Claude-MasterOrchestrator-Original.psm1`
- **Size:** 46.06 KB
- **Functions:** 34
- **Lines:** 1293
- **Last Modified:** 08/26/2025 11:46:19

**Functions:**
- `Add-EventToQueue` (Line 478, 14 lines) - `Clear-OrchestratorState` (Line 1210, 30 lines) - `Get-ModuleIntegrationPoints` (Line 341, 40 lines) - `Get-OperationHistory` (Line 1192, 16 lines) - `Get-OrchestratorStatus` (Line 1103, 23 lines) - `Initialize-ModuleIntegration` (Line 197, 86 lines) - `Initialize-SingleModule` (Line 285, 54 lines) - `Invoke-ApprovalRequest` (Line 977, 6 lines) - `Invoke-CommandExecution` (Line 928, 6 lines) - `Invoke-CommandValidation` (Line 936, 6 lines) - `Invoke-ConversationContinuation` (Line 944, 7 lines) - `Invoke-DecisionEventProcessing` (Line 625, 38 lines) - `Invoke-DecisionExecution` (Line 790, 83 lines) - `Invoke-ErrorAnalysis` (Line 961, 6 lines) - `Invoke-ErrorEventProcessing` (Line 665, 35 lines) - `Invoke-EventProcessing` (Line 516, 54 lines) - `Invoke-MonitoringContinuation` (Line 985, 6 lines) - `Invoke-RecommendationExecution` (Line 912, 6 lines) - `Invoke-ResponseEventProcessing` (Line 576, 47 lines) - `Invoke-ResponseGeneration` (Line 953, 6 lines) - `Invoke-SafetyEventProcessing` (Line 744, 40 lines) - `Invoke-SafetyValidation` (Line 875, 34 lines) - `Invoke-TestEventProcessing` (Line 702, 40 lines) - `Invoke-TestExecution` (Line 920, 6 lines) - `Invoke-WorkflowContinuation` (Line 969, 6 lines) - `Register-DecisionEngineEvents` (Line 454, 22 lines) - `Register-ResponseMonitorEvents` (Line 429, 23 lines) - `Start-AutonomousFeedbackLoop` (Line 997, 57 lines) - `Start-EventDrivenProcessing` (Line 387, 40 lines) - `Start-EventProcessingLoop` (Line 494, 20 lines) - `Stop-AutonomousFeedbackLoop` (Line 1056, 41 lines) - `Test-ModuleAvailability` (Line 120, 71 lines) - `Test-OrchestratorIntegration` (Line 1128, 62 lines) - `Write-OrchestratorLog` (Line 81, 37 lines) 
### Unity-Claude-MasterOrchestrator-Refactored

- **Path:** `Modules\Unity-Claude-MasterOrchestrator\Unity-Claude-MasterOrchestrator-Refactored.psm1`
- **Size:** 11.45 KB
- **Functions:** 3
- **Lines:** 299
- **Last Modified:** 08/26/2025 11:46:19

**Functions:**
- `Get-MasterOrchestratorStatus` (Line 114, 37 lines) - `Initialize-MasterOrchestrator` (Line 60, 52 lines) - `Test-MasterOrchestratorIntegration` (Line 153, 52 lines) 
### Unity-Claude-MasterOrchestrator

- **Path:** `Modules\Unity-Claude-MasterOrchestrator\Unity-Claude-MasterOrchestrator.psm1`
- **Size:** 11.45 KB
- **Functions:** 3
- **Lines:** 299
- **Last Modified:** 08/26/2025 11:46:19

**Functions:**
- `Get-MasterOrchestratorStatus` (Line 114, 37 lines) - `Initialize-MasterOrchestrator` (Line 60, 52 lines) - `Test-MasterOrchestratorIntegration` (Line 153, 52 lines) 
### Unity-Claude-MemoryAnalysis

- **Path:** `Modules\Unity-Claude-MemoryAnalysis.psm1`
- **Size:** 16.55 KB
- **Functions:** 6
- **Lines:** 368
- **Last Modified:** 08/20/2025 17:25:22

**Functions:**
- `Analyze-MemoryData` (Line 126, 60 lines) - `Generate-AutonomousMemoryRecommendation` (Line 188, 56 lines) - `Get-UnityMemoryStatus` (Line 246, 35 lines) - `Process-MemoryDataFile` (Line 88, 36 lines) - `Start-UnityMemoryMonitoring` (Line 25, 61 lines) - `Test-MemoryMonitoringSystem` (Line 283, 39 lines) 
### Unity-Claude-MessageQueue

- **Path:** `Modules\Unity-Claude-MessageQueue\Unity-Claude-MessageQueue.psm1`
- **Size:** 18.19 KB
- **Functions:** 10
- **Lines:** 524
- **Last Modified:** 08/24/2025 12:06:11

**Functions:**
- `Add-MessageToQueue` (Line 49, 48 lines) - `Get-CircuitBreakerStatus` (Line 457, 18 lines) - `Get-MessageFromQueue` (Line 99, 46 lines) - `Get-QueueStatistics` (Line 433, 22 lines) - `Initialize-CircuitBreaker` (Line 247, 34 lines) - `Initialize-MessageQueue` (Line 22, 25 lines) - `Invoke-WithCircuitBreaker` (Line 283, 73 lines) - `Register-FileSystemWatcher` (Line 147, 98 lines) - `Register-MessageHandler` (Line 358, 21 lines) - `Start-MessageProcessor` (Line 381, 50 lines) 
### Unity-Claude-Monitoring

- **Path:** `Modules\Unity-Claude-Monitoring\Unity-Claude-Monitoring.psm1`
- **Size:** 20.05 KB
- **Functions:** 12
- **Lines:** 701
- **Last Modified:** 08/24/2025 12:06:11

**Functions:**
- `Get-ActiveAlerts` (Line 510, 48 lines) - `Get-ContainerMetrics` (Line 230, 63 lines) - `Get-PrometheusMetrics` (Line 168, 60 lines) - `Get-ServiceHealth` (Line 34, 59 lines) - `Get-ServiceLogs` (Line 383, 46 lines) - `ParseTimeRange` (Line 564, 17 lines) - `Search-Logs` (Line 299, 82 lines) - `Send-Alert` (Line 435, 73 lines) - `Start-MonitoringStack` (Line 583, 36 lines) - `Stop-MonitoringStack` (Line 621, 28 lines) - `Test-ServiceLiveness` (Line 95, 28 lines) - `Test-ServiceReadiness` (Line 125, 37 lines) 
### Unity-Claude-MultiStepOrchestrator

- **Path:** `Modules\Unity-Claude-AI-Integration\LangGraph\Unity-Claude-MultiStepOrchestrator.psm1`
- **Size:** 30.34 KB
- **Functions:** 12
- **Lines:** 753
- **Last Modified:** 08/29/2025 15:48:10

**Functions:**
- `Get-BottleneckAnalysis` (Line 693, 37 lines) - `Get-ResourceBaseline` (Line 467, 23 lines) - `Initialize-OrchestrationContext` (Line 131, 25 lines) - `Invoke-AIEnhancementWorker` (Line 308, 62 lines) - `Invoke-MultiStepAnalysisOrchestration` (Line 39, 90 lines) - `Invoke-OptimizationFramework` (Line 492, 55 lines) - `Invoke-ParallelAnalysisWorkers` (Line 158, 104 lines) - `Invoke-ResultValidation` (Line 549, 53 lines) - `Invoke-SynthesisWorker` (Line 372, 93 lines) - `New-ComprehensiveAnalysisReport` (Line 604, 46 lines) - `Receive-ParallelWorkerResults` (Line 264, 42 lines) - `Start-PerformanceMonitoring` (Line 656, 35 lines) 
### Unity-Claude-NotificationContentEngine

- **Path:** `Modules\Unity-Claude-NotificationContentEngine\Unity-Claude-NotificationContentEngine.psm1`
- **Size:** 50.83 KB
- **Functions:** 35
- **Lines:** 1701
- **Last Modified:** 08/21/2025 17:45:27

**Functions:**
- `Add-NotificationHistory` (Line 1619, 10 lines) - `Export-NotificationTemplate` (Line 280, 43 lines) - `Format-ContentForChannel` (Line 1512, 49 lines) - `Format-UnifiedNotificationContent` (Line 507, 42 lines) - `Get-ChannelPreferences` (Line 1060, 28 lines) - `Get-ContentEngineConfiguration` (Line 1423, 5 lines) - `Get-NotificationAnalytics` (Line 1316, 57 lines) - `Get-NotificationRouting` (Line 760, 37 lines) - `Get-NotificationStatus` (Line 1281, 33 lines) - `Get-NotificationTemplate` (Line 167, 27 lines) - `Get-TemplateComponent` (Line 431, 27 lines) - `Import-NotificationTemplate` (Line 325, 63 lines) - `Initialize-NotificationContentEngine` (Line 1379, 42 lines) - `Invoke-ChannelSelection` (Line 1090, 37 lines) - `Invoke-NotificationDelivery` (Line 1235, 44 lines) - `Invoke-SeverityBasedRouting` (Line 799, 59 lines) - `New-ChannelPreferences` (Line 985, 32 lines) - `New-NotificationRoutingRule` (Line 661, 42 lines) - `New-TemplateComponent` (Line 394, 35 lines) - `New-UnifiedNotificationTemplate` (Line 48, 53 lines) - `Preview-NotificationTemplate` (Line 607, 48 lines) - `Process-HashTableVariables` (Line 1563, 26 lines) - `Remove-NotificationTemplate` (Line 251, 27 lines) - `Select-NotificationChannels` (Line 932, 51 lines) - `Send-UnifiedNotification` (Line 1133, 100 lines) - `Set-ChannelPreferences` (Line 1019, 39 lines) - `Set-ContentEngineConfiguration` (Line 1430, 46 lines) - `Set-NotificationRouting` (Line 705, 53 lines) - `Set-NotificationTemplate` (Line 103, 62 lines) - `Set-TemplateComponent` (Line 460, 45 lines) - `Test-ChannelThrottling` (Line 1591, 26 lines) - `Test-NotificationRouting` (Line 860, 66 lines) - `Test-NotificationTemplate` (Line 196, 53 lines) - `Test-TemplateStructure` (Line 1482, 28 lines) - `Validate-NotificationContent` (Line 551, 54 lines) 
### Unity-Claude-NotificationIntegration-Modular

- **Path:** `Modules\Unity-Claude-NotificationIntegration\Unity-Claude-NotificationIntegration-Modular.psm1`
- **Size:** 13.61 KB
- **Functions:** 3
- **Lines:** 328
- **Last Modified:** 08/21/2025 17:45:27

**Functions:**
- `Get-NotificationState` (Line 69, 56 lines) - `Set-NotificationState` (Line 127, 57 lines) - `Update-NotificationMetrics` (Line 186, 29 lines) 
### Unity-Claude-NotificationIntegration

- **Path:** `Modules\Unity-Claude-NotificationIntegration\Unity-Claude-NotificationIntegration.psm1`
- **Size:** 47.5 KB
- **Functions:** 20
- **Lines:** 1374
- **Last Modified:** 08/30/2025 14:29:46

**Functions:**
- `Get-DeliveryChannelsForAlert` (Line 259, 45 lines) - `Get-NotificationQueueStatus` (Line 1266, 17 lines) - `Get-NotificationQueueStatus` (Line 1114, 17 lines) - `Initialize-NotificationIntegration` (Line 836, 63 lines) - `New-NotificationContent` (Line 306, 92 lines) - `Send-ChannelNotification` (Line 400, 69 lines) - `Send-ClaudeSubmissionNotification` (Line 938, 42 lines) - `Send-DashboardNotificationEnhanced` (Line 584, 57 lines) - `Send-EmailNotificationEnhanced` (Line 643, 45 lines) - `Send-IntegratedNotification` (Line 982, 58 lines) - `Send-NotificationMultiChannel` (Line 174, 83 lines) - `Send-SlackNotificationEnhanced` (Line 471, 57 lines) - `Send-SMSNotificationEnhanced` (Line 737, 37 lines) - `Send-TeamsNotificationEnhanced` (Line 530, 52 lines) - `Send-UnityErrorNotification` (Line 901, 35 lines) - `Send-WebhookNotificationEnhanced` (Line 690, 45 lines) - `Test-NotificationDeliveryMultiChannel` (Line 776, 57 lines) - `Test-NotificationIntegration` (Line 1133, 28 lines) - `Test-NotificationReliability` (Line 1163, 101 lines) - `Test-NotificationReliability` (Line 1042, 70 lines) 
### Unity-Claude-NotificationPreferences

- **Path:** `Modules\Unity-Claude-NotificationPreferences\Unity-Claude-NotificationPreferences.psm1`
- **Size:** 37.57 KB
- **Functions:** 24
- **Lines:** 1095
- **Last Modified:** 08/30/2025 14:35:17

**Functions:**
- `Add-AutoTags` (Line 678, 54 lines) - `Apply-TimeBasedRules` (Line 847, 63 lines) - `Create-DefaultUserPreferences` (Line 1071, 3 lines) - `Get-ChannelsFromRules` (Line 788, 57 lines) - `Get-DefaultDeliveryRules` (Line 306, 101 lines) - `Get-DefaultNotificationPreferences` (Line 230, 74 lines) - `Get-DefaultTagDefinitions` (Line 409, 46 lines) - `Get-DeliveryChannelsForAlert` (Line 608, 68 lines) - `Get-NotificationPreferencesForUser` (Line 489, 54 lines) - `Get-NotificationPreferencesStatistics` (Line 1026, 21 lines) - `Initialize-NotificationPreferences` (Line 54, 69 lines) - `Initialize-RuleEngine` (Line 457, 30 lines) - `Load-DeliveryRules` (Line 160, 33 lines) - `Load-NotificationPreferences` (Line 125, 33 lines) - `Load-TagDefinitions` (Line 195, 33 lines) - `Merge-UserPreferences` (Line 1081, 3 lines) - `Save-DeliveryRules` (Line 1057, 5 lines) - `Save-NotificationPreferences` (Line 1050, 5 lines) - `Save-TagDefinitions` (Line 1064, 5 lines) - `Set-NotificationPreferencesForUser` (Line 545, 61 lines) - `Test-NotificationPreferences` (Line 957, 67 lines) - `Test-RuleConditions` (Line 734, 52 lines) - `Test-TimeInRange` (Line 912, 43 lines) - `Test-UserPreferencesConfiguration` (Line 1076, 3 lines) 
### Unity-Claude-ObsolescenceDetection-Refactored

- **Path:** `Modules\Unity-Claude-CPG\Unity-Claude-ObsolescenceDetection-Refactored.psm1`
- **Size:** 22.22 KB
- **Functions:** 5
- **Lines:** 584
- **Last Modified:** 08/26/2025 11:46:18

**Functions:**
- `Generate-AnalysisSummary` (Line 432, 35 lines) - `Generate-ObsolescenceActionPlan` (Line 469, 37 lines) - `Get-ObsolescenceDetectionComponents` (Line 134, 51 lines) - `Invoke-ComprehensiveObsolescenceAnalysis` (Line 308, 122 lines) - `Test-ObsolescenceDetectionHealth` (Line 187, 119 lines) 
### Unity-Claude-ObsolescenceDetection

- **Path:** `Modules\Unity-Claude-CPG\Unity-Claude-ObsolescenceDetection.psm1`
- **Size:** 22.22 KB
- **Functions:** 5
- **Lines:** 584
- **Last Modified:** 08/26/2025 11:46:18

**Functions:**
- `Generate-AnalysisSummary` (Line 432, 35 lines) - `Generate-ObsolescenceActionPlan` (Line 469, 37 lines) - `Get-ObsolescenceDetectionComponents` (Line 134, 51 lines) - `Invoke-ComprehensiveObsolescenceAnalysis` (Line 308, 122 lines) - `Test-ObsolescenceDetectionHealth` (Line 187, 119 lines) 
### Unity-Claude-Ollama-Enhanced

- **Path:** `Modules\Unity-Claude-AI-Integration\Ollama\Unity-Claude-Ollama-Enhanced.psm1`
- **Size:** 26.84 KB
- **Functions:** 13
- **Lines:** 826
- **Last Modified:** 08/30/2025 19:47:36

**Functions:**
- `Add-DocumentationRequest` (Line 235, 61 lines) - `Get-DocumentationPrompt` (Line 725, 28 lines) - `Get-DocumentationQualityAssessment` (Line 298, 76 lines) - `Get-RealTimeAnalysisStatus` (Line 579, 46 lines) - `Initialize-PowershAI` (Line 42, 62 lines) - `Invoke-OllamaDirectDocumentation` (Line 787, 16 lines) - `Invoke-OllamaGeneration` (Line 755, 30 lines) - `Invoke-PowershAIDocumentation` (Line 106, 64 lines) - `Optimize-DocumentationWithAI` (Line 376, 68 lines) - `Start-BatchDocumentationProcessing` (Line 631, 88 lines) - `Start-IntelligentDocumentationPipeline` (Line 176, 57 lines) - `Start-RealTimeAIAnalysis` (Line 450, 81 lines) - `Stop-RealTimeAIAnalysis` (Line 533, 44 lines) 
### Unity-Claude-Ollama-Optimized-Fixed

- **Path:** `Modules\Unity-Claude-AI-Integration\Ollama\Unity-Claude-Ollama-Optimized-Fixed.psm1`
- **Size:** 35.32 KB
- **Functions:** 6
- **Lines:** 800
- **Last Modified:** 08/30/2025 19:47:36

**Functions:**
- `Format-OptimizedPrompt` (Line 562, 29 lines) - `Get-OllamaPerformanceReport` (Line 597, 147 lines) - `Get-OptimalContextWindow` (Line 90, 55 lines) - `Invoke-OllamaOptimizedRequest` (Line 478, 82 lines) - `Optimize-OllamaConfiguration` (Line 147, 87 lines) - `Start-OllamaBatchProcessing` (Line 240, 236 lines) 
### Unity-Claude-Ollama-Optimized

- **Path:** `Modules\Unity-Claude-AI-Integration\Ollama\Unity-Claude-Ollama-Optimized.psm1`
- **Size:** 27.37 KB
- **Functions:** 6
- **Lines:** 655
- **Last Modified:** 08/30/2025 19:47:36

**Functions:**
- `Format-OptimizedPrompt` (Line 453, 29 lines) - `Get-OllamaPerformanceReport` (Line 488, 127 lines) - `Get-OptimalContextWindow` (Line 89, 55 lines) - `Invoke-OllamaOptimizedRequest` (Line 369, 82 lines) - `Optimize-OllamaConfiguration` (Line 146, 64 lines) - `Start-OllamaBatchProcessing` (Line 216, 151 lines) 
### Unity-Claude-Ollama

- **Path:** `Modules\Unity-Claude-AI-Integration\Ollama\Unity-Claude-Ollama.psm1`
- **Size:** 34.17 KB
- **Functions:** 13
- **Lines:** 970
- **Last Modified:** 08/30/2025 19:47:36

**Functions:**
- `Export-OllamaConfiguration` (Line 904, 39 lines) - `Format-DocumentationPrompt` (Line 609, 108 lines) - `Get-OllamaModelInfo` (Line 218, 53 lines) - `Get-OllamaPerformanceMetrics` (Line 879, 23 lines) - `Invoke-OllamaCodeAnalysis` (Line 406, 62 lines) - `Invoke-OllamaDocumentation` (Line 321, 83 lines) - `Invoke-OllamaExplanation` (Line 470, 63 lines) - `Invoke-OllamaRetry` (Line 719, 158 lines) - `Set-OllamaConfiguration` (Line 273, 42 lines) - `Start-ModelPreloading` (Line 539, 68 lines) - `Start-OllamaService` (Line 42, 54 lines) - `Stop-OllamaService` (Line 98, 47 lines) - `Test-OllamaConnectivity` (Line 147, 65 lines) 
### Unity-Claude-ParallelProcessing

- **Path:** `Modules\Unity-Claude-ParallelProcessing\Unity-Claude-ParallelProcessing.psm1`
- **Size:** 40.62 KB
- **Functions:** 18
- **Lines:** 1150
- **Last Modified:** 08/21/2025 17:45:27

**Functions:**
- `Clear-ParallelStatus` (Line 568, 46 lines) - `Get-ParallelStatus` (Line 395, 53 lines) - `Get-SynchronizedValue` (Line 108, 39 lines) - `Get-ThreadSafetyStats` (Line 877, 12 lines) - `Initialize-ConcurrentLogging` (Line 918, 59 lines) - `Initialize-ParallelStatusManager` (Line 331, 49 lines) - `Invoke-ThreadSafeOperation` (Line 634, 49 lines) - `Lock-SynchronizedHashtable` (Line 274, 17 lines) - `New-SynchronizedHashtable` (Line 62, 30 lines) - `Remove-SynchronizedValue` (Line 219, 42 lines) - `Set-ParallelStatus` (Line 464, 41 lines) - `Set-SynchronizedValue` (Line 165, 40 lines) - `Stop-ConcurrentLogging` (Line 1038, 31 lines) - `Test-ThreadSafety` (Line 697, 170 lines) - `Unlock-SynchronizedHashtable` (Line 303, 10 lines) - `Update-ParallelStatus` (Line 519, 36 lines) - `Write-AgentLog` (Line 9, 16 lines) - `Write-ConcurrentLog` (Line 999, 26 lines) 
### Unity-Claude-ParallelProcessor-Original

- **Path:** `Modules\Unity-Claude-ParallelProcessor\Unity-Claude-ParallelProcessor-Original.psm1`
- **Size:** 32.43 KB
- **Functions:** 35
- **Lines:** 923
- **Last Modified:** 08/26/2025 12:30:44

**Functions:**
- `AddItems` (Line 650, 7 lines, 1 params) - `BatchProcessor` (Line 538, 30 lines, 3 params) - `CalculateOptimalThreads` (Line 98, 13 lines) - `CancelAllJobs` (Line 378, 8 lines) - `CancelJob` (Line 360, 15 lines, 1 params) - `CollectJobResult` (Line 284, 45 lines, 1 params) - `CompleteAdding` (Line 660, 3 lines) - `CreateRunspacePool` (Line 114, 28 lines) - `Dispose` (Line 725, 18 lines) - `Dispose` (Line 505, 18 lines) - `Get-JobStatus` (Line 866, 12 lines) - `Get-ParallelProcessorStatistics` (Line 855, 9 lines) - `GetJobStatus` (Line 488, 14 lines, 1 params) - `GetResults` (Line 666, 20 lines, 1 params) - `GetStatistics` (Line 710, 3 lines) - `GetStatistics` (Line 468, 17 lines) - `Initialize` (Line 53, 42 lines, 3 params) - `Invoke-ParallelProcessing` (Line 782, 32 lines) - `InvokeParallel` (Line 407, 26 lines, 3 params) - `New-ParallelProcessor` (Line 748, 32 lines) - `ParallelProcessor` (Line 41, 2 lines) - `ParallelProcessor` (Line 45, 2 lines, 2 params) - `ParallelProcessor` (Line 49, 2 lines, 3 params) - `RetryJob` (Line 332, 25 lines, 1 params) - `Start` (Line 571, 76 lines) - `Start-BatchProcessing` (Line 816, 37 lines) - `StartProducerConsumer` (Line 436, 29 lines, 3 params) - `Stop` (Line 716, 6 lines) - `SubmitJob` (Line 145, 47 lines, 2 params) - `SubmitJobs` (Line 195, 12 lines, 2 params) - `UpdateExecutionStatistics` (Line 389, 15 lines, 1 params) - `UpdateStatistics` (Line 700, 7 lines) - `WaitForAllJobs` (Line 240, 41 lines, 1 params) - `WaitForCompletion` (Line 689, 8 lines) - `WaitForJob` (Line 210, 27 lines, 2 params) 
### Unity-Claude-ParallelProcessor-Refactored

- **Path:** `Modules\Unity-Claude-ParallelProcessor\Unity-Claude-ParallelProcessor-Refactored.psm1`
- **Size:** 10.43 KB
- **Functions:** 1
- **Lines:** 251
- **Last Modified:** 08/26/2025 11:46:19

**Functions:**
- `Get-UnityClaudeParallelProcessorInfo` (Line 117, 10 lines) 
### Unity-Claude-ParallelProcessor

- **Path:** `Modules\Unity-Claude-ParallelProcessor\Unity-Claude-ParallelProcessor.psm1`
- **Size:** 10.43 KB
- **Functions:** 1
- **Lines:** 251
- **Last Modified:** 08/26/2025 11:46:19

**Functions:**
- `Get-UnityClaudeParallelProcessorInfo` (Line 117, 10 lines) 
### Unity-Claude-PerformanceOptimizer-Original

- **Path:** `Modules\Unity-Claude-PerformanceOptimizer\Unity-Claude-PerformanceOptimizer-Original.psm1`
- **Size:** 34.33 KB
- **Functions:** 34
- **Lines:** 922
- **Last Modified:** 08/26/2025 11:46:19

**Functions:**
- `AnalyzeBottlenecks` (Line 311, 24 lines) - `CalculateFilePriority` (Line 251, 6 lines, 1 params) - `CalculateOptimalThreadCount` (Line 129, 12 lines) - `Export-PerformanceReport` (Line 787, 89 lines) - `Get-PerformanceMetrics` (Line 703, 12 lines) - `Get-ThroughputMetrics` (Line 717, 12 lines) - `GetPerformanceMetrics` (Line 598, 2 lines) - `GetThroughputReport` (Line 602, 23 lines) - `HandleFileChange` (Line 237, 12 lines, 1 params) - `IncreaseBatchSize` (Line 356, 8 lines) - `InitializeComponents` (Line 94, 33 lines) - `New-PerformanceOptimizer` (Line 630, 41 lines) - `OptimizeCacheSettings` (Line 366, 11 lines) - `OptimizePerformance` (Line 337, 17 lines) - `PerformanceOptimizer` (Line 64, 28 lines, 1 params) - `ProcessCSharpFile` (Line 536, 8 lines, 1 params) - `ProcessFileChange` (Line 433, 54 lines, 1 params) - `ProcessFileInternal` (Line 489, 26 lines, 1 params) - `ProcessGenericFile` (Line 566, 7 lines, 1 params) - `ProcessingWorker` (Line 411, 20 lines) - `ProcessJavaScriptFile` (Line 556, 8 lines, 1 params) - `ProcessPowerShellFile` (Line 517, 17 lines, 1 params) - `ProcessPythonFile` (Line 546, 8 lines, 1 params) - `ReduceMemoryUsage` (Line 379, 12 lines) - `Start` (Line 143, 29 lines) - `Start-BatchProcessor` (Line 731, 54 lines) - `Start-OptimizedProcessing` (Line 673, 13 lines) - `StartFileWatcher` (Line 219, 16 lines) - `StartPerformanceMonitoring` (Line 259, 10 lines) - `StartProcessingWorkers` (Line 393, 16 lines) - `Stop` (Line 174, 43 lines) - `Stop-OptimizedProcessing` (Line 688, 13 lines) - `UpdateDependentFiles` (Line 575, 21 lines, 2 params) - `UpdatePerformanceMetrics` (Line 271, 38 lines) 
### Unity-Claude-PerformanceOptimizer-Refactored

- **Path:** `Modules\Unity-Claude-PerformanceOptimizer\Unity-Claude-PerformanceOptimizer-Refactored.psm1`
- **Size:** 19.43 KB
- **Functions:** 22
- **Lines:** 527
- **Last Modified:** 08/26/2025 11:46:19

**Functions:**
- `Export-PerformanceReport` (Line 422, 17 lines) - `Get-PerformanceMetrics` (Line 350, 8 lines) - `Get-PerformanceOptimizerComponents` (Line 442, 15 lines) - `Get-ThroughputMetrics` (Line 360, 8 lines) - `GetPerformanceMetrics` (Line 283, 2 lines) - `GetThroughputReport` (Line 287, 4 lines) - `InitializeComponents` (Line 65, 5 lines) - `New-PerformanceOptimizer` (Line 296, 30 lines) - `OptimizePerformance` (Line 193, 10 lines) - `PerformanceOptimizer` (Line 46, 17 lines, 1 params) - `ProcessFileChange` (Line 247, 34 lines, 1 params) - `ProcessingWorker` (Line 226, 19 lines) - `Start` (Line 72, 29 lines) - `Start-BatchProcessor` (Line 370, 50 lines) - `Start-OptimizedProcessing` (Line 328, 9 lines) - `StartFileWatcher` (Line 147, 13 lines) - `StartPerformanceMonitoring` (Line 162, 9 lines) - `StartProcessingWorkers` (Line 205, 19 lines) - `Stop` (Line 103, 42 lines) - `Stop-OptimizedProcessing` (Line 339, 9 lines) - `Test-PerformanceOptimizerHealth` (Line 459, 20 lines) - `UpdatePerformanceMetrics` (Line 173, 18 lines) 
### Unity-Claude-PerformanceOptimizer

- **Path:** `Modules\Unity-Claude-PerformanceOptimizer.psm1`
- **Size:** 27.63 KB
- **Functions:** 22
- **Lines:** 856
- **Last Modified:** 08/20/2025 17:25:22

**Functions:**
- `Clear-ExpiredCacheEntries` (Line 690, 20 lines) - `Clear-PerformanceCache` (Line 445, 40 lines) - `Get-CachedComputationResult` (Line 384, 39 lines) - `Get-CachedFileContent` (Line 300, 57 lines) - `Get-OptimizedRegex` (Line 491, 20 lines) - `Get-PerformanceReport` (Line 716, 33 lines) - `Get-PerfTimestamp` (Line 105, 2 lines) - `Invoke-OptimizedBatchProcessing` (Line 584, 53 lines) - `Invoke-OptimizedRegexMatch` (Line 513, 29 lines) - `Manage-CacheSize` (Line 425, 18 lines) - `Measure-OperationPerformance` (Line 192, 29 lines) - `New-PerformanceId` (Line 109, 2 lines) - `Optimize-JsonProcessing` (Line 544, 34 lines) - `Optimize-MemoryUsage` (Line 639, 49 lines) - `Read-FileDirectly` (Line 359, 23 lines) - `Record-Bottleneck` (Line 249, 20 lines) - `Save-ProfileData` (Line 271, 23 lines) - `Start-OperationProfile` (Line 117, 30 lines) - `Stop-OperationProfile` (Line 149, 41 lines) - `Test-PerformanceThresholds` (Line 751, 35 lines) - `Update-PerformanceMetrics` (Line 223, 24 lines) - `Write-PerfLog` (Line 73, 30 lines) 
### Unity-Claude-PerformanceOptimizer

- **Path:** `Modules\Unity-Claude-PerformanceOptimizer\Unity-Claude-PerformanceOptimizer.psm1`
- **Size:** 19.43 KB
- **Functions:** 22
- **Lines:** 527
- **Last Modified:** 08/26/2025 11:46:19

**Functions:**
- `Export-PerformanceReport` (Line 422, 17 lines) - `Get-PerformanceMetrics` (Line 350, 8 lines) - `Get-PerformanceOptimizerComponents` (Line 442, 15 lines) - `Get-ThroughputMetrics` (Line 360, 8 lines) - `GetPerformanceMetrics` (Line 283, 2 lines) - `GetThroughputReport` (Line 287, 4 lines) - `InitializeComponents` (Line 65, 5 lines) - `New-PerformanceOptimizer` (Line 296, 30 lines) - `OptimizePerformance` (Line 193, 10 lines) - `PerformanceOptimizer` (Line 46, 17 lines, 1 params) - `ProcessFileChange` (Line 247, 34 lines, 1 params) - `ProcessingWorker` (Line 226, 19 lines) - `Start` (Line 72, 29 lines) - `Start-BatchProcessor` (Line 370, 50 lines) - `Start-OptimizedProcessing` (Line 328, 9 lines) - `StartFileWatcher` (Line 147, 13 lines) - `StartPerformanceMonitoring` (Line 162, 9 lines) - `StartProcessingWorkers` (Line 205, 19 lines) - `Stop` (Line 103, 42 lines) - `Stop-OptimizedProcessing` (Line 339, 9 lines) - `Test-PerformanceOptimizerHealth` (Line 459, 20 lines) - `UpdatePerformanceMetrics` (Line 173, 18 lines) 
### Unity-Claude-PredictiveAnalysis-Original

- **Path:** `Modules\Unity-Claude-PredictiveAnalysis\Unity-Claude-PredictiveAnalysis-Original.psm1`
- **Size:** 74.37 KB
- **Functions:** 28
- **Lines:** 2095
- **Last Modified:** 08/25/2025 13:45:25

**Functions:**
- `Calculate-SmellScore` (Line 1796, 17 lines) - `Calculate-TechnicalDebt` (Line 475, 112 lines) - `Estimate-RefactoringEffort` (Line 1853, 46 lines) - `Export-RoadmapReport` (Line 1256, 158 lines) - `Find-AntiPatterns` (Line 1697, 45 lines) - `Find-GodClasses` (Line 721, 57 lines) - `Find-LongMethods` (Line 678, 41 lines) - `Find-RefactoringOpportunities` (Line 593, 83 lines) - `Get-AuthorContributions` (Line 1516, 47 lines) - `Get-CodeEvolutionTrend` (Line 73, 128 lines) - `Get-CommitFrequency` (Line 1487, 27 lines) - `Get-ComplexityTrend` (Line 2011, 41 lines) - `Get-CouplingIssues` (Line 1420, 65 lines) - `Get-DesignFlaws` (Line 1744, 50 lines) - `Get-DuplicationCandidates` (Line 780, 93 lines) - `Get-HistoricalMetrics` (Line 1951, 23 lines) - `Get-HotspotAnalysis` (Line 255, 74 lines) - `Get-MaintenancePrediction` (Line 335, 138 lines) - `Get-MaintenanceRisk` (Line 1647, 17 lines) - `Get-PriorityActions` (Line 1815, 36 lines) - `Get-ROIAnalysis` (Line 1901, 48 lines) - `Get-SmellProbability` (Line 1666, 29 lines) - `Initialize-PredictiveCache` (Line 17, 50 lines) - `Measure-CodeChurn` (Line 203, 50 lines) - `New-ImprovementRoadmap` (Line 1010, 244 lines) - `Predict-BugProbability` (Line 1565, 80 lines) - `Predict-CodeSmells` (Line 879, 125 lines) - `Update-PredictionModels` (Line 1976, 33 lines) 
### Unity-Claude-PredictiveAnalysis-Refactored

- **Path:** `Modules\Unity-Claude-PredictiveAnalysis\Unity-Claude-PredictiveAnalysis-Refactored.psm1`
- **Size:** 18.66 KB
- **Functions:** 4
- **Lines:** 494
- **Last Modified:** 08/26/2025 11:46:19

**Functions:**
- `Calculate-OverallRisk` (Line 278, 58 lines) - `Get-ComprehensiveAnalysis` (Line 171, 105 lines) - `Get-TopPriorities` (Line 338, 71 lines) - `Initialize-PredictiveAnalysis` (Line 92, 77 lines) 
### Unity-Claude-PredictiveAnalysis

- **Path:** `Modules\Unity-Claude-PredictiveAnalysis\Unity-Claude-PredictiveAnalysis.psm1`
- **Size:** 18.66 KB
- **Functions:** 4
- **Lines:** 494
- **Last Modified:** 08/26/2025 11:46:19

**Functions:**
- `Calculate-OverallRisk` (Line 278, 58 lines) - `Get-ComprehensiveAnalysis` (Line 171, 105 lines) - `Get-TopPriorities` (Line 338, 71 lines) - `Initialize-PredictiveAnalysis` (Line 92, 77 lines) 
### Unity-Claude-ProactiveMaintenanceEngine

- **Path:** `Modules\Unity-Claude-ProactiveMaintenanceEngine\Unity-Claude-ProactiveMaintenanceEngine.psm1`
- **Size:** 33.33 KB
- **Functions:** 22
- **Lines:** 964
- **Last Modified:** 08/30/2025 14:11:00

**Functions:**
- `Calculate-OverallHealthScore` (Line 732, 26 lines) - `Check-EarlyWarnings` (Line 633, 71 lines) - `Connect-MaintenanceModules` (Line 123, 75 lines) - `Create-Recommendation` (Line 529, 25 lines) - `Generate-ProactiveRecommendations` (Line 461, 66 lines) - `Get-MaintenanceWarnings` (Line 833, 17 lines) - `Get-ProactiveMaintenanceStatistics` (Line 937, 16 lines) - `Get-ProactiveRecommendations` (Line 816, 15 lines) - `Get-WarningSeverity` (Line 760, 21 lines) - `Initialize-EarlyWarningSystem` (Line 246, 36 lines) - `Initialize-ProactiveMaintenanceEngine` (Line 90, 31 lines) - `Initialize-RecommendationEngine` (Line 200, 25 lines) - `Initialize-TrendAnalyzer` (Line 227, 17 lines) - `Invoke-ProactiveAnalysis` (Line 410, 49 lines) - `Invoke-TestAnalysisCycle` (Line 869, 66 lines) - `Invoke-TrendAnalysis` (Line 706, 24 lines) - `Rank-Recommendations` (Line 556, 49 lines) - `Start-ProactiveMaintenanceEngine` (Line 284, 24 lines) - `Start-ProactiveMonitoringThread` (Line 310, 98 lines) - `Stop-ProactiveMaintenanceEngine` (Line 852, 15 lines) - `Trigger-MaintenanceAlert` (Line 783, 31 lines) - `Update-ActiveRecommendations` (Line 607, 24 lines) 
### Unity-Claude-RealTimeAnalysis

- **Path:** `Modules\Unity-Claude-RealTimeAnalysis\Unity-Claude-RealTimeAnalysis.psm1`
- **Size:** 22.22 KB
- **Functions:** 15
- **Lines:** 658
- **Last Modified:** 08/30/2025 12:38:30

**Functions:**
- `Add-FileChangeToAnalysisQueue` (Line 256, 22 lines) - `Create-VisualizationData` (Line 480, 18 lines) - `Discover-ExistingModules` (Line 99, 81 lines) - `Get-PipelineConfiguration` (Line 554, 5 lines) - `Get-RealTimeAnalysisStatistics` (Line 536, 16 lines) - `Initialize-RealTimeAnalysisPipeline` (Line 63, 34 lines) - `Process-AnalysisRequest` (Line 345, 89 lines) - `Set-PipelineConfiguration` (Line 561, 18 lines) - `Start-FileSystemMonitoringIntegration` (Line 224, 30 lines) - `Start-PipelineProcessingThread` (Line 280, 63 lines) - `Start-RealTimeAnalysisPipeline` (Line 182, 40 lines) - `Start-VisualizationThread` (Line 436, 42 lines) - `Stop-RealTimeAnalysisPipeline` (Line 500, 34 lines) - `Submit-TestAnalysisRequest` (Line 627, 19 lines) - `Test-PipelineHealth` (Line 581, 43 lines) 
### Unity-Claude-RealTimeMonitoring

- **Path:** `Modules\Unity-Claude-RealTimeMonitoring\Unity-Claude-RealTimeMonitoring.psm1`
- **Size:** 17.14 KB
- **Functions:** 12
- **Lines:** 527
- **Last Modified:** 08/30/2025 12:13:13

**Functions:**
- `Add-EventToQueue` (Line 229, 27 lines) - `Get-EventPriority` (Line 315, 28 lines) - `Get-MonitoringConfiguration` (Line 434, 5 lines) - `Get-MonitoringStatistics` (Line 417, 15 lines) - `Initialize-RealTimeMonitoring` (Line 42, 37 lines) - `Invoke-AutoRecovery` (Line 345, 30 lines) - `Register-FileSystemEventHandlers` (Line 169, 58 lines) - `Set-MonitoringConfiguration` (Line 441, 18 lines) - `Start-EventProcessingThread` (Line 258, 55 lines) - `Start-FileSystemMonitoring` (Line 81, 86 lines) - `Stop-FileSystemMonitoring` (Line 377, 38 lines) - `Test-MonitoringHealth` (Line 461, 55 lines) 
### Unity-Claude-RealTimeOptimizer

- **Path:** `Modules\Unity-Claude-RealTimeOptimizer\Unity-Claude-RealTimeOptimizer.psm1`
- **Size:** 26.14 KB
- **Functions:** 22
- **Lines:** 730
- **Last Modified:** 08/30/2025 13:10:46

**Functions:**
- `Disable-RTAdaptiveThrottling` (Line 500, 33 lines) - `Enable-RTAdaptiveThrottling` (Line 454, 27 lines) - `Enable-RTEmergencyThrottling` (Line 483, 15 lines) - `Get-RTCurrentCPUUsage` (Line 377, 21 lines) - `Get-RTCurrentMemoryUsage` (Line 400, 27 lines) - `Get-RTOptimalBatchSize` (Line 631, 27 lines) - `Get-RTPerformanceStatistics` (Line 670, 20 lines) - `Get-RTThrottledDelay` (Line 660, 8 lines) - `Get-SystemLoadLevel` (Line 429, 23 lines) - `Initialize-RealTimeOptimizer` (Line 76, 31 lines) - `Initialize-RTMemoryManager` (Line 192, 19 lines) - `Initialize-RTResourceMonitor` (Line 142, 32 lines) - `Initialize-RTThrottleController` (Line 176, 14 lines) - `Invoke-RTCacheCleanup` (Line 609, 20 lines) - `Invoke-RTEmergencyCleanup` (Line 581, 26 lines) - `Invoke-RTPeriodicCleanup` (Line 557, 22 lines) - `Optimize-RTBatchSize` (Line 535, 20 lines) - `Set-RTOptimizationMode` (Line 109, 31 lines) - `Start-RealTimeOptimization` (Line 213, 27 lines) - `Start-RTOptimizationThread` (Line 307, 68 lines) - `Start-RTResourceMonitoringThread` (Line 242, 63 lines) - `Stop-RealTimeOptimizer` (Line 692, 28 lines) 
### Unity-Claude-RecompileSignaling

- **Path:** `Modules\Unity-Claude-RecompileSignaling.psm1`
- **Size:** 11.62 KB
- **Functions:** 4
- **Lines:** 288
- **Last Modified:** 08/20/2025 17:25:22

**Functions:**
- `Process-RecompileSignal` (Line 86, 61 lines) - `Start-RecompileSignalMonitoring` (Line 153, 59 lines) - `Stop-RecompileSignalMonitoring` (Line 214, 27 lines) - `Switch-ToUnityWindow` (Line 30, 48 lines) 
### Unity-Claude-ReliabilityManager

- **Path:** `Modules\Unity-Claude-ReliabilityManager\Unity-Claude-ReliabilityManager.psm1`
- **Size:** 43.51 KB
- **Functions:** 20
- **Lines:** 1161
- **Last Modified:** 08/30/2025 20:35:08

**Functions:**
- `Execute-HealthCheck` (Line 606, 34 lines) - `Execute-RecoveryProcedure` (Line 1020, 54 lines) - `Get-DisasterRecoveryProcedures` (Line 1001, 17 lines) - `Get-IssueSeverity` (Line 845, 12 lines) - `Get-ReliabilityManagerStatus` (Line 1076, 72 lines) - `Initialize-BackupRecoverySystem` (Line 213, 63 lines) - `Initialize-FaultToleranceSystem` (Line 165, 46 lines) - `Initialize-GracefulDegradationSystem` (Line 352, 69 lines) - `Initialize-HealthMonitoringSystem` (Line 278, 72 lines) - `Initialize-ReliabilityManager` (Line 84, 79 lines) - `Initialize-SystemHealthTracking` (Line 423, 33 lines) - `Invoke-AutoRecovery` (Line 767, 76 lines) - `Invoke-DisasterRecovery` (Line 911, 88 lines) - `Invoke-SystemHealthCheck` (Line 481, 123 lines) - `Start-ContinuousReliabilityMonitoring` (Line 458, 21 lines) - `Test-ConnectivityHealth` (Line 739, 26 lines) - `Test-ModuleHealth` (Line 670, 26 lines) - `Test-ResourceHealth` (Line 698, 39 lines) - `Test-SystemHealth` (Line 642, 26 lines) - `Update-SystemHealth` (Line 859, 50 lines) 
### Unity-Claude-ReliableMonitoring

- **Path:** `Modules\Unity-Claude-ReliableMonitoring.psm1`
- **Size:** 16.66 KB
- **Functions:** 10
- **Lines:** 461
- **Last Modified:** 08/20/2025 17:25:22

**Functions:**
- `Get-ReliableMonitoringStatus` (Line 398, 18 lines) - `Process-UnityErrors` (Line 116, 49 lines) - `Read-SafeJsonFile` (Line 39, 36 lines) - `Start-FileWatcher` (Line 171, 48 lines) - `Start-PollingTimer` (Line 254, 38 lines) - `Start-ReliableUnityMonitoring` (Line 320, 58 lines) - `Stop-FileWatcher` (Line 221, 27 lines) - `Stop-PollingTimer` (Line 294, 20 lines) - `Stop-ReliableUnityMonitoring` (Line 380, 16 lines) - `Test-ErrorFileChanged` (Line 77, 33 lines) 
### Unity-Claude-RepoAnalyst

- **Path:** `Modules\Unity-Claude-RepoAnalyst\Unity-Claude-RepoAnalyst.psm1`
- **Size:** 13.83 KB
- **Functions:** 20
- **Lines:** 453
- **Last Modified:** 08/24/2025 12:06:11

**Functions:**
- `Get-AgentStatus` (Line 326, 0 lines) - `Get-CtagsIndex` (Line 319, 0 lines) - `Get-MCPServerStatus` (Line 254, 13 lines) - `Get-PowerShellAST` (Line 320, 0 lines) - `Get-PythonBridgeStatus` (Line 311, 5 lines) - `Initialize-RepoAnalyst` (Line 83, 24 lines) - `Initialize-RepoAnalystLogging` (Line 32, 12 lines) - `Invoke-DocGeneration` (Line 323, 0 lines) - `Invoke-MCPTool` (Line 324, 0 lines) - `Invoke-PythonScript` (Line 291, 18 lines) - `Invoke-RipgrepSearch` (Line 110, 48 lines) - `New-CodeGraph` (Line 161, 37 lines) - `New-DocumentationUpdate` (Line 321, 0 lines) - `Send-AgentMessage` (Line 327, 0 lines) - `Start-MCPServer` (Line 201, 31 lines) - `Start-PythonBridge` (Line 270, 19 lines) - `Start-RepoAnalystAgent` (Line 325, 0 lines) - `Stop-MCPServer` (Line 234, 18 lines) - `Test-DocumentationDrift` (Line 322, 0 lines) - `Write-RepoAnalystLog` (Line 47, 33 lines) 
### Unity-Claude-ResourceOptimizer

- **Path:** `Modules\Unity-Claude-ResourceOptimizer.psm1`
- **Size:** 33.53 KB
- **Functions:** 12
- **Lines:** 904
- **Last Modified:** 08/20/2025 17:25:22

**Functions:**
- `ConvertTo-HumanReadableSize` (Line 127, 13 lines) - `Get-MemoryUsage` (Line 146, 39 lines) - `Get-ResourceTimestamp` (Line 123, 2 lines) - `Invoke-ComprehensiveResourceCheck` (Line 678, 105 lines) - `Invoke-EmergencyCleanup` (Line 560, 51 lines) - `Invoke-GarbageCollection` (Line 265, 52 lines) - `Invoke-LogRotation` (Line 323, 120 lines) - `Invoke-MemoryMonitoring` (Line 187, 76 lines) - `Invoke-ResourceAlert` (Line 617, 55 lines) - `Invoke-SessionCleanup` (Line 449, 109 lines) - `Start-AutomaticResourceOptimization` (Line 785, 52 lines) - `Write-ResourceLog` (Line 91, 30 lines) 
### Unity-Claude-ResponseMonitor

- **Path:** `Modules\Unity-Claude-ResponseMonitor\Unity-Claude-ResponseMonitor.psm1`
- **Size:** 28.94 KB
- **Functions:** 24
- **Lines:** 837
- **Last Modified:** 08/20/2025 17:25:21

**Functions:**
- `Add-PendingContinuation` (Line 596, 9 lines) - `Add-PendingExecution` (Line 607, 9 lines) - `Add-PendingRecommendation` (Line 574, 9 lines) - `Add-PendingTest` (Line 585, 9 lines) - `Clear-ResponseQueue` (Line 630, 7 lines) - `Get-ActionableItems` (Line 418, 43 lines) - `Get-MonitoringStatus` (Line 717, 11 lines) - `Get-ResponseMonitorConfig` (Line 92, 6 lines) - `Get-ResponseQueue` (Line 618, 10 lines) - `Initialize-FileSystemWatcher` (Line 162, 55 lines) - `Invoke-AutonomousResponseHandling` (Line 368, 48 lines) - `Invoke-ContinuationHandler` (Line 520, 23 lines) - `Invoke-DebouncedResponseHandler` (Line 245, 50 lines) - `Invoke-ExecutionHandler` (Line 545, 23 lines) - `Invoke-RecommendationHandler` (Line 467, 26 lines) - `Invoke-ResponseProcessing` (Line 301, 65 lines) - `Invoke-TestHandler` (Line 495, 23 lines) - `Set-ResponseMonitorConfig` (Line 100, 56 lines) - `Start-ClaudeResponseMonitoring` (Line 643, 39 lines) - `Stop-ClaudeResponseMonitoring` (Line 684, 31 lines) - `Stop-FileSystemWatcher` (Line 219, 24 lines) - `Test-RequiredModule` (Line 73, 13 lines) - `Test-ResponseMonitorIntegration` (Line 730, 55 lines) - `Write-ResponseMonitorLog` (Line 34, 37 lines) 
### Unity-Claude-ResponseMonitoring

- **Path:** `Modules\Unity-Claude-ResponseMonitoring.psm1`
- **Size:** 18 KB
- **Functions:** 11
- **Lines:** 492
- **Last Modified:** 08/20/2025 17:25:22

**Functions:**
- `Format-ResponseSummary` (Line 415, 30 lines) - `Get-ResponseMonitoringStatus` (Line 392, 17 lines) - `Process-ClaudeResponse` (Line 117, 52 lines) - `Read-SafeResponseFile` (Line 37, 41 lines) - `Start-ClaudeResponseMonitoring` (Line 318, 54 lines) - `Start-ResponseFileWatcher` (Line 175, 47 lines) - `Start-ResponsePollingTimer` (Line 253, 37 lines) - `Stop-ClaudeResponseMonitoring` (Line 374, 16 lines) - `Stop-ResponseFileWatcher` (Line 224, 27 lines) - `Stop-ResponsePollingTimer` (Line 292, 20 lines) - `Test-ResponseFileChanged` (Line 80, 31 lines) 
### Unity-Claude-RunspaceManagement-Original

- **Path:** `Modules\Unity-Claude-RunspaceManagement\Unity-Claude-RunspaceManagement-Original.psm1`
- **Size:** 75.97 KB
- **Functions:** 30
- **Lines:** 1950
- **Last Modified:** 08/26/2025 11:46:19

**Functions:**
- `Add-SessionStateModule` (Line 247, 39 lines) - `Add-SessionStateVariable` (Line 304, 38 lines) - `Add-SharedVariable` (Line 684, 40 lines) - `Close-RunspacePool` (Line 941, 46 lines) - `Get-RunspaceJobResults` (Line 1559, 55 lines) - `Get-RunspacePoolStatus` (Line 999, 43 lines) - `Get-SessionStateModules` (Line 541, 25 lines) - `Get-SessionStateVariables` (Line 578, 39 lines) - `Get-SharedVariable` (Line 737, 15 lines) - `Import-SessionStateModules` (Line 413, 51 lines) - `Initialize-SessionStateVariables` (Line 478, 51 lines) - `Invoke-RunspacePoolCleanup` (Line 1802, 65 lines) - `New-ManagedRunspacePool` (Line 833, 48 lines) - `New-ProductionRunspacePool` (Line 1134, 80 lines) - `New-RunspaceSessionState` (Line 123, 71 lines) - `New-SessionStateVariableEntry` (Line 639, 25 lines) - `Open-RunspacePool` (Line 893, 34 lines) - `Remove-SharedVariable` (Line 797, 14 lines) - `Set-AdaptiveThrottling` (Line 1729, 59 lines) - `Set-SessionStateConfiguration` (Line 206, 25 lines) - `Set-SharedVariable` (Line 767, 18 lines) - `Submit-RunspaceJob` (Line 1236, 72 lines) - `Test-ModuleDependencyAvailability` (Line 7, 20 lines) - `Test-RunspacePoolHealth` (Line 1054, 56 lines) - `Test-RunspacePoolResources` (Line 1630, 83 lines) - `Test-SessionStateConfiguration` (Line 354, 41 lines) - `Update-RunspaceJobStatus` (Line 1322, 144 lines) - `Wait-RunspaceJobs` (Line 1484, 61 lines) - `Write-FallbackLog` (Line 53, 16 lines) - `Write-ModuleLog` (Line 72, 12 lines) 
### Unity-Claude-RunspaceManagement-Refactored

- **Path:** `Modules\Unity-Claude-RunspaceManagement\Unity-Claude-RunspaceManagement-Refactored.psm1`
- **Size:** 10.91 KB
- **Functions:** 3
- **Lines:** 309
- **Last Modified:** 08/26/2025 11:46:19

**Functions:**
- `Get-RunspaceManagementStatus` (Line 110, 36 lines) - `Initialize-RunspaceManagement` (Line 63, 45 lines) - `Stop-RunspaceManagement` (Line 148, 55 lines) 
### Unity-Claude-RunspaceManagement

- **Path:** `Modules\Unity-Claude-RunspaceManagement\Unity-Claude-RunspaceManagement.psm1`
- **Size:** 10.91 KB
- **Functions:** 3
- **Lines:** 309
- **Last Modified:** 08/26/2025 11:46:19

**Functions:**
- `Get-RunspaceManagementStatus` (Line 110, 36 lines) - `Initialize-RunspaceManagement` (Line 63, 45 lines) - `Stop-RunspaceManagement` (Line 148, 55 lines) 
### Unity-Claude-Safety

- **Path:** `Modules\Unity-Claude-Safety\Unity-Claude-Safety.psm1`
- **Size:** 23.95 KB
- **Functions:** 9
- **Lines:** 701
- **Last Modified:** 08/20/2025 17:25:21

**Functions:**
- `Add-SafetyLog` (Line 489, 28 lines) - `Get-SafetyConfiguration` (Line 454, 10 lines) - `Initialize-SafetyFramework` (Line 27, 53 lines) - `Invoke-DryRun` (Line 263, 135 lines) - `Invoke-SafeFixApplication` (Line 519, 130 lines) - `Invoke-SafetyBackup` (Line 206, 55 lines) - `Set-SafetyConfiguration` (Line 400, 52 lines) - `Test-CriticalFile` (Line 466, 21 lines) - `Test-FixSafety` (Line 82, 122 lines) 
### Unity-Claude-ScalabilityEnhancements-Original

- **Path:** `Modules\Unity-Claude-ScalabilityEnhancements\Unity-Claude-ScalabilityEnhancements-Original.psm1`
- **Size:** 48.16 KB
- **Functions:** 70
- **Lines:** 1582
- **Last Modified:** 08/26/2025 11:46:19

**Functions:**
- `Add-JobToQueue` (Line 684, 27 lines) - `AddJob` (Line 544, 17 lines, 3 params) - `AssessScalabilityReadiness` (Line 1339, 47 lines, 1 params) - `BackgroundJobQueue` (Line 534, 8 lines, 1 params) - `CalculateGraphSize` (Line 145, 5 lines, 1 params) - `Cancel` (Line 920, 2 lines) - `Cancel-Operation` (Line 1020, 15 lines) - `Compress-GraphData` (Line 258, 36 lines) - `CompressGraphData` (Line 118, 25 lines, 1 params) - `CreatePartitionPlan` (Line 1304, 33 lines, 1 params) - `ExecuteJob` (Line 597, 34 lines, 1 params) - `Export-PagedData` (Line 482, 37 lines) - `Export-ScalabilityMetrics` (Line 1443, 49 lines) - `Force-GarbageCollection` (Line 1202, 24 lines) - `Get-JobResults` (Line 764, 25 lines) - `Get-MemoryUsageReport` (Line 1184, 16 lines) - `Get-PaginatedResults` (Line 405, 23 lines) - `Get-ProgressReport` (Line 969, 14 lines) - `Get-PruningReport` (Line 296, 17 lines) - `Get-QueueStatus` (Line 747, 15 lines) - `GetMemoryUsageReport` (Line 1105, 17 lines) - `GetNextPage` (Line 367, 5 lines) - `GetPage` (Line 336, 18 lines, 1 params) - `GetPageInfo` (Line 356, 9 lines) - `GetPreviousPage` (Line 374, 5 lines) - `GetProgressReport` (Line 902, 12 lines) - `GetQueueStatus` (Line 650, 15 lines) - `GraphPruner` (Line 16, 11 lines, 1 params) - `HandleMemoryPressure` (Line 1143, 4 lines) - `Invoke-JobPriorityUpdate` (Line 818, 26 lines) - `IsCancellationRequested` (Line 924, 2 lines) - `MarkPreservedNodes` (Line 67, 9 lines, 2 params) - `MemoryManager` (Line 1066, 10 lines, 1 params) - `Monitor-MemoryPressure` (Line 1255, 28 lines) - `Navigate-ResultPages` (Line 455, 25 lines) - `New-BackgroundJobQueue` (Line 668, 14 lines) - `New-CancellationToken` (Line 985, 23 lines) - `New-PaginationProvider` (Line 382, 21 lines) - `New-ProgressTracker` (Line 929, 18 lines) - `New-ScalingConfiguration` (Line 1389, 23 lines) - `Optimize-GraphStructure` (Line 214, 42 lines) - `Optimize-ObjectLifecycles` (Line 1228, 25 lines) - `OptimizeMemory` (Line 1124, 17 lines) - `PaginationProvider` (Line 327, 7 lines, 2 params) - `Prepare-DistributedMode` (Line 1494, 47 lines) - `ProcessJobs` (Line 579, 16 lines) - `ProgressTracker` (Line 860, 13 lines, 2 params) - `PruneGraph` (Line 29, 36 lines, 2 params) - `Register-ProgressCallback` (Line 1037, 18 lines) - `RegisterCallback` (Line 916, 2 lines, 1 params) - `RegisterManagedObject` (Line 1156, 3 lines, 1 params) - `Remove-CompletedJobs` (Line 791, 25 lines) - `Remove-UnusedNodes` (Line 182, 30 lines) - `RemoveOrphanedEdges` (Line 100, 16 lines, 1 params) - `RemoveUnusedNodes` (Line 78, 20 lines, 1 params) - `ScalingConfiguration` (Line 1296, 6 lines, 1 params) - `Set-PageSize` (Line 430, 23 lines) - `ShouldOptimize` (Line 1149, 5 lines) - `Start-GraphPruning` (Line 153, 27 lines) - `Start-MemoryOptimization` (Line 1162, 20 lines) - `Start-QueueProcessor` (Line 713, 15 lines) - `StartMonitoring` (Line 1078, 12 lines) - `StartProcessing` (Line 563, 14 lines) - `Stop-QueueProcessor` (Line 730, 15 lines) - `StopProcessing` (Line 633, 15 lines) - `Test-CancellationRequested` (Line 1010, 8 lines) - `Test-HorizontalReadiness` (Line 1414, 27 lines) - `Update-OperationProgress` (Line 949, 18 lines) - `UpdateMemoryStatistics` (Line 1092, 11 lines) - `UpdateProgress` (Line 875, 25 lines, 1 params) 
### Unity-Claude-ScalabilityEnhancements-Refactored

- **Path:** `Modules\Unity-Claude-ScalabilityEnhancements\Unity-Claude-ScalabilityEnhancements-Refactored.psm1`
- **Size:** 16.67 KB
- **Functions:** 4
- **Lines:** 428
- **Last Modified:** 08/26/2025 11:46:19

**Functions:**
- `Get-ScalabilityInfo` (Line 200, 66 lines) - `Initialize-ScalabilityEnhancements` (Line 26, 86 lines) - `Test-ScalabilityComponents` (Line 114, 84 lines) - `Update-ScalabilityStatistics` (Line 268, 64 lines) 
### Unity-Claude-ScalabilityEnhancements

- **Path:** `Modules\Unity-Claude-ScalabilityEnhancements\Unity-Claude-ScalabilityEnhancements.psm1`
- **Size:** 16.67 KB
- **Functions:** 4
- **Lines:** 428
- **Last Modified:** 08/26/2025 11:46:19

**Functions:**
- `Get-ScalabilityInfo` (Line 200, 66 lines) - `Initialize-ScalabilityEnhancements` (Line 26, 86 lines) - `Test-ScalabilityComponents` (Line 114, 84 lines) - `Update-ScalabilityStatistics` (Line 268, 64 lines) 
### Unity-Claude-ScalabilityOptimizer

- **Path:** `Modules\Unity-Claude-ScalabilityOptimizer\Unity-Claude-ScalabilityOptimizer.psm1`
- **Size:** 37.82 KB
- **Functions:** 17
- **Lines:** 1007
- **Last Modified:** 08/30/2025 20:31:03

**Functions:**
- `Apply-DistributedProcessingScaling` (Line 871, 55 lines) - `Apply-ScalingDecision` (Line 827, 42 lines) - `Calculate-BenchmarkAverages` (Line 541, 22 lines) - `Calculate-BenchmarkSummary` (Line 565, 35 lines) - `Evaluate-ScalingPolicy` (Line 759, 41 lines) - `Execute-BenchmarkIteration` (Line 475, 64 lines) - `Get-CurrentPerformanceMetrics` (Line 727, 30 lines) - `Get-ScalabilityOptimizerStatus` (Line 928, 66 lines) - `Initialize-DistributedProcessing` (Line 289, 51 lines) - `Initialize-PerformanceBenchmarking` (Line 255, 32 lines) - `Initialize-ScalabilityOptimizer` (Line 72, 89 lines) - `Initialize-ScalingPolicies` (Line 163, 90 lines) - `Invoke-AutoScaling` (Line 645, 80 lines) - `Invoke-PerformanceBenchmark` (Line 369, 104 lines) - `Select-PrimaryScalingDecision` (Line 802, 23 lines) - `Start-PerformanceMonitoring` (Line 342, 25 lines) - `Update-PerformanceMetrics` (Line 602, 41 lines) 
### Unity-Claude-SemanticAnalysis-Architecture

- **Path:** `Modules\Unity-Claude-CPG\Unity-Claude-SemanticAnalysis-Architecture.psm1`
- **Size:** 13.45 KB
- **Functions:** 5
- **Lines:** 388
- **Last Modified:** 08/25/2025 02:21:49

**Functions:**
- `Analyze-ComponentRelationships` (Line 299, 43 lines) - `Analyze-ModuleDependencies` (Line 157, 59 lines) - `Find-ArchitecturalPatterns` (Line 218, 79 lines) - `Identify-SystemLayers` (Line 101, 54 lines) - `Recover-Architecture` (Line 7, 92 lines) 
### Unity-Claude-SemanticAnalysis-Business

- **Path:** `Modules\Unity-Claude-CPG\Unity-Claude-SemanticAnalysis-Business.psm1`
- **Size:** 15.91 KB
- **Functions:** 5
- **Lines:** 455
- **Last Modified:** 08/25/2025 02:21:50

**Functions:**
- `Extract-BusinessLogic` (Line 7, 97 lines) - `Find-BusinessRules` (Line 186, 77 lines) - `Find-DomainCalculations` (Line 338, 71 lines) - `Find-ValidationRules` (Line 106, 78 lines) - `Find-WorkflowPatterns` (Line 265, 71 lines) 
### Unity-Claude-SemanticAnalysis-Helpers

- **Path:** `Modules\Unity-Claude-CPG\Unity-Claude-SemanticAnalysis-Helpers.psm1`
- **Size:** 20.93 KB
- **Functions:** 13
- **Lines:** 601
- **Last Modified:** 08/25/2025 02:21:50

**Functions:**
- `Canonicalize-PatternTypes` (Line 548, 14 lines) - `Clamp01` (Line 539, 7 lines) - `Classify-CallablePurpose` (Line 404, 61 lines) - `Classify-ClassPurpose` (Line 467, 53 lines) - `Ensure-Array` (Line 162, 16 lines) - `Ensure-Array` (Line 532, 5 lines) - `Ensure-GraphDuckType` (Line 68, 92 lines) - `Ensure-GraphDuckType` (Line 317, 13 lines) - `Get-CacheKey` (Line 248, 34 lines) - `Get-CacheKey` (Line 302, 13 lines) - `Normalize-AnalysisRecord` (Line 180, 66 lines) - `Normalize-AnalysisRecord` (Line 332, 70 lines) - `Test-IsCPGraph` (Line 42, 24 lines) 
### Unity-Claude-SemanticAnalysis-Metrics

- **Path:** `Modules\Unity-Claude-CPG\Unity-Claude-SemanticAnalysis-Metrics.psm1`
- **Size:** 13.13 KB
- **Functions:** 5
- **Lines:** 401
- **Last Modified:** 08/25/2025 02:21:50

**Functions:**
- `Calculate-ModuleCohesion` (Line 119, 100 lines) - `Calculate-SemanticCohesion` (Line 221, 62 lines) - `Get-CohesionMetrics` (Line 7, 110 lines) - `Get-CohesionRecommendations` (Line 285, 43 lines) - `Get-ComplexityMetrics` (Line 330, 25 lines) 
### Unity-Claude-SemanticAnalysis-New

- **Path:** `Modules\Unity-Claude-CPG\Unity-Claude-SemanticAnalysis-New.psm1`
- **Size:** 8.38 KB
- **Functions:** 1
- **Lines:** 234
- **Last Modified:** 08/25/2025 02:21:50

**Functions:**
- `ConvertTo-CPGFromScriptBlock` (Line 99, 37 lines) 
### Unity-Claude-SemanticAnalysis-Old

- **Path:** `Modules\Unity-Claude-CPG\Unity-Claude-SemanticAnalysis-Old.psm1`
- **Size:** 8.38 KB
- **Functions:** 1
- **Lines:** 234
- **Last Modified:** 08/25/2025 02:21:50

**Functions:**
- `ConvertTo-CPGFromScriptBlock` (Line 99, 37 lines) 
### Unity-Claude-SemanticAnalysis-Patterns

- **Path:** `Modules\Unity-Claude-CPG\Unity-Claude-SemanticAnalysis-Patterns.psm1`
- **Size:** 19.41 KB
- **Functions:** 8
- **Lines:** 517
- **Last Modified:** 08/25/2025 02:21:50

**Functions:**
- `Canonicalize-PatternTypes` (Line 7, 26 lines) - `Find-CommandPattern` (Line 442, 12 lines) - `Find-DecoratorPattern` (Line 456, 12 lines) - `Find-DesignPatterns` (Line 35, 148 lines) - `Find-FactoryPattern` (Line 291, 77 lines) - `Find-ObserverPattern` (Line 370, 56 lines) - `Find-SingletonPattern` (Line 185, 104 lines) - `Find-StrategyPattern` (Line 428, 12 lines) 
### Unity-Claude-SemanticAnalysis-Purpose

- **Path:** `Modules\Unity-Claude-CPG\Unity-Claude-SemanticAnalysis-Purpose.psm1`
- **Size:** 14.99 KB
- **Functions:** 3
- **Lines:** 406
- **Last Modified:** 08/25/2025 02:21:50

**Functions:**
- `Classify-CallablePurpose` (Line 145, 111 lines) - `Classify-ClassPurpose` (Line 258, 103 lines) - `Get-CodePurpose` (Line 7, 136 lines) 
### Unity-Claude-SemanticAnalysis-Quality

- **Path:** `Modules\Unity-Claude-CPG\Unity-Claude-SemanticAnalysis-Quality.psm1`
- **Size:** 21.63 KB
- **Functions:** 8
- **Lines:** 685
- **Last Modified:** 08/25/2025 02:21:50

**Functions:**
- `Analyze-ClassDocumentation` (Line 209, 107 lines) - `Analyze-FunctionDocumentation` (Line 103, 104 lines) - `Get-TechnicalDebt` (Line 546, 39 lines) - `New-QualityReport` (Line 587, 52 lines) - `Test-CommentCodeAlignment` (Line 510, 34 lines) - `Test-DocumentationCompleteness` (Line 7, 94 lines) - `Test-NamingConventions` (Line 318, 67 lines) - `Test-NodeNaming` (Line 387, 121 lines) 
### Unity-Claude-SemanticAnalysis

- **Path:** `Modules\Unity-Claude-CPG\Unity-Claude-SemanticAnalysis.psm1`
- **Size:** 8.38 KB
- **Functions:** 1
- **Lines:** 234
- **Last Modified:** 08/25/2025 02:21:50

**Functions:**
- `ConvertTo-CPGFromScriptBlock` (Line 99, 37 lines) 
### Unity-Claude-SemanticAnalysis

- **Path:** `Unity-Claude-SemanticAnalysis.psm1`
- **Size:** 140 KB
- **Functions:** 51
- **Lines:** 3680
- **Last Modified:** 08/24/2025 23:24:25

**Functions:**
- `Clamp01` (Line 1412, 5 lines) - `Ensure-GraphDuckType` (Line 41, 128 lines) - `Extract-BusinessLogic` (Line 1562, 131 lines) - `Find-CommandPattern` (Line 817, 76 lines) - `Find-DecoratorPattern` (Line 895, 88 lines) - `Find-DesignPatterns` (Line 226, 141 lines) - `Find-FactoryPattern` (Line 514, 131 lines) - `Find-ObserverPattern` (Line 647, 86 lines) - `Find-SingletonPattern` (Line 369, 143 lines) - `Find-StrategyPattern` (Line 735, 80 lines) - `Get-ArchitecturalComponents` (Line 1959, 39 lines) - `Get-ArchitecturalLayers` (Line 1913, 44 lines) - `Get-ArchitecturalPatterns` (Line 2029, 50 lines) - `Get-BusinessLogicFromComments` (Line 1695, 55 lines) - `Get-BusinessLogicFromConditionals` (Line 1752, 51 lines) - `Get-ClassDocumentationScore` (Line 2273, 50 lines) - `Get-ClassTechnicalDebt` (Line 3041, 44 lines) - `Get-CodePurpose` (Line 1006, 253 lines) - `Get-CodeSmells` (Line 3128, 25 lines) - `Get-CohesionMetrics` (Line 1265, 145 lines) - `Get-CommentCodeAlignmentScore` (Line 2709, 67 lines) - `Get-CompletenessLevel` (Line 2361, 11 lines) - `Get-ComponentCohesion` (Line 2000, 27 lines) - `Get-DebtScoreForLevel` (Line 3100, 12 lines) - `Get-FunctionDocumentationScore` (Line 2205, 66 lines) - `Get-FunctionInteractionCohesion` (Line 1419, 38 lines) - `Get-FunctionInteractionMatrix` (Line 1519, 18 lines) - `Get-FunctionTechnicalDebt` (Line 2953, 86 lines) - `Get-HigherLevel` (Line 3114, 12 lines) - `Get-MaintainabilityIndex` (Line 3155, 16 lines) - `Get-ModuleDocumentationScore` (Line 2325, 34 lines) - `Get-NamingSuggestion` (Line 2580, 41 lines) - `Get-QualityRating` (Line 3436, 11 lines) - `Get-QualityRecommendations` (Line 3449, 32 lines) - `Get-QualityReportSummary` (Line 3388, 46 lines) - `Get-SemanticCohesion` (Line 1459, 33 lines) - `Get-SemanticSimilarityMatrix` (Line 1539, 17 lines) - `Get-SimplifiedComplexity` (Line 2778, 20 lines) - `Get-StringSimilarity` (Line 1494, 23 lines) - `Get-TechnicalDebt` (Line 2834, 117 lines) - `Get-ThresholdLevel` (Line 3087, 11 lines) - `New-CSVQualityReport` (Line 3618, 46 lines) - `New-HTMLQualityReport` (Line 3483, 133 lines) - `New-QualityReport` (Line 3173, 213 lines) - `Recover-Architecture` (Line 1805, 106 lines) - `Resolve-PurposeFromName` (Line 989, 15 lines) - `Test-CommentCodeAlignment` (Line 2623, 84 lines) - `Test-DocumentationCompleteness` (Line 2085, 118 lines) - `Test-IsCPGraph` (Line 25, 14 lines) - `Test-NamingConventions` (Line 2374, 204 lines) - `Test-SemanticAlignment` (Line 2800, 32 lines) 
### Unity-Claude-SessionManager

- **Path:** `Modules\Unity-Claude-SessionManager.psm1`
- **Size:** 26.48 KB
- **Functions:** 18
- **Lines:** 792
- **Last Modified:** 08/20/2025 17:25:22

**Functions:**
- `Add-ConversationHistoryEntry` (Line 275, 54 lines) - `Complete-ConversationSession` (Line 679, 42 lines) - `Get-ConversationHistoryForContext` (Line 331, 41 lines) - `Get-ConversationSession` (Line 184, 31 lines) - `Get-SessionAnalytics` (Line 596, 48 lines) - `Get-SessionTimestamp` (Line 96, 2 lines) - `Invoke-ConversationSummarization` (Line 374, 50 lines) - `New-ConversationSession` (Line 104, 78 lines) - `New-SessionBackup` (Line 661, 16 lines) - `New-SessionCheckpoint` (Line 430, 44 lines) - `New-SessionId` (Line 92, 2 lines) - `Restore-SessionFromCheckpoint` (Line 476, 43 lines) - `Resume-ConversationSession` (Line 521, 42 lines) - `Save-ConversationSession` (Line 217, 30 lines) - `Should-CreateBackup` (Line 650, 9 lines) - `Update-ConversationSession` (Line 249, 20 lines) - `Update-SessionMetrics` (Line 569, 25 lines) - `Write-SessionLog` (Line 60, 30 lines) 
### Unity-Claude-SlackIntegration

- **Path:** `Modules\Unity-Claude-SlackIntegration\Unity-Claude-SlackIntegration.psm1`
- **Size:** 18.86 KB
- **Functions:** 10
- **Lines:** 610
- **Last Modified:** 08/30/2025 14:31:14

**Functions:**
- `Create-SlackAlertAttachments` (Line 251, 68 lines) - `Format-SlackAlertMessage` (Line 203, 46 lines) - `Get-SlackIntegrationStatistics` (Line 524, 19 lines) - `Initialize-SlackIntegration` (Line 25, 90 lines) - `Send-SlackAlert` (Line 117, 84 lines) - `Send-SlackMessageViaPSSlack` (Line 321, 49 lines) - `Send-SlackMessageViaWebhook` (Line 372, 56 lines) - `Set-SlackConfiguration` (Line 545, 56 lines) - `Test-SlackIntegration` (Line 454, 68 lines) - `Wait-ForRateLimit` (Line 430, 22 lines) 
### Unity-Claude-SystemCoordinator

- **Path:** `Modules\Unity-Claude-SystemCoordinator\Unity-Claude-SystemCoordinator.psm1`
- **Size:** 40.22 KB
- **Functions:** 21
- **Lines:** 1103
- **Last Modified:** 08/30/2025 20:21:25

**Functions:**
- `Allocate-OperationResources` (Line 626, 31 lines) - `Execute-CoordinatedOperation` (Line 378, 94 lines) - `Get-EstimatedOperationDuration` (Line 509, 35 lines) - `Get-OperationResourceRequirements` (Line 474, 33 lines) - `Get-SystemCoordinatorStatus` (Line 828, 72 lines) - `Initialize-SystemCoordinator` (Line 76, 98 lines) - `Invoke-MonitoredExecution` (Line 677, 46 lines) - `Optimize-ModuleHealth` (Line 1037, 26 lines) - `Optimize-OperationQueue` (Line 1000, 35 lines) - `Optimize-ResourcePool` (Line 968, 30 lines) - `Optimize-SystemPerformance` (Line 902, 64 lines) - `Process-QueuedOperations` (Line 770, 31 lines) - `Register-AvailableModules` (Line 176, 66 lines) - `Release-OperationResources` (Line 659, 16 lines) - `Request-CoordinatedOperation` (Line 244, 132 lines) - `Start-BackgroundOptimization` (Line 803, 23 lines) - `Start-ResourceMonitoring` (Line 725, 16 lines) - `Stop-ResourceMonitoring` (Line 743, 25 lines) - `Test-OperationConflicts` (Line 546, 38 lines) - `Test-ResourceAvailability` (Line 586, 38 lines) - `Update-SystemHealthMetrics` (Line 1065, 25 lines) 
### Unity-Claude-SystemStatus.cleaned

- **Path:** `Backups\PS7Migration_20250822_162419\Unity-Claude-SystemStatus.cleaned.psm1`
- **Size:** 129.31 KB
- **Functions:** 50
- **Lines:** 3334
- **Last Modified:** 08/20/2025 17:25:25

**Functions:**
- `ConvertTo-HashTable` (Line 351, 28 lines) - `Get-AlertHistory` (Line 2564, 108 lines) - `Get-CriticalSubsystems` (Line 2008, 51 lines) - `Get-ProcessPerformanceCounters` (Line 1827, 107 lines) - `Get-RegisteredSubsystems` (Line 598, 28 lines) - `Get-ServiceDependencyGraph` (Line 2726, 87 lines) - `Get-SubsystemProcessId` (Line 400, 31 lines) - `Get-SystemUptime` (Line 381, 13 lines) - `Get-TopologicalSort` (Line 2815, 58 lines) - `Initialize-CrossModuleEvents` (Line 1379, 33 lines) - `Initialize-NamedPipeServer` (Line 856, 75 lines) - `Initialize-SubsystemRunspaces` (Line 3057, 65 lines) - `Initialize-SystemStatusMonitoring` (Line 1507, 123 lines) - `Invoke-CircuitBreakerCheck` (Line 2168, 140 lines) - `Invoke-EscalationProcedure` (Line 2448, 114 lines) - `Invoke-MessageHandler` (Line 1306, 20 lines) - `Measure-CommunicationPerformance` (Line 1329, 47 lines) - `New-SystemStatusMessage` (Line 953, 31 lines) - `Read-SystemStatus` (Line 283, 32 lines) - `Receive-SystemStatusMessage` (Line 1072, 62 lines) - `Register-MessageHandler` (Line 1286, 18 lines) - `Register-Subsystem` (Line 481, 80 lines) - `Restart-ServiceWithDependencies` (Line 2877, 105 lines) - `Send-EngineEvent` (Line 1414, 18 lines) - `Send-HealthAlert` (Line 2310, 136 lines) - `Send-HealthCheckRequest` (Line 1248, 35 lines) - `Send-Heartbeat` (Line 632, 54 lines) - `Send-HeartbeatRequest` (Line 1219, 27 lines) - `Send-SystemStatusMessage` (Line 986, 84 lines) - `Start-MessageProcessor` (Line 1435, 50 lines) - `Start-ServiceRecoveryAction` (Line 2984, 69 lines) - `Start-SubsystemSession` (Line 3124, 58 lines) - `Start-SystemStatusFileWatcher` (Line 1138, 62 lines) - `Stop-MessageProcessor` (Line 1487, 14 lines) - `Stop-NamedPipeServer` (Line 933, 16 lines) - `Stop-SubsystemRunspaces` (Line 3184, 53 lines) - `Stop-SystemStatusFileWatcher` (Line 1202, 15 lines) - `Stop-SystemStatusMonitoring` (Line 2676, 44 lines) - `Test-AllSubsystemHeartbeats` (Line 765, 51 lines) - `Test-CriticalSubsystemHealth` (Line 2061, 105 lines) - `Test-HeartbeatResponse` (Line 688, 75 lines) - `Test-ProcessHealth` (Line 1635, 116 lines) - `Test-ProcessPerformanceHealth` (Line 1936, 70 lines) - `Test-ServiceResponsiveness` (Line 1753, 72 lines) - `Test-SystemStatusSchema` (Line 188, 89 lines) - `Unregister-Subsystem` (Line 563, 33 lines) - `Update-SubsystemProcessInfo` (Line 433, 42 lines) - `Visit-Node` (Line 2828, 29 lines, 1 params) - `Write-SystemStatus` (Line 317, 28 lines) - `Write-SystemStatusLog` (Line 151, 31 lines) 
### Unity-Claude-SystemStatus.cleaned

- **Path:** `Unity-Claude-SystemStatus.cleaned.psm1`
- **Size:** 129.31 KB
- **Functions:** 50
- **Lines:** 3334
- **Last Modified:** 08/20/2025 17:25:25

**Functions:**
- `ConvertTo-HashTable` (Line 351, 28 lines) - `Get-AlertHistory` (Line 2564, 108 lines) - `Get-CriticalSubsystems` (Line 2008, 51 lines) - `Get-ProcessPerformanceCounters` (Line 1827, 107 lines) - `Get-RegisteredSubsystems` (Line 598, 28 lines) - `Get-ServiceDependencyGraph` (Line 2726, 87 lines) - `Get-SubsystemProcessId` (Line 400, 31 lines) - `Get-SystemUptime` (Line 381, 13 lines) - `Get-TopologicalSort` (Line 2815, 58 lines) - `Initialize-CrossModuleEvents` (Line 1379, 33 lines) - `Initialize-NamedPipeServer` (Line 856, 75 lines) - `Initialize-SubsystemRunspaces` (Line 3057, 65 lines) - `Initialize-SystemStatusMonitoring` (Line 1507, 123 lines) - `Invoke-CircuitBreakerCheck` (Line 2168, 140 lines) - `Invoke-EscalationProcedure` (Line 2448, 114 lines) - `Invoke-MessageHandler` (Line 1306, 20 lines) - `Measure-CommunicationPerformance` (Line 1329, 47 lines) - `New-SystemStatusMessage` (Line 953, 31 lines) - `Read-SystemStatus` (Line 283, 32 lines) - `Receive-SystemStatusMessage` (Line 1072, 62 lines) - `Register-MessageHandler` (Line 1286, 18 lines) - `Register-Subsystem` (Line 481, 80 lines) - `Restart-ServiceWithDependencies` (Line 2877, 105 lines) - `Send-EngineEvent` (Line 1414, 18 lines) - `Send-HealthAlert` (Line 2310, 136 lines) - `Send-HealthCheckRequest` (Line 1248, 35 lines) - `Send-Heartbeat` (Line 632, 54 lines) - `Send-HeartbeatRequest` (Line 1219, 27 lines) - `Send-SystemStatusMessage` (Line 986, 84 lines) - `Start-MessageProcessor` (Line 1435, 50 lines) - `Start-ServiceRecoveryAction` (Line 2984, 69 lines) - `Start-SubsystemSession` (Line 3124, 58 lines) - `Start-SystemStatusFileWatcher` (Line 1138, 62 lines) - `Stop-MessageProcessor` (Line 1487, 14 lines) - `Stop-NamedPipeServer` (Line 933, 16 lines) - `Stop-SubsystemRunspaces` (Line 3184, 53 lines) - `Stop-SystemStatusFileWatcher` (Line 1202, 15 lines) - `Stop-SystemStatusMonitoring` (Line 2676, 44 lines) - `Test-AllSubsystemHeartbeats` (Line 765, 51 lines) - `Test-CriticalSubsystemHealth` (Line 2061, 105 lines) - `Test-HeartbeatResponse` (Line 688, 75 lines) - `Test-ProcessHealth` (Line 1635, 116 lines) - `Test-ProcessPerformanceHealth` (Line 1936, 70 lines) - `Test-ServiceResponsiveness` (Line 1753, 72 lines) - `Test-SystemStatusSchema` (Line 188, 89 lines) - `Unregister-Subsystem` (Line 563, 33 lines) - `Update-SubsystemProcessInfo` (Line 433, 42 lines) - `Visit-Node` (Line 2828, 29 lines, 1 params) - `Write-SystemStatus` (Line 317, 28 lines) - `Write-SystemStatusLog` (Line 151, 31 lines) 
### Unity-Claude-TeamsIntegration

- **Path:** `Modules\Unity-Claude-TeamsIntegration\Unity-Claude-TeamsIntegration.psm1`
- **Size:** 22.77 KB
- **Functions:** 11
- **Lines:** 691
- **Last Modified:** 08/30/2025 14:32:46

**Functions:**
- `Create-TeamsRichCardPayload` (Line 246, 109 lines) - `Create-TeamsSimplePayload` (Line 357, 28 lines) - `Get-TeamsIntegrationStatistics` (Line 555, 19 lines) - `Initialize-TeamsIntegration` (Line 30, 87 lines) - `Send-TeamsAlert` (Line 170, 74 lines) - `Send-TeamsMessage` (Line 387, 66 lines) - `Send-TeamsMigrationWarning` (Line 640, 40 lines) - `Set-TeamsConfiguration` (Line 576, 62 lines) - `Test-TeamsIntegration` (Line 479, 74 lines) - `Test-TeamsMigrationStatus` (Line 119, 49 lines) - `Wait-ForTeamsRateLimit` (Line 455, 22 lines) 
### Unity-Claude-TechnicalDebtAgents

- **Path:** `Unity-Claude-TechnicalDebtAgents.psm1`
- **Size:** 22.4 KB
- **Functions:** 4
- **Lines:** 537
- **Last Modified:** 08/29/2025 20:47:39

**Functions:**
- `Invoke-HumanInterventionEscalation` (Line 433, 89 lines) - `Invoke-MultiAgentPrioritization` (Line 179, 148 lines) - `Invoke-TechnicalDebtMultiAgentAnalysis` (Line 57, 120 lines) - `New-RefactoringDecisionWorkflow` (Line 329, 102 lines) 
### Unity-Claude-TreeSitter

- **Path:** `Modules\Unity-Claude-CPG\Unity-Claude-TreeSitter.psm1`
- **Size:** 19.96 KB
- **Functions:** 10
- **Lines:** 633
- **Last Modified:** 08/24/2025 23:42:55

**Functions:**
- `ConvertFrom-TreeSitterCST` (Line 389, 30 lines) - `ConvertTreeSitterOutputToJson` (Line 368, 19 lines) - `Initialize-TreeSitter` (Line 13, 64 lines) - `Install-TreeSitterParsers` (Line 79, 64 lines) - `Invoke-TreeSitterCliParse` (Line 176, 27 lines) - `Invoke-TreeSitterNodeParse` (Line 205, 50 lines) - `Invoke-TreeSitterParse` (Line 145, 29 lines) - `Process-CSTNode` (Line 421, 91 lines) - `Test-TreeSitterPerformance` (Line 514, 75 lines) - `Write-TreeSitterNodeScript` (Line 257, 109 lines) 
### Unity-Claude-TriggerConditions

- **Path:** `Modules\Unity-Claude-DocumentationDrift\Unity-Claude-TriggerConditions.psm1`
- **Size:** 27.5 KB
- **Functions:** 7
- **Lines:** 758
- **Last Modified:** 08/24/2025 12:06:11

**Functions:**
- `Add-ToProcessingQueue` (Line 365, 65 lines) - `Clear-ProcessingQueue` (Line 600, 69 lines) - `Get-EstimatedProcessingTime` (Line 672, 29 lines) - `Get-ProcessingQueue` (Line 432, 44 lines) - `Initialize-TriggerConditions` (Line 79, 67 lines) - `Start-QueueProcessing` (Line 478, 120 lines) - `Test-TriggerCondition` (Line 148, 215 lines) 
### Unity-Claude-TriggerIntegration

- **Path:** `Modules\Unity-Claude-DocumentationDrift\Unity-Claude-TriggerIntegration.psm1`
- **Size:** 23.33 KB
- **Functions:** 8
- **Lines:** 622
- **Last Modified:** 08/24/2025 12:06:11

**Functions:**
- `Collect-ProcessingMetrics` (Line 471, 58 lines) - `Get-IntegrationStatus` (Line 531, 42 lines) - `Initialize-TriggerIntegration` (Line 57, 75 lines) - `Register-EventHandlers` (Line 134, 110 lines) - `Send-ProcessingNotification` (Line 424, 45 lines) - `Start-AsynchronousProcessing` (Line 371, 51 lines) - `Start-FileMonitoring` (Line 246, 68 lines) - `Stop-FileMonitoring` (Line 316, 53 lines) 
### Unity-Claude-TriggerManager

- **Path:** `Modules\Unity-Claude-FileMonitor\Unity-Claude-TriggerManager.psm1`
- **Size:** 19.18 KB
- **Functions:** 25
- **Lines:** 568
- **Last Modified:** 08/24/2025 12:06:11

**Functions:**
- `Add-ChangeToTrigger` (Line 176, 25 lines) - `Add-ExclusionPattern` (Line 472, 11 lines) - `Clear-TriggerQueue` (Line 454, 16 lines) - `Find-MatchingTriggers` (Line 120, 32 lines) - `Get-ExclusionPatterns` (Line 496, 5 lines) - `Get-ProcessingQueueStatus` (Line 443, 9 lines) - `Get-TriggerStatus` (Line 424, 17 lines) - `Initialize-TriggerManager` (Line 57, 41 lines) - `Invoke-ArchitectureUpdate` (Line 343, 3 lines) - `Invoke-CodeAnalysis` (Line 328, 3 lines) - `Invoke-ConfigValidation` (Line 333, 3 lines) - `Invoke-CoverageUpdate` (Line 363, 3 lines) - `Invoke-DocumentationUpdate` (Line 323, 3 lines) - `Invoke-FullAnalysis` (Line 338, 3 lines) - `Invoke-IndexUpdate` (Line 358, 3 lines) - `Invoke-LinkValidation` (Line 353, 3 lines) - `Invoke-TestExecution` (Line 348, 3 lines) - `Invoke-Trigger` (Line 203, 49 lines) - `Process-FileChange` (Line 368, 27 lines) - `Register-TriggerHandler` (Line 397, 12 lines) - `Remove-ExclusionPattern` (Line 485, 9 lines) - `Start-TriggerProcessing` (Line 254, 66 lines) - `Test-FileExclusion` (Line 100, 18 lines) - `Test-TriggerCooldown` (Line 154, 20 lines) - `Unregister-TriggerHandler` (Line 411, 11 lines) 
### Unity-Claude-UnityParallelization-Original

- **Path:** `Modules\Unity-Claude-UnityParallelization\Unity-Claude-UnityParallelization-Original.psm1`
- **Size:** 86.33 KB
- **Functions:** 22
- **Lines:** 2095
- **Last Modified:** 08/26/2025 11:46:19

**Functions:**
- `Aggregate-UnityErrors` (Line 1363, 111 lines) - `Classify-UnityCompilationError` (Line 1275, 74 lines) - `Deduplicate-UnityErrors` (Line 1490, 86 lines) - `Export-UnityErrorsConcurrently` (Line 1706, 157 lines) - `Find-UnityProjects` (Line 145, 69 lines) - `Format-UnityErrorsForClaude` (Line 1877, 61 lines) - `Get-RegisteredUnityProjects` (Line 352, 11 lines) - `Get-UnityErrorStatistics` (Line 1590, 94 lines) - `Get-UnityMonitoringStatus` (Line 932, 53 lines) - `Get-UnityProjectConfiguration` (Line 320, 22 lines) - `New-UnityParallelMonitor` (Line 490, 169 lines) - `Register-UnityProject` (Line 232, 76 lines) - `Set-UnityProjectConfiguration` (Line 377, 37 lines) - `Start-ConcurrentErrorDetection` (Line 1123, 138 lines) - `Start-UnityCompilationJob` (Line 1007, 96 lines) - `Start-UnityParallelMonitoring` (Line 673, 179 lines) - `Stop-UnityParallelMonitoring` (Line 866, 54 lines) - `Test-ModuleDependencyAvailability` (Line 12, 20 lines) - `Test-UnityParallelizationPerformance` (Line 1952, 70 lines) - `Test-UnityProjectAvailability` (Line 426, 42 lines) - `Write-FallbackLog` (Line 75, 16 lines) - `Write-UnityParallelLog` (Line 94, 12 lines) 
### Unity-Claude-UnityParallelization-Refactored

- **Path:** `Modules\Unity-Claude-UnityParallelization\Unity-Claude-UnityParallelization-Refactored.psm1`
- **Size:** 10.72 KB
- **Functions:** 2
- **Lines:** 263
- **Last Modified:** 08/26/2025 11:46:19

**Functions:**
- `Get-UnityParallelizationModuleInfo` (Line 102, 13 lines) - `Show-UnityParallelizationFunctions` (Line 117, 40 lines) 
### Unity-Claude-UnityParallelization

- **Path:** `Modules\Unity-Claude-UnityParallelization\Unity-Claude-UnityParallelization.psm1`
- **Size:** 10.72 KB
- **Functions:** 2
- **Lines:** 263
- **Last Modified:** 08/26/2025 11:46:19

**Functions:**
- `Get-UnityParallelizationModuleInfo` (Line 102, 13 lines) - `Show-UnityParallelizationFunctions` (Line 117, 40 lines) 
### Unity-Claude-WebhookNotifications

- **Path:** `Modules\Unity-Claude-WebhookNotifications\Unity-Claude-WebhookNotifications.psm1`
- **Size:** 40.8 KB
- **Functions:** 11
- **Lines:** 1002
- **Last Modified:** 08/21/2025 17:45:27

**Functions:**
- `Get-WebhookConfiguration` (Line 358, 65 lines) - `Get-WebhookDeliveryAnalytics` (Line 879, 70 lines) - `Get-WebhookDeliveryStats` (Line 855, 22 lines) - `Invoke-WebhookDelivery` (Line 209, 147 lines) - `New-APIKeyAuthentication` (Line 588, 83 lines) - `New-BasicAuthentication` (Line 501, 85 lines) - `New-BearerTokenAuth` (Line 426, 73 lines) - `New-WebhookConfiguration` (Line 24, 82 lines) - `Send-WebhookNotification` (Line 673, 76 lines) - `Send-WebhookWithRetry` (Line 752, 101 lines) - `Test-WebhookConfiguration` (Line 108, 99 lines) 
### Unity-Claude-WindowDetection-Enhanced

- **Path:** `Modules\Unity-Claude-WindowDetection-Enhanced.psm1`
- **Size:** 9.34 KB
- **Functions:** 1
- **Lines:** 179
- **Last Modified:** 08/20/2025 17:25:22

**Functions:**
- `Find-ClaudeCodeCLIWindow-Enhanced` (Line 4, 138 lines) 
### Unity-Claude-WindowDetection

- **Path:** `Modules\Unity-Claude-WindowDetection.psm1`
- **Size:** 15.24 KB
- **Functions:** 5
- **Lines:** 415
- **Last Modified:** 08/20/2025 17:25:22

**Functions:**
- `Find-ClaudeCodeCLIWindow` (Line 239, 95 lines) - `Get-DetailedWindowInfo` (Line 49, 35 lines) - `Get-ForegroundWindow` (Line 177, 56 lines) - `Test-ClaudeCodeWindow` (Line 86, 89 lines) - `Test-WindowDetection` (Line 336, 31 lines) 
### Unity-Project-TestMocks

- **Path:** `Unity-Project-TestMocks.psm1`
- **Size:** 7.86 KB
- **Functions:** 6
- **Lines:** 238
- **Last Modified:** 08/21/2025 12:40:15

**Functions:**
- `Get-RegisteredUnityProjects` (Line 182, 16 lines) - `Get-UnityProjectStatus` (Line 120, 39 lines) - `Initialize-UnityProjectRegistry` (Line 201, 23 lines) - `Register-UnityProject` (Line 87, 30 lines) - `Test-UnityProjectAvailability` (Line 40, 44 lines) - `Unregister-UnityProject` (Line 162, 17 lines) 
### Unity-Project-TestMocks

- **Path:** `Backups\PS7Migration_20250822_162419\Unity-Project-TestMocks.psm1`
- **Size:** 7.86 KB
- **Functions:** 6
- **Lines:** 238
- **Last Modified:** 08/21/2025 12:40:15

**Functions:**
- `Get-RegisteredUnityProjects` (Line 182, 16 lines) - `Get-UnityProjectStatus` (Line 120, 39 lines) - `Initialize-UnityProjectRegistry` (Line 201, 23 lines) - `Register-UnityProject` (Line 87, 30 lines) - `Test-UnityProjectAvailability` (Line 40, 44 lines) - `Unregister-UnityProject` (Line 162, 17 lines) 
### Unity-TestAutomation

- **Path:** `Modules\Unity-TestAutomation\Unity-TestAutomation.psm1`
- **Size:** 41.42 KB
- **Functions:** 9
- **Lines:** 1202
- **Last Modified:** 08/20/2025 17:25:22

**Functions:**
- `Export-TestReport` (Line 858, 281 lines) - `Find-CustomTestScripts` (Line 671, 53 lines) - `Get-TestResultAggregation` (Line 730, 126 lines) - `Get-UnityTestCategories` (Line 420, 49 lines) - `Get-UnityTestResults` (Line 307, 107 lines) - `Invoke-PowerShellTests` (Line 546, 123 lines) - `Invoke-UnityEditModeTests` (Line 27, 136 lines) - `Invoke-UnityPlayModeTests` (Line 169, 132 lines) - `New-UnityTestFilter` (Line 471, 69 lines) 
### UnityBuildOperations

- **Path:** `Modules\SafeCommandExecution\Core\UnityBuildOperations.psm1`
- **Size:** 22.42 KB
- **Functions:** 6
- **Lines:** 633
- **Last Modified:** 08/26/2025 11:46:17

**Functions:**
- `Invoke-UnityAssetImport` (Line 360, 107 lines) - `Invoke-UnityCustomMethod` (Line 550, 29 lines) - `Invoke-UnityPlayerBuild` (Line 22, 138 lines) - `New-UnityAssetImportScript` (Line 469, 75 lines) - `New-UnityBuildScript` (Line 162, 91 lines) - `Test-UnityBuildResult` (Line 255, 99 lines) 
### UnityCommands

- **Path:** `Modules\Unity-Claude-AutonomousAgent\Commands\UnityCommands.psm1`
- **Size:** 15.5 KB
- **Functions:** 7
- **Lines:** 446
- **Last Modified:** 08/20/2025 17:25:20

**Functions:**
- `Find-UnityExecutable` (Line 346, 51 lines) - `Invoke-AnalyzeCommand` (Line 280, 64 lines) - `Invoke-BuildCommand` (Line 229, 49 lines) - `Invoke-CompilationTest` (Line 127, 41 lines) - `Invoke-PowerShellTests` (Line 170, 57 lines) - `Invoke-TestCommand` (Line 16, 48 lines) - `Invoke-UnityTests` (Line 66, 59 lines) 
### UnityIntegration

- **Path:** `Modules\Unity-Claude-AutonomousAgent\Integration\UnityIntegration.psm1`
- **Size:** 12.64 KB
- **Functions:** 6
- **Lines:** 364
- **Last Modified:** 08/20/2025 17:25:21

**Functions:**
- `Convert-ActionToType` (Line 121, 43 lines) - `Convert-TypeToStandard` (Line 74, 45 lines) - `Get-PatternConfidence` (Line 16, 56 lines) - `Get-StringSimilarity` (Line 253, 59 lines) - `Normalize-RecommendationType` (Line 166, 38 lines) - `Remove-DuplicateRecommendations` (Line 206, 45 lines) 
### UnityLogAnalysis

- **Path:** `Modules\SafeCommandExecution\Core\UnityLogAnalysis.psm1`
- **Size:** 14.77 KB
- **Functions:** 2
- **Lines:** 401
- **Last Modified:** 08/26/2025 11:46:17

**Functions:**
- `Invoke-UnityErrorPatternAnalysis` (Line 200, 151 lines) - `Invoke-UnityLogAnalysis` (Line 22, 172 lines) 
### UnityPerformanceAnalysis

- **Path:** `Modules\SafeCommandExecution\Core\UnityPerformanceAnalysis.psm1`
- **Size:** 15.01 KB
- **Functions:** 2
- **Lines:** 398
- **Last Modified:** 08/26/2025 11:46:17

**Functions:**
- `Invoke-UnityPerformanceAnalysis` (Line 21, 191 lines) - `Invoke-UnityTrendAnalysis` (Line 218, 130 lines) 
### UnityProjectOperations

- **Path:** `Modules\SafeCommandExecution\Core\UnityProjectOperations.psm1`
- **Size:** 14.34 KB
- **Functions:** 3
- **Lines:** 378
- **Last Modified:** 08/26/2025 11:46:17

**Functions:**
- `Invoke-UnityProjectValidation` (Line 22, 121 lines) - `Invoke-UnityScriptCompilation` (Line 149, 104 lines) - `Test-UnityCompilationResult` (Line 255, 72 lines) 
### UnityReportingOperations

- **Path:** `Modules\SafeCommandExecution\Core\UnityReportingOperations.psm1`
- **Size:** 21.96 KB
- **Functions:** 3
- **Lines:** 598
- **Last Modified:** 08/26/2025 11:46:17

**Functions:**
- `Export-UnityAnalysisData` (Line 214, 150 lines) - `Get-UnityAnalyticsMetrics` (Line 370, 177 lines) - `Invoke-UnityReportGeneration` (Line 21, 187 lines) 
### ValidationEngine

- **Path:** `Modules\SafeCommandExecution\Core\ValidationEngine.psm1`
- **Size:** 11.32 KB
- **Functions:** 4
- **Lines:** 335
- **Last Modified:** 08/26/2025 11:46:17

**Functions:**
- `Remove-DangerousCharacters` (Line 198, 27 lines) - `Test-CommandSafety` (Line 21, 122 lines) - `Test-InputValidity` (Line 227, 56 lines) - `Test-PathSafety` (Line 149, 43 lines) 
### VariableSharing

- **Path:** `Modules\Unity-Claude-RunspaceManagement\Core\VariableSharing.psm1`
- **Size:** 12.9 KB
- **Functions:** 10
- **Lines:** 347
- **Last Modified:** 08/26/2025 11:46:19

**Functions:**
- `Add-SessionStateVariable` (Line 26, 0 lines) - `Add-SharedVariable` (Line 73, 65 lines) - `Get-AllSharedVariables` (Line 270, 29 lines) - `Get-SharedVariable` (Line 140, 38 lines) - `Get-SharedVariablesDictionary` (Line 27, 0 lines) - `New-SessionStateVariableEntry` (Line 30, 41 lines) - `Remove-SharedVariable` (Line 217, 30 lines) - `Set-SharedVariable` (Line 180, 35 lines) - `Test-SharedVariableAccess` (Line 249, 19 lines) - `Write-ModuleLog` (Line 21, 4 lines) 
### WindowManager-Enhanced

- **Path:** `Modules\Unity-Claude-CLIOrchestrator\Core\WindowManager-Enhanced.psm1`
- **Size:** 16.34 KB
- **Functions:** 4
- **Lines:** 342
- **Last Modified:** 08/27/2025 20:42:25

**Functions:**
- `Find-ClaudeWindow` (Line 120, 134 lines) - `Get-ClaudeWindowInfo` (Line 256, 21 lines) - `Switch-ToWindow` (Line 279, 55 lines) - `Update-ClaudeWindowInfo` (Line 74, 44 lines) 
### WindowManager-NUGGETRON

- **Path:** `Modules\Unity-Claude-CLIOrchestrator\Core\WindowManager-NUGGETRON.psm1`
- **Size:** 6.27 KB
- **Functions:** 4
- **Lines:** 188
- **Last Modified:** 08/27/2025 21:15:04

**Functions:**
- `Get-ClaudeWindowInfo` (Line 6, 43 lines) - `Submit-ToClaudeWindow` (Line 131, 49 lines) - `Switch-ToClaudeWindow` (Line 92, 37 lines) - `Update-ClaudeWindowInfo` (Line 51, 39 lines) 
### WindowManager-Original

- **Path:** `Modules\Unity-Claude-CLIOrchestrator\Core\WindowManager-Original.psm1`
- **Size:** 16.34 KB
- **Functions:** 4
- **Lines:** 342
- **Last Modified:** 08/27/2025 20:42:25

**Functions:**
- `Find-ClaudeWindow` (Line 120, 134 lines) - `Get-ClaudeWindowInfo` (Line 256, 21 lines) - `Switch-ToWindow` (Line 279, 55 lines) - `Update-ClaudeWindowInfo` (Line 74, 44 lines) 
### WindowManager

- **Path:** `Modules\Unity-Claude-CLIOrchestrator\Core\WindowManager.psm1`
- **Size:** 14.5 KB
- **Functions:** 5
- **Lines:** 367
- **Last Modified:** 08/27/2025 23:51:05

**Functions:**
- `Get-ClaudeWindowInfo` (Line 76, 83 lines) - `Submit-ToClaudeWindow` (Line 281, 77 lines) - `Switch-ToClaudeWindow` (Line 209, 70 lines) - `Update-ClaudeWindowInfo` (Line 193, 14 lines) - `Update-ProtectedRegistration` (Line 161, 30 lines) 
### WorkflowCore

- **Path:** `Modules\Unity-Claude-IntegratedWorkflow\Core\WorkflowCore.psm1`
- **Size:** 4.3 KB
- **Functions:** 3
- **Lines:** 102
- **Last Modified:** 08/26/2025 11:46:18

**Functions:**
- `Get-IntegratedWorkflowState` (Line 55, 2 lines) - `Write-FallbackLog` (Line 17, 19 lines) - `Write-IntegratedWorkflowLog` (Line 39, 13 lines) 
### WorkflowIntegration

- **Path:** `Modules\Unity-Claude-NotificationIntegration\Integration\WorkflowIntegration.psm1`
- **Size:** 9.09 KB
- **Functions:** 6
- **Lines:** 272
- **Last Modified:** 08/21/2025 17:45:27

**Functions:**
- `Add-WorkflowNotificationTrigger` (Line 71, 47 lines) - `Disable-WorkflowNotifications` (Line 163, 30 lines) - `Enable-WorkflowNotifications` (Line 131, 30 lines) - `Get-WorkflowNotificationStatus` (Line 195, 29 lines) - `Invoke-NotificationHook` (Line 7, 62 lines) - `Remove-WorkflowNotificationTrigger` (Line 120, 9 lines) 
### WorkflowIntegration

- **Path:** `Modules\Unity-Claude-HITL\Core\WorkflowIntegration.psm1`
- **Size:** 14.84 KB
- **Functions:** 6
- **Lines:** 429
- **Last Modified:** 08/26/2025 11:46:18

**Functions:**
- `Export-ApprovalMetrics` (Line 301, 22 lines) - `Invoke-ApprovalAction` (Line 248, 51 lines) - `Invoke-HumanApprovalWorkflow` (Line 165, 77 lines) - `Resume-WorkflowFromApproval` (Line 110, 53 lines) - `Test-HITLSystemHealth` (Line 325, 54 lines) - `Wait-HumanApproval` (Line 17, 91 lines) 
### WorkflowMonitoring

- **Path:** `Modules\Unity-Claude-IntegratedWorkflow\Core\WorkflowMonitoring.psm1`
- **Size:** 13.34 KB
- **Functions:** 2
- **Lines:** 287
- **Last Modified:** 08/26/2025 11:46:18

**Functions:**
- `Get-IntegratedWorkflowStatus` (Line 23, 89 lines) - `Stop-IntegratedWorkflow` (Line 128, 116 lines) 
### WorkflowOrchestration

- **Path:** `Modules\Unity-Claude-IntegratedWorkflow\Core\WorkflowOrchestration.psm1`
- **Size:** 21.3 KB
- **Functions:** 3
- **Lines:** 448
- **Last Modified:** 08/26/2025 11:46:18

**Functions:**
- `Get-WorkflowOrchestrationScript` (Line 321, 83 lines) - `New-IntegratedWorkflow` (Line 31, 174 lines) - `Start-IntegratedWorkflow` (Line 223, 95 lines)

## Function Index

Total Functions: 6003

### Top 50 Functions by Size

| Function | Module/Script | Lines | Parameters |
|----------|--------------|-------|------------|
| `Start-CLIOrchestration` | OrchestrationManager.psm1 | 967 | 0 | | `Out-PSModuleCallGraph` | Out-PSModuleCallGraph.ps1 | 938 | 0 | | `Assess-DocumentationQuality` | Unity-Claude-DocumentationQualityAssessment_Original_20250830_193150.psm1 | 804 | 0 | | `Test-Case` | Test-UnityClaudeModules.ps1 | 548 | 0 | | `New-AnalysisSummaryReport` | New-AnalysisSummaryReport.ps1 | 531 | 0 | | `New-AnalysisTrendReport` | New-AnalysisTrendReport.ps1 | 518 | 0 | | `New-UserGuideDocumentation` | Week3Day15Hour7-8-FinalDocumentationKnowledgeTransfer.ps1 | 490 | 0 | | `New-TestProject` | Test-E2E-Documentation.ps1 | 478 | 0 | | `Invoke-SemgrepAnalysis` | Invoke-SemgrepAnalysis.ps1 | 432 | 0 | | `Invoke-PSScriptAnalyzerEnhanced` | Invoke-PSScriptAnalyzerEnhanced.ps1 | 429 | 0 | | `Invoke-PylintAnalysis` | Invoke-PylintAnalysis.ps1 | 398 | 0 | | `Submit-PromptToClaudeCode` | Unity-Claude-CLISubmission.psm1 | 375 | 0 | | `Invoke-BanditAnalysis` | Invoke-BanditAnalysis.ps1 | 374 | 0 | | `Invoke-ESLintAnalysis` | Invoke-ESLintAnalysis.ps1 | 365 | 0 | | `New-CodeGraph` | New-CodeGraph.ps1 | 354 | 0 | | `Document-LessonsLearned` | Week3Day15Hour7-8-FinalDocumentationKnowledgeTransfer.ps1 | 348 | 0 | | `Build-DocumentationGraph` | Unity-Claude-DocumentationCrossReference.psm1 | 341 | 0 | | `Get-UCEventPatterns` | Get-UCEventPatterns.ps1 | 339 | 0 | | `Test-ManifestSecurity` | Test-ManifestSecurity.ps1 | 339 | 0 | | `Create-AdvancedFeaturesTraining` | Week3Day15Hour7-8-FinalDocumentationKnowledgeTransfer.ps1 | 321 | 0 | | `Create-SystemHandoverDocument` | Week3Day15Hour7-8-FinalDocumentationKnowledgeTransfer.ps1 | 316 | 0 | | `Create-AdminCertificationGuide` | Week3Day15Hour7-8-FinalDocumentationKnowledgeTransfer.ps1 | 307 | 0 | | `Register-SubsystemFromManifest` | Register-SubsystemFromManifest.ps1 | 306 | 0 | | `Invoke-DecisionExecution` | Invoke-DecisionExecution.ps1 | 298 | 0 | | `New-DocumentationPR` | Unity-Claude-DocumentationDrift.psm1 | 297 | 0 | | `Set-GitHubGovernanceConfiguration` | Set-GitHubGovernanceConfiguration.ps1 | 293 | 0 | | `Invoke-GitHubAPIWithRetry` | Invoke-GitHubAPIWithRetry.ps1 | 290 | 0 | | `New-SystemArchitectureDocumentation` | Week3Day15Hour7-8-FinalDocumentationKnowledgeTransfer.ps1 | 288 | 0 | | `Invoke-StaticAnalysis` | Invoke-StaticAnalysis.ps1 | 282 | 0 | | `Export-TestReport` | Unity-TestAutomation.psm1 | 281 | 0 | | `Start-IntegratedWorkflow` | Unity-Claude-IntegratedWorkflow-Original.psm1 | 276 | 0 | | `Search-GitHubIssues` | Search-GitHubIssues.ps1 | 275 | 0 | | `Get-SubsystemManifests` | Get-SubsystemManifests.ps1 | 267 | 0 | | `Test-GitHubBranchProtection` | Test-GitHubBranchProtection.ps1 | 266 | 0 | | `Write-UCEventLog` | Write-UCEventLog.ps1 | 265 | 0 | | `Start-CLIOrchestration` | Start-CLIOrchestration.ps1 | 264 | 0 | | `Merge-SarifResults` | Merge-SarifResults.ps1 | 263 | 0 | | `Create-IncidentResponseRunbook` | Week3Day15-ProductionDeploymentConfiguration.ps1 | 262 | 0 | | `Test-GitHubIssueDuplicate` | Test-GitHubIssueDuplicate.ps1 | 258 | 0 | | `Get-CodePurpose` | Unity-Claude-SemanticAnalysis.psm1 | 253 | 0 | | `Test-AutonomousAgentStatus` | Test-AutonomousAgentStatus-EventLog.ps1 | 251 | 0 | | `Get-ASTCrossReferences` | Unity-Claude-DocumentationCrossReference.psm1 | 250 | 0 | | `New-IntelligentJobBatching` | Unity-Claude-IntegratedWorkflow-Original.psm1 | 249 | 0 | | `New-ImprovementRoadmap` | Unity-Claude-PredictiveAnalysis-Original.psm1 | 244 | 0 | | `New-GitHubCodeOwnersFile` | New-GitHubCodeOwnersFile.ps1 | 244 | 0 | | `Test-SubsystemManifest` | Test-SubsystemManifest.ps1 | 243 | 0 | | `Invoke-RipgrepSearch` | Invoke-RipgrepSearch.ps1 | 243 | 0 | | `Connect-ToPipeServer` | BidirectionalClient-Example.ps1 | 242 | 0 | | `Find-RecommendationPatterns` | Find-RecommendationPatterns.ps1 | 242 | 0 | | `Restart-AutonomousAgent` | Test-AutonomousAgentStatus-EventLog.ps1 | 241 | 0 |

---
*Generated by Unity-Claude Documentation System*
