# Initialize script variable if not already set
if (-not $script:DecisionConfig) {
    $script:DecisionConfig = @{
        PerformanceTargets = @{
            DecisionTimeMs = 100
        }
    }
}

function Write-DecisionLog {
    param(
        [string]$Message,
        [string]$Level = "INFO",
        [string]$Component = "DecisionEngine"
    )
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss.fff"
    $logEntry = "[$timestamp] [$Level] [$Component] $Message"
    Write-Host $logEntry -ForegroundColor $(
        switch ($Level) {
            "ERROR" { "Red" }
            "WARN" { "Yellow" }
            "SUCCESS" { "Green" }
            "DEBUG" { "Gray" }
            default { "White" }
        }
    )
}