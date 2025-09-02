# Test-LinkManagement.ps1
# Focused test for link extraction and validation
[CmdletBinding()]
param(
    [switch]$EnableVerbose
)

if ($EnableVerbose) {
    $VerbosePreference = "Continue"
}

Write-Host "Link Management Tests" -ForegroundColor Cyan
Write-Host "=====================" -ForegroundColor Cyan

$testResults = @{
    TestName = "Link Management"
    Passed = 0
    Failed = 0
    Tests = @{}
}

# Test 1: Load module
try {
    Write-Host "Loading DocumentationCrossReference module..." -ForegroundColor Yellow
    Import-Module ".\Modules\Unity-Claude-DocumentationCrossReference\Unity-Claude-DocumentationCrossReference.psm1" -Force -ErrorAction Stop
    Write-Host "  [PASS] Module loaded" -ForegroundColor Green
    $testResults.Passed++
    $testResults.Tests.ModuleLoad = $true
}
catch {
    Write-Host "  [FAIL] Module load failed: $_" -ForegroundColor Red
    $testResults.Failed++
    $testResults.Tests.ModuleLoad = $false
    return $testResults
}

# Test 2: Markdown link extraction
try {
    Write-Host "Testing markdown link extraction..." -ForegroundColor Yellow
    
    $testMarkdown = @"
# Test Document

This has [internal link](./doc.md) and [external link](https://example.com).

Also includes:
- [Reference](#section)
- <https://autolink.example.com>
- [Another doc](../other/file.md)
"@
    
    $linkResult = Extract-MarkdownLinks -Content $testMarkdown
    
    if ($linkResult -and $linkResult.Links) {
        $linkCount = ($linkResult.Links | Measure-Object).Count
        if ($linkCount -ge 4) {
            Write-Host "  [PASS] Found $linkCount links" -ForegroundColor Green
            $testResults.Passed++
            $testResults.Tests.LinkExtraction = $true
        }
        else {
            Write-Host "  [FAIL] Expected at least 4 links, found $linkCount" -ForegroundColor Red
            $testResults.Failed++
            $testResults.Tests.LinkExtraction = $false
        }
    }
    else {
        Write-Host "  [FAIL] No links extracted" -ForegroundColor Red
        $testResults.Failed++
        $testResults.Tests.LinkExtraction = $false
    }
}
catch {
    Write-Host "  [FAIL] Link extraction error: $_" -ForegroundColor Red
    $testResults.Failed++
    $testResults.Tests.LinkExtraction = $false
}

# Test 3: Link validation
try {
    Write-Host "Testing link validation..." -ForegroundColor Yellow
    
    if ($linkResult) {
        $validated = Invoke-LinkValidation -LinkData $linkResult -UseCache
        
        if ($validated) {
            Write-Host "  [PASS] Link validation completed" -ForegroundColor Green
            Write-Host "    Total links: $($validated.Metrics.TotalLinks)" -ForegroundColor Gray
            $testResults.Passed++
            $testResults.Tests.LinkValidation = $true
        }
        else {
            Write-Host "  [FAIL] Link validation failed" -ForegroundColor Red
            $testResults.Failed++
            $testResults.Tests.LinkValidation = $false
        }
    }
}
catch {
    Write-Host "  [FAIL] Link validation error: $_" -ForegroundColor Red
    $testResults.Failed++
    $testResults.Tests.LinkValidation = $false
}

# Test 4: Link type classification
try {
    Write-Host "Testing link type classification..." -ForegroundColor Yellow
    
    if ($linkResult -and $linkResult.Metrics) {
        $hasTypes = ($linkResult.Metrics.InlineLinks -ge 0) -and 
                   ($linkResult.Metrics.ExternalLinks -ge 0) -and
                   ($linkResult.Metrics.RelativeLinks -ge 0)
        
        if ($hasTypes) {
            Write-Host "  [PASS] Link types classified" -ForegroundColor Green
            Write-Host "    Inline: $($linkResult.Metrics.InlineLinks)" -ForegroundColor Gray
            Write-Host "    External: $($linkResult.Metrics.ExternalLinks)" -ForegroundColor Gray
            Write-Host "    Relative: $($linkResult.Metrics.RelativeLinks)" -ForegroundColor Gray
            $testResults.Passed++
            $testResults.Tests.TypeClassification = $true
        }
        else {
            Write-Host "  [FAIL] Link type classification incomplete" -ForegroundColor Red
            $testResults.Failed++
            $testResults.Tests.TypeClassification = $false
        }
    }
}
catch {
    Write-Host "  [FAIL] Type classification error: $_" -ForegroundColor Red
    $testResults.Failed++
    $testResults.Tests.TypeClassification = $false
}

# Summary
Write-Host "`nLink Management Test Summary" -ForegroundColor Cyan
Write-Host "============================" -ForegroundColor Cyan
Write-Host "Passed: $($testResults.Passed)" -ForegroundColor Green
Write-Host "Failed: $($testResults.Failed)" -ForegroundColor Red
Write-Host "Success Rate: $([math]::Round(($testResults.Passed / ($testResults.Passed + $testResults.Failed)) * 100, 2))%" -ForegroundColor Yellow

return $testResults