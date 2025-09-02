# JSON Signal File Structure Documentation

## Overview
This document defines the **canonical structure** for JSON signal files used by the Unity-Claude CLI Orchestrator system. These JSON files are placed in `./ClaudeResponses/Autonomous/` and are detected by the orchestrator to trigger automated workflows.

## Critical Requirements
1. **Location**: All JSON signal files MUST be placed in `./ClaudeResponses/Autonomous/`
2. **Encoding**: UTF-8 without BOM
3. **Extension**: `.json`
4. **Processing**: Files are processed once and renamed with `.processed` extension

## Core Fields (Required for ALL Signal Files)

```json
{
  "timestamp": "ISO 8601 timestamp (e.g., 2025-08-28T03:00:00Z)",
  "session_id": "unique-session-identifier",
  "prompt_type": "One of: Testing, Continue, Fixing, Compiling, Implementation",
  "RESPONSE": "Human-readable response with action keyword"
}
```

### Field Descriptions

#### `timestamp` (Required)
- **Type**: String
- **Format**: ISO 8601 (YYYY-MM-DDTHH:MM:SSZ)
- **Purpose**: Tracks when the signal was created

#### `session_id` (Required)
- **Type**: String
- **Format**: Lowercase with hyphens (e.g., "day2-test-callgraph-dataflow")
- **Purpose**: Groups related signals and tracks workflow sessions

#### `prompt_type` (Required)
- **Type**: String (case-sensitive)
- **Valid Values**:
  - `"Testing"` - Triggers test execution
  - `"Continue"` - Continues implementation from plan
  - `"Fixing"` - Applies fixes to code/configuration
  - `"Compiling"` - Triggers build operations
  - `"Implementation"` - Starts new implementation

#### `RESPONSE` (Required)
- **Type**: String
- **Format**: Must contain action keyword for orchestrator detection
- **Keywords**: `TESTING`, `CONTINUE`, `FIX`, `COMPILE`, `IMPLEMENT`
- **Example**: `"TESTING - Test-Day2-CallGraphDataFlow.ps1: Execute comprehensive test suite"`

## Prompt-Type Specific Fields

### Testing Prompt Type

```json
{
  "timestamp": "2025-08-28T03:00:00Z",
  "session_id": "day2-test-callgraph-dataflow",
  "prompt_type": "Testing",
  "task": "Description of test task",
  "test_script": "Test-Script-Name.ps1",
  "test_details": {
    "modules_to_test": ["Module1.psm1", "Module2.psm1"],
    "expected_tests": 25,
    "test_groups": 3,
    "coverage_areas": ["area1", "area2"]
  },
  "RESPONSE": "TESTING - Test-Script-Name.ps1: Description"
}
```

#### Testing-Specific Fields:
- **`test_script`** (Required): Script filename to execute (detected by orchestrator at line 366 of Start-CLIOrchestrator.ps1)
- **`task`** (Optional): Human-readable task description
- **`test_details`** (Optional): Structured test information

### Continue Prompt Type

```json
{
  "timestamp": "2025-08-28T10:00:00Z",
  "session_id": "week1-day3-implementation",
  "prompt_type": "Continue",
  "task": "Continue Week 1, Day 3 implementation",
  "implementation_plan": "Path/To/Implementation_Plan.md",
  "phase": "Week 1, Day 3",
  "current_step": 5,
  "total_steps": 10,
  "RESPONSE": "CONTINUE - Proceeding with next implementation phase"
}
```

#### Continue-Specific Fields:
- **`implementation_plan`** (Recommended): Path to implementation plan document
- **`phase`** (Optional): Current implementation phase
- **`current_step`** (Optional): Current step number
- **`total_steps`** (Optional): Total number of steps

### Fixing Prompt Type

```json
{
  "timestamp": "2025-08-28T11:00:00Z",
  "session_id": "fix-module-syntax-errors",
  "prompt_type": "Fixing",
  "task": "Fix syntax errors in module",
  "target_file": "Path/To/Module.psm1",
  "error_details": {
    "error_type": "SyntaxError",
    "line_number": 145,
    "description": "Missing closing bracket"
  },
  "RESPONSE": "FIX - Module.psm1: Correcting syntax error at line 145"
}
```

#### Fixing-Specific Fields:
- **`target_file`** (Required): File to be fixed
- **`error_details`** (Optional): Structured error information

### Compiling Prompt Type

```json
{
  "timestamp": "2025-08-28T12:00:00Z",
  "session_id": "unity-project-build",
  "prompt_type": "Compiling",
  "task": "Compile Unity project",
  "project_path": "C:\\UnityProjects\\ProjectName",
  "build_configuration": "Release",
  "target_platform": "StandaloneWindows64",
  "RESPONSE": "COMPILE - Building Unity project for Windows x64"
}
```

#### Compiling-Specific Fields:
- **`project_path`** (Required): Path to project
- **`build_configuration`** (Optional): Build configuration
- **`target_platform`** (Optional): Target platform

### Implementation Prompt Type

```json
{
  "timestamp": "2025-08-28T14:00:00Z",
  "session_id": "new-feature-implementation",
  "prompt_type": "Implementation",
  "task": "Implement new analysis feature",
  "feature_name": "Advanced Pattern Recognition",
  "target_module": "Unity-Claude-PatternRecognition",
  "requirements": [
    "Support for recursive patterns",
    "Thread-safe operations",
    "JSON export capability"
  ],
  "RESPONSE": "IMPLEMENT - Starting Advanced Pattern Recognition feature"
}
```

#### Implementation-Specific Fields:
- **`feature_name`** (Required): Name of feature to implement
- **`target_module`** (Optional): Target module for implementation
- **`requirements`** (Optional): List of requirements

## Orchestrator Processing Logic

The orchestrator processes JSON files based on the following logic (from Start-CLIOrchestrator.ps1):

1. **Detection**: Scans `./ClaudeResponses/Autonomous/` for new `.json` files
2. **Parsing**: Attempts to parse JSON content
3. **Field Extraction**:
   - First checks `prompt_type` field (line 355)
   - For Testing: Checks `test_script` field directly (line 366)
   - Falls back to `details` field (line 364)
   - Falls back to regex extraction from `RESPONSE` field (line 367)
4. **Action Execution**: Based on prompt_type and extracted fields
5. **Completion**: Renames file with `.processed` extension

## Best Practices

1. **Always include all required core fields**
2. **Use descriptive session_id values** for tracking related signals
3. **Include prompt-type specific required fields**
4. **RESPONSE field should always contain the action keyword** (TESTING, CONTINUE, etc.)
5. **For Testing prompt type, always include `test_script` field** at root level
6. **Use ISO 8601 timestamps** for consistency
7. **Include optional fields when they provide valuable context**

## Common Mistakes to Avoid

1. ❌ **Wrong location**: Placing files outside `./ClaudeResponses/Autonomous/`
2. ❌ **Missing RESPONSE field**: Orchestrator won't detect the action
3. ❌ **Wrong prompt_type case**: Use exact case (e.g., "Testing" not "TESTING")
4. ❌ **Missing test_script for Testing**: Orchestrator can't find script to execute
5. ❌ **Nested test_script**: Place at root level, not inside test_details
6. ❌ **Invalid JSON syntax**: Use proper JSON formatting and escaping

## Validation Checklist

Before creating a JSON signal file, verify:
- [ ] File will be placed in `./ClaudeResponses/Autonomous/`
- [ ] All core required fields are present
- [ ] `prompt_type` matches valid values exactly
- [ ] `RESPONSE` contains appropriate action keyword
- [ ] Prompt-type specific required fields are included
- [ ] JSON syntax is valid (use a JSON validator)
- [ ] Timestamps follow ISO 8601 format
- [ ] File paths use proper escaping (double backslashes on Windows)

## Example: Complete Testing Signal

```json
{
  "timestamp": "2025-08-28T03:00:00Z",
  "session_id": "day2-test-callgraph-dataflow",
  "prompt_type": "Testing",
  "task": "Test Day 2 implementations - Call Graph Builder and Data Flow Tracker",
  "test_script": "Test-Day2-CallGraphDataFlow.ps1",
  "test_details": {
    "modules_to_test": [
      "CPG-CallGraphBuilder.psm1",
      "CPG-DataFlowTracker.psm1"
    ],
    "expected_tests": 25,
    "test_groups": 3,
    "coverage_areas": [
      "Module loading and function availability",
      "Call graph construction and analysis",
      "Recursive call detection",
      "Data flow construction",
      "Taint analysis validation",
      "Security vulnerability detection",
      "Sensitivity analysis",
      "Integration testing"
    ]
  },
  "validation_criteria": {
    "call_graph": [
      "Detect 4+ functions in sample script",
      "Identify recursive calls",
      "Generate call metrics",
      "Export to JSON format"
    ],
    "data_flow": [
      "Track variable definitions and uses",
      "Create def-use chains",
      "Detect tainted variables",
      "Identify sensitive data",
      "Find unused definitions"
    ]
  },
  "expected_workflow": {
    "step_1": "Orchestrator detects this JSON signal file",
    "step_2": "Executes Test-Day2-CallGraphDataFlow.ps1",
    "step_3": "Test creates sample PowerShell script for analysis",
    "step_4": "Builds call graph from sample script",
    "step_5": "Builds data flow from sample script",
    "step_6": "Validates recursive call detection",
    "step_7": "Validates taint analysis detection",
    "step_8": "Generates test results JSON with metrics",
    "step_9": "Creates boilerplate prompt with results",
    "step_10": "Submits to Claude via clipboard paste"
  },
  "RESPONSE": "TESTING - Test-Day2-CallGraphDataFlow.ps1: Execute comprehensive test suite to validate Call Graph Builder and Data Flow Tracker implementations"
}
```

## References

- **Orchestrator Implementation**: `Start-CLIOrchestrator.ps1`
- **Response Processing**: Lines 350-470 handle JSON signal detection and processing
- **Test Script Detection**: Line 366 specifically checks for `test_script` field
- **Boilerplate Generation**: `New-BoilerplatePrompt` function in CLIOrchestrator module
- **Window Management**: `Submit-ToClaudeViaTypeKeys` function for Claude interaction

---

**Last Updated**: 2025-08-28
**Version**: 1.0.0
**Status**: ACTIVE - This is the canonical reference for JSON signal file structure