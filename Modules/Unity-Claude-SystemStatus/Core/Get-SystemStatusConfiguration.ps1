function Get-SystemStatusConfiguration {
    <#
    .SYNOPSIS
    Loads and validates SystemStatus configuration with layered override support
    
    .DESCRIPTION
    Implements comprehensive configuration management with:
    - Layered configuration loading (defaults -> JSON -> environment -> parameters)
    - PowerShell 5.1 compatible validation and error handling
    - Environment variable integration with UNITYC_ prefix
    - Script-scoped caching for performance optimization
    - File change detection for cache invalidation
    
    .PARAMETER ConfigPath
    Path to JSON configuration file (default: Config\systemstatus.config.json)
    
    .PARAMETER ForceRefresh
    Force refresh of cached configuration
    
    .PARAMETER Overrides
    Hashtable of configuration overrides (for testing)
    
    .EXAMPLE
    Get-SystemStatusConfiguration
    
    .EXAMPLE
    Get-SystemStatusConfiguration -ForceRefresh
    
    .EXAMPLE
    Get-SystemStatusConfiguration -Overrides @{ "SystemStatus.LogLevel" = "DEBUG" }
    #>
    [CmdletBinding()]
    param(
        [string]$ConfigPath,
        [switch]$ForceRefresh,
        [hashtable]$Overrides = @{}
    )
    
    Write-SystemStatusLog "Loading SystemStatus configuration" -Level 'DEBUG'
    
    try {
        # PowerShell version compatibility fallback for $PSScriptRoot
        $moduleRoot = $PSScriptRoot
        if (-not $moduleRoot) {
            $moduleRoot = Split-Path $MyInvocation.MyCommand.Path -Parent
            $moduleRoot = Split-Path $moduleRoot -Parent  # Go up from Core to module root
        } else {
            $moduleRoot = Split-Path $moduleRoot -Parent  # Go up from Core to module root
        }
        
        # Default configuration path
        if (-not $ConfigPath) {
            $ConfigPath = Join-Path $moduleRoot "Config\systemstatus.config.json"
        }
        
        Write-SystemStatusLog "Configuration path: $ConfigPath" -Level 'TRACE'
        
        # Check cache first (unless force refresh)
        $cacheKey = "SystemStatusConfiguration"
        if (-not $ForceRefresh -and $script:ConfigurationCache -and $script:ConfigurationCache.ContainsKey($cacheKey)) {
            $cachedConfig = $script:ConfigurationCache[$cacheKey]
            
            # Check if cache is still valid
            $cacheAge = (Get-Date) - $cachedConfig.LoadTime
            $maxAge = $cachedConfig.Config.Performance.MaxConfigurationAge
            
            if ($cacheAge.TotalMilliseconds -lt $maxAge) {
                # Check if file has changed
                $fileChanged = $false
                if (Test-Path $ConfigPath) {
                    $currentHash = Get-FileHash $ConfigPath -Algorithm MD5
                    if ($currentHash.Hash -ne $cachedConfig.FileHash) {
                        $fileChanged = $true
                        Write-SystemStatusLog "Configuration file changed, invalidating cache" -Level 'DEBUG'
                    }
                }
                
                if (-not $fileChanged) {
                    Write-SystemStatusLog "Using cached configuration (age: $([math]::Round($cacheAge.TotalSeconds, 1))s)" -Level 'TRACE'
                    return $cachedConfig.Config
                }
            } else {
                Write-SystemStatusLog "Configuration cache expired (age: $([math]::Round($cacheAge.TotalSeconds, 1))s)" -Level 'DEBUG'
            }
        }
        
        # Initialize configuration cache if not exists
        if (-not $script:ConfigurationCache) {
            $script:ConfigurationCache = @{}
        }
        
        # Step 1: Load default configuration (embedded)
        Write-SystemStatusLog "Loading default configuration" -Level 'DEBUG'
        $config = Get-DefaultSystemStatusConfiguration
        
        # Step 2: Load JSON configuration file if exists
        if (Test-Path $ConfigPath) {
            Write-SystemStatusLog "Loading JSON configuration from: $ConfigPath" -Level 'DEBUG'
            
            try {
                $jsonContent = Get-Content $ConfigPath -Raw -ErrorAction Stop
                $jsonConfig = ConvertFrom-Json $jsonContent -ErrorAction Stop
                
                # Convert PSCustomObject to hashtable for easier manipulation
                $jsonHashtable = ConvertTo-HashTable -InputObject $jsonConfig
                
                # Merge JSON configuration with defaults
                $config = Merge-Configuration -BaseConfig $config -OverrideConfig $jsonHashtable
                
                Write-SystemStatusLog "JSON configuration loaded successfully" -Level 'DEBUG'
                
            } catch {
                Write-SystemStatusLog "Error loading JSON configuration: $($_.Exception.Message)" -Level 'ERROR'
                Write-SystemStatusLog "Using default configuration only" -Level 'WARN'
                # Continue with default configuration
            }
        } else {
            Write-SystemStatusLog "JSON configuration file not found: $ConfigPath" -Level 'DEBUG'
            Write-SystemStatusLog "Using default configuration only" -Level 'INFO'
        }
        
        # Step 3: Apply environment variable overrides
        Write-SystemStatusLog "Applying environment variable overrides" -Level 'DEBUG'
        $config = Apply-EnvironmentOverrides -Config $config
        
        # Step 4: Apply parameter overrides (for testing)
        if ($Overrides.Count -gt 0) {
            Write-SystemStatusLog "Applying parameter overrides: $($Overrides.Count) settings" -Level 'DEBUG'
            $config = Apply-ParameterOverrides -Config $config -Overrides $Overrides
        }
        
        # Step 5: Validate configuration
        Write-SystemStatusLog "Validating configuration" -Level 'DEBUG'
        $validationResult = Test-SystemStatusConfiguration -Config $config
        
        if (-not $validationResult.IsValid) {
            $errorMsg = "Configuration validation failed: $($validationResult.Errors -join '; ')"
            Write-SystemStatusLog $errorMsg -Level 'ERROR'
            throw $errorMsg
        }
        
        if ($validationResult.Warnings.Count -gt 0) {
            foreach ($warning in $validationResult.Warnings) {
                Write-SystemStatusLog "Configuration warning: $warning" -Level 'WARN'
            }
        }
        
        # Step 6: Cache the configuration
        $fileHash = $null
        if (Test-Path $ConfigPath) {
            $fileHash = (Get-FileHash $ConfigPath -Algorithm MD5).Hash
        }
        
        $script:ConfigurationCache[$cacheKey] = @{
            Config = $config
            LoadTime = Get-Date
            FileHash = $fileHash
            ConfigPath = $ConfigPath
        }
        
        Write-SystemStatusLog "Configuration loaded and cached successfully" -Level 'INFO'
        Write-SystemStatusLog "Config sections: $($config.Keys -join ', ')" -Level 'TRACE'
        
        return $config
        
    } catch {
        Write-SystemStatusLog "Critical error loading configuration: $($_.Exception.Message)" -Level 'ERROR'
        Write-SystemStatusLog "Stack trace: $($_.ScriptStackTrace)" -Level 'DEBUG'
        
        # Return minimal default configuration as fallback
        Write-SystemStatusLog "Returning minimal fallback configuration" -Level 'WARN'
        return Get-MinimalDefaultConfiguration
    }
}

function Get-DefaultSystemStatusConfiguration {
    <#
    .SYNOPSIS
    Returns the embedded default configuration
    #>
    
    return @{
        SystemStatus = @{
            MonitoringInterval = 30
            LogLevel = "INFO"
            EnableMutex = $true
            MutexPrefix = "Global\\UnityClaudeSubsystem"
            ManifestSearchPaths = @(
                ".\\Manifests",
                ".\\Modules\\*",
                ".\\**\\*.manifest.psd1"
            )
            SystemStatusFilePath = ".\\system_status.json"
            MaxRetries = 3
            RetryDelayMs = 1000
        }
        CircuitBreaker = @{
            EnableCircuitBreaker = $true
            FailureThreshold = 3
            TimeoutSeconds = 60
            MaxTestRequests = 1
            HalfOpenRetryCount = 1
        }
        HealthMonitoring = @{
            ParallelHealthChecks = $true
            ThrottleLimit = 4
            HealthCheckTimeout = 30
            IncludePerformanceData = $false
            DefaultHealthCheckInterval = 30
            MaxParallelHealthChecks = 8
        }
        Logging = @{
            EnableDetailedLogging = $true
            LogRotationEnabled = $true
            LogRotationSizeMB = 10
            MaxLogFiles = 5
            LogFilePath = ".\\unity_claude_automation.log"
            EnableTraceLogging = $false
            EnableStructuredLogging = $false
            DiagnosticMode = "Disabled"
            CompressOldLogs = $true
        }
        Performance = @{
            CacheConfigurationMs = 30000
            EnableConfigurationCaching = $true
            MaxConfigurationAge = 300000
            FileWatcherEnabled = $true
            EnablePerformanceCounters = $false
            CounterSampleInterval = 30
            MaxPerformanceDataPoints = 1000
            EnablePerformanceAnalysis = $true
        }
        Security = @{
            ValidateManifestSignatures = $false
            RequireSecureConfiguration = $false
            AllowEnvironmentOverrides = $true
            SensitiveConfigKeys = @("API_KEY", "PASSWORD", "SECRET", "TOKEN")
        }
        Subsystems = @{
            DefaultRestartPolicy = "OnFailure"
            DefaultMaxRestarts = 3
            DefaultRestartDelay = 5
            DefaultMaxMemoryMB = 500
            DefaultMaxCpuPercent = 25
        }
    }
}

function Apply-EnvironmentOverrides {
    <#
    .SYNOPSIS
    Applies environment variable overrides to configuration
    #>
    param(
        [hashtable]$Config
    )
    
    $overrideCount = 0
    
    # Environment variable mapping
    $envMappings = @{
        "UNITYC_MONITORING_INTERVAL" = "SystemStatus.MonitoringInterval"
        "UNITYC_LOG_LEVEL" = "SystemStatus.LogLevel"
        "UNITYC_ENABLE_MUTEX" = "SystemStatus.EnableMutex"
        "UNITYC_MUTEX_PREFIX" = "SystemStatus.MutexPrefix"
        "UNITYC_STATUS_FILE" = "SystemStatus.SystemStatusFilePath"
        "UNITYC_MAX_RETRIES" = "SystemStatus.MaxRetries"
        "UNITYC_RETRY_DELAY" = "SystemStatus.RetryDelayMs"
        
        "UNITYC_CB_ENABLE" = "CircuitBreaker.EnableCircuitBreaker"
        "UNITYC_CB_FAILURE_THRESHOLD" = "CircuitBreaker.FailureThreshold"
        "UNITYC_CB_TIMEOUT_SECONDS" = "CircuitBreaker.TimeoutSeconds"
        "UNITYC_CB_MAX_TEST_REQUESTS" = "CircuitBreaker.MaxTestRequests"
        "UNITYC_CB_HALF_OPEN_RETRY_COUNT" = "CircuitBreaker.HalfOpenRetryCount"
        
        "UNITYC_HM_PARALLEL" = "HealthMonitoring.ParallelHealthChecks"
        "UNITYC_HM_THROTTLE" = "HealthMonitoring.ThrottleLimit"
        "UNITYC_HM_TIMEOUT" = "HealthMonitoring.HealthCheckTimeout"
        "UNITYC_HM_PERF_DATA" = "HealthMonitoring.IncludePerformanceData"
        "UNITYC_HM_INTERVAL" = "HealthMonitoring.DefaultHealthCheckInterval"
        
        "UNITYC_LOG_DETAILED" = "Logging.EnableDetailedLogging"
        "UNITYC_LOG_SIZE" = "Logging.LogRotationSize"
        "UNITYC_LOG_MAX_FILES" = "Logging.MaxLogFiles"
        "UNITYC_LOG_PATH" = "Logging.LogFilePath"
        "UNITYC_LOG_TRACE" = "Logging.EnableTraceLogging"
    }
    
    foreach ($envVar in $envMappings.Keys) {
        $envValue = [Environment]::GetEnvironmentVariable($envVar)
        if ($envValue) {
            $configPath = $envMappings[$envVar]
            $parts = $configPath.Split('.')
            
            if ($parts.Length -eq 2) {
                $section = $parts[0]
                $key = $parts[1]
                
                # Convert value to appropriate type
                $convertedValue = Convert-ConfigurationValue -Value $envValue -ConfigPath $configPath
                
                if ($Config.ContainsKey($section)) {
                    $Config[$section][$key] = $convertedValue
                    $overrideCount++
                    Write-SystemStatusLog "Environment override: $configPath = $convertedValue" -Level 'DEBUG'
                }
            }
        }
    }
    
    if ($overrideCount -gt 0) {
        Write-SystemStatusLog "Applied $overrideCount environment variable overrides" -Level 'INFO'
    }
    
    return $Config
}

function Convert-ConfigurationValue {
    <#
    .SYNOPSIS
    Converts string environment variable values to appropriate types
    #>
    param(
        [string]$Value,
        [string]$ConfigPath
    )
    
    # Boolean values
    if ($Value -match "^(true|false)$") {
        return [bool]::Parse($Value)
    }
    
    # Integer values
    if ($Value -match "^\d+$") {
        return [int]$Value
    }
    
    # Return as string
    return $Value
}

function Apply-ParameterOverrides {
    <#
    .SYNOPSIS
    Applies parameter overrides to configuration
    #>
    param(
        [hashtable]$Config,
        [hashtable]$Overrides
    )
    
    foreach ($override in $Overrides.Keys) {
        $parts = $override.Split('.')
        if ($parts.Length -eq 2) {
            $section = $parts[0]
            $key = $parts[1]
            
            if ($Config.ContainsKey($section)) {
                $Config[$section][$key] = $Overrides[$override]
                Write-SystemStatusLog "Parameter override: $override = $($Overrides[$override])" -Level 'DEBUG'
            }
        }
    }
    
    return $Config
}

function Merge-Configuration {
    <#
    .SYNOPSIS
    Merges two configuration hashtables with override semantics
    #>
    param(
        [hashtable]$BaseConfig,
        [hashtable]$OverrideConfig
    )
    
    $merged = $BaseConfig.Clone()
    
    foreach ($section in $OverrideConfig.Keys) {
        if ($merged.ContainsKey($section)) {
            # Merge section
            foreach ($key in $OverrideConfig[$section].Keys) {
                $merged[$section][$key] = $OverrideConfig[$section][$key]
            }
        } else {
            # Add new section
            $merged[$section] = $OverrideConfig[$section]
        }
    }
    
    return $merged
}

function Test-SystemStatusConfiguration {
    <#
    .SYNOPSIS
    Validates system status configuration
    #>
    param(
        [hashtable]$Config
    )
    
    $errors = @()
    $warnings = @()
    
    try {
        # Validate SystemStatus section
        if ($Config.ContainsKey('SystemStatus')) {
            $ss = $Config.SystemStatus
            
            if ($ss.MonitoringInterval -lt 5 -or $ss.MonitoringInterval -gt 3600) {
                $errors += "MonitoringInterval must be between 5 and 3600 seconds"
            }
            
            if ($ss.LogLevel -notin @("DEBUG", "TRACE", "INFO", "WARN", "ERROR")) {
                $errors += "LogLevel must be one of: DEBUG, TRACE, INFO, WARN, ERROR"
            }
            
            if ($ss.MaxRetries -lt 0 -or $ss.MaxRetries -gt 10) {
                $errors += "MaxRetries must be between 0 and 10"
            }
        }
        
        # Validate CircuitBreaker section
        if ($Config.ContainsKey('CircuitBreaker')) {
            $cb = $Config.CircuitBreaker
            
            if ($cb.FailureThreshold -lt 1 -or $cb.FailureThreshold -gt 10) {
                $errors += "CircuitBreaker.FailureThreshold must be between 1 and 10"
            }
            
            if ($cb.TimeoutSeconds -lt 10 -or $cb.TimeoutSeconds -gt 600) {
                $errors += "CircuitBreaker.TimeoutSeconds must be between 10 and 600"
            }
        }
        
        # Validate HealthMonitoring section
        if ($Config.ContainsKey('HealthMonitoring')) {
            $hm = $Config.HealthMonitoring
            
            if ($hm.ThrottleLimit -lt 1 -or $hm.ThrottleLimit -gt 16) {
                $errors += "HealthMonitoring.ThrottleLimit must be between 1 and 16"
            }
            
            if ($hm.HealthCheckTimeout -lt 5 -or $hm.HealthCheckTimeout -gt 300) {
                $errors += "HealthMonitoring.HealthCheckTimeout must be between 5 and 300 seconds"
            }
        }
        
        # Add warnings for performance considerations
        if ($Config.HealthMonitoring.ThrottleLimit -gt 8) {
            $warnings += "High ThrottleLimit ($($Config.HealthMonitoring.ThrottleLimit)) may impact performance"
        }
        
        if ($Config.SystemStatus.MonitoringInterval -lt 10) {
            $warnings += "Low MonitoringInterval ($($Config.SystemStatus.MonitoringInterval)) may increase CPU usage"
        }
        
    } catch {
        $errors += "Configuration validation error: $($_.Exception.Message)"
    }
    
    return @{
        IsValid = ($errors.Count -eq 0)
        Errors = $errors
        Warnings = $warnings
    }
}

function Get-MinimalDefaultConfiguration {
    <#
    .SYNOPSIS
    Returns minimal fallback configuration for emergency use
    #>
    
    return @{
        SystemStatus = @{
            MonitoringInterval = 30
            LogLevel = "INFO"
            EnableMutex = $true
            MutexPrefix = "Global\\UnityClaudeSubsystem"
            ManifestSearchPaths = @(".\\Manifests")
            SystemStatusFilePath = ".\\system_status.json"
            MaxRetries = 3
            RetryDelayMs = 1000
        }
        CircuitBreaker = @{
            EnableCircuitBreaker = $true
            FailureThreshold = 3
            TimeoutSeconds = 60
            MaxTestRequests = 1
        }
        HealthMonitoring = @{
            ParallelHealthChecks = $false
            ThrottleLimit = 2
            HealthCheckTimeout = 30
            IncludePerformanceData = $false
        }
        Logging = @{
            EnableDetailedLogging = $false
            LogFilePath = ".\\unity_claude_automation.log"
        }
        Performance = @{
            EnableConfigurationCaching = $false
            MaxConfigurationAge = 60000
        }
    }
}
# SIG # Begin signature block
# MIIFqQYJKoZIhvcNAQcCoIIFmjCCBZYCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUjiOAijIAkZwyk765N7BhA/q/
# Ew+gggMwMIIDLDCCAhSgAwIBAgIQdR0W2SKoK5VE8JId4ZxrRTANBgkqhkiG9w0B
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
# CQQxFgQUQu6BCbDIiqrKyuZn2Q9lr/xYD38wDQYJKoZIhvcNAQEBBQAEggEAAIQc
# oaXnFWfT7xcK4MOoTFCNCxCS2lbqlWtIT2Kcuoba/3b75R7qtnZJB99MmtpxMB3y
# E47+4MRuOzeR+gFM25RP7cLIvrk2NxcCvN+qqM5TYsGdAiujXDXLgKhgg73aefyY
# 5yeHXWdXFnlRneUavmoOC7gDYP+GamuwKLyXbkkd45o/WU+3eH+AN8GjVzfikSbd
# HN/ReX83x5uGf8uqOm8k3WfDLh6VHtVi/dWlD1qUApiP3dhfumgyqOCwPrQKoMHz
# 3QkbQOoe68n5ctPZJLhCNko6Gmz0DMmNSYrET+eTvBO484OrqVXffUfF4LpeBCpS
# 9UWzZKzCs6n9SvruVg==
# SIG # End signature block
