<#
.SYNOPSIS
    Default CLIOrchestrator - NUGGETRON Mode with proper duplicate prevention
#>

[CmdletBinding()]
param(
    [int]$MaxExecutionTimeMinutes = 60,
    [int]$MonitorIntervalSeconds = 5
)

$ErrorActionPreference = 'Continue'

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "CLI ORCHESTRATOR - NUGGETRON DEFAULT" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

# Add Windows API type definitions
if (-not ([System.Management.Automation.PSTypeName]'WindowHelper').Type) {
    Add-Type @"
using System;
using System.Text;
using System.Runtime.InteropServices;
using System.Collections.Generic;

public class WindowHelper {
    [DllImport("user32.dll")]
    public static extern bool EnumWindows(EnumWindowsProc lpEnumFunc, IntPtr lParam);
    
    [DllImport("user32.dll", CharSet = CharSet.Auto)]
    public static extern int GetWindowText(IntPtr hWnd, StringBuilder lpString, int nMaxCount);
    
    [DllImport("user32.dll")]
    public static extern int GetWindowTextLength(IntPtr hWnd);
    
    [DllImport("user32.dll")]
    public static extern uint GetWindowThreadProcessId(IntPtr hWnd, out uint lpdwProcessId);
    
    [DllImport("user32.dll")]
    public static extern bool IsWindowVisible(IntPtr hWnd);
    
    public delegate bool EnumWindowsProc(IntPtr hWnd, IntPtr lParam);
    
    public static List<WindowInfo> GetAllWindows() {
        List<WindowInfo> windows = new List<WindowInfo>();
        
        EnumWindows(delegate(IntPtr hWnd, IntPtr lParam) {
            if (IsWindowVisible(hWnd)) {
                int length = GetWindowTextLength(hWnd);
                if (length > 0) {
                    StringBuilder sb = new StringBuilder(length + 1);
                    GetWindowText(hWnd, sb, sb.Capacity);
                    
                    uint processId;
                    GetWindowThreadProcessId(hWnd, out processId);
                    
                    windows.Add(new WindowInfo {
                        Handle = hWnd,
                        Title = sb.ToString(),
                        ProcessId = (int)processId
                    });
                }
            }
            return true;
        }, IntPtr.Zero);
        
        return windows;
    }
}

public class WindowInfo {
    public IntPtr Handle { get; set; }
    public string Title { get; set; }
    public int ProcessId { get; set; }
}
"@
}

# Create override function for NUGGETRON detection using Windows API
function Global:Find-ClaudeWindow {
    Write-Host "  Using Windows API to find NUGGETRON..." -ForegroundColor Cyan
    
    # Get all windows using Windows API
    $allWindows = [WindowHelper]::GetAllWindows()
    
    # Find NUGGETRON
    $nuggetronWindow = $allWindows | Where-Object { $_.Title -like "*NUGGETRON*" } | Select-Object -First 1
    
    if ($nuggetronWindow) {
        Write-Host "    [OK] Found NUGGETRON via Windows API!" -ForegroundColor Green
        Write-Host "    ProcessId: $($nuggetronWindow.ProcessId)" -ForegroundColor Gray
        
        # Verify process exists
        $proc = Get-Process -Id $nuggetronWindow.ProcessId -ErrorAction SilentlyContinue
        if ($proc) {
            return @{
                ProcessId = $nuggetronWindow.ProcessId
                WindowHandle = [int64]$nuggetronWindow.Handle
                WindowTitle = $nuggetronWindow.Title
                ProcessName = $proc.ProcessName
            }
        }
    }
    
    # Fallback to protected registration
    $protectedRegPath = ".\.nuggetron_registration.json"
    if (Test-Path $protectedRegPath) {
        $reg = Get-Content $protectedRegPath -Raw | ConvertFrom-Json
        if ($reg.ProcessId) {
            $proc = Get-Process -Id $reg.ProcessId -ErrorAction SilentlyContinue
            if ($proc) {
                Write-Host "    [WARNING] Using registration fallback" -ForegroundColor Yellow
                return @{
                    ProcessId = $reg.ProcessId
                    WindowHandle = [int64]$reg.WindowHandle
                    WindowTitle = $reg.WindowTitle
                    ProcessName = $reg.ProcessName
                }
            }
        }
    }
    
    # Not found - show available windows
    Write-Host "    [ERROR] NUGGETRON not found!" -ForegroundColor Red
    Write-Host "    Available windows (first 10):" -ForegroundColor Yellow
    $allWindows | Select-Object -First 10 | ForEach-Object {
        if ($_.Title) {
            Write-Host "      - PID $($_.ProcessId): '$($_.Title)'" -ForegroundColor Gray
        }
    }
    
    return $null
}

# Check for NUGGETRON before starting
Write-Host "`nChecking for NUGGETRON window..." -ForegroundColor Yellow
$window = Find-ClaudeWindow
if (-not $window) {
    Write-Host "`n[ERROR] Cannot start without NUGGETRON!" -ForegroundColor Red
    Write-Host "Please run in your Claude terminal:" -ForegroundColor Yellow
    Write-Host "  .\Register-NUGGETRON-Protected.ps1" -ForegroundColor Cyan
    exit 1
}

Write-Host "[OK] NUGGETRON ready!" -ForegroundColor Green

# Load required modules
Write-Host "`nLoading modules..." -ForegroundColor Yellow

# Initialize for SendKeys
Add-Type -AssemblyName System.Windows.Forms

# Load WindowManager for Claude submission
if (Test-Path ".\Modules\Unity-Claude-CLIOrchestrator\Core\WindowManager.psm1") {
    Import-Module ".\Modules\Unity-Claude-CLIOrchestrator\Core\WindowManager.psm1" -Force
    Write-Host "  WindowManager loaded (NUGGETRON functions)" -ForegroundColor Green
}

try {
    # Load the CLIOrchestrator module (includes window management)
    Import-Module ".\Modules\Unity-Claude-CLIOrchestrator\Unity-Claude-CLIOrchestrator.psd1" -Force -ErrorAction Stop
    Write-Host "  CLIOrchestrator module loaded" -ForegroundColor Green
    
    # Optional: Load SystemStatus for monitoring
    if (Test-Path ".\Modules\Unity-Claude-SystemStatus\Unity-Claude-SystemStatus.psd1") {
        Import-Module ".\Modules\Unity-Claude-SystemStatus\Unity-Claude-SystemStatus.psd1" -Force -ErrorAction SilentlyContinue
        Write-Host "  SystemStatus module loaded" -ForegroundColor Green
    }
} catch {
    Write-Host "[ERROR] Failed to load modules: $_" -ForegroundColor Red
    Write-Host "Continuing without full module support..." -ForegroundColor Yellow
}

Write-Host "`nStarting orchestration loop..." -ForegroundColor Cyan
Write-Host "Configuration:" -ForegroundColor Gray
Write-Host "  - Max time: $MaxExecutionTimeMinutes minutes" -ForegroundColor Gray
Write-Host "  - Interval: $MonitorIntervalSeconds seconds" -ForegroundColor Gray
Write-Host "  - Target: **NUGGETRON**" -ForegroundColor Magenta

# Initialize tracking
$startTime = Get-Date
$endTime = $startTime.AddMinutes($MaxExecutionTimeMinutes)
$responseDir = ".\ClaudeResponses\Autonomous"
$processedFiles = @{}  # Track processed files in memory
$script:activeTests = @{}  # Track running tests

# Ensure TestResults directory exists
$testResultsDir = ".\TestResults"
if (!(Test-Path $testResultsDir)) {
    New-Item -ItemType Directory -Path $testResultsDir -Force | Out-Null
    Write-Host "Created TestResults directory" -ForegroundColor Gray
}
$cycleCount = 0
$stats = @{
    Responses = 0
    Decisions = 0
    Actions = 0
    Tests = 0
}

# Function to submit test results to Claude using proper boilerplate format
function Submit-TestResultsToClaude {
    param(
        [hashtable]$TestResult,
        [string]$ResultsFile
    )
    
    Write-Host "  [SUBMIT] Preparing boilerplate Claude submission..." -ForegroundColor Magenta
    
    # CRITICAL FIX: Load the enhanced functions directly since they're not in module exports
    $boilerplateFunction = ".\Modules\Unity-Claude-CLIOrchestrator\Public\PromptSubmissionEngine\New-BoilerplatePrompt.ps1"
    $submissionFunction = ".\Modules\Unity-Claude-CLIOrchestrator\Public\PromptSubmissionEngine\Submit-ToClaudeViaTypeKeys.ps1"
    
    try {
        # Force load the enhanced functions every time to ensure availability
        if (Test-Path $boilerplateFunction) {
            . $boilerplateFunction
            Write-Host "    [LOADED] Boilerplate function from: $boilerplateFunction" -ForegroundColor Green
        } else {
            Write-Host "    [ERROR] Boilerplate function not found: $boilerplateFunction" -ForegroundColor Red
        }
        
        if (Test-Path $submissionFunction) {
            . $submissionFunction  
            Write-Host "    [LOADED] Enhanced submission function from: $submissionFunction" -ForegroundColor Green
        } else {
            Write-Host "    [ERROR] Enhanced submission function not found: $submissionFunction" -ForegroundColor Red
        }
        
        # Build proper details for boilerplate
        $details = "Please analyze the console output and results from running the test $($TestResult.TestScript) in file $ResultsFile"
        
        # Add context about the test results
        if ($TestResult.Success) {
            $details += ". The test completed successfully"
        } else {
            $details += ". The test failed"
        }
        
        if ($TestResult.HasErrors) {
            $details += " with errors that need attention"
        }
        
        # Use enhanced boilerplate submission - functions should be loaded above
        if (Get-Command New-BoilerplatePrompt -ErrorAction SilentlyContinue) {
            Write-Host "    [OK] New-BoilerplatePrompt function available" -ForegroundColor Green
            Write-Host "    Building proper boilerplate prompt..." -ForegroundColor Cyan
            
            # Create the complete boilerplate prompt
            $completePrompt = New-BoilerplatePrompt -PromptType "Testing" -Details $details -FilePaths @($ResultsFile)
            Write-Host "    Boilerplate prompt built: $($completePrompt.Length) characters" -ForegroundColor Gray
            
            # Now check for the submission function
            if (Get-Command Submit-ToClaudeViaTypeKeys -ErrorAction SilentlyContinue) {
                Write-Host "    [OK] Submit-ToClaudeViaTypeKeys function available" -ForegroundColor Green
                Write-Host "    Using enhanced clipboard-based submission..." -ForegroundColor Cyan
                
                # Use the enhanced submission with clipboard paste
                $submitted = Submit-ToClaudeViaTypeKeys -PromptText $completePrompt
                
                if ($submitted) {
                    Write-Host "  [SUCCESS] Boilerplate prompt submitted via clipboard!" -ForegroundColor Green
                    Write-Host "  Format: [BOILERPLATE] Testing: [details] Files: [paths]" -ForegroundColor Gray
                } else {
                    Write-Host "  [ERROR] Enhanced submission failed" -ForegroundColor Red
                }
                return  # Exit here to prevent fallback execution
            } else {
                Write-Host "    [WARN] Submit-ToClaudeViaTypeKeys not available" -ForegroundColor Yellow
            }
        } else {
            Write-Host "    [WARN] New-BoilerplatePrompt not available after loading attempt" -ForegroundColor Yellow
        }
        
        # Fallback: Use old method but warn user
        Write-Host "    [FALLBACK] Using old submission method (not recommended)" -ForegroundColor Yellow
        
        # Build the prompt as a single line to avoid accidental submission
        $prompt = "Test Execution Complete: $($TestResult.TestScript) | "
        $prompt += "Exit Code: $($TestResult.ExitCode) | "
        $prompt += "Duration: $($TestResult.Duration) | "
        $prompt += "Success: $($TestResult.Success) | "
        $prompt += "Results File: $ResultsFile"
        
        # Add output preview if exists (on same line)
        if ($TestResult.HasOutput) {
            $outputSummary = $TestResult.OutputPreview -replace "`n", " " -replace "`r", ""
            if ($outputSummary.Length -gt 200) {
                $outputSummary = $outputSummary.Substring(0, 200) + "..."
            }
            $prompt += " | Output: $outputSummary"
        }
        
        if ($TestResult.HasErrors) {
            $errorSummary = $TestResult.ErrorPreview -replace "`n", " " -replace "`r", ""
            if ($errorSummary.Length -gt 100) {
                $errorSummary = $errorSummary.Substring(0, 100) + "..."
            }
            $prompt += " | Errors: $errorSummary"
        }
        
        # Use the old WindowManager function as fallback
        if (Get-Command Submit-ToClaudeWindow -ErrorAction SilentlyContinue) {
            $submitted = Submit-ToClaudeWindow -Text $prompt
            if ($submitted) {
                Write-Host "  [SUCCESS] Results submitted to Claude (old format)!" -ForegroundColor Yellow
            } else {
                Write-Host "  [ERROR] Failed to submit to Claude" -ForegroundColor Red
            }
        } else {
            Write-Host "  [WARN] No submission method available" -ForegroundColor Red
            Write-Host "  Manual submission required for: $ResultsFile" -ForegroundColor Yellow
            Write-Host "  Expected format: '[BOILERPLATE] Testing: $details'" -ForegroundColor Gray
        }
        
    } catch {
        Write-Host "  [ERROR] Submission error: $_" -ForegroundColor Red
        Write-Host "  Manual submission required for: $ResultsFile" -ForegroundColor Yellow
    }
}

# Main orchestration loop
while ((Get-Date) -lt $endTime) {
    $cycleCount++
    $runtime = [math]::Round(((Get-Date) - $startTime).TotalSeconds)
    
    Write-Host "`n--- Cycle $cycleCount ---" -ForegroundColor Cyan
    Write-Host "Runtime: $('{0:mm\:ss}' -f ([timespan]::FromSeconds($runtime)))" -ForegroundColor Gray
    
    # Look for new JSON files
    $jsonFiles = Get-ChildItem -Path $responseDir -Filter "*.json" -ErrorAction SilentlyContinue |
                 Where-Object { 
                     # Check if not already processed
                     -not (Test-Path "$($_.FullName).processed") -and
                     -not $processedFiles.ContainsKey($_.FullName)
                 }
    
    if ($jsonFiles) {
        Write-Host "Found $($jsonFiles.Count) new JSON file(s)" -ForegroundColor Yellow
        
        foreach ($file in $jsonFiles) {
            Write-Host "  Processing: $($file.Name)" -ForegroundColor Gray
            
            # Mark as processed IMMEDIATELY to prevent re-processing
            $processedFiles[$file.FullName] = $true
            $processedMarker = "$($file.FullName).processed"
            "Processed at $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" | 
                Set-Content $processedMarker -Force
            
            try {
                $content = Get-Content $file.FullName -Raw | ConvertFrom-Json
                $stats.Responses++
                
                # Check if it's a test request
                if ($content.prompt_type -eq 'Testing' -and 
                    ($content.RESPONSE -match 'TEST' -or $content.action -eq 'EXECUTE_TEST')) {
                    
                    Write-Host "    [TEST] Test execution requested" -ForegroundColor Green
                    $stats.Decisions++
                    
                    # Extract test script path
                    $testScript = $null
                    if ($content.details) { 
                        $testScript = $content.details 
                    } elseif ($content.test_script) {
                        $testScript = $content.test_script
                    } elseif ($content.RESPONSE -match '([^\\/:*?"<>|\s]+\.ps1)') {
                        $testScript = $matches[1]
                    }
                    
                    if ($testScript) {
                        Write-Host "    Executing: $testScript" -ForegroundColor Cyan
                        
                        if (Test-Path $testScript) {
                            # Generate unique result file paths
                            $timestamp = Get-Date -Format 'yyyyMMdd_HHmmss'
                            $testName = [System.IO.Path]::GetFileNameWithoutExtension($testScript)
                            $outputFile = ".\TestResults\${timestamp}_${testName}_output.txt"
                            $errorFile = ".\TestResults\${timestamp}_${testName}_error.txt"
                            
                            Write-Host "    Output: $outputFile" -ForegroundColor Gray
                            
                            # Launch test with output redirection and proper context inheritance
                            Write-Host "    [DEBUG] Current working directory: $(Get-Location)" -ForegroundColor Gray
                            Write-Host "    [DEBUG] Python path: $env:PATH" -ForegroundColor Gray
                            Write-Host "    [DEBUG] PSModulePath: $env:PSModulePath" -ForegroundColor Gray
                            
                            $testProc = Start-Process powershell -ArgumentList @(
                                "-NoProfile",
                                "-ExecutionPolicy", "Bypass",
                                "-File", $testScript
                            ) -WindowStyle Normal -PassThru `
                              -WorkingDirectory (Get-Location) `
                              -RedirectStandardOutput $outputFile `
                              -RedirectStandardError $errorFile
                            
                            # Track the test process
                            $script:activeTests[$testProc.Id] = @{
                                Process = $testProc
                                Script = $testScript
                                OutputFile = $outputFile
                                ErrorFile = $errorFile
                                StartTime = Get-Date
                                JsonSource = $file.Name
                            }
                            
                            Write-Host "    [OK] Test launched (PID: $($testProc.Id))" -ForegroundColor Green
                            Write-Host "    [TRACKED] Monitoring for completion..." -ForegroundColor Gray
                            $stats.Actions++
                            $stats.Tests++
                        } else {
                            Write-Host "    [ERROR] Test script not found: $testScript" -ForegroundColor Red
                        }
                    } else {
                        Write-Host "    [WARN] Could not extract test script path" -ForegroundColor Yellow
                    }
                }
                # Check if it's a Continue request
                elseif ($content.prompt_type -eq 'Continue' -and 
                        ($content.RESPONSE -match 'CONTINUE' -or $content.action -eq 'CONTINUE')) {
                    
                    Write-Host "    [CONTINUE] Continue implementation requested" -ForegroundColor Cyan
                    $stats.Decisions++
                    
                    # Extract implementation plan path and current step
                    $implementationPlan = $null
                    $currentStep = $null
                    
                    if ($content.reference_document) {
                        $implementationPlan = $content.reference_document
                    } elseif ($content.implementation_plan) {
                        $implementationPlan = $content.implementation_plan
                    }
                    
                    if ($content.current_step) {
                        $currentStep = $content.current_step
                    } elseif ($content.next_step) {
                        $currentStep = $content.next_step
                    }
                    
                    Write-Host "    [CONTINUE] Submitting continuation prompt to Claude..." -ForegroundColor Green
                    
                    # Load boilerplate functions
                    $boilerplateFunction = ".\Modules\Unity-Claude-CLIOrchestrator\Public\PromptSubmissionEngine\New-BoilerplatePrompt.ps1"
                    $submissionFunction = ".\Modules\Unity-Claude-CLIOrchestrator\Public\PromptSubmissionEngine\Submit-ToClaudeViaTypeKeys.ps1"
                    
                    if (Test-Path $boilerplateFunction) {
                        . $boilerplateFunction
                        Write-Host "    [LOADED] Boilerplate function" -ForegroundColor Gray
                    }
                    
                    if (Test-Path $submissionFunction) {
                        . $submissionFunction
                        Write-Host "    [LOADED] Submission function" -ForegroundColor Gray
                    }
                    
                    # Build the Continue prompt
                    $continueDetails = "Please proceed with the implementation plan set out in $implementationPlan"
                    
                    if ($currentStep) {
                        $continueDetails += ": $currentStep"
                    } else {
                        $continueDetails += ". Review the implementation plan and current codebase to determine which step is next"
                    }
                    
                    # Create and submit the boilerplate prompt
                    if (Get-Command New-BoilerplatePrompt -ErrorAction SilentlyContinue) {
                        $completePrompt = New-BoilerplatePrompt -PromptType "Continue" -Details $continueDetails -FilePaths @($implementationPlan)
                        Write-Host "    Boilerplate prompt built: $($completePrompt.Length) characters" -ForegroundColor Gray
                        
                        if (Get-Command Submit-ToClaudeViaTypeKeys -ErrorAction SilentlyContinue) {
                            $submitted = Submit-ToClaudeViaTypeKeys -PromptText $completePrompt
                            
                            if ($submitted) {
                                Write-Host "  [SUCCESS] Continue prompt submitted!" -ForegroundColor Green
                                Write-Host "  Format: [BOILERPLATE] Continue: [implementation details]" -ForegroundColor Gray
                                $stats.Actions++
                            } else {
                                Write-Host "  [ERROR] Failed to submit Continue prompt" -ForegroundColor Red
                            }
                        } else {
                            Write-Host "  [ERROR] Submit function not available" -ForegroundColor Red
                        }
                    } else {
                        Write-Host "  [ERROR] Boilerplate function not available" -ForegroundColor Red
                    }
                }
            }
            catch {
                Write-Host "    [ERROR] Failed to process: $_" -ForegroundColor Red
            }
        }
    } else {
        Write-Host "No new files to process" -ForegroundColor Gray
    }
    
    # Check for signal files
    $signalFiles = Get-ChildItem -Path $responseDir -Filter "*.signal" -ErrorAction SilentlyContinue |
                   Where-Object { 
                       -not (Test-Path "$($_.FullName).processed") -and
                       -not $processedFiles.ContainsKey($_.FullName)
                   }
    
    if ($signalFiles) {
        foreach ($signal in $signalFiles) {
            Write-Host "  [SIGNAL] $($signal.Name)" -ForegroundColor Magenta
            $processedFiles[$signal.FullName] = $true
            Move-Item $signal.FullName "$($signal.FullName).processed" -Force
        }
    }
    
    # Check for completed tests
    if ($script:activeTests.Count -gt 0) {
        Write-Host "  Checking $($script:activeTests.Count) active test(s)..." -ForegroundColor Gray
        
        foreach ($processId in @($script:activeTests.Keys)) {
            $test = $script:activeTests[$processId]
            
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
                    ProcessId = $processId
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
                $script:activeTests.Remove($processId)
                $stats.Tests++
            }
        }
    }
    
    Write-Host "Stats: R:$($stats.Responses) D:$($stats.Decisions) A:$($stats.Actions) T:$($stats.Tests)" -ForegroundColor Gray
    
    # Periodic NUGGETRON check
    if ($cycleCount % 12 -eq 0) {
        $window = Find-ClaudeWindow
        if (-not $window) {
            Write-Host "[WARN] NUGGETRON window lost!" -ForegroundColor Yellow
        }
    }
    
    Start-Sleep -Seconds $MonitorIntervalSeconds
}

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "Orchestration completed" -ForegroundColor Cyan
Write-Host "Total runtime: $MaxExecutionTimeMinutes minutes" -ForegroundColor Gray
Write-Host "Final stats:" -ForegroundColor Gray
Write-Host "  - Responses: $($stats.Responses)" -ForegroundColor Gray
Write-Host "  - Decisions: $($stats.Decisions)" -ForegroundColor Gray  
Write-Host "  - Actions: $($stats.Actions)" -ForegroundColor Gray
Write-Host "  - Tests: $($stats.Tests)" -ForegroundColor Gray
Write-Host "========================================" -ForegroundColor Cyan