# Unity-Claude-SessionManager.psm1
# Enhanced conversation session management for Day 14 Integration Testing
# Extends ConversationStateManager with advanced persistence, recovery, and analytics
# Date: 2025-08-18 | Day 14: Complete Feedback Loop Integration

#region Module Configuration and Dependencies

$ErrorActionPreference = "Stop"

Write-Host "[SessionManager] Loading enhanced session management module..." -ForegroundColor Cyan

# Load ConversationStateManager if available
$conversationStatePath = Join-Path $PSScriptRoot "Unity-Claude-AutonomousAgent\ConversationStateManager.psm1"
if (Test-Path $conversationStatePath) {
    Import-Module $conversationStatePath -Force -DisableNameChecking
    Write-Host "[SessionManager] ConversationStateManager imported" -ForegroundColor Green
} else {
    Write-Host "[SessionManager] ConversationStateManager not found, using built-in functionality" -ForegroundColor Yellow
}

# Session configuration
$script:SessionConfig = @{
    # Storage paths
    SessionDataPath = Join-Path $PSScriptRoot "..\SessionData\Sessions"
    ArchivePath = Join-Path $PSScriptRoot "..\SessionData\Archive"
    BackupPath = Join-Path $PSScriptRoot "..\SessionData\Backups"
    
    # Session settings
    MaxSessionHistoryItems = 100
    MaxSessionDurationHours = 24
    AutoArchiveAfterHours = 48
    BackupIntervalMinutes = 15
    
    # Conversation settings
    ContextSummaryThreshold = 50  # Items before summarization
    ContextRetentionSize = 20     # Items to keep after summarization
    MaxConversationBranches = 5   # Parallel conversation tracking
    
    # Performance settings
    CompressionEnabled = $true
    AnalyticsEnabled = $true
    MetricsCollectionInterval = 60  # seconds
    
    # Logging
    VerboseLogging = $true
    LogFile = "session_manager.log"
}

# Ensure directories exist
foreach ($path in @($script:SessionConfig.SessionDataPath, $script:SessionConfig.ArchivePath, $script:SessionConfig.BackupPath)) {
    if (-not (Test-Path $path)) {
        New-Item -Path $path -ItemType Directory -Force | Out-Null
    }
}

#endregion

#region Logging and Utilities

function Write-SessionLog {
    param(
        [string]$Message,
        [ValidateSet("INFO", "WARNING", "ERROR", "DEBUG")]
        [string]$Level = "INFO",
        [string]$SessionId = "SYSTEM"
    )
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss.fff"
    $logEntry = "[$timestamp] [$Level] [Session:$SessionId] $Message"
    
    # Console output with colors
    $color = switch ($Level) {
        "INFO" { "White" }
        "WARNING" { "Yellow" }
        "ERROR" { "Red" }
        "DEBUG" { "Gray" }
    }
    
    if ($Level -ne "DEBUG" -or $script:SessionConfig.VerboseLogging) {
        Write-Host $logEntry -ForegroundColor $color
    }
    
    # File logging
    $logFile = Join-Path (Split-Path $script:SessionConfig.SessionDataPath -Parent) $script:SessionConfig.LogFile
    try {
        Add-Content -Path $logFile -Value $logEntry -Encoding UTF8
    } catch {
        Write-Warning "Failed to write to session log: $($_.Exception.Message)"
    }
}

function New-SessionId {
    return [System.Guid]::NewGuid().ToString("N").Substring(0, 16)
}

function Get-SessionTimestamp {
    return Get-Date -Format "yyyy-MM-dd HH:mm:ss.fff"
}

#endregion

#region Enhanced Session Management

function New-ConversationSession {
    param(
        [string]$SessionName = "AutoSession",
        [string]$InitiatedBy = "Integration Engine",
        [hashtable]$InitialContext = @{},
        [string]$SessionType = "Autonomous",
        [hashtable]$Configuration = @{}
    )
    
    $sessionId = New-SessionId
    Write-SessionLog "Creating new conversation session: $SessionName" -Level "INFO" -SessionId $sessionId
    
    $session = @{
        # Session Identity
        SessionId = $sessionId
        SessionName = $SessionName
        SessionType = $SessionType
        InitiatedBy = $InitiatedBy
        
        # Timestamps
        StartTime = Get-SessionTimestamp
        LastActivity = Get-SessionTimestamp
        LastBackup = Get-SessionTimestamp
        EndTime = $null
        
        # Status tracking
        Status = "Active"
        Phase = "Initializing"
        IsActive = $true
        
        # Conversation data
        ConversationHistory = @()
        ConversationBranches = @{}
        CurrentBranch = "main"
        ContextSummary = ""
        
        # Performance metrics
        Metrics = @{
            TotalCycles = 0
            SuccessfulCycles = 0
            FailedCycles = 0
            AverageResponseTime = 0
            TotalProcessingTime = 0
            LastCycleTime = 0
            TokensUsed = 0
            ErrorCount = 0
        }
        
        # Configuration
        Configuration = $script:SessionConfig + $Configuration
        InitialContext = $InitialContext
        
        # State management
        LastKnownState = "Idle"
        StateHistory = @()
        
        # Recovery information
        RecoveryPoints = @()
        LastCheckpoint = $null
        
        # Analytics
        Analytics = @{
            ConversationPatterns = @{}
            SuccessPatterns = @{}
            ErrorPatterns = @{}
            PerformanceTrends = @()
        }
    }
    
    # Save session
    $sessionResult = Save-ConversationSession -Session $session
    if ($sessionResult.Success) {
        Write-SessionLog "Session created and saved successfully" -Level "INFO" -SessionId $sessionId
        return @{ Success = $true; Session = $session }
    } else {
        Write-SessionLog "Failed to save new session: $($sessionResult.Error)" -Level "ERROR" -SessionId $sessionId
        return @{ Success = $false; Error = $sessionResult.Error }
    }
}

function Get-ConversationSession {
    param(
        [string]$SessionId
    )
    
    if (-not $SessionId) {
        Write-SessionLog "SessionId is required" -Level "ERROR"
        return @{ Success = $false; Error = "SessionId is required" }
    }
    
    $sessionFile = Join-Path $script:SessionConfig.SessionDataPath "$SessionId.json"
    
    if (-not (Test-Path $sessionFile)) {
        Write-SessionLog "Session file not found: $sessionFile" -Level "WARNING" -SessionId $SessionId
        return @{ Success = $false; Error = "Session not found" }
    }
    
    try {
        $sessionJson = Get-Content -Path $sessionFile -Raw
        $session = $sessionJson | ConvertFrom-Json
        
        # Convert PSCustomObject to hashtable for easier manipulation
        $sessionHash = @{}
        $session.PSObject.Properties | ForEach-Object { $sessionHash[$_.Name] = $_.Value }
        
        Write-SessionLog "Session loaded successfully" -Level "INFO" -SessionId $SessionId
        return @{ Success = $true; Session = $sessionHash }
    } catch {
        Write-SessionLog "Failed to load session: $($_.Exception.Message)" -Level "ERROR" -SessionId $SessionId
        return @{ Success = $false; Error = $_.ToString() }
    }
}

function Save-ConversationSession {
    param(
        [hashtable]$Session,
        [switch]$CreateBackup
    )
    
    $sessionId = $Session.SessionId
    
    try {
        # Update timestamps
        $Session.LastActivity = Get-SessionTimestamp
        
        # Create backup if requested or if it's time for scheduled backup
        if ($CreateBackup -or (Should-CreateBackup -Session $Session)) {
            $backupResult = New-SessionBackup -Session $Session
            if ($backupResult.Success) {
                $Session.LastBackup = Get-SessionTimestamp
            }
        }
        
        # Save main session file
        $sessionFile = Join-Path $script:SessionConfig.SessionDataPath "$sessionId.json"
        $Session | ConvertTo-Json -Depth 20 | Set-Content -Path $sessionFile -Encoding UTF8
        
        Write-SessionLog "Session saved successfully" -Level "DEBUG" -SessionId $sessionId
        return @{ Success = $true }
    } catch {
        Write-SessionLog "Failed to save session: $($_.Exception.Message)" -Level "ERROR" -SessionId $sessionId
        return @{ Success = $false; Error = $_.ToString() }
    }
}

function Update-ConversationSession {
    param(
        [string]$SessionId,
        [hashtable]$Updates
    )
    
    $sessionResult = Get-ConversationSession -SessionId $SessionId
    if (-not $sessionResult.Success) {
        return $sessionResult
    }
    
    $session = $sessionResult.Session
    
    # Apply updates
    foreach ($update in $Updates.GetEnumerator()) {
        $session[$update.Key] = $update.Value
    }
    
    # Save updated session
    return Save-ConversationSession -Session $session
}

#endregion

#region Conversation History Management

function Add-ConversationHistoryEntry {
    param(
        [string]$SessionId,
        [string]$Type,  # "UserInput", "ClaudeResponse", "SystemAction", "Error"
        [string]$Content,
        [hashtable]$Metadata = @{},
        [string]$Branch = "main"
    )
    
    $sessionResult = Get-ConversationSession -SessionId $SessionId
    if (-not $sessionResult.Success) {
        return $sessionResult
    }
    
    $session = $sessionResult.Session
    
    $historyEntry = @{
        EntryId = (New-Guid).ToString("N").Substring(0, 8)
        Timestamp = Get-SessionTimestamp
        Type = $Type
        Content = $Content
        Metadata = $Metadata
        Branch = $Branch
        Sequence = $session.ConversationHistory.Count + 1
    }
    
    # Add to conversation history
    $session.ConversationHistory += $historyEntry
    
    # Add to specific branch if not main
    if ($Branch -ne "main") {
        if (-not $session.ConversationBranches.ContainsKey($Branch)) {
            $session.ConversationBranches[$Branch] = @()
        }
        $session.ConversationBranches[$Branch] += $historyEntry
    }
    
    # Check if summarization is needed
    if ($session.ConversationHistory.Count -gt $script:SessionConfig.ContextSummaryThreshold) {
        $summarizationResult = Invoke-ConversationSummarization -Session $session
        if ($summarizationResult.Success) {
            $session = $summarizationResult.Session
        }
    }
    
    Write-SessionLog "Added conversation history entry: $Type" -Level "DEBUG" -SessionId $SessionId
    
    # Save updated session
    $saveResult = Save-ConversationSession -Session $session
    if ($saveResult.Success) {
        return @{ Success = $true; Entry = $historyEntry }
    } else {
        return $saveResult
    }
}

function Get-ConversationHistoryForContext {
    param(
        [string]$SessionId,
        [int]$MaxItems = 20,
        [string]$Branch = "main",
        [switch]$IncludeSummary
    )
    
    $sessionResult = Get-ConversationSession -SessionId $SessionId
    if (-not $sessionResult.Success) {
        return $sessionResult
    }
    
    $session = $sessionResult.Session
    
    # Get conversation history
    $history = if ($Branch -eq "main") {
        $session.ConversationHistory
    } else {
        $session.ConversationBranches[$Branch]
    }
    
    if (-not $history) {
        $history = @()
    }
    
    # Get most recent items
    $recentHistory = $history | Select-Object -Last $MaxItems
    
    # Include summary if requested and available
    $context = @{
        History = $recentHistory
        TotalEntries = $history.Count
        Branch = $Branch
    }
    
    if ($IncludeSummary -and $session.ContextSummary) {
        $context.Summary = $session.ContextSummary
    }
    
    return @{ Success = $true; Context = $context }
}

function Invoke-ConversationSummarization {
    param(
        [hashtable]$Session
    )
    
    try {
        $history = $Session.ConversationHistory
        $retentionSize = $script:SessionConfig.ContextRetentionSize
        
        # Keep recent items
        $recentItems = $history | Select-Object -Last $retentionSize
        
        # Create summary of older items
        $olderItems = $history | Select-Object -SkipLast $retentionSize
        
        if ($olderItems.Count -gt 0) {
            $summary = "Previous conversation summary ($($olderItems.Count) items): "
            
            # Categorize and count different types
            $typeGroups = $olderItems | Group-Object -Property Type
            $summaryParts = @()
            
            foreach ($group in $typeGroups) {
                $summaryParts += "$($group.Count) $($group.Name.ToLower()) items"
            }
            
            $summary += $summaryParts -join ", "
            
            # Add key topics if available
            $keyContent = $olderItems | Where-Object { $_.Type -in @("UserInput", "ClaudeResponse") } | 
                          Select-Object -ExpandProperty Content | 
                          ForEach-Object { $_.Substring(0, [Math]::Min(100, $_.Length)) }
            
            if ($keyContent) {
                $summary += ". Key topics: " + (($keyContent | Select-Object -First 3) -join "; ")
            }
            
            $Session.ContextSummary = $summary
        }
        
        # Update conversation history to keep only recent items
        $Session.ConversationHistory = $recentItems
        
        Write-SessionLog "Conversation summarized: kept $($recentItems.Count) recent items, summarized $($olderItems.Count) older items" -Level "INFO" -SessionId $Session.SessionId
        
        return @{ Success = $true; Session = $Session }
    } catch {
        Write-SessionLog "Failed to summarize conversation: $($_.Exception.Message)" -Level "ERROR" -SessionId $Session.SessionId
        return @{ Success = $false; Error = $_.ToString() }
    }
}

#endregion

#region Session Recovery and Checkpoints

function New-SessionCheckpoint {
    param(
        [string]$SessionId,
        [string]$CheckpointName = "Auto",
        [hashtable]$CheckpointData = @{}
    )
    
    $sessionResult = Get-ConversationSession -SessionId $SessionId
    if (-not $sessionResult.Success) {
        return $sessionResult
    }
    
    $session = $sessionResult.Session
    
    $checkpoint = @{
        CheckpointId = (New-Guid).ToString("N").Substring(0, 8)
        Name = $CheckpointName
        Timestamp = Get-SessionTimestamp
        SessionState = $session.Clone()
        CheckpointData = $CheckpointData
        RecoveryInstructions = @{
            RestoreSession = $true
            RestoreHistory = $true
            RestoreMetrics = $true
        }
    }
    
    # Add to recovery points
    $session.RecoveryPoints += $checkpoint
    $session.LastCheckpoint = $checkpoint.CheckpointId
    
    # Limit recovery points to prevent bloat
    if ($session.RecoveryPoints.Count -gt 10) {
        $session.RecoveryPoints = $session.RecoveryPoints | Select-Object -Last 10
    }
    
    Write-SessionLog "Created checkpoint: $CheckpointName" -Level "INFO" -SessionId $SessionId
    
    $saveResult = Save-ConversationSession -Session $session
    if ($saveResult.Success) {
        return @{ Success = $true; Checkpoint = $checkpoint }
    } else {
        return $saveResult
    }
}

function Restore-SessionFromCheckpoint {
    param(
        [string]$SessionId,
        [string]$CheckpointId = $null
    )
    
    $sessionResult = Get-ConversationSession -SessionId $SessionId
    if (-not $sessionResult.Success) {
        return $sessionResult
    }
    
    $session = $sessionResult.Session
    
    # Find checkpoint
    $checkpoint = if ($CheckpointId) {
        $session.RecoveryPoints | Where-Object { $_.CheckpointId -eq $CheckpointId }
    } else {
        $session.RecoveryPoints | Select-Object -Last 1  # Most recent
    }
    
    if (-not $checkpoint) {
        Write-SessionLog "Checkpoint not found" -Level "ERROR" -SessionId $SessionId
        return @{ Success = $false; Error = "Checkpoint not found" }
    }
    
    try {
        # Restore session state
        $restoredSession = $checkpoint.SessionState.Clone()
        $restoredSession.SessionId = $SessionId  # Maintain session ID
        $restoredSession.LastActivity = Get-SessionTimestamp
        
        # Save restored session
        $saveResult = Save-ConversationSession -Session $restoredSession
        if ($saveResult.Success) {
            Write-SessionLog "Session restored from checkpoint: $($checkpoint.Name)" -Level "INFO" -SessionId $SessionId
            return @{ Success = $true; Session = $restoredSession; Checkpoint = $checkpoint }
        } else {
            return $saveResult
        }
    } catch {
        Write-SessionLog "Failed to restore from checkpoint: $($_.Exception.Message)" -Level "ERROR" -SessionId $SessionId
        return @{ Success = $false; Error = $_.ToString() }
    }
}

function Resume-ConversationSession {
    param(
        [string]$SessionId,
        [hashtable]$ResumeContext = @{}
    )
    
    $sessionResult = Get-ConversationSession -SessionId $SessionId
    if (-not $sessionResult.Success) {
        return $sessionResult
    }
    
    $session = $sessionResult.Session
    
    # Check if session can be resumed
    if ($session.Status -in @("Completed", "Archived")) {
        Write-SessionLog "Cannot resume completed or archived session" -Level "WARNING" -SessionId $SessionId
        return @{ Success = $false; Error = "Session cannot be resumed" }
    }
    
    # Update session for resumption
    $updates = @{
        Status = "Active"
        IsActive = $true
        LastActivity = Get-SessionTimestamp
        Phase = "Resuming"
    }
    
    # Add resume context if provided
    if ($ResumeContext.Count -gt 0) {
        $historyResult = Add-ConversationHistoryEntry -SessionId $SessionId -Type "SystemAction" -Content "Session resumed" -Metadata $ResumeContext
        if (-not $historyResult.Success) {
            Write-SessionLog "Failed to add resume history entry: $($historyResult.Error)" -Level "WARNING" -SessionId $SessionId
        }
    }
    
    $updateResult = Update-ConversationSession -SessionId $SessionId -Updates $updates
    if ($updateResult.Success) {
        Write-SessionLog "Session resumed successfully" -Level "INFO" -SessionId $SessionId
        return @{ Success = $true; SessionId = $SessionId }
    } else {
        return $updateResult
    }
}

#endregion

#region Session Analytics and Metrics

function Update-SessionMetrics {
    param(
        [string]$SessionId,
        [hashtable]$MetricUpdates
    )
    
    $sessionResult = Get-ConversationSession -SessionId $SessionId
    if (-not $sessionResult.Success) {
        return $sessionResult
    }
    
    $session = $sessionResult.Session
    
    # Update metrics
    foreach ($metric in $MetricUpdates.GetEnumerator()) {
        $session.Metrics[$metric.Key] = $metric.Value
    }
    
    # Calculate derived metrics
    if ($session.Metrics.TotalCycles -gt 0) {
        $session.Metrics.SuccessRate = ($session.Metrics.SuccessfulCycles / $session.Metrics.TotalCycles) * 100
    }
    
    # Save updated session
    return Save-ConversationSession -Session $session
}

function Get-SessionAnalytics {
    param(
        [string]$SessionId
    )
    
    $sessionResult = Get-ConversationSession -SessionId $SessionId
    if (-not $sessionResult.Success) {
        return $sessionResult
    }
    
    $session = $sessionResult.Session
    
    $analytics = @{
        SessionInfo = @{
            SessionId = $session.SessionId
            SessionName = $session.SessionName
            Duration = if ($session.EndTime) {
                ((Get-Date $session.EndTime) - (Get-Date $session.StartTime)).TotalMinutes
            } else {
                ((Get-Date) - (Get-Date $session.StartTime)).TotalMinutes
            }
            Status = $session.Status
        }
        
        Performance = @{
            TotalCycles = $session.Metrics.TotalCycles
            SuccessfulCycles = $session.Metrics.SuccessfulCycles
            FailedCycles = $session.Metrics.FailedCycles
            SuccessRate = $session.Metrics.SuccessRate
            AverageResponseTime = $session.Metrics.AverageResponseTime
            TotalProcessingTime = $session.Metrics.TotalProcessingTime
        }
        
        Conversation = @{
            TotalHistoryItems = $session.ConversationHistory.Count
            HasSummary = [bool]$session.ContextSummary
            BranchCount = $session.ConversationBranches.Keys.Count
            CurrentBranch = $session.CurrentBranch
        }
        
        Recovery = @{
            CheckpointCount = $session.RecoveryPoints.Count
            LastCheckpoint = $session.LastCheckpoint
            LastBackup = $session.LastBackup
        }
    }
    
    return @{ Success = $true; Analytics = $analytics }
}

#endregion

#region Backup and Archive Management

function Should-CreateBackup {
    param([hashtable]$Session)
    
    if (-not $Session.LastBackup) { return $true }
    
    $lastBackup = Get-Date $Session.LastBackup
    $backupInterval = [TimeSpan]::FromMinutes($script:SessionConfig.BackupIntervalMinutes)
    
    return ((Get-Date) - $lastBackup) -gt $backupInterval
}

function New-SessionBackup {
    param([hashtable]$Session)
    
    try {
        $sessionId = $Session.SessionId
        $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
        $backupFile = Join-Path $script:SessionConfig.BackupPath "$sessionId`_$timestamp.json"
        
        $Session | ConvertTo-Json -Depth 20 | Set-Content -Path $backupFile -Encoding UTF8
        
        Write-SessionLog "Backup created: $backupFile" -Level "DEBUG" -SessionId $sessionId
        return @{ Success = $true; BackupFile = $backupFile }
    } catch {
        Write-SessionLog "Failed to create backup: $($_.Exception.Message)" -Level "ERROR" -SessionId $Session.SessionId
        return @{ Success = $false; Error = $_.ToString() }
    }
}

function Complete-ConversationSession {
    param(
        [string]$SessionId,
        [string]$CompletionReason = "Manual completion",
        [switch]$Archive
    )
    
    $sessionResult = Get-ConversationSession -SessionId $SessionId
    if (-not $sessionResult.Success) {
        return $sessionResult
    }
    
    $session = $sessionResult.Session
    
    # Update session for completion
    $session.EndTime = Get-SessionTimestamp
    $session.Status = "Completed"
    $session.IsActive = $false
    
    # Add completion entry to history
    $historyResult = Add-ConversationHistoryEntry -SessionId $SessionId -Type "SystemAction" -Content "Session completed: $CompletionReason"
    
    # Create final backup
    $backupResult = New-SessionBackup -Session $session
    
    # Save completed session
    $saveResult = Save-ConversationSession -Session $session
    
    if ($Archive) {
        # Archive session
        $archiveFile = Join-Path $script:SessionConfig.ArchivePath "$SessionId.json"
        Copy-Item -Path (Join-Path $script:SessionConfig.SessionDataPath "$SessionId.json") -Destination $archiveFile
        
        # Remove from active sessions
        Remove-Item -Path (Join-Path $script:SessionConfig.SessionDataPath "$SessionId.json") -Force
        
        Write-SessionLog "Session completed and archived" -Level "INFO" -SessionId $SessionId
    } else {
        Write-SessionLog "Session completed" -Level "INFO" -SessionId $SessionId
    }
    
    return @{ Success = $true; SessionId = $SessionId; Archived = $Archive.IsPresent }
}

#endregion

#region Module Exports

Export-ModuleMember -Function @(
    # Session management
    'New-ConversationSession',
    'Get-ConversationSession',
    'Save-ConversationSession',
    'Update-ConversationSession',
    'Complete-ConversationSession',
    
    # Conversation history
    'Add-ConversationHistoryEntry',
    'Get-ConversationHistoryForContext',
    'Invoke-ConversationSummarization',
    
    # Recovery and checkpoints
    'New-SessionCheckpoint',
    'Restore-SessionFromCheckpoint',
    'Resume-ConversationSession',
    
    # Analytics and metrics
    'Update-SessionMetrics',
    'Get-SessionAnalytics',
    
    # Backup and archive
    'New-SessionBackup',
    
    # Utilities
    'Write-SessionLog'
)

#endregion

Write-Host "[SessionManager] Enhanced session management module loaded successfully" -ForegroundColor Green
# SIG # Begin signature block
# MIIFqQYJKoZIhvcNAQcCoIIFmjCCBZYCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUg9tByY3vDWmiWygGugfFlycx
# m7qgggMwMIIDLDCCAhSgAwIBAgIQdR0W2SKoK5VE8JId4ZxrRTANBgkqhkiG9w0B
# AQsFADAuMSwwKgYDVQQDDCNVbml0eS1DbGF1ZGUtQXV0b21hdGlvbi1EZXZlbG9w
# bWVudDAeFw0yNTA4MjAyMTE1MTdaFw0yNjA4MjAyMTM1MTdaMC4xLDAqBgNVBAMM
# I1VuaXR5LUNsYXVkZS1BdXRvbWF0aW9uLURldmVsb3BtZW50MIIBIjANBgkqhkiG
# 9w0BAQEFAAOCAQ8AMIIBCgKCAQEAseH3qinVEOhrn2OLpjc5TNT4vGh1BkfB5X4S
# FhY7K0QMQsYYnkZVmx3tB8PqVQXl++l+e3uT7uCscc7vjMTK8tDSWH98ji0U34WL
# JBwXC62l1ArazMKp4Tyr7peksei7vL4pZOtOVgAyTYn5d1hbnsVQmCSTPRtpn7mC
# Azfq2ec5qZ9Kgl7puPW5utvYfh8idtOWa5/WgYSKwOIvyZawIdZKLFpwqOtqbJe4
# sWzVahasFhLfoAKkniKOAocJDkJexh5pO/EOSKEZ3mOCU1ZSs4XWRGISRhV3qGZp
# f+Y3JlHKMeFDWKynaJBO8/GU5sqMATlDUvrByBtU2OQ2Um/L3QIDAQABo0YwRDAO
# BgNVHQ8BAf8EBAMCB4AwEwYDVR0lBAwwCgYIKwYBBQUHAwMwHQYDVR0OBBYEFHw5
# rOy6xlW6B45sJUsiI2A/yS0MMA0GCSqGSIb3DQEBCwUAA4IBAQAUTLH0+w8ysvmh
# YuBw4NDKcZm40MTh9Zc1M2p2hAkYsgNLJ+/rAP+I74rNfqguTYwxpCyjkwrg8yF5
# wViwggboLpF2yDu4N/dgDainR4wR8NVpS7zFZOFkpmNPepc6bw3d4yQKa/wJXKeC
# pkRjS50N77/hfVI+fFKNao7POb7en5fcXuZaN6xWoTRy+J4I4MhfHpjZuxSLSXjb
# VXtPD4RZ9HGjl9BU8162cRhjujr/Lc3/dY/6ikHQYnxuxcdxRew4nzaqAQaOeWu6
# tGp899JPKfldM5Zay5IBl3zs15gNS9+0Jrd0ARQnSVYoI0DLh3KybFnfK4POezoN
# Lp/dbX2SMYIB4zCCAd8CAQEwQjAuMSwwKgYDVQQDDCNVbml0eS1DbGF1ZGUtQXV0
# b21hdGlvbi1EZXZlbG9wbWVudAIQdR0W2SKoK5VE8JId4ZxrRTAJBgUrDgMCGgUA
# oHgwGAYKKwYBBAGCNwIBDDEKMAigAoAAoQKAADAZBgkqhkiG9w0BCQMxDAYKKwYB
# BAGCNwIBBDAcBgorBgEEAYI3AgELMQ4wDAYKKwYBBAGCNwIBFTAjBgkqhkiG9w0B
# CQQxFgQUzE5t1uf3a2tsrJ+hrV9lynjvHp0wDQYJKoZIhvcNAQEBBQAEggEAqK/e
# V1roVnpxFJTNpR5R9SV4WIY2Rp9yW3C8WQmy+tUgp7bQfVGfMNLQ9jm8IiV0V8ev
# V0nj2CfX0jqFxMpcAFQjNuYYVubWRx6+F73vOhN1oegAx01szTFDWhOc4og5lVtp
# ADpFz0d8VviZ5bYg10G/JdQ8Q1jvSqLjxi8WTnLrhf2AGv0KN7wKPpbe+O/lg9Ru
# qeJ0PrIypqZVQwzAe3+76CNNBOg4N8xC21Rn4zmIsTZK6O/+HKR70o/96dFls7z3
# SZKRuWdyD27oDcZXmXQh1mZtPjpRb1pdAzhWUjCOH5EN3TsUbLH/hqlIivrm2usK
# MCXmSQIAM9bs5IlD1Q==
# SIG # End signature block
