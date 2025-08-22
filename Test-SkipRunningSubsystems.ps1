# Test-SkipRunningSubsystems.ps1
# Tests the fix for skipping already-running subsystems in manifest-based startup

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "TEST: Skip Running Subsystems" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan

$projectRoot = "C:\UnityProjects\Sound-and-Shoal\Unity-Claude-Automation"
Set-Location $projectRoot

# Load the SystemStatus module
Write-Host "Loading SystemStatus module..." -ForegroundColor Yellow
Import-Module ".\Modules\Unity-Claude-SystemStatus\Unity-Claude-SystemStatus.psm1" -Force

# Test the new function
Write-Host "`n1. Testing Test-SubsystemRunning function..." -ForegroundColor Yellow
$testResults = @{
    SystemMonitoring = Test-SubsystemRunning -SubsystemName "SystemMonitoring" -MutexName "Global\UnityClaudeSystemMonitoring"
    AutonomousAgent = Test-SubsystemRunning -SubsystemName "AutonomousAgent" -MutexName "Global\UnityClaudeAutonomousAgent"
    CLISubmission = Test-SubsystemRunning -SubsystemName "CLISubmission" -MutexName "Global\UnityClaudeCLISubmission"
}

Write-Host "  Current subsystem status:" -ForegroundColor White
foreach ($subsystem in $testResults.Keys | Sort-Object) {
    $status = if ($testResults[$subsystem]) { "RUNNING" } else { "NOT RUNNING" }
    $color = if ($testResults[$subsystem]) { "Green" } else { "Gray" }
    Write-Host "    - ${subsystem}: $status" -ForegroundColor $color
}

# Load backward compatibility layer
Write-Host "`n2. Loading backward compatibility layer..." -ForegroundColor Yellow
Import-Module ".\Migration\Legacy-Compatibility.psm1" -Force
Write-Host "  Loaded" -ForegroundColor Green

# Test manifest-based startup with the fix
Write-Host "`n3. Testing manifest-based startup (should skip running subsystems)..." -ForegroundColor Yellow
Write-Host "  This should:" -ForegroundColor Gray
Write-Host "    - Skip SystemMonitoring if already running" -ForegroundColor Gray
Write-Host "    - Skip AutonomousAgent if already running" -ForegroundColor Gray
Write-Host "    - Start any subsystems that aren't running" -ForegroundColor Gray

$result = Invoke-ManifestBasedSystemStartup
if ($result.Success) {
    Write-Host "`n  [SUCCESS] Manifest-based startup completed" -ForegroundColor Green
    Write-Host "  Started subsystems: $($result.StartedSubsystems -join ', ')" -ForegroundColor White
} else {
    Write-Host "`n  [FAILED] Manifest-based startup failed" -ForegroundColor Red
    Write-Host "  Error: $($result.Message)" -ForegroundColor Red
}

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "TEST COMPLETE" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan