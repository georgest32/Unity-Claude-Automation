# SafeOperationsHandler.psm1
# Converts all destructive operations to safe, non-destructive alternatives
# Implements automatic git checkpointing for implementation plans

#region Configuration
$script:SafeOpsConfig = @{
    Enabled = $true
    ArchivePath = ".\Archive"
    BackupPath = ".\Backups"
    GitAutoCommit = $true
    GitPushEnabled = $true
    CheckpointInterval = "Hourly"  # Per implementation plan hour
    Statistics = @{
        OperationsIntercepted = 0
        FilesArchived = 0
        GitCheckpoints = 0
        SafeAlternativesUsed = 0
    }
}

# Track implementation progress
$script:ImplementationTracking = @{
    CurrentPlan = $null
    CurrentPhase = $null
    LastCheckpoint = $null
    StartTime = $null
    CompletedSteps = @()
}
#endregion

#region Destructive Operation Patterns
$script:DestructivePatterns = @{
    # File deletion patterns
    "Remove-Item" = @{
        Pattern = 'Remove-Item\s+(.+?)(?:\s+-|$)'
        SafeAlternative = 'Archive-ItemSafely'
        Description = "Archive instead of delete"
    }
    "rm" = @{
        Pattern = '\brm\s+(.+?)(?:\s+-|$)'
        SafeAlternative = 'Archive-ItemSafely'
        Description = "Archive instead of delete"
    }
    "del" = @{
        Pattern = '\bdel\s+(.+?)(?:\s+/|$)'
        SafeAlternative = 'Archive-ItemSafely'
        Description = "Archive instead of delete"
    }
    "Clear-Content" = @{
        Pattern = 'Clear-Content\s+(.+?)(?:\s+-|$)'
        SafeAlternative = 'Backup-ThenClear'
        Description = "Backup before clearing"
    }
    
    # Directory operations
    "rmdir" = @{
        Pattern = '\brmdir\s+(.+?)(?:\s+/|$)'
        SafeAlternative = 'Archive-DirectorySafely'
        Description = "Archive directory instead of delete"
    }
    "Remove-Item -Recurse" = @{
        Pattern = 'Remove-Item\s+(.+?)\s+-Recurse'
        SafeAlternative = 'Archive-DirectoryTreeSafely'
        Description = "Archive entire tree instead of delete"
    }
    
    # Git operations
    "git reset --hard" = @{
        Pattern = 'git\s+reset\s+--hard'
        SafeAlternative = 'Create-GitBackupBranch'
        Description = "Create backup branch before hard reset"
    }
    "git clean" = @{
        Pattern = 'git\s+clean'
        SafeAlternative = 'Archive-UntrackedFiles'
        Description = "Archive untracked files before cleaning"
    }
    
    # Database/config operations
    "Set-Content" = @{
        Pattern = 'Set-Content\s+(.+?)(?:\s+-|$)'
        SafeAlternative = 'Backup-ThenSet'
        Description = "Backup before overwriting"
    }
    "Out-File" = @{
        Pattern = 'Out-File\s+(.+?)(?:\s+-|$)'
        SafeAlternative = 'Backup-ThenWrite'
        Description = "Backup before overwriting"
    }
}
#endregion

#region Public Functions

function Initialize-SafeOperations {
    <#
    .SYNOPSIS
        Initializes the safe operations handler
    #>
    [CmdletBinding()]
    param(
        [string]$ArchivePath = $script:SafeOpsConfig.ArchivePath,
        [string]$BackupPath = $script:SafeOpsConfig.BackupPath,
        [bool]$GitAutoCommit = $true,
        [bool]$GitPushEnabled = $true
    )
    
    # Create directories if needed
    foreach ($path in @($ArchivePath, $BackupPath)) {
        if (-not (Test-Path $path)) {
            New-Item -Path $path -ItemType Directory -Force | Out-Null
        }
    }
    
    # Update configuration
    $script:SafeOpsConfig.ArchivePath = $ArchivePath
    $script:SafeOpsConfig.BackupPath = $BackupPath
    $script:SafeOpsConfig.GitAutoCommit = $GitAutoCommit
    $script:SafeOpsConfig.GitPushEnabled = $GitPushEnabled
    $script:SafeOpsConfig.Enabled = $true
    
    Write-Host "[SafeOps] Initialized - All destructive operations will be converted to safe alternatives" -ForegroundColor Green
    Write-Host "[SafeOps] Archive Path: $ArchivePath" -ForegroundColor Cyan
    Write-Host "[SafeOps] Git Auto-Commit: $GitAutoCommit" -ForegroundColor Cyan
    
    return @{
        Success = $true
        Config = $script:SafeOpsConfig
    }
}

function Convert-ToSafeOperation {
    <#
    .SYNOPSIS
        Converts a destructive command to a safe alternative
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Command,
        
        [switch]$ExecuteImmediately
    )
    
    $safeCommand = $Command
    $converted = $false
    $explanation = @()
    
    foreach ($pattern in $script:DestructivePatterns.Keys) {
        $patternInfo = $script:DestructivePatterns[$pattern]
        
        if ($Command -match $patternInfo.Pattern) {
            $target = $Matches[1]
            $safeAlternative = $patternInfo.SafeAlternative
            
            # Build safe command
            switch ($safeAlternative) {
                'Archive-ItemSafely' {
                    $safeCommand = "Archive-ItemSafely -Path '$target'"
                    $explanation += "• Archiving '$target' instead of deleting"
                }
                'Archive-DirectorySafely' {
                    $safeCommand = "Archive-DirectorySafely -Path '$target'"
                    $explanation += "• Archiving directory '$target' instead of deleting"
                }
                'Archive-DirectoryTreeSafely' {
                    $safeCommand = "Archive-DirectoryTreeSafely -Path '$target'"
                    $explanation += "• Archiving directory tree '$target' instead of recursive delete"
                }
                'Backup-ThenClear' {
                    $safeCommand = "Backup-ThenClear -Path '$target'"
                    $explanation += "• Backing up '$target' before clearing content"
                }
                'Backup-ThenSet' {
                    $safeCommand = "Backup-ThenSet -Path '$target'"
                    $explanation += "• Backing up '$target' before overwriting"
                }
                'Backup-ThenWrite' {
                    $safeCommand = "Backup-ThenWrite -Path '$target'"
                    $explanation += "• Backing up '$target' before writing"
                }
                'Create-GitBackupBranch' {
                    $safeCommand = "Create-GitBackupBranch"
                    $explanation += "• Creating backup branch before hard reset"
                }
                'Archive-UntrackedFiles' {
                    $safeCommand = "Archive-UntrackedFiles"
                    $explanation += "• Archiving untracked files before git clean"
                }
            }
            
            $converted = $true
            $script:SafeOpsConfig.Statistics.OperationsIntercepted++
            break
        }
    }
    
    $result = @{
        OriginalCommand = $Command
        SafeCommand = $safeCommand
        WasConverted = $converted
        Explanation = $explanation -join "`n"
        Timestamp = Get-Date
    }
    
    if ($ExecuteImmediately -and $converted) {
        Write-Host "[SafeOps] Executing safe alternative..." -ForegroundColor Yellow
        try {
            Invoke-Expression $safeCommand
            $result.Executed = $true
            $script:SafeOpsConfig.Statistics.SafeAlternativesUsed++
        } catch {
            $result.Executed = $false
            $result.Error = $_.Exception.Message
        }
    }
    
    return $result
}

#endregion

#region Safe Alternative Implementations

function Archive-ItemSafely {
    <#
    .SYNOPSIS
        Archives a file instead of deleting it
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Path
    )
    
    if (-not (Test-Path $Path)) {
        Write-Warning "Path does not exist: $Path"
        return
    }
    
    $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
    $item = Get-Item $Path
    $archiveName = "$($item.BaseName)_$timestamp$($item.Extension)"
    $archivePath = Join-Path $script:SafeOpsConfig.ArchivePath $archiveName
    
    Write-Host "[SafeOps] Archiving '$Path' to '$archivePath'" -ForegroundColor Cyan
    Move-Item -Path $Path -Destination $archivePath -Force
    
    $script:SafeOpsConfig.Statistics.FilesArchived++
    
    # Log the operation
    $logEntry = @{
        Operation = "Archive"
        Original = $Path
        Archive = $archivePath
        Timestamp = Get-Date
    } | ConvertTo-Json -Compress
    
    Add-Content -Path (Join-Path $script:SafeOpsConfig.ArchivePath "archive_log.json") -Value $logEntry
    
    return @{
        Success = $true
        ArchivedTo = $archivePath
    }
}

function Archive-DirectorySafely {
    <#
    .SYNOPSIS
        Archives a directory instead of deleting it
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Path
    )
    
    if (-not (Test-Path $Path -PathType Container)) {
        Write-Warning "Directory does not exist: $Path"
        return
    }
    
    $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
    $dirName = Split-Path $Path -Leaf
    $archiveName = "${dirName}_$timestamp"
    $archivePath = Join-Path $script:SafeOpsConfig.ArchivePath $archiveName
    
    Write-Host "[SafeOps] Archiving directory '$Path' to '$archivePath'" -ForegroundColor Cyan
    Move-Item -Path $Path -Destination $archivePath -Force -Recurse
    
    $script:SafeOpsConfig.Statistics.FilesArchived++
    
    return @{
        Success = $true
        ArchivedTo = $archivePath
    }
}

function Archive-DirectoryTreeSafely {
    <#
    .SYNOPSIS
        Archives an entire directory tree instead of recursive delete
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Path
    )
    
    # Compress to save space for large trees
    $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
    $dirName = Split-Path $Path -Leaf
    $archiveName = "${dirName}_tree_$timestamp.zip"
    $archivePath = Join-Path $script:SafeOpsConfig.ArchivePath $archiveName
    
    Write-Host "[SafeOps] Compressing and archiving tree '$Path' to '$archivePath'" -ForegroundColor Cyan
    
    Compress-Archive -Path $Path -DestinationPath $archivePath -CompressionLevel Optimal
    Remove-Item -Path $Path -Recurse -Force
    
    $script:SafeOpsConfig.Statistics.FilesArchived++
    
    return @{
        Success = $true
        ArchivedTo = $archivePath
        Compressed = $true
    }
}

function Backup-ThenClear {
    <#
    .SYNOPSIS
        Backs up file content before clearing
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Path
    )
    
    if (-not (Test-Path $Path)) {
        Write-Warning "File does not exist: $Path"
        return
    }
    
    $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
    $fileName = Split-Path $Path -Leaf
    $backupName = "$($fileName).backup_$timestamp"
    $backupPath = Join-Path $script:SafeOpsConfig.BackupPath $backupName
    
    Write-Host "[SafeOps] Backing up '$Path' before clearing" -ForegroundColor Cyan
    Copy-Item -Path $Path -Destination $backupPath -Force
    Clear-Content -Path $Path
    
    return @{
        Success = $true
        BackupPath = $backupPath
    }
}

function Backup-ThenSet {
    <#
    .SYNOPSIS
        Backs up file before overwriting with Set-Content
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Path,
        
        [Parameter(Mandatory)]
        [string]$Value
    )
    
    if (Test-Path $Path) {
        $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
        $fileName = Split-Path $Path -Leaf
        $backupName = "$($fileName).backup_$timestamp"
        $backupPath = Join-Path $script:SafeOpsConfig.BackupPath $backupName
        
        Write-Host "[SafeOps] Backing up existing '$Path' before overwriting" -ForegroundColor Cyan
        Copy-Item -Path $Path -Destination $backupPath -Force
    }
    
    Set-Content -Path $Path -Value $Value
    
    return @{
        Success = $true
        BackupPath = if (Test-Path $backupPath) { $backupPath } else { $null }
    }
}

function Create-GitBackupBranch {
    <#
    .SYNOPSIS
        Creates a backup branch before destructive git operations
    #>
    [CmdletBinding()]
    param()
    
    $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
    $backupBranch = "backup/auto_$timestamp"
    
    Write-Host "[SafeOps] Creating backup branch: $backupBranch" -ForegroundColor Cyan
    
    git branch $backupBranch
    Write-Host "[SafeOps] Backup branch created. Original state preserved in: $backupBranch" -ForegroundColor Green
    
    return @{
        Success = $true
        BackupBranch = $backupBranch
    }
}

function Archive-UntrackedFiles {
    <#
    .SYNOPSIS
        Archives untracked files before git clean
    #>
    [CmdletBinding()]
    param()
    
    $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
    $archivePath = Join-Path $script:SafeOpsConfig.ArchivePath "untracked_$timestamp"
    
    Write-Host "[SafeOps] Archiving untracked files to: $archivePath" -ForegroundColor Cyan
    
    New-Item -Path $archivePath -ItemType Directory -Force | Out-Null
    
    $untrackedFiles = git ls-files --others --exclude-standard
    foreach ($file in $untrackedFiles) {
        if (Test-Path $file) {
            $destPath = Join-Path $archivePath $file
            $destDir = Split-Path $destPath -Parent
            if (-not (Test-Path $destDir)) {
                New-Item -Path $destDir -ItemType Directory -Force | Out-Null
            }
            Copy-Item -Path $file -Destination $destPath -Force
        }
    }
    
    Write-Host "[SafeOps] Archived $($untrackedFiles.Count) untracked files" -ForegroundColor Green
    
    return @{
        Success = $true
        ArchivePath = $archivePath
        FileCount = $untrackedFiles.Count
    }
}

#endregion

#region Git Checkpoint Functions

function Start-ImplementationPlan {
    <#
    .SYNOPSIS
        Starts tracking an implementation plan with automatic git checkpoints
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$PlanName,
        
        [string]$PlanFile,
        [string]$InitialPhase = "Hour 1"
    )
    
    $script:ImplementationTracking = @{
        CurrentPlan = $PlanName
        CurrentPhase = $InitialPhase
        LastCheckpoint = Get-Date
        StartTime = Get-Date
        CompletedSteps = @()
        PlanFile = $PlanFile
    }
    
    Write-Host "[SafeOps] Starting implementation plan: $PlanName" -ForegroundColor Green
    Write-Host "[SafeOps] Git checkpoints will be created after each major phase" -ForegroundColor Cyan
    
    # Create initial checkpoint
    if ($script:SafeOpsConfig.GitAutoCommit) {
        New-GitCheckpoint -Message "Starting implementation: $PlanName - $InitialPhase"
    }
    
    return @{
        Success = $true
        Plan = $PlanName
        StartTime = $script:ImplementationTracking.StartTime
    }
}

function Complete-ImplementationPhase {
    <#
    .SYNOPSIS
        Marks a phase complete and creates a git checkpoint
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$PhaseName,
        
        [string]$Summary,
        [switch]$Push
    )
    
    if (-not $script:ImplementationTracking.CurrentPlan) {
        Write-Warning "No active implementation plan. Use Start-ImplementationPlan first."
        return
    }
    
    # Add to completed steps
    $script:ImplementationTracking.CompletedSteps += @{
        Phase = $PhaseName
        CompletedAt = Get-Date
        Summary = $Summary
        Duration = (Get-Date) - $script:ImplementationTracking.LastCheckpoint
    }
    
    Write-Host "[SafeOps] Completing phase: $PhaseName" -ForegroundColor Green
    
    # Create git checkpoint
    if ($script:SafeOpsConfig.GitAutoCommit) {
        $commitMessage = "✅ Completed: $($script:ImplementationTracking.CurrentPlan) - $PhaseName"
        if ($Summary) {
            $commitMessage += "`n`n$Summary"
        }
        
        New-GitCheckpoint -Message $commitMessage -Push:$Push
    }
    
    # Update tracking
    $script:ImplementationTracking.CurrentPhase = $PhaseName
    $script:ImplementationTracking.LastCheckpoint = Get-Date
    
    return @{
        Success = $true
        Phase = $PhaseName
        CheckpointCreated = $script:SafeOpsConfig.GitAutoCommit
        TotalCompleted = $script:ImplementationTracking.CompletedSteps.Count
    }
}

function New-GitCheckpoint {
    <#
    .SYNOPSIS
        Creates a git checkpoint (add, commit, optionally push)
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Message,
        
        [switch]$Push,
        [string[]]$FilesToAdd = @(".")
    )
    
    try {
        Write-Host "[SafeOps] Creating git checkpoint..." -ForegroundColor Cyan
        
        # Stage changes
        foreach ($file in $FilesToAdd) {
            git add $file 2>&1 | Out-Null
        }
        
        # Check if there are changes to commit
        $status = git status --porcelain
        if ($status) {
            # Commit with detailed message
            $fullMessage = "$Message`n`n🤖 Automated checkpoint by SafeOperationsHandler`nTimestamp: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
            
            git commit -m $fullMessage 2>&1 | Out-Null
            Write-Host "[SafeOps] ✅ Checkpoint committed: $Message" -ForegroundColor Green
            
            $script:SafeOpsConfig.Statistics.GitCheckpoints++
            
            # Push if requested and enabled
            if ($Push -and $script:SafeOpsConfig.GitPushEnabled) {
                Write-Host "[SafeOps] Pushing to remote..." -ForegroundColor Cyan
                git push 2>&1 | Out-Null
                Write-Host "[SafeOps] ✅ Pushed to remote repository" -ForegroundColor Green
            }
        } else {
            Write-Host "[SafeOps] No changes to checkpoint" -ForegroundColor Yellow
        }
        
        return @{
            Success = $true
            Message = $Message
            Pushed = $Push -and $script:SafeOpsConfig.GitPushEnabled
        }
    } catch {
        Write-Warning "[SafeOps] Failed to create checkpoint: $_"
        return @{
            Success = $false
            Error = $_.Exception.Message
        }
    }
}

function Enable-AutoCheckpoints {
    <#
    .SYNOPSIS
        Enables automatic checkpointing at specified intervals
    #>
    [CmdletBinding()]
    param(
        [ValidateSet("Hourly", "Every30Min", "Every15Min", "AfterEachStep")]
        [string]$Interval = "Hourly"
    )
    
    $script:SafeOpsConfig.CheckpointInterval = $Interval
    $script:SafeOpsConfig.GitAutoCommit = $true
    
    Write-Host "[SafeOps] Auto-checkpointing enabled: $Interval" -ForegroundColor Green
    
    # Start background job for periodic checkpoints
    $scriptBlock = {
        param($Interval)
        
        $intervalMinutes = switch ($Interval) {
            "Hourly" { 60 }
            "Every30Min" { 30 }
            "Every15Min" { 15 }
            "AfterEachStep" { 5 }  # Check every 5 min for step completion
        }
        
        while ($true) {
            Start-Sleep -Seconds ($intervalMinutes * 60)
            
            # Check if there are changes
            $status = git status --porcelain
            if ($status) {
                $message = "⏰ Automated checkpoint - $Interval interval"
                git add .
                git commit -m $message
                Write-Host "[AutoCheckpoint] Created scheduled checkpoint" -ForegroundColor Cyan
            }
        }
    }
    
    $job = Start-Job -ScriptBlock $scriptBlock -ArgumentList $Interval
    
    return @{
        Success = $true
        Interval = $Interval
        JobId = $job.Id
    }
}

#endregion

#region Statistics and Reporting

function Get-SafeOperationStats {
    <#
    .SYNOPSIS
        Gets statistics about safe operations
    #>
    [CmdletBinding()]
    param()
    
    $stats = $script:SafeOpsConfig.Statistics
    
    if ($script:ImplementationTracking.CurrentPlan) {
        $stats.ActivePlan = $script:ImplementationTracking.CurrentPlan
        $stats.CurrentPhase = $script:ImplementationTracking.CurrentPhase
        $stats.CompletedPhases = $script:ImplementationTracking.CompletedSteps.Count
        $stats.Duration = (Get-Date) - $script:ImplementationTracking.StartTime
    }
    
    return $stats
}

function Show-SafeOperationsSummary {
    <#
    .SYNOPSIS
        Displays a summary of safe operations
    #>
    [CmdletBinding()]
    param()
    
    $stats = Get-SafeOperationStats
    
    Write-Host "`n" + ("=" * 60) -ForegroundColor Cyan
    Write-Host "SAFE OPERATIONS SUMMARY" -ForegroundColor Green
    Write-Host ("=" * 60) -ForegroundColor Cyan
    
    Write-Host "`nProtection Statistics:" -ForegroundColor Yellow
    Write-Host "  Operations Intercepted: $($stats.OperationsIntercepted)" -ForegroundColor White
    Write-Host "  Files Archived: $($stats.FilesArchived)" -ForegroundColor White
    Write-Host "  Safe Alternatives Used: $($stats.SafeAlternativesUsed)" -ForegroundColor White
    Write-Host "  Git Checkpoints: $($stats.GitCheckpoints)" -ForegroundColor White
    
    if ($stats.ActivePlan) {
        Write-Host "`nActive Implementation:" -ForegroundColor Yellow
        Write-Host "  Plan: $($stats.ActivePlan)" -ForegroundColor White
        Write-Host "  Current Phase: $($stats.CurrentPhase)" -ForegroundColor White
        Write-Host "  Completed Phases: $($stats.CompletedPhases)" -ForegroundColor White
        Write-Host "  Duration: $($stats.Duration.ToString('hh\:mm\:ss'))" -ForegroundColor White
    }
    
    Write-Host "`nConfiguration:" -ForegroundColor Yellow
    Write-Host "  Archive Path: $($script:SafeOpsConfig.ArchivePath)" -ForegroundColor White
    Write-Host "  Auto Git Commit: $($script:SafeOpsConfig.GitAutoCommit)" -ForegroundColor White
    Write-Host "  Git Push Enabled: $($script:SafeOpsConfig.GitPushEnabled)" -ForegroundColor White
    Write-Host ("=" * 60) -ForegroundColor Cyan
}

#endregion

# Export module members
Export-ModuleMember -Function @(
    'Initialize-SafeOperations',
    'Convert-ToSafeOperation',
    'Archive-ItemSafely',
    'Archive-DirectorySafely',
    'Archive-DirectoryTreeSafely',
    'Backup-ThenClear',
    'Backup-ThenSet',
    'Create-GitBackupBranch',
    'Archive-UntrackedFiles',
    'Start-ImplementationPlan',
    'Complete-ImplementationPhase',
    'New-GitCheckpoint',
    'Enable-AutoCheckpoints',
    'Get-SafeOperationStats',
    'Show-SafeOperationsSummary'
)