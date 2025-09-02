#requires -Version 5.1

<#
.SYNOPSIS
Complete Week 3 readiness verification including all AI components from Week 1 (updated for new structure)

.DESCRIPTION
Comprehensive check of all prerequisites for Week 3 implementation including
AI components (now in Modules/Unity-Claude-AI-Integration), monitoring infrastructure, 
and existing implementations.

.NOTES
Date: 2025-08-30
Author: Unity-Claude-Automation System
Updated: Check new AI component locations in Modules/Unity-Claude-AI-Integration
#>

param(
    [switch]$TestAIComponents,
    [switch]$CheckMonitoringPatterns,
    [switch]$ExportReadinessReport
)

$results = @{
    Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    AIComponents = @{}
    MonitoringInfrastructure = @{}
    FileSystemWatcherImplementations = @{}
    Week3Readiness = @{
        Score = 0
        Details = @()
    }
}

function Write-ReadinessLog {
    param([string]$Message, [string]$Level = "Info")
    
    $colors = @{
        "Info" = "White"
        "Success" = "Green"
        "Warning" = "Yellow"
        "Error" = "Red"
        "Header" = "Cyan"
    }
    
    Write-Host "[$(Get-Date -Format 'HH:mm:ss')] $Message" -ForegroundColor $colors[$Level]
}

Write-Host ""
Write-ReadinessLog "========================================" -Level "Header"
Write-ReadinessLog "Week 3 Complete Readiness Assessment" -Level "Header"
Write-ReadinessLog "========================================" -Level "Header"
Write-Host ""

# =============================================================================
# CHECK AI COMPONENTS FROM WEEK 1 (NEW LOCATIONS)
# =============================================================================
Write-ReadinessLog "AI Components (Week 1 - Reorganized Structure)" -Level "Header"

# Check LangGraph Bridge components
$langGraphFiles = @{
    "Unity-Claude-LangGraphBridge.psm1" = "Modules\Unity-Claude-AI-Integration\LangGraph\Unity-Claude-LangGraphBridge.psm1"
    "Unity-Claude-MultiStepOrchestrator.psm1" = "Modules\Unity-Claude-AI-Integration\LangGraph\Unity-Claude-MultiStepOrchestrator.psm1"
    "MultiStep-Orchestrator-Workflows.json" = "Modules\Unity-Claude-AI-Integration\LangGraph\Workflows\MultiStep-Orchestrator-Workflows.json"
    "PredictiveAnalysis-LangGraph-Workflows.json" = "Modules\Unity-Claude-AI-Integration\LangGraph\Workflows\PredictiveAnalysis-LangGraph-Workflows.json"
}

Write-ReadinessLog "LangGraph Components:" -Level "Info"
foreach ($file in $langGraphFiles.GetEnumerator()) {
    $path = Join-Path $PSScriptRoot $file.Value
    if (Test-Path $path) {
        $results.AIComponents[$file.Key] = "Available"
        Write-ReadinessLog "  [OK] $($file.Key) found" -Level "Success"
        
        if ($file.Key -match "\.psm1$") {
            try {
                Import-Module $path -Force -ErrorAction Stop
                $moduleName = [System.IO.Path]::GetFileNameWithoutExtension($file.Key)
                $module = Get-Module $moduleName
                if ($module) {
                    $results.AIComponents["$($file.Key) Functions"] = $module.ExportedFunctions.Count
                    Write-ReadinessLog "    Functions: $($module.ExportedFunctions.Count)" -Level "Info"
                }
            }
            catch {
                Write-ReadinessLog "    Warning: Could not import module" -Level "Warning"
            }
        }
    }
    else {
        $results.AIComponents[$file.Key] = "Missing"
        Write-ReadinessLog "  [X] $($file.Key) not found" -Level "Error"
    }
}

# Check AutoGen components
$autoGenFiles = @{
    "Unity-Claude-AutoGen.psm1" = "Modules\Unity-Claude-AI-Integration\AutoGen\Unity-Claude-AutoGen.psm1"
    "Unity-Claude-AutoGenMonitoring.psm1" = "Modules\Unity-Claude-AI-Integration\AutoGen\Unity-Claude-AutoGenMonitoring.psm1"
    "PowerShell-AutoGen-Terminal-Integration.ps1" = "Modules\Unity-Claude-AI-Integration\AutoGen\PowerShell-AutoGen-Terminal-Integration.ps1"
}

Write-Host ""
Write-ReadinessLog "AutoGen Components:" -Level "Info"
foreach ($file in $autoGenFiles.GetEnumerator()) {
    $path = Join-Path $PSScriptRoot $file.Value
    if (Test-Path $path) {
        $results.AIComponents[$file.Key] = "Available"
        Write-ReadinessLog "  [OK] $($file.Key) found" -Level "Success"
    }
    else {
        $results.AIComponents[$file.Key] = "Missing"
        Write-ReadinessLog "  [X] $($file.Key) not found" -Level "Error"
    }
}

# Check Ollama components
$ollamaFiles = @{
    "Unity-Claude-Ollama.psm1" = "Modules\Unity-Claude-AI-Integration\Ollama\Unity-Claude-Ollama.psm1"
    "Unity-Claude-Ollama-Optimized-Fixed.psm1" = "Modules\Unity-Claude-AI-Integration\Ollama\Unity-Claude-Ollama-Optimized-Fixed.psm1"
    "Unity-Claude-Ollama-Enhanced.psm1" = "Modules\Unity-Claude-AI-Integration\Ollama\Unity-Claude-Ollama-Enhanced.psm1"
}

Write-Host ""
Write-ReadinessLog "Ollama Components:" -Level "Info"
foreach ($file in $ollamaFiles.GetEnumerator()) {
    $path = Join-Path $PSScriptRoot $file.Value
    if (Test-Path $path) {
        $results.AIComponents[$file.Key] = "Available"
        Write-ReadinessLog "  [OK] $($file.Key) found" -Level "Success"
    }
    else {
        $results.AIComponents[$file.Key] = "Missing"
        Write-ReadinessLog "  [X] $($file.Key) not found" -Level "Error"
    }
}

# Check test files (still in root)
$testFiles = @(
    "Test-AutoGenBasicConversation.ps1",
    "Test-Ollama-Integration.ps1",
    "Generate-Ollama-Enhanced-Documentation.ps1",
    "Test-LangGraphBridge.ps1",
    "Test-PredictiveAnalysis-LangGraph-Integration.ps1"
)

Write-Host ""
Write-ReadinessLog "Test Files (Root Directory):" -Level "Info"
foreach ($file in $testFiles) {
    $path = Join-Path $PSScriptRoot $file
    if (Test-Path $path) {
        $results.AIComponents["Test: $file"] = "Available"
        Write-ReadinessLog "  [OK] $file found" -Level "Success"
    }
    else {
        Write-ReadinessLog "  [!] $file not found (optional)" -Level "Info"
    }
}

Write-Host ""

# =============================================================================
# CHECK FILESYSTEMWATCHER IMPLEMENTATIONS
# =============================================================================
Write-ReadinessLog "FileSystemWatcher Implementations" -Level "Header"

$fswModules = Get-ChildItem -Path $PSScriptRoot -Filter "*.psm1" -Recurse | 
              Where-Object { (Get-Content $_.FullName -Raw) -match "FileSystemWatcher" }

$fswCount = 0
foreach ($module in $fswModules | Select-Object -First 10) {
    $moduleName = [System.IO.Path]::GetFileNameWithoutExtension($module.Name)
    $content = Get-Content $module.FullName -Raw
    
    # Check for key FileSystemWatcher patterns
    $patterns = @{
        "Event Registration" = '\$\w+\.Add_\w+'
        "Debouncing" = 'deboun|throttl|delay'
        "Event Handling" = 'Register-ObjectEvent|Unregister-Event'
        "Path Monitoring" = '\$\w+\.Path\s*='
        "Filter Setting" = '\$\w+\.Filter\s*='
    }
    
    $modulePatterns = @()
    foreach ($pattern in $patterns.GetEnumerator()) {
        if ($content -match $pattern.Value) {
            $modulePatterns += $pattern.Key
        }
    }
    
    if ($modulePatterns.Count -gt 0) {
        $results.FileSystemWatcherImplementations[$moduleName] = @{
            Path = $module.FullName
            Patterns = $modulePatterns
        }
        
        Write-ReadinessLog "  [OK] $moduleName" -Level "Success"
        Write-ReadinessLog "    Patterns: $($modulePatterns -join ', ')" -Level "Info"
        $fswCount++
    }
}

Write-ReadinessLog "  Total FileSystemWatcher implementations: $fswCount" -Level "Info"

Write-Host ""

# =============================================================================
# CHECK MONITORING INFRASTRUCTURE
# =============================================================================
if ($CheckMonitoringPatterns) {
    Write-ReadinessLog "Monitoring Infrastructure Patterns" -Level "Header"
    
    $monitoringPatterns = @{
        "Circuit Breaker" = 'Circuit.*Breaker|CircuitBreaker'
        "Health Check" = 'Health.*Check|HealthCheck|Test-.*Health'
        "Performance Monitoring" = 'Get-Counter|Performance.*Monitor|Measure-'
        "Resource Monitoring" = 'CPU|Memory|Disk|Network'
        "Logging Infrastructure" = 'Write-.*Log|Logger|Logging'
        "Error Handling" = 'try.*catch|ErrorAction|Exception'
        "Retry Logic" = 'Retry|Attempt|MaxAttempts'
        "Throttling" = 'Throttl|RateLimit|Delay'
    }
    
    foreach ($pattern in $monitoringPatterns.GetEnumerator()) {
        $files = Get-ChildItem -Path $PSScriptRoot -Filter "*.ps*" -Recurse |
                Where-Object { (Get-Content $_.FullName -Raw) -match $pattern.Value } |
                Select-Object -First 5
        
        if ($files) {
            $results.MonitoringInfrastructure[$pattern.Key] = @{
                Count = $files.Count
                Examples = $files.Name -join ", "
            }
            Write-ReadinessLog "  [OK] $($pattern.Key): $($files.Count) implementations" -Level "Success"
        }
        else {
            $results.MonitoringInfrastructure[$pattern.Key] = "Not Found"
            Write-ReadinessLog "  [!] $($pattern.Key): Not found" -Level "Warning"
        }
    }
}

Write-Host ""

# =============================================================================
# TEST AI COMPONENTS (Optional)
# =============================================================================
if ($TestAIComponents) {
    Write-ReadinessLog "Testing AI Component Functionality" -Level "Header"
    
    # Test LangGraph Bridge
    $langGraphPath = Join-Path $PSScriptRoot "Modules\Unity-Claude-AI-Integration\LangGraph\Unity-Claude-LangGraphBridge.psm1"
    if (Test-Path $langGraphPath) {
        try {
            Import-Module $langGraphPath -Force
            if (Get-Command New-LangGraphWorkflow -ErrorAction SilentlyContinue) {
                Write-ReadinessLog "  [OK] LangGraph Bridge functional" -Level "Success"
                $results.AIComponents["LangGraph Functional"] = $true
            }
        }
        catch {
            Write-ReadinessLog "  [!] LangGraph Bridge test failed" -Level "Warning"
        }
    }
    
    # Test Ollama
    $ollamaPath = Join-Path $PSScriptRoot "Modules\Unity-Claude-AI-Integration\Ollama\Unity-Claude-Ollama.psm1"
    if (Test-Path $ollamaPath) {
        try {
            Import-Module $ollamaPath -Force
            if (Get-Command Initialize-OllamaService -ErrorAction SilentlyContinue) {
                Write-ReadinessLog "  [OK] Ollama module functional" -Level "Success"
                $results.AIComponents["Ollama Functional"] = $true
            }
        }
        catch {
            Write-ReadinessLog "  [!] Ollama module test failed" -Level "Warning"
        }
    }
}

Write-Host ""

# =============================================================================
# CALCULATE READINESS SCORE
# =============================================================================
Write-ReadinessLog "========================================" -Level "Header"
Write-ReadinessLog "Week 3 Readiness Score Calculation" -Level "Header"
Write-ReadinessLog "========================================" -Level "Header"
Write-Host ""

$scoreComponents = @{
    "AI Components" = 0
    "FileSystemWatcher" = 0
    "Monitoring" = 0
    "Documentation" = 0
}

# Score AI Components (40% weight)
$aiAvailable = ($results.AIComponents.Values | Where-Object { $_ -eq "Available" }).Count
$aiTotal = ($results.AIComponents.Keys | Where-Object { $_ -notmatch "^Test:" }).Count
if ($aiTotal -gt 0) {
    $scoreComponents["AI Components"] = ($aiAvailable / $aiTotal) * 40
}

# Score FileSystemWatcher (30% weight)
if ($results.FileSystemWatcherImplementations.Count -gt 0) {
    $scoreComponents["FileSystemWatcher"] = 30
}

# Score Monitoring (20% weight)
if ($results.MonitoringInfrastructure.Count -gt 5) {
    $scoreComponents["Monitoring"] = 20
}

# Score Documentation (10% weight)
$docFiles = @(
    "Week3-Preparation-Advanced-Features-Plan.md",
    "Documentation\Enhanced-Visualization-Guide.md",
    "Week2-Success-Metrics-Validation-Report.md"
)

$docFound = $docFiles | Where-Object { Test-Path (Join-Path $PSScriptRoot $_) }
if ($docFound.Count -eq $docFiles.Count) {
    $scoreComponents["Documentation"] = 10
}

$totalScore = [math]::Round(($scoreComponents.Values | Measure-Object -Sum).Sum, 2)
$results.Week3Readiness.Score = $totalScore

Write-Host "Component Scores:" -ForegroundColor Cyan
foreach ($component in $scoreComponents.GetEnumerator()) {
    $maxScore = switch ($component.Key) {
        "AI Components" { 40 }
        "FileSystemWatcher" { 30 }
        "Monitoring" { 20 }
        "Documentation" { 10 }
    }
    Write-Host "  $($component.Key): $([math]::Round($component.Value, 1))/$maxScore" -ForegroundColor White
}

Write-Host ""
Write-Host "AI Component Details:" -ForegroundColor Cyan
Write-Host "  Available: $aiAvailable" -ForegroundColor Green
Write-Host "  Total Required: $aiTotal" -ForegroundColor White

Write-Host ""
Write-Host "Overall Week 3 Readiness Score: $totalScore%" -ForegroundColor $(
    if ($totalScore -ge 80) { "Green" }
    elseif ($totalScore -ge 60) { "Yellow" }
    else { "Red" }
)

# Provide recommendations
Write-Host ""
if ($totalScore -ge 80) {
    Write-ReadinessLog "[OK] READY FOR WEEK 3" -Level "Success"
    Write-ReadinessLog "All major components are in place" -Level "Success"
    $results.Week3Readiness.Details += "Ready to proceed with Week 3 implementation"
}
elseif ($totalScore -ge 60) {
    Write-ReadinessLog "[!] PARTIALLY READY FOR WEEK 3" -Level "Warning"
    Write-ReadinessLog "Some components need attention" -Level "Warning"
    $results.Week3Readiness.Details += "Review missing AI components before starting"
}
else {
    Write-ReadinessLog "[X] NOT READY FOR WEEK 3" -Level "Error"
    Write-ReadinessLog "Critical components missing" -Level "Error"
    $results.Week3Readiness.Details += "Complete Week 1 AI components first"
}

# Export report if requested
if ($ExportReadinessReport) {
    $reportPath = Join-Path $PSScriptRoot "Week3-Readiness-Report-$(Get-Date -Format 'yyyyMMdd-HHmmss').json"
    $results | ConvertTo-Json -Depth 10 | Out-File -FilePath $reportPath -Encoding UTF8
    Write-Host ""
    Write-Host "Readiness report saved to: $reportPath" -ForegroundColor Cyan
}

# Return readiness score as exit code (0 if >= 80, 1 otherwise)
exit $(if ($totalScore -ge 80) { 0 } else { 1 })