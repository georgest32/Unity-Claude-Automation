# Test-Week3-Day5-EndToEndIntegration-Final.ps1
# FINAL VERSION: Removes function name conflicts, uses only real UnityParallelization functions
# Research-validated solution for Unity project registration persistence
# Date: 2025-08-21

[CmdletBinding()]
param(
    [switch]$SaveResults,
    [switch]$EnableResourceMonitoring,
    [switch]$TestWithRealUnityProjects,
    [switch]$TestWithRealClaudeAPI,
    [string]$TestResultsFile,
    [int]$TestTimeout = 600
)

Write-Host "=== Week 3 Day 5: End-to-End Integration Test (FINAL) ===" -ForegroundColor Cyan
Write-Host "Research-validated module loading WITHOUT function name conflicts" -ForegroundColor White
Write-Host "Date: $(Get-Date -Format 'MM/dd/yyyy HH:mm:ss')" -ForegroundColor White
Write-Host "PowerShell Version: $($PSVersionTable.PSVersion)" -ForegroundColor White
Write-Host ""

# Test configuration
$TestConfig = @{
    TestName = "Week3-Day5-EndToEndIntegration-Final"
    Date = Get-Date
    SaveResults = $SaveResults
    EnableResourceMonitoring = $EnableResourceMonitoring
    TestWithRealUnityProjects = $TestWithRealUnityProjects
    TestWithRealClaudeAPI = $TestWithRealClaudeAPI
    TestTimeout = $TestTimeout
    TestResultsFile = if ($TestResultsFile) { $TestResultsFile } else { 
        "Test_Results_Week3_Day5_EndToEnd_FINAL_$(Get-Date -Format 'yyyyMMdd_HHmmss').txt" 
    }
}

# Initialize test results
$TestResults = @{
    TestName = $TestConfig.TestName
    StartTime = Get-Date
    Tests = @()
    Summary = @{ Total = 0; Passed = 0; Failed = 0; Skipped = 0 }
    Categories = @{}
    EndTime = $null
}

# Enhanced test function with comprehensive logging
function Test-IntegratedWorkflowFunction {
    param(
        [string]$TestName,
        [scriptblock]$TestCode,
        [string]$Category = "General",
        [int]$TimeoutSeconds = 30
    )
    
    $testStart = Get-Date
    $testResult = @{
        Name = $TestName
        Category = $Category
        StartTime = $testStart
        Duration = 0
        Status = "Unknown"
        Result = $false
        Error = $null
    }
    
    Write-Host "[DEBUG] [TestExecution] Starting test: $TestName (Category: $Category)" -ForegroundColor Gray
    
    try {
        Write-Host "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss.fff')] [INFO] [$Category] Starting test: $TestName" -ForegroundColor White
        
        # Execute test with detailed logging
        Write-Host "[DEBUG] [TestExecution] Executing test code for: $TestName" -ForegroundColor Gray
        $result = & $TestCode $TestConfig
        
        $testEnd = Get-Date
        $duration = ($testEnd - $testStart).TotalMilliseconds
        
        if ($result) {
            $testResult.Status = "PASS"
            $testResult.Result = $true
            Write-Host "[PASS] $TestName" -ForegroundColor Green
            Write-Host "    Duration: $([int]$duration)ms" -ForegroundColor Gray
            Write-Host "[DEBUG] [TestExecution] Test passed: $TestName" -ForegroundColor Green
        } else {
            $testResult.Status = "FAIL"
            $testResult.Result = $false
            Write-Host "[FAIL] $TestName" -ForegroundColor Red
            Write-Host "    Duration: $([int]$duration)ms" -ForegroundColor Gray
            Write-Host "[DEBUG] [TestExecution] Test failed: $TestName" -ForegroundColor Red
        }
        
        $testResult.Duration = [int]$duration
        
    } catch {
        $testEnd = Get-Date
        $duration = ($testEnd - $testStart).TotalMilliseconds
        
        $testResult.Status = "FAIL"
        $testResult.Result = $false
        $testResult.Error = $_.Exception.Message
        $testResult.Duration = [int]$duration
        
        Write-Host "[FAIL] $TestName" -ForegroundColor Red
        Write-Host "    Error: $($_.Exception.Message)" -ForegroundColor Red
        Write-Host "    Duration: $([int]$duration)ms" -ForegroundColor Gray
        Write-Host "[DEBUG] [TestExecution] Test error: $TestName - $($_.Exception.Message)" -ForegroundColor Red
    }
    
    # Update category statistics
    if (-not $TestResults.Categories.ContainsKey($Category)) {
        $TestResults.Categories[$Category] = @{ Total = 0; Passed = 0; Failed = 0 }
    }
    
    $TestResults.Categories[$Category].Total++
    if ($testResult.Result) {
        $TestResults.Categories[$Category].Passed++
        $TestResults.Summary.Passed++
    } else {
        $TestResults.Categories[$Category].Failed++
        $TestResults.Summary.Failed++
    }
    
    $TestResults.Summary.Total++
    $TestResults.Tests += $testResult
    
    Write-Host "[DEBUG] [TestExecution] Test completed: $TestName (Result: $($testResult.Status))" -ForegroundColor Gray
    
    return $testResult.Result
}

function Write-TestHeader {
    param([string]$Title)
    Write-Host ""
    Write-Host "=== $Title ===" -ForegroundColor Cyan
}

# Module Loading Sequence (NO MOCK MODULE - Use only real modules)
Write-Host "Importing modules..."
Write-Host "[DEBUG] [ModuleLoading] Starting FINAL module loading sequence WITHOUT function conflicts" -ForegroundColor Gray

# Apply PSModulePath fix for current session
$moduleBasePath = "C:\UnityProjects\Sound-and-Shoal\Unity-Claude-Automation\Modules"
if ($env:PSModulePath -notlike "*$moduleBasePath*") {
    Write-Host "[DEBUG] [ModuleLoading] Adding Modules directory to PSModulePath..." -ForegroundColor Yellow
    $env:PSModulePath = "$moduleBasePath;$($env:PSModulePath)"
    Write-Host "[DEBUG] [ModuleLoading] PSModulePath updated for current session" -ForegroundColor Green
}

# Load modules in dependency order WITHOUT mock conflicts
try {
    Write-Host "[DEBUG] [ModuleLoading] Step 1: Loading base dependency (ParallelProcessing)..." -ForegroundColor Cyan
    Import-Module "$moduleBasePath\Unity-Claude-ParallelProcessing\Unity-Claude-ParallelProcessing.psm1" -Force -Global -ErrorAction Stop
    $parallelCommands = (Get-Command -Module Unity-Claude-ParallelProcessing -ErrorAction SilentlyContinue).Count
    Write-Host "[DEBUG] [ModuleLoading] ParallelProcessing loaded: $parallelCommands functions" -ForegroundColor Green
    
    Write-Host "[DEBUG] [ModuleLoading] Step 2: Loading RunspaceManagement..." -ForegroundColor Cyan
    Import-Module "$moduleBasePath\Unity-Claude-RunspaceManagement\Unity-Claude-RunspaceManagement.psm1" -Force -Global -ErrorAction Stop
    $runspaceCommands = (Get-Command -Module Unity-Claude-RunspaceManagement -ErrorAction SilentlyContinue).Count
    Write-Host "[DEBUG] [ModuleLoading] RunspaceManagement loaded: $runspaceCommands functions" -ForegroundColor Green
    
    Write-Host "[DEBUG] [ModuleLoading] Step 3: Loading UnityParallelization..." -ForegroundColor Cyan
    Import-Module "$moduleBasePath\Unity-Claude-UnityParallelization\Unity-Claude-UnityParallelization.psm1" -Force -Global -ErrorAction Stop
    $unityCommands = (Get-Command -Module Unity-Claude-UnityParallelization -ErrorAction SilentlyContinue).Count
    Write-Host "[DEBUG] [ModuleLoading] UnityParallelization loaded: $unityCommands functions" -ForegroundColor Green
    
    Write-Host "[DEBUG] [ModuleLoading] Step 4: Loading ClaudeParallelization..." -ForegroundColor Cyan
    Import-Module "$moduleBasePath\Unity-Claude-ClaudeParallelization\Unity-Claude-ClaudeParallelization.psm1" -Force -Global -ErrorAction Stop
    $claudeCommands = (Get-Command -Module Unity-Claude-ClaudeParallelization -ErrorAction SilentlyContinue).Count
    Write-Host "[DEBUG] [ModuleLoading] ClaudeParallelization loaded: $claudeCommands functions" -ForegroundColor Green
    
    Write-Host "[DEBUG] [ModuleLoading] Step 5: Loading IntegratedWorkflow..." -ForegroundColor Cyan
    Import-Module "$moduleBasePath\Unity-Claude-IntegratedWorkflow\Unity-Claude-IntegratedWorkflow.psm1" -Force -Global -ErrorAction Stop
    $integratedCommands = (Get-Command -Module Unity-Claude-IntegratedWorkflow -ErrorAction SilentlyContinue).Count
    Write-Host "[DEBUG] [ModuleLoading] IntegratedWorkflow loaded: $integratedCommands functions" -ForegroundColor Green
    
    $totalFunctions = $parallelCommands + $runspaceCommands + $unityCommands + $claudeCommands + $integratedCommands
    Write-Host "[DEBUG] [ModuleLoading] Total functions loaded: $totalFunctions" -ForegroundColor Green
    Write-Host "All modules imported successfully" -ForegroundColor Green
    
} catch {
    Write-Host "ERROR: Module loading failed: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "[DEBUG] [ModuleLoading] Error details: $($_.ScriptStackTrace)" -ForegroundColor Red
    exit 1
}

# Unity Project Setup using ONLY real UnityParallelization functions
Write-Host ""
Write-Host "[DEBUG] [ProjectSetup] Setting up Unity projects using REAL UnityParallelization functions..." -ForegroundColor Yellow

$mockProjectsBasePath = "C:\MockProjects"
$mockProjects = @("Unity-Project-1", "Unity-Project-2", "Unity-Project-3")

# Ensure mock project directories exist
foreach ($projectName in $mockProjects) {
    $projectPath = Join-Path $mockProjectsBasePath $projectName
    
    if (-not (Test-Path $projectPath)) {
        Write-Host "[DEBUG] [ProjectSetup] Creating mock project directory: $projectName" -ForegroundColor Gray
        New-Item -Path $projectPath -ItemType Directory -Force | Out-Null
        New-Item -Path "$projectPath\Assets" -ItemType Directory -Force | Out-Null
        New-Item -Path "$projectPath\ProjectSettings" -ItemType Directory -Force | Out-Null
        
        @"
m_EditorVersion: 2021.1.14f1
m_EditorVersionWithRevision: 2021.1.14f1 (54ba63c7b9e8)
"@ | Set-Content "$projectPath\ProjectSettings\ProjectVersion.txt" -Encoding UTF8
    }
    
    # Register using REAL UnityParallelization module function with explicit qualification
    try {
        Write-Host "[DEBUG] [ProjectSetup] Registering $projectName with REAL UnityParallelization module..." -ForegroundColor Gray
        
        # Use module-qualified function call to ensure we use the REAL function
        $registerCommand = Get-Command Register-UnityProject -Module Unity-Claude-UnityParallelization -ErrorAction Stop
        $registration = & $registerCommand -ProjectPath $projectPath -ProjectName $projectName -MonitoringEnabled
        
        # Test availability using REAL function with explicit module qualification
        $availabilityCommand = Get-Command Test-UnityProjectAvailability -Module Unity-Claude-UnityParallelization -ErrorAction Stop
        $availability = & $availabilityCommand -ProjectName $projectName
        
        Write-Host "[DEBUG] [ProjectSetup] $projectName registration result: Available=$($availability.Available)" -ForegroundColor $(if ($availability.Available) { "Green" } else { "Red" })
        if (-not $availability.Available) {
            Write-Host "[DEBUG] [ProjectSetup] Registration failure reason: $($availability.Reason)" -ForegroundColor Red
        }
        
    } catch {
        Write-Host "[DEBUG] [ProjectSetup] Failed to register $projectName : $($_.Exception.Message)" -ForegroundColor Red
        Write-Host "[DEBUG] [ProjectSetup] Error details: $($_.ScriptStackTrace)" -ForegroundColor Red
    }
}

# Function Availability Validation
Write-Host ""
Write-Host "[DEBUG] [Diagnostics] Validating all critical functions are available..." -ForegroundColor Yellow

$criticalFunctions = @(
    'New-IntegratedWorkflow', 
    'Start-IntegratedWorkflow', 
    'Get-IntegratedWorkflowStatus',
    'Stop-IntegratedWorkflow',
    'Initialize-AdaptiveThrottling',
    'Update-AdaptiveThrottling',
    'New-IntelligentJobBatching',
    'Get-WorkflowPerformanceAnalysis',
    'Test-UnityProjectAvailability',
    'Register-UnityProject'
)

$availableCount = 0
foreach ($func in $criticalFunctions) {
    $exists = Get-Command $func -ErrorAction SilentlyContinue
    if ($exists) {
        $availableCount++
        Write-Host "[DEBUG] [Diagnostics] Function AVAILABLE: $func (Module: $($exists.ModuleName))" -ForegroundColor Green
    } else {
        Write-Host "[DEBUG] [Diagnostics] Function MISSING: $func" -ForegroundColor Red
    }
}

$functionAvailabilityRate = [math]::Round(($availableCount / $criticalFunctions.Count) * 100, 1)
Write-Host "[DEBUG] [Diagnostics] Function Availability: $availableCount/$($criticalFunctions.Count) ($functionAvailabilityRate%)" -ForegroundColor $(if ($functionAvailabilityRate -ge 90) { "Green" } else { "Red" })

# Test execution begins
Write-TestHeader "1. Module Integration Validation"

Test-IntegratedWorkflowFunction "IntegratedWorkflow Functions Available" {
    param($Config)
    
    Write-Host "[DEBUG] [Test] Validating IntegratedWorkflow functions..." -ForegroundColor Gray
    
    try {
        $expectedFunctions = @(
            'New-IntegratedWorkflow',
            'Start-IntegratedWorkflow',
            'Get-IntegratedWorkflowStatus',
            'Stop-IntegratedWorkflow',
            'Initialize-AdaptiveThrottling',
            'Update-AdaptiveThrottling',
            'New-IntelligentJobBatching',
            'Get-WorkflowPerformanceAnalysis'
        )
        
        $missingFunctions = @()
        foreach ($func in $expectedFunctions) {
            $command = Get-Command $func -ErrorAction SilentlyContinue
            if (-not $command) {
                $missingFunctions += $func
                Write-Host "[DEBUG] [Test] Missing function: $func" -ForegroundColor Red
            } else {
                Write-Host "[DEBUG] [Test] Available function: $func (Module: $($command.ModuleName))" -ForegroundColor Green
            }
        }
        
        if ($missingFunctions.Count -eq 0) {
            Write-Host "    All $($expectedFunctions.Count) IntegratedWorkflow functions available" -ForegroundColor Green
            return $true
        } else {
            Write-Host "    Missing functions: $($missingFunctions -join ', ')" -ForegroundColor Red
            return $false
        }
        
    } catch {
        Write-Host "[DEBUG] [Test] Function validation error: $($_.Exception.Message)" -ForegroundColor Red
        Write-Host "    Module import validation error: $($_.Exception.Message)" -ForegroundColor Red
        return $false
    }
} -Category "ModuleLoading"

Test-IntegratedWorkflowFunction "Unity Project Registration Verification" {
    param($Config)
    
    Write-Host "[DEBUG] [Test] Testing Unity project registration state using REAL module functions..." -ForegroundColor Gray
    
    try {
        # Test each project using explicit module-qualified function
        $testProjects = @("Unity-Project-1", "Unity-Project-2", "Unity-Project-3")
        $availableProjects = 0
        
        foreach ($projectName in $testProjects) {
            Write-Host "[DEBUG] [Test] Testing $projectName with REAL UnityParallelization function..." -ForegroundColor Gray
            
            # Use explicit module qualification to ensure we're using the REAL function
            $availabilityCommand = Get-Command Test-UnityProjectAvailability -Module Unity-Claude-UnityParallelization -ErrorAction Stop
            $availability = & $availabilityCommand -ProjectName $projectName
            
            Write-Host "[DEBUG] [Test] $projectName availability result: Available=$($availability.Available)" -ForegroundColor $(if ($availability.Available) { "Green" } else { "Red" })
            if (-not $availability.Available) {
                Write-Host "[DEBUG] [Test] $projectName failure reason: $($availability.Reason)" -ForegroundColor Red
            }
            
            if ($availability.Available) {
                $availableProjects++
            }
        }
        
        if ($availableProjects -eq $testProjects.Count) {
            Write-Host "    All $availableProjects/$($testProjects.Count) Unity projects available for monitoring" -ForegroundColor Green
            return $true
        } else {
            Write-Host "    Only $availableProjects/$($testProjects.Count) Unity projects available" -ForegroundColor Red
            return $false
        }
        
    } catch {
        Write-Host "[DEBUG] [Test] Project verification error: $($_.Exception.Message)" -ForegroundColor Red
        Write-Host "    Project verification error: $($_.Exception.Message)" -ForegroundColor Red
        return $false
    }
} -Category "ModuleLoading"

Write-TestHeader "2. Workflow Creation and Management"

Test-IntegratedWorkflowFunction "Basic Integrated Workflow Creation" {
    param($Config)
    
    Write-Host "[DEBUG] [Test] Testing basic workflow creation with registered Unity projects..." -ForegroundColor Gray
    
    try {
        # Pre-test: Verify Unity projects are available using REAL function
        Write-Host "[DEBUG] [Test] Pre-workflow validation - checking REAL Unity project availability..." -ForegroundColor Gray
        
        $testProjects = @("Unity-Project-1", "Unity-Project-2")
        foreach ($projectName in $testProjects) {
            $availabilityCommand = Get-Command Test-UnityProjectAvailability -Module Unity-Claude-UnityParallelization -ErrorAction Stop
            $availability = & $availabilityCommand -ProjectName $projectName
            
            Write-Host "[DEBUG] [Test] Pre-workflow check - ${projectName}: Available=$($availability.Available)" -ForegroundColor $(if ($availability.Available) { "Green" } else { "Red" })
            if (-not $availability.Available) {
                Write-Host "[DEBUG] [Test] Pre-workflow check - ${projectName} reason: $($availability.Reason)" -ForegroundColor Red
            }
        }
        
        # Test basic workflow creation
        Write-Host "[DEBUG] [Test] Creating IntegratedWorkflow with validated projects..." -ForegroundColor Gray
        $workflow = New-IntegratedWorkflow -WorkflowName "TestBasicWorkflow" -MaxUnityProjects 2 -MaxClaudeSubmissions 3
        
        Write-Host "[DEBUG] [Test] Workflow creation result type: $($workflow.GetType().Name)" -ForegroundColor Gray
        Write-Host "[DEBUG] [Test] Workflow hashtable keys: $($workflow.Keys -join ', ')" -ForegroundColor Gray
        Write-Host "[DEBUG] [Test] Workflow Name: $($workflow.WorkflowName)" -ForegroundColor Gray
        Write-Host "[DEBUG] [Test] Workflow Status: $($workflow.Status)" -ForegroundColor Gray
        
        # Fix: Use WorkflowName key instead of Name property (function returns hashtable with WorkflowName key)
        if ($workflow -and $workflow.WorkflowName -eq "TestBasicWorkflow") {
            Write-Host "    Basic workflow created successfully" -ForegroundColor Green
            Write-Host "[DEBUG] [Test] Workflow validation passed: $($workflow.WorkflowName)" -ForegroundColor Green
            return $true
        } else {
            Write-Host "    Basic workflow creation failed - incorrect workflow name or structure" -ForegroundColor Red
            Write-Host "[DEBUG] [Test] Expected WorkflowName: TestBasicWorkflow, Actual: $($workflow.WorkflowName)" -ForegroundColor Red
            Write-Host "[DEBUG] [Test] Workflow object structure: $($workflow | ConvertTo-Json -Depth 1)" -ForegroundColor Red
            return $false
        }
        
    } catch {
        Write-Host "[DEBUG] [Test] Workflow creation exception: $($_.Exception.Message)" -ForegroundColor Red
        Write-Host "[DEBUG] [Test] Exception stack trace: $($_.ScriptStackTrace)" -ForegroundColor Red
        Write-Host "    Workflow creation error: $($_.Exception.Message)" -ForegroundColor Red
        return $false
    }
} -Category "WorkflowIntegration"

Test-IntegratedWorkflowFunction "Workflow Status and Monitoring" {
    param($Config)
    
    Write-Host "[DEBUG] [Test] Testing workflow status and monitoring..." -ForegroundColor Gray
    
    try {
        # Create workflow first
        Write-Host "[DEBUG] [Test] Creating workflow for status testing..." -ForegroundColor Gray
        $testWorkflow = New-IntegratedWorkflow -WorkflowName "TestStatusWorkflow" -MaxUnityProjects 1 -MaxClaudeSubmissions 2
        
        if (-not $testWorkflow) {
            Write-Host "[DEBUG] [Test] Cannot test status - workflow creation failed" -ForegroundColor Red
            Write-Host "    Cannot test status - workflow creation failed" -ForegroundColor Red
            return $false
        }
        
        # Test workflow status
        Write-Host "[DEBUG] [Test] Getting workflow status..." -ForegroundColor Gray
        $status = Get-IntegratedWorkflowStatus -IntegratedWorkflow $testWorkflow
        
        Write-Host "[DEBUG] [Test] Status result type: $($status.GetType().Name)" -ForegroundColor Gray
        
        if ($status -and $status.WorkflowName -eq "TestStatusWorkflow") {
            Write-Host "    Workflow status monitoring working correctly" -ForegroundColor Green
            Write-Host "[DEBUG] [Test] Status monitoring validated: $($status.WorkflowName)" -ForegroundColor Green
            return $true
        } else {
            Write-Host "    Workflow status monitoring failed" -ForegroundColor Red
            Write-Host "[DEBUG] [Test] Status monitoring failed - status: $status" -ForegroundColor Red
            return $false
        }
        
    } catch {
        Write-Host "[DEBUG] [Test] Status monitoring exception: $($_.Exception.Message)" -ForegroundColor Red
        Write-Host "    Status monitoring error: $($_.Exception.Message)" -ForegroundColor Red
        return $false
    }
} -Category "WorkflowIntegration"

Write-TestHeader "3. Performance Optimization Framework"

Test-IntegratedWorkflowFunction "Adaptive Throttling Initialization" {
    param($Config)
    
    Write-Host "[DEBUG] [Test] Testing adaptive throttling initialization..." -ForegroundColor Gray
    
    try {
        # Create workflow first
        Write-Host "[DEBUG] [Test] Creating workflow for throttling testing..." -ForegroundColor Gray
        $testWorkflow = New-IntegratedWorkflow -WorkflowName "TestThrottlingWorkflow" -MaxUnityProjects 1 -MaxClaudeSubmissions 2 -EnableResourceOptimization
        
        if (-not $testWorkflow) {
            Write-Host "[DEBUG] [Test] Cannot test throttling - workflow creation failed" -ForegroundColor Red
            Write-Host "    Cannot test throttling - workflow creation failed" -ForegroundColor Red
            return $false
        }
        
        # Test adaptive throttling
        Write-Host "[DEBUG] [Test] Initializing adaptive throttling..." -ForegroundColor Gray
        $throttlingResult = Initialize-AdaptiveThrottling -IntegratedWorkflow $testWorkflow -CPUThreshold 80 -MemoryThreshold 75
        
        Write-Host "[DEBUG] [Test] Throttling result: $throttlingResult" -ForegroundColor Gray
        
        if ($throttlingResult) {
            Write-Host "    Adaptive throttling initialized successfully" -ForegroundColor Green
            Write-Host "[DEBUG] [Test] Throttling initialization validated" -ForegroundColor Green
            return $true
        } else {
            Write-Host "    Adaptive throttling initialization failed" -ForegroundColor Red
            Write-Host "[DEBUG] [Test] Throttling initialization failed" -ForegroundColor Red
            return $false
        }
        
    } catch {
        Write-Host "[DEBUG] [Test] Throttling initialization exception: $($_.Exception.Message)" -ForegroundColor Red
        Write-Host "    Throttling initialization error: $($_.Exception.Message)" -ForegroundColor Red
        return $false
    }
} -Category "PerformanceOptimization"

# Final test results summary
$TestResults.EndTime = Get-Date
$totalDuration = ($TestResults.EndTime - $TestResults.StartTime).TotalSeconds

Write-Host ""
Write-Host "=== End-to-End Integration Testing Results Summary ===" -ForegroundColor Cyan
Write-Host ""
Write-Host "Testing Execution Summary:" -ForegroundColor White
Write-Host "Total Tests: $($TestResults.Summary.Total)" -ForegroundColor White
Write-Host "Passed: $($TestResults.Summary.Passed)" -ForegroundColor Green
Write-Host "Failed: $($TestResults.Summary.Failed)" -ForegroundColor Red
Write-Host "Skipped: $($TestResults.Summary.Skipped)" -ForegroundColor Yellow
Write-Host "Duration: $([math]::Round($totalDuration, 2)) seconds" -ForegroundColor White

if ($TestResults.Summary.Total -gt 0) {
    $passRate = [math]::Round(($TestResults.Summary.Passed / $TestResults.Summary.Total) * 100, 1)
    Write-Host "Pass Rate: $passRate percent" -ForegroundColor $(if ($passRate -ge 90) { "Green" } elseif ($passRate -ge 70) { "Yellow" } else { "Red" })
} else {
    Write-Host "Pass Rate: 0 percent" -ForegroundColor Red
}

Write-Host ""
Write-Host "Category Breakdown:" -ForegroundColor White
foreach ($category in $TestResults.Categories.GetEnumerator() | Sort-Object Key) {
    $catPassRate = if ($category.Value.Total -gt 0) { 
        [math]::Round(($category.Value.Passed / $category.Value.Total) * 100, 1) 
    } else { 0 }
    Write-Host "$($category.Key): $($category.Value.Passed)/$($category.Value.Total) ($catPassRate%)" -ForegroundColor White
}

Write-Host ""
if ($TestResults.Summary.Failed -eq 0) {
    Write-Host "[SUCCESS] WEEK 3 DAY 5 END-TO-END INTEGRATION: SUCCESS All workflow components operational" -ForegroundColor Green
} elseif ($TestResults.Summary.Passed -gt 0) {
    Write-Host "[PARTIAL] WEEK 3 DAY 5 END-TO-END INTEGRATION: PARTIAL SUCCESS Some issues remain" -ForegroundColor Yellow
} else {
    Write-Host "[FAILURE] WEEK 3 DAY 5 END-TO-END INTEGRATION: NEEDS ATTENTION Significant issues in workflow implementation" -ForegroundColor Red
}

Write-Host ""
Write-Host "[DEBUG] [TestExecution] Test execution completed - using REAL module functions only" -ForegroundColor Gray

# Save test results if requested
if ($SaveResults) {
    $resultsOutput = @"
=== Unity-Claude End-to-End Integration Test Results (FINAL) ===
Test: $($TestConfig.TestName)
Date: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
PowerShell Version: $($PSVersionTable.PSVersion)

Summary:
Total Tests: $($TestResults.Summary.Total)
Passed: $($TestResults.Summary.Passed)
Failed: $($TestResults.Summary.Failed)
Duration: $([math]::Round($totalDuration, 2)) seconds
Pass Rate: $passRate%

Module Loading Results:
ParallelProcessing: $parallelCommands functions
RunspaceManagement: $runspaceCommands functions  
UnityParallelization: $unityCommands functions
ClaudeParallelization: $claudeCommands functions
IntegratedWorkflow: $integratedCommands functions
Total Functions: $totalFunctions

Function Availability: $availableCount/$($criticalFunctions.Count) ($functionAvailabilityRate%)

Category Results:
$($TestResults.Categories.GetEnumerator() | ForEach-Object { "$($_.Key): $($_.Value.Passed)/$($_.Value.Total)" } | Out-String)

Detailed Test Results:
$($TestResults.Tests | ForEach-Object { "[$($_.Status)] $($_.Name) ($($_.Duration)ms)$(if ($_.Error) { " - Error: $($_.Error)" })" } | Out-String)

Debug Information - Function Sources:
$($criticalFunctions | ForEach-Object { $cmd = Get-Command $_ -ErrorAction SilentlyContinue; "[$(if ($cmd) { 'AVAILABLE' } else { 'MISSING' })] $_ $(if ($cmd) { "(Module: $($cmd.ModuleName))" })" } | Out-String)
"@
    
    $resultsOutput | Out-File -FilePath $TestConfig.TestResultsFile -Encoding UTF8
    Write-Host "Test results saved to: $($TestConfig.TestResultsFile)" -ForegroundColor Gray
}

Write-Host ""
return $TestResults
# SIG # Begin signature block
# MIIFqQYJKoZIhvcNAQcCoIIFmjCCBZYCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUm1R1XhqojB0njZD6du78hjH6
# om6gggMwMIIDLDCCAhSgAwIBAgIQdR0W2SKoK5VE8JId4ZxrRTANBgkqhkiG9w0B
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
# CQQxFgQUZLIdQPDEoXXJCIVvy/74zQD4tT4wDQYJKoZIhvcNAQEBBQAEggEATkFP
# qk6nbQN3kx8CY7PcizxKjcjIhMVn9oJAnXwdHk3JpYhfpUvMyvwAM9sk0lRsuQYS
# FLvQZs6lbnRMhfwFyP/qf782WfcDss4FjUdMOz8Z5k2JaRAF7bQLwMJt3oIJmyl8
# Nxzcph87q3XpkcoFU8detQwzBMu0B710h/kT4wADG2ahD9bxwocpDhcuaTzp8QhO
# qxw6GjQSgMA/CfXIWncNMnAtetVLtIfeGu+piODHsaek5bVd/KYG+C3f+Jm/Bj7w
# bEErFpHFf1k6qLvyqtaX9xScNQ5a7ULy2nHMQoaArr+YzRfVk2MkCxR2xrI0f0E9
# yKz47tq6rRas3cPeMw==
# SIG # End signature block
