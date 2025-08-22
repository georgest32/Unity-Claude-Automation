# Unity-Claude-IPC-Bidirectional-Fixed.psm1
# Fixed version with working named pipes
# Bidirectional communication module for Unity-Claude automation

# Simple logging function (standalone to avoid dependencies)
function Write-Log {
    param(
        [string]$Message,
        [string]$Level = 'INFO'
    )
    $timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
    Write-Verbose "[$timestamp] [$Level] $Message"
}

#region Module Variables

$script:PipeServers = @{}
$script:HttpListeners = @{}
$script:MessageQueue = [System.Collections.Concurrent.ConcurrentQueue[PSObject]]::new()
$script:ResponseQueue = [System.Collections.Concurrent.ConcurrentQueue[PSObject]]::new()
$script:ActiveConnections = @{}
$script:ServerRunning = $false
$script:PipeJobs = @{}

#endregion

#region Named Pipes Implementation

function Start-NamedPipeServer {
    <#
    .SYNOPSIS
    Starts a named pipe server for IPC (simplified synchronous version)
    
    .DESCRIPTION
    Creates a named pipe server that can handle bidirectional communication
    with clients. This version uses a simplified synchronous approach.
    
    .PARAMETER PipeName
    Name of the pipe to create
    
    .PARAMETER MaxConnections
    Maximum number of concurrent connections (default 10)
    
    .PARAMETER Async
    If specified, runs the server in background (experimental)
    
    .EXAMPLE
    Start-NamedPipeServer -PipeName "Unity-Claude-Bridge"
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$PipeName,
        
        [int]$MaxConnections = 10,
        
        [switch]$Async
    )
    
    try {
        Write-Verbose "Creating named pipe server: $PipeName"
        
        if ($Async) {
            # Start background job for async operation
            $job = Start-Job -ScriptBlock {
                param($PipeName, $MaxConnections)
                
                while ($true) {
                    try {
                        # Create pipe server
                        $pipeServer = New-Object System.IO.Pipes.NamedPipeServerStream(
                            $PipeName,
                            [System.IO.Pipes.PipeDirection]::InOut,
                            $MaxConnections,
                            [System.IO.Pipes.PipeTransmissionMode]::Message,
                            [System.IO.Pipes.PipeOptions]::None
                        )
                        
                        # Wait for connection
                        $pipeServer.WaitForConnection()
                        
                        # Handle connection
                        $reader = New-Object System.IO.StreamReader($pipeServer)
                        $writer = New-Object System.IO.StreamWriter($pipeServer)
                        $writer.AutoFlush = $true
                        
                        # Send welcome message
                        $writer.WriteLine("CONNECTED:Unity-Claude-IPC:v2.0")
                        
                        # Process messages
                        while ($pipeServer.IsConnected) {
                            if ($reader.Peek() -ge 0) {
                                $message = $reader.ReadLine()
                                
                                if ($message) {
                                    # Process message
                                    $response = switch -Regex ($message) {
                                        '^PING:' { "PONG:$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" }
                                        '^GET_STATUS:' { "STATUS:OK" }
                                        '^CLAUDE_QUESTION:(.*)$' { "QUEUED:Question received" }
                                        '^ERROR_REPORT:(.*)$' { "QUEUED:Error report received" }
                                        default { "ERROR:Unknown command" }
                                    }
                                    
                                    $writer.WriteLine($response)
                                }
                            }
                            Start-Sleep -Milliseconds 100
                        }
                        
                        # Cleanup
                        $reader.Dispose()
                        $writer.Dispose()
                        $pipeServer.Dispose()
                        
                    } catch {
                        Write-Error "Pipe server error: $_"
                        Start-Sleep -Seconds 1
                    }
                }
            } -ArgumentList $PipeName, $MaxConnections
            
            # Store job reference
            $script:PipeJobs[$PipeName] = $job
            
            # Give it a moment to start
            Start-Sleep -Milliseconds 500
            
            Write-Verbose "Async pipe server started (Job ID: $($job.Id))"
            
            return @{
                Success = $true
                PipeName = $PipeName
                JobId = $job.Id
            }
            
        } else {
            # Synchronous mode - create but don't wait
            $pipeServer = New-Object System.IO.Pipes.NamedPipeServerStream(
                $PipeName,
                [System.IO.Pipes.PipeDirection]::InOut,
                $MaxConnections,
                [System.IO.Pipes.PipeTransmissionMode]::Message,
                [System.IO.Pipes.PipeOptions]::None
            )
            
            # Store server reference
            $script:PipeServers[$PipeName] = @{
                Server = $pipeServer
                Active = $true
                Connections = 0
                StartTime = Get-Date
            }
            
            Write-Verbose "Synchronous pipe server created: $PipeName"
            
            return @{
                Success = $true
                PipeName = $PipeName
                Server = $pipeServer
            }
        }
        
    } catch {
        Write-Error "Failed to start named pipe server: $_"
        return @{
            Success = $false
            Error = $_.Exception.Message
        }
    }
}

function Send-PipeMessage {
    <#
    .SYNOPSIS
    Sends a message to a named pipe server
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$PipeName,
        
        [Parameter(Mandatory)]
        [string]$Message
    )
    
    try {
        $pipeClient = New-Object System.IO.Pipes.NamedPipeClientStream(
            ".",  # local machine
            $PipeName,
            [System.IO.Pipes.PipeDirection]::InOut
        )
        
        # Connect with timeout
        $pipeClient.Connect(5000)
        
        $writer = New-Object System.IO.StreamWriter($pipeClient)
        $reader = New-Object System.IO.StreamReader($pipeClient)
        $writer.AutoFlush = $true
        
        # Read welcome message if any
        if ($reader.Peek() -ge 0) {
            $welcome = $reader.ReadLine()
            Write-Verbose "Server welcome: $welcome"
        }
        
        # Send message
        $writer.WriteLine($Message)
        
        # Read response
        $response = $reader.ReadLine()
        
        return @{
            Success = $true
            Response = $response
        }
        
    } catch {
        return @{
            Success = $false
            Error = $_.Exception.Message
        }
    } finally {
        if ($writer) { $writer.Dispose() }
        if ($reader) { $reader.Dispose() }
        if ($pipeClient) { $pipeClient.Dispose() }
    }
}

#endregion

#region TCP/HTTP REST API Server

function Start-HttpApiServer {
    <#
    .SYNOPSIS
    Starts an HTTP REST API server
    
    .DESCRIPTION
    Creates an HttpListener-based REST API server for remote communication
    
    .PARAMETER Port
    Port to listen on (default 5555)
    
    .PARAMETER Prefix
    URL prefix (default http://+:port/)
    
    .EXAMPLE
    Start-HttpApiServer -Port 5555
    #>
    [CmdletBinding()]
    param(
        [int]$Port = 5555,
        
        [string]$Prefix = "",
        
        [switch]$LocalOnly
    )
    
    try {
        # Build prefix
        if (-not $Prefix) {
            $host = if ($LocalOnly) { "localhost" } else { "+" }
            $Prefix = "http://${host}:${Port}/"
        }
        
        Write-Verbose "Starting HTTP API server on: $Prefix"
        
        # Create listener
        $listener = New-Object System.Net.HttpListener
        $listener.Prefixes.Add($Prefix)
        
        # Start listener
        $listener.Start()
        
        # Store listener reference
        $script:HttpListeners[$Port] = @{
            Listener = $listener
            Active = $true
            Prefix = $Prefix
            StartTime = Get-Date
            RequestCount = 0
        }
        
        # Start async request handler
        Start-HttpRequestHandler -Port $Port -Listener $listener
        
        Write-Host "HTTP API Server started on $Prefix" -ForegroundColor Green
        
        return @{
            Success = $true
            Port = $Port
            Prefix = $Prefix
        }
        
    } catch {
        Write-Error "Failed to start HTTP server: $_"
        return @{
            Success = $false
            Error = $_.Exception.Message
        }
    }
}

function Start-HttpRequestHandler {
    <#
    .SYNOPSIS
    Handles HTTP requests asynchronously
    #>
    [CmdletBinding()]
    param(
        [int]$Port,
        [System.Net.HttpListener]$Listener
    )
    
    $scriptBlock = {
        param($Port, $Listener)
        
        while ($Listener.IsListening) {
            try {
                # Get context
                $context = $Listener.GetContext()
                
                $request = $context.Request
                $response = $context.Response
                
                # Route based on path
                $path = $request.Url.AbsolutePath
                
                $result = switch -Regex ($path) {
                    '^/api/health$' {
                        @{ status = "healthy"; timestamp = Get-Date -Format 'o' }
                    }
                    
                    '^/api/status$' {
                        @{ 
                            status = "running"
                            port = $Port
                            uptime = 0
                            requests = 0
                        }
                    }
                    
                    '^/api/errors$' {
                        if ($request.HttpMethod -eq 'POST') {
                            @{ success = $true; message = "Error queued" }
                        } else {
                            @{ queue_length = 0 }
                        }
                    }
                    
                    default {
                        $response.StatusCode = 404
                        @{ error = "Not found"; path = $path }
                    }
                }
                
                # Send response
                $json = $result | ConvertTo-Json -Compress
                $buffer = [System.Text.Encoding]::UTF8.GetBytes($json)
                
                $response.ContentType = "application/json"
                $response.ContentLength64 = $buffer.Length
                $response.OutputStream.Write($buffer, 0, $buffer.Length)
                $response.Close()
                
            } catch {
                # Ignore listener closed errors
                if ($_.Exception.Message -notlike "*Listener was closed*") {
                    Write-Error "HTTP handler error: $_"
                }
            }
        }
    }
    
    # Start handler in background
    Start-Job -ScriptBlock $scriptBlock -ArgumentList $Port, $Listener | Out-Null
}

#endregion

#region Queue Management

function Initialize-MessageQueues {
    <#
    .SYNOPSIS
    Initializes thread-safe message queues
    #>
    [CmdletBinding()]
    param()
    
    # Already initialized in module load
    Write-Verbose "Message queues initialized"
    
    return @{
        MessageQueue = $script:MessageQueue
        ResponseQueue = $script:ResponseQueue
    }
}

function Add-MessageToQueue {
    <#
    .SYNOPSIS
    Adds a message to the processing queue
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [PSObject]$Message,
        
        [ValidateSet('Message','Response')]
        [string]$QueueType = 'Message'
    )
    
    if ($QueueType -eq 'Message') { 
        $script:MessageQueue.Enqueue($Message)
        $queueCount = $script:MessageQueue.Count
    } else { 
        $script:ResponseQueue.Enqueue($Message)
        $queueCount = $script:ResponseQueue.Count
    }
    
    Write-Verbose "Added message to $QueueType queue (Count: $queueCount)"
}

function Get-NextMessage {
    <#
    .SYNOPSIS
    Gets the next message from the queue
    #>
    [CmdletBinding()]
    param(
        [ValidateSet('Message','Response')]
        [string]$QueueType = 'Message',
        
        [switch]$Wait,
        
        [int]$TimeoutMs = 1000
    )
    
    $message = $null
    
    if ($QueueType -eq 'Message') {
        if ($Wait) {
            $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
            
            while (-not $script:MessageQueue.TryDequeue([ref]$message) -and 
                   $stopwatch.ElapsedMilliseconds -lt $TimeoutMs) {
                Start-Sleep -Milliseconds 100
            }
        } else {
            [void]$script:MessageQueue.TryDequeue([ref]$message)
        }
    } else {
        if ($Wait) {
            $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
            
            while (-not $script:ResponseQueue.TryDequeue([ref]$message) -and 
                   $stopwatch.ElapsedMilliseconds -lt $TimeoutMs) {
                Start-Sleep -Milliseconds 100
            }
        } else {
            [void]$script:ResponseQueue.TryDequeue([ref]$message)
        }
    }
    
    return $message
}

function Get-QueueStatus {
    <#
    .SYNOPSIS
    Gets the status of all queues
    #>
    [CmdletBinding()]
    param()
    
    return @{
        MessageQueue = @{
            Count = $script:MessageQueue.Count
            Type = 'ConcurrentQueue[PSObject]'
        }
        ResponseQueue = @{
            Count = $script:ResponseQueue.Count
            Type = 'ConcurrentQueue[PSObject]'
        }
        PipeServers = $script:PipeServers.Keys | ForEach-Object {
            @{
                Name = $_
                Active = $script:PipeServers[$_].Active
                Connections = $script:PipeServers[$_].Connections
            }
        }
        HttpListeners = $script:HttpListeners.Keys | ForEach-Object {
            @{
                Port = $_
                Active = $script:HttpListeners[$_].Active
                Requests = $script:HttpListeners[$_].RequestCount
            }
        }
        PipeJobs = $script:PipeJobs.Keys | ForEach-Object {
            $job = $script:PipeJobs[$_]
            @{
                Name = $_
                JobId = $job.Id
                State = $job.State
            }
        }
    }
}

function Clear-MessageQueue {
    <#
    .SYNOPSIS
    Clears all messages from a queue
    #>
    [CmdletBinding()]
    param(
        [ValidateSet('Message','Response','All')]
        [string]$QueueType = 'All'
    )
    
    if ($QueueType -eq 'Message' -or $QueueType -eq 'All') {
        while ($script:MessageQueue.TryDequeue([ref]$null)) { }
        Write-Verbose "Cleared message queue"
    }
    
    if ($QueueType -eq 'Response' -or $QueueType -eq 'All') {
        while ($script:ResponseQueue.TryDequeue([ref]$null)) { }
        Write-Verbose "Cleared response queue"
    }
}

#endregion

#region Server Management

function Start-BidirectionalServers {
    <#
    .SYNOPSIS
    Starts all bidirectional communication servers
    #>
    [CmdletBinding()]
    param(
        [string]$PipeName = "Unity-Claude-Bridge",
        
        [int]$HttpPort = 5555,
        
        [switch]$LocalOnly
    )
    
    $results = @{}
    
    # Start named pipe server
    Write-Host "Starting named pipe server..." -ForegroundColor Cyan
    $pipeResult = Start-NamedPipeServer -PipeName $PipeName -Async
    $results.NamedPipe = $pipeResult
    
    # Start HTTP API server
    Write-Host "Starting HTTP API server..." -ForegroundColor Cyan
    $httpResult = Start-HttpApiServer -Port $HttpPort -LocalOnly:$LocalOnly
    $results.HttpApi = $httpResult
    
    # Initialize queues
    $queues = Initialize-MessageQueues
    $results.Queues = $queues
    
    $script:ServerRunning = $true
    
    Write-Host "`nBidirectional servers started successfully!" -ForegroundColor Green
    Write-Host "  Named Pipe: \\.\pipe\$PipeName" -ForegroundColor White
    Write-Host "  HTTP API: http://localhost:$HttpPort/api/" -ForegroundColor White
    
    return $results
}

function Stop-BidirectionalServers {
    <#
    .SYNOPSIS
    Stops all bidirectional communication servers
    #>
    [CmdletBinding()]
    param()
    
    Write-Host "Stopping bidirectional servers..." -ForegroundColor Yellow
    
    # Stop pipe servers
    foreach ($pipeName in $script:PipeServers.Keys) {
        $script:PipeServers[$pipeName].Active = $false
        if ($script:PipeServers[$pipeName].Server) {
            $script:PipeServers[$pipeName].Server.Dispose()
        }
    }
    $script:PipeServers.Clear()
    
    # Stop pipe jobs
    foreach ($pipeName in $script:PipeJobs.Keys) {
        $job = $script:PipeJobs[$pipeName]
        Stop-Job -Id $job.Id -ErrorAction SilentlyContinue
        Remove-Job -Id $job.Id -ErrorAction SilentlyContinue
    }
    $script:PipeJobs.Clear()
    
    # Stop HTTP listeners
    foreach ($port in $script:HttpListeners.Keys) {
        $script:HttpListeners[$port].Active = $false
        if ($script:HttpListeners[$port].Listener) {
            $script:HttpListeners[$port].Listener.Stop()
            $script:HttpListeners[$port].Listener.Close()
        }
    }
    $script:HttpListeners.Clear()
    
    # Clear queues
    Clear-MessageQueue -QueueType All
    
    $script:ServerRunning = $false
    
    Write-Host "All servers stopped" -ForegroundColor Green
}

#endregion

#region Module Exports

Export-ModuleMember -Function @(
    # Named Pipes
    'Start-NamedPipeServer',
    'Send-PipeMessage',
    
    # HTTP API
    'Start-HttpApiServer',
    
    # Queue Management
    'Initialize-MessageQueues',
    'Add-MessageToQueue',
    'Get-NextMessage',
    'Get-QueueStatus',
    'Clear-MessageQueue',
    
    # Server Management
    'Start-BidirectionalServers',
    'Stop-BidirectionalServers'
)

#endregion
# SIG # Begin signature block
# MIIFqQYJKoZIhvcNAQcCoIIFmjCCBZYCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUhH+G9Xw69vxxnQ24tKT6sIXF
# J2WgggMwMIIDLDCCAhSgAwIBAgIQdR0W2SKoK5VE8JId4ZxrRTANBgkqhkiG9w0B
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
# CQQxFgQUC3QtCYKiyIwYXSD7qj0zqLkCVxYwDQYJKoZIhvcNAQEBBQAEggEAfAnn
# G3/wkxd1sQZ7Lst6HEWDUcrOd7YSHvFoHx1p+OeP3o+L1t1yCDEs/GiG4gmVFt5/
# wK71703ouUYwKQuv3IMrCZzqX6a2MqK2PRKdY3OA+vf4xQLjKt570YUHhCaDp3vy
# Sdi8JW53zNf8WPlWlYzBXioEOdfqobgcOxBkTkUY/1GarRXqTlGf9ADC9IZYO9Nd
# NodtOWMulWSMiIIbNOQvGIv/jACubxI3j3BB7YQRq4ijgBpGE3PiPnwzScJLQBeu
# bEFlCyOBjlKTKN5YGAGeBGqAnbU8JCdBTOtkeWCjD4R5FiJng5yeDIylnWirdxfw
# YEGbDsOSoML1OU1DnQ==
# SIG # End signature block
