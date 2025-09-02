# Unity-Claude Automation System - Hybrid Semantic Documentation

**Generated:** 2025-08-31 01:22:16  
**Total Modules:** 367  
**AI-Enhanced Modules:** 10  
**Pattern-Based Modules:** 377  
**Total Functions:** 3893

## 📑 Table of Contents

1. [System Overview](#-system-overview)
2. [Architecture](#-architecture)
3. [Module Categories](#-module-categories)
4. [Critical Modules (AI-Enhanced)](#-critical-modules-ai-enhanced)
5. [Standard Modules](#-standard-modules)
6. [Module Network](#-module-network)

---

## 🎯 System Overview

The Unity-Claude Automation System is a sophisticated PowerShell-based framework that bridges Unity game development with Claude AI capabilities. This hybrid documentation combines AI-powered analysis for critical components with efficient pattern-based documentation for standard modules.

### Documentation Approach

- **🤖 AI-Enhanced**: Critical infrastructure and complex modules analyzed by codellama:34b
- **📋 Pattern-Based**: Standard modules documented using intelligent pattern matching
- **🔗 Relationship Mapping**: Automatic dependency and interaction analysis

## 🏗️ Architecture

The system implements a microservices-inspired architecture with these layers:

```mermaid
graph TB
    subgraph "External Systems"
        Unity[Unity Editor]
        Claude[Claude AI/CLI]
        GitHub[GitHub]
        Docker[Docker]
    end
    
    subgraph "Core Layer"
        Core[Core Infrastructure]
        Config[Configuration]
        Safety[Safety Framework]
    end
    
    subgraph "Intelligence Layer"
        AI[AI Integration]
        Decision[Decision Engine]
        Pattern[Pattern Recognition]
        Learning[Machine Learning]
    end
    
    subgraph "Processing Layer"
        Parallel[Parallel Processing]
        Cache[Caching System]
        Monitor[Monitoring]
    end
    
    subgraph "Orchestration Layer"
        CLIOrch[CLI Orchestrator]
        Master[Master Orchestrator]
        Auto[Autonomous Agents]
    end
    
    Unity --> Core
    Claude --> CLIOrch
    Core --> AI
    AI --> Decision
    Decision --> Pattern
    Pattern --> Parallel
    Parallel --> Cache
    Cache --> Monitor
    Monitor --> CLIOrch
    CLIOrch --> Master
    Master --> GitHub
```

## 📦 Module Categories


### ⚡ Performance & Processing

**Modules:** 26 | **Functions:** 414

- [**ContextOptimization**](#contextoptimization) - [**CPG-ThreadSafeOperations**](#cpg-threadsafeoperations) - [**LLM-ResponseCache**](#llm-responsecache) - [**ParallelizationCore**](#parallelizationcore) - [**ParallelMonitoring**](#parallelmonitoring) - [**Performance-Cache**](#performance-cache) - [**Performance-IncrementalUpdates**](#performance-incrementalupdates) - [**PerformanceAnalysis**](#performanceanalysis) - [**PerformanceMonitoring**](#performancemonitoring) - [**PerformanceOptimization**](#performanceoptimization) - [**PerformanceOptimizer**](#performanceoptimizer) - [**Unity-Claude-Cache**](#unity-claude-cache) - [**Unity-Claude-Cache-Fixed**](#unity-claude-cache-fixed) - [**Unity-Claude-Cache-Original**](#unity-claude-cache-original) - [**Unity-Claude-ClaudeParallelization**](#unity-claude-claudeparallelization) - [**Unity-Claude-ParallelProcessing**](#unity-claude-parallelprocessing) - [**Unity-Claude-ParallelProcessor**](#unity-claude-parallelprocessor) - [**Unity-Claude-ParallelProcessor-Original**](#unity-claude-parallelprocessor-original) - [**Unity-Claude-ParallelProcessor-Refactored**](#unity-claude-parallelprocessor-refactored) - [**Unity-Claude-PerformanceOptimizer**](#unity-claude-performanceoptimizer) - [**Unity-Claude-PerformanceOptimizer-Original**](#unity-claude-performanceoptimizer-original) - [**Unity-Claude-PerformanceOptimizer-Refactored**](#unity-claude-performanceoptimizer-refactored) - [**Unity-Claude-UnityParallelization**](#unity-claude-unityparallelization) - [**Unity-Claude-UnityParallelization-Original**](#unity-claude-unityparallelization-original) - [**Unity-Claude-UnityParallelization-Refactored**](#unity-claude-unityparallelization-refactored) - [**UnityPerformanceAnalysis**](#unityperformanceanalysis) 
### 🎮 Unity Integration

**Modules:** 167 | **Functions:** 2085

- [**CompilationIntegration**](#compilationintegration) - [**Unity-Claude-AgentIntegration**](#unity-claude-agentintegration) - [**Unity-Claude-AIAlertClassifier**](#unity-claude-aialertclassifier) - [**Unity-Claude-AlertAnalytics**](#unity-claude-alertanalytics) - [**Unity-Claude-AlertFeedbackCollector**](#unity-claude-alertfeedbackcollector) - [**Unity-Claude-AlertMLOptimizer**](#unity-claude-alertmloptimizer) - [**Unity-Claude-AlertQualityReporting**](#unity-claude-alertqualityreporting) - [**Unity-Claude-APIDocumentation**](#unity-claude-apidocumentation) - [**Unity-Claude-AST-Enhanced**](#unity-claude-ast-enhanced) - [**Unity-Claude-AutoGen**](#unity-claude-autogen) - [**Unity-Claude-AutoGenMonitoring**](#unity-claude-autogenmonitoring) - [**Unity-Claude-AutonomousAgent-Refactored**](#unity-claude-autonomousagent-refactored) - [**Unity-Claude-AutonomousDocumentationEngine**](#unity-claude-autonomousdocumentationengine) - [**Unity-Claude-AutonomousStateTracker**](#unity-claude-autonomousstatetracker) - [**Unity-Claude-AutonomousStateTracker-Enhanced**](#unity-claude-autonomousstatetracker-enhanced) - [**Unity-Claude-AutonomousStateTracker-Enhanced-Refactored**](#unity-claude-autonomousstatetracker-enhanced-refactored) - [**Unity-Claude-Cache**](#unity-claude-cache) - [**Unity-Claude-Cache-Fixed**](#unity-claude-cache-fixed) - [**Unity-Claude-Cache-Original**](#unity-claude-cache-original) - [**Unity-Claude-ChangeIntelligence**](#unity-claude-changeintelligence) - [**Unity-Claude-ClaudeParallelization**](#unity-claude-claudeparallelization) - [**Unity-Claude-CLIOrchestrator**](#unity-claude-cliorchestrator) - [**Unity-Claude-CLIOrchestrator-Fixed-Simple**](#unity-claude-cliorchestrator-fixed-simple) - [**Unity-Claude-CLIOrchestrator-FullFeatured**](#unity-claude-cliorchestrator-fullfeatured) - [**Unity-Claude-CLIOrchestrator-Original**](#unity-claude-cliorchestrator-original) - [**Unity-Claude-CLIOrchestrator-Original-Backup**](#unity-claude-cliorchestrator-original-backup) - [**Unity-Claude-CLIOrchestrator-Refactored**](#unity-claude-cliorchestrator-refactored) - [**Unity-Claude-CLIOrchestrator-Refactored-Fixed**](#unity-claude-cliorchestrator-refactored-fixed) - [**Unity-Claude-CLISubmission**](#unity-claude-clisubmission) - [**Unity-Claude-CLISubmission-Enhanced**](#unity-claude-clisubmission-enhanced) - [**Unity-Claude-CodeQL**](#unity-claude-codeql) - [**Unity-Claude-ConcurrentCollections**](#unity-claude-concurrentcollections) - [**Unity-Claude-ConcurrentProcessor**](#unity-claude-concurrentprocessor) - [**Unity-Claude-CPG**](#unity-claude-cpg) - [**Unity-Claude-CPG-ASTConverter**](#unity-claude-cpg-astconverter) - [**Unity-Claude-CPG-Original**](#unity-claude-cpg-original) - [**Unity-Claude-CPG-Refactored**](#unity-claude-cpg-refactored) - [**Unity-Claude-CrossLanguage**](#unity-claude-crosslanguage) - [**Unity-Claude-DecisionEngine**](#unity-claude-decisionengine) - [**Unity-Claude-DecisionEngine-Bayesian**](#unity-claude-decisionengine-bayesian) - [**Unity-Claude-DecisionEngine-Original**](#unity-claude-decisionengine-original) - [**Unity-Claude-DecisionEngine-Refactored**](#unity-claude-decisionengine-refactored) - [**Unity-Claude-DocumentationAnalytics**](#unity-claude-documentationanalytics) - [**Unity-Claude-DocumentationAutomation**](#unity-claude-documentationautomation) - [**Unity-Claude-DocumentationAutomation-Original**](#unity-claude-documentationautomation-original) - [**Unity-Claude-DocumentationAutomation-Refactored**](#unity-claude-documentationautomation-refactored) - [**Unity-Claude-DocumentationCrossReference**](#unity-claude-documentationcrossreference) - [**Unity-Claude-DocumentationDrift**](#unity-claude-documentationdrift) - [**Unity-Claude-DocumentationDrift-Refactored**](#unity-claude-documentationdrift-refactored) - [**Unity-Claude-DocumentationPipeline**](#unity-claude-documentationpipeline) - [**Unity-Claude-DocumentationQualityAssessment**](#unity-claude-documentationqualityassessment) - [**Unity-Claude-DocumentationQualityAssessment_Original_20250830_193150**](#unity-claude-documentationqualityassessment-original-20250830-193150) - [**Unity-Claude-DocumentationQualityOrchestrator**](#unity-claude-documentationqualityorchestrator) - [**Unity-Claude-DocumentationSuggestions**](#unity-claude-documentationsuggestions) - [**Unity-Claude-DocumentationVersioning**](#unity-claude-documentationversioning) - [**Unity-Claude-EmailNotifications**](#unity-claude-emailnotifications) - [**Unity-Claude-EmailNotifications-SystemNetMail**](#unity-claude-emailnotifications-systemnetmail) - [**Unity-Claude-ErrorHandling**](#unity-claude-errorhandling) - [**Unity-Claude-Errors**](#unity-claude-errors) - [**Unity-Claude-EventLog**](#unity-claude-eventlog) - [**Unity-Claude-FileMonitor**](#unity-claude-filemonitor) - [**Unity-Claude-FileMonitor-Fixed**](#unity-claude-filemonitor-fixed) - [**Unity-Claude-FixEngine**](#unity-claude-fixengine) - [**Unity-Claude-GitHub**](#unity-claude-github) - [**Unity-Claude-GovernanceIntegration**](#unity-claude-governanceintegration) - [**Unity-Claude-HITL**](#unity-claude-hitl) - [**Unity-Claude-HITL-Original**](#unity-claude-hitl-original) - [**Unity-Claude-HITL-Refactored**](#unity-claude-hitl-refactored) - [**Unity-Claude-IncrementalProcessor**](#unity-claude-incrementalprocessor) - [**Unity-Claude-IncrementalProcessor-Fixed**](#unity-claude-incrementalprocessor-fixed) - [**Unity-Claude-IntegratedWorkflow**](#unity-claude-integratedworkflow) - [**Unity-Claude-IntegratedWorkflow-Original**](#unity-claude-integratedworkflow-original) - [**Unity-Claude-IntegratedWorkflow-Refactored**](#unity-claude-integratedworkflow-refactored) - [**Unity-Claude-IntegrationEngine**](#unity-claude-integrationengine) - [**Unity-Claude-IntelligentAlerting**](#unity-claude-intelligentalerting) - [**Unity-Claude-IntelligentDocumentationTriggers**](#unity-claude-intelligentdocumentationtriggers) - [**Unity-Claude-IPC**](#unity-claude-ipc) - [**Unity-Claude-IPC-Bidirectional**](#unity-claude-ipc-bidirectional) - [**Unity-Claude-IPC-Bidirectional-Fixed**](#unity-claude-ipc-bidirectional-fixed) - [**Unity-Claude-LangGraphBridge**](#unity-claude-langgraphbridge) - [**Unity-Claude-Learning**](#unity-claude-learning) - [**Unity-Claude-Learning-Analytics**](#unity-claude-learning-analytics) - [**Unity-Claude-Learning-Original**](#unity-claude-learning-original) - [**Unity-Claude-Learning-Refactored**](#unity-claude-learning-refactored) - [**Unity-Claude-Learning-Simple**](#unity-claude-learning-simple) - [**Unity-Claude-LLM**](#unity-claude-llm) - [**Unity-Claude-MachineLearning**](#unity-claude-machinelearning) - [**Unity-Claude-MasterOrchestrator**](#unity-claude-masterorchestrator) - [**Unity-Claude-MasterOrchestrator-Original**](#unity-claude-masterorchestrator-original) - [**Unity-Claude-MasterOrchestrator-Refactored**](#unity-claude-masterorchestrator-refactored) - [**Unity-Claude-MemoryAnalysis**](#unity-claude-memoryanalysis) - [**Unity-Claude-MessageQueue**](#unity-claude-messagequeue) - [**Unity-Claude-Monitoring**](#unity-claude-monitoring) - [**Unity-Claude-MultiStepOrchestrator**](#unity-claude-multisteporchestrator) - [**Unity-Claude-NotificationConfiguration**](#unity-claude-notificationconfiguration) - [**Unity-Claude-NotificationContentEngine**](#unity-claude-notificationcontentengine) - [**Unity-Claude-NotificationIntegration**](#unity-claude-notificationintegration) - [**Unity-Claude-NotificationIntegration-Modular**](#unity-claude-notificationintegration-modular) - [**Unity-Claude-NotificationPreferences**](#unity-claude-notificationpreferences) - [**Unity-Claude-ObsolescenceDetection**](#unity-claude-obsolescencedetection) - [**Unity-Claude-ObsolescenceDetection-Refactored**](#unity-claude-obsolescencedetection-refactored) - [**Unity-Claude-Ollama**](#unity-claude-ollama) - [**Unity-Claude-Ollama-Enhanced**](#unity-claude-ollama-enhanced) - [**Unity-Claude-Ollama-Optimized**](#unity-claude-ollama-optimized) - [**Unity-Claude-Ollama-Optimized-Fixed**](#unity-claude-ollama-optimized-fixed) - [**Unity-Claude-ParallelProcessing**](#unity-claude-parallelprocessing) - [**Unity-Claude-ParallelProcessor**](#unity-claude-parallelprocessor) - [**Unity-Claude-ParallelProcessor-Original**](#unity-claude-parallelprocessor-original) - [**Unity-Claude-ParallelProcessor-Refactored**](#unity-claude-parallelprocessor-refactored) - [**Unity-Claude-PerformanceOptimizer**](#unity-claude-performanceoptimizer) - [**Unity-Claude-PerformanceOptimizer-Original**](#unity-claude-performanceoptimizer-original) - [**Unity-Claude-PerformanceOptimizer-Refactored**](#unity-claude-performanceoptimizer-refactored) - [**Unity-Claude-PredictiveAnalysis**](#unity-claude-predictiveanalysis) - [**Unity-Claude-PredictiveAnalysis-Original**](#unity-claude-predictiveanalysis-original) - [**Unity-Claude-PredictiveAnalysis-Refactored**](#unity-claude-predictiveanalysis-refactored) - [**Unity-Claude-ProactiveMaintenanceEngine**](#unity-claude-proactivemaintenanceengine) - [**Unity-Claude-RealTimeAnalysis**](#unity-claude-realtimeanalysis) - [**Unity-Claude-RealTimeMonitoring**](#unity-claude-realtimemonitoring) - [**Unity-Claude-RealTimeOptimizer**](#unity-claude-realtimeoptimizer) - [**Unity-Claude-RecompileSignaling**](#unity-claude-recompilesignaling) - [**Unity-Claude-ReliabilityManager**](#unity-claude-reliabilitymanager) - [**Unity-Claude-ReliableMonitoring**](#unity-claude-reliablemonitoring) - [**Unity-Claude-RepoAnalyst**](#unity-claude-repoanalyst) - [**Unity-Claude-ResourceOptimizer**](#unity-claude-resourceoptimizer) - [**Unity-Claude-ResponseMonitor**](#unity-claude-responsemonitor) - [**Unity-Claude-ResponseMonitoring**](#unity-claude-responsemonitoring) - [**Unity-Claude-RunspaceManagement**](#unity-claude-runspacemanagement) - [**Unity-Claude-RunspaceManagement-Original**](#unity-claude-runspacemanagement-original) - [**Unity-Claude-RunspaceManagement-Refactored**](#unity-claude-runspacemanagement-refactored) - [**Unity-Claude-Safety**](#unity-claude-safety) - [**Unity-Claude-ScalabilityEnhancements**](#unity-claude-scalabilityenhancements) - [**Unity-Claude-ScalabilityEnhancements-Original**](#unity-claude-scalabilityenhancements-original) - [**Unity-Claude-ScalabilityEnhancements-Refactored**](#unity-claude-scalabilityenhancements-refactored) - [**Unity-Claude-ScalabilityOptimizer**](#unity-claude-scalabilityoptimizer) - [**Unity-Claude-SemanticAnalysis**](#unity-claude-semanticanalysis) - [**Unity-Claude-SemanticAnalysis-Architecture**](#unity-claude-semanticanalysis-architecture) - [**Unity-Claude-SemanticAnalysis-Business**](#unity-claude-semanticanalysis-business) - [**Unity-Claude-SemanticAnalysis-Helpers**](#unity-claude-semanticanalysis-helpers) - [**Unity-Claude-SemanticAnalysis-Metrics**](#unity-claude-semanticanalysis-metrics) - [**Unity-Claude-SemanticAnalysis-New**](#unity-claude-semanticanalysis-new) - [**Unity-Claude-SemanticAnalysis-Old**](#unity-claude-semanticanalysis-old) - [**Unity-Claude-SemanticAnalysis-Patterns**](#unity-claude-semanticanalysis-patterns) - [**Unity-Claude-SemanticAnalysis-Purpose**](#unity-claude-semanticanalysis-purpose) - [**Unity-Claude-SemanticAnalysis-Quality**](#unity-claude-semanticanalysis-quality) - [**Unity-Claude-SessionManager**](#unity-claude-sessionmanager) - [**Unity-Claude-SlackIntegration**](#unity-claude-slackintegration) - [**Unity-Claude-SystemCoordinator**](#unity-claude-systemcoordinator) - [**Unity-Claude-SystemStatus**](#unity-claude-systemstatus) - [**Unity-Claude-TeamsIntegration**](#unity-claude-teamsintegration) - [**Unity-Claude-TreeSitter**](#unity-claude-treesitter) - [**Unity-Claude-TriggerConditions**](#unity-claude-triggerconditions) - [**Unity-Claude-TriggerIntegration**](#unity-claude-triggerintegration) - [**Unity-Claude-TriggerManager**](#unity-claude-triggermanager) - [**Unity-Claude-UnityParallelization**](#unity-claude-unityparallelization) - [**Unity-Claude-UnityParallelization-Original**](#unity-claude-unityparallelization-original) - [**Unity-Claude-UnityParallelization-Refactored**](#unity-claude-unityparallelization-refactored) - [**Unity-Claude-WebhookNotifications**](#unity-claude-webhooknotifications) - [**Unity-Claude-WindowDetection**](#unity-claude-windowdetection) - [**Unity-Claude-WindowDetection-Enhanced**](#unity-claude-windowdetection-enhanced) - [**Unity-TestAutomation**](#unity-testautomation) - [**UnityBuildOperations**](#unitybuildoperations) - [**UnityCommands**](#unitycommands) - [**UnityIntegration**](#unityintegration) - [**UnityLogAnalysis**](#unityloganalysis) - [**UnityPerformanceAnalysis**](#unityperformanceanalysis) - [**UnityProjectOperations**](#unityprojectoperations) - [**UnityReportingOperations**](#unityreportingoperations) 
### 🎯 Orchestration & Control

**Modules:** 32 | **Functions:** 235

- [**AgentLogging**](#agentlogging) - [**AutomationEngine**](#automationengine) - [**CLIAutomation**](#cliautomation) - [**OrchestrationCore**](#orchestrationcore) - [**OrchestrationManager**](#orchestrationmanager) - [**OrchestrationManager-Refactored**](#orchestrationmanager-refactored) - [**OrchestratorCore**](#orchestratorcore) - [**OrchestratorManagement**](#orchestratormanagement) - [**Unity-Claude-AgentIntegration**](#unity-claude-agentintegration) - [**Unity-Claude-AutonomousAgent-Refactored**](#unity-claude-autonomousagent-refactored) - [**Unity-Claude-CLIOrchestrator**](#unity-claude-cliorchestrator) - [**Unity-Claude-CLIOrchestrator-Fixed-Simple**](#unity-claude-cliorchestrator-fixed-simple) - [**Unity-Claude-CLIOrchestrator-FullFeatured**](#unity-claude-cliorchestrator-fullfeatured) - [**Unity-Claude-CLIOrchestrator-Original**](#unity-claude-cliorchestrator-original) - [**Unity-Claude-CLIOrchestrator-Original-Backup**](#unity-claude-cliorchestrator-original-backup) - [**Unity-Claude-CLIOrchestrator-Refactored**](#unity-claude-cliorchestrator-refactored) - [**Unity-Claude-CLIOrchestrator-Refactored-Fixed**](#unity-claude-cliorchestrator-refactored-fixed) - [**Unity-Claude-DocumentationAutomation**](#unity-claude-documentationautomation) - [**Unity-Claude-DocumentationAutomation-Original**](#unity-claude-documentationautomation-original) - [**Unity-Claude-DocumentationAutomation-Refactored**](#unity-claude-documentationautomation-refactored) - [**Unity-Claude-DocumentationQualityOrchestrator**](#unity-claude-documentationqualityorchestrator) - [**Unity-Claude-IntegratedWorkflow**](#unity-claude-integratedworkflow) - [**Unity-Claude-IntegratedWorkflow-Original**](#unity-claude-integratedworkflow-original) - [**Unity-Claude-IntegratedWorkflow-Refactored**](#unity-claude-integratedworkflow-refactored) - [**Unity-Claude-MasterOrchestrator**](#unity-claude-masterorchestrator) - [**Unity-Claude-MasterOrchestrator-Original**](#unity-claude-masterorchestrator-original) - [**Unity-Claude-MasterOrchestrator-Refactored**](#unity-claude-masterorchestrator-refactored) - [**Unity-Claude-MultiStepOrchestrator**](#unity-claude-multisteporchestrator) - [**Unity-TestAutomation**](#unity-testautomation) - [**WorkflowIntegration**](#workflowintegration) - [**WorkflowMonitoring**](#workflowmonitoring) - [**WorkflowOrchestration**](#workfloworchestration) 
### 🏗️ Core Infrastructure

**Modules:** 22 | **Functions:** 96

- [**BayesianConfiguration**](#bayesianconfiguration) - [**Configuration**](#configuration) - [**ConfigurationLogging**](#configurationlogging) - [**ConfigurationManagement**](#configurationmanagement) - [**DatabaseManagement**](#databasemanagement) - [**DecisionEngineCore**](#decisionenginecore) - [**HITLCore**](#hitlcore) - [**NotificationCore**](#notificationcore) - [**OptimizerConfiguration**](#optimizerconfiguration) - [**OrchestrationCore**](#orchestrationcore) - [**OrchestratorCore**](#orchestratorcore) - [**ParallelizationCore**](#parallelizationcore) - [**ProjectConfiguration**](#projectconfiguration) - [**PromptConfiguration**](#promptconfiguration) - [**ResponseAnalysisEngine-Core**](#responseanalysisengine-core) - [**RuleBasedDecisionTrees**](#rulebaseddecisiontrees) - [**RunspaceCore**](#runspacecore) - [**SafeCommandCore**](#safecommandcore) - [**SessionStateConfiguration**](#sessionstateconfiguration) - [**StateConfiguration**](#stateconfiguration) - [**StateMachineCore**](#statemachinecore) - [**Unity-Claude-NotificationConfiguration**](#unity-claude-notificationconfiguration) 
### 📊 Monitoring & Analytics

**Modules:** 38 | **Functions:** 447

- [**CodeComplexityMetrics**](#codecomplexitymetrics) - [**FileSystemMonitoring**](#filesystemmonitoring) - [**HealthMonitoring**](#healthmonitoring) - [**IntegratedNotifications**](#integratednotifications) - [**MetricsAndHealthCheck**](#metricsandhealthcheck) - [**MetricsCollection**](#metricscollection) - [**MonitoringLoop**](#monitoringloop) - [**NotificationCore**](#notificationcore) - [**NotificationSystem**](#notificationsystem) - [**ParallelMonitoring**](#parallelmonitoring) - [**PerformanceMonitoring**](#performancemonitoring) - [**ResponseMonitoring**](#responsemonitoring) - [**SemanticAnalysis-Metrics**](#semanticanalysis-metrics) - [**Unity-Claude-AIAlertClassifier**](#unity-claude-aialertclassifier) - [**Unity-Claude-AlertAnalytics**](#unity-claude-alertanalytics) - [**Unity-Claude-AlertFeedbackCollector**](#unity-claude-alertfeedbackcollector) - [**Unity-Claude-AlertMLOptimizer**](#unity-claude-alertmloptimizer) - [**Unity-Claude-AlertQualityReporting**](#unity-claude-alertqualityreporting) - [**Unity-Claude-AutoGenMonitoring**](#unity-claude-autogenmonitoring) - [**Unity-Claude-EmailNotifications**](#unity-claude-emailnotifications) - [**Unity-Claude-EmailNotifications-SystemNetMail**](#unity-claude-emailnotifications-systemnetmail) - [**Unity-Claude-FileMonitor**](#unity-claude-filemonitor) - [**Unity-Claude-FileMonitor-Fixed**](#unity-claude-filemonitor-fixed) - [**Unity-Claude-IntelligentAlerting**](#unity-claude-intelligentalerting) - [**Unity-Claude-Monitoring**](#unity-claude-monitoring) - [**Unity-Claude-NotificationConfiguration**](#unity-claude-notificationconfiguration) - [**Unity-Claude-NotificationContentEngine**](#unity-claude-notificationcontentengine) - [**Unity-Claude-NotificationIntegration**](#unity-claude-notificationintegration) - [**Unity-Claude-NotificationIntegration-Modular**](#unity-claude-notificationintegration-modular) - [**Unity-Claude-NotificationPreferences**](#unity-claude-notificationpreferences) - [**Unity-Claude-RealTimeMonitoring**](#unity-claude-realtimemonitoring) - [**Unity-Claude-ReliableMonitoring**](#unity-claude-reliablemonitoring) - [**Unity-Claude-ResponseMonitor**](#unity-claude-responsemonitor) - [**Unity-Claude-ResponseMonitoring**](#unity-claude-responsemonitoring) - [**Unity-Claude-SemanticAnalysis-Metrics**](#unity-claude-semanticanalysis-metrics) - [**Unity-Claude-SystemStatus**](#unity-claude-systemstatus) - [**Unity-Claude-WebhookNotifications**](#unity-claude-webhooknotifications) - [**WorkflowMonitoring**](#workflowmonitoring) 
### 📚 Documentation System

**Modules:** 35 | **Functions:** 410

- [**AnalyticsReporting**](#analyticsreporting) - [**DocumentationAccuracy**](#documentationaccuracy) - [**DocumentationComparison**](#documentationcomparison) - [**ReportingExport**](#reportingexport) - [**SemanticAnalysis-Metrics**](#semanticanalysis-metrics) - [**SemanticAnalysis-PatternDetector**](#semanticanalysis-patterndetector) - [**SemanticAnalysis-PatternDetector-PS51Compatible**](#semanticanalysis-patterndetector-ps51compatible) - [**Unity-Claude-AlertQualityReporting**](#unity-claude-alertqualityreporting) - [**Unity-Claude-APIDocumentation**](#unity-claude-apidocumentation) - [**Unity-Claude-AutonomousDocumentationEngine**](#unity-claude-autonomousdocumentationengine) - [**Unity-Claude-DocumentationAnalytics**](#unity-claude-documentationanalytics) - [**Unity-Claude-DocumentationAutomation**](#unity-claude-documentationautomation) - [**Unity-Claude-DocumentationAutomation-Original**](#unity-claude-documentationautomation-original) - [**Unity-Claude-DocumentationAutomation-Refactored**](#unity-claude-documentationautomation-refactored) - [**Unity-Claude-DocumentationCrossReference**](#unity-claude-documentationcrossreference) - [**Unity-Claude-DocumentationDrift**](#unity-claude-documentationdrift) - [**Unity-Claude-DocumentationDrift-Refactored**](#unity-claude-documentationdrift-refactored) - [**Unity-Claude-DocumentationPipeline**](#unity-claude-documentationpipeline) - [**Unity-Claude-DocumentationQualityAssessment**](#unity-claude-documentationqualityassessment) - [**Unity-Claude-DocumentationQualityAssessment_Original_20250830_193150**](#unity-claude-documentationqualityassessment-original-20250830-193150) - [**Unity-Claude-DocumentationQualityOrchestrator**](#unity-claude-documentationqualityorchestrator) - [**Unity-Claude-DocumentationSuggestions**](#unity-claude-documentationsuggestions) - [**Unity-Claude-DocumentationVersioning**](#unity-claude-documentationversioning) - [**Unity-Claude-IntelligentDocumentationTriggers**](#unity-claude-intelligentdocumentationtriggers) - [**Unity-Claude-SemanticAnalysis**](#unity-claude-semanticanalysis) - [**Unity-Claude-SemanticAnalysis-Architecture**](#unity-claude-semanticanalysis-architecture) - [**Unity-Claude-SemanticAnalysis-Business**](#unity-claude-semanticanalysis-business) - [**Unity-Claude-SemanticAnalysis-Helpers**](#unity-claude-semanticanalysis-helpers) - [**Unity-Claude-SemanticAnalysis-Metrics**](#unity-claude-semanticanalysis-metrics) - [**Unity-Claude-SemanticAnalysis-New**](#unity-claude-semanticanalysis-new) - [**Unity-Claude-SemanticAnalysis-Old**](#unity-claude-semanticanalysis-old) - [**Unity-Claude-SemanticAnalysis-Patterns**](#unity-claude-semanticanalysis-patterns) - [**Unity-Claude-SemanticAnalysis-Purpose**](#unity-claude-semanticanalysis-purpose) - [**Unity-Claude-SemanticAnalysis-Quality**](#unity-claude-semanticanalysis-quality) - [**UnityReportingOperations**](#unityreportingoperations) 
### 🔒 Safety & Validation

**Modules:** 9 | **Functions:** 46

- [**ApprovalRequests**](#approvalrequests) - [**HITLCore**](#hitlcore) - [**SafetyValidationFramework**](#safetyvalidationframework) - [**SecurityTokens**](#securitytokens) - [**Unity-Claude-HITL**](#unity-claude-hitl) - [**Unity-Claude-HITL-Original**](#unity-claude-hitl-original) - [**Unity-Claude-HITL-Refactored**](#unity-claude-hitl-refactored) - [**Unity-Claude-Safety**](#unity-claude-safety) - [**ValidationEngine**](#validationengine) 
### 🔧 Integration & Tools

**Modules:** 22 | **Functions:** 172

- [**BackupIntegration**](#backupintegration) - [**ClaudeIntegration**](#claudeintegration) - [**CompilationIntegration**](#compilationintegration) - [**DecisionEngineIntegration**](#decisionengineintegration) - [**EnhancedPatternIntegration**](#enhancedpatternintegration) - [**GitHubPRManager**](#githubprmanager) - [**IntegrationManagement**](#integrationmanagement) - [**ModuleIntegration**](#moduleintegration) - [**SystemIntegration**](#systemintegration) - [**Unity-Claude-AgentIntegration**](#unity-claude-agentintegration) - [**Unity-Claude-EmailNotifications**](#unity-claude-emailnotifications) - [**Unity-Claude-EmailNotifications-SystemNetMail**](#unity-claude-emailnotifications-systemnetmail) - [**Unity-Claude-GitHub**](#unity-claude-github) - [**Unity-Claude-GovernanceIntegration**](#unity-claude-governanceintegration) - [**Unity-Claude-IntegrationEngine**](#unity-claude-integrationengine) - [**Unity-Claude-NotificationIntegration**](#unity-claude-notificationintegration) - [**Unity-Claude-NotificationIntegration-Modular**](#unity-claude-notificationintegration-modular) - [**Unity-Claude-SlackIntegration**](#unity-claude-slackintegration) - [**Unity-Claude-TeamsIntegration**](#unity-claude-teamsintegration) - [**Unity-Claude-TriggerIntegration**](#unity-claude-triggerintegration) - [**UnityIntegration**](#unityintegration) - [**WorkflowIntegration**](#workflowintegration) 
### 🤖 AI & Intelligence

**Modules:** 188 | **Functions:** 2285

- [**AIAssessment**](#aiassessment) - [**BayesianConfidenceEngine**](#bayesianconfidenceengine) - [**BayesianConfiguration**](#bayesianconfiguration) - [**BayesianInference**](#bayesianinference) - [**ClaudeIntegration**](#claudeintegration) - [**DecisionEngine**](#decisionengine) - [**DecisionEngine-Bayesian**](#decisionengine-bayesian) - [**DecisionEngine-Bayesian-Refactored**](#decisionengine-bayesian-refactored) - [**DecisionEngine-Refactored**](#decisionengine-refactored) - [**DecisionEngineCore**](#decisionenginecore) - [**DecisionEngineIntegration**](#decisionengineintegration) - [**DecisionExecution**](#decisionexecution) - [**DecisionExecution-Fixed**](#decisionexecution-fixed) - [**DecisionMaking**](#decisionmaking) - [**DecisionMaking-Fixed**](#decisionmaking-fixed) - [**EnhancedPatternIntegration**](#enhancedpatternintegration) - [**FailureMode**](#failuremode) - [**LearningAdaptation**](#learningadaptation) - [**MaintenancePrediction**](#maintenanceprediction) - [**PatternAnalysis**](#patternanalysis) - [**PatternRecognition**](#patternrecognition) - [**PatternRecognitionEngine**](#patternrecognitionengine) - [**PatternRecognitionEngine-Fixed**](#patternrecognitionengine-fixed) - [**PatternRecognitionEngine-New**](#patternrecognitionengine-new) - [**PatternRecognitionEngine-Original**](#patternrecognitionengine-original) - [**Predictive-Maintenance**](#predictive-maintenance) - [**RecommendationPatternEngine**](#recommendationpatternengine) - [**RuleBasedDecisionTrees**](#rulebaseddecisiontrees) - [**SemanticAnalysis-PatternDetector**](#semanticanalysis-patterndetector) - [**SemanticAnalysis-PatternDetector-PS51Compatible**](#semanticanalysis-patterndetector-ps51compatible) - [**Unity-Claude-AgentIntegration**](#unity-claude-agentintegration) - [**Unity-Claude-AIAlertClassifier**](#unity-claude-aialertclassifier) - [**Unity-Claude-AlertAnalytics**](#unity-claude-alertanalytics) - [**Unity-Claude-AlertFeedbackCollector**](#unity-claude-alertfeedbackcollector) - [**Unity-Claude-AlertMLOptimizer**](#unity-claude-alertmloptimizer) - [**Unity-Claude-AlertQualityReporting**](#unity-claude-alertqualityreporting) - [**Unity-Claude-APIDocumentation**](#unity-claude-apidocumentation) - [**Unity-Claude-AST-Enhanced**](#unity-claude-ast-enhanced) - [**Unity-Claude-AutoGen**](#unity-claude-autogen) - [**Unity-Claude-AutoGenMonitoring**](#unity-claude-autogenmonitoring) - [**Unity-Claude-AutonomousAgent-Refactored**](#unity-claude-autonomousagent-refactored) - [**Unity-Claude-AutonomousDocumentationEngine**](#unity-claude-autonomousdocumentationengine) - [**Unity-Claude-AutonomousStateTracker**](#unity-claude-autonomousstatetracker) - [**Unity-Claude-AutonomousStateTracker-Enhanced**](#unity-claude-autonomousstatetracker-enhanced) - [**Unity-Claude-AutonomousStateTracker-Enhanced-Refactored**](#unity-claude-autonomousstatetracker-enhanced-refactored) - [**Unity-Claude-Cache**](#unity-claude-cache) - [**Unity-Claude-Cache-Fixed**](#unity-claude-cache-fixed) - [**Unity-Claude-Cache-Original**](#unity-claude-cache-original) - [**Unity-Claude-ChangeIntelligence**](#unity-claude-changeintelligence) - [**Unity-Claude-ClaudeParallelization**](#unity-claude-claudeparallelization) - [**Unity-Claude-CLIOrchestrator**](#unity-claude-cliorchestrator) - [**Unity-Claude-CLIOrchestrator-Fixed-Simple**](#unity-claude-cliorchestrator-fixed-simple) - [**Unity-Claude-CLIOrchestrator-FullFeatured**](#unity-claude-cliorchestrator-fullfeatured) - [**Unity-Claude-CLIOrchestrator-Original**](#unity-claude-cliorchestrator-original) - [**Unity-Claude-CLIOrchestrator-Original-Backup**](#unity-claude-cliorchestrator-original-backup) - [**Unity-Claude-CLIOrchestrator-Refactored**](#unity-claude-cliorchestrator-refactored) - [**Unity-Claude-CLIOrchestrator-Refactored-Fixed**](#unity-claude-cliorchestrator-refactored-fixed) - [**Unity-Claude-CLISubmission**](#unity-claude-clisubmission) - [**Unity-Claude-CLISubmission-Enhanced**](#unity-claude-clisubmission-enhanced) - [**Unity-Claude-CodeQL**](#unity-claude-codeql) - [**Unity-Claude-ConcurrentCollections**](#unity-claude-concurrentcollections) - [**Unity-Claude-ConcurrentProcessor**](#unity-claude-concurrentprocessor) - [**Unity-Claude-CPG**](#unity-claude-cpg) - [**Unity-Claude-CPG-ASTConverter**](#unity-claude-cpg-astconverter) - [**Unity-Claude-CPG-Original**](#unity-claude-cpg-original) - [**Unity-Claude-CPG-Refactored**](#unity-claude-cpg-refactored) - [**Unity-Claude-CrossLanguage**](#unity-claude-crosslanguage) - [**Unity-Claude-DecisionEngine**](#unity-claude-decisionengine) - [**Unity-Claude-DecisionEngine-Bayesian**](#unity-claude-decisionengine-bayesian) - [**Unity-Claude-DecisionEngine-Original**](#unity-claude-decisionengine-original) - [**Unity-Claude-DecisionEngine-Refactored**](#unity-claude-decisionengine-refactored) - [**Unity-Claude-DocumentationAnalytics**](#unity-claude-documentationanalytics) - [**Unity-Claude-DocumentationAutomation**](#unity-claude-documentationautomation) - [**Unity-Claude-DocumentationAutomation-Original**](#unity-claude-documentationautomation-original) - [**Unity-Claude-DocumentationAutomation-Refactored**](#unity-claude-documentationautomation-refactored) - [**Unity-Claude-DocumentationCrossReference**](#unity-claude-documentationcrossreference) - [**Unity-Claude-DocumentationDrift**](#unity-claude-documentationdrift) - [**Unity-Claude-DocumentationDrift-Refactored**](#unity-claude-documentationdrift-refactored) - [**Unity-Claude-DocumentationPipeline**](#unity-claude-documentationpipeline) - [**Unity-Claude-DocumentationQualityAssessment**](#unity-claude-documentationqualityassessment) - [**Unity-Claude-DocumentationQualityAssessment_Original_20250830_193150**](#unity-claude-documentationqualityassessment-original-20250830-193150) - [**Unity-Claude-DocumentationQualityOrchestrator**](#unity-claude-documentationqualityorchestrator) - [**Unity-Claude-DocumentationSuggestions**](#unity-claude-documentationsuggestions) - [**Unity-Claude-DocumentationVersioning**](#unity-claude-documentationversioning) - [**Unity-Claude-EmailNotifications**](#unity-claude-emailnotifications) - [**Unity-Claude-EmailNotifications-SystemNetMail**](#unity-claude-emailnotifications-systemnetmail) - [**Unity-Claude-ErrorHandling**](#unity-claude-errorhandling) - [**Unity-Claude-Errors**](#unity-claude-errors) - [**Unity-Claude-EventLog**](#unity-claude-eventlog) - [**Unity-Claude-FileMonitor**](#unity-claude-filemonitor) - [**Unity-Claude-FileMonitor-Fixed**](#unity-claude-filemonitor-fixed) - [**Unity-Claude-FixEngine**](#unity-claude-fixengine) - [**Unity-Claude-GitHub**](#unity-claude-github) - [**Unity-Claude-GovernanceIntegration**](#unity-claude-governanceintegration) - [**Unity-Claude-HITL**](#unity-claude-hitl) - [**Unity-Claude-HITL-Original**](#unity-claude-hitl-original) - [**Unity-Claude-HITL-Refactored**](#unity-claude-hitl-refactored) - [**Unity-Claude-IncrementalProcessor**](#unity-claude-incrementalprocessor) - [**Unity-Claude-IncrementalProcessor-Fixed**](#unity-claude-incrementalprocessor-fixed) - [**Unity-Claude-IntegratedWorkflow**](#unity-claude-integratedworkflow) - [**Unity-Claude-IntegratedWorkflow-Original**](#unity-claude-integratedworkflow-original) - [**Unity-Claude-IntegratedWorkflow-Refactored**](#unity-claude-integratedworkflow-refactored) - [**Unity-Claude-IntegrationEngine**](#unity-claude-integrationengine) - [**Unity-Claude-IntelligentAlerting**](#unity-claude-intelligentalerting) - [**Unity-Claude-IntelligentDocumentationTriggers**](#unity-claude-intelligentdocumentationtriggers) - [**Unity-Claude-IPC**](#unity-claude-ipc) - [**Unity-Claude-IPC-Bidirectional**](#unity-claude-ipc-bidirectional) - [**Unity-Claude-IPC-Bidirectional-Fixed**](#unity-claude-ipc-bidirectional-fixed) - [**Unity-Claude-LangGraphBridge**](#unity-claude-langgraphbridge) - [**Unity-Claude-Learning**](#unity-claude-learning) - [**Unity-Claude-Learning-Analytics**](#unity-claude-learning-analytics) - [**Unity-Claude-Learning-Original**](#unity-claude-learning-original) - [**Unity-Claude-Learning-Refactored**](#unity-claude-learning-refactored) - [**Unity-Claude-Learning-Simple**](#unity-claude-learning-simple) - [**Unity-Claude-LLM**](#unity-claude-llm) - [**Unity-Claude-MachineLearning**](#unity-claude-machinelearning) - [**Unity-Claude-MasterOrchestrator**](#unity-claude-masterorchestrator) - [**Unity-Claude-MasterOrchestrator-Original**](#unity-claude-masterorchestrator-original) - [**Unity-Claude-MasterOrchestrator-Refactored**](#unity-claude-masterorchestrator-refactored) - [**Unity-Claude-MemoryAnalysis**](#unity-claude-memoryanalysis) - [**Unity-Claude-MessageQueue**](#unity-claude-messagequeue) - [**Unity-Claude-Monitoring**](#unity-claude-monitoring) - [**Unity-Claude-MultiStepOrchestrator**](#unity-claude-multisteporchestrator) - [**Unity-Claude-NotificationConfiguration**](#unity-claude-notificationconfiguration) - [**Unity-Claude-NotificationContentEngine**](#unity-claude-notificationcontentengine) - [**Unity-Claude-NotificationIntegration**](#unity-claude-notificationintegration) - [**Unity-Claude-NotificationIntegration-Modular**](#unity-claude-notificationintegration-modular) - [**Unity-Claude-NotificationPreferences**](#unity-claude-notificationpreferences) - [**Unity-Claude-ObsolescenceDetection**](#unity-claude-obsolescencedetection) - [**Unity-Claude-ObsolescenceDetection-Refactored**](#unity-claude-obsolescencedetection-refactored) - [**Unity-Claude-Ollama**](#unity-claude-ollama) - [**Unity-Claude-Ollama-Enhanced**](#unity-claude-ollama-enhanced) - [**Unity-Claude-Ollama-Optimized**](#unity-claude-ollama-optimized) - [**Unity-Claude-Ollama-Optimized-Fixed**](#unity-claude-ollama-optimized-fixed) - [**Unity-Claude-ParallelProcessing**](#unity-claude-parallelprocessing) - [**Unity-Claude-ParallelProcessor**](#unity-claude-parallelprocessor) - [**Unity-Claude-ParallelProcessor-Original**](#unity-claude-parallelprocessor-original) - [**Unity-Claude-ParallelProcessor-Refactored**](#unity-claude-parallelprocessor-refactored) - [**Unity-Claude-PerformanceOptimizer**](#unity-claude-performanceoptimizer) - [**Unity-Claude-PerformanceOptimizer-Original**](#unity-claude-performanceoptimizer-original) - [**Unity-Claude-PerformanceOptimizer-Refactored**](#unity-claude-performanceoptimizer-refactored) - [**Unity-Claude-PredictiveAnalysis**](#unity-claude-predictiveanalysis) - [**Unity-Claude-PredictiveAnalysis-Original**](#unity-claude-predictiveanalysis-original) - [**Unity-Claude-PredictiveAnalysis-Refactored**](#unity-claude-predictiveanalysis-refactored) - [**Unity-Claude-ProactiveMaintenanceEngine**](#unity-claude-proactivemaintenanceengine) - [**Unity-Claude-RealTimeAnalysis**](#unity-claude-realtimeanalysis) - [**Unity-Claude-RealTimeMonitoring**](#unity-claude-realtimemonitoring) - [**Unity-Claude-RealTimeOptimizer**](#unity-claude-realtimeoptimizer) - [**Unity-Claude-RecompileSignaling**](#unity-claude-recompilesignaling) - [**Unity-Claude-ReliabilityManager**](#unity-claude-reliabilitymanager) - [**Unity-Claude-ReliableMonitoring**](#unity-claude-reliablemonitoring) - [**Unity-Claude-RepoAnalyst**](#unity-claude-repoanalyst) - [**Unity-Claude-ResourceOptimizer**](#unity-claude-resourceoptimizer) - [**Unity-Claude-ResponseMonitor**](#unity-claude-responsemonitor) - [**Unity-Claude-ResponseMonitoring**](#unity-claude-responsemonitoring) - [**Unity-Claude-RunspaceManagement**](#unity-claude-runspacemanagement) - [**Unity-Claude-RunspaceManagement-Original**](#unity-claude-runspacemanagement-original) - [**Unity-Claude-RunspaceManagement-Refactored**](#unity-claude-runspacemanagement-refactored) - [**Unity-Claude-Safety**](#unity-claude-safety) - [**Unity-Claude-ScalabilityEnhancements**](#unity-claude-scalabilityenhancements) - [**Unity-Claude-ScalabilityEnhancements-Original**](#unity-claude-scalabilityenhancements-original) - [**Unity-Claude-ScalabilityEnhancements-Refactored**](#unity-claude-scalabilityenhancements-refactored) - [**Unity-Claude-ScalabilityOptimizer**](#unity-claude-scalabilityoptimizer) - [**Unity-Claude-SemanticAnalysis**](#unity-claude-semanticanalysis) - [**Unity-Claude-SemanticAnalysis-Architecture**](#unity-claude-semanticanalysis-architecture) - [**Unity-Claude-SemanticAnalysis-Business**](#unity-claude-semanticanalysis-business) - [**Unity-Claude-SemanticAnalysis-Helpers**](#unity-claude-semanticanalysis-helpers) - [**Unity-Claude-SemanticAnalysis-Metrics**](#unity-claude-semanticanalysis-metrics) - [**Unity-Claude-SemanticAnalysis-New**](#unity-claude-semanticanalysis-new) - [**Unity-Claude-SemanticAnalysis-Old**](#unity-claude-semanticanalysis-old) - [**Unity-Claude-SemanticAnalysis-Patterns**](#unity-claude-semanticanalysis-patterns) - [**Unity-Claude-SemanticAnalysis-Purpose**](#unity-claude-semanticanalysis-purpose) - [**Unity-Claude-SemanticAnalysis-Quality**](#unity-claude-semanticanalysis-quality) - [**Unity-Claude-SessionManager**](#unity-claude-sessionmanager) - [**Unity-Claude-SlackIntegration**](#unity-claude-slackintegration) - [**Unity-Claude-SystemCoordinator**](#unity-claude-systemcoordinator) - [**Unity-Claude-SystemStatus**](#unity-claude-systemstatus) - [**Unity-Claude-TeamsIntegration**](#unity-claude-teamsintegration) - [**Unity-Claude-TreeSitter**](#unity-claude-treesitter) - [**Unity-Claude-TriggerConditions**](#unity-claude-triggerconditions) - [**Unity-Claude-TriggerIntegration**](#unity-claude-triggerintegration) - [**Unity-Claude-TriggerManager**](#unity-claude-triggermanager) - [**Unity-Claude-UnityParallelization**](#unity-claude-unityparallelization) - [**Unity-Claude-UnityParallelization-Original**](#unity-claude-unityparallelization-original) - [**Unity-Claude-UnityParallelization-Refactored**](#unity-claude-unityparallelization-refactored) - [**Unity-Claude-WebhookNotifications**](#unity-claude-webhooknotifications) - [**Unity-Claude-WindowDetection**](#unity-claude-windowdetection) - [**Unity-Claude-WindowDetection-Enhanced**](#unity-claude-windowdetection-enhanced)

---

## 🤖 Critical Modules (AI-Enhanced)

These modules received detailed AI analysis due to their critical importance:



## 📋 Standard Modules

These modules use pattern-based documentation for efficiency:


### ActionExecutionEngine

[⬆ Back to Contents](#-table-of-contents)

Specialized module providing targeted functionality for the Unity-Claude automation system. Integrates with the broader architecture to deliver specific capabilities.

**Key Capabilities:** specialized operations, validation and testing, resource creation

**Module Statistics:**
- Functions: 11
- Lines of Code: 673
- Exported Members: 2


**Module Details:**
- **Path:** `Modules\Unity-Claude-CLIOrchestrator\Core\ActionExecutionEngine.psm1`
- **Size:** 23.53 KB
- **Functions:** 11
- **Last Modified:** 2025-08-25 13:45

**Dependencies:** CPG-DataStructures, CrossLanguage-DependencyMaps, Unity-Claude-PerformanceOptimizer-Original, JobScheduler, Unity-Claude-IncrementalProcessor, SafeExecution, CPG-Unified, Unity-Claude-ParallelProcessor-Original, RunspacePoolManager, Unity-Claude-Cache-Original, StatisticsTracker, ModuleFunctions, Unity-Claude-Cache, Unity-Claude-PerformanceOptimizer-Refactored, Performance-Cache, Unity-Claude-CPG-Original, Unity-Claude-IncrementalProcessor-Fixed, BatchProcessingEngine, DecisionEngine, SafetyValidationFramework, Unity-Claude-Cache-Fixed, SafeCommandExecution-Original, RunspaceManagement

--- 
### AgentLogging

[⬆ Back to Contents](#-table-of-contents)

Specialized module providing targeted functionality for the Unity-Claude automation system. Integrates with the broader architecture to deliver specific capabilities.

**Key Capabilities:** specialized operations, system initialization, action execution, cleanup operations, data retrieval

**Module Statistics:**
- Functions: 8
- Lines of Code: 399
- Exported Members: 1


**Module Details:**
- **Path:** `Modules\Unity-Claude-AutonomousAgent\Core\AgentLogging.psm1`
- **Size:** 13.12 KB
- **Functions:** 7
- **Last Modified:** 2025-08-26 11:46

**Dependencies:** CPG-DataStructures, CrossLanguage-DependencyMaps, Unity-Claude-PerformanceOptimizer-Original, Unity-Claude-IncrementalProcessor, CPG-Unified, Unity-Claude-ParallelProcessor-Original, Unity-Claude-Cache-Original, ModuleFunctions, Unity-Claude-Cache, Unity-Claude-ParallelProcessing, Unity-Claude-PerformanceOptimizer-Refactored, Performance-Cache, Unity-Claude-CPG-Original, Unity-Claude-IncrementalProcessor-Fixed, Unity-Claude-ResourceOptimizer, BatchProcessingEngine, Unity-Claude-Cache-Fixed

--- 
### AIAssessment

[⬆ Back to Contents](#-table-of-contents)

Specialized module providing targeted functionality for the Unity-Claude automation system. Integrates with the broader architecture to deliver specific capabilities.

**Key Capabilities:** specialized operations, system initialization

**Module Statistics:**
- Functions: 2
- Lines of Code: 34
- Exported Members: 1


**Module Details:**
- **Path:** `Modules\Unity-Claude-DocumentationQualityAssessment\Components\AIAssessment.psm1`
- **Size:** 0.87 KB
- **Functions:** 2
- **Last Modified:** 2025-08-30 19:31

**Dependencies:** Unity-Claude-ParallelProcessor-Original, Unity-Claude-Cache-Original, ModuleFunctions, Unity-Claude-Cache, Unity-Claude-Cache-Fixed

--- 
### AnalysisLogging

[⬆ Back to Contents](#-table-of-contents)

Specialized module providing targeted functionality for the Unity-Claude automation system. Integrates with the broader architecture to deliver specific capabilities.

**Key Capabilities:** specialized operations, configuration management, data retrieval, validation and testing

**Module Statistics:**
- Functions: 4
- Lines of Code: 169
- Exported Members: 1


**Module Details:**
- **Path:** `Modules\Unity-Claude-CLIOrchestrator\Core\Components\AnalysisLogging.psm1`
- **Size:** 5.72 KB
- **Functions:** 4
- **Last Modified:** 2025-08-26 11:46

**Dependencies:** Unity-Claude-Cache-Original, Unity-Claude-Cache, Performance-Cache, ResponseAnalysisEngine-Broken, Unity-Claude-Cache-Fixed, CircuitBreaker, JsonProcessing

--- 
### AnalyticsReporting

[⬆ Back to Contents](#-table-of-contents)

Specialized module providing targeted functionality for the Unity-Claude automation system. Integrates with the broader architecture to deliver specific capabilities.

**Key Capabilities:** data retrieval, specialized operations

**Module Statistics:**
- Functions: 9
- Lines of Code: 716
- Exported Members: 1


**Module Details:**
- **Path:** `Modules\Unity-Claude-PredictiveAnalysis\Core\AnalyticsReporting.psm1`
- **Size:** 24.71 KB
- **Functions:** 9
- **Last Modified:** 2025-08-26 11:46

**Dependencies:** CPG-DataStructures, CrossLanguage-DependencyMaps, CPG-Unified, RefactoringDetection, Unity-Claude-ParallelProcessor-Original, MetricsCollection, Unity-Claude-Cache-Original, ModuleFunctions, Unity-Claude-Cache, Unity-Claude-PredictiveAnalysis-Original, ContentAnalysis, Performance-Cache, TrendAnalysis, ImprovementRoadmaps, Unity-Claude-CPG-Original, CPG-QueryOperations, Unity-Claude-Cache-Fixed

--- 
### ApprovalRequests

[⬆ Back to Contents](#-table-of-contents)

Specialized module providing targeted functionality for the Unity-Claude automation system. Integrates with the broader architecture to deliver specific capabilities.

**Key Capabilities:** resource creation, data retrieval, configuration management, specialized operations

**Module Statistics:**
- Functions: 5
- Lines of Code: 313
- Exported Members: 1


**Module Details:**
- **Path:** `Modules\Unity-Claude-HITL\Core\ApprovalRequests.psm1`
- **Size:** 10.46 KB
- **Functions:** 5
- **Last Modified:** 2025-08-26 11:46

**Dependencies:** CPG-DataStructures, CrossLanguage-DependencyMaps, Unity-Claude-HITL-Original, CPG-Unified, Unity-Claude-Cache-Original, Unity-Claude-Cache, SecurityTokens, Performance-Cache, Unity-Claude-CPG-Original, CommandExecutionEngine, Unity-Claude-Cache-Fixed

--- 
### ASTAnalysis

[⬆ Back to Contents](#-table-of-contents)

Specialized module providing targeted functionality for the Unity-Claude automation system. Integrates with the broader architecture to deliver specific capabilities.

**Key Capabilities:** data retrieval, specialized operations

**Module Statistics:**
- Functions: 5
- Lines of Code: 313
- Exported Members: 1


**Module Details:**
- **Path:** `Modules\Unity-Claude-Learning\Core\ASTAnalysis.psm1`
- **Size:** 10.33 KB
- **Functions:** 4
- **Last Modified:** 2025-08-26 11:46

**Dependencies:** CPG-DataStructures, CrossLanguage-DependencyMaps, Unity-Claude-PerformanceOptimizer-Original, Unity-Claude-IncrementalProcessor, Performance-IncrementalUpdates, CPG-Unified, Unity-Claude-ParallelProcessor-Original, MetricsCollection, Unity-Claude-Cache-Original, Unity-Claude-Cache, SelfPatching, RunspaceCore, Unity-Claude-PerformanceOptimizer-Refactored, Performance-Cache, ProductionRunspacePool, ModuleVariablePreloading, Unity-Claude-Learning-Original, RunspacePoolManagement, Unity-Claude-CPG-Original, Unity-Claude-IncrementalProcessor-Fixed, SessionStateConfiguration, Unity-Claude-Learning-Simple, BatchProcessingEngine, SuccessTracking, Unity-Claude-Cache-Fixed, Unity-Claude-RunspaceManagement-Original, VariableSharing, ThrottlingResourceControl

--- 
### AutoGenerationTriggers

[⬆ Back to Contents](#-table-of-contents)

Specialized module providing targeted functionality for the Unity-Claude automation system. Integrates with the broader architecture to deliver specific capabilities.

**Key Capabilities:** system initialization, process initiation, process termination, specialized operations

**Module Statistics:**
- Functions: 11
- Lines of Code: 772
- Exported Members: 1


**Module Details:**
- **Path:** `Modules\Unity-Claude-Enhanced-DocumentationGenerators\Core\AutoGenerationTriggers.psm1`
- **Size:** 25.08 KB
- **Functions:** 11
- **Last Modified:** 2025-08-28 17:06

**Dependencies:** Unity-Claude-ReliableMonitoring, Unity-Claude-PerformanceOptimizer-Original, JobScheduler, Unity-Claude-IncrementalProcessor, Unity-Claude-ParallelProcessor-Original, RunspacePoolManager, Unity-Claude-Cache-Original, StatisticsTracker, ModuleFunctions, Unity-Claude-Cache, Unity-Claude-PerformanceOptimizer-Refactored, Performance-Cache, Unity-Claude-IncrementalProcessor-Fixed, Unity-Claude-LLM, BatchProcessingEngine, Templates-PerLanguage, Unity-Claude-Cache-Fixed

--- 
### AutomationEngine

[⬆ Back to Contents](#-table-of-contents)

Specialized module providing targeted functionality for the Unity-Claude automation system. Integrates with the broader architecture to deliver specific capabilities.

**Key Capabilities:** process initiation, process termination, validation and testing, data retrieval

**Module Statistics:**
- Functions: 4
- Lines of Code: 308
- Exported Members: 1


**Module Details:**
- **Path:** `Modules\Unity-Claude-DocumentationAutomation\Core\AutomationEngine.psm1`
- **Size:** 10.97 KB
- **Functions:** 4
- **Last Modified:** 2025-08-26 11:46

**Dependencies:** Unity-Claude-PerformanceOptimizer-Original, Unity-Claude-IncrementalProcessor, Unity-Claude-ParallelProcessor-Original, Unity-Claude-Cache-Original, ModuleFunctions, Unity-Claude-Cache, Unity-Claude-PerformanceOptimizer-Refactored, Unity-Claude-TriggerManager, Performance-Cache, Unity-Claude-IncrementalProcessor-Fixed, BatchProcessingEngine, TriggerSystem, Unity-Claude-Cache-Fixed, Unity-Claude-DocumentationAutomation-Original

--- 
### AutonomousFeedbackLoop

[⬆ Back to Contents](#-table-of-contents)

Autonomous operation module enabling self-directed task execution. Implements goal-seeking behavior, state management, and recovery mechanisms.

**Key Capabilities:** process initiation, process termination, data retrieval, validation and testing, specialized operations

**Module Statistics:**
- Functions: 5
- Lines of Code: 333
- Exported Members: 1


**Module Details:**
- **Path:** `Modules\Unity-Claude-MasterOrchestrator\Core\AutonomousFeedbackLoop.psm1`
- **Size:** 12.19 KB
- **Functions:** 5
- **Last Modified:** 2025-08-26 11:46

**Dependencies:** Unity-Claude-PerformanceOptimizer-Original, Unity-Claude-IncrementalProcessor, Unity-Claude-MasterOrchestrator-Original, Unity-Claude-ParallelProcessor-Original, ModuleIntegration, Unity-Claude-Cache-Original, ModuleFunctions, Unity-Claude-Cache, Unity-Claude-PerformanceOptimizer-Refactored, Performance-Cache, Unity-Claude-IncrementalProcessor-Fixed, Unity-Claude-IntegrationEngine, BatchProcessingEngine, OrchestratorCore, EventProcessing, Unity-Claude-Cache-Fixed, Unity-Claude-CLISubmission

--- 
### AutonomousOperations

[⬆ Back to Contents](#-table-of-contents)

Autonomous operation module enabling self-directed task execution. Implements goal-seeking behavior, state management, and recovery mechanisms.

**Key Capabilities:** resource creation, data retrieval, specialized operations, action execution

**Module Statistics:**
- Functions: 4
- Lines of Code: 794
- Exported Members: 1


**Module Details:**
- **Path:** `Modules\Unity-Claude-CLIOrchestrator\Core\AutonomousOperations.psm1`
- **Size:** 34.64 KB
- **Functions:** 4
- **Last Modified:** 2025-08-27 14:32

**Dependencies:** Unity-Claude-PerformanceOptimizer-Original, Unity-Claude-IncrementalProcessor, Unity-Claude-ParallelProcessor-Original, Unity-Claude-Cache-Original, PromptSubmissionEngine, Unity-Claude-Cache, Unity-Claude-CLIOrchestrator-Fixed-Simple, Unity-Claude-PerformanceOptimizer-Refactored, Performance-Cache, Unity-Claude-IncrementalProcessor-Fixed, ResponseAnalysisEngine-Broken, BatchProcessingEngine, Unity-Claude-Cache-Fixed, Unity-Claude-CLIOrchestrator-Original, Unity-Claude-CLISubmission

--- 
### BackgroundJobQueue

[⬆ Back to Contents](#-table-of-contents)

Specialized module providing targeted functionality for the Unity-Claude automation system. Integrates with the broader architecture to deliver specific capabilities.

**Key Capabilities:** resource creation, specialized operations, process initiation, process termination, data retrieval

**Module Statistics:**
- Functions: 8
- Lines of Code: 377
- Classes: 1
- Exported Members: 1


**Module Details:**
- **Path:** `Modules\Unity-Claude-ScalabilityEnhancements\Core\BackgroundJobQueue.psm1`
- **Size:** 11.85 KB
- **Functions:** 15
- **Last Modified:** 2025-08-26 11:46

**Dependencies:** CPG-DataStructures, CrossLanguage-DependencyMaps, Unity-Claude-PerformanceOptimizer-Original, Unity-Claude-IncrementalProcessor, CPG-Unified, Unity-Claude-ParallelProcessor-Original, Unity-Claude-Cache-Original, Unity-Claude-IPC-Bidirectional-Fixed, Unity-Claude-Cache, Unity-Claude-PerformanceOptimizer-Refactored, Performance-Cache, QueueManagement, Unity-Claude-CPG-Original, Unity-Claude-IncrementalProcessor-Fixed, BatchProcessingEngine, ProgressTracker, CommandExecutionEngine, Unity-Claude-ScalabilityEnhancements-Original, Unity-Claude-Cache-Fixed, Unity-Claude-IPC-Bidirectional

--- 
### BackupIntegration

[⬆ Back to Contents](#-table-of-contents)

Specialized module providing targeted functionality for the Unity-Claude automation system. Integrates with the broader architecture to deliver specific capabilities.

**Key Capabilities:** resource creation, specialized operations, data retrieval, validation and testing

**Module Statistics:**
- Functions: 8
- Lines of Code: 881
- Exported Members: 1


**Module Details:**
- **Path:** `Modules\Unity-Claude-DocumentationAutomation\Core\BackupIntegration.psm1`
- **Size:** 30.36 KB
- **Functions:** 8
- **Last Modified:** 2025-08-26 11:46

**Dependencies:** CPG-DataStructures, CrossLanguage-DependencyMaps, CPG-Unified, RunspacePoolManager, Unity-Claude-Cache-Original, Unity-Claude-Cache, Performance-Cache, Unity-Claude-CPG-Original, Unity-Claude-DocumentationDrift, AutomationEngine, TemplateSystem, TriggerSystem, Unity-Claude-Cache-Fixed, GitHubPRManager, Unity-Claude-DocumentationAutomation-Original

--- 
### BatchProcessingEngine

[⬆ Back to Contents](#-table-of-contents)

Specialized module providing targeted functionality for the Unity-Claude automation system. Integrates with the broader architecture to deliver specific capabilities.

**Key Capabilities:** resource creation, process initiation

**Module Statistics:**
- Functions: 2
- Lines of Code: 499
- Classes: 1
- Exported Members: 1


**Module Details:**
- **Path:** `Modules\Unity-Claude-ParallelProcessor\Core\BatchProcessingEngine.psm1`
- **Size:** 22.88 KB
- **Functions:** 13
- **Last Modified:** 2025-08-26 11:46

**Dependencies:** Unity-Claude-PerformanceOptimizer-Original, JobScheduler, Unity-Claude-IncrementalProcessor, Performance-IncrementalUpdates, Unity-Claude-ParallelProcessor-Original, RunspacePoolManager, Unity-Claude-Cache-Original, StatisticsTracker, ModuleFunctions, Unity-Claude-Cache, Unity-Claude-PerformanceOptimizer-Refactored, Performance-Cache, Unity-Claude-CPG-Original, Unity-Claude-IncrementalProcessor-Fixed, OptimizerConfiguration, Unity-Claude-Cache-Fixed

--- 
### BayesianConfidenceEngine

[⬆ Back to Contents](#-table-of-contents)

Bayesian inference engine for probabilistic reasoning and confidence scoring. Updates beliefs based on evidence and provides uncertainty quantification.

**Key Capabilities:** specialized operations, data retrieval

**Module Statistics:**
- Functions: 15
- Lines of Code: 738
- Exported Members: 1


**Module Details:**
- **Path:** `Modules\Unity-Claude-CLIOrchestrator\Core\BayesianConfidenceEngine.psm1`
- **Size:** 24.86 KB
- **Functions:** 15
- **Last Modified:** 2025-08-26 11:46

**Dependencies:** Unity-Claude-PerformanceOptimizer-Original, Unity-Claude-IncrementalProcessor, Unity-Claude-ParallelProcessor-Original, Unity-Claude-Cache-Original, PatternRecognitionEngine-Original, ModuleFunctions, Unity-Claude-Cache, Unity-Claude-PerformanceOptimizer-Refactored, Performance-Cache, Unity-Claude-IncrementalProcessor-Fixed, BatchProcessingEngine, Unity-Claude-Cache-Fixed

--- 
### BayesianConfiguration

[⬆ Back to Contents](#-table-of-contents)

Bayesian inference engine for probabilistic reasoning and confidence scoring. Updates beliefs based on evidence and provides uncertainty quantification.

**Module Statistics:**
- Functions: 0
- Lines of Code: 92
- Exported Members: 1


**Module Details:**
- **Path:** `Modules\Unity-Claude-CLIOrchestrator\Core\DecisionEngine-Bayesian\BayesianConfiguration.psm1`
- **Size:** 4.21 KB
- **Functions:** 0
- **Last Modified:** 2025-08-26 11:46



--- 
### BayesianInference

[⬆ Back to Contents](#-table-of-contents)

Bayesian inference engine for probabilistic reasoning and confidence scoring. Updates beliefs based on evidence and provides uncertainty quantification.

**Key Capabilities:** action execution, data retrieval, specialized operations

**Module Statistics:**
- Functions: 6
- Lines of Code: 307
- Exported Members: 1


**Module Details:**
- **Path:** `Modules\Unity-Claude-CLIOrchestrator\Core\DecisionEngine-Bayesian\BayesianInference.psm1`
- **Size:** 11.82 KB
- **Functions:** 6
- **Last Modified:** 2025-08-26 11:46

**Dependencies:** Unity-Claude-PerformanceOptimizer-Original, Unity-Claude-IncrementalProcessor, Unity-Claude-ParallelProcessor-Original, DecisionEngine-Bayesian, Unity-Claude-Cache-Original, Unity-Claude-Cache, ResponseAnalysisEngine-Enhanced, Unity-Claude-PerformanceOptimizer-Refactored, Performance-Cache, Unity-Claude-IncrementalProcessor-Fixed, ConfigurationLogging, ResponseAnalysisEngine-Broken, BatchProcessingEngine, DecisionEngine, Unity-Claude-Cache-Fixed, ResponseAnalysisEngine, ConfidenceBands

--- 
### CircuitBreaker

[⬆ Back to Contents](#-table-of-contents)

Specialized module providing targeted functionality for the Unity-Claude automation system. Integrates with the broader architecture to deliver specific capabilities.

**Key Capabilities:** specialized operations, validation and testing, data retrieval

**Module Statistics:**
- Functions: 8
- Lines of Code: 316
- Exported Members: 1


**Module Details:**
- **Path:** `Modules\Unity-Claude-CLIOrchestrator\Core\Components\CircuitBreaker.psm1`
- **Size:** 11.48 KB
- **Functions:** 8
- **Last Modified:** 2025-08-26 11:46

**Dependencies:** RunspacePoolManager, Unity-Claude-Cache-Original, Unity-Claude-Cache, Performance-Cache, AnalysisLogging, ResponseAnalysisEngine-Broken, Unity-Claude-ErrorHandling, Unity-Claude-MessageQueue, Unity-Claude-AutonomousStateTracker, Unity-Claude-Cache-Fixed, ErrorHandling, JsonProcessing

--- 
### Classification

[⬆ Back to Contents](#-table-of-contents)

Specialized module providing targeted functionality for the Unity-Claude automation system. Integrates with the broader architecture to deliver specific capabilities.

**Key Capabilities:** action execution, validation and testing, data retrieval

**Module Statistics:**
- Functions: 8
- Lines of Code: 760
- Exported Members: 1


**Module Details:**
- **Path:** `Modules\Unity-Claude-AutonomousAgent\Parsing\Classification.psm1`
- **Size:** 28.04 KB
- **Functions:** 8
- **Last Modified:** 2025-08-20 17:25

**Dependencies:** Unity-Claude-PerformanceOptimizer-Original, Unity-Claude-IncrementalProcessor, Unity-Claude-ParallelProcessor-Original, Unity-Claude-Cache-Original, Unity-Claude-Cache, Unity-Claude-ParallelProcessing, AgentLogging, Unity-Claude-PerformanceOptimizer-Refactored, Performance-Cache, Unity-Claude-IncrementalProcessor-Fixed, BatchProcessingEngine, Unity-Claude-Cache-Fixed

--- 
### ClaudeIntegration

[⬆ Back to Contents](#-table-of-contents)

Specialized module providing targeted functionality for the Unity-Claude automation system. Integrates with the broader architecture to deliver specific capabilities.

**Key Capabilities:** request processing, resource creation, data retrieval

**Module Statistics:**
- Functions: 6
- Lines of Code: 322
- Exported Members: 1


**Module Details:**
- **Path:** `Modules\Unity-Claude-AutonomousAgent\Integration\ClaudeIntegration.psm1`
- **Size:** 12.77 KB
- **Functions:** 4
- **Last Modified:** 2025-08-20 17:25

**Dependencies:** Unity-Claude-Cache-Original, Unity-Claude-Cache, Unity-Claude-ParallelProcessing, AgentLogging, Performance-Cache, ResponseMonitoring, Unity-Claude-CLISubmission-Enhanced, Unity-Claude-Cache-Fixed, Unity-Claude-CLISubmission

--- 
### CLIAutomation

[⬆ Back to Contents](#-table-of-contents)

Specialized module providing targeted functionality for the Unity-Claude automation system. Integrates with the broader architecture to deliver specific capabilities.

**Key Capabilities:** specialized operations, validation and testing, data retrieval, configuration management

**Module Statistics:**
- Functions: 15
- Lines of Code: 839
- Classes: 1
- Exported Members: 1


**Module Details:**
- **Path:** `Modules\Execution\CLIAutomation.psm1`
- **Size:** 27.25 KB
- **Functions:** 15
- **Last Modified:** 2025-08-20 17:25

**Dependencies:** CPG-DataStructures, CrossLanguage-DependencyMaps, Unity-Claude-PerformanceOptimizer-Original, Unity-Claude-IncrementalProcessor, CPG-Unified, Unity-Claude-ParallelProcessor-Original, Unity-Claude-Cache-Original, ModuleFunctions, Unity-Claude-Cache, Unity-Claude-PerformanceOptimizer-Refactored, Performance-Cache, Unity-Claude-CPG-Original, Unity-Claude-IncrementalProcessor-Fixed, BatchProcessingEngine, Unity-Claude-Cache-Fixed

--- 
### CodeComplexityMetrics

[⬆ Back to Contents](#-table-of-contents)

Specialized module providing targeted functionality for the Unity-Claude automation system. Integrates with the broader architecture to deliver specific capabilities.

**Key Capabilities:** data retrieval

**Module Statistics:**
- Functions: 12
- Lines of Code: 556
- Classes: 1
- Exported Members: 1


**Module Details:**
- **Path:** `Modules\Unity-Claude-CPG\Core\CodeComplexityMetrics.psm1`
- **Size:** 19.43 KB
- **Functions:** 11
- **Last Modified:** 2025-08-26 11:46

**Dependencies:** Unity-Claude-Cache-Original, Unity-Claude-Cache, Performance-Cache, Unity-Claude-Cache-Fixed, Unity-Claude-AST-Enhanced

--- 
### CodeRedundancyDetection

[⬆ Back to Contents](#-table-of-contents)

Specialized module providing targeted functionality for the Unity-Claude automation system. Integrates with the broader architecture to deliver specific capabilities.

**Key Capabilities:** validation and testing, specialized operations, data retrieval

**Module Statistics:**
- Functions: 11
- Lines of Code: 498
- Exported Members: 1


**Module Details:**
- **Path:** `Modules\Unity-Claude-CPG\Core\CodeRedundancyDetection.psm1`
- **Size:** 17.61 KB
- **Functions:** 8
- **Last Modified:** 2025-08-26 11:46

**Dependencies:** CrossLanguage-DependencyMaps, EntityContextEngine, DecisionEngine-Bayesian, Unity-Claude-Cache-Original, Unity-Claude-Cache, Performance-Cache, Unity-Claude-Learning-Original, CrossLanguage-GraphMerger, Unity-Claude-Learning-Simple, StringSimilarity, Unity-Claude-Cache-Fixed, PatternAnalysis

--- 
### CodeSmellPrediction

[⬆ Back to Contents](#-table-of-contents)

Specialized module providing targeted functionality for the Unity-Claude automation system. Integrates with the broader architecture to deliver specific capabilities.

**Key Capabilities:** specialized operations

**Module Statistics:**
- Functions: 6
- Lines of Code: 541
- Classes: 2
- Exported Members: 1


**Module Details:**
- **Path:** `Modules\Unity-Claude-PredictiveAnalysis\Core\CodeSmellPrediction.psm1`
- **Size:** 21.09 KB
- **Functions:** 6
- **Last Modified:** 2025-08-26 11:46

**Dependencies:** CPG-DataStructures, Unity-Claude-PerformanceOptimizer-Original, Unity-Claude-IncrementalProcessor, CPG-Unified, RefactoringDetection, Unity-Claude-ParallelProcessor-Original, Unity-Claude-Cache-Original, Unity-Claude-Cache, Unity-Claude-PredictiveAnalysis-Original, Unity-Claude-PerformanceOptimizer-Refactored, Performance-Cache, Unity-Claude-CPG-Original, Unity-Claude-IncrementalProcessor-Fixed, CPG-QueryOperations, BatchProcessingEngine, Unity-Claude-Cache-Fixed

--- 
### CommandExecution

[⬆ Back to Contents](#-table-of-contents)

Specialized module providing targeted functionality for the Unity-Claude automation system. Integrates with the broader architecture to deliver specific capabilities.

**Key Capabilities:** action execution, validation and testing, data retrieval

**Module Statistics:**
- Functions: 3
- Lines of Code: 266
- Exported Members: 1


**Module Details:**
- **Path:** `Modules\SafeCommandExecution\Core\CommandExecution.psm1`
- **Size:** 8.78 KB
- **Functions:** 3
- **Last Modified:** 2025-08-26 11:46

**Dependencies:** CPG-DataStructures, CrossLanguage-DependencyMaps, Unity-Claude-PerformanceOptimizer-Original, Unity-Claude-IncrementalProcessor, SafeExecution, CPG-Unified, Unity-Claude-ParallelProcessor-Original, Unity-Claude-Cache-Original, SafeCommandCore, Unity-Claude-Cache, ValidationEngine, Unity-Claude-PerformanceOptimizer-Refactored, Performance-Cache, Unity-Claude-CPG-Original, Unity-Claude-IncrementalProcessor-Fixed, BatchProcessingEngine, CommandTypeHandlers, Unity-Claude-Cache-Fixed, SafeCommandExecution-Original, UnityCommands

--- 
### CommandExecutionEngine

[⬆ Back to Contents](#-table-of-contents)

Specialized module providing targeted functionality for the Unity-Claude automation system. Integrates with the broader architecture to deliver specific capabilities.

**Key Capabilities:** specialized operations, data retrieval, process initiation

**Module Statistics:**
- Functions: 13
- Lines of Code: 894
- Exported Members: 1


**Module Details:**
- **Path:** `Modules\Unity-Claude-AutonomousAgent\Execution\CommandExecutionEngine.psm1`
- **Size:** 31.54 KB
- **Functions:** 13
- **Last Modified:** 2025-08-20 17:25

**Dependencies:** CPG-DataStructures, CrossLanguage-DependencyMaps, Unity-Claude-HITL-Original, Unity-Claude-PerformanceOptimizer-Original, JobScheduler, Unity-Claude-IncrementalProcessor, SafeExecution, BackgroundJobQueue, CPG-Unified, Unity-Claude-ParallelProcessor-Original, ActionExecutionEngine, RunspacePoolManager, Unity-Claude-Cache-Original, Unity-Claude-IPC-Bidirectional-Fixed, StatisticsTracker, ModuleFunctions, Unity-Claude-Cache, ApprovalRequests, ValidationEngine, Unity-Claude-ParallelProcessing, AgentLogging, Unity-Claude-PerformanceOptimizer-Refactored, Performance-Cache, QueueManagement, Unity-Claude-CPG-Original, Unity-Claude-IncrementalProcessor-Fixed, BatchProcessingEngine, Unity-Claude-ScalabilityEnhancements-Original, Unity-Claude-Cache-Fixed, ErrorHandling, SafeCommandExecution-Original, Unity-Claude-IPC-Bidirectional, RunspaceManagement

--- 
### CommandTypeHandlers

[⬆ Back to Contents](#-table-of-contents)

Specialized module providing targeted functionality for the Unity-Claude automation system. Integrates with the broader architecture to deliver specific capabilities.

**Key Capabilities:** action execution

**Module Statistics:**
- Functions: 5
- Lines of Code: 445
- Exported Members: 1


**Module Details:**
- **Path:** `Modules\SafeCommandExecution\Core\CommandTypeHandlers.psm1`
- **Size:** 15.11 KB
- **Functions:** 5
- **Last Modified:** 2025-08-26 11:46

**Dependencies:** CPG-DataStructures, UnityReportingOperations, CrossLanguage-DependencyMaps, Unity-Claude-PerformanceOptimizer-Original, JobScheduler, UnityProjectOperations, Unity-Claude-IncrementalProcessor, SafeExecution, CPG-Unified, Unity-Claude-ParallelProcessor-Original, ActionExecutionEngine, RunspacePoolManager, Unity-Claude-Cache-Original, SafeCommandCore, StatisticsTracker, ModuleFunctions, Unity-Claude-Cache, ValidationEngine, Unity-Claude-PerformanceOptimizer-Refactored, Performance-Cache, UnityPerformanceAnalysis, Unity-Claude-CPG-Original, Unity-Claude-IncrementalProcessor-Fixed, UnityBuildOperations, BatchProcessingEngine, Unity-Claude-Cache-Fixed, SafeCommandExecution-Original, UnityLogAnalysis, UnityCommands, RunspaceManagement

--- 
### CompilationIntegration

[⬆ Back to Contents](#-table-of-contents)

Specialized module providing targeted functionality for the Unity-Claude automation system. Integrates with the broader architecture to deliver specific capabilities.

**Key Capabilities:** process initiation, specialized operations, validation and testing

**Module Statistics:**
- Functions: 3
- Lines of Code: 300
- Exported Members: 1


**Module Details:**
- **Path:** `Modules\Unity-Claude-UnityParallelization\Core\CompilationIntegration.psm1`
- **Size:** 11.59 KB
- **Functions:** 3
- **Last Modified:** 2025-08-26 11:46

**Dependencies:** Unity-Claude-UnityParallelization-Original, Unity-Claude-PerformanceOptimizer-Original, UnityProjectOperations, Unity-Claude-IncrementalProcessor, Unity-Claude-ParallelProcessor-Original, Unity-Claude-Cache-Original, Unity-Claude-Cache, Unity-Claude-PerformanceOptimizer-Refactored, Performance-Cache, ProductionRunspacePool, Unity-Claude-IncrementalProcessor-Fixed, BatchProcessingEngine, ParallelizationCore, Unity-Claude-Cache-Fixed, Unity-Claude-RunspaceManagement-Original, SafeCommandExecution-Original, ProjectConfiguration

--- 
### ConfidenceBands

[⬆ Back to Contents](#-table-of-contents)

Specialized module providing targeted functionality for the Unity-Claude automation system. Integrates with the broader architecture to deliver specific capabilities.

**Key Capabilities:** data retrieval, specialized operations

**Module Statistics:**
- Functions: 2
- Lines of Code: 127
- Exported Members: 1


**Module Details:**
- **Path:** `Modules\Unity-Claude-CLIOrchestrator\Core\DecisionEngine-Bayesian\ConfidenceBands.psm1`
- **Size:** 4.83 KB
- **Functions:** 2
- **Last Modified:** 2025-08-26 11:46

**Dependencies:** DecisionEngine-Bayesian, Unity-Claude-Cache-Original, Unity-Claude-Cache, ResponseAnalysisEngine-Enhanced, Performance-Cache, ConfigurationLogging, ResponseAnalysisEngine-Broken, DecisionEngine, Unity-Claude-Cache-Fixed, ResponseAnalysisEngine

--- 
### Configuration

[⬆ Back to Contents](#-table-of-contents)

Specialized module providing targeted functionality for the Unity-Claude automation system. Integrates with the broader architecture to deliver specific capabilities.

**Key Capabilities:** system initialization, data retrieval, configuration management, specialized operations

**Module Statistics:**
- Functions: 5
- Lines of Code: 330
- Exported Members: 1


**Module Details:**
- **Path:** `Modules\Unity-Claude-DocumentationDrift\Core\Configuration.psm1`
- **Size:** 12.68 KB
- **Functions:** 5
- **Last Modified:** 2025-08-26 11:46

**Dependencies:** Unity-Claude-ParallelProcessor-Original, Unity-Claude-Cache-Original, ModuleFunctions, Unity-Claude-Cache, Performance-Cache, Unity-Claude-DocumentationDrift, Unity-Claude-Cache-Fixed

--- 
### ConfigurationLogging

[⬆ Back to Contents](#-table-of-contents)

Specialized module providing targeted functionality for the Unity-Claude automation system. Integrates with the broader architecture to deliver specific capabilities.

**Key Capabilities:** data retrieval, configuration management, specialized operations

**Module Statistics:**
- Functions: 4
- Lines of Code: 179
- Exported Members: 1


**Module Details:**
- **Path:** `Modules\Unity-Claude-CLIOrchestrator\Core\DecisionEngine\ConfigurationLogging.psm1`
- **Size:** 6.06 KB
- **Functions:** 3
- **Last Modified:** 2025-08-26 11:46

**Dependencies:** Unity-Claude-Cache-Original, Unity-Claude-Cache, Performance-Cache, DecisionEngine, Unity-Claude-Cache-Fixed

--- 
### ConfigurationManagement

[⬆ Back to Contents](#-table-of-contents)

Specialized module providing targeted functionality for the Unity-Claude automation system. Integrates with the broader architecture to deliver specific capabilities.

**Key Capabilities:** resource creation, specialized operations, validation and testing, data retrieval

**Module Statistics:**
- Functions: 6
- Lines of Code: 318
- Exported Members: 1


**Module Details:**
- **Path:** `Modules\Unity-Claude-NotificationIntegration\Configuration\ConfigurationManagement.psm1`
- **Size:** 10.9 KB
- **Functions:** 6
- **Last Modified:** 2025-08-21 17:45

**Dependencies:** Unity-Claude-Cache-Original, Unity-Claude-Cache, Performance-Cache, Unity-Claude-NotificationIntegration-Modular, Unity-Claude-Cache-Fixed

--- 
### ContentAnalysis

[⬆ Back to Contents](#-table-of-contents)

Specialized module providing targeted functionality for the Unity-Claude automation system. Integrates with the broader architecture to deliver specific capabilities.

**Key Capabilities:** specialized operations

**Module Statistics:**
- Functions: 8
- Lines of Code: 111
- Exported Members: 1


**Module Details:**
- **Path:** `Modules\Unity-Claude-DocumentationQualityAssessment\Components\ContentAnalysis.psm1`
- **Size:** 4.1 KB
- **Functions:** 8
- **Last Modified:** 2025-08-30 19:31

**Dependencies:** Unity-Claude-Cache-Original, Unity-Claude-Cache, Unity-Claude-PredictiveAnalysis-Original, AnalyticsReporting, Performance-Cache, Unity-Claude-Cache-Fixed

--- 
### ContextExtraction

[⬆ Back to Contents](#-table-of-contents)

Specialized module providing targeted functionality for the Unity-Claude automation system. Integrates with the broader architecture to deliver specific capabilities.

**Key Capabilities:** action execution, data retrieval, resource creation

**Module Statistics:**
- Functions: 6
- Lines of Code: 707
- Exported Members: 1


**Module Details:**
- **Path:** `Modules\Unity-Claude-AutonomousAgent\Parsing\ContextExtraction.psm1`
- **Size:** 25.92 KB
- **Functions:** 6
- **Last Modified:** 2025-08-20 17:25

**Dependencies:** Unity-Claude-PerformanceOptimizer-Original, Unity-Claude-IncrementalProcessor, Unity-Claude-ParallelProcessor-Original, Unity-Claude-Cache-Original, Unity-Claude-Cache, Unity-Claude-ParallelProcessing, AgentLogging, Unity-Claude-PerformanceOptimizer-Refactored, Performance-Cache, Unity-Claude-IncrementalProcessor-Fixed, BatchProcessingEngine, ContextOptimization, Unity-Claude-Cache-Fixed

--- 
### ContextManagement

[⬆ Back to Contents](#-table-of-contents)

Specialized module providing targeted functionality for the Unity-Claude automation system. Integrates with the broader architecture to deliver specific capabilities.

**Key Capabilities:** resource creation, specialized operations, data retrieval

**Module Statistics:**
- Functions: 5
- Lines of Code: 204
- Exported Members: 1


**Module Details:**
- **Path:** `Modules\Unity-Claude-NotificationIntegration\Integration\ContextManagement.psm1`
- **Size:** 7 KB
- **Functions:** 5
- **Last Modified:** 2025-08-21 17:45

**Dependencies:** CPG-DataStructures, CrossLanguage-DependencyMaps, CPG-Unified, Unity-Claude-Cache-Original, Unity-Claude-Cache, Performance-Cache, Unity-Claude-CPG-Original, Unity-Claude-Cache-Fixed

--- 
### ContextOptimization

[⬆ Back to Contents](#-table-of-contents)

Specialized module providing targeted functionality for the Unity-Claude automation system. Integrates with the broader architecture to deliver specific capabilities.

**Key Capabilities:** specialized operations, system initialization, data retrieval

**Module Statistics:**
- Functions: 22
- Lines of Code: 1447
- Exported Members: 1


**Module Details:**
- **Path:** `Modules\Unity-Claude-AutonomousAgent\ContextOptimization.psm1`
- **Size:** 49.16 KB
- **Functions:** 22
- **Last Modified:** 2025-08-20 17:25

**Dependencies:** CPG-DataStructures, CrossLanguage-DependencyMaps, Unity-Claude-PerformanceOptimizer-Original, Unity-Claude-IncrementalProcessor, CPG-Unified, Unity-Claude-ParallelProcessor-Original, DecisionEngine-Bayesian, Unity-Claude-Cache-Original, ModuleFunctions, Unity-Claude-Cache, ResponseAnalysisEngine-Enhanced, Unity-Claude-PerformanceOptimizer-Refactored, Performance-Cache, Unity-Claude-CPG-Original, Unity-Claude-IncrementalProcessor-Fixed, ResponseAnalysisEngine-Broken, BatchProcessingEngine, Unity-Claude-Cache-Fixed, PatternAnalysis, ResponseAnalysisEngine

--- 
### ConversationStateManager

[⬆ Back to Contents](#-table-of-contents)

Specialized module providing targeted functionality for the Unity-Claude automation system. Integrates with the broader architecture to deliver specific capabilities.

**Key Capabilities:** specialized operations, system initialization, configuration management, data retrieval

**Module Statistics:**
- Functions: 22
- Lines of Code: 1410
- Exported Members: 1


**Module Details:**
- **Path:** `Modules\Unity-Claude-AutonomousAgent\ConversationStateManager.psm1`
- **Size:** 46.97 KB
- **Functions:** 22
- **Last Modified:** 2025-08-26 11:46

**Dependencies:** CPG-DataStructures, CrossLanguage-DependencyMaps, CPG-Unified, Unity-Claude-ParallelProcessor-Original, HistoryManagement, Unity-Claude-Cache-Original, ModuleFunctions, Unity-Claude-Cache, RoleAwareManagement, PersistenceManagement, GoalManagement, Performance-Cache, Unity-Claude-CPG-Original, StateManagement, Unity-Claude-Cache-Fixed

--- 
### ConversationStateManager-Refactored

[⬆ Back to Contents](#-table-of-contents)

Specialized module providing targeted functionality for the Unity-Claude automation system. Integrates with the broader architecture to deliver specific capabilities.

**Key Capabilities:** data retrieval, validation and testing, action execution, system initialization

**Module Statistics:**
- Functions: 5
- Lines of Code: 329
- Exported Members: 1


**Module Details:**
- **Path:** `Modules\Unity-Claude-AutonomousAgent\ConversationStateManager-Refactored.psm1`
- **Size:** 12.5 KB
- **Functions:** 5
- **Last Modified:** 2025-08-26 11:46

**Dependencies:** Unity-Claude-ParallelProcessor-Original, HistoryManagement, Unity-Claude-Cache-Original, ConversationStateManager, ModuleFunctions, Unity-Claude-Cache, RoleAwareManagement, PersistenceManagement, GoalManagement, Performance-Cache, StateManagement, Unity-Claude-Cache-Fixed

--- 
### CPG-AdvancedEdges

[⬆ Back to Contents](#-table-of-contents)

Specialized module providing targeted functionality for the Unity-Claude automation system. Integrates with the broader architecture to deliver specific capabilities.

**Key Capabilities:** resource creation

**Module Statistics:**
- Functions: 15
- Lines of Code: 824
- Classes: 6
- Exported Members: 1


**Module Details:**
- **Path:** `Modules\Unity-Claude-CPG\Core\CPG-AdvancedEdges.psm1`
- **Size:** 25.39 KB
- **Functions:** 30
- **Last Modified:** 2025-08-28 01:39

**Dependencies:** CPG-DataStructures, CrossLanguage-DependencyMaps, CPG-Unified, Unity-Claude-Cache-Original, Unity-Claude-Cache, Performance-Cache, Unity-Claude-CPG-Original, Unity-Claude-Cache-Fixed

--- 
### CPG-AnalysisOperations

[⬆ Back to Contents](#-table-of-contents)

Specialized module providing targeted functionality for the Unity-Claude automation system. Integrates with the broader architecture to deliver specific capabilities.

**Key Capabilities:** data retrieval, validation and testing, specialized operations

**Module Statistics:**
- Functions: 5
- Lines of Code: 284
- Exported Members: 1


**Module Details:**
- **Path:** `Modules\Unity-Claude-CPG\Core\CPG-AnalysisOperations.psm1`
- **Size:** 9.03 KB
- **Functions:** 5
- **Last Modified:** 2025-08-26 11:46

**Dependencies:** CPG-DataStructures, CrossLanguage-DependencyMaps, CPG-Unified, Unity-Claude-Cache-Original, Unity-Claude-Cache, Performance-Cache, Unity-Claude-CPG-Original, Unity-Claude-Cache-Fixed

--- 
### CPG-BasicOperations

[⬆ Back to Contents](#-table-of-contents)

Specialized module providing targeted functionality for the Unity-Claude automation system. Integrates with the broader architecture to deliver specific capabilities.

**Key Capabilities:** resource creation, specialized operations

**Module Statistics:**
- Functions: 5
- Lines of Code: 220
- Exported Members: 1


**Module Details:**
- **Path:** `Modules\Unity-Claude-CPG\Core\CPG-BasicOperations.psm1`
- **Size:** 6.78 KB
- **Functions:** 5
- **Last Modified:** 2025-08-26 11:46

**Dependencies:** CPG-DataStructures, CrossLanguage-DependencyMaps, CPG-Unified, Unity-Claude-Cache-Original, Unity-Claude-Cache, Performance-Cache, Unity-Claude-CPG-Original, Unity-Claude-Cache-Fixed

--- 
### CPG-CallGraphBuilder

[⬆ Back to Contents](#-table-of-contents)

Specialized module providing targeted functionality for the Unity-Claude automation system. Integrates with the broader architecture to deliver specific capabilities.

**Key Capabilities:** specialized operations, validation and testing, data retrieval

**Module Statistics:**
- Functions: 11
- Lines of Code: 670
- Classes: 5
- Exported Members: 1


**Module Details:**
- **Path:** `Modules\Unity-Claude-CPG\Core\CPG-CallGraphBuilder.psm1`
- **Size:** 24.92 KB
- **Functions:** 16
- **Last Modified:** 2025-08-28 02:52

**Dependencies:** CPG-DataStructures, CrossLanguage-DependencyMaps, CPG-Unified, TreeSitter-CSTConverter, Unity-Claude-Cache-Original, Unity-Claude-Cache, Performance-Cache, CrossLanguage-GraphMerger, Unity-Claude-CPG-Original, CPG-DataFlowTracker, Unity-Claude-Cache-Fixed

--- 
### CPG-DataFlowTracker

[⬆ Back to Contents](#-table-of-contents)

Specialized module providing targeted functionality for the Unity-Claude automation system. Integrates with the broader architecture to deliver specific capabilities.

**Key Capabilities:** specialized operations, data retrieval

**Module Statistics:**
- Functions: 6
- Lines of Code: 847
- Classes: 6
- Exported Members: 1


**Module Details:**
- **Path:** `Modules\Unity-Claude-CPG\Core\CPG-DataFlowTracker.psm1`
- **Size:** 31.56 KB
- **Functions:** 22
- **Last Modified:** 2025-08-28 03:02

**Dependencies:** CPG-DataStructures, CrossLanguage-DependencyMaps, Unity-Claude-PerformanceOptimizer-Original, Unity-Claude-IncrementalProcessor, Performance-IncrementalUpdates, CPG-Unified, Unity-Claude-ParallelProcessor-Original, TreeSitter-CSTConverter, Unity-Claude-Cache-Original, ModuleFunctions, Unity-Claude-Cache, Unity-Claude-PerformanceOptimizer-Refactored, Performance-Cache, CrossLanguage-GraphMerger, Unity-Claude-CPG-Original, Unity-Claude-IncrementalProcessor-Fixed, BatchProcessingEngine, Unity-Claude-Cache-Fixed, CPG-CallGraphBuilder

--- 
### CPG-DataStructures

[⬆ Back to Contents](#-table-of-contents)

Specialized module providing targeted functionality for the Unity-Claude automation system. Integrates with the broader architecture to deliver specific capabilities.

**Module Statistics:**
- Functions: 0
- Lines of Code: 279
- Classes: 4
- Exported Members: 1


**Module Details:**
- **Path:** `Modules\Unity-Claude-CPG\Core\CPG-DataStructures.psm1`
- **Size:** 8.78 KB
- **Functions:** 13
- **Last Modified:** 2025-08-26 11:46

**Dependencies:** CrossLanguage-DependencyMaps, CPG-Unified, Unity-Claude-Cache-Original, Unity-Claude-Cache, Performance-Cache, Unity-Claude-CPG-Original, Unity-Claude-Cache-Fixed

--- 
### CPG-QueryOperations

[⬆ Back to Contents](#-table-of-contents)

Specialized module providing targeted functionality for the Unity-Claude automation system. Integrates with the broader architecture to deliver specific capabilities.

**Key Capabilities:** data retrieval, specialized operations

**Module Statistics:**
- Functions: 4
- Lines of Code: 374
- Exported Members: 1


**Module Details:**
- **Path:** `Modules\Unity-Claude-CPG\Core\CPG-QueryOperations.psm1`
- **Size:** 11.65 KB
- **Functions:** 4
- **Last Modified:** 2025-08-26 11:46

**Dependencies:** CPG-DataStructures, Unity-Claude-PerformanceOptimizer-Original, Unity-Claude-IncrementalProcessor, CPG-Unified, Unity-Claude-ParallelProcessor-Original, Unity-Claude-Cache-Original, Unity-Claude-Cache, Unity-Claude-PerformanceOptimizer-Refactored, Performance-Cache, Unity-Claude-CPG-Original, Unity-Claude-IncrementalProcessor-Fixed, BatchProcessingEngine, Unity-Claude-Cache-Fixed

--- 
### CPG-SerializationOperations

[⬆ Back to Contents](#-table-of-contents)

Specialized module providing targeted functionality for the Unity-Claude automation system. Integrates with the broader architecture to deliver specific capabilities.

**Key Capabilities:** specialized operations

**Module Statistics:**
- Functions: 6
- Lines of Code: 318
- Exported Members: 1


**Module Details:**
- **Path:** `Modules\Unity-Claude-CPG\Core\CPG-SerializationOperations.psm1`
- **Size:** 10.24 KB
- **Functions:** 4
- **Last Modified:** 2025-08-26 11:46

**Dependencies:** CPG-DataStructures, CPG-Unified, Unity-Claude-Cache-Original, Unity-Claude-Cache, Performance-Cache, Unity-Claude-CPG-Original, ReportingExport, Unity-Claude-Cache-Fixed

--- 
### CPG-ThreadSafeOperations

[⬆ Back to Contents](#-table-of-contents)

Specialized module providing targeted functionality for the Unity-Claude automation system. Integrates with the broader architecture to deliver specific capabilities.

**Key Capabilities:** specialized operations, resource creation, data retrieval

**Module Statistics:**
- Functions: 12
- Lines of Code: 832
- Exported Members: 1


**Module Details:**
- **Path:** `Modules\Unity-Claude-CPG\Core\CPG-ThreadSafeOperations.psm1`
- **Size:** 25.68 KB
- **Functions:** 12
- **Last Modified:** 2025-08-28 01:31

**Dependencies:** CPG-DataStructures, CrossLanguage-DependencyMaps, JobScheduler, Unity-Claude-IncrementalProcessor, CPG-Unified, Unity-Claude-ParallelProcessor-Original, RunspacePoolManager, Unity-Claude-Cache-Original, StatisticsTracker, ModuleFunctions, Unity-Claude-Cache, Performance-Cache, CrossLanguage-GraphMerger, Unity-Claude-CPG-Original, Unity-Claude-IncrementalProcessor-Fixed, BatchProcessingEngine, Unity-Claude-Cache-Fixed

--- 
### CPG-Unified

[⬆ Back to Contents](#-table-of-contents)

Specialized module providing targeted functionality for the Unity-Claude automation system. Integrates with the broader architecture to deliver specific capabilities.

**Key Capabilities:** specialized operations, resource creation

**Module Statistics:**
- Functions: 14
- Lines of Code: 818
- Classes: 12
- Exported Members: 1


**Module Details:**
- **Path:** `Modules\Unity-Claude-CPG\Core\CPG-Unified.psm1`
- **Size:** 26.53 KB
- **Functions:** 41
- **Last Modified:** 2025-08-28 01:46

**Dependencies:** CPG-DataStructures, CrossLanguage-DependencyMaps, Unity-Claude-ParallelProcessor-Original, Unity-Claude-Cache-Original, ModuleFunctions, Unity-Claude-Cache, Performance-Cache, CrossLanguage-GraphMerger, Unity-Claude-CPG-Original, CPG-BasicOperations, CPG-DataFlowTracker, Unity-Claude-Cache-Fixed, CPG-CallGraphBuilder, CPG-AdvancedEdges

--- 
### CrossLanguage-DependencyMaps

[⬆ Back to Contents](#-table-of-contents)

Specialized module providing targeted functionality for the Unity-Claude automation system. Integrates with the broader architecture to deliver specific capabilities.

**Key Capabilities:** specialized operations

**Module Statistics:**
- Functions: 11
- Lines of Code: 1344
- Classes: 9
- Exported Members: 1


**Module Details:**
- **Path:** `Modules\Unity-Claude-CPG\Core\CrossLanguage-DependencyMaps.psm1`
- **Size:** 46.43 KB
- **Functions:** 58
- **Last Modified:** 2025-08-28 11:34

**Dependencies:** CPG-DataStructures, CPG-Unified, Unity-Claude-ParallelProcessor-Original, Unity-Claude-Cache-Original, ModuleFunctions, Unity-Claude-Cache, Performance-Cache, CrossLanguage-GraphMerger, Unity-Claude-CPG-Original, CPG-DataFlowTracker, CrossLanguage-UnifiedModel, Unity-Claude-Cache-Fixed, CPG-CallGraphBuilder

--- 
### CrossLanguage-GraphMerger

[⬆ Back to Contents](#-table-of-contents)

Specialized module providing targeted functionality for the Unity-Claude automation system. Integrates with the broader architecture to deliver specific capabilities.

**Key Capabilities:** specialized operations

**Module Statistics:**
- Functions: 8
- Lines of Code: 1184
- Classes: 12
- Exported Members: 1


**Module Details:**
- **Path:** `Modules\Unity-Claude-CPG\Core\CrossLanguage-GraphMerger.psm1`
- **Size:** 39.26 KB
- **Functions:** 56
- **Last Modified:** 2025-08-28 12:05

**Dependencies:** CPG-DataStructures, CrossLanguage-DependencyMaps, CPG-Unified, Unity-Claude-ParallelProcessor-Original, Unity-Claude-Cache-Original, ModuleFunctions, Unity-Claude-Cache, Unity-Claude-CrossLanguage, Performance-Cache, Unity-Claude-CPG-Original, CPG-DataFlowTracker, CrossLanguage-UnifiedModel, Unity-Claude-Cache-Fixed, CPG-CallGraphBuilder

--- 
### CrossLanguage-UnifiedModel

[⬆ Back to Contents](#-table-of-contents)

Specialized module providing targeted functionality for the Unity-Claude automation system. Integrates with the broader architecture to deliver specific capabilities.

**Key Capabilities:** resource creation, data retrieval

**Module Statistics:**
- Functions: 5
- Lines of Code: 871
- Classes: 6
- Exported Members: 1


**Module Details:**
- **Path:** `Modules\Unity-Claude-CPG\Core\CrossLanguage-UnifiedModel.psm1`
- **Size:** 28.62 KB
- **Functions:** 31
- **Last Modified:** 2025-08-28 12:07

**Dependencies:** CPG-DataStructures, CrossLanguage-DependencyMaps, CPG-Unified, Unity-Claude-ParallelProcessor-Original, Unity-Claude-Cache-Original, ModuleFunctions, Unity-Claude-Cache, Performance-Cache, CrossLanguage-GraphMerger, Unity-Claude-CPG-Original, Unity-Claude-Cache-Fixed

--- 
### DatabaseManagement

[⬆ Back to Contents](#-table-of-contents)

Specialized module providing targeted functionality for the Unity-Claude automation system. Integrates with the broader architecture to deliver specific capabilities.

**Key Capabilities:** system initialization, validation and testing

**Module Statistics:**
- Functions: 2
- Lines of Code: 215
- Exported Members: 1


**Module Details:**
- **Path:** `Modules\Unity-Claude-HITL\Core\DatabaseManagement.psm1`
- **Size:** 8.13 KB
- **Functions:** 2
- **Last Modified:** 2025-08-26 11:46

**Dependencies:** Unity-Claude-HITL-Original, Unity-Claude-ParallelProcessor-Original, Unity-Claude-Cache-Original, ModuleFunctions, Unity-Claude-Cache, Performance-Cache, Unity-Claude-Cache-Fixed

--- 
### DecisionEngine

[⬆ Back to Contents](#-table-of-contents)

Decision engine module implementing rule-based and ML-enhanced decision trees. Analyzes inputs, evaluates constraints, and determines appropriate actions based on configurable policies.

**Key Capabilities:** specialized operations, action execution, validation and testing

**Module Statistics:**
- Functions: 12
- Lines of Code: 936
- Exported Members: 1


**Module Details:**
- **Path:** `Modules\Unity-Claude-CLIOrchestrator\Core\DecisionEngine.psm1`
- **Size:** 33.98 KB
- **Functions:** 11
- **Last Modified:** 2025-08-26 22:10

**Dependencies:** CPG-DataStructures, CrossLanguage-DependencyMaps, Unity-Claude-PerformanceOptimizer-Original, Unity-Claude-IncrementalProcessor, CPG-Unified, Unity-Claude-ParallelProcessor-Original, ActionExecutionEngine, Unity-Claude-Cache-Original, Unity-Claude-Cache, Unity-Claude-CLIOrchestrator-Fixed-Simple, Unity-Claude-PerformanceOptimizer-Refactored, Performance-Cache, Unity-Claude-CPG-Original, Unity-Claude-IncrementalProcessor-Fixed, ConfigurationLogging, RuleBasedDecisionTrees, BatchProcessingEngine, SafetyValidationFramework, PriorityActionQueue, FallbackStrategies, Unity-Claude-Cache-Fixed

--- 
### DecisionEngine-Bayesian

[⬆ Back to Contents](#-table-of-contents)

Decision engine module implementing rule-based and ML-enhanced decision trees. Analyzes inputs, evaluates constraints, and determines appropriate actions based on configurable policies. Bayesian inference engine for probabilistic reasoning and confidence scoring. Updates beliefs based on evidence and provides uncertainty quantification. 

**Key Capabilities:** action execution, data retrieval, specialized operations 

**Module Statistics:**
 - Functions: 20
 - Lines of Code: 1319
 - Exported Members: 1


**Module Details:**
- **Path:** `Modules\Unity-Claude-CLIOrchestrator\Core\DecisionEngine-Bayesian.psm1`
- **Size:** 45.26 KB
- **Functions:** 20
- **Last Modified:** 2025-08-26 11:46

**Dependencies:** CrossLanguage-DependencyMaps, Unity-Claude-PerformanceOptimizer-Original, Unity-Claude-IncrementalProcessor, BayesianInference, EntityContextEngine, Unity-Claude-ParallelProcessor-Original, Unity-Claude-Cache-Original, PatternRecognitionEngine-Original, EnhancedPatternIntegration, ModuleFunctions, LearningAdaptation, Unity-Claude-Cache, ResponseAnalysisEngine-Enhanced, Unity-Claude-PerformanceOptimizer-Refactored, Performance-Cache, Unity-Claude-Learning-Original, CrossLanguage-GraphMerger, TemporalContextTracking, Unity-Claude-IncrementalProcessor-Fixed, ConfigurationLogging, Unity-Claude-Learning-Simple, ResponseAnalysisEngine-Broken, BatchProcessingEngine, StringSimilarity, DecisionEngine, ContextOptimization, CodeRedundancyDetection, Unity-Claude-Cache-Fixed, EntityRelationshipManagement, PatternAnalysis, ResponseAnalysisEngine, ConfidenceBands

--- 
### DecisionEngine-Bayesian-Refactored

[⬆ Back to Contents](#-table-of-contents)

Decision engine module implementing rule-based and ML-enhanced decision trees. Analyzes inputs, evaluates constraints, and determines appropriate actions based on configurable policies. Bayesian inference engine for probabilistic reasoning and confidence scoring. Updates beliefs based on evidence and provides uncertainty quantification. 

**Module Statistics:**
 - Functions: 0
 - Lines of Code: 115
 - Exported Members: 2


**Module Details:**
- **Path:** `Modules\Unity-Claude-CLIOrchestrator\Core\DecisionEngine-Bayesian-Refactored.psm1`
- **Size:** 4.65 KB
- **Functions:** 0
- **Last Modified:** 2025-08-26 11:46

**Dependencies:** CrossLanguage-DependencyMaps, BayesianInference, EntityContextEngine, Unity-Claude-ParallelProcessor-Original, DecisionEngine-Bayesian, Unity-Claude-Cache-Original, PatternRecognitionEngine-Original, EnhancedPatternIntegration, ModuleFunctions, LearningAdaptation, Unity-Claude-Cache, ResponseAnalysisEngine-Enhanced, Performance-Cache, Unity-Claude-Learning-Original, CrossLanguage-GraphMerger, TemporalContextTracking, ConfigurationLogging, Unity-Claude-Learning-Simple, ResponseAnalysisEngine-Broken, StringSimilarity, DecisionEngine, ContextOptimization, CodeRedundancyDetection, Unity-Claude-Cache-Fixed, EntityRelationshipManagement, PatternAnalysis, ResponseAnalysisEngine, ConfidenceBands

--- 
### DecisionEngine-Refactored

[⬆ Back to Contents](#-table-of-contents)

Decision engine module implementing rule-based and ML-enhanced decision trees. Analyzes inputs, evaluates constraints, and determines appropriate actions based on configurable policies.

**Key Capabilities:** system initialization, validation and testing, data retrieval, action execution

**Module Statistics:**
- Functions: 5
- Lines of Code: 362
- Exported Members: 1


**Module Details:**
- **Path:** `Modules\Unity-Claude-CLIOrchestrator\Core\DecisionEngine-Refactored.psm1`
- **Size:** 13.89 KB
- **Functions:** 4
- **Last Modified:** 2025-08-26 11:46

**Dependencies:** Unity-Claude-ParallelProcessor-Original, ActionExecutionEngine, Unity-Claude-Cache-Original, ModuleFunctions, Unity-Claude-Cache, Unity-Claude-CLIOrchestrator-Fixed-Simple, Performance-Cache, ConfigurationLogging, RuleBasedDecisionTrees, DecisionEngine, SafetyValidationFramework, PriorityActionQueue, IntegrationManagement, FallbackStrategies, Unity-Claude-Cache-Fixed

--- 
### DecisionEngineCore

[⬆ Back to Contents](#-table-of-contents)

Core infrastructure module providing fundamental functionality for the Unity-Claude system. This module serves as the foundation for other components, offering essential utilities, configuration management, and base services. Decision engine module implementing rule-based and ML-enhanced decision trees. Analyzes inputs, evaluates constraints, and determines appropriate actions based on configurable policies. 

**Key Capabilities:** specialized operations, validation and testing, data retrieval, configuration management 

**Module Statistics:**
 - Functions: 7
 - Lines of Code: 213
 - Exported Members: 1


**Module Details:**
- **Path:** `Modules\Unity-Claude-DecisionEngine\Core\DecisionEngineCore.psm1`
- **Size:** 6.91 KB
- **Functions:** 7
- **Last Modified:** 2025-08-26 11:46

**Dependencies:** Unity-Claude-Cache-Original, Unity-Claude-Cache, Performance-Cache, Unity-Claude-ResponseMonitor, Unity-Claude-DecisionEngine-Original, Unity-Claude-FixEngine, Unity-Claude-Cache-Fixed

--- 
### DecisionEngineIntegration

[⬆ Back to Contents](#-table-of-contents)

Decision engine module implementing rule-based and ML-enhanced decision trees. Analyzes inputs, evaluates constraints, and determines appropriate actions based on configurable policies.

**Key Capabilities:** specialized operations, action execution, data retrieval

**Module Statistics:**
- Functions: 12
- Lines of Code: 620
- Exported Members: 1


**Module Details:**
- **Path:** `Modules\Unity-Claude-CLIOrchestrator\Core\DecisionEngineIntegration.psm1`
- **Size:** 23.33 KB
- **Functions:** 12
- **Last Modified:** 2025-08-25 13:45

**Dependencies:** CPG-DataStructures, CrossLanguage-DependencyMaps, BayesianInference, CPG-Unified, Unity-Claude-ParallelProcessor-Original, DecisionEngine-Bayesian, RunspacePoolManager, Unity-Claude-Cache-Original, EnhancedPatternIntegration, ModuleFunctions, LearningAdaptation, Unity-Claude-Cache, Unity-Claude-CLIOrchestrator-Fixed-Simple, ResponseAnalysisEngine-Enhanced, Performance-Cache, Unity-Claude-CPG-Original, Unity-Claude-IntegrationEngine, Unity-Claude-Safety, ResponseAnalysisEngine-Broken, RuleBasedDecisionTrees, Unity-Claude-ErrorHandling, DecisionEngine, Unity-Claude-AutonomousStateTracker, FailureMode, Unity-Claude-Cache-Fixed, CircuitBreaker, ErrorHandling, ResponseAnalysisEngine, EscalationProtocol

--- 
### DecisionExecution

[⬆ Back to Contents](#-table-of-contents)

Decision engine module implementing rule-based and ML-enhanced decision trees. Analyzes inputs, evaluates constraints, and determines appropriate actions based on configurable policies.

**Key Capabilities:** action execution, specialized operations, request processing

**Module Statistics:**
- Functions: 6
- Lines of Code: 369
- Exported Members: 1


**Module Details:**
- **Path:** `Modules\Unity-Claude-CLIOrchestrator\Core\OrchestrationComponents\DecisionExecution.psm1`
- **Size:** 10.67 KB
- **Functions:** 6
- **Last Modified:** 2025-08-27 15:21

**Dependencies:** CPG-DataStructures, CrossLanguage-DependencyMaps, Unity-Claude-PerformanceOptimizer-Original, Unity-Claude-IncrementalProcessor, Unity-Claude-MasterOrchestrator-Original, CPG-Unified, Unity-Claude-ParallelProcessor-Original, Unity-Claude-Cache-Original, Unity-Claude-Cache, WindowManager-Enhanced, Unity-Claude-CLIOrchestrator-Fixed-Simple, DecisionExecution-Fixed, Unity-Claude-PerformanceOptimizer-Refactored, Performance-Cache, Unity-Claude-CPG-Original, Unity-Claude-IncrementalProcessor-Fixed, BatchProcessingEngine, WindowManager-Original, Unity-Claude-CLISubmission-Enhanced, Unity-Claude-CLIOrchestrator-FullFeatured, Unity-Claude-Cache-Fixed, Unity-Claude-CLIOrchestrator-Original, ClaudeIntegration

--- 
### DecisionExecution-Fixed

[⬆ Back to Contents](#-table-of-contents)

Decision engine module implementing rule-based and ML-enhanced decision trees. Analyzes inputs, evaluates constraints, and determines appropriate actions based on configurable policies.

**Key Capabilities:** action execution, specialized operations

**Module Statistics:**
- Functions: 2
- Lines of Code: 147


**Module Details:**
- **Path:** `Modules\Unity-Claude-CLIOrchestrator\Core\OrchestrationComponents\DecisionExecution-Fixed.psm1`
- **Size:** 4.86 KB
- **Functions:** 2
- **Last Modified:** 2025-08-27 17:21

**Dependencies:** CPG-DataStructures, CrossLanguage-DependencyMaps, Unity-Claude-MasterOrchestrator-Original, CPG-Unified, DecisionExecution, Unity-Claude-Cache-Original, Unity-Claude-Cache, Unity-Claude-CLIOrchestrator-Fixed-Simple, Performance-Cache, Unity-Claude-CPG-Original, Unity-Claude-Cache-Fixed, Unity-Claude-CLIOrchestrator-Original

--- 
### DecisionMaking

[⬆ Back to Contents](#-table-of-contents)

Decision engine module implementing rule-based and ML-enhanced decision trees. Analyzes inputs, evaluates constraints, and determines appropriate actions based on configurable policies.

**Key Capabilities:** action execution, validation and testing

**Module Statistics:**
- Functions: 3
- Lines of Code: 262
- Exported Members: 1


**Module Details:**
- **Path:** `Modules\Unity-Claude-CLIOrchestrator\Core\OrchestrationComponents\DecisionMaking.psm1`
- **Size:** 9.43 KB
- **Functions:** 3
- **Last Modified:** 2025-08-27 15:21

**Dependencies:** Unity-Claude-Cache-Original, Unity-Claude-Cache, Unity-Claude-CLIOrchestrator-Fixed-Simple, Performance-Cache, DecisionMaking-Fixed, Unity-Claude-Cache-Fixed, Unity-Claude-CLIOrchestrator-Original

--- 
### DecisionMaking-Fixed

[⬆ Back to Contents](#-table-of-contents)

Decision engine module implementing rule-based and ML-enhanced decision trees. Analyzes inputs, evaluates constraints, and determines appropriate actions based on configurable policies.

**Key Capabilities:** action execution, validation and testing

**Module Statistics:**
- Functions: 3
- Lines of Code: 218


**Module Details:**
- **Path:** `Modules\Unity-Claude-CLIOrchestrator\Core\OrchestrationComponents\DecisionMaking-Fixed.psm1`
- **Size:** 7.61 KB
- **Functions:** 3
- **Last Modified:** 2025-08-27 17:21

**Dependencies:** Unity-Claude-Cache-Original, Unity-Claude-Cache, Unity-Claude-CLIOrchestrator-Fixed-Simple, Performance-Cache, Unity-Claude-Cache-Fixed, Unity-Claude-CLIOrchestrator-Original, DecisionMaking

--- 
### DepaAlgorithm

[⬆ Back to Contents](#-table-of-contents)

Specialized module providing targeted functionality for the Unity-Claude automation system. Integrates with the broader architecture to deliver specific capabilities.

**Key Capabilities:** data retrieval, validation and testing

**Module Statistics:**
- Functions: 4
- Lines of Code: 353
- Exported Members: 1


**Module Details:**
- **Path:** `Modules\Unity-Claude-CPG\Core\DepaAlgorithm.psm1`
- **Size:** 13.6 KB
- **Functions:** 3
- **Last Modified:** 2025-08-26 11:46

**Dependencies:** Unity-Claude-ParallelProcessor-Original, Unity-Claude-Cache-Original, ModuleFunctions, Unity-Claude-Cache, Performance-Cache, Unity-Claude-Cache-Fixed

--- 
### DependencyManagement

[⬆ Back to Contents](#-table-of-contents)

Specialized module providing targeted functionality for the Unity-Claude automation system. Integrates with the broader architecture to deliver specific capabilities.

**Key Capabilities:** validation and testing, system initialization, specialized operations, data retrieval

**Module Statistics:**
- Functions: 5
- Lines of Code: 174
- Exported Members: 1


**Module Details:**
- **Path:** `Modules\Unity-Claude-IntegratedWorkflow\Core\DependencyManagement.psm1`
- **Size:** 7.8 KB
- **Functions:** 5
- **Last Modified:** 2025-08-26 11:46

**Dependencies:** Unity-Claude-UnityParallelization-Original, Unity-Claude-PerformanceOptimizer-Original, Unity-Claude-IncrementalProcessor, Unity-Claude-ParallelProcessor-Original, Unity-Claude-Cache-Original, ModuleFunctions, Unity-Claude-Cache, RunspaceCore, Unity-Claude-PerformanceOptimizer-Refactored, Performance-Cache, Unity-Claude-ClaudeParallelization, Unity-Claude-IncrementalProcessor-Fixed, BatchProcessingEngine, ParallelizationCore, Unity-Claude-Cache-Fixed, Unity-Claude-RunspaceManagement-Original, Unity-Claude-IntegratedWorkflow-Original

--- 
### DocumentationAccuracy

[⬆ Back to Contents](#-table-of-contents)

Documentation automation module providing real-time documentation updates. Generates API docs, maintains cross-references, and ensures documentation accuracy.

**Key Capabilities:** validation and testing, specialized operations

**Module Statistics:**
- Functions: 12
- Lines of Code: 685
- Exported Members: 1


**Module Details:**
- **Path:** `Modules\Unity-Claude-CPG\Core\DocumentationAccuracy.psm1`
- **Size:** 25.41 KB
- **Functions:** 10
- **Last Modified:** 2025-08-26 11:46

**Dependencies:** CPG-DataStructures, CrossLanguage-DependencyMaps, DocumentationComparison, CPG-Unified, Unity-Claude-Cache-Original, Unity-Claude-Cache, Performance-Cache, Unity-Claude-CPG-Original, Unity-Claude-Cache-Fixed

--- 
### DocumentationComparison

[⬆ Back to Contents](#-table-of-contents)

Documentation automation module providing real-time documentation updates. Generates API docs, maintains cross-references, and ensures documentation accuracy.

**Key Capabilities:** specialized operations, data retrieval

**Module Statistics:**
- Functions: 7
- Lines of Code: 596
- Exported Members: 1


**Module Details:**
- **Path:** `Modules\Unity-Claude-CPG\Core\DocumentationComparison.psm1`
- **Size:** 22.14 KB
- **Functions:** 6
- **Last Modified:** 2025-08-26 11:46

**Dependencies:** Unity-Claude-Cache-Original, Unity-Claude-Cache, Performance-Cache, DocumentationAccuracy, Unity-Claude-Cache-Fixed

--- 
### EnhancedPatternIntegration

[⬆ Back to Contents](#-table-of-contents)

Specialized module providing targeted functionality for the Unity-Claude automation system. Integrates with the broader architecture to deliver specific capabilities.

**Key Capabilities:** action execution, specialized operations

**Module Statistics:**
- Functions: 3
- Lines of Code: 160
- Exported Members: 1


**Module Details:**
- **Path:** `Modules\Unity-Claude-CLIOrchestrator\Core\DecisionEngine-Bayesian\EnhancedPatternIntegration.psm1`
- **Size:** 7.34 KB
- **Functions:** 3
- **Last Modified:** 2025-08-26 11:46

**Dependencies:** BayesianInference, EntityContextEngine, DecisionEngine-Bayesian, Unity-Claude-Cache-Original, PatternRecognitionEngine-Original, Unity-Claude-Cache, ResponseAnalysisEngine-Enhanced, Performance-Cache, TemporalContextTracking, ConfigurationLogging, ResponseAnalysisEngine-Broken, DecisionEngine, Unity-Claude-Cache-Fixed, EntityRelationshipManagement, PatternAnalysis, ResponseAnalysisEngine

--- 
### EntityContextEngine

[⬆ Back to Contents](#-table-of-contents)

Specialized module providing targeted functionality for the Unity-Claude automation system. Integrates with the broader architecture to deliver specific capabilities.

**Key Capabilities:** specialized operations, data retrieval, action execution

**Module Statistics:**
- Functions: 14
- Lines of Code: 704
- Exported Members: 1


**Module Details:**
- **Path:** `Modules\Unity-Claude-CLIOrchestrator\Core\EntityContextEngine.psm1`
- **Size:** 24.74 KB
- **Functions:** 14
- **Last Modified:** 2025-08-26 11:46

**Dependencies:** CrossLanguage-DependencyMaps, Unity-Claude-PerformanceOptimizer-Original, Unity-Claude-IncrementalProcessor, Unity-Claude-ParallelProcessor-Original, DecisionEngine-Bayesian, Unity-Claude-Cache-Original, PatternRecognitionEngine-Original, Unity-Claude-Cache, Unity-Claude-CrossLanguage, ResponseAnalysisEngine-Enhanced, Unity-Claude-PerformanceOptimizer-Refactored, Performance-Cache, ErrorDetection, Unity-Claude-Learning-Original, CrossLanguage-GraphMerger, ResponseAnalysis, Unity-Claude-IncrementalProcessor-Fixed, Unity-Claude-Learning-Simple, ResponseAnalysisEngine-Broken, BatchProcessingEngine, StringSimilarity, CodeRedundancyDetection, Unity-Claude-DecisionEngine-Original, UnityIntegration, Unity-Claude-Cache-Fixed, Unity-Claude-AIAlertClassifier, EntityRelationshipManagement, PatternAnalysis, ResponseAnalysisEngine

--- 
### EntityRelationshipManagement

[⬆ Back to Contents](#-table-of-contents)

Specialized module providing targeted functionality for the Unity-Claude automation system. Integrates with the broader architecture to deliver specific capabilities.

**Key Capabilities:** specialized operations

**Module Statistics:**
- Functions: 3
- Lines of Code: 266
- Exported Members: 1


**Module Details:**
- **Path:** `Modules\Unity-Claude-CLIOrchestrator\Core\DecisionEngine-Bayesian\EntityRelationshipManagement.psm1`
- **Size:** 9.27 KB
- **Functions:** 3
- **Last Modified:** 2025-08-26 11:46

**Dependencies:** EntityContextEngine, DecisionEngine-Bayesian, Unity-Claude-Cache-Original, PatternRecognitionEngine-Original, Unity-Claude-Cache, ResponseAnalysisEngine-Enhanced, Performance-Cache, ConfigurationLogging, ResponseAnalysisEngine-Broken, DecisionEngine, Unity-Claude-Cache-Fixed, ResponseAnalysisEngine

--- 
### ErrorDetection

[⬆ Back to Contents](#-table-of-contents)

Specialized module providing targeted functionality for the Unity-Claude automation system. Integrates with the broader architecture to deliver specific capabilities.

**Key Capabilities:** process initiation, specialized operations, data retrieval

**Module Statistics:**
- Functions: 7
- Lines of Code: 676
- Exported Members: 1


**Module Details:**
- **Path:** `Modules\Unity-Claude-UnityParallelization\Core\ErrorDetection.psm1`
- **Size:** 28.25 KB
- **Functions:** 6
- **Last Modified:** 2025-08-26 11:46

**Dependencies:** CPG-DataStructures, CrossLanguage-DependencyMaps, Unity-Claude-UnityParallelization-Original, Unity-Claude-PerformanceOptimizer-Original, JobScheduler, Unity-Claude-IncrementalProcessor, CPG-Unified, EntityContextEngine, Unity-Claude-ParallelProcessor-Original, RunspacePoolManager, Unity-Claude-Cache-Original, StatisticsTracker, ModuleFunctions, Unity-Claude-Cache, Unity-Claude-CrossLanguage, Unity-Claude-PerformanceOptimizer-Refactored, Performance-Cache, Unity-Claude-Learning-Original, Unity-Claude-CPG-Original, Unity-Claude-IncrementalProcessor-Fixed, Unity-Claude-Learning-Simple, BatchProcessingEngine, StringSimilarity, ParallelizationCore, UnityIntegration, Unity-Claude-Cache-Fixed, Unity-Claude-AIAlertClassifier, ProjectConfiguration

--- 
### ErrorExport

[⬆ Back to Contents](#-table-of-contents)

Specialized module providing targeted functionality for the Unity-Claude automation system. Integrates with the broader architecture to deliver specific capabilities.

**Key Capabilities:** specialized operations, validation and testing

**Module Statistics:**
- Functions: 3
- Lines of Code: 406
- Exported Members: 1


**Module Details:**
- **Path:** `Modules\Unity-Claude-UnityParallelization\Core\ErrorExport.psm1`
- **Size:** 16.9 KB
- **Functions:** 3
- **Last Modified:** 2025-08-26 11:46

**Dependencies:** CPG-DataStructures, CrossLanguage-DependencyMaps, Unity-Claude-UnityParallelization-Original, Unity-Claude-PerformanceOptimizer-Original, Unity-Claude-IncrementalProcessor, CPG-Unified, Unity-Claude-ParallelProcessor-Original, Unity-Claude-Cache-Original, Unity-Claude-Cache, Unity-Claude-PerformanceOptimizer-Refactored, Performance-Cache, ErrorDetection, ProductionRunspacePool, Unity-Claude-CPG-Original, Unity-Claude-IncrementalProcessor-Fixed, BatchProcessingEngine, ParallelizationCore, Unity-Claude-Cache-Fixed, Unity-Claude-RunspaceManagement-Original

--- 
### ErrorHandling

[⬆ Back to Contents](#-table-of-contents)

Specialized module providing targeted functionality for the Unity-Claude automation system. Integrates with the broader architecture to deliver specific capabilities.

**Key Capabilities:** action execution, data retrieval, validation and testing, configuration management

**Module Statistics:**
- Functions: 11
- Lines of Code: 687
- Exported Members: 1


**Module Details:**
- **Path:** `Modules\Unity-Claude-AutonomousAgent\Execution\ErrorHandling.psm1`
- **Size:** 22.55 KB
- **Functions:** 11
- **Last Modified:** 2025-08-20 17:25

**Dependencies:** CPG-DataStructures, CrossLanguage-DependencyMaps, Unity-Claude-PerformanceOptimizer-Original, Unity-Claude-IncrementalProcessor, CPG-Unified, Unity-Claude-ParallelProcessor-Original, RunspacePoolManager, Unity-Claude-Cache-Original, ModuleFunctions, Unity-Claude-Cache, Unity-Claude-ParallelProcessing, AgentLogging, Unity-Claude-PerformanceOptimizer-Refactored, Performance-Cache, Unity-Claude-CPG-Original, Unity-Claude-IncrementalProcessor-Fixed, ResponseAnalysisEngine-Broken, Unity-Claude-ErrorHandling, BatchProcessingEngine, ProgressTracker, Unity-Claude-ScalabilityEnhancements-Original, Unity-Claude-AutonomousStateTracker, Unity-Claude-Cache-Fixed, CircuitBreaker

--- 
### EscalationProtocol

[⬆ Back to Contents](#-table-of-contents)

Specialized module providing targeted functionality for the Unity-Claude automation system. Integrates with the broader architecture to deliver specific capabilities.

**Key Capabilities:** specialized operations, resource creation, action execution

**Module Statistics:**
- Functions: 16
- Lines of Code: 1146
- Exported Members: 1


**Module Details:**
- **Path:** `Modules\Unity-Claude-CLIOrchestrator\Core\EscalationProtocol.psm1`
- **Size:** 37.63 KB
- **Functions:** 16
- **Last Modified:** 2025-08-25 13:45

**Dependencies:** CPG-DataStructures, CrossLanguage-DependencyMaps, Unity-Claude-PerformanceOptimizer-Original, Unity-Claude-IncrementalProcessor, Performance-IncrementalUpdates, CPG-Unified, Unity-Claude-EmailNotifications-SystemNetMail, Unity-Claude-ParallelProcessor-Original, Unity-Claude-Cache-Original, Unity-Claude-Cache, MetricsAndHealthCheck, Unity-Claude-PerformanceOptimizer-Refactored, Performance-Cache, Unity-Claude-CPG-Original, Unity-Claude-IncrementalProcessor-Fixed, BatchProcessingEngine, FailureMode, Unity-Claude-Cache-Fixed

--- 
### EventProcessing

[⬆ Back to Contents](#-table-of-contents)

Specialized module providing targeted functionality for the Unity-Claude automation system. Integrates with the broader architecture to deliver specific capabilities.

**Key Capabilities:** process initiation, specialized operations

**Module Statistics:**
- Functions: 11
- Lines of Code: 491
- Exported Members: 1


**Module Details:**
- **Path:** `Modules\Unity-Claude-MasterOrchestrator\Core\EventProcessing.psm1`
- **Size:** 15.59 KB
- **Functions:** 11
- **Last Modified:** 2025-08-26 11:46

**Dependencies:** CPG-DataStructures, CrossLanguage-DependencyMaps, Unity-Claude-PerformanceOptimizer-Original, Unity-Claude-IncrementalProcessor, Unity-Claude-MasterOrchestrator-Original, CPG-Unified, Unity-Claude-ParallelProcessor-Original, Unity-Claude-Cache-Original, ModuleFunctions, Unity-Claude-Cache, Unity-Claude-PerformanceOptimizer-Refactored, Unity-Claude-RealTimeMonitoring, Performance-Cache, Unity-Claude-CPG-Original, Unity-Claude-IncrementalProcessor-Fixed, BatchProcessingEngine, OrchestratorCore, Unity-Claude-Cache-Fixed

--- 
### FailureMode

[⬆ Back to Contents](#-table-of-contents)

Specialized module providing targeted functionality for the Unity-Claude automation system. Integrates with the broader architecture to deliver specific capabilities.

**Key Capabilities:** validation and testing, action execution, specialized operations

**Module Statistics:**
- Functions: 12
- Lines of Code: 653
- Exported Members: 1


**Module Details:**
- **Path:** `Modules\Unity-Claude-AutonomousAgent\Execution\FailureMode.psm1`
- **Size:** 20.87 KB
- **Functions:** 12
- **Last Modified:** 2025-08-20 17:25

**Dependencies:** Unity-Claude-Cache-Original, Unity-Claude-Cache, Unity-Claude-ParallelProcessing, AgentLogging, Performance-Cache, Unity-Claude-AutonomousStateTracker, Unity-Claude-Cache-Fixed, EscalationProtocol

--- 
### FallbackMechanisms

[⬆ Back to Contents](#-table-of-contents)

Specialized module providing targeted functionality for the Unity-Claude automation system. Integrates with the broader architecture to deliver specific capabilities.

**Key Capabilities:** resource creation, action execution, validation and testing, data retrieval, specialized operations

**Module Statistics:**
- Functions: 7
- Lines of Code: 253
- Exported Members: 1


**Module Details:**
- **Path:** `Modules\Unity-Claude-NotificationIntegration\Reliability\FallbackMechanisms.psm1`
- **Size:** 8.83 KB
- **Functions:** 7
- **Last Modified:** 2025-08-21 17:45

**Dependencies:** CPG-DataStructures, CrossLanguage-DependencyMaps, Unity-Claude-NotificationIntegration, CPG-Unified, RunspacePoolManager, Unity-Claude-Cache-Original, Unity-Claude-Cache, IntegratedNotifications, Performance-Cache, Unity-Claude-CPG-Original, NotificationCore, Unity-Claude-Cache-Fixed

--- 
### FallbackStrategies

[⬆ Back to Contents](#-table-of-contents)

Specialized module providing targeted functionality for the Unity-Claude automation system. Integrates with the broader architecture to deliver specific capabilities.

**Key Capabilities:** specialized operations, action execution, data retrieval

**Module Statistics:**
- Functions: 4
- Lines of Code: 236
- Exported Members: 1


**Module Details:**
- **Path:** `Modules\Unity-Claude-CLIOrchestrator\Core\DecisionEngine\FallbackStrategies.psm1`
- **Size:** 9.11 KB
- **Functions:** 4
- **Last Modified:** 2025-08-26 11:46

**Dependencies:** Unity-Claude-PerformanceOptimizer-Original, Unity-Claude-IncrementalProcessor, Unity-Claude-ParallelProcessor-Original, Unity-Claude-Cache-Original, Unity-Claude-Cache, Unity-Claude-PerformanceOptimizer-Refactored, Performance-Cache, Unity-Claude-IncrementalProcessor-Fixed, ConfigurationLogging, BatchProcessingEngine, DecisionEngine, Unity-Claude-Cache-Fixed

--- 
### FileProcessing

[⬆ Back to Contents](#-table-of-contents)

Specialized module providing targeted functionality for the Unity-Claude automation system. Integrates with the broader architecture to deliver specific capabilities.

**Key Capabilities:** action execution

**Module Statistics:**
- Functions: 9
- Lines of Code: 307
- Exported Members: 1


**Module Details:**
- **Path:** `Modules\Unity-Claude-PerformanceOptimizer\Core\FileProcessing.psm1`
- **Size:** 9.6 KB
- **Functions:** 9
- **Last Modified:** 2025-08-26 11:46

**Dependencies:** Unity-Claude-Cache-Original, Unity-Claude-Cache, Performance-Cache, Unity-Claude-CPG-ASTConverter, OptimizerConfiguration, Unity-Claude-Cache-Fixed

--- 
### FileSystemMonitoring

[⬆ Back to Contents](#-table-of-contents)

Real-time monitoring module tracking system health and performance metrics. Provides event-driven notifications and automated issue response.

**Key Capabilities:** process initiation, process termination, data retrieval, validation and testing

**Module Statistics:**
- Functions: 4
- Lines of Code: 442
- Exported Members: 1


**Module Details:**
- **Path:** `Modules\Unity-Claude-AutonomousAgent\Monitoring\FileSystemMonitoring.psm1`
- **Size:** 20.74 KB
- **Functions:** 4
- **Last Modified:** 2025-08-20 17:25

**Dependencies:** Unity-Claude-PerformanceOptimizer-Original, JobScheduler, Unity-Claude-IncrementalProcessor, Unity-Claude-ParallelProcessor-Original, RunspacePoolManager, Unity-Claude-Cache-Original, StatisticsTracker, ModuleFunctions, Unity-Claude-Cache, Unity-Claude-ParallelProcessing, AgentLogging, Unity-Claude-PerformanceOptimizer-Refactored, Performance-Cache, Unity-Claude-IncrementalProcessor-Fixed, Unity-Claude-ResponseMonitoring, Unity-Claude-ResponseMonitor, BatchProcessingEngine, Unity-Claude-Cache-Fixed, StateMachineCore

--- 
### GitHubPRManager

[⬆ Back to Contents](#-table-of-contents)

GitHub integration module for version control operations. Handles commits, pull requests, issue management, and repository automation.

**Key Capabilities:** resource creation, specialized operations, data retrieval, validation and testing

**Module Statistics:**
- Functions: 5
- Lines of Code: 456
- Exported Members: 1


**Module Details:**
- **Path:** `Modules\Unity-Claude-DocumentationAutomation\Core\GitHubPRManager.psm1`
- **Size:** 14.91 KB
- **Functions:** 5
- **Last Modified:** 2025-08-26 11:46

**Dependencies:** RunspacePoolManager, Unity-Claude-Cache-Original, Unity-Claude-Cache, Performance-Cache, Unity-Claude-DocumentationDrift, Unity-Claude-Cache-Fixed, Unity-Claude-DocumentationAutomation-Original

--- 
### GoalManagement

[⬆ Back to Contents](#-table-of-contents)

Specialized module providing targeted functionality for the Unity-Claude automation system. Integrates with the broader architecture to deliver specific capabilities.

**Key Capabilities:** specialized operations, data retrieval

**Module Statistics:**
- Functions: 8
- Lines of Code: 463
- Exported Members: 1


**Module Details:**
- **Path:** `Modules\Unity-Claude-AutonomousAgent\Core\GoalManagement.psm1`
- **Size:** 15.85 KB
- **Functions:** 8
- **Last Modified:** 2025-08-26 11:46

**Dependencies:** CPG-DataStructures, CrossLanguage-DependencyMaps, CPG-Unified, Unity-Claude-Cache-Original, ConversationStateManager, Unity-Claude-Cache, RoleAwareManagement, PersistenceManagement, Performance-Cache, Unity-Claude-CPG-Original, Unity-Claude-Cache-Fixed

--- 
### GraphOptimizer

[⬆ Back to Contents](#-table-of-contents)

Specialized module providing targeted functionality for the Unity-Claude automation system. Integrates with the broader architecture to deliver specific capabilities.

**Key Capabilities:** process initiation, cleanup operations, specialized operations, data retrieval

**Module Statistics:**
- Functions: 5
- Lines of Code: 358
- Classes: 1
- Exported Members: 1


**Module Details:**
- **Path:** `Modules\Unity-Claude-ScalabilityEnhancements\Core\GraphOptimizer.psm1`
- **Size:** 12.18 KB
- **Functions:** 12
- **Last Modified:** 2025-08-26 11:46

**Dependencies:** Unity-Claude-PerformanceOptimizer-Original, Unity-Claude-IncrementalProcessor, Unity-Claude-ParallelProcessor-Original, Unity-Claude-Cache-Original, Unity-Claude-Cache, Unity-Claude-PerformanceOptimizer-Refactored, Performance-Cache, Unity-Claude-IncrementalProcessor-Fixed, BatchProcessingEngine, Unity-Claude-ScalabilityEnhancements-Original, Unity-Claude-Cache-Fixed

--- 
### GraphTraversal

[⬆ Back to Contents](#-table-of-contents)

Specialized module providing targeted functionality for the Unity-Claude automation system. Integrates with the broader architecture to deliver specific capabilities.

**Key Capabilities:** specialized operations

**Module Statistics:**
- Functions: 1
- Lines of Code: 255
- Classes: 2
- Exported Members: 1


**Module Details:**
- **Path:** `Modules\Unity-Claude-CPG\Core\GraphTraversal.psm1`
- **Size:** 10.32 KB
- **Functions:** 3
- **Last Modified:** 2025-08-26 11:46

**Dependencies:** Unity-Claude-PerformanceOptimizer-Original, Unity-Claude-IncrementalProcessor, Unity-Claude-ParallelProcessor-Original, Unity-Claude-Cache-Original, ModuleFunctions, Unity-Claude-Cache, Unity-Claude-PerformanceOptimizer-Refactored, Performance-Cache, Unity-Claude-IncrementalProcessor-Fixed, BatchProcessingEngine, Unity-Claude-Cache-Fixed

--- 
### HealthMonitoring

[⬆ Back to Contents](#-table-of-contents)

Real-time monitoring module tracking system health and performance metrics. Provides event-driven notifications and automated issue response.

**Key Capabilities:** process initiation, process termination, data retrieval, validation and testing

**Module Statistics:**
- Functions: 4
- Lines of Code: 257
- Exported Members: 1


**Module Details:**
- **Path:** `Modules\Unity-Claude-AutonomousStateTracker-Enhanced\Core\HealthMonitoring.psm1`
- **Size:** 10.12 KB
- **Functions:** 4
- **Last Modified:** 2025-08-26 11:46

**Dependencies:** Unity-Claude-PerformanceOptimizer-Original, Unity-Claude-IncrementalProcessor, Unity-Claude-ParallelProcessor-Original, Unity-Claude-Cache-Original, Unity-Claude-Cache, StateConfiguration, Unity-Claude-PerformanceOptimizer-Refactored, Performance-Cache, Unity-Claude-IncrementalProcessor-Fixed, HumanIntervention, BatchProcessingEngine, Unity-Claude-Cache-Fixed, StateMachineCore

--- 
### HistoryManagement

[⬆ Back to Contents](#-table-of-contents)

Specialized module providing targeted functionality for the Unity-Claude automation system. Integrates with the broader architecture to deliver specific capabilities.

**Key Capabilities:** specialized operations, data retrieval

**Module Statistics:**
- Functions: 7
- Lines of Code: 390
- Exported Members: 1


**Module Details:**
- **Path:** `Modules\Unity-Claude-AutonomousAgent\Core\HistoryManagement.psm1`
- **Size:** 14.05 KB
- **Functions:** 6
- **Last Modified:** 2025-08-26 11:46

**Dependencies:** Unity-Claude-Cache-Original, ConversationStateManager, Unity-Claude-Cache, PersistenceManagement, Performance-Cache, Unity-Claude-Cache-Fixed

--- 
### HITLCore

[⬆ Back to Contents](#-table-of-contents)

Core infrastructure module providing fundamental functionality for the Unity-Claude system. This module serves as the foundation for other components, offering essential utilities, configuration management, and base services.

**Key Capabilities:** configuration management, data retrieval

**Module Statistics:**
- Functions: 2
- Lines of Code: 145
- Exported Members: 1


**Module Details:**
- **Path:** `Modules\Unity-Claude-HITL\Core\HITLCore.psm1`
- **Size:** 5.03 KB
- **Functions:** 2
- **Last Modified:** 2025-08-26 11:46

**Dependencies:** Unity-Claude-HITL-Original, Unity-Claude-Cache-Original, Unity-Claude-Cache, Performance-Cache, Unity-Claude-Cache-Fixed

--- 
### HorizontalScaling

[⬆ Back to Contents](#-table-of-contents)

Specialized module providing targeted functionality for the Unity-Claude automation system. Integrates with the broader architecture to deliver specific capabilities.

**Key Capabilities:** resource creation, validation and testing, specialized operations

**Module Statistics:**
- Functions: 4
- Lines of Code: 303
- Classes: 1
- Exported Members: 1


**Module Details:**
- **Path:** `Modules\Unity-Claude-ScalabilityEnhancements\Core\HorizontalScaling.psm1`
- **Size:** 10.83 KB
- **Functions:** 7
- **Last Modified:** 2025-08-26 11:46

**Dependencies:** Unity-Claude-ScalabilityEnhancements-Original

--- 
### HumanIntervention

[⬆ Back to Contents](#-table-of-contents)

Specialized module providing targeted functionality for the Unity-Claude automation system. Integrates with the broader architecture to deliver specific capabilities.

**Key Capabilities:** specialized operations, data retrieval

**Module Statistics:**
- Functions: 6
- Lines of Code: 371
- Exported Members: 1


**Module Details:**
- **Path:** `Modules\Unity-Claude-AutonomousStateTracker-Enhanced\Core\HumanIntervention.psm1`
- **Size:** 13.89 KB
- **Functions:** 6
- **Last Modified:** 2025-08-26 11:46

**Dependencies:** Unity-Claude-PerformanceOptimizer-Original, Unity-Claude-IncrementalProcessor, Unity-Claude-ParallelProcessor-Original, Unity-Claude-Cache-Original, Unity-Claude-Cache, StateConfiguration, Unity-Claude-PerformanceOptimizer-Refactored, Performance-Cache, Unity-Claude-IncrementalProcessor-Fixed, Unity-Claude-GitHub, BatchProcessingEngine, Unity-Claude-Cache-Fixed, StateMachineCore

--- 
### ImpactAnalysis

[⬆ Back to Contents](#-table-of-contents)

Specialized module providing targeted functionality for the Unity-Claude automation system. Integrates with the broader architecture to deliver specific capabilities.

**Key Capabilities:** specialized operations

**Module Statistics:**
- Functions: 7
- Lines of Code: 432
- Exported Members: 1


**Module Details:**
- **Path:** `Modules\Unity-Claude-DocumentationDrift\Analysis\ImpactAnalysis.psm1`
- **Size:** 14.86 KB
- **Functions:** 7
- **Last Modified:** 2025-08-26 11:46

**Dependencies:** Unity-Claude-IntelligentDocumentationTriggers, Unity-Claude-ParallelProcessor-Original, Unity-Claude-Cache-Original, ModuleFunctions, Unity-Claude-Cache, Performance-Cache, Unity-Claude-DocumentationDrift, Unity-Claude-Cache-Fixed

--- 
### ImprovementRoadmaps

[⬆ Back to Contents](#-table-of-contents)

Specialized module providing targeted functionality for the Unity-Claude automation system. Integrates with the broader architecture to deliver specific capabilities.

**Key Capabilities:** resource creation, specialized operations

**Module Statistics:**
- Functions: 12
- Lines of Code: 1024
- Exported Members: 1


**Module Details:**
- **Path:** `Modules\Unity-Claude-PredictiveAnalysis\Core\ImprovementRoadmaps.psm1`
- **Size:** 36.86 KB
- **Functions:** 12
- **Last Modified:** 2025-08-26 11:46

**Dependencies:** Unity-Claude-PerformanceOptimizer-Original, Unity-Claude-IncrementalProcessor, RefactoringDetection, Unity-Claude-ParallelProcessor-Original, Unity-Claude-Cache-Original, CodeSmellPrediction, ModuleFunctions, Unity-Claude-Cache, Predictive-Maintenance, MaintenancePrediction, Unity-Claude-PredictiveAnalysis-Original, Unity-Claude-PerformanceOptimizer-Refactored, Performance-Cache, TrendAnalysis, Unity-Claude-IncrementalProcessor-Fixed, Unity-Claude-LLM, BatchProcessingEngine, Unity-Claude-MachineLearning, Unity-Claude-Cache-Fixed

--- 
### IntegratedNotifications

[⬆ Back to Contents](#-table-of-contents)

Specialized module providing targeted functionality for the Unity-Claude automation system. Integrates with the broader architecture to deliver specific capabilities.

**Key Capabilities:** specialized operations, validation and testing

**Module Statistics:**
- Functions: 3
- Lines of Code: 323
- Exported Members: 1


**Module Details:**
- **Path:** `Modules\Unity-Claude-NotificationIntegration\Integration\IntegratedNotifications.psm1`
- **Size:** 11.62 KB
- **Functions:** 3
- **Last Modified:** 2025-08-21 17:45

**Dependencies:** CPG-DataStructures, CrossLanguage-DependencyMaps, Unity-Claude-NotificationIntegration, CPG-Unified, Unity-Claude-EmailNotifications-SystemNetMail, Unity-Claude-Cache-Original, Unity-Claude-Cache, Unity-Claude-EmailNotifications, Performance-Cache, Unity-Claude-CPG-Original, NotificationCore, Unity-Claude-Cache-Fixed, Unity-Claude-WebhookNotifications

--- 
### IntegrationManagement

[⬆ Back to Contents](#-table-of-contents)

Specialized module providing targeted functionality for the Unity-Claude automation system. Integrates with the broader architecture to deliver specific capabilities.

**Key Capabilities:** specialized operations, data retrieval, validation and testing

**Module Statistics:**
- Functions: 6
- Lines of Code: 360
- Exported Members: 1


**Module Details:**
- **Path:** `Modules\Unity-Claude-DecisionEngine\Core\IntegrationManagement.psm1`
- **Size:** 13.75 KB
- **Functions:** 6
- **Last Modified:** 2025-08-26 11:46

**Dependencies:** Unity-Claude-Cache-Original, ConversationStateManager, Unity-Claude-Cache, Performance-Cache, ResponseAnalysis, Unity-Claude-ResponseMonitor, Unity-Claude-DecisionEngine-Original, StateManagement, Unity-Claude-FixEngine, DecisionEngine-Refactored, Unity-Claude-Cache-Fixed, DecisionEngineCore

--- 
### IntelligentPromptEngine

[⬆ Back to Contents](#-table-of-contents)

Specialized module providing targeted functionality for the Unity-Claude automation system. Integrates with the broader architecture to deliver specific capabilities.

**Key Capabilities:** action execution, resource creation, data retrieval, validation and testing, system initialization

**Module Statistics:**
- Functions: 5
- Lines of Code: 426
- Exported Members: 2


**Module Details:**
- **Path:** `Modules\Unity-Claude-AutonomousAgent\IntelligentPromptEngine.psm1`
- **Size:** 17.39 KB
- **Functions:** 5
- **Last Modified:** 2025-08-26 11:46

**Dependencies:** CPG-DataStructures, CrossLanguage-DependencyMaps, Unity-Claude-PerformanceOptimizer-Original, Unity-Claude-IncrementalProcessor, CPG-Unified, Unity-Claude-ParallelProcessor-Original, Unity-Claude-Cache-Original, ModuleFunctions, Unity-Claude-Cache, Unity-Claude-ParallelProcessing, AgentLogging, Unity-Claude-PerformanceOptimizer-Refactored, Performance-Cache, ResultAnalysisEngine, Unity-Claude-CPG-Original, Unity-Claude-IncrementalProcessor-Fixed, PromptTypeSelection, BatchProcessingEngine, IntelligentPromptEngine-Refactored, TemplateSystem, Unity-Claude-Cache-Fixed, PromptTemplateSystem, PromptConfiguration

--- 
### IntelligentPromptEngine-Refactored

[⬆ Back to Contents](#-table-of-contents)

Specialized module providing targeted functionality for the Unity-Claude automation system. Integrates with the broader architecture to deliver specific capabilities.

**Key Capabilities:** action execution, resource creation, data retrieval, validation and testing, system initialization

**Module Statistics:**
- Functions: 5
- Lines of Code: 426
- Exported Members: 2


**Module Details:**
- **Path:** `Modules\Unity-Claude-AutonomousAgent\IntelligentPromptEngine-Refactored.psm1`
- **Size:** 17.39 KB
- **Functions:** 5
- **Last Modified:** 2025-08-26 11:46

**Dependencies:** CPG-DataStructures, CrossLanguage-DependencyMaps, Unity-Claude-PerformanceOptimizer-Original, Unity-Claude-IncrementalProcessor, CPG-Unified, Unity-Claude-ParallelProcessor-Original, Unity-Claude-Cache-Original, ModuleFunctions, Unity-Claude-Cache, Unity-Claude-ParallelProcessing, AgentLogging, Unity-Claude-PerformanceOptimizer-Refactored, Performance-Cache, ResultAnalysisEngine, Unity-Claude-CPG-Original, Unity-Claude-IncrementalProcessor-Fixed, PromptTypeSelection, BatchProcessingEngine, IntelligentPromptEngine, TemplateSystem, Unity-Claude-Cache-Fixed, PromptTemplateSystem, PromptConfiguration

--- 
### JobScheduler

[⬆ Back to Contents](#-table-of-contents)

Specialized module providing targeted functionality for the Unity-Claude automation system. Integrates with the broader architecture to deliver specific capabilities.

**Key Capabilities:** resource creation

**Module Statistics:**
- Functions: 1
- Lines of Code: 486
- Classes: 2
- Exported Members: 1


**Module Details:**
- **Path:** `Modules\Unity-Claude-ParallelProcessor\Core\JobScheduler.psm1`
- **Size:** 19.46 KB
- **Functions:** 17
- **Last Modified:** 2025-08-26 11:46

**Dependencies:** CPG-DataStructures, CrossLanguage-DependencyMaps, Unity-Claude-PerformanceOptimizer-Original, Unity-Claude-IncrementalProcessor, CPG-Unified, Unity-Claude-ParallelProcessor-Original, RunspacePoolManager, Unity-Claude-Cache-Original, StatisticsTracker, ModuleFunctions, Unity-Claude-Cache, Unity-Claude-PerformanceOptimizer-Refactored, Performance-Cache, Unity-Claude-CPG-Original, Unity-Claude-IncrementalProcessor-Fixed, BatchProcessingEngine, ProgressTracker, Unity-Claude-ScalabilityEnhancements-Original, Unity-Claude-Cache-Fixed

--- 
### JsonProcessing

[⬆ Back to Contents](#-table-of-contents)

Specialized module providing targeted functionality for the Unity-Claude automation system. Integrates with the broader architecture to deliver specific capabilities.

**Key Capabilities:** specialized operations, validation and testing, action execution

**Module Statistics:**
- Functions: 10
- Lines of Code: 523
- Exported Members: 1


**Module Details:**
- **Path:** `Modules\Unity-Claude-CLIOrchestrator\Core\Components\JsonProcessing.psm1`
- **Size:** 19.5 KB
- **Functions:** 10
- **Last Modified:** 2025-08-26 11:46

**Dependencies:** Unity-Claude-PerformanceOptimizer-Original, Unity-Claude-IncrementalProcessor, Unity-Claude-ParallelProcessor-Original, RunspacePoolManager, Unity-Claude-Cache-Original, Unity-Claude-Cache, Unity-Claude-PerformanceOptimizer-Refactored, Performance-Cache, Unity-Claude-IncrementalProcessor-Fixed, AnalysisLogging, ResponseAnalysisEngine-Broken, BatchProcessingEngine, Unity-Claude-Cache-Fixed, CircuitBreaker

--- 
### LearningAdaptation

[⬆ Back to Contents](#-table-of-contents)

Machine learning module that adapts system behavior based on historical data. Implements online learning, model updates, and performance optimization.

**Key Capabilities:** specialized operations, system initialization

**Module Statistics:**
- Functions: 3
- Lines of Code: 184
- Exported Members: 1


**Module Details:**
- **Path:** `Modules\Unity-Claude-CLIOrchestrator\Core\DecisionEngine-Bayesian\LearningAdaptation.psm1`
- **Size:** 7.47 KB
- **Functions:** 3
- **Last Modified:** 2025-08-26 11:46

**Dependencies:** Unity-Claude-ParallelProcessor-Original, DecisionEngine-Bayesian, Unity-Claude-Cache-Original, ModuleFunctions, Unity-Claude-Cache, Performance-Cache, ConfigurationLogging, DecisionEngine, Unity-Claude-Cache-Fixed

--- 
### LLM-PromptTemplates

[⬆ Back to Contents](#-table-of-contents)

Specialized module providing targeted functionality for the Unity-Claude automation system. Integrates with the broader architecture to deliver specific capabilities.

**Key Capabilities:** data retrieval

**Module Statistics:**
- Functions: 17
- Lines of Code: 495
- Classes: 3
- Exported Members: 1


**Module Details:**
- **Path:** `Modules\Unity-Claude-LLM\Core\LLM-PromptTemplates.psm1`
- **Size:** 13.57 KB
- **Functions:** 15
- **Last Modified:** 2025-08-28 13:58

**Dependencies:** CPG-DataStructures, CrossLanguage-DependencyMaps, CPG-Unified, Unity-Claude-Cache-Original, Unity-Claude-Cache, Performance-Cache, Unity-Claude-CPG-Original, Unity-Claude-Cache-Fixed

--- 
### LLM-ResponseCache

[⬆ Back to Contents](#-table-of-contents)

Intelligent caching system optimizing performance through strategic data persistence. Implements LRU policies, dependency tracking, and automatic invalidation.

**Key Capabilities:** data retrieval, configuration management, cleanup operations, specialized operations

**Module Statistics:**
- Functions: 14
- Lines of Code: 458
- Exported Members: 1


**Module Details:**
- **Path:** `Modules\Unity-Claude-LLM\Core\LLM-ResponseCache.psm1`
- **Size:** 13.88 KB
- **Functions:** 14
- **Last Modified:** 2025-08-30 19:47

**Dependencies:** CPG-DataStructures, CrossLanguage-DependencyMaps, Unity-Claude-PerformanceOptimizer-Original, Unity-Claude-IncrementalProcessor, Performance-IncrementalUpdates, CPG-Unified, Unity-Claude-ParallelProcessor-Original, Unity-Claude-Cache-Original, Unity-Claude-Cache, Unity-Claude-PerformanceOptimizer-Refactored, Performance-Cache, Unity-Claude-CPG-Original, Unity-Claude-IncrementalProcessor-Fixed, BatchProcessingEngine, PerformanceOptimizer, Unity-Claude-SemanticAnalysis-Helpers, Unity-Claude-Cache-Fixed

--- 
### MaintenancePrediction

[⬆ Back to Contents](#-table-of-contents)

Specialized module providing targeted functionality for the Unity-Claude automation system. Integrates with the broader architecture to deliver specific capabilities.

**Key Capabilities:** data retrieval, specialized operations

**Module Statistics:**
- Functions: 3
- Lines of Code: 362
- Exported Members: 1


**Module Details:**
- **Path:** `Modules\Unity-Claude-PredictiveAnalysis\Core\MaintenancePrediction.psm1`
- **Size:** 13.96 KB
- **Functions:** 2
- **Last Modified:** 2025-08-26 11:46

**Dependencies:** Unity-Claude-PerformanceOptimizer-Original, Unity-Claude-IncrementalProcessor, Unity-Claude-ParallelProcessor-Original, Unity-Claude-Cache-Original, ModuleFunctions, Unity-Claude-Cache, Predictive-Maintenance, Unity-Claude-PredictiveAnalysis-Original, Unity-Claude-PerformanceOptimizer-Refactored, Performance-Cache, TrendAnalysis, Unity-Claude-IncrementalProcessor-Fixed, Unity-Claude-LLM, GraphTraversal, CodeComplexityMetrics, BatchProcessingEngine, CodeRedundancyDetection, Unity-Claude-MachineLearning, Unity-Claude-Cache-Fixed

--- 
### MemoryManager

[⬆ Back to Contents](#-table-of-contents)

Specialized module providing targeted functionality for the Unity-Claude automation system. Integrates with the broader architecture to deliver specific capabilities.

**Key Capabilities:** process initiation, data retrieval, specialized operations

**Module Statistics:**
- Functions: 5
- Lines of Code: 274
- Classes: 1
- Exported Members: 1


**Module Details:**
- **Path:** `Modules\Unity-Claude-ScalabilityEnhancements\Core\MemoryManager.psm1`
- **Size:** 9 KB
- **Functions:** 13
- **Last Modified:** 2025-08-26 11:46

**Dependencies:** Unity-Claude-PerformanceOptimizer-Original, JobScheduler, Unity-Claude-IncrementalProcessor, Unity-Claude-ParallelProcessor-Original, RunspacePoolManager, Unity-Claude-Cache-Original, StatisticsTracker, ModuleFunctions, Unity-Claude-Cache, Unity-Claude-PerformanceOptimizer-Refactored, Performance-Cache, Unity-Claude-IncrementalProcessor-Fixed, BatchProcessingEngine, Unity-Claude-ScalabilityEnhancements-Original, Unity-Claude-Cache-Fixed

--- 
### MetricsAndHealthCheck

[⬆ Back to Contents](#-table-of-contents)

Specialized module providing targeted functionality for the Unity-Claude automation system. Integrates with the broader architecture to deliver specific capabilities.

**Key Capabilities:** data retrieval, resource creation, specialized operations

**Module Statistics:**
- Functions: 13
- Lines of Code: 569
- Exported Members: 1


**Module Details:**
- **Path:** `Modules\Unity-Claude-NotificationIntegration\Monitoring\MetricsAndHealthCheck.psm1`
- **Size:** 20.09 KB
- **Functions:** 13
- **Last Modified:** 2025-08-21 17:45

**Dependencies:** Unity-Claude-PerformanceOptimizer-Original, BackgroundJobQueue, MetricsCollection, RunspacePoolManager, Unity-Claude-Cache-Original, Unity-Claude-IPC-Bidirectional-Fixed, Unity-Claude-Cache, ConfigurationManagement, Unity-Claude-PerformanceOptimizer-Refactored, Performance-Cache, QueueManagement, Unity-Claude-DocumentationDrift, CommandExecutionEngine, NotificationCore, Unity-Claude-ScalabilityEnhancements-Original, Unity-Claude-NotificationIntegration-Modular, FallbackMechanisms, Unity-Claude-Cache-Fixed, Unity-Claude-IPC-Bidirectional

--- 
### MetricsCollection

[⬆ Back to Contents](#-table-of-contents)

Specialized module providing targeted functionality for the Unity-Claude automation system. Integrates with the broader architecture to deliver specific capabilities.

**Key Capabilities:** specialized operations, process initiation, process termination, data retrieval

**Module Statistics:**
- Functions: 11
- Lines of Code: 497
- Exported Members: 1


**Module Details:**
- **Path:** `Modules\Unity-Claude-Learning\Core\MetricsCollection.psm1`
- **Size:** 15.74 KB
- **Functions:** 11
- **Last Modified:** 2025-08-26 11:46

**Dependencies:** Unity-Claude-PerformanceOptimizer-Original, JobScheduler, Unity-Claude-IncrementalProcessor, Unity-Claude-ParallelProcessor-Original, RunspacePoolManager, Unity-Claude-Cache-Original, StatisticsTracker, ModuleFunctions, Unity-Claude-Cache, SelfPatching, MetricsAndHealthCheck, RunspaceCore, Unity-Claude-PredictiveAnalysis-Original, AnalyticsReporting, Unity-Claude-PerformanceOptimizer-Refactored, Performance-Cache, ProductionRunspacePool, ModuleVariablePreloading, Unity-Claude-Learning-Original, RunspacePoolManagement, Unity-Claude-IncrementalProcessor-Fixed, SessionStateConfiguration, Unity-Claude-DocumentationDrift, Unity-Claude-Learning-Simple, BatchProcessingEngine, SuccessTracking, Unity-Claude-Cache-Fixed, Unity-Claude-RunspaceManagement-Original, VariableSharing, ThrottlingResourceControl

--- 
### ModuleFunctions

[⬆ Back to Contents](#-table-of-contents)

Specialized module providing targeted functionality for the Unity-Claude automation system. Integrates with the broader architecture to deliver specific capabilities.

**Key Capabilities:** resource creation, action execution, process initiation, data retrieval

**Module Statistics:**
- Functions: 7
- Lines of Code: 563
- Classes: 1
- Exported Members: 3


**Module Details:**
- **Path:** `Modules\Unity-Claude-ParallelProcessor\Core\ModuleFunctions.psm1`
- **Size:** 19.46 KB
- **Functions:** 24
- **Last Modified:** 2025-08-26 11:46

**Dependencies:** Unity-Claude-PerformanceOptimizer-Original, JobScheduler, Unity-Claude-IncrementalProcessor, Performance-IncrementalUpdates, Unity-Claude-ParallelProcessor-Original, RunspacePoolManager, Unity-Claude-Cache-Original, StatisticsTracker, Unity-Claude-Cache, Unity-Claude-PerformanceOptimizer-Refactored, Performance-Cache, RunspacePoolManagement, Unity-Claude-CPG-Original, Unity-Claude-IncrementalProcessor-Fixed, OptimizerConfiguration, BatchProcessingEngine, ProgressTracker, Unity-Claude-ScalabilityEnhancements-Original, Unity-Claude-Cache-Fixed, Unity-Claude-RunspaceManagement-Original

--- 
### ModuleIntegration

[⬆ Back to Contents](#-table-of-contents)

Specialized module providing targeted functionality for the Unity-Claude automation system. Integrates with the broader architecture to deliver specific capabilities.

**Key Capabilities:** validation and testing, system initialization, data retrieval

**Module Statistics:**
- Functions: 8
- Lines of Code: 342
- Exported Members: 1


**Module Details:**
- **Path:** `Modules\Unity-Claude-MasterOrchestrator\Core\ModuleIntegration.psm1`
- **Size:** 13.68 KB
- **Functions:** 4
- **Last Modified:** 2025-08-26 11:46

**Dependencies:** CPG-DataStructures, CrossLanguage-DependencyMaps, Unity-Claude-PerformanceOptimizer-Original, Unity-Claude-IncrementalProcessor, Unity-Claude-MasterOrchestrator-Original, CPG-Unified, Unity-Claude-ParallelProcessor-Original, Unity-Claude-Cache-Original, ModuleFunctions, Unity-Claude-Cache, Unity-Claude-PerformanceOptimizer-Refactored, Performance-Cache, Unity-Claude-CPG-Original, Unity-Claude-IncrementalProcessor-Fixed, BatchProcessingEngine, OrchestratorCore, Unity-Claude-Cache-Fixed

--- 
### ModuleVariablePreloading

[⬆ Back to Contents](#-table-of-contents)

Specialized module providing targeted functionality for the Unity-Claude automation system. Integrates with the broader architecture to deliver specific capabilities.

**Key Capabilities:** specialized operations, system initialization

**Module Statistics:**
- Functions: 7
- Lines of Code: 297
- Exported Members: 1


**Module Details:**
- **Path:** `Modules\Unity-Claude-RunspaceManagement\Core\ModuleVariablePreloading.psm1`
- **Size:** 11.65 KB
- **Functions:** 7
- **Last Modified:** 2025-08-26 11:46

**Dependencies:** Unity-Claude-PerformanceOptimizer-Original, Unity-Claude-IncrementalProcessor, Unity-Claude-ParallelProcessor-Original, MetricsCollection, Unity-Claude-Cache-Original, ModuleFunctions, Unity-Claude-Cache, SelfPatching, RunspaceCore, Unity-Claude-PerformanceOptimizer-Refactored, Performance-Cache, ProductionRunspacePool, RunspacePoolManagement, Unity-Claude-IncrementalProcessor-Fixed, SessionStateConfiguration, BatchProcessingEngine, SuccessTracking, Unity-Claude-Cache-Fixed, Unity-Claude-RunspaceManagement-Original, VariableSharing, ThrottlingResourceControl

--- 
### MonitoringLoop

[⬆ Back to Contents](#-table-of-contents)

Real-time monitoring module tracking system health and performance metrics. Provides event-driven notifications and automated issue response.

**Key Capabilities:** process initiation, action execution, specialized operations

**Module Statistics:**
- Functions: 3
- Lines of Code: 344
- Exported Members: 1


**Module Details:**
- **Path:** `Modules\Unity-Claude-CLIOrchestrator\Core\OrchestrationComponents\MonitoringLoop.psm1`
- **Size:** 15.08 KB
- **Functions:** 3
- **Last Modified:** 2025-08-27 19:19

**Dependencies:** CPG-DataStructures, CrossLanguage-DependencyMaps, Unity-Claude-PerformanceOptimizer-Original, Unity-Claude-IncrementalProcessor, Unity-Claude-MasterOrchestrator-Original, CPG-Unified, DecisionExecution, Unity-Claude-ParallelProcessor-Original, Unity-Claude-Cache-Original, PromptSubmissionEngine, Unity-Claude-Cache, Unity-Claude-CLIOrchestrator-Fixed-Simple, DecisionExecution-Fixed, Unity-Claude-PerformanceOptimizer-Refactored, Performance-Cache, AutonomousOperations, Unity-Claude-CPG-Original, Unity-Claude-IncrementalProcessor-Fixed, ResponseAnalysisEngine-Broken, BatchProcessingEngine, DecisionMaking-Fixed, Unity-Claude-Cache-Fixed, Unity-Claude-CLIOrchestrator-Original, DecisionMaking

--- 
### NotificationCore

[⬆ Back to Contents](#-table-of-contents)

Core infrastructure module providing fundamental functionality for the Unity-Claude system. This module serves as the foundation for other components, offering essential utilities, configuration management, and base services.

**Key Capabilities:** system initialization, specialized operations, data retrieval

**Module Statistics:**
- Functions: 6
- Lines of Code: 418
- Exported Members: 1


**Module Details:**
- **Path:** `Modules\Unity-Claude-NotificationIntegration\Core\NotificationCore.psm1`
- **Size:** 16.34 KB
- **Functions:** 6
- **Last Modified:** 2025-08-21 17:45

**Dependencies:** Unity-Claude-NotificationIntegration, Unity-Claude-NotificationContentEngine, Unity-Claude-ParallelProcessor-Original, Unity-Claude-Cache-Original, ModuleFunctions, Unity-Claude-Cache, IntegratedNotifications, Performance-Cache, Unity-Claude-NotificationIntegration-Modular, Unity-Claude-Cache-Fixed

--- 
### NotificationSystem

[⬆ Back to Contents](#-table-of-contents)

Specialized module providing targeted functionality for the Unity-Claude automation system. Integrates with the broader architecture to deliver specific capabilities.

**Key Capabilities:** specialized operations

**Module Statistics:**
- Functions: 4
- Lines of Code: 322
- Exported Members: 1


**Module Details:**
- **Path:** `Modules\Unity-Claude-HITL\Core\NotificationSystem.psm1`
- **Size:** 12.66 KB
- **Functions:** 4
- **Last Modified:** 2025-08-26 11:46

**Dependencies:** CPG-DataStructures, CrossLanguage-DependencyMaps, Unity-Claude-HITL-Original, CPG-Unified, Unity-Claude-EmailNotifications-SystemNetMail, Unity-Claude-Cache-Original, Unity-Claude-Cache, Performance-Cache, Unity-Claude-CPG-Original, HITLCore, Unity-Claude-Cache-Fixed

--- 
### OptimizerConfiguration

[⬆ Back to Contents](#-table-of-contents)

Specialized module providing targeted functionality for the Unity-Claude automation system. Integrates with the broader architecture to deliver specific capabilities.

**Key Capabilities:** system initialization, data retrieval

**Module Statistics:**
- Functions: 6
- Lines of Code: 203
- Exported Members: 1


**Module Details:**
- **Path:** `Modules\Unity-Claude-PerformanceOptimizer\Core\OptimizerConfiguration.psm1`
- **Size:** 7.06 KB
- **Functions:** 6
- **Last Modified:** 2025-08-26 11:46

**Dependencies:** Unity-Claude-IncrementalProcessor, Unity-Claude-ParallelProcessor-Original, Unity-Claude-Cache-Original, ModuleFunctions, Unity-Claude-Cache, Performance-Cache, Unity-Claude-IncrementalProcessor-Fixed, Unity-Claude-Cache-Fixed

--- 
### OrchestrationCore

[⬆ Back to Contents](#-table-of-contents)

Core infrastructure module providing fundamental functionality for the Unity-Claude system. This module serves as the foundation for other components, offering essential utilities, configuration management, and base services. Master orchestration module coordinating complex multi-step workflows. Manages module interactions, handles state transitions, and ensures proper sequencing of automated operations. 

**Key Capabilities:** process initiation, data retrieval, system initialization 

**Module Statistics:**
 - Functions: 3
 - Lines of Code: 226
 - Exported Members: 1


**Module Details:**
- **Path:** `Modules\Unity-Claude-CLIOrchestrator\Core\OrchestrationComponents\OrchestrationCore.psm1`
- **Size:** 9.09 KB
- **Functions:** 3
- **Last Modified:** 2025-08-27 15:25

**Dependencies:** Unity-Claude-PerformanceOptimizer-Original, Unity-Claude-IncrementalProcessor, Unity-Claude-ParallelProcessor-Original, RunspacePoolManager, Unity-Claude-Cache-Original, ModuleFunctions, Unity-Claude-Cache, WindowManager-Enhanced, Unity-Claude-CLIOrchestrator-Fixed-Simple, Unity-Claude-PerformanceOptimizer-Refactored, Performance-Cache, Unity-Claude-IncrementalProcessor-Fixed, MonitoringLoop, BatchProcessingEngine, WindowManager-Original, Unity-Claude-CLIOrchestrator-FullFeatured, Unity-Claude-Cache-Fixed, Unity-Claude-CLIOrchestrator-Original, OrchestrationManager

--- 
### OrchestrationManager

[⬆ Back to Contents](#-table-of-contents)

Master orchestration module coordinating complex multi-step workflows. Manages module interactions, handles state transitions, and ensures proper sequencing of automated operations.

**Key Capabilities:** process initiation, data retrieval, action execution

**Module Statistics:**
- Functions: 5
- Lines of Code: 988
- Exported Members: 1


**Module Details:**
- **Path:** `Modules\Unity-Claude-CLIOrchestrator\Core\OrchestrationManager.psm1`
- **Size:** 52.72 KB
- **Functions:** 3
- **Last Modified:** 2025-08-27 19:57

**Dependencies:** CPG-DataStructures, CrossLanguage-DependencyMaps, Unity-Claude-PerformanceOptimizer-Original, Unity-Claude-IncrementalProcessor, Unity-Claude-MasterOrchestrator-Original, CPG-Unified, DecisionExecution, Unity-Claude-ParallelProcessor-Original, RunspacePoolManager, Unity-Claude-Cache-Original, PromptSubmissionEngine, ModuleFunctions, Unity-Claude-Cache, WindowManager-Enhanced, Unity-Claude-CLIOrchestrator-Fixed-Simple, DecisionExecution-Fixed, Unity-Claude-PerformanceOptimizer-Refactored, Performance-Cache, Unity-Claude-CPG-Original, Unity-Claude-IncrementalProcessor-Fixed, BatchProcessingEngine, DecisionMaking-Fixed, WindowManager-Original, Unity-Claude-CLIOrchestrator-FullFeatured, Unity-Claude-Cache-Fixed, Unity-Claude-CLIOrchestrator-Original, DecisionMaking, OrchestrationCore

--- 
### OrchestrationManager-Refactored

[⬆ Back to Contents](#-table-of-contents)

Master orchestration module coordinating complex multi-step workflows. Manages module interactions, handles state transitions, and ensures proper sequencing of automated operations.

**Module Statistics:**
- Functions: 0
- Lines of Code: 105
- Exported Members: 1


**Module Details:**
- **Path:** `Modules\Unity-Claude-CLIOrchestrator\Core\OrchestrationManager-Refactored.psm1`
- **Size:** 3.27 KB
- **Functions:** 0
- **Last Modified:** 2025-08-27 15:15

**Dependencies:** Unity-Claude-PerformanceOptimizer-Original, Unity-Claude-IncrementalProcessor, Unity-Claude-MasterOrchestrator-Original, DecisionExecution, Unity-Claude-ParallelProcessor-Original, Unity-Claude-Cache-Original, ModuleFunctions, Unity-Claude-Cache, WindowManager-Enhanced, Unity-Claude-CLIOrchestrator-Fixed-Simple, DecisionExecution-Fixed, Unity-Claude-PerformanceOptimizer-Refactored, Performance-Cache, Unity-Claude-IncrementalProcessor-Fixed, MonitoringLoop, BatchProcessingEngine, DecisionMaking-Fixed, WindowManager-Original, Unity-Claude-CLIOrchestrator-FullFeatured, Unity-Claude-Cache-Fixed, Unity-Claude-CLIOrchestrator-Original, DecisionMaking, OrchestrationCore, OrchestrationManager

--- 
### OrchestratorCore

[⬆ Back to Contents](#-table-of-contents)

Core infrastructure module providing fundamental functionality for the Unity-Claude system. This module serves as the foundation for other components, offering essential utilities, configuration management, and base services. Master orchestration module coordinating complex multi-step workflows. Manages module interactions, handles state transitions, and ensures proper sequencing of automated operations. 

**Key Capabilities:** specialized operations, data retrieval, configuration management 

**Module Statistics:**
 - Functions: 5
 - Lines of Code: 233
 - Exported Members: 1


**Module Details:**
- **Path:** `Modules\Unity-Claude-MasterOrchestrator\Core\OrchestratorCore.psm1`
- **Size:** 7.61 KB
- **Functions:** 5
- **Last Modified:** 2025-08-26 11:46

**Dependencies:** Unity-Claude-MasterOrchestrator-Original, Unity-Claude-Cache-Original, Unity-Claude-Cache, Performance-Cache, Unity-Claude-Cache-Fixed

--- 
### OrchestratorManagement

[⬆ Back to Contents](#-table-of-contents)

Master orchestration module coordinating complex multi-step workflows. Manages module interactions, handles state transitions, and ensures proper sequencing of automated operations.

**Key Capabilities:** data retrieval, validation and testing, specialized operations

**Module Statistics:**
- Functions: 7
- Lines of Code: 439
- Exported Members: 1


**Module Details:**
- **Path:** `Modules\Unity-Claude-MasterOrchestrator\Core\OrchestratorManagement.psm1`
- **Size:** 16.16 KB
- **Functions:** 6
- **Last Modified:** 2025-08-26 11:46

**Dependencies:** CPG-DataStructures, CrossLanguage-DependencyMaps, Unity-Claude-PerformanceOptimizer-Original, Unity-Claude-IncrementalProcessor, Unity-Claude-MasterOrchestrator-Original, CPG-Unified, DecisionExecution, Unity-Claude-ParallelProcessor-Original, ModuleIntegration, Unity-Claude-Cache-Original, ModuleFunctions, Unity-Claude-Cache, Unity-Claude-CLIOrchestrator-Fixed-Simple, DecisionExecution-Fixed, Unity-Claude-PerformanceOptimizer-Refactored, Performance-Cache, Unity-Claude-CPG-Original, Unity-Claude-IncrementalProcessor-Fixed, Unity-Claude-IntegrationEngine, BatchProcessingEngine, OrchestratorCore, AutonomousFeedbackLoop, Unity-Claude-Cache-Fixed, Unity-Claude-CLIOrchestrator-Original, Unity-Claude-CLISubmission

--- 
### PaginationProvider

[⬆ Back to Contents](#-table-of-contents)

Specialized module providing targeted functionality for the Unity-Claude automation system. Integrates with the broader architecture to deliver specific capabilities.

**Key Capabilities:** resource creation, data retrieval, configuration management, specialized operations

**Module Statistics:**
- Functions: 5
- Lines of Code: 252
- Classes: 1
- Exported Members: 1


**Module Details:**
- **Path:** `Modules\Unity-Claude-ScalabilityEnhancements\Core\PaginationProvider.psm1`
- **Size:** 8.05 KB
- **Functions:** 10
- **Last Modified:** 2025-08-26 11:46

**Dependencies:** Unity-Claude-Cache-Original, Unity-Claude-Cache, Performance-Cache, Unity-Claude-ScalabilityEnhancements-Original, Unity-Claude-Cache-Fixed

--- 
### ParallelizationCore

[⬆ Back to Contents](#-table-of-contents)

Core infrastructure module providing fundamental functionality for the Unity-Claude system. This module serves as the foundation for other components, offering essential utilities, configuration management, and base services. High-performance parallel processing module for concurrent operations. Manages thread pools, runspace allocation, and synchronization primitives. 

**Key Capabilities:** validation and testing, system initialization, specialized operations, data retrieval 

**Module Statistics:**
 - Functions: 8
 - Lines of Code: 274
 - Exported Members: 1


**Module Details:**
- **Path:** `Modules\Unity-Claude-UnityParallelization\Core\ParallelizationCore.psm1`
- **Size:** 9.75 KB
- **Functions:** 6
- **Last Modified:** 2025-08-26 11:46

**Dependencies:** Unity-Claude-UnityParallelization-Original, Unity-Claude-PerformanceOptimizer-Original, Unity-Claude-IncrementalProcessor, Unity-Claude-ParallelProcessor-Original, MetricsCollection, Unity-Claude-Cache-Original, ModuleFunctions, Unity-Claude-Cache, SelfPatching, RunspaceCore, DependencyManagement, Unity-Claude-PerformanceOptimizer-Refactored, Performance-Cache, ProductionRunspacePool, ModuleVariablePreloading, RunspacePoolManagement, Unity-Claude-ClaudeParallelization, Unity-Claude-IncrementalProcessor-Fixed, SessionStateConfiguration, BatchProcessingEngine, SuccessTracking, Unity-Claude-Cache-Fixed, Unity-Claude-RunspaceManagement-Original, Unity-Claude-IntegratedWorkflow-Original, VariableSharing, ThrottlingResourceControl

--- 
### ParallelMonitoring

[⬆ Back to Contents](#-table-of-contents)

High-performance parallel processing module for concurrent operations. Manages thread pools, runspace allocation, and synchronization primitives. Real-time monitoring module tracking system health and performance metrics. Provides event-driven notifications and automated issue response. 

**Key Capabilities:** resource creation, process initiation, process termination, data retrieval 

**Module Statistics:**
 - Functions: 4
 - Lines of Code: 592
 - Exported Members: 1


**Module Details:**
- **Path:** `Modules\Unity-Claude-UnityParallelization\Core\ParallelMonitoring.psm1`
- **Size:** 26.79 KB
- **Functions:** 4
- **Last Modified:** 2025-08-26 11:46

**Dependencies:** Unity-Claude-UnityParallelization-Original, Unity-Claude-PerformanceOptimizer-Original, JobScheduler, Unity-Claude-IncrementalProcessor, Unity-Claude-ParallelProcessor-Original, RunspacePoolManager, Unity-Claude-Cache-Original, StatisticsTracker, ModuleFunctions, Unity-Claude-Cache, Unity-Claude-PerformanceOptimizer-Refactored, Performance-Cache, ProductionRunspacePool, ModuleVariablePreloading, RunspacePoolManagement, Unity-Claude-IncrementalProcessor-Fixed, SessionStateConfiguration, BatchProcessingEngine, ParallelizationCore, Unity-Claude-Cache-Fixed, Unity-Claude-RunspaceManagement-Original, VariableSharing, ProjectConfiguration

--- 
### PatternAnalysis

[⬆ Back to Contents](#-table-of-contents)

Specialized module providing targeted functionality for the Unity-Claude automation system. Integrates with the broader architecture to deliver specific capabilities.

**Key Capabilities:** specialized operations, data retrieval

**Module Statistics:**
- Functions: 3
- Lines of Code: 239
- Exported Members: 1


**Module Details:**
- **Path:** `Modules\Unity-Claude-CLIOrchestrator\Core\DecisionEngine-Bayesian\PatternAnalysis.psm1`
- **Size:** 8.57 KB
- **Functions:** 3
- **Last Modified:** 2025-08-26 11:46

**Dependencies:** CrossLanguage-DependencyMaps, EntityContextEngine, Unity-Claude-ParallelProcessor-Original, DecisionEngine-Bayesian, Unity-Claude-Cache-Original, ModuleFunctions, Unity-Claude-Cache, ResponseAnalysisEngine-Enhanced, Performance-Cache, Unity-Claude-Learning-Original, CrossLanguage-GraphMerger, ConfigurationLogging, Unity-Claude-Learning-Simple, ResponseAnalysisEngine-Broken, StringSimilarity, DecisionEngine, ContextOptimization, CodeRedundancyDetection, Unity-Claude-Cache-Fixed, ResponseAnalysisEngine

--- 
### PatternRecognition

[⬆ Back to Contents](#-table-of-contents)

Pattern recognition engine that identifies recurring patterns, anomalies, and trends. Uses statistical analysis and machine learning to improve system behavior over time.

**Key Capabilities:** specialized operations

**Module Statistics:**
- Functions: 5
- Lines of Code: 398
- Exported Members: 1


**Module Details:**
- **Path:** `Modules\Unity-Claude-Learning\Core\PatternRecognition.psm1`
- **Size:** 15.02 KB
- **Functions:** 5
- **Last Modified:** 2025-08-26 11:46

**Dependencies:** CPG-DataStructures, CrossLanguage-DependencyMaps, Unity-Claude-PerformanceOptimizer-Original, JobScheduler, Unity-Claude-IncrementalProcessor, Performance-IncrementalUpdates, CPG-Unified, EntityContextEngine, Unity-Claude-ParallelProcessor-Original, Unity-Claude-Errors, MetricsCollection, RunspacePoolManager, Unity-Claude-Cache-Original, StatisticsTracker, ModuleFunctions, Unity-Claude-Cache, Unity-Claude-CrossLanguage, SelfPatching, RunspaceCore, Unity-Claude-PerformanceOptimizer-Refactored, Performance-Cache, ErrorDetection, ProductionRunspacePool, ModuleVariablePreloading, Unity-Claude-Learning-Original, RunspacePoolManagement, Unity-Claude-CPG-Original, Unity-Claude-IncrementalProcessor-Fixed, SessionStateConfiguration, Unity-Claude-Learning-Simple, ASTAnalysis, BatchProcessingEngine, StringSimilarity, SuccessTracking, UnityIntegration, Unity-Claude-Cache-Fixed, Unity-Claude-AIAlertClassifier, Unity-Claude-RunspaceManagement-Original, VariableSharing, ThrottlingResourceControl

--- 
### PatternRecognitionEngine

[⬆ Back to Contents](#-table-of-contents)

Pattern recognition engine that identifies recurring patterns, anomalies, and trends. Uses statistical analysis and machine learning to improve system behavior over time.

**Key Capabilities:** specialized operations, action execution, validation and testing, data retrieval

**Module Statistics:**
- Functions: 4
- Lines of Code: 283
- Exported Members: 1


**Module Details:**
- **Path:** `Modules\Unity-Claude-CLIOrchestrator\Core\PatternRecognitionEngine.psm1`
- **Size:** 11.03 KB
- **Functions:** 4
- **Last Modified:** 2025-08-26 22:06

**Dependencies:** CPG-DataStructures, CrossLanguage-DependencyMaps, Unity-Claude-PerformanceOptimizer-Original, Unity-Claude-IncrementalProcessor, CPG-Unified, EntityContextEngine, Unity-Claude-ParallelProcessor-Original, Unity-Claude-Cache-Original, PatternRecognitionEngine-Original, Unity-Claude-Cache, Unity-Claude-CLIOrchestrator-Fixed-Simple, RecommendationPatternEngine, Unity-Claude-PerformanceOptimizer-Refactored, Performance-Cache, ResponseClassificationEngine, Unity-Claude-CPG-Original, Unity-Claude-IncrementalProcessor-Fixed, BayesianConfidenceEngine, PatternRecognitionEngine-New, BatchProcessingEngine, PatternRecognitionEngine-Fixed, Unity-Claude-Cache-Fixed

--- 
### PatternRecognitionEngine-Fixed

[⬆ Back to Contents](#-table-of-contents)

Pattern recognition engine that identifies recurring patterns, anomalies, and trends. Uses statistical analysis and machine learning to improve system behavior over time.

**Key Capabilities:** specialized operations, action execution, data retrieval, configuration management

**Module Statistics:**
- Functions: 5
- Lines of Code: 273
- Exported Members: 1


**Module Details:**
- **Path:** `Modules\Unity-Claude-CLIOrchestrator\Core\PatternRecognitionEngine-Fixed.psm1`
- **Size:** 8.86 KB
- **Functions:** 4
- **Last Modified:** 2025-08-27 16:51

**Dependencies:** Unity-Claude-PerformanceOptimizer-Original, Unity-Claude-IncrementalProcessor, EntityContextEngine, Unity-Claude-ParallelProcessor-Original, Unity-Claude-Cache-Original, PatternRecognitionEngine-Original, ModuleFunctions, Unity-Claude-Cache, Unity-Claude-CLIOrchestrator-Fixed-Simple, RecommendationPatternEngine, Unity-Claude-PerformanceOptimizer-Refactored, Performance-Cache, ResponseClassificationEngine, Unity-Claude-IncrementalProcessor-Fixed, BayesianConfidenceEngine, PatternRecognitionEngine-New, BatchProcessingEngine, PatternRecognitionEngine, Unity-Claude-Cache-Fixed

--- 
### PatternRecognitionEngine-New

[⬆ Back to Contents](#-table-of-contents)

Pattern recognition engine that identifies recurring patterns, anomalies, and trends. Uses statistical analysis and machine learning to improve system behavior over time.

**Key Capabilities:** specialized operations, action execution, validation and testing, data retrieval

**Module Statistics:**
- Functions: 4
- Lines of Code: 283
- Exported Members: 1


**Module Details:**
- **Path:** `Modules\Unity-Claude-CLIOrchestrator\Core\PatternRecognitionEngine-New.psm1`
- **Size:** 11.06 KB
- **Functions:** 4
- **Last Modified:** 2025-08-25 14:20

**Dependencies:** CPG-DataStructures, CrossLanguage-DependencyMaps, Unity-Claude-PerformanceOptimizer-Original, Unity-Claude-IncrementalProcessor, CPG-Unified, EntityContextEngine, Unity-Claude-ParallelProcessor-Original, Unity-Claude-Cache-Original, PatternRecognitionEngine-Original, Unity-Claude-Cache, Unity-Claude-CLIOrchestrator-Fixed-Simple, RecommendationPatternEngine, Unity-Claude-PerformanceOptimizer-Refactored, Performance-Cache, ResponseClassificationEngine, Unity-Claude-CPG-Original, Unity-Claude-IncrementalProcessor-Fixed, BayesianConfidenceEngine, BatchProcessingEngine, PatternRecognitionEngine-Fixed, PatternRecognitionEngine, Unity-Claude-Cache-Fixed

--- 
### PatternRecognitionEngine-Original

[⬆ Back to Contents](#-table-of-contents)

Pattern recognition engine that identifies recurring patterns, anomalies, and trends. Uses statistical analysis and machine learning to improve system behavior over time.

**Key Capabilities:** system initialization, validation and testing, data retrieval, specialized operations

**Module Statistics:**
- Functions: 34
- Lines of Code: 2444
- Exported Members: 1


**Module Details:**
- **Path:** `Modules\Unity-Claude-CLIOrchestrator\Core\PatternRecognitionEngine-Original.psm1`
- **Size:** 89.32 KB
- **Functions:** 33
- **Last Modified:** 2025-08-25 14:20

**Dependencies:** CPG-DataStructures, CrossLanguage-DependencyMaps, Unity-Claude-PerformanceOptimizer-Original, Unity-Claude-IncrementalProcessor, CPG-Unified, EntityContextEngine, Unity-Claude-ParallelProcessor-Original, DecisionEngine-Bayesian, RunspacePoolManager, Unity-Claude-Cache-Original, ModuleFunctions, Unity-Claude-Cache, Unity-Claude-CLIOrchestrator-Fixed-Simple, RecommendationPatternEngine, ResponseAnalysisEngine-Enhanced, Unity-Claude-PerformanceOptimizer-Refactored, Performance-Cache, ResponseClassificationEngine, Unity-Claude-CPG-Original, Unity-Claude-IncrementalProcessor-Fixed, ResponseAnalysisEngine-Broken, BayesianConfidenceEngine, PatternRecognitionEngine-New, BatchProcessingEngine, PatternRecognitionEngine-Fixed, PatternRecognitionEngine, Unity-Claude-Cache-Fixed, EntityRelationshipManagement, ResponseAnalysisEngine

--- 
### Performance-Cache

[⬆ Back to Contents](#-table-of-contents)

Intelligent caching system optimizing performance through strategic data persistence. Implements LRU policies, dependency tracking, and automatic invalidation.

**Key Capabilities:** resource creation, configuration management, data retrieval, cleanup operations, specialized operations

**Module Statistics:**
- Functions: 9
- Lines of Code: 679
- Classes: 4
- Exported Members: 2


**Module Details:**
- **Path:** `Modules\Unity-Claude-CPG\Core\Performance-Cache.psm1`
- **Size:** 20.32 KB
- **Functions:** 32
- **Last Modified:** 2025-08-28 16:26

**Dependencies:** Unity-Claude-PerformanceOptimizer-Original, JobScheduler, Unity-Claude-IncrementalProcessor, Performance-IncrementalUpdates, Unity-Claude-ParallelProcessor-Original, RunspacePoolManager, Unity-Claude-Cache-Original, StatisticsTracker, LLM-ResponseCache, ModuleFunctions, Unity-Claude-Cache, Unity-Claude-PerformanceOptimizer-Refactored, Unity-Claude-CPG-Original, Unity-Claude-IncrementalProcessor-Fixed, BatchProcessingEngine, Unity-Claude-Cache-Fixed

--- 
### Performance-IncrementalUpdates

[⬆ Back to Contents](#-table-of-contents)

Specialized module providing targeted functionality for the Unity-Claude automation system. Integrates with the broader architecture to deliver specific capabilities.

**Key Capabilities:** resource creation, process initiation, data retrieval, specialized operations

**Module Statistics:**
- Functions: 9
- Lines of Code: 752
- Classes: 4
- Exported Members: 2


**Module Details:**
- **Path:** `Modules\Unity-Claude-CPG\Core\Performance-IncrementalUpdates.psm1`
- **Size:** 27.26 KB
- **Functions:** 23
- **Last Modified:** 2025-08-28 16:49

**Dependencies:** CrossLanguage-DependencyMaps, Unity-Claude-PerformanceOptimizer-Original, Unity-Claude-IncrementalProcessor, Unity-Claude-ParallelProcessor-Original, Unity-Claude-Cache-Original, StatisticsTracker, ModuleFunctions, Unity-Claude-Cache, Unity-Claude-PerformanceOptimizer-Refactored, Performance-Cache, CrossLanguage-GraphMerger, Unity-Claude-CPG-Original, Unity-Claude-IncrementalProcessor-Fixed, BatchProcessingEngine, Unity-Claude-Cache-Fixed

--- 
### PerformanceAnalysis

[⬆ Back to Contents](#-table-of-contents)

Specialized module providing targeted functionality for the Unity-Claude automation system. Integrates with the broader architecture to deliver specific capabilities.

**Key Capabilities:** data retrieval

**Module Statistics:**
- Functions: 3
- Lines of Code: 298
- Exported Members: 1


**Module Details:**
- **Path:** `Modules\Unity-Claude-IntegratedWorkflow\Core\PerformanceAnalysis.psm1`
- **Size:** 15.12 KB
- **Functions:** 2
- **Last Modified:** 2025-08-26 11:46

**Dependencies:** Unity-Claude-PerformanceOptimizer-Original, Unity-Claude-IncrementalProcessor, Unity-Claude-ParallelProcessor-Original, Unity-Claude-Cache-Original, Unity-Claude-Cache, Unity-Claude-PerformanceOptimizer-Refactored, Performance-Cache, Unity-Claude-IncrementalProcessor-Fixed, BatchProcessingEngine, Unity-Claude-Cache-Fixed, Unity-Claude-IntegratedWorkflow-Original

--- 
### PerformanceMonitoring

[⬆ Back to Contents](#-table-of-contents)

Real-time monitoring module tracking system health and performance metrics. Provides event-driven notifications and automated issue response.

**Key Capabilities:** specialized operations, data retrieval, resource creation, validation and testing

**Module Statistics:**
- Functions: 6
- Lines of Code: 274
- Exported Members: 1


**Module Details:**
- **Path:** `Modules\Unity-Claude-PerformanceOptimizer\Core\PerformanceMonitoring.psm1`
- **Size:** 9.89 KB
- **Functions:** 6
- **Last Modified:** 2025-08-26 11:46

**Dependencies:** Unity-Claude-IncrementalProcessor, Performance-IncrementalUpdates, Unity-Claude-ParallelProcessor-Original, Unity-Claude-Cache-Original, StatisticsTracker, ModuleFunctions, Unity-Claude-Cache, Performance-Cache, Unity-Claude-CPG-Original, Unity-Claude-IncrementalProcessor-Fixed, BatchProcessingEngine, Unity-Claude-PerformanceOptimizer, PerformanceOptimizer, Unity-Claude-ScalabilityOptimizer, Unity-Claude-AutonomousStateTracker, Unity-Claude-Cache-Fixed, Unity-Claude-DocumentationQualityOrchestrator

--- 
### PerformanceOptimization

[⬆ Back to Contents](#-table-of-contents)

Specialized module providing targeted functionality for the Unity-Claude automation system. Integrates with the broader architecture to deliver specific capabilities.

**Key Capabilities:** specialized operations

**Module Statistics:**
- Functions: 8
- Lines of Code: 296
- Exported Members: 1


**Module Details:**
- **Path:** `Modules\Unity-Claude-PerformanceOptimizer\Core\PerformanceOptimization.psm1`
- **Size:** 9.84 KB
- **Functions:** 8
- **Last Modified:** 2025-08-26 11:46

**Dependencies:** Unity-Claude-Cache-Original, Unity-Claude-Cache, Performance-Cache, Unity-Claude-PerformanceOptimizer, Unity-Claude-Cache-Fixed

--- 
### PerformanceOptimizer

[⬆ Back to Contents](#-table-of-contents)

Specialized module providing targeted functionality for the Unity-Claude automation system. Integrates with the broader architecture to deliver specific capabilities.

**Key Capabilities:** data retrieval, configuration management

**Module Statistics:**
- Functions: 14
- Lines of Code: 784
- Exported Members: 1


**Module Details:**
- **Path:** `Modules\Unity-Claude-CLIOrchestrator\Core\PerformanceOptimizer.psm1`
- **Size:** 26.96 KB
- **Functions:** 14
- **Last Modified:** 2025-08-29 20:46

**Dependencies:** CPG-DataStructures, CrossLanguage-DependencyMaps, Unity-Claude-PerformanceOptimizer-Original, JobScheduler, Unity-Claude-IncrementalProcessor, Performance-IncrementalUpdates, CPG-Unified, Unity-Claude-ParallelProcessor-Original, RunspacePoolManager, Unity-Claude-Cache-Original, StatisticsTracker, LLM-ResponseCache, ModuleFunctions, Unity-Claude-Cache, Unity-Claude-PerformanceOptimizer-Refactored, Performance-Cache, PerformanceMonitoring, Unity-Claude-CPG-Original, Unity-Claude-IncrementalProcessor-Fixed, BatchProcessingEngine, Unity-Claude-PerformanceOptimizer, Unity-Claude-SemanticAnalysis-Helpers, Unity-Claude-ScalabilityOptimizer, Unity-Claude-Cache-Fixed, Unity-Claude-MultiStepOrchestrator

--- 
### PermissionHandler

[⬆ Back to Contents](#-table-of-contents)

Specialized module providing targeted functionality for the Unity-Claude automation system. Integrates with the broader architecture to deliver specific capabilities.

**Key Capabilities:** system initialization, validation and testing, data retrieval, request processing, specialized operations

**Module Statistics:**
- Functions: 8
- Lines of Code: 622
- Classes: 1
- Exported Members: 1


**Module Details:**
- **Path:** `Modules\Unity-Claude-CLIOrchestrator\Core\PermissionHandler.psm1`
- **Size:** 18.75 KB
- **Functions:** 8
- **Last Modified:** 2025-08-31 00:19

**Dependencies:** CPG-DataStructures, CrossLanguage-DependencyMaps, Unity-Claude-PerformanceOptimizer-Original, Unity-Claude-IncrementalProcessor, CPG-Unified, Unity-Claude-ParallelProcessor-Original, Unity-Claude-Cache-Original, ModuleFunctions, Unity-Claude-Cache, Unity-Claude-PerformanceOptimizer-Refactored, Performance-Cache, Unity-Claude-CPG-Original, Unity-Claude-IncrementalProcessor-Fixed, BatchProcessingEngine, Unity-Claude-Cache-Fixed

--- 
### PersistenceManagement

[⬆ Back to Contents](#-table-of-contents)

Specialized module providing targeted functionality for the Unity-Claude automation system. Integrates with the broader architecture to deliver specific capabilities.

**Key Capabilities:** specialized operations

**Module Statistics:**
- Functions: 8
- Lines of Code: 533
- Exported Members: 1


**Module Details:**
- **Path:** `Modules\Unity-Claude-AutonomousAgent\Core\PersistenceManagement.psm1`
- **Size:** 19.12 KB
- **Functions:** 8
- **Last Modified:** 2025-08-26 11:46

**Dependencies:** HistoryManagement, RunspacePoolManager, Unity-Claude-Cache-Original, ConversationStateManager, Unity-Claude-Cache, GoalManagement, Performance-Cache, StateManagement, Unity-Claude-Cache-Fixed

--- 
### Predictive-Evolution

[⬆ Back to Contents](#-table-of-contents)

Specialized module providing targeted functionality for the Unity-Claude automation system. Integrates with the broader architecture to deliver specific capabilities.

**Key Capabilities:** data retrieval

**Module Statistics:**
- Functions: 18
- Lines of Code: 1377
- Classes: 2
- Exported Members: 2


**Module Details:**
- **Path:** `Modules\Unity-Claude-CPG\Core\Predictive-Evolution.psm1`
- **Size:** 48.78 KB
- **Functions:** 19
- **Last Modified:** 2025-08-29 14:50

**Dependencies:** CPG-DataStructures, CrossLanguage-DependencyMaps, Unity-Claude-PerformanceOptimizer-Original, Unity-Claude-IncrementalProcessor, CPG-Unified, Unity-Claude-ParallelProcessor-Original, Unity-Claude-Cache-Original, Unity-Claude-Cache, Predictive-Maintenance, MaintenancePrediction, Unity-Claude-PredictiveAnalysis-Original, Unity-Claude-PerformanceOptimizer-Refactored, Performance-Cache, Unity-Claude-LangGraphBridge, Unity-Claude-CPG-Original, Unity-Claude-IncrementalProcessor-Fixed, BatchProcessingEngine, Unity-Claude-MachineLearning, Unity-Claude-Cache-Fixed

--- 
### Predictive-Maintenance

[⬆ Back to Contents](#-table-of-contents)

Specialized module providing targeted functionality for the Unity-Claude automation system. Integrates with the broader architecture to deliver specific capabilities.

**Key Capabilities:** data retrieval

**Module Statistics:**
- Functions: 42
- Lines of Code: 2298
- Classes: 3
- Exported Members: 1


**Module Details:**
- **Path:** `Modules\Unity-Claude-CPG\Core\Predictive-Maintenance.psm1`
- **Size:** 86.99 KB
- **Functions:** 43
- **Last Modified:** 2025-08-30 22:37

**Dependencies:** CPG-DataStructures, CrossLanguage-DependencyMaps, Unity-Claude-PerformanceOptimizer-Original, Unity-Claude-SemanticAnalysis-Quality, Unity-Claude-IncrementalProcessor, CPG-Unified, Unity-Claude-ParallelProcessor-Original, Unity-Claude-Cache-Original, ModuleFunctions, Unity-Claude-Cache, MaintenancePrediction, Unity-Claude-PredictiveAnalysis-Original, Predictive-Evolution, Unity-Claude-PerformanceOptimizer-Refactored, Performance-Cache, Unity-Claude-LangGraphBridge, Unity-Claude-CPG-Original, Unity-Claude-IncrementalProcessor-Fixed, BatchProcessingEngine, Unity-Claude-MachineLearning, Unity-Claude-Cache-Fixed

--- 
### PriorityActionQueue

[⬆ Back to Contents](#-table-of-contents)

Specialized module providing targeted functionality for the Unity-Claude automation system. Integrates with the broader architecture to deliver specific capabilities.

**Key Capabilities:** validation and testing, resource creation, data retrieval, specialized operations

**Module Statistics:**
- Functions: 5
- Lines of Code: 280
- Exported Members: 1


**Module Details:**
- **Path:** `Modules\Unity-Claude-CLIOrchestrator\Core\DecisionEngine\PriorityActionQueue.psm1`
- **Size:** 9.74 KB
- **Functions:** 5
- **Last Modified:** 2025-08-26 11:46

**Dependencies:** Unity-Claude-Cache-Original, Unity-Claude-Cache, Performance-Cache, ConfigurationLogging, DecisionEngine, Unity-Claude-Cache-Fixed

--- 
### ProductionRunspacePool

[⬆ Back to Contents](#-table-of-contents)

Specialized module providing targeted functionality for the Unity-Claude automation system. Integrates with the broader architecture to deliver specific capabilities.

**Key Capabilities:** specialized operations, validation and testing, resource creation, request processing

**Module Statistics:**
- Functions: 8
- Lines of Code: 582
- Exported Members: 1


**Module Details:**
- **Path:** `Modules\Unity-Claude-RunspaceManagement\Core\ProductionRunspacePool.psm1`
- **Size:** 24.32 KB
- **Functions:** 8
- **Last Modified:** 2025-08-26 11:46

**Dependencies:** CPG-DataStructures, CrossLanguage-DependencyMaps, Unity-Claude-PerformanceOptimizer-Original, JobScheduler, Unity-Claude-IncrementalProcessor, CPG-Unified, Unity-Claude-ParallelProcessor-Original, MetricsCollection, RunspacePoolManager, Unity-Claude-Cache-Original, StatisticsTracker, ModuleFunctions, Unity-Claude-Cache, SelfPatching, RunspaceCore, Unity-Claude-PerformanceOptimizer-Refactored, Performance-Cache, ModuleVariablePreloading, RunspacePoolManagement, Unity-Claude-CPG-Original, Unity-Claude-IncrementalProcessor-Fixed, SessionStateConfiguration, BatchProcessingEngine, SuccessTracking, ProgressTracker, Unity-Claude-ScalabilityEnhancements-Original, Unity-Claude-Cache-Fixed, Unity-Claude-RunspaceManagement-Original, VariableSharing, ThrottlingResourceControl

--- 
### ProgressTracker

[⬆ Back to Contents](#-table-of-contents)

Specialized module providing targeted functionality for the Unity-Claude automation system. Integrates with the broader architecture to deliver specific capabilities.

**Key Capabilities:** resource creation, specialized operations, data retrieval, validation and testing

**Module Statistics:**
- Functions: 7
- Lines of Code: 261
- Classes: 1
- Exported Members: 1


**Module Details:**
- **Path:** `Modules\Unity-Claude-ScalabilityEnhancements\Core\ProgressTracker.psm1`
- **Size:** 8.87 KB
- **Functions:** 13
- **Last Modified:** 2025-08-26 11:46

**Dependencies:** Unity-Claude-Cache-Original, Unity-Claude-Cache, Performance-Cache, Unity-Claude-ScalabilityEnhancements-Original, Unity-Claude-Cache-Fixed

--- 
### ProjectConfiguration

[⬆ Back to Contents](#-table-of-contents)

Specialized module providing targeted functionality for the Unity-Claude automation system. Integrates with the broader architecture to deliver specific capabilities.

**Key Capabilities:** specialized operations, data retrieval, configuration management

**Module Statistics:**
- Functions: 6
- Lines of Code: 412
- Exported Members: 1


**Module Details:**
- **Path:** `Modules\Unity-Claude-UnityParallelization\Core\ProjectConfiguration.psm1`
- **Size:** 15.66 KB
- **Functions:** 6
- **Last Modified:** 2025-08-26 11:46

**Dependencies:** Unity-Claude-UnityParallelization-Original, Unity-Claude-Cache-Original, Unity-Claude-Cache, Performance-Cache, ParallelizationCore, Unity-Claude-Cache-Fixed

--- 
### PromptConfiguration

[⬆ Back to Contents](#-table-of-contents)

Specialized module providing targeted functionality for the Unity-Claude automation system. Integrates with the broader architecture to deliver specific capabilities.

**Key Capabilities:** data retrieval

**Module Statistics:**
- Functions: 1
- Lines of Code: 96
- Exported Members: 1


**Module Details:**
- **Path:** `Modules\Unity-Claude-AutonomousAgent\Core\PromptConfiguration.psm1`
- **Size:** 4.4 KB
- **Functions:** 3
- **Last Modified:** 2025-08-26 11:46

**Dependencies:** Unity-Claude-Cache-Original, Unity-Claude-Cache, Performance-Cache, Unity-Claude-Cache-Fixed

--- 
### PromptSubmissionEngine

[⬆ Back to Contents](#-table-of-contents)

Specialized module providing targeted functionality for the Unity-Claude automation system. Integrates with the broader architecture to deliver specific capabilities.

**Key Capabilities:** request processing, specialized operations

**Module Statistics:**
- Functions: 3
- Lines of Code: 366
- Exported Members: 1


**Module Details:**
- **Path:** `Modules\Unity-Claude-CLIOrchestrator\Core\PromptSubmissionEngine.psm1`
- **Size:** 14.55 KB
- **Functions:** 2
- **Last Modified:** 2025-08-26 11:46

**Dependencies:** Unity-Claude-PerformanceOptimizer-Original, Unity-Claude-IncrementalProcessor, Unity-Claude-ParallelProcessor-Original, Unity-Claude-Cache-Original, Unity-Claude-Cache, WindowManager-Enhanced, Unity-Claude-CLIOrchestrator-Fixed-Simple, Unity-Claude-PerformanceOptimizer-Refactored, Performance-Cache, Unity-Claude-IncrementalProcessor-Fixed, BatchProcessingEngine, ProgressTracker, WindowManager-Original, Unity-Claude-CLIOrchestrator-FullFeatured, Unity-Claude-ScalabilityEnhancements-Original, Unity-Claude-Cache-Fixed, Unity-Claude-CLIOrchestrator-Original

--- 
### PromptTemplateSystem

[⬆ Back to Contents](#-table-of-contents)

Specialized module providing targeted functionality for the Unity-Claude automation system. Integrates with the broader architecture to deliver specific capabilities.

**Key Capabilities:** resource creation

**Module Statistics:**
- Functions: 7
- Lines of Code: 473
- Exported Members: 1


**Module Details:**
- **Path:** `Modules\Unity-Claude-AutonomousAgent\Core\PromptTemplateSystem.psm1`
- **Size:** 18.22 KB
- **Functions:** 7
- **Last Modified:** 2025-08-26 11:46

**Dependencies:** CPG-DataStructures, CrossLanguage-DependencyMaps, CPG-Unified, Unity-Claude-Cache-Original, Unity-Claude-Cache, Unity-Claude-ParallelProcessing, AgentLogging, Performance-Cache, Unity-Claude-CPG-Original, TemplateSystem, Unity-Claude-Cache-Fixed, PromptConfiguration

--- 
### PromptTypeSelection

[⬆ Back to Contents](#-table-of-contents)

Specialized module providing targeted functionality for the Unity-Claude automation system. Integrates with the broader architecture to deliver specific capabilities.

**Key Capabilities:** action execution, resource creation

**Module Statistics:**
- Functions: 4
- Lines of Code: 499
- Exported Members: 1


**Module Details:**
- **Path:** `Modules\Unity-Claude-AutonomousAgent\Core\PromptTypeSelection.psm1`
- **Size:** 19.73 KB
- **Functions:** 4
- **Last Modified:** 2025-08-26 11:46

**Dependencies:** CPG-DataStructures, CrossLanguage-DependencyMaps, Unity-Claude-PerformanceOptimizer-Original, Unity-Claude-IncrementalProcessor, CPG-Unified, Unity-Claude-ParallelProcessor-Original, Unity-Claude-Cache-Original, Unity-Claude-Cache, Unity-Claude-ParallelProcessing, AgentLogging, Unity-Claude-PerformanceOptimizer-Refactored, Performance-Cache, Unity-Claude-CPG-Original, Unity-Claude-IncrementalProcessor-Fixed, BatchProcessingEngine, Unity-Claude-Cache-Fixed, PromptConfiguration

--- 
### QueueManagement

[⬆ Back to Contents](#-table-of-contents)

Specialized module providing targeted functionality for the Unity-Claude automation system. Integrates with the broader architecture to deliver specific capabilities.

**Key Capabilities:** system initialization, specialized operations, data retrieval

**Module Statistics:**
- Functions: 6
- Lines of Code: 339
- Exported Members: 1


**Module Details:**
- **Path:** `Modules\Unity-Claude-NotificationIntegration\Queue\QueueManagement.psm1`
- **Size:** 11.95 KB
- **Functions:** 6
- **Last Modified:** 2025-08-21 17:45

**Dependencies:** BackgroundJobQueue, Unity-Claude-ParallelProcessor-Original, Unity-Claude-Cache-Original, Unity-Claude-IPC-Bidirectional-Fixed, ModuleFunctions, Unity-Claude-Cache, Performance-Cache, CommandExecutionEngine, Unity-Claude-ScalabilityEnhancements-Original, Unity-Claude-NotificationIntegration-Modular, Unity-Claude-Cache-Fixed, Unity-Claude-IPC-Bidirectional

--- 
### ReadabilityAlgorithms

[⬆ Back to Contents](#-table-of-contents)

Specialized module providing targeted functionality for the Unity-Claude automation system. Integrates with the broader architecture to deliver specific capabilities.

**Key Capabilities:** specialized operations, data retrieval

**Module Statistics:**
- Functions: 8
- Lines of Code: 402
- Exported Members: 1


**Module Details:**
- **Path:** `Modules\Unity-Claude-DocumentationQualityAssessment\Components\ReadabilityAlgorithms.psm1`
- **Size:** 14.1 KB
- **Functions:** 8
- **Last Modified:** 2025-08-30 19:48

**Dependencies:** CPG-DataStructures, CrossLanguage-DependencyMaps, CPG-Unified, Unity-Claude-Cache-Original, Unity-Claude-Cache, Performance-Cache, Unity-Claude-CPG-Original, Unity-Claude-Cache-Fixed

--- 
### RecommendationPatternEngine

[⬆ Back to Contents](#-table-of-contents)

Specialized module providing targeted functionality for the Unity-Claude automation system. Integrates with the broader architecture to deliver specific capabilities.

**Key Capabilities:** system initialization, specialized operations

**Module Statistics:**
- Functions: 2
- Lines of Code: 307
- Exported Members: 1


**Module Details:**
- **Path:** `Modules\Unity-Claude-CLIOrchestrator\Core\RecommendationPatternEngine.psm1`
- **Size:** 11.93 KB
- **Functions:** 2
- **Last Modified:** 2025-08-25 14:20

**Dependencies:** Unity-Claude-PerformanceOptimizer-Original, Unity-Claude-IncrementalProcessor, Unity-Claude-ParallelProcessor-Original, Unity-Claude-Cache-Original, PatternRecognitionEngine-Original, ModuleFunctions, Unity-Claude-Cache, Unity-Claude-CLIOrchestrator-Fixed-Simple, Unity-Claude-PerformanceOptimizer-Refactored, Performance-Cache, Unity-Claude-IncrementalProcessor-Fixed, BatchProcessingEngine, Unity-Claude-Cache-Fixed

--- 
### RefactoringDetection

[⬆ Back to Contents](#-table-of-contents)

Specialized module providing targeted functionality for the Unity-Claude automation system. Integrates with the broader architecture to deliver specific capabilities.

**Key Capabilities:** specialized operations, data retrieval

**Module Statistics:**
- Functions: 12
- Lines of Code: 602
- Classes: 1
- Exported Members: 1


**Module Details:**
- **Path:** `Modules\Unity-Claude-PredictiveAnalysis\Core\RefactoringDetection.psm1`
- **Size:** 23.67 KB
- **Functions:** 6
- **Last Modified:** 2025-08-26 11:46

**Dependencies:** CPG-DataStructures, Unity-Claude-PerformanceOptimizer-Original, Unity-Claude-IncrementalProcessor, CPG-Unified, Unity-Claude-ParallelProcessor-Original, Unity-Claude-Cache-Original, Unity-Claude-Cache, Unity-Claude-PredictiveAnalysis-Original, AnalyticsReporting, Unity-Claude-PerformanceOptimizer-Refactored, Performance-Cache, Unity-Claude-CPG-Original, Unity-Claude-IncrementalProcessor-Fixed, CPG-QueryOperations, BatchProcessingEngine, Unity-Claude-Cache-Fixed

--- 
### ReportingExport

[⬆ Back to Contents](#-table-of-contents)

Specialized module providing targeted functionality for the Unity-Claude automation system. Integrates with the broader architecture to deliver specific capabilities.

**Key Capabilities:** specialized operations

**Module Statistics:**
- Functions: 6
- Lines of Code: 352
- Exported Members: 1


**Module Details:**
- **Path:** `Modules\Unity-Claude-PerformanceOptimizer\Core\ReportingExport.psm1`
- **Size:** 12.62 KB
- **Functions:** 6
- **Last Modified:** 2025-08-26 11:46

**Dependencies:** CPG-DataStructures, CrossLanguage-DependencyMaps, Unity-Claude-PerformanceOptimizer-Original, CPG-Unified, Unity-Claude-Cache-Original, Unity-Claude-Cache, Unity-Claude-PerformanceOptimizer-Refactored, Performance-Cache, Unity-Claude-CPG-Original, Unity-Claude-Cache-Fixed

--- 
### ResponseAnalysis

[⬆ Back to Contents](#-table-of-contents)

Response analysis module that processes and interprets Claude AI responses. Extracts actionable information, validates safety constraints, and prepares execution plans.

**Key Capabilities:** action execution, data retrieval

**Module Statistics:**
- Functions: 12
- Lines of Code: 541
- Exported Members: 1


**Module Details:**
- **Path:** `Modules\Unity-Claude-DecisionEngine\Core\ResponseAnalysis.psm1`
- **Size:** 17.63 KB
- **Functions:** 12
- **Last Modified:** 2025-08-26 11:46

**Dependencies:** Unity-Claude-PerformanceOptimizer-Original, Unity-Claude-IncrementalProcessor, Unity-Claude-ParallelProcessor-Original, RunspacePoolManager, Unity-Claude-Cache-Original, Unity-Claude-Cache, Unity-Claude-PerformanceOptimizer-Refactored, Performance-Cache, Unity-Claude-IncrementalProcessor-Fixed, Unity-Claude-ResponseMonitor, BatchProcessingEngine, Unity-Claude-DecisionEngine-Original, Unity-Claude-FixEngine, Unity-Claude-Cache-Fixed, DecisionEngineCore

--- 
### ResponseAnalysisEngine

[⬆ Back to Contents](#-table-of-contents)

Response analysis module that processes and interprets Claude AI responses. Extracts actionable information, validates safety constraints, and prepares execution plans.

**Key Capabilities:** specialized operations, data retrieval, action execution

**Module Statistics:**
- Functions: 12
- Lines of Code: 829
- Exported Members: 1


**Module Details:**
- **Path:** `Modules\Unity-Claude-CLIOrchestrator\Core\ResponseAnalysisEngine.psm1`
- **Size:** 28.2 KB
- **Functions:** 12
- **Last Modified:** 2025-08-25 13:45

**Dependencies:** Unity-Claude-PerformanceOptimizer-Original, Unity-Claude-IncrementalProcessor, BayesianInference, EntityContextEngine, ResponseAnalysisEngine-Core, Unity-Claude-ParallelProcessor-Original, DecisionEngine-Bayesian, RunspacePoolManager, Unity-Claude-Cache-Original, PatternRecognitionEngine-Original, EnhancedPatternIntegration, Unity-Claude-Cache, Unity-Claude-CLIOrchestrator-Fixed-Simple, ResponseAnalysisEngine-Enhanced, Unity-Claude-PerformanceOptimizer-Refactored, Performance-Cache, TemporalContextTracking, Unity-Claude-IncrementalProcessor-Fixed, AnalysisLogging, ResponseAnalysisEngine-Broken, BatchProcessingEngine, ContextOptimization, Unity-Claude-Cache-Fixed, CircuitBreaker, EntityRelationshipManagement, PatternAnalysis, JsonProcessing, ConfidenceBands

--- 
### ResponseAnalysisEngine-Broken

[⬆ Back to Contents](#-table-of-contents)

Response analysis module that processes and interprets Claude AI responses. Extracts actionable information, validates safety constraints, and prepares execution plans.

**Key Capabilities:** specialized operations, validation and testing

**Module Statistics:**
- Functions: 40
- Lines of Code: 2613
- Exported Members: 1


**Module Details:**
- **Path:** `Modules\Unity-Claude-CLIOrchestrator\Core\ResponseAnalysisEngine-Broken.psm1`
- **Size:** 92.6 KB
- **Functions:** 39
- **Last Modified:** 2025-08-26 22:17

**Dependencies:** Unity-Claude-PerformanceOptimizer-Original, Unity-Claude-IncrementalProcessor, BayesianInference, EntityContextEngine, ResponseAnalysisEngine-Core, Unity-Claude-FileMonitor, Unity-Claude-ParallelProcessor-Original, DecisionEngine-Bayesian, RunspacePoolManager, Unity-Claude-Cache-Original, PatternRecognitionEngine-Original, EnhancedPatternIntegration, ModuleFunctions, Unity-Claude-Cache, Unity-Claude-CLIOrchestrator-Fixed-Simple, ResponseAnalysisEngine-Enhanced, Unity-Claude-PerformanceOptimizer-Refactored, Performance-Cache, AutonomousOperations, Unity-Claude-FileMonitor-Fixed, TemporalContextTracking, Unity-Claude-IncrementalProcessor-Fixed, AnalysisLogging, Unity-Claude-ResponseMonitoring, Unity-Claude-ErrorHandling, BatchProcessingEngine, ContextOptimization, Unity-Claude-AutonomousStateTracker, Unity-Claude-Cache-Fixed, CircuitBreaker, Unity-Claude-CLIOrchestrator-Original, EntityRelationshipManagement, ErrorHandling, PatternAnalysis, ResponseAnalysisEngine, JsonProcessing, ConfidenceBands

--- 
### ResponseAnalysisEngine-Core

[⬆ Back to Contents](#-table-of-contents)

Core infrastructure module providing fundamental functionality for the Unity-Claude system. This module serves as the foundation for other components, offering essential utilities, configuration management, and base services. Response analysis module that processes and interprets Claude AI responses. Extracts actionable information, validates safety constraints, and prepares execution plans. 

**Key Capabilities:** specialized operations, action execution, system initialization, data retrieval, validation and testing 

**Module Statistics:**
 - Functions: 6
 - Lines of Code: 594
 - Exported Members: 1


**Module Details:**
- **Path:** `Modules\Unity-Claude-CLIOrchestrator\Core\Components\ResponseAnalysisEngine-Core.psm1`
- **Size:** 22.47 KB
- **Functions:** 6
- **Last Modified:** 2025-08-27 15:39

**Dependencies:** Unity-Claude-PerformanceOptimizer-Original, Unity-Claude-IncrementalProcessor, Unity-Claude-ParallelProcessor-Original, RunspacePoolManager, Unity-Claude-Cache-Original, ModuleFunctions, Unity-Claude-Cache, Unity-Claude-CLIOrchestrator-Fixed-Simple, Unity-Claude-PerformanceOptimizer-Refactored, Performance-Cache, Unity-Claude-IncrementalProcessor-Fixed, AnalysisLogging, ResponseAnalysisEngine-Broken, Unity-Claude-ErrorHandling, BatchProcessingEngine, Unity-Claude-AutonomousStateTracker, Unity-Claude-Cache-Fixed, CircuitBreaker, ErrorHandling, JsonProcessing

--- 
### ResponseAnalysisEngine-Enhanced

[⬆ Back to Contents](#-table-of-contents)

Response analysis module that processes and interprets Claude AI responses. Extracts actionable information, validates safety constraints, and prepares execution plans.

**Key Capabilities:** specialized operations, data retrieval, action execution

**Module Statistics:**
- Functions: 12
- Lines of Code: 829
- Exported Members: 1


**Module Details:**
- **Path:** `Modules\Unity-Claude-CLIOrchestrator\Core\ResponseAnalysisEngine-Enhanced.psm1`
- **Size:** 28.2 KB
- **Functions:** 12
- **Last Modified:** 2025-08-25 13:45

**Dependencies:** Unity-Claude-PerformanceOptimizer-Original, Unity-Claude-IncrementalProcessor, BayesianInference, EntityContextEngine, ResponseAnalysisEngine-Core, Unity-Claude-ParallelProcessor-Original, DecisionEngine-Bayesian, RunspacePoolManager, Unity-Claude-Cache-Original, PatternRecognitionEngine-Original, EnhancedPatternIntegration, Unity-Claude-Cache, Unity-Claude-CLIOrchestrator-Fixed-Simple, Unity-Claude-PerformanceOptimizer-Refactored, Performance-Cache, TemporalContextTracking, Unity-Claude-IncrementalProcessor-Fixed, AnalysisLogging, ResponseAnalysisEngine-Broken, BatchProcessingEngine, ContextOptimization, Unity-Claude-Cache-Fixed, CircuitBreaker, EntityRelationshipManagement, PatternAnalysis, ResponseAnalysisEngine, JsonProcessing, ConfidenceBands

--- 
### ResponseClassificationEngine

[⬆ Back to Contents](#-table-of-contents)

Specialized module providing targeted functionality for the Unity-Claude automation system. Integrates with the broader architecture to deliver specific capabilities.

**Key Capabilities:** data retrieval, validation and testing, specialized operations, action execution

**Module Statistics:**
- Functions: 12
- Lines of Code: 636
- Exported Members: 1


**Module Details:**
- **Path:** `Modules\Unity-Claude-CLIOrchestrator\Core\ResponseClassificationEngine.psm1`
- **Size:** 25.17 KB
- **Functions:** 12
- **Last Modified:** 2025-08-25 14:20

**Dependencies:** CPG-DataStructures, CrossLanguage-DependencyMaps, Unity-Claude-PerformanceOptimizer-Original, Unity-Claude-IncrementalProcessor, CPG-Unified, Unity-Claude-ParallelProcessor-Original, Unity-Claude-Cache-Original, PatternRecognitionEngine-Original, Unity-Claude-Cache, Unity-Claude-PerformanceOptimizer-Refactored, Performance-Cache, Unity-Claude-CPG-Original, Unity-Claude-IncrementalProcessor-Fixed, BatchProcessingEngine, Unity-Claude-Cache-Fixed

--- 
### ResponseMonitoring

[⬆ Back to Contents](#-table-of-contents)

Real-time monitoring module tracking system health and performance metrics. Provides event-driven notifications and automated issue response.

**Key Capabilities:** action execution, specialized operations, request processing

**Module Statistics:**
- Functions: 5
- Lines of Code: 368
- Exported Members: 1


**Module Details:**
- **Path:** `Modules\Unity-Claude-AutonomousAgent\Monitoring\ResponseMonitoring.psm1`
- **Size:** 15.06 KB
- **Functions:** 5
- **Last Modified:** 2025-08-20 17:25

**Dependencies:** Unity-Claude-PerformanceOptimizer-Original, JobScheduler, Unity-Claude-IncrementalProcessor, Unity-Claude-ParallelProcessor-Original, RunspacePoolManager, Unity-Claude-Cache-Original, StatisticsTracker, ModuleFunctions, Unity-Claude-Cache, Unity-Claude-ParallelProcessing, AgentLogging, Unity-Claude-PerformanceOptimizer-Refactored, Performance-Cache, Unity-Claude-IncrementalProcessor-Fixed, BatchProcessingEngine, Unity-Claude-Cache-Fixed, ClaudeIntegration, StateMachineCore

--- 
### ResponseParsing

[⬆ Back to Contents](#-table-of-contents)

Specialized module providing targeted functionality for the Unity-Claude automation system. Integrates with the broader architecture to deliver specific capabilities.

**Key Capabilities:** action execution, data retrieval, specialized operations

**Module Statistics:**
- Functions: 6
- Lines of Code: 691
- Exported Members: 1


**Module Details:**
- **Path:** `Modules\Unity-Claude-AutonomousAgent\Parsing\ResponseParsing.psm1`
- **Size:** 26.9 KB
- **Functions:** 6
- **Last Modified:** 2025-08-20 17:25

**Dependencies:** Unity-Claude-Cache-Original, Unity-Claude-Cache, Unity-Claude-ParallelProcessing, AgentLogging, Performance-Cache, Unity-Claude-Cache-Fixed

--- 
### ResultAnalysisEngine

[⬆ Back to Contents](#-table-of-contents)

Specialized module providing targeted functionality for the Unity-Claude automation system. Integrates with the broader architecture to deliver specific capabilities.

**Key Capabilities:** action execution, data retrieval, specialized operations

**Module Statistics:**
- Functions: 6
- Lines of Code: 650
- Exported Members: 1


**Module Details:**
- **Path:** `Modules\Unity-Claude-AutonomousAgent\Core\ResultAnalysisEngine.psm1`
- **Size:** 26.47 KB
- **Functions:** 6
- **Last Modified:** 2025-08-26 11:46

**Dependencies:** CPG-DataStructures, CrossLanguage-DependencyMaps, CPG-Unified, Unity-Claude-ParallelProcessor-Original, Unity-Claude-Cache-Original, ModuleFunctions, Unity-Claude-Cache, Unity-Claude-ParallelProcessing, AgentLogging, Performance-Cache, Unity-Claude-CPG-Original, Unity-Claude-Cache-Fixed, PromptConfiguration

--- 
### RetryLogic

[⬆ Back to Contents](#-table-of-contents)

Specialized module providing targeted functionality for the Unity-Claude automation system. Integrates with the broader architecture to deliver specific capabilities.

**Key Capabilities:** resource creation, action execution, validation and testing, data retrieval, specialized operations

**Module Statistics:**
- Functions: 6
- Lines of Code: 261
- Exported Members: 1


**Module Details:**
- **Path:** `Modules\Unity-Claude-NotificationIntegration\Reliability\RetryLogic.psm1`
- **Size:** 8.88 KB
- **Functions:** 6
- **Last Modified:** 2025-08-21 17:45

**Dependencies:** Unity-Claude-PerformanceOptimizer-Original, Unity-Claude-NotificationIntegration, Unity-Claude-IncrementalProcessor, Unity-Claude-ParallelProcessor-Original, Unity-Claude-Cache-Original, Unity-Claude-Cache, IntegratedNotifications, Unity-Claude-PerformanceOptimizer-Refactored, Performance-Cache, Unity-Claude-IncrementalProcessor-Fixed, BatchProcessingEngine, NotificationCore, Unity-Claude-Cache-Fixed

--- 
### RiskAssessment

[⬆ Back to Contents](#-table-of-contents)

Specialized module providing targeted functionality for the Unity-Claude automation system. Integrates with the broader architecture to deliver specific capabilities.

**Key Capabilities:** specialized operations, data retrieval

**Module Statistics:**
- Functions: 20
- Lines of Code: 1115
- Classes: 3
- Exported Members: 1


**Module Details:**
- **Path:** `Modules\Unity-Claude-PredictiveAnalysis\Core\RiskAssessment.psm1`
- **Size:** 41.07 KB
- **Functions:** 18
- **Last Modified:** 2025-08-26 11:46

**Dependencies:** CPG-DataStructures, Unity-Claude-PerformanceOptimizer-Original, Unity-Claude-IncrementalProcessor, CPG-Unified, RefactoringDetection, Unity-Claude-ParallelProcessor-Original, Unity-Claude-Cache-Original, ModuleFunctions, Unity-Claude-Cache, Predictive-Maintenance, MaintenancePrediction, Unity-Claude-PredictiveAnalysis-Original, AnalyticsReporting, Unity-Claude-PerformanceOptimizer-Refactored, Performance-Cache, TrendAnalysis, Unity-Claude-CPG-Original, Unity-Claude-IncrementalProcessor-Fixed, CPG-QueryOperations, BatchProcessingEngine, Unity-Claude-MachineLearning, Unity-Claude-Cache-Fixed

--- 
### RoleAwareManagement

[⬆ Back to Contents](#-table-of-contents)

Specialized module providing targeted functionality for the Unity-Claude automation system. Integrates with the broader architecture to deliver specific capabilities.

**Key Capabilities:** specialized operations, data retrieval

**Module Statistics:**
- Functions: 9
- Lines of Code: 478
- Exported Members: 1


**Module Details:**
- **Path:** `Modules\Unity-Claude-AutonomousAgent\Core\RoleAwareManagement.psm1`
- **Size:** 18.58 KB
- **Functions:** 9
- **Last Modified:** 2025-08-26 11:46

**Dependencies:** CPG-DataStructures, CrossLanguage-DependencyMaps, CPG-Unified, Unity-Claude-ParallelProcessor-Original, Unity-Claude-Cache-Original, ConversationStateManager, ModuleFunctions, Unity-Claude-Cache, GoalManagement, Performance-Cache, Unity-Claude-CPG-Original, Unity-Claude-Cache-Fixed

--- 
### RuleBasedDecisionTrees

[⬆ Back to Contents](#-table-of-contents)

Decision engine module implementing rule-based and ML-enhanced decision trees. Analyzes inputs, evaluates constraints, and determines appropriate actions based on configurable policies.

**Key Capabilities:** action execution, specialized operations

**Module Statistics:**
- Functions: 2
- Lines of Code: 267
- Exported Members: 1


**Module Details:**
- **Path:** `Modules\Unity-Claude-CLIOrchestrator\Core\DecisionEngine\RuleBasedDecisionTrees.psm1`
- **Size:** 11.64 KB
- **Functions:** 2
- **Last Modified:** 2025-08-26 11:46

**Dependencies:** CPG-DataStructures, CrossLanguage-DependencyMaps, CPG-Unified, Unity-Claude-Cache-Original, Unity-Claude-Cache, Unity-Claude-CLIOrchestrator-Fixed-Simple, Performance-Cache, Unity-Claude-CPG-Original, ConfigurationLogging, DecisionEngine, SafetyValidationFramework, PriorityActionQueue, Unity-Claude-Cache-Fixed

--- 
### RunspaceCore

[⬆ Back to Contents](#-table-of-contents)

Core infrastructure module providing fundamental functionality for the Unity-Claude system. This module serves as the foundation for other components, offering essential utilities, configuration management, and base services.

**Key Capabilities:** validation and testing, specialized operations, data retrieval

**Module Statistics:**
- Functions: 10
- Lines of Code: 202
- Exported Members: 1


**Module Details:**
- **Path:** `Modules\Unity-Claude-RunspaceManagement\Core\RunspaceCore.psm1`
- **Size:** 6.92 KB
- **Functions:** 8
- **Last Modified:** 2025-08-26 11:46

**Dependencies:** Unity-Claude-UnityParallelization-Original, Unity-Claude-PerformanceOptimizer-Original, Unity-Claude-IncrementalProcessor, Unity-Claude-ParallelProcessor-Original, MetricsCollection, Unity-Claude-Cache-Original, ModuleFunctions, Unity-Claude-Cache, SelfPatching, Unity-Claude-ParallelProcessing, DependencyManagement, AgentLogging, Unity-Claude-PerformanceOptimizer-Refactored, Performance-Cache, ProductionRunspacePool, ModuleVariablePreloading, RunspacePoolManagement, Unity-Claude-ClaudeParallelization, Unity-Claude-IncrementalProcessor-Fixed, SessionStateConfiguration, BatchProcessingEngine, SuccessTracking, ParallelizationCore, Unity-Claude-Cache-Fixed, Unity-Claude-RunspaceManagement-Original, Unity-Claude-IntegratedWorkflow-Original, VariableSharing, ThrottlingResourceControl

--- 
### RunspaceManagement

[⬆ Back to Contents](#-table-of-contents)

Specialized module providing targeted functionality for the Unity-Claude automation system. Integrates with the broader architecture to deliver specific capabilities.

**Key Capabilities:** resource creation, cleanup operations, validation and testing

**Module Statistics:**
- Functions: 3
- Lines of Code: 195
- Exported Members: 1


**Module Details:**
- **Path:** `Modules\SafeCommandExecution\Core\RunspaceManagement.psm1`
- **Size:** 7.01 KB
- **Functions:** 3
- **Last Modified:** 2025-08-26 11:46

**Dependencies:** JobScheduler, Unity-Claude-IncrementalProcessor, SafeExecution, Unity-Claude-ParallelProcessor-Original, ActionExecutionEngine, RunspacePoolManager, Unity-Claude-Cache-Original, SafeCommandCore, StatisticsTracker, ModuleFunctions, Unity-Claude-Cache, Performance-Cache, Unity-Claude-IncrementalProcessor-Fixed, BatchProcessingEngine, Unity-Claude-Cache-Fixed, SafeCommandExecution-Original

--- 
### RunspacePoolManagement

[⬆ Back to Contents](#-table-of-contents)

Specialized module providing targeted functionality for the Unity-Claude automation system. Integrates with the broader architecture to deliver specific capabilities.

**Key Capabilities:** specialized operations, data retrieval, resource creation

**Module Statistics:**
- Functions: 9
- Lines of Code: 408
- Exported Members: 1


**Module Details:**
- **Path:** `Modules\Unity-Claude-RunspaceManagement\Core\RunspacePoolManagement.psm1`
- **Size:** 14.72 KB
- **Functions:** 9
- **Last Modified:** 2025-08-26 11:46

**Dependencies:** Unity-Claude-PerformanceOptimizer-Original, Unity-Claude-IncrementalProcessor, Unity-Claude-ParallelProcessor-Original, MetricsCollection, RunspacePoolManager, Unity-Claude-Cache-Original, Unity-Claude-Cache, SelfPatching, RunspaceCore, Unity-Claude-PerformanceOptimizer-Refactored, Performance-Cache, ProductionRunspacePool, ModuleVariablePreloading, Unity-Claude-IncrementalProcessor-Fixed, SessionStateConfiguration, BatchProcessingEngine, SuccessTracking, Unity-Claude-Cache-Fixed, Unity-Claude-RunspaceManagement-Original, VariableSharing, ThrottlingResourceControl

--- 
### RunspacePoolManager

[⬆ Back to Contents](#-table-of-contents)

Specialized module providing targeted functionality for the Unity-Claude automation system. Integrates with the broader architecture to deliver specific capabilities.

**Key Capabilities:** resource creation, validation and testing

**Module Statistics:**
- Functions: 2
- Lines of Code: 341
- Classes: 1
- Exported Members: 3


**Module Details:**
- **Path:** `Modules\Unity-Claude-ParallelProcessor\Core\RunspacePoolManager.psm1`
- **Size:** 15.02 KB
- **Functions:** 11
- **Last Modified:** 2025-08-26 11:46

**Dependencies:** CPG-DataStructures, CrossLanguage-DependencyMaps, JobScheduler, Unity-Claude-IncrementalProcessor, CPG-Unified, Unity-Claude-ParallelProcessor-Original, Unity-Claude-Cache-Original, StatisticsTracker, ModuleFunctions, Unity-Claude-Cache, Performance-Cache, RunspacePoolManagement, Unity-Claude-CPG-Original, Unity-Claude-IncrementalProcessor-Fixed, OptimizerConfiguration, BatchProcessingEngine, Unity-Claude-Cache-Fixed, Unity-Claude-RunspaceManagement-Original

--- 
### SafeCommandCore

[⬆ Back to Contents](#-table-of-contents)

Core infrastructure module providing fundamental functionality for the Unity-Claude system. This module serves as the foundation for other components, offering essential utilities, configuration management, and base services.

**Key Capabilities:** specialized operations, data retrieval, configuration management, validation and testing

**Module Statistics:**
- Functions: 5
- Lines of Code: 223
- Exported Members: 1


**Module Details:**
- **Path:** `Modules\SafeCommandExecution\Core\SafeCommandCore.psm1`
- **Size:** 7.33 KB
- **Functions:** 4
- **Last Modified:** 2025-08-26 11:46

**Dependencies:** Unity-Claude-PerformanceOptimizer-Original, Unity-Claude-IncrementalProcessor, Unity-Claude-ParallelProcessor-Original, Unity-Claude-Cache-Original, Unity-Claude-Cache, Unity-Claude-PerformanceOptimizer-Refactored, Performance-Cache, Unity-Claude-IncrementalProcessor-Fixed, BatchProcessingEngine, Unity-Claude-Cache-Fixed, SafeCommandExecution-Original

--- 
### SafeCommandExecution

[⬆ Back to Contents](#-table-of-contents)

Specialized module providing targeted functionality for the Unity-Claude automation system. Integrates with the broader architecture to deliver specific capabilities.

**Key Capabilities:** system initialization, data retrieval, validation and testing

**Module Statistics:**
- Functions: 3
- Lines of Code: 353
- Exported Members: 1


**Module Details:**
- **Path:** `Modules\SafeCommandExecution\SafeCommandExecution.psm1`
- **Size:** 12.93 KB
- **Functions:** 3
- **Last Modified:** 2025-08-26 11:46

**Dependencies:** UnityReportingOperations, UnityProjectOperations, SafeExecution, Unity-Claude-ParallelProcessor-Original, ActionExecutionEngine, CommandExecution, Unity-Claude-Cache-Original, SafeCommandExecution-Refactored, SafeCommandCore, ModuleFunctions, Unity-Claude-Cache, ValidationEngine, Performance-Cache, UnityPerformanceAnalysis, UnityBuildOperations, CompilationIntegration, CommandTypeHandlers, Unity-Claude-Cache-Fixed, SafeCommandExecution-Original, UnityLogAnalysis, UnityCommands, RunspaceManagement

--- 
### SafeCommandExecution-Original

[⬆ Back to Contents](#-table-of-contents)

Specialized module providing targeted functionality for the Unity-Claude automation system. Integrates with the broader architecture to deliver specific capabilities.

**Key Capabilities:** specialized operations, resource creation, validation and testing, cleanup operations

**Module Statistics:**
- Functions: 30
- Lines of Code: 2872
- Classes: 2
- Exported Members: 1


**Module Details:**
- **Path:** `Modules\SafeCommandExecution\SafeCommandExecution-Original.psm1`
- **Size:** 99.06 KB
- **Functions:** 30
- **Last Modified:** 2025-08-26 11:46

**Dependencies:** CPG-DataStructures, UnityReportingOperations, CrossLanguage-DependencyMaps, Unity-Claude-PerformanceOptimizer-Original, JobScheduler, UnityProjectOperations, Unity-Claude-IncrementalProcessor, SafeExecution, CPG-Unified, Unity-Claude-ParallelProcessor-Original, ActionExecutionEngine, CommandExecution, RunspacePoolManager, Unity-Claude-Cache-Original, SafeCommandCore, StatisticsTracker, ModuleFunctions, Unity-Claude-Cache, ValidationEngine, Unity-Claude-PerformanceOptimizer-Refactored, Performance-Cache, UnityPerformanceAnalysis, Unity-Claude-CPG-Original, Unity-Claude-IncrementalProcessor-Fixed, UnityBuildOperations, BatchProcessingEngine, CompilationIntegration, CommandTypeHandlers, Unity-Claude-Cache-Fixed, UnityLogAnalysis, UnityCommands, RunspaceManagement

--- 
### SafeCommandExecution-Refactored

[⬆ Back to Contents](#-table-of-contents)

Specialized module providing targeted functionality for the Unity-Claude automation system. Integrates with the broader architecture to deliver specific capabilities.

**Key Capabilities:** system initialization, data retrieval, validation and testing

**Module Statistics:**
- Functions: 3
- Lines of Code: 353
- Exported Members: 1


**Module Details:**
- **Path:** `Modules\SafeCommandExecution\SafeCommandExecution-Refactored.psm1`
- **Size:** 12.93 KB
- **Functions:** 3
- **Last Modified:** 2025-08-26 11:46

**Dependencies:** UnityReportingOperations, UnityProjectOperations, SafeExecution, Unity-Claude-ParallelProcessor-Original, ActionExecutionEngine, CommandExecution, Unity-Claude-Cache-Original, SafeCommandCore, ModuleFunctions, Unity-Claude-Cache, ValidationEngine, Performance-Cache, UnityPerformanceAnalysis, UnityBuildOperations, CompilationIntegration, CommandTypeHandlers, SafeCommandExecution, Unity-Claude-Cache-Fixed, SafeCommandExecution-Original, UnityLogAnalysis, UnityCommands, RunspaceManagement

--- 
### SafeExecution

[⬆ Back to Contents](#-table-of-contents)

Specialized module providing targeted functionality for the Unity-Claude automation system. Integrates with the broader architecture to deliver specific capabilities.

**Key Capabilities:** resource creation, validation and testing, action execution

**Module Statistics:**
- Functions: 7
- Lines of Code: 593
- Exported Members: 1


**Module Details:**
- **Path:** `Modules\Unity-Claude-AutonomousAgent\Execution\SafeExecution.psm1`
- **Size:** 22.26 KB
- **Functions:** 7
- **Last Modified:** 2025-08-20 17:25

**Dependencies:** Unity-Claude-PerformanceOptimizer-Original, JobScheduler, Unity-Claude-IncrementalProcessor, Unity-Claude-ParallelProcessor-Original, ActionExecutionEngine, RunspacePoolManager, Unity-Claude-Cache-Original, StatisticsTracker, ModuleFunctions, Unity-Claude-Cache, ValidationEngine, Unity-Claude-ParallelProcessing, AgentLogging, Unity-Claude-PerformanceOptimizer-Refactored, Performance-Cache, Unity-Claude-IncrementalProcessor-Fixed, BatchProcessingEngine, Unity-Claude-Cache-Fixed, SafeCommandExecution-Original, RunspaceManagement

--- 
### SafeOperationsHandler

[⬆ Back to Contents](#-table-of-contents)

Specialized module providing targeted functionality for the Unity-Claude automation system. Integrates with the broader architecture to deliver specific capabilities.

**Key Capabilities:** system initialization, specialized operations

**Module Statistics:**
- Functions: 15
- Lines of Code: 729
- Exported Members: 1


**Module Details:**
- **Path:** `Modules\Unity-Claude-CLIOrchestrator\Core\SafeOperationsHandler.psm1`
- **Size:** 22.65 KB
- **Functions:** 15
- **Last Modified:** 2025-08-31 00:55

**Dependencies:** CPG-DataStructures, CrossLanguage-DependencyMaps, Unity-Claude-PerformanceOptimizer-Original, Unity-Claude-IncrementalProcessor, CPG-Unified, Unity-Claude-ParallelProcessor-Original, Unity-Claude-Cache-Original, ModuleFunctions, Unity-Claude-Cache, Unity-Claude-PerformanceOptimizer-Refactored, Performance-Cache, Unity-Claude-CPG-Original, Unity-Claude-IncrementalProcessor-Fixed, BatchProcessingEngine, Unity-Claude-Cache-Fixed

--- 
### SafetyValidationFramework

[⬆ Back to Contents](#-table-of-contents)

Safety and validation framework ensuring all automated operations meet security requirements. Implements sandboxing, command validation, and rollback mechanisms. Validation framework ensuring data integrity and operation safety. Implements schema validation, constraint checking, and error prevention. 

**Key Capabilities:** validation and testing 

**Module Statistics:**
 - Functions: 3
 - Lines of Code: 332
 - Exported Members: 1


**Module Details:**
- **Path:** `Modules\Unity-Claude-CLIOrchestrator\Core\DecisionEngine\SafetyValidationFramework.psm1`
- **Size:** 12.53 KB
- **Functions:** 3
- **Last Modified:** 2025-08-26 11:46

**Dependencies:** CPG-DataStructures, CrossLanguage-DependencyMaps, Unity-Claude-PerformanceOptimizer-Original, Unity-Claude-IncrementalProcessor, CPG-Unified, Unity-Claude-ParallelProcessor-Original, ActionExecutionEngine, Unity-Claude-Cache-Original, Unity-Claude-Cache, Unity-Claude-CLIOrchestrator-Fixed-Simple, Unity-Claude-PerformanceOptimizer-Refactored, Performance-Cache, Unity-Claude-CPG-Original, Unity-Claude-IncrementalProcessor-Fixed, ConfigurationLogging, BatchProcessingEngine, DecisionEngine, PriorityActionQueue, Unity-Claude-Cache-Fixed

--- 
### SecurityTokens

[⬆ Back to Contents](#-table-of-contents)

Specialized module providing targeted functionality for the Unity-Claude automation system. Integrates with the broader architecture to deliver specific capabilities.

**Key Capabilities:** resource creation, validation and testing, data retrieval, specialized operations

**Module Statistics:**
- Functions: 4
- Lines of Code: 226
- Exported Members: 1


**Module Details:**
- **Path:** `Modules\Unity-Claude-HITL\Core\SecurityTokens.psm1`
- **Size:** 7.49 KB
- **Functions:** 4
- **Last Modified:** 2025-08-26 11:46

**Dependencies:** CPG-DataStructures, CrossLanguage-DependencyMaps, Unity-Claude-HITL-Original, JobScheduler, Unity-Claude-IncrementalProcessor, CPG-Unified, Unity-Claude-ParallelProcessor-Original, RunspacePoolManager, Unity-Claude-Cache-Original, StatisticsTracker, ModuleFunctions, Unity-Claude-Cache, Performance-Cache, Unity-Claude-CPG-Original, Unity-Claude-IncrementalProcessor-Fixed, BatchProcessingEngine, Unity-Claude-Cache-Fixed

--- 
### SelfPatching

[⬆ Back to Contents](#-table-of-contents)

Specialized module providing targeted functionality for the Unity-Claude automation system. Integrates with the broader architecture to deliver specific capabilities.

**Key Capabilities:** specialized operations, data retrieval

**Module Statistics:**
- Functions: 8
- Lines of Code: 458
- Exported Members: 1


**Module Details:**
- **Path:** `Modules\Unity-Claude-Learning\Core\SelfPatching.psm1`
- **Size:** 14.37 KB
- **Functions:** 8
- **Last Modified:** 2025-08-26 11:46

**Dependencies:** Unity-Claude-PerformanceOptimizer-Original, JobScheduler, Unity-Claude-IncrementalProcessor, Unity-Claude-ParallelProcessor-Original, PatternRecognition, MetricsCollection, RunspacePoolManager, Unity-Claude-Cache-Original, StatisticsTracker, ModuleFunctions, Unity-Claude-Cache, RunspaceCore, Unity-Claude-PerformanceOptimizer-Refactored, Performance-Cache, ProductionRunspacePool, ModuleVariablePreloading, Unity-Claude-Learning-Original, RunspacePoolManagement, Unity-Claude-IncrementalProcessor-Fixed, SessionStateConfiguration, Unity-Claude-Learning-Simple, BatchProcessingEngine, SuccessTracking, Unity-Claude-Cache-Fixed, Unity-Claude-RunspaceManagement-Original, VariableSharing, ThrottlingResourceControl

--- 
### SemanticAnalysis-Metrics

[⬆ Back to Contents](#-table-of-contents)

Specialized module providing targeted functionality for the Unity-Claude automation system. Integrates with the broader architecture to deliver specific capabilities.

**Key Capabilities:** data retrieval

**Module Statistics:**
- Functions: 14
- Lines of Code: 796
- Classes: 9
- Exported Members: 1


**Module Details:**
- **Path:** `Modules\Unity-Claude-CPG\Core\SemanticAnalysis-Metrics.psm1`
- **Size:** 30.17 KB
- **Functions:** 9
- **Last Modified:** 2025-08-28 15:45

**Dependencies:** CPG-DataStructures, CrossLanguage-DependencyMaps, CPG-Unified, Unity-Claude-DocumentationCrossReference, Unity-Claude-ParallelProcessor-Original, SemanticAnalysis-PatternDetector, Unity-Claude-Cache-Original, ModuleFunctions, Unity-Claude-Cache, Unity-Claude-RepoAnalyst, Performance-Cache, Unity-Claude-CPG-Original, Unity-Claude-Cache-Fixed

--- 
### SemanticAnalysis-PatternDetector

[⬆ Back to Contents](#-table-of-contents)

Specialized module providing targeted functionality for the Unity-Claude automation system. Integrates with the broader architecture to deliver specific capabilities.

**Key Capabilities:** data retrieval

**Module Statistics:**
- Functions: 20
- Lines of Code: 754
- Classes: 13
- Exported Members: 1


**Module Details:**
- **Path:** `Modules\Unity-Claude-CPG\Core\SemanticAnalysis-PatternDetector.psm1`
- **Size:** 24.85 KB
- **Functions:** 17
- **Last Modified:** 2025-08-28 15:01

**Dependencies:** Unity-Claude-DocumentationCrossReference, Unity-Claude-Cache-Original, Unity-Claude-Cache, Unity-Claude-RepoAnalyst, Performance-Cache, Unity-Claude-Cache-Fixed

--- 
### SemanticAnalysis-PatternDetector-PS51Compatible

[⬆ Back to Contents](#-table-of-contents)

Specialized module providing targeted functionality for the Unity-Claude automation system. Integrates with the broader architecture to deliver specific capabilities.

**Key Capabilities:** resource creation, data retrieval

**Module Statistics:**
- Functions: 19
- Lines of Code: 388
- Classes: 1
- Exported Members: 1


**Module Details:**
- **Path:** `Modules\Unity-Claude-CPG\Core\SemanticAnalysis-PatternDetector-PS51Compatible.psm1`
- **Size:** 12.42 KB
- **Functions:** 9
- **Last Modified:** 2025-08-28 15:27

**Dependencies:** Unity-Claude-PerformanceOptimizer-Original, Unity-Claude-IncrementalProcessor, Unity-Claude-ParallelProcessor-Original, SemanticAnalysis-PatternDetector, Unity-Claude-Cache-Original, Unity-Claude-Cache, Unity-Claude-PerformanceOptimizer-Refactored, Performance-Cache, Unity-Claude-IncrementalProcessor-Fixed, BatchProcessingEngine, Unity-Claude-Cache-Fixed

--- 
### SessionStateConfiguration

[⬆ Back to Contents](#-table-of-contents)

Specialized module providing targeted functionality for the Unity-Claude automation system. Integrates with the broader architecture to deliver specific capabilities.

**Key Capabilities:** specialized operations, resource creation, configuration management

**Module Statistics:**
- Functions: 7
- Lines of Code: 378
- Exported Members: 1


**Module Details:**
- **Path:** `Modules\Unity-Claude-RunspaceManagement\Core\SessionStateConfiguration.psm1`
- **Size:** 14.79 KB
- **Functions:** 7
- **Last Modified:** 2025-08-26 11:46

**Dependencies:** Unity-Claude-PerformanceOptimizer-Original, Unity-Claude-IncrementalProcessor, Unity-Claude-ParallelProcessor-Original, MetricsCollection, Unity-Claude-Cache-Original, Unity-Claude-Cache, SelfPatching, RunspaceCore, Unity-Claude-PerformanceOptimizer-Refactored, Performance-Cache, ProductionRunspacePool, ModuleVariablePreloading, RunspacePoolManagement, Unity-Claude-IncrementalProcessor-Fixed, BatchProcessingEngine, SuccessTracking, Unity-Claude-Cache-Fixed, Unity-Claude-RunspaceManagement-Original, VariableSharing, ThrottlingResourceControl

--- 
### StateConfiguration

[⬆ Back to Contents](#-table-of-contents)

Specialized module providing targeted functionality for the Unity-Claude automation system. Integrates with the broader architecture to deliver specific capabilities.

**Key Capabilities:** data retrieval, system initialization

**Module Statistics:**
- Functions: 4
- Lines of Code: 285
- Exported Members: 1


**Module Details:**
- **Path:** `Modules\Unity-Claude-AutonomousStateTracker-Enhanced\Core\StateConfiguration.psm1`
- **Size:** 11.35 KB
- **Functions:** 4
- **Last Modified:** 2025-08-26 11:46

**Dependencies:** Unity-Claude-PerformanceOptimizer-Original, Unity-Claude-IncrementalProcessor, Unity-Claude-ParallelProcessor-Original, Unity-Claude-Cache-Original, ModuleFunctions, Unity-Claude-Cache, Unity-Claude-PerformanceOptimizer-Refactored, Performance-Cache, Unity-Claude-IncrementalProcessor-Fixed, BatchProcessingEngine, Unity-Claude-Cache-Fixed

--- 
### StateMachineCore

[⬆ Back to Contents](#-table-of-contents)

Core infrastructure module providing fundamental functionality for the Unity-Claude system. This module serves as the foundation for other components, offering essential utilities, configuration management, and base services.

**Key Capabilities:** system initialization, configuration management, data retrieval, specialized operations

**Module Statistics:**
- Functions: 5
- Lines of Code: 386
- Exported Members: 1


**Module Details:**
- **Path:** `Modules\Unity-Claude-AutonomousStateTracker-Enhanced\Core\StateMachineCore.psm1`
- **Size:** 14.54 KB
- **Functions:** 5
- **Last Modified:** 2025-08-26 11:46

**Dependencies:** Unity-Claude-ParallelProcessor-Original, RunspacePoolManager, Unity-Claude-Cache-Original, ModuleFunctions, Unity-Claude-Cache, StateConfiguration, Performance-Cache, HumanIntervention, StatePersistence, Unity-Claude-GitHub, Unity-Claude-Cache-Fixed

--- 
### StateManagement

[⬆ Back to Contents](#-table-of-contents)

Specialized module providing targeted functionality for the Unity-Claude automation system. Integrates with the broader architecture to deliver specific capabilities.

**Key Capabilities:** system initialization, configuration management, data retrieval, specialized operations

**Module Statistics:**
- Functions: 7
- Lines of Code: 382
- Exported Members: 1


**Module Details:**
- **Path:** `Modules\Unity-Claude-AutonomousAgent\Core\StateManagement.psm1`
- **Size:** 13.66 KB
- **Functions:** 6
- **Last Modified:** 2025-08-26 11:46

**Dependencies:** CPG-DataStructures, CrossLanguage-DependencyMaps, CPG-Unified, Unity-Claude-ParallelProcessor-Original, Unity-Claude-Cache-Original, ConversationStateManager, ModuleFunctions, Unity-Claude-Cache, PersistenceManagement, Performance-Cache, Unity-Claude-CPG-Original, Unity-Claude-Cache-Fixed

--- 
### StatePersistence

[⬆ Back to Contents](#-table-of-contents)

Specialized module providing targeted functionality for the Unity-Claude automation system. Integrates with the broader architecture to deliver specific capabilities.

**Key Capabilities:** resource creation, specialized operations, data retrieval, cleanup operations, validation and testing

**Module Statistics:**
- Functions: 5
- Lines of Code: 323
- Exported Members: 1


**Module Details:**
- **Path:** `Modules\Unity-Claude-AutonomousStateTracker-Enhanced\Core\StatePersistence.psm1`
- **Size:** 11.54 KB
- **Functions:** 5
- **Last Modified:** 2025-08-26 11:46

**Dependencies:** Unity-Claude-Cache-Original, Unity-Claude-Cache, StateConfiguration, Performance-Cache, Unity-Claude-GitHub, Unity-Claude-Cache-Fixed

--- 
### StatisticsTracker

[⬆ Back to Contents](#-table-of-contents)

Specialized module providing targeted functionality for the Unity-Claude automation system. Integrates with the broader architecture to deliver specific capabilities.

**Key Capabilities:** resource creation, specialized operations

**Module Statistics:**
- Functions: 2
- Lines of Code: 441
- Classes: 1
- Exported Members: 3


**Module Details:**
- **Path:** `Modules\Unity-Claude-ParallelProcessor\Core\StatisticsTracker.psm1`
- **Size:** 17.12 KB
- **Functions:** 17
- **Last Modified:** 2025-08-26 11:46

**Dependencies:** JobScheduler, Unity-Claude-IncrementalProcessor, Performance-IncrementalUpdates, Unity-Claude-ParallelProcessor-Original, RunspacePoolManager, Unity-Claude-Cache-Original, ModuleFunctions, Unity-Claude-Cache, Performance-Cache, Unity-Claude-CPG-Original, Unity-Claude-IncrementalProcessor-Fixed, BatchProcessingEngine, Unity-Claude-Cache-Fixed

--- 
### StringSimilarity

[⬆ Back to Contents](#-table-of-contents)

Specialized module providing targeted functionality for the Unity-Claude automation system. Integrates with the broader architecture to deliver specific capabilities.

**Key Capabilities:** data retrieval

**Module Statistics:**
- Functions: 8
- Lines of Code: 436
- Exported Members: 1


**Module Details:**
- **Path:** `Modules\Unity-Claude-Learning\Core\StringSimilarity.psm1`
- **Size:** 12.95 KB
- **Functions:** 8
- **Last Modified:** 2025-08-26 11:46

**Dependencies:** CrossLanguage-DependencyMaps, Unity-Claude-PerformanceOptimizer-Original, Unity-Claude-IncrementalProcessor, EntityContextEngine, Unity-Claude-ParallelProcessor-Original, MetricsCollection, DecisionEngine-Bayesian, Unity-Claude-Cache-Original, ModuleFunctions, Unity-Claude-Cache, Unity-Claude-CrossLanguage, SelfPatching, RunspaceCore, Unity-Claude-PerformanceOptimizer-Refactored, Performance-Cache, ErrorDetection, ProductionRunspacePool, ModuleVariablePreloading, Unity-Claude-Learning-Original, CrossLanguage-GraphMerger, RunspacePoolManagement, Unity-Claude-IncrementalProcessor-Fixed, SessionStateConfiguration, Unity-Claude-Learning-Simple, BatchProcessingEngine, SuccessTracking, CodeRedundancyDetection, UnityIntegration, Unity-Claude-Cache-Fixed, Unity-Claude-AIAlertClassifier, Unity-Claude-RunspaceManagement-Original, VariableSharing, PatternAnalysis, ThrottlingResourceControl

--- 
### SuccessTracking

[⬆ Back to Contents](#-table-of-contents)

Specialized module providing targeted functionality for the Unity-Claude automation system. Integrates with the broader architecture to deliver specific capabilities.

**Key Capabilities:** specialized operations, data retrieval

**Module Statistics:**
- Functions: 9
- Lines of Code: 400
- Exported Members: 1


**Module Details:**
- **Path:** `Modules\Unity-Claude-Learning\Core\SuccessTracking.psm1`
- **Size:** 12.36 KB
- **Functions:** 9
- **Last Modified:** 2025-08-26 11:46

**Dependencies:** Unity-Claude-PerformanceOptimizer-Original, JobScheduler, Unity-Claude-IncrementalProcessor, Unity-Claude-ParallelProcessor-Original, MetricsCollection, RunspacePoolManager, Unity-Claude-Cache-Original, StatisticsTracker, ModuleFunctions, Unity-Claude-Cache, SelfPatching, RunspaceCore, Unity-Claude-PerformanceOptimizer-Refactored, Performance-Cache, ProductionRunspacePool, ModuleVariablePreloading, Unity-Claude-Learning-Original, RunspacePoolManagement, Unity-Claude-IncrementalProcessor-Fixed, SessionStateConfiguration, Unity-Claude-Learning-Simple, BatchProcessingEngine, Unity-Claude-Cache-Fixed, Unity-Claude-RunspaceManagement-Original, VariableSharing, ThrottlingResourceControl

--- 
### SystemIntegration

[⬆ Back to Contents](#-table-of-contents)

Specialized module providing targeted functionality for the Unity-Claude automation system. Integrates with the broader architecture to deliver specific capabilities.

**Key Capabilities:** system initialization, data retrieval, specialized operations

**Module Statistics:**
- Functions: 6
- Lines of Code: 253
- Exported Members: 2


**Module Details:**
- **Path:** `Modules\Unity-Claude-DocumentationQualityAssessment\Components\SystemIntegration.psm1`
- **Size:** 9.2 KB
- **Functions:** 6
- **Last Modified:** 2025-08-30 19:31

**Dependencies:** Unity-Claude-PerformanceOptimizer-Original, Unity-Claude-IncrementalProcessor, Unity-Claude-ParallelProcessor-Original, Unity-Claude-Cache-Original, ModuleFunctions, Unity-Claude-Cache, Unity-Claude-PerformanceOptimizer-Refactored, Performance-Cache, Unity-Claude-IncrementalProcessor-Fixed, BatchProcessingEngine, Unity-Claude-Cache-Fixed, AIAssessment, Unity-Claude-DocumentationQualityAssessment_Original_20250830_193150

--- 
### Templates-PerLanguage

[⬆ Back to Contents](#-table-of-contents)

Specialized module providing targeted functionality for the Unity-Claude automation system. Integrates with the broader architecture to deliver specific capabilities.

**Key Capabilities:** data retrieval

**Module Statistics:**
- Functions: 9
- Lines of Code: 447
- Exported Members: 1


**Module Details:**
- **Path:** `Modules\Unity-Claude-Enhanced-DocumentationGenerators\Core\Templates-PerLanguage.psm1`
- **Size:** 12.74 KB
- **Functions:** 7
- **Last Modified:** 2025-08-28 17:05

**Dependencies:** Unity-Claude-Cache-Original, Unity-Claude-Cache, Performance-Cache, Unity-Claude-DocumentationDrift, Unity-Claude-Cache-Fixed

--- 
### TemplateSystem

[⬆ Back to Contents](#-table-of-contents)

Specialized module providing targeted functionality for the Unity-Claude automation system. Integrates with the broader architecture to deliver specific capabilities.

**Key Capabilities:** resource creation, data retrieval, specialized operations

**Module Statistics:**
- Functions: 6
- Lines of Code: 466
- Exported Members: 1


**Module Details:**
- **Path:** `Modules\Unity-Claude-DocumentationAutomation\Core\TemplateSystem.psm1`
- **Size:** 16.47 KB
- **Functions:** 6
- **Last Modified:** 2025-08-26 11:46

**Dependencies:** Unity-Claude-Cache-Original, Unity-Claude-Cache, Performance-Cache, Unity-Claude-Cache-Fixed, PromptTemplateSystem, Unity-Claude-DocumentationAutomation-Original

--- 
### TemporalContextTracking

[⬆ Back to Contents](#-table-of-contents)

Specialized module providing targeted functionality for the Unity-Claude automation system. Integrates with the broader architecture to deliver specific capabilities.

**Key Capabilities:** specialized operations, data retrieval

**Module Statistics:**
- Functions: 2
- Lines of Code: 187
- Exported Members: 1


**Module Details:**
- **Path:** `Modules\Unity-Claude-CLIOrchestrator\Core\DecisionEngine-Bayesian\TemporalContextTracking.psm1`
- **Size:** 7.29 KB
- **Functions:** 2
- **Last Modified:** 2025-08-26 11:46

**Dependencies:** Unity-Claude-PerformanceOptimizer-Original, Unity-Claude-IncrementalProcessor, Unity-Claude-ParallelProcessor-Original, DecisionEngine-Bayesian, Unity-Claude-Cache-Original, Unity-Claude-Cache, ResponseAnalysisEngine-Enhanced, Unity-Claude-PerformanceOptimizer-Refactored, Performance-Cache, Unity-Claude-IncrementalProcessor-Fixed, ConfigurationLogging, ResponseAnalysisEngine-Broken, BatchProcessingEngine, DecisionEngine, Unity-Claude-Cache-Fixed, ResponseAnalysisEngine

--- 
### ThrottlingResourceControl

[⬆ Back to Contents](#-table-of-contents)

Specialized module providing targeted functionality for the Unity-Claude automation system. Integrates with the broader architecture to deliver specific capabilities.

**Key Capabilities:** specialized operations, validation and testing, configuration management, action execution, data retrieval

**Module Statistics:**
- Functions: 5
- Lines of Code: 378
- Exported Members: 1


**Module Details:**
- **Path:** `Modules\Unity-Claude-RunspaceManagement\Core\ThrottlingResourceControl.psm1`
- **Size:** 16.31 KB
- **Functions:** 5
- **Last Modified:** 2025-08-26 11:46

**Dependencies:** Unity-Claude-PerformanceOptimizer-Original, Unity-Claude-IncrementalProcessor, Unity-Claude-ParallelProcessor-Original, MetricsCollection, Unity-Claude-Cache-Original, Unity-Claude-Cache, SelfPatching, RunspaceCore, Unity-Claude-PerformanceOptimizer-Refactored, Performance-Cache, ProductionRunspacePool, ModuleVariablePreloading, RunspacePoolManagement, Unity-Claude-IncrementalProcessor-Fixed, SessionStateConfiguration, BatchProcessingEngine, SuccessTracking, Unity-Claude-Cache-Fixed, Unity-Claude-RunspaceManagement-Original, VariableSharing

--- 
### TreeSitter-CSTConverter

[⬆ Back to Contents](#-table-of-contents)

Specialized module providing targeted functionality for the Unity-Claude automation system. Integrates with the broader architecture to deliver specific capabilities.

**Key Capabilities:** specialized operations

**Module Statistics:**
- Functions: 3
- Lines of Code: 738
- Classes: 11
- Exported Members: 1


**Module Details:**
- **Path:** `Modules\Unity-Claude-CPG\Core\TreeSitter-CSTConverter.psm1`
- **Size:** 23.98 KB
- **Functions:** 24
- **Last Modified:** 2025-08-28 03:22

**Dependencies:** CPG-DataStructures, CrossLanguage-DependencyMaps, CPG-Unified, Unity-Claude-Cache-Original, Unity-Claude-Cache, Performance-Cache, Unity-Claude-CPG-Original, CPG-BasicOperations, Unity-Claude-Cache-Fixed, CPG-ThreadSafeOperations

--- 
### TrendAnalysis

[⬆ Back to Contents](#-table-of-contents)

Specialized module providing targeted functionality for the Unity-Claude automation system. Integrates with the broader architecture to deliver specific capabilities.

**Key Capabilities:** data retrieval, specialized operations

**Module Statistics:**
- Functions: 3
- Lines of Code: 349
- Exported Members: 1


**Module Details:**
- **Path:** `Modules\Unity-Claude-PredictiveAnalysis\Core\TrendAnalysis.psm1`
- **Size:** 13.62 KB
- **Functions:** 3
- **Last Modified:** 2025-08-26 11:46

**Dependencies:** CPG-DataStructures, CrossLanguage-DependencyMaps, Unity-Claude-PerformanceOptimizer-Original, Unity-Claude-IncrementalProcessor, CPG-Unified, Unity-Claude-ParallelProcessor-Original, Unity-Claude-Cache-Original, Unity-Claude-Cache, Unity-Claude-PredictiveAnalysis-Original, Unity-Claude-PerformanceOptimizer-Refactored, Performance-Cache, Unity-Claude-CPG-Original, Unity-Claude-IncrementalProcessor-Fixed, BatchProcessingEngine, Unity-Claude-Cache-Fixed

--- 
### TriggerSystem

[⬆ Back to Contents](#-table-of-contents)

Specialized module providing targeted functionality for the Unity-Claude automation system. Integrates with the broader architecture to deliver specific capabilities.

**Key Capabilities:** specialized operations, data retrieval, validation and testing, action execution

**Module Statistics:**
- Functions: 10
- Lines of Code: 691
- Exported Members: 1


**Module Details:**
- **Path:** `Modules\Unity-Claude-DocumentationAutomation\Core\TriggerSystem.psm1`
- **Size:** 23.28 KB
- **Functions:** 10
- **Last Modified:** 2025-08-26 11:46

**Dependencies:** Unity-Claude-PerformanceOptimizer-Original, Unity-Claude-IncrementalProcessor, Unity-Claude-ParallelProcessor-Original, Unity-Claude-Cache-Original, BackupIntegration, Unity-Claude-Cache, Unity-Claude-PerformanceOptimizer-Refactored, Unity-Claude-TriggerManager, Performance-Cache, Unity-Claude-IncrementalProcessor-Fixed, Unity-Claude-DocumentationDrift, BatchProcessingEngine, Unity-Claude-Cache-Fixed, GitHubPRManager, Unity-Claude-DocumentationAutomation-Original

--- 
### Unity-Claude-AgentIntegration

[⬆ Back to Contents](#-table-of-contents)

Unity Editor integration providing direct communication with Unity processes. Monitors compilation, extracts errors, and manages project operations.

**Key Capabilities:** system initialization, specialized operations

**Module Statistics:**
- Functions: 7
- Lines of Code: 419
- Exported Members: 1


**Module Details:**
- **Path:** `Modules\Unity-Claude-MessageQueue\Unity-Claude-AgentIntegration.psm1`
- **Size:** 16.16 KB
- **Functions:** 7
- **Last Modified:** 2025-08-24 12:06

**Dependencies:** Unity-Claude-PerformanceOptimizer-Original, Unity-Claude-IncrementalProcessor, Unity-Claude-ParallelProcessor-Original, Unity-Claude-Cache-Original, Unity-Claude-IPC-Bidirectional-Fixed, ModuleFunctions, Unity-Claude-Cache, Unity-Claude-PerformanceOptimizer-Refactored, Performance-Cache, Unity-Claude-IncrementalProcessor-Fixed, Unity-Claude-ErrorHandling, BatchProcessingEngine, Unity-Claude-MessageQueue, Unity-Claude-Cache-Fixed, Unity-Claude-IPC-Bidirectional

--- 
### Unity-Claude-AIAlertClassifier

[⬆ Back to Contents](#-table-of-contents)

Unity Editor integration providing direct communication with Unity processes. Monitors compilation, extracts errors, and manages project operations. Alert management system for incident detection and notification. Categorizes alerts, manages thresholds, and coordinates response actions. 

**Key Capabilities:** system initialization, validation and testing 

**Module Statistics:**
 - Functions: 19
 - Lines of Code: 974
 - Exported Members: 1


**Module Details:**
- **Path:** `Modules\Unity-Claude-AIAlertClassifier\Unity-Claude-AIAlertClassifier.psm1`
- **Size:** 32.8 KB
- **Functions:** 19
- **Last Modified:** 2025-08-30 21:58

**Dependencies:** CPG-DataStructures, CrossLanguage-DependencyMaps, Unity-Claude-PerformanceOptimizer-Original, JobScheduler, Unity-Claude-IncrementalProcessor, Performance-IncrementalUpdates, CPG-Unified, EntityContextEngine, Unity-Claude-ParallelProcessor-Original, RunspacePoolManager, Unity-Claude-Cache-Original, StatisticsTracker, ModuleFunctions, Unity-Claude-Cache, Unity-Claude-CrossLanguage, Unity-Claude-PerformanceOptimizer-Refactored, Performance-Cache, ErrorDetection, Unity-Claude-Learning-Original, Unity-Claude-CPG-Original, Unity-Claude-IncrementalProcessor-Fixed, Unity-Claude-LLM, Unity-Claude-Learning-Simple, Unity-Claude-ChangeIntelligence, BatchProcessingEngine, StringSimilarity, Unity-Claude-RealTimeOptimizer, UnityIntegration, Unity-Claude-Cache-Fixed

--- 
### Unity-Claude-AlertAnalytics

[⬆ Back to Contents](#-table-of-contents)

Unity Editor integration providing direct communication with Unity processes. Monitors compilation, extracts errors, and manages project operations. Alert management system for incident detection and notification. Categorizes alerts, manages thresholds, and coordinates response actions. 

**Key Capabilities:** system initialization, data retrieval, specialized operations 

**Module Statistics:**
 - Functions: 22
 - Lines of Code: 935
 - Exported Members: 1


**Module Details:**
- **Path:** `Modules\Unity-Claude-AlertAnalytics\Unity-Claude-AlertAnalytics.psm1`
- **Size:** 33.31 KB
- **Functions:** 22
- **Last Modified:** 2025-08-30 14:58

**Dependencies:** CPG-DataStructures, CrossLanguage-DependencyMaps, Unity-Claude-PerformanceOptimizer-Original, Unity-Claude-IncrementalProcessor, CPG-Unified, Unity-Claude-ParallelProcessor-Original, Unity-Claude-Cache-Original, ModuleFunctions, Unity-Claude-Cache, Unity-Claude-PerformanceOptimizer-Refactored, Performance-Cache, Unity-Claude-CPG-Original, Unity-Claude-IncrementalProcessor-Fixed, BatchProcessingEngine, Unity-Claude-Cache-Fixed

--- 
### Unity-Claude-AlertFeedbackCollector

[⬆ Back to Contents](#-table-of-contents)

Unity Editor integration providing direct communication with Unity processes. Monitors compilation, extracts errors, and manages project operations. Alert management system for incident detection and notification. Categorizes alerts, manages thresholds, and coordinates response actions. 

**Key Capabilities:** system initialization, data retrieval, specialized operations 

**Module Statistics:**
 - Functions: 20
 - Lines of Code: 1028
 - Exported Members: 1


**Module Details:**
- **Path:** `Modules\Unity-Claude-AlertFeedbackCollector\Unity-Claude-AlertFeedbackCollector.psm1`
- **Size:** 36.27 KB
- **Functions:** 17
- **Last Modified:** 2025-08-30 14:54

**Dependencies:** CPG-DataStructures, CrossLanguage-DependencyMaps, Unity-Claude-PerformanceOptimizer-Original, Unity-Claude-IncrementalProcessor, CPG-Unified, Unity-Claude-ParallelProcessor-Original, Unity-Claude-Cache-Original, ModuleFunctions, Unity-Claude-Cache, Unity-Claude-PerformanceOptimizer-Refactored, Performance-Cache, Unity-Claude-CPG-Original, Unity-Claude-IncrementalProcessor-Fixed, BatchProcessingEngine, Unity-Claude-Cache-Fixed

--- 
### Unity-Claude-AlertMLOptimizer

[⬆ Back to Contents](#-table-of-contents)

Unity Editor integration providing direct communication with Unity processes. Monitors compilation, extracts errors, and manages project operations. Alert management system for incident detection and notification. Categorizes alerts, manages thresholds, and coordinates response actions. 

**Key Capabilities:** system initialization, data retrieval, specialized operations 

**Module Statistics:**
 - Functions: 27
 - Lines of Code: 927
 - Exported Members: 1


**Module Details:**
- **Path:** `Modules\Unity-Claude-AlertMLOptimizer\Unity-Claude-AlertMLOptimizer.psm1`
- **Size:** 34.34 KB
- **Functions:** 27
- **Last Modified:** 2025-08-30 14:56

**Dependencies:** CPG-DataStructures, CrossLanguage-DependencyMaps, Unity-Claude-PerformanceOptimizer-Original, Unity-Claude-IncrementalProcessor, CPG-Unified, Unity-Claude-ParallelProcessor-Original, Unity-Claude-Cache-Original, ModuleFunctions, Unity-Claude-Cache, Unity-Claude-PerformanceOptimizer-Refactored, Performance-Cache, Unity-Claude-CPG-Original, Unity-Claude-IncrementalProcessor-Fixed, Unity-Claude-AlertQualityReporting, BatchProcessingEngine, Unity-Claude-Cache-Fixed

--- 
### Unity-Claude-AlertQualityReporting

[⬆ Back to Contents](#-table-of-contents)

Unity Editor integration providing direct communication with Unity processes. Monitors compilation, extracts errors, and manages project operations. Alert management system for incident detection and notification. Categorizes alerts, manages thresholds, and coordinates response actions. 

**Key Capabilities:** system initialization, data retrieval, specialized operations 

**Module Statistics:**
 - Functions: 40
 - Lines of Code: 1034
 - Exported Members: 1


**Module Details:**
- **Path:** `Modules\Unity-Claude-AlertQualityReporting\Unity-Claude-AlertQualityReporting.psm1`
- **Size:** 36.02 KB
- **Functions:** 40
- **Last Modified:** 2025-08-30 15:01

**Dependencies:** CPG-DataStructures, CrossLanguage-DependencyMaps, CPG-Unified, Unity-Claude-ParallelProcessor-Original, Unity-Claude-AlertMLOptimizer, Unity-Claude-Cache-Original, ModuleFunctions, Unity-Claude-Cache, Performance-Cache, Unity-Claude-CPG-Original, Unity-Claude-Cache-Fixed

--- 
### Unity-Claude-APIDocumentation

[⬆ Back to Contents](#-table-of-contents)

Documentation automation module providing real-time documentation updates. Generates API docs, maintains cross-references, and ensures documentation accuracy. Unity Editor integration providing direct communication with Unity processes. Monitors compilation, extracts errors, and manages project operations. 

**Key Capabilities:** specialized operations, system initialization, resource creation 

**Module Statistics:**
 - Functions: 14
 - Lines of Code: 855
 - Exported Members: 1


**Module Details:**
- **Path:** `Modules\Unity-Claude-APIDocumentation\Unity-Claude-APIDocumentation.psm1`
- **Size:** 28.41 KB
- **Functions:** 10
- **Last Modified:** 2025-08-26 11:46

**Dependencies:** Unity-Claude-PerformanceOptimizer-Original, Unity-Claude-SemanticAnalysis-Quality, Unity-Claude-IncrementalProcessor, Unity-Claude-ParallelProcessor-Original, Unity-Claude-Cache-Original, ModuleFunctions, Unity-Claude-Cache, Unity-Claude-PerformanceOptimizer-Refactored, Performance-Cache, Unity-Claude-SemanticAnalysis-Purpose, Unity-Claude-IncrementalProcessor-Fixed, BatchProcessingEngine, Unity-Claude-Cache-Fixed

--- 
### Unity-Claude-AST-Enhanced

[⬆ Back to Contents](#-table-of-contents)

Unity Editor integration providing direct communication with Unity processes. Monitors compilation, extracts errors, and manages project operations.

**Key Capabilities:** data retrieval, specialized operations

**Module Statistics:**
- Functions: 32
- Lines of Code: 695
- Exported Members: 1


**Module Details:**
- **Path:** `Modules\Unity-Claude-AST-Enhanced\Unity-Claude-AST-Enhanced.psm1`
- **Size:** 23.43 KB
- **Functions:** 15
- **Last Modified:** 2025-08-30 02:47

**Dependencies:** Unity-Claude-Cache-Original, Unity-Claude-Cache, Performance-Cache, CodeComplexityMetrics, Unity-Claude-Cache-Fixed, CPG-CallGraphBuilder

--- 
### Unity-Claude-AutoGen

[⬆ Back to Contents](#-table-of-contents)

Unity Editor integration providing direct communication with Unity processes. Monitors compilation, extracts errors, and manages project operations.

**Key Capabilities:** resource creation, data retrieval, action execution, process initiation

**Module Statistics:**
- Functions: 13
- Lines of Code: 1291
- Exported Members: 1


**Module Details:**
- **Path:** `Modules\Unity-Claude-AI-Integration\AutoGen\Unity-Claude-AutoGen.psm1`
- **Size:** 48.23 KB
- **Functions:** 13
- **Last Modified:** 2025-08-29 21:03

**Dependencies:** CPG-DataStructures, CrossLanguage-DependencyMaps, Unity-Claude-PerformanceOptimizer-Original, JobScheduler, Unity-Claude-IncrementalProcessor, CPG-Unified, Unity-Claude-ParallelProcessor-Original, RunspacePoolManager, Unity-Claude-Cache-Original, StatisticsTracker, ModuleFunctions, Unity-Claude-Cache, Unity-Claude-PerformanceOptimizer-Refactored, Performance-Cache, Unity-Claude-CPG-Original, Unity-Claude-IncrementalProcessor-Fixed, BatchProcessingEngine, Unity-Claude-Cache-Fixed

--- 
### Unity-Claude-AutoGenMonitoring

[⬆ Back to Contents](#-table-of-contents)

Unity Editor integration providing direct communication with Unity processes. Monitors compilation, extracts errors, and manages project operations. Real-time monitoring module tracking system health and performance metrics. Provides event-driven notifications and automated issue response. 

**Key Capabilities:** process initiation, data retrieval, action execution, process termination 

**Module Statistics:**
 - Functions: 4
 - Lines of Code: 379
 - Exported Members: 1


**Module Details:**
- **Path:** `Modules\Unity-Claude-AI-Integration\AutoGen\Unity-Claude-AutoGenMonitoring.psm1`
- **Size:** 15.56 KB
- **Functions:** 4
- **Last Modified:** 2025-08-29 18:33

**Dependencies:** CPG-DataStructures, CrossLanguage-DependencyMaps, Unity-Claude-AutoGen, Unity-Claude-PerformanceOptimizer-Original, Unity-Claude-IncrementalProcessor, CPG-Unified, Unity-Claude-ParallelProcessor-Original, Unity-Claude-Cache-Original, ModuleFunctions, Unity-Claude-Cache, Unity-Claude-PerformanceOptimizer-Refactored, Performance-Cache, Unity-Claude-CPG-Original, Unity-Claude-IncrementalProcessor-Fixed, BatchProcessingEngine, Unity-Claude-Cache-Fixed

--- 
### Unity-Claude-AutonomousAgent-Refactored

[⬆ Back to Contents](#-table-of-contents)

Unity Editor integration providing direct communication with Unity processes. Monitors compilation, extracts errors, and manages project operations. Autonomous operation module enabling self-directed task execution. Implements goal-seeking behavior, state management, and recovery mechanisms. 

**Key Capabilities:** data retrieval 

**Module Statistics:**
 - Functions: 2
 - Lines of Code: 220


**Module Details:**
- **Path:** `Modules\Unity-Claude-AutonomousAgent\Unity-Claude-AutonomousAgent-Refactored.psm1`
- **Size:** 8.77 KB
- **Functions:** 3
- **Last Modified:** 2025-08-20 17:25

**Dependencies:** Unity-Claude-PerformanceOptimizer-Original, Unity-Claude-IncrementalProcessor, Unity-Claude-ParallelProcessor-Original, Unity-Claude-Cache-Original, ConversationStateManager, ModuleFunctions, Unity-Claude-Cache, Unity-Claude-ParallelProcessing, AgentLogging, Unity-Claude-PerformanceOptimizer-Refactored, Performance-Cache, Unity-Claude-IncrementalProcessor-Fixed, Unity-Claude-ResponseMonitoring, Unity-Claude-ResponseMonitor, BatchProcessingEngine, ContextOptimization, StateManagement, Unity-Claude-Cache-Fixed, FileSystemMonitoring

--- 
### Unity-Claude-AutonomousDocumentationEngine

[⬆ Back to Contents](#-table-of-contents)

Documentation automation module providing real-time documentation updates. Generates API docs, maintains cross-references, and ensures documentation accuracy. Unity Editor integration providing direct communication with Unity processes. Monitors compilation, extracts errors, and manages project operations. Autonomous operation module enabling self-directed task execution. Implements goal-seeking behavior, state management, and recovery mechanisms. 

**Key Capabilities:** system initialization, data retrieval, specialized operations 

**Module Statistics:**
 - Functions: 32
 - Lines of Code: 1459
 - Exported Members: 1


**Module Details:**
- **Path:** `Modules\Unity-Claude-AutonomousDocumentationEngine\Unity-Claude-AutonomousDocumentationEngine.psm1`
- **Size:** 55.81 KB
- **Functions:** 29
- **Last Modified:** 2025-08-30 19:47

**Dependencies:** CPG-DataStructures, CrossLanguage-DependencyMaps, Unity-Claude-PerformanceOptimizer-Original, Unity-Claude-IncrementalProcessor, CPG-Unified, Unity-Claude-ParallelProcessor-Original, TreeSitter-CSTConverter, Unity-Claude-Cache-Original, Unity-Claude-DocumentationQualityAssessment, ModuleFunctions, Unity-Claude-Cache, Unity-Claude-PerformanceOptimizer-Refactored, Performance-Cache, Unity-Claude-DocumentationVersioning, Unity-Claude-Ollama, Unity-Claude-CPG-Original, Unity-Claude-IncrementalProcessor-Fixed, BatchProcessingEngine, Unity-Claude-Cache-Fixed, Unity-Claude-DocumentationQualityAssessment_Original_20250830_193150

--- 
### Unity-Claude-AutonomousStateTracker

[⬆ Back to Contents](#-table-of-contents)

Unity Editor integration providing direct communication with Unity processes. Monitors compilation, extracts errors, and manages project operations. Autonomous operation module enabling self-directed task execution. Implements goal-seeking behavior, state management, and recovery mechanisms. 

**Key Capabilities:** specialized operations, data retrieval, resource creation, system initialization 

**Module Statistics:**
 - Functions: 18
 - Lines of Code: 888
 - Exported Members: 1


**Module Details:**
- **Path:** `Modules\Unity-Claude-AutonomousStateTracker.psm1`
- **Size:** 30.86 KB
- **Functions:** 18
- **Last Modified:** 2025-08-20 17:25

**Dependencies:** CPG-DataStructures, CrossLanguage-DependencyMaps, Unity-Claude-PerformanceOptimizer-Original, Unity-Claude-IncrementalProcessor, CPG-Unified, Unity-Claude-ParallelProcessor-Original, RunspacePoolManager, Unity-Claude-Cache-Original, ModuleFunctions, Unity-Claude-Cache, Unity-Claude-PerformanceOptimizer-Refactored, Performance-Cache, PerformanceMonitoring, Unity-Claude-CPG-Original, Unity-Claude-IncrementalProcessor-Fixed, ResponseAnalysisEngine-Broken, Unity-Claude-ErrorHandling, BatchProcessingEngine, Unity-Claude-PerformanceOptimizer, Unity-Claude-ScalabilityOptimizer, FailureMode, Unity-Claude-Cache-Fixed, CircuitBreaker, ErrorHandling, Unity-Claude-DocumentationQualityOrchestrator

--- 
### Unity-Claude-AutonomousStateTracker-Enhanced

[⬆ Back to Contents](#-table-of-contents)

Unity Editor integration providing direct communication with Unity processes. Monitors compilation, extracts errors, and manages project operations. Autonomous operation module enabling self-directed task execution. Implements goal-seeking behavior, state management, and recovery mechanisms. 

**Key Capabilities:** data retrieval, validation and testing, action execution 

**Module Statistics:**
 - Functions: 4
 - Lines of Code: 519
 - Exported Members: 1


**Module Details:**
- **Path:** `Modules\Unity-Claude-AutonomousStateTracker-Enhanced\Unity-Claude-AutonomousStateTracker-Enhanced.psm1`
- **Size:** 21.74 KB
- **Functions:** 3
- **Last Modified:** 2025-08-26 11:46

**Dependencies:** Unity-Claude-AutonomousStateTracker-Enhanced-Refactored, Unity-Claude-PerformanceOptimizer-Original, Unity-Claude-IncrementalProcessor, Unity-Claude-ParallelProcessor-Original, RunspacePoolManager, Unity-Claude-Cache-Original, ModuleFunctions, Unity-Claude-Cache, StateConfiguration, Unity-Claude-PerformanceOptimizer-Refactored, Performance-Cache, Unity-Claude-IncrementalProcessor-Fixed, HumanIntervention, StatePersistence, Unity-Claude-GitHub, BatchProcessingEngine, Unity-Claude-Cache-Fixed, HealthMonitoring, StateMachineCore

--- 
### Unity-Claude-AutonomousStateTracker-Enhanced-Refactored

[⬆ Back to Contents](#-table-of-contents)

Unity Editor integration providing direct communication with Unity processes. Monitors compilation, extracts errors, and manages project operations. Autonomous operation module enabling self-directed task execution. Implements goal-seeking behavior, state management, and recovery mechanisms. 

**Key Capabilities:** data retrieval, validation and testing, action execution 

**Module Statistics:**
 - Functions: 4
 - Lines of Code: 519
 - Exported Members: 1


**Module Details:**
- **Path:** `Modules\Unity-Claude-AutonomousStateTracker-Enhanced\Unity-Claude-AutonomousStateTracker-Enhanced-Refactored.psm1`
- **Size:** 21.74 KB
- **Functions:** 3
- **Last Modified:** 2025-08-26 11:46

**Dependencies:** Unity-Claude-PerformanceOptimizer-Original, Unity-Claude-IncrementalProcessor, Unity-Claude-ParallelProcessor-Original, RunspacePoolManager, Unity-Claude-Cache-Original, ModuleFunctions, Unity-Claude-Cache, StateConfiguration, Unity-Claude-PerformanceOptimizer-Refactored, Performance-Cache, Unity-Claude-IncrementalProcessor-Fixed, HumanIntervention, StatePersistence, Unity-Claude-GitHub, BatchProcessingEngine, Unity-Claude-AutonomousStateTracker-Enhanced, Unity-Claude-Cache-Fixed, HealthMonitoring, StateMachineCore

--- 
### Unity-Claude-Cache

[⬆ Back to Contents](#-table-of-contents)

Unity Editor integration providing direct communication with Unity processes. Monitors compilation, extracts errors, and manages project operations. Intelligent caching system optimizing performance through strategic data persistence. Implements LRU policies, dependency tracking, and automatic invalidation. 

**Key Capabilities:** resource creation, configuration management, data retrieval, cleanup operations, specialized operations 

**Module Statistics:**
 - Functions: 10
 - Lines of Code: 799
 - Classes: 1
 - Exported Members: 1


**Module Details:**
- **Path:** `Modules\Unity-Claude-Cache\Unity-Claude-Cache.psm1`
- **Size:** 25.32 KB
- **Functions:** 32
- **Last Modified:** 2025-08-25 13:45

**Dependencies:** CPG-DataStructures, CrossLanguage-DependencyMaps, Unity-Claude-PerformanceOptimizer-Original, JobScheduler, Unity-Claude-IncrementalProcessor, Performance-IncrementalUpdates, CPG-Unified, Unity-Claude-ParallelProcessor-Original, RunspacePoolManager, Unity-Claude-Cache-Original, StatisticsTracker, LLM-ResponseCache, ModuleFunctions, Unity-Claude-PerformanceOptimizer-Refactored, Performance-Cache, Unity-Claude-CPG-Original, Unity-Claude-IncrementalProcessor-Fixed, BatchProcessingEngine, Unity-Claude-Cache-Fixed

--- 
### Unity-Claude-Cache-Fixed

[⬆ Back to Contents](#-table-of-contents)

Unity Editor integration providing direct communication with Unity processes. Monitors compilation, extracts errors, and manages project operations. Intelligent caching system optimizing performance through strategic data persistence. Implements LRU policies, dependency tracking, and automatic invalidation. 

**Key Capabilities:** resource creation, configuration management, data retrieval, cleanup operations, specialized operations 

**Module Statistics:**
 - Functions: 10
 - Lines of Code: 802
 - Classes: 1
 - Exported Members: 1


**Module Details:**
- **Path:** `Modules\Unity-Claude-Cache\Unity-Claude-Cache-Fixed.psm1`
- **Size:** 25.39 KB
- **Functions:** 32
- **Last Modified:** 2025-08-25 13:45

**Dependencies:** CPG-DataStructures, CrossLanguage-DependencyMaps, Unity-Claude-PerformanceOptimizer-Original, JobScheduler, Unity-Claude-IncrementalProcessor, Performance-IncrementalUpdates, CPG-Unified, Unity-Claude-ParallelProcessor-Original, RunspacePoolManager, Unity-Claude-Cache-Original, StatisticsTracker, LLM-ResponseCache, ModuleFunctions, Unity-Claude-Cache, Unity-Claude-PerformanceOptimizer-Refactored, Performance-Cache, Unity-Claude-CPG-Original, Unity-Claude-IncrementalProcessor-Fixed, BatchProcessingEngine

--- 
### Unity-Claude-Cache-Original

[⬆ Back to Contents](#-table-of-contents)

Unity Editor integration providing direct communication with Unity processes. Monitors compilation, extracts errors, and manages project operations. Intelligent caching system optimizing performance through strategic data persistence. Implements LRU policies, dependency tracking, and automatic invalidation. 

**Key Capabilities:** resource creation, configuration management, data retrieval, cleanup operations, specialized operations 

**Module Statistics:**
 - Functions: 10
 - Lines of Code: 789
 - Classes: 1
 - Exported Members: 1


**Module Details:**
- **Path:** `Modules\Unity-Claude-Cache\Unity-Claude-Cache-Original.psm1`
- **Size:** 25.15 KB
- **Functions:** 31
- **Last Modified:** 2025-08-25 13:45

**Dependencies:** CPG-DataStructures, CrossLanguage-DependencyMaps, Unity-Claude-PerformanceOptimizer-Original, JobScheduler, Unity-Claude-IncrementalProcessor, Performance-IncrementalUpdates, CPG-Unified, Unity-Claude-ParallelProcessor-Original, RunspacePoolManager, StatisticsTracker, LLM-ResponseCache, ModuleFunctions, Unity-Claude-Cache, Unity-Claude-PerformanceOptimizer-Refactored, Performance-Cache, Unity-Claude-CPG-Original, Unity-Claude-IncrementalProcessor-Fixed, BatchProcessingEngine, Unity-Claude-Cache-Fixed

--- 
### Unity-Claude-ChangeIntelligence

[⬆ Back to Contents](#-table-of-contents)

Unity Editor integration providing direct communication with Unity processes. Monitors compilation, extracts errors, and manages project operations.

**Key Capabilities:** system initialization, data retrieval

**Module Statistics:**
- Functions: 15
- Lines of Code: 605
- Exported Members: 3


**Module Details:**
- **Path:** `Modules\Unity-Claude-ChangeIntelligence\Unity-Claude-ChangeIntelligence.psm1`
- **Size:** 20.69 KB
- **Functions:** 13
- **Last Modified:** 2025-08-30 12:45

**Dependencies:** Unity-Claude-PerformanceOptimizer-Original, Unity-Claude-IncrementalProcessor, Unity-Claude-ParallelProcessor-Original, TreeSitter-CSTConverter, Unity-Claude-Cache-Original, ModuleFunctions, Unity-Claude-Cache, Unity-Claude-PerformanceOptimizer-Refactored, Performance-Cache, Unity-Claude-IncrementalProcessor-Fixed, Unity-Claude-LLM, BatchProcessingEngine, Unity-Claude-Cache-Fixed

--- 
### Unity-Claude-ClaudeParallelization

[⬆ Back to Contents](#-table-of-contents)

High-performance parallel processing module for concurrent operations. Manages thread pools, runspace allocation, and synchronization primitives. Unity Editor integration providing direct communication with Unity processes. Monitors compilation, extracts errors, and manages project operations. 

**Key Capabilities:** validation and testing, specialized operations, resource creation, request processing 

**Module Statistics:**
 - Functions: 12
 - Lines of Code: 1282
 - Exported Members: 1


**Module Details:**
- **Path:** `Modules\Unity-Claude-ClaudeParallelization\Unity-Claude-ClaudeParallelization.psm1`
- **Size:** 53.27 KB
- **Functions:** 11
- **Last Modified:** 2025-08-21 17:45

**Dependencies:** Unity-Claude-UnityParallelization-Original, Unity-Claude-PerformanceOptimizer-Original, JobScheduler, Unity-Claude-IncrementalProcessor, Unity-Claude-ParallelProcessor-Original, MetricsCollection, RunspacePoolManager, Unity-Claude-Cache-Original, StatisticsTracker, ModuleFunctions, Unity-Claude-Cache, SelfPatching, RunspaceCore, DependencyManagement, Unity-Claude-PerformanceOptimizer-Refactored, Performance-Cache, ProductionRunspacePool, ModuleVariablePreloading, RunspacePoolManagement, Unity-Claude-IncrementalProcessor-Fixed, SessionStateConfiguration, BatchProcessingEngine, SuccessTracking, ParallelizationCore, Unity-Claude-Cache-Fixed, Unity-Claude-RunspaceManagement-Original, Unity-Claude-IntegratedWorkflow-Original, VariableSharing, ThrottlingResourceControl

--- 
### Unity-Claude-CLIOrchestrator

[⬆ Back to Contents](#-table-of-contents)

Master orchestration module coordinating complex multi-step workflows. Manages module interactions, handles state transitions, and ensures proper sequencing of automated operations. Unity Editor integration providing direct communication with Unity processes. Monitors compilation, extracts errors, and manages project operations. 

**Key Capabilities:** system initialization, validation and testing, data retrieval, specialized operations 

**Module Statistics:**
 - Functions: 7
 - Lines of Code: 568
 - Exported Members: 2


**Module Details:**
- **Path:** `Modules\Unity-Claude-CLIOrchestrator\Unity-Claude-CLIOrchestrator.psm1`
- **Size:** 22.86 KB
- **Functions:** 4
- **Last Modified:** 2025-08-26 22:06

**Dependencies:** Unity-Claude-CLIOrchestrator-Original-Backup, Unity-Claude-PerformanceOptimizer-Original, Unity-Claude-IncrementalProcessor, Unity-Claude-MasterOrchestrator-Original, EntityContextEngine, DecisionExecution, ResponseAnalysisEngine-Core, Unity-Claude-ParallelProcessor-Original, ActionExecutionEngine, Unity-Claude-CLIOrchestrator-Refactored-Fixed, Unity-Claude-Cache-Original, PatternRecognitionEngine-Original, PromptSubmissionEngine, ModuleFunctions, Unity-Claude-Cache, WindowManager-Enhanced, Unity-Claude-CLIOrchestrator-Fixed-Simple, DecisionExecution-Fixed, RecommendationPatternEngine, Unity-Claude-PerformanceOptimizer-Refactored, Performance-Cache, ResponseClassificationEngine, AutonomousOperations, Unity-Claude-IncrementalProcessor-Fixed, ResponseAnalysisEngine-Broken, BayesianConfidenceEngine, RuleBasedDecisionTrees, WindowManager-NUGGETRON, PatternRecognitionEngine-New, Unity-Claude-ErrorHandling, BatchProcessingEngine, DecisionEngine, DecisionMaking-Fixed, WindowManager-Original, SafetyValidationFramework, Unity-Claude-CLIOrchestrator-FullFeatured, PatternRecognitionEngine-Fixed, PriorityActionQueue, Unity-Claude-AutonomousStateTracker, PatternRecognitionEngine, WindowManager, FallbackStrategies, Unity-Claude-Cache-Fixed, CircuitBreaker, Unity-Claude-CLIOrchestrator-Original, ErrorHandling, DecisionMaking, Unity-Claude-CLIOrchestrator-Refactored, OrchestrationCore, OrchestrationManager, Unity-Claude-CLISubmission, JsonProcessing

--- 
### Unity-Claude-CLIOrchestrator-Fixed-Simple

[⬆ Back to Contents](#-table-of-contents)

Master orchestration module coordinating complex multi-step workflows. Manages module interactions, handles state transitions, and ensures proper sequencing of automated operations. Unity Editor integration providing direct communication with Unity processes. Monitors compilation, extracts errors, and manages project operations. 

**Key Capabilities:** system initialization, validation and testing, data retrieval, specialized operations 

**Module Statistics:**
 - Functions: 14
 - Lines of Code: 510
 - Exported Members: 1


**Module Details:**
- **Path:** `Modules\Unity-Claude-CLIOrchestrator\Unity-Claude-CLIOrchestrator-Fixed-Simple.psm1`
- **Size:** 14.26 KB
- **Functions:** 14
- **Last Modified:** 2025-08-27 23:42

**Dependencies:** Unity-Claude-CLIOrchestrator-Original-Backup, Unity-Claude-PerformanceOptimizer-Original, Unity-Claude-IncrementalProcessor, Unity-Claude-MasterOrchestrator-Original, Unity-Claude-CLIOrchestrator, DecisionExecution, ResponseAnalysisEngine-Core, Unity-Claude-ParallelProcessor-Original, Unity-Claude-CLIOrchestrator-Refactored-Fixed, Unity-Claude-Cache-Original, PatternRecognitionEngine-Original, PromptSubmissionEngine, ModuleFunctions, Unity-Claude-Cache, WindowManager-Enhanced, DecisionExecution-Fixed, RecommendationPatternEngine, Unity-Claude-PerformanceOptimizer-Refactored, Performance-Cache, AutonomousOperations, Unity-Claude-IncrementalProcessor-Fixed, ResponseAnalysisEngine-Broken, RuleBasedDecisionTrees, BatchProcessingEngine, DecisionEngine, DecisionMaking-Fixed, WindowManager-Original, SafetyValidationFramework, Unity-Claude-CLIOrchestrator-FullFeatured, Unity-Claude-Cache-Fixed, Unity-Claude-CLIOrchestrator-Original, DecisionMaking, Unity-Claude-CLIOrchestrator-Refactored

--- 
### Unity-Claude-CLIOrchestrator-FullFeatured

[⬆ Back to Contents](#-table-of-contents)

Master orchestration module coordinating complex multi-step workflows. Manages module interactions, handles state transitions, and ensures proper sequencing of automated operations. Unity Editor integration providing direct communication with Unity processes. Monitors compilation, extracts errors, and manages project operations. 

**Key Capabilities:** system initialization, specialized operations 

**Module Statistics:**
 - Functions: 2
 - Lines of Code: 296
 - Classes: 1
 - Exported Members: 1


**Module Details:**
- **Path:** `Modules\Unity-Claude-CLIOrchestrator\Unity-Claude-CLIOrchestrator-FullFeatured.psm1`
- **Size:** 10.46 KB
- **Functions:** 2
- **Last Modified:** 2025-08-27 18:03

**Dependencies:** Unity-Claude-CLIOrchestrator-Original-Backup, Unity-Claude-PerformanceOptimizer-Original, Unity-Claude-IncrementalProcessor, Unity-Claude-MasterOrchestrator-Original, Unity-Claude-CLIOrchestrator, EntityContextEngine, DecisionExecution, ResponseAnalysisEngine-Core, Unity-Claude-ParallelProcessor-Original, ActionExecutionEngine, Unity-Claude-CLIOrchestrator-Refactored-Fixed, Unity-Claude-Cache-Original, PatternRecognitionEngine-Original, PromptSubmissionEngine, ModuleFunctions, Unity-Claude-Cache, WindowManager-Enhanced, Unity-Claude-CLIOrchestrator-Fixed-Simple, DecisionExecution-Fixed, RecommendationPatternEngine, Unity-Claude-PerformanceOptimizer-Refactored, Performance-Cache, ResponseClassificationEngine, AutonomousOperations, Unity-Claude-IncrementalProcessor-Fixed, ResponseAnalysisEngine-Broken, BayesianConfidenceEngine, RuleBasedDecisionTrees, WindowManager-NUGGETRON, PatternRecognitionEngine-New, Unity-Claude-ErrorHandling, BatchProcessingEngine, DecisionEngine, DecisionMaking-Fixed, WindowManager-Original, SafetyValidationFramework, PatternRecognitionEngine-Fixed, PriorityActionQueue, Unity-Claude-AutonomousStateTracker, PatternRecognitionEngine, WindowManager, FallbackStrategies, Unity-Claude-Cache-Fixed, CircuitBreaker, Unity-Claude-CLIOrchestrator-Original, ErrorHandling, DecisionMaking, Unity-Claude-CLIOrchestrator-Refactored, OrchestrationCore, OrchestrationManager, Unity-Claude-CLISubmission, JsonProcessing

--- 
### Unity-Claude-CLIOrchestrator-Original

[⬆ Back to Contents](#-table-of-contents)

Master orchestration module coordinating complex multi-step workflows. Manages module interactions, handles state transitions, and ensures proper sequencing of automated operations. Unity Editor integration providing direct communication with Unity processes. Monitors compilation, extracts errors, and manages project operations. 

**Key Capabilities:** specialized operations, request processing 

**Module Statistics:**
 - Functions: 18
 - Lines of Code: 1760
 - Classes: 1
 - Exported Members: 11


**Module Details:**
- **Path:** `Modules\Unity-Claude-CLIOrchestrator\Unity-Claude-CLIOrchestrator-Original.psm1`
- **Size:** 74.96 KB
- **Functions:** 15
- **Last Modified:** 2025-08-28 12:37

**Dependencies:** CPG-DataStructures, CrossLanguage-DependencyMaps, Unity-Claude-PerformanceOptimizer-Original, Unity-Claude-IncrementalProcessor, Unity-Claude-MasterOrchestrator-Original, CPG-Unified, EntityContextEngine, DecisionExecution, ResponseAnalysisEngine-Core, Unity-Claude-ParallelProcessor-Original, ActionExecutionEngine, RunspacePoolManager, Unity-Claude-Cache-Original, PatternRecognitionEngine-Original, PromptSubmissionEngine, ModuleFunctions, Unity-Claude-Cache, WindowManager-Enhanced, Unity-Claude-CLIOrchestrator-Fixed-Simple, DecisionExecution-Fixed, RecommendationPatternEngine, Unity-Claude-PerformanceOptimizer-Refactored, Performance-Cache, ResponseClassificationEngine, AutonomousOperations, Unity-Claude-CPG-Original, Unity-Claude-IncrementalProcessor-Fixed, ResponseAnalysisEngine-Broken, BayesianConfidenceEngine, RuleBasedDecisionTrees, WindowManager-NUGGETRON, PatternRecognitionEngine-New, Unity-Claude-ErrorHandling, BatchProcessingEngine, DecisionEngine, ProgressTracker, DecisionMaking-Fixed, WindowManager-Original, SafetyValidationFramework, Unity-Claude-CLIOrchestrator-FullFeatured, PatternRecognitionEngine-Fixed, PriorityActionQueue, Unity-Claude-ScalabilityEnhancements-Original, Unity-Claude-AutonomousStateTracker, PatternRecognitionEngine, WindowManager, FallbackStrategies, Unity-Claude-Cache-Fixed, CircuitBreaker, ErrorHandling, DecisionMaking, OrchestrationCore, OrchestrationManager, Unity-Claude-CLISubmission, JsonProcessing

--- 
### Unity-Claude-CLIOrchestrator-Original-Backup

[⬆ Back to Contents](#-table-of-contents)

Master orchestration module coordinating complex multi-step workflows. Manages module interactions, handles state transitions, and ensures proper sequencing of automated operations. Unity Editor integration providing direct communication with Unity processes. Monitors compilation, extracts errors, and manages project operations. 

**Key Capabilities:** system initialization, validation and testing, data retrieval, specialized operations 

**Module Statistics:**
 - Functions: 5
 - Lines of Code: 577
 - Exported Members: 11


**Module Details:**
- **Path:** `Modules\Unity-Claude-CLIOrchestrator\Unity-Claude-CLIOrchestrator-Original-Backup.psm1`
- **Size:** 22.7 KB
- **Functions:** 4
- **Last Modified:** 2025-08-26 11:46

**Dependencies:** Unity-Claude-PerformanceOptimizer-Original, Unity-Claude-IncrementalProcessor, Unity-Claude-MasterOrchestrator-Original, Unity-Claude-CLIOrchestrator, EntityContextEngine, DecisionExecution, ResponseAnalysisEngine-Core, Unity-Claude-ParallelProcessor-Original, ActionExecutionEngine, Unity-Claude-CLIOrchestrator-Refactored-Fixed, Unity-Claude-Cache-Original, PatternRecognitionEngine-Original, PromptSubmissionEngine, ModuleFunctions, Unity-Claude-Cache, WindowManager-Enhanced, Unity-Claude-CLIOrchestrator-Fixed-Simple, DecisionExecution-Fixed, RecommendationPatternEngine, Unity-Claude-PerformanceOptimizer-Refactored, Performance-Cache, ResponseClassificationEngine, AutonomousOperations, Unity-Claude-IncrementalProcessor-Fixed, ResponseAnalysisEngine-Broken, BayesianConfidenceEngine, RuleBasedDecisionTrees, WindowManager-NUGGETRON, PatternRecognitionEngine-New, Unity-Claude-ErrorHandling, BatchProcessingEngine, DecisionEngine, DecisionMaking-Fixed, WindowManager-Original, SafetyValidationFramework, Unity-Claude-CLIOrchestrator-FullFeatured, PatternRecognitionEngine-Fixed, PriorityActionQueue, Unity-Claude-AutonomousStateTracker, PatternRecognitionEngine, WindowManager, FallbackStrategies, Unity-Claude-Cache-Fixed, CircuitBreaker, Unity-Claude-CLIOrchestrator-Original, ErrorHandling, DecisionMaking, Unity-Claude-CLIOrchestrator-Refactored, OrchestrationCore, OrchestrationManager, Unity-Claude-CLISubmission, JsonProcessing

--- 
### Unity-Claude-CLIOrchestrator-Refactored

[⬆ Back to Contents](#-table-of-contents)

Master orchestration module coordinating complex multi-step workflows. Manages module interactions, handles state transitions, and ensures proper sequencing of automated operations. Unity Editor integration providing direct communication with Unity processes. Monitors compilation, extracts errors, and manages project operations. 

**Key Capabilities:** system initialization, validation and testing, data retrieval, specialized operations 

**Module Statistics:**
 - Functions: 6
 - Lines of Code: 556
 - Exported Members: 2


**Module Details:**
- **Path:** `Modules\Unity-Claude-CLIOrchestrator\Unity-Claude-CLIOrchestrator-Refactored.psm1`
- **Size:** 22.24 KB
- **Functions:** 4
- **Last Modified:** 2025-08-26 22:32

**Dependencies:** Unity-Claude-CLIOrchestrator-Original-Backup, Unity-Claude-PerformanceOptimizer-Original, Unity-Claude-IncrementalProcessor, Unity-Claude-MasterOrchestrator-Original, Unity-Claude-CLIOrchestrator, EntityContextEngine, DecisionExecution, ResponseAnalysisEngine-Core, Unity-Claude-ParallelProcessor-Original, ActionExecutionEngine, Unity-Claude-CLIOrchestrator-Refactored-Fixed, Unity-Claude-Cache-Original, PatternRecognitionEngine-Original, PromptSubmissionEngine, ModuleFunctions, Unity-Claude-Cache, WindowManager-Enhanced, Unity-Claude-CLIOrchestrator-Fixed-Simple, DecisionExecution-Fixed, RecommendationPatternEngine, Unity-Claude-PerformanceOptimizer-Refactored, Performance-Cache, ResponseClassificationEngine, AutonomousOperations, Unity-Claude-IncrementalProcessor-Fixed, ResponseAnalysisEngine-Broken, BayesianConfidenceEngine, RuleBasedDecisionTrees, WindowManager-NUGGETRON, PatternRecognitionEngine-New, Unity-Claude-ErrorHandling, BatchProcessingEngine, DecisionEngine, DecisionMaking-Fixed, WindowManager-Original, SafetyValidationFramework, Unity-Claude-CLIOrchestrator-FullFeatured, PatternRecognitionEngine-Fixed, PriorityActionQueue, Unity-Claude-AutonomousStateTracker, PatternRecognitionEngine, WindowManager, FallbackStrategies, Unity-Claude-Cache-Fixed, CircuitBreaker, Unity-Claude-CLIOrchestrator-Original, ErrorHandling, DecisionMaking, OrchestrationCore, OrchestrationManager, Unity-Claude-CLISubmission, JsonProcessing

--- 
### Unity-Claude-CLIOrchestrator-Refactored-Fixed

[⬆ Back to Contents](#-table-of-contents)

Master orchestration module coordinating complex multi-step workflows. Manages module interactions, handles state transitions, and ensures proper sequencing of automated operations. Unity Editor integration providing direct communication with Unity processes. Monitors compilation, extracts errors, and manages project operations. 

**Key Capabilities:** system initialization, validation and testing, data retrieval, specialized operations 

**Module Statistics:**
 - Functions: 4
 - Lines of Code: 429
 - Exported Members: 2


**Module Details:**
- **Path:** `Modules\Unity-Claude-CLIOrchestrator\Unity-Claude-CLIOrchestrator-Refactored-Fixed.psm1`
- **Size:** 15.12 KB
- **Functions:** 4
- **Last Modified:** 2025-08-27 17:22

**Dependencies:** Unity-Claude-CLIOrchestrator-Original-Backup, Unity-Claude-PerformanceOptimizer-Original, Unity-Claude-IncrementalProcessor, Unity-Claude-MasterOrchestrator-Original, Unity-Claude-CLIOrchestrator, EntityContextEngine, DecisionExecution, ResponseAnalysisEngine-Core, Unity-Claude-ParallelProcessor-Original, ActionExecutionEngine, Unity-Claude-Cache-Original, PatternRecognitionEngine-Original, PromptSubmissionEngine, ModuleFunctions, Unity-Claude-Cache, WindowManager-Enhanced, Unity-Claude-CLIOrchestrator-Fixed-Simple, DecisionExecution-Fixed, RecommendationPatternEngine, Unity-Claude-PerformanceOptimizer-Refactored, Performance-Cache, ResponseClassificationEngine, AutonomousOperations, Unity-Claude-IncrementalProcessor-Fixed, ResponseAnalysisEngine-Broken, BayesianConfidenceEngine, RuleBasedDecisionTrees, WindowManager-NUGGETRON, PatternRecognitionEngine-New, Unity-Claude-ErrorHandling, BatchProcessingEngine, DecisionEngine, DecisionMaking-Fixed, WindowManager-Original, SafetyValidationFramework, Unity-Claude-CLIOrchestrator-FullFeatured, PatternRecognitionEngine-Fixed, PriorityActionQueue, Unity-Claude-AutonomousStateTracker, PatternRecognitionEngine, WindowManager, FallbackStrategies, Unity-Claude-Cache-Fixed, CircuitBreaker, Unity-Claude-CLIOrchestrator-Original, ErrorHandling, DecisionMaking, Unity-Claude-CLIOrchestrator-Refactored, OrchestrationCore, OrchestrationManager, Unity-Claude-CLISubmission, JsonProcessing

--- 
### Unity-Claude-CLISubmission

[⬆ Back to Contents](#-table-of-contents)

Unity Editor integration providing direct communication with Unity processes. Monitors compilation, extracts errors, and manages project operations.

**Key Capabilities:** process initiation, process termination, resource creation, request processing

**Module Statistics:**
- Functions: 8
- Lines of Code: 975
- Classes: 2
- Exported Members: 1


**Module Details:**
- **Path:** `Modules\Unity-Claude-CLISubmission.psm1`
- **Size:** 45.44 KB
- **Functions:** 7
- **Last Modified:** 2025-08-20 17:25

**Dependencies:** Unity-Claude-PerformanceOptimizer-Original, Unity-Claude-IncrementalProcessor, Unity-Claude-MasterOrchestrator-Original, Unity-Claude-ParallelProcessor-Original, Unity-Claude-Cache-Original, ModuleFunctions, Unity-Claude-Cache, Unity-Claude-WindowDetection, Unity-Claude-PerformanceOptimizer-Refactored, Performance-Cache, AutonomousOperations, Unity-Claude-IncrementalProcessor-Fixed, Unity-Claude-IntegrationEngine, Unity-Claude-ResponseMonitoring, ResponseMonitoring, BatchProcessingEngine, AutonomousFeedbackLoop, Unity-Claude-Cache-Fixed, Unity-Claude-CLIOrchestrator-Original, ClaudeIntegration

--- 
### Unity-Claude-CLISubmission-Enhanced

[⬆ Back to Contents](#-table-of-contents)

Unity Editor integration providing direct communication with Unity processes. Monitors compilation, extracts errors, and manages project operations.

**Key Capabilities:** request processing, process initiation, process termination, specialized operations

**Module Statistics:**
- Functions: 8
- Lines of Code: 475
- Classes: 2
- Exported Members: 1


**Module Details:**
- **Path:** `Modules\Unity-Claude-CLISubmission-Enhanced.psm1`
- **Size:** 16.43 KB
- **Functions:** 6
- **Last Modified:** 2025-08-21 20:16

**Dependencies:** CPG-DataStructures, CrossLanguage-DependencyMaps, Unity-Claude-PerformanceOptimizer-Original, Unity-Claude-IncrementalProcessor, CPG-Unified, Unity-Claude-ParallelProcessor-Original, Unity-Claude-Cache-Original, Unity-Claude-Cache, Unity-Claude-PerformanceOptimizer-Refactored, Performance-Cache, Unity-Claude-CPG-Original, Unity-Claude-IncrementalProcessor-Fixed, BatchProcessingEngine, Unity-Claude-Cache-Fixed, ClaudeIntegration

--- 
### Unity-Claude-CodeQL

[⬆ Back to Contents](#-table-of-contents)

Unity Editor integration providing direct communication with Unity processes. Monitors compilation, extracts errors, and manages project operations.

**Key Capabilities:** specialized operations, validation and testing, resource creation, system initialization

**Module Statistics:**
- Functions: 10
- Lines of Code: 733
- Exported Members: 1


**Module Details:**
- **Path:** `Modules\Unity-Claude-CodeQL\Unity-Claude-CodeQL.psm1`
- **Size:** 24.37 KB
- **Functions:** 10
- **Last Modified:** 2025-08-26 11:46

**Dependencies:** Unity-Claude-ParallelProcessor-Original, Unity-Claude-Cache-Original, ModuleFunctions, Unity-Claude-Cache, Performance-Cache, Unity-Claude-Cache-Fixed

--- 
### Unity-Claude-ConcurrentCollections

[⬆ Back to Contents](#-table-of-contents)

Unity Editor integration providing direct communication with Unity processes. Monitors compilation, extracts errors, and manages project operations.

**Key Capabilities:** resource creation, specialized operations, data retrieval, validation and testing

**Module Statistics:**
- Functions: 15
- Lines of Code: 787
- Exported Members: 1


**Module Details:**
- **Path:** `Modules\Unity-Claude-ParallelProcessing\Unity-Claude-ConcurrentCollections.psm1`
- **Size:** 25.57 KB
- **Functions:** 14
- **Last Modified:** 2025-08-21 17:45

**Dependencies:** Unity-Claude-PerformanceOptimizer-Original, JobScheduler, Unity-Claude-IncrementalProcessor, Unity-Claude-ParallelProcessor-Original, RunspacePoolManager, Unity-Claude-Cache-Original, StatisticsTracker, ModuleFunctions, Unity-Claude-Cache, Unity-Claude-PerformanceOptimizer-Refactored, Performance-Cache, Unity-Claude-IncrementalProcessor-Fixed, BatchProcessingEngine, ProgressTracker, Unity-Claude-ScalabilityEnhancements-Original, Unity-Claude-Cache-Fixed

--- 
### Unity-Claude-ConcurrentProcessor

[⬆ Back to Contents](#-table-of-contents)

Unity Editor integration providing direct communication with Unity processes. Monitors compilation, extracts errors, and manages project operations.

**Key Capabilities:** specialized operations, resource creation, data retrieval, action execution

**Module Statistics:**
- Functions: 17
- Lines of Code: 999
- Exported Members: 1


**Module Details:**
- **Path:** `Modules\Unity-Claude-ConcurrentProcessor.psm1`
- **Size:** 34.36 KB
- **Functions:** 17
- **Last Modified:** 2025-08-20 17:25

**Dependencies:** CPG-DataStructures, CrossLanguage-DependencyMaps, Unity-Claude-PerformanceOptimizer-Original, Unity-Claude-IncrementalProcessor, CPG-Unified, Unity-Claude-ParallelProcessor-Original, Unity-Claude-Cache-Original, Unity-Claude-SystemCoordinator, ModuleFunctions, Unity-Claude-Cache, Unity-Claude-ParallelProcessing, Unity-Claude-PerformanceOptimizer-Refactored, Performance-Cache, Unity-Claude-CPG-Original, Unity-Claude-IncrementalProcessor-Fixed, BatchProcessingEngine, Unity-Claude-Cache-Fixed

--- 
### Unity-Claude-CPG

[⬆ Back to Contents](#-table-of-contents)

Unity Editor integration providing direct communication with Unity processes. Monitors compilation, extracts errors, and manages project operations.

**Key Capabilities:** specialized operations

**Module Statistics:**
- Functions: 3
- Lines of Code: 207
- Exported Members: 1


**Module Details:**
- **Path:** `Modules\Unity-Claude-CPG\Unity-Claude-CPG.psm1`
- **Size:** 8.38 KB
- **Functions:** 3
- **Last Modified:** 2025-08-26 11:46

**Dependencies:** CPG-DataStructures, CrossLanguage-DependencyMaps, CPG-SerializationOperations, CPG-Unified, Unity-Claude-SemanticAnalysis-Old, Unity-Claude-SemanticAnalysis, Unity-Claude-Cache-Original, Unity-Claude-Cache, Performance-Cache, Unity-Claude-SemanticAnalysis-New, Unity-Claude-CPG-ASTConverter, Unity-Claude-CPG-Original, CPG-BasicOperations, CPG-QueryOperations, Unity-Claude-CPG-Refactored, Unity-Claude-Cache-Fixed, CPG-AnalysisOperations

--- 
### Unity-Claude-CPG-ASTConverter

[⬆ Back to Contents](#-table-of-contents)

Unity Editor integration providing direct communication with Unity processes. Monitors compilation, extracts errors, and manages project operations.

**Key Capabilities:** specialized operations

**Module Statistics:**
- Functions: 31
- Lines of Code: 1045
- Classes: 2
- Exported Members: 1


**Module Details:**
- **Path:** `Modules\Unity-Claude-CPG\Unity-Claude-CPG-ASTConverter.psm1`
- **Size:** 37.8 KB
- **Functions:** 20
- **Last Modified:** 2025-08-24 23:42

**Dependencies:** CPG-DataStructures, CrossLanguage-DependencyMaps, CPG-Unified, Unity-Claude-SemanticAnalysis-Old, Unity-Claude-SemanticAnalysis, TreeSitter-CSTConverter, Unity-Claude-Cache-Original, Unity-Claude-Cache, Performance-Cache, Unity-Claude-SemanticAnalysis-New, Unity-Claude-CPG, Unity-Claude-CPG-Original, CPG-BasicOperations, CPG-QueryOperations, Unity-Claude-CPG-Refactored, Unity-Claude-Cache-Fixed, CPG-AdvancedEdges

--- 
### Unity-Claude-CPG-Original

[⬆ Back to Contents](#-table-of-contents)

Unity Editor integration providing direct communication with Unity processes. Monitors compilation, extracts errors, and manages project operations.

**Key Capabilities:** resource creation, specialized operations

**Module Statistics:**
- Functions: 17
- Lines of Code: 1026
- Classes: 3
- Exported Members: 1


**Module Details:**
- **Path:** `Modules\Unity-Claude-CPG\Unity-Claude-CPG-Original.psm1`
- **Size:** 31.05 KB
- **Functions:** 33
- **Last Modified:** 2025-08-26 11:46

**Dependencies:** CPG-DataStructures, CrossLanguage-DependencyMaps, CPG-SerializationOperations, Unity-Claude-IncrementalProcessor, Performance-IncrementalUpdates, CPG-Unified, Unity-Claude-SemanticAnalysis-Old, Unity-Claude-SemanticAnalysis, Unity-Claude-ParallelProcessor-Original, Unity-Claude-Cache-Original, StatisticsTracker, ModuleFunctions, Unity-Claude-Cache, Performance-Cache, Unity-Claude-SemanticAnalysis-New, CrossLanguage-GraphMerger, Unity-Claude-CPG-ASTConverter, Unity-Claude-CPG, Unity-Claude-IncrementalProcessor-Fixed, CPG-BasicOperations, CPG-QueryOperations, BatchProcessingEngine, Unity-Claude-CPG-Refactored, Unity-Claude-Cache-Fixed, CPG-AnalysisOperations

--- 
### Unity-Claude-CPG-Refactored

[⬆ Back to Contents](#-table-of-contents)

Unity Editor integration providing direct communication with Unity processes. Monitors compilation, extracts errors, and manages project operations.

**Key Capabilities:** specialized operations

**Module Statistics:**
- Functions: 3
- Lines of Code: 207
- Exported Members: 1


**Module Details:**
- **Path:** `Modules\Unity-Claude-CPG\Unity-Claude-CPG-Refactored.psm1`
- **Size:** 8.38 KB
- **Functions:** 3
- **Last Modified:** 2025-08-26 11:46

**Dependencies:** CPG-DataStructures, CrossLanguage-DependencyMaps, CPG-SerializationOperations, CPG-Unified, Unity-Claude-SemanticAnalysis-Old, Unity-Claude-SemanticAnalysis, Unity-Claude-Cache-Original, Unity-Claude-Cache, Performance-Cache, Unity-Claude-SemanticAnalysis-New, Unity-Claude-CPG-ASTConverter, Unity-Claude-CPG, Unity-Claude-CPG-Original, CPG-BasicOperations, CPG-QueryOperations, Unity-Claude-Cache-Fixed, CPG-AnalysisOperations

--- 
### Unity-Claude-CrossLanguage

[⬆ Back to Contents](#-table-of-contents)

Unity Editor integration providing direct communication with Unity processes. Monitors compilation, extracts errors, and manages project operations.

**Key Capabilities:** specialized operations, validation and testing

**Module Statistics:**
- Functions: 10
- Lines of Code: 603
- Classes: 2
- Exported Members: 1


**Module Details:**
- **Path:** `Modules\Unity-Claude-CPG\Unity-Claude-CrossLanguage.psm1`
- **Size:** 22.28 KB
- **Functions:** 9
- **Last Modified:** 2025-08-24 23:42

**Dependencies:** CPG-DataStructures, CrossLanguage-DependencyMaps, CPG-Unified, EntityContextEngine, Unity-Claude-Cache-Original, Unity-Claude-Cache, Performance-Cache, ErrorDetection, Unity-Claude-Learning-Original, CrossLanguage-GraphMerger, Unity-Claude-CPG-Original, Unity-Claude-Learning-Simple, CPG-BasicOperations, StringSimilarity, UnityIntegration, Unity-Claude-Cache-Fixed, Unity-Claude-AIAlertClassifier

--- 
### Unity-Claude-DecisionEngine

[⬆ Back to Contents](#-table-of-contents)

Decision engine module implementing rule-based and ML-enhanced decision trees. Analyzes inputs, evaluates constraints, and determines appropriate actions based on configurable policies. Unity Editor integration providing direct communication with Unity processes. Monitors compilation, extracts errors, and manages project operations. 

**Key Capabilities:** specialized operations, data retrieval, action execution, validation and testing 

**Module Statistics:**
 - Functions: 6
 - Lines of Code: 489
 - Exported Members: 1


**Module Details:**
- **Path:** `Modules\Unity-Claude-DecisionEngine\Unity-Claude-DecisionEngine.psm1`
- **Size:** 18.09 KB
- **Functions:** 5
- **Last Modified:** 2025-08-26 11:46

**Dependencies:** Unity-Claude-ParallelProcessor-Original, Unity-Claude-Cache-Original, ModuleFunctions, Unity-Claude-Cache, Unity-Claude-DecisionEngine-Refactored, Performance-Cache, ResponseAnalysis, Unity-Claude-ResponseMonitor, Unity-Claude-DecisionEngine-Original, IntegrationManagement, Unity-Claude-FixEngine, DecisionEngine-Refactored, Unity-Claude-Cache-Fixed, DecisionEngineCore

--- 
### Unity-Claude-DecisionEngine-Bayesian

[⬆ Back to Contents](#-table-of-contents)

Decision engine module implementing rule-based and ML-enhanced decision trees. Analyzes inputs, evaluates constraints, and determines appropriate actions based on configurable policies. Unity Editor integration providing direct communication with Unity processes. Monitors compilation, extracts errors, and manages project operations. Bayesian inference engine for probabilistic reasoning and confidence scoring. Updates beliefs based on evidence and provides uncertainty quantification. 

**Module Statistics:**
 - Functions: 0
 - Lines of Code: 96
 - Exported Members: 1


**Module Details:**
- **Path:** `Modules\Unity-Claude-CLIOrchestrator\Core\DecisionEngine-Bayesian\Unity-Claude-DecisionEngine-Bayesian.psm1`
- **Size:** 4.21 KB
- **Functions:** 0
- **Last Modified:** 2025-08-26 11:46

**Dependencies:** Unity-Claude-Cache-Original, PatternRecognitionEngine-Original, Unity-Claude-Cache, Performance-Cache, Unity-Claude-Cache-Fixed

--- 
### Unity-Claude-DecisionEngine-Original

[⬆ Back to Contents](#-table-of-contents)

Decision engine module implementing rule-based and ML-enhanced decision trees. Analyzes inputs, evaluates constraints, and determines appropriate actions based on configurable policies. Unity Editor integration providing direct communication with Unity processes. Monitors compilation, extracts errors, and manages project operations. 

**Key Capabilities:** specialized operations, validation and testing, data retrieval, configuration management, action execution 

**Module Statistics:**
 - Functions: 27
 - Lines of Code: 1340


**Module Details:**
- **Path:** `Modules\Unity-Claude-DecisionEngine\Unity-Claude-DecisionEngine-Original.psm1`
- **Size:** 46.72 KB
- **Functions:** 27
- **Last Modified:** 2025-08-26 11:46

**Dependencies:** CPG-DataStructures, CrossLanguage-DependencyMaps, CPG-Unified, Unity-Claude-Cache-Original, Unity-Claude-Cache, Performance-Cache, ResponseAnalysis, Unity-Claude-CPG-Original, Unity-Claude-ResponseMonitor, IntegrationManagement, Unity-Claude-FixEngine, Unity-Claude-Cache-Fixed, DecisionEngineCore

--- 
### Unity-Claude-DecisionEngine-Refactored

[⬆ Back to Contents](#-table-of-contents)

Decision engine module implementing rule-based and ML-enhanced decision trees. Analyzes inputs, evaluates constraints, and determines appropriate actions based on configurable policies. Unity Editor integration providing direct communication with Unity processes. Monitors compilation, extracts errors, and manages project operations. 

**Key Capabilities:** specialized operations, data retrieval, action execution, validation and testing 

**Module Statistics:**
 - Functions: 6
 - Lines of Code: 489
 - Exported Members: 1


**Module Details:**
- **Path:** `Modules\Unity-Claude-DecisionEngine\Unity-Claude-DecisionEngine-Refactored.psm1`
- **Size:** 18.09 KB
- **Functions:** 5
- **Last Modified:** 2025-08-26 11:46

**Dependencies:** Unity-Claude-ParallelProcessor-Original, Unity-Claude-Cache-Original, ModuleFunctions, Unity-Claude-Cache, Performance-Cache, ResponseAnalysis, Unity-Claude-ResponseMonitor, Unity-Claude-DecisionEngine-Original, Unity-Claude-DecisionEngine, IntegrationManagement, Unity-Claude-FixEngine, DecisionEngine-Refactored, Unity-Claude-Cache-Fixed, DecisionEngineCore

--- 
### Unity-Claude-DocumentationAnalytics

[⬆ Back to Contents](#-table-of-contents)

Documentation automation module providing real-time documentation updates. Generates API docs, maintains cross-references, and ensures documentation accuracy. Unity Editor integration providing direct communication with Unity processes. Monitors compilation, extracts errors, and manages project operations. 

**Key Capabilities:** system initialization, process initiation, data retrieval, specialized operations 

**Module Statistics:**
 - Functions: 14
 - Lines of Code: 1042
 - Exported Members: 1


**Module Details:**
- **Path:** `Modules\Unity-Claude-DocumentationAnalytics\Unity-Claude-DocumentationAnalytics.psm1`
- **Size:** 44.08 KB
- **Functions:** 14
- **Last Modified:** 2025-08-30 20:15

**Dependencies:** Unity-Claude-PerformanceOptimizer-Original, Unity-Claude-IncrementalProcessor, Unity-Claude-ParallelProcessor-Original, Unity-Claude-Cache-Original, ModuleFunctions, Unity-Claude-Cache, Unity-Claude-PerformanceOptimizer-Refactored, Performance-Cache, Unity-Claude-IncrementalProcessor-Fixed, BatchProcessingEngine, Unity-Claude-Cache-Fixed

--- 
### Unity-Claude-DocumentationAutomation

[⬆ Back to Contents](#-table-of-contents)

Documentation automation module providing real-time documentation updates. Generates API docs, maintains cross-references, and ensures documentation accuracy. Unity Editor integration providing direct communication with Unity processes. Monitors compilation, extracts errors, and manages project operations. 

**Key Capabilities:** system initialization, validation and testing, data retrieval 

**Module Statistics:**
 - Functions: 3
 - Lines of Code: 453
 - Exported Members: 1


**Module Details:**
- **Path:** `Modules\Unity-Claude-DocumentationAutomation\Unity-Claude-DocumentationAutomation.psm1`
- **Size:** 16.62 KB
- **Functions:** 3
- **Last Modified:** 2025-08-26 11:46

**Dependencies:** Unity-Claude-PerformanceOptimizer-Original, Unity-Claude-IncrementalProcessor, Unity-Claude-ParallelProcessor-Original, Unity-Claude-Cache-Original, BackupIntegration, ModuleFunctions, Unity-Claude-Cache, Unity-Claude-DocumentationAutomation-Refactored, Unity-Claude-PerformanceOptimizer-Refactored, Unity-Claude-TriggerManager, Performance-Cache, Unity-Claude-IncrementalProcessor-Fixed, Unity-Claude-DocumentationDrift, BatchProcessingEngine, AutomationEngine, TemplateSystem, TriggerSystem, Unity-Claude-Cache-Fixed, GitHubPRManager, PromptTemplateSystem, Unity-Claude-DocumentationAutomation-Original

--- 
### Unity-Claude-DocumentationAutomation-Original

[⬆ Back to Contents](#-table-of-contents)

Documentation automation module providing real-time documentation updates. Generates API docs, maintains cross-references, and ensures documentation accuracy. Unity Editor integration providing direct communication with Unity processes. Monitors compilation, extracts errors, and manages project operations. 

**Key Capabilities:** process initiation, process termination, validation and testing, data retrieval, resource creation 

**Module Statistics:**
 - Functions: 20
 - Lines of Code: 1634
 - Exported Members: 1


**Module Details:**
- **Path:** `Modules\Unity-Claude-DocumentationAutomation\Unity-Claude-DocumentationAutomation-Original.psm1`
- **Size:** 54.38 KB
- **Functions:** 20
- **Last Modified:** 2025-08-25 13:45

**Dependencies:** CPG-DataStructures, CrossLanguage-DependencyMaps, Unity-Claude-PerformanceOptimizer-Original, Unity-Claude-IncrementalProcessor, CPG-Unified, Unity-Claude-ParallelProcessor-Original, RunspacePoolManager, Unity-Claude-Cache-Original, BackupIntegration, ModuleFunctions, Unity-Claude-Cache, Unity-Claude-PerformanceOptimizer-Refactored, Unity-Claude-TriggerManager, Performance-Cache, Unity-Claude-CPG-Original, Unity-Claude-IncrementalProcessor-Fixed, Unity-Claude-DocumentationDrift, BatchProcessingEngine, AutomationEngine, TemplateSystem, TriggerSystem, Unity-Claude-Cache-Fixed, GitHubPRManager

--- 
### Unity-Claude-DocumentationAutomation-Refactored

[⬆ Back to Contents](#-table-of-contents)

Documentation automation module providing real-time documentation updates. Generates API docs, maintains cross-references, and ensures documentation accuracy. Unity Editor integration providing direct communication with Unity processes. Monitors compilation, extracts errors, and manages project operations. 

**Key Capabilities:** system initialization, validation and testing, data retrieval 

**Module Statistics:**
 - Functions: 3
 - Lines of Code: 453
 - Exported Members: 1


**Module Details:**
- **Path:** `Modules\Unity-Claude-DocumentationAutomation\Unity-Claude-DocumentationAutomation-Refactored.psm1`
- **Size:** 16.62 KB
- **Functions:** 3
- **Last Modified:** 2025-08-26 11:46

**Dependencies:** Unity-Claude-PerformanceOptimizer-Original, Unity-Claude-IncrementalProcessor, Unity-Claude-ParallelProcessor-Original, Unity-Claude-Cache-Original, BackupIntegration, ModuleFunctions, Unity-Claude-Cache, Unity-Claude-PerformanceOptimizer-Refactored, Unity-Claude-TriggerManager, Performance-Cache, Unity-Claude-IncrementalProcessor-Fixed, Unity-Claude-DocumentationDrift, BatchProcessingEngine, AutomationEngine, Unity-Claude-DocumentationAutomation, TemplateSystem, TriggerSystem, Unity-Claude-Cache-Fixed, GitHubPRManager, PromptTemplateSystem, Unity-Claude-DocumentationAutomation-Original

--- 
### Unity-Claude-DocumentationCrossReference

[⬆ Back to Contents](#-table-of-contents)

Documentation automation module providing real-time documentation updates. Generates API docs, maintains cross-references, and ensures documentation accuracy. Unity Editor integration providing direct communication with Unity processes. Monitors compilation, extracts errors, and manages project operations. 

**Key Capabilities:** system initialization, data retrieval, specialized operations 

**Module Statistics:**
 - Functions: 31
 - Lines of Code: 1576
 - Exported Members: 1


**Module Details:**
- **Path:** `Modules\Unity-Claude-DocumentationCrossReference\Unity-Claude-DocumentationCrossReference.psm1`
- **Size:** 64.02 KB
- **Functions:** 12
- **Last Modified:** 2025-08-30 19:08

**Dependencies:** Unity-Claude-PerformanceOptimizer-Original, Unity-Claude-IncrementalProcessor, Unity-Claude-ParallelProcessor-Original, TreeSitter-CSTConverter, SemanticAnalysis-PatternDetector, Unity-Claude-Cache-Original, Unity-Claude-DocumentationQualityAssessment, ModuleFunctions, Unity-Claude-Cache, Unity-Claude-PerformanceOptimizer-Refactored, Unity-Claude-TriggerManager, Performance-Cache, Unity-Claude-Ollama, Unity-Claude-IncrementalProcessor-Fixed, BatchProcessingEngine, Unity-Claude-AutonomousDocumentationEngine, Unity-Claude-Cache-Fixed, Unity-Claude-DocumentationQualityAssessment_Original_20250830_193150, Unity-Claude-DocumentationQualityOrchestrator

--- 
### Unity-Claude-DocumentationDrift

[⬆ Back to Contents](#-table-of-contents)

Documentation automation module providing real-time documentation updates. Generates API docs, maintains cross-references, and ensures documentation accuracy. Unity Editor integration providing direct communication with Unity processes. Monitors compilation, extracts errors, and manages project operations. 

**Key Capabilities:** system initialization, data retrieval, configuration management, specialized operations 

**Module Statistics:**
 - Functions: 65
 - Lines of Code: 3709
 - Classes: 8
 - Exported Members: 1


**Module Details:**
- **Path:** `Modules\Unity-Claude-DocumentationDrift\Unity-Claude-DocumentationDrift.psm1`
- **Size:** 142.95 KB
- **Functions:** 55
- **Last Modified:** 2025-08-24 12:06

**Dependencies:** Unity-Claude-PerformanceOptimizer-Original, Unity-Claude-DocumentationDrift-Refactored, Unity-Claude-IncrementalProcessor, Unity-Claude-IntelligentDocumentationTriggers, Unity-Claude-ParallelProcessor-Original, ImpactAnalysis, MetricsCollection, Unity-Claude-Cache-Original, ModuleFunctions, Unity-Claude-Cache, MetricsAndHealthCheck, Unity-Claude-PerformanceOptimizer-Refactored, Performance-Cache, Unity-Claude-IncrementalProcessor-Fixed, BatchProcessingEngine, Configuration, Templates-PerLanguage, Unity-Claude-Cache-Fixed, GitHubPRManager, Unity-Claude-DocumentationAutomation-Original

--- 
### Unity-Claude-DocumentationDrift-Refactored

[⬆ Back to Contents](#-table-of-contents)

Documentation automation module providing real-time documentation updates. Generates API docs, maintains cross-references, and ensures documentation accuracy. Unity Editor integration providing direct communication with Unity processes. Monitors compilation, extracts errors, and manages project operations. 

**Key Capabilities:** specialized operations, data retrieval, validation and testing 

**Module Statistics:**
 - Functions: 3
 - Lines of Code: 270
 - Exported Members: 1


**Module Details:**
- **Path:** `Modules\Unity-Claude-DocumentationDrift\Unity-Claude-DocumentationDrift-Refactored.psm1`
- **Size:** 9.91 KB
- **Functions:** 3
- **Last Modified:** 2025-08-26 11:46

**Dependencies:** Unity-Claude-PerformanceOptimizer-Original, Unity-Claude-IncrementalProcessor, Unity-Claude-IntelligentDocumentationTriggers, Unity-Claude-ParallelProcessor-Original, ImpactAnalysis, Unity-Claude-Cache-Original, ModuleFunctions, Unity-Claude-Cache, Unity-Claude-RepoAnalyst, Unity-Claude-PerformanceOptimizer-Refactored, Performance-Cache, Unity-Claude-IncrementalProcessor-Fixed, Unity-Claude-DocumentationDrift, BatchProcessingEngine, Configuration, Unity-Claude-Cache-Fixed

--- 
### Unity-Claude-DocumentationPipeline

[⬆ Back to Contents](#-table-of-contents)

Documentation automation module providing real-time documentation updates. Generates API docs, maintains cross-references, and ensures documentation accuracy. Unity Editor integration providing direct communication with Unity processes. Monitors compilation, extracts errors, and manages project operations. 

**Key Capabilities:** resource creation, action execution, specialized operations 

**Module Statistics:**
 - Functions: 6
 - Lines of Code: 363
 - Exported Members: 1


**Module Details:**
- **Path:** `Modules\Unity-Claude-LLM\Unity-Claude-DocumentationPipeline.psm1`
- **Size:** 13.73 KB
- **Functions:** 6
- **Last Modified:** 2025-08-25 03:00

**Dependencies:** CPG-DataStructures, CrossLanguage-DependencyMaps, Unity-Claude-SemanticAnalysis-Metrics, AutoGenerationTriggers, CPG-Unified, Unity-Claude-SemanticAnalysis-Old, Unity-Claude-SemanticAnalysis, Unity-Claude-Cache-Original, Unity-Claude-Cache, Unity-Claude-TriggerManager, Performance-Cache, Unity-Claude-SemanticAnalysis-New, Unity-Claude-CPG-ASTConverter, Unity-Claude-SemanticAnalysis-Purpose, Unity-Claude-CPG, Unity-Claude-CPG-Original, Unity-Claude-LLM, CPG-QueryOperations, Unity-Claude-SemanticAnalysis-Business, Unity-Claude-SemanticAnalysis-Patterns, Unity-Claude-CPG-Refactored, Unity-Claude-Cache-Fixed

--- 
### Unity-Claude-DocumentationQualityAssessment

[⬆ Back to Contents](#-table-of-contents)

Documentation automation module providing real-time documentation updates. Generates API docs, maintains cross-references, and ensures documentation accuracy. Unity Editor integration providing direct communication with Unity processes. Monitors compilation, extracts errors, and manages project operations. 

**Key Capabilities:** specialized operations 

**Module Statistics:**
 - Functions: 2
 - Lines of Code: 133
 - Exported Members: 2


**Module Details:**
- **Path:** `Modules\Unity-Claude-DocumentationQualityAssessment\Unity-Claude-DocumentationQualityAssessment.psm1`
- **Size:** 5.28 KB
- **Functions:** 3
- **Last Modified:** 2025-08-30 19:40

**Dependencies:** Unity-Claude-ParallelProcessor-Original, Unity-Claude-Cache-Original, ModuleFunctions, Unity-Claude-Cache, Unity-Claude-PredictiveAnalysis-Original, ContentAnalysis, AnalyticsReporting, Performance-Cache, SystemIntegration, ReadabilityAlgorithms, Unity-Claude-AutonomousDocumentationEngine, Unity-Claude-Cache-Fixed, AIAssessment, Unity-Claude-DocumentationQualityAssessment_Original_20250830_193150

--- 
### Unity-Claude-DocumentationQualityAssessment_Original_20250830_193150

[⬆ Back to Contents](#-table-of-contents)

Documentation automation module providing real-time documentation updates. Generates API docs, maintains cross-references, and ensures documentation accuracy. Unity Editor integration providing direct communication with Unity processes. Monitors compilation, extracts errors, and manages project operations. 

**Key Capabilities:** system initialization, data retrieval, specialized operations 

**Module Statistics:**
 - Functions: 26
 - Lines of Code: 1024
 - Exported Members: 1


**Module Details:**
- **Path:** `Modules\Unity-Claude-DocumentationQualityAssessment\Unity-Claude-DocumentationQualityAssessment_Original_20250830_193150.psm1`
- **Size:** 38.58 KB
- **Functions:** 3
- **Last Modified:** 2025-08-30 19:27

**Dependencies:** CPG-DataStructures, CrossLanguage-DependencyMaps, Unity-Claude-PerformanceOptimizer-Original, Unity-Claude-IncrementalProcessor, CPG-Unified, Unity-Claude-ParallelProcessor-Original, Unity-Claude-Cache-Original, Unity-Claude-DocumentationQualityAssessment, ModuleFunctions, Unity-Claude-Cache, Unity-Claude-PredictiveAnalysis-Original, ContentAnalysis, AnalyticsReporting, Unity-Claude-PerformanceOptimizer-Refactored, Performance-Cache, SystemIntegration, ReadabilityAlgorithms, Unity-Claude-CPG-Original, Unity-Claude-IncrementalProcessor-Fixed, BatchProcessingEngine, Unity-Claude-AutonomousDocumentationEngine, Unity-Claude-Cache-Fixed, AIAssessment

--- 
### Unity-Claude-DocumentationQualityOrchestrator

[⬆ Back to Contents](#-table-of-contents)

Master orchestration module coordinating complex multi-step workflows. Manages module interactions, handles state transitions, and ensures proper sequencing of automated operations. Documentation automation module providing real-time documentation updates. Generates API docs, maintains cross-references, and ensures documentation accuracy. Unity Editor integration providing direct communication with Unity processes. Monitors compilation, extracts errors, and manages project operations. 

**Key Capabilities:** system initialization, data retrieval, process initiation, specialized operations 

**Module Statistics:**
 - Functions: 24
 - Lines of Code: 988
 - Exported Members: 1


**Module Details:**
- **Path:** `Modules\Unity-Claude-DocumentationQualityOrchestrator\Unity-Claude-DocumentationQualityOrchestrator.psm1`
- **Size:** 37.23 KB
- **Functions:** 24
- **Last Modified:** 2025-08-30 18:38

**Dependencies:** CPG-DataStructures, CrossLanguage-DependencyMaps, Unity-Claude-PerformanceOptimizer-Original, Unity-Claude-IncrementalProcessor, CPG-Unified, Unity-Claude-DocumentationCrossReference, Unity-Claude-ParallelProcessor-Original, Unity-Claude-Cache-Original, Unity-Claude-DocumentationQualityAssessment, ModuleFunctions, Unity-Claude-Cache, Unity-Claude-PerformanceOptimizer-Refactored, Performance-Cache, PerformanceMonitoring, Unity-Claude-CPG-Original, Unity-Claude-IncrementalProcessor-Fixed, Unity-Claude-DocumentationSuggestions, BatchProcessingEngine, Unity-Claude-PerformanceOptimizer, Unity-Claude-AutonomousDocumentationEngine, Unity-Claude-ScalabilityOptimizer, Unity-Claude-AutonomousStateTracker, Unity-Claude-Cache-Fixed, Unity-Claude-DocumentationQualityAssessment_Original_20250830_193150

--- 
### Unity-Claude-DocumentationSuggestions

[⬆ Back to Contents](#-table-of-contents)

Documentation automation module providing real-time documentation updates. Generates API docs, maintains cross-references, and ensures documentation accuracy. Unity Editor integration providing direct communication with Unity processes. Monitors compilation, extracts errors, and manages project operations. 

**Key Capabilities:** system initialization, specialized operations 

**Module Statistics:**
 - Functions: 18
 - Lines of Code: 1171
 - Exported Members: 1


**Module Details:**
- **Path:** `Modules\Unity-Claude-DocumentationSuggestions\Unity-Claude-DocumentationSuggestions.psm1`
- **Size:** 43.47 KB
- **Functions:** 15
- **Last Modified:** 2025-08-30 19:47

**Dependencies:** Unity-Claude-PerformanceOptimizer-Original, Unity-Claude-IncrementalProcessor, Performance-IncrementalUpdates, Unity-Claude-DocumentationCrossReference, Unity-Claude-ParallelProcessor-Original, Unity-Claude-Cache-Original, ModuleFunctions, Unity-Claude-Cache, Unity-Claude-PerformanceOptimizer-Refactored, Performance-Cache, Unity-Claude-Ollama, Unity-Claude-IncrementalProcessor-Fixed, BatchProcessingEngine, Unity-Claude-Cache-Fixed

--- 
### Unity-Claude-DocumentationVersioning

[⬆ Back to Contents](#-table-of-contents)

Documentation automation module providing real-time documentation updates. Generates API docs, maintains cross-references, and ensures documentation accuracy. Unity Editor integration providing direct communication with Unity processes. Monitors compilation, extracts errors, and manages project operations. 

**Key Capabilities:** system initialization, data retrieval, specialized operations 

**Module Statistics:**
 - Functions: 26
 - Lines of Code: 720
 - Exported Members: 1


**Module Details:**
- **Path:** `Modules\Unity-Claude-DocumentationVersioning\Unity-Claude-DocumentationVersioning.psm1`
- **Size:** 25.49 KB
- **Functions:** 25
- **Last Modified:** 2025-08-30 15:41

**Dependencies:** CPG-DataStructures, CrossLanguage-DependencyMaps, CPG-Unified, Unity-Claude-ParallelProcessor-Original, Unity-Claude-Cache-Original, ModuleFunctions, Unity-Claude-Cache, Performance-Cache, Unity-Claude-CPG-Original, Unity-Claude-AutonomousDocumentationEngine, Unity-Claude-Cache-Fixed

--- 
### Unity-Claude-EmailNotifications

[⬆ Back to Contents](#-table-of-contents)

Unity Editor integration providing direct communication with Unity processes. Monitors compilation, extracts errors, and manages project operations. Email notification module for multi-channel alert delivery. Supports SMTP configuration, templated messages, and escalation chains. 

**Key Capabilities:** specialized operations, resource creation, configuration management, validation and testing, data retrieval 

**Module Statistics:**
 - Functions: 7
 - Lines of Code: 679
 - Exported Members: 1


**Module Details:**
- **Path:** `Modules\Unity-Claude-EmailNotifications\Unity-Claude-EmailNotifications.psm1`
- **Size:** 27.9 KB
- **Functions:** 7
- **Last Modified:** 2025-08-21 17:45

**Dependencies:** Unity-Claude-PerformanceOptimizer-Original, JobScheduler, Unity-Claude-IncrementalProcessor, Unity-Claude-EmailNotifications-SystemNetMail, Unity-Claude-ParallelProcessor-Original, RunspacePoolManager, Unity-Claude-Cache-Original, StatisticsTracker, ModuleFunctions, Unity-Claude-Cache, Unity-Claude-PerformanceOptimizer-Refactored, Performance-Cache, Unity-Claude-IncrementalProcessor-Fixed, BatchProcessingEngine, Unity-Claude-Cache-Fixed

--- 
### Unity-Claude-EmailNotifications-SystemNetMail

[⬆ Back to Contents](#-table-of-contents)

Unity Editor integration providing direct communication with Unity processes. Monitors compilation, extracts errors, and manages project operations. Email notification module for multi-channel alert delivery. Supports SMTP configuration, templated messages, and escalation chains. 

**Key Capabilities:** resource creation, configuration management, validation and testing, specialized operations, data retrieval 

**Module Statistics:**
 - Functions: 13
 - Lines of Code: 1170
 - Exported Members: 1


**Module Details:**
- **Path:** `Modules\Unity-Claude-EmailNotifications\Unity-Claude-EmailNotifications-SystemNetMail.psm1`
- **Size:** 45.7 KB
- **Functions:** 13
- **Last Modified:** 2025-08-21 17:45

**Dependencies:** Unity-Claude-PerformanceOptimizer-Original, JobScheduler, Unity-Claude-IncrementalProcessor, Unity-Claude-ParallelProcessor-Original, RunspacePoolManager, Unity-Claude-Cache-Original, StatisticsTracker, ModuleFunctions, Unity-Claude-Cache, Unity-Claude-EmailNotifications, Unity-Claude-PerformanceOptimizer-Refactored, Performance-Cache, Unity-Claude-IncrementalProcessor-Fixed, BatchProcessingEngine, Unity-Claude-Cache-Fixed

--- 
### Unity-Claude-ErrorHandling

[⬆ Back to Contents](#-table-of-contents)

Unity Editor integration providing direct communication with Unity processes. Monitors compilation, extracts errors, and manages project operations.

**Key Capabilities:** action execution, resource creation, data retrieval, system initialization

**Module Statistics:**
- Functions: 9
- Lines of Code: 745
- Exported Members: 1


**Module Details:**
- **Path:** `Modules\Unity-Claude-ParallelProcessing\Unity-Claude-ErrorHandling.psm1`
- **Size:** 28.54 KB
- **Functions:** 9
- **Last Modified:** 2025-08-21 17:45

**Dependencies:** Unity-Claude-PerformanceOptimizer-Original, JobScheduler, Unity-Claude-IncrementalProcessor, Unity-Claude-ConcurrentProcessor, Unity-Claude-ParallelProcessor-Original, RunspacePoolManager, Unity-Claude-Cache-Original, StatisticsTracker, ModuleFunctions, Unity-Claude-Cache, Unity-Claude-ParallelProcessing, Unity-Claude-PerformanceOptimizer-Refactored, Performance-Cache, Unity-Claude-IncrementalProcessor-Fixed, Unity-Claude-ConcurrentCollections, ResponseAnalysisEngine-Broken, BatchProcessingEngine, Unity-Claude-MessageQueue, Unity-Claude-AutonomousStateTracker, Unity-Claude-Cache-Fixed, CircuitBreaker, ErrorHandling

--- 
### Unity-Claude-Errors

[⬆ Back to Contents](#-table-of-contents)

Unity Editor integration providing direct communication with Unity processes. Monitors compilation, extracts errors, and manages project operations.

**Key Capabilities:** system initialization, specialized operations, data retrieval

**Module Statistics:**
- Functions: 9
- Lines of Code: 727
- Exported Members: 1


**Module Details:**
- **Path:** `Modules\Unity-Claude-Errors\Unity-Claude-Errors.psm1`
- **Size:** 23.76 KB
- **Functions:** 9
- **Last Modified:** 2025-08-20 17:25

**Dependencies:** CPG-DataStructures, CrossLanguage-DependencyMaps, Unity-Claude-PerformanceOptimizer-Original, Unity-Claude-IncrementalProcessor, CPG-Unified, Unity-Claude-ParallelProcessor-Original, PatternRecognition, Unity-Claude-Cache-Original, Unity-Claude-IPC-Bidirectional-Fixed, ModuleFunctions, Unity-Claude-Cache, Unity-Claude-PerformanceOptimizer-Refactored, Performance-Cache, Unity-Claude-Learning-Original, Unity-Claude-CPG-Original, Unity-Claude-IncrementalProcessor-Fixed, Unity-Claude-Learning-Simple, BatchProcessingEngine, Unity-Claude-Cache-Fixed, Unity-Claude-IPC-Bidirectional

--- 
### Unity-Claude-EventLog

[⬆ Back to Contents](#-table-of-contents)

Unity Editor integration providing direct communication with Unity processes. Monitors compilation, extracts errors, and manages project operations.

**Key Capabilities:** specialized operations

**Module Statistics:**
- Functions: 4
- Lines of Code: 115


**Module Details:**
- **Path:** `Modules\Unity-Claude-EventLog\Unity-Claude-EventLog.psm1`
- **Size:** 4.87 KB
- **Functions:** 3
- **Last Modified:** 2025-08-24 12:06

**Dependencies:** Unity-Claude-Cache-Original, Unity-Claude-Cache, Performance-Cache, Unity-Claude-Cache-Fixed

--- 
### Unity-Claude-FileMonitor

[⬆ Back to Contents](#-table-of-contents)

Unity Editor integration providing direct communication with Unity processes. Monitors compilation, extracts errors, and manages project operations. Real-time monitoring module tracking system health and performance metrics. Provides event-driven notifications and automated issue response. 

**Key Capabilities:** resource creation, process initiation, process termination, specialized operations, data retrieval 

**Module Statistics:**
 - Functions: 15
 - Lines of Code: 650
 - Exported Members: 1


**Module Details:**
- **Path:** `Modules\Unity-Claude-FileMonitor\Unity-Claude-FileMonitor.psm1`
- **Size:** 24.06 KB
- **Functions:** 15
- **Last Modified:** 2025-08-24 12:06

**Dependencies:** CPG-DataStructures, CrossLanguage-DependencyMaps, Unity-Claude-PerformanceOptimizer-Original, JobScheduler, Unity-Claude-IncrementalProcessor, CPG-Unified, Unity-Claude-ParallelProcessor-Original, RunspacePoolManager, Unity-Claude-Cache-Original, StatisticsTracker, ModuleFunctions, Unity-Claude-Cache, Unity-Claude-PerformanceOptimizer-Refactored, Performance-Cache, Unity-Claude-FileMonitor-Fixed, Unity-Claude-CPG-Original, Unity-Claude-IncrementalProcessor-Fixed, BatchProcessingEngine, Unity-Claude-Cache-Fixed

--- 
### Unity-Claude-FileMonitor-Fixed

[⬆ Back to Contents](#-table-of-contents)

Unity Editor integration providing direct communication with Unity processes. Monitors compilation, extracts errors, and manages project operations. Real-time monitoring module tracking system health and performance metrics. Provides event-driven notifications and automated issue response. 

**Key Capabilities:** specialized operations, resource creation, process initiation, data retrieval 

**Module Statistics:**
 - Functions: 17
 - Lines of Code: 735
 - Exported Members: 1


**Module Details:**
- **Path:** `Modules\Unity-Claude-FileMonitor\Unity-Claude-FileMonitor-Fixed.psm1`
- **Size:** 25.9 KB
- **Functions:** 17
- **Last Modified:** 2025-08-24 12:06

**Dependencies:** CPG-DataStructures, CrossLanguage-DependencyMaps, Unity-Claude-PerformanceOptimizer-Original, JobScheduler, Unity-Claude-IncrementalProcessor, CPG-Unified, Unity-Claude-FileMonitor, Unity-Claude-ParallelProcessor-Original, RunspacePoolManager, Unity-Claude-Cache-Original, StatisticsTracker, ModuleFunctions, Unity-Claude-Cache, Unity-Claude-PerformanceOptimizer-Refactored, Performance-Cache, Unity-Claude-CPG-Original, Unity-Claude-IncrementalProcessor-Fixed, BatchProcessingEngine, Unity-Claude-Cache-Fixed

--- 
### Unity-Claude-FixEngine

[⬆ Back to Contents](#-table-of-contents)

Unity Editor integration providing direct communication with Unity processes. Monitors compilation, extracts errors, and manages project operations.

**Key Capabilities:** specialized operations, validation and testing, data retrieval, configuration management, resource creation

**Module Statistics:**
- Functions: 25
- Lines of Code: 1438
- Classes: 1


**Module Details:**
- **Path:** `Modules\Unity-Claude-FixEngine\Unity-Claude-FixEngine.psm1`
- **Size:** 49.76 KB
- **Functions:** 25
- **Last Modified:** 2025-08-20 17:25

**Dependencies:** CPG-DataStructures, CrossLanguage-DependencyMaps, Unity-Claude-PerformanceOptimizer-Original, Unity-Claude-IncrementalProcessor, CPG-Unified, Unity-Claude-ParallelProcessor-Original, RunspacePoolManager, Unity-Claude-Cache-Original, Unity-Claude-Cache, Unity-Claude-PerformanceOptimizer-Refactored, Performance-Cache, Unity-Claude-Learning-Original, Unity-Claude-CPG-Original, Unity-Claude-IncrementalProcessor-Fixed, Unity-Claude-Learning-Simple, Unity-Claude-Safety, Unity-Claude-ResponseMonitor, BatchProcessingEngine, Unity-Claude-DecisionEngine-Original, Unity-Claude-Cache-Fixed, DecisionEngineCore

--- 
### Unity-Claude-GitHub

[⬆ Back to Contents](#-table-of-contents)

GitHub integration module for version control operations. Handles commits, pull requests, issue management, and repository automation. Unity Editor integration providing direct communication with Unity processes. Monitors compilation, extracts errors, and manages project operations. 

**Key Capabilities:** specialized operations 

**Module Statistics:**
 - Functions: 2
 - Lines of Code: 176
 - Exported Members: 1


**Module Details:**
- **Path:** `Modules\Unity-Claude-GitHub\Unity-Claude-GitHub.psm1`
- **Size:** 7.07 KB
- **Functions:** 3
- **Last Modified:** 2025-08-30 23:15

**Dependencies:** Unity-Claude-PerformanceOptimizer-Original, Unity-Claude-IncrementalProcessor, Unity-Claude-ParallelProcessor-Original, Unity-Claude-Cache-Original, Unity-Claude-Cache, Unity-Claude-PerformanceOptimizer-Refactored, Performance-Cache, Unity-Claude-IncrementalProcessor-Fixed, BatchProcessingEngine, Unity-Claude-Cache-Fixed

--- 
### Unity-Claude-GovernanceIntegration

[⬆ Back to Contents](#-table-of-contents)

Unity Editor integration providing direct communication with Unity processes. Monitors compilation, extracts errors, and manages project operations.

**Key Capabilities:** validation and testing, resource creation, specialized operations, data retrieval

**Module Statistics:**
- Functions: 7
- Lines of Code: 583
- Exported Members: 1


**Module Details:**
- **Path:** `Modules\Unity-Claude-HITL\Unity-Claude-GovernanceIntegration.psm1`
- **Size:** 22.24 KB
- **Functions:** 7
- **Last Modified:** 2025-08-24 12:06

**Dependencies:** Unity-Claude-HITL-Original, Unity-Claude-Cache-Original, Unity-Claude-Cache, ApprovalRequests, Performance-Cache, Unity-Claude-Cache-Fixed

--- 
### Unity-Claude-HITL

[⬆ Back to Contents](#-table-of-contents)

Unity Editor integration providing direct communication with Unity processes. Monitors compilation, extracts errors, and manages project operations.

**Key Capabilities:** data retrieval, validation and testing, action execution

**Module Statistics:**
- Functions: 3
- Lines of Code: 425
- Exported Members: 1


**Module Details:**
- **Path:** `Modules\Unity-Claude-HITL\Unity-Claude-HITL.psm1`
- **Size:** 15.55 KB
- **Functions:** 3
- **Last Modified:** 2025-08-26 11:46

**Dependencies:** Unity-Claude-HITL-Original, Unity-Claude-PerformanceOptimizer-Original, Unity-Claude-IncrementalProcessor, Unity-Claude-ParallelProcessor-Original, Unity-Claude-Cache-Original, ModuleFunctions, Unity-Claude-Cache, ApprovalRequests, SecurityTokens, Unity-Claude-PerformanceOptimizer-Refactored, Performance-Cache, Unity-Claude-IncrementalProcessor-Fixed, HITLCore, NotificationSystem, BatchProcessingEngine, CommandExecutionEngine, Unity-Claude-HITL-Refactored, DatabaseManagement, Unity-Claude-Cache-Fixed

--- 
### Unity-Claude-HITL-Original

[⬆ Back to Contents](#-table-of-contents)

Unity Editor integration providing direct communication with Unity processes. Monitors compilation, extracts errors, and manages project operations.

**Key Capabilities:** system initialization, resource creation, validation and testing, specialized operations

**Module Statistics:**
- Functions: 13
- Lines of Code: 946


**Module Details:**
- **Path:** `Modules\Unity-Claude-HITL\Unity-Claude-HITL-Original.psm1`
- **Size:** 32.77 KB
- **Functions:** 13
- **Last Modified:** 2025-08-26 11:46

**Dependencies:** CPG-DataStructures, CrossLanguage-DependencyMaps, Unity-Claude-PerformanceOptimizer-Original, JobScheduler, Unity-Claude-IncrementalProcessor, CPG-Unified, Unity-Claude-EmailNotifications-SystemNetMail, Unity-Claude-ParallelProcessor-Original, RunspacePoolManager, Unity-Claude-Cache-Original, StatisticsTracker, ModuleFunctions, Unity-Claude-Cache, ApprovalRequests, SecurityTokens, Unity-Claude-PerformanceOptimizer-Refactored, Performance-Cache, Unity-Claude-CPG-Original, Unity-Claude-IncrementalProcessor-Fixed, HITLCore, NotificationSystem, BatchProcessingEngine, CommandExecutionEngine, DatabaseManagement, Unity-Claude-Cache-Fixed

--- 
### Unity-Claude-HITL-Refactored

[⬆ Back to Contents](#-table-of-contents)

Unity Editor integration providing direct communication with Unity processes. Monitors compilation, extracts errors, and manages project operations.

**Key Capabilities:** data retrieval, validation and testing, action execution

**Module Statistics:**
- Functions: 3
- Lines of Code: 425
- Exported Members: 1


**Module Details:**
- **Path:** `Modules\Unity-Claude-HITL\Unity-Claude-HITL-Refactored.psm1`
- **Size:** 15.55 KB
- **Functions:** 3
- **Last Modified:** 2025-08-26 11:46

**Dependencies:** Unity-Claude-HITL-Original, Unity-Claude-PerformanceOptimizer-Original, Unity-Claude-IncrementalProcessor, Unity-Claude-ParallelProcessor-Original, Unity-Claude-Cache-Original, ModuleFunctions, Unity-Claude-Cache, ApprovalRequests, Unity-Claude-HITL, SecurityTokens, Unity-Claude-PerformanceOptimizer-Refactored, Performance-Cache, Unity-Claude-IncrementalProcessor-Fixed, HITLCore, NotificationSystem, BatchProcessingEngine, CommandExecutionEngine, DatabaseManagement, Unity-Claude-Cache-Fixed

--- 
### Unity-Claude-IncrementalProcessor

[⬆ Back to Contents](#-table-of-contents)

Unity Editor integration providing direct communication with Unity processes. Monitors compilation, extracts errors, and manages project operations.

**Key Capabilities:** resource creation, process initiation, process termination, data retrieval

**Module Statistics:**
- Functions: 10
- Lines of Code: 813
- Classes: 1
- Exported Members: 1


**Module Details:**
- **Path:** `Modules\Unity-Claude-IncrementalProcessor\Unity-Claude-IncrementalProcessor.psm1`
- **Size:** 28.41 KB
- **Functions:** 34
- **Last Modified:** 2025-08-25 13:45

**Dependencies:** CPG-DataStructures, CrossLanguage-DependencyMaps, Unity-Claude-PerformanceOptimizer-Original, JobScheduler, Performance-IncrementalUpdates, CPG-Unified, Unity-Claude-ParallelProcessor-Original, RunspacePoolManager, Unity-Claude-Cache-Original, StatisticsTracker, ModuleFunctions, Unity-Claude-Cache, Unity-Claude-PerformanceOptimizer-Refactored, Performance-Cache, Unity-Claude-CPG-Original, Unity-Claude-IncrementalProcessor-Fixed, BatchProcessingEngine, Unity-Claude-Cache-Fixed

--- 
### Unity-Claude-IncrementalProcessor-Fixed

[⬆ Back to Contents](#-table-of-contents)

Unity Editor integration providing direct communication with Unity processes. Monitors compilation, extracts errors, and manages project operations.

**Key Capabilities:** resource creation, process initiation, process termination, data retrieval

**Module Statistics:**
- Functions: 10
- Lines of Code: 813
- Classes: 1
- Exported Members: 1


**Module Details:**
- **Path:** `Modules\Unity-Claude-IncrementalProcessor\Unity-Claude-IncrementalProcessor-Fixed.psm1`
- **Size:** 28.41 KB
- **Functions:** 34
- **Last Modified:** 2025-08-25 13:45

**Dependencies:** CPG-DataStructures, CrossLanguage-DependencyMaps, Unity-Claude-PerformanceOptimizer-Original, JobScheduler, Unity-Claude-IncrementalProcessor, Performance-IncrementalUpdates, CPG-Unified, Unity-Claude-ParallelProcessor-Original, RunspacePoolManager, Unity-Claude-Cache-Original, StatisticsTracker, ModuleFunctions, Unity-Claude-Cache, Unity-Claude-PerformanceOptimizer-Refactored, Performance-Cache, Unity-Claude-CPG-Original, BatchProcessingEngine, Unity-Claude-Cache-Fixed

--- 
### Unity-Claude-IntegratedWorkflow

[⬆ Back to Contents](#-table-of-contents)

Unity Editor integration providing direct communication with Unity processes. Monitors compilation, extracts errors, and manages project operations.

**Module Statistics:**
- Functions: 6
- Lines of Code: 190
- Exported Members: 3


**Module Details:**
- **Path:** `Modules\Unity-Claude-IntegratedWorkflow\Unity-Claude-IntegratedWorkflow.psm1`
- **Size:** 9.29 KB
- **Functions:** 0
- **Last Modified:** 2025-08-26 11:46

**Dependencies:** Unity-Claude-UnityParallelization-Original, Unity-Claude-PerformanceOptimizer-Original, Unity-Claude-IncrementalProcessor, WorkflowOrchestration, Unity-Claude-ParallelProcessor-Original, Unity-Claude-Cache-Original, ModuleFunctions, Unity-Claude-Cache, PerformanceAnalysis, RunspaceCore, DependencyManagement, Unity-Claude-PerformanceOptimizer-Refactored, Performance-Cache, Unity-Claude-ClaudeParallelization, Unity-Claude-IncrementalProcessor-Fixed, BatchProcessingEngine, ParallelizationCore, WorkflowMonitoring, Unity-Claude-Cache-Fixed, Unity-Claude-RunspaceManagement-Original, Unity-Claude-IntegratedWorkflow-Original

--- 
### Unity-Claude-IntegratedWorkflow-Original

[⬆ Back to Contents](#-table-of-contents)

Unity Editor integration providing direct communication with Unity processes. Monitors compilation, extracts errors, and manages project operations.

**Key Capabilities:** validation and testing, specialized operations

**Module Statistics:**
- Functions: 16
- Lines of Code: 1723
- Exported Members: 2


**Module Details:**
- **Path:** `Modules\Unity-Claude-IntegratedWorkflow\Unity-Claude-IntegratedWorkflow-Original.psm1`
- **Size:** 82.62 KB
- **Functions:** 13
- **Last Modified:** 2025-08-26 11:46

**Dependencies:** CPG-DataStructures, CrossLanguage-DependencyMaps, Unity-Claude-UnityParallelization-Original, Unity-Claude-PerformanceOptimizer-Original, JobScheduler, Unity-Claude-IncrementalProcessor, CPG-Unified, WorkflowOrchestration, Unity-Claude-ParallelProcessor-Original, RunspacePoolManager, Unity-Claude-Cache-Original, StatisticsTracker, ModuleFunctions, Unity-Claude-Cache, PerformanceAnalysis, RunspaceCore, DependencyManagement, Unity-Claude-PerformanceOptimizer-Refactored, Performance-Cache, ProductionRunspacePool, ModuleVariablePreloading, RunspacePoolManagement, Unity-Claude-CPG-Original, Unity-Claude-ClaudeParallelization, Unity-Claude-IncrementalProcessor-Fixed, SessionStateConfiguration, BatchProcessingEngine, ParallelizationCore, WorkflowMonitoring, Unity-Claude-Cache-Fixed, ParallelMonitoring, Unity-Claude-RunspaceManagement-Original, VariableSharing, ProjectConfiguration

--- 
### Unity-Claude-IntegratedWorkflow-Refactored

[⬆ Back to Contents](#-table-of-contents)

Unity Editor integration providing direct communication with Unity processes. Monitors compilation, extracts errors, and manages project operations.

**Module Statistics:**
- Functions: 6
- Lines of Code: 190
- Exported Members: 3


**Module Details:**
- **Path:** `Modules\Unity-Claude-IntegratedWorkflow\Unity-Claude-IntegratedWorkflow-Refactored.psm1`
- **Size:** 9.29 KB
- **Functions:** 0
- **Last Modified:** 2025-08-26 11:46

**Dependencies:** Unity-Claude-UnityParallelization-Original, Unity-Claude-PerformanceOptimizer-Original, Unity-Claude-IncrementalProcessor, WorkflowOrchestration, Unity-Claude-ParallelProcessor-Original, Unity-Claude-Cache-Original, ModuleFunctions, Unity-Claude-Cache, PerformanceAnalysis, RunspaceCore, DependencyManagement, Unity-Claude-PerformanceOptimizer-Refactored, Performance-Cache, Unity-Claude-ClaudeParallelization, Unity-Claude-IncrementalProcessor-Fixed, BatchProcessingEngine, ParallelizationCore, WorkflowMonitoring, Unity-Claude-Cache-Fixed, Unity-Claude-RunspaceManagement-Original, Unity-Claude-IntegratedWorkflow-Original

--- 
### Unity-Claude-IntegrationEngine

[⬆ Back to Contents](#-table-of-contents)

Unity Editor integration providing direct communication with Unity processes. Monitors compilation, extracts errors, and manages project operations.

**Key Capabilities:** specialized operations, data retrieval, resource creation, system initialization

**Module Statistics:**
- Functions: 20
- Lines of Code: 807
- Exported Members: 1


**Module Details:**
- **Path:** `Modules\Unity-Claude-IntegrationEngine.psm1`
- **Size:** 29.48 KB
- **Functions:** 20
- **Last Modified:** 2025-08-20 17:25

**Dependencies:** CPG-DataStructures, CrossLanguage-DependencyMaps, Unity-Claude-PerformanceOptimizer-Original, Unity-Claude-IncrementalProcessor, Unity-Claude-MasterOrchestrator-Original, SafeExecution, CPG-Unified, Unity-Claude-ParallelProcessor-Original, DecisionEngineIntegration, Unity-Claude-Cache-Original, ModuleFunctions, Unity-Claude-Cache, Unity-Claude-PerformanceOptimizer-Refactored, Performance-Cache, ResultAnalysisEngine, Unity-Claude-CPG-Original, Unity-Claude-IncrementalProcessor-Fixed, PromptTypeSelection, Unity-Claude-ResponseMonitoring, Unity-Claude-ResponseMonitor, ResponseMonitoring, BatchProcessingEngine, AutonomousFeedbackLoop, Unity-Claude-Cache-Fixed, PromptTemplateSystem, Unity-Claude-CLISubmission, CLIAutomation, FileSystemMonitoring

--- 
### Unity-Claude-IntelligentAlerting

[⬆ Back to Contents](#-table-of-contents)

Unity Editor integration providing direct communication with Unity processes. Monitors compilation, extracts errors, and manages project operations. Alert management system for incident detection and notification. Categorizes alerts, manages thresholds, and coordinates response actions. 

**Key Capabilities:** system initialization, specialized operations, process initiation 

**Module Statistics:**
 - Functions: 15
 - Lines of Code: 648
 - Exported Members: 1


**Module Details:**
- **Path:** `Modules\Unity-Claude-IntelligentAlerting\Unity-Claude-IntelligentAlerting.psm1`
- **Size:** 21.6 KB
- **Functions:** 14
- **Last Modified:** 2025-08-30 13:44

**Dependencies:** CPG-DataStructures, CrossLanguage-DependencyMaps, Unity-Claude-PerformanceOptimizer-Original, Unity-Claude-IncrementalProcessor, CPG-Unified, Unity-Claude-ParallelProcessor-Original, RunspacePoolManager, Unity-Claude-Cache-Original, ModuleFunctions, Unity-Claude-Cache, Unity-Claude-PerformanceOptimizer-Refactored, Performance-Cache, Unity-Claude-CPG-Original, Unity-Claude-IncrementalProcessor-Fixed, BatchProcessingEngine, Unity-Claude-Cache-Fixed, Unity-Claude-AIAlertClassifier

--- 
### Unity-Claude-IntelligentDocumentationTriggers

[⬆ Back to Contents](#-table-of-contents)

Documentation automation module providing real-time documentation updates. Generates API docs, maintains cross-references, and ensures documentation accuracy. Unity Editor integration providing direct communication with Unity processes. Monitors compilation, extracts errors, and manages project operations. 

**Key Capabilities:** system initialization, data retrieval, specialized operations 

**Module Statistics:**
 - Functions: 21
 - Lines of Code: 729
 - Exported Members: 2


**Module Details:**
- **Path:** `Modules\Unity-Claude-IntelligentDocumentationTriggers\Unity-Claude-IntelligentDocumentationTriggers.psm1`
- **Size:** 26.53 KB
- **Functions:** 20
- **Last Modified:** 2025-08-30 15:41

**Dependencies:** CPG-DataStructures, CrossLanguage-DependencyMaps, CPG-Unified, Unity-Claude-ParallelProcessor-Original, ImpactAnalysis, TreeSitter-CSTConverter, Unity-Claude-Cache-Original, ModuleFunctions, Unity-Claude-Cache, Performance-Cache, Unity-Claude-Ollama, Unity-Claude-CPG-Original, Unity-Claude-DocumentationDrift, Unity-Claude-Cache-Fixed

--- 
### Unity-Claude-IPC

[⬆ Back to Contents](#-table-of-contents)

Unity Editor integration providing direct communication with Unity processes. Monitors compilation, extracts errors, and manages project operations.

**Key Capabilities:** validation and testing, action execution, specialized operations, process initiation

**Module Statistics:**
- Functions: 9
- Lines of Code: 475
- Exported Members: 1


**Module Details:**
- **Path:** `Modules\Unity-Claude-IPC\Unity-Claude-IPC.psm1`
- **Size:** 14.76 KB
- **Functions:** 9
- **Last Modified:** 2025-08-20 17:25

**Dependencies:** CPG-DataStructures, CrossLanguage-DependencyMaps, Unity-Claude-PerformanceOptimizer-Original, Unity-Claude-IncrementalProcessor, CPG-Unified, Unity-Claude-ParallelProcessor-Original, Unity-Claude-Cache-Original, Unity-Claude-IPC-Bidirectional-Fixed, Unity-Claude-Cache, Unity-Claude-PerformanceOptimizer-Refactored, Performance-Cache, Unity-Claude-CPG-Original, Unity-Claude-IncrementalProcessor-Fixed, BatchProcessingEngine, Unity-Claude-Cache-Fixed, Unity-Claude-IPC-Bidirectional

--- 
### Unity-Claude-IPC-Bidirectional

[⬆ Back to Contents](#-table-of-contents)

Unity Editor integration providing direct communication with Unity processes. Monitors compilation, extracts errors, and manages project operations.

**Key Capabilities:** specialized operations, process initiation

**Module Statistics:**
- Functions: 12
- Lines of Code: 680
- Exported Members: 1


**Module Details:**
- **Path:** `Modules\Unity-Claude-IPC-Bidirectional\Unity-Claude-IPC-Bidirectional.psm1`
- **Size:** 20.33 KB
- **Functions:** 12
- **Last Modified:** 2025-08-20 17:25

**Dependencies:** Unity-Claude-PerformanceOptimizer-Original, JobScheduler, Unity-Claude-IncrementalProcessor, BackgroundJobQueue, Unity-Claude-ParallelProcessor-Original, RunspacePoolManager, Unity-Claude-Cache-Original, Unity-Claude-IPC-Bidirectional-Fixed, StatisticsTracker, ModuleFunctions, Unity-Claude-Cache, Unity-Claude-PerformanceOptimizer-Refactored, Performance-Cache, QueueManagement, Unity-Claude-IncrementalProcessor-Fixed, BatchProcessingEngine, CommandExecutionEngine, Unity-Claude-MessageQueue, Unity-Claude-ScalabilityEnhancements-Original, Unity-Claude-Cache-Fixed

--- 
### Unity-Claude-IPC-Bidirectional-Fixed

[⬆ Back to Contents](#-table-of-contents)

Unity Editor integration providing direct communication with Unity processes. Monitors compilation, extracts errors, and manages project operations.

**Key Capabilities:** specialized operations, process initiation

**Module Statistics:**
- Functions: 12
- Lines of Code: 680
- Exported Members: 1


**Module Details:**
- **Path:** `Modules\Unity-Claude-IPC-Bidirectional\Unity-Claude-IPC-Bidirectional-Fixed.psm1`
- **Size:** 20.33 KB
- **Functions:** 12
- **Last Modified:** 2025-08-20 17:25

**Dependencies:** Unity-Claude-PerformanceOptimizer-Original, JobScheduler, Unity-Claude-IncrementalProcessor, BackgroundJobQueue, Unity-Claude-ParallelProcessor-Original, RunspacePoolManager, Unity-Claude-Cache-Original, StatisticsTracker, ModuleFunctions, Unity-Claude-Cache, Unity-Claude-PerformanceOptimizer-Refactored, Performance-Cache, QueueManagement, Unity-Claude-IncrementalProcessor-Fixed, BatchProcessingEngine, CommandExecutionEngine, Unity-Claude-MessageQueue, Unity-Claude-ScalabilityEnhancements-Original, Unity-Claude-Cache-Fixed, Unity-Claude-IPC-Bidirectional

--- 
### Unity-Claude-LangGraphBridge

[⬆ Back to Contents](#-table-of-contents)

Unity Editor integration providing direct communication with Unity processes. Monitors compilation, extracts errors, and manages project operations.

**Key Capabilities:** resource creation, request processing, data retrieval, validation and testing

**Module Statistics:**
- Functions: 8
- Lines of Code: 414
- Exported Members: 1


**Module Details:**
- **Path:** `Modules\Unity-Claude-AI-Integration\LangGraph\Unity-Claude-LangGraphBridge.psm1`
- **Size:** 11.73 KB
- **Functions:** 8
- **Last Modified:** 2025-08-29 15:17

**Dependencies:** Unity-Claude-PerformanceOptimizer-Original, Unity-Claude-IncrementalProcessor, Unity-Claude-ParallelProcessor-Original, Unity-Claude-Cache-Original, Unity-Claude-Cache, Unity-Claude-PerformanceOptimizer-Refactored, Performance-Cache, Unity-Claude-IncrementalProcessor-Fixed, BatchProcessingEngine, Unity-Claude-Cache-Fixed

--- 
### Unity-Claude-Learning

[⬆ Back to Contents](#-table-of-contents)

Unity Editor integration providing direct communication with Unity processes. Monitors compilation, extracts errors, and manages project operations. Machine learning module that adapts system behavior based on historical data. Implements online learning, model updates, and performance optimization. 

**Module Statistics:**
 - Functions: 1
 - Lines of Code: 172
 - Exported Members: 1


**Module Details:**
- **Path:** `Modules\Unity-Claude-Learning\Unity-Claude-Learning.psm1`
- **Size:** 7.32 KB
- **Functions:** 0
- **Last Modified:** 2025-08-26 11:46

**Dependencies:** CrossLanguage-DependencyMaps, Unity-Claude-PerformanceOptimizer-Original, Unity-Claude-IncrementalProcessor, EntityContextEngine, Unity-Claude-ParallelProcessor-Original, PatternRecognition, Unity-Claude-Errors, DecisionEngine-Bayesian, Unity-Claude-Cache-Original, ModuleFunctions, Unity-Claude-Cache, Unity-Claude-CrossLanguage, SelfPatching, Unity-Claude-PerformanceOptimizer-Refactored, Performance-Cache, ErrorDetection, Unity-Claude-Learning-Original, CrossLanguage-GraphMerger, Unity-Claude-IncrementalProcessor-Fixed, Unity-Claude-Learning-Simple, ASTAnalysis, BatchProcessingEngine, StringSimilarity, CodeRedundancyDetection, UnityIntegration, Unity-Claude-Cache-Fixed, Unity-Claude-AIAlertClassifier, PatternAnalysis

--- 
### Unity-Claude-Learning-Analytics

[⬆ Back to Contents](#-table-of-contents)

Unity Editor integration providing direct communication with Unity processes. Monitors compilation, extracts errors, and manages project operations. Machine learning module that adapts system behavior based on historical data. Implements online learning, model updates, and performance optimization. 

**Key Capabilities:** data retrieval, specialized operations 

**Module Statistics:**
 - Functions: 8
 - Lines of Code: 688
 - Exported Members: 1


**Module Details:**
- **Path:** `Modules\Unity-Claude-Learning\Unity-Claude-Learning-Analytics.psm1`
- **Size:** 24.52 KB
- **Functions:** 8
- **Last Modified:** 2025-08-20 17:25

**Dependencies:** CPG-DataStructures, CrossLanguage-DependencyMaps, CPG-Unified, PatternRecognition, Unity-Claude-Cache-Original, Unity-Claude-Cache, Performance-Cache, Unity-Claude-Learning-Original, Unity-Claude-CPG-Original, Unity-Claude-Learning-Simple, Unity-Claude-Cache-Fixed

--- 
### Unity-Claude-Learning-Original

[⬆ Back to Contents](#-table-of-contents)

Unity Editor integration providing direct communication with Unity processes. Monitors compilation, extracts errors, and manages project operations. Machine learning module that adapts system behavior based on historical data. Implements online learning, model updates, and performance optimization. 

**Key Capabilities:** system initialization, data retrieval, specialized operations 

**Module Statistics:**
 - Functions: 27
 - Lines of Code: 2294
 - Exported Members: 1


**Module Details:**
- **Path:** `Modules\Unity-Claude-Learning\Unity-Claude-Learning-Original.psm1`
- **Size:** 79.5 KB
- **Functions:** 26
- **Last Modified:** 2025-08-26 11:46

**Dependencies:** CPG-DataStructures, CrossLanguage-DependencyMaps, Unity-Claude-PerformanceOptimizer-Original, JobScheduler, Unity-Claude-IncrementalProcessor, Performance-IncrementalUpdates, CPG-Unified, EntityContextEngine, Unity-Claude-ParallelProcessor-Original, PatternRecognition, Unity-Claude-Errors, DecisionEngine-Bayesian, RunspacePoolManager, Unity-Claude-Cache-Original, StatisticsTracker, ModuleFunctions, Unity-Claude-Cache, Unity-Claude-CrossLanguage, SelfPatching, Unity-Claude-PerformanceOptimizer-Refactored, Performance-Cache, ErrorDetection, CrossLanguage-GraphMerger, Unity-Claude-CPG-Original, Unity-Claude-IncrementalProcessor-Fixed, Unity-Claude-Learning-Simple, ASTAnalysis, BatchProcessingEngine, StringSimilarity, CodeRedundancyDetection, UnityIntegration, Unity-Claude-Cache-Fixed, Unity-Claude-AIAlertClassifier, PatternAnalysis

--- 
### Unity-Claude-Learning-Refactored

[⬆ Back to Contents](#-table-of-contents)

Unity Editor integration providing direct communication with Unity processes. Monitors compilation, extracts errors, and manages project operations. Machine learning module that adapts system behavior based on historical data. Implements online learning, model updates, and performance optimization. 

**Module Statistics:**
 - Functions: 1
 - Lines of Code: 172
 - Exported Members: 1


**Module Details:**
- **Path:** `Modules\Unity-Claude-Learning\Unity-Claude-Learning-Refactored.psm1`
- **Size:** 7.32 KB
- **Functions:** 0
- **Last Modified:** 2025-08-26 11:46

**Dependencies:** CrossLanguage-DependencyMaps, Unity-Claude-PerformanceOptimizer-Original, Unity-Claude-IncrementalProcessor, EntityContextEngine, Unity-Claude-ParallelProcessor-Original, PatternRecognition, Unity-Claude-Errors, DecisionEngine-Bayesian, Unity-Claude-Cache-Original, ModuleFunctions, Unity-Claude-Cache, Unity-Claude-CrossLanguage, SelfPatching, Unity-Claude-PerformanceOptimizer-Refactored, Performance-Cache, ErrorDetection, Unity-Claude-Learning-Original, CrossLanguage-GraphMerger, Unity-Claude-IncrementalProcessor-Fixed, Unity-Claude-Learning-Simple, ASTAnalysis, BatchProcessingEngine, StringSimilarity, CodeRedundancyDetection, UnityIntegration, Unity-Claude-Cache-Fixed, Unity-Claude-AIAlertClassifier, PatternAnalysis

--- 
### Unity-Claude-Learning-Simple

[⬆ Back to Contents](#-table-of-contents)

Unity Editor integration providing direct communication with Unity processes. Monitors compilation, extracts errors, and manages project operations. Machine learning module that adapts system behavior based on historical data. Implements online learning, model updates, and performance optimization. 

**Key Capabilities:** specialized operations, system initialization 

**Module Statistics:**
 - Functions: 29
 - Lines of Code: 1739
 - Exported Members: 1


**Module Details:**
- **Path:** `Modules\Unity-Claude-Learning-Simple\Unity-Claude-Learning-Simple.psm1`
- **Size:** 53.76 KB
- **Functions:** 25
- **Last Modified:** 2025-08-20 17:25

**Dependencies:** CPG-DataStructures, CrossLanguage-DependencyMaps, CPG-Unified, EntityContextEngine, Unity-Claude-ParallelProcessor-Original, TreeSitter-CSTConverter, PatternRecognition, Unity-Claude-Errors, DecisionEngine-Bayesian, Unity-Claude-Cache-Original, ModuleFunctions, Unity-Claude-Cache, Unity-Claude-CrossLanguage, SelfPatching, Performance-Cache, ErrorDetection, Unity-Claude-Learning-Original, CrossLanguage-GraphMerger, Unity-Claude-CPG-Original, ASTAnalysis, StringSimilarity, CodeRedundancyDetection, UnityIntegration, Unity-Claude-Cache-Fixed, Unity-Claude-AIAlertClassifier, PatternAnalysis

--- 
### Unity-Claude-LLM

[⬆ Back to Contents](#-table-of-contents)

Unity Editor integration providing direct communication with Unity processes. Monitors compilation, extracts errors, and manages project operations.

**Key Capabilities:** validation and testing, data retrieval, action execution, resource creation

**Module Statistics:**
- Functions: 10
- Lines of Code: 522
- Exported Members: 1


**Module Details:**
- **Path:** `Modules\Unity-Claude-LLM\Unity-Claude-LLM.psm1`
- **Size:** 16 KB
- **Functions:** 10
- **Last Modified:** 2025-08-30 19:47

**Dependencies:** AutoGenerationTriggers, Unity-Claude-Cache-Original, Unity-Claude-Cache, Unity-Claude-TriggerManager, Performance-Cache, Unity-Claude-ChangeIntelligence, Unity-Claude-Cache-Fixed

--- 
### Unity-Claude-MachineLearning

[⬆ Back to Contents](#-table-of-contents)

Unity Editor integration providing direct communication with Unity processes. Monitors compilation, extracts errors, and manages project operations. Machine learning module that adapts system behavior based on historical data. Implements online learning, model updates, and performance optimization. 

**Key Capabilities:** system initialization, data retrieval, specialized operations 

**Module Statistics:**
 - Functions: 25
 - Lines of Code: 1428
 - Exported Members: 1


**Module Details:**
- **Path:** `Modules\Unity-Claude-MachineLearning\Unity-Claude-MachineLearning.psm1`
- **Size:** 53.6 KB
- **Functions:** 25
- **Last Modified:** 2025-08-30 20:27

**Dependencies:** Unity-Claude-PerformanceOptimizer-Original, Unity-Claude-IncrementalProcessor, Unity-Claude-ParallelProcessor-Original, Unity-Claude-Cache-Original, ModuleFunctions, Unity-Claude-Cache, Predictive-Maintenance, MaintenancePrediction, Unity-Claude-PredictiveAnalysis-Original, Unity-Claude-PerformanceOptimizer-Refactored, Performance-Cache, Unity-Claude-IncrementalProcessor-Fixed, BatchProcessingEngine, Unity-Claude-Cache-Fixed

--- 
### Unity-Claude-MasterOrchestrator

[⬆ Back to Contents](#-table-of-contents)

Master orchestration module coordinating complex multi-step workflows. Manages module interactions, handles state transitions, and ensures proper sequencing of automated operations. Unity Editor integration providing direct communication with Unity processes. Monitors compilation, extracts errors, and manages project operations. 

**Key Capabilities:** system initialization, data retrieval, validation and testing 

**Module Statistics:**
 - Functions: 3
 - Lines of Code: 299
 - Exported Members: 1


**Module Details:**
- **Path:** `Modules\Unity-Claude-MasterOrchestrator\Unity-Claude-MasterOrchestrator.psm1`
- **Size:** 11.45 KB
- **Functions:** 3
- **Last Modified:** 2025-08-26 11:46

**Dependencies:** Unity-Claude-PerformanceOptimizer-Original, Unity-Claude-IncrementalProcessor, Unity-Claude-MasterOrchestrator-Original, DecisionExecution, Unity-Claude-ParallelProcessor-Original, ModuleIntegration, Unity-Claude-Cache-Original, ModuleFunctions, Unity-Claude-Cache, Unity-Claude-CLIOrchestrator-Fixed-Simple, DecisionExecution-Fixed, DependencyManagement, Unity-Claude-PerformanceOptimizer-Refactored, Performance-Cache, Unity-Claude-IncrementalProcessor-Fixed, OrchestratorManagement, Unity-Claude-IntegrationEngine, BatchProcessingEngine, OrchestratorCore, EventProcessing, AutonomousFeedbackLoop, Unity-Claude-MasterOrchestrator-Refactored, Unity-Claude-Cache-Fixed, Unity-Claude-CLIOrchestrator-Original, Unity-Claude-IntegratedWorkflow-Original, Unity-Claude-CLISubmission

--- 
### Unity-Claude-MasterOrchestrator-Original

[⬆ Back to Contents](#-table-of-contents)

Master orchestration module coordinating complex multi-step workflows. Manages module interactions, handles state transitions, and ensures proper sequencing of automated operations. Unity Editor integration providing direct communication with Unity processes. Monitors compilation, extracts errors, and manages project operations. 

**Key Capabilities:** specialized operations, validation and testing, system initialization, data retrieval 

**Module Statistics:**
 - Functions: 38
 - Lines of Code: 1293


**Module Details:**
- **Path:** `Modules\Unity-Claude-MasterOrchestrator\Unity-Claude-MasterOrchestrator-Original.psm1`
- **Size:** 46.06 KB
- **Functions:** 34
- **Last Modified:** 2025-08-26 11:46

**Dependencies:** CPG-DataStructures, CrossLanguage-DependencyMaps, Unity-Claude-PerformanceOptimizer-Original, Unity-Claude-IncrementalProcessor, CPG-Unified, DecisionExecution, Unity-Claude-ParallelProcessor-Original, ModuleIntegration, Unity-Claude-Cache-Original, ModuleFunctions, Unity-Claude-Cache, Unity-Claude-CLIOrchestrator-Fixed-Simple, DecisionExecution-Fixed, Unity-Claude-PerformanceOptimizer-Refactored, Unity-Claude-TriggerManager, Unity-Claude-RealTimeMonitoring, Performance-Cache, ResponseAnalysis, Unity-Claude-CPG-Original, Unity-Claude-IncrementalProcessor-Fixed, OrchestratorManagement, Unity-Claude-IntegrationEngine, Unity-Claude-ResponseMonitoring, Unity-Claude-ResponseMonitor, BatchProcessingEngine, OrchestratorCore, Unity-Claude-DecisionEngine-Original, EventProcessing, Unity-Claude-FixEngine, AutonomousFeedbackLoop, Unity-Claude-Cache-Fixed, Unity-Claude-CLIOrchestrator-Original, Unity-Claude-CLISubmission, FileSystemMonitoring

--- 
### Unity-Claude-MasterOrchestrator-Refactored

[⬆ Back to Contents](#-table-of-contents)

Master orchestration module coordinating complex multi-step workflows. Manages module interactions, handles state transitions, and ensures proper sequencing of automated operations. Unity Editor integration providing direct communication with Unity processes. Monitors compilation, extracts errors, and manages project operations. 

**Key Capabilities:** system initialization, data retrieval, validation and testing 

**Module Statistics:**
 - Functions: 3
 - Lines of Code: 299
 - Exported Members: 1


**Module Details:**
- **Path:** `Modules\Unity-Claude-MasterOrchestrator\Unity-Claude-MasterOrchestrator-Refactored.psm1`
- **Size:** 11.45 KB
- **Functions:** 3
- **Last Modified:** 2025-08-26 11:46

**Dependencies:** Unity-Claude-MasterOrchestrator, Unity-Claude-PerformanceOptimizer-Original, Unity-Claude-IncrementalProcessor, Unity-Claude-MasterOrchestrator-Original, DecisionExecution, Unity-Claude-ParallelProcessor-Original, ModuleIntegration, Unity-Claude-Cache-Original, ModuleFunctions, Unity-Claude-Cache, Unity-Claude-CLIOrchestrator-Fixed-Simple, DecisionExecution-Fixed, DependencyManagement, Unity-Claude-PerformanceOptimizer-Refactored, Performance-Cache, Unity-Claude-IncrementalProcessor-Fixed, OrchestratorManagement, Unity-Claude-IntegrationEngine, BatchProcessingEngine, OrchestratorCore, EventProcessing, AutonomousFeedbackLoop, Unity-Claude-Cache-Fixed, Unity-Claude-CLIOrchestrator-Original, Unity-Claude-IntegratedWorkflow-Original, Unity-Claude-CLISubmission

--- 
### Unity-Claude-MemoryAnalysis

[⬆ Back to Contents](#-table-of-contents)

Unity Editor integration providing direct communication with Unity processes. Monitors compilation, extracts errors, and manages project operations.

**Key Capabilities:** process initiation, specialized operations, data retrieval

**Module Statistics:**
- Functions: 6
- Lines of Code: 368
- Exported Members: 1


**Module Details:**
- **Path:** `Modules\Unity-Claude-MemoryAnalysis.psm1`
- **Size:** 16.55 KB
- **Functions:** 6
- **Last Modified:** 2025-08-20 17:25

**Dependencies:** CPG-DataStructures, CrossLanguage-DependencyMaps, Unity-Claude-PerformanceOptimizer-Original, Unity-Claude-IncrementalProcessor, CPG-Unified, Unity-Claude-ParallelProcessor-Original, Unity-Claude-Cache-Original, Unity-Claude-Cache, Unity-Claude-PerformanceOptimizer-Refactored, Performance-Cache, Unity-Claude-CPG-Original, Unity-Claude-IncrementalProcessor-Fixed, BatchProcessingEngine, Unity-Claude-Cache-Fixed

--- 
### Unity-Claude-MessageQueue

[⬆ Back to Contents](#-table-of-contents)

Unity Editor integration providing direct communication with Unity processes. Monitors compilation, extracts errors, and manages project operations.

**Key Capabilities:** system initialization, specialized operations, data retrieval

**Module Statistics:**
- Functions: 10
- Lines of Code: 524
- Exported Members: 1


**Module Details:**
- **Path:** `Modules\Unity-Claude-MessageQueue\Unity-Claude-MessageQueue.psm1`
- **Size:** 18.19 KB
- **Functions:** 10
- **Last Modified:** 2025-08-24 12:06

**Dependencies:** CPG-DataStructures, CrossLanguage-DependencyMaps, Unity-Claude-PerformanceOptimizer-Original, JobScheduler, Unity-Claude-IncrementalProcessor, CPG-Unified, Unity-Claude-ParallelProcessor-Original, RunspacePoolManager, Unity-Claude-Cache-Original, Unity-Claude-IPC-Bidirectional-Fixed, StatisticsTracker, ModuleFunctions, Unity-Claude-Cache, Unity-Claude-PerformanceOptimizer-Refactored, Performance-Cache, Unity-Claude-CPG-Original, Unity-Claude-IncrementalProcessor-Fixed, Unity-Claude-ErrorHandling, BatchProcessingEngine, Unity-Claude-Cache-Fixed, CircuitBreaker, Unity-Claude-IPC-Bidirectional

--- 
### Unity-Claude-Monitoring

[⬆ Back to Contents](#-table-of-contents)

Unity Editor integration providing direct communication with Unity processes. Monitors compilation, extracts errors, and manages project operations. Real-time monitoring module tracking system health and performance metrics. Provides event-driven notifications and automated issue response. 

**Key Capabilities:** data retrieval, validation and testing 

**Module Statistics:**
 - Functions: 12
 - Lines of Code: 701
 - Exported Members: 1


**Module Details:**
- **Path:** `Modules\Unity-Claude-Monitoring\Unity-Claude-Monitoring.psm1`
- **Size:** 20.05 KB
- **Functions:** 12
- **Last Modified:** 2025-08-24 12:06

**Dependencies:** CPG-DataStructures, CrossLanguage-DependencyMaps, Unity-Claude-PerformanceOptimizer-Original, Unity-Claude-IncrementalProcessor, CPG-Unified, Unity-Claude-ParallelProcessor-Original, Unity-Claude-Cache-Original, Unity-Claude-Cache, Unity-Claude-PerformanceOptimizer-Refactored, Performance-Cache, Unity-Claude-CPG-Original, Unity-Claude-IncrementalProcessor-Fixed, BatchProcessingEngine, Unity-Claude-Cache-Fixed

--- 
### Unity-Claude-MultiStepOrchestrator

[⬆ Back to Contents](#-table-of-contents)

Master orchestration module coordinating complex multi-step workflows. Manages module interactions, handles state transitions, and ensures proper sequencing of automated operations. Unity Editor integration providing direct communication with Unity processes. Monitors compilation, extracts errors, and manages project operations. 

**Key Capabilities:** action execution, system initialization, specialized operations 

**Module Statistics:**
 - Functions: 12
 - Lines of Code: 753
 - Exported Members: 1


**Module Details:**
- **Path:** `Modules\Unity-Claude-AI-Integration\LangGraph\Unity-Claude-MultiStepOrchestrator.psm1`
- **Size:** 30.34 KB
- **Functions:** 12
- **Last Modified:** 2025-08-29 15:48

**Dependencies:** CPG-DataStructures, CrossLanguage-DependencyMaps, Unity-Claude-PerformanceOptimizer-Original, Unity-Claude-IncrementalProcessor, CPG-Unified, Unity-Claude-ParallelProcessor-Original, Unity-Claude-Cache-Original, ModuleFunctions, Unity-Claude-Cache, Predictive-Maintenance, MaintenancePrediction, Unity-Claude-PredictiveAnalysis-Original, Predictive-Evolution, Unity-Claude-PerformanceOptimizer-Refactored, Performance-Cache, Unity-Claude-CPG-Original, Unity-Claude-IncrementalProcessor-Fixed, BatchProcessingEngine, DecisionEngine, PerformanceOptimizer, Unity-Claude-MachineLearning, Unity-Claude-ScalabilityOptimizer, FallbackStrategies, Unity-Claude-Cache-Fixed

--- 
### Unity-Claude-NotificationConfiguration

[⬆ Back to Contents](#-table-of-contents)

Unity Editor integration providing direct communication with Unity processes. Monitors compilation, extracts errors, and manages project operations.

**Module Statistics:**
- Functions: 0
- Lines of Code: 97
- Exported Members: 1


**Module Details:**
- **Path:** `Modules\Unity-Claude-NotificationConfiguration\Unity-Claude-NotificationConfiguration.psm1`
- **Size:** 4.43 KB
- **Functions:** 0
- **Last Modified:** 2025-08-24 12:06

**Dependencies:** Unity-Claude-PerformanceOptimizer-Original, Unity-Claude-IncrementalProcessor, Unity-Claude-ParallelProcessor-Original, Unity-Claude-Cache-Original, ModuleFunctions, Unity-Claude-Cache, Unity-Claude-PerformanceOptimizer-Refactored, Performance-Cache, Unity-Claude-IncrementalProcessor-Fixed, BatchProcessingEngine, Unity-Claude-Cache-Fixed

--- 
### Unity-Claude-NotificationContentEngine

[⬆ Back to Contents](#-table-of-contents)

Unity Editor integration providing direct communication with Unity processes. Monitors compilation, extracts errors, and manages project operations.

**Key Capabilities:** resource creation, configuration management, data retrieval, validation and testing, cleanup operations

**Module Statistics:**
- Functions: 37
- Lines of Code: 1701
- Exported Members: 1


**Module Details:**
- **Path:** `Modules\Unity-Claude-NotificationContentEngine\Unity-Claude-NotificationContentEngine.psm1`
- **Size:** 50.83 KB
- **Functions:** 35
- **Last Modified:** 2025-08-21 17:45

**Dependencies:** CPG-DataStructures, CrossLanguage-DependencyMaps, Unity-Claude-PerformanceOptimizer-Original, Unity-Claude-IncrementalProcessor, CPG-Unified, Unity-Claude-EmailNotifications-SystemNetMail, Unity-Claude-ParallelProcessor-Original, Unity-Claude-Cache-Original, ModuleFunctions, Unity-Claude-Cache, Unity-Claude-PerformanceOptimizer-Refactored, Performance-Cache, Unity-Claude-CPG-Original, Unity-Claude-IncrementalProcessor-Fixed, BatchProcessingEngine, Unity-Claude-Cache-Fixed, Unity-Claude-WebhookNotifications

--- 
### Unity-Claude-NotificationIntegration

[⬆ Back to Contents](#-table-of-contents)

Unity Editor integration providing direct communication with Unity processes. Monitors compilation, extracts errors, and manages project operations.

**Key Capabilities:** specialized operations, data retrieval, resource creation

**Module Statistics:**
- Functions: 22
- Lines of Code: 1374
- Exported Members: 1


**Module Details:**
- **Path:** `Modules\Unity-Claude-NotificationIntegration\Unity-Claude-NotificationIntegration.psm1`
- **Size:** 47.5 KB
- **Functions:** 20
- **Last Modified:** 2025-08-30 14:29

**Dependencies:** CPG-DataStructures, CrossLanguage-DependencyMaps, Unity-Claude-PerformanceOptimizer-Original, Unity-Claude-IncrementalProcessor, CPG-Unified, Unity-Claude-EmailNotifications-SystemNetMail, Unity-Claude-ParallelProcessor-Original, Unity-Claude-Cache-Original, ModuleFunctions, Unity-Claude-Cache, ConfigurationManagement, IntegratedNotifications, Unity-Claude-PerformanceOptimizer-Refactored, Performance-Cache, Unity-Claude-CPG-Original, Unity-Claude-IncrementalProcessor-Fixed, ResponseAnalysisEngine-Broken, Unity-Claude-ErrorHandling, BatchProcessingEngine, Unity-Claude-NotificationPreferences, NotificationCore, Unity-Claude-AutonomousStateTracker, Unity-Claude-Cache-Fixed, CircuitBreaker, ErrorHandling, Unity-Claude-WebhookNotifications

--- 
### Unity-Claude-NotificationIntegration-Modular

[⬆ Back to Contents](#-table-of-contents)

Unity Editor integration providing direct communication with Unity processes. Monitors compilation, extracts errors, and manages project operations.

**Key Capabilities:** data retrieval, configuration management, specialized operations

**Module Statistics:**
- Functions: 3
- Lines of Code: 328
- Exported Members: 1


**Module Details:**
- **Path:** `Modules\Unity-Claude-NotificationIntegration\Unity-Claude-NotificationIntegration-Modular.psm1`
- **Size:** 13.61 KB
- **Functions:** 3
- **Last Modified:** 2025-08-21 17:45

**Dependencies:** Unity-Claude-NotificationIntegration, BackgroundJobQueue, Unity-Claude-ParallelProcessor-Original, RunspacePoolManager, Unity-Claude-Cache-Original, Unity-Claude-IPC-Bidirectional-Fixed, ModuleFunctions, Unity-Claude-Cache, ConfigurationManagement, IntegratedNotifications, MetricsAndHealthCheck, Performance-Cache, ContextManagement, QueueManagement, RetryLogic, CommandExecutionEngine, NotificationCore, Unity-Claude-ScalabilityEnhancements-Original, WorkflowIntegration, FallbackMechanisms, Unity-Claude-Cache-Fixed, Unity-Claude-IPC-Bidirectional

--- 
### Unity-Claude-NotificationPreferences

[⬆ Back to Contents](#-table-of-contents)

Unity Editor integration providing direct communication with Unity processes. Monitors compilation, extracts errors, and manages project operations.

**Key Capabilities:** system initialization, specialized operations, data retrieval

**Module Statistics:**
- Functions: 24
- Lines of Code: 1095
- Exported Members: 1


**Module Details:**
- **Path:** `Modules\Unity-Claude-NotificationPreferences\Unity-Claude-NotificationPreferences.psm1`
- **Size:** 37.57 KB
- **Functions:** 24
- **Last Modified:** 2025-08-30 14:35

**Dependencies:** CPG-DataStructures, CrossLanguage-DependencyMaps, Unity-Claude-PerformanceOptimizer-Original, Unity-Claude-NotificationIntegration, Unity-Claude-IncrementalProcessor, CPG-Unified, Unity-Claude-ParallelProcessor-Original, Unity-Claude-Cache-Original, ModuleFunctions, Unity-Claude-Cache, Unity-Claude-PerformanceOptimizer-Refactored, Performance-Cache, Unity-Claude-CPG-Original, Unity-Claude-IncrementalProcessor-Fixed, BatchProcessingEngine, Unity-Claude-Cache-Fixed

--- 
### Unity-Claude-ObsolescenceDetection

[⬆ Back to Contents](#-table-of-contents)

Unity Editor integration providing direct communication with Unity processes. Monitors compilation, extracts errors, and manages project operations.

**Key Capabilities:** data retrieval, validation and testing, action execution, specialized operations

**Module Statistics:**
- Functions: 6
- Lines of Code: 584
- Exported Members: 1


**Module Details:**
- **Path:** `Modules\Unity-Claude-CPG\Unity-Claude-ObsolescenceDetection.psm1`
- **Size:** 22.22 KB
- **Functions:** 5
- **Last Modified:** 2025-08-26 11:46

**Dependencies:** DocumentationComparison, Unity-Claude-PerformanceOptimizer-Original, Unity-Claude-IncrementalProcessor, Unity-Claude-ObsolescenceDetection-Refactored, Unity-Claude-ParallelProcessor-Original, Unity-Claude-Cache-Original, Unity-Claude-Cache, Unity-Claude-PerformanceOptimizer-Refactored, Performance-Cache, Unity-Claude-IncrementalProcessor-Fixed, GraphTraversal, CodeComplexityMetrics, BatchProcessingEngine, CodeRedundancyDetection, DocumentationAccuracy, Unity-Claude-Cache-Fixed, DepaAlgorithm

--- 
### Unity-Claude-ObsolescenceDetection-Refactored

[⬆ Back to Contents](#-table-of-contents)

Unity Editor integration providing direct communication with Unity processes. Monitors compilation, extracts errors, and manages project operations.

**Key Capabilities:** data retrieval, validation and testing, action execution, specialized operations

**Module Statistics:**
- Functions: 6
- Lines of Code: 584
- Exported Members: 1


**Module Details:**
- **Path:** `Modules\Unity-Claude-CPG\Unity-Claude-ObsolescenceDetection-Refactored.psm1`
- **Size:** 22.22 KB
- **Functions:** 5
- **Last Modified:** 2025-08-26 11:46

**Dependencies:** DocumentationComparison, Unity-Claude-PerformanceOptimizer-Original, Unity-Claude-IncrementalProcessor, Unity-Claude-ParallelProcessor-Original, Unity-Claude-Cache-Original, Unity-Claude-ObsolescenceDetection, Unity-Claude-Cache, Unity-Claude-PerformanceOptimizer-Refactored, Performance-Cache, Unity-Claude-IncrementalProcessor-Fixed, GraphTraversal, CodeComplexityMetrics, BatchProcessingEngine, CodeRedundancyDetection, DocumentationAccuracy, Unity-Claude-Cache-Fixed, DepaAlgorithm

--- 
### Unity-Claude-Ollama

[⬆ Back to Contents](#-table-of-contents)

Unity Editor integration providing direct communication with Unity processes. Monitors compilation, extracts errors, and manages project operations.

**Key Capabilities:** process initiation, process termination, validation and testing, data retrieval, configuration management

**Module Statistics:**
- Functions: 15
- Lines of Code: 970
- Exported Members: 1


**Module Details:**
- **Path:** `Modules\Unity-Claude-AI-Integration\Ollama\Unity-Claude-Ollama.psm1`
- **Size:** 34.17 KB
- **Functions:** 13
- **Last Modified:** 2025-08-30 19:47

**Dependencies:** CPG-DataStructures, CrossLanguage-DependencyMaps, Unity-Claude-PerformanceOptimizer-Original, Unity-Claude-IncrementalProcessor, CPG-Unified, Unity-Claude-ParallelProcessor-Original, Unity-Claude-Cache-Original, Unity-Claude-Cache, Unity-Claude-PerformanceOptimizer-Refactored, Performance-Cache, Unity-Claude-CPG-Original, Unity-Claude-IncrementalProcessor-Fixed, BatchProcessingEngine, Unity-Claude-Cache-Fixed

--- 
### Unity-Claude-Ollama-Enhanced

[⬆ Back to Contents](#-table-of-contents)

Unity Editor integration providing direct communication with Unity processes. Monitors compilation, extracts errors, and manages project operations.

**Key Capabilities:** system initialization, action execution, process initiation, specialized operations, data retrieval

**Module Statistics:**
- Functions: 13
- Lines of Code: 826
- Exported Members: 1


**Module Details:**
- **Path:** `Modules\Unity-Claude-AI-Integration\Ollama\Unity-Claude-Ollama-Enhanced.psm1`
- **Size:** 26.84 KB
- **Functions:** 13
- **Last Modified:** 2025-08-30 19:47

**Dependencies:** CPG-DataStructures, CrossLanguage-DependencyMaps, Unity-Claude-PerformanceOptimizer-Original, JobScheduler, Unity-Claude-IncrementalProcessor, CPG-Unified, Unity-Claude-ParallelProcessor-Original, RunspacePoolManager, Unity-Claude-Cache-Original, StatisticsTracker, ModuleFunctions, Unity-Claude-Cache, Unity-Claude-PerformanceOptimizer-Refactored, Performance-Cache, Unity-Claude-Ollama, Unity-Claude-CPG-Original, Unity-Claude-IncrementalProcessor-Fixed, BatchProcessingEngine, Unity-Claude-Cache-Fixed

--- 
### Unity-Claude-Ollama-Optimized

[⬆ Back to Contents](#-table-of-contents)

Unity Editor integration providing direct communication with Unity processes. Monitors compilation, extracts errors, and manages project operations.

**Key Capabilities:** data retrieval, specialized operations, process initiation, action execution

**Module Statistics:**
- Functions: 8
- Lines of Code: 655
- Exported Members: 1


**Module Details:**
- **Path:** `Modules\Unity-Claude-AI-Integration\Ollama\Unity-Claude-Ollama-Optimized.psm1`
- **Size:** 27.37 KB
- **Functions:** 6
- **Last Modified:** 2025-08-30 19:47

**Dependencies:** Unity-Claude-PerformanceOptimizer-Original, Unity-Claude-IncrementalProcessor, Unity-Claude-ParallelProcessor-Original, Unity-Claude-Cache-Original, ModuleFunctions, Unity-Claude-Cache, Unity-Claude-PerformanceOptimizer-Refactored, Performance-Cache, Unity-Claude-Ollama-Optimized-Fixed, Unity-Claude-Ollama, Unity-Claude-IncrementalProcessor-Fixed, BatchProcessingEngine, Unity-Claude-Cache-Fixed

--- 
### Unity-Claude-Ollama-Optimized-Fixed

[⬆ Back to Contents](#-table-of-contents)

Unity Editor integration providing direct communication with Unity processes. Monitors compilation, extracts errors, and manages project operations.

**Key Capabilities:** data retrieval, specialized operations, process initiation, action execution

**Module Statistics:**
- Functions: 9
- Lines of Code: 800
- Exported Members: 1


**Module Details:**
- **Path:** `Modules\Unity-Claude-AI-Integration\Ollama\Unity-Claude-Ollama-Optimized-Fixed.psm1`
- **Size:** 35.32 KB
- **Functions:** 6
- **Last Modified:** 2025-08-30 19:47

**Dependencies:** Unity-Claude-PerformanceOptimizer-Original, Unity-Claude-IncrementalProcessor, Unity-Claude-ParallelProcessor-Original, Unity-Claude-Cache-Original, ModuleFunctions, Unity-Claude-Cache, Unity-Claude-PerformanceOptimizer-Refactored, Performance-Cache, Unity-Claude-Ollama-Optimized, Unity-Claude-Ollama, Unity-Claude-IncrementalProcessor-Fixed, BatchProcessingEngine, Unity-Claude-Cache-Fixed

--- 
### Unity-Claude-ParallelProcessing

[⬆ Back to Contents](#-table-of-contents)

High-performance parallel processing module for concurrent operations. Manages thread pools, runspace allocation, and synchronization primitives. Unity Editor integration providing direct communication with Unity processes. Monitors compilation, extracts errors, and manages project operations. 

**Key Capabilities:** specialized operations, resource creation, data retrieval, configuration management, cleanup operations 

**Module Statistics:**
 - Functions: 19
 - Lines of Code: 1150
 - Exported Members: 1


**Module Details:**
- **Path:** `Modules\Unity-Claude-ParallelProcessing\Unity-Claude-ParallelProcessing.psm1`
- **Size:** 40.62 KB
- **Functions:** 18
- **Last Modified:** 2025-08-21 17:45

**Dependencies:** CPG-DataStructures, CrossLanguage-DependencyMaps, Unity-Claude-PerformanceOptimizer-Original, JobScheduler, Unity-Claude-IncrementalProcessor, CPG-Unified, Unity-Claude-ConcurrentProcessor, Unity-Claude-ParallelProcessor-Original, RunspacePoolManager, Unity-Claude-Cache-Original, StatisticsTracker, ModuleFunctions, Unity-Claude-Cache, AgentLogging, Unity-Claude-PerformanceOptimizer-Refactored, Performance-Cache, Unity-Claude-CPG-Original, Unity-Claude-IncrementalProcessor-Fixed, Unity-Claude-ResourceOptimizer, Unity-Claude-ConcurrentCollections, BatchProcessingEngine, Unity-Claude-Cache-Fixed

--- 
### Unity-Claude-ParallelProcessor

[⬆ Back to Contents](#-table-of-contents)

High-performance parallel processing module for concurrent operations. Manages thread pools, runspace allocation, and synchronization primitives. Unity Editor integration providing direct communication with Unity processes. Monitors compilation, extracts errors, and manages project operations. 

**Key Capabilities:** data retrieval 

**Module Statistics:**
 - Functions: 1
 - Lines of Code: 251
 - Exported Members: 2


**Module Details:**
- **Path:** `Modules\Unity-Claude-ParallelProcessor\Unity-Claude-ParallelProcessor.psm1`
- **Size:** 10.43 KB
- **Functions:** 3
- **Last Modified:** 2025-08-26 11:46

**Dependencies:** Unity-Claude-PerformanceOptimizer-Original, JobScheduler, Unity-Claude-IncrementalProcessor, Unity-Claude-ParallelProcessor-Original, RunspacePoolManager, Unity-Claude-Cache-Original, StatisticsTracker, ModuleFunctions, Unity-Claude-Cache, Unity-Claude-PerformanceOptimizer-Refactored, Performance-Cache, RunspacePoolManagement, Unity-Claude-IncrementalProcessor-Fixed, OptimizerConfiguration, BatchProcessingEngine, Unity-Claude-Cache-Fixed, Unity-Claude-RunspaceManagement-Original, Unity-Claude-ParallelProcessor-Refactored

--- 
### Unity-Claude-ParallelProcessor-Original

[⬆ Back to Contents](#-table-of-contents)

High-performance parallel processing module for concurrent operations. Manages thread pools, runspace allocation, and synchronization primitives. Unity Editor integration providing direct communication with Unity processes. Monitors compilation, extracts errors, and manages project operations. 

**Key Capabilities:** resource creation, action execution, process initiation, data retrieval 

**Module Statistics:**
 - Functions: 5
 - Lines of Code: 923
 - Classes: 2
 - Exported Members: 1


**Module Details:**
- **Path:** `Modules\Unity-Claude-ParallelProcessor\Unity-Claude-ParallelProcessor-Original.psm1`
- **Size:** 32.43 KB
- **Functions:** 35
- **Last Modified:** 2025-08-26 12:30

**Dependencies:** CPG-DataStructures, CrossLanguage-DependencyMaps, Unity-Claude-PerformanceOptimizer-Original, JobScheduler, Unity-Claude-IncrementalProcessor, Performance-IncrementalUpdates, CPG-Unified, RunspacePoolManager, Unity-Claude-Cache-Original, StatisticsTracker, ModuleFunctions, Unity-Claude-Cache, Unity-Claude-PerformanceOptimizer-Refactored, Performance-Cache, Unity-Claude-CPG-Original, Unity-Claude-IncrementalProcessor-Fixed, BatchProcessingEngine, ProgressTracker, Unity-Claude-ScalabilityEnhancements-Original, Unity-Claude-Cache-Fixed

--- 
### Unity-Claude-ParallelProcessor-Refactored

[⬆ Back to Contents](#-table-of-contents)

High-performance parallel processing module for concurrent operations. Manages thread pools, runspace allocation, and synchronization primitives. Unity Editor integration providing direct communication with Unity processes. Monitors compilation, extracts errors, and manages project operations. 

**Key Capabilities:** data retrieval 

**Module Statistics:**
 - Functions: 1
 - Lines of Code: 251
 - Exported Members: 2


**Module Details:**
- **Path:** `Modules\Unity-Claude-ParallelProcessor\Unity-Claude-ParallelProcessor-Refactored.psm1`
- **Size:** 10.43 KB
- **Functions:** 3
- **Last Modified:** 2025-08-26 11:46

**Dependencies:** Unity-Claude-PerformanceOptimizer-Original, JobScheduler, Unity-Claude-IncrementalProcessor, Unity-Claude-ParallelProcessor-Original, RunspacePoolManager, Unity-Claude-Cache-Original, StatisticsTracker, ModuleFunctions, Unity-Claude-Cache, Unity-Claude-PerformanceOptimizer-Refactored, Performance-Cache, RunspacePoolManagement, Unity-Claude-IncrementalProcessor-Fixed, OptimizerConfiguration, BatchProcessingEngine, Unity-Claude-Cache-Fixed, Unity-Claude-RunspaceManagement-Original, Unity-Claude-ParallelProcessor

--- 
### Unity-Claude-PerformanceOptimizer

[⬆ Back to Contents](#-table-of-contents)

Unity Editor integration providing direct communication with Unity processes. Monitors compilation, extracts errors, and manages project operations.

**Key Capabilities:** specialized operations, data retrieval, resource creation, process initiation, process termination

**Module Statistics:**
- Functions: 22
- Lines of Code: 856
- Exported Members: 1


**Module Details:**
- **Path:** `Modules\Unity-Claude-PerformanceOptimizer.psm1`
- **Size:** 27.63 KB
- **Functions:** 22
- **Last Modified:** 2025-08-20 17:25

**Dependencies:** CPG-DataStructures, CrossLanguage-DependencyMaps, Unity-Claude-PerformanceOptimizer-Original, PerformanceOptimization, Unity-Claude-IncrementalProcessor, CPG-Unified, Unity-Claude-ParallelProcessor-Original, Unity-Claude-Cache-Original, ModuleFunctions, Unity-Claude-Cache, Unity-Claude-PerformanceOptimizer-Refactored, Performance-Cache, PerformanceMonitoring, Unity-Claude-CPG-Original, Unity-Claude-IncrementalProcessor-Fixed, BatchProcessingEngine, PerformanceOptimizer, Unity-Claude-ScalabilityOptimizer, Unity-Claude-AutonomousStateTracker, Unity-Claude-Cache-Fixed, Unity-Claude-DocumentationQualityOrchestrator

--- 
### Unity-Claude-PerformanceOptimizer-Original

[⬆ Back to Contents](#-table-of-contents)

Unity Editor integration providing direct communication with Unity processes. Monitors compilation, extracts errors, and manages project operations.

**Key Capabilities:** resource creation, process initiation, process termination, data retrieval

**Module Statistics:**
- Functions: 7
- Lines of Code: 922
- Classes: 1
- Exported Members: 1


**Module Details:**
- **Path:** `Modules\Unity-Claude-PerformanceOptimizer\Unity-Claude-PerformanceOptimizer-Original.psm1`
- **Size:** 34.33 KB
- **Functions:** 34
- **Last Modified:** 2025-08-26 11:46

**Dependencies:** JobScheduler, Unity-Claude-IncrementalProcessor, Performance-IncrementalUpdates, Unity-Claude-ParallelProcessor-Original, MetricsCollection, RunspacePoolManager, Unity-Claude-Cache-Original, StatisticsTracker, ModuleFunctions, Unity-Claude-Cache, MetricsAndHealthCheck, Unity-Claude-PerformanceOptimizer-Refactored, Performance-Cache, Unity-Claude-CPG-ASTConverter, Unity-Claude-CPG-Original, Unity-Claude-IncrementalProcessor-Fixed, Unity-Claude-DocumentationDrift, BatchProcessingEngine, ProgressTracker, Unity-Claude-ScalabilityEnhancements-Original, Unity-Claude-Cache-Fixed

--- 
### Unity-Claude-PerformanceOptimizer-Refactored

[⬆ Back to Contents](#-table-of-contents)

Unity Editor integration providing direct communication with Unity processes. Monitors compilation, extracts errors, and manages project operations.

**Key Capabilities:** resource creation, process initiation, process termination, data retrieval

**Module Statistics:**
- Functions: 9
- Lines of Code: 527
- Classes: 1
- Exported Members: 1


**Module Details:**
- **Path:** `Modules\Unity-Claude-PerformanceOptimizer\Unity-Claude-PerformanceOptimizer-Refactored.psm1`
- **Size:** 19.43 KB
- **Functions:** 22
- **Last Modified:** 2025-08-26 11:46

**Dependencies:** Unity-Claude-PerformanceOptimizer-Original, JobScheduler, PerformanceOptimization, Unity-Claude-IncrementalProcessor, Performance-IncrementalUpdates, Unity-Claude-FileMonitor, Unity-Claude-ParallelProcessor-Original, MetricsCollection, RunspacePoolManager, Unity-Claude-Cache-Original, StatisticsTracker, ModuleFunctions, Unity-Claude-Cache, MetricsAndHealthCheck, Unity-Claude-RealTimeMonitoring, Performance-Cache, PerformanceMonitoring, Unity-Claude-FileMonitor-Fixed, Unity-Claude-IncrementalProcessor-Fixed, Unity-Claude-DocumentationDrift, OptimizerConfiguration, Unity-Claude-ResponseMonitor, BatchProcessingEngine, Unity-Claude-PerformanceOptimizer, ProgressTracker, Unity-Claude-ScalabilityOptimizer, Unity-Claude-ScalabilityEnhancements-Original, Unity-Claude-AutonomousStateTracker, ReportingExport, Unity-Claude-Cache-Fixed, Unity-Claude-DocumentationQualityOrchestrator, FileProcessing

--- 
### Unity-Claude-PredictiveAnalysis

[⬆ Back to Contents](#-table-of-contents)

Unity Editor integration providing direct communication with Unity processes. Monitors compilation, extracts errors, and manages project operations.

**Key Capabilities:** system initialization, data retrieval, specialized operations

**Module Statistics:**
- Functions: 4
- Lines of Code: 494
- Exported Members: 1


**Module Details:**
- **Path:** `Modules\Unity-Claude-PredictiveAnalysis\Unity-Claude-PredictiveAnalysis.psm1`
- **Size:** 18.66 KB
- **Functions:** 4
- **Last Modified:** 2025-08-26 11:46

**Dependencies:** RefactoringDetection, Unity-Claude-ParallelProcessor-Original, MetricsCollection, Unity-Claude-Cache-Original, CodeSmellPrediction, ModuleFunctions, Unity-Claude-Cache, Predictive-Maintenance, MaintenancePrediction, Unity-Claude-PredictiveAnalysis-Original, ContentAnalysis, AnalyticsReporting, Performance-Cache, TrendAnalysis, ImprovementRoadmaps, Unity-Claude-PredictiveAnalysis-Refactored, Unity-Claude-MachineLearning, RiskAssessment, Unity-Claude-Cache-Fixed

--- 
### Unity-Claude-PredictiveAnalysis-Original

[⬆ Back to Contents](#-table-of-contents)

Unity Editor integration providing direct communication with Unity processes. Monitors compilation, extracts errors, and manages project operations.

**Key Capabilities:** system initialization, data retrieval, specialized operations

**Module Statistics:**
- Functions: 30
- Lines of Code: 2095
- Classes: 3
- Exported Members: 1


**Module Details:**
- **Path:** `Modules\Unity-Claude-PredictiveAnalysis\Unity-Claude-PredictiveAnalysis-Original.psm1`
- **Size:** 74.37 KB
- **Functions:** 28
- **Last Modified:** 2025-08-25 13:45

**Dependencies:** CPG-DataStructures, CrossLanguage-DependencyMaps, Unity-Claude-PerformanceOptimizer-Original, Unity-Claude-IncrementalProcessor, CPG-Unified, RefactoringDetection, Unity-Claude-ParallelProcessor-Original, MetricsCollection, Unity-Claude-Cache-Original, CodeSmellPrediction, ModuleFunctions, Unity-Claude-Cache, Predictive-Maintenance, MaintenancePrediction, ContentAnalysis, AnalyticsReporting, Unity-Claude-PerformanceOptimizer-Refactored, Performance-Cache, TrendAnalysis, ImprovementRoadmaps, Unity-Claude-CPG-Original, Unity-Claude-IncrementalProcessor-Fixed, Unity-Claude-LLM, GraphTraversal, CPG-QueryOperations, CodeComplexityMetrics, BatchProcessingEngine, CodeRedundancyDetection, Unity-Claude-MachineLearning, RiskAssessment, Unity-Claude-Cache-Fixed

--- 
### Unity-Claude-PredictiveAnalysis-Refactored

[⬆ Back to Contents](#-table-of-contents)

Unity Editor integration providing direct communication with Unity processes. Monitors compilation, extracts errors, and manages project operations.

**Key Capabilities:** system initialization, data retrieval, specialized operations

**Module Statistics:**
- Functions: 4
- Lines of Code: 494
- Exported Members: 1


**Module Details:**
- **Path:** `Modules\Unity-Claude-PredictiveAnalysis\Unity-Claude-PredictiveAnalysis-Refactored.psm1`
- **Size:** 18.66 KB
- **Functions:** 4
- **Last Modified:** 2025-08-26 11:46

**Dependencies:** RefactoringDetection, Unity-Claude-ParallelProcessor-Original, MetricsCollection, Unity-Claude-Cache-Original, CodeSmellPrediction, ModuleFunctions, Unity-Claude-Cache, Predictive-Maintenance, MaintenancePrediction, Unity-Claude-PredictiveAnalysis-Original, ContentAnalysis, AnalyticsReporting, Performance-Cache, TrendAnalysis, ImprovementRoadmaps, Unity-Claude-MachineLearning, RiskAssessment, Unity-Claude-PredictiveAnalysis, Unity-Claude-Cache-Fixed

--- 
### Unity-Claude-ProactiveMaintenanceEngine

[⬆ Back to Contents](#-table-of-contents)

Unity Editor integration providing direct communication with Unity processes. Monitors compilation, extracts errors, and manages project operations.

**Key Capabilities:** system initialization, specialized operations

**Module Statistics:**
- Functions: 22
- Lines of Code: 964
- Exported Members: 1


**Module Details:**
- **Path:** `Modules\Unity-Claude-ProactiveMaintenanceEngine\Unity-Claude-ProactiveMaintenanceEngine.psm1`
- **Size:** 33.33 KB
- **Functions:** 22
- **Last Modified:** 2025-08-30 14:11

**Dependencies:** CPG-DataStructures, CrossLanguage-DependencyMaps, Unity-Claude-PerformanceOptimizer-Original, Unity-Claude-IncrementalProcessor, CPG-Unified, Unity-Claude-ParallelProcessor-Original, RunspacePoolManager, Unity-Claude-Cache-Original, ModuleFunctions, Unity-Claude-Cache, Predictive-Maintenance, MaintenancePrediction, Unity-Claude-IntelligentAlerting, Unity-Claude-PredictiveAnalysis-Original, Unity-Claude-PerformanceOptimizer-Refactored, Unity-Claude-RealTimeMonitoring, Performance-Cache, TrendAnalysis, Unity-Claude-CPG-Original, Unity-Claude-IncrementalProcessor-Fixed, BatchProcessingEngine, Unity-Claude-MachineLearning, RiskAssessment, Unity-Claude-Cache-Fixed

--- 
### Unity-Claude-RealTimeAnalysis

[⬆ Back to Contents](#-table-of-contents)

Unity Editor integration providing direct communication with Unity processes. Monitors compilation, extracts errors, and manages project operations.

**Key Capabilities:** system initialization, specialized operations, process initiation

**Module Statistics:**
- Functions: 16
- Lines of Code: 658
- Exported Members: 1


**Module Details:**
- **Path:** `Modules\Unity-Claude-RealTimeAnalysis\Unity-Claude-RealTimeAnalysis.psm1`
- **Size:** 22.22 KB
- **Functions:** 15
- **Last Modified:** 2025-08-30 12:38

**Dependencies:** CPG-DataStructures, CrossLanguage-DependencyMaps, Unity-Claude-PerformanceOptimizer-Original, Unity-Claude-IncrementalProcessor, CPG-Unified, Unity-Claude-ParallelProcessor-Original, RunspacePoolManager, Unity-Claude-Cache-Original, ModuleFunctions, Unity-Claude-Cache, Unity-Claude-PerformanceOptimizer-Refactored, Unity-Claude-RealTimeMonitoring, Performance-Cache, Unity-Claude-CPG-Original, Unity-Claude-IncrementalProcessor-Fixed, Unity-Claude-ChangeIntelligence, BatchProcessingEngine, Unity-Claude-Cache-Fixed

--- 
### Unity-Claude-RealTimeMonitoring

[⬆ Back to Contents](#-table-of-contents)

Unity Editor integration providing direct communication with Unity processes. Monitors compilation, extracts errors, and manages project operations. Real-time monitoring module tracking system health and performance metrics. Provides event-driven notifications and automated issue response. 

**Key Capabilities:** system initialization, process initiation, specialized operations 

**Module Statistics:**
 - Functions: 12
 - Lines of Code: 527
 - Exported Members: 1


**Module Details:**
- **Path:** `Modules\Unity-Claude-RealTimeMonitoring\Unity-Claude-RealTimeMonitoring.psm1`
- **Size:** 17.14 KB
- **Functions:** 12
- **Last Modified:** 2025-08-30 12:13

**Dependencies:** Unity-Claude-PerformanceOptimizer-Original, JobScheduler, Unity-Claude-IncrementalProcessor, Unity-Claude-MasterOrchestrator-Original, Unity-Claude-ParallelProcessor-Original, RunspacePoolManager, Unity-Claude-Cache-Original, StatisticsTracker, ModuleFunctions, Unity-Claude-Cache, Unity-Claude-PerformanceOptimizer-Refactored, Performance-Cache, Unity-Claude-ReliabilityManager, Unity-Claude-IncrementalProcessor-Fixed, BatchProcessingEngine, EventProcessing, Unity-Claude-Cache-Fixed

--- 
### Unity-Claude-RealTimeOptimizer

[⬆ Back to Contents](#-table-of-contents)

Unity Editor integration providing direct communication with Unity processes. Monitors compilation, extracts errors, and manages project operations.

**Key Capabilities:** system initialization, configuration management

**Module Statistics:**
- Functions: 22
- Lines of Code: 730
- Exported Members: 1


**Module Details:**
- **Path:** `Modules\Unity-Claude-RealTimeOptimizer\Unity-Claude-RealTimeOptimizer.psm1`
- **Size:** 26.14 KB
- **Functions:** 22
- **Last Modified:** 2025-08-30 13:10

**Dependencies:** Unity-Claude-PerformanceOptimizer-Original, JobScheduler, Unity-Claude-IncrementalProcessor, Unity-Claude-ParallelProcessor-Original, RunspacePoolManager, Unity-Claude-Cache-Original, StatisticsTracker, ModuleFunctions, Unity-Claude-Cache, Unity-Claude-PerformanceOptimizer-Refactored, Performance-Cache, MemoryManager, Unity-Claude-IncrementalProcessor-Fixed, Unity-Claude-ChangeIntelligence, BatchProcessingEngine, Unity-Claude-ScalabilityEnhancements-Original, Unity-Claude-Cache-Fixed

--- 
### Unity-Claude-RecompileSignaling

[⬆ Back to Contents](#-table-of-contents)

Unity Editor integration providing direct communication with Unity processes. Monitors compilation, extracts errors, and manages project operations.

**Key Capabilities:** specialized operations, process initiation, process termination

**Module Statistics:**
- Functions: 4
- Lines of Code: 288
- Exported Members: 1


**Module Details:**
- **Path:** `Modules\Unity-Claude-RecompileSignaling.psm1`
- **Size:** 11.62 KB
- **Functions:** 4
- **Last Modified:** 2025-08-20 17:25

**Dependencies:** Unity-Claude-PerformanceOptimizer-Original, JobScheduler, Unity-Claude-IncrementalProcessor, Unity-Claude-ParallelProcessor-Original, RunspacePoolManager, Unity-Claude-Cache-Original, StatisticsTracker, ModuleFunctions, Unity-Claude-Cache, Unity-Claude-PerformanceOptimizer-Refactored, Performance-Cache, Unity-Claude-IncrementalProcessor-Fixed, BatchProcessingEngine, Unity-Claude-Cache-Fixed

--- 
### Unity-Claude-ReliabilityManager

[⬆ Back to Contents](#-table-of-contents)

Unity Editor integration providing direct communication with Unity processes. Monitors compilation, extracts errors, and manages project operations.

**Key Capabilities:** system initialization

**Module Statistics:**
- Functions: 20
- Lines of Code: 1161
- Exported Members: 1


**Module Details:**
- **Path:** `Modules\Unity-Claude-ReliabilityManager\Unity-Claude-ReliabilityManager.psm1`
- **Size:** 43.51 KB
- **Functions:** 20
- **Last Modified:** 2025-08-30 20:35

**Dependencies:** Unity-Claude-PerformanceOptimizer-Original, Unity-Claude-IncrementalProcessor, BackgroundJobQueue, Unity-Claude-ParallelProcessor-Original, Unity-Claude-Cache-Original, ModuleFunctions, Unity-Claude-Cache, Unity-Claude-PerformanceOptimizer-Refactored, Unity-Claude-RealTimeMonitoring, Performance-Cache, Unity-Claude-IncrementalProcessor-Fixed, BatchProcessingEngine, Unity-Claude-ScalabilityEnhancements-Original, Unity-Claude-Cache-Fixed

--- 
### Unity-Claude-ReliableMonitoring

[⬆ Back to Contents](#-table-of-contents)

Unity Editor integration providing direct communication with Unity processes. Monitors compilation, extracts errors, and manages project operations. Real-time monitoring module tracking system health and performance metrics. Provides event-driven notifications and automated issue response. 

**Key Capabilities:** specialized operations, validation and testing, process initiation, process termination 

**Module Statistics:**
 - Functions: 12
 - Lines of Code: 461
 - Exported Members: 1


**Module Details:**
- **Path:** `Modules\Unity-Claude-ReliableMonitoring.psm1`
- **Size:** 16.66 KB
- **Functions:** 10
- **Last Modified:** 2025-08-20 17:25

**Dependencies:** Unity-Claude-PerformanceOptimizer-Original, JobScheduler, Unity-Claude-IncrementalProcessor, AutoGenerationTriggers, Unity-Claude-ParallelProcessor-Original, RunspacePoolManager, Unity-Claude-Cache-Original, StatisticsTracker, ModuleFunctions, Unity-Claude-Cache, Unity-Claude-PerformanceOptimizer-Refactored, Performance-Cache, Unity-Claude-IncrementalProcessor-Fixed, BatchProcessingEngine, Unity-Claude-Cache-Fixed

--- 
### Unity-Claude-RepoAnalyst

[⬆ Back to Contents](#-table-of-contents)

Unity Editor integration providing direct communication with Unity processes. Monitors compilation, extracts errors, and manages project operations.

**Key Capabilities:** system initialization, specialized operations, action execution, resource creation

**Module Statistics:**
- Functions: 21
- Lines of Code: 453
- Exported Members: 1


**Module Details:**
- **Path:** `Modules\Unity-Claude-RepoAnalyst\Unity-Claude-RepoAnalyst.psm1`
- **Size:** 13.83 KB
- **Functions:** 20
- **Last Modified:** 2025-08-24 12:06

**Dependencies:** Unity-Claude-PerformanceOptimizer-Original, Unity-Claude-DocumentationDrift-Refactored, Unity-Claude-IncrementalProcessor, Unity-Claude-ParallelProcessor-Original, SemanticAnalysis-PatternDetector, Unity-Claude-Cache-Original, ModuleFunctions, Unity-Claude-Cache, Predictive-Maintenance, Unity-Claude-PerformanceOptimizer-Refactored, Performance-Cache, Unity-Claude-IncrementalProcessor-Fixed, BatchProcessingEngine, Unity-Claude-Cache-Fixed

--- 
### Unity-Claude-ResourceOptimizer

[⬆ Back to Contents](#-table-of-contents)

Unity Editor integration providing direct communication with Unity processes. Monitors compilation, extracts errors, and manages project operations.

**Key Capabilities:** specialized operations, data retrieval, action execution

**Module Statistics:**
- Functions: 12
- Lines of Code: 904
- Exported Members: 1


**Module Details:**
- **Path:** `Modules\Unity-Claude-ResourceOptimizer.psm1`
- **Size:** 33.53 KB
- **Functions:** 12
- **Last Modified:** 2025-08-20 17:25

**Dependencies:** CPG-DataStructures, CrossLanguage-DependencyMaps, Unity-Claude-PerformanceOptimizer-Original, Unity-Claude-IncrementalProcessor, CPG-Unified, Unity-Claude-ParallelProcessor-Original, Unity-Claude-Cache-Original, ModuleFunctions, Unity-Claude-Cache, AgentLogging, Unity-Claude-PerformanceOptimizer-Refactored, Performance-Cache, Unity-Claude-CPG-Original, Unity-Claude-IncrementalProcessor-Fixed, BatchProcessingEngine, Unity-Claude-PerformanceOptimizer, Unity-Claude-Cache-Fixed

--- 
### Unity-Claude-ResponseMonitor

[⬆ Back to Contents](#-table-of-contents)

Unity Editor integration providing direct communication with Unity processes. Monitors compilation, extracts errors, and manages project operations. Real-time monitoring module tracking system health and performance metrics. Provides event-driven notifications and automated issue response. 

**Key Capabilities:** specialized operations, validation and testing, data retrieval, configuration management, system initialization 

**Module Statistics:**
 - Functions: 24
 - Lines of Code: 837


**Module Details:**
- **Path:** `Modules\Unity-Claude-ResponseMonitor\Unity-Claude-ResponseMonitor.psm1`
- **Size:** 28.94 KB
- **Functions:** 24
- **Last Modified:** 2025-08-20 17:25

**Dependencies:** Unity-Claude-PerformanceOptimizer-Original, JobScheduler, Unity-Claude-IncrementalProcessor, Unity-Claude-ParallelProcessor-Original, RunspacePoolManager, Unity-Claude-Cache-Original, StatisticsTracker, ModuleFunctions, Unity-Claude-Cache, Unity-Claude-PerformanceOptimizer-Refactored, Performance-Cache, Unity-Claude-IncrementalProcessor-Fixed, Unity-Claude-ResponseMonitoring, BatchProcessingEngine, ProgressTracker, Unity-Claude-DecisionEngine-Original, Unity-Claude-FixEngine, Unity-Claude-ScalabilityEnhancements-Original, Unity-Claude-Cache-Fixed, DecisionEngineCore, FileSystemMonitoring

--- 
### Unity-Claude-ResponseMonitoring

[⬆ Back to Contents](#-table-of-contents)

Unity Editor integration providing direct communication with Unity processes. Monitors compilation, extracts errors, and manages project operations. Real-time monitoring module tracking system health and performance metrics. Provides event-driven notifications and automated issue response. 

**Key Capabilities:** specialized operations, validation and testing, process initiation, process termination 

**Module Statistics:**
 - Functions: 13
 - Lines of Code: 492
 - Exported Members: 1


**Module Details:**
- **Path:** `Modules\Unity-Claude-ResponseMonitoring.psm1`
- **Size:** 18 KB
- **Functions:** 11
- **Last Modified:** 2025-08-20 17:25

**Dependencies:** Unity-Claude-PerformanceOptimizer-Original, JobScheduler, Unity-Claude-IncrementalProcessor, Unity-Claude-ParallelProcessor-Original, RunspacePoolManager, Unity-Claude-Cache-Original, StatisticsTracker, ModuleFunctions, Unity-Claude-Cache, Unity-Claude-PerformanceOptimizer-Refactored, Performance-Cache, Unity-Claude-IncrementalProcessor-Fixed, ResponseAnalysisEngine-Broken, Unity-Claude-ResponseMonitor, BatchProcessingEngine, Unity-Claude-Cache-Fixed, FileSystemMonitoring

--- 
### Unity-Claude-RunspaceManagement

[⬆ Back to Contents](#-table-of-contents)

Unity Editor integration providing direct communication with Unity processes. Monitors compilation, extracts errors, and manages project operations.

**Key Capabilities:** system initialization, data retrieval, process termination

**Module Statistics:**
- Functions: 3
- Lines of Code: 309
- Exported Members: 1


**Module Details:**
- **Path:** `Modules\Unity-Claude-RunspaceManagement\Unity-Claude-RunspaceManagement.psm1`
- **Size:** 10.91 KB
- **Functions:** 3
- **Last Modified:** 2025-08-26 11:46

**Dependencies:** CPG-DataStructures, CrossLanguage-DependencyMaps, Unity-Claude-PerformanceOptimizer-Original, Unity-Claude-IncrementalProcessor, CPG-Unified, Unity-Claude-ParallelProcessor-Original, MetricsCollection, RunspacePoolManager, Unity-Claude-Cache-Original, ModuleFunctions, Unity-Claude-Cache, SelfPatching, RunspaceCore, Unity-Claude-PerformanceOptimizer-Refactored, Performance-Cache, ProductionRunspacePool, ModuleVariablePreloading, RunspacePoolManagement, Unity-Claude-CPG-Original, Unity-Claude-IncrementalProcessor-Fixed, SessionStateConfiguration, BatchProcessingEngine, SuccessTracking, Unity-Claude-RunspaceManagement-Refactored, Unity-Claude-Cache-Fixed, Unity-Claude-RunspaceManagement-Original, VariableSharing, ThrottlingResourceControl

--- 
### Unity-Claude-RunspaceManagement-Original

[⬆ Back to Contents](#-table-of-contents)

Unity Editor integration providing direct communication with Unity processes. Monitors compilation, extracts errors, and manages project operations.

**Key Capabilities:** validation and testing, specialized operations, resource creation, configuration management

**Module Statistics:**
- Functions: 35
- Lines of Code: 1950
- Exported Members: 1


**Module Details:**
- **Path:** `Modules\Unity-Claude-RunspaceManagement\Unity-Claude-RunspaceManagement-Original.psm1`
- **Size:** 75.97 KB
- **Functions:** 30
- **Last Modified:** 2025-08-26 11:46

**Dependencies:** CPG-DataStructures, CrossLanguage-DependencyMaps, Unity-Claude-UnityParallelization-Original, Unity-Claude-PerformanceOptimizer-Original, JobScheduler, Unity-Claude-IncrementalProcessor, CPG-Unified, Unity-Claude-ParallelProcessor-Original, MetricsCollection, RunspacePoolManager, Unity-Claude-Cache-Original, StatisticsTracker, ModuleFunctions, Unity-Claude-Cache, SelfPatching, Unity-Claude-ParallelProcessing, RunspaceCore, DependencyManagement, AgentLogging, Unity-Claude-PerformanceOptimizer-Refactored, Performance-Cache, ProductionRunspacePool, ModuleVariablePreloading, RunspacePoolManagement, Unity-Claude-CPG-Original, Unity-Claude-ClaudeParallelization, Unity-Claude-IncrementalProcessor-Fixed, SessionStateConfiguration, BatchProcessingEngine, SuccessTracking, ParallelizationCore, ProgressTracker, Unity-Claude-ScalabilityEnhancements-Original, Unity-Claude-Cache-Fixed, Unity-Claude-IntegratedWorkflow-Original, VariableSharing, ThrottlingResourceControl

--- 
### Unity-Claude-RunspaceManagement-Refactored

[⬆ Back to Contents](#-table-of-contents)

Unity Editor integration providing direct communication with Unity processes. Monitors compilation, extracts errors, and manages project operations.

**Key Capabilities:** system initialization, data retrieval, process termination

**Module Statistics:**
- Functions: 3
- Lines of Code: 309
- Exported Members: 1


**Module Details:**
- **Path:** `Modules\Unity-Claude-RunspaceManagement\Unity-Claude-RunspaceManagement-Refactored.psm1`
- **Size:** 10.91 KB
- **Functions:** 3
- **Last Modified:** 2025-08-26 11:46

**Dependencies:** CPG-DataStructures, CrossLanguage-DependencyMaps, Unity-Claude-PerformanceOptimizer-Original, Unity-Claude-IncrementalProcessor, CPG-Unified, Unity-Claude-ParallelProcessor-Original, MetricsCollection, RunspacePoolManager, Unity-Claude-Cache-Original, ModuleFunctions, Unity-Claude-Cache, SelfPatching, RunspaceCore, Unity-Claude-RunspaceManagement, Unity-Claude-PerformanceOptimizer-Refactored, Performance-Cache, ProductionRunspacePool, ModuleVariablePreloading, RunspacePoolManagement, Unity-Claude-CPG-Original, Unity-Claude-IncrementalProcessor-Fixed, SessionStateConfiguration, BatchProcessingEngine, SuccessTracking, Unity-Claude-Cache-Fixed, Unity-Claude-RunspaceManagement-Original, VariableSharing, ThrottlingResourceControl

--- 
### Unity-Claude-Safety

[⬆ Back to Contents](#-table-of-contents)

Safety and validation framework ensuring all automated operations meet security requirements. Implements sandboxing, command validation, and rollback mechanisms. Unity Editor integration providing direct communication with Unity processes. Monitors compilation, extracts errors, and manages project operations. 

**Key Capabilities:** system initialization, validation and testing, action execution, configuration management 

**Module Statistics:**
 - Functions: 9
 - Lines of Code: 701
 - Exported Members: 1


**Module Details:**
- **Path:** `Modules\Unity-Claude-Safety\Unity-Claude-Safety.psm1`
- **Size:** 23.95 KB
- **Functions:** 9
- **Last Modified:** 2025-08-20 17:25

**Dependencies:** Unity-Claude-ParallelProcessor-Original, Unity-Claude-Cache-Original, ModuleFunctions, Unity-Claude-Cache, Performance-Cache, Unity-Claude-Cache-Fixed

--- 
### Unity-Claude-ScalabilityEnhancements

[⬆ Back to Contents](#-table-of-contents)

Unity Editor integration providing direct communication with Unity processes. Monitors compilation, extracts errors, and manages project operations.

**Key Capabilities:** system initialization, validation and testing, data retrieval, specialized operations

**Module Statistics:**
- Functions: 4
- Lines of Code: 428
- Exported Members: 1


**Module Details:**
- **Path:** `Modules\Unity-Claude-ScalabilityEnhancements\Unity-Claude-ScalabilityEnhancements.psm1`
- **Size:** 16.67 KB
- **Functions:** 4
- **Last Modified:** 2025-08-26 11:46

**Dependencies:** Unity-Claude-PerformanceOptimizer-Original, Unity-Claude-IncrementalProcessor, BackgroundJobQueue, HorizontalScaling, Unity-Claude-ParallelProcessor-Original, Unity-Claude-Cache-Original, Unity-Claude-IPC-Bidirectional-Fixed, ModuleFunctions, Unity-Claude-Cache, PaginationProvider, Unity-Claude-PerformanceOptimizer-Refactored, Performance-Cache, GraphOptimizer, MemoryManager, QueueManagement, Unity-Claude-IncrementalProcessor-Fixed, BatchProcessingEngine, ProgressTracker, CommandExecutionEngine, Unity-Claude-ScalabilityEnhancements-Original, Unity-Claude-Cache-Fixed, Unity-Claude-IPC-Bidirectional, Unity-Claude-ScalabilityEnhancements-Refactored

--- 
### Unity-Claude-ScalabilityEnhancements-Original

[⬆ Back to Contents](#-table-of-contents)

Unity Editor integration providing direct communication with Unity processes. Monitors compilation, extracts errors, and manages project operations.

**Key Capabilities:** process initiation, cleanup operations, specialized operations, data retrieval

**Module Statistics:**
- Functions: 34
- Lines of Code: 1582
- Classes: 6
- Exported Members: 1


**Module Details:**
- **Path:** `Modules\Unity-Claude-ScalabilityEnhancements\Unity-Claude-ScalabilityEnhancements-Original.psm1`
- **Size:** 48.16 KB
- **Functions:** 70
- **Last Modified:** 2025-08-26 11:46

**Dependencies:** CPG-DataStructures, CrossLanguage-DependencyMaps, Unity-Claude-PerformanceOptimizer-Original, JobScheduler, Unity-Claude-IncrementalProcessor, BackgroundJobQueue, CPG-Unified, HorizontalScaling, Unity-Claude-ParallelProcessor-Original, RunspacePoolManager, Unity-Claude-Cache-Original, Unity-Claude-IPC-Bidirectional-Fixed, StatisticsTracker, ModuleFunctions, Unity-Claude-Cache, PaginationProvider, Unity-Claude-PerformanceOptimizer-Refactored, Performance-Cache, GraphOptimizer, MemoryManager, QueueManagement, Unity-Claude-CPG-Original, Unity-Claude-IncrementalProcessor-Fixed, BatchProcessingEngine, ProgressTracker, CommandExecutionEngine, Unity-Claude-Cache-Fixed, Unity-Claude-IPC-Bidirectional

--- 
### Unity-Claude-ScalabilityEnhancements-Refactored

[⬆ Back to Contents](#-table-of-contents)

Unity Editor integration providing direct communication with Unity processes. Monitors compilation, extracts errors, and manages project operations.

**Key Capabilities:** system initialization, validation and testing, data retrieval, specialized operations

**Module Statistics:**
- Functions: 4
- Lines of Code: 428
- Exported Members: 1


**Module Details:**
- **Path:** `Modules\Unity-Claude-ScalabilityEnhancements\Unity-Claude-ScalabilityEnhancements-Refactored.psm1`
- **Size:** 16.67 KB
- **Functions:** 4
- **Last Modified:** 2025-08-26 11:46

**Dependencies:** Unity-Claude-PerformanceOptimizer-Original, Unity-Claude-IncrementalProcessor, BackgroundJobQueue, HorizontalScaling, Unity-Claude-ParallelProcessor-Original, Unity-Claude-Cache-Original, Unity-Claude-IPC-Bidirectional-Fixed, ModuleFunctions, Unity-Claude-Cache, PaginationProvider, Unity-Claude-PerformanceOptimizer-Refactored, Performance-Cache, GraphOptimizer, MemoryManager, QueueManagement, Unity-Claude-IncrementalProcessor-Fixed, BatchProcessingEngine, ProgressTracker, CommandExecutionEngine, Unity-Claude-ScalabilityEnhancements-Original, Unity-Claude-Cache-Fixed, Unity-Claude-ScalabilityEnhancements, Unity-Claude-IPC-Bidirectional

--- 
### Unity-Claude-ScalabilityOptimizer

[⬆ Back to Contents](#-table-of-contents)

Unity Editor integration providing direct communication with Unity processes. Monitors compilation, extracts errors, and manages project operations.

**Key Capabilities:** system initialization, process initiation

**Module Statistics:**
- Functions: 17
- Lines of Code: 1007
- Exported Members: 1


**Module Details:**
- **Path:** `Modules\Unity-Claude-ScalabilityOptimizer\Unity-Claude-ScalabilityOptimizer.psm1`
- **Size:** 37.82 KB
- **Functions:** 17
- **Last Modified:** 2025-08-30 20:31

**Dependencies:** Unity-Claude-PerformanceOptimizer-Original, Unity-Claude-IncrementalProcessor, Unity-Claude-ParallelProcessor-Original, Unity-Claude-Cache-Original, ModuleFunctions, Unity-Claude-Cache, Unity-Claude-PerformanceOptimizer-Refactored, Performance-Cache, PerformanceMonitoring, Unity-Claude-IncrementalProcessor-Fixed, BatchProcessingEngine, Unity-Claude-PerformanceOptimizer, PerformanceOptimizer, Unity-Claude-AutonomousStateTracker, Unity-Claude-Cache-Fixed, Unity-Claude-DocumentationQualityOrchestrator, Unity-Claude-MultiStepOrchestrator

--- 
### Unity-Claude-SemanticAnalysis

[⬆ Back to Contents](#-table-of-contents)

Unity Editor integration providing direct communication with Unity processes. Monitors compilation, extracts errors, and manages project operations.

**Key Capabilities:** specialized operations

**Module Statistics:**
- Functions: 3
- Lines of Code: 234
- Exported Members: 1


**Module Details:**
- **Path:** `Modules\Unity-Claude-CPG\Unity-Claude-SemanticAnalysis.psm1`
- **Size:** 8.38 KB
- **Functions:** 3
- **Last Modified:** 2025-08-25 02:21

**Dependencies:** CPG-DataStructures, CrossLanguage-DependencyMaps, Unity-Claude-SemanticAnalysis-Quality, Unity-Claude-SemanticAnalysis-Metrics, CPG-Unified, Unity-Claude-SemanticAnalysis-Old, Unity-Claude-Cache-Original, LLM-ResponseCache, Unity-Claude-Cache, Predictive-Maintenance, Unity-Claude-SemanticAnalysis-Architecture, Performance-Cache, Unity-Claude-SemanticAnalysis-New, Unity-Claude-CPG-ASTConverter, Unity-Claude-SemanticAnalysis-Purpose, Unity-Claude-CPG, Unity-Claude-CPG-Original, CPG-BasicOperations, Unity-Claude-SemanticAnalysis-Business, PerformanceOptimizer, Unity-Claude-SemanticAnalysis-Patterns, Unity-Claude-SemanticAnalysis-Helpers, Unity-Claude-CPG-Refactored, Unity-Claude-Cache-Fixed, Unity-Claude-DocumentationPipeline

--- 
### Unity-Claude-SemanticAnalysis-Architecture

[⬆ Back to Contents](#-table-of-contents)

Unity Editor integration providing direct communication with Unity processes. Monitors compilation, extracts errors, and manages project operations.

**Key Capabilities:** specialized operations

**Module Statistics:**
- Functions: 5
- Lines of Code: 388
- Classes: 2
- Exported Members: 1


**Module Details:**
- **Path:** `Modules\Unity-Claude-CPG\Unity-Claude-SemanticAnalysis-Architecture.psm1`
- **Size:** 13.45 KB
- **Functions:** 5
- **Last Modified:** 2025-08-25 02:21

**Dependencies:** CPG-DataStructures, CPG-Unified, Unity-Claude-ParallelProcessor-Original, Unity-Claude-Cache-Original, LLM-ResponseCache, ModuleFunctions, Unity-Claude-Cache, Performance-Cache, Unity-Claude-CPG-Original, CPG-QueryOperations, PerformanceOptimizer, Unity-Claude-SemanticAnalysis-Helpers, Unity-Claude-Cache-Fixed

--- 
### Unity-Claude-SemanticAnalysis-Business

[⬆ Back to Contents](#-table-of-contents)

Unity Editor integration providing direct communication with Unity processes. Monitors compilation, extracts errors, and manages project operations.

**Key Capabilities:** specialized operations

**Module Statistics:**
- Functions: 9
- Lines of Code: 455
- Exported Members: 1


**Module Details:**
- **Path:** `Modules\Unity-Claude-CPG\Unity-Claude-SemanticAnalysis-Business.psm1`
- **Size:** 15.91 KB
- **Functions:** 5
- **Last Modified:** 2025-08-25 02:21

**Dependencies:** CPG-DataStructures, Unity-Claude-PerformanceOptimizer-Original, Unity-Claude-IncrementalProcessor, CPG-Unified, Unity-Claude-ParallelProcessor-Original, Unity-Claude-Cache-Original, LLM-ResponseCache, ModuleFunctions, Unity-Claude-Cache, Unity-Claude-PerformanceOptimizer-Refactored, Performance-Cache, Unity-Claude-CPG-Original, Unity-Claude-IncrementalProcessor-Fixed, CPG-QueryOperations, BatchProcessingEngine, PerformanceOptimizer, Unity-Claude-SemanticAnalysis-Helpers, Unity-Claude-Cache-Fixed

--- 
### Unity-Claude-SemanticAnalysis-Helpers

[⬆ Back to Contents](#-table-of-contents)

Unity Editor integration providing direct communication with Unity processes. Monitors compilation, extracts errors, and manages project operations.

**Key Capabilities:** validation and testing, specialized operations, data retrieval

**Module Statistics:**
- Functions: 13
- Lines of Code: 601
- Classes: 1
- Exported Members: 1


**Module Details:**
- **Path:** `Modules\Unity-Claude-CPG\Unity-Claude-SemanticAnalysis-Helpers.psm1`
- **Size:** 20.93 KB
- **Functions:** 13
- **Last Modified:** 2025-08-25 02:21

**Dependencies:** CPG-DataStructures, CrossLanguage-DependencyMaps, CPG-Unified, Unity-Claude-Cache-Original, LLM-ResponseCache, Unity-Claude-Cache, Performance-Cache, Unity-Claude-SemanticAnalysis-Purpose, Unity-Claude-CPG-Original, CPG-QueryOperations, PerformanceOptimizer, Unity-Claude-SemanticAnalysis-Patterns, Unity-Claude-Cache-Fixed

--- 
### Unity-Claude-SemanticAnalysis-Metrics

[⬆ Back to Contents](#-table-of-contents)

Unity Editor integration providing direct communication with Unity processes. Monitors compilation, extracts errors, and manages project operations.

**Key Capabilities:** data retrieval, specialized operations

**Module Statistics:**
- Functions: 5
- Lines of Code: 401
- Exported Members: 1


**Module Details:**
- **Path:** `Modules\Unity-Claude-CPG\Unity-Claude-SemanticAnalysis-Metrics.psm1`
- **Size:** 13.13 KB
- **Functions:** 5
- **Last Modified:** 2025-08-25 02:21

**Dependencies:** CPG-DataStructures, CPG-Unified, Unity-Claude-ParallelProcessor-Original, Unity-Claude-Cache-Original, LLM-ResponseCache, ModuleFunctions, Unity-Claude-Cache, Performance-Cache, Unity-Claude-CPG-Original, CPG-QueryOperations, PerformanceOptimizer, Unity-Claude-SemanticAnalysis-Helpers, Unity-Claude-Cache-Fixed, Unity-Claude-DocumentationPipeline

--- 
### Unity-Claude-SemanticAnalysis-New

[⬆ Back to Contents](#-table-of-contents)

Unity Editor integration providing direct communication with Unity processes. Monitors compilation, extracts errors, and manages project operations.

**Key Capabilities:** specialized operations

**Module Statistics:**
- Functions: 3
- Lines of Code: 234
- Exported Members: 1


**Module Details:**
- **Path:** `Modules\Unity-Claude-CPG\Unity-Claude-SemanticAnalysis-New.psm1`
- **Size:** 8.38 KB
- **Functions:** 3
- **Last Modified:** 2025-08-25 02:21

**Dependencies:** CPG-DataStructures, CrossLanguage-DependencyMaps, Unity-Claude-SemanticAnalysis-Quality, Unity-Claude-SemanticAnalysis-Metrics, CPG-Unified, Unity-Claude-SemanticAnalysis-Old, Unity-Claude-SemanticAnalysis, Unity-Claude-Cache-Original, LLM-ResponseCache, Unity-Claude-Cache, Predictive-Maintenance, Unity-Claude-SemanticAnalysis-Architecture, Performance-Cache, Unity-Claude-CPG-ASTConverter, Unity-Claude-SemanticAnalysis-Purpose, Unity-Claude-CPG, Unity-Claude-CPG-Original, CPG-BasicOperations, Unity-Claude-SemanticAnalysis-Business, PerformanceOptimizer, Unity-Claude-SemanticAnalysis-Patterns, Unity-Claude-SemanticAnalysis-Helpers, Unity-Claude-CPG-Refactored, Unity-Claude-Cache-Fixed, Unity-Claude-DocumentationPipeline

--- 
### Unity-Claude-SemanticAnalysis-Old

[⬆ Back to Contents](#-table-of-contents)

Unity Editor integration providing direct communication with Unity processes. Monitors compilation, extracts errors, and manages project operations.

**Key Capabilities:** specialized operations

**Module Statistics:**
- Functions: 3
- Lines of Code: 234
- Exported Members: 1


**Module Details:**
- **Path:** `Modules\Unity-Claude-CPG\Unity-Claude-SemanticAnalysis-Old.psm1`
- **Size:** 8.38 KB
- **Functions:** 3
- **Last Modified:** 2025-08-25 02:21

**Dependencies:** CPG-DataStructures, CrossLanguage-DependencyMaps, Unity-Claude-SemanticAnalysis-Quality, Unity-Claude-SemanticAnalysis-Metrics, CPG-Unified, Unity-Claude-SemanticAnalysis, Unity-Claude-Cache-Original, LLM-ResponseCache, Unity-Claude-Cache, Predictive-Maintenance, Unity-Claude-SemanticAnalysis-Architecture, Performance-Cache, Unity-Claude-SemanticAnalysis-New, Unity-Claude-CPG-ASTConverter, Unity-Claude-SemanticAnalysis-Purpose, Unity-Claude-CPG, Unity-Claude-CPG-Original, CPG-BasicOperations, Unity-Claude-SemanticAnalysis-Business, PerformanceOptimizer, Unity-Claude-SemanticAnalysis-Patterns, Unity-Claude-SemanticAnalysis-Helpers, Unity-Claude-CPG-Refactored, Unity-Claude-Cache-Fixed, Unity-Claude-DocumentationPipeline

--- 
### Unity-Claude-SemanticAnalysis-Patterns

[⬆ Back to Contents](#-table-of-contents)

Unity Editor integration providing direct communication with Unity processes. Monitors compilation, extracts errors, and manages project operations.

**Key Capabilities:** specialized operations

**Module Statistics:**
- Functions: 8
- Lines of Code: 517
- Classes: 4
- Exported Members: 1


**Module Details:**
- **Path:** `Modules\Unity-Claude-CPG\Unity-Claude-SemanticAnalysis-Patterns.psm1`
- **Size:** 19.41 KB
- **Functions:** 8
- **Last Modified:** 2025-08-25 02:21

**Dependencies:** CPG-DataStructures, CPG-Unified, Unity-Claude-ParallelProcessor-Original, Unity-Claude-Cache-Original, ModuleFunctions, Unity-Claude-Cache, Performance-Cache, Unity-Claude-CPG-Original, CPG-QueryOperations, Unity-Claude-SemanticAnalysis-Helpers, Unity-Claude-Cache-Fixed

--- 
### Unity-Claude-SemanticAnalysis-Purpose

[⬆ Back to Contents](#-table-of-contents)

Unity Editor integration providing direct communication with Unity processes. Monitors compilation, extracts errors, and manages project operations.

**Key Capabilities:** data retrieval, specialized operations

**Module Statistics:**
- Functions: 4
- Lines of Code: 406
- Classes: 3
- Exported Members: 1


**Module Details:**
- **Path:** `Modules\Unity-Claude-CPG\Unity-Claude-SemanticAnalysis-Purpose.psm1`
- **Size:** 14.99 KB
- **Functions:** 3
- **Last Modified:** 2025-08-25 02:21

**Dependencies:** CPG-DataStructures, Unity-Claude-PerformanceOptimizer-Original, Unity-Claude-IncrementalProcessor, CPG-Unified, Unity-Claude-ParallelProcessor-Original, Unity-Claude-Cache-Original, LLM-ResponseCache, ModuleFunctions, Unity-Claude-Cache, Unity-Claude-PerformanceOptimizer-Refactored, Performance-Cache, Unity-Claude-CPG-Original, Unity-Claude-IncrementalProcessor-Fixed, CPG-QueryOperations, BatchProcessingEngine, PerformanceOptimizer, Unity-Claude-SemanticAnalysis-Helpers, Unity-Claude-Cache-Fixed

--- 
### Unity-Claude-SemanticAnalysis-Quality

[⬆ Back to Contents](#-table-of-contents)

Unity Editor integration providing direct communication with Unity processes. Monitors compilation, extracts errors, and manages project operations.

**Key Capabilities:** validation and testing, specialized operations

**Module Statistics:**
- Functions: 13
- Lines of Code: 685
- Classes: 7
- Exported Members: 1


**Module Details:**
- **Path:** `Modules\Unity-Claude-CPG\Unity-Claude-SemanticAnalysis-Quality.psm1`
- **Size:** 21.63 KB
- **Functions:** 8
- **Last Modified:** 2025-08-25 02:21

**Dependencies:** CPG-DataStructures, Unity-Claude-PerformanceOptimizer-Original, Unity-Claude-IncrementalProcessor, CPG-Unified, Unity-Claude-ParallelProcessor-Original, Unity-Claude-Cache-Original, LLM-ResponseCache, ModuleFunctions, Unity-Claude-Cache, Predictive-Maintenance, Unity-Claude-PerformanceOptimizer-Refactored, Performance-Cache, Unity-Claude-CPG-Original, Unity-Claude-IncrementalProcessor-Fixed, CPG-QueryOperations, BatchProcessingEngine, PerformanceOptimizer, Unity-Claude-SemanticAnalysis-Helpers, Unity-Claude-Cache-Fixed

--- 
### Unity-Claude-SessionManager

[⬆ Back to Contents](#-table-of-contents)

Unity Editor integration providing direct communication with Unity processes. Monitors compilation, extracts errors, and manages project operations.

**Key Capabilities:** specialized operations, resource creation, data retrieval

**Module Statistics:**
- Functions: 18
- Lines of Code: 792
- Exported Members: 1


**Module Details:**
- **Path:** `Modules\Unity-Claude-SessionManager.psm1`
- **Size:** 26.48 KB
- **Functions:** 18
- **Last Modified:** 2025-08-20 17:25

**Dependencies:** CPG-DataStructures, CrossLanguage-DependencyMaps, Unity-Claude-PerformanceOptimizer-Original, Unity-Claude-IncrementalProcessor, CPG-Unified, Unity-Claude-ParallelProcessor-Original, Unity-Claude-Cache-Original, Unity-Claude-Cache, Unity-Claude-PerformanceOptimizer-Refactored, Performance-Cache, Unity-Claude-CPG-Original, Unity-Claude-IncrementalProcessor-Fixed, BatchProcessingEngine, Unity-Claude-Cache-Fixed

--- 
### Unity-Claude-SlackIntegration

[⬆ Back to Contents](#-table-of-contents)

Unity Editor integration providing direct communication with Unity processes. Monitors compilation, extracts errors, and manages project operations.

**Key Capabilities:** system initialization, specialized operations

**Module Statistics:**
- Functions: 10
- Lines of Code: 610
- Exported Members: 1


**Module Details:**
- **Path:** `Modules\Unity-Claude-SlackIntegration\Unity-Claude-SlackIntegration.psm1`
- **Size:** 18.86 KB
- **Functions:** 10
- **Last Modified:** 2025-08-30 14:31

**Dependencies:** CPG-DataStructures, CrossLanguage-DependencyMaps, Unity-Claude-PerformanceOptimizer-Original, Unity-Claude-IncrementalProcessor, CPG-Unified, Unity-Claude-ParallelProcessor-Original, Unity-Claude-Cache-Original, ModuleFunctions, Unity-Claude-Cache, Unity-Claude-PerformanceOptimizer-Refactored, Performance-Cache, Unity-Claude-CPG-Original, Unity-Claude-IncrementalProcessor-Fixed, BatchProcessingEngine, Unity-Claude-Cache-Fixed

--- 
### Unity-Claude-SystemCoordinator

[⬆ Back to Contents](#-table-of-contents)

Unity Editor integration providing direct communication with Unity processes. Monitors compilation, extracts errors, and manages project operations.

**Key Capabilities:** system initialization, specialized operations, data retrieval

**Module Statistics:**
- Functions: 24
- Lines of Code: 1103
- Exported Members: 1


**Module Details:**
- **Path:** `Modules\Unity-Claude-SystemCoordinator\Unity-Claude-SystemCoordinator.psm1`
- **Size:** 40.22 KB
- **Functions:** 21
- **Last Modified:** 2025-08-30 20:21

**Dependencies:** CPG-DataStructures, Unity-Claude-DocumentationAnalytics, CrossLanguage-DependencyMaps, Unity-Claude-PerformanceOptimizer-Original, Unity-Claude-IncrementalProcessor, CPG-Unified, Unity-Claude-ConcurrentProcessor, Unity-Claude-ParallelProcessor-Original, MetricsCollection, Unity-Claude-Cache-Original, ModuleFunctions, Unity-Claude-Cache, MetricsAndHealthCheck, Unity-Claude-PerformanceOptimizer-Refactored, Performance-Cache, PerformanceMonitoring, Unity-Claude-CPG-Original, Unity-Claude-IncrementalProcessor-Fixed, Unity-Claude-DocumentationDrift, Unity-Claude-ResponseMonitor, BatchProcessingEngine, Unity-Claude-PerformanceOptimizer, Unity-Claude-ScalabilityOptimizer, Unity-Claude-AutonomousStateTracker, Unity-Claude-Cache-Fixed, Unity-Claude-DocumentationQualityOrchestrator, FileSystemMonitoring

--- 
### Unity-Claude-SystemStatus

[⬆ Back to Contents](#-table-of-contents)

Unity Editor integration providing direct communication with Unity processes. Monitors compilation, extracts errors, and manages project operations.

**Module Statistics:**
- Functions: 0
- Lines of Code: 74
- Exported Members: 1


**Module Details:**
- **Path:** `Modules\Unity-Claude-SystemStatus\Unity-Claude-SystemStatus.psm1`
- **Size:** 5.03 KB
- **Functions:** 0
- **Last Modified:** 2025-08-26 21:41

**Dependencies:** Unity-Claude-PerformanceOptimizer-Original, Unity-Claude-IncrementalProcessor, Unity-Claude-ParallelProcessor-Original, Unity-Claude-Cache-Original, ModuleFunctions, Unity-Claude-Cache, AgentLogging, Unity-Claude-PerformanceOptimizer-Refactored, Performance-Cache, Unity-Claude-IncrementalProcessor-Fixed, Unity-Claude-ResourceOptimizer, Unity-Claude-GitHub, BatchProcessingEngine, Unity-Claude-MessageQueue, Unity-Claude-Cache-Fixed

--- 
### Unity-Claude-TeamsIntegration

[⬆ Back to Contents](#-table-of-contents)

Unity Editor integration providing direct communication with Unity processes. Monitors compilation, extracts errors, and manages project operations.

**Key Capabilities:** system initialization, validation and testing, specialized operations

**Module Statistics:**
- Functions: 11
- Lines of Code: 691
- Exported Members: 1


**Module Details:**
- **Path:** `Modules\Unity-Claude-TeamsIntegration\Unity-Claude-TeamsIntegration.psm1`
- **Size:** 22.77 KB
- **Functions:** 11
- **Last Modified:** 2025-08-30 14:32

**Dependencies:** CPG-DataStructures, CrossLanguage-DependencyMaps, Unity-Claude-PerformanceOptimizer-Original, Unity-Claude-IncrementalProcessor, CPG-Unified, Unity-Claude-ParallelProcessor-Original, Unity-Claude-Cache-Original, ModuleFunctions, Unity-Claude-Cache, Unity-Claude-PerformanceOptimizer-Refactored, Performance-Cache, Unity-Claude-CPG-Original, Unity-Claude-IncrementalProcessor-Fixed, BatchProcessingEngine, Unity-Claude-Cache-Fixed

--- 
### Unity-Claude-TreeSitter

[⬆ Back to Contents](#-table-of-contents)

Unity Editor integration providing direct communication with Unity processes. Monitors compilation, extracts errors, and manages project operations.

**Key Capabilities:** system initialization, specialized operations, action execution

**Module Statistics:**
- Functions: 12
- Lines of Code: 633
- Exported Members: 1


**Module Details:**
- **Path:** `Modules\Unity-Claude-CPG\Unity-Claude-TreeSitter.psm1`
- **Size:** 19.96 KB
- **Functions:** 10
- **Last Modified:** 2025-08-24 23:42

**Dependencies:** CPG-DataStructures, CrossLanguage-DependencyMaps, Unity-Claude-PerformanceOptimizer-Original, Unity-Claude-IncrementalProcessor, CPG-Unified, Unity-Claude-ParallelProcessor-Original, TreeSitter-CSTConverter, Unity-Claude-Cache-Original, ModuleFunctions, Unity-Claude-Cache, Unity-Claude-PerformanceOptimizer-Refactored, Performance-Cache, Unity-Claude-CPG-Original, Unity-Claude-IncrementalProcessor-Fixed, CPG-BasicOperations, BatchProcessingEngine, Unity-Claude-Cache-Fixed

--- 
### Unity-Claude-TriggerConditions

[⬆ Back to Contents](#-table-of-contents)

Unity Editor integration providing direct communication with Unity processes. Monitors compilation, extracts errors, and manages project operations.

**Key Capabilities:** system initialization, validation and testing, specialized operations, data retrieval, process initiation

**Module Statistics:**
- Functions: 8
- Lines of Code: 758
- Classes: 1
- Exported Members: 1


**Module Details:**
- **Path:** `Modules\Unity-Claude-DocumentationDrift\Unity-Claude-TriggerConditions.psm1`
- **Size:** 27.5 KB
- **Functions:** 7
- **Last Modified:** 2025-08-24 12:06

**Dependencies:** Unity-Claude-PerformanceOptimizer-Original, Unity-Claude-IncrementalProcessor, Unity-Claude-ParallelProcessor-Original, Unity-Claude-Cache-Original, ModuleFunctions, Unity-Claude-Cache, Unity-Claude-PerformanceOptimizer-Refactored, Performance-Cache, Unity-Claude-IncrementalProcessor-Fixed, Unity-Claude-DocumentationDrift, BatchProcessingEngine, Unity-Claude-Cache-Fixed

--- 
### Unity-Claude-TriggerIntegration

[⬆ Back to Contents](#-table-of-contents)

Unity Editor integration providing direct communication with Unity processes. Monitors compilation, extracts errors, and manages project operations.

**Key Capabilities:** system initialization, specialized operations, process initiation, process termination

**Module Statistics:**
- Functions: 8
- Lines of Code: 622
- Exported Members: 1


**Module Details:**
- **Path:** `Modules\Unity-Claude-DocumentationDrift\Unity-Claude-TriggerIntegration.psm1`
- **Size:** 23.33 KB
- **Functions:** 8
- **Last Modified:** 2025-08-24 12:06

**Dependencies:** Unity-Claude-TriggerConditions, CPG-DataStructures, CrossLanguage-DependencyMaps, Unity-Claude-PerformanceOptimizer-Original, JobScheduler, Unity-Claude-IncrementalProcessor, CPG-Unified, Unity-Claude-ParallelProcessor-Original, RunspacePoolManager, Unity-Claude-Cache-Original, StatisticsTracker, ModuleFunctions, Unity-Claude-Cache, Unity-Claude-PerformanceOptimizer-Refactored, Performance-Cache, Unity-Claude-CPG-Original, Unity-Claude-IncrementalProcessor-Fixed, Unity-Claude-DocumentationDrift, BatchProcessingEngine, Configuration, Unity-Claude-Cache-Fixed

--- 
### Unity-Claude-TriggerManager

[⬆ Back to Contents](#-table-of-contents)

Unity Editor integration providing direct communication with Unity processes. Monitors compilation, extracts errors, and manages project operations.

**Key Capabilities:** system initialization, validation and testing, specialized operations

**Module Statistics:**
- Functions: 25
- Lines of Code: 568
- Exported Members: 1


**Module Details:**
- **Path:** `Modules\Unity-Claude-FileMonitor\Unity-Claude-TriggerManager.psm1`
- **Size:** 19.18 KB
- **Functions:** 25
- **Last Modified:** 2025-08-24 12:06

**Dependencies:** Unity-Claude-PerformanceOptimizer-Original, Unity-Claude-IncrementalProcessor, Unity-Claude-MasterOrchestrator-Original, Unity-Claude-DocumentationCrossReference, Unity-Claude-ParallelProcessor-Original, SemanticAnalysis-PatternDetector, Unity-Claude-Cache-Original, ModuleFunctions, Unity-Claude-Cache, Unity-Claude-PerformanceOptimizer-Refactored, Performance-Cache, Unity-Claude-IncrementalProcessor-Fixed, Unity-Claude-LLM, BatchProcessingEngine, TriggerSystem, Unity-Claude-Cache-Fixed, Unity-Claude-DocumentationAutomation-Original

--- 
### Unity-Claude-UnityParallelization

[⬆ Back to Contents](#-table-of-contents)

High-performance parallel processing module for concurrent operations. Manages thread pools, runspace allocation, and synchronization primitives. Unity Editor integration providing direct communication with Unity processes. Monitors compilation, extracts errors, and manages project operations. 

**Key Capabilities:** data retrieval, specialized operations 

**Module Statistics:**
 - Functions: 2
 - Lines of Code: 263
 - Exported Members: 1


**Module Details:**
- **Path:** `Modules\Unity-Claude-UnityParallelization\Unity-Claude-UnityParallelization.psm1`
- **Size:** 10.72 KB
- **Functions:** 2
- **Last Modified:** 2025-08-26 11:46

**Dependencies:** Unity-Claude-UnityParallelization-Original, Unity-Claude-PerformanceOptimizer-Original, UnityProjectOperations, Unity-Claude-IncrementalProcessor, Unity-Claude-ParallelProcessor-Original, Unity-Claude-Cache-Original, ModuleFunctions, Unity-Claude-Cache, Unity-Claude-PerformanceOptimizer-Refactored, Performance-Cache, ErrorDetection, ProductionRunspacePool, Unity-Claude-IncrementalProcessor-Fixed, Unity-Claude-UnityParallelization-Refactored, ErrorExport, BatchProcessingEngine, CompilationIntegration, ParallelizationCore, Unity-Claude-Cache-Fixed, ParallelMonitoring, Unity-Claude-RunspaceManagement-Original, SafeCommandExecution-Original, ProjectConfiguration

--- 
### Unity-Claude-UnityParallelization-Original

[⬆ Back to Contents](#-table-of-contents)

High-performance parallel processing module for concurrent operations. Manages thread pools, runspace allocation, and synchronization primitives. Unity Editor integration providing direct communication with Unity processes. Monitors compilation, extracts errors, and manages project operations. 

**Key Capabilities:** validation and testing, specialized operations 

**Module Statistics:**
 - Functions: 23
 - Lines of Code: 2095
 - Exported Members: 1


**Module Details:**
- **Path:** `Modules\Unity-Claude-UnityParallelization\Unity-Claude-UnityParallelization-Original.psm1`
- **Size:** 86.33 KB
- **Functions:** 22
- **Last Modified:** 2025-08-26 11:46

**Dependencies:** CPG-DataStructures, CrossLanguage-DependencyMaps, Unity-Claude-PerformanceOptimizer-Original, JobScheduler, Unity-Claude-IncrementalProcessor, CPG-Unified, EntityContextEngine, Unity-Claude-ParallelProcessor-Original, MetricsCollection, RunspacePoolManager, Unity-Claude-Cache-Original, StatisticsTracker, ModuleFunctions, Unity-Claude-Cache, Unity-Claude-CrossLanguage, SelfPatching, RunspaceCore, DependencyManagement, Unity-Claude-PerformanceOptimizer-Refactored, Performance-Cache, ErrorDetection, ProductionRunspacePool, ModuleVariablePreloading, Unity-Claude-Learning-Original, RunspacePoolManagement, Unity-Claude-CPG-Original, Unity-Claude-ClaudeParallelization, Unity-Claude-IncrementalProcessor-Fixed, SessionStateConfiguration, Unity-Claude-Learning-Simple, ErrorExport, BatchProcessingEngine, CompilationIntegration, StringSimilarity, SuccessTracking, ParallelizationCore, UnityIntegration, Unity-Claude-Cache-Fixed, ParallelMonitoring, Unity-Claude-AIAlertClassifier, Unity-Claude-RunspaceManagement-Original, Unity-Claude-IntegratedWorkflow-Original, VariableSharing, ProjectConfiguration, ThrottlingResourceControl

--- 
### Unity-Claude-UnityParallelization-Refactored

[⬆ Back to Contents](#-table-of-contents)

High-performance parallel processing module for concurrent operations. Manages thread pools, runspace allocation, and synchronization primitives. Unity Editor integration providing direct communication with Unity processes. Monitors compilation, extracts errors, and manages project operations. 

**Key Capabilities:** data retrieval, specialized operations 

**Module Statistics:**
 - Functions: 2
 - Lines of Code: 263
 - Exported Members: 1


**Module Details:**
- **Path:** `Modules\Unity-Claude-UnityParallelization\Unity-Claude-UnityParallelization-Refactored.psm1`
- **Size:** 10.72 KB
- **Functions:** 2
- **Last Modified:** 2025-08-26 11:46

**Dependencies:** Unity-Claude-UnityParallelization-Original, Unity-Claude-PerformanceOptimizer-Original, UnityProjectOperations, Unity-Claude-IncrementalProcessor, Unity-Claude-ParallelProcessor-Original, Unity-Claude-Cache-Original, ModuleFunctions, Unity-Claude-Cache, Unity-Claude-UnityParallelization, Unity-Claude-PerformanceOptimizer-Refactored, Performance-Cache, ErrorDetection, ProductionRunspacePool, Unity-Claude-IncrementalProcessor-Fixed, ErrorExport, BatchProcessingEngine, CompilationIntegration, ParallelizationCore, Unity-Claude-Cache-Fixed, ParallelMonitoring, Unity-Claude-RunspaceManagement-Original, SafeCommandExecution-Original, ProjectConfiguration

--- 
### Unity-Claude-WebhookNotifications

[⬆ Back to Contents](#-table-of-contents)

Unity Editor integration providing direct communication with Unity processes. Monitors compilation, extracts errors, and manages project operations.

**Key Capabilities:** resource creation, validation and testing, action execution, data retrieval

**Module Statistics:**
- Functions: 11
- Lines of Code: 1002
- Exported Members: 1


**Module Details:**
- **Path:** `Modules\Unity-Claude-WebhookNotifications\Unity-Claude-WebhookNotifications.psm1`
- **Size:** 40.8 KB
- **Functions:** 11
- **Last Modified:** 2025-08-21 17:45

**Dependencies:** CPG-DataStructures, CrossLanguage-DependencyMaps, Unity-Claude-PerformanceOptimizer-Original, Unity-Claude-IncrementalProcessor, CPG-Unified, Unity-Claude-ParallelProcessor-Original, Unity-Claude-Cache-Original, ModuleFunctions, Unity-Claude-Cache, Unity-Claude-PerformanceOptimizer-Refactored, Performance-Cache, Unity-Claude-CPG-Original, Unity-Claude-IncrementalProcessor-Fixed, BatchProcessingEngine, Unity-Claude-Cache-Fixed

--- 
### Unity-Claude-WindowDetection

[⬆ Back to Contents](#-table-of-contents)

Unity Editor integration providing direct communication with Unity processes. Monitors compilation, extracts errors, and manages project operations.

**Key Capabilities:** data retrieval, validation and testing, specialized operations

**Module Statistics:**
- Functions: 5
- Lines of Code: 415
- Classes: 1
- Exported Members: 1


**Module Details:**
- **Path:** `Modules\Unity-Claude-WindowDetection.psm1`
- **Size:** 15.24 KB
- **Functions:** 5
- **Last Modified:** 2025-08-20 17:25

**Dependencies:** CPG-DataStructures, CrossLanguage-DependencyMaps, Unity-Claude-PerformanceOptimizer-Original, Unity-Claude-IncrementalProcessor, CPG-Unified, Unity-Claude-ParallelProcessor-Original, Unity-Claude-Cache-Original, Unity-Claude-Cache, Unity-Claude-PerformanceOptimizer-Refactored, Performance-Cache, Unity-Claude-CPG-Original, Unity-Claude-IncrementalProcessor-Fixed, BatchProcessingEngine, Unity-Claude-Cache-Fixed

--- 
### Unity-Claude-WindowDetection-Enhanced

[⬆ Back to Contents](#-table-of-contents)

Unity Editor integration providing direct communication with Unity processes. Monitors compilation, extracts errors, and manages project operations.

**Key Capabilities:** specialized operations

**Module Statistics:**
- Functions: 2
- Lines of Code: 179
- Exported Members: 1


**Module Details:**
- **Path:** `Modules\Unity-Claude-WindowDetection-Enhanced.psm1`
- **Size:** 9.34 KB
- **Functions:** 3
- **Last Modified:** 2025-08-20 17:25

**Dependencies:** Unity-Claude-Cache-Original, Unity-Claude-Cache, Unity-Claude-WindowDetection, Performance-Cache, Unity-Claude-Cache-Fixed

--- 
### Unity-TestAutomation

[⬆ Back to Contents](#-table-of-contents)

Unity Editor integration providing direct communication with Unity processes. Monitors compilation, extracts errors, and manages project operations.

**Key Capabilities:** action execution, data retrieval, resource creation

**Module Statistics:**
- Functions: 9
- Lines of Code: 1202
- Exported Members: 1


**Module Details:**
- **Path:** `Modules\Unity-TestAutomation\Unity-TestAutomation.psm1`
- **Size:** 41.42 KB
- **Functions:** 9
- **Last Modified:** 2025-08-20 17:25

**Dependencies:** CPG-DataStructures, CrossLanguage-DependencyMaps, Unity-Claude-PerformanceOptimizer-Original, Unity-Claude-IncrementalProcessor, CPG-Unified, Unity-Claude-ParallelProcessor-Original, CommandExecution, Unity-Claude-Cache-Original, ModuleFunctions, Unity-Claude-Cache, Unity-Claude-PerformanceOptimizer-Refactored, Performance-Cache, Unity-Claude-CPG-Original, Unity-Claude-IncrementalProcessor-Fixed, BatchProcessingEngine, Unity-Claude-Cache-Fixed, SafeCommandExecution-Original, UnityCommands

--- 
### UnityBuildOperations

[⬆ Back to Contents](#-table-of-contents)

Unity Editor integration providing direct communication with Unity processes. Monitors compilation, extracts errors, and manages project operations.

**Key Capabilities:** action execution, resource creation, validation and testing

**Module Statistics:**
- Functions: 6
- Lines of Code: 633
- Classes: 2
- Exported Members: 1


**Module Details:**
- **Path:** `Modules\SafeCommandExecution\Core\UnityBuildOperations.psm1`
- **Size:** 22.42 KB
- **Functions:** 6
- **Last Modified:** 2025-08-26 11:46

**Dependencies:** Unity-Claude-PerformanceOptimizer-Original, Unity-Claude-IncrementalProcessor, SafeExecution, Unity-Claude-ParallelProcessor-Original, Unity-Claude-Cache-Original, SafeCommandCore, Unity-Claude-Cache, ValidationEngine, Unity-Claude-PerformanceOptimizer-Refactored, Performance-Cache, Unity-Claude-IncrementalProcessor-Fixed, BatchProcessingEngine, Unity-Claude-Cache-Fixed, SafeCommandExecution-Original, UnityCommands

--- 
### UnityCommands

[⬆ Back to Contents](#-table-of-contents)

Unity Editor integration providing direct communication with Unity processes. Monitors compilation, extracts errors, and manages project operations.

**Key Capabilities:** action execution

**Module Statistics:**
- Functions: 7
- Lines of Code: 446
- Exported Members: 1


**Module Details:**
- **Path:** `Modules\Unity-Claude-AutonomousAgent\Commands\UnityCommands.psm1`
- **Size:** 15.5 KB
- **Functions:** 7
- **Last Modified:** 2025-08-20 17:25

**Dependencies:** Unity-Claude-ParallelProcessing, AgentLogging, CommandTypeHandlers, SafeCommandExecution-Original, Unity-TestAutomation

--- 
### UnityIntegration

[⬆ Back to Contents](#-table-of-contents)

Unity Editor integration providing direct communication with Unity processes. Monitors compilation, extracts errors, and manages project operations.

**Key Capabilities:** data retrieval, specialized operations, cleanup operations

**Module Statistics:**
- Functions: 6
- Lines of Code: 364
- Exported Members: 1


**Module Details:**
- **Path:** `Modules\Unity-Claude-AutonomousAgent\Integration\UnityIntegration.psm1`
- **Size:** 12.64 KB
- **Functions:** 6
- **Last Modified:** 2025-08-20 17:25

**Dependencies:** EntityContextEngine, Unity-Claude-Cache-Original, Unity-Claude-Cache, Unity-Claude-CrossLanguage, Unity-Claude-ParallelProcessing, AgentLogging, Performance-Cache, ErrorDetection, Unity-Claude-Learning-Original, Unity-Claude-Learning-Simple, ResponseMonitoring, StringSimilarity, Unity-Claude-CLISubmission-Enhanced, Unity-Claude-Cache-Fixed, Unity-Claude-AIAlertClassifier, ClaudeIntegration

--- 
### UnityLogAnalysis

[⬆ Back to Contents](#-table-of-contents)

Unity Editor integration providing direct communication with Unity processes. Monitors compilation, extracts errors, and manages project operations.

**Key Capabilities:** action execution

**Module Statistics:**
- Functions: 2
- Lines of Code: 401
- Exported Members: 1


**Module Details:**
- **Path:** `Modules\SafeCommandExecution\Core\UnityLogAnalysis.psm1`
- **Size:** 14.77 KB
- **Functions:** 2
- **Last Modified:** 2025-08-26 11:46

**Dependencies:** CPG-DataStructures, CrossLanguage-DependencyMaps, SafeExecution, CPG-Unified, Unity-Claude-Cache-Original, SafeCommandCore, Unity-Claude-Cache, ValidationEngine, Performance-Cache, Unity-Claude-CPG-Original, Unity-Claude-Cache-Fixed, SafeCommandExecution-Original

--- 
### UnityPerformanceAnalysis

[⬆ Back to Contents](#-table-of-contents)

Unity Editor integration providing direct communication with Unity processes. Monitors compilation, extracts errors, and manages project operations.

**Key Capabilities:** action execution

**Module Statistics:**
- Functions: 2
- Lines of Code: 398
- Exported Members: 1


**Module Details:**
- **Path:** `Modules\SafeCommandExecution\Core\UnityPerformanceAnalysis.psm1`
- **Size:** 15.01 KB
- **Functions:** 2
- **Last Modified:** 2025-08-26 11:46

**Dependencies:** CPG-DataStructures, CrossLanguage-DependencyMaps, Unity-Claude-PerformanceOptimizer-Original, Unity-Claude-IncrementalProcessor, CPG-Unified, Unity-Claude-ParallelProcessor-Original, Unity-Claude-Cache-Original, SafeCommandCore, Unity-Claude-Cache, Unity-Claude-PerformanceOptimizer-Refactored, Performance-Cache, Unity-Claude-CPG-Original, Unity-Claude-IncrementalProcessor-Fixed, BatchProcessingEngine, Unity-Claude-Cache-Fixed, SafeCommandExecution-Original

--- 
### UnityProjectOperations

[⬆ Back to Contents](#-table-of-contents)

Unity Editor integration providing direct communication with Unity processes. Monitors compilation, extracts errors, and manages project operations.

**Key Capabilities:** action execution, validation and testing

**Module Statistics:**
- Functions: 3
- Lines of Code: 378
- Exported Members: 1


**Module Details:**
- **Path:** `Modules\SafeCommandExecution\Core\UnityProjectOperations.psm1`
- **Size:** 14.34 KB
- **Functions:** 3
- **Last Modified:** 2025-08-26 11:46

**Dependencies:** CPG-DataStructures, CrossLanguage-DependencyMaps, Unity-Claude-PerformanceOptimizer-Original, Unity-Claude-IncrementalProcessor, SafeExecution, CPG-Unified, Unity-Claude-ParallelProcessor-Original, Unity-Claude-Cache-Original, SafeCommandCore, Unity-Claude-Cache, ValidationEngine, Unity-Claude-PerformanceOptimizer-Refactored, Performance-Cache, Unity-Claude-CPG-Original, Unity-Claude-IncrementalProcessor-Fixed, BatchProcessingEngine, CompilationIntegration, Unity-Claude-Cache-Fixed, SafeCommandExecution-Original, UnityCommands

--- 
### UnityReportingOperations

[⬆ Back to Contents](#-table-of-contents)

Unity Editor integration providing direct communication with Unity processes. Monitors compilation, extracts errors, and manages project operations.

**Key Capabilities:** action execution, specialized operations, data retrieval

**Module Statistics:**
- Functions: 3
- Lines of Code: 598
- Exported Members: 1


**Module Details:**
- **Path:** `Modules\SafeCommandExecution\Core\UnityReportingOperations.psm1`
- **Size:** 21.96 KB
- **Functions:** 3
- **Last Modified:** 2025-08-26 11:46

**Dependencies:** CPG-DataStructures, CrossLanguage-DependencyMaps, CPG-Unified, Unity-Claude-ParallelProcessor-Original, Unity-Claude-Cache-Original, SafeCommandCore, ModuleFunctions, Unity-Claude-Cache, Performance-Cache, Unity-Claude-CPG-Original, Unity-Claude-Cache-Fixed, SafeCommandExecution-Original

--- 
### ValidationEngine

[⬆ Back to Contents](#-table-of-contents)

Validation framework ensuring data integrity and operation safety. Implements schema validation, constraint checking, and error prevention.

**Key Capabilities:** validation and testing, cleanup operations

**Module Statistics:**
- Functions: 4
- Lines of Code: 335
- Exported Members: 1


**Module Details:**
- **Path:** `Modules\SafeCommandExecution\Core\ValidationEngine.psm1`
- **Size:** 11.32 KB
- **Functions:** 4
- **Last Modified:** 2025-08-26 11:46

**Dependencies:** CPG-DataStructures, CrossLanguage-DependencyMaps, Unity-Claude-PerformanceOptimizer-Original, Unity-Claude-IncrementalProcessor, SafeExecution, CPG-Unified, Unity-Claude-ParallelProcessor-Original, Unity-Claude-Cache-Original, SafeCommandCore, Unity-Claude-Cache, Unity-Claude-PerformanceOptimizer-Refactored, Performance-Cache, Unity-Claude-CPG-Original, Unity-Claude-IncrementalProcessor-Fixed, BatchProcessingEngine, Unity-Claude-Cache-Fixed, SafeCommandExecution-Original

--- 
### VariableSharing

[⬆ Back to Contents](#-table-of-contents)

Specialized module providing targeted functionality for the Unity-Claude automation system. Integrates with the broader architecture to deliver specific capabilities.

**Key Capabilities:** specialized operations, data retrieval, resource creation

**Module Statistics:**
- Functions: 13
- Lines of Code: 347
- Exported Members: 1


**Module Details:**
- **Path:** `Modules\Unity-Claude-RunspaceManagement\Core\VariableSharing.psm1`
- **Size:** 12.9 KB
- **Functions:** 10
- **Last Modified:** 2025-08-26 11:46

**Dependencies:** Unity-Claude-PerformanceOptimizer-Original, Unity-Claude-IncrementalProcessor, Unity-Claude-ParallelProcessor-Original, MetricsCollection, Unity-Claude-Cache-Original, Unity-Claude-Cache, SelfPatching, RunspaceCore, Unity-Claude-PerformanceOptimizer-Refactored, Performance-Cache, ProductionRunspacePool, ModuleVariablePreloading, RunspacePoolManagement, Unity-Claude-IncrementalProcessor-Fixed, SessionStateConfiguration, BatchProcessingEngine, SuccessTracking, Unity-Claude-Cache-Fixed, Unity-Claude-RunspaceManagement-Original, ThrottlingResourceControl

--- 
### WindowManager

[⬆ Back to Contents](#-table-of-contents)

Specialized module providing targeted functionality for the Unity-Claude automation system. Integrates with the broader architecture to deliver specific capabilities.

**Key Capabilities:** data retrieval, specialized operations, request processing

**Module Statistics:**
- Functions: 6
- Lines of Code: 367
- Classes: 3
- Exported Members: 1


**Module Details:**
- **Path:** `Modules\Unity-Claude-CLIOrchestrator\Core\WindowManager.psm1`
- **Size:** 14.5 KB
- **Functions:** 5
- **Last Modified:** 2025-08-27 23:51

**Dependencies:** CPG-DataStructures, CrossLanguage-DependencyMaps, Unity-Claude-PerformanceOptimizer-Original, Unity-Claude-IncrementalProcessor, CPG-Unified, Unity-Claude-ParallelProcessor-Original, Unity-Claude-Cache-Original, Unity-Claude-Cache, WindowManager-Enhanced, Unity-Claude-PerformanceOptimizer-Refactored, Performance-Cache, Unity-Claude-CPG-Original, Unity-Claude-IncrementalProcessor-Fixed, WindowManager-NUGGETRON, BatchProcessingEngine, WindowManager-Original, Unity-Claude-Cache-Fixed, Unity-Claude-CLIOrchestrator-Original

--- 
### WindowManager-Enhanced

[⬆ Back to Contents](#-table-of-contents)

Specialized module providing targeted functionality for the Unity-Claude automation system. Integrates with the broader architecture to deliver specific capabilities.

**Key Capabilities:** specialized operations, data retrieval

**Module Statistics:**
- Functions: 4
- Lines of Code: 342
- Classes: 1
- Exported Members: 1


**Module Details:**
- **Path:** `Modules\Unity-Claude-CLIOrchestrator\Core\WindowManager-Enhanced.psm1`
- **Size:** 16.34 KB
- **Functions:** 4
- **Last Modified:** 2025-08-27 20:42

**Dependencies:** Unity-Claude-PerformanceOptimizer-Original, Unity-Claude-IncrementalProcessor, Unity-Claude-ParallelProcessor-Original, Unity-Claude-Cache-Original, Unity-Claude-Cache, Unity-Claude-CLIOrchestrator-Fixed-Simple, Unity-Claude-PerformanceOptimizer-Refactored, Performance-Cache, Unity-Claude-IncrementalProcessor-Fixed, WindowManager-NUGGETRON, BatchProcessingEngine, WindowManager-Original, Unity-Claude-CLIOrchestrator-FullFeatured, WindowManager, Unity-Claude-Cache-Fixed, Unity-Claude-CLIOrchestrator-Original

--- 
### WindowManager-NUGGETRON

[⬆ Back to Contents](#-table-of-contents)

Specialized module providing targeted functionality for the Unity-Claude automation system. Integrates with the broader architecture to deliver specific capabilities.

**Key Capabilities:** data retrieval, specialized operations, request processing

**Module Statistics:**
- Functions: 4
- Lines of Code: 188
- Classes: 1
- Exported Members: 1


**Module Details:**
- **Path:** `Modules\Unity-Claude-CLIOrchestrator\Core\WindowManager-NUGGETRON.psm1`
- **Size:** 6.27 KB
- **Functions:** 4
- **Last Modified:** 2025-08-27 21:15

**Dependencies:** Unity-Claude-PerformanceOptimizer-Original, Unity-Claude-IncrementalProcessor, Unity-Claude-ParallelProcessor-Original, Unity-Claude-Cache-Original, Unity-Claude-Cache, WindowManager-Enhanced, Unity-Claude-PerformanceOptimizer-Refactored, Performance-Cache, Unity-Claude-IncrementalProcessor-Fixed, BatchProcessingEngine, WindowManager-Original, WindowManager, Unity-Claude-Cache-Fixed, Unity-Claude-CLIOrchestrator-Original

--- 
### WindowManager-Original

[⬆ Back to Contents](#-table-of-contents)

Specialized module providing targeted functionality for the Unity-Claude automation system. Integrates with the broader architecture to deliver specific capabilities.

**Key Capabilities:** specialized operations, data retrieval

**Module Statistics:**
- Functions: 4
- Lines of Code: 342
- Classes: 1
- Exported Members: 1


**Module Details:**
- **Path:** `Modules\Unity-Claude-CLIOrchestrator\Core\WindowManager-Original.psm1`
- **Size:** 16.34 KB
- **Functions:** 4
- **Last Modified:** 2025-08-27 20:42

**Dependencies:** Unity-Claude-PerformanceOptimizer-Original, Unity-Claude-IncrementalProcessor, Unity-Claude-ParallelProcessor-Original, Unity-Claude-Cache-Original, Unity-Claude-Cache, WindowManager-Enhanced, Unity-Claude-CLIOrchestrator-Fixed-Simple, Unity-Claude-PerformanceOptimizer-Refactored, Performance-Cache, Unity-Claude-IncrementalProcessor-Fixed, WindowManager-NUGGETRON, BatchProcessingEngine, Unity-Claude-CLIOrchestrator-FullFeatured, WindowManager, Unity-Claude-Cache-Fixed, Unity-Claude-CLIOrchestrator-Original

--- 
### WorkflowIntegration

[⬆ Back to Contents](#-table-of-contents)

Specialized module providing targeted functionality for the Unity-Claude automation system. Integrates with the broader architecture to deliver specific capabilities.

**Key Capabilities:** action execution, specialized operations, cleanup operations

**Module Statistics:**
- Functions: 6
- Lines of Code: 272
- Exported Members: 1


**Module Details:**
- **Path:** `Modules\Unity-Claude-NotificationIntegration\Integration\WorkflowIntegration.psm1`
- **Size:** 9.09 KB
- **Functions:** 6
- **Last Modified:** 2025-08-21 17:45

**Dependencies:** Unity-Claude-NotificationIntegration, Unity-Claude-Cache-Original, Unity-Claude-Cache, IntegratedNotifications, Performance-Cache, NotificationCore, Unity-Claude-Cache-Fixed

--- 
### WorkflowMonitoring

[⬆ Back to Contents](#-table-of-contents)

Real-time monitoring module tracking system health and performance metrics. Provides event-driven notifications and automated issue response.

**Key Capabilities:** data retrieval, process termination

**Module Statistics:**
- Functions: 2
- Lines of Code: 287
- Exported Members: 1


**Module Details:**
- **Path:** `Modules\Unity-Claude-IntegratedWorkflow\Core\WorkflowMonitoring.psm1`
- **Size:** 13.34 KB
- **Functions:** 2
- **Last Modified:** 2025-08-26 11:46

**Dependencies:** Unity-Claude-UnityParallelization-Original, Unity-Claude-PerformanceOptimizer-Original, JobScheduler, Unity-Claude-IncrementalProcessor, Unity-Claude-ParallelProcessor-Original, RunspacePoolManager, Unity-Claude-Cache-Original, StatisticsTracker, ModuleFunctions, Unity-Claude-Cache, Unity-Claude-PerformanceOptimizer-Refactored, Performance-Cache, RunspacePoolManagement, Unity-Claude-IncrementalProcessor-Fixed, BatchProcessingEngine, Unity-Claude-Cache-Fixed, ParallelMonitoring, Unity-Claude-RunspaceManagement-Original, Unity-Claude-IntegratedWorkflow-Original

--- 
### WorkflowOrchestration

[⬆ Back to Contents](#-table-of-contents)

Master orchestration module coordinating complex multi-step workflows. Manages module interactions, handles state transitions, and ensures proper sequencing of automated operations.

**Key Capabilities:** resource creation, process initiation, data retrieval

**Module Statistics:**
- Functions: 4
- Lines of Code: 448
- Exported Members: 1


**Module Details:**
- **Path:** `Modules\Unity-Claude-IntegratedWorkflow\Core\WorkflowOrchestration.psm1`
- **Size:** 21.3 KB
- **Functions:** 3
- **Last Modified:** 2025-08-26 11:46

**Dependencies:** CPG-DataStructures, CrossLanguage-DependencyMaps, Unity-Claude-UnityParallelization-Original, Unity-Claude-PerformanceOptimizer-Original, Unity-Claude-IncrementalProcessor, CPG-Unified, Unity-Claude-ParallelProcessor-Original, RunspacePoolManager, Unity-Claude-Cache-Original, ModuleFunctions, Unity-Claude-Cache, DependencyManagement, Unity-Claude-PerformanceOptimizer-Refactored, Performance-Cache, ProductionRunspacePool, ModuleVariablePreloading, RunspacePoolManagement, Unity-Claude-CPG-Original, Unity-Claude-ClaudeParallelization, Unity-Claude-IncrementalProcessor-Fixed, SessionStateConfiguration, BatchProcessingEngine, Unity-Claude-Cache-Fixed, ParallelMonitoring, Unity-Claude-RunspaceManagement-Original, Unity-Claude-IntegratedWorkflow-Original, VariableSharing, ProjectConfiguration

---

## 🕸️ Module Network

### Dependency Statistics

| Metric | Value |
|--------|-------|
| Total Modules | 367 |
| Total Dependencies | 6380 |
| AI-Enhanced Modules | 10 |
| Average Functions per Module | 10.61 |

### Most Connected Modules

| Module | Connections | Type | |--------|-------------|------| | Unity-Claude-CLIOrchestrator-Original | 55 | 📋 Pattern-Based | | Unity-Claude-CLIOrchestrator-Refactored-Fixed | 52 | 📋 Pattern-Based | | Unity-Claude-CLIOrchestrator-Original-Backup | 52 | 📋 Pattern-Based | | Unity-Claude-CLIOrchestrator | 52 | 📋 Pattern-Based | | Unity-Claude-CLIOrchestrator-Refactored | 52 | 📋 Pattern-Based | | Unity-Claude-CLIOrchestrator-FullFeatured | 52 | 📋 Pattern-Based | | Unity-Claude-UnityParallelization-Original | 45 | 📋 Pattern-Based | | PatternRecognition | 40 | 📋 Pattern-Based | | ResponseAnalysisEngine-Broken | 37 | 📋 Pattern-Based | | Unity-Claude-RunspaceManagement-Original | 37 | 📋 Pattern-Based |

---

*Generated by Unity-Claude Hybrid Documentation System*  
*AI Model: codellama:34b | Pattern Engine: v2.0*
