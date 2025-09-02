# PowerShell Specific Learnings

*Critical PowerShell knowledge, syntax issues, compatibility fixes, and best practices*

## Character Encoding and Unicode Issues

### Learning #234: Unicode Characters Cause PowerShell Parser Errors (2025-12-28)
**Context**: Test-CLIOrchestrator-Serialization.ps1 execution failure
**Issue**: Non-ASCII Unicode characters (✓, ✗) in PowerShell scripts cause parser errors
**Critical Discovery**: Unicode characters can trigger misleading "string terminator" errors
**Evidence**: "The string is missing the terminator" error at line with Unicode character
**Root Cause**: PowerShell parser has issues with certain Unicode characters in string literals
**Resolution**: Replace all Unicode characters with ASCII equivalents
**Implementation**:
- Replace ✓ with [PASS] or similar ASCII indicator
- Replace ✗ with [FAIL] or similar ASCII indicator  
- Replace any other Unicode symbols with ASCII alternatives
**Critical Pattern**: Always use ASCII-only characters in PowerShell scripts
**Best Practices**:
1. Follow directive #15: "USE ASCII CHARACTERS ONLY"
2. Use bracketed text indicators like [PASS], [FAIL], [INFO] instead of symbols
3. Avoid emoji and special Unicode characters in all scripts
4. Test scripts for Unicode characters before deployment
5. Configure editors to show non-ASCII characters
**Technical Details**:
- PowerShell misinterprets Unicode as string termination issues
- Error messages are misleading - reports missing quotes when issue is Unicode
- Cascading errors occur (missing braces) due to initial parse failure
- Issue occurs in both PowerShell 5.1 and PowerShell 7

## Object Serialization and String Interpolation

### Learning #233: PowerShell Object-to-String Interpolation Corruption (2025-12-28)
**Context**: CLIOrchestrator prompt submission to Claude Code CLI
**Issue**: Complex objects (hashtables/PSObjects) embedded in strings show as @{key=System.Object[]} instead of actual values
**Critical Discovery**: Direct string interpolation "$variable" calls ToString() which returns type info for complex objects
**Evidence**: Prompt showing "@{week_1_priorities=System.Object[]}" instead of file path
**Root Cause**: PowerShell default ToString() on hashtables returns type representation not content
**Resolution**: Implement proper serialization helper function before string interpolation
**Implementation**:
```powershell
# Helper function to properly serialize objects
function Convert-ToSerializedString {
    param($InputObject)
    if ($InputObject -is [string]) { return $InputObject }
    if ($InputObject -is [hashtable] -or $InputObject -is [PSCustomObject]) {
        # Extract file path properties
        $pathProps = @('Path','FilePath','FullName','ImplementationPlan')
        foreach ($prop in $pathProps) {
            if ($InputObject.$prop) { return $InputObject.$prop.ToString() }
        }
        # Fallback to JSON
        return $InputObject | ConvertTo-Json -Depth 5 -Compress
    }
    return $InputObject.ToString()
}
```
**Critical Patterns**:
- Always check object type before string interpolation
- Use subexpression operator $() for property access: "$($hash.Property)"
- Implement serialization helper for complex prompt building
- Extract relevant string properties from objects
**Best Practices**:
1. Never directly embed complex objects in strings with "$object"
2. Always serialize objects to meaningful strings first
3. Use -is operator for type checking: `$var -is [hashtable]`
4. ConvertTo-Json with -Depth parameter for nested objects
5. Test serialization with various object types
**Technical Details**:
- Default ConvertTo-Json depth of 2 causes nested "System.Object[]"
- GetEnumerator() method for iterating hashtable key-value pairs
- Select-Object -ExpandProperty extracts string values from PSObjects
- .Values property returns hashtable values without @{} notation

## Count Property and Collection Safety

### Learning #226: Comprehensive Count Property Safety - Final Resolution (2025-08-24)
**Context**: Phase 6 CPG Module Testing - Final resolution of persistent Test-CodeRedundancy op_Subtraction error
**Issue**: Direct .Count property usage in arithmetic and comparison operations causing array-type errors
**Critical Discovery**: Line 520 arithmetic operation `Count = $similarBlocks.Count + 1` was the primary culprit
**Evidence**: Persistent op_Subtraction error despite multiple previous fixes - required comprehensive audit of all .Count usage
**Research Insight**: "op_Subtraction" error messages are misleading and can occur with addition operations when Count returns array instead of scalar
**Complete Resolution**: Applied Measure-Object pattern to ALL remaining .Count operations in Test-CodeRedundancy function
**Locations Fixed**:
1. **Line 520**: `Count = ($similarBlocks | Measure-Object).Count + 1` - Critical arithmetic fix
2. **Line 511**: `if (($similarBlocks | Measure-Object).Count -gt 0)` - Comparison safety
3. **Lines 483-484**: Created `$totalBlocks` variable for loop conditions
4. **Line 491**: Used `$totalBlocks` in inner loop condition 
5. **Line 477**: Write-Verbose statement with Measure-Object pattern
6. **Line 535**: Hashtable count using `($processed.Keys | Measure-Object).Count`
**Technical Understanding**: 
- PowerShell PSv3+ accessing property on collection returns array of property values
- Arrays don't support arithmetic operators (+-*/), causing op_Subtraction errors
- Error message mentions "subtraction" even for addition operations due to operator implementation
- Hashtables require .Keys collection for reliable counting in arithmetic contexts
**Final Pattern**: Always use `($collection | Measure-Object).Count` for ANY Count property used in arithmetic, comparisons, or string interpolation
**Success Criteria**: 8/8 tests passing (100%) with no CLR crashes or array operation errors

### Learning #225: PowerShell Count Property Arithmetic Safety (2025-08-24)
**Context**: Phase 6 CPG Module Testing - Test-CodeRedundancy persistent op_Subtraction errors
**Issue**: Count property from collections can return array instead of scalar in PowerShell 5.1
**Discovery**: Where-Object, Select-Object -Unique, and filtered collections' Count can behave as arrays
**Evidence**: "Method invocation failed because [System.Object[]] does not contain a method named op_Subtraction"
**Resolution**: Apply [int] cast to all Count properties used in arithmetic operations
**Critical Pattern**: Use [int]@(collection).Count or [int]collection.Count for arithmetic safety
**Affected Operations**:
1. Where-Object filtered collections: [int]@($collection | Where-Object {...}).Count
2. Select-Object -Unique: [int]@($collection | Select-Object -Unique Property).Count  
3. Division operations: [int]$numerator.Count / [int]$denominator.Count
4. Multiplication: $value * [int]$collection.Count
5. Comparisons: if ([int]$collection.Count -gt 0)
**Best Practices**:
- Always use [int] cast when Count will be used in arithmetic
- Wrap filtered collections in @() before accessing Count
- Alternative: Use ($collection | Measure-Object).Count for guaranteed scalar
- Apply defensive coding: assume Count might return non-scalar
**Technical Details**:
- PowerShell 5.1 automatic type conversion can make single-item results non-arrays
- Select-Object and Where-Object can return types that lack reliable Count property
- Arithmetic operators (+-*/) require scalar operands, not arrays
- Fixed 15 locations in ObsolescenceDetection module for complete resolution

## Type System and Enum Handling

### Learning #224: PowerShell Enum Type Reference Consistency (2025-08-24)
**Context**: Phase 6 CPG Module Testing - Test-ObsolescenceDetection.ps1 failures
**Issue**: Enum type references must match exact definition names - no partial resolution
**Discovery**: ObsolescenceDetection module using [NodeType] when enum defined as CPGNodeType
**Evidence**: "Unable to find type [NodeType]" errors in 6/8 tests (75% failure rate)
**Resolution**: Updated all [NodeType] references to [CPGNodeType] throughout module
**Critical Insight**: PowerShell 5.1 does not support partial type name resolution or automatic aliasing for enums
**Best Practices**:
1. Always use fully qualified enum names matching exact definition
2. Verify enum naming consistency across all dependent modules
3. Load enum definitions before modules that reference them
4. Consider using type accelerators for complex scenarios but avoid for simple cases
5. Document enum names clearly in module manifests
**Technical Details**:
- Enums defined in Unity-Claude-CPG-Enums.ps1 as CPGNodeType
- ObsolescenceDetection module expected NodeType (missing CPG prefix)
- Affected functions: Find-UnreachableCode, Test-CodeRedundancy, Get-CodeComplexityMetrics, etc.
- Fix: Simple find/replace of [NodeType] with [CPGNodeType]

## PowerShell 5.1 Compatibility Issues

### Learning #170: PowerShell 5.1 ConcurrentQueue Instantiation Critical Issue (2025-08-20)
**Context**: Phase 3 Day 17 State Management Implementation
**Issue**: Direct ConcurrentQueue instantiation fails in PowerShell 5.1 with AddType conflicts
**Evidence**: "A type named 'ConcurrentQueue' already exists" error despite no previous declarations
**Root Cause**: PowerShell 5.1's automatic type resolution conflicts with System.Collections.Concurrent namespace
**Resolution**: Use full namespace qualification consistently
**Critical Pattern**: `[System.Collections.Concurrent.ConcurrentQueue[psobject]]::new()`
**Best Practices**:
- Never use shortened type names for concurrent collections in PS 5.1
- Always fully qualify System.Collections.Concurrent types
- Test instantiation patterns thoroughly in PS 5.1 environments
- Consider wrapper classes for complex concurrent types

## Semantic Analysis and Pattern Detection

### Learning #235: PowerShell Singleton Pattern Detection Specifics (2025-08-28)
**Context**: Week 2 Day 3 Semantic Analysis - Test-Week2Day3-SemanticAnalysis.ps1 singleton detection failure
**Issue**: Traditional OOP singleton pattern detection fails with PowerShell class syntax
**Critical Discovery**: PowerShell uses `hidden` keyword instead of `private` for constructor restriction
**Evidence**: Test singleton class with `hidden` constructor not detected by pattern matching
**Root Cause**: Pattern detection logic expected traditional `private` constructor syntax
**Resolution**: Updated singleton detection to recognize PowerShell-specific patterns
**PowerShell Singleton Characteristics**:
- Uses `hidden` keyword for constructor restriction (not `private`)
- Static property/field for instance storage: `hidden static [Class] $Instance`
- Static access method: `static [Class] GetInstance()`
- Lazy initialization with conditional instantiation in GetInstance()
**Pattern Detection Updates**:
1. Check for `hidden` constructors instead of `private`
2. Accept non-public constructors as potential singleton indicators
3. Enhanced static property detection including AST field analysis
4. Regex-based static method name matching: `Get.*Instance|GetSingleton|Instance`
5. Bonus scoring for lazy initialization patterns (if statements in access methods)
**Best Practices**:
- PowerShell singleton detection requires language-specific criteria
- Confidence scoring should account for PowerShell syntax differences
- AST analysis must check both Properties and AST Members for static fields
- Debug logging essential for pattern matching troubleshooting

### Learning #236: AST Method Interaction Analysis for Cohesion Metrics (2025-08-28)
**Context**: Week 2 Day 3 Semantic Analysis - CHM (Cohesion at Message Level) calculation failure
**Issue**: Method interaction analysis not detecting internal class method calls correctly
**Critical Discovery**: PowerShell AST requires specific filtering for "this" variable and member expressions
**Evidence**: CHM calculation returning 0 internal calls despite test class having internal method calls
**Root Cause**: InvokeMemberExpressionAst filtering too broad, not distinguishing internal vs external calls
**Resolution**: Enhanced method call detection with proper "this" variable filtering
**Technical Implementation**:
1. **Explicit "this" calls**: Filter by `VariableExpressionAst.VariablePath.UserPath -eq "this"`
2. **Potential internal calls**: Check InvokeMemberExpressionAst without "this" but matching class method names
3. **Member vs Method distinction**: Use StringConstantExpressionAst vs generic ToString() for method names
4. **Class method verification**: Cross-reference called method names with class method list
**AST Analysis Patterns**:
```powershell
# Find explicit 'this' method calls
$memberCalls = $method.Body.FindAll({
    param($node)
    $node -is [InvokeMemberExpressionAst] -and
    $node.Expression -is [VariableExpressionAst] -and
    $node.Expression.VariablePath.UserPath -eq "this"
}, $true)
```
**Best Practices**:
- Always use proper VariableExpressionAst filtering for "this" detection
- Distinguish between explicit and implicit internal method calls
- Add comprehensive debug logging for interaction counting
- Verify method names exist in current class before counting as internal

### Learning #237: PowerShell Class Backtick Escape Sequence Issues (2025-08-28)
**Context**: Week 2 Day 3 Semantic Analysis - Test file parse errors affecting pattern detection
**Issue**: Backtick escape sequences in PowerShell class parameter definitions cause AST parsing errors
**Critical Discovery**: Backticks before $ in class syntax are unnecessary and problematic
**Evidence**: Parse errors in test files with `$variable` syntax in class definitions
**Root Cause**: PowerShell class syntax doesn't require backtick escaping for $ in parameter definitions
**Resolution**: Remove all backticks from PowerShell class syntax in test files
**Problematic Patterns**:
- `hidden static [Class] `$Instance` (should be: `hidden static [Class] $Instance`)
- `[void] Method([string] `$param)` (should be: `[void] Method([string] $param)`)
- `return `$this.Property` (should be: `return $this.Property`)
**Critical Understanding**: 
- PowerShell class syntax uses standard $ variable notation without backticks
- Backticks in class definitions can cause "string terminator" and parsing errors
- Apply Learning #234 (ASCII characters only) includes avoiding unnecessary backticks
**Best Practices**:
1. Never use backticks before $ in PowerShell class parameter definitions
2. Use clean syntax: `[Type] $parameter` not `[Type] `$parameter`
3. Class property access: `$this.Property` not `$this.Property`
4. Test all class syntax with AST parsing before pattern analysis
5. Apply ASCII-only principle to all test code and class definitions

### Learning #238: PowerShell 5.1 UTF-8 BOM Issues in AST Parsing (2025-08-28)
**Context**: Week 2 Day 3 Semantic Analysis - Test regression from 86.7% to 60% success rate after fixes
**Issue**: PowerShell 5.1 Out-File with UTF-8 encoding creates BOM causing widespread AST parsing failures
**Critical Discovery**: BOM (Byte Order Mark) in UTF-8 files breaks PowerShell AST parser in temporary files
**Evidence**: All test files showing parse errors after using `Out-File -Encoding UTF8` in PowerShell 5.1
**Root Cause**: PowerShell 5.1 always creates UTF-8 files with BOM, parser has documented issues with BOM
**Resolution**: Use ASCII encoding for simple test files without Unicode characters
**Technical Details**:
- PowerShell 5.1: `Out-File -Encoding UTF8` creates UTF-8 **with BOM**
- PowerShell 7+: Defaults to UTF-8 **without BOM** 
- AST parser in PowerShell 5.1 has known issues with BOM in temporary files
- BOM causes "string terminator" and parse error symptoms
**Implementation Fix**:
```powershell
# WRONG - Creates BOM causing parse errors
$content | Out-File -FilePath $tempFile -Encoding UTF8

# CORRECT - ASCII encoding prevents BOM issues  
$content | Out-File -FilePath $tempFile -Encoding ASCII

# ALTERNATIVE - Set-Content with ASCII
Set-Content -Path $tempFile -Value $content -Encoding ASCII
```
**Best Practices**:
1. Use ASCII encoding for simple PowerShell test files in PowerShell 5.1
2. Reserve UTF8 encoding only for files that need Unicode characters
3. Avoid Out-File with UTF8 encoding for temporary files in PowerShell 5.1
4. Set default parameter: `$PSDefaultParameterValues['Out-File:Encoding'] = 'ascii'`
5. Test file creation and parsing immediately to catch encoding issues early
**Critical Pattern**: Always use ASCII encoding for temporary PowerShell class definition files in PowerShell 5.1 environment

### Learning #239: PowerShell 5.1 Class Limitations Require Function-Based Alternatives (2025-08-28)
**Context**: Week 2 Day 3 Semantic Analysis - Persistent AST parsing failures confirmed in PowerShell 5.1.22621.5697 Desktop edition
**Issue**: PowerShell 5.1 has fundamental limitations with class definitions causing widespread AST parsing failures
**Critical Discovery**: PowerShell 5.1 classes described as "second-class citizens" and "an afterthought, arguably the least mature part of the language"
**Evidence**: Even simplest PowerShell class syntax fails direct AST parsing in PowerShell 5.1 environment
**Root Cause**: PowerShell 5.1 class implementation has known limitations with parse-time compilation and module scope
**Resolution**: Implement function-based pattern detection using hashtable objects instead of PowerShell classes
**PowerShell 5.1 Class Limitations**:
- Classes are "second-class citizens" with significant parsing restrictions
- Parse-time type resolution requirements cause compilation failures
- Module scope isolation prevents proper class definition loading
- Classes can't be unloaded or reloaded in PowerShell 5.1 sessions
- External type references must be available at parse-time for IL generation
**Function-Based Solution**:
```powershell
# WRONG - PowerShell classes fail in 5.1
class PatternMatch {
    [string] $PatternName
    [double] $Confidence
}

# CORRECT - Function-based hashtable objects
function New-PatternMatch {
    param([string] $PatternName, [double] $Confidence)
    return @{
        PatternName = $PatternName
        Confidence = $Confidence
        ConfidenceLevel = if ($Confidence -ge 0.8) { "High" } else { "Medium" }
    }
}
```
**Best Practices**:
1. Use function-based pattern detection following PSScriptAnalyzer model
2. Replace custom classes with hashtable factory functions
3. Use simple PowerShell function definitions for test content (not classes)
4. Implement pattern detection as functions accepting AST parameters
5. Set $DebugPreference = "Continue" for debug output visibility in PowerShell 5.1
**Alternative Approaches**: Consider inline C# classes or compiled assemblies for complex scenarios
**Critical Understanding**: PowerShell 5.1 requires function-based approaches for reliable AST analysis and pattern detection

### Learning #240: PowerShell Double-Quoted Here-String Variable Expansion Issues (2025-08-28)
**Context**: Week 2 Day 3 Semantic Analysis - Variable names stripped from all test content causing AST parsing failures
**Issue**: Double-quoted here-strings (@"..."@) expand variables to empty strings when variables don't exist in scope
**Critical Discovery**: Enhanced debug output revealed all $variables being stripped from class/function definitions
**Evidence**: 
- `$Instance` → empty string (class property names missing)
- `$Type, $a, $b` → empty strings (parameter names missing)  
- `$this` → empty string (method call corruption)
**Root Cause**: PowerShell double-quoted here-strings perform variable expansion even when variables undefined
**Resolution**: Use single-quoted here-strings (@'...'@) for literal preservation of variable names
**Before/After Comparison**:
```powershell
# WRONG - Double-quoted here-string expands variables
$testContent = @"
class TestClass {
    [string] $Property
    [void] Method([string] $param) {}
}
"@
# Result: Variables expanded to empty, syntax broken

# CORRECT - Single-quoted here-string preserves literally  
$testContent = @'
class TestClass {
    [string] $Property
    [void] Method([string] $param) {}
}
'@
# Result: All variable names preserved, syntax valid
```
**Technical Details**:
- Double-quoted here-strings (@"..."@) behave like double-quoted strings with variable expansion
- Single-quoted here-strings (@'...'@) behave like single-quoted strings with literal preservation
- Variable expansion occurs during string creation, not file writing
- Undefined variables expand to empty strings causing syntax corruption
**Parse Error Symptoms**:
- "Missing expression after unary operator '-not'" (missing variable after -not)
- "Parameter declarations are comma-separated list" (missing parameter names)
- "Missing ')' in function parameter list" (parameters without names)
- "Only one type may be specified on class members" (missing property names)
**Best Practices**:
1. Always use single-quoted here-strings (@'...'@) for PowerShell code generation
2. Reserve double-quoted here-strings only when you need variable expansion
3. Test content creation immediately to verify variable preservation
4. Use Write-Debug to verify content before file creation
5. Default to literal strings unless expansion specifically needed
**Critical Pattern**: Use @'...'@ for all PowerShell code content generation to prevent variable expansion corruption

### Learning #241: PowerShell File Copy Truncation During Large Script Transfer (2025-08-28)
**Context**: Week 3 Day 4-5 Testing & Validation - Test-EnhancedDocumentationSystem.ps1 syntax errors
**Issue**: Copy-Item operation truncated large PowerShell script from 764 lines to 734 lines
**Critical Discovery**: PowerShell Copy-Item can silently truncate large files during transfer operations
**Evidence**: Parser errors for missing closing braces and incomplete try-catch blocks after copy
**Root Cause**: File copy operation incomplete, missing final 30 lines containing critical script structure
**Error Symptoms**:
- "The string is missing the terminator" in Write-Error statements
- "Missing closing '}' in statement block or type definition"  
- "Try statement is missing its Catch or Finally block"
- Parser reporting line numbers beyond actual file length
**Resolution Applied**:
```powershell
# Verify file integrity after copy operations
$originalLines = (Get-Content $SourcePath | Measure-Object).Count
$copiedLines = (Get-Content $DestinationPath | Measure-Object).Count
if ($originalLines -ne $copiedLines) {
    Write-Warning "File copy incomplete: $originalLines vs $copiedLines lines"
}
```
**Best Practices**:
1. Always verify file line counts after Copy-Item operations on large scripts
2. Use Get-Content | Measure-Object to confirm complete transfer
3. Test PowerShell syntax validation after file operations: Get-Command -Syntax
4. For critical scripts, use alternative copy methods if Copy-Item fails
5. Check file integrity before executing copied PowerShell scripts
**Technical Details**:
- Issue occurred with 764-line PowerShell script containing Pester v5 test framework
- Copy operation stopped at line 734, missing hashtable closure and try-catch completion
- PowerShell parser cascades errors when structure is incomplete
- Error line numbers can be misleading when file is structurally incomplete
**Critical Pattern**: Always validate file integrity after copy operations, especially for large PowerShell test scripts

### Learning #242: Pester Configuration Recursive Execution Prevention (2025-08-28)
**Context**: Week 3 Day 4-5 Testing & Validation - Test-EnhancedDocumentationSystem.ps1 call depth overflow
**Issue**: Pester configuration with `$config.Run.Path = $PSCommandPath` causes infinite recursion when script executes itself
**Critical Discovery**: Setting Run.Path to current script in self-executing test scripts creates recursive loop
**Evidence**: Call depth overflow at Describe block, Pester discovering 0 tests, 50+ repeated test starts
**Root Cause**: Script configures Pester to run itself, then calls Invoke-Pester, causing infinite self-execution
**Error Pattern**: 
- System.Management.Automation.ScriptCallDepthException at Describe block
- "Discovery found 0 tests" despite valid Describe/Context/It structure  
- Multiple repeated script header outputs indicating loop
- Stack overflow in Pester.psm1 line 10202 at Describe function
**Resolution**: Remove `$config.Run.Path = $PSCommandPath` and let Pester auto-discover tests
**Correct Configuration**:
```powershell
# WRONG - Causes recursive execution
$config.Run.Path = $PSCommandPath
$testResults = Invoke-Pester -Configuration $config

# CORRECT - Auto-discovery without recursion
$config = New-PesterConfiguration
# Don't set Run.Path - let Pester discover tests in current script
$config.Run.PassThru = $true
$testResults = Invoke-Pester -Configuration $config
```
**Best Practices**:
1. Never set Run.Path to $PSCommandPath in self-executing test scripts
2. Let Pester auto-discover tests in the current script context
3. Use Run.Path only when testing external scripts from a runner script
4. Add debug logging to trace recursive execution issues
5. Verify Pester configuration doesn't create self-referential loops
**Technical Details**:
- Pester Run.Path tells framework which files to execute for testing
- Setting it to current script creates execution loop when Invoke-Pester called
- Auto-discovery mode lets Pester find Describe blocks without re-execution
- Call depth overflow occurs when PowerShell stack exceeds maximum recursion depth
**Critical Pattern**: Never configure Pester to re-execute the script it's already running from

### Learning #243: Pester Self-Executing Test Script Infinite Recursion (2025-08-28)
**Context**: Week 3 Day 4-5 Testing & Validation - Test-EnhancedDocumentationSystem.ps1 call depth overflow persistence
**Issue**: Self-executing test scripts that contain both test definitions and Invoke-Pester calls create infinite recursion
**Critical Discovery**: Scripts with Describe blocks AND Invoke-Pester calls cause recursive discovery loop
**Evidence**: 
- Call depth overflow at Describe block during discovery phase
- "Starting discovery in 1 files" repeated endlessly
- Script header output repeated 50+ times indicating infinite loop
- Stack trace shows Invoke-Pester → Describe → Invoke-Pester recursion
**Root Cause**: During Pester discovery phase, script re-executes and hits Invoke-Pester call again
**Error Flow**:
1. Orchestrator executes Test-Script.ps1
2. Script contains Describe blocks + Invoke-Pester call
3. Pester discovery phase re-executes entire script
4. Script hits Invoke-Pester call again during discovery
5. New Pester instance starts discovery of same script
6. Infinite recursion until call depth overflow
**Resolution**: Separate test definitions from test execution
**Correct Architecture**:
```powershell
# TEST DEFINITIONS FILE (Test-Something.ps1)
# Contains ONLY Describe/Context/It blocks - NO Invoke-Pester

Describe "My Tests" {
    It "Should work" {
        # Test logic
    }
}
# No Invoke-Pester call in this file

# TEST RUNNER FILE (Run-SomethingTests.ps1) 
# Contains ONLY Invoke-Pester call - NO test definitions

$config = New-PesterConfiguration
$config.Run.Path = "Test-Something.ps1"
$testResults = Invoke-Pester -Configuration $config
```
**Best Practices**:
1. Never combine test definitions and Invoke-Pester calls in same script
2. Use separate runner script for orchestrator execution
3. Test definition files contain only Describe/Context/It blocks
4. Runner scripts handle Pester configuration and execution
5. Remove all Invoke-Pester calls from scripts containing Describe blocks
**Technical Details**:
- Pester discovery phase executes entire script looking for test definitions
- Any Invoke-Pester calls encountered during discovery trigger new Pester instances
- Stack overflow occurs when recursive depth exceeds PowerShell limits
- Error persists despite removing $config.Run.Path because script still calls Invoke-Pester
**Critical Pattern**: Separate test definitions from test execution to prevent Pester recursive discovery loops

### Learning #244: Pester Conditional Describe Block Discovery Prevention (2025-08-28)
**Context**: Week 3 Day 4-5 Testing & Validation - Test discovery finding 0 tests despite resolved recursion
**Issue**: Describe blocks wrapped in conditional if statements prevent Pester v5 discovery phase execution
**Critical Discovery**: Parameters and variables unavailable during Pester discovery phase cause if conditions to fail
**Evidence**:
- Test script with if ($TestScope -eq "All") wrapping Describe blocks
- Pester discovery finds 0 tests despite valid Describe/Context/It structure
- Parameters like $TestScope undefined during discovery phase
- Conditional logic prevents Describe blocks from executing during discovery
**Root Cause**: Pester v5 discovery phase loads script but doesn't pass parameters or initialize variables
**Error Pattern**:
- "Discovery found 0 tests" despite valid test structure
- Describe blocks wrapped in if statements checking script parameters
- Parameters undefined during discovery, conditions evaluate false
- Test blocks never execute during discovery phase, so not registered
**Resolution**: Remove conditional wrappers, use Pester built-in filtering instead
**Before (Wrong)**:
```powershell
param([string]$TestScope = "All")

if ($TestScope -eq "All" -or $TestScope -eq "CPG") {
    Describe "CPG Tests" {
        # Tests here
    }
}
```
**After (Correct)**:
```powershell
# No parameters in test definitions file
Describe "CPG Tests" -Tag "CPG" {
    # Tests here
}

# Use runner script for filtering:
# $config.Filter.Tag = "CPG"  # In runner script
```
**Best Practices**:
1. Never wrap Describe blocks in conditional logic based on script parameters
2. Use Pester built-in filtering mechanisms (tags, names) for test selection
3. Test definitions files should have no parameters or conditional logic
4. Runner scripts handle test filtering and configuration
5. All Describe blocks must execute during discovery phase to be registered
**Technical Details**:
- Pester discovery phase executes script top-to-bottom but doesn't initialize parameters
- Script variables and parameters are undefined during discovery
- if statements around Describe blocks prevent registration during discovery
- Use -Tag parameters on Describe blocks for filtering instead of if conditions
**Critical Pattern**: Never use conditional logic around Describe blocks - use Pester filtering mechanisms instead

### Learning #245: Pester Script Variable Null Array Prevention in Test Conditions (2025-08-28)
**Context**: Week 3 Day 4-5 Testing & Validation - Test execution with "Cannot index into a null array" runtime error
**Issue**: Test conditions accessing $script:VariableName hashtables fail with null array indexing when BeforeAll initialization incomplete
**Critical Discovery**: Pester test conditions execute even when BeforeAll blocks fail, causing null reference errors
**Evidence**: 
- "Cannot index into a null array" at line 121 in test condition
- Test condition: -Skip:(-not $script:CPGModulesAvailable['ModuleName'])
- BeforeAll block initializes $script:CPGModulesAvailable but fails before completion
- Test framework attempts to evaluate skip condition on null hashtable
**Root Cause**: BeforeAll block failures leave script variables in undefined state, test conditions try to access null hashtables
**Resolution**: Initialize script variables with defensive defaults before complex logic
**Best Practices**:
1. Initialize script hashtables with all expected keys set to safe defaults
2. Use defensive defaults before attempting complex initialization logic  
3. Ensure test conditions can safely access hashtable keys even on BeforeAll failure
4. Add comprehensive error handling in module availability testing
5. Use try-catch around individual module tests, not entire initialization
**Critical Pattern**: Always initialize script hashtables with defensive defaults before complex population logic

### Learning #246: Pester Discovery Phase Script Variable Availability (2025-08-28)
**Context**: Week 3 Day 4-5 Testing & Validation - Null array error persisting despite BeforeAll defensive initialization
**Issue**: Script variables defined in BeforeAll blocks are undefined during Pester discovery phase when test conditions evaluated
**Critical Discovery**: Pester v5 discovery phase evaluates test conditions BEFORE executing any BeforeAll blocks
**Evidence**:
- "Cannot index into a null array" at test condition -Skip:(-not $script:ModuleVar['Key'])
- BeforeAll block initializes variables but error occurs during discovery
- Test conditions with script variable access failing during discovery evaluation
- Variables must exist during discovery for proper test registration
**Root Cause**: Discovery phase evaluates entire script including test conditions before any BeforeAll execution
**Resolution**: Initialize all script variables at top-level scope before any Describe blocks
**Timing Analysis**:
```
Discovery Phase (Variables Must Exist):
1. Script loaded and executed top-to-bottom
2. Test conditions evaluated: -Skip:(-not $script:Variable)
3. Describe/Context/It blocks registered
4. Variables accessed HERE → Must be initialized

Run Phase (BeforeAll Executes):
5. BeforeAll blocks execute
6. Test logic runs
7. AfterAll blocks execute
```
**Correct Pattern**:
```powershell
# TOP-LEVEL INITIALIZATION (Discovery Phase Available)
$script:ModuleStatus = @{
    'Module1' = $false
    'Module2' = $false
}

Describe "Tests" {
    BeforeAll {
        # Update variables during run phase
        $script:ModuleStatus['Module1'] = Test-ModuleAvailability
    }
    
    # Condition evaluates during discovery - variable must already exist
    It "Test" -Skip:(-not $script:ModuleStatus['Module1']) {
        # Test logic
    }
}
```
**Best Practices**:
1. Initialize ALL script variables at script top-level before any Describe blocks
2. Use BeforeAll blocks only to UPDATE variables, not initialize them
3. Ensure test conditions can safely access variables during discovery phase
4. Set conservative defaults (false/null) that promote test skipping over failures
5. Never rely on BeforeAll execution for variables used in test conditions
**Technical Details**:
- Discovery phase happens before any BeforeAll block execution
- Test conditions (-Skip, -TestCases) evaluated during discovery to register tests
- Script variables accessed in conditions must exist at script load time
- BeforeAll blocks execute later during run phase and can update values
**Critical Pattern**: Script variables used in test conditions must be initialized at top-level scope for discovery phase availability

### Learning #247: Pester Function Scope Issues in Test Execution Context (2025-08-28)
**Context**: Week 3 Day 4-5 Testing & Validation - Function recognition errors during test execution
**Issue**: Custom functions defined in test files are not available during Pester test execution context
**Critical Discovery**: Functions defined in test file regions may not be accessible during It block execution
**Evidence**:
- "The term 'Measure-TestPerformance' is not recognized as the name of a cmdlet, function" error
- Function defined in #region Helper Functions but not accessible in test execution
- Tests discovering and executing but failing on custom function calls
- Built-in PowerShell functions (Measure-Command) work correctly
**Root Cause**: Pester v5 test execution context may not include functions defined in the test file itself
**Resolution**: Replace custom helper functions with direct PowerShell code in test blocks
**Before (Problematic)**:
```powershell
function Measure-TestPerformance {
    param([string]$TestName, [scriptblock]$ScriptBlock)
    # Custom logic
}

It "Test" {
    Measure-TestPerformance -TestName "Test" -ScriptBlock {
        # Test logic
    }
}
```
**After (Working)**:
```powershell
It "Test" {
    # Direct test logic without custom function calls
    $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
    # Test logic here
    $stopwatch.Stop()
    # Assertions here
}
```
**Best Practices**:
1. Use built-in PowerShell cmdlets (Measure-Command) instead of custom functions
2. Keep test logic simple and self-contained within It blocks
3. Avoid custom helper functions that may not be in test execution scope
4. Use direct PowerShell code rather than custom abstractions in test files
5. Test function availability before using in test execution context
**Technical Details**:
- Pester v5 execution context may isolate test blocks from file-level function definitions
- Built-in PowerShell functions and cmdlets remain available
- Custom functions in test files may not be loaded in test execution scope
- Function scope issues different from variable scope issues
**Critical Pattern**: Keep test logic simple and use built-in PowerShell features rather than custom functions

### Learning #248: Module Import Testing in Pester Context Requires Permissive Error Handling (2025-08-28)
**Context**: Week 3 Day 4-5 Testing & Validation - modules exist and import manually but Test-ModuleAvailable reports unavailable
**Issue**: Module availability testing functions using ErrorAction Stop treat warnings as failures, incorrectly reporting available modules as unavailable
**Critical Discovery**: PowerShell modules often import successfully with warnings, but strict error handling catches warnings as failures
**Evidence**:
- Manual import of CPG-ThreadSafeOperations.psm1 succeeds with warning messages
- Manual import of Templates-PerLanguage.psm1 succeeds without errors  
- Test-ModuleAvailable function with ErrorAction Stop reports both as unavailable
- 27 of 28 tests skipped due to false negative module detection
**Root Cause**: ErrorAction Stop treats warnings as terminating errors, causing successful imports with warnings to be marked as failures
**Resolution**: Use permissive error handling with SilentlyContinue and PassThru validation
**Before (Too Strict)**:
```powershell
function Test-ModuleAvailable {
    try {
        Import-Module $ModulePath -Force -ErrorAction Stop
        return $true
    }
    catch {
        return $false  # Treats warnings as failures
    }
}
```
**After (Correctly Permissive)**:
```powershell
function Test-ModuleAvailable {
    try {
        $module = Import-Module $ModulePath -Force -PassThru -ErrorAction SilentlyContinue
        if ($module) {
            return $true  # Module object returned = success
        }
        # Fallback: Check if functions available
        Get-Command -Module $ModuleName -ErrorAction SilentlyContinue | Out-Null
        return $?  # $? = true if previous command succeeded
    }
    catch {
        return $false
    }
}
```
**Best Practices**:
1. Use ErrorAction SilentlyContinue for module availability testing
2. Use PassThru to get actual module object for validation
3. Implement fallback checks with Get-Command for additional validation
4. Don't treat warnings as failures when testing module availability
5. Distinguish between "module doesn't exist" vs "module imports with warnings"
**Technical Details**:
- PowerShell modules frequently emit warnings during import (dependency messages, etc.)
- ErrorAction Stop converts warnings to terminating exceptions
- Successful module import with warnings still populates module functions
- PassThru parameter returns module object which can be validated
**Critical Pattern**: Use permissive error handling for module availability testing to avoid false negatives from warning messages

### Learning #249: Pester v5 Selective BeforeAll Execution Optimization (2025-08-28)
**Context**: Week 3 Day 4-5 Testing & Validation - BeforeAll blocks not executing for CPG/LLM/Templates causing 27 test skips
**Issue**: Pester v5 optimizes execution by skipping BeforeAll blocks when all tests in that category would be skipped anyway
**Critical Discovery**: When all tests have -Skip:$true conditions, Pester doesn't execute the BeforeAll blocks for that category
**Evidence**:
- Red alert markers confirm only Performance BeforeAll executes during run phase
- CPG/LLM/Templates BeforeAll blocks never reached (no red alert markers)
- All modules default to $false causing -Skip:$true for all tests in those categories  
- Pester optimization: "Setups and teardowns are skipped when the current tree won't result in any test being run"
**Root Cause**: Pester v5 selective execution optimization prevents BeforeAll when no tests would execute
**Resolution**: Test module availability during script initialization (not BeforeAll) so skip conditions are accurate
**Before (Problematic)**:
```powershell
# Variables default to false
$script:ModuleAvailable = $false

Describe "Tests" {
    BeforeAll {
        # This never executes because all tests skip
        $script:ModuleAvailable = Test-ModuleActuallyAvailable
    }
    
    It "Test" -Skip:(-not $script:ModuleAvailable) {
        # Always skips because variable stays false
    }
}
```
**After (Working)**:
```powershell
# Test availability during script initialization
$script:ModuleAvailable = Test-ModuleActuallyAvailable

Describe "Tests" {
    BeforeAll {
        # Now executes because some tests may run
        # Additional setup here
    }
    
    It "Test" -Skip:(-not $script:ModuleAvailable) {
        # Skips only if actually unavailable
    }
}
```
**Best Practices**:
1. Test module/dependency availability during script initialization for accurate -Skip conditions
2. Use file existence (Test-Path) for basic availability checking during script load
3. Reserve BeforeAll blocks for runtime setup that needs to execute
4. Understand Pester v5 optimization skips BeforeAll when all tests would skip
5. Ensure at least some tests are runnable to trigger BeforeAll execution
**Technical Details**:
- Pester v5 evaluates skip conditions during discovery to optimize execution
- BeforeAll blocks are skipped when Pester determines no tests will run in that category
- Script-level initialization runs during discovery and can populate skip condition variables
**Critical Pattern**: Test dependencies during script initialization to enable accurate Pester v5 skip conditions and BeforeAll execution

### Learning #250: Pester v5 Variable Scope Isolation Between Discovery and Run Phases (2025-08-28)
**Context**: Week 3 Day 4-5 Testing & Validation - script variables available during discovery but NULL during run phase BeforeAll execution
**Issue**: Pester v5 isolates variable scope between discovery and run phases, causing script variables to be unavailable in BeforeAll blocks
**Critical Discovery**: Variables initialized during script load are accessible during discovery but not during run phase execution
**Evidence**:
- Script initialization shows all modules as FOUND during discovery phase
- BeforeAll blocks show "CPGModulesAvailable: NULL" during run phase
- Variable scope isolation prevents BeforeAll access to script-level variables
**Root Cause**: Pester v5 architecture isolates discovery and run phases, script variables don't persist between phases
**Resolution**: Use BeforeDiscovery blocks to ensure variables available in both discovery and run phases
**Best Practices**:
1. Use BeforeDiscovery blocks to ensure variables persist across Pester phases
2. Re-initialize critical variables in BeforeDiscovery for run phase availability
3. Don't rely on script-level initialization for BeforeAll variable access
4. Test variable availability in BeforeAll blocks with defensive null checking
**Critical Pattern**: Use BeforeDiscovery blocks to ensure script variables available during Pester v5 run phase execution