# Bootstrap Orchestrator Design for Unity-Claude-Automation
## Based on Research of Best Practices

## Overview
Based on extensive research into orchestration patterns, dependency management, and process coordination, we recommend implementing a **Bootstrap Orchestrator Module** to manage all subsystem initialization and coordination.

## Architecture Components

### 1. Bootstrap Orchestrator Module
A new central module responsible for:
- **Initialization Sequencing**: Using topological sort to determine startup order
- **Dependency Resolution**: Ensuring subsystems start only after dependencies
- **Process Lifecycle Management**: Starting, monitoring, and restarting subsystems
- **Singleton Enforcement**: Using named mutexes to prevent duplicates
- **Health Monitoring**: Heartbeat-based liveness detection

### 2. Subsystem Registration Manifest
Each subsystem provides a manifest defining:
```powershell
@{
    Name = "AutonomousAgent"
    Dependencies = @("SystemStatus", "CLISubmission")
    Priority = 10
    HealthCheckInterval = 30
    RestartPolicy = "OnFailure"
    MaxRestarts = 3
    StartupScript = ".\Start-AutonomousMonitoring-Fixed.ps1"
    Mutex = "Global\UnityClaudeAutonomousAgent"
}
```

### 3. Implementation Pattern

#### Phase 1: Discovery and Registration
```powershell
function Initialize-BootstrapOrchestrator {
    # 1. Discover all subsystem manifests
    $subsystems = Get-ChildItem ".\Modules\*\*.manifest.psd1" | 
        ForEach-Object { Import-PowerShellDataFile $_ }
    
    # 2. Build dependency graph
    $dependencyGraph = Build-DependencyGraph -Subsystems $subsystems
    
    # 3. Topological sort for initialization order
    $initOrder = Get-TopologicalSort -Graph $dependencyGraph
    
    return $initOrder
}
```

#### Phase 2: Singleton Enforcement
```powershell
function Start-SubsystemWithMutex {
    param($Subsystem)
    
    # Create named mutex for this subsystem
    $mutex = New-Object System.Threading.Mutex($false, $Subsystem.Mutex)
    
    try {
        if ($mutex.WaitOne(0)) {
            # We got the mutex - start the subsystem
            Start-Process -FilePath "powershell.exe" `
                -ArgumentList "-File", $Subsystem.StartupScript `
                -PassThru
        } else {
            Write-Warning "$($Subsystem.Name) already running"
            return $null
        }
    } finally {
        $mutex.ReleaseMutex()
        $mutex.Dispose()
    }
}
```

#### Phase 3: Health Monitoring
```powershell
function Start-SubsystemMonitor {
    param($Subsystems)
    
    while ($true) {
        foreach ($subsystem in $Subsystems) {
            # Check heartbeat
            if (-not (Test-SubsystemHeartbeat $subsystem)) {
                # Restart if policy allows
                if ($subsystem.RestartPolicy -eq "OnFailure") {
                    Restart-Subsystem $subsystem
                }
            }
        }
        Start-Sleep -Seconds 10
    }
}
```

## Benefits Over Current Architecture

### Current Issues
- Multiple agents can start simultaneously
- No coordination between subsystems
- Manual dependency management
- Inconsistent initialization patterns
- Difficult to debug startup issues

### With Bootstrap Orchestrator
- **Guaranteed Single Instance**: Mutex enforcement prevents duplicates
- **Automatic Dependency Resolution**: Topological sort ensures correct order
- **Self-Healing**: Automatic restart of failed subsystems
- **Centralized Logging**: All initialization in one place
- **Scalable**: Easy to add new subsystems

## Implementation Phases

### Phase 1: Core Orchestrator (Week 1)
- [ ] Create Bootstrap-Orchestrator module
- [ ] Implement dependency graph builder
- [ ] Add topological sort algorithm
- [ ] Basic subsystem launcher

### Phase 2: Singleton & Monitoring (Week 2)
- [ ] Add mutex-based singleton enforcement
- [ ] Implement heartbeat monitoring
- [ ] Add restart policies
- [ ] Create health dashboard

### Phase 3: Migration (Week 3)
- [ ] Create manifests for existing subsystems
- [ ] Update Start-UnifiedSystem to use orchestrator
- [ ] Add backward compatibility layer
- [ ] Comprehensive testing

## Key Design Decisions

### Why Topological Sort?
- **Proven Algorithm**: O(n+m) linear time complexity
- **Handles Complex Dependencies**: Works with any DAG
- **Detects Circular Dependencies**: Fails fast on invalid configs
- **Industry Standard**: Used in build systems, package managers

### Why Named Mutexes?
- **OS-Level Enforcement**: Works across all processes
- **No Race Conditions**: Atomic acquisition
- **Cross-Session Support**: Global\ prefix for system-wide
- **Reliable Cleanup**: OS handles abandoned mutexes

### Why Supervisor Pattern?
- **Fault Tolerance**: Automatic recovery from failures
- **Observability**: Centralized monitoring point
- **Scalability**: Can manage many subsystems
- **Proven Pattern**: Used in Erlang/OTP, Kubernetes, etc.

## Example Usage

```powershell
# User runs this single command
.\Start-UnityClaudeSystem.ps1

# Behind the scenes:
# 1. Bootstrap Orchestrator starts
# 2. Discovers all subsystem manifests
# 3. Resolves dependencies (SystemStatus -> CLISubmission -> AutonomousAgent)
# 4. Starts each subsystem in order with mutex protection
# 5. Monitors health and restarts as needed
```

## Monitoring Dashboard Example
```
==========================================
UNITY-CLAUDE SYSTEM STATUS
==========================================
Bootstrap Orchestrator: RUNNING (PID: 12345)

Subsystems:
  [✓] SystemStatus       - RUNNING (PID: 12346) - Uptime: 00:15:32
  [✓] CLISubmission      - RUNNING (PID: 12347) - Uptime: 00:15:30  
  [✓] AutonomousAgent    - RUNNING (PID: 12348) - Uptime: 00:15:28

Health Metrics:
  - Last Check: 2025-08-21 22:30:15
  - Total Restarts: 0
  - System Health: HEALTHY

Press Ctrl+C to shutdown system gracefully
==========================================
```

## Conclusion

The Bootstrap Orchestrator pattern provides a robust, scalable solution to the current duplicate process and coordination issues. It follows industry best practices and proven patterns from distributed systems, microservices, and process supervision domains.

This architecture will:
1. Eliminate duplicate processes through mutex enforcement
2. Ensure correct initialization order through dependency resolution
3. Provide self-healing through automatic restarts
4. Improve observability through centralized monitoring
5. Simplify the user experience with a single entry point