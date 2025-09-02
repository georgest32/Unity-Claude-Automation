#!/usr/bin/env pwsh

<#
.SYNOPSIS
    Test CLIOrchestrator Core Function Availability
.DESCRIPTION
    Tests whether Core functions are properly exported from the refactored CLIOrchestrator module
#>

Write-Host "Testing CLIOrchestrator Core Function Availability" -ForegroundColor Cyan
Write-Host "=====================================================" -ForegroundColor Cyan
Write-Host ""

# Remove any existing instances
Get-Module Unity-Claude-CLIOrchestrator -All | Remove-Module -Force -ErrorAction SilentlyContinue

# Import the module
try {
    Import-Module "C:\UnityProjects\Sound-and-Shoal\Unity-Claude-Automation\Modules\Unity-Claude-CLIOrchestrator\Unity-Claude-CLIOrchestrator.psd1" -Force
    Write-Host "Module imported successfully" -ForegroundColor Green
} catch {
    Write-Host "Failed to import module: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

Write-Host ""

# Test Core functions
$testFunctions = @(
    'Extract-ResponseEntities', 'Find-RecommendationPatterns', 'Invoke-RuleBasedDecision', 
    'Test-SafeFilePath', 'Test-SafetyValidation', 'Invoke-PatternRecognitionAnalysis',
    'Calculate-OverallConfidence', 'Test-SafeCommand', 'Invoke-EnhancedResponseAnalysis'
)

$availableCount = 0
$missingCount = 0

Write-Host "Testing Core function availability:" -ForegroundColor Yellow
foreach ($func in $testFunctions) {
    Write-Host "  $func : " -NoNewline
    if (Get-Command $func -ErrorAction SilentlyContinue) {
        Write-Host "Available" -ForegroundColor Green
        $availableCount++
    } else {
        Write-Host "Missing" -ForegroundColor Red
        $missingCount++
    }
}

Write-Host ""
Write-Host "Results Summary:" -ForegroundColor Cyan
Write-Host "  Available: $availableCount" -ForegroundColor Green
Write-Host "  Missing: $missingCount" -ForegroundColor Red
Write-Host "  Total functions exported: $((Get-Command -Module Unity-Claude-CLIOrchestrator).Count)" -ForegroundColor White

if ($missingCount -eq 0) {
    Write-Host ""
    Write-Host "SUCCESS: All Core functions are available!" -ForegroundColor Green
} else {
    Write-Host ""
    Write-Host "ISSUE: Some Core functions are still missing" -ForegroundColor Yellow
}