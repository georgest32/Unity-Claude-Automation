# Test-PermissionApproval.ps1
# Test script to trigger permission approval for various operations

Write-Host "`n=== Testing Permission Approval System ===" -ForegroundColor Cyan
Write-Host "This will test various operations that should trigger permission prompts`n" -ForegroundColor Yellow

# Ensure the permission system is initialized
$initScript = Join-Path $PSScriptRoot "Initialize-CLIOrchestratorWithPermissions.ps1"
if (Test-Path $initScript) {
    Write-Host "Initializing CLIOrchestrator with Permissions..." -ForegroundColor Green
    & $initScript -EnableSafeOperations -EnableInterceptor -Mode "Interactive"
    Start-Sleep -Seconds 2
}

# Test 1: File System Operation
Write-Host "`n[TEST 1] File System Operation - Delete attempt" -ForegroundColor Magenta
$testFile = Join-Path $env:TEMP "test_permission_file.txt"
"Test content" | Out-File $testFile -Force
Write-Host "Created test file: $testFile"

# Simulate a Claude response requesting file deletion
$deleteRequest = @{
    Type = "FileOperation"
    Operation = "Delete"
    Path = $testFile
    RequestId = [Guid]::NewGuid().ToString()
    Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Context = "Claude wants to delete a temporary test file"
}

Write-Host "Simulating delete request from Claude..." -ForegroundColor Yellow
$jsonRequest = $deleteRequest | ConvertTo-Json -Compress
$responseFile = Join-Path $PSScriptRoot "ClaudeResponses\Autonomous\Test_Permission_$(Get-Date -Format 'yyyyMMdd_HHmmss').json"
New-Item -Path (Split-Path $responseFile -Parent) -ItemType Directory -Force -ErrorAction SilentlyContinue | Out-Null
$jsonRequest | Out-File $responseFile -Force

# Test 2: Bash Command Operation
Write-Host "`n[TEST 2] Bash Command Operation - System modification attempt" -ForegroundColor Magenta
$bashRequest = @{
    Type = "BashCommand"
    Command = "rm -rf /important/folder"
    RequestId = [Guid]::NewGuid().ToString()
    Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Context = "Claude wants to run a potentially dangerous bash command"
    PromptText = "Do you want to run `"rm -rf /important/folder`"? [y/n]"
}

Write-Host "Simulating bash command request from Claude..." -ForegroundColor Yellow
$bashResponseFile = Join-Path $PSScriptRoot "ClaudeResponses\Autonomous\Test_BashPermission_$(Get-Date -Format 'yyyyMMdd_HHmmss').json"
$bashRequest | ConvertTo-Json -Compress | Out-File $bashResponseFile -Force

# Test 3: Git Operation
Write-Host "`n[TEST 3] Git Operation - Repository modification" -ForegroundColor Magenta
$gitRequest = @{
    Type = "GitOperation"
    Operation = "Push"
    Repository = "Unity-Claude-Automation"
    Branch = "main"
    RequestId = [Guid]::NewGuid().ToString()
    Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Context = "Claude wants to push changes to main branch"
}

Write-Host "Simulating git push request from Claude..." -ForegroundColor Yellow
$gitResponseFile = Join-Path $PSScriptRoot "ClaudeResponses\Autonomous\Test_GitPermission_$(Get-Date -Format 'yyyyMMdd_HHmmss').json"
$gitRequest | ConvertTo-Json -Compress | Out-File $gitResponseFile -Force

# Test 4: Direct Permission Prompt Test
Write-Host "`n[TEST 4] Direct Permission Prompt Test" -ForegroundColor Magenta
if (Get-Command Test-ClaudePermissionDetection -ErrorAction SilentlyContinue) {
    Write-Host "Running permission detection test..." -ForegroundColor Yellow
    Test-ClaudePermissionDetection
}

# Test 5: Safe Operations Handler Test
Write-Host "`n[TEST 5] Safe Operations Handler Test" -ForegroundColor Magenta
if (Get-Module Unity-Claude-SafeOperationsHandler) {
    Write-Host "Testing archiving operation (should be auto-approved)..." -ForegroundColor Yellow
    
    # Create a test directory to archive
    $testDir = Join-Path $env:TEMP "test_archive_dir"
    New-Item -Path $testDir -ItemType Directory -Force | Out-Null
    "Test file" | Out-File (Join-Path $testDir "test.txt") -Force
    
    # Try to "delete" it (should be archived instead)
    if (Get-Command Invoke-SafeOperation -ErrorAction SilentlyContinue) {
        $result = Invoke-SafeOperation -Operation "Delete" -Target $testDir -Reason "Testing safe deletion"
        Write-Host "Safe operation result: $($result.Success)" -ForegroundColor Green
    }
}

# Monitor for permission responses
Write-Host "`n=== Monitoring for Permission Responses ===" -ForegroundColor Cyan
Write-Host "The system should now process these requests and show permission prompts." -ForegroundColor Yellow
Write-Host "Check the console output for permission approval messages.`n" -ForegroundColor Yellow

# Give the system time to process
Write-Host "Waiting for permission handler to process requests..." -ForegroundColor Gray
Start-Sleep -Seconds 5

# Check for processed files
$processedFiles = Get-ChildItem -Path "$PSScriptRoot\ClaudeResponses\Autonomous" -Filter "*.processed" -ErrorAction SilentlyContinue | 
    Where-Object { $_.CreationTime -gt (Get-Date).AddMinutes(-1) }

if ($processedFiles) {
    Write-Host "`n✅ Found $($processedFiles.Count) processed permission requests:" -ForegroundColor Green
    $processedFiles | ForEach-Object {
        Write-Host "  - $($_.Name)" -ForegroundColor Gray
    }
} else {
    Write-Host "`n⚠️ No processed files found yet. The permission handler may still be processing." -ForegroundColor Yellow
}

Write-Host "`n=== Permission Approval Test Complete ===" -ForegroundColor Cyan
Write-Host "Review the console output above for permission prompts and approvals." -ForegroundColor Green