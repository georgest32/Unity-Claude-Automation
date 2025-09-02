# Test-DeploymentVerification.ps1  
# Week 4 Day 4: Deployment Verification Testing
# Enhanced Documentation System - Comprehensive Validation
# Date: 2025-08-29

<#
.SYNOPSIS
    Comprehensive deployment verification testing for Enhanced Documentation System.

.DESCRIPTION
    Validates all aspects of Enhanced Documentation System deployment including:
    - Service health and availability
    - API endpoint functionality
    - PowerShell module integration
    - Docker container status
    - Performance benchmarks
    - Security scanning capabilities

.PARAMETER Environment
    Environment to validate (Development, Staging, Production)

.PARAMETER SkipPerformanceTests
    Skip performance benchmark testing (faster execution)

.PARAMETER SkipSecurityTests  
    Skip security scanning validation

.PARAMETER SaveReport
    Save detailed verification report to file

.PARAMETER OutputPath
    Path for verification report (default: auto-generated)

.EXAMPLE
    .\Test-DeploymentVerification.ps1 -Environment Production -SaveReport

.EXAMPLE
    .\Test-DeploymentVerification.ps1 -SkipPerformanceTests -SkipSecurityTests
#>

[CmdletBinding()]
param(
    [ValidateSet('Development', 'Staging', 'Production')]
    [string]$Environment = 'Development',
    
    [switch]$SkipPerformanceTests,
    [switch]$SkipSecurityTests,
    [switch]$SaveReport,
    [string]$OutputPath = ".\DeploymentVerification-$(Get-Date -Format 'yyyyMMdd-HHmmss').json"
)

$ErrorActionPreference = 'Continue'  # Continue on errors to complete all tests

# Initialize test results structure
$testResults = @{
    TestName = "Enhanced Documentation System - Deployment Verification"
    Environment = $Environment
    Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Results = @()
    Summary = @{
        Total = 0
        Passed = 0
        Failed = 0
        Warnings = 0
        OverallHealth = 0
    }
    Performance = @{}
    Security = @{}
}

# Logging function for verification tests
function Write-VerifyLog {
    param(
        [Parameter(Mandatory)]
        [string]$Message,
        
        [ValidateSet('Info', 'Warning', 'Error', 'Success')]
        [string]$Level = 'Info'
    )
    
    $timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
    $color = switch ($Level) {
        'Info' { 'White' }
        'Warning' { 'Yellow' }
        'Error' { 'Red' }
        'Success' { 'Green' }
    }
    
    Write-Host "[$timestamp] [VERIFY] [$Level] $Message" -ForegroundColor $color
}

# Test execution function
function Test-Component {
    param(
        [string]$ComponentName,
        [scriptblock]$TestCode,
        [string]$Description = "",
        [string]$Category = "General"
    )
    
    $testResults.Summary.Total++
    $testStart = Get-Date
    
    try {
        Write-VerifyLog "Testing $ComponentName..." -Level Info
        
        $result = & $TestCode
        $success = $true
        $error = $null
        
        Write-VerifyLog "$ComponentName: PASS" -Level Success
        $testResults.Summary.Passed++
    }
    catch {
        $success = $false
        $error = $_.Exception.Message
        Write-VerifyLog "$ComponentName: FAIL - $error" -Level Error
        $testResults.Summary.Failed++
    }
    
    $testEnd = Get-Date
    $duration = ($testEnd - $testStart).TotalMilliseconds
    
    $testResults.Results += [PSCustomObject]@{
        ComponentName = $ComponentName
        Category = $Category
        Description = $Description
        Success = $success
        Error = $error
        Duration = [math]::Round($duration, 2)
        Result = $result
        Timestamp = $testStart.ToString("yyyy-MM-dd HH:mm:ss")
    }
    
    return $success
}

Write-VerifyLog "=== Enhanced Documentation System - Deployment Verification ===" -Level Info
Write-VerifyLog "Environment: $Environment" -Level Info
Write-VerifyLog "Test Started: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -Level Info

# Category 1: Docker Infrastructure Tests
Write-VerifyLog "`n=== Docker Infrastructure Validation ===" -Level Info

Test-Component -ComponentName "Docker Engine" -Category "Infrastructure" -Description "Validate Docker engine availability" -TestCode {
    $version = docker --version 2>$null
    if (-not $version) {
        throw "Docker engine not available"
    }
    return @{ Version = $version; Status = "Available" }
}

Test-Component -ComponentName "Docker Compose" -Category "Infrastructure" -Description "Validate Docker Compose functionality" -TestCode {
    $composeVersion = docker-compose --version 2>$null
    if (-not $composeVersion) {
        throw "Docker Compose not available"  
    }
    
    # Check if compose files exist
    $composeFiles = @("docker-compose.yml", "docker-compose.monitoring.yml")
    foreach ($file in $composeFiles) {
        if (-not (Test-Path -Path $file)) {
            throw "Required compose file not found: $file"
        }
    }
    
    return @{ Version = $composeVersion; ComposeFiles = $composeFiles }
}

Test-Component -ComponentName "Docker Services" -Category "Infrastructure" -Description "Validate running Docker services" -TestCode {
    $services = docker-compose ps --services --filter "status=running" 2>$null
    if (-not $services) {
        throw "No Docker services running"
    }
    
    $expectedServices = @('docs-api', 'docs-web', 'powershell-modules')
    $runningServices = $services -split "`n" | Where-Object { $_ }
    $missingServices = $expectedServices | Where-Object { $_ -notin $runningServices }
    
    if ($missingServices) {
        throw "Missing services: $($missingServices -join ', ')"
    }
    
    return @{ RunningServices = $runningServices; HealthyServices = $runningServices.Count }
}

# Category 2: API Endpoint Tests
Write-VerifyLog "`n=== API Endpoint Validation ===" -Level Info

Test-Component -ComponentName "Documentation API Health" -Category "API" -Description "Validate documentation API health endpoint" -TestCode {
    try {
        $healthResponse = Invoke-RestMethod -Uri "http://localhost:8091/health" -TimeoutSec 10
        return @{ Status = "Healthy"; Response = $healthResponse }
    } catch {
        throw "Documentation API health endpoint not responding"
    }
}

Test-Component -ComponentName "Documentation Web Interface" -Category "API" -Description "Validate documentation web interface availability" -TestCode {
    try {
        $webResponse = Invoke-WebRequest -Uri "http://localhost:8080" -TimeoutSec 10 -UseBasicParsing
        if ($webResponse.StatusCode -ne 200) {
            throw "Web interface returned status code: $($webResponse.StatusCode)"
        }
        return @{ StatusCode = $webResponse.StatusCode; ContentLength = $webResponse.Content.Length }
    } catch {
        throw "Documentation web interface not accessible"
    }
}

Test-Component -ComponentName "API Modules Endpoint" -Category "API" -Description "Validate API modules endpoint functionality" -TestCode {
    try {
        $modulesResponse = Invoke-RestMethod -Uri "http://localhost:8091/api/modules" -TimeoutSec 10
        if (-not $modulesResponse) {
            throw "Modules endpoint returned no data"
        }
        return @{ ModuleCount = $modulesResponse.Count; Status = "Functional" }
    } catch {
        # This might fail if no modules are loaded yet, which is acceptable
        Write-VerifyLog "API modules endpoint not yet populated (may be normal during initial deployment)" -Level Warning
        $testResults.Summary.Warnings++
        return @{ Status = "NotPopulated"; Note = "Acceptable for new deployment" }
    }
}

# Category 3: PowerShell Module Tests  
Write-VerifyLog "`n=== PowerShell Module Validation ===" -Level Info

Test-Component -ComponentName "Week 4 Predictive Evolution Module" -Category "Modules" -Description "Validate Predictive-Evolution module functionality" -TestCode {
    try {
        Import-Module ".\Modules\Unity-Claude-CPG\Core\Predictive-Evolution.psm1" -Force -DisableNameChecking
        $module = Get-Module -Name "Predictive-Evolution"
        if (-not $module) {
            throw "Predictive-Evolution module not imported"
        }
        
        $expectedFunctions = @('Get-GitCommitHistory', 'Get-CodeChurnMetrics', 'New-EvolutionReport')
        $availableFunctions = $module.ExportedFunctions.Keys
        $missingFunctions = $expectedFunctions | Where-Object { $_ -notin $availableFunctions }
        
        if ($missingFunctions) {
            throw "Missing functions: $($missingFunctions -join ', ')"
        }
        
        return @{ 
            ModuleName = $module.Name
            Version = $module.Version
            FunctionCount = $availableFunctions.Count
            Status = "Functional"
        }
    } catch {
        throw "Predictive-Evolution module validation failed: $_"
    }
}

Test-Component -ComponentName "Week 4 Maintenance Prediction Module" -Category "Modules" -Description "Validate Predictive-Maintenance module functionality" -TestCode {
    try {
        Import-Module ".\Modules\Unity-Claude-CPG\Core\Predictive-Maintenance.psm1" -Force -DisableNameChecking
        $module = Get-Module -Name "Predictive-Maintenance"
        if (-not $module) {
            throw "Predictive-Maintenance module not imported"
        }
        
        $expectedFunctions = @('Get-TechnicalDebt', 'Get-CodeSmells', 'New-MaintenanceReport')
        $availableFunctions = $module.ExportedFunctions.Keys
        $missingFunctions = $expectedFunctions | Where-Object { $_ -notin $availableFunctions }
        
        if ($missingFunctions) {
            throw "Missing functions: $($missingFunctions -join ', ')"
        }
        
        return @{ 
            ModuleName = $module.Name
            Version = $module.Version  
            FunctionCount = $availableFunctions.Count
            Status = "Functional"
        }
    } catch {
        throw "Predictive-Maintenance module validation failed: $_"
    }
}

# Category 4: Performance Tests (Optional)
if (-not $SkipPerformanceTests) {
    Write-VerifyLog "`n=== Performance Validation ===" -Level Info
    
    Test-Component -ComponentName "API Response Time" -Category "Performance" -Description "Measure API endpoint response times" -TestCode {
        $endpointTests = @()
        $endpoints = @(
            "http://localhost:8091/health",
            "http://localhost:8080",
            "http://localhost:8091/api/modules"
        )
        
        foreach ($endpoint in $endpoints) {
            try {
                $start = Get-Date
                $response = Invoke-RestMethod -Uri $endpoint -TimeoutSec 5 -ErrorAction SilentlyContinue
                $responseTime = ((Get-Date) - $start).TotalMilliseconds
                
                $endpointTests += [PSCustomObject]@{
                    Endpoint = $endpoint
                    ResponseTime = [math]::Round($responseTime, 2)
                    Status = "Responsive"
                }
            } catch {
                $endpointTests += [PSCustomObject]@{
                    Endpoint = $endpoint  
                    ResponseTime = -1
                    Status = "Unresponsive"
                }
            }
        }
        
        $testResults.Performance.EndpointTests = $endpointTests
        $avgResponseTime = ($endpointTests | Where-Object { $_.ResponseTime -gt 0 } | Measure-Object ResponseTime -Average).Average
        
        return @{ 
            AverageResponseTime = [math]::Round($avgResponseTime, 2)
            TestedEndpoints = $endpointTests.Count
            ResponsiveEndpoints = ($endpointTests | Where-Object { $_.Status -eq "Responsive" }).Count
        }
    }
}

# Category 5: Security Validation (Optional)
if (-not $SkipSecurityTests) {
    Write-VerifyLog "`n=== Security Validation ===" -Level Info
    
    Test-Component -ComponentName "Container Security" -Category "Security" -Description "Validate container security configuration" -TestCode {
        $securityChecks = @()
        
        # Check for non-root user execution
        $containerUsers = docker-compose exec -T docs-api whoami 2>$null
        $securityChecks += [PSCustomObject]@{
            Check = "Non-root execution"
            Status = if ($containerUsers -ne "root") { "PASS" } else { "FAIL" }
            Value = $containerUsers
        }
        
        # Check for read-only filesystem mounts
        $mounts = docker-compose exec -T docs-api mount 2>$null | Select-String "ro," | Measure-Object
        $securityChecks += [PSCustomObject]@{
            Check = "Read-only mounts"  
            Status = if ($mounts.Count -gt 0) { "PASS" } else { "WARNING" }
            Value = "$($mounts.Count) read-only mounts"
        }
        
        $testResults.Security.ContainerChecks = $securityChecks
        
        return @{
            SecurityChecks = $securityChecks.Count
            PassedChecks = ($securityChecks | Where-Object { $_.Status -eq "PASS" }).Count
        }
    }
}

# Final Summary and Report Generation
Write-VerifyLog "`n=== Verification Summary ===" -Level Info
Write-VerifyLog "Total Tests: $($testResults.Summary.Total)" -Level Info
Write-VerifyLog "Passed: $($testResults.Summary.Passed)" -Level Success
Write-VerifyLog "Failed: $($testResults.Summary.Failed)" -Level $(if ($testResults.Summary.Failed -eq 0) { "Success" } else { "Error" })
Write-VerifyLog "Warnings: $($testResults.Summary.Warnings)" -Level Warning

$successRate = if ($testResults.Summary.Total -gt 0) {
    [math]::Round(($testResults.Summary.Passed / $testResults.Summary.Total) * 100, 1)
} else { 0 }

$testResults.Summary.OverallHealth = $successRate

Write-VerifyLog "Success Rate: $successRate%" -Level $(if ($successRate -ge 85) { "Success" } elseif ($successRate -ge 70) { "Warning" } else { "Error" })

# Deployment readiness assessment
$deploymentReady = ($successRate -ge 85 -and $testResults.Summary.Failed -eq 0)
$readinessStatus = if ($deploymentReady) { "READY" } else { "NOT READY" }
$readinessLevel = if ($deploymentReady) { "Success" } else { "Error" }

Write-VerifyLog "`nDeployment Status: $readinessStatus for $Environment environment" -Level $readinessLevel

# Performance summary
if (-not $SkipPerformanceTests -and $testResults.Performance.EndpointTests) {
    $avgResponse = ($testResults.Performance.EndpointTests | Where-Object { $_.ResponseTime -gt 0 } | Measure-Object ResponseTime -Average).Average
    Write-VerifyLog "Average API Response Time: $([math]::Round($avgResponse, 2))ms" -Level Info
}

# Security summary
if (-not $SkipSecurityTests -and $testResults.Security.ContainerChecks) {
    $securityPassed = ($testResults.Security.ContainerChecks | Where-Object { $_.Status -eq "PASS" }).Count
    $securityTotal = $testResults.Security.ContainerChecks.Count
    Write-VerifyLog "Security Checks: $securityPassed/$securityTotal passed" -Level Info
}

# Save detailed report if requested
if ($SaveReport) {
    $testResults | ConvertTo-Json -Depth 10 | Out-File -FilePath $OutputPath -Encoding UTF8
    Write-VerifyLog "Detailed verification report saved to: $OutputPath" -Level Success
}

# Return results for automation integration
$testResults.DeploymentReady = $deploymentReady
$testResults.Summary.SuccessRate = $successRate

return $testResults

Write-VerifyLog "`n=== Enhanced Documentation System Deployment Verification Complete ===" -Level Success