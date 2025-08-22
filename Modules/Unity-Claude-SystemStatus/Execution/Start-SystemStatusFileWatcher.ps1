
function Start-SystemStatusFileWatcher {
    [CmdletBinding()]
    param()
    
    Write-SystemStatusLog "Starting real-time file system monitoring..." -Level 'INFO'
    
    try {
        # Stop existing watcher if running
        Stop-SystemStatusFileWatcher
        
        # Create FileSystemWatcher for system status file (building on existing patterns)
        $statusFileDir = Split-Path $script:SystemStatusConfig.SystemStatusFile -Parent
        $statusFileName = Split-Path $script:SystemStatusConfig.SystemStatusFile -Leaf
        
        $script:CommunicationState.FileWatcher = New-Object System.IO.FileSystemWatcher
        $script:CommunicationState.FileWatcher.Path = $statusFileDir
        $script:CommunicationState.FileWatcher.Filter = $statusFileName
        $script:CommunicationState.FileWatcher.NotifyFilter = [System.IO.NotifyFilters]::LastWrite
        $script:CommunicationState.FileWatcher.EnableRaisingEvents = $true
        
        # Event handler with 3-second debouncing (Day 17 research finding)
        $script:CommunicationState.FileWatcher.add_Changed({
            param($sender, $eventArgs)
            
            try {
                # Debouncing logic to prevent excessive updates
                $currentTime = Get-Date
                if ($script:CommunicationState.LastMessageTime -and 
                    ($currentTime - $script:CommunicationState.LastMessageTime).TotalSeconds -lt 3) {
                    return  # Skip update due to debouncing
                }
                
                $script:CommunicationState.LastMessageTime = $currentTime
                
                Write-SystemStatusLog "System status file changed - triggering real-time update" -Level 'DEBUG'
                
                # Send status update message to all registered subsystems (safely)
                try {
                    $message = New-SystemStatusMessage -MessageType "StatusUpdate" -Source "Unity-Claude-SystemStatus" -Target "All"
                    $payload = @{
                        updateType = "FileChanged"
                        timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss.fff'
                        filePath = $eventArgs.FullPath
                    }
                    $message.payload = $payload
                    
                    Send-SystemStatusMessage -Message $message | Out-Null
                } catch {
                    # Silently ignore message send errors to prevent crashes
                }
            } catch {
                # Silently ignore all file watcher errors to prevent crashes
            }
        })
        
        Write-SystemStatusLog "File system watcher started successfully" -Level 'OK'
        return $true
        
    } catch {
        Write-SystemStatusLog "Error starting file system watcher - $($_.Exception.Message)" -Level 'ERROR'
        return $false
    }
}

# SIG # Begin signature block
# MIIFqQYJKoZIhvcNAQcCoIIFmjCCBZYCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUJw/E/yq+s35/aOUrgMu+9cy/
# F0igggMwMIIDLDCCAhSgAwIBAgIQdR0W2SKoK5VE8JId4ZxrRTANBgkqhkiG9w0B
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
# CQQxFgQUX7fUzmlNzTSw4r0vI9Euoskur+IwDQYJKoZIhvcNAQEBBQAEggEASqa8
# aX+yupItNlvf6nd1GysHJBGpRb2W0/l/p+hpPqiYgQnddH0SdDz1aYaBjuKzjjgw
# DKkGSvjjN/MR622dwKlOgqElpo3/kuLSQP/uzbRImOCDipvnSOZsF14tj48Fi2xY
# cqWAgqOGWJPVwVKKqqSlJJ/ZiPnShS5fa/d93fA+WBjGWP6qlyZjqhjQ2f42Kdhg
# duQONddMJVtKhEzeZmm9Acgun1w7wxrg3VCAtdYXj0lcBzuwWyKcVimaaOI5aeWq
# /wvCgju6o9pOCYhaIh95WKJyQu7Pvr3yt/N+cY7IMliXM1cLU0FHPrs95B1KfkeS
# BZni8P/7K6JnT2ojLQ==
# SIG # End signature block
