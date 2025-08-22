# SystemStatusMonitoring Enhancement Plan
## Expanding Existing Module vs Creating New Bootstrap Orchestrator

## Executive Summary
**Recommendation: Expand SystemStatusMonitoring** rather than create a new Bootstrap Orchestrator module.

## Rationale

### Why Expand Rather Than Create New

1. **SystemStatusMonitoring Already Does 70% of What We Need**
   - Has subsystem registration
   - Has health monitoring
   - Has process management (for AutonomousAgent)
   - Has event loops and timers
   - Has comprehensive logging

2. **Natural Evolution**
   - A monitor that detects failures naturally should restart them
   - A monitor that tracks subsystems naturally should start them
   - A monitor with health checks naturally should enforce policies

3. **Less Code Duplication**
   - Both would need PID tracking
   - Both would need subsystem registration
   - Both would need health checks
   - Both would need logging

4. **Simpler Architecture**
   - One module to maintain instead of two
   - One process running instead of two
   - One configuration point instead of two

## Proposed Enhancements

### Phase 1: Add Mutex-Based Singleton Enforcement
```powershell
# In Initialize-SystemStatusMonitoring
$script:SystemMutex = New-Object System.Threading.Mutex($false, "Global\UnityClaudeSystemStatus")
if (-not $script:SystemMutex.WaitOne(0)) {
    Write-Warning "SystemStatusMonitoring already running"
    exit
}

# In Register-Subsystem
if ($Manifest.Mutex) {
    $mutex = New-Object System.Threading.Mutex($false, $Manifest.Mutex)
    if (-not $mutex.WaitOne(0)) {
        # Kill existing process
        Stop-Process -Id $existingPid -Force
    }
}
```

### Phase 2: Add Manifest-Based Configuration
```powershell
# New structure: Modules\*\subsystem.manifest.psd1
@{
    Name = "AutonomousAgent"
    Dependencies = @("SystemStatus", "CLISubmission")
    StartScript = ".\Start-AutonomousMonitoring-Fixed.ps1"
    HealthCheck = "Test-AutonomousAgentStatus"
    RestartPolicy = "OnFailure"
    MaxRestarts = 3
    Mutex = "Global\UnityClaudeAutonomousAgent"
}
```

### Phase 3: Add Dependency Resolution
```powershell
function Get-SubsystemStartOrder {
    $manifests = Get-ChildItem ".\Modules\*\*.manifest.psd1" | 
        ForEach-Object { Import-PowerShellDataFile $_ }
    
    # Build dependency graph
    $graph = @{}
    foreach ($manifest in $manifests) {
        $graph[$manifest.Name] = $manifest.Dependencies
    }
    
    # Topological sort
    return Get-TopologicalSort -Graph $graph
}
```

### Phase 4: Generalize Process Management
```powershell
# Instead of hardcoded Test-AutonomousAgentStatus
function Test-SubsystemStatus {
    param($SubsystemName)
    
    $manifest = Get-SubsystemManifest $SubsystemName
    if ($manifest.HealthCheck) {
        & $manifest.HealthCheck
    } else {
        # Default PID check
        Test-ProcessAlive -ProcessId $subsystem.ProcessId
    }
}

# Instead of hardcoded Start-AutonomousAgentSafe
function Start-SubsystemSafe {
    param($SubsystemName)
    
    $manifest = Get-SubsystemManifest $SubsystemName
    Start-Process -FilePath "powershell.exe" `
        -ArgumentList "-File", $manifest.StartScript `
        -PassThru
}
```

### Phase 5: Update Main Monitoring Loop
```powershell
# In the timer event
foreach ($subsystemName in Get-RegisteredSubsystems) {
    $status = Test-SubsystemStatus -SubsystemName $subsystemName
    
    if (-not $status.IsRunning) {
        $manifest = Get-SubsystemManifest $subsystemName
        
        if ($manifest.RestartPolicy -eq "OnFailure") {
            if ($status.RestartCount -lt $manifest.MaxRestarts) {
                Start-SubsystemSafe -SubsystemName $subsystemName
            }
        }
    }
}
```

## Migration Path

### Week 1: Foundation
1. Add mutex support to prevent duplicates
2. Fix current PID tracking issues
3. Add manifest loading capability

### Week 2: Generalization  
1. Create manifests for existing subsystems
2. Replace hardcoded AutonomousAgent logic with generic
3. Add dependency resolution

### Week 3: Testing & Polish
1. Test with multiple subsystems
2. Add dashboard improvements
3. Documentation

## Benefits of This Approach

1. **Incremental** - Can be done step by step
2. **Backward Compatible** - Old scripts keep working
3. **Unified** - Single source of truth for system state
4. **Proven** - Building on working code
5. **Maintainable** - One module instead of two

## Example Enhanced Usage

```powershell
# Start system - orchestrator functionality built-in
.\Start-SystemStatusMonitoring-Enhanced.ps1 -EnableOrchestration

# Behind the scenes:
# 1. Discovers all subsystem manifests
# 2. Resolves dependencies
# 3. Starts subsystems in order
# 4. Monitors health
# 5. Restarts on failure per policy
```

## Comparison Table

| Feature | Current | With Enhancements |
|---------|---------|-------------------|
| Duplicate Prevention | PID-based (broken) | Mutex-based (robust) |
| Subsystem Support | AutonomousAgent only | Any subsystem via manifest |
| Dependencies | None | Topological sort |
| Configuration | Hardcoded | Manifest-driven |
| Restart Policies | Implicit | Configurable per subsystem |
| Startup Order | Random | Dependency-based |

## Conclusion

Expanding SystemStatusMonitoring is the right approach because:
1. It already has most infrastructure we need
2. Monitoring and orchestration are naturally related
3. Less code duplication and complexity
4. Easier migration path
5. Single process managing everything

The enhancements turn SystemStatusMonitoring into a full-featured subsystem orchestrator while preserving its monitoring capabilities.