# Test-Ollama-Integration-Optimized.ps1
# Week 1 Day 3 Hour 7-8: Ollama Integration Testing and Optimization
# Comprehensive validation of performance optimizations, batch processing, and resource utilization

#region Test Framework Setup

$ErrorActionPreference = "Stop"

# Test results tracking with enhanced metrics
$script:TestResults = @{
    StartTime = Get-Date
    TestSuite = "Ollama Integration Testing and Optimization (Week 1 Day 3 Hour 7-8)"
    Tests = @()
    Summary = @{}
    EndTime = $null
    OptimizationMetrics = @{}
    PerformanceComparison = @{}
}

function Add-TestResult {
    param(
        [string]$TestName,
        [string]$Category,
        [bool]$Passed,
        [string]$Details,
        [hashtable]$Data = @{},
        [double]$Duration = $null,
        [hashtable]$PerformanceData = @{}
    )
    
    $testResult = @{
        TestName = $TestName
        Category = $Category
        Passed = $Passed
        Details = $Details
        Data = $Data
        Duration = $Duration
        PerformanceData = $PerformanceData
        Timestamp = Get-Date
    }
    
    $script:TestResults.Tests += $testResult
    
    $status = if ($Passed) { "[PASS]" } else { "[FAIL]" }
    $color = if ($Passed) { "Green" } else { "Red" }
    
    if ($Duration) {
        Write-Host "  $status $TestName ($([Math]::Round($Duration, 2))s) - $Details" -ForegroundColor $color
    } else {
        Write-Host "  $status $TestName - $Details" -ForegroundColor $color
    }
}

function Test-PerformanceImprovement {
    param(
        [string]$TestName,
        [double]$BaselineTime,
        [double]$OptimizedTime,
        [double]$TargetTime,
        [double]$ImprovementThreshold = 0.2  # 20% improvement required
    )
    
    $improvementPercent = if ($BaselineTime -gt 0) {
        [Math]::Round((($BaselineTime - $OptimizedTime) / $BaselineTime) * 100, 1)
    } else { 0 }
    
    $meetsTarget = $OptimizedTime -le $TargetTime
    $meetsImprovement = $improvementPercent -ge ($ImprovementThreshold * 100)
    
    $passed = $meetsTarget -or $meetsImprovement
    
    $details = "Improvement: $improvementPercent%, Target: <$TargetTime s, Actual: $([Math]::Round($OptimizedTime, 2))s"
    
    return @{
        Passed = $passed
        Details = $details
        ImprovementPercent = $improvementPercent
        MeetsTarget = $meetsTarget
        MeetsImprovement = $meetsImprovement
    }
}

#endregion

#region Test Data Preparation

# Create sample code content of varying sizes for context window testing
$TestCodeSamples = @{
    Small = @'
Get-Date | Format-Table
'@
    
    Medium = @'
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
    
    Large = @'
function Invoke-AdvancedSystemAnalysis {
    <#
    .SYNOPSIS
    Performs comprehensive system analysis with multiple diagnostic checks
    
    .DESCRIPTION
    This function conducts extensive system analysis including performance monitoring,
    security assessment, resource utilization tracking, and health validation.
    It provides detailed reporting and recommendations for system optimization.
    
    .PARAMETER ComputerName
    Target computer for analysis
    
    .PARAMETER IncludePerformanceCounters
    Include detailed performance counter analysis
    
    .PARAMETER GenerateReport
    Generate comprehensive HTML report
    
    .EXAMPLE
    Invoke-AdvancedSystemAnalysis -ComputerName "SERVER01" -IncludePerformanceCounters -GenerateReport
    #>
    [CmdletBinding()]
    param(
        [string]$ComputerName = $env:COMPUTERNAME,
        [switch]$IncludePerformanceCounters,
        [switch]$GenerateReport,
        [string]$OutputPath = ".\SystemAnalysisReport.html"
    )
    
    Write-Verbose "Starting advanced system analysis for $ComputerName"
    
    try {
        # System Information Collection
        $systemInfo = Get-WmiObject Win32_ComputerSystem -ComputerName $ComputerName
        $osInfo = Get-WmiObject Win32_OperatingSystem -ComputerName $ComputerName
        $processorInfo = Get-WmiObject Win32_Processor -ComputerName $ComputerName
        $memoryInfo = Get-WmiObject Win32_PhysicalMemory -ComputerName $ComputerName
        $diskInfo = Get-WmiObject Win32_LogicalDisk -ComputerName $ComputerName | Where-Object { $_.DriveType -eq 3 }
        
        # Performance Counter Collection
        if ($IncludePerformanceCounters) {
            $perfCounters = @{
                CPUUsage = (Get-Counter "\Processor(_Total)\% Processor Time" -ComputerName $ComputerName).CounterSamples.CookedValue
                MemoryUsage = (Get-Counter "\Memory\Available MBytes" -ComputerName $ComputerName).CounterSamples.CookedValue
                DiskActivity = (Get-Counter "\PhysicalDisk(_Total)\% Disk Time" -ComputerName $ComputerName).CounterSamples.CookedValue
            }
        }
        
        # Security Assessment
        $securityInfo = @{
            WindowsDefenderStatus = Get-Service "WinDefend" -ComputerName $ComputerName -ErrorAction SilentlyContinue
            FirewallProfiles = Get-NetFirewallProfile -CimSession $ComputerName
            LastUpdates = Get-HotFix -ComputerName $ComputerName | Sort-Object InstalledOn -Descending | Select-Object -First 5
        }
        
        # Service Analysis
        $criticalServices = Get-Service -ComputerName $ComputerName | Where-Object { 
            $_.Name -in @("BITS", "Spooler", "Themes", "AudioSrv", "Dhcp", "Dnscache", "Schedule") 
        }
        
        # Event Log Analysis
        $recentErrors = Get-WinEvent -FilterHashtable @{LogName="System"; Level=2; StartTime=(Get-Date).AddDays(-7)} -MaxEvents 10 -ComputerName $ComputerName -ErrorAction SilentlyContinue
        
        # Compile comprehensive results
        $analysisResults = @{
            ComputerName = $ComputerName
            Timestamp = Get-Date
            SystemInfo = @{
                Manufacturer = $systemInfo.Manufacturer
                Model = $systemInfo.Model
                TotalPhysicalMemory = [math]::Round($systemInfo.TotalPhysicalMemory / 1GB, 2)
                NumberOfProcessors = $systemInfo.NumberOfProcessors
            }
            OperatingSystem = @{
                Caption = $osInfo.Caption
                Version = $osInfo.Version
                Architecture = $osInfo.OSArchitecture
                InstallDate = $osInfo.ConvertToDateTime($osInfo.InstallDate)
                LastBootUpTime = $osInfo.ConvertToDateTime($osInfo.LastBootUpTime)
                FreePhysicalMemory = [math]::Round($osInfo.FreePhysicalMemory / 1MB, 2)
            }
            ProcessorInfo = @{
                Name = $processorInfo.Name
                Cores = $processorInfo.NumberOfCores
                LogicalProcessors = $processorInfo.NumberOfLogicalProcessors
                ClockSpeed = $processorInfo.MaxClockSpeed
            }
            DiskInfo = $diskInfo | Select-Object DeviceID, Size, FreeSpace, @{Name="UsedPercent";Expression={[math]::Round((($_.Size - $_.FreeSpace) / $_.Size) * 100, 1)}}
            CriticalServices = $criticalServices | Select-Object Name, Status, StartType
            RecentErrors = $recentErrors | Select-Object Id, LevelDisplayName, TimeCreated, @{Name="Message";Expression={$_.Message.Substring(0, [Math]::Min(100, $_.Message.Length))}}
            SecurityInfo = $securityInfo
            PerformanceCounters = if ($IncludePerformanceCounters) { $perfCounters } else { $null }
        }
        
        # Generate HTML Report if requested
        if ($GenerateReport) {
            $htmlReport = Generate-SystemAnalysisReport -AnalysisResults $analysisResults
            $htmlReport | Out-File -FilePath $OutputPath -Encoding UTF8
            Write-Verbose "Report generated: $OutputPath"
        }
        
        return $analysisResults
    }
    catch {
        Write-Error "System analysis failed: $($_.Exception.Message)"
        throw
    }
}

function Generate-SystemAnalysisReport {
    param([hashtable]$AnalysisResults)
    
    # HTML report generation logic would go here
    return "<html><body><h1>System Analysis Report</h1><p>Generated: $(Get-Date)</p></body></html>"
}
'@
}

# Batch processing test data
$BatchTestRequests = @()
for ($i = 1; $i -le 10; $i++) {
    $BatchTestRequests += @{
        Id = $i
        CodeContent = $TestCodeSamples.Medium
        DocumentationType = "Detailed"
    }
}

#endregion

#region Test Execution

Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "Ollama Integration Testing and Optimization Suite" -ForegroundColor White
Write-Host "Week 1 Day 3 Hour 7-8: Performance Optimization Validation" -ForegroundColor White
Write-Host "Target: Optimized Ollama integration with efficient resource utilization" -ForegroundColor White
Write-Host "============================================================" -ForegroundColor Cyan

#region Module Loading and Optimization Testing

Write-Host "`n[TEST CATEGORY] Module Loading and Configuration Optimization..." -ForegroundColor Yellow

try {
    Write-Host "Loading Unity-Claude-Ollama-Optimized-Fixed module..." -ForegroundColor White
    Import-Module ".\Unity-Claude-Ollama-Optimized-Fixed.psm1" -Force
    
    $optimizedCommands = Get-Command -Module "Unity-Claude-Ollama-Optimized-Fixed"
    $commandCount = ($optimizedCommands | Measure-Object).Count
    
    $expectedOptimizedFunctions = @(
        'Get-OptimalContextWindow',
        'Optimize-OllamaConfiguration', 
        'Start-OllamaBatchProcessing',
        'Get-OllamaPerformanceReport'
    )
    
    $hasOptimizedFunctions = $true
    $missingFunctions = @()
    
    foreach ($func in $expectedOptimizedFunctions) {
        if ($optimizedCommands.Name -notcontains $func) {
            $hasOptimizedFunctions = $false
            $missingFunctions += $func
        }
    }
    
    Add-TestResult -TestName "Optimized Module Loading" -Category "Optimization" -Passed $hasOptimizedFunctions -Details "Commands loaded: $commandCount, Missing: $($missingFunctions -join ', ')" -Data @{
        LoadedCommands = $optimizedCommands.Name
        ExpectedCount = $expectedOptimizedFunctions.Count
        ActualCount = $commandCount
        MissingFunctions = $missingFunctions
    }
}
catch {
    Add-TestResult -TestName "Optimized Module Loading" -Category "Optimization" -Passed $false -Details "Exception: $($_.Exception.Message)"
}

try {
    Write-Host "Testing automatic configuration optimization..." -ForegroundColor White
    $startTime = Get-Date
    
    $configResult = Optimize-OllamaConfiguration
    $duration = (Get-Date) - $startTime
    
    $configOptimal = ($configResult -ne $null) -and $configResult.ContainsKey('OptimalParallel') -and $configResult.ContainsKey('OptimalTimeout')
    
    Add-TestResult -TestName "Configuration Optimization" -Category "Optimization" -Passed $configOptimal -Details "Auto-configuration: $configOptimal" -Data @{
        OptimalConfiguration = $configResult
        GPUDetected = $configResult.GPU
        OptimalParallel = $configResult.OptimalParallel
        OptimalTimeout = $configResult.OptimalTimeout
    } -Duration $duration.TotalSeconds
}
catch {
    Add-TestResult -TestName "Configuration Optimization" -Category "Optimization" -Passed $false -Details "Exception: $($_.Exception.Message)"
}

#endregion

#region Context Window Optimization Testing

Write-Host "`n[TEST CATEGORY] Context Window Optimization..." -ForegroundColor Yellow

try {
    Write-Host "Testing dynamic context window selection..." -ForegroundColor White
    
    $smallContextResult = Get-OptimalContextWindow -CodeContent $TestCodeSamples.Small -DocumentationType "Synopsis"
    $mediumContextResult = Get-OptimalContextWindow -CodeContent $TestCodeSamples.Medium -DocumentationType "Detailed"
    $largeContextResult = Get-OptimalContextWindow -CodeContent $TestCodeSamples.Large -DocumentationType "Complete"
    
    $contextOptimizationWorking = (
        $smallContextResult.WindowType -eq "Small" -and 
        $mediumContextResult.WindowType -eq "Medium" -and 
        $largeContextResult.WindowType -in @("Large", "Maximum")
    )
    
    Add-TestResult -TestName "Context Window Selection" -Category "ContextOptimization" -Passed $contextOptimizationWorking -Details "Dynamic sizing: Small->$($smallContextResult.WindowType), Medium->$($mediumContextResult.WindowType), Large->$($largeContextResult.WindowType)" -Data @{
        SmallContext = $smallContextResult
        MediumContext = $mediumContextResult
        LargeContext = $largeContextResult
        OptimizationWorking = $contextOptimizationWorking
    }
}
catch {
    Add-TestResult -TestName "Context Window Selection" -Category "ContextOptimization" -Passed $false -Details "Exception: $($_.Exception.Message)"
}

#endregion

#region Performance Optimization Testing

Write-Host "`n[TEST CATEGORY] Performance Optimization Validation..." -ForegroundColor Yellow

# Load original module for comparison
$baselineResults = @{}
try {
    Write-Host "Loading original module for baseline comparison..." -ForegroundColor White
    Import-Module ".\Unity-Claude-Ollama.psm1" -Force
    
    Write-Host "Running baseline performance test..." -ForegroundColor White
    $startTime = Get-Date
    
    $baselineDoc = Invoke-OllamaDocumentation -CodeContent $TestCodeSamples.Medium -DocumentationType "Synopsis"
    $baselineResults.ResponseTime = (Get-Date) - $startTime
    $baselineResults.Success = ($baselineDoc -ne $null) -and ($baselineDoc.Documentation.Length -gt 0)
    
    Write-Host "Baseline test completed in $([Math]::Round($baselineResults.ResponseTime.TotalSeconds, 2))s" -ForegroundColor Gray
}
catch {
    Write-Warning "Baseline test failed: $($_.Exception.Message)"
    $baselineResults = @{ ResponseTime = [TimeSpan]::FromSeconds(60); Success = $false }
}

# Test optimized performance
try {
    Write-Host "Testing optimized performance..." -ForegroundColor White
    Import-Module ".\Unity-Claude-Ollama-Optimized-Fixed.psm1" -Force
    
    $startTime = Get-Date
    $optimizedRequest = @{
        CodeContent = $TestCodeSamples.Medium
        DocumentationType = "Synopsis"
    }
    
    $contextInfo = Get-OptimalContextWindow -CodeContent $optimizedRequest.CodeContent -DocumentationType $optimizedRequest.DocumentationType
    $optimizedResult = Invoke-OllamaOptimizedRequest -Request $optimizedRequest -ContextInfo $contextInfo
    
    $optimizedDuration = (Get-Date) - $startTime
    
    $performanceTest = Test-PerformanceImprovement -TestName "Optimized Performance" -BaselineTime $baselineResults.ResponseTime.TotalSeconds -OptimizedTime $optimizedDuration.TotalSeconds -TargetTime 30
    
    Add-TestResult -TestName "Performance Optimization" -Category "Performance" -Passed $performanceTest.Passed -Details $performanceTest.Details -Duration $optimizedDuration.TotalSeconds -PerformanceData @{
        BaselineTime = $baselineResults.ResponseTime.TotalSeconds
        OptimizedTime = $optimizedDuration.TotalSeconds
        ImprovementPercent = $performanceTest.ImprovementPercent
        MeetsTarget = $performanceTest.MeetsTarget
        ContextWindow = $contextInfo.ContextWindow
    }
    
    $script:TestResults.PerformanceComparison = @{
        BaselineTime = $baselineResults.ResponseTime.TotalSeconds
        OptimizedTime = $optimizedDuration.TotalSeconds
        ImprovementPercent = $performanceTest.ImprovementPercent
        TargetAchieved = $performanceTest.MeetsTarget
    }
}
catch {
    Add-TestResult -TestName "Performance Optimization" -Category "Performance" -Passed $false -Details "Exception: $($_.Exception.Message)"
}

#endregion

#region Batch Processing Testing

Write-Host "`n[TEST CATEGORY] Batch Processing Optimization..." -ForegroundColor Yellow

try {
    Write-Host "Testing batch processing capability..." -ForegroundColor White
    $startTime = Get-Date
    
    # Create smaller batch for testing (5 requests)
    $testBatch = $BatchTestRequests[0..4]  # Take first 5 requests
    
    $batchResult = Start-OllamaBatchProcessing -RequestBatch $testBatch -BatchSize 3 -ShowProgress
    $batchDuration = (Get-Date) - $startTime
    
    $batchSuccess = $batchResult.Success -and $batchResult.Results.Count -gt 0
    $parallelEfficiency = $batchResult.ParallelEfficiency
    
    # Calculate theoretical vs actual time
    $theoreticalTime = $testBatch.Count * 30  # 30s per request sequentially
    $actualTime = $batchDuration.TotalSeconds
    $timeReduction = [Math]::Round(($theoreticalTime - $actualTime) / $theoreticalTime * 100, 1)
    
    Add-TestResult -TestName "Batch Processing" -Category "BatchProcessing" -Passed $batchSuccess -Details "Processed: $($batchResult.Results.Count), Efficiency: $parallelEfficiency%, Time reduction: $timeReduction%" -Duration $batchDuration.TotalSeconds -PerformanceData @{
        RequestsProcessed = $batchResult.Results.Count
        ParallelEfficiency = $parallelEfficiency
        TheoreticalTime = $theoreticalTime
        ActualTime = $actualTime
        TimeReduction = $timeReduction
        BatchResults = $batchResult
    }
}
catch {
    Add-TestResult -TestName "Batch Processing" -Category "BatchProcessing" -Passed $false -Details "Exception: $($_.Exception.Message)"
}

#endregion

#region Resource Monitoring and Memory Usage Testing

Write-Host "`n[TEST CATEGORY] Resource Monitoring and Memory Usage..." -ForegroundColor Yellow

try {
    Write-Host "Testing memory usage monitoring..." -ForegroundColor White
    
    # Get baseline memory usage
    $baselineMemory = Get-Process -Name "ollama" -ErrorAction SilentlyContinue | ForEach-Object { [Math]::Round($_.WorkingSet64 / 1MB, 2) }
    
    # Perform several operations to test memory usage
    for ($i = 1; $i -le 3; $i++) {
        $testRequest = @{ CodeContent = $TestCodeSamples.Small; DocumentationType = "Synopsis" }
        $contextInfo = Get-OptimalContextWindow -CodeContent $testRequest.CodeContent -DocumentationType $testRequest.DocumentationType
        Invoke-OllamaOptimizedRequest -Request $testRequest -ContextInfo $contextInfo | Out-Null
    }
    
    # Get performance report with memory monitoring
    $performanceReport = Get-OllamaPerformanceReport -Detailed
    
    $memoryMonitoringWorking = $performanceReport.MemoryUsage.CurrentMemoryMB -gt 0
    $hasOptimizationRecommendations = $performanceReport.PerformanceRecommendations -ne $null
    
    Add-TestResult -TestName "Memory Usage Monitoring" -Category "ResourceMonitoring" -Passed $memoryMonitoringWorking -Details "Memory tracking: $memoryMonitoringWorking, Current: $($performanceReport.MemoryUsage.CurrentMemoryMB)MB" -Data @{
        BaselineMemory = $baselineMemory
        CurrentMemory = $performanceReport.MemoryUsage.CurrentMemoryMB
        PeakMemory = $performanceReport.MemoryUsage.PeakMemoryMB
        PerformanceReport = $performanceReport
        OptimizationStatus = $performanceReport.OptimizationStatus
    }
}
catch {
    Add-TestResult -TestName "Memory Usage Monitoring" -Category "ResourceMonitoring" -Passed $false -Details "Exception: $($_.Exception.Message)"
}

#endregion

#region Stress Testing

Write-Host "`n[TEST CATEGORY] Stress Testing and Scalability..." -ForegroundColor Yellow

try {
    Write-Host "Testing concurrent request handling..." -ForegroundColor White
    $startTime = Get-Date
    
    # Create multiple concurrent requests
    $stressTestRequests = @()
    for ($i = 1; $i -le 6; $i++) {
        $stressTestRequests += @{
            Id = $i
            CodeContent = $TestCodeSamples.Small
            DocumentationType = "Synopsis"
        }
    }
    
    $stressResult = Start-OllamaBatchProcessing -RequestBatch $stressTestRequests -BatchSize 4 -ShowProgress
    $stressDuration = (Get-Date) - $startTime
    
    $stressTestPassed = $stressResult.Success -and $stressResult.Results.Count -eq $stressTestRequests.Count
    $averageResponseTime = if ($stressResult.Results.Count -gt 0) {
        ($stressResult.Results | Where-Object { $_.Success } | ForEach-Object { $_.ResponseTime } | Measure-Object -Average).Average
    } else { 0 }
    
    Add-TestResult -TestName "Concurrent Request Stress Test" -Category "StressTesting" -Passed $stressTestPassed -Details "Requests: $($stressResult.Results.Count), Avg response: $([Math]::Round($averageResponseTime, 2))s" -Duration $stressDuration.TotalSeconds -PerformanceData @{
        ConcurrentRequests = $stressTestRequests.Count
        SuccessfulRequests = ($stressResult.Results | Where-Object { $_.Success } | Measure-Object).Count
        AverageResponseTime = $averageResponseTime
        TotalProcessingTime = $stressDuration.TotalSeconds
        StressTestResults = $stressResult
    }
}
catch {
    Add-TestResult -TestName "Concurrent Request Stress Test" -Category "StressTesting" -Passed $false -Details "Exception: $($_.Exception.Message)"
}

#endregion

#region Hour 7-8 Success Criteria Validation

Write-Host "`n[TEST CATEGORY] Hour 7-8 Success Criteria Validation..." -ForegroundColor Yellow

try {
    Write-Host "Validating comprehensive testing completion..." -ForegroundColor White
    
    # Check if we've tested all optimization scenarios
    $testCategories = ($script:TestResults.Tests | Group-Object Category).Name
    $requiredCategories = @("Optimization", "ContextOptimization", "Performance", "BatchProcessing", "ResourceMonitoring", "StressTesting")
    $allCategoriesTested = $true
    $missingCategories = @()
    
    foreach ($category in $requiredCategories) {
        if ($testCategories -notcontains $category) {
            $allCategoriesTested = $false
            $missingCategories += $category
        }
    }
    
    Add-TestResult -TestName "Comprehensive Testing Coverage" -Category "SuccessCriteria" -Passed $allCategoriesTested -Details "Categories tested: $($testCategories.Count)/$($requiredCategories.Count)" -Data @{
        TestedCategories = $testCategories
        RequiredCategories = $requiredCategories
        MissingCategories = $missingCategories
        ComprehensiveTesting = $allCategoriesTested
    }
}
catch {
    Add-TestResult -TestName "Comprehensive Testing Coverage" -Category "SuccessCriteria" -Passed $false -Details "Exception: $($_.Exception.Message)"
}

try {
    Write-Host "Validating performance optimization effectiveness..." -ForegroundColor White
    
    $performanceImproved = $false
    $performanceDetails = "No performance data available"
    
    if ($script:TestResults.PerformanceComparison -and $script:TestResults.PerformanceComparison.ContainsKey('ImprovementPercent')) {
        $improvementPercent = $script:TestResults.PerformanceComparison.ImprovementPercent
        $targetAchieved = $script:TestResults.PerformanceComparison.TargetAchieved
        
        # Performance is considered improved if we either achieved target or improved by 20%+
        $performanceImproved = $targetAchieved -or ($improvementPercent -ge 20)
        $performanceDetails = "Improvement: $improvementPercent%, Target achieved: $targetAchieved"
    }
    
    Add-TestResult -TestName "Performance Optimization Effectiveness" -Category "SuccessCriteria" -Passed $performanceImproved -Details $performanceDetails -Data @{
        PerformanceComparison = $script:TestResults.PerformanceComparison
        OptimizationEffective = $performanceImproved
    }
}
catch {
    Add-TestResult -TestName "Performance Optimization Effectiveness" -Category "SuccessCriteria" -Passed $false -Details "Exception: $($_.Exception.Message)"
}

try {
    Write-Host "Validating resource usage optimization..." -ForegroundColor White
    
    # Get final performance report
    $finalReport = Get-OllamaPerformanceReport
    
    $resourceOptimized = $finalReport.OptimizationStatus -in @("Optimal", "Good")
    $contextOptimized = $finalReport.ContextWindowAnalysis.OptimizationEffective
    
    Add-TestResult -TestName "Resource Usage Optimization" -Category "SuccessCriteria" -Passed ($resourceOptimized -and $contextOptimized) -Details "Status: $($finalReport.OptimizationStatus), Context optimized: $contextOptimized" -Data @{
        OptimizationStatus = $finalReport.OptimizationStatus
        ContextOptimized = $contextOptimized
        PerformanceRecommendations = $finalReport.PerformanceRecommendations.Count
        FinalReport = $finalReport
    }
    
    # Store optimization metrics for summary
    $script:TestResults.OptimizationMetrics = $finalReport
}
catch {
    Add-TestResult -TestName "Resource Usage Optimization" -Category "SuccessCriteria" -Passed $false -Details "Exception: $($_.Exception.Message)"
}

#endregion

#region Results Summary and Analysis

$script:TestResults.EndTime = Get-Date
$totalTests = ($script:TestResults.Tests | Measure-Object).Count
$passedTests = ($script:TestResults.Tests | Where-Object { $_.Passed } | Measure-Object).Count
$failedTests = $totalTests - $passedTests
$passRate = if ($totalTests -gt 0) { [Math]::Round(($passedTests / $totalTests) * 100, 1) } else { 0 }

# Category analysis
$categoryResults = @{}
$uniqueCategories = $script:TestResults.Tests | ForEach-Object { $_.Category } | Sort-Object -Unique

foreach ($categoryName in $uniqueCategories) {
    $categoryTests = $script:TestResults.Tests | Where-Object { $_.Category -eq $categoryName }
    $categoryPassed = ($categoryTests | Where-Object { $_.Passed } | Measure-Object).Count
    $categoryTotal = ($categoryTests | Measure-Object).Count
    $categoryPassRate = if ($categoryTotal -gt 0) { [Math]::Round(($categoryPassed / $categoryTotal) * 100, 0) } else { 0 }
    
    $categoryResults[$categoryName] = @{
        Passed = $categoryPassed
        Total = $categoryTotal
        Failed = $categoryTotal - $categoryPassed
        PassRate = $categoryPassRate
    }
}

Write-Host "`n[OPTIMIZATION RESULTS SUMMARY]" -ForegroundColor Cyan
foreach ($category in $categoryResults.Keys | Sort-Object) {
    $result = $categoryResults[$category]
    $color = if ($result.PassRate -eq 100) { "Green" } elseif ($result.PassRate -ge 75) { "Yellow" } else { "Red" }
    Write-Host "  ${category}: $($result.Passed)/$($result.Total) ($($result.PassRate)%)" -ForegroundColor $color
}

# Hour 7-8 Success Assessment
Write-Host "`n[HOUR 7-8 SUCCESS ASSESSMENT]" -ForegroundColor Cyan

$successCriteria = @{
    ComprehensiveTestingComplete = ($script:TestResults.Tests | Where-Object { $_.TestName -eq "Comprehensive Testing Coverage" -and $_.Passed }) -ne $null
    PerformanceOptimizationEffective = ($script:TestResults.Tests | Where-Object { $_.TestName -eq "Performance Optimization Effectiveness" -and $_.Passed }) -ne $null
    ResourceUsageOptimized = ($script:TestResults.Tests | Where-Object { $_.TestName -eq "Resource Usage Optimization" -and $_.Passed }) -ne $null
    BatchProcessingOperational = ($script:TestResults.Tests | Where-Object { $_.TestName -eq "Batch Processing" -and $_.Passed }) -ne $null
}

foreach ($criterion in $successCriteria.Keys) {
    $status = if ($successCriteria[$criterion]) { "[ACHIEVED]" } else { "[PENDING]" }
    $color = if ($successCriteria[$criterion]) { "Green" } else { "Red" }
    Write-Host "  $status $criterion" -ForegroundColor $color
}

$overallSuccess = $successCriteria.Values -notcontains $false
$successStatus = if ($overallSuccess) { "[SUCCESS]" } else { "[PARTIAL]" }
$successColor = if ($overallSuccess) { "Green" } else { "Yellow" }

Write-Host "`n$successStatus Hour 7-8 Optimization Success: $(($successCriteria.Values | Where-Object { $_ }).Count)/$(($successCriteria.Keys | Measure-Object).Count) criteria achieved" -ForegroundColor $successColor

# Performance Summary
if ($script:TestResults.PerformanceComparison) {
    Write-Host "`n[PERFORMANCE OPTIMIZATION SUMMARY]" -ForegroundColor Cyan
    $perf = $script:TestResults.PerformanceComparison
    Write-Host "  Baseline Response Time: $([Math]::Round($perf.BaselineTime, 2))s" -ForegroundColor Gray
    Write-Host "  Optimized Response Time: $([Math]::Round($perf.OptimizedTime, 2))s" -ForegroundColor Gray
    Write-Host "  Performance Improvement: $($perf.ImprovementPercent)%" -ForegroundColor $(if($perf.ImprovementPercent -gt 20) {"Green"} elseif($perf.ImprovementPercent -gt 0) {"Yellow"} else {"Red"})
    Write-Host "  Target (<30s) Achieved: $($perf.TargetAchieved)" -ForegroundColor $(if($perf.TargetAchieved) {"Green"} else {"Red"})
}

$script:TestResults.Summary = @{
    TotalTests = $totalTests
    PassedTests = $passedTests
    FailedTests = $failedTests
    PassRate = "$passRate%"
    Categories = $categoryResults
    Duration = ($script:TestResults.EndTime - $script:TestResults.StartTime).ToString()
    Hour7_8Success = $overallSuccess
    Hour7_8SuccessCriteria = $successCriteria
    OptimizationAchieved = $overallSuccess
}

Write-Host "`nOVERALL OPTIMIZATION RESULTS:" -ForegroundColor Cyan
Write-Host "  Total Tests: $totalTests" -ForegroundColor White
Write-Host "  Passed: $passedTests" -ForegroundColor Green
Write-Host "  Failed: $failedTests" -ForegroundColor Red
Write-Host "  Pass Rate: $passRate%" -ForegroundColor White

# Determine completion status
$completionStatus = if ($overallSuccess) { "COMPLETE" } else { "REQUIRES attention" }
$deploymentStatus = if ($overallSuccess -and $passRate -ge 90) { "PRODUCTION READY" } else { "NEEDS optimization" }

Write-Host "`n[HOUR 7-8 COMPLETION STATUS]" -ForegroundColor Cyan
Write-Host "Ollama Integration Optimization: $completionStatus" -ForegroundColor $(if ($overallSuccess) { "Green" } else { "Yellow" })
Write-Host "Performance Optimization Status: $deploymentStatus" -ForegroundColor $(if ($overallSuccess -and $passRate -ge 90) { "Green" } else { "Yellow" })

# Save comprehensive test results
$resultFile = ".\Ollama-Integration-Optimized-TestResults-$(Get-Date -Format 'yyyyMMdd-HHmmss').json"
$script:TestResults | ConvertTo-Json -Depth 15 | Out-File -FilePath $resultFile -Encoding UTF8

Write-Host "`nOptimization test results saved to: $resultFile" -ForegroundColor Gray

Write-Host "`n============================================================" -ForegroundColor Cyan
Write-Host "Ollama Integration Testing and Optimization Complete" -ForegroundColor White
Write-Host "Pass Rate: $passRate% ($passedTests/$totalTests tests)" -ForegroundColor White
Write-Host "Hour 7-8 Status: $completionStatus" -ForegroundColor $(if ($overallSuccess) { "Green" } else { "Yellow" })
Write-Host "Optimization Status: $deploymentStatus" -ForegroundColor $(if ($overallSuccess -and $passRate -ge 90) { "Green" } else { "Yellow" })
Write-Host "============================================================" -ForegroundColor Cyan

#endregion

# Return comprehensive test results
return $script:TestResults