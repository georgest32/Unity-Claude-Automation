function Invoke-LogRotation {
    <#
    .SYNOPSIS
    Performs size-based log rotation with compression and archive management
    
    .DESCRIPTION
    Implements automated log rotation following PowerShell best practices for 2025:
    - Size-based rotation with configurable thresholds
    - Archive management with retention policy
    - Optional compression of rotated logs
    - PowerShell 5.1 compatible implementation
    - Thread-safe rotation with mutex protection
    
    .PARAMETER LogPath
    Path to the log file to check for rotation
    
    .PARAMETER MaxSizeMB
    Maximum size in MB before rotation (default: 10MB)
    
    .PARAMETER MaxLogFiles
    Maximum number of rotated log files to keep (default: 5)
    
    .PARAMETER CompressOldLogs
    Compress rotated log files to save space
    
    .EXAMPLE
    Invoke-LogRotation -LogPath ".\unity_claude_automation.log"
    
    .EXAMPLE
    Invoke-LogRotation -LogPath ".\unity_claude_automation.log" -MaxSizeMB 50 -MaxLogFiles 10 -CompressOldLogs
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$LogPath,
        
        [int]$MaxSizeMB = 10,
        
        [int]$MaxLogFiles = 5,
        
        [switch]$CompressOldLogs
    )
    
    try {
        # Check if log file exists and needs rotation
        if (-not (Test-Path $LogPath)) {
            return
        }
        
        $logFile = Get-Item $LogPath
        $currentSizeMB = [math]::Round($logFile.Length / 1MB, 2)
        
        Write-SystemStatusLog "Checking log rotation: $LogPath ($currentSizeMB MB / $MaxSizeMB MB)" -Level 'TRACE' -Source 'LogRotation'
        
        if ($currentSizeMB -lt $MaxSizeMB) {
            return
        }
        
        Write-SystemStatusLog "Log rotation triggered: file size $currentSizeMB MB exceeds $MaxSizeMB MB threshold" -Level 'INFO' -Source 'LogRotation'
        
        # Use mutex for thread-safe rotation
        $mutexName = "Global\UnityClaudeLogRotation_$($logFile.Name)"
        $mutex = $null
        $acquired = $false
        
        try {
            $mutex = New-Object System.Threading.Mutex($false, $mutexName)
            $acquired = $mutex.WaitOne(5000) # 5 second timeout
            
            if (-not $acquired) {
                Write-SystemStatusLog "Log rotation already in progress by another process" -Level 'WARN' -Source 'LogRotation'
                return
            }
            
            # Re-check file size after acquiring mutex (another process might have rotated)
            if (Test-Path $LogPath) {
                $currentFile = Get-Item $LogPath
                $newSizeMB = [math]::Round($currentFile.Length / 1MB, 2)
                if ($newSizeMB -lt $MaxSizeMB) {
                    Write-SystemStatusLog "Log already rotated by another process" -Level 'INFO' -Source 'LogRotation'
                    return
                }
            }
            
            $timestamp = Get-Date -Format 'yyyyMMdd_HHmmss'
            $logDir = Split-Path $LogPath -Parent
            $logName = [System.IO.Path]::GetFileNameWithoutExtension($LogPath)
            $logExt = [System.IO.Path]::GetExtension($LogPath)
            
            # Rotate existing numbered logs (highest number first)
            for ($i = $MaxLogFiles; $i -gt 1; $i--) {
                $oldFile = Join-Path $logDir "$logName.$($i-1)$logExt"
                $newFile = Join-Path $logDir "$logName.$i$logExt"
                
                if (Test-Path $oldFile) {
                    if (Test-Path $newFile) {
                        Remove-Item $newFile -Force -ErrorAction SilentlyContinue
                    }
                    Move-Item $oldFile $newFile -ErrorAction SilentlyContinue
                    Write-SystemStatusLog "Rotated $oldFile to $newFile" -Level 'TRACE' -Source 'LogRotation'
                }
            }
            
            # Move current log to .1
            $rotatedFile = Join-Path $logDir "$logName.1$logExt"
            if (Test-Path $rotatedFile) {
                Remove-Item $rotatedFile -Force -ErrorAction SilentlyContinue
            }
            
            Move-Item $LogPath $rotatedFile -ErrorAction Stop
            Write-SystemStatusLog "Rotated current log to $rotatedFile" -Level 'INFO' -Source 'LogRotation'
            
            # Compress old logs if requested
            if ($CompressOldLogs) {
                Compress-RotatedLogs -LogDir $logDir -LogName $logName -LogExt $logExt -MaxLogFiles $MaxLogFiles
            }
            
            # Clean up excess log files
            Remove-ExcessLogFiles -LogDir $logDir -LogName $logName -LogExt $logExt -MaxLogFiles $MaxLogFiles
            
            # Create new empty log file
            New-Item $LogPath -ItemType File -Force | Out-Null
            Write-SystemStatusLog "Log rotation completed successfully" -Level 'OK' -Source 'LogRotation'
            
        } finally {
            if ($acquired -and $mutex) {
                $mutex.ReleaseMutex()
            }
            if ($mutex) {
                $mutex.Dispose()
            }
        }
        
    } catch {
        Write-SystemStatusLog "Log rotation failed: $($_.Exception.Message)" -Level 'ERROR' -Source 'LogRotation'
    }
}

function Compress-RotatedLogs {
    <#
    .SYNOPSIS
    Compresses rotated log files to save disk space
    #>
    param(
        [string]$LogDir,
        [string]$LogName,
        [string]$LogExt,
        [int]$MaxLogFiles
    )
    
    try {
        # Compress logs .2 and higher (keep .1 uncompressed for easy access)
        for ($i = 2; $i -le $MaxLogFiles; $i++) {
            $logFile = Join-Path $LogDir "$LogName.$i$LogExt"
            $zipFile = Join-Path $LogDir "$LogName.$i.zip"
            
            if ((Test-Path $logFile) -and -not (Test-Path $zipFile)) {
                try {
                    # PowerShell 5.1 compatible compression
                    Add-Type -AssemblyName System.IO.Compression.FileSystem
                    [System.IO.Compression.ZipFile]::CreateFromDirectory((Split-Path $logFile -Parent), $zipFile)
                    
                    # Verify compression worked and remove original
                    if (Test-Path $zipFile) {
                        $originalSize = (Get-Item $logFile).Length
                        $compressedSize = (Get-Item $zipFile).Length
                        $compressionRatio = [math]::Round((1 - ($compressedSize / $originalSize)) * 100, 1)
                        
                        Remove-Item $logFile -Force
                        Write-SystemStatusLog "Compressed $logFile (saved $compressionRatio%)" -Level 'DEBUG' -Source 'LogRotation'
                    }
                } catch {
                    Write-SystemStatusLog "Failed to compress $logFile : $($_.Exception.Message)" -Level 'WARN' -Source 'LogRotation'
                }
            }
        }
    } catch {
        Write-SystemStatusLog "Log compression failed: $($_.Exception.Message)" -Level 'WARN' -Source 'LogRotation'
    }
}

function Remove-ExcessLogFiles {
    <#
    .SYNOPSIS
    Removes log files that exceed the maximum retention count
    #>
    param(
        [string]$LogDir,
        [string]$LogName,
        [string]$LogExt,
        [int]$MaxLogFiles
    )
    
    try {
        # Remove numbered logs beyond the limit
        $excessStart = $MaxLogFiles + 1
        for ($i = $excessStart; $i -le ($MaxLogFiles + 10); $i++) { # Check 10 extra files
            $logFile = Join-Path $LogDir "$LogName.$i$LogExt"
            $zipFile = Join-Path $LogDir "$LogName.$i.zip"
            
            if (Test-Path $logFile) {
                Remove-Item $logFile -Force -ErrorAction SilentlyContinue
                Write-SystemStatusLog "Removed excess log file: $logFile" -Level 'DEBUG' -Source 'LogRotation'
            }
            
            if (Test-Path $zipFile) {
                Remove-Item $zipFile -Force -ErrorAction SilentlyContinue
                Write-SystemStatusLog "Removed excess compressed log: $zipFile" -Level 'DEBUG' -Source 'LogRotation'
            }
        }
        
        # Also remove any old timestamp-based logs (legacy cleanup)
        $timestampPattern = "$LogName_????????_??????$LogExt"
        $oldLogs = Get-ChildItem -Path $LogDir -Filter $timestampPattern -ErrorAction SilentlyContinue
        
        if ($oldLogs) {
            # Keep only the most recent timestamp logs, remove the rest
            $sortedLogs = $oldLogs | Sort-Object LastWriteTime -Descending
            $logsToRemove = $sortedLogs | Select-Object -Skip $MaxLogFiles
            
            foreach ($log in $logsToRemove) {
                Remove-Item $log.FullName -Force -ErrorAction SilentlyContinue
                Write-SystemStatusLog "Removed legacy log file: $($log.Name)" -Level 'DEBUG' -Source 'LogRotation'
            }
        }
        
    } catch {
        Write-SystemStatusLog "Excess log cleanup failed: $($_.Exception.Message)" -Level 'WARN' -Source 'LogRotation'
    }
}
# SIG # Begin signature block
# MIIFzgYJKoZIhvcNAQcCoIIFvzCCBbsCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCBvfW9skRvvo6v0
# iICp3ynaxk/RLUaQjwen8ixJcezq16CCAzAwggMsMIICFKADAgECAhB1HRbZIqgr
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
# MAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEILyWi0qkWe1YRT+vI8d1DfdG
# PKDz/VFxf9gpkKz7lwzpMA0GCSqGSIb3DQEBAQUABIIBACOZ6m3H/eR60Xg2qxd8
# QmtwTKQxg2/Xhh8RDkYafyvdA3cBEgCcKhny/Z00tZ4CUikLNhVixAb/s5EQdJl4
# //ka6C3qZx/F72jTlZhwr3C2MaMxTVb55mSu1DiyfkOHjGFX1CtmHRCWuQfBsxmV
# +QbMFmkG+6BNqILt7bLoDBVoly1or81wyChn69toJb5KWNxrpekA+QCy2VEK7sKx
# AdnQOMLTLBc9PHTQks6cf1zrpgrrz9OtwIV9sZER65rrHYgqEOiqQWW5ZTmypUiS
# eWaFS7rN6kAoEjocIXHDmkeUAhUDYL2BgGv05eUTBTc2Eey/UdeQlB5PbsLBZgUU
# zO4=
# SIG # End signature block
