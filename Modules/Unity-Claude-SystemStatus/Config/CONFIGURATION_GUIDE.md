# Unity-Claude-SystemStatus Configuration Guide

## Overview

The Unity-Claude-SystemStatus module uses a layered configuration system that combines:
1. **Default Configuration** - Built-in fallback values
2. **JSON Configuration** - File-based settings (`systemstatus.config.json`)
3. **Environment Variables** - Runtime overrides with `UNITYC_` prefix
4. **Parameter Overrides** - Function-level configuration

## Quick Start

### 1. Basic Setup
```powershell
# Copy example configuration
Copy-Item ".\Modules\Unity-Claude-SystemStatus\Config\examples\development.config.json" `
          ".\Modules\Unity-Claude-SystemStatus\Config\systemstatus.config.json"

# Load configuration
$config = Get-SystemStatusConfiguration
```

### 2. Environment-Specific Configuration
```powershell
# Development
Copy-Item ".\Config\examples\development.config.json" ".\Config\systemstatus.config.json"

# Production
Copy-Item ".\Config\examples\production.config.json" ".\Config\systemstatus.config.json"

# High-performance
Copy-Item ".\Config\examples\high-performance.config.json" ".\Config\systemstatus.config.json"
```

## Configuration Sections

### SystemStatus
Controls core monitoring behavior:
```json
{
    "SystemStatus": {
        "MonitoringInterval": 30,     // Seconds between health checks (5-3600)
        "LogLevel": "INFO",           // TRACE, DEBUG, INFO, WARN, ERROR
        "EnableMutex": true,          // Enable cross-process synchronization
        "MaxRetries": 3,              // Maximum retry attempts (1-10)
        "RetryDelayMs": 1000         // Delay between retries (100-10000)
    }
}
```

### CircuitBreaker
Manages circuit breaker patterns:
```json
{
    "CircuitBreaker": {
        "EnableCircuitBreaker": true,    // Enable circuit breaker protection
        "FailureThreshold": 3,           // Failures before opening (1-10)
        "TimeoutSeconds": 60,            // Timeout before half-open (10-600)
        "MaxTestRequests": 1,            // Test requests in half-open (1-5)
        "HalfOpenRetryCount": 1          // Retries in half-open state (1-3)
    }
}
```

### HealthMonitoring
Controls health check execution:
```json
{
    "HealthMonitoring": {
        "ParallelHealthChecks": true,        // Enable parallel execution
        "ThrottleLimit": 4,                  // Max concurrent checks (1-20)
        "HealthCheckTimeout": 30,            // Timeout per check (5-300)
        "IncludePerformanceData": true,      // Include perf counters
        "DefaultHealthCheckInterval": 30,    // Default interval (5-3600)
        "MaxParallelHealthChecks": 8         // Global parallel limit (1-50)
    }
}
```

### Logging
Manages logging behavior:
```json
{
    "Logging": {
        "EnableDetailedLogging": true,       // Enable detailed logs
        "LogRotationSize": "10MB",           // Size before rotation
        "MaxLogFiles": 5,                    // Max rotated files (1-20)
        "LogFilePath": "./logs/unity_claude_automation.log",
        "EnableTraceLogging": false          // Enable TRACE level
    }
}
```

### Performance
Controls performance optimizations:
```json
{
    "Performance": {
        "CacheConfigurationMs": 30000,      // Config cache duration (1000-300000)
        "EnableConfigurationCaching": true, // Enable config caching
        "MaxConfigurationAge": 300000,      // Max cache age (10000-3600000)
        "FileWatcherEnabled": true          // Auto-reload on file changes
    }
}
```

### Security
Security-related settings:
```json
{
    "Security": {
        "ValidateManifestSignatures": false,  // Validate signed manifests
        "RequireSecureConfiguration": false,  // Require encrypted config
        "AllowEnvironmentOverrides": true     // Allow env var overrides
    }
}
```

### Subsystems
Default settings for subsystems:
```json
{
    "Subsystems": {
        "DefaultRestartPolicy": "OnFailure", // OnFailure, Never, Always
        "DefaultMaxRestarts": 3,              // Max restart attempts (0-10)
        "DefaultRestartDelay": 5,             // Delay between restarts (1-60)
        "DefaultMaxMemoryMB": 500,            // Memory limit (50-2000)
        "DefaultMaxCpuPercent": 25            // CPU limit (5-80)
    }
}
```

## Environment Variable Overrides

All configuration values can be overridden using environment variables with the `UNITYC_` prefix:

### System Status Overrides
```powershell
$env:UNITYC_MONITORING_INTERVAL = "15"
$env:UNITYC_LOG_LEVEL = "DEBUG"
$env:UNITYC_ENABLE_MUTEX = "true"
$env:UNITYC_MAX_RETRIES = "5"
$env:UNITYC_RETRY_DELAY_MS = "500"
```

### Circuit Breaker Overrides
```powershell
$env:UNITYC_CB_ENABLE = "true"
$env:UNITYC_CB_FAILURE_THRESHOLD = "5"
$env:UNITYC_CB_TIMEOUT_SECONDS = "120"
$env:UNITYC_CB_MAX_TEST_REQUESTS = "2"
$env:UNITYC_CB_HALF_OPEN_RETRY_COUNT = "2"
```

### Health Monitoring Overrides
```powershell
$env:UNITYC_HM_PARALLEL_CHECKS = "true"
$env:UNITYC_HM_THROTTLE_LIMIT = "8"
$env:UNITYC_HM_TIMEOUT = "45"
$env:UNITYC_HM_INCLUDE_PERFORMANCE = "false"
```

### Complete Environment Variable Reference
| Configuration Path | Environment Variable | Type | Example |
|-------------------|---------------------|------|---------|
| SystemStatus.MonitoringInterval | UNITYC_MONITORING_INTERVAL | Integer | 30 |
| SystemStatus.LogLevel | UNITYC_LOG_LEVEL | String | INFO |
| SystemStatus.EnableMutex | UNITYC_ENABLE_MUTEX | Boolean | true |
| CircuitBreaker.EnableCircuitBreaker | UNITYC_CB_ENABLE | Boolean | true |
| CircuitBreaker.FailureThreshold | UNITYC_CB_FAILURE_THRESHOLD | Integer | 3 |
| CircuitBreaker.TimeoutSeconds | UNITYC_CB_TIMEOUT_SECONDS | Integer | 60 |
| HealthMonitoring.ParallelHealthChecks | UNITYC_HM_PARALLEL_CHECKS | Boolean | true |
| HealthMonitoring.ThrottleLimit | UNITYC_HM_THROTTLE_LIMIT | Integer | 4 |
| Logging.EnableDetailedLogging | UNITYC_LOG_DETAILED | Boolean | true |
| Performance.EnableConfigurationCaching | UNITYC_PERF_CACHE_CONFIG | Boolean | true |

## Advanced Configuration

### Subsystem-Specific Circuit Breaker Overrides

Create subsystem manifests with circuit breaker overrides:

```json
// Unity-Claude-Core.manifest.psd1 equivalent JSON section
{
    "CircuitBreaker": {
        "FailureThreshold": 5,        // Higher threshold for critical subsystem
        "TimeoutSeconds": 30,         // Shorter timeout for faster recovery
        "MaxTestRequests": 2          // More test requests for reliability
    }
}
```

### Configuration Precedence

Configuration values are applied in this order (later values override earlier ones):

1. **Built-in Defaults** - Hardcoded fallback values
2. **JSON Configuration** - Values from `systemstatus.config.json`
3. **Environment Variables** - Runtime overrides with `UNITYC_` prefix
4. **Function Parameters** - Direct parameter overrides

### Runtime Configuration Changes

```powershell
# Force configuration reload
$config = Get-SystemStatusConfiguration -ForceRefresh

# Override specific values at runtime
$overrides = @{
    'SystemStatus.LogLevel' = 'DEBUG'
    'CircuitBreaker.FailureThreshold' = 5
}
$config = Get-SystemStatusConfiguration -Overrides $overrides

# Check configuration source
Write-Host "Configuration loaded from: $($config.ConfigurationMetadata.Sources -join ', ')"
```

## Usage Examples

### Example 1: Development Environment Setup
```powershell
# Set up development environment
Copy-Item ".\Config\examples\development.config.json" ".\Config\systemstatus.config.json"

# Override log level for current session
$env:UNITYC_LOG_LEVEL = "TRACE"

# Load configuration
$config = Get-SystemStatusConfiguration

# Verify settings
Write-Host "Log Level: $($config.SystemStatus.LogLevel)"        # Should be TRACE
Write-Host "Monitoring Interval: $($config.SystemStatus.MonitoringInterval)"  # Should be 10
Write-Host "Circuit Breaker Threshold: $($config.CircuitBreaker.FailureThreshold)"  # Should be 2
```

### Example 2: Production Deployment
```powershell
# Deploy production configuration
Copy-Item ".\Config\examples\production.config.json" ".\Config\systemstatus.config.json"

# Set production environment variables
$env:UNITYC_LOG_LEVEL = "ERROR"
$env:UNITYC_CB_FAILURE_THRESHOLD = "10"
$env:UNITYC_HM_INCLUDE_PERFORMANCE = "false"

# Load and validate configuration
$config = Get-SystemStatusConfiguration
$validation = Test-SystemStatusConfiguration -Config $config

if (-not $validation.IsValid) {
    throw "Invalid production configuration: $($validation.Errors -join ', ')"
}
```

### Example 3: Dynamic Circuit Breaker Configuration
```powershell
# Load base configuration
$config = Get-SystemStatusConfiguration

# Get circuit breaker config for specific subsystem
$coreSubsystemConfig = Get-SubsystemCircuitBreakerConfig -SubsystemName "Unity-Claude-Core" -BaseConfig $config.CircuitBreaker

# Check configuration source
Write-Host "Config source: $($coreSubsystemConfig.ConfigurationSource)"

# Apply circuit breaker check
$result = Invoke-CircuitBreakerCheck -SubsystemName "Unity-Claude-Core" -TestResult $true
Write-Host "Circuit breaker state: $($result.State)"
```

### Example 4: Configuration Monitoring
```powershell
# Enable file watching for automatic configuration reloads
$config = Get-SystemStatusConfiguration

if ($config.Performance.FileWatcherEnabled) {
    Write-Host "Configuration file watching enabled"
    
    # Monitor configuration changes
    while ($true) {
        Start-Sleep 10
        $newConfig = Get-SystemStatusConfiguration
        
        if ($newConfig.ConfigurationMetadata.LastModified -gt $config.ConfigurationMetadata.LastModified) {
            Write-Host "Configuration file changed, reloading..."
            $config = $newConfig
        }
    }
}
```

## Configuration Validation

### Manual Validation
```powershell
# Test configuration file syntax
try {
    $content = Get-Content ".\Config\systemstatus.config.json" -Raw
    $json = ConvertFrom-Json $content
    Write-Host "JSON syntax is valid"
} catch {
    Write-Error "JSON syntax error: $($_.Exception.Message)"
}

# Test configuration logic
$config = Get-SystemStatusConfiguration
$validation = Test-SystemStatusConfiguration -Config $config

Write-Host "Validation Result: $($validation.IsValid)"
if ($validation.Errors) {
    Write-Host "Errors: $($validation.Errors -join ', ')"
}
if ($validation.Warnings) {
    Write-Host "Warnings: $($validation.Warnings -join ', ')"
}
```

### Automated Validation Script
```powershell
# Save as Validate-Configuration.ps1
param(
    [string]$ConfigPath = ".\Config\systemstatus.config.json"
)

if (-not (Test-Path $ConfigPath)) {
    Write-Error "Configuration file not found: $ConfigPath"
    exit 1
}

try {
    $config = Get-SystemStatusConfiguration -ConfigPath $ConfigPath -ForceRefresh
    $validation = Test-SystemStatusConfiguration -Config $config
    
    if ($validation.IsValid) {
        Write-Host "✓ Configuration is valid" -ForegroundColor Green
        exit 0
    } else {
        Write-Host "✗ Configuration validation failed" -ForegroundColor Red
        $validation.Errors | ForEach-Object { Write-Host "  Error: $_" -ForegroundColor Red }
        exit 1
    }
} catch {
    Write-Host "✗ Configuration loading failed: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}
```

## Best Practices

1. **Version Control**: Keep configuration files in version control
2. **Environment Separation**: Use different config files for dev/test/prod
3. **Validation**: Always validate configuration before deployment
4. **Documentation**: Document any custom subsystem overrides
5. **Monitoring**: Monitor configuration file changes in production
6. **Security**: Use environment variables for sensitive settings
7. **Testing**: Test configuration changes in development first
8. **Backup**: Backup working configurations before changes