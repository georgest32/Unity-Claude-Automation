# Start-PermissionMonitoring.ps1
# Direct test of permission monitoring functionality

Write-Host "`n=== Starting Direct Permission Monitoring Test ===" -ForegroundColor Cyan

# Import modules
Import-Module ".\Modules\Unity-Claude-CLIOrchestrator\Unity-Claude-CLIOrchestrator.psm1" -Force -WarningAction SilentlyContinue
Import-Module ".\Modules\Unity-Claude-CLIOrchestrator\Core\PermissionIntegration.psm1" -Force -WarningAction SilentlyContinue -ErrorAction SilentlyContinue

# Initialize the orchestrator
Write-Host "`nInitializing orchestrator..." -ForegroundColor Yellow
$initResult = Initialize-CLIOrchestrator -ValidateComponents -SetupDirectories

# Check initialization
if ($initResult) {
    Write-Host "✅ Orchestrator initialized" -ForegroundColor Green
} else {
    Write-Host "❌ Failed to initialize orchestrator" -ForegroundColor Red
    exit 1
}

# Show monitoring path
$status = Get-CLIOrchestrationStatus
Write-Host "`nMonitoring path: $($status.ResponsePath)" -ForegroundColor Cyan
Write-Host "Initial status: Active=$($status.Active)" -ForegroundColor Gray

# Create a test permission request
Write-Host "`nCreating test permission request..." -ForegroundColor Yellow
$testRequest = @{
    Type = "PermissionRequest"
    Tool = "Bash"
    PromptText = "Allow Bash to execute command 'git status'? (y/n)"
    Command = "git status"
    RequestId = [Guid]::NewGuid().ToString()
    Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Context = "Direct monitoring test"
    SafetyLevel = "Low"
    RequiresApproval = false
} | ConvertTo-Json

$requestFile = Join-Path $status.ResponsePath "PermissionRequest_direct_$(Get-Date -Format 'yyyyMMdd_HHmmss').json"
$testRequest | Out-File $requestFile -Force
Write-Host "  Created: $(Split-Path $requestFile -Leaf)" -ForegroundColor Green

# Start the orchestration monitoring
Write-Host "`n🚀 Starting orchestration monitoring..." -ForegroundColor Green
Write-Host "The orchestrator will now monitor for permission requests." -ForegroundColor Yellow
Write-Host "Press Ctrl+C to stop monitoring.`n" -ForegroundColor Gray

try {
    # Start the actual monitoring loop
    Start-CLIOrchestration -MonitoringInterval 500 -EnableDecisionMaking
} catch {
    Write-Host "`n❌ Monitoring stopped: $_" -ForegroundColor Red
}

Write-Host "`n=== Monitoring Test Complete ===" -ForegroundColor Cyan