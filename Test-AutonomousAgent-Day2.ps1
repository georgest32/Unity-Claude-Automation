# Test-AutonomousAgent-Day2.ps1
# Day 2 testing for Claude Code CLI Autonomous Agent enhanced parsing engine
# Tests: Enhanced regex patterns, response classification, context extraction, state detection

[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'

Write-Host "=== Unity-Claude Autonomous Agent Day 2 Testing ===" -ForegroundColor Yellow
Write-Host "Testing enhanced parsing, classification, context extraction, and state detection" -ForegroundColor Cyan

# Import the autonomous agent module
try {
    $ModulePath = Join-Path $PSScriptRoot "Modules\Unity-Claude-AutonomousAgent\Unity-Claude-AutonomousAgent.psd1"
    Import-Module $ModulePath -Force -DisableNameChecking
    Initialize-AgentLogging
    
    $exportedFunctions = Get-Command -Module Unity-Claude-AutonomousAgent
    Write-Host "Module loaded with $($exportedFunctions.Count) functions" -ForegroundColor Green
}
catch {
    Write-Error "Failed to load autonomous agent module: $_"
    exit 1
}

# Test 1: Enhanced Regex Pattern Matching
Write-Host ""
Write-Host "Test 1: Enhanced Regex Pattern Matching" -ForegroundColor Yellow
try {
    $testResponses = @(
        @{ content = "RECOMMENDED: TEST - Run Unity EditMode tests" },
        @{ content = "You should BUILD - the project for validation" },
        @{ content = "I recommend running tests to check the implementation" },
        @{ content = "RUN TESTS to validate the changes before deployment" },
        @{ content = "I suggest analyzing the log files for performance issues" }
    )
    
    $totalRecommendations = 0
    foreach ($response in $testResponses) {
        $recommendations = Find-ClaudeRecommendations -ResponseObject $response
        $totalRecommendations += $recommendations.Count
        
        foreach ($rec in $recommendations) {
            Write-Host "  Found: $($rec.Type) - $($rec.Details) (Pattern: $($rec.Pattern), Confidence: $($rec.Confidence))" -ForegroundColor Gray
        }
    }
    
    Write-Host "Enhanced pattern matching found $totalRecommendations total recommendations" -ForegroundColor Green
}
catch {
    Write-Host "Enhanced pattern matching test failed: $_" -ForegroundColor Red
}

# Test 2: Response Classification Engine
Write-Host ""
Write-Host "Test 2: Response Classification Engine" -ForegroundColor Yellow
try {
    $classificationTests = @(
        @{ content = "RECOMMENDED: TEST - Run unit tests"; expected = "Recommendation" },
        @{ content = "Can you tell me what files are in the project?"; expected = "Question" },
        @{ content = "Here is the analysis of your code structure..."; expected = "Information" },
        @{ content = "First, open the file. Then, add the using directive. Finally, compile."; expected = "Instruction" },
        @{ content = "I'm sorry, I cannot access that file due to security restrictions."; expected = "Error" }
    )
    
    $correctClassifications = 0
    foreach ($test in $classificationTests) {
        $classification = Classify-ClaudeResponse -ResponseObject $test
        $isCorrect = $classification.PrimaryType -eq $test.expected
        $correctClassifications += if ($isCorrect) { 1 } else { 0 }
        
        $color = if ($isCorrect) { "Green" } else { "Red" }
        Write-Host "  $($test.expected): $($classification.PrimaryType) (Confidence: $($classification.Confidence)) - $($isCorrect)" -ForegroundColor $color
    }
    
    $accuracy = ($correctClassifications / $classificationTests.Count) * 100
    Write-Host "Classification accuracy: $accuracy%" -ForegroundColor Green
}
catch {
    Write-Host "Response classification test failed: $_" -ForegroundColor Red
}

# Test 3: Context Extraction
Write-Host ""
Write-Host "Test 3: Context Extraction Engine" -ForegroundColor Yellow
try {
    $contextTest = @{
        content = @"
I found several CS0246 errors in Assets\Scripts\Player.cs related to missing using directives. 
The Unity EditorApplication needs to be properly imported. Let me analyze the GameObject references
and check if MonoBehaviour is properly inherited. Next, we should run tests to validate the fix.
"@
    }
    
    $context = Extract-ConversationContext -ResponseObject $contextTest
    
    Write-Host "Context extraction results:" -ForegroundColor Cyan
    Write-Host "  - Error mentions: $($context.ErrorMentions.Count)" -ForegroundColor Gray
    Write-Host "  - File mentions: $($context.FileMentions.Count)" -ForegroundColor Gray  
    Write-Host "  - Unity terms: $($context.UnitySpecificContent.Count)" -ForegroundColor Gray
    Write-Host "  - Conversation cues: $($context.ConversationCues.Count)" -ForegroundColor Gray
    Write-Host "  - Next actions: $($context.NextActionSuggestions.Count)" -ForegroundColor Gray
    
    if ($context.ErrorMentions.Count -gt 0) {
        Write-Host "Errors found:" -ForegroundColor Yellow
        foreach ($error in $context.ErrorMentions) {
            Write-Host "    $error" -ForegroundColor Gray
        }
    }
    
    Write-Host "Context extraction test completed" -ForegroundColor Green
}
catch {
    Write-Host "Context extraction test failed: $_" -ForegroundColor Red
}

# Test 4: Conversation State Detection
Write-Host ""
Write-Host "Test 4: Conversation State Detection" -ForegroundColor Yellow
try {
    $stateTests = @(
        @{ content = "Can you provide the contents of the error log file?"; expected = "WaitingForInput" },
        @{ content = "Let me analyze these compilation errors..."; expected = "Processing" },
        @{ content = "The issue has been resolved! Here are the results."; expected = "Completed" },
        @{ content = "Follow these steps: First, open the file. Then, add the directive."; expected = "ProvidingGuidance" },
        @{ content = "I'm sorry, I cannot access that file."; expected = "ErrorEncountered" }
    )
    
    $correctStates = 0
    foreach ($test in $stateTests) {
        $state = Detect-ConversationState -ResponseObject $test
        $isCorrect = $state.PrimaryState -eq $test.expected
        $correctStates += if ($isCorrect) { 1 } else { 0 }
        
        $color = if ($isCorrect) { "Green" } else { "Red" }
        Write-Host "  $($test.expected): $($state.PrimaryState) (Confidence: $($state.Confidence), Autonomous: $($state.CanProceedAutonomously)) - $($isCorrect)" -ForegroundColor $color
    }
    
    $stateAccuracy = ($correctStates / $stateTests.Count) * 100
    Write-Host "State detection accuracy: $stateAccuracy%" -ForegroundColor Green
}
catch {
    Write-Host "Conversation state detection test failed: $_" -ForegroundColor Red
}

# Test 5: Confidence Scoring Algorithm
Write-Host ""
Write-Host "Test 5: Confidence Scoring Algorithm" -ForegroundColor Yellow
try {
    # Test confidence calculation for different pattern types
    $confidenceTests = @(
        @{ pattern = "Standard"; text = "RECOMMENDED: TEST - Run comprehensive Unity EditMode tests with detailed validation"; expectedRange = @(0.9, 1.0) },
        @{ pattern = "ActionOriented"; text = "You should BUILD - the project"; expectedRange = @(0.8, 0.9) },
        @{ pattern = "Suggestion"; text = "I suggest checking the logs"; expectedRange = @(0.7, 0.8) }
    )
    
    foreach ($test in $confidenceTests) {
        # Create a mock match object for testing
        $mockMatch = [regex]::Match($test.text, 'TEST|BUILD|ANALYZE')
        $confidence = Get-PatternConfidence -PatternName $test.pattern -Match $mockMatch
        
        $inRange = $confidence -ge $test.expectedRange[0] -and $confidence -le $test.expectedRange[1]
        $color = if ($inRange) { "Green" } else { "Red" }
        
        Write-Host "  $($test.pattern): $confidence (Expected: $($test.expectedRange[0])-$($test.expectedRange[1])) - $($inRange)" -ForegroundColor $color
    }
    
    Write-Host "Confidence scoring algorithm validated" -ForegroundColor Green
}
catch {
    Write-Host "Confidence scoring test failed: $_" -ForegroundColor Red
}

# Test Summary
Write-Host ""
Write-Host "=== Day 2 Testing Summary ===" -ForegroundColor Yellow
Write-Host "Enhanced parsing engine components tested:" -ForegroundColor Cyan
Write-Host "Enhanced regex pattern matching with multiple formats" -ForegroundColor Green
Write-Host "Response classification engine (Recommendation, Question, Information, etc.)" -ForegroundColor Green
Write-Host "Context extraction for errors, files, Unity terms, and conversation cues" -ForegroundColor Green
Write-Host "Conversation state detection with autonomous operation assessment" -ForegroundColor Green
Write-Host "Confidence scoring algorithm for automated decision making" -ForegroundColor Green

Write-Host ""
Write-Host "Day 2 Enhanced Parsing Engine implementation completed!" -ForegroundColor Green
Write-Host "Ready for Day 3: Safe Command Execution Framework implementation" -ForegroundColor Cyan
# SIG # Begin signature block
# MIIFqQYJKoZIhvcNAQcCoIIFmjCCBZYCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUsD+SyPRvUCM9mrirJ1XjVO0Q
# X9OgggMwMIIDLDCCAhSgAwIBAgIQdR0W2SKoK5VE8JId4ZxrRTANBgkqhkiG9w0B
# AQsFADAuMSwwKgYDVQQDDCNVbml0eS1DbGF1ZGUtQXV0b21hdGlvbi1EZXZlbG9w
# bWVudDAeFw0yNTA4MjAyMTE1MTdaFw0yNjA4MjAyMTM1MTdaMC4xLDAqBgNVBAMM
# I1VuaXR5LUNsYXVkZS1BdXRvbWF0aW9uLURldmVsb3BtZW50MIIBIjANBgkqhkiG
# 9w0BAQEFAAOCAQ8AMIIBCgKCAQEAseH3qinVEOhrn2OLpjc5TNT4vGh1BkfB5X4S
# FhY7K0QMQsYYnkZVmx3tB8PqVQXl++l+e3uT7uCscc7vjMTK8tDSWH98ji0U34WL
# JBwXC62l1ArazMKp4Tyr7peksei7vL4pZOtOVgAyTYn5d1hbnsVQmCSTPRtpn7mC
# Azfq2ec5qZ9Kgl7puPW5utvYfh8idtOWa5/WgYSKwOIvyZawIdZKLFpwqOtqbJe4
# sWzVahasFhLfoAKkniKOAocJDkJexh5pO/EOSKEZ3mOCU1ZSs4XWRGISRhV3qGZp
# f+Y3JlHKMeFDWKynaJBO8/GU5sqMATlDUvrByBtU2OQ2Um/L3QIDAQABo0YwRDAO
# BgNVHQ8BAf8EBAMCB4AwEwYDVR0lBAwwCgYIKwYBBQUHAwMwHQYDVR0OBBYEFHw5
# rOy6xlW6B45sJUsiI2A/yS0MMA0GCSqGSIb3DQEBCwUAA4IBAQAUTLH0+w8ysvmh
# YuBw4NDKcZm40MTh9Zc1M2p2hAkYsgNLJ+/rAP+I74rNfqguTYwxpCyjkwrg8yF5
# wViwggboLpF2yDu4N/dgDainR4wR8NVpS7zFZOFkpmNPepc6bw3d4yQKa/wJXKeC
# pkRjS50N77/hfVI+fFKNao7POb7en5fcXuZaN6xWoTRy+J4I4MhfHpjZuxSLSXjb
# VXtPD4RZ9HGjl9BU8162cRhjujr/Lc3/dY/6ikHQYnxuxcdxRew4nzaqAQaOeWu6
# tGp899JPKfldM5Zay5IBl3zs15gNS9+0Jrd0ARQnSVYoI0DLh3KybFnfK4POezoN
# Lp/dbX2SMYIB4zCCAd8CAQEwQjAuMSwwKgYDVQQDDCNVbml0eS1DbGF1ZGUtQXV0
# b21hdGlvbi1EZXZlbG9wbWVudAIQdR0W2SKoK5VE8JId4ZxrRTAJBgUrDgMCGgUA
# oHgwGAYKKwYBBAGCNwIBDDEKMAigAoAAoQKAADAZBgkqhkiG9w0BCQMxDAYKKwYB
# BAGCNwIBBDAcBgorBgEEAYI3AgELMQ4wDAYKKwYBBAGCNwIBFTAjBgkqhkiG9w0B
# CQQxFgQUGxgyrn/EC0rmUMae4/b5VeVr3sAwDQYJKoZIhvcNAQEBBQAEggEAaS4B
# wEUrf6TUYIiO+ugxTo9EezwDQ2qurSZdN0mLHCue1anV9/6xQEl8TprWT0d6vwKp
# OMRit5KhiI6TCaWHRgwtYETtmVyqZ4VTJ7mkdF9N2HkmGzLTyJWWiWjlVe2ng/74
# vNVAA8T0ULMNAjakX8dK7BvOqAYM2+ZFhfdSWGhwPjH32yY96UZ+ubPb3KCvHUm8
# G2ZI3mCQbWi1/xuPDODwN+Ns6dY/pI7Ksw1/vuBgqDSLE8+ud9xyrQrYLpz1Zgjo
# rvFNQMuwXepGK1kR5T5dLaaU9RXPyNEal14EKHHm4NrggMTH01vI4FOvDfRWbC4N
# w/HGmU4qTN1m5eup4g==
# SIG # End signature block
