# Test-PredictiveEvolution.ps1
# Test script for Week 4 Day 1: Code Evolution Analysis Module
# Date: 2025-08-29

param(
    [switch]$Verbose,
    [switch]$SaveReport,
    [string]$OutputPath = ".\PredictiveEvolution-TestResults-$(Get-Date -Format 'yyyyMMdd-HHmmss').json"
)

if ($Verbose) { $VerbosePreference = "Continue" }

Write-Host "=== Testing Week 4 Day 1: Code Evolution Analysis Module ===" -ForegroundColor Cyan
Write-Host "Test Started: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor Green

$testResults = @{
    TestName = "PredictiveEvolution Module Test"
    Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    ModulePath = ".\Modules\Unity-Claude-CPG\Core\Predictive-Evolution.psm1"
    Results = @()
    Summary = @{
        Total = 0
        Passed = 0
        Failed = 0
        Warnings = 0
    }
}

function Test-Function {
    param(
        [string]$FunctionName,
        [scriptblock]$TestCode,
        [string]$Description = ""
    )
    
    $testResults.Summary.Total++
    $testStart = Get-Date
    
    try {
        Write-Host "Testing $FunctionName..." -ForegroundColor Yellow -NoNewline
        
        $result = & $TestCode
        $success = $true
        $error = $null
        
        Write-Host " PASS" -ForegroundColor Green
        $testResults.Summary.Passed++
    }
    catch {
        $success = $false
        $error = $_.Exception.Message
        Write-Host " FAIL" -ForegroundColor Red
        Write-Host "  Error: $error" -ForegroundColor Red
        $testResults.Summary.Failed++
    }
    
    $testEnd = Get-Date
    $duration = ($testEnd - $testStart).TotalMilliseconds
    
    $testResults.Results += [PSCustomObject]@{
        FunctionName = $FunctionName
        Description = $Description
        Success = $success
        Error = $error
        Duration = [math]::Round($duration, 2)
        Result = $result
    }
    
    return $success
}

# Test 1: Module Import
$moduleImported = Test-Function -FunctionName "Module Import" -Description "Import Predictive-Evolution module" -TestCode {
    try {
        if (Get-Module -Name "Predictive-Evolution" -ErrorAction SilentlyContinue) {
            Remove-Module -Name "Predictive-Evolution" -Force
        }
        
        Import-Module ".\Modules\Unity-Claude-CPG\Core\Predictive-Evolution.psm1" -Force -DisableNameChecking
        
        $module = Get-Module -Name "Predictive-Evolution"
        if (-not $module) {
            throw "Module not imported successfully"
        }
        
        $expectedFunctions = @(
            'Get-GitCommitHistory'
            'Get-CodeChurnMetrics'
            'Get-FileHotspots'
            'Get-ComplexityTrends'
            'Get-PatternEvolution'
            'New-EvolutionReport'
        )
        
        $availableFunctions = $module.ExportedFunctions.Keys
        $missingFunctions = $expectedFunctions | Where-Object { $_ -notin $availableFunctions }
        
        if ($missingFunctions) {
            throw "Missing functions: $($missingFunctions -join ', ')"
        }
        
        return @{
            ModuleName = $module.Name
            Version = $module.Version
            FunctionCount = $availableFunctions.Count
            Functions = $availableFunctions
        }
    }
    catch {
        throw "Module import failed: $($_.Exception.Message)"
    }
}

if (-not $moduleImported) {
    Write-Host "Module import failed - aborting remaining tests" -ForegroundColor Red
    $testResults | ConvertTo-Json -Depth 10 | Out-File -FilePath $OutputPath -Encoding UTF8
    exit 1
}

# Test 2: Git Repository Check
Test-Function -FunctionName "Git Repository Check" -Description "Verify git repository availability" -TestCode {
    $gitVersion = git --version 2>$null
    if (-not $gitVersion) {
        throw "Git is not available"
    }
    
    $gitDir = git rev-parse --git-dir 2>$null
    if (-not $gitDir) {
        Write-Warning "Current directory is not a git repository - some tests may be limited"
        $testResults.Summary.Warnings++
        return @{ Status = "NoRepository"; GitVersion = $gitVersion }
    }
    
    return @{
        Status = "RepositoryFound"
        GitVersion = $gitVersion
        GitDirectory = $gitDir
    }
}

# Test 3: Get-GitCommitHistory Function
Test-Function -FunctionName "Get-GitCommitHistory" -Description "Test git commit history retrieval" -TestCode {
    try {
        # Test with limited commits to avoid timeouts
        $commits = Get-GitCommitHistory -MaxCount 10 -Since "1.month.ago" -ErrorAction Stop
        
        if (-not $commits -or $commits.Count -eq 0) {
            Write-Warning "No commits found in the last month"
            $testResults.Summary.Warnings++
            return @{ CommitCount = 0; Status = "NoCommits" }
        }
        
        # Validate commit structure
        $sampleCommit = $commits[0]
        $requiredProperties = @('Hash', 'Author', 'Date', 'Subject', 'FilesChanged')
        
        foreach ($prop in $requiredProperties) {
            if (-not $sampleCommit.PSObject.Properties[$prop]) {
                throw "Missing property: $prop"
            }
        }
        
        return @{
            CommitCount = $commits.Count
            FirstCommit = $sampleCommit.Hash.Substring(0, 8)
            DateRange = "$($commits[-1].Date.ToString('yyyy-MM-dd')) to $($commits[0].Date.ToString('yyyy-MM-dd'))"
            Authors = ($commits | Select-Object Author -Unique).Count
        }
    }
    catch {
        throw "Git commit history retrieval failed: $($_.Exception.Message)"
    }
}

# Test 4: Get-CodeChurnMetrics Function
Test-Function -FunctionName "Get-CodeChurnMetrics" -Description "Test code churn metrics calculation" -TestCode {
    try {
        $churnMetrics = Get-CodeChurnMetrics -Since "1.month.ago" -FilePattern "*.ps1" -ErrorAction Stop
        
        if (-not $churnMetrics -or $churnMetrics.Count -eq 0) {
            Write-Warning "No churn metrics found"
            $testResults.Summary.Warnings++
            return @{ ChurnCount = 0; Status = "NoChurn" }
        }
        
        # Validate churn metrics structure
        $sampleMetric = $churnMetrics[0]
        $requiredProperties = @('FilePath', 'ChurnScore', 'ChangeCount')
        
        foreach ($prop in $requiredProperties) {
            if (-not $sampleMetric.PSObject.Properties[$prop]) {
                throw "Missing property: $prop"
            }
        }
        
        return @{
            ChurnCount = $churnMetrics.Count
            TopFile = $sampleMetric.FilePath
            TopScore = [math]::Round($sampleMetric.ChurnScore, 2)
            TotalChanges = ($churnMetrics | Measure-Object ChangeCount -Sum).Sum
        }
    }
    catch {
        throw "Code churn metrics calculation failed: $($_.Exception.Message)"
    }
}

# Test 5: Integration Test - Full Report Generation
Test-Function -FunctionName "New-EvolutionReport" -Description "Test comprehensive evolution report generation" -TestCode {
    try {
        $report = New-EvolutionReport -Since "1.month.ago" -Format "JSON" -ErrorAction Stop
        
        if (-not $report) {
            throw "Report generation returned null"
        }
        
        # Validate report structure
        $requiredSections = @('Metadata', 'Summary', 'ChurnAnalysis')
        
        foreach ($section in $requiredSections) {
            if (-not $report.PSObject.Properties[$section]) {
                throw "Missing report section: $section"
            }
        }
        
        return @{
            ReportGenerated = $true
            Sections = $report.PSObject.Properties.Name
            TotalCommits = $report.Summary.TotalCommits
            FilesAnalyzed = $report.Summary.UniqueFiles
            GeneratedAt = $report.Metadata.GeneratedAt
        }
    }
    catch {
        throw "Evolution report generation failed: $($_.Exception.Message)"
    }
}

# Test Summary
Write-Host "`n=== Test Summary ===" -ForegroundColor Cyan
Write-Host "Total Tests: $($testResults.Summary.Total)" -ForegroundColor White
Write-Host "Passed: $($testResults.Summary.Passed)" -ForegroundColor Green
Write-Host "Failed: $($testResults.Summary.Failed)" -ForegroundColor Red
Write-Host "Warnings: $($testResults.Summary.Warnings)" -ForegroundColor Yellow

$successRate = if ($testResults.Summary.Total -gt 0) { 
    [math]::Round(($testResults.Summary.Passed / $testResults.Summary.Total) * 100, 1) 
} else { 0 }

Write-Host "Success Rate: $successRate%" -ForegroundColor $(if ($successRate -ge 80) { "Green" } elseif ($successRate -ge 60) { "Yellow" } else { "Red" })

# Save results if requested
if ($SaveReport) {
    $testResults | ConvertTo-Json -Depth 10 | Out-File -FilePath $OutputPath -Encoding UTF8
    Write-Host "`nTest results saved to: $OutputPath" -ForegroundColor Green
}

$testResults.Summary.SuccessRate = $successRate

# Return results for integration with other systems
return $testResults

Write-Host "`n=== Week 4 Day 1: Code Evolution Analysis Implementation Complete ===" -ForegroundColor Green