# Test-CLIOrchestrator-Quick.ps1
# Quick validation test for Phase 7 CLIOrchestrator implementation
# Date: 2025-08-25

param([switch]$SaveResults)

Write-Host "================================================================" -ForegroundColor Cyan
Write-Host "  Unity-Claude CLIOrchestrator Quick Validation Test" -ForegroundColor Cyan
Write-Host "  Started: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor Cyan
Write-Host "================================================================" -ForegroundColor Cyan

$testResults = @{
    TestSuite = "CLIOrchestrator-Quick"
    StartTime = Get-Date
    Results = @()
    Summary = @{ Total = 0; Passed = 0; Failed = 0 }
}

function Add-TestResult {
    param($Name, $Status, $Error = "")
    $testResults.Results += @{ Name = $Name; Status = $Status; Error = $Error; Timestamp = Get-Date }
    $testResults.Summary.Total++
    $testResults.Summary.$Status++
    
    if ($Status -eq "Passed") {
        Write-Host "  ✓ $Name" -ForegroundColor Green
    } else {
        Write-Host "  ✗ $Name" -ForegroundColor Red
        if ($Error) { Write-Host "    Error: $Error" -ForegroundColor Yellow }
    }
}

Write-Host "`nRunning quick validation tests..." -ForegroundColor White

try {
    # Test 1: Module Import
    Write-Host "`n1. Testing module import..." -ForegroundColor Cyan
    Get-Module Unity-Claude-CLIOrchestrator | Remove-Module -Force -ErrorAction SilentlyContinue
    Import-Module ".\Modules\Unity-Claude-CLIOrchestrator\Unity-Claude-CLIOrchestrator.psd1" -Force -ErrorAction Stop
    Add-TestResult -Name "Module Import" -Status "Passed"
} catch {
    Add-TestResult -Name "Module Import" -Status "Failed" -Error $_.Exception.Message
}

try {
    # Test 2: Function Availability
    Write-Host "`n2. Testing function availability..." -ForegroundColor Cyan
    $coreFunctions = @('Extract-ResponseEntities', 'Analyze-ResponseSentiment', 'Find-RecommendationPatterns', 'Invoke-RuleBasedDecision', 'Test-SafetyValidation')
    $missing = @()
    foreach ($func in $coreFunctions) {
        if (-not (Get-Command $func -ErrorAction SilentlyContinue)) {
            $missing += $func
        }
    }
    if ($missing.Count -eq 0) {
        Add-TestResult -Name "Function Availability" -Status "Passed"
    } else {
        Add-TestResult -Name "Function Availability" -Status "Failed" -Error "Missing functions: $($missing -join ', ')"
    }
} catch {
    Add-TestResult -Name "Function Availability" -Status "Failed" -Error $_.Exception.Message
}

try {
    # Test 3: Configuration Files
    Write-Host "`n3. Testing configuration files..." -ForegroundColor Cyan
    $configPath = ".\Modules\Unity-Claude-CLIOrchestrator\Config"
    $configFiles = @('DecisionTrees.json', 'SafetyPolicies.json', 'LearningParameters.json')
    $missing = @()
    foreach ($file in $configFiles) {
        if (-not (Test-Path (Join-Path $configPath $file))) {
            $missing += $file
        }
    }
    if ($missing.Count -eq 0) {
        Add-TestResult -Name "Configuration Files" -Status "Passed"
    } else {
        Add-TestResult -Name "Configuration Files" -Status "Failed" -Error "Missing files: $($missing -join ', ')"
    }
} catch {
    Add-TestResult -Name "Configuration Files" -Status "Failed" -Error $_.Exception.Message
}

try {
    # Test 4: Basic Function Execution
    Write-Host "`n4. Testing basic function execution..." -ForegroundColor Cyan
    $testResponse = "RECOMMENDATION: TEST - Test-SemanticAnalysis.ps1: Run validation test"
    
    # Test pattern recognition
    $patterns = Find-RecommendationPatterns -ResponseText $testResponse
    if ($patterns -and $patterns.Count -gt 0) {
        Add-TestResult -Name "Pattern Recognition" -Status "Passed"
    } else {
        Add-TestResult -Name "Pattern Recognition" -Status "Failed" -Error "No patterns found in test response"
    }
} catch {
    Add-TestResult -Name "Pattern Recognition" -Status "Failed" -Error $_.Exception.Message
}

try {
    # Test 5: Decision Engine Basic Test
    Write-Host "`n5. Testing decision engine..." -ForegroundColor Cyan
    $testAnalysisResult = @{
        Recommendations = @(@{
            Type = "TEST"
            Action = "Run validation test"  
            FilePath = ""
            Confidence = 0.95
            Priority = 1
        })
        ConfidenceAnalysis = @{ OverallConfidence = 0.90; QualityRating = "High" }
        Entities = @{ FilePaths = @(); Commands = @("Test-SemanticAnalysis") }
        ProcessingSuccess = $true
        TotalProcessingTimeMs = 150
    }
    
    $decision = Invoke-RuleBasedDecision -AnalysisResult $testAnalysisResult -DryRun
    if ($decision -and $decision.Decision -in @("PROCEED", "TEST", "CONTINUE")) {
        Add-TestResult -Name "Decision Engine" -Status "Passed"
    } else {
        Add-TestResult -Name "Decision Engine" -Status "Failed" -Error "Unexpected decision: $($decision.Decision)"
    }
} catch {
    Add-TestResult -Name "Decision Engine" -Status "Failed" -Error $_.Exception.Message
}

# Summary
$testResults.EndTime = Get-Date
$testResults.TotalDuration = ($testResults.EndTime - $testResults.StartTime).TotalMilliseconds

Write-Host "`n================================================================" -ForegroundColor Cyan
Write-Host "  QUICK VALIDATION COMPLETE" -ForegroundColor Cyan
Write-Host "================================================================" -ForegroundColor Cyan
Write-Host "Total Tests: $($testResults.Summary.Total)" -ForegroundColor White
Write-Host "Passed: $($testResults.Summary.Passed)" -ForegroundColor Green  
Write-Host "Failed: $($testResults.Summary.Failed)" -ForegroundColor Red
$successRate = [math]::Round(($testResults.Summary.Passed / $testResults.Summary.Total) * 100, 1)
Write-Host "Success Rate: $successRate%" -ForegroundColor $(if ($successRate -ge 80) { "Green" } else { "Yellow" })

if ($SaveResults) {
    $timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
    $resultsFile = "CLIOrchestrator-Quick-TestResults-$timestamp.json"
    $testResults | ConvertTo-Json -Depth 10 | Out-File $resultsFile -Encoding UTF8
    Write-Host "`nTest results saved to: $resultsFile" -ForegroundColor Cyan
}

Write-Host "`nCLIOrchestrator quick validation completed." -ForegroundColor White
# SIG # Begin signature block
# MIIFzgYJKoZIhvcNAQcCoIIFvzCCBbsCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCCsCvJYSfQH4Hcl
# fwUs3UpJ3KQo3SWGXVZ/YA+QeLNc4aCCAzAwggMsMIICFKADAgECAhB1HRbZIqgr
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
# MAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIDgaTyjtHmpAkfY6aKZtqqWc
# kf3aZc8o/h9KKjbLyHLEMA0GCSqGSIb3DQEBAQUABIIBALAOSBwJHBt6GY4UJaDd
# 3ogWfFiIykKm5H46a50RcyqsBT5XZD2wo0h+JuERS8Uig4pl4upzu6rVBCbUFaYz
# SEWLLT9O31cSmF/MyIWFur223cQqu/5qj7EhUCZjZZNf8AIZNCM82lDMSQ612WIh
# BbJQ7h9CUgMZ0tqicZPwXB2SpONoGBhHq5wb9xYdZ7ExyerrWG+otImmaZNtea5W
# 9aR8bNChs90zabCZ6NylRZNQ+Yg/1lczEPkcsE69ebZSB6tvB96WrzmmpiEZiXPt
# 0XcihRtKUpoB/vI/1XqFcKb7EVNdBv7EbTLxE5MTod/KR6tcK+n1SWmu4wm9Y8MT
# pXw=
# SIG # End signature block
