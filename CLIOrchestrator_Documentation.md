# CLI Orchestrator Documentation

## Overview
The CLI Orchestrator is an autonomous system that monitors JSON files containing Claude's responses and takes appropriate actions based on the prompt type and content.

## Architecture
- **Component-Based**: Refactored into 8 modular components for maintainability
- **Autonomous Operation**: Runs continuously monitoring for new instructions
- **Decision Engine**: Makes rule-based decisions on what actions to take
- **Action Execution**: Safely executes approved actions with full logging

## Core Components

### 1. OrchestrationManager
- Main orchestration control and monitoring loop
- Coordinates all other components
- Manages monitoring cycles and execution flow

### 2. ResponseAnalysisEngine
- Analyzes JSON response files from Claude
- Extracts entities, patterns, and recommendations
- Performs comprehensive response analysis

### 3. PatternRecognitionEngine
- Identifies patterns in responses
- Classifies prompt types and intentions
- Detects action recommendations

### 4. DecisionEngine
- Makes rule-based decisions on actions to take
- Evaluates safety and validity of actions
- Assigns confidence scores to decisions

### 5. ActionExecutionEngine
- Safely executes approved actions
- Manages execution queue
- Handles error recovery

### 6. WindowManager
- Detects and manages Claude CLI window
- Handles window switching and focus

### 7. PromptSubmissionEngine
- Submits prompts to Claude via TypeKeys
- Includes safety measures and validation
- Handles boilerplate prompt inclusion

### 8. AutonomousOperations
- Manages autonomous execution loops
- Generates prompts based on context
- Handles continuous operation

## Prompt Types and Required Details

### Testing
**Purpose**: Execute PowerShell test scripts and report results
**Required Details**:
- `test_path`: Full path to the test script (.ps1 file)
- `expected_behavior`: Array of expected behaviors (optional)
- `timeout`: Maximum execution time in seconds (optional, default: 300)

**Response Format**:
```json
{
  "prompt_type": "Testing",
  "response": "RECOMMENDATION: Testing - C:\\path\\to\\test.ps1",
  "details": "Description of what to test"
}
```

**Execution Flow** (Updated 2025-08-27 with Enhanced Error Handling):
1. Detects Testing prompt-type from JSON `prompt_type` field
2. Extracts test path from `details` field or RESPONSE recommendation
3. Makes EXECUTE_TEST decision with 95% confidence
4. Executes test via Execute-TestInWindow.ps1:
   - Opens new PowerShell window
   - Executes test with full error capture (stdout + stderr)
   - **ALWAYS** saves results to timestamped .txt file (even on failure)
   - **ALWAYS** creates TestComplete signal file (includes ErrorDetails on failure)
   - **ALWAYS** closes window properly (shows status, waits if not AutoClose)
5. Orchestrator processes TestComplete signal:
   - Detects success/failure from Status field
   - Reads full test results from result file
   - Builds appropriate prompt (different for success vs failure)
6. Submits results back to Claude via TypeKeys:
   - Includes boilerplate prompt directives
   - For failures: includes error details and asks for fix suggestions
   - For success: includes results for review

**Error Handling Features**:
- **ErrorActionPreference**: Set to 'Continue' to capture all output
- **Try-Catch-Finally**: Ensures cleanup even on catastrophic failure
- **Error Capture**: Full exception messages and stack traces saved
- **Signal Files**: Created even for failed tests with ErrorDetails field
- **Window Management**: Finally block ensures windows always close properly
- **Result Files**: Always created with whatever output was captured
- **Prevents Loops**: Failed tests won't keep reopening indefinitely

### System Test Request
**Purpose**: Similar to Testing but for system-level tests
**Required Details**:
- Same as Testing prompt-type
- May include multiple test paths

### Implementation Task
**Purpose**: Implement new features or fix issues
**Required Details**:
- `task`: Description of what to implement
- `files`: Array of files to modify (optional)
- `priority`: High/Medium/Low (optional)

**Response Format**:
```json
{
  "prompt_type": "Implementation Task",
  "response": "RECOMMENDATION: Implement feature X in file Y",
  "details": "Detailed implementation instructions"
}
```

### Debugging
**Purpose**: Debug and investigate issues
**Required Details**:
- `issue`: Description of the problem
- `error_message`: Specific error text (optional)
- `files`: Relevant files to check (optional)

**Response Format**:
```json
{
  "prompt_type": "Debugging",
  "response": "RECOMMENDATION: Investigate error in module X",
  "details": "Debug steps and areas to check"
}
```

### Documentation
**Purpose**: Create or update documentation
**Required Details**:
- `document_type`: Type of documentation (API, User Guide, etc.)
- `target_files`: Files to document (optional)
- `format`: Markdown/HTML/etc. (optional, default: Markdown)

### Analysis
**Purpose**: Analyze code or system behavior
**Required Details**:
- `analysis_type`: Type of analysis (Performance, Security, Quality)
- `target`: What to analyze (files, modules, system)
- `metrics`: Specific metrics to report (optional)

## Decision Types

### EXECUTE_TEST
- Triggered by Testing prompt-type
- Executes test scripts in new window
- Captures and reports results

### EXECUTE
- General execution of approved actions
- Used for implementation tasks

### INVESTIGATE
- Triggered by debugging requests
- Gathers information without making changes

### FIX
- Applies fixes to identified issues
- Requires high confidence

### COMPILE
- Triggers compilation or build processes
- Monitors for errors

### CONTINUE
- Continues with current operation
- Used for multi-step processes

### DEFER
- Defers action for manual review
- Used when confidence is low

### MONITOR
- Continues monitoring without action
- Default for informational responses

## Configuration

### Monitoring Settings
- `MonitoringInterval`: Seconds between monitoring cycles (default: 5)
- `MaxExecutionTime`: Maximum runtime in minutes (default: 60)
- `ResponseDirectory`: Path to monitor for JSON files

### Execution Modes
- `AutonomousMode`: Enable autonomous operation (default: true)
- `EnableResponseAnalysis`: Analyze responses (default: true)
- `EnableDecisionMaking`: Make decisions (default: true)
- `SafetyMode`: Enhanced safety checks (default: true)

## Signal Files

Signal files are used for asynchronous communication between processes:

### TestComplete_*.signal
Created when a test completes execution (Updated 2025-08-27 with error handling)
```json
{
  "TestPath": "path/to/test.ps1",
  "ResultFile": "path/to/results.txt",
  "ExitCode": 0,
  "Status": "SUCCESS",
  "ErrorDetails": null,  // Contains error message on failure
  "Timestamp": "2025-08-27 13:00:00"
}
```

**Failure Example**:
```json
{
  "TestPath": "./Test-PredictiveAnalysis.ps1",
  "ResultFile": "./Test-PredictiveAnalysis-TestResults-20250827-191234.txt",
  "ExitCode": 1,
  "Status": "FAILED",
  "ErrorDetails": "The term 'Import-RequiredModule' is not recognized",
  "Timestamp": "2025-08-27 19:12:34"
}
```

## Boilerplate Prompt

The system automatically prepends a boilerplate prompt from:
`C:\UnityProjects\Sound-and-Shoal\Unity-Claude-Automation\CLAUDE_PROMPT_DIRECTIVES_COMPLETE_UCA.txt`

This ensures consistent context and directives for Claude.

## Safety Features

1. **Path Validation**: All file paths are validated before execution
2. **Command Filtering**: Dangerous commands are blocked
3. **Confidence Thresholds**: Actions require minimum confidence scores
4. **Error Recovery**: Graceful handling of failures
5. **Audit Logging**: All actions are logged for review

## Troubleshooting

### Test Not Executing
1. Check debug logs for "EXECUTE_TEST CASE REACHED"
2. Verify test path exists and is valid
3. Ensure Execute-TestInWindow.ps1 is present
4. Check for signal files in ClaudeResponses\Autonomous

### Test Keeps Reopening in New Windows
**Issue**: Tests repeatedly open in new PowerShell windows without completing
**Root Cause**: Execute-TestInWindow.ps1 was failing without proper error handling
**Fixed in v3.0** (2025-08-27):
- Added comprehensive try-catch-finally block
- Changed ErrorActionPreference to 'Continue'
- Always saves results and creates signal files
- Always closes window properly

### Test Results Not Being Created
**Issue**: No test result files appear when tests fail
**Root Cause**: Error would stop execution before saving results
**Fixed in v3.0**:
- Finally block ensures results are always saved
- Error output captured even on failure
- Default result file name generated if not provided

### Test Errors Not Captured
**Issue**: Test failures show no error details
**Root Cause**: stderr not being captured properly
**Fixed in v3.0**:
- Uses `2>&1 | Out-String -Stream` to capture all output
- Catches exceptions during test execution
- Includes ErrorDetails in signal files
- Submits error context to Claude for analysis

### Submission Failures
1. Verify Claude CLI window is open
2. Check window title matches expected pattern
3. Ensure TypeKeys permissions are enabled
4. Review submission logs for errors

### Signal File Issues
1. Check ClaudeResponses\Autonomous directory permissions
2. Look for *.signal.processed files (archived signals)
3. Verify JSON format in signal files
4. Check timestamp filtering in monitoring loop
5. For failed tests, check ErrorDetails field in signal

## Usage Example

Start the orchestrator:
```powershell
.\Start-CLIOrchestrator-Fixed.ps1 -PollIntervalSeconds 5
```

Create a test JSON file:
```powershell
@{
    timestamp = Get-Date -Format "yyyy-MM-ddTHH:mm:ss"
    prompt_type = "Testing"
    response = "RECOMMENDATION: Testing - .\Test-Module.ps1"
    details = "Test the module functionality"
} | ConvertTo-Json | Out-File ".\ClaudeResponses\Autonomous\test_request.json"
```

The orchestrator will:
1. Detect the JSON file
2. Process with Process-ResponseFile (extract prompt_type and details)
3. Make EXECUTE_TEST decision via Invoke-AutonomousDecisionMaking
4. Launch test in new window via Invoke-DecisionExecution
5. Test runs with Execute-TestInWindow.ps1 v3.0:
   - Captures all output (stdout + stderr)
   - Saves results even on failure
   - Creates TestComplete signal with Status and ErrorDetails
   - Closes window properly
6. Process-SignalFile detects TestComplete signal
7. Builds appropriate prompt (different for success/failure)
8. Submit results to Claude via Submit-ToClaudeViaTypeKeys

## Version History

### v3.0 (2025-08-27) - Enhanced Error Handling
- **Execute-TestInWindow.ps1**: Complete error handling rewrite
  - Added try-catch-finally for guaranteed cleanup
  - Always saves test results, even on failure
  - Always creates signal files with ErrorDetails
  - Properly closes windows after showing status
  - Changed ErrorActionPreference to 'Continue'
- **Process-SignalFile**: Enhanced TestComplete signal processing
  - Handles standalone TestComplete signals (no JSON needed)
  - Different prompts for success vs failure
  - Includes error context for failed tests
- **Enhanced Logging**: Added comprehensive [TRACE] level logging
  - Full object dumps at key decision points
  - Detailed flow tracing for debugging
  - Error details captured and propagated

### v2.0 (2025-08-25) - Component Architecture
- Refactored from monolithic to component-based architecture
- Split into 8 specialized modules
- Added Public/Private folder structure to avoid module nesting limits
- PowerShell 5.1 compatibility fixes

### v1.0 - Initial Implementation
- Basic autonomous monitoring and execution
- JSON response processing
- Claude CLI integration via TypeKeys