# Simplified Unity-Claude-Automation Architecture
## Date: 2025-08-21

## Overview
To avoid duplicate agent issues, we're using a simplified architecture where the SystemStatus monitor is the sole launcher and manager of the AutonomousAgent.

## How It Works

### Single Point of Control
The SystemStatus monitor is the ONLY component that should start AutonomousAgent:
1. User runs `Start-UnifiedSystem-Simple.ps1` or starts the monitor directly
2. Monitor checks every 30 seconds if AutonomousAgent is running
3. If not running, monitor starts it automatically
4. If it crashes, monitor restarts it
5. Monitor prevents duplicates by checking PIDs

### Key Scripts

#### Start-UnifiedSystem-Simple.ps1
- Cleans up any existing agents
- Clears stale registrations  
- Starts the SystemStatus monitor
- Monitor handles everything else

#### Start-SystemStatusMonitoring-Enhanced.ps1
- The actual monitoring script
- Checks agent status every 30 seconds
- Calls `Start-AutonomousAgentSafe` when needed
- Logs all activity

#### Start-AutonomousMonitoring-Fixed.ps1
- The actual AutonomousAgent script
- Self-registers with SystemStatus using its PID
- Should ONLY be started by the monitor
- Users should NOT run this directly

## Usage

### To Start the System
```powershell
.\Start-UnifiedSystem-Simple.ps1
```

### To Stop Everything
```powershell
# Kill all monitoring and agent windows
Get-Process | Where-Object { 
    $_.MainWindowTitle -like "*MONITORING*" -or
    $_.MainWindowTitle -like "*AUTONOMOUS*"
} | Stop-Process -Force
```

## Benefits
1. **No Duplicates**: Monitor ensures only one agent runs
2. **Auto-Recovery**: Agent automatically restarts if it crashes
3. **Single Entry Point**: Users only need to know one script
4. **Clear Logs**: All activity logged by SystemStatus monitor

## Fixed Issues
1. **PID Mismatch**: Fixed by waiting for agent to self-register
2. **Duplicate Prevention**: Fixed by reading status from file before registering
3. **Process Tracking**: Monitor correctly tracks actual agent PID, not wrapper PID

## Architecture Diagram
```
User
  |
  v
Start-UnifiedSystem-Simple.ps1
  |
  v
SystemStatus Monitor (running in window)
  |
  ├──[Every 30 seconds]──> Check if AutonomousAgent running
  |                          |
  |                          ├──[If not running]──> Start-AutonomousAgentSafe
  |                          |                        |
  |                          |                        v
  |                          |                    Start-AutonomousMonitoring-Fixed.ps1
  |                          |                        |
  |                          |                        v
  |                          |                    Self-registers with correct PID
  |                          |
  |                          └──[If running]──> Continue monitoring
  |
  └──[Logs all activity to console]
```

## Important Notes
- Do NOT run Start-AutonomousMonitoring-Fixed.ps1 directly
- Do NOT try to manage agents manually
- Let the monitor handle everything
- Check monitor window for status and logs