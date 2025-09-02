# Validate-CrossReferenceSystem.ps1
# Comprehensive validation of the Cross-Reference and Link Management system

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Cross-Reference System Validation" -ForegroundColor Cyan  
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

$validationResults = @{
    Timestamp = Get-Date
    ModuleChecks = @{}
    SyntaxChecks = @{}
    FunctionalityChecks = @{}
    PerformanceMetrics = @{}
    Issues = @()
    Warnings = @()
}

# Suppress verbose warnings for cleaner output
$originalWarningPreference = $WarningPreference
$WarningPreference = 'SilentlyContinue'

try {
    # 1. Module Syntax Validation
    Write-Host "Phase 1: Module Syntax Validation" -ForegroundColor Yellow
    Write-Host "---------------------------------" -ForegroundColor Yellow
    
    $modules = @(
        ".\Modules\Unity-Claude-DocumentationCrossReference\Unity-Claude-DocumentationCrossReference.psm1",
        ".\Modules\Unity-Claude-DocumentationSuggestions\Unity-Claude-DocumentationSuggestions.psm1",
        ".\Modules\Unity-Claude-DocumentationQualityAssessment\Unity-Claude-DocumentationQualityAssessment.psm1"
    )
    
    foreach ($module in $modules) {
        $moduleName = Split-Path $module -Leaf
        Write-Host "  Checking $moduleName..." -NoNewline
        
        $errors = $null
        $tokens = $null
        $ast = [System.Management.Automation.Language.Parser]::ParseFile(
            $module,
            [ref]$tokens,
            [ref]$errors
        )
        
        if ($errors.Count -eq 0) {
            Write-Host " [PASS]" -ForegroundColor Green
            $validationResults.SyntaxChecks[$moduleName] = "PASS"
        } else {
            Write-Host " [FAIL]" -ForegroundColor Red
            Write-Host "    Errors: $($errors.Count)" -ForegroundColor Red
            $validationResults.SyntaxChecks[$moduleName] = "FAIL"
            $validationResults.Issues += "Syntax errors in $moduleName"
        }
    }
    
    # 2. Module Loading Validation
    Write-Host "`nPhase 2: Module Loading Validation" -ForegroundColor Yellow
    Write-Host "-----------------------------------" -ForegroundColor Yellow
    
    foreach ($module in $modules) {
        $moduleName = Split-Path $module -Leaf
        Write-Host "  Loading $moduleName..." -NoNewline
        
        try {
            Import-Module $module -Force -ErrorAction Stop
            Write-Host " [PASS]" -ForegroundColor Green
            $validationResults.ModuleChecks[$moduleName] = "LOADED"
        } catch {
            Write-Host " [FAIL]" -ForegroundColor Red
            Write-Host "    Error: $_" -ForegroundColor Red
            $validationResults.ModuleChecks[$moduleName] = "FAILED"
            $validationResults.Issues += "Failed to load $moduleName"
        }
    }
    
    # 3. Functionality Validation
    Write-Host "`nPhase 3: Functionality Validation" -ForegroundColor Yellow
    Write-Host "----------------------------------" -ForegroundColor Yellow
    
    # Test CrossReference initialization
    Write-Host "  Testing CrossReference initialization..." -NoNewline
    try {
        $initResult = Initialize-DocumentationCrossReference -EnableRealTimeMonitoring -EnableAIEnhancement
        if ($initResult) {
            Write-Host " [PASS]" -ForegroundColor Green
            $validationResults.FunctionalityChecks.Initialization = "PASS"
        } else {
            Write-Host " [FAIL]" -ForegroundColor Red
            $validationResults.FunctionalityChecks.Initialization = "FAIL"
        }
    } catch {
        Write-Host " [ERROR]" -ForegroundColor Red
        $validationResults.FunctionalityChecks.Initialization = "ERROR"
        $validationResults.Issues += "CrossReference initialization failed"
    }
    
    # Test AST analysis
    Write-Host "  Testing AST analysis..." -NoNewline
    try {
        $testScript = @"
function Test-Sample {
    param(`$Name)
    Write-Host "Test `$Name"
}
Test-Sample -Name "Validation"
"@
        $tempFile = [System.IO.Path]::GetTempFileName() + ".ps1"
        Set-Content -Path $tempFile -Value $testScript
        
        $astResult = Get-ASTCrossReferences -FilePath $tempFile
        Remove-Item $tempFile -Force -ErrorAction SilentlyContinue
        
        if ($astResult -and $astResult.References) {
            Write-Host " [PASS]" -ForegroundColor Green
            $validationResults.FunctionalityChecks.ASTAnalysis = "PASS"
        } else {
            Write-Host " [FAIL]" -ForegroundColor Red
            $validationResults.FunctionalityChecks.ASTAnalysis = "FAIL"
        }
    } catch {
        Write-Host " [ERROR]" -ForegroundColor Red
        $validationResults.FunctionalityChecks.ASTAnalysis = "ERROR"
    }
    
    # Test link extraction
    Write-Host "  Testing link extraction..." -NoNewline
    try {
        $testMarkdown = "Test [link](./test.md) and [external](https://example.com)"
        $linkResult = Extract-MarkdownLinks -Content $testMarkdown
        
        if ($linkResult -and $linkResult.Links.Count -ge 2) {
            Write-Host " [PASS]" -ForegroundColor Green
            $validationResults.FunctionalityChecks.LinkExtraction = "PASS"
        } else {
            Write-Host " [FAIL]" -ForegroundColor Red
            $validationResults.FunctionalityChecks.LinkExtraction = "FAIL"
        }
    } catch {
        Write-Host " [ERROR]" -ForegroundColor Red
        $validationResults.FunctionalityChecks.LinkExtraction = "ERROR"
    }
    
    # 4. Performance Metrics
    Write-Host "`nPhase 4: Performance Metrics" -ForegroundColor Yellow
    Write-Host "-----------------------------" -ForegroundColor Yellow
    
    $startTime = Get-Date
    
    # Quick performance test
    $perfTestContent = "This is a test of the documentation system performance metrics."
    $embedding = Generate-ContentEmbedding -Content $perfTestContent
    
    $endTime = Get-Date
    $duration = ($endTime - $startTime).TotalSeconds
    
    Write-Host "  Embedding generation time: $([Math]::Round($duration, 2))s" -ForegroundColor Cyan
    $validationResults.PerformanceMetrics.EmbeddingTime = $duration
    
    # 5. Summary
    Write-Host "`n========================================" -ForegroundColor Cyan
    Write-Host "Validation Summary" -ForegroundColor Cyan
    Write-Host "========================================" -ForegroundColor Cyan
    
    $syntaxPass = ($validationResults.SyntaxChecks.Values | Where-Object { $_ -eq "PASS" }).Count
    $syntaxTotal = $validationResults.SyntaxChecks.Count
    Write-Host "Syntax Checks: $syntaxPass/$syntaxTotal passed" -ForegroundColor $(if ($syntaxPass -eq $syntaxTotal) { "Green" } else { "Yellow" })
    
    $modulePass = ($validationResults.ModuleChecks.Values | Where-Object { $_ -eq "LOADED" }).Count
    $moduleTotal = $validationResults.ModuleChecks.Count
    Write-Host "Module Loading: $modulePass/$moduleTotal loaded" -ForegroundColor $(if ($modulePass -eq $moduleTotal) { "Green" } else { "Yellow" })
    
    $funcPass = ($validationResults.FunctionalityChecks.Values | Where-Object { $_ -eq "PASS" }).Count
    $funcTotal = $validationResults.FunctionalityChecks.Count
    Write-Host "Functionality: $funcPass/$funcTotal passed" -ForegroundColor $(if ($funcPass -eq $funcTotal) { "Green" } else { "Yellow" })
    
    if ($validationResults.Issues.Count -gt 0) {
        Write-Host "`nIssues Found:" -ForegroundColor Red
        $validationResults.Issues | ForEach-Object {
            Write-Host "  - $_" -ForegroundColor Red
        }
    } else {
        Write-Host "`n[SUCCESS] All validations passed!" -ForegroundColor Green
    }
    
    # Save results
    $validationResults | ConvertTo-Json -Depth 5 | Out-File ".\ValidationResults-$(Get-Date -Format 'yyyyMMddHHmmss').json"
    
} finally {
    # Restore warning preference
    $WarningPreference = $originalWarningPreference
}

# Return success/failure
if ($validationResults.Issues.Count -eq 0) {
    exit 0
} else {
    exit 1
}