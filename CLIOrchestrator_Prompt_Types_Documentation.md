# Unity-Claude CLIOrchestrator - Prompt Types Documentation
*Last Updated: 2025-08-27*

## Overview
The CLIOrchestrator is an intelligent automation system that processes different types of prompts and performs appropriate actions. It creates a bidirectional communication channel between the Unity-Claude system and the Claude Code CLI, enabling autonomous operation and intelligent decision-making.

## Architecture Components

### 1. **OrchestrationManager** 
- Main control center that monitors for responses and signals
- Processes both JSON response files and test completion signals
- Manages the autonomous execution loop

### 2. **AutonomousOperations**
- Creates and processes autonomous prompts
- Extracts recommendations and actions from responses
- Manages the execution loop

### 3. **WindowManager**
- Detects and manages Claude CLI windows
- Handles window switching and focus

### 4. **PromptSubmissionEngine**
- Submits prompts to Claude using TypeKeys
- Ensures safe text submission with proper escaping

## Prompt Types and Details

### 1. Testing
**Purpose**: Execute test scripts and submit results to Claude for analysis
**Trigger**: When a response contains `prompt_type: "Testing"`
**Details Section Should Include**:
- `test_path`: Full or relative path to the test script (e.g., `.\Test-CLIOrchestrator-Simple.ps1`)
- `test_name`: Optional friendly name for the test
- `expected_outcome`: Optional description of expected results

**Example Response JSON**:
```json
{
    "timestamp": "2025-08-27 12:00:00",
    "prompt_type": "Testing",
    "details": ".\\Test-CLIOrchestrator-Simple.ps1",
    "RESPONSE": "RECOMMENDATION: TEST - .\\Test-CLIOrchestrator-Simple.ps1"
}
```

**Workflow**:
1. CLIOrchestrator detects Testing prompt_type
2. Extracts test path from details or RESPONSE field
3. Executes test in new PowerShell window
4. Test runner creates signal file when complete
5. Orchestrator detects signal file
6. Reads test results and submits to Claude
7. Claude analyzes results and provides next recommendation

### 2. Debugging
**Purpose**: Investigate issues with enhanced logging and analysis
**Trigger**: When a response contains `prompt_type: "Debugging"`
**Details Section Should Include**:
- `target_module`: Module or script to debug
- `error_pattern`: Specific error to investigate
- `log_level`: Desired logging verbosity (Verbose, Debug, Trace)

**Example Response JSON**:
```json
{
    "timestamp": "2025-08-27 12:00:00",
    "prompt_type": "Debugging",
    "details": "Unity-Claude-CLIOrchestrator",
    "RESPONSE": "RECOMMENDATION: FIX - Add comprehensive debug logging to trace execution flow"
}
```

### 3. Continue
**Purpose**: Continue with the next step in an implementation plan
**Trigger**: When a response contains `prompt_type: "Continue"`
**Details Section Should Include**:
- `next_step`: Description of the next implementation step
- `phase`: Current phase of implementation
- `context`: Any relevant context for continuation

**Example Response JSON**:
```json
{
    "timestamp": "2025-08-27 12:00:00",
    "prompt_type": "Continue",
    "details": "Proceed to Day 5: Configuration & Documentation - Hour 1-4",
    "RESPONSE": "RECOMMENDATION: CONTINUE: Create configuration management for notification settings"
}
```

### 4. Fix
**Purpose**: Fix a specific file or module
**Trigger**: When a response contains `prompt_type: "Fix"`
**Details Section Should Include**:
- `file_path`: Path to the file needing fixes
- `issues`: List of issues to address
- `priority`: Urgency of the fix (High, Medium, Low)

**Example Response JSON**:
```json
{
    "timestamp": "2025-08-27 12:00:00",
    "prompt_type": "Fix",
    "details": "Modules\\Unity-Claude-CLIOrchestrator\\Core\\AutonomousOperations.psm1",
    "RESPONSE": "RECOMMENDATION: FIX - AutonomousOperations.psm1: Add better response parsing"
}
```

### 5. Compile
**Purpose**: Compile or build the project
**Trigger**: When a response contains `prompt_type: "Compile"`
**Details Section Should Include**:
- `build_config`: Build configuration (Debug, Release)
- `target`: Specific target to build
- `clean_first`: Whether to clean before building

**Example Response JSON**:
```json
{
    "timestamp": "2025-08-27 12:00:00",
    "prompt_type": "Compile",
    "details": "Release configuration",
    "RESPONSE": "RECOMMENDATION: COMPILE - Build the solution in Release mode"
}
```

### 6. System Test Request
**Purpose**: Execute system-wide tests
**Trigger**: When a response contains `prompt_type: "System Test Request"`
**Details Section Should Include**:
- `test_suite`: Name of test suite to run
- `components`: List of components to test
- `validation_criteria`: Success criteria for the tests

**Example Response JSON**:
```json
{
    "timestamp": "2025-08-27 12:00:00",
    "prompt_type": "System Test Request",
    "details": "Test-UnityClaudeModules.ps1",
    "RESPONSE": "RECOMMENDATION: TEST - Run comprehensive module validation"
}
```

### 7. Complete
**Purpose**: Mark a task or phase as complete
**Trigger**: When a response contains `prompt_type: "Complete"`
**Details Section Should Include**:
- `completed_task`: Description of what was completed
- `summary`: Summary of achievements
- `next_phase`: Optional next phase to begin

**Example Response JSON**:
```json
{
    "timestamp": "2025-08-27 12:00:00",
    "prompt_type": "Complete",
    "details": "Phase 7 CLIOrchestrator Implementation",
    "RESPONSE": "RECOMMENDATION: COMPLETE - CLIOrchestrator implementation successful"
}
```

### 8. Error
**Purpose**: Handle error conditions
**Trigger**: When a response contains `prompt_type: "Error"`
**Details Section Should Include**:
- `error_message`: The error that occurred
- `stack_trace`: Optional stack trace
- `recovery_action`: Suggested recovery steps

**Example Response JSON**:
```json
{
    "timestamp": "2025-08-27 12:00:00",
    "prompt_type": "Error",
    "details": "Failed to import module: Unity-Claude-CLIOrchestrator",
    "RESPONSE": "RECOMMENDATION: ERROR - Module import failed, check syntax"
}
```

## Response File Structure

All response files should be saved as JSON in `.\ClaudeResponses\Autonomous\` with this structure:

```json
{
    "timestamp": "YYYY-MM-DD HH:MM:SS",
    "prompt_type": "PromptTypeName",
    "details": "Specific details for the action",
    "RESPONSE": "RECOMMENDATION: ACTION - Description",
    "confidence": 85,
    "reasoning": ["Optional reasoning for the decision"]
}
```

## Signal Files

For asynchronous operations like testing, signal files are created in `.\ClaudeResponses\Autonomous\`:

**Format**: `TestComplete_YYYYMMDD_HHMMSS.signal`

**Structure**:
```json
{
    "TestPath": "Path to test that was executed",
    "ResultFile": "Path to test results file",
    "ExitCode": 0,
    "Status": "SUCCESS",
    "Timestamp": "YYYY-MM-DD HH:MM:SS"
}
```

## Execution Flow

1. **Response Detection**:
   - Orchestrator monitors `.\ClaudeResponses\Autonomous\` for new JSON files
   - Files are processed in chronological order

2. **Decision Making**:
   - Response is parsed to extract prompt_type and details
   - Decision engine determines appropriate action
   - Safety checks are performed

3. **Action Execution**:
   - Action is executed based on prompt_type
   - For tests: New PowerShell window is launched
   - For other actions: Direct execution in current context

4. **Result Processing**:
   - Results are captured and formatted
   - For tests: Signal file triggers result submission
   - Prompt is constructed with boilerplate + results

5. **Claude Submission**:
   - Window manager switches to Claude CLI
   - PromptSubmissionEngine submits via TypeKeys
   - System returns to monitoring state

## Safety Features

1. **Path Validation**: All file paths are validated before execution
2. **Command Filtering**: Dangerous commands are blocked
3. **Execution Limits**: Maximum iterations and timeouts prevent infinite loops
4. **Error Recovery**: Graceful error handling with detailed logging
5. **Signal Archiving**: Processed signals are archived to prevent reprocessing

## Configuration

Key configuration parameters in the orchestration system:

- `MonitoringInterval`: How often to check for new responses (default: 30 seconds)
- `MaxExecutionTime`: Maximum runtime before automatic shutdown (default: 60 minutes)
- `EnableResponseAnalysis`: Whether to perform deep response analysis
- `EnableDecisionMaking`: Whether to enable autonomous decision making
- `AutonomousMode`: Whether to run in fully autonomous mode

## Troubleshooting

### Common Issues

1. **Test Not Executing**:
   - Verify test path is correct
   - Check if Execute-TestInWindow.ps1 exists
   - Ensure PowerShell execution policy allows scripts

2. **Results Not Submitted**:
   - Check if Claude CLI window is open
   - Verify signal files are being created
   - Check logs for submission errors

3. **JSON Parse Errors**:
   - Ensure response files are valid JSON
   - Check for UTF-8 encoding issues
   - Verify all required fields are present

### Debug Mode

Enable comprehensive debugging by setting environment variable:
```powershell
$env:CLIORCH_DEBUG = "true"
```

This will enable verbose logging throughout all components.

## Best Practices

1. **Response Files**: Always include both prompt_type and RESPONSE fields
2. **Test Paths**: Use absolute paths when possible, relative paths from project root
3. **Details Field**: Be specific and comprehensive in the details section
4. **Error Handling**: Always include error recovery recommendations
5. **Signal Files**: Don't manually create signal files - let the system manage them

## Example Usage

### Starting the Orchestrator
```powershell
# Import and initialize
Import-Module Unity-Claude-CLIOrchestrator
Initialize-CLIOrchestrator -ValidateComponents -SetupDirectories

# Start orchestration with all features
Start-CLIOrchestration -AutonomousMode -EnableResponseAnalysis -EnableDecisionMaking
```

### Creating a Test Response
```powershell
$response = @{
    timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    prompt_type = "Testing"
    details = ".\Test-CLIOrchestrator-Simple.ps1"
    RESPONSE = "RECOMMENDATION: TEST - .\Test-CLIOrchestrator-Simple.ps1: Validate core functions"
}

$response | ConvertTo-Json | Out-File ".\ClaudeResponses\Autonomous\test_request.json"
```

## Version History

- **v2.0.0** (2025-08-27): Enhanced testing workflow with comprehensive logging
- **v1.5.0** (2025-08-25): Added signal file processing for async operations
- **v1.0.0** (2025-08-24): Initial release with basic orchestration

## Support

For issues or questions:
- Check logs in `.\logs\orchestrator\`
- Review test results in project root
- Examine signal files in `.\ClaudeResponses\Autonomous\`