function Initialize-CommunicationState {
    <#
    .SYNOPSIS
    Initializes the script-level CommunicationState object with all required properties.
    
    .DESCRIPTION
    Creates and initializes the $script:CommunicationState object that is used throughout
    the SystemStatus module for communication features including FileWatcher, MessageProcessor,
    NamedPipe server, and message queues.
    #>
    [CmdletBinding()]
    param()
    
    Write-SystemStatusLog "Initializing communication state..." -Level 'DEBUG'
    
    try {
        # Initialize the communication state object with all required properties
        $script:CommunicationState = [PSCustomObject]@{
            # File monitoring
            FileWatcher = $null
            LastMessageTime = $null
            
            # Message queues and processing
            IncomingMessageQueue = [System.Collections.Concurrent.ConcurrentQueue[PSObject]]::new()
            OutgoingMessageQueue = [System.Collections.Concurrent.ConcurrentQueue[PSObject]]::new()
            MessageProcessor = $null
            MessageHandlers = @{}
            PendingResponses = [System.Collections.Concurrent.ConcurrentDictionary[string, PSObject]]::new()
            
            # Named pipe communication
            NamedPipeServer = $null
            NamedPipeEnabled = $false
            PipeConnectionJob = $null
            
            # Performance tracking
            MessageStats = [PSCustomObject]@{
                Sent = 0
                Received = 0
                Errors = 0
                AverageLatencyMs = 0.0
            }
        }
        
        Write-SystemStatusLog "Communication state initialized successfully" -Level 'OK'
        return $true
        
    } catch {
        Write-SystemStatusLog "Error initializing communication state: $($_.Exception.Message)" -Level 'ERROR'
        return $false
    }
}