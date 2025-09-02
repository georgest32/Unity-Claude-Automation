# Archive-OldResponses.ps1
# Archives old response files to reduce orchestrator processing noise

param(
    [string]$ResponsePath = ".\ClaudeResponses\Autonomous",
    [string]$ArchivePath = ".\ClaudeResponses\Archive",
    [int]$DaysToKeep = 7
)

Write-Host "Archiving old response files..." -ForegroundColor Cyan

# Create archive directory if it doesn't exist
if (-not (Test-Path $ArchivePath)) {
    New-Item -Path $ArchivePath -ItemType Directory -Force | Out-Null
    Write-Host "Created archive directory: $ArchivePath" -ForegroundColor Green
}

# Get old response files
$cutoffDate = (Get-Date).AddDays(-$DaysToKeep)
$oldFiles = Get-ChildItem -Path $ResponsePath -Filter "*.json" -File | 
    Where-Object { $_.LastWriteTime -lt $cutoffDate }

if ($oldFiles) {
    Write-Host "Found $($oldFiles.Count) files older than $DaysToKeep days" -ForegroundColor Yellow
    
    # Create timestamped archive subdirectory
    $archiveSubDir = Join-Path $ArchivePath "Archive_$(Get-Date -Format 'yyyyMMdd_HHmmss')"
    New-Item -Path $archiveSubDir -ItemType Directory -Force | Out-Null
    
    # Move files
    foreach ($file in $oldFiles) {
        Move-Item -Path $file.FullName -Destination $archiveSubDir -Force
        Write-Host "  Archived: $($file.Name)" -ForegroundColor Gray
    }
    
    Write-Host "✅ Archived $($oldFiles.Count) files to: $archiveSubDir" -ForegroundColor Green
} else {
    Write-Host "No files older than $DaysToKeep days found" -ForegroundColor Gray
}

# Also move any .processed signal files
$processedFiles = Get-ChildItem -Path $ResponsePath -Filter "*.processed" -File
if ($processedFiles) {
    Write-Host "Moving $($processedFiles.Count) processed signal files..." -ForegroundColor Yellow
    
    $signalArchive = Join-Path $ArchivePath "ProcessedSignals"
    if (-not (Test-Path $signalArchive)) {
        New-Item -Path $signalArchive -ItemType Directory -Force | Out-Null
    }
    
    foreach ($file in $processedFiles) {
        Move-Item -Path $file.FullName -Destination $signalArchive -Force
    }
    
    Write-Host "✅ Moved processed signals to: $signalArchive" -ForegroundColor Green
}

Write-Host "`nArchiving complete!" -ForegroundColor Green