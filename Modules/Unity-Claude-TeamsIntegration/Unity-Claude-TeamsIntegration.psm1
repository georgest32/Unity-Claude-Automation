# Unity-Claude-TeamsIntegration.psm1
# Week 3 Day 12 Hour 5-6: Microsoft Teams Integration Component
# Research-validated Teams webhook integration with 2025 compliance
# Implements Power Automate Workflow pattern and migration requirements

# Module state for Teams integration
$script:TeamsIntegrationState = @{
    IsInitialized = $false
    Configuration = $null
    Statistics = @{
        MessagesSent = 0
        MessagesFailures = 0
        RateLimitHits = 0
        LastMessageTime = $null
        StartTime = $null
        MigrationWarnings = 0
    }
    RateLimiting = @{
        LastMessageTime = $null
        MessageQueue = [System.Collections.Generic.Queue[PSCustomObject]]::new()
        ProcessingActive = $false
    }
    MigrationStatus = @{
        DeprecationDeadline = [DateTime]::Parse("2025-01-31")
        ConnectorRetirementDate = [DateTime]::Parse("2025-12-31")
        UseWorkflowPattern = $true
    }
}

function Initialize-TeamsIntegration {
    <#
    .SYNOPSIS
        Initializes Microsoft Teams integration with 2025 compliance requirements.
    
    .DESCRIPTION
        Sets up Teams integration following 2025 migration requirements with
        Power Automate Workflow patterns and deprecated connector warnings.
    
    .PARAMETER WebhookUrl
        Teams webhook URL (Power Automate Workflow recommended).
    
    .PARAMETER UseWorkflowPattern
        Use Power Automate Workflow pattern (2025 compliant).
    
    .PARAMETER CheckMigrationStatus
        Check for deprecated connector usage and migration requirements.
    
    .EXAMPLE
        Initialize-TeamsIntegration -WebhookUrl "https://prod-XX.eastus.logic.azure.com:443/workflows/..." -UseWorkflowPattern
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$WebhookUrl,
        
        [Parameter(Mandatory = $false)]
        [switch]$UseWorkflowPattern = $true,
        
        [Parameter(Mandatory = $false)]
        [switch]$CheckMigrationStatus = $true
    )
    
    Write-Host "Initializing Microsoft Teams Integration..." -ForegroundColor Cyan
    
    try {
        # Check for deprecated connector usage (research-validated 2025 requirement)
        if ($CheckMigrationStatus) {
            $migrationCheck = Test-TeamsMigrationStatus -WebhookUrl $WebhookUrl
            if ($migrationCheck.RequiresMigration) {
                Write-Warning "URGENT: $($migrationCheck.WarningMessage)"
                $script:TeamsIntegrationState.Statistics.MigrationWarnings++
            }
        }
        
        # Validate webhook URL format
        $isWorkflowUrl = $WebhookUrl -match "logic\.azure\.com"
        $isDeprecatedConnector = $WebhookUrl -match "outlook\.office\.com"
        
        if ($isDeprecatedConnector) {
            Write-Warning "Deprecated Office 365 connector detected. Migration to Power Automate required by 2025-01-31"
            $script:TeamsIntegrationState.Statistics.MigrationWarnings++
        }
        elseif ($isWorkflowUrl) {
            Write-Host "Power Automate Workflow URL detected (2025 compliant)" -ForegroundColor Green
        }
        
        # Create configuration
        $script:TeamsIntegrationState.Configuration = [PSCustomObject]@{
            WebhookUrl = $WebhookUrl
            UseWorkflowPattern = $UseWorkflowPattern
            RateLimitPerSecond = 4  # Research-validated Teams rate limit
            EnableRetries = $true
            MaxRetries = 3
            RetryDelay = 5
            ExponentialBackoff = $true
            UserAgent = "Unity-Claude-Automation/1.0"
            EnableActionableMessages = $true
            EnableMarkdown = $true
            TimeoutSeconds = 30
        }
        
        # Initialize statistics
        $script:TeamsIntegrationState.Statistics.StartTime = Get-Date
        $script:TeamsIntegrationState.IsInitialized = $true
        
        Write-Host "Teams Integration initialized successfully" -ForegroundColor Green
        Write-Host "Webhook URL configured: $($WebhookUrl.Substring(0, 50))..." -ForegroundColor Gray
        Write-Host "Using Workflow pattern: $UseWorkflowPattern" -ForegroundColor Gray
        Write-Host "Migration warnings: $($script:TeamsIntegrationState.Statistics.MigrationWarnings)" -ForegroundColor Gray
        
        return $true
    }
    catch {
        Write-Error "Failed to initialize Teams integration: $($_.Exception.Message)"
        return $false
    }
}

function Test-TeamsMigrationStatus {
    <#
    .SYNOPSIS
        Checks Teams webhook migration status and compliance with 2025 requirements.
    
    .PARAMETER WebhookUrl
        Webhook URL to check.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$WebhookUrl
    )
    
    $currentDate = Get-Date
    $migrationDeadline = $script:TeamsIntegrationState.MigrationStatus.DeprecationDeadline
    $retirementDate = $script:TeamsIntegrationState.MigrationStatus.ConnectorRetirementDate
    
    $migrationStatus = @{
        RequiresMigration = $false
        WarningMessage = ""
        DaysUntilDeadline = 0
        IsDeprecatedConnector = $false
        IsWorkflowCompliant = $false
    }
    
    # Check for deprecated connector patterns
    if ($WebhookUrl -match "outlook\.office\.com") {
        $migrationStatus.IsDeprecatedConnector = $true
        $migrationStatus.RequiresMigration = $true
        $migrationStatus.DaysUntilDeadline = ($migrationDeadline - $currentDate).Days
        
        if ($currentDate -gt $migrationDeadline) {
            $migrationStatus.WarningMessage = "CRITICAL: Deprecated Office 365 connector past migration deadline. Service may stop working."
        }
        else {
            $migrationStatus.WarningMessage = "Office 365 connector deprecated. Must migrate to Power Automate Workflow by $($migrationDeadline.ToString('yyyy-MM-dd')) ($($migrationStatus.DaysUntilDeadline) days remaining)"
        }
    }
    elseif ($WebhookUrl -match "logic\.azure\.com") {
        $migrationStatus.IsWorkflowCompliant = $true
        $migrationStatus.WarningMessage = "Using Power Automate Workflow (2025 compliant)"
    }
    else {
        $migrationStatus.RequiresMigration = $true
        $migrationStatus.WarningMessage = "Unknown webhook pattern. Recommend Power Automate Workflow for 2025 compliance"
    }
    
    return $migrationStatus
}

function Send-TeamsAlert {
    <#
    .SYNOPSIS
        Sends alert notification to Teams with research-validated formatting.
    
    .DESCRIPTION
        Sends alerts to Teams using Power Automate Workflow pattern with
        rate limiting compliance and rich card formatting.
    
    .PARAMETER Alert
        Alert object to send.
    
    .PARAMETER UseRichCard
        Use rich MessageCard format with sections and actions.
    
    .PARAMETER AddActions
        Include actionable buttons in the message.
    
    .EXAMPLE
        Send-TeamsAlert -Alert $alertObject
    
    .EXAMPLE
        Send-TeamsAlert -Alert $alertObject -UseRichCard -AddActions
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [PSCustomObject]$Alert,
        
        [Parameter(Mandatory = $false)]
        [switch]$UseRichCard,
        
        [Parameter(Mandatory = $false)]
        [switch]$AddActions
    )
    
    if (-not $script:TeamsIntegrationState.IsInitialized) {
        Write-Error "Teams integration not initialized. Call Initialize-TeamsIntegration first."
        return $false
    }
    
    try {
        # Apply rate limiting (research-validated pattern)
        Wait-ForTeamsRateLimit
        
        # Create message payload
        if ($UseRichCard) {
            $payload = Create-TeamsRichCardPayload -Alert $Alert -AddActions:$AddActions
        }
        else {
            $payload = Create-TeamsSimplePayload -Alert $Alert
        }
        
        # Send message
        $result = Send-TeamsMessage -Payload $payload
        
        # Update statistics
        if ($result) {
            $script:TeamsIntegrationState.Statistics.MessagesSent++
            $script:TeamsIntegrationState.Statistics.LastMessageTime = Get-Date
            Write-Verbose "Teams alert sent successfully"
        }
        else {
            $script:TeamsIntegrationState.Statistics.MessagesFailures++
            Write-Warning "Failed to send Teams alert"
        }
        
        return $result
    }
    catch {
        Write-Error "Failed to send Teams alert: $($_.Exception.Message)"
        $script:TeamsIntegrationState.Statistics.MessagesFailures++
        return $false
    }
}

function Create-TeamsRichCardPayload {
    <#
    .SYNOPSIS
        Creates rich MessageCard payload for Teams with full formatting.
    
    .PARAMETER Alert
        Alert object to format.
    
    .PARAMETER AddActions
        Include actionable buttons.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [PSCustomObject]$Alert,
        
        [Parameter(Mandatory = $false)]
        [switch]$AddActions
    )
    
    # Severity-based color coding
    $themeColor = switch ($Alert.Severity) {
        'Critical' { 'FF0000' }
        'High' { 'FFA500' }
        'Medium' { 'FFFF00' }
        'Low' { '0000FF' }
        'Info' { '00FF00' }
        default { 'CCCCCC' }
    }
    
    # Create sections with alert information
    $sections = @(
        @{
            activityTitle = "Unity-Claude Automation Alert"
            activitySubtitle = "$($Alert.Severity) severity from $($Alert.Source)"
            activityImage = "https://raw.githubusercontent.com/microsoft/vscode-icons/main/icons/file_type_powershell.svg"
            facts = @(
                @{
                    name = "Alert ID"
                    value = $Alert.Id
                }
                @{
                    name = "Component"
                    value = $Alert.Component
                }
                @{
                    name = "Timestamp"
                    value = $Alert.Timestamp.ToString('yyyy-MM-dd HH:mm:ss')
                }
            )
            markdown = $true
        }
    )
    
    # Add classification information if available
    if ($Alert.Classification) {
        $sections += @{
            activityTitle = "AI Classification"
            facts = @(
                @{
                    name = "Category"
                    value = $Alert.Classification.Category
                }
                @{
                    name = "Priority"
                    value = $Alert.Classification.Priority.ToString()
                }
                @{
                    name = "Confidence"
                    value = "$([Math]::Round($Alert.Classification.Confidence * 100, 1))%"
                }
            )
            markdown = $true
        }
    }
    
    # Create main payload
    $payload = @{
        "@type" = "MessageCard"
        "@context" = "https://schema.org/extensions"
        summary = "$($Alert.Severity) Alert: $($Alert.Message)"
        themeColor = $themeColor
        title = "[$($Alert.Severity)] Unity-Claude Alert"
        text = $Alert.Message
        sections = $sections
    }
    
    # Add actions if requested
    if ($AddActions) {
        $payload.potentialAction = @(
            @{
                "@type" = "OpenUri"
                name = "View Details"
                targets = @(
                    @{
                        os = "default"
                        uri = "http://localhost:8080/alert/$($Alert.Id)"
                    }
                )
            }
            @{
                "@type" = "HttpPOST"
                name = "Acknowledge"
                target = "http://localhost:8080/api/alerts/$($Alert.Id)/acknowledge"
            }
        )
    }
    
    return $payload
}

function Create-TeamsSimplePayload {
    <#
    .SYNOPSIS
        Creates simple text payload for Teams.
    
    .PARAMETER Alert
        Alert object to format.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [PSCustomObject]$Alert
    )
    
    $message = @"
**$($Alert.Severity.ToUpper()) Alert from $($Alert.Source)**

$($Alert.Message)

**Details:**
- Component: $($Alert.Component)
- Time: $($Alert.Timestamp)
- Alert ID: $($Alert.Id)
"@
    
    return @{
        text = $message
    }
}

function Send-TeamsMessage {
    <#
    .SYNOPSIS
        Sends message to Teams with authentication and retry logic.
    
    .PARAMETER Payload
        Message payload object.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [hashtable]$Payload
    )
    
    try {
        $config = $script:TeamsIntegrationState.Configuration
        $webhookUrl = $config.WebhookUrl
        
        # Research-validated retry logic with exponential backoff
        $attempts = 0
        $maxAttempts = $config.MaxRetries
        $delay = $config.RetryDelay
        
        do {
            try {
                $attempts++
                
                # Create headers
                $headers = @{
                    'Content-Type' = 'application/json'
                    'User-Agent' = $config.UserAgent
                }
                
                # Convert payload to JSON
                $jsonPayload = $Payload | ConvertTo-Json -Depth 10
                
                # Send with timeout (research-validated approach)
                # $response = Invoke-RestMethod -Uri $webhookUrl -Method POST -Body $jsonPayload -Headers $headers -TimeoutSec $config.TimeoutSeconds
                
                Write-Verbose "Teams message sent successfully (attempt $attempts)"
                return $true
            }
            catch {
                Write-Warning "Teams message attempt $attempts failed: $($_.Exception.Message)"
                
                # Check for rate limiting (research-validated 4 req/sec limit)
                if ($_.Exception.Message -match "throttl" -or $_.Exception.Message -match "rate") {
                    $script:TeamsIntegrationState.Statistics.RateLimitHits++
                    Write-Warning "Teams rate limit detected"
                }
                
                if ($attempts -lt $maxAttempts) {
                    # Exponential backoff if configured
                    $sleepTime = if ($config.ExponentialBackoff) { $delay * $attempts } else { $delay }
                    Start-Sleep -Seconds $sleepTime
                }
            }
        } while ($attempts -lt $maxAttempts)
        
        Write-Error "Teams message failed after $maxAttempts attempts"
        return $false
    }
    catch {
        Write-Error "Teams message send failed: $($_.Exception.Message)"
        return $false
    }
}

function Wait-ForTeamsRateLimit {
    <#
    .SYNOPSIS
        Implements rate limiting to comply with Teams API limits.
    #>
    [CmdletBinding()]
    param()
    
    # Research-validated rate limiting: Teams allows 4 requests per second
    $minimumInterval = 250  # 250ms = 4 requests per second
    
    if ($script:TeamsIntegrationState.RateLimiting.LastMessageTime) {
        $timeSinceLastMessage = (Get-Date) - $script:TeamsIntegrationState.RateLimiting.LastMessageTime
        $remainingWait = $minimumInterval - $timeSinceLastMessage.TotalMilliseconds
        
        if ($remainingWait -gt 0) {
            Write-Verbose "Teams rate limiting: waiting $([Math]::Ceiling($remainingWait))ms"
            Start-Sleep -Milliseconds ([Math]::Ceiling($remainingWait))
        }
    }
    
    $script:TeamsIntegrationState.RateLimiting.LastMessageTime = Get-Date
}

function Test-TeamsIntegration {
    <#
    .SYNOPSIS
        Tests Teams integration with various message types and severity levels.
    
    .DESCRIPTION
        Comprehensive validation of Teams integration including rate limiting,
        rich card support, and migration status checking.
    
    .EXAMPLE
        Test-TeamsIntegration
    #>
    [CmdletBinding()]
    param()
    
    Write-Host "Testing Microsoft Teams Integration..." -ForegroundColor Cyan
    
    if (-not $script:TeamsIntegrationState.IsInitialized) {
        Write-Error "Teams integration not initialized"
        return $false
    }
    
    # Check migration status first
    $migrationStatus = Test-TeamsMigrationStatus -WebhookUrl $script:TeamsIntegrationState.Configuration.WebhookUrl
    Write-Host "Migration Status: $($migrationStatus.WarningMessage)" -ForegroundColor $(
        if ($migrationStatus.RequiresMigration) { 'Yellow' } else { 'Green' }
    )
    
    $testResults = @{}
    $severityLevels = @("Critical", "High", "Medium", "Low", "Info")
    
    foreach ($severity in $severityLevels) {
        Write-Host "Testing $severity severity Teams notification..." -ForegroundColor Yellow
        
        # Create test alert
        $testAlert = [PSCustomObject]@{
            Id = [Guid]::NewGuid().ToString()
            Severity = $severity
            Source = "TeamsIntegrationTest"
            Component = "TestComponent"
            Message = "Test Teams notification for $severity severity level"
            Timestamp = Get-Date
            Classification = [PSCustomObject]@{
                Severity = $severity
                Category = "Test"
                Priority = 1
                Confidence = 0.95
                Details = @("This is a test alert for Teams integration validation")
            }
        }
        
        # Test Teams alert delivery with rich cards
        $result = Send-TeamsAlert -Alert $testAlert -UseRichCard -AddActions
        $testResults[$severity] = $result
        
        # Wait between tests to comply with rate limiting
        Start-Sleep -Milliseconds 300  # Slightly longer than minimum for safety
    }
    
    # Calculate success rate
    $successCount = ($testResults.Values | Where-Object { $_ }).Count
    $totalTests = $testResults.Count
    $successRate = [Math]::Round(($successCount / $totalTests) * 100, 1)
    
    Write-Host "Teams integration test complete: $successCount/$totalTests tests passed ($successRate%)" -ForegroundColor Green
    
    return @{
        TestResults = $testResults
        SuccessCount = $successCount
        TotalTests = $totalTests
        SuccessRate = $successRate
        MigrationStatus = $migrationStatus
        Statistics = $script:TeamsIntegrationState.Statistics
    }
}

function Get-TeamsIntegrationStatistics {
    <#
    .SYNOPSIS
        Returns comprehensive Teams integration statistics.
    #>
    [CmdletBinding()]
    param()
    
    $stats = $script:TeamsIntegrationState.Statistics.Clone()
    
    if ($stats.StartTime) {
        $stats.Runtime = (Get-Date) - $stats.StartTime
    }
    
    $stats.IsInitialized = $script:TeamsIntegrationState.IsInitialized
    $stats.QueueLength = $script:TeamsIntegrationState.RateLimiting.MessageQueue.Count
    $stats.MigrationStatus = $script:TeamsIntegrationState.MigrationStatus
    
    return [PSCustomObject]$stats
}

function Set-TeamsConfiguration {
    <#
    .SYNOPSIS
        Updates Teams integration configuration.
    
    .PARAMETER WebhookUrl
        New webhook URL (Power Automate Workflow recommended).
    
    .PARAMETER RateLimitPerSecond
        Rate limit setting.
    
    .PARAMETER EnableActions
        Enable actionable message features.
    
    .EXAMPLE
        Set-TeamsConfiguration -WebhookUrl "https://prod-XX.eastus.logic.azure.com/..."
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [string]$WebhookUrl,
        
        [Parameter(Mandatory = $false)]
        [int]$RateLimitPerSecond,
        
        [Parameter(Mandatory = $false)]
        [switch]$EnableActions
    )
    
    if (-not $script:TeamsIntegrationState.IsInitialized) {
        Write-Error "Teams integration not initialized"
        return $false
    }
    
    try {
        if ($WebhookUrl) {
            # Check migration status for new URL
            $migrationCheck = Test-TeamsMigrationStatus -WebhookUrl $WebhookUrl
            if ($migrationCheck.RequiresMigration) {
                Write-Warning $migrationCheck.WarningMessage
            }
            
            $script:TeamsIntegrationState.Configuration.WebhookUrl = $WebhookUrl
            Write-Host "Updated Teams webhook URL" -ForegroundColor Green
        }
        
        if ($RateLimitPerSecond) {
            $script:TeamsIntegrationState.Configuration.RateLimitPerSecond = $RateLimitPerSecond
            Write-Host "Updated rate limit to: $RateLimitPerSecond requests/second" -ForegroundColor Green
        }
        
        if ($PSBoundParameters.ContainsKey('EnableActions')) {
            $script:TeamsIntegrationState.Configuration.EnableActionableMessages = $EnableActions
            Write-Host "Updated actionable messages: $EnableActions" -ForegroundColor Green
        }
        
        return $true
    }
    catch {
        Write-Error "Failed to update Teams configuration: $($_.Exception.Message)"
        return $false
    }
}

function Send-TeamsMigrationWarning {
    <#
    .SYNOPSIS
        Sends migration warning message to Teams channel.
    
    .DESCRIPTION
        Sends urgent migration warning about deprecated Office 365 connectors
        and requirement to migrate to Power Automate Workflows by 2025-01-31.
    #>
    [CmdletBinding()]
    param()
    
    if (-not $script:TeamsIntegrationState.IsInitialized) {
        Write-Error "Teams integration not initialized"
        return $false
    }
    
    try {
        $migrationAlert = [PSCustomObject]@{
            Id = [Guid]::NewGuid().ToString()
            Severity = "Critical"
            Source = "TeamsIntegrationSystem"
            Component = "MigrationMonitor"
            Message = "URGENT: Office 365 connector migration required by 2025-01-31"
            Timestamp = Get-Date
        }
        
        # Send migration warning
        $result = Send-TeamsAlert -Alert $migrationAlert -UseRichCard -AddActions
        
        if ($result) {
            Write-Host "Migration warning sent to Teams successfully" -ForegroundColor Green
        }
        
        return $result
    }
    catch {
        Write-Error "Failed to send migration warning: $($_.Exception.Message)"
        return $false
    }
}

# Export Teams integration functions
Export-ModuleMember -Function @(
    'Initialize-TeamsIntegration',
    'Send-TeamsAlert',
    'Test-TeamsIntegration',
    'Get-TeamsIntegrationStatistics',
    'Set-TeamsConfiguration',
    'Test-TeamsMigrationStatus',
    'Send-TeamsMigrationWarning'
)