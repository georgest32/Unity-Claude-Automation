# Enhanced Documentation System - Production Deployment Script
# Phase 3 Day 5: Production Integration & Advanced Features
# Version: 2025-08-25
# 
# This script provides complete production deployment of the Enhanced Documentation System
# including CodeQL integration, API documentation generation, and Docker containerization

[CmdletBinding()]
param(
    [ValidateSet('Development', 'Staging', 'Production')]
    [string]$Environment = 'Development',
    
    [string]$ConfigPath = '.\config',
    
    [switch]$SkipPreReqs,
    [switch]$SkipBuild,
    [switch]$SkipTests,
    [switch]$SkipHealthCheck,
    [switch]$Force
)

$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'

# Logging function
function Write-DeployLog {
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
    
    Write-Host "[$timestamp] [$Level] $Message" -ForegroundColor $color
    
    # Also log to file
    $logFile = "deployment-$(Get-Date -Format 'yyyy-MM-dd').log"
    "[$timestamp] [$Level] $Message" | Out-File -FilePath $logFile -Append -Encoding UTF8
}

# Phase 1: Pre-deployment checks and preparation
function Test-Prerequisites {
    Write-DeployLog "Checking system prerequisites..." -Level Info
    
    $issues = @()
    
    # Check PowerShell version
    if ($PSVersionTable.PSVersion.Major -lt 7) {
        $issues += "PowerShell 7.0+ required (current: $($PSVersionTable.PSVersion))"
    }
    
    # Check Docker
    try {
        $dockerVersion = docker --version
        Write-DeployLog "Docker version: $dockerVersion" -Level Info
    } catch {
        $issues += "Docker not installed or not accessible"
    }
    
    # Check Docker Compose
    try {
        $composeVersion = docker-compose --version
        Write-DeployLog "Docker Compose version: $composeVersion" -Level Info
    } catch {
        $issues += "Docker Compose not installed or not accessible"
    }
    
    # Check available disk space (minimum 10GB)
    $diskSpace = Get-WmiObject -Class Win32_LogicalDisk | Where-Object { $_.DeviceID -eq "C:" }
    $freeSpaceGB = [math]::Round($diskSpace.FreeSpace / 1GB, 2)
    if ($freeSpaceGB -lt 10) {
        $issues += "Insufficient disk space: ${freeSpaceGB}GB free (minimum 10GB required)"
    }
    
    # Check available memory (minimum 8GB)
    $memory = Get-WmiObject -Class Win32_ComputerSystem
    $totalMemoryGB = [math]::Round($memory.TotalPhysicalMemory / 1GB, 2)
    if ($totalMemoryGB -lt 8) {
        $issues += "Insufficient memory: ${totalMemoryGB}GB total (minimum 8GB recommended)"
    }
    
    # Check network connectivity
    try {
        Test-NetConnection -ComputerName "github.com" -Port 443 -InformationLevel Quiet | Out-Null
        Write-DeployLog "Network connectivity verified" -Level Info
    } catch {
        $issues += "No network connectivity to required services"
    }
    
    if ($issues.Count -gt 0) {
        Write-DeployLog "Prerequisites check failed:" -Level Error
        $issues | ForEach-Object { Write-DeployLog "  - $_" -Level Error }
        
        if (-not $Force) {
            throw "Prerequisites not met. Use -Force to override"
        } else {
            Write-DeployLog "Continuing with -Force despite issues" -Level Warning
        }
    } else {
        Write-DeployLog "All prerequisites met" -Level Success
    }
}

# Phase 2: Environment setup and configuration
function Initialize-Environment {
    param([string]$Environment)
    
    Write-DeployLog "Initializing $Environment environment..." -Level Info
    
    # Create required directories
    $directories = @(
        'logs',
        'data',
        'secrets',
        'config',
        'backups'
    )
    
    foreach ($dir in $directories) {
        if (-not (Test-Path $dir)) {
            New-Item -Path $dir -ItemType Directory -Force | Out-Null
            Write-DeployLog "Created directory: $dir" -Level Info
        }
    }
    
    # Set environment-specific configuration
    $envConfig = switch ($Environment) {
        'Development' {
            @{
                LogLevel = 'Debug'
                DockerComposeFile = 'docker-compose.yml'
                MonitoringEnabled = $true
                SecurityScanning = $false
                Port = 8080
            }
        }
        'Staging' {
            @{
                LogLevel = 'Info'
                DockerComposeFile = 'docker-compose.yml'
                MonitoringEnabled = $true
                SecurityScanning = $true
                Port = 8080
            }
        }
        'Production' {
            @{
                LogLevel = 'Warning'
                DockerComposeFile = 'docker-compose.yml'
                MonitoringEnabled = $true
                SecurityScanning = $true
                Port = 80
            }
        }
    }
    
    # Save environment configuration
    $configFile = Join-Path $ConfigPath "environment.json"
    $envConfig | ConvertTo-Json -Depth 5 | Out-File -FilePath $configFile -Encoding UTF8
    Write-DeployLog "Environment configuration saved to: $configFile" -Level Info
    
    return $envConfig
}

# Phase 3: Build and prepare Docker images
function Build-DockerImages {
    Write-DeployLog "Building Docker images..." -Level Info
    
    try {
        # Build documentation API image
        Write-DeployLog "Building documentation API image..." -Level Info
        docker build -f docker/documentation/Dockerfile.docs-api -t unity-claude-docs-api:latest .
        
        # Build CodeQL security scanner image
        Write-DeployLog "Building CodeQL security scanner image..." -Level Info
        docker build -f docker/documentation/Dockerfile.codeql -t unity-claude-codeql:latest .
        
        # Build existing images if needed
        Write-DeployLog "Building core system images..." -Level Info
        docker-compose build --parallel
        
        Write-DeployLog "All Docker images built successfully" -Level Success
        
    } catch {
        Write-DeployLog "Failed to build Docker images: $_" -Level Error
        throw
    }
}

# Phase 4: Deploy services
function Deploy-Services {
    param([hashtable]$EnvConfig)
    
    Write-DeployLog "Deploying Enhanced Documentation System services..." -Level Info
    
    try {
        # Stop existing services if running
        Write-DeployLog "Stopping existing services..." -Level Info
        docker-compose down --remove-orphans 2>$null
        
        # Start core services
        Write-DeployLog "Starting core services..." -Level Info
        docker-compose up -d
        
        # Wait for core services to be ready
        Write-DeployLog "Waiting for core services to initialize..." -Level Info
        Start-Sleep -Seconds 30
        
        # Start monitoring services
        if ($EnvConfig.MonitoringEnabled) {
            Write-DeployLog "Starting monitoring services..." -Level Info
            docker-compose -f docker-compose.monitoring.yml up -d
            Start-Sleep -Seconds 15
        }
        
        # Verify services are running
        $runningServices = docker-compose ps --services --filter "status=running"
        Write-DeployLog "Running services: $($runningServices -join ', ')" -Level Info
        
        Write-DeployLog "Services deployed successfully" -Level Success
        
    } catch {
        Write-DeployLog "Failed to deploy services: $_" -Level Error
        throw
    }
}

# Phase 5: Initialize Enhanced Documentation System
function Initialize-DocumentationSystem {
    Write-DeployLog "Initializing Enhanced Documentation System..." -Level Info
    
    try {
        # Import required PowerShell modules
        $modules = @(
            'Unity-Claude-CPG',
            'Unity-Claude-SemanticAnalysis',
            'Unity-Claude-LLM',
            'Unity-Claude-APIDocumentation',
            'Unity-Claude-CodeQL'
        )
        
        foreach ($module in $modules) {
            $modulePath = ".\Modules\$module\$module.psd1"
            if (Test-Path $modulePath) {
                try {
                    Import-Module $modulePath -Force -Global
                    Write-DeployLog "Imported module: $module" -Level Info
                } catch {
                    Write-DeployLog "Failed to import module $module`: $_" -Level Warning
                }
            } else {
                Write-DeployLog "Module not found: $modulePath" -Level Warning
            }
        }
        
        # Initialize documentation generation
        Write-DeployLog "Generating initial documentation..." -Level Info
        if (Get-Command New-ComprehensiveAPIDocs -ErrorAction SilentlyContinue) {
            try {
                New-ComprehensiveAPIDocs -ModulesPath ".\Modules" -OutputPath ".\docs\generated" -EnableCache -GenerateHTML
                Write-DeployLog "Initial documentation generated successfully" -Level Success
            } catch {
                Write-DeployLog "Failed to generate initial documentation: $_" -Level Warning
            }
        }
        
        # Initialize CodeQL databases if security scanning enabled
        if (Get-Command Initialize-PowerShellCodeQLDB -ErrorAction SilentlyContinue) {
            try {
                Write-DeployLog "Initializing CodeQL security databases..." -Level Info
                # This would normally be done by the CodeQL container, but we can trigger it
                Write-DeployLog "CodeQL initialization will be handled by the security service" -Level Info
            } catch {
                Write-DeployLog "CodeQL initialization warning: $_" -Level Warning
            }
        }
        
        Write-DeployLog "Enhanced Documentation System initialized" -Level Success
        
    } catch {
        Write-DeployLog "Failed to initialize documentation system: $_" -Level Error
        throw
    }
}

# Phase 6: Run system health checks
function Test-SystemHealth {
    Write-DeployLog "Running system health checks..." -Level Info
    
    $healthResults = @()
    
    # Test core services
    $services = @(
        @{ Name = "Documentation Web"; URL = "http://localhost:8080/health"; Timeout = 30 },
        @{ Name = "Documentation API"; URL = "http://localhost:8091/health"; Timeout = 30 },
        @{ Name = "PowerShell Modules"; URL = "http://localhost:5985"; Timeout = 15 },
        @{ Name = "LangGraph API"; URL = "http://localhost:8000/health"; Timeout = 30 },
        @{ Name = "AutoGen Service"; URL = "http://localhost:8001/health"; Timeout = 30 }
    )
    
    foreach ($service in $services) {
        try {
            $response = Invoke-WebRequest -Uri $service.URL -TimeoutSec $service.Timeout -UseBasicParsing
            if ($response.StatusCode -eq 200) {
                $healthResults += @{ Service = $service.Name; Status = "Healthy"; Details = "HTTP 200" }
                Write-DeployLog "$($service.Name): Healthy" -Level Success
            } else {
                $healthResults += @{ Service = $service.Name; Status = "Warning"; Details = "HTTP $($response.StatusCode)" }
                Write-DeployLog "$($service.Name): Warning (HTTP $($response.StatusCode))" -Level Warning
            }
        } catch {
            $healthResults += @{ Service = $service.Name; Status = "Error"; Details = $_.Exception.Message }
            Write-DeployLog "$($service.Name): Error - $($_.Exception.Message)" -Level Error
        }
    }
    
    # Test monitoring services
    try {
        $response = Invoke-WebRequest -Uri "http://localhost:3000" -TimeoutSec 15 -UseBasicParsing
        $healthResults += @{ Service = "Grafana Dashboard"; Status = "Healthy"; Details = "HTTP 200" }
        Write-DeployLog "Grafana Dashboard: Healthy" -Level Success
    } catch {
        $healthResults += @{ Service = "Grafana Dashboard"; Status = "Warning"; Details = "Not accessible" }
        Write-DeployLog "Grafana Dashboard: Not accessible (monitoring may not be fully ready)" -Level Warning
    }
    
    # Generate health report
    $healthReport = @{
        Timestamp = (Get-Date).ToString('yyyy-MM-dd HH:mm:ss')
        Environment = $Environment
        TotalServices = $healthResults.Count
        HealthyServices = ($healthResults | Where-Object { $_.Status -eq "Healthy" }).Count
        WarningServices = ($healthResults | Where-Object { $_.Status -eq "Warning" }).Count
        ErrorServices = ($healthResults | Where-Object { $_.Status -eq "Error" }).Count
        Services = $healthResults
    }
    
    $healthReport | ConvertTo-Json -Depth 5 | Out-File -FilePath "deployment-health-report.json" -Encoding UTF8
    
    $healthyPercentage = [math]::Round(($healthReport.HealthyServices / $healthReport.TotalServices) * 100, 1)
    Write-DeployLog "System Health: $healthyPercentage% ($($healthReport.HealthyServices)/$($healthReport.TotalServices) services healthy)" -Level Info
    
    if ($healthReport.ErrorServices -gt 0) {
        Write-DeployLog "Deployment completed with errors. Check deployment-health-report.json for details" -Level Warning
        return $false
    } else {
        Write-DeployLog "All critical services healthy" -Level Success
        return $true
    }
}

# Main deployment orchestration
function Start-Deployment {
    $startTime = Get-Date
    Write-DeployLog "Enhanced Documentation System Deployment Started" -Level Info
    Write-DeployLog "Environment: $Environment" -Level Info
    Write-DeployLog "Deployment ID: deployment-$(Get-Date -Format 'yyyyMMdd-HHmmss')" -Level Info
    
    try {
        # Phase 1: Prerequisites
        if (-not $SkipPreReqs) {
            Test-Prerequisites
        } else {
            Write-DeployLog "Skipping prerequisites check" -Level Warning
        }
        
        # Phase 2: Environment setup
        $envConfig = Initialize-Environment -Environment $Environment
        
        # Phase 3: Build images
        if (-not $SkipBuild) {
            Build-DockerImages
        } else {
            Write-DeployLog "Skipping Docker image build" -Level Warning
        }
        
        # Phase 4: Deploy services
        Deploy-Services -EnvConfig $envConfig
        
        # Phase 5: Initialize system
        Initialize-DocumentationSystem
        
        # Phase 6: Health checks
        if (-not $SkipHealthCheck) {
            $healthOk = Test-SystemHealth
        } else {
            Write-DeployLog "Skipping health checks" -Level Warning
            $healthOk = $true
        }
        
        $endTime = Get-Date
        $duration = $endTime - $startTime
        
        Write-DeployLog "Enhanced Documentation System Deployment Complete" -Level Success
        Write-DeployLog "Duration: $($duration.ToString('hh\:mm\:ss'))" -Level Info
        Write-DeployLog "Access documentation at: http://localhost:8080" -Level Success
        Write-DeployLog "API documentation at: http://localhost:8091/docs" -Level Success
        Write-DeployLog "Monitoring dashboard at: http://localhost:3000" -Level Success
        
        # Save deployment summary
        $summary = @{
            DeploymentId = "deployment-$(Get-Date -Format 'yyyyMMdd-HHmmss')"
            Environment = $Environment
            StartTime = $startTime.ToString('yyyy-MM-dd HH:mm:ss')
            EndTime = $endTime.ToString('yyyy-MM-dd HH:mm:ss')
            Duration = $duration.ToString('hh\:mm\:ss')
            Success = $healthOk
            Services = @{
                Documentation = "http://localhost:8080"
                API = "http://localhost:8091/docs"
                Monitoring = "http://localhost:3000"
                PowerShell = "http://localhost:5985"
                LangGraph = "http://localhost:8000"
                AutoGen = "http://localhost:8001"
            }
        }
        
        $summary | ConvertTo-Json -Depth 5 | Out-File -FilePath "deployment-summary.json" -Encoding UTF8
        
        if ($healthOk) {
            Write-DeployLog "🎉 Deployment successful! Enhanced Documentation System is operational." -Level Success
            exit 0
        } else {
            Write-DeployLog "⚠️  Deployment completed with warnings. Review health report." -Level Warning
            exit 1
        }
        
    } catch {
        $endTime = Get-Date
        $duration = $endTime - $startTime
        
        Write-DeployLog "Deployment failed after $($duration.ToString('hh\:mm\:ss'))" -Level Error
        Write-DeployLog "Error: $($_.Exception.Message)" -Level Error
        Write-DeployLog "Stack trace: $($_.ScriptStackTrace)" -Level Error
        
        # Attempt cleanup on failure
        Write-DeployLog "Attempting cleanup of failed deployment..." -Level Info
        try {
            docker-compose down --remove-orphans
            Write-DeployLog "Cleanup completed" -Level Info
        } catch {
            Write-DeployLog "Cleanup failed: $_" -Level Warning
        }
        
        exit 2
    }
}

# Execute deployment
Start-Deployment
# SIG # Begin signature block
# MIIFzgYJKoZIhvcNAQcCoIIFvzCCBbsCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCBmbTRw7h3O6zJH
# evFabHcAE0a0+0WOfOXnRx3IUrLDhqCCAzAwggMsMIICFKADAgECAhB1HRbZIqgr
# lUTwkh3hnGtFMA0GCSqGSIb3DQEBCwUAMC4xLDAqBgNVBAMMI1VuaXR5LUNsYXVk
# ZS1BdXRvbWF0aW9uLURldmVsb3BtZW50MB4XDTI1MDgyMDIxMTUxN1oXDTI2MDgy
# MDIxMzUxN1owLjEsMCoGA1UEAwwjVW5pdHktQ2xhdWRlLUF1dG9tYXRpb24tRGV2
# ZWxvcG1lbnQwggEiMA0GCSqGSIb3DQEBAQUAA4IBDwAwggEKAoIBAQCx4feqKdUQ
# 6GufY4umNzlM1Pi8aHUGR8HlfhIWFjsrRAxCxhieRlWbHe0Hw+pVBeX76X57e5Pu
# 4Kxxzu+MxMry0NJYf3yOLRTfhYskHBcLraXUCtrMwqnhPKvul6Sx6Lu8vilk605W
# ADJNifl3WFuexVCYJJM9G2mfuYIDN+rZ5zmpn0qCXum49bm629h+HyJ205Zrn9aB
# hIrA4i/JlrAh1kosWnCo62psl7ixbNVqFqwWEt+gAqSeIo4ChwkOQl7GHmk78Q5I
# oRneY4JTVlKzhdZEYhJGFXeoZml/5jcmUcox4UNYrKdokE7z8ZTmyowBOUNS+sHI
# G1TY5DZSb8vdAgMBAAGjRjBEMA4GA1UdDwEB/wQEAwIHgDATBgNVHSUEDDAKBggr
# BgEFBQcDAzAdBgNVHQ4EFgQUfDms7LrGVboHjmwlSyIjYD/JLQwwDQYJKoZIhvcN
# AQELBQADggEBABRMsfT7DzKy+aFi4HDg0MpxmbjQxOH1lzUzanaECRiyA0sn7+sA
# /4jvis1+qC5NjDGkLKOTCuDzIXnBWLCCBugukXbIO7g392ANqKdHjBHw1WlLvMVk
# 4WSmY096lzpvDd3jJApr/Alcp4KmRGNLnQ3vv+F9Uj58Uo1qjs85vt6fl9xe5lo3
# rFahNHL4ngjgyF8emNm7FItJeNtVe08PhFn0caOX0FTzXrZxGGO6Ov8tzf91j/qK
# QdBifG7Fx3FF7DifNqoBBo55a7q0anz30k8p+V0zllrLkgGXfOzXmA1L37Qmt3QB
# FCdJVigjQMuHcrJsWd8rg857Og0un91tfZIxggH0MIIB8AIBATBCMC4xLDAqBgNV
# BAMMI1VuaXR5LUNsYXVkZS1BdXRvbWF0aW9uLURldmVsb3BtZW50AhB1HRbZIqgr
# lUTwkh3hnGtFMA0GCWCGSAFlAwQCAQUAoIGEMBgGCisGAQQBgjcCAQwxCjAIoAKA
# AKECgAAwGQYJKoZIhvcNAQkDMQwGCisGAQQBgjcCAQQwHAYKKwYBBAGCNwIBCzEO
# MAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIGi7SOoJqe7JOHyPbJy+4JOC
# oxbklfGabefoUCssDyU+MA0GCSqGSIb3DQEBAQUABIIBAF/DbuHv5kUxwgRhhEGY
# M8yPVtaMj7fuwPb8cbLuH/WVCxMRJdLp+duEW0EmER7RJfOM0cQlr8VNv5SWwnRn
# CKQSWwfhpCkZEuYbsi4NbAsnnlpppJ1K6XoG3gEb1mV5QlVkbDBL4nZURZ9pVhH+
# XGdWIQT/nd2uBlOUqP2aZZnbRWhNJp4iHU8764M0ouD5wP4NxCFGQ0zQvfk8QpIf
# UxVT7vEFLieq98rB4y/w81pqzjcSueMSe8kNlTOtvEc2/RuMR5+mlUWbKd6gqFog
# KKUcOr3kRx843LqMBc7e3/DetfkgOXMmajoiMkc+AMUo+93Z6qM213Q//tPkYAaY
# wSU=
# SIG # End signature block
