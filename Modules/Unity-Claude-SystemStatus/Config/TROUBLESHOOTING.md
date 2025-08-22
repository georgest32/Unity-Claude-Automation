# Unity-Claude-SystemStatus Configuration Troubleshooting Guide

## Common Configuration Issues

### 1. Configuration File Not Found

**Symptoms:**
- Warning: "JSON configuration file not found"
- Using default configuration only

**Solutions:**
```powershell
# Check if config file exists
Test-Path ".\Modules\Unity-Claude-SystemStatus\Config\systemstatus.config.json"

# Create config from example
Copy-Item ".\Modules\Unity-Claude-SystemStatus\Config\examples\development.config.json" `
          ".\Modules\Unity-Claude-SystemStatus\Config\systemstatus.config.json"
```

### 2. Invalid JSON Configuration

**Symptoms:**
- Error: "Error loading JSON configuration"
- Falling back to default configuration

**Solutions:**
```powershell
# Validate JSON syntax
try {
    $content = Get-Content ".\Modules\Unity-Claude-SystemStatus\Config\systemstatus.config.json" -Raw
    ConvertFrom-Json $content
    Write-Host "JSON is valid"
} catch {
    Write-Host "JSON Error: $($_.Exception.Message)"
}

# Common JSON issues:
# - Missing quotes around strings
# - Trailing commas
# - Incorrect boolean values (use true/false, not True/False)
```

### 3. Configuration Validation Failures

**Symptoms:**
- Error: "Configuration validation failed"
- Specific validation error messages

**Common Issues and Fixes:**

#### MonitoringInterval Out of Range
```json
// Wrong (outside 5-3600 range)
"MonitoringInterval": 3

// Correct
"MonitoringInterval": 30
```

#### Invalid LogLevel
```json
// Wrong
"LogLevel": "Debug"

// Correct
"LogLevel": "DEBUG"
```

#### Circuit Breaker Threshold Issues
```json
// Wrong (outside 1-10 range)
"FailureThreshold": 0

// Correct
"FailureThreshold": 3
```

### 4. Environment Variable Override Issues

**Symptoms:**
- Environment variables not being applied
- Unexpected configuration values

**Debugging:**
```powershell
# Check environment variables
Get-ChildItem Env: | Where-Object Name -like "UNITYC_*"

# Test specific variable
$env:UNITYC_LOG_LEVEL = "DEBUG"
$config = Get-SystemStatusConfiguration -ForceRefresh
$config.SystemStatus.LogLevel  # Should be "DEBUG"
```

**Common Environment Variable Issues:**
- Incorrect variable names (must start with UNITYC_)
- Invalid values for type (e.g., "yes" instead of "true" for boolean)
- Case sensitivity in values

### 5. Configuration Caching Issues

**Symptoms:**
- Configuration changes not taking effect
- Old values being used

**Solutions:**
```powershell
# Force refresh configuration
$config = Get-SystemStatusConfiguration -ForceRefresh

# Clear configuration cache
$script:ConfigurationCache = @{}

# Check cache status
if ($script:ConfigurationCache) {
    $script:ConfigurationCache.Keys | ForEach-Object {
        $cache = $script:ConfigurationCache[$_]
        Write-Host "Cache: $_ - Age: $((Get-Date) - $cache.LoadTime)"
    }
}
```

### 6. Circuit Breaker Configuration Issues

**Symptoms:**
- Circuit breaker not opening/closing as expected
- Configuration changes not applying to existing circuit breakers

**Debugging:**
```powershell
# Check circuit breaker state
$cbStatus = Invoke-CircuitBreakerCheck -SubsystemName "TestSubsystem" -TestResult $false
$cbStatus | Format-List

# Check configuration source
$config = Get-SubsystemCircuitBreakerConfig -SubsystemName "TestSubsystem" -BaseConfig @{
    FailureThreshold = 3
    TimeoutSeconds = 60
    MaxTestRequests = 1
    HalfOpenRetryCount = 1
}
Write-Host "Config Source: $($config.ConfigurationSource)"
```

### 7. Subsystem Manifest Override Issues

**Symptoms:**
- Manifest overrides not being applied
- Unexpected circuit breaker behavior for specific subsystems

**Solutions:**
```powershell
# Check if subsystem manifest exists
$manifest = Get-SubsystemManifest -SubsystemName "YourSubsystem" -ErrorAction SilentlyContinue
if ($manifest) {
    Write-Host "Manifest found"
    if ($manifest.CircuitBreaker) {
        Write-Host "Circuit breaker overrides: $($manifest.CircuitBreaker | ConvertTo-Json)"
    }
} else {
    Write-Host "No manifest found"
}
```

## Diagnostic Commands

### Check Overall Configuration Health
```powershell
# Test configuration loading
try {
    $config = Get-SystemStatusConfiguration -ForceRefresh
    Write-Host "Configuration loaded successfully"
    Write-Host "Sections: $($config.Keys -join ', ')"
} catch {
    Write-Host "Configuration error: $($_.Exception.Message)"
}
```

### Validate Configuration Schema
```powershell
# Test configuration validation
$config = Get-SystemStatusConfiguration
$validation = Test-SystemStatusConfiguration -Config $config

if ($validation.IsValid) {
    Write-Host "Configuration is valid"
} else {
    Write-Host "Validation errors:"
    $validation.Errors | ForEach-Object { Write-Host "  - $_" }
}

if ($validation.Warnings.Count -gt 0) {
    Write-Host "Warnings:"
    $validation.Warnings | ForEach-Object { Write-Host "  - $_" }
}
```

### Check Performance Settings
```powershell
$config = Get-SystemStatusConfiguration
$perf = $config.Performance

Write-Host "Configuration Caching: $($perf.EnableConfigurationCaching)"
Write-Host "Cache Age Limit: $($perf.MaxConfigurationAge)ms"
Write-Host "File Watcher: $($perf.FileWatcherEnabled)"
```

## Configuration Best Practices

### 1. Development Environment
- Use `LogLevel: "DEBUG"` for detailed troubleshooting
- Enable `EnableTraceLogging: true` for maximum detail
- Lower `MonitoringInterval` for faster feedback
- Higher `FailureThreshold` to prevent unnecessary circuit breaking during testing

### 2. Production Environment
- Use `LogLevel: "WARN"` or `"ERROR"` to reduce log volume
- Disable `EnableTraceLogging` for performance
- Higher `MonitoringInterval` to reduce resource usage
- Enable `ValidateManifestSignatures` for security

### 3. Configuration Management
- Always test configuration changes in development first
- Use environment variables for environment-specific settings
- Keep configuration files in version control
- Document any custom subsystem manifest overrides

### 4. Monitoring Configuration Changes
```powershell
# Enable file watcher for automatic configuration reloading
$config = Get-SystemStatusConfiguration
if ($config.Performance.FileWatcherEnabled) {
    Write-Host "File watcher enabled - config changes will be detected automatically"
} else {
    Write-Host "File watcher disabled - manual refresh required"
}
```

## Emergency Recovery

### If Configuration System Fails Completely
```powershell
# Get minimal fallback configuration
$minimalConfig = Get-MinimalDefaultConfiguration
Write-Host "Using emergency fallback configuration"

# Reset all configuration cache
$script:ConfigurationCache = $null

# Restart system status monitoring with defaults
Stop-SystemStatusMonitoring
Start-Sleep 2
Initialize-SystemStatusMonitoring
```

### Restore Default Configuration
```powershell
# Backup current config
if (Test-Path ".\Modules\Unity-Claude-SystemStatus\Config\systemstatus.config.json") {
    Copy-Item ".\Modules\Unity-Claude-SystemStatus\Config\systemstatus.config.json" `
              ".\Modules\Unity-Claude-SystemStatus\Config\systemstatus.config.json.backup"
}

# Get embedded defaults
$defaults = Get-DefaultSystemStatusConfiguration
$defaults | ConvertTo-Json -Depth 10 | Out-File ".\Modules\Unity-Claude-SystemStatus\Config\systemstatus.config.json"

# Force refresh
$config = Get-SystemStatusConfiguration -ForceRefresh
```

## Getting Help

If you continue to experience configuration issues:

1. Check the system status log file for detailed error messages
2. Enable DEBUG logging temporarily for more information
3. Verify PowerShell version compatibility (requires PowerShell 5.1 or later)
4. Ensure all required modules are properly loaded
5. Check file permissions on configuration directories