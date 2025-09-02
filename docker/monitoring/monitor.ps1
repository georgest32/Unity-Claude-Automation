# File Monitoring Service
param(
    [string]$WatchPath = "/watch",
    [string]$LogPath = "/var/log/monitoring"
)

Write-Host "Unity-Claude File Monitoring Service Starting..." -ForegroundColor Green

# Import monitoring modules
Import-Module Unity-Claude-FileMonitor -Force -ErrorAction SilentlyContinue
Import-Module Unity-Claude-DocumentationDrift -Force -ErrorAction SilentlyContinue

Write-Host "Monitoring path: $WatchPath" -ForegroundColor Cyan
Write-Host "Log path: $LogPath" -ForegroundColor Cyan

# Create log directory if it doesn't exist
if (-not (Test-Path $LogPath)) {
    New-Item -Path $LogPath -ItemType Directory -Force | Out-Null
}

# Create file watcher
$watcher = New-Object System.IO.FileSystemWatcher
$watcher.Path = $WatchPath
$watcher.IncludeSubdirectories = $true
$watcher.EnableRaisingEvents = $true

# Define action for file changes
$action = {
    $path = $Event.SourceEventArgs.FullPath
    $changeType = $Event.SourceEventArgs.ChangeType
    $timeStamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    
    $logMessage = "$timeStamp - ${changeType}: $path"
    Write-Host $logMessage -ForegroundColor Yellow
    
    # Log to file
    Add-Content -Path "$LogPath/changes.log" -Value $logMessage
    
    # Check for documentation drift if it is a code file
    if ($path -match "\.(ps1|psm1|py|js|ts|cs)$") {
        Write-Host "  Checking documentation drift for $path" -ForegroundColor Gray
        # Trigger documentation drift check
        # This would integrate with the documentation drift module
    }
}

# Register event handlers
Register-ObjectEvent -InputObject $watcher -EventName "Changed" -Action $action
Register-ObjectEvent -InputObject $watcher -EventName "Created" -Action $action
Register-ObjectEvent -InputObject $watcher -EventName "Deleted" -Action $action
Register-ObjectEvent -InputObject $watcher -EventName "Renamed" -Action $action

Write-Host "File monitoring service is running..." -ForegroundColor Green

# Keep the service running
while ($true) {
    Start-Sleep -Seconds 60
    Write-Host "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] Monitoring active" -ForegroundColor Gray
}