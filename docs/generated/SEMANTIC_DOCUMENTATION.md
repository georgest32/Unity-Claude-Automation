# Unity-Claude Automation System - Complete Semantic Documentation

**Generated:** 2025-08-30 23:59:53  
**Total Modules:** 375  
**Total Functions:** 3904

## 📑 Table of Contents

1. [System Overview](#-system-overview)
2. [Architecture](#-architecture)
3. [Semantic Groups](#-semantic-groups)
4. [Module Network](#-module-network)
5. [Module Catalog](#-module-catalog)
6. [Relationship Matrix](#-relationship-matrix)

---

## 🎯 System Overview

The Unity-Claude Automation System represents a sophisticated integration framework that bridges Unity game development with advanced AI capabilities. This PowerShell-based system implements a microservices-like architecture where each module provides specialized functionality while maintaining loose coupling through well-defined interfaces.

### Core Design Principles

- **Modularity**: Each component is self-contained with clear boundaries
- **Event-Driven**: Reactive architecture responding to Unity and file system events
- **Parallel Processing**: Maximizes performance through concurrent execution
- **Safety First**: Multiple validation layers prevent destructive operations
- **Self-Documenting**: Automatically maintains its own documentation
- **AI-Enhanced**: Integrates Claude AI for intelligent decision making

## 🏗️ Architecture

The system follows a layered architecture pattern:

\\\
┌─────────────────────────────────────────────┐
│          Presentation Layer                 │
│    (CLI, Web Dashboard, Notifications)      │
├─────────────────────────────────────────────┤
│          Orchestration Layer                │
│    (Workflow Management, Coordination)      │
├─────────────────────────────────────────────┤
│          Business Logic Layer               │
│    (Decision Engine, Rules, Validation)     │
├─────────────────────────────────────────────┤
│          Integration Layer                  │
│    (Unity, Claude AI, GitHub, Email)        │
├─────────────────────────────────────────────┤
│          Core Services Layer                │
│    (Parallel Processing, Caching, Logging)  │
└─────────────────────────────────────────────┘
\\\

## 🔗 Semantic Groups

The modules are organized into semantic groups based on their primary responsibilities:


### AI & Intelligence

**Modules in this group:** 177

- [**AIAssessment**](#aiassessment) - [**ClaudeIntegration**](#claudeintegration) - [**DecisionEngine**](#decisionengine) - [**DecisionEngine-Bayesian**](#decisionengine-bayesian) - [**DecisionEngine-Bayesian-Refactored**](#decisionengine-bayesian-refactored) - [**DecisionEngine-Refactored**](#decisionengine-refactored) - [**DecisionEngineCore**](#decisionenginecore) - [**DecisionEngineIntegration**](#decisionengineintegration) - [**DecisionExecution**](#decisionexecution) - [**DecisionExecution-Fixed**](#decisionexecution-fixed) - [**DecisionMaking**](#decisionmaking) - [**DecisionMaking-Fixed**](#decisionmaking-fixed) - [**FailureMode**](#failuremode) - [**LearningAdaptation**](#learningadaptation) - [**LearningCore**](#learningcore) - [**MaintenancePrediction**](#maintenanceprediction) - [**Predictive-Maintenance**](#predictive-maintenance) - [**RuleBasedDecisionTrees**](#rulebaseddecisiontrees) - [**Unity-Claude-AgentIntegration**](#unity-claude-agentintegration) - [**Unity-Claude-AIAlertClassifier**](#unity-claude-aialertclassifier) - [**Unity-Claude-AlertAnalytics**](#unity-claude-alertanalytics) - [**Unity-Claude-AlertFeedbackCollector**](#unity-claude-alertfeedbackcollector) - [**Unity-Claude-AlertMLOptimizer**](#unity-claude-alertmloptimizer) - [**Unity-Claude-AlertQualityReporting**](#unity-claude-alertqualityreporting) - [**Unity-Claude-APIDocumentation**](#unity-claude-apidocumentation) - [**Unity-Claude-AST-Enhanced**](#unity-claude-ast-enhanced) - [**Unity-Claude-AutoGen**](#unity-claude-autogen) - [**Unity-Claude-AutoGenMonitoring**](#unity-claude-autogenmonitoring) - [**Unity-Claude-AutonomousAgent-Refactored**](#unity-claude-autonomousagent-refactored) - [**Unity-Claude-AutonomousDocumentationEngine**](#unity-claude-autonomousdocumentationengine) - [**Unity-Claude-AutonomousStateTracker**](#unity-claude-autonomousstatetracker) - [**Unity-Claude-AutonomousStateTracker-Enhanced**](#unity-claude-autonomousstatetracker-enhanced) - [**Unity-Claude-AutonomousStateTracker-Enhanced-Refactored**](#unity-claude-autonomousstatetracker-enhanced-refactored) - [**Unity-Claude-Cache**](#unity-claude-cache) - [**Unity-Claude-Cache-Fixed**](#unity-claude-cache-fixed) - [**Unity-Claude-Cache-Original**](#unity-claude-cache-original) - [**Unity-Claude-ChangeIntelligence**](#unity-claude-changeintelligence) - [**Unity-Claude-ClaudeParallelization**](#unity-claude-claudeparallelization) - [**Unity-Claude-CLIOrchestrator**](#unity-claude-cliorchestrator) - [**Unity-Claude-CLIOrchestrator-Fixed-Simple**](#unity-claude-cliorchestrator-fixed-simple) - [**Unity-Claude-CLIOrchestrator-FullFeatured**](#unity-claude-cliorchestrator-fullfeatured) - [**Unity-Claude-CLIOrchestrator-Original**](#unity-claude-cliorchestrator-original) - [**Unity-Claude-CLIOrchestrator-Original-Backup**](#unity-claude-cliorchestrator-original-backup) - [**Unity-Claude-CLIOrchestrator-Refactored**](#unity-claude-cliorchestrator-refactored) - [**Unity-Claude-CLIOrchestrator-Refactored-Fixed**](#unity-claude-cliorchestrator-refactored-fixed) - [**Unity-Claude-CLISubmission**](#unity-claude-clisubmission) - [**Unity-Claude-CLISubmission-Enhanced**](#unity-claude-clisubmission-enhanced) - [**Unity-Claude-CodeQL**](#unity-claude-codeql) - [**Unity-Claude-ConcurrentCollections**](#unity-claude-concurrentcollections) - [**Unity-Claude-ConcurrentProcessor**](#unity-claude-concurrentprocessor) - [**Unity-Claude-Core**](#unity-claude-core) - [**Unity-Claude-CPG**](#unity-claude-cpg) - [**Unity-Claude-CPG-ASTConverter**](#unity-claude-cpg-astconverter) - [**Unity-Claude-CPG-Original**](#unity-claude-cpg-original) - [**Unity-Claude-CPG-Refactored**](#unity-claude-cpg-refactored) - [**Unity-Claude-CrossLanguage**](#unity-claude-crosslanguage) - [**Unity-Claude-DecisionEngine**](#unity-claude-decisionengine) - [**Unity-Claude-DecisionEngine-Bayesian**](#unity-claude-decisionengine-bayesian) - [**Unity-Claude-DecisionEngine-Original**](#unity-claude-decisionengine-original) - [**Unity-Claude-DecisionEngine-Refactored**](#unity-claude-decisionengine-refactored) - [**Unity-Claude-DocumentationAnalytics**](#unity-claude-documentationanalytics) - [**Unity-Claude-DocumentationAutomation**](#unity-claude-documentationautomation) - [**Unity-Claude-DocumentationAutomation-Original**](#unity-claude-documentationautomation-original) - [**Unity-Claude-DocumentationAutomation-Refactored**](#unity-claude-documentationautomation-refactored) - [**Unity-Claude-DocumentationCrossReference**](#unity-claude-documentationcrossreference) - [**Unity-Claude-DocumentationDrift**](#unity-claude-documentationdrift) - [**Unity-Claude-DocumentationDrift-Refactored**](#unity-claude-documentationdrift-refactored) - [**Unity-Claude-DocumentationPipeline**](#unity-claude-documentationpipeline) - [**Unity-Claude-DocumentationQualityAssessment**](#unity-claude-documentationqualityassessment) - [**Unity-Claude-DocumentationQualityAssessment_Original_20250830_193150**](#unity-claude-documentationqualityassessment-original-20250830-193150) - [**Unity-Claude-DocumentationQualityOrchestrator**](#unity-claude-documentationqualityorchestrator) - [**Unity-Claude-DocumentationSuggestions**](#unity-claude-documentationsuggestions) - [**Unity-Claude-DocumentationVersioning**](#unity-claude-documentationversioning) - [**Unity-Claude-EmailNotifications**](#unity-claude-emailnotifications) - [**Unity-Claude-EmailNotifications-SystemNetMail**](#unity-claude-emailnotifications-systemnetmail) - [**Unity-Claude-ErrorHandling**](#unity-claude-errorhandling) - [**Unity-Claude-Errors**](#unity-claude-errors) - [**Unity-Claude-EventLog**](#unity-claude-eventlog) - [**Unity-Claude-FileMonitor**](#unity-claude-filemonitor) - [**Unity-Claude-FileMonitor-Fixed**](#unity-claude-filemonitor-fixed) - [**Unity-Claude-FixEngine**](#unity-claude-fixengine) - [**Unity-Claude-GitHub**](#unity-claude-github) - [**Unity-Claude-GovernanceIntegration**](#unity-claude-governanceintegration) - [**Unity-Claude-HITL**](#unity-claude-hitl) - [**Unity-Claude-HITL-Original**](#unity-claude-hitl-original) - [**Unity-Claude-HITL-Refactored**](#unity-claude-hitl-refactored) - [**Unity-Claude-IncrementalProcessor**](#unity-claude-incrementalprocessor) - [**Unity-Claude-IncrementalProcessor-Fixed**](#unity-claude-incrementalprocessor-fixed) - [**Unity-Claude-IntegratedWorkflow**](#unity-claude-integratedworkflow) - [**Unity-Claude-IntegratedWorkflow-Original**](#unity-claude-integratedworkflow-original) - [**Unity-Claude-IntegratedWorkflow-Refactored**](#unity-claude-integratedworkflow-refactored) - [**Unity-Claude-IntegrationEngine**](#unity-claude-integrationengine) - [**Unity-Claude-IntelligentAlerting**](#unity-claude-intelligentalerting) - [**Unity-Claude-IntelligentDocumentationTriggers**](#unity-claude-intelligentdocumentationtriggers) - [**Unity-Claude-IPC**](#unity-claude-ipc) - [**Unity-Claude-IPC-Bidirectional**](#unity-claude-ipc-bidirectional) - [**Unity-Claude-IPC-Bidirectional-Fixed**](#unity-claude-ipc-bidirectional-fixed) - [**Unity-Claude-LangGraphBridge**](#unity-claude-langgraphbridge) - [**Unity-Claude-Learning**](#unity-claude-learning) - [**Unity-Claude-Learning-Analytics**](#unity-claude-learning-analytics) - [**Unity-Claude-Learning-Original**](#unity-claude-learning-original) - [**Unity-Claude-Learning-Refactored**](#unity-claude-learning-refactored) - [**Unity-Claude-Learning-Simple**](#unity-claude-learning-simple) - [**Unity-Claude-LLM**](#unity-claude-llm) - [**Unity-Claude-MachineLearning**](#unity-claude-machinelearning) - [**Unity-Claude-MasterOrchestrator**](#unity-claude-masterorchestrator) - [**Unity-Claude-MasterOrchestrator-Original**](#unity-claude-masterorchestrator-original) - [**Unity-Claude-MasterOrchestrator-Refactored**](#unity-claude-masterorchestrator-refactored) - [**Unity-Claude-MemoryAnalysis**](#unity-claude-memoryanalysis) - [**Unity-Claude-MessageQueue**](#unity-claude-messagequeue) - [**Unity-Claude-Monitoring**](#unity-claude-monitoring) - [**Unity-Claude-MultiStepOrchestrator**](#unity-claude-multisteporchestrator) - [**Unity-Claude-NotificationConfiguration**](#unity-claude-notificationconfiguration) - [**Unity-Claude-NotificationContentEngine**](#unity-claude-notificationcontentengine) - [**Unity-Claude-NotificationIntegration**](#unity-claude-notificationintegration) - [**Unity-Claude-NotificationIntegration-Modular**](#unity-claude-notificationintegration-modular) - [**Unity-Claude-NotificationPreferences**](#unity-claude-notificationpreferences) - [**Unity-Claude-ObsolescenceDetection**](#unity-claude-obsolescencedetection) - [**Unity-Claude-ObsolescenceDetection-Refactored**](#unity-claude-obsolescencedetection-refactored) - [**Unity-Claude-Ollama**](#unity-claude-ollama) - [**Unity-Claude-Ollama-Enhanced**](#unity-claude-ollama-enhanced) - [**Unity-Claude-Ollama-Optimized**](#unity-claude-ollama-optimized) - [**Unity-Claude-Ollama-Optimized-Fixed**](#unity-claude-ollama-optimized-fixed) - [**Unity-Claude-ParallelProcessing**](#unity-claude-parallelprocessing) - [**Unity-Claude-ParallelProcessor**](#unity-claude-parallelprocessor) - [**Unity-Claude-ParallelProcessor-Original**](#unity-claude-parallelprocessor-original) - [**Unity-Claude-ParallelProcessor-Refactored**](#unity-claude-parallelprocessor-refactored) - [**Unity-Claude-PerformanceOptimizer**](#unity-claude-performanceoptimizer) - [**Unity-Claude-PerformanceOptimizer-Original**](#unity-claude-performanceoptimizer-original) - [**Unity-Claude-PerformanceOptimizer-Refactored**](#unity-claude-performanceoptimizer-refactored) - [**Unity-Claude-PredictiveAnalysis**](#unity-claude-predictiveanalysis) - [**Unity-Claude-PredictiveAnalysis-Original**](#unity-claude-predictiveanalysis-original) - [**Unity-Claude-PredictiveAnalysis-Refactored**](#unity-claude-predictiveanalysis-refactored) - [**Unity-Claude-ProactiveMaintenanceEngine**](#unity-claude-proactivemaintenanceengine) - [**Unity-Claude-RealTimeAnalysis**](#unity-claude-realtimeanalysis) - [**Unity-Claude-RealTimeMonitoring**](#unity-claude-realtimemonitoring) - [**Unity-Claude-RealTimeOptimizer**](#unity-claude-realtimeoptimizer) - [**Unity-Claude-RecompileSignaling**](#unity-claude-recompilesignaling) - [**Unity-Claude-ReliabilityManager**](#unity-claude-reliabilitymanager) - [**Unity-Claude-ReliableMonitoring**](#unity-claude-reliablemonitoring) - [**Unity-Claude-RepoAnalyst**](#unity-claude-repoanalyst) - [**Unity-Claude-ResourceOptimizer**](#unity-claude-resourceoptimizer) - [**Unity-Claude-ResponseMonitor**](#unity-claude-responsemonitor) - [**Unity-Claude-ResponseMonitoring**](#unity-claude-responsemonitoring) - [**Unity-Claude-RunspaceManagement**](#unity-claude-runspacemanagement) - [**Unity-Claude-RunspaceManagement-Original**](#unity-claude-runspacemanagement-original) - [**Unity-Claude-RunspaceManagement-Refactored**](#unity-claude-runspacemanagement-refactored) - [**Unity-Claude-Safety**](#unity-claude-safety) - [**Unity-Claude-ScalabilityEnhancements**](#unity-claude-scalabilityenhancements) - [**Unity-Claude-ScalabilityEnhancements-Original**](#unity-claude-scalabilityenhancements-original) - [**Unity-Claude-ScalabilityEnhancements-Refactored**](#unity-claude-scalabilityenhancements-refactored) - [**Unity-Claude-ScalabilityOptimizer**](#unity-claude-scalabilityoptimizer) - [**Unity-Claude-SemanticAnalysis**](#unity-claude-semanticanalysis) - [**Unity-Claude-SemanticAnalysis-Architecture**](#unity-claude-semanticanalysis-architecture) - [**Unity-Claude-SemanticAnalysis-Business**](#unity-claude-semanticanalysis-business) - [**Unity-Claude-SemanticAnalysis-Helpers**](#unity-claude-semanticanalysis-helpers) - [**Unity-Claude-SemanticAnalysis-Metrics**](#unity-claude-semanticanalysis-metrics) - [**Unity-Claude-SemanticAnalysis-New**](#unity-claude-semanticanalysis-new) - [**Unity-Claude-SemanticAnalysis-Old**](#unity-claude-semanticanalysis-old) - [**Unity-Claude-SemanticAnalysis-Patterns**](#unity-claude-semanticanalysis-patterns) - [**Unity-Claude-SemanticAnalysis-Purpose**](#unity-claude-semanticanalysis-purpose) - [**Unity-Claude-SemanticAnalysis-Quality**](#unity-claude-semanticanalysis-quality) - [**Unity-Claude-SessionManager**](#unity-claude-sessionmanager) - [**Unity-Claude-SlackIntegration**](#unity-claude-slackintegration) - [**Unity-Claude-SystemCoordinator**](#unity-claude-systemcoordinator) - [**Unity-Claude-SystemStatus**](#unity-claude-systemstatus) - [**Unity-Claude-TeamsIntegration**](#unity-claude-teamsintegration) - [**Unity-Claude-TreeSitter**](#unity-claude-treesitter) - [**Unity-Claude-TriggerConditions**](#unity-claude-triggerconditions) - [**Unity-Claude-TriggerIntegration**](#unity-claude-triggerintegration) - [**Unity-Claude-TriggerManager**](#unity-claude-triggermanager) - [**Unity-Claude-UnityParallelization**](#unity-claude-unityparallelization) - [**Unity-Claude-UnityParallelization-Original**](#unity-claude-unityparallelization-original) - [**Unity-Claude-UnityParallelization-Refactored**](#unity-claude-unityparallelization-refactored) - [**Unity-Claude-WebhookNotifications**](#unity-claude-webhooknotifications) - [**Unity-Claude-WindowDetection**](#unity-claude-windowdetection) - [**Unity-Claude-WindowDetection-Enhanced**](#unity-claude-windowdetection-enhanced) 
### Core Infrastructure

**Modules in this group:** 22

- [**AgentCore**](#agentcore) - [**ConversationCore**](#conversationcore) - [**Core**](#core) - [**CoreUtilities**](#coreutilities) - [**DatabaseManagement**](#databasemanagement) - [**DecisionEngineCore**](#decisionenginecore) - [**HITLCore**](#hitlcore) - [**LearningCore**](#learningcore) - [**NotificationCore**](#notificationcore) - [**OrchestrationCore**](#orchestrationcore) - [**OrchestratorCore**](#orchestratorcore) - [**ParallelizationCore**](#parallelizationcore) - [**ParallelProcessorCore**](#parallelprocessorcore) - [**PredictiveCore**](#predictivecore) - [**ResponseAnalysisEngine-Core**](#responseanalysisengine-core) - [**ResponseAnalysisEngine-Core-Fixed**](#responseanalysisengine-core-fixed) - [**RuleBasedDecisionTrees**](#rulebaseddecisiontrees) - [**RunspaceCore**](#runspacecore) - [**SafeCommandCore**](#safecommandcore) - [**StateMachineCore**](#statemachinecore) - [**Unity-Claude-Core**](#unity-claude-core) - [**WorkflowCore**](#workflowcore) 
### Documentation System

**Modules in this group:** 32

- [**DocumentationAccuracy**](#documentationaccuracy) - [**DocumentationComparison**](#documentationcomparison) - [**SemanticAnalysis-Metrics**](#semanticanalysis-metrics) - [**SemanticAnalysis-PatternDetector**](#semanticanalysis-patterndetector) - [**SemanticAnalysis-PatternDetector-PS51Compatible**](#semanticanalysis-patterndetector-ps51compatible) - [**Unity-Claude-AlertQualityReporting**](#unity-claude-alertqualityreporting) - [**Unity-Claude-APIDocumentation**](#unity-claude-apidocumentation) - [**Unity-Claude-AutonomousDocumentationEngine**](#unity-claude-autonomousdocumentationengine) - [**Unity-Claude-DocumentationAnalytics**](#unity-claude-documentationanalytics) - [**Unity-Claude-DocumentationAutomation**](#unity-claude-documentationautomation) - [**Unity-Claude-DocumentationAutomation-Original**](#unity-claude-documentationautomation-original) - [**Unity-Claude-DocumentationAutomation-Refactored**](#unity-claude-documentationautomation-refactored) - [**Unity-Claude-DocumentationCrossReference**](#unity-claude-documentationcrossreference) - [**Unity-Claude-DocumentationDrift**](#unity-claude-documentationdrift) - [**Unity-Claude-DocumentationDrift-Refactored**](#unity-claude-documentationdrift-refactored) - [**Unity-Claude-DocumentationPipeline**](#unity-claude-documentationpipeline) - [**Unity-Claude-DocumentationQualityAssessment**](#unity-claude-documentationqualityassessment) - [**Unity-Claude-DocumentationQualityAssessment_Original_20250830_193150**](#unity-claude-documentationqualityassessment-original-20250830-193150) - [**Unity-Claude-DocumentationQualityOrchestrator**](#unity-claude-documentationqualityorchestrator) - [**Unity-Claude-DocumentationSuggestions**](#unity-claude-documentationsuggestions) - [**Unity-Claude-DocumentationVersioning**](#unity-claude-documentationversioning) - [**Unity-Claude-IntelligentDocumentationTriggers**](#unity-claude-intelligentdocumentationtriggers) - [**Unity-Claude-SemanticAnalysis**](#unity-claude-semanticanalysis) - [**Unity-Claude-SemanticAnalysis-Architecture**](#unity-claude-semanticanalysis-architecture) - [**Unity-Claude-SemanticAnalysis-Business**](#unity-claude-semanticanalysis-business) - [**Unity-Claude-SemanticAnalysis-Helpers**](#unity-claude-semanticanalysis-helpers) - [**Unity-Claude-SemanticAnalysis-Metrics**](#unity-claude-semanticanalysis-metrics) - [**Unity-Claude-SemanticAnalysis-New**](#unity-claude-semanticanalysis-new) - [**Unity-Claude-SemanticAnalysis-Old**](#unity-claude-semanticanalysis-old) - [**Unity-Claude-SemanticAnalysis-Patterns**](#unity-claude-semanticanalysis-patterns) - [**Unity-Claude-SemanticAnalysis-Purpose**](#unity-claude-semanticanalysis-purpose) - [**Unity-Claude-SemanticAnalysis-Quality**](#unity-claude-semanticanalysis-quality) 
### Integration & Orchestration

**Modules in this group:** 41

- [**BackupIntegration**](#backupintegration) - [**ClaudeIntegration**](#claudeintegration) - [**CompilationIntegration**](#compilationintegration) - [**DecisionEngineIntegration**](#decisionengineintegration) - [**EnhancedPatternIntegration**](#enhancedpatternintegration) - [**IntegrationManagement**](#integrationmanagement) - [**ModuleIntegration**](#moduleintegration) - [**OrchestrationCore**](#orchestrationcore) - [**OrchestrationManager**](#orchestrationmanager) - [**OrchestrationManager-Refactored**](#orchestrationmanager-refactored) - [**OrchestratorCore**](#orchestratorcore) - [**OrchestratorManagement**](#orchestratormanagement) - [**SystemIntegration**](#systemintegration) - [**Unity-Claude-AgentIntegration**](#unity-claude-agentintegration) - [**Unity-Claude-CLIOrchestrator**](#unity-claude-cliorchestrator) - [**Unity-Claude-CLIOrchestrator-Fixed-Simple**](#unity-claude-cliorchestrator-fixed-simple) - [**Unity-Claude-CLIOrchestrator-FullFeatured**](#unity-claude-cliorchestrator-fullfeatured) - [**Unity-Claude-CLIOrchestrator-Original**](#unity-claude-cliorchestrator-original) - [**Unity-Claude-CLIOrchestrator-Original-Backup**](#unity-claude-cliorchestrator-original-backup) - [**Unity-Claude-CLIOrchestrator-Refactored**](#unity-claude-cliorchestrator-refactored) - [**Unity-Claude-CLIOrchestrator-Refactored-Fixed**](#unity-claude-cliorchestrator-refactored-fixed) - [**Unity-Claude-DocumentationQualityOrchestrator**](#unity-claude-documentationqualityorchestrator) - [**Unity-Claude-GovernanceIntegration**](#unity-claude-governanceintegration) - [**Unity-Claude-IntegratedWorkflow**](#unity-claude-integratedworkflow) - [**Unity-Claude-IntegratedWorkflow-Original**](#unity-claude-integratedworkflow-original) - [**Unity-Claude-IntegratedWorkflow-Refactored**](#unity-claude-integratedworkflow-refactored) - [**Unity-Claude-IntegrationEngine**](#unity-claude-integrationengine) - [**Unity-Claude-MasterOrchestrator**](#unity-claude-masterorchestrator) - [**Unity-Claude-MasterOrchestrator-Original**](#unity-claude-masterorchestrator-original) - [**Unity-Claude-MasterOrchestrator-Refactored**](#unity-claude-masterorchestrator-refactored) - [**Unity-Claude-MultiStepOrchestrator**](#unity-claude-multisteporchestrator) - [**Unity-Claude-NotificationIntegration**](#unity-claude-notificationintegration) - [**Unity-Claude-NotificationIntegration-Modular**](#unity-claude-notificationintegration-modular) - [**Unity-Claude-SlackIntegration**](#unity-claude-slackintegration) - [**Unity-Claude-TeamsIntegration**](#unity-claude-teamsintegration) - [**Unity-Claude-TriggerIntegration**](#unity-claude-triggerintegration) - [**UnityIntegration**](#unityintegration) - [**WorkflowCore**](#workflowcore) - [**WorkflowIntegration**](#workflowintegration) - [**WorkflowMonitoring**](#workflowmonitoring) - [**WorkflowOrchestration**](#workfloworchestration) 
### Monitoring & Alerts

**Modules in this group:** 32

- [**FileSystemMonitoring**](#filesystemmonitoring) - [**HealthMonitoring**](#healthmonitoring) - [**IntegratedNotifications**](#integratednotifications) - [**MonitoringLoop**](#monitoringloop) - [**NotificationCore**](#notificationcore) - [**NotificationSystem**](#notificationsystem) - [**ParallelMonitoring**](#parallelmonitoring) - [**PerformanceMonitoring**](#performancemonitoring) - [**ResponseMonitoring**](#responsemonitoring) - [**Unity-Claude-AIAlertClassifier**](#unity-claude-aialertclassifier) - [**Unity-Claude-AlertAnalytics**](#unity-claude-alertanalytics) - [**Unity-Claude-AlertFeedbackCollector**](#unity-claude-alertfeedbackcollector) - [**Unity-Claude-AlertMLOptimizer**](#unity-claude-alertmloptimizer) - [**Unity-Claude-AlertQualityReporting**](#unity-claude-alertqualityreporting) - [**Unity-Claude-AutoGenMonitoring**](#unity-claude-autogenmonitoring) - [**Unity-Claude-EmailNotifications**](#unity-claude-emailnotifications) - [**Unity-Claude-EmailNotifications-SystemNetMail**](#unity-claude-emailnotifications-systemnetmail) - [**Unity-Claude-FileMonitor**](#unity-claude-filemonitor) - [**Unity-Claude-FileMonitor-Fixed**](#unity-claude-filemonitor-fixed) - [**Unity-Claude-IntelligentAlerting**](#unity-claude-intelligentalerting) - [**Unity-Claude-Monitoring**](#unity-claude-monitoring) - [**Unity-Claude-NotificationConfiguration**](#unity-claude-notificationconfiguration) - [**Unity-Claude-NotificationContentEngine**](#unity-claude-notificationcontentengine) - [**Unity-Claude-NotificationIntegration**](#unity-claude-notificationintegration) - [**Unity-Claude-NotificationIntegration-Modular**](#unity-claude-notificationintegration-modular) - [**Unity-Claude-NotificationPreferences**](#unity-claude-notificationpreferences) - [**Unity-Claude-RealTimeMonitoring**](#unity-claude-realtimemonitoring) - [**Unity-Claude-ReliableMonitoring**](#unity-claude-reliablemonitoring) - [**Unity-Claude-ResponseMonitor**](#unity-claude-responsemonitor) - [**Unity-Claude-ResponseMonitoring**](#unity-claude-responsemonitoring) - [**Unity-Claude-WebhookNotifications**](#unity-claude-webhooknotifications) - [**WorkflowMonitoring**](#workflowmonitoring) 
### Parallel Processing

**Modules in this group:** 22

- [**CPG-ThreadSafeOperations**](#cpg-threadsafeoperations) - [**ParallelizationCore**](#parallelizationcore) - [**ParallelMonitoring**](#parallelmonitoring) - [**ParallelProcessorCore**](#parallelprocessorcore) - [**ProductionRunspacePool**](#productionrunspacepool) - [**RunspaceCore**](#runspacecore) - [**RunspaceManagement**](#runspacemanagement) - [**RunspacePoolManagement**](#runspacepoolmanagement) - [**RunspacePoolManager**](#runspacepoolmanager) - [**Unity-Claude-ClaudeParallelization**](#unity-claude-claudeparallelization) - [**Unity-Claude-ConcurrentCollections**](#unity-claude-concurrentcollections) - [**Unity-Claude-ConcurrentProcessor**](#unity-claude-concurrentprocessor) - [**Unity-Claude-ParallelProcessing**](#unity-claude-parallelprocessing) - [**Unity-Claude-ParallelProcessor**](#unity-claude-parallelprocessor) - [**Unity-Claude-ParallelProcessor-Original**](#unity-claude-parallelprocessor-original) - [**Unity-Claude-ParallelProcessor-Refactored**](#unity-claude-parallelprocessor-refactored) - [**Unity-Claude-RunspaceManagement**](#unity-claude-runspacemanagement) - [**Unity-Claude-RunspaceManagement-Original**](#unity-claude-runspacemanagement-original) - [**Unity-Claude-RunspaceManagement-Refactored**](#unity-claude-runspacemanagement-refactored) - [**Unity-Claude-UnityParallelization**](#unity-claude-unityparallelization) - [**Unity-Claude-UnityParallelization-Original**](#unity-claude-unityparallelization-original) - [**Unity-Claude-UnityParallelization-Refactored**](#unity-claude-unityparallelization-refactored) 
### Safety & Validation

**Modules in this group:** 8

- [**ApprovalRequests**](#approvalrequests) - [**HITLCore**](#hitlcore) - [**SafetyValidationFramework**](#safetyvalidationframework) - [**Unity-Claude-HITL**](#unity-claude-hitl) - [**Unity-Claude-HITL-Original**](#unity-claude-hitl-original) - [**Unity-Claude-HITL-Refactored**](#unity-claude-hitl-refactored) - [**Unity-Claude-Safety**](#unity-claude-safety) - [**ValidationEngine**](#validationengine) 
### Unity Integration

**Modules in this group:** 168

- [**CompilationIntegration**](#compilationintegration) - [**Unity-Claude-AgentIntegration**](#unity-claude-agentintegration) - [**Unity-Claude-AIAlertClassifier**](#unity-claude-aialertclassifier) - [**Unity-Claude-AlertAnalytics**](#unity-claude-alertanalytics) - [**Unity-Claude-AlertFeedbackCollector**](#unity-claude-alertfeedbackcollector) - [**Unity-Claude-AlertMLOptimizer**](#unity-claude-alertmloptimizer) - [**Unity-Claude-AlertQualityReporting**](#unity-claude-alertqualityreporting) - [**Unity-Claude-APIDocumentation**](#unity-claude-apidocumentation) - [**Unity-Claude-AST-Enhanced**](#unity-claude-ast-enhanced) - [**Unity-Claude-AutoGen**](#unity-claude-autogen) - [**Unity-Claude-AutoGenMonitoring**](#unity-claude-autogenmonitoring) - [**Unity-Claude-AutonomousAgent-Refactored**](#unity-claude-autonomousagent-refactored) - [**Unity-Claude-AutonomousDocumentationEngine**](#unity-claude-autonomousdocumentationengine) - [**Unity-Claude-AutonomousStateTracker**](#unity-claude-autonomousstatetracker) - [**Unity-Claude-AutonomousStateTracker-Enhanced**](#unity-claude-autonomousstatetracker-enhanced) - [**Unity-Claude-AutonomousStateTracker-Enhanced-Refactored**](#unity-claude-autonomousstatetracker-enhanced-refactored) - [**Unity-Claude-Cache**](#unity-claude-cache) - [**Unity-Claude-Cache-Fixed**](#unity-claude-cache-fixed) - [**Unity-Claude-Cache-Original**](#unity-claude-cache-original) - [**Unity-Claude-ChangeIntelligence**](#unity-claude-changeintelligence) - [**Unity-Claude-ClaudeParallelization**](#unity-claude-claudeparallelization) - [**Unity-Claude-CLIOrchestrator**](#unity-claude-cliorchestrator) - [**Unity-Claude-CLIOrchestrator-Fixed-Simple**](#unity-claude-cliorchestrator-fixed-simple) - [**Unity-Claude-CLIOrchestrator-FullFeatured**](#unity-claude-cliorchestrator-fullfeatured) - [**Unity-Claude-CLIOrchestrator-Original**](#unity-claude-cliorchestrator-original) - [**Unity-Claude-CLIOrchestrator-Original-Backup**](#unity-claude-cliorchestrator-original-backup) - [**Unity-Claude-CLIOrchestrator-Refactored**](#unity-claude-cliorchestrator-refactored) - [**Unity-Claude-CLIOrchestrator-Refactored-Fixed**](#unity-claude-cliorchestrator-refactored-fixed) - [**Unity-Claude-CLISubmission**](#unity-claude-clisubmission) - [**Unity-Claude-CLISubmission-Enhanced**](#unity-claude-clisubmission-enhanced) - [**Unity-Claude-CodeQL**](#unity-claude-codeql) - [**Unity-Claude-ConcurrentCollections**](#unity-claude-concurrentcollections) - [**Unity-Claude-ConcurrentProcessor**](#unity-claude-concurrentprocessor) - [**Unity-Claude-Core**](#unity-claude-core) - [**Unity-Claude-CPG**](#unity-claude-cpg) - [**Unity-Claude-CPG-ASTConverter**](#unity-claude-cpg-astconverter) - [**Unity-Claude-CPG-Original**](#unity-claude-cpg-original) - [**Unity-Claude-CPG-Refactored**](#unity-claude-cpg-refactored) - [**Unity-Claude-CrossLanguage**](#unity-claude-crosslanguage) - [**Unity-Claude-DecisionEngine**](#unity-claude-decisionengine) - [**Unity-Claude-DecisionEngine-Bayesian**](#unity-claude-decisionengine-bayesian) - [**Unity-Claude-DecisionEngine-Original**](#unity-claude-decisionengine-original) - [**Unity-Claude-DecisionEngine-Refactored**](#unity-claude-decisionengine-refactored) - [**Unity-Claude-DocumentationAnalytics**](#unity-claude-documentationanalytics) - [**Unity-Claude-DocumentationAutomation**](#unity-claude-documentationautomation) - [**Unity-Claude-DocumentationAutomation-Original**](#unity-claude-documentationautomation-original) - [**Unity-Claude-DocumentationAutomation-Refactored**](#unity-claude-documentationautomation-refactored) - [**Unity-Claude-DocumentationCrossReference**](#unity-claude-documentationcrossreference) - [**Unity-Claude-DocumentationDrift**](#unity-claude-documentationdrift) - [**Unity-Claude-DocumentationDrift-Refactored**](#unity-claude-documentationdrift-refactored) - [**Unity-Claude-DocumentationPipeline**](#unity-claude-documentationpipeline) - [**Unity-Claude-DocumentationQualityAssessment**](#unity-claude-documentationqualityassessment) - [**Unity-Claude-DocumentationQualityAssessment_Original_20250830_193150**](#unity-claude-documentationqualityassessment-original-20250830-193150) - [**Unity-Claude-DocumentationQualityOrchestrator**](#unity-claude-documentationqualityorchestrator) - [**Unity-Claude-DocumentationSuggestions**](#unity-claude-documentationsuggestions) - [**Unity-Claude-DocumentationVersioning**](#unity-claude-documentationversioning) - [**Unity-Claude-EmailNotifications**](#unity-claude-emailnotifications) - [**Unity-Claude-EmailNotifications-SystemNetMail**](#unity-claude-emailnotifications-systemnetmail) - [**Unity-Claude-ErrorHandling**](#unity-claude-errorhandling) - [**Unity-Claude-Errors**](#unity-claude-errors) - [**Unity-Claude-EventLog**](#unity-claude-eventlog) - [**Unity-Claude-FileMonitor**](#unity-claude-filemonitor) - [**Unity-Claude-FileMonitor-Fixed**](#unity-claude-filemonitor-fixed) - [**Unity-Claude-FixEngine**](#unity-claude-fixengine) - [**Unity-Claude-GitHub**](#unity-claude-github) - [**Unity-Claude-GovernanceIntegration**](#unity-claude-governanceintegration) - [**Unity-Claude-HITL**](#unity-claude-hitl) - [**Unity-Claude-HITL-Original**](#unity-claude-hitl-original) - [**Unity-Claude-HITL-Refactored**](#unity-claude-hitl-refactored) - [**Unity-Claude-IncrementalProcessor**](#unity-claude-incrementalprocessor) - [**Unity-Claude-IncrementalProcessor-Fixed**](#unity-claude-incrementalprocessor-fixed) - [**Unity-Claude-IntegratedWorkflow**](#unity-claude-integratedworkflow) - [**Unity-Claude-IntegratedWorkflow-Original**](#unity-claude-integratedworkflow-original) - [**Unity-Claude-IntegratedWorkflow-Refactored**](#unity-claude-integratedworkflow-refactored) - [**Unity-Claude-IntegrationEngine**](#unity-claude-integrationengine) - [**Unity-Claude-IntelligentAlerting**](#unity-claude-intelligentalerting) - [**Unity-Claude-IntelligentDocumentationTriggers**](#unity-claude-intelligentdocumentationtriggers) - [**Unity-Claude-IPC**](#unity-claude-ipc) - [**Unity-Claude-IPC-Bidirectional**](#unity-claude-ipc-bidirectional) - [**Unity-Claude-IPC-Bidirectional-Fixed**](#unity-claude-ipc-bidirectional-fixed) - [**Unity-Claude-LangGraphBridge**](#unity-claude-langgraphbridge) - [**Unity-Claude-Learning**](#unity-claude-learning) - [**Unity-Claude-Learning-Analytics**](#unity-claude-learning-analytics) - [**Unity-Claude-Learning-Original**](#unity-claude-learning-original) - [**Unity-Claude-Learning-Refactored**](#unity-claude-learning-refactored) - [**Unity-Claude-Learning-Simple**](#unity-claude-learning-simple) - [**Unity-Claude-LLM**](#unity-claude-llm) - [**Unity-Claude-MachineLearning**](#unity-claude-machinelearning) - [**Unity-Claude-MasterOrchestrator**](#unity-claude-masterorchestrator) - [**Unity-Claude-MasterOrchestrator-Original**](#unity-claude-masterorchestrator-original) - [**Unity-Claude-MasterOrchestrator-Refactored**](#unity-claude-masterorchestrator-refactored) - [**Unity-Claude-MemoryAnalysis**](#unity-claude-memoryanalysis) - [**Unity-Claude-MessageQueue**](#unity-claude-messagequeue) - [**Unity-Claude-Monitoring**](#unity-claude-monitoring) - [**Unity-Claude-MultiStepOrchestrator**](#unity-claude-multisteporchestrator) - [**Unity-Claude-NotificationConfiguration**](#unity-claude-notificationconfiguration) - [**Unity-Claude-NotificationContentEngine**](#unity-claude-notificationcontentengine) - [**Unity-Claude-NotificationIntegration**](#unity-claude-notificationintegration) - [**Unity-Claude-NotificationIntegration-Modular**](#unity-claude-notificationintegration-modular) - [**Unity-Claude-NotificationPreferences**](#unity-claude-notificationpreferences) - [**Unity-Claude-ObsolescenceDetection**](#unity-claude-obsolescencedetection) - [**Unity-Claude-ObsolescenceDetection-Refactored**](#unity-claude-obsolescencedetection-refactored) - [**Unity-Claude-Ollama**](#unity-claude-ollama) - [**Unity-Claude-Ollama-Enhanced**](#unity-claude-ollama-enhanced) - [**Unity-Claude-Ollama-Optimized**](#unity-claude-ollama-optimized) - [**Unity-Claude-Ollama-Optimized-Fixed**](#unity-claude-ollama-optimized-fixed) - [**Unity-Claude-ParallelProcessing**](#unity-claude-parallelprocessing) - [**Unity-Claude-ParallelProcessor**](#unity-claude-parallelprocessor) - [**Unity-Claude-ParallelProcessor-Original**](#unity-claude-parallelprocessor-original) - [**Unity-Claude-ParallelProcessor-Refactored**](#unity-claude-parallelprocessor-refactored) - [**Unity-Claude-PerformanceOptimizer**](#unity-claude-performanceoptimizer) - [**Unity-Claude-PerformanceOptimizer-Original**](#unity-claude-performanceoptimizer-original) - [**Unity-Claude-PerformanceOptimizer-Refactored**](#unity-claude-performanceoptimizer-refactored) - [**Unity-Claude-PredictiveAnalysis**](#unity-claude-predictiveanalysis) - [**Unity-Claude-PredictiveAnalysis-Original**](#unity-claude-predictiveanalysis-original) - [**Unity-Claude-PredictiveAnalysis-Refactored**](#unity-claude-predictiveanalysis-refactored) - [**Unity-Claude-ProactiveMaintenanceEngine**](#unity-claude-proactivemaintenanceengine) - [**Unity-Claude-RealTimeAnalysis**](#unity-claude-realtimeanalysis) - [**Unity-Claude-RealTimeMonitoring**](#unity-claude-realtimemonitoring) - [**Unity-Claude-RealTimeOptimizer**](#unity-claude-realtimeoptimizer) - [**Unity-Claude-RecompileSignaling**](#unity-claude-recompilesignaling) - [**Unity-Claude-ReliabilityManager**](#unity-claude-reliabilitymanager) - [**Unity-Claude-ReliableMonitoring**](#unity-claude-reliablemonitoring) - [**Unity-Claude-RepoAnalyst**](#unity-claude-repoanalyst) - [**Unity-Claude-ResourceOptimizer**](#unity-claude-resourceoptimizer) - [**Unity-Claude-ResponseMonitor**](#unity-claude-responsemonitor) - [**Unity-Claude-ResponseMonitoring**](#unity-claude-responsemonitoring) - [**Unity-Claude-RunspaceManagement**](#unity-claude-runspacemanagement) - [**Unity-Claude-RunspaceManagement-Original**](#unity-claude-runspacemanagement-original) - [**Unity-Claude-RunspaceManagement-Refactored**](#unity-claude-runspacemanagement-refactored) - [**Unity-Claude-Safety**](#unity-claude-safety) - [**Unity-Claude-ScalabilityEnhancements**](#unity-claude-scalabilityenhancements) - [**Unity-Claude-ScalabilityEnhancements-Original**](#unity-claude-scalabilityenhancements-original) - [**Unity-Claude-ScalabilityEnhancements-Refactored**](#unity-claude-scalabilityenhancements-refactored) - [**Unity-Claude-ScalabilityOptimizer**](#unity-claude-scalabilityoptimizer) - [**Unity-Claude-SemanticAnalysis**](#unity-claude-semanticanalysis) - [**Unity-Claude-SemanticAnalysis-Architecture**](#unity-claude-semanticanalysis-architecture) - [**Unity-Claude-SemanticAnalysis-Business**](#unity-claude-semanticanalysis-business) - [**Unity-Claude-SemanticAnalysis-Helpers**](#unity-claude-semanticanalysis-helpers) - [**Unity-Claude-SemanticAnalysis-Metrics**](#unity-claude-semanticanalysis-metrics) - [**Unity-Claude-SemanticAnalysis-New**](#unity-claude-semanticanalysis-new) - [**Unity-Claude-SemanticAnalysis-Old**](#unity-claude-semanticanalysis-old) - [**Unity-Claude-SemanticAnalysis-Patterns**](#unity-claude-semanticanalysis-patterns) - [**Unity-Claude-SemanticAnalysis-Purpose**](#unity-claude-semanticanalysis-purpose) - [**Unity-Claude-SemanticAnalysis-Quality**](#unity-claude-semanticanalysis-quality) - [**Unity-Claude-SessionManager**](#unity-claude-sessionmanager) - [**Unity-Claude-SlackIntegration**](#unity-claude-slackintegration) - [**Unity-Claude-SystemCoordinator**](#unity-claude-systemcoordinator) - [**Unity-Claude-SystemStatus**](#unity-claude-systemstatus) - [**Unity-Claude-TeamsIntegration**](#unity-claude-teamsintegration) - [**Unity-Claude-TreeSitter**](#unity-claude-treesitter) - [**Unity-Claude-TriggerConditions**](#unity-claude-triggerconditions) - [**Unity-Claude-TriggerIntegration**](#unity-claude-triggerintegration) - [**Unity-Claude-TriggerManager**](#unity-claude-triggermanager) - [**Unity-Claude-UnityParallelization**](#unity-claude-unityparallelization) - [**Unity-Claude-UnityParallelization-Original**](#unity-claude-unityparallelization-original) - [**Unity-Claude-UnityParallelization-Refactored**](#unity-claude-unityparallelization-refactored) - [**Unity-Claude-WebhookNotifications**](#unity-claude-webhooknotifications) - [**Unity-Claude-WindowDetection**](#unity-claude-windowdetection) - [**Unity-Claude-WindowDetection-Enhanced**](#unity-claude-windowdetection-enhanced) - [**Unity-TestAutomation**](#unity-testautomation) - [**UnityBuildOperations**](#unitybuildoperations) - [**UnityCommands**](#unitycommands) - [**UnityIntegration**](#unityintegration) - [**UnityLogAnalysis**](#unityloganalysis) - [**UnityPerformanceAnalysis**](#unityperformanceanalysis) - [**UnityProjectOperations**](#unityprojectoperations) - [**UnityReportingOperations**](#unityreportingoperations)

## 🕸️ Module Network

### Primary Communication Patterns

1. **Event Broadcasting**
   - Modules publish events to a central event bus
   - Subscribers react to relevant events asynchronously
   - Enables loose coupling between components

2. **Pipeline Processing**
   - Data flows through transformation pipelines
   - Each module adds value or filters data
   - Results aggregate at orchestration points

3. **Request-Response**
   - Synchronous calls for immediate operations
   - Used for critical path operations
   - Includes timeout and retry mechanisms

### Dependency Flow

\\\mermaid
graph TB
    subgraph "External Systems"
        Unity[Unity Editor]
        Claude[Claude AI]
        GitHub[GitHub API]
    end
    
    subgraph "Core Layer"
        Core[Core Modules]
        Config[Configuration]
        Cache[Cache System]
    end
    
    subgraph "Processing Layer"
        Parallel[Parallel Processing]
        Queue[Message Queue]
        Events[Event System]
    end
    
    subgraph "Intelligence Layer"
        Decision[Decision Engine]
        Learning[ML/Learning]
        Pattern[Pattern Recognition]
    end
    
    subgraph "Action Layer"
        Safety[Safety Framework]
        Execute[Execution Engine]
        Monitor[Monitoring]
    end
    
    Unity --> Core
    Core --> Processing Layer
    Processing Layer --> Intelligence Layer
    Intelligence Layer --> Claude
    Intelligence Layer --> Action Layer
    Action Layer --> Safety
    Safety --> Execute
    Execute --> GitHub
    Monitor --> Events
\\\

## 📚 Module Catalog


### ActionExecutionEngine

[⬆ Back to Contents](#-table-of-contents)

Specialized module providing targeted functionality for the Unity-Claude automation system. Integrates with the broader architecture to deliver specific capabilities and enhance overall system functionality.

**Module Statistics:**
- Functions: 11
- Dependencies: 1 modules


**Module Information:**
- **Path:** `Modules\Unity-Claude-CLIOrchestrator\Core\ActionExecutionEngine.psm1`
- **Size:** 23.53 KB
- **Last Modified:** 2025-08-25 13:45
- **Total Functions:** 11
- **Exported Functions:** 1




**Key Functions:**
- **Write-ExecutionLog** - Line 70 - **Test-ActionSafety** - Line 104 - **Test-SafeFilePath** - Line 174 - **Test-SafeCommand** - Line 215 - **New-ConstrainedRunspace** - Line 263
- *...and 6 more functions*

--- 
### AgentCore

[⬆ Back to Contents](#-table-of-contents)

Core infrastructure module providing fundamental functionality for the Unity-Claude system. This module serves as the foundation for other components, offering essential utilities, configuration management, and base services that other modules depend upon.

**Module Statistics:**
- Functions: 6


**Module Information:**
- **Path:** `Modules\Unity-Claude-AutonomousAgent\Core\AgentCore.psm1`
- **Size:** 9.11 KB
- **Last Modified:** 2025-08-20 17:25
- **Total Functions:** 6
- **Exported Functions:** 1




**Key Functions:**
- **Initialize-AgentCore** - Line 65 - **Get-AgentConfig** - Line 94 - **Set-AgentConfig** - Line 117 - **Get-AgentState** - Line 145 - **Set-AgentState** - Line 168
- *...and 1 more functions*

--- 
### AgentLogging

[⬆ Back to Contents](#-table-of-contents)

Specialized module providing targeted functionality for the Unity-Claude automation system. Integrates with the broader architecture to deliver specific capabilities and enhance overall system functionality.

**Module Statistics:**
- Functions: 8


**Module Information:**
- **Path:** `Modules\Unity-Claude-AutonomousAgent\Core\AgentLogging.psm1`
- **Size:** 13.12 KB
- **Last Modified:** 2025-08-26 11:46
- **Total Functions:** 7
- **Exported Functions:** 1




**Key Functions:**
- **Write-AgentLog** - Line 31 - **Initialize-AgentLogging** - Line 147 - **Invoke-LogRotation** - Line 196 - **Remove-OldLogFiles** - Line 225 - **Get-AgentLogPath** - Line 257
- *...and 2 more functions*

--- 
### AIAssessment

[⬆ Back to Contents](#-table-of-contents)

Artificial Intelligence integration module that bridges PowerShell automation with AI services. Provides intelligent error analysis, pattern recognition, and automated decision-making capabilities through Claude AI or local LLM integration.

**Module Statistics:**
- Functions: 2


**Module Information:**
- **Path:** `Modules\Unity-Claude-DocumentationQualityAssessment\Components\AIAssessment.psm1`
- **Size:** 0.87 KB
- **Last Modified:** 2025-08-30 19:31
- **Total Functions:** 2
- **Exported Functions:** 3




**Key Functions:**
- **Parse-AIQualityResponse** - Line 13 - **Initialize-AIContentAssessor** - Line 26


--- 
### AnalysisLogging

[⬆ Back to Contents](#-table-of-contents)

Specialized module providing targeted functionality for the Unity-Claude automation system. Integrates with the broader architecture to deliver specific capabilities and enhance overall system functionality.

**Module Statistics:**
- Functions: 4


**Module Information:**
- **Path:** `Modules\Unity-Claude-CLIOrchestrator\Core\Components\AnalysisLogging.psm1`
- **Size:** 5.72 KB
- **Last Modified:** 2025-08-26 11:46
- **Total Functions:** 4
- **Exported Functions:** 1




**Key Functions:**
- **Write-AnalysisLog** - Line 15 - **Set-AnalysisLogPath** - Line 57 - **Get-AnalysisLogPath** - Line 68 - **Test-AnalysisLogging** - Line 75


--- 
### AnalyticsReporting

[⬆ Back to Contents](#-table-of-contents)

Specialized module providing targeted functionality for the Unity-Claude automation system. Integrates with the broader architecture to deliver specific capabilities and enhance overall system functionality.

**Module Statistics:**
- Functions: 9
- Dependencies: 2 modules


**Module Information:**
- **Path:** `Modules\Unity-Claude-PredictiveAnalysis\Core\AnalyticsReporting.psm1`
- **Size:** 24.71 KB
- **Last Modified:** 2025-08-26 11:46
- **Total Functions:** 9
- **Exported Functions:** 1


**Dependencies:**
- `-Name` (external) - `-Name` (external)


**Key Functions:**
- **Get-ROIAnalysis** - Line 33 - **Estimate-RefactoringEffort** - Line 103 - **Get-PriorityActions** - Line 173 - **Get-HistoricalMetrics** - Line 238 - **Get-ComplexityTrend** - Line 295
- *...and 4 more functions*

--- 
### ApprovalRequests

[⬆ Back to Contents](#-table-of-contents)

Specialized module providing targeted functionality for the Unity-Claude automation system. Integrates with the broader architecture to deliver specific capabilities and enhance overall system functionality.

**Module Statistics:**
- Functions: 5
- Dependencies: 2 modules


**Module Information:**
- **Path:** `Modules\Unity-Claude-HITL\Core\ApprovalRequests.psm1`
- **Size:** 10.46 KB
- **Last Modified:** 2025-08-26 11:46
- **Total Functions:** 5
- **Exported Functions:** 1


**Dependencies:**
- `$coreModule` (external) - `$tokenModule` (external)


**Key Functions:**
- **New-ApprovalRequest** - Line 14 - **Get-ApprovalStatus** - Line 132 - **Set-ApprovalEscalation** - Line 162 - **Get-PendingApprovals** - Line 203 - **Update-ApprovalStatus** - Line 219


--- 
### ASTAnalysis

[⬆ Back to Contents](#-table-of-contents)

Specialized module providing targeted functionality for the Unity-Claude automation system. Integrates with the broader architecture to deliver specific capabilities and enhance overall system functionality.

**Module Statistics:**
- Functions: 5
- Dependencies: 1 modules


**Module Information:**
- **Path:** `Modules\Unity-Claude-Learning\Core\ASTAnalysis.psm1`
- **Size:** 10.33 KB
- **Last Modified:** 2025-08-26 11:46
- **Total Functions:** 4
- **Exported Functions:** 1


**Dependencies:**
- `$CorePath` (external)


**Key Functions:**
- **Get-CodeAST** - Line 11 - **Find-CodePattern** - Line 85 - **Get-ASTStatistics** - Line 154 - **Compare-ASTStructures** - Line 199


--- 
### AutoGenerationTriggers

[⬆ Back to Contents](#-table-of-contents)

Specialized module providing targeted functionality for the Unity-Claude automation system. Integrates with the broader architecture to deliver specific capabilities and enhance overall system functionality.

**Module Statistics:**
- Functions: 11
- Dependencies: 5 modules


**Module Information:**
- **Path:** `Modules\Unity-Claude-Enhanced-DocumentationGenerators\Core\AutoGenerationTriggers.psm1`
- **Size:** 25.08 KB
- **Last Modified:** 2025-08-28 17:06
- **Total Functions:** 11
- **Exported Functions:** 1


**Dependencies:**
- `$PSScriptRoot\..\..\Modules\Unity-Claude-Enhanced-DocumentationGenerators\Unity-Claude-Enhanced-DocumentationGenerators.psd1` (external) - `$PSScriptRoot\..\..\Modules\Unity-Claude-Enhanced-DocumentationGenerators\Unity-Claude-Enhanced-DocumentationGenerators.psd1` (external) - `$PSScriptRoot\..\..\Modules\Unity-Claude-Enhanced-DocumentationGenerators\Unity-Claude-Enhanced-DocumentationGenerators.psd1` (external) - `$PSScriptRoot\Templates-PerLanguage.psm1` (external) - `$PSScriptRoot\..\Unity-Claude-Enhanced-DocumentationGenerators.psd1` (external)


**Key Functions:**
- **Initialize-DocumentationTriggers** - Line 15 - **Start-FileWatcher** - Line 76 - **Stop-FileWatcher** - Line 172 - **Install-GitHooks** - Line 212 - **Uninstall-GitHooks** - Line 442
- *...and 6 more functions*

--- 
### AutomationEngine

[⬆ Back to Contents](#-table-of-contents)

Specialized module providing targeted functionality for the Unity-Claude automation system. Integrates with the broader architecture to deliver specific capabilities and enhance overall system functionality.

**Module Statistics:**
- Functions: 4


**Module Information:**
- **Path:** `Modules\Unity-Claude-DocumentationAutomation\Core\AutomationEngine.psm1`
- **Size:** 10.97 KB
- **Last Modified:** 2025-08-26 11:46
- **Total Functions:** 4
- **Exported Functions:** 1




**Key Functions:**
- **Start-DocumentationAutomation** - Line 20 - **Stop-DocumentationAutomation** - Line 102 - **Test-DocumentationSync** - Line 142 - **Get-DocumentationStatus** - Line 224


--- 
### AutonomousFeedbackLoop

[⬆ Back to Contents](#-table-of-contents)

Specialized module providing targeted functionality for the Unity-Claude automation system. Integrates with the broader architecture to deliver specific capabilities and enhance overall system functionality.

**Module Statistics:**
- Functions: 5
- Dependencies: 3 modules


**Module Information:**
- **Path:** `Modules\Unity-Claude-MasterOrchestrator\Core\AutonomousFeedbackLoop.psm1`
- **Size:** 12.19 KB
- **Last Modified:** 2025-08-26 11:46
- **Total Functions:** 5
- **Exported Functions:** 1


**Dependencies:**
- `$PSScriptRoot\OrchestratorCore.psm1` (external) - `$PSScriptRoot\ModuleIntegration.psm1` (external) - `$PSScriptRoot\EventProcessing.psm1` (external)


**Key Functions:**
- **Start-AutonomousFeedbackLoop** - Line 22 - **Stop-AutonomousFeedbackLoop** - Line 102 - **Get-FeedbackLoopStatus** - Line 152 - **Test-AutonomousFeedbackLoop** - Line 184 - **Resume-AutonomousFeedbackLoop** - Line 257


--- 
### AutonomousOperations

[⬆ Back to Contents](#-table-of-contents)

Specialized module providing targeted functionality for the Unity-Claude automation system. Integrates with the broader architecture to deliver specific capabilities and enhance overall system functionality.

**Module Statistics:**
- Functions: 4


**Module Information:**
- **Path:** `Modules\Unity-Claude-CLIOrchestrator\Core\AutonomousOperations.psm1`
- **Size:** 34.64 KB
- **Last Modified:** 2025-08-27 14:32
- **Total Functions:** 4
- **Exported Functions:** 1




**Key Functions:**
- **New-AutonomousPrompt** - Line 39 - **Get-ActionResultSummary** - Line 135 - **Process-ResponseFile** - Line 308 - **Invoke-AutonomousExecutionLoop** - Line 544


--- 
### BackgroundJobQueue

[⬆ Back to Contents](#-table-of-contents)

Specialized module providing targeted functionality for the Unity-Claude automation system. Integrates with the broader architecture to deliver specific capabilities and enhance overall system functionality.

**Module Statistics:**
- Functions: 8
- Classes: 1


**Module Information:**
- **Path:** `Modules\Unity-Claude-ScalabilityEnhancements\Core\BackgroundJobQueue.psm1`
- **Size:** 11.85 KB
- **Last Modified:** 2025-08-26 11:46
- **Total Functions:** 15
- **Exported Functions:** 1




**Key Functions:**
- **BackgroundJobQueue** - Line 18 - **AddJob** - Line 28 - **StartProcessing** - Line 47 - **ProcessJobs** - Line 63 - **ExecuteJob** - Line 81
- *...and 10 more functions*

--- 
### BackupIntegration

[⬆ Back to Contents](#-table-of-contents)

Specialized module providing targeted functionality for the Unity-Claude automation system. Integrates with the broader architecture to deliver specific capabilities and enhance overall system functionality.

**Module Statistics:**
- Functions: 8


**Module Information:**
- **Path:** `Modules\Unity-Claude-DocumentationAutomation\Core\BackupIntegration.psm1`
- **Size:** 30.36 KB
- **Last Modified:** 2025-08-26 11:46
- **Total Functions:** 8
- **Exported Functions:** 1




**Key Functions:**
- **New-DocumentationBackup** - Line 20 - **Restore-DocumentationBackup** - Line 93 - **Get-DocumentationHistory** - Line 175 - **Test-RollbackCapability** - Line 238 - **Sync-WithPredictiveAnalysis** - Line 355
- *...and 3 more functions*

--- 
### BatchProcessingEngine

[⬆ Back to Contents](#-table-of-contents)

Specialized module providing targeted functionality for the Unity-Claude automation system. Integrates with the broader architecture to deliver specific capabilities and enhance overall system functionality.

**Module Statistics:**
- Functions: 2
- Classes: 1
- Dependencies: 4 modules


**Module Information:**
- **Path:** `Modules\Unity-Claude-ParallelProcessor\Core\BatchProcessingEngine.psm1`
- **Size:** 22.88 KB
- **Last Modified:** 2025-08-26 11:46
- **Total Functions:** 13
- **Exported Functions:** 1


**Dependencies:**
- `$PSScriptRoot\ParallelProcessorCore.psm1` (external) - `$PSScriptRoot\RunspacePoolManager.psm1` (external) - `$PSScriptRoot\JobScheduler.psm1` (external) - `$PSScriptRoot\StatisticsTracker.psm1` (external)


**Key Functions:**
- **BatchProcessingEngine** - Line 30 - **Start** - Line 66 - **AddItems** - Line 196 - **AddItem** - Line 217 - **CompleteAdding** - Line 222
- *...and 8 more functions*

--- 
### BayesianConfidenceEngine

[⬆ Back to Contents](#-table-of-contents)

Specialized module providing targeted functionality for the Unity-Claude automation system. Integrates with the broader architecture to deliver specific capabilities and enhance overall system functionality.

**Module Statistics:**
- Functions: 15


**Module Information:**
- **Path:** `Modules\Unity-Claude-CLIOrchestrator\Core\BayesianConfidenceEngine.psm1`
- **Size:** 24.86 KB
- **Last Modified:** 2025-08-26 11:46
- **Total Functions:** 15
- **Exported Functions:** 1




**Key Functions:**
- **Calculate-OverallConfidence** - Line 71 - **Get-BayesianRecommendationConfidence** - Line 154 - **Get-BayesianConfidence** - Line 190 - **Get-PositionWeightMatrixScore** - Line 249 - **Get-KeySimilarityScore** - Line 298
- *...and 10 more functions*

--- 
### BayesianConfiguration

[⬆ Back to Contents](#-table-of-contents)

Specialized module providing targeted functionality for the Unity-Claude automation system. Integrates with the broader architecture to deliver specific capabilities and enhance overall system functionality.

**Module Statistics:**
- Functions: 0


**Module Information:**
- **Path:** `Modules\Unity-Claude-CLIOrchestrator\Core\DecisionEngine-Bayesian\BayesianConfiguration.psm1`
- **Size:** 4.21 KB
- **Last Modified:** 2025-08-26 11:46
- **Total Functions:** 0






--- 
### BayesianInference

[⬆ Back to Contents](#-table-of-contents)

Specialized module providing targeted functionality for the Unity-Claude automation system. Integrates with the broader architecture to deliver specific capabilities and enhance overall system functionality.

**Module Statistics:**
- Functions: 6


**Module Information:**
- **Path:** `Modules\Unity-Claude-CLIOrchestrator\Core\DecisionEngine-Bayesian\BayesianInference.psm1`
- **Size:** 11.82 KB
- **Last Modified:** 2025-08-26 11:46
- **Total Functions:** 6
- **Exported Functions:** 6




**Key Functions:**
- **Invoke-BayesianConfidenceAdjustment** - Line 9 - **Get-BayesianPrior** - Line 95 - **Calculate-BayesianLikelihood** - Line 126 - **Calculate-BayesianEvidence** - Line 157 - **Calculate-ContextualAdjustment** - Line 187
- *...and 1 more functions*

--- 
### CircuitBreaker

[⬆ Back to Contents](#-table-of-contents)

Specialized module providing targeted functionality for the Unity-Claude automation system. Integrates with the broader architecture to deliver specific capabilities and enhance overall system functionality.

**Module Statistics:**
- Functions: 8
- Dependencies: 1 modules


**Module Information:**
- **Path:** `Modules\Unity-Claude-CLIOrchestrator\Core\Components\CircuitBreaker.psm1`
- **Size:** 11.48 KB
- **Last Modified:** 2025-08-26 11:46
- **Total Functions:** 8
- **Exported Functions:** 1


**Dependencies:**
- `$loggingPath` (external)


**Key Functions:**
- **Write-AnalysisLog** - Line 17 - **Test-CircuitBreakerState** - Line 46 - **Update-CircuitBreakerState** - Line 73 - **Reset-CircuitBreakerState** - Line 101 - **Get-CircuitBreakerState** - Line 112
- *...and 3 more functions*

--- 
### Classification

[⬆ Back to Contents](#-table-of-contents)

Specialized module providing targeted functionality for the Unity-Claude automation system. Integrates with the broader architecture to deliver specific capabilities and enhance overall system functionality.

**Module Statistics:**
- Functions: 8
- Dependencies: 1 modules


**Module Information:**
- **Path:** `Modules\Unity-Claude-AutonomousAgent\Parsing\Classification.psm1`
- **Size:** 28.04 KB
- **Last Modified:** 2025-08-20 17:25
- **Total Functions:** 8
- **Exported Functions:** 1


**Dependencies:**
- `(Join-Path` (external)


**Key Functions:**
- **Invoke-ResponseClassification** - Line 147 - **Invoke-DecisionTreeClassification** - Line 227 - **Test-NodeCondition** - Line 308 - **Get-ResponseIntent** - Line 375 - **Get-ResponseSentiment** - Line 430
- *...and 3 more functions*

--- 
### ClaudeIntegration

[⬆ Back to Contents](#-table-of-contents)

Specialized module providing targeted functionality for the Unity-Claude automation system. Integrates with the broader architecture to deliver specific capabilities and enhance overall system functionality.

**Module Statistics:**
- Functions: 6
- Dependencies: 2 modules


**Module Information:**
- **Path:** `Modules\Unity-Claude-AutonomousAgent\Integration\ClaudeIntegration.psm1`
- **Size:** 12.77 KB
- **Last Modified:** 2025-08-20 17:25
- **Total Functions:** 4
- **Exported Functions:** 1


**Dependencies:**
- `(Join-Path` (external) - `$cliSubmissionPath` (external)


**Key Functions:**
- **Submit-PromptToClaude** - Line 16 - **New-FollowUpPrompt** - Line 90 - **Submit-ToClaude** - Line 164 - **Get-ClaudeResponseStatus** - Line 235


--- 
### CLIAutomation

[⬆ Back to Contents](#-table-of-contents)

Specialized module providing targeted functionality for the Unity-Claude automation system. Integrates with the broader architecture to deliver specific capabilities and enhance overall system functionality.

**Module Statistics:**
- Functions: 15
- Classes: 1


**Module Information:**
- **Path:** `Modules\Execution\CLIAutomation.psm1`
- **Size:** 27.25 KB
- **Last Modified:** 2025-08-20 17:25
- **Total Functions:** 15
- **Exported Functions:** 1




**Key Functions:**
- **Write-CLILog** - Line 64 - **Test-ProcessExists** - Line 87 - **Get-ClaudeWindow** - Line 101 - **Set-WindowFocus** - Line 152 - **Send-KeysToWindow** - Line 233
- *...and 10 more functions*

--- 
### CodeComplexityMetrics

[⬆ Back to Contents](#-table-of-contents)

Specialized module providing targeted functionality for the Unity-Claude automation system. Integrates with the broader architecture to deliver specific capabilities and enhance overall system functionality.

**Module Statistics:**
- Functions: 12
- Classes: 1
- Dependencies: 1 modules


**Module Information:**
- **Path:** `Modules\Unity-Claude-CPG\Core\CodeComplexityMetrics.psm1`
- **Size:** 19.43 KB
- **Last Modified:** 2025-08-26 11:46
- **Total Functions:** 11
- **Exported Functions:** 1


**Dependencies:**
- `$cpgModule` (external)


**Key Functions:**
- **Get-CodeComplexityMetrics** - Line 44 - **Get-FunctionComplexity** - Line 150 - **Get-ClassComplexity** - Line 199 - **Get-CyclomaticComplexity** - Line 249 - **Get-CognitiveComplexity** - Line 278
- *...and 6 more functions*

--- 
### CodeRedundancyDetection

[⬆ Back to Contents](#-table-of-contents)

Specialized module providing targeted functionality for the Unity-Claude automation system. Integrates with the broader architecture to deliver specific capabilities and enhance overall system functionality.

**Module Statistics:**
- Functions: 11
- Dependencies: 1 modules


**Module Information:**
- **Path:** `Modules\Unity-Claude-CPG\Core\CodeRedundancyDetection.psm1`
- **Size:** 17.61 KB
- **Last Modified:** 2025-08-26 11:46
- **Total Functions:** 8
- **Exported Functions:** 1


**Dependencies:**
- `$cpgModule` (external)


**Key Functions:**
- **Test-CodeRedundancy** - Line 42 - **Find-DuplicateFunctions** - Line 159 - **Find-SimilarCodeBlocks** - Line 209 - **Find-CloneGroups** - Line 265 - **Get-StructuralSimilarity** - Line 325
- *...and 3 more functions*

--- 
### CodeSmellPrediction

[⬆ Back to Contents](#-table-of-contents)

Specialized module providing targeted functionality for the Unity-Claude automation system. Integrates with the broader architecture to deliver specific capabilities and enhance overall system functionality.

**Module Statistics:**
- Functions: 6
- Classes: 2
- Dependencies: 2 modules


**Module Information:**
- **Path:** `Modules\Unity-Claude-PredictiveAnalysis\Core\CodeSmellPrediction.psm1`
- **Size:** 21.09 KB
- **Last Modified:** 2025-08-26 11:46
- **Total Functions:** 6
- **Exported Functions:** 1


**Dependencies:**
- `$CorePath` (external) - `$RefactoringPath` (external)


**Key Functions:**
- **Predict-CodeSmells** - Line 15 - **Find-FeatureEnvy** - Line 193 - **Find-DataClumps** - Line 254 - **Find-HighComplexityMethods** - Line 332 - **Find-ExcessiveParameters** - Line 381
- *...and 1 more functions*

--- 
### CommandExecution

[⬆ Back to Contents](#-table-of-contents)

Specialized module providing targeted functionality for the Unity-Claude automation system. Integrates with the broader architecture to deliver specific capabilities and enhance overall system functionality.

**Module Statistics:**
- Functions: 3
- Dependencies: 2 modules


**Module Information:**
- **Path:** `Modules\SafeCommandExecution\Core\CommandExecution.psm1`
- **Size:** 8.78 KB
- **Last Modified:** 2025-08-26 11:46
- **Total Functions:** 3
- **Exported Functions:** 1


**Dependencies:**
- `$PSScriptRoot\SafeCommandCore.psm1` (external) - `$PSScriptRoot\ValidationEngine.psm1` (external)


**Key Functions:**
- **Invoke-SafeCommand** - Line 22 - **Test-ExecutionResult** - Line 161 - **Get-CommandExecutionStatistics** - Line 198


--- 
### CommandExecutionEngine

[⬆ Back to Contents](#-table-of-contents)

Specialized module providing targeted functionality for the Unity-Claude automation system. Integrates with the broader architecture to deliver specific capabilities and enhance overall system functionality.

**Module Statistics:**
- Functions: 13
- Dependencies: 7 modules


**Module Information:**
- **Path:** `Modules\Unity-Claude-AutonomousAgent\Execution\CommandExecutionEngine.psm1`
- **Size:** 31.54 KB
- **Last Modified:** 2025-08-20 17:25
- **Total Functions:** 13
- **Exported Functions:** 1


**Dependencies:**
- `(Join-Path` (external) - `(Join-Path` (external) - `(Join-Path` (external) - `(Join-Path` (external) - `ThreadJob` (external) - `(Join-Path` (external) - `(Join-Path` (external)


**Key Functions:**
- **Add-CommandToQueue** - Line 70 - **Get-NextCommand** - Line 150 - **Get-QueueStatus** - Line 193 - **Clear-ExecutionQueue** - Line 221 - **Start-ParallelExecution** - Line 255
- *...and 8 more functions*

--- 
### CommandTypeHandlers

[⬆ Back to Contents](#-table-of-contents)

Specialized module providing targeted functionality for the Unity-Claude automation system. Integrates with the broader architecture to deliver specific capabilities and enhance overall system functionality.

**Module Statistics:**
- Functions: 5
- Dependencies: 3 modules


**Module Information:**
- **Path:** `Modules\SafeCommandExecution\Core\CommandTypeHandlers.psm1`
- **Size:** 15.11 KB
- **Last Modified:** 2025-08-26 11:46
- **Total Functions:** 5
- **Exported Functions:** 1


**Dependencies:**
- `$PSScriptRoot\SafeCommandCore.psm1` (external) - `$PSScriptRoot\ValidationEngine.psm1` (external) - `$PSScriptRoot\RunspaceManagement.psm1` (external)


**Key Functions:**
- **Invoke-UnityCommand** - Line 23 - **Invoke-TestCommand** - Line 93 - **Invoke-PowerShellCommand** - Line 164 - **Invoke-BuildCommand** - Line 232 - **Invoke-AnalysisCommand** - Line 310


--- 
### CompilationIntegration

[⬆ Back to Contents](#-table-of-contents)

Specialized module providing targeted functionality for the Unity-Claude automation system. Integrates with the broader architecture to deliver specific capabilities and enhance overall system functionality.

**Module Statistics:**
- Functions: 3
- Dependencies: 2 modules


**Module Information:**
- **Path:** `Modules\Unity-Claude-UnityParallelization\Core\CompilationIntegration.psm1`
- **Size:** 11.59 KB
- **Last Modified:** 2025-08-26 11:46
- **Total Functions:** 3
- **Exported Functions:** 1


**Dependencies:**
- `$PSScriptRoot\ParallelizationCore.psm1` (external) - `$PSScriptRoot\ProjectConfiguration.psm1` (external)


**Key Functions:**
- **Start-UnityCompilationJob** - Line 22 - **Find-UnityExecutablePath** - Line 137 - **Test-UnityCompilationResult** - Line 183


--- 
### ConfidenceBands

[⬆ Back to Contents](#-table-of-contents)

Specialized module providing targeted functionality for the Unity-Claude automation system. Integrates with the broader architecture to deliver specific capabilities and enhance overall system functionality.

**Module Statistics:**
- Functions: 2


**Module Information:**
- **Path:** `Modules\Unity-Claude-CLIOrchestrator\Core\DecisionEngine-Bayesian\ConfidenceBands.psm1`
- **Size:** 4.83 KB
- **Last Modified:** 2025-08-26 11:46
- **Total Functions:** 2
- **Exported Functions:** 2




**Key Functions:**
- **Get-ConfidenceBand** - Line 9 - **Calculate-PatternConfidence** - Line 32


--- 
### Configuration

[⬆ Back to Contents](#-table-of-contents)

Specialized module providing targeted functionality for the Unity-Claude automation system. Integrates with the broader architecture to deliver specific capabilities and enhance overall system functionality.

**Module Statistics:**
- Functions: 5


**Module Information:**
- **Path:** `Modules\Unity-Claude-DocumentationDrift\Core\Configuration.psm1`
- **Size:** 12.68 KB
- **Last Modified:** 2025-08-26 11:46
- **Total Functions:** 5
- **Exported Functions:** 1




**Key Functions:**
- **Initialize-DocumentationDrift** - Line 45 - **Get-DocumentationDriftConfig** - Line 115 - **Set-DocumentationDriftConfig** - Line 139 - **Reset-DocumentationDriftConfig** - Line 228 - **Export-DocumentationDriftConfig** - Line 250


--- 
### ConfigurationLogging

[⬆ Back to Contents](#-table-of-contents)

Specialized module providing targeted functionality for the Unity-Claude automation system. Integrates with the broader architecture to deliver specific capabilities and enhance overall system functionality.

**Module Statistics:**
- Functions: 4


**Module Information:**
- **Path:** `Modules\Unity-Claude-CLIOrchestrator\Core\DecisionEngine\ConfigurationLogging.psm1`
- **Size:** 6.06 KB
- **Last Modified:** 2025-08-26 11:46
- **Total Functions:** 3
- **Exported Functions:** 1




**Key Functions:**
- **Get-DecisionEngineConfiguration** - Line 95 - **Set-DecisionEngineConfiguration** - Line 103 - **Write-DecisionLog** - Line 117


--- 
### ConfigurationManagement

[⬆ Back to Contents](#-table-of-contents)

Specialized module providing targeted functionality for the Unity-Claude automation system. Integrates with the broader architecture to deliver specific capabilities and enhance overall system functionality.

**Module Statistics:**
- Functions: 6


**Module Information:**
- **Path:** `Modules\Unity-Claude-NotificationIntegration\Configuration\ConfigurationManagement.psm1`
- **Size:** 10.9 KB
- **Last Modified:** 2025-08-21 17:45
- **Total Functions:** 6
- **Exported Functions:** 1




**Key Functions:**
- **New-NotificationConfiguration** - Line 7 - **Import-NotificationConfiguration** - Line 65 - **Export-NotificationConfiguration** - Line 113 - **Test-NotificationConfiguration** - Line 150 - **Get-NotificationConfiguration** - Line 213
- *...and 1 more functions*

--- 
### ContentAnalysis

[⬆ Back to Contents](#-table-of-contents)

Specialized module providing targeted functionality for the Unity-Claude automation system. Integrates with the broader architecture to deliver specific capabilities and enhance overall system functionality.

**Module Statistics:**
- Functions: 8


**Module Information:**
- **Path:** `Modules\Unity-Claude-DocumentationQualityAssessment\Components\ContentAnalysis.psm1`
- **Size:** 4.1 KB
- **Last Modified:** 2025-08-30 19:31
- **Total Functions:** 8
- **Exported Functions:** 8




**Key Functions:**
- **Assess-ContentCompleteness** - Line 5 - **Calculate-OverallQualityMetrics** - Line 27 - **Generate-ImprovementSuggestions** - Line 54 - **Generate-ClarityRecommendations** - Line 83 - **Generate-CompletenessRecommendations** - Line 88
- *...and 3 more functions*

--- 
### ContextExtraction

[⬆ Back to Contents](#-table-of-contents)

Specialized module providing targeted functionality for the Unity-Claude automation system. Integrates with the broader architecture to deliver specific capabilities and enhance overall system functionality.

**Module Statistics:**
- Functions: 6
- Dependencies: 2 modules


**Module Information:**
- **Path:** `Modules\Unity-Claude-AutonomousAgent\Parsing\ContextExtraction.psm1`
- **Size:** 25.92 KB
- **Last Modified:** 2025-08-20 17:25
- **Total Functions:** 6
- **Exported Functions:** 1


**Dependencies:**
- `(Join-Path` (external) - `(Join-Path` (external)


**Key Functions:**
- **Invoke-AdvancedContextExtraction** - Line 113 - **Get-ContextRelevanceScores** - Line 215 - **New-ContextItemsFromExtraction** - Line 310 - **Invoke-ContextIntegration** - Line 399 - **Get-EntityRelationshipMap** - Line 472
- *...and 1 more functions*

--- 
### ContextManagement

[⬆ Back to Contents](#-table-of-contents)

Specialized module providing targeted functionality for the Unity-Claude automation system. Integrates with the broader architecture to deliver specific capabilities and enhance overall system functionality.

**Module Statistics:**
- Functions: 5


**Module Information:**
- **Path:** `Modules\Unity-Claude-NotificationIntegration\Integration\ContextManagement.psm1`
- **Size:** 7 KB
- **Last Modified:** 2025-08-21 17:45
- **Total Functions:** 5
- **Exported Functions:** 1




**Key Functions:**
- **New-NotificationContext** - Line 7 - **Add-NotificationContextData** - Line 51 - **Get-NotificationContext** - Line 79 - **Clear-NotificationContext** - Line 89 - **Format-NotificationContext** - Line 102


--- 
### ContextOptimization

[⬆ Back to Contents](#-table-of-contents)

Specialized module providing targeted functionality for the Unity-Claude automation system. Integrates with the broader architecture to deliver specific capabilities and enhance overall system functionality.

**Module Statistics:**
- Functions: 22


**Module Information:**
- **Path:** `Modules\Unity-Claude-AutonomousAgent\ContextOptimization.psm1`
- **Size:** 49.16 KB
- **Last Modified:** 2025-08-20 17:25
- **Total Functions:** 22
- **Exported Functions:** 1




**Key Functions:**
- **Write-ContextLog** - Line 27 - **Initialize-WorkingMemory** - Line 54 - **Add-ContextItem** - Line 121 - **Compress-Context** - Line 259 - **Get-OptimizedContext** - Line 349
- *...and 17 more functions*

--- 
### ConversationCore

[⬆ Back to Contents](#-table-of-contents)

Core infrastructure module providing fundamental functionality for the Unity-Claude system. This module serves as the foundation for other components, offering essential utilities, configuration management, and base services that other modules depend upon.

**Module Statistics:**
- Functions: 1


**Module Information:**
- **Path:** `Modules\Unity-Claude-AutonomousAgent\Core\ConversationCore.psm1`
- **Size:** 4.18 KB
- **Last Modified:** 2025-08-26 11:46
- **Total Functions:** 1





**Key Functions:**
- **Write-StateLog** - Line 26


--- 
### ConversationStateManager

[⬆ Back to Contents](#-table-of-contents)

Specialized module providing targeted functionality for the Unity-Claude automation system. Integrates with the broader architecture to deliver specific capabilities and enhance overall system functionality.

**Module Statistics:**
- Functions: 22


**Module Information:**
- **Path:** `Modules\Unity-Claude-AutonomousAgent\ConversationStateManager.psm1`
- **Size:** 46.97 KB
- **Last Modified:** 2025-08-26 11:46
- **Total Functions:** 22
- **Exported Functions:** 1




**Key Functions:**
- **Write-StateLog** - Line 36 - **Initialize-ConversationState** - Line 63 - **Set-ConversationState** - Line 197 - **Get-ConversationState** - Line 288 - **Get-ValidStateTransitions** - Line 352
- *...and 17 more functions*

--- 
### ConversationStateManager-Refactored

[⬆ Back to Contents](#-table-of-contents)

Specialized module providing targeted functionality for the Unity-Claude automation system. Integrates with the broader architecture to deliver specific capabilities and enhance overall system functionality.

**Module Statistics:**
- Functions: 5
- Dependencies: 6 modules


**Module Information:**
- **Path:** `Modules\Unity-Claude-AutonomousAgent\ConversationStateManager-Refactored.psm1`
- **Size:** 12.5 KB
- **Last Modified:** 2025-08-26 11:46
- **Total Functions:** 5
- **Exported Functions:** 1


**Dependencies:**
- `(Join-Path` (external) - `(Join-Path` (external) - `(Join-Path` (external) - `(Join-Path` (external) - `(Join-Path` (external) - `(Join-Path` (external)


**Key Functions:**
- **Get-ConversationStateManagerComponents** - Line 23 - **Test-ConversationStateManagerHealth** - Line 48 - **Invoke-ConversationStateManagerDiagnostics** - Line 95 - **Initialize-CompleteConversationSystem** - Line 147 - **Get-ConversationSummary** - Line 206


--- 
### Core

[⬆ Back to Contents](#-table-of-contents)

Core infrastructure module providing fundamental functionality for the Unity-Claude system. This module serves as the foundation for other components, offering essential utilities, configuration management, and base services that other modules depend upon.

**Module Statistics:**
- Functions: 0


**Module Information:**
- **Path:** `Modules\Unity-Claude-CLIOrchestrator\Core\Core.psm1`
- **Size:** 5.28 KB
- **Last Modified:** 2025-08-25 02:21
- **Total Functions:** 0
- **Exported Functions:** 20





--- 
### CoreUtilities

[⬆ Back to Contents](#-table-of-contents)

Core infrastructure module providing fundamental functionality for the Unity-Claude system. This module serves as the foundation for other components, offering essential utilities, configuration management, and base services that other modules depend upon.

**Module Statistics:**
- Functions: 6


**Module Information:**
- **Path:** `Modules\Unity-Claude-AutonomousStateTracker-Enhanced\Core\CoreUtilities.psm1`
- **Size:** 13.24 KB
- **Last Modified:** 2025-08-26 11:46
- **Total Functions:** 6
- **Exported Functions:** 1




**Key Functions:**
- **ConvertTo-HashTable** - Line 8 - **Get-SafeDateTime** - Line 67 - **Get-UptimeMinutes** - Line 109 - **Write-EnhancedStateLog** - Line 150 - **Get-SystemPerformanceMetrics** - Line 217
- *...and 1 more functions*

--- 
### CPG-AdvancedEdges

[⬆ Back to Contents](#-table-of-contents)

Specialized module providing targeted functionality for the Unity-Claude automation system. Integrates with the broader architecture to deliver specific capabilities and enhance overall system functionality.

**Module Statistics:**
- Functions: 15
- Classes: 6


**Module Information:**
- **Path:** `Modules\Unity-Claude-CPG\Core\CPG-AdvancedEdges.psm1`
- **Size:** 25.39 KB
- **Last Modified:** 2025-08-28 01:39
- **Total Functions:** 30
- **Exported Functions:** 1




**Key Functions:**
- **DataFlowEdge** - Line 80 - **AddTransformation** - Line 95 - **AnalyzeFlow** - Line 100 - **ControlFlowEdge** - Line 129 - **SetCondition** - Line 146
- *...and 25 more functions*

--- 
### CPG-AnalysisOperations

[⬆ Back to Contents](#-table-of-contents)

Specialized module providing targeted functionality for the Unity-Claude automation system. Integrates with the broader architecture to deliver specific capabilities and enhance overall system functionality.

**Module Statistics:**
- Functions: 5


**Module Information:**
- **Path:** `Modules\Unity-Claude-CPG\Core\CPG-AnalysisOperations.psm1`
- **Size:** 9.03 KB
- **Last Modified:** 2025-08-26 11:46
- **Total Functions:** 5
- **Exported Functions:** 1




**Key Functions:**
- **Get-CPGStatistics** - Line 19 - **Test-CPGStronglyConnected** - Line 105 - **Get-CPGComplexityMetrics** - Line 149 - **Find-CPGCycles** - Line 183 - **Find-CyclesDFS** - Line 200


--- 
### CPG-BasicOperations

[⬆ Back to Contents](#-table-of-contents)

Specialized module providing targeted functionality for the Unity-Claude automation system. Integrates with the broader architecture to deliver specific capabilities and enhance overall system functionality.

**Module Statistics:**
- Functions: 5


**Module Information:**
- **Path:** `Modules\Unity-Claude-CPG\Core\CPG-BasicOperations.psm1`
- **Size:** 6.78 KB
- **Last Modified:** 2025-08-26 11:46
- **Total Functions:** 5
- **Exported Functions:** 1




**Key Functions:**
- **New-CPGNode** - Line 19 - **New-CPGEdge** - Line 55 - **New-CPGraph** - Line 86 - **Add-CPGNode** - Line 103 - **Add-CPGEdge** - Line 132


--- 
### CPG-CallGraphBuilder

[⬆ Back to Contents](#-table-of-contents)

Specialized module providing targeted functionality for the Unity-Claude automation system. Integrates with the broader architecture to deliver specific capabilities and enhance overall system functionality.

**Module Statistics:**
- Functions: 11
- Classes: 5


**Module Information:**
- **Path:** `Modules\Unity-Claude-CPG\Core\CPG-CallGraphBuilder.psm1`
- **Size:** 24.92 KB
- **Last Modified:** 2025-08-28 02:52
- **Total Functions:** 16
- **Exported Functions:** 1




**Key Functions:**
- **Write-CPGDebug** - Line 32 - **CallNode** - Line 83 - **GetSignature** - Line 92 - **CallEdge** - Line 119 - **IncrementFrequency** - Line 130
- *...and 11 more functions*

--- 
### CPG-DataFlowTracker

[⬆ Back to Contents](#-table-of-contents)

Specialized module providing targeted functionality for the Unity-Claude automation system. Integrates with the broader architecture to deliver specific capabilities and enhance overall system functionality.

**Module Statistics:**
- Functions: 6
- Classes: 6


**Module Information:**
- **Path:** `Modules\Unity-Claude-CPG\Core\CPG-DataFlowTracker.psm1`
- **Size:** 31.56 KB
- **Last Modified:** 2025-08-28 03:02
- **Total Functions:** 22
- **Exported Functions:** 1




**Key Functions:**
- **Write-CPGDebug** - Line 21 - **VariableDefinition** - Line 70 - **VariableUse** - Line 90 - **DefUseChain** - Line 107 - **AddUse** - Line 115
- *...and 17 more functions*

--- 
### CPG-DataStructures

[⬆ Back to Contents](#-table-of-contents)

Specialized module providing targeted functionality for the Unity-Claude automation system. Integrates with the broader architecture to deliver specific capabilities and enhance overall system functionality.

**Module Statistics:**
- Functions: 0
- Classes: 4


**Module Information:**
- **Path:** `Modules\Unity-Claude-CPG\Core\CPG-DataStructures.psm1`
- **Size:** 8.78 KB
- **Last Modified:** 2025-08-26 11:46
- **Total Functions:** 13





**Key Functions:**
- **CPGNode** - Line 84 - **CPGNode** - Line 92 - **ToString** - Line 102 - **ToHashtable** - Line 106 - **CPGEdge** - Line 136
- *...and 8 more functions*

--- 
### CPG-QueryOperations

[⬆ Back to Contents](#-table-of-contents)

Specialized module providing targeted functionality for the Unity-Claude automation system. Integrates with the broader architecture to deliver specific capabilities and enhance overall system functionality.

**Module Statistics:**
- Functions: 4


**Module Information:**
- **Path:** `Modules\Unity-Claude-CPG\Core\CPG-QueryOperations.psm1`
- **Size:** 11.65 KB
- **Last Modified:** 2025-08-26 11:46
- **Total Functions:** 4
- **Exported Functions:** 1




**Key Functions:**
- **Get-CPGNode** - Line 19 - **Get-CPGEdge** - Line 74 - **Get-CPGNeighbors** - Line 129 - **Find-CPGPath** - Line 219


--- 
### CPG-SerializationOperations

[⬆ Back to Contents](#-table-of-contents)

Specialized module providing targeted functionality for the Unity-Claude automation system. Integrates with the broader architecture to deliver specific capabilities and enhance overall system functionality.

**Module Statistics:**
- Functions: 6


**Module Information:**
- **Path:** `Modules\Unity-Claude-CPG\Core\CPG-SerializationOperations.psm1`
- **Size:** 10.24 KB
- **Last Modified:** 2025-08-26 11:46
- **Total Functions:** 4
- **Exported Functions:** 1




**Key Functions:**
- **Export-CPGraph** - Line 19 - **Import-CPGraph** - Line 101 - **Export-ToGraphML** - Line 196 - **Export-ToDOT** - Line 246


--- 
### CPG-ThreadSafeOperations

[⬆ Back to Contents](#-table-of-contents)

Specialized module providing targeted functionality for the Unity-Claude automation system. Integrates with the broader architecture to deliver specific capabilities and enhance overall system functionality.

**Module Statistics:**
- Functions: 12
- Dependencies: 2 modules


**Module Information:**
- **Path:** `Modules\Unity-Claude-CPG\Core\CPG-ThreadSafeOperations.psm1`
- **Size:** 25.68 KB
- **Last Modified:** 2025-08-28 01:31
- **Total Functions:** 12
- **Exported Functions:** 1


**Dependencies:**
- `$PSScriptRoot\CPG-DataStructures.psm1` (external) - `$PSScriptRoot\..\..\Unity-Claude-ParallelProcessing\Unity-Claude-ParallelProcessing.psm1` (external)


**Key Functions:**
- **Write-CPGLog** - Line 38 - **New-ThreadSafeCPG** - Line 69 - **Add-CPGNodeThreadSafe** - Line 116 - **Get-CPGNodeThreadSafe** - Line 191 - **Update-CPGNodeThreadSafe** - Line 252
- *...and 7 more functions*

--- 
### CPG-Unified

[⬆ Back to Contents](#-table-of-contents)

Specialized module providing targeted functionality for the Unity-Claude automation system. Integrates with the broader architecture to deliver specific capabilities and enhance overall system functionality.

**Module Statistics:**
- Functions: 14
- Classes: 12


**Module Information:**
- **Path:** `Modules\Unity-Claude-CPG\Core\CPG-Unified.psm1`
- **Size:** 26.53 KB
- **Last Modified:** 2025-08-28 01:46
- **Total Functions:** 41
- **Exported Functions:** 1




**Key Functions:**
- **Write-CPGDebug** - Line 18 - **CPGNode** - Line 159 - **CPGNode** - Line 168 - **ToString** - Line 179 - **ToHashtable** - Line 183
- *...and 36 more functions*

--- 
### CrossLanguage-DependencyMaps

[⬆ Back to Contents](#-table-of-contents)

Specialized module providing targeted functionality for the Unity-Claude automation system. Integrates with the broader architecture to deliver specific capabilities and enhance overall system functionality.

**Module Statistics:**
- Functions: 11
- Classes: 9
- Dependencies: 4 modules


**Module Information:**
- **Path:** `Modules\Unity-Claude-CPG\Core\CrossLanguage-DependencyMaps.psm1`
- **Size:** 46.43 KB
- **Last Modified:** 2025-08-28 11:34
- **Total Functions:** 58
- **Exported Functions:** 1


**Dependencies:**
- `with` (external) - `$PSScriptRoot\CPG-Unified.psm1` (external)


**Key Functions:**
- **UnifiedNode** - Line 60 - **UnifiedRelation** - Line 78 - **UnifiedCPG** - Line 95 - **AddNode** - Line 102 - **AddRelation** - Line 108
- *...and 53 more functions*

--- 
### CrossLanguage-GraphMerger

[⬆ Back to Contents](#-table-of-contents)

Specialized module providing targeted functionality for the Unity-Claude automation system. Integrates with the broader architecture to deliver specific capabilities and enhance overall system functionality.

**Module Statistics:**
- Functions: 8
- Classes: 12
- Dependencies: 2 modules


**Module Information:**
- **Path:** `Modules\Unity-Claude-CPG\Core\CrossLanguage-GraphMerger.psm1`
- **Size:** 39.26 KB
- **Last Modified:** 2025-08-28 12:05
- **Total Functions:** 56
- **Exported Functions:** 1


**Dependencies:**
- `instead` (external) - `$PSScriptRoot\CPG-Unified.psm1` (external)


**Key Functions:**
- **UnifiedCPG** - Line 21 - **AddNode** - Line 28 - **AddRelation** - Line 34 - **GetAllNodes** - Line 38 - **GetAllRelations** - Line 42
- *...and 51 more functions*

--- 
### CrossLanguage-UnifiedModel

[⬆ Back to Contents](#-table-of-contents)

Specialized module providing targeted functionality for the Unity-Claude automation system. Integrates with the broader architecture to deliver specific capabilities and enhance overall system functionality.

**Module Statistics:**
- Functions: 5
- Classes: 6


**Module Information:**
- **Path:** `Modules\Unity-Claude-CPG\Core\CrossLanguage-UnifiedModel.psm1`
- **Size:** 28.62 KB
- **Last Modified:** 2025-08-28 12:07
- **Total Functions:** 31
- **Exported Functions:** 1




**Key Functions:**
- **UnifiedNode** - Line 128 - **UnifiedNode** - Line 137 - **GetDisplayName** - Line 149 - **GetMetadata** - Line 156 - **IsEquivalentTo** - Line 170
- *...and 26 more functions*

--- 
### DatabaseManagement

[⬆ Back to Contents](#-table-of-contents)

Specialized module providing targeted functionality for the Unity-Claude automation system. Integrates with the broader architecture to deliver specific capabilities and enhance overall system functionality.

**Module Statistics:**
- Functions: 1
- Dependencies: 1 modules


**Module Information:**
- **Path:** `Modules\Unity-Claude-Learning\Core\DatabaseManagement.psm1`
- **Size:** 7.55 KB
- **Last Modified:** 2025-08-26 11:46
- **Total Functions:** 1
- **Exported Functions:** 1


**Dependencies:**
- `$CorePath` (external)


**Key Functions:**
- **Initialize-LearningDatabase** - Line 11


--- 
### DecisionEngine

[⬆ Back to Contents](#-table-of-contents)

Decision engine module implementing rule-based and ML-enhanced decision trees. Analyzes Claude responses, evaluates safety constraints, and determines appropriate actions based on configurable policies and learned patterns.

**Module Statistics:**
- Functions: 12


**Module Information:**
- **Path:** `Modules\Unity-Claude-CLIOrchestrator\Core\DecisionEngine.psm1`
- **Size:** 33.98 KB
- **Last Modified:** 2025-08-26 22:10
- **Total Functions:** 11
- **Exported Functions:** 1




**Key Functions:**
- **Write-DecisionLog** - Line 105 - **Invoke-RuleBasedDecision** - Line 130 - **Resolve-PriorityDecision** - Line 236 - **Test-SafetyValidation** - Line 346 - **Test-SafeFilePath** - Line 484
- *...and 6 more functions*

--- 
### DecisionEngine-Bayesian

[⬆ Back to Contents](#-table-of-contents)

Decision engine module implementing rule-based and ML-enhanced decision trees. Analyzes Claude responses, evaluates safety constraints, and determines appropriate actions based on configurable policies and learned patterns.

**Module Statistics:**
- Functions: 20


**Module Information:**
- **Path:** `Modules\Unity-Claude-CLIOrchestrator\Core\DecisionEngine-Bayesian.psm1`
- **Size:** 45.26 KB
- **Last Modified:** 2025-08-26 11:46
- **Total Functions:** 20
- **Exported Functions:** 1




**Key Functions:**
- **Invoke-BayesianConfidenceAdjustment** - Line 66 - **Get-BayesianPrior** - Line 152 - **Calculate-BayesianLikelihood** - Line 183 - **Calculate-BayesianEvidence** - Line 214 - **Calculate-ContextualAdjustment** - Line 244
- *...and 15 more functions*

--- 
### DecisionEngine-Bayesian-Refactored

[⬆ Back to Contents](#-table-of-contents)

Decision engine module implementing rule-based and ML-enhanced decision trees. Analyzes Claude responses, evaluates safety constraints, and determines appropriate actions based on configurable policies and learned patterns.

**Module Statistics:**
- Functions: 0
- Dependencies: 8 modules


**Module Information:**
- **Path:** `Modules\Unity-Claude-CLIOrchestrator\Core\DecisionEngine-Bayesian-Refactored.psm1`
- **Size:** 4.65 KB
- **Last Modified:** 2025-08-26 11:46
- **Total Functions:** 0
- **Exported Functions:** 1


**Dependencies:**
- `(Join-Path` (external) - `(Join-Path` (external) - `(Join-Path` (external) - `(Join-Path` (external) - `(Join-Path` (external) - `(Join-Path` (external) - `(Join-Path` (external) - `(Join-Path` (external)



--- 
### DecisionEngine-Refactored

[⬆ Back to Contents](#-table-of-contents)

Decision engine module implementing rule-based and ML-enhanced decision trees. Analyzes Claude responses, evaluates safety constraints, and determines appropriate actions based on configurable policies and learned patterns.

**Module Statistics:**
- Functions: 5
- Dependencies: 5 modules


**Module Information:**
- **Path:** `Modules\Unity-Claude-CLIOrchestrator\Core\DecisionEngine-Refactored.psm1`
- **Size:** 13.89 KB
- **Last Modified:** 2025-08-26 11:46
- **Total Functions:** 4
- **Exported Functions:** 1


**Dependencies:**
- `(Join-Path` (external) - `(Join-Path` (external) - `(Join-Path` (external) - `(Join-Path` (external) - `(Join-Path` (external)


**Key Functions:**
- **Initialize-DecisionEngine** - Line 43 - **Test-DecisionEngineHealth** - Line 89 - **Get-DecisionEngineStatistics** - Line 180 - **Invoke-EnhancedDecisionProcessing** - Line 233


--- 
### DecisionEngineCore

[⬆ Back to Contents](#-table-of-contents)

Core infrastructure module providing fundamental functionality for the Unity-Claude system. This module serves as the foundation for other components, offering essential utilities, configuration management, and base services that other modules depend upon. Decision engine module implementing rule-based and ML-enhanced decision trees. Analyzes Claude responses, evaluates safety constraints, and determines appropriate actions based on configurable policies and learned patterns. 

**Module Statistics:**
 - Functions: 7


**Module Information:**
- **Path:** `Modules\Unity-Claude-DecisionEngine\Core\DecisionEngineCore.psm1`
- **Size:** 6.91 KB
- **Last Modified:** 2025-08-26 11:46
- **Total Functions:** 7
- **Exported Functions:** 1




**Key Functions:**
- **Write-DecisionEngineLog** - Line 25 - **Test-RequiredModule** - Line 64 - **Get-DecisionEngineConfig** - Line 83 - **Set-DecisionEngineConfig** - Line 91 - **Get-DecisionHistory** - Line 116
- *...and 2 more functions*

--- 
### DecisionEngineIntegration

[⬆ Back to Contents](#-table-of-contents)

Decision engine module implementing rule-based and ML-enhanced decision trees. Analyzes Claude responses, evaluates safety constraints, and determines appropriate actions based on configurable policies and learned patterns.

**Module Statistics:**
- Functions: 12
- Dependencies: 5 modules


**Module Information:**
- **Path:** `Modules\Unity-Claude-CLIOrchestrator\Core\DecisionEngineIntegration.psm1`
- **Size:** 23.33 KB
- **Last Modified:** 2025-08-25 13:45
- **Total Functions:** 12
- **Exported Functions:** 1


**Dependencies:**
- `$modulePath\DecisionEngine.psm1` (external) - `$modulePath\DecisionEngine-Bayesian.psm1` (external) - `$modulePath\CircuitBreaker.psm1` (external) - `$modulePath\EscalationProtocol.psm1` (external) - `$safetyModulePath` (external)


**Key Functions:**
- **Write-IntegrationLog** - Line 97 - **Invoke-IntegratedDecision** - Line 123 - **Get-CircuitBreakerName** - Line 367 - **Get-CurrentMetrics** - Line 380 - **Get-SystemLoad** - Line 407
- *...and 7 more functions*

--- 
### DecisionExecution

[⬆ Back to Contents](#-table-of-contents)

Decision engine module implementing rule-based and ML-enhanced decision trees. Analyzes Claude responses, evaluates safety constraints, and determines appropriate actions based on configurable policies and learned patterns.

**Module Statistics:**
- Functions: 12
- Dependencies: 1 modules


**Module Information:**
- **Path:** `Modules\Unity-Claude-MasterOrchestrator\Core\DecisionExecution.psm1`
- **Size:** 12.2 KB
- **Last Modified:** 2025-08-26 11:46
- **Total Functions:** 12
- **Exported Functions:** 1


**Dependencies:**
- `$PSScriptRoot\OrchestratorCore.psm1` (external)


**Key Functions:**
- **Invoke-DecisionExecution** - Line 19 - **Invoke-SafetyValidation** - Line 111 - **Invoke-RecommendationExecution** - Line 151 - **Invoke-TestExecution** - Line 163 - **Invoke-CommandExecution** - Line 175
- *...and 7 more functions*

--- 
### DecisionExecution-Fixed

[⬆ Back to Contents](#-table-of-contents)

Decision engine module implementing rule-based and ML-enhanced decision trees. Analyzes Claude responses, evaluates safety constraints, and determines appropriate actions based on configurable policies and learned patterns.

**Module Statistics:**
- Functions: 2


**Module Information:**
- **Path:** `Modules\Unity-Claude-CLIOrchestrator\Core\OrchestrationComponents\DecisionExecution-Fixed.psm1`
- **Size:** 4.86 KB
- **Last Modified:** 2025-08-27 17:21
- **Total Functions:** 2





**Key Functions:**
- **Invoke-DecisionExecution** - Line 4 - **Execute-TestAction** - Line 84


--- 
### DecisionMaking

[⬆ Back to Contents](#-table-of-contents)

Decision engine module implementing rule-based and ML-enhanced decision trees. Analyzes Claude responses, evaluates safety constraints, and determines appropriate actions based on configurable policies and learned patterns.

**Module Statistics:**
- Functions: 4
- Dependencies: 1 modules


**Module Information:**
- **Path:** `Modules\Unity-Claude-DecisionEngine\Core\DecisionMaking.psm1`
- **Size:** 14.17 KB
- **Last Modified:** 2025-08-26 11:46
- **Total Functions:** 4
- **Exported Functions:** 1


**Dependencies:**
- `$corePath` (external)


**Key Functions:**
- **Invoke-AutonomousDecision** - Line 13 - **Invoke-DecisionTree** - Line 86 - **Apply-ContextualAdjustments** - Line 186 - **Invoke-DecisionValidation** - Line 262


--- 
### DecisionMaking-Fixed

[⬆ Back to Contents](#-table-of-contents)

Decision engine module implementing rule-based and ML-enhanced decision trees. Analyzes Claude responses, evaluates safety constraints, and determines appropriate actions based on configurable policies and learned patterns.

**Module Statistics:**
- Functions: 3


**Module Information:**
- **Path:** `Modules\Unity-Claude-CLIOrchestrator\Core\OrchestrationComponents\DecisionMaking-Fixed.psm1`
- **Size:** 7.61 KB
- **Last Modified:** 2025-08-27 17:21
- **Total Functions:** 3





**Key Functions:**
- **Invoke-ComprehensiveResponseAnalysis** - Line 4 - **Invoke-AutonomousDecisionMaking** - Line 103 - **Test-DecisionSafety** - Line 185


--- 
### DepaAlgorithm

[⬆ Back to Contents](#-table-of-contents)

Specialized module providing targeted functionality for the Unity-Claude automation system. Integrates with the broader architecture to deliver specific capabilities and enhance overall system functionality.

**Module Statistics:**
- Functions: 4
- Dependencies: 1 modules


**Module Information:**
- **Path:** `Modules\Unity-Claude-CPG\Core\DepaAlgorithm.psm1`
- **Size:** 13.6 KB
- **Last Modified:** 2025-08-26 11:46
- **Total Functions:** 3
- **Exported Functions:** 1


**Dependencies:**
- `$cpgModule` (external)


**Key Functions:**
- **Get-CodePerplexity** - Line 42 - **Get-LinePerplexity** - Line 250 - **Test-DeadProgramArtifacts** - Line 275


--- 
### DependencyManagement

[⬆ Back to Contents](#-table-of-contents)

Specialized module providing targeted functionality for the Unity-Claude automation system. Integrates with the broader architecture to deliver specific capabilities and enhance overall system functionality.

**Module Statistics:**
- Functions: 5
- Dependencies: 4 modules


**Module Information:**
- **Path:** `Modules\Unity-Claude-IntegratedWorkflow\Core\DependencyManagement.psm1`
- **Size:** 7.8 KB
- **Last Modified:** 2025-08-26 11:46
- **Total Functions:** 5
- **Exported Functions:** 1


**Dependencies:**
- `$CorePath` (external) - `$RunspaceManagementPath` (external) - `$UnityParallelizationPath` (external) - `$ClaudeParallelizationPath` (external)


**Key Functions:**
- **Test-ModuleDependencyAvailability** - Line 16 - **Initialize-RequiredModules** - Line 39 - **Test-ModuleDependencies** - Line 98 - **Assert-Dependencies** - Line 113 - **Get-ModuleAvailability** - Line 126


--- 
### DocumentationAccuracy

[⬆ Back to Contents](#-table-of-contents)

Intelligent documentation module that provides automated documentation generation, quality assessment, and cross-referencing capabilities. Maintains live documentation that updates automatically as the codebase evolves.

**Module Statistics:**
- Functions: 12
- Dependencies: 1 modules


**Module Information:**
- **Path:** `Modules\Unity-Claude-CPG\Core\DocumentationAccuracy.psm1`
- **Size:** 25.41 KB
- **Last Modified:** 2025-08-26 11:46
- **Total Functions:** 10
- **Exported Functions:** 1


**Dependencies:**
- `$cpgModule` (external)


**Key Functions:**
- **Test-DocumentationAccuracy** - Line 42 - **Update-DocumentationSuggestions** - Line 187 - **Test-ParameterAccuracy** - Line 286 - **Test-ReturnTypeAccuracy** - Line 333 - **Test-ExampleAccuracy** - Line 365
- *...and 5 more functions*

--- 
### DocumentationComparison

[⬆ Back to Contents](#-table-of-contents)

Intelligent documentation module that provides automated documentation generation, quality assessment, and cross-referencing capabilities. Maintains live documentation that updates automatically as the codebase evolves.

**Module Statistics:**
- Functions: 7
- Dependencies: 1 modules


**Module Information:**
- **Path:** `Modules\Unity-Claude-CPG\Core\DocumentationComparison.psm1`
- **Size:** 22.14 KB
- **Last Modified:** 2025-08-26 11:46
- **Total Functions:** 6
- **Exported Functions:** 1


**Dependencies:**
- `$cpgModule` (external)


**Key Functions:**
- **Compare-CodeToDocumentation** - Line 42 - **Find-UndocumentedFeatures** - Line 212 - **Get-NodeDocumentation** - Line 340 - **Get-DocumentationScore** - Line 442 - **Get-DocumentationPriority** - Line 492
- *...and 1 more functions*

--- 
### EnhancedPatternIntegration

[⬆ Back to Contents](#-table-of-contents)

Specialized module providing targeted functionality for the Unity-Claude automation system. Integrates with the broader architecture to deliver specific capabilities and enhance overall system functionality.

**Module Statistics:**
- Functions: 3


**Module Information:**
- **Path:** `Modules\Unity-Claude-CLIOrchestrator\Core\DecisionEngine-Bayesian\EnhancedPatternIntegration.psm1`
- **Size:** 7.34 KB
- **Last Modified:** 2025-08-26 11:46
- **Total Functions:** 1
- **Exported Functions:** 1




**Key Functions:**
- **Invoke-EnhancedPatternAnalysis** - Line 9


--- 
### EntityContextEngine

[⬆ Back to Contents](#-table-of-contents)

Specialized module providing targeted functionality for the Unity-Claude automation system. Integrates with the broader architecture to deliver specific capabilities and enhance overall system functionality.

**Module Statistics:**
- Functions: 14


**Module Information:**
- **Path:** `Modules\Unity-Claude-CLIOrchestrator\Core\EntityContextEngine.psm1`
- **Size:** 24.74 KB
- **Last Modified:** 2025-08-26 11:46
- **Total Functions:** 14
- **Exported Functions:** 1




**Key Functions:**
- **Extract-ContextEntities** - Line 69 - **Get-TextSpans** - Line 135 - **Split-TextIntoSentences** - Line 183 - **Invoke-JointEntityClassification** - Line 214 - **Get-SpanConfidenceScore** - Line 263
- *...and 9 more functions*

--- 
### EntityRelationshipManagement

[⬆ Back to Contents](#-table-of-contents)

Specialized module providing targeted functionality for the Unity-Claude automation system. Integrates with the broader architecture to deliver specific capabilities and enhance overall system functionality.

**Module Statistics:**
- Functions: 3


**Module Information:**
- **Path:** `Modules\Unity-Claude-CLIOrchestrator\Core\DecisionEngine-Bayesian\EntityRelationshipManagement.psm1`
- **Size:** 9.27 KB
- **Last Modified:** 2025-08-26 11:46
- **Total Functions:** 3
- **Exported Functions:** 3




**Key Functions:**
- **Build-EntityRelationshipGraph** - Line 9 - **Find-EntityCluster** - Line 112 - **Measure-EntityProximity** - Line 152


--- 
### ErrorDetection

[⬆ Back to Contents](#-table-of-contents)

Specialized module providing targeted functionality for the Unity-Claude automation system. Integrates with the broader architecture to deliver specific capabilities and enhance overall system functionality.

**Module Statistics:**
- Functions: 7
- Dependencies: 2 modules


**Module Information:**
- **Path:** `Modules\Unity-Claude-UnityParallelization\Core\ErrorDetection.psm1`
- **Size:** 28.25 KB
- **Last Modified:** 2025-08-26 11:46
- **Total Functions:** 6
- **Exported Functions:** 1


**Dependencies:**
- `$PSScriptRoot\ParallelizationCore.psm1` (external) - `$PSScriptRoot\ProjectConfiguration.psm1` (external)


**Key Functions:**
- **Start-ConcurrentErrorDetection** - Line 22 - **Classify-UnityCompilationError** - Line 176 - **Aggregate-UnityErrors** - Line 264 - **Deduplicate-UnityErrors** - Line 389 - **Get-UnityErrorStatistics** - Line 491
- *...and 1 more functions*

--- 
### ErrorExport

[⬆ Back to Contents](#-table-of-contents)

Specialized module providing targeted functionality for the Unity-Claude automation system. Integrates with the broader architecture to deliver specific capabilities and enhance overall system functionality.

**Module Statistics:**
- Functions: 3
- Dependencies: 3 modules


**Module Information:**
- **Path:** `Modules\Unity-Claude-UnityParallelization\Core\ErrorExport.psm1`
- **Size:** 16.9 KB
- **Last Modified:** 2025-08-26 11:46
- **Total Functions:** 3
- **Exported Functions:** 1


**Dependencies:**
- `$PSScriptRoot\ParallelizationCore.psm1` (external) - `$PSScriptRoot\ErrorDetection.psm1` (external) - `$PSScriptRoot\ParallelMonitoring.psm1` (external)


**Key Functions:**
- **Export-UnityErrorsConcurrently** - Line 23 - **Format-UnityErrorsForClaude** - Line 198 - **Test-UnityParallelizationPerformance** - Line 273


--- 
### ErrorHandling

[⬆ Back to Contents](#-table-of-contents)

Specialized module providing targeted functionality for the Unity-Claude automation system. Integrates with the broader architecture to deliver specific capabilities and enhance overall system functionality.

**Module Statistics:**
- Functions: 11
- Dependencies: 1 modules


**Module Information:**
- **Path:** `Modules\Unity-Claude-AutonomousAgent\Execution\ErrorHandling.psm1`
- **Size:** 22.55 KB
- **Last Modified:** 2025-08-20 17:25
- **Total Functions:** 11
- **Exported Functions:** 1


**Dependencies:**
- `(Join-Path` (external)


**Key Functions:**
- **Invoke-ExponentialBackoffRetry** - Line 67 - **Get-ExponentialBackoffDelay** - Line 153 - **Test-ErrorRetryability** - Line 196 - **Get-ErrorClassificationConfig** - Line 267 - **Set-ErrorClassificationConfig** - Line 281
- *...and 6 more functions*

--- 
### EscalationProtocol

[⬆ Back to Contents](#-table-of-contents)

Specialized module providing targeted functionality for the Unity-Claude automation system. Integrates with the broader architecture to deliver specific capabilities and enhance overall system functionality.

**Module Statistics:**
- Functions: 16


**Module Information:**
- **Path:** `Modules\Unity-Claude-CLIOrchestrator\Core\EscalationProtocol.psm1`
- **Size:** 37.63 KB
- **Last Modified:** 2025-08-25 13:45
- **Total Functions:** 16
- **Exported Functions:** 1




**Key Functions:**
- **Write-EscalationLog** - Line 144 - **New-Escalation** - Line 172 - **Invoke-EscalationIncrease** - Line 243 - **Invoke-EscalationDecrease** - Line 309 - **Resolve-Escalation** - Line 374
- *...and 11 more functions*

--- 
### EventProcessing

[⬆ Back to Contents](#-table-of-contents)

Specialized module providing targeted functionality for the Unity-Claude automation system. Integrates with the broader architecture to deliver specific capabilities and enhance overall system functionality.

**Module Statistics:**
- Functions: 11
- Dependencies: 1 modules


**Module Information:**
- **Path:** `Modules\Unity-Claude-MasterOrchestrator\Core\EventProcessing.psm1`
- **Size:** 15.59 KB
- **Last Modified:** 2025-08-26 11:46
- **Total Functions:** 11
- **Exported Functions:** 1


**Dependencies:**
- `$PSScriptRoot\OrchestratorCore.psm1` (external)


**Key Functions:**
- **Start-EventDrivenProcessing** - Line 22 - **Register-ResponseMonitorEvents** - Line 71 - **Register-DecisionEngineEvents** - Line 100 - **Add-EventToQueue** - Line 128 - **Start-EventProcessingLoop** - Line 149
- *...and 6 more functions*

--- 
### FailureMode

[⬆ Back to Contents](#-table-of-contents)

Artificial Intelligence integration module that bridges PowerShell automation with AI services. Provides intelligent error analysis, pattern recognition, and automated decision-making capabilities through Claude AI or local LLM integration.

**Module Statistics:**
- Functions: 12
- Dependencies: 1 modules


**Module Information:**
- **Path:** `Modules\Unity-Claude-AutonomousAgent\Execution\FailureMode.psm1`
- **Size:** 20.87 KB
- **Last Modified:** 2025-08-20 17:25
- **Total Functions:** 12
- **Exported Functions:** 1


**Dependencies:**
- `(Join-Path` (external)


**Key Functions:**
- **Test-EscalationTriggers** - Line 49 - **Invoke-HumanEscalation** - Line 124 - **Enable-SafeMode** - Line 200 - **Disable-SafeMode** - Line 244 - **Test-SafeModeOperation** - Line 287
- *...and 7 more functions*

--- 
### FallbackMechanisms

[⬆ Back to Contents](#-table-of-contents)

Specialized module providing targeted functionality for the Unity-Claude automation system. Integrates with the broader architecture to deliver specific capabilities and enhance overall system functionality.

**Module Statistics:**
- Functions: 7


**Module Information:**
- **Path:** `Modules\Unity-Claude-NotificationIntegration\Reliability\FallbackMechanisms.psm1`
- **Size:** 8.83 KB
- **Last Modified:** 2025-08-21 17:45
- **Total Functions:** 7
- **Exported Functions:** 1




**Key Functions:**
- **New-NotificationFallbackChain** - Line 7 - **Invoke-NotificationFallback** - Line 34 - **Test-NotificationFallback** - Line 89 - **Get-FallbackStatus** - Line 109 - **Reset-FallbackState** - Line 124
- *...and 2 more functions*

--- 
### FallbackStrategies

[⬆ Back to Contents](#-table-of-contents)

Specialized module providing targeted functionality for the Unity-Claude automation system. Integrates with the broader architecture to deliver specific capabilities and enhance overall system functionality.

**Module Statistics:**
- Functions: 4


**Module Information:**
- **Path:** `Modules\Unity-Claude-CLIOrchestrator\Core\DecisionEngine\FallbackStrategies.psm1`
- **Size:** 9.11 KB
- **Last Modified:** 2025-08-26 11:46
- **Total Functions:** 4
- **Exported Functions:** 1




**Key Functions:**
- **Resolve-ConflictingRecommendations** - Line 9 - **Invoke-GracefulDegradation** - Line 65 - **Get-ConflictAnalysis** - Line 118 - **Get-EmergencyFallback** - Line 173


--- 
### FileProcessing

[⬆ Back to Contents](#-table-of-contents)

Specialized module providing targeted functionality for the Unity-Claude automation system. Integrates with the broader architecture to deliver specific capabilities and enhance overall system functionality.

**Module Statistics:**
- Functions: 9


**Module Information:**
- **Path:** `Modules\Unity-Claude-PerformanceOptimizer\Core\FileProcessing.psm1`
- **Size:** 9.6 KB
- **Last Modified:** 2025-08-26 11:46
- **Total Functions:** 9
- **Exported Functions:** 1




**Key Functions:**
- **Invoke-FileProcessing** - Line 7 - **Invoke-FileTypeProcessing** - Line 44 - **Invoke-PowerShellFileProcessing** - Line 78 - **Invoke-CSharpFileProcessing** - Line 111 - **Invoke-PythonFileProcessing** - Line 133
- *...and 4 more functions*

--- 
### FileSystemMonitoring

[⬆ Back to Contents](#-table-of-contents)

Real-time monitoring module tracking system health, performance metrics, and Unity compilation status. Provides event-driven notifications and triggers automated responses to detected issues.

**Module Statistics:**
- Functions: 8


**Module Information:**
- **Path:** `Modules\Unity-Claude-PerformanceOptimizer\Core\FileSystemMonitoring.psm1`
- **Size:** 7.67 KB
- **Last Modified:** 2025-08-26 11:46
- **Total Functions:** 8
- **Exported Functions:** 1




**Key Functions:**
- **Initialize-FileSystemWatcher** - Line 8 - **Register-FileChangeHandler** - Line 30 - **Start-FileSystemMonitoring** - Line 50 - **Stop-FileSystemMonitoring** - Line 62 - **New-FileChangeInfo** - Line 77
- *...and 3 more functions*

--- 
### GitHubPRManager

[⬆ Back to Contents](#-table-of-contents)

GitHub integration module enabling version control operations, issue management, and pull request automation. Facilitates collaborative development workflows and automated documentation updates.

**Module Statistics:**
- Functions: 5


**Module Information:**
- **Path:** `Modules\Unity-Claude-DocumentationAutomation\Core\GitHubPRManager.psm1`
- **Size:** 14.91 KB
- **Last Modified:** 2025-08-26 11:46
- **Total Functions:** 5
- **Exported Functions:** 1




**Key Functions:**
- **New-DocumentationPR** - Line 20 - **Update-DocumentationPR** - Line 171 - **Get-DocumentationPRs** - Line 252 - **Merge-DocumentationPR** - Line 285 - **Test-PRDocumentationChanges** - Line 342


--- 
### GoalManagement

[⬆ Back to Contents](#-table-of-contents)

Specialized module providing targeted functionality for the Unity-Claude automation system. Integrates with the broader architecture to deliver specific capabilities and enhance overall system functionality.

**Module Statistics:**
- Functions: 8
- Dependencies: 1 modules


**Module Information:**
- **Path:** `Modules\Unity-Claude-AutonomousAgent\Core\GoalManagement.psm1`
- **Size:** 15.85 KB
- **Last Modified:** 2025-08-26 11:46
- **Total Functions:** 8
- **Exported Functions:** 4


**Dependencies:**
- `(Join-Path` (external)


**Key Functions:**
- **Add-ConversationGoal** - Line 7 - **Update-ConversationGoal** - Line 86 - **Get-ConversationGoals** - Line 184 - **Calculate-GoalRelevance** - Line 253 - **Calculate-GoalEffectiveness** - Line 332
- *...and 3 more functions*

--- 
### GraphOptimizer

[⬆ Back to Contents](#-table-of-contents)

Specialized module providing targeted functionality for the Unity-Claude automation system. Integrates with the broader architecture to deliver specific capabilities and enhance overall system functionality.

**Module Statistics:**
- Functions: 5
- Classes: 1


**Module Information:**
- **Path:** `Modules\Unity-Claude-ScalabilityEnhancements\Core\GraphOptimizer.psm1`
- **Size:** 12.18 KB
- **Last Modified:** 2025-08-26 11:46
- **Total Functions:** 12
- **Exported Functions:** 1




**Key Functions:**
- **GraphPruner** - Line 15 - **PruneGraph** - Line 28 - **MarkPreservedNodes** - Line 66 - **RemoveUnusedNodes** - Line 77 - **RemoveOrphanedEdges** - Line 99
- *...and 7 more functions*

--- 
### GraphTraversal

[⬆ Back to Contents](#-table-of-contents)

Specialized module providing targeted functionality for the Unity-Claude automation system. Integrates with the broader architecture to deliver specific capabilities and enhance overall system functionality.

**Module Statistics:**
- Functions: 1
- Classes: 2
- Dependencies: 1 modules


**Module Information:**
- **Path:** `Modules\Unity-Claude-CPG\Core\GraphTraversal.psm1`
- **Size:** 10.32 KB
- **Last Modified:** 2025-08-26 11:46
- **Total Functions:** 1
- **Exported Functions:** 1


**Dependencies:**
- `$cpgModule` (external)


**Key Functions:**
- **Find-UnreachableCode** - Line 42


--- 
### HealthMonitoring

[⬆ Back to Contents](#-table-of-contents)

Real-time monitoring module tracking system health, performance metrics, and Unity compilation status. Provides event-driven notifications and triggers automated responses to detected issues.

**Module Statistics:**
- Functions: 4
- Dependencies: 1 modules


**Module Information:**
- **Path:** `Modules\Unity-Claude-AutonomousStateTracker-Enhanced\Core\HealthMonitoring.psm1`
- **Size:** 10.12 KB
- **Last Modified:** 2025-08-26 11:46
- **Total Functions:** 4
- **Exported Functions:** 1


**Dependencies:**
- `(Join-Path` (external)


**Key Functions:**
- **Start-EnhancedHealthMonitoring** - Line 8 - **Stop-EnhancedHealthMonitoring** - Line 100 - **Get-HealthMonitoringStatus** - Line 126 - **Test-AgentHealth** - Line 156


--- 
### HistoryManagement

[⬆ Back to Contents](#-table-of-contents)

Specialized module providing targeted functionality for the Unity-Claude automation system. Integrates with the broader architecture to deliver specific capabilities and enhance overall system functionality.

**Module Statistics:**
- Functions: 7
- Dependencies: 1 modules


**Module Information:**
- **Path:** `Modules\Unity-Claude-AutonomousAgent\Core\HistoryManagement.psm1`
- **Size:** 14.05 KB
- **Last Modified:** 2025-08-26 11:46
- **Total Functions:** 6
- **Exported Functions:** 5


**Dependencies:**
- `(Join-Path` (external)


**Key Functions:**
- **Add-ConversationHistoryItem** - Line 7 - **Get-ConversationHistory** - Line 88 - **Get-ConversationContext** - Line 151 - **Clear-ConversationHistory** - Line 234 - **Get-SessionMetadata** - Line 276
- *...and 1 more functions*

--- 
### HITLCore

[⬆ Back to Contents](#-table-of-contents)

Core infrastructure module providing fundamental functionality for the Unity-Claude system. This module serves as the foundation for other components, offering essential utilities, configuration management, and base services that other modules depend upon.

**Module Statistics:**
- Functions: 2
- Dependencies: 1 modules


**Module Information:**
- **Path:** `Modules\Unity-Claude-HITL\Core\HITLCore.psm1`
- **Size:** 5.03 KB
- **Last Modified:** 2025-08-26 11:46
- **Total Functions:** 2
- **Exported Functions:** 1


**Dependencies:**
- `$governanceModule` (external)


**Key Functions:**
- **Set-HITLConfiguration** - Line 35 - **Get-HITLConfiguration** - Line 74


--- 
### HorizontalScaling

[⬆ Back to Contents](#-table-of-contents)

Specialized module providing targeted functionality for the Unity-Claude automation system. Integrates with the broader architecture to deliver specific capabilities and enhance overall system functionality.

**Module Statistics:**
- Functions: 4
- Classes: 1


**Module Information:**
- **Path:** `Modules\Unity-Claude-ScalabilityEnhancements\Core\HorizontalScaling.psm1`
- **Size:** 10.83 KB
- **Last Modified:** 2025-08-26 11:46
- **Total Functions:** 7
- **Exported Functions:** 1




**Key Functions:**
- **ScalingConfiguration** - Line 13 - **CreatePartitionPlan** - Line 21 - **AssessScalabilityReadiness** - Line 56 - **New-ScalingConfiguration** - Line 106 - **Test-HorizontalReadiness** - Line 131
- *...and 2 more functions*

--- 
### HumanIntervention

[⬆ Back to Contents](#-table-of-contents)

Specialized module providing targeted functionality for the Unity-Claude automation system. Integrates with the broader architecture to deliver specific capabilities and enhance overall system functionality.

**Module Statistics:**
- Functions: 6


**Module Information:**
- **Path:** `Modules\Unity-Claude-AutonomousStateTracker-Enhanced\Core\HumanIntervention.psm1`
- **Size:** 13.89 KB
- **Last Modified:** 2025-08-26 11:46
- **Total Functions:** 6
- **Exported Functions:** 1




**Key Functions:**
- **Request-HumanIntervention** - Line 8 - **Approve-AgentIntervention** - Line 103 - **Deny-AgentIntervention** - Line 157 - **Update-InterventionStatus** - Line 200 - **Get-PendingInterventions** - Line 243
- *...and 1 more functions*

--- 
### ImpactAnalysis

[⬆ Back to Contents](#-table-of-contents)

Specialized module providing targeted functionality for the Unity-Claude automation system. Integrates with the broader architecture to deliver specific capabilities and enhance overall system functionality.

**Module Statistics:**
- Functions: 7


**Module Information:**
- **Path:** `Modules\Unity-Claude-DocumentationDrift\Analysis\ImpactAnalysis.psm1`
- **Size:** 14.86 KB
- **Last Modified:** 2025-08-26 11:46
- **Total Functions:** 7
- **Exported Functions:** 1




**Key Functions:**
- **Analyze-ChangeImpact** - Line 7 - **Analyze-NewFileImpact** - Line 110 - **Analyze-DeletedFileImpact** - Line 163 - **Analyze-ModifiedFileImpact** - Line 200 - **Analyze-RenamedFileImpact** - Line 284
- *...and 2 more functions*

--- 
### ImprovementRoadmaps

[⬆ Back to Contents](#-table-of-contents)

Specialized module providing targeted functionality for the Unity-Claude automation system. Integrates with the broader architecture to deliver specific capabilities and enhance overall system functionality.

**Module Statistics:**
- Functions: 12
- Dependencies: 5 modules


**Module Information:**
- **Path:** `Modules\Unity-Claude-PredictiveAnalysis\Core\ImprovementRoadmaps.psm1`
- **Size:** 36.86 KB
- **Last Modified:** 2025-08-26 11:46
- **Total Functions:** 12
- **Exported Functions:** 1


**Dependencies:**
- `$CorePath` (external) - `$TrendPath` (external) - `$MaintenancePath` (external) - `$RefactoringPath` (external) - `$SmellPath` (external)


**Key Functions:**
- **New-ImprovementRoadmap** - Line 21 - **Create-CriticalPhase** - Line 146 - **Create-HighImpactPhase** - Line 224 - **Create-OptimizationPhase** - Line 302 - **Create-DocumentationPhase** - Line 375
- *...and 7 more functions*

--- 
### IntegratedNotifications

[⬆ Back to Contents](#-table-of-contents)

Specialized module providing targeted functionality for the Unity-Claude automation system. Integrates with the broader architecture to deliver specific capabilities and enhance overall system functionality.

**Module Statistics:**
- Functions: 3


**Module Information:**
- **Path:** `Modules\Unity-Claude-NotificationIntegration\Integration\IntegratedNotifications.psm1`
- **Size:** 11.62 KB
- **Last Modified:** 2025-08-21 17:45
- **Total Functions:** 3
- **Exported Functions:** 1




**Key Functions:**
- **Send-IntegratedNotification** - Line 5 - **Test-IntegratedNotification** - Line 168 - **Validate-CrossModuleMessage** - Line 204


--- 
### IntegrationManagement

[⬆ Back to Contents](#-table-of-contents)

Specialized module providing targeted functionality for the Unity-Claude automation system. Integrates with the broader architecture to deliver specific capabilities and enhance overall system functionality.

**Module Statistics:**
- Functions: 6
- Dependencies: 1 modules


**Module Information:**
- **Path:** `Modules\Unity-Claude-DecisionEngine\Core\IntegrationManagement.psm1`
- **Size:** 13.75 KB
- **Last Modified:** 2025-08-26 11:46
- **Total Functions:** 6
- **Exported Functions:** 1


**Dependencies:**
- `$corePath` (external)


**Key Functions:**
- **Connect-IntelligentPromptEngine** - Line 20 - **Connect-ConversationManager** - Line 58 - **Get-DecisionEngineStatus** - Line 99 - **Test-DecisionEngineIntegration** - Line 158 - **Get-DecisionEngineComponents** - Line 253
- *...and 1 more functions*

--- 
### IntelligentPromptEngine

[⬆ Back to Contents](#-table-of-contents)

Specialized module providing targeted functionality for the Unity-Claude automation system. Integrates with the broader architecture to deliver specific capabilities and enhance overall system functionality.

**Module Statistics:**
- Functions: 5
- Dependencies: 5 modules


**Module Information:**
- **Path:** `Modules\Unity-Claude-AutonomousAgent\IntelligentPromptEngine.psm1`
- **Size:** 17.39 KB
- **Last Modified:** 2025-08-26 11:46
- **Total Functions:** 5
- **Exported Functions:** 2


**Dependencies:**
- `$PSScriptRoot\Core\AgentLogging.psm1` (external) - `$PSScriptRoot\Core\PromptConfiguration.psm1` (external) - `$PSScriptRoot\Core\ResultAnalysisEngine.psm1` (external) - `$PSScriptRoot\Core\PromptTypeSelection.psm1` (external) - `$PSScriptRoot\Core\PromptTemplateSystem.psm1` (external)


**Key Functions:**
- **Invoke-IntelligentPromptGeneration** - Line 41 - **New-FallbackPrompt** - Line 155 - **Get-PromptEngineStatus** - Line 208 - **Test-ComponentAvailability** - Line 274 - **Initialize-IntelligentPromptEngine** - Line 290


--- 
### IntelligentPromptEngine-Refactored

[⬆ Back to Contents](#-table-of-contents)

Specialized module providing targeted functionality for the Unity-Claude automation system. Integrates with the broader architecture to deliver specific capabilities and enhance overall system functionality.

**Module Statistics:**
- Functions: 5
- Dependencies: 5 modules


**Module Information:**
- **Path:** `Modules\Unity-Claude-AutonomousAgent\IntelligentPromptEngine-Refactored.psm1`
- **Size:** 17.39 KB
- **Last Modified:** 2025-08-26 11:46
- **Total Functions:** 5
- **Exported Functions:** 2


**Dependencies:**
- `$PSScriptRoot\Core\AgentLogging.psm1` (external) - `$PSScriptRoot\Core\PromptConfiguration.psm1` (external) - `$PSScriptRoot\Core\ResultAnalysisEngine.psm1` (external) - `$PSScriptRoot\Core\PromptTypeSelection.psm1` (external) - `$PSScriptRoot\Core\PromptTemplateSystem.psm1` (external)


**Key Functions:**
- **Invoke-IntelligentPromptGeneration** - Line 41 - **New-FallbackPrompt** - Line 155 - **Get-PromptEngineStatus** - Line 208 - **Test-ComponentAvailability** - Line 274 - **Initialize-IntelligentPromptEngine** - Line 290


--- 
### JobScheduler

[⬆ Back to Contents](#-table-of-contents)

Specialized module providing targeted functionality for the Unity-Claude automation system. Integrates with the broader architecture to deliver specific capabilities and enhance overall system functionality.

**Module Statistics:**
- Functions: 1
- Classes: 2
- Dependencies: 2 modules


**Module Information:**
- **Path:** `Modules\Unity-Claude-ParallelProcessor\Core\JobScheduler.psm1`
- **Size:** 19.46 KB
- **Last Modified:** 2025-08-26 11:46
- **Total Functions:** 17
- **Exported Functions:** 1


**Dependencies:**
- `$PSScriptRoot\ParallelProcessorCore.psm1` (external) - `$PSScriptRoot\RunspacePoolManager.psm1` (external)


**Key Functions:**
- **ParallelJob** - Line 30 - **GetDuration** - Line 42 - **GetSummary** - Line 51 - **JobScheduler** - Line 76 - **SubmitJob** - Line 95
- *...and 12 more functions*

--- 
### JsonProcessing

[⬆ Back to Contents](#-table-of-contents)

Specialized module providing targeted functionality for the Unity-Claude automation system. Integrates with the broader architecture to deliver specific capabilities and enhance overall system functionality.

**Module Statistics:**
- Functions: 10
- Dependencies: 1 modules


**Module Information:**
- **Path:** `Modules\Unity-Claude-CLIOrchestrator\Core\Components\JsonProcessing.psm1`
- **Size:** 19.5 KB
- **Last Modified:** 2025-08-26 11:46
- **Total Functions:** 10
- **Exported Functions:** 1


**Dependencies:**
- `$loggingPath` (external)


**Key Functions:**
- **Write-AnalysisLog** - Line 17 - **Test-JsonTruncation** - Line 39 - **Repair-TruncatedJson** - Line 76 - **ConvertFrom-JsonFast** - Line 128 - **Invoke-MultiParserJson** - Line 159
- *...and 5 more functions*

--- 
### LearningAdaptation

[⬆ Back to Contents](#-table-of-contents)

Machine learning module that improves system performance over time. Tracks success patterns, identifies optimal configurations, and adapts behavior based on historical outcomes.

**Module Statistics:**
- Functions: 3


**Module Information:**
- **Path:** `Modules\Unity-Claude-CLIOrchestrator\Core\DecisionEngine-Bayesian\LearningAdaptation.psm1`
- **Size:** 7.47 KB
- **Last Modified:** 2025-08-26 11:46
- **Total Functions:** 3
- **Exported Functions:** 3




**Key Functions:**
- **Update-BayesianLearning** - Line 9 - **Save-BayesianLearning** - Line 80 - **Initialize-BayesianLearning** - Line 107


--- 
### LearningCore

[⬆ Back to Contents](#-table-of-contents)

Core infrastructure module providing fundamental functionality for the Unity-Claude system. This module serves as the foundation for other components, offering essential utilities, configuration management, and base services that other modules depend upon. Machine learning module that improves system performance over time. Tracks success patterns, identifies optimal configurations, and adapts behavior based on historical outcomes. 

**Module Statistics:**
 - Functions: 11


**Module Information:**
- **Path:** `Modules\Unity-Claude-Learning\Core\LearningCore.psm1`
- **Size:** 8.16 KB
- **Last Modified:** 2025-08-26 11:46
- **Total Functions:** 9
- **Exported Functions:** 1




**Key Functions:**
- **Write-LearningLog** - Line 26 - **Get-LearningConfig** - Line 46 - **Set-LearningConfig** - Line 61 - **Get-PatternCache** - Line 106 - **Update-PatternCache** - Line 118
- *...and 4 more functions*

--- 
### LLM-PromptTemplates

[⬆ Back to Contents](#-table-of-contents)

Specialized module providing targeted functionality for the Unity-Claude automation system. Integrates with the broader architecture to deliver specific capabilities and enhance overall system functionality.

**Module Statistics:**
- Functions: 17
- Classes: 3


**Module Information:**
- **Path:** `Modules\Unity-Claude-LLM\Core\LLM-PromptTemplates.psm1`
- **Size:** 13.57 KB
- **Last Modified:** 2025-08-28 13:58
- **Total Functions:** 15
- **Exported Functions:** 1




**Key Functions:**
- **Get-FunctionDocumentationTemplate** - Line 12 - **Get-ModuleDocumentationTemplate** - Line 42 - **Get-ClassDocumentationTemplate** - Line 73 - **Get-APIDocumentationTemplate** - Line 104 - **Get-SecurityAnalysisTemplate** - Line 139
- *...and 10 more functions*

--- 
### LLM-ResponseCache

[⬆ Back to Contents](#-table-of-contents)

Intelligent caching module optimizing performance through strategic data persistence. Implements LRU caching, dependency tracking, and automatic invalidation to reduce redundant computations.

**Module Statistics:**
- Functions: 14


**Module Information:**
- **Path:** `Modules\Unity-Claude-LLM\Core\LLM-ResponseCache.psm1`
- **Size:** 13.88 KB
- **Last Modified:** 2025-08-30 19:47
- **Total Functions:** 14
- **Exported Functions:** 1




**Key Functions:**
- **Get-CacheKey** - Line 35 - **Get-CachedResponse** - Line 58 - **Set-CachedResponse** - Line 107 - **Remove-CacheEntry** - Line 148 - **Clear-ExpiredCache** - Line 167
- *...and 9 more functions*

--- 
### MaintenancePrediction

[⬆ Back to Contents](#-table-of-contents)

Artificial Intelligence integration module that bridges PowerShell automation with AI services. Provides intelligent error analysis, pattern recognition, and automated decision-making capabilities through Claude AI or local LLM integration.

**Module Statistics:**
- Functions: 3
- Dependencies: 2 modules


**Module Information:**
- **Path:** `Modules\Unity-Claude-PredictiveAnalysis\Core\MaintenancePrediction.psm1`
- **Size:** 13.96 KB
- **Last Modified:** 2025-08-26 11:46
- **Total Functions:** 2
- **Exported Functions:** 1


**Dependencies:**
- `$CorePath` (external) - `$TrendPath` (external)


**Key Functions:**
- **Get-MaintenancePrediction** - Line 15 - **Calculate-TechnicalDebt** - Line 180


--- 
### MemoryManager

[⬆ Back to Contents](#-table-of-contents)

Specialized module providing targeted functionality for the Unity-Claude automation system. Integrates with the broader architecture to deliver specific capabilities and enhance overall system functionality.

**Module Statistics:**
- Functions: 5
- Classes: 1


**Module Information:**
- **Path:** `Modules\Unity-Claude-ScalabilityEnhancements\Core\MemoryManager.psm1`
- **Size:** 9 KB
- **Last Modified:** 2025-08-26 11:46
- **Total Functions:** 13
- **Exported Functions:** 1




**Key Functions:**
- **MemoryManager** - Line 11 - **StartMonitoring** - Line 23 - **UpdateMemoryStatistics** - Line 37 - **GetMemoryUsageReport** - Line 50 - **OptimizeMemory** - Line 69
- *...and 8 more functions*

--- 
### MetricsAndHealthCheck

[⬆ Back to Contents](#-table-of-contents)

Specialized module providing targeted functionality for the Unity-Claude automation system. Integrates with the broader architecture to deliver specific capabilities and enhance overall system functionality.

**Module Statistics:**
- Functions: 13


**Module Information:**
- **Path:** `Modules\Unity-Claude-NotificationIntegration\Monitoring\MetricsAndHealthCheck.psm1`
- **Size:** 20.09 KB
- **Last Modified:** 2025-08-21 17:45
- **Total Functions:** 13
- **Exported Functions:** 1




**Key Functions:**
- **Get-NotificationMetrics** - Line 7 - **Get-NotificationHealthCheck** - Line 78 - **New-NotificationReport** - Line 146 - **Export-NotificationAnalytics** - Line 203 - **Reset-NotificationMetrics** - Line 248
- *...and 8 more functions*

--- 
### MetricsCollection

[⬆ Back to Contents](#-table-of-contents)

Specialized module providing targeted functionality for the Unity-Claude automation system. Integrates with the broader architecture to deliver specific capabilities and enhance overall system functionality.

**Module Statistics:**
- Functions: 11
- Dependencies: 2 modules


**Module Information:**
- **Path:** `Modules\Unity-Claude-Learning\Core\MetricsCollection.psm1`
- **Size:** 15.74 KB
- **Last Modified:** 2025-08-26 11:46
- **Total Functions:** 11
- **Exported Functions:** 1


**Dependencies:**
- `$CorePath` (external) - `$SuccessPath` (external)


**Key Functions:**
- **Write-ModuleLog** - Line 13 - **Start-PerformanceTimer** - Line 37 - **Stop-PerformanceTimer** - Line 70 - **Get-PerformanceMetrics** - Line 116 - **Update-CacheMetrics** - Line 157
- *...and 6 more functions*

--- 
### ModuleFunctions

[⬆ Back to Contents](#-table-of-contents)

Specialized module providing targeted functionality for the Unity-Claude automation system. Integrates with the broader architecture to deliver specific capabilities and enhance overall system functionality.

**Module Statistics:**
- Functions: 7
- Classes: 1
- Dependencies: 5 modules


**Module Information:**
- **Path:** `Modules\Unity-Claude-ParallelProcessor\Core\ModuleFunctions.psm1`
- **Size:** 19.46 KB
- **Last Modified:** 2025-08-26 11:46
- **Total Functions:** 24
- **Exported Functions:** 3


**Dependencies:**
- `$PSScriptRoot\ParallelProcessorCore.psm1` (external) - `$PSScriptRoot\RunspacePoolManager.psm1` (external) - `$PSScriptRoot\JobScheduler.psm1` (external) - `$PSScriptRoot\StatisticsTracker.psm1` (external) - `$PSScriptRoot\BatchProcessingEngine.psm1` (external)


**Key Functions:**
- **ParallelProcessor** - Line 32 - **ParallelProcessor** - Line 36 - **ParallelProcessor** - Line 40 - **Initialize** - Line 44 - **SubmitJob** - Line 88
- *...and 19 more functions*

--- 
### ModuleIntegration

[⬆ Back to Contents](#-table-of-contents)

Specialized module providing targeted functionality for the Unity-Claude automation system. Integrates with the broader architecture to deliver specific capabilities and enhance overall system functionality.

**Module Statistics:**
- Functions: 8
- Dependencies: 3 modules


**Module Information:**
- **Path:** `Modules\Unity-Claude-MasterOrchestrator\Core\ModuleIntegration.psm1`
- **Size:** 13.68 KB
- **Last Modified:** 2025-08-26 11:46
- **Total Functions:** 4
- **Exported Functions:** 1


**Dependencies:**
- `$PSScriptRoot\OrchestratorCore.psm1` (external) - `$path` (external) - `$ModuleName` (external)


**Key Functions:**
- **Test-ModuleAvailability** - Line 19 - **Initialize-ModuleIntegration** - Line 97 - **Initialize-SingleModule** - Line 192 - **Get-ModuleIntegrationPoints** - Line 252


--- 
### ModuleVariablePreloading

[⬆ Back to Contents](#-table-of-contents)

Specialized module providing targeted functionality for the Unity-Claude automation system. Integrates with the broader architecture to deliver specific capabilities and enhance overall system functionality.

**Module Statistics:**
- Functions: 7


**Module Information:**
- **Path:** `Modules\Unity-Claude-RunspaceManagement\Core\ModuleVariablePreloading.psm1`
- **Size:** 11.65 KB
- **Last Modified:** 2025-08-26 11:46
- **Total Functions:** 7
- **Exported Functions:** 1




**Key Functions:**
- **Write-ModuleLog** - Line 21 - **Add-SessionStateVariable** - Line 26 - **Add-SessionStateModule** - Line 27 - **Import-SessionStateModules** - Line 34 - **Initialize-SessionStateVariables** - Line 100
- *...and 2 more functions*

--- 
### MonitoringLoop

[⬆ Back to Contents](#-table-of-contents)

Real-time monitoring module tracking system health, performance metrics, and Unity compilation status. Provides event-driven notifications and triggers automated responses to detected issues.

**Module Statistics:**
- Functions: 3


**Module Information:**
- **Path:** `Modules\Unity-Claude-CLIOrchestrator\Core\OrchestrationComponents\MonitoringLoop.psm1`
- **Size:** 15.08 KB
- **Last Modified:** 2025-08-27 19:19
- **Total Functions:** 3





**Key Functions:**
- **Start-MonitoringLoop** - Line 4 - **Invoke-SingleExecutionCycle** - Line 111 - **Process-SignalFile** - Line 191


--- 
### NotificationCore

[⬆ Back to Contents](#-table-of-contents)

Core infrastructure module providing fundamental functionality for the Unity-Claude system. This module serves as the foundation for other components, offering essential utilities, configuration management, and base services that other modules depend upon.

**Module Statistics:**
- Functions: 6


**Module Information:**
- **Path:** `Modules\Unity-Claude-NotificationIntegration\Core\NotificationCore.psm1`
- **Size:** 16.34 KB
- **Last Modified:** 2025-08-21 17:45
- **Total Functions:** 6
- **Exported Functions:** 1




**Key Functions:**
- **Initialize-NotificationIntegration** - Line 18 - **Register-NotificationHook** - Line 107 - **Unregister-NotificationHook** - Line 185 - **Get-NotificationHooks** - Line 222 - **Clear-NotificationHooks** - Line 266
- *...and 1 more functions*

--- 
### NotificationSystem

[⬆ Back to Contents](#-table-of-contents)

Specialized module providing targeted functionality for the Unity-Claude automation system. Integrates with the broader architecture to deliver specific capabilities and enhance overall system functionality.

**Module Statistics:**
- Functions: 4
- Dependencies: 1 modules


**Module Information:**
- **Path:** `Modules\Unity-Claude-HITL\Core\NotificationSystem.psm1`
- **Size:** 12.66 KB
- **Last Modified:** 2025-08-26 11:46
- **Total Functions:** 4
- **Exported Functions:** 1


**Dependencies:**
- `$coreModule` (external)


**Key Functions:**
- **Send-ApprovalNotification** - Line 14 - **Build-ApprovalEmailTemplate** - Line 98 - **Send-ApprovalReminder** - Line 198 - **Send-ApprovalResultNotification** - Line 234


--- 
### OptimizerConfiguration

[⬆ Back to Contents](#-table-of-contents)

Specialized module providing targeted functionality for the Unity-Claude automation system. Integrates with the broader architecture to deliver specific capabilities and enhance overall system functionality.

**Module Statistics:**
- Functions: 6


**Module Information:**
- **Path:** `Modules\Unity-Claude-PerformanceOptimizer\Core\OptimizerConfiguration.psm1`
- **Size:** 7.06 KB
- **Last Modified:** 2025-08-26 11:46
- **Total Functions:** 6
- **Exported Functions:** 1




**Key Functions:**
- **Initialize-PerformanceMetrics** - Line 8 - **Get-OptimalThreadCount** - Line 28 - **Get-FilePriority** - Line 48 - **Initialize-OptimizerComponents** - Line 63 - **Get-DefaultOptimizerConfiguration** - Line 111
- *...and 1 more functions*

--- 
### OrchestrationCore

[⬆ Back to Contents](#-table-of-contents)

Core infrastructure module providing fundamental functionality for the Unity-Claude system. This module serves as the foundation for other components, offering essential utilities, configuration management, and base services that other modules depend upon. Master orchestration module coordinating complex multi-step workflows. Manages module interactions, handles state transitions, and ensures proper sequencing of automated operations. 

**Module Statistics:**
 - Functions: 3


**Module Information:**
- **Path:** `Modules\Unity-Claude-CLIOrchestrator\Core\OrchestrationComponents\OrchestrationCore.psm1`
- **Size:** 9.09 KB
- **Last Modified:** 2025-08-27 15:25
- **Total Functions:** 3





**Key Functions:**
- **Start-CLIOrchestration** - Line 4 - **Get-CLIOrchestrationStatus** - Line 114 - **Initialize-OrchestrationEnvironment** - Line 176


--- 
### OrchestrationManager

[⬆ Back to Contents](#-table-of-contents)

Master orchestration module coordinating complex multi-step workflows. Manages module interactions, handles state transitions, and ensures proper sequencing of automated operations.

**Module Statistics:**
- Functions: 5


**Module Information:**
- **Path:** `Modules\Unity-Claude-CLIOrchestrator\Core\OrchestrationManager.psm1`
- **Size:** 52.72 KB
- **Last Modified:** 2025-08-27 19:57
- **Total Functions:** 1
- **Exported Functions:** 1




**Key Functions:**
- **Start-CLIOrchestration** - Line 20


--- 
### OrchestrationManager-Refactored

[⬆ Back to Contents](#-table-of-contents)

Master orchestration module coordinating complex multi-step workflows. Manages module interactions, handles state transitions, and ensures proper sequencing of automated operations.

**Module Statistics:**
- Functions: 0


**Module Information:**
- **Path:** `Modules\Unity-Claude-CLIOrchestrator\Core\OrchestrationManager-Refactored.psm1`
- **Size:** 3.27 KB
- **Last Modified:** 2025-08-27 15:15
- **Total Functions:** 0
- **Exported Functions:** 1





--- 
### OrchestratorCore

[⬆ Back to Contents](#-table-of-contents)

Core infrastructure module providing fundamental functionality for the Unity-Claude system. This module serves as the foundation for other components, offering essential utilities, configuration management, and base services that other modules depend upon. Master orchestration module coordinating complex multi-step workflows. Manages module interactions, handles state transitions, and ensures proper sequencing of automated operations. 

**Module Statistics:**
 - Functions: 5


**Module Information:**
- **Path:** `Modules\Unity-Claude-MasterOrchestrator\Core\OrchestratorCore.psm1`
- **Size:** 7.61 KB
- **Last Modified:** 2025-08-26 11:46
- **Total Functions:** 5
- **Exported Functions:** 1




**Key Functions:**
- **Write-OrchestratorLog** - Line 84 - **Get-OrchestratorConfig** - Line 129 - **Set-OrchestratorConfig** - Line 137 - **Get-ModuleArchitecture** - Line 155 - **Get-OrchestratorState** - Line 163


--- 
### OrchestratorManagement

[⬆ Back to Contents](#-table-of-contents)

Master orchestration module coordinating complex multi-step workflows. Manages module interactions, handles state transitions, and ensures proper sequencing of automated operations.

**Module Statistics:**
- Functions: 7
- Dependencies: 5 modules


**Module Information:**
- **Path:** `Modules\Unity-Claude-MasterOrchestrator\Core\OrchestratorManagement.psm1`
- **Size:** 16.16 KB
- **Last Modified:** 2025-08-26 11:46
- **Total Functions:** 6
- **Exported Functions:** 1


**Dependencies:**
- `$PSScriptRoot\OrchestratorCore.psm1` (external) - `$PSScriptRoot\ModuleIntegration.psm1` (external) - `$PSScriptRoot\EventProcessing.psm1` (external) - `$PSScriptRoot\DecisionExecution.psm1` (external) - `$PSScriptRoot\AutonomousFeedbackLoop.psm1` (external)


**Key Functions:**
- **Get-OrchestratorStatus** - Line 23 - **Test-OrchestratorIntegration** - Line 66 - **Get-OperationHistory** - Line 141 - **Clear-OrchestratorState** - Line 185 - **Get-OrchestratorHealth** - Line 253
- *...and 1 more functions*

--- 
### PaginationProvider

[⬆ Back to Contents](#-table-of-contents)

Specialized module providing targeted functionality for the Unity-Claude automation system. Integrates with the broader architecture to deliver specific capabilities and enhance overall system functionality.

**Module Statistics:**
- Functions: 5
- Classes: 1


**Module Information:**
- **Path:** `Modules\Unity-Claude-ScalabilityEnhancements\Core\PaginationProvider.psm1`
- **Size:** 8.05 KB
- **Last Modified:** 2025-08-26 11:46
- **Total Functions:** 10
- **Exported Functions:** 1




**Key Functions:**
- **PaginationProvider** - Line 14 - **GetPage** - Line 23 - **GetPageInfo** - Line 43 - **GetNextPage** - Line 54 - **GetPreviousPage** - Line 61
- *...and 5 more functions*

--- 
### ParallelizationCore

[⬆ Back to Contents](#-table-of-contents)

Core infrastructure module providing fundamental functionality for the Unity-Claude system. This module serves as the foundation for other components, offering essential utilities, configuration management, and base services that other modules depend upon. High-performance parallel processing module designed to maximize throughput and system utilization. Implements thread-safe operations, runspace management, and concurrent execution patterns to handle multiple Unity operations simultaneously without blocking. 

**Module Statistics:**
 - Functions: 8
 - Dependencies: 2 modules


**Module Information:**
- **Path:** `Modules\Unity-Claude-UnityParallelization\Core\ParallelizationCore.psm1`
- **Size:** 9.75 KB
- **Last Modified:** 2025-08-26 11:46
- **Total Functions:** 6
- **Exported Functions:** 1


**Dependencies:**
- [`Unity-Claude-RunspaceManagement`](#unity-claude-runspacemanagement) - [`Unity-Claude-ParallelProcessing`](#unity-claude-parallelprocessing)


**Key Functions:**
- **Test-ModuleDependencyAvailability** - Line 46 - **Initialize-ModuleDependencies** - Line 79 - **Write-FallbackLog** - Line 121 - **Write-UnityParallelLog** - Line 145 - **Get-UnityParallelizationConfig** - Line 169
- *...and 1 more functions*

--- 
### ParallelMonitoring

[⬆ Back to Contents](#-table-of-contents)

High-performance parallel processing module designed to maximize throughput and system utilization. Implements thread-safe operations, runspace management, and concurrent execution patterns to handle multiple Unity operations simultaneously without blocking. Real-time monitoring module tracking system health, performance metrics, and Unity compilation status. Provides event-driven notifications and triggers automated responses to detected issues. 

**Module Statistics:**
 - Functions: 4
 - Dependencies: 2 modules


**Module Information:**
- **Path:** `Modules\Unity-Claude-UnityParallelization\Core\ParallelMonitoring.psm1`
- **Size:** 26.79 KB
- **Last Modified:** 2025-08-26 11:46
- **Total Functions:** 4
- **Exported Functions:** 1


**Dependencies:**
- `$PSScriptRoot\ParallelizationCore.psm1` (external) - `$PSScriptRoot\ProjectConfiguration.psm1` (external)


**Key Functions:**
- **New-UnityParallelMonitor** - Line 22 - **Start-UnityParallelMonitoring** - Line 209 - **Stop-UnityParallelMonitoring** - Line 402 - **Get-UnityMonitoringStatus** - Line 470


--- 
### ParallelProcessorCore

[⬆ Back to Contents](#-table-of-contents)

Core infrastructure module providing fundamental functionality for the Unity-Claude system. This module serves as the foundation for other components, offering essential utilities, configuration management, and base services that other modules depend upon. High-performance parallel processing module designed to maximize throughput and system utilization. Implements thread-safe operations, runspace management, and concurrent execution patterns to handle multiple Unity operations simultaneously without blocking. 

**Module Statistics:**
 - Functions: 11


**Module Information:**
- **Path:** `Modules\Unity-Claude-ParallelProcessor\Core\ParallelProcessorCore.psm1`
- **Size:** 10.13 KB
- **Last Modified:** 2025-08-26 11:46
- **Total Functions:** 11
- **Exported Functions:** 2




**Key Functions:**
- **Write-ParallelProcessorLog** - Line 36 - **Set-ParallelProcessorDebugMode** - Line 73 - **Get-OptimalThreadCount** - Line 88 - **New-ProcessorId** - Line 120 - **Register-ParallelProcessor** - Line 129
- *...and 6 more functions*

--- 
### PatternAnalysis

[⬆ Back to Contents](#-table-of-contents)

Specialized module providing targeted functionality for the Unity-Claude automation system. Integrates with the broader architecture to deliver specific capabilities and enhance overall system functionality.

**Module Statistics:**
- Functions: 3


**Module Information:**
- **Path:** `Modules\Unity-Claude-CLIOrchestrator\Core\DecisionEngine-Bayesian\PatternAnalysis.psm1`
- **Size:** 8.57 KB
- **Last Modified:** 2025-08-26 11:46
- **Total Functions:** 3
- **Exported Functions:** 3




**Key Functions:**
- **Build-NGramModel** - Line 9 - **Calculate-PatternSimilarity** - Line 73 - **Get-LevenshteinDistance** - Line 159


--- 
### PatternRecognition

[⬆ Back to Contents](#-table-of-contents)

Specialized module providing targeted functionality for the Unity-Claude automation system. Integrates with the broader architecture to deliver specific capabilities and enhance overall system functionality.

**Module Statistics:**
- Functions: 5
- Dependencies: 4 modules


**Module Information:**
- **Path:** `Modules\Unity-Claude-Learning\Core\PatternRecognition.psm1`
- **Size:** 15.02 KB
- **Last Modified:** 2025-08-26 11:46
- **Total Functions:** 5
- **Exported Functions:** 1


**Dependencies:**
- `$CorePath` (external) - `$DatabasePath` (external) - `$StringPath` (external) - `$ASTPath` (external)


**Key Functions:**
- **Add-ErrorPattern** - Line 18 - **Add-ErrorPatternSQLite** - Line 114 - **Find-SimilarPatterns** - Line 195 - **Find-SimilarPatternsMemory** - Line 242 - **Calculate-ConfidenceScore** - Line 306


--- 
### PatternRecognitionEngine

[⬆ Back to Contents](#-table-of-contents)

Specialized module providing targeted functionality for the Unity-Claude automation system. Integrates with the broader architecture to deliver specific capabilities and enhance overall system functionality.

**Module Statistics:**
- Functions: 4
- Dependencies: 4 modules


**Module Information:**
- **Path:** `Modules\Unity-Claude-CLIOrchestrator\Core\PatternRecognitionEngine.psm1`
- **Size:** 11.03 KB
- **Last Modified:** 2025-08-26 22:06
- **Total Functions:** 4
- **Exported Functions:** 1


**Dependencies:**
- `$moduleBasePath\RecommendationPatternEngine.psm1` (external) - `$moduleBasePath\EntityContextEngine.psm1` (external) - `$moduleBasePath\ResponseClassificationEngine.psm1` (external) - `$moduleBasePath\BayesianConfidenceEngine.psm1` (external)


**Key Functions:**
- **Write-PatternLog** - Line 35 - **Invoke-PatternRecognitionAnalysis** - Line 70 - **Test-PatternRecognitionPerformance** - Line 163 - **Get-PatternRecognitionStatus** - Line 200


--- 
### PatternRecognitionEngine-Fixed

[⬆ Back to Contents](#-table-of-contents)

Specialized module providing targeted functionality for the Unity-Claude automation system. Integrates with the broader architecture to deliver specific capabilities and enhance overall system functionality.

**Module Statistics:**
- Functions: 5
- Dependencies: 1 modules


**Module Information:**
- **Path:** `Modules\Unity-Claude-CLIOrchestrator\Core\PatternRecognitionEngine-Fixed.psm1`
- **Size:** 8.86 KB
- **Last Modified:** 2025-08-27 16:51
- **Total Functions:** 4
- **Exported Functions:** 1


**Dependencies:**
- `to` (external)


**Key Functions:**
- **Write-PatternLog** - Line 63 - **Invoke-PatternRecognitionAnalysis** - Line 92 - **Get-CachedPattern** - Line 206 - **Set-CachedPattern** - Line 227


--- 
### PatternRecognitionEngine-New

[⬆ Back to Contents](#-table-of-contents)

Specialized module providing targeted functionality for the Unity-Claude automation system. Integrates with the broader architecture to deliver specific capabilities and enhance overall system functionality.

**Module Statistics:**
- Functions: 4
- Dependencies: 4 modules


**Module Information:**
- **Path:** `Modules\Unity-Claude-CLIOrchestrator\Core\PatternRecognitionEngine-New.psm1`
- **Size:** 11.06 KB
- **Last Modified:** 2025-08-25 14:20
- **Total Functions:** 4
- **Exported Functions:** 1


**Dependencies:**
- `$moduleBasePath\RecommendationPatternEngine.psm1` (external) - `$moduleBasePath\EntityContextEngine.psm1` (external) - `$moduleBasePath\ResponseClassificationEngine.psm1` (external) - `$moduleBasePath\BayesianConfidenceEngine.psm1` (external)


**Key Functions:**
- **Write-PatternLog** - Line 35 - **Invoke-PatternRecognitionAnalysis** - Line 70 - **Test-PatternRecognitionPerformance** - Line 163 - **Get-PatternRecognitionStatus** - Line 200


--- 
### PatternRecognitionEngine-Original

[⬆ Back to Contents](#-table-of-contents)

Specialized module providing targeted functionality for the Unity-Claude automation system. Integrates with the broader architecture to deliver specific capabilities and enhance overall system functionality.

**Module Statistics:**
- Functions: 34


**Module Information:**
- **Path:** `Modules\Unity-Claude-CLIOrchestrator\Core\PatternRecognitionEngine-Original.psm1`
- **Size:** 89.32 KB
- **Last Modified:** 2025-08-25 14:20
- **Total Functions:** 33
- **Exported Functions:** 1




**Key Functions:**
- **Initialize-CompiledPatterns** - Line 316 - **Test-PatternValidation** - Line 361 - **Get-EnhancedPatternMatch** - Line 401 - **Write-PatternLog** - Line 475 - **Find-RecommendationPatterns** - Line 514
- *...and 28 more functions*

--- 
### Performance-Cache

[⬆ Back to Contents](#-table-of-contents)

Intelligent caching module optimizing performance through strategic data persistence. Implements LRU caching, dependency tracking, and automatic invalidation to reduce redundant computations.

**Module Statistics:**
- Functions: 9
- Classes: 4


**Module Information:**
- **Path:** `Modules\Unity-Claude-CPG\Core\Performance-Cache.psm1`
- **Size:** 20.32 KB
- **Last Modified:** 2025-08-28 16:26
- **Total Functions:** 32
- **Exported Functions:** 1




**Key Functions:**
- **CacheItem** - Line 19 - **IsExpired** - Line 33 - **UpdateAccess** - Line 37 - **GetHitRatio** - Line 54 - **GetUptime** - Line 59
- *...and 27 more functions*

--- 
### Performance-IncrementalUpdates

[⬆ Back to Contents](#-table-of-contents)

Specialized module providing targeted functionality for the Unity-Claude automation system. Integrates with the broader architecture to deliver specific capabilities and enhance overall system functionality.

**Module Statistics:**
- Functions: 9
- Classes: 4


**Module Information:**
- **Path:** `Modules\Unity-Claude-CPG\Core\Performance-IncrementalUpdates.psm1`
- **Size:** 27.26 KB
- **Last Modified:** 2025-08-28 16:49
- **Total Functions:** 23
- **Exported Functions:** 1




**Key Functions:**
- **FileChangeInfo** - Line 20 - **HasChanged** - Line 34 - **ComputeHash** - Line 54 - **DiffResult** - Line 83 - **IncrementalUpdateEngine** - Line 108
- *...and 18 more functions*

--- 
### PerformanceAnalysis

[⬆ Back to Contents](#-table-of-contents)

Specialized module providing targeted functionality for the Unity-Claude automation system. Integrates with the broader architecture to deliver specific capabilities and enhance overall system functionality.

**Module Statistics:**
- Functions: 3
- Dependencies: 1 modules


**Module Information:**
- **Path:** `Modules\Unity-Claude-IntegratedWorkflow\Core\PerformanceAnalysis.psm1`
- **Size:** 15.12 KB
- **Last Modified:** 2025-08-26 11:46
- **Total Functions:** 2
- **Exported Functions:** 1


**Dependencies:**
- `$CorePath` (external)


**Key Functions:**
- **Get-WorkflowPerformanceAnalysis** - Line 17 - **Get-OptimizationRecommendations** - Line 213


--- 
### PerformanceMonitoring

[⬆ Back to Contents](#-table-of-contents)

Real-time monitoring module tracking system health, performance metrics, and Unity compilation status. Provides event-driven notifications and triggers automated responses to detected issues.

**Module Statistics:**
- Functions: 6


**Module Information:**
- **Path:** `Modules\Unity-Claude-PerformanceOptimizer\Core\PerformanceMonitoring.psm1`
- **Size:** 9.89 KB
- **Last Modified:** 2025-08-26 11:46
- **Total Functions:** 6
- **Exported Functions:** 1




**Key Functions:**
- **Update-PerformanceMetrics** - Line 8 - **Get-PerformanceBottlenecks** - Line 62 - **New-PerformanceTimer** - Line 109 - **Get-ThroughputAnalysis** - Line 130 - **Test-PerformanceOptimizationNeeded** - Line 174
- *...and 1 more functions*

--- 
### PerformanceOptimization

[⬆ Back to Contents](#-table-of-contents)

Specialized module providing targeted functionality for the Unity-Claude automation system. Integrates with the broader architecture to deliver specific capabilities and enhance overall system functionality.

**Module Statistics:**
- Functions: 8


**Module Information:**
- **Path:** `Modules\Unity-Claude-PerformanceOptimizer\Core\PerformanceOptimization.psm1`
- **Size:** 9.84 KB
- **Last Modified:** 2025-08-26 11:46
- **Total Functions:** 8
- **Exported Functions:** 1




**Key Functions:**
- **Optimize-Performance** - Line 5 - **Optimize-BatchSize** - Line 46 - **Optimize-CacheSettings** - Line 69 - **Optimize-MemoryUsage** - Line 105 - **Clear-CompletedQueue** - Line 125
- *...and 3 more functions*

--- 
### PerformanceOptimizer

[⬆ Back to Contents](#-table-of-contents)

Specialized module providing targeted functionality for the Unity-Claude automation system. Integrates with the broader architecture to deliver specific capabilities and enhance overall system functionality.

**Module Statistics:**
- Functions: 14


**Module Information:**
- **Path:** `Modules\Unity-Claude-CLIOrchestrator\Core\PerformanceOptimizer.psm1`
- **Size:** 26.96 KB
- **Last Modified:** 2025-08-29 20:46
- **Total Functions:** 14
- **Exported Functions:** 1




**Key Functions:**
- **Get-CacheKey** - Line 37 - **Get-StringHash** - Line 61 - **Get-CachedResult** - Line 76 - **Set-CachedResult** - Line 109 - **Get-CompiledRegex** - Line 149
- *...and 9 more functions*

--- 
### PersistenceManagement

[⬆ Back to Contents](#-table-of-contents)

Specialized module providing targeted functionality for the Unity-Claude automation system. Integrates with the broader architecture to deliver specific capabilities and enhance overall system functionality.

**Module Statistics:**
- Functions: 8
- Dependencies: 1 modules


**Module Information:**
- **Path:** `Modules\Unity-Claude-AutonomousAgent\Core\PersistenceManagement.psm1`
- **Size:** 19.12 KB
- **Last Modified:** 2025-08-26 11:46
- **Total Functions:** 8
- **Exported Functions:** 4


**Dependencies:**
- `(Join-Path` (external)


**Key Functions:**
- **Save-ConversationState** - Line 7 - **Save-ConversationHistory** - Line 67 - **Save-ConversationGoals** - Line 128 - **Load-ConversationState** - Line 168 - **Load-ConversationHistory** - Line 232
- *...and 3 more functions*

--- 
### Predictive-Evolution

[⬆ Back to Contents](#-table-of-contents)

Specialized module providing targeted functionality for the Unity-Claude automation system. Integrates with the broader architecture to deliver specific capabilities and enhance overall system functionality.

**Module Statistics:**
- Functions: 18
- Classes: 2
- Dependencies: 4 modules


**Module Information:**
- **Path:** `Modules\Unity-Claude-CPG\Core\Predictive-Evolution.psm1`
- **Size:** 48.78 KB
- **Last Modified:** 2025-08-29 14:50
- **Total Functions:** 19
- **Exported Functions:** 2


**Dependencies:**
- [`Unity-Claude-CPG`](#unity-claude-cpg) - `-Path` (external) - `-Path` (external) - `-Path` (external)


**Key Functions:**
- **GitCommitInfo** - Line 58 - **CodeChurnMetrics** - Line 73 - **Get-GitCommitHistory** - Line 80 - **Get-CodeChurnMetrics** - Line 230 - **Get-FileHotspots** - Line 355
- *...and 14 more functions*

--- 
### Predictive-Maintenance

[⬆ Back to Contents](#-table-of-contents)

Artificial Intelligence integration module that bridges PowerShell automation with AI services. Provides intelligent error analysis, pattern recognition, and automated decision-making capabilities through Claude AI or local LLM integration.

**Module Statistics:**
- Functions: 42
- Classes: 3
- Dependencies: 4 modules


**Module Information:**
- **Path:** `Modules\Unity-Claude-CPG\Core\Predictive-Maintenance.psm1`
- **Size:** 86.99 KB
- **Last Modified:** 2025-08-30 22:37
- **Total Functions:** 43
- **Exported Functions:** 1


**Dependencies:**
- `$safeEnumPath` (external) - `PSScriptAnalyzer` (external) - `-Path` (external) - `-Path` (external)


**Key Functions:**
- **Get-SafeChildItems** - Line 42 - **TechnicalDebtItem** - Line 104 - **MaintenancePrediction** - Line 119 - **RefactoringRecommendation** - Line 136 - **Get-TechnicalDebt** - Line 158
- *...and 38 more functions*

--- 
### PredictiveCore

[⬆ Back to Contents](#-table-of-contents)

Core infrastructure module providing fundamental functionality for the Unity-Claude system. This module serves as the foundation for other components, offering essential utilities, configuration management, and base services that other modules depend upon.

**Module Statistics:**
- Functions: 7


**Module Information:**
- **Path:** `Modules\Unity-Claude-PredictiveAnalysis\Core\PredictiveCore.psm1`
- **Size:** 9.52 KB
- **Last Modified:** 2025-08-26 11:46
- **Total Functions:** 7
- **Exported Functions:** 1




**Key Functions:**
- **Initialize-PredictiveCache** - Line 14 - **Get-PredictiveConfig** - Line 86 - **Set-PredictiveConfig** - Line 101 - **Get-CacheItem** - Line 142 - **Set-CacheItem** - Line 172
- *...and 2 more functions*

--- 
### PriorityActionQueue

[⬆ Back to Contents](#-table-of-contents)

Specialized module providing targeted functionality for the Unity-Claude automation system. Integrates with the broader architecture to deliver specific capabilities and enhance overall system functionality.

**Module Statistics:**
- Functions: 5


**Module Information:**
- **Path:** `Modules\Unity-Claude-CLIOrchestrator\Core\DecisionEngine\PriorityActionQueue.psm1`
- **Size:** 9.74 KB
- **Last Modified:** 2025-08-26 11:46
- **Total Functions:** 5
- **Exported Functions:** 1




**Key Functions:**
- **Test-ActionQueueCapacity** - Line 13 - **New-ActionQueueItem** - Line 32 - **Get-ActionQueueStatus** - Line 122 - **Clear-ActionQueue** - Line 163 - **Update-ActionStatus** - Line 197


--- 
### ProductionRunspacePool

[⬆ Back to Contents](#-table-of-contents)

Specialized module providing targeted functionality for the Unity-Claude automation system. Integrates with the broader architecture to deliver specific capabilities and enhance overall system functionality.

**Module Statistics:**
- Functions: 8


**Module Information:**
- **Path:** `Modules\Unity-Claude-RunspaceManagement\Core\ProductionRunspacePool.psm1`
- **Size:** 24.32 KB
- **Last Modified:** 2025-08-26 11:46
- **Total Functions:** 8
- **Exported Functions:** 1




**Key Functions:**
- **Write-ModuleLog** - Line 28 - **Update-RunspacePoolRegistry** - Line 34 - **Test-RunspacePoolResources** - Line 35 - **New-ProductionRunspacePool** - Line 38 - **Submit-RunspaceJob** - Line 138
- *...and 3 more functions*

--- 
### ProgressTracker

[⬆ Back to Contents](#-table-of-contents)

Specialized module providing targeted functionality for the Unity-Claude automation system. Integrates with the broader architecture to deliver specific capabilities and enhance overall system functionality.

**Module Statistics:**
- Functions: 7
- Classes: 1


**Module Information:**
- **Path:** `Modules\Unity-Claude-ScalabilityEnhancements\Core\ProgressTracker.psm1`
- **Size:** 8.87 KB
- **Last Modified:** 2025-08-26 11:46
- **Total Functions:** 13
- **Exported Functions:** 1




**Key Functions:**
- **ProgressTracker** - Line 18 - **UpdateProgress** - Line 33 - **GetProgressReport** - Line 60 - **RegisterCallback** - Line 74 - **Cancel** - Line 78
- *...and 8 more functions*

--- 
### ProjectConfiguration

[⬆ Back to Contents](#-table-of-contents)

Specialized module providing targeted functionality for the Unity-Claude automation system. Integrates with the broader architecture to deliver specific capabilities and enhance overall system functionality.

**Module Statistics:**
- Functions: 6
- Dependencies: 1 modules


**Module Information:**
- **Path:** `Modules\Unity-Claude-UnityParallelization\Core\ProjectConfiguration.psm1`
- **Size:** 15.66 KB
- **Last Modified:** 2025-08-26 11:46
- **Total Functions:** 6
- **Exported Functions:** 1


**Dependencies:**
- `$PSScriptRoot\ParallelizationCore.psm1` (external)


**Key Functions:**
- **Find-UnityProjects** - Line 21 - **Register-UnityProject** - Line 106 - **Get-UnityProjectConfiguration** - Line 200 - **Get-RegisteredUnityProjects** - Line 234 - **Set-UnityProjectConfiguration** - Line 255
- *...and 1 more functions*

--- 
### PromptConfiguration

[⬆ Back to Contents](#-table-of-contents)

Specialized module providing targeted functionality for the Unity-Claude automation system. Integrates with the broader architecture to deliver specific capabilities and enhance overall system functionality.

**Module Statistics:**
- Functions: 1


**Module Information:**
- **Path:** `Modules\Unity-Claude-AutonomousAgent\Core\PromptConfiguration.psm1`
- **Size:** 4.4 KB
- **Last Modified:** 2025-08-26 11:46
- **Total Functions:** 1
- **Exported Functions:** 1




**Key Functions:**
- **Get-PromptEngineConfig** - Line 45


--- 
### PromptSubmissionEngine

[⬆ Back to Contents](#-table-of-contents)

Specialized module providing targeted functionality for the Unity-Claude automation system. Integrates with the broader architecture to deliver specific capabilities and enhance overall system functionality.

**Module Statistics:**
- Functions: 3


**Module Information:**
- **Path:** `Modules\Unity-Claude-CLIOrchestrator\Core\PromptSubmissionEngine.psm1`
- **Size:** 14.55 KB
- **Last Modified:** 2025-08-26 11:46
- **Total Functions:** 2
- **Exported Functions:** 1




**Key Functions:**
- **Submit-ToClaudeViaTypeKeys** - Line 19 - **Execute-TestScript** - Line 166


--- 
### PromptTemplateSystem

[⬆ Back to Contents](#-table-of-contents)

Specialized module providing targeted functionality for the Unity-Claude automation system. Integrates with the broader architecture to deliver specific capabilities and enhance overall system functionality.

**Module Statistics:**
- Functions: 7


**Module Information:**
- **Path:** `Modules\Unity-Claude-AutonomousAgent\Core\PromptTemplateSystem.psm1`
- **Size:** 18.22 KB
- **Last Modified:** 2025-08-26 11:46
- **Total Functions:** 7
- **Exported Functions:** 1




**Key Functions:**
- **New-PromptTemplate** - Line 8 - **New-DebuggingPromptTemplate** - Line 76 - **New-TestResultsPromptTemplate** - Line 140 - **New-ContinuePromptTemplate** - Line 200 - **New-ARPPromptTemplate** - Line 252
- *...and 2 more functions*

--- 
### PromptTypeSelection

[⬆ Back to Contents](#-table-of-contents)

Specialized module providing targeted functionality for the Unity-Claude automation system. Integrates with the broader architecture to deliver specific capabilities and enhance overall system functionality.

**Module Statistics:**
- Functions: 4


**Module Information:**
- **Path:** `Modules\Unity-Claude-AutonomousAgent\Core\PromptTypeSelection.psm1`
- **Size:** 19.73 KB
- **Last Modified:** 2025-08-26 11:46
- **Total Functions:** 4
- **Exported Functions:** 1




**Key Functions:**
- **Invoke-PromptTypeSelection** - Line 8 - **New-PromptTypeDecisionTree** - Line 76 - **Invoke-DecisionTreeAnalysis** - Line 247 - **Invoke-NodeEvaluation** - Line 323


--- 
### QueueManagement

[⬆ Back to Contents](#-table-of-contents)

Specialized module providing targeted functionality for the Unity-Claude automation system. Integrates with the broader architecture to deliver specific capabilities and enhance overall system functionality.

**Module Statistics:**
- Functions: 6


**Module Information:**
- **Path:** `Modules\Unity-Claude-NotificationIntegration\Queue\QueueManagement.psm1`
- **Size:** 11.95 KB
- **Last Modified:** 2025-08-21 17:45
- **Total Functions:** 6
- **Exported Functions:** 1




**Key Functions:**
- **Initialize-NotificationQueue** - Line 7 - **Add-NotificationToQueue** - Line 52 - **Process-NotificationQueue** - Line 127 - **Get-QueueStatus** - Line 198 - **Clear-NotificationQueue** - Line 245
- *...and 1 more functions*

--- 
### ReadabilityAlgorithms

[⬆ Back to Contents](#-table-of-contents)

Specialized module providing targeted functionality for the Unity-Claude automation system. Integrates with the broader architecture to deliver specific capabilities and enhance overall system functionality.

**Module Statistics:**
- Functions: 8


**Module Information:**
- **Path:** `Modules\Unity-Claude-DocumentationQualityAssessment\Components\ReadabilityAlgorithms.psm1`
- **Size:** 14.1 KB
- **Last Modified:** 2025-08-30 19:48
- **Total Functions:** 8
- **Exported Functions:** 8




**Key Functions:**
- **Calculate-ComprehensiveReadabilityScores** - Line 23 - **Analyze-TextStatistics** - Line 92 - **Estimate-SyllableCount** - Line 156 - **Get-ReadabilityLevel** - Line 183 - **Measure-FleschKincaidScore** - Line 194
- *...and 3 more functions*

--- 
### RecommendationPatternEngine

[⬆ Back to Contents](#-table-of-contents)

Specialized module providing targeted functionality for the Unity-Claude automation system. Integrates with the broader architecture to deliver specific capabilities and enhance overall system functionality.

**Module Statistics:**
- Functions: 2


**Module Information:**
- **Path:** `Modules\Unity-Claude-CLIOrchestrator\Core\RecommendationPatternEngine.psm1`
- **Size:** 11.93 KB
- **Last Modified:** 2025-08-25 14:20
- **Total Functions:** 2
- **Exported Functions:** 1




**Key Functions:**
- **Initialize-CompiledPatterns** - Line 121 - **Find-RecommendationPatterns** - Line 161


--- 
### RefactoringDetection

[⬆ Back to Contents](#-table-of-contents)

Specialized module providing targeted functionality for the Unity-Claude automation system. Integrates with the broader architecture to deliver specific capabilities and enhance overall system functionality.

**Module Statistics:**
- Functions: 12
- Classes: 1
- Dependencies: 1 modules


**Module Information:**
- **Path:** `Modules\Unity-Claude-PredictiveAnalysis\Core\RefactoringDetection.psm1`
- **Size:** 23.67 KB
- **Last Modified:** 2025-08-26 11:46
- **Total Functions:** 6
- **Exported Functions:** 1


**Dependencies:**
- `$CorePath` (external)


**Key Functions:**
- **Find-RefactoringOpportunities** - Line 12 - **Find-LongMethods** - Line 143 - **Find-GodClasses** - Line 203 - **Get-DuplicationCandidates** - Line 294 - **Calculate-FunctionSimilarity** - Line 372
- *...and 1 more functions*

--- 
### ReportingExport

[⬆ Back to Contents](#-table-of-contents)

Specialized module providing targeted functionality for the Unity-Claude automation system. Integrates with the broader architecture to deliver specific capabilities and enhance overall system functionality.

**Module Statistics:**
- Functions: 6


**Module Information:**
- **Path:** `Modules\Unity-Claude-PerformanceOptimizer\Core\ReportingExport.psm1`
- **Size:** 12.62 KB
- **Last Modified:** 2025-08-26 11:46
- **Total Functions:** 6
- **Exported Functions:** 1




**Key Functions:**
- **Export-PerformanceData** - Line 5 - **Export-ToJson** - Line 48 - **Export-ToCsv** - Line 83 - **Export-ToHtml** - Line 115 - **Export-ToXml** - Line 271
- *...and 1 more functions*

--- 
### ResponseAnalysis

[⬆ Back to Contents](#-table-of-contents)

Specialized module providing targeted functionality for the Unity-Claude automation system. Integrates with the broader architecture to deliver specific capabilities and enhance overall system functionality.

**Module Statistics:**
- Functions: 12
- Dependencies: 1 modules


**Module Information:**
- **Path:** `Modules\Unity-Claude-DecisionEngine\Core\ResponseAnalysis.psm1`
- **Size:** 17.63 KB
- **Last Modified:** 2025-08-26 11:46
- **Total Functions:** 12
- **Exported Functions:** 1


**Dependencies:**
- `$corePath` (external)


**Key Functions:**
- **Invoke-HybridResponseAnalysis** - Line 13 - **Invoke-RegexBasedAnalysis** - Line 71 - **Invoke-AIEnhancedAnalysis** - Line 156 - **Get-IntentClassification** - Line 197 - **Get-SemanticContext** - Line 228
- *...and 7 more functions*

--- 
### ResponseAnalysisEngine

[⬆ Back to Contents](#-table-of-contents)

Specialized module providing targeted functionality for the Unity-Claude automation system. Integrates with the broader architecture to deliver specific capabilities and enhance overall system functionality.

**Module Statistics:**
- Functions: 12


**Module Information:**
- **Path:** `Modules\Unity-Claude-CLIOrchestrator\Core\ResponseAnalysisEngine.psm1`
- **Size:** 28.2 KB
- **Last Modified:** 2025-08-25 13:45
- **Total Functions:** 12
- **Exported Functions:** 1




**Key Functions:**
- **Calculate-PatternConfidence** - Line 33 - **Get-ConfidenceBand** - Line 160 - **Invoke-BayesianConfidenceAdjustment** - Line 173 - **Build-NGramModel** - Line 210 - **Update-NGramDatabase** - Line 268
- *...and 7 more functions*

--- 
### ResponseAnalysisEngine-Broken

[⬆ Back to Contents](#-table-of-contents)

Specialized module providing targeted functionality for the Unity-Claude automation system. Integrates with the broader architecture to deliver specific capabilities and enhance overall system functionality.

**Module Statistics:**
- Functions: 40
- Dependencies: 1 modules


**Module Information:**
- **Path:** `Modules\Unity-Claude-CLIOrchestrator\Core\ResponseAnalysisEngine-Broken.psm1`
- **Size:** 92.6 KB
- **Last Modified:** 2025-08-26 22:17
- **Total Functions:** 39
- **Exported Functions:** 1


**Dependencies:**
- [`Unity-Claude-FileMonitor`](#unity-claude-filemonitor)


**Key Functions:**
- **Write-AnalysisLog** - Line 33 - **Test-CircuitBreakerState** - Line 73 - **Update-CircuitBreakerState** - Line 100 - **Test-JsonTruncation** - Line 132 - **Repair-TruncatedJson** - Line 170
- *...and 34 more functions*

--- 
### ResponseAnalysisEngine-Core

[⬆ Back to Contents](#-table-of-contents)

Core infrastructure module providing fundamental functionality for the Unity-Claude system. This module serves as the foundation for other components, offering essential utilities, configuration management, and base services that other modules depend upon.

**Module Statistics:**
- Functions: 6
- Dependencies: 1 modules


**Module Information:**
- **Path:** `Modules\Unity-Claude-CLIOrchestrator\Core\Components\ResponseAnalysisEngine-Core.psm1`
- **Size:** 22.47 KB
- **Last Modified:** 2025-08-27 15:39
- **Total Functions:** 6
- **Exported Functions:** 1


**Dependencies:**
- `$componentFile` (external)


**Key Functions:**
- **Analyze-ResponseSentiment** - Line 47 - **Invoke-EnhancedResponseAnalysis** - Line 168 - **Initialize-ResponseAnalysisEngine** - Line 326 - **Get-ResponseAnalysisEngineStatus** - Line 360 - **Test-ResponseAnalysisEngineCore** - Line 389
- *...and 1 more functions*

--- 
### ResponseAnalysisEngine-Core-Fixed

[⬆ Back to Contents](#-table-of-contents)

Core infrastructure module providing fundamental functionality for the Unity-Claude system. This module serves as the foundation for other components, offering essential utilities, configuration management, and base services that other modules depend upon.

**Module Statistics:**
- Functions: 4
- Dependencies: 1 modules


**Module Information:**
- **Path:** `Modules\Unity-Claude-CLIOrchestrator\Core\Components\ResponseAnalysisEngine-Core-Fixed.psm1`
- **Size:** 13.52 KB
- **Last Modified:** 2025-08-27 16:57
- **Total Functions:** 4
- **Exported Functions:** 1


**Dependencies:**
- `$script:ComponentPath` (external)


**Key Functions:**
- **Analyze-ResponseSentiment** - Line 59 - **Extract-ResponseEntities** - Line 136 - **Get-ResponseContext** - Line 196 - **Invoke-EnhancedResponseAnalysis** - Line 283


--- 
### ResponseAnalysisEngine-Enhanced

[⬆ Back to Contents](#-table-of-contents)

Specialized module providing targeted functionality for the Unity-Claude automation system. Integrates with the broader architecture to deliver specific capabilities and enhance overall system functionality.

**Module Statistics:**
- Functions: 12


**Module Information:**
- **Path:** `Modules\Unity-Claude-CLIOrchestrator\Core\ResponseAnalysisEngine-Enhanced.psm1`
- **Size:** 28.2 KB
- **Last Modified:** 2025-08-25 13:45
- **Total Functions:** 12
- **Exported Functions:** 1




**Key Functions:**
- **Calculate-PatternConfidence** - Line 33 - **Get-ConfidenceBand** - Line 160 - **Invoke-BayesianConfidenceAdjustment** - Line 173 - **Build-NGramModel** - Line 210 - **Update-NGramDatabase** - Line 268
- *...and 7 more functions*

--- 
### ResponseClassificationEngine

[⬆ Back to Contents](#-table-of-contents)

Specialized module providing targeted functionality for the Unity-Claude automation system. Integrates with the broader architecture to deliver specific capabilities and enhance overall system functionality.

**Module Statistics:**
- Functions: 12


**Module Information:**
- **Path:** `Modules\Unity-Claude-CLIOrchestrator\Core\ResponseClassificationEngine.psm1`
- **Size:** 25.17 KB
- **Last Modified:** 2025-08-25 14:20
- **Total Functions:** 12
- **Exported Functions:** 1




**Key Functions:**
- **Get-EnhancedFeatureEngineering** - Line 56 - **Test-FeaturePattern** - Line 129 - **Classify-ResponseType** - Line 152 - **Invoke-DecisionTreeClassifier** - Line 203 - **Invoke-FeatureBasedClassifier** - Line 252
- *...and 7 more functions*

--- 
### ResponseMonitoring

[⬆ Back to Contents](#-table-of-contents)

Real-time monitoring module tracking system health, performance metrics, and Unity compilation status. Provides event-driven notifications and triggers automated responses to detected issues.

**Module Statistics:**
- Functions: 5
- Dependencies: 1 modules


**Module Information:**
- **Path:** `Modules\Unity-Claude-AutonomousAgent\Monitoring\ResponseMonitoring.psm1`
- **Size:** 15.06 KB
- **Last Modified:** 2025-08-20 17:25
- **Total Functions:** 5
- **Exported Functions:** 1


**Dependencies:**
- `(Join-Path` (external)


**Key Functions:**
- **Invoke-ProcessClaudeResponse** - Line 15 - **Find-ClaudeRecommendations** - Line 135 - **Add-RecommendationToQueue** - Line 192 - **Invoke-ProcessCommandQueue** - Line 234 - **Submit-PromptToClaude** - Line 261


--- 
### ResponseParsing

[⬆ Back to Contents](#-table-of-contents)

Specialized module providing targeted functionality for the Unity-Claude automation system. Integrates with the broader architecture to deliver specific capabilities and enhance overall system functionality.

**Module Statistics:**
- Functions: 6
- Dependencies: 1 modules


**Module Information:**
- **Path:** `Modules\Unity-Claude-AutonomousAgent\Parsing\ResponseParsing.psm1`
- **Size:** 26.9 KB
- **Last Modified:** 2025-08-20 17:25
- **Total Functions:** 6
- **Exported Functions:** 1


**Dependencies:**
- `(Join-Path` (external)


**Key Functions:**
- **Invoke-EnhancedResponseParsing** - Line 115 - **Get-ResponseQualityScore** - Line 222 - **Extract-CommandsFromResponse** - Line 281 - **Get-ResponseCategorization** - Line 356 - **Get-ResponseEntities** - Line 488
- *...and 1 more functions*

--- 
### ResultAnalysisEngine

[⬆ Back to Contents](#-table-of-contents)

Specialized module providing targeted functionality for the Unity-Claude automation system. Integrates with the broader architecture to deliver specific capabilities and enhance overall system functionality.

**Module Statistics:**
- Functions: 6


**Module Information:**
- **Path:** `Modules\Unity-Claude-AutonomousAgent\Core\ResultAnalysisEngine.psm1`
- **Size:** 26.47 KB
- **Last Modified:** 2025-08-26 11:46
- **Total Functions:** 6
- **Exported Functions:** 1




**Key Functions:**
- **Invoke-CommandResultAnalysis** - Line 8 - **Get-ResultClassification** - Line 101 - **Get-ResultSeverity** - Line 270 - **Find-ResultPatterns** - Line 395 - **Get-HistoricalPatterns** - Line 487
- *...and 1 more functions*

--- 
### RetryLogic

[⬆ Back to Contents](#-table-of-contents)

Specialized module providing targeted functionality for the Unity-Claude automation system. Integrates with the broader architecture to deliver specific capabilities and enhance overall system functionality.

**Module Statistics:**
- Functions: 6


**Module Information:**
- **Path:** `Modules\Unity-Claude-NotificationIntegration\Reliability\RetryLogic.psm1`
- **Size:** 8.88 KB
- **Last Modified:** 2025-08-21 17:45
- **Total Functions:** 6
- **Exported Functions:** 1




**Key Functions:**
- **New-NotificationRetryPolicy** - Line 7 - **Invoke-NotificationWithRetry** - Line 40 - **Test-NotificationDelivery** - Line 100 - **Get-NotificationDeliveryStatus** - Line 150 - **Reset-NotificationRetryState** - Line 170
- *...and 1 more functions*

--- 
### RiskAssessment

[⬆ Back to Contents](#-table-of-contents)

Specialized module providing targeted functionality for the Unity-Claude automation system. Integrates with the broader architecture to deliver specific capabilities and enhance overall system functionality.

**Module Statistics:**
- Functions: 20
- Classes: 3
- Dependencies: 5 modules


**Module Information:**
- **Path:** `Modules\Unity-Claude-PredictiveAnalysis\Core\RiskAssessment.psm1`
- **Size:** 41.07 KB
- **Last Modified:** 2025-08-26 11:46
- **Total Functions:** 18
- **Exported Functions:** 1


**Dependencies:**
- `$CorePath` (external) - `$TrendPath` (external) - `$MaintenancePath` (external) - `$RefactoringPath` (external) - `$SmellPath` (external)


**Key Functions:**
- **Predict-BugProbability** - Line 21 - **Get-BugPreventionActions** - Line 198 - **Get-MaintenanceRisk** - Line 256 - **Find-AntiPatterns** - Line 310 - **Find-SpaghettiCode** - Line 384
- *...and 13 more functions*

--- 
### RoleAwareManagement

[⬆ Back to Contents](#-table-of-contents)

Specialized module providing targeted functionality for the Unity-Claude automation system. Integrates with the broader architecture to deliver specific capabilities and enhance overall system functionality.

**Module Statistics:**
- Functions: 9
- Dependencies: 1 modules


**Module Information:**
- **Path:** `Modules\Unity-Claude-AutonomousAgent\Core\RoleAwareManagement.psm1`
- **Size:** 18.58 KB
- **Last Modified:** 2025-08-26 11:46
- **Total Functions:** 9
- **Exported Functions:** 4


**Dependencies:**
- `(Join-Path` (external)


**Key Functions:**
- **Add-RoleAwareHistoryItem** - Line 7 - **Get-RoleAwareHistory** - Line 100 - **Update-DialoguePatterns** - Line 165 - **Update-ConversationEffectiveness** - Line 249 - **Analyze-Sentiment** - Line 361
- *...and 4 more functions*

--- 
### RuleBasedDecisionTrees

[⬆ Back to Contents](#-table-of-contents)

Decision engine module implementing rule-based and ML-enhanced decision trees. Analyzes Claude responses, evaluates safety constraints, and determines appropriate actions based on configurable policies and learned patterns.

**Module Statistics:**
- Functions: 2


**Module Information:**
- **Path:** `Modules\Unity-Claude-CLIOrchestrator\Core\DecisionEngine\RuleBasedDecisionTrees.psm1`
- **Size:** 11.64 KB
- **Last Modified:** 2025-08-26 11:46
- **Total Functions:** 2
- **Exported Functions:** 1




**Key Functions:**
- **Invoke-RuleBasedDecision** - Line 9 - **Resolve-PriorityDecision** - Line 118


--- 
### RunspaceCore

[⬆ Back to Contents](#-table-of-contents)

Core infrastructure module providing fundamental functionality for the Unity-Claude system. This module serves as the foundation for other components, offering essential utilities, configuration management, and base services that other modules depend upon.

**Module Statistics:**
- Functions: 10
- Dependencies: 1 modules


**Module Information:**
- **Path:** `Modules\Unity-Claude-RunspaceManagement\Core\RunspaceCore.psm1`
- **Size:** 6.92 KB
- **Last Modified:** 2025-08-26 11:46
- **Total Functions:** 8
- **Exported Functions:** 1


**Dependencies:**
- [`Unity-Claude-ParallelProcessing`](#unity-claude-parallelprocessing)


**Key Functions:**
- **Test-ModuleDependencyAvailability** - Line 14 - **Write-FallbackLog** - Line 51 - **Write-ModuleLog** - Line 70 - **Get-RunspacePoolRegistry** - Line 89 - **Update-RunspacePoolRegistry** - Line 101
- *...and 3 more functions*

--- 
### RunspaceManagement

[⬆ Back to Contents](#-table-of-contents)

Specialized module providing targeted functionality for the Unity-Claude automation system. Integrates with the broader architecture to deliver specific capabilities and enhance overall system functionality.

**Module Statistics:**
- Functions: 3
- Dependencies: 1 modules


**Module Information:**
- **Path:** `Modules\SafeCommandExecution\Core\RunspaceManagement.psm1`
- **Size:** 7.01 KB
- **Last Modified:** 2025-08-26 11:46
- **Total Functions:** 3
- **Exported Functions:** 1


**Dependencies:**
- `$PSScriptRoot\SafeCommandCore.psm1` (external)


**Key Functions:**
- **New-ConstrainedRunspace** - Line 21 - **Remove-ConstrainedRunspace** - Line 104 - **Test-RunspaceHealth** - Line 127


--- 
### RunspacePoolManagement

[⬆ Back to Contents](#-table-of-contents)

Specialized module providing targeted functionality for the Unity-Claude automation system. Integrates with the broader architecture to deliver specific capabilities and enhance overall system functionality.

**Module Statistics:**
- Functions: 9


**Module Information:**
- **Path:** `Modules\Unity-Claude-RunspaceManagement\Core\RunspacePoolManagement.psm1`
- **Size:** 14.72 KB
- **Last Modified:** 2025-08-26 11:46
- **Total Functions:** 9
- **Exported Functions:** 1




**Key Functions:**
- **Write-ModuleLog** - Line 21 - **Update-RunspacePoolRegistry** - Line 26 - **Get-RunspacePoolRegistry** - Line 27 - **New-ManagedRunspacePool** - Line 33 - **Open-RunspacePool** - Line 100
- *...and 4 more functions*

--- 
### RunspacePoolManager

[⬆ Back to Contents](#-table-of-contents)

Specialized module providing targeted functionality for the Unity-Claude automation system. Integrates with the broader architecture to deliver specific capabilities and enhance overall system functionality.

**Module Statistics:**
- Functions: 2
- Classes: 1
- Dependencies: 1 modules


**Module Information:**
- **Path:** `Modules\Unity-Claude-ParallelProcessor\Core\RunspacePoolManager.psm1`
- **Size:** 15.02 KB
- **Last Modified:** 2025-08-26 11:46
- **Total Functions:** 11
- **Exported Functions:** 3


**Dependencies:**
- `$PSScriptRoot\ParallelProcessorCore.psm1` (external)


**Key Functions:**
- **RunspacePoolManager** - Line 24 - **CreateInitialSessionState** - Line 38 - **CreateRunspacePool** - Line 75 - **ConfigureRunspacePool** - Line 98 - **Open** - Line 130
- *...and 6 more functions*

--- 
### SafeCommandCore

[⬆ Back to Contents](#-table-of-contents)

Core infrastructure module providing fundamental functionality for the Unity-Claude system. This module serves as the foundation for other components, offering essential utilities, configuration management, and base services that other modules depend upon.

**Module Statistics:**
- Functions: 5


**Module Information:**
- **Path:** `Modules\SafeCommandExecution\Core\SafeCommandCore.psm1`
- **Size:** 7.33 KB
- **Last Modified:** 2025-08-26 11:46
- **Total Functions:** 4
- **Exported Functions:** 1




**Key Functions:**
- **Write-SafeLog** - Line 40 - **Get-SafeCommandConfig** - Line 89 - **Set-SafeCommandConfig** - Line 100 - **Test-SafeCommandInitialization** - Line 133


--- 
### SafeCommandExecution

[⬆ Back to Contents](#-table-of-contents)

Specialized module providing targeted functionality for the Unity-Claude automation system. Integrates with the broader architecture to deliver specific capabilities and enhance overall system functionality.

**Module Statistics:**
- Functions: 3
- Dependencies: 1 modules


**Module Information:**
- **Path:** `Modules\SafeCommandExecution\SafeCommandExecution.psm1`
- **Size:** 12.93 KB
- **Last Modified:** 2025-08-26 11:46
- **Total Functions:** 3
- **Exported Functions:** 1


**Dependencies:**
- `$componentFile` (external)


**Key Functions:**
- **Initialize-SafeCommandExecution** - Line 77 - **Get-SafeCommandStatus** - Line 131 - **Test-SafeCommandIntegration** - Line 166


--- 
### SafeCommandExecution-Original

[⬆ Back to Contents](#-table-of-contents)

Specialized module providing targeted functionality for the Unity-Claude automation system. Integrates with the broader architecture to deliver specific capabilities and enhance overall system functionality.

**Module Statistics:**
- Functions: 30
- Classes: 2


**Module Information:**
- **Path:** `Modules\SafeCommandExecution\SafeCommandExecution-Original.psm1`
- **Size:** 99.06 KB
- **Last Modified:** 2025-08-26 11:46
- **Total Functions:** 30
- **Exported Functions:** 1




**Key Functions:**
- **Write-SafeLog** - Line 40 - **New-ConstrainedRunspace** - Line 81 - **Test-CommandSafety** - Line 151 - **Test-PathSafety** - Line 267 - **Remove-DangerousCharacters** - Line 304
- *...and 25 more functions*

--- 
### SafeCommandExecution-Refactored

[⬆ Back to Contents](#-table-of-contents)

Specialized module providing targeted functionality for the Unity-Claude automation system. Integrates with the broader architecture to deliver specific capabilities and enhance overall system functionality.

**Module Statistics:**
- Functions: 3
- Dependencies: 1 modules


**Module Information:**
- **Path:** `Modules\SafeCommandExecution\SafeCommandExecution-Refactored.psm1`
- **Size:** 12.93 KB
- **Last Modified:** 2025-08-26 11:46
- **Total Functions:** 3
- **Exported Functions:** 1


**Dependencies:**
- `$componentFile` (external)


**Key Functions:**
- **Initialize-SafeCommandExecution** - Line 77 - **Get-SafeCommandStatus** - Line 131 - **Test-SafeCommandIntegration** - Line 166


--- 
### SafeExecution

[⬆ Back to Contents](#-table-of-contents)

Specialized module providing targeted functionality for the Unity-Claude automation system. Integrates with the broader architecture to deliver specific capabilities and enhance overall system functionality.

**Module Statistics:**
- Functions: 7
- Dependencies: 2 modules


**Module Information:**
- **Path:** `Modules\Unity-Claude-AutonomousAgent\Execution\SafeExecution.psm1`
- **Size:** 22.26 KB
- **Last Modified:** 2025-08-20 17:25
- **Total Functions:** 7
- **Exported Functions:** 1


**Dependencies:**
- `(Join-Path` (external)


**Key Functions:**
- **New-ConstrainedRunspace** - Line 63 - **Test-CommandSafety** - Line 147 - **Test-ParameterSafety** - Line 221 - **Test-PathSafety** - Line 276 - **Invoke-SafeConstrainedCommand** - Line 325
- *...and 2 more functions*

--- 
### SafetyValidationFramework

[⬆ Back to Contents](#-table-of-contents)

Safety and validation framework ensuring all automated operations meet security and stability requirements. Implements sandboxing, command validation, and rollback mechanisms to prevent destructive operations.

**Module Statistics:**
- Functions: 3


**Module Information:**
- **Path:** `Modules\Unity-Claude-CLIOrchestrator\Core\DecisionEngine\SafetyValidationFramework.psm1`
- **Size:** 12.53 KB
- **Last Modified:** 2025-08-26 11:46
- **Total Functions:** 3
- **Exported Functions:** 1




**Key Functions:**
- **Test-SafetyValidation** - Line 9 - **Test-SafeFilePath** - Line 150 - **Test-SafeCommand** - Line 223


--- 
### SecurityTokens

[⬆ Back to Contents](#-table-of-contents)

Specialized module providing targeted functionality for the Unity-Claude automation system. Integrates with the broader architecture to deliver specific capabilities and enhance overall system functionality.

**Module Statistics:**
- Functions: 4
- Dependencies: 1 modules


**Module Information:**
- **Path:** `Modules\Unity-Claude-HITL\Core\SecurityTokens.psm1`
- **Size:** 7.49 KB
- **Last Modified:** 2025-08-26 11:46
- **Total Functions:** 4
- **Exported Functions:** 1


**Dependencies:**
- `$coreModule` (external)


**Key Functions:**
- **New-ApprovalToken** - Line 14 - **Test-ApprovalToken** - Line 69 - **Get-TokenMetadata** - Line 114 - **Revoke-ApprovalToken** - Line 148


--- 
### SelfPatching

[⬆ Back to Contents](#-table-of-contents)

Specialized module providing targeted functionality for the Unity-Claude automation system. Integrates with the broader architecture to deliver specific capabilities and enhance overall system functionality.

**Module Statistics:**
- Functions: 8
- Dependencies: 2 modules


**Module Information:**
- **Path:** `Modules\Unity-Claude-Learning\Core\SelfPatching.psm1`
- **Size:** 14.37 KB
- **Last Modified:** 2025-08-26 11:46
- **Total Functions:** 8
- **Exported Functions:** 1


**Dependencies:**
- `$CorePath` (external) - `$DatabasePath` (external)


**Key Functions:**
- **Write-ModuleLog** - Line 13 - **Apply-AutoFix** - Line 32 - **Apply-FixToFile** - Line 126 - **Get-PatternFix** - Line 214 - **Get-PatternFixSQLite** - Line 252
- *...and 3 more functions*

--- 
### SemanticAnalysis-Metrics

[⬆ Back to Contents](#-table-of-contents)

Specialized module providing targeted functionality for the Unity-Claude automation system. Integrates with the broader architecture to deliver specific capabilities and enhance overall system functionality.

**Module Statistics:**
- Functions: 14
- Classes: 9
- Dependencies: 2 modules


**Module Information:**
- **Path:** `Modules\Unity-Claude-CPG\Core\SemanticAnalysis-Metrics.psm1`
- **Size:** 30.17 KB
- **Last Modified:** 2025-08-28 15:45
- **Total Functions:** 9
- **Exported Functions:** 1


**Dependencies:**
- `$cpgModule` (external) - `$complexityModule` (external)


**Key Functions:**
- **Get-CHMCohesionAtMessageLevel** - Line 32 - **Get-CHDCohesionAtDomainLevel** - Line 154 - **Get-CBOCouplingBetweenObjects** - Line 245 - **Get-LCOMCohesionInMethods** - Line 331 - **Get-CHDCohesionAtDomainLevel** - Line 408
- *...and 4 more functions*

--- 
### SemanticAnalysis-PatternDetector

[⬆ Back to Contents](#-table-of-contents)

Specialized module providing targeted functionality for the Unity-Claude automation system. Integrates with the broader architecture to deliver specific capabilities and enhance overall system functionality.

**Module Statistics:**
- Functions: 20
- Classes: 13
- Dependencies: 1 modules


**Module Information:**
- **Path:** `Modules\Unity-Claude-CPG\Core\SemanticAnalysis-PatternDetector.psm1`
- **Size:** 24.85 KB
- **Last Modified:** 2025-08-28 15:01
- **Total Functions:** 17
- **Exported Functions:** 1


**Dependencies:**
- `$cpgModule` (external)


**Key Functions:**
- **PatternSignature** - Line 39 - **PatternMatch** - Line 60 - **Get-SingletonPattern** - Line 81 - **Get-FactoryPattern** - Line 102 - **Get-ObserverPattern** - Line 123
- *...and 12 more functions*

--- 
### SemanticAnalysis-PatternDetector-PS51Compatible

[⬆ Back to Contents](#-table-of-contents)

Specialized module providing targeted functionality for the Unity-Claude automation system. Integrates with the broader architecture to deliver specific capabilities and enhance overall system functionality.

**Module Statistics:**
- Functions: 19
- Classes: 1
- Dependencies: 1 modules


**Module Information:**
- **Path:** `Modules\Unity-Claude-CPG\Core\SemanticAnalysis-PatternDetector-PS51Compatible.psm1`
- **Size:** 12.42 KB
- **Last Modified:** 2025-08-28 15:27
- **Total Functions:** 9
- **Exported Functions:** 1


**Dependencies:**
- `$cpgModule` (external)


**Key Functions:**
- **New-PatternSignature** - Line 32 - **New-PatternMatch** - Line 64 - **Get-SingletonPatternSignature** - Line 102 - **Get-FactoryPatternSignature** - Line 118 - **Get-PowerShellASTCompatible** - Line 138
- *...and 4 more functions*

--- 
### SessionStateConfiguration

[⬆ Back to Contents](#-table-of-contents)

Specialized module providing targeted functionality for the Unity-Claude automation system. Integrates with the broader architecture to deliver specific capabilities and enhance overall system functionality.

**Module Statistics:**
- Functions: 7


**Module Information:**
- **Path:** `Modules\Unity-Claude-RunspaceManagement\Core\SessionStateConfiguration.psm1`
- **Size:** 14.79 KB
- **Last Modified:** 2025-08-26 11:46
- **Total Functions:** 7
- **Exported Functions:** 1




**Key Functions:**
- **Write-ModuleLog** - Line 15 - **Update-SessionStateRegistry** - Line 20 - **New-RunspaceSessionState** - Line 32 - **Set-SessionStateConfiguration** - Line 124 - **Add-SessionStateModule** - Line 161
- *...and 2 more functions*

--- 
### StateConfiguration

[⬆ Back to Contents](#-table-of-contents)

Specialized module providing targeted functionality for the Unity-Claude automation system. Integrates with the broader architecture to deliver specific capabilities and enhance overall system functionality.

**Module Statistics:**
- Functions: 4


**Module Information:**
- **Path:** `Modules\Unity-Claude-AutonomousStateTracker-Enhanced\Core\StateConfiguration.psm1`
- **Size:** 11.35 KB
- **Last Modified:** 2025-08-26 11:46
- **Total Functions:** 4
- **Exported Functions:** 1




**Key Functions:**
- **Get-EnhancedStateConfig** - Line 62 - **Initialize-StateDirectories** - Line 70 - **Get-EnhancedAutonomousStates** - Line 195 - **Get-PerformanceCounters** - Line 231


--- 
### StateMachineCore

[⬆ Back to Contents](#-table-of-contents)

Core infrastructure module providing fundamental functionality for the Unity-Claude system. This module serves as the foundation for other components, offering essential utilities, configuration management, and base services that other modules depend upon.

**Module Statistics:**
- Functions: 5


**Module Information:**
- **Path:** `Modules\Unity-Claude-AutonomousStateTracker-Enhanced\Core\StateMachineCore.psm1`
- **Size:** 14.54 KB
- **Last Modified:** 2025-08-26 11:46
- **Total Functions:** 5
- **Exported Functions:** 1




**Key Functions:**
- **Initialize-EnhancedAutonomousStateTracking** - Line 8 - **Set-EnhancedAutonomousState** - Line 85 - **Get-EnhancedAutonomousState** - Line 203 - **Save-AgentState** - Line 279 - **Get-AgentState** - Line 312


--- 
### StateManagement

[⬆ Back to Contents](#-table-of-contents)

Specialized module providing targeted functionality for the Unity-Claude automation system. Integrates with the broader architecture to deliver specific capabilities and enhance overall system functionality.

**Module Statistics:**
- Functions: 7
- Dependencies: 1 modules


**Module Information:**
- **Path:** `Modules\Unity-Claude-AutonomousAgent\Core\StateManagement.psm1`
- **Size:** 13.66 KB
- **Last Modified:** 2025-08-26 11:46
- **Total Functions:** 6
- **Exported Functions:** 5


**Dependencies:**
- `(Join-Path` (external)


**Key Functions:**
- **Initialize-ConversationState** - Line 7 - **Set-ConversationState** - Line 111 - **Get-ConversationState** - Line 206 - **Get-ValidStateTransitions** - Line 243 - **Reset-ConversationState** - Line 271
- *...and 1 more functions*

--- 
### StatePersistence

[⬆ Back to Contents](#-table-of-contents)

Specialized module providing targeted functionality for the Unity-Claude automation system. Integrates with the broader architecture to deliver specific capabilities and enhance overall system functionality.

**Module Statistics:**
- Functions: 5


**Module Information:**
- **Path:** `Modules\Unity-Claude-AutonomousStateTracker-Enhanced\Core\StatePersistence.psm1`
- **Size:** 11.54 KB
- **Last Modified:** 2025-08-26 11:46
- **Total Functions:** 5
- **Exported Functions:** 1




**Key Functions:**
- **New-StateCheckpoint** - Line 8 - **Restore-AgentStateFromCheckpoint** - Line 70 - **Get-CheckpointHistory** - Line 129 - **Remove-OldCheckpoints** - Line 177 - **Test-CheckpointIntegrity** - Line 224


--- 
### StatisticsTracker

[⬆ Back to Contents](#-table-of-contents)

Specialized module providing targeted functionality for the Unity-Claude automation system. Integrates with the broader architecture to deliver specific capabilities and enhance overall system functionality.

**Module Statistics:**
- Functions: 2
- Classes: 1
- Dependencies: 1 modules


**Module Information:**
- **Path:** `Modules\Unity-Claude-ParallelProcessor\Core\StatisticsTracker.psm1`
- **Size:** 17.12 KB
- **Last Modified:** 2025-08-26 11:46
- **Total Functions:** 17
- **Exported Functions:** 3


**Dependencies:**
- `$PSScriptRoot\ParallelProcessorCore.psm1` (external)


**Key Functions:**
- **StatisticsTracker** - Line 22 - **RecordJobSubmission** - Line 57 - **RecordJobCompletion** - Line 68 - **RecordJobFailure** - Line 99 - **RecordJobCancellation** - Line 124
- *...and 12 more functions*

--- 
### StringSimilarity

[⬆ Back to Contents](#-table-of-contents)

Specialized module providing targeted functionality for the Unity-Claude automation system. Integrates with the broader architecture to deliver specific capabilities and enhance overall system functionality.

**Module Statistics:**
- Functions: 8
- Dependencies: 1 modules


**Module Information:**
- **Path:** `Modules\Unity-Claude-Learning\Core\StringSimilarity.psm1`
- **Size:** 12.95 KB
- **Last Modified:** 2025-08-26 11:46
- **Total Functions:** 8
- **Exported Functions:** 1


**Dependencies:**
- `$CorePath` (external)


**Key Functions:**
- **Get-StringSimilarity** - Line 13 - **Get-LevenshteinDistance** - Line 62 - **Get-LevenshteinSimilarity** - Line 116 - **Get-JaroWinklerSimilarity** - Line 148 - **Get-JaroSimilarity** - Line 197
- *...and 3 more functions*

--- 
### SuccessTracking

[⬆ Back to Contents](#-table-of-contents)

Specialized module providing targeted functionality for the Unity-Claude automation system. Integrates with the broader architecture to deliver specific capabilities and enhance overall system functionality.

**Module Statistics:**
- Functions: 9
- Dependencies: 1 modules


**Module Information:**
- **Path:** `Modules\Unity-Claude-Learning\Core\SuccessTracking.psm1`
- **Size:** 12.36 KB
- **Last Modified:** 2025-08-26 11:46
- **Total Functions:** 9
- **Exported Functions:** 1


**Dependencies:**
- `$CorePath` (external)


**Key Functions:**
- **Write-ModuleLog** - Line 12 - **Update-SuccessMetrics** - Line 37 - **Get-SuccessMetrics** - Line 97 - **Reset-SuccessMetrics** - Line 143 - **Save-SuccessMetrics** - Line 186
- *...and 4 more functions*

--- 
### SystemIntegration

[⬆ Back to Contents](#-table-of-contents)

Specialized module providing targeted functionality for the Unity-Claude automation system. Integrates with the broader architecture to deliver specific capabilities and enhance overall system functionality.

**Module Statistics:**
- Functions: 6
- Dependencies: 3 modules


**Module Information:**
- **Path:** `Modules\Unity-Claude-DocumentationQualityAssessment\Components\SystemIntegration.psm1`
- **Size:** 9.2 KB
- **Last Modified:** 2025-08-30 19:31
- **Total Functions:** 6
- **Exported Functions:** 6


**Dependencies:**
- `$autonomousPath` (external) - `$ollamaPath` (external) - `$alertQualityPath` (external)


**Key Functions:**
- **Initialize-DocumentationQualityAssessment** - Line 27 - **Get-DefaultQualityAssessmentConfiguration** - Line 101 - **Discover-QualityAssessmentSystems** - Line 168 - **Initialize-ReadabilityCalculator** - Line 217 - **Setup-QualitySystemIntegration** - Line 222
- *...and 1 more functions*

--- 
### Templates-PerLanguage

[⬆ Back to Contents](#-table-of-contents)

Specialized module providing targeted functionality for the Unity-Claude automation system. Integrates with the broader architecture to deliver specific capabilities and enhance overall system functionality.

**Module Statistics:**
- Functions: 9


**Module Information:**
- **Path:** `Modules\Unity-Claude-Enhanced-DocumentationGenerators\Core\Templates-PerLanguage.psm1`
- **Size:** 12.74 KB
- **Last Modified:** 2025-08-28 17:05
- **Total Functions:** 7
- **Exported Functions:** 1




**Key Functions:**
- **Get-PowerShellDocTemplate** - Line 8 - **Get-PythonDocTemplate** - Line 76 - **Get-CSharpDocTemplate** - Line 162 - **Get-JavaScriptDocTemplate** - Line 236 - **Get-DocumentationTemplate** - Line 329
- *...and 2 more functions*

--- 
### TemplateSystem

[⬆ Back to Contents](#-table-of-contents)

Specialized module providing targeted functionality for the Unity-Claude automation system. Integrates with the broader architecture to deliver specific capabilities and enhance overall system functionality.

**Module Statistics:**
- Functions: 6


**Module Information:**
- **Path:** `Modules\Unity-Claude-DocumentationAutomation\Core\TemplateSystem.psm1`
- **Size:** 16.47 KB
- **Last Modified:** 2025-08-26 11:46
- **Total Functions:** 6
- **Exported Functions:** 1




**Key Functions:**
- **New-DocumentationTemplate** - Line 20 - **Get-DocumentationTemplates** - Line 83 - **Update-DocumentationTemplate** - Line 130 - **Export-DocumentationTemplates** - Line 181 - **Import-DocumentationTemplates** - Line 257
- *...and 1 more functions*

--- 
### TemporalContextTracking

[⬆ Back to Contents](#-table-of-contents)

Specialized module providing targeted functionality for the Unity-Claude automation system. Integrates with the broader architecture to deliver specific capabilities and enhance overall system functionality.

**Module Statistics:**
- Functions: 2


**Module Information:**
- **Path:** `Modules\Unity-Claude-CLIOrchestrator\Core\DecisionEngine-Bayesian\TemporalContextTracking.psm1`
- **Size:** 7.29 KB
- **Last Modified:** 2025-08-26 11:46
- **Total Functions:** 2
- **Exported Functions:** 2




**Key Functions:**
- **Add-TemporalContext** - Line 22 - **Get-TemporalContextRelevance** - Line 93


--- 
### ThrottlingResourceControl

[⬆ Back to Contents](#-table-of-contents)

Specialized module providing targeted functionality for the Unity-Claude automation system. Integrates with the broader architecture to deliver specific capabilities and enhance overall system functionality.

**Module Statistics:**
- Functions: 5


**Module Information:**
- **Path:** `Modules\Unity-Claude-RunspaceManagement\Core\ThrottlingResourceControl.psm1`
- **Size:** 16.31 KB
- **Last Modified:** 2025-08-26 11:46
- **Total Functions:** 5
- **Exported Functions:** 1




**Key Functions:**
- **Write-ModuleLog** - Line 19 - **Test-RunspacePoolResources** - Line 26 - **Set-AdaptiveThrottling** - Line 121 - **Invoke-RunspacePoolCleanup** - Line 196 - **Get-ResourceMonitoringStatus** - Line 275


--- 
### TreeSitter-CSTConverter

[⬆ Back to Contents](#-table-of-contents)

Specialized module providing targeted functionality for the Unity-Claude automation system. Integrates with the broader architecture to deliver specific capabilities and enhance overall system functionality.

**Module Statistics:**
- Functions: 3
- Classes: 11


**Module Information:**
- **Path:** `Modules\Unity-Claude-CPG\Core\TreeSitter-CSTConverter.psm1`
- **Size:** 23.98 KB
- **Last Modified:** 2025-08-28 03:22
- **Total Functions:** 24
- **Exported Functions:** 1




**Key Functions:**
- **CSTNode** - Line 86 - **CSTNode** - Line 92 - **ConvertToCPGNode** - Line 100 - **GetDescendants** - Line 124 - **FindPattern** - Line 144
- *...and 19 more functions*

--- 
### TrendAnalysis

[⬆ Back to Contents](#-table-of-contents)

Specialized module providing targeted functionality for the Unity-Claude automation system. Integrates with the broader architecture to deliver specific capabilities and enhance overall system functionality.

**Module Statistics:**
- Functions: 3
- Dependencies: 1 modules


**Module Information:**
- **Path:** `Modules\Unity-Claude-PredictiveAnalysis\Core\TrendAnalysis.psm1`
- **Size:** 13.62 KB
- **Last Modified:** 2025-08-26 11:46
- **Total Functions:** 3
- **Exported Functions:** 1


**Dependencies:**
- `$CorePath` (external)


**Key Functions:**
- **Get-CodeEvolutionTrend** - Line 12 - **Measure-CodeChurn** - Line 156 - **Get-HotspotAnalysis** - Line 217


--- 
### TriggerSystem

[⬆ Back to Contents](#-table-of-contents)

Specialized module providing targeted functionality for the Unity-Claude automation system. Integrates with the broader architecture to deliver specific capabilities and enhance overall system functionality.

**Module Statistics:**
- Functions: 10


**Module Information:**
- **Path:** `Modules\Unity-Claude-DocumentationAutomation\Core\TriggerSystem.psm1`
- **Size:** 23.28 KB
- **Last Modified:** 2025-08-26 11:46
- **Total Functions:** 10
- **Exported Functions:** 1




**Key Functions:**
- **Register-DocumentationTrigger** - Line 20 - **Unregister-DocumentationTrigger** - Line 82 - **Get-DocumentationTriggers** - Line 118 - **Test-TriggerConditions** - Line 162 - **Invoke-DocumentationUpdate** - Line 232
- *...and 5 more functions*

--- 
### Unity-Claude-AgentIntegration

[⬆ Back to Contents](#-table-of-contents)

Unity Editor integration module providing direct communication with Unity processes. Handles compilation monitoring, error extraction, project management, and automated testing workflows.

**Module Statistics:**
- Functions: 7
- Dependencies: 3 modules


**Module Information:**
- **Path:** `Modules\Unity-Claude-MessageQueue\Unity-Claude-AgentIntegration.psm1`
- **Size:** 16.16 KB
- **Last Modified:** 2025-08-24 12:06
- **Total Functions:** 7
- **Exported Functions:** 1


**Dependencies:**
- `$messageQueuePath` (external) - `$ModulePath` (external) - `$ModulePath` (external)


**Key Functions:**
- **Initialize-AgentMessageSystem** - Line 13 - **Register-DefaultHandlers** - Line 61 - **Initialize-SupervisorOrchestration** - Line 151 - **Select-BestAgent** - Line 240 - **Send-SupervisorMessage** - Line 280
- *...and 2 more functions*

--- 
### Unity-Claude-AIAlertClassifier

[⬆ Back to Contents](#-table-of-contents)

Artificial Intelligence integration module that bridges PowerShell automation with AI services. Provides intelligent error analysis, pattern recognition, and automated decision-making capabilities through Claude AI or local LLM integration. Unity Editor integration module providing direct communication with Unity processes. Handles compilation monitoring, error extraction, project management, and automated testing workflows. 

**Module Statistics:**
 - Functions: 19


**Module Information:**
- **Path:** `Modules\Unity-Claude-AIAlertClassifier\Unity-Claude-AIAlertClassifier.psm1`
- **Size:** 32.8 KB
- **Last Modified:** 2025-08-30 21:58
- **Total Functions:** 19
- **Exported Functions:** 1




**Key Functions:**
- **Initialize-AIAlertClassifier** - Line 101 - **Test-AIConnection** - Line 144 - **Initialize-ClassificationEngine** - Line 175 - **Initialize-CorrelationEngine** - Line 219 - **Initialize-EscalationEngine** - Line 250
- *...and 14 more functions*

--- 
### Unity-Claude-AlertAnalytics

[⬆ Back to Contents](#-table-of-contents)

Unity Editor integration module providing direct communication with Unity processes. Handles compilation monitoring, error extraction, project management, and automated testing workflows.

**Module Statistics:**
- Functions: 22


**Module Information:**
- **Path:** `Modules\Unity-Claude-AlertAnalytics\Unity-Claude-AlertAnalytics.psm1`
- **Size:** 33.31 KB
- **Last Modified:** 2025-08-30 14:58
- **Total Functions:** 22
- **Exported Functions:** 1




**Key Functions:**
- **Initialize-AlertAnalytics** - Line 80 - **Get-DefaultAnalyticsConfiguration** - Line 165 - **Load-TimeSeriesDatabase** - Line 213 - **Save-TimeSeriesDatabase** - Line 249 - **Analyze-AlertPatterns** - Line 280
- *...and 17 more functions*

--- 
### Unity-Claude-AlertFeedbackCollector

[⬆ Back to Contents](#-table-of-contents)

Unity Editor integration module providing direct communication with Unity processes. Handles compilation monitoring, error extraction, project management, and automated testing workflows.

**Module Statistics:**
- Functions: 20
- Dependencies: 4 modules


**Module Information:**
- **Path:** `Modules\Unity-Claude-AlertFeedbackCollector\Unity-Claude-AlertFeedbackCollector.psm1`
- **Size:** 36.27 KB
- **Last Modified:** 2025-08-30 14:54
- **Total Functions:** 17
- **Exported Functions:** 1


**Dependencies:**
- `$notificationPath` (external) - `$alertingPath` (external) - `$maintenancePath` (external) - `$classifierPath` (external)


**Key Functions:**
- **Initialize-AlertFeedbackCollector** - Line 69 - **Get-DefaultFeedbackConfiguration** - Line 157 - **Load-FeedbackDatabase** - Line 205 - **Save-FeedbackDatabase** - Line 241 - **Discover-ConnectedAlertSystems** - Line 272
- *...and 12 more functions*

--- 
### Unity-Claude-AlertMLOptimizer

[⬆ Back to Contents](#-table-of-contents)

Unity Editor integration module providing direct communication with Unity processes. Handles compilation monitoring, error extraction, project management, and automated testing workflows.

**Module Statistics:**
- Functions: 27


**Module Information:**
- **Path:** `Modules\Unity-Claude-AlertMLOptimizer\Unity-Claude-AlertMLOptimizer.psm1`
- **Size:** 34.34 KB
- **Last Modified:** 2025-08-30 14:56
- **Total Functions:** 27
- **Exported Functions:** 1




**Key Functions:**
- **Initialize-AlertMLOptimizer** - Line 57 - **Initialize-PythonEnvironment** - Line 132 - **Get-DefaultMLOptimizerConfiguration** - Line 220 - **Optimize-AlertThresholds** - Line 272 - **Optimize-AdaptiveThreshold** - Line 365
- *...and 22 more functions*

--- 
### Unity-Claude-AlertQualityReporting

[⬆ Back to Contents](#-table-of-contents)

Unity Editor integration module providing direct communication with Unity processes. Handles compilation monitoring, error extraction, project management, and automated testing workflows.

**Module Statistics:**
- Functions: 40


**Module Information:**
- **Path:** `Modules\Unity-Claude-AlertQualityReporting\Unity-Claude-AlertQualityReporting.psm1`
- **Size:** 36.02 KB
- **Last Modified:** 2025-08-30 15:01
- **Total Functions:** 40
- **Exported Functions:** 1




**Key Functions:**
- **Initialize-AlertQualityReporting** - Line 79 - **Get-DefaultQualityReportingConfiguration** - Line 174 - **Generate-QualityReport** - Line 231 - **Calculate-ComprehensiveQualityMetrics** - Line 362 - **Calculate-PrecisionRecallMetrics** - Line 437
- *...and 35 more functions*

--- 
### Unity-Claude-APIDocumentation

[⬆ Back to Contents](#-table-of-contents)

Intelligent documentation module that provides automated documentation generation, quality assessment, and cross-referencing capabilities. Maintains live documentation that updates automatically as the codebase evolves. Unity Editor integration module providing direct communication with Unity processes. Handles compilation monitoring, error extraction, project management, and automated testing workflows. 

**Module Statistics:**
 - Functions: 14
 - Dependencies: 3 modules


**Module Information:**
- **Path:** `Modules\Unity-Claude-APIDocumentation\Unity-Claude-APIDocumentation.psm1`
- **Size:** 28.41 KB
- **Last Modified:** 2025-08-26 11:46
- **Total Functions:** 10
- **Exported Functions:** 1


**Dependencies:**
- `$manifestPath.FullName` (external) - `$script:ModuleConfig.PlatypsPSVersion` (external) - `platyPS` (external)


**Key Functions:**
- **Write-DocLog** - Line 20 - **Install-PlatyPS** - Line 45 - **Initialize-DocumentationProject** - Line 105 - **New-ModuleDocumentation** - Line 184 - **New-FunctionDocumentation** - Line 305
- *...and 5 more functions*

--- 
### Unity-Claude-AST-Enhanced

[⬆ Back to Contents](#-table-of-contents)

Unity Editor integration module providing direct communication with Unity processes. Handles compilation monitoring, error extraction, project management, and automated testing workflows.

**Module Statistics:**
- Functions: 32
- Dependencies: 5 modules


**Module Information:**
- **Path:** `Modules\Unity-Claude-AST-Enhanced\Unity-Claude-AST-Enhanced.psm1`
- **Size:** 23.43 KB
- **Last Modified:** 2025-08-30 02:47
- **Total Functions:** 15
- **Exported Functions:** 1


**Dependencies:**
- `DependencySearch` (external) - `statements,` (external) - `statements` (external) - `commands` (external)


**Key Functions:**
- **Get-ModuleCallGraph** - Line 62 - **Get-CrossModuleRelationships** - Line 155 - **Get-FunctionCallAnalysis** - Line 248 - **Export-CallGraphData** - Line 349 - **Get-ModuleAnalysisFromPath** - Line 407
- *...and 10 more functions*

--- 
### Unity-Claude-AutoGen

[⬆ Back to Contents](#-table-of-contents)

Unity Editor integration module providing direct communication with Unity processes. Handles compilation monitoring, error extraction, project management, and automated testing workflows.

**Module Statistics:**
- Functions: 13


**Module Information:**
- **Path:** `Modules\Unity-Claude-AI-Integration\AutoGen\Unity-Claude-AutoGen.psm1`
- **Size:** 48.23 KB
- **Last Modified:** 2025-08-29 21:03
- **Total Functions:** 13
- **Exported Functions:** 1




**Key Functions:**
- **New-AutoGenAgent** - Line 44 - **Get-AutoGenAgent** - Line 286 - **New-AutoGenTeam** - Line 324 - **Invoke-AutoGenConversation** - Line 412 - **Start-AutoGenNamedPipeServer** - Line 601
- *...and 8 more functions*

--- 
### Unity-Claude-AutoGenMonitoring

[⬆ Back to Contents](#-table-of-contents)

Real-time monitoring module tracking system health, performance metrics, and Unity compilation status. Provides event-driven notifications and triggers automated responses to detected issues. Unity Editor integration module providing direct communication with Unity processes. Handles compilation monitoring, error extraction, project management, and automated testing workflows. 

**Module Statistics:**
 - Functions: 4


**Module Information:**
- **Path:** `Modules\Unity-Claude-AI-Integration\AutoGen\Unity-Claude-AutoGenMonitoring.psm1`
- **Size:** 15.56 KB
- **Last Modified:** 2025-08-29 18:33
- **Total Functions:** 4
- **Exported Functions:** 1




**Key Functions:**
- **Start-AutoGenActivityMonitoring** - Line 50 - **Get-AutoGenPerformanceMetrics** - Line 159 - **Invoke-AgentPerformanceOptimization** - Line 240 - **Stop-AutoGenActivityMonitoring** - Line 321


--- 
### Unity-Claude-AutonomousAgent-Refactored

[⬆ Back to Contents](#-table-of-contents)

Unity Editor integration module providing direct communication with Unity processes. Handles compilation monitoring, error extraction, project management, and automated testing workflows.

**Module Statistics:**
- Functions: 2
- Dependencies: 2 modules


**Module Information:**
- **Path:** `Modules\Unity-Claude-AutonomousAgent\Unity-Claude-AutonomousAgent-Refactored.psm1`
- **Size:** 8.77 KB
- **Last Modified:** 2025-08-20 17:25
- **Total Functions:** 1



**Dependencies:**
- `for` (external) - `$modulePath` (external)


**Key Functions:**
- **Get-ModuleStatus** - Line 143


--- 
### Unity-Claude-AutonomousDocumentationEngine

[⬆ Back to Contents](#-table-of-contents)

Intelligent documentation module that provides automated documentation generation, quality assessment, and cross-referencing capabilities. Maintains live documentation that updates automatically as the codebase evolves. Unity Editor integration module providing direct communication with Unity processes. Handles compilation monitoring, error extraction, project management, and automated testing workflows. 

**Module Statistics:**
 - Functions: 32
 - Dependencies: 5 modules


**Module Information:**
- **Path:** `Modules\Unity-Claude-AutonomousDocumentationEngine\Unity-Claude-AutonomousDocumentationEngine.psm1`
- **Size:** 55.81 KB
- **Last Modified:** 2025-08-30 19:47
- **Total Functions:** 29
- **Exported Functions:** 1


**Dependencies:**
- `$docAutomationPath` (external) - `$fileMonitorPath` (external) - `$triggersPath` (external) - `$ollamaPath` (external) - `$feedbackPath` (external)


**Key Functions:**
- **Initialize-AutonomousDocumentationEngine** - Line 75 - **Get-DefaultAutonomousDocConfiguration** - Line 152 - **Discover-DocumentationSystems** - Line 209 - **Initialize-AIDocumentationEngine** - Line 291 - **Process-AutonomousDocumentationUpdate** - Line 401
- *...and 24 more functions*

--- 
### Unity-Claude-AutonomousStateTracker

[⬆ Back to Contents](#-table-of-contents)

Unity Editor integration module providing direct communication with Unity processes. Handles compilation monitoring, error extraction, project management, and automated testing workflows.

**Module Statistics:**
- Functions: 18


**Module Information:**
- **Path:** `Modules\Unity-Claude-AutonomousStateTracker.psm1`
- **Size:** 30.86 KB
- **Last Modified:** 2025-08-20 17:25
- **Total Functions:** 18
- **Exported Functions:** 1




**Key Functions:**
- **Write-StateTrackerLog** - Line 129 - **Get-StateTimestamp** - Line 161 - **New-StateTrackingId** - Line 165 - **Initialize-AutonomousStateTracking** - Line 173 - **Get-AutonomousStateTracking** - Line 267
- *...and 13 more functions*

--- 
### Unity-Claude-AutonomousStateTracker-Enhanced

[⬆ Back to Contents](#-table-of-contents)

Unity Editor integration module providing direct communication with Unity processes. Handles compilation monitoring, error extraction, project management, and automated testing workflows.

**Module Statistics:**
- Functions: 4
- Dependencies: 1 modules


**Module Information:**
- **Path:** `Modules\Unity-Claude-AutonomousStateTracker-Enhanced\Unity-Claude-AutonomousStateTracker-Enhanced.psm1`
- **Size:** 21.74 KB
- **Last Modified:** 2025-08-26 11:46
- **Total Functions:** 3
- **Exported Functions:** 1


**Dependencies:**
- `$modulePath` (external)


**Key Functions:**
- **Get-AutonomousStateTrackerComponents** - Line 64 - **Test-AutonomousStateTrackerHealth** - Line 138 - **Invoke-ComprehensiveAutonomousAnalysis** - Line 316


--- 
### Unity-Claude-AutonomousStateTracker-Enhanced-Refactored

[⬆ Back to Contents](#-table-of-contents)

Unity Editor integration module providing direct communication with Unity processes. Handles compilation monitoring, error extraction, project management, and automated testing workflows.

**Module Statistics:**
- Functions: 4
- Dependencies: 1 modules


**Module Information:**
- **Path:** `Modules\Unity-Claude-AutonomousStateTracker-Enhanced\Unity-Claude-AutonomousStateTracker-Enhanced-Refactored.psm1`
- **Size:** 21.74 KB
- **Last Modified:** 2025-08-26 11:46
- **Total Functions:** 3
- **Exported Functions:** 1


**Dependencies:**
- `$modulePath` (external)


**Key Functions:**
- **Get-AutonomousStateTrackerComponents** - Line 64 - **Test-AutonomousStateTrackerHealth** - Line 138 - **Invoke-ComprehensiveAutonomousAnalysis** - Line 316


--- 
### Unity-Claude-Cache

[⬆ Back to Contents](#-table-of-contents)

Unity Editor integration module providing direct communication with Unity processes. Handles compilation monitoring, error extraction, project management, and automated testing workflows. Intelligent caching module optimizing performance through strategic data persistence. Implements LRU caching, dependency tracking, and automatic invalidation to reduce redundant computations. 

**Module Statistics:**
 - Functions: 10
 - Classes: 1


**Module Information:**
- **Path:** `Modules\Unity-Claude-Cache\Unity-Claude-Cache.psm1`
- **Size:** 25.32 KB
- **Last Modified:** 2025-08-25 13:45
- **Total Functions:** 32
- **Exported Functions:** 1




**Key Functions:**
- **CacheManager** - Line 24 - **CacheManager** - Line 28 - **CacheManager** - Line 32 - **Initialize** - Line 36 - **Set** - Line 76
- *...and 27 more functions*

--- 
### Unity-Claude-Cache-Fixed

[⬆ Back to Contents](#-table-of-contents)

Unity Editor integration module providing direct communication with Unity processes. Handles compilation monitoring, error extraction, project management, and automated testing workflows. Intelligent caching module optimizing performance through strategic data persistence. Implements LRU caching, dependency tracking, and automatic invalidation to reduce redundant computations. 

**Module Statistics:**
 - Functions: 10
 - Classes: 1


**Module Information:**
- **Path:** `Modules\Unity-Claude-Cache\Unity-Claude-Cache-Fixed.psm1`
- **Size:** 25.39 KB
- **Last Modified:** 2025-08-25 13:45
- **Total Functions:** 32
- **Exported Functions:** 1




**Key Functions:**
- **CacheManager** - Line 24 - **CacheManager** - Line 28 - **CacheManager** - Line 32 - **Initialize** - Line 36 - **Set** - Line 76
- *...and 27 more functions*

--- 
### Unity-Claude-Cache-Original

[⬆ Back to Contents](#-table-of-contents)

Unity Editor integration module providing direct communication with Unity processes. Handles compilation monitoring, error extraction, project management, and automated testing workflows. Intelligent caching module optimizing performance through strategic data persistence. Implements LRU caching, dependency tracking, and automatic invalidation to reduce redundant computations. 

**Module Statistics:**
 - Functions: 10
 - Classes: 1


**Module Information:**
- **Path:** `Modules\Unity-Claude-Cache\Unity-Claude-Cache-Original.psm1`
- **Size:** 25.15 KB
- **Last Modified:** 2025-08-25 13:45
- **Total Functions:** 31
- **Exported Functions:** 1




**Key Functions:**
- **CacheManager** - Line 23 - **CacheManager** - Line 27 - **CacheManager** - Line 31 - **Initialize** - Line 35 - **Set** - Line 80
- *...and 26 more functions*

--- 
### Unity-Claude-ChangeIntelligence

[⬆ Back to Contents](#-table-of-contents)

Unity Editor integration module providing direct communication with Unity processes. Handles compilation monitoring, error extraction, project management, and automated testing workflows.

**Module Statistics:**
- Functions: 15
- Dependencies: 2 modules


**Module Information:**
- **Path:** `Modules\Unity-Claude-ChangeIntelligence\Unity-Claude-ChangeIntelligence.psm1`
- **Size:** 20.69 KB
- **Last Modified:** 2025-08-30 12:45
- **Total Functions:** 13
- **Exported Functions:** 1




**Key Functions:**
- **Initialize-ChangeIntelligence** - Line 54 - **Initialize-ClassificationRules** - Line 82 - **Get-ChangeClassification** - Line 130 - **Get-ExtensionBasedClassification** - Line 196 - **Get-ContentBasedClassification** - Line 231
- *...and 8 more functions*

--- 
### Unity-Claude-ClaudeParallelization

[⬆ Back to Contents](#-table-of-contents)

High-performance parallel processing module designed to maximize throughput and system utilization. Implements thread-safe operations, runspace management, and concurrent execution patterns to handle multiple Unity operations simultaneously without blocking. Unity Editor integration module providing direct communication with Unity processes. Handles compilation monitoring, error extraction, project management, and automated testing workflows. 

**Module Statistics:**
 - Functions: 12
 - Dependencies: 2 modules


**Module Information:**
- **Path:** `Modules\Unity-Claude-ClaudeParallelization\Unity-Claude-ClaudeParallelization.psm1`
- **Size:** 53.27 KB
- **Last Modified:** 2025-08-21 17:45
- **Total Functions:** 11
- **Exported Functions:** 1


**Dependencies:**
- [`Unity-Claude-RunspaceManagement`](#unity-claude-runspacemanagement) - [`Unity-Claude-ParallelProcessing`](#unity-claude-parallelprocessing)


**Key Functions:**
- **Test-ModuleDependencyAvailability** - Line 3 - **Write-FallbackLog** - Line 66 - **Write-ClaudeParallelLog** - Line 85 - **New-ClaudeParallelSubmitter** - Line 149 - **Submit-ClaudeAPIParallel** - Line 260
- *...and 6 more functions*

--- 
### Unity-Claude-CLIOrchestrator

[⬆ Back to Contents](#-table-of-contents)

Unity Editor integration module providing direct communication with Unity processes. Handles compilation monitoring, error extraction, project management, and automated testing workflows. Master orchestration module coordinating complex multi-step workflows. Manages module interactions, handles state transitions, and ensures proper sequencing of automated operations. 

**Module Statistics:**
 - Functions: 7
 - Dependencies: 9 modules


**Module Information:**
- **Path:** `Modules\Unity-Claude-CLIOrchestrator\Unity-Claude-CLIOrchestrator.psm1`
- **Size:** 22.86 KB
- **Last Modified:** 2025-08-26 22:06
- **Total Functions:** 4
- **Exported Functions:** 2


**Dependencies:**
- `(Join-Path` (external) - `(Join-Path` (external) - `(Join-Path` (external) - `(Join-Path` (external) - `for` (external) - `(Join-Path` (external) - `(Join-Path` (external) - `(Join-Path` (external) - `(Join-Path` (external)


**Key Functions:**
- **Initialize-CLIOrchestrator** - Line 99 - **Test-CLIOrchestratorComponents** - Line 183 - **Get-CLIOrchestratorInfo** - Line 319 - **Update-CLISessionStats** - Line 391


--- 
### Unity-Claude-CLIOrchestrator-Fixed-Simple

[⬆ Back to Contents](#-table-of-contents)

Unity Editor integration module providing direct communication with Unity processes. Handles compilation monitoring, error extraction, project management, and automated testing workflows. Master orchestration module coordinating complex multi-step workflows. Manages module interactions, handles state transitions, and ensures proper sequencing of automated operations. 

**Module Statistics:**
 - Functions: 14


**Module Information:**
- **Path:** `Modules\Unity-Claude-CLIOrchestrator\Unity-Claude-CLIOrchestrator-Fixed-Simple.psm1`
- **Size:** 14.26 KB
- **Last Modified:** 2025-08-27 23:42
- **Total Functions:** 14
- **Exported Functions:** 1




**Key Functions:**
- **Initialize-CLIOrchestrator** - Line 41 - **Test-CLIOrchestratorComponents** - Line 72 - **Get-CLIOrchestratorInfo** - Line 102 - **Update-CLISessionStats** - Line 110 - **Process-ResponseFile** - Line 132
- *...and 9 more functions*

--- 
### Unity-Claude-CLIOrchestrator-FullFeatured

[⬆ Back to Contents](#-table-of-contents)

Unity Editor integration module providing direct communication with Unity processes. Handles compilation monitoring, error extraction, project management, and automated testing workflows. Master orchestration module coordinating complex multi-step workflows. Manages module interactions, handles state transitions, and ensures proper sequencing of automated operations. 

**Module Statistics:**
 - Functions: 2
 - Classes: 1


**Module Information:**
- **Path:** `Modules\Unity-Claude-CLIOrchestrator\Unity-Claude-CLIOrchestrator-FullFeatured.psm1`
- **Size:** 10.46 KB
- **Last Modified:** 2025-08-27 18:03
- **Total Functions:** 2
- **Exported Functions:** 1




**Key Functions:**
- **Initialize-CLIOrchestrator** - Line 186 - **Find-ClaudeWindow** - Line 205


--- 
### Unity-Claude-CLIOrchestrator-Original

[⬆ Back to Contents](#-table-of-contents)

Unity Editor integration module providing direct communication with Unity processes. Handles compilation monitoring, error extraction, project management, and automated testing workflows. Master orchestration module coordinating complex multi-step workflows. Manages module interactions, handles state transitions, and ensures proper sequencing of automated operations. 

**Module Statistics:**
 - Functions: 18
 - Classes: 1


**Module Information:**
- **Path:** `Modules\Unity-Claude-CLIOrchestrator\Unity-Claude-CLIOrchestrator-Original.psm1`
- **Size:** 74.96 KB
- **Last Modified:** 2025-08-28 12:37
- **Total Functions:** 15
- **Exported Functions:** 11




**Key Functions:**
- **Update-ClaudeWindowInfo** - Line 93 - **Find-ClaudeWindow** - Line 136 - **Switch-ToWindow** - Line 228 - **Submit-ToClaudeViaTypeKeys** - Line 275 - **Execute-TestScript** - Line 410
- *...and 10 more functions*

--- 
### Unity-Claude-CLIOrchestrator-Original-Backup

[⬆ Back to Contents](#-table-of-contents)

Unity Editor integration module providing direct communication with Unity processes. Handles compilation monitoring, error extraction, project management, and automated testing workflows. Master orchestration module coordinating complex multi-step workflows. Manages module interactions, handles state transitions, and ensures proper sequencing of automated operations. 

**Module Statistics:**
 - Functions: 5
 - Dependencies: 4 modules


**Module Information:**
- **Path:** `Modules\Unity-Claude-CLIOrchestrator\Unity-Claude-CLIOrchestrator-Original-Backup.psm1`
- **Size:** 22.7 KB
- **Last Modified:** 2025-08-26 11:46
- **Total Functions:** 4
- **Exported Functions:** 11


**Dependencies:**
- `(Join-Path` (external) - `(Join-Path` (external) - `(Join-Path` (external) - `(Join-Path` (external)


**Key Functions:**
- **Initialize-CLIOrchestrator** - Line 95 - **Test-CLIOrchestratorComponents** - Line 179 - **Get-CLIOrchestratorInfo** - Line 315 - **Update-CLISessionStats** - Line 387


--- 
### Unity-Claude-CLIOrchestrator-Refactored

[⬆ Back to Contents](#-table-of-contents)

Unity Editor integration module providing direct communication with Unity processes. Handles compilation monitoring, error extraction, project management, and automated testing workflows. Master orchestration module coordinating complex multi-step workflows. Manages module interactions, handles state transitions, and ensures proper sequencing of automated operations. 

**Module Statistics:**
 - Functions: 6


**Module Information:**
- **Path:** `Modules\Unity-Claude-CLIOrchestrator\Unity-Claude-CLIOrchestrator-Refactored.psm1`
- **Size:** 22.24 KB
- **Last Modified:** 2025-08-26 22:32
- **Total Functions:** 4
- **Exported Functions:** 2




**Key Functions:**
- **Initialize-CLIOrchestrator** - Line 87 - **Test-CLIOrchestratorComponents** - Line 171 - **Get-CLIOrchestratorInfo** - Line 307 - **Update-CLISessionStats** - Line 379


--- 
### Unity-Claude-CLIOrchestrator-Refactored-Fixed

[⬆ Back to Contents](#-table-of-contents)

Unity Editor integration module providing direct communication with Unity processes. Handles compilation monitoring, error extraction, project management, and automated testing workflows. Master orchestration module coordinating complex multi-step workflows. Manages module interactions, handles state transitions, and ensures proper sequencing of automated operations. 

**Module Statistics:**
 - Functions: 4


**Module Information:**
- **Path:** `Modules\Unity-Claude-CLIOrchestrator\Unity-Claude-CLIOrchestrator-Refactored-Fixed.psm1`
- **Size:** 15.12 KB
- **Last Modified:** 2025-08-27 17:22
- **Total Functions:** 4
- **Exported Functions:** 1




**Key Functions:**
- **Initialize-CLIOrchestrator** - Line 145 - **Test-CLIOrchestratorComponents** - Line 218 - **Get-CLIOrchestratorInfo** - Line 295 - **Update-CLISessionStats** - Line 327


--- 
### Unity-Claude-CLISubmission

[⬆ Back to Contents](#-table-of-contents)

Unity Editor integration module providing direct communication with Unity processes. Handles compilation monitoring, error extraction, project management, and automated testing workflows.

**Module Statistics:**
- Functions: 8
- Classes: 2
- Dependencies: 1 modules


**Module Information:**
- **Path:** `Modules\Unity-Claude-CLISubmission.psm1`
- **Size:** 45.44 KB
- **Last Modified:** 2025-08-20 17:25
- **Total Functions:** 7
- **Exported Functions:** 1


**Dependencies:**
- `$windowDetectionPath` (external)


**Key Functions:**
- **Start-UnityErrorMonitoring** - Line 38 - **Stop-UnityErrorMonitoring** - Line 129 - **New-AutonomousPrompt** - Line 150 - **Submit-PromptToClaudeCode** - Line 358 - **Start-ResponseMonitoring** - Line 739
- *...and 2 more functions*

--- 
### Unity-Claude-CLISubmission-Enhanced

[⬆ Back to Contents](#-table-of-contents)

Unity Editor integration module providing direct communication with Unity processes. Handles compilation monitoring, error extraction, project management, and automated testing workflows.

**Module Statistics:**
- Functions: 8
- Classes: 2
- Dependencies: 1 modules


**Module Information:**
- **Path:** `Modules\Unity-Claude-CLISubmission-Enhanced.psm1`
- **Size:** 16.43 KB
- **Last Modified:** 2025-08-21 20:16
- **Total Functions:** 6
- **Exported Functions:** 1


**Dependencies:**
- `(Join-Path` (external)


**Key Functions:**
- **Submit-ToClaudeWithInputLock** - Line 27 - **Start-InputLockProtection** - Line 144 - **Stop-InputLockProtection** - Line 194 - **Wait-ForResponseCompletion** - Line 272 - **Submit-ToClaude** - Line 352
- *...and 1 more functions*

--- 
### Unity-Claude-CodeQL

[⬆ Back to Contents](#-table-of-contents)

Unity Editor integration module providing direct communication with Unity processes. Handles compilation monitoring, error extraction, project management, and automated testing workflows.

**Module Statistics:**
- Functions: 10


**Module Information:**
- **Path:** `Modules\Unity-Claude-CodeQL\Unity-Claude-CodeQL.psm1`
- **Size:** 24.37 KB
- **Last Modified:** 2025-08-26 11:46
- **Total Functions:** 10
- **Exported Functions:** 1




**Key Functions:**
- **Write-CodeQLLog** - Line 21 - **Install-CodeQLCLI** - Line 46 - **Test-CodeQLInstallation** - Line 137 - **New-CodeQLDatabase** - Line 179 - **Initialize-PowerShellCodeQLDB** - Line 259
- *...and 5 more functions*

--- 
### Unity-Claude-ConcurrentCollections

[⬆ Back to Contents](#-table-of-contents)

Unity Editor integration module providing direct communication with Unity processes. Handles compilation monitoring, error extraction, project management, and automated testing workflows.

**Module Statistics:**
- Functions: 15


**Module Information:**
- **Path:** `Modules\Unity-Claude-ParallelProcessing\Unity-Claude-ConcurrentCollections.psm1`
- **Size:** 25.57 KB
- **Last Modified:** 2025-08-21 17:45
- **Total Functions:** 14
- **Exported Functions:** 1




**Key Functions:**
- **New-ConcurrentQueue** - Line 14 - **Add-ConcurrentQueueItem** - Line 80 - **Get-ConcurrentQueueItem** - Line 127 - **Test-ConcurrentQueueEmpty** - Line 192 - **Get-ConcurrentQueueCount** - Line 223
- *...and 9 more functions*

--- 
### Unity-Claude-ConcurrentProcessor

[⬆ Back to Contents](#-table-of-contents)

Unity Editor integration module providing direct communication with Unity processes. Handles compilation monitoring, error extraction, project management, and automated testing workflows.

**Module Statistics:**
- Functions: 17
- Dependencies: 1 modules


**Module Information:**
- **Path:** `Modules\Unity-Claude-ConcurrentProcessor.psm1`
- **Size:** 34.36 KB
- **Last Modified:** 2025-08-20 17:25
- **Total Functions:** 17
- **Exported Functions:** 1


**Dependencies:**
- `ThreadJob` (external)


**Key Functions:**
- **Write-ConcurrentLog** - Line 103 - **New-JobId** - Line 143 - **Get-ConcurrentTimestamp** - Line 147 - **Get-ProcessMutex** - Line 155 - **Invoke-WithMutex** - Line 175
- *...and 12 more functions*

--- 
### Unity-Claude-Core

[⬆ Back to Contents](#-table-of-contents)

Core infrastructure module providing fundamental functionality for the Unity-Claude system. This module serves as the foundation for other components, offering essential utilities, configuration management, and base services that other modules depend upon. Unity Editor integration module providing direct communication with Unity processes. Handles compilation monitoring, error extraction, project management, and automated testing workflows. 

**Module Statistics:**
 - Functions: 9
 - Classes: 2


**Module Information:**
- **Path:** `Modules\Unity-Claude-Core\Unity-Claude-Core.psm1`
- **Size:** 17.57 KB
- **Last Modified:** 2025-08-20 17:25
- **Total Functions:** 9
- **Exported Functions:** 1




**Key Functions:**
- **Initialize-AutomationContext** - Line 11 - **Write-Log** - Line 50 - **Get-FileTailAsString** - Line 87 - **Test-UnityCompilation** - Line 122 - **Export-UnityConsole** - Line 180
- *...and 4 more functions*

--- 
### Unity-Claude-CPG

[⬆ Back to Contents](#-table-of-contents)

Unity Editor integration module providing direct communication with Unity processes. Handles compilation monitoring, error extraction, project management, and automated testing workflows.

**Module Statistics:**
- Functions: 3
- Dependencies: 3 modules


**Module Information:**
- **Path:** `Modules\Unity-Claude-CPG\Unity-Claude-CPG.psm1`
- **Size:** 8.38 KB
- **Last Modified:** 2025-08-26 11:46
- **Total Functions:** 1
- **Exported Functions:** 1


**Dependencies:**
- `$dataStructuresPath` (external) - `$componentPath` (external) - `$astConverterPath` (external)


**Key Functions:**
- **ConvertTo-CPGFromScriptBlock** - Line 75


--- 
### Unity-Claude-CPG-ASTConverter

[⬆ Back to Contents](#-table-of-contents)

Unity Editor integration module providing direct communication with Unity processes. Handles compilation monitoring, error extraction, project management, and automated testing workflows.

**Module Statistics:**
- Functions: 31
- Classes: 2


**Module Information:**
- **Path:** `Modules\Unity-Claude-CPG\Unity-Claude-CPG-ASTConverter.psm1`
- **Size:** 37.8 KB
- **Last Modified:** 2025-08-24 23:42
- **Total Functions:** 20
- **Exported Functions:** 1




**Key Functions:**
- **Convert-ASTtoCPG** - Line 19 - **Process-ASTNode** - Line 99 - **Process-FunctionDefinition** - Line 233 - **Process-Command** - Line 324 - **Process-Variable** - Line 384
- *...and 15 more functions*

--- 
### Unity-Claude-CPG-Original

[⬆ Back to Contents](#-table-of-contents)

Unity Editor integration module providing direct communication with Unity processes. Handles compilation monitoring, error extraction, project management, and automated testing workflows.

**Module Statistics:**
- Functions: 17
- Classes: 3
- Dependencies: 1 modules


**Module Information:**
- **Path:** `Modules\Unity-Claude-CPG\Unity-Claude-CPG-Original.psm1`
- **Size:** 31.05 KB
- **Last Modified:** 2025-08-26 11:46
- **Total Functions:** 33
- **Exported Functions:** 1


**Dependencies:**
- `$astConverterPath` (external)


**Key Functions:**
- **CPGNode** - Line 105 - **CPGNode** - Line 113 - **ToString** - Line 123 - **ToHashtable** - Line 127 - **CPGEdge** - Line 157
- *...and 28 more functions*

--- 
### Unity-Claude-CPG-Refactored

[⬆ Back to Contents](#-table-of-contents)

Unity Editor integration module providing direct communication with Unity processes. Handles compilation monitoring, error extraction, project management, and automated testing workflows.

**Module Statistics:**
- Functions: 3
- Dependencies: 3 modules


**Module Information:**
- **Path:** `Modules\Unity-Claude-CPG\Unity-Claude-CPG-Refactored.psm1`
- **Size:** 8.38 KB
- **Last Modified:** 2025-08-26 11:46
- **Total Functions:** 1
- **Exported Functions:** 1


**Dependencies:**
- `$dataStructuresPath` (external) - `$componentPath` (external) - `$astConverterPath` (external)


**Key Functions:**
- **ConvertTo-CPGFromScriptBlock** - Line 75


--- 
### Unity-Claude-CrossLanguage

[⬆ Back to Contents](#-table-of-contents)

Unity Editor integration module providing direct communication with Unity processes. Handles compilation monitoring, error extraction, project management, and automated testing workflows.

**Module Statistics:**
- Functions: 10
- Classes: 2


**Module Information:**
- **Path:** `Modules\Unity-Claude-CPG\Unity-Claude-CrossLanguage.psm1`
- **Size:** 22.28 KB
- **Last Modified:** 2025-08-24 23:42
- **Total Functions:** 9
- **Exported Functions:** 1




**Key Functions:**
- **Merge-LanguageGraphs** - Line 13 - **Resolve-CrossLanguageImports** - Line 116 - **Test-ImportMatch** - Line 188 - **Resolve-SharedInterfaces** - Line 205 - **Resolve-DataModels** - Line 277
- *...and 4 more functions*

--- 
### Unity-Claude-DecisionEngine

[⬆ Back to Contents](#-table-of-contents)

Decision engine module implementing rule-based and ML-enhanced decision trees. Analyzes Claude responses, evaluates safety constraints, and determines appropriate actions based on configurable policies and learned patterns. Unity Editor integration module providing direct communication with Unity processes. Handles compilation monitoring, error extraction, project management, and automated testing workflows. 

**Module Statistics:**
 - Functions: 6
 - Dependencies: 2 modules


**Module Information:**
- **Path:** `Modules\Unity-Claude-DecisionEngine\Unity-Claude-DecisionEngine.psm1`
- **Size:** 18.09 KB
- **Last Modified:** 2025-08-26 11:46
- **Total Functions:** 5
- **Exported Functions:** 1


**Dependencies:**
- `$componentPath` (external) - `$module` (external)


**Key Functions:**
- **Import-DecisionEngineComponent** - Line 23 - **Get-DecisionEngineComponentStatus** - Line 122 - **Invoke-DecisionEngineAnalysis** - Line 168 - **Reset-DecisionEngine** - Line 250 - **Test-DecisionEngineDeployment** - Line 287


--- 
### Unity-Claude-DecisionEngine-Bayesian

[⬆ Back to Contents](#-table-of-contents)

Decision engine module implementing rule-based and ML-enhanced decision trees. Analyzes Claude responses, evaluates safety constraints, and determines appropriate actions based on configurable policies and learned patterns. Unity Editor integration module providing direct communication with Unity processes. Handles compilation monitoring, error extraction, project management, and automated testing workflows. 

**Module Statistics:**
 - Functions: 0


**Module Information:**
- **Path:** `Modules\Unity-Claude-CLIOrchestrator\Core\DecisionEngine-Bayesian\Unity-Claude-DecisionEngine-Bayesian.psm1`
- **Size:** 4.21 KB
- **Last Modified:** 2025-08-26 11:46
- **Total Functions:** 0
- **Exported Functions:** 1





--- 
### Unity-Claude-DecisionEngine-Original

[⬆ Back to Contents](#-table-of-contents)

Decision engine module implementing rule-based and ML-enhanced decision trees. Analyzes Claude responses, evaluates safety constraints, and determines appropriate actions based on configurable policies and learned patterns. Unity Editor integration module providing direct communication with Unity processes. Handles compilation monitoring, error extraction, project management, and automated testing workflows. 

**Module Statistics:**
 - Functions: 27
 - Dependencies: 1 modules


**Module Information:**
- **Path:** `Modules\Unity-Claude-DecisionEngine\Unity-Claude-DecisionEngine-Original.psm1`
- **Size:** 46.72 KB
- **Last Modified:** 2025-08-26 11:46
- **Total Functions:** 27



**Dependencies:**
- `$module` (external)


**Key Functions:**
- **Write-DecisionEngineLog** - Line 43 - **Test-RequiredModule** - Line 82 - **Get-DecisionEngineConfig** - Line 101 - **Set-DecisionEngineConfig** - Line 109 - **Invoke-HybridResponseAnalysis** - Line 165
- *...and 22 more functions*

--- 
### Unity-Claude-DecisionEngine-Refactored

[⬆ Back to Contents](#-table-of-contents)

Decision engine module implementing rule-based and ML-enhanced decision trees. Analyzes Claude responses, evaluates safety constraints, and determines appropriate actions based on configurable policies and learned patterns. Unity Editor integration module providing direct communication with Unity processes. Handles compilation monitoring, error extraction, project management, and automated testing workflows. 

**Module Statistics:**
 - Functions: 6
 - Dependencies: 2 modules


**Module Information:**
- **Path:** `Modules\Unity-Claude-DecisionEngine\Unity-Claude-DecisionEngine-Refactored.psm1`
- **Size:** 18.09 KB
- **Last Modified:** 2025-08-26 11:46
- **Total Functions:** 5
- **Exported Functions:** 1


**Dependencies:**
- `$componentPath` (external) - `$module` (external)


**Key Functions:**
- **Import-DecisionEngineComponent** - Line 23 - **Get-DecisionEngineComponentStatus** - Line 122 - **Invoke-DecisionEngineAnalysis** - Line 168 - **Reset-DecisionEngine** - Line 250 - **Test-DecisionEngineDeployment** - Line 287


--- 
### Unity-Claude-DocumentationAnalytics

[⬆ Back to Contents](#-table-of-contents)

Intelligent documentation module that provides automated documentation generation, quality assessment, and cross-referencing capabilities. Maintains live documentation that updates automatically as the codebase evolves. Unity Editor integration module providing direct communication with Unity processes. Handles compilation monitoring, error extraction, project management, and automated testing workflows. 

**Module Statistics:**
 - Functions: 14
 - Dependencies: 1 modules


**Module Information:**
- **Path:** `Modules\Unity-Claude-DocumentationAnalytics\Unity-Claude-DocumentationAnalytics.psm1`
- **Size:** 44.08 KB
- **Last Modified:** 2025-08-30 20:15
- **Total Functions:** 14
- **Exported Functions:** 1


**Dependencies:**
- [`Unity-Claude-Ollama`](#unity-claude-ollama)


**Key Functions:**
- **Initialize-DocumentationAnalytics** - Line 46 - **Start-DocumentationAnalytics** - Line 115 - **Get-DocumentationUsageMetrics** - Line 198 - **Get-ContentOptimizationRecommendations** - Line 317 - **Save-AnalyticsData** - Line 476
- *...and 9 more functions*

--- 
### Unity-Claude-DocumentationAutomation

[⬆ Back to Contents](#-table-of-contents)

Intelligent documentation module that provides automated documentation generation, quality assessment, and cross-referencing capabilities. Maintains live documentation that updates automatically as the codebase evolves. Unity Editor integration module providing direct communication with Unity processes. Handles compilation monitoring, error extraction, project management, and automated testing workflows. 

**Module Statistics:**
 - Functions: 3
 - Dependencies: 5 modules


**Module Information:**
- **Path:** `Modules\Unity-Claude-DocumentationAutomation\Unity-Claude-DocumentationAutomation.psm1`
- **Size:** 16.62 KB
- **Last Modified:** 2025-08-26 11:46
- **Total Functions:** 3
- **Exported Functions:** 1


**Dependencies:**
- `(Join-Path` (external) - `(Join-Path` (external) - `(Join-Path` (external) - `(Join-Path` (external) - `(Join-Path` (external)


**Key Functions:**
- **Initialize-DocumentationAutomation** - Line 84 - **Test-ComponentHealth** - Line 176 - **Get-DocumentationAutomationInfo** - Line 288


--- 
### Unity-Claude-DocumentationAutomation-Original

[⬆ Back to Contents](#-table-of-contents)

Intelligent documentation module that provides automated documentation generation, quality assessment, and cross-referencing capabilities. Maintains live documentation that updates automatically as the codebase evolves. Unity Editor integration module providing direct communication with Unity processes. Handles compilation monitoring, error extraction, project management, and automated testing workflows. 

**Module Statistics:**
 - Functions: 20


**Module Information:**
- **Path:** `Modules\Unity-Claude-DocumentationAutomation\Unity-Claude-DocumentationAutomation-Original.psm1`
- **Size:** 54.38 KB
- **Last Modified:** 2025-08-25 13:45
- **Total Functions:** 20
- **Exported Functions:** 1




**Key Functions:**
- **Start-DocumentationAutomation** - Line 39 - **Stop-DocumentationAutomation** - Line 121 - **Test-DocumentationSync** - Line 161 - **Get-DocumentationStatus** - Line 243 - **New-DocumentationPR** - Line 288
- *...and 15 more functions*

--- 
### Unity-Claude-DocumentationAutomation-Refactored

[⬆ Back to Contents](#-table-of-contents)

Intelligent documentation module that provides automated documentation generation, quality assessment, and cross-referencing capabilities. Maintains live documentation that updates automatically as the codebase evolves. Unity Editor integration module providing direct communication with Unity processes. Handles compilation monitoring, error extraction, project management, and automated testing workflows. 

**Module Statistics:**
 - Functions: 3
 - Dependencies: 5 modules


**Module Information:**
- **Path:** `Modules\Unity-Claude-DocumentationAutomation\Unity-Claude-DocumentationAutomation-Refactored.psm1`
- **Size:** 16.62 KB
- **Last Modified:** 2025-08-26 11:46
- **Total Functions:** 3
- **Exported Functions:** 1


**Dependencies:**
- `(Join-Path` (external) - `(Join-Path` (external) - `(Join-Path` (external) - `(Join-Path` (external) - `(Join-Path` (external)


**Key Functions:**
- **Initialize-DocumentationAutomation** - Line 84 - **Test-ComponentHealth** - Line 176 - **Get-DocumentationAutomationInfo** - Line 288


--- 
### Unity-Claude-DocumentationCrossReference

[⬆ Back to Contents](#-table-of-contents)

Intelligent documentation module that provides automated documentation generation, quality assessment, and cross-referencing capabilities. Maintains live documentation that updates automatically as the codebase evolves. Unity Editor integration module providing direct communication with Unity processes. Handles compilation monitoring, error extraction, project management, and automated testing workflows. 

**Module Statistics:**
 - Functions: 31
 - Dependencies: 5 modules


**Module Information:**
- **Path:** `Modules\Unity-Claude-DocumentationCrossReference\Unity-Claude-DocumentationCrossReference.psm1`
- **Size:** 64.02 KB
- **Last Modified:** 2025-08-30 19:08
- **Total Functions:** 12
- **Exported Functions:** 1


**Dependencies:**
- `statements` (external) - `$qualityAssessmentPath` (external) - `$orchestratorPath` (external) - `$ollamaPath` (external)


**Key Functions:**
- **Initialize-DocumentationCrossReference** - Line 70 - **Get-ASTCrossReferences** - Line 181 - **Extract-MarkdownLinks** - Line 433 - **Find-FunctionDefinitions** - Line 582 - **Find-FunctionCalls** - Line 683
- *...and 7 more functions*

--- 
### Unity-Claude-DocumentationDrift

[⬆ Back to Contents](#-table-of-contents)

Intelligent documentation module that provides automated documentation generation, quality assessment, and cross-referencing capabilities. Maintains live documentation that updates automatically as the codebase evolves. Unity Editor integration module providing direct communication with Unity processes. Handles compilation monitoring, error extraction, project management, and automated testing workflows. 

**Module Statistics:**
 - Functions: 65
 - Classes: 8
 - Dependencies: 3 modules


**Module Information:**
- **Path:** `Modules\Unity-Claude-DocumentationDrift\Unity-Claude-DocumentationDrift.psm1`
- **Size:** 142.95 KB
- **Last Modified:** 2025-08-24 12:06
- **Total Functions:** 55
- **Exported Functions:** 1


**Dependencies:**
- [`Unity-Claude-RepoAnalyst`](#unity-claude-repoanalyst) - [`Unity-Claude-FileMonitor`](#unity-claude-filemonitor) - [`Unity-Claude-GitHub`](#unity-claude-github)


**Key Functions:**
- **Initialize-DocumentationDrift** - Line 62 - **Get-DocumentationDriftConfig** - Line 145 - **Set-DocumentationDriftConfig** - Line 168 - **Clear-DriftCache** - Line 211 - **Get-DriftDetectionResults** - Line 243
- *...and 50 more functions*

--- 
### Unity-Claude-DocumentationDrift-Refactored

[⬆ Back to Contents](#-table-of-contents)

Intelligent documentation module that provides automated documentation generation, quality assessment, and cross-referencing capabilities. Maintains live documentation that updates automatically as the codebase evolves. Unity Editor integration module providing direct communication with Unity processes. Handles compilation monitoring, error extraction, project management, and automated testing workflows. 

**Module Statistics:**
 - Functions: 3
 - Dependencies: 2 modules


**Module Information:**
- **Path:** `Modules\Unity-Claude-DocumentationDrift\Unity-Claude-DocumentationDrift-Refactored.psm1`
- **Size:** 9.91 KB
- **Last Modified:** 2025-08-26 11:46
- **Total Functions:** 3
- **Exported Functions:** 1


**Dependencies:**
- `$ModulePath\Core\Configuration.psd1` (external) - `$ModulePath\Analysis\ImpactAnalysis.psd1` (external)


**Key Functions:**
- **Clear-DriftCache** - Line 33 - **Get-DriftDetectionResults** - Line 68 - **Test-DocumentationDrift** - Line 93


--- 
### Unity-Claude-DocumentationPipeline

[⬆ Back to Contents](#-table-of-contents)

Intelligent documentation module that provides automated documentation generation, quality assessment, and cross-referencing capabilities. Maintains live documentation that updates automatically as the codebase evolves. Unity Editor integration module providing direct communication with Unity processes. Handles compilation monitoring, error extraction, project management, and automated testing workflows. 

**Module Statistics:**
 - Functions: 6
 - Dependencies: 4 modules


**Module Information:**
- **Path:** `Modules\Unity-Claude-LLM\Unity-Claude-DocumentationPipeline.psm1`
- **Size:** 13.73 KB
- **Last Modified:** 2025-08-25 03:00
- **Total Functions:** 6
- **Exported Functions:** 1


**Dependencies:**
- `$PSScriptRoot\..\Unity-Claude-CPG\Unity-Claude-CPG.psd1` (external) - `$PSScriptRoot\..\Unity-Claude-CPG\Unity-Claude-SemanticAnalysis.psd1` (external) - `$PSScriptRoot\Unity-Claude-LLM.psd1` (external)


**Key Functions:**
- **New-EnhancedDocumentationPipeline** - Line 11 - **Invoke-SemanticAnalysisPipeline** - Line 117 - **Invoke-ArchitectureAnalysis** - Line 152 - **Build-DocumentationContext** - Line 179 - **New-DocumentationIndex** - Line 226
- *...and 1 more functions*

--- 
### Unity-Claude-DocumentationQualityAssessment

[⬆ Back to Contents](#-table-of-contents)

Intelligent documentation module that provides automated documentation generation, quality assessment, and cross-referencing capabilities. Maintains live documentation that updates automatically as the codebase evolves. Unity Editor integration module providing direct communication with Unity processes. Handles compilation monitoring, error extraction, project management, and automated testing workflows. 

**Module Statistics:**
 - Functions: 2
 - Dependencies: 4 modules


**Module Information:**
- **Path:** `Modules\Unity-Claude-DocumentationQualityAssessment\Unity-Claude-DocumentationQualityAssessment.psm1`
- **Size:** 5.28 KB
- **Last Modified:** 2025-08-30 19:40
- **Total Functions:** 1
- **Exported Functions:** 2


**Dependencies:**
- `$PSScriptRoot\Components\SystemIntegration.psm1` (external) - `$PSScriptRoot\Components\ReadabilityAlgorithms.psm1` (external) - `$PSScriptRoot\Components\AIAssessment.psm1` (external) - `$PSScriptRoot\Components\ContentAnalysis.psm1` (external)


**Key Functions:**
- **Assess-DocumentationQuality** - Line 11


--- 
### Unity-Claude-DocumentationQualityAssessment_Original_20250830_193150

[⬆ Back to Contents](#-table-of-contents)

Intelligent documentation module that provides automated documentation generation, quality assessment, and cross-referencing capabilities. Maintains live documentation that updates automatically as the codebase evolves. Unity Editor integration module providing direct communication with Unity processes. Handles compilation monitoring, error extraction, project management, and automated testing workflows. 

**Module Statistics:**
 - Functions: 26
 - Dependencies: 3 modules


**Module Information:**
- **Path:** `Modules\Unity-Claude-DocumentationQualityAssessment\Unity-Claude-DocumentationQualityAssessment_Original_20250830_193150.psm1`
- **Size:** 38.58 KB
- **Last Modified:** 2025-08-30 19:27
- **Total Functions:** 3
- **Exported Functions:** 1


**Dependencies:**
- `$autonomousPath` (external) - `$ollamaPath` (external) - `$alertQualityPath` (external)


**Key Functions:**
- **Initialize-DocumentationQualityAssessment** - Line 79 - **Get-DefaultQualityAssessmentConfiguration** - Line 153 - **Assess-DocumentationQuality** - Line 220


--- 
### Unity-Claude-DocumentationQualityOrchestrator

[⬆ Back to Contents](#-table-of-contents)

Intelligent documentation module that provides automated documentation generation, quality assessment, and cross-referencing capabilities. Maintains live documentation that updates automatically as the codebase evolves. Unity Editor integration module providing direct communication with Unity processes. Handles compilation monitoring, error extraction, project management, and automated testing workflows. Master orchestration module coordinating complex multi-step workflows. Manages module interactions, handles state transitions, and ensures proper sequencing of automated operations. 

**Module Statistics:**
 - Functions: 24
 - Dependencies: 3 modules


**Module Information:**
- **Path:** `Modules\Unity-Claude-DocumentationQualityOrchestrator\Unity-Claude-DocumentationQualityOrchestrator.psm1`
- **Size:** 37.23 KB
- **Last Modified:** 2025-08-30 18:38
- **Total Functions:** 24
- **Exported Functions:** 1


**Dependencies:**
- `$qualityPath` (external) - `$autonomousPath` (external) - `$alertPath` (external)


**Key Functions:**
- **Initialize-DocumentationQualityOrchestrator** - Line 60 - **Get-DefaultOrchestratorConfiguration** - Line 141 - **Start-DocumentationQualityWorkflow** - Line 178 - **Execute-ComprehensiveReviewWorkflow** - Line 300 - **Evaluate-QualityRules** - Line 434
- *...and 19 more functions*

--- 
### Unity-Claude-DocumentationSuggestions

[⬆ Back to Contents](#-table-of-contents)

Intelligent documentation module that provides automated documentation generation, quality assessment, and cross-referencing capabilities. Maintains live documentation that updates automatically as the codebase evolves. Unity Editor integration module providing direct communication with Unity processes. Handles compilation monitoring, error extraction, project management, and automated testing workflows. 

**Module Statistics:**
 - Functions: 18
 - Dependencies: 4 modules


**Module Information:**
- **Path:** `Modules\Unity-Claude-DocumentationSuggestions\Unity-Claude-DocumentationSuggestions.psm1`
- **Size:** 43.47 KB
- **Last Modified:** 2025-08-30 19:47
- **Total Functions:** 15
- **Exported Functions:** 1


**Dependencies:**
- `$crossRefPath` (external) - `$ollamaPath` (external) - `$qualityPath` (external)


**Key Functions:**
- **Initialize-DocumentationSuggestions** - Line 49 - **Generate-RelatedContentSuggestions** - Line 134 - **Generate-ContentEmbedding** - Line 288 - **ConvertTo-SimpleEmbedding** - Line 368 - **Find-RelatedContent** - Line 442
- *...and 10 more functions*

--- 
### Unity-Claude-DocumentationVersioning

[⬆ Back to Contents](#-table-of-contents)

Intelligent documentation module that provides automated documentation generation, quality assessment, and cross-referencing capabilities. Maintains live documentation that updates automatically as the codebase evolves. Unity Editor integration module providing direct communication with Unity processes. Handles compilation monitoring, error extraction, project management, and automated testing workflows. 

**Module Statistics:**
 - Functions: 26


**Module Information:**
- **Path:** `Modules\Unity-Claude-DocumentationVersioning\Unity-Claude-DocumentationVersioning.psm1`
- **Size:** 25.49 KB
- **Last Modified:** 2025-08-30 15:41
- **Total Functions:** 25
- **Exported Functions:** 1




**Key Functions:**
- **Initialize-DocumentationVersioning** - Line 68 - **Get-DefaultVersioningConfiguration** - Line 148 - **Create-DocumentationVersion** - Line 204 - **Track-DocumentationChangeCorrelation** - Line 304 - **Create-DocumentationRelease** - Line 394
- *...and 20 more functions*

--- 
### Unity-Claude-EmailNotifications

[⬆ Back to Contents](#-table-of-contents)

Artificial Intelligence integration module that bridges PowerShell automation with AI services. Provides intelligent error analysis, pattern recognition, and automated decision-making capabilities through Claude AI or local LLM integration. Email notification module providing multi-channel alert delivery. Supports SMTP configuration, templated messages, and escalation chains for critical system events. Unity Editor integration module providing direct communication with Unity processes. Handles compilation monitoring, error extraction, project management, and automated testing workflows. 

**Module Statistics:**
 - Functions: 7


**Module Information:**
- **Path:** `Modules\Unity-Claude-EmailNotifications\Unity-Claude-EmailNotifications.psm1`
- **Size:** 27.9 KB
- **Last Modified:** 2025-08-21 17:45
- **Total Functions:** 7
- **Exported Functions:** 1




**Key Functions:**
- **Load-MailKitAssemblies** - Line 22 - **New-EmailConfiguration** - Line 84 - **Set-EmailCredentials** - Line 166 - **Test-EmailConfiguration** - Line 253 - **Get-EmailConfiguration** - Line 408
- *...and 2 more functions*

--- 
### Unity-Claude-EmailNotifications-SystemNetMail

[⬆ Back to Contents](#-table-of-contents)

Artificial Intelligence integration module that bridges PowerShell automation with AI services. Provides intelligent error analysis, pattern recognition, and automated decision-making capabilities through Claude AI or local LLM integration. Email notification module providing multi-channel alert delivery. Supports SMTP configuration, templated messages, and escalation chains for critical system events. Unity Editor integration module providing direct communication with Unity processes. Handles compilation monitoring, error extraction, project management, and automated testing workflows. 

**Module Statistics:**
 - Functions: 13


**Module Information:**
- **Path:** `Modules\Unity-Claude-EmailNotifications\Unity-Claude-EmailNotifications-SystemNetMail.psm1`
- **Size:** 45.7 KB
- **Last Modified:** 2025-08-21 17:45
- **Total Functions:** 13
- **Exported Functions:** 1




**Key Functions:**
- **New-EmailConfiguration** - Line 23 - **Set-EmailCredentials** - Line 106 - **Test-EmailConfiguration** - Line 191 - **Send-EmailNotification** - Line 331 - **Get-EmailConfiguration** - Line 470
- *...and 8 more functions*

--- 
### Unity-Claude-ErrorHandling

[⬆ Back to Contents](#-table-of-contents)

Unity Editor integration module providing direct communication with Unity processes. Handles compilation monitoring, error extraction, project management, and automated testing workflows.

**Module Statistics:**
- Functions: 9


**Module Information:**
- **Path:** `Modules\Unity-Claude-ParallelProcessing\Unity-Claude-ErrorHandling.psm1`
- **Size:** 28.54 KB
- **Last Modified:** 2025-08-21 17:45
- **Total Functions:** 9
- **Exported Functions:** 1




**Key Functions:**
- **Invoke-AsyncWithErrorHandling** - Line 49 - **New-ParallelErrorAggregator** - Line 189 - **Get-ParallelErrorClassification** - Line 246 - **Get-ParallelErrorReport** - Line 317 - **Initialize-CircuitBreaker** - Line 402
- *...and 4 more functions*

--- 
### Unity-Claude-Errors

[⬆ Back to Contents](#-table-of-contents)

Unity Editor integration module providing direct communication with Unity processes. Handles compilation monitoring, error extraction, project management, and automated testing workflows.

**Module Statistics:**
- Functions: 9
- Dependencies: 2 modules


**Module Information:**
- **Path:** `Modules\Unity-Claude-Errors\Unity-Claude-Errors.psm1`
- **Size:** 23.76 KB
- **Last Modified:** 2025-08-20 17:25
- **Total Functions:** 9
- **Exported Functions:** 1


**Dependencies:**
- [`Unity-Claude-Core`](#unity-claude-core) - `PSSQLite` (external)


**Key Functions:**
- **Initialize-ErrorDatabase** - Line 14 - **Add-ErrorPattern** - Line 101 - **Get-ErrorPattern** - Line 165 - **Find-SimilarErrors** - Line 213 - **Update-ErrorSolution** - Line 270
- *...and 4 more functions*

--- 
### Unity-Claude-EventLog

[⬆ Back to Contents](#-table-of-contents)

Unity Editor integration module providing direct communication with Unity processes. Handles compilation monitoring, error extraction, project management, and automated testing workflows.

**Module Statistics:**
- Functions: 4


**Module Information:**
- **Path:** `Modules\Unity-Claude-EventLog\Unity-Claude-EventLog.psm1`
- **Size:** 4.87 KB
- **Last Modified:** 2025-08-24 12:06
- **Total Functions:** 1





**Key Functions:**
- **Write-UCDebugLog** - Line 35


--- 
### Unity-Claude-FileMonitor

[⬆ Back to Contents](#-table-of-contents)

Real-time monitoring module tracking system health, performance metrics, and Unity compilation status. Provides event-driven notifications and triggers automated responses to detected issues. Unity Editor integration module providing direct communication with Unity processes. Handles compilation monitoring, error extraction, project management, and automated testing workflows. 

**Module Statistics:**
 - Functions: 15


**Module Information:**
- **Path:** `Modules\Unity-Claude-FileMonitor\Unity-Claude-FileMonitor.psm1`
- **Size:** 24.06 KB
- **Last Modified:** 2025-08-24 12:06
- **Total Functions:** 15
- **Exported Functions:** 1




**Key Functions:**
- **New-FileMonitor** - Line 35 - **Start-FileMonitor** - Line 101 - **Stop-FileMonitor** - Line 272 - **Aggregate-Changes** - Line 328 - **Get-FileType** - Line 366
- *...and 10 more functions*

--- 
### Unity-Claude-FileMonitor-Fixed

[⬆ Back to Contents](#-table-of-contents)

Real-time monitoring module tracking system health, performance metrics, and Unity compilation status. Provides event-driven notifications and triggers automated responses to detected issues. Unity Editor integration module providing direct communication with Unity processes. Handles compilation monitoring, error extraction, project management, and automated testing workflows. 

**Module Statistics:**
 - Functions: 17


**Module Information:**
- **Path:** `Modules\Unity-Claude-FileMonitor\Unity-Claude-FileMonitor-Fixed.psm1`
- **Size:** 25.9 KB
- **Last Modified:** 2025-08-24 12:06
- **Total Functions:** 17
- **Exported Functions:** 1




**Key Functions:**
- **Write-FileMonitorLog** - Line 28 - **New-FileMonitor** - Line 52 - **Start-FileMonitor** - Line 122 - **Start-DebounceTimer** - Line 239 - **Get-AggregatedChanges** - Line 306
- *...and 12 more functions*

--- 
### Unity-Claude-FixEngine

[⬆ Back to Contents](#-table-of-contents)

Unity Editor integration module providing direct communication with Unity processes. Handles compilation monitoring, error extraction, project management, and automated testing workflows.

**Module Statistics:**
- Functions: 25
- Classes: 1
- Dependencies: 2 modules


**Module Information:**
- **Path:** `Modules\Unity-Claude-FixEngine\Unity-Claude-FixEngine.psm1`
- **Size:** 49.76 KB
- **Last Modified:** 2025-08-20 17:25
- **Total Functions:** 25



**Dependencies:**
- [`Unity-Claude-Safety`](#unity-claude-safety) - [`Unity-Claude-Learning`](#unity-claude-learning)


**Key Functions:**
- **Write-FixEngineLog** - Line 48 - **Test-RequiredModule** - Line 87 - **Get-FixEngineConfig** - Line 106 - **Set-FixEngineConfig** - Line 114 - **New-BackupFile** - Line 176
- *...and 20 more functions*

--- 
### Unity-Claude-GitHub

[⬆ Back to Contents](#-table-of-contents)

GitHub integration module enabling version control operations, issue management, and pull request automation. Facilitates collaborative development workflows and automated documentation updates. Unity Editor integration module providing direct communication with Unity processes. Handles compilation monitoring, error extraction, project management, and automated testing workflows. 

**Module Statistics:**
 - Functions: 2


**Module Information:**
- **Path:** `Modules\Unity-Claude-GitHub\Unity-Claude-GitHub.psm1`
- **Size:** 7.07 KB
- **Last Modified:** 2025-08-30 23:15
- **Total Functions:** 1
- **Exported Functions:** 1




**Key Functions:**
- **ConvertTo-HashTable** - Line 54


--- 
### Unity-Claude-GovernanceIntegration

[⬆ Back to Contents](#-table-of-contents)

Unity Editor integration module providing direct communication with Unity processes. Handles compilation monitoring, error extraction, project management, and automated testing workflows.

**Module Statistics:**
- Functions: 7


**Module Information:**
- **Path:** `Modules\Unity-Claude-HITL\Unity-Claude-GovernanceIntegration.psm1`
- **Size:** 22.24 KB
- **Last Modified:** 2025-08-24 12:06
- **Total Functions:** 7
- **Exported Functions:** 1




**Key Functions:**
- **Test-GitHubGovernanceCompliance** - Line 7 - **New-GovernanceAwareApprovalRequest** - Line 178 - **Wait-GovernanceApproval** - Line 310 - **Get-CodeOwnersRequirements** - Line 410 - **Get-ChangeRiskAssessment** - Line 450
- *...and 2 more functions*

--- 
### Unity-Claude-HITL

[⬆ Back to Contents](#-table-of-contents)

Unity Editor integration module providing direct communication with Unity processes. Handles compilation monitoring, error extraction, project management, and automated testing workflows.

**Module Statistics:**
- Functions: 3
- Dependencies: 2 modules


**Module Information:**
- **Path:** `Modules\Unity-Claude-HITL\Unity-Claude-HITL.psm1`
- **Size:** 15.55 KB
- **Last Modified:** 2025-08-26 11:46
- **Total Functions:** 3
- **Exported Functions:** 1


**Dependencies:**
- `$ComponentPath` (external) - [`Unity-Claude-GitHub`](#unity-claude-github)


**Key Functions:**
- **Get-HITLComponents** - Line 43 - **Test-HITLSystemIntegration** - Line 84 - **Invoke-ComprehensiveHITLAnalysis** - Line 218


--- 
### Unity-Claude-HITL-Original

[⬆ Back to Contents](#-table-of-contents)

Unity Editor integration module providing direct communication with Unity processes. Handles compilation monitoring, error extraction, project management, and automated testing workflows.

**Module Statistics:**
- Functions: 13
- Dependencies: 2 modules


**Module Information:**
- **Path:** `Modules\Unity-Claude-HITL\Unity-Claude-HITL-Original.psm1`
- **Size:** 32.77 KB
- **Last Modified:** 2025-08-26 11:46
- **Total Functions:** 13



**Dependencies:**
- [`Unity-Claude-GitHub`](#unity-claude-github) - `$governanceModule` (external)


**Key Functions:**
- **Initialize-ApprovalDatabase** - Line 56 - **New-ApprovalToken** - Line 178 - **Test-ApprovalToken** - Line 233 - **New-ApprovalRequest** - Line 282 - **Send-ApprovalNotification** - Line 404
- *...and 8 more functions*

--- 
### Unity-Claude-HITL-Refactored

[⬆ Back to Contents](#-table-of-contents)

Unity Editor integration module providing direct communication with Unity processes. Handles compilation monitoring, error extraction, project management, and automated testing workflows.

**Module Statistics:**
- Functions: 3
- Dependencies: 2 modules


**Module Information:**
- **Path:** `Modules\Unity-Claude-HITL\Unity-Claude-HITL-Refactored.psm1`
- **Size:** 15.55 KB
- **Last Modified:** 2025-08-26 11:46
- **Total Functions:** 3
- **Exported Functions:** 1


**Dependencies:**
- `$ComponentPath` (external) - [`Unity-Claude-GitHub`](#unity-claude-github)


**Key Functions:**
- **Get-HITLComponents** - Line 43 - **Test-HITLSystemIntegration** - Line 84 - **Invoke-ComprehensiveHITLAnalysis** - Line 218


--- 
### Unity-Claude-IncrementalProcessor

[⬆ Back to Contents](#-table-of-contents)

Unity Editor integration module providing direct communication with Unity processes. Handles compilation monitoring, error extraction, project management, and automated testing workflows.

**Module Statistics:**
- Functions: 10
- Classes: 1
- Dependencies: 2 modules


**Module Information:**
- **Path:** `Modules\Unity-Claude-IncrementalProcessor\Unity-Claude-IncrementalProcessor.psm1`
- **Size:** 28.41 KB
- **Last Modified:** 2025-08-25 13:45
- **Total Functions:** 34
- **Exported Functions:** 1


**Dependencies:**
- `statements` (external)


**Key Functions:**
- **IncrementalProcessor** - Line 25 - **SetupFileWatcher** - Line 57 - **Start** - Line 94 - **Stop** - Line 104 - **CreateInitialSnapshots** - Line 111
- *...and 29 more functions*

--- 
### Unity-Claude-IncrementalProcessor-Fixed

[⬆ Back to Contents](#-table-of-contents)

Unity Editor integration module providing direct communication with Unity processes. Handles compilation monitoring, error extraction, project management, and automated testing workflows.

**Module Statistics:**
- Functions: 10
- Classes: 1
- Dependencies: 2 modules


**Module Information:**
- **Path:** `Modules\Unity-Claude-IncrementalProcessor\Unity-Claude-IncrementalProcessor-Fixed.psm1`
- **Size:** 28.41 KB
- **Last Modified:** 2025-08-25 13:45
- **Total Functions:** 34
- **Exported Functions:** 1


**Dependencies:**
- `statements` (external)


**Key Functions:**
- **IncrementalProcessor** - Line 25 - **SetupFileWatcher** - Line 57 - **Start** - Line 94 - **Stop** - Line 104 - **CreateInitialSnapshots** - Line 111
- *...and 29 more functions*

--- 
### Unity-Claude-IntegratedWorkflow

[⬆ Back to Contents](#-table-of-contents)

Unity Editor integration module providing direct communication with Unity processes. Handles compilation monitoring, error extraction, project management, and automated testing workflows.

**Module Statistics:**
- Functions: 6
- Dependencies: 1 modules


**Module Information:**
- **Path:** `Modules\Unity-Claude-IntegratedWorkflow\Unity-Claude-IntegratedWorkflow.psm1`
- **Size:** 9.29 KB
- **Last Modified:** 2025-08-26 11:46
- **Total Functions:** 0
- **Exported Functions:** 1


**Dependencies:**
- `$componentFullPath` (external)



--- 
### Unity-Claude-IntegratedWorkflow-Original

[⬆ Back to Contents](#-table-of-contents)

Unity Editor integration module providing direct communication with Unity processes. Handles compilation monitoring, error extraction, project management, and automated testing workflows.

**Module Statistics:**
- Functions: 16
- Dependencies: 3 modules


**Module Information:**
- **Path:** `Modules\Unity-Claude-IntegratedWorkflow\Unity-Claude-IntegratedWorkflow-Original.psm1`
- **Size:** 82.62 KB
- **Last Modified:** 2025-08-26 11:46
- **Total Functions:** 13
- **Exported Functions:** 1


**Dependencies:**
- `$RunspaceManagementPath` (external) - `$UnityParallelizationPath` (external) - `$ClaudeParallelizationPath` (external)


**Key Functions:**
- **Test-ModuleDependencyAvailability** - Line 3 - **Test-ModuleDependencies** - Line 92 - **Write-FallbackLog** - Line 113 - **Write-IntegratedWorkflowLog** - Line 135 - **Assert-Dependencies** - Line 160
- *...and 8 more functions*

--- 
### Unity-Claude-IntegratedWorkflow-Refactored

[⬆ Back to Contents](#-table-of-contents)

Unity Editor integration module providing direct communication with Unity processes. Handles compilation monitoring, error extraction, project management, and automated testing workflows.

**Module Statistics:**
- Functions: 6
- Dependencies: 1 modules


**Module Information:**
- **Path:** `Modules\Unity-Claude-IntegratedWorkflow\Unity-Claude-IntegratedWorkflow-Refactored.psm1`
- **Size:** 9.29 KB
- **Last Modified:** 2025-08-26 11:46
- **Total Functions:** 0
- **Exported Functions:** 1


**Dependencies:**
- `$componentFullPath` (external)



--- 
### Unity-Claude-IntegrationEngine

[⬆ Back to Contents](#-table-of-contents)

Unity Editor integration module providing direct communication with Unity processes. Handles compilation monitoring, error extraction, project management, and automated testing workflows.

**Module Statistics:**
- Functions: 20
- Dependencies: 1 modules


**Module Information:**
- **Path:** `Modules\Unity-Claude-IntegrationEngine.psm1`
- **Size:** 29.48 KB
- **Last Modified:** 2025-08-20 17:25
- **Total Functions:** 20
- **Exported Functions:** 1


**Dependencies:**
- `$modulePath` (external)


**Key Functions:**
- **Write-IntegrationLog** - Line 81 - **Get-CurrentTimestamp** - Line 113 - **New-CycleId** - Line 117 - **Initialize-IntegrationState** - Line 125 - **Get-IntegrationState** - Line 158
- *...and 15 more functions*

--- 
### Unity-Claude-IntelligentAlerting

[⬆ Back to Contents](#-table-of-contents)

Unity Editor integration module providing direct communication with Unity processes. Handles compilation monitoring, error extraction, project management, and automated testing workflows.

**Module Statistics:**
- Functions: 15
- Dependencies: 5 modules


**Module Information:**
- **Path:** `Modules\Unity-Claude-IntelligentAlerting\Unity-Claude-IntelligentAlerting.psm1`
- **Size:** 21.6 KB
- **Last Modified:** 2025-08-30 13:44
- **Total Functions:** 14
- **Exported Functions:** 1


**Dependencies:**
- `$aiAlertPath` (external) - `$notificationPath` (external) - `$contentPath` (external) - `$changePath` (external) - `$optimizerPath` (external)


**Key Functions:**
- **Initialize-IntelligentAlerting** - Line 57 - **Connect-AvailableModules** - Line 90 - **Start-IntelligentAlerting** - Line 167 - **Start-AlertProcessingThread** - Line 193 - **Process-IntelligentAlert** - Line 262
- *...and 9 more functions*

--- 
### Unity-Claude-IntelligentDocumentationTriggers

[⬆ Back to Contents](#-table-of-contents)

Intelligent documentation module that provides automated documentation generation, quality assessment, and cross-referencing capabilities. Maintains live documentation that updates automatically as the codebase evolves. Unity Editor integration module providing direct communication with Unity processes. Handles compilation monitoring, error extraction, project management, and automated testing workflows. 

**Module Statistics:**
 - Functions: 21


**Module Information:**
- **Path:** `Modules\Unity-Claude-IntelligentDocumentationTriggers\Unity-Claude-IntelligentDocumentationTriggers.psm1`
- **Size:** 26.53 KB
- **Last Modified:** 2025-08-30 15:41
- **Total Functions:** 20
- **Exported Functions:** 1




**Key Functions:**
- **Initialize-IntelligentDocumentationTriggers** - Line 67 - **Get-DefaultIntelligentTriggersConfiguration** - Line 143 - **Evaluate-IntelligentTrigger** - Line 188 - **Analyze-ChangeImpact** - Line 275 - **Perform-ASTChangeAnalysis** - Line 349
- *...and 15 more functions*

--- 
### Unity-Claude-IPC

[⬆ Back to Contents](#-table-of-contents)

Unity Editor integration module providing direct communication with Unity processes. Handles compilation monitoring, error extraction, project management, and automated testing workflows.

**Module Statistics:**
- Functions: 9
- Dependencies: 1 modules


**Module Information:**
- **Path:** `Modules\Unity-Claude-IPC\Unity-Claude-IPC.psm1`
- **Size:** 14.76 KB
- **Last Modified:** 2025-08-20 17:25
- **Total Functions:** 9
- **Exported Functions:** 1


**Dependencies:**
- [`Unity-Claude-Core`](#unity-claude-core)


**Key Functions:**
- **Test-ClaudeAvailable** - Line 18 - **Invoke-ClaudeAnalysis** - Line 37 - **Send-ClaudePrompt** - Line 72 - **Build-ClaudePrompt** - Line 146 - **Start-BidirectionalPipe** - Line 180
- *...and 4 more functions*

--- 
### Unity-Claude-IPC-Bidirectional

[⬆ Back to Contents](#-table-of-contents)

Unity Editor integration module providing direct communication with Unity processes. Handles compilation monitoring, error extraction, project management, and automated testing workflows.

**Module Statistics:**
- Functions: 12


**Module Information:**
- **Path:** `Modules\Unity-Claude-IPC-Bidirectional\Unity-Claude-IPC-Bidirectional.psm1`
- **Size:** 20.33 KB
- **Last Modified:** 2025-08-20 17:25
- **Total Functions:** 12
- **Exported Functions:** 1




**Key Functions:**
- **Write-Log** - Line 6 - **Start-NamedPipeServer** - Line 29 - **Send-PipeMessage** - Line 173 - **Start-HttpApiServer** - Line 234 - **Start-HttpRequestHandler** - Line 305
- *...and 7 more functions*

--- 
### Unity-Claude-IPC-Bidirectional-Fixed

[⬆ Back to Contents](#-table-of-contents)

Unity Editor integration module providing direct communication with Unity processes. Handles compilation monitoring, error extraction, project management, and automated testing workflows.

**Module Statistics:**
- Functions: 12


**Module Information:**
- **Path:** `Modules\Unity-Claude-IPC-Bidirectional\Unity-Claude-IPC-Bidirectional-Fixed.psm1`
- **Size:** 20.33 KB
- **Last Modified:** 2025-08-20 17:25
- **Total Functions:** 12
- **Exported Functions:** 1




**Key Functions:**
- **Write-Log** - Line 6 - **Start-NamedPipeServer** - Line 29 - **Send-PipeMessage** - Line 173 - **Start-HttpApiServer** - Line 234 - **Start-HttpRequestHandler** - Line 305
- *...and 7 more functions*

--- 
### Unity-Claude-LangGraphBridge

[⬆ Back to Contents](#-table-of-contents)

Unity Editor integration module providing direct communication with Unity processes. Handles compilation monitoring, error extraction, project management, and automated testing workflows.

**Module Statistics:**
- Functions: 8


**Module Information:**
- **Path:** `Modules\Unity-Claude-AI-Integration\LangGraph\Unity-Claude-LangGraphBridge.psm1`
- **Size:** 11.73 KB
- **Last Modified:** 2025-08-29 15:17
- **Total Functions:** 8
- **Exported Functions:** 1




**Key Functions:**
- **New-LangGraphWorkflow** - Line 30 - **Submit-WorkflowTask** - Line 78 - **Get-WorkflowResult** - Line 127 - **Test-LangGraphServer** - Line 186 - **Get-LangGraphWorkflows** - Line 228
- *...and 3 more functions*

--- 
### Unity-Claude-Learning

[⬆ Back to Contents](#-table-of-contents)

Unity Editor integration module providing direct communication with Unity processes. Handles compilation monitoring, error extraction, project management, and automated testing workflows. Machine learning module that improves system performance over time. Tracks success patterns, identifies optimal configurations, and adapts behavior based on historical outcomes. 

**Module Statistics:**
 - Functions: 1
 - Dependencies: 1 modules


**Module Information:**
- **Path:** `Modules\Unity-Claude-Learning\Unity-Claude-Learning.psm1`
- **Size:** 7.32 KB
- **Last Modified:** 2025-08-26 11:46
- **Total Functions:** 0
- **Exported Functions:** 1


**Dependencies:**
- `$componentFullPath` (external)



--- 
### Unity-Claude-Learning-Analytics

[⬆ Back to Contents](#-table-of-contents)

Unity Editor integration module providing direct communication with Unity processes. Handles compilation monitoring, error extraction, project management, and automated testing workflows. Machine learning module that improves system performance over time. Tracks success patterns, identifies optimal configurations, and adapts behavior based on historical outcomes. 

**Module Statistics:**
 - Functions: 8
 - Dependencies: 1 modules


**Module Information:**
- **Path:** `Modules\Unity-Claude-Learning\Unity-Claude-Learning-Analytics.psm1`
- **Size:** 24.52 KB
- **Last Modified:** 2025-08-20 17:25
- **Total Functions:** 8
- **Exported Functions:** 1


**Dependencies:**
- `(Join-Path` (external)


**Key Functions:**
- **Get-PatternSuccessRate** - Line 7 - **Get-AllPatternsSuccessRates** - Line 83 - **Calculate-MovingAverage** - Line 127 - **Get-LearningTrend** - Line 175 - **Update-PatternConfidence** - Line 290
- *...and 3 more functions*

--- 
### Unity-Claude-Learning-Original

[⬆ Back to Contents](#-table-of-contents)

Unity Editor integration module providing direct communication with Unity processes. Handles compilation monitoring, error extraction, project management, and automated testing workflows. Machine learning module that improves system performance over time. Tracks success patterns, identifies optimal configurations, and adapts behavior based on historical outcomes. 

**Module Statistics:**
 - Functions: 27


**Module Information:**
- **Path:** `Modules\Unity-Claude-Learning\Unity-Claude-Learning-Original.psm1`
- **Size:** 79.5 KB
- **Last Modified:** 2025-08-26 11:46
- **Total Functions:** 26
- **Exported Functions:** 1




**Key Functions:**
- **Initialize-LearningDatabase** - Line 32 - **Get-StringSimilarity** - Line 181 - **Get-LevenshteinDistance** - Line 238 - **Get-ErrorSignature** - Line 296 - **Find-SimilarPatterns** - Line 348
- *...and 21 more functions*

--- 
### Unity-Claude-Learning-Refactored

[⬆ Back to Contents](#-table-of-contents)

Unity Editor integration module providing direct communication with Unity processes. Handles compilation monitoring, error extraction, project management, and automated testing workflows. Machine learning module that improves system performance over time. Tracks success patterns, identifies optimal configurations, and adapts behavior based on historical outcomes. 

**Module Statistics:**
 - Functions: 1
 - Dependencies: 1 modules


**Module Information:**
- **Path:** `Modules\Unity-Claude-Learning\Unity-Claude-Learning-Refactored.psm1`
- **Size:** 7.32 KB
- **Last Modified:** 2025-08-26 11:46
- **Total Functions:** 0
- **Exported Functions:** 1


**Dependencies:**
- `$componentFullPath` (external)



--- 
### Unity-Claude-Learning-Simple

[⬆ Back to Contents](#-table-of-contents)

Unity Editor integration module providing direct communication with Unity processes. Handles compilation monitoring, error extraction, project management, and automated testing workflows. Machine learning module that improves system performance over time. Tracks success patterns, identifies optimal configurations, and adapts behavior based on historical outcomes. 

**Module Statistics:**
 - Functions: 29


**Module Information:**
- **Path:** `Modules\Unity-Claude-Learning-Simple\Unity-Claude-Learning-Simple.psm1`
- **Size:** 53.76 KB
- **Last Modified:** 2025-08-20 17:25
- **Total Functions:** 25
- **Exported Functions:** 1




**Key Functions:**
- **Write-LearningLog** - Line 37 - **ConvertFrom-JsonToHashtable** - Line 94 - **Initialize-LearningStorage** - Line 134 - **Save-Patterns** - Line 219 - **Save-Metrics** - Line 238
- *...and 20 more functions*

--- 
### Unity-Claude-LLM

[⬆ Back to Contents](#-table-of-contents)

Unity Editor integration module providing direct communication with Unity processes. Handles compilation monitoring, error extraction, project management, and automated testing workflows.

**Module Statistics:**
- Functions: 10


**Module Information:**
- **Path:** `Modules\Unity-Claude-LLM\Unity-Claude-LLM.psm1`
- **Size:** 16 KB
- **Last Modified:** 2025-08-30 19:47
- **Total Functions:** 10
- **Exported Functions:** 1




**Key Functions:**
- **Test-OllamaConnection** - Line 25 - **Get-OllamaModels** - Line 48 - **Invoke-OllamaGenerate** - Line 71 - **New-DocumentationPrompt** - Line 124 - **Invoke-DocumentationGeneration** - Line 180
- *...and 5 more functions*

--- 
### Unity-Claude-MachineLearning

[⬆ Back to Contents](#-table-of-contents)

Unity Editor integration module providing direct communication with Unity processes. Handles compilation monitoring, error extraction, project management, and automated testing workflows. Machine learning module that improves system performance over time. Tracks success patterns, identifies optimal configurations, and adapts behavior based on historical outcomes. 

**Module Statistics:**
 - Functions: 25


**Module Information:**
- **Path:** `Modules\Unity-Claude-MachineLearning\Unity-Claude-MachineLearning.psm1`
- **Size:** 53.6 KB
- **Last Modified:** 2025-08-30 20:27
- **Total Functions:** 25
- **Exported Functions:** 1




**Key Functions:**
- **Initialize-MachineLearning** - Line 70 - **Initialize-PatternModels** - Line 159 - **Initialize-SyntheticTrainingData** - Line 211 - **Get-SyntheticClassification** - Line 267 - **Calculate-SyntheticPerformance** - Line 280
- *...and 20 more functions*

--- 
### Unity-Claude-MasterOrchestrator

[⬆ Back to Contents](#-table-of-contents)

Unity Editor integration module providing direct communication with Unity processes. Handles compilation monitoring, error extraction, project management, and automated testing workflows. Master orchestration module coordinating complex multi-step workflows. Manages module interactions, handles state transitions, and ensures proper sequencing of automated operations. 

**Module Statistics:**
 - Functions: 3
 - Dependencies: 1 modules


**Module Information:**
- **Path:** `Modules\Unity-Claude-MasterOrchestrator\Unity-Claude-MasterOrchestrator.psm1`
- **Size:** 11.45 KB
- **Last Modified:** 2025-08-26 11:46
- **Total Functions:** 3
- **Exported Functions:** 1


**Dependencies:**
- `$componentFile` (external)


**Key Functions:**
- **Initialize-MasterOrchestrator** - Line 60 - **Get-MasterOrchestratorStatus** - Line 114 - **Test-MasterOrchestratorIntegration** - Line 153


--- 
### Unity-Claude-MasterOrchestrator-Original

[⬆ Back to Contents](#-table-of-contents)

Unity Editor integration module providing direct communication with Unity processes. Handles compilation monitoring, error extraction, project management, and automated testing workflows. Master orchestration module coordinating complex multi-step workflows. Manages module interactions, handles state transitions, and ensures proper sequencing of automated operations. 

**Module Statistics:**
 - Functions: 38
 - Dependencies: 2 modules


**Module Information:**
- **Path:** `Modules\Unity-Claude-MasterOrchestrator\Unity-Claude-MasterOrchestrator-Original.psm1`
- **Size:** 46.06 KB
- **Last Modified:** 2025-08-26 11:46
- **Total Functions:** 34



**Dependencies:**
- `$path` (external) - `$ModuleName` (external)


**Key Functions:**
- **Write-OrchestratorLog** - Line 81 - **Test-ModuleAvailability** - Line 120 - **Initialize-ModuleIntegration** - Line 197 - **Initialize-SingleModule** - Line 285 - **Get-ModuleIntegrationPoints** - Line 341
- *...and 29 more functions*

--- 
### Unity-Claude-MasterOrchestrator-Refactored

[⬆ Back to Contents](#-table-of-contents)

Unity Editor integration module providing direct communication with Unity processes. Handles compilation monitoring, error extraction, project management, and automated testing workflows. Master orchestration module coordinating complex multi-step workflows. Manages module interactions, handles state transitions, and ensures proper sequencing of automated operations. 

**Module Statistics:**
 - Functions: 3
 - Dependencies: 1 modules


**Module Information:**
- **Path:** `Modules\Unity-Claude-MasterOrchestrator\Unity-Claude-MasterOrchestrator-Refactored.psm1`
- **Size:** 11.45 KB
- **Last Modified:** 2025-08-26 11:46
- **Total Functions:** 3
- **Exported Functions:** 1


**Dependencies:**
- `$componentFile` (external)


**Key Functions:**
- **Initialize-MasterOrchestrator** - Line 60 - **Get-MasterOrchestratorStatus** - Line 114 - **Test-MasterOrchestratorIntegration** - Line 153


--- 
### Unity-Claude-MemoryAnalysis

[⬆ Back to Contents](#-table-of-contents)

Unity Editor integration module providing direct communication with Unity processes. Handles compilation monitoring, error extraction, project management, and automated testing workflows.

**Module Statistics:**
- Functions: 6


**Module Information:**
- **Path:** `Modules\Unity-Claude-MemoryAnalysis.psm1`
- **Size:** 16.55 KB
- **Last Modified:** 2025-08-20 17:25
- **Total Functions:** 6
- **Exported Functions:** 1




**Key Functions:**
- **Start-UnityMemoryMonitoring** - Line 25 - **Process-MemoryDataFile** - Line 88 - **Analyze-MemoryData** - Line 126 - **Generate-AutonomousMemoryRecommendation** - Line 188 - **Get-UnityMemoryStatus** - Line 246
- *...and 1 more functions*

--- 
### Unity-Claude-MessageQueue

[⬆ Back to Contents](#-table-of-contents)

Unity Editor integration module providing direct communication with Unity processes. Handles compilation monitoring, error extraction, project management, and automated testing workflows.

**Module Statistics:**
- Functions: 10


**Module Information:**
- **Path:** `Modules\Unity-Claude-MessageQueue\Unity-Claude-MessageQueue.psm1`
- **Size:** 18.19 KB
- **Last Modified:** 2025-08-24 12:06
- **Total Functions:** 10
- **Exported Functions:** 1




**Key Functions:**
- **Initialize-MessageQueue** - Line 22 - **Add-MessageToQueue** - Line 49 - **Get-MessageFromQueue** - Line 99 - **Register-FileSystemWatcher** - Line 147 - **Initialize-CircuitBreaker** - Line 247
- *...and 5 more functions*

--- 
### Unity-Claude-Monitoring

[⬆ Back to Contents](#-table-of-contents)

Real-time monitoring module tracking system health, performance metrics, and Unity compilation status. Provides event-driven notifications and triggers automated responses to detected issues. Unity Editor integration module providing direct communication with Unity processes. Handles compilation monitoring, error extraction, project management, and automated testing workflows. 

**Module Statistics:**
 - Functions: 12


**Module Information:**
- **Path:** `Modules\Unity-Claude-Monitoring\Unity-Claude-Monitoring.psm1`
- **Size:** 20.05 KB
- **Last Modified:** 2025-08-24 12:06
- **Total Functions:** 12
- **Exported Functions:** 1




**Key Functions:**
- **Get-ServiceHealth** - Line 34 - **Test-ServiceLiveness** - Line 95 - **Test-ServiceReadiness** - Line 125 - **Get-PrometheusMetrics** - Line 168 - **Get-ContainerMetrics** - Line 230
- *...and 7 more functions*

--- 
### Unity-Claude-MultiStepOrchestrator

[⬆ Back to Contents](#-table-of-contents)

Unity Editor integration module providing direct communication with Unity processes. Handles compilation monitoring, error extraction, project management, and automated testing workflows. Master orchestration module coordinating complex multi-step workflows. Manages module interactions, handles state transitions, and ensures proper sequencing of automated operations. 

**Module Statistics:**
 - Functions: 12


**Module Information:**
- **Path:** `Modules\Unity-Claude-AI-Integration\LangGraph\Unity-Claude-MultiStepOrchestrator.psm1`
- **Size:** 30.34 KB
- **Last Modified:** 2025-08-29 15:48
- **Total Functions:** 12
- **Exported Functions:** 1




**Key Functions:**
- **Invoke-MultiStepAnalysisOrchestration** - Line 39 - **Initialize-OrchestrationContext** - Line 131 - **Invoke-ParallelAnalysisWorkers** - Line 158 - **Receive-ParallelWorkerResults** - Line 264 - **Invoke-AIEnhancementWorker** - Line 308
- *...and 7 more functions*

--- 
### Unity-Claude-NotificationConfiguration

[⬆ Back to Contents](#-table-of-contents)

Unity Editor integration module providing direct communication with Unity processes. Handles compilation monitoring, error extraction, project management, and automated testing workflows.

**Module Statistics:**
- Functions: 0


**Module Information:**
- **Path:** `Modules\Unity-Claude-NotificationConfiguration\Unity-Claude-NotificationConfiguration.psm1`
- **Size:** 4.43 KB
- **Last Modified:** 2025-08-24 12:06
- **Total Functions:** 0
- **Exported Functions:** 1





--- 
### Unity-Claude-NotificationContentEngine

[⬆ Back to Contents](#-table-of-contents)

Unity Editor integration module providing direct communication with Unity processes. Handles compilation monitoring, error extraction, project management, and automated testing workflows.

**Module Statistics:**
- Functions: 37


**Module Information:**
- **Path:** `Modules\Unity-Claude-NotificationContentEngine\Unity-Claude-NotificationContentEngine.psm1`
- **Size:** 50.83 KB
- **Last Modified:** 2025-08-21 17:45
- **Total Functions:** 35
- **Exported Functions:** 1




**Key Functions:**
- **New-UnifiedNotificationTemplate** - Line 48 - **Set-NotificationTemplate** - Line 103 - **Get-NotificationTemplate** - Line 167 - **Test-NotificationTemplate** - Line 196 - **Remove-NotificationTemplate** - Line 251
- *...and 30 more functions*

--- 
### Unity-Claude-NotificationIntegration

[⬆ Back to Contents](#-table-of-contents)

Unity Editor integration module providing direct communication with Unity processes. Handles compilation monitoring, error extraction, project management, and automated testing workflows.

**Module Statistics:**
- Functions: 22
- Dependencies: 4 modules


**Module Information:**
- **Path:** `Modules\Unity-Claude-NotificationIntegration\Unity-Claude-NotificationIntegration.psm1`
- **Size:** 47.5 KB
- **Last Modified:** 2025-08-30 14:29
- **Total Functions:** 20
- **Exported Functions:** 1


**Dependencies:**
- [`Unity-Claude-EmailNotifications`](#unity-claude-emailnotifications) - [`Unity-Claude-WebhookNotifications`](#unity-claude-webhooknotifications) - [`Unity-Claude-NotificationContentEngine`](#unity-claude-notificationcontentengine) - [`Unity-Claude-SystemStatus`](#unity-claude-systemstatus)


**Key Functions:**
- **Send-NotificationMultiChannel** - Line 174 - **Get-DeliveryChannelsForAlert** - Line 259 - **New-NotificationContent** - Line 306 - **Send-ChannelNotification** - Line 400 - **Send-SlackNotificationEnhanced** - Line 471
- *...and 15 more functions*

--- 
### Unity-Claude-NotificationIntegration-Modular

[⬆ Back to Contents](#-table-of-contents)

Unity Editor integration module providing direct communication with Unity processes. Handles compilation monitoring, error extraction, project management, and automated testing workflows.

**Module Statistics:**
- Functions: 3


**Module Information:**
- **Path:** `Modules\Unity-Claude-NotificationIntegration\Unity-Claude-NotificationIntegration-Modular.psm1`
- **Size:** 13.61 KB
- **Last Modified:** 2025-08-21 17:45
- **Total Functions:** 3
- **Exported Functions:** 1




**Key Functions:**
- **Get-NotificationState** - Line 69 - **Set-NotificationState** - Line 127 - **Update-NotificationMetrics** - Line 186


--- 
### Unity-Claude-NotificationPreferences

[⬆ Back to Contents](#-table-of-contents)

Unity Editor integration module providing direct communication with Unity processes. Handles compilation monitoring, error extraction, project management, and automated testing workflows.

**Module Statistics:**
- Functions: 24


**Module Information:**
- **Path:** `Modules\Unity-Claude-NotificationPreferences\Unity-Claude-NotificationPreferences.psm1`
- **Size:** 37.57 KB
- **Last Modified:** 2025-08-30 14:35
- **Total Functions:** 24
- **Exported Functions:** 1




**Key Functions:**
- **Initialize-NotificationPreferences** - Line 54 - **Load-NotificationPreferences** - Line 125 - **Load-DeliveryRules** - Line 160 - **Load-TagDefinitions** - Line 195 - **Get-DefaultNotificationPreferences** - Line 230
- *...and 19 more functions*

--- 
### Unity-Claude-ObsolescenceDetection

[⬆ Back to Contents](#-table-of-contents)

Unity Editor integration module providing direct communication with Unity processes. Handles compilation monitoring, error extraction, project management, and automated testing workflows.

**Module Statistics:**
- Functions: 6
- Dependencies: 1 modules


**Module Information:**
- **Path:** `Modules\Unity-Claude-CPG\Unity-Claude-ObsolescenceDetection.psm1`
- **Size:** 22.22 KB
- **Last Modified:** 2025-08-26 11:46
- **Total Functions:** 5
- **Exported Functions:** 1


**Dependencies:**
- `$componentPath` (external)


**Key Functions:**
- **Get-ObsolescenceDetectionComponents** - Line 134 - **Test-ObsolescenceDetectionHealth** - Line 187 - **Invoke-ComprehensiveObsolescenceAnalysis** - Line 308 - **Generate-AnalysisSummary** - Line 432 - **Generate-ObsolescenceActionPlan** - Line 469


--- 
### Unity-Claude-ObsolescenceDetection-Refactored

[⬆ Back to Contents](#-table-of-contents)

Unity Editor integration module providing direct communication with Unity processes. Handles compilation monitoring, error extraction, project management, and automated testing workflows.

**Module Statistics:**
- Functions: 6
- Dependencies: 1 modules


**Module Information:**
- **Path:** `Modules\Unity-Claude-CPG\Unity-Claude-ObsolescenceDetection-Refactored.psm1`
- **Size:** 22.22 KB
- **Last Modified:** 2025-08-26 11:46
- **Total Functions:** 5
- **Exported Functions:** 1


**Dependencies:**
- `$componentPath` (external)


**Key Functions:**
- **Get-ObsolescenceDetectionComponents** - Line 134 - **Test-ObsolescenceDetectionHealth** - Line 187 - **Invoke-ComprehensiveObsolescenceAnalysis** - Line 308 - **Generate-AnalysisSummary** - Line 432 - **Generate-ObsolescenceActionPlan** - Line 469


--- 
### Unity-Claude-Ollama

[⬆ Back to Contents](#-table-of-contents)

Unity Editor integration module providing direct communication with Unity processes. Handles compilation monitoring, error extraction, project management, and automated testing workflows.

**Module Statistics:**
- Functions: 15


**Module Information:**
- **Path:** `Modules\Unity-Claude-AI-Integration\Ollama\Unity-Claude-Ollama.psm1`
- **Size:** 34.17 KB
- **Last Modified:** 2025-08-30 19:47
- **Total Functions:** 13
- **Exported Functions:** 1




**Key Functions:**
- **Start-OllamaService** - Line 42 - **Stop-OllamaService** - Line 98 - **Test-OllamaConnectivity** - Line 147 - **Get-OllamaModelInfo** - Line 218 - **Set-OllamaConfiguration** - Line 273
- *...and 8 more functions*

--- 
### Unity-Claude-Ollama-Enhanced

[⬆ Back to Contents](#-table-of-contents)

Unity Editor integration module providing direct communication with Unity processes. Handles compilation monitoring, error extraction, project management, and automated testing workflows.

**Module Statistics:**
- Functions: 13
- Dependencies: 2 modules


**Module Information:**
- **Path:** `Modules\Unity-Claude-AI-Integration\Ollama\Unity-Claude-Ollama-Enhanced.psm1`
- **Size:** 26.84 KB
- **Last Modified:** 2025-08-30 19:47
- **Total Functions:** 13
- **Exported Functions:** 1


**Dependencies:**
- `powershai` (external) - `.\Unity-Claude-Ollama.psm1` (external)


**Key Functions:**
- **Initialize-PowershAI** - Line 42 - **Invoke-PowershAIDocumentation** - Line 106 - **Start-IntelligentDocumentationPipeline** - Line 176 - **Add-DocumentationRequest** - Line 235 - **Get-DocumentationQualityAssessment** - Line 298
- *...and 8 more functions*

--- 
### Unity-Claude-Ollama-Optimized

[⬆ Back to Contents](#-table-of-contents)

Unity Editor integration module providing direct communication with Unity processes. Handles compilation monitoring, error extraction, project management, and automated testing workflows.

**Module Statistics:**
- Functions: 8
- Dependencies: 2 modules


**Module Information:**
- **Path:** `Modules\Unity-Claude-AI-Integration\Ollama\Unity-Claude-Ollama-Optimized.psm1`
- **Size:** 27.37 KB
- **Last Modified:** 2025-08-30 19:47
- **Total Functions:** 6
- **Exported Functions:** 1


**Dependencies:**
- `$using:PSScriptRoot\Unity-Claude-Ollama-Optimized.psm1` (external) - `$scriptPath` (external)


**Key Functions:**
- **Get-OptimalContextWindow** - Line 89 - **Optimize-OllamaConfiguration** - Line 146 - **Start-OllamaBatchProcessing** - Line 216 - **Invoke-OllamaOptimizedRequest** - Line 369 - **Format-OptimizedPrompt** - Line 453
- *...and 1 more functions*

--- 
### Unity-Claude-Ollama-Optimized-Fixed

[⬆ Back to Contents](#-table-of-contents)

Unity Editor integration module providing direct communication with Unity processes. Handles compilation monitoring, error extraction, project management, and automated testing workflows.

**Module Statistics:**
- Functions: 9
- Dependencies: 1 modules


**Module Information:**
- **Path:** `Modules\Unity-Claude-AI-Integration\Ollama\Unity-Claude-Ollama-Optimized-Fixed.psm1`
- **Size:** 35.32 KB
- **Last Modified:** 2025-08-30 19:47
- **Total Functions:** 6
- **Exported Functions:** 1


**Dependencies:**
- `in` (external)


**Key Functions:**
- **Get-OptimalContextWindow** - Line 90 - **Optimize-OllamaConfiguration** - Line 147 - **Start-OllamaBatchProcessing** - Line 240 - **Invoke-OllamaOptimizedRequest** - Line 478 - **Format-OptimizedPrompt** - Line 562
- *...and 1 more functions*

--- 
### Unity-Claude-ParallelProcessing

[⬆ Back to Contents](#-table-of-contents)

High-performance parallel processing module designed to maximize throughput and system utilization. Implements thread-safe operations, runspace management, and concurrent execution patterns to handle multiple Unity operations simultaneously without blocking. Unity Editor integration module providing direct communication with Unity processes. Handles compilation monitoring, error extraction, project management, and automated testing workflows. 

**Module Statistics:**
 - Functions: 19
 - Dependencies: 1 modules


**Module Information:**
- **Path:** `Modules\Unity-Claude-ParallelProcessing\Unity-Claude-ParallelProcessing.psm1`
- **Size:** 40.62 KB
- **Last Modified:** 2025-08-21 17:45
- **Total Functions:** 18
- **Exported Functions:** 1


**Dependencies:**
- `$AgentLoggingPath` (external)


**Key Functions:**
- **Write-AgentLog** - Line 9 - **New-SynchronizedHashtable** - Line 62 - **Get-SynchronizedValue** - Line 108 - **Set-SynchronizedValue** - Line 165 - **Remove-SynchronizedValue** - Line 219
- *...and 13 more functions*

--- 
### Unity-Claude-ParallelProcessor

[⬆ Back to Contents](#-table-of-contents)

High-performance parallel processing module designed to maximize throughput and system utilization. Implements thread-safe operations, runspace management, and concurrent execution patterns to handle multiple Unity operations simultaneously without blocking. Unity Editor integration module providing direct communication with Unity processes. Handles compilation monitoring, error extraction, project management, and automated testing workflows. 

**Module Statistics:**
 - Functions: 1
 - Dependencies: 6 modules


**Module Information:**
- **Path:** `Modules\Unity-Claude-ParallelProcessor\Unity-Claude-ParallelProcessor.psm1`
- **Size:** 10.43 KB
- **Last Modified:** 2025-08-26 11:46
- **Total Functions:** 1
- **Exported Functions:** 2


**Dependencies:**
- `$ComponentPath\ParallelProcessorCore.psm1` (external) - `$ComponentPath\RunspacePoolManager.psm1` (external) - `$ComponentPath\StatisticsTracker.psm1` (external) - `$ComponentPath\JobScheduler.psm1` (external) - `$ComponentPath\BatchProcessingEngine.psm1` (external) - `$ComponentPath\ModuleFunctions.psm1` (external)


**Key Functions:**
- **Get-UnityClaudeParallelProcessorInfo** - Line 117


--- 
### Unity-Claude-ParallelProcessor-Original

[⬆ Back to Contents](#-table-of-contents)

High-performance parallel processing module designed to maximize throughput and system utilization. Implements thread-safe operations, runspace management, and concurrent execution patterns to handle multiple Unity operations simultaneously without blocking. Unity Editor integration module providing direct communication with Unity processes. Handles compilation monitoring, error extraction, project management, and automated testing workflows. 

**Module Statistics:**
 - Functions: 5
 - Classes: 2


**Module Information:**
- **Path:** `Modules\Unity-Claude-ParallelProcessor\Unity-Claude-ParallelProcessor-Original.psm1`
- **Size:** 32.43 KB
- **Last Modified:** 2025-08-26 12:30
- **Total Functions:** 35
- **Exported Functions:** 1




**Key Functions:**
- **ParallelProcessor** - Line 41 - **ParallelProcessor** - Line 45 - **ParallelProcessor** - Line 49 - **Initialize** - Line 53 - **CalculateOptimalThreads** - Line 98
- *...and 30 more functions*

--- 
### Unity-Claude-ParallelProcessor-Refactored

[⬆ Back to Contents](#-table-of-contents)

High-performance parallel processing module designed to maximize throughput and system utilization. Implements thread-safe operations, runspace management, and concurrent execution patterns to handle multiple Unity operations simultaneously without blocking. Unity Editor integration module providing direct communication with Unity processes. Handles compilation monitoring, error extraction, project management, and automated testing workflows. 

**Module Statistics:**
 - Functions: 1
 - Dependencies: 6 modules


**Module Information:**
- **Path:** `Modules\Unity-Claude-ParallelProcessor\Unity-Claude-ParallelProcessor-Refactored.psm1`
- **Size:** 10.43 KB
- **Last Modified:** 2025-08-26 11:46
- **Total Functions:** 1
- **Exported Functions:** 2


**Dependencies:**
- `$ComponentPath\ParallelProcessorCore.psm1` (external) - `$ComponentPath\RunspacePoolManager.psm1` (external) - `$ComponentPath\StatisticsTracker.psm1` (external) - `$ComponentPath\JobScheduler.psm1` (external) - `$ComponentPath\BatchProcessingEngine.psm1` (external) - `$ComponentPath\ModuleFunctions.psm1` (external)


**Key Functions:**
- **Get-UnityClaudeParallelProcessorInfo** - Line 117


--- 
### Unity-Claude-PerformanceOptimizer

[⬆ Back to Contents](#-table-of-contents)

Unity Editor integration module providing direct communication with Unity processes. Handles compilation monitoring, error extraction, project management, and automated testing workflows.

**Module Statistics:**
- Functions: 9
- Classes: 1
- Dependencies: 10 modules


**Module Information:**
- **Path:** `Modules\Unity-Claude-PerformanceOptimizer\Unity-Claude-PerformanceOptimizer.psm1`
- **Size:** 19.43 KB
- **Last Modified:** 2025-08-26 11:46
- **Total Functions:** 22
- **Exported Functions:** 1


**Dependencies:**
- [`Unity-Claude-Cache`](#unity-claude-cache) - [`Unity-Claude-IncrementalProcessor`](#unity-claude-incrementalprocessor) - [`Unity-Claude-ParallelProcessor`](#unity-claude-parallelprocessor) - [`Unity-Claude-CPG`](#unity-claude-cpg) - `$PSScriptRoot\Core\OptimizerConfiguration.psm1` (external) - `$PSScriptRoot\Core\FileSystemMonitoring.psm1` (external) - `$PSScriptRoot\Core\PerformanceMonitoring.psm1` (external) - `$PSScriptRoot\Core\PerformanceOptimization.psm1` (external) - `$PSScriptRoot\Core\FileProcessing.psm1` (external) - `$PSScriptRoot\Core\ReportingExport.psm1` (external)


**Key Functions:**
- **PerformanceOptimizer** - Line 46 - **InitializeComponents** - Line 65 - **Start** - Line 72 - **Stop** - Line 103 - **StartFileWatcher** - Line 147
- *...and 17 more functions*

--- 
### Unity-Claude-PerformanceOptimizer-Original

[⬆ Back to Contents](#-table-of-contents)

Unity Editor integration module providing direct communication with Unity processes. Handles compilation monitoring, error extraction, project management, and automated testing workflows.

**Module Statistics:**
- Functions: 7
- Classes: 1
- Dependencies: 4 modules


**Module Information:**
- **Path:** `Modules\Unity-Claude-PerformanceOptimizer\Unity-Claude-PerformanceOptimizer-Original.psm1`
- **Size:** 34.33 KB
- **Last Modified:** 2025-08-26 11:46
- **Total Functions:** 34
- **Exported Functions:** 1


**Dependencies:**
- [`Unity-Claude-Cache`](#unity-claude-cache) - [`Unity-Claude-IncrementalProcessor`](#unity-claude-incrementalprocessor) - [`Unity-Claude-ParallelProcessor`](#unity-claude-parallelprocessor) - [`Unity-Claude-CPG`](#unity-claude-cpg)


**Key Functions:**
- **PerformanceOptimizer** - Line 64 - **InitializeComponents** - Line 94 - **CalculateOptimalThreadCount** - Line 129 - **Start** - Line 143 - **Stop** - Line 174
- *...and 29 more functions*

--- 
### Unity-Claude-PerformanceOptimizer-Refactored

[⬆ Back to Contents](#-table-of-contents)

Unity Editor integration module providing direct communication with Unity processes. Handles compilation monitoring, error extraction, project management, and automated testing workflows.

**Module Statistics:**
- Functions: 9
- Classes: 1
- Dependencies: 10 modules


**Module Information:**
- **Path:** `Modules\Unity-Claude-PerformanceOptimizer\Unity-Claude-PerformanceOptimizer-Refactored.psm1`
- **Size:** 19.43 KB
- **Last Modified:** 2025-08-26 11:46
- **Total Functions:** 22
- **Exported Functions:** 1


**Dependencies:**
- [`Unity-Claude-Cache`](#unity-claude-cache) - [`Unity-Claude-IncrementalProcessor`](#unity-claude-incrementalprocessor) - [`Unity-Claude-ParallelProcessor`](#unity-claude-parallelprocessor) - [`Unity-Claude-CPG`](#unity-claude-cpg) - `$PSScriptRoot\Core\OptimizerConfiguration.psm1` (external) - `$PSScriptRoot\Core\FileSystemMonitoring.psm1` (external) - `$PSScriptRoot\Core\PerformanceMonitoring.psm1` (external) - `$PSScriptRoot\Core\PerformanceOptimization.psm1` (external) - `$PSScriptRoot\Core\FileProcessing.psm1` (external) - `$PSScriptRoot\Core\ReportingExport.psm1` (external)


**Key Functions:**
- **PerformanceOptimizer** - Line 46 - **InitializeComponents** - Line 65 - **Start** - Line 72 - **Stop** - Line 103 - **StartFileWatcher** - Line 147
- *...and 17 more functions*

--- 
### Unity-Claude-PredictiveAnalysis

[⬆ Back to Contents](#-table-of-contents)

Unity Editor integration module providing direct communication with Unity processes. Handles compilation monitoring, error extraction, project management, and automated testing workflows.

**Module Statistics:**
- Functions: 4
- Dependencies: 1 modules


**Module Information:**
- **Path:** `Modules\Unity-Claude-PredictiveAnalysis\Unity-Claude-PredictiveAnalysis.psm1`
- **Size:** 18.66 KB
- **Last Modified:** 2025-08-26 11:46
- **Total Functions:** 4
- **Exported Functions:** 5


**Dependencies:**
- `$ComponentFile` (external)


**Key Functions:**
- **Initialize-PredictiveAnalysis** - Line 92 - **Get-ComprehensiveAnalysis** - Line 171 - **Calculate-OverallRisk** - Line 278 - **Get-TopPriorities** - Line 338


--- 
### Unity-Claude-PredictiveAnalysis-Original

[⬆ Back to Contents](#-table-of-contents)

Unity Editor integration module providing direct communication with Unity processes. Handles compilation monitoring, error extraction, project management, and automated testing workflows.

**Module Statistics:**
- Functions: 30
- Classes: 3


**Module Information:**
- **Path:** `Modules\Unity-Claude-PredictiveAnalysis\Unity-Claude-PredictiveAnalysis-Original.psm1`
- **Size:** 74.37 KB
- **Last Modified:** 2025-08-25 13:45
- **Total Functions:** 28
- **Exported Functions:** 5




**Key Functions:**
- **Initialize-PredictiveCache** - Line 17 - **Get-CodeEvolutionTrend** - Line 73 - **Measure-CodeChurn** - Line 203 - **Get-HotspotAnalysis** - Line 255 - **Get-MaintenancePrediction** - Line 335
- *...and 23 more functions*

--- 
### Unity-Claude-PredictiveAnalysis-Refactored

[⬆ Back to Contents](#-table-of-contents)

Unity Editor integration module providing direct communication with Unity processes. Handles compilation monitoring, error extraction, project management, and automated testing workflows.

**Module Statistics:**
- Functions: 4
- Dependencies: 1 modules


**Module Information:**
- **Path:** `Modules\Unity-Claude-PredictiveAnalysis\Unity-Claude-PredictiveAnalysis-Refactored.psm1`
- **Size:** 18.66 KB
- **Last Modified:** 2025-08-26 11:46
- **Total Functions:** 4
- **Exported Functions:** 5


**Dependencies:**
- `$ComponentFile` (external)


**Key Functions:**
- **Initialize-PredictiveAnalysis** - Line 92 - **Get-ComprehensiveAnalysis** - Line 171 - **Calculate-OverallRisk** - Line 278 - **Get-TopPriorities** - Line 338


--- 
### Unity-Claude-ProactiveMaintenanceEngine

[⬆ Back to Contents](#-table-of-contents)

Artificial Intelligence integration module that bridges PowerShell automation with AI services. Provides intelligent error analysis, pattern recognition, and automated decision-making capabilities through Claude AI or local LLM integration. Unity Editor integration module providing direct communication with Unity processes. Handles compilation monitoring, error extraction, project management, and automated testing workflows. 

**Module Statistics:**
 - Functions: 22
 - Dependencies: 5 modules


**Module Information:**
- **Path:** `Modules\Unity-Claude-ProactiveMaintenanceEngine\Unity-Claude-ProactiveMaintenanceEngine.psm1`
- **Size:** 33.33 KB
- **Last Modified:** 2025-08-30 14:11
- **Total Functions:** 22
- **Exported Functions:** 1


**Dependencies:**
- `$predictivePath` (external) - `$monitoringPath` (external) - `$changePath` (external) - `$alertPath` (external) - `$notificationPath` (external)


**Key Functions:**
- **Initialize-ProactiveMaintenanceEngine** - Line 90 - **Connect-MaintenanceModules** - Line 123 - **Initialize-RecommendationEngine** - Line 200 - **Initialize-TrendAnalyzer** - Line 227 - **Initialize-EarlyWarningSystem** - Line 246
- *...and 17 more functions*

--- 
### Unity-Claude-RealTimeAnalysis

[⬆ Back to Contents](#-table-of-contents)

Unity Editor integration module providing direct communication with Unity processes. Handles compilation monitoring, error extraction, project management, and automated testing workflows.

**Module Statistics:**
- Functions: 16
- Dependencies: 4 modules


**Module Information:**
- **Path:** `Modules\Unity-Claude-RealTimeAnalysis\Unity-Claude-RealTimeAnalysis.psm1`
- **Size:** 22.22 KB
- **Last Modified:** 2025-08-30 12:38
- **Total Functions:** 15
- **Exported Functions:** 1


**Dependencies:**
- `$monitoringPath` (external) - `$intelligencePath` (external) - `$fullPath` (external) - `$fullPath` (external)


**Key Functions:**
- **Initialize-RealTimeAnalysisPipeline** - Line 63 - **Discover-ExistingModules** - Line 99 - **Start-RealTimeAnalysisPipeline** - Line 182 - **Start-FileSystemMonitoringIntegration** - Line 224 - **Add-FileChangeToAnalysisQueue** - Line 256
- *...and 10 more functions*

--- 
### Unity-Claude-RealTimeMonitoring

[⬆ Back to Contents](#-table-of-contents)

Real-time monitoring module tracking system health, performance metrics, and Unity compilation status. Provides event-driven notifications and triggers automated responses to detected issues. Unity Editor integration module providing direct communication with Unity processes. Handles compilation monitoring, error extraction, project management, and automated testing workflows. 

**Module Statistics:**
 - Functions: 12


**Module Information:**
- **Path:** `Modules\Unity-Claude-RealTimeMonitoring\Unity-Claude-RealTimeMonitoring.psm1`
- **Size:** 17.14 KB
- **Last Modified:** 2025-08-30 12:13
- **Total Functions:** 12
- **Exported Functions:** 1




**Key Functions:**
- **Initialize-RealTimeMonitoring** - Line 42 - **Start-FileSystemMonitoring** - Line 81 - **Register-FileSystemEventHandlers** - Line 169 - **Add-EventToQueue** - Line 229 - **Start-EventProcessingThread** - Line 258
- *...and 7 more functions*

--- 
### Unity-Claude-RealTimeOptimizer

[⬆ Back to Contents](#-table-of-contents)

Unity Editor integration module providing direct communication with Unity processes. Handles compilation monitoring, error extraction, project management, and automated testing workflows.

**Module Statistics:**
- Functions: 22


**Module Information:**
- **Path:** `Modules\Unity-Claude-RealTimeOptimizer\Unity-Claude-RealTimeOptimizer.psm1`
- **Size:** 26.14 KB
- **Last Modified:** 2025-08-30 13:10
- **Total Functions:** 22
- **Exported Functions:** 1




**Key Functions:**
- **Initialize-RealTimeOptimizer** - Line 76 - **Set-RTOptimizationMode** - Line 109 - **Initialize-RTResourceMonitor** - Line 142 - **Initialize-RTThrottleController** - Line 176 - **Initialize-RTMemoryManager** - Line 192
- *...and 17 more functions*

--- 
### Unity-Claude-RecompileSignaling

[⬆ Back to Contents](#-table-of-contents)

Unity Editor integration module providing direct communication with Unity processes. Handles compilation monitoring, error extraction, project management, and automated testing workflows.

**Module Statistics:**
- Functions: 4


**Module Information:**
- **Path:** `Modules\Unity-Claude-RecompileSignaling.psm1`
- **Size:** 11.62 KB
- **Last Modified:** 2025-08-20 17:25
- **Total Functions:** 4
- **Exported Functions:** 1




**Key Functions:**
- **Switch-ToUnityWindow** - Line 30 - **Process-RecompileSignal** - Line 86 - **Start-RecompileSignalMonitoring** - Line 153 - **Stop-RecompileSignalMonitoring** - Line 214


--- 
### Unity-Claude-ReliabilityManager

[⬆ Back to Contents](#-table-of-contents)

Unity Editor integration module providing direct communication with Unity processes. Handles compilation monitoring, error extraction, project management, and automated testing workflows.

**Module Statistics:**
- Functions: 20


**Module Information:**
- **Path:** `Modules\Unity-Claude-ReliabilityManager\Unity-Claude-ReliabilityManager.psm1`
- **Size:** 43.51 KB
- **Last Modified:** 2025-08-30 20:35
- **Total Functions:** 20
- **Exported Functions:** 1




**Key Functions:**
- **Initialize-ReliabilityManager** - Line 84 - **Initialize-FaultToleranceSystem** - Line 165 - **Initialize-BackupRecoverySystem** - Line 213 - **Initialize-HealthMonitoringSystem** - Line 278 - **Initialize-GracefulDegradationSystem** - Line 352
- *...and 15 more functions*

--- 
### Unity-Claude-ReliableMonitoring

[⬆ Back to Contents](#-table-of-contents)

Real-time monitoring module tracking system health, performance metrics, and Unity compilation status. Provides event-driven notifications and triggers automated responses to detected issues. Unity Editor integration module providing direct communication with Unity processes. Handles compilation monitoring, error extraction, project management, and automated testing workflows. 

**Module Statistics:**
 - Functions: 12


**Module Information:**
- **Path:** `Modules\Unity-Claude-ReliableMonitoring.psm1`
- **Size:** 16.66 KB
- **Last Modified:** 2025-08-20 17:25
- **Total Functions:** 10
- **Exported Functions:** 1




**Key Functions:**
- **Read-SafeJsonFile** - Line 39 - **Test-ErrorFileChanged** - Line 77 - **Process-UnityErrors** - Line 116 - **Start-FileWatcher** - Line 171 - **Stop-FileWatcher** - Line 221
- *...and 5 more functions*

--- 
### Unity-Claude-RepoAnalyst

[⬆ Back to Contents](#-table-of-contents)

Unity Editor integration module providing direct communication with Unity processes. Handles compilation monitoring, error extraction, project management, and automated testing workflows.

**Module Statistics:**
- Functions: 21


**Module Information:**
- **Path:** `Modules\Unity-Claude-RepoAnalyst\Unity-Claude-RepoAnalyst.psm1`
- **Size:** 13.83 KB
- **Last Modified:** 2025-08-24 12:06
- **Total Functions:** 20
- **Exported Functions:** 1




**Key Functions:**
- **Initialize-RepoAnalystLogging** - Line 32 - **Write-RepoAnalystLog** - Line 47 - **Initialize-RepoAnalyst** - Line 83 - **Invoke-RipgrepSearch** - Line 110 - **New-CodeGraph** - Line 161
- *...and 15 more functions*

--- 
### Unity-Claude-ResourceOptimizer

[⬆ Back to Contents](#-table-of-contents)

Unity Editor integration module providing direct communication with Unity processes. Handles compilation monitoring, error extraction, project management, and automated testing workflows.

**Module Statistics:**
- Functions: 12


**Module Information:**
- **Path:** `Modules\Unity-Claude-ResourceOptimizer.psm1`
- **Size:** 33.53 KB
- **Last Modified:** 2025-08-20 17:25
- **Total Functions:** 12
- **Exported Functions:** 1




**Key Functions:**
- **Write-ResourceLog** - Line 91 - **Get-ResourceTimestamp** - Line 123 - **ConvertTo-HumanReadableSize** - Line 127 - **Get-MemoryUsage** - Line 146 - **Invoke-MemoryMonitoring** - Line 187
- *...and 7 more functions*

--- 
### Unity-Claude-ResponseMonitor

[⬆ Back to Contents](#-table-of-contents)

Real-time monitoring module tracking system health, performance metrics, and Unity compilation status. Provides event-driven notifications and triggers automated responses to detected issues. Unity Editor integration module providing direct communication with Unity processes. Handles compilation monitoring, error extraction, project management, and automated testing workflows. 

**Module Statistics:**
 - Functions: 24
 - Dependencies: 1 modules


**Module Information:**
- **Path:** `Modules\Unity-Claude-ResponseMonitor\Unity-Claude-ResponseMonitor.psm1`
- **Size:** 28.94 KB
- **Last Modified:** 2025-08-20 17:25
- **Total Functions:** 24



**Dependencies:**
- [`ConversationStateManager`](#conversationstatemanager)


**Key Functions:**
- **Write-ResponseMonitorLog** - Line 34 - **Test-RequiredModule** - Line 73 - **Get-ResponseMonitorConfig** - Line 92 - **Set-ResponseMonitorConfig** - Line 100 - **Initialize-FileSystemWatcher** - Line 162
- *...and 19 more functions*

--- 
### Unity-Claude-ResponseMonitoring

[⬆ Back to Contents](#-table-of-contents)

Real-time monitoring module tracking system health, performance metrics, and Unity compilation status. Provides event-driven notifications and triggers automated responses to detected issues. Unity Editor integration module providing direct communication with Unity processes. Handles compilation monitoring, error extraction, project management, and automated testing workflows. 

**Module Statistics:**
 - Functions: 13


**Module Information:**
- **Path:** `Modules\Unity-Claude-ResponseMonitoring.psm1`
- **Size:** 18 KB
- **Last Modified:** 2025-08-20 17:25
- **Total Functions:** 11
- **Exported Functions:** 1




**Key Functions:**
- **Read-SafeResponseFile** - Line 37 - **Test-ResponseFileChanged** - Line 80 - **Process-ClaudeResponse** - Line 117 - **Start-ResponseFileWatcher** - Line 175 - **Stop-ResponseFileWatcher** - Line 224
- *...and 6 more functions*

--- 
### Unity-Claude-RunspaceManagement

[⬆ Back to Contents](#-table-of-contents)

Unity Editor integration module providing direct communication with Unity processes. Handles compilation monitoring, error extraction, project management, and automated testing workflows.

**Module Statistics:**
- Functions: 3
- Dependencies: 1 modules


**Module Information:**
- **Path:** `Modules\Unity-Claude-RunspaceManagement\Unity-Claude-RunspaceManagement.psm1`
- **Size:** 10.91 KB
- **Last Modified:** 2025-08-26 11:46
- **Total Functions:** 3
- **Exported Functions:** 1


**Dependencies:**
- `$componentPath` (external)


**Key Functions:**
- **Initialize-RunspaceManagement** - Line 63 - **Get-RunspaceManagementStatus** - Line 110 - **Stop-RunspaceManagement** - Line 148


--- 
### Unity-Claude-RunspaceManagement-Original

[⬆ Back to Contents](#-table-of-contents)

Unity Editor integration module providing direct communication with Unity processes. Handles compilation monitoring, error extraction, project management, and automated testing workflows.

**Module Statistics:**
- Functions: 35


**Module Information:**
- **Path:** `Modules\Unity-Claude-RunspaceManagement\Unity-Claude-RunspaceManagement-Original.psm1`
- **Size:** 75.97 KB
- **Last Modified:** 2025-08-26 11:46
- **Total Functions:** 30
- **Exported Functions:** 1




**Key Functions:**
- **Test-ModuleDependencyAvailability** - Line 7 - **Write-FallbackLog** - Line 53 - **Write-ModuleLog** - Line 72 - **New-RunspaceSessionState** - Line 123 - **Set-SessionStateConfiguration** - Line 206
- *...and 25 more functions*

--- 
### Unity-Claude-RunspaceManagement-Refactored

[⬆ Back to Contents](#-table-of-contents)

Unity Editor integration module providing direct communication with Unity processes. Handles compilation monitoring, error extraction, project management, and automated testing workflows.

**Module Statistics:**
- Functions: 3
- Dependencies: 1 modules


**Module Information:**
- **Path:** `Modules\Unity-Claude-RunspaceManagement\Unity-Claude-RunspaceManagement-Refactored.psm1`
- **Size:** 10.91 KB
- **Last Modified:** 2025-08-26 11:46
- **Total Functions:** 3
- **Exported Functions:** 1


**Dependencies:**
- `$componentPath` (external)


**Key Functions:**
- **Initialize-RunspaceManagement** - Line 63 - **Get-RunspaceManagementStatus** - Line 110 - **Stop-RunspaceManagement** - Line 148


--- 
### Unity-Claude-Safety

[⬆ Back to Contents](#-table-of-contents)

Safety and validation framework ensuring all automated operations meet security and stability requirements. Implements sandboxing, command validation, and rollback mechanisms to prevent destructive operations. Unity Editor integration module providing direct communication with Unity processes. Handles compilation monitoring, error extraction, project management, and automated testing workflows. 

**Module Statistics:**
 - Functions: 9


**Module Information:**
- **Path:** `Modules\Unity-Claude-Safety\Unity-Claude-Safety.psm1`
- **Size:** 23.95 KB
- **Last Modified:** 2025-08-20 17:25
- **Total Functions:** 9
- **Exported Functions:** 1




**Key Functions:**
- **Initialize-SafetyFramework** - Line 27 - **Test-FixSafety** - Line 82 - **Invoke-SafetyBackup** - Line 206 - **Invoke-DryRun** - Line 263 - **Set-SafetyConfiguration** - Line 400
- *...and 4 more functions*

--- 
### Unity-Claude-ScalabilityEnhancements

[⬆ Back to Contents](#-table-of-contents)

Unity Editor integration module providing direct communication with Unity processes. Handles compilation monitoring, error extraction, project management, and automated testing workflows.

**Module Statistics:**
- Functions: 4
- Dependencies: 6 modules


**Module Information:**
- **Path:** `Modules\Unity-Claude-ScalabilityEnhancements\Unity-Claude-ScalabilityEnhancements.psm1`
- **Size:** 16.67 KB
- **Last Modified:** 2025-08-26 11:46
- **Total Functions:** 4
- **Exported Functions:** 1


**Dependencies:**
- `(Join-Path` (external) - `(Join-Path` (external) - `(Join-Path` (external) - `(Join-Path` (external) - `(Join-Path` (external) - `(Join-Path` (external)


**Key Functions:**
- **Initialize-ScalabilityEnhancements** - Line 26 - **Test-ScalabilityComponents** - Line 114 - **Get-ScalabilityInfo** - Line 200 - **Update-ScalabilityStatistics** - Line 268


--- 
### Unity-Claude-ScalabilityEnhancements-Original

[⬆ Back to Contents](#-table-of-contents)

Unity Editor integration module providing direct communication with Unity processes. Handles compilation monitoring, error extraction, project management, and automated testing workflows.

**Module Statistics:**
- Functions: 34
- Classes: 6


**Module Information:**
- **Path:** `Modules\Unity-Claude-ScalabilityEnhancements\Unity-Claude-ScalabilityEnhancements-Original.psm1`
- **Size:** 48.16 KB
- **Last Modified:** 2025-08-26 11:46
- **Total Functions:** 70
- **Exported Functions:** 1




**Key Functions:**
- **GraphPruner** - Line 16 - **PruneGraph** - Line 29 - **MarkPreservedNodes** - Line 67 - **RemoveUnusedNodes** - Line 78 - **RemoveOrphanedEdges** - Line 100
- *...and 65 more functions*

--- 
### Unity-Claude-ScalabilityEnhancements-Refactored

[⬆ Back to Contents](#-table-of-contents)

Unity Editor integration module providing direct communication with Unity processes. Handles compilation monitoring, error extraction, project management, and automated testing workflows.

**Module Statistics:**
- Functions: 4
- Dependencies: 6 modules


**Module Information:**
- **Path:** `Modules\Unity-Claude-ScalabilityEnhancements\Unity-Claude-ScalabilityEnhancements-Refactored.psm1`
- **Size:** 16.67 KB
- **Last Modified:** 2025-08-26 11:46
- **Total Functions:** 4
- **Exported Functions:** 1


**Dependencies:**
- `(Join-Path` (external) - `(Join-Path` (external) - `(Join-Path` (external) - `(Join-Path` (external) - `(Join-Path` (external) - `(Join-Path` (external)


**Key Functions:**
- **Initialize-ScalabilityEnhancements** - Line 26 - **Test-ScalabilityComponents** - Line 114 - **Get-ScalabilityInfo** - Line 200 - **Update-ScalabilityStatistics** - Line 268


--- 
### Unity-Claude-ScalabilityOptimizer

[⬆ Back to Contents](#-table-of-contents)

Unity Editor integration module providing direct communication with Unity processes. Handles compilation monitoring, error extraction, project management, and automated testing workflows.

**Module Statistics:**
- Functions: 17


**Module Information:**
- **Path:** `Modules\Unity-Claude-ScalabilityOptimizer\Unity-Claude-ScalabilityOptimizer.psm1`
- **Size:** 37.82 KB
- **Last Modified:** 2025-08-30 20:31
- **Total Functions:** 17
- **Exported Functions:** 1




**Key Functions:**
- **Initialize-ScalabilityOptimizer** - Line 72 - **Initialize-ScalingPolicies** - Line 163 - **Initialize-PerformanceBenchmarking** - Line 255 - **Initialize-DistributedProcessing** - Line 289 - **Start-PerformanceMonitoring** - Line 342
- *...and 12 more functions*

--- 
### Unity-Claude-SemanticAnalysis

[⬆ Back to Contents](#-table-of-contents)

Unity Editor integration module providing direct communication with Unity processes. Handles compilation monitoring, error extraction, project management, and automated testing workflows.

**Module Statistics:**
- Functions: 3
- Dependencies: 8 modules


**Module Information:**
- **Path:** `Modules\Unity-Claude-CPG\Unity-Claude-SemanticAnalysis.psm1`
- **Size:** 8.38 KB
- **Last Modified:** 2025-08-25 02:21
- **Total Functions:** 1
- **Exported Functions:** 1


**Dependencies:**
- `$cpgModule` (external) - `$helpersModule` (external) - `$patternsModule` (external) - `$purposeModule` (external) - `$metricsModule` (external) - `$businessModule` (external) - `$qualityModule` (external) - `$archModule` (external)


**Key Functions:**
- **ConvertTo-CPGFromScriptBlock** - Line 99


--- 
### Unity-Claude-SemanticAnalysis-Architecture

[⬆ Back to Contents](#-table-of-contents)

Unity Editor integration module providing direct communication with Unity processes. Handles compilation monitoring, error extraction, project management, and automated testing workflows.

**Module Statistics:**
- Functions: 5
- Classes: 2
- Dependencies: 1 modules


**Module Information:**
- **Path:** `Modules\Unity-Claude-CPG\Unity-Claude-SemanticAnalysis-Architecture.psm1`
- **Size:** 13.45 KB
- **Last Modified:** 2025-08-25 02:21
- **Total Functions:** 5
- **Exported Functions:** 1


**Dependencies:**
- `(Join-Path` (external)


**Key Functions:**
- **Recover-Architecture** - Line 7 - **Identify-SystemLayers** - Line 101 - **Analyze-ModuleDependencies** - Line 157 - **Find-ArchitecturalPatterns** - Line 218 - **Analyze-ComponentRelationships** - Line 299


--- 
### Unity-Claude-SemanticAnalysis-Business

[⬆ Back to Contents](#-table-of-contents)

Unity Editor integration module providing direct communication with Unity processes. Handles compilation monitoring, error extraction, project management, and automated testing workflows.

**Module Statistics:**
- Functions: 9
- Dependencies: 1 modules


**Module Information:**
- **Path:** `Modules\Unity-Claude-CPG\Unity-Claude-SemanticAnalysis-Business.psm1`
- **Size:** 15.91 KB
- **Last Modified:** 2025-08-25 02:21
- **Total Functions:** 5
- **Exported Functions:** 1


**Dependencies:**
- `(Join-Path` (external)


**Key Functions:**
- **Extract-BusinessLogic** - Line 7 - **Find-ValidationRules** - Line 106 - **Find-BusinessRules** - Line 186 - **Find-WorkflowPatterns** - Line 265 - **Find-DomainCalculations** - Line 338


--- 
### Unity-Claude-SemanticAnalysis-Helpers

[⬆ Back to Contents](#-table-of-contents)

Unity Editor integration module providing direct communication with Unity processes. Handles compilation monitoring, error extraction, project management, and automated testing workflows.

**Module Statistics:**
- Functions: 13
- Classes: 1


**Module Information:**
- **Path:** `Modules\Unity-Claude-CPG\Unity-Claude-SemanticAnalysis-Helpers.psm1`
- **Size:** 20.93 KB
- **Last Modified:** 2025-08-25 02:21
- **Total Functions:** 13
- **Exported Functions:** 1




**Key Functions:**
- **Test-IsCPGraph** - Line 42 - **Ensure-GraphDuckType** - Line 68 - **Ensure-Array** - Line 162 - **Normalize-AnalysisRecord** - Line 180 - **Get-CacheKey** - Line 248
- *...and 8 more functions*

--- 
### Unity-Claude-SemanticAnalysis-Metrics

[⬆ Back to Contents](#-table-of-contents)

Unity Editor integration module providing direct communication with Unity processes. Handles compilation monitoring, error extraction, project management, and automated testing workflows.

**Module Statistics:**
- Functions: 5
- Dependencies: 1 modules


**Module Information:**
- **Path:** `Modules\Unity-Claude-CPG\Unity-Claude-SemanticAnalysis-Metrics.psm1`
- **Size:** 13.13 KB
- **Last Modified:** 2025-08-25 02:21
- **Total Functions:** 5
- **Exported Functions:** 1


**Dependencies:**
- `(Join-Path` (external)


**Key Functions:**
- **Get-CohesionMetrics** - Line 7 - **Calculate-ModuleCohesion** - Line 119 - **Calculate-SemanticCohesion** - Line 221 - **Get-CohesionRecommendations** - Line 285 - **Get-ComplexityMetrics** - Line 330


--- 
### Unity-Claude-SemanticAnalysis-New

[⬆ Back to Contents](#-table-of-contents)

Unity Editor integration module providing direct communication with Unity processes. Handles compilation monitoring, error extraction, project management, and automated testing workflows.

**Module Statistics:**
- Functions: 3
- Dependencies: 8 modules


**Module Information:**
- **Path:** `Modules\Unity-Claude-CPG\Unity-Claude-SemanticAnalysis-New.psm1`
- **Size:** 8.38 KB
- **Last Modified:** 2025-08-25 02:21
- **Total Functions:** 1
- **Exported Functions:** 1


**Dependencies:**
- `$cpgModule` (external) - `$helpersModule` (external) - `$patternsModule` (external) - `$purposeModule` (external) - `$metricsModule` (external) - `$businessModule` (external) - `$qualityModule` (external) - `$archModule` (external)


**Key Functions:**
- **ConvertTo-CPGFromScriptBlock** - Line 99


--- 
### Unity-Claude-SemanticAnalysis-Old

[⬆ Back to Contents](#-table-of-contents)

Unity Editor integration module providing direct communication with Unity processes. Handles compilation monitoring, error extraction, project management, and automated testing workflows.

**Module Statistics:**
- Functions: 3
- Dependencies: 8 modules


**Module Information:**
- **Path:** `Modules\Unity-Claude-CPG\Unity-Claude-SemanticAnalysis-Old.psm1`
- **Size:** 8.38 KB
- **Last Modified:** 2025-08-25 02:21
- **Total Functions:** 1
- **Exported Functions:** 1


**Dependencies:**
- `$cpgModule` (external) - `$helpersModule` (external) - `$patternsModule` (external) - `$purposeModule` (external) - `$metricsModule` (external) - `$businessModule` (external) - `$qualityModule` (external) - `$archModule` (external)


**Key Functions:**
- **ConvertTo-CPGFromScriptBlock** - Line 99


--- 
### Unity-Claude-SemanticAnalysis-Patterns

[⬆ Back to Contents](#-table-of-contents)

Unity Editor integration module providing direct communication with Unity processes. Handles compilation monitoring, error extraction, project management, and automated testing workflows.

**Module Statistics:**
- Functions: 8
- Classes: 4
- Dependencies: 1 modules


**Module Information:**
- **Path:** `Modules\Unity-Claude-CPG\Unity-Claude-SemanticAnalysis-Patterns.psm1`
- **Size:** 19.41 KB
- **Last Modified:** 2025-08-25 02:21
- **Total Functions:** 8
- **Exported Functions:** 1


**Dependencies:**
- `(Join-Path` (external)


**Key Functions:**
- **Canonicalize-PatternTypes** - Line 7 - **Find-DesignPatterns** - Line 35 - **Find-SingletonPattern** - Line 185 - **Find-FactoryPattern** - Line 291 - **Find-ObserverPattern** - Line 370
- *...and 3 more functions*

--- 
### Unity-Claude-SemanticAnalysis-Purpose

[⬆ Back to Contents](#-table-of-contents)

Unity Editor integration module providing direct communication with Unity processes. Handles compilation monitoring, error extraction, project management, and automated testing workflows.

**Module Statistics:**
- Functions: 4
- Classes: 3
- Dependencies: 1 modules


**Module Information:**
- **Path:** `Modules\Unity-Claude-CPG\Unity-Claude-SemanticAnalysis-Purpose.psm1`
- **Size:** 14.99 KB
- **Last Modified:** 2025-08-25 02:21
- **Total Functions:** 3
- **Exported Functions:** 1


**Dependencies:**
- `(Join-Path` (external)


**Key Functions:**
- **Get-CodePurpose** - Line 7 - **Classify-CallablePurpose** - Line 145 - **Classify-ClassPurpose** - Line 258


--- 
### Unity-Claude-SemanticAnalysis-Quality

[⬆ Back to Contents](#-table-of-contents)

Unity Editor integration module providing direct communication with Unity processes. Handles compilation monitoring, error extraction, project management, and automated testing workflows.

**Module Statistics:**
- Functions: 13
- Classes: 7
- Dependencies: 1 modules


**Module Information:**
- **Path:** `Modules\Unity-Claude-CPG\Unity-Claude-SemanticAnalysis-Quality.psm1`
- **Size:** 21.63 KB
- **Last Modified:** 2025-08-25 02:21
- **Total Functions:** 8
- **Exported Functions:** 1


**Dependencies:**
- `(Join-Path` (external)


**Key Functions:**
- **Test-DocumentationCompleteness** - Line 7 - **Analyze-FunctionDocumentation** - Line 103 - **Analyze-ClassDocumentation** - Line 209 - **Test-NamingConventions** - Line 318 - **Test-NodeNaming** - Line 387
- *...and 3 more functions*

--- 
### Unity-Claude-SessionManager

[⬆ Back to Contents](#-table-of-contents)

Unity Editor integration module providing direct communication with Unity processes. Handles compilation monitoring, error extraction, project management, and automated testing workflows.

**Module Statistics:**
- Functions: 18
- Dependencies: 1 modules


**Module Information:**
- **Path:** `Modules\Unity-Claude-SessionManager.psm1`
- **Size:** 26.48 KB
- **Last Modified:** 2025-08-20 17:25
- **Total Functions:** 18
- **Exported Functions:** 1


**Dependencies:**
- `$conversationStatePath` (external)


**Key Functions:**
- **Write-SessionLog** - Line 60 - **New-SessionId** - Line 92 - **Get-SessionTimestamp** - Line 96 - **New-ConversationSession** - Line 104 - **Get-ConversationSession** - Line 184
- *...and 13 more functions*

--- 
### Unity-Claude-SlackIntegration

[⬆ Back to Contents](#-table-of-contents)

Unity Editor integration module providing direct communication with Unity processes. Handles compilation monitoring, error extraction, project management, and automated testing workflows.

**Module Statistics:**
- Functions: 10
- Dependencies: 1 modules


**Module Information:**
- **Path:** `Modules\Unity-Claude-SlackIntegration\Unity-Claude-SlackIntegration.psm1`
- **Size:** 18.86 KB
- **Last Modified:** 2025-08-30 14:31
- **Total Functions:** 10
- **Exported Functions:** 1


**Dependencies:**
- `PSSlack` (external)


**Key Functions:**
- **Initialize-SlackIntegration** - Line 25 - **Send-SlackAlert** - Line 117 - **Format-SlackAlertMessage** - Line 203 - **Create-SlackAlertAttachments** - Line 251 - **Send-SlackMessageViaPSSlack** - Line 321
- *...and 5 more functions*

--- 
### Unity-Claude-SystemCoordinator

[⬆ Back to Contents](#-table-of-contents)

Unity Editor integration module providing direct communication with Unity processes. Handles compilation monitoring, error extraction, project management, and automated testing workflows.

**Module Statistics:**
- Functions: 24
- Dependencies: 2 modules


**Module Information:**
- **Path:** `Modules\Unity-Claude-SystemCoordinator\Unity-Claude-SystemCoordinator.psm1`
- **Size:** 40.22 KB
- **Last Modified:** 2025-08-30 20:21
- **Total Functions:** 21
- **Exported Functions:** 1


**Dependencies:**
- `$modulePath` (external) - `$modulePath` (external)


**Key Functions:**
- **Initialize-SystemCoordinator** - Line 76 - **Register-AvailableModules** - Line 176 - **Request-CoordinatedOperation** - Line 244 - **Execute-CoordinatedOperation** - Line 378 - **Get-OperationResourceRequirements** - Line 474
- *...and 16 more functions*

--- 
### Unity-Claude-SystemStatus

[⬆ Back to Contents](#-table-of-contents)

Unity Editor integration module providing direct communication with Unity processes. Handles compilation monitoring, error extraction, project management, and automated testing workflows.

**Module Statistics:**
- Functions: 0


**Module Information:**
- **Path:** `Modules\Unity-Claude-SystemStatus\Unity-Claude-SystemStatus.psm1`
- **Size:** 5.03 KB
- **Last Modified:** 2025-08-26 21:41
- **Total Functions:** 0
- **Exported Functions:** 1





--- 
### Unity-Claude-TeamsIntegration

[⬆ Back to Contents](#-table-of-contents)

Unity Editor integration module providing direct communication with Unity processes. Handles compilation monitoring, error extraction, project management, and automated testing workflows.

**Module Statistics:**
- Functions: 11


**Module Information:**
- **Path:** `Modules\Unity-Claude-TeamsIntegration\Unity-Claude-TeamsIntegration.psm1`
- **Size:** 22.77 KB
- **Last Modified:** 2025-08-30 14:32
- **Total Functions:** 11
- **Exported Functions:** 1




**Key Functions:**
- **Initialize-TeamsIntegration** - Line 30 - **Test-TeamsMigrationStatus** - Line 119 - **Send-TeamsAlert** - Line 170 - **Create-TeamsRichCardPayload** - Line 246 - **Create-TeamsSimplePayload** - Line 357
- *...and 6 more functions*

--- 
### Unity-Claude-TreeSitter

[⬆ Back to Contents](#-table-of-contents)

Unity Editor integration module providing direct communication with Unity processes. Handles compilation monitoring, error extraction, project management, and automated testing workflows.

**Module Statistics:**
- Functions: 12


**Module Information:**
- **Path:** `Modules\Unity-Claude-CPG\Unity-Claude-TreeSitter.psm1`
- **Size:** 19.96 KB
- **Last Modified:** 2025-08-24 23:42
- **Total Functions:** 10
- **Exported Functions:** 1




**Key Functions:**
- **Initialize-TreeSitter** - Line 13 - **Install-TreeSitterParsers** - Line 79 - **Invoke-TreeSitterParse** - Line 145 - **Invoke-TreeSitterCliParse** - Line 176 - **Invoke-TreeSitterNodeParse** - Line 205
- *...and 5 more functions*

--- 
### Unity-Claude-TriggerConditions

[⬆ Back to Contents](#-table-of-contents)

Unity Editor integration module providing direct communication with Unity processes. Handles compilation monitoring, error extraction, project management, and automated testing workflows.

**Module Statistics:**
- Functions: 8
- Classes: 1


**Module Information:**
- **Path:** `Modules\Unity-Claude-DocumentationDrift\Unity-Claude-TriggerConditions.psm1`
- **Size:** 27.5 KB
- **Last Modified:** 2025-08-24 12:06
- **Total Functions:** 7
- **Exported Functions:** 1




**Key Functions:**
- **Initialize-TriggerConditions** - Line 79 - **Test-TriggerCondition** - Line 148 - **Add-ToProcessingQueue** - Line 365 - **Get-ProcessingQueue** - Line 432 - **Start-QueueProcessing** - Line 478
- *...and 2 more functions*

--- 
### Unity-Claude-TriggerIntegration

[⬆ Back to Contents](#-table-of-contents)

Unity Editor integration module providing direct communication with Unity processes. Handles compilation monitoring, error extraction, project management, and automated testing workflows.

**Module Statistics:**
- Functions: 8
- Dependencies: 4 modules


**Module Information:**
- **Path:** `Modules\Unity-Claude-DocumentationDrift\Unity-Claude-TriggerIntegration.psm1`
- **Size:** 23.33 KB
- **Last Modified:** 2025-08-24 12:06
- **Total Functions:** 8
- **Exported Functions:** 1


**Dependencies:**
- [`Unity-Claude-DocumentationDrift`](#unity-claude-documentationdrift) - [`Unity-Claude-TriggerConditions`](#unity-claude-triggerconditions) - [`Unity-Claude-DocumentationDrift`](#unity-claude-documentationdrift) - [`Unity-Claude-TriggerConditions`](#unity-claude-triggerconditions)


**Key Functions:**
- **Initialize-TriggerIntegration** - Line 57 - **Register-EventHandlers** - Line 134 - **Start-FileMonitoring** - Line 246 - **Stop-FileMonitoring** - Line 316 - **Start-AsynchronousProcessing** - Line 371
- *...and 3 more functions*

--- 
### Unity-Claude-TriggerManager

[⬆ Back to Contents](#-table-of-contents)

Unity Editor integration module providing direct communication with Unity processes. Handles compilation monitoring, error extraction, project management, and automated testing workflows.

**Module Statistics:**
- Functions: 25


**Module Information:**
- **Path:** `Modules\Unity-Claude-FileMonitor\Unity-Claude-TriggerManager.psm1`
- **Size:** 19.18 KB
- **Last Modified:** 2025-08-24 12:06
- **Total Functions:** 25
- **Exported Functions:** 1




**Key Functions:**
- **Initialize-TriggerManager** - Line 57 - **Test-FileExclusion** - Line 100 - **Find-MatchingTriggers** - Line 120 - **Test-TriggerCooldown** - Line 154 - **Add-ChangeToTrigger** - Line 176
- *...and 20 more functions*

--- 
### Unity-Claude-UnityParallelization

[⬆ Back to Contents](#-table-of-contents)

High-performance parallel processing module designed to maximize throughput and system utilization. Implements thread-safe operations, runspace management, and concurrent execution patterns to handle multiple Unity operations simultaneously without blocking. Unity Editor integration module providing direct communication with Unity processes. Handles compilation monitoring, error extraction, project management, and automated testing workflows. 

**Module Statistics:**
 - Functions: 2
 - Dependencies: 1 modules


**Module Information:**
- **Path:** `Modules\Unity-Claude-UnityParallelization\Unity-Claude-UnityParallelization.psm1`
- **Size:** 10.72 KB
- **Last Modified:** 2025-08-26 11:46
- **Total Functions:** 2
- **Exported Functions:** 1


**Dependencies:**
- `$modulePath` (external)


**Key Functions:**
- **Get-UnityParallelizationModuleInfo** - Line 102 - **Show-UnityParallelizationFunctions** - Line 117


--- 
### Unity-Claude-UnityParallelization-Original

[⬆ Back to Contents](#-table-of-contents)

High-performance parallel processing module designed to maximize throughput and system utilization. Implements thread-safe operations, runspace management, and concurrent execution patterns to handle multiple Unity operations simultaneously without blocking. Unity Editor integration module providing direct communication with Unity processes. Handles compilation monitoring, error extraction, project management, and automated testing workflows. 

**Module Statistics:**
 - Functions: 23
 - Dependencies: 2 modules


**Module Information:**
- **Path:** `Modules\Unity-Claude-UnityParallelization\Unity-Claude-UnityParallelization-Original.psm1`
- **Size:** 86.33 KB
- **Last Modified:** 2025-08-26 11:46
- **Total Functions:** 22
- **Exported Functions:** 1


**Dependencies:**
- [`Unity-Claude-RunspaceManagement`](#unity-claude-runspacemanagement) - [`Unity-Claude-ParallelProcessing`](#unity-claude-parallelprocessing)


**Key Functions:**
- **Test-ModuleDependencyAvailability** - Line 12 - **Write-FallbackLog** - Line 75 - **Write-UnityParallelLog** - Line 94 - **Find-UnityProjects** - Line 145 - **Register-UnityProject** - Line 232
- *...and 17 more functions*

--- 
### Unity-Claude-UnityParallelization-Refactored

[⬆ Back to Contents](#-table-of-contents)

High-performance parallel processing module designed to maximize throughput and system utilization. Implements thread-safe operations, runspace management, and concurrent execution patterns to handle multiple Unity operations simultaneously without blocking. Unity Editor integration module providing direct communication with Unity processes. Handles compilation monitoring, error extraction, project management, and automated testing workflows. 

**Module Statistics:**
 - Functions: 2
 - Dependencies: 1 modules


**Module Information:**
- **Path:** `Modules\Unity-Claude-UnityParallelization\Unity-Claude-UnityParallelization-Refactored.psm1`
- **Size:** 10.72 KB
- **Last Modified:** 2025-08-26 11:46
- **Total Functions:** 2
- **Exported Functions:** 1


**Dependencies:**
- `$modulePath` (external)


**Key Functions:**
- **Get-UnityParallelizationModuleInfo** - Line 102 - **Show-UnityParallelizationFunctions** - Line 117


--- 
### Unity-Claude-WebhookNotifications

[⬆ Back to Contents](#-table-of-contents)

Unity Editor integration module providing direct communication with Unity processes. Handles compilation monitoring, error extraction, project management, and automated testing workflows.

**Module Statistics:**
- Functions: 11


**Module Information:**
- **Path:** `Modules\Unity-Claude-WebhookNotifications\Unity-Claude-WebhookNotifications.psm1`
- **Size:** 40.8 KB
- **Last Modified:** 2025-08-21 17:45
- **Total Functions:** 11
- **Exported Functions:** 1




**Key Functions:**
- **New-WebhookConfiguration** - Line 24 - **Test-WebhookConfiguration** - Line 108 - **Invoke-WebhookDelivery** - Line 209 - **Get-WebhookConfiguration** - Line 358 - **New-BearerTokenAuth** - Line 426
- *...and 6 more functions*

--- 
### Unity-Claude-WindowDetection

[⬆ Back to Contents](#-table-of-contents)

Unity Editor integration module providing direct communication with Unity processes. Handles compilation monitoring, error extraction, project management, and automated testing workflows.

**Module Statistics:**
- Functions: 5
- Classes: 1


**Module Information:**
- **Path:** `Modules\Unity-Claude-WindowDetection.psm1`
- **Size:** 15.24 KB
- **Last Modified:** 2025-08-20 17:25
- **Total Functions:** 5
- **Exported Functions:** 1




**Key Functions:**
- **Get-DetailedWindowInfo** - Line 49 - **Test-ClaudeCodeWindow** - Line 86 - **Get-ForegroundWindow** - Line 177 - **Find-ClaudeCodeCLIWindow** - Line 239 - **Test-WindowDetection** - Line 336


--- 
### Unity-Claude-WindowDetection-Enhanced

[⬆ Back to Contents](#-table-of-contents)

Unity Editor integration module providing direct communication with Unity processes. Handles compilation monitoring, error extraction, project management, and automated testing workflows.

**Module Statistics:**
- Functions: 2


**Module Information:**
- **Path:** `Modules\Unity-Claude-WindowDetection-Enhanced.psm1`
- **Size:** 9.34 KB
- **Last Modified:** 2025-08-20 17:25
- **Total Functions:** 1
- **Exported Functions:** 1




**Key Functions:**
- **Find-ClaudeCodeCLIWindow-Enhanced** - Line 4


--- 
### Unity-TestAutomation

[⬆ Back to Contents](#-table-of-contents)

Unity Editor integration module providing direct communication with Unity processes. Handles compilation monitoring, error extraction, project management, and automated testing workflows.

**Module Statistics:**
- Functions: 9
- Dependencies: 3 modules


**Module Information:**
- **Path:** `Modules\Unity-TestAutomation\Unity-TestAutomation.psm1`
- **Size:** 41.42 KB
- **Last Modified:** 2025-08-20 17:25
- **Total Functions:** 9
- **Exported Functions:** 1


**Dependencies:**
- `$PSScriptRoot\..\SafeCommandExecution\SafeCommandExecution.psm1` (external) - `Pester` (external) - `Pester` (external)


**Key Functions:**
- **Invoke-UnityEditModeTests** - Line 27 - **Invoke-UnityPlayModeTests** - Line 169 - **Get-UnityTestResults** - Line 307 - **Get-UnityTestCategories** - Line 420 - **New-UnityTestFilter** - Line 471
- *...and 4 more functions*

--- 
### UnityBuildOperations

[⬆ Back to Contents](#-table-of-contents)

Unity Editor integration module providing direct communication with Unity processes. Handles compilation monitoring, error extraction, project management, and automated testing workflows.

**Module Statistics:**
- Functions: 6
- Classes: 2
- Dependencies: 2 modules


**Module Information:**
- **Path:** `Modules\SafeCommandExecution\Core\UnityBuildOperations.psm1`
- **Size:** 22.42 KB
- **Last Modified:** 2025-08-26 11:46
- **Total Functions:** 6
- **Exported Functions:** 1


**Dependencies:**
- `$PSScriptRoot\SafeCommandCore.psm1` (external) - `$PSScriptRoot\ValidationEngine.psm1` (external)


**Key Functions:**
- **Invoke-UnityPlayerBuild** - Line 22 - **New-UnityBuildScript** - Line 162 - **Test-UnityBuildResult** - Line 255 - **Invoke-UnityAssetImport** - Line 360 - **New-UnityAssetImportScript** - Line 469
- *...and 1 more functions*

--- 
### UnityCommands

[⬆ Back to Contents](#-table-of-contents)

Unity Editor integration module providing direct communication with Unity processes. Handles compilation monitoring, error extraction, project management, and automated testing workflows.

**Module Statistics:**
- Functions: 7
- Dependencies: 1 modules


**Module Information:**
- **Path:** `Modules\Unity-Claude-AutonomousAgent\Commands\UnityCommands.psm1`
- **Size:** 15.5 KB
- **Last Modified:** 2025-08-20 17:25
- **Total Functions:** 7
- **Exported Functions:** 1


**Dependencies:**
- `(Join-Path` (external)


**Key Functions:**
- **Invoke-TestCommand** - Line 16 - **Invoke-UnityTests** - Line 66 - **Invoke-CompilationTest** - Line 127 - **Invoke-PowerShellTests** - Line 170 - **Invoke-BuildCommand** - Line 229
- *...and 2 more functions*

--- 
### UnityIntegration

[⬆ Back to Contents](#-table-of-contents)

Unity Editor integration module providing direct communication with Unity processes. Handles compilation monitoring, error extraction, project management, and automated testing workflows.

**Module Statistics:**
- Functions: 6
- Dependencies: 1 modules


**Module Information:**
- **Path:** `Modules\Unity-Claude-AutonomousAgent\Integration\UnityIntegration.psm1`
- **Size:** 12.64 KB
- **Last Modified:** 2025-08-20 17:25
- **Total Functions:** 6
- **Exported Functions:** 1


**Dependencies:**
- `(Join-Path` (external)


**Key Functions:**
- **Get-PatternConfidence** - Line 16 - **Convert-TypeToStandard** - Line 74 - **Convert-ActionToType** - Line 121 - **Normalize-RecommendationType** - Line 166 - **Remove-DuplicateRecommendations** - Line 206
- *...and 1 more functions*

--- 
### UnityLogAnalysis

[⬆ Back to Contents](#-table-of-contents)

Unity Editor integration module providing direct communication with Unity processes. Handles compilation monitoring, error extraction, project management, and automated testing workflows.

**Module Statistics:**
- Functions: 2
- Dependencies: 2 modules


**Module Information:**
- **Path:** `Modules\SafeCommandExecution\Core\UnityLogAnalysis.psm1`
- **Size:** 14.77 KB
- **Last Modified:** 2025-08-26 11:46
- **Total Functions:** 2
- **Exported Functions:** 1


**Dependencies:**
- `$PSScriptRoot\SafeCommandCore.psm1` (external) - `$PSScriptRoot\ValidationEngine.psm1` (external)


**Key Functions:**
- **Invoke-UnityLogAnalysis** - Line 22 - **Invoke-UnityErrorPatternAnalysis** - Line 200


--- 
### UnityPerformanceAnalysis

[⬆ Back to Contents](#-table-of-contents)

Unity Editor integration module providing direct communication with Unity processes. Handles compilation monitoring, error extraction, project management, and automated testing workflows.

**Module Statistics:**
- Functions: 2
- Dependencies: 1 modules


**Module Information:**
- **Path:** `Modules\SafeCommandExecution\Core\UnityPerformanceAnalysis.psm1`
- **Size:** 15.01 KB
- **Last Modified:** 2025-08-26 11:46
- **Total Functions:** 2
- **Exported Functions:** 1


**Dependencies:**
- `$PSScriptRoot\SafeCommandCore.psm1` (external)


**Key Functions:**
- **Invoke-UnityPerformanceAnalysis** - Line 21 - **Invoke-UnityTrendAnalysis** - Line 218


--- 
### UnityProjectOperations

[⬆ Back to Contents](#-table-of-contents)

Unity Editor integration module providing direct communication with Unity processes. Handles compilation monitoring, error extraction, project management, and automated testing workflows.

**Module Statistics:**
- Functions: 3
- Dependencies: 2 modules


**Module Information:**
- **Path:** `Modules\SafeCommandExecution\Core\UnityProjectOperations.psm1`
- **Size:** 14.34 KB
- **Last Modified:** 2025-08-26 11:46
- **Total Functions:** 3
- **Exported Functions:** 1


**Dependencies:**
- `$PSScriptRoot\SafeCommandCore.psm1` (external) - `$PSScriptRoot\ValidationEngine.psm1` (external)


**Key Functions:**
- **Invoke-UnityProjectValidation** - Line 22 - **Invoke-UnityScriptCompilation** - Line 149 - **Test-UnityCompilationResult** - Line 255


--- 
### UnityReportingOperations

[⬆ Back to Contents](#-table-of-contents)

Unity Editor integration module providing direct communication with Unity processes. Handles compilation monitoring, error extraction, project management, and automated testing workflows.

**Module Statistics:**
- Functions: 3
- Dependencies: 1 modules


**Module Information:**
- **Path:** `Modules\SafeCommandExecution\Core\UnityReportingOperations.psm1`
- **Size:** 21.96 KB
- **Last Modified:** 2025-08-26 11:46
- **Total Functions:** 3
- **Exported Functions:** 1


**Dependencies:**
- `$PSScriptRoot\SafeCommandCore.psm1` (external)


**Key Functions:**
- **Invoke-UnityReportGeneration** - Line 21 - **Export-UnityAnalysisData** - Line 214 - **Get-UnityAnalyticsMetrics** - Line 370


--- 
### ValidationEngine

[⬆ Back to Contents](#-table-of-contents)

Specialized module providing targeted functionality for the Unity-Claude automation system. Integrates with the broader architecture to deliver specific capabilities and enhance overall system functionality.

**Module Statistics:**
- Functions: 4
- Dependencies: 1 modules


**Module Information:**
- **Path:** `Modules\SafeCommandExecution\Core\ValidationEngine.psm1`
- **Size:** 11.32 KB
- **Last Modified:** 2025-08-26 11:46
- **Total Functions:** 4
- **Exported Functions:** 1


**Dependencies:**
- `$PSScriptRoot\SafeCommandCore.psm1` (external)


**Key Functions:**
- **Test-CommandSafety** - Line 21 - **Test-PathSafety** - Line 149 - **Remove-DangerousCharacters** - Line 198 - **Test-InputValidity** - Line 227


--- 
### VariableSharing

[⬆ Back to Contents](#-table-of-contents)

Specialized module providing targeted functionality for the Unity-Claude automation system. Integrates with the broader architecture to deliver specific capabilities and enhance overall system functionality.

**Module Statistics:**
- Functions: 13


**Module Information:**
- **Path:** `Modules\Unity-Claude-RunspaceManagement\Core\VariableSharing.psm1`
- **Size:** 12.9 KB
- **Last Modified:** 2025-08-26 11:46
- **Total Functions:** 10
- **Exported Functions:** 1




**Key Functions:**
- **Write-ModuleLog** - Line 21 - **Add-SessionStateVariable** - Line 26 - **Get-SharedVariablesDictionary** - Line 27 - **New-SessionStateVariableEntry** - Line 30 - **Add-SharedVariable** - Line 73
- *...and 5 more functions*

--- 
### WindowManager

[⬆ Back to Contents](#-table-of-contents)

Specialized module providing targeted functionality for the Unity-Claude automation system. Integrates with the broader architecture to deliver specific capabilities and enhance overall system functionality.

**Module Statistics:**
- Functions: 6
- Classes: 3


**Module Information:**
- **Path:** `Modules\Unity-Claude-CLIOrchestrator\Core\WindowManager.psm1`
- **Size:** 14.5 KB
- **Last Modified:** 2025-08-27 23:51
- **Total Functions:** 5
- **Exported Functions:** 1




**Key Functions:**
- **Get-ClaudeWindowInfo** - Line 76 - **Update-ProtectedRegistration** - Line 161 - **Update-ClaudeWindowInfo** - Line 193 - **Switch-ToClaudeWindow** - Line 209 - **Submit-ToClaudeWindow** - Line 281


--- 
### WindowManager-Enhanced

[⬆ Back to Contents](#-table-of-contents)

Specialized module providing targeted functionality for the Unity-Claude automation system. Integrates with the broader architecture to deliver specific capabilities and enhance overall system functionality.

**Module Statistics:**
- Functions: 4
- Classes: 1


**Module Information:**
- **Path:** `Modules\Unity-Claude-CLIOrchestrator\Core\WindowManager-Enhanced.psm1`
- **Size:** 16.34 KB
- **Last Modified:** 2025-08-27 20:42
- **Total Functions:** 4
- **Exported Functions:** 1




**Key Functions:**
- **Update-ClaudeWindowInfo** - Line 74 - **Find-ClaudeWindow** - Line 120 - **Get-ClaudeWindowInfo** - Line 256 - **Switch-ToWindow** - Line 279


--- 
### WindowManager-NUGGETRON

[⬆ Back to Contents](#-table-of-contents)

Specialized module providing targeted functionality for the Unity-Claude automation system. Integrates with the broader architecture to deliver specific capabilities and enhance overall system functionality.

**Module Statistics:**
- Functions: 4
- Classes: 1


**Module Information:**
- **Path:** `Modules\Unity-Claude-CLIOrchestrator\Core\WindowManager-NUGGETRON.psm1`
- **Size:** 6.27 KB
- **Last Modified:** 2025-08-27 21:15
- **Total Functions:** 4
- **Exported Functions:** 1




**Key Functions:**
- **Get-ClaudeWindowInfo** - Line 6 - **Update-ClaudeWindowInfo** - Line 51 - **Switch-ToClaudeWindow** - Line 92 - **Submit-ToClaudeWindow** - Line 131


--- 
### WindowManager-Original

[⬆ Back to Contents](#-table-of-contents)

Specialized module providing targeted functionality for the Unity-Claude automation system. Integrates with the broader architecture to deliver specific capabilities and enhance overall system functionality.

**Module Statistics:**
- Functions: 4
- Classes: 1


**Module Information:**
- **Path:** `Modules\Unity-Claude-CLIOrchestrator\Core\WindowManager-Original.psm1`
- **Size:** 16.34 KB
- **Last Modified:** 2025-08-27 20:42
- **Total Functions:** 4
- **Exported Functions:** 1




**Key Functions:**
- **Update-ClaudeWindowInfo** - Line 74 - **Find-ClaudeWindow** - Line 120 - **Get-ClaudeWindowInfo** - Line 256 - **Switch-ToWindow** - Line 279


--- 
### WorkflowCore

[⬆ Back to Contents](#-table-of-contents)

Core infrastructure module providing fundamental functionality for the Unity-Claude system. This module serves as the foundation for other components, offering essential utilities, configuration management, and base services that other modules depend upon.

**Module Statistics:**
- Functions: 4


**Module Information:**
- **Path:** `Modules\Unity-Claude-IntegratedWorkflow\Core\WorkflowCore.psm1`
- **Size:** 4.3 KB
- **Last Modified:** 2025-08-26 11:46
- **Total Functions:** 3
- **Exported Functions:** 1




**Key Functions:**
- **Write-FallbackLog** - Line 17 - **Write-IntegratedWorkflowLog** - Line 39 - **Get-IntegratedWorkflowState** - Line 55


--- 
### WorkflowIntegration

[⬆ Back to Contents](#-table-of-contents)

Specialized module providing targeted functionality for the Unity-Claude automation system. Integrates with the broader architecture to deliver specific capabilities and enhance overall system functionality.

**Module Statistics:**
- Functions: 6


**Module Information:**
- **Path:** `Modules\Unity-Claude-NotificationIntegration\Integration\WorkflowIntegration.psm1`
- **Size:** 9.09 KB
- **Last Modified:** 2025-08-21 17:45
- **Total Functions:** 6
- **Exported Functions:** 1




**Key Functions:**
- **Invoke-NotificationHook** - Line 7 - **Add-WorkflowNotificationTrigger** - Line 71 - **Remove-WorkflowNotificationTrigger** - Line 120 - **Enable-WorkflowNotifications** - Line 131 - **Disable-WorkflowNotifications** - Line 163
- *...and 1 more functions*

--- 
### WorkflowMonitoring

[⬆ Back to Contents](#-table-of-contents)

Real-time monitoring module tracking system health, performance metrics, and Unity compilation status. Provides event-driven notifications and triggers automated responses to detected issues.

**Module Statistics:**
- Functions: 2
- Dependencies: 1 modules


**Module Information:**
- **Path:** `Modules\Unity-Claude-IntegratedWorkflow\Core\WorkflowMonitoring.psm1`
- **Size:** 13.34 KB
- **Last Modified:** 2025-08-26 11:46
- **Total Functions:** 2
- **Exported Functions:** 1


**Dependencies:**
- `$CorePath` (external)


**Key Functions:**
- **Get-IntegratedWorkflowStatus** - Line 23 - **Stop-IntegratedWorkflow** - Line 128


--- 
### WorkflowOrchestration

[⬆ Back to Contents](#-table-of-contents)

Master orchestration module coordinating complex multi-step workflows. Manages module interactions, handles state transitions, and ensures proper sequencing of automated operations.

**Module Statistics:**
- Functions: 4
- Dependencies: 2 modules


**Module Information:**
- **Path:** `Modules\Unity-Claude-IntegratedWorkflow\Core\WorkflowOrchestration.psm1`
- **Size:** 21.3 KB
- **Last Modified:** 2025-08-26 11:46
- **Total Functions:** 3
- **Exported Functions:** 1


**Dependencies:**
- `$CorePath` (external) - `$DepsPath` (external)


**Key Functions:**
- **New-IntegratedWorkflow** - Line 31 - **Start-IntegratedWorkflow** - Line 223 - **Get-WorkflowOrchestrationScript** - Line 321


---

## 🔄 Relationship Matrix

### Module Interdependencies

The following modules have the most connections:

| Module | Connections | Type | |--------|-------------|------| | Unity-Claude-PerformanceOptimizer | 14 | 📦 Standard | | Unity-Claude-PerformanceOptimizer-Refactored | 14 | 📦 Standard | | Unity-Claude-CLIOrchestrator | 9 | 🎭 Orchestrator | | Unity-Claude-SemanticAnalysis-New | 8 | 📦 Standard | | Unity-Claude-PerformanceOptimizer-Original | 8 | 📦 Standard | | Unity-Claude-NotificationIntegration | 8 | 🔌 Integration | | Unity-Claude-TriggerIntegration | 8 | 🔌 Integration | | Unity-Claude-ParallelProcessor | 8 | 📦 Standard | | Unity-Claude-SemanticAnalysis | 8 | 📦 Standard | | Unity-Claude-SemanticAnalysis-Old | 8 | 📦 Standard |

---

*Generated by Unity-Claude Semantic Documentation System*
