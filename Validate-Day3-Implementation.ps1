# Validate-Day3-Implementation.ps1
# Quick validation that Day 3 features are implemented without requiring Ollama service

Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "Day 3 Implementation Validation (No Ollama Required)" -ForegroundColor White
Write-Host "============================================================" -ForegroundColor Cyan

$results = @{
    ModulesFound = @()
    FunctionsAvailable = @()
    TestsCreated = @()
    Success = $true
}

# Check core Ollama module
Write-Host "`n[Checking Unity-Claude-Ollama.psm1]" -ForegroundColor Yellow
if (Test-Path ".\Unity-Claude-Ollama.psm1") {
    Write-Host "  ✓ Core module found" -ForegroundColor Green
    $results.ModulesFound += "Unity-Claude-Ollama.psm1"
    
    try {
        Import-Module ".\Unity-Claude-Ollama.psm1" -Force
        $coreFunctions = Get-Command -Module "Unity-Claude-Ollama"
        Write-Host "  ✓ $($coreFunctions.Count) functions available" -ForegroundColor Green
        $results.FunctionsAvailable += $coreFunctions.Name
    } catch {
        Write-Host "  ✗ Error loading module: $($_.Exception.Message)" -ForegroundColor Red
        $results.Success = $false
    }
} else {
    Write-Host "  ✗ Core module not found" -ForegroundColor Red
    $results.Success = $false
}

# Check enhanced module
Write-Host "`n[Checking Unity-Claude-Ollama-Enhanced.psm1]" -ForegroundColor Yellow
if (Test-Path ".\Unity-Claude-Ollama-Enhanced.psm1") {
    Write-Host "  ✓ Enhanced module found" -ForegroundColor Green
    $results.ModulesFound += "Unity-Claude-Ollama-Enhanced.psm1"
    
    try {
        Import-Module ".\Unity-Claude-Ollama-Enhanced.psm1" -Force
        $enhancedFunctions = Get-Command -Module "Unity-Claude-Ollama-Enhanced"
        Write-Host "  ✓ $($enhancedFunctions.Count) enhanced functions available" -ForegroundColor Green
        $results.FunctionsAvailable += $enhancedFunctions.Name
    } catch {
        Write-Host "  ✗ Error loading module: $($_.Exception.Message)" -ForegroundColor Red
        $results.Success = $false
    }
} else {
    Write-Host "  ✗ Enhanced module not found" -ForegroundColor Red
    $results.Success = $false
}

# Check PowershAI module
Write-Host "`n[Checking PowershAI Module]" -ForegroundColor Yellow
$powershAI = Get-Module -ListAvailable PowershAI
if ($powershAI) {
    Write-Host "  ✓ PowershAI installed (v$($powershAI.Version))" -ForegroundColor Green
    Write-Host "  Path: $($powershAI.Path)" -ForegroundColor Gray
} else {
    Write-Host "  ⚠ PowershAI not installed (optional)" -ForegroundColor Yellow
}

# Check test files
Write-Host "`n[Checking Test Files]" -ForegroundColor Yellow
$testFiles = @(
    ".\Test-Ollama-Integration.ps1",
    ".\Test-Day3-Complete-Integration.ps1"
)

foreach ($testFile in $testFiles) {
    if (Test-Path $testFile) {
        Write-Host "  ✓ $(Split-Path -Leaf $testFile) found" -ForegroundColor Green
        $results.TestsCreated += $testFile
    } else {
        Write-Host "  ✗ $(Split-Path -Leaf $testFile) not found" -ForegroundColor Red
    }
}

# Check documentation
Write-Host "`n[Checking Documentation]" -ForegroundColor Yellow
if (Test-Path ".\Day3_Ollama_Implementation_Status_2025_08_30.md") {
    Write-Host "  ✓ Implementation status documentation found" -ForegroundColor Green
} else {
    Write-Host "  ✗ Implementation status documentation not found" -ForegroundColor Red
}

# Day 3 Feature Checklist
Write-Host "`n[Day 3 Feature Implementation Status]" -ForegroundColor Cyan

$features = @{
    "Hour 1-2: Ollama Service Management" = ($results.FunctionsAvailable -contains "Start-OllamaService")
    "Hour 1-2: Model Configuration" = ($results.FunctionsAvailable -contains "Set-OllamaConfiguration")
    "Hour 1-2: Documentation Generation" = ($results.FunctionsAvailable -contains "Invoke-OllamaDocumentation")
    "Hour 3-4: PowershAI Integration" = ($results.FunctionsAvailable -contains "Initialize-PowershAI")
    "Hour 3-4: Intelligent Pipeline" = ($results.FunctionsAvailable -contains "Start-IntelligentDocumentationPipeline")
    "Hour 3-4: Quality Assessment" = ($results.FunctionsAvailable -contains "Get-DocumentationQualityAssessment")
    "Hour 5-6: Real-Time Analysis" = ($results.FunctionsAvailable -contains "Start-RealTimeAIAnalysis")
    "Hour 5-6: Status Monitoring" = ($results.FunctionsAvailable -contains "Get-RealTimeAnalysisStatus")
    "Hour 7-8: Batch Processing" = ($results.FunctionsAvailable -contains "Start-BatchDocumentationProcessing")
    "Hour 7-8: Test Suite" = ($results.TestsCreated.Count -ge 2)
}

$implemented = 0
$total = $features.Count

foreach ($feature in $features.Keys) {
    if ($features[$feature]) {
        Write-Host "  ✓ $feature" -ForegroundColor Green
        $implemented++
    } else {
        Write-Host "  ✗ $feature" -ForegroundColor Red
    }
}

# Summary
Write-Host "`n============================================================" -ForegroundColor Cyan
Write-Host "VALIDATION SUMMARY" -ForegroundColor White
Write-Host "============================================================" -ForegroundColor Cyan

$completionRate = [math]::Round(($implemented / $total) * 100, 1)
Write-Host "`nModules Found: $($results.ModulesFound.Count)" -ForegroundColor White
Write-Host "Functions Available: $($results.FunctionsAvailable.Count)" -ForegroundColor White
Write-Host "Test Files Created: $($results.TestsCreated.Count)" -ForegroundColor White
Write-Host "Features Implemented: $implemented/$total ($completionRate%)" -ForegroundColor White

$status = if ($completionRate -ge 90) { "COMPLETE" } elseif ($completionRate -ge 70) { "MOSTLY COMPLETE" } else { "PARTIAL" }
$color = if ($completionRate -ge 90) { "Green" } elseif ($completionRate -ge 70) { "Yellow" } else { "Red" }

Write-Host "`nDay 3 Implementation Status: $status" -ForegroundColor $color

if ($completionRate -ge 90) {
    Write-Host "`n✅ Day 3 Ollama Integration is ready!" -ForegroundColor Green
    Write-Host "   All major features have been implemented." -ForegroundColor Gray
    Write-Host "   To use the features, ensure Ollama service is running." -ForegroundColor Gray
    Write-Host "`nNext Steps:" -ForegroundColor Cyan
    Write-Host "  1. Start Ollama service: ollama serve" -ForegroundColor White
    Write-Host "  2. Pull CodeLlama model: ollama pull codellama:13b" -ForegroundColor White
    Write-Host "  3. Run full tests: .\Test-Day3-Complete-Integration.ps1" -ForegroundColor White
    Write-Host "  4. Proceed to Day 4 or implement Day 1-2 features" -ForegroundColor White
} else {
    Write-Host "`n⚠ Additional work needed on Day 3 features" -ForegroundColor Yellow
    Write-Host "  Missing features listed above in red" -ForegroundColor Gray
}

Write-Host "`n============================================================" -ForegroundColor Cyan

# Save validation results
$validationFile = ".\Day3-Validation-$(Get-Date -Format 'yyyyMMdd-HHmmss').json"
@{
    Timestamp = Get-Date
    ModulesFound = $results.ModulesFound
    FunctionsCount = $results.FunctionsAvailable.Count
    Functions = $results.FunctionsAvailable
    TestsCreated = $results.TestsCreated
    Features = $features
    ImplementedCount = $implemented
    TotalFeatures = $total
    CompletionRate = $completionRate
    Status = $status
} | ConvertTo-Json -Depth 5 | Out-File -FilePath $validationFile -Encoding UTF8

Write-Host "Validation results saved to: $validationFile" -ForegroundColor Gray

return @{
    Success = $completionRate -ge 90
    CompletionRate = $completionRate
    Status = $status
}