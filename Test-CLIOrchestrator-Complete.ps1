# Test-CLIOrchestrator-Complete.ps1
# Comprehensive test suite for Phase 7 CLIOrchestrator implementation
# Tests all components: ResponseAnalysis, PatternRecognition, DecisionEngine, ActionExecution
# Date: 2025-08-25

param(
    [Parameter(Mandatory=$false)]
    [ValidateSet("All", "Unit", "Integration", "Performance", "Safety")]
    [string]$TestType = "All",
    
    [Parameter(Mandatory=$false)]
    [switch]$SaveResults,
    
    [Parameter(Mandatory=$false)]
    [switch]$VerboseOutput
)

# Set up error handling and logging
$ErrorActionPreference = 'Continue'
$WarningPreference = 'Continue'
if ($VerboseOutput) { $VerbosePreference = 'Continue' }

# Initialize test results
$testResults = @{
    TestSuite = "CLIOrchestrator-Complete"
    StartTime = Get-Date
    TestType = $TestType
    Results = @()
    Summary = @{
        Total = 0
        Passed = 0
        Failed = 0
        Skipped = 0
        Errors = 0
    }
}

Write-Host "================================================================" -ForegroundColor Cyan
Write-Host "  Unity-Claude CLIOrchestrator Comprehensive Test Suite" -ForegroundColor Cyan
Write-Host "  Test Type: $TestType" -ForegroundColor Cyan
Write-Host "  Started: $($testResults.StartTime.ToString('yyyy-MM-dd HH:mm:ss'))" -ForegroundColor Cyan
Write-Host "================================================================" -ForegroundColor Cyan

function Write-TestLog {
    param($Message, $Level = "INFO")
    $timestamp = Get-Date -Format "HH:mm:ss.fff"
    $color = switch ($Level) {
        "ERROR" { "Red" }
        "WARNING" { "Yellow" }
        "SUCCESS" { "Green" }
        "INFO" { "White" }
        default { "White" }
    }
    Write-Host "[$timestamp] [$Level] $Message" -ForegroundColor $color
}

function Add-TestResult {
    param($Name, $Status, $Duration, $Details = "", $Error = "")
    $testResults.Results += @{
        Name = $Name
        Status = $Status
        Duration = $Duration
        Details = $Details
        Error = $Error
        Timestamp = Get-Date
    }
    $testResults.Summary.Total++
    $testResults.Summary.$Status++
}

# Test 1: Module Import and Validation
function Test-ModuleImport {
    Write-TestLog "Testing module import and basic validation..." -Level "INFO"
    $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
    
    try {
        # Clean any existing modules
        Get-Module Unity-Claude-CLIOrchestrator | Remove-Module -Force -ErrorAction SilentlyContinue
        
        # Import the main module
        Import-Module ".\Modules\Unity-Claude-CLIOrchestrator\Unity-Claude-CLIOrchestrator.psd1" -Force -ErrorAction Stop
        
        # Verify main module is loaded with nested modules
        $mainModule = Get-Module Unity-Claude-CLIOrchestrator -ErrorAction SilentlyContinue
        if (-not $mainModule) {
            throw "Main CLIOrchestrator module not loaded"
        }
        
        # Check that nested modules are accessible through function availability
        $testFunction = Get-Command Extract-ResponseEntities -ErrorAction SilentlyContinue
        if (-not $testFunction) {
            throw "Nested modules not properly imported - functions not available"
        }
        
        # Test core function availability
        $coreFunctions = @(
            'Invoke-EnhancedResponseAnalysis',
            'Extract-ResponseEntities',
            'Analyze-ResponseSentiment',
            'Find-RecommendationPatterns',
            'Invoke-RuleBasedDecision', 
            'Test-SafetyValidation',
            'Invoke-SafeAction'
        )
        
        foreach ($function in $coreFunctions) {
            $cmd = Get-Command $function -ErrorAction SilentlyContinue
            if (-not $cmd) {
                throw "Core function not available: $function"
            }
        }
        
        $stopwatch.Stop()
        Add-TestResult -Name "Module Import and Validation" -Status "Passed" -Duration $stopwatch.ElapsedMilliseconds -Details "All core modules and functions loaded successfully"
        Write-TestLog "Module import test PASSED ($($stopwatch.ElapsedMilliseconds)ms)" -Level "SUCCESS"
        
    } catch {
        $stopwatch.Stop()
        Add-TestResult -Name "Module Import and Validation" -Status "Failed" -Duration $stopwatch.ElapsedMilliseconds -Error $_.Exception.Message
        Write-TestLog "Module import test FAILED: $($_.Exception.Message)" -Level "ERROR"
    }
}

# Test 2: Response Analysis Engine
function Test-ResponseAnalysisEngine {
    Write-TestLog "Testing Response Analysis Engine..." -Level "INFO"
    $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
    
    try {
        # Test entity extraction
        $testResponse = @"
I need you to run Test-SemanticAnalysis.ps1 to validate the implementation. 
The file is located at C:\UnityProjects\Sound-and-Shoal\Unity-Claude-Automation\Test-SemanticAnalysis.ps1.
There was an error CS0234 in the build process. Please check the Unity logs at C:\Users\georg\AppData\Local\Unity\Editor\Editor.log.
You should also verify the MonoBehaviour components and GameObject references.
RECOMMENDATION: TEST - Test-SemanticAnalysis.ps1: Run the semantic analysis validation test
"@

        # Test entity extraction
        $entities = Extract-ResponseEntities -ResponseText $testResponse
        if (-not $entities -or $entities.TotalMatches -eq 0) {
            throw "Entity extraction returned no results"
        }
        
        # Verify specific entity types were found
        if ($entities.FilePaths.Count -eq 0) {
            throw "No file paths extracted from test response"
        }
        if ($entities.Commands.Count -eq 0) {
            throw "No commands extracted from test response"
        }
        
        # Test sentiment analysis
        $sentiment = Analyze-ResponseSentiment -ResponseText $testResponse
        if (-not $sentiment -or -not $sentiment.DominantSentiment) {
            throw "Sentiment analysis failed to return results"
        }
        
        # Test context extraction
        $context = Get-ResponseContext -ResponseText $testResponse
        if (-not $context -or -not $context.RelevanceScore) {
            throw "Context extraction failed"
        }
        
        $stopwatch.Stop()
        $details = "Entities: $($entities.TotalMatches), Sentiment: $($sentiment.DominantSentiment) ($($sentiment.OverallConfidence)), Relevance: $($context.RelevanceScore)"
        Add-TestResult -Name "Response Analysis Engine" -Status "Passed" -Duration $stopwatch.ElapsedMilliseconds -Details $details
        Write-TestLog "Response Analysis Engine test PASSED ($($stopwatch.ElapsedMilliseconds)ms)" -Level "SUCCESS"
        
    } catch {
        $stopwatch.Stop()
        Add-TestResult -Name "Response Analysis Engine" -Status "Failed" -Duration $stopwatch.ElapsedMilliseconds -Error $_.Exception.Message
        Write-TestLog "Response Analysis Engine test FAILED: $($_.Exception.Message)" -Level "ERROR"
    }
}

# Test 3: Pattern Recognition Engine  
function Test-PatternRecognitionEngine {
    Write-TestLog "Testing Pattern Recognition Engine..." -Level "INFO"
    $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
    
    try {
        $testResponse = "RECOMMENDATION: TEST - Test-SemanticAnalysis.ps1: Run the comprehensive validation test to ensure all components work correctly"
        
        # Test recommendation pattern finding
        $patterns = Find-RecommendationPatterns -ResponseText $testResponse
        if (-not $patterns -or $patterns.Count -eq 0) {
            throw "No recommendation patterns found in test response"
        }
        
        # Verify TEST pattern was found
        $testPattern = $patterns | Where-Object { $_.Type -eq "TEST" }
        if (-not $testPattern) {
            throw "TEST recommendation pattern not detected"
        }
        
        if (-not $testPattern.FilePath -or $testPattern.FilePath -notlike "*Test-SemanticAnalysis.ps1*") {
            throw "TEST pattern file path not correctly extracted"
        }
        
        # Test response type classification
        $classification = Classify-ResponseType -ResponseContent $testResponse
        if (-not $classification -or -not $classification.Type) {
            throw "Response type classification failed or returned no type"
        }
        
        $stopwatch.Stop()
        $details = "Patterns found: $($patterns.Count), Classification: $($classification.Type) ($($classification.Confidence))"
        Add-TestResult -Name "Pattern Recognition Engine" -Status "Passed" -Duration $stopwatch.ElapsedMilliseconds -Details $details
        Write-TestLog "Pattern Recognition Engine test PASSED ($($stopwatch.ElapsedMilliseconds)ms)" -Level "SUCCESS"
        
    } catch {
        $stopwatch.Stop()
        Add-TestResult -Name "Pattern Recognition Engine" -Status "Failed" -Duration $stopwatch.ElapsedMilliseconds -Error $_.Exception.Message
        Write-TestLog "Pattern Recognition Engine test FAILED: $($_.Exception.Message)" -Level "ERROR"
    }
}

# Test 4: Decision Engine
function Test-DecisionEngine {
    Write-TestLog "Testing Decision Engine..." -Level "INFO"
    $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
    
    try {
        # Create test analysis result
        $testAnalysisResult = @{
            Recommendations = @(
                @{
                    Type = "TEST"
                    Action = "Run validation test"
                    FilePath = "Test-SemanticAnalysis.ps1"
                    Confidence = 0.95
                    Priority = 1
                }
            )
            ConfidenceAnalysis = @{
                OverallConfidence = 0.90
                QualityRating = "High"
            }
            Entities = @{
                FilePaths = @("Test-SemanticAnalysis.ps1")
                Commands = @("Test-SemanticAnalysis")
            }
            ProcessingSuccess = $true
            TotalProcessingTimeMs = 150
        }
        
        # Test rule-based decision making
        $decision = Invoke-RuleBasedDecision -AnalysisResult $testAnalysisResult -DryRun
        if (-not $decision -or -not $decision.Decision) {
            throw "Rule-based decision making failed to return results"
        }
        
        if ($decision.Decision -ne "TEST") {
            throw "Decision engine returned unexpected decision: $($decision.Decision)"
        }
        
        # Test safety validation
        $safety = Test-SafetyValidation -AnalysisResult $testAnalysisResult
        if (-not $safety -or -not $safety.ContainsKey('IsSafe')) {
            throw "Safety validation failed to return results"
        }
        
        $stopwatch.Stop()
        $details = "Decision: $($decision.Decision), Safety: $($safety.IsSafe), Confidence: $($decision.ConfidenceLevel)"
        Add-TestResult -Name "Decision Engine" -Status "Passed" -Duration $stopwatch.ElapsedMilliseconds -Details $details
        Write-TestLog "Decision Engine test PASSED ($($stopwatch.ElapsedMilliseconds)ms)" -Level "SUCCESS"
        
    } catch {
        $stopwatch.Stop()
        Add-TestResult -Name "Decision Engine" -Status "Failed" -Duration $stopwatch.ElapsedMilliseconds -Error $_.Exception.Message
        Write-TestLog "Decision Engine test FAILED: $($_.Exception.Message)" -Level "ERROR"
    }
}

# Test 5: Action Execution Framework
function Test-ActionExecutionFramework {
    Write-TestLog "Testing Action Execution Framework..." -Level "INFO"
    $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
    
    try {
        # Test safe file path validation
        $safePath = Test-SafeFilePath -FilePath "$env:TEMP\test-file.txt"
        if (-not $safePath) {
            throw "Safe path validation failed for temporary directory"
        }
        
        $unsafePath = Test-SafeFilePath -FilePath "C:\Windows\System32\config.txt"
        if ($unsafePath) {
            throw "Unsafe path was incorrectly validated as safe"
        }
        
        # Test safe command validation
        $safeCommand = Test-SafeCommand -Command "Get-ChildItem"
        if (-not $safeCommand.IsSafe) {
            throw "Safe command was incorrectly flagged as unsafe"
        }
        
        $unsafeCommand = Test-SafeCommand -Command "Remove-Computer"
        if ($unsafeCommand.IsSafe) {
            throw "Unsafe command was incorrectly validated as safe"
        }
        
        # Test action safety validation
        $testAction = @{
            ActionType = "CONTINUE"
            Description = "Continue with implementation"
            TimeoutSeconds = 60
        }
        
        $actionSafety = Test-ActionSafety -ActionRequest $testAction
        if (-not $actionSafety.IsSafe) {
            throw "Safe action was flagged as unsafe: $($actionSafety.Violations -join '; ')"
        }
        
        # Test action queue functionality
        $queueId = Add-ActionToQueue -ActionRequest $testAction
        if (-not $queueId) {
            throw "Failed to add action to queue"
        }
        
        $queuedAction = Get-NextQueuedAction
        if (-not $queuedAction -or $queuedAction.Id -ne $queueId) {
            throw "Failed to retrieve queued action"
        }
        
        $stopwatch.Stop()
        $details = "Path validation: OK, Command validation: OK, Action safety: OK, Queue operations: OK"
        Add-TestResult -Name "Action Execution Framework" -Status "Passed" -Duration $stopwatch.ElapsedMilliseconds -Details $details
        Write-TestLog "Action Execution Framework test PASSED ($($stopwatch.ElapsedMilliseconds)ms)" -Level "SUCCESS"
        
    } catch {
        $stopwatch.Stop()
        Add-TestResult -Name "Action Execution Framework" -Status "Failed" -Duration $stopwatch.ElapsedMilliseconds -Error $_.Exception.Message
        Write-TestLog "Action Execution Framework test FAILED: $($_.Exception.Message)" -Level "ERROR"
    }
}

# Test 6: Configuration Loading
function Test-ConfigurationLoading {
    Write-TestLog "Testing configuration file loading..." -Level "INFO"
    $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
    
    try {
        $configPath = ".\Modules\Unity-Claude-CLIOrchestrator\Config"
        
        # Test decision trees config
        $decisionTreesPath = Join-Path $configPath "DecisionTrees.json"
        if (-not (Test-Path $decisionTreesPath)) {
            throw "DecisionTrees.json configuration file not found"
        }
        
        $decisionTrees = Get-Content $decisionTreesPath | ConvertFrom-Json
        if (-not $decisionTrees.decisionTrees) {
            throw "DecisionTrees.json has invalid structure"
        }
        
        # Test safety policies config
        $safetyPoliciesPath = Join-Path $configPath "SafetyPolicies.json"
        if (-not (Test-Path $safetyPoliciesPath)) {
            throw "SafetyPolicies.json configuration file not found"
        }
        
        $safetyPolicies = Get-Content $safetyPoliciesPath | ConvertFrom-Json
        if (-not $safetyPolicies.safetyPolicies) {
            throw "SafetyPolicies.json has invalid structure"
        }
        
        # Test learning parameters config
        $learningParamsPath = Join-Path $configPath "LearningParameters.json"
        if (-not (Test-Path $learningParamsPath)) {
            throw "LearningParameters.json configuration file not found"
        }
        
        $learningParams = Get-Content $learningParamsPath | ConvertFrom-Json
        if (-not $learningParams.learningParameters) {
            throw "LearningParameters.json has invalid structure"
        }
        
        $stopwatch.Stop()
        $details = "Decision trees: OK, Safety policies: OK, Learning parameters: OK"
        Add-TestResult -Name "Configuration Loading" -Status "Passed" -Duration $stopwatch.ElapsedMilliseconds -Details $details
        Write-TestLog "Configuration Loading test PASSED ($($stopwatch.ElapsedMilliseconds)ms)" -Level "SUCCESS"
        
    } catch {
        $stopwatch.Stop()
        Add-TestResult -Name "Configuration Loading" -Status "Failed" -Duration $stopwatch.ElapsedMilliseconds -Error $_.Exception.Message
        Write-TestLog "Configuration Loading test FAILED: $($_.Exception.Message)" -Level "ERROR"
    }
}

# Test 7: Integration Test - End-to-End Workflow
function Test-EndToEndWorkflow {
    Write-TestLog "Testing end-to-end workflow integration..." -Level "INFO"
    $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
    
    try {
        # Simulate complete Claude response processing workflow
        $testClaudeResponse = @"
Based on the analysis, I need to run the validation test to ensure the implementation is working correctly.

The test file is located at C:\UnityProjects\Sound-and-Shoal\Unity-Claude-Automation\Test-SemanticAnalysis.ps1.

There are some potential issues with the MonoBehaviour components that should be investigated.

RECOMMENDATION: TEST - Test-SemanticAnalysis.ps1: Execute the comprehensive validation test to verify all semantic analysis components are functioning properly.
"@

        # Step 1: Extract entities and context (Skip Enhanced JSON Analysis for plain text response)
        $entities = Extract-ResponseEntities -ResponseText $testClaudeResponse
        $sentiment = Analyze-ResponseSentiment -ResponseText $testClaudeResponse
        $context = Get-ResponseContext -ResponseText $testClaudeResponse
        
        # Step 2: Pattern recognition
        $patterns = Find-RecommendationPatterns -ResponseText $testClaudeResponse
        if ($patterns.Count -eq 0) {
            throw "No patterns found in test response"
        }
        
        # Step 3: Create comprehensive analysis result
        $analysisResult = @{
            Recommendations = $patterns
            ConfidenceAnalysis = @{
                OverallConfidence = $context.RelevanceScore
                QualityRating = if ($context.RelevanceScore -gt 0.8) { "High" } else { "Medium" }
            }
            Entities = $entities
            Sentiment = $sentiment
            Context = $context
            ProcessingSuccess = $true
            TotalProcessingTimeMs = 200
        }
        
        # Step 4: Decision making
        $decision = Invoke-RuleBasedDecision -AnalysisResult $analysisResult -DryRun
        if (-not $decision.Decision) {
            throw "Decision engine failed to make decision"
        }
        
        # Step 5: Safety validation
        $safety = Test-SafetyValidation -AnalysisResult $analysisResult
        if (-not $safety.IsSafe) {
            Write-TestLog "Safety validation flagged issues: $($safety.Violations -join '; ')" -Level "WARNING"
        }
        
        $stopwatch.Stop()
        $details = "Analysis: OK, Patterns: $($patterns.Count), Decision: $($decision.Decision), Safety: $($safety.IsSafe)"
        Add-TestResult -Name "End-to-End Workflow" -Status "Passed" -Duration $stopwatch.ElapsedMilliseconds -Details $details
        Write-TestLog "End-to-End Workflow test PASSED ($($stopwatch.ElapsedMilliseconds)ms)" -Level "SUCCESS"
        
    } catch {
        $stopwatch.Stop()
        Add-TestResult -Name "End-to-End Workflow" -Status "Failed" -Duration $stopwatch.ElapsedMilliseconds -Error $_.Exception.Message
        Write-TestLog "End-to-End Workflow test FAILED: $($_.Exception.Message)" -Level "ERROR"
    }
}

# Run tests based on TestType parameter
Write-TestLog "Starting test execution..." -Level "INFO"

if ($TestType -eq "All" -or $TestType -eq "Unit") {
    Test-ModuleImport
    Test-ResponseAnalysisEngine  
    Test-PatternRecognitionEngine
    Test-DecisionEngine
    Test-ActionExecutionFramework
    Test-ConfigurationLoading
}

if ($TestType -eq "All" -or $TestType -eq "Integration") {
    Test-EndToEndWorkflow
}

# Finalize test results
$testResults.EndTime = Get-Date
$testResults.TotalDuration = ($testResults.EndTime - $testResults.StartTime).TotalMilliseconds

# Display summary
Write-Host "`n================================================================" -ForegroundColor Cyan
Write-Host "  TEST EXECUTION COMPLETE" -ForegroundColor Cyan
Write-Host "================================================================" -ForegroundColor Cyan
Write-Host "Total Tests: $($testResults.Summary.Total)" -ForegroundColor White
Write-Host "Passed: $($testResults.Summary.Passed)" -ForegroundColor Green  
Write-Host "Failed: $($testResults.Summary.Failed)" -ForegroundColor Red
Write-Host "Skipped: $($testResults.Summary.Skipped)" -ForegroundColor Yellow
Write-Host "Errors: $($testResults.Summary.Errors)" -ForegroundColor Red
Write-Host "Total Duration: $([Math]::Round($testResults.TotalDuration))ms" -ForegroundColor White

$successRate = if ($testResults.Summary.Total -gt 0) { 
    [Math]::Round(($testResults.Summary.Passed / $testResults.Summary.Total) * 100, 1) 
} else { 0 }
Write-Host "Success Rate: $successRate%" -ForegroundColor $(if ($successRate -ge 90) { "Green" } elseif ($successRate -ge 70) { "Yellow" } else { "Red" })

# Show failed tests details
if ($testResults.Summary.Failed -gt 0) {
    Write-Host "`nFAILED TESTS:" -ForegroundColor Red
    $failedTests = $testResults.Results | Where-Object { $_.Status -eq "Failed" }
    foreach ($test in $failedTests) {
        Write-Host "  - $($test.Name): $($test.Error)" -ForegroundColor Red
    }
}

# Save results if requested
if ($SaveResults) {
    $timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
    $resultsFile = "CLIOrchestrator-TestResults-$timestamp.json"
    $testResults | ConvertTo-Json -Depth 10 | Out-File $resultsFile -Encoding UTF8
    Write-Host "`nTest results saved to: $resultsFile" -ForegroundColor Green
}

Write-Host "`nCLIOrchestrator comprehensive testing completed." -ForegroundColor Cyan

# Return success/failure for automation
if ($testResults.Summary.Failed -eq 0) {
    exit 0
} else {
    exit 1
}
# SIG # Begin signature block
# MIIFzgYJKoZIhvcNAQcCoIIFvzCCBbsCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCDRRmlAxlkCUHQT
# vfXZZ6rLqgQzarQoKa7akxOQC+LkSqCCAzAwggMsMIICFKADAgECAhB1HRbZIqgr
# lUTwkh3hnGtFMA0GCSqGSIb3DQEBCwUAMC4xLDAqBgNVBAMMI1VuaXR5LUNsYXVk
# ZS1BdXRvbWF0aW9uLURldmVsb3BtZW50MB4XDTI1MDgyMDIxMTUxN1oXDTI2MDgy
# MDIxMzUxN1owLjEsMCoGA1UEAwwjVW5pdHktQ2xhdWRlLUF1dG9tYXRpb24tRGV2
# ZWxvcG1lbnQwggEiMA0GCSqGSIb3DQEBAQUAA4IBDwAwggEKAoIBAQCx4feqKdUQ
# 6GufY4umNzlM1Pi8aHUGR8HlfhIWFjsrRAxCxhieRlWbHe0Hw+pVBeX76X57e5Pu
# 4Kxxzu+MxMry0NJYf3yOLRTfhYskHBcLraXUCtrMwqnhPKvul6Sx6Lu8vilk605W
# ADJNifl3WFuexVCYJJM9G2mfuYIDN+rZ5zmpn0qCXum49bm629h+HyJ205Zrn9aB
# hIrA4i/JlrAh1kosWnCo62psl7ixbNVqFqwWEt+gAqSeIo4ChwkOQl7GHmk78Q5I
# oRneY4JTVlKzhdZEYhJGFXeoZml/5jcmUcox4UNYrKdokE7z8ZTmyowBOUNS+sHI
# G1TY5DZSb8vdAgMBAAGjRjBEMA4GA1UdDwEB/wQEAwIHgDATBgNVHSUEDDAKBggr
# BgEFBQcDAzAdBgNVHQ4EFgQUfDms7LrGVboHjmwlSyIjYD/JLQwwDQYJKoZIhvcN
# AQELBQADggEBABRMsfT7DzKy+aFi4HDg0MpxmbjQxOH1lzUzanaECRiyA0sn7+sA
# /4jvis1+qC5NjDGkLKOTCuDzIXnBWLCCBugukXbIO7g392ANqKdHjBHw1WlLvMVk
# 4WSmY096lzpvDd3jJApr/Alcp4KmRGNLnQ3vv+F9Uj58Uo1qjs85vt6fl9xe5lo3
# rFahNHL4ngjgyF8emNm7FItJeNtVe08PhFn0caOX0FTzXrZxGGO6Ov8tzf91j/qK
# QdBifG7Fx3FF7DifNqoBBo55a7q0anz30k8p+V0zllrLkgGXfOzXmA1L37Qmt3QB
# FCdJVigjQMuHcrJsWd8rg857Og0un91tfZIxggH0MIIB8AIBATBCMC4xLDAqBgNV
# BAMMI1VuaXR5LUNsYXVkZS1BdXRvbWF0aW9uLURldmVsb3BtZW50AhB1HRbZIqgr
# lUTwkh3hnGtFMA0GCWCGSAFlAwQCAQUAoIGEMBgGCisGAQQBgjcCAQwxCjAIoAKA
# AKECgAAwGQYJKoZIhvcNAQkDMQwGCisGAQQBgjcCAQQwHAYKKwYBBAGCNwIBCzEO
# MAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIDT4t7gCpxHPThpGb4BMZ+WK
# JeOnTbpXF5pXCLp4q9Y+MA0GCSqGSIb3DQEBAQUABIIBAFu3hAurXRc1h4cR8rhZ
# em2tbBZ+w0sq0uSitH1zD89tRSK3/KVftMoztNlJf9Y1yo0YtwgHcv+nlSFJHoAh
# Fjjtx9erA6wA+wXQTHn7XpfEZYSPIh4oCfUuJzbe+GnbLnX1vq5oYDTUxdFYY7VF
# y5HUUtsOgs/MtAqiln5NU5TvN8KDC6XEz1aAElvT6rmmqTRUAu/EOMhSMbZ2lCBi
# IHuz2FeUnRJwmZZHaHxrcdp9xaE84qV/ARRtKhxiq0pZ+C3q8Nq23/dwcpCK9ewX
# RPvRtpvz82WwKhrfu0Vf768NRUJDtmTMBrboYQ0c8ELVZXsRvfvhop3CEB6W4+Ob
# DUY=
# SIG # End signature block
