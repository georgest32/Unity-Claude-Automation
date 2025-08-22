function Test-NotificationConfig {
    <#
    .SYNOPSIS
    Validates notification configuration
    
    .DESCRIPTION
    Tests the current notification configuration for validity and connectivity.
    Checks schema compliance, required fields, and optionally tests connections.
    
    .PARAMETER TestConnections
    Actually test email and webhook connections
    
    .PARAMETER Detailed
    Show detailed validation results
    
    .EXAMPLE
    Test-NotificationConfig
    
    .EXAMPLE
    Test-NotificationConfig -TestConnections -Detailed
    #>
    [CmdletBinding()]
    param(
        [switch]$TestConnections,
        [switch]$Detailed
    )
    
    Write-Host "=== Notification Configuration Validation ===" -ForegroundColor Cyan
    
    $results = @{
        Valid = $true
        Errors = @()
        Warnings = @()
        Tests = @()
    }
    
    # Load configuration
    $config = Get-NotificationConfig -NoCache
    
    if (-not $config) {
        $results.Valid = $false
        $results.Errors += "Failed to load configuration file"
        return $results
    }
    
    # Validate Email Configuration
    Write-Host ""
    Write-Host "Validating Email Configuration..." -ForegroundColor Yellow
    
    $emailConfig = $config.EmailNotifications
    if ($emailConfig.Enabled) {
        # Check required fields
        $requiredFields = @('SMTPServer', 'SMTPPort', 'FromAddress', 'ToAddresses')
        foreach ($field in $requiredFields) {
            if (-not $emailConfig.$field) {
                $results.Valid = $false
                $results.Errors += "Email configuration missing required field: $field"
            }
        }
        
        # Validate SMTP port
        if ($emailConfig.SMTPPort -notin @(25, 465, 587, 2525)) {
            $results.Warnings += "Non-standard SMTP port: $($emailConfig.SMTPPort)"
        }
        
        # Test connection if requested
        if ($TestConnections) {
            Write-Host "  Testing SMTP connection to $($emailConfig.SMTPServer):$($emailConfig.SMTPPort)..." -ForegroundColor Gray
            try {
                $tcp = New-Object System.Net.Sockets.TcpClient
                $tcp.Connect($emailConfig.SMTPServer, $emailConfig.SMTPPort)
                if ($tcp.Connected) {
                    Write-Host "  [SUCCESS] SMTP server reachable" -ForegroundColor Green
                    $results.Tests += @{Type='SMTP'; Status='Success'; Message='Server reachable'}
                    $tcp.Close()
                }
            } catch {
                Write-Host "  [FAILURE] Cannot connect to SMTP server: $_" -ForegroundColor Red
                $results.Tests += @{Type='SMTP'; Status='Failure'; Message=$_.ToString()}
                $results.Warnings += "SMTP server not reachable"
            }
        }
    }
    
    # Validate Webhook Configuration
    Write-Host ""
    Write-Host "Validating Webhook Configuration..." -ForegroundColor Yellow
    
    $webhookConfig = $config.WebhookNotifications
    if ($webhookConfig.Enabled) {
        # Check for webhook URLs
        if (-not $webhookConfig.WebhookURLs -or $webhookConfig.WebhookURLs.Count -eq 0) {
            $results.Errors += "Webhook enabled but no URLs configured"
            $results.Valid = $false
        } else {
            foreach ($url in $webhookConfig.WebhookURLs) {
                if ($url -match 'YOUR_WEBHOOK') {
                    $results.Warnings += "Webhook URL contains placeholder: $url"
                }
                
                # Test webhook if requested
                if ($TestConnections -and $url -notmatch 'YOUR_WEBHOOK') {
                    Write-Host "  Testing webhook: $url..." -ForegroundColor Gray
                    try {
                        $testPayload = @{
                            test = $true
                            timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
                            source = "Unity-Claude Configuration Test"
                        } | ConvertTo-Json
                        
                        $response = Invoke-RestMethod -Uri $url -Method Post -Body $testPayload -ContentType 'application/json' -TimeoutSec 10
                        Write-Host "  [SUCCESS] Webhook responded" -ForegroundColor Green
                        $results.Tests += @{Type='Webhook'; Status='Success'; URL=$url}
                    } catch {
                        Write-Host "  [FAILURE] Webhook test failed: $_" -ForegroundColor Red
                        $results.Tests += @{Type='Webhook'; Status='Failure'; URL=$url; Error=$_.ToString()}
                        $results.Warnings += "Webhook not responding: $url"
                    }
                }
            }
        }
    }
    
    # Validate Notification Triggers
    Write-Host ""
    Write-Host "Validating Notification Triggers..." -ForegroundColor Yellow
    
    $triggers = $config.NotificationTriggers
    if ($triggers) {
        $triggerCount = 0
        foreach ($trigger in $triggers.PSObject.Properties) {
            $triggerConfig = $trigger.Value
            if ($triggerConfig.PSObject.Properties.Name -contains 'DebounceSeconds') {
                if ($triggerConfig.DebounceSeconds -lt 0) {
                    $results.Warnings += "$($trigger.Name) has invalid debounce value"
                }
            }
            $triggerCount++
        }
        Write-Host "  Found $triggerCount notification triggers configured" -ForegroundColor Gray
    }
    
    # Display results
    Write-Host ""
    Write-Host "=== Validation Results ===" -ForegroundColor Cyan
    
    if ($results.Errors.Count -gt 0) {
        Write-Host "Errors:" -ForegroundColor Red
        foreach ($error in $results.Errors) {
            Write-Host "  - $error" -ForegroundColor Red
        }
    }
    
    if ($results.Warnings.Count -gt 0) {
        Write-Host "Warnings:" -ForegroundColor Yellow
        foreach ($warning in $results.Warnings) {
            Write-Host "  - $warning" -ForegroundColor Yellow
        }
    }
    
    if ($results.Valid) {
        Write-Host "Configuration is VALID" -ForegroundColor Green
    } else {
        Write-Host "Configuration is INVALID" -ForegroundColor Red
    }
    
    if ($Detailed) {
        return $results
    } else {
        return $results.Valid
    }
}