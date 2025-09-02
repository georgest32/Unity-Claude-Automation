# CLIOrchestrator Subsystem Manifest
# Updated from AutonomousAgent to CLIOrchestrator
# Date: 2025-08-25

@{
    # Required fields
    Name = "CLIOrchestrator"
    Version = "2.0.0"
    Description = "CLI orchestration system for automated Unity error detection and Claude interactions"
    StartScript = ".\Start-CLIOrchestrator-WithPermissions.ps1"  # Includes permission handling
    WorkingDirectory = "C:\UnityProjects\Sound-and-Shoal\Unity-Claude-Automation"
    
    # Dependencies
    Dependencies = @("SystemMonitoring")
    
    # Health monitoring
    HealthCheckFunction = "Test-CLIOrchestratorStatus"
    HealthCheckInterval = 30  # seconds
    
    # Recovery policy
    RestartPolicy = "OnFailure"  # OnFailure, Always, Never
    MaxRestarts = 3
    RestartDelay = 5  # seconds
    
    # Resource limits
    MaxMemoryMB = 500
    MaxCpuPercent = 25
    
    # Window visibility
    WindowStyle = "Normal"  # Normal, Hidden, Minimized, Maximized
    
    # Mutex for singleton enforcement
    MutexName = "Global\UnityClaudeCLIOrchestrator"
    
    # Migration metadata
    MigratedFrom = "AutonomousAgent"
    MigrationDate = "2025-08-25"
    GeneratedBy = "Manual migration from AutonomousAgent"
}