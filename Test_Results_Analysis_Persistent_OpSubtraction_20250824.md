# Test Results Analysis: Persistent op_Subtraction Error
**Date**: 2025-08-24
**Time**: Current
**Issue**: Test-CodeRedundancy still failing with op_Subtraction error after multiple fixes
**Previous Context**: Phase 6 CPG Module Testing - Multiple array operation fixes applied
**Topics**: PowerShell array operations, persistent debugging, Test-CodeRedundancy function

## Current Test Status
- **Total Tests**: 8
- **Passed**: 7 (87.5%)
- **Failed**: 1 (12.5%)
- **Failing Test**: Test-CodeRedundancy
- **Error Location**: Line 335 in Test-ObsolescenceDetection.ps1

## Error Details
```
Failed to test code redundancy: Method invocation failed because [System.Object[]] does not contain a method named 'op_Subtraction'.
```

## Previous Fixes Applied

### Fix #1: Enum Reference Consistency (Learning #224)
- **Applied**: Changed [NodeType] to [CPGNodeType]
- **Result**: Fixed 6/8 tests (75% → 87.5%)
- **Status**: ✅ Successful

### Fix #2: Count Property Arithmetic Safety (Learning #225)
- **Applied**: Added [int] casting to 15 locations
- **Pattern Used**: [int]@(collection).Count and [int]collection.Count
- **Result**: Caused CLR crash (0x80131506)
- **Status**: ❌ Reverted

### Fix #3: Measure-Object Pattern
- **Applied**: Replaced [int] casting with ($collection | Measure-Object).Count
- **Locations Fixed**: 6 major locations
- **Result**: Still failing Test-CodeRedundancy
- **Status**: ⚠️ Partial success

## Current Problem Analysis

The Test-CodeRedundancy function is still failing at line 335. Despite our extensive fixes:
1. Enum references are correct
2. Major Count operations use Measure-Object
3. Regex Matches are wrapped in @() operators

**This suggests there's still an undiscovered array operation causing the op_Subtraction error.**

## Investigation Plan

### Phase 1: Deep Function Analysis
1. Examine Test-CodeRedundancy function line by line
2. Identify all arithmetic operations
3. Find any remaining .Count or array operations
4. Look for subtraction (-) operations specifically

### Phase 2: Targeted Fix
1. Apply safe patterns to remaining operations
2. Test specific function in isolation if possible
3. Verify fix resolves the error

### Phase 3: Comprehensive Validation
1. Run full test suite
2. Ensure 8/8 tests pass (100%)
3. Update documentation with final solution

## Research Questions

1. Are there any direct array subtraction operations we missed?
2. Could there be implicit type conversions causing arrays?
3. Are there nested function calls that return arrays?
4. Could this be in the Levenshtein distance calculation?

## Success Criteria
- Test-CodeRedundancy passes without op_Subtraction error
- All 8 tests achieve 100% pass rate
- No CLR crashes or memory issues
- Solution is stable and maintainable