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
# MIIFzgYJKoZIhvcNAQcCoIIFvzCCBbsCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCBI/HD2Rs4Dnd/r
# 7vBGpZ4AOukqdOxsbDl9kgXeyKiM0KCCAzAwggMsMIICFKADAgECAhB1HRbZIqgr
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
# MAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEII+sRPYczEpnjCH8zjvltOsP
# l9mGPenwJjlKENdDZfRBMA0GCSqGSIb3DQEBAQUABIIBAH49/sOI5FrPgFAantkE
# C0APURnu2mCFwUBZnS/H14F5UixXyrT14WByZq+c3b00qzL4pJdm0hj9qYQ40Bt1
# C+C2ooLfJYvoT2cFVA36ZeCFjVeQ609oXYfhl2BQJjVMu4ovRd58HbvKcKusKwKc
# +biSYC5tMU6EdVtWKqhKhhhymbO0cIxgckdDlPz4ZvVdgQ6x3fpSzLCTAAADRimE
# sI0n1tnH/x+EmvaCEqwJ40dWGU2ocJFikjhhyxPTXyXvzZ5/3mhhcQyRL1ht/3N7
# 1dqY9P95RtZSIXzDqH22jIjaCYuRWQZEGfZLXuookMovhPMse+pmdMcbH7L1Nfcv
# S9g=
# SIG # End signature block
