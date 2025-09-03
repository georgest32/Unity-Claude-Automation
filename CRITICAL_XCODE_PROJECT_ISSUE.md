# CRITICAL: Missing Files in Xcode Project

## Problem
The following Swift files were created but are **NOT** in the Xcode project's target membership:
- `AgentsView.swift` ❌
- `TerminalView.swift` ❌  
- `AnalyticsView.swift` ❌

These files exist in git but Xcode doesn't know about them, causing build failures.

## Why This Happens
When files are created from a PC (without Xcode), they:
1. Get added to the filesystem ✅
2. Get committed to git ✅
3. But are NOT added to `project.pbxproj` ❌

## Current Status
Files that ARE in the project:
- `ContentView.swift` ✅
- `DashboardView.swift` ✅
- `WidgetContainerView.swift` ✅

Files that are MISSING from project:
- `AgentsView.swift` ❌
- `TerminalView.swift` ❌
- `AnalyticsView.swift` ❌

## Solutions

### Option 1: Add to Xcode Project (Requires Mac)
Someone with Xcode needs to:
1. Open `AgentDashboard.xcodeproj`
2. Right-click on the Views folder
3. Add Files to "AgentDashboard"
4. Select the three missing Swift files
5. Ensure "AgentDashboard" target is checked
6. Commit and push the updated `project.pbxproj`

### Option 2: Temporary Workaround (PC-friendly)
Remove references to the missing views from ContentView.swift:
```swift
// Comment out these tabs until files are added to project:
// AgentsView(store: store.scope(state: \.agents, action: \.agents))
// TerminalView(store: store.scope(state: \.terminal, action: \.terminal))  
// AnalyticsView(store: store.scope(state: \.analytics, action: \.analytics))
```

### Option 3: Manual pbxproj Edit (Advanced)
Manually edit `project.pbxproj` to add the file references. This is complex and error-prone.

## Verification
Run this command to check which files are in the project:
```bash
grep -o "[A-Za-z]*View\.swift" iOS-App/AgentDashboard/AgentDashboard.xcodeproj/project.pbxproj | sort -u
```

## Prevention
Before creating new Swift files from PC:
1. Check if similar files exist in the project
2. Copy an existing file's pbxproj entries as a template
3. Or have someone with Xcode add the files properly