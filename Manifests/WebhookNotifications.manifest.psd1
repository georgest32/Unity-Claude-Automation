# WebhookNotifications Subsystem Manifest
# Week 6 Days 1-2: System Integration Implementation
# Bootstrap Orchestrator Configuration for Webhook Notification Service

@{
    # Required fields
    Name = "WebhookNotifications"
    Version = "1.0.0"
    Description = "Webhook notification service for Unity-Claude autonomous operations with HTTP delivery and authentication"
    StartScript = ".\Start-WebhookNotificationService.ps1"
    WorkingDirectory = "C:\UnityProjects\Sound-and-Shoal\Unity-Claude-Automation"
    
    # Dependencies - requires SystemMonitoring and can work alongside EmailNotifications
    Dependencies = @("SystemMonitoring")
    
    # Health monitoring
    HealthCheckFunction = "Test-WebhookNotificationHealth"
    HealthCheckInterval = 60  # seconds - less frequent for notification services
    
    # Recovery policy
    RestartPolicy = "OnFailure"  # OnFailure, Always, Never
    MaxRestarts = 5  # Higher for notification services as they are less critical than core functions
    RestartDelay = 10  # seconds - longer delay for external service dependencies
    
    # Resource limits - webhook services are lightweight
    MaxMemoryMB = 100
    MaxCpuPercent = 10
    
    # Mutex for singleton enforcement
    MutexName = "Global\UnityClaudeWebhookNotifications"
    
    # Webhook-specific configuration
    NotificationTypes = @("Error", "Warning", "Info", "Success")
    AuthenticationMethods = @("Bearer", "Basic", "APIKey")
    RetryAttempts = 3
    RetryDelaySeconds = 5
    ExponentialBackoff = $true
    UseJitter = $true
    
    # HTTP configuration
    TimeoutSeconds = 30
    UserAgent = "Unity-Claude-Automation/1.0"
    ContentType = "application/json"
    
    # Integration metadata
    CreatedFor = "Week 6 Days 1-2 System Integration"
    CreationDate = "2025-08-22"
    Author = "Unity-Claude Automation System"
    IntegrationPhase = "PHASE 2: EMAIL/WEBHOOK NOTIFICATIONS"
}