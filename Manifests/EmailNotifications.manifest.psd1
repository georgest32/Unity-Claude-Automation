# EmailNotifications Subsystem Manifest
# Week 6 Days 1-2: System Integration Implementation
# Bootstrap Orchestrator Configuration for Email Notification Service

@{
    # Required fields
    Name = "EmailNotifications"
    Version = "1.0.0"
    Description = "Email notification service for Unity-Claude autonomous operations with SMTP integration and retry logic"
    StartScript = ".\Start-EmailNotificationService.ps1"
    WorkingDirectory = "C:\UnityProjects\Sound-and-Shoal\Unity-Claude-Automation"
    
    # Dependencies - requires SystemMonitoring for configuration and logging
    Dependencies = @("SystemMonitoring")
    
    # Health monitoring
    HealthCheckFunction = "Test-EmailNotificationHealth"
    HealthCheckInterval = 60  # seconds - less frequent for notification services
    
    # Recovery policy
    RestartPolicy = "OnFailure"  # OnFailure, Always, Never
    MaxRestarts = 5  # Higher for notification services as they are less critical than core functions
    RestartDelay = 10  # seconds - longer delay for external service dependencies
    
    # Resource limits - email services are lightweight
    MaxMemoryMB = 100
    MaxCpuPercent = 10
    
    # Mutex for singleton enforcement
    MutexName = "Global\UnityClaudeEmailNotifications"
    
    # Notification-specific configuration
    NotificationTypes = @("Error", "Warning", "Info", "Success")
    DeliveryMethods = @("SMTP", "SystemNetMail")
    RetryAttempts = 3
    RetryDelaySeconds = 5
    ExponentialBackoff = $true
    
    # Integration metadata
    CreatedFor = "Week 6 Days 1-2 System Integration"
    CreationDate = "2025-08-22"
    Author = "Unity-Claude Automation System"
    IntegrationPhase = "PHASE 2: EMAIL/WEBHOOK NOTIFICATIONS"
}