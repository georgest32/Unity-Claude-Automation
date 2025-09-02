# Obsolescence Detection Persistent op_Subtraction Error Analysis
**Date**: 2025-08-24
**Time**: Current
**Issue**: Test-CodeRedundancy still failing with op_Subtraction error
**Previous Context**: Multiple regex Matches fixes applied but error persists
**Topics**: PowerShell array operations, arithmetic on collections, debugging

## Home State Summary
- Project: Unity-Claude Automation
- Module: Unity-Claude-CPG with ObsolescenceDetection
- PowerShell Version: 5.1
- Test Status: 7/8 tests passing (87.5%)

## Error Analysis

### Current Error
```
Test-CodeRedundancy: Line 335
Failed to test code redundancy: Method invocation failed because [System.Object[]] does not contain a method named 'op_Subtraction'.
```

### Previous Fixes Applied
1. Changed all [NodeType] to [CPGNodeType] - Fixed 6 tests
2. Wrapped multiple regex Matches in @() array operator:
   - Lines 628, 654-655, 676-677

### Problem Still Persists
Despite wrapping regex matches, the error continues. This suggests:
1. There may be other array operations we missed
2. The @() wrapper might not be sufficient in all cases
3. There could be a deeper issue with how values are being processed

## Investigation Areas

### Potential Problem Locations
1. Halstead metrics calculations (lines 685-693)
   - Uses $n1, $n2, $N1, $N2 from regex counts
   - Complex arithmetic operations
   
2. Variable assignment from Select-Object
   - Lines 679-680: Select-Object -Unique may return unexpected types
   
3. Array concatenation operations
   - Multiple += operations throughout the function

## Research Needed
- PowerShell Select-Object behavior with Count property
- Arithmetic operations on potentially null or array values
- Defensive programming for collection operations

## Implementation Plan

### Immediate Fix (Hour 1)
1. Add explicit type conversion for all count operations
2. Ensure scalar values before any arithmetic
3. Add null checks before operations

### Testing (Hour 2)
1. Verify fix resolves the error
2. Ensure no performance degradation
3. Test with various input scenarios

### Documentation (Hour 3)
1. Update IMPORTANT_LEARNINGS.md
2. Document the complete fix pattern
3. Create best practices guide for collection operations