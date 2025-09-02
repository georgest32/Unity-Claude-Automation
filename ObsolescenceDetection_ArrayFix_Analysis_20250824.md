# Obsolescence Detection Array Operation Fix Analysis
**Date**: 2025-08-24
**Time**: Current
**Issue**: Test-CodeRedundancy op_Subtraction array operation error
**Previous Context**: NodeType enum reference fix applied
**Topics**: PowerShell array operations, regex matches, arithmetic operations

## Problem Analysis

### Error Message
```
Failed to test code redundancy: Method invocation failed because [System.Object[]] does not contain a method named 'op_Subtraction'.
```

### Root Cause
PowerShell's `[regex]::Matches()` method returns a MatchCollection object. When accessing the `.Count` property on this collection and trying to perform arithmetic operations, PowerShell 5.1 can sometimes treat it as an array rather than a scalar value, causing the op_Subtraction error.

### Location Identified
Lines 654-656 in Unity-Claude-ObsolescenceDetection.psm1:
```powershell
$openBraces = ([regex]::Matches($line, '\{').Count)
$closeBraces = ([regex]::Matches($line, '\}').Count)
$nestingLevel += $openBraces - $closeBraces
```

## Solution Applied

### Fix Implementation
Changed the code to explicitly convert the MatchCollection to an array before accessing Count:
```powershell
$openBraces = @([regex]::Matches($line, '\{')).Count
$closeBraces = @([regex]::Matches($line, '\}')).Count
$nestingLevel += ($openBraces - $closeBraces)
```

### Why This Works
1. The `@()` array subexpression operator ensures the result is treated as an array
2. Accessing `.Count` on an array always returns a scalar integer
3. Parentheses around the subtraction ensure proper operation order

## Research Findings

### Common Causes of op_Subtraction Error
1. **Select-String returning multiple matches** - LineNumber becomes an array
2. **Properties unexpectedly returning arrays** - Like ADPropertyValueCollection
3. **Null values in arithmetic** - Cannot subtract from null
4. **Regex Matches collections** - Count property behaves inconsistently

### Best Practices
1. Always wrap collections in `@()` when you need a reliable Count
2. Use `(collection | Measure-Object).Count` for guaranteed scalar result
3. Check for null/array before arithmetic operations
4. Use parentheses to ensure operation order

## Testing Status
- Fixed enum references: [NodeType] → [CPGNodeType]
- Fixed array arithmetic: Added @() wrapper for regex matches
- Ready for re-testing of all 8 test scenarios

## Expected Outcome
All 8 tests in Test-ObsolescenceDetection.ps1 should now pass:
1. Code Perplexity Analysis - Was passing
2. Unreachable Code Detection - Fixed (enum issue)
3. Code Redundancy Testing - Fixed (array operation issue)
4. Code Complexity Metrics - Fixed (enum issue)
5. Documentation Drift Detection (4 sub-tests) - Fixed (enum issue)