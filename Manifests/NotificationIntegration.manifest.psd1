# NotificationIntegration Subsystem Manifest
# Week 6 Days 1-2: System Integration Implementation
# Bootstrap Orchestrator Configuration for Unified Notification Integration Service

@{
    # Required fields
    Name = "NotificationIntegration"
    Version = "1.0.0"
    Description = "Unified notification integration service that coordinates email and webhook notifications with autonomous agent workflow"
    StartScript = ".\Start-NotificationIntegrationService.ps1"
    WorkingDirectory = "C:\UnityProjects\Sound-and-Shoal\Unity-Claude-Automation"
    
    # Dependencies - requires SystemMonitoring and both notification services
    Dependencies = @("SystemMonitoring", "EmailNotifications", "WebhookNotifications")
    
    # Health monitoring
    HealthCheckFunction = "Test-NotificationIntegration"
    HealthCheckInterval = 60  # seconds - less frequent for integration services
    
    # Recovery policy
    RestartPolicy = "OnFailure"  # OnFailure, Always, Never
    MaxRestarts = 3  # Moderate for integration services
    RestartDelay = 15  # seconds - longer delay for multiple dependencies
    
    # Resource limits - integration services need more resources for coordination
    MaxMemoryMB = 200
    MaxCpuPercent = 15
    
    # Mutex for singleton enforcement
    MutexName = "Global\UnityClaudeNotificationIntegration"
    
    # Integration-specific configuration
    NotificationTypes = @("Error", "Warning", "Info", "Success")
    IntegrationMethods = @("Email", "Webhook", "Hybrid")
    RetryAttempts = 3
    RetryDelaySeconds = 5
    ExponentialBackoff = $true
    CircuitBreakerEnabled = $true
    QueueManagementEnabled = $true
    
    # Trigger configuration
    TriggerPoints = @{
        "UnityCompilation" = $true
        "ClaudeSubmission" = $true
        "ErrorResolution" = $true
        "SystemHealth" = $true
        "AutonomousAgent" = $true
    }
    
    # Performance settings
    BatchNotifications = $true
    BatchIntervalSeconds = 30
    MaxBatchSize = 10
    EnableFailover = $true
    
    # Integration metadata
    CreatedFor = "Week 6 Days 1-2 System Integration"
    CreationDate = "2025-08-22"
    Author = "Unity-Claude Automation System"
    IntegrationPhase = "PHASE 2: EMAIL/WEBHOOK NOTIFICATIONS"
    BootstrapIntegration = $true
}