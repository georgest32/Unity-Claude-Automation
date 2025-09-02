# Support-Infrastructure - Detailed Module Analysis
**Enhanced Documentation System v2.0.0**
**Generated**: 2025-08-29 12:31:39
**Module Count**: 53
**Total Lines**: 21329
**Total Functions**: 261

## Category Overview
Supporting infrastructure component for Enhanced Documentation System operations

## Detailed Module Analysis

### Unity-Claude-ConcurrentProcessor 🟢
- **Path**: $(@{ModuleName=Unity-Claude-ConcurrentProcessor; DetailedCategory=Support-Infrastructure; SystemRole=Supporting infrastructure component for Enhanced Documentation System operations; RelativePath=Modules\Unity-Claude-ConcurrentProcessor.psm1; LineCount=998; FunctionCount=17; Functions=System.Object[]; ClassCount=0; Classes=System.Object[]; ExportCount=0; Exports=System.Object[]; Dependencies=System.Object[]; FileSizeKB=34.36; LastModified=08/20/2025 17:25:22; Complexity=43.98; Importance=Support}.RelativePath)
- **System Role**: Supporting infrastructure component for Enhanced Documentation System operations
- **Metrics**: 34.36 KB, 998 lines, 17 functions, 0 classes
- **Complexity Score**: 44
- **Last Modified**: 2025-08-20 17:25:22
- **Importance**: Support

#### Functions (17 total)
- **Write-ConcurrentLog** (Line 103) - **New-JobId** (Line 143) - **Get-ConcurrentTimestamp** (Line 147) - **Get-ProcessMutex** (Line 155) - **Invoke-WithMutex** (Line 175) - **Update-SharedData** (Line 203) - **Get-SharedData** (Line 222) - **Update-ResourceMonitoring** (Line 248) - **Test-ResourceAvailability** (Line 285) - **Start-ConcurrentJob** (Line 332) - **Wait-ConcurrentJob** (Line 409) - **Get-ConcurrentJobStatus** (Line 496) - **Stop-ConcurrentJob** (Line 539) - **Invoke-ParallelFileProcessing** (Line 583) - **Invoke-ParallelDataProcessing** (Line 680) - **Invoke-JobCleanup** (Line 809) - **Get-ConcurrentProcessingReport** (Line 888)



#### Dependencies
- ThreadJob



--- ### Unity-Claude-ResourceOptimizer 🟢
- **Path**: $(@{ModuleName=Unity-Claude-ResourceOptimizer; DetailedCategory=Support-Infrastructure; SystemRole=Supporting infrastructure component for Enhanced Documentation System operations; RelativePath=Modules\Unity-Claude-ResourceOptimizer.psm1; LineCount=903; FunctionCount=12; Functions=System.Object[]; ClassCount=0; Classes=System.Object[]; ExportCount=0; Exports=System.Object[]; Dependencies=System.Object[]; FileSizeKB=33.53; LastModified=08/20/2025 17:25:22; Complexity=33.03; Importance=Support}.RelativePath)
- **System Role**: Supporting infrastructure component for Enhanced Documentation System operations
- **Metrics**: 33.53 KB, 903 lines, 12 functions, 0 classes
- **Complexity Score**: 33
- **Last Modified**: 2025-08-20 17:25:22
- **Importance**: Support

#### Functions (12 total)
- **Write-ResourceLog** (Line 91) - **Get-ResourceTimestamp** (Line 123) - **ConvertTo-HumanReadableSize** (Line 127) - **Get-MemoryUsage** (Line 146) - **Invoke-MemoryMonitoring** (Line 187) - **Invoke-GarbageCollection** (Line 265) - **Invoke-LogRotation** (Line 323) - **Invoke-SessionCleanup** (Line 449) - **Invoke-EmergencyCleanup** (Line 560) - **Invoke-ResourceAlert** (Line 617) - **Invoke-ComprehensiveResourceCheck** (Line 678) - **Start-AutomaticResourceOptimization** (Line 785)







--- ### Unity-Claude-AutonomousStateTracker 🟢
- **Path**: $(@{ModuleName=Unity-Claude-AutonomousStateTracker; DetailedCategory=Support-Infrastructure; SystemRole=Supporting infrastructure component for Enhanced Documentation System operations; RelativePath=Modules\Unity-Claude-AutonomousStateTracker.psm1; LineCount=887; FunctionCount=18; Functions=System.Object[]; ClassCount=0; Classes=System.Object[]; ExportCount=0; Exports=System.Object[]; Dependencies=System.Object[]; FileSizeKB=30.86; LastModified=08/20/2025 17:25:22; Complexity=44.87; Importance=Support}.RelativePath)
- **System Role**: Supporting infrastructure component for Enhanced Documentation System operations
- **Metrics**: 30.86 KB, 887 lines, 18 functions, 0 classes
- **Complexity Score**: 44.9
- **Last Modified**: 2025-08-20 17:25:22
- **Importance**: Support

#### Functions (18 total)
- **Write-StateTrackerLog** (Line 129) - **Get-StateTimestamp** (Line 161) - **New-StateTrackingId** (Line 165) - **Initialize-AutonomousStateTracking** (Line 173) - **Get-AutonomousStateTracking** (Line 267) - **Save-StateTracking** (Line 294) - **Set-AutonomousState** (Line 313) - **Test-StateTransition** (Line 379) - **Invoke-HealthCheck** (Line 407) - **Get-SystemMetrics** (Line 455) - **Calculate-HealthStatus** (Line 484) - **Test-InterventionTriggers** (Line 529) - **Invoke-InterventionTrigger** (Line 569) - **Update-PerformanceMetrics** (Line 633) - **Test-CircuitBreakerState** (Line 675) - **Reset-CircuitBreaker** (Line 709) - **Get-AutonomousOperationStatus** (Line 746) - **Get-StateTransitionHistory** (Line 804)







--- ### CLIAutomation 🟢
- **Path**: $(@{ModuleName=CLIAutomation; DetailedCategory=Support-Infrastructure; SystemRole=Supporting infrastructure component for Enhanced Documentation System operations; RelativePath=Modules\Execution\CLIAutomation.psm1; LineCount=838; FunctionCount=15; Functions=System.Object[]; ClassCount=0; Classes=System.Object[]; ExportCount=0; Exports=System.Object[]; Dependencies=System.Object[]; FileSizeKB=27.25; LastModified=08/20/2025 17:25:20; Complexity=38.38; Importance=Support}.RelativePath)
- **System Role**: Supporting infrastructure component for Enhanced Documentation System operations
- **Metrics**: 27.25 KB, 838 lines, 15 functions, 0 classes
- **Complexity Score**: 38.4
- **Last Modified**: 2025-08-20 17:25:20
- **Importance**: Support

#### Functions (15 total)
- **Write-CLILog** (Line 64) - **Test-ProcessExists** (Line 87) - **Get-ClaudeWindow** (Line 101) - **Set-WindowFocus** (Line 152) - **Send-KeysToWindow** (Line 233) - **Submit-ClaudeCLIInput** (Line 264) - **Write-ClaudeMessageFile** (Line 321) - **Submit-ClaudeFileInput** (Line 352) - **Initialize-InputQueue** (Line 455) - **Add-InputToQueue** (Line 472) - **Process-InputQueue** (Line 524) - **Get-InputQueueStatus** (Line 615) - **Format-ClaudePrompt** (Line 648) - **Test-InputDelivery** (Line 683) - **Submit-ClaudeInputWithFallback** (Line 719)







--- ### Unity-Claude-IntegrationEngine 🟢
- **Path**: $(@{ModuleName=Unity-Claude-IntegrationEngine; DetailedCategory=Support-Infrastructure; SystemRole=Supporting infrastructure component for Enhanced Documentation System operations; RelativePath=Modules\Unity-Claude-IntegrationEngine.psm1; LineCount=806; FunctionCount=20; Functions=System.Object[]; ClassCount=0; Classes=System.Object[]; ExportCount=0; Exports=System.Object[]; Dependencies=System.Object[]; FileSizeKB=29.48; LastModified=08/20/2025 17:25:22; Complexity=48.06; Importance=Support}.RelativePath)
- **System Role**: Supporting infrastructure component for Enhanced Documentation System operations
- **Metrics**: 29.48 KB, 806 lines, 20 functions, 0 classes
- **Complexity Score**: 48.1
- **Last Modified**: 2025-08-20 17:25:22
- **Importance**: Support

#### Functions (20 total)
- **Write-IntegrationLog** (Line 81) - **Get-CurrentTimestamp** (Line 113) - **New-CycleId** (Line 117) - **Initialize-IntegrationState** (Line 125) - **Get-IntegrationState** (Line 158) - **Update-IntegrationState** (Line 174) - **New-FeedbackCycle** (Line 208) - **Update-CyclePhase** (Line 242) - **Complete-FeedbackCycle** (Line 275) - **Invoke-FeedbackCyclePhase1Monitor** (Line 304) - **Invoke-FeedbackCyclePhase2Parse** (Line 332) - **Invoke-FeedbackCyclePhase3Analyze** (Line 360) - **Invoke-FeedbackCyclePhase4Execute** (Line 388) - **Invoke-FeedbackCyclePhase5Generate** (Line 430) - **Invoke-FeedbackCyclePhase6Submit** (Line 464) - **Start-AutonomousFeedbackLoop** (Line 496) - **Invoke-CompleteFeedbackCycle** (Line 601) - **Stop-AutonomousFeedbackLoop** (Line 662) - **Get-FeedbackLoopStatus** (Line 685) - **Resume-FeedbackLoopSession** (Line 711)



#### Dependencies
- $modulePath



--- ### Unity-Claude-SessionManager 🟢
- **Path**: $(@{ModuleName=Unity-Claude-SessionManager; DetailedCategory=Support-Infrastructure; SystemRole=Supporting infrastructure component for Enhanced Documentation System operations; RelativePath=Modules\Unity-Claude-SessionManager.psm1; LineCount=791; FunctionCount=18; Functions=System.Object[]; ClassCount=0; Classes=System.Object[]; ExportCount=0; Exports=System.Object[]; Dependencies=System.Object[]; FileSizeKB=26.48; LastModified=08/20/2025 17:25:22; Complexity=43.91; Importance=Support}.RelativePath)
- **System Role**: Supporting infrastructure component for Enhanced Documentation System operations
- **Metrics**: 26.48 KB, 791 lines, 18 functions, 0 classes
- **Complexity Score**: 43.9
- **Last Modified**: 2025-08-20 17:25:22
- **Importance**: Support

#### Functions (18 total)
- **Write-SessionLog** (Line 60) - **New-SessionId** (Line 92) - **Get-SessionTimestamp** (Line 96) - **New-ConversationSession** (Line 104) - **Get-ConversationSession** (Line 184) - **Save-ConversationSession** (Line 217) - **Update-ConversationSession** (Line 249) - **Add-ConversationHistoryEntry** (Line 275) - **Get-ConversationHistoryForContext** (Line 331) - **Invoke-ConversationSummarization** (Line 374) - **New-SessionCheckpoint** (Line 430) - **Restore-SessionFromCheckpoint** (Line 476) - **Resume-ConversationSession** (Line 521) - **Update-SessionMetrics** (Line 569) - **Get-SessionAnalytics** (Line 596) - **Should-CreateBackup** (Line 650) - **New-SessionBackup** (Line 661) - **Complete-ConversationSession** (Line 679)



#### Dependencies
- $conversationStatePath



--- ### Unity-Claude-TriggerConditions 🟢
- **Path**: $(@{ModuleName=Unity-Claude-TriggerConditions; DetailedCategory=Support-Infrastructure; SystemRole=Supporting infrastructure component for Enhanced Documentation System operations; RelativePath=Modules\Unity-Claude-DocumentationDrift\Unity-Claude-TriggerConditions.psm1; LineCount=757; FunctionCount=7; Functions=System.Object[]; ClassCount=0; Classes=System.Object[]; ExportCount=0; Exports=System.Object[]; Dependencies=System.Object[]; FileSizeKB=27.5; LastModified=08/24/2025 12:06:11; Complexity=21.57; Importance=Support}.RelativePath)
- **System Role**: Supporting infrastructure component for Enhanced Documentation System operations
- **Metrics**: 27.5 KB, 757 lines, 7 functions, 0 classes
- **Complexity Score**: 21.6
- **Last Modified**: 2025-08-24 12:06:11
- **Importance**: Support

#### Functions (7 total)
- **Initialize-TriggerConditions** (Line 79) - **Test-TriggerCondition** (Line 148) - **Add-ToProcessingQueue** (Line 365) - **Get-ProcessingQueue** (Line 432) - **Start-QueueProcessing** (Line 478) - **Clear-ProcessingQueue** (Line 600) - **Get-EstimatedProcessingTime** (Line 672)







--- ### Unity-Claude-AutonomousMonitoring 🟢
- **Path**: $(@{ModuleName=Unity-Claude-AutonomousMonitoring; DetailedCategory=Support-Infrastructure; SystemRole=Supporting infrastructure component for Enhanced Documentation System operations; RelativePath=Backup_20250824_233959\Modules\Unity-Claude-AutonomousMonitoring\Unity-Claude-AutonomousMonitoring.psm1; LineCount=731; FunctionCount=7; Functions=System.Object[]; ClassCount=0; Classes=System.Object[]; ExportCount=0; Exports=System.Object[]; Dependencies=System.Object[]; FileSizeKB=32.74; LastModified=08/24/2025 12:06:11; Complexity=21.31; Importance=Support}.RelativePath)
- **System Role**: Supporting infrastructure component for Enhanced Documentation System operations
- **Metrics**: 32.74 KB, 731 lines, 7 functions, 0 classes
- **Complexity Score**: 21.3
- **Last Modified**: 2025-08-24 12:06:11
- **Importance**: Support

#### Functions (7 total)
- **Update-ClaudeWindowInfo** (Line 70) - **Find-ClaudeWindow** (Line 113) - **Switch-ToWindow** (Line 205) - **Submit-ToClaudeViaTypeKeys** (Line 252) - **Execute-TestScript** (Line 387) - **Process-ResponseFile** (Line 488) - **Start-AutonomousMonitoring** (Line 573)







--- ### Unity-Claude-AutonomousMonitoring 🟢
- **Path**: $(@{ModuleName=Unity-Claude-AutonomousMonitoring; DetailedCategory=Support-Infrastructure; SystemRole=Supporting infrastructure component for Enhanced Documentation System operations; RelativePath=Backup_20250824_233959\Unity-Claude-AutonomousMonitoring\Unity-Claude-AutonomousMonitoring.psm1; LineCount=731; FunctionCount=7; Functions=System.Object[]; ClassCount=0; Classes=System.Object[]; ExportCount=0; Exports=System.Object[]; Dependencies=System.Object[]; FileSizeKB=32.74; LastModified=08/24/2025 12:06:11; Complexity=21.31; Importance=Support}.RelativePath)
- **System Role**: Supporting infrastructure component for Enhanced Documentation System operations
- **Metrics**: 32.74 KB, 731 lines, 7 functions, 0 classes
- **Complexity Score**: 21.3
- **Last Modified**: 2025-08-24 12:06:11
- **Importance**: Support

#### Functions (7 total)
- **Update-ClaudeWindowInfo** (Line 70) - **Find-ClaudeWindow** (Line 113) - **Switch-ToWindow** (Line 205) - **Submit-ToClaudeViaTypeKeys** (Line 252) - **Execute-TestScript** (Line 387) - **Process-ResponseFile** (Line 488) - **Start-AutonomousMonitoring** (Line 573)







--- ### Unity-Claude-AutonomousMonitoring 🟢
- **Path**: $(@{ModuleName=Unity-Claude-AutonomousMonitoring; DetailedCategory=Support-Infrastructure; SystemRole=Supporting infrastructure component for Enhanced Documentation System operations; RelativePath=Backup_20250824_233959\Backup_20250824_233959\Unity-Claude-AutonomousMonitoring\Unity-Claude-AutonomousMonitoring.psm1; LineCount=731; FunctionCount=7; Functions=System.Object[]; ClassCount=0; Classes=System.Object[]; ExportCount=0; Exports=System.Object[]; Dependencies=System.Object[]; FileSizeKB=32.74; LastModified=08/24/2025 12:06:11; Complexity=21.31; Importance=Support}.RelativePath)
- **System Role**: Supporting infrastructure component for Enhanced Documentation System operations
- **Metrics**: 32.74 KB, 731 lines, 7 functions, 0 classes
- **Complexity Score**: 21.3
- **Last Modified**: 2025-08-24 12:06:11
- **Importance**: Support

#### Functions (7 total)
- **Update-ClaudeWindowInfo** (Line 70) - **Find-ClaudeWindow** (Line 113) - **Switch-ToWindow** (Line 205) - **Submit-ToClaudeViaTypeKeys** (Line 252) - **Execute-TestScript** (Line 387) - **Process-ResponseFile** (Line 488) - **Start-AutonomousMonitoring** (Line 573)







--- ### Legacy-Compatibility 🟢
- **Path**: $(@{ModuleName=Legacy-Compatibility; DetailedCategory=Support-Infrastructure; SystemRole=Supporting infrastructure component for Enhanced Documentation System operations; RelativePath=Migration\Legacy-Compatibility.psm1; LineCount=725; FunctionCount=9; Functions=System.Object[]; ClassCount=0; Classes=System.Object[]; ExportCount=0; Exports=System.Object[]; Dependencies=System.Object[]; FileSizeKB=28.16; LastModified=08/27/2025 00:06:45; Complexity=25.25; Importance=Support}.RelativePath)
- **System Role**: Supporting infrastructure component for Enhanced Documentation System operations
- **Metrics**: 28.16 KB, 725 lines, 9 functions, 0 classes
- **Complexity Score**: 25.2
- **Last Modified**: 2025-08-27 00:06:45
- **Importance**: Support

#### Functions (9 total)
- **Enable-LegacyMode** (Line 12) - **Disable-LegacyMode** (Line 63) - **Test-LegacyMode** (Line 81) - **Show-DeprecationWarning** (Line 98) - **Invoke-LegacySystemStartup** (Line 138) - **Start-SubsystemInWindow** (Line 232) - **Invoke-ManifestBasedSystemStartup** (Line 295) - **Start-UnityClaudeSystem** (Line 533) - **Test-MigrationStatus** (Line 646)



#### Dependencies
- $systemStatusModule



--- ### Unity-Claude-GovernanceIntegration 🟢
- **Path**: $(@{ModuleName=Unity-Claude-GovernanceIntegration; DetailedCategory=Support-Infrastructure; SystemRole=Supporting infrastructure component for Enhanced Documentation System operations; RelativePath=Modules\Unity-Claude-HITL\Unity-Claude-GovernanceIntegration.psm1; LineCount=582; FunctionCount=7; Functions=System.Object[]; ClassCount=0; Classes=System.Object[]; ExportCount=0; Exports=System.Object[]; Dependencies=System.Object[]; FileSizeKB=22.24; LastModified=08/24/2025 12:06:11; Complexity=19.82; Importance=Support}.RelativePath)
- **System Role**: Supporting infrastructure component for Enhanced Documentation System operations
- **Metrics**: 22.24 KB, 582 lines, 7 functions, 0 classes
- **Complexity Score**: 19.8
- **Last Modified**: 2025-08-24 12:06:11
- **Importance**: Support

#### Functions (7 total)
- **Test-GitHubGovernanceCompliance** (Line 7) - **New-GovernanceAwareApprovalRequest** (Line 178) - **Wait-GovernanceApproval** (Line 310) - **Get-CodeOwnersRequirements** (Line 410) - **Get-ChangeRiskAssessment** (Line 450) - **Test-GovernancePolicyViolations** (Line 496) - **Test-ApprovalGovernanceCompliance** (Line 525)







--- ### Unity-Claude-AutonomousStateTracker-Enhanced-Refactored 🟢
- **Path**: $(@{ModuleName=Unity-Claude-AutonomousStateTracker-Enhanced-Refactored; DetailedCategory=Support-Infrastructure; SystemRole=Supporting infrastructure component for Enhanced Documentation System operations; RelativePath=Modules\Unity-Claude-AutonomousStateTracker-Enhanced\Unity-Claude-AutonomousStateTracker-Enhanced-Refactored.psm1; LineCount=518; FunctionCount=3; Functions=System.Object[]; ClassCount=0; Classes=System.Object[]; ExportCount=0; Exports=System.Object[]; Dependencies=System.Object[]; FileSizeKB=21.74; LastModified=08/26/2025 11:46:17; Complexity=11.18; Importance=Support}.RelativePath)
- **System Role**: Supporting infrastructure component for Enhanced Documentation System operations
- **Metrics**: 21.74 KB, 518 lines, 3 functions, 0 classes
- **Complexity Score**: 11.2
- **Last Modified**: 2025-08-26 11:46:17
- **Importance**: Support

#### Functions (3 total)
- **Get-AutonomousStateTrackerComponents** (Line 64) - **Test-AutonomousStateTrackerHealth** (Line 138) - **Invoke-ComprehensiveAutonomousAnalysis** (Line 316)



#### Dependencies
- $modulePath



--- ### Unity-Claude-AutonomousStateTracker-Enhanced 🟢
- **Path**: $(@{ModuleName=Unity-Claude-AutonomousStateTracker-Enhanced; DetailedCategory=Support-Infrastructure; SystemRole=Supporting infrastructure component for Enhanced Documentation System operations; RelativePath=Modules\Unity-Claude-AutonomousStateTracker-Enhanced\Unity-Claude-AutonomousStateTracker-Enhanced.psm1; LineCount=518; FunctionCount=3; Functions=System.Object[]; ClassCount=0; Classes=System.Object[]; ExportCount=0; Exports=System.Object[]; Dependencies=System.Object[]; FileSizeKB=21.74; LastModified=08/26/2025 11:46:17; Complexity=11.18; Importance=Support}.RelativePath)
- **System Role**: Supporting infrastructure component for Enhanced Documentation System operations
- **Metrics**: 21.74 KB, 518 lines, 3 functions, 0 classes
- **Complexity Score**: 11.2
- **Last Modified**: 2025-08-26 11:46:17
- **Importance**: Support

#### Functions (3 total)
- **Get-AutonomousStateTrackerComponents** (Line 64) - **Test-AutonomousStateTrackerHealth** (Line 138) - **Invoke-ComprehensiveAutonomousAnalysis** (Line 316)



#### Dependencies
- $modulePath



--- ### Unity-Claude-DocumentationAutomation 🟢
- **Path**: $(@{ModuleName=Unity-Claude-DocumentationAutomation; DetailedCategory=Support-Infrastructure; SystemRole=Supporting infrastructure component for Enhanced Documentation System operations; RelativePath=Modules\Unity-Claude-DocumentationAutomation\Unity-Claude-DocumentationAutomation.psm1; LineCount=452; FunctionCount=3; Functions=System.Object[]; ClassCount=0; Classes=System.Object[]; ExportCount=0; Exports=System.Object[]; Dependencies=System.Object[]; FileSizeKB=16.62; LastModified=08/26/2025 11:46:18; Complexity=10.52; Importance=Support}.RelativePath)
- **System Role**: Supporting infrastructure component for Enhanced Documentation System operations
- **Metrics**: 16.62 KB, 452 lines, 3 functions, 0 classes
- **Complexity Score**: 10.5
- **Last Modified**: 2025-08-26 11:46:18
- **Importance**: Support

#### Functions (3 total)
- **Initialize-DocumentationAutomation** (Line 84) - **Test-ComponentHealth** (Line 176) - **Get-DocumentationAutomationInfo** (Line 288)



#### Dependencies
- (Join-Path - (Join-Path - (Join-Path - (Join-Path - (Join-Path



--- ### Unity-Claude-DocumentationAutomation-Refactored 🟢
- **Path**: $(@{ModuleName=Unity-Claude-DocumentationAutomation-Refactored; DetailedCategory=Support-Infrastructure; SystemRole=Supporting infrastructure component for Enhanced Documentation System operations; RelativePath=Modules\Unity-Claude-DocumentationAutomation\Unity-Claude-DocumentationAutomation-Refactored.psm1; LineCount=452; FunctionCount=3; Functions=System.Object[]; ClassCount=0; Classes=System.Object[]; ExportCount=0; Exports=System.Object[]; Dependencies=System.Object[]; FileSizeKB=16.62; LastModified=08/26/2025 11:46:18; Complexity=10.52; Importance=Support}.RelativePath)
- **System Role**: Supporting infrastructure component for Enhanced Documentation System operations
- **Metrics**: 16.62 KB, 452 lines, 3 functions, 0 classes
- **Complexity Score**: 10.5
- **Last Modified**: 2025-08-26 11:46:18
- **Importance**: Support

#### Functions (3 total)
- **Initialize-DocumentationAutomation** (Line 84) - **Test-ComponentHealth** (Line 176) - **Get-DocumentationAutomationInfo** (Line 288)



#### Dependencies
- (Join-Path - (Join-Path - (Join-Path - (Join-Path - (Join-Path



--- ### UnityCommands 🟢
- **Path**: $(@{ModuleName=UnityCommands; DetailedCategory=Support-Infrastructure; SystemRole=Supporting infrastructure component for Enhanced Documentation System operations; RelativePath=Modules\Unity-Claude-AutonomousAgent\Commands\UnityCommands.psm1; LineCount=445; FunctionCount=7; Functions=System.Object[]; ClassCount=0; Classes=System.Object[]; ExportCount=0; Exports=System.Object[]; Dependencies=System.Object[]; FileSizeKB=15.5; LastModified=08/20/2025 17:25:20; Complexity=18.45; Importance=Support}.RelativePath)
- **System Role**: Supporting infrastructure component for Enhanced Documentation System operations
- **Metrics**: 15.5 KB, 445 lines, 7 functions, 0 classes
- **Complexity Score**: 18.4
- **Last Modified**: 2025-08-20 17:25:20
- **Importance**: Support

#### Functions (7 total)
- **Invoke-TestCommand** (Line 16) - **Invoke-UnityTests** (Line 66) - **Invoke-CompilationTest** (Line 127) - **Invoke-PowerShellTests** (Line 170) - **Invoke-BuildCommand** (Line 229) - **Invoke-AnalyzeCommand** (Line 280) - **Find-UnityExecutable** (Line 346)



#### Dependencies
- (Join-Path



--- ### FileSystemMonitoring 🟢
- **Path**: $(@{ModuleName=FileSystemMonitoring; DetailedCategory=Support-Infrastructure; SystemRole=Supporting infrastructure component for Enhanced Documentation System operations; RelativePath=Modules\Unity-Claude-AutonomousAgent\Monitoring\FileSystemMonitoring.psm1; LineCount=441; FunctionCount=4; Functions=System.Object[]; ClassCount=0; Classes=System.Object[]; ExportCount=0; Exports=System.Object[]; Dependencies=System.Object[]; FileSizeKB=20.74; LastModified=08/20/2025 17:25:21; Complexity=12.41; Importance=Support}.RelativePath)
- **System Role**: Supporting infrastructure component for Enhanced Documentation System operations
- **Metrics**: 20.74 KB, 441 lines, 4 functions, 0 classes
- **Complexity Score**: 12.4
- **Last Modified**: 2025-08-20 17:25:21
- **Importance**: Support

#### Functions (4 total)
- **Start-ClaudeResponseMonitoring** (Line 16) - **Stop-ClaudeResponseMonitoring** (Line 223) - **Get-MonitoringStatus** (Line 283) - **Test-FileSystemMonitoring** (Line 325)



#### Dependencies
- (Join-Path - (Join-Path



--- ### Unity-Claude-ScalabilityEnhancements 🟢
- **Path**: $(@{ModuleName=Unity-Claude-ScalabilityEnhancements; DetailedCategory=Support-Infrastructure; SystemRole=Supporting infrastructure component for Enhanced Documentation System operations; RelativePath=Modules\Unity-Claude-ScalabilityEnhancements\Unity-Claude-ScalabilityEnhancements.psm1; LineCount=427; FunctionCount=4; Functions=System.Object[]; ClassCount=0; Classes=System.Object[]; ExportCount=0; Exports=System.Object[]; Dependencies=System.Object[]; FileSizeKB=16.67; LastModified=08/26/2025 11:46:19; Complexity=12.27; Importance=Support}.RelativePath)
- **System Role**: Supporting infrastructure component for Enhanced Documentation System operations
- **Metrics**: 16.67 KB, 427 lines, 4 functions, 0 classes
- **Complexity Score**: 12.3
- **Last Modified**: 2025-08-26 11:46:19
- **Importance**: Support

#### Functions (4 total)
- **Initialize-ScalabilityEnhancements** (Line 26) - **Test-ScalabilityComponents** (Line 114) - **Get-ScalabilityInfo** (Line 200) - **Update-ScalabilityStatistics** (Line 268)



#### Dependencies
- (Join-Path - (Join-Path - (Join-Path - (Join-Path - (Join-Path - (Join-Path



--- ### Unity-Claude-ScalabilityEnhancements-Refactored 🟢
- **Path**: $(@{ModuleName=Unity-Claude-ScalabilityEnhancements-Refactored; DetailedCategory=Support-Infrastructure; SystemRole=Supporting infrastructure component for Enhanced Documentation System operations; RelativePath=Modules\Unity-Claude-ScalabilityEnhancements\Unity-Claude-ScalabilityEnhancements-Refactored.psm1; LineCount=427; FunctionCount=4; Functions=System.Object[]; ClassCount=0; Classes=System.Object[]; ExportCount=0; Exports=System.Object[]; Dependencies=System.Object[]; FileSizeKB=16.67; LastModified=08/26/2025 11:46:19; Complexity=12.27; Importance=Support}.RelativePath)
- **System Role**: Supporting infrastructure component for Enhanced Documentation System operations
- **Metrics**: 16.67 KB, 427 lines, 4 functions, 0 classes
- **Complexity Score**: 12.3
- **Last Modified**: 2025-08-26 11:46:19
- **Importance**: Support

#### Functions (4 total)
- **Initialize-ScalabilityEnhancements** (Line 26) - **Test-ScalabilityComponents** (Line 114) - **Get-ScalabilityInfo** (Line 200) - **Update-ScalabilityStatistics** (Line 268)



#### Dependencies
- (Join-Path - (Join-Path - (Join-Path - (Join-Path - (Join-Path - (Join-Path



--- ### Unity-Claude-HITL 🟢
- **Path**: $(@{ModuleName=Unity-Claude-HITL; DetailedCategory=Support-Infrastructure; SystemRole=Supporting infrastructure component for Enhanced Documentation System operations; RelativePath=Modules\Unity-Claude-HITL\Unity-Claude-HITL.psm1; LineCount=424; FunctionCount=3; Functions=System.Object[]; ClassCount=0; Classes=System.Object[]; ExportCount=0; Exports=System.Object[]; Dependencies=System.Object[]; FileSizeKB=15.55; LastModified=08/26/2025 11:46:18; Complexity=10.24; Importance=Support}.RelativePath)
- **System Role**: Supporting infrastructure component for Enhanced Documentation System operations
- **Metrics**: 15.55 KB, 424 lines, 3 functions, 0 classes
- **Complexity Score**: 10.2
- **Last Modified**: 2025-08-26 11:46:18
- **Importance**: Support

#### Functions (3 total)
- **Get-HITLComponents** (Line 43) - **Test-HITLSystemIntegration** (Line 84) - **Invoke-ComprehensiveHITLAnalysis** (Line 218)



#### Dependencies
- $ComponentPath - Unity-Claude-GitHub



--- ### Unity-Claude-HITL-Refactored 🟢
- **Path**: $(@{ModuleName=Unity-Claude-HITL-Refactored; DetailedCategory=Support-Infrastructure; SystemRole=Supporting infrastructure component for Enhanced Documentation System operations; RelativePath=Modules\Unity-Claude-HITL\Unity-Claude-HITL-Refactored.psm1; LineCount=424; FunctionCount=3; Functions=System.Object[]; ClassCount=0; Classes=System.Object[]; ExportCount=0; Exports=System.Object[]; Dependencies=System.Object[]; FileSizeKB=15.55; LastModified=08/26/2025 11:46:18; Complexity=10.24; Importance=Support}.RelativePath)
- **System Role**: Supporting infrastructure component for Enhanced Documentation System operations
- **Metrics**: 15.55 KB, 424 lines, 3 functions, 0 classes
- **Complexity Score**: 10.2
- **Last Modified**: 2025-08-26 11:46:18
- **Importance**: Support

#### Functions (3 total)
- **Get-HITLComponents** (Line 43) - **Test-HITLSystemIntegration** (Line 84) - **Invoke-ComprehensiveHITLAnalysis** (Line 218)



#### Dependencies
- $ComponentPath - Unity-Claude-GitHub



--- ### ConversationStateManager-Refactored 🟢
- **Path**: $(@{ModuleName=ConversationStateManager-Refactored; DetailedCategory=Support-Infrastructure; SystemRole=Supporting infrastructure component for Enhanced Documentation System operations; RelativePath=Modules\Unity-Claude-AutonomousAgent\ConversationStateManager-Refactored.psm1; LineCount=328; FunctionCount=5; Functions=System.Object[]; ClassCount=0; Classes=System.Object[]; ExportCount=0; Exports=System.Object[]; Dependencies=System.Object[]; FileSizeKB=12.5; LastModified=08/26/2025 11:46:17; Complexity=13.28; Importance=Support}.RelativePath)
- **System Role**: Supporting infrastructure component for Enhanced Documentation System operations
- **Metrics**: 12.5 KB, 328 lines, 5 functions, 0 classes
- **Complexity Score**: 13.3
- **Last Modified**: 2025-08-26 11:46:17
- **Importance**: Support

#### Functions (5 total)
- **Get-ConversationStateManagerComponents** (Line 23) - **Test-ConversationStateManagerHealth** (Line 48) - **Invoke-ConversationStateManagerDiagnostics** (Line 95) - **Initialize-CompleteConversationSystem** (Line 147) - **Get-ConversationSummary** (Line 206)



#### Dependencies
- (Join-Path - (Join-Path - (Join-Path - (Join-Path - (Join-Path - (Join-Path



--- ### Unity-Claude-RunspaceManagement 🟢
- **Path**: $(@{ModuleName=Unity-Claude-RunspaceManagement; DetailedCategory=Support-Infrastructure; SystemRole=Supporting infrastructure component for Enhanced Documentation System operations; RelativePath=Modules\Unity-Claude-RunspaceManagement\Unity-Claude-RunspaceManagement.psm1; LineCount=308; FunctionCount=3; Functions=System.Object[]; ClassCount=0; Classes=System.Object[]; ExportCount=0; Exports=System.Object[]; Dependencies=System.Object[]; FileSizeKB=10.91; LastModified=08/26/2025 11:46:19; Complexity=9.08; Importance=Support}.RelativePath)
- **System Role**: Supporting infrastructure component for Enhanced Documentation System operations
- **Metrics**: 10.91 KB, 308 lines, 3 functions, 0 classes
- **Complexity Score**: 9.1
- **Last Modified**: 2025-08-26 11:46:19
- **Importance**: Support

#### Functions (3 total)
- **Initialize-RunspaceManagement** (Line 63) - **Get-RunspaceManagementStatus** (Line 110) - **Stop-RunspaceManagement** (Line 148)



#### Dependencies
- $componentPath



--- ### Unity-Claude-RunspaceManagement-Refactored 🟢
- **Path**: $(@{ModuleName=Unity-Claude-RunspaceManagement-Refactored; DetailedCategory=Support-Infrastructure; SystemRole=Supporting infrastructure component for Enhanced Documentation System operations; RelativePath=Modules\Unity-Claude-RunspaceManagement\Unity-Claude-RunspaceManagement-Refactored.psm1; LineCount=308; FunctionCount=3; Functions=System.Object[]; ClassCount=0; Classes=System.Object[]; ExportCount=0; Exports=System.Object[]; Dependencies=System.Object[]; FileSizeKB=10.91; LastModified=08/26/2025 11:46:19; Complexity=9.08; Importance=Support}.RelativePath)
- **System Role**: Supporting infrastructure component for Enhanced Documentation System operations
- **Metrics**: 10.91 KB, 308 lines, 3 functions, 0 classes
- **Complexity Score**: 9.1
- **Last Modified**: 2025-08-26 11:46:19
- **Importance**: Support

#### Functions (3 total)
- **Initialize-RunspaceManagement** (Line 63) - **Get-RunspaceManagementStatus** (Line 110) - **Stop-RunspaceManagement** (Line 148)



#### Dependencies
- $componentPath



--- ### Unity-Claude-DocumentationDrift-Refactored 🟢
- **Path**: $(@{ModuleName=Unity-Claude-DocumentationDrift-Refactored; DetailedCategory=Support-Infrastructure; SystemRole=Supporting infrastructure component for Enhanced Documentation System operations; RelativePath=Modules\Unity-Claude-DocumentationDrift\Unity-Claude-DocumentationDrift-Refactored.psm1; LineCount=269; FunctionCount=3; Functions=System.Object[]; ClassCount=0; Classes=System.Object[]; ExportCount=0; Exports=System.Object[]; Dependencies=System.Object[]; FileSizeKB=9.91; LastModified=08/26/2025 11:46:18; Complexity=8.69; Importance=Support}.RelativePath)
- **System Role**: Supporting infrastructure component for Enhanced Documentation System operations
- **Metrics**: 9.91 KB, 269 lines, 3 functions, 0 classes
- **Complexity Score**: 8.7
- **Last Modified**: 2025-08-26 11:46:18
- **Importance**: Support

#### Functions (3 total)
- **Clear-DriftCache** (Line 33) - **Get-DriftDetectionResults** (Line 68) - **Test-DocumentationDrift** (Line 93)



#### Dependencies
- $ModulePath\Core\Configuration.psd1 - $ModulePath\Analysis\ImpactAnalysis.psd1



--- ### Unity-Claude-AutonomousAgent-Refactored 🟢
- **Path**: $(@{ModuleName=Unity-Claude-AutonomousAgent-Refactored; DetailedCategory=Support-Infrastructure; SystemRole=Supporting infrastructure component for Enhanced Documentation System operations; RelativePath=Modules\Unity-Claude-AutonomousAgent\Unity-Claude-AutonomousAgent-Refactored.psm1; LineCount=219; FunctionCount=1; Functions=System.Object[]; ClassCount=0; Classes=System.Object[]; ExportCount=0; Exports=System.Object[]; Dependencies=System.Object[]; FileSizeKB=8.77; LastModified=08/20/2025 17:25:21; Complexity=4.19; Importance=Support}.RelativePath)
- **System Role**: Supporting infrastructure component for Enhanced Documentation System operations
- **Metrics**: 8.77 KB, 219 lines, 1 functions, 0 classes
- **Complexity Score**: 4.2
- **Last Modified**: 2025-08-20 17:25:21
- **Importance**: Support

#### Functions (1 total)
- **Get-ModuleStatus** (Line 143)



#### Dependencies
- for - $modulePath



--- ### Unity-Claude-SystemStatus-ModularLoader 🟢
- **Path**: $(@{ModuleName=Unity-Claude-SystemStatus-ModularLoader; DetailedCategory=Support-Infrastructure; SystemRole=Supporting infrastructure component for Enhanced Documentation System operations; RelativePath=Backups\PS7Migration_20250822_162419\Unity-Claude-SystemStatus-ModularLoader.psm1; LineCount=201; FunctionCount=0; Functions=System.Object[]; ClassCount=0; Classes=System.Object[]; ExportCount=0; Exports=System.Object[]; Dependencies=System.Object[]; FileSizeKB=8.56; LastModified=08/20/2025 17:25:25; Complexity=2.01; Importance=Support}.RelativePath)
- **System Role**: Supporting infrastructure component for Enhanced Documentation System operations
- **Metrics**: 8.56 KB, 201 lines, 0 functions, 0 classes
- **Complexity Score**: 2
- **Last Modified**: 2025-08-20 17:25:25
- **Importance**: Support

#### Functions (0 total)
- No functions detected



#### Dependencies
- $watchdogPath - $submodulePath



--- ### Unity-Claude-SystemStatus-ModularLoader 🟢
- **Path**: $(@{ModuleName=Unity-Claude-SystemStatus-ModularLoader; DetailedCategory=Support-Infrastructure; SystemRole=Supporting infrastructure component for Enhanced Documentation System operations; RelativePath=Unity-Claude-SystemStatus-ModularLoader.psm1; LineCount=201; FunctionCount=0; Functions=System.Object[]; ClassCount=0; Classes=System.Object[]; ExportCount=0; Exports=System.Object[]; Dependencies=System.Object[]; FileSizeKB=8.56; LastModified=08/20/2025 17:25:25; Complexity=2.01; Importance=Support}.RelativePath)
- **System Role**: Supporting infrastructure component for Enhanced Documentation System operations
- **Metrics**: 8.56 KB, 201 lines, 0 functions, 0 classes
- **Complexity Score**: 2
- **Last Modified**: 2025-08-20 17:25:25
- **Importance**: Support

#### Functions (0 total)
- No functions detected



#### Dependencies
- $watchdogPath - $submodulePath



--- ### Unity-Claude-IntegratedWorkflow 🟢
- **Path**: $(@{ModuleName=Unity-Claude-IntegratedWorkflow; DetailedCategory=Support-Infrastructure; SystemRole=Supporting infrastructure component for Enhanced Documentation System operations; RelativePath=Modules\Unity-Claude-IntegratedWorkflow\Unity-Claude-IntegratedWorkflow.psm1; LineCount=189; FunctionCount=0; Functions=System.Object[]; ClassCount=0; Classes=System.Object[]; ExportCount=0; Exports=System.Object[]; Dependencies=System.Object[]; FileSizeKB=9.29; LastModified=08/26/2025 11:46:18; Complexity=1.89; Importance=Support}.RelativePath)
- **System Role**: Supporting infrastructure component for Enhanced Documentation System operations
- **Metrics**: 9.29 KB, 189 lines, 0 functions, 0 classes
- **Complexity Score**: 1.9
- **Last Modified**: 2025-08-26 11:46:18
- **Importance**: Support

#### Functions (0 total)
- No functions detected



#### Dependencies
- $componentFullPath



--- ### Unity-Claude-IntegratedWorkflow-Refactored 🟢
- **Path**: $(@{ModuleName=Unity-Claude-IntegratedWorkflow-Refactored; DetailedCategory=Support-Infrastructure; SystemRole=Supporting infrastructure component for Enhanced Documentation System operations; RelativePath=Modules\Unity-Claude-IntegratedWorkflow\Unity-Claude-IntegratedWorkflow-Refactored.psm1; LineCount=189; FunctionCount=0; Functions=System.Object[]; ClassCount=0; Classes=System.Object[]; ExportCount=0; Exports=System.Object[]; Dependencies=System.Object[]; FileSizeKB=9.29; LastModified=08/26/2025 11:46:18; Complexity=1.89; Importance=Support}.RelativePath)
- **System Role**: Supporting infrastructure component for Enhanced Documentation System operations
- **Metrics**: 9.29 KB, 189 lines, 0 functions, 0 classes
- **Complexity Score**: 1.9
- **Last Modified**: 2025-08-26 11:46:18
- **Importance**: Support

#### Functions (0 total)
- No functions detected



#### Dependencies
- $componentFullPath



--- ### Unity-Claude-Learning 🟢
- **Path**: $(@{ModuleName=Unity-Claude-Learning; DetailedCategory=Support-Infrastructure; SystemRole=Supporting infrastructure component for Enhanced Documentation System operations; RelativePath=Modules\Unity-Claude-Learning\Unity-Claude-Learning.psm1; LineCount=171; FunctionCount=0; Functions=System.Object[]; ClassCount=0; Classes=System.Object[]; ExportCount=0; Exports=System.Object[]; Dependencies=System.Object[]; FileSizeKB=7.32; LastModified=08/26/2025 11:46:18; Complexity=1.71; Importance=Support}.RelativePath)
- **System Role**: Supporting infrastructure component for Enhanced Documentation System operations
- **Metrics**: 7.32 KB, 171 lines, 0 functions, 0 classes
- **Complexity Score**: 1.7
- **Last Modified**: 2025-08-26 11:46:18
- **Importance**: Support

#### Functions (0 total)
- No functions detected



#### Dependencies
- $componentFullPath



--- ### Unity-Claude-Learning-Refactored 🟢
- **Path**: $(@{ModuleName=Unity-Claude-Learning-Refactored; DetailedCategory=Support-Infrastructure; SystemRole=Supporting infrastructure component for Enhanced Documentation System operations; RelativePath=Modules\Unity-Claude-Learning\Unity-Claude-Learning-Refactored.psm1; LineCount=171; FunctionCount=0; Functions=System.Object[]; ClassCount=0; Classes=System.Object[]; ExportCount=0; Exports=System.Object[]; Dependencies=System.Object[]; FileSizeKB=7.32; LastModified=08/26/2025 11:46:18; Complexity=1.71; Importance=Support}.RelativePath)
- **System Role**: Supporting infrastructure component for Enhanced Documentation System operations
- **Metrics**: 7.32 KB, 171 lines, 0 functions, 0 classes
- **Complexity Score**: 1.7
- **Last Modified**: 2025-08-26 11:46:18
- **Importance**: Support

#### Functions (0 total)
- No functions detected



#### Dependencies
- $componentFullPath



--- ### Unity-Claude-EventLog 🟢
- **Path**: $(@{ModuleName=Unity-Claude-EventLog; DetailedCategory=Support-Infrastructure; SystemRole=Supporting infrastructure component for Enhanced Documentation System operations; RelativePath=Modules\Unity-Claude-EventLog\Unity-Claude-EventLog.psm1; LineCount=114; FunctionCount=1; Functions=System.Object[]; ClassCount=0; Classes=System.Object[]; ExportCount=0; Exports=System.Object[]; Dependencies=System.Object[]; FileSizeKB=4.87; LastModified=08/24/2025 12:06:11; Complexity=3.14; Importance=Support}.RelativePath)
- **System Role**: Supporting infrastructure component for Enhanced Documentation System operations
- **Metrics**: 4.87 KB, 114 lines, 1 functions, 0 classes
- **Complexity Score**: 3.1
- **Last Modified**: 2025-08-24 12:06:11
- **Importance**: Support

#### Functions (1 total)
- **Write-UCDebugLog** (Line 35)







--- ### Unity-Claude-NotificationConfiguration 🟢
- **Path**: $(@{ModuleName=Unity-Claude-NotificationConfiguration; DetailedCategory=Support-Infrastructure; SystemRole=Supporting infrastructure component for Enhanced Documentation System operations; RelativePath=Modules\Unity-Claude-NotificationConfiguration\Unity-Claude-NotificationConfiguration.psm1; LineCount=96; FunctionCount=0; Functions=System.Object[]; ClassCount=0; Classes=System.Object[]; ExportCount=0; Exports=System.Object[]; Dependencies=System.Object[]; FileSizeKB=4.43; LastModified=08/24/2025 12:06:11; Complexity=0.96; Importance=Support}.RelativePath)
- **System Role**: Supporting infrastructure component for Enhanced Documentation System operations
- **Metrics**: 4.43 KB, 96 lines, 0 functions, 0 classes
- **Complexity Score**: 1
- **Last Modified**: 2025-08-24 12:06:11
- **Importance**: Support

#### Functions (0 total)
- No functions detected







--- ### Unity-Claude-SystemStatus 🟢
- **Path**: $(@{ModuleName=Unity-Claude-SystemStatus; DetailedCategory=Support-Infrastructure; SystemRole=Supporting infrastructure component for Enhanced Documentation System operations; RelativePath=Modules\Unity-Claude-SystemStatus\Unity-Claude-SystemStatus.psm1; LineCount=73; FunctionCount=0; Functions=System.Object[]; ClassCount=0; Classes=System.Object[]; ExportCount=0; Exports=System.Object[]; Dependencies=System.Object[]; FileSizeKB=5.03; LastModified=08/26/2025 21:41:32; Complexity=0.73; Importance=Support}.RelativePath)
- **System Role**: Supporting infrastructure component for Enhanced Documentation System operations
- **Metrics**: 5.03 KB, 73 lines, 0 functions, 0 classes
- **Complexity Score**: 0.7
- **Last Modified**: 2025-08-26 21:41:32
- **Importance**: Support

#### Functions (0 total)
- No functions detected







--- ### Test-Minimal-Queue 🟢
- **Path**: $(@{ModuleName=Test-Minimal-Queue; DetailedCategory=Support-Infrastructure; SystemRole=Supporting infrastructure component for Enhanced Documentation System operations; RelativePath=Test-Minimal-Queue.psm1; LineCount=12; FunctionCount=1; Functions=System.Object[]; ClassCount=0; Classes=System.Object[]; ExportCount=0; Exports=System.Object[]; Dependencies=System.Object[]; FileSizeKB=0.32; LastModified=08/20/2025 19:09:44; Complexity=2.12; Importance=Support}.RelativePath)
- **System Role**: Supporting infrastructure component for Enhanced Documentation System operations
- **Metrics**: 0.32 KB, 12 lines, 1 functions, 0 classes
- **Complexity Score**: 2.1
- **Last Modified**: 2025-08-20 19:09:44
- **Importance**: Support

#### Functions (1 total)
- **Test-NewConcurrentQueue** (Line 4)







--- ### Test-Minimal-Queue 🟢
- **Path**: $(@{ModuleName=Test-Minimal-Queue; DetailedCategory=Support-Infrastructure; SystemRole=Supporting infrastructure component for Enhanced Documentation System operations; RelativePath=Backups\PS7Migration_20250822_162419\Test-Minimal-Queue.psm1; LineCount=12; FunctionCount=1; Functions=System.Object[]; ClassCount=0; Classes=System.Object[]; ExportCount=0; Exports=System.Object[]; Dependencies=System.Object[]; FileSizeKB=0.32; LastModified=08/20/2025 19:09:44; Complexity=2.12; Importance=Support}.RelativePath)
- **System Role**: Supporting infrastructure component for Enhanced Documentation System operations
- **Metrics**: 0.32 KB, 12 lines, 1 functions, 0 classes
- **Complexity Score**: 2.1
- **Last Modified**: 2025-08-20 19:09:44
- **Importance**: Support

#### Functions (1 total)
- **Test-NewConcurrentQueue** (Line 4)







--- ### Unity-Claude-ObsolescenceDetection 🟡 HIGH
- **Path**: $(@{ModuleName=Unity-Claude-ObsolescenceDetection; DetailedCategory=Support-Infrastructure; SystemRole=Supporting infrastructure component for Enhanced Documentation System operations; RelativePath=Modules\Unity-Claude-CPG\Unity-Claude-ObsolescenceDetection.psm1; LineCount=583; FunctionCount=5; Functions=System.Object[]; ClassCount=0; Classes=System.Object[]; ExportCount=0; Exports=System.Object[]; Dependencies=System.Object[]; FileSizeKB=22.22; LastModified=08/26/2025 11:46:18; Complexity=15.83; Importance=High}.RelativePath)
- **System Role**: Supporting infrastructure component for Enhanced Documentation System operations
- **Metrics**: 22.22 KB, 583 lines, 5 functions, 0 classes
- **Complexity Score**: 15.8
- **Last Modified**: 2025-08-26 11:46:18
- **Importance**: High

#### Functions (5 total)
- **Get-ObsolescenceDetectionComponents** (Line 134) - **Test-ObsolescenceDetectionHealth** (Line 187) - **Invoke-ComprehensiveObsolescenceAnalysis** (Line 308) - **Generate-AnalysisSummary** (Line 432) - **Generate-ObsolescenceActionPlan** (Line 469)



#### Dependencies
- $componentPath



--- ### Unity-Claude-ObsolescenceDetection-Refactored 🟡 HIGH
- **Path**: $(@{ModuleName=Unity-Claude-ObsolescenceDetection-Refactored; DetailedCategory=Support-Infrastructure; SystemRole=Supporting infrastructure component for Enhanced Documentation System operations; RelativePath=Modules\Unity-Claude-CPG\Unity-Claude-ObsolescenceDetection-Refactored.psm1; LineCount=583; FunctionCount=5; Functions=System.Object[]; ClassCount=0; Classes=System.Object[]; ExportCount=0; Exports=System.Object[]; Dependencies=System.Object[]; FileSizeKB=22.22; LastModified=08/26/2025 11:46:18; Complexity=15.83; Importance=High}.RelativePath)
- **System Role**: Supporting infrastructure component for Enhanced Documentation System operations
- **Metrics**: 22.22 KB, 583 lines, 5 functions, 0 classes
- **Complexity Score**: 15.8
- **Last Modified**: 2025-08-26 11:46:18
- **Importance**: High

#### Functions (5 total)
- **Get-ObsolescenceDetectionComponents** (Line 134) - **Test-ObsolescenceDetectionHealth** (Line 187) - **Invoke-ComprehensiveObsolescenceAnalysis** (Line 308) - **Generate-AnalysisSummary** (Line 432) - **Generate-ObsolescenceActionPlan** (Line 469)



#### Dependencies
- $componentPath



--- ### AgentLogging 🟡 HIGH
- **Path**: $(@{ModuleName=AgentLogging; DetailedCategory=Support-Infrastructure; SystemRole=Supporting infrastructure component for Enhanced Documentation System operations; RelativePath=Modules\Unity-Claude-AutonomousAgent\Core\AgentLogging.psm1; LineCount=398; FunctionCount=7; Functions=System.Object[]; ClassCount=0; Classes=System.Object[]; ExportCount=0; Exports=System.Object[]; Dependencies=System.Object[]; FileSizeKB=13.12; LastModified=08/26/2025 11:46:17; Complexity=17.98; Importance=High}.RelativePath)
- **System Role**: Supporting infrastructure component for Enhanced Documentation System operations
- **Metrics**: 13.12 KB, 398 lines, 7 functions, 0 classes
- **Complexity Score**: 18
- **Last Modified**: 2025-08-26 11:46:17
- **Importance**: High

#### Functions (7 total)
- **Write-AgentLog** (Line 31) - **Initialize-AgentLogging** (Line 147) - **Invoke-LogRotation** (Line 196) - **Remove-OldLogFiles** (Line 225) - **Get-AgentLogPath** (Line 257) - **Get-AgentLogStatistics** (Line 271) - **Clear-AgentLog** (Line 317)







--- ### IntegrationManagement 🟡 HIGH
- **Path**: $(@{ModuleName=IntegrationManagement; DetailedCategory=Support-Infrastructure; SystemRole=Supporting infrastructure component for Enhanced Documentation System operations; RelativePath=Modules\Unity-Claude-DecisionEngine\Core\IntegrationManagement.psm1; LineCount=359; FunctionCount=6; Functions=System.Object[]; ClassCount=0; Classes=System.Object[]; ExportCount=0; Exports=System.Object[]; Dependencies=System.Object[]; FileSizeKB=13.75; LastModified=08/26/2025 11:46:18; Complexity=15.59; Importance=High}.RelativePath)
- **System Role**: Supporting infrastructure component for Enhanced Documentation System operations
- **Metrics**: 13.75 KB, 359 lines, 6 functions, 0 classes
- **Complexity Score**: 15.6
- **Last Modified**: 2025-08-26 11:46:18
- **Importance**: High

#### Functions (6 total)
- **Connect-IntelligentPromptEngine** (Line 20) - **Connect-ConversationManager** (Line 58) - **Get-DecisionEngineStatus** (Line 99) - **Test-DecisionEngineIntegration** (Line 158) - **Get-DecisionEngineComponents** (Line 253) - **Test-DecisionEngineHealth** (Line 281)



#### Dependencies
- $corePath



--- ### StateConfiguration 🟡 HIGH
- **Path**: $(@{ModuleName=StateConfiguration; DetailedCategory=Support-Infrastructure; SystemRole=Supporting infrastructure component for Enhanced Documentation System operations; RelativePath=Modules\Unity-Claude-AutonomousStateTracker-Enhanced\Core\StateConfiguration.psm1; LineCount=284; FunctionCount=4; Functions=System.Object[]; ClassCount=0; Classes=System.Object[]; ExportCount=0; Exports=System.Object[]; Dependencies=System.Object[]; FileSizeKB=11.35; LastModified=08/26/2025 11:46:17; Complexity=10.84; Importance=High}.RelativePath)
- **System Role**: Supporting infrastructure component for Enhanced Documentation System operations
- **Metrics**: 11.35 KB, 284 lines, 4 functions, 0 classes
- **Complexity Score**: 10.8
- **Last Modified**: 2025-08-26 11:46:17
- **Importance**: High

#### Functions (4 total)
- **Get-EnhancedStateConfig** (Line 62) - **Initialize-StateDirectories** (Line 70) - **Get-EnhancedAutonomousStates** (Line 195) - **Get-PerformanceCounters** (Line 231)







--- ### MemoryManager 🟡 HIGH
- **Path**: $(@{ModuleName=MemoryManager; DetailedCategory=Support-Infrastructure; SystemRole=Supporting infrastructure component for Enhanced Documentation System operations; RelativePath=Modules\Unity-Claude-ScalabilityEnhancements\Core\MemoryManager.psm1; LineCount=273; FunctionCount=5; Functions=System.Object[]; ClassCount=1; Classes=System.Object[]; ExportCount=0; Exports=System.Object[]; Dependencies=System.Object[]; FileSizeKB=9; LastModified=08/26/2025 11:46:19; Complexity=15.73; Importance=High}.RelativePath)
- **System Role**: Supporting infrastructure component for Enhanced Documentation System operations
- **Metrics**: 9 KB, 273 lines, 5 functions, 1 classes
- **Complexity Score**: 15.7
- **Last Modified**: 2025-08-26 11:46:19
- **Importance**: High

#### Functions (5 total)
- **Start-MemoryOptimization** (Line 107) - **Get-MemoryUsageReport** (Line 129) - **Force-GarbageCollection** (Line 147) - **Optimize-ObjectLifecycles** (Line 173) - **Monitor-MemoryPressure** (Line 200)

#### Classes (1 total)
- **MemoryManager**





--- ### Unity-Claude-CPG 🟡 HIGH
- **Path**: $(@{ModuleName=Unity-Claude-CPG; DetailedCategory=Support-Infrastructure; SystemRole=Supporting infrastructure component for Enhanced Documentation System operations; RelativePath=Modules\Unity-Claude-CPG\Unity-Claude-CPG.psm1; LineCount=206; FunctionCount=1; Functions=System.Object[]; ClassCount=0; Classes=System.Object[]; ExportCount=0; Exports=System.Object[]; Dependencies=System.Object[]; FileSizeKB=8.38; LastModified=08/26/2025 11:46:18; Complexity=4.06; Importance=High}.RelativePath)
- **System Role**: Supporting infrastructure component for Enhanced Documentation System operations
- **Metrics**: 8.38 KB, 206 lines, 1 functions, 0 classes
- **Complexity Score**: 4.1
- **Last Modified**: 2025-08-26 11:46:18
- **Importance**: High

#### Functions (1 total)
- **ConvertTo-CPGFromScriptBlock** (Line 75)



#### Dependencies
- $dataStructuresPath - $componentPath - $astConverterPath



--- ### Unity-Claude-CPG-Refactored 🟡 HIGH
- **Path**: $(@{ModuleName=Unity-Claude-CPG-Refactored; DetailedCategory=Support-Infrastructure; SystemRole=Supporting infrastructure component for Enhanced Documentation System operations; RelativePath=Modules\Unity-Claude-CPG\Unity-Claude-CPG-Refactored.psm1; LineCount=206; FunctionCount=1; Functions=System.Object[]; ClassCount=0; Classes=System.Object[]; ExportCount=0; Exports=System.Object[]; Dependencies=System.Object[]; FileSizeKB=8.38; LastModified=08/26/2025 11:46:18; Complexity=4.06; Importance=High}.RelativePath)
- **System Role**: Supporting infrastructure component for Enhanced Documentation System operations
- **Metrics**: 8.38 KB, 206 lines, 1 functions, 0 classes
- **Complexity Score**: 4.1
- **Last Modified**: 2025-08-26 11:46:18
- **Importance**: High

#### Functions (1 total)
- **ConvertTo-CPGFromScriptBlock** (Line 75)



#### Dependencies
- $dataStructuresPath - $componentPath - $astConverterPath



--- ### RunspaceCore 🟡 HIGH
- **Path**: $(@{ModuleName=RunspaceCore; DetailedCategory=Support-Infrastructure; SystemRole=Supporting infrastructure component for Enhanced Documentation System operations; RelativePath=Modules\Unity-Claude-RunspaceManagement\Core\RunspaceCore.psm1; LineCount=201; FunctionCount=8; Functions=System.Object[]; ClassCount=0; Classes=System.Object[]; ExportCount=0; Exports=System.Object[]; Dependencies=System.Object[]; FileSizeKB=6.92; LastModified=08/26/2025 11:46:19; Complexity=18.01; Importance=High}.RelativePath)
- **System Role**: Supporting infrastructure component for Enhanced Documentation System operations
- **Metrics**: 6.92 KB, 201 lines, 8 functions, 0 classes
- **Complexity Score**: 18
- **Last Modified**: 2025-08-26 11:46:19
- **Importance**: High

#### Functions (8 total)
- **Test-ModuleDependencyAvailability** (Line 14) - **Write-FallbackLog** (Line 51) - **Write-ModuleLog** (Line 70) - **Get-RunspacePoolRegistry** (Line 89) - **Update-RunspacePoolRegistry** (Line 101) - **Get-SharedVariablesDictionary** (Line 112) - **Get-SessionStatesRegistry** (Line 124) - **Update-SessionStateRegistry** (Line 136)



#### Dependencies
- Unity-Claude-ParallelProcessing



--- ### DatabaseManagement 🟡 HIGH
- **Path**: $(@{ModuleName=DatabaseManagement; DetailedCategory=Support-Infrastructure; SystemRole=Supporting infrastructure component for Enhanced Documentation System operations; RelativePath=Modules\Unity-Claude-Learning\Core\DatabaseManagement.psm1; LineCount=195; FunctionCount=1; Functions=System.Object[]; ClassCount=0; Classes=System.Object[]; ExportCount=0; Exports=System.Object[]; Dependencies=System.Object[]; FileSizeKB=7.55; LastModified=08/26/2025 11:46:19; Complexity=3.95; Importance=High}.RelativePath)
- **System Role**: Supporting infrastructure component for Enhanced Documentation System operations
- **Metrics**: 7.55 KB, 195 lines, 1 functions, 0 classes
- **Complexity Score**: 4
- **Last Modified**: 2025-08-26 11:46:19
- **Importance**: High

#### Functions (1 total)
- **Initialize-LearningDatabase** (Line 11)



#### Dependencies
- $CorePath



--- ### DependencyManagement 🟡 HIGH
- **Path**: $(@{ModuleName=DependencyManagement; DetailedCategory=Support-Infrastructure; SystemRole=Supporting infrastructure component for Enhanced Documentation System operations; RelativePath=Modules\Unity-Claude-IntegratedWorkflow\Core\DependencyManagement.psm1; LineCount=173; FunctionCount=5; Functions=System.Object[]; ClassCount=0; Classes=System.Object[]; ExportCount=0; Exports=System.Object[]; Dependencies=System.Object[]; FileSizeKB=7.8; LastModified=08/26/2025 11:46:18; Complexity=11.73; Importance=High}.RelativePath)
- **System Role**: Supporting infrastructure component for Enhanced Documentation System operations
- **Metrics**: 7.8 KB, 173 lines, 5 functions, 0 classes
- **Complexity Score**: 11.7
- **Last Modified**: 2025-08-26 11:46:18
- **Importance**: High

#### Functions (5 total)
- **Test-ModuleDependencyAvailability** (Line 16) - **Initialize-RequiredModules** (Line 39) - **Test-ModuleDependencies** (Line 98) - **Assert-Dependencies** (Line 113) - **Get-ModuleAvailability** (Line 126)



#### Dependencies
- $CorePath - $RunspaceManagementPath - $UnityParallelizationPath - $ClaudeParallelizationPath



--- ### WorkflowCore 🟡 HIGH
- **Path**: $(@{ModuleName=WorkflowCore; DetailedCategory=Support-Infrastructure; SystemRole=Supporting infrastructure component for Enhanced Documentation System operations; RelativePath=Modules\Unity-Claude-IntegratedWorkflow\Core\WorkflowCore.psm1; LineCount=101; FunctionCount=3; Functions=System.Object[]; ClassCount=0; Classes=System.Object[]; ExportCount=0; Exports=System.Object[]; Dependencies=System.Object[]; FileSizeKB=4.3; LastModified=08/26/2025 11:46:18; Complexity=7.01; Importance=High}.RelativePath)
- **System Role**: Supporting infrastructure component for Enhanced Documentation System operations
- **Metrics**: 4.3 KB, 101 lines, 3 functions, 0 classes
- **Complexity Score**: 7
- **Last Modified**: 2025-08-26 11:46:18
- **Importance**: High

#### Functions (3 total)
- **Write-FallbackLog** (Line 17) - **Write-IntegratedWorkflowLog** (Line 39) - **Get-IntegratedWorkflowState** (Line 55)







--- ### PromptConfiguration 🟡 HIGH
- **Path**: $(@{ModuleName=PromptConfiguration; DetailedCategory=Support-Infrastructure; SystemRole=Supporting infrastructure component for Enhanced Documentation System operations; RelativePath=Modules\Unity-Claude-AutonomousAgent\Core\PromptConfiguration.psm1; LineCount=95; FunctionCount=1; Functions=System.Object[]; ClassCount=0; Classes=System.Object[]; ExportCount=0; Exports=System.Object[]; Dependencies=System.Object[]; FileSizeKB=4.4; LastModified=08/26/2025 11:46:17; Complexity=2.95; Importance=High}.RelativePath)
- **System Role**: Supporting infrastructure component for Enhanced Documentation System operations
- **Metrics**: 4.4 KB, 95 lines, 1 functions, 0 classes
- **Complexity Score**: 3
- **Last Modified**: 2025-08-26 11:46:17
- **Importance**: High

#### Functions (1 total)
- **Get-PromptEngineConfig** (Line 45)







--- ### ConversationCore 🟡 HIGH
- **Path**: $(@{ModuleName=ConversationCore; DetailedCategory=Support-Infrastructure; SystemRole=Supporting infrastructure component for Enhanced Documentation System operations; RelativePath=Modules\Unity-Claude-AutonomousAgent\Core\ConversationCore.psm1; LineCount=88; FunctionCount=1; Functions=System.Object[]; ClassCount=0; Classes=System.Object[]; ExportCount=0; Exports=System.Object[]; Dependencies=System.Object[]; FileSizeKB=4.18; LastModified=08/26/2025 11:46:17; Complexity=2.88; Importance=High}.RelativePath)
- **System Role**: Supporting infrastructure component for Enhanced Documentation System operations
- **Metrics**: 4.18 KB, 88 lines, 1 functions, 0 classes
- **Complexity Score**: 2.9
- **Last Modified**: 2025-08-26 11:46:17
- **Importance**: High

#### Functions (1 total)
- **Write-StateLog** (Line 26)







--- ### AnalyticsReporting 🔴 CRITICAL
- **Path**: $(@{ModuleName=AnalyticsReporting; DetailedCategory=Support-Infrastructure; SystemRole=Supporting infrastructure component for Enhanced Documentation System operations; RelativePath=Modules\Unity-Claude-PredictiveAnalysis\Core\AnalyticsReporting.psm1; LineCount=715; FunctionCount=9; Functions=System.Object[]; ClassCount=0; Classes=System.Object[]; ExportCount=0; Exports=System.Object[]; Dependencies=System.Object[]; FileSizeKB=24.71; LastModified=08/26/2025 11:46:19; Complexity=25.15; Importance=Critical}.RelativePath)
- **System Role**: Supporting infrastructure component for Enhanced Documentation System operations
- **Metrics**: 24.71 KB, 715 lines, 9 functions, 0 classes
- **Complexity Score**: 25.2
- **Last Modified**: 2025-08-26 11:46:19
- **Importance**: Critical

#### Functions (9 total)
- **Get-ROIAnalysis** (Line 33) - **Estimate-RefactoringEffort** (Line 103) - **Get-PriorityActions** (Line 173) - **Get-HistoricalMetrics** (Line 238) - **Get-ComplexityTrend** (Line 295) - **Get-CommitFrequency** (Line 372) - **Get-AuthorContributions** (Line 423) - **Update-PredictionModels** (Line 500) - **Get-CouplingIssues** (Line 576)



#### Dependencies
- -Name - -Name



---

## Support-Infrastructure Summary Statistics
- **Average Module Size**: 15.5 KB
- **Average Functions per Module**: 4.9
- **Most Complex Module**: Unity-Claude-IntegrationEngine (48.1 complexity)
- **Critical Modules**: 1
- **High Priority Modules**: 14

*Detailed analysis of Support-Infrastructure modules in Enhanced Documentation System v2.0.0*
