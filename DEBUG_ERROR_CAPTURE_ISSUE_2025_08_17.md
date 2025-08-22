# Debug: Error Capture Issue
**Date**: 2025-08-17
**Time**: 13:30
**Issue**: Unity console shows 4 errors but Invoke-RapidUnityCompile.ps1 captured 0 errors
**Previous Context**: ConsoleErrorExporter should write to Assets/Editor.log every 2 seconds

## Problem Summary
- Unity console displays 4 compilation errors
- Script found Editor.log but detected 0 errors
- Editor.log was not updated during the 2.5 second wait period
- ConsoleErrorExporter may not be running or exporting

## Potential Causes

### 1. ConsoleErrorExporter Not Running
- Script might not be loaded in Unity
- May have compilation errors preventing it from running
- Unity might need manual refresh

### 2. Export Path Mismatch
- ConsoleErrorExporter writes to Assets/Editor.log
- Script reads from same location but file not updating

### 3. Unity Focus Issue
- ConsoleErrorExporter requires Unity to have focus
- EditorApplication.update only runs when Unity is active
- 2.5 seconds might not be enough for first export

### 4. Compilation State
- Errors might be runtime errors, not compilation errors
- ConsoleErrorExporter might only capture compilation errors
- Error format might not match regex pattern

## Diagnostic Steps

### Step 1: Verify ConsoleErrorExporter is Active
1. Check Unity console for "[ConsoleErrorExporter]" messages
2. Look for "Initialized. Exporting to:" message
3. Check if periodic export messages appear

### Step 2: Check Editor.log Contents
1. Open C:\UnityProjects\Sound-and-Shoal\Dithering\Assets\Editor.log
2. Check last modification time
3. Look for error entries

### Step 3: Force Manual Export
1. In Unity, go to menu Unity-Claude/Force Error Export
2. Check if Editor.log updates
3. Verify error format

### Step 4: Test Longer Wait Time
1. Run script with -CompileWaitTime 5000
2. Check if errors are captured with longer wait

## Solutions to Try

### Solution 1: Force Unity Refresh
```powershell
.\Invoke-RapidUnityCompile.ps1 -ForceCompile -CompileWaitTime 5000 -Debug
```

### Solution 2: Check Unity Console for Exporter Status
In Unity:
1. Clear console
2. Look for ConsoleErrorExporter messages
3. Menu: Unity-Claude/Force Error Export

### Solution 3: Verify File Path
```powershell
# Check if Editor.log exists and is recent
Get-Item "C:\UnityProjects\Sound-and-Shoal\Dithering\Assets\Editor.log" | 
    Select-Object Name, LastWriteTime, Length
```

### Solution 4: Manual Compilation Trigger
1. Make a small change to any .cs file
2. Save the file
3. Run the rapid compile script
4. Check if compilation errors are captured

## Error Pattern Analysis
The script looks for "error CS####" pattern. Need to verify:
1. Are the errors compilation errors (CS####)?
2. Are they runtime errors?
3. What's the exact format in the console?

## Next Steps
1. Verify ConsoleErrorExporter is running in Unity
2. Check Editor.log file contents manually
3. Test with longer wait time
4. Force compilation with Ctrl+R