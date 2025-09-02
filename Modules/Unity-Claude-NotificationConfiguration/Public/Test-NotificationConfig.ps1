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
# SIG # Begin signature block
# MIIFzgYJKoZIhvcNAQcCoIIFvzCCBbsCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCCjUSnyOO4qSn6t
# EyRqUcglptcJ2VgwBEfISga4+3QdaaCCAzAwggMsMIICFKADAgECAhB1HRbZIqgr
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
# MAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIIoiZlRFprpODICTaFb8PqbL
# YEfQKlRv0H1MWBiKMKPUMA0GCSqGSIb3DQEBAQUABIIBAGB0ymQhhQ2Q7M5TvsKo
# +rRHNarQGPT3NtsEfBFYMNrZu4b/sQMgTAFRM4LW+7llMJffEXBnJhG9ndCP4s6P
# fkPyuuSf6Bah1shmQQO885MNP9ikSEHqHxkeoB8XGAR248FZKF4umCuiormgsRmX
# dv1iUY+uzoDqCpIWR5RX70cKFUvzr4LIrBKXvYS6FuuGPMYDNgAdUm+P77571yNC
# lMjRhxqf+56feUc3koX3QjMYCKUwiPFTlLGNYnT0oif/wGZQ5235amXkd5T+Q8ot
# nWgtH5bt7oHL1/NtctFiHBFCWzvPWvf94+eaA+Z7jGBPj2IK6mV1ySsZV5eNbvO7
# rj0=
# SIG # End signature block
