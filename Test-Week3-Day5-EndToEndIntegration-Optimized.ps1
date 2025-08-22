# Test-Week3-Day5-EndToEndIntegration-Optimized.ps1
# Phase 3: Test Script Optimization with proper module loading sequence and Unity mocks
# Implements research-validated patterns for module dependency management
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

Write-Host "=== Week 3 Day 5: End-to-End Integration Test (OPTIMIZED) ===" -ForegroundColor Cyan
Write-Host "Research-validated module loading with Unity project mocking" -ForegroundColor White
Write-Host "Date: $(Get-Date -Format 'MM/dd/yyyy HH:mm:ss')" -ForegroundColor White
Write-Host "PowerShell Version: $($PSVersionTable.PSVersion)" -ForegroundColor White
Write-Host ""

# Test configuration
$TestConfig = @{
    TestName = "Week3-Day5-EndToEndIntegration-Optimized"
    Date = Get-Date
    SaveResults = $SaveResults
    EnableResourceMonitoring = $EnableResourceMonitoring
    TestWithRealUnityProjects = $TestWithRealUnityProjects
    TestWithRealClaudeAPI = $TestWithRealClaudeAPI
    TestTimeout = $TestTimeout
    TestResultsFile = if ($TestResultsFile) { $TestResultsFile } else { 
        "Test_Results_Week3_Day5_EndToEnd_OPTIMIZED_$(Get-Date -Format 'yyyyMMdd_HHmmss').txt" 
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
        # Write timestamp log for debugging
        Write-Host "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss.fff')] [INFO] [$Category] Starting test: $TestName" -ForegroundColor White
        
        # Pre-test function availability validation
        Write-Host "[DEBUG] [TestExecution] Pre-test validation for: $TestName" -ForegroundColor Gray
        $requiredFunctions = @('New-IntegratedWorkflow', 'Start-IntegratedWorkflow', 'Get-IntegratedWorkflowStatus')
        $preTestAvailable = 0
        foreach ($func in $requiredFunctions) {
            $exists = Get-Command $func -ErrorAction SilentlyContinue
            if ($exists) {
                $preTestAvailable++
                Write-Host "[DEBUG] [TestExecution] Function available: $func" -ForegroundColor Green
            } else {
                Write-Host "[DEBUG] [TestExecution] Function missing: $func" -ForegroundColor Red
            }
        }
        Write-Host "[DEBUG] [TestExecution] Pre-test function availability: $preTestAvailable/$($requiredFunctions.Count)" -ForegroundColor $(if ($preTestAvailable -eq $requiredFunctions.Count) { "Green" } else { "Red" })
        
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

# Phase 3 Hour 1-2: Module Loading Sequence Optimization
Write-Host "Importing modules..."
Write-Host "[DEBUG] [ModuleLoading] Starting optimized module loading sequence" -ForegroundColor Gray

# Apply PSModulePath fix for current session
$moduleBasePath = "C:\UnityProjects\Sound-and-Shoal\Unity-Claude-Automation\Modules"
if ($env:PSModulePath -notlike "*$moduleBasePath*") {
    Write-Host "[DEBUG] [ModuleLoading] Adding Modules directory to PSModulePath..." -ForegroundColor Yellow
    $env:PSModulePath = "$moduleBasePath;$($env:PSModulePath)"
    Write-Host "[DEBUG] [ModuleLoading] PSModulePath updated for current session" -ForegroundColor Green
}

# Load modules in dependency order without RequiredModules (research-validated approach)
try {
    Write-Host "[DEBUG] [ModuleLoading] Step 1: Loading Unity Project Test Mocks..." -ForegroundColor Cyan
    Import-Module ".\Unity-Project-TestMocks.psm1" -Force -Global -ErrorAction Stop
    Write-Host "[DEBUG] [ModuleLoading] Unity Project Test Mocks loaded successfully" -ForegroundColor Green
    
    Write-Host "[DEBUG] [ModuleLoading] Step 2: Loading base dependency (ParallelProcessing)..." -ForegroundColor Cyan
    try {
        Import-Module Unity-Claude-ParallelProcessing -Force -Global -ErrorAction Stop
    } catch {
        # Fallback to explicit path
        Write-Host "[DEBUG] [ModuleLoading] Module name import failed, trying explicit path..." -ForegroundColor Yellow
        Import-Module "$moduleBasePath\Unity-Claude-ParallelProcessing\Unity-Claude-ParallelProcessing.psm1" -Force -Global -ErrorAction Stop
    }
    $parallelCommands = (Get-Command -Module Unity-Claude-ParallelProcessing -ErrorAction SilentlyContinue).Count
    Write-Host "[DEBUG] [ModuleLoading] ParallelProcessing loaded: $parallelCommands functions" -ForegroundColor Green
    
    Write-Host "[DEBUG] [ModuleLoading] Step 3: Loading RunspaceManagement..." -ForegroundColor Cyan
    try {
        Import-Module Unity-Claude-RunspaceManagement -Force -Global -ErrorAction Stop
    } catch {
        # Fallback to explicit path
        Write-Host "[DEBUG] [ModuleLoading] Module name import failed, trying explicit path..." -ForegroundColor Yellow
        Import-Module "$moduleBasePath\Unity-Claude-RunspaceManagement\Unity-Claude-RunspaceManagement.psm1" -Force -Global -ErrorAction Stop
    }
    $runspaceCommands = (Get-Command -Module Unity-Claude-RunspaceManagement -ErrorAction SilentlyContinue).Count
    Write-Host "[DEBUG] [ModuleLoading] RunspaceManagement loaded: $runspaceCommands functions" -ForegroundColor Green
    
    Write-Host "[DEBUG] [ModuleLoading] Step 4: Loading UnityParallelization..." -ForegroundColor Cyan
    try {
        Import-Module Unity-Claude-UnityParallelization -Force -Global -ErrorAction Stop
    } catch {
        # Fallback to explicit path
        Write-Host "[DEBUG] [ModuleLoading] Module name import failed, trying explicit path..." -ForegroundColor Yellow
        Import-Module "$moduleBasePath\Unity-Claude-UnityParallelization\Unity-Claude-UnityParallelization.psm1" -Force -Global -ErrorAction Stop
    }
    $unityCommands = (Get-Command -Module Unity-Claude-UnityParallelization -ErrorAction SilentlyContinue).Count
    Write-Host "[DEBUG] [ModuleLoading] UnityParallelization loaded: $unityCommands functions" -ForegroundColor Green
    
    Write-Host "[DEBUG] [ModuleLoading] Step 5: Loading ClaudeParallelization..." -ForegroundColor Cyan
    try {
        Import-Module Unity-Claude-ClaudeParallelization -Force -Global -ErrorAction Stop
    } catch {
        # Fallback to explicit path
        Write-Host "[DEBUG] [ModuleLoading] Module name import failed, trying explicit path..." -ForegroundColor Yellow
        Import-Module "$moduleBasePath\Unity-Claude-ClaudeParallelization\Unity-Claude-ClaudeParallelization.psm1" -Force -Global -ErrorAction Stop
    }
    $claudeCommands = (Get-Command -Module Unity-Claude-ClaudeParallelization -ErrorAction SilentlyContinue).Count
    Write-Host "[DEBUG] [ModuleLoading] ClaudeParallelization loaded: $claudeCommands functions" -ForegroundColor Green
    
    Write-Host "[DEBUG] [ModuleLoading] Step 6: Loading IntegratedWorkflow..." -ForegroundColor Cyan
    try {
        Import-Module Unity-Claude-IntegratedWorkflow -Force -Global -ErrorAction Stop
    } catch {
        # Fallback to explicit path
        Write-Host "[DEBUG] [ModuleLoading] Module name import failed, trying explicit path..." -ForegroundColor Yellow
        Import-Module "$moduleBasePath\Unity-Claude-IntegratedWorkflow\Unity-Claude-IntegratedWorkflow.psm1" -Force -Global -ErrorAction Stop
    }
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

# Phase 2: Unity Project Mock Infrastructure Integration
Write-Host ""
Write-Host "[DEBUG] [MockSetup] Setting up Unity project mocks..." -ForegroundColor Yellow

# Create mock project directories and register with UnityParallelization module
$mockProjectsBasePath = "C:\MockProjects"
$mockProjects = @("Unity-Project-1", "Unity-Project-2", "Unity-Project-3")

foreach ($projectName in $mockProjects) {
    $projectPath = Join-Path $mockProjectsBasePath $projectName
    
    # Create basic Unity project structure if it doesn't exist
    if (-not (Test-Path $projectPath)) {
        Write-Host "[DEBUG] [MockSetup] Creating mock project directory: $projectName" -ForegroundColor Gray
        New-Item -Path $projectPath -ItemType Directory -Force | Out-Null
        
        # Create minimal Unity structure
        New-Item -Path "$projectPath\Assets" -ItemType Directory -Force | Out-Null
        New-Item -Path "$projectPath\ProjectSettings" -ItemType Directory -Force | Out-Null
        
        # Create ProjectVersion.txt to make it look like a Unity project
        @"
m_EditorVersion: 2021.1.14f1
m_EditorVersionWithRevision: 2021.1.14f1 (54ba63c7b9e8)
"@ | Set-Content "$projectPath\ProjectSettings\ProjectVersion.txt" -Encoding UTF8
    }
    
    # Register with UnityParallelization module
    try {
        Write-Host "[DEBUG] [MockSetup] Registering $projectName with UnityParallelization module..." -ForegroundColor Gray
        $registration = Register-UnityProject -ProjectPath $projectPath -ProjectName $projectName -MonitoringEnabled
        
        # Test availability immediately
        $availability = Test-UnityProjectAvailability -ProjectName $projectName
        Write-Host "[DEBUG] [MockSetup] $projectName registration result: Available=$($availability.Available)" -ForegroundColor $(if ($availability.Available) { "Green" } else { "Red" })
        
    } catch {
        Write-Host "[DEBUG] [MockSetup] Failed to register $projectName : $($_.Exception.Message)" -ForegroundColor Red
    }
}

# Phase 3 Hour 3-4: Enhanced Logging and Diagnostics - Function Availability Validation
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
        Write-Host "[DEBUG] [Diagnostics] Function AVAILABLE: $func" -ForegroundColor Green
    } else {
        Write-Host "[DEBUG] [Diagnostics] Function MISSING: $func" -ForegroundColor Red
    }
}

$functionAvailabilityRate = [math]::Round(($availableCount / $criticalFunctions.Count) * 100, 1)
Write-Host "[DEBUG] [Diagnostics] Function Availability: $availableCount/$($criticalFunctions.Count) ($functionAvailabilityRate%)" -ForegroundColor $(if ($functionAvailabilityRate -ge 90) { "Green" } else { "Red" })

if ($functionAvailabilityRate -lt 90) {
    Write-Host "ERROR: Critical functions missing - cannot proceed with tests" -ForegroundColor Red
    exit 1
}

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
                Write-Host "[DEBUG] [Test] Available function: $func" -ForegroundColor Green
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

Test-IntegratedWorkflowFunction "Unity Project Mock Infrastructure" {
    param($Config)
    
    Write-Host "[DEBUG] [Test] Testing Unity project mock infrastructure..." -ForegroundColor Gray
    
    try {
        # Test mock project availability
        $project1Status = Test-UnityProjectAvailability -ProjectName "Unity-Project-1"
        $project2Status = Test-UnityProjectAvailability -ProjectName "Unity-Project-2"
        
        Write-Host "[DEBUG] [Test] Unity-Project-1 available: $($project1Status.Available)" -ForegroundColor $(if ($project1Status.Available) { "Green" } else { "Red" })
        Write-Host "[DEBUG] [Test] Unity-Project-2 available: $($project2Status.Available)" -ForegroundColor $(if ($project2Status.Available) { "Green" } else { "Red" })
        
        if ($project1Status.Available -and $project2Status.Available) {
            Write-Host "    Mock Unity projects available for testing" -ForegroundColor Green
            return $true
        } else {
            Write-Host "    Mock Unity projects not properly configured" -ForegroundColor Red
            return $false
        }
        
    } catch {
        Write-Host "[DEBUG] [Test] Mock infrastructure test error: $($_.Exception.Message)" -ForegroundColor Red
        Write-Host "    Mock infrastructure error: $($_.Exception.Message)" -ForegroundColor Red
        return $false
    }
} -Category "ModuleLoading"

Write-TestHeader "2. Workflow Creation and Management"

Test-IntegratedWorkflowFunction "Basic Integrated Workflow Creation with Mocks" {
    param($Config)
    
    Write-Host "[DEBUG] [Test] Testing basic workflow creation with mock Unity projects..." -ForegroundColor Gray
    
    try {
        # Pre-test: Ensure Unity projects are available
        Write-Host "[DEBUG] [Test] Pre-workflow validation - checking Unity project availability..." -ForegroundColor Gray
        
        $registeredProjects = Get-RegisteredUnityProjects
        Write-Host "[DEBUG] [Test] Found $($registeredProjects.Count) registered Unity projects" -ForegroundColor Gray
        
        foreach ($project in $registeredProjects) {
            Write-Host "[DEBUG] [Test] Registered project: $($project.Name) (Status: $($project.Status))" -ForegroundColor Gray
        }
        
        # Test basic workflow creation
        Write-Host "[DEBUG] [Test] Creating IntegratedWorkflow with mock projects..." -ForegroundColor Gray
        $workflow = New-IntegratedWorkflow -WorkflowName "TestBasicWorkflow" -MaxUnityProjects 2 -MaxClaudeSubmissions 3
        
        Write-Host "[DEBUG] [Test] Workflow creation result type: $($workflow.GetType().Name)" -ForegroundColor Gray
        Write-Host "[DEBUG] [Test] Workflow object: $($workflow | Out-String)" -ForegroundColor Gray
        
        if ($workflow -and $workflow.Name -eq "TestBasicWorkflow") {
            Write-Host "    Basic workflow created successfully with mock Unity projects" -ForegroundColor Green
            Write-Host "[DEBUG] [Test] Workflow validation passed: $($workflow.Name)" -ForegroundColor Green
            return $true
        } else {
            Write-Host "    Basic workflow creation failed - invalid return object" -ForegroundColor Red
            Write-Host "[DEBUG] [Test] Workflow validation failed - object: $workflow" -ForegroundColor Red
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
        Write-Host "[DEBUG] [Test] Status details: $($status | Out-String)" -ForegroundColor Gray
        
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
Write-Host "[DEBUG] [TestExecution] Test execution completed" -ForegroundColor Gray

# Save test results if requested
if ($SaveResults) {
    $resultsOutput = @"
=== Unity-Claude End-to-End Integration Test Results (OPTIMIZED) ===
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

Debug Information:
$($criticalFunctions | ForEach-Object { $exists = Get-Command $_ -ErrorAction SilentlyContinue; "[$(if ($exists) { 'AVAILABLE' } else { 'MISSING' })] $_" } | Out-String)
"@
    
    $resultsOutput | Out-File -FilePath $TestConfig.TestResultsFile -Encoding UTF8
    Write-Host "Test results saved to: $($TestConfig.TestResultsFile)" -ForegroundColor Gray
}

Write-Host ""
return $TestResults
# SIG # Begin signature block
# MIIFqQYJKoZIhvcNAQcCoIIFmjCCBZYCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUr1yCbau+Wwx/rH81QxG0r/qK
# tHOgggMwMIIDLDCCAhSgAwIBAgIQdR0W2SKoK5VE8JId4ZxrRTANBgkqhkiG9w0B
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
# CQQxFgQUu5hkIU4+sQHWv80QyX9bG82f8vUwDQYJKoZIhvcNAQEBBQAEggEAid3V
# 8CHaJC9tB3umsp5Fpym+etrmwod+Rcay4YOonklAF+tMEZk2RWAWV4EF2ZGzYEeX
# Qi2u1nCC/jeN1aiwM9mjUmxKtJQeWR4Cjb6yqtTuZ25B0kH/aO/ajIsfEN6//u8e
# Ef778N9Ka09mV9WQbAE3Ep1sF1SP2G6vEld0jSYePM26LnkAhQaVhskbPs7CO8LU
# 8vdDMcRZiGXM1+gG6VSJ39GrS+zRQ4u45SGOHRXG/fKr5EXK/+hBqWE1VoM2n99V
# jfGgBSUlIF7Tr9CcQbZmmFl5NaRBlhWAFSilOqwnA5oNTtq5OaWbcC8asFvsMIYh
# ivPICJbJ5WtpCzKUOg==
# SIG # End signature block
