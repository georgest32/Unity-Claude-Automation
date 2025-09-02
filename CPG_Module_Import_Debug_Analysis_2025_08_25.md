# CPG Module Import Debugging Analysis
## Analysis, Research, and Planning Document
**Date**: 2025-08-25  
**Time**: Debugging Session - CPG Module Import Issues  
**Status**: Phase 2 Day 1-2 Complete, Testing Phase Failing  
**Previous Context**: Phase 2 Semantic Analysis Layer implementation completed with CPG-based approach  
**Topics**: PowerShell module imports, scope issues, function availability, CPG integration  

## Summary Information
- **Problem**: `Convert-ASTtoCPG` function not found within test function context despite successful module imports
- **Current State**: Unity-Claude-SemanticAnalysis module completed with sophisticated CPG-based pattern recognition, but tests failing due to function resolution
- **Desired State**: CPG-based semantic analysis functions working correctly with proper module dependency resolution
- **Approach**: Debug PowerShell module scope issues and ensure proper function availability across module boundaries

## 1. Home State Analysis

### Current Project Structure (Phase 2 Complete)
The Unity-Claude-Automation project has implemented Phase 2 Semantic Analysis Layer:

#### Existing Components
1. **Unity-Claude-CPG.psm1**: Core CPG data structures with complete graph operations
2. **Unity-Claude-CPG-ASTConverter.psm1**: AST to CPG conversion functionality 
3. **Unity-Claude-SemanticAnalysis.psm1**: NEW - Semantic analysis layer with pattern recognition
4. **Test-SemanticAnalysis.ps1**: NEW - Comprehensive test suite for validation

#### Phase 2 Implementation Status
- ✅ **Pattern Recognition System**: Find-DesignPatterns with Singleton, Factory, Observer, Strategy, Command, Decorator patterns
- ✅ **Code Purpose Classification**: Get-CodePurpose with CRUD, validation, transformation classification
- ✅ **Cohesion Metrics**: Get-CohesionMetrics with CHM/CHD calculations
- ✅ **Business Logic Extraction**: Extract-BusinessLogic with rule identification
- ✅ **Quality Analysis**: Documentation completeness, naming conventions, technical debt analysis
- ❌ **Testing Integration**: Module import dependency issues preventing validation

### Current Error Context
From test results (SemanticAnalysis-TestResults-20250824-204646.json):
- **12 PASSED**: All module imports and function exports successful
- **7 FAILED**: All CPG-dependent tests failing with "Convert-ASTtoCPG not recognized" errors

#### Specific Error Pattern
```
Error: "The term 'Convert-ASTtoCPG' is not recognized as a name of a cmdlet, function, script file, or executable program."
```

#### Successful Evidence
- CPG module exports Convert-ASTtoCPG correctly: `Get-Command Convert-ASTtoCPG -Module Unity-Claude-CPG` works
- Manual import: `Import-Module Unity-Claude-CPG.psd1 -Force -Global` makes function available
- Semantic analysis module imports CPG module successfully in its initialization

### Root Cause Analysis
The issue appears to be **PowerShell module scope isolation**:

1. **Test Function Context**: Helper function `ConvertTo-CPGFromScriptBlock` defined inside test script cannot access functions from modules imported in different scopes
2. **Module Import Timing**: CPG module imported in `Test-ModuleImport` function but not available in subsequent test functions 
3. **Scope Inheritance**: PowerShell function scopes don't inherit module imports from parent functions
4. **Global Import Issue**: `-Global` flag may not be propagating correctly through nested module imports

### Flow Analysis
1. `Test-ModuleImport` imports CPG module with `-Global` flag ✅
2. `Test-ModuleImport` imports Semantic Analysis module ✅  
3. `Test-PatternRecognition` calls `ConvertTo-CPGFromScriptBlock` helper function ❌
4. Helper function calls `Convert-ASTtoCPG` - **NOT FOUND** ❌

### Preliminary Solution Strategy
Based on PowerShell module scope best practices:
1. **Global Module Import**: Ensure CPG module imported globally at script level
2. **Function Availability**: Verify function resolution across all test scopes
3. **Alternative Approach**: Use module-qualified function calls or direct AST parsing
4. **Scope Chain Fix**: Ensure proper module import propagation through test execution

## 2. Implementation Objectives

### Short-Term Goals (Current Session)
1. Fix `Convert-ASTtoCPG` function availability in test context
2. Ensure proper CPG module import scope management
3. Validate all semantic analysis functions work with CPG infrastructure
4. Achieve 100% test pass rate for Phase 2 validation

### Long-Term Goals (Phase 2 Complete)
1. Robust CPG-based semantic analysis system
2. Integration with documentation generation pipeline
3. Real-time code quality assessment capabilities
4. Foundation for Phase 2 Day 3-4 LLM integration

## 3. Critical Knowledge Context

### PowerShell Module Import Challenges (from IMPORTANT_LEARNINGS.md)
- **Learning #224**: PowerShell 5.1 enum type references must match exactly
- **Learning #225**: Count property arithmetic requires [int] casting for safety
- **Scope Issues**: Functions imported in one scope may not be available in nested scopes
- **Global Import**: `-Global` flag needed for cross-module function availability

### CPG Architecture Requirements
- CPG classes (CPGNode, CPGEdge, CPGraph) must be available for pattern analysis
- AST to CPG conversion essential for semantic understanding
- Graph traversal algorithms needed for relationship mapping
- Thread-safe operations required for performance

## 4. Research Findings (5 Web Queries Completed)

### PowerShell Module Scope Behavior (2025 Context)
**Critical Discovery**: PowerShell module import scope behavior is complex and has known issues with nested modules:
- **Default Behavior**: When `Import-Module` called from command prompt/script, functions imported to global session state
- **Module Context**: When called from within another module, functions imported to caller's session state only
- **Force Issues**: `Import-Module -Force` can wipe out nested modules and create availability issues
- **Scope Propagation**: Functions don't automatically propagate from one scope to nested function contexts

### Root Cause Identification
**Confirmed Issue**: The problem is **PowerShell module scope isolation** in test context:
1. **Helper Function Context**: `ConvertTo-CPGFromScriptBlock` defined inside test script cannot access functions from modules imported in different scopes
2. **Scope Inheritance**: PowerShell function scopes don't inherit module imports from parent functions automatically
3. **Module-to-Module Import**: When loading one module from within another, exports placed in current module scope, not global

### Solution Strategies from Research
**Microsoft Recommended Approach**: "Avoid calling Import-Module from within a module. Instead, declare the target module as a nested module in the parent module's manifest"

**Alternative Solutions**:
1. **Global Scope Import**: Use `-Scope Global` parameter to force global availability
2. **Dot-Sourcing**: Load functions directly into global scope for session-wide availability  
3. **Module-Qualified Calls**: Use fully qualified module function names
4. **Nested Module Declaration**: Declare dependencies in module manifest rather than runtime import

### Critical Implementation Insights
- **Test Context**: Need to ensure CPG module functions available in test script global context
- **Function Resolution**: Use `Get-Command` to verify function availability before calling
- **Scope Chain**: Test functions need access to globally-imported module functions
- **Best Practice**: Import required modules at script level with `-Global` flag rather than within functions

## 5. Refined Solution Strategy

### Immediate Fix (Current Session)
1. **Script-Level Import**: Move CPG module import to script level with `-Global` flag
2. **Function Verification**: Add debugging to verify function availability before calls
3. **Error Handling**: Implement fallback mechanisms if function resolution fails
4. **Scope Testing**: Verify module function availability in all test contexts

### Long-Term Architecture (Phase 2 Complete)
1. **Manifest Dependencies**: Declare CPG module as nested module dependency  
2. **Module Architecture**: Restructure to avoid runtime module imports
3. **Test Framework**: Develop robust test framework with proper module handling
4. **Documentation**: Document module dependency chain and scope requirements