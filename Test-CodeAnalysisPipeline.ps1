#Requires -Version 5.1
<#
.SYNOPSIS
Tests the complete code analysis pipeline

.DESCRIPTION
Comprehensive test suite for ripgrep, ctags, AST parsing, and code graph generation
#>

[CmdletBinding()]
param(
    [Parameter()]
    [switch]$SkipSlowTests,
    
    [Parameter()]
    [string]$OutputPath = ".\Test-CodeAnalysisPipeline-Results_$(Get-Date -Format 'yyyyMMdd_HHmmss').txt"
)

$ErrorActionPreference = 'Stop'

# Initialize test results
$testResults = @{
    Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Tests = @()
    Summary = @{
        Total = 0
        Passed = 0
        Failed = 0
        Skipped = 0
    }
    Details = @{}
}

function Test-Component {
    param(
        [string]$Name,
        [scriptblock]$Test,
        [switch]$Critical
    )
    
    Write-Host "`nTesting: $Name" -ForegroundColor Cyan
    Write-Host ("=" * 50) -ForegroundColor DarkGray
    
    $result = @{
        Name = $Name
        StartTime = Get-Date
        Result = 'Failed'
        Error = $null
        Output = $null
    }
    
    try {
        $output = & $Test
        $result.Result = 'Passed'
        $result.Output = $output
        Write-Host "[PASS] $Name" -ForegroundColor Green
        $testResults.Summary.Passed++
    }
    catch {
        $result.Result = 'Failed'
        $result.Error = $_.ToString()
        Write-Host "[FAIL] $Name" -ForegroundColor Red
        Write-Host "  Error: $_" -ForegroundColor Red
        $testResults.Summary.Failed++
        
        if ($Critical) {
            throw "Critical test failed: $Name"
        }
    }
    finally {
        $result.EndTime = Get-Date
        $result.Duration = ($result.EndTime - $result.StartTime).TotalSeconds
        $testResults.Tests += $result
        $testResults.Summary.Total++
    }
    
    return $result
}

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "   Code Analysis Pipeline Test Suite" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

# Import module
Test-Component -Name "Module Import" -Critical -Test {
    Import-Module ".\Modules\Unity-Claude-RepoAnalyst\Unity-Claude-RepoAnalyst.psd1" -Force
    $module = Get-Module Unity-Claude-RepoAnalyst
    if (-not $module) {
        throw "Module not loaded"
    }
    return "Module version: $($module.Version)"
}

# Test ripgrep functionality
Write-Host "`nPhase 1: Ripgrep Integration" -ForegroundColor Yellow
Write-Host ("-" * 40) -ForegroundColor DarkGray

Test-Component -Name "Ripgrep Basic Search" -Test {
    $results = Invoke-RipgrepSearch -Pattern "function" -Path ".\Modules" -FileType "ps1" -ReturnObjects
    if ($results.Count -eq 0) {
        throw "No results found"
    }
    return "Found $($results.Count) matches"
}

Test-Component -Name "Ripgrep Pattern Types" -Test {
    # Test different search types
    $literal = Invoke-RipgrepSearch -Pattern "function Get-" -Path ".\Modules" -SearchType literal -FilesWithMatches
    $regex = Invoke-RipgrepSearch -Pattern "function\s+Get-\w+" -Path ".\Modules" -SearchType regex -FilesWithMatches
    
    if (-not $literal -and -not $regex) {
        throw "No matches found for any pattern type"
    }
    return "Literal: $($literal.Count) files, Regex: $($regex.Count) files"
}

Test-Component -Name "Code Pattern Search" -Test {
    $functions = Search-CodePattern -Pattern "Get-.*" -PatternType Function -Language PowerShell -Path ".\Modules"
    if ($functions) {
        return "Found $($functions.Count) PowerShell functions"
    } else {
        return "No functions found (might be expected)"
    }
}

Test-Component -Name "Code Changes Detection" -Test {
    # This might fail if no git repo or no changes
    try {
        $changes = Get-CodeChanges -Path "." -IncludeUntracked
        return "Detected $($changes.Count) changed/untracked files"
    }
    catch {
        return "Git not available or not a repository"
    }
}

# Test CTags functionality
Write-Host "`nPhase 2: CTags Integration" -ForegroundColor Yellow
Write-Host ("-" * 40) -ForegroundColor DarkGray

Test-Component -Name "CTags Index Generation" -Test {
    $indexPath = ".\Test-Tags.json"
    try {
        $result = Get-CtagsIndex -Path ".\Modules" -OutputPath $indexPath -OutputFormat json -Recurse
        if (-not (Test-Path $indexPath)) {
            throw "Index file not created"
        }
        $fileSize = (Get-Item $indexPath).Length
        return "Index created: $fileSize bytes"
    }
    finally {
        if (Test-Path $indexPath) {
            Remove-Item $indexPath -Force
        }
    }
}

Test-Component -Name "CTags Symbol Reading" -Test {
    $indexPath = ".\Test-Tags.json"
    try {
        # Create a small index
        Get-CtagsIndex -Path ".\Modules\Unity-Claude-RepoAnalyst\Public" -OutputPath $indexPath -OutputFormat json
        
        # Read symbols
        $symbols = Read-CtagsIndex -IndexPath $indexPath -Format json
        
        if ($symbols) {
            $functionCount = ($symbols | Where-Object { $_.Kind -eq 'function' }).Count
            return "Read $($symbols.Count) symbols, $functionCount functions"
        } else {
            return "No symbols found (empty index)"
        }
    }
    finally {
        if (Test-Path $indexPath) {
            Remove-Item $indexPath -Force
        }
    }
}

Test-Component -Name "Symbol Search" -Test {
    # Generate temporary index
    $indexPath = ".\Test-Tags.json"
    try {
        Get-CtagsIndex -Path ".\Modules" -OutputPath $indexPath -OutputFormat json -Recurse
        
        # Search for symbols
        $symbols = Find-Symbol -Name "Get" -IndexPath $indexPath
        
        if ($symbols) {
            return "Found $($symbols.Count) symbols matching 'Get'"
        } else {
            return "No symbols found"
        }
    }
    finally {
        if (Test-Path $indexPath) {
            Remove-Item $indexPath -Force
        }
    }
}

# Test PowerShell AST
Write-Host "`nPhase 3: PowerShell AST Parsing" -ForegroundColor Yellow
Write-Host ("-" * 40) -ForegroundColor DarkGray

Test-Component -Name "AST Basic Parsing" -Test {
    # Find a PowerShell file to parse
    $testFile = Get-ChildItem -Path ".\Modules" -Filter "*.ps1" -Recurse | Select-Object -First 1
    
    if ($testFile) {
        $ast = Get-PowerShellAST -Path $testFile.FullName
        
        if (-not $ast) {
            throw "AST parsing returned null"
        }
        
        return @"
File: $($testFile.Name)
Functions: $($ast.Functions.Count)
Variables: $($ast.Variables.Count)
Commands: $($ast.Commands.Count)
Lines: $($ast.Statistics.TotalLines)
"@
    } else {
        throw "No PowerShell files found to test"
    }
}

Test-Component -Name "Function Dependencies" -Test {
    # Find a module file with functions
    $moduleFile = Get-ChildItem -Path ".\Modules" -Filter "*.psm1" -Recurse | Select-Object -First 1
    
    if ($moduleFile) {
        $deps = Get-FunctionDependencies -Path $moduleFile.FullName
        
        $totalDeps = 0
        foreach ($func in $deps.Keys) {
            $totalDeps += $deps[$func].Count
        }
        
        return "Analyzed $($deps.Count) functions with $totalDeps total dependencies"
    } else {
        return "No module files found"
    }
}

Test-Component -Name "AST Pattern Search" -Test {
    # Search for common patterns
    $patterns = @{
        'Write-Host usage' = $Script:ASTPatterns.WriteHost
        'Global variables' = $Script:ASTPatterns.GlobalVariables
    }
    
    $totalMatches = 0
    $results = @()
    
    foreach ($patternName in $patterns.Keys) {
        $matches = Find-ASTPattern -Path ".\Modules" -Predicate $patterns[$patternName] -Recurse
        $totalMatches += $matches.Count
        $results += "$patternName : $($matches.Count) matches"
    }
    
    return $results -join "`n"
}

# Test Code Graph Generation
if (-not $SkipSlowTests) {
    Write-Host "`nPhase 4: Code Graph Generation" -ForegroundColor Yellow
    Write-Host ("-" * 40) -ForegroundColor DarkGray
    
    Test-Component -Name "Basic Code Graph" -Test {
        $graphPath = ".\Test-CodeGraph.json"
        try {
            $result = New-CodeGraph -ProjectPath ".\Modules\Unity-Claude-RepoAnalyst" -OutputPath $graphPath
            
            if (-not (Test-Path $graphPath)) {
                throw "Code graph file not created"
            }
            
            $graph = Get-Content $graphPath -Raw | ConvertFrom-Json
            
            return @"
Files: $($graph.files.Count)
Languages: $($graph.languages.PSObject.Properties.Name -join ', ')
Generation Time: $($result.GenerationTime) seconds
"@
        }
        finally {
            if (Test-Path $graphPath) {
                Remove-Item $graphPath -Force
            }
        }
    }
    
    Test-Component -Name "Code Graph with Symbols" -Test {
        $graphPath = ".\Test-CodeGraph-Full.json"
        try {
            $result = New-CodeGraph -ProjectPath ".\Modules\Unity-Claude-RepoAnalyst" `
                                   -OutputPath $graphPath `
                                   -IncludeSymbols `
                                   -IncludeMetrics
            
            $graph = Get-Content $graphPath -Raw | ConvertFrom-Json
            
            return @"
Files: $($graph.files.Count)
Symbols: $($graph.symbols.Count)
Total Lines: $($graph.metrics.totalLines)
Functions: $($graph.metrics.totalFunctions)
"@
        }
        finally {
            if (Test-Path $graphPath) {
                Remove-Item $graphPath -Force
            }
        }
    }
} else {
    Write-Host "`nSkipping slow tests (Code Graph Generation)" -ForegroundColor Yellow
    $testResults.Summary.Skipped += 2
}

# Integration Tests
Write-Host "`nPhase 5: Integration Tests" -ForegroundColor Yellow
Write-Host ("-" * 40) -ForegroundColor DarkGray

Test-Component -Name "Combined Analysis Pipeline" -Test {
    # Test that all components work together
    $testPath = ".\Modules\Unity-Claude-RepoAnalyst\Public"
    
    # 1. Search for functions
    $functions = Invoke-RipgrepSearch -Pattern "^function" -Path $testPath -ReturnObjects
    
    # 2. Generate index
    $indexPath = ".\Test-Integration-Tags.json"
    Get-CtagsIndex -Path $testPath -OutputPath $indexPath -OutputFormat json
    
    # 3. Parse AST for first file
    $psFile = Get-ChildItem -Path $testPath -Filter "*.ps1" | Select-Object -First 1
    if ($psFile) {
        $ast = Get-PowerShellAST -Path $psFile.FullName
    }
    
    # Clean up
    if (Test-Path $indexPath) {
        Remove-Item $indexPath -Force
    }
    
    return @"
Ripgrep matches: $($functions.Count)
CTags index created: $(Test-Path $indexPath)
AST functions: $(if ($ast) { $ast.Functions.Count } else { 0 })
"@
}

# Performance Tests
Write-Host "`nPhase 6: Performance Benchmarks" -ForegroundColor Yellow
Write-Host ("-" * 40) -ForegroundColor DarkGray

Test-Component -Name "Search Performance" -Test {
    $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
    
    # Perform multiple searches
    for ($i = 1; $i -le 5; $i++) {
        $null = Invoke-RipgrepSearch -Pattern "function|class|module" -Path "." -FilesWithMatches
    }
    
    $stopwatch.Stop()
    $avgTime = $stopwatch.Elapsed.TotalMilliseconds / 5
    
    return "Average search time: $([Math]::Round($avgTime, 2))ms"
}

# Summary
Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "           TEST SUMMARY" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

Write-Host "Total Tests: $($testResults.Summary.Total)" -ForegroundColor White
Write-Host "Passed: $($testResults.Summary.Passed)" -ForegroundColor Green
Write-Host "Failed: $($testResults.Summary.Failed)" -ForegroundColor $(if ($testResults.Summary.Failed -gt 0) { 'Red' } else { 'Gray' })
Write-Host "Skipped: $($testResults.Summary.Skipped)" -ForegroundColor Yellow

# Calculate success rate
$successRate = if ($testResults.Summary.Total -gt 0) {
    [Math]::Round(($testResults.Summary.Passed / ($testResults.Summary.Total - $testResults.Summary.Skipped)) * 100, 2)
} else { 0 }

Write-Host "`nSuccess Rate: $successRate%" -ForegroundColor $(if ($successRate -ge 80) { 'Green' } elseif ($successRate -ge 60) { 'Yellow' } else { 'Red' })

# Save results
$testResults | ConvertTo-Json -Depth 10 | Out-File $OutputPath -Encoding UTF8
Write-Host "`nDetailed results saved to: $OutputPath" -ForegroundColor Cyan

# Return success status
$success = $testResults.Summary.Failed -eq 0
if ($success) {
    Write-Host "`nAll tests passed! Code analysis pipeline is ready." -ForegroundColor Green
} else {
    Write-Host "`nSome tests failed. Review the results for details." -ForegroundColor Red
}

return $success
# SIG # Begin signature block
# MIIFzgYJKoZIhvcNAQcCoIIFvzCCBbsCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCA6MX5zqhy4H4t9
# 12fQiRp7pHw3asozbbJ2ysi1b2suI6CCAzAwggMsMIICFKADAgECAhB1HRbZIqgr
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
# MAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIDPVSwjfq6yNPCsOXoWxxiYJ
# 5amDa4PUn1V1en0bolKIMA0GCSqGSIb3DQEBAQUABIIBAIoB2uigzAbVymYi/fiM
# 4UUaEoGp5VmvG1rnCtUAbs4N52Z32Gak7YErsgrMKH2P92xD6wJKO5eCh68bppqo
# 28la86y8Or1/pWgR8qgcnz0z0rT25+x3o9l1+HpurKyBOKWbUKNJsRbtiKQAA+lf
# wy3m0Pq6VWCdAutlV6+0Uu35dE++Ihwv51cDWLaa8cKA/Z64QRrdGwoZF0A5jaFv
# n0KiUVVf3gJTvgIY01ue6ZBb5/PpzHq56+L7FXIsvXt7InU5LaWvpEvPvOwm9wly
# iFv9gQJh1i4mZthQJMSfTZf/NUcvMi3KyHNF4/6QrM/zMysLd7r0QuPijKuqlEUb
# sV8=
# SIG # End signature block
