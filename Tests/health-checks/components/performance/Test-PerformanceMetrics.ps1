# Unity-Claude-Automation Performance Metrics Health Check Component
# Tests system performance metrics and resource usage
# Version: 2025-08-25

[CmdletBinding()]
param(
    [ValidateSet('Quick', 'Full', 'Critical', 'Performance')]
    [string]$TestType = 'Quick'
)

# Import shared utilities
Import-Module "$PSScriptRoot\..\..\shared\Test-HealthUtilities.psm1" -Force

function Test-MemoryUsage {
    <#
    .SYNOPSIS
    Test system memory usage
    #>
    
    Write-TestLog "Testing memory usage..." -Level Info
    
    try {
        $memory = Get-WmiObject -Class Win32_ComputerSystem
        $memoryUsage = Get-WmiObject -Class Win32_OperatingSystem
        
        $totalMemoryGB = [math]::Round($memory.TotalPhysicalMemory / 1GB, 2)
        $availableMemoryGB = [math]::Round($memoryUsage.FreePhysicalMemory / 1MB / 1024, 2)
        $usedMemoryGB = $totalMemoryGB - $availableMemoryGB
        $usedMemoryPercentage = [math]::Round(($usedMemoryGB / $totalMemoryGB) * 100, 1)
        
        $metrics = @{
            TotalMemoryGB = $totalMemoryGB
            UsedMemoryGB = $usedMemoryGB
            AvailableMemoryGB = $availableMemoryGB
            UsedPercentage = $usedMemoryPercentage
            MemoryPressure = $usedMemoryPercentage -gt 80
        }
        
        if ($usedMemoryPercentage -gt 90) {
            Add-TestResult -TestName "Memory Usage" -Status 'Fail' -Details "${usedMemoryPercentage}% used (${usedMemoryGB}GB/${totalMemoryGB}GB)" -Metrics $metrics
        } elseif ($usedMemoryPercentage -gt 80) {
            Add-TestResult -TestName "Memory Usage" -Status 'Warning' -Details "${usedMemoryPercentage}% used (${usedMemoryGB}GB/${totalMemoryGB}GB)" -Metrics $metrics
        } else {
            Add-TestResult -TestName "Memory Usage" -Status 'Pass' -Details "${usedMemoryPercentage}% used (${usedMemoryGB}GB/${totalMemoryGB}GB)" -Metrics $metrics
        }
        
    } catch {
        Add-TestResult -TestName "Memory Usage" -Status 'Fail' -Details "Error checking memory: $($_.Exception.Message)"
    }
}

function Test-CPUUsage {
    <#
    .SYNOPSIS
    Test CPU usage over a sampling period
    #>
    
    Write-TestLog "Testing CPU usage (5 second average)..." -Level Info
    
    try {
        # Get CPU usage average over 5 seconds
        $cpuSamples = @()
        for ($i = 0; $i -lt 5; $i++) {
            $sample = (Get-Counter "\Processor(_Total)\% Processor Time" -SampleInterval 1 -MaxSamples 1).CounterSamples[0].CookedValue
            $cpuSamples += $sample
            if ($i -lt 4) { Start-Sleep -Seconds 1 }
        }
        
        $avgCpuUsage = [math]::Round(($cpuSamples | Measure-Object -Average).Average, 1)
        $maxCpuUsage = [math]::Round(($cpuSamples | Measure-Object -Maximum).Maximum, 1)
        $minCpuUsage = [math]::Round(($cpuSamples | Measure-Object -Minimum).Minimum, 1)
        
        $metrics = @{
            AverageCPU = $avgCpuUsage
            MaximumCPU = $maxCpuUsage
            MinimumCPU = $minCpuUsage
            Samples = $cpuSamples
            SampleCount = $cpuSamples.Count
        }
        
        if ($avgCpuUsage -gt 90) {
            Add-TestResult -TestName "CPU Usage" -Status 'Fail' -Details "${avgCpuUsage}% average (peak: ${maxCpuUsage}%)" -Metrics $metrics
        } elseif ($avgCpuUsage -gt 75) {
            Add-TestResult -TestName "CPU Usage" -Status 'Warning' -Details "${avgCpuUsage}% average (peak: ${maxCpuUsage}%)" -Metrics $metrics
        } else {
            Add-TestResult -TestName "CPU Usage" -Status 'Pass' -Details "${avgCpuUsage}% average (peak: ${maxCpuUsage}%)" -Metrics $metrics
        }
        
    } catch {
        Add-TestResult -TestName "CPU Usage" -Status 'Fail' -Details "Error checking CPU: $($_.Exception.Message)"
    }
}

function Test-ProcessMetrics {
    <#
    .SYNOPSIS
    Test metrics for key processes
    #>
    
    if ($TestType -notin @('Performance', 'Full')) {
        return
    }
    
    Write-TestLog "Testing key process metrics..." -Level Info
    
    # Key processes to monitor
    $keyProcesses = @(
        'docker',
        'pwsh',
        'powershell',
        'python',
        'node'
    )
    
    foreach ($processName in $keyProcesses) {
        $testName = "Process Metrics: $processName"
        
        try {
            $processes = Get-Process -Name $processName -ErrorAction SilentlyContinue
            
            if ($processes) {
                $totalMemoryMB = [math]::Round(($processes | Measure-Object -Property WorkingSet64 -Sum).Sum / 1MB, 2)
                $processCount = $processes.Count
                $cpuTime = ($processes | Measure-Object -Property TotalProcessorTime -Sum).Sum.TotalSeconds
                
                $metrics = @{
                    ProcessCount = $processCount
                    TotalMemoryMB = $totalMemoryMB
                    TotalCPUTimeSeconds = [math]::Round($cpuTime, 2)
                    ProcessIDs = $processes.Id
                }
                
                if ($totalMemoryMB -lt 500) {
                    Add-TestResult -TestName $testName -Status 'Pass' -Details "$processCount processes, ${totalMemoryMB}MB total" -Metrics $metrics
                } elseif ($totalMemoryMB -lt 1000) {
                    Add-TestResult -TestName $testName -Status 'Warning' -Details "$processCount processes, ${totalMemoryMB}MB total" -Metrics $metrics
                } else {
                    Add-TestResult -TestName $testName -Status 'Warning' -Details "$processCount processes, ${totalMemoryMB}MB total (high memory)" -Metrics $metrics
                }
            } else {
                Add-TestResult -TestName $testName -Status 'Warning' -Details "No processes found"
            }
            
        } catch {
            Add-TestResult -TestName $testName -Status 'Warning' -Details "Error checking process: $($_.Exception.Message)"
        }
    }
}

function Test-NetworkPerformance {
    <#
    .SYNOPSIS
    Test network performance metrics
    #>
    
    if ($TestType -ne 'Performance') {
        return
    }
    
    Write-TestLog "Testing network performance..." -Level Info
    
    try {
        # Test localhost connectivity
        $testName = "Network Performance: Localhost"
        $startTime = Get-Date
        
        $response = Test-NetConnection -ComputerName "localhost" -Port 80 -InformationLevel Quiet -WarningAction SilentlyContinue
        $duration = [int]((Get-Date) - $startTime).TotalMilliseconds
        
        $metrics = @{
            LocalhostReachable = $response
            TestDuration = $duration
        }
        
        if ($response) {
            Add-TestResult -TestName $testName -Status 'Pass' -Details "Localhost reachable in ${duration}ms" -Metrics $metrics
        } else {
            Add-TestResult -TestName $testName -Status 'Warning' -Details "Localhost not reachable on port 80" -Metrics $metrics
        }
        
    } catch {
        Add-TestResult -TestName "Network Performance: Localhost" -Status 'Warning' -Details "Network test failed: $($_.Exception.Message)"
    }
    
    # Test DNS resolution
    try {
        $testName = "Network Performance: DNS"
        $startTime = Get-Date
        
        $dnsResult = Resolve-DnsName -Name "localhost" -ErrorAction Stop
        $duration = [int]((Get-Date) - $startTime).TotalMilliseconds
        
        $metrics = @{
            DNSResolved = $true
            ResolutionTime = $duration
            ResolvedAddress = $dnsResult.IPAddress
        }
        
        Add-TestResult -TestName $testName -Status 'Pass' -Details "DNS resolved in ${duration}ms" -Metrics $metrics
        
    } catch {
        Add-TestResult -TestName "Network Performance: DNS" -Status 'Warning' -Details "DNS resolution failed: $($_.Exception.Message)"
    }
}

function Test-DiskPerformance {
    <#
    .SYNOPSIS
    Test disk I/O performance
    #>
    
    if ($TestType -ne 'Performance') {
        return
    }
    
    Write-TestLog "Testing disk I/O performance..." -Level Info
    
    try {
        $testName = "Disk Performance: I/O Test"
        
        # Create a temporary file for I/O testing
        $tempFile = Join-Path $env:TEMP "health_check_io_test.tmp"
        $testData = "x" * 1024 * 1024  # 1MB of data
        
        # Test write performance
        $writeStart = Get-Date
        $testData | Out-File -FilePath $tempFile -Encoding ASCII -NoNewline
        $writeTime = [int]((Get-Date) - $writeStart).TotalMilliseconds
        
        # Test read performance
        $readStart = Get-Date
        $readData = Get-Content -Path $tempFile -Raw
        $readTime = [int]((Get-Date) - $readStart).TotalMilliseconds
        
        # Cleanup
        Remove-Item -Path $tempFile -ErrorAction SilentlyContinue
        
        $metrics = @{
            WriteTimeMs = $writeTime
            ReadTimeMs = $readTime
            TestDataSizeMB = 1
            WriteSpeedMBps = [math]::Round(1000 / $writeTime, 2)
            ReadSpeedMBps = [math]::Round(1000 / $readTime, 2)
        }
        
        if ($writeTime -lt 500 -and $readTime -lt 100) {
            Add-TestResult -TestName $testName -Status 'Pass' -Details "Write: ${writeTime}ms, Read: ${readTime}ms" -Metrics $metrics
        } elseif ($writeTime -lt 1000 -and $readTime -lt 500) {
            Add-TestResult -TestName $testName -Status 'Warning' -Details "Write: ${writeTime}ms, Read: ${readTime}ms (acceptable)" -Metrics $metrics
        } else {
            Add-TestResult -TestName $testName -Status 'Warning' -Details "Write: ${writeTime}ms, Read: ${readTime}ms (slow)" -Metrics $metrics
        }
        
    } catch {
        Add-TestResult -TestName "Disk Performance: I/O Test" -Status 'Fail' -Details "Disk I/O test failed: $($_.Exception.Message)"
    }
}

function Test-SystemLoad {
    <#
    .SYNOPSIS
    Test overall system load and responsiveness
    #>
    
    if ($TestType -ne 'Performance') {
        return
    }
    
    Write-TestLog "Testing system load..." -Level Info
    
    try {
        $testName = "System Load: Overall"
        
        # Get system uptime
        $uptime = (Get-WmiObject -Class Win32_OperatingSystem).LastBootUpTime
        $uptimeSpan = (Get-Date) - [Management.ManagementDateTimeConverter]::ToDateTime($uptime)
        
        # Get system responsiveness by measuring command execution time
        $commandStart = Get-Date
        Get-Process | Out-Null
        $commandTime = [int]((Get-Date) - $commandStart).TotalMilliseconds
        
        $metrics = @{
            UptimeDays = [math]::Round($uptimeSpan.TotalDays, 1)
            UptimeHours = [math]::Round($uptimeSpan.TotalHours, 1)
            CommandResponseTime = $commandTime
            LastBootTime = [Management.ManagementDateTimeConverter]::ToDateTime($uptime).ToString('yyyy-MM-dd HH:mm:ss')
        }
        
        if ($commandTime -lt 1000) {
            $status = 'Pass'
            $details = "Responsive (${commandTime}ms), uptime: $([math]::Round($uptimeSpan.TotalDays, 1)) days"
        } elseif ($commandTime -lt 3000) {
            $status = 'Warning'
            $details = "Acceptable (${commandTime}ms), uptime: $([math]::Round($uptimeSpan.TotalDays, 1)) days"
        } else {
            $status = 'Warning'
            $details = "Slow response (${commandTime}ms), uptime: $([math]::Round($uptimeSpan.TotalDays, 1)) days"
        }
        
        Add-TestResult -TestName $testName -Status $status -Details $details -Metrics $metrics
        
    } catch {
        Add-TestResult -TestName "System Load: Overall" -Status 'Fail' -Details "System load test failed: $($_.Exception.Message)"
    }
}

# Main execution function
function Invoke-PerformanceHealthCheck {
    <#
    .SYNOPSIS
    Execute performance health checks based on test type
    #>
    
    if ($TestType -notin @('Performance', 'Full')) {
        Write-TestLog "Skipping performance tests (Test type: $TestType)" -Level Info
        return
    }
    
    Write-TestLog "Starting performance health checks (Type: $TestType)" -Level Info
    
    # Always test memory and CPU for Performance/Full mode
    Test-MemoryUsage
    Test-CPUUsage
    
    # Extended performance tests
    if ($TestType -eq 'Performance') {
        Test-ProcessMetrics
        Test-NetworkPerformance
        Test-DiskPerformance
        Test-SystemLoad
    } elseif ($TestType -eq 'Full') {
        Test-ProcessMetrics
    }
    
    Write-TestLog "Performance health checks completed" -Level Info
}

# Execute if run directly
if ($MyInvocation.InvocationName -ne '.') {
    Invoke-PerformanceHealthCheck
}

# Export functions for module use
Export-ModuleMember -Function @(
    'Invoke-PerformanceHealthCheck',
    'Test-MemoryUsage',
    'Test-CPUUsage',
    'Test-ProcessMetrics',
    'Test-NetworkPerformance',
    'Test-DiskPerformance',
    'Test-SystemLoad'
)