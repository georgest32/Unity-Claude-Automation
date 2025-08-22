# Start-WebhookNotificationService.ps1
# Week 6 Days 1-2: System Integration - Bootstrap Orchestrator Integration
# Startup script for WebhookNotifications subsystem
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
    $logEntry = "$timestamp [$Level] [WebhookNotificationService] $Message"
    Write-Host $logEntry
    Add-Content -Path $logFile -Value $logEntry -ErrorAction SilentlyContinue
}

Write-StartupLog "Starting WebhookNotifications subsystem..." -Level "INFO"

try {
    # Register with Bootstrap Orchestrator system
    Import-Module Unity-Claude-SystemStatus -ErrorAction Stop
    Write-StartupLog "SystemStatus module loaded successfully" -Level "DEBUG"
    
    # Load notification integration modules
    Import-Module Unity-Claude-WebhookNotifications -ErrorAction Stop
    Import-Module Unity-Claude-NotificationIntegration -ErrorAction Stop
    Write-StartupLog "Notification modules loaded successfully" -Level "DEBUG"
    
    # Load manifest-aware configuration
    $config = Get-NotificationConfiguration -NotificationService "WebhookNotifications" -ConfigPath $ConfigPath
    $webhookConfig = $config.WebhookNotifications
    
    if (-not $webhookConfig.Enabled -and -not $TestMode) {
        Write-StartupLog "WebhookNotifications is disabled in configuration. Exiting gracefully." -Level "WARN"
        exit 0
    }
    
    Write-StartupLog "Configuration loaded successfully. Enabled: $($webhookConfig.Enabled)" -Level "INFO"
    
    # Validate configuration
    $validationResult = Test-NotificationConfiguration -Configuration $config
    if (-not $validationResult.IsValid) {
        $errorMessage = "Configuration validation failed: $($validationResult.Errors -join ', ')"
        Write-StartupLog $errorMessage -Level "ERROR"
        throw $errorMessage
    }
    
    Write-StartupLog "Configuration validation passed" -Level "INFO"
    
    # Register subsystem with Bootstrap Orchestrator
    try {
        $manifestPath = Join-Path $PSScriptRoot "Manifests\WebhookNotifications.manifest.psd1"
        if (Test-Path $manifestPath) {
            Register-SubsystemFromManifest -ManifestPath $manifestPath
            Write-StartupLog "Registered with Bootstrap Orchestrator using manifest" -Level "INFO"
        } else {
            # Fallback to direct registration
            Register-Subsystem -Name "WebhookNotifications" -ProcessId $PID -StartTime (Get-Date) -Status "Starting"
            Write-StartupLog "Registered with SystemStatus (fallback method)" -Level "INFO"
        }
    } catch {
        Write-StartupLog "Warning: Unable to register with Bootstrap Orchestrator: $($_.Exception.Message)" -Level "WARN"
    }
    
    # Initialize webhook notification service
    try {
        Initialize-NotificationIntegration -Service "WebhookNotifications" -Configuration $config
        Write-StartupLog "WebhookNotifications service initialized successfully" -Level "INFO"
    } catch {
        $errorMessage = "Failed to initialize WebhookNotifications service: $($_.Exception.Message)"
        Write-StartupLog $errorMessage -Level "ERROR"
        throw $_
    }
    
    # Perform initial health check
    $healthResult = Test-WebhookNotificationHealth -Detailed
    if (-not $healthResult.IsHealthy) {
        $warningMessage = "WebhookNotifications health check warnings: $($healthResult.Warnings -join ', ')"
        Write-StartupLog $warningMessage -Level "WARN"
        
        if ($healthResult.Errors.Count -gt 0) {
            $errorMessage = "WebhookNotifications health check errors: $($healthResult.Errors -join ', ')"
            Write-StartupLog $errorMessage -Level "ERROR"
        }
    } else {
        Write-StartupLog "WebhookNotifications health check passed" -Level "INFO"
    }
    
    # Update subsystem status to Running
    try {
        Update-SubsystemProcessInfo -Name "WebhookNotifications" -ProcessId $PID -Status "Running"
        Write-StartupLog "Subsystem status updated to Running" -Level "INFO"
    } catch {
        Write-StartupLog "Warning: Unable to update subsystem status: $($_.Exception.Message)" -Level "WARN"
    }
    
    # Send startup heartbeat
    try {
        Send-Heartbeat -SubsystemName "WebhookNotifications" -Status "Running" -ProcessId $PID
        Write-StartupLog "Startup heartbeat sent" -Level "DEBUG"
    } catch {
        Write-StartupLog "Warning: Unable to send startup heartbeat: $($_.Exception.Message)" -Level "WARN"
    }
    
    Write-StartupLog "WebhookNotifications subsystem startup completed successfully" -Level "INFO"
    
    # In test mode, exit after successful startup
    if ($TestMode) {
        Write-StartupLog "Test mode: WebhookNotifications startup validation completed" -Level "INFO"
        exit 0
    }
    
    # Main service loop
    Write-StartupLog "Entering WebhookNotifications service main loop" -Level "INFO"
    
    $heartbeatInterval = 30  # seconds
    $lastHeartbeat = Get-Date
    
    while ($true) {
        try {
            # Send periodic heartbeat
            $now = Get-Date
            if (($now - $lastHeartbeat).TotalSeconds -ge $heartbeatInterval) {
                Send-Heartbeat -SubsystemName "WebhookNotifications" -Status "Running" -ProcessId $PID
                $lastHeartbeat = $now
            }
            
            # Process notification queue (this would be handled by the main notification integration)
            # For now, just maintain service presence
            
            Start-Sleep -Seconds 5
            
        } catch {
            $errorMessage = "Error in WebhookNotifications service main loop: $($_.Exception.Message)"
            Write-StartupLog $errorMessage -Level "ERROR"
            
            # Update status to error
            try {
                Update-SubsystemProcessInfo -Name "WebhookNotifications" -ProcessId $PID -Status "Error"
            } catch {
                # Ignore registration errors during error handling
            }
            
            # In production, might want to restart or exit
            Start-Sleep -Seconds 10
        }
    }
    
} catch {
    $errorMessage = "WebhookNotifications subsystem startup failed: $($_.Exception.Message)"
    Write-StartupLog $errorMessage -Level "ERROR"
    
    # Update status to failed
    try {
        Update-SubsystemProcessInfo -Name "WebhookNotifications" -ProcessId $PID -Status "Failed"
    } catch {
        # Ignore registration errors during error handling
    }
    
    exit 1
}