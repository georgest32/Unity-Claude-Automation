# CLIOrchestrator Debugging Analysis
**Date:** 2025-08-27  
**Time:** 11:30:00  
**Problem:** CLIOrchestrator not properly handling Testing prompt-type  
**Context:** End-to-end orchestration flow failure  
**Previous Topics:** CLIOrchestrator fixes, JSON parsing, window management  

## Home State Analysis

### Current Project Structure
- **Root:** C:\UnityProjects\Sound-and-Shoal\Unity-Claude-Automation
- **Module Location:** Modules\Unity-Claude-CLIOrchestrator
- **Response Directory:** ClaudeResponses\Autonomous
- **Configuration:** PowerShell 7, Windows platform

### Software Versions
- PowerShell: 7.x (minimum required)
- .NET Framework: Required for System.Windows.Forms
- Unity: Not directly involved in orchestration

## Objectives and Benchmarks

### Short-term Goals
1. Get Testing prompt-type working end-to-end
2. Enable proper test execution and result capture
3. Fix window switching and TypeKeys submission
4. Add comprehensive debug logging

### Long-term Goals
1. Support all prompt types (Testing, Debugging, ARP, Continue, Review)
2. Fully autonomous operation with decision making
3. Comprehensive error recovery and retry logic
4. Performance optimization and scalability

### Current Implementation Status
- **Phase 7:** CLI Orchestration implementation (IN PROGRESS)
- **Status:** Basic monitoring works, but prompt-type handling broken
- **Blockers:** JSON parsing, test execution, window switching

## Error Analysis

### Flow Tracing Results
1. **JSON Detection:** Working - finds new JSON files
2. **JSON Parsing:** Partially working - reads RESPONSE field but not prompt_type
3. **Decision Making:** Limited - only pattern matching, no prompt_type awareness
4. **Test Execution:** NOT IMPLEMENTED - no code to run tests
5. **Result Capture:** NOT IMPLEMENTED - no test result handling
6. **Window Switching:** Partially working - finds window but submission fails
7. **TypeKeys Submission:** Limited - only sends RECOMMENDATION text

### Root Causes
1. **Missing prompt_type parsing** - Code only looks at RESPONSE field
2. **No test execution logic** - EXECUTE decision is only simulated
3. **No result capture** - No code to capture test output
4. **Incomplete submission** - Doesn't build proper prompt with boilerplate

## Research Findings

### PowerShell Test Execution
- Use Start-Process or Invoke-Expression to run test scripts
- Capture output with -RedirectStandardOutput and -RedirectStandardError
- Wait for completion with -Wait parameter
- Parse exit codes for success/failure

### Window Management
- Use [System.Windows.Forms.SendKeys] for reliable typing
- Add delays between window activation and typing
- Verify window focus before sending keys
- Use clipboard as fallback for large text

### JSON Parsing Best Practices
- Always check for null/missing fields
- Use -ErrorAction SilentlyContinue for safe parsing
- Validate structure before processing
- Log all parsing steps for debugging

## Implementation Plan

### Phase 1: Enhanced JSON Parsing (Hour 1)
1. Add prompt_type field parsing
2. Add response field parsing (for full recommendation)
3. Add validation for required fields
4. Add comprehensive debug logging

### Phase 2: Test Execution Logic (Hour 2-3)
1. Detect Testing prompt-type
2. Parse test file path from response/details
3. Execute test with output capture
4. Wait for completion and get exit code
5. Save results to timestamped file

### Phase 3: Window Switching & Submission (Hour 4-5)
1. Build complete prompt with boilerplate
2. Add prompt-type specific formatting
3. Enhance window switching with retries
4. Add clipboard fallback for large prompts
5. Verify submission success

### Phase 4: Error Handling (Hour 6)
1. Add try-catch blocks throughout
2. Implement retry logic for failures
3. Add detailed error logging
4. Create fallback mechanisms

### Phase 5: Documentation & Testing (Hour 7-8)
1. Create CLIOrchestrator documentation
2. Document all prompt types
3. Create test cases
4. Validate end-to-end flow

## Critical Learnings

### PowerShell Module Loading
- Use Import-Module with -Force -Global for component visibility
- Export functions explicitly with Export-ModuleMember
- Avoid circular dependencies between modules

### JSON Response Structure
- Always include timestamp, prompt_type, and response fields
- Use standardized format for recommendations
- Include details field for prompt-type specific data

### Window Automation
- Add delays between operations for stability
- Verify window state before operations
- Use multiple methods (SendKeys, clipboard) for reliability

## Solution Summary

The CLIOrchestrator needs comprehensive enhancements to properly handle Testing prompt-type:
1. Parse prompt_type from JSON and route to appropriate handler
2. Implement test execution with output capture
3. Build proper prompts with boilerplate and submit to Claude
4. Add extensive debug logging throughout the flow
5. Create documentation for all supported prompt types

The solution involves modifying OrchestrationManager.psm1 to add prompt-type aware processing, implementing test execution logic, and enhancing the window submission functionality.