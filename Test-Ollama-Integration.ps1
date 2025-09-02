# Test-Ollama-Integration.ps1
# Week 1 Day 3 Hour 1-2: Ollama Local AI Integration Testing
# Comprehensive validation of Ollama service setup and PowerShell module integration

#region Test Framework Setup

$ErrorActionPreference = "Stop"

# Test results tracking
$script:TestResults = @{
    StartTime = Get-Date
    TestSuite = "Ollama Local AI Integration Testing (Week 1 Day 3 Hour 1-2)"
    Tests = @()
    Summary = @{}
    EndTime = $null
}

function Add-TestResult {
    param(
        [string]$TestName,
        [string]$Category,
        [bool]$Passed,
        [string]$Details,
        [hashtable]$Data = @{},
        [double]$Duration = $null
    )
    
    $testResult = @{
        TestName = $TestName
        Category = $Category
        Passed = $Passed
        Details = $Details
        Data = $Data
        Duration = $Duration
        Timestamp = Get-Date
    }
    
    $script:TestResults.Tests += $testResult
    
    $status = if ($Passed) { "[PASS]" } else { "[FAIL]" }
    $color = if ($Passed) { "Green" } else { "Red" }
    
    Write-Host "  $status $TestName - $Details" -ForegroundColor $color
}

#endregion

#region Test Execution

Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "Ollama Local AI Integration Test Suite" -ForegroundColor White
Write-Host "Week 1 Day 3 Hour 1-2: Ollama Service Setup and PowerShell Module Integration" -ForegroundColor White
Write-Host "Target: AI-Enhanced Documentation Generation with Local Models" -ForegroundColor White
Write-Host "============================================================" -ForegroundColor Cyan

#region Infrastructure Testing

Write-Host "`n[TEST CATEGORY] Infrastructure..." -ForegroundColor Yellow

try {
    Write-Host "Loading Unity-Claude-Ollama module..." -ForegroundColor White
    Import-Module ".\Unity-Claude-Ollama.psm1" -Force
    
    $moduleCommands = Get-Command -Module "Unity-Claude-Ollama"
    $commandCount = ($moduleCommands | Measure-Object).Count
    
    Add-TestResult -TestName "Module Loading" -Category "Infrastructure" -Passed ($commandCount -eq 13) -Details "Functions loaded: $commandCount/13" -Data @{
        LoadedCommands = $moduleCommands.Name
        ExpectedCount = 13
        ActualCount = $commandCount
    }
}
catch {
    Add-TestResult -TestName "Module Loading" -Category "Infrastructure" -Passed $false -Details "Exception: $($_.Exception.Message)"
}

try {
    Write-Host "Testing Ollama service connectivity..." -ForegroundColor White
    $connectivity = Test-OllamaConnectivity
    
    Add-TestResult -TestName "Ollama Service Connectivity" -Category "Infrastructure" -Passed $connectivity.IsConnected -Details "Models available: $(($connectivity.Models | Measure-Object).Count)" -Data @{
        IsConnected = $connectivity.IsConnected
        ModelsAvailable = ($connectivity.Models | Measure-Object).Count
        Endpoint = $connectivity.Endpoint
        Models = $connectivity.Models
    }
}
catch {
    Add-TestResult -TestName "Ollama Service Connectivity" -Category "Infrastructure" -Passed $false -Details "Exception: $($_.Exception.Message)"
}

#endregion

#region Model Management Testing

Write-Host "`n[TEST CATEGORY] Model Management..." -ForegroundColor Yellow

try {
    Write-Host "Testing model information retrieval..." -ForegroundColor White
    $modelInfo = Get-OllamaModelInfo
    
    $hasCodeLlama = $false
    if ($modelInfo) {
        $hasCodeLlama = $modelInfo | Where-Object { $_.name -match "codellama" } | Measure-Object | ForEach-Object { $_.Count -gt 0 }
    }
    
    Add-TestResult -TestName "Model Information Retrieval" -Category "ModelManagement" -Passed ($modelInfo -ne $null) -Details "CodeLlama available: $hasCodeLlama" -Data @{
        ModelsFound = ($modelInfo | Measure-Object).Count
        HasCodeLlama = $hasCodeLlama
        ModelDetails = $modelInfo
    }
}
catch {
    Add-TestResult -TestName "Model Information Retrieval" -Category "ModelManagement" -Passed $false -Details "Exception: $($_.Exception.Message)"
}

try {
    Write-Host "Testing configuration management..." -ForegroundColor White
    $configResult = Set-OllamaConfiguration -ContextWindow 32768 -RequestTimeout 300 -MaxRetries 5
    
    $configValid = ($configResult.ContextWindow -eq 32768) -and ($configResult.RequestTimeout -eq 300)
    
    Add-TestResult -TestName "Configuration Management" -Category "ModelManagement" -Passed $configValid -Details "Context window: $($configResult.ContextWindow) tokens, Timeout: $($configResult.RequestTimeout)s" -Data @{
        ContextWindow = $configResult.ContextWindow
        RequestTimeout = $configResult.RequestTimeout
        MaxRetries = $configResult.MaxRetries
        DefaultModel = $configResult.DefaultModel
    }
}
catch {
    Add-TestResult -TestName "Configuration Management" -Category "ModelManagement" -Passed $false -Details "Exception: $($_.Exception.Message)"
}

#endregion

#region AI Documentation Generation Testing

Write-Host "`n[TEST CATEGORY] AI Documentation Generation..." -ForegroundColor Yellow

# Sample PowerShell code for documentation testing
$sampleCode = @'
function Get-SystemInfo {
    param(
        [string]$ComputerName = $env:COMPUTERNAME,
        [switch]$IncludeProcesses
    )
    
    $systemInfo = @{
        ComputerName = $ComputerName
        OS = (Get-WmiObject Win32_OperatingSystem).Caption
        Memory = [math]::Round((Get-WmiObject Win32_ComputerSystem).TotalPhysicalMemory / 1GB, 2)
        Uptime = (Get-Date) - (Get-WmiObject Win32_OperatingSystem).ConvertToDateTime((Get-WmiObject Win32_OperatingSystem).LastBootUpTime)
    }
    
    if ($IncludeProcesses) {
        $systemInfo.ProcessCount = (Get-Process | Measure-Object).Count
    }
    
    return $systemInfo
}
'@

try {
    Write-Host "Testing basic documentation generation..." -ForegroundColor White
    $startTime = Get-Date
    
    $docResult = Invoke-OllamaDocumentation -CodeContent $sampleCode -DocumentationType "Synopsis"
    $duration = (Get-Date) - $startTime
    
    $docGenerated = ($docResult -ne $null) -and ($docResult.Documentation.Length -gt 0)
    $responseTime = $duration.TotalSeconds
    $meetsTimeTarget = $responseTime -lt 60
    
    Add-TestResult -TestName "Basic Documentation Generation" -Category "DocumentationGeneration" -Passed $docGenerated -Details "Response time: $([math]::Round($responseTime, 2))s (target: <60s)" -Data @{
        DocumentationGenerated = $docGenerated
        ResponseTime = $responseTime
        MeetsTimeTarget = $meetsTimeTarget
        DocumentationLength = if ($docResult) { $docResult.Documentation.Length } else { 0 }
        Model = if ($docResult) { $docResult.Model } else { "N/A" }
    } -Duration $responseTime
}
catch {
    Add-TestResult -TestName "Basic Documentation Generation" -Category "DocumentationGeneration" -Passed $false -Details "Exception: $($_.Exception.Message)"
}

try {
    Write-Host "Testing code analysis capabilities..." -ForegroundColor White
    $startTime = Get-Date
    
    $analysisResult = Invoke-OllamaCodeAnalysis -CodeContent $sampleCode -AnalysisType "BestPractices"
    $duration = (Get-Date) - $startTime
    
    $analysisGenerated = ($analysisResult -ne $null) -and ($analysisResult.Analysis.Length -gt 0)
    $responseTime = $duration.TotalSeconds
    
    Add-TestResult -TestName "Code Analysis Generation" -Category "DocumentationGeneration" -Passed $analysisGenerated -Details "Analysis response time: $([math]::Round($responseTime, 2))s" -Data @{
        AnalysisGenerated = $analysisGenerated
        ResponseTime = $responseTime
        AnalysisLength = if ($analysisResult) { $analysisResult.Analysis.Length } else { 0 }
        AnalysisType = if ($analysisResult) { $analysisResult.AnalysisType } else { "N/A" }
    } -Duration $responseTime
}
catch {
    Add-TestResult -TestName "Code Analysis Generation" -Category "DocumentationGeneration" -Passed $false -Details "Exception: $($_.Exception.Message)"
}

try {
    Write-Host "Testing technical explanation generation..." -ForegroundColor White
    $startTime = Get-Date
    
    $explanationResult = Invoke-OllamaExplanation -CodeContent $sampleCode -ExplanationLevel "Intermediate"
    $duration = (Get-Date) - $startTime
    
    $explanationGenerated = ($explanationResult -ne $null) -and ($explanationResult.Explanation.Length -gt 0)
    $responseTime = $duration.TotalSeconds
    
    Add-TestResult -TestName "Technical Explanation Generation" -Category "DocumentationGeneration" -Passed $explanationGenerated -Details "Explanation response time: $([math]::Round($responseTime, 2))s" -Data @{
        ExplanationGenerated = $explanationGenerated
        ResponseTime = $responseTime
        ExplanationLength = if ($explanationResult) { $explanationResult.Explanation.Length } else { 0 }
        ExplanationLevel = if ($explanationResult) { $explanationResult.ExplanationLevel } else { "N/A" }
    } -Duration $responseTime
}
catch {
    Add-TestResult -TestName "Technical Explanation Generation" -Category "DocumentationGeneration" -Passed $false -Details "Exception: $($_.Exception.Message)"
}

#endregion

#region Performance and Integration Testing

Write-Host "`n[TEST CATEGORY] Performance and Integration..." -ForegroundColor Yellow

try {
    Write-Host "Testing performance metrics collection..." -ForegroundColor White
    $metricsResult = Get-OllamaPerformanceMetrics
    
    $metricsWorking = ($metricsResult -ne $null) -and ($metricsResult.RequestCount -ge 0)
    
    Add-TestResult -TestName "Performance Metrics Collection" -Category "Performance" -Passed $metricsWorking -Details "Requests tracked: $($metricsResult.RequestCount)" -Data @{
        RequestCount = $metricsResult.RequestCount
        SuccessCount = $metricsResult.SuccessCount
        ErrorCount = $metricsResult.ErrorCount
        AverageResponseTime = $metricsResult.AverageResponseTime
    }
}
catch {
    Add-TestResult -TestName "Performance Metrics Collection" -Category "Performance" -Passed $false -Details "Exception: $($_.Exception.Message)"
}

try {
    Write-Host "Testing configuration export..." -ForegroundColor White
    $exportResult = Export-OllamaConfiguration -Path ".\TestResults\ollama-test-config.json"
    
    $exportWorking = $exportResult.Success -and (Test-Path $exportResult.Path)
    
    Add-TestResult -TestName "Configuration Export" -Category "Integration" -Passed $exportWorking -Details "Config exported: $($exportResult.Success)" -Data @{
        ExportSuccess = $exportResult.Success
        ExportPath = $exportResult.Path
        FileExists = if ($exportResult.Path) { Test-Path $exportResult.Path } else { $false }
    }
}
catch {
    Add-TestResult -TestName "Configuration Export" -Category "Integration" -Passed $false -Details "Exception: $($_.Exception.Message)"
}

#endregion

#region Week 1 Day 3 Hour 1-2 Success Criteria Validation

Write-Host "`n[TEST CATEGORY] Week 1 Day 3 Hour 1-2 Success Criteria..." -ForegroundColor Yellow

try {
    Write-Host "Validating Ollama service operational status..." -ForegroundColor White
    $connectivity = Test-OllamaConnectivity -Silent
    $serviceOperational = $connectivity.IsConnected -and (($connectivity.Models | Measure-Object).Count -gt 0)
    
    Add-TestResult -TestName "Ollama Service Operational" -Category "SuccessCriteria" -Passed $serviceOperational -Details "Service responsive with models available" -Data @{
        ServiceRunning = $connectivity.IsConnected
        ModelsAvailable = ($connectivity.Models | Measure-Object).Count
        CodeLlamaDetected = $connectivity.Models | Where-Object { $_.name -match "codellama" } | Measure-Object | ForEach-Object { $_.Count -gt 0 }
    }
}
catch {
    Add-TestResult -TestName "Ollama Service Operational" -Category "SuccessCriteria" -Passed $false -Details "Exception: $($_.Exception.Message)"
}

try {
    Write-Host "Validating Unity-Claude-Ollama module functionality..." -ForegroundColor White
    $moduleCommands = Get-Command -Module "Unity-Claude-Ollama" -ErrorAction SilentlyContinue
    $functionsOperational = ($moduleCommands | Measure-Object).Count -eq 13
    
    Add-TestResult -TestName "Module Functions Operational" -Category "SuccessCriteria" -Passed $functionsOperational -Details "Functions available: $(($moduleCommands | Measure-Object).Count)/13" -Data @{
        ExpectedFunctions = 13
        AvailableFunctions = ($moduleCommands | Measure-Object).Count
        FunctionNames = $moduleCommands.Name
        AllFunctionsWorking = $functionsOperational
    }
}
catch {
    Add-TestResult -TestName "Module Functions Operational" -Category "SuccessCriteria" -Passed $false -Details "Exception: $($_.Exception.Message)"
}

try {
    Write-Host "Validating AI documentation generation capability..." -ForegroundColor White
    # Use a simple test case for validation
    $simpleCode = "Get-Date | Format-Table"
    $docTest = Invoke-OllamaDocumentation -CodeContent $simpleCode -DocumentationType "Synopsis"
    
    $aiDocWorking = ($docTest -ne $null) -and ($docTest.Documentation.Length -gt 50)
    
    Add-TestResult -TestName "AI Documentation Generation Working" -Category "SuccessCriteria" -Passed $aiDocWorking -Details "AI documentation: $($aiDocWorking)" -Data @{
        DocumentationGenerated = $aiDocWorking
        DocumentationLength = if ($docTest) { $docTest.Documentation.Length } else { 0 }
        Model = if ($docTest) { $docTest.Model } else { "N/A" }
        GenerationWorking = $aiDocWorking
    }
}
catch {
    Add-TestResult -TestName "AI Documentation Generation Working" -Category "SuccessCriteria" -Passed $false -Details "Exception: $($_.Exception.Message)"
}

#endregion

#region Results Summary and Analysis

$script:TestResults.EndTime = Get-Date
$totalTests = ($script:TestResults.Tests | Measure-Object).Count
$passedTests = ($script:TestResults.Tests | Where-Object { $_.Passed } | Measure-Object).Count
$failedTests = $totalTests - $passedTests
$passRate = if ($totalTests -gt 0) { [math]::Round(($passedTests / $totalTests) * 100, 1) } else { 0 }

# Category analysis with comprehensive debugging
Write-Host "[DEBUG] Analyzing test results by category..." -ForegroundColor Gray
Write-Host "[DEBUG] Total test results: $(($script:TestResults.Tests | Measure-Object).Count)" -ForegroundColor Gray

$categoryResults = @{}

# Get unique categories from test results
$uniqueCategories = $script:TestResults.Tests | ForEach-Object { $_.Category } | Sort-Object -Unique

Write-Host "[DEBUG] Unique categories found: $($uniqueCategories -join ', ')" -ForegroundColor Gray

foreach ($categoryName in $uniqueCategories) {
    Write-Host "[DEBUG] Processing category: $categoryName" -ForegroundColor Gray
    
    $categoryTests = $script:TestResults.Tests | Where-Object { $_.Category -eq $categoryName }
    $categoryPassed = ($categoryTests | Where-Object { $_.Passed } | Measure-Object).Count
    $categoryTotal = ($categoryTests | Measure-Object).Count
    $categoryPassRate = if ($categoryTotal -gt 0) { [math]::Round(($categoryPassed / $categoryTotal) * 100, 0) } else { 0 }
    
    Write-Host "[DEBUG] Category $categoryName - Passed: $categoryPassed, Total: $categoryTotal, Rate: $categoryPassRate%" -ForegroundColor Gray
    
    $categoryResults[$categoryName] = @{
        Passed = $categoryPassed
        Total = $categoryTotal
        Failed = $categoryTotal - $categoryPassed
        PassRate = $categoryPassRate
    }
}

Write-Host "`n[RESULTS SUMMARY]" -ForegroundColor Cyan
foreach ($category in $categoryResults.Keys | Sort-Object) {
    $result = $categoryResults[$category]
    Write-Host "  ${category}: $($result.Passed)/$($result.Total) ($($result.PassRate)%)" -ForegroundColor White
}

# Week 1 Day 3 Hour 1-2 Success Assessment
Write-Host "`n[WEEK 1 DAY 3 HOUR 1-2 SUCCESS ASSESSMENT]" -ForegroundColor Cyan

$successCriteria = @{
    OllamaServiceOperational = ($script:TestResults.Tests | Where-Object { $_.TestName -eq "Ollama Service Operational" -and $_.Passed }) -ne $null
    ModuleFunctionsOperational = ($script:TestResults.Tests | Where-Object { $_.TestName -eq "Module Functions Operational" -and $_.Passed }) -ne $null
    AIDocumentationWorking = ($script:TestResults.Tests | Where-Object { $_.TestName -eq "AI Documentation Generation Working" -and $_.Passed }) -ne $null
}

foreach ($criterion in $successCriteria.Keys) {
    $status = if ($successCriteria[$criterion]) { "[ACHIEVED]" } else { "[PENDING]" }
    $color = if ($successCriteria[$criterion]) { "Green" } else { "Red" }
    Write-Host "  $status $criterion" -ForegroundColor $color
}

$overallSuccess = $successCriteria.Values -notcontains $false
$successStatus = if ($overallSuccess) { "[SUCCESS]" } else { "[PARTIAL]" }
$successColor = if ($overallSuccess) { "Green" } else { "Yellow" }

Write-Host "`n$successStatus Week 1 Day 3 Hour 1-2 Success: $(($successCriteria.Values | Where-Object { $_ }).Count)/$(($successCriteria.Keys | Measure-Object).Count) criteria achieved" -ForegroundColor $successColor

$script:TestResults.Summary = @{
    TotalTests = $totalTests
    PassedTests = $passedTests
    FailedTests = $failedTests
    PassRate = "$passRate%"
    Categories = $categoryResults
    Duration = ($script:TestResults.EndTime - $script:TestResults.StartTime).ToString()
    Day3Hour1_2Success = $overallSuccess
    Day3Hour1_2SuccessCriteria = $successCriteria
}

Write-Host "`nOVERALL RESULTS:" -ForegroundColor Cyan
Write-Host "  Total Tests: $totalTests" -ForegroundColor White
Write-Host "  Passed: $passedTests" -ForegroundColor Green
Write-Host "  Failed: $failedTests" -ForegroundColor Red
Write-Host "  Pass Rate: $passRate%" -ForegroundColor White

# Determine completion status
$completionStatus = if ($overallSuccess) { "COMPLETE" } else { "REQUIRES attention" }
$deploymentStatus = if ($overallSuccess) { "READY" } else { "PENDING fixes" }

Write-Host "`n[WEEK 1 DAY 3 HOUR 1-2 COMPLETION STATUS]" -ForegroundColor Cyan
Write-Host "Ollama Integration Foundation: $completionStatus" -ForegroundColor $(if ($overallSuccess) { "Green" } else { "Yellow" })
Write-Host "AI Documentation Pipeline: $deploymentStatus" -ForegroundColor $(if ($overallSuccess) { "Green" } else { "Yellow" })

# Save test results
$resultFile = ".\Ollama-Integration-TestResults-$(Get-Date -Format 'yyyyMMdd-HHmmss').json"
$script:TestResults | ConvertTo-Json -Depth 10 | Out-File -FilePath $resultFile -Encoding UTF8

Write-Host "`nTest results saved to: $resultFile" -ForegroundColor Gray

Write-Host "`n============================================================" -ForegroundColor Cyan
Write-Host "Ollama Local AI Integration Testing Complete" -ForegroundColor White
Write-Host "Pass Rate: $passRate% ($passedTests/$totalTests tests)" -ForegroundColor White
Write-Host "Week 1 Day 3 Hour 1-2 Status: $completionStatus" -ForegroundColor $(if ($overallSuccess) { "Green" } else { "Yellow" })
Write-Host "AI Documentation Pipeline: $deploymentStatus" -ForegroundColor $(if ($overallSuccess) { "Green" } else { "Yellow" })
Write-Host "============================================================" -ForegroundColor Cyan

#endregion

# Return test results object
return $script:TestResults