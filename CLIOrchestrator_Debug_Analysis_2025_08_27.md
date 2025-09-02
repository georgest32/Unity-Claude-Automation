# CLI Orchestrator Debug Analysis
**Date**: 2025-08-27  
**Time**: 19:56  
**Context**: Debugging CLI Orchestrator test execution loop and window switching issues

## Problem Summary
1. **Test Execution Loop**: Tests run repeatedly even after completion
2. **Window Switching Failure**: Claude Code CLI window detection is incorrect
3. **Wrong PID Detection**: System detecting PowerShell window instead of Claude CLI

## Root Causes Identified

### 1. Claude Window Detection Issue
**Location**: `WindowManager.psm1` -> `Find-ClaudeWindow` function  
**Current Behavior**: 
- System_status.json shows ProcessId 31912, WindowTitle "Unity-Claude Subsystem - SystemMonitoring"
- This is a PowerShell window, NOT the Claude Code CLI window
- Detection method listed as "AutonomousAgent"

**Root Cause**: The window detection logic is incorrectly identifying any PowerShell window as the Claude CLI

### 2. Test Execution Loop Issue
**Location**: `OrchestrationManager.psm1` lines 179-217  
**Current Behavior**:
- Signal files (TestComplete_*.signal) are detected correctly
- Signal files are processed but never marked as "processed"
- Every monitoring cycle re-processes the same signal files because the filter only checks LastWriteTime > $startTime
- No mechanism to prevent re-processing of already handled signals

**Evidence**:
```powershell
# Line 179-180: Gets all signal files newer than start time
$signalFiles = Get-ChildItem -Path $responseDir -Filter "TestComplete_*.signal" -ErrorAction SilentlyContinue |
               Where-Object { $_.LastWriteTime -gt $startTime }
```

### 3. Missing Signal File Management
**Issue**: No tracking of processed signal files  
**Required Fix**: 
1. Rename processed signal files (e.g., add .processed extension)
2. OR track processed signals in memory/state
3. OR delete signal files after processing

## Flow Analysis

### Current Test Execution Flow
1. Claude recommends TEST action with test file path
2. CLIOrchestrator executes test via `Execute-TestAction`
3. Test completes and creates signal file
4. Signal file is detected in monitoring loop
5. Signal file is processed but NOT marked as complete
6. Next monitoring cycle detects same signal file again
7. Process repeats indefinitely

### Window Switching Flow
1. CLIOrchestrator tries to find Claude window via `Find-ClaudeWindow`
2. Function incorrectly identifies PowerShell window as Claude CLI
3. Window switch attempts go to wrong window
4. TypeKeys input goes to wrong application

## Preliminary Solutions

### Solution 1: Fix Claude Window Detection
```powershell
# Enhanced window detection logic needed:
# - Check for process name containing "claude" or "claude-code"
# - Check for window title containing "Claude"
# - Use more specific window class detection
# - Store and verify against known Claude window handle
```

### Solution 2: Fix Test Signal Processing
```powershell
# After processing signal file (line 217):
# Mark as processed
$processedName = $signalFile.FullName + ".processed"
Rename-Item -Path $signalFile.FullName -NewName $processedName -Force
```

### Solution 3: Implement Proper Window Detection
```powershell
# Check for Claude-specific window characteristics:
# - Terminal window with "claude" in command line
# - Window title pattern matching
# - Process tree analysis (parent/child relationships)
```

## Research Needed
1. PowerShell window detection for specific terminal applications
2. Claude Code CLI window characteristics
3. Signal file management patterns in PowerShell
4. Window handle persistence and verification

## Implementation Plan

### Phase 1: Fix Test Loop (Immediate)
1. Add signal file renaming after processing
2. Update filter to exclude .processed files
3. Test with sample signal files

### Phase 2: Fix Window Detection (Priority)
1. Research Claude Code CLI window characteristics
2. Implement enhanced detection logic
3. Add fallback detection methods
4. Store verified window handle for reuse

### Phase 3: Add Safeguards (Enhancement)
1. Add maximum retry limits
2. Implement circuit breaker for failed operations
3. Add comprehensive logging for debugging
4. Create manual override mechanisms

## Next Steps
1. Implement signal file renaming fix
2. Research Claude Code CLI window detection methods
3. Test enhanced window detection logic
4. Validate complete flow end-to-end