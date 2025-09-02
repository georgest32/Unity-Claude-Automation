# Test-OrchestrationMonitoring.ps1
# Diagnostic script to check what the orchestrator is monitoring

Write-Host "`n=== Testing Orchestration Monitoring ===" -ForegroundColor Cyan

# Import the orchestrator module
Import-Module ".\Modules\Unity-Claude-CLIOrchestrator\Unity-Claude-CLIOrchestrator.psm1" -Force -WarningAction SilentlyContinue

# Check the orchestration status
Write-Host "`nChecking orchestration status..." -ForegroundColor Yellow
$status = Get-CLIOrchestrationStatus
$status | Format-List

# Check what path it's monitoring
Write-Host "`nResponse Path being monitored:" -ForegroundColor Yellow
Write-Host "  $($status.ResponsePath)" -ForegroundColor White

# Check if the path exists
if (Test-Path $status.ResponsePath) {
    Write-Host "  ✅ Path exists" -ForegroundColor Green
    
    # List recent files
    Write-Host "`nRecent files in response path:" -ForegroundColor Yellow
    Get-ChildItem $status.ResponsePath -Filter "*.json" | 
        Sort-Object LastWriteTime -Descending | 
        Select-Object -First 5 Name, LastWriteTime | 
        Format-Table
        
    # Check for permission request files
    Write-Host "`nPermission request files:" -ForegroundColor Yellow
    $permFiles = Get-ChildItem $status.ResponsePath -Filter "PermissionRequest*.json"
    if ($permFiles) {
        $permFiles | Select-Object Name, LastWriteTime | Format-Table
        
        # Check for processed markers
        Write-Host "`nProcessed markers:" -ForegroundColor Yellow
        Get-ChildItem $status.ResponsePath -Filter "PermissionRequest*.json.processed" | 
            Select-Object Name, LastWriteTime | Format-Table
    } else {
        Write-Host "  No permission request files found" -ForegroundColor Gray
    }
} else {
    Write-Host "  ❌ Path does not exist!" -ForegroundColor Red
}

# Test creating a permission request directly in the monitored path
Write-Host "`nCreating test permission request in monitored path..." -ForegroundColor Yellow
$testRequest = @{
    Type = "PermissionRequest"
    Tool = "Bash"
    PromptText = "Allow Bash to execute command 'pwd'? (y/n)"
    Command = "pwd"
    RequestId = [Guid]::NewGuid().ToString()
    Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Context = "Test permission request"
    SafetyLevel = "Low"
    RequiresApproval = true
} | ConvertTo-Json

$testFile = Join-Path $status.ResponsePath "PermissionRequest_test_$(Get-Date -Format 'yyyyMMdd_HHmmss').json"
$testRequest | Out-File $testFile -Force
Write-Host "  Created: $(Split-Path $testFile -Leaf)" -ForegroundColor Green

Write-Host "`n=== Diagnostic Complete ===" -ForegroundColor Cyan
Write-Host "The orchestrator should be monitoring: $($status.ResponsePath)" -ForegroundColor White
Write-Host "Active status: $($status.Active)" -ForegroundColor $(if ($status.Active) { "Green" } else { "Red" })