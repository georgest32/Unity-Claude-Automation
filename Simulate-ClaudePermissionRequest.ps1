# Simulate-ClaudePermissionRequest.ps1
# Simulates Claude requesting permission for operations

param(
    [string]$Operation = "bash",
    [string]$Command = "dir C:\Windows",
    [switch]$AutoApprove
)

Write-Host "`n=== Simulating Claude Permission Request ===" -ForegroundColor Cyan
Write-Host "This simulates Claude asking for permission to run: $Command" -ForegroundColor Yellow

# Create a response file that looks like Claude is asking for permission
$timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$responseDir = Join-Path $PSScriptRoot "ClaudeResponses\Autonomous"

# Ensure directory exists
New-Item -Path $responseDir -ItemType Directory -Force -ErrorAction SilentlyContinue | Out-Null

# Create different types of permission requests based on operation
switch ($Operation.ToLower()) {
    "bash" {
        $content = @"
{
    "Type": "PermissionRequest",
    "Tool": "Bash",
    "PromptText": "Allow Bash to execute command '$Command'? (y/n)",
    "Command": "$Command",
    "RequestId": "$([Guid]::NewGuid())",
    "Timestamp": "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')",
    "Context": "Claude needs to run a system command to analyze the codebase",
    "SafetyLevel": "Medium",
    "RequiresApproval": true
}
"@
    }
    
    "delete" {
        $content = @"
{
    "Type": "PermissionRequest",
    "Tool": "FileSystem",
    "PromptText": "Delete file '$Command'? (y/n)",
    "Operation": "Delete",
    "Target": "$Command",
    "RequestId": "$([Guid]::NewGuid())",
    "Timestamp": "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')",
    "Context": "Claude wants to remove an outdated file",
    "SafetyLevel": "High",
    "RequiresApproval": true
}
"@
    }
    
    "edit" {
        $content = @"
{
    "Type": "PermissionRequest",
    "Tool": "Edit",
    "PromptText": "Apply edit to '$Command'? (y/n)",
    "File": "$Command",
    "RequestId": "$([Guid]::NewGuid())",
    "Timestamp": "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')",
    "Context": "Claude wants to modify a configuration file",
    "SafetyLevel": "Medium",
    "RequiresApproval": true,
    "Changes": {
        "LinesAdded": 5,
        "LinesRemoved": 2,
        "Type": "Refactoring"
    }
}
"@
    }
    
    "git" {
        $content = @"
{
    "Type": "PermissionRequest",
    "Tool": "Git",
    "PromptText": "Execute git command '$Command'? (y/n)",
    "GitCommand": "$Command",
    "RequestId": "$([Guid]::NewGuid())",
    "Timestamp": "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')",
    "Context": "Claude wants to perform a git operation",
    "SafetyLevel": "High",
    "RequiresApproval": true,
    "Repository": "Unity-Claude-Automation"
}
"@
    }
}

# Write the request file
$requestFile = Join-Path $responseDir "PermissionRequest_${Operation}_${timestamp}.json"
$content | Out-File $requestFile -Force
Write-Host "`n✅ Created permission request file:" -ForegroundColor Green
Write-Host "   $requestFile" -ForegroundColor Gray

# If auto-approve is set, create an approval response
if ($AutoApprove) {
    Start-Sleep -Milliseconds 500
    $approvalContent = @"
{
    "Type": "PermissionResponse",
    "RequestId": "$([Guid]::NewGuid())",
    "Approved": true,
    "ApprovedBy": "AutoApprove",
    "Timestamp": "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')",
    "Note": "Auto-approved for testing"
}
"@
    $approvalFile = Join-Path $responseDir "PermissionResponse_${Operation}_${timestamp}.json"
    $approvalContent | Out-File $approvalFile -Force
    Write-Host "`n✅ Auto-approved the request" -ForegroundColor Green
}

# Monitor for processing
Write-Host "`n⏳ Waiting for permission handler to process..." -ForegroundColor Yellow

# Check if the orchestrator is monitoring this directory
$maxWait = 10
$waited = 0
while ($waited -lt $maxWait) {
    Start-Sleep -Seconds 1
    $waited++
    
    # Check for .processed marker
    $processedFile = "$requestFile.processed"
    if (Test-Path $processedFile) {
        Write-Host "✅ Permission request was processed!" -ForegroundColor Green
        
        # Read the processed result if available
        if (Test-Path $processedFile) {
            $result = Get-Content $processedFile -Raw -ErrorAction SilentlyContinue
            if ($result) {
                Write-Host "`nProcessing Result:" -ForegroundColor Cyan
                Write-Host $result -ForegroundColor Gray
            }
        }
        break
    }
    
    # Show waiting indicator
    if ($waited % 2 -eq 0) {
        Write-Host "." -NoNewline -ForegroundColor Gray
    }
}

if ($waited -eq $maxWait) {
    Write-Host "`n⚠️ Request was not processed within $maxWait seconds" -ForegroundColor Yellow
    Write-Host "The permission handler may not be actively monitoring." -ForegroundColor Gray
    Write-Host "`nTo start monitoring, run:" -ForegroundColor Cyan
    Write-Host "  pwsh .\Start-UnityClaudeSystem-Windowed.ps1 -StartPythonServices" -ForegroundColor White
}

Write-Host "`n=== Simulation Complete ===" -ForegroundColor Cyan