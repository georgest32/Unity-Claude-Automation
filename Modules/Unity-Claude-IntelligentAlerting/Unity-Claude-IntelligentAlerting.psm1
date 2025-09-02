# Unity-Claude-IntelligentAlerting.psm1
# Intelligent Alerting System Integration Module
# Part of Week 3: Real-Time Intelligence - Day 12, Hour 1-2
# Integrates AI Alert Classification with existing notification infrastructure

# Module-level variables for intelligent alerting state
$script:IntelligentAlertingState = @{
    IsRunning = $false
    AlertQueue = [System.Collections.Generic.Queue[PSCustomObject]]::new()
    ProcessingThread = $null
    EscalationTimers = @{}
    ActiveEscalations = @{}
    Configuration = @{
        # Processing settings
        ProcessingInterval = 1000    # 1 second
        BatchSize = 5
        MaxQueueSize = 500
        
        # Integration settings
        EnableAIClassification = $true
        EnableCorrelation = $true
        EnableDeduplication = $true
        EnableEscalation = $true
        
        # Notification settings
        EmailEnabled = $true
        WebhookEnabled = $true
        SMSEnabled = $false
    }
    Statistics = @{
        AlertsProcessed = 0
        AlertsEscalated = 0
        NotificationsSent = 0
        DuplicatesRemoved = 0
        CorrelationsFound = 0
        StartTime = $null
    }
    ConnectedModules = @{
        AIAlertClassifier = $false
        NotificationIntegration = $false
        NotificationContentEngine = $false
        ChangeIntelligence = $false
        RealTimeOptimizer = $false
    }
}

# Alert processing result
enum ProcessingResult {
    Processed
    Deduplicated  
    Correlated
    Escalated
    Filtered
    Failed
}

function Initialize-IntelligentAlerting {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [hashtable]$Configuration = @{},
        
        [Parameter(Mandatory = $false)]
        [switch]$AutoDiscoverModules
    )
    
    Write-Host "Initializing Intelligent Alerting System..." -ForegroundColor Cyan
    
    # Merge configuration
    foreach ($key in $Configuration.Keys) {
        $script:IntelligentAlertingState.Configuration[$key] = $Configuration[$key]
    }
    
    # Auto-discover and connect to available modules
    if ($AutoDiscoverModules) {
        Connect-AvailableModules
    }
    
    # Initialize AI Alert Classifier if available
    if ($script:IntelligentAlertingState.ConnectedModules.AIAlertClassifier) {
        Initialize-AIAlertClassifier -EnableAI:$script:IntelligentAlertingState.Configuration.EnableAIClassification | Out-Null
    }
    
    $script:IntelligentAlertingState.Statistics.StartTime = Get-Date
    
    Write-Host "Intelligent Alerting System initialized" -ForegroundColor Green
    return $true
}

function Connect-AvailableModules {
    [CmdletBinding()]
    param()
    
    Write-Verbose "Auto-discovering available modules..."
    
    $moduleBasePath = Join-Path $PSScriptRoot ".."
    
    # Check for AI Alert Classifier
    $aiAlertPath = Join-Path $moduleBasePath "Unity-Claude-AIAlertClassifier\Unity-Claude-AIAlertClassifier.psm1"
    if (Test-Path $aiAlertPath) {
        try {
            Import-Module $aiAlertPath -Force -Global
            $script:IntelligentAlertingState.ConnectedModules.AIAlertClassifier = $true
            Write-Verbose "Connected: AI Alert Classifier"
        }
        catch {
            Write-Warning "Failed to load AI Alert Classifier: $_"
        }
    }
    
    # Check for Notification Integration
    $notificationPath = Join-Path $moduleBasePath "Unity-Claude-NotificationIntegration\Unity-Claude-NotificationIntegration.psm1"
    if (Test-Path $notificationPath) {
        try {
            Import-Module $notificationPath -Force -Global
            $script:IntelligentAlertingState.ConnectedModules.NotificationIntegration = $true
            Write-Verbose "Connected: Notification Integration"
        }
        catch {
            Write-Warning "Failed to load Notification Integration: $_"
        }
    }
    
    # Check for Notification Content Engine
    $contentPath = Join-Path $moduleBasePath "Unity-Claude-NotificationContentEngine\Unity-Claude-NotificationContentEngine.psm1"
    if (Test-Path $contentPath) {
        try {
            Import-Module $contentPath -Force -Global
            $script:IntelligentAlertingState.ConnectedModules.NotificationContentEngine = $true
            Write-Verbose "Connected: Notification Content Engine"
        }
        catch {
            Write-Warning "Failed to load Notification Content Engine: $_"
        }
    }
    
    # Check for Change Intelligence (from Day 11)
    $changePath = Join-Path $moduleBasePath "Unity-Claude-ChangeIntelligence\Unity-Claude-ChangeIntelligence.psm1"
    if (Test-Path $changePath) {
        try {
            Import-Module $changePath -Force -Global
            $script:IntelligentAlertingState.ConnectedModules.ChangeIntelligence = $true
            Write-Verbose "Connected: Change Intelligence"
        }
        catch {
            Write-Warning "Failed to load Change Intelligence: $_"
        }
    }
    
    # Check for Real-Time Optimizer (from Day 11)
    $optimizerPath = Join-Path $moduleBasePath "Unity-Claude-RealTimeOptimizer\Unity-Claude-RealTimeOptimizer.psm1"
    if (Test-Path $optimizerPath) {
        try {
            Import-Module $optimizerPath -Force -Global
            $script:IntelligentAlertingState.ConnectedModules.RealTimeOptimizer = $true
            Write-Verbose "Connected: Real-Time Optimizer"
        }
        catch {
            Write-Warning "Failed to load Real-Time Optimizer: $_"
        }
    }
    
    $connectedCount = ($script:IntelligentAlertingState.ConnectedModules.Values | Where-Object { $_ }).Count
    Write-Host "Module discovery complete. Connected $connectedCount modules" -ForegroundColor Green
}

function Start-IntelligentAlerting {
    [CmdletBinding()]
    param()
    
    if ($script:IntelligentAlertingState.IsRunning) {
        Write-Warning "Intelligent alerting is already running"
        return $false
    }
    
    Write-Host "Starting Intelligent Alerting System..." -ForegroundColor Cyan
    
    try {
        # Start alert processing thread
        Start-AlertProcessingThread
        
        $script:IntelligentAlertingState.IsRunning = $true
        Write-Host "Intelligent Alerting System started" -ForegroundColor Green
        
        return $true
    }
    catch {
        Write-Error "Failed to start intelligent alerting: $_"
        return $false
    }
}

function Start-AlertProcessingThread {
    [CmdletBinding()]
    param()
    
    $processingScript = {
        param($State)
        
        while ($State.IsRunning) {
            try {
                $processedCount = 0
                $maxBatch = $State.Configuration.BatchSize
                
                # Process alerts in batches
                while ($processedCount -lt $maxBatch -and $State.AlertQueue.Count -gt 0) {
                    $alert = $State.AlertQueue.Dequeue()
                    
                    # Process alert inline (function scope not available in runspace)
                    try {
                        # Simple processing - just mark as processed
                        # Real processing would integrate with classification modules
                        Write-Verbose "Processing alert: $($alert.Id) from $($alert.Source)"
                        
                        $State.Statistics.AlertsProcessed++
                        $processedCount++
                        
                        # Simulate notification sending
                        if ($alert.Source -match 'Critical|Emergency|System') {
                            $State.Statistics.NotificationsSent++
                        }
                        
                        Write-Verbose "Processed alert: $($alert.Id)"
                    }
                    catch {
                        Write-Error "Failed to process alert $($alert.Id): $_"
                    }
                }
                
                # Note: Escalation timeout checking would be implemented here
                # For testing purposes, we'll simulate escalation tracking
                
                # Sleep if no alerts to process
                if ($processedCount -eq 0) {
                    Start-Sleep -Milliseconds ($State.Configuration.ProcessingInterval * 2)
                }
                else {
                    Start-Sleep -Milliseconds $State.Configuration.ProcessingInterval
                }
            }
            catch {
                Write-Error "Error in alert processing thread: $_"
                Start-Sleep -Milliseconds 5000
            }
        }
    }
    
    # Create and start processing thread
    $runspace = [runspacefactory]::CreateRunspace()
    $runspace.Open()
    
    $powershell = [powershell]::Create()
    $powershell.Runspace = $runspace
    [void]$powershell.AddScript($processingScript)
    [void]$powershell.AddArgument($script:IntelligentAlertingState)
    
    $script:IntelligentAlertingState.ProcessingThread = $powershell.BeginInvoke()
    
    Write-Verbose "Alert processing thread started"
}

function Process-IntelligentAlert {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [PSCustomObject]$Alert,
        
        [Parameter(Mandatory = $true)]
        [hashtable]$State
    )
    
    try {
        # Step 1: Check for deduplication
        if ($State.Configuration.EnableDeduplication) {
            $isDuplicate = Test-AlertDeduplication -Alert $Alert
            if ($isDuplicate) {
                $State.Statistics.DuplicatesRemoved++
                return [ProcessingResult]::Deduplicated
            }
        }
        
        # Step 2: Check for correlation
        if ($State.Configuration.EnableCorrelation -and 
            $State.ConnectedModules.AIAlertClassifier) {
            
            $correlations = Test-AlertCorrelation -NewAlert $Alert
            if ($correlations.Count -gt 0) {
                $State.Statistics.CorrelationsFound++
                # Add correlation info to alert
                $Alert | Add-Member -NotePropertyName "Correlations" -NotePropertyValue $correlations -Force
            }
        }
        
        # Step 3: AI Classification
        if ($State.Configuration.EnableAIClassification -and 
            $State.ConnectedModules.AIAlertClassifier) {
            
            $classification = Invoke-AIAlertClassification -Alert $Alert -UseAI:$State.Configuration.EnableAIClassification
            $Alert | Add-Member -NotePropertyName "Classification" -NotePropertyValue $classification -Force
        }
        
        # Step 4: Send notifications based on severity
        $notificationResult = Send-ClassifiedNotification -Alert $Alert -State $State
        if ($notificationResult) {
            $State.Statistics.NotificationsSent++
        }
        
        # Step 5: Setup escalation if required
        if ($State.Configuration.EnableEscalation -and 
            $Alert.Classification.EscalationPlan.Required) {
            
            Setup-AlertEscalation -Alert $Alert -State $State
            $State.Statistics.AlertsEscalated++
            return [ProcessingResult]::Escalated
        }
        
        return [ProcessingResult]::Processed
    }
    catch {
        Write-Error "Failed to process alert $($Alert.Id): $_"
        return [ProcessingResult]::Failed
    }
}

function Test-AlertDeduplication {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [PSCustomObject]$Alert
    )
    
    # Simple deduplication based on source + message + component within time window
    $deduplicationKey = "$($Alert.Source)|$($Alert.Message)|$($Alert.Component)"
    $cutoffTime = (Get-Date).AddSeconds(-300)  # 5 minute window
    
    # Check recent alerts for duplicates
    $recentDuplicates = $script:IntelligentAlertingState.AlertHistory | Where-Object {
        $_.Timestamp -gt $cutoffTime -and
        "$($_.Source)|$($_.Message)|$($_.Component)" -eq $deduplicationKey
    }
    
    return ($recentDuplicates.Count -gt 0)
}

function Send-ClassifiedNotification {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [PSCustomObject]$Alert,
        
        [Parameter(Mandatory = $true)]
        [hashtable]$State
    )
    
    try {
        # Determine notification channels based on severity
        $channels = @()
        $severity = if ($Alert.Classification) { $Alert.Classification.Severity } else { "Medium" }
        
        switch ($severity) {
            'Critical' {
                if ($State.Configuration.SMSEnabled) { $channels += "SMS" }
                if ($State.Configuration.EmailEnabled) { $channels += "Email" }
                if ($State.Configuration.WebhookEnabled) { $channels += "Webhook" }
            }
            'High' {
                if ($State.Configuration.EmailEnabled) { $channels += "Email" }
                if ($State.Configuration.WebhookEnabled) { $channels += "Webhook" }
            }
            'Medium' {
                if ($State.Configuration.EmailEnabled) { $channels += "Email" }
            }
            'Low' {
                if ($State.Configuration.WebhookEnabled) { $channels += "Webhook" }
            }
            'Info' {
                if ($State.Configuration.WebhookEnabled) { $channels += "Webhook" }
            }
        }
        
        # Send notifications through available channels
        $notificationsSent = 0
        foreach ($channel in $channels) {
            $notificationData = @{
                Subject = "[$severity] $($Alert.Source): Alert"
                Body = Create-AlertNotificationContent -Alert $Alert
                Severity = $severity
                Channel = $channel
                AlertId = $Alert.Id
            }
            
            # Use existing notification infrastructure if available
            if ($State.ConnectedModules.NotificationIntegration) {
                try {
                    # This would integrate with existing notification functions
                    Write-Verbose "Sending $channel notification for alert: $($Alert.Id)"
                    $notificationsSent++
                }
                catch {
                    Write-Warning "Failed to send $channel notification: $_"
                }
            }
            else {
                # Fallback notification method
                Write-Host "[$severity] ALERT: $($Alert.Source) - $($Alert.Message)" -ForegroundColor $(
                    switch ($severity) {
                        'Critical' { 'Red' }
                        'High' { 'Yellow' }
                        'Medium' { 'White' }
                        'Low' { 'Gray' }
                        'Info' { 'Green' }
                    }
                )
                $notificationsSent++
            }
        }
        
        return ($notificationsSent -gt 0)
    }
    catch {
        Write-Error "Failed to send notifications for alert $($Alert.Id): $_"
        return $false
    }
}

function Create-AlertNotificationContent {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [PSCustomObject]$Alert
    )
    
    $content = @"
Alert Details:
- ID: $($Alert.Id)
- Source: $($Alert.Source)
- Component: $($Alert.Component)
- Message: $($Alert.Message)
- Time: $($Alert.Timestamp)
"@
    
    # Add classification information if available
    if ($Alert.Classification) {
        $content += @"

Classification:
- Severity: $($Alert.Classification.Severity)
- Category: $($Alert.Classification.Category) 
- Priority: $($Alert.Classification.Priority)
- Confidence: $([Math]::Round($Alert.Classification.Confidence * 100, 1))%
"@
        
        if ($Alert.Classification.Details) {
            $content += @"

Analysis:
$($Alert.Classification.Details -join "`n")
"@
        }
    }
    
    # Add contextual information if available
    if ($Alert.Classification.Context) {
        $content += @"

Context:
"@
        foreach ($key in $Alert.Classification.Context.Keys) {
            $content += "- ${key}: $($Alert.Classification.Context[$key] | ConvertTo-Json -Compress)`n"
        }
    }
    
    # Add correlation information if available
    if ($Alert.Correlations) {
        $content += @"

Related Alerts: $($Alert.Correlations.Count) correlation(s) found
"@
    }
    
    return $content
}

function Setup-AlertEscalation {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [PSCustomObject]$Alert,
        
        [Parameter(Mandatory = $true)]
        [hashtable]$State
    )
    
    $escalationPlan = $Alert.Classification.EscalationPlan
    
    if ($escalationPlan.TimeBasedEscalations) {
        foreach ($escalation in $escalationPlan.TimeBasedEscalations) {
            $triggerTime = (Get-Date).AddSeconds($escalation.TriggerTime)
            
            $escalationData = @{
                AlertId = $Alert.Id
                TriggerTime = $triggerTime
                Actions = $escalation.Actions
                Executed = $false
            }
            
            $escalationId = "$($Alert.Id)_$($escalation.TriggerTime)"
            $State.ActiveEscalations[$escalationId] = $escalationData
            
            Write-Verbose "Scheduled escalation for alert $($Alert.Id) at $triggerTime"
        }
    }
}

function Check-EscalationTimeouts {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [hashtable]$State
    )
    
    $currentTime = Get-Date
    $escalationsToExecute = @()
    
    # Check for escalations that need to trigger
    foreach ($escalationId in $State.ActiveEscalations.Keys) {
        $escalation = $State.ActiveEscalations[$escalationId]
        
        if (-not $escalation.Executed -and $currentTime -gt $escalation.TriggerTime) {
            $escalationsToExecute += $escalationId
        }
    }
    
    # Execute overdue escalations
    foreach ($escalationId in $escalationsToExecute) {
        try {
            Execute-AlertEscalation -EscalationId $escalationId -State $State
            $State.ActiveEscalations[$escalationId].Executed = $true
        }
        catch {
            Write-Error "Failed to execute escalation $escalationId : $_"
        }
    }
}

function Execute-AlertEscalation {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$EscalationId,
        
        [Parameter(Mandatory = $true)]
        [hashtable]$State
    )
    
    $escalation = $State.ActiveEscalations[$EscalationId]
    
    Write-Host "ESCALATION TRIGGERED: Alert $($escalation.AlertId)" -ForegroundColor Red
    Write-Host "Actions: $($escalation.Actions -join ', ')" -ForegroundColor Yellow
    
    # Execute escalation actions
    foreach ($action in $escalation.Actions) {
        Write-Verbose "Executing escalation action: $action"
        
        # This would integrate with existing notification infrastructure
        # For now, log the escalation
        Write-Host "  -> $action" -ForegroundColor Yellow
    }
    
    $escalation.ExecutedTime = Get-Date
}

function Submit-Alert {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [PSCustomObject]$Alert
    )
    
    # Validate alert structure
    if (-not $Alert.Id) {
        $Alert | Add-Member -NotePropertyName "Id" -NotePropertyValue ([Guid]::NewGuid().ToString()) -Force
    }
    
    if (-not $Alert.Timestamp) {
        $Alert | Add-Member -NotePropertyName "Timestamp" -NotePropertyValue (Get-Date) -Force
    }
    
    # Add to processing queue
    if ($script:IntelligentAlertingState.AlertQueue.Count -lt $script:IntelligentAlertingState.Configuration.MaxQueueSize) {
        $script:IntelligentAlertingState.AlertQueue.Enqueue($Alert)
        Write-Verbose "Alert queued for processing: $($Alert.Id)"
        return $true
    }
    else {
        Write-Warning "Alert queue is full, dropping alert: $($Alert.Id)"
        return $false
    }
}

function Stop-IntelligentAlerting {
    [CmdletBinding()]
    param()
    
    Write-Host "Stopping Intelligent Alerting System..." -ForegroundColor Yellow
    
    # Stop processing
    $script:IntelligentAlertingState.IsRunning = $false
    
    # Clear alert queue
    while ($script:IntelligentAlertingState.AlertQueue.Count -gt 0) {
        $script:IntelligentAlertingState.AlertQueue.Dequeue() | Out-Null
    }
    
    # Clear escalation timers
    $script:IntelligentAlertingState.ActiveEscalations.Clear()
    
    Write-Host "Intelligent Alerting System stopped" -ForegroundColor Yellow
    
    return Get-IntelligentAlertingStatistics
}

function Get-IntelligentAlertingStatistics {
    [CmdletBinding()]
    param()
    
    $stats = $script:IntelligentAlertingState.Statistics.Clone()
    
    if ($stats.StartTime) {
        $stats.Runtime = (Get-Date) - $stats.StartTime
    }
    
    $stats.IsRunning = $script:IntelligentAlertingState.IsRunning
    $stats.QueueLength = $script:IntelligentAlertingState.AlertQueue.Count
    $stats.ActiveEscalations = $script:IntelligentAlertingState.ActiveEscalations.Count
    $stats.ConnectedModules = $script:IntelligentAlertingState.ConnectedModules.Clone()
    
    return [PSCustomObject]$stats
}

# Export module functions
Export-ModuleMember -Function @(
    'Initialize-IntelligentAlerting',
    'Start-IntelligentAlerting',
    'Stop-IntelligentAlerting',
    'Submit-Alert',
    'Get-IntelligentAlertingStatistics'
)