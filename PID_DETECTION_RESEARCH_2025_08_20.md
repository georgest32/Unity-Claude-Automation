# PID Detection Research Document
**Date:** 2025-08-20  
**Time:** 02:48 AM  
**Issue:** Claude Code CLI window PID detection failing - SendKeys going to wrong window  
**Previous Context:** Terminal registration, window switching, autonomous agent automation  

## Problem Summary
The autonomous agent is unable to correctly identify and send keystrokes to the Claude Code CLI window. Despite multiple attempts at PID registration (ProcessId: 36760, TerminalPID: 16860), the SendKeys automation is targeting the wrong window.

## Current State Analysis
- **system_status.json shows:**
  - ProcessId: 36760 (Node.js process)
  - Status: Active
  - DetectionMethod: Node.js Process
  - Missing TerminalPID after recent updates
- **Issue:** SendKeys requires the window handle/PID that can receive keyboard input, not the Node.js process
- **Symptom:** User had to manually switch windows, automation targeting wrong window

## Key Questions to Research
1. How does Windows differentiate between process PIDs and window handles?
2. What's the relationship between Node.js processes and their terminal windows?
3. How does SendKeys determine which window to target?
4. Why would a registered PID become invalid or target the wrong window?
5. How to reliably get the window handle that can receive keyboard input?

## Initial Hypothesis
The system is confusing:
- Node.js process PID (36760) - the backend process
- Terminal/Console window PID - the actual window that displays and receives input
- Parent process PID - the shell hosting the Node.js process

## Research Findings (First 5 Queries)

### 1. Windows PID vs HWND Fundamentals
**Critical Discovery:** Windows differentiates between Process IDs (PIDs) and Window Handles (HWNDs)
- **PID:** Identifies a process (like node.exe), not a window
- **HWND:** Identifies a specific window that can receive keyboard input
- **Key Issue:** A single process can have 0, 1, or multiple windows
- **SendKeys Requirement:** Needs HWND, not PID, to target specific windows
- **API Function:** GetWindowThreadProcessId converts HWND to PID, but reverse is complex

### 2. PowerShell Window Handle Detection
**Methods to Get HWND:**
- Simple: `(Get-Process -id $pid).MainWindowHandle`
- By Title: `Get-Process | Where-Object {$_.MainWindowTitle -like "*Claude*"}`
- **Problem:** Node.js processes often don't have MainWindowHandle
- **Solution:** Need to use Win32 API via P/Invoke for reliable detection
- **Alternative:** PostMessage API can send keystrokes to specific HWND without focus

### 3. Node.js Process Architecture
**Node.js Process Characteristics:**
- Node.js runs as backend process without window
- Terminal window is separate process (bash.exe, cmd.exe, powershell.exe)
- Parent-child relationship exists but complex on Windows
- WindowsHide option can hide console windows
- Console host behavior differs from Unix systems

### 4. Git Bash Terminal Complexity
**Git Bash Specific Issues:**
- `$$` PID variable returns wrong value in Git Bash
- Multiple processes involved: git-bash.exe, mintty.exe, bash.exe
- Terminal emulator (mintty) is the actual window with HWND
- PowerShell sees "C:\\Program Files\\Git\\bin\\..\\usr\\bin\\bash.exe" as title
- Process tree: mintty.exe -> bash.exe -> node.exe

### 5. Process Detection Challenges
**Why PID Detection Fails:**
- Confusing Node.js process (36760) with terminal window
- Terminal PID changes when shell restarts
- Multiple terminal types (Git Bash, WSL, cmd, PowerShell)
- Window title not unique or predictable
- Parent process detection unreliable across different terminals

## Implementation Plan
(To be developed after research)

## Research Findings (Queries 6-10)

### 6. SetForegroundWindow API Restrictions
**Window Focus Requirements:**
- SetForegroundWindow has limitations since Windows 2000/XP
- Process must meet specific conditions to set foreground window
- Alternative: AttachThreadInput or AllowSetForegroundWindow
- SendMessage/PostMessage can send input without focus
- UI Automation provides modern alternatives

### 7. Terminal Emulator HWND Detection
**MinTTY and Git Bash:**
- MinTTY is Git Bash's default terminal emulator
- MinTTY detection library checks if stderr is attached
- ConPTY API (Windows 10) handles compatibility issues
- Terminal type determined at binary level
- Multiple processes: mintty.exe -> bash.exe -> node.exe

### 8. Node.js MainWindowHandle Behavior
**Background Process Characteristics:**
- MainWindowHandle returns 0 for processes without windows
- Node.js background processes have no UI window
- Hidden windows also return MainWindowHandle = 0
- MainWindowTitle empty for windowless processes
- Background services by definition lack window handles

### 9. Windows API Console Detection
**Console Window Handle Methods:**
- GetConsoleWindow() - modern direct approach
- FindWindow() with unique title - legacy approach
- SendMessage/PostMessage for input without focus
- SendKeys requires active window (limitation)
- EnumChildWindows more reliable than GetWindow loop

### 10. WMI/CIM Parent Process Detection
**Getting Parent Terminal from Child:**
- Get-CimInstance Win32_Process has ParentProcessId
- Trace parent chain: node.exe -> bash.exe -> mintty.exe
- WMI works with less privileges than Get-Process
- PowerShell Core Process.Parent requires admin
- Terminal is typically several levels up the parent chain

## Research Findings (Queries 11-15)

### 11. Windows Process Tree Detection
**Process Tree Methods:**
- wmic.exe for parent-child relationships (slow, >100ms)
- pslist64.exe -t from SysInternals for tree view
- @vscode/windows-process-tree for fast Node.js detection
- Parent process may terminate after spawning child
- Process chain: mintty.exe → bash.exe → node.exe

### 12. PowerShell P/Invoke Window Detection
**Add-Type User32.dll Implementation:**
- FindWindow requires proper null handling with IntPtr.Zero
- GetWindowText needs StringBuilder for buffer
- CharSet.Auto vs CharSet.Unicode considerations
- Multiple overloads needed for null parameters
- GetForegroundWindow for active window detection

### 13. UI Automation Framework
**Modern Window Detection:**
- UIAutomation assembly built into .NET
- FlaUI (UIA3) more reliable than UIA2
- WASP PowerShell snapin for automation
- Test-IsWindowsTerminal checks process hierarchy
- Inspect.exe/Accessibility Insights for exploration

### 14. Node.js process.ppid
**Parent Process in Node:**
- process.ppid returns parent process ID
- ppid = 1 means parent died (orphaned)
- Windows .bat/.cmd require shell option
- find-process npm package provides ppid info
- IPC channels for parent-child communication

### 15. Claude Code Process Architecture
**Claude Code CLI Specifics:**
- Runs as Node.js REPL in terminal
- Installed globally via npm
- Multiple instances can run simultaneously
- Unix philosophy - composable and scriptable
- Session scoped to project folder

## Research Findings (Queries 16-20)

### 16. Console Allocation and Attachment
**AllocConsole vs AttachConsole:**
- AllocConsole creates new console, fails if already attached
- AttachConsole attaches to existing console
- Each process allowed only one console
- Console closed when last attached process exits
- FreeConsole detaches from current console

### 17. Git Bash MinTTY Automation
**MinTTY Challenges:**
- Uses different architecture than native consoles
- winpty required for some console programs
- Standard SendKeys may not work reliably
- Process chain: git-bash.exe → mintty.exe → bash.exe
- Detection requires special handling

### 18. EnumWindows for HWND by PID
**Finding Window by Process ID:**
- EnumWindows iterates all top-level windows
- GetWindowThreadProcessId gets PID from HWND
- Multiple windows can belong to one PID
- Desktop/session limitations apply
- No concept of "main window" in Win32

### 19. PowerShell P/Invoke EnumWindows
**Delegate Callbacks in PowerShell:**
- Requires delegate type declaration
- Callback as script block or C# code
- IntPtr for HWND and LPARAM
- Return true to continue enumeration
- Can filter by visibility or criteria

### 20. Console Host Architecture
**conhost.exe Role:**
- Intermediary between console apps and Windows
- One conhost per console window
- Replaced direct CSRSS handling (security)
- Child of program that created console
- Manages input/output for CLI apps

## Research Findings (Queries 21-25)

### 21. Node.js Detached Process Spawning
**child_process.spawn on Windows:**
- detached: true creates own console window
- Must use stdio: 'ignore' for true independence
- child.unref() prevents parent waiting
- shell: true + detached: true for separate console
- windowsHide conflicts with detached option

### 22. Windows Terminal Process Management
**Terminal Tabs and Panes:**
- Each pane runs in separate process
- $PID gets current PowerShell session ID
- wt.exe split-pane creates new processes
- Enter-PSHostProcess for pane interaction
- No direct GetPaneProcessId API

### 23. SetForegroundWindow Bypass
**AttachThreadInput Method:**
- Windows restricts foreground window changes
- AttachThreadInput bypasses restrictions
- Attach → SetForegroundWindow → Detach pattern
- ALT key simulation 100% reliable
- Doesn't work with console windows

### 24. Claude Code Parent Detection
**WindowsTerminal.exe Relationship:**
- Claude Code runs as Node.js REPL
- WindowsTerminal.exe appears as parent
- Win32_Process class for detection
- WSL originally required, now native
- Parent-child monitoring for security

### 25. PPID Chain Traversal
**Recursive Parent Detection:**
- Get-CimInstance Win32_Process for PPID
- Do-while loop walks up parent chain
- Recursive functions for tree building
- PPID spoofing detection with ETW
- PowerShell Core has Process.Parent property

## Critical Learnings

### Core Problem Identified
**The fundamental issue:** Claude Code CLI (Node.js process) doesn't have a window handle - the terminal emulator does.

### Process Architecture
1. **Windows Terminal/Git Bash**: WindowsTerminal.exe or mintty.exe (has HWND)
2. **Shell Process**: bash.exe or pwsh.exe
3. **Node.js Process**: node.exe running Claude Code (no HWND)

### Why PID Detection Fails
- Saving Node.js PID (36760) doesn't help with window automation
- SendKeys needs HWND, not PID
- Terminal window belongs to different process (mintty/WindowsTerminal)
- MainWindowHandle returns 0 for Node.js processes

### Solution Approach
1. **Traverse Parent Chain**: From Node.js → Shell → Terminal
2. **Find Terminal Window**: Use EnumWindows + GetWindowThreadProcessId
3. **Store Terminal HWND**: Save window handle, not just PID
4. **Use P/Invoke**: PowerShell Add-Type for Win32 API access
5. **AttachThreadInput**: For reliable SetForegroundWindow

### Key APIs Required
- EnumWindows: Find all windows
- GetWindowThreadProcessId: Match window to process
- FindWindow: Direct lookup by title/class
- AttachThreadInput: Bypass focus restrictions
- Get-CimInstance Win32_Process: Parent chain traversal