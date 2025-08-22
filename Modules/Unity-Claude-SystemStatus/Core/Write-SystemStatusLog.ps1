
function Write-SystemStatusLog {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Message,
        
        [ValidateSet('INFO','WARN','WARNING','ERROR','OK','DEBUG','TRACE')]
        [string]$Level = 'INFO',
        
        [string]$Source = 'SystemStatus',
        
        [string]$Operation,
        
        [hashtable]$Context = @{},
        
        [System.Diagnostics.Stopwatch]$Timer,
        
        [switch]$StructuredLogging
    )
    
    $timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss.fff'
    
    # Enhanced log line with structured data support
    if ($StructuredLogging -and ($Context.Count -gt 0 -or $Operation -or $Timer)) {
        $structuredData = @{
            Timestamp = $timestamp
            Level = $Level
            Source = $Source
            Message = $Message
        }
        
        if ($Operation) { $structuredData.Operation = $Operation }
        if ($Timer) { 
            $structuredData.Duration = "$($Timer.ElapsedMilliseconds)ms"
            $structuredData.DurationMs = $Timer.ElapsedMilliseconds
        }
        if ($Context.Count -gt 0) { $structuredData.Context = $Context }
        
        # JSON structured log line
        try {
            $jsonData = ConvertTo-Json $structuredData -Compress -Depth 3
            $logLine = $jsonData
        } catch {
            # Fallback to standard format if JSON conversion fails
            $logLine = "[$timestamp] [$Level] [$Source] $Message"
        }
    } else {
        # Standard log format
        $logLine = "[$timestamp] [$Level] [$Source] $Message"
        if ($Operation) { $logLine += " [Op: $Operation]" }
        if ($Timer) { $logLine += " [Duration: $($Timer.ElapsedMilliseconds)ms]" }
    }
    
    # Console output with colors (following Unity-Claude-Core pattern)
    # Only show TRACE level if diagnostic mode is enabled
    $showTrace = $Level -ne 'TRACE' -or $script:DiagnosticModeEnabled
    
    if ($showTrace) {
        switch ($Level) {
            'ERROR' { Write-Host $logLine -ForegroundColor Red }
            'WARN'  { Write-Host $logLine -ForegroundColor Yellow }
            'WARNING' { Write-Host $logLine -ForegroundColor Yellow }
            'OK'    { Write-Host $logLine -ForegroundColor Green }
            'DEBUG' { Write-Host $logLine -ForegroundColor DarkGray }
            'TRACE' { Write-Host $logLine -ForegroundColor DarkCyan }
            default { Write-Host $logLine }
        }
    }
    
    # File output to centralized log with rotation check
    try {
        if ($script:SystemStatusConfig) {
            $logFile = Join-Path (Split-Path $script:SystemStatusConfig.SystemStatusFile -Parent) $script:SystemStatusConfig.LogFile
            
            # Check for log rotation if enabled
            if ($script:SystemStatusConfig.Logging.LogRotationEnabled) {
                Invoke-LogRotation -LogPath $logFile -MaxSizeMB $script:SystemStatusConfig.Logging.LogRotationSizeMB -MaxLogFiles $script:SystemStatusConfig.Logging.MaxLogFiles
            }
            
            Add-Content -Path $logFile -Value $logLine -ErrorAction SilentlyContinue
        }
    } catch {
        # Silently fail if we can't write to log (following Unity-Claude-Core pattern)
    }
}

# SIG # Begin signature block
# MIIFqQYJKoZIhvcNAQcCoIIFmjCCBZYCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUNphrJNnCnU4hiEneDLESLA9i
# qWCgggMwMIIDLDCCAhSgAwIBAgIQdR0W2SKoK5VE8JId4ZxrRTANBgkqhkiG9w0B
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
# CQQxFgQUcexMs9KSttJNqzXP3o5cdIH5smkwDQYJKoZIhvcNAQEBBQAEggEAJnDc
# spCEOMzw+zeCnvPPDSXc3ykqg4dBhSMSpD5mjaQSziavQ1HbvvFL2ydi00jAEIvN
# HzI6K12zzHCXT2hB1ZjyG/AnV1vYR/QJukKKmXcGUqlCx4p2MzSNZFtsuLraJtSs
# cuYYsh//s63I9sbqAEBw1ClKB2kqf1z1cnD+jD2YUwzkPTXDDVwXe0aqkHEGdt6s
# 2lclEaZz+pBM/qPNkqABqeKJRFfn3duJyX5LkY2mQVTgrzWO7DX+GoCa3Bg4p+7R
# AfSYR9hVml8ejwxcwC9d82DrCJIN89jVCUifb7SsqtZ8hoKCU8PWWk04IxVVOpf3
# 5FbuJCLv4pIMRtpNTQ==
# SIG # End signature block
