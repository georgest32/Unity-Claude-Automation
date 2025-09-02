#requires -Version 5.1

<#
.SYNOPSIS
Complete Week 3 readiness verification including all AI components from Week 1

.DESCRIPTION
Comprehensive check of all prerequisites for Week 3 implementation including
AI components, monitoring infrastructure, and existing implementations.

.NOTES
Date: 2025-08-30
Author: Unity-Claude-Automation System
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
# CHECK AI COMPONENTS FROM WEEK 1
# =============================================================================
Write-ReadinessLog "AI Components (Week 1 Implementation)" -Level "Header"

# Check LangGraph Bridge
$langGraphFiles = @(
    "Unity-Claude-LangGraphBridge.psm1",
    "Unity-Claude-MultiStepOrchestrator.psm1",
    "MultiStep-Orchestrator-Workflows.json",
    "PredictiveAnalysis-LangGraph-Workflows.json"
)

foreach ($file in $langGraphFiles) {
    $path = Join-Path $PSScriptRoot $file
    if (Test-Path $path) {
        $results.AIComponents[$file] = "Available"
        Write-ReadinessLog "  ✅ $file found" -Level "Success"
        
        if ($file -match "\.psm1$") {
            try {
                Import-Module $path -Force -ErrorAction Stop
                $moduleName = [System.IO.Path]::GetFileNameWithoutExtension($file)
                $module = Get-Module $moduleName
                if ($module) {
                    $results.AIComponents["$file Functions"] = $module.ExportedFunctions.Count
                    Write-ReadinessLog "    Functions: $($module.ExportedFunctions.Count)" -Level "Info"
                }
            }
            catch {
                Write-ReadinessLog "    Warning: Could not import module" -Level "Warning"
            }
        }
    }
    else {
        $results.AIComponents[$file] = "Missing"
        Write-ReadinessLog "  ❌ $file not found" -Level "Error"
    }
}

# Check AutoGen
$autoGenFiles = @(
    "Unity-Claude-AutoGen.psm1",
    "Unity-Claude-AutoGenMonitoring.psm1",
    "PowerShell-AutoGen-Terminal-Integration.ps1",
    "Test-AutoGenBasicConversation.ps1"
)

foreach ($file in $autoGenFiles) {
    $path = Join-Path $PSScriptRoot $file
    if (Test-Path $path) {
        $results.AIComponents[$file] = "Available"
        Write-ReadinessLog "  ✅ $file found" -Level "Success"
    }
    else {
        $results.AIComponents[$file] = "Missing"
        Write-ReadinessLog "  ⚠️ $file not found" -Level "Warning"
    }
}

# Check Ollama
$ollamaFiles = @(
    "Unity-Claude-Ollama.psm1",
    "Unity-Claude-Ollama-Optimized-Fixed.psm1",
    "Test-Ollama-Integration.ps1",
    "Generate-Ollama-Enhanced-Documentation.ps1"
)

foreach ($file in $ollamaFiles) {
    $path = Join-Path $PSScriptRoot $file
    if (Test-Path $path) {
        $results.AIComponents[$file] = "Available"
        Write-ReadinessLog "  ✅ $file found" -Level "Success"
    }
    else {
        $results.AIComponents[$file] = "Missing"
        Write-ReadinessLog "  ⚠️ $file not found" -Level "Warning"
    }
}

Write-Host ""

# =============================================================================
# CHECK FILESYSTEMWATCHER IMPLEMENTATIONS
# =============================================================================
Write-ReadinessLog "FileSystemWatcher Implementations" -Level "Header"

$fswModules = Get-ChildItem -Path $PSScriptRoot -Filter "*.psm1" -Recurse | 
              Where-Object { (Get-Content $_.FullName -Raw) -match "FileSystemWatcher" }

foreach ($module in $fswModules) {
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
    
    $results.FileSystemWatcherImplementations[$moduleName] = @{
        Path = $module.FullName
        Patterns = $modulePatterns
    }
    
    Write-ReadinessLog "  ✅ $moduleName" -Level "Success"
    Write-ReadinessLog "    Patterns: $($modulePatterns -join ', ')" -Level "Info"
}

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
            Write-ReadinessLog "  ✅ $($pattern.Key): $($files.Count) implementations" -Level "Success"
        }
        else {
            $results.MonitoringInfrastructure[$pattern.Key] = "Not Found"
            Write-ReadinessLog "  ⚠️ $($pattern.Key): Not found" -Level "Warning"
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
    if (Get-Module Unity-Claude-LangGraphBridge) {
        try {
            $testWorkflow = @{
                Type = "Test"
                Data = @{ Message = "Test" }
            }
            
            if (Get-Command New-LangGraphWorkflow -ErrorAction SilentlyContinue) {
                Write-ReadinessLog "  ✅ LangGraph Bridge functional" -Level "Success"
                $results.AIComponents["LangGraph Functional"] = $true
            }
        }
        catch {
            Write-ReadinessLog "  ⚠️ LangGraph Bridge test failed" -Level "Warning"
        }
    }
    
    # Test Ollama
    if (Test-Path (Join-Path $PSScriptRoot "Unity-Claude-Ollama.psm1")) {
        try {
            Import-Module (Join-Path $PSScriptRoot "Unity-Claude-Ollama.psm1") -Force
            if (Get-Command Initialize-OllamaService -ErrorAction SilentlyContinue) {
                Write-ReadinessLog "  ✅ Ollama module functional" -Level "Success"
                $results.AIComponents["Ollama Functional"] = $true
            }
        }
        catch {
            Write-ReadinessLog "  ⚠️ Ollama module test failed" -Level "Warning"
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
$aiTotal = $results.AIComponents.Count
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
    "Enhanced-Visualization-Guide.md",
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
Write-Host "Overall Week 3 Readiness Score: $totalScore%" -ForegroundColor $(
    if ($totalScore -ge 80) { "Green" }
    elseif ($totalScore -ge 60) { "Yellow" }
    else { "Red" }
)

# Provide recommendations
Write-Host ""
if ($totalScore -ge 80) {
    Write-ReadinessLog "✅ READY FOR WEEK 3" -Level "Success"
    Write-ReadinessLog "All major components are in place" -Level "Success"
    $results.Week3Readiness.Details += "Ready to proceed with Week 3 implementation"
}
elseif ($totalScore -ge 60) {
    Write-ReadinessLog "⚠️ PARTIALLY READY FOR WEEK 3" -Level "Warning"
    Write-ReadinessLog "Some components need attention" -Level "Warning"
    $results.Week3Readiness.Details += "Review missing AI components before starting"
}
else {
    Write-ReadinessLog "❌ NOT READY FOR WEEK 3" -Level "Error"
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