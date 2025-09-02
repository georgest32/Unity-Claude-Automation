# Test-PermissionHandling.ps1
# Comprehensive test suite for Claude CLI permission handling system

param(
    [string]$TestType = "All",  # All, Patterns, Integration, RealTime
    [switch]$Verbose
)

Write-Host "=" * 80 -ForegroundColor Cyan
Write-Host "CLAUDE PERMISSION HANDLING TEST SUITE" -ForegroundColor Green
Write-Host "=" * 80 -ForegroundColor Cyan

# Import required modules
Write-Host "`nLoading modules..." -ForegroundColor Gray
try {
    Import-Module ".\Modules\Unity-Claude-CLIOrchestrator\Core\PermissionHandler.psm1" -Force
    Import-Module ".\Modules\Unity-Claude-CLIOrchestrator\Core\SafeOperationsHandler.psm1" -Force
    Import-Module ".\Modules\Unity-Claude-CLIOrchestrator\Core\ClaudePermissionInterceptor.psm1" -Force
    Write-Host "✅ All modules loaded successfully" -ForegroundColor Green
} catch {
    Write-Host "❌ Failed to load modules: $_" -ForegroundColor Red
    exit 1
}

#region Test Functions

function Test-PermissionPatterns {
    Write-Host "`n" + ("=" * 60) -ForegroundColor Blue
    Write-Host "TEST: Permission Pattern Detection" -ForegroundColor Blue
    Write-Host ("=" * 60) -ForegroundColor Blue
    
    # Run built-in pattern test
    $testResult = Test-ClaudePermissionDetection
    
    Write-Host "`nPattern Detection Results:" -ForegroundColor Yellow
    Write-Host "  Success Rate: $($testResult.SuccessRate)%" -ForegroundColor White
    Write-Host "  Detected: $($testResult.Detected)/$($testResult.TotalTests)" -ForegroundColor White
    
    return $testResult.SuccessRate -ge 85  # Pass if 85% or better
}

function Test-PermissionRules {
    Write-Host "`n" + ("=" * 60) -ForegroundColor Blue
    Write-Host "TEST: Permission Rule Engine" -ForegroundColor Blue
    Write-Host ("=" * 60) -ForegroundColor Blue
    
    # Initialize handler
    Initialize-PermissionHandler -Mode "Intelligent"
    
    # Test cases
    $testCases = @(
        @{
            Text = "Allow Bash to read config.json? (y/n)"
            ExpectedDecision = "approve"
            Reason = "Read operations should be approved"
        },
        @{
            Text = "Allow Remove-Item to delete System32? (y/n)"
            ExpectedDecision = "deny"
            Reason = "System file deletions should be denied"
        },
        @{
            Text = "Execute command: git status? (y/n)"
            ExpectedDecision = "approve"
            Reason = "Safe git operations should be approved"
        },
        @{
            Text = "Allow Write to modify Unity-Claude-Automation/test.txt? (y/n)"
            ExpectedDecision = "approve"
            Reason = "Project file writes should be approved"
        }
    )
    
    $passed = 0
    $total = $testCases.Count
    
    foreach ($test in $testCases) {
        Write-Host "`nTesting: $($test.Text)" -ForegroundColor Gray
        
        # Create mock prompt info
        $promptInfo = @{
            IsPermissionPrompt = $true
            Type = "ToolPermission"
            OriginalText = $test.Text
            CapturedData = @{}
        }
        
        # Get decision
        $decision = Get-PermissionDecision -PromptInfo $promptInfo
        
        Write-Host "  Expected: $($test.ExpectedDecision)" -ForegroundColor Yellow
        Write-Host "  Actual: $($decision.Action)" -ForegroundColor Yellow
        Write-Host "  Reason: $($decision.Reason)" -ForegroundColor Cyan
        
        if ($decision.Action -eq $test.ExpectedDecision) {
            Write-Host "  ✅ PASS" -ForegroundColor Green
            $passed++
        } else {
            Write-Host "  ❌ FAIL" -ForegroundColor Red
        }
    }
    
    Write-Host "`nRule Engine Results:" -ForegroundColor Yellow
    Write-Host "  Passed: $passed/$total" -ForegroundColor White
    Write-Host "  Success Rate: $([math]::Round(($passed/$total)*100, 2))%" -ForegroundColor White
    
    return $passed -eq $total
}

function Test-SafeOperations {
    Write-Host "`n" + ("=" * 60) -ForegroundColor Blue
    Write-Host "TEST: Safe Operations System" -ForegroundColor Blue
    Write-Host ("=" * 60) -ForegroundColor Blue
    
    # Initialize safe operations
    Initialize-SafeOperations -GitAutoCommit:$false
    
    $passed = 0
    $total = 0
    
    # Test destructive command conversion
    $testCommands = @(
        "Remove-Item test.txt",
        "rm -rf temp/",
        "git reset --hard",
        "Clear-Content config.json"
    )
    
    foreach ($cmd in $testCommands) {
        $total++
        Write-Host "`nTesting: $cmd" -ForegroundColor Gray
        
        $result = Convert-ToSafeOperation -Command $cmd
        
        if ($result.WasConverted) {
            Write-Host "  ✅ CONVERTED: $($result.SafeCommand)" -ForegroundColor Green
            Write-Host "  Explanation: $($result.Explanation)" -ForegroundColor Cyan
            $passed++
        } else {
            Write-Host "  ❌ NOT CONVERTED" -ForegroundColor Red
        }
    }
    
    Write-Host "`nSafe Operations Results:" -ForegroundColor Yellow
    Write-Host "  Converted: $passed/$total" -ForegroundColor White
    Write-Host "  Success Rate: $([math]::Round(($passed/$total)*100, 2))%" -ForegroundColor White
    
    return $passed -eq $total
}

function Test-Integration {
    Write-Host "`n" + ("=" * 60) -ForegroundColor Blue
    Write-Host "TEST: Module Integration" -ForegroundColor Blue
    Write-Host ("=" * 60) -ForegroundColor Blue
    
    $tests = @()
    
    # Test permission handler initialization
    try {
        $result = Initialize-PermissionHandler -Mode "Intelligent"
        if ($result.Success) {
            Write-Host "✅ PermissionHandler initialization" -ForegroundColor Green
            $tests += $true
        } else {
            Write-Host "❌ PermissionHandler initialization failed" -ForegroundColor Red
            $tests += $false
        }
    } catch {
        Write-Host "❌ PermissionHandler initialization error: $_" -ForegroundColor Red
        $tests += $false
    }
    
    # Test safe operations initialization
    try {
        $result = Initialize-SafeOperations
        if ($result.Success) {
            Write-Host "✅ SafeOperations initialization" -ForegroundColor Green
            $tests += $true
        } else {
            Write-Host "❌ SafeOperations initialization failed" -ForegroundColor Red
            $tests += $false
        }
    } catch {
        Write-Host "❌ SafeOperations initialization error: $_" -ForegroundColor Red
        $tests += $false
    }
    
    # Test statistics functions
    try {
        $stats = Get-PermissionStatistics
        if ($stats) {
            Write-Host "✅ Permission statistics retrieval" -ForegroundColor Green
            $tests += $true
        } else {
            Write-Host "❌ Permission statistics failed" -ForegroundColor Red
            $tests += $false
        }
    } catch {
        Write-Host "❌ Permission statistics error: $_" -ForegroundColor Red
        $tests += $false
    }
    
    # Test interceptor functions
    try {
        $testResult = Test-ClaudePermissionDetection
        if ($testResult.SuccessRate -gt 0) {
            Write-Host "✅ Interceptor pattern detection" -ForegroundColor Green
            $tests += $true
        } else {
            Write-Host "❌ Interceptor pattern detection failed" -ForegroundColor Red
            $tests += $false
        }
    } catch {
        Write-Host "❌ Interceptor test error: $_" -ForegroundColor Red
        $tests += $false
    }
    
    $passed = ($tests | Where-Object { $_ }).Count
    $total = $tests.Count
    
    Write-Host "`nIntegration Test Results:" -ForegroundColor Yellow
    Write-Host "  Passed: $passed/$total" -ForegroundColor White
    Write-Host "  Success Rate: $([math]::Round(($passed/$total)*100, 2))%" -ForegroundColor White
    
    return $passed -eq $total
}

function Test-RealTimeSimulation {
    Write-Host "`n" + ("=" * 60) -ForegroundColor Blue
    Write-Host "TEST: Real-Time Simulation" -ForegroundColor Blue
    Write-Host ("=" * 60) -ForegroundColor Blue
    
    Write-Host "Starting permission interceptor..." -ForegroundColor Gray
    
    # Initialize components
    $permissionHandler = @{
        Mode = "Intelligent"
    }
    
    try {
        Initialize-PermissionHandler -Mode "Intelligent"
        
        # Simulate permission detection and response
        Write-Host "`nSimulating permission prompts..." -ForegroundColor Gray
        
        $simulatedPrompts = @(
            "Allow Bash to read package.json? (y/n)",
            "Execute command: npm test? (y/n)",
            "Apply edit to README.md? (y/n)"
        )
        
        $responses = @()
        
        foreach ($prompt in $simulatedPrompts) {
            Write-Host "  Simulating: $prompt" -ForegroundColor Cyan
            
            # Test the detection
            $promptInfo = Test-ClaudePermissionPrompt -Text $prompt
            
            if ($promptInfo.IsPermissionPrompt) {
                $decision = Get-PermissionDecision -PromptInfo $promptInfo
                $response = if ($decision.Action -eq "approve") { "y" } else { "n" }
                
                Write-Host "    Decision: $($decision.Action) -> $response" -ForegroundColor Yellow
                Write-Host "    Reason: $($decision.Reason)" -ForegroundColor Gray
                
                $responses += @{
                    Prompt = $prompt
                    Decision = $decision.Action
                    Response = $response
                    Success = $true
                }
            } else {
                Write-Host "    ❌ Not detected as permission prompt" -ForegroundColor Red
                $responses += @{
                    Prompt = $prompt
                    Success = $false
                }
            }
        }
        
        $successful = ($responses | Where-Object { $_.Success }).Count
        $total = $responses.Count
        
        Write-Host "`nReal-Time Simulation Results:" -ForegroundColor Yellow
        Write-Host "  Successful: $successful/$total" -ForegroundColor White
        Write-Host "  Success Rate: $([math]::Round(($successful/$total)*100, 2))%" -ForegroundColor White
        
        return $successful -eq $total
        
    } catch {
        Write-Host "❌ Real-time simulation failed: $_" -ForegroundColor Red
        return $false
    }
}

#endregion

#region Main Test Execution

$testResults = @{}

switch ($TestType) {
    "All" {
        $testResults.Patterns = Test-PermissionPatterns
        $testResults.Rules = Test-PermissionRules
        $testResults.SafeOps = Test-SafeOperations
        $testResults.Integration = Test-Integration
        $testResults.RealTime = Test-RealTimeSimulation
    }
    "Patterns" {
        $testResults.Patterns = Test-PermissionPatterns
    }
    "Integration" {
        $testResults.Integration = Test-Integration
    }
    "RealTime" {
        $testResults.RealTime = Test-RealTimeSimulation
    }
}

# Summary
Write-Host "`n" + ("=" * 80) -ForegroundColor Cyan
Write-Host "TEST SUMMARY" -ForegroundColor Green
Write-Host ("=" * 80) -ForegroundColor Cyan

$totalTests = $testResults.Keys.Count
$passedTests = ($testResults.Values | Where-Object { $_ }).Count

foreach ($test in $testResults.Keys) {
    $status = if ($testResults[$test]) { "✅ PASS" } else { "❌ FAIL" }
    $color = if ($testResults[$test]) { "Green" } else { "Red" }
    Write-Host "  $test`: $status" -ForegroundColor $color
}

Write-Host "`nOverall Results:" -ForegroundColor Yellow
Write-Host "  Passed: $passedTests/$totalTests" -ForegroundColor White
Write-Host "  Success Rate: $([math]::Round(($passedTests/$totalTests)*100, 2))%" -ForegroundColor White

if ($passedTests -eq $totalTests) {
    Write-Host "`n🎉 ALL TESTS PASSED!" -ForegroundColor Green
    Write-Host "Permission handling system is ready for use." -ForegroundColor Green
} else {
    Write-Host "`n⚠️ Some tests failed. Review the results above." -ForegroundColor Yellow
}

# Create test report
$report = @{
    Timestamp = Get-Date
    TestType = $TestType
    Results = $testResults
    Summary = @{
        Total = $totalTests
        Passed = $passedTests
        SuccessRate = ($passedTests/$totalTests)*100
        OverallPass = $passedTests -eq $totalTests
    }
}

$reportPath = ".\TestResults\PermissionHandling_TestResults_$(Get-Date -Format 'yyyyMMdd_HHmmss').json"
$reportDir = Split-Path $reportPath -Parent
if (-not (Test-Path $reportDir)) {
    New-Item -Path $reportDir -ItemType Directory -Force | Out-Null
}

$report | ConvertTo-Json -Depth 10 | Out-File -Path $reportPath -Encoding UTF8

Write-Host "`n📄 Test report saved: $reportPath" -ForegroundColor Cyan

#endregion