# Unity-Claude Automation System Architecture
**Date:** 2025-08-18  
**Version:** 2.0

## System Overview
The Unity-Claude Automation system consists of multiple components working together to detect, analyze, and fix Unity compilation errors autonomously.

## Component Responsibilities

### 1. Unity Components (C# Scripts in Unity)

#### SafeConsoleExporter.cs
- **Purpose:** Export Unity compilation errors to JSON
- **Location:** `Dithering/Assets/Scripts/SafeConsoleExporter.cs`
- **Output:** `unity_errors_safe.json`
- **Responsibilities:**
  - Monitor Unity compilation events
  - Capture errors using Application.logMessageReceived
  - Export to JSON only when errors change
- **Issues to Fix:**
  - Currently exports every few seconds causing FileWatcher spam
  - Should only export when error count/content changes

#### ConsoleErrorExporter.cs
- **Status:** Active (uses different export path)
- **Location:** `Dithering/Assets/ConsoleErrorExporter.cs`
- **Output:** `AutomationLogs/current_errors.json`

#### UnityConsoleExporter.cs
- **Status:** DISABLED (causes LogEntries assertion failures)
- **Location:** `Dithering/Assets/Scripts/UnityConsoleExporter.cs`

### 2. PowerShell Monitoring System

#### Unity-Claude-ReliableMonitoring.psm1
- **Purpose:** Detect file changes and trigger callbacks
- **Responsibilities:**
  - Monitor `unity_errors_safe.json` for changes
  - Trigger callback when NEW errors detected (not just file updates)
  - Should ignore timestamp-only changes

#### Unity-Claude-CLISubmission.psm1
- **Purpose:** Submit prompts to Claude Code CLI
- **Responsibilities:**
  - Format error information into prompts
  - Find and activate Claude Code CLI window
  - Submit prompts via SendKeys

### 3. Autonomous System Scripts

#### Start-ImprovedAutonomy-Fixed.ps1
- **Purpose:** Main entry point for autonomous monitoring
- **Responsibilities:**
  - Initialize monitoring
  - Set up callback chain
  - Manage session state

## Current Problems & Solutions

### Problem 1: Excessive File Change Detection
**Issue:** SafeConsoleExporter updates JSON every 2 seconds even with no changes
**Solution:** Modify SafeConsoleExporter to only write when errors actually change

### Problem 2: ~~Circular Logic~~ [RESOLVED]
**Current Architecture:** The system correctly uses separate windows:
- **Window 1:** Claude Code CLI (receives prompts and fixes errors)
- **Window 2:** Autonomous System (monitors Unity and submits prompts)
- **Window 3:** Server (additional services)

This is the correct design - no circular logic!

### Problem 3: Duplicate Error Entries
**Issue:** Errors accumulate in JSON instead of replacing
**Solution:** Clear errors array before adding new ones

## Current Architecture (System A - Working Implementation)

```
Unity Editor (Dithering Project)
    ↓ (compilation errors)
SafeConsoleExporter.cs (Application.logMessageReceived)
    ↓ (writes JSON only on actual changes)
unity_errors_safe.json
    ↓ (file change detected via FileSystemWatcher)
ReliableMonitoring Module (Window 2)
    ↓ (new errors detected, not just file updates)
Autonomous Callback
    ↓ (generates structured prompt with boilerplate format)
Unity-Claude-CLISubmission Module
    ↓ (submits comprehensive prompt)
Claude Code CLI (Window 1)
    ↓ (analyzes errors and implements fixes directly)
Unity Project Files
    ↓ (triggers recompilation)
SafeConsoleExporter.cs (detects error resolution)

```

**Window Distribution:**
- **Window 1:** Claude Code CLI (receives prompts, implements fixes)
- **Window 2:** Autonomous System (monitors Unity, submits prompts) 
- **Window 3:** Server (additional services)

**Key Improvement:** Enhanced prompt generation now follows boilerplate structure with:
- Proper prompt-type identification (Debugging)
- Comprehensive project context and environment details
- Structured error analysis with specific Unity error codes
- Clear success criteria and validation requirements
- System A architecture alignment (Claude implements fixes directly)

## Immediate Actions Needed

1. **Fix SafeConsoleExporter.cs**
   - Only export when errors change
   - Clear old errors before adding new ones
   - Add proper change detection

2. **Fix ReliableMonitoring Module**
   - Ignore timestamp-only changes
   - Track error content, not just count

3. **Clarify Execution Model**
   - Decide: Self-contained or separate windows
   - Document the chosen approach

4. **Remove Redundancy**
   - Disable duplicate exporters
   - Consolidate to single error export path

## File Paths Reference

### Unity Project
- Base: `C:\UnityProjects\Sound-and-Shoal\Dithering\`
- Scripts: `Assets\Scripts\`
- Editor: `Assets\Editor\`

### Automation System
- Base: `C:\UnityProjects\Sound-and-Shoal\Unity-Claude-Automation\`
- Modules: `Modules\`
- Logs: `AutomationLogs\`

### Output Files
- Primary: `unity_errors_safe.json`
- Secondary: `AutomationLogs\current_errors.json`
- Unity Log: `C:\Users\georg\AppData\Local\Unity\Editor\Editor.log`

## Testing Checklist

- [ ] SafeConsoleExporter only writes on actual changes
- [ ] FileWatcher doesn't trigger on timestamp-only updates
- [ ] Errors are properly cleared between compilations
- [ ] No duplicate error entries in JSON
- [ ] Clear responsibility boundaries
- [ ] No circular dependencies