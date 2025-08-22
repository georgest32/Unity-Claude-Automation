# Unity-Claude-ResponseMonitor Module
# Claude Code CLI Output Monitoring System for Day 17 Integration
# Real-time response detection with FileSystemWatcher and autonomous conversation management
# Compatible with PowerShell 5.1 and Unity 2021.1.14f1

# Module-level variables
$script:ResponseMonitorConfig = @{
    EnableDebugLogging = $true
    MonitorPath = "C:\Users\georg\.claude"
    ResponseFilePattern = "*.md"
    DebounceDelayMs = 500
    RefreshCycleMs = 3000
    MaxResponseSizeMB = 10
    TimeoutSeconds = 30
    IntegrationEnabled = $true
}

$script:LogPath = "C:\UnityProjects\Sound-and-Shoal\Unity-Claude-Automation\unity_claude_automation.log"

# Module state tracking
$script:FileSystemWatcher = $null
$script:MonitoringActive = $false
$script:LastResponseTime = Get-Date
$script:DebounceTimer = $null
$script:ResponseQueue = [System.Collections.Queue]::new()

# Import required modules if available
if (Get-Module -ListAvailable -Name "ConversationStateManager") {
    Import-Module "ConversationStateManager" -Force -ErrorAction SilentlyContinue
}

#region Logging and Utilities

function Write-ResponseMonitorLog {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Message,
        
        [Parameter()]
        [ValidateSet("INFO", "WARN", "ERROR", "DEBUG")]
        [string]$Level = "INFO"
    )
    
    if (-not $script:ResponseMonitorConfig.EnableDebugLogging -and $Level -eq "DEBUG") {
        return
    }
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logEntry = "[$timestamp] [$Level] [ResponseMonitor] $Message"
    
    try {
        Add-Content -Path $script:LogPath -Value $logEntry -Encoding UTF8 -ErrorAction SilentlyContinue
    } catch {
        # Silently continue if logging fails
    }
    
    if ($Level -eq "ERROR") {
        Write-Error $Message
    } elseif ($Level -eq "WARN") {
        Write-Warning $Message
    } elseif ($script:ResponseMonitorConfig.EnableDebugLogging) {
        Write-Host "[$Level] $Message" -ForegroundColor $(
            switch ($Level) {
                "INFO" { "Green" }
                "DEBUG" { "Gray" }
                default { "White" }
            }
        )
    }
}

function Test-RequiredModule {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$ModuleName
    )
    
    $module = Get-Module -Name $ModuleName -ErrorAction SilentlyContinue
    if (-not $module) {
        Write-ResponseMonitorLog -Message "Required module '$ModuleName' not loaded" -Level "WARN"
        return $false
    }
    return $true
}

#endregion

#region Configuration Management

function Get-ResponseMonitorConfig {
    [CmdletBinding()]
    param()
    
    Write-ResponseMonitorLog -Message "Retrieving Response Monitor configuration" -Level "DEBUG"
    return $script:ResponseMonitorConfig.Clone()
}

function Set-ResponseMonitorConfig {
    [CmdletBinding()]
    param(
        [Parameter()]
        [bool]$EnableDebugLogging,
        
        [Parameter()]
        [string]$MonitorPath,
        
        [Parameter()]
        [string]$ResponseFilePattern,
        
        [Parameter()]
        [int]$DebounceDelayMs,
        
        [Parameter()]
        [int]$RefreshCycleMs,
        
        [Parameter()]
        [int]$MaxResponseSizeMB,
        
        [Parameter()]
        [int]$TimeoutSeconds,
        
        [Parameter()]
        [bool]$IntegrationEnabled
    )
    
    Write-ResponseMonitorLog -Message "Updating Response Monitor configuration" -Level "INFO"
    
    if ($PSBoundParameters.ContainsKey('EnableDebugLogging')) {
        $script:ResponseMonitorConfig.EnableDebugLogging = $EnableDebugLogging
    }
    if ($PSBoundParameters.ContainsKey('MonitorPath')) {
        $script:ResponseMonitorConfig.MonitorPath = $MonitorPath
    }
    if ($PSBoundParameters.ContainsKey('ResponseFilePattern')) {
        $script:ResponseMonitorConfig.ResponseFilePattern = $ResponseFilePattern
    }
    if ($PSBoundParameters.ContainsKey('DebounceDelayMs')) {
        $script:ResponseMonitorConfig.DebounceDelayMs = $DebounceDelayMs
    }
    if ($PSBoundParameters.ContainsKey('RefreshCycleMs')) {
        $script:ResponseMonitorConfig.RefreshCycleMs = $RefreshCycleMs
    }
    if ($PSBoundParameters.ContainsKey('MaxResponseSizeMB')) {
        $script:ResponseMonitorConfig.MaxResponseSizeMB = $MaxResponseSizeMB
    }
    if ($PSBoundParameters.ContainsKey('TimeoutSeconds')) {
        $script:ResponseMonitorConfig.TimeoutSeconds = $TimeoutSeconds
    }
    if ($PSBoundParameters.ContainsKey('IntegrationEnabled')) {
        $script:ResponseMonitorConfig.IntegrationEnabled = $IntegrationEnabled
    }
    
    Write-ResponseMonitorLog -Message "Response Monitor configuration updated successfully" -Level "INFO"
}

#endregion

#region FileSystemWatcher Implementation

function Initialize-FileSystemWatcher {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$MonitorPath,
        
        [Parameter()]
        [string]$FileFilter = "*.*"
    )
    
    Write-ResponseMonitorLog -Message "Initializing FileSystemWatcher for path: $MonitorPath" -Level "INFO"
    
    if (-not (Test-Path $MonitorPath)) {
        Write-ResponseMonitorLog -Message "Monitor path does not exist: $MonitorPath" -Level "ERROR"
        throw "Monitor path not found: $MonitorPath"
    }
    
    try {
        # Dispose existing watcher if present
        if ($script:FileSystemWatcher -ne $null) {
            $script:FileSystemWatcher.Dispose()
        }
        
        # Create new FileSystemWatcher with research-validated settings
        $script:FileSystemWatcher = New-Object System.IO.FileSystemWatcher
        $script:FileSystemWatcher.Path = $MonitorPath
        $script:FileSystemWatcher.Filter = $FileFilter
        $script:FileSystemWatcher.IncludeSubdirectories = $true
        $script:FileSystemWatcher.NotifyFilter = [System.IO.NotifyFilters]::CreationTime -bor 
                                               [System.IO.NotifyFilters]::LastWrite -bor
                                               [System.IO.NotifyFilters]::Size
        
        # Register event handlers with proper resource management
        Register-ObjectEvent -InputObject $script:FileSystemWatcher -EventName "Created" -Action {
            $Event.MessageData.OnFileCreated($Event.SourceEventArgs)
        } -MessageData $script:ResponseMonitorConfig | Out-Null
        
        Register-ObjectEvent -InputObject $script:FileSystemWatcher -EventName "Changed" -Action {
            $Event.MessageData.OnFileChanged($Event.SourceEventArgs)
        } -MessageData $script:ResponseMonitorConfig | Out-Null
        
        $script:FileSystemWatcher.EnableRaisingEvents = $true
        $script:MonitoringActive = $true
        
        Write-ResponseMonitorLog -Message "FileSystemWatcher initialized successfully" -Level "INFO"
        return @{
            Success = $true
            WatcherPath = $MonitorPath
            Filter = $FileFilter
        }
    }
    catch {
        Write-ResponseMonitorLog -Message "Failed to initialize FileSystemWatcher: $_" -Level "ERROR"
        throw "FileSystemWatcher initialization failed: $_"
    }
}

function Stop-FileSystemWatcher {
    [CmdletBinding()]
    param()
    
    Write-ResponseMonitorLog -Message "Stopping FileSystemWatcher" -Level "INFO"
    
    try {
        if ($script:FileSystemWatcher -ne $null) {
            $script:FileSystemWatcher.EnableRaisingEvents = $false
            
            # Unregister events
            Get-EventSubscriber | Where-Object { $_.SourceObject -eq $script:FileSystemWatcher } | Unregister-Event
            
            # Dispose with proper resource management pattern
            $script:FileSystemWatcher.Dispose()
            $script:FileSystemWatcher = $null
        }
        
        $script:MonitoringActive = $false
        Write-ResponseMonitorLog -Message "FileSystemWatcher stopped successfully" -Level "INFO"
    }
    catch {
        Write-ResponseMonitorLog -Message "Error stopping FileSystemWatcher: $_" -Level "ERROR"
    }
}

function Invoke-DebouncedResponseHandler {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$FilePath,
        
        [Parameter(Mandatory = $true)]
        [string]$EventType
    )
    
    Write-ResponseMonitorLog -Message "Debounced handler triggered: $EventType - $FilePath" -Level "DEBUG"
    
    # Cancel existing timer
    if ($script:DebounceTimer -ne $null) {
        $script:DebounceTimer.Stop()
        $script:DebounceTimer.Dispose()
    }
    
    # Create new debounce timer with research-validated 500ms delay
    $script:DebounceTimer = New-Object System.Timers.Timer
    $script:DebounceTimer.Interval = $script:ResponseMonitorConfig.DebounceDelayMs
    $script:DebounceTimer.AutoReset = $false
    
    # Register timer event for actual processing
    Register-ObjectEvent -InputObject $script:DebounceTimer -EventName "Elapsed" -Action {
        param($sender, $e)
        
        $filePath = $Event.MessageData.FilePath
        $eventType = $Event.MessageData.EventType
        
        try {
            # Process the file change after debounce delay
            Invoke-ResponseProcessing -FilePath $filePath -EventType $eventType
        }
        catch {
            Write-ResponseMonitorLog -Message "Error in debounced response processing: $_" -Level "ERROR"
        }
        finally {
            # Clean up timer
            if ($sender -ne $null) {
                $sender.Dispose()
            }
        }
    } -MessageData @{
        FilePath = $FilePath
        EventType = $EventType
    } | Out-Null
    
    $script:DebounceTimer.Start()
    Write-ResponseMonitorLog -Message "Debounce timer started for $FilePath" -Level "DEBUG"
}

#endregion

#region Response Processing

function Invoke-ResponseProcessing {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$FilePath,
        
        [Parameter(Mandatory = $true)]
        [string]$EventType
    )
    
    Write-ResponseMonitorLog -Message "Processing Claude response: $EventType - $FilePath" -Level "INFO"
    
    if (-not (Test-Path $FilePath)) {
        Write-ResponseMonitorLog -Message "Response file no longer exists: $FilePath" -Level "WARN"
        return
    }
    
    try {
        # Validate file size to prevent processing extremely large files
        $fileInfo = Get-Item $FilePath
        $maxSizeBytes = $script:ResponseMonitorConfig.MaxResponseSizeMB * 1MB
        
        if ($fileInfo.Length -gt $maxSizeBytes) {
            Write-ResponseMonitorLog -Message "Response file too large: $($fileInfo.Length) bytes (max: $maxSizeBytes)" -Level "WARN"
            return
        }
        
        # Wait briefly to ensure file is fully written
        Start-Sleep -Milliseconds 100
        
        # Read response content with error handling
        $responseContent = Get-Content -Path $FilePath -Raw -Encoding UTF8 -ErrorAction Stop
        
        if ([string]::IsNullOrWhiteSpace($responseContent)) {
            Write-ResponseMonitorLog -Message "Response file is empty: $FilePath" -Level "DEBUG"
            return
        }
        
        # Create response object
        $response = @{
            FilePath = $FilePath
            Content = $responseContent
            Timestamp = Get-Date
            EventType = $EventType
            FileSize = $fileInfo.Length
            ProcessingTime = Get-Date
        }
        
        # Add to processing queue
        $script:ResponseQueue.Enqueue($response)
        $script:LastResponseTime = Get-Date
        
        Write-ResponseMonitorLog -Message "Response queued for processing: $($response.FileSize) bytes" -Level "INFO"
        
        # Trigger autonomous processing if integration enabled
        if ($script:ResponseMonitorConfig.IntegrationEnabled) {
            Invoke-AutonomousResponseHandling -Response $response
        }
        
        return $response
    }
    catch {
        Write-ResponseMonitorLog -Message "Error processing response from $FilePath - $_" -Level "ERROR"
        return $null
    }
}

function Invoke-AutonomousResponseHandling {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [hashtable]$Response
    )
    
    Write-ResponseMonitorLog -Message "Starting autonomous response handling" -Level "INFO"
    
    try {
        # Extract actionable items from Claude response
        $actionableItems = Get-ActionableItems -Content $Response.Content
        
        Write-ResponseMonitorLog -Message "Extracted $($actionableItems.Count) actionable items from response" -Level "DEBUG"
        
        foreach ($item in $actionableItems) {
            Write-ResponseMonitorLog -Message "Processing actionable item: $($item.Type) - $($item.Action)" -Level "DEBUG"
            
            # Route to appropriate handler based on item type
            switch ($item.Type) {
                "RECOMMENDED" {
                    Invoke-RecommendationHandler -Item $item -Response $Response
                }
                "TEST" {
                    Invoke-TestHandler -Item $item -Response $Response  
                }
                "CONTINUE" {
                    Invoke-ContinuationHandler -Item $item -Response $Response
                }
                "EXECUTE" {
                    Invoke-ExecutionHandler -Item $item -Response $Response
                }
                default {
                    Write-ResponseMonitorLog -Message "Unknown actionable item type: $($item.Type)" -Level "WARN"
                }
            }
        }
        
        # Update conversation state if ConversationStateManager available
        if (Test-RequiredModule -ModuleName "ConversationStateManager") {
            Update-ConversationState -Response $Response -ActionableItems $actionableItems
        }
        
        Write-ResponseMonitorLog -Message "Autonomous response handling completed" -Level "INFO"
    }
    catch {
        Write-ResponseMonitorLog -Message "Error in autonomous response handling: $_" -Level "ERROR"
    }
}

function Get-ActionableItems {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Content
    )
    
    Write-ResponseMonitorLog -Message "Extracting actionable items from response content" -Level "DEBUG"
    
    $actionableItems = @()
    
    try {
        # Research-validated regex patterns for Claude Code output
        $patterns = @{
            "RECOMMENDED" = 'RECOMMENDED:\s*([^-\n]+)(?:\s*-\s*(.+))?'
            "TEST" = 'TEST:\s*(.+?)(?:\n|$)'
            "CONTINUE" = 'CONTINUE:\s*(.+?)(?:\n|$)'
            "EXECUTE" = '```powershell\s*([\s\S]*?)```'
            "COMMAND" = '`([^`]+)`'
        }
        
        foreach ($patternName in $patterns.Keys) {
            $pattern = $patterns[$patternName]
            $matches = [regex]::Matches($Content, $pattern, [System.Text.RegularExpressions.RegexOptions]::IgnoreCase -bor [System.Text.RegularExpressions.RegexOptions]::Multiline)
            
            foreach ($match in $matches) {
                $actionableItems += @{
                    Type = $patternName
                    Action = $match.Groups[1].Value.Trim()
                    Details = if ($match.Groups.Count -gt 2) { $match.Groups[2].Value.Trim() } else { "" }
                    FullMatch = $match.Value
                    Position = $match.Index
                }
            }
        }
        
        Write-ResponseMonitorLog -Message "Found $($actionableItems.Count) actionable items" -Level "DEBUG"
        return $actionableItems
    }
    catch {
        Write-ResponseMonitorLog -Message "Error extracting actionable items: $_" -Level "ERROR"
        return @()
    }
}

#endregion

#region Action Handlers

function Invoke-RecommendationHandler {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [hashtable]$Item,
        
        [Parameter(Mandatory = $true)]
        [hashtable]$Response
    )
    
    Write-ResponseMonitorLog -Message "Processing recommendation: $($Item.Action)" -Level "INFO"
    
    # This will be extended to integrate with the decision engine in Hours 3-4
    # For now, log the recommendation for autonomous processing
    $recommendation = @{
        Action = $Item.Action
        Details = $Item.Details
        Timestamp = Get-Date
        Source = "ClaudeResponse"
        FilePath = $Response.FilePath
    }
    
    # Store recommendation for decision engine processing
    Add-PendingRecommendation -Recommendation $recommendation
    
    Write-ResponseMonitorLog -Message "Recommendation stored for decision processing" -Level "DEBUG"
}

function Invoke-TestHandler {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [hashtable]$Item,
        
        [Parameter(Mandatory = $true)]
        [hashtable]$Response
    )
    
    Write-ResponseMonitorLog -Message "Processing test request: $($Item.Action)" -Level "INFO"
    
    # Create test request for autonomous execution
    $testRequest = @{
        TestType = $Item.Action
        Details = $Item.Details
        Timestamp = Get-Date
        Source = "ClaudeResponse"
        FilePath = $Response.FilePath
    }
    
    Add-PendingTest -TestRequest $testRequest
    Write-ResponseMonitorLog -Message "Test request queued for execution" -Level "DEBUG"
}

function Invoke-ContinuationHandler {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [hashtable]$Item,
        
        [Parameter(Mandatory = $true)]
        [hashtable]$Response
    )
    
    Write-ResponseMonitorLog -Message "Processing continuation request: $($Item.Action)" -Level "INFO"
    
    # Queue continuation for autonomous conversation management
    $continuation = @{
        ContinuationType = $Item.Action
        Details = $Item.Details  
        Timestamp = Get-Date
        Source = "ClaudeResponse"
        FilePath = $Response.FilePath
    }
    
    Add-PendingContinuation -Continuation $continuation
    Write-ResponseMonitorLog -Message "Continuation request queued" -Level "DEBUG"
}

function Invoke-ExecutionHandler {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [hashtable]$Item,
        
        [Parameter(Mandatory = $true)]
        [hashtable]$Response
    )
    
    Write-ResponseMonitorLog -Message "Processing execution request" -Level "INFO"
    
    # Create execution request for safe command execution
    $execution = @{
        Command = $Item.Action
        Details = $Item.Details
        Timestamp = Get-Date
        Source = "ClaudeResponse"
        FilePath = $Response.FilePath
    }
    
    Add-PendingExecution -Execution $execution
    Write-ResponseMonitorLog -Message "Execution request queued for safety validation" -Level "DEBUG"
}

#endregion

#region Queue Management

function Add-PendingRecommendation {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [hashtable]$Recommendation
    )
    
    # Placeholder for decision engine integration (Hours 3-4)
    Write-ResponseMonitorLog -Message "Recommendation added to processing queue: $($Recommendation.Action)" -Level "DEBUG"
}

function Add-PendingTest {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [hashtable]$TestRequest
    )
    
    # Placeholder for test automation integration
    Write-ResponseMonitorLog -Message "Test request added to execution queue: $($TestRequest.TestType)" -Level "DEBUG"
}

function Add-PendingContinuation {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [hashtable]$Continuation
    )
    
    # Placeholder for conversation management integration
    Write-ResponseMonitorLog -Message "Continuation added to conversation queue: $($Continuation.ContinuationType)" -Level "DEBUG"
}

function Add-PendingExecution {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [hashtable]$Execution
    )
    
    # Placeholder for safe command execution integration
    Write-ResponseMonitorLog -Message "Execution request added to safety validation queue: Command length $($Execution.Command.Length)" -Level "DEBUG"
}

function Get-ResponseQueue {
    [CmdletBinding()]
    param()
    
    $queueArray = @()
    foreach ($item in $script:ResponseQueue) {
        $queueArray += $item
    }
    
    return $queueArray
}

function Clear-ResponseQueue {
    [CmdletBinding()]
    param()
    
    $clearedCount = $script:ResponseQueue.Count
    $script:ResponseQueue.Clear()
    Write-ResponseMonitorLog -Message "Cleared $clearedCount items from response queue" -Level "INFO"
}

#endregion

#region Core Management Functions

function Start-ClaudeResponseMonitoring {
    [CmdletBinding()]
    param(
        [Parameter()]
        [string]$MonitorPath = $script:ResponseMonitorConfig.MonitorPath,
        
        [Parameter()]
        [string]$FilePattern = $script:ResponseMonitorConfig.ResponseFilePattern
    )
    
    Write-ResponseMonitorLog -Message "Starting Claude response monitoring" -Level "INFO"
    Write-ResponseMonitorLog -Message "Monitor Path: $MonitorPath" -Level "DEBUG"
    Write-ResponseMonitorLog -Message "File Pattern: $FilePattern" -Level "DEBUG"
    
    try {
        # Initialize FileSystemWatcher with research-validated configuration
        $result = Initialize-FileSystemWatcher -MonitorPath $MonitorPath -FileFilter $FilePattern
        
        if ($result.Success) {
            Write-ResponseMonitorLog -Message "Claude response monitoring started successfully" -Level "INFO"
            return @{
                Success = $true
                MonitoringActive = $script:MonitoringActive
                MonitorPath = $MonitorPath
                FilePattern = $FilePattern
                StartTime = Get-Date
            }
        } else {
            throw "FileSystemWatcher initialization failed"
        }
    }
    catch {
        Write-ResponseMonitorLog -Message "Failed to start Claude response monitoring: $_" -Level "ERROR"
        return @{
            Success = $false
            Error = $_.Exception.Message
            MonitoringActive = $false
        }
    }
}

function Stop-ClaudeResponseMonitoring {
    [CmdletBinding()]
    param()
    
    Write-ResponseMonitorLog -Message "Stopping Claude response monitoring" -Level "INFO"
    
    try {
        Stop-FileSystemWatcher
        
        # Clean up debounce timer
        if ($script:DebounceTimer -ne $null) {
            $script:DebounceTimer.Stop()
            $script:DebounceTimer.Dispose()
            $script:DebounceTimer = $null
        }
        
        Write-ResponseMonitorLog -Message "Claude response monitoring stopped successfully" -Level "INFO"
        return @{
            Success = $true
            MonitoringActive = $script:MonitoringActive
            StopTime = Get-Date
        }
    }
    catch {
        Write-ResponseMonitorLog -Message "Error stopping Claude response monitoring: $_" -Level "ERROR"
        return @{
            Success = $false
            Error = $_.Exception.Message
            MonitoringActive = $script:MonitoringActive
        }
    }
}

function Get-MonitoringStatus {
    [CmdletBinding()]
    param()
    
    return @{
        MonitoringActive = $script:MonitoringActive
        LastResponseTime = $script:LastResponseTime
        QueueLength = $script:ResponseQueue.Count
        Configuration = $script:ResponseMonitorConfig
        WatcherExists = ($script:FileSystemWatcher -ne $null)
    }
}

function Test-ResponseMonitorIntegration {
    [CmdletBinding()]
    param()
    
    Write-ResponseMonitorLog -Message "Testing Response Monitor integration" -Level "INFO"
    
    $testResults = @{
        FileSystemWatcher = $false
        ConversationManager = $false
        ConfigurationValid = $false
        MonitorPathExists = $false
        OverallStatus = "FAIL"
    }
    
    try {
        # Test FileSystemWatcher capability
        if ([System.IO.FileSystemWatcher] -ne $null) {
            $testResults.FileSystemWatcher = $true
            Write-ResponseMonitorLog -Message "FileSystemWatcher availability: PASS" -Level "DEBUG"
        }
        
        # Test ConversationStateManager integration
        if (Test-RequiredModule -ModuleName "ConversationStateManager") {
            $testResults.ConversationManager = $true
            Write-ResponseMonitorLog -Message "ConversationStateManager integration: PASS" -Level "DEBUG"
        }
        
        # Test configuration validity
        if ($script:ResponseMonitorConfig.MonitorPath -and $script:ResponseMonitorConfig.ResponseFilePattern) {
            $testResults.ConfigurationValid = $true
            Write-ResponseMonitorLog -Message "Configuration validity: PASS" -Level "DEBUG"
        }
        
        # Test monitor path accessibility
        if (Test-Path $script:ResponseMonitorConfig.MonitorPath) {
            $testResults.MonitorPathExists = $true
            Write-ResponseMonitorLog -Message "Monitor path accessibility: PASS" -Level "DEBUG"
        }
        
        # Overall status
        $passCount = ($testResults.GetEnumerator() | Where-Object { $_.Value -eq $true }).Count
        if ($passCount -ge 3) {
            $testResults.OverallStatus = "PASS"
            Write-ResponseMonitorLog -Message "Response Monitor integration test: PASS ($passCount/4 tests passed)" -Level "INFO"
        } else {
            Write-ResponseMonitorLog -Message "Response Monitor integration test: FAIL ($passCount/4 tests passed)" -Level "WARN"
        }
        
        return $testResults
    }
    catch {
        Write-ResponseMonitorLog -Message "Error during integration test: $_" -Level "ERROR"
        $testResults.OverallStatus = "ERROR"
        return $testResults
    }
}

#endregion

# Module initialization with proper resource management
try {
    Write-ResponseMonitorLog -Message "Unity-Claude-ResponseMonitor module loading" -Level "INFO"
    
    # Validate configuration on load
    if (-not (Test-Path $script:ResponseMonitorConfig.MonitorPath)) {
        Write-ResponseMonitorLog -Message "Warning: Default monitor path does not exist: $($script:ResponseMonitorConfig.MonitorPath)" -Level "WARN"
    }
    
    Write-ResponseMonitorLog -Message "Unity-Claude-ResponseMonitor module loaded successfully" -Level "INFO"
} catch {
    Write-ResponseMonitorLog -Message "Error during module initialization: $_" -Level "ERROR"
}

# Export module members (functions are exported via manifest)
# SIG # Begin signature block
# MIIFqQYJKoZIhvcNAQcCoIIFmjCCBZYCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUV8vYAhp0LWMihHOjMwZsQCn3
# 3ZegggMwMIIDLDCCAhSgAwIBAgIQdR0W2SKoK5VE8JId4ZxrRTANBgkqhkiG9w0B
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
# CQQxFgQUVLrAdS5dWU7PZDOq2yHzjTmWvDIwDQYJKoZIhvcNAQEBBQAEggEAlTX6
# oSGspu50ZSzafZ7rnv6wsMIDnhVa/o9Yyte7pn+ovRJwy4J/CoVxq988496xA3Pj
# 7+EXPIioRhDzYbv26W2n1M+mpm8x2eMZcaoegPAGAsRJ+UXyYs1q+F3Z1vfxadlC
# e/1bKi2FVl0yJjKm8KKDK1iM4voABaSnkI783JLEAPjHKiTDn44/+ZZU8Bb5mBBe
# Q/H3TNZJ2JVVm2njhw6LGcZEbpgNn/FM1dXUmXCz6Vfw+nngwm/5T+qheftcJu1R
# LrMSxadf4amBXRRApl+qh81CSEE1RnaGEMY4Jpc9x7qiwLIHHllAc0PLACExc50b
# m08cWyoNmv9O1kYF0A==
# SIG # End signature block
