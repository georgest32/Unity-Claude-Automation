# Validate-ContainerStartup.ps1
# Research-validated container startup validation for 100% deployment success
# Implements intelligent timing and comprehensive service validation
# Date: 2025-08-29

param(
    [ValidateSet('Development', 'Staging', 'Production')]
    [string]$Environment = 'Production',
    
    [int]$MaxWaitMinutes = 10,
    [switch]$UseEnhancedConfig,
    [switch]$Verbose
)

if ($Verbose) { $VerbosePreference = "Continue" }

Write-Host "=== Enhanced Container Startup Validation ===" -ForegroundColor Cyan
Write-Host "Research-validated service initialization with optimal timing" -ForegroundColor Yellow

function Write-ValidateLog {
    param([string]$Message, [string]$Level = "Info")
    
    $color = switch ($Level) {
        "Success" { "Green" }
        "Warning" { "Yellow" }
        "Error" { "Red" }
        "Debug" { "Cyan" }
        default { "White" }
    }
    
    $timestamp = Get-Date -Format 'HH:mm:ss.fff'
    Write-Host "[$timestamp] [$Level] $Message" -ForegroundColor $color
}

# Research-validated service configuration with graduated timing
$serviceConfig = @{
    "powershell-modules" = @{
        ContainerName = "unity-claude-powershell"
        HealthUrl = "http://localhost:5985"
        InitTime = 120  # PowerShell service needs extended initialization
        CheckInterval = 15
        Description = "PowerShell Module Service"
    }
    "docs-server" = @{
        ContainerName = "unity-claude-docs"
        HealthUrl = "http://localhost:8080"
        InitTime = 90   # Web server initialization
        CheckInterval = 10
        Description = "Documentation Web Server"
    }
    "docs-api" = @{
        ContainerName = "unity-claude-docs-api"
        HealthUrl = "http://localhost:8091/health"
        InitTime = 75   # API service initialization
        CheckInterval = 10
        Description = "Documentation REST API"
    }
    "langgraph-api" = @{
        ContainerName = "unity-claude-langgraph"
        HealthUrl = "http://localhost:8000/health"
        InitTime = 150  # AI service needs extended time
        CheckInterval = 20
        Description = "LangGraph AI Service"
    }
}

function Test-ContainerStatus {
    param([string]$ContainerName)
    
    try {
        $containerInfo = docker inspect $ContainerName --format '{{.State.Status}}' 2>$null
        
        if ($LASTEXITCODE -eq 0) {
            return $containerInfo.Trim()
        } else {
            return "not-found"
        }
    } catch {
        return "error"
    }
}

function Get-ContainerLogs {
    param([string]$ContainerName, [int]$Lines = 5)
    
    try {
        $logs = docker logs $ContainerName --tail $Lines 2>$null
        return $logs
    } catch {
        return @("Unable to retrieve logs")
    }
}

function Wait-ForServiceWithIntelligentTiming {
    param(
        [string]$ServiceName,
        [hashtable]$Config
    )
    
    Write-ValidateLog "Validating service: $($Config.Description)" -Level "Info"
    
    # Step 1: Verify container is running
    $containerStatus = Test-ContainerStatus -ContainerName $Config.ContainerName
    
    if ($containerStatus -ne "running") {
        Write-ValidateLog "Container $($Config.ContainerName) status: $containerStatus" -Level "Error"
        return $false
    }
    
    Write-ValidateLog "Container $($Config.ContainerName) is running - waiting for service initialization" -Level "Success"
    
    # Step 2: Research-validated initial delay for service initialization
    Write-ValidateLog "Initial delay: $($Config.InitTime) seconds for $($Config.Description) initialization" -Level "Info"
    
    $delayIncrement = 30
    $remainingTime = $Config.InitTime
    
    while ($remainingTime -gt 0) {
        $waitTime = [math]::Min($delayIncrement, $remainingTime)
        Start-Sleep -Seconds $waitTime
        $remainingTime -= $waitTime
        
        Write-ValidateLog "Initialization progress: $($Config.InitTime - $remainingTime)/$($Config.InitTime) seconds" -Level "Debug"
    }
    
    # Step 3: Intelligent health checking with retry logic
    $maxAttempts = ($MaxWaitMinutes * 60) / $Config.CheckInterval
    $attempts = 0
    
    Write-ValidateLog "Starting health checks for $($Config.Description) (max $maxAttempts attempts)" -Level "Info"
    
    while ($attempts -lt $maxAttempts) {
        $attempts++
        
        try {
            Write-ValidateLog "Health check $attempts/$maxAttempts for $($Config.Description)" -Level "Debug"
            
            # Research-validated health check with proper timeout
            $response = Invoke-WebRequest -Uri $Config.HealthUrl -TimeoutSec 10 -UseBasicParsing -ErrorAction Stop
            
            if ($response.StatusCode -eq 200) {
                Write-ValidateLog "$($Config.Description) is healthy (HTTP $($response.StatusCode))" -Level "Success"
                return $true
            }
            
        } catch {
            Write-ValidateLog "$($Config.Description) health check failed: $($_.Exception.Message)" -Level "Debug"
            
            # Research-validated debugging: Check container logs for issues
            if ($attempts % 3 -eq 0) {  # Every 3rd attempt, check logs
                $logs = Get-ContainerLogs -ContainerName $Config.ContainerName -Lines 3
                if ($logs) {
                    Write-ValidateLog "Recent container logs: $($logs[-1])" -Level "Debug"
                }
            }
        }
        
        if ($attempts -lt $maxAttempts) {
            Start-Sleep -Seconds $Config.CheckInterval
        }
    }
    
    Write-ValidateLog "$($Config.Description) failed to become healthy within $MaxWaitMinutes minutes" -Level "Error"
    
    # Final diagnostic information
    Write-ValidateLog "Final diagnostics for $($Config.Description):" -Level "Warning"
    $finalLogs = Get-ContainerLogs -ContainerName $Config.ContainerName -Lines 10
    foreach ($log in $finalLogs) {
        Write-ValidateLog "  Log: $log" -Level "Debug"
    }
    
    return $false
}

# Main validation execution
Write-ValidateLog "Container Startup Validation Started" -Level "Success"
Write-ValidateLog "Environment: $Environment" -Level "Info"
Write-ValidateLog "Enhanced Configuration: $UseEnhancedConfig" -Level "Info"

$validationResults = @{}
$allServicesHealthy = $true

# Validate each service with research-optimized timing
foreach ($serviceName in $serviceConfig.Keys) {
    $config = $serviceConfig[$serviceName]
    
    Write-ValidateLog "Starting validation for: $serviceName" -Level "Info"
    
    $serviceHealthy = Wait-ForServiceWithIntelligentTiming -ServiceName $serviceName -Config $config
    
    $validationResults[$serviceName] = @{
        Config = $config
        Healthy = $serviceHealthy
        Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    }
    
    if (-not $serviceHealthy) {
        $allServicesHealthy = $false
    }
}

# Comprehensive validation summary
Write-Host "`n=== Container Startup Validation Summary ===" -ForegroundColor Cyan

$healthyCount = ($validationResults.Values | Where-Object { $_.Healthy }).Count
$totalCount = $validationResults.Count

Write-ValidateLog "Service Health Summary: $healthyCount/$totalCount services healthy" -Level "Info"

foreach ($serviceName in $validationResults.Keys) {
    $result = $validationResults[$serviceName]
    $status = if ($result.Healthy) { "HEALTHY" } else { "UNHEALTHY" }
    $color = if ($result.Healthy) { "Success" } else { "Error" }
    
    Write-ValidateLog "$serviceName ($($result.Config.Description)): $status" -Level $color
}

$successRate = [math]::Round(($healthyCount / $totalCount) * 100, 1)
Write-ValidateLog "Overall Success Rate: $successRate%" -Level "Info"

# Final assessment
if ($allServicesHealthy) {
    Write-ValidateLog "🎉 100% CONTAINER STARTUP SUCCESS!" -Level "Success"
    Write-ValidateLog "All services healthy and ready for production use" -Level "Success"
    exit 0
} else {
    Write-ValidateLog "⚠️ Container startup validation incomplete" -Level "Warning"
    Write-ValidateLog "Unhealthy services require investigation and optimization" -Level "Warning"
    
    # Provide research-validated troubleshooting guidance
    Write-ValidateLog "Research-validated troubleshooting steps:" -Level "Info"
    Write-ValidateLog "1. Check container logs: docker logs <container-name>" -Level "Info"
    Write-ValidateLog "2. Verify port binding: docker port <container-name>" -Level "Info"
    Write-ValidateLog "3. Test container network: docker exec -it <container-name> netstat -tlnp" -Level "Info"
    Write-ValidateLog "4. Use enhanced config: docker-compose -f docker-compose-enhanced.yml" -Level "Info"
    
    exit 1
}

Write-Host "`n=== Container Startup Validation Complete ===" -ForegroundColor Green