# IntegratedNotifications.psm1
# Provides integrated notification functionality
# Date: 2025-08-21

function Send-IntegratedNotification {
    <#
    .SYNOPSIS
    Sends an integrated notification through configured channels
    
    .DESCRIPTION
    Sends a notification using the integrated notification system with template support
    
    .PARAMETER TemplateName
    Name of the notification template to use
    
    .PARAMETER Severity
    Severity level of the notification
    
    .PARAMETER Data
    Data to include in the notification
    
    .PARAMETER Channels
    Channels to send the notification through
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$TemplateName,
        
        [Parameter(Mandatory = $true)]
        [ValidateSet('Critical', 'Error', 'Warning', 'Info', 'Debug')]
        [string]$Severity,
        
        [Parameter()]
        [hashtable]$Data = @{},
        
        [Parameter()]
        [string[]]$Channels = @('Console')
    )
    
    Write-Verbose "Sending integrated notification: $TemplateName (Severity: $Severity)"
    
    # Get parent module state
    $parentModule = Get-Module 'Unity-Claude-NotificationIntegration-Modular' -ErrorAction SilentlyContinue
    if (-not $parentModule) {
        Write-Warning "Parent module not found - using local processing"
        
        # Fallback to console output
        $timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
        $message = "[$timestamp] [$Severity] $TemplateName"
        
        if ($Data.Count -gt 0) {
            $dataStr = ($Data.GetEnumerator() | ForEach-Object { "$($_.Key)=$($_.Value)" }) -join ', '
            $message += " - Data: {$dataStr}"
        }
        
        Write-Host $message -ForegroundColor $(
            switch ($Severity) {
                'Critical' { 'Red' }
                'Error' { 'Red' }
                'Warning' { 'Yellow' }
                'Info' { 'Cyan' }
                'Debug' { 'Gray' }
                default { 'White' }
            }
        )
        
        return @{
            Success = $true
            Template = $TemplateName
            Severity = $Severity
            Channels = @('Console')
            Timestamp = $timestamp
        }
    }
    
    # Use parent module state
    $result = & $parentModule {
        param($template, $sev, $data, $chans)
        
        # Check if we have a content engine
        if (Get-Command 'Format-NotificationContent' -ErrorAction SilentlyContinue) {
            $content = Format-NotificationContent -Template $template -Data $data -Severity $sev
        } else {
            # Simple formatting
            $content = @{
                Subject = "$template Notification"
                Body = "Severity: $sev`n"
                if ($data.Count -gt 0) {
                    $content.Body += "Data:`n"
                    foreach ($key in $data.Keys) {
                        $content.Body += "  $key: $($data[$key])`n"
                    }
                }
            }
        }
        
        # Send through each channel
        $results = @()
        foreach ($channel in $chans) {
            $channelResult = @{
                Channel = $channel
                Success = $false
            }
            
            try {
                switch ($channel) {
                    'Console' {
                        Write-Host "[$sev] $($content.Subject)" -ForegroundColor $(
                            switch ($sev) {
                                'Critical' { 'Red' }
                                'Error' { 'Red' }
                                'Warning' { 'Yellow' }
                                'Info' { 'Cyan' }
                                'Debug' { 'Gray' }
                                default { 'White' }
                            }
                        )
                        if ($content.Body) {
                            Write-Host $content.Body
                        }
                        $channelResult.Success = $true
                    }
                    
                    'Email' {
                        if (Get-Command 'Send-EmailNotification' -ErrorAction SilentlyContinue) {
                            Send-EmailNotification -Subject $content.Subject -Body $content.Body -Priority $sev
                            $channelResult.Success = $true
                        } else {
                            Write-Warning "Email notification not available"
                        }
                    }
                    
                    'Webhook' {
                        if (Get-Command 'Send-WebhookNotification' -ErrorAction SilentlyContinue) {
                            Send-WebhookNotification -Payload $content -Severity $sev
                            $channelResult.Success = $true
                        } else {
                            Write-Warning "Webhook notification not available"
                        }
                    }
                    
                    default {
                        Write-Warning "Unknown channel: $channel"
                    }
                }
            }
            catch {
                Write-Warning "Failed to send through $channel : $_"
                $channelResult.Error = $_.Exception.Message
            }
            
            $results += $channelResult
        }
        
        return @{
            Success = ($results | Where-Object { $_.Success }).Count -gt 0
            Template = $template
            Severity = $sev
            Channels = $results
            Timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
        }
    } -template $TemplateName -sev $Severity -data $Data -chans $Channels
    
    return $result
}

function Test-IntegratedNotification {
    <#
    .SYNOPSIS
    Tests integrated notification functionality
    
    .DESCRIPTION
    Sends a test notification to verify the integrated notification system is working
    
    .PARAMETER Channels
    Channels to test
    #>
    [CmdletBinding()]
    param(
        [Parameter()]
        [string[]]$Channels = @('Console')
    )
    
    Write-Verbose "Testing integrated notification system"
    
    $testData = @{
        TestId = [guid]::NewGuid().ToString()
        TestTime = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
        TestType = 'IntegrationTest'
    }
    
    $result = Send-IntegratedNotification -TemplateName 'TestNotification' -Severity 'Info' -Data $testData -Channels $Channels
    
    if ($result.Success) {
        Write-Host "Integrated notification test successful" -ForegroundColor Green
    } else {
        Write-Warning "Integrated notification test failed"
    }
    
    return $result
}

function Validate-CrossModuleMessage {
    <#
    .SYNOPSIS
    Validates cross-module message passing
    
    .DESCRIPTION
    Tests that messages can be passed correctly between notification modules
    
    .PARAMETER MessageData
    Test message data to validate
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [hashtable]$MessageData
    )
    
    Write-Verbose "Validating cross-module message"
    
    $validationResult = @{
        Valid = $true
        Errors = @()
        ProcessedBy = @()
    }
    
    # Check required fields
    $requiredFields = @('EventType', 'Severity')
    foreach ($field in $requiredFields) {
        if (-not $MessageData.ContainsKey($field)) {
            $validationResult.Valid = $false
            $validationResult.Errors += "Missing required field: $field"
        }
    }
    
    # Validate through each module that's loaded
    $modules = @(
        'Unity-Claude-EmailNotifications',
        'Unity-Claude-WebhookNotifications',
        'Unity-Claude-NotificationContentEngine'
    )
    
    foreach ($moduleName in $modules) {
        if (Get-Module $moduleName -ErrorAction SilentlyContinue) {
            $validationResult.ProcessedBy += $moduleName
            
            # Module-specific validation
            switch ($moduleName) {
                'Unity-Claude-EmailNotifications' {
                    if ($MessageData.ContainsKey('EmailRecipients')) {
                        if ($MessageData.EmailRecipients.Count -eq 0) {
                            $validationResult.Errors += "Email module: No recipients specified"
                        }
                    }
                }
                
                'Unity-Claude-WebhookNotifications' {
                    if ($MessageData.ContainsKey('WebhookUrl')) {
                        if (-not [Uri]::IsWellFormedUriString($MessageData.WebhookUrl, 'Absolute')) {
                            $validationResult.Errors += "Webhook module: Invalid URL format"
                        }
                    }
                }
                
                'Unity-Claude-NotificationContentEngine' {
                    if ($MessageData.ContainsKey('Template')) {
                        # Would validate template exists
                        Write-Verbose "Content engine: Template validation would occur here"
                    }
                }
            }
        }
    }
    
    if ($validationResult.Errors.Count -gt 0) {
        $validationResult.Valid = $false
    }
    
    return $validationResult
}

# Export functions
Export-ModuleMember -Function @(
    'Send-IntegratedNotification',
    'Test-IntegratedNotification',
    'Validate-CrossModuleMessage'
)
# SIG # Begin signature block
# MIIFqQYJKoZIhvcNAQcCoIIFmjCCBZYCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQU85QjX7Lq5wBS4ghX/hP34UOr
# Up2gggMwMIIDLDCCAhSgAwIBAgIQdR0W2SKoK5VE8JId4ZxrRTANBgkqhkiG9w0B
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
# CQQxFgQUc8WyWDMInqiiIqlVuaZrGZVQ/BUwDQYJKoZIhvcNAQEBBQAEggEAmj9X
# SVQEv8mwZ89g8xdA/t5hEkofz0gTJY8mF8a3YebewmQCV+AeSidbyrhdL82YTCi6
# 5S8QYu67z+GYUcj44gLkOVAyeomqldvX2y47JYHnTDV5FoUQXpK3gXq2fsTJ0FkB
# hSIectPSk9hxQ4gZWewOPv2EffdxRy8mHq1EfmesqJ5ZMOEMZG488VLX2N/1nECe
# J69EcB2ew0e6AGcpJd17s3HJQ/rWLomvK7L5+K4oK/0HDcp/KJCLltp+tJhLtcP9
# hjUuaNkrSfR1raIh0t9Er/nmZeiAKmsHBl9ulziBjxYd5spLZ5osRuuBLLTI7iUS
# aXXiIobai5vRP16zrQ==
# SIG # End signature block
