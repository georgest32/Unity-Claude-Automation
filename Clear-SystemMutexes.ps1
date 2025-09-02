# Clear-SystemMutexes.ps1
# Clears Windows mutex locks for Unity-Claude subsystems
# This handles the case where mutex locks persist after process termination

Write-Host "Clearing Unity-Claude system mutexes..." -ForegroundColor Yellow

$mutexNames = @(
    "Global\UnityClaudeCLIOrchestrator",
    "Global\UnityClaudeSystemMonitoring", 
    "Global\UnityClaudeCLISubmission",
    "Global\UnityClaudeEmailNotifications",
    "Global\UnityClaudeNotificationIntegration",
    "Global\UnityClaudeWebhookNotifications"
)

$clearedCount = 0
foreach ($mutexName in $mutexNames) {
    try {
        # Try to open the existing mutex
        $mutex = [System.Threading.Mutex]::OpenExisting($mutexName)
        if ($mutex) {
            # If we can open it, try to release it
            try {
                $mutex.ReleaseMutex()
                $mutex.Dispose()
                Write-Host "  Cleared mutex: $mutexName" -ForegroundColor Green
                $clearedCount++
            } catch {
                Write-Host "  Could not release mutex: $mutexName - $($_.Exception.Message)" -ForegroundColor Yellow
            }
        }
    } catch [System.Threading.WaitHandleCannotBeOpenedException] {
        # Mutex doesn't exist - that's good
        Write-Host "  Mutex not found (already cleared): $mutexName" -ForegroundColor Gray
    } catch {
        Write-Host "  Error checking mutex: $mutexName - $($_.Exception.Message)" -ForegroundColor Red
    }
}

Write-Host ""
if ($clearedCount -gt 0) {
    Write-Host "Cleared $clearedCount mutex locks" -ForegroundColor Green
} else {
    Write-Host "No mutex locks needed clearing" -ForegroundColor Green
}

Write-Host ""
Write-Host "System mutexes cleared. You can now restart Unity-Claude subsystems." -ForegroundColor Cyan