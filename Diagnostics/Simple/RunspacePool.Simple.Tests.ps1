# RunspacePool.Simple.Tests.ps1
# Operation Validation Framework - Simple Tests
# Quick smoke tests for Unity-Claude-RunspaceManagement basic functionality
# Date: 2025-08-21

Describe "Unity-Claude-RunspaceManagement Simple Validation" {
    
    BeforeAll {
        # Import module for testing
        Import-Module "$PSScriptRoot\..\..\Modules\Unity-Claude-RunspaceManagement\Unity-Claude-RunspaceManagement.psd1" -Force
        
        # Create test session state
        $script:TestSessionConfig = New-RunspaceSessionState
        Initialize-SessionStateVariables -SessionStateConfig $script:TestSessionConfig | Out-Null
    }
    
    Context "Basic Module Functionality" {
        
        It "Should load Unity-Claude-RunspaceManagement module" {
            $module = Get-Module -Name Unity-Claude-RunspaceManagement
            $module | Should Not BeNullOrEmpty
            $module.ExportedCommands.Count | Should BeGreaterThan 20
        }
        
        It "Should create session state configuration" {
            $sessionConfig = New-RunspaceSessionState
            $sessionConfig | Should Not BeNullOrEmpty
            $sessionConfig.SessionState | Should Not BeNullOrEmpty
            $sessionConfig.Metadata | Should Not BeNullOrEmpty
        }
        
        It "Should create production runspace pool" {
            $pool = New-ProductionRunspacePool -SessionStateConfig $script:TestSessionConfig -MaxRunspaces 2 -Name "SimpleTestPool"
            $pool | Should Not BeNullOrEmpty
            $pool.RunspacePool | Should Not BeNullOrEmpty
            $pool.Status | Should Be 'Created'
        }
        
        It "Should open runspace pool successfully" {
            $pool = New-ProductionRunspacePool -SessionStateConfig $script:TestSessionConfig -MaxRunspaces 2 -Name "OpenTestPool"
            $result = Open-RunspacePool -PoolManager $pool
            
            $result.Success | Should Be $true
            $pool.Status | Should Be 'Open'
            
            # Cleanup
            Close-RunspacePool -PoolManager $pool | Out-Null
        }
        
        It "Should submit and execute simple job" {
            $pool = New-ProductionRunspacePool -SessionStateConfig $script:TestSessionConfig -MaxRunspaces 2 -Name "JobTestPool"
            Open-RunspacePool -PoolManager $pool | Out-Null
            
            $simpleScript = { param($x) return $x * 2 }
            $job = Submit-RunspaceJob -PoolManager $pool -ScriptBlock $simpleScript -Parameters @{x=5} -JobName "SimpleJob"
            
            $job | Should Not BeNullOrEmpty
            $job.JobId | Should Not BeNullOrEmpty
            $job.Status | Should Be 'Running'
            
            # Wait for completion and verify
            Wait-RunspaceJobs -PoolManager $pool -TimeoutSeconds 5 -ProcessResults | Out-Null
            $results = Get-RunspaceJobResults -PoolManager $pool
            
            $results.CompletedJobs.Count | Should Be 1
            $results.CompletedJobs[0].Result | Should Be 10
            
            # Cleanup
            Close-RunspacePool -PoolManager $pool | Out-Null
        }
    }
    
    Context "Performance Smoke Tests" {
        
        It "Should create pools quickly (under 100ms)" {
            $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
            $pool = New-ProductionRunspacePool -SessionStateConfig $script:TestSessionConfig -MaxRunspaces 2 -Name "PerfSmokePool"
            $stopwatch.Stop()
            
            $stopwatch.ElapsedMilliseconds | Should BeLessThan 100
        }
        
        It "Should submit jobs quickly (under 50ms)" {
            $pool = New-ProductionRunspacePool -SessionStateConfig $script:TestSessionConfig -MaxRunspaces 2 -Name "JobPerfSmokePool"
            Open-RunspacePool -PoolManager $pool | Out-Null
            
            $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
            Submit-RunspaceJob -PoolManager $pool -ScriptBlock { return "Quick" } -JobName "QuickJob" | Out-Null
            $stopwatch.Stop()
            
            $stopwatch.ElapsedMilliseconds | Should BeLessThan 50
            
            # Cleanup
            Close-RunspacePool -PoolManager $pool -Force | Out-Null
        }
    }
    
    Context "Error Handling Smoke Tests" {
        
        It "Should handle closed pool submission gracefully" {
            $pool = New-ProductionRunspacePool -SessionStateConfig $script:TestSessionConfig -MaxRunspaces 2 -Name "ErrorSmokePool"
            # Don't open pool
            
            {
                Submit-RunspaceJob -PoolManager $pool -ScriptBlock { return "ShouldFail" } -JobName "ErrorJob"
            } | Should Throw "*Status: Created*"
        }
        
        It "Should handle job timeouts properly" {
            $pool = New-ProductionRunspacePool -SessionStateConfig $script:TestSessionConfig -MaxRunspaces 2 -Name "TimeoutSmokePool"
            Open-RunspacePool -PoolManager $pool | Out-Null
            
            $timeoutScript = { Start-Sleep -Seconds 10; return "ShouldTimeout" }
            Submit-RunspaceJob -PoolManager $pool -ScriptBlock $timeoutScript -JobName "TimeoutJob" -TimeoutSeconds 1 | Out-Null
            
            $waitResult = Wait-RunspaceJobs -PoolManager $pool -TimeoutSeconds 3 -ProcessResults
            $results = Get-RunspaceJobResults -PoolManager $pool -IncludeFailedJobs
            
            # Use safe array wrapper (Learning #193)
            $timedOutJobs = @($results.FailedJobs | Where-Object { $_.Status -eq 'TimedOut' })
            $timedOutJobs.Count | Should Be 1
            
            # Cleanup
            Close-RunspacePool -PoolManager $pool | Out-Null
        }
    }
}