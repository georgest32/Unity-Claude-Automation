# AgentLogging.psm1
# Thread-safe logging functions for Unity-Claude Autonomous Agent
# Extracted from main module during refactoring
# Date: 2025-08-18

#region Module Variables

# Thread-safe logging using mutex with error handling
try {
    $script:LogMutex = New-Object System.Threading.Mutex($false, "UnityClaudeAutonomousAgentLog")
} catch {
    # If mutex creation fails, create a local one
    $script:LogMutex = New-Object System.Threading.Mutex($false)
}

# Ensure log path is in the correct directory
$script:LogPath = Join-Path (Split-Path (Split-Path $PSScriptRoot -Parent) -Parent) "unity_claude_automation.log"

# Create log directory if it doesn't exist
$logDir = Split-Path $script:LogPath -Parent
if (-not (Test-Path $logDir)) {
    New-Item -ItemType Directory -Path $logDir -Force | Out-Null
}
$script:MaxLogSize = 10MB  # Maximum log file size before rotation
$script:LogRetentionDays = 30  # Days to keep old log files

#endregion

#region Core Logging Functions

function Write-AgentLog {
    <#
    .SYNOPSIS
    Thread-safe logging function for autonomous agent operations
    
    .DESCRIPTION
    Writes log entries to the central unity_claude_automation.log file with mutex protection
    for thread-safe operation across multiple autonomous processes
    
    .PARAMETER Message
    The log message to write
    
    .PARAMETER Level
    Log level (DEBUG, INFO, WARNING, ERROR, SUCCESS)
    
    .PARAMETER Component
    Component name for log entry categorization
    
    .PARAMETER NoConsole
    Suppress console output
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Message,
        
        [Parameter()]
        [ValidateSet("DEBUG", "INFO", "WARNING", "ERROR", "SUCCESS")]
        [string]$Level = "INFO",
        
        [Parameter()]
        [string]$Component = "AutonomousAgent",
        
        [switch]$NoConsole
    )
    
    try {
        # Try to acquire mutex for thread-safe file writing
        $acquired = $false
        try {
            $acquired = $script:LogMutex.WaitOne(1000)  # 1 second timeout
        } catch {
            # If mutex fails, continue without it
            $acquired = $false
        }
        
        if (-not $acquired) {
            # Continue without mutex but add PID to avoid conflicts
            $Component = "$Component-$PID"
        }
        
        $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss.fff"
        $logEntry = "[$timestamp] [$Level] [$Component] $Message"
        
        # Check log rotation
        if ((Test-Path $script:LogPath) -and (Get-Item $script:LogPath).Length -gt $script:MaxLogSize) {
            Invoke-LogRotation
        }
        
        # Write to log file with retry logic for locked files
        $retryCount = 0
        $maxRetries = 3
        $written = $false
        
        while (-not $written -and $retryCount -lt $maxRetries) {
            try {
                Add-Content -Path $script:LogPath -Value $logEntry -Encoding UTF8 -Force -ErrorAction Stop
                $written = $true
            }
            catch {
                $retryCount++
                if ($retryCount -lt $maxRetries) {
                    Start-Sleep -Milliseconds 100
                } else {
                    # Fall back to alternate log file
                    $altLogPath = $script:LogPath -replace '\.log$', "_$PID.log"
                    try {
                        Add-Content -Path $altLogPath -Value $logEntry -Encoding UTF8 -Force
                        $written = $true
                    }
                    catch {
                        # Last resort: write to console only
                        if (-not $NoConsole) {
                            Write-Warning "Could not write to log: $($_.Exception.Message)"
                        }
                    }
                }
            }
        }
        
        # Console output with color coding (unless suppressed)
        if (-not $NoConsole) {
            switch ($Level) {
                "ERROR" { Write-Host $logEntry -ForegroundColor Red }
                "WARNING" { Write-Host $logEntry -ForegroundColor Yellow }
                "SUCCESS" { Write-Host $logEntry -ForegroundColor Green }
                "DEBUG" { 
                    if ($DebugPreference -ne 'SilentlyContinue') {
                        Write-Host $logEntry -ForegroundColor Cyan 
                    }
                }
                default { Write-Host $logEntry -ForegroundColor Gray }
            }
        }
    }
    catch {
        Write-Error "Failed to write to agent log: $_"
    }
    finally {
        # Always release mutex if acquired
        if ($acquired) {
            $script:LogMutex.ReleaseMutex()
        }
    }
}

function Initialize-AgentLogging {
    <#
    .SYNOPSIS
    Initializes logging system for autonomous agent
    
    .DESCRIPTION
    Sets up the logging infrastructure, creates necessary directories, and performs initial cleanup
    
    .PARAMETER LogPath
    Override default log path
    
    .PARAMETER RotateOnStart
    Force log rotation on initialization
    #>
    [CmdletBinding()]
    param(
        [string]$LogPath,
        [switch]$RotateOnStart
    )
    
    # Override log path if provided
    if ($LogPath) {
        $script:LogPath = $LogPath
    }
    
    # Ensure log directory exists
    $logDir = Split-Path $script:LogPath -Parent
    if (-not (Test-Path $logDir)) {
        New-Item -Path $logDir -ItemType Directory -Force | Out-Null
    }
    
    # Rotate log if requested
    if ($RotateOnStart -and (Test-Path $script:LogPath)) {
        Invoke-LogRotation
    }
    
    # Clean up old logs
    Remove-OldLogFiles
    
    Write-AgentLog -Message "Autonomous agent logging system initialized" -Level "INFO"
    Write-AgentLog -Message "Log path: $script:LogPath" -Level "DEBUG"
    Write-AgentLog -Message "Max log size: $($script:MaxLogSize / 1MB)MB" -Level "DEBUG"
    Write-AgentLog -Message "Log retention: $script:LogRetentionDays days" -Level "DEBUG"
}

#endregion

#region Log Management Functions

function Invoke-LogRotation {
    <#
    .SYNOPSIS
    Rotates the current log file
    
    .DESCRIPTION
    Renames current log file with timestamp and starts a new log file
    #>
    [CmdletBinding()]
    param()
    
    try {
        if (Test-Path $script:LogPath) {
            $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
            $archiveName = [System.IO.Path]::GetFileNameWithoutExtension($script:LogPath)
            $archiveExt = [System.IO.Path]::GetExtension($script:LogPath)
            $archivePath = Join-Path (Split-Path $script:LogPath -Parent) "$archiveName.$timestamp$archiveExt"
            
            Move-Item -Path $script:LogPath -Destination $archivePath -Force
            
            # Create new log entry in the new file
            Add-Content -Path $script:LogPath -Value "[$((Get-Date).ToString('yyyy-MM-dd HH:mm:ss.fff'))] [INFO] [AgentLogging] Log rotated from: $archivePath" -Encoding UTF8
        }
    }
    catch {
        Write-Warning "Failed to rotate log file: $_"
    }
}

function Remove-OldLogFiles {
    <#
    .SYNOPSIS
    Removes log files older than retention period
    
    .DESCRIPTION
    Cleans up archived log files that exceed the retention period
    #>
    [CmdletBinding()]
    param()
    
    try {
        $logDir = Split-Path $script:LogPath -Parent
        $logName = [System.IO.Path]::GetFileNameWithoutExtension($script:LogPath)
        $logExt = [System.IO.Path]::GetExtension($script:LogPath)
        
        # Find archived log files
        $archivePattern = "$logName.*$logExt"
        $cutoffDate = (Get-Date).AddDays(-$script:LogRetentionDays)
        
        Get-ChildItem -Path $logDir -Filter $archivePattern | 
            Where-Object { $_.LastWriteTime -lt $cutoffDate } |
            ForEach-Object {
                Remove-Item $_.FullName -Force
                Write-AgentLog -Message "Removed old log file: $($_.Name)" -Level "DEBUG" -NoConsole
            }
    }
    catch {
        Write-Warning "Failed to clean up old log files: $_"
    }
}

function Get-AgentLogPath {
    <#
    .SYNOPSIS
    Gets the current log file path
    
    .DESCRIPTION
    Returns the path to the current active log file
    #>
    [CmdletBinding()]
    param()
    
    return $script:LogPath
}

function Get-AgentLogStatistics {
    <#
    .SYNOPSIS
    Gets statistics about the log file
    
    .DESCRIPTION
    Returns information about log file size, entry count, and age
    #>
    [CmdletBinding()]
    param()
    
    $stats = @{
        Path = $script:LogPath
        Exists = Test-Path $script:LogPath
        Size = 0
        SizeMB = 0
        LineCount = 0
        OldestEntry = $null
        NewestEntry = $null
        Age = $null
    }
    
    if ($stats.Exists) {
        $fileInfo = Get-Item $script:LogPath
        $stats.Size = $fileInfo.Length
        $stats.SizeMB = [Math]::Round($fileInfo.Length / 1MB, 2)
        $stats.Age = (Get-Date) - $fileInfo.CreationTime
        
        # Get line count and timestamps
        $content = Get-Content $script:LogPath
        $stats.LineCount = $content.Count
        
        if ($content.Count -gt 0) {
            # Parse first and last timestamps
            if ($content[0] -match '\[(\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}\.\d{3})\]') {
                $stats.OldestEntry = [DateTime]::ParseExact($matches[1], "yyyy-MM-dd HH:mm:ss.fff", $null)
            }
            if ($content[-1] -match '\[(\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}\.\d{3})\]') {
                $stats.NewestEntry = [DateTime]::ParseExact($matches[1], "yyyy-MM-dd HH:mm:ss.fff", $null)
            }
        }
    }
    
    return $stats
}

function Clear-AgentLog {
    <#
    .SYNOPSIS
    Clears the current log file
    
    .DESCRIPTION
    Archives the current log file and starts fresh
    
    .PARAMETER NoArchive
    If specified, deletes the log file instead of archiving
    #>
    [CmdletBinding()]
    param(
        [switch]$NoArchive
    )
    
    try {
        if (Test-Path $script:LogPath) {
            if ($NoArchive) {
                Remove-Item $script:LogPath -Force
                Write-Host "Log file cleared" -ForegroundColor Yellow
            } else {
                Invoke-LogRotation
                Write-Host "Log file archived and cleared" -ForegroundColor Green
            }
        }
        
        # Write initial entry
        Write-AgentLog -Message "Log cleared by user request" -Level "INFO"
    }
    catch {
        Write-Error "Failed to clear log: $_"
    }
}

#endregion

# Export module functions
Export-ModuleMember -Function @(
    'Write-AgentLog',
    'Initialize-AgentLogging',
    'Invoke-LogRotation',
    'Remove-OldLogFiles',
    'Get-AgentLogPath',
    'Get-AgentLogStatistics',
    'Clear-AgentLog'
)
# SIG # Begin signature block
# MIIFqQYJKoZIhvcNAQcCoIIFmjCCBZYCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUfBPyZfFFyNdVSw2iLNy/ZQew
# roCgggMwMIIDLDCCAhSgAwIBAgIQdR0W2SKoK5VE8JId4ZxrRTANBgkqhkiG9w0B
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
# CQQxFgQUNbLErjB7sLS4Et1HJh2CbLEkf2QwDQYJKoZIhvcNAQEBBQAEggEAArGb
# AtH2NMXCH4DxiumvOC19DMw5/7yexzKC4qZpT/lFkm9lYFqMgbwPVkkuAPajK+WM
# fATHUtGLZFyoXvWViTn+a11aeJL4u7JUStr3kr+CrIvsxWRQDxX6uht/Ff7/uDTx
# 737AeUBKbcsq1uzpHopF6gX2ulvUimNbuN0ySu6rlKzPalSXmFbmqgBikmJF+MU0
# D4y5Sr5udQ0mwAMsxalg/fSq865xAxzBexc3n6jW0MNVq4B8RQ4vTwqR87T8dy3R
# 6g/mlrGoPjIZhsbDAD5eHUNQm0GwdhPpsddKs/fBoeBToF75PNpDIK1XOEYVKNss
# IGGSES1dFZxTrUCW1g==
# SIG # End signature block
