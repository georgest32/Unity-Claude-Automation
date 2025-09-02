# CLI Orchestrator Critical Learnings - 2025-08-27

## Learning #227: Testing Prompt-Type Full Implementation
**Date:** 2025-08-27  
**Category:** CLIOrchestrator  
**Impact:** Critical for test automation  

### Discovery
The CLIOrchestrator was not properly handling Testing prompt-type. It only performed pattern matching on the RESPONSE field and didn't execute tests or capture results.

### Root Cause
- Missing prompt_type field parsing from JSON
- No test execution implementation
- No result capture mechanism
- Incomplete Claude submission logic

### Solution
```powershell
# Enhanced decision making with prompt-type awareness
if ($content.prompt_type) {
    switch ($content.prompt_type) {
        "Testing" {
            $decisionResult.Decision = "EXECUTE_TEST"
            # Extract test path and execute
        }
    }
}

# Test execution with result capture
$testOutput = & powershell.exe -ExecutionPolicy Bypass -File $testPath 2>&1
$testResultContent | Out-File -FilePath $resultFile -Encoding UTF8
```

### Key Takeaways
- Always parse and use prompt_type field for decision routing
- Implement complete execution flow for each prompt type
- Capture both stdout and stderr for test results
- Save results before submitting to Claude

---

## Learning #228: JSON Response Field Parsing Strategy
**Date:** 2025-08-27  
**Category:** JSON Processing  
**Impact:** High for compatibility  

### Discovery
JSON responses have inconsistent field naming (response vs RESPONSE) and may include various metadata fields.

### Solution
```powershell
# Flexible field parsing
$responseText = if ($content.response) { $content.response } 
                elseif ($content.RESPONSE) { $content.RESPONSE } 
                else { $null }

# Always check prompt_type first
if ($content.prompt_type) {
    # Route based on prompt_type
}
```

### Key Takeaways
- Support both lowercase and uppercase field names
- Check for prompt_type to determine routing logic
- Fall back to pattern matching if prompt_type missing
- Validate all fields before processing

---

## Learning #229: Test Execution and Result Capture Pattern
**Date:** 2025-08-27  
**Category:** Test Automation  
**Impact:** Critical for testing workflow  

### Discovery
Tests need proper execution with output capture, result storage, and Claude submission.

### Implementation Pattern
```powershell
# 1. Generate timestamped result file
$timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
$resultFile = ".\{0}-TestResults-{1}.txt" -f $testName, $timestamp

# 2. Execute with output capture
$testOutput = & powershell.exe -ExecutionPolicy Bypass -File $testPath 2>&1
$exitCode = $LASTEXITCODE

# 3. Format and save results
$testResultContent = @"
Test Execution Report
====================
Test Script: $testPath
Execution Time: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
Exit Code: $exitCode

Test Output:
============
$($testOutput -join "`n")
"@
$testResultContent | Out-File -FilePath $resultFile -Encoding UTF8

# 4. Submit to Claude with boilerplate
$promptText = "$boilerplate`n`n***END OF BOILERPLATE***`n`nPrompt-type: Testing`nTest Results File: $resultFile"
Submit-ToClaudeViaTypeKeys -PromptText $promptText
```

### Key Takeaways
- Always capture exit codes for success/failure determination
- Use timestamped filenames to avoid conflicts
- Include all metadata in result files
- Build complete prompts with boilerplate for Claude submission

---

## Learning #230: Debug Logging Best Practices
**Date:** 2025-08-27  
**Category:** Debugging  
**Impact:** High for troubleshooting  

### Pattern
```powershell
Write-Host "[DEBUG] Component: Action details" -ForegroundColor DarkGray
Write-Host "[DEBUG] ERROR: Error message" -ForegroundColor Red
Write-Host "[DEBUG] SUCCESS: Success message" -ForegroundColor Green
Write-Host "[DEBUG] WARNING: Warning message" -ForegroundColor Yellow
```

### Log Points
1. Entry to major functions
2. JSON parsing results
3. Decision outcomes
4. Execution start/end
5. Error conditions
6. Success confirmations

### Key Takeaways
- Use consistent [DEBUG] prefix for filtering
- Color code by severity
- Include component/function context
- Log both successes and failures
- Add timing information for performance analysis

---

## Learning #231: Window Management and TypeKeys Submission
**Date:** 2025-08-27  
**Category:** UI Automation  
**Impact:** High for Claude interaction  

### Challenges
- Window focus can be lost during operations
- Large prompts may exceed SendKeys limits
- Timing issues between operations

### Solutions
```powershell
# Add delays for stability
Start-Sleep -Milliseconds 500

# Use clipboard for large text
Set-Clipboard -Value $promptText
[System.Windows.Forms.SendKeys]::SendWait("^v")

# Verify window before typing
$window = Find-ClaudeWindow
if ($window) {
    # Proceed with submission
}
```

### Key Takeaways
- Always verify window state before operations
- Add delays between window operations
- Use clipboard for prompts over 1000 characters
- Implement retry logic for failed submissions
- Consider multiple submission methods as fallbacks