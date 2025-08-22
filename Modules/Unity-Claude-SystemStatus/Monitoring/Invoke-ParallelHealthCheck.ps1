function Invoke-ParallelHealthCheck {
    <#
    .SYNOPSIS
    Performs parallel health checks for independent subsystems
    
    .DESCRIPTION
    Optimizes health checking by running independent subsystem checks in parallel:
    - Uses ThreadJob module for PowerShell 5.1 compatibility
    - Implements throttling to prevent resource exhaustion
    - Collects results in thread-safe manner
    - Maintains proper error handling across threads
    
    .PARAMETER Manifests
    Array of subsystem manifests to check
    
    .PARAMETER ThrottleLimit
    Maximum number of concurrent health checks (default: 4)
    
    .PARAMETER TimeoutSeconds
    Maximum time to wait for all checks to complete (default: 60)
    
    .PARAMETER IncludePerformanceData
    Include performance metrics in health checks
    
    .EXAMPLE
    Invoke-ParallelHealthCheck -Manifests $manifests -ThrottleLimit 4
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [array]$Manifests,
        
        [int]$ThrottleLimit = 4,
        [int]$TimeoutSeconds = 60,
        [switch]$IncludePerformanceData
    )
    
    Write-SystemStatusLog "Starting parallel health checks for $($Manifests.Count) subsystems" -Level 'INFO'
    
    try {
        # Check if ThreadJob module is available for PowerShell 5.1
        $threadJobAvailable = $false
        try {
            Import-Module ThreadJob -ErrorAction SilentlyContinue
            $threadJobAvailable = $true
            Write-SystemStatusLog "Using ThreadJob module for parallel execution" -Level 'DEBUG'
        } catch {
            Write-SystemStatusLog "ThreadJob module not available, using sequential processing" -Level 'WARN'
        }
        
        # If parallel processing not available, fall back to sequential
        if (-not $threadJobAvailable -or $Manifests.Count -eq 1) {
            Write-SystemStatusLog "Falling back to sequential health checks" -Level 'DEBUG'
            $results = @()
            foreach ($manifest in $Manifests) {
                $result = Test-SubsystemStatus -SubsystemName $manifest.Name -Manifest $manifest -IncludePerformanceData:$IncludePerformanceData
                $results += $result
            }
            return $results
        }
        
        # Parallel execution using ThreadJob
        $jobs = @()
        $results = @()
        $startTime = Get-Date
        
        # Create script block for health check
        $healthCheckScript = {
            param($SubsystemName, $Manifest, $IncludePerformanceData)
            
            # Import module in thread context
            Import-Module "$using:PSScriptRoot\..\Unity-Claude-SystemStatus.psd1" -Force
            
            try {
                $result = Test-SubsystemStatus -SubsystemName $SubsystemName -Manifest $Manifest -IncludePerformanceData:$IncludePerformanceData
                return $result
            } catch {
                return @{
                    SubsystemName = $SubsystemName
                    Timestamp = Get-Date
                    OverallHealthy = $false
                    ProcessRunning = $false
                    ProcessId = $null
                    CustomHealthCheck = $null
                    PerformanceData = $null
                    ErrorDetails = @("Parallel execution error: $($_.Exception.Message)")
                    HealthCheckSource = "ParallelError"
                }
            }
        }
        
        # Start jobs with throttling
        $activeJobs = 0
        $manifestIndex = 0
        
        while ($manifestIndex -lt $Manifests.Count -or $jobs.Count -gt 0) {
            # Start new jobs up to throttle limit
            while ($activeJobs -lt $ThrottleLimit -and $manifestIndex -lt $Manifests.Count) {
                $manifest = $Manifests[$manifestIndex]
                
                Write-SystemStatusLog "Starting parallel health check for $($manifest.Name)" -Level 'DEBUG'
                
                $job = Start-ThreadJob -ScriptBlock $healthCheckScript -ArgumentList $manifest.Name, $manifest, $IncludePerformanceData
                $jobs += @{
                    Job = $job
                    SubsystemName = $manifest.Name
                    StartTime = Get-Date
                }
                
                $activeJobs++
                $manifestIndex++
            }
            
            # Check for completed jobs
            $completedJobs = @()
            $runningJobs = @()
            
            foreach ($jobInfo in $jobs) {
                if ($jobInfo.Job.State -eq "Completed") {
                    $completedJobs += $jobInfo
                } elseif ($jobInfo.Job.State -eq "Running") {
                    $runningJobs += $jobInfo
                } elseif ($jobInfo.Job.State -eq "Failed") {
                    Write-SystemStatusLog "Health check job failed for $($jobInfo.SubsystemName)" -Level 'ERROR'
                    
                    # Create error result
                    $errorResult = @{
                        SubsystemName = $jobInfo.SubsystemName
                        Timestamp = Get-Date
                        OverallHealthy = $false
                        ProcessRunning = $false
                        ProcessId = $null
                        CustomHealthCheck = $null
                        PerformanceData = $null
                        ErrorDetails = @("Job execution failed")
                        HealthCheckSource = "JobFailure"
                    }
                    $results += $errorResult
                    
                    Remove-Job $jobInfo.Job -Force
                    $activeJobs--
                }
            }
            
            # Collect results from completed jobs
            foreach ($jobInfo in $completedJobs) {
                try {
                    $result = Receive-Job $jobInfo.Job
                    $results += $result
                    
                    $duration = ((Get-Date) - $jobInfo.StartTime).TotalMilliseconds
                    Write-SystemStatusLog "Health check completed for $($jobInfo.SubsystemName) in $([math]::Round($duration, 1))ms" -Level 'DEBUG'
                    
                } catch {
                    Write-SystemStatusLog "Error receiving job result for $($jobInfo.SubsystemName): $($_.Exception.Message)" -Level 'ERROR'
                    
                    # Create error result
                    $errorResult = @{
                        SubsystemName = $jobInfo.SubsystemName
                        Timestamp = Get-Date
                        OverallHealthy = $false
                        ProcessRunning = $false
                        ProcessId = $null
                        CustomHealthCheck = $null
                        PerformanceData = $null
                        ErrorDetails = @("Result collection error: $($_.Exception.Message)")
                        HealthCheckSource = "ResultError"
                    }
                    $results += $errorResult
                }
                
                Remove-Job $jobInfo.Job -Force
                $activeJobs--
            }
            
            # Update jobs array
            $jobs = $runningJobs
            
            # Check timeout
            if (((Get-Date) - $startTime).TotalSeconds -gt $TimeoutSeconds) {
                Write-SystemStatusLog "Parallel health check timeout after $TimeoutSeconds seconds" -Level 'ERROR'
                
                # Clean up remaining jobs
                foreach ($jobInfo in $jobs) {
                    try {
                        Stop-Job $jobInfo.Job -PassThru | Remove-Job -Force
                        
                        # Create timeout result
                        $timeoutResult = @{
                            SubsystemName = $jobInfo.SubsystemName
                            Timestamp = Get-Date
                            OverallHealthy = $false
                            ProcessRunning = $false
                            ProcessId = $null
                            CustomHealthCheck = $null
                            PerformanceData = $null
                            ErrorDetails = @("Health check timeout")
                            HealthCheckSource = "Timeout"
                        }
                        $results += $timeoutResult
                        
                    } catch {
                        Write-SystemStatusLog "Error cleaning up job for $($jobInfo.SubsystemName): $($_.Exception.Message)" -Level 'WARN'
                    }
                }
                break
            }
            
            # Brief pause to prevent CPU spinning
            if ($jobs.Count -gt 0) {
                Start-Sleep -Milliseconds 100
            }
        }
        
        $totalDuration = ((Get-Date) - $startTime).TotalMilliseconds
        Write-SystemStatusLog "Parallel health checks completed in $([math]::Round($totalDuration, 1))ms for $($results.Count) subsystems" -Level 'INFO'
        
        return $results
        
    } catch {
        Write-SystemStatusLog "Critical error in parallel health checking: $($_.Exception.Message)" -Level 'ERROR'
        
        # Clean up any remaining jobs
        try {
            Get-Job | Where-Object { $_.Name -like "*ThreadJob*" } | Stop-Job -PassThru | Remove-Job -Force
        } catch {
            Write-SystemStatusLog "Error cleaning up jobs: $($_.Exception.Message)" -Level 'WARN'
        }
        
        throw
    }
}
# SIG # Begin signature block
# MIIFqQYJKoZIhvcNAQcCoIIFmjCCBZYCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUdrHlD7TbQhg085WNRIi1t+Yt
# XC6gggMwMIIDLDCCAhSgAwIBAgIQdR0W2SKoK5VE8JId4ZxrRTANBgkqhkiG9w0B
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
# CQQxFgQU5d5XrHFDLfel06ncTK/coFCEeqAwDQYJKoZIhvcNAQEBBQAEggEAYWeO
# m9UnKh93E7AkLgD1Bjs89QXbaH9b/1hG8Foz16U7UiOjDXicTa6DyU07B+CFe4fn
# mtXjG/Oqv5cZyAAf8lLomSHUUUKIRO0Sy/WK/05ILvTBMUZ2D1Q1tvFqmBEdXeow
# aHRZPikjEUfgVDw1Up3v0yOXyTewlboQdR6JZrdQu7Vqeb7A23kWpsZE5qHM9GPO
# YPz1p+kvJ9VwjU6deTvohuOrxgB8uDrJdxGh7j2YLini+ZNKNosoE0Fp4igRpd/G
# uvXWDZ766dLVPNywd+UYseajmWGolFIR0kUM8PRk1j2Kxw0otKeiLfM2VNEt7i/5
# RRgtFjUNuzRBOPYbrQ==
# SIG # End signature block
