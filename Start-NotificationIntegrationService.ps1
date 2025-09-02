# Start-NotificationIntegrationService.ps1
# Week 6 Days 1-2: System Integration - Bootstrap Orchestrator Integration
# Startup script for unified NotificationIntegration subsystem
# Date: 2025-08-22

param(
    [string]$ConfigPath,
    [switch]$TestMode,
    [string]$LogLevel = "INFO"
)

$ErrorActionPreference = "Stop"

# Initialize logging
$logFile = ".\unity_claude_automation.log"
function Write-StartupLog {
    param($Message, $Level = "INFO")
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logEntry = "$timestamp [$Level] [NotificationIntegrationService] $Message"
    Write-Host $logEntry
    Add-Content -Path $logFile -Value $logEntry -ErrorAction SilentlyContinue
}

Write-StartupLog "Starting NotificationIntegration subsystem..." -Level "INFO"

try {
    # Register with Bootstrap Orchestrator system
    Import-Module Unity-Claude-SystemStatus -ErrorAction Stop
    Write-StartupLog "SystemStatus module loaded successfully" -Level "DEBUG"
    
    # Load all notification modules
    Import-Module Unity-Claude-EmailNotifications -ErrorAction Stop
    Import-Module Unity-Claude-WebhookNotifications -ErrorAction Stop
    Import-Module Unity-Claude-NotificationContentEngine -ErrorAction Stop
    Import-Module Unity-Claude-NotificationIntegration -ErrorAction Stop
    Write-StartupLog "All notification modules loaded successfully" -Level "DEBUG"
    
    # Load unified configuration
    $config = Get-NotificationConfiguration -ConfigPath $ConfigPath
    
    if (-not $config.Notifications.EnableNotifications -and -not $TestMode) {
        Write-StartupLog "Notifications are disabled in configuration. Exiting gracefully." -Level "WARN"
        exit 0
    }
    
    Write-StartupLog "Unified configuration loaded successfully. Enabled: $($config.Notifications.EnableNotifications)" -Level "INFO"
    
    # Validate configuration
    $validationResult = Test-NotificationConfiguration -Configuration $config
    if (-not $validationResult.IsValid) {
        $errorMessage = "Configuration validation failed: $($validationResult.Errors -join ', ')"
        Write-StartupLog $errorMessage -Level "ERROR"
        throw $errorMessage
    }
    
    Write-StartupLog "Configuration validation passed" -Level "INFO"
    
    # Check dependency subsystems
    $dependencies = @("SystemMonitoring")
    if ($config.EmailNotifications.Enabled) { $dependencies += "EmailNotifications" }
    if ($config.WebhookNotifications.Enabled) { $dependencies += "WebhookNotifications" }
    
    foreach ($dependency in $dependencies) {
        try {
            $depStatus = Test-SubsystemRunning -Name $dependency -ErrorAction SilentlyContinue
            if ($depStatus) {
                Write-StartupLog "Dependency '$dependency' is running" -Level "DEBUG"
            } else {
                Write-StartupLog "Warning: Dependency '$dependency' is not running" -Level "WARN"
            }
        } catch {
            Write-StartupLog "Warning: Unable to check dependency '$dependency': $($_.Exception.Message)" -Level "WARN"
        }
    }
    
    # Register subsystem with Bootstrap Orchestrator
    try {
        $manifestPath = Join-Path $PSScriptRoot "Manifests\NotificationIntegration.manifest.psd1"
        if (Test-Path $manifestPath) {
            Register-SubsystemFromManifest -ManifestPath $manifestPath
            Write-StartupLog "Registered with Bootstrap Orchestrator using manifest" -Level "INFO"
        } else {
            # Fallback to direct registration
            Register-Subsystem -Name "NotificationIntegration" -ProcessId $PID -StartTime (Get-Date) -Status "Starting"
            Write-StartupLog "Registered with SystemStatus (fallback method)" -Level "INFO"
        }
    } catch {
        Write-StartupLog "Warning: Unable to register with Bootstrap Orchestrator: $($_.Exception.Message)" -Level "WARN"
    }
    
    # Initialize notification integration service
    try {
        Initialize-NotificationIntegration -Configuration $config
        Write-StartupLog "NotificationIntegration service initialized successfully" -Level "INFO"
    } catch {
        $errorMessage = "Failed to initialize NotificationIntegration service: $($_.Exception.Message)"
        Write-StartupLog $errorMessage -Level "ERROR"
        throw $_
    }
    
    # Start notification retry processor
    try {
        Start-NotificationRetryProcessor -Configuration $config
        Write-StartupLog "Notification retry processor started" -Level "INFO"
    } catch {
        Write-StartupLog "Warning: Failed to start notification retry processor: $($_.Exception.Message)" -Level "WARN"
    }
    
    # Perform comprehensive health check
    $healthResult = Test-NotificationIntegration -Detailed
    if (-not $healthResult.IsHealthy) {
        $warningMessage = "NotificationIntegration health check warnings: $($healthResult.Warnings -join ', ')"
        Write-StartupLog $warningMessage -Level "WARN"
        
        if ($healthResult.Errors.Count -gt 0) {
            $errorMessage = "NotificationIntegration health check errors: $($healthResult.Errors -join ', ')"
            Write-StartupLog $errorMessage -Level "ERROR"
        }
    } else {
        Write-StartupLog "NotificationIntegration comprehensive health check passed" -Level "INFO"
    }
    
    # Update subsystem status to Running
    try {
        Update-SubsystemProcessInfo -Name "NotificationIntegration" -ProcessId $PID -Status "Running"
        Write-StartupLog "Subsystem status updated to Running" -Level "INFO"
    } catch {
        Write-StartupLog "Warning: Unable to update subsystem status: $($_.Exception.Message)" -Level "WARN"
    }
    
    # Send startup heartbeat
    try {
        Send-Heartbeat -SubsystemName "NotificationIntegration" -Status "Running" -ProcessId $PID
        Write-StartupLog "Startup heartbeat sent" -Level "DEBUG"
    } catch {
        Write-StartupLog "Warning: Unable to send startup heartbeat: $($_.Exception.Message)" -Level "WARN"
    }
    
    Write-StartupLog "NotificationIntegration subsystem startup completed successfully" -Level "INFO"
    
    # In test mode, exit after successful startup
    if ($TestMode) {
        Write-StartupLog "Test mode: NotificationIntegration startup validation completed" -Level "INFO"
        exit 0
    }
    
    # Main service loop
    Write-StartupLog "Entering NotificationIntegration service main loop" -Level "INFO"
    
    $heartbeatInterval = 30  # seconds
    $healthCheckInterval = 60  # seconds
    $lastHeartbeat = Get-Date
    $lastHealthCheck = Get-Date
    
    while ($true) {
        try {
            $now = Get-Date
            
            # Send periodic heartbeat
            if (($now - $lastHeartbeat).TotalSeconds -ge $heartbeatInterval) {
                Send-Heartbeat -SubsystemName "NotificationIntegration" -Status "Running" -ProcessId $PID
                $lastHeartbeat = $now
            }
            
            # Perform periodic health check
            if (($now - $lastHealthCheck).TotalSeconds -ge $healthCheckInterval) {
                try {
                    $healthResult = Test-NotificationIntegration
                    if (-not $healthResult.IsHealthy) {
                        Write-StartupLog "Health check detected issues: $($healthResult.Warnings -join ', ')" -Level "WARN"
                    }
                    $lastHealthCheck = $now
                } catch {
                    Write-StartupLog "Health check error: $($_.Exception.Message)" -Level "WARN"
                }
            }
            
            # Process notification queues and maintain integration state
            try {
                $queueStatus = Get-NotificationQueueStatus -ErrorAction SilentlyContinue
                if ($queueStatus -and ($queueStatus.TotalQueueLength -gt 0)) {
                    Write-StartupLog "Processing $($queueStatus.TotalQueueLength) queued notifications" -Level "DEBUG"
                }
            } catch {
                # Ignore queue processing errors for now
            }
            
            Start-Sleep -Seconds 10
            
        } catch {
            $errorMessage = "Error in NotificationIntegration service main loop: $($_.Exception.Message)"
            Write-StartupLog $errorMessage -Level "ERROR"
            
            # Update status to error
            try {
                Update-SubsystemProcessInfo -Name "NotificationIntegration" -ProcessId $PID -Status "Error"
            } catch {
                # Ignore registration errors during error handling
            }
            
            # In production, might want to restart or exit
            Start-Sleep -Seconds 10
        }
    }
    
} catch {
    $errorMessage = "NotificationIntegration subsystem startup failed: $($_.Exception.Message)"
    Write-StartupLog $errorMessage -Level "ERROR"
    
    # Update status to failed
    try {
        Update-SubsystemProcessInfo -Name "NotificationIntegration" -ProcessId $PID -Status "Failed"
    } catch {
        # Ignore registration errors during error handling
    }
    
    exit 1
}
# SIG # Begin signature block
# MIIFzgYJKoZIhvcNAQcCoIIFvzCCBbsCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCBj48G+tUyBDbTy
# rBgyDKzHvgYB3mqw4sYojbAvHkbUrKCCAzAwggMsMIICFKADAgECAhB1HRbZIqgr
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
# MAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIH+5px/Gb+mD9ON5PWTeGHf3
# 3kvVI1YVW0onMP3D+ReyMA0GCSqGSIb3DQEBAQUABIIBAGjfUVsEeyRNqN4TXqO1
# +NigCp16+uY1UgNe08cDpdgQiV7TrCeww+dYHfhTvujLpKyYB7Miwwe3kRjnIULj
# W/1T1OKI/OPOCqo9XaZvWBimpzv0vTJON8Al5Y+TQ3QWE/ne4wGbXkkhgL2liQM4
# PH6oTVEgOKhtWx37eeTAopTW4m4O4fzxd4DEPD5kuI0u61Dj7fYP6OameARu/+K4
# z5mBciKULDRmfl1t0CGsvik1P49/tf6I6Zmw9KiORPzHvdM3N5pZQSssjmwSETjK
# Nq8E5pm0L5sZ0kNOvjsKhVjhjrqGvstFOJ5NFVxjllnTYe9JmZkOIlI5RZru4OfC
# alI=
# SIG # End signature block
