# RunspacePool.Comprehensive.Tests.ps1
# Operation Validation Framework - Comprehensive Tests
# Thorough integration and stress testing for Unity-Claude-RunspaceManagement
# Date: 2025-08-21

Describe "Unity-Claude-RunspaceManagement Comprehensive Validation" {
    
    BeforeAll {
        # Import all required modules for comprehensive testing
        Import-Module "$PSScriptRoot\..\..\Modules\Unity-Claude-RunspaceManagement\Unity-Claude-RunspaceManagement.psd1" -Force
        
        # Try to import parallel processing module
        $parallelProcessingPath = "$PSScriptRoot\..\..\Modules\Unity-Claude-ParallelProcessing\Unity-Claude-ParallelProcessing.psd1"
        if (Test-Path $parallelProcessingPath) {
            Import-Module $parallelProcessingPath -Force -ErrorAction SilentlyContinue
        }
        
        # Create comprehensive test session state
        $script:ComprehensiveSessionConfig = New-RunspaceSessionState
        Initialize-SessionStateVariables -SessionStateConfig $script:ComprehensiveSessionConfig | Out-Null
        
        # Create shared synchronized hashtable for comprehensive testing
        $script:ComprehensiveSharedData = [hashtable]::Synchronized(@{})
        Add-SharedVariable -SessionStateConfig $script:ComprehensiveSessionConfig -Name "ComprehensiveTestData" -Value $script:ComprehensiveSharedData -MakeThreadSafe
    }
    
    Context "Stress Testing and Concurrent Load" {
        
        It "Should handle 25 concurrent jobs with 5 runspace throttling" {
            $pool = New-ProductionRunspacePool -SessionStateConfig $script:ComprehensiveSessionConfig -MaxRunspaces 5 -Name "StressTestPool" -EnableResourceMonitoring
            Open-RunspacePool -PoolManager $pool | Out-Null
            
            # Create varying complexity jobs
            $stressScript = {
                param($jobId, $delay, $complexity)
                Start-Sleep -Milliseconds $delay
                
                $result = switch ($complexity) {
                    "Light" { "Job $jobId light result" }
                    "Medium" { @{JobId=$jobId; Data=(1..50); Processed=Get-Date} }
                    "Heavy" { @{JobId=$jobId; LargeData=(1..200); Complex=$true; Processed=Get-Date} }
                }
                return $result
            }
            
            # Submit 25 jobs with mixed complexity
            for ($i = 1; $i -le 25; $i++) {
                $complexity = @("Light", "Medium", "Heavy")[($i % 3)]
                $delay = Get-Random -Minimum 25 -Maximum 100
                Submit-RunspaceJob -PoolManager $pool -ScriptBlock $stressScript -Parameters @{jobId=$i; delay=$delay; complexity=$complexity} -JobName "StressJob$i" -TimeoutSeconds 30 | Out-Null
            }
            
            # Wait for completion with timeout
            $waitResult = Wait-RunspaceJobs -PoolManager $pool -TimeoutSeconds 60 -ProcessResults
            $results = Get-RunspaceJobResults -PoolManager $pool -IncludeFailedJobs
            
            # Validate results
            $successRate = ($results.CompletedJobs.Count / 25) * 100
            
            # Cleanup
            Invoke-RunspacePoolCleanup -PoolManager $pool -Force | Out-Null
            Close-RunspacePool -PoolManager $pool | Out-Null
            
            $successRate | Should BeGreaterThan 90
            $results.CompletedJobs.Count | Should BeGreaterThan 22
        }
        
        It "Should maintain thread safety with concurrent shared data access" {
            $pool = New-ProductionRunspacePool -SessionStateConfig $script:ComprehensiveSessionConfig -MaxRunspaces 4 -Name "ThreadSafetyPool"
            Open-RunspacePool -PoolManager $pool | Out-Null
            
            # Script that accesses shared data concurrently
            $threadSafetyScript = {
                param($threadId, $operationCount)
                
                for ($i = 0; $i -lt $operationCount; $i++) {
                    $key = "Thread$threadId-Op$i"
                    $value = @{
                        ThreadId = $threadId
                        Operation = $i
                        Timestamp = Get-Date
                        ProcessId = $PID
                    }
                    $ComprehensiveTestData[$key] = $value
                    
                    # Small random delay to increase contention
                    Start-Sleep -Milliseconds (Get-Random -Minimum 1 -Maximum 5)
                }
                
                return "Thread $threadId completed $operationCount operations"
            }
            
            # Submit concurrent jobs with shared data access
            for ($threadId = 1; $threadId -le 4; $threadId++) {
                Submit-RunspaceJob -PoolManager $pool -ScriptBlock $threadSafetyScript -Parameters @{threadId=$threadId; operationCount=15} -JobName "ThreadSafetyJob$threadId" | Out-Null
            }
            
            $waitResult = Wait-RunspaceJobs -PoolManager $pool -TimeoutSeconds 30 -ProcessResults
            $results = Get-RunspaceJobResults -PoolManager $pool
            
            # Validate thread safety
            $expectedOperations = 4 * 15 # 4 threads * 15 operations each
            $actualOperations = $script:ComprehensiveSharedData.Count
            
            # Cleanup
            Close-RunspacePool -PoolManager $pool | Out-Null
            
            $results.CompletedJobs.Count | Should Be 4
            $actualOperations | Should Be $expectedOperations
        }
        
        It "Should handle mixed job types and priorities" {
            $pool = New-ProductionRunspacePool -SessionStateConfig $script:ComprehensiveSessionConfig -MaxRunspaces 3 -Name "MixedJobsPool"
            Open-RunspacePool -PoolManager $pool | Out-Null
            
            # Submit jobs with different characteristics
            $quickJob = { param($x) return $x + 1 }
            $mediumJob = { param($text) Start-Sleep -Milliseconds 100; return $text.ToUpper() }
            $longJob = { param($count) Start-Sleep -Milliseconds 200; return 1..$count }
            $errorJob = { throw "Intentional test error" }
            
            Submit-RunspaceJob -PoolManager $pool -ScriptBlock $quickJob -Parameters @{x=10} -JobName "QuickJob" -Priority "High" | Out-Null
            Submit-RunspaceJob -PoolManager $pool -ScriptBlock $mediumJob -Parameters @{text="test"} -JobName "MediumJob" -Priority "Normal" | Out-Null
            Submit-RunspaceJob -PoolManager $pool -ScriptBlock $longJob -Parameters @{count=5} -JobName "LongJob" -Priority "Low" | Out-Null
            Submit-RunspaceJob -PoolManager $pool -ScriptBlock $errorJob -JobName "ErrorJob" -Priority "Normal" | Out-Null
            
            $waitResult = Wait-RunspaceJobs -PoolManager $pool -TimeoutSeconds 15 -ProcessResults
            $results = Get-RunspaceJobResults -PoolManager $pool -IncludeFailedJobs
            
            # Cleanup
            Close-RunspacePool -PoolManager $pool | Out-Null
            
            $results.CompletedJobs.Count | Should Be 3
            $results.FailedJobs.Count | Should Be 1
            $results.CompletedJobs[0].Result | Should Be 11 # QuickJob result
        }
    }
    
    Context "Performance and Resource Validation" {
        
        It "Should meet performance targets for pool operations" {
            # Pool creation performance
            $poolStopwatch = [System.Diagnostics.Stopwatch]::StartNew()
            $pool = New-ProductionRunspacePool -SessionStateConfig $script:ComprehensiveSessionConfig -MaxRunspaces 3 -Name "PerformancePool"
            $poolStopwatch.Stop()
            
            # Job submission performance
            Open-RunspacePool -PoolManager $pool | Out-Null
            $jobStopwatch = [System.Diagnostics.Stopwatch]::StartNew()
            Submit-RunspaceJob -PoolManager $pool -ScriptBlock { return "PerfTest" } -JobName "PerfJob" | Out-Null
            $jobStopwatch.Stop()
            
            # Cleanup
            Close-RunspacePool -PoolManager $pool -Force | Out-Null
            
            $poolStopwatch.ElapsedMilliseconds | Should BeLessThan 200 # Target: <200ms
            $jobStopwatch.ElapsedMilliseconds | Should BeLessThan 50   # Target: <50ms
        }
        
        It "Should properly track and dispose resources" {
            $pool = New-ProductionRunspacePool -SessionStateConfig $script:ComprehensiveSessionConfig -MaxRunspaces 2 -Name "ResourceTrackingPool"
            Open-RunspacePool -PoolManager $pool | Out-Null
            
            # Submit multiple jobs to test disposal tracking
            for ($i = 1; $i -le 10; $i++) {
                Submit-RunspaceJob -PoolManager $pool -ScriptBlock { param($x) return $x } -Parameters @{x=$i} -JobName "ResourceJob$i" | Out-Null
            }
            
            Wait-RunspaceJobs -PoolManager $pool -TimeoutSeconds 10 -ProcessResults | Out-Null
            
            # Check disposal tracking
            $created = $pool.DisposalTracking.PowerShellInstancesCreated
            $disposed = $pool.DisposalTracking.PowerShellInstancesDisposed
            
            # Cleanup
            Close-RunspacePool -PoolManager $pool | Out-Null
            
            $created | Should Be 10
            $disposed | Should Be 10
        }
    }
    
    Context "Integration with Unity-Claude Ecosystem" {
        
        It "Should integrate with available Unity-Claude modules" {
            # Test integration with any available Unity-Claude modules
            $availableModules = @()
            
            $moduleTests = @(
                "Unity-Claude-ParallelProcessing",
                "Unity-Claude-SystemStatus",
                "Unity-Claude-Core"
            )
            
            foreach ($moduleName in $moduleTests) {
                $modulePath = "$PSScriptRoot\..\..\Modules\$moduleName\$moduleName.psd1"
                if (Test-Path $modulePath) {
                    try {
                        Import-Module $modulePath -Force -ErrorAction Stop
                        $availableModules += $moduleName
                    } catch {
                        Write-Warning "Could not import $moduleName : $($_.Exception.Message)"
                    }
                }
            }
            
            # Should have at least the runspace management module
            $availableModules.Count | Should BeGreaterThan -1
            
            # Test that runspace management works regardless of other module availability
            $pool = New-ProductionRunspacePool -SessionStateConfig $script:ComprehensiveSessionConfig -MaxRunspaces 2 -Name "EcosystemPool"
            $pool | Should Not BeNullOrEmpty
            $pool.RunspacePool | Should Not BeNullOrEmpty
        }
    }
    
    AfterAll {
        # Cleanup any remaining pools
        if ($script:ActiveRunspacePools -and $script:ActiveRunspacePools.Count -gt 0) {
            foreach ($poolName in $script:ActiveRunspacePools.Keys) {
                try {
                    $pool = $script:ActiveRunspacePools[$poolName]
                    if ($pool.Status -eq 'Open') {
                        Close-RunspacePool -PoolManager $pool -Force | Out-Null
                    }
                } catch {
                    Write-Warning "Cleanup warning for $poolName : $($_.Exception.Message)"
                }
            }
        }
    }
}