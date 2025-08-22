# Unity Test Automation Module with Enhanced Security
# Phase 1 Day 4 Implementation - Unity Test Runner Integration
# Date: 2025-08-18
# Security Framework: Constrained Runspace with Safe Command Execution

#region Module Configuration

# Import the safe command execution framework
Import-Module "$PSScriptRoot\..\SafeCommandExecution\SafeCommandExecution.psm1" -ErrorAction Stop

# Unity test result paths
$script:UnityTestResultPath = "$env:TEMP\Unity-TestResults"
$script:UnityEditModeResultFile = "EditMode-Results.xml"
$script:UnityPlayModeResultFile = "PlayMode-Results.xml"

# Test execution state tracking
$script:TestExecutionState = @{
    CurrentTestRun = $null
    LastExecutionTime = $null
    TestHistory = @()
}

#endregion

#region Unity EditMode Test Execution

function Invoke-UnityEditModeTests {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [ValidateScript({
            if (-not (Test-Path $_)) {
                throw "Unity project path does not exist: $_"
            }
            if (-not (Test-Path "$_\Assets")) {
                throw "Not a valid Unity project (Assets folder missing): $_"
            }
            $true
        })]
        [string]$ProjectPath,
        
        [Parameter()]
        [string]$TestCategory = "",
        
        [Parameter()]
        [string]$TestFilter = "",
        
        [Parameter()]
        [string]$TestPlatform = "EditMode",
        
        [Parameter()]
        [switch]$RunSynchronously,
        
        [Parameter()]
        [string]$ResultsDirectory = $script:UnityTestResultPath,
        
        [Parameter()]
        [switch]$GenerateCodeCoverage,
        
        [Parameter()]
        [int]$TimeoutSeconds = 600
    )
    
    begin {
        Write-Host "`n=== Unity EditMode Test Execution ===" -ForegroundColor Cyan
        Write-Host "Project: $ProjectPath"
        Write-Host "Category: $(if ($TestCategory) { $TestCategory } else { 'All' })"
        Write-Host "Filter: $(if ($TestFilter) { $TestFilter } else { 'None' })"
        
        # Initialize results directory
        if (-not (Test-Path $ResultsDirectory)) {
            New-Item -ItemType Directory -Path $ResultsDirectory -Force | Out-Null
            Write-Host "Created results directory: $ResultsDirectory" -ForegroundColor Green
        }
        
        # Initialize test run tracking
        $script:TestExecutionState.CurrentTestRun = @{
            Type = "EditMode"
            StartTime = Get-Date
            ProjectPath = $ProjectPath
            Parameters = @{
                Category = $TestCategory
                Filter = $TestFilter
                Synchronous = $RunSynchronously.IsPresent
            }
        }
    }
    
    process {
        try {
            # Build Unity command arguments
            $unityArgs = @(
                "-projectPath", $ProjectPath,
                "-runTests",
                "-testPlatform", $TestPlatform,
                "-batchmode",
                "-nographics",
                "-logFile", "$ResultsDirectory\EditMode-Log.txt",
                "-testResults", "$ResultsDirectory\$script:UnityEditModeResultFile"
            )
            
            # Add optional parameters
            if ($TestCategory) {
                $unityArgs += @("-testCategory", $TestCategory)
            }
            
            if ($TestFilter) {
                $unityArgs += @("-testFilter", $TestFilter)
            }
            
            if ($RunSynchronously) {
                $unityArgs += "-runSynchronously"
            }
            
            if ($GenerateCodeCoverage) {
                $unityArgs += @(
                    "-enableCodeCoverage",
                    "-coverageResultsPath", "$ResultsDirectory\CodeCoverage",
                    "-coverageOptions", "generateAdditionalMetrics;generateHtmlReport"
                )
            }
            
            # Execute Unity with safe command framework
            Write-Host "`nExecuting Unity EditMode tests with constrained runspace..." -ForegroundColor Yellow
            
            $safeParams = @{
                Command = @{
                    CommandType = 'Unity'
                    Operation = 'Test'
                    Arguments = $unityArgs -join ' '
                }
                TimeoutSeconds = $TimeoutSeconds
                ValidateExecution = $true
            }
            
            $result = Invoke-SafeCommand @safeParams
            
            if ($result.Success) {
                Write-Host "Unity EditMode tests executed successfully" -ForegroundColor Green
                
                # Parse and display results
                if (Test-Path "$ResultsDirectory\$script:UnityEditModeResultFile") {
                    $testResults = Get-UnityTestResults -ResultFile "$ResultsDirectory\$script:UnityEditModeResultFile"
                    
                    # Update execution state
                    $script:TestExecutionState.CurrentTestRun.Results = $testResults
                    $script:TestExecutionState.CurrentTestRun.EndTime = Get-Date
                    $script:TestExecutionState.TestHistory += $script:TestExecutionState.CurrentTestRun
                    
                    return $testResults
                }
            }
            else {
                throw "Unity EditMode test execution failed: $($result.Error)"
            }
        }
        catch {
            Write-Error "EditMode test execution error: $_"
            $script:TestExecutionState.CurrentTestRun.Error = $_.ToString()
            throw
        }
    }
}

#endregion

#region Unity PlayMode Test Execution

function Invoke-UnityPlayModeTests {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [ValidateScript({
            if (-not (Test-Path $_)) {
                throw "Unity project path does not exist: $_"
            }
            if (-not (Test-Path "$_\Assets")) {
                throw "Not a valid Unity project (Assets folder missing): $_"
            }
            $true
        })]
        [string]$ProjectPath,
        
        [Parameter()]
        [ValidateSet("StandaloneWindows64", "StandaloneLinux64", "StandaloneOSX", "Android", "iOS", "WebGL")]
        [string]$BuildTarget = "StandaloneWindows64",
        
        [Parameter()]
        [string]$TestCategory = "",
        
        [Parameter()]
        [string]$TestFilter = "",
        
        [Parameter()]
        [string]$ResultsDirectory = $script:UnityTestResultPath,
        
        [Parameter()]
        [switch]$GenerateCodeCoverage,
        
        [Parameter()]
        [int]$TimeoutSeconds = 900
    )
    
    begin {
        Write-Host "`n=== Unity PlayMode Test Execution ===" -ForegroundColor Cyan
        Write-Host "Project: $ProjectPath"
        Write-Host "Build Target: $BuildTarget"
        Write-Host "Category: $(if ($TestCategory) { $TestCategory } else { 'All' })"
        Write-Host "Filter: $(if ($TestFilter) { $TestFilter } else { 'None' })"
        
        # Initialize results directory
        if (-not (Test-Path $ResultsDirectory)) {
            New-Item -ItemType Directory -Path $ResultsDirectory -Force | Out-Null
            Write-Host "Created results directory: $ResultsDirectory" -ForegroundColor Green
        }
        
        # Initialize test run tracking
        $script:TestExecutionState.CurrentTestRun = @{
            Type = "PlayMode"
            StartTime = Get-Date
            ProjectPath = $ProjectPath
            BuildTarget = $BuildTarget
            Parameters = @{
                Category = $TestCategory
                Filter = $TestFilter
            }
        }
    }
    
    process {
        try {
            # Build Unity command arguments
            $unityArgs = @(
                "-projectPath", $ProjectPath,
                "-runTests",
                "-testPlatform", "PlayMode",
                "-buildTarget", $BuildTarget,
                "-batchmode",
                "-nographics",
                "-logFile", "$ResultsDirectory\PlayMode-Log.txt",
                "-testResults", "$ResultsDirectory\$script:UnityPlayModeResultFile"
            )
            
            # Add optional parameters
            if ($TestCategory) {
                $unityArgs += @("-testCategory", $TestCategory)
            }
            
            if ($TestFilter) {
                $unityArgs += @("-testFilter", $TestFilter)
            }
            
            if ($GenerateCodeCoverage) {
                $unityArgs += @(
                    "-enableCodeCoverage",
                    "-coverageResultsPath", "$ResultsDirectory\CodeCoverage",
                    "-coverageOptions", "generateAdditionalMetrics;generateHtmlReport"
                )
            }
            
            # Execute Unity with safe command framework
            Write-Host "`nExecuting Unity PlayMode tests with constrained runspace..." -ForegroundColor Yellow
            
            $safeParams = @{
                Command = @{
                    CommandType = 'Unity'
                    Operation = 'Test'
                    Arguments = $unityArgs -join ' '
                }
                TimeoutSeconds = $TimeoutSeconds
                ValidateExecution = $true
            }
            
            $result = Invoke-SafeCommand @safeParams
            
            if ($result.Success) {
                Write-Host "Unity PlayMode tests executed successfully" -ForegroundColor Green
                
                # Parse and display results
                if (Test-Path "$ResultsDirectory\$script:UnityPlayModeResultFile") {
                    $testResults = Get-UnityTestResults -ResultFile "$ResultsDirectory\$script:UnityPlayModeResultFile"
                    
                    # Update execution state
                    $script:TestExecutionState.CurrentTestRun.Results = $testResults
                    $script:TestExecutionState.CurrentTestRun.EndTime = Get-Date
                    $script:TestExecutionState.TestHistory += $script:TestExecutionState.CurrentTestRun
                    
                    return $testResults
                }
            }
            else {
                throw "Unity PlayMode test execution failed: $($result.Error)"
            }
        }
        catch {
            Write-Error "PlayMode test execution error: $_"
            $script:TestExecutionState.CurrentTestRun.Error = $_.ToString()
            throw
        }
    }
}

#endregion

#region Unity Test Result Parsing

function Get-UnityTestResults {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [ValidateScript({
            if (-not (Test-Path $_)) {
                throw "Test result file not found: $_"
            }
            $true
        })]
        [string]$ResultFile,
        
        [Parameter()]
        [switch]$Detailed
    )
    
    try {
        Write-Host "`nParsing Unity test results from: $ResultFile" -ForegroundColor Yellow
        
        # Load XML content
        [xml]$xmlContent = Get-Content -Path $ResultFile -Raw
        
        # Parse NUnit 3 format
        $testRun = $xmlContent.'test-run'
        
        if (-not $testRun) {
            throw "Invalid Unity test result format (missing test-run element)"
        }
        
        # Extract summary information
        $summary = @{
            Total = [int]$testRun.total
            Passed = [int]$testRun.passed
            Failed = [int]$testRun.failed
            Inconclusive = [int]$testRun.inconclusive
            Skipped = [int]$testRun.skipped
            Duration = [double]$testRun.duration
            StartTime = $testRun.'start-time'
            EndTime = $testRun.'end-time'
            Result = $testRun.result
        }
        
        Write-Host "`n=== Test Summary ===" -ForegroundColor Cyan
        Write-Host "Total Tests: $($summary.Total)"
        Write-Host "Passed: $($summary.Passed)" -ForegroundColor Green
        Write-Host "Failed: $($summary.Failed)" -ForegroundColor $(if ($summary.Failed -gt 0) { 'Red' } else { 'Gray' })
        Write-Host "Skipped: $($summary.Skipped)" -ForegroundColor Yellow
        Write-Host "Duration: $($summary.Duration) seconds"
        Write-Host "Result: $($summary.Result)" -ForegroundColor $(if ($summary.Result -eq 'Passed') { 'Green' } else { 'Red' })
        
        # Parse detailed test results if requested
        $testCases = @()
        
        if ($Detailed) {
            Write-Host "`n=== Detailed Test Results ===" -ForegroundColor Cyan
            
            # Recursively find all test cases
            $allTestCases = $xmlContent.SelectNodes("//test-case")
            
            foreach ($testCase in $allTestCases) {
                $caseInfo = @{
                    Id = $testCase.id
                    Name = $testCase.name
                    FullName = $testCase.fullname
                    MethodName = $testCase.methodname
                    ClassName = $testCase.classname
                    Result = $testCase.result
                    Duration = [double]$testCase.duration
                    StartTime = $testCase.'start-time'
                    EndTime = $testCase.'end-time'
                    Asserts = [int]$testCase.asserts
                }
                
                # Check for failure information
                if ($testCase.failure) {
                    $caseInfo.FailureMessage = $testCase.failure.message.'#cdata-section'
                    $caseInfo.StackTrace = $testCase.failure.'stack-trace'.'#cdata-section'
                    
                    Write-Host "`nFAILED: $($caseInfo.FullName)" -ForegroundColor Red
                    Write-Host "  Message: $($caseInfo.FailureMessage)" -ForegroundColor Red
                    if ($caseInfo.StackTrace) {
                        Write-Host "  Stack Trace:`n$($caseInfo.StackTrace)" -ForegroundColor DarkRed
                    }
                }
                elseif ($caseInfo.Result -eq 'Passed') {
                    Write-Host "PASSED: $($caseInfo.Name) ($($caseInfo.Duration)s)" -ForegroundColor Green
                }
                elseif ($caseInfo.Result -eq 'Skipped') {
                    Write-Host "SKIPPED: $($caseInfo.Name)" -ForegroundColor Yellow
                }
                
                $testCases += $caseInfo
            }
        }
        
        # Return comprehensive results
        return @{
            Summary = $summary
            TestCases = $testCases
            RawXml = $xmlContent
            FilePath = $ResultFile
        }
    }
    catch {
        Write-Error "Failed to parse Unity test results: $_"
        throw
    }
}

#endregion

#region Test Filtering and Category Selection

function Get-UnityTestCategories {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [ValidateScript({
            if (-not (Test-Path $_)) {
                throw "Unity project path does not exist: $_"
            }
            $true
        })]
        [string]$ProjectPath
    )
    
    try {
        Write-Host "`nDiscovering test categories in project: $ProjectPath" -ForegroundColor Yellow
        
        # Search for test files with Category attributes
        $testFiles = Get-ChildItem -Path "$ProjectPath\Assets" -Filter "*.cs" -Recurse | 
                     Select-String -Pattern "\[Category\([`"']([^`"']+)[`"']\)\]" -AllMatches
        
        $categories = @()
        
        foreach ($match in $testFiles) {
            foreach ($categoryMatch in $match.Matches) {
                if ($categoryMatch.Groups.Count -ge 2) {
                    $categoryName = $categoryMatch.Groups[1].Value
                    if ($categoryName -notin $categories) {
                        $categories += $categoryName
                    }
                }
            }
        }
        
        if ($categories.Count -gt 0) {
            Write-Host "`nFound $($categories.Count) test categories:" -ForegroundColor Green
            $categories | ForEach-Object {
                Write-Host "  - $_" -ForegroundColor Cyan
            }
        }
        else {
            Write-Host "No test categories found in project" -ForegroundColor Yellow
        }
        
        return $categories
    }
    catch {
        Write-Error "Failed to discover test categories: $_"
        throw
    }
}

function New-UnityTestFilter {
    [CmdletBinding()]
    param (
        [Parameter()]
        [string[]]$IncludeCategories = @(),
        
        [Parameter()]
        [string[]]$ExcludeCategories = @(),
        
        [Parameter()]
        [string[]]$IncludeTests = @(),
        
        [Parameter()]
        [string[]]$ExcludeTests = @(),
        
        [Parameter()]
        [string]$NamePattern = ""
    )
    
    $filters = @{
        Category = ""
        Filter = ""
    }
    
    # Build category filter
    if ($IncludeCategories.Count -gt 0 -or $ExcludeCategories.Count -gt 0) {
        $categoryParts = @()
        
        foreach ($cat in $IncludeCategories) {
            $categoryParts += $cat
        }
        
        foreach ($cat in $ExcludeCategories) {
            $categoryParts += "!$cat"
        }
        
        $filters.Category = $categoryParts -join ";"
    }
    
    # Build test name filter
    if ($IncludeTests.Count -gt 0 -or $ExcludeTests.Count -gt 0 -or $NamePattern) {
        $filterParts = @()
        
        if ($NamePattern) {
            $filterParts += $NamePattern
        }
        
        foreach ($test in $IncludeTests) {
            $filterParts += $test
        }
        
        foreach ($test in $ExcludeTests) {
            $filterParts += "!$test"
        }
        
        if ($filterParts.Count -gt 0) {
            $filters.Filter = $filterParts[0]
        }
    }
    
    Write-Host "`nGenerated test filters:" -ForegroundColor Cyan
    if ($filters.Category) {
        Write-Host "  Category: $($filters.Category)" -ForegroundColor Yellow
    }
    if ($filters.Filter) {
        Write-Host "  Filter: $($filters.Filter)" -ForegroundColor Yellow
    }
    
    return $filters
}

#endregion

#region PowerShell Test Integration

function Invoke-PowerShellTests {
    [CmdletBinding()]
    param (
        [Parameter()]
        [string]$TestPath = $PSScriptRoot,
        
        [Parameter()]
        [string[]]$TestNames = @(),
        
        [Parameter()]
        [string[]]$Tags = @(),
        
        [Parameter()]
        [string]$OutputPath = "$script:UnityTestResultPath\PowerShell-Results.xml",
        
        [Parameter()]
        [ValidateSet("NUnitXml", "JUnitXml", "LegacyNUnitXml")]
        [string]$OutputFormat = "NUnitXml",
        
        [Parameter()]
        [switch]$PassThru,
        
        [Parameter()]
        [switch]$CodeCoverage
    )
    
    begin {
        Write-Host "`n=== PowerShell Test Execution ===" -ForegroundColor Cyan
        Write-Host "Test Path: $TestPath"
        
        # Check if Pester is available
        $pester = Get-Module -Name Pester -ListAvailable | Sort-Object Version -Descending | Select-Object -First 1
        
        if (-not $pester) {
            Write-Warning "Pester module not found. Installing Pester..."
            Install-Module -Name Pester -Force -SkipPublisherCheck
            Import-Module Pester
        }
        elseif ($pester.Version.Major -lt 5) {
            Write-Warning "Pester version $($pester.Version) detected. Version 5+ recommended."
        }
        else {
            Import-Module Pester
            Write-Host "Using Pester version $($pester.Version)" -ForegroundColor Green
        }
    }
    
    process {
        try {
            # Build Pester configuration
            $config = New-PesterConfiguration
            
            # Set test path
            $config.Run.Path = $TestPath
            $config.Run.PassThru = $PassThru
            
            # Set test filters
            if ($TestNames.Count -gt 0) {
                $config.Filter.FullName = $TestNames
            }
            
            if ($Tags.Count -gt 0) {
                $config.Filter.Tag = $Tags
            }
            
            # Configure output
            $config.TestResult.Enabled = $true
            $config.TestResult.OutputPath = $OutputPath
            $config.TestResult.OutputFormat = $OutputFormat
            
            # Configure code coverage if requested
            if ($CodeCoverage) {
                $config.CodeCoverage.Enabled = $true
                $config.CodeCoverage.Path = @("$TestPath\*.ps1", "$TestPath\*.psm1")
                $config.CodeCoverage.OutputPath = "$script:UnityTestResultPath\CodeCoverage.xml"
                $config.CodeCoverage.OutputFormat = "JaCoCo"
            }
            
            # Execute tests with safe command framework
            Write-Host "`nExecuting PowerShell tests..." -ForegroundColor Yellow
            
            $safeParams = @{
                Command = @{
                    CommandType = 'PowerShell'
                    Operation = 'Test'
                    Arguments = @{
                        Configuration = $config
                    }
                }
                ValidateExecution = $true
            }
            
            $result = Invoke-SafeCommand @safeParams
            
            if ($result.Success) {
                $testResults = $result.Output
                
                Write-Host "`n=== PowerShell Test Summary ===" -ForegroundColor Cyan
                Write-Host "Total Tests: $($testResults.TotalCount)"
                Write-Host "Passed: $($testResults.PassedCount)" -ForegroundColor Green
                Write-Host "Failed: $($testResults.FailedCount)" -ForegroundColor $(if ($testResults.FailedCount -gt 0) { 'Red' } else { 'Gray' })
                Write-Host "Skipped: $($testResults.SkippedCount)" -ForegroundColor Yellow
                Write-Host "Duration: $($testResults.Duration.TotalSeconds) seconds"
                
                # Display failed tests
                if ($testResults.Failed.Count -gt 0) {
                    Write-Host "`n=== Failed Tests ===" -ForegroundColor Red
                    foreach ($failed in $testResults.Failed) {
                        Write-Host "  - $($failed.ExpandedPath): $($failed.ErrorRecord.Exception.Message)" -ForegroundColor Red
                    }
                }
                
                return $testResults
            }
            else {
                throw "PowerShell test execution failed: $($result.Error)"
            }
        }
        catch {
            Write-Error "PowerShell test execution error: $_"
            throw
        }
    }
}

function Find-CustomTestScripts {
    [CmdletBinding()]
    param (
        [Parameter()]
        [string]$SearchPath = $PSScriptRoot,
        
        [Parameter()]
        [string]$Pattern = "Test-*.ps1"
    )
    
    try {
        Write-Host "`nSearching for custom test scripts in: $SearchPath" -ForegroundColor Yellow
        
        $testScripts = Get-ChildItem -Path $SearchPath -Filter $Pattern -Recurse -File
        
        if ($testScripts.Count -gt 0) {
            Write-Host "Found $($testScripts.Count) custom test scripts:" -ForegroundColor Green
            
            $scriptInfo = @()
            
            foreach ($script in $testScripts) {
                $info = @{
                    Name = $script.Name
                    FullPath = $script.FullName
                    Directory = $script.DirectoryName
                    LastModified = $script.LastWriteTime
                }
                
                # Try to extract script description
                $content = Get-Content -Path $script.FullName -TotalCount 20
                $description = $content | Where-Object { $_ -match "^\s*#\s*Description:\s*(.+)" } | 
                               ForEach-Object { $Matches[1] } | Select-Object -First 1
                
                if ($description) {
                    $info.Description = $description
                }
                
                Write-Host "  - $($info.Name)$(if ($info.Description) { ": $($info.Description)" })" -ForegroundColor Cyan
                
                $scriptInfo += $info
            }
            
            return $scriptInfo
        }
        else {
            Write-Host "No custom test scripts found" -ForegroundColor Yellow
            return @()
        }
    }
    catch {
        Write-Error "Failed to find custom test scripts: $_"
        throw
    }
}

#endregion

#region Test Result Aggregation and Analysis

function Get-TestResultAggregation {
    [CmdletBinding()]
    param (
        [Parameter()]
        [string]$ResultsDirectory = $script:UnityTestResultPath,
        
        [Parameter()]
        [switch]$IncludeHistory
    )
    
    try {
        Write-Host "`n=== Test Result Aggregation ===" -ForegroundColor Cyan
        
        $aggregation = @{
            Timestamp = Get-Date
            Results = @{
                Unity = @{
                    EditMode = $null
                    PlayMode = $null
                }
                PowerShell = $null
            }
            Summary = @{
                TotalTests = 0
                TotalPassed = 0
                TotalFailed = 0
                TotalSkipped = 0
                TotalDuration = 0
                OverallResult = "Unknown"
            }
        }
        
        # Parse Unity EditMode results
        $editModeFile = Join-Path $ResultsDirectory $script:UnityEditModeResultFile
        if (Test-Path $editModeFile) {
            $editModeResults = Get-UnityTestResults -ResultFile $editModeFile
            $aggregation.Results.Unity.EditMode = $editModeResults
            
            $aggregation.Summary.TotalTests += $editModeResults.Summary.Total
            $aggregation.Summary.TotalPassed += $editModeResults.Summary.Passed
            $aggregation.Summary.TotalFailed += $editModeResults.Summary.Failed
            $aggregation.Summary.TotalSkipped += $editModeResults.Summary.Skipped
            $aggregation.Summary.TotalDuration += $editModeResults.Summary.Duration
        }
        
        # Parse Unity PlayMode results
        $playModeFile = Join-Path $ResultsDirectory $script:UnityPlayModeResultFile
        if (Test-Path $playModeFile) {
            $playModeResults = Get-UnityTestResults -ResultFile $playModeFile
            $aggregation.Results.Unity.PlayMode = $playModeResults
            
            $aggregation.Summary.TotalTests += $playModeResults.Summary.Total
            $aggregation.Summary.TotalPassed += $playModeResults.Summary.Passed
            $aggregation.Summary.TotalFailed += $playModeResults.Summary.Failed
            $aggregation.Summary.TotalSkipped += $playModeResults.Summary.Skipped
            $aggregation.Summary.TotalDuration += $playModeResults.Summary.Duration
        }
        
        # Parse PowerShell results
        $psResultFile = Join-Path $ResultsDirectory "PowerShell-Results.xml"
        if (Test-Path $psResultFile) {
            [xml]$psXml = Get-Content -Path $psResultFile -Raw
            
            # Handle different XML formats
            $testRun = $psXml.'test-run' -or $psXml.'test-results' -or $psXml.testsuites
            
            if ($testRun) {
                $psResults = @{
                    Total = [int]($testRun.total -or $testRun.tests -or 0)
                    Passed = [int]($testRun.passed -or ($testRun.tests - $testRun.failures - $testRun.errors) -or 0)
                    Failed = [int]($testRun.failed -or ($testRun.failures + $testRun.errors) -or 0)
                    Skipped = [int]($testRun.skipped -or $testRun.disabled -or 0)
                    Duration = [double]($testRun.duration -or $testRun.time -or 0)
                }
                
                $aggregation.Results.PowerShell = $psResults
                
                $aggregation.Summary.TotalTests += $psResults.Total
                $aggregation.Summary.TotalPassed += $psResults.Passed
                $aggregation.Summary.TotalFailed += $psResults.Failed
                $aggregation.Summary.TotalSkipped += $psResults.Skipped
                $aggregation.Summary.TotalDuration += $psResults.Duration
            }
        }
        
        # Determine overall result
        if ($aggregation.Summary.TotalFailed -gt 0) {
            $aggregation.Summary.OverallResult = "Failed"
        }
        elseif ($aggregation.Summary.TotalTests -eq 0) {
            $aggregation.Summary.OverallResult = "No Tests"
        }
        elseif ($aggregation.Summary.TotalPassed -eq $aggregation.Summary.TotalTests) {
            $aggregation.Summary.OverallResult = "Passed"
        }
        else {
            $aggregation.Summary.OverallResult = "Partial"
        }
        
        # Include history if requested
        if ($IncludeHistory) {
            $aggregation.History = $script:TestExecutionState.TestHistory
        }
        
        # Display aggregated summary
        Write-Host "`n=== Aggregated Test Summary ===" -ForegroundColor Cyan
        Write-Host "Total Tests: $($aggregation.Summary.TotalTests)"
        Write-Host "Total Passed: $($aggregation.Summary.TotalPassed)" -ForegroundColor Green
        Write-Host "Total Failed: $($aggregation.Summary.TotalFailed)" -ForegroundColor $(if ($aggregation.Summary.TotalFailed -gt 0) { 'Red' } else { 'Gray' })
        Write-Host "Total Skipped: $($aggregation.Summary.TotalSkipped)" -ForegroundColor Yellow
        Write-Host "Total Duration: $([Math]::Round($aggregation.Summary.TotalDuration, 2)) seconds"
        Write-Host "Overall Result: $($aggregation.Summary.OverallResult)" -ForegroundColor $(
            switch ($aggregation.Summary.OverallResult) {
                "Passed" { 'Green' }
                "Failed" { 'Red' }
                "Partial" { 'Yellow' }
                default { 'Gray' }
            }
        )
        
        return $aggregation
    }
    catch {
        Write-Error "Failed to aggregate test results: $_"
        throw
    }
}

function Export-TestReport {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [hashtable]$AggregatedResults,
        
        [Parameter()]
        [string]$OutputPath = "$script:UnityTestResultPath\TestReport.html",
        
        [Parameter()]
        [ValidateSet("HTML", "JSON", "Markdown")]
        [string]$Format = "HTML"
    )
    
    try {
        Write-Host "`nGenerating test report in $Format format..." -ForegroundColor Yellow
        
        switch ($Format) {
            "HTML" {
                $html = @"
<!DOCTYPE html>
<html>
<head>
    <title>Unity Test Report - $($AggregatedResults.Timestamp.ToString('yyyy-MM-dd HH:mm:ss'))</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 20px; background: #f5f5f5; }
        h1 { color: #333; border-bottom: 2px solid #007acc; padding-bottom: 10px; }
        h2 { color: #007acc; margin-top: 30px; }
        .summary { background: white; padding: 15px; border-radius: 5px; margin: 20px 0; box-shadow: 0 2px 4px rgba(0,0,0,0.1); }
        .passed { color: #28a745; font-weight: bold; }
        .failed { color: #dc3545; font-weight: bold; }
        .skipped { color: #ffc107; font-weight: bold; }
        .metric { display: inline-block; margin: 10px 20px 10px 0; }
        .metric-label { color: #666; font-size: 0.9em; }
        .metric-value { font-size: 1.5em; font-weight: bold; }
        table { width: 100%; border-collapse: collapse; background: white; margin: 20px 0; }
        th { background: #007acc; color: white; padding: 10px; text-align: left; }
        td { padding: 8px; border-bottom: 1px solid #ddd; }
        tr:hover { background: #f9f9f9; }
        .status-passed { background: #d4edda; }
        .status-failed { background: #f8d7da; }
        .status-skipped { background: #fff3cd; }
    </style>
</head>
<body>
    <h1>Unity Test Automation Report</h1>
    <div class="summary">
        <h2>Overall Summary</h2>
        <div class="metric">
            <div class="metric-label">Total Tests</div>
            <div class="metric-value">$($AggregatedResults.Summary.TotalTests)</div>
        </div>
        <div class="metric">
            <div class="metric-label">Passed</div>
            <div class="metric-value passed">$($AggregatedResults.Summary.TotalPassed)</div>
        </div>
        <div class="metric">
            <div class="metric-label">Failed</div>
            <div class="metric-value failed">$($AggregatedResults.Summary.TotalFailed)</div>
        </div>
        <div class="metric">
            <div class="metric-label">Skipped</div>
            <div class="metric-value skipped">$($AggregatedResults.Summary.TotalSkipped)</div>
        </div>
        <div class="metric">
            <div class="metric-label">Duration</div>
            <div class="metric-value">$([Math]::Round($AggregatedResults.Summary.TotalDuration, 2))s</div>
        </div>
        <div class="metric">
            <div class="metric-label">Result</div>
            <div class="metric-value $(if ($AggregatedResults.Summary.OverallResult -eq 'Passed') { 'passed' } elseif ($AggregatedResults.Summary.OverallResult -eq 'Failed') { 'failed' } else { 'skipped' })">$($AggregatedResults.Summary.OverallResult)</div>
        </div>
    </div>
"@
                
                # Add Unity EditMode results
                if ($AggregatedResults.Results.Unity.EditMode) {
                    $editMode = $AggregatedResults.Results.Unity.EditMode.Summary
                    $html += @"
    <h2>Unity EditMode Tests</h2>
    <table>
        <tr>
            <th>Metric</th>
            <th>Value</th>
        </tr>
        <tr>
            <td>Total Tests</td>
            <td>$($editMode.Total)</td>
        </tr>
        <tr class="status-passed">
            <td>Passed</td>
            <td class="passed">$($editMode.Passed)</td>
        </tr>
        <tr class="status-failed">
            <td>Failed</td>
            <td class="failed">$($editMode.Failed)</td>
        </tr>
        <tr class="status-skipped">
            <td>Skipped</td>
            <td class="skipped">$($editMode.Skipped)</td>
        </tr>
        <tr>
            <td>Duration</td>
            <td>$($editMode.Duration) seconds</td>
        </tr>
    </table>
"@
                }
                
                # Add Unity PlayMode results
                if ($AggregatedResults.Results.Unity.PlayMode) {
                    $playMode = $AggregatedResults.Results.Unity.PlayMode.Summary
                    $html += @"
    <h2>Unity PlayMode Tests</h2>
    <table>
        <tr>
            <th>Metric</th>
            <th>Value</th>
        </tr>
        <tr>
            <td>Total Tests</td>
            <td>$($playMode.Total)</td>
        </tr>
        <tr class="status-passed">
            <td>Passed</td>
            <td class="passed">$($playMode.Passed)</td>
        </tr>
        <tr class="status-failed">
            <td>Failed</td>
            <td class="failed">$($playMode.Failed)</td>
        </tr>
        <tr class="status-skipped">
            <td>Skipped</td>
            <td class="skipped">$($playMode.Skipped)</td>
        </tr>
        <tr>
            <td>Duration</td>
            <td>$($playMode.Duration) seconds</td>
        </tr>
    </table>
"@
                }
                
                # Add PowerShell results
                if ($AggregatedResults.Results.PowerShell) {
                    $psResults = $AggregatedResults.Results.PowerShell
                    $html += @"
    <h2>PowerShell Tests</h2>
    <table>
        <tr>
            <th>Metric</th>
            <th>Value</th>
        </tr>
        <tr>
            <td>Total Tests</td>
            <td>$($psResults.Total)</td>
        </tr>
        <tr class="status-passed">
            <td>Passed</td>
            <td class="passed">$($psResults.Passed)</td>
        </tr>
        <tr class="status-failed">
            <td>Failed</td>
            <td class="failed">$($psResults.Failed)</td>
        </tr>
        <tr class="status-skipped">
            <td>Skipped</td>
            <td class="skipped">$($psResults.Skipped)</td>
        </tr>
        <tr>
            <td>Duration</td>
            <td>$($psResults.Duration) seconds</td>
        </tr>
    </table>
"@
                }
                
                $html += @"
    <div style="margin-top: 40px; padding: 10px; background: #f0f0f0; text-align: center; color: #666;">
        Generated on $($AggregatedResults.Timestamp.ToString('yyyy-MM-dd HH:mm:ss')) by Unity Test Automation Framework
    </div>
</body>
</html>
"@
                
                $html | Out-File -FilePath $OutputPath -Encoding UTF8
                Write-Host "HTML report generated: $OutputPath" -ForegroundColor Green
            }
            
            "JSON" {
                $AggregatedResults | ConvertTo-Json -Depth 10 | Out-File -FilePath $OutputPath -Encoding UTF8
                Write-Host "JSON report generated: $OutputPath" -ForegroundColor Green
            }
            
            "Markdown" {
                $markdown = @"
# Unity Test Automation Report

**Generated:** $($AggregatedResults.Timestamp.ToString('yyyy-MM-dd HH:mm:ss'))

## Overall Summary

| Metric | Value |
|--------|-------|
| Total Tests | $($AggregatedResults.Summary.TotalTests) |
| Passed | **$($AggregatedResults.Summary.TotalPassed)** ✅ |
| Failed | **$($AggregatedResults.Summary.TotalFailed)** ❌ |
| Skipped | **$($AggregatedResults.Summary.TotalSkipped)** ⚠️ |
| Duration | $([Math]::Round($AggregatedResults.Summary.TotalDuration, 2)) seconds |
| **Result** | **$($AggregatedResults.Summary.OverallResult)** |

"@
                
                if ($AggregatedResults.Results.Unity.EditMode) {
                    $editMode = $AggregatedResults.Results.Unity.EditMode.Summary
                    $markdown += @"

## Unity EditMode Tests

| Metric | Value |
|--------|-------|
| Total | $($editMode.Total) |
| Passed | $($editMode.Passed) |
| Failed | $($editMode.Failed) |
| Skipped | $($editMode.Skipped) |
| Duration | $($editMode.Duration)s |

"@
                }
                
                if ($AggregatedResults.Results.Unity.PlayMode) {
                    $playMode = $AggregatedResults.Results.Unity.PlayMode.Summary
                    $markdown += @"

## Unity PlayMode Tests

| Metric | Value |
|--------|-------|
| Total | $($playMode.Total) |
| Passed | $($playMode.Passed) |
| Failed | $($playMode.Failed) |
| Skipped | $($playMode.Skipped) |
| Duration | $($playMode.Duration)s |

"@
                }
                
                if ($AggregatedResults.Results.PowerShell) {
                    $psResults = $AggregatedResults.Results.PowerShell
                    $markdown += @"

## PowerShell Tests

| Metric | Value |
|--------|-------|
| Total | $($psResults.Total) |
| Passed | $($psResults.Passed) |
| Failed | $($psResults.Failed) |
| Skipped | $($psResults.Skipped) |
| Duration | $($psResults.Duration)s |

"@
                }
                
                $markdown += @"

---
*Generated by Unity Test Automation Framework*
"@
                
                $markdown | Out-File -FilePath $OutputPath -Encoding UTF8
                Write-Host "Markdown report generated: $OutputPath" -ForegroundColor Green
            }
        }
        
        return $OutputPath
    }
    catch {
        Write-Error "Failed to export test report: $_"
        throw
    }
}

#endregion

#region Module Exports

Export-ModuleMember -Function @(
    # Unity test execution
    'Invoke-UnityEditModeTests',
    'Invoke-UnityPlayModeTests',
    
    # Result parsing
    'Get-UnityTestResults',
    
    # Test filtering
    'Get-UnityTestCategories',
    'New-UnityTestFilter',
    
    # PowerShell testing
    'Invoke-PowerShellTests',
    'Find-CustomTestScripts',
    
    # Result aggregation
    'Get-TestResultAggregation',
    'Export-TestReport'
)

#endregion

Write-Host "Unity Test Automation Module loaded successfully" -ForegroundColor Green
# SIG # Begin signature block
# MIIFqQYJKoZIhvcNAQcCoIIFmjCCBZYCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUmBqZsbUeGt5rcWikncjXBS+8
# GlOgggMwMIIDLDCCAhSgAwIBAgIQdR0W2SKoK5VE8JId4ZxrRTANBgkqhkiG9w0B
# AQsFADAuMSwwKgYDVQQDDCNVbml0eS1DbGF1ZGUtQXV0b21hdGlvbi1EZXZlbG9w
# bWVudDAeFw0yNTA4MjAyMTE1MTdaFw0yNjA4MjAyMTM1MTdaMC4xLDAqBgNVBAMM
# I1VuaXR5LUNsYXVkZS1BdXRvbWF0aW9uLURldmVsb3BtZW50MIIBIjANBgkqhkiG
# 9w0BAQEFAAOCAQ8AMIIBCgKCAQEAseH3qinVEOhrn2OLpjc5TNT4vGh1BkfB5X4S
# FhY7K0QMQsYYnkZVmx3tB8PqVQXl++l+e3uT7uCscc7vjMTK8tDSWH98ji0U34WL
# JBwXC62l1ArazMKp4Tyr7peksei7vL4pZOtOVgAyTYn5d1hbnsVQmCSTPRtpn7mC
# Azfq2ec5qZ9Kgl7puPW5utvYfh8idtOWa5/WgYSKwOIvyZawIdZKLFpwqOtqbJe4
# sWzVahasFhLfoAKkniKOAocJDkJexh5pO/EOSKEZ3mOCU1ZSs4XWRGISRhV3qGZp
# f+Y3JlHKMeFDWKynaJBO8/GU5sqMATlDUvrByBtU2OQ2Um/L3QIDAQABo0YwRDAO
# BgNVHQ8BAf8EBAMCB4AwEwYDVR0lBAwwCgYIKwYBBQUHAwMwHQYDVR0OBBYEFHw5
# rOy6xlW6B45sJUsiI2A/yS0MMA0GCSqGSIb3DQEBCwUAA4IBAQAUTLH0+w8ysvmh
# YuBw4NDKcZm40MTh9Zc1M2p2hAkYsgNLJ+/rAP+I74rNfqguTYwxpCyjkwrg8yF5
# wViwggboLpF2yDu4N/dgDainR4wR8NVpS7zFZOFkpmNPepc6bw3d4yQKa/wJXKeC
# pkRjS50N77/hfVI+fFKNao7POb7en5fcXuZaN6xWoTRy+J4I4MhfHpjZuxSLSXjb
# VXtPD4RZ9HGjl9BU8162cRhjujr/Lc3/dY/6ikHQYnxuxcdxRew4nzaqAQaOeWu6
# tGp899JPKfldM5Zay5IBl3zs15gNS9+0Jrd0ARQnSVYoI0DLh3KybFnfK4POezoN
# Lp/dbX2SMYIB4zCCAd8CAQEwQjAuMSwwKgYDVQQDDCNVbml0eS1DbGF1ZGUtQXV0
# b21hdGlvbi1EZXZlbG9wbWVudAIQdR0W2SKoK5VE8JId4ZxrRTAJBgUrDgMCGgUA
# oHgwGAYKKwYBBAGCNwIBDDEKMAigAoAAoQKAADAZBgkqhkiG9w0BCQMxDAYKKwYB
# BAGCNwIBBDAcBgorBgEEAYI3AgELMQ4wDAYKKwYBBAGCNwIBFTAjBgkqhkiG9w0B
# CQQxFgQUDa2i7tLD1h9Rd2qCBWH6OGYSwoEwDQYJKoZIhvcNAQEBBQAEggEAOmkg
# fOOAA/WHjbidA0k+WaglGo0bCUutIvxtx99cSyRsZB3B8GOHeGdh8Fkiy3jfSi4G
# uE3HCK3vRpAhArQtTNzEx1wckNbDgkJ/onYwJQ5MJd5IvJjCrk/audcvnZ1lGxRJ
# 0HpVbqsiqY73sCufgxkLT/Gs8XUEIvj5mX5mA1uK1QXW+1LXvj2qBBF9RtZwT0J6
# bx71FuwIH3Pt0oSU+17nN66Tqclx+3Ge47jkgxObOL1ePR3k3XIC8CIZupEAQ0e6
# bWDVFat3MHThW9X16YsZE8BaAlN+FEy4weyo9rQ40J+QwN71J7qFaRVPluf/TU6x
# Q++zW5X3fecxjYeOfQ==
# SIG # End signature block
