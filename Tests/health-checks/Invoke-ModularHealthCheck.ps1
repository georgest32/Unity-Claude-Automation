# Unity-Claude-Automation Modular Health Check Orchestrator
# Coordinates all health check components in a modular architecture
# Version: 2025-08-25

[CmdletBinding()]
param(
    [Parameter(HelpMessage = "Type of health check to perform")]
    [ValidateSet('Quick', 'Full', 'Critical', 'Performance')]
    [string]$TestType = 'Quick',
    
    [Parameter(HelpMessage = "Directory to save test results")]
    [string]$OutputPath = '.\health-reports',
    
    [Parameter(HelpMessage = "Specific components to test (leave empty for all)")]
    [ValidateSet('Docker', 'PowerShell', 'API', 'FileSystem', 'Performance', 'All')]
    [string[]]$Components = @('All'),
    
    [Parameter(HelpMessage = "Save results to file")]
    [switch]$SaveResults,
    
    [Parameter(HelpMessage = "Enable detailed testing")]
    [switch]$Detailed,
    
    [Parameter(HelpMessage = "Include performance metrics")]
    [switch]$IncludeMetrics,
    
    [Parameter(HelpMessage = "Generate HTML report")]
    [switch]$GenerateReport,
    
    [Parameter(HelpMessage = "Run tests in parallel where possible")]
    [switch]$Parallel,
    
    [Parameter(HelpMessage = "Show progress during execution")]
    [switch]$ShowProgress
)

$ErrorActionPreference = 'Continue'
$ProgressPreference = if ($ShowProgress) { 'Continue' } else { 'SilentlyContinue' }

# Import shared utilities
$sharedUtilitiesPath = Join-Path $PSScriptRoot "shared\Test-HealthUtilities.psm1"
if (-not (Test-Path $sharedUtilitiesPath)) {
    Write-Error "Shared utilities module not found at: $sharedUtilitiesPath"
    exit 1
}

Import-Module $sharedUtilitiesPath -Force

# Component configuration
$ComponentConfig = @{
    Docker = @{
        Name = "Docker Services"
        ScriptPath = "components\docker\Test-DockerHealth.ps1"
        Priority = 1
        Required = $true
        Description = "Docker daemon and container health"
    }
    PowerShell = @{
        Name = "PowerShell Modules"
        ScriptPath = "components\powershell\Test-PowerShellModules.ps1"
        Priority = 2
        Required = $true
        Description = "PowerShell module integrity and functionality"
    }
    API = @{
        Name = "API Services"
        ScriptPath = "components\api\Test-APIHealth.ps1"
        Priority = 3
        Required = $true
        Description = "Service endpoints and API functionality"
    }
    FileSystem = @{
        Name = "File System"
        ScriptPath = "components\filesystem\Test-FileSystemHealth.ps1"
        Priority = 4
        Required = $false
        Description = "Directory structure and disk space"
    }
    Performance = @{
        Name = "Performance Metrics"
        ScriptPath = "components\performance\Test-PerformanceMetrics.ps1"
        Priority = 5
        Required = $false
        Description = "System performance and resource usage"
    }
}

function Get-ComponentsToTest {
    <#
    .SYNOPSIS
    Determine which components to test based on parameters
    #>
    
    if ($Components -contains 'All' -or $Components.Count -eq 0) {
        # Return all components, filtered by test type
        $componentsToTest = $ComponentConfig.Keys
        
        # Filter components based on test type
        switch ($TestType) {
            'Quick' {
                # Quick test - only required components
                $componentsToTest = $ComponentConfig.Keys | Where-Object { $ComponentConfig[$_].Required }
            }
            'Critical' {
                # Critical test - all except performance unless specifically requested
                $componentsToTest = $ComponentConfig.Keys | Where-Object { $_ -ne 'Performance' }
            }
            'Performance' {
                # Performance test - all components
                $componentsToTest = $ComponentConfig.Keys
            }
            'Full' {
                # Full test - all components
                $componentsToTest = $ComponentConfig.Keys
            }
        }
        
        return $componentsToTest
    } else {
        # Return only specified components
        return $Components | Where-Object { $ComponentConfig.ContainsKey($_) }
    }
}

function Test-ComponentPrerequisites {
    <#
    .SYNOPSIS
    Test if component scripts exist and are accessible
    #>
    param([string[]]$ComponentNames)
    
    $missingComponents = @()
    
    foreach ($componentName in $ComponentNames) {
        $config = $ComponentConfig[$componentName]
        $scriptPath = Join-Path $PSScriptRoot $config.ScriptPath
        
        if (-not (Test-Path $scriptPath)) {
            $missingComponents += @{
                Name = $componentName
                ScriptPath = $scriptPath
                Description = $config.Description
            }
        }
    }
    
    if ($missingComponents.Count -gt 0) {
        Write-TestLog "Missing component scripts:" -Level Error
        foreach ($missing in $missingComponents) {
            Write-TestLog "  $($missing.Name): $($missing.ScriptPath)" -Level Error
        }
        return $false
    }
    
    return $true
}

function Invoke-ComponentHealthCheck {
    <#
    .SYNOPSIS
    Execute a single component health check
    #>
    param(
        [string]$ComponentName,
        [hashtable]$Config
    )
    
    $scriptPath = Join-Path $PSScriptRoot $Config.ScriptPath
    
    try {
        Write-TestLog "Starting $($Config.Name) health check..." -Level Info
        
        # Prepare parameters for component script
        $componentParams = @{
            TestType = $TestType
        }
        
        if ($Detailed) {
            $componentParams.Detailed = $true
        }
        
        # Additional parameters for specific components
        switch ($ComponentName) {
            'PowerShell' {
                if ($TestType -eq 'Performance') {
                    $componentParams.TestFunctionality = $true
                }
            }
        }
        
        # Execute component script
        $job = Start-Job -ScriptBlock {
            param($ScriptPath, $Params)
            
            # Change to the script directory
            $scriptDir = Split-Path $ScriptPath -Parent
            Set-Location $scriptDir
            
            # Execute the script with parameters
            & $ScriptPath @Params
            
        } -ArgumentList $scriptPath, $componentParams
        
        # Wait for completion with timeout
        $timeoutMinutes = switch ($TestType) {
            'Performance' { 10 }
            'Full' { 5 }
            default { 3 }
        }
        
        $completed = $job | Wait-Job -Timeout ($timeoutMinutes * 60)
        
        if ($completed) {
            $results = Receive-Job -Job $job
            Remove-Job -Job $job
            
            Write-TestLog "$($Config.Name) health check completed" -Level Success
            return @{ Success = $true; Results = $results }
        } else {
            Stop-Job -Job $job
            Remove-Job -Job $job
            
            Add-TestResult -TestName "$($Config.Name) Component" -Status 'Fail' -Details "Component test timed out after $timeoutMinutes minutes"
            return @{ Success = $false; Error = "Timeout" }
        }
        
    } catch {
        Add-TestResult -TestName "$($Config.Name) Component" -Status 'Fail' -Details "Component execution failed: $($_.Exception.Message)"
        return @{ Success = $false; Error = $_.Exception.Message }
    }
}

function Invoke-ParallelHealthChecks {
    <#
    .SYNOPSIS
    Execute health checks in parallel for better performance
    #>
    param([string[]]$ComponentNames)
    
    Write-TestLog "Running health checks in parallel..." -Level Info
    
    $jobs = @()
    
    # Start all component jobs
    foreach ($componentName in $ComponentNames) {
        $config = $ComponentConfig[$componentName]
        
        $job = Start-Job -Name "HealthCheck-$componentName" -ScriptBlock {
            param($ComponentName, $Config, $ScriptRoot, $TestType, $Detailed)
            
            # Import utilities in job context
            $sharedUtilitiesPath = Join-Path $ScriptRoot "shared\Test-HealthUtilities.psm1"
            Import-Module $sharedUtilitiesPath -Force
            
            # Initialize health check for this component
            Initialize-HealthCheck -TestType $TestType
            
            # Execute component
            $scriptPath = Join-Path $ScriptRoot $Config.ScriptPath
            
            $componentParams = @{
                TestType = $TestType
            }
            
            if ($Detailed) {
                $componentParams.Detailed = $true
            }
            
            & $scriptPath @componentParams
            
            # Return results
            return Get-TestResults
            
        } -ArgumentList $componentName, $ComponentConfig[$componentName], $PSScriptRoot, $TestType, $Detailed
        
        $jobs += @{
            Job = $job
            ComponentName = $componentName
            Config = $ComponentConfig[$componentName]
        }
    }
    
    # Wait for all jobs to complete
    $completedJobs = @()
    $timeoutSeconds = 300  # 5 minutes total timeout
    
    $timeout = (Get-Date).AddSeconds($timeoutSeconds)
    
    while ($jobs.Count -gt 0 -and (Get-Date) -lt $timeout) {
        $runningJobs = $jobs | Where-Object { $_.Job.State -eq 'Running' }
        $finishedJobs = $jobs | Where-Object { $_.Job.State -ne 'Running' }
        
        # Process finished jobs
        foreach ($finishedJob in $finishedJobs) {
            $results = Receive-Job -Job $finishedJob.Job
            
            if ($results -and $results.Results) {
                # Merge results from component
                foreach ($result in $results.Results) {
                    Add-TestResult -TestName $result.TestName -Status $result.Status -Details $result.Details -Metrics $result.Metrics -Duration $result.Duration
                }
            }
            
            Remove-Job -Job $finishedJob.Job
            $completedJobs += $finishedJob
            $jobs = $jobs | Where-Object { $_.ComponentName -ne $finishedJob.ComponentName }
        }
        
        if ($runningJobs.Count -gt 0) {
            Start-Sleep -Seconds 1
        }
    }
    
    # Handle remaining jobs (timeouts)
    foreach ($remainingJob in $jobs) {
        Stop-Job -Job $remainingJob.Job
        Remove-Job -Job $remainingJob.Job
        Add-TestResult -TestName "$($remainingJob.Config.Name) Component" -Status 'Fail' -Details "Component test timed out"
    }
    
    Write-TestLog "Parallel health checks completed" -Level Info
}

function Invoke-SequentialHealthChecks {
    <#
    .SYNOPSIS
    Execute health checks sequentially
    #>
    param([string[]]$ComponentNames)
    
    Write-TestLog "Running health checks sequentially..." -Level Info
    
    # Sort components by priority
    $sortedComponents = $ComponentNames | Sort-Object { $ComponentConfig[$_].Priority }
    
    foreach ($componentName in $sortedComponents) {
        $config = $ComponentConfig[$componentName]
        
        if ($ShowProgress) {
            Write-Progress -Activity "System Health Check" -Status "Testing $($config.Name)..." -PercentComplete ((([array]::IndexOf($sortedComponents, $componentName)) / $sortedComponents.Count) * 100)
        }
        
        $result = Invoke-ComponentHealthCheck -ComponentName $componentName -Config $config
        
        if (-not $result.Success) {
            Write-TestLog "Component $componentName failed: $($result.Error)" -Level Warning
        }
    }
    
    if ($ShowProgress) {
        Write-Progress -Activity "System Health Check" -Completed
    }
}

function Show-HealthCheckSummary {
    <#
    .SYNOPSIS
    Display comprehensive health check summary
    #>
    
    $results = Get-TestResults
    $exitCode = Show-TestSummary
    
    # Additional component-specific summary
    Write-Host ""
    Write-Host "Component Summary:" -ForegroundColor Cyan
    Write-Host "==================" -ForegroundColor Cyan
    
    $componentResults = @{}
    foreach ($result in $results.Results) {
        $componentName = ($result.TestName -split ':')[0] -replace ' Component$', ''
        if (-not $componentResults.ContainsKey($componentName)) {
            $componentResults[$componentName] = @{ Pass = 0; Fail = 0; Warning = 0; Total = 0 }
        }
        $componentResults[$componentName].Total++
        $componentResults[$componentName][$result.Status]++
    }
    
    foreach ($componentName in ($componentResults.Keys | Sort-Object)) {
        $stats = $componentResults[$componentName]
        $passRate = if ($stats.Total -gt 0) { [math]::Round(($stats.Pass / $stats.Total) * 100, 1) } else { 0 }
        
        $statusColor = if ($passRate -gt 80) { 'Green' } elseif ($passRate -gt 60) { 'Yellow' } else { 'Red' }
        Write-Host "  $componentName`: $passRate% ($($stats.Pass)/$($stats.Total) passed)" -ForegroundColor $statusColor
    }
    
    return $exitCode
}

# Main execution
function Start-ModularHealthCheck {
    <#
    .SYNOPSIS
    Main health check orchestrator function
    #>
    
    Write-Host "Unity-Claude-Automation Modular Health Check" -ForegroundColor Cyan
    Write-Host "=============================================" -ForegroundColor Cyan
    Write-Host "Test Type: $TestType" -ForegroundColor White
    Write-Host "Components: $($Components -join ', ')" -ForegroundColor White
    Write-Host "Parallel Execution: $Parallel" -ForegroundColor White
    Write-Host ""
    
    # Initialize health check session
    Initialize-HealthCheck -TestType $TestType
    
    # Determine components to test
    $componentsToTest = Get-ComponentsToTest
    
    if ($componentsToTest.Count -eq 0) {
        Write-TestLog "No components to test" -Level Error
        exit 1
    }
    
    Write-TestLog "Testing components: $($componentsToTest -join ', ')" -Level Info
    
    # Verify component prerequisites
    if (-not (Test-ComponentPrerequisites -ComponentNames $componentsToTest)) {
        Write-TestLog "Component prerequisites not met" -Level Error
        exit 1
    }
    
    # Execute health checks
    if ($Parallel -and $componentsToTest.Count -gt 1) {
        Invoke-ParallelHealthChecks -ComponentNames $componentsToTest
    } else {
        Invoke-SequentialHealthChecks -ComponentNames $componentsToTest
    }
    
    # Save results if requested
    if ($SaveResults) {
        $savedPath = Save-TestResults -OutputPath $OutputPath -GenerateReport:$GenerateReport
        Write-TestLog "Results saved to: $savedPath" -Level Info
    }
    
    # Show summary and return exit code
    $exitCode = Show-HealthCheckSummary
    return $exitCode
}

# Execute main function if script is run directly
if ($MyInvocation.InvocationName -ne '.') {
    $exitCode = Start-ModularHealthCheck
    exit $exitCode
}

# Export main function for module use
Export-ModuleMember -Function 'Start-ModularHealthCheck'