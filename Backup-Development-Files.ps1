# Backup Development Files Script
# Backs up files that are ignored by git but contain important development history

Write-Host "=== Unity-Claude Development Files Backup ===" -ForegroundColor Green

$BackupDir = "DevBackup_$(Get-Date -Format 'yyyyMMdd_HHmmss')"
$BackupPath = Join-Path (Get-Location) $BackupDir

Write-Host "Creating backup directory: $BackupPath" -ForegroundColor Cyan
New-Item -ItemType Directory -Path $BackupPath -Force | Out-Null

# Create subdirectories for organization
$Subdirs = @(
    "ClaudeResponses",
    "TestResults", 
    "Logs",
    "AIAnalysis",
    "BuildArtifacts",
    "NodeModules"
)

foreach ($subdir in $Subdirs) {
    New-Item -ItemType Directory -Path (Join-Path $BackupPath $subdir) -Force | Out-Null
}

Write-Host "Backup directories created" -ForegroundColor Green

# Step 1: Backup Claude Responses (development history)
Write-Host "`nBacking up Claude Responses..." -ForegroundColor Yellow
if (Test-Path "ClaudeResponses") {
    Copy-Item -Path "ClaudeResponses\*" -Destination (Join-Path $BackupPath "ClaudeResponses") -Recurse -Force
    $claudeFiles = (Get-ChildItem "ClaudeResponses" -Recurse -File).Count
    Write-Host "Backed up $claudeFiles Claude response files" -ForegroundColor Green
}

# Step 2: Backup Test Results
Write-Host "`nBacking up Test Results..." -ForegroundColor Yellow  
if (Test-Path "TestResults") {
    Copy-Item -Path "TestResults\*" -Destination (Join-Path $BackupPath "TestResults") -Recurse -Force
    $testFiles = (Get-ChildItem "TestResults" -Recurse -File).Count
    Write-Host "Backed up $testFiles test result files" -ForegroundColor Green
}

# Step 3: Backup Logs
Write-Host "`nBacking up Logs..." -ForegroundColor Yellow
if (Test-Path "Logs") {
    Copy-Item -Path "Logs\*" -Destination (Join-Path $BackupPath "Logs") -Recurse -Force  
    $logFiles = (Get-ChildItem "Logs" -Recurse -File).Count
    Write-Host "Backed up $logFiles log files" -ForegroundColor Green
}

Write-Host "`n✅ Development files backup completed!" -ForegroundColor Green
Write-Host "Backup location: $BackupPath" -ForegroundColor Cyan