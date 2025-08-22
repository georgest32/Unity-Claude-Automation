# Week 6 Modular Architecture - Using Variable Scope Fix
**Date**: 2025-08-21
**Time**: Analysis Round 2
**Problem**: "A Using variable cannot be retrieved" errors in 3 tests
**Previous Context**: Fixed $using expression syntax, added function exports
**Topics**: PowerShell scope modifiers, scriptblock invocation, module context

## Problem Summary
The module now loads and exports 44 functions successfully, but we're getting runtime errors:
1. **Core initialization error**: Using variable cannot be retrieved
2. **Integration functionality error**: Using variable cannot be retrieved  
3. **Queue management error**: Using variable cannot be retrieved

## Error Analysis

### The $using Scope Modifier Limitation
The error states: "A Using variable can be used only with Invoke-Command, Start-Job, or InlineScript"

**Current Pattern (WRONG)**:
```powershell
& $parentModule { 
    Set-NotificationState -StateType 'Config' -Property $using:key -Value $using:value 
}
```

**Problem**: The `& $parentModule { }` syntax is NOT one of the supported contexts for $using:
- ✅ Invoke-Command (for remote execution)
- ✅ Start-Job (for background jobs)
- ✅ InlineScript (in workflows)
- ❌ & (call operator with module scriptblock)

## Root Cause
When using `& $parentModule { }`, we're executing a scriptblock in the module's context, but this is NOT the same as Invoke-Command. The $using: scope modifier is specifically designed for cross-process or remote execution contexts, not for simple scriptblock invocation.

## Solution Approaches

### Approach 1: Use Script Parameters (RECOMMENDED)
Instead of $using:, pass values as parameters to the scriptblock:

```powershell
& $parentModule {
    param($key, $value)
    Set-NotificationState -StateType 'Config' -Property $key -Value $value
} -key $key -value $value
```

### Approach 2: Use ForEach-Object with Pipeline
Use the pipeline to pass values:

```powershell
$params = @{key=$key; value=$value}
$params | ForEach-Object {
    & $parentModule {
        param($p)
        Set-NotificationState -StateType 'Config' -Property $p.key -Value $p.value
    } -p $_
}
```

### Approach 3: Direct Module Function Invocation
Since modules are in the same process, we can invoke functions directly:

```powershell
& $parentModule Set-NotificationState -StateType 'Config' -Property $key -Value $value
```

## Implementation Plan

### Files to Fix
1. **NotificationCore.psm1** - Fix all & $parentModule invocations
2. **QueueManagement.psm1** - Fix state update calls
3. **MetricsAndHealthCheck.psm1** - Fix state update calls

### Pattern to Replace
All instances of:
```powershell
& $parentModule { 
    Write-Host "[MODULE->PARENT] ..." 
    Set-NotificationState ... $using:variable 
}
```

With:
```powershell
& $parentModule {
    param($var1, $var2)
    Write-Host "[MODULE->PARENT] ..."
    Set-NotificationState ... $var1 ... $var2
} -var1 $variable1 -var2 $variable2
```

## Testing Status
- Module loading: ✅ Working
- Function exports: ✅ 44 functions exported
- Core initialization: ❌ Using variable error
- Integration hooks: ❌ Using variable error
- Context management: ✅ Working
- Queue management: ❌ Using variable error
- Configuration: ✅ Working
- Monitoring: ✅ Working
- Components accessible: ✅ Working

## Expected Outcome
After fixing the $using variable scope issues:
- All 9 tests should pass
- No "Using variable cannot be retrieved" errors
- Proper state sharing between modules
- Extensive debug logging showing state operations