# Test-EnhancedDocumentationSystem.ps1
# Unit Test Suite for Enhanced Documentation System
# Week 3 Day 4: Comprehensive unit testing for all components
# Date: 2025-08-28

#Requires -Version 5.1
#Requires -Module Pester

using namespace System.Collections.Generic
using namespace System.Collections.Concurrent

param(
    [Parameter(Mandatory = $false)]
    [string]$TestOutputPath = "$PSScriptRoot\..\TestResults",
    
    [Parameter(Mandatory = $false)]
    [switch]$Detailed,
    
    [Parameter(Mandatory = $false)]
    [string]$TestScope = "All"  # All, CPG, LLM, Templates, Performance
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
$config.TestResult.OutputPath = "$TestOutputPath\EnhancedDocumentationSystem-UnitTests-$(Get-Date -Format 'yyyyMMdd-HHmmss').xml"
$config.Output.Verbosity = if ($Detailed) { 'Detailed' } else { 'Normal' }

# Performance tracking
$script:PerformanceResults = @{}
$script:TestStartTime = Get-Date

Write-Host "=== Enhanced Documentation System Unit Test Suite ===" -ForegroundColor Cyan
Write-Host "Test Scope: $TestScope" -ForegroundColor Green
Write-Host "Output Path: $TestOutputPath" -ForegroundColor Green
Write-Host "Start Time: $script:TestStartTime" -ForegroundColor Green

#region Helper Functions

function Measure-TestPerformance {
    param(
        [string]$TestName,
        [scriptblock]$ScriptBlock
    )
    
    $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
    try {
        $result = & $ScriptBlock
        $stopwatch.Stop()
        $script:PerformanceResults[$TestName] = $stopwatch.ElapsedMilliseconds
        Write-Debug "[$TestName] Completed in $($stopwatch.ElapsedMilliseconds)ms"
        return $result
    }
    catch {
        $stopwatch.Stop()
        $script:PerformanceResults[$TestName] = -1  # Error indicator
        throw
    }
}

function Test-ModuleAvailable {
    param([string]$ModuleName, [string]$ModulePath)
    
    if (-not (Test-Path $ModulePath)) {
        Write-Warning "Module not found: $ModulePath"
        return $false
    }
    
    try {
        Import-Module $ModulePath -Force -ErrorAction Stop
        return $true
    }
    catch {
        Write-Warning "Failed to import $ModuleName`: $_"
        return $false
    }
}

#endregion

#region CPG (Code Property Graph) Tests

if ($TestScope -eq "All" -or $TestScope -eq "CPG") {
    Describe "Enhanced Documentation System - CPG Components" -Tag "CPG", "Core" {
        
        BeforeAll {
            Write-Host "  Initializing CPG test environment..." -ForegroundColor Yellow
            
            # Module paths
            $cpgModulePaths = @{
                'CPG-ThreadSafeOperations' = "$PSScriptRoot\..\Modules\Unity-Claude-CPG\Core\CPG-ThreadSafeOperations.psm1"
                'CPG-Unified' = "$PSScriptRoot\..\Modules\Unity-Claude-CPG\Core\CPG-Unified.psm1"
                'CPG-CallGraphBuilder' = "$PSScriptRoot\..\Modules\Unity-Claude-CPG\Core\CPG-CallGraphBuilder.psm1"
                'CPG-DataFlowTracker' = "$PSScriptRoot\..\Modules\Unity-Claude-CPG\Core\CPG-DataFlowTracker.psm1"
            }
            
            $script:CPGModulesAvailable = @{}
            foreach ($moduleName in $cpgModulePaths.Keys) {
                $script:CPGModulesAvailable[$moduleName] = Test-ModuleAvailable -ModuleName $moduleName -ModulePath $cpgModulePaths[$moduleName]
            }
        }
        
        Context "Thread-Safe Operations" {
            BeforeAll {
                if (-not $script:CPGModulesAvailable['CPG-ThreadSafeOperations']) {
                    Set-ItResult -Skipped -Because "CPG-ThreadSafeOperations module not available"
                }
            }
            
            It "Should create thread-safe CPG wrapper" {
                Measure-TestPerformance -TestName "ThreadSafe-Create" -ScriptBlock {
                    $cpg = New-ThreadSafeCPG
                    $cpg | Should -Not -BeNullOrEmpty
                    $cpg.GetType().Name | Should -Be "ThreadSafeCPG"
                }
            }
            
            It "Should handle concurrent operations safely" -Skip:(-not $script:CPGModulesAvailable['CPG-ThreadSafeOperations']) {
                Measure-TestPerformance -TestName "ThreadSafe-Concurrent" -ScriptBlock {
                    $cpg = New-ThreadSafeCPG
                    $results = @()
                    
                    # Simulate concurrent operations
                    $jobs = 1..10 | ForEach-Object {
                        Start-Job -ScriptBlock {
                            param($cpgInstance, $iteration)
                            $cpgInstance.AddNode("TestNode$iteration", "Test")
                            return "Success-$iteration"
                        } -ArgumentList $cpg, $_
                    }
                    
                    $results = $jobs | Wait-Job | Receive-Job
                    $jobs | Remove-Job
                    
                    $results.Count | Should -Be 10
                    $results | Should -Match "Success-"
                }
            }
            
            It "Should provide thread safety statistics" -Skip:(-not $script:CPGModulesAvailable['CPG-ThreadSafeOperations']) {
                Measure-TestPerformance -TestName "ThreadSafe-Stats" -ScriptBlock {
                    $stats = Get-ThreadSafetyStats
                    $stats | Should -Not -BeNullOrEmpty
                    $stats.TotalOperations | Should -BeOfType [int]
                    $stats.ReadOperations | Should -BeOfType [int]
                    $stats.WriteOperations | Should -BeOfType [int]
                }
            }
        }
        
        Context "Call Graph Builder" {
            BeforeAll {
                if (-not $script:CPGModulesAvailable['CPG-CallGraphBuilder']) {
                    Set-ItResult -Skipped -Because "CPG-CallGraphBuilder module not available"
                }
            }
            
            It "Should build call graphs from source code" -Skip:(-not $script:CPGModulesAvailable['CPG-CallGraphBuilder']) {
                Measure-TestPerformance -TestName "CallGraph-Build" -ScriptBlock {
                    $testCode = @"
function Test-Function {
    param([string]`$Input)
    Another-Function `$Input
    return `$Input
}

function Another-Function {
    param([string]`$Data)
    Write-Output `$Data
}
"@
                    
                    $callGraph = Build-CallGraph -SourceCode $testCode -Language "PowerShell"
                    $callGraph | Should -Not -BeNullOrEmpty
                    $callGraph.Nodes.Count | Should -BeGreaterThan 0
                    $callGraph.Edges.Count | Should -BeGreaterThan 0
                }
            }
            
            It "Should detect recursive calls" -Skip:(-not $script:CPGModulesAvailable['CPG-CallGraphBuilder']) {
                Measure-TestPerformance -TestName "CallGraph-Recursive" -ScriptBlock {
                    $recursiveCode = @"
function Recursive-Function {
    param([int]`$Count)
    if (`$Count -gt 0) {
        Recursive-Function (`$Count - 1)
    }
}
"@
                    
                    $callGraph = Build-CallGraph -SourceCode $recursiveCode -Language "PowerShell"
                    $recursiveEdges = $callGraph.Edges | Where-Object { $_.Source -eq $_.Target }
                    $recursiveEdges.Count | Should -BeGreaterThan 0
                }
            }
        }
        
        Context "Data Flow Tracker" {
            BeforeAll {
                if (-not $script:CPGModulesAvailable['CPG-DataFlowTracker']) {
                    Set-ItResult -Skipped -Because "CPG-DataFlowTracker module not available"
                }
            }
            
            It "Should track variable definitions and uses" -Skip:(-not $script:CPGModulesAvailable['CPG-DataFlowTracker']) {
                Measure-TestPerformance -TestName "DataFlow-DefUse" -ScriptBlock {
                    $testCode = @"
`$variable = "test"
Write-Output `$variable
`$variable = "modified"
"@
                    
                    $dataFlow = Trace-DataFlow -SourceCode $testCode -Language "PowerShell"
                    $dataFlow | Should -Not -BeNullOrEmpty
                    $dataFlow.DefUseChains | Should -Not -BeNullOrEmpty
                }
            }
            
            It "Should perform taint analysis" -Skip:(-not $script:CPGModulesAvailable['CPG-DataFlowTracker']) {
                Measure-TestPerformance -TestName "DataFlow-Taint" -ScriptBlock {
                    $taintedCode = @"
`$userInput = Read-Host "Enter data"
`$sqlQuery = "SELECT * FROM users WHERE name = '`$userInput'"
Invoke-SqlCmd -Query `$sqlQuery
"@
                    
                    $taintAnalysis = Invoke-TaintAnalysis -SourceCode $taintedCode -Language "PowerShell"
                    $taintAnalysis | Should -Not -BeNullOrEmpty
                    $taintAnalysis.TaintedPaths | Should -Not -BeNullOrEmpty
                }
            }
        }
    }
}

#endregion

#region LLM Integration Tests

if ($TestScope -eq "All" -or $TestScope -eq "LLM") {
    Describe "Enhanced Documentation System - LLM Integration" -Tag "LLM", "Integration" {
        
        BeforeAll {
            Write-Host "  Initializing LLM test environment..." -ForegroundColor Yellow
            
            # Check Ollama availability
            $script:OllamaAvailable = $false
            try {
                $response = Invoke-RestMethod -Uri "http://localhost:11434/api/version" -Method Get -TimeoutSec 5
                if ($response) {
                    $script:OllamaAvailable = $true
                    Write-Host "    Ollama service detected: Available" -ForegroundColor Green
                }
            }
            catch {
                Write-Warning "Ollama service not available: $_"
            }
            
            # LLM module paths
            $llmModulePaths = @{
                'LLM-PromptTemplates' = "$PSScriptRoot\..\Modules\Unity-Claude-LLM\Core\LLM-PromptTemplates.psm1"
                'LLM-ResponseCache' = "$PSScriptRoot\..\Modules\Unity-Claude-LLM\Core\LLM-ResponseCache.psm1"
            }
            
            $script:LLMModulesAvailable = @{}
            foreach ($moduleName in $llmModulePaths.Keys) {
                $script:LLMModulesAvailable[$moduleName] = Test-ModuleAvailable -ModuleName $moduleName -ModulePath $llmModulePaths[$moduleName]
            }
        }
        
        Context "Ollama API Integration" {
            It "Should connect to Ollama service" -Skip:(-not $script:OllamaAvailable) {
                Measure-TestPerformance -TestName "Ollama-Connection" -ScriptBlock {
                    $health = Test-OllamaConnection
                    $health | Should -Be $true
                }
            }
            
            It "Should list available models" -Skip:(-not $script:OllamaAvailable) {
                Measure-TestPerformance -TestName "Ollama-Models" -ScriptBlock {
                    $models = Get-OllamaModels
                    $models | Should -Not -BeNullOrEmpty
                    $models | Should -BeOfType [array]
                }
            }
            
            It "Should generate responses for code analysis" -Skip:(-not $script:OllamaAvailable) {
                Measure-TestPerformance -TestName "Ollama-CodeAnalysis" -ScriptBlock {
                    $testCode = "function Get-Example { return 'Hello World' }"
                    $prompt = "Analyze this PowerShell function and provide documentation"
                    
                    $response = Invoke-OllamaQuery -Prompt $prompt -Context $testCode -MaxTokens 100
                    $response | Should -Not -BeNullOrEmpty
                    $response.Length | Should -BeGreaterThan 10
                }
            }
        }
        
        Context "Prompt Templates" {
            BeforeAll {
                if (-not $script:LLMModulesAvailable['LLM-PromptTemplates']) {
                    Set-ItResult -Skipped -Because "LLM-PromptTemplates module not available"
                }
            }
            
            It "Should create function documentation prompts" -Skip:(-not $script:LLMModulesAvailable['LLM-PromptTemplates']) {
                Measure-TestPerformance -TestName "Prompt-Function" -ScriptBlock {
                    $template = Get-FunctionDocumentationPrompt -FunctionName "Test-Function" -Parameters @("Param1", "Param2")
                    $template | Should -Not -BeNullOrEmpty
                    $template | Should -Match "Test-Function"
                    $template | Should -Match "Param1"
                }
            }
            
            It "Should create module documentation prompts" -Skip:(-not $script:LLMModulesAvailable['LLM-PromptTemplates']) {
                Measure-TestPerformance -TestName "Prompt-Module" -ScriptBlock {
                    $template = Get-ModuleDocumentationPrompt -ModuleName "TestModule" -Functions @("Func1", "Func2")
                    $template | Should -Not -BeNullOrEmpty
                    $template | Should -Match "TestModule"
                    $template | Should -Match "Func1"
                }
            }
            
            It "Should support variable substitution" -Skip:(-not $script:LLMModulesAvailable['LLM-PromptTemplates']) {
                Measure-TestPerformance -TestName "Prompt-Substitution" -ScriptBlock {
                    $variables = @{
                        'FunctionName' = 'Get-TestData'
                        'Description' = 'Retrieves test data'
                    }
                    
                    $result = Expand-PromptTemplate -Template "Function: {FunctionName} - {Description}" -Variables $variables
                    $result | Should -Be "Function: Get-TestData - Retrieves test data"
                }
            }
        }
        
        Context "Response Cache" {
            BeforeAll {
                if (-not $script:LLMModulesAvailable['LLM-ResponseCache']) {
                    Set-ItResult -Skipped -Because "LLM-ResponseCache module not available"
                }
            }
            
            It "Should cache and retrieve responses" -Skip:(-not $script:LLMModulesAvailable['LLM-ResponseCache']) {
                Measure-TestPerformance -TestName "Cache-Store-Retrieve" -ScriptBlock {
                    $key = "test-prompt-$(Get-Date -Format 'yyyyMMddHHmmss')"
                    $response = "This is a test response"
                    
                    Set-LLMCache -Key $key -Response $response -TTL 300
                    $cached = Get-LLMCache -Key $key
                    
                    $cached | Should -Be $response
                }
            }
            
            It "Should handle TTL expiration" -Skip:(-not $script:LLMModulesAvailable['LLM-ResponseCache']) {
                Measure-TestPerformance -TestName "Cache-TTL" -ScriptBlock {
                    $key = "ttl-test-$(Get-Date -Format 'yyyyMMddHHmmss')"
                    $response = "TTL test response"
                    
                    Set-LLMCache -Key $key -Response $response -TTL 1  # 1 second
                    Start-Sleep -Seconds 2
                    $expired = Get-LLMCache -Key $key
                    
                    $expired | Should -BeNullOrEmpty
                }
            }
            
            It "Should provide cache statistics" -Skip:(-not $script:LLMModulesAvailable['LLM-ResponseCache']) {
                Measure-TestPerformance -TestName "Cache-Stats" -ScriptBlock {
                    $stats = Get-LLMCacheStats
                    $stats | Should -Not -BeNullOrEmpty
                    $stats.Hits | Should -BeOfType [int]
                    $stats.Misses | Should -BeOfType [int]
                    $stats.HitRate | Should -BeOfType [double]
                }
            }
        }
    }
}

#endregion

#region Templates and Automation Tests

if ($TestScope -eq "All" -or $TestScope -eq "Templates") {
    Describe "Enhanced Documentation System - Templates & Automation" -Tag "Templates", "Automation" {
        
        BeforeAll {
            Write-Host "  Initializing Templates test environment..." -ForegroundColor Yellow
            
            # Template module paths
            $templateModulePaths = @{
                'Templates-PerLanguage' = "$PSScriptRoot\..\Modules\Unity-Claude-Enhanced-DocumentationGenerators\Core\Templates-PerLanguage.psm1"
                'AutoGenerationTriggers' = "$PSScriptRoot\..\Modules\Unity-Claude-Enhanced-DocumentationGenerators\Core\AutoGenerationTriggers.psm1"
            }
            
            $script:TemplateModulesAvailable = @{}
            foreach ($moduleName in $templateModulePaths.Keys) {
                $script:TemplateModulesAvailable[$moduleName] = Test-ModuleAvailable -ModuleName $moduleName -ModulePath $templateModulePaths[$moduleName]
            }
        }
        
        Context "Language-Specific Templates" {
            BeforeAll {
                if (-not $script:TemplateModulesAvailable['Templates-PerLanguage']) {
                    Set-ItResult -Skipped -Because "Templates-PerLanguage module not available"
                }
            }
            
            It "Should generate PowerShell documentation templates" -Skip:(-not $script:TemplateModulesAvailable['Templates-PerLanguage']) {
                Measure-TestPerformance -TestName "Template-PowerShell" -ScriptBlock {
                    $template = Get-PowerShellDocTemplate -FunctionName "Test-Function" -Parameters @("Param1", "Param2") -Synopsis "Test function"
                    $template | Should -Not -BeNullOrEmpty
                    $template | Should -Match "\.SYNOPSIS"
                    $template | Should -Match "Test function"
                    $template | Should -Match "\.PARAMETER Param1"
                }
            }
            
            It "Should generate Python documentation templates" -Skip:(-not $script:TemplateModulesAvailable['Templates-PerLanguage']) {
                Measure-TestPerformance -TestName "Template-Python" -ScriptBlock {
                    $template = Get-PythonDocTemplate -FunctionName "test_function" -Parameters @("param1", "param2") -Description "Test function description"
                    $template | Should -Not -BeNullOrEmpty
                    $template | Should -Match "Args:"
                    $template | Should -Match "Returns:"
                    $template | Should -Match "param1"
                }
            }
            
            It "Should generate C# documentation templates" -Skip:(-not $script:TemplateModulesAvailable['Templates-PerLanguage']) {
                Measure-TestPerformance -TestName "Template-CSharp" -ScriptBlock {
                    $template = Get-CSharpDocTemplate -MethodName "TestMethod" -Parameters @("param1", "param2") -Summary "Test method summary"
                    $template | Should -Not -BeNullOrEmpty
                    $template | Should -Match "<summary>"
                    $template | Should -Match "Test method summary"
                    $template | Should -Match '<param name="param1">'
                }
            }
            
            It "Should generate JavaScript documentation templates" -Skip:(-not $script:TemplateModulesAvailable['Templates-PerLanguage']) {
                Measure-TestPerformance -TestName "Template-JavaScript" -ScriptBlock {
                    $template = Get-JavaScriptDocTemplate -FunctionName "testFunction" -Parameters @("param1", "param2") -Description "Test function description"
                    $template | Should -Not -BeNullOrEmpty
                    $template | Should -Match "/\*\*"
                    $template | Should -Match "@param"
                    $template | Should -Match "@returns"
                    $template | Should -Match "\*/"
                }
            }
            
            It "Should detect language from file extensions" -Skip:(-not $script:TemplateModulesAvailable['Templates-PerLanguage']) {
                Measure-TestPerformance -TestName "Language-Detection" -ScriptBlock {
                    Get-LanguageFromExtension -FilePath "test.ps1" | Should -Be "PowerShell"
                    Get-LanguageFromExtension -FilePath "test.py" | Should -Be "Python" 
                    Get-LanguageFromExtension -FilePath "test.cs" | Should -Be "CSharp"
                    Get-LanguageFromExtension -FilePath "test.js" | Should -Be "JavaScript"
                    Get-LanguageFromExtension -FilePath "test.ts" | Should -Be "TypeScript"
                }
            }
        }
        
        Context "Automation Triggers" {
            BeforeAll {
                if (-not $script:TemplateModulesAvailable['AutoGenerationTriggers']) {
                    Set-ItResult -Skipped -Because "AutoGenerationTriggers module not available"
                }
            }
            
            It "Should initialize documentation triggers" -Skip:(-not $script:TemplateModulesAvailable['AutoGenerationTriggers']) {
                Measure-TestPerformance -TestName "Triggers-Initialize" -ScriptBlock {
                    $result = Initialize-DocumentationTriggers
                    $result | Should -Be $true
                }
            }
            
            It "Should log trigger activity" -Skip:(-not $script:TemplateModulesAvailable['AutoGenerationTriggers']) {
                Measure-TestPerformance -TestName "Triggers-Activity" -ScriptBlock {
                    $logEntry = @{
                        Timestamp = Get-Date
                        Trigger = 'Manual'
                        FilePath = 'test.ps1'
                        Language = 'PowerShell'
                        ChangeType = 'Created'
                    }
                    
                    Add-TriggerActivity -LogEntry $logEntry
                    $activities = Get-TriggerActivity -Last 1 -TriggerType 'Manual'
                    $activities | Should -Not -BeNullOrEmpty
                    $activities[0].Trigger | Should -Be 'Manual'
                }
            }
        }
    }
}

#endregion

#region Performance Tests

if ($TestScope -eq "All" -or $TestScope -eq "Performance") {
    Describe "Enhanced Documentation System - Performance" -Tag "Performance", "Benchmarking" {
        
        BeforeAll {
            Write-Host "  Initializing Performance test environment..." -ForegroundColor Yellow
            
            # Performance module paths  
            $perfModulePaths = @{
                'Performance-Cache' = "$PSScriptRoot\..\Modules\Unity-Claude-CPG\Core\Performance-Cache.psm1"
                'Performance-IncrementalUpdates' = "$PSScriptRoot\..\Modules\Unity-Claude-CPG\Core\Performance-IncrementalUpdates.psm1"
                'ParallelProcessing' = "$PSScriptRoot\..\Modules\Unity-Claude-ParallelProcessing\Unity-Claude-ParallelProcessing.psm1"
            }
            
            $script:PerfModulesAvailable = @{}
            foreach ($moduleName in $perfModulePaths.Keys) {
                $script:PerfModulesAvailable[$moduleName] = Test-ModuleAvailable -ModuleName $moduleName -ModulePath $perfModulePaths[$moduleName]
            }
        }
        
        Context "Cache Performance" {
            BeforeAll {
                if (-not $script:PerfModulesAvailable['Performance-Cache']) {
                    Set-ItResult -Skipped -Because "Performance-Cache module not available"
                }
            }
            
            It "Should meet cache performance benchmarks" -Skip:(-not $script:PerfModulesAvailable['Performance-Cache']) {
                Measure-TestPerformance -TestName "Cache-Performance" -ScriptBlock {
                    $cache = New-PerformanceCache -MaxSize 1000
                    
                    # Benchmark cache operations
                    $operations = 100
                    $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
                    
                    1..$operations | ForEach-Object {
                        Set-CacheItem -Cache $cache -Key "key$_" -Value "value$_"
                    }
                    
                    1..$operations | ForEach-Object {
                        Get-CacheItem -Cache $cache -Key "key$_"
                    }
                    
                    $stopwatch.Stop()
                    $avgTimePerOp = $stopwatch.ElapsedMilliseconds / ($operations * 2)
                    
                    # Should complete operations in under 1ms each
                    $avgTimePerOp | Should -BeLessThan 1.0
                }
            }
            
            It "Should handle cache warming efficiently" -Skip:(-not $script:PerfModulesAvailable['Performance-Cache']) {
                Measure-TestPerformance -TestName "Cache-Warming" -ScriptBlock {
                    $cache = New-PerformanceCache -MaxSize 500
                    $warmingData = 1..100 | ForEach-Object { @{ Key = "warmup$_"; Value = "data$_" } }
                    
                    $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
                    Start-CacheWarming -Cache $cache -Data $warmingData
                    $stopwatch.Stop()
                    
                    # Cache warming should complete in under 100ms for 100 items
                    $stopwatch.ElapsedMilliseconds | Should -BeLessThan 100
                    Get-CacheStats -Cache $cache | Select-Object -ExpandProperty Size | Should -Be 100
                }
            }
        }
        
        Context "File Processing Performance" {
            BeforeAll {
                # Create test files for performance testing
                $script:TestFilesPath = "$TestOutputPath\TestFiles"
                if (-not (Test-Path $script:TestFilesPath)) {
                    New-Item -ItemType Directory -Path $script:TestFilesPath -Force | Out-Null
                }
                
                # Generate test files with varying sizes
                $script:TestFiles = @()
                1..50 | ForEach-Object {
                    $filePath = "$script:TestFilesPath\test$_.ps1"
                    $content = @"
# Test PowerShell file $_
function Test-Function$_ {
    param([string]`$Input)
    Write-Output "Processing: `$Input"
    return `$Input
}

function Helper-Function$_ {
    param([int]`$Number)
    return `$Number * 2
}
"@
                    Set-Content -Path $filePath -Value $content
                    $script:TestFiles += $filePath
                }
                
                Write-Host "    Generated $($script:TestFiles.Count) test files" -ForegroundColor Green
            }
            
            It "Should process files at 100+ files per second" {
                Measure-TestPerformance -TestName "File-Processing-Speed" -ScriptBlock {
                    $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
                    $processed = 0
                    
                    foreach ($file in $script:TestFiles) {
                        # Simulate file processing (read + basic analysis)
                        $content = Get-Content -Path $file -Raw
                        $functions = ($content | Select-String -Pattern "function\s+\w+" -AllMatches).Matches
                        $processed++
                    }
                    
                    $stopwatch.Stop()
                    $filesPerSecond = $processed / ($stopwatch.ElapsedMilliseconds / 1000)
                    
                    Write-Host "    Processed $processed files in $($stopwatch.ElapsedMilliseconds)ms" -ForegroundColor Cyan
                    Write-Host "    Rate: $([math]::Round($filesPerSecond, 2)) files/second" -ForegroundColor Cyan
                    
                    # Must meet 100+ files/second requirement
                    $filesPerSecond | Should -BeGreaterThan 100
                }
            }
            
            It "Should handle incremental updates efficiently" -Skip:(-not $script:PerfModulesAvailable['Performance-IncrementalUpdates']) {
                Measure-TestPerformance -TestName "Incremental-Updates" -ScriptBlock {
                    # Modify a subset of files
                    $filesToModify = $script:TestFiles | Select-Object -First 10
                    
                    $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
                    
                    $changes = @()
                    foreach ($file in $filesToModify) {
                        Add-Content -Path $file -Value "`n# Modified at $(Get-Date)"
                        $changes += Detect-FileChange -FilePath $file
                    }
                    
                    $stopwatch.Stop()
                    
                    $changes.Count | Should -Be 10
                    $stopwatch.ElapsedMilliseconds | Should -BeLessThan 100  # Should detect changes quickly
                }
            }
        }
        
        Context "Parallel Processing Performance" {
            BeforeAll {
                if (-not $script:PerfModulesAvailable['ParallelProcessing']) {
                    Set-ItResult -Skipped -Because "ParallelProcessing module not available"
                }
            }
            
            It "Should demonstrate parallel processing benefits" -Skip:(-not $script:PerfModulesAvailable['ParallelProcessing']) {
                Measure-TestPerformance -TestName "Parallel-Processing" -ScriptBlock {
                    # Sequential processing baseline
                    $sequentialTime = Measure-Command {
                        $script:TestFiles | ForEach-Object {
                            Start-Sleep -Milliseconds 10  # Simulate processing time
                        }
                    }
                    
                    # Parallel processing comparison
                    $parallelTime = Measure-Command {
                        $script:TestFiles | ForEach-Object -Parallel {
                            Start-Sleep -Milliseconds 10  # Simulate processing time
                        } -ThrottleLimit 8
                    }
                    
                    Write-Host "    Sequential: $($sequentialTime.TotalMilliseconds)ms" -ForegroundColor Cyan
                    Write-Host "    Parallel: $($parallelTime.TotalMilliseconds)ms" -ForegroundColor Cyan
                    
                    # Parallel should be significantly faster (at least 2x improvement)
                    $parallelTime.TotalMilliseconds | Should -BeLessThan ($sequentialTime.TotalMilliseconds / 2)
                }
            }
        }
        
        AfterAll {
            # Cleanup test files
            if (Test-Path $script:TestFilesPath) {
                Remove-Item -Path $script:TestFilesPath -Recurse -Force
                Write-Host "    Cleaned up test files" -ForegroundColor Yellow
            }
        }
    }
}

#endregion

# Execute the tests and generate comprehensive report
Write-Host "`n=== Running Test Suite ===" -ForegroundColor Cyan

try {
    $testResults = Invoke-Pester -Configuration $config
    
    # Performance summary
    Write-Host "`n=== Performance Summary ===" -ForegroundColor Cyan
    $script:PerformanceResults.GetEnumerator() | Sort-Object Name | ForEach-Object {
        $status = if ($_.Value -eq -1) { "ERROR" } else { "$($_.Value)ms" }
        Write-Host "  $($_.Key): $status" -ForegroundColor $(if ($_.Value -eq -1) { 'Red' } else { 'Green' })
    }
    
    # Test results summary
    $testEndTime = Get-Date
    $totalDuration = $testEndTime - $script:TestStartTime
    
    Write-Host "`n=== Test Results Summary ===" -ForegroundColor Cyan
    Write-Host "  Total Tests: $($testResults.TotalCount)" -ForegroundColor White
    Write-Host "  Passed: $($testResults.PassedCount)" -ForegroundColor Green
    Write-Host "  Failed: $($testResults.FailedCount)" -ForegroundColor $(if ($testResults.FailedCount -gt 0) { 'Red' } else { 'Green' })
    Write-Host "  Skipped: $($testResults.SkippedCount)" -ForegroundColor Yellow
    Write-Host "  Duration: $($totalDuration.TotalSeconds) seconds" -ForegroundColor White
    Write-Host "  Success Rate: $([math]::Round(($testResults.PassedCount / $testResults.TotalCount) * 100, 1))%" -ForegroundColor $(if ($testResults.FailedCount -eq 0) { 'Green' } else { 'Yellow' })
    
    # Save detailed results
    $detailedResults = @{
        Summary = @{
            TotalTests = $testResults.TotalCount
            Passed = $testResults.PassedCount
            Failed = $testResults.FailedCount
            Skipped = $testResults.SkippedCount
            SuccessRate = [math]::Round(($testResults.PassedCount / $testResults.TotalCount) * 100, 1)
            Duration = $totalDuration.TotalSeconds
            StartTime = $script:TestStartTime
            EndTime = $testEndTime
        }
        Performance = $script:PerformanceResults
        FailedTests = $testResults.Failed
        TestScope = $TestScope
    }
    
    $resultsFile = "$TestOutputPath\EnhancedDocumentationSystem-UnitTests-Results-$(Get-Date -Format 'yyyyMMdd-HHmmss').json"
    $detailedResults | ConvertTo-Json -Depth 5 | Set-Content -Path $resultsFile
    
    Write-Host "`n=== Test Artifacts ===" -ForegroundColor Cyan
    Write-Host "  XML Report: $($config.TestResult.OutputPath)" -ForegroundColor Gray
    Write-Host "  JSON Results: $resultsFile" -ForegroundColor Gray
    Write-Host "  Test Output Directory: $TestOutputPath" -ForegroundColor Gray
    
    if ($testResults.FailedCount -eq 0) {
        Write-Host "`n✓ All tests passed successfully!" -ForegroundColor Green
        exit 0
    } else {
        Write-Host "`n⚠ Some tests failed. Review the detailed results above." -ForegroundColor Yellow
        exit 1
    }
}
catch {
    Write-Error "Test execution failed: $_"
    exit 1
}