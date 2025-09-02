#Requires -Version 5.1
<#
.SYNOPSIS
    Tests the documentation generation pipeline.

.DESCRIPTION
    Validates that all documentation parsers and the unified generator
    are working correctly with sample files from the project.

.PARAMETER SaveResults
    Save test results to a JSON file

.EXAMPLE
    .\Test-DocumentationPipeline.ps1 -SaveResults
#>

param(
    [switch]$SaveResults,
    [switch]$Verbose
)

$ErrorActionPreference = 'Stop'

# Test results structure
$testResults = @{
    TestName = "Documentation Generation Pipeline Test"
    StartTime = Get-Date
    EndTime = $null
    Tests = @()
    Summary = @{
        Total = 0
        Passed = 0
        Failed = 0
        Skipped = 0
    }
}

function Test-Component {
    param(
        [string]$Name,
        [scriptblock]$Test,
        [string]$Description
    )
    
    $result = @{
        Name = $Name
        Description = $Description
        Status = 'Failed'
        Error = $null
        Duration = $null
    }
    
    $testResults.Summary.Total++
    
    Write-Host "`nTesting: $Name" -ForegroundColor Cyan
    Write-Host "Description: $Description" -ForegroundColor Gray
    
    $startTime = Get-Date
    
    try {
        $testResult = & $Test
        $result.Status = 'Passed'
        $testResults.Summary.Passed++
        Write-Host "Result: PASSED" -ForegroundColor Green
    }
    catch {
        $result.Status = 'Failed'
        $result.Error = $_.Exception.Message
        $testResults.Summary.Failed++
        Write-Host "Result: FAILED" -ForegroundColor Red
        Write-Host "Error: $_" -ForegroundColor Red
    }
    finally {
        $result.Duration = ((Get-Date) - $startTime).TotalSeconds
        $testResults.Tests += $result
    }
}

Write-Host "=======================================" -ForegroundColor Yellow
Write-Host "Documentation Generation Pipeline Test" -ForegroundColor Yellow
Write-Host "=======================================" -ForegroundColor Yellow
Write-Host "Starting at: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor Gray

# Test 1: Directory Structure
Test-Component -Name "Directory Structure" -Description "Verify all required directories exist" -Test {
    $requiredDirs = @(
        '.\.ai\mcp\servers',
        '.\.ai\cache',
        '.\.ai\rules',
        '.\agents\analyst_docs',
        '.\agents\research_lab',
        '.\agents\implementers',
        '.\docs\api',
        '.\docs\guides',
        '.\scripts\codegraph',
        '.\scripts\docs'
    )
    
    foreach ($dir in $requiredDirs) {
        if (-not (Test-Path $dir)) {
            throw "Missing directory: $dir"
        }
    }
    
    return $true
}

# Test 2: PowerShell Documentation Parser
Test-Component -Name "PowerShell Parser" -Description "Test PowerShell documentation extraction" -Test {
    $parserPath = ".\scripts\docs\Get-PowerShellDocumentation.ps1"
    
    if (-not (Test-Path $parserPath)) {
        throw "PowerShell parser not found at: $parserPath"
    }
    
    # Test with a sample module
    $testPath = ".\Modules\Unity-Claude-GitHub"
    if (Test-Path $testPath) {
        $tempOutput = ".\test_ps_docs_$(Get-Date -Format 'yyyyMMddHHmmss').json"
        
        try {
            & $parserPath -Path $testPath -OutputFormat JSON | Out-Null
            
            # Check if output was created
            $outputFiles = Get-ChildItem -Path . -Filter "PowerShellDocs_*.json" | 
                          Sort-Object LastWriteTime -Descending | 
                          Select-Object -First 1
            
            if (-not $outputFiles) {
                throw "No output file generated"
            }
            
            # Validate JSON structure
            $content = Get-Content $outputFiles.FullName | ConvertFrom-Json
            
            if (-not $content.GeneratedAt) {
                throw "Invalid JSON structure: missing GeneratedAt"
            }
            
            if ($null -eq $content.Files) {
                throw "Invalid JSON structure: missing Files array"
            }
            
            Write-Host "  - Extracted $($content.Functions.Count) functions" -ForegroundColor Gray
            Write-Host "  - Extracted $($content.Modules.Count) modules" -ForegroundColor Gray
            
            # Cleanup
            Remove-Item $outputFiles.FullName -Force -ErrorAction SilentlyContinue
        }
        finally {
            # Cleanup any test files
            Get-ChildItem -Path . -Filter "PowerShellDocs_*.json" | Remove-Item -Force -ErrorAction SilentlyContinue
            Get-ChildItem -Path . -Filter "PowerShellDocs_*.md" | Remove-Item -Force -ErrorAction SilentlyContinue
        }
    }
    
    return $true
}

# Test 3: Python Documentation Parser
Test-Component -Name "Python Parser" -Description "Test Python documentation extraction" -Test {
    $parserPath = ".\scripts\docs\extract_python_docs.py"
    
    if (-not (Test-Path $parserPath)) {
        throw "Python parser not found at: $parserPath"
    }
    
    # Check if Python is available
    $pythonCmd = Get-Command python -ErrorAction SilentlyContinue
    if (-not $pythonCmd) {
        Write-Host "  - Python not available, skipping Python parser test" -ForegroundColor Yellow
        $testResults.Summary.Skipped++
        $testResults.Summary.Total--
        return $true
    }
    
    # Test the parser itself
    $tempDir = [System.IO.Path]::GetTempPath()
    
    try {
        $result = python $parserPath $parserPath --output-format json --output-dir $tempDir 2>&1
        
        # Check for generated file
        $outputFiles = Get-ChildItem -Path $tempDir -Filter "python_docs_*.json" | 
                      Sort-Object LastWriteTime -Descending | 
                      Select-Object -First 1
        
        if ($outputFiles) {
            $content = Get-Content $outputFiles.FullName | ConvertFrom-Json
            
            if (-not $content.generated_at) {
                throw "Invalid JSON structure: missing generated_at"
            }
            
            Write-Host "  - Extracted $($content.classes.Count) classes" -ForegroundColor Gray
            Write-Host "  - Extracted $($content.functions.Count) functions" -ForegroundColor Gray
            
            # Cleanup
            Remove-Item $outputFiles.FullName -Force -ErrorAction SilentlyContinue
        }
    }
    finally {
        # Cleanup
        Get-ChildItem -Path $tempDir -Filter "python_docs_*.json" | Remove-Item -Force -ErrorAction SilentlyContinue
        Get-ChildItem -Path $tempDir -Filter "python_docs_*.md" | Remove-Item -Force -ErrorAction SilentlyContinue
    }
    
    return $true
}

# Test 4: Unified Documentation Generator
Test-Component -Name "Unified Generator" -Description "Test unified documentation generation" -Test {
    $generatorPath = ".\scripts\docs\New-UnifiedDocumentation.ps1"
    
    if (-not (Test-Path $generatorPath)) {
        throw "Unified generator not found at: $generatorPath"
    }
    
    # Create test output directory
    $testOutput = ".\test_docs_output_$(Get-Date -Format 'yyyyMMddHHmmss')"
    
    try {
        # Run generator on Modules directory
        $result = & $generatorPath -ProjectPath ".\Modules" -OutputPath $testOutput -GenerateIndex
        
        # Verify output files
        if (-not (Test-Path "$testOutput\unified_documentation.json")) {
            throw "Unified documentation JSON not created"
        }
        
        if (-not (Test-Path "$testOutput\index.md")) {
            throw "Index markdown not created"
        }
        
        # Validate JSON structure
        $content = Get-Content "$testOutput\unified_documentation.json" | ConvertFrom-Json
        
        if (-not $content.GeneratedAt) {
            throw "Invalid unified docs structure: missing GeneratedAt"
        }
        
        if (-not $content.Languages) {
            throw "Invalid unified docs structure: missing Languages"
        }
        
        Write-Host "  - Generated unified documentation" -ForegroundColor Gray
        Write-Host "  - Total functions: $($content.Statistics.TotalFunctions)" -ForegroundColor Gray
        Write-Host "  - Total classes: $($content.Statistics.TotalClasses)" -ForegroundColor Gray
        Write-Host "  - Languages: $($content.Languages.Keys -join ', ')" -ForegroundColor Gray
    }
    finally {
        # Cleanup
        if (Test-Path $testOutput) {
            Remove-Item $testOutput -Recurse -Force -ErrorAction SilentlyContinue
        }
    }
    
    return $true
}

# Test 5: C# Documentation Parser
Test-Component -Name "C# Parser" -Description "Test C# documentation extraction" -Test {
    $parserPath = ".\scripts\docs\Get-CSharpDocumentation.ps1"
    
    if (-not (Test-Path $parserPath)) {
        throw "C# parser not found at: $parserPath"
    }
    
    # Create a test C# file
    $testCSharp = @'
using System;
using UnityEngine;

namespace TestNamespace
{
    /// <summary>
    /// Test MonoBehaviour component
    /// </summary>
    public class TestComponent : MonoBehaviour
    {
        [SerializeField]
        [Tooltip("Test field")]
        private int testField;
        
        /// <summary>
        /// Test method
        /// </summary>
        /// <param name="value">Test parameter</param>
        /// <returns>Test return value</returns>
        public string TestMethod(int value)
        {
            return value.ToString();
        }
    }
}
'@
    
    $testFile = ".\test_component_$(Get-Date -Format 'yyyyMMddHHmmss').cs"
    
    try {
        $testCSharp | Out-File -FilePath $testFile -Encoding UTF8
        
        & $parserPath -Path $testFile -OutputFormat JSON | Out-Null
        
        # Check if output was created
        $outputFiles = Get-ChildItem -Path . -Filter "CSharpDocs_*.json" | 
                      Sort-Object LastWriteTime -Descending | 
                      Select-Object -First 1
        
        if (-not $outputFiles) {
            throw "No output file generated"
        }
        
        # Validate JSON structure
        $content = Get-Content $outputFiles.FullName | ConvertFrom-Json
        
        if (-not $content.GeneratedAt) {
            throw "Invalid JSON structure: missing GeneratedAt"
        }
        
        if ($content.Classes.Count -eq 0) {
            throw "No classes extracted from test file"
        }
        
        Write-Host "  - Extracted $($content.Classes.Count) classes" -ForegroundColor Gray
        Write-Host "  - Unity components: $($content.Statistics.UnityComponents)" -ForegroundColor Gray
        
        # Cleanup
        Remove-Item $outputFiles.FullName -Force -ErrorAction SilentlyContinue
    }
    finally {
        # Cleanup
        if (Test-Path $testFile) {
            Remove-Item $testFile -Force -ErrorAction SilentlyContinue
        }
        Get-ChildItem -Path . -Filter "CSharpDocs_*.json" | Remove-Item -Force -ErrorAction SilentlyContinue
        Get-ChildItem -Path . -Filter "CSharpDocs_*.md" | Remove-Item -Force -ErrorAction SilentlyContinue
    }
    
    return $true
}

# Test 6: HTML Generation
Test-Component -Name "HTML Generation" -Description "Test HTML documentation generation" -Test {
    $generatorPath = ".\scripts\docs\New-UnifiedDocumentation.ps1"
    
    # Create test output directory
    $testOutput = ".\test_html_output_$(Get-Date -Format 'yyyyMMddHHmmss')"
    
    try {
        # Run generator with HTML option
        $result = & $generatorPath -ProjectPath ".\Modules" -OutputPath $testOutput -GenerateIndex -GenerateHTML
        
        # Verify HTML output
        if (-not (Test-Path "$testOutput\index.html")) {
            throw "HTML documentation not created"
        }
        
        # Check HTML content
        $htmlContent = Get-Content "$testOutput\index.html" -Raw
        
        if ($htmlContent -notmatch '<title>Project Documentation</title>') {
            throw "Invalid HTML structure"
        }
        
        Write-Host "  - Generated HTML documentation" -ForegroundColor Gray
        Write-Host "  - HTML file size: $((Get-Item "$testOutput\index.html").Length) bytes" -ForegroundColor Gray
    }
    finally {
        # Cleanup
        if (Test-Path $testOutput) {
            Remove-Item $testOutput -Recurse -Force -ErrorAction SilentlyContinue
        }
    }
    
    return $true
}

# Test 7: Cross-Language Integration
Test-Component -Name "Cross-Language" -Description "Test documentation from multiple languages" -Test {
    $generatorPath = ".\scripts\docs\New-UnifiedDocumentation.ps1"
    
    # Create test output directory
    $testOutput = ".\test_multilang_output_$(Get-Date -Format 'yyyyMMddHHmmss')"
    
    try {
        # Create a safe test directory to avoid .venv symbolic link issues
        $testSourceDir = ".\test_source_$(Get-Date -Format 'yyyyMMddHHmmss')"
        New-Item -Path $testSourceDir -ItemType Directory -Force | Out-Null
        
        # Copy a few safe files for testing (avoid .venv)
        if (Test-Path ".\scripts\docs\*.ps1") {
            Copy-Item ".\scripts\docs\*.ps1" -Destination $testSourceDir -Force
        }
        if (Test-Path ".\scripts\docs\*.py") {
            Copy-Item ".\scripts\docs\*.py" -Destination $testSourceDir -Force
        }
        
        # Run generator on test directory
        $result = & $generatorPath -ProjectPath $testSourceDir -OutputPath $testOutput -GenerateIndex -IncludeLanguages @('PowerShell', 'Python', 'JavaScript')
        
        # Check for multi-language content
        $content = Get-Content "$testOutput\unified_documentation.json" | ConvertFrom-Json
        
        $languageCount = ($content.Languages.PSObject.Properties | Measure-Object).Count
        
        if ($languageCount -eq 0) {
            throw "No languages documented"
        }
        
        Write-Host "  - Documented $languageCount language(s)" -ForegroundColor Gray
        
        # Check cross-references
        if ($content.CrossReferences) {
            $crossRefCount = ($content.CrossReferences.PSObject.Properties | Measure-Object).Count
            Write-Host "  - Generated $crossRefCount cross-references" -ForegroundColor Gray
        }
    }
    finally {
        # Cleanup
        if (Test-Path $testOutput) {
            Remove-Item $testOutput -Recurse -Force -ErrorAction SilentlyContinue
        }
        if (Test-Path $testSourceDir) {
            Remove-Item $testSourceDir -Recurse -Force -ErrorAction SilentlyContinue
        }
    }
    
    return $true
}

# Complete testing
$testResults.EndTime = Get-Date
$testResults.Duration = ($testResults.EndTime - $testResults.StartTime).TotalSeconds

Write-Host "`n=======================================" -ForegroundColor Yellow
Write-Host "Test Summary" -ForegroundColor Yellow
Write-Host "=======================================" -ForegroundColor Yellow
Write-Host "Total Tests: $($testResults.Summary.Total)"
Write-Host "Passed: $($testResults.Summary.Passed)" -ForegroundColor Green
Write-Host "Failed: $($testResults.Summary.Failed)" -ForegroundColor $(if ($testResults.Summary.Failed -gt 0) { 'Red' } else { 'Gray' })
Write-Host "Skipped: $($testResults.Summary.Skipped)" -ForegroundColor Yellow
Write-Host "Duration: $([math]::Round($testResults.Duration, 2)) seconds"
Write-Host ""

# Save results if requested
if ($SaveResults) {
    $resultsFile = ".\DocumentationPipeline-TestResults-$(Get-Date -Format 'yyyyMMdd-HHmmss').json"
    $testResults | ConvertTo-Json -Depth 10 | Out-File -FilePath $resultsFile -Encoding UTF8
    Write-Host "Test results saved to: $resultsFile" -ForegroundColor Cyan
}

# Return success/failure
if ($testResults.Summary.Failed -gt 0) {
    Write-Host "`nDocumentation Pipeline Test: FAILED" -ForegroundColor Red
    exit 1
} else {
    Write-Host "`nDocumentation Pipeline Test: PASSED" -ForegroundColor Green
    exit 0
}
# SIG # Begin signature block
# MIIFzgYJKoZIhvcNAQcCoIIFvzCCBbsCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCCoLyjr+4JBxRca
# W2p9eaSq5+oV+NKNa5DzNBMsCK9+G6CCAzAwggMsMIICFKADAgECAhB1HRbZIqgr
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
# MAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIFMZU17pfNN7TskOXGPcV0pS
# 5mWyqEy1C/JQ4kJ0BgCVMA0GCSqGSIb3DQEBAQUABIIBAJehfMKLsTo4mhuTWFFv
# xDaeD2U0ZB6v6BZivut8FSN0oEVC96KIX+9pArNlRz/btfFihIqzPzU9CoFV0bdo
# QWOPLserBycLQA7WHv6ub/O9Yz52YTWihVt/BxeUmg3GVkyHStvLi02njD7TbMNL
# uCGMPkenqHbp4P9pi2d4BMFwGuRWmCjH/P0XZiqjL8U6MpRA/sPLvpw1dl4gvUSQ
# yWQ7XfdplO7atZ8mNCyC5CwgTeiLTrOXDeCv1aLsIC46lP/oKktZxEbu1La3z+nT
# 2byWGpWZStqlZdFOIw9mH46865cZpaiP2SUTS8PoBrINcHNHO7bR2cvsGhHd0B4q
# RIY=
# SIG # End signature block
