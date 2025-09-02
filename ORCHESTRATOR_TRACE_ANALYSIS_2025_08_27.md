# CLIOrchestrator Test Execution Flow - Detailed Trace Analysis
**Date**: 2025-08-27  
**Current Time**: 22:10  
**Purpose**: Complete trace of test execution flow, result saving, and Claude submission logic

## EXECUTIVE SUMMARY
The orchestrator successfully detects and launches test scripts but has **THREE CRITICAL GAPS**:
1. **No test result capture mechanism** - Test output is lost
2. **No test completion detection** - Orchestrator doesn't know when tests finish
3. **No Claude submission logic** - Results are never sent to Claude

## 1. CURRENT EXECUTION FLOW (What Happens)

### 1.1 Test Detection Phase ✅ WORKING
```powershell
# Start-CLIOrchestrator.ps1:191-196
$jsonFiles = Get-ChildItem -Path $responseDir -Filter "*.json" -ErrorAction SilentlyContinue |
             Where-Object { 
                 -not (Test-Path "$($_.FullName).processed") -and
                 -not $processedFiles.ContainsKey($_.FullName)
             }
```
**STATUS**: Successfully finds new JSON files in `ClaudeResponses\Autonomous`

### 1.2 Test Launch Phase ✅ WORKING (but incomplete)
```powershell
# Start-CLIOrchestrator.ps1:236-241
$testProc = Start-Process powershell -ArgumentList @(
    "-NoProfile",
    "-ExecutionPolicy", "Bypass",
    "-File", $testScript
) -WindowStyle Normal -PassThru
```
**STATUS**: Launches test in new window  
**PROBLEM**: No `-RedirectStandardOutput` or `-RedirectStandardError` parameters  
**RESULT**: Test output is displayed in new window but NOT captured

### 1.3 Test Result Capture Phase ❌ MISSING
**EXPECTED**:
```powershell
# MISSING CODE - Should be after line 241
$resultsFile = ".\TestResults\$(Get-Date -Format 'yyyyMMdd_HHmmss')_$([System.IO.Path]::GetFileNameWithoutExtension($testScript)).json"

# Option 1: Redirect output during launch
$testProc = Start-Process powershell -ArgumentList @(
    "-NoProfile",
    "-ExecutionPolicy", "Bypass", 
    "-File", $testScript
) -WindowStyle Normal -PassThru `
  -RedirectStandardOutput "$resultsFile.log" `
  -RedirectStandardError "$resultsFile.error"

# Option 2: Wait for completion and capture exit code
$testProc.WaitForExit(60000)  # 60 second timeout
$testResult = @{
    Script = $testScript
    StartTime = $testProc.StartTime
    ExitTime = $testProc.ExitTime
    ExitCode = $testProc.ExitCode
    Success = $testProc.ExitCode -eq 0
}
```
**ACTUAL**: Nothing - output is lost when test window closes

### 1.4 Test Completion Detection ❌ MISSING
**EXPECTED**: Monitor for test completion signal
```powershell
# MISSING CODE - Should be in monitoring loop
# Option 1: Check if process is still running
if ($testProc -and !$testProc.HasExited) {
    Write-Host "Test still running (PID: $($testProc.Id))"
}

# Option 2: Look for completion signal files
$completionSignals = Get-ChildItem -Path $responseDir -Filter "TestComplete_*.signal"
if ($completionSignals) {
    # Test completed, process results
}
```
**ACTUAL**: Orchestrator ignores test status completely

### 1.5 Claude Submission Phase ❌ MISSING
**EXPECTED**: Submit results to Claude window
```powershell
# MISSING CODE - Should trigger after test completion
if ($testCompleted) {
    # Prepare prompt with test results
    $prompt = "Test completed: $testScript`nResults: $resultsFile`n[Review the attached test results]"
    
    # Submit to Claude window
    Submit-ToClaudeWindow -Text $prompt
}
```
**ACTUAL**: No submission logic exists in main orchestrator loop

## 2. PROBLEM AREAS - DETAILED ANALYSIS

### Problem 1: No Test Output Capture
**Location**: `Start-CLIOrchestrator.ps1:236-241`
**Issue**: `Start-Process` doesn't capture output
**Impact**: All test console output is lost
**Fix Required**:
- Add `-RedirectStandardOutput` and `-RedirectStandardError`
- OR use `Invoke-Command` with output capture
- OR modify tests to write their own result files

### Problem 2: No Process Tracking
**Location**: After `Start-CLIOrchestrator.ps1:243`  
**Issue**: `$testProc` variable is never used after launch
**Impact**: Can't tell if test is running, completed, or failed
**Fix Required**:
- Store `$testProc` in tracking hashtable
- Monitor `HasExited` property
- Check exit codes

### Problem 3: No Signal File Handling for Test Results
**Location**: `Start-CLIOrchestrator.ps1:263-275`
**Current Code**:
```powershell
if ($signalFiles) {
    foreach ($signal in $signalFiles) {
        Write-Host "  [SIGNAL] $($signal.Name)" -ForegroundColor Magenta
        $processedFiles[$signal.FullName] = $true
        Move-Item $signal.FullName "$($signal.FullName).processed" -Force
    }
}
```
**Issue**: Just marks signals as processed, doesn't act on them
**Fix Required**: Check signal type and trigger appropriate action

### Problem 4: No Claude Window Interaction
**Location**: Entire orchestrator loop
**Issue**: `Submit-ToClaudeWindow` is never called
**Impact**: Results never reach Claude
**Fix Required**:
- Import WindowManager module functions
- Add submission logic after test completion
- Handle submission failures

### Problem 5: Test Scripts Don't Write Results
**Example**: `Test-WindowsAPI-Detection.ps1`
**Issue**: Tests only write to console, not to files
**Impact**: Even if captured, results aren't structured
**Fix Required**:
- Modify test scripts to write JSON results
- OR create wrapper that captures and formats output

## 3. MISSING COMPONENTS

### 3.1 Test Result Structure
**Not Defined Anywhere**
```powershell
$testResult = @{
    TestName = "Test-WindowsAPI-Detection.ps1"
    StartTime = "2025-08-27 22:10:00"
    EndTime = "2025-08-27 22:10:05"
    Duration = "5 seconds"
    ExitCode = 0
    Success = $true
    Output = @{
        Stdout = "...",
        Stderr = "..."
    }
    Summary = "NUGGETRON detected successfully"
}
```

### 3.2 Result File Management
**Not Implemented**
- No TestResults directory creation
- No timestamp-based file naming
- No result file cleanup

### 3.3 Submission Queue
**Not Implemented**
- No queue for pending submissions
- No retry logic for failed submissions
- No tracking of what's been submitted

## 4. SIGNAL FLOW GAPS

### Current Signal Files Found:
- `TestComplete_*.signal` files exist in ClaudeResponses\Autonomous
- But orchestrator just moves them to `.processed` without reading content

### Expected Signal Processing:
```powershell
# MISSING CODE
$signalContent = Get-Content $signal.FullName -Raw | ConvertFrom-Json
switch ($signalContent.Type) {
    "TestComplete" {
        # Find associated test results
        $resultsFile = $signalContent.ResultsFile
        if (Test-Path $resultsFile) {
            $results = Get-Content $resultsFile -Raw
            Submit-ToClaudeWindow -Text "Test Results: `n$results"
        }
    }
    "SubmitPrompt" {
        Submit-ToClaudeWindow -Text $signalContent.Prompt
    }
}
```

## 5. FUNCTION AVAILABILITY ISSUES

### Functions That Exist But Aren't Used:
1. **Submit-ToClaudeWindow** (in WindowManager.psm1)
   - Location: `Modules\Unity-Claude-CLIOrchestrator\Core\WindowManager.psm1:238`
   - Status: Defined but never imported or called in orchestrator

2. **ProcessTestResults** (Not found)
   - Expected in: OrchestrationManager.psm1
   - Status: Doesn't exist

3. **Wait-TestCompletion** (Not found)
   - Status: Doesn't exist

## 6. MODULE LOADING ISSUES

### Current Module Loading (Line 149-162):
```powershell
Import-Module ".\Modules\Unity-Claude-CLIOrchestrator\Unity-Claude-CLIOrchestrator.psd1"
```
**Problem**: Module may not export Submit-ToClaudeWindow function

### Check Required:
```powershell
Get-Command -Module Unity-Claude-CLIOrchestrator | Where Name -like "*Submit*"
```

## 7. COMPLETE FIX REQUIRED

### Step 1: Capture Test Output
```powershell
# Replace lines 236-241
$outputFile = ".\TestResults\$(Get-Date -Format 'yyyyMMdd_HHmmss')_test.log"
$errorFile = ".\TestResults\$(Get-Date -Format 'yyyyMMdd_HHmmss')_test.error"

$testProc = Start-Process powershell -ArgumentList @(
    "-NoProfile",
    "-ExecutionPolicy", "Bypass",
    "-File", $testScript
) -WindowStyle Normal -PassThru `
  -RedirectStandardOutput $outputFile `
  -RedirectStandardError $errorFile

# Track the process
$script:activeTests[$testProc.Id] = @{
    Process = $testProc
    Script = $testScript
    OutputFile = $outputFile
    ErrorFile = $errorFile
    StartTime = Get-Date
}
```

### Step 2: Monitor Test Completion
```powershell
# Add to monitoring loop (after line 275)
foreach ($testId in @($script:activeTests.Keys)) {
    $test = $script:activeTests[$testId]
    if ($test.Process.HasExited) {
        Write-Host "Test completed: $($test.Script)" -ForegroundColor Green
        
        # Read results
        $output = Get-Content $test.OutputFile -Raw
        $errors = Get-Content $test.ErrorFile -Raw
        
        # Create result object
        $result = @{
            Script = $test.Script
            ExitCode = $test.Process.ExitCode
            Success = $test.Process.ExitCode -eq 0
            Output = $output
            Errors = $errors
            Duration = (Get-Date) - $test.StartTime
        }
        
        # Save results
        $resultFile = ".\TestResults\$(Get-Date -Format 'yyyyMMdd_HHmmss')_results.json"
        $result | ConvertTo-Json -Depth 10 | Out-File $resultFile
        
        # Submit to Claude
        $prompt = "Test completed: $($test.Script)`nExit Code: $($result.ExitCode)`nResults saved to: $resultFile"
        Submit-ToClaudeWindow -Text $prompt
        
        # Clean up tracking
        $script:activeTests.Remove($testId)
    }
}
```

### Step 3: Ensure Submit Function Available
```powershell
# Add at line 148 (before module import)
if (Test-Path ".\Modules\Unity-Claude-CLIOrchestrator\Core\WindowManager.psm1") {
    Import-Module ".\Modules\Unity-Claude-CLIOrchestrator\Core\WindowManager.psm1" -Force
}
```

## 8. TEST VALIDATION CHECKLIST

### Before Fix:
- [ ] Test launches in new window ✅
- [ ] Test output is captured ❌
- [ ] Test completion is detected ❌
- [ ] Results are saved to file ❌
- [ ] Results are submitted to Claude ❌

### After Fix Should Have:
- [ ] Test launches in new window
- [ ] Test output is redirected to files
- [ ] Test completion triggers result processing
- [ ] Results are saved as JSON
- [ ] Claude window receives submission
- [ ] Enter key is sent to submit

## 9. ERROR SCENARIOS TO HANDLE

1. **Test script not found** - Currently handled ✅
2. **Test hangs/timeout** - Not handled ❌
3. **Claude window lost** - Partially handled (warning only) ⚠️
4. **Submit-ToClaudeWindow fails** - Not handled ❌
5. **Results file write fails** - Not handled ❌
6. **Test crashes** - Not handled ❌

## 10. IMMEDIATE NEXT STEPS

1. **Create TestResults directory**
   ```powershell
   if (!(Test-Path ".\TestResults")) {
       New-Item -ItemType Directory -Path ".\TestResults"
   }
   ```

2. **Add process tracking hashtable**
   ```powershell
   $script:activeTests = @{}
   ```

3. **Import WindowManager functions**
   ```powershell
   Import-Module ".\Modules\Unity-Claude-CLIOrchestrator\Core\WindowManager.psm1"
   ```

4. **Implement completion detection**
   - Check process status each cycle
   - Process results when test exits
   - Submit to Claude window

## CONCLUSION

The orchestrator has a solid foundation for detecting and launching tests but completely lacks:
1. **Output capture** - Test results vanish
2. **Completion detection** - No awareness of test status  
3. **Result submission** - No connection to Claude window

These are not minor issues - they represent the entire "results and submission" phase being missing. The fix requires approximately 50-75 lines of additional code in the main orchestration loop.

---

# COMPREHENSIVE TRACE - SECOND ANALYSIS
**Time**: 22:15  
**Focus**: Complete end-to-end workflow from test execution to Claude submission

## A. DETAILED WORKFLOW BREAKDOWN

### A.1 CURRENT STATE - What Actually Happens
```
1. JSON file detected ✅
2. Test script extracted ✅ 
3. Test launched in new window ✅
4. Test runs and displays output in its window ✅
5. Test window closes ✅
6. Output is lost forever ❌
7. Orchestrator continues loop, unaware test finished ❌
8. No submission to Claude ❌
9. No Enter key pressed ❌
```

### A.2 DESIRED STATE - What Should Happen
```
1. JSON file detected ✅
2. Test script extracted ✅
3. TestResults directory created/verified 🔧
4. Test launched with output redirection 🔧
5. Test process tracked in hashtable 🔧
6. Test runs, output captured to files 🔧
7. Orchestrator detects test completion 🔧
8. Results read from output files 🔧
9. Results formatted as JSON 🔧
10. Results file saved with timestamp 🔧
11. Claude window found (NUGGETRON) 🔧
12. Window switched to foreground 🔧
13. Existing text cleared (Ctrl+A, Delete) 🔧
14. Prompt typed with results file path 🔧
15. ENTER KEY PRESSED TO SUBMIT 🔧 <-- CRITICAL MISSING STEP
16. Return focus to orchestrator 🔧
17. Mark test as completed 🔧
```

## B. CRITICAL MISSING COMPONENTS - DEEP DIVE

### B.1 NO ENTER KEY SUBMISSION ❌❌❌
**Location**: `WindowManager.psm1:238-289`
**Current Submit-ToClaudeWindow function**:
```powershell
# Line 282 - STOPS HERE!
Write-Host "  [OK] Text submitted to NUGGETRON" -ForegroundColor Green
return $true
```

**MISSING CODE**:
```powershell
# AFTER line 280, BEFORE line 282
# CRITICAL: SEND ENTER TO SUBMIT THE PROMPT!
Write-Host "  Sending ENTER to submit..." -ForegroundColor Yellow
[System.Windows.Forms.SendKeys]::SendWait("{ENTER}")
Start-Sleep -Milliseconds 500
```

**Impact**: Text is typed but NEVER submitted to Claude!

### B.2 NO OUTPUT REDIRECTION ❌
**Location**: `Start-CLIOrchestrator.ps1:236-241`
**Current Code**:
```powershell
$testProc = Start-Process powershell -ArgumentList @(
    "-NoProfile",
    "-ExecutionPolicy", "Bypass",
    "-File", $testScript
) -WindowStyle Normal -PassThru
```

**Problem**: No `-RedirectStandardOutput` or `-RedirectStandardError`
**Consequence**: Console output appears in window but isn't saved

**REQUIRED FIX**:
```powershell
# Create results directory
$resultsDir = ".\TestResults"
if (!(Test-Path $resultsDir)) {
    New-Item -ItemType Directory -Path $resultsDir -Force | Out-Null
}

# Generate unique filenames
$timestamp = Get-Date -Format 'yyyyMMdd_HHmmss'
$testName = [System.IO.Path]::GetFileNameWithoutExtension($testScript)
$outputFile = "$resultsDir\${timestamp}_${testName}_output.txt"
$errorFile = "$resultsDir\${timestamp}_${testName}_error.txt"

# Launch with redirection
$testProc = Start-Process powershell -ArgumentList @(
    "-NoProfile",
    "-ExecutionPolicy", "Bypass",
    "-File", $testScript
) -WindowStyle Normal -PassThru `
  -RedirectStandardOutput $outputFile `
  -RedirectStandardError $errorFile
```

### B.3 NO PROCESS TRACKING ❌
**Location**: After `Start-CLIOrchestrator.ps1:243`
**Current Code**: Process object `$testProc` is abandoned
**Missing**: No tracking structure

**REQUIRED INITIALIZATION** (at line 174):
```powershell
$processedFiles = @{}  # Already exists
$script:activeTests = @{}  # ADD THIS - Track running tests
```

**REQUIRED TRACKING** (after line 243):
```powershell
# Store test information
$script:activeTests[$testProc.Id] = @{
    Process = $testProc
    Script = $testScript
    OutputFile = $outputFile
    ErrorFile = $errorFile
    StartTime = Get-Date
    JsonSource = $file.Name
}
Write-Host "    [TRACKED] Test PID: $($testProc.Id)" -ForegroundColor Gray
```

### B.4 NO COMPLETION DETECTION ❌
**Location**: Should be in main loop (around line 276)
**Current**: Nothing checks if tests finished

**REQUIRED CODE** (insert after line 275):
```powershell
# Check for completed tests
if ($script:activeTests.Count -gt 0) {
    Write-Host "  Checking $($script:activeTests.Count) active test(s)..." -ForegroundColor Gray
    
    foreach ($pid in @($script:activeTests.Keys)) {
        $test = $script:activeTests[$pid]
        
        # Check if process has exited
        if ($test.Process.HasExited) {
            Write-Host "  [COMPLETED] Test finished: $($test.Script)" -ForegroundColor Green
            Write-Host "    Exit Code: $($test.Process.ExitCode)" -ForegroundColor Gray
            
            # Calculate duration
            $duration = (Get-Date) - $test.StartTime
            Write-Host "    Duration: $([math]::Round($duration.TotalSeconds, 2)) seconds" -ForegroundColor Gray
            
            # Read captured output
            $output = if (Test-Path $test.OutputFile) {
                Get-Content $test.OutputFile -Raw
            } else { "" }
            
            $errors = if (Test-Path $test.ErrorFile) {
                Get-Content $test.ErrorFile -Raw  
            } else { "" }
            
            # Create comprehensive result
            $testResult = @{
                TestScript = $test.Script
                JsonTrigger = $test.JsonSource
                ProcessId = $pid
                StartTime = $test.StartTime.ToString("yyyy-MM-dd HH:mm:ss")
                EndTime = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
                Duration = "$([math]::Round($duration.TotalSeconds, 2)) seconds"
                ExitCode = $test.Process.ExitCode
                Success = $test.Process.ExitCode -eq 0
                OutputFile = $test.OutputFile
                ErrorFile = $test.ErrorFile
                OutputPreview = if ($output.Length -gt 500) {
                    $output.Substring(0, 500) + "...[truncated]"
                } else { $output }
                ErrorPreview = if ($errors.Length -gt 500) {
                    $errors.Substring(0, 500) + "...[truncated]"
                } else { $errors }
                HasOutput = $output.Length -gt 0
                HasErrors = $errors.Length -gt 0
            }
            
            # Save complete results
            $resultsJson = "$($test.OutputFile -replace '\.txt$', '.json')"
            $testResult | ConvertTo-Json -Depth 10 | Out-File $resultsJson -Encoding UTF8
            Write-Host "    Results saved: $resultsJson" -ForegroundColor Gray
            
            # CRITICAL: Submit to Claude with ENTER
            Submit-TestResultsToClaude -TestResult $testResult -ResultsFile $resultsJson
            
            # Clean up tracking
            $script:activeTests.Remove($pid)
            $stats.Tests++
        }
    }
}
```

### B.5 NO SUBMISSION FUNCTION ❌
**Location**: Missing entirely
**Required**: New function to handle complete submission

**NEW FUNCTION REQUIRED**:
```powershell
function Submit-TestResultsToClaude {
    param(
        [hashtable]$TestResult,
        [string]$ResultsFile
    )
    
    Write-Host "  [SUBMIT] Preparing Claude submission..." -ForegroundColor Magenta
    
    # Build the prompt
    $prompt = @"
Test Execution Complete: $($TestResult.TestScript)

Exit Code: $($TestResult.ExitCode)
Duration: $($TestResult.Duration)
Success: $($TestResult.Success)

Results File: $ResultsFile

"@
    
    # Add output preview if exists
    if ($TestResult.HasOutput) {
        $prompt += "Output Preview:`n$($TestResult.OutputPreview)`n`n"
    }
    
    if ($TestResult.HasErrors) {
        $prompt += "Error Output:`n$($TestResult.ErrorPreview)`n`n"
    }
    
    $prompt += "Full results saved to: $ResultsFile"
    
    # Switch to Claude window
    Write-Host "  Finding NUGGETRON window..." -ForegroundColor Gray
    $windowInfo = Get-ClaudeWindowInfo
    if (-not $windowInfo) {
        Write-Host "  [ERROR] NUGGETRON window not found!" -ForegroundColor Red
        return $false
    }
    
    Write-Host "  Switching to NUGGETRON (PID: $($windowInfo.ProcessId))..." -ForegroundColor Gray
    if (-not (Switch-ToClaudeWindow -WindowInfo $windowInfo)) {
        Write-Host "  [ERROR] Could not switch to window!" -ForegroundColor Red
        return $false
    }
    
    # Clear and type prompt
    Write-Host "  Clearing input area..." -ForegroundColor Gray
    [System.Windows.Forms.SendKeys]::SendWait("^a")
    Start-Sleep -Milliseconds 100
    [System.Windows.Forms.SendKeys]::SendWait("{DEL}")
    Start-Sleep -Milliseconds 200
    
    Write-Host "  Typing prompt..." -ForegroundColor Gray
    # Escape special characters
    $escapedPrompt = $prompt -replace '([+^%~(){}])', '{$1}'
    $escapedPrompt = $escapedPrompt -replace '\[', '{[}'
    $escapedPrompt = $escapedPrompt -replace '\]', '{]}'
    
    # Send in chunks
    $chunkSize = 50
    for ($i = 0; $i -lt $escapedPrompt.Length; $i += $chunkSize) {
        $chunk = $escapedPrompt.Substring($i, [Math]::Min($chunkSize, $escapedPrompt.Length - $i))
        [System.Windows.Forms.SendKeys]::SendWait($chunk)
        Start-Sleep -Milliseconds 25
    }
    
    # CRITICAL: SEND ENTER TO SUBMIT!
    Write-Host "  [ENTER] Submitting to Claude!" -ForegroundColor Green
    Start-Sleep -Milliseconds 500  # Brief pause before Enter
    [System.Windows.Forms.SendKeys]::SendWait("{ENTER}")
    
    Write-Host "  [SUCCESS] Submitted to Claude!" -ForegroundColor Green
    return $true
}
```

### B.6 MISSING MODULE IMPORTS ❌
**Location**: `Start-CLIOrchestrator.ps1:147-162`
**Current**: Only imports main orchestrator module
**Missing**: WindowManager functions

**REQUIRED** (at line 147):
```powershell
# Load required modules with all functions
Write-Host "`nLoading modules..." -ForegroundColor Yellow

# Initialize for SendKeys
Add-Type -AssemblyName System.Windows.Forms

# Load WindowManager for Claude submission
if (Test-Path ".\Modules\Unity-Claude-CLIOrchestrator\Core\WindowManager.psm1") {
    Import-Module ".\Modules\Unity-Claude-CLIOrchestrator\Core\WindowManager.psm1" -Force
    Write-Host "  WindowManager loaded (NUGGETRON functions)" -ForegroundColor Green
}

# Rest of existing module loading...
```

### B.7 TESTRESULTS DIRECTORY ❌
**Location**: Directory doesn't exist
**Impact**: Output redirection will fail

**REQUIRED** (at line 169):
```powershell
# Ensure TestResults directory exists
$testResultsDir = ".\TestResults"
if (!(Test-Path $testResultsDir)) {
    New-Item -ItemType Directory -Path $testResultsDir -Force | Out-Null
    Write-Host "Created TestResults directory" -ForegroundColor Gray
}
```

## C. COMPLETE CORRECTION PLAN

### Phase 1: Initialize Environment (Lines 147-175)
```powershell
# 1. Add System.Windows.Forms for SendKeys
Add-Type -AssemblyName System.Windows.Forms

# 2. Import WindowManager module
Import-Module ".\Modules\Unity-Claude-CLIOrchestrator\Core\WindowManager.psm1"

# 3. Create TestResults directory
if (!(Test-Path ".\TestResults")) {
    New-Item -ItemType Directory -Path ".\TestResults" -Force
}

# 4. Initialize tracking hashtable
$script:activeTests = @{}
```

### Phase 2: Fix Test Launch (Lines 236-245)
```powershell
# Generate result file paths
$timestamp = Get-Date -Format 'yyyyMMdd_HHmmss'
$testName = [System.IO.Path]::GetFileNameWithoutExtension($testScript)
$outputFile = ".\TestResults\${timestamp}_${testName}_output.txt"
$errorFile = ".\TestResults\${timestamp}_${testName}_error.txt"

# Launch with output capture
$testProc = Start-Process powershell -ArgumentList @(
    "-NoProfile",
    "-ExecutionPolicy", "Bypass",
    "-File", $testScript
) -WindowStyle Normal -PassThru `
  -RedirectStandardOutput $outputFile `
  -RedirectStandardError $errorFile

# Track the test
$script:activeTests[$testProc.Id] = @{
    Process = $testProc
    Script = $testScript
    OutputFile = $outputFile
    ErrorFile = $errorFile
    StartTime = Get-Date
    JsonSource = $file.Name
}
```

### Phase 3: Add Completion Detection (After line 275)
```powershell
# Check for completed tests
foreach ($pid in @($script:activeTests.Keys)) {
    $test = $script:activeTests[$pid]
    if ($test.Process.HasExited) {
        # Process results
        # Submit to Claude WITH ENTER
        # Clean up
    }
}
```

### Phase 4: Fix WindowManager.psm1 (Line 280)
```powershell
# Add ENTER submission
Write-Host "  Sending ENTER to submit..." -ForegroundColor Yellow
[System.Windows.Forms.SendKeys]::SendWait("{ENTER}")
Start-Sleep -Milliseconds 500
```

## D. VALIDATION CHECKLIST

### Current State:
- [x] JSON detection works
- [x] Test launches
- [ ] Output captured to files
- [ ] Completion detected
- [ ] Results saved as JSON
- [ ] Claude window found
- [ ] Text typed in window
- [ ] **ENTER pressed to submit**
- [ ] Focus returned

### After Fix:
- [x] JSON detection works
- [x] Test launches
- [x] Output captured to files
- [x] Completion detected  
- [x] Results saved as JSON
- [x] Claude window found
- [x] Text typed in window
- [x] **ENTER pressed to submit**
- [x] Focus returned

## E. EDGE CASES TO HANDLE

1. **Test never completes** - Add timeout (e.g., 5 minutes)
2. **Claude window closed during test** - Detect and warn
3. **Multiple tests running** - Track all in hashtable
4. **SendKeys fails** - Try-catch with retry
5. **Output files locked** - Wait and retry
6. **NUGGETRON process dies** - Re-register window

## F. FINAL CRITICAL POINTS

### THE MOST CRITICAL MISSING PIECE:
**NO ENTER KEY SUBMISSION** - Without this, nothing gets to Claude!

### Order of Operations:
1. Capture output ← Currently missing
2. Detect completion ← Currently missing
3. Save results ← Currently missing
4. Find Claude window ← Partially works
5. Type prompt ← Partially works
6. **PRESS ENTER** ← **COMPLETELY MISSING**

### Estimated Fix Size:
- ~150 lines of new code
- 3 new functions
- 5 modified sections
- 1 new directory (TestResults)

## SUMMARY

The orchestrator is **80% broken** for the complete workflow. It successfully launches tests but then:
- Loses all output
- Never detects completion
- Never submits to Claude
- **Never presses Enter**

This is not a minor bug - it's a fundamental incompleteness of the submission pipeline.