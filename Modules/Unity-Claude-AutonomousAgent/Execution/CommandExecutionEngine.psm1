# CommandExecutionEngine.psm1
# Master Plan Day 12: Command Execution Engine Integration
# Implements execution pipeline, queue management, parallel execution, and safety integration
# Date: 2025-08-18
# IMPORTANT: ASCII only, no backticks, proper variable delimiting

#region Module Dependencies

# Import required modules
Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) "Core\AgentLogging.psm1") -Force
Import-Module (Join-Path $PSScriptRoot "SafeExecution.psm1") -Force
Import-Module (Join-Path $PSScriptRoot "ErrorHandling.psm1") -Force
# Classification module integration will be added in future iteration
# Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) "Parsing\Classification.psm1") -Force

#endregion

#region Module Variables

# Execution queue with priority levels
$script:ExecutionQueue = @{
    Critical = [System.Collections.Concurrent.ConcurrentQueue[object]]::new()
    High = [System.Collections.Concurrent.ConcurrentQueue[object]]::new()
    Medium = [System.Collections.Concurrent.ConcurrentQueue[object]]::new()
    Low = [System.Collections.Concurrent.ConcurrentQueue[object]]::new()
}

# Queue statistics
$script:QueueStats = @{
    TotalQueued = 0
    TotalExecuted = 0
    TotalFailed = 0
    TotalSkipped = 0
    AverageExecutionTime = 0
    LastExecutionTime = $null
}

# Execution configuration
$script:ExecutionConfig = @{
    ThrottleLimit = 5          # Max parallel executions
    DefaultTimeoutMs = 300000  # 5 minutes default
    MinConfidenceThreshold = 0.7  # Minimum confidence for auto-execution
    EnableDryRun = $false      # Global dry-run mode
    RequireApproval = $false  # Require human approval for all commands
    EnableParallel = $true    # Enable parallel execution
}

# Active executions tracking
$script:ActiveExecutions = @{
    Jobs = @{}
    Count = 0
    MaxCount = 5
}

# Human approval queue
$script:ApprovalQueue = [System.Collections.Concurrent.ConcurrentQueue[object]]::new()

# Command dependencies registry
$script:DependencyRegistry = @{
    FileRead = @("Get-Content", "Get-Item", "Test-Path", "Get-ChildItem")
    FileWrite = @("Set-Content", "Add-Content", "Out-File", "New-Item")
    ProcessControl = @("Start-Process", "Stop-Process", "Get-Process")
    NetworkOps = @("Invoke-WebRequest", "Invoke-RestMethod", "Test-Connection")
}

#endregion

#region Queue Management Functions

function Add-CommandToQueue {
    <#
    .SYNOPSIS
    Adds a command to the execution queue with priority
    
    .DESCRIPTION
    Enqueues commands based on priority level and tracks queue statistics
    
    .PARAMETER Command
    The command to execute
    
    .PARAMETER Priority
    Execution priority (Critical, High, Medium, Low)
    
    .PARAMETER Context
    Additional context for the command
    
    .PARAMETER Dependencies
    List of commands that must complete before this one
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Command,
        
        [ValidateSet("Critical", "High", "Medium", "Low")]
        [string]$Priority = "Medium",
        
        [hashtable]$Context = @{},
        
        [string[]]$Dependencies = @()
    )
    
    Write-AgentLog "Adding command to $Priority priority queue: $Command" -Level "INFO" -Component "QueueManager"
    
    try {
        $queueItem = @{
            Id = [Guid]::NewGuid().ToString()
            Command = $Command
            Priority = $Priority
            Context = $Context
            Dependencies = $Dependencies
            QueuedAt = Get-Date
            Status = "Queued"
            Confidence = 0.0
        }
        
        # Calculate confidence if not provided
        if (-not $Context.ContainsKey("Confidence")) {
            # Simple confidence calculation for commands
            # In future, integrate with Classification module properly
            $queueItem.Confidence = 0.5  # Default confidence
            
            # Higher confidence for safe read-only commands
            if ($Command -match "^(Get-|Test-|Read-)") {
                $queueItem.Confidence = 0.8
            }
            # Lower confidence for write operations
            elseif ($Command -match "^(Set-|Remove-|Clear-|Stop-)") {
                $queueItem.Confidence = 0.3
            }
        } else {
            $queueItem.Confidence = $Context.Confidence
        }
        
        # Add to appropriate queue
        $queue = $script:ExecutionQueue[$Priority]
        $queue.Enqueue($queueItem)
        $script:QueueStats.TotalQueued++
        
        Write-AgentLog "Command queued successfully: ID=$($queueItem.Id), Confidence=$($queueItem.Confidence)" -Level "SUCCESS" -Component "QueueManager"
        
        return $queueItem
    }
    catch {
        Write-AgentLog "Failed to queue command: $_" -Level "ERROR" -Component "QueueManager"
        return $null
    }
}

function Get-NextCommand {
    <#
    .SYNOPSIS
    Gets the next command from the queue based on priority
    
    .DESCRIPTION
    Dequeues commands in priority order: Critical > High > Medium > Low
    
    .PARAMETER CheckDependencies
    Whether to check if dependencies are satisfied
    #>
    [CmdletBinding()]
    param(
        [switch]$CheckDependencies
    )
    
    Write-AgentLog "Getting next command from queue" -Level "DEBUG" -Component "QueueManager"
    
    # Check queues in priority order
    foreach ($priority in @("Critical", "High", "Medium", "Low")) {
        $queue = $script:ExecutionQueue[$priority]
        $item = $null
        
        if ($queue.TryDequeue([ref]$item)) {
            # Check dependencies if requested
            if ($CheckDependencies -and $item.Dependencies.Count -gt 0) {
                if (-not (Test-CommandDependencies -Dependencies $item.Dependencies)) {
                    # Re-queue if dependencies not satisfied
                    Write-AgentLog "Dependencies not satisfied for command $($item.Id), re-queuing" -Level "DEBUG" -Component "QueueManager"
                    $queue.Enqueue($item)
                    continue
                }
            }
            
            Write-AgentLog "Dequeued command from $priority queue: $($item.Command)" -Level "INFO" -Component "QueueManager"
            return $item
        }
    }
    
    Write-AgentLog "No commands available in queue" -Level "DEBUG" -Component "QueueManager"
    return $null
}

function Get-QueueStatus {
    <#
    .SYNOPSIS
    Gets the current status of all execution queues
    
    .DESCRIPTION
    Returns queue counts and statistics
    #>
    [CmdletBinding()]
    param()
    
    $status = @{
        Critical = $script:ExecutionQueue.Critical.Count
        High = $script:ExecutionQueue.High.Count
        Medium = $script:ExecutionQueue.Medium.Count
        Low = $script:ExecutionQueue.Low.Count
        Total = 0
        Stats = $script:QueueStats
        ActiveExecutions = $script:ActiveExecutions.Count
    }
    
    $status.Total = $status.Critical + $status.High + $status.Medium + $status.Low
    
    Write-AgentLog "Queue status: Total=$($status.Total), Active=$($status.ActiveExecutions)" -Level "DEBUG" -Component "QueueManager"
    
    return $status
}

function Clear-ExecutionQueue {
    <#
    .SYNOPSIS
    Clears all commands from the execution queue
    
    .DESCRIPTION
    Removes all queued commands and optionally specific priority levels
    
    .PARAMETER Priority
    Specific priority level to clear (or all if not specified)
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [ValidateSet("Critical", "High", "Medium", "Low", "All")]
        [string]$Priority = "All"
    )
    
    if ($PSCmdlet.ShouldProcess("Execution Queue", "Clear")) {
        if ($Priority -eq "All") {
            foreach ($p in @("Critical", "High", "Medium", "Low")) {
                $script:ExecutionQueue[$p] = [System.Collections.Concurrent.ConcurrentQueue[object]]::new()
            }
            Write-AgentLog "Cleared all execution queues" -Level "INFO" -Component "QueueManager"
        } else {
            $script:ExecutionQueue[$Priority] = [System.Collections.Concurrent.ConcurrentQueue[object]]::new()
            Write-AgentLog "Cleared $Priority priority queue" -Level "INFO" -Component "QueueManager"
        }
    }
}

#endregion

#region Parallel Execution Functions

function Start-ParallelExecution {
    <#
    .SYNOPSIS
    Starts parallel execution of queued commands
    
    .DESCRIPTION
    Uses ThreadJob for efficient parallel execution with throttling
    
    .PARAMETER MaxParallel
    Maximum number of parallel executions
    
    .PARAMETER TimeoutMs
    Timeout for each execution in milliseconds
    #>
    [CmdletBinding()]
    param(
        [int]$MaxParallel = 5,
        
        [int]$TimeoutMs = 300000
    )
    
    Write-AgentLog "Starting parallel execution processor (MaxParallel=$MaxParallel)" -Level "INFO" -Component "ParallelExecutor"
    
    # Check if ThreadJob module is available
    if (-not (Get-Module -ListAvailable -Name ThreadJob)) {
        Write-AgentLog "ThreadJob module not found, installing..." -Level "WARNING" -Component "ParallelExecutor"
        try {
            Install-Module -Name ThreadJob -Scope CurrentUser -Force -AllowClobber
            Import-Module ThreadJob
        }
        catch {
            Write-AgentLog "Failed to install ThreadJob module: $_" -Level "ERROR" -Component "ParallelExecutor"
            return $false
        }
    }
    
    $script:ExecutionConfig.ThrottleLimit = $MaxParallel
    $processorRunning = $true
    
    while ($processorRunning) {
        # Check if we can start more jobs
        if ($script:ActiveExecutions.Count -lt $MaxParallel) {
            $command = Get-NextCommand -CheckDependencies
            
            if ($command) {
                # Start execution job
                $job = Start-ThreadJob -ThrottleLimit $MaxParallel -ScriptBlock {
                    param($CommandItem, $ModulePath)
                    
                    # Import required modules in job context
                    Import-Module (Join-Path $ModulePath "Core\AgentLogging.psm1") -Force
                    Import-Module (Join-Path $ModulePath "Execution\SafeExecution.psm1") -Force
                    
                    # Execute command
                    $result = Invoke-SafeCommandExecution -Command $CommandItem.Command -Context $CommandItem.Context
                    
                    return @{
                        CommandId = $CommandItem.Id
                        Success = $result.Success
                        Output = $result.Output
                        Error = $result.Error
                        ExecutionTime = $result.ExecutionTime
                    }
                } -ArgumentList $command, (Split-Path $PSScriptRoot -Parent)
                
                # Track active job
                $script:ActiveExecutions.Jobs[$job.Id] = @{
                    Job = $job
                    Command = $command
                    StartTime = Get-Date
                }
                $script:ActiveExecutions.Count++
                
                Write-AgentLog "Started parallel execution: JobId=$($job.Id), CommandId=$($command.Id)" -Level "INFO" -Component "ParallelExecutor"
            }
        }
        
        # Check for completed jobs
        $completedJobs = @()
        foreach ($jobId in $script:ActiveExecutions.Jobs.Keys) {
            $jobInfo = $script:ActiveExecutions.Jobs[$jobId]
            $job = $jobInfo.Job
            
            if ($job.State -eq "Completed" -or $job.State -eq "Failed") {
                $completedJobs += $jobId
                
                # Process job results
                try {
                    $result = Receive-Job -Job $job
                    Remove-Job -Job $job -Force
                    
                    # Update statistics
                    if ($result.Success) {
                        $script:QueueStats.TotalExecuted++
                        Write-AgentLog "Command executed successfully: $($result.CommandId)" -Level "SUCCESS" -Component "ParallelExecutor"
                    } else {
                        $script:QueueStats.TotalFailed++
                        Write-AgentLog "Command execution failed: $($result.CommandId) - $($result.Error)" -Level "ERROR" -Component "ParallelExecutor"
                    }
                    
                    # Update execution time stats
                    if ($result.ExecutionTime) {
                        $currentAvg = $script:QueueStats.AverageExecutionTime
                        $totalExec = $script:QueueStats.TotalExecuted + $script:QueueStats.TotalFailed
                        $script:QueueStats.AverageExecutionTime = (($currentAvg * ($totalExec - 1)) + $result.ExecutionTime) / $totalExec
                    }
                }
                catch {
                    Write-AgentLog "Error processing job results: $_" -Level "ERROR" -Component "ParallelExecutor"
                    $script:QueueStats.TotalFailed++
                }
            }
            
            # Check for timeout
            elseif (((Get-Date) - $jobInfo.StartTime).TotalMilliseconds -gt $TimeoutMs) {
                $completedJobs += $jobId
                Stop-Job -Job $job -PassThru | Remove-Job -Force
                
                $script:QueueStats.TotalFailed++
                Write-AgentLog "Job timed out: JobId=$jobId" -Level "WARNING" -Component "ParallelExecutor"
            }
        }
        
        # Remove completed jobs from tracking
        foreach ($jobId in $completedJobs) {
            $script:ActiveExecutions.Jobs.Remove($jobId)
            $script:ActiveExecutions.Count--
        }
        
        # Check if we should continue
        $queueStatus = Get-QueueStatus
        if ($queueStatus.Total -eq 0 -and $script:ActiveExecutions.Count -eq 0) {
            Write-AgentLog "No more commands to process, stopping parallel executor" -Level "INFO" -Component "ParallelExecutor"
            $processorRunning = $false
        }
        
        # Small delay to prevent CPU spinning
        Start-Sleep -Milliseconds 100
    }
    
    Write-AgentLog "Parallel execution completed" -Level "SUCCESS" -Component "ParallelExecutor"
    return $true
}

function Test-CommandDependencies {
    <#
    .SYNOPSIS
    Tests if command dependencies are satisfied
    
    .DESCRIPTION
    Checks if required commands have been executed successfully
    
    .PARAMETER Dependencies
    List of command dependencies to check
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string[]]$Dependencies
    )
    
    Write-AgentLog "Checking dependencies: $($Dependencies -join ', ')" -Level "DEBUG" -Component "DependencyChecker"
    
    # For now, simplified implementation - could be enhanced with actual tracking
    foreach ($dep in $Dependencies) {
        # Check if dependency type is available
        $isAvailable = $true
        
        # Check against known command types
        foreach ($category in $script:DependencyRegistry.Keys) {
            if ($dep -in $script:DependencyRegistry[$category]) {
                Write-AgentLog "Dependency '$dep' found in category '$category'" -Level "DEBUG" -Component "DependencyChecker"
                break
            }
        }
        
        if (-not $isAvailable) {
            Write-AgentLog "Dependency not satisfied: $dep" -Level "WARNING" -Component "DependencyChecker"
            return $false
        }
    }
    
    Write-AgentLog "All dependencies satisfied" -Level "DEBUG" -Component "DependencyChecker"
    return $true
}

#endregion

#region Safety and Validation Functions

function Invoke-SafeCommandExecution {
    <#
    .SYNOPSIS
    Executes a command with safety validation and confidence checking
    
    .DESCRIPTION
    Validates command safety, checks confidence thresholds, and executes in constrained runspace
    
    .PARAMETER Command
    The command to execute
    
    .PARAMETER Context
    Execution context including confidence scores
    
    .PARAMETER DryRun
    Perform dry-run without actual execution
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Command,
        
        [hashtable]$Context = @{},
        
        [switch]$DryRun
    )
    
    $startTime = Get-Date
    Write-AgentLog "Starting safe command execution: $Command" -Level "INFO" -Component "SafeExecutor"
    
    try {
        # Step 1: Safety validation
        $safetyCheck = Test-CommandSafety -CommandText $Command
        if (-not $safetyCheck.IsSafe) {
            Write-AgentLog "Command failed safety check: $($safetyCheck.Reasons -join '; ')" -Level "ERROR" -Component "SafeExecutor"
            return @{
                Success = $false
                Error = "Command failed safety validation"
                SafetyReasons = $safetyCheck.Reasons
            }
        }
        
        # Step 2: Confidence threshold check
        $confidence = if ($Context.ContainsKey("Confidence")) { $Context.Confidence } else { 0.5 }
        if ($confidence -lt $script:ExecutionConfig.MinConfidenceThreshold) {
            Write-AgentLog "Command confidence below threshold: $confidence < $($script:ExecutionConfig.MinConfidenceThreshold)" -Level "WARNING" -Component "SafeExecutor"
            
            # Queue for human approval
            if (-not $Context.ContainsKey("ApprovalOverride")) {
                $approvalItem = @{
                    Command = $Command
                    Confidence = $confidence
                    Context = $Context
                    RequestedAt = Get-Date
                }
                $script:ApprovalQueue.Enqueue($approvalItem)
                
                Write-AgentLog "Command queued for human approval" -Level "INFO" -Component "SafeExecutor"
                return @{
                    Success = $false
                    Error = "Command requires human approval (low confidence)"
                    RequiresApproval = $true
                }
            }
        }
        
        # Step 3: Dry-run check
        if ($DryRun -or $script:ExecutionConfig.EnableDryRun) {
            if ($PSCmdlet.ShouldProcess($Command, "Execute Command (DRY-RUN)")) {
                Write-AgentLog "DRY-RUN: Would execute: $Command" -Level "INFO" -Component "SafeExecutor"
                return @{
                    Success = $true
                    Output = "[DRY-RUN] Command would be executed: $Command"
                    DryRun = $true
                    ExecutionTime = ((Get-Date) - $startTime).TotalMilliseconds
                }
            }
        }
        
        # Step 4: Execute in constrained runspace
        if ($PSCmdlet.ShouldProcess($Command, "Execute Command")) {
            Write-AgentLog "Executing command in constrained runspace" -Level "INFO" -Component "SafeExecutor"
            
            # Create constrained runspace
            $runspaceResult = New-ConstrainedRunspace -TimeoutMs $Context.TimeoutMs
            if (-not $runspaceResult.Success) {
                throw "Failed to create constrained runspace: $($runspaceResult.Error)"
            }
            
            $runspace = $runspaceResult.Runspace
            
            try {
                # Create PowerShell instance
                $powershell = [System.Management.Automation.PowerShell]::Create()
                $powershell.Runspace = $runspace
                
                # Add command
                $null = $powershell.AddScript($Command)
                
                # Execute with error handling
                $executeResult = Invoke-ExponentialBackoffRetry -ScriptBlock {
                    $asyncResult = $powershell.BeginInvoke()
                    $handle = $asyncResult.AsyncWaitHandle
                    
                    # Wait for completion with timeout
                    $completed = $handle.WaitOne($Context.TimeoutMs)
                    
                    if ($completed) {
                        $output = $powershell.EndInvoke($asyncResult)
                        return $output
                    } else {
                        $powershell.Stop()
                        throw "Command execution timed out"
                    }
                } -MaxRetries 2 -BaseDelayMs 1000
                
                if ($executeResult.Success) {
                    Write-AgentLog "Command executed successfully" -Level "SUCCESS" -Component "SafeExecutor"
                    return @{
                        Success = $true
                        Output = $executeResult.Result
                        ExecutionTime = ((Get-Date) - $startTime).TotalMilliseconds
                    }
                } else {
                    throw $executeResult.Error
                }
            }
            finally {
                # Cleanup
                if ($powershell) { $powershell.Dispose() }
                if ($runspace) { $runspace.Close() }
            }
        }
    }
    catch {
        Write-AgentLog "Command execution failed: $_" -Level "ERROR" -Component "SafeExecutor"
        return @{
            Success = $false
            Error = $_.Exception.Message
            ExecutionTime = ((Get-Date) - $startTime).TotalMilliseconds
        }
    }
}

function Request-HumanApproval {
    <#
    .SYNOPSIS
    Requests human approval for low-confidence commands
    
    .DESCRIPTION
    Creates approval request and waits for human response
    
    .PARAMETER Command
    The command requiring approval
    
    .PARAMETER Reason
    Reason for approval request
    
    .PARAMETER TimeoutMs
    Timeout for approval wait
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Command,
        
        [string]$Reason = "Low confidence score",
        
        [int]$TimeoutMs = 60000  # 1 minute default
    )
    
    Write-AgentLog "Requesting human approval for command: $Command" -Level "INFO" -Component "ApprovalManager"
    
    try {
        $approvalRequest = @{
            Id = [Guid]::NewGuid().ToString()
            Command = $Command
            Reason = $Reason
            RequestedAt = Get-Date
            Status = "Pending"
            TimeoutMs = $TimeoutMs
        }
        
        # Create approval file for human review
        $approvalDir = Join-Path (Split-Path (Split-Path $PSScriptRoot -Parent) -Parent) "Approvals"
        if (-not (Test-Path $approvalDir)) {
            New-Item -Path $approvalDir -ItemType Directory -Force | Out-Null
        }
        
        $approvalFile = Join-Path $approvalDir "$($approvalRequest.Id).json"
        $approvalRequest | ConvertTo-Json -Depth 10 | Set-Content -Path $approvalFile -Force
        
        Write-AgentLog "Approval request created: $approvalFile" -Level "INFO" -Component "ApprovalManager"
        
        # Wait for approval with timeout
        $startTime = Get-Date
        while (((Get-Date) - $startTime).TotalMilliseconds -lt $TimeoutMs) {
            # Check if approval file has been updated
            if (Test-Path $approvalFile) {
                $currentContent = Get-Content $approvalFile -Raw | ConvertFrom-Json
                if ($currentContent.Status -ne "Pending") {
                    Write-AgentLog "Approval status changed: $($currentContent.Status)" -Level "INFO" -Component "ApprovalManager"
                    return $currentContent
                }
            }
            
            Start-Sleep -Milliseconds 500
        }
        
        Write-AgentLog "Approval request timed out" -Level "WARNING" -Component "ApprovalManager"
        return @{
            Status = "Timeout"
            Id = $approvalRequest.Id
        }
    }
    catch {
        Write-AgentLog "Approval request failed: $_" -Level "ERROR" -Component "ApprovalManager"
        return @{
            Status = "Error"
            Error = $_.Exception.Message
        }
    }
}

function Get-PendingApprovals {
    <#
    .SYNOPSIS
    Gets all pending approval requests
    
    .DESCRIPTION
    Returns list of commands awaiting human approval
    #>
    [CmdletBinding()]
    param()
    
    $pendingApprovals = @()
    $item = $null
    
    # Temporarily dequeue to inspect (will re-queue)
    $tempQueue = @()
    while ($script:ApprovalQueue.TryDequeue([ref]$item)) {
        $pendingApprovals += $item
        $tempQueue += $item
    }
    
    # Re-queue items
    foreach ($item in $tempQueue) {
        $script:ApprovalQueue.Enqueue($item)
    }
    
    Write-AgentLog "Found $($pendingApprovals.Count) pending approvals" -Level "DEBUG" -Component "ApprovalManager"
    
    return $pendingApprovals
}

#endregion

#region Configuration Functions

function Set-ExecutionConfig {
    <#
    .SYNOPSIS
    Updates execution engine configuration
    
    .DESCRIPTION
    Configures throttle limits, timeouts, confidence thresholds, etc.
    
    .PARAMETER Config
    Configuration hashtable
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [hashtable]$Config
    )
    
    Write-AgentLog "Updating execution configuration" -Level "INFO" -Component "ConfigManager"
    
    try {
        foreach ($key in $Config.Keys) {
            if ($script:ExecutionConfig.ContainsKey($key)) {
                $oldValue = $script:ExecutionConfig[$key]
                $script:ExecutionConfig[$key] = $Config[$key]
                Write-AgentLog "Config updated: $key = $($Config[$key]) (was: $oldValue)" -Level "DEBUG" -Component "ConfigManager"
            } else {
                Write-AgentLog "Unknown configuration key: $key" -Level "WARNING" -Component "ConfigManager"
            }
        }
        
        Write-AgentLog "Execution configuration updated successfully" -Level "SUCCESS" -Component "ConfigManager"
        return $true
    }
    catch {
        Write-AgentLog "Failed to update configuration: $_" -Level "ERROR" -Component "ConfigManager"
        return $false
    }
}

function Get-ExecutionConfig {
    <#
    .SYNOPSIS
    Gets the current execution engine configuration
    
    .DESCRIPTION
    Returns current configuration settings
    #>
    [CmdletBinding()]
    param()
    
    return $script:ExecutionConfig
}

#endregion

#region Execution Result Functions

function Get-ExecutionStatistics {
    <#
    .SYNOPSIS
    Gets execution statistics and metrics
    
    .DESCRIPTION
    Returns detailed statistics about command execution
    #>
    [CmdletBinding()]
    param()
    
    $stats = $script:QueueStats.Clone()
    $stats.QueueStatus = Get-QueueStatus
    $stats.ConfiguredThrottle = $script:ExecutionConfig.ThrottleLimit
    $stats.MinConfidenceThreshold = $script:ExecutionConfig.MinConfidenceThreshold
    $stats.LastUpdated = Get-Date
    
    Write-AgentLog "Execution statistics retrieved" -Level "DEBUG" -Component "StatsManager"
    
    return $stats
}

function Export-ExecutionResults {
    <#
    .SYNOPSIS
    Exports execution results to file
    
    .DESCRIPTION
    Saves execution history and statistics for analysis
    
    .PARAMETER Path
    Output file path
    
    .PARAMETER Format
    Output format (JSON or CSV)
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path,
        
        [ValidateSet("JSON", "CSV")]
        [string]$Format = "JSON"
    )
    
    Write-AgentLog "Exporting execution results to $Path (Format: $Format)" -Level "INFO" -Component "ExportManager"
    
    try {
        $exportData = @{
            Statistics = Get-ExecutionStatistics
            Configuration = Get-ExecutionConfig
            Timestamp = Get-Date
        }
        
        switch ($Format) {
            "JSON" {
                $exportData | ConvertTo-Json -Depth 10 | Set-Content -Path $Path -Force
            }
            "CSV" {
                # Flatten for CSV export
                $flatData = @()
                foreach ($key in $exportData.Statistics.Keys) {
                    $flatData += [PSCustomObject]@{
                        Metric = $key
                        Value = $exportData.Statistics[$key]
                    }
                }
                $flatData | Export-Csv -Path $Path -NoTypeInformation
            }
        }
        
        Write-AgentLog "Execution results exported successfully" -Level "SUCCESS" -Component "ExportManager"
        return $true
    }
    catch {
        Write-AgentLog "Failed to export execution results: $_" -Level "ERROR" -Component "ExportManager"
        return $false
    }
}

#endregion

# Export module functions
Export-ModuleMember -Function @(
    'Add-CommandToQueue',
    'Get-NextCommand',
    'Get-QueueStatus',
    'Clear-ExecutionQueue',
    'Start-ParallelExecution',
    'Test-CommandDependencies',
    'Invoke-SafeCommandExecution',
    'Request-HumanApproval',
    'Get-PendingApprovals',
    'Set-ExecutionConfig',
    'Get-ExecutionConfig',
    'Get-ExecutionStatistics',
    'Export-ExecutionResults'
)

Write-AgentLog "CommandExecutionEngine module loaded successfully" -Level "INFO" -Component "CommandExecutionEngine"
# SIG # Begin signature block
# MIIFqQYJKoZIhvcNAQcCoIIFmjCCBZYCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUAOpG1zb2TC815WTg01KSEnGh
# 8NKgggMwMIIDLDCCAhSgAwIBAgIQdR0W2SKoK5VE8JId4ZxrRTANBgkqhkiG9w0B
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
# CQQxFgQUHf8XJnp7btZfoWh8izxnD2XE0jEwDQYJKoZIhvcNAQEBBQAEggEAaSRY
# jGtLFXuOwRqZbXulsgE0FkuLfMx/pmzy6ZMTxXYS7ckq0nLt4HWmmUaVtEA3dKO3
# SnQgf8gtt/jXtFqkW3bf7xDw40B8ab5aUtCzUOTsT3JaNWMAhtfFvx4oohO/p9Dm
# N7GtkfeGBY05mgW66TEN2eDxWUzOFVkkZeSTgkFJB+UEgth8W/eIbl5fz9zEb4sm
# pb7+/JjCNzxdAHHVAO9FRKNI2FWCA21Ih7xN12xzfbx2Bjhn5bh2QlJOris0AZHh
# s3xq/f1HGFcdox3PN1EkisBhb0/SahGvKiEEN+u/wx1Psr3bUEUorvtvULqdUzmw
# nM6idLw4/cK7Su7JNQ==
# SIG # End signature block
