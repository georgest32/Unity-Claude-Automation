# Unity-Claude-IncrementalProcessor-Fixed.psm1
# Incremental update engine for efficient CPG updates on file changes
# Fixed version without timer-based processing to avoid runspace issues

using namespace System.IO
using namespace System.Collections.Generic
using namespace System.Management.Automation.Language

# Incremental Processor Class
class IncrementalProcessor {
    [hashtable]$FileSnapshots
    [hashtable]$DependencyGraph
    [System.IO.FileSystemWatcher]$FileWatcher
    [hashtable]$ChangeQueue
    [hashtable]$ProcessingState
    [object]$CPGManager
    [object]$CacheManager
    [int]$BatchSize
    [bool]$IsRunning
    [hashtable]$Statistics
    [scriptblock]$OnChangeDetected
    [scriptblock]$OnProcessingComplete
    [bool]$IsDisposed
    
    IncrementalProcessor([string]$watchPath, [object]$cpgManager, [object]$cacheManager) {
        Write-Debug "[IncrementalProcessor] Initializing for path: $watchPath"
        
        $this.FileSnapshots = [hashtable]::Synchronized(@{})
        $this.DependencyGraph = [hashtable]::Synchronized(@{})
        $this.ChangeQueue = [hashtable]::Synchronized(@{})
        $this.ProcessingState = [hashtable]::Synchronized(@{})
        $this.CPGManager = $cpgManager
        $this.CacheManager = $cacheManager
        $this.BatchSize = 10
        $this.IsRunning = $false
        $this.IsDisposed = $false
        
        # Initialize statistics
        $this.Statistics = [hashtable]::Synchronized(@{
            TotalChangesDetected = 0
            TotalChangesProcessed = 0
            TotalDiffsCalculated = 0
            TotalGraphUpdates = 0
            TotalPropagations = 0
            AverageProcessingTime = 0
            LastProcessingTime = [datetime]::MinValue
            CreatedAt = [datetime]::Now
        })
        
        # Setup file watcher
        $this.SetupFileWatcher($watchPath)
        
        Write-Debug "[IncrementalProcessor] Initialization complete"
    }
    
    # Setup file system watcher
    hidden [void]SetupFileWatcher([string]$path) {
        Write-Debug "[IncrementalProcessor] Setting up file watcher for: $path"
        
        $this.FileWatcher = [System.IO.FileSystemWatcher]::new()
        $this.FileWatcher.Path = $path
        $this.FileWatcher.Filter = "*.*"
        $this.FileWatcher.IncludeSubdirectories = $true
        $this.FileWatcher.NotifyFilter = [System.IO.NotifyFilters]::LastWrite -bor 
                                        [System.IO.NotifyFilters]::FileName -bor 
                                        [System.IO.NotifyFilters]::DirectoryName
        
        # Register event handlers with simpler action blocks
        $processor = $this
        
        Register-ObjectEvent -InputObject $this.FileWatcher -EventName "Changed" -Action {
            $path = $Event.SourceEventArgs.FullPath
            Write-Debug "File changed: $path"
        } | Out-Null
        
        Register-ObjectEvent -InputObject $this.FileWatcher -EventName "Created" -Action {
            $path = $Event.SourceEventArgs.FullPath
            Write-Debug "File created: $path"
        } | Out-Null
        
        Register-ObjectEvent -InputObject $this.FileWatcher -EventName "Deleted" -Action {
            $path = $Event.SourceEventArgs.FullPath
            Write-Debug "File deleted: $path"
        } | Out-Null
        
        Register-ObjectEvent -InputObject $this.FileWatcher -EventName "Renamed" -Action {
            $oldPath = $Event.SourceEventArgs.OldFullPath
            $newPath = $Event.SourceEventArgs.FullPath
            Write-Debug "File renamed from $oldPath to $newPath"
        } | Out-Null
    }
    
    # Start monitoring
    [void]Start() {
        Write-Debug "[IncrementalProcessor] Starting file monitoring"
        $this.FileWatcher.EnableRaisingEvents = $true
        $this.IsRunning = $true
        
        # Initial snapshot of existing files
        $this.CreateInitialSnapshots($this.FileWatcher.Path)
    }
    
    # Stop monitoring
    [void]Stop() {
        Write-Debug "[IncrementalProcessor] Stopping file monitoring"
        $this.FileWatcher.EnableRaisingEvents = $false
        $this.IsRunning = $false
    }
    
    # Create initial snapshots
    hidden [void]CreateInitialSnapshots([string]$path) {
        Write-Debug "[IncrementalProcessor] Creating initial snapshots"
        
        $files = Get-ChildItem -Path $path -File -Recurse -Include "*.ps1", "*.psm1", "*.psd1", "*.py", "*.js", "*.ts", "*.cs" -ErrorAction SilentlyContinue
        
        foreach ($file in $files) {
            try {
                $snapshot = $this.CreateFileSnapshot($file.FullName)
                if ($snapshot) {
                    $this.FileSnapshots[$file.FullName] = $snapshot
                    Write-Debug "[IncrementalProcessor] Created snapshot for: $($file.Name)"
                }
            }
            catch {
                Write-Warning "[IncrementalProcessor] Failed to create snapshot for $($file.FullName): $_"
            }
        }
        
        Write-Debug "[IncrementalProcessor] Created $($this.FileSnapshots.Count) initial snapshots"
    }
    
    # Create file snapshot
    hidden [hashtable]CreateFileSnapshot([string]$filePath) {
        if (-not (Test-Path $filePath)) {
            return $null
        }
        
        $content = Get-Content -Path $filePath -Raw -ErrorAction SilentlyContinue
        if (-not $content) {
            return $null
        }
        
        $snapshot = @{
            FilePath = $filePath
            Content = $content
            Hash = $this.GetContentHash($content)
            LastModified = (Get-Item $filePath).LastWriteTime
            AST = $null
            Tokens = $null
            ParseErrors = $null
        }
        
        # Parse AST for PowerShell files
        if ($filePath -match '\.(ps1|psm1|psd1)$') {
            try {
                $tokens = $null
                $errors = $null
                $ast = [Parser]::ParseInput($content, [ref]$tokens, [ref]$errors)
                
                $snapshot.AST = $ast
                $snapshot.Tokens = $tokens
                $snapshot.ParseErrors = $errors
            }
            catch {
                Write-Warning "[IncrementalProcessor] Failed to parse AST for $filePath : $_"
            }
        }
        
        return $snapshot
    }
    
    # Get content hash
    hidden [string]GetContentHash([string]$content) {
        $sha256 = [System.Security.Cryptography.SHA256]::Create()
        $bytes = [System.Text.Encoding]::UTF8.GetBytes($content)
        $hash = $sha256.ComputeHash($bytes)
        return [System.BitConverter]::ToString($hash).Replace("-", "")
    }
    
    # Handle file change - manual processing
    [void]HandleFileChange([string]$filePath, [string]$changeType) {
        # Filter for relevant file types
        if ($filePath -notmatch '\.(ps1|psm1|psd1|py|js|ts|cs)$') {
            return
        }
        
        Write-Debug "[IncrementalProcessor] File change detected: $filePath ($changeType)"
        
        # Add to change queue
        $this.ChangeQueue[$filePath] = @{
            FilePath = $filePath
            ChangeType = $changeType
            Timestamp = [datetime]::Now
            Processed = $false
        }
        
        $this.Statistics.TotalChangesDetected++
        
        # Trigger change detected callback
        if ($this.OnChangeDetected) {
            & $this.OnChangeDetected $filePath $changeType
        }
    }
    
    # Process change queue manually
    [void]ProcessChangeQueue() {
        if ($this.ChangeQueue.Count -eq 0) {
            return
        }
        
        $startTime = [datetime]::Now
        $changes = @()
        
        # Get batch of changes to process
        $count = 0
        foreach ($change in $this.ChangeQueue.Values) {
            if (-not $change.Processed -and $count -lt $this.BatchSize) {
                $changes += $change
                $count++
            }
        }
        
        if ($changes.Count -eq 0) {
            return
        }
        
        Write-Debug "[IncrementalProcessor] Processing $($changes.Count) changes"
        
        foreach ($change in $changes) {
            try {
                $this.ProcessFileChange($change)
                $change.Processed = $true
                $this.ChangeQueue.Remove($change.FilePath)
                $this.Statistics.TotalChangesProcessed++
            }
            catch {
                Write-Error "[IncrementalProcessor] Error processing change for $($change.FilePath): $_"
            }
        }
        
        # Update statistics
        $elapsed = ([datetime]::Now - $startTime).TotalMilliseconds
        if ($this.Statistics.TotalChangesProcessed -gt 0) {
            $this.Statistics.AverageProcessingTime = (($this.Statistics.AverageProcessingTime * ($this.Statistics.TotalChangesProcessed - $changes.Count)) + $elapsed) / $this.Statistics.TotalChangesProcessed
        }
        $this.Statistics.LastProcessingTime = [datetime]::Now
        
        # Trigger processing complete callback
        if ($this.OnProcessingComplete -and $changes.Count -gt 0) {
            & $this.OnProcessingComplete $changes
        }
    }
    
    # Process individual file change
    hidden [void]ProcessFileChange([hashtable]$change) {
        Write-Debug "[IncrementalProcessor] Processing change: $($change.FilePath) ($($change.ChangeType))"
        
        switch ($change.ChangeType) {
            'Created' {
                $this.ProcessFileCreated($change.FilePath)
            }
            'Modified' {
                $this.ProcessFileModified($change.FilePath)
            }
            'Deleted' {
                $this.ProcessFileDeleted($change.FilePath)
            }
        }
    }
    
    # Process file creation
    hidden [void]ProcessFileCreated([string]$filePath) {
        Write-Debug "[IncrementalProcessor] Processing file creation: $filePath"
        
        # Create snapshot
        $snapshot = $this.CreateFileSnapshot($filePath)
        if (-not $snapshot) {
            return
        }
        
        $this.FileSnapshots[$filePath] = $snapshot
        
        # Update CPG if AST available
        if ($snapshot.AST -and $this.CPGManager) {
            $this.UpdateCPGForFile($filePath, $snapshot, 'Add')
        }
        
        # Invalidate cache
        if ($this.CacheManager) {
            $this.InvalidateCacheForFile($filePath)
        }
    }
    
    # Process file modification
    hidden [void]ProcessFileModified([string]$filePath) {
        Write-Debug "[IncrementalProcessor] Processing file modification: $filePath"
        
        # Get old snapshot
        $oldSnapshot = $this.FileSnapshots[$filePath]
        
        # Create new snapshot
        $newSnapshot = $this.CreateFileSnapshot($filePath)
        if (-not $newSnapshot) {
            return
        }
        
        # Check if content actually changed
        if ($oldSnapshot -and $oldSnapshot.Hash -eq $newSnapshot.Hash) {
            Write-Debug "[IncrementalProcessor] File content unchanged, skipping: $filePath"
            return
        }
        
        # Calculate diff
        $diff = $this.CalculateDiff($oldSnapshot, $newSnapshot)
        $this.Statistics.TotalDiffsCalculated++
        
        # Update snapshot
        $this.FileSnapshots[$filePath] = $newSnapshot
        
        # Update CPG if AST available
        if ($newSnapshot.AST -and $this.CPGManager) {
            $this.UpdateCPGForFile($filePath, $newSnapshot, 'Update', $diff)
        }
        
        # Propagate changes
        $this.PropagateChanges($filePath, $diff)
        
        # Invalidate cache
        if ($this.CacheManager) {
            $this.InvalidateCacheForFile($filePath)
        }
    }
    
    # Process file deletion
    hidden [void]ProcessFileDeleted([string]$filePath) {
        Write-Debug "[IncrementalProcessor] Processing file deletion: $filePath"
        
        # Remove snapshot
        $this.FileSnapshots.Remove($filePath)
        
        # Update CPG
        if ($this.CPGManager) {
            $this.UpdateCPGForFile($filePath, $null, 'Remove')
        }
        
        # Propagate deletion
        $this.PropagateChanges($filePath, @{ Type = 'Deleted' })
        
        # Invalidate cache
        if ($this.CacheManager) {
            $this.InvalidateCacheForFile($filePath)
        }
    }
    
    # Calculate diff between snapshots
    hidden [hashtable]CalculateDiff([hashtable]$oldSnapshot, [hashtable]$newSnapshot) {
        Write-Debug "[IncrementalProcessor] Calculating diff"
        
        $diff = @{
            Type = 'Modified'
            AddedLines = @()
            RemovedLines = @()
            ModifiedLines = @()
            ASTChanges = @()
        }
        
        if (-not $oldSnapshot) {
            $diff.Type = 'Created'
            return $diff
        }
        
        # Line-level diff
        $oldLines = $oldSnapshot.Content -split "`n"
        $newLines = $newSnapshot.Content -split "`n"
        
        # Simple line diff (could be enhanced with proper diff algorithm)
        $maxLines = [Math]::Max($oldLines.Count, $newLines.Count)
        for ($i = 0; $i -lt $maxLines; $i++) {
            if ($i -ge $oldLines.Count) {
                $diff.AddedLines += @{ LineNumber = $i + 1; Content = $newLines[$i] }
            }
            elseif ($i -ge $newLines.Count) {
                $diff.RemovedLines += @{ LineNumber = $i + 1; Content = $oldLines[$i] }
            }
            elseif ($oldLines[$i] -ne $newLines[$i]) {
                $diff.ModifiedLines += @{ 
                    LineNumber = $i + 1
                    OldContent = $oldLines[$i]
                    NewContent = $newLines[$i]
                }
            }
        }
        
        # AST-level diff for PowerShell files
        if ($oldSnapshot.AST -and $newSnapshot.AST) {
            $diff.ASTChanges = $this.CalculateASTDiff($oldSnapshot.AST, $newSnapshot.AST)
        }
        
        return $diff
    }
    
    # Calculate AST diff
    hidden [array]CalculateASTDiff([Ast]$oldAst, [Ast]$newAst) {
        $changes = @()
        
        # Find functions in old AST
        $oldFunctions = $oldAst.FindAll({ $args[0] -is [FunctionDefinitionAst] }, $true)
        $newFunctions = $newAst.FindAll({ $args[0] -is [FunctionDefinitionAst] }, $true)
        
        # Track function changes
        $oldFuncNames = $oldFunctions | ForEach-Object { $_.Name }
        $newFuncNames = $newFunctions | ForEach-Object { $_.Name }
        
        # Added functions
        $added = $newFuncNames | Where-Object { $_ -notin $oldFuncNames }
        foreach ($name in $added) {
            $changes += @{ Type = 'FunctionAdded'; Name = $name }
        }
        
        # Removed functions
        $removed = $oldFuncNames | Where-Object { $_ -notin $newFuncNames }
        foreach ($name in $removed) {
            $changes += @{ Type = 'FunctionRemoved'; Name = $name }
        }
        
        # Modified functions (simplified check)
        $common = $oldFuncNames | Where-Object { $_ -in $newFuncNames }
        foreach ($name in $common) {
            $oldFunc = $oldFunctions | Where-Object { $_.Name -eq $name } | Select-Object -First 1
            $newFunc = $newFunctions | Where-Object { $_.Name -eq $name } | Select-Object -First 1
            
            if ($oldFunc.Body.ToString() -ne $newFunc.Body.ToString()) {
                $changes += @{ Type = 'FunctionModified'; Name = $name }
            }
        }
        
        return $changes
    }
    
    # Update CPG for file
    hidden [void]UpdateCPGForFile([string]$filePath, [hashtable]$snapshot, [string]$operation, [hashtable]$diff = $null) {
        Write-Debug "[IncrementalProcessor] Updating CPG for file: $filePath ($operation)"
        
        try {
            switch ($operation) {
                'Add' {
                    if ($this.CPGManager -and $this.CPGManager.PSObject.Methods['AddFile']) {
                        $this.CPGManager.AddFile($filePath, $snapshot.AST)
                    }
                }
                'Update' {
                    if ($this.CPGManager -and $this.CPGManager.PSObject.Methods['UpdateFile']) {
                        $this.CPGManager.UpdateFile($filePath, $snapshot.AST, $diff)
                    }
                }
                'Remove' {
                    if ($this.CPGManager -and $this.CPGManager.PSObject.Methods['RemoveFile']) {
                        $this.CPGManager.RemoveFile($filePath)
                    }
                }
            }
            
            $this.Statistics.TotalGraphUpdates++
        }
        catch {
            Write-Error "[IncrementalProcessor] Failed to update CPG: $_"
        }
    }
    
    # Propagate changes to dependent files
    hidden [void]PropagateChanges([string]$filePath, [hashtable]$diff) {
        Write-Debug "[IncrementalProcessor] Propagating changes from: $filePath"
        
        # Get dependent files from dependency graph
        $dependents = $this.GetDependentFiles($filePath)
        
        foreach ($dependent in $dependents) {
            Write-Debug "[IncrementalProcessor] Propagating to dependent: $dependent"
            
            # Mark dependent for reprocessing
            if ($this.CacheManager) {
                $this.InvalidateCacheForFile($dependent)
            }
            
            # Could trigger re-analysis of dependent file
            # This is simplified - real implementation would be more sophisticated
            $this.Statistics.TotalPropagations++
        }
    }
    
    # Get dependent files
    hidden [array]GetDependentFiles([string]$filePath) {
        if (-not $this.DependencyGraph.ContainsKey($filePath)) {
            return @()
        }
        
        return $this.DependencyGraph[$filePath]
    }
    
    # Build dependency graph
    [void]BuildDependencyGraph() {
        Write-Debug "[IncrementalProcessor] Building dependency graph"
        
        foreach ($snapshot in $this.FileSnapshots.Values) {
            if (-not $snapshot.AST) {
                continue
            }
            
            $dependencies = $this.ExtractDependencies($snapshot)
            $this.DependencyGraph[$snapshot.FilePath] = $dependencies
        }
        
        Write-Debug "[IncrementalProcessor] Dependency graph built with $($this.DependencyGraph.Count) nodes"
    }
    
    # Extract dependencies from snapshot
    hidden [array]ExtractDependencies([hashtable]$snapshot) {
        $dependencies = @()
        
        if ($snapshot.AST) {
            # Find Import-Module statements
            $imports = $snapshot.AST.FindAll({ $args[0] -is [CommandAst] -and $args[0].CommandElements[0].Value -eq 'Import-Module' }, $true)
            
            foreach ($import in $imports) {
                if ($import.CommandElements.Count -gt 1) {
                    $moduleName = $import.CommandElements[1].Value
                    $dependencies += $moduleName
                }
            }
            
            # Find dot-sourcing
            $dotSources = $snapshot.AST.FindAll({ $args[0] -is [CommandAst] -and $args[0].CommandElements[0].Value -eq '.' }, $true)
            
            foreach ($dotSource in $dotSources) {
                if ($dotSource.CommandElements.Count -gt 1) {
                    $scriptPath = $dotSource.CommandElements[1].Value
                    $dependencies += $scriptPath
                }
            }
        }
        
        return $dependencies | Select-Object -Unique
    }
    
    # Invalidate cache for file
    hidden [void]InvalidateCacheForFile([string]$filePath) {
        if (-not $this.CacheManager) {
            return
        }
        
        Write-Debug "[IncrementalProcessor] Invalidating cache for: $filePath"
        
        # Remove file-specific cache entries
        $keysToRemove = @()
        
        if ($this.CacheManager.PSObject.Methods['GetKeys']) {
            $keys = $this.CacheManager.GetKeys()
            foreach ($key in $keys) {
                if ($key -like "*$filePath*") {
                    $keysToRemove += $key
                }
            }
        }
        
        foreach ($key in $keysToRemove) {
            if ($this.CacheManager.PSObject.Methods['Remove']) {
                $this.CacheManager.Remove($key)
                Write-Debug "[IncrementalProcessor] Removed cache key: $key"
            }
        }
    }
    
    # Get statistics
    [hashtable]GetStatistics() {
        return @{
            TotalChangesDetected = $this.Statistics.TotalChangesDetected
            TotalChangesProcessed = $this.Statistics.TotalChangesProcessed
            TotalDiffsCalculated = $this.Statistics.TotalDiffsCalculated
            TotalGraphUpdates = $this.Statistics.TotalGraphUpdates
            TotalPropagations = $this.Statistics.TotalPropagations
            AverageProcessingTime = [math]::Round($this.Statistics.AverageProcessingTime, 2)
            LastProcessingTime = $this.Statistics.LastProcessingTime
            QueueSize = $this.ChangeQueue.Count
            SnapshotCount = $this.FileSnapshots.Count
            IsRunning = $this.IsRunning
            Uptime = ([datetime]::Now - $this.Statistics.CreatedAt)
        }
    }
    
    # Create checkpoint
    [hashtable]CreateCheckpoint() {
        Write-Debug "[IncrementalProcessor] Creating checkpoint"
        
        return @{
            Timestamp = [datetime]::Now
            Snapshots = $this.FileSnapshots.Clone()
            DependencyGraph = $this.DependencyGraph.Clone()
            Statistics = $this.Statistics.Clone()
        }
    }
    
    # Restore from checkpoint
    [void]RestoreCheckpoint([hashtable]$checkpoint) {
        Write-Debug "[IncrementalProcessor] Restoring from checkpoint"
        
        $this.FileSnapshots = $checkpoint.Snapshots
        $this.DependencyGraph = $checkpoint.DependencyGraph
        
        Write-Debug "[IncrementalProcessor] Checkpoint restored"
    }
    
    # Dispose resources
    [void]Dispose() {
        if ($this.IsDisposed) { return }
        
        Write-Debug "[IncrementalProcessor] Disposing incremental processor"
        
        $this.IsDisposed = $true
        $this.Stop()
        
        if ($this.FileWatcher) {
            $this.FileWatcher.Dispose()
        }
        
        # Clean up event handlers
        Get-EventSubscriber | Where-Object { $_.SourceObject -eq $this.FileWatcher } | Unregister-Event
    }
}

# Module Functions

function New-IncrementalProcessor {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$WatchPath,
        
        [Parameter()]
        [object]$CPGManager,
        
        [Parameter()]
        [object]$CacheManager,
        
        [Parameter()]
        [scriptblock]$OnChangeDetected,
        
        [Parameter()]
        [scriptblock]$OnProcessingComplete
    )
    
    Write-Verbose "Creating incremental processor for: $WatchPath"
    
    try {
        $processor = [IncrementalProcessor]::new($WatchPath, $CPGManager, $CacheManager)
        
        if ($OnChangeDetected) {
            $processor.OnChangeDetected = $OnChangeDetected
        }
        
        if ($OnProcessingComplete) {
            $processor.OnProcessingComplete = $OnProcessingComplete
        }
        
        Write-Verbose "Incremental processor created successfully"
        return $processor
    }
    catch {
        Write-Error "Failed to create incremental processor: $_"
        throw
    }
}

function Start-IncrementalProcessing {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [IncrementalProcessor]$Processor
    )
    
    Write-Verbose "Starting incremental processing"
    $Processor.Start()
}

function Stop-IncrementalProcessing {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [IncrementalProcessor]$Processor
    )
    
    Write-Verbose "Stopping incremental processing"
    $Processor.Stop()
}

function Get-IncrementalProcessorStatistics {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [IncrementalProcessor]$Processor
    )
    
    Write-Verbose "Getting incremental processor statistics"
    return $Processor.GetStatistics()
}

function New-ProcessorCheckpoint {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [IncrementalProcessor]$Processor
    )
    
    Write-Verbose "Creating processor checkpoint"
    return $Processor.CreateCheckpoint()
}

function Restore-ProcessorCheckpoint {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [IncrementalProcessor]$Processor,
        
        [Parameter(Mandatory)]
        [hashtable]$Checkpoint
    )
    
    Write-Verbose "Restoring processor checkpoint"
    $Processor.RestoreCheckpoint($Checkpoint)
}

function Update-CPGIncremental {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$FilePath,
        
        [Parameter(Mandatory)]
        [IncrementalProcessor]$Processor
    )
    
    Write-Verbose "Triggering incremental CPG update for: $FilePath"
    $Processor.HandleFileChange($FilePath, 'Modified')
}

function Build-DependencyGraph {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [IncrementalProcessor]$Processor
    )
    
    Write-Verbose "Building dependency graph"
    $Processor.BuildDependencyGraph()
}

function Start-ProcessChangeQueue {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [IncrementalProcessor]$Processor
    )
    
    Write-Verbose "Processing change queue"
    $Processor.ProcessChangeQueue()
}

# Export module members
Export-ModuleMember -Function @(
    'New-IncrementalProcessor',
    'Start-IncrementalProcessing',
    'Stop-IncrementalProcessing',
    'Get-IncrementalProcessorStatistics',
    'New-ProcessorCheckpoint',
    'Restore-ProcessorCheckpoint',
    'Update-CPGIncremental',
    'Build-DependencyGraph',
    'Start-ProcessChangeQueue'
) -Variable @() -Alias @()
# SIG # Begin signature block
# MIIFzgYJKoZIhvcNAQcCoIIFvzCCBbsCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCDVvL6utOg3oAKi
# JJNFpkd8g8KH/PykjGpjHVpL+uNeVaCCAzAwggMsMIICFKADAgECAhB1HRbZIqgr
# lUTwkh3hnGtFMA0GCSqGSIb3DQEBCwUAMC4xLDAqBgNVBAMMI1VuaXR5LUNsYXVk
# ZS1BdXRvbWF0aW9uLURldmVsb3BtZW50MB4XDTI1MDgyMDIxMTUxN1oXDTI2MDgy
# MDIxMzUxN1owLjEsMCoGA1UEAwwjVW5pdHktQ2xhdWRlLUF1dG9tYXRpb24tRGV2
# ZWxvcG1lbnQwggEiMA0GCSqGSIb3DQEBAQUAA4IBDwAwggEKAoIBAQCx4feqKdUQ
# 6GufY4umNzlM1Pi8aHUGR8HlfhIWFjsrRAxCxhieRlWbHe0Hw+pVBeX76X57e5Pu
# 4Kxxzu+MxMry0NJYf3yOLRTfhYskHBcLraXUCtrMwqnhPKvul6Sx6Lu8vilk605W
# ADJNifl3WFuexVCYJJM9G2mfuYIDN+rZ5zmpn0qCXum49bm629h+HyJ205Zrn9aB
# hIrA4i/JlrAh1kosWnCo62psl7ixbNVqFqwWEt+gAqSeIo4ChwkOQl7GHmk78Q5I
# oRneY4JTVlKzhdZEYhJGFXeoZml/5jcmUcox4UNYrKdokE7z8ZTmyowBOUNS+sHI
# G1TY5DZSb8vdAgMBAAGjRjBEMA4GA1UdDwEB/wQEAwIHgDATBgNVHSUEDDAKBggr
# BgEFBQcDAzAdBgNVHQ4EFgQUfDms7LrGVboHjmwlSyIjYD/JLQwwDQYJKoZIhvcN
# AQELBQADggEBABRMsfT7DzKy+aFi4HDg0MpxmbjQxOH1lzUzanaECRiyA0sn7+sA
# /4jvis1+qC5NjDGkLKOTCuDzIXnBWLCCBugukXbIO7g392ANqKdHjBHw1WlLvMVk
# 4WSmY096lzpvDd3jJApr/Alcp4KmRGNLnQ3vv+F9Uj58Uo1qjs85vt6fl9xe5lo3
# rFahNHL4ngjgyF8emNm7FItJeNtVe08PhFn0caOX0FTzXrZxGGO6Ov8tzf91j/qK
# QdBifG7Fx3FF7DifNqoBBo55a7q0anz30k8p+V0zllrLkgGXfOzXmA1L37Qmt3QB
# FCdJVigjQMuHcrJsWd8rg857Og0un91tfZIxggH0MIIB8AIBATBCMC4xLDAqBgNV
# BAMMI1VuaXR5LUNsYXVkZS1BdXRvbWF0aW9uLURldmVsb3BtZW50AhB1HRbZIqgr
# lUTwkh3hnGtFMA0GCWCGSAFlAwQCAQUAoIGEMBgGCisGAQQBgjcCAQwxCjAIoAKA
# AKECgAAwGQYJKoZIhvcNAQkDMQwGCisGAQQBgjcCAQQwHAYKKwYBBAGCNwIBCzEO
# MAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIO3AwDI90Ppk/b1aeZALWZui
# pbQrz22x3WHjiRDAyE53MA0GCSqGSIb3DQEBAQUABIIBAEZgfOQBuCfbun6GSLbg
# vQLk7KDbEgV1Y8+/AjlSwBE1lCzkelJJQcUNyIpXX6q8ZRzWbkpCGKr95OjGo7CZ
# BOjPdFevMvoF/45AsagNzXopKlO+XxBd1NMwrXP/+ssXKA7SJlbaq2tpx4+S5dGJ
# 4KRf0BPw9a+4vwFzvYzRWAhITijHTU1CZ/aVyyLTuQnW4V6nsHDq+uCqfZc8kE8U
# jp5gDtGZP2rlqaW1hr07MM56x5NMafvv4UGsfk3sCwKWwUelcR+t66ZsnclPsLFq
# y+8MnPoHlk5xN/7RPDoG4+sBXCp7semsd0TdbSMKVKM8cW3EdupMAf/bYLaFJYH2
# +CM=
# SIG # End signature block
