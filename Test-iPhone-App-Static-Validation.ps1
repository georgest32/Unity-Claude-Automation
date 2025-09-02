# Test-iPhone-App-Static-Validation.ps1
# Comprehensive static code validation for iPhone App implementation
# Tests Hour 7-8 enhanced cancellation and progress tracking features

param(
    [string]$ProjectPath = ".\iOS-App\AgentDashboard",
    [string]$OutputFile = "iPhone_App_Static_Validation_Results_$(Get-Date -Format 'yyyyMMdd_HHmmss').txt"
)

function Write-TestLog {
    param([string]$Message, [string]$Level = "INFO")
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logMessage = "[$timestamp] [$Level] $Message"
    Write-Host $logMessage
    Add-Content -Path $OutputFile -Value $logMessage
}

function Test-FileExists {
    param([string]$FilePath, [string]$Description)
    
    if (Test-Path $FilePath) {
        Write-TestLog "✅ PASS: $Description - File exists: $FilePath" "PASS"
        return $true
    } else {
        Write-TestLog "❌ FAIL: $Description - File missing: $FilePath" "FAIL"
        return $false
    }
}

function Test-SwiftSyntax {
    param([string]$FilePath, [string]$ComponentName)
    
    $content = Get-Content $FilePath -Raw -ErrorAction SilentlyContinue
    if (-not $content) {
        Write-TestLog "❌ FAIL: $ComponentName - Could not read file content" "FAIL"
        return $false
    }
    
    # Basic Swift syntax checks
    $syntaxChecks = @(
        @{ Pattern = "import \w+"; Description = "Import statements" },
        @{ Pattern = "struct \w+.*\{"; Description = "Struct declarations" },
        @{ Pattern = "@Reducer"; Description = "TCA Reducer annotation" },
        @{ Pattern = "enum Action"; Description = "TCA Action enum" },
        @{ Pattern = "var body:"; Description = "SwiftUI/TCA body implementation" }
    )
    
    $passed = 0
    $total = $syntaxChecks.Count
    
    foreach ($check in $syntaxChecks) {
        if ($content -match $check.Pattern) {
            Write-TestLog "  ✅ $($check.Description) - Found" "DETAIL"
            $passed++
        } else {
            Write-TestLog "  ❌ $($check.Description) - Missing" "DETAIL"
        }
    }
    
    $success = ($passed -eq $total)
    Write-TestLog "$(if($success){'✅ PASS'}else{'❌ FAIL'}): $ComponentName - Syntax check: $passed/$total" $(if($success){"PASS"}else{"FAIL"})
    return $success
}

function Test-TCACompliance {
    param([string]$FilePath, [string]$FeatureName)
    
    $content = Get-Content $FilePath -Raw -ErrorAction SilentlyContinue
    if (-not $content) { return $false }
    
    # TCA compliance checks
    $tcaChecks = @(
        @{ Pattern = "@Reducer\s+struct $FeatureName"; Description = "TCA Reducer struct" },
        @{ Pattern = "struct State.*Equatable"; Description = "Equatable State" },
        @{ Pattern = "enum Action.*Equatable"; Description = "Equatable Action" },
        @{ Pattern = "var body:.*Reducer"; Description = "Reducer body implementation" },
        @{ Pattern = "Reduce.*state, action"; Description = "Reduce function" },
        @{ Pattern = "switch action"; Description = "Action switching" }
    )
    
    $passed = 0
    foreach ($check in $tcaChecks) {
        if ($content -match $check.Pattern) {
            Write-TestLog "  ✅ $($check.Description)" "DETAIL"
            $passed++
        } else {
            Write-TestLog "  ❌ $($check.Description)" "DETAIL"
        }
    }
    
    $success = ($passed -ge 4) # At least 4/6 checks should pass
    Write-TestLog "$(if($success){'✅ PASS'}else{'❌ FAIL'}): $FeatureName - TCA compliance: $passed/$($tcaChecks.Count)" $(if($success){"PASS"}else{"FAIL"})
    return $success
}

# Initialize test results
Write-TestLog "=== iPhone App Static Validation Test Suite ===" "INFO"
Write-TestLog "Testing enhanced cancellation support and advanced progress tracking features" "INFO"
Write-TestLog "Project Path: $ProjectPath" "INFO"

$testResults = @{
    FilesExist = 0
    SyntaxValid = 0
    TCACompliant = 0
    TotalTests = 0
}

# Test 1: Core File Existence
Write-TestLog "`n--- Test 1: Core File Existence ---" "INFO"

$coreFiles = @(
    @{ Path = "$ProjectPath\AgentDashboard\TCA\CommandQueueFeature.swift"; Name = "CommandQueueFeature" },
    @{ Path = "$ProjectPath\AgentDashboard\Models\Models.swift"; Name = "Enhanced Models" },
    @{ Path = "$ProjectPath\AgentDashboard\Views\Queue\CommandQueueView.swift"; Name = "CommandQueueView" },
    @{ Path = "$ProjectPath\AgentDashboard\Views\Queue\SelectableCommandRow.swift"; Name = "SelectableCommandRow" },
    @{ Path = "$ProjectPath\AgentDashboard\Views\Analytics\QueueAnalyticsView.swift"; Name = "QueueAnalyticsView" },
    @{ Path = "$ProjectPath\AgentDashboard\TCA\PromptFeature.swift"; Name = "PromptFeature Integration" }
)

foreach ($file in $coreFiles) {
    if (Test-FileExists $file.Path $file.Name) {
        $testResults.FilesExist++
    }
    $testResults.TotalTests++
}

# Test 2: Swift Syntax Validation
Write-TestLog "`n--- Test 2: Swift Syntax Validation ---" "INFO"

foreach ($file in $coreFiles) {
    if (Test-Path $file.Path) {
        if (Test-SwiftSyntax $file.Path $file.Name) {
            $testResults.SyntaxValid++
        }
    }
}

# Test 3: TCA Architecture Compliance
Write-TestLog "`n--- Test 3: TCA Architecture Compliance ---" "INFO"

$tcaFeatures = @(
    @{ Path = "$ProjectPath\AgentDashboard\TCA\CommandQueueFeature.swift"; Name = "CommandQueueFeature" },
    @{ Path = "$ProjectPath\AgentDashboard\TCA\PromptFeature.swift"; Name = "PromptFeature" }
)

foreach ($feature in $tcaFeatures) {
    if (Test-Path $feature.Path) {
        if (Test-TCACompliance $feature.Path $feature.Name) {
            $testResults.TCACompliant++
        }
    }
}

# Test 4: Hour 7-8 Feature Implementation Validation
Write-TestLog "`n--- Test 4: Hour 7-8 Feature Validation ---" "INFO"

# Test CommandQueueFeature for Hour 7 features
$commandQueuePath = "$ProjectPath\AgentDashboard\TCA\CommandQueueFeature.swift"
if (Test-Path $commandQueuePath) {
    $content = Get-Content $commandQueuePath -Raw
    
    # Hour 7: Enhanced cancellation features
    $hour7Features = @(
        "isInEditMode",
        "selectedCommandIDs", 
        "confirmationDialog",
        "undoableOperations",
        "enterEditMode",
        "exitEditMode",
        "toggleCommandSelection",
        "cancelSelectedCommands",
        "showConfirmationDialog"
    )
    
    $hour7Found = 0
    foreach ($feature in $hour7Features) {
        if ($content -match $feature) {
            Write-TestLog "  ✅ Hour 7 feature: $feature" "DETAIL"
            $hour7Found++
        } else {
            Write-TestLog "  ❌ Hour 7 feature missing: $feature" "DETAIL"
        }
    }
    
    Write-TestLog "$(if($hour7Found -eq $hour7Features.Count){'✅ PASS'}else{'❌ FAIL'}): Hour 7 Enhanced Cancellation - $hour7Found/$($hour7Features.Count) features" $(if($hour7Found -eq $hour7Features.Count){"PASS"}else{"FAIL"})
    
    # Hour 8: Advanced progress tracking features
    $hour8Features = @(
        "queueAnalytics",
        "isShowingAnalytics",
        "executionMetrics",
        "trendHistory",
        "updateDetailedProgress",
        "generateAnalytics",
        "DetailedExecutionProgress",
        "ExecutionPhase"
    )
    
    $hour8Found = 0
    foreach ($feature in $hour8Features) {
        if ($content -match $feature) {
            Write-TestLog "  ✅ Hour 8 feature: $feature" "DETAIL"
            $hour8Found++
        } else {
            Write-TestLog "  ❌ Hour 8 feature missing: $feature" "DETAIL"
        }
    }
    
    Write-TestLog "$(if($hour8Found -eq $hour8Features.Count){'✅ PASS'}else{'❌ FAIL'}): Hour 8 Advanced Progress - $hour8Found/$($hour8Features.Count) features" $(if($hour8Found -eq $hour8Features.Count){"PASS"}else{"FAIL"})
}

# Test 5: UI Component Validation
Write-TestLog "`n--- Test 5: UI Component Validation ---" "INFO"

# Test SelectableCommandRow for multi-select features
$selectableRowPath = "$ProjectPath\AgentDashboard\Views\Queue\SelectableCommandRow.swift"
if (Test-Path $selectableRowPath) {
    $content = Get-Content $selectableRowPath -Raw
    
    $uiFeatures = @(
        "isSelected.*Bool",
        "isInEditMode.*Bool",
        "onSelectionToggle",
        "EnhancedProgressBar",
        "DetailedProgressInfo",
        "ExecutionPhase",
        "etaDescription"
    )
    
    $uiFound = 0
    foreach ($feature in $uiFeatures) {
        if ($content -match $feature) {
            Write-TestLog "  ✅ UI feature: $feature" "DETAIL"
            $uiFound++
        } else {
            Write-TestLog "  ❌ UI feature missing: $feature" "DETAIL"
        }
    }
    
    Write-TestLog "$(if($uiFound -eq $uiFeatures.Count){'✅ PASS'}else{'❌ FAIL'}): UI Components - $uiFound/$($uiFeatures.Count) features" $(if($uiFound -eq $uiFeatures.Count){"PASS"}else{"FAIL"})
}

# Test 6: Analytics Dashboard Validation
Write-TestLog "`n--- Test 6: Analytics Dashboard Validation ---" "INFO"

$analyticsPath = "$ProjectPath\AgentDashboard\Views\Analytics\QueueAnalyticsView.swift"
if (Test-Path $analyticsPath) {
    $content = Get-Content $analyticsPath -Raw
    
    $analyticsFeatures = @(
        "QueueAnalyticsView",
        "Charts",
        "AnalyticsTab",
        "MetricCard",
        "ResourceBar",
        "efficiencyScore",
        "generateRecommendations"
    )
    
    $analyticsFound = 0
    foreach ($feature in $analyticsFeatures) {
        if ($content -match $feature) {
            Write-TestLog "  ✅ Analytics feature: $feature" "DETAIL"
            $analyticsFound++
        } else {
            Write-TestLog "  ❌ Analytics feature missing: $feature" "DETAIL"
        }
    }
    
    Write-TestLog "$(if($analyticsFound -eq $analyticsFeatures.Count){'✅ PASS'}else{'❌ FAIL'}): Analytics Dashboard - $analyticsFound/$($analyticsFeatures.Count) features" $(if($analyticsFound -eq $analyticsFeatures.Count){"PASS"}else{"FAIL"})
}

# Final Results Summary
Write-TestLog "`n=== FINAL TEST RESULTS ===" "INFO"
Write-TestLog "Files Exist: $($testResults.FilesExist)/$($testResults.TotalTests)" "RESULT"
Write-TestLog "Syntax Valid: $($testResults.SyntaxValid)/$($testResults.TotalTests)" "RESULT"  
Write-TestLog "TCA Compliant: $($testResults.TCACompliant)/$($tcaFeatures.Count)" "RESULT"

$overallScore = [math]::Round((($testResults.FilesExist + $testResults.SyntaxValid + $testResults.TCACompliant) / ($testResults.TotalTests + $tcaFeatures.Count)) * 100, 1)
Write-TestLog "Overall Score: $overallScore%" "RESULT"

if ($overallScore -ge 90) {
    Write-TestLog "🎉 EXCELLENT: Implementation ready for compilation testing" "SUCCESS"
} elseif ($overallScore -ge 80) {
    Write-TestLog "✅ GOOD: Implementation mostly complete with minor issues" "SUCCESS"
} elseif ($overallScore -ge 70) {
    Write-TestLog "⚠️  ACCEPTABLE: Implementation needs some improvements" "WARNING"
} else {
    Write-TestLog "❌ NEEDS WORK: Implementation has significant issues" "ERROR"
}

Write-TestLog "`nTest results saved to: $OutputFile" "INFO"
Write-TestLog "=== TEST COMPLETE ===" "INFO"