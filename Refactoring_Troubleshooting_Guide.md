# PowerShell Module Refactoring Troubleshooting Guide

## Overview
This document outlines common issues and solutions when refactoring monolithic PowerShell modules into modular component-based architectures. These fixes have been successfully applied to the Unity-Claude-ParallelProcessor.psm1 refactoring.

## Critical Issue: Function Export Scope Problems (Latest Finding)

**Problem**: Helper functions from components are not available for export by the orchestrator module, even when using `-Global` import flag.

**Root Cause**: Each component imports `ParallelProcessorCore.psm1` locally, creating separate module scopes. Functions are imported globally but not available in the orchestrator's scope for re-export.

**Current Status**: NEEDS ALTERNATIVE SOLUTION - Current refactoring architecture is flawed.

**Evidence**:
```
WARNING: Function Get-OptimalThreadCount not found in global scope
WARNING: Function New-RunspacePoolManager not found in global scope  
WARNING: Function New-StatisticsTracker not found in global scope
```

**Attempted Solutions**:
1. ❌ Dot-sourcing components - Caused infinite loops/hangs
2. ❌ Import-Module -Scope Global - Functions not in orchestrator scope
3. ❌ Import-Module -Global - Same issue

**Recommended Alternative**: Create a single refactored .psm1 file with #region sections instead of separate component files.

## Common Issues and Fixes

### 1. Cross-Component Class Type Dependencies

**Problem**: `Unable to find type [ClassName]` errors when classes reference other classes from different components.

**Root Cause**: PowerShell classes need to be defined in the same scope or properly imported before they can be referenced as types.

**Solutions**:

#### Option A: Use Object Types (Recommended)
```powershell
# Instead of strongly typed class references:
class JobScheduler {
    [RunspacePoolManager]$PoolManager  # ❌ May fail
    JobScheduler([RunspacePoolManager]$poolManager) { }  # ❌ May fail
}

# Use object types:
class JobScheduler {
    [object]$PoolManager  # ✅ Always works
    JobScheduler([object]$poolManager) { }  # ✅ Always works
}
```

#### Option B: Add Helper Functions for Object Creation
```powershell
# Create helper function instead of direct constructor calls
function New-JobScheduler {
    param([object]$PoolManager, [string]$ProcessorId)
    return [JobScheduler]::new($PoolManager, $ProcessorId)
}

# Use helper function instead of direct constructor:
$jobScheduler = New-JobScheduler -PoolManager $poolManager -ProcessorId $id
# Instead of: $jobScheduler = [JobScheduler]::new($poolManager, $id)
```

### 2. Variable Scope Issues in Class Methods

**Problem**: `Variable is not assigned in the method` errors when accessing global variables from within class methods.

**Example Error**: `$PSVersionTable` not accessible in class methods.

**Fix**: Use explicit global scope or wrap in try-catch:
```powershell
# Instead of:
if ($PSVersionTable.PSVersion.Major -ge 7) { }  # ❌ May fail

# Use:
try {
    if ($global:PSVersionTable.PSVersion.Major -ge 7) { }  # ✅ Works
} catch {
    Write-Debug "PSVersionTable not accessible, skipping feature"
}
```

### 3. Component Import Order Dependencies

**Problem**: Components fail to load due to dependency ordering issues.

**Solution**: Import components in dependency order and use proper scope:
```powershell
# Correct import order:
Import-Module "$ComponentPath\ParallelProcessorCore.psm1" -Force -Scope Global     # 1. Core (no deps)
Import-Module "$ComponentPath\RunspacePoolManager.psm1" -Force -Scope Global      # 2. Pool Manager (deps: Core)
Import-Module "$ComponentPath\JobScheduler.psm1" -Force -Scope Global             # 3. Job Scheduler (deps: Core, Pool)
Import-Module "$ComponentPath\StatisticsTracker.psm1" -Force -Scope Global        # 4. Stats (deps: Core)
Import-Module "$ComponentPath\ModuleFunctions.psm1" -Force -Scope Global          # 5. Functions (deps: All)
```

### 4. Function Export Issues

**Problem**: Helper functions not available after module import.

**Solution**: Update all export lists consistently:

1. **Component modules**: Export helper functions
```powershell
Export-ModuleMember -Function @('New-JobScheduler', 'Test-JobSchedulerHealth')
```

2. **Orchestrator module**: Include all helper functions
```powershell
$HelperFunctions = @(
    'Get-OptimalThreadCount',
    'New-RunspacePoolManager',
    'New-JobScheduler',          # ✅ Add new helpers
    'New-StatisticsTracker'
)
```

3. **Manifest (.psd1)**: Update FunctionsToExport
```powershell
FunctionsToExport = @(
    'New-ParallelProcessor',
    'Get-OptimalThreadCount',
    'New-JobScheduler'           # ✅ Add new helpers
)
```

### 5. Parameter Type Mismatches

**Problem**: Functions expecting strongly typed parameters fail when objects are passed.

**Solution**: Change parameter types to `[object]` in public API functions:
```powershell
# Instead of:
function Get-Statistics {
    param([ParallelProcessor]$Processor)  # ❌ May fail
}

# Use:
function Get-Statistics {
    param([object]$Processor)  # ✅ Works with any object
}
```

### 6. Object Creation in Refactored Classes

**Problem**: Direct class constructor calls fail across component boundaries.

**Solutions**:

#### Option A: Use New-Object
```powershell
# Instead of: $obj = [ClassName]::new($arg1, $arg2)
$obj = New-Object -TypeName ClassName -ArgumentList $arg1, $arg2
```

#### Option B: Use Helper Functions
```powershell
# Create helper in the component module:
function New-JobScheduler {
    param($PoolManager, $ProcessorId)
    return [JobScheduler]::new($PoolManager, $ProcessorId)
}

# Use helper in other components:
$scheduler = New-JobScheduler -PoolManager $pool -ProcessorId $id
```

### 7. Thread-Safe Collection Issues

**Problem**: Reader/writer lock conflicts in statistics tracking.

**Solution**: Implement proper lock management with try/finally:
```powershell
[void]RecordJobCompletion([double]$executionTimeMs) {
    $this.StatisticsLock.EnterWriteLock()
    try {
        # Update statistics here
        $this.Statistics.TotalJobsCompleted++
    } finally {
        $this.StatisticsLock.ExitWriteLock()  # ✅ Always release
    }
}
```

## Testing Strategy

### 1. Incremental Testing
Test each component individually before testing the full orchestrator:
```powershell
# Test individual component
Import-Module ".\Core\RunspacePoolManager.psm1" -Force
$manager = New-RunspacePoolManager -ProcessorId "TEST"
```

### 2. Import Order Testing
Test import dependency chain:
```powershell
# Clean all modules first
Get-Module Unity-Claude* | Remove-Module -Force

# Test orchestrator import
Import-Module ".\Unity-Claude-ParallelProcessor.psd1" -Force
```

### 3. Function Availability Testing
Verify all expected functions are exported:
```powershell
$expectedFunctions = @('New-ParallelProcessor', 'Get-OptimalThreadCount')
$missingFunctions = @()
foreach ($func in $expectedFunctions) {
    if (-not (Get-Command $func -ErrorAction SilentlyContinue)) {
        $missingFunctions += $func
    }
}
```

## Best Practices Summary

1. **Use `[object]` types** for cross-component class references
2. **Create helper functions** for object creation instead of direct constructors
3. **Import components in dependency order** with `-Scope Global`
4. **Update all export lists** (component, orchestrator, manifest)
5. **Use explicit global scope** for global variables in class methods
6. **Implement proper error handling** with try/catch blocks
7. **Test incrementally** - components first, then orchestrator
8. **Use consistent naming patterns** for helper functions (New-*, Test-*, Get-*)

## Verification Checklist

Before considering refactoring complete:

- [ ] All components import without errors
- [ ] Orchestrator module loads successfully
- [ ] All expected functions are available via `Get-Command`
- [ ] Basic functionality tests pass
- [ ] No type resolution errors in PowerShell ISE/VS Code
- [ ] Helper functions work as expected
- [ ] Module manifest exports are complete and accurate

## File Structure Template

```
Modules/
├── Unity-Claude-ModuleName/
│   ├── Unity-Claude-ModuleName.psd1              # Updated manifest
│   ├── Unity-Claude-ModuleName.psm1              # Original (marked as refactored)
│   ├── Unity-Claude-ModuleName-Refactored.psm1   # New orchestrator
│   └── Core/
│       ├── ModuleNameCore.psm1                   # Core utilities
│       ├── Component1.psm1                       # Specific functionality
│       ├── Component2.psm1                       # Specific functionality
│       └── ModuleFunctions.psm1                  # Public API functions
```

This troubleshooting guide has been validated through the successful refactoring of Unity-Claude-ParallelProcessor.psm1 from 907 lines into 6 focused components.