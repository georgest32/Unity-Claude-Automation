# Setup-EmailNotificationIntegration.ps1
# Week 5 Day 2 Hour 5-6: Unity-Claude Workflow Integration
# Connect email notifications to Unity-Claude workflow events
# Date: 2025-08-21

[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [string]$EmailConfigurationName,
    [Parameter(Mandatory)]
    [string]$NotificationRecipient,
    [switch]$TestMode,
    [switch]$EnableAllNotifications
)

Write-Host "=== Email Notification Integration Setup ===" -ForegroundColor Cyan
Write-Host "Week 5 Day 2 Hour 5-6: Unity-Claude Workflow Integration" -ForegroundColor White
Write-Host "Email Config: $EmailConfigurationName → $NotificationRecipient" -ForegroundColor White
Write-Host ""

# Integration results tracking
$IntegrationResults = @{
    StartTime = Get-Date
    EmailConfiguration = $EmailConfigurationName
    NotificationRecipient = $NotificationRecipient
    TriggersRegistered = @()
    TemplatesCreated = @()
    IntegrationPoints = @()
    TestMode = $TestMode
    Errors = @()
}

function Write-IntegrationLog {
    param(
        [string]$Message,
        [string]$Level = "INFO"
    )
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss.fff"
    $logMessage = "[$timestamp] [$Level] [EmailIntegration] $Message"
    
    switch ($Level) {
        "ERROR" { Write-Host $logMessage -ForegroundColor Red }
        "WARNING" { Write-Host $logMessage -ForegroundColor Yellow }
        "DEBUG" { Write-Host $logMessage -ForegroundColor Gray }
        "SUCCESS" { Write-Host $logMessage -ForegroundColor Green }
        default { Write-Host $logMessage -ForegroundColor White }
    }
    
    Add-Content -Path ".\unity_claude_automation.log" -Value $logMessage -ErrorAction SilentlyContinue
}

Write-IntegrationLog -Message "Starting Unity-Claude email notification integration setup" -Level "INFO"

# Step 1: Load Email Notifications Module
Write-Host "=== Step 1: Email Notifications Module Loading ===" -ForegroundColor Yellow
Write-IntegrationLog -Message "Loading Unity-Claude-EmailNotifications module" -Level "INFO"

try {
    Import-Module ".\Modules\Unity-Claude-EmailNotifications\Unity-Claude-EmailNotifications-SystemNetMail.psm1" -Force -Global -ErrorAction Stop
    Write-IntegrationLog -Message "Email notifications module loaded successfully" -Level "SUCCESS"
    Write-Host "Email notifications module: LOADED" -ForegroundColor Green
    
    # Validate email configuration exists
    $emailConfig = Get-EmailConfiguration -ConfigurationName $EmailConfigurationName -ErrorAction SilentlyContinue
    if (-not $emailConfig) {
        throw "Email configuration '$EmailConfigurationName' not found. Create it first with New-EmailConfiguration."
    }
    
    Write-IntegrationLog -Message "Email configuration '$EmailConfigurationName' validated" -Level "SUCCESS"
    Write-Host "Email configuration: VALIDATED" -ForegroundColor Green
    
} catch {
    Write-IntegrationLog -Message "Failed to load email notifications module: $($_.Exception.Message)" -Level "ERROR"
    $IntegrationResults.Errors += "Module Loading: $($_.Exception.Message)"
    Write-Host "ERROR: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

# Step 2: Create Unity-Claude Specific Email Templates
Write-Host ""
Write-Host "=== Step 2: Unity-Claude Email Templates Creation ===" -ForegroundColor Yellow
Write-IntegrationLog -Message "Creating Unity-Claude specific email templates" -Level "INFO"

$templates = @(
    @{
        Name = "UnityCompilationError"
        Subject = "Unity Compilation Error: {ErrorType} in {ProjectName}"
        Body = @"
Unity Compilation Error Detected

Project: {ProjectName}
Error Type: {ErrorType}
Error Message: {ErrorMessage}
File: {ErrorFile}
Line: {ErrorLine}
Time: {Timestamp}

Full Error Context:
{FullErrorContext}

Unity-Claude Automation System will attempt to resolve this error automatically.

--
Unity-Claude Automation System
Notification sent at: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
"@
        Severity = "Error"
    },
    @{
        Name = "ClaudeResponseFailure"
        Subject = "Claude Response Failure: {FailureType}"
        Body = @"
Claude Response Processing Failure

Failure Type: {FailureType}
Request Type: {RequestType}
Error Message: {ErrorMessage}
Retry Attempts: {RetryAttempts}
Time: {Timestamp}

Context:
{FailureContext}

Manual intervention may be required.

--
Unity-Claude Automation System
Notification sent at: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
"@
        Severity = "Error"
    },
    @{
        Name = "WorkflowStatusChange"
        Subject = "Unity-Claude Workflow Status: {WorkflowName} → {NewStatus}"
        Body = @"
Unity-Claude Workflow Status Change

Workflow: {WorkflowName}
Previous Status: {PreviousStatus}
New Status: {NewStatus}
Unity Projects: {UnityProjectCount}
Claude Submissions: {ClaudeSubmissionCount}
Change Time: {Timestamp}

Status Details:
{StatusDetails}

--
Unity-Claude Automation System
Notification sent at: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
"@
        Severity = "Info"
    },
    @{
        Name = "SystemHealthAlert"
        Subject = "Unity-Claude System Health Alert: {AlertType}"
        Body = @"
Unity-Claude System Health Alert

Alert Type: {AlertType}
Severity: {Severity}
Component: {Component}
Metric: {MetricName} = {MetricValue}
Threshold: {Threshold}
Time: {Timestamp}

System Status:
{SystemStatus}

Recommended Action:
{RecommendedAction}

--
Unity-Claude Automation System
Notification sent at: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
"@
        Severity = "Warning"
    },
    @{
        Name = "AutonomousAgentAlert"
        Subject = "Unity-Claude Autonomous Agent: {AlertType}"
        Body = @"
Unity-Claude Autonomous Agent Alert

Alert Type: {AlertType}
Agent Status: {AgentStatus}
Intervention Required: {InterventionRequired}
Error Context: {ErrorContext}
Time: {Timestamp}

Agent Details:
{AgentDetails}

Human intervention may be required for optimal operation.

--
Unity-Claude Automation System
Notification sent at: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
"@
        Severity = "Critical"
    }
)

$templatesCreated = 0
foreach ($templateConfig in $templates) {
    try {
        Write-IntegrationLog -Message "Creating email template: $($templateConfig.Name)" -Level "DEBUG"
        
        $template = New-EmailTemplate -TemplateName $templateConfig.Name -Subject $templateConfig.Subject -BodyText $templateConfig.Body -Severity $templateConfig.Severity
        
        if ($template) {
            $templatesCreated++
            $IntegrationResults.TemplatesCreated += $templateConfig.Name
            Write-IntegrationLog -Message "Template created successfully: $($templateConfig.Name)" -Level "SUCCESS"
        }
        
    } catch {
        Write-IntegrationLog -Message "Failed to create template '$($templateConfig.Name)': $($_.Exception.Message)" -Level "ERROR"
        $IntegrationResults.Errors += "Template Creation ($($templateConfig.Name)): $($_.Exception.Message)"
    }
}

Write-Host "Email templates created: $templatesCreated/$($templates.Count)" -ForegroundColor $(if ($templatesCreated -eq $templates.Count) { "Green" } else { "Yellow" })

# Step 3: Register Email Notification Triggers
Write-Host ""
Write-Host "=== Step 3: Email Notification Triggers Registration ===" -ForegroundColor Yellow
Write-IntegrationLog -Message "Registering email notification triggers for Unity-Claude workflow events" -Level "INFO"

$triggers = @(
    @{
        Name = "UnityCompilationErrors"
        EventType = "UnityError"
        Template = "UnityCompilationError"
        Conditions = @{ Severity = "Error" }
    },
    @{
        Name = "ClaudeResponseFailures"
        EventType = "ClaudeFailure"
        Template = "ClaudeResponseFailure"
        Conditions = @{ Severity = "Error" }
    },
    @{
        Name = "WorkflowStatusChanges"
        EventType = "WorkflowStatus"
        Template = "WorkflowStatusChange"
        Conditions = @{}
    },
    @{
        Name = "SystemHealthAlerts"
        EventType = "SystemHealth"
        Template = "SystemHealthAlert"
        Conditions = @{ Severity = "Warning" }
    },
    @{
        Name = "AutonomousAgentAlerts"
        EventType = "AutonomousAgent"
        Template = "AutonomousAgentAlert"
        Conditions = @{ Severity = "Critical" }
    }
)

$triggersRegistered = 0
foreach ($triggerConfig in $triggers) {
    try {
        Write-IntegrationLog -Message "Registering notification trigger: $($triggerConfig.Name)" -Level "DEBUG"
        
        $trigger = Register-EmailNotificationTrigger -TriggerName $triggerConfig.Name -EventType $triggerConfig.EventType -ConfigurationName $EmailConfigurationName -ToAddress $NotificationRecipient -TemplateName $triggerConfig.Template -Conditions $triggerConfig.Conditions
        
        if ($trigger) {
            $triggersRegistered++
            $IntegrationResults.TriggersRegistered += $triggerConfig.Name
            Write-IntegrationLog -Message "Trigger registered successfully: $($triggerConfig.Name)" -Level "SUCCESS"
        }
        
    } catch {
        Write-IntegrationLog -Message "Failed to register trigger '$($triggerConfig.Name)': $($_.Exception.Message)" -Level "ERROR"
        $IntegrationResults.Errors += "Trigger Registration ($($triggerConfig.Name)): $($_.Exception.Message)"
    }
}

Write-Host "Email notification triggers registered: $triggersRegistered/$($triggers.Count)" -ForegroundColor $(if ($triggersRegistered -eq $triggers.Count) { "Green" } else { "Yellow" })

# Step 4: Create Integration Helper Functions
Write-Host ""
Write-Host "=== Step 4: Integration Helper Functions ===" -ForegroundColor Yellow
Write-IntegrationLog -Message "Creating Unity-Claude workflow integration helper functions" -Level "INFO"

$integrationHelpers = @"
# Unity-Claude-EmailIntegrationHelpers.ps1
# Week 5 Day 2 Hour 5-6: Integration helper functions for Unity-Claude workflow
# Auto-generated by Setup-EmailNotificationIntegration.ps1
# Date: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')

function Send-UnityErrorNotification {
    [CmdletBinding()]
    param(
        [string]`$ProjectName = "Unknown",
        [string]`$ErrorType = "Unknown",
        [string]`$ErrorMessage = "Unknown error",
        [string]`$ErrorFile = "Unknown",
        [string]`$ErrorLine = "Unknown",
        [string]`$FullErrorContext = "No additional context"
    )
    
    try {
        `$eventData = @{
            ProjectName = `$ProjectName
            ErrorType = `$ErrorType
            ErrorMessage = `$ErrorMessage
            ErrorFile = `$ErrorFile
            ErrorLine = `$ErrorLine
            FullErrorContext = `$FullErrorContext
            Timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
            Severity = "Error"
        }
        
        Write-Host "[DEBUG] [EmailIntegration] Sending Unity error notification: `$ErrorType in `$ProjectName" -ForegroundColor Gray
        `$result = Invoke-EmailNotificationTrigger -TriggerName "UnityCompilationErrors" -EventData `$eventData
        
        return `$result
        
    } catch {
        Write-Host "[ERROR] [EmailIntegration] Failed to send Unity error notification: `$(`$_.Exception.Message)" -ForegroundColor Red
        return @{ Success = `$false; Error = `$_.Exception.Message }
    }
}

function Send-ClaudeFailureNotification {
    [CmdletBinding()]
    param(
        [string]`$FailureType = "Unknown",
        [string]`$RequestType = "Unknown",
        [string]`$ErrorMessage = "Unknown error",
        [int]`$RetryAttempts = 0,
        [string]`$FailureContext = "No additional context"
    )
    
    try {
        `$eventData = @{
            FailureType = `$FailureType
            RequestType = `$RequestType
            ErrorMessage = `$ErrorMessage
            RetryAttempts = `$RetryAttempts
            FailureContext = `$FailureContext
            Timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
            Severity = "Error"
        }
        
        Write-Host "[DEBUG] [EmailIntegration] Sending Claude failure notification: `$FailureType" -ForegroundColor Gray
        `$result = Invoke-EmailNotificationTrigger -TriggerName "ClaudeResponseFailures" -EventData `$eventData
        
        return `$result
        
    } catch {
        Write-Host "[ERROR] [EmailIntegration] Failed to send Claude failure notification: `$(`$_.Exception.Message)" -ForegroundColor Red
        return @{ Success = `$false; Error = `$_.Exception.Message }
    }
}

function Send-WorkflowStatusNotification {
    [CmdletBinding()]
    param(
        [string]`$WorkflowName = "Unknown",
        [string]`$PreviousStatus = "Unknown",
        [string]`$NewStatus = "Unknown",
        [int]`$UnityProjectCount = 0,
        [int]`$ClaudeSubmissionCount = 0,
        [string]`$StatusDetails = "No additional details"
    )
    
    try {
        `$eventData = @{
            WorkflowName = `$WorkflowName
            PreviousStatus = `$PreviousStatus
            NewStatus = `$NewStatus
            UnityProjectCount = `$UnityProjectCount
            ClaudeSubmissionCount = `$ClaudeSubmissionCount
            StatusDetails = `$StatusDetails
            Timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
        }
        
        Write-Host "[DEBUG] [EmailIntegration] Sending workflow status notification: `$WorkflowName → `$NewStatus" -ForegroundColor Gray
        `$result = Invoke-EmailNotificationTrigger -TriggerName "WorkflowStatusChanges" -EventData `$eventData
        
        return `$result
        
    } catch {
        Write-Host "[ERROR] [EmailIntegration] Failed to send workflow status notification: `$(`$_.Exception.Message)" -ForegroundColor Red
        return @{ Success = `$false; Error = `$_.Exception.Message }
    }
}

function Send-SystemHealthNotification {
    [CmdletBinding()]
    param(
        [string]`$AlertType = "Unknown",
        [string]`$Component = "Unknown",
        [string]`$MetricName = "Unknown",
        [string]`$MetricValue = "Unknown",
        [string]`$Threshold = "Unknown",
        [string]`$SystemStatus = "Unknown",
        [string]`$RecommendedAction = "No action specified",
        [string]`$Severity = "Warning"
    )
    
    try {
        `$eventData = @{
            AlertType = `$AlertType
            Component = `$Component
            MetricName = `$MetricName
            MetricValue = `$MetricValue
            Threshold = `$Threshold
            SystemStatus = `$SystemStatus
            RecommendedAction = `$RecommendedAction
            Severity = `$Severity
            Timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
        }
        
        Write-Host "[DEBUG] [EmailIntegration] Sending system health notification: `$AlertType (`$Severity)" -ForegroundColor Gray
        `$result = Invoke-EmailNotificationTrigger -TriggerName "SystemHealthAlerts" -EventData `$eventData
        
        return `$result
        
    } catch {
        Write-Host "[ERROR] [EmailIntegration] Failed to send system health notification: `$(`$_.Exception.Message)" -ForegroundColor Red
        return @{ Success = `$false; Error = `$_.Exception.Message }
    }
}

function Send-AutonomousAgentNotification {
    [CmdletBinding()]
    param(
        [string]`$AlertType = "Unknown",
        [string]`$AgentStatus = "Unknown",
        [bool]`$InterventionRequired = `$true,
        [string]`$ErrorContext = "Unknown context",
        [string]`$AgentDetails = "No additional details"
    )
    
    try {
        `$eventData = @{
            AlertType = `$AlertType
            AgentStatus = `$AgentStatus
            InterventionRequired = `$InterventionRequired
            ErrorContext = `$ErrorContext
            AgentDetails = `$AgentDetails
            Timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
            Severity = "Critical"
        }
        
        Write-Host "[DEBUG] [EmailIntegration] Sending autonomous agent notification: `$AlertType" -ForegroundColor Gray
        `$result = Invoke-EmailNotificationTrigger -TriggerName "AutonomousAgentAlerts" -EventData `$eventData
        
        return `$result
        
    } catch {
        Write-Host "[ERROR] [EmailIntegration] Failed to send autonomous agent notification: `$(`$_.Exception.Message)" -ForegroundColor Red
        return @{ Success = `$false; Error = `$_.Exception.Message }
    }
}

# Example usage and testing functions
function Test-EmailNotificationIntegration {
    [CmdletBinding()]
    param()
    
    Write-Host "[INFO] [EmailIntegration] Testing Unity-Claude email notification integration..." -ForegroundColor White
    
    `$testResults = @()
    
    # Test Unity error notification
    try {
        `$unityResult = Send-UnityErrorNotification -ProjectName "TestProject" -ErrorType "CS0246" -ErrorMessage "Type 'TestClass' could not be found" -ErrorFile "TestScript.cs" -ErrorLine "42" -FullErrorContext "Example Unity compilation error for testing"
        `$testResults += @{ Test = "Unity Error"; Success = `$unityResult.Success }
        Write-Host "[DEBUG] [EmailIntegration] Unity error notification test: `$(`$unityResult.Success)" -ForegroundColor `$(if (`$unityResult.Success) { "Green" } else { "Red" })
    } catch {
        `$testResults += @{ Test = "Unity Error"; Success = `$false; Error = `$_.Exception.Message }
    }
    
    # Test Claude failure notification
    try {
        `$claudeResult = Send-ClaudeFailureNotification -FailureType "API Timeout" -RequestType "Error Analysis" -ErrorMessage "Request timed out after 30 seconds" -RetryAttempts 3 -FailureContext "Example Claude API failure for testing"
        `$testResults += @{ Test = "Claude Failure"; Success = `$claudeResult.Success }
        Write-Host "[DEBUG] [EmailIntegration] Claude failure notification test: `$(`$claudeResult.Success)" -ForegroundColor `$(if (`$claudeResult.Success) { "Green" } else { "Red" })
    } catch {
        `$testResults += @{ Test = "Claude Failure"; Success = `$false; Error = `$_.Exception.Message }
    }
    
    # Test workflow status notification
    try {
        `$workflowResult = Send-WorkflowStatusNotification -WorkflowName "TestWorkflow" -PreviousStatus "Created" -NewStatus "Running" -UnityProjectCount 2 -ClaudeSubmissionCount 5 -StatusDetails "Workflow started successfully for testing"
        `$testResults += @{ Test = "Workflow Status"; Success = `$workflowResult.Success }
        Write-Host "[DEBUG] [EmailIntegration] Workflow status notification test: `$(`$workflowResult.Success)" -ForegroundColor `$(if (`$workflowResult.Success) { "Green" } else { "Red" })
    } catch {
        `$testResults += @{ Test = "Workflow Status"; Success = `$false; Error = `$_.Exception.Message }
    }
    
    return `$testResults
}

Write-Host "`n=== Unity-Claude Email Integration Helpers Ready ===" -ForegroundColor Green
Write-Host "Integration functions available:" -ForegroundColor White
Write-Host "- Send-UnityErrorNotification" -ForegroundColor Gray
Write-Host "- Send-ClaudeFailureNotification" -ForegroundColor Gray  
Write-Host "- Send-WorkflowStatusNotification" -ForegroundColor Gray
Write-Host "- Send-SystemHealthNotification" -ForegroundColor Gray
Write-Host "- Send-AutonomousAgentNotification" -ForegroundColor Gray
Write-Host "- Test-EmailNotificationIntegration" -ForegroundColor Gray
Write-Host "`nTo test integration: Test-EmailNotificationIntegration" -ForegroundColor White
"@

$integrationHelpers | Set-Content ".\Unity-Claude-EmailIntegrationHelpers.ps1" -Encoding UTF8
Write-IntegrationLog -Message "Integration helper functions created: Unity-Claude-EmailIntegrationHelpers.ps1" -Level "SUCCESS"
Write-Host "Integration helpers: CREATED" -ForegroundColor Green

# Step 5: Integration Summary and Testing
if ($TestMode) {
    Write-Host ""
    Write-Host "=== Step 5: Integration Testing ===" -ForegroundColor Yellow
    Write-IntegrationLog -Message "Testing email notification integration in test mode" -Level "INFO"
    
    try {
        # Source the integration helpers
        . ".\Unity-Claude-EmailIntegrationHelpers.ps1"
        
        # Run integration tests
        Write-Host "[INFO] [EmailIntegration] Running integration tests..." -ForegroundColor White
        $testResults = Test-EmailNotificationIntegration
        
        $successfulTests = ($testResults | Where-Object { $_.Success }).Count
        $totalTests = $testResults.Count
        
        Write-Host "[INFO] [EmailIntegration] Integration tests completed: $successfulTests/$totalTests passed" -ForegroundColor $(if ($successfulTests -eq $totalTests) { "Green" } else { "Yellow" })
        
        foreach ($test in $testResults) {
            $status = if ($test.Success) { "PASS" } else { "FAIL" }
            $color = if ($test.Success) { "Green" } else { "Red" }
            Write-Host "  [$status] $($test.Test)" -ForegroundColor $color
            if ($test.Error) {
                Write-Host "    Error: $($test.Error)" -ForegroundColor Red
            }
        }
        
        $IntegrationResults.TestResults = $testResults
        
    } catch {
        Write-IntegrationLog -Message "Integration testing failed: $($_.Exception.Message)" -Level "ERROR"
        $IntegrationResults.Errors += "Integration Testing: $($_.Exception.Message)"
    }
}

# Integration Summary
$IntegrationResults.EndTime = Get-Date
$totalDuration = ($IntegrationResults.EndTime - $IntegrationResults.StartTime).TotalSeconds

Write-Host ""
Write-Host "=== Email Notification Integration Summary ===" -ForegroundColor Cyan
Write-Host ""
Write-Host "Integration Status: $(if ($IntegrationResults.Errors.Count -eq 0) { 'SUCCESS' } else { 'PARTIAL_SUCCESS' })" -ForegroundColor $(if ($IntegrationResults.Errors.Count -eq 0) { "Green" } else { "Yellow" })
Write-Host "Total Duration: $([math]::Round($totalDuration, 2)) seconds" -ForegroundColor White
Write-Host "Templates Created: $($IntegrationResults.TemplatesCreated.Count)" -ForegroundColor White
Write-Host "Triggers Registered: $($IntegrationResults.TriggersRegistered.Count)" -ForegroundColor White

if ($IntegrationResults.TestResults) {
    $passedTests = ($IntegrationResults.TestResults | Where-Object { $_.Success }).Count
    Write-Host "Integration Tests: $passedTests/$($IntegrationResults.TestResults.Count) passed" -ForegroundColor $(if ($passedTests -eq $IntegrationResults.TestResults.Count) { "Green" } else { "Yellow" })
}

Write-Host ""
Write-Host "Integration Components:" -ForegroundColor White
Write-Host "- Email Templates: $($IntegrationResults.TemplatesCreated -join ', ')" -ForegroundColor Gray
Write-Host "- Notification Triggers: $($IntegrationResults.TriggersRegistered -join ', ')" -ForegroundColor Gray
Write-Host "- Helper Functions: Unity-Claude-EmailIntegrationHelpers.ps1" -ForegroundColor Gray

if ($IntegrationResults.Errors.Count -gt 0) {
    Write-Host ""
    Write-Host "Errors Encountered:" -ForegroundColor Red
    foreach ($error in $IntegrationResults.Errors) {
        Write-Host "  - $error" -ForegroundColor Red
    }
}

Write-Host ""
if ($IntegrationResults.Errors.Count -eq 0) {
    Write-Host "✅ EMAIL NOTIFICATION INTEGRATION SUCCESSFUL" -ForegroundColor Green
    Write-Host ""
    Write-Host "Integration Ready:" -ForegroundColor White
    Write-Host "1. Email notification triggers registered for all Unity-Claude events" -ForegroundColor Gray
    Write-Host "2. Integration helper functions available for workflow modules" -ForegroundColor Gray
    Write-Host "3. Email templates configured for Unity errors, Claude failures, and system events" -ForegroundColor Gray
    Write-Host "4. Production-ready email notification system integrated with Unity-Claude workflow" -ForegroundColor Gray
} else {
    Write-Host "⚠️ EMAIL NOTIFICATION INTEGRATION PARTIAL" -ForegroundColor Yellow
    Write-Host "Review errors and retry integration setup" -ForegroundColor Gray
}

Write-IntegrationLog -Message "Email notification integration setup completed" -Level "INFO"

Write-Host ""
Write-Host "=== Integration Setup Complete ===" -ForegroundColor Cyan

return $IntegrationResults
# SIG # Begin signature block
# MIIFqQYJKoZIhvcNAQcCoIIFmjCCBZYCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUrH1tUmFGM+UTibQf68NbrXm1
# zHugggMwMIIDLDCCAhSgAwIBAgIQdR0W2SKoK5VE8JId4ZxrRTANBgkqhkiG9w0B
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
# CQQxFgQUsf9b3EIjlpjdNFFoGmzs3I4wghwwDQYJKoZIhvcNAQEBBQAEggEAROAb
# afmeV9NTA5EAzGGXN9pi1bEVebowHGtZt5roJwTsqHLyTW/yIFoXvjgWZhQBbAuT
# +Km9MSHU7uM+qCAIW3n64P1pNJuWWvHtQSTzGxdbDXDcy7DeljLa+2yZsC84VJwq
# lWizKWMAQBC1gxV4+AY+IlWctrClx75FaBbWvctJfR9c+pOlrZVoSIFzmFgs/Ylr
# wSvIrR3lhD73JPNKixaBpFqip63W+Wllhkz0c7RGEPpdx95SsOJBXn3yq6lyW2dS
# A3cx3t3Ok/74/ysPpnBGlvjh+KwT/jruVwVxRDjD08tpdmlDfXin01PJVpKHCHC+
# 2SlqawLKx8uvHpVklw==
# SIG # End signature block
