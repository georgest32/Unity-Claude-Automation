
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
# MIIFzgYJKoZIhvcNAQcCoIIFvzCCBbsCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCCYac2FrU9UBTUj
# nx0WAr3aHmsSUfBF1N2CwTaX3phXFKCCAzAwggMsMIICFKADAgECAhB1HRbZIqgr
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
# MAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIOxVUgZb9eZ6spvP35hJn9V5
# kyLF7stCo7EqcheNp/ljMA0GCSqGSIb3DQEBAQUABIIBAF7Fv1qQHI/QPisFKMCk
# 2vUbmkjUPFHBhYwkDiFHP+nimaLs0gUldFKjAbYJYRZUCnJUcXgDuHK9qM/0iNwN
# KfDBBqNo9Yz+ORBeEKx7UgMcDxAKdYtYRLI1sBTeYre190zt5jWL1rs+SjGf8k1B
# YkWsW0w9mPGC1tyxx/4uLURnPAx8IWYRQOQqGRN7UNsWbk6K434AcskOhDaw2cHB
# zUTeTGLOuks4BQRRkTnrvyuaN6JGPRgfbozdqdHLltomtEgAfODqVLSqgWq4Ltxk
# na/ZOt1Iccobt3K3YxtSpSCTR3LqD2WgvxfgFR4t7QlEKSZi/YEhQbn7wdvRKCNi
# hGs=
# SIG # End signature block
