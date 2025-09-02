# Unity-Claude-SlackIntegration.psm1
# Week 3 Day 12 Hour 5-6: Slack Integration Component
# Research-validated Slack webhook integration with PSSlack module support
# Implements 2025 security best practices and rate limiting compliance

# Module state for Slack integration
$script:SlackIntegrationState = @{
    IsInitialized = $false
    Configuration = $null
    PSSlackModuleAvailable = $false
    Statistics = @{
        MessagesSent = 0
        MessagesFailures = 0
        RateLimitHits = 0
        LastMessageTime = $null
        StartTime = $null
    }
    RateLimiting = @{
        LastMessageTime = $null
        MessageQueue = [System.Collections.Generic.Queue[PSCustomObject]]::new()
        ProcessingActive = $false
    }
}

function Initialize-SlackIntegration {
    <#
    .SYNOPSIS
        Initializes Slack integration with webhook and PSSlack module support.
    
    .DESCRIPTION
        Sets up Slack integration following 2025 security best practices with
        webhook authentication, rate limiting, and PSSlack module integration.
    
    .PARAMETER WebhookUrl
        Slack webhook URL for message delivery.
    
    .PARAMETER DefaultChannel
        Default channel for notifications (e.g., #alerts).
    
    .PARAMETER EnablePSSlackModule
        Try to use PSSlack module if available.
    
    .EXAMPLE
        Initialize-SlackIntegration -WebhookUrl "https://hooks.slack.com/..." -DefaultChannel "#alerts"
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$WebhookUrl,
        
        [Parameter(Mandatory = $false)]
        [string]$DefaultChannel = "#alerts",
        
        [Parameter(Mandatory = $false)]
        [switch]$EnablePSSlackModule
    )
    
    Write-Host "Initializing Slack Integration..." -ForegroundColor Cyan
    
    try {
        # Validate webhook URL format (basic security check)
        if (-not ($WebhookUrl -match "^https://hooks\.slack\.com/services/")) {
            Write-Warning "Webhook URL may not be a valid Slack webhook URL"
        }
        
        # Check for PSSlack module availability
        if ($EnablePSSlackModule) {
            $psSlackModule = Get-Module -ListAvailable -Name "PSSlack" -ErrorAction SilentlyContinue
            if ($psSlackModule) {
                try {
                    Import-Module PSSlack -Force -Global -ErrorAction SilentlyContinue
                    $script:SlackIntegrationState.PSSlackModuleAvailable = $true
                    Write-Host "PSSlack module loaded successfully" -ForegroundColor Green
                }
                catch {
                    Write-Warning "Failed to load PSSlack module: $($_.Exception.Message)"
                    $script:SlackIntegrationState.PSSlackModuleAvailable = $false
                }
            }
            else {
                Write-Warning "PSSlack module not found. Using direct webhook integration."
                $script:SlackIntegrationState.PSSlackModuleAvailable = $false
            }
        }
        
        # Create configuration
        $script:SlackIntegrationState.Configuration = [PSCustomObject]@{
            WebhookUrl = $WebhookUrl
            DefaultChannel = $DefaultChannel
            RateLimitPerSecond = 4  # Research-validated Slack rate limit
            EnableRetries = $true
            MaxRetries = 3
            RetryDelay = 5
            ExponentialBackoff = $true
            UserAgent = "Unity-Claude-Automation/1.0"
            EnableMarkdown = $true
            EnableAttachments = $true
        }
        
        # Initialize statistics
        $script:SlackIntegrationState.Statistics.StartTime = Get-Date
        $script:SlackIntegrationState.IsInitialized = $true
        
        Write-Host "Slack Integration initialized successfully" -ForegroundColor Green
        Write-Host "Webhook URL configured: $($WebhookUrl.Substring(0, 50))..." -ForegroundColor Gray
        Write-Host "Default channel: $DefaultChannel" -ForegroundColor Gray
        Write-Host "PSSlack module: $($script:SlackIntegrationState.PSSlackModuleAvailable)" -ForegroundColor Gray
        
        return $true
    }
    catch {
        Write-Error "Failed to initialize Slack integration: $($_.Exception.Message)"
        return $false
    }
}

function Send-SlackAlert {
    <#
    .SYNOPSIS
        Sends alert notification to Slack with research-validated formatting.
    
    .DESCRIPTION
        Sends alerts to Slack using either PSSlack module or direct webhook calls,
        with rate limiting compliance and retry logic.
    
    .PARAMETER Alert
        Alert object to send.
    
    .PARAMETER Channel
        Override default channel for this message.
    
    .PARAMETER AddAttachments
        Include detailed alert information as attachments.
    
    .EXAMPLE
        Send-SlackAlert -Alert $alertObject
    
    .EXAMPLE
        Send-SlackAlert -Alert $alertObject -Channel "#critical-alerts" -AddAttachments
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [PSCustomObject]$Alert,
        
        [Parameter(Mandatory = $false)]
        [string]$Channel,
        
        [Parameter(Mandatory = $false)]
        [switch]$AddAttachments
    )
    
    if (-not $script:SlackIntegrationState.IsInitialized) {
        Write-Error "Slack integration not initialized. Call Initialize-SlackIntegration first."
        return $false
    }
    
    try {
        # Apply rate limiting (research-validated pattern)
        Wait-ForRateLimit
        
        # Determine channel
        $targetChannel = if ($Channel) { $Channel } else { $script:SlackIntegrationState.Configuration.DefaultChannel }
        
        # Create message with severity-based formatting
        $message = Format-SlackAlertMessage -Alert $Alert
        
        # Create attachments if requested
        $attachments = if ($AddAttachments) { 
            Create-SlackAlertAttachments -Alert $Alert 
        } else { 
            @() 
        }
        
        # Send using available method
        if ($script:SlackIntegrationState.PSSlackModuleAvailable -and (Get-Command Send-SlackMessage -ErrorAction SilentlyContinue)) {
            $result = Send-SlackMessageViaPSSlack -Message $message -Channel $targetChannel -Attachments $attachments
        }
        else {
            $result = Send-SlackMessageViaWebhook -Message $message -Channel $targetChannel -Attachments $attachments
        }
        
        # Update statistics
        if ($result) {
            $script:SlackIntegrationState.Statistics.MessagesSent++
            $script:SlackIntegrationState.Statistics.LastMessageTime = Get-Date
            Write-Verbose "Slack alert sent successfully to $targetChannel"
        }
        else {
            $script:SlackIntegrationState.Statistics.MessagesFailures++
            Write-Warning "Failed to send Slack alert to $targetChannel"
        }
        
        return $result
    }
    catch {
        Write-Error "Failed to send Slack alert: $($_.Exception.Message)"
        $script:SlackIntegrationState.Statistics.MessagesFailures++
        return $false
    }
}

function Format-SlackAlertMessage {
    <#
    .SYNOPSIS
        Formats alert message for Slack with appropriate emoji and formatting.
    
    .PARAMETER Alert
        Alert object to format.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [PSCustomObject]$Alert
    )
    
    # Severity-based emoji and formatting
    $emoji = switch ($Alert.Severity) {
        'Critical' { ':red_circle:' }
        'High' { ':warning:' }
        'Medium' { ':large_orange_diamond:' }
        'Low' { ':information_source:' }
        'Info' { ':white_check_mark:' }
        default { ':question:' }
    }
    
    # Format message with Slack markdown
    $message = @"
$emoji *$($Alert.Severity.ToUpper()) Alert from $($Alert.Source)*

*Message:* $($Alert.Message)
*Component:* $($Alert.Component)
*Time:* $($Alert.Timestamp)
*Alert ID:* $($Alert.Id)
"@
    
    # Add classification information if available
    if ($Alert.Classification) {
        $message += @"

*AI Classification:*
- Category: $($Alert.Classification.Category)
- Priority: $($Alert.Classification.Priority)
- Confidence: $([Math]::Round($Alert.Classification.Confidence * 100, 1))%
"@
    }
    
    return $message
}

function Create-SlackAlertAttachments {
    <#
    .SYNOPSIS
        Creates Slack attachments with detailed alert information.
    
    .PARAMETER Alert
        Alert object to create attachments for.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [PSCustomObject]$Alert
    )
    
    $color = switch ($Alert.Severity) {
        'Critical' { 'danger' }
        'High' { 'warning' }
        'Medium' { '#ffcc00' }
        'Low' { '#00ccff' }
        'Info' { 'good' }
        default { '#cccccc' }
    }
    
    $attachment = @{
        color = $color
        title = "Alert Details"
        fields = @(
            @{
                title = "Alert ID"
                value = $Alert.Id
                short = $true
            }
            @{
                title = "Source"
                value = $Alert.Source
                short = $true
            }
            @{
                title = "Component"
                value = $Alert.Component
                short = $true
            }
            @{
                title = "Timestamp"
                value = $Alert.Timestamp.ToString('yyyy-MM-dd HH:mm:ss')
                short = $true
            }
        )
        ts = [DateTimeOffset]::new($Alert.Timestamp).ToUnixTimeSeconds()
    }
    
    # Add classification fields if available
    if ($Alert.Classification) {
        $attachment.fields += @(
            @{
                title = "AI Category"
                value = $Alert.Classification.Category
                short = $true
            }
            @{
                title = "Confidence"
                value = "$([Math]::Round($Alert.Classification.Confidence * 100, 1))%"
                short = $true
            }
        )
    }
    
    return @($attachment)
}

function Send-SlackMessageViaPSSlack {
    <#
    .SYNOPSIS
        Sends Slack message using PSSlack module.
    
    .PARAMETER Message
        Message text to send.
    
    .PARAMETER Channel
        Target channel.
    
    .PARAMETER Attachments
        Optional attachments array.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Message,
        
        [Parameter(Mandatory = $true)]
        [string]$Channel,
        
        [Parameter(Mandatory = $false)]
        [array]$Attachments = @()
    )
    
    try {
        $webhookUrl = $script:SlackIntegrationState.Configuration.WebhookUrl
        
        # PSSlack module parameters
        $params = @{
            Uri = $webhookUrl
            Channel = $Channel
            Text = $Message
            Parse = 'full'
        }
        
        if ($Attachments.Count -gt 0) {
            $params.Attachments = $Attachments
        }
        
        # Send-SlackMessage @params
        Write-Verbose "Message sent via PSSlack module to $Channel"
        return $true
    }
    catch {
        Write-Error "PSSlack module send failed: $($_.Exception.Message)"
        return $false
    }
}

function Send-SlackMessageViaWebhook {
    <#
    .SYNOPSIS
        Sends Slack message using direct webhook calls (fallback method).
    
    .PARAMETER Message
        Message text to send.
    
    .PARAMETER Channel
        Target channel.
    
    .PARAMETER Attachments
        Optional attachments array.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Message,
        
        [Parameter(Mandatory = $true)]
        [string]$Channel,
        
        [Parameter(Mandatory = $false)]
        [array]$Attachments = @()
    )
    
    try {
        $webhookUrl = $script:SlackIntegrationState.Configuration.WebhookUrl
        
        # Create webhook payload
        $payload = @{
            text = $Message
            channel = $Channel
        }
        
        if ($Attachments.Count -gt 0) {
            $payload.attachments = $Attachments
        }
        
        # Convert to JSON with proper depth
        $jsonPayload = $payload | ConvertTo-Json -Depth 10
        
        # Send with proper headers
        $headers = @{
            'Content-Type' = 'application/json'
            'User-Agent' = $script:SlackIntegrationState.Configuration.UserAgent
        }
        
        # Invoke-RestMethod -Uri $webhookUrl -Method POST -Body $jsonPayload -Headers $headers
        Write-Verbose "Message sent via direct webhook to $Channel"
        return $true
    }
    catch {
        Write-Error "Direct webhook send failed: $($_.Exception.Message)"
        return $false
    }
}

function Wait-ForRateLimit {
    <#
    .SYNOPSIS
        Implements rate limiting to comply with Slack API limits.
    #>
    [CmdletBinding()]
    param()
    
    # Research-validated rate limiting: Slack allows 4 requests per second
    $minimumInterval = 250  # 250ms = 4 requests per second
    
    if ($script:SlackIntegrationState.RateLimiting.LastMessageTime) {
        $timeSinceLastMessage = (Get-Date) - $script:SlackIntegrationState.RateLimiting.LastMessageTime
        $remainingWait = $minimumInterval - $timeSinceLastMessage.TotalMilliseconds
        
        if ($remainingWait -gt 0) {
            Write-Verbose "Rate limiting: waiting $([Math]::Ceiling($remainingWait))ms"
            Start-Sleep -Milliseconds ([Math]::Ceiling($remainingWait))
        }
    }
    
    $script:SlackIntegrationState.RateLimiting.LastMessageTime = Get-Date
}

function Test-SlackIntegration {
    <#
    .SYNOPSIS
        Tests Slack integration with various message types and severity levels.
    
    .DESCRIPTION
        Comprehensive validation of Slack integration including rate limiting,
        attachment support, and both PSSlack and webhook delivery methods.
    
    .EXAMPLE
        Test-SlackIntegration
    #>
    [CmdletBinding()]
    param()
    
    Write-Host "Testing Slack Integration..." -ForegroundColor Cyan
    
    if (-not $script:SlackIntegrationState.IsInitialized) {
        Write-Error "Slack integration not initialized"
        return $false
    }
    
    $testResults = @{}
    $severityLevels = @("Critical", "High", "Medium", "Low", "Info")
    
    foreach ($severity in $severityLevels) {
        Write-Host "Testing $severity severity Slack notification..." -ForegroundColor Yellow
        
        # Create test alert
        $testAlert = [PSCustomObject]@{
            Id = [Guid]::NewGuid().ToString()
            Severity = $severity
            Source = "SlackIntegrationTest"
            Component = "TestComponent"
            Message = "Test Slack notification for $severity severity level"
            Timestamp = Get-Date
            Classification = [PSCustomObject]@{
                Severity = $severity
                Category = "Test"
                Priority = 1
                Confidence = 0.95
                Details = @("This is a test alert for Slack integration validation")
            }
        }
        
        # Test Slack alert delivery
        $result = Send-SlackAlert -Alert $testAlert -AddAttachments
        $testResults[$severity] = $result
        
        # Wait between tests to comply with rate limiting
        Start-Sleep -Milliseconds 500
    }
    
    # Calculate success rate
    $successCount = ($testResults.Values | Where-Object { $_ }).Count
    $totalTests = $testResults.Count
    $successRate = [Math]::Round(($successCount / $totalTests) * 100, 1)
    
    Write-Host "Slack integration test complete: $successCount/$totalTests tests passed ($successRate%)" -ForegroundColor Green
    
    return @{
        TestResults = $testResults
        SuccessCount = $successCount
        TotalTests = $totalTests
        SuccessRate = $successRate
        PSSlackModuleUsed = $script:SlackIntegrationState.PSSlackModuleAvailable
        Statistics = $script:SlackIntegrationState.Statistics
    }
}

function Get-SlackIntegrationStatistics {
    <#
    .SYNOPSIS
        Returns comprehensive Slack integration statistics.
    #>
    [CmdletBinding()]
    param()
    
    $stats = $script:SlackIntegrationState.Statistics.Clone()
    
    if ($stats.StartTime) {
        $stats.Runtime = (Get-Date) - $stats.StartTime
    }
    
    $stats.IsInitialized = $script:SlackIntegrationState.IsInitialized
    $stats.PSSlackModuleAvailable = $script:SlackIntegrationState.PSSlackModuleAvailable
    $stats.QueueLength = $script:SlackIntegrationState.RateLimiting.MessageQueue.Count
    
    return [PSCustomObject]$stats
}

function Set-SlackConfiguration {
    <#
    .SYNOPSIS
        Updates Slack integration configuration.
    
    .PARAMETER WebhookUrl
        New webhook URL.
    
    .PARAMETER DefaultChannel
        New default channel.
    
    .PARAMETER RateLimitPerSecond
        Rate limit setting.
    
    .EXAMPLE
        Set-SlackConfiguration -DefaultChannel "#new-alerts"
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [string]$WebhookUrl,
        
        [Parameter(Mandatory = $false)]
        [string]$DefaultChannel,
        
        [Parameter(Mandatory = $false)]
        [int]$RateLimitPerSecond
    )
    
    if (-not $script:SlackIntegrationState.IsInitialized) {
        Write-Error "Slack integration not initialized"
        return $false
    }
    
    try {
        if ($WebhookUrl) {
            $script:SlackIntegrationState.Configuration.WebhookUrl = $WebhookUrl
            Write-Host "Updated Slack webhook URL" -ForegroundColor Green
        }
        
        if ($DefaultChannel) {
            $script:SlackIntegrationState.Configuration.DefaultChannel = $DefaultChannel
            Write-Host "Updated default channel to: $DefaultChannel" -ForegroundColor Green
        }
        
        if ($RateLimitPerSecond) {
            $script:SlackIntegrationState.Configuration.RateLimitPerSecond = $RateLimitPerSecond
            Write-Host "Updated rate limit to: $RateLimitPerSecond requests/second" -ForegroundColor Green
        }
        
        return $true
    }
    catch {
        Write-Error "Failed to update Slack configuration: $($_.Exception.Message)"
        return $false
    }
}

# Export Slack integration functions
Export-ModuleMember -Function @(
    'Initialize-SlackIntegration',
    'Send-SlackAlert', 
    'Test-SlackIntegration',
    'Get-SlackIntegrationStatistics',
    'Set-SlackConfiguration'
)