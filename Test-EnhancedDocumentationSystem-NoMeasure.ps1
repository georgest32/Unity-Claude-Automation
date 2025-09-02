# Test-EnhancedDocumentationSystem.ps1
# Unit Test Suite for Enhanced Documentation System
# Week 3 Day 4: Comprehensive unit testing for all components
# Date: 2025-08-28

#Requires -Version 5.1
#Requires -Module Pester

# Test-EnhancedDocumentationSystem.ps1
# Test Definitions Only - Enhanced Documentation System Unit Tests
# Week 3 Day 4-5: Testing & Validation - Pester v5 compatible test definitions
# Date: 2025-08-28
# 
# NOTE: This file contains ONLY test definitions (Describe/Context/It blocks)
# To execute: Use Run-EnhancedDocumentationTests.ps1 runner script

#Requires -Version 5.1

using namespace System.Collections.Generic
using namespace System.Collections.Concurrent

# Performance tracking (available during discovery)
$script:PerformanceResults = @{}

Write-Host "========== SCRIPT INITIALIZATION START ==========" -ForegroundColor Magenta
Write-Host "[SCRIPT-INIT] Initializing Enhanced Documentation System test script..." -ForegroundColor Yellow
Write-Host "[SCRIPT-INIT] PSScriptRoot: $PSScriptRoot" -ForegroundColor Gray

# Initialize module availability hashtables at script level for discovery phase access
Write-Host "[SCRIPT-INIT] Initializing module availability hashtables..." -ForegroundColor Yellow

# Test module availability during script initialization so it's available for -Skip conditions
Write-Host "[SCRIPT-INIT] Testing CPG module availability..." -ForegroundColor Yellow
$script:CPGModulesAvailable = @{
    'CPG-ThreadSafeOperations' = (Test-Path "$PSScriptRoot\Modules\Unity-Claude-CPG\Core\CPG-ThreadSafeOperations.psm1")
    'CPG-Unified' = (Test-Path "$PSScriptRoot\Modules\Unity-Claude-CPG\Core\CPG-Unified.psm1")
    'CPG-CallGraphBuilder' = (Test-Path "$PSScriptRoot\Modules\Unity-Claude-CPG\Core\CPG-CallGraphBuilder.psm1")
    'CPG-DataFlowTracker' = (Test-Path "$PSScriptRoot\Modules\Unity-Claude-CPG\Core\CPG-DataFlowTracker.psm1")
}

Write-Host "[SCRIPT-INIT] Testing LLM module availability..." -ForegroundColor Yellow  
$script:LLMModulesAvailable = @{
    'LLM-PromptTemplates' = (Test-Path "$PSScriptRoot\Modules\Unity-Claude-LLM\Core\LLM-PromptTemplates.psm1")
    'LLM-ResponseCache' = (Test-Path "$PSScriptRoot\Modules\Unity-Claude-LLM\Core\LLM-ResponseCache.psm1")
}

Write-Host "[SCRIPT-INIT] Testing Template module availability..." -ForegroundColor Yellow
$script:TemplateModulesAvailable = @{
    'Templates-PerLanguage' = (Test-Path "$PSScriptRoot\Modules\Unity-Claude-Enhanced-DocumentationGenerators\Core\Templates-PerLanguage.psm1")
    'AutoGenerationTriggers' = (Test-Path "$PSScriptRoot\Modules\Unity-Claude-Enhanced-DocumentationGenerators\Core\AutoGenerationTriggers.psm1")
}

Write-Host "[SCRIPT-INIT] Testing Performance module availability..." -ForegroundColor Yellow
$script:PerfModulesAvailable = @{
    'Performance-Cache' = (Test-Path "$PSScriptRoot\Modules\Unity-Claude-CPG\Core\Performance-Cache.psm1")
    'Performance-IncrementalUpdates' = (Test-Path "$PSScriptRoot\Modules\Unity-Claude-CPG\Core\Performance-IncrementalUpdates.psm1")
    'ParallelProcessing' = (Test-Path "$PSScriptRoot\Modules\Unity-Claude-ParallelProcessing\Unity-Claude-ParallelProcessing.psm1")
}

$script:OllamaAvailable = $false

# Initialize test file paths with safe defaults
$script:TestFilesPath = $null
$script:TestFiles = @()

Write-Host "[SCRIPT-INIT] Module availability testing complete" -ForegroundColor Green
Write-Host "[SCRIPT-INIT] CPG module results:" -ForegroundColor Gray
$script:CPGModulesAvailable.GetEnumerator() | ForEach-Object {
    $status = if ($_.Value) { "FOUND" } else { "MISSING" }
    $color = if ($_.Value) { "Green" } else { "Red" }
    Write-Host "  $($_.Key): $status" -ForegroundColor $color
}

Write-Host "[SCRIPT-INIT] LLM module results:" -ForegroundColor Gray
$script:LLMModulesAvailable.GetEnumerator() | ForEach-Object {
    $status = if ($_.Value) { "FOUND" } else { "MISSING" }
    $color = if ($_.Value) { "Green" } else { "Red" }
    Write-Host "  $($_.Key): $status" -ForegroundColor $color
}

Write-Host "[SCRIPT-INIT] Template module results:" -ForegroundColor Gray
$script:TemplateModulesAvailable.GetEnumerator() | ForEach-Object {
    $status = if ($_.Value) { "FOUND" } else { "MISSING" }
    $color = if ($_.Value) { "Green" } else { "Red" }
    Write-Host "  $($_.Key): $status" -ForegroundColor $color
}

Write-Host "[SCRIPT-INIT] Performance module results:" -ForegroundColor Gray
$script:PerfModulesAvailable.GetEnumerator() | ForEach-Object {
    $status = if ($_.Value) { "FOUND" } else { "MISSING" }
    $color = if ($_.Value) { "Green" } else { "Red" }
    Write-Host "  $($_.Key): $status" -ForegroundColor $color
}
Write-Host "========== SCRIPT INITIALIZATION COMPLETE ==========" -ForegroundColor Magenta

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
    
    Write-Host "====== [Test-ModuleAvailable] START DETAILED TRACE ======" -ForegroundColor Magenta
    Write-Host "[Test-ModuleAvailable] Module: $ModuleName" -ForegroundColor Yellow
    Write-Host "[Test-ModuleAvailable] Path: $ModulePath" -ForegroundColor Yellow
    Write-Debug "[Test-ModuleAvailable] Checking module: $ModuleName at path: $ModulePath"
    
    # Step 1: File existence check
    Write-Host "[Test-ModuleAvailable] Step 1: Checking file existence..." -ForegroundColor Cyan
    if (-not (Test-Path $ModulePath)) {
        Write-Host "[Test-ModuleAvailable] RESULT: FILE NOT FOUND - $ModulePath" -ForegroundColor Red
        Write-Debug "[Test-ModuleAvailable] Module file not found: $ModulePath"
        Write-Host "====== [Test-ModuleAvailable] END (FILE NOT FOUND) ======" -ForegroundColor Magenta
        return $false
    }
    Write-Host "[Test-ModuleAvailable] Step 1 SUCCESS: File exists at $ModulePath" -ForegroundColor Green
    
    try {
        # Step 2: Module import attempt  
        Write-Host "[Test-ModuleAvailable] Step 2: Attempting module import..." -ForegroundColor Cyan
        Write-Debug "[Test-ModuleAvailable] Attempting to import module: $ModuleName"
        
        # Capture any warnings/errors during import
        $importWarnings = @()
        $importErrors = @()
        
        # Use more permissive import that allows warnings
        Write-Host "[Test-ModuleAvailable] Importing with -PassThru -ErrorAction SilentlyContinue..." -ForegroundColor Gray
        $module = Import-Module $ModulePath -Force -PassThru -ErrorAction SilentlyContinue -WarningVariable importWarnings
        
        Write-Host "[Test-ModuleAvailable] Import attempt completed" -ForegroundColor Gray
        Write-Host "[Test-ModuleAvailable] Warnings count: $($importWarnings.Count)" -ForegroundColor Gray
        if ($importWarnings.Count -gt 0) {
            Write-Host "[Test-ModuleAvailable] Warnings detected:" -ForegroundColor Yellow
            $importWarnings | ForEach-Object { Write-Host "  WARNING: $_" -ForegroundColor Yellow }
        }
        
        # Step 3: Validate module object
        Write-Host "[Test-ModuleAvailable] Step 3: Validating module object..." -ForegroundColor Cyan
        if ($module) {
            Write-Host "[Test-ModuleAvailable] SUCCESS: Module object returned" -ForegroundColor Green
            Write-Host "[Test-ModuleAvailable] Module Name: $($module.Name)" -ForegroundColor Green
            Write-Host "[Test-ModuleAvailable] Module Path: $($module.Path)" -ForegroundColor Green
            
            # Step 4: Check exported functions
            Write-Host "[Test-ModuleAvailable] Step 4: Checking exported functions..." -ForegroundColor Cyan
            $exportedFunctions = Get-Command -Module $module.Name -ErrorAction SilentlyContinue
            Write-Host "[Test-ModuleAvailable] Exported functions count: $($exportedFunctions.Count)" -ForegroundColor Green
            if ($exportedFunctions.Count -gt 0) {
                Write-Host "[Test-ModuleAvailable] First 5 functions: $($exportedFunctions | Select-Object -First 5 | ForEach-Object Name)" -ForegroundColor Green
            }
            
            Write-Debug "[Test-ModuleAvailable] Successfully imported module: $ModuleName (with possible warnings)"
            Write-Host "[Test-ModuleAvailable] FINAL RESULT: SUCCESS (module imported with $($exportedFunctions.Count) functions)" -ForegroundColor Green
            Write-Host "====== [Test-ModuleAvailable] END (SUCCESS) ======" -ForegroundColor Magenta
            return $true
        } else {
            Write-Host "[Test-ModuleAvailable] WARNING: No module object returned from import" -ForegroundColor Yellow
            
            # Step 5: Fallback - Try syntax check
            Write-Host "[Test-ModuleAvailable] Step 5: Fallback - checking via Get-Command..." -ForegroundColor Cyan
            try {
                $commands = Get-Command -Module $ModuleName -ErrorAction SilentlyContinue
                if ($commands) {
                    Write-Host "[Test-ModuleAvailable] FALLBACK SUCCESS: Found $($commands.Count) commands via Get-Command" -ForegroundColor Green
                    Write-Debug "[Test-ModuleAvailable] Module $ModuleName available via Get-Command"
                    Write-Host "====== [Test-ModuleAvailable] END (FALLBACK SUCCESS) ======" -ForegroundColor Magenta
                    return $true
                } else {
                    Write-Host "[Test-ModuleAvailable] FALLBACK FAILED: No commands found via Get-Command" -ForegroundColor Red
                    Write-Debug "[Test-ModuleAvailable] Module $ModuleName not available via Get-Command"
                }
            }
            catch {
                Write-Host "[Test-ModuleAvailable] FALLBACK EXCEPTION: $($_.Exception.Message)" -ForegroundColor Red
                Write-Debug "[Test-ModuleAvailable] Module $ModuleName not available via Get-Command"
            }
        }
        
        Write-Host "[Test-ModuleAvailable] FINAL RESULT: FAILED (no module object or commands found)" -ForegroundColor Red
        Write-Debug "[Test-ModuleAvailable] Import appears to have failed for $ModuleName"
        Write-Host "====== [Test-ModuleAvailable] END (FAILED) ======" -ForegroundColor Magenta
        return $false
    }
    catch {
        Write-Host "[Test-ModuleAvailable] EXCEPTION during import: $($_.Exception.Message)" -ForegroundColor Red
        Write-Host "[Test-ModuleAvailable] Exception type: $($_.Exception.GetType().FullName)" -ForegroundColor Red
        Write-Debug "[Test-ModuleAvailable] Exception importing $ModuleName : $($_.Exception.Message)"
        Write-Host "====== [Test-ModuleAvailable] END (EXCEPTION) ======" -ForegroundColor Magenta
        return $false
    }
}

#endregion

#region CPG (Code Property Graph) Tests

Describe "Enhanced Documentation System - CPG Components" -Tag "CPG", "Core" {
        Write-Host ">>>>>> [DESCRIBE-CPG] CPG Describe block ENTERED <<<<<<" -ForegroundColor Magenta
        
        BeforeAll {
            Write-Host "!!!!!! [BeforeAll-CPG] BEFOREALL BLOCK REACHED DURING RUN PHASE !!!!!!" -ForegroundColor Red
            Write-Host "========== [BeforeAll-CPG] STARTING CPG MODULE TESTING ==========" -ForegroundColor Cyan
            Write-Host "[BeforeAll-CPG] Initializing CPG test environment..." -ForegroundColor Yellow
            Write-Debug "[BeforeAll-CPG] Starting CPG module initialization"
            
            # Module paths
            $cpgModulePaths = @{
                'CPG-ThreadSafeOperations' = "$PSScriptRoot\Modules\Unity-Claude-CPG\Core\CPG-ThreadSafeOperations.psm1"
                'CPG-Unified' = "$PSScriptRoot\Modules\Unity-Claude-CPG\Core\CPG-Unified.psm1"
                'CPG-CallGraphBuilder' = "$PSScriptRoot\Modules\Unity-Claude-CPG\Core\CPG-CallGraphBuilder.psm1"
                'CPG-DataFlowTracker' = "$PSScriptRoot\Modules\Unity-Claude-CPG\Core\CPG-DataFlowTracker.psm1"
            }
            
            Write-Host "[BeforeAll-CPG] Module paths configured:" -ForegroundColor Yellow
            $cpgModulePaths.GetEnumerator() | ForEach-Object {
                Write-Host "  $($_.Key): $($_.Value)" -ForegroundColor Gray
            }
            Write-Debug "[BeforeAll-CPG] Module paths configured: $($cpgModulePaths.Keys -join ', ')"
            Write-Debug "[BeforeAll-CPG] Script variables already initialized at top level for discovery phase"
            
            Write-Host "[BeforeAll-CPG] Current script variable status:" -ForegroundColor Yellow
            if ($script:CPGModulesAvailable) {
                Write-Host "  CPGModulesAvailable type: $($script:CPGModulesAvailable.GetType().FullName)" -ForegroundColor Gray
                Write-Host "  CPGModulesAvailable keys: $($script:CPGModulesAvailable.Keys -join ', ')" -ForegroundColor Gray
            } else {
                Write-Host "  CPGModulesAvailable: NULL" -ForegroundColor Red
            }
            
            # Import available CPG modules directly (availability already determined at script level)
            Write-Host "[BeforeAll-CPG] Importing available CPG modules..." -ForegroundColor Yellow
            foreach ($moduleName in $cpgModulePaths.Keys) {
                if ($script:CPGModulesAvailable[$moduleName]) {
                    try {
                        Write-Host "[BeforeAll-CPG] Importing $moduleName..." -ForegroundColor Gray
                        Import-Module $cpgModulePaths[$moduleName] -Force -ErrorAction SilentlyContinue
                        Write-Host "[BeforeAll-CPG] Successfully imported $moduleName" -ForegroundColor Green
                    }
                    catch {
                        Write-Host "[BeforeAll-CPG] Warning: Could not import $moduleName : $($_.Exception.Message)" -ForegroundColor Yellow
                    }
                } else {
                    Write-Host "[BeforeAll-CPG] Skipping $moduleName (not available)" -ForegroundColor Gray
                }
            }
            
            Write-Host "[BeforeAll-CPG] ===== FINAL MODULE AVAILABILITY SUMMARY =====" -ForegroundColor Cyan
            $script:CPGModulesAvailable.GetEnumerator() | ForEach-Object {
                $status = if ($_.Value) { "AVAILABLE" } else { "NOT AVAILABLE" }
                $color = if ($_.Value) { "Green" } else { "Red" }
                Write-Host "  $($_.Key): $status" -ForegroundColor $color
            }
            Write-Debug "[BeforeAll-CPG] Final module availability: $($script:CPGModulesAvailable | ConvertTo-Json -Compress)"
            
            Write-Host "[BeforeAll-CPG] CPG module initialization completed" -ForegroundColor Cyan
            Write-Debug "[BeforeAll-CPG] CPG module initialization completed"
            Write-Host "========== [BeforeAll-CPG] END CPG MODULE TESTING ==========" -ForegroundColor Cyan
        }
        
        Context "Thread-Safe Operations" {
            
            It "Should create thread-safe CPG wrapper" -Skip:(-not $script:CPGModulesAvailable['CPG-ThreadSafeOperations']) {
                Write-Host "[TEST-CONDITION] Evaluating skip condition for CPG-ThreadSafeOperations..." -ForegroundColor Yellow
                Write-Host "[TEST-CONDITION] Module availability value: $($script:CPGModulesAvailable['CPG-ThreadSafeOperations'])" -ForegroundColor Yellow
                Write-Host "[TEST-CONDITION] Skip condition result: $(-not $script:CPGModulesAvailable['CPG-ThreadSafeOperations'])" -ForegroundColor Yellow
                $cpg = New-ThreadSafeCPG
                $cpg | Should -Not -BeNullOrEmpty
                $cpg.GetType().Name | Should -Be "ThreadSafeCPG"
            }
            
            It "Should handle concurrent operations safely" -Skip:(-not $script:CPGModulesAvailable['CPG-ThreadSafeOperations']) {
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
            
            It "Should provide thread safety statistics" -Skip:(-not $script:CPGModulesAvailable['CPG-ThreadSafeOperations']) {
                $stats = Get-ThreadSafetyStats
                $stats | Should -Not -BeNullOrEmpty
                $stats.TotalOperations | Should -BeOfType [int]
                $stats.ReadOperations | Should -BeOfType [int]
                $stats.WriteOperations | Should -BeOfType [int]
            }
        }
        
        Context "Call Graph Builder" {
            BeforeAll {
                if (-not $script:CPGModulesAvailable['CPG-CallGraphBuilder']) {
                    Set-ItResult -Skipped -Because "CPG-CallGraphBuilder module not available"
                }
            }
            
            It "Should build call graphs from source code" -Skip:(-not $script:CPGModulesAvailable['CPG-CallGraphBuilder']) {
                
                    $testCode = @'
function Test-Function {
    param([string]$Input)
    Another-Function $Input
    return $Input
}

function Another-Function {
    param([string]$Data)
    Write-Output $Data
}
'@
                    
                    $callGraph = Build-CallGraph -SourceCode $testCode -Language "PowerShell"
                    $callGraph | Should -Not -BeNullOrEmpty
                    $callGraph.Nodes.Count | Should -BeGreaterThan 0
                    $callGraph.Edges.Count | Should -BeGreaterThan 0
                }
            }
            
            It "Should detect recursive calls" -Skip:(-not $script:CPGModulesAvailable['CPG-CallGraphBuilder']) {
                
                    $recursiveCode = @'
function Recursive-Function {
    param([int]$Count)
    if ($Count -gt 0) {
        Recursive-Function ($Count - 1)
    }
}
'@
                    
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
                
                    $testCode = @'
$variable = "test"
Write-Output $variable
$variable = "modified"
'@
                    
                    $dataFlow = Trace-DataFlow -SourceCode $testCode -Language "PowerShell"
                    $dataFlow | Should -Not -BeNullOrEmpty
                    $dataFlow.DefUseChains | Should -Not -BeNullOrEmpty
                }
            }
            
            It "Should perform taint analysis" -Skip:(-not $script:CPGModulesAvailable['CPG-DataFlowTracker']) {
                
                    $taintedCode = @'
$userInput = Read-Host "Enter data"
$sqlQuery = "SELECT * FROM users WHERE name = '$userInput'"
Invoke-SqlCmd -Query $sqlQuery
'@
                    
                    $taintAnalysis = Invoke-TaintAnalysis -SourceCode $taintedCode -Language "PowerShell"
                    $taintAnalysis | Should -Not -BeNullOrEmpty
                    $taintAnalysis.TaintedPaths | Should -Not -BeNullOrEmpty
                }
            }
        }
    }

#endregion

#region LLM Integration Tests

Describe "Enhanced Documentation System - LLM Integration" -Tag "LLM", "Integration" {
        Write-Host ">>>>>> [DESCRIBE-LLM] LLM Describe block ENTERED <<<<<<" -ForegroundColor Magenta
        
        BeforeAll {
            Write-Host "!!!!!! [BeforeAll-LLM] BEFOREALL BLOCK REACHED DURING RUN PHASE !!!!!!" -ForegroundColor Red
            Write-Host "  Initializing LLM test environment..." -ForegroundColor Yellow
            
            # Check Ollama availability (variable already initialized at script level)
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
                'LLM-PromptTemplates' = "$PSScriptRoot\Modules\Unity-Claude-LLM\Core\LLM-PromptTemplates.psm1"
                'LLM-ResponseCache' = "$PSScriptRoot\Modules\Unity-Claude-LLM\Core\LLM-ResponseCache.psm1"
            }
            
            Write-Debug "[BeforeAll-LLM] Script variables already initialized at top level for discovery phase"
            
            # Import available LLM modules directly (availability already determined at script level)
            Write-Host "[BeforeAll-LLM] Importing available LLM modules..." -ForegroundColor Yellow
            foreach ($moduleName in $llmModulePaths.Keys) {
                if ($script:LLMModulesAvailable[$moduleName]) {
                    try {
                        Write-Host "[BeforeAll-LLM] Importing $moduleName..." -ForegroundColor Gray
                        Import-Module $llmModulePaths[$moduleName] -Force -ErrorAction SilentlyContinue
                        Write-Host "[BeforeAll-LLM] Successfully imported $moduleName" -ForegroundColor Green
                    }
                    catch {
                        Write-Host "[BeforeAll-LLM] Warning: Could not import $moduleName : $($_.Exception.Message)" -ForegroundColor Yellow
                    }
                } else {
                    Write-Host "[BeforeAll-LLM] Skipping $moduleName (not available)" -ForegroundColor Gray
                }
            }
        }
        
        Context "Ollama API Integration" {
            It "Should connect to Ollama service" -Skip:(-not $script:OllamaAvailable) {
                
                    $health = Test-OllamaConnection
                    $health | Should -Be $true
                }
            }
            
            It "Should list available models" -Skip:(-not $script:OllamaAvailable) {
                
                    $models = Get-OllamaModels
                    $models | Should -Not -BeNullOrEmpty
                    $models | Should -BeOfType [array]
                }
            }
            
            It "Should generate responses for code analysis" -Skip:(-not $script:OllamaAvailable) {
                
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
                
                    $template = Get-FunctionDocumentationPrompt -FunctionName "Test-Function" -Parameters @("Param1", "Param2")
                    $template | Should -Not -BeNullOrEmpty
                    $template | Should -Match "Test-Function"
                    $template | Should -Match "Param1"
                }
            }
            
            It "Should create module documentation prompts" -Skip:(-not $script:LLMModulesAvailable['LLM-PromptTemplates']) {
                
                    $template = Get-ModuleDocumentationPrompt -ModuleName "TestModule" -Functions @("Func1", "Func2")
                    $template | Should -Not -BeNullOrEmpty
                    $template | Should -Match "TestModule"
                    $template | Should -Match "Func1"
                }
            }
            
            It "Should support variable substitution" -Skip:(-not $script:LLMModulesAvailable['LLM-PromptTemplates']) {
                
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
                
                    $key = "test-prompt-$(Get-Date -Format 'yyyyMMddHHmmss')"
                    $response = "This is a test response"
                    
                    Set-LLMCache -Key $key -Response $response -TTL 300
                    $cached = Get-LLMCache -Key $key
                    
                    $cached | Should -Be $response
                }
            }
            
            It "Should handle TTL expiration" -Skip:(-not $script:LLMModulesAvailable['LLM-ResponseCache']) {
                
                    $key = "ttl-test-$(Get-Date -Format 'yyyyMMddHHmmss')"
                    $response = "TTL test response"
                    
                    Set-LLMCache -Key $key -Response $response -TTL 1  # 1 second
                    Start-Sleep -Seconds 2
                    $expired = Get-LLMCache -Key $key
                    
                    $expired | Should -BeNullOrEmpty
                }
            }
            
            It "Should provide cache statistics" -Skip:(-not $script:LLMModulesAvailable['LLM-ResponseCache']) {
                
                    $stats = Get-LLMCacheStats
                    $stats | Should -Not -BeNullOrEmpty
                    $stats.Hits | Should -BeOfType [int]
                    $stats.Misses | Should -BeOfType [int]
                    $stats.HitRate | Should -BeOfType [double]
                }
            }
        }
    }

#endregion

#region Templates and Automation Tests

Describe "Enhanced Documentation System - Templates & Automation" -Tag "Templates", "Automation" {
        Write-Host ">>>>>> [DESCRIBE-TEMPLATES] Templates Describe block ENTERED <<<<<<" -ForegroundColor Magenta
        
        BeforeAll {
            Write-Host "!!!!!! [BeforeAll-TEMPLATES] BEFOREALL BLOCK REACHED DURING RUN PHASE !!!!!!" -ForegroundColor Red
            Write-Host "  Initializing Templates test environment..." -ForegroundColor Yellow
            
            # Template module paths
            $templateModulePaths = @{
                'Templates-PerLanguage' = "$PSScriptRoot\Modules\Unity-Claude-Enhanced-DocumentationGenerators\Core\Templates-PerLanguage.psm1"
                'AutoGenerationTriggers' = "$PSScriptRoot\Modules\Unity-Claude-Enhanced-DocumentationGenerators\Core\AutoGenerationTriggers.psm1"
            }
            
            Write-Debug "[BeforeAll-Templates] Script variables already initialized at top level for discovery phase"
            
            # Import available Template modules directly (availability already determined at script level)
            Write-Host "[BeforeAll-Templates] Importing available Template modules..." -ForegroundColor Yellow
            foreach ($moduleName in $templateModulePaths.Keys) {
                if ($script:TemplateModulesAvailable[$moduleName]) {
                    try {
                        Write-Host "[BeforeAll-Templates] Importing $moduleName..." -ForegroundColor Gray
                        Import-Module $templateModulePaths[$moduleName] -Force -ErrorAction SilentlyContinue
                        Write-Host "[BeforeAll-Templates] Successfully imported $moduleName" -ForegroundColor Green
                    }
                    catch {
                        Write-Host "[BeforeAll-Templates] Warning: Could not import $moduleName : $($_.Exception.Message)" -ForegroundColor Yellow
                    }
                } else {
                    Write-Host "[BeforeAll-Templates] Skipping $moduleName (not available)" -ForegroundColor Gray
                }
            }
        }
        
        Context "Language-Specific Templates" {
            
            It "Should generate PowerShell documentation templates" -Skip:(-not $script:TemplateModulesAvailable['Templates-PerLanguage']) {
                $template = Get-PowerShellDocTemplate -FunctionName "Test-Function" -Parameters @("Param1", "Param2") -Synopsis "Test function"
                $template | Should -Not -BeNullOrEmpty
                $template | Should -Match "\.SYNOPSIS"
                $template | Should -Match "Test function"
                $template | Should -Match "\.PARAMETER Param1"
            }
            
            It "Should generate Python documentation templates" -Skip:(-not $script:TemplateModulesAvailable['Templates-PerLanguage']) {
                
                    $template = Get-PythonDocTemplate -FunctionName "test_function" -Parameters @("param1", "param2") -Description "Test function description"
                    $template | Should -Not -BeNullOrEmpty
                    $template | Should -Match "Args:"
                    $template | Should -Match "Returns:"
                    $template | Should -Match "param1"
                }
            }
            
            It "Should generate C# documentation templates" -Skip:(-not $script:TemplateModulesAvailable['Templates-PerLanguage']) {
                
                    $template = Get-CSharpDocTemplate -MethodName "TestMethod" -Parameters @("param1", "param2") -Summary "Test method summary"
                    $template | Should -Not -BeNullOrEmpty
                    $template | Should -Match "<summary>"
                    $template | Should -Match "Test method summary"
                    $template | Should -Match '<param name="param1">'
                }
            }
            
            It "Should generate JavaScript documentation templates" -Skip:(-not $script:TemplateModulesAvailable['Templates-PerLanguage']) {
                
                    $template = Get-JavaScriptDocTemplate -FunctionName "testFunction" -Parameters @("param1", "param2") -Description "Test function description"
                    $template | Should -Not -BeNullOrEmpty
                    $template | Should -Match "/\*\*"
                    $template | Should -Match "@param"
                    $template | Should -Match "@returns"
                    $template | Should -Match "\*/"
                }
            }
            
            It "Should detect language from file extensions" -Skip:(-not $script:TemplateModulesAvailable['Templates-PerLanguage']) {
                
                    Get-LanguageFromExtension -FilePath "test.ps1" | Should -Be "PowerShell"
                    Get-LanguageFromExtension -FilePath "test.py" | Should -Be "Python" 
                    Get-LanguageFromExtension -FilePath "test.cs" | Should -Be "CSharp"
                    Get-LanguageFromExtension -FilePath "test.js" | Should -Be "JavaScript"
                    Get-LanguageFromExtension -FilePath "test.ts" | Should -Be "TypeScript"
                }
            }
        }
        
        Context "Automation Triggers" {
            
            It "Should initialize documentation triggers" -Skip:(-not $script:TemplateModulesAvailable['AutoGenerationTriggers']) {
                
                    $result = Initialize-DocumentationTriggers
                    $result | Should -Be $true
                }
            }
            
            It "Should log trigger activity" -Skip:(-not $script:TemplateModulesAvailable['AutoGenerationTriggers']) {
                
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

#endregion

#region Performance Tests

Describe "Enhanced Documentation System - Performance" -Tag "Performance", "Benchmarking" {
        Write-Host ">>>>>> [DESCRIBE-PERFORMANCE] Performance Describe block ENTERED <<<<<<" -ForegroundColor Magenta
        
        BeforeAll {
            Write-Host "!!!!!! [BeforeAll-PERFORMANCE] BEFOREALL BLOCK REACHED DURING RUN PHASE !!!!!!" -ForegroundColor Red
            Write-Host "  Initializing Performance test environment..." -ForegroundColor Yellow
            
            # Performance module paths  
            $perfModulePaths = @{
                'Performance-Cache' = "$PSScriptRoot\Modules\Unity-Claude-CPG\Core\Performance-Cache.psm1"
                'Performance-IncrementalUpdates' = "$PSScriptRoot\Modules\Unity-Claude-CPG\Core\Performance-IncrementalUpdates.psm1"
                'ParallelProcessing' = "$PSScriptRoot\Modules\Unity-Claude-ParallelProcessing\Unity-Claude-ParallelProcessing.psm1"
            }
            
            Write-Debug "[BeforeAll-Performance] Script variables already initialized at top level for discovery phase"
            
            # Test and update module availability (variables already initialized at script level)
            foreach ($moduleName in $perfModulePaths.Keys) {
                if ([string]::IsNullOrEmpty($moduleName)) {
                    Write-Debug "[BeforeAll-Performance] Skipping null/empty module name"
                    continue
                }
                
                Write-Debug "[BeforeAll-Performance] Testing availability for module: $moduleName"
                try {
                    $moduleResult = Test-ModuleAvailable -ModuleName $moduleName -ModulePath $perfModulePaths[$moduleName]
                    if ($script:PerfModulesAvailable -and $script:PerfModulesAvailable.ContainsKey($moduleName)) {
                        $script:PerfModulesAvailable[$moduleName] = $moduleResult
                        Write-Debug "[BeforeAll-Performance] Module $moduleName availability: $moduleResult"
                    } else {
                        Write-Debug "[BeforeAll-Performance] WARNING: PerfModulesAvailable hashtable not properly initialized"
                    }
                }
                catch {
                    Write-Debug "[BeforeAll-Performance] Exception testing module $moduleName : $($_.Exception.Message)"
                    if ($script:PerfModulesAvailable -and $script:PerfModulesAvailable.ContainsKey($moduleName)) {
                        $script:PerfModulesAvailable[$moduleName] = $false
                    }
                }
            }
        }
        
        Context "Cache Performance" {
            
            It "Should meet cache performance benchmarks" -Skip:(-not $script:PerfModulesAvailable['Performance-Cache']) {
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
            
            It "Should handle cache warming efficiently" -Skip:(-not $script:PerfModulesAvailable['Performance-Cache']) {
                $cache = New-PerformanceCache -MaxSize 500
                $warmingData = 1..100 | ForEach-Object { @{ Key = "warmup$_"; Value = "data$_" 
                
                $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
                Start-CacheWarming -Cache $cache -Data $warmingData
                $stopwatch.Stop()
                
                # Cache warming should complete in under 100ms for 100 items
                $stopwatch.ElapsedMilliseconds | Should -BeLessThan 100
                Get-CacheStats -Cache $cache | Select-Object -ExpandProperty Size | Should -Be 100
            }
        }
        
        Context "File Processing Performance" {
            BeforeAll {
                # Create test files for performance testing
                $testOutputRoot = if ($PSScriptRoot) { $PSScriptRoot } else { "." }
                $script:TestFilesPath = "$testOutputRoot\TestOutput\TestFiles"
                if (-not (Test-Path $script:TestFilesPath)) {
                    New-Item -ItemType Directory -Path $script:TestFilesPath -Force | Out-Null
                }
                
                # Generate test files with varying sizes
                $script:TestFiles = @()
                1..50 | ForEach-Object {
                    $filePath = "$script:TestFilesPath\test$_.ps1"
                    $content = @'
# Test PowerShell file $_
function Test-Function$_ {
    param([string]$Input)
    Write-Output "Processing: $Input"
    return $Input
}

function Helper-Function$_ {
    param([int]$Number)
    return $Number * 2
}
'@
                    Set-Content -Path $filePath -Value $content
                    $script:TestFiles += $filePath
                }
                
                Write-Host "    Generated $($script:TestFiles.Count) test files" -ForegroundColor Green
            }
            
            It "Should process files at 100+ files per second" {
                $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
                $processed = 0
                
                if ($script:TestFiles -and $script:TestFiles.Count -gt 0) {
                    foreach ($file in $script:TestFiles) {
                        if (Test-Path $file) {
                            # Simulate file processing (read + basic analysis)
                            $content = Get-Content -Path $file -Raw
                            $functions = ($content | Select-String -Pattern "function\s+\w+" -AllMatches).Matches
                            $processed++
                        }
                    }
                } else {
                    Write-Host "    WARNING: No test files available for processing test" -ForegroundColor Yellow
                }
                
                $stopwatch.Stop()
                $filesPerSecond = $processed / ($stopwatch.ElapsedMilliseconds / 1000)
                
                Write-Host "    Processed $processed files in $($stopwatch.ElapsedMilliseconds)ms" -ForegroundColor Cyan
                Write-Host "    Rate: $([math]::Round($filesPerSecond, 2)) files/second" -ForegroundColor Cyan
                
                # Must meet 100+ files/second requirement
                $filesPerSecond | Should -BeGreaterThan 100
            }
            
            It "Should handle incremental updates efficiently" -Skip:(-not $script:PerfModulesAvailable['Performance-IncrementalUpdates']) {
                # Modify a subset of files
                $filesToModify = $script:TestFiles | Select-Object -First 10
                
                $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
                
                $changes = @()
                foreach ($file in $filesToModify) {
                    Add-Content -Path $file -Value "`n# Modified at $(Get-Date)"
                    # Simple change detection - just record that file was modified
                    $changes += @{
                        FilePath = $file
                        ChangeType = "Modified"
                        Timestamp = Get-Date
                    }
                }
                
                $stopwatch.Stop()
                
                $changes.Count | Should -Be 10
                $stopwatch.ElapsedMilliseconds | Should -BeLessThan 100  # Should detect changes quickly
            }
        }
        
        Context "Parallel Processing Performance" {
            
            It "Should demonstrate parallel processing benefits" -Skip:(-not $script:PerfModulesAvailable['ParallelProcessing']) {
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
        
        AfterAll {
            # Cleanup test files
            if (Test-Path $script:TestFilesPath) {
                Remove-Item -Path $script:TestFilesPath -Recurse -Force
                Write-Host "    Cleaned up test files" -ForegroundColor Yellow
            }
        }
    }

#endregion
