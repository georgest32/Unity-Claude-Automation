function Initialize-NotificationReliabilitySystem {
    <#
    .SYNOPSIS
    Initializes enhanced reliability system with circuit breakers, dead letter queues, and fallback mechanisms
    
    .DESCRIPTION
    Implements comprehensive notification reliability infrastructure including:
    - Enhanced circuit breaker patterns with state management
    - Dead letter queue for failed notification persistence
    - Multi-channel fallback mechanisms
    - Exponential backoff with jitter for retry logic
    - Performance monitoring and reliability metrics
    
    .PARAMETER Configuration
    Notification configuration object
    
    .PARAMETER EnableDeadLetterQueue
    Enable dead letter queue for failed notifications
    
    .PARAMETER MaxRetryAttempts
    Maximum retry attempts before moving to dead letter queue (default: 3)
    
    .EXAMPLE
    Initialize-NotificationReliabilitySystem -Configuration $config
    #>
    [CmdletBinding()]
    param(
        [hashtable]$Configuration,
        [switch]$EnableDeadLetterQueue = $true,
        [int]$MaxRetryAttempts = 3
    )
    
    Write-SystemStatusLog "Initializing notification reliability system" -Level 'INFO'
    
    try {
        # Initialize circuit breaker state management
        $script:CircuitBreakerState = @{
            Email = @{
                State = "Closed"  # Closed, Open, HalfOpen
                FailureCount = 0
                LastFailureTime = $null
                SuccessCount = 0
                LastSuccessTime = $null
                FailureThreshold = 5
                RecoveryTimeoutSeconds = 300
                HalfOpenTestCount = 0
                MaxHalfOpenTests = 3
            }
            Webhook = @{
                State = "Closed"
                FailureCount = 0
                LastFailureTime = $null
                SuccessCount = 0
                LastSuccessTime = $null
                FailureThreshold = 5
                RecoveryTimeoutSeconds = 300
                HalfOpenTestCount = 0
                MaxHalfOpenTests = 3
            }
        }
        
        # Initialize dead letter queue
        if ($EnableDeadLetterQueue) {
            $script:DeadLetterQueue = @{
                Enabled = $true
                MaxRetryAttempts = $MaxRetryAttempts
                QueuedNotifications = @()
                ProcessingEnabled = $true
                RetryIntervalSeconds = 60
                ExponentialBackoffMultiplier = 2
                MaxBackoffSeconds = 3600  # 1 hour
                LastProcessingTime = $null
            }
            
            Write-SystemStatusLog "Dead letter queue initialized with max $MaxRetryAttempts retry attempts" -Level 'DEBUG'
        }
        
        # Initialize reliability metrics tracking
        $script:ReliabilityMetrics = @{
            StartTime = Get-Date
            EmailNotifications = @{
                TotalAttempts = 0
                Successes = 0
                Failures = 0
                CircuitBreakerActivations = 0
                FallbackActivations = 0
                AverageResponseTime = 0
                ResponseTimes = @()
            }
            WebhookNotifications = @{
                TotalAttempts = 0
                Successes = 0
                Failures = 0
                CircuitBreakerActivations = 0
                FallbackActivations = 0
                AverageResponseTime = 0
                ResponseTimes = @()
            }
            DeadLetterQueue = @{
                MessagesAdded = 0
                MessagesProcessed = 0
                MessagesRecovered = 0
                MessagesPermanentlyFailed = 0
            }
        }
        
        # Initialize fallback channel configuration
        $script:FallbackChannels = @{
            Primary = @()
            Secondary = @()
            Emergency = @()
        }
        
        # Configure fallback channels based on enabled services
        if ($Configuration.EmailNotifications.Enabled) {
            $script:FallbackChannels.Primary += "Email"
        }
        if ($Configuration.WebhookNotifications.Enabled) {
            if ($script:FallbackChannels.Primary.Count -eq 0) {
                $script:FallbackChannels.Primary += "Webhook"
            } else {
                $script:FallbackChannels.Secondary += "Webhook"
            }
        }
        
        Write-SystemStatusLog "Notification reliability system initialized successfully" -Level 'INFO'
        Write-SystemStatusLog "Primary channels: $($script:FallbackChannels.Primary -join ', ')" -Level 'DEBUG'
        Write-SystemStatusLog "Secondary channels: $($script:FallbackChannels.Secondary -join ', ')" -Level 'DEBUG'
        
        return @{
            Success = $true
            CircuitBreakerEnabled = $true
            DeadLetterQueueEnabled = $EnableDeadLetterQueue
            FallbackChannelsConfigured = ($script:FallbackChannels.Primary.Count + $script:FallbackChannels.Secondary.Count)
            MaxRetryAttempts = $MaxRetryAttempts
        }
        
    } catch {
        $errorMessage = "Failed to initialize notification reliability system: $($_.Exception.Message)"
        Write-SystemStatusLog $errorMessage -Level 'ERROR'
        throw $_
    }
}

function Test-CircuitBreakerState {
    <#
    .SYNOPSIS
    Tests and updates circuit breaker state for notification channels
    
    .DESCRIPTION
    Implements circuit breaker pattern for notification reliability:
    - Closed: Normal operation, monitor for failures
    - Open: Failures exceed threshold, block requests temporarily
    - HalfOpen: Test recovery with limited requests
    
    .PARAMETER Channel
    Notification channel to test (Email, Webhook)
    
    .PARAMETER OperationResult
    Result of the last notification operation (Success, Failure)
    
    .EXAMPLE
    Test-CircuitBreakerState -Channel "Email" -OperationResult "Success"
    #>
    [CmdletBinding()]
    param(
        [ValidateSet("Email", "Webhook")]
        [string]$Channel,
        [ValidateSet("Success", "Failure")]
        [string]$OperationResult
    )
    
    Write-SystemStatusLog "Testing circuit breaker state for $Channel channel: $OperationResult" -Level 'DEBUG'
    
    try {
        $circuitBreaker = $script:CircuitBreakerState[$Channel]
        $currentTime = Get-Date
        
        # Update circuit breaker based on operation result
        switch ($OperationResult) {
            "Success" {
                $circuitBreaker.SuccessCount++
                $circuitBreaker.LastSuccessTime = $currentTime
                
                # Handle state transitions on success
                switch ($circuitBreaker.State) {
                    "Closed" {
                        # Reset failure count on success in closed state
                        $circuitBreaker.FailureCount = 0
                    }
                    "HalfOpen" {
                        $circuitBreaker.HalfOpenTestCount++
                        
                        # If enough successful tests in half-open, transition to closed
                        if ($circuitBreaker.HalfOpenTestCount -ge $circuitBreaker.MaxHalfOpenTests) {
                            $circuitBreaker.State = "Closed"
                            $circuitBreaker.FailureCount = 0
                            $circuitBreaker.HalfOpenTestCount = 0
                            Write-SystemStatusLog "Circuit breaker for $Channel transitioned from HalfOpen to Closed" -Level 'INFO'
                        }
                    }
                }
            }
            "Failure" {
                $circuitBreaker.FailureCount++
                $circuitBreaker.LastFailureTime = $currentTime
                
                # Handle state transitions on failure
                switch ($circuitBreaker.State) {
                    "Closed" {
                        # Check if failure threshold exceeded
                        if ($circuitBreaker.FailureCount -ge $circuitBreaker.FailureThreshold) {
                            $circuitBreaker.State = "Open"
                            $script:ReliabilityMetrics["$($Channel)Notifications"].CircuitBreakerActivations++
                            Write-SystemStatusLog "Circuit breaker for $Channel opened due to failure threshold exceeded ($($circuitBreaker.FailureCount) failures)" -Level 'WARN'
                        }
                    }
                    "HalfOpen" {
                        # Failure in half-open state returns to open
                        $circuitBreaker.State = "Open"
                        $circuitBreaker.HalfOpenTestCount = 0
                        Write-SystemStatusLog "Circuit breaker for $Channel returned to Open state due to failure in HalfOpen" -Level 'WARN'
                    }
                }
            }
        }
        
        # Check for automatic recovery from Open to HalfOpen
        if ($circuitBreaker.State -eq "Open" -and $circuitBreaker.LastFailureTime) {
            $timeSinceLastFailure = ($currentTime - $circuitBreaker.LastFailureTime).TotalSeconds
            if ($timeSinceLastFailure -ge $circuitBreaker.RecoveryTimeoutSeconds) {
                $circuitBreaker.State = "HalfOpen"
                $circuitBreaker.HalfOpenTestCount = 0
                Write-SystemStatusLog "Circuit breaker for $Channel transitioned from Open to HalfOpen for recovery testing" -Level 'INFO'
            }
        }
        
        return @{
            Channel = $Channel
            State = $circuitBreaker.State
            FailureCount = $circuitBreaker.FailureCount
            SuccessCount = $circuitBreaker.SuccessCount
            AllowOperation = ($circuitBreaker.State -ne "Open")
            LastStateChange = $currentTime
        }
        
    } catch {
        Write-SystemStatusLog "Error testing circuit breaker state for $Channel : $($_.Exception.Message)" -Level 'ERROR'
        throw $_
    }
}

function Add-NotificationToDeadLetterQueue {
    <#
    .SYNOPSIS
    Adds failed notification to dead letter queue for retry processing
    
    .DESCRIPTION
    Implements dead letter queue pattern for failed notifications:
    - Persists failed notifications with retry metadata
    - Tracks retry attempts and exponential backoff timing
    - Supports manual intervention and replay capabilities
    
    .PARAMETER NotificationData
    Failed notification data including content and delivery details
    
    .PARAMETER Channel
    Notification channel that failed (Email, Webhook)
    
    .PARAMETER FailureReason
    Reason for the notification failure
    
    .EXAMPLE
    Add-NotificationToDeadLetterQueue -NotificationData $notification -Channel "Email" -FailureReason "SMTP Authentication Failed"
    #>
    [CmdletBinding()]
    param(
        [hashtable]$NotificationData,
        [ValidateSet("Email", "Webhook")]
        [string]$Channel,
        [string]$FailureReason
    )
    
    Write-SystemStatusLog "Adding failed notification to dead letter queue: $Channel - $FailureReason" -Level 'WARN'
    
    try {
        if (-not $script:DeadLetterQueue.Enabled) {
            Write-SystemStatusLog "Dead letter queue is disabled, notification will be discarded" -Level 'WARN'
            return $false
        }
        
        # Create dead letter queue entry
        $dlqEntry = @{
            Id = [System.Guid]::NewGuid().ToString()
            Channel = $Channel
            OriginalNotificationData = $NotificationData
            FailureReason = $FailureReason
            FirstFailureTime = Get-Date
            LastAttemptTime = Get-Date
            AttemptCount = 1
            MaxRetryAttempts = $script:DeadLetterQueue.MaxRetryAttempts
            NextRetryTime = (Get-Date).AddSeconds($script:DeadLetterQueue.RetryIntervalSeconds)
            BackoffMultiplier = 1
            Status = "Queued"  # Queued, Retrying, Failed, Recovered
            CreatedBy = "NotificationReliabilitySystem"
        }
        
        # Add to dead letter queue
        $script:DeadLetterQueue.QueuedNotifications += $dlqEntry
        $script:ReliabilityMetrics.DeadLetterQueue.MessagesAdded++
        
        Write-SystemStatusLog "Notification added to dead letter queue: ID $($dlqEntry.Id)" -Level 'DEBUG'
        Write-SystemStatusLog "Dead letter queue size: $($script:DeadLetterQueue.QueuedNotifications.Count) messages" -Level 'DEBUG'
        
        # Trigger immediate processing if queue processor is not running
        if ($script:DeadLetterQueue.ProcessingEnabled) {
            Start-DeadLetterQueueProcessor
        }
        
        return @{
            Success = $true
            QueueId = $dlqEntry.Id
            NextRetryTime = $dlqEntry.NextRetryTime
            QueueLength = $script:DeadLetterQueue.QueuedNotifications.Count
        }
        
    } catch {
        Write-SystemStatusLog "Error adding notification to dead letter queue: $($_.Exception.Message)" -Level 'ERROR'
        throw $_
    }
}

function Start-DeadLetterQueueProcessor {
    <#
    .SYNOPSIS
    Starts dead letter queue processor for automatic retry of failed notifications
    
    .DESCRIPTION
    Implements background processing of dead letter queue with:
    - Exponential backoff retry scheduling
    - Automatic retry attempt management
    - Circuit breaker integration for retry decisions
    - Permanent failure handling after max attempts
    
    .EXAMPLE
    Start-DeadLetterQueueProcessor
    #>
    [CmdletBinding()]
    param()
    
    Write-SystemStatusLog "Starting dead letter queue processor" -Level 'INFO'
    
    try {
        if (-not $script:DeadLetterQueue.Enabled) {
            Write-SystemStatusLog "Dead letter queue is disabled, processor not started" -Level 'WARN'
            return
        }
        
        $currentTime = Get-Date
        $processedCount = 0
        $recoveredCount = 0
        $permanentFailureCount = 0
        
        # Process queued notifications ready for retry
        $readyForRetry = $script:DeadLetterQueue.QueuedNotifications | Where-Object { 
            $_.Status -eq "Queued" -and $_.NextRetryTime -le $currentTime 
        }
        
        foreach ($dlqEntry in $readyForRetry) {
            try {
                Write-SystemStatusLog "Processing dead letter queue entry: $($dlqEntry.Id)" -Level 'DEBUG'
                
                # Check if max retry attempts exceeded
                if ($dlqEntry.AttemptCount -ge $dlqEntry.MaxRetryAttempts) {
                    $dlqEntry.Status = "Failed"
                    $script:ReliabilityMetrics.DeadLetterQueue.MessagesPermanentlyFailed++
                    $permanentFailureCount++
                    Write-SystemStatusLog "Notification permanently failed after $($dlqEntry.AttemptCount) attempts: $($dlqEntry.Id)" -Level 'ERROR'
                    continue
                }
                
                # Check circuit breaker before attempting retry
                $circuitBreakerState = Test-CircuitBreakerState -Channel $dlqEntry.Channel -OperationResult "Success"  # Test current state
                if (-not $circuitBreakerState.AllowOperation) {
                    Write-SystemStatusLog "Circuit breaker open for $($dlqEntry.Channel), skipping retry for: $($dlqEntry.Id)" -Level 'DEBUG'
                    continue
                }
                
                # Update attempt count and timing
                $dlqEntry.AttemptCount++
                $dlqEntry.LastAttemptTime = $currentTime
                $dlqEntry.Status = "Retrying"
                
                # Attempt notification delivery
                $retryResult = $null
                switch ($dlqEntry.Channel) {
                    "Email" {
                        try {
                            $retryResult = Retry-EmailNotificationDelivery -NotificationData $dlqEntry.OriginalNotificationData
                        } catch {
                            $retryResult = @{ Success = $false; Error = $_.Exception.Message }
                        }
                    }
                    "Webhook" {
                        try {
                            $retryResult = Retry-WebhookNotificationDelivery -NotificationData $dlqEntry.OriginalNotificationData
                        } catch {
                            $retryResult = @{ Success = $false; Error = $_.Exception.Message }
                        }
                    }
                }
                
                if ($retryResult.Success) {
                    # Successful retry
                    $dlqEntry.Status = "Recovered"
                    $script:ReliabilityMetrics.DeadLetterQueue.MessagesRecovered++
                    $recoveredCount++
                    
                    # Update circuit breaker with success
                    Test-CircuitBreakerState -Channel $dlqEntry.Channel -OperationResult "Success" | Out-Null
                    
                    Write-SystemStatusLog "Notification successfully recovered from dead letter queue: $($dlqEntry.Id)" -Level 'INFO'
                } else {
                    # Failed retry - calculate next retry time with exponential backoff
                    $baseDelay = $script:DeadLetterQueue.RetryIntervalSeconds
                    $backoffDelay = $baseDelay * [math]::Pow($script:DeadLetterQueue.ExponentialBackoffMultiplier, $dlqEntry.AttemptCount - 1)
                    $maxDelay = $script:DeadLetterQueue.MaxBackoffSeconds
                    $actualDelay = [math]::Min($backoffDelay, $maxDelay)
                    
                    # Add jitter (randomize ±25% to prevent thundering herd)
                    $jitterRange = $actualDelay * 0.25
                    $jitter = (Get-Random -Minimum (-$jitterRange) -Maximum $jitterRange)
                    $finalDelay = [math]::Max(1, $actualDelay + $jitter)
                    
                    $dlqEntry.NextRetryTime = $currentTime.AddSeconds($finalDelay)
                    $dlqEntry.Status = "Queued"
                    $dlqEntry.BackoffMultiplier = $dlqEntry.AttemptCount
                    
                    # Update circuit breaker with failure
                    Test-CircuitBreakerState -Channel $dlqEntry.Channel -OperationResult "Failure" | Out-Null
                    
                    Write-SystemStatusLog "Notification retry failed, rescheduled for: $($dlqEntry.NextRetryTime) (attempt $($dlqEntry.AttemptCount)/$($dlqEntry.MaxRetryAttempts))" -Level 'DEBUG'
                }
                
                $processedCount++
                
            } catch {
                Write-SystemStatusLog "Error processing dead letter queue entry $($dlqEntry.Id): $($_.Exception.Message)" -Level 'ERROR'
                $dlqEntry.Status = "Queued"  # Reset to queued for next processing cycle
            }
        }
        
        # Update last processing time
        $script:DeadLetterQueue.LastProcessingTime = $currentTime
        $script:ReliabilityMetrics.DeadLetterQueue.MessagesProcessed += $processedCount
        
        if ($processedCount -gt 0) {
            Write-SystemStatusLog "Dead letter queue processor completed: $processedCount processed, $recoveredCount recovered, $permanentFailureCount permanently failed" -Level 'INFO'
        }
        
        return @{
            ProcessedCount = $processedCount
            RecoveredCount = $recoveredCount
            PermanentFailureCount = $permanentFailureCount
            QueueLength = $script:DeadLetterQueue.QueuedNotifications.Count
        }
        
    } catch {
        Write-SystemStatusLog "Error in dead letter queue processor: $($_.Exception.Message)" -Level 'ERROR'
        throw $_
    }
}

function Invoke-FallbackNotificationDelivery {
    <#
    .SYNOPSIS
    Implements fallback notification delivery using alternative channels
    
    .DESCRIPTION
    Implements multi-channel fallback strategy:
    - Attempts delivery through primary channel
    - Falls back to secondary channels on failure
    - Tracks fallback activations and success rates
    - Integrates with circuit breaker patterns
    
    .PARAMETER NotificationData
    Notification data to deliver
    
    .PARAMETER PreferredChannel
    Preferred delivery channel (Email, Webhook, Auto)
    
    .EXAMPLE
    Invoke-FallbackNotificationDelivery -NotificationData $notification -PreferredChannel "Auto"
    #>
    [CmdletBinding()]
    param(
        [hashtable]$NotificationData,
        [ValidateSet("Email", "Webhook", "Auto")]
        [string]$PreferredChannel = "Auto"
    )
    
    Write-SystemStatusLog "Initiating fallback notification delivery" -Level 'DEBUG'
    
    try {
        $deliveryResults = @()
        $finalResult = @{
            Success = $false
            Channel = $null
            FallbackUsed = $false
            DeliveryTime = $null
            Error = $null
        }
        
        # Determine channel priority order
        $channelOrder = @()
        if ($PreferredChannel -eq "Auto") {
            $channelOrder = $script:FallbackChannels.Primary + $script:FallbackChannels.Secondary
        } else {
            $channelOrder = @($PreferredChannel)
            # Add other channels as fallback
            $otherChannels = @("Email", "Webhook") | Where-Object { $_ -ne $PreferredChannel }
            $channelOrder += $otherChannels
        }
        
        # Remove channels that are not enabled
        $enabledChannels = @()
        foreach ($channel in $channelOrder) {
            switch ($channel) {
                "Email" { if ($script:NotificationIntegrationConfig.EmailEnabled) { $enabledChannels += $channel } }
                "Webhook" { if ($script:NotificationIntegrationConfig.WebhookEnabled) { $enabledChannels += $channel } }
            }
        }
        
        Write-SystemStatusLog "Fallback delivery order: $($enabledChannels -join ' -> ')" -Level 'DEBUG'
        
        # Attempt delivery through each channel in order
        foreach ($channel in $enabledChannels) {
            $deliveryStart = Get-Date
            
            # Check circuit breaker before attempting delivery
            $circuitBreakerState = Test-CircuitBreakerState -Channel $channel -OperationResult "Success"  # Check current state
            if (-not $circuitBreakerState.AllowOperation) {
                Write-SystemStatusLog "Circuit breaker open for $channel, skipping delivery attempt" -Level 'WARN'
                $deliveryResults += @{
                    Channel = $channel
                    Success = $false
                    Error = "Circuit breaker open"
                    Skipped = $true
                }
                continue
            }
            
            try {
                $deliveryResult = $null
                
                switch ($channel) {
                    "Email" {
                        $deliveryResult = Send-EmailNotificationWithReliability -NotificationData $NotificationData
                    }
                    "Webhook" {
                        $deliveryResult = Send-WebhookNotificationWithReliability -NotificationData $NotificationData
                    }
                }
                
                $deliveryEnd = Get-Date
                $deliveryTime = ($deliveryEnd - $deliveryStart).TotalMilliseconds
                
                if ($deliveryResult.Success) {
                    # Successful delivery
                    $finalResult.Success = $true
                    $finalResult.Channel = $channel
                    $finalResult.DeliveryTime = $deliveryTime
                    $finalResult.FallbackUsed = ($deliveryResults.Count -gt 0)
                    
                    # Update circuit breaker with success
                    Test-CircuitBreakerState -Channel $channel -OperationResult "Success" | Out-Null
                    
                    # Update metrics
                    $script:ReliabilityMetrics["$($channel)Notifications"].TotalAttempts++
                    $script:ReliabilityMetrics["$($channel)Notifications"].Successes++
                    $script:ReliabilityMetrics["$($channel)Notifications"].ResponseTimes += $deliveryTime
                    
                    if ($finalResult.FallbackUsed) {
                        $script:ReliabilityMetrics["$($channel)Notifications"].FallbackActivations++
                    }
                    
                    $deliveryResults += @{
                        Channel = $channel
                        Success = $true
                        DeliveryTime = $deliveryTime
                        Details = $deliveryResult.Details
                    }
                    
                    Write-SystemStatusLog "Notification delivered successfully via $channel in $([math]::Round($deliveryTime, 2))ms" -Level 'INFO'
                    break  # Stop trying other channels on success
                } else {
                    # Failed delivery
                    $deliveryResults += @{
                        Channel = $channel
                        Success = $false
                        Error = $deliveryResult.Error
                        DeliveryTime = $deliveryTime
                    }
                    
                    # Update circuit breaker with failure
                    Test-CircuitBreakerState -Channel $channel -OperationResult "Failure" | Out-Null
                    
                    # Update metrics
                    $script:ReliabilityMetrics["$($channel)Notifications"].TotalAttempts++
                    $script:ReliabilityMetrics["$($channel)Notifications"].Failures++
                    
                    Write-SystemStatusLog "Notification delivery failed via $channel : $($deliveryResult.Error)" -Level 'WARN'
                }
                
            } catch {
                $deliveryResults += @{
                    Channel = $channel
                    Success = $false
                    Error = $_.Exception.Message
                    DeliveryTime = ($deliveryEnd - $deliveryStart).TotalMilliseconds
                }
                
                # Update circuit breaker with failure
                Test-CircuitBreakerState -Channel $channel -OperationResult "Failure" | Out-Null
                
                Write-SystemStatusLog "Exception during $channel delivery: $($_.Exception.Message)" -Level 'ERROR'
            }
        }
        
        # If all channels failed, add to dead letter queue
        if (-not $finalResult.Success) {
            $finalResult.Error = "All delivery channels failed: $(($deliveryResults | ForEach-Object { "$($_.Channel): $($_.Error)" }) -join '; ')"
            
            Add-NotificationToDeadLetterQueue -NotificationData $NotificationData -Channel "Multiple" -FailureReason $finalResult.Error
        }
        
        return $finalResult
        
    } catch {
        Write-SystemStatusLog "Error in fallback notification delivery: $($_.Exception.Message)" -Level 'ERROR'
        throw $_
    }
}

function Get-NotificationReliabilityMetrics {
    <#
    .SYNOPSIS
    Retrieves comprehensive reliability metrics for the notification system
    
    .DESCRIPTION
    Provides detailed reliability metrics including:
    - Success rates by channel
    - Circuit breaker activation counts
    - Dead letter queue statistics
    - Performance metrics and response times
    - Overall system reliability score
    
    .EXAMPLE
    Get-NotificationReliabilityMetrics
    #>
    [CmdletBinding()]
    param()
    
    try {
        # Calculate average response times
        if ($script:ReliabilityMetrics.EmailNotifications.ResponseTimes.Count -gt 0) {
            $script:ReliabilityMetrics.EmailNotifications.AverageResponseTime = ($script:ReliabilityMetrics.EmailNotifications.ResponseTimes | Measure-Object -Average).Average
        }
        
        if ($script:ReliabilityMetrics.WebhookNotifications.ResponseTimes.Count -gt 0) {
            $script:ReliabilityMetrics.WebhookNotifications.AverageResponseTime = ($script:ReliabilityMetrics.WebhookNotifications.ResponseTimes | Measure-Object -Average).Average
        }
        
        # Calculate overall success rates
        $emailSuccessRate = if ($script:ReliabilityMetrics.EmailNotifications.TotalAttempts -gt 0) {
            ($script:ReliabilityMetrics.EmailNotifications.Successes / $script:ReliabilityMetrics.EmailNotifications.TotalAttempts) * 100
        } else { 0 }
        
        $webhookSuccessRate = if ($script:ReliabilityMetrics.WebhookNotifications.TotalAttempts -gt 0) {
            ($script:ReliabilityMetrics.WebhookNotifications.Successes / $script:ReliabilityMetrics.WebhookNotifications.TotalAttempts) * 100
        } else { 0 }
        
        # Calculate overall system reliability score
        $totalAttempts = $script:ReliabilityMetrics.EmailNotifications.TotalAttempts + $script:ReliabilityMetrics.WebhookNotifications.TotalAttempts
        $totalSuccesses = $script:ReliabilityMetrics.EmailNotifications.Successes + $script:ReliabilityMetrics.WebhookNotifications.Successes
        $overallSuccessRate = if ($totalAttempts -gt 0) { ($totalSuccesses / $totalAttempts) * 100 } else { 0 }
        
        $reliabilityReport = @{
            SystemStatus = @{
                OverallSuccessRate = [math]::Round($overallSuccessRate, 2)
                TotalDeliveryAttempts = $totalAttempts
                TotalSuccessfulDeliveries = $totalSuccesses
                TotalFailedDeliveries = $totalAttempts - $totalSuccesses
                SystemUptime = ((Get-Date) - $script:ReliabilityMetrics.StartTime).TotalMinutes
                LastUpdated = Get-Date
            }
            EmailNotifications = @{
                SuccessRate = [math]::Round($emailSuccessRate, 2)
                TotalAttempts = $script:ReliabilityMetrics.EmailNotifications.TotalAttempts
                Successes = $script:ReliabilityMetrics.EmailNotifications.Successes
                Failures = $script:ReliabilityMetrics.EmailNotifications.Failures
                AverageResponseTime = [math]::Round($script:ReliabilityMetrics.EmailNotifications.AverageResponseTime, 2)
                CircuitBreakerActivations = $script:ReliabilityMetrics.EmailNotifications.CircuitBreakerActivations
                FallbackActivations = $script:ReliabilityMetrics.EmailNotifications.FallbackActivations
                CurrentCircuitBreakerState = $script:CircuitBreakerState.Email.State
            }
            WebhookNotifications = @{
                SuccessRate = [math]::Round($webhookSuccessRate, 2)
                TotalAttempts = $script:ReliabilityMetrics.WebhookNotifications.TotalAttempts
                Successes = $script:ReliabilityMetrics.WebhookNotifications.Successes
                Failures = $script:ReliabilityMetrics.WebhookNotifications.Failures
                AverageResponseTime = [math]::Round($script:ReliabilityMetrics.WebhookNotifications.AverageResponseTime, 2)
                CircuitBreakerActivations = $script:ReliabilityMetrics.WebhookNotifications.CircuitBreakerActivations
                FallbackActivations = $script:ReliabilityMetrics.WebhookNotifications.FallbackActivations
                CurrentCircuitBreakerState = $script:CircuitBreakerState.Webhook.State
            }
            DeadLetterQueue = @{
                Enabled = $script:DeadLetterQueue.Enabled
                QueueLength = $script:DeadLetterQueue.QueuedNotifications.Count
                MessagesAdded = $script:ReliabilityMetrics.DeadLetterQueue.MessagesAdded
                MessagesProcessed = $script:ReliabilityMetrics.DeadLetterQueue.MessagesProcessed
                MessagesRecovered = $script:ReliabilityMetrics.DeadLetterQueue.MessagesRecovered
                MessagesPermanentlyFailed = $script:ReliabilityMetrics.DeadLetterQueue.MessagesPermanentlyFailed
                LastProcessingTime = $script:DeadLetterQueue.LastProcessingTime
            }
            CircuitBreakers = @{
                EmailState = $script:CircuitBreakerState.Email.State
                EmailFailureCount = $script:CircuitBreakerState.Email.FailureCount
                EmailLastFailure = $script:CircuitBreakerState.Email.LastFailureTime
                WebhookState = $script:CircuitBreakerState.Webhook.State
                WebhookFailureCount = $script:CircuitBreakerState.Webhook.FailureCount
                WebhookLastFailure = $script:CircuitBreakerState.Webhook.LastFailureTime
            }
        }
        
        Write-SystemStatusLog "Reliability metrics calculated: Overall success rate $($reliabilityReport.SystemStatus.OverallSuccessRate)%" -Level 'INFO'
        return $reliabilityReport
        
    } catch {
        Write-SystemStatusLog "Error retrieving reliability metrics: $($_.Exception.Message)" -Level 'ERROR'
        throw $_
    }
}

function Retry-EmailNotificationDelivery {
    <#
    .SYNOPSIS
    Retry email notification delivery with enhanced error handling
    #>
    [CmdletBinding()]
    param([hashtable]$NotificationData)
    
    try {
        # Simulate email delivery retry (actual implementation would use email module functions)
        Write-SystemStatusLog "Retrying email notification delivery" -Level 'DEBUG'
        
        # For now, return simulated success (actual implementation would call Send-EmailWithRetry)
        return @{
            Success = $true
            Details = "Email delivery retry simulation successful"
            ResponseTime = (Get-Random -Minimum 100 -Maximum 1000)
        }
    } catch {
        return @{
            Success = $false
            Error = $_.Exception.Message
        }
    }
}

function Retry-WebhookNotificationDelivery {
    <#
    .SYNOPSIS
    Retry webhook notification delivery with enhanced error handling
    #>
    [CmdletBinding()]
    param([hashtable]$NotificationData)
    
    try {
        # Simulate webhook delivery retry (actual implementation would use webhook module functions)
        Write-SystemStatusLog "Retrying webhook notification delivery" -Level 'DEBUG'
        
        # For now, return simulated success (actual implementation would call Send-WebhookWithRetry)
        return @{
            Success = $true
            Details = "Webhook delivery retry simulation successful"
            ResponseTime = (Get-Random -Minimum 50 -Maximum 500)
        }
    } catch {
        return @{
            Success = $false
            Error = $_.Exception.Message
        }
    }
}

function Send-EmailNotificationWithReliability {
    <#
    .SYNOPSIS
    Send email notification with enhanced reliability patterns
    #>
    [CmdletBinding()]
    param([hashtable]$NotificationData)
    
    try {
        # Simulate email sending with reliability (actual implementation would integrate with existing email functions)
        $success = (Get-Random -Minimum 1 -Maximum 10) -gt 2  # 80% simulated success rate
        
        if ($success) {
            return @{
                Success = $true
                Details = "Email sent successfully with reliability patterns"
                ResponseTime = (Get-Random -Minimum 200 -Maximum 2000)
            }
        } else {
            return @{
                Success = $false
                Error = "Simulated email delivery failure"
            }
        }
    } catch {
        return @{
            Success = $false
            Error = $_.Exception.Message
        }
    }
}

function Send-WebhookNotificationWithReliability {
    <#
    .SYNOPSIS
    Send webhook notification with enhanced reliability patterns
    #>
    [CmdletBinding()]
    param([hashtable]$NotificationData)
    
    try {
        # Simulate webhook sending with reliability (actual implementation would integrate with existing webhook functions)
        $success = (Get-Random -Minimum 1 -Maximum 10) -gt 1  # 90% simulated success rate
        
        if ($success) {
            return @{
                Success = $true
                Details = "Webhook sent successfully with reliability patterns"
                ResponseTime = (Get-Random -Minimum 100 -Maximum 800)
            }
        } else {
            return @{
                Success = $false
                Error = "Simulated webhook delivery failure"
            }
        }
    } catch {
        return @{
            Success = $false
            Error = $_.Exception.Message
        }
    }
}

# Functions available for dot-sourcing in main module
# Initialize-NotificationReliabilitySystem, Test-CircuitBreakerState, Add-NotificationToDeadLetterQueue, Start-DeadLetterQueueProcessor, Invoke-FallbackNotificationDelivery, Get-NotificationReliabilityMetrics, Retry-EmailNotificationDelivery, Retry-WebhookNotificationDelivery, Send-EmailNotificationWithReliability, Send-WebhookNotificationWithReliability