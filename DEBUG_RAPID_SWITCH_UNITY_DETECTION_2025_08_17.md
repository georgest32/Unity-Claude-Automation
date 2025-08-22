# Debug Analysis: Rapid Switch Unity Detection Issue
**Date**: 2025-08-17
**Time**: 12:59
**Previous Context**: Implemented Invoke-RapidUnitySwitch.ps1 with P/Invoke SendInput
**Topics**: Unity detection, Alt+Tab switching, window handle tracking, process identification

## Problem Summary
Unity is not being detected after Alt+Tab switching. The window handle remains the same (1577952) before and after the Alt+Tab sequence, indicating the switch is not occurring.

## Home State
- **Project**: Unity-Claude-Automation
- **Unity Project Name**: Dithering
- **PowerShell Version**: 5.1
- **Current Phase**: Phase 4 - Rapid Window Switching Implementation
- **Script**: Invoke-RapidUnitySwitch.ps1

## Error Analysis

### Observed Behavior
1. SendInput returns success (Result: 4) for both Alt+Tab sequences
2. Window handle remains unchanged (1577952) throughout
3. Process remains WindowsTerminal throughout
4. Unity is never detected (UnityDetected: False)
5. First switch takes 9.8ms, second takes 0.27ms

### Current Flow of Logic
1. Store original window handle (WindowsTerminal)
2. Create Alt+Tab input sequence
3. Send first Alt+Tab (successful but no switch)
4. Wait 75ms
5. Check current window (still WindowsTerminal)
6. Send second Alt+Tab (successful but no switch)
7. Check final window (still WindowsTerminal)

## Preliminary Solutions
1. Unity process name might not contain "Unity" - need to check actual process name
2. Alt+Tab might need different timing or key sequence
3. Unity might be minimized or not running
4. Window might need activation before Alt+Tab works
5. SendInput might need different flags or setup

## Research Findings (5 queries completed)

### Unity Process and Window Information
1. **Process Name**: Unity Editor runs as "Unity.exe" in Windows
2. **Window Title Format**: Typically includes project name (e.g., "Dithering"), scene name, Unity version
3. **Related Processes**: UnityHelper.exe, Unity.Licensing, UnityPackageManager, UnityShaderCompiler

### Alt+Tab SendInput Issues
1. **Security Restrictions**: Windows blocks SendInput for Alt+Tab due to UIPI (User Interface Privilege Isolation)
2. **Protected Functionality**: Alt+Tab is system-level functionality protected from programmatic access
3. **UIAccess Required**: Would need special manifest and code signing for UIAccess permission

### Alternative Solutions
1. **SetForegroundWindow**: Direct window activation (with workarounds for restrictions)
2. **AttachThreadInput**: Attach to target thread to bypass focus restrictions
3. **Window Enumeration**: Find Unity window by title/process and activate directly

### Root Cause
The Alt+Tab approach is failing because:
1. Windows security prevents SendInput from triggering Alt+Tab
2. Need to use direct window activation instead
3. Unity detection fails because we're looking for "Unity" in process name but should look for "Unity.exe"

## Research Findings Continued (10 queries completed)

### AttachThreadInput Bypass Method
1. **Core Technique**: Attach current thread to foreground window thread
2. **Steps**: AttachThreadInput → SetForegroundLockTimeout(0) → SetForegroundWindow → Restore
3. **Reliability**: More reliable than Alt+Tab but requires proper implementation

### Window Enumeration for Unity
1. **EnumWindows API**: Can iterate all windows and check titles
2. **Unity Title Pattern**: Contains "Dithering" (project name), scene name, Unity version
3. **Process Filtering**: Look for Unity.exe process with MainWindowTitle

### Alt Key Simulation Alternative
1. **keybd_event**: Can simulate Alt key press to unlock SetForegroundWindow
2. **Virtual Key Code**: VK_MENU (0x12) for Alt key
3. **Sequence**: Alt down → Alt up unlocks focus restrictions temporarily

## Implementation Plan

### Immediate Fix (Hour 1)
1. Replace Alt+Tab SendInput with direct window activation
2. Implement Unity window finding by process name "Unity.exe"
3. Use SetForegroundWindow with Alt key workaround

### Enhanced Solution (Hour 2)
1. Add EnumWindows to find Unity by title containing "Dithering"
2. Implement AttachThreadInput for reliable activation
3. Add fallback methods if primary approach fails

### Testing Plan (Hour 3)
1. Test with Unity running and focused
2. Test with Unity minimized
3. Test with Unity in background
4. Measure timing and reliability

## Solution Implemented

### Version 2 Script Created
**File**: Invoke-RapidUnitySwitch-v2.ps1
**Key Changes**:
1. Replaced Alt+Tab SendInput with direct window activation
2. Added Unity window detection by process name and title
3. Implemented SetForegroundWindow with bypass methods
4. Added AttachThreadInput for reliable activation
5. Simulates Alt key to unlock focus restrictions

### Technical Implementation
1. **Window Finding**: 
   - Search for "Unity.exe" process
   - Enumerate windows for title containing "Dithering"
   - Fallback to window enumeration if process search fails

2. **Focus Bypass Methods**:
   - Alt key simulation (keybd_event)
   - AttachThreadInput with foreground thread
   - SystemParametersInfo to set lock timeout to 0
   - BringWindowToTop before SetForegroundWindow

3. **Timing Optimization**:
   - Direct activation instead of Alt+Tab
   - Configurable wait time (default 75ms)
   - Comprehensive timing measurements

### Expected Results
- Unity window activation in <300ms
- Reliable compilation triggering
- Return to original window
- Works despite Windows security restrictions

## Critical Learnings
1. **Alt+Tab is Protected**: Windows UIPI prevents SendInput from triggering Alt+Tab
2. **Direct Activation Required**: Must use SetForegroundWindow with bypass techniques
3. **Unity Detection**: Process name is "Unity.exe", window title contains project name
4. **Focus Restrictions**: Windows prevents focus stealing, requires workarounds