# SystemStatus Configuration Schema
**File**: systemstatus.config.json  
**Purpose**: Central configuration for Unity-Claude-SystemStatus module  
**Environment Override Prefix**: UNITYC_

## Configuration Sections

### SystemStatus
Core system monitoring and operation settings.

| Setting | Type | Default | Environment Variable | Description |
|---------|------|---------|---------------------|-------------|
| MonitoringInterval | int | 30 | UNITYC_MONITORING_INTERVAL | Seconds between monitoring checks |
| LogLevel | string | "INFO" | UNITYC_LOG_LEVEL | Logging level: DEBUG, INFO, WARN, ERROR |
| EnableMutex | bool | true | UNITYC_ENABLE_MUTEX | Enable mutex-based singleton enforcement |
| MutexPrefix | string | "Global\\UnityClaudeSubsystem" | UNITYC_MUTEX_PREFIX | Mutex name prefix for subsystems |
| ManifestSearchPaths | array | [see default] | UNITYC_MANIFEST_PATHS | Paths to search for manifest files |
| SystemStatusFilePath | string | ".\\system_status.json" | UNITYC_STATUS_FILE | Path to system status file |
| MaxRetries | int | 3 | UNITYC_MAX_RETRIES | Maximum retry attempts for operations |
| RetryDelayMs | int | 1000 | UNITYC_RETRY_DELAY | Delay between retries in milliseconds |

### CircuitBreaker
Circuit breaker pattern configuration for failure detection and recovery.

| Setting | Type | Default | Environment Variable | Description |
|---------|------|---------|---------------------|-------------|
| EnableCircuitBreaker | bool | true | UNITYC_CB_ENABLE | Enable circuit breaker functionality |
| FailureThreshold | int | 3 | UNITYC_CB_THRESHOLD | Failures before opening circuit |
| TimeoutSeconds | int | 60 | UNITYC_CB_TIMEOUT | Seconds in open state before half-open |
| MaxTestRequests | int | 1 | UNITYC_CB_MAX_TESTS | Max test requests in half-open state |
| HalfOpenRetryCount | int | 1 | UNITYC_CB_RETRY_COUNT | Retry attempts in half-open state |

### HealthMonitoring
Health check system configuration and performance settings.

| Setting | Type | Default | Environment Variable | Description |
|---------|------|---------|---------------------|-------------|
| ParallelHealthChecks | bool | true | UNITYC_HM_PARALLEL | Enable parallel health checking |
| ThrottleLimit | int | 4 | UNITYC_HM_THROTTLE | Max concurrent health checks |
| HealthCheckTimeout | int | 30 | UNITYC_HM_TIMEOUT | Health check timeout in seconds |
| IncludePerformanceData | bool | false | UNITYC_HM_PERF_DATA | Include CPU/memory metrics |
| DefaultHealthCheckInterval | int | 30 | UNITYC_HM_INTERVAL | Default check interval for subsystems |
| MaxParallelHealthChecks | int | 8 | UNITYC_HM_MAX_PARALLEL | Absolute max parallel checks |

### Logging
Logging system configuration and file management.

| Setting | Type | Default | Environment Variable | Description |
|---------|------|---------|---------------------|-------------|
| EnableDetailedLogging | bool | true | UNITYC_LOG_DETAILED | Enable detailed debug logging |
| LogRotationSize | string | "10MB" | UNITYC_LOG_SIZE | Max log file size before rotation |
| MaxLogFiles | int | 5 | UNITYC_LOG_MAX_FILES | Maximum number of log files to keep |
| LogFilePath | string | ".\\unity_claude_automation.log" | UNITYC_LOG_PATH | Path to log file |
| EnableTraceLogging | bool | false | UNITYC_LOG_TRACE | Enable trace-level logging |

### Performance
Performance optimization and caching configuration.

| Setting | Type | Default | Environment Variable | Description |
|---------|------|---------|---------------------|-------------|
| CacheConfigurationMs | int | 30000 | UNITYC_PERF_CACHE_MS | Configuration cache duration |
| EnableConfigurationCaching | bool | true | UNITYC_PERF_CACHE_ENABLE | Enable configuration caching |
| MaxConfigurationAge | int | 300000 | UNITYC_PERF_MAX_AGE | Max config age before refresh |
| FileWatcherEnabled | bool | true | UNITYC_PERF_WATCHER | Enable file change watching |

### Security
Security and validation settings.

| Setting | Type | Default | Environment Variable | Description |
|---------|------|---------|---------------------|-------------|
| ValidateManifestSignatures | bool | false | UNITYC_SEC_VALIDATE_SIG | Validate manifest signatures |
| RequireSecureConfiguration | bool | false | UNITYC_SEC_REQUIRE_SECURE | Require encrypted configuration |
| AllowEnvironmentOverrides | bool | true | UNITYC_SEC_ALLOW_ENV | Allow environment variable overrides |
| SensitiveConfigKeys | array | [see default] | UNITYC_SEC_SENSITIVE_KEYS | Keys treated as sensitive |

### Subsystems
Default settings for subsystem management.

| Setting | Type | Default | Environment Variable | Description |
|---------|------|---------|---------------------|-------------|
| DefaultRestartPolicy | string | "OnFailure" | UNITYC_SUB_RESTART_POLICY | Default restart policy for subsystems |
| DefaultMaxRestarts | int | 3 | UNITYC_SUB_MAX_RESTARTS | Default maximum restart attempts |
| DefaultRestartDelay | int | 5 | UNITYC_SUB_RESTART_DELAY | Default delay between restarts |
| DefaultMaxMemoryMB | int | 500 | UNITYC_SUB_MAX_MEMORY | Default memory limit in MB |
| DefaultMaxCpuPercent | int | 25 | UNITYC_SUB_MAX_CPU | Default CPU usage limit |

## Configuration Precedence
Configuration values are loaded in the following order (last wins):

1. **Embedded Defaults** - Built into Get-SystemStatusConfiguration function
2. **JSON Configuration File** - systemstatus.config.json
3. **Environment Variables** - UNITYC_* prefixed variables
4. **Parameter Overrides** - Direct function parameters (testing)

## Validation Rules

### Data Types
- **int**: Must be positive integers for timeouts, limits, and intervals
- **bool**: true/false values only
- **string**: Non-empty strings for paths and identifiers
- **array**: Valid array format for paths and lists

### Value Ranges
- MonitoringInterval: 5-3600 seconds
- FailureThreshold: 1-10 failures
- TimeoutSeconds: 10-600 seconds
- ThrottleLimit: 1-16 concurrent operations
- LogLevel: DEBUG, INFO, WARN, ERROR

### Path Validation
- File paths must be accessible to PowerShell process
- Relative paths resolved from module root
- Network paths supported with proper permissions

## Examples

### Development Configuration
```json
{
    "SystemStatus": {
        "MonitoringInterval": 10,
        "LogLevel": "DEBUG"
    },
    "Logging": {
        "EnableDetailedLogging": true,
        "EnableTraceLogging": true
    }
}
```

### Production Configuration
```json
{
    "SystemStatus": {
        "MonitoringInterval": 60,
        "LogLevel": "WARN"
    },
    "CircuitBreaker": {
        "FailureThreshold": 5,
        "TimeoutSeconds": 120
    }
}
```

### High Performance Configuration
```json
{
    "HealthMonitoring": {
        "ParallelHealthChecks": true,
        "ThrottleLimit": 8,
        "MaxParallelHealthChecks": 16
    },
    "Performance": {
        "CacheConfigurationMs": 60000,
        "EnableConfigurationCaching": true
    }
}
```