# RAPID WINDOW SWITCHING Implementation Session
**Date**: 2025-08-17
**Time**: Current Session
**Previous Context**: Unity-Claude-Automation Phase 3.5 Complete, moving to rapid switching feature
**Topics**: P/Invoke SendInput, Alt+Tab automation, sub-second window switching, Unity compilation triggers

## Summary Information
- **Problem**: Unity requires focus to compile, current Force-UnityCompilation.ps1 takes 2+ seconds
- **Solution**: Implement rapid Alt+Tab switching using P/Invoke SendInput to achieve <500ms switching
- **Implementation Phase**: Week 1, Day 1, Hour 1-2 (Creating P/Invoke foundation)
- **Target**: 150-300ms typical switching time

## Project Context

### Home State
- **Project Root**: C:\UnityProjects\Sound-and-Shoal\Unity-Claude-Automation
- **Unity Version**: 2021.1.14f1
- **PowerShell Version**: 5.1 (Windows PowerShell)
- **Platform**: Windows (win32)
- **Current Phase**: Phase 3.5 Complete, implementing rapid switching feature

### Current Implementation Status
- Unity-Claude-Automation v2.0 operational
- Phase 2 (Bidirectional Communication) complete with 92% test success
- Phase 3 (Self-Improvement) 80% complete with fuzzy matching implemented
- Phase 3.5 (Integration Debugging) complete with encoding issues resolved

### Objectives
- **Short-term**: Implement rapid window switching in <500ms
- **Long-term**: Zero-touch Unity compilation triggering with minimal user disruption

## Implementation Plan (From ARP Document)

### Week 1, Day 1: P/Invoke Foundation (4 hours)

#### Hour 1-2: Create Invoke-RapidUnitySwitch.ps1
- Define SendInput P/Invoke structures
- Set up Windows API imports
- Create INPUT structure definitions
- Implement key constant definitions

#### Hour 3-4: Core Switch Logic
- Store current window handle
- Create INPUT array for Alt+Tab
- Implement timing measurement with Stopwatch
- Add configurable wait time

## Research Findings Summary
- **SendInput Speed**: <1ms for keystroke injection
- **Alt+Tab Animation**: 50-100ms system dependent
- **Unity Focus Detection**: Immediate upon gaining focus
- **Total Expected Time**: 150-300ms typical, <500ms worst case

## Current Flow of Logic
1. Store current window handle using GetForegroundWindow
2. Build INPUT array for Alt+Tab sequence (Alt down, Tab down, Tab up, Alt up)
3. Send Alt+Tab using SendInput to switch to Unity
4. Wait configurable time (default 75ms) for Unity to process
5. Send Alt+Tab again to return to original window
6. Measure and report total time

## Implementation Steps

### Step 1: Create Base Script with P/Invoke Definitions
### Step 2: Implement Core Switching Logic
### Step 3: Add Debug Logging Throughout
### Step 4: Test and Measure Performance
### Step 5: Integrate with ConsoleErrorExporter

## Debug Points to Add
- Before storing original window
- After getting window handle
- Before each SendInput call
- After each SendInput call
- Before and after wait period
- Total time measurement
- Error handling for API calls

## Success Benchmarks
- Total switch time < 500ms
- Unity compilation triggers reliably
- Returns to correct window
- Works with ConsoleErrorExporter
- Handles edge cases gracefully

## Critical Learnings to Remember
1. **UTF-8 BOM Required**: PowerShell 5.1 requires UTF-8 with BOM encoding
2. **SendInput Superior**: P/Invoke SendInput is fastest (<1ms)
3. **MRU Order**: Single Alt+Tab returns to previous window
4. **Unity Immediate**: Unity triggers compilation immediately on focus
5. **Avoid SendKeys**: Too slow, use P/Invoke instead

## Files to Create/Modify
- **Create**: Invoke-RapidUnitySwitch.ps1
- **Update**: IMPLEMENTATION_GUIDE.md with Phase 4 progress
- **Update**: IMPORTANT_LEARNINGS.md with rapid switching findings
- **Log to**: unity_claude_automation.log for centralized logging

## Next Actions
1. Implement P/Invoke definitions in Invoke-RapidUnitySwitch.ps1
2. Add comprehensive debug logging
3. Test basic switching functionality
4. Measure timing performance
5. Document results