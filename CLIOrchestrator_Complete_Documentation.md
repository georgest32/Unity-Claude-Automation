# Unity-Claude CLIOrchestrator Complete Documentation
**Version:** 2.0.0  
**Architecture:** Component-Based  
**Last Updated:** 2025-08-27  

## Overview

The Unity-Claude CLIOrchestrator is an advanced autonomous system that monitors JSON response files, makes intelligent decisions based on prompt types, executes appropriate actions, and submits results back to the Claude Code CLI interface.

## Core Functionality

### 1. Autonomous Monitoring
- **Directory Monitoring:** Continuously scans `.\ClaudeResponses\Autonomous\` for new JSON files
- **Interval:** Configurable (default 5-30 seconds)
- **Detection:** Identifies new files created after orchestrator start time
- **Processing:** Processes files in chronological order

### 2. JSON Response Processing
- **Parsing:** Reads and validates JSON structure
- **Field Detection:** Extracts key fields (prompt_type, response, timestamp, etc.)
- **Validation:** Ensures required fields are present
- **Error Handling:** Gracefully handles malformed JSON

### 3. Decision Making
- **Prompt-Type Aware:** Makes decisions based on prompt_type field
- **Pattern Recognition:** Falls back to pattern matching if prompt_type missing
- **Safety Validation:** Checks for potentially dangerous operations
- **Confidence Scoring:** Assigns confidence levels to decisions

### 4. Action Execution
- **Test Execution:** Runs PowerShell test scripts with output capture
- **Result Storage:** Saves test results to timestamped files
- **Window Management:** Switches to Claude CLI window
- **Prompt Submission:** Types prompts using SendKeys automation

## Supported Prompt Types

### Testing
**Purpose:** Execute tests and report results back to Claude  
**JSON Structure:**
```json
{
  "timestamp": "2025-08-27T11:00:00",
  "prompt_type": "Testing",
  "response": "RECOMMENDATION: Testing - C:\\path\\to\\test.ps1",
  "details": "Additional test parameters or instructions"
}
```
**Actions:**
1. Extracts test file path from response
2. Validates test file exists
3. Executes test with PowerShell
4. Captures all output and exit code
5. Saves results to timestamped file
6. Builds prompt with boilerplate + test results
7. Switches to Claude window
8. Submits prompt via TypeKeys

### System Test Request
**Purpose:** Similar to Testing but for system-level tests  
**JSON Structure:**
```json
{
  "timestamp": "2025-08-27T11:00:00",
  "prompt_type": "System Test Request",
  "response": "RECOMMENDATION: Testing - C:\\path\\to\\system-test.ps1"
}
```
**Actions:** Same as Testing prompt type

### Debugging
**Purpose:** Investigate and debug issues  
**JSON Structure:**
```json
{
  "timestamp": "2025-08-27T11:00:00",
  "prompt_type": "Debugging",
  "response": "RECOMMENDATION: FIX - FileName.ps1",
  "issue": "Description of the problem",
  "analysis": {
    "error": "Error details",
    "line": 42,
    "suggestion": "Suggested fix"
  }
}
```
**Actions:**
1. Flags issue for investigation
2. Logs debugging information
3. May trigger additional analysis
4. Submits findings to Claude if needed

### Continue
**Purpose:** Continue with implementation plan  
**JSON Structure:**
```json
{
  "timestamp": "2025-08-27T11:00:00",
  "prompt_type": "Continue",
  "response": "RECOMMENDATION: CONTINUE: Next implementation step details"
}
```
**Actions:**
1. Extracts continuation instructions
2. Submits to Claude for next steps

### ARP (Analysis, Research, and Planning)
**Purpose:** Perform analysis and create implementation plans  
**JSON Structure:**
```json
{
  "timestamp": "2025-08-27T11:00:00",
  "prompt_type": "ARP",
  "topic": "Feature or system to analyze",
  "response": "RECOMMENDATION: Research and plan for XYZ feature"
}
```
**Actions:**
1. Triggers research mode
2. May execute analysis scripts
3. Generates planning documentation
4. Submits findings to Claude

### Review
**Purpose:** Review code or documentation  
**JSON Structure:**
```json
{
  "timestamp": "2025-08-27T11:00:00",
  "prompt_type": "Review",
  "target": "File or component to review",
  "response": "RECOMMENDATION: Review implementation status"
}
```
**Actions:**
1. Performs review analysis
2. Generates review report
3. Submits findings to Claude

## Response Field Formats

### RECOMMENDATION Patterns
The CLIOrchestrator recognizes these recommendation patterns in the response field:

- **Testing:** `RECOMMENDATION: Testing - [FilePath]`
- **Continue:** `RECOMMENDATION: CONTINUE: [Details]`
- **Fix:** `RECOMMENDATION: FIX - [FileName]: [Details]`
- **Compile:** `RECOMMENDATION: COMPILE`
- **Restart:** `RECOMMENDATION: RESTART - [ModuleName]`
- **Complete:** `RECOMMENDATION: COMPLETE`
- **Error:** `RECOMMENDATION: ERROR - [Description]`

### Details Field
The details field provides prompt-type specific information:
- **Testing:** Test parameters, expected results, validation criteria
- **Debugging:** Error context, stack traces, variable states
- **Continue:** Next steps, dependencies, requirements
- **ARP:** Research questions, scope, deliverables
- **Review:** Review criteria, focus areas, checklist

## Configuration

### Startup Parameters
```powershell
Start-CLIOrchestrator -AutonomousMode `
                     -MonitoringInterval 5 `
                     -MaxExecutionTime 60 `
                     -EnableResponseAnalysis `
                     -EnableDecisionMaking
```

### Parameters Explained
- **AutonomousMode:** Enable fully autonomous operation
- **MonitoringInterval:** Seconds between monitoring cycles (default: 30)
- **MaxExecutionTime:** Minutes before automatic shutdown (default: 60)
- **EnableResponseAnalysis:** Enable comprehensive response analysis
- **EnableDecisionMaking:** Enable autonomous decision making

## Safety Features

### Blocked Patterns
The following patterns trigger safety blocks:
- `rm -rf` - Dangerous recursive deletion
- `Remove-Item -Recurse -Force` - PowerShell recursive deletion
- `format` - Disk formatting commands
- `shutdown` - System shutdown commands
- File operations on system directories

### Safety Validation
Before executing any action:
1. Pattern matching against dangerous commands
2. Path validation for file operations
3. Scope checking for system modifications
4. User confirmation for high-risk operations (if not fully autonomous)

## Debug Logging

### Log Levels
- **[DEBUG]** - Detailed trace information
- **[INFO]** - Normal operational messages
- **[WARNING]** - Non-critical issues
- **[ERROR]** - Errors that don't stop operation
- **[CRITICAL]** - Fatal errors requiring restart

### Key Debug Points
1. JSON file detection and parsing
2. Prompt type identification
3. Decision making process
4. Test execution start/end
5. Result file creation
6. Window switching attempts
7. Claude submission status

## Troubleshooting

### Common Issues and Solutions

#### JSON Not Detected
- **Check:** File location in `.\ClaudeResponses\Autonomous\`
- **Check:** File extension is `.json`
- **Check:** File timestamp is after orchestrator start
- **Solution:** Ensure proper directory and file naming

#### Test Execution Fails
- **Check:** Test file path exists and is accessible
- **Check:** PowerShell execution policy allows script
- **Check:** Required modules are loaded
- **Solution:** Use absolute paths, set execution policy

#### Claude Window Not Found
- **Check:** Claude Code CLI is running and visible
- **Check:** Window title matches expected pattern
- **Check:** No modal dialogs blocking
- **Solution:** Restart Claude, ensure window is not minimized

#### TypeKeys Not Working
- **Check:** Window has focus before typing
- **Check:** No keyboard input blockers
- **Check:** Text length within limits
- **Solution:** Add delays, use clipboard for long text

## Performance Considerations

### Optimization Tips
1. Keep monitoring interval balanced (5-30 seconds)
2. Limit concurrent test executions
3. Clean up old result files periodically
4. Use absolute paths for better performance
5. Minimize window switching operations

### Resource Usage
- **CPU:** Low during monitoring, spike during test execution
- **Memory:** Proportional to test output size
- **Disk I/O:** Minimal, only for file operations
- **Network:** None (all local operations)

## Integration Points

### Input Sources
1. JSON files in `.\ClaudeResponses\Autonomous\`
2. Manual trigger files
3. System event triggers (future)

### Output Destinations
1. Test result files (timestamped .txt)
2. Claude Code CLI (via TypeKeys)
3. System logs (orchestrator logs)
4. Status files (optional)

## Future Enhancements

### Planned Features
1. Support for parallel test execution
2. Advanced error recovery and retry logic
3. Integration with CI/CD pipelines
4. Remote execution capabilities
5. Web dashboard for monitoring
6. Email/webhook notifications
7. Custom prompt type plugins
8. Machine learning for decision optimization

### Extension Points
- Custom decision handlers
- Additional safety validators
- Alternative submission methods
- Result formatters
- Event hooks

## Examples

### Example Testing Flow
1. Claude generates JSON with Testing prompt-type
2. CLIOrchestrator detects new JSON file
3. Parses and identifies Testing prompt-type
4. Extracts test path: `C:\Tests\MyTest.ps1`
5. Executes test and captures output
6. Saves results to `MyTest-TestResults-20250827-113000.txt`
7. Builds prompt with boilerplate and results
8. Switches to Claude window
9. Types and submits prompt
10. Claude processes test results

### Example JSON Response
```json
{
  "timestamp": "2025-08-27T11:30:00",
  "prompt_type": "Testing",
  "issue": "Validation of new feature",
  "analysis": {
    "test_required": true,
    "test_path": "C:\\UnityProjects\\Tests\\Feature.ps1",
    "expected_outcome": "All tests pass"
  },
  "response": "RECOMMENDATION: Testing - C:\\UnityProjects\\Tests\\Feature.ps1",
  "details": "Run comprehensive feature tests with verbose output"
}
```

## Support and Maintenance

### Log Files
- **Orchestrator Log:** `.\logs\orchestrator\orchestrator.log`
- **Error Log:** `.\autonomous_monitoring_errors.log`
- **Test Results:** `.\\*-TestResults-*.txt`

### Maintenance Tasks
1. Regular log rotation (weekly)
2. Clean old test results (monthly)
3. Update boilerplate prompt (as needed)
4. Review safety patterns (quarterly)
5. Performance tuning (as needed)

## Version History

### v2.0.0 (2025-08-27)
- Complete refactor to component-based architecture
- Enhanced Testing prompt-type support
- Comprehensive debug logging
- Improved error handling
- Documentation created

### v1.0.0 (2025-08-25)
- Initial implementation
- Basic monitoring and decision making
- Simple pattern matching

## API Reference

### Core Functions

#### Start-CLIOrchestration
```powershell
Start-CLIOrchestration [-AutonomousMode] [-MonitoringInterval <int>] 
                      [-MaxExecutionTime <int>] [-EnableResponseAnalysis] 
                      [-EnableDecisionMaking]
```
**Purpose:** Starts the CLIOrchestrator monitoring and decision system  
**Parameters:**
- `AutonomousMode`: Enable fully autonomous operation without user prompts
- `MonitoringInterval`: Seconds between monitoring cycles (default: 30)
- `MaxExecutionTime`: Minutes before automatic shutdown (default: 60)
- `EnableResponseAnalysis`: Enable comprehensive response analysis (recommended)
- `EnableDecisionMaking`: Enable autonomous decision making (required for testing)

#### Get-CLIOrchestrationStatus
```powershell
Get-CLIOrchestrationStatus
```
**Purpose:** Returns current status of CLIOrchestrator system  
**Returns:** Hashtable with Status, LastActivity, ProcessedFiles, Errors

#### Find-RecommendationPatterns
```powershell
Find-RecommendationPatterns -ResponseText <string>
```
**Purpose:** Extracts recommendation patterns from response text  
**Returns:** Array of pattern matches with confidence scores

#### Invoke-RuleBasedDecision
```powershell
Invoke-RuleBasedDecision -AnalysisResult <hashtable> [-DryRun]
```
**Purpose:** Makes decisions based on analysis results using rule-based logic  
**Returns:** Decision object with Action, Confidence, and Details

#### Test-SafetyValidation
```powershell
Test-SafetyValidation -AnalysisResult <hashtable>
```
**Purpose:** Validates operations for safety before execution  
**Returns:** Safety validation result with IsSafe flag and warnings

#### Extract-ResponseEntities
```powershell
Extract-ResponseEntities -ResponseText <string>
```
**Purpose:** Extracts entities (file paths, commands, etc.) from response text  
**Returns:** Hashtable with FilePaths, PowerShellCommands, and other entities

#### Analyze-ResponseSentiment
```powershell
Analyze-ResponseSentiment -ResponseText <string>
```
**Purpose:** Performs sentiment analysis on response text  
**Returns:** Sentiment object with Classification, Confidence, and scores

### Enhanced Logging Examples

The CLIOrchestrator includes comprehensive debug logging with visual indicators for easy identification:

#### Testing Flow Debug Output
```
[DEBUG] *** TESTING FLOW TRACE *** Starting prompt-type decision logic
[DEBUG] *** TESTING FLOW *** Processing Testing prompt-type  
[DEBUG] TESTING FLOW: 🔍 Searching for test path in response: 'RECOMMENDATION: Testing - C:\Tests\MyTest.ps1'
[DEBUG] TESTING FLOW: ✅ Found test path using pattern 'Testing\s*[-:]\s*([^\s]+\.ps1)': C:\Tests\MyTest.ps1
[DEBUG] TESTING FLOW: 📁 Validating test path exists: C:\Tests\MyTest.ps1
[DEBUG] TESTING FLOW: ✅ Test path validation successful
[DEBUG] TESTING FLOW: 🚀 Starting test execution for: C:\Tests\MyTest.ps1
[DEBUG] TESTING FLOW: ⚙️ Executing PowerShell test with capture
[DEBUG] TESTING FLOW: 💾 Saving test results to: MyTest-TestResults-20250827-113000.txt
[DEBUG] TESTING FLOW: 🔄 Switching to Claude Code CLI window  
[DEBUG] TESTING FLOW: ⌨️ Submitting results via TypeKeys
[DEBUG] TESTING FLOW: ✅ Testing workflow completed successfully
```

#### Decision Making Debug Output
```
[DEBUG] 🧠 DECISION ENGINE: Analyzing response for prompt patterns
[DEBUG] 🎯 DECISION ENGINE: Found Testing pattern with 95% confidence
[DEBUG] ⚖️ DECISION ENGINE: Safety validation passed - proceeding with execution
[DEBUG] 📊 DECISION ENGINE: Final decision: EXECUTE_TEST with path extraction
```

#### Error Handling Debug Output
```
[WARNING] ⚠️ TESTING FLOW: Test path extraction failed with primary pattern
[DEBUG] 🔄 TESTING FLOW: Attempting fallback pattern matching
[ERROR] ❌ TESTING FLOW: All test path extraction methods failed
[DEBUG] 🛡️ SAFETY: Blocking potentially dangerous operation
```

## Testing Workflow Details

### Step-by-Step Testing Process

1. **JSON Detection Phase**
   ```
   [DEBUG] 📂 Monitoring directory: .\ClaudeResponses\Autonomous\
   [DEBUG] 🔍 Found new JSON file: TestResponse_20250827_113000.json
   [DEBUG] ✅ File timestamp check passed (created after orchestrator start)
   ```

2. **JSON Parsing Phase**
   ```
   [DEBUG] 📄 Parsing JSON file content
   [DEBUG] ✅ JSON structure validation passed
   [DEBUG] 🏷️ Extracted prompt_type: 'Testing'
   [DEBUG] 📝 Extracted response: 'RECOMMENDATION: Testing - C:\Tests\MyTest.ps1'
   ```

3. **Decision Making Phase**
   ```
   [DEBUG] *** TESTING FLOW TRACE *** Starting prompt-type decision logic
   [DEBUG] *** TESTING FLOW *** Processing Testing prompt-type
   [DEBUG] 🎯 Decision: EXECUTE_TEST with confidence 95%
   ```

4. **Test Path Extraction Phase**
   ```
   [DEBUG] TESTING FLOW: 🔍 Using enhanced test path extraction
   [DEBUG] TESTING FLOW: Pattern 1 - 'Testing\s*[-:]\s*([^\s]+\.ps1)' : MATCH
   [DEBUG] TESTING FLOW: ✅ Found test path: C:\Tests\MyTest.ps1
   ```

5. **Test Execution Phase**
   ```
   [DEBUG] TESTING FLOW: 🚀 Starting test execution
   [DEBUG] TESTING FLOW: 📋 Command: powershell.exe -ExecutionPolicy Bypass -File "C:\Tests\MyTest.ps1"
   [DEBUG] TESTING FLOW: ⏱️ Test execution completed in 2.5 seconds
   [DEBUG] TESTING FLOW: 📈 Exit code: 0 (Success)
   ```

6. **Results Processing Phase**
   ```
   [DEBUG] TESTING FLOW: 💾 Creating test results file
   [DEBUG] TESTING FLOW: 📄 Results file: MyTest-TestResults-20250827-113000.txt
   [DEBUG] TESTING FLOW: ✅ Results saved successfully
   ```

7. **Claude Submission Phase**
   ```
   [DEBUG] TESTING FLOW: 🔄 Switching to Claude Code CLI window
   [DEBUG] TESTING FLOW: 🎯 Found Claude window (PID: 18180)
   [DEBUG] TESTING FLOW: ⌨️ Submitting results via TypeKeys
   [DEBUG] TESTING FLOW: ✅ Submission completed successfully
   ```

### Error Recovery Patterns

The CLIOrchestrator includes robust error recovery:

```powershell
# Test path extraction with multiple fallbacks
$testPathPatterns = @(
    "Testing\s*[-:]\s*([^\s]+\.ps1)",      # Primary: "Testing - path.ps1"
    "Test\s*Path[:\s]*([^\s\n]+\.ps1)",    # Secondary: "Test Path: path.ps1" 
    "TEST\s*[-:]\s*([^\s]+\.ps1)",         # Tertiary: "TEST - path.ps1"
    "([A-Za-z0-9_-]+\.ps1)",               # Generic: "filename.ps1"
    "run.*?([A-Za-z0-9_\\/-]+\.ps1)"       # Context: "run the script.ps1"
)
```

### Signal File System

For test completion notification:
```powershell
# Create signal file when test completes
$signalFile = "TestComplete_$(Get-Date -Format 'yyyyMMdd_HHmmss').signal"
$signalData = @{
    TestPath = $testPath
    ResultsFile = $resultsFile
    ExitCode = $exitCode
    CompletedAt = Get-Date
} | ConvertTo-Json
$signalData | Out-File $signalFile -Encoding UTF8
```

## Architecture Details

### Component Structure
```
Unity-Claude-CLIOrchestrator/
├── Core/
│   ├── Components/
│   │   ├── ResponseAnalysisEngine-Core.psm1      # Response analysis
│   │   ├── PatternRecognitionEngine-Core.psm1    # Pattern matching  
│   │   ├── DecisionEngine-Core.psm1              # Decision logic
│   │   └── ActionExecutionEngine-Core.psm1       # Action execution
│   ├── OrchestrationManager.psm1                 # Main orchestration
│   ├── RecommendationPatternEngine.psm1          # Pattern definitions
│   ├── BayesianConfidenceEngine.psm1             # Confidence scoring
│   └── EntityContextEngine.psm1                  # Context analysis
├── Unity-Claude-CLIOrchestrator.psd1             # Module manifest
└── Unity-Claude-CLIOrchestrator.psm1             # Main module loader
```

### Data Flow
```
JSON File → Parser → Analysis → Decision → Execution → Results → Submission
     ↓         ↓        ↓         ↓          ↓          ↓         ↓
  Monitor   Extract  Pattern   Safety    Execute   Format   TypeKeys
            Entities  Match   Validate    Test     Output   to Claude
```

---

## End of Documentation

This comprehensive documentation covers all aspects of the Unity-Claude CLIOrchestrator system, including prompt types, workflows, troubleshooting, and implementation details. For additional support or feature requests, refer to the project repository or contact the development team.