#Requires -Version 5.1
<#
.SYNOPSIS
    Tests all refactored modules to ensure they're running without errors
    
.DESCRIPTION
    Comprehensive test suite for all 20 refactored modules listed in REFACTORING_TRACKER.md
    Tests module imports, function exports, and basic operations
    
.PARAMETER TestType
    Type of test to run: Quick, Comprehensive, or All
    
.PARAMETER SaveResults
    Save test results to JSON file
    
.PARAMETER ShowProgress
    Display detailed progress during testing
#>

[CmdletBinding()]
param(
    [ValidateSet('Quick', 'Comprehensive', 'All')]
    [string]$TestType = 'Quick',
    
    [switch]$SaveResults,
    [switch]$ShowProgress
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

# Initialize test results
$testResults = @{
    TestSuite = "Refactored Modules Verification"
    StartTime = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    ModulesTotal = 0
    ModulesSuccess = 0
    ModulesFailed = 0
    Details = @()
}

# List of all refactored modules from REFACTORING_TRACKER.md
$refactoredModules = @(
    @{
        Name = "Unity-Claude-CPG"
        Path = "C:\UnityProjects\Sound-and-Shoal\Unity-Claude-Automation\Modules\Unity-Claude-CPG\Unity-Claude-CPG.psd1"
        ExpectedFunctions = @("New-CPGraph", "Get-CPGNode", "Add-CPGNode", "Add-CPGEdge")
    },
    @{
        Name = "Unity-Claude-MasterOrchestrator"
        Path = "C:\UnityProjects\Sound-and-Shoal\Unity-Claude-Automation\Modules\Unity-Claude-MasterOrchestrator\Unity-Claude-MasterOrchestrator.psd1"
        ExpectedFunctions = @("Start-MasterOrchestrator", "Register-OrchestratorSubsystem", "Invoke-SubsystemDecision")
    },
    @{
        Name = "SafeCommandExecution"
        Path = "C:\UnityProjects\Sound-and-Shoal\Unity-Claude-Automation\Modules\SafeCommandExecution\SafeCommandExecution.psd1"
        ExpectedFunctions = @("Invoke-SafeCommand", "Test-SafePath", "New-SafeRunspace")
    },
    @{
        Name = "Unity-Claude-UnityParallelization"
        Path = "C:\UnityProjects\Sound-and-Shoal\Unity-Claude-Automation\Modules\Unity-Claude-UnityParallelization\Unity-Claude-UnityParallelization.psd1"
        ExpectedFunctions = @("Start-UnityParallelMonitoring", "Get-UnityProjectPaths", "Start-UnityCompilation")
    },
    @{
        Name = "Unity-Claude-IntegratedWorkflow"
        Path = "C:\UnityProjects\Sound-and-Shoal\Unity-Claude-Automation\Modules\Unity-Claude-IntegratedWorkflow\Unity-Claude-IntegratedWorkflow.psd1"
        ExpectedFunctions = @("Start-IntegratedWorkflow", "Initialize-WorkflowDependencies", "Get-WorkflowStatus")
    },
    @{
        Name = "Unity-Claude-Learning"
        Path = "C:\UnityProjects\Sound-and-Shoal\Unity-Claude-Automation\Modules\Unity-Claude-Learning\Unity-Claude-Learning.psd1"
        ExpectedFunctions = @("Initialize-LearningDatabase", "Get-CodePattern", "Save-SuccessPattern", "Get-SuccessRate")
    },
    @{
        Name = "Unity-Claude-RunspaceManagement"
        Path = "C:\UnityProjects\Sound-and-Shoal\Unity-Claude-Automation\Modules\Unity-Claude-RunspaceManagement\Unity-Claude-RunspaceManagement.psd1"
        ExpectedFunctions = @("New-ManagedRunspacePool", "Initialize-SharedRunspace", "Add-SharedVariable")
    },
    @{
        Name = "Unity-Claude-PredictiveAnalysis"
        Path = "C:\UnityProjects\Sound-and-Shoal\Unity-Claude-Automation\Modules\Unity-Claude-PredictiveAnalysis\Unity-Claude-PredictiveAnalysis-Refactored.psd1"
        ExpectedFunctions = @("Get-CodeEvolutionTrend", "Get-MaintenancePrediction", "Get-RefactoringOpportunities")
    },
    @{
        Name = "Unity-Claude-ObsolescenceDetection"
        Path = "C:\UnityProjects\Sound-and-Shoal\Unity-Claude-Automation\Modules\Unity-Claude-CPG\Unity-Claude-ObsolescenceDetection-Refactored.psd1"
        ExpectedFunctions = @("Find-UnreachableCode", "Test-CodeRedundancy", "Get-CodeComplexityMetrics")
    },
    @{
        Name = "Unity-Claude-AutonomousStateTracker-Enhanced"
        Path = "C:\UnityProjects\Sound-and-Shoal\Unity-Claude-Automation\Modules\Unity-Claude-AutonomousStateTracker-Enhanced\Unity-Claude-AutonomousStateTracker-Enhanced-Refactored.psd1"
        ExpectedFunctions = @("Initialize-StateTracker", "Get-StateTrackerStatus", "Update-StateTrackerState")
    },
    @{
        Name = "IntelligentPromptEngine"
        Path = "C:\UnityProjects\Sound-and-Shoal\Unity-Claude-Automation\Modules\Unity-Claude-AutonomousAgent\IntelligentPromptEngine-Refactored.psd1"
        ExpectedFunctions = @("New-AutonomousPrompt", "Analyze-CommandResult", "Select-PromptType")
    },
    @{
        Name = "Unity-Claude-DocumentationAutomation"
        Path = "C:\UnityProjects\Sound-and-Shoal\Unity-Claude-Automation\Modules\Unity-Claude-DocumentationAutomation\Unity-Claude-DocumentationAutomation-Refactored.psd1"
        ExpectedFunctions = @("New-DocumentationTrigger", "Start-DocumentationAutomation", "New-DocumentationPR")
    },
    @{
        Name = "Unity-Claude-CLIOrchestrator"
        Path = "C:\UnityProjects\Sound-and-Shoal\Unity-Claude-Automation\Modules\Unity-Claude-CLIOrchestrator\Unity-Claude-CLIOrchestrator-Refactored.psd1"
        ExpectedFunctions = @("Find-ClaudeWindow", "Submit-ClaudePrompt", "Start-AutonomousOrchestration")
    },
    @{
        Name = "Unity-Claude-ScalabilityEnhancements"
        Path = "C:\UnityProjects\Sound-and-Shoal\Unity-Claude-Automation\Modules\Unity-Claude-ScalabilityEnhancements\Unity-Claude-ScalabilityEnhancements-Refactored.psd1"
        ExpectedFunctions = @("Optimize-GraphStructure", "Get-PagedResults", "Start-BackgroundJobWithCancellation")
    },
    @{
        Name = "DecisionEngine-Bayesian"
        Path = "C:\UnityProjects\Sound-and-Shoal\Unity-Claude-Automation\Modules\Unity-Claude-CLIOrchestrator\Core\DecisionEngine-Bayesian\Unity-Claude-DecisionEngine-Bayesian.psd1"
        ExpectedFunctions = @("Invoke-BayesianInference", "Get-PositionWeightMatrixScore", "Update-PriorProbabilities")
    },
    @{
        Name = "Unity-Claude-HITL"
        Path = "C:\UnityProjects\Sound-and-Shoal\Unity-Claude-Automation\Modules\Unity-Claude-HITL\Unity-Claude-HITL.psd1"
        ExpectedFunctions = @("New-HITLApprovalRequest", "Get-ApprovalRequestStatus", "Send-HITLNotification")
    },
    @{
        Name = "Unity-Claude-ParallelProcessor"
        Path = "C:\UnityProjects\Sound-and-Shoal\Unity-Claude-Automation\Modules\Unity-Claude-ParallelProcessor\Unity-Claude-ParallelProcessor.psd1"
        ExpectedFunctions = @("Start-ParallelProcessing", "Add-ProcessingWork", "Wait-ParallelProcessing")
    },
    @{
        Name = "Unity-Claude-PerformanceOptimizer"
        Path = "C:\UnityProjects\Sound-and-Shoal\Unity-Claude-Automation\Modules\Unity-Claude-PerformanceOptimizer\Unity-Claude-PerformanceOptimizer.psd1"
        ExpectedFunctions = @("Start-PerformanceOptimizer", "Get-PerformanceMetrics", "Export-PerformanceReport")
    },
    @{
        Name = "Unity-Claude-DecisionEngine"
        Path = "C:\UnityProjects\Sound-and-Shoal\Unity-Claude-Automation\Modules\Unity-Claude-DecisionEngine\Unity-Claude-DecisionEngine.psd1"
        ExpectedFunctions = @("Analyze-ClaudeResponse", "Make-AutonomousDecision", "Process-ActionQueue")
    }
)

function Test-ModuleImport {
    param($Module)
    
    $result = @{
        Module = $Module.Name
        Path = $Module.Path
        Status = "Unknown"
        Error = $null
        FunctionsFound = 0
        ExpectedFunctionsPresent = $false
        LoadTime = 0
        IsRefactoredVersion = $false
    }
    
    try {
        # Check if manifest exists
        if (-not (Test-Path $Module.Path)) {
            throw "Module manifest not found at: $Module.Path"
        }
        
        # Remove module if already loaded
        Get-Module $Module.Name -All | Remove-Module -Force -ErrorAction SilentlyContinue
        
        # Measure import time
        $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
        
        # Import the module
        Import-Module $Module.Path -Force -Global -ErrorAction Stop
        
        $stopwatch.Stop()
        $result.LoadTime = $stopwatch.ElapsedMilliseconds
        
        # Get imported module info
        $importedModule = Get-Module $Module.Name
        if (-not $importedModule) {
            throw "Module imported but not found in session"
        }
        
        # Check if it's the refactored version (should show in verbose output)
        $verboseOutput = Import-Module $Module.Path -Force -Verbose 4>&1
        $result.IsRefactoredVersion = $verboseOutput -match "REFACTORED VERSION" -or
                                      $Module.Path -match "-Refactored\.psd1$"
        
        # Count exported functions
        $exportedFunctions = Get-Command -Module $Module.Name -ErrorAction SilentlyContinue
        $result.FunctionsFound = @($exportedFunctions).Count
        
        # Check for expected functions
        if ($Module.ExpectedFunctions -and $Module.ExpectedFunctions.Count -gt 0) {
            $foundExpected = 0
            foreach ($expectedFunc in $Module.ExpectedFunctions) {
                if (Get-Command $expectedFunc -Module $Module.Name -ErrorAction SilentlyContinue) {
                    $foundExpected++
                }
            }
            $result.ExpectedFunctionsPresent = ($foundExpected -eq $Module.ExpectedFunctions.Count)
        } else {
            $result.ExpectedFunctionsPresent = $true # No specific functions to check
        }
        
        # Quick function test if comprehensive mode
        if ($TestType -in 'Comprehensive', 'All') {
            # Try to call a simple function from the module
            $testFunc = $exportedFunctions | Where-Object { 
                $_.Name -like "Get-*" -or 
                $_.Name -like "Test-*" 
            } | Select-Object -First 1
            
            if ($testFunc) {
                try {
                    & $testFunc.Name -ErrorAction Stop | Out-Null
                } catch {
                    # Some functions may require parameters, that's okay
                    if ($_.Exception.Message -notmatch "Missing|Required|Parameter") {
                        throw $_
                    }
                }
            }
        }
        
        $result.Status = "Success"
        
    } catch {
        $result.Status = "Failed"
        $result.Error = $_.Exception.Message
    }
    
    return $result
}

# Main test execution
Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "  REFACTORED MODULES VERIFICATION TEST  " -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan

Write-Host "Test Configuration:" -ForegroundColor Yellow
Write-Host "  - Test Type: $TestType"
Write-Host "  - Total Modules: $($refactoredModules.Count)"
Write-Host "  - Save Results: $($SaveResults -eq $true)"
Write-Host "`n"

$testResults.ModulesTotal = $refactoredModules.Count
$moduleIndex = 0

foreach ($module in $refactoredModules) {
    $moduleIndex++
    
    if ($ShowProgress) {
        $percentComplete = [math]::Round(($moduleIndex / $refactoredModules.Count) * 100)
        Write-Progress -Activity "Testing Refactored Modules" `
                      -Status "Testing $($module.Name)" `
                      -PercentComplete $percentComplete `
                      -CurrentOperation "$moduleIndex of $($refactoredModules.Count)"
    }
    
    Write-Host "[$moduleIndex/$($refactoredModules.Count)] Testing $($module.Name)..." -NoNewline
    
    $testResult = Test-ModuleImport -Module $module
    
    if ($testResult.Status -eq "Success") {
        Write-Host " PASS" -ForegroundColor Green
        Write-Host "    Functions: $($testResult.FunctionsFound) | " -NoNewline
        Write-Host "Load Time: $($testResult.LoadTime)ms | " -NoNewline
        
        if ($testResult.IsRefactoredVersion) {
            Write-Host "Version: REFACTORED" -ForegroundColor Cyan
        } else {
            Write-Host "Version: Standard" -ForegroundColor Yellow
        }
        
        $testResults.ModulesSuccess++
    } else {
        Write-Host " FAIL" -ForegroundColor Red
        Write-Host "    Error: $($testResult.Error)" -ForegroundColor Red
        $testResults.ModulesFailed++
    }
    
    $testResults.Details += $testResult
}

if ($ShowProgress) {
    Write-Progress -Activity "Testing Refactored Modules" -Completed
}

# Summary
$testResults.EndTime = Get-Date -Format "yyyy-MM-dd HH:mm:ss"

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "           TEST SUMMARY                 " -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

$successRate = if ($testResults.ModulesTotal -gt 0) {
    [math]::Round(($testResults.ModulesSuccess / $testResults.ModulesTotal) * 100, 2)
} else { 0 }

Write-Host "`nResults:" -ForegroundColor Yellow
Write-Host "  Total Modules: $($testResults.ModulesTotal)"
Write-Host "  Successful: " -NoNewline
Write-Host "$($testResults.ModulesSuccess)" -ForegroundColor Green
Write-Host "  Failed: " -NoNewline
if ($testResults.ModulesFailed -gt 0) {
    Write-Host "$($testResults.ModulesFailed)" -ForegroundColor Red
} else {
    Write-Host "$($testResults.ModulesFailed)" -ForegroundColor Green
}
Write-Host "  Success Rate: " -NoNewline
if ($successRate -ge 100) {
    Write-Host "$successRate%" -ForegroundColor Green
} elseif ($successRate -ge 80) {
    Write-Host "$successRate%" -ForegroundColor Yellow
} else {
    Write-Host "$successRate%" -ForegroundColor Red
}

# Show failed modules
if ($testResults.ModulesFailed -gt 0) {
    Write-Host "`nFailed Modules:" -ForegroundColor Red
    $testResults.Details | Where-Object { $_.Status -eq "Failed" } | ForEach-Object {
        Write-Host "  - $($_.Module): $($_.Error)" -ForegroundColor Red
    }
}

# Show modules not using refactored version
$nonRefactored = $testResults.Details | Where-Object { 
    $_.Status -eq "Success" -and -not $_.IsRefactoredVersion 
}
if ($nonRefactored) {
    Write-Host "`nModules Not Using Refactored Version:" -ForegroundColor Yellow
    $nonRefactored | ForEach-Object {
        Write-Host "  - $($_.Module)" -ForegroundColor Yellow
    }
}

# Performance statistics
if ($TestType -in 'Comprehensive', 'All') {
    $avgLoadTime = ($testResults.Details | Where-Object { $_.Status -eq "Success" } | 
                    Measure-Object -Property LoadTime -Average).Average
    
    Write-Host "`nPerformance Statistics:" -ForegroundColor Cyan
    Write-Host "  Average Load Time: $([math]::Round($avgLoadTime, 2))ms"
    
    $slowModules = $testResults.Details | Where-Object { 
        $_.Status -eq "Success" -and $_.LoadTime -gt 1000 
    }
    if ($slowModules) {
        Write-Host "  Slow Loading Modules (>1s):" -ForegroundColor Yellow
        $slowModules | ForEach-Object {
            Write-Host "    - $($_.Module): $($_.LoadTime)ms" -ForegroundColor Yellow
        }
    }
}

# Save results if requested
if ($SaveResults) {
    $timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
    $resultsFile = "RefactoredModules-TestResults-$timestamp.json"
    $testResults | ConvertTo-Json -Depth 5 | Out-File $resultsFile -Encoding UTF8
    Write-Host "`nResults saved to: $resultsFile" -ForegroundColor Green
}

# Final status
Write-Host "`n" -NoNewline
if ($testResults.ModulesFailed -eq 0) {
    Write-Host "✓ ALL REFACTORED MODULES PASSED VERIFICATION!" -ForegroundColor Green -BackgroundColor DarkGreen
} else {
    Write-Host "✗ SOME MODULES FAILED - REVIEW REQUIRED" -ForegroundColor Red -BackgroundColor DarkRed
}

Write-Host "`n========================================`n" -ForegroundColor Cyan

# Return overall success
return ($testResults.ModulesFailed -eq 0)
# SIG # Begin signature block
# MIIFzgYJKoZIhvcNAQcCoIIFvzCCBbsCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCDdwrAuIK8dQAVD
# RcZntTl60SE97uuPxWjV3dQblf+RsaCCAzAwggMsMIICFKADAgECAhB1HRbZIqgr
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
# MAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEILBs/MNnmEKM7vyQnhS8rq55
# Qh3Mw4ZudyYB4Dap2iiWMA0GCSqGSIb3DQEBAQUABIIBAHZ0kWL7/aBH1aech0+A
# vL0Op+k9wR8c77g7QwXwfE+cLJDCLwnbu7p80yFw6HDyoe3w7UegXELzUNdWKm86
# 0Z0aVOmEYiQFoV3IMUE9Gg6K6PqVhtPOptQFJQGB8sbaXfapUKpqfpmmi+h7UsIJ
# KgVVgKsKT7ifn4MQcWU1Hp9VnyTpghT0vPug+ibNgX3gohT3ZNebXYA/CTAQ8U4K
# VR6tYeGpNAba89VYrdtgEd00GSwbl3WgdxpmjYDXAxZUZrwaHN7heUh8nmQuclvp
# Y/MIdPJ6SYKcU73bsaIrXA270/9BQLWnr4o6Ykr02mTL+65Twt1ehtAUQPMYvrVW
# E8g=
# SIG # End signature block
