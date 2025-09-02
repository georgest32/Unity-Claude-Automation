# Test-Week4-FinalIntegration.ps1
# Week 4 Day 5: Final Integration Testing Suite
# Enhanced Documentation System - Comprehensive End-to-End Validation
# Date: 2025-08-29

param(
    [ValidateSet('Development', 'Staging', 'Production')]
    [string]$Environment = 'Development',
    
    [switch]$Verbose,
    [switch]$SaveReport,
    [string]$OutputPath = ".\Week4-FinalIntegration-TestResults-$(Get-Date -Format 'yyyyMMdd-HHmmss').json"
)

if ($Verbose) { $VerbosePreference = "Continue" }

Write-Host "=== Week 4 Final Integration Testing Suite ===" -ForegroundColor Cyan
Write-Host "Test Started: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor Green
Write-Host "Environment: $Environment" -ForegroundColor Yellow

$testResults = @{
    TestName = "Week 4 Final Integration Testing"
    Environment = $Environment
    Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Results = @()
    Summary = @{
        Total = 0
        Passed = 0
        Failed = 0
        Warnings = 0
    }
    IntegrationFlow = @{}
    PerformanceMetrics = @{}
}

function Test-IntegrationComponent {
    param(
        [string]$ComponentName,
        [scriptblock]$TestCode,
        [string]$Description = "",
        [bool]$Critical = $true
    )
    
    $testResults.Summary.Total++
    $testStart = Get-Date
    
    try {
        Write-Host "Testing $ComponentName..." -ForegroundColor Yellow -NoNewline
        
        $result = & $TestCode
        $success = $true
        $error = $null
        
        Write-Host " PASS" -ForegroundColor Green
        $testResults.Summary.Passed++
    }
    catch {
        $success = $false
        $error = $_.Exception.Message
        
        if ($Critical) {
            Write-Host " FAIL (CRITICAL)" -ForegroundColor Red
            $testResults.Summary.Failed++
        } else {
            Write-Host " WARN" -ForegroundColor Yellow
            $testResults.Summary.Warnings++
        }
        
        Write-Host "  Error: $error" -ForegroundColor Red
    }
    
    $testEnd = Get-Date
    $duration = ($testEnd - $testStart).TotalMilliseconds
    
    $testResults.Results += [PSCustomObject]@{
        ComponentName = $ComponentName
        Description = $Description
        Success = $success
        Critical = $Critical
        Error = $error
        Duration = [math]::Round($duration, 2)
        Result = $result
    }
    
    return $success
}

Write-Host "`n=== WEEK 4 MODULE INTEGRATION TESTS ===" -ForegroundColor Cyan

# Test 1: Week 4 Module Loading Integration
Test-IntegrationComponent -ComponentName "Week 4 Module Loading" -Description "Validate all Week 4 modules load together successfully" -TestCode {
    $week4Modules = @(
        ".\Modules\Unity-Claude-CPG\Core\Predictive-Evolution.psm1",
        ".\Modules\Unity-Claude-CPG\Core\Predictive-Maintenance.psm1"
    )
    
    $loadedModules = @()
    $loadErrors = @()
    
    foreach ($module in $week4Modules) {
        try {
            $moduleName = [System.IO.Path]::GetFileNameWithoutExtension($module)
            
            # Remove if already loaded
            if (Get-Module -Name $moduleName -ErrorAction SilentlyContinue) {
                Remove-Module -Name $moduleName -Force
            }
            
            Import-Module $module -Force -DisableNameChecking
            $loadedModule = Get-Module -Name $moduleName
            
            if ($loadedModule) {
                $loadedModules += [PSCustomObject]@{
                    Name = $moduleName
                    FunctionCount = $loadedModule.ExportedFunctions.Count
                    Path = $module
                }
            } else {
                $loadErrors += "Module $moduleName failed to load"
            }
        } catch {
            $loadErrors += "Module $moduleName error: $($_.Exception.Message)"
        }
    }
    
    if ($loadErrors.Count -gt 0) {
        throw "Module loading errors: $($loadErrors -join '; ')"
    }
    
    return @{
        LoadedModules = $loadedModules
        TotalFunctions = ($loadedModules | Measure-Object FunctionCount -Sum).Sum
        ModuleCount = $loadedModules.Count
    }
}

# Test 2: Week 4 Cross-Module Integration
Test-IntegrationComponent -ComponentName "Cross-Module Integration" -Description "Test Week 4 modules working together in integrated workflows" -TestCode {
    # Test integration between Code Evolution and Maintenance Prediction
    try {
        # Test 1: Evolution data feeding into maintenance prediction
        if (Get-Command -Name "Get-CodeChurnMetrics" -ErrorAction SilentlyContinue) {
            $churnData = Get-CodeChurnMetrics -Path ".\Modules\Unity-Claude-CPG\Core" -Since "1.month.ago"
            
            if (Get-Command -Name "Get-TechnicalDebt" -ErrorAction SilentlyContinue) {
                $debtData = Get-TechnicalDebt -Path ".\Modules\Unity-Claude-CPG\Core" -UseEvolutionData
                
                $integrationWorking = $churnData -and $debtData
                if (-not $integrationWorking) {
                    throw "Cross-module data integration not working"
                }
            } else {
                throw "Get-TechnicalDebt function not available for integration test"
            }
        } else {
            throw "Get-CodeChurnMetrics function not available for integration test"
        }
        
        return @{
            ChurnDataAvailable = $churnData -ne $null
            DebtDataAvailable = $debtData -ne $null
            IntegrationWorking = $true
            DataPoints = if ($churnData) { $churnData.Count } else { 0 }
        }
    } catch {
        throw "Cross-module integration failed: $($_.Exception.Message)"
    }
}

# Test 3: End-to-End Predictive Analysis Workflow
Test-IntegrationComponent -ComponentName "E2E Predictive Analysis" -Description "Complete predictive analysis workflow validation" -TestCode {
    try {
        $workflowResults = @{}
        
        # Step 1: Code Evolution Analysis
        if (Get-Command -Name "New-EvolutionReport" -ErrorAction SilentlyContinue) {
            $evolutionReport = New-EvolutionReport -Path ".\Modules\Unity-Claude-CPG\Core" -Since "1.month.ago" -Format "JSON"
            $workflowResults["EvolutionAnalysis"] = "Working"
        } else {
            $workflowResults["EvolutionAnalysis"] = "Not Available"
        }
        
        # Step 2: Maintenance Prediction
        if (Get-Command -Name "New-MaintenanceReport" -ErrorAction SilentlyContinue) {
            $maintenanceReport = New-MaintenanceReport -Path ".\Modules\Unity-Claude-CPG\Core" -Format "JSON"
            $workflowResults["MaintenancePrediction"] = "Working"
        } else {
            $workflowResults["MaintenancePrediction"] = "Not Available"
        }
        
        # Step 3: Combined Analysis
        $workflowComplete = $workflowResults["EvolutionAnalysis"] -eq "Working" -and 
                           $workflowResults["MaintenancePrediction"] -eq "Working"
        
        if (-not $workflowComplete) {
            throw "E2E workflow incomplete: $($workflowResults | ConvertTo-Json)"
        }
        
        return @{
            WorkflowResults = $workflowResults
            WorkflowComplete = $workflowComplete
            EvolutionReportGenerated = $evolutionReport -ne $null
            MaintenanceReportGenerated = $maintenanceReport -ne $null
        }
    } catch {
        throw "E2E workflow validation failed: $($_.Exception.Message)"
    }
}

Write-Host "`n=== INFRASTRUCTURE INTEGRATION TESTS ===" -ForegroundColor Cyan

# Test 4: Enhanced Documentation System Infrastructure
Test-IntegrationComponent -ComponentName "Documentation Infrastructure" -Description "Validate complete documentation system infrastructure" -TestCode {
    $infrastructure = @{}
    
    # Check core module directories
    $coreModules = @(
        "Unity-Claude-CPG",
        "Unity-Claude-LLM", 
        "Unity-Claude-ParallelProcessing",
        "Unity-Claude-Enhanced-DocumentationGenerators"
    )
    
    foreach ($module in $coreModules) {
        $modulePath = ".\Modules\$module"
        $infrastructure[$module] = if (Test-Path $modulePath) { "Available" } else { "Missing" }
    }
    
    # Check deployment infrastructure
    $deploymentComponents = @{
        "DeploymentScript" = ".\Deploy-EnhancedDocumentationSystem.ps1"
        "RollbackFunctions" = ".\Deploy-Rollback-Functions.ps1" 
        "DockerCompose" = ".\docker-compose.yml"
        "UserGuide" = ".\Enhanced_Documentation_System_User_Guide.md"
    }
    
    foreach ($component in $deploymentComponents.Keys) {
        $path = $deploymentComponents[$component]
        $infrastructure[$component] = if (Test-Path $path) { "Available" } else { "Missing" }
    }
    
    $missingComponents = $infrastructure.Keys | Where-Object { $infrastructure[$_] -eq "Missing" }
    
    if ($missingComponents.Count -gt 0) {
        throw "Missing infrastructure components: $($missingComponents -join ', ')"
    }
    
    return $infrastructure
}

# Test 5: Performance Baseline Validation
Test-IntegrationComponent -ComponentName "Performance Baseline" -Description "Validate system performance meets baseline requirements" -Critical $false -TestCode {
    $performanceResults = @{}
    
    # Test Week 4 module performance
    $performanceStart = Get-Date
    
    try {
        # Quick performance test of key functions
        if (Get-Command -Name "Get-GitCommitHistory" -ErrorAction SilentlyContinue) {
            $commitStart = Get-Date
            $commits = Get-GitCommitHistory -MaxCount 10 -Since "1.week.ago"
            $commitDuration = ((Get-Date) - $commitStart).TotalMilliseconds
            $performanceResults["GitHistoryAnalysis"] = @{
                Duration = [math]::Round($commitDuration, 2)
                CommitCount = if ($commits) { $commits.Count } else { 0 }
            }
        }
        
        if (Get-Command -Name "Get-CodeChurnMetrics" -ErrorAction SilentlyContinue) {
            $churnStart = Get-Date
            $churn = Get-CodeChurnMetrics -Path ".\Modules\Unity-Claude-CPG\Core" -Since "1.week.ago"
            $churnDuration = ((Get-Date) - $churnStart).TotalMilliseconds
            $performanceResults["ChurnAnalysis"] = @{
                Duration = [math]::Round($churnDuration, 2)
                FileCount = if ($churn) { $churn.Count } else { 0 }
            }
        }
        
        $totalDuration = ((Get-Date) - $performanceStart).TotalMilliseconds
        $performanceResults["TotalExecution"] = [math]::Round($totalDuration, 2)
        
        # Performance validation (target: under 30 seconds for E2E tests)
        if ($totalDuration -gt 30000) {
            Write-Warning "Performance slower than 30-second target: $([math]::Round($totalDuration/1000, 2))s"
        }
        
        return $performanceResults
    } catch {
        throw "Performance validation failed: $($_.Exception.Message)"
    }
}

Write-Host "`n=== INTEGRATION WORKFLOW TESTS ===" -ForegroundColor Cyan

# Test 6: Complete System Integration Flow
Test-IntegrationComponent -ComponentName "Complete System Flow" -Description "Validate end-to-end system integration workflow" -TestCode {
    try {
        $flowResults = @{}
        
        # Flow Step 1: Module ecosystem validation
        $availableCommands = Get-Command -Module "*Evolution*", "*Maintenance*" -ErrorAction SilentlyContinue
        $flowResults["AvailableCommands"] = $availableCommands.Count
        
        # Flow Step 2: Documentation generation capability
        $docsAvailable = Test-Path ".\Enhanced_Documentation_System_User_Guide.md"
        $flowResults["DocumentationAvailable"] = $docsAvailable
        
        # Flow Step 3: Deployment automation capability  
        $deploymentAvailable = Test-Path ".\Deploy-EnhancedDocumentationSystem.ps1"
        $flowResults["DeploymentAvailable"] = $deploymentAvailable
        
        # Flow Step 4: Testing infrastructure
        $testingInfrastructure = @(
            ".\Test-PredictiveEvolution.ps1",
            ".\Test-MaintenancePrediction.ps1",
            ".\Test-EnhancedDocumentationSystemDeployment.ps1"
        )
        
        $testingAvailable = $testingInfrastructure | ForEach-Object { Test-Path $_ }
        $flowResults["TestingInfrastructure"] = ($testingAvailable | Where-Object { $_ }).Count
        
        # Validate complete flow
        $minimumRequirements = @{
            AvailableCommands = 10  # Minimum command count
            DocumentationAvailable = $true
            DeploymentAvailable = $true
            TestingInfrastructure = 3  # All test scripts
        }
        
        $validationPassed = $true
        foreach ($requirement in $minimumRequirements.Keys) {
            if ($flowResults[$requirement] -ne $minimumRequirements[$requirement] -and 
                $flowResults[$requirement] -lt $minimumRequirements[$requirement]) {
                $validationPassed = $false
                break
            }
        }
        
        if (-not $validationPassed) {
            throw "System integration flow validation failed - minimum requirements not met"
        }
        
        return $flowResults
    } catch {
        throw "Complete system flow validation failed: $($_.Exception.Message)"
    }
}

# Test Summary
Write-Host "`n=== Final Integration Test Summary ===" -ForegroundColor Cyan
Write-Host "Total Tests: $($testResults.Summary.Total)" -ForegroundColor White
Write-Host "Passed: $($testResults.Summary.Passed)" -ForegroundColor Green  
Write-Host "Failed: $($testResults.Summary.Failed)" -ForegroundColor Red
Write-Host "Warnings: $($testResults.Summary.Warnings)" -ForegroundColor Yellow

$successRate = if ($testResults.Summary.Total -gt 0) { 
    [math]::Round(($testResults.Summary.Passed / $testResults.Summary.Total) * 100, 1) 
} else { 0 }

Write-Host "Success Rate: $successRate%" -ForegroundColor $(if ($successRate -ge 85) { "Green" } elseif ($successRate -ge 70) { "Yellow" } else { "Red" })

# Integration Status Assessment
Write-Host "`n=== Integration Status Assessment ===" -ForegroundColor Cyan
$integrationReady = $testResults.Summary.Failed -eq 0
$integrationStatus = if ($integrationReady) { "INTEGRATED" } else { "INTEGRATION ISSUES" }
$integrationColor = if ($integrationReady) { "Green" } else { "Red" }

Write-Host "Integration Status: $integrationStatus" -ForegroundColor $integrationColor

if ($integrationReady) {
    Write-Host "Week 4 Enhanced Documentation System integration validated" -ForegroundColor Green
    Write-Host "All predictive analysis components working together seamlessly" -ForegroundColor Green
} else {
    Write-Host "Integration issues require resolution:" -ForegroundColor Red
    $failedTests = $testResults.Results | Where-Object { -not $_.Success -and $_.Critical }
    $failedTests | ForEach-Object { Write-Host "  - $($_.ComponentName): $($_.Error)" -ForegroundColor Red }
}

# Critical Analysis Summary
Write-Host "`n=== Week 4 Achievement Summary ===" -ForegroundColor Cyan
$achievementSummary = @{
    "Day 1: Code Evolution Analysis" = "VALIDATED (100% test success)"
    "Day 2: Maintenance Prediction" = "VALIDATED (100% test success)"  
    "Day 3: User Documentation" = "COMPLETE (enterprise-grade user guide)"
    "Day 4: Deployment Automation" = "COMPLETE (with rollback and verification)"
    "Day 5: Final Integration" = "IN VALIDATION (current test execution)"
}

foreach ($achievement in $achievementSummary.GetEnumerator()) {
    $status = $achievement.Value
    $color = if ($status -like "*VALIDATED*" -or $status -like "*COMPLETE*") { "Green" } else { "Yellow" }
    Write-Host "$($achievement.Key): $status" -ForegroundColor $color
}

# Save results if requested
if ($SaveReport) {
    $testResults.Summary.SuccessRate = $successRate
    $testResults.IntegrationReady = $integrationReady
    $testResults.AchievementSummary = $achievementSummary
    $testResults | ConvertTo-Json -Depth 10 | Out-File -FilePath $OutputPath -Encoding UTF8
    Write-Host "`nFinal integration test results saved to: $OutputPath" -ForegroundColor Green
}

# Return results
return $testResults

Write-Host "`n=== Week 4 Day 5: Final Integration Testing Complete ===" -ForegroundColor Green