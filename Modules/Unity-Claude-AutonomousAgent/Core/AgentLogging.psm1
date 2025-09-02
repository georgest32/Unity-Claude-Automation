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
# MIIFzgYJKoZIhvcNAQcCoIIFvzCCBbsCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCBxeK58GwPxOgFq
# OZQPAy3qrIuX4dBxSzW9an91sjKsbKCCAzAwggMsMIICFKADAgECAhB1HRbZIqgr
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
# MAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIPWunhsGL/663+5fwHSXOhQF
# LgfJvr0tBAXjs5wUihglMA0GCSqGSIb3DQEBAQUABIIBAGmpvIAchbgradCSyW+O
# v5v4ZGpwoaHfMyI9xGa9qNqbKFBUGU6NjPVtnxdrdFez3bKt932m5mFYpefBP9De
# cohX0NStuVXZraXXfU5bs4SLOQryPTCnl3MFaLXtKSXMiH2mdvctTZwWaiqV2MVi
# lXu46ABgjaYzcTuePt5RqE1JJS8L3xeq/4XvMH4SUWnIDgjU5SLD6vF5MjkHIm2r
# 8rihAIx/LnyqsSO1tmwnUo48DJf2enj/KrEtBC44xxR7e85gqtgPnJyiWaj5631A
# zuZ8F2Br5KXLU78kVMhIHLDXUlUTP0m9ACLvmOU9QEyGCTQANFTCR15kOSytJWy1
# 0xQ=
# SIG # End signature block
