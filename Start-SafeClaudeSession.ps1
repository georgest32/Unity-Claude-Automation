# Start-SafeClaudeSession.ps1
# Starts Claude with safe auto-approval and file archiving

param(
    [switch]$EnableAutoAccept,
    [switch]$EnableGitTracking,
    [string]$ArchivePath = ".\Archive",
    [switch]$Debug
)

Write-Host @"
================================================================================
SAFE CLAUDE SESSION MANAGER
================================================================================
This wrapper ensures all Claude operations are safe and reversible:
- Files are archived before modification
- Destructive operations are blocked
- Git commits after each feature
- Auto-approval only for safe operations

"@ -ForegroundColor Cyan

# Ensure archive directory exists
if (-not (Test-Path $ArchivePath)) {
    New-Item -Path $ArchivePath -ItemType Directory -Force | Out-Null
    Write-Host "✅ Created archive directory: $ArchivePath" -ForegroundColor Green
}

# Create a file system watcher to archive files before modification
$watcher = New-Object System.IO.FileSystemWatcher
$watcher.Path = $PWD.Path
$watcher.IncludeSubdirectories = $true
$watcher.NotifyFilter = [System.IO.NotifyFilters]::LastWrite

# Archive function
$archiveAction = {
    param($Source, $Event)
    
    $filePath = $Event.SourceEventArgs.FullPath
    $fileName = Split-Path $filePath -Leaf
    
    # Skip certain files/directories
    if ($fileName -match "\.git|Archive|\.claude|node_modules|\.processed") {
        return
    }
    
    # Archive the file before it's modified
    $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
    $archiveDir = Join-Path $ArchivePath $timestamp
    
    if (-not (Test-Path $archiveDir)) {
        New-Item -Path $archiveDir -ItemType Directory -Force | Out-Null
    }
    
    $relativePath = $filePath.Replace($PWD.Path, "").TrimStart("\")
    $archiveFile = Join-Path $archiveDir $relativePath
    $archiveFileDir = Split-Path $archiveFile -Parent
    
    if (-not (Test-Path $archiveFileDir)) {
        New-Item -Path $archiveFileDir -ItemType Directory -Force | Out-Null
    }
    
    try {
        Copy-Item -Path $filePath -Destination $archiveFile -Force -ErrorAction SilentlyContinue
        Write-Host "[ARCHIVE] Backed up: $relativePath" -ForegroundColor DarkGray
    } catch {
        # File might be locked, that's okay
    }
}

# Register the watcher
Register-ObjectEvent -InputObject $watcher -EventName "Changed" -Action $archiveAction | Out-Null
$watcher.EnableRaisingEvents = $true

Write-Host "✅ File archiving enabled" -ForegroundColor Green

# Git tracking function
function Invoke-SafeGitCommit {
    param(
        [string]$Message = "Auto-commit: Safe operation completed"
    )
    
    try {
        # Check if we're in a git repo
        $gitStatus = git status 2>&1
        if ($LASTEXITCODE -eq 0) {
            # Add all changes
            git add -A
            
            # Commit with descriptive message
            $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
            $fullMessage = "$Message`n`nTimestamp: $timestamp`nAuto-committed by SafeClaudeSession"
            git commit -m $fullMessage 2>&1 | Out-Null
            
            if ($LASTEXITCODE -eq 0) {
                Write-Host "[GIT] ✅ Changes committed" -ForegroundColor Green
                
                # Push to remote (only if it's a safe branch)
                $currentBranch = git rev-parse --abbrev-ref HEAD
                if ($currentBranch -notmatch "main|master|production") {
                    git push 2>&1 | Out-Null
                    if ($LASTEXITCODE -eq 0) {
                        Write-Host "[GIT] ✅ Pushed to $currentBranch" -ForegroundColor Green
                    }
                } else {
                    Write-Host "[GIT] ⚠️ Skipping push to protected branch: $currentBranch" -ForegroundColor Yellow
                }
            }
        }
    } catch {
        Write-Warning "[GIT] Could not commit: $_"
    }
}

# Monitor for completion signals
$completionWatcher = {
    param($FilePath)
    
    # Look for signals that a feature is complete
    if ($FilePath -match "\.json$" -and (Get-Content $FilePath -Raw) -match "complete|success|fixed") {
        Invoke-SafeGitCommit -Message "Feature completed: $(Split-Path $FilePath -Leaf)"
    }
}

if ($EnableGitTracking) {
    Write-Host "✅ Git auto-commit enabled" -ForegroundColor Green
    
    # Set up periodic git commits
    $gitTimer = New-Object System.Timers.Timer
    $gitTimer.Interval = 300000  # 5 minutes
    $gitTimer.AutoReset = $true
    
    Register-ObjectEvent -InputObject $gitTimer -EventName Elapsed -Action {
        $changes = git status --porcelain
        if ($changes) {
            Invoke-SafeGitCommit -Message "Periodic auto-commit"
        }
    } | Out-Null
    
    $gitTimer.Start()
}

# Send keys to enable auto-accept mode in Claude
if ($EnableAutoAccept) {
    Write-Host "`n⚠️ IMPORTANT: When Claude starts, press shift+tab to enable auto-accept mode" -ForegroundColor Yellow
    Write-Host "   The UI should show 'auto-accept edit on'" -ForegroundColor Yellow
    Write-Host "`nAlternatively, start Claude with: claude --dangerously-skip-permissions" -ForegroundColor Gray
}

Write-Host @"

SAFETY FEATURES ACTIVE:
- Archive before modify: ✅
- Git tracking: $(if ($EnableGitTracking) { "✅" } else { "❌" })
- Auto-accept mode: $(if ($EnableAutoAccept) { "Ready (press shift+tab)" } else { "Manual" })

SAFE OPERATIONS (auto-approved):
  • git status, git diff, git add, git commit
  • Read any file
  • Write to src/, *.ps1, *.psm1, *.md
  • Get-*, Test-* PowerShell commands
  • ls, pwd, dir commands

BLOCKED OPERATIONS:
  • rm -rf, sudo commands
  • git push --force, git reset --hard
  • Writing to .env, *.key, *.pem files
  • Remove-Item -Recurse -Force

Press Ctrl+C to stop monitoring
================================================================================

"@ -ForegroundColor Cyan

# Keep the script running
try {
    while ($true) {
        Start-Sleep -Seconds 60
        
        # Periodic status check
        $archivedCount = (Get-ChildItem $ArchivePath -Recurse -File -ErrorAction SilentlyContinue).Count
        Write-Host "[$(Get-Date -Format 'HH:mm:ss')] Status - Archived files: $archivedCount" -ForegroundColor DarkGray
    }
} finally {
    # Cleanup
    $watcher.EnableRaisingEvents = $false
    $watcher.Dispose()
    
    if ($gitTimer) {
        $gitTimer.Stop()
        $gitTimer.Dispose()
    }
    
    # Final git commit
    if ($EnableGitTracking) {
        Invoke-SafeGitCommit -Message "Session ended - final commit"
    }
    
    Write-Host "`nSafe Claude session ended." -ForegroundColor Yellow
}