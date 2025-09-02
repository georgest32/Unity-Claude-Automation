# PowerShell Compatibility - Unity-Claude Automation
*PowerShell 5.1 compatibility issues, syntax errors, and version-specific workarounds*
*Last Updated: 2025-08-19*

## 🔧 PowerShell 5.1 Syntax and Compatibility Issues

### 13. PowerShell String Interpolation Modulo Operator (⚠️ CRITICAL)
**Issue**: `($variable%)` in strings causes "You must provide a value expression following the '%' operator"
**Discovery**: PowerShell interprets `%` as modulo operator even in string interpolation context
**Evidence**: Test-ModuleRefactoring-Enhanced.ps1 failed with parser errors on `($percentage%)`
**Resolution**: Move `%` outside parentheses: `$percentage%` or use format operator `"{0}%" -f $percentage`
**Critical Learning**: Avoid `($var%)` pattern in PowerShell strings; use `$var%` or format operators instead
**Error Pattern**: Parser reports cascading brace errors when modulo operator syntax is invalid

### 14. PowerShell Backtick Escape Sequence Errors (⚠️ CRITICAL)
**Issue**: `$variable\`:` in strings causes "Missing closing '}'" brace matching errors
**Discovery**: Backtick (\`) before colon creates invalid escape sequence, breaking parser
**Evidence**: Test-ModuleRefactoring-Enhanced.ps1 failed with brace errors on foreach loops
**Resolution**: Remove unnecessary backticks: `$variable:` instead of `$variable\`:`
**Critical Learning**: Only use backtick for valid escape sequences (`\n`, `\t`, `\"`, etc.)
**Error Pattern**: Invalid escape sequences cause parser failure and cascading brace mismatch errors

### 15. PowerShell Variable Drive Reference Ambiguity (⚠️ CRITICAL)
**Issue**: `$variable:` causes "Variable reference is not valid. ':' was not followed by a valid variable name character"
**Discovery**: PowerShell interprets `$variable:` as drive reference syntax (like C:, D:), not variable + colon
**Evidence**: Test-ModuleRefactoring-Enhanced.ps1 failed with InvalidVariableReferenceWithDrive errors
**Resolution**: Use variable delimiting: `${variable}:` instead of `$variable:`
**Critical Learning**: Always delimit variables with `${variable}` when followed by colon to avoid drive reference confusion
**Error Pattern**: Drive reference ambiguity causes cascading parser errors in surrounding code

### 16. PowerShell Unicode Character Contamination (⚠️ CRITICAL)
**Issue**: Persistent "Missing closing '}'" errors on foreach loops despite multiple syntax fixes
**Discovery**: Copy-paste from rich text sources introduces Unicode dashes (U+2013, U+2014) instead of ASCII hyphens (U+002D)
**Evidence**: 5 debugging attempts with same error location indicates Unicode character contamination
**Resolution**: Create ASCII-only scripts, use Unicode detection tools, avoid copy-paste from Word/web
**Critical Learning**: PowerShell 5.1 cannot distinguish Unicode dashes from ASCII hyphens, causing parser failures
**Error Pattern**: Unicode characters cause misleading error locations and persistent syntax failures

### 17. PowerShell Split-Path Parameter Binding Errors (⚠️ CRITICAL)
**Issue**: "Cannot bind parameter because parameter 'Parent' is specified more than once"
**Discovery**: Cannot specify same parameter multiple times in Split-Path command
**Evidence**: `Split-Path $PSScriptRoot -Parent -Parent` syntax is invalid
**Resolution**: Use nested calls: `Split-Path (Split-Path $PSScriptRoot -Parent) -Parent`
**Critical Learning**: Split-Path location parameters (-Parent, -Leaf, -Extension) are mutually exclusive
**Error Pattern**: Parameter binding errors when trying to use same parameter twice

### 18. PowerShell Array Index Expression Errors in Strings (⚠️ CRITICAL)
**Issue**: "Array index expression is missing or not valid" when using [ERROR] or [DEBUG] in Write-Host
**Discovery**: PowerShell interprets square brackets as array indexing syntax even in strings
**Evidence**: `Write-Host "[ERROR] Message"` breaks with array index errors
**Resolution**: Use alternative format: `Write-Host "ERROR: Message"` or escape brackets
**Critical Learning**: Avoid square brackets in PowerShell strings unless escaped or using single quotes
**Error Pattern**: Square brackets in strings cause array indexing interpretation errors

### 20. PowerShell Automatic Variable Collision (⚠️ CRITICAL)
**Issue**: "The '++' operator works only on numbers. The operand is a 'System.Collections.Hashtable'"
**Discovery**: Custom variable `$matches` conflicts with PowerShell automatic `$Matches` variable (hashtable)
**Evidence**: Classification.psm1 using `$matches++` but automatic variable overwrites integer with hashtable
**Resolution**: Rename variables to avoid collision: `$matches` → `$patternMatches`, avoid `$error`, `$input`
**Critical Learning**: Never use PowerShell automatic variable names for custom variables
**Error Pattern**: Automatic variable collision causes type conversion errors in arithmetic operations

### 21. PowerShell Hashtable Property Access with Measure-Object (⚠️ CRITICAL)
**Issue**: "The property 'Confidence' cannot be found in the input for any objects"
**Discovery**: Measure-Object cannot access hashtable keys as properties, requires PSCustomObject
**Evidence**: ResponseParsing.psm1:194 and 400 using Measure-Object on array of hashtables
**Resolution**: Use manual iteration: `foreach ($item in $array) { $sum += $item.Property }`
**Critical Learning**: Hashtables don't expose keys as properties for Measure-Object; use manual loops or convert to PSCustomObject
**Error Pattern**: Property access errors when using Measure-Object with hashtable collections - CHECK ALL INSTANCES

### 134. PowerShell 5.1 DateTime ETS Properties JSON Serialization (⚠️ CRITICAL)
**Issue**: "Cannot create object of type System.DateTime. The DisplayHint property was not found for the System.DateTime object"
**Discovery**: PowerShell Extended Type System (ETS) adds DisplayHint and DateTime properties to DateTime objects that break JSON serialization
**Evidence**: Get-Date creates DateTime objects with ETS properties that serialize incorrectly and fail during ConvertFrom-Json reconstruction
**Location**: ConvertTo-HashTable function and Get-EnhancedAutonomousState UptimeMinutes calculation
**Root Cause**: PowerShell 5.1's ETS automatically adds extra properties to DateTime objects:
- **DisplayHint Property**: NoteProperty added by Get-Date cmdlet  
- **DateTime Property**: ScriptProperty attached by ETS to all DateTime objects
- **JSON Serialization**: These properties get included in JSON but fail during reconstruction
**Technical Details**:
- PowerShell 5.1 uses JavaScriptSerializer with problematic DateTime handling
- PowerShell 7.2+ fixed this by excluding ETS properties from DateTime serialization
- ConvertFrom-Json tries to recreate objects with missing ETS properties causing errors
**Resolution**: Special DateTime handling in ConvertTo-HashTable function:
```powershell
# Detect DateTime objects
if ($propertyValue -is [DateTime] -or ($propertyValue -and $propertyValue.GetType().Name -eq "DateTime")) {
    # Use BaseObject to get underlying .NET DateTime without ETS properties
    $baseDateTime = if ($propertyValue.PSObject.BaseObject) { $propertyValue.PSObject.BaseObject } else { $propertyValue }
    # Convert to ISO string format for clean JSON serialization
    $hashtable[$propertyName] = $baseDateTime.ToString("yyyy-MM-ddTHH:mm:ss.fffK")
}
```
**DateTime Parsing Fix**: Update calculations to parse DateTime strings:
```powershell
# Before (fails with ETS properties)
UptimeMinutes = [math]::Round(((Get-Date) - [DateTime]$agentState.StartTime).TotalMinutes, 2)

# After (parses ISO string correctly)
UptimeMinutes = [math]::Round(((Get-Date) - [DateTime]::Parse($agentState.StartTime)).TotalMinutes, 2)
```
**Alternative Solutions**:
1. Use .PSObject.BaseObject to get underlying DateTime
2. Type casting with [DateTime]$object to unwrap PSObject
3. Use ToString() method for string representation
4. Remove-TypeData to eliminate ETS properties globally
**Critical Learning**: PowerShell 5.1 requires special DateTime handling for JSON serialization due to ETS property contamination. Always convert DateTime objects to ISO strings for persistence and parse back for calculations.

### 135. PowerShell ETS DateTime Object Access Complex Structure (Phase 3 Day 15 - ✅ RESOLVED)
**Issue**: "Exception calling 'Parse' with '1' argument(s): 'The string was not recognized as a valid DateTime. There is an unknown word starting at index 0.'"
**Discovery**: DateTime objects from Get-Date retain ETS properties (DisplayHint, DateTime, value) even after JSON round-trip, causing parsing failures
**Evidence**: Agent state shows `StartTime {DisplayHint, DateTime, value}` structure instead of simple DateTime or string values
**Location**: Get-EnhancedAutonomousState function UptimeMinutes calculation attempting DateTime.Parse() on complex object
**Root Cause**: In-memory DateTime objects retain PSObject wrapper with ETS properties independently of JSON serialization fixes
**Technical Details**:
- Get-Date creates DateTime objects wrapped in PSObject with ETS properties
- ConvertTo-HashTable correctly handles serialization to JSON as ISO strings
- In-memory agent state objects still contain original PSObject complex structure
- DateTime.Parse() receives complex object {DisplayHint, DateTime, value} instead of string
- "Unknown word starting at index 0" indicates Parse() cannot interpret the object type
**Resolution**: Implemented Get-SafeDateTime helper function with comprehensive object type handling:
```powershell
function Get-SafeDateTime {
    param($DateTimeObject)
    
    # Handle various object types: DateTime, String, PSObject with ETS properties
    if ($DateTimeObject -is [DateTime]) { return $DateTimeObject }
    if ($DateTimeObject -is [string]) { return [DateTime]::Parse($DateTimeObject) }
    
    # Handle PSObject with ETS properties
    if ($DateTimeObject.PSObject) {
        # Try BaseObject first
        if ($DateTimeObject.PSObject.BaseObject -is [DateTime]) {
            return $DateTimeObject.PSObject.BaseObject
        }
        # Try 'value' property for complex ETS objects  
        if ($DateTimeObject.value -is [DateTime]) {
            return $DateTimeObject.value
        }
        # Try casting entire object
        try { return [DateTime]$DateTimeObject } catch { }
    }
    
    # Last resort: ToString() and parse
    return [DateTime]::Parse($DateTimeObject.ToString())
}
```
**Updated Implementation**: 
```powershell
# Before (fails with ETS objects)
UptimeMinutes = [math]::Round(((Get-Date) - [DateTime]::Parse($agentState.StartTime)).TotalMinutes, 2)

# After (handles all DateTime object types)
UptimeMinutes = [math]::Round(((Get-Date) - (Get-SafeDateTime -DateTimeObject $agentState.StartTime)).TotalMinutes, 2)
```
**Alternative Solutions**:
1. Use [DateTime] casting with error handling
2. Access .PSObject.BaseObject directly
3. Check object type before parsing
4. Use .value property for ETS complex objects
**Critical Learning**: PowerShell ETS properties persist in memory independently of JSON serialization. Always use safe extraction methods for DateTime objects rather than assuming they are strings or pure DateTime types.

### 133. PowerShell 5.1 Sort-Object String vs Numeric Comparison (⚠️ CRITICAL)
**Issue**: Queue sorting failing because Sort-Object treats numbers as strings
**Discovery**: PowerShell 5.1 Sort-Object performs string comparison on numeric properties
**Evidence**: Debug logs show "1, 10, 5" sorted as "10, 1, 5" instead of "10, 5, 1"
**Location**: CLIAutomation.psm1 Add-InputToQueue function
**Root Cause**: Sort-Object -Property Priority treats values as strings where "1" < "5" alphabetically
**Technical Details**:
- String sorting: "1" comes before "5" alphabetically, regardless of numeric value
- PowerShell 5.1 lacks stable sort features available in PowerShell 7+
- JSON deserialization may convert numbers to strings in PSObjects
**Resolution**: Cast property to correct type for sorting:
```powershell
# Before (string sorting)
$queue.Queue = $queueArray | Sort-Object -Property Priority -Descending

# After (numeric sorting)  
$queue.Queue = $queueArray | Sort-Object -Property { [int]$_.Priority } -Descending
```
**Alternative Solutions**:
1. Version casting: `Sort-Object { [version] $_.Priority }`
2. Regex padding: `Sort-Object { [regex]::Replace($_.Priority, '\d+', { $args[0].Value.PadLeft(20) }) }`
3. Custom comparison function using StrCmpLogicalW API
**Critical Learning**: Always cast numeric properties to proper types when sorting in PowerShell 5.1 to avoid string comparison behavior

## 🔧 PowerShell Version Feature Compatibility

### PowerShell 5.1 vs PowerShell 7+ Feature Differences
**Features NOT available in PowerShell 5.1**:
- Null coalescing operator `??`
- Ternary operator `? :`
- `ForEach-Object -Parallel`
- Pipeline chain operators `&&`, `||`
- ConvertFrom-Json `-AsHashtable` parameter
- ConvertFrom-Json `-DateKind` parameter

**PowerShell 5.1 Workarounds**:
```powershell
# Instead of ??
$value = if ($null -eq $variable) { "default" } else { $variable }

# Instead of ? :
$result = if ($condition) { "true" } else { "false" }

# Instead of ForEach-Object -Parallel
Install-Module ThreadJob -Scope CurrentUser
Start-ThreadJob -ScriptBlock { ... }

# Instead of ConvertFrom-Json -AsHashtable
function ConvertTo-HashTable { 
    # Custom implementation using PSObject.Properties
}
```

## 🔍 PowerShell Debugging and Error Analysis

### Error Location Investigation Patterns
1. **Check encoding first** - UTF-8 BOM requirement
2. **Expand error range** - Check lines before reported location
3. **Look for Unicode contamination** - Use detection tools
4. **Validate syntax separately** - Test small code blocks
5. **Use ISE or VSCode** - Better error highlighting than console

### Common Error Misleading Patterns
- Unicode characters cause persistent syntax errors
- Encoding issues reported at wrong line numbers
- Escape sequence errors cascade to unrelated code
- Module import failures mask function export issues
- Automatic variable collisions appear as type errors

---
*This document focuses specifically on PowerShell 5.1 compatibility and syntax issues.*
*For broader development patterns, see LEARNINGS_CRITICAL_REQUIREMENTS.md*