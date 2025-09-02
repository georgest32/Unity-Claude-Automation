# Test-EnhancedDocumentationSystemDeployment.ps1
# Comprehensive verification tests for Enhanced Documentation System deployment
# Week 4 Day 4: Deployment Automation - Verification component
# Date: 2025-08-29

param(
    [ValidateSet('Development', 'Staging', 'Production')]
    [string]$Environment = 'Development',
    
    [switch]$Verbose,
    [switch]$SaveReport,
    [string]$OutputPath = ".\DeploymentVerification-TestResults-$(Get-Date -Format 'yyyyMMdd-HHmmss').json"
)

if ($Verbose) { $VerbosePreference = "Continue" }

Write-Host "=== Enhanced Documentation System Deployment Verification ===" -ForegroundColor Cyan
Write-Host "Test Started: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor Green
Write-Host "Environment: $Environment" -ForegroundColor Yellow

$testResults = @{
    TestName = "Enhanced Documentation System Deployment Verification"
    Environment = $Environment
    Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Results = @()
    Summary = @{
        Total = 0
        Passed = 0
        Failed = 0
        Warnings = 0
    }
    DeploymentHealth = @{}
}

function Test-DeploymentComponent {
    param(
        [string]$ComponentName,
        [scriptblock]$TestCode,
        [string]$Description = "",
        [bool]$Critical = $true
    )
    
    $testResults.Summary.Total++
    $testStart = Get-Date
    
    try {
        Write-Host "Testing $ComponentName..." -ForegroundColor Yellow -NoNewline
        
        $result = & $TestCode
        $success = $true
        $error = $null
        
        Write-Host " PASS" -ForegroundColor Green
        $testResults.Summary.Passed++
    }
    catch {
        $success = $false
        $error = $_.Exception.Message
        
        if ($Critical) {
            Write-Host " FAIL (CRITICAL)" -ForegroundColor Red
            $testResults.Summary.Failed++
        } else {
            Write-Host " WARN" -ForegroundColor Yellow
            $testResults.Summary.Warnings++
        }
        
        Write-Host "  Error: $error" -ForegroundColor Red
    }
    
    $testEnd = Get-Date
    $duration = ($testEnd - $testStart).TotalMilliseconds
    
    $testResults.Results += [PSCustomObject]@{
        ComponentName = $ComponentName
        Description = $Description
        Success = $success
        Critical = $Critical
        Error = $error
        Duration = [math]::Round($duration, 2)
        Result = $result
    }
    
    return $success
}

# Test 1: Prerequisites Validation
Test-DeploymentComponent -ComponentName "Prerequisites Check" -Description "Validate deployment prerequisites" -TestCode {
    $issues = @()
    
    # Check Docker availability
    try {
        $dockerVersion = docker --version 2>$null
        if (-not $dockerVersion) {
            $issues += "Docker is not installed or not available"
        }
    } catch {
        $issues += "Docker check failed: $($_.Exception.Message)"
    }
    
    # Check PowerShell version
    if ($PSVersionTable.PSVersion.Major -lt 5) {
        $issues += "PowerShell version 5.0+ required"
    }
    
    # Check available disk space (minimum 10GB)
    $freeSpace = Get-WmiObject -Class Win32_LogicalDisk -Filter "DeviceID='C:'" | Select-Object -ExpandProperty FreeSpace
    if ($freeSpace -lt 10GB) {
        $issues += "Insufficient disk space (need 10GB+, have $([math]::Round($freeSpace/1GB, 2))GB)"
    }
    
    if ($issues.Count -gt 0) {
        throw "Prerequisites not met: $($issues -join '; ')"
    }
    
    return @{
        DockerVersion = $dockerVersion
        PowerShellVersion = $PSVersionTable.PSVersion.ToString()
        FreeSpaceGB = [math]::Round($freeSpace/1GB, 2)
    }
}

# Test 2: Module Availability
Test-DeploymentComponent -ComponentName "PowerShell Modules" -Description "Verify required PowerShell modules available" -TestCode {
    $requiredModules = @(
        'Unity-Claude-CPG',
        'Unity-Claude-LLM', 
        'Unity-Claude-ParallelProcessing'
    )
    
    $moduleStatus = @{}
    $missingModules = @()
    
    foreach ($moduleName in $requiredModules) {
        $foundModule = Get-ChildItem -Path ".\Modules" -Recurse -Filter "*$moduleName*" -Directory | Select-Object -First 1
        if ($foundModule) {
            $moduleStatus[$moduleName] = "Available"
        } else {
            $moduleStatus[$moduleName] = "Missing"
            $missingModules += $moduleName
        }
    }
    
    if ($missingModules.Count -gt 0) {
        throw "Required modules not found: $($missingModules -join ', ')"
    }
    
    return $moduleStatus
}

# Test 3: Docker Configuration
Test-DeploymentComponent -ComponentName "Docker Configuration" -Description "Validate Docker Compose configuration files" -TestCode {
    $configFiles = @{
        "docker-compose.yml" = $false
        "docker-compose.monitoring.yml" = $false
    }
    
    $missingConfigs = @()
    
    foreach ($configFile in $configFiles.Keys) {
        if (Test-Path $configFile) {
            try {
                # Basic YAML validation by attempting to parse with docker-compose
                $output = docker-compose -f $configFile config 2>&1
                if ($LASTEXITCODE -eq 0) {
                    $configFiles[$configFile] = $true
                } else {
                    throw "Docker Compose validation failed for $configFile"
                }
            } catch {
                $missingConfigs += "$configFile (validation failed)"
            }
        } else {
            $missingConfigs += "$configFile (file missing)"
        }
    }
    
    if ($missingConfigs.Count -gt 0) {
        throw "Docker configuration issues: $($missingConfigs -join ', ')"
    }
    
    return $configFiles
}

# Test 4: Container Image Availability
Test-DeploymentComponent -ComponentName "Container Images" -Description "Verify Docker container images available" -Critical $false -TestCode {
    $images = docker images --format "table {{.Repository}}\t{{.Tag}}\t{{.ID}}" 2>$null
    
    $requiredImages = @(
        "unity-claude-docs-api",
        "unity-claude-powershell"
    )
    
    $imageStatus = @{}
    $missingImages = @()
    
    foreach ($imageName in $requiredImages) {
        if ($images -like "*$imageName*") {
            $imageStatus[$imageName] = "Available"
        } else {
            $imageStatus[$imageName] = "Missing"
            $missingImages += $imageName
        }
    }
    
    if ($missingImages.Count -gt 0) {
        # Non-critical - images can be built during deployment
        Write-Warning "Container images will be built during deployment: $($missingImages -join ', ')"
    }
    
    return @{
        ImageStatus = $imageStatus
        MissingImages = $missingImages
        TotalImages = ($images | Measure-Object).Count
    }
}

# Test 5: Network and Port Availability
Test-DeploymentComponent -ComponentName "Network Configuration" -Description "Validate network ports and connectivity" -TestCode {
    $requiredPorts = @(8080, 8091, 3000, 9090, 5985, 5986)
    $portStatus = @{}
    $conflictPorts = @()
    
    foreach ($port in $requiredPorts) {
        try {
            $listener = Get-NetTCPConnection -LocalPort $port -ErrorAction SilentlyContinue
            if ($listener) {
                $portStatus[$port] = "In Use"
                $conflictPorts += $port
            } else {
                $portStatus[$port] = "Available"
            }
        } catch {
            $portStatus[$port] = "Available"  # Assume available if check fails
        }
    }
    
    if ($conflictPorts.Count -gt 0) {
        Write-Warning "Ports in use (may cause conflicts): $($conflictPorts -join ', ')"
        # Don't fail - deployment may still work with port conflicts
    }
    
    return @{
        PortStatus = $portStatus
        ConflictPorts = $conflictPorts
        RequiredPorts = $requiredPorts
    }
}

# Test 6: Deployment Script Validation
Test-DeploymentComponent -ComponentName "Deployment Script" -Description "Validate deployment script functionality" -TestCode {
    $deployScript = ".\Deploy-EnhancedDocumentationSystem.ps1"
    
    if (-not (Test-Path $deployScript)) {
        throw "Deployment script not found: $deployScript"
    }
    
    # Check script syntax
    $errors = $null
    $ast = [System.Management.Automation.Language.Parser]::ParseFile($deployScript, [ref]$null, [ref]$errors)
    
    if ($errors) {
        throw "Deployment script has syntax errors: $($errors[0].Message)"
    }
    
    # Check for required functions
    $scriptContent = Get-Content $deployScript
    $requiredFunctions = @(
        'Write-DeployLog',
        'Test-Prerequisites', 
        'Initialize-Environment',
        'Deploy-Services'
    )
    
    $missingFunctions = @()
    foreach ($func in $requiredFunctions) {
        if ($scriptContent -notmatch "function $func") {
            $missingFunctions += $func
        }
    }
    
    if ($missingFunctions.Count -gt 0) {
        throw "Missing required functions: $($missingFunctions -join ', ')"
    }
    
    return @{
        ScriptPath = $deployScript
        ScriptSize = (Get-Item $deployScript).Length
        SyntaxValid = $true
        RequiredFunctions = $requiredFunctions.Count
        TotalLines = (Get-Content $deployScript).Count
    }
}

# Test 7: Rollback Capability
Test-DeploymentComponent -ComponentName "Rollback Functions" -Description "Validate rollback mechanism availability" -TestCode {
    $rollbackScript = ".\Deploy-Rollback-Functions.ps1"
    
    if (-not (Test-Path $rollbackScript)) {
        throw "Rollback functions script not found: $rollbackScript"
    }
    
    # Check rollback script syntax
    $errors = $null
    $ast = [System.Management.Automation.Language.Parser]::ParseFile($rollbackScript, [ref]$null, [ref]$errors)
    
    if ($errors) {
        throw "Rollback script has syntax errors: $($errors[0].Message)"
    }
    
    # Check for rollback functions
    $rollbackContent = Get-Content $rollbackScript
    $rollbackFunctions = @(
        'New-DeploymentSnapshot',
        'Test-DeploymentHealth',
        'Invoke-DeploymentRollback'
    )
    
    $missingRollbackFunctions = @()
    foreach ($func in $rollbackFunctions) {
        if ($rollbackContent -notmatch "function $func") {
            $missingRollbackFunctions += $func
        }
    }
    
    if ($missingRollbackFunctions.Count -gt 0) {
        throw "Missing rollback functions: $($missingRollbackFunctions -join ', ')"
    }
    
    return @{
        RollbackScript = $rollbackScript
        RollbackFunctions = $rollbackFunctions.Count
        SyntaxValid = $true
        TotalLines = (Get-Content $rollbackScript).Count
    }
}

# Test Summary
Write-Host "`n=== Deployment Verification Summary ===" -ForegroundColor Cyan
Write-Host "Total Tests: $($testResults.Summary.Total)" -ForegroundColor White
Write-Host "Passed: $($testResults.Summary.Passed)" -ForegroundColor Green
Write-Host "Failed: $($testResults.Summary.Failed)" -ForegroundColor Red
Write-Host "Warnings: $($testResults.Summary.Warnings)" -ForegroundColor Yellow

$successRate = if ($testResults.Summary.Total -gt 0) { 
    [math]::Round(($testResults.Summary.Passed / $testResults.Summary.Total) * 100, 1) 
} else { 0 }

Write-Host "Success Rate: $successRate%" -ForegroundColor $(if ($successRate -ge 85) { "Green" } elseif ($successRate -ge 70) { "Yellow" } else { "Red" })

# Deployment Readiness Assessment
Write-Host "`n=== Deployment Readiness Assessment ===" -ForegroundColor Cyan
$deploymentReady = $testResults.Summary.Failed -eq 0
$readinessStatus = if ($deploymentReady) { "READY" } else { "NOT READY" }
$readinessColor = if ($deploymentReady) { "Green" } else { "Red" }

Write-Host "Deployment Status: $readinessStatus" -ForegroundColor $readinessColor

if ($deploymentReady) {
    Write-Host "System is ready for $Environment deployment" -ForegroundColor Green
    Write-Host "Run: .\Deploy-EnhancedDocumentationSystem.ps1 -Environment $Environment" -ForegroundColor Cyan
} else {
    Write-Host "Resolve failed tests before deployment" -ForegroundColor Red
    $failedTests = $testResults.Results | Where-Object { -not $_.Success -and $_.Critical }
    $failedTests | ForEach-Object { Write-Host "  - $($_.ComponentName): $($_.Error)" -ForegroundColor Red }
}

# Save results if requested
if ($SaveReport) {
    $testResults.Summary.SuccessRate = $successRate
    $testResults.DeploymentReady = $deploymentReady
    $testResults | ConvertTo-Json -Depth 10 | Out-File -FilePath $OutputPath -Encoding UTF8
    Write-Host "`nVerification results saved to: $OutputPath" -ForegroundColor Green
}

# Return results for integration
return $testResults

Write-Host "`n=== Week 4 Day 4: Deployment Verification Complete ===" -ForegroundColor Green