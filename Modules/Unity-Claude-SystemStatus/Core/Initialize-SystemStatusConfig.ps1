function Initialize-SystemStatusConfig {
    [CmdletBinding()]
    param()
    
    # Get module root (Unity-Claude-Automation directory) using reliable path resolution
    $script:ModuleRootPath = if ($PSScriptRoot) {
        # Go up from Core folder to SystemStatus folder, then up to Modules, then up to Unity-Claude-Automation
        Split-Path (Split-Path (Split-Path $PSScriptRoot -Parent) -Parent) -Parent
    } else {
        # Fallback for dot-sourcing scenarios
        (Get-Location).Path
    }

    # System status monitoring configuration
    $script:SystemStatusConfig = @{
        # Core system status paths
        SystemStatusFile = Join-Path $script:ModuleRootPath "system_status.json"
        HealthDataPath = Join-Path $script:ModuleRootPath "SessionData\Health"
        WatchdogDataPath = Join-Path $script:ModuleRootPath "SessionData\Watchdog"
        SchemaFile = Join-Path $script:ModuleRootPath "system_status_schema.json"
        
        # Status monitoring settings
        HeartbeatIntervalSeconds = 60
        HeartbeatFailureThreshold = 4
        HealthCheckIntervalSeconds = 15
        StatusUpdateIntervalSeconds = 30
        
        # Performance monitoring thresholds
        CriticalCpuPercentage = 70
        CriticalMemoryMB = 800
        CriticalResponseTimeMs = 1000
        WarningCpuPercentage = 50
        WarningMemoryMB = 500
        
        # Communication configuration
        NamedPipeName = "UnityClaudeSystemStatus"
        CommunicationTimeoutMs = 5000
        MessageRetryAttempts = 3
        
        # Circuit breaker configuration
        CircuitBreakerEnabled = $true
        CircuitBreakerThreshold = 5
        CircuitBreakerResetTimeSeconds = 30
        
        # Alert configuration
        AlertCooldownSeconds = 300
        MaxAlertFrequency = 10
        EscalationEnabled = $true
        EscalationThresholds = @{
            Level1 = 3
            Level2 = 5
            Level3 = 10
        }
        
        # Logging
        LogPath = Join-Path $script:ModuleRootPath "Logs\SystemStatus"
        LogFile = "unity_claude_automation.log"
        LogLevel = "INFO"
        MaxLogSizeMB = 100
        LogRetentionDays = 30
    }

    # Default system status data structure
    $script:SystemStatusData = @{
        timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss.fff'
        subsystems = @{}
        Dependencies = @{}
        overall_health = "Unknown"
        last_update = Get-Date -Format 'yyyy-MM-dd HH:mm:ss.fff'
        alerts = @()
        metrics = @{}
        Watchdog = @{
            Enabled = $true
            LastCheck = Get-Date -Format 'yyyy-MM-dd HH:mm:ss.fff'
            RestartPolicy = "Auto"
        }
        Communication = @{
            NamedPipesEnabled = $true
            JsonFallbackEnabled = $true
            LastActivity = Get-Date -Format 'yyyy-MM-dd HH:mm:ss.fff'
        }
        SystemInfo = @{
            ModuleVersion = "1.0.0"
            LastUpdate = Get-Date -Format 'yyyy-MM-dd HH:mm:ss.fff'
            MonitoringStartTime = Get-Date -Format 'yyyy-MM-dd HH:mm:ss.fff'
            HostName = $env:COMPUTERNAME
            PowerShellVersion = $PSVersionTable.PSVersion.ToString()
        }
    }

    # Critical subsystems list
    $script:CriticalSubsystems = @{
        "Unity" = @{
            Priority = 1
            RestartOnFailure = $true
            HealthCheckInterval = 10
            MaxRestartAttempts = 3
        }
        "Claude" = @{
            Priority = 1
            RestartOnFailure = $false
            HealthCheckInterval = 15
            MaxRestartAttempts = 0
        }
        "AutonomousAgent" = @{
            Priority = 2
            RestartOnFailure = $true
            HealthCheckInterval = 30
            MaxRestartAttempts = 5
        }
        "Watchdog" = @{
            Priority = 1
            RestartOnFailure = $true
            HealthCheckInterval = 5
            MaxRestartAttempts = 3
        }
        "ResponseMonitor" = @{
            Priority = 3
            RestartOnFailure = $true
            HealthCheckInterval = 60
            MaxRestartAttempts = 3
        }
    }

    # Ensure all directories exist
    foreach ($path in @($script:SystemStatusConfig.HealthDataPath, $script:SystemStatusConfig.WatchdogDataPath)) {
        if (-not (Test-Path $path)) {
            try {
                New-Item -Path $path -ItemType Directory -Force | Out-Null
                Write-Verbose "Created directory: $path"
            } catch {
                Write-Warning "Failed to create directory $path : $($_.Exception.Message)"
            }
        }
    }

    Write-Verbose "SystemStatus configuration initialized"
    Write-Verbose "SystemStatusFile: $($script:SystemStatusConfig.SystemStatusFile)"
}
# SIG # Begin signature block
# MIIFqQYJKoZIhvcNAQcCoIIFmjCCBZYCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUhuF0AfqIHCFo876CPZacoXjP
# XT6gggMwMIIDLDCCAhSgAwIBAgIQdR0W2SKoK5VE8JId4ZxrRTANBgkqhkiG9w0B
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
# CQQxFgQU+VfZR0Uk81JyIlK0j963JlAfNO4wDQYJKoZIhvcNAQEBBQAEggEAMwWT
# MxL/aqkFBVD9gRojwzSo8FtZS4zRx3sRact8VZ3oAEHF14GwdskvlAdogjz4kuif
# pKgo8qHh+kG/E057nc8lyGgamp5BEbXfD0gvJgTRULKDfj7NQPhVgtM5CT9re+Y2
# IUfrfxdciMik6YSSANR6Ne+dgCBS3Tl8HyvJol/BPRGeHfXMjPWJXM3rYnm7GwJH
# Djw6rN6DUsgzXJ6AzP1PPdNZ4nR5o+ImQ8vDBZP46+cYJy9Q5+bCN4PNzOXktFkG
# xPDZvtH5LL5RcXUgJEitPDGQ+H/YtpRTYRIdaGh+N1Wh/Y6IPsoHgDZEiyyYt2lo
# Rdrgn/LR/a/HfCElHA==
# SIG # End signature block
