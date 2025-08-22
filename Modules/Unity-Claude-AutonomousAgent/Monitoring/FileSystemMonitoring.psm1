# FileSystemMonitoring.psm1
# FileSystemWatcher implementation for monitoring Claude Code CLI responses
# Extracted from main module during refactoring
# Date: 2025-08-18

#region Module Dependencies

# Import required modules
Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) "Core\AgentCore.psm1") -Force
Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) "Core\AgentLogging.psm1") -Force

#endregion

#region FileSystemWatcher Implementation

function Start-ClaudeResponseMonitoring {
    <#
    .SYNOPSIS
    Starts FileSystemWatcher monitoring for Claude Code CLI responses
    
    .DESCRIPTION
    Monitors the Claude output directory for new response files created by headless mode
    Implements debouncing and thread-safe event handling
    
    .PARAMETER OutputDirectory
    Directory to monitor for Claude responses
    
    .PARAMETER DebounceMs
    Milliseconds to wait before processing file changes
    
    .PARAMETER Filter
    File filter pattern (default: *.json)
    #>
    [CmdletBinding()]
    param(
        [string]$OutputDirectory = (Get-AgentConfig -Setting "ClaudeOutputDirectory"),
        [int]$DebounceMs = (Get-AgentConfig -Setting "DebounceMs"),
        [string]$Filter = "*.json"
    )
    
    Write-AgentLog -Message "Starting Claude response monitoring" -Level "INFO"
    Write-AgentLog -Message "Monitoring directory: $OutputDirectory" -Level "DEBUG"
    Write-AgentLog -Message "Filter: $Filter, Debounce: ${DebounceMs}ms" -Level "DEBUG"
    
    try {
        # Ensure directory exists
        if (-not (Test-Path $OutputDirectory)) {
            New-Item -Path $OutputDirectory -ItemType Directory -Force | Out-Null
            Write-AgentLog -Message "Created monitoring directory: $OutputDirectory" -Level "INFO"
        }
        
        # Get current state
        $agentState = Get-AgentState
        
        # Create FileSystemWatcher with increased buffer size
        $watcher = New-Object System.IO.FileSystemWatcher
        $watcher.Path = $OutputDirectory
        $watcher.Filter = $Filter
        $watcher.IncludeSubdirectories = $false
        $watcher.NotifyFilter = [System.IO.NotifyFilters]::Creation -bor [System.IO.NotifyFilters]::LastWrite
        $watcher.InternalBufferSize = 32768  # Increase from default 8192 to prevent buffer overflow
        
        # Register event handlers with proper scope and global scope access
        $createdEvent = Register-ObjectEvent -InputObject $watcher -EventName "Created" -SourceIdentifier "FSWatcher_Created" -MessageData @{
            DebounceMs = $DebounceMs
            OutputDirectory = $OutputDirectory
        } -Action {
            try {
                $timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss.fff'
                
                # Log event handler entry
                $entryMessage = "[$timestamp] [DEBUG] [FileWatcher] CREATED EVENT HANDLER TRIGGERED"
                Add-Content -Path "C:\UnityProjects\Sound-and-Shoal\Unity-Claude-Automation\unity_claude_automation.log" -Value $entryMessage
                
                $filePath = $Event.SourceEventArgs.FullPath
                $config = $Event.MessageData
                
                $logMessage = "[$timestamp] [DEBUG] [FileWatcher] File created - $filePath"
                Add-Content -Path "C:\UnityProjects\Sound-and-Shoal\Unity-Claude-Automation\unity_claude_automation.log" -Value $logMessage
                
                $configMessage = "[$timestamp] [DEBUG] [FileWatcher] Config - DebounceMs: $($config.DebounceMs), OutputDir: $($config.OutputDirectory)"
                Add-Content -Path "C:\UnityProjects\Sound-and-Shoal\Unity-Claude-Automation\unity_claude_automation.log" -Value $configMessage
                
                # Implement debouncing - wait before processing
                $debounceMessage = "[$timestamp] [DEBUG] [FileWatcher] Starting debounce wait: $($config.DebounceMs)ms"
                Add-Content -Path "C:\UnityProjects\Sound-and-Shoal\Unity-Claude-Automation\unity_claude_automation.log" -Value $debounceMessage
                
                Start-Sleep -Milliseconds $config.DebounceMs
                
                $afterDebounceMessage = "[$timestamp] [DEBUG] [FileWatcher] Debounce complete, processing file"
                Add-Content -Path "C:\UnityProjects\Sound-and-Shoal\Unity-Claude-Automation\unity_claude_automation.log" -Value $afterDebounceMessage
                
                # Process the response file (this will be handled by main module)
                try {
                    $pendingPath = Join-Path $config.OutputDirectory ".pending"
                    $preWriteMessage = "[$timestamp] [DEBUG] [FileWatcher] Writing to pending file: $pendingPath"
                    Add-Content -Path "C:\UnityProjects\Sound-and-Shoal\Unity-Claude-Automation\unity_claude_automation.log" -Value $preWriteMessage
                    
                    [System.IO.File]::WriteAllText($pendingPath, $filePath)
                    
                    $logMessage2 = "[$timestamp] [DEBUG] [FileWatcher] Successfully queued file for processing: $filePath"
                    Add-Content -Path "C:\UnityProjects\Sound-and-Shoal\Unity-Claude-Automation\unity_claude_automation.log" -Value $logMessage2
                }
                catch {
                    $errorMessage = "[$timestamp] [ERROR] [FileWatcher] Error queuing Claude response: $_ | Stack: $($_.ScriptStackTrace)"
                    Add-Content -Path "C:\UnityProjects\Sound-and-Shoal\Unity-Claude-Automation\unity_claude_automation.log" -Value $errorMessage
                }
            }
            catch {
                $criticalError = "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss.fff')] [CRITICAL] [FileWatcher] Event handler crashed: $_ | Stack: $($_.ScriptStackTrace)"
                Add-Content -Path "C:\UnityProjects\Sound-and-Shoal\Unity-Claude-Automation\unity_claude_automation.log" -Value $criticalError
            }
        }
        
        $changedEvent = Register-ObjectEvent -InputObject $watcher -EventName "Changed" -SourceIdentifier "FSWatcher_Changed" -MessageData @{
            DebounceMs = $DebounceMs
            OutputDirectory = $OutputDirectory
            LastProcessedFile = ""
        } -Action {
            try {
                $timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss.fff'
                
                # Log event handler entry
                $entryMessage = "[$timestamp] [DEBUG] [FileWatcher] CHANGED EVENT HANDLER TRIGGERED"
                Add-Content -Path "C:\UnityProjects\Sound-and-Shoal\Unity-Claude-Automation\unity_claude_automation.log" -Value $entryMessage
                
                # Test accessing event data
                try {
                    $filePath = $Event.SourceEventArgs.FullPath
                    $pathMessage = "[$timestamp] [DEBUG] [FileWatcher] Got file path: $filePath"
                    Add-Content -Path "C:\UnityProjects\Sound-and-Shoal\Unity-Claude-Automation\unity_claude_automation.log" -Value $pathMessage
                } catch {
                    $pathError = "[$timestamp] [ERROR] [FileWatcher] Failed to get file path: $_"
                    Add-Content -Path "C:\UnityProjects\Sound-and-Shoal\Unity-Claude-Automation\unity_claude_automation.log" -Value $pathError
                    return
                }
                
                # Test accessing message data
                try {
                    $config = $Event.MessageData
                    $configMessage = "[$timestamp] [DEBUG] [FileWatcher] Got config data - DebounceMs: $($config.DebounceMs)"
                    Add-Content -Path "C:\UnityProjects\Sound-and-Shoal\Unity-Claude-Automation\unity_claude_automation.log" -Value $configMessage
                } catch {
                    $configError = "[$timestamp] [ERROR] [FileWatcher] Failed to get config data: $_"
                    Add-Content -Path "C:\UnityProjects\Sound-and-Shoal\Unity-Claude-Automation\unity_claude_automation.log" -Value $configError
                    return
                }
                
                $logMessage = "[$timestamp] [DEBUG] [FileWatcher] File changed - $filePath"
                Add-Content -Path "C:\UnityProjects\Sound-and-Shoal\Unity-Claude-Automation\unity_claude_automation.log" -Value $logMessage
                
                $lastFileMessage = "[$timestamp] [DEBUG] [FileWatcher] LastProcessedFile: $($config.LastProcessedFile)"
                Add-Content -Path "C:\UnityProjects\Sound-and-Shoal\Unity-Claude-Automation\unity_claude_automation.log" -Value $lastFileMessage
                
                # Only process if it's not the same file we just processed
                if ($filePath -ne $config.LastProcessedFile) {
                    $processingMessage = "[$timestamp] [DEBUG] [FileWatcher] File is different from last processed, proceeding with processing"
                    Add-Content -Path "C:\UnityProjects\Sound-and-Shoal\Unity-Claude-Automation\unity_claude_automation.log" -Value $processingMessage
                    
                    # Implement debouncing
                    $debounceMessage = "[$timestamp] [DEBUG] [FileWatcher] Starting debounce wait: $($config.DebounceMs)ms"
                    Add-Content -Path "C:\UnityProjects\Sound-and-Shoal\Unity-Claude-Automation\unity_claude_automation.log" -Value $debounceMessage
                    
                    Start-Sleep -Milliseconds $config.DebounceMs
                    
                    $afterDebounceMessage = "[$timestamp] [DEBUG] [FileWatcher] Debounce complete, queuing file"
                    Add-Content -Path "C:\UnityProjects\Sound-and-Shoal\Unity-Claude-Automation\unity_claude_automation.log" -Value $afterDebounceMessage
                    
                    # Queue file for processing
                    try {
                        $pendingPath = Join-Path $config.OutputDirectory ".pending"
                        $preWriteMessage = "[$timestamp] [DEBUG] [FileWatcher] Writing to pending file: $pendingPath"
                        Add-Content -Path "C:\UnityProjects\Sound-and-Shoal\Unity-Claude-Automation\unity_claude_automation.log" -Value $preWriteMessage
                        
                        [System.IO.File]::WriteAllText($pendingPath, $filePath)
                        
                        $logMessage2 = "[$timestamp] [DEBUG] [FileWatcher] Successfully queued changed file for processing: $filePath"
                        Add-Content -Path "C:\UnityProjects\Sound-and-Shoal\Unity-Claude-Automation\unity_claude_automation.log" -Value $logMessage2
                    }
                    catch {
                        $errorMessage = "[$timestamp] [ERROR] [FileWatcher] Error queuing changed file: $_ | Stack: $($_.ScriptStackTrace)"
                        Add-Content -Path "C:\UnityProjects\Sound-and-Shoal\Unity-Claude-Automation\unity_claude_automation.log" -Value $errorMessage
                    }
                } else {
                    $skipMessage = "[$timestamp] [DEBUG] [FileWatcher] Skipping file (same as last processed): $filePath"
                    Add-Content -Path "C:\UnityProjects\Sound-and-Shoal\Unity-Claude-Automation\unity_claude_automation.log" -Value $skipMessage
                }
            }
            catch {
                $criticalError = "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss.fff')] [CRITICAL] [FileWatcher] CHANGED event handler crashed: $_ | Stack: $($_.ScriptStackTrace)"
                Add-Content -Path "C:\UnityProjects\Sound-and-Shoal\Unity-Claude-Automation\unity_claude_automation.log" -Value $criticalError
            }
        }
        
        # Start monitoring
        $watcher.EnableRaisingEvents = $true
        
        # Update agent state
        Set-AgentState -Properties @{
            FileWatcher = $watcher
            IsMonitoring = $true
        }
        
        Write-AgentLog -Message "Claude response monitoring started successfully" -Level "SUCCESS"
        Write-AgentLog -Message "Monitoring filter: $Filter in $OutputDirectory" -Level "DEBUG"
        Write-AgentLog -Message "Event handlers registered: Created=$($createdEvent.Name), Changed=$($changedEvent.Name)" -Level "DEBUG"
        
        return @{
            Success = $true
            Watcher = $watcher
            EventHandlers = @($createdEvent.Name, $changedEvent.Name)
        }
    }
    catch {
        Write-AgentLog -Message "Failed to start Claude response monitoring: $_" -Level "ERROR"
        return @{
            Success = $false
            Error = $_.Exception.Message
        }
    }
}

function Stop-ClaudeResponseMonitoring {
    <#
    .SYNOPSIS
    Stops FileSystemWatcher monitoring and cleans up resources
    
    .DESCRIPTION
    Disables file monitoring, disposes of the watcher, and unregisters event handlers
    #>
    [CmdletBinding()]
    param()
    
    Write-AgentLog -Message "Stopping Claude response monitoring" -Level "INFO"
    
    try {
        $agentState = Get-AgentState
        
        if ($agentState.FileWatcher) {
            # Disable monitoring
            $agentState.FileWatcher.EnableRaisingEvents = $false
            
            # Dispose watcher
            $agentState.FileWatcher.Dispose()
            
            Write-AgentLog -Message "FileSystemWatcher disposed successfully" -Level "DEBUG"
        }
        
        # Unregister event handlers
        $unregisteredCount = 0
        Get-EventSubscriber | Where-Object { 
            $_.SourceIdentifier -like "*FileSystemWatcher*" -or 
            $_.SourceObject -is [System.IO.FileSystemWatcher] 
        } | ForEach-Object {
            Unregister-Event -SubscriptionId $_.SubscriptionId
            $unregisteredCount++
        }
        
        Write-AgentLog -Message "Unregistered $unregisteredCount event handlers" -Level "DEBUG"
        
        # Update agent state
        Set-AgentState -Properties @{
            FileWatcher = $null
            IsMonitoring = $false
        }
        
        Write-AgentLog -Message "Claude response monitoring stopped successfully" -Level "SUCCESS"
        
        return @{
            Success = $true
            UnregisteredHandlers = $unregisteredCount
        }
    }
    catch {
        Write-AgentLog -Message "Error stopping Claude response monitoring: $_" -Level "ERROR"
        return @{
            Success = $false
            Error = $_.Exception.Message
        }
    }
}

function Get-MonitoringStatus {
    <#
    .SYNOPSIS
    Gets the current status of file system monitoring
    
    .DESCRIPTION
    Returns information about the active FileSystemWatcher and monitoring state
    #>
    [CmdletBinding()]
    param()
    
    $agentState = Get-AgentState
    
    $status = @{
        IsMonitoring = $agentState.IsMonitoring
        WatcherActive = $false
        MonitoredDirectory = $null
        Filter = $null
        EventHandlers = @()
        PendingFiles = @()
    }
    
    if ($agentState.FileWatcher) {
        $status.WatcherActive = $agentState.FileWatcher.EnableRaisingEvents
        $status.MonitoredDirectory = $agentState.FileWatcher.Path
        $status.Filter = $agentState.FileWatcher.Filter
        
        # Get registered event handlers
        $status.EventHandlers = Get-EventSubscriber | Where-Object { 
            $_.SourceObject -is [System.IO.FileSystemWatcher] 
        } | Select-Object -ExpandProperty SourceIdentifier
        
        # Check for pending files
        $pendingFile = Join-Path $agentState.FileWatcher.Path ".pending"
        if (Test-Path $pendingFile) {
            $status.PendingFiles = @(Get-Content $pendingFile)
        }
    }
    
    return $status
}

function Test-FileSystemMonitoring {
    <#
    .SYNOPSIS
    Tests the file system monitoring capability
    
    .DESCRIPTION
    Creates a test file to verify monitoring is working correctly
    
    .PARAMETER TestDirectory
    Directory to use for testing (uses configured directory by default)
    #>
    [CmdletBinding()]
    param(
        [string]$TestDirectory = (Get-AgentConfig -Setting "ClaudeOutputDirectory")
    )
    
    Write-AgentLog -Message "Testing file system monitoring" -Level "INFO" -Component "MonitoringTest"
    
    try {
        # Ensure monitoring is running
        $status = Get-MonitoringStatus
        if (-not $status.IsMonitoring) {
            Write-AgentLog -Message "Monitoring not active, starting it for test" -Level "WARNING" -Component "MonitoringTest"
            Start-ClaudeResponseMonitoring
        }
        
        # Create test file
        $testFileName = "test_response_$(Get-Date -Format 'yyyyMMdd_HHmmss').json"
        $testFilePath = Join-Path $TestDirectory $testFileName
        
        $testContent = @{
            test = $true
            timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
            message = "RECOMMENDED: TEST - This is a test file for monitoring validation"
        } | ConvertTo-Json
        
        Write-AgentLog -Message "Creating test file: $testFileName" -Level "DEBUG" -Component "MonitoringTest"
        Set-Content -Path $testFilePath -Value $testContent -Force
        
        # Wait for processing
        Start-Sleep -Seconds 3
        
        # Check if file was detected
        $pendingFile = Join-Path $TestDirectory ".pending"
        $wasDetected = $false
        
        if (Test-Path $pendingFile) {
            $pending = Get-Content $pendingFile
            $wasDetected = $pending -contains $testFilePath
        }
        
        # Clean up test file
        Remove-Item $testFilePath -Force -ErrorAction SilentlyContinue
        
        if ($wasDetected) {
            Write-AgentLog -Message "File system monitoring test PASSED" -Level "SUCCESS" -Component "MonitoringTest"
        } else {
            Write-AgentLog -Message "File system monitoring test FAILED - File not detected" -Level "ERROR" -Component "MonitoringTest"
        }
        
        return @{
            Success = $wasDetected
            TestFile = $testFileName
            Message = if ($wasDetected) { "Monitoring is working correctly" } else { "File was not detected by monitor" }
        }
    }
    catch {
        Write-AgentLog -Message "File system monitoring test error: $_" -Level "ERROR" -Component "MonitoringTest"
        return @{
            Success = $false
            Error = $_.Exception.Message
        }
    }
}

#endregion

# Export module functions
Export-ModuleMember -Function @(
    'Start-ClaudeResponseMonitoring',
    'Stop-ClaudeResponseMonitoring',
    'Get-MonitoringStatus',
    'Test-FileSystemMonitoring'
)
# SIG # Begin signature block
# MIIFqQYJKoZIhvcNAQcCoIIFmjCCBZYCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQU5eFnuwcFHTZ4oMEhxrRWoIlN
# EzqgggMwMIIDLDCCAhSgAwIBAgIQdR0W2SKoK5VE8JId4ZxrRTANBgkqhkiG9w0B
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
# CQQxFgQUQAUpgJjoehQTAlii0WHxDF6h3UQwDQYJKoZIhvcNAQEBBQAEggEAnSzQ
# ZiF2J7lBaEEZG6DF7oQIUh9z+nr2D7T5Bod7zzLuWMnCD4urHDBeILMZc22ROtDT
# INpTsnwFHNWnEvd2GgI5dze7Czp9pQyMe2bgNuDlNfxc7VR8INg5OnCyEH9se415
# RsBBjz9SkKUVp3+6rzMNKLu0UhZw56YM8coWhI4oGQspRvepvZ526FFmCIFC4Pmg
# D/Fgn6Dm1rjqcypKVNQnFOzSyb17sn6cNNPBlECUyuoq/Z1Fc7JgsWbZcfhHbsnu
# 9wiDRLpSbB0YnwB09svhba1TmQlBIkunhr/RDhP7F1XO7Hllp769d7PkH2/NRyrc
# azzdBfDsqw10My6UXQ==
# SIG # End signature block
