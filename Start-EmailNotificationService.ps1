# Start-EmailNotificationService.ps1
# Week 6 Days 1-2: System Integration - Bootstrap Orchestrator Integration
# Startup script for EmailNotifications subsystem
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
    $logEntry = "$timestamp [$Level] [EmailNotificationService] $Message"
    Write-Host $logEntry
    Add-Content -Path $logFile -Value $logEntry -ErrorAction SilentlyContinue
}

Write-StartupLog "Starting EmailNotifications subsystem..." -Level "INFO"

try {
    # Register with Bootstrap Orchestrator system
    Import-Module Unity-Claude-SystemStatus -ErrorAction Stop
    Write-StartupLog "SystemStatus module loaded successfully" -Level "DEBUG"
    
    # Load notification integration modules
    Import-Module Unity-Claude-EmailNotifications -ErrorAction Stop
    Import-Module Unity-Claude-NotificationIntegration -ErrorAction Stop
    Write-StartupLog "Notification modules loaded successfully" -Level "DEBUG"
    
    # Load manifest-aware configuration
    $config = Get-NotificationConfiguration -NotificationService "EmailNotifications" -ConfigPath $ConfigPath
    $emailConfig = $config.EmailNotifications
    
    if (-not $emailConfig.Enabled -and -not $TestMode) {
        Write-StartupLog "EmailNotifications is disabled in configuration. Exiting gracefully." -Level "WARN"
        exit 0
    }
    
    Write-StartupLog "Configuration loaded successfully. Enabled: $($emailConfig.Enabled)" -Level "INFO"
    
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
        $manifestPath = Join-Path $PSScriptRoot "Manifests\EmailNotifications.manifest.psd1"
        if (Test-Path $manifestPath) {
            Register-SubsystemFromManifest -ManifestPath $manifestPath
            Write-StartupLog "Registered with Bootstrap Orchestrator using manifest" -Level "INFO"
        } else {
            # Fallback to direct registration
            Register-Subsystem -Name "EmailNotifications" -ProcessId $PID -StartTime (Get-Date) -Status "Starting"
            Write-StartupLog "Registered with SystemStatus (fallback method)" -Level "INFO"
        }
    } catch {
        Write-StartupLog "Warning: Unable to register with Bootstrap Orchestrator: $($_.Exception.Message)" -Level "WARN"
    }
    
    # Initialize email notification service
    try {
        Initialize-NotificationIntegration -Service "EmailNotifications" -Configuration $config
        Write-StartupLog "EmailNotifications service initialized successfully" -Level "INFO"
    } catch {
        $errorMessage = "Failed to initialize EmailNotifications service: $($_.Exception.Message)"
        Write-StartupLog $errorMessage -Level "ERROR"
        throw $_
    }
    
    # Perform initial health check
    $healthResult = Test-EmailNotificationHealth -Detailed
    if (-not $healthResult.IsHealthy) {
        $warningMessage = "EmailNotifications health check warnings: $($healthResult.Warnings -join ', ')"
        Write-StartupLog $warningMessage -Level "WARN"
        
        if ($healthResult.Errors.Count -gt 0) {
            $errorMessage = "EmailNotifications health check errors: $($healthResult.Errors -join ', ')"
            Write-StartupLog $errorMessage -Level "ERROR"
        }
    } else {
        Write-StartupLog "EmailNotifications health check passed" -Level "INFO"
    }
    
    # Update subsystem status to Running
    try {
        Update-SubsystemProcessInfo -Name "EmailNotifications" -ProcessId $PID -Status "Running"
        Write-StartupLog "Subsystem status updated to Running" -Level "INFO"
    } catch {
        Write-StartupLog "Warning: Unable to update subsystem status: $($_.Exception.Message)" -Level "WARN"
    }
    
    # Send startup heartbeat
    try {
        Send-Heartbeat -SubsystemName "EmailNotifications" -Status "Running" -ProcessId $PID
        Write-StartupLog "Startup heartbeat sent" -Level "DEBUG"
    } catch {
        Write-StartupLog "Warning: Unable to send startup heartbeat: $($_.Exception.Message)" -Level "WARN"
    }
    
    Write-StartupLog "EmailNotifications subsystem startup completed successfully" -Level "INFO"
    
    # In test mode, exit after successful startup
    if ($TestMode) {
        Write-StartupLog "Test mode: EmailNotifications startup validation completed" -Level "INFO"
        exit 0
    }
    
    # Main service loop
    Write-StartupLog "Entering EmailNotifications service main loop" -Level "INFO"
    
    $heartbeatInterval = 30  # seconds
    $lastHeartbeat = Get-Date
    
    while ($true) {
        try {
            # Send periodic heartbeat
            $now = Get-Date
            if (($now - $lastHeartbeat).TotalSeconds -ge $heartbeatInterval) {
                Send-Heartbeat -SubsystemName "EmailNotifications" -Status "Running" -ProcessId $PID
                $lastHeartbeat = $now
            }
            
            # Process notification queue (this would be handled by the main notification integration)
            # For now, just maintain service presence
            
            Start-Sleep -Seconds 5
            
        } catch {
            $errorMessage = "Error in EmailNotifications service main loop: $($_.Exception.Message)"
            Write-StartupLog $errorMessage -Level "ERROR"
            
            # Update status to error
            try {
                Update-SubsystemProcessInfo -Name "EmailNotifications" -ProcessId $PID -Status "Error"
            } catch {
                # Ignore registration errors during error handling
            }
            
            # In production, might want to restart or exit
            Start-Sleep -Seconds 10
        }
    }
    
} catch {
    $errorMessage = "EmailNotifications subsystem startup failed: $($_.Exception.Message)"
    Write-StartupLog $errorMessage -Level "ERROR"
    
    # Update status to failed
    try {
        Update-SubsystemProcessInfo -Name "EmailNotifications" -ProcessId $PID -Status "Failed"
    } catch {
        # Ignore registration errors during error handling
    }
    
    exit 1
}