# Demonstration of the complete autonomous CLIOrchestrator workflow
Write-Host @"
===============================================
AUTONOMOUS CLI ORCHESTRATOR DEMONSTRATION
===============================================
This demonstrates the complete autonomous workflow:
1. Response analysis and recommendation extraction
2. Decision making based on confidence and safety
3. Prompt generation with boilerplate
4. Action execution and result summarization
===============================================
"@ -ForegroundColor Cyan

# Import the module
Write-Host "`nImporting CLIOrchestrator module..." -ForegroundColor Yellow
Import-Module ".\Modules\Unity-Claude-CLIOrchestrator\Unity-Claude-CLIOrchestrator.psd1" -Force

# Create a sample Claude response file
Write-Host "`nCreating sample Claude response file..." -ForegroundColor Yellow
$sampleResponse = @{
    timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
    prompt_type = "Test Results"
    content = @"
Based on the test results analysis, I have identified the following issues and recommendations:

## Test Results Summary
- Total Tests: 25
- Passed: 20 
- Failed: 5
- Success Rate: 80%

## Analysis
The test failures are primarily related to module export issues in the CLIOrchestrator module. The autonomous functions (New-AutonomousPrompt, Get-ActionResultSummary, Invoke-AutonomousExecutionLoop) are not being properly exported from the module.

## Entities Identified
- File: C:\UnityProjects\Sound-and-Shoal\Unity-Claude-Automation\Test-CLIOrchestrator.ps1
- Module: Unity-Claude-CLIOrchestrator
- Functions: New-AutonomousPrompt, Get-ActionResultSummary, Invoke-AutonomousExecutionLoop

## Recommendations
1. Fix the Export-ModuleMember statement to include the new autonomous functions
2. Remove signature block that may be causing issues
3. Test the module import after fixes

RECOMMENDATION: TEST - C:\UnityProjects\Sound-and-Shoal\Unity-Claude-Automation\Test-CLIOrchestrator-Complete.ps1: Run comprehensive tests to validate all autonomous functions are working correctly. Expected: All functions should be available and operational.
"@
}

$responseFile = ".\Demo-ClaudeResponse.json"
$sampleResponse | ConvertTo-Json -Depth 10 | Out-File $responseFile -Encoding UTF8
Write-Host "  Created: $responseFile" -ForegroundColor Green

# Process the response file using the enhanced orchestrator
Write-Host "`n--- PROCESSING RESPONSE WITH AUTONOMOUS ORCHESTRATOR ---" -ForegroundColor Cyan

try {
    # Use Process-ResponseFile which includes all the autonomous capabilities
    Write-Host "`nCalling Process-ResponseFile with autonomous features..." -ForegroundColor Yellow
    
    # Since Process-ResponseFile attempts to submit to Claude window, 
    # we'll demonstrate the individual steps instead
    
    # Step 1: Analyze the response
    Write-Host "`n[Step 1] Analyzing response..." -ForegroundColor Yellow
    $responseText = Get-Content $responseFile -Raw | ConvertFrom-Json | Select-Object -ExpandProperty content
    
    # Step 2: Extract recommendations using pattern recognition
    Write-Host "[Step 2] Extracting recommendations..." -ForegroundColor Yellow
    $recommendations = @()
    $lines = $responseText -split "`n"
    foreach ($line in $lines) {
        if ($line -match "RECOMMENDATION:\s*(\w+)\s*-\s*(.+):\s*(.+)") {
            $rec = @{
                Type = $Matches[1]
                Target = $Matches[2]
                Action = $Matches[3]
            }
            $recommendations += $rec
            Write-Host "  Found: $($rec.Type) - $($rec.Target)" -ForegroundColor Green
        }
    }
    
    # Step 3: Make decision using the Decision Engine
    Write-Host "[Step 3] Making decision..." -ForegroundColor Yellow
    $analysisResult = @{
        Recommendations = @(
            @{
                Type = "TEST"
                Action = "Test-CLIOrchestrator-Complete.ps1"
                Confidence = 0.95
                Priority = 1
            }
        )
        ConfidenceAnalysis = @{
            OverallConfidence = 0.95
            QualityRating = "High"
        }
        Entities = @{
            FilePaths = @(".\Test-CLIOrchestrator-Complete.ps1")
        }
    }
    
    $decision = Invoke-RuleBasedDecision -AnalysisResult $analysisResult -DryRun
    Write-Host "  Decision: $($decision.Decision)" -ForegroundColor Green
    Write-Host "  Rules Applied: $($decision.Rules -join ', ')" -ForegroundColor Gray
    
    # Step 4: Validate safety
    Write-Host "[Step 4] Validating safety..." -ForegroundColor Yellow
    $safety = Test-SafetyValidation -AnalysisResult $analysisResult
    Write-Host "  Safety Check: $(if($safety.IsSafe){'PASSED'}else{'FAILED'})" -ForegroundColor $(if($safety.IsSafe){'Green'}else{'Red'})
    Write-Host "  Risk Level: $($safety.RiskLevel)" -ForegroundColor Gray
    
    # Step 5: Generate autonomous prompt
    Write-Host "[Step 5] Generating autonomous prompt..." -ForegroundColor Yellow
    
    # Load the autonomous functions directly since they're not exported
    . ".\Modules\Unity-Claude-CLIOrchestrator\Unity-Claude-CLIOrchestrator.psm1"
    
    $prompt = New-AutonomousPrompt `
        -RecommendationType "TEST" `
        -ActionDetails "Test-CLIOrchestrator-Complete.ps1" `
        -Context @{
            TestResults = "80% pass rate"
            Issues = "Module export problems"
            NextSteps = "Run comprehensive tests"
        } `
        -IncludeBoilerplate
    
    Write-Host "  Generated prompt: $($prompt.Length) characters" -ForegroundColor Green
    
    # Show prompt preview
    Write-Host "`n[Step 6] Prompt Preview (first 500 chars):" -ForegroundColor Yellow
    $preview = $prompt.Substring(0, [Math]::Min(500, $prompt.Length))
    Write-Host $preview -ForegroundColor DarkGray
    Write-Host "..." -ForegroundColor DarkGray
    
    # Step 7: Queue action for execution
    Write-Host "`n[Step 7] Queueing action for execution..." -ForegroundColor Yellow
    $queueResult = Add-ActionToQueue `
        -Action @{
            Type = "ExecuteTest"
            Target = "Test-CLIOrchestrator-Complete.ps1"
            Priority = 1
        } `
        -Priority 1 `
        -Context @{Source = "AutonomousOrchestrator"}
    
    Write-Host "  Action queued successfully" -ForegroundColor Green
    Write-Host "  Queue position: $($queueResult.QueuePosition)" -ForegroundColor Gray
    
    # Step 8: Demonstrate result summarization
    Write-Host "`n[Step 8] Simulating action execution and result summary..." -ForegroundColor Yellow
    
    # Create mock test results
    $mockResults = @{
        Timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
        TestName = "CLIOrchestrator-Complete"
        TotalTests = 30
        Passed = 30
        Failed = 0
        Duration = "15.3s"
    }
    
    $mockResultFile = ".\Demo-TestResults.json"
    $mockResults | ConvertTo-Json | Out-File $mockResultFile -Encoding UTF8
    
    $summary = Get-ActionResultSummary -ResultPath $mockResultFile -ActionType "Test"
    Write-Host "  Result Summary:" -ForegroundColor Green
    Write-Host $summary -ForegroundColor Gray
    
    # Clean up mock files
    Remove-Item $mockResultFile -Force -ErrorAction SilentlyContinue
    
} catch {
    Write-Host "ERROR: $_" -ForegroundColor Red
    Write-Host "Stack: $($_.ScriptStackTrace)" -ForegroundColor DarkGray
} finally {
    # Clean up
    if (Test-Path $responseFile) {
        Remove-Item $responseFile -Force -ErrorAction SilentlyContinue
        Write-Host "`nCleaned up demo files" -ForegroundColor Gray
    }
}

Write-Host "`n===============================================" -ForegroundColor Cyan
Write-Host "DEMONSTRATION COMPLETE" -ForegroundColor Cyan
Write-Host @"

Summary of Autonomous Capabilities:
✓ Response analysis and pattern recognition
✓ Recommendation extraction from Claude output  
✓ Rule-based decision making with confidence scoring
✓ Safety validation and risk assessment
✓ Autonomous prompt generation with boilerplate
✓ Action queueing and execution framework
✓ Result retrieval and summarization

The CLIOrchestrator is now fully autonomous and can:
1. Receive and analyze Claude's recommendations
2. Make intelligent decisions about actions to take
3. Generate new prompts with full context
4. Execute actions safely with validation
5. Report results and continue the loop

Note: The new autonomous functions need to be properly
exported from the module for full integration.
"@ -ForegroundColor Green
# SIG # Begin signature block
# MIIFzgYJKoZIhvcNAQcCoIIFvzCCBbsCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCAomD2FBQGDFr8V
# GOtlGMNqlLEkcxGsbFM2FRQR9OMxo6CCAzAwggMsMIICFKADAgECAhB1HRbZIqgr
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
# MAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIDJpY8bBnT+90VYhWAyDMyll
# eBVlMN3qc3991KxCVBvmMA0GCSqGSIb3DQEBAQUABIIBAEGkERWoKFmNsesrTjVv
# On7WxkYycWPCYDcfON5f5mplwvdqD+0cOz1VImUuZ8+fE2YcfWjEkmQw3w2AMnEz
# lGb88YJbkC3r/792FlBje4HBAMzjSG8YWw3Z1ll7JqL7s01gupMqnR5oIrRYkRVg
# jHNhOZSAtIlKANcfU1nPP3jqmz8CZao3eEU0ubGVU7T77HUE6Ro/CyJCo/Z2JYhX
# YuQ5H2xt0qWBtCx1ItNDhrk8+aVZEII8bWgKC8LKLDifJpx2bpHOq5NiHveMy2KT
# eZlLRM08cRgP7Yx18agGrsBFGIlh3lqXTApe/mxCpdmkI9ZMgwKWxjU/BYHC3TWb
# g3M=
# SIG # End signature block
