# Test-ObsolescenceDetection.ps1
# Comprehensive test suite for Obsolescence Detection module

#Requires -Version 5.1

param(
    [switch]$SaveResults,
    [switch]$Verbose,
    [switch]$TestPerplexity,
    [switch]$TestUnreachable,
    [switch]$TestRedundancy,
    [switch]$TestComplexity,
    [switch]$TestDocumentationDrift,
    [switch]$TestAll
)

# Set verbose preference
if ($Verbose) {
    $VerbosePreference = "Continue"
}

# If TestAll or no specific test selected, test everything
if ($TestAll -or (-not $TestPerplexity -and -not $TestUnreachable -and 
                   -not $TestRedundancy -and -not $TestComplexity -and 
                   -not $TestDocumentationDrift)) {
    $TestPerplexity = $true
    $TestUnreachable = $true
    $TestRedundancy = $true
    $TestComplexity = $true
    $TestDocumentationDrift = $true
}

# Import modules
$modulePath = Join-Path $PSScriptRoot "Unity-Claude-CPG.psd1"
$obsolescencePath = Join-Path $PSScriptRoot "Unity-Claude-ObsolescenceDetection.psm1"
$enumPath = Join-Path $PSScriptRoot "Unity-Claude-CPG-Enums.ps1"

Write-Host "Testing Obsolescence Detection Module" -ForegroundColor Cyan
Write-Host "=====================================" -ForegroundColor Cyan
Write-Host ""

# Load enums
if (Test-Path $enumPath) {
    Write-Host "Loading enum definitions..." -ForegroundColor Gray
    . $enumPath
} else {
    Write-Error "Enum file not found: $enumPath"
    exit 1
}

# Import modules
Write-Host "Importing modules..." -ForegroundColor Gray
Import-Module $modulePath -Force
Import-Module $obsolescencePath -Force

# Initialize test results
$results = @{
    Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Tests = @()
    Summary = @{
        Total = 0
        Passed = 0
        Failed = 0
    }
}

# Create test CPG graph
Write-Host "`nCreating test CPG graph..." -ForegroundColor Gray
$testGraph = New-CPGraph -Name "TestGraph"

# Add test nodes
$moduleNode = New-CPGNode -Name "TestModule" -Type Module -Properties @{
    FilePath = "TestModule.psm1"
    LineNumber = 1
}
Add-CPGNode -Graph $testGraph -Node $moduleNode

# Add documented function
$func1 = New-CPGNode -Name "Get-TestData" -Type Function -Properties @{
    FilePath = "TestModule.psm1"
    LineNumber = 10
    IsExported = $true
    Parameters = @(
        @{ Name = "Path"; Type = "string" }
        @{ Name = "Filter"; Type = "string" }
    )
    Code = @'
function Get-TestData {
    param(
        [string]$Path,
        [string]$Filter
    )
    
    if (Test-Path $Path) {
        $data = Get-Content $Path
        if ($Filter) {
            $data = $data | Where-Object { $_ -match $Filter }
        }
        return $data
    }
    return $null
}
'@
    CommentHelp = @'
<#
.SYNOPSIS
Gets test data from a file

.DESCRIPTION
Retrieves test data from the specified file path with optional filtering

.PARAMETER Path
Path to the data file

.PARAMETER Filter
Optional regex filter

.EXAMPLE
Get-TestData -Path "data.txt" -Filter "test"

.OUTPUTS
[string[]] Array of data lines
#>
'@
}
Add-CPGNode -Graph $testGraph -Node $func1

# Add undocumented function with high complexity
$func2 = New-CPGNode -Name "Process-ComplexData" -Type Function -Properties @{
    FilePath = "TestModule.psm1"
    LineNumber = 50
    IsExported = $true
    Parameters = @(
        @{ Name = "Data"; Type = "object[]" }
        @{ Name = "Mode"; Type = "string" }
    )
    Code = @'
function Process-ComplexData {
    param($Data, $Mode)
    
    $result = @()
    foreach ($item in $Data) {
        if ($Mode -eq "Simple") {
            if ($item.Type -eq "A") {
                if ($item.Value -gt 10) {
                    $result += $item
                } elseif ($item.Value -gt 5) {
                    $item.Value *= 2
                    $result += $item
                } else {
                    continue
                }
            } elseif ($item.Type -eq "B") {
                switch ($item.SubType) {
                    "X" { $result += $item }
                    "Y" { 
                        if ($item.Value -lt 100) {
                            $result += $item
                        }
                    }
                    "Z" { continue }
                }
            }
        } elseif ($Mode -eq "Complex") {
            # More complex logic here
            for ($i = 0; $i -lt $item.Count; $i++) {
                if ($item[$i] -match "pattern") {
                    $result += $item[$i]
                }
            }
        }
    }
    return $result
}
'@
}
Add-CPGNode -Graph $testGraph -Node $func2

# Add duplicate function (for redundancy testing)
$func3 = New-CPGNode -Name "Get-TestDataCopy" -Type Function -Properties @{
    FilePath = "TestModule.psm1"
    LineNumber = 100
    Code = @'
function Get-TestDataCopy {
    param(
        [string]$Path,
        [string]$Filter
    )
    
    if (Test-Path $Path) {
        $data = Get-Content $Path
        if ($Filter) {
            $data = $data | Where-Object { $_ -match $Filter }
        }
        return $data
    }
    return $null
}
'@
}
Add-CPGNode -Graph $testGraph -Node $func3

# Add unreachable function (not called anywhere)
$func4 = New-CPGNode -Name "Helper-UnusedFunction" -Type Function -Properties @{
    FilePath = "TestModule.psm1"
    LineNumber = 120
    Code = @'
function Helper-UnusedFunction {
    Write-Host "This function is never called"
}
'@
}
Add-CPGNode -Graph $testGraph -Node $func4

# Add edges (using actual node IDs)
Add-CPGEdge -Graph $testGraph -Edge (New-CPGEdge -Source $moduleNode.Id -Target $func1.Id -Type Contains)
Add-CPGEdge -Graph $testGraph -Edge (New-CPGEdge -Source $moduleNode.Id -Target $func2.Id -Type Contains)
Add-CPGEdge -Graph $testGraph -Edge (New-CPGEdge -Source $moduleNode.Id -Target $func3.Id -Type Contains)
Add-CPGEdge -Graph $testGraph -Edge (New-CPGEdge -Source $moduleNode.Id -Target $func4.Id -Type Contains)
Add-CPGEdge -Graph $testGraph -Edge (New-CPGEdge -Source $func2.Id -Target $func1.Id -Type Calls)

Write-Host "Test graph created with $($testGraph.Nodes.Count) nodes and $($testGraph.Edges.Count) edges" -ForegroundColor Green

# Test 1: Code Perplexity Analysis
if ($TestPerplexity) {
    Write-Host "`nTest 1: Code Perplexity Analysis" -ForegroundColor Yellow
    try {
        $testCode = @'
function Test-Function {
    # Normal code
    $result = @()
    
    # This line has no context
    $xyz123 = Get-RandomThing
    
    # Normal pattern
    foreach ($item in $collection) {
        $result += $item
    }
    
    # Isolated variable with no references
    $orphanVariable = 42
    
    return $result
}
'@
        
        $perplexity = Get-CodePerplexity -CodeContent $testCode -Language PowerShell -Verbose
        
        if ($perplexity -and $perplexity.Scores) {
            Write-Host "  [PASS] Perplexity analysis completed" -ForegroundColor Green
            Write-Host "    Total lines: $($perplexity.TotalLines)" -ForegroundColor Gray
            Write-Host "    Normal lines: $($perplexity.Summary.Normal)" -ForegroundColor Gray
            Write-Host "    Suspicious lines: $($perplexity.Summary.Suspicious)" -ForegroundColor Gray
            Write-Host "    High perplexity lines: $($perplexity.Summary.HighPerplexity)" -ForegroundColor Gray
            Write-Host "    Dead code candidates: $($perplexity.DeadCodeCandidates.Count)" -ForegroundColor Gray
            
            $results.Tests += @{
                Name = "Code Perplexity Analysis"
                Status = "Passed"
                Details = $perplexity.Summary
            }
            $results.Summary.Passed++
        } else {
            throw "No perplexity results returned"
        }
    }
    catch {
        Write-Host "  [FAIL] $($_.Exception.Message)" -ForegroundColor Red
        $results.Tests += @{
            Name = "Code Perplexity Analysis"
            Status = "Failed"
            Error = $_.Exception.Message
        }
        $results.Summary.Failed++
    }
    $results.Summary.Total++
}

# Test 2: Unreachable Code Detection
if ($TestUnreachable) {
    Write-Host "`nTest 2: Unreachable Code Detection" -ForegroundColor Yellow
    try {
        $unreachable = Find-UnreachableCode -Graph $testGraph -Verbose
        
        if ($unreachable) {
            $hasUnreachable = $unreachable.UnreachableCode.Count -gt 0
            
            Write-Host "  [PASS] Unreachable code analysis completed" -ForegroundColor Green
            Write-Host "    Total nodes: $($unreachable.Statistics.TotalNodes)" -ForegroundColor Gray
            Write-Host "    Reachable nodes: $($unreachable.Statistics.ReachableNodes)" -ForegroundColor Gray
            Write-Host "    Unreachable nodes: $($unreachable.Statistics.UnreachableNodes)" -ForegroundColor Gray
            Write-Host "    Coverage: $($unreachable.Statistics.Coverage)%" -ForegroundColor Gray
            
            if ($hasUnreachable) {
                Write-Host "    Found unreachable:" -ForegroundColor Yellow
                foreach ($item in $unreachable.UnreachableCode) {
                    Write-Host "      - $($item.Name) (Line $($item.Line))" -ForegroundColor Yellow
                }
            }
            
            # Verify that Helper-UnusedFunction is detected as unreachable
            $foundUnused = $unreachable.UnreachableCode | Where-Object { $_.Name -eq "Helper-UnusedFunction" }
            if ($foundUnused) {
                Write-Host "    Correctly identified Helper-UnusedFunction as unreachable" -ForegroundColor Green
            }
            
            $results.Tests += @{
                Name = "Unreachable Code Detection"
                Status = "Passed"
                UnreachableCount = $unreachable.UnreachableCode.Count
                FoundExpectedUnreachable = [bool]$foundUnused
            }
            $results.Summary.Passed++
        } else {
            throw "No unreachable analysis results"
        }
    }
    catch {
        Write-Host "  [FAIL] $($_.Exception.Message)" -ForegroundColor Red
        $results.Tests += @{
            Name = "Unreachable Code Detection"
            Status = "Failed"
            Error = $_.Exception.Message
        }
        $results.Summary.Failed++
    }
    $results.Summary.Total++
}

# Test 3: Code Redundancy Testing
if ($TestRedundancy) {
    Write-Host "`nTest 3: Code Redundancy Testing" -ForegroundColor Yellow
    try {
        $redundancy = Test-CodeRedundancy -Graph $testGraph -SimilarityThreshold 0.85 -Verbose
        
        if ($redundancy) {
            Write-Host "  [PASS] Redundancy analysis completed" -ForegroundColor Green
            Write-Host "    Total blocks: $($redundancy.Statistics.TotalBlocks)" -ForegroundColor Gray
            Write-Host "    Duplicate groups: $($redundancy.Statistics.DuplicateGroups)" -ForegroundColor Gray
            Write-Host "    Redundancy rate: $($redundancy.Statistics.RedundancyRate)%" -ForegroundColor Gray
            
            if ($redundancy.ExactDuplicates.Count -gt 0) {
                Write-Host "    Found exact duplicates:" -ForegroundColor Yellow
                foreach ($dup in $redundancy.ExactDuplicates) {
                    Write-Host "      - $($dup.Primary.Name) and $($dup.Duplicates.Count) other(s)" -ForegroundColor Yellow
                }
            }
            
            # Verify that Get-TestData and Get-TestDataCopy are detected as duplicates
            $foundDuplicate = $redundancy.Duplicates | Where-Object { 
                ($_.Primary.Name -eq "Get-TestData" -and $_.Duplicates.Name -contains "Get-TestDataCopy") -or
                ($_.Primary.Name -eq "Get-TestDataCopy" -and $_.Duplicates.Name -contains "Get-TestData")
            }
            
            if ($foundDuplicate) {
                Write-Host "    Correctly identified Get-TestData/Get-TestDataCopy as duplicates" -ForegroundColor Green
            }
            
            $results.Tests += @{
                Name = "Code Redundancy Testing"
                Status = "Passed"
                DuplicateGroups = $redundancy.Statistics.DuplicateGroups
                FoundExpectedDuplicates = [bool]$foundDuplicate
            }
            $results.Summary.Passed++
        } else {
            throw "No redundancy analysis results"
        }
    }
    catch {
        Write-Host "  [FAIL] $($_.Exception.Message)" -ForegroundColor Red
        $results.Tests += @{
            Name = "Code Redundancy Testing"
            Status = "Failed"
            Error = $_.Exception.Message
        }
        $results.Summary.Failed++
    }
    $results.Summary.Total++
}

# Test 4: Code Complexity Metrics
if ($TestComplexity) {
    Write-Host "`nTest 4: Code Complexity Metrics" -ForegroundColor Yellow
    try {
        $complexity = Get-CodeComplexityMetrics -Graph $testGraph -IncludeHalstead -Verbose
        
        if ($complexity) {
            Write-Host "  [PASS] Complexity analysis completed" -ForegroundColor Green
            Write-Host "    Total functions: $($complexity.Summary.TotalFunctions)" -ForegroundColor Gray
            Write-Host "    Average cyclomatic complexity: $([Math]::Round($complexity.Summary.AverageCyclomaticComplexity, 2))" -ForegroundColor Gray
            Write-Host "    High risk functions: $($complexity.Summary.HighRiskFunctions)" -ForegroundColor Gray
            Write-Host "    Obsolescence candidates: $($complexity.Summary.ObsolescenceCandidates)" -ForegroundColor Gray
            
            # Check if Process-ComplexData is identified as high complexity
            $complexFunc = $complexity.Metrics | Where-Object { $_.Name -eq "Process-ComplexData" }
            if ($complexFunc -and $complexFunc.RiskLevel -in @("High", "VeryHigh")) {
                Write-Host "    Correctly identified Process-ComplexData as high complexity" -ForegroundColor Green
                Write-Host "      Cyclomatic: $($complexFunc.CyclomaticComplexity)" -ForegroundColor Gray
                Write-Host "      Risk Level: $($complexFunc.RiskLevel)" -ForegroundColor Gray
            }
            
            $results.Tests += @{
                Name = "Code Complexity Metrics"
                Status = "Passed"
                HighRiskCount = $complexity.Summary.HighRiskFunctions
                IdentifiedComplexFunction = ($complexFunc -and $complexFunc.RiskLevel -in @("High", "VeryHigh"))
            }
            $results.Summary.Passed++
        } else {
            throw "No complexity analysis results"
        }
    }
    catch {
        Write-Host "  [FAIL] $($_.Exception.Message)" -ForegroundColor Red
        $results.Tests += @{
            Name = "Code Complexity Metrics"
            Status = "Failed"
            Error = $_.Exception.Message
        }
        $results.Summary.Failed++
    }
    $results.Summary.Total++
}

# Test 5: Documentation Drift Detection
if ($TestDocumentationDrift) {
    Write-Host "`nTest 5: Documentation Drift Detection" -ForegroundColor Yellow
    
    # Test 5a: Compare Code to Documentation
    Write-Host "  5a: Compare Code to Documentation" -ForegroundColor Cyan
    try {
        $drift = Compare-CodeToDocumentation -Graph $testGraph -Verbose
        
        if ($drift) {
            Write-Host "    [PASS] Documentation comparison completed" -ForegroundColor Green
            Write-Host "      Total elements: $($drift.Statistics.TotalCodeElements)" -ForegroundColor Gray
            Write-Host "      Elements with issues: $($drift.Statistics.ElementsWithIssues)" -ForegroundColor Gray
            Write-Host "      Coverage rate: $($drift.Statistics.CoverageRate)%" -ForegroundColor Gray
            
            $results.Tests += @{
                Name = "Compare Code to Documentation"
                Status = "Passed"
                IssueCount = $drift.Statistics.TotalIssues
            }
            $results.Summary.Passed++
        } else {
            throw "No drift analysis results"
        }
    }
    catch {
        Write-Host "    [FAIL] $($_.Exception.Message)" -ForegroundColor Red
        $results.Tests += @{
            Name = "Compare Code to Documentation"
            Status = "Failed"
            Error = $_.Exception.Message
        }
        $results.Summary.Failed++
    }
    $results.Summary.Total++
    
    # Test 5b: Find Undocumented Features
    Write-Host "  5b: Find Undocumented Features" -ForegroundColor Cyan
    try {
        $undocumented = Find-UndocumentedFeatures -Graph $testGraph -MinimumVisibility Public -Verbose
        
        if ($undocumented) {
            Write-Host "    [PASS] Undocumented feature search completed" -ForegroundColor Green
            Write-Host "      Total public elements: $($undocumented.Statistics.TotalPublicElements)" -ForegroundColor Gray
            Write-Host "      Undocumented count: $($undocumented.Statistics.UndocumentedCount)" -ForegroundColor Gray
            Write-Host "      Documentation coverage: $($undocumented.Statistics.DocumentationCoverage)%" -ForegroundColor Gray
            
            # Check if Process-ComplexData is identified as undocumented
            $undocFunc = $undocumented.UndocumentedFeatures | Where-Object { $_.Name -eq "Process-ComplexData" }
            if ($undocFunc) {
                Write-Host "      Correctly identified Process-ComplexData as undocumented" -ForegroundColor Green
            }
            
            $results.Tests += @{
                Name = "Find Undocumented Features"
                Status = "Passed"
                UndocumentedCount = $undocumented.Statistics.UndocumentedCount
                FoundExpectedUndocumented = [bool]$undocFunc
            }
            $results.Summary.Passed++
        } else {
            throw "No undocumented feature results"
        }
    }
    catch {
        Write-Host "    [FAIL] $($_.Exception.Message)" -ForegroundColor Red
        $results.Tests += @{
            Name = "Find Undocumented Features"
            Status = "Failed"
            Error = $_.Exception.Message
        }
        $results.Summary.Failed++
    }
    $results.Summary.Total++
    
    # Test 5c: Test Documentation Accuracy
    Write-Host "  5c: Test Documentation Accuracy" -ForegroundColor Cyan
    try {
        $accuracy = Test-DocumentationAccuracy -Graph $testGraph -TestExamples -Verbose
        
        if ($accuracy) {
            Write-Host "    [PASS] Documentation accuracy test completed" -ForegroundColor Green
            Write-Host "      Tested items: $($accuracy.Statistics.TestedItems)" -ForegroundColor Gray
            Write-Host "      Passed items: $($accuracy.Statistics.PassedItems)" -ForegroundColor Gray
            Write-Host "      Accuracy score: $($accuracy.Statistics.AccuracyScore)%" -ForegroundColor Gray
            
            $results.Tests += @{
                Name = "Test Documentation Accuracy"
                Status = "Passed"
                AccuracyScore = $accuracy.Statistics.AccuracyScore
            }
            $results.Summary.Passed++
        } else {
            throw "No accuracy test results"
        }
    }
    catch {
        Write-Host "    [FAIL] $($_.Exception.Message)" -ForegroundColor Red
        $results.Tests += @{
            Name = "Test Documentation Accuracy"
            Status = "Failed"
            Error = $_.Exception.Message
        }
        $results.Summary.Failed++
    }
    $results.Summary.Total++
    
    # Test 5d: Generate Documentation Suggestions
    Write-Host "  5d: Generate Documentation Suggestions" -ForegroundColor Cyan
    try {
        # Use results from previous tests if available
        $suggestions = Update-DocumentationSuggestions -Graph $testGraph `
            -DriftAnalysis $drift `
            -UndocumentedFeatures $undocumented `
            -Verbose
        
        if ($suggestions) {
            Write-Host "    [PASS] Documentation suggestions generated" -ForegroundColor Green
            Write-Host "      Templates generated: $($suggestions.Summary.TemplatesGenerated)" -ForegroundColor Gray
            Write-Host "      Updates needed: $($suggestions.Summary.UpdatesNeeded)" -ForegroundColor Gray
            Write-Host "      New documentation needed: $($suggestions.Summary.NewDocumentationNeeded)" -ForegroundColor Gray
            Write-Host "      Estimated effort: $($suggestions.EffortEstimate.EstimatedHours) hours" -ForegroundColor Gray
            
            $results.Tests += @{
                Name = "Generate Documentation Suggestions"
                Status = "Passed"
                TotalSuggestions = $suggestions.EffortEstimate.TotalItems
                EstimatedHours = $suggestions.EffortEstimate.EstimatedHours
            }
            $results.Summary.Passed++
        } else {
            throw "No suggestions generated"
        }
    }
    catch {
        Write-Host "    [FAIL] $($_.Exception.Message)" -ForegroundColor Red
        $results.Tests += @{
            Name = "Generate Documentation Suggestions"
            Status = "Failed"
            Error = $_.Exception.Message
        }
        $results.Summary.Failed++
    }
    $results.Summary.Total++
}

# Display summary
Write-Host "`n=====================================" -ForegroundColor Cyan
Write-Host "Test Summary" -ForegroundColor Cyan
Write-Host "=====================================" -ForegroundColor Cyan
Write-Host "Total Tests: $($results.Summary.Total)"
Write-Host "Passed: $($results.Summary.Passed)" -ForegroundColor Green
Write-Host "Failed: $($results.Summary.Failed)" -ForegroundColor Red

$passRate = if ($results.Summary.Total -gt 0) {
    [Math]::Round(($results.Summary.Passed / $results.Summary.Total) * 100, 1)
} else { 0 }

Write-Host "Pass Rate: $passRate%"

# Save results if requested
if ($SaveResults) {
    $resultsFile = Join-Path $PSScriptRoot "ObsolescenceDetection-TestResults-$(Get-Date -Format 'yyyyMMdd-HHmmss').json"
    $results | ConvertTo-Json -Depth 10 | Out-File -FilePath $resultsFile -Encoding UTF8
    Write-Host "`nResults saved to: $resultsFile" -ForegroundColor Gray
}

# Return exit code
if ($results.Summary.Failed -eq 0) {
    Write-Host "`nAll tests passed!" -ForegroundColor Green
    exit 0
} else {
    Write-Host "`nSome tests failed. Please review the errors above." -ForegroundColor Yellow
    exit 1
}
# SIG # Begin signature block
# MIIFzgYJKoZIhvcNAQcCoIIFvzCCBbsCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCCDmqDNSjxZ5DUV
# aOvT/vZjROzkN8B1q+VMlLOIiAyZjqCCAzAwggMsMIICFKADAgECAhB1HRbZIqgr
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
# MAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEICaHsM1fvPq/czC4nlp49lZD
# tw2jhEMH27VkgGwVGYnvMA0GCSqGSIb3DQEBAQUABIIBADxeu53Sl0RWY7v2nGVR
# kmll+8jhuuBUxRYS9weBbc0b+9xa+wPoU+3L286pKWVPGwZMQoLlV68PFmLZw6Uo
# DhhfPUHEaj7Ek7lduie026NoLO1GEhpL9VLt3uAbfGVGcheEWtdBdBfurRWxC6HA
# Ek+MQX5RXvnnZQJBxyE46X2WqCl2WygWd1fFQ34o61l4C2aWnZAYg63BjNvQiYHV
# y+5Y6TkvU/H3McBFRUfJblfLg99yyBm6U8vyU52LoS9al9MhqJSNmd9AClv62Pks
# PdBcczVyve6uwNUrcZ0qeBs/OdPym9ISfrCFK5cHweL3h1DhqgVvcYDSCR8ktOg1
# st8=
# SIG # End signature block
