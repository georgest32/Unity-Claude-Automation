
function Send-HealthAlert {
    <#
    .SYNOPSIS
    Sends health alerts using enterprise notification methods
    
    .DESCRIPTION
    Implements research-validated alert system with multiple notification methods:
    - Multi-tier severity: Info, Warning, Critical
    - Multiple channels: Console, File, Event logging
    - Enterprise integration patterns
    
    .PARAMETER AlertLevel
    Alert severity level: Info, Warning, Critical
    
    .PARAMETER SubsystemName
    Name of the subsystem generating the alert
    
    .PARAMETER Message
    Alert message content
    
    .PARAMETER NotificationMethods
    Array of notification methods to use
    
    .EXAMPLE
    Send-HealthAlert -AlertLevel "Critical" -SubsystemName "Unity-Claude-Core" -Message "Service unresponsive"
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [ValidateSet("Info", "Warning", "Critical")]
        [string]$AlertLevel,
        
        [Parameter(Mandatory=$true)]
        [string]$SubsystemName,
        
        [Parameter(Mandatory=$true)]
        [string]$Message,
        
        [Parameter(Mandatory=$false)]
        [string[]]$NotificationMethods = @("Console", "File", "Event")
    )
    
    $timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss.fff'
    $alertId = [System.Guid]::NewGuid().ToString().Substring(0, 8)
    
    Write-SystemStatusLog "Sending health alert [$alertId]: $AlertLevel for $SubsystemName" -Level 'INFO'
    
    try {
        # Create alert object
        $alert = @{
            AlertId = $alertId
            Timestamp = $timestamp
            AlertLevel = $AlertLevel
            SubsystemName = $SubsystemName
            Message = $Message
            NotificationMethods = $NotificationMethods
        }
        
        # Console notification
        if ("Console" -in $NotificationMethods) {
            $consoleColor = switch ($AlertLevel) {
                "Info" { "Green" }
                "Warning" { "Yellow" }
                "Critical" { "Red" }
            }
            
            Write-Host "[$timestamp] [$AlertLevel] HEALTH ALERT [$alertId]: $SubsystemName - $Message" -ForegroundColor $consoleColor
        }
        
        # File notification (using existing logging system)
        if ("File" -in $NotificationMethods) {
            $logLevel = switch ($AlertLevel) {
                "Info" { "INFO" }
                "Warning" { "WARN" }
                "Critical" { "ERROR" }
            }
            
            Write-SystemStatusLog "HEALTH ALERT [$alertId]: $SubsystemName - $Message" -Level $logLevel
            
            # Also write to dedicated health alert log
            $projectRoot = Split-Path $script:SystemStatusConfig.SystemStatusFile -Parent
            $healthAlertLogPath = Join-Path $projectRoot "health_alerts.log"
            $alertLogLine = "[$timestamp] [$AlertLevel] [$alertId] $SubsystemName - $Message"
            Add-Content -Path $healthAlertLogPath -Value $alertLogLine -ErrorAction SilentlyContinue
        }
        
        # Event logging (Windows Event Log)
        if ("Event" -in $NotificationMethods) {
            try {
                $eventLogSource = "Unity-Claude-SystemStatus"
                $eventId = switch ($AlertLevel) {
                    "Info" { 1001 }
                    "Warning" { 2001 }
                    "Critical" { 3001 }
                }
                
                $eventType = switch ($AlertLevel) {
                    "Info" { "Information" }
                    "Warning" { "Warning" }
                    "Critical" { "Error" }
                }
                
                # Create event log entry
                $eventMessage = "Health Alert [$alertId] for subsystem '$SubsystemName': $Message"
                Write-EventLog -LogName "Application" -Source $eventLogSource -EventId $eventId -EntryType $eventType -Message $eventMessage -ErrorAction SilentlyContinue
                
                Write-SystemStatusLog "Health alert [$alertId] logged to Windows Event Log" -Level 'DEBUG'
            } catch {
                Write-SystemStatusLog "Failed to write health alert [$alertId] to Event Log: $($_.Exception.Message)" -Level 'WARN'
            }
        }
        
        # Store alert for escalation processing
        if (-not $script:HealthAlertHistory) {
            $script:HealthAlertHistory = @()
        }
        
        $script:HealthAlertHistory += $alert
        
        # Keep only last 100 alerts to prevent memory issues
        if ($script:HealthAlertHistory.Count -gt 100) {
            $script:HealthAlertHistory = $script:HealthAlertHistory[-100..-1]
        }
        
        # Check for escalation if this is a critical alert
        if ($AlertLevel -eq "Critical") {
            Invoke-EscalationProcedure -Alert $alert
        }
        
        Write-SystemStatusLog "Health alert [$alertId] sent successfully via $($NotificationMethods -join ', ')" -Level 'DEBUG'
        return $alertId
        
    } catch {
        Write-SystemStatusLog "Error sending health alert: $($_.Exception.Message)" -Level 'ERROR'
        throw
    }
}

# SIG # Begin signature block
# MIIFqQYJKoZIhvcNAQcCoIIFmjCCBZYCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQU/fr6uSuy4wmY1ihlmBWYqKfZ
# uragggMwMIIDLDCCAhSgAwIBAgIQdR0W2SKoK5VE8JId4ZxrRTANBgkqhkiG9w0B
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
# CQQxFgQU+9UZtPT5A87s5RApjoUogcoDQ3QwDQYJKoZIhvcNAQEBBQAEggEAUluL
# 6x4tUf7fdrMASAxM2gDf4vanOTAeXJcIHbVdWdBdmy0sjSzwkUD3SWXcuQ9+C1KP
# p2Cz3qa+MJqq1nz23yerPARYN5dvYZ8/vmqxpPFr6chxw8tP+SYd/uY8myucbRUL
# hZq2LN+1q6wHYJ0IkzfU80LthKSSMOlozY4cmTSw1NGAKQwguiqjT0L63SIxsyJv
# laz9ciZXoFlgrPN4qOpTavGFCqowmKbbECh9c4LhqGttTVoX6neQVw9baXv6mhxS
# 47xfAyd2zdhBlbk5ajvA+YqAxvmmT8Whr/ukETP84CvwrGMlwHG7XNIm9nmevm1N
# JGDBOJKM6jXkzngRnw==
# SIG # End signature block
