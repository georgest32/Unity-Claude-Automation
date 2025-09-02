#requires -Version 5.1

<#
.SYNOPSIS
Comprehensive verification test for Week 2 Day 10 deliverables and Week 3 readiness

.DESCRIPTION
This script verifies all completed tasks, deliverables, and components from Week 2 Day 10
implementation, and assesses readiness for Week 3 features.

.NOTES
Date: 2025-08-30
Author: Unity-Claude-Automation System
Part of: MAXIMUM_UTILIZATION_IMPLEMENTATION_PLAN_2025_08_29.md
#>

param(
    [switch]$Detailed,
    [switch]$TestFunctionality,
    [switch]$CheckWeek3Prerequisites
)

# Initialize verification results
$verificationResults = @{
    Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Week2Day10 = @{
        TotalChecks = 0
        PassedChecks = 0
        FailedChecks = 0
        Deliverables = @{}
    }
    Week3Readiness = @{
        Prerequisites = @{}
        MissingComponents = @()
        ReadinessScore = 0
    }
    Details = @()
}

function Write-VerificationLog {
    param(
        [string]$Message,
        [string]$Level = "Info"
    )
    
    $colors = @{
        "Info" = "White"
        "Success" = "Green"
        "Warning" = "Yellow"
        "Error" = "Red"
        "Check" = "Cyan"
        "Header" = "Magenta"
    }
    
    Write-Host "[$(Get-Date -Format 'HH:mm:ss')] $Message" -ForegroundColor $colors[$Level]
}

function Test-Deliverable {
    param(
        [string]$Name,
        [string]$Type,
        [scriptblock]$TestBlock,
        [string]$Category = "General"
    )
    
    $verificationResults.Week2Day10.TotalChecks++
    Write-VerificationLog "Checking: $Name" -Level "Check"
    
    try {
        $result = & $TestBlock
        if ($result) {
            $verificationResults.Week2Day10.PassedChecks++
            Write-VerificationLog "  ✅ VERIFIED: $Name" -Level "Success"
            
            if (-not $verificationResults.Week2Day10.Deliverables.ContainsKey($Category)) {
                $verificationResults.Week2Day10.Deliverables[$Category] = @()
            }
            $verificationResults.Week2Day10.Deliverables[$Category] += @{
                Name = $Name
                Type = $Type
                Status = "Verified"
                Details = $result
            }
            return $true
        }
        else {
            $verificationResults.Week2Day10.FailedChecks++
            Write-VerificationLog "  ❌ MISSING: $Name" -Level "Error"
            $verificationResults.Week2Day10.Deliverables[$Category] += @{
                Name = $Name
                Type = $Type
                Status = "Missing"
            }
            return $false
        }
    }
    catch {
        $verificationResults.Week2Day10.FailedChecks++
        Write-VerificationLog "  ❌ ERROR: $Name - $_" -Level "Error"
        $verificationResults.Week2Day10.Deliverables[$Category] += @{
            Name = $Name
            Type = $Type
            Status = "Error"
            Error = $_.Exception.Message
        }
        return $false
    }
}

Write-Host ""
Write-VerificationLog "================================================" -Level "Header"
Write-VerificationLog "Week 2 Day 10 Deliverables Verification" -Level "Header"
Write-VerificationLog "================================================" -Level "Header"
Write-Host ""

# =============================================================================
# HOUR 1-2: Complete Visualization System Integration
# =============================================================================
Write-VerificationLog "Hour 1-2: Visualization System Integration" -Level "Header"

# Check Unity-Claude-AST-Enhanced module
Test-Deliverable -Name "Unity-Claude-AST-Enhanced Module" -Type "Module" -Category "Hour1-2" -TestBlock {
    $modulePath = Join-Path $PSScriptRoot "Modules\Unity-Claude-AST-Enhanced\Unity-Claude-AST-Enhanced.psm1"
    if (Test-Path $modulePath) {
        # Check if module can be imported
        try {
            Import-Module $modulePath -Force -ErrorAction Stop
            $module = Get-Module Unity-Claude-AST-Enhanced
            if ($module) {
                return @{
                    Path = $modulePath
                    Functions = $module.ExportedFunctions.Keys -join ", "
                    FunctionCount = $module.ExportedFunctions.Count
                }
            }
        }
        catch {
            return $false
        }
    }
    return $false
}

# Check manifest file
Test-Deliverable -Name "Unity-Claude-AST-Enhanced Manifest" -Type "Manifest" -Category "Hour1-2" -TestBlock {
    $manifestPath = Join-Path $PSScriptRoot "Modules\Unity-Claude-AST-Enhanced\Unity-Claude-AST-Enhanced.psd1"
    Test-Path $manifestPath
}

# Check DependencySearch module availability
Test-Deliverable -Name "DependencySearch Module Integration" -Type "Dependency" -Category "Hour1-2" -TestBlock {
    $module = Get-Module -ListAvailable DependencySearch
    if ($module) {
        return @{
            Version = $module.Version.ToString()
            Path = $module.Path
        }
    }
    return $false
}

# Check test suite
Test-Deliverable -Name "Week 2 Day 10 Integration Test Suite" -Type "Test" -Category "Hour1-2" -TestBlock {
    $testPath = Join-Path $PSScriptRoot "Test-Week2-Day10-Integration-Fixed.ps1"
    if (Test-Path $testPath) {
        $content = Get-Content $testPath -Raw
        $testCount = ([regex]::Matches($content, 'Test-ComponentAvailability\s+"[^"]+"')).Count
        return @{
            Path = $testPath
            TestCount = $testCount
        }
    }
    return $false
}

# Check visualization scripts
Test-Deliverable -Name "Start-Visualization-Dashboard.ps1" -Type "Script" -Category "Hour1-2" -TestBlock {
    $scriptPath = Join-Path $PSScriptRoot "Start-Visualization-Dashboard.ps1"
    Test-Path $scriptPath
}

# Check core AST functions if module loaded
if (Get-Module Unity-Claude-AST-Enhanced) {
    Test-Deliverable -Name "Core AST Functions" -Type "Functions" -Category "Hour1-2" -TestBlock {
        $requiredFunctions = @(
            "Get-ModuleCallGraph",
            "Get-CrossModuleRelationships",
            "Get-FunctionCallAnalysis",
            "Export-CallGraphData"
        )
        
        $module = Get-Module Unity-Claude-AST-Enhanced
        $availableFunctions = $module.ExportedFunctions.Keys
        $foundFunctions = $requiredFunctions | Where-Object { $_ -in $availableFunctions }
        
        if ($foundFunctions.Count -eq $requiredFunctions.Count) {
            return @{
                Functions = $foundFunctions -join ", "
                Count = $foundFunctions.Count
            }
        }
        return $false
    }
}

Write-Host ""

# =============================================================================
# HOUR 3-4: Documentation and Usage Guidelines
# =============================================================================
Write-VerificationLog "Hour 3-4: Documentation and Usage Guidelines" -Level "Header"

Test-Deliverable -Name "Enhanced Visualization Guide" -Type "Documentation" -Category "Hour3-4" -TestBlock {
    $docPath = Join-Path $PSScriptRoot "Documentation\Enhanced-Visualization-Guide.md"
    if (Test-Path $docPath) {
        $content = Get-Content $docPath -Raw
        $sections = @(
            "Overview",
            "System Architecture",
            "Installation and Setup",
            "Core Components",
            "Usage Examples",
            "Configuration",
            "Troubleshooting",
            "API Reference"
        )
        
        $foundSections = $sections | Where-Object { $content -match "##?\s+$_" }
        return @{
            Path = $docPath
            FileSize = (Get-Item $docPath).Length
            Sections = $foundSections.Count
            TotalSections = $sections.Count
        }
    }
    return $false
}

Test-Deliverable -Name "API Reference Documentation" -Type "Documentation" -Category "Hour3-4" -TestBlock {
    $docPath = Join-Path $PSScriptRoot "Documentation\Enhanced-Visualization-Guide.md"
    if (Test-Path $docPath) {
        $content = Get-Content $docPath -Raw
        $apiSections = @(
            "Get-ModuleCallGraph",
            "Get-CrossModuleRelationships",
            "Export-CallGraphData",
            "Get-FunctionCallAnalysis"
        )
        
        $foundAPIs = $apiSections | Where-Object { $content -match "###?\s+$_" }
        return @{
            DocumentedAPIs = $foundAPIs -join ", "
            Count = $foundAPIs.Count
        }
    }
    return $false
}

Write-Host ""

# =============================================================================
# HOUR 5-6: Week 2 Success Metrics Validation
# =============================================================================
Write-VerificationLog "Hour 5-6: Success Metrics Validation" -Level "Header"

Test-Deliverable -Name "Week 2 Success Metrics Validation Report" -Type "Report" -Category "Hour5-6" -TestBlock {
    $reportPath = Join-Path $PSScriptRoot "Week2-Success-Metrics-Validation-Report.md"
    if (Test-Path $reportPath) {
        $content = Get-Content $reportPath -Raw
        $metrics = @(
            "Visualization Capability",
            "Interactive Features",
            "Real-Time Updates",
            "AI Enhancement"
        )
        
        $foundMetrics = $metrics | Where-Object { $content -match $_ }
        return @{
            Path = $reportPath
            MetricsAssessed = $foundMetrics.Count
            FileSize = (Get-Item $reportPath).Length
        }
    }
    return $false
}

Test-Deliverable -Name "Week 2 Integration Documentation" -Type "Documentation" -Category "Hour5-6" -TestBlock {
    $docPath = Join-Path $PSScriptRoot "Week2_Day10_Integration_Documentation_2025_08_30.md"
    Test-Path $docPath
}

Write-Host ""

# =============================================================================
# HOUR 7-8: Week 3 Preparation and Advanced Feature Planning
# =============================================================================
Write-VerificationLog "Hour 7-8: Week 3 Preparation" -Level "Header"

Test-Deliverable -Name "Week 3 Preparation Plan" -Type "Planning" -Category "Hour7-8" -TestBlock {
    $planPath = Join-Path $PSScriptRoot "Week3-Preparation-Advanced-Features-Plan.md"
    if (Test-Path $planPath) {
        $content = Get-Content $planPath -Raw
        $days = @("Day 11", "Day 12", "Day 13", "Day 14", "Day 15")
        $foundDays = $days | Where-Object { $content -match $_ }
        
        return @{
            Path = $planPath
            PlannedDays = $foundDays.Count
            FileSize = (Get-Item $planPath).Length
        }
    }
    return $false
}

Test-Deliverable -Name "Response JSON Signal File" -Type "Signal" -Category "Hour7-8" -TestBlock {
    $jsonPath = Join-Path $PSScriptRoot "ClaudeResponses\Autonomous\Week2_Day10_Complete_2025_08_30.json"
    if (Test-Path $jsonPath) {
        try {
            $json = Get-Content $jsonPath -Raw | ConvertFrom-Json
            return @{
                Status = $json.status
                Recommendation = $json.response
                Week2Completion = $json.metrics.week2_completion
            }
        }
        catch {
            return $false
        }
    }
    return $false
}

Write-Host ""

# =============================================================================
# VISUALIZATION INFRASTRUCTURE
# =============================================================================
Write-VerificationLog "Visualization Infrastructure" -Level "Header"

Test-Deliverable -Name "Visualization Directory Structure" -Type "Infrastructure" -Category "Visualization" -TestBlock {
    $vizPath = Join-Path $PSScriptRoot "Visualization"
    $requiredDirs = @(
        "",
        "public",
        "public\static",
        "public\static\data"
    )
    
    $existingDirs = $requiredDirs | Where-Object {
        $fullPath = if ($_) { Join-Path $vizPath $_ } else { $vizPath }
        Test-Path $fullPath
    }
    
    if ($existingDirs.Count -gt 0) {
        return @{
            VisualizationRoot = $vizPath
            Directories = $existingDirs.Count
            RequiredDirs = $requiredDirs.Count
        }
    }
    return $false
}

Write-Host ""

# =============================================================================
# WEEK 3 PREREQUISITES CHECK
# =============================================================================
if ($CheckWeek3Prerequisites) {
    Write-VerificationLog "================================================" -Level "Header"
    Write-VerificationLog "Week 3 Prerequisites Assessment" -Level "Header"
    Write-VerificationLog "================================================" -Level "Header"
    Write-Host ""
    
    # Check FileSystemWatcher implementations
    $fswModules = @(
        "Unity-Claude-AutonomousAgent",
        "Unity-Claude-SystemStatus"
    )
    
    foreach ($moduleName in $fswModules) {
        $modulePath = Get-ChildItem -Path (Join-Path $PSScriptRoot "Modules") -Filter "$moduleName*.psm1" -Recurse -ErrorAction SilentlyContinue | Select-Object -First 1
        
        if ($modulePath) {
            $content = Get-Content $modulePath.FullName -Raw
            if ($content -match "FileSystemWatcher") {
                $verificationResults.Week3Readiness.Prerequisites["$moduleName FileSystemWatcher"] = "Available"
                Write-VerificationLog "  ✅ $moduleName has FileSystemWatcher implementation" -Level "Success"
            }
        }
    }
    
    # Check AI components from Week 1
    $aiComponents = @(
        "Unity-Claude-LangGraphBridge",
        "Unity-Claude-AutoGen",
        "Unity-Claude-Ollama"
    )
    
    foreach ($component in $aiComponents) {
        $componentPath = Get-ChildItem -Path (Join-Path $PSScriptRoot "Modules") -Filter "$component*.psm1" -Recurse -ErrorAction SilentlyContinue | Select-Object -First 1
        
        if ($componentPath) {
            $verificationResults.Week3Readiness.Prerequisites[$component] = "Available"
            Write-VerificationLog "  ✅ $component available for Week 3" -Level "Success"
        }
        else {
            $verificationResults.Week3Readiness.MissingComponents += $component
            Write-VerificationLog "  ⚠️ $component not found" -Level "Warning"
        }
    }
    
    # Check monitoring infrastructure
    $monitoringFeatures = @(
        "Circuit Breaker",
        "Performance Monitoring",
        "Health Check"
    )
    
    foreach ($feature in $monitoringFeatures) {
        $found = Get-ChildItem -Path (Join-Path $PSScriptRoot "Modules") -Filter "*.psm1" -Recurse | 
                 Where-Object { (Get-Content $_.FullName -Raw) -match $feature.Replace(" ", "") } |
                 Select-Object -First 1
        
        if ($found) {
            $verificationResults.Week3Readiness.Prerequisites[$feature] = "Available"
            Write-VerificationLog "  ✅ $feature pattern found" -Level "Success"
        }
    }
    
    # Calculate readiness score
    $totalPrerequisites = $verificationResults.Week3Readiness.Prerequisites.Count + $verificationResults.Week3Readiness.MissingComponents.Count
    if ($totalPrerequisites -gt 0) {
        $verificationResults.Week3Readiness.ReadinessScore = [math]::Round(($verificationResults.Week3Readiness.Prerequisites.Count / $totalPrerequisites) * 100, 2)
    }
}

Write-Host ""

# =============================================================================
# FUNCTIONAL TESTING (Optional)
# =============================================================================
if ($TestFunctionality) {
    Write-VerificationLog "================================================" -Level "Header"
    Write-VerificationLog "Functional Testing" -Level "Header"
    Write-VerificationLog "================================================" -Level "Header"
    Write-Host ""
    
    # Test AST analysis on a small module
    if (Get-Module Unity-Claude-AST-Enhanced) {
        Write-VerificationLog "Testing AST Analysis functionality..." -Level "Check"
        try {
            $testModulePath = Join-Path $PSScriptRoot "Modules\Unity-Claude-AST-Enhanced\Unity-Claude-AST-Enhanced.psm1"
            if (Test-Path $testModulePath) {
                $result = Get-ModuleCallGraph -ModulePaths @($testModulePath) -CacheResults
                if ($result) {
                    Write-VerificationLog "  ✅ AST Analysis functional" -Level "Success"
                    $verificationResults.Details += @{
                        Test = "AST Analysis"
                        Status = "Functional"
                        Details = "Analyzed module successfully"
                    }
                }
            }
        }
        catch {
            Write-VerificationLog "  ❌ AST Analysis error: $_" -Level "Error"
        }
    }
    
    # Test D3.js export functionality
    if (Get-Command Export-CallGraphData -ErrorAction SilentlyContinue) {
        Write-VerificationLog "Testing D3.js Export functionality..." -Level "Check"
        try {
            $testData = @{
                Modules = @(
                    @{
                        Name = "TestModule"
                        Functions = @(
                            @{ Name = "Test-Function"; Calls = @() }
                        )
                    }
                )
            }
            
            $result = Export-CallGraphData -CallGraphData $testData -Format "D3JS" -PassThru
            if ($result) {
                Write-VerificationLog "  ✅ D3.js Export functional" -Level "Success"
            }
        }
        catch {
            Write-VerificationLog "  ❌ D3.js Export error: $_" -Level "Error"
        }
    }
}

Write-Host ""

# =============================================================================
# SUMMARY REPORT
# =============================================================================
Write-VerificationLog "================================================" -Level "Header"
Write-VerificationLog "Verification Summary" -Level "Header"
Write-VerificationLog "================================================" -Level "Header"
Write-Host ""

$week2SuccessRate = if ($verificationResults.Week2Day10.TotalChecks -gt 0) {
    [math]::Round(($verificationResults.Week2Day10.PassedChecks / $verificationResults.Week2Day10.TotalChecks) * 100, 2)
} else { 0 }

Write-Host "Week 2 Day 10 Deliverables:" -ForegroundColor Cyan
Write-Host "  Total Checks: $($verificationResults.Week2Day10.TotalChecks)" -ForegroundColor White
Write-Host "  Passed: $($verificationResults.Week2Day10.PassedChecks)" -ForegroundColor Green
Write-Host "  Failed: $($verificationResults.Week2Day10.FailedChecks)" -ForegroundColor $(if ($verificationResults.Week2Day10.FailedChecks -gt 0) { "Red" } else { "Gray" })
Write-Host "  Success Rate: $week2SuccessRate%" -ForegroundColor $(if ($week2SuccessRate -ge 80) { "Green" } elseif ($week2SuccessRate -ge 60) { "Yellow" } else { "Red" })

Write-Host ""

# Category breakdown
Write-Host "Deliverables by Category:" -ForegroundColor Cyan
foreach ($category in $verificationResults.Week2Day10.Deliverables.Keys | Sort-Object) {
    $items = $verificationResults.Week2Day10.Deliverables[$category]
    $verified = ($items | Where-Object { $_.Status -eq "Verified" }).Count
    $total = $items.Count
    Write-Host "  $category : $verified/$total verified" -ForegroundColor White
}

if ($CheckWeek3Prerequisites) {
    Write-Host ""
    Write-Host "Week 3 Readiness:" -ForegroundColor Cyan
    Write-Host "  Prerequisites Available: $($verificationResults.Week3Readiness.Prerequisites.Count)" -ForegroundColor Green
    Write-Host "  Missing Components: $($verificationResults.Week3Readiness.MissingComponents.Count)" -ForegroundColor $(if ($verificationResults.Week3Readiness.MissingComponents.Count -gt 0) { "Yellow" } else { "Gray" })
    Write-Host "  Readiness Score: $($verificationResults.Week3Readiness.ReadinessScore)%" -ForegroundColor $(if ($verificationResults.Week3Readiness.ReadinessScore -ge 80) { "Green" } elseif ($verificationResults.Week3Readiness.ReadinessScore -ge 60) { "Yellow" } else { "Red" })
}

# Export detailed results
$resultsPath = Join-Path $PSScriptRoot "Week2-Day10-Verification-Results-$(Get-Date -Format 'yyyyMMdd-HHmmss').json"
$verificationResults | ConvertTo-Json -Depth 10 | Out-File -FilePath $resultsPath -Encoding UTF8

Write-Host ""
Write-Host "Detailed results saved to: $resultsPath" -ForegroundColor Cyan

# Provide recommendation
Write-Host ""
if ($week2SuccessRate -ge 80) {
    Write-Host "✅ VERIFICATION PASSED: Week 2 Day 10 deliverables confirmed" -ForegroundColor Green
    Write-Host "   Ready to proceed to Week 3" -ForegroundColor Green
} elseif ($week2SuccessRate -ge 60) {
    Write-Host "⚠️ PARTIAL VERIFICATION: Some deliverables missing" -ForegroundColor Yellow
    Write-Host "   Review missing components before Week 3" -ForegroundColor Yellow
} else {
    Write-Host "❌ VERIFICATION FAILED: Significant gaps in deliverables" -ForegroundColor Red
    Write-Host "   Complete missing items before proceeding" -ForegroundColor Red
}

# Return exit code based on success rate
exit $(if ($week2SuccessRate -ge 80) { 0 } else { 1 })