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
# SIG # Begin signature block
# MIIFzgYJKoZIhvcNAQcCoIIFvzCCBbsCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCBvv1FNLgTxzGOm
# /D1n7mwAVoLhhelxNXOtbuJek/RDPaCCAzAwggMsMIICFKADAgECAhB1HRbZIqgr
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
# MAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEILXQswYTYZmfc8GmXRlttOqv
# 9pqk28bnibWlF96U8RTTMA0GCSqGSIb3DQEBAQUABIIBAEW4SwmRFqwIkP4985Na
# aOzcCiBu1PsvxzshVrtF6+aJB5iABjszUywbxRac+gS5gkJXapIHFoweZwq8ukRZ
# cfGZ7VKo6jmJJqMpJnlA+y4N8cSn5/ZESydPiOtdT2STsM9H7AwPanoSDVoWDE5S
# 9hALaNT3KZaCWDBvwxPO7NL31hCIQaLPfPH4FiU2cP0BiDG286hTZir7hdCT0QiT
# Tbhns1X3crppXRxXOX7F0YOUux0bG8ZkyPHNG/1Ahcn4mpRdNF5Jmy8UBsGMx7te
# PkfftUw73krwqJgXHERYSNug4UaPNDtqzie5LkwcMJ5kaaXcck04LfcLbPTbJtIh
# 5ts=
# SIG # End signature block
