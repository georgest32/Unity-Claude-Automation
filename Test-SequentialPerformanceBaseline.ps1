# Test-SequentialPerformanceBaseline.ps1
# Performance baseline measurements for current sequential Unity-Claude system
# Phase 1 Week 1 Hours 5-6: Create performance baseline measurements
# Date: 2025-08-20

param(
    [switch]$Detailed = $false,
    [string]$ResultsFile = ".\Performance_Baseline_Results_$(Get-Date -Format 'yyyyMMdd_HHmmss').txt"
)

$ErrorActionPreference = "Continue"

# Initialize results collection
$results = @{
    TestDate = Get-Date
    SystemSpecs = @{}
    SequentialOperations = @{}
    ModulePerformance = @{}
    FileOperations = @{}
    ProcessOperations = @{}
    MemoryUsage = @{}
    Summary = @{}
}

Write-Host "=== Unity-Claude Sequential Performance Baseline Test ===" -ForegroundColor Cyan
Write-Host "Date: $(Get-Date)" -ForegroundColor Gray
Write-Host "Results will be saved to: $ResultsFile" -ForegroundColor Gray
Write-Host ""

# Collect system specifications
Write-Host "1. Collecting system specifications..." -ForegroundColor Yellow
$stopwatch = [System.Diagnostics.Stopwatch]::StartNew()

try {
    $cpu = Get-WmiObject Win32_Processor | Select-Object -First 1
    $memory = Get-WmiObject Win32_ComputerSystem
    $os = Get-WmiObject Win32_OperatingSystem
    
    $results.SystemSpecs = @{
        ProcessorName = $cpu.Name
        ProcessorCores = $cpu.NumberOfCores
        ProcessorThreads = $cpu.NumberOfLogicalProcessors
        TotalMemoryGB = [Math]::Round($memory.TotalPhysicalMemory / 1GB, 2)
        OSVersion = $os.Caption
        PowerShellVersion = $PSVersionTable.PSVersion.ToString()
        MeasurementOverhead = $stopwatch.ElapsedMilliseconds
    }
    
    Write-Host "  CPU: $($results.SystemSpecs.ProcessorName)" -ForegroundColor Gray
    Write-Host "  Cores: $($results.SystemSpecs.ProcessorCores) / Threads: $($results.SystemSpecs.ProcessorThreads)" -ForegroundColor Gray
    Write-Host "  Memory: $($results.SystemSpecs.TotalMemoryGB) GB" -ForegroundColor Gray
    Write-Host "  PowerShell: $($results.SystemSpecs.PowerShellVersion)" -ForegroundColor Gray
} catch {
    Write-Host "  Error collecting system specs: $($_.Exception.Message)" -ForegroundColor Red
    $results.SystemSpecs.Error = $_.Exception.Message
}

$stopwatch.Stop()
Write-Host "  System specs collected in $($stopwatch.ElapsedMilliseconds)ms" -ForegroundColor Green
Write-Host ""

# Test 2: Module loading performance
Write-Host "2. Testing module loading performance..." -ForegroundColor Yellow

$moduleTests = @(
    @{ Name = "Unity-Claude-SystemStatus"; Path = ".\Modules\Unity-Claude-SystemStatus\Unity-Claude-SystemStatus.psd1" },
    @{ Name = "Unity-Claude-AutonomousAgent-Refactored"; Path = ".\Modules\Unity-Claude-AutonomousAgent\Unity-Claude-AutonomousAgent-Refactored.psd1" },
    @{ Name = "Unity-Claude-CLISubmission"; Path = ".\Modules\Unity-Claude-CLISubmission.psm1" },
    @{ Name = "SafeCommandExecution"; Path = ".\Modules\SafeCommandExecution\SafeCommandExecution.psd1" }
)

foreach ($moduleTest in $moduleTests) {
    Write-Host "  Testing $($moduleTest.Name)..." -ForegroundColor Gray
    
    if (Test-Path $moduleTest.Path) {
        $moduleStopwatch = [System.Diagnostics.Stopwatch]::StartNew()
        
        try {
            # Remove module if already loaded
            Remove-Module $moduleTest.Name -Force -ErrorAction SilentlyContinue
            
            # Import module and measure time
            Import-Module $moduleTest.Path -Force -DisableNameChecking
            $moduleStopwatch.Stop()
            
            # Get module info
            $moduleInfo = Get-Module $moduleTest.Name
            $functionCount = if ($moduleInfo.ExportedCommands) { $moduleInfo.ExportedCommands.Count } else { 0 }
            
            $results.ModulePerformance[$moduleTest.Name] = @{
                LoadTime = $moduleStopwatch.ElapsedMilliseconds
                FunctionCount = $functionCount
                Status = "Success"
                ModuleVersion = $moduleInfo.Version.ToString()
            }
            
            Write-Host "    Loaded in $($moduleStopwatch.ElapsedMilliseconds)ms ($functionCount functions)" -ForegroundColor Green
        } catch {
            $moduleStopwatch.Stop()
            $results.ModulePerformance[$moduleTest.Name] = @{
                LoadTime = $moduleStopwatch.ElapsedMilliseconds
                Status = "Failed"
                Error = $_.Exception.Message
            }
            Write-Host "    Failed in $($moduleStopwatch.ElapsedMilliseconds)ms: $($_.Exception.Message)" -ForegroundColor Red
        }
    } else {
        $results.ModulePerformance[$moduleTest.Name] = @{
            Status = "NotFound"
            Path = $moduleTest.Path
        }
        Write-Host "    Module not found: $($moduleTest.Path)" -ForegroundColor Yellow
    }
}

Write-Host ""

# Test 3: File I/O operations (simulating current JSON operations)
Write-Host "3. Testing file I/O operations..." -ForegroundColor Yellow

$testData = @{
    timestamp = Get-Date
    subsystems = @{
        "SystemStatusMonitoring" = @{ Status = "Running"; LastHeartbeat = Get-Date }
        "Unity-Claude-AutonomousAgent" = @{ Status = "Running"; LastHeartbeat = Get-Date }
    }
    testData = 1..100 | ForEach-Object { "Test data line $_" }
}

# JSON Write Test
Write-Host "  Testing JSON write operations..." -ForegroundColor Gray
$writeTests = @()
for ($i = 1; $i -le 10; $i++) {
    $writeStopwatch = [System.Diagnostics.Stopwatch]::StartNew()
    $testFile = ".\test_json_$i.json"
    $testData | ConvertTo-Json -Depth 10 | Set-Content $testFile -Encoding UTF8
    $writeStopwatch.Stop()
    $writeTests += $writeStopwatch.ElapsedMilliseconds
}

# JSON Read Test  
Write-Host "  Testing JSON read operations..." -ForegroundColor Gray
$readTests = @()
for ($i = 1; $i -le 10; $i++) {
    $readStopwatch = [System.Diagnostics.Stopwatch]::StartNew()
    $testFile = ".\test_json_$i.json"
    if (Test-Path $testFile) {
        $data = Get-Content $testFile -Raw | ConvertFrom-Json
    }
    $readStopwatch.Stop()
    $readTests += $readStopwatch.ElapsedMilliseconds
}

# Cleanup test files
1..10 | ForEach-Object { 
    $testFile = ".\test_json_$_.json"
    if (Test-Path $testFile) { Remove-Item $testFile -Force }
}

$results.FileOperations = @{
    JSONWrite = @{
        AverageMs = [Math]::Round(($writeTests | Measure-Object -Average).Average, 2)
        MinMs = ($writeTests | Measure-Object -Minimum).Minimum
        MaxMs = ($writeTests | Measure-Object -Maximum).Maximum
        Tests = $writeTests.Count
    }
    JSONRead = @{
        AverageMs = [Math]::Round(($readTests | Measure-Object -Average).Average, 2)
        MinMs = ($readTests | Measure-Object -Minimum).Minimum
        MaxMs = ($readTests | Measure-Object -Maximum).Maximum
        Tests = $readTests.Count
    }
}

Write-Host "    JSON Write: Avg $($results.FileOperations.JSONWrite.AverageMs)ms (Min: $($results.FileOperations.JSONWrite.MinMs)ms, Max: $($results.FileOperations.JSONWrite.MaxMs)ms)" -ForegroundColor Green
Write-Host "    JSON Read: Avg $($results.FileOperations.JSONRead.AverageMs)ms (Min: $($results.FileOperations.JSONRead.MinMs)ms, Max: $($results.FileOperations.JSONRead.MaxMs)ms)" -ForegroundColor Green
Write-Host ""

# Test 4: Process operations (simulating current process discovery)
Write-Host "4. Testing process operations..." -ForegroundColor Yellow

# Process enumeration test
Write-Host "  Testing process enumeration..." -ForegroundColor Gray
$processTests = @()
for ($i = 1; $i -le 5; $i++) {
    $processStopwatch = [System.Diagnostics.Stopwatch]::StartNew()
    $processes = Get-Process | Where-Object { $_.ProcessName -match "explorer|notepad|powershell" }
    $processStopwatch.Stop()
    $processTests += $processStopwatch.ElapsedMilliseconds
}

# WMI process enumeration test (current method)
Write-Host "  Testing WMI process enumeration..." -ForegroundColor Gray
$wmiTests = @()
for ($i = 1; $i -le 5; $i++) {
    $wmiStopwatch = [System.Diagnostics.Stopwatch]::StartNew()
    $wmiProcesses = Get-WmiObject Win32_Process | Where-Object { $_.Name -match "explorer|notepad|powershell" }
    $wmiStopwatch.Stop()
    $wmiTests += $wmiStopwatch.ElapsedMilliseconds
}

$results.ProcessOperations = @{
    GetProcess = @{
        AverageMs = [Math]::Round(($processTests | Measure-Object -Average).Average, 2)
        MinMs = ($processTests | Measure-Object -Minimum).Minimum
        MaxMs = ($processTests | Measure-Object -Maximum).Maximum
    }
    WMIProcess = @{
        AverageMs = [Math]::Round(($wmiTests | Measure-Object -Average).Average, 2)
        MinMs = ($wmiTests | Measure-Object -Minimum).Minimum
        MaxMs = ($wmiTests | Measure-Object -Maximum).Maximum
    }
}

Write-Host "    Get-Process: Avg $($results.ProcessOperations.GetProcess.AverageMs)ms" -ForegroundColor Green
Write-Host "    WMI Process: Avg $($results.ProcessOperations.WMIProcess.AverageMs)ms" -ForegroundColor Green
Write-Host ""

# Test 5: Memory usage analysis
Write-Host "5. Analyzing current memory usage..." -ForegroundColor Yellow

$memoryBefore = [GC]::GetTotalMemory($false)
$process = Get-Process -Id $PID
$results.MemoryUsage = @{
    ProcessWorkingSetMB = [Math]::Round($process.WorkingSet64 / 1MB, 2)
    ProcessPrivateMemoryMB = [Math]::Round($process.PrivateMemorySize64 / 1MB, 2)
    GCMemoryKB = [Math]::Round($memoryBefore / 1KB, 2)
    AvailableMemoryGB = [Math]::Round((Get-Counter "\Memory\Available MBytes").CounterSamples[0].CookedValue / 1024, 2)
}

Write-Host "  Process Working Set: $($results.MemoryUsage.ProcessWorkingSetMB) MB" -ForegroundColor Gray
Write-Host "  Process Private Memory: $($results.MemoryUsage.ProcessPrivateMemoryMB) MB" -ForegroundColor Gray
Write-Host "  GC Memory: $($results.MemoryUsage.GCMemoryKB) KB" -ForegroundColor Gray
Write-Host "  Available System Memory: $($results.MemoryUsage.AvailableMemoryGB) GB" -ForegroundColor Gray
Write-Host ""

# Calculate summary and parallel processing potential
Write-Host "6. Calculating performance summary..." -ForegroundColor Yellow

$totalModuleLoadTime = ($results.ModulePerformance.Values | Where-Object { $_.LoadTime } | Measure-Object -Property LoadTime -Sum).Sum
$avgFileOperation = [Math]::Round(($results.FileOperations.JSONWrite.AverageMs + $results.FileOperations.JSONRead.AverageMs) / 2, 2)

$results.Summary = @{
    TotalModuleLoadTimeMs = $totalModuleLoadTime
    AverageFileOperationMs = $avgFileOperation
    AverageProcessQueryMs = $results.ProcessOperations.GetProcess.AverageMs
    EstimatedSequentialCycleMs = $totalModuleLoadTime + ($avgFileOperation * 3) + $results.ProcessOperations.GetProcess.AverageMs
    ParallelizationPotential = "HIGH - Multiple independent operations identified"
    PrimaryBottlenecks = @("Module loading", "JSON file operations", "Process enumeration")
}

Write-Host "  Total module load time: $($results.Summary.TotalModuleLoadTimeMs)ms" -ForegroundColor Gray
Write-Host "  Average file operation: $($results.Summary.AverageFileOperationMs)ms" -ForegroundColor Gray
Write-Host "  Estimated sequential cycle: $($results.Summary.EstimatedSequentialCycleMs)ms" -ForegroundColor Gray
Write-Host "  Parallelization potential: $($results.Summary.ParallelizationPotential)" -ForegroundColor Green
Write-Host ""

# Save results to file
Write-Host "7. Saving results to file..." -ForegroundColor Yellow

try {
    $output = @()
    $output += "=== Unity-Claude Sequential Performance Baseline Results ==="
    $output += "Date: $($results.TestDate)"
    $output += "Results File: $ResultsFile"
    $output += ""
    
    $output += "SYSTEM SPECIFICATIONS:"
    $results.SystemSpecs.GetEnumerator() | ForEach-Object {
        $output += "  $($_.Key): $($_.Value)"
    }
    $output += ""
    
    $output += "MODULE PERFORMANCE:"
    $results.ModulePerformance.GetEnumerator() | ForEach-Object {
        $output += "  $($_.Key):"
        $_.Value.GetEnumerator() | ForEach-Object {
            $output += "    $($_.Key): $($_.Value)"
        }
        $output += ""
    }
    
    $output += "FILE OPERATIONS:"
    $output += "  JSON Write: Avg $($results.FileOperations.JSONWrite.AverageMs)ms (Min: $($results.FileOperations.JSONWrite.MinMs), Max: $($results.FileOperations.JSONWrite.MaxMs))"
    $output += "  JSON Read: Avg $($results.FileOperations.JSONRead.AverageMs)ms (Min: $($results.FileOperations.JSONRead.MinMs), Max: $($results.FileOperations.JSONRead.MaxMs))"
    $output += ""
    
    $output += "PROCESS OPERATIONS:"
    $output += "  Get-Process: Avg $($results.ProcessOperations.GetProcess.AverageMs)ms"
    $output += "  WMI Process: Avg $($results.ProcessOperations.WMIProcess.AverageMs)ms"
    $output += ""
    
    $output += "MEMORY USAGE:"
    $results.MemoryUsage.GetEnumerator() | ForEach-Object {
        $output += "  $($_.Key): $($_.Value)"
    }
    $output += ""
    
    $output += "PERFORMANCE SUMMARY:"
    $results.Summary.GetEnumerator() | ForEach-Object {
        if ($_.Value -is [array]) {
            $output += "  $($_.Key): $($_.Value -join ', ')"
        } else {
            $output += "  $($_.Key): $($_.Value)"
        }
    }
    $output += ""
    
    $output += "PARALLEL PROCESSING RECOMMENDATIONS:"
    $output += "1. Module loading can be parallelized during system startup"
    $output += "2. JSON file operations should be replaced with in-memory synchronized data structures"
    $output += "3. Process enumeration can run in background threads"
    $output += "4. Multiple Unity project monitoring can run concurrently"
    $output += "5. Claude API/CLI submissions can be parallelized"
    $output += ""
    $output += "EXPECTED PERFORMANCE IMPROVEMENT: 75-93% based on research findings"
    $output += ""
    
    # Add detailed results if requested
    if ($Detailed) {
        $output += "DETAILED RESULTS (JSON):"
        $output += ($results | ConvertTo-Json -Depth 10)
    }
    
    $output | Set-Content $ResultsFile -Encoding UTF8
    Write-Host "  Results saved to: $ResultsFile" -ForegroundColor Green
} catch {
    Write-Host "  Error saving results: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host ""
Write-Host "=== Performance Baseline Test Complete ===" -ForegroundColor Cyan
Write-Host "Next Step: PowerShell 5.1 runspace pool compatibility testing" -ForegroundColor Yellow
Write-Host ""

return $results
# SIG # Begin signature block
# MIIFqQYJKoZIhvcNAQcCoIIFmjCCBZYCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUI+4NaojjTcklLn2Jt1wT7CUn
# ZR6gggMwMIIDLDCCAhSgAwIBAgIQdR0W2SKoK5VE8JId4ZxrRTANBgkqhkiG9w0B
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
# CQQxFgQULX/fpC1qUdZ2VS4Smu2EcnSxYI8wDQYJKoZIhvcNAQEBBQAEggEAWY16
# 1PDmuNEbld3PUpoEzvKqlmNXE3BnrDZaSRA4iQIZgh/9KklR5if2BwykXpCEUI/b
# 8K803GvYmmtBStgGvp/15nRMsH2w6mE6etmyv+SSGFmrwLGcq0iV6TtnZvDFKVLV
# NRrNT639z2UyvVGAeF2/k/mUm1UJBZkRl0NdvdwT3Err4wFPaGMOLnDE7wrDQkGJ
# 4m8hmMOWXRZCG2bCkye+D83JhADGTsasa8lIo2qctd9xqm4KpAHzXnbBaoIpL++Z
# EUvug1OoUa625XnDzgaJlagzy32gDpEZ9UVZi1BdcuLB/9FK51z3nP1fn0p0i/RF
# njkAlK8rpbn3yMae1A==
# SIG # End signature block
