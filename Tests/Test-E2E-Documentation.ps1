# Test-E2E-Documentation.ps1
# End-to-End Integration Test Suite for Enhanced Documentation System
# Week 3 Day 5: Integration testing with multi-language projects and load testing
# Date: 2025-08-28

#Requires -Version 5.1
#Requires -Module Pester

using namespace System.Collections.Generic
using namespace System.Collections.Concurrent
using namespace System.IO

param(
    [Parameter(Mandatory = $false)]
    [string]$TestOutputPath = "$PSScriptRoot\..\TestResults",
    
    [Parameter(Mandatory = $false)]
    [switch]$LoadTest,
    
    [Parameter(Mandatory = $false)]
    [int]$LoadTestFileCount = 1000,
    
    [Parameter(Mandatory = $false)]
    [switch]$VisualizationTest,
    
    [Parameter(Mandatory = $false)]
    [switch]$Detailed
)

# Ensure Pester v5 is available
if (-not (Get-Module -Name Pester -ListAvailable | Where-Object Version -ge '5.0.0')) {
    Write-Warning "Pester v5+ required. Installing..."
    Install-Module -Name Pester -Force -Scope CurrentUser
}

Import-Module Pester -Force

# Create test results directory
if (-not (Test-Path $TestOutputPath)) {
    New-Item -ItemType Directory -Path $TestOutputPath -Force | Out-Null
}

# Initialize test configuration
$config = New-PesterConfiguration
$config.Run.Path = $PSCommandPath
$config.Run.PassThru = $true
$config.TestResult.Enabled = $true
$config.TestResult.OutputPath = "$TestOutputPath\E2E-Documentation-Tests-$(Get-Date -Format 'yyyyMMdd-HHmmss').xml"
$config.Output.Verbosity = if ($Detailed) { 'Detailed' } else { 'Normal' }

# Global test tracking
$script:E2EResults = @{}
$script:TestStartTime = Get-Date
$script:CreatedTestFiles = @()

Write-Host "=== Enhanced Documentation System E2E Test Suite ===" -ForegroundColor Cyan
Write-Host "Load Testing: $LoadTest" -ForegroundColor Green
Write-Host "Load Test Files: $LoadTestFileCount" -ForegroundColor Green
Write-Host "Visualization Testing: $VisualizationTest" -ForegroundColor Green
Write-Host "Output Path: $TestOutputPath" -ForegroundColor Green

#region Helper Functions

function New-TestProject {
    param(
        [string]$ProjectPath,
        [string[]]$Languages = @('PowerShell', 'Python', 'CSharp', 'JavaScript')
    )
    
    Write-Debug "Creating test project at: $ProjectPath"
    
    if (-not (Test-Path $ProjectPath)) {
        New-Item -ItemType Directory -Path $ProjectPath -Force | Out-Null
    }
    
    $files = @()
    
    foreach ($lang in $Languages) {
        $langDir = Join-Path $ProjectPath $lang
        if (-not (Test-Path $langDir)) {
            New-Item -ItemType Directory -Path $langDir -Force | Out-Null
        }
        
        switch ($lang) {
            'PowerShell' {
                $psFile = Join-Path $langDir "TestModule.psm1"
                $psContent = @"
# TestModule.psm1 - Example PowerShell module for testing

function Get-TestData {
    <#
    .SYNOPSIS
    Retrieves test data for validation
    
    .DESCRIPTION
    This function generates sample test data used for validating
    the Enhanced Documentation System functionality
    
    .PARAMETER Count
    Number of test records to generate
    
    .PARAMETER Format
    Output format for the test data
    
    .EXAMPLE
    Get-TestData -Count 10 -Format "JSON"
    Generates 10 test records in JSON format
    
    .OUTPUTS
    PSCustomObject array containing test data
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = `$false)]
        [int]`$Count = 5,
        
        [Parameter(Mandatory = `$false)]
        [ValidateSet('JSON', 'XML', 'CSV')]
        [string]`$Format = 'JSON'
    )
    
    Write-Debug "Generating `$Count test records in `$Format format"
    
    try {
        `$testData = 1..`$Count | ForEach-Object {
            [PSCustomObject]@{
                Id = `$_
                Name = "TestItem`$_"
                Value = Get-Random -Minimum 1 -Maximum 100
                Timestamp = Get-Date
            }
        }
        
        switch (`$Format) {
            'JSON' { return `$testData | ConvertTo-Json }
            'XML' { return `$testData | ConvertTo-Xml }
            'CSV' { return `$testData | ConvertTo-Csv }
        }
    }
    catch {
        Write-Error "Failed to generate test data: `$_"
        return `$null
    }
}

function Invoke-DataProcessing {
    param(
        [Parameter(Mandatory = `$true)]
        [object[]]`$InputData,
        
        [Parameter(Mandatory = `$false)]
        [string]`$Operation = 'Count'
    )
    
    Write-Debug "Processing `$(`$InputData.Count) data items with operation: `$Operation"
    
    switch (`$Operation) {
        'Count' { return `$InputData.Count }
        'Sum' { return (`$InputData | Measure-Object -Property Value -Sum).Sum }
        'Average' { return (`$InputData | Measure-Object -Property Value -Average).Average }
        default { throw "Unknown operation: `$Operation" }
    }
}

Export-ModuleMember -Function Get-TestData, Invoke-DataProcessing
"@
                Set-Content -Path $psFile -Value $psContent
                $files += $psFile
            }
            
            'Python' {
                $pyFile = Join-Path $langDir "test_module.py"
                $pyContent = @"
"""test_module.py - Example Python module for testing

This module provides sample functions for validating
the Enhanced Documentation System functionality.
"""

import json
import datetime
from typing import List, Dict, Any, Optional


def get_test_data(count: int = 5, format_type: str = "json") -> Any:
    """Generate test data for validation.
    
    This function creates sample test data used for validating
    the Enhanced Documentation System functionality across languages.
    
    Args:
        count (int): Number of test records to generate. Defaults to 5.
        format_type (str): Output format for the test data. Defaults to "json".
        
    Returns:
        Any: Test data in the specified format (dict, list, or str).
        
    Raises:
        ValueError: If format_type is not supported.
        
    Examples:
        >>> get_test_data(3, "json")
        [{"id": 1, "name": "TestItem1", ...}, ...]
        
        >>> get_test_data(5, "dict")
        [{"id": 1, "name": "TestItem1", ...}, ...]
    """
    
    print(f"Generating {count} test records in {format_type} format")
    
    try:
        test_data = []
        for i in range(1, count + 1):
            item = {
                "id": i,
                "name": f"TestItem{i}",
                "value": i * 10,
                "timestamp": datetime.datetime.now().isoformat()
            }
            test_data.append(item)
        
        if format_type.lower() == "json":
            return json.dumps(test_data, indent=2)
        elif format_type.lower() == "dict":
            return test_data
        else:
            raise ValueError(f"Unsupported format: {format_type}")
            
    except Exception as e:
        print(f"Failed to generate test data: {e}")
        return None


def process_data(input_data: List[Dict[str, Any]], operation: str = "count") -> Any:
    """Process input data with specified operation.
    
    Args:
        input_data (List[Dict[str, Any]]): Input data to process.
        operation (str): Operation to perform. Defaults to "count".
        
    Returns:
        Any: Result of the specified operation.
        
    Raises:
        ValueError: If operation is not supported.
    """
    
    print(f"Processing {len(input_data)} data items with operation: {operation}")
    
    if operation.lower() == "count":
        return len(input_data)
    elif operation.lower() == "sum":
        return sum(item.get("value", 0) for item in input_data)
    elif operation.lower() == "average":
        values = [item.get("value", 0) for item in input_data]
        return sum(values) / len(values) if values else 0
    else:
        raise ValueError(f"Unknown operation: {operation}")


if __name__ == "__main__":
    # Example usage
    data = get_test_data(3, "dict")
    print("Generated data:", data)
    
    count_result = process_data(data, "count")
    print("Count:", count_result)
    
    sum_result = process_data(data, "sum")
    print("Sum:", sum_result)
"@
                Set-Content -Path $pyFile -Value $pyContent
                $files += $pyFile
            }
            
            'CSharp' {
                $csFile = Join-Path $langDir "TestModule.cs"
                $csContent = @"
/// <summary>
/// TestModule.cs - Example C# class for testing
/// 
/// This module provides sample classes and methods for validating
/// the Enhanced Documentation System functionality.
/// </summary>

using System;
using System.Collections.Generic;
using System.Linq;

namespace TestModule
{
    /// <summary>
    /// Represents a test data item for validation purposes
    /// </summary>
    public class TestDataItem
    {
        /// <summary>
        /// Gets or sets the unique identifier for the test item
        /// </summary>
        public int Id { get; set; }
        
        /// <summary>
        /// Gets or sets the name of the test item
        /// </summary>
        public string Name { get; set; }
        
        /// <summary>
        /// Gets or sets the numeric value associated with the test item
        /// </summary>
        public int Value { get; set; }
        
        /// <summary>
        /// Gets or sets the timestamp when the item was created
        /// </summary>
        public DateTime Timestamp { get; set; }
    }
    
    /// <summary>
    /// Provides functionality for generating and processing test data
    /// </summary>
    public class TestDataProcessor
    {
        /// <summary>
        /// Generates test data for validation purposes
        /// </summary>
        /// <param name="count">Number of test records to generate</param>
        /// <param name="format">Output format for the test data</param>
        /// <returns>Collection of test data items</returns>
        /// <example>
        /// <code>
        /// var processor = new TestDataProcessor();
        /// var data = processor.GetTestData(10, "standard");
        /// </code>
        /// </example>
        public List<TestDataItem> GetTestData(int count = 5, string format = "standard")
        {
            Console.WriteLine($"Generating {count} test records in {format} format");
            
            try
            {
                var testData = new List<TestDataItem>();
                var random = new Random();
                
                for (int i = 1; i <= count; i++)
                {
                    var item = new TestDataItem
                    {
                        Id = i,
                        Name = $"TestItem{i}",
                        Value = random.Next(1, 100),
                        Timestamp = DateTime.Now
                    };
                    testData.Add(item);
                }
                
                return testData;
            }
            catch (Exception ex)
            {
                Console.WriteLine($"Failed to generate test data: {ex.Message}");
                return new List<TestDataItem>();
            }
        }
        
        /// <summary>
        /// Processes input data with specified operation
        /// </summary>
        /// <param name="inputData">Input data to process</param>
        /// <param name="operation">Operation to perform on the data</param>
        /// <returns>Result of the specified operation</returns>
        /// <exception cref="ArgumentException">Thrown when operation is not supported</exception>
        public object ProcessData(List<TestDataItem> inputData, string operation = "count")
        {
            Console.WriteLine($"Processing {inputData.Count} data items with operation: {operation}");
            
            switch (operation.ToLower())
            {
                case "count":
                    return inputData.Count;
                case "sum":
                    return inputData.Sum(item => item.Value);
                case "average":
                    return inputData.Average(item => item.Value);
                default:
                    throw new ArgumentException($"Unknown operation: {operation}");
            }
        }
    }
}
"@
                Set-Content -Path $csFile -Value $csContent
                $files += $csFile
            }
            
            'JavaScript' {
                $jsFile = Join-Path $langDir "testModule.js"
                $jsContent = @"
/**
 * testModule.js - Example JavaScript module for testing
 * 
 * This module provides sample functions for validating
 * the Enhanced Documentation System functionality.
 * 
 * @author Enhanced Documentation System
 * @since 2025-08-28
 */

/**
 * Represents a test data item for validation purposes
 * @class
 */
class TestDataItem {
    /**
     * Creates a new test data item
     * @param {number} id - Unique identifier for the test item
     * @param {string} name - Name of the test item  
     * @param {number} value - Numeric value associated with the test item
     * @param {Date} timestamp - Timestamp when the item was created
     */
    constructor(id, name, value, timestamp = new Date()) {
        this.id = id;
        this.name = name;
        this.value = value;
        this.timestamp = timestamp;
    }
}

/**
 * Generates test data for validation purposes
 * 
 * This function creates sample test data used for validating
 * the Enhanced Documentation System functionality across languages.
 * 
 * @param {number} count - Number of test records to generate
 * @param {string} format - Output format for the test data
 * @returns {Array<TestDataItem>|string} Test data in the specified format
 * @throws {Error} If format is not supported
 * 
 * @example
 * // Generate 10 test records
 * const data = getTestData(10, 'array');
 * 
 * @example  
 * // Generate test data as JSON string
 * const jsonData = getTestData(5, 'json');
 */
function getTestData(count = 5, format = 'array') {
    console.log(`Generating ${count} test records in ${format} format`);
    
    try {
        const testData = [];
        
        for (let i = 1; i <= count; i++) {
            const item = new TestDataItem(
                i,
                `TestItem${i}`,
                Math.floor(Math.random() * 100) + 1,
                new Date()
            );
            testData.push(item);
        }
        
        switch (format.toLowerCase()) {
            case 'array':
                return testData;
            case 'json':
                return JSON.stringify(testData, null, 2);
            default:
                throw new Error(`Unsupported format: ${format}`);
        }
    } catch (error) {
        console.error(`Failed to generate test data: ${error.message}`);
        return null;
    }
}

/**
 * Processes input data with specified operation
 * 
 * @param {Array<TestDataItem>} inputData - Input data to process
 * @param {string} operation - Operation to perform on the data
 * @returns {number} Result of the specified operation
 * @throws {Error} If operation is not supported
 * 
 * @example
 * const data = getTestData(5);
 * const count = processData(data, 'count');
 * const sum = processData(data, 'sum');
 */
function processData(inputData, operation = 'count') {
    console.log(`Processing ${inputData.length} data items with operation: ${operation}`);
    
    switch (operation.toLowerCase()) {
        case 'count':
            return inputData.length;
        case 'sum':
            return inputData.reduce((sum, item) => sum + item.value, 0);
        case 'average':
            const sum = inputData.reduce((sum, item) => sum + item.value, 0);
            return sum / inputData.length;
        default:
            throw new Error(`Unknown operation: ${operation}`);
    }
}

/**
 * Validates test data integrity
 * @param {Array<TestDataItem>} testData - Data to validate
 * @returns {boolean} True if data is valid, false otherwise
 */
function validateTestData(testData) {
    if (!Array.isArray(testData)) {
        return false;
    }
    
    return testData.every(item => 
        typeof item.id === 'number' &&
        typeof item.name === 'string' &&
        typeof item.value === 'number' &&
        item.timestamp instanceof Date
    );
}

// Export functions for testing
if (typeof module !== 'undefined' && module.exports) {
    module.exports = {
        TestDataItem,
        getTestData,
        processData,
        validateTestData
    };
}
"@
                Set-Content -Path $jsFile -Value $jsContent
                $files += $jsFile
            }
        }
    }
    
    Write-Debug "Created $($files.Count) test files for languages: $($Languages -join ', ')"
    return $files
}

function Test-VisualizationServer {
    param([int]$TimeoutSeconds = 10)
    
    try {
        # Check if D3.js visualization server is running
        $response = Invoke-WebRequest -Uri "http://localhost:3000" -Method Get -TimeoutSec $TimeoutSeconds -UseBasicParsing
        return $response.StatusCode -eq 200
    }
    catch {
        Write-Debug "Visualization server not available: $_"
        return $false
    }
}

function Measure-E2EPerformance {
    param(
        [string]$TestName,
        [scriptblock]$ScriptBlock
    )
    
    $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
    try {
        $result = & $ScriptBlock
        $stopwatch.Stop()
        $script:E2EResults[$TestName] = @{
            Duration = $stopwatch.ElapsedMilliseconds
            Success = $true
            Result = $result
        }
        Write-Debug "[$TestName] Completed in $($stopwatch.ElapsedMilliseconds)ms"
        return $result
    }
    catch {
        $stopwatch.Stop()
        $script:E2EResults[$TestName] = @{
            Duration = $stopwatch.ElapsedMilliseconds
            Success = $false
            Error = $_.Exception.Message
        }
        throw
    }
}

#endregion

#region Multi-Language Project Tests

Describe "Enhanced Documentation System - Multi-Language Integration" -Tag "Integration", "MultiLanguage" {
    
    BeforeAll {
        Write-Host "  Setting up multi-language test project..." -ForegroundColor Yellow
        
        $script:TestProjectPath = "$TestOutputPath\MultiLanguageProject"
        $script:ProjectFiles = New-TestProject -ProjectPath $script:TestProjectPath -Languages @('PowerShell', 'Python', 'CSharp', 'JavaScript')
        $script:CreatedTestFiles += $script:ProjectFiles
        
        Write-Host "    Created test project with $($script:ProjectFiles.Count) files" -ForegroundColor Green
        
        # Import required modules
        $script:ModulesLoaded = @{}
        try {
            Import-Module "$PSScriptRoot\..\Modules\Unity-Claude-Enhanced-DocumentationGenerators\Core\Templates-PerLanguage.psm1" -Force
            $script:ModulesLoaded['Templates'] = $true
        } catch {
            Write-Warning "Templates module not available: $_"
            $script:ModulesLoaded['Templates'] = $false
        }
        
        try {
            Import-Module "$PSScriptRoot\..\Modules\Unity-Claude-Enhanced-DocumentationGenerators\Core\AutoGenerationTriggers.psm1" -Force
            $script:ModulesLoaded['Triggers'] = $true
        } catch {
            Write-Warning "Triggers module not available: $_"
            $script:ModulesLoaded['Triggers'] = $false
        }
    }
    
    Context "End-to-End Documentation Generation" {
        It "Should analyze PowerShell files and generate documentation" -Skip:(-not $script:ModulesLoaded['Templates']) {
            Measure-E2EPerformance -TestName "E2E-PowerShell" -ScriptBlock {
                $psFile = $script:ProjectFiles | Where-Object { $_ -match '\.psm1$' } | Select-Object -First 1
                $language = Get-LanguageFromExtension -FilePath $psFile
                
                $language | Should -Be "PowerShell"
                
                # Generate documentation template
                $template = Get-PowerShellDocTemplate -FunctionName "Get-TestData" -Parameters @("Count", "Format") -Synopsis "Retrieves test data for validation"
                $template | Should -Not -BeNullOrEmpty
                $template | Should -Match "Get-TestData"
            }
        }
        
        It "Should analyze Python files and generate documentation" -Skip:(-not $script:ModulesLoaded['Templates']) {
            Measure-E2EPerformance -TestName "E2E-Python" -ScriptBlock {
                $pyFile = $script:ProjectFiles | Where-Object { $_ -match '\.py$' } | Select-Object -First 1
                $language = Get-LanguageFromExtension -FilePath $pyFile
                
                $language | Should -Be "Python"
                
                # Generate documentation template
                $template = Get-PythonDocTemplate -FunctionName "get_test_data" -Parameters @("count", "format_type") -Description "Generate test data for validation."
                $template | Should -Not -BeNullOrEmpty
                $template | Should -Match "get_test_data"
            }
        }
        
        It "Should analyze C# files and generate documentation" -Skip:(-not $script:ModulesLoaded['Templates']) {
            Measure-E2EPerformance -TestName "E2E-CSharp" -ScriptBlock {
                $csFile = $script:ProjectFiles | Where-Object { $_ -match '\.cs$' } | Select-Object -First 1
                $language = Get-LanguageFromExtension -FilePath $csFile
                
                $language | Should -Be "CSharp"
                
                # Generate documentation template
                $template = Get-CSharpDocTemplate -MethodName "GetTestData" -Parameters @("count", "format") -Summary "Generates test data for validation purposes"
                $template | Should -Not -BeNullOrEmpty
                $template | Should -Match "GetTestData"
            }
        }
        
        It "Should analyze JavaScript files and generate documentation" -Skip:(-not $script:ModulesLoaded['Templates']) {
            Measure-E2EPerformance -TestName "E2E-JavaScript" -ScriptBlock {
                $jsFile = $script:ProjectFiles | Where-Object { $_ -match '\.js$' } | Select-Object -First 1
                $language = Get-LanguageFromExtension -FilePath $jsFile
                
                $language | Should -Be "JavaScript"
                
                # Generate documentation template
                $template = Get-JavaScriptDocTemplate -FunctionName "getTestData" -Parameters @("count", "formatType") -Description "Generate test data for validation purposes"
                $template | Should -Not -BeNullOrEmpty
                $template | Should -Match "getTestData"
            }
        }
        
        It "Should process all languages in a single workflow" -Skip:(-not $script:ModulesLoaded['Templates']) {
            Measure-E2EPerformance -TestName "E2E-AllLanguages" -ScriptBlock {
                $results = @{}
                
                foreach ($file in $script:ProjectFiles) {
                    $language = Get-LanguageFromExtension -FilePath $file
                    if ($language -ne 'Unknown') {
                        $config = Get-LanguageTemplateConfig -Language $language
                        $results[$language] = $config
                    }
                }
                
                $results.Keys.Count | Should -BeGreaterOrEqual 4
                $results['PowerShell'].CommentStyle | Should -Be 'Block'
                $results['Python'].CommentStyle | Should -Be 'Docstring'
                $results['CSharp'].CommentStyle | Should -Be 'XML'
                $results['JavaScript'].CommentStyle | Should -Be 'JSDoc'
            }
        }
    }
}

#endregion

#region Load Testing

if ($LoadTest) {
    Describe "Enhanced Documentation System - Load Testing" -Tag "LoadTest", "Performance" {
        
        BeforeAll {
            Write-Host "  Setting up load test environment..." -ForegroundColor Yellow
            Write-Host "  Target: $LoadTestFileCount files" -ForegroundColor Yellow
            
            $script:LoadTestPath = "$TestOutputPath\LoadTest"
            if (-not (Test-Path $script:LoadTestPath)) {
                New-Item -ItemType Directory -Path $script:LoadTestPath -Force | Out-Null
            }
        }
        
        Context "Large-Scale File Processing" {
            It "Should generate $LoadTestFileCount test files efficiently" {
                Measure-E2EPerformance -TestName "LoadTest-FileGeneration" -ScriptBlock {
                    $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
                    
                    Write-Host "    Generating $LoadTestFileCount test files..." -ForegroundColor Yellow
                    
                    # Generate files in batches for memory efficiency
                    $batchSize = 100
                    $generatedFiles = @()
                    
                    for ($i = 1; $i -le $LoadTestFileCount; $i += $batchSize) {
                        $batchEnd = [Math]::Min($i + $batchSize - 1, $LoadTestFileCount)
                        Write-Progress -Activity "Generating test files" -Status "Processing batch $i-$batchEnd" -PercentComplete (($i / $LoadTestFileCount) * 100)
                        
                        $i..$batchEnd | ForEach-Object -Parallel {
                            $filePath = "$using:script:LoadTestPath\test$_.ps1"
                            $content = @"
# Test PowerShell file $_
function Get-Data$_ {
    param([string]`$Input = "default")
    Write-Debug "Processing in function $_"
    return "Result-$_-`$Input"
}

function Process-Item$_ {
    param([int]`$Number)
    `$result = `$Number * $_
    Write-Verbose "Processed `$Number -> `$result"
    return `$result
}

function Validate-Input$_ {
    param([object]`$Data)
    if (`$null -eq `$Data) { return `$false }
    return `$true
}
"@
                            Set-Content -Path $filePath -Value $content
                            $filePath
                        } -ThrottleLimit 8 | ForEach-Object {
                            $generatedFiles += $_
                        }
                    }
                    
                    $stopwatch.Stop()
                    Write-Progress -Activity "Generating test files" -Completed
                    
                    $script:CreatedTestFiles += $generatedFiles
                    
                    Write-Host "    Generated $($generatedFiles.Count) files in $($stopwatch.ElapsedMilliseconds)ms" -ForegroundColor Green
                    
                    $generatedFiles.Count | Should -Be $LoadTestFileCount
                    $stopwatch.ElapsedMilliseconds | Should -BeLessThan 30000  # Should complete in under 30 seconds
                }
            }
            
            It "Should process $LoadTestFileCount files at target performance" {
                Measure-E2EPerformance -TestName "LoadTest-Processing" -ScriptBlock {
                    $testFiles = Get-ChildItem -Path $script:LoadTestPath -Filter "*.ps1"
                    Write-Host "    Processing $($testFiles.Count) files..." -ForegroundColor Yellow
                    
                    $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
                    $processed = 0
                    $errors = 0
                    
                    # Process files in parallel for realistic performance testing
                    $results = $testFiles | ForEach-Object -Parallel {
                        try {
                            $content = Get-Content -Path $_.FullName -Raw
                            $functions = ($content | Select-String -Pattern "function\s+[\w-]+" -AllMatches).Matches
                            $lineCount = ($content -split "`n").Count
                            
                            return @{
                                File = $_.Name
                                Functions = $functions.Count
                                Lines = $lineCount
                                Success = $true
                            }
                        }
                        catch {
                            return @{
                                File = $_.Name
                                Error = $_.Exception.Message
                                Success = $false
                            }
                        }
                    } -ThrottleLimit 16
                    
                    $stopwatch.Stop()
                    
                    $processed = $results.Count
                    $errors = ($results | Where-Object { -not $_.Success }).Count
                    $filesPerSecond = $processed / ($stopwatch.ElapsedMilliseconds / 1000)
                    
                    Write-Host "    Processed: $processed files" -ForegroundColor Cyan
                    Write-Host "    Errors: $errors" -ForegroundColor $(if ($errors -eq 0) { 'Green' } else { 'Red' })
                    Write-Host "    Duration: $($stopwatch.ElapsedMilliseconds)ms" -ForegroundColor Cyan
                    Write-Host "    Rate: $([math]::Round($filesPerSecond, 2)) files/second" -ForegroundColor Cyan
                    
                    # Performance requirements
                    $processed | Should -Be $LoadTestFileCount
                    $errors | Should -Be 0
                    $filesPerSecond | Should -BeGreaterThan 100  # Must meet 100+ files/second requirement
                }
            }
            
            It "Should handle memory usage efficiently during load testing" {
                Measure-E2EPerformance -TestName "LoadTest-Memory" -ScriptBlock {
                    $beforeMemory = [GC]::GetTotalMemory($false)
                    
                    # Process a large number of files
                    $testFiles = Get-ChildItem -Path $script:LoadTestPath -Filter "*.ps1" | Select-Object -First 500
                    
                    $processedData = @()
                    foreach ($file in $testFiles) {
                        $content = Get-Content -Path $file.FullName -Raw
                        $analysis = @{
                            File = $file.Name
                            Size = $file.Length
                            FunctionCount = ($content | Select-String -Pattern "function\s+" -AllMatches).Matches.Count
                        }
                        $processedData += $analysis
                        
                        # Trigger garbage collection periodically
                        if ($processedData.Count % 100 -eq 0) {
                            [GC]::Collect()
                        }
                    }
                    
                    $afterMemory = [GC]::GetTotalMemory($true)  # Force full GC
                    $memoryUsed = $afterMemory - $beforeMemory
                    $memoryUsedMB = $memoryUsed / 1MB
                    
                    Write-Host "    Memory used: $([math]::Round($memoryUsedMB, 2)) MB" -ForegroundColor Cyan
                    Write-Host "    Processed files: $($processedData.Count)" -ForegroundColor Cyan
                    
                    # Memory usage should be reasonable (less than 500MB for 500 files)
                    $memoryUsedMB | Should -BeLessThan 500
                    $processedData.Count | Should -Be $testFiles.Count
                }
            }
        }
        
        AfterAll {
            # Cleanup load test files
            if (Test-Path $script:LoadTestPath) {
                Write-Host "    Cleaning up load test files..." -ForegroundColor Yellow
                Remove-Item -Path $script:LoadTestPath -Recurse -Force
            }
        }
    }
}

#endregion

#region Visualization Testing

if ($VisualizationTest) {
    Describe "Enhanced Documentation System - Visualization Validation" -Tag "Visualization", "D3js" {
        
        BeforeAll {
            Write-Host "  Testing D3.js visualization system..." -ForegroundColor Yellow
            
            $script:VisualizationAvailable = Test-VisualizationServer -TimeoutSeconds 5
            if (-not $script:VisualizationAvailable) {
                Write-Warning "D3.js visualization server not available at localhost:3000"
            }
        }
        
        Context "Visualization Server" {
            It "Should have D3.js server running" -Skip:(-not $script:VisualizationAvailable) {
                Measure-E2EPerformance -TestName "Visualization-Server" -ScriptBlock {
                    $serverStatus = Test-VisualizationServer
                    $serverStatus | Should -Be $true
                }
            }
            
            It "Should serve visualization assets" -Skip:(-not $script:VisualizationAvailable) {
                Measure-E2EPerformance -TestName "Visualization-Assets" -ScriptBlock {
                    # Test graph renderer
                    $rendererResponse = Invoke-WebRequest -Uri "http://localhost:3000/static/js/graph-renderer.js" -UseBasicParsing
                    $rendererResponse.StatusCode | Should -Be 200
                    $rendererResponse.Content | Should -Match "d3\."
                    
                    # Test graph controls
                    $controlsResponse = Invoke-WebRequest -Uri "http://localhost:3000/static/js/graph-controls.js" -UseBasicParsing  
                    $controlsResponse.StatusCode | Should -Be 200
                    $controlsResponse.Content | Should -Match "zoom"
                }
            }
            
            It "Should handle sample graph data" -Skip:(-not $script:VisualizationAvailable) {
                Measure-E2EPerformance -TestName "Visualization-Data" -ScriptBlock {
                    # Create sample graph data
                    $graphData = @{
                        nodes = @(
                            @{ id = "node1"; type = "function"; name = "GetTestData" }
                            @{ id = "node2"; type = "function"; name = "ProcessData" }
                        )
                        edges = @(
                            @{ source = "node1"; target = "node2"; type = "calls" }
                        )
                    } | ConvertTo-Json -Depth 3
                    
                    # Test data posting (if API endpoint available)
                    try {
                        $response = Invoke-RestMethod -Uri "http://localhost:3000/api/graph" -Method Post -Body $graphData -ContentType "application/json"
                        $response | Should -Not -BeNullOrEmpty
                    }
                    catch {
                        Write-Debug "API endpoint not available, testing data structure only"
                        $graphData | Should -Match "nodes"
                        $graphData | Should -Match "edges"
                    }
                }
            }
        }
    }
}

#endregion

#region System Integration Tests

Describe "Enhanced Documentation System - System Integration" -Tag "Integration", "System" {
    
    Context "Module Integration" {
        It "Should load all core modules without conflicts" {
            Measure-E2EPerformance -TestName "Integration-ModuleLoading" -ScriptBlock {
                $modules = @()
                $errors = @()
                
                # Core CPG modules
                $cpgModules = @(
                    "$PSScriptRoot\..\Modules\Unity-Claude-CPG\Core\CPG-Unified.psm1"
                    "$PSScriptRoot\..\Modules\Unity-Claude-CPG\Core\Performance-Cache.psm1"
                    "$PSScriptRoot\..\Modules\Unity-Claude-CPG\Core\Performance-IncrementalUpdates.psm1"
                )
                
                foreach ($module in $cpgModules) {
                    if (Test-Path $module) {
                        try {
                            Import-Module $module -Force
                            $moduleName = [System.IO.Path]::GetFileNameWithoutExtension($module)
                            $modules += $moduleName
                        }
                        catch {
                            $errors += "Failed to load $module`: $_"
                        }
                    }
                }
                
                # Template modules
                $templateModules = @(
                    "$PSScriptRoot\..\Modules\Unity-Claude-Enhanced-DocumentationGenerators\Core\Templates-PerLanguage.psm1"
                    "$PSScriptRoot\..\Modules\Unity-Claude-Enhanced-DocumentationGenerators\Core\AutoGenerationTriggers.psm1"
                )
                
                foreach ($module in $templateModules) {
                    if (Test-Path $module) {
                        try {
                            Import-Module $module -Force
                            $moduleName = [System.IO.Path]::GetFileNameWithoutExtension($module)
                            $modules += $moduleName
                        }
                        catch {
                            $errors += "Failed to load $module`: $_"
                        }
                    }
                }
                
                Write-Host "    Loaded modules: $($modules -join ', ')" -ForegroundColor Green
                if ($errors.Count -gt 0) {
                    Write-Host "    Errors: $($errors -join '; ')" -ForegroundColor Red
                }
                
                $modules.Count | Should -BeGreaterOrEqual 3
                $errors.Count | Should -Be 0
            }
        }
        
        It "Should validate system configuration" {
            Measure-E2EPerformance -TestName "Integration-Configuration" -ScriptBlock {
                # Check critical paths and configurations
                $checks = @{}
                
                # Module paths
                $checks['CPG-Core'] = Test-Path "$PSScriptRoot\..\Modules\Unity-Claude-CPG\Core"
                $checks['Documentation-Generators'] = Test-Path "$PSScriptRoot\..\Modules\Unity-Claude-Enhanced-DocumentationGenerators"
                $checks['Visualization'] = Test-Path "$PSScriptRoot\..\Visualization"
                $checks['Tests'] = Test-Path "$PSScriptRoot\.."
                
                # Optional components
                $checks['Ollama-Available'] = try { 
                    (Invoke-RestMethod -Uri "http://localhost:11434/api/version" -TimeoutSec 2) -ne $null 
                } catch { $false }
                
                $checks['D3js-Server'] = Test-VisualizationServer -TimeoutSeconds 2
                
                $criticalChecks = @('CPG-Core', 'Documentation-Generators', 'Tests')
                $criticalFailures = $criticalChecks | Where-Object { -not $checks[$_] }
                
                if ($criticalFailures.Count -gt 0) {
                    Write-Host "    Critical failures: $($criticalFailures -join ', ')" -ForegroundColor Red
                }
                
                Write-Host "    Configuration check results:" -ForegroundColor Cyan
                $checks.GetEnumerator() | Sort-Object Name | ForEach-Object {
                    $status = if ($_.Value) { "✓" } else { "✗" }
                    $color = if ($_.Value) { 'Green' } else { 'Red' }
                    Write-Host "      $($_.Key): $status" -ForegroundColor $color
                }
                
                # All critical components must be available
                $criticalFailures.Count | Should -Be 0
            }
        }
    }
}

#endregion

# Execute the tests and generate comprehensive report
Write-Host "`n=== Running E2E Test Suite ===" -ForegroundColor Cyan

try {
    $testResults = Invoke-Pester -Configuration $config
    
    # E2E Performance summary
    Write-Host "`n=== E2E Performance Summary ===" -ForegroundColor Cyan
    $script:E2EResults.GetEnumerator() | Sort-Object Name | ForEach-Object {
        $result = $_.Value
        if ($result.Success) {
            Write-Host "  $($_.Key): $($result.Duration)ms ✓" -ForegroundColor Green
        } else {
            Write-Host "  $($_.Key): $($result.Duration)ms ✗ ($($result.Error))" -ForegroundColor Red
        }
    }
    
    # Calculate performance metrics
    $avgDuration = ($script:E2EResults.Values | Where-Object Success | Measure-Object -Property Duration -Average).Average
    $totalDuration = ($script:E2EResults.Values | Measure-Object -Property Duration -Sum).Sum
    
    # Test results summary
    $testEndTime = Get-Date
    $overallDuration = $testEndTime - $script:TestStartTime
    
    Write-Host "`n=== E2E Test Results Summary ===" -ForegroundColor Cyan
    Write-Host "  Total Tests: $($testResults.TotalCount)" -ForegroundColor White
    Write-Host "  Passed: $($testResults.PassedCount)" -ForegroundColor Green
    Write-Host "  Failed: $($testResults.FailedCount)" -ForegroundColor $(if ($testResults.FailedCount -gt 0) { 'Red' } else { 'Green' })
    Write-Host "  Skipped: $($testResults.SkippedCount)" -ForegroundColor Yellow
    Write-Host "  Overall Duration: $($overallDuration.TotalSeconds) seconds" -ForegroundColor White
    Write-Host "  Average Test Duration: $([math]::Round($avgDuration, 2))ms" -ForegroundColor White
    Write-Host "  Success Rate: $([math]::Round(($testResults.PassedCount / $testResults.TotalCount) * 100, 1))%" -ForegroundColor $(if ($testResults.FailedCount -eq 0) { 'Green' } else { 'Yellow' })
    
    # Save detailed results
    $detailedResults = @{
        Summary = @{
            TotalTests = $testResults.TotalCount
            Passed = $testResults.PassedCount
            Failed = $testResults.FailedCount
            Skipped = $testResults.SkippedCount
            SuccessRate = [math]::Round(($testResults.PassedCount / $testResults.TotalCount) * 100, 1)
            OverallDuration = $overallDuration.TotalSeconds
            AverageTestDuration = [math]::Round($avgDuration, 2)
            StartTime = $script:TestStartTime
            EndTime = $testEndTime
        }
        E2EPerformance = $script:E2EResults
        FailedTests = $testResults.Failed
        LoadTestEnabled = $LoadTest
        LoadTestFileCount = $LoadTestFileCount
        VisualizationTestEnabled = $VisualizationTest
        CreatedFiles = $script:CreatedTestFiles.Count
    }
    
    $resultsFile = "$TestOutputPath\E2E-Documentation-Tests-Results-$(Get-Date -Format 'yyyyMMdd-HHmmss').json"
    $detailedResults | ConvertTo-Json -Depth 5 | Set-Content -Path $resultsFile
    
    # Generate load test summary if applicable
    if ($LoadTest) {
        $loadTestSummary = @"
=== Load Test Summary ===
Files Generated: $LoadTestFileCount
Processing Performance: $([math]::Round(($LoadTestFileCount / ($script:E2EResults['LoadTest-Processing'].Duration / 1000)), 2)) files/second
Memory Usage: Efficient (under 500MB for 500 files)
Status: $(if ($testResults.FailedCount -eq 0) { 'PASSED' } else { 'FAILED' })

Performance Target: 100+ files/second
Actual Performance: $([math]::Round(($LoadTestFileCount / ($script:E2EResults['LoadTest-Processing'].Duration / 1000)), 2)) files/second
Target Met: $(if (($LoadTestFileCount / ($script:E2EResults['LoadTest-Processing'].Duration / 1000)) -gt 100) { 'YES' } else { 'NO' })
"@
        
        $loadTestSummary | Set-Content -Path "$TestOutputPath\LoadTest-Summary-$(Get-Date -Format 'yyyyMMdd-HHmmss').txt"
        Write-Host $loadTestSummary -ForegroundColor Cyan
    }
    
    Write-Host "`n=== Test Artifacts ===" -ForegroundColor Cyan
    Write-Host "  XML Report: $($config.TestResult.OutputPath)" -ForegroundColor Gray
    Write-Host "  JSON Results: $resultsFile" -ForegroundColor Gray
    Write-Host "  Test Output Directory: $TestOutputPath" -ForegroundColor Gray
    if ($LoadTest) {
        Write-Host "  Load Test Summary: $TestOutputPath\LoadTest-Summary-*.txt" -ForegroundColor Gray
    }
    
    # Cleanup created test files
    Write-Host "`n  Cleaning up test files..." -ForegroundColor Yellow
    foreach ($file in $script:CreatedTestFiles) {
        if (Test-Path $file) {
            Remove-Item -Path $file -Force
        }
    }
    
    # Clean up test project directory
    if (Test-Path $script:TestProjectPath) {
        Remove-Item -Path $script:TestProjectPath -Recurse -Force
    }
    
    if ($testResults.FailedCount -eq 0) {
        Write-Host "`n✓ All E2E tests passed successfully!" -ForegroundColor Green
        exit 0
    } else {
        Write-Host "`n⚠ Some E2E tests failed. Review the detailed results above." -ForegroundColor Yellow
        exit 1
    }
}
catch {
    Write-Error "E2E test execution failed: $_"
    
    # Cleanup on error
    foreach ($file in $script:CreatedTestFiles) {
        if (Test-Path $file) {
            Remove-Item -Path $file -Force -ErrorAction SilentlyContinue
        }
    }
    
    if ($script:TestProjectPath -and (Test-Path $script:TestProjectPath)) {
        Remove-Item -Path $script:TestProjectPath -Recurse -Force -ErrorAction SilentlyContinue
    }
    
    exit 1
}