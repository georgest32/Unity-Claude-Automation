# Test-EnhancedResponseProcessing-Day11.ps1
# Test suite for Phase 2 Day 11: Enhanced Response Processing
# Tests ResponseParsing, Classification, and ContextExtraction modules
# Date: 2025-08-18

param(
    [switch]$Detailed,
    [switch]$SkipPerformanceTests,
    [string]$LogLevel = "Info"
)

# Test configuration
$TestConfig = @{
    ProjectRoot = "C:\UnityProjects\Sound-and-Shoal\Unity-Claude-Automation"
    ModulePath = "C:\UnityProjects\Sound-and-Shoal\Unity-Claude-Automation\Modules\Unity-Claude-AutonomousAgent"
    TestTimeout = 30
    ExpectedPatterns = 12
    ExpectedCategories = 5
    ExpectedEntityTypes = 9
}

# Initialize test results tracking
$TestResults = @{
    Total = 0
    Passed = 0
    Failed = 0
    Skipped = 0
    Details = @()
    StartTime = Get-Date
}

function Write-TestResult {
    param(
        [string]$TestName,
        [bool]$Passed,
        [string]$Details = "",
        [string]$Error = ""
    )
    
    $TestResults.Total++
    if ($Passed) {
        $TestResults.Passed++
        $status = "PASS"
        $color = "Green"
    } else {
        $TestResults.Failed++
        $status = "FAIL"
        $color = "Red"
    }
    
    $result = @{
        TestName = $TestName
        Status = $status
        Details = $Details
        Error = $Error
        Timestamp = Get-Date
    }
    
    $TestResults.Details += $result
    
    if ($Detailed) {
        Write-Host "[$status] $TestName" -ForegroundColor $color
        if ($Details) { Write-Host "  $Details" -ForegroundColor Gray }
        if ($Error) { Write-Host "  ERROR: $Error" -ForegroundColor Red }
    } else {
        Write-Host "$status" -ForegroundColor $color -NoNewline
        Write-Host " " -NoNewline
    }
}

Write-Host ""
Write-Host "Starting Enhanced Response Processing Tests - Phase 2 Day 11" -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Cyan

# Load required modules
Write-Host ""
Write-Host "Loading required modules..." -ForegroundColor Yellow

try {
    # Import the refactored autonomous agent module
    Import-Module "$($TestConfig.ModulePath)\Unity-Claude-AutonomousAgent-Refactored.psd1" -Force
    Write-Host "Unity-Claude-AutonomousAgent-Refactored module loaded successfully" -ForegroundColor Green
    
    # Test that Day 11 functions are available
    $day11Functions = @(
        'Invoke-EnhancedResponseParsing',
        'Get-ResponseQualityScore',
        'Extract-CommandsFromResponse',
        'Get-ResponseCategorization',
        'Get-ResponseEntities',
        'Invoke-ResponseClassification',
        'Get-ResponseIntent',
        'Get-ResponseSentiment',
        'Invoke-AdvancedContextExtraction',
        'Get-ContextRelevanceScores'
    )
    
    $missingFunctions = @()
    foreach ($func in $day11Functions) {
        if (-not (Get-Command $func -ErrorAction SilentlyContinue)) {
            $missingFunctions += $func
        }
    }
    
    if ($missingFunctions.Count -gt 0) {
        Write-Host "WARNING: Missing Day 11 functions: $($missingFunctions -join ', ')" -ForegroundColor Yellow
    } else {
        Write-Host "All Day 11 functions available" -ForegroundColor Green
    }
} catch {
    Write-Host "CRITICAL: Failed to load modules: $_" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "Running Enhanced Response Processing Tests..." -ForegroundColor Yellow
Write-Host ""

# Test 1: Enhanced response parsing
try {
    $testResponse = "RECOMMENDED: TEST - Run the validation script to check all functionality. CS0246: Type not found error occurred."
    $result = Invoke-EnhancedResponseParsing -ResponseText $testResponse
    
    $passed = $result.Success -eq $true -and 
              $result.Results.PatternsMatched.Count -gt 0 -and
              $result.Results.OverallConfidence -gt 0
    
    Write-TestResult -TestName "Enhanced response parsing with pattern matching" -Passed $passed -Details "Patterns matched: $($result.Results.PatternsMatched.Count), Confidence: $($result.Results.OverallConfidence)"
} catch {
    Write-TestResult -TestName "Enhanced response parsing with pattern matching" -Passed $false -Error $_.Exception.Message
}

# Test 2: Response quality scoring
try {
    $testResponse = "The implementation was successful and working correctly. All tests are passing."
    $qualityScore = Get-ResponseQualityScore -ResponseText $testResponse
    
    $passed = $qualityScore -gt 0 -and $qualityScore -le 1.0
    
    Write-TestResult -TestName "Response quality score calculation" -Passed $passed -Details "Quality score: $qualityScore"
} catch {
    Write-TestResult -TestName "Response quality score calculation" -Passed $false -Error $_.Exception.Message
}

# Test 3: Command extraction
try {
    $testResponse = "RECOMMENDED: TEST - Run the comprehensive validation. Please also update the configuration file."
    $result = Extract-CommandsFromResponse -ResponseText $testResponse
    
    $passed = $result.Success -eq $true -and 
              $result.CommandCount -gt 0 -and
              $result.Commands[0].CommandType -eq "TEST"
    
    Write-TestResult -TestName "Command extraction from response" -Passed $passed -Details "Commands extracted: $($result.CommandCount)"
} catch {
    Write-TestResult -TestName "Command extraction from response" -Passed $false -Error $_.Exception.Message
}

# Test 4: Response classification
try {
    $testResponse = "CS0246: The type or namespace could not be found. Please check your using statements."
    $result = Invoke-ResponseClassification -ResponseText $testResponse -UseAdvancedTree
    
    $passed = $result.Success -eq $true -and 
              $result.Classification.Category -eq "Error" -and
              $result.Classification.Confidence -ge 0.25
    
    Write-TestResult -TestName "Response classification with decision tree" -Passed $passed -Details "Category: $($result.Classification.Category), Confidence: $($result.Classification.Confidence)"
} catch {
    Write-TestResult -TestName "Response classification with decision tree" -Passed $false -Error $_.Exception.Message
}

# Test 5: Intent detection
try {
    $testResponse = "Could you help me understand how to fix this Unity error?"
    $result = Get-ResponseIntent -ResponseText $testResponse
    
    $passed = $result.Success -eq $true -and 
              $result.Intent -ne "Unknown" -and
              $result.Confidence -gt 0
    
    Write-TestResult -TestName "Intent detection from response text" -Passed $passed -Details "Intent: $($result.Intent), Confidence: $($result.Confidence)"
} catch {
    Write-TestResult -TestName "Intent detection from response text" -Passed $false -Error $_.Exception.Message
}

# Test 6: Sentiment analysis
try {
    $testResponse = "The fix was successful and everything is working perfectly now."
    $result = Get-ResponseSentiment -ResponseText $testResponse
    
    $passed = $result.Success -eq $true -and 
              $result.Sentiment -eq "Positive" -and
              $result.Score -gt 0
    
    Write-TestResult -TestName "Sentiment analysis of response" -Passed $passed -Details "Sentiment: $($result.Sentiment), Score: $($result.Score)"
} catch {
    Write-TestResult -TestName "Sentiment analysis of response" -Passed $false -Error $_.Exception.Message
}

# Test 7: Entity extraction
try {
    $testResponse = "Check the file C:\Unity\Scripts\Player.cs for CS0246 error. The GameObject component needs updating."
    $result = Get-ResponseEntities -ResponseText $testResponse
    
    $passed = $result.Success -eq $true -and 
              $result.TotalEntities -gt 0 -and
              $result.Entities.FilePaths.Count -gt 0
    
    Write-TestResult -TestName "Entity extraction from response" -Passed $passed -Details "Total entities: $($result.TotalEntities)"
} catch {
    Write-TestResult -TestName "Entity extraction from response" -Passed $false -Error $_.Exception.Message
}

# Test 8: Advanced context extraction
try {
    $testResponse = "CS0246 error in Player.cs line 42. The Transform component is missing. RECOMMENDED: TEST - Check component references."
    $result = Invoke-AdvancedContextExtraction -ResponseText $testResponse
    
    $passed = $result.Success -eq $true -and 
              $result.Results.Entities.Count -gt 0 -and
              $result.Results.IntegrationReady -eq $true
    
    Write-TestResult -TestName "Advanced context extraction with relationships" -Passed $passed -Details "Entities: $($result.Results.Entities.Count), Relationships: $($result.Results.Relationships.Count)"
} catch {
    Write-TestResult -TestName "Advanced context extraction with relationships" -Passed $false -Error $_.Exception.Message
}

# Test 9: Entity relationship mapping
try {
    $entities = @(
        @{ Type = "File"; Value = "Player.cs"; BaseRelevance = 0.9 },
        @{ Type = "ErrorCode"; Value = "CS0246"; BaseRelevance = 0.95 }
    )
    $relationships = @(
        @{ Type = "FileError"; MatchedText = "Player.cs CS0246"; Relevance = 0.85 }
    )
    
    $result = Get-EntityRelationshipMap -Entities $entities -Relationships $relationships
    
    $passed = $result.Success -eq $true -and 
              $result.RelationshipMap.Nodes.Count -gt 0 -and
              $result.RelationshipMap.Edges.Count -gt 0
    
    Write-TestResult -TestName "Entity relationship mapping and clustering" -Passed $passed -Details "Nodes: $($result.RelationshipMap.Nodes.Count), Edges: $($result.RelationshipMap.Edges.Count)"
} catch {
    Write-TestResult -TestName "Entity relationship mapping and clustering" -Passed $false -Error $_.Exception.Message
}

# Test 10: Module self-tests
try {
    $parsingTest = Test-ResponseParsingModule
    $classificationTest = Test-ClassificationEngine
    
    $passed = $parsingTest.Success -eq $true -and 
              $classificationTest.Success -eq $true -and
              $parsingTest.SuccessRate -ge 75 -and
              $classificationTest.SuccessRate -ge 75
    
    Write-TestResult -TestName "Module self-validation tests" -Passed $passed -Details "Parsing: $($parsingTest.SuccessRate)%, Classification: $($classificationTest.SuccessRate)%"
} catch {
    Write-TestResult -TestName "Module self-validation tests" -Passed $false -Error $_.Exception.Message
}

# Performance Tests (if not skipped)
if (-not $SkipPerformanceTests) {
    # Test 11: Response processing performance
    try {
        $testResponse = "RECOMMENDED: TEST - Run validation. CS0246 error in Player.cs. The implementation was successful."
        $startTime = Get-Date
        
        for ($i = 1; $i -le 10; $i++) {
            Invoke-EnhancedResponseParsing -ResponseText $testResponse | Out-Null
        }
        
        $duration = ((Get-Date) - $startTime).TotalMilliseconds
        $avgDuration = $duration / 10
        $passed = $avgDuration -lt 100  # Should complete within 100ms average
        
        Write-TestResult -TestName "Response processing performance" -Passed $passed -Details "$([Math]::Round($avgDuration, 2))ms average for parsing"
    } catch {
        Write-TestResult -TestName "Response processing performance" -Passed $false -Error $_.Exception.Message
    }
    
    # Test 12: Classification performance
    try {
        $testResponse = "What Unity version are you using? Please check the error logs for CS0246 issues."
        $startTime = Get-Date
        
        for ($i = 1; $i -le 10; $i++) {
            Invoke-ResponseClassification -ResponseText $testResponse | Out-Null
        }
        
        $duration = ((Get-Date) - $startTime).TotalMilliseconds
        $avgDuration = $duration / 10
        $passed = $avgDuration -lt 50  # Should complete within 50ms average
        
        Write-TestResult -TestName "Classification engine performance" -Passed $passed -Details "$([Math]::Round($avgDuration, 2))ms average for classification"
    } catch {
        Write-TestResult -TestName "Classification engine performance" -Passed $false -Error $_.Exception.Message
    }
} else {
    Write-Host "SKIP SKIP " -ForegroundColor Yellow -NoNewline
}

# Final results
$TestResults.EndTime = Get-Date
$duration = ($TestResults.EndTime - $TestResults.StartTime).TotalSeconds

Write-Host ""
Write-Host ""
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "Enhanced Response Processing Test Results - Phase 2 Day 11" -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "Total Tests: $($TestResults.Total)" -ForegroundColor White
Write-Host "Passed: $($TestResults.Passed)" -ForegroundColor Green
Write-Host "Failed: $($TestResults.Failed)" -ForegroundColor Red
Write-Host "Skipped: $($TestResults.Skipped)" -ForegroundColor Yellow
Write-Host "Duration: $([Math]::Round($duration, 2)) seconds" -ForegroundColor White

$successRate = if ($TestResults.Total -gt 0) { 
    [Math]::Round(($TestResults.Passed / $TestResults.Total) * 100, 1) 
} else { 0 }

Write-Host "Success Rate: $successRate%" -ForegroundColor $(if ($successRate -ge 90) { 'Green' } elseif ($successRate -ge 70) { 'Yellow' } else { 'Red' })

if ($TestResults.Failed -gt 0) {
    Write-Host ""
    Write-Host "Failed Tests:" -ForegroundColor Red
    foreach ($failure in ($TestResults.Details | Where-Object { $_.Status -eq 'FAIL' })) {
        Write-Host "  - $($failure.TestName): $($failure.Error)" -ForegroundColor Red
    }
}

Write-Host ""
if ($successRate -ge 90) {
    Write-Host "Phase 2 Day 11: ENHANCED RESPONSE PROCESSING OPERATIONAL" -ForegroundColor Green
    Write-Host "Response parsing, classification, and context extraction validated" -ForegroundColor Green
} elseif ($successRate -ge 70) {
    Write-Host "Phase 2 Day 11: MOSTLY SUCCESSFUL" -ForegroundColor Yellow
    Write-Host "Core response processing working, minor issues detected" -ForegroundColor Yellow
} else {
    Write-Host "Phase 2 Day 11: VALIDATION FAILED" -ForegroundColor Red
    Write-Host "Critical issues detected in response processing system" -ForegroundColor Red
}

Write-Host ""
Write-Host "Day 11 Modules Created:" -ForegroundColor Cyan
Write-Host "  - ResponseParsing.psm1 (6 functions)" -ForegroundColor Gray
Write-Host "  - Classification.psm1 (8 functions)" -ForegroundColor Gray  
Write-Host "  - ContextExtraction.psm1 (6 functions)" -ForegroundColor Gray
Write-Host "  Total: 20 new functions for enhanced response processing" -ForegroundColor Gray

Write-Host ""
Write-Host "Test completed at $(Get-Date)" -ForegroundColor Gray

# Return success rate for automation
return $successRate
# SIG # Begin signature block
# MIIFqQYJKoZIhvcNAQcCoIIFmjCCBZYCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUKymeUb5Tv11ENW7G0Yf6N9hM
# zZigggMwMIIDLDCCAhSgAwIBAgIQdR0W2SKoK5VE8JId4ZxrRTANBgkqhkiG9w0B
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
# CQQxFgQU4atll77Y3L1vz4lEjoMf652BnNEwDQYJKoZIhvcNAQEBBQAEggEAP3Zn
# +9OIUyhTreFmX9XO0iDIXOLJDbZDjktpMJBScK+/9zrYBAQM+zc9ZoZ/j+Li0D1Z
# Y0SMFtERLO+0P9IxDKusNvFyDRAdJgiAiZsSfj0l2RE5hMW/nPb6PtcCbd9A+rqa
# GIUiN6bHqBWmaa1hz2/4OObmwPE6oNnCvRwp5XQYP+puEAleop1J/7sIPe9lu4yu
# HlyIlKzgnXqPmMVDYEKBR3EQ5mVDnIq7ZwLJsX1GGga+GWXGJipdS+Do7e3NOrlE
# HR6pPp19Ajn1aFKsSkBkNcIJZwMMjD+jnaF98tobFb8h7C/ktqaxdjSlVWkGx0vb
# kC4a4yNuQeDqR0eaPg==
# SIG # End signature block
