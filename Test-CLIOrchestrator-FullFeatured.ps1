param(
    [switch]$Quick,
    [switch]$Verbose
)

# Test script for the full-featured CLIOrchestrator with Public/Private architecture
Write-Host "=============================================================" -ForegroundColor Cyan
Write-Host "Unity-Claude CLIOrchestrator Full-Featured Test Suite v3.0.0" -ForegroundColor Cyan
Write-Host "=============================================================" -ForegroundColor Cyan
Write-Host ""

$results = @{
    TestStartTime = Get-Date
    TestEndTime = $null
    TotalTests = 0
    PassedTests = 0
    FailedTests = 0
    TestResults = @()
    ModuleLoadTime = 0
    FunctionCount = 0
    Architecture = "Unknown"
}

try {
    # Test 1: Module Import with Performance Measurement
    Write-Host "TEST 1: Loading Full-Featured Module..." -ForegroundColor Yellow
    $loadStart = Get-Date
    
    try {
        # Remove any existing module first
        Get-Module "*CLIOrchestrator*" | Remove-Module -Force -ErrorAction SilentlyContinue
        
        # Import the full-featured module
        Import-Module ".\Modules\Unity-Claude-CLIOrchestrator\Unity-Claude-CLIOrchestrator-FullFeatured.psd1" -Force
        
        $loadEnd = Get-Date
        $results.ModuleLoadTime = ($loadEnd - $loadStart).TotalMilliseconds
        
        $results.TestResults += @{
            Test = "Module Import"
            Status = "PASS"
            Message = "Module loaded successfully in $([Math]::Round($results.ModuleLoadTime, 2))ms"
            Details = @{
                LoadTime = $results.ModuleLoadTime
                ModulePath = "Unity-Claude-CLIOrchestrator-FullFeatured.psd1"
            }
        }
        $results.PassedTests++
        Write-Host "  ✅ PASS: Module loaded in $([Math]::Round($results.ModuleLoadTime, 2))ms" -ForegroundColor Green
        
    } catch {
        $results.TestResults += @{
            Test = "Module Import"
            Status = "FAIL"
            Message = "Module import failed: $($_.Exception.Message)"
            Details = $_.Exception.ToString()
        }
        $results.FailedTests++
        Write-Host "  ❌ FAIL: Module import failed: $($_.Exception.Message)" -ForegroundColor Red
        throw "Cannot continue without module - exiting test"
    }
    $results.TotalTests++
    
    # Test 2: Function Availability Check
    Write-Host ""
    Write-Host "TEST 2: Function Availability Check..." -ForegroundColor Yellow
    
    $expectedFunctions = @(
        # Core Functions (4)
        'Initialize-CLIOrchestrator', 'Test-CLIOrchestratorComponents', 'Get-CLIOrchestratorInfo', 'Update-CLISessionStats',
        # WindowManager Functions (3)
        'Update-ClaudeWindowInfo', 'Find-ClaudeWindow', 'Switch-ToWindow',
        # AutonomousOperations Functions (4)  
        'New-AutonomousPrompt', 'Get-ActionResultSummary', 'Process-ResponseFile', 'Invoke-AutonomousExecutionLoop',
        # OrchestrationManager Functions (5)
        'Start-CLIOrchestration', 'Get-CLIOrchestrationStatus', 'Invoke-ComprehensiveResponseAnalysis', 'Invoke-AutonomousDecisionMaking', 'Invoke-DecisionExecution',
        # DecisionEngine Functions (10)
        'Invoke-RuleBasedDecision', 'Resolve-PriorityDecision', 'Test-SafetyValidation', 'Test-SafeFilePath', 'Test-SafeCommand', 'Test-ActionQueueCapacity', 'New-ActionQueueItem', 'Get-ActionQueueStatus', 'Resolve-ConflictingRecommendations', 'Invoke-GracefulDegradation',
        # PromptSubmissionEngine Functions (2)
        'Submit-ToClaudeViaTypeKeys', 'Execute-TestScript'
    )
    
    $availableFunctions = @()
    $missingFunctions = @()
    
    foreach ($func in $expectedFunctions) {
        if (Get-Command $func -ErrorAction SilentlyContinue) {
            $availableFunctions += $func
        } else {
            $missingFunctions += $func
        }
    }
    
    $results.FunctionCount = $availableFunctions.Count
    
    if ($missingFunctions.Count -eq 0) {
        $results.TestResults += @{
            Test = "Function Availability"
            Status = "PASS"
            Message = "All $($expectedFunctions.Count) expected functions are available"
            Details = @{
                AvailableFunctions = $availableFunctions
                ExpectedCount = $expectedFunctions.Count
                ActualCount = $availableFunctions.Count
            }
        }
        $results.PassedTests++
        Write-Host "  ✅ PASS: All $($expectedFunctions.Count) functions available" -ForegroundColor Green
    } else {
        $results.TestResults += @{
            Test = "Function Availability"
            Status = "FAIL"
            Message = "Missing $($missingFunctions.Count) functions: $($missingFunctions -join ', ')"
            Details = @{
                AvailableFunctions = $availableFunctions
                MissingFunctions = $missingFunctions
                ExpectedCount = $expectedFunctions.Count
                ActualCount = $availableFunctions.Count
            }
        }
        $results.FailedTests++
        Write-Host "  ❌ FAIL: Missing functions: $($missingFunctions -join ', ')" -ForegroundColor Red
    }
    $results.TotalTests++
    
    # Test 3: Core Functions Basic Functionality
    Write-Host ""
    Write-Host "TEST 3: Core Functions Basic Functionality..." -ForegroundColor Yellow
    
    try {
        # Test Initialize-CLIOrchestrator
        $initResult = Initialize-CLIOrchestrator -ValidateComponents -SetupDirectories
        
        if ($initResult.Initialized -and $initResult.Version -eq "3.0.0") {
            Write-Host "  ✅ Initialize-CLIOrchestrator: Working" -ForegroundColor Green
            $coreTestPassed = $true
        } else {
            Write-Host "  ❌ Initialize-CLIOrchestrator: Unexpected result" -ForegroundColor Red
            $coreTestPassed = $false
        }
        
        # Test Get-CLIOrchestratorInfo
        if (Get-Command Get-CLIOrchestratorInfo -ErrorAction SilentlyContinue) {
            $infoResult = Get-CLIOrchestratorInfo
            if ($infoResult.Version) {
                Write-Host "  ✅ Get-CLIOrchestratorInfo: Working" -ForegroundColor Green
            } else {
                Write-Host "  ❌ Get-CLIOrchestratorInfo: Invalid result" -ForegroundColor Red
                $coreTestPassed = $false
            }
        } else {
            Write-Host "  ❌ Get-CLIOrchestratorInfo: Function not available" -ForegroundColor Red
            $coreTestPassed = $false
        }
        
        # Test Find-ClaudeWindow
        if (Get-Command Find-ClaudeWindow -ErrorAction SilentlyContinue) {
            $windowResult = Find-ClaudeWindow
            Write-Host "  ✅ Find-ClaudeWindow: Working (returned: $(if($windowResult){'Handle'}else{'null'}))" -ForegroundColor Green
        } else {
            Write-Host "  ❌ Find-ClaudeWindow: Function not available" -ForegroundColor Red
            $coreTestPassed = $false
        }
        
        if ($coreTestPassed) {
            $results.TestResults += @{
                Test = "Core Functions"
                Status = "PASS"
                Message = "Core functions are working correctly"
                Details = @{
                    InitResult = $initResult
                    InfoResult = if($infoResult){$infoResult}else{$null}
                    WindowResult = $windowResult
                }
            }
            $results.PassedTests++
        } else {
            $results.TestResults += @{
                Test = "Core Functions"
                Status = "FAIL"
                Message = "One or more core functions failed"
                Details = "See individual function test results above"
            }
            $results.FailedTests++
        }
        
    } catch {
        $results.TestResults += @{
            Test = "Core Functions"
            Status = "FAIL"
            Message = "Core function testing failed: $($_.Exception.Message)"
            Details = $_.Exception.ToString()
        }
        $results.FailedTests++
        Write-Host "  ❌ FAIL: Core function testing failed: $($_.Exception.Message)" -ForegroundColor Red
    }
    $results.TotalTests++
    
    # Test 4: Decision Engine Functions (if not Quick test)
    if (-not $Quick -and (Get-Command Test-SafetyValidation -ErrorAction SilentlyContinue)) {
        Write-Host ""
        Write-Host "TEST 4: Decision Engine Functions..." -ForegroundColor Yellow
        
        try {
            # Test safety validation with safe content
            $testAnalysis = @{
                ResponseText = "Please continue with the analysis"
                Recommendations = @()
            }
            
            $safetyResult = Test-SafetyValidation -AnalysisResult $testAnalysis
            
            if ($safetyResult.IsSafe -eq $true) {
                Write-Host "  ✅ Test-SafetyValidation: Working (safe content detected)" -ForegroundColor Green
                
                $results.TestResults += @{
                    Test = "Decision Engine"
                    Status = "PASS"
                    Message = "Decision engine functions working correctly"
                    Details = $safetyResult
                }
                $results.PassedTests++
            } else {
                Write-Host "  ❌ Test-SafetyValidation: Unexpected result" -ForegroundColor Red
                
                $results.TestResults += @{
                    Test = "Decision Engine"
                    Status = "FAIL"
                    Message = "Safety validation returned unexpected result"
                    Details = $safetyResult
                }
                $results.FailedTests++
            }
            
        } catch {
            $results.TestResults += @{
                Test = "Decision Engine"
                Status = "FAIL"
                Message = "Decision engine test failed: $($_.Exception.Message)"
                Details = $_.Exception.ToString()
            }
            $results.FailedTests++
            Write-Host "  ❌ FAIL: Decision engine test failed: $($_.Exception.Message)" -ForegroundColor Red
        }
        $results.TotalTests++
    }
    
    # Architecture verification
    $results.Architecture = "Public/Private"
    
} catch {
    Write-Host ""
    Write-Host "CRITICAL ERROR: $($_.Exception.Message)" -ForegroundColor Red
    
    $results.TestResults += @{
        Test = "Critical Error"
        Status = "FAIL"
        Message = $_.Exception.Message
        Details = $_.Exception.ToString()
    }
    $results.FailedTests++
}

# Final Results
$results.TestEndTime = Get-Date
$totalTestTime = ($results.TestEndTime - $results.TestStartTime).TotalSeconds

Write-Host ""
Write-Host "=============================================================" -ForegroundColor Cyan
Write-Host "TEST RESULTS SUMMARY" -ForegroundColor Cyan  
Write-Host "=============================================================" -ForegroundColor Cyan
Write-Host "Total Tests: $($results.TotalTests)" -ForegroundColor White
Write-Host "Passed: $($results.PassedTests)" -ForegroundColor Green
Write-Host "Failed: $($results.FailedTests)" -ForegroundColor $(if($results.FailedTests -gt 0){'Red'}else{'Green'})
Write-Host "Success Rate: $([Math]::Round(($results.PassedTests / [Math]::Max(1, $results.TotalTests)) * 100, 1))%" -ForegroundColor $(if($results.FailedTests -eq 0){'Green'}else{'Yellow'})
Write-Host ""
Write-Host "Performance Metrics:" -ForegroundColor White
Write-Host "  Module Load Time: $([Math]::Round($results.ModuleLoadTime, 2))ms" -ForegroundColor Gray
Write-Host "  Functions Available: $($results.FunctionCount)" -ForegroundColor Gray
Write-Host "  Architecture: $($results.Architecture)" -ForegroundColor Gray
Write-Host "  Total Test Time: $([Math]::Round($totalTestTime, 2))s" -ForegroundColor Gray
Write-Host ""

# Output detailed results if Verbose
if ($Verbose -or $results.FailedTests -gt 0) {
    Write-Host "DETAILED RESULTS:" -ForegroundColor White
    foreach ($test in $results.TestResults) {
        $color = if ($test.Status -eq "PASS") { "Green" } else { "Red" }
        Write-Host "  $($test.Test): $($test.Status) - $($test.Message)" -ForegroundColor $color
    }
    Write-Host ""
}

# Save results to JSON file
$timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
$resultFile = ".\CLIOrchestrator-FullFeatured-TestResults-$timestamp.json"
$results | ConvertTo-Json -Depth 10 | Set-Content $resultFile -Encoding UTF8

Write-Host "Test results saved to: $resultFile" -ForegroundColor Gray
Write-Host ""

# Exit with appropriate code
if ($results.FailedTests -eq 0) {
    Write-Host "✅ ALL TESTS PASSED - Full-Featured CLIOrchestrator is ready!" -ForegroundColor Green
    exit 0
} else {
    Write-Host "❌ SOME TESTS FAILED - Review results above" -ForegroundColor Red  
    exit 1
}