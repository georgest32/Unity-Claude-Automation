# Bootstrap Orchestrator Enhancement Analysis
## Unity-Claude-Automation SystemStatusMonitoring Module
## Date: 2025-08-22 14:30:00
## Previous Context: Duplicate agent prevention issues, PID tracking problems
## Topics: Module architecture, bootstrap patterns, dependency management, singleton enforcement

## Executive Summary
Analysis of adding Bootstrap Orchestrator functionality to the existing SystemStatusMonitoring module rather than creating a new module. Current module already has significant infrastructure (56 functions across 4 categories) that can be extended.

## Home State Analysis

### Project Structure
- **Root**: C:\UnityProjects\Sound-and-Shoal\Unity-Claude-Automation\
- **Module Location**: Modules\Unity-Claude-SystemStatus\
- **Module Version**: 1.0.0 with 25+ exported functions
- **PowerShell Version**: 5.1 (Windows PowerShell)
- **Unity Version**: 2021.1.14f1

### Current Module Architecture
The Unity-Claude-SystemStatus module has 56 functions organized into:
1. **Core** (30 functions): System state, messaging, dependency management
2. **Execution** (12 functions): Process control, recovery actions
3. **Monitoring** (7 functions): Health checks, agent status
4. **Parsing** (1 function): Data conversion utilities

### Key Existing Functions Relevant to Bootstrap Orchestrator
- `Get-TopologicalSort.ps1` - Already has dependency sorting!
- `Get-ServiceDependencyGraph.ps1` - Dependency graph building
- `Register-Subsystem.ps1` - Subsystem registration with duplicate check
- `Test-AutonomousAgentStatus.ps1` - Agent-specific monitoring
- `Initialize-SubsystemRunspaces.ps1` - Runspace management
- `Restart-ServiceWithDependencies.ps1` - Dependency-aware restart

## Objectives and Implementation Plan

### Short-Term Objectives (Week 1)
1. Add mutex-based singleton enforcement to replace broken PID tracking
2. Create manifest-based configuration system for subsystems
3. Generalize hardcoded AutonomousAgent logic to support any subsystem
4. Fix duplicate prevention issues identified in previous sessions

### Long-Term Objectives (Week 2-3)
1. Full dependency resolution with automatic startup ordering
2. Configurable restart policies per subsystem
3. Health monitoring with adaptive thresholds
4. Production-ready orchestration for all Unity-Claude subsystems

## Current Issues and Blockers

### Issue 1: Duplicate Agent Prevention Failure
- **Problem**: Multiple AutonomousAgent instances running simultaneously
- **Root Cause**: PID mismatch between wrapper process and actual script
- **Current State**: Register-Subsystem reads from file but doesn't prevent duplicates effectively

### Issue 2: Hardcoded AutonomousAgent Logic
- **Problem**: SystemStatus monitor only knows about AutonomousAgent
- **Location**: Start-SystemStatusMonitoring-Window.ps1 lines with Test-AutonomousAgentStatus
- **Impact**: Cannot manage other subsystems

### Issue 3: No Dependency Management
- **Problem**: Subsystems start in random order
- **Impact**: Failures when dependencies not ready
- **Note**: Get-TopologicalSort exists but unused

## Research Findings Summary

### Key Patterns Identified
1. **Mutex Pattern**: System.Threading.Mutex with named mutexes for OS-level singleton
2. **Manifest Pattern**: Subsystem.manifest.psd1 files for configuration
3. **Supervisor Pattern**: Monitor as single coordinator for all subsystems
4. **Topological Sort**: Already implemented but not integrated

### Critical Learnings
1. Mutexes more reliable than PID tracking for duplicate prevention
2. PowerShell 5.1 requires careful handling of synchronized objects
3. Bootstrap orchestration naturally fits monitoring responsibilities
4. Dependency resolution critical for multi-subsystem management

## Preliminary Solution Design

### Solution Architecture
```
SystemStatusMonitoring (Enhanced)
├── Manifest Discovery
│   └── Get-SubsystemManifests
├── Dependency Resolution  
│   └── Get-TopologicalSort (existing)
├── Singleton Enforcement
│   └── New-SubsystemMutex
├── Generic Management
│   └── Start-SubsystemSafe (replaces Start-AutonomousAgentSafe)
└── Monitoring Loop
    └── Test-SubsystemStatus (replaces Test-AutonomousAgentStatus)
```

### Key Changes Required
1. **Add Manifest Support**: Create subsystem.manifest.psd1 structure
2. **Add Mutex Functions**: New-SubsystemMutex, Test-SubsystemMutex
3. **Generalize Functions**: Make agent-specific functions work for any subsystem
4. **Integrate Dependency Resolution**: Use existing Get-TopologicalSort

## Implementation Recommendation
Expand SystemStatusMonitoring rather than create new module because:
1. 70% of required infrastructure already exists
2. Natural evolution of monitoring to include orchestration
3. Less code duplication and simpler architecture
4. Existing dependency functions (Get-TopologicalSort) ready to use

## Research Findings (After 5 Queries)

### Query 1-5 Summary
1. **Mutex Implementation**: System.Threading.Mutex with named mutexes works in PowerShell 5.1. Use "Global\" prefix for system-wide, WaitOne(0) for non-blocking check, always release in finally block.
2. **Module Manifest Schema**: RequiredModules and NestedModules have different session state behaviors. NestedModules run in module's session state, RequiredModules in global.
3. **Topological Sort**: Kahn's algorithm (BFS) or DFS approaches work. PowerShell implementations exist (Get-TopologicalSort). Multiple valid orderings possible.
4. **Module Loading Lifecycle**: Each module gets its own session state. Import-Module with -Force only reloads root module, not nested. Classes need "using module" statement.
5. **Circuit Breaker Pattern**: Three states (Closed/Open/Half-Open). Runspace pools don't auto-reset state. Polly framework available for .NET/PowerShell.

### Critical Insights
- Mutex with "Global\" prefix ensures system-wide singleton
- Abandoned mutex throws exception - must handle properly
- Module session states are isolated - careful with nested modules
- Topological sort can identify parallel execution opportunities
- Circuit breaker prevents cascade failures in distributed systems

## Research Findings (After 10 Queries)

### Query 6-10 Summary
6. **Process Monitoring**: Get-Counter for CPU/memory, Get-CimInstance for WMI data, continuous monitoring loops with thresholds
7. **Configuration Management**: JSON preferred (15% smaller than XML), Registry for Windows-specific, hashtables for lookups, environment variables for simple key-value
8. **Runspace Lifecycle**: Manual disposal required (EndInvoke then Dispose), CleanupInterval for automatic cleanup, memory leaks without proper disposal
9. **Service Recovery**: SC.exe for recovery options, external watchdog better than internal, scheduled tasks for periodic checks
10. **Plugin Architecture**: Module discovery via $PSModulePath, manifests control loading, dynamic modules via New-Module, explicit exports for performance

### Additional Critical Insights
- Get-Counter more reliable than WMI for performance monitoring
- JSON configuration with powershell.config.json standard
- Runspace pools require explicit resource cleanup sequence
- Windows service recovery has built-in options via SC.exe
- Module discovery automatic when in PSModulePath directories

## Implementation Plan Summary

### Phase 1: Foundation (Week 1, Days 1-3)
- **Day 1**: Mutex-based singleton enforcement (8 hours)
- **Day 2**: Manifest-based configuration system (8 hours)
- **Day 3**: Dependency resolution integration (8 hours)

### Phase 2: Generic Management (Week 1, Days 4-5)
- **Day 4**: Generalize monitoring functions (8 hours)
- **Day 5**: Configuration management with JSON (8 hours)

### Phase 3: Testing & Migration (Week 2, Days 1-3)
- **Day 1**: Comprehensive testing suite (8 hours)
- **Day 2**: Migration and backward compatibility (8 hours)
- **Day 3**: Production readiness and hardening (8 hours)

### Key Deliverables
1. Mutex-based duplicate prevention replacing broken PID tracking
2. Manifest system for subsystem configuration
3. Generic subsystem management (not just AutonomousAgent)
4. Dependency resolution with parallel startup detection
5. Circuit breaker pattern for failure recovery
6. JSON-based configuration management
7. Comprehensive test suite
8. Migration tools and backward compatibility

### Success Metrics
- Zero duplicate processes
- Correct startup ordering
- Automatic failure recovery
- 99.9% uptime for critical subsystems

## Conclusion
The SystemStatusMonitoring module should be enhanced rather than replaced. With 56 existing functions including Get-TopologicalSort already implemented, adding Bootstrap Orchestrator functionality is a natural evolution. The incremental approach ensures minimal disruption while solving current issues with duplicate processes and lack of generic subsystem support.