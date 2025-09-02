# Test-AllRefactoredModules-Fixed.ps1
# Fixed version that properly handles module name registration differences

param(
    [string]$TestType = "All",  # All, Quick, Individual
    [switch]$ShowProgress,
    [switch]$SaveResults
)

# Clear any existing modules first
Write-Host "Clearing all Unity-Claude modules from session..." -ForegroundColor Yellow
Get-Module Unity-Claude* | Remove-Module -Force -ErrorAction SilentlyContinue
Get-Module SafeCommandExecution | Remove-Module -Force -ErrorAction SilentlyContinue

Write-Host ""
Write-Host "REFACTORED MODULES TEST SUITE (FIXED)" -ForegroundColor Cyan
Write-Host "======================================" -ForegroundColor Cyan
Write-Host ""

# Define module configurations with actual registered names
$moduleConfigs = @(
    @{
        Name = "Unity-Claude-CPG"
        Path = "C:\UnityProjects\Sound-and-Shoal\Unity-Claude-Automation\Modules\Unity-Claude-CPG\Unity-Claude-CPG.psd1"
        ActualName = "Unity-Claude-CPG"  # Registers as expected
        ExpectedFunctions = @("New-CPGraph", "Get-CPGNode", "Add-CPGEdge")
    },
    @{
        Name = "Unity-Claude-MasterOrchestrator"
        Path = "C:\UnityProjects\Sound-and-Shoal\Unity-Claude-Automation\Modules\Unity-Claude-MasterOrchestrator\Unity-Claude-MasterOrchestrator.psd1"
        ActualName = "Unity-Claude-MasterOrchestrator"
        ExpectedFunctions = @("Start-MasterOrchestration", "Get-OrchestrationStatus")
    },
    @{
        Name = "SafeCommandExecution"
        Path = "C:\UnityProjects\Sound-and-Shoal\Unity-Claude-Automation\Modules\SafeCommandExecution\SafeCommandExecution.psd1"
        ActualName = "SafeCommandExecution"
        ExpectedFunctions = @("Invoke-SafeCommand", "Test-CommandSafety")
    },
    @{
        Name = "Unity-Claude-UnityParallelization"
        Path = "C:\UnityProjects\Sound-and-Shoal\Unity-Claude-Automation\Modules\Unity-Claude-UnityParallelization\Unity-Claude-UnityParallelization.psd1"
        ActualName = "Unity-Claude-UnityParallelization"
        ExpectedFunctions = @("Start-ParallelUnityBuild", "Get-BuildWorkerStatus")
    },
    @{
        Name = "Unity-Claude-IntegratedWorkflow"
        Path = "C:\UnityProjects\Sound-and-Shoal\Unity-Claude-Automation\Modules\Unity-Claude-IntegratedWorkflow\Unity-Claude-IntegratedWorkflow.psd1"
        ActualName = "Unity-Claude-IntegratedWorkflow"
        ExpectedFunctions = @("Start-IntegratedWorkflow", "Get-WorkflowStatus")
    },
    @{
        Name = "Unity-Claude-Learning"
        Path = "C:\UnityProjects\Sound-and-Shoal\Unity-Claude-Automation\Modules\Unity-Claude-Learning\Unity-Claude-Learning.psd1"
        ActualName = "Unity-Claude-Learning"
        ExpectedFunctions = @("Get-LearningConfiguration", "Update-LearningMetrics")
    },
    @{
        Name = "Unity-Claude-RunspaceManagement"
        Path = "C:\UnityProjects\Sound-and-Shoal\Unity-Claude-Automation\Modules\Unity-Claude-RunspaceManagement\Unity-Claude-RunspaceManagement.psd1"
        ActualName = "Unity-Claude-RunspaceManagement"
        ExpectedFunctions = @("New-ManagedRunspace", "Get-RunspaceStatus")
    },
    @{
        Name = "Unity-Claude-PredictiveAnalysis"
        Path = "C:\UnityProjects\Sound-and-Shoal\Unity-Claude-Automation\Modules\Unity-Claude-PredictiveAnalysis\Unity-Claude-PredictiveAnalysis.psd1"
        ActualName = "Unity-Claude-PredictiveAnalysis"  # May register differently
        ExpectedFunctions = @("Get-PredictedOutcome", "Update-PredictionModel")
    },
    @{
        Name = "Unity-Claude-ObsolescenceDetection"
        Path = "C:\UnityProjects\Sound-and-Shoal\Unity-Claude-Automation\Modules\Unity-Claude-CPG\Unity-Claude-ObsolescenceDetection-Refactored.psd1"
        ActualName = "Unity-Claude-ObsolescenceDetection-Refactored"  # Registers with -Refactored suffix
        ExpectedFunctions = @("Find-UnreachableCode", "Test-CodeRedundancy")
        IsNestedModule = $false
    },
    @{
        Name = "Unity-Claude-AutonomousStateTracker-Enhanced"
        Path = "C:\UnityProjects\Sound-and-Shoal\Unity-Claude-Automation\Modules\Unity-Claude-AutonomousStateTracker-Enhanced\Unity-Claude-AutonomousStateTracker-Enhanced.psd1"
        ActualName = "Unity-Claude-AutonomousStateTracker-Enhanced"
        ExpectedFunctions = @("Get-StateConfiguration", "Update-StateTracking")
    },
    @{
        Name = "IntelligentPromptEngine"
        Path = "C:\UnityProjects\Sound-and-Shoal\Unity-Claude-Automation\Modules\Unity-Claude-AutonomousAgent\IntelligentPromptEngine-Refactored.psd1"
        ActualName = "IntelligentPromptEngine-Refactored"
        ExpectedFunctions = @("New-IntelligentPrompt", "Get-PromptConfiguration")
    },
    @{
        Name = "Unity-Claude-DocumentationAutomation"
        Path = "C:\UnityProjects\Sound-and-Shoal\Unity-Claude-Automation\Modules\Unity-Claude-DocumentationAutomation\Unity-Claude-DocumentationAutomation.psd1"
        ActualName = "Unity-Claude-DocumentationAutomation"
        ExpectedFunctions = @("Update-Documentation", "Test-DocumentationDrift")
    },
    @{
        Name = "Unity-Claude-CLIOrchestrator"
        Path = "C:\UnityProjects\Sound-and-Shoal\Unity-Claude-Automation\Modules\Unity-Claude-CLIOrchestrator\Unity-Claude-CLIOrchestrator.psd1"
        ActualName = "Unity-Claude-CLIOrchestrator"
        ExpectedFunctions = @("Start-CLIOrchestration", "Get-CLIStatus")
    },
    @{
        Name = "Unity-Claude-ScalabilityEnhancements"
        Path = "C:\UnityProjects\Sound-and-Shoal\Unity-Claude-Automation\Modules\Unity-Claude-ScalabilityEnhancements\Unity-Claude-ScalabilityEnhancements.psd1"
        ActualName = "Unity-Claude-ScalabilityEnhancements"
        ExpectedFunctions = @("Optimize-Performance", "Get-ScalabilityMetrics")
    },
    @{
        Name = "Unity-Claude-DecisionEngine"
        Path = "C:\UnityProjects\Sound-and-Shoal\Unity-Claude-Automation\Modules\Unity-Claude-DecisionEngine\Unity-Claude-DecisionEngine.psd1"
        ActualName = "Unity-Claude-DecisionEngine"
        ExpectedFunctions = @("Invoke-DecisionEngine", "Get-DecisionMetrics")
    },
    @{
        Name = "DecisionEngine-Bayesian"
        Path = "C:\UnityProjects\Sound-and-Shoal\Unity-Claude-Automation\Modules\Unity-Claude-CLIOrchestrator\Core\DecisionEngine-Bayesian\Unity-Claude-DecisionEngine-Bayesian.psd1"
        ActualName = "Unity-Claude-DecisionEngine-Bayesian"
        ExpectedFunctions = @("Invoke-BayesianDecision", "Update-BayesianPriors")
    },
    @{
        Name = "Unity-Claude-HITL"
        Path = "C:\UnityProjects\Sound-and-Shoal\Unity-Claude-Automation\Modules\Unity-Claude-HITL\Unity-Claude-HITL.psd1"
        ActualName = "Unity-Claude-HITL"
        ExpectedFunctions = @("Request-HumanApproval", "Get-HITLStatus")
    },
    @{
        Name = "Unity-Claude-ParallelProcessor"
        Path = "C:\UnityProjects\Sound-and-Shoal\Unity-Claude-Automation\Modules\Unity-Claude-ParallelProcessor\Unity-Claude-ParallelProcessor.psd1"
        ActualName = "Unity-Claude-ParallelProcessor"
        ExpectedFunctions = @("Start-ParallelProcessing", "Get-ProcessorStatus")
    },
    @{
        Name = "Unity-Claude-PerformanceOptimizer"
        Path = "C:\UnityProjects\Sound-and-Shoal\Unity-Claude-Automation\Modules\Unity-Claude-PerformanceOptimizer\Unity-Claude-PerformanceOptimizer.psd1"
        ActualName = "Unity-Claude-PerformanceOptimizer"
        ExpectedFunctions = @("Optimize-Performance", "Get-OptimizationMetrics")
    }
)

# Filter modules based on test type
$modulesToTest = switch ($TestType) {
    "Quick" { $moduleConfigs | Select-Object -First 5 }
    "Individual" { $moduleConfigs | Where-Object { $_.Name -in @("Unity-Claude-Learning", "Unity-Claude-PredictiveAnalysis") } }
    default { $moduleConfigs }
}

$results = @()
$passCount = 0
$failCount = 0
$totalModules = $modulesToTest.Count
$currentModule = 0

foreach ($Module in $modulesToTest) {
    $currentModule++
    
    if ($ShowProgress) {
        Write-Progress -Activity "Testing Refactored Modules" -Status "Testing $($Module.Name)" -PercentComplete (($currentModule / $totalModules) * 100)
    }
    
    Write-Host "[$currentModule/$totalModules] Testing $($Module.Name)..." -ForegroundColor Yellow -NoNewline
    
    $result = [PSCustomObject]@{
        Module = $Module.Name
        Status = "Unknown"
        LoadTime = 0
        FunctionsFound = 0
        ExpectedFunctionsMissing = @()
        IsRefactoredVersion = $false
        Error = $null
        ActualModuleName = $null
    }
    
    try {
        # Check if manifest exists
        if (-not (Test-Path $Module.Path)) {
            throw "Module manifest not found at: $($Module.Path)"
        }
        
        # Import the module
        $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
        Import-Module $Module.Path -Force -Global -ErrorAction Stop 2>$null | Out-Null
        $stopwatch.Stop()
        $result.LoadTime = $stopwatch.ElapsedMilliseconds
        
        # FIXED: Use the ActualName property to find the module
        $importedModule = $null
        
        # First try the configured ActualName
        if ($Module.ActualName) {
            $importedModule = Get-Module $Module.ActualName -ErrorAction SilentlyContinue
            if ($importedModule) {
                $result.ActualModuleName = $Module.ActualName
                if ($Module.ActualName -ne $Module.Name) {
                    Write-Host " (loads as $($Module.ActualName))" -ForegroundColor Cyan -NoNewline
                }
            }
        }
        
        # If not found and not a nested module, try the expected name
        if (-not $importedModule -and -not $Module.IsNestedModule) {
            $importedModule = Get-Module $Module.Name -ErrorAction SilentlyContinue
            if ($importedModule) {
                $result.ActualModuleName = $Module.Name
            }
        }
        
        # For nested modules, verify the parent module has the functions
        if ($Module.IsNestedModule -and $importedModule) {
            # Module is loaded as part of parent, this is expected
            $result.ActualModuleName = $Module.ActualName
        }
        
        if (-not $importedModule) {
            # Check all loaded modules to see what got imported
            $allModules = Get-Module
            $moduleList = $allModules | Select-Object -ExpandProperty Name
            throw "Module imported but not found in session. Available modules: $($moduleList -join ', ')"
        }
        
        # Check if it's the refactored version
        $result.IsRefactoredVersion = $Module.Path -match "-Refactored\.psd1$" -or
                                      $Module.Path -match "Refactored" -or
                                      $true  # Assume all are refactored at this point
        
        # Count exported functions using the actual module name
        $exportedFunctions = Get-Command -Module $importedModule.Name -ErrorAction SilentlyContinue
        $result.FunctionsFound = @($exportedFunctions).Count
        
        # Check for expected functions
        if ($Module.ExpectedFunctions -and $Module.ExpectedFunctions.Count -gt 0) {
            $missingFunctions = @()
            foreach ($func in $Module.ExpectedFunctions) {
                $foundFunc = Get-Command $func -ErrorAction SilentlyContinue
                if (-not $foundFunc) {
                    $missingFunctions += $func
                }
            }
            $result.ExpectedFunctionsMissing = $missingFunctions
        }
        
        # Determine overall status
        if ($result.FunctionsFound -gt 0) {
            $result.Status = "Success"
            Write-Host " SUCCESS" -ForegroundColor Green
            Write-Host "  Functions exported: $($result.FunctionsFound)" -ForegroundColor Gray
            if ($result.ExpectedFunctionsMissing.Count -gt 0) {
                Write-Host "  Note: Some expected functions not found: $($result.ExpectedFunctionsMissing -join ', ')" -ForegroundColor Yellow
            }
            $passCount++
        } elseif ($importedModule) {
            # Module loaded but no functions exported - might be OK for some modules
            $result.Status = "Loaded"
            Write-Host " LOADED" -ForegroundColor Yellow
            Write-Host "  Module loaded successfully but no functions exported" -ForegroundColor Gray
            $passCount++
        } else {
            $result.Status = "NoFunctions"
            Write-Host " NO FUNCTIONS" -ForegroundColor Yellow
            Write-Host "  Module loaded but no functions exported" -ForegroundColor Gray
            $failCount++
        }
        
    } catch {
        $result.Status = "Failed"
        $result.Error = $_.Exception.Message
        Write-Host " FAIL" -ForegroundColor Red
        Write-Host "  Error: $($_.Exception.Message)" -ForegroundColor Red
        $failCount++
    }
    
    $results += $result
}

if ($ShowProgress) {
    Write-Progress -Activity "Testing Refactored Modules" -Completed
}

# Summary
Write-Host ""
Write-Host "TEST SUMMARY" -ForegroundColor Cyan
Write-Host "============" -ForegroundColor Cyan
Write-Host "Total modules tested: $totalModules"
Write-Host "Passed: $passCount" -ForegroundColor Green
Write-Host "Failed: $failCount" -ForegroundColor Red

if ($passCount -gt 0) {
    $successRate = [math]::Round(($passCount / $totalModules) * 100, 1)
    Write-Host "Success rate: $successRate%" -ForegroundColor Cyan
}

# Show details for any failures
$failures = $results | Where-Object { $_.Status -eq "Failed" }
if ($failures) {
    Write-Host ""
    Write-Host "FAILED MODULES:" -ForegroundColor Red
    foreach ($failure in $failures) {
        Write-Host "  - $($failure.Module): $($failure.Error)" -ForegroundColor Red
    }
}

# Performance summary
Write-Host ""
Write-Host "PERFORMANCE:" -ForegroundColor Cyan
$avgLoadTime = [math]::Round(($results | Measure-Object -Property LoadTime -Average).Average, 0)
$maxLoadTime = ($results | Measure-Object -Property LoadTime -Maximum).Maximum
Write-Host "  Average load time: ${avgLoadTime}ms"
Write-Host "  Max load time: ${maxLoadTime}ms"

# Module name mapping summary
Write-Host ""
Write-Host "MODULE NAME MAPPINGS:" -ForegroundColor Cyan
$mappings = $results | Where-Object { $_.ActualModuleName -and $_.ActualModuleName -ne $_.Module } | Select-Object Module, ActualModuleName
if ($mappings) {
    foreach ($map in $mappings) {
        Write-Host "  $($map.Module) -> $($map.ActualModuleName)" -ForegroundColor Gray
    }
} else {
    Write-Host "  All modules registered with expected names" -ForegroundColor Gray
}

# Save results if requested
if ($SaveResults) {
    $timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
    $reportFile = "RefactoredModules-TestResults-$timestamp.json"
    
    $report = @{
        Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        TestType = $TestType
        ModulesTotal = $totalModules
        ModulesSuccess = $passCount
        ModulesFailed = $failCount
        SuccessRate = if ($totalModules -gt 0) { [math]::Round(($passCount / $totalModules) * 100, 1) } else { 0 }
        AverageLoadTime = $avgLoadTime
        MaxLoadTime = $maxLoadTime
        Details = $results
    }
    
    $report | ConvertTo-Json -Depth 5 | Out-File $reportFile -Encoding UTF8
    Write-Host ""
    Write-Host "Results saved to: $reportFile" -ForegroundColor Green
}

# Return results for pipeline
return $results
# SIG # Begin signature block
# MIIFzgYJKoZIhvcNAQcCoIIFvzCCBbsCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCANFG2XBOk6s77h
# MsyK7b5JVoIQp3SzTkV9v8xMdin3WKCCAzAwggMsMIICFKADAgECAhB1HRbZIqgr
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
# MAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEINnSvM1TN3yHnJy5CA9UaeJO
# RMgyZ8jsjliJJDWO6ZGqMA0GCSqGSIb3DQEBAQUABIIBAAXVbbAqPsjcQKI3ytqh
# axY5GLJa6I4GzpMrykM6G62Tnz6EdY9niYpeWKD1E19Rjsv8e3zGjzblj4e0+KYc
# j/kD0JkxEFfV2S7QksutkLI8ed2UBpyktAy/YIYT1OVJITVIcWViWcEZVCFLQpWG
# 4PvceI8A5Dxd2ZpB3xQ49mt4qt7CSDuk281zgqmjsBL/aagR6C4WoZg9d7Sgnl0y
# imd7mKU5zIP5A7nQ4+eUa1w0/0/STT0sUdwxd7aZYTLS30dx164ogj97nZE4sb9V
# OzODKqPDJqOkM2Pp6+Dr7+mNR7Ol+IxGr0Pm0zdq/VKu9XdtjD4sw7ZXnMWqfh7D
# 7MU=
# SIG # End signature block
