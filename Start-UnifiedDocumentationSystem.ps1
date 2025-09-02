# Start-UnifiedDocumentationSystem.ps1
# Unified startup system integrating Docker Compose with PowerShell module loading
# Enhanced Documentation System v2.0.0 - Complete Integration
# Date: 2025-08-29

[CmdletBinding()]
param(
    [ValidateSet('Development', 'Staging', 'Production')]
    [string]$Environment = 'Production',
    
    [ValidateSet('Local', 'Docker', 'Hybrid')]
    [string]$DeploymentMode = 'Hybrid',
    
    [switch]$SkipHealthChecks
)

# CmdletBinding automatically provides $VerbosePreference

# Unified logging system
function Write-UnifiedLog {
    param(
        [string]$Message,
        [ValidateSet('Info', 'Success', 'Warning', 'Error', 'Debug')]
        [string]$Level = 'Info',
        [string]$Component = 'System'
    )
    
    $timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss.fff'
    $color = @{
        'Info' = 'White'
        'Success' = 'Green'
        'Warning' = 'Yellow'
        'Error' = 'Red'
        'Debug' = 'Cyan'
    }[$Level]
    
    Write-Host "[$timestamp] [$Component] [$Level] $Message" -ForegroundColor $color
    
    # Unified logging to file
    $logFile = "unified-system-$(Get-Date -Format 'yyyy-MM-dd').log"
    "[$timestamp] [$Component] [$Level] $Message" | Out-File -FilePath $logFile -Append -Encoding UTF8
}

# Service health validation with intelligent retry
function Test-ServiceHealth {
    param(
        [string]$ServiceName,
        [string]$HealthUrl,
        [int]$MaxWaitSeconds = 300,
        [int]$RetryInterval = 15
    )
    
    Write-UnifiedLog "Testing health for $ServiceName at $HealthUrl" -Level Info -Component $ServiceName
    
    $maxAttempts = $MaxWaitSeconds / $RetryInterval
    $attempts = 0
    
    while ($attempts -lt $maxAttempts) {
        $attempts++
        
        try {
            $response = Invoke-WebRequest -Uri $HealthUrl -TimeoutSec 10 -UseBasicParsing -ErrorAction Stop
            
            if ($response.StatusCode -eq 200) {
                Write-UnifiedLog "Service healthy (HTTP $($response.StatusCode))" -Level Success -Component $ServiceName
                return $true
            }
        } catch {
            if ($attempts % 4 -eq 0) {  # Log every 4th attempt
                Write-UnifiedLog "Health check $attempts/$maxAttempts failed: $($_.Exception.Message)" -Level Debug -Component $ServiceName
            }
        }
        
        if ($attempts -lt $maxAttempts) {
            Start-Sleep -Seconds $RetryInterval
        }
    }
    
    Write-UnifiedLog "Service failed to become healthy within $MaxWaitSeconds seconds" -Level Error -Component $ServiceName
    return $false
}

# PowerShell module loading with enhanced discovery
function Initialize-PowerShellModules {
    Write-UnifiedLog "Initializing PowerShell modules with enhanced discovery" -Level Info -Component "Modules"
    
    # Enhanced Documentation System core modules
    $coreModules = @(
        "Unity-Claude-CPG",
        "Unity-Claude-LLM", 
        "Unity-Claude-ParallelProcessing",
        "Unity-Claude-APIDocumentation"
    )
    
    # Week 4 Predictive Analysis modules
    $week4Modules = @(
        "Predictive-Evolution",
        "Predictive-Maintenance"
    )
    
    $loadedModules = @()
    $moduleErrors = @()
    
    # Load core modules first
    foreach ($moduleName in $coreModules) {
        try {
            # Dynamic module discovery
            $manifestPath = Get-ChildItem -Path ".\Modules" -Filter "$moduleName.psd1" -Recurse | Select-Object -First 1
            $modulePath = Get-ChildItem -Path ".\Modules" -Filter "$moduleName.psm1" -Recurse | Select-Object -First 1
            
            $pathToLoad = $null
            if ($manifestPath) {
                $pathToLoad = $manifestPath.FullName
            } elseif ($modulePath) {
                $pathToLoad = $modulePath.FullName
            }
            
            if ($pathToLoad) {
                Import-Module $pathToLoad -Force -Global -ErrorAction Stop
                $loadedModules += $moduleName
                Write-UnifiedLog "Loaded module: $moduleName" -Level Success -Component "Modules"
            } else {
                $moduleErrors += "$moduleName (not found)"
                Write-UnifiedLog "Module not found: $moduleName" -Level Warning -Component "Modules"
            }
        } catch {
            $moduleErrors += "$moduleName ($($_.Exception.Message))"
            Write-UnifiedLog "Failed to load $moduleName`: $($_.Exception.Message)" -Level Error -Component "Modules"
        }
    }
    
    # Load Week 4 modules
    foreach ($moduleName in $week4Modules) {
        try {
            $modulePath = ".\Modules\Unity-Claude-CPG\Core\$moduleName.psm1"
            
            if (Test-Path $modulePath) {
                Import-Module $modulePath -Force -Global -ErrorAction Stop
                $loadedModules += $moduleName
                Write-UnifiedLog "Loaded Week 4 module: $moduleName" -Level Success -Component "Week4"
            } else {
                $moduleErrors += "$moduleName (Week 4 module not found)"
                Write-UnifiedLog "Week 4 module not found: $moduleName" -Level Warning -Component "Week4"
            }
        } catch {
            $moduleErrors += "$moduleName ($($_.Exception.Message))"
            Write-UnifiedLog "Failed to load Week 4 module $moduleName`: $($_.Exception.Message)" -Level Error -Component "Week4"
        }
    }
    
    Write-UnifiedLog "Module loading complete: $($loadedModules.Count) loaded, $($moduleErrors.Count) errors" -Level Info -Component "Modules"
    
    return @{
        LoadedModules = $loadedModules
        ModuleErrors = $moduleErrors
        Success = $moduleErrors.Count -eq 0
    }
}

# Docker Compose startup integration
function Start-DockerServices {
    param([string]$ComposeFile = "docker-compose-working.yml")
    
    Write-UnifiedLog "Starting Docker services with unified integration" -Level Info -Component "Docker"
    
    try {
        # Check if Docker is available
        $dockerVersion = docker --version 2>$null
        if (-not $dockerVersion) {
            Write-UnifiedLog "Docker not available - skipping container services" -Level Warning -Component "Docker"
            return $false
        }
        
        Write-UnifiedLog "Docker available: $dockerVersion" -Level Success -Component "Docker"
        
        # Check if compose file exists
        if (-not (Test-Path $ComposeFile)) {
            Write-UnifiedLog "Compose file not found: $ComposeFile" -Level Error -Component "Docker"
            return $false
        }
        
        Write-UnifiedLog "Using Docker Compose file: $ComposeFile" -Level Info -Component "Docker"
        
        # Stop existing services
        Write-UnifiedLog "Stopping existing Docker services..." -Level Info -Component "Docker"
        docker-compose -f $ComposeFile down --remove-orphans 2>$null
        
        # Start services
        Write-UnifiedLog "Starting Docker services (this may take several minutes)..." -Level Info -Component "Docker"
        $buildOutput = docker-compose -f $ComposeFile up -d --build 2>&1
        
        if ($LASTEXITCODE -eq 0) {
            Write-UnifiedLog "Docker services started successfully" -Level Success -Component "Docker"
            
            # Get running services
            $runningServices = docker-compose -f $ComposeFile ps --services --filter "status=running" 2>$null
            if ($runningServices) {
                Write-UnifiedLog "Running services: $($runningServices -join ', ')" -Level Info -Component "Docker"
            }
            
            return $true
        } else {
            Write-UnifiedLog "Docker service startup failed" -Level Error -Component "Docker"
            Write-UnifiedLog "Build output: $($buildOutput[-5..-1] -join '; ')" -Level Debug -Component "Docker"
            return $false
        }
        
    } catch {
        Write-UnifiedLog "Docker startup error: $($_.Exception.Message)" -Level Error -Component "Docker"
        return $false
    }
}

# Comprehensive service health validation
function Test-UnifiedSystemHealth {
    Write-UnifiedLog "Starting comprehensive system health validation" -Level Info -Component "Health"
    
    $healthResults = @{}
    
    # Core services to validate
    $services = @{
        "Documentation Web" = "http://localhost:8080"
        "Documentation API" = "http://localhost:8091/health"
        "PowerShell Service" = "http://localhost:5985"
        "LangGraph API" = "http://localhost:8000/health"
        "AutoGen Service" = "http://localhost:8001/health"
    }
    
    $healthyServices = 0
    $totalServices = $services.Count
    
    foreach ($serviceName in $services.Keys) {
        $serviceUrl = $services[$serviceName]
        
        Write-UnifiedLog "Checking health: $serviceName" -Level Info -Component "Health"
        
        $healthy = Test-ServiceHealth -ServiceName $serviceName -HealthUrl $serviceUrl -MaxWaitSeconds 180 -RetryInterval 15
        
        $healthResults[$serviceName] = @{
            Url = $serviceUrl
            Healthy = $healthy
            Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        }
        
        if ($healthy) {
            $healthyServices++
        }
    }
    
    $healthPercentage = [math]::Round(($healthyServices / $totalServices) * 100, 1)
    
    Write-UnifiedLog "System health: $healthPercentage% ($healthyServices/$totalServices services healthy)" -Level Info -Component "Health"
    
    return @{
        HealthPercentage = $healthPercentage
        HealthyServices = $healthyServices
        TotalServices = $totalServices
        ServiceResults = $healthResults
        AllHealthy = $healthyServices -eq $totalServices
    }
}

# Main unified startup function
function Start-EnhancedDocumentationSystem {
    $startTime = Get-Date
    
    Write-UnifiedLog "🚀 Enhanced Documentation System v2.0.0 - Unified Startup" -Level Success -Component "System"
    Write-UnifiedLog "Environment: $Environment | Mode: $DeploymentMode" -Level Info -Component "System"
    Write-UnifiedLog "Integration: Docker + PowerShell + AI Services" -Level Info -Component "System"
    
    try {
        # Phase 1: PowerShell Module Loading
        Write-UnifiedLog "Phase 1: Loading PowerShell modules" -Level Info -Component "Phase1"
        $moduleResult = Initialize-PowerShellModules
        
        # Phase 2: Docker Service Startup (if Docker mode)
        $dockerResult = $null
        if ($DeploymentMode -in @('Docker', 'Hybrid')) {
            Write-UnifiedLog "Phase 2: Starting Docker services" -Level Info -Component "Phase2"
            $dockerResult = Start-DockerServices -ComposeFile "docker-compose-working.yml"
        } else {
            Write-UnifiedLog "Phase 2: Skipped (Local mode)" -Level Info -Component "Phase2"
            $dockerResult = $false
        }
        
        # Phase 3: Health Validation
        if (-not $SkipHealthChecks) {
            Write-UnifiedLog "Phase 3: System health validation" -Level Info -Component "Phase3"
            Start-Sleep -Seconds 60  # Allow services to initialize
            $healthResult = Test-UnifiedSystemHealth
        } else {
            Write-UnifiedLog "Phase 3: Skipped health checks" -Level Warning -Component "Phase3"
            $healthResult = @{ AllHealthy = $true; HealthPercentage = 100 }
        }
        
        # Phase 4: System Summary
        $duration = (Get-Date) - $startTime
        
        Write-UnifiedLog "Enhanced Documentation System Startup Complete" -Level Success -Component "Summary"
        Write-UnifiedLog "Duration: $($duration.ToString('mm\:ss'))" -Level Info -Component "Summary"
        Write-UnifiedLog "PowerShell Modules: $($moduleResult.LoadedModules.Count) loaded" -Level Info -Component "Summary"
        Write-UnifiedLog "Docker Services: $(if ($dockerResult) { 'Started' } else { 'Skipped/Failed' })" -Level Info -Component "Summary"
        Write-UnifiedLog "System Health: $($healthResult.HealthPercentage)%" -Level Info -Component "Summary"
        
        # Access information
        Write-UnifiedLog "🌐 Service Access URLs:" -Level Success -Component "Access"
        Write-UnifiedLog "  📚 Documentation: http://localhost:8080" -Level Success -Component "Access"
        Write-UnifiedLog "  🔌 API Documentation: http://localhost:8091" -Level Success -Component "Access"
        Write-UnifiedLog "  🤖 LangGraph AI: http://localhost:8000" -Level Success -Component "Access"
        Write-UnifiedLog "  👥 AutoGen GroupChat: http://localhost:8001" -Level Success -Component "Access"
        Write-UnifiedLog "  💻 PowerShell: Local session with loaded modules" -Level Success -Component "Access"
        
        # Week 4 Features Summary
        Write-UnifiedLog "🔮 Week 4 Predictive Features Available:" -Level Success -Component "Week4"
        if (Get-Command Get-GitCommitHistory -ErrorAction SilentlyContinue) {
            Write-UnifiedLog "  ✅ Code Evolution Analysis (Get-GitCommitHistory, Get-CodeChurnMetrics)" -Level Success -Component "Week4"
        }
        if (Get-Command Get-TechnicalDebt -ErrorAction SilentlyContinue) {
            Write-UnifiedLog "  ✅ Maintenance Prediction (Get-TechnicalDebt, Get-MaintenancePrediction)" -Level Success -Component "Week4"
        }
        
        # Create unified status summary
        $summary = @{
            StartupId = "unified-$(Get-Date -Format 'yyyyMMdd-HHmmss')"
            Environment = $Environment
            DeploymentMode = $DeploymentMode
            StartTime = $startTime.ToString('yyyy-MM-dd HH:mm:ss')
            Duration = $duration.ToString('mm\:ss')
            PowerShellModules = $moduleResult
            DockerServices = $dockerResult
            SystemHealth = $healthResult
            Week4Features = @{
                CodeEvolution = (Get-Command Get-GitCommitHistory -ErrorAction SilentlyContinue) -ne $null
                MaintenancePrediction = (Get-Command Get-TechnicalDebt -ErrorAction SilentlyContinue) -ne $null
            }
            AccessUrls = @{
                Documentation = "http://localhost:8080"
                API = "http://localhost:8091"
                LangGraph = "http://localhost:8000"
                AutoGen = "http://localhost:8001"
            }
        }
        
        $summary | ConvertTo-Json -Depth 5 | Out-File -FilePath "unified-system-status.json" -Encoding UTF8
        
        # Final status
        $overallSuccess = $moduleResult.Success -and ($dockerResult -or $DeploymentMode -eq 'Local') -and ($healthResult.AllHealthy -or $SkipHealthChecks)
        
        if ($overallSuccess) {
            Write-UnifiedLog "🎉 ENHANCED DOCUMENTATION SYSTEM v2.0.0 FULLY OPERATIONAL!" -Level Success -Component "Final"
            Write-UnifiedLog "All systems integrated and ready for use" -Level Success -Component "Final"
            return $summary
        } else {
            Write-UnifiedLog "⚠️ System started with warnings - check logs for details" -Level Warning -Component "Final"
            return $summary
        }
        
    } catch {
        Write-UnifiedLog "Unified system startup failed: $($_.Exception.Message)" -Level Error -Component "Error"
        Write-UnifiedLog "Stack trace: $($_.ScriptStackTrace)" -Level Debug -Component "Error"
        throw
    }
}

# Execute unified system startup
Write-Host "=== Enhanced Documentation System v2.0.0 - Unified Startup ===" -ForegroundColor Cyan
Write-Host "Integrating Docker Compose + PowerShell + AI Services" -ForegroundColor Yellow

$result = Start-EnhancedDocumentationSystem

Write-Host "`n=== Unified Documentation System Startup Complete ===" -ForegroundColor Green

return $result