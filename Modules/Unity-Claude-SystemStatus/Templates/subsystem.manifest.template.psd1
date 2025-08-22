# Unity-Claude-Automation Subsystem Manifest Template
# This file defines the configuration for a subsystem managed by the Bootstrap Orchestrator
# Copy this template and customize for your specific subsystem

@{
    # ==========================================
    # REQUIRED: Core Identification
    # ==========================================
    
    # Unique name for this subsystem
    Name = "SubsystemName"
    
    # Version of this subsystem (SemVer format)
    Version = "1.0.0"
    
    # Human-readable description
    Description = "Description of what this subsystem does"
    
    # Author/maintainer
    Author = "Your Name"
    
    # ==========================================
    # REQUIRED: Execution Configuration
    # ==========================================
    
    # Script to start this subsystem (relative to manifest location)
    StartScript = ".\Start-Subsystem.ps1"
    
    # Optional: Script to stop this subsystem gracefully
    StopScript = ""
    
    # Optional: Working directory for the subsystem
    WorkingDirectory = ""
    
    # ==========================================
    # Dependencies
    # ==========================================
    
    # List of module dependencies that must be loaded
    RequiredModules = @()
    
    # List of other subsystems this depends on
    DependsOn = @()
    
    # ==========================================
    # Health Monitoring
    # ==========================================
    
    # Function to check subsystem health (must return $true/$false)
    HealthCheckFunction = ""
    
    # How often to check health (in seconds)
    HealthCheckInterval = 30
    
    # Timeout for health check (milliseconds)
    HealthCheckTimeout = 5000
    
    # Optional: Custom health check script path
    HealthCheckScript = ""
    
    # ==========================================
    # Recovery Policy
    # ==========================================
    
    # When to restart: "OnFailure", "Always", "Never"
    RestartPolicy = "OnFailure"
    
    # Maximum number of restart attempts
    MaxRestarts = 3
    
    # Delay between restart attempts (seconds)
    RestartDelay = 5
    
    # Reset restart count after this many seconds of healthy operation
    RestartCountResetTime = 300
    
    # ==========================================
    # Resource Limits
    # ==========================================
    
    # Maximum memory usage in MB (0 = unlimited)
    MaxMemoryMB = 0
    
    # Maximum CPU percentage (0 = unlimited)
    MaxCpuPercent = 0
    
    # Kill process if it exceeds resource limits
    EnforceResourceLimits = $false
    
    # ==========================================
    # Process Management
    # ==========================================
    
    # Run as background job
    RunAsJob = $true
    
    # Process priority: "Normal", "BelowNormal", "AboveNormal", "High", "RealTime"
    Priority = "Normal"
    
    # Hide window (if applicable)
    WindowStyle = "Hidden"
    
    # ==========================================
    # Singleton Enforcement
    # ==========================================
    
    # Enable mutex-based singleton enforcement
    UseMutex = $true
    
    # Custom mutex name (default: "Global\UnityClaudeSubsystem_$Name")
    MutexName = ""
    
    # Timeout for acquiring mutex (milliseconds)
    MutexTimeout = 5000
    
    # Kill existing instance if mutex is held
    KillExistingOnConflict = $false
    
    # ==========================================
    # Logging and Monitoring
    # ==========================================
    
    # Enable verbose logging
    VerboseLogging = $false
    
    # Log file path (empty = use default)
    LogFile = ""
    
    # Maximum log file size in MB
    MaxLogSizeMB = 10
    
    # Number of log files to keep
    LogFileCount = 5
    
    # ==========================================
    # Environment Variables
    # ==========================================
    
    # Environment variables to set for this subsystem
    EnvironmentVariables = @{}
    
    # ==========================================
    # Custom Properties
    # ==========================================
    
    # Any additional properties specific to your subsystem
    CustomProperties = @{}
    
    # ==========================================
    # Metadata
    # ==========================================
    
    # Tags for categorization and discovery
    Tags = @()
    
    # Creation timestamp
    CreatedDate = "2025-08-22"
    
    # Last modified timestamp
    ModifiedDate = "2025-08-22"
}
# SIG # Begin signature block
# MIIFqQYJKoZIhvcNAQcCoIIFmjCCBZYCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUH6c53BMvzWV++rNCb+y+l+Ob
# AAGgggMwMIIDLDCCAhSgAwIBAgIQdR0W2SKoK5VE8JId4ZxrRTANBgkqhkiG9w0B
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
# CQQxFgQUMSg4KGp0HNaUS3ZqvD/0duSRorMwDQYJKoZIhvcNAQEBBQAEggEAGYX8
# QnyeAa6JblIHWiF62k5JH4ps//dzPCIpTeaYtwAQeBwpUnvKzBH8nUx4sLgWe4Rq
# J7kigkdQmqVvHIcsI4NjaNeP2lTPLKJjDQkjAuuWq/U0yRYztpDsZi3D8ScP9/ET
# R6eBMzh/adf1MNJk7oRAAAdwntFz/WYgRM0IoWQqpX3e5cRchfhr6IjUvWHOX+zO
# xkFDkJJKyjsbU/HwBGfHcCS84Nf61a/+l7Peu7PTuAluTe7aCvttIljHvalanCHQ
# 9ngRJ/hqcw8caO+i0NiVXrFYXt1Q83TjMs9Qb7AjsUnHl8TzL4RJcR1kzSSATfKh
# ui7jfnzJqd2hM/SzFw==
# SIG # End signature block
