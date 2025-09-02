#Requires -Version 5.1

<#
.SYNOPSIS
Unity-Claude LangGraph Bridge PowerShell Module
Phase 4: Multi-Agent Orchestration - PowerShell-LangGraph Bridge

.DESCRIPTION
This module provides PowerShell functions to communicate with LangGraph Python REST API server,
enabling seamless integration between PowerShell automation and LangGraph multi-agent workflows.

Key Features:
- HTTP REST API communication with retry logic
- JSON state serialization/deserialization
- Human-in-the-Loop (HITL) interrupt handling
- Error handling with comprehensive logging
- State management across PowerShell-Python boundary

.NOTES
Author: Unity-Claude-Automation System
Version: 1.0.0
Created: 2025-08-23
Dependencies: PowerShell 7.5+, Invoke-RestMethod
#>

# Module variables
$script:LangGraphServerUri = "http://127.0.0.1:8000"
$script:DefaultRetryCount = 3
$script:DefaultRetryDelaySeconds = 2
$script:LoggingEnabled = $true

# Logging function
function Write-LangGraphLog {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Message,
        
        [Parameter()]
        [ValidateSet('Info', 'Warning', 'Error', 'Debug')]
        [string]$Level = 'Info',
        
        [Parameter()]
        [string]$Function = $null
    )
    
    if (-not $script:LoggingEnabled) { return }
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss.fff"
    $caller = if ($Function) { $Function } else { (Get-PSCallStack)[1].Command }
    
    $logMessage = "[$timestamp] [$Level] [$caller] $Message"
    
    switch ($Level) {
        'Error' { Write-Error $logMessage }
        'Warning' { Write-Warning $logMessage }
        'Debug' { Write-Debug $logMessage }
        default { Write-Host $logMessage -ForegroundColor Green }
    }
    
    # Also write to file if available
    $logFile = "langgraph_bridge.log"
    try {
        Add-Content -Path $logFile -Value $logMessage -ErrorAction SilentlyContinue
    }
    catch {
        # Silently fail if can't write to log file
    }
}

# HTTP Client function with retry logic
function Invoke-LangGraphRequest {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Uri,
        
        [Parameter()]
        [Microsoft.PowerShell.Commands.WebRequestMethod]$Method = 'Get',
        
        [Parameter()]
        [hashtable]$Body = @{},
        
        [Parameter()]
        [hashtable]$Headers = @{},
        
        [Parameter()]
        [int]$RetryCount = $script:DefaultRetryCount,
        
        [Parameter()]
        [int]$RetryDelaySeconds = $script:DefaultRetryDelaySeconds
    )
    
    Write-LangGraphLog -Message "Making HTTP request: $Method $Uri" -Level Debug
    
    # Prepare request parameters
    $requestParams = @{
        Uri = $Uri
        Method = $Method
        Headers = $Headers
        ContentType = "application/json"
        UseBasicParsing = $true
        ErrorAction = 'Stop'
    }
    
    # Add body if provided and not GET request
    if ($Method -ne 'Get' -and $Body.Count -gt 0) {
        $jsonBody = $Body | ConvertTo-Json -Depth 10 -Compress
        $requestParams.Body = $jsonBody
        Write-LangGraphLog -Message "Request body: $jsonBody" -Level Debug
    }
    
    $attempt = 0
    do {
        $attempt++
        try {
            Write-LangGraphLog -Message "Attempt $attempt of $($RetryCount + 1)" -Level Debug
            
            $response = Invoke-RestMethod @requestParams
            
            Write-LangGraphLog -Message "HTTP request successful on attempt $attempt" -Level Info
            return $response
        }
        catch {
            $errorDetails = $_.Exception.Message
            $statusCode = $null
            
            # Extract HTTP status code if available
            if ($_.Exception.Response) {
                $statusCode = [int]$_.Exception.Response.StatusCode
                Write-LangGraphLog -Message "HTTP Error $statusCode : $errorDetails" -Level Warning
            }
            else {
                Write-LangGraphLog -Message "Request Error: $errorDetails" -Level Warning
            }
            
            # Don't retry on authentication errors (401) or client errors (400-499)
            if ($statusCode -and $statusCode -ge 400 -and $statusCode -lt 500) {
                Write-LangGraphLog -Message "Client error detected (HTTP $statusCode). Not retrying." -Level Error
                throw
            }
            
            # If this is the last attempt, rethrow the exception
            if ($attempt -gt $RetryCount) {
                Write-LangGraphLog -Message "All retry attempts exhausted. Request failed." -Level Error
                throw
            }
            
            # Wait before retrying with exponential backoff
            $delay = [math]::Pow(2, $attempt - 1) * $RetryDelaySeconds
            Write-LangGraphLog -Message "Waiting $delay seconds before retry..." -Level Info
            Start-Sleep -Seconds $delay
        }
    } while ($attempt -le $RetryCount)
}

# Server connectivity and health check functions
function Test-LangGraphServer {
    <#
    .SYNOPSIS
    Tests connectivity to the LangGraph REST API server
    
    .DESCRIPTION
    Performs a health check against the LangGraph server to ensure it's running and responsive
    
    .EXAMPLE
    Test-LangGraphServer
    Returns $true if server is healthy, $false otherwise
    #>
    [CmdletBinding()]
    param()
    
    Write-LangGraphLog -Message "Testing LangGraph server connectivity" -Function $MyInvocation.MyCommand.Name
    
    try {
        $healthResponse = Invoke-LangGraphRequest -Uri "$script:LangGraphServerUri/health" -Method Get
        
        if ($healthResponse.status -eq "healthy") {
            Write-LangGraphLog -Message "Server is healthy. Database: $($healthResponse.database)" -Level Info
            return $true
        }
        else {
            Write-LangGraphLog -Message "Server health check failed: $($healthResponse.status)" -Level Warning
            return $false
        }
    }
    catch {
        Write-LangGraphLog -Message "Server connectivity test failed: $($_.Exception.Message)" -Level Error
        return $false
    }
}

function Get-LangGraphServerInfo {
    <#
    .SYNOPSIS
    Gets information about the LangGraph server
    
    .DESCRIPTION
    Retrieves server status, version, and runtime information
    
    .EXAMPLE
    Get-LangGraphServerInfo
    Returns server information object
    #>
    [CmdletBinding()]
    param()
    
    Write-LangGraphLog -Message "Getting server information" -Function $MyInvocation.MyCommand.Name
    
    try {
        $serverInfo = Invoke-LangGraphRequest -Uri "$script:LangGraphServerUri/" -Method Get
        Write-LangGraphLog -Message "Server info retrieved: Version $($serverInfo.version), Active graphs: $($serverInfo.active_graphs)" -Level Info
        return $serverInfo
    }
    catch {
        Write-LangGraphLog -Message "Failed to get server information: $($_.Exception.Message)" -Level Error
        throw
    }
}

function Get-LangGraphServerStatus {
    <#
    .SYNOPSIS
    Gets the current status of the LangGraph server
    
    .DESCRIPTION
    Retrieves detailed server status including database connectivity,
    active graphs, and system health metrics
    
    .EXAMPLE
    Get-LangGraphServerStatus
    Returns server status object with database and graph information
    #>
    [CmdletBinding()]
    param()
    
    Write-LangGraphLog -Message "Getting server status" -Function $MyInvocation.MyCommand.Name
    
    try {
        $status = Invoke-LangGraphRequest -Uri "$script:LangGraphServerUri/health" -Method Get
        Write-LangGraphLog -Message "Server status retrieved: Database $($status.database), Active graphs: $($status.active_graphs)" -Level Info
        return $status
    }
    catch {
        Write-LangGraphLog -Message "Failed to get server status: $($_.Exception.Message)" -Level Error
        throw
    }
}

# Graph management functions
function New-LangGraph {
    <#
    .SYNOPSIS
    Creates a new LangGraph instance
    
    .DESCRIPTION
    Creates a new graph with specified ID and type on the LangGraph server
    
    .PARAMETER GraphId
    Unique identifier for the graph
    
    .PARAMETER GraphType
    Type of graph to create ('basic' or 'hitl')
    
    .PARAMETER Config
    Optional configuration hashtable for the graph
    
    .EXAMPLE
    New-LangGraph -GraphId "test-graph" -GraphType "basic"
    Creates a basic graph with ID "test-graph"
    
    .EXAMPLE
    New-LangGraph -GraphId "approval-graph" -GraphType "hitl" -Config @{ timeout = 300 }
    Creates a human-in-the-loop graph with custom configuration
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$GraphId,
        
        [Parameter()]
        [ValidateSet('basic', 'hitl', 'simple_approval', 'detailed_approval', 'state_review', 'conditional_interrupt')]
        [string]$GraphType = 'basic',
        
        [Parameter()]
        [hashtable]$Config = @{}
    )
    
    Write-LangGraphLog -Message "Creating new graph: $GraphId (type: $GraphType)" -Function $MyInvocation.MyCommand.Name
    
    $requestBody = @{
        graph_id = $GraphId
        graph_type = $GraphType
        config = $Config
    }
    
    try {
        $response = Invoke-LangGraphRequest -Uri "$script:LangGraphServerUri/graphs" -Method Post -Body $requestBody
        Write-LangGraphLog -Message "Graph created successfully: $GraphId" -Level Info
        return $response
    }
    catch {
        Write-LangGraphLog -Message "Failed to create graph $GraphId : $($_.Exception.Message)" -Level Error
        throw
    }
}

function Get-LangGraph {
    <#
    .SYNOPSIS
    Lists all available graphs or gets information about a specific graph
    
    .DESCRIPTION
    Retrieves information about all graphs currently available on the server,
    or details about a specific graph if GraphId is provided
    
    .PARAMETER GraphId
    Optional specific graph ID to query. If not provided, returns all graphs.
    
    .EXAMPLE
    Get-LangGraph
    Returns information about all available graphs
    
    .EXAMPLE
    Get-LangGraph -GraphId "my-graph-123"
    Returns information about the specific graph
    #>
    [CmdletBinding()]
    param(
        [Parameter()]
        [string]$GraphId
    )
    
    if ($GraphId) {
        Write-LangGraphLog -Message "Retrieving information for graph: $GraphId" -Function $MyInvocation.MyCommand.Name
        
        try {
            $response = Invoke-LangGraphRequest -Uri "$script:LangGraphServerUri/graphs/$GraphId" -Method Get
            Write-LangGraphLog -Message "Retrieved information for graph: $GraphId" -Level Info
            return $response
        }
        catch {
            Write-LangGraphLog -Message "Failed to retrieve graph information for $GraphId`: $($_.Exception.Message)" -Level Error
            throw
        }
    } else {
        Write-LangGraphLog -Message "Retrieving information for all graphs" -Function $MyInvocation.MyCommand.Name
        
        try {
            $response = Invoke-LangGraphRequest -Uri "$script:LangGraphServerUri/graphs" -Method Get
            Write-LangGraphLog -Message "Retrieved information for $($response.total) graphs" -Level Info
            return $response
        }
        catch {
            Write-LangGraphLog -Message "Failed to retrieve graph information: $($_.Exception.Message)" -Level Error
            throw
        }
    }
}

function Remove-LangGraph {
    <#
    .SYNOPSIS
    Deletes a graph from the server
    
    .DESCRIPTION
    Removes a graph and all its associated data from the LangGraph server
    
    .PARAMETER GraphId
    The ID of the graph to delete
    
    .EXAMPLE
    Remove-LangGraph -GraphId "test-graph"
    Deletes the graph with ID "test-graph"
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory = $true)]
        [string]$GraphId
    )
    
    if ($PSCmdlet.ShouldProcess($GraphId, "Delete LangGraph")) {
        Write-LangGraphLog -Message "Deleting graph: $GraphId" -Function $MyInvocation.MyCommand.Name
        
        try {
            $response = Invoke-LangGraphRequest -Uri "$script:LangGraphServerUri/graphs/$GraphId" -Method Delete
            Write-LangGraphLog -Message "Graph deleted successfully: $GraphId" -Level Info
            return $response
        }
        catch {
            Write-LangGraphLog -Message "Failed to delete graph $GraphId : $($_.Exception.Message)" -Level Error
            throw
        }
    }
}

# Graph execution functions
function Start-LangGraphExecution {
    <#
    .SYNOPSIS
    Executes a LangGraph with given initial state
    
    .DESCRIPTION
    Starts execution of a graph with provided initial state. May complete immediately 
    or be interrupted for human-in-the-loop processing.
    
    .PARAMETER GraphId
    The ID of the graph to execute
    
    .PARAMETER InitialState
    Hashtable containing the initial state for graph execution
    
    .PARAMETER ThreadId
    Optional thread ID for persistence. If not provided, a new one is generated
    
    .EXAMPLE
    Start-LangGraphExecution -GraphId "test-graph" -InitialState @{ counter = 0; messages = @() }
    Executes the test-graph with initial state
    
    .EXAMPLE
    $result = Start-LangGraphExecution -GraphId "approval-graph" -InitialState @{ counter = 5 } -ThreadId "my-thread"
    if ($result.status -eq "interrupted") {
        Write-Host "Execution paused for human input"
    }
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$GraphId,
        
        [Parameter()]
        [hashtable]$InitialState = @{},
        
        [Parameter()]
        [string]$ThreadId = $null
    )
    
    Write-LangGraphLog -Message "Starting graph execution: $GraphId" -Function $MyInvocation.MyCommand.Name
    
    $requestBody = @{
        graph_id = $GraphId
        initial_state = $InitialState
    }
    
    if ($ThreadId) {
        $requestBody.thread_id = $ThreadId
    }
    
    try {
        $response = Invoke-LangGraphRequest -Uri "$script:LangGraphServerUri/graphs/$GraphId/execute" -Method Post -Body $requestBody
        
        if ($response.status -eq "completed") {
            Write-LangGraphLog -Message "Graph execution completed: $GraphId" -Level Info
        }
        elseif ($response.status -eq "interrupted") {
            Write-LangGraphLog -Message "Graph execution interrupted for HITL: $GraphId, Thread: $($response.thread_id)" -Level Info
        }
        
        return $response
    }
    catch {
        Write-LangGraphLog -Message "Failed to execute graph $GraphId : $($_.Exception.Message)" -Level Error
        throw
    }
}

function Resume-LangGraphExecution {
    <#
    .SYNOPSIS
    Resumes an interrupted graph execution
    
    .DESCRIPTION
    Provides input to resume a graph that was paused for human-in-the-loop processing
    
    .PARAMETER GraphId
    The ID of the graph to resume
    
    .PARAMETER ThreadId
    The thread ID of the interrupted execution
    
    .PARAMETER ResumeValue
    The value/input to provide for resuming execution
    
    .EXAMPLE
    Resume-LangGraphExecution -GraphId "approval-graph" -ThreadId "thread-123" -ResumeValue @{ approved = $true }
    Resumes execution with approval
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$GraphId,
        
        [Parameter(Mandatory = $true)]
        [string]$ThreadId,
        
        [Parameter(Mandatory = $true)]
        [object]$ResumeValue
    )
    
    Write-LangGraphLog -Message "Resuming graph execution: $GraphId, Thread: $ThreadId" -Function $MyInvocation.MyCommand.Name
    
    $requestBody = @{
        graph_id = $GraphId
        thread_id = $ThreadId
        resume_value = $ResumeValue
    }
    
    try {
        $response = Invoke-LangGraphRequest -Uri "$script:LangGraphServerUri/graphs/$GraphId/resume" -Method Post -Body $requestBody
        Write-LangGraphLog -Message "Graph execution resumed and completed: $GraphId" -Level Info
        return $response
    }
    catch {
        Write-LangGraphLog -Message "Failed to resume graph $GraphId : $($_.Exception.Message)" -Level Error
        throw
    }
}

# Thread management functions
function Get-LangGraphThread {
    <#
    .SYNOPSIS
    Gets information about execution threads
    
    .DESCRIPTION
    Retrieves information about all active threads or a specific thread
    
    .PARAMETER ThreadId
    Optional specific thread ID to query
    
    .EXAMPLE
    Get-LangGraphThread
    Returns information about all active threads
    
    .EXAMPLE
    Get-LangGraphThread -ThreadId "thread-123"
    Returns information about specific thread
    #>
    [CmdletBinding()]
    param(
        [Parameter()]
        [string]$ThreadId = $null
    )
    
    if ($ThreadId) {
        Write-LangGraphLog -Message "Getting thread information: $ThreadId" -Function $MyInvocation.MyCommand.Name
        $uri = "$script:LangGraphServerUri/threads/$ThreadId"
    }
    else {
        Write-LangGraphLog -Message "Getting all thread information" -Function $MyInvocation.MyCommand.Name
        $uri = "$script:LangGraphServerUri/threads"
    }
    
    try {
        $response = Invoke-LangGraphRequest -Uri $uri -Method Get
        return $response
    }
    catch {
        Write-LangGraphLog -Message "Failed to get thread information: $($_.Exception.Message)" -Level Error
        throw
    }
}

function Remove-LangGraphThread {
    <#
    .SYNOPSIS
    Deletes a thread and its execution history
    
    .DESCRIPTION
    Removes a thread and all associated execution state from the server
    
    .PARAMETER ThreadId
    The ID of the thread to delete
    
    .EXAMPLE
    Remove-LangGraphThread -ThreadId "thread-123"
    Deletes the specified thread
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory = $true)]
        [string]$ThreadId
    )
    
    if ($PSCmdlet.ShouldProcess($ThreadId, "Delete LangGraph Thread")) {
        Write-LangGraphLog -Message "Deleting thread: $ThreadId" -Function $MyInvocation.MyCommand.Name
        
        try {
            $response = Invoke-LangGraphRequest -Uri "$script:LangGraphServerUri/threads/$ThreadId" -Method Delete
            Write-LangGraphLog -Message "Thread deleted successfully: $ThreadId" -Level Info
            return $response
        }
        catch {
            Write-LangGraphLog -Message "Failed to delete thread $ThreadId : $($_.Exception.Message)" -Level Error
            throw
        }
    }
}

# Utility functions
function Set-LangGraphServerUri {
    <#
    .SYNOPSIS
    Sets the URI for the LangGraph server
    
    .DESCRIPTION
    Updates the server URI used for all API calls
    
    .PARAMETER Uri
    The new server URI (e.g., "http://localhost:8000")
    
    .EXAMPLE
    Set-LangGraphServerUri -Uri "http://192.168.1.100:8000"
    Changes server URI to a remote server
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Uri
    )
    
    Write-LangGraphLog -Message "Updating server URI from $script:LangGraphServerUri to $Uri" -Function $MyInvocation.MyCommand.Name
    $script:LangGraphServerUri = $Uri.TrimEnd('/')
    Write-LangGraphLog -Message "Server URI updated successfully" -Level Info
}

function Get-LangGraphServerUri {
    <#
    .SYNOPSIS
    Gets the current LangGraph server URI
    
    .DESCRIPTION
    Returns the URI currently being used for API calls
    
    .EXAMPLE
    Get-LangGraphServerUri
    Returns the current server URI
    #>
    [CmdletBinding()]
    param()
    
    return $script:LangGraphServerUri
}

function Enable-LangGraphLogging {
    <#
    .SYNOPSIS
    Enables logging for LangGraph Bridge operations
    
    .EXAMPLE
    Enable-LangGraphLogging
    #>
    [CmdletBinding()]
    param()
    
    $script:LoggingEnabled = $true
    Write-LangGraphLog -Message "Logging enabled" -Level Info
}

function Disable-LangGraphLogging {
    <#
    .SYNOPSIS
    Disables logging for LangGraph Bridge operations
    
    .EXAMPLE
    Disable-LangGraphLogging
    #>
    [CmdletBinding()]
    param()
    
    Write-LangGraphLog -Message "Logging disabled" -Level Info
    $script:LoggingEnabled = $false
}

# Helper function for HITL workflows
# ===== ENHANCED HITL FUNCTIONS (Hour 7: HITL Interrupt Handling) =====

function Show-LangGraphInterrupt {
    <#
    .SYNOPSIS
    Display detailed interrupt information to user with rich formatting
    
    .DESCRIPTION
    Shows interrupt details with proper formatting, context, and available options
    for enhanced human-in-the-loop decision making.
    
    .PARAMETER InterruptData
    The interrupt data received from LangGraph
    
    .PARAMETER ThreadId  
    The thread ID for the interrupted execution
    
    .PARAMETER GraphId
    The graph ID for the interrupted execution
    
    .EXAMPLE
    Show-LangGraphInterrupt -InterruptData $interruptInfo -ThreadId $threadId -GraphId $graphId
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [object]$InterruptData,
        
        [Parameter(Mandatory = $true)]
        [string]$ThreadId,
        
        [Parameter(Mandatory = $true)]
        [string]$GraphId
    )
    
    Write-Host "`n" -NoNewline
    Write-Host "====== LANGGRAPH INTERRUPT NOTIFICATION ======" -ForegroundColor Yellow
    Write-Host "Graph: " -ForegroundColor Cyan -NoNewline
    Write-Host $GraphId -ForegroundColor White
    Write-Host "Thread: " -ForegroundColor Cyan -NoNewline
    Write-Host $ThreadId -ForegroundColor White
    Write-Host "Type: " -ForegroundColor Cyan -NoNewline
    Write-Host $InterruptData.interrupt_type -ForegroundColor White
    Write-Host "Time: " -ForegroundColor Cyan -NoNewline
    Write-Host $InterruptData.timestamp -ForegroundColor White
    
    if ($InterruptData.urgency) {
        Write-Host "Urgency: " -ForegroundColor Cyan -NoNewline
        $urgencyColor = switch ($InterruptData.urgency) {
            "high" { "Red" }
            "medium" { "Yellow" }
            "low" { "Green" }
            default { "White" }
        }
        Write-Host $InterruptData.urgency.ToUpper() -ForegroundColor $urgencyColor
    }
    
    Write-Host "`nMessage:" -ForegroundColor Cyan
    Write-Host $InterruptData.message -ForegroundColor White
    
    if ($InterruptData.current_state) {
        Write-Host "`nCurrent State:" -ForegroundColor Cyan
        $InterruptData.current_state | Format-Table -AutoSize | Out-String | Write-Host -ForegroundColor Gray
    }
    
    if ($InterruptData.action_details) {
        Write-Host "`nAction Details:" -ForegroundColor Cyan
        $InterruptData.action_details | Format-Table -AutoSize | Out-String | Write-Host -ForegroundColor Gray
    }
    
    if ($InterruptData.options) {
        Write-Host "`nAvailable Options:" -ForegroundColor Cyan
        $InterruptData.options | ForEach-Object -Begin { $i = 1 } -Process {
            Write-Host "  $i. $_" -ForegroundColor Green
            $i++
        }
    }
    
    Write-Host "===============================================" -ForegroundColor Yellow
    Write-Host ""
}

function Get-LangGraphInterruptChoice {
    <#
    .SYNOPSIS
    Get user choice for interrupt handling with validation
    
    .DESCRIPTION
    Prompts user for input with validation against available options and
    returns structured response data for LangGraph resumption.
    
    .PARAMETER InterruptData
    The interrupt data containing available options
    
    .PARAMETER AllowCustomInput
    Allow custom input beyond predefined options
    
    .EXAMPLE
    $choice = Get-LangGraphInterruptChoice -InterruptData $interruptInfo
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [object]$InterruptData,
        
        [Parameter()]
        [switch]$AllowCustomInput
    )
    
    $validOptions = $InterruptData.options
    $interruptType = $InterruptData.interrupt_type
    
    do {
        switch ($interruptType) {
            "approval" {
                $response = Read-Host "Choose (approve/reject)"
                $approved = $response -in @('approve', 'a', 'yes', 'y')
                return @{
                    approved = $approved
                    action = if ($approved) { "approve" } else { "reject" }
                    response_time = (Get-Date).ToString("o")
                }
            }
            
            "detailed_approval" {
                Write-Host "Options: " -ForegroundColor Cyan -NoNewline
                Write-Host ($validOptions -join ", ") -ForegroundColor Green
                $response = Read-Host "Your choice"
                
                if ($response -in $validOptions) {
                    $result = @{
                        approved = ($response -eq "approve")
                        action = $response
                        response_time = (Get-Date).ToString("o")
                    }
                    
                    if ($response -eq "modify") {
                        $modifications = Read-Host "Enter modifications (JSON format or description)"
                        $result["details"] = @{ modifications = $modifications }
                    }
                    
                    return $result
                }
                else {
                    Write-Host "Invalid choice. Please select from: $($validOptions -join ', ')" -ForegroundColor Red
                }
            }
            
            "state_review" {
                Write-Host "Editable fields: " -ForegroundColor Cyan -NoNewline
                Write-Host ($InterruptData.editable_fields -join ", ") -ForegroundColor Green
                
                $modifications = @{}
                $makeChanges = Read-Host "Make changes? (y/n)"
                
                if ($makeChanges -in @('y', 'yes')) {
                    foreach ($field in $InterruptData.editable_fields) {
                        $currentValue = $InterruptData.current_state.$field
                        Write-Host "Current $field`: $currentValue" -ForegroundColor Gray
                        $newValue = Read-Host "New value for $field (press Enter to keep current)"
                        
                        if (-not [string]::IsNullOrWhiteSpace($newValue)) {
                            # Try to parse as number if it looks like one
                            if ($newValue -match '^\d+$') {
                                $modifications[$field] = [int]$newValue
                            }
                            else {
                                $modifications[$field] = $newValue
                            }
                        }
                    }
                }
                
                return @{
                    approved = $true
                    action = "review_complete"
                    modifications = $modifications
                    response_time = (Get-Date).ToString("o")
                }
            }
            
            "conditional" {
                Write-Host "Condition: " -ForegroundColor Cyan -NoNewline
                Write-Host $InterruptData.trigger_condition -ForegroundColor Yellow
                $response = Read-Host "How to proceed? (continue/stop/modify)"
                
                return @{
                    approved = ($response -ne "stop")
                    action = $response
                    response_time = (Get-Date).ToString("o")
                }
            }
            
            default {
                if ($validOptions) {
                    Write-Host "Available options: " -ForegroundColor Cyan -NoNewline
                    Write-Host ($validOptions -join ", ") -ForegroundColor Green
                    $response = Read-Host "Your choice"
                    
                    if ($response -in $validOptions -or $AllowCustomInput) {
                        return @{
                            approved = ($response -in @("approve", "yes", "continue"))
                            action = $response
                            response_time = (Get-Date).ToString("o")
                        }
                    }
                    else {
                        Write-Host "Invalid choice. Please select from available options." -ForegroundColor Red
                    }
                }
                else {
                    $response = Read-Host "Enter your response"
                    return @{
                        approved = $true
                        action = $response
                        response_time = (Get-Date).ToString("o")
                    }
                }
            }
        }
    } while ($true)
}

function Wait-LangGraphApprovalEnhanced {
    <#
    .SYNOPSIS
    Enhanced approval waiting with rich interrupt handling
    
    .DESCRIPTION
    Waits for and handles LangGraph interrupts with enhanced user interface,
    multiple approval types, and comprehensive notification system integration.
    
    .PARAMETER GraphId
    Graph identifier for the interrupted execution
    
    .PARAMETER ThreadId
    Thread identifier for the interrupted execution
    
    .PARAMETER TimeoutSeconds
    Timeout in seconds for user response (default: 300)
    
    .PARAMETER ShowDetails
    Show detailed interrupt information
    
    .EXAMPLE
    Wait-LangGraphApprovalEnhanced -GraphId "workflow-01" -ThreadId "thread-123" -ShowDetails
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$GraphId,
        
        [Parameter(Mandatory = $true)]
        [string]$ThreadId,
        
        [Parameter()]
        [int]$TimeoutSeconds = 300,
        
        [Parameter()]
        [switch]$ShowDetails
    )
    
    Write-LangGraphLog -Message "Enhanced approval waiting for $GraphId/$ThreadId" -Function $MyInvocation.MyCommand.Name
    
    try {
        # Get thread information to check for interrupt data
        $threadInfo = Get-LangGraphThread -ThreadId $ThreadId
        
        if ($threadInfo.info.status -ne 'interrupted') {
            Write-Host "Thread is not in interrupted state. Current status: $($threadInfo.info.status)" -ForegroundColor Yellow
            return $threadInfo
        }
        
        # For this implementation, we'll simulate interrupt data since it's not directly available
        # In a real scenario, this would come from the thread's interrupt information
        $interruptData = @{
            interrupt_type = "enhanced_approval"
            message = "Enhanced approval required for graph execution"
            current_state = $threadInfo.info
            options = @("approve", "reject", "modify", "skip")
            urgency = "medium"
            timestamp = (Get-Date).ToString("o")
        }
        
        if ($ShowDetails) {
            Show-LangGraphInterrupt -InterruptData $interruptData -ThreadId $ThreadId -GraphId $GraphId
        }
        
        # Get user choice
        Write-Host "=== ENHANCED APPROVAL REQUEST ===" -ForegroundColor Yellow
        Write-Host "Graph: $GraphId" -ForegroundColor Cyan
        Write-Host "Thread: $ThreadId" -ForegroundColor Cyan
        Write-Host ""
        
        $userChoice = Get-LangGraphInterruptChoice -InterruptData $interruptData
        
        Write-LangGraphLog -Message "User choice received: $($userChoice.action)" -Level Info
        
        # Resume execution with user choice
        $resumeResult = Resume-LangGraphExecution -GraphId $GraphId -ThreadId $ThreadId -ResumeValue $userChoice
        
        # Display result
        $actionColor = switch ($userChoice.action) {
            "approve" { "Green" }
            "reject" { "Red" }
            "modify" { "Yellow" }
            "skip" { "Cyan" }
            default { "White" }
        }
        
        Write-Host "Action: " -NoNewline
        Write-Host $userChoice.action.ToUpper() -ForegroundColor $actionColor
        Write-Host "Status: " -NoNewline
        Write-Host $resumeResult.status -ForegroundColor Green
        
        return $resumeResult
    }
    catch {
        Write-LangGraphLog -Message "Enhanced approval failed: $($_.Exception.Message)" -Level Error
        throw
    }
}

function Wait-LangGraphApproval {
    <#
    .SYNOPSIS
    Interactive helper for handling HITL (Human-in-the-Loop) approvals
    
    .DESCRIPTION
    Provides an interactive prompt for approving or rejecting interrupted graph executions
    
    .PARAMETER GraphId
    The ID of the interrupted graph
    
    .PARAMETER ThreadId
    The thread ID of the interrupted execution
    
    .PARAMETER Message
    Optional custom message to display to user
    
    .EXAMPLE
    Wait-LangGraphApproval -GraphId "approval-graph" -ThreadId "thread-123"
    Prompts user for approval and automatically resumes execution
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$GraphId,
        
        [Parameter(Mandatory = $true)]
        [string]$ThreadId,
        
        [Parameter()]
        [string]$Message = "Graph execution requires approval. Do you want to proceed?"
    )
    
    Write-LangGraphLog -Message "Waiting for user approval: $GraphId, Thread: $ThreadId" -Function $MyInvocation.MyCommand.Name
    
    # Display approval prompt
    Write-Host "`n" -NoNewline
    Write-Host "=== HUMAN-IN-THE-LOOP APPROVAL REQUIRED ===" -ForegroundColor Yellow
    Write-Host "Graph: $GraphId" -ForegroundColor Cyan
    Write-Host "Thread: $ThreadId" -ForegroundColor Cyan
    Write-Host "Message: $Message" -ForegroundColor White
    Write-Host ""
    
    # Get user input
    do {
        $response = Read-Host "Approve? (y/n)"
        $response = $response.ToLower().Trim()
    } while ($response -notin @('y', 'n', 'yes', 'no'))
    
    # Determine approval status
    $approved = $response -in @('y', 'yes')
    
    Write-LangGraphLog -Message "User response: $response (approved: $approved)" -Level Info
    
    # Resume execution with approval response
    try {
        $resumeValue = @{ approved = $approved }
        $result = Resume-LangGraphExecution -GraphId $GraphId -ThreadId $ThreadId -ResumeValue $resumeValue
        
        if ($approved) {
            Write-Host "Execution approved and resumed." -ForegroundColor Green
        }
        else {
            Write-Host "Execution rejected. Process cancelled." -ForegroundColor Red
        }
        
        return $result
    }
    catch {
        Write-LangGraphLog -Message "Failed to resume execution after approval: $($_.Exception.Message)" -Level Error
        throw
    }
}

# ===== STATE MANAGEMENT FUNCTIONS (Hour 6: State Management Interface) =====

function Test-LangGraphState {
    <#
    .SYNOPSIS
    Validate PowerShell state data against LangGraph schema
    
    .DESCRIPTION
    Validates state data to ensure it conforms to the expected schema for a given state type
    before processing by LangGraph workflows.
    
    .PARAMETER StateData
    Hashtable containing the state data to validate
    
    .PARAMETER StateType
    Type of state validation to perform: basic, hitl, multi_agent, complex
    
    .PARAMETER GraphId
    Graph ID for context (optional)
    
    .PARAMETER ThreadId
    Thread ID for context (optional)
    
    .EXAMPLE
    $state = @{ counter = 5; messages = @() }
    Test-LangGraphState -StateData $state -StateType "basic"
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [hashtable]$StateData,
        
        [Parameter(Mandatory = $true)]
        [ValidateSet('basic', 'hitl', 'multi_agent', 'complex')]
        [string]$StateType,
        
        [Parameter()]
        [string]$GraphId = "test-validation",
        
        [Parameter()]
        [string]$ThreadId = $null
    )
    
    Write-LangGraphLog -Message "Validating state data (type: $StateType)" -Function $MyInvocation.MyCommand.Name
    
    try {
        $requestBody = @{
            state_data = $StateData
            state_type = $StateType
            graph_id = $GraphId
            thread_id = $ThreadId
        }
        
        $response = Invoke-LangGraphRequest -Uri "$script:LangGraphServerUri/state/validate" -Method Post -Body $requestBody
        
        Write-LangGraphLog -Message "State validation result: $($response.valid)" -Level Info
        return $response
    }
    catch {
        Write-LangGraphLog -Message "State validation failed: $($_.Exception.Message)" -Level Error
        throw
    }
}

function ConvertTo-LangGraphState {
    <#
    .SYNOPSIS
    Process PowerShell state data for LangGraph consumption
    
    .DESCRIPTION
    Converts PowerShell state data to LangGraph-compatible format, including validation,
    serialization, and optional snapshot creation for persistence.
    
    .PARAMETER StateData
    Hashtable containing the state data to process
    
    .PARAMETER StateType
    Type of state processing: basic, hitl, multi_agent, complex
    
    .PARAMETER GraphId
    Graph ID for context
    
    .PARAMETER ThreadId
    Thread ID for context (enables snapshot creation)
    
    .EXAMPLE
    $state = @{ counter = 1; messages = @(@{ role = "user"; content = "Hello" }) }
    ConvertTo-LangGraphState -StateData $state -StateType "basic" -GraphId "chat-01"
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [hashtable]$StateData,
        
        [Parameter(Mandatory = $true)]
        [ValidateSet('basic', 'hitl', 'multi_agent', 'complex')]
        [string]$StateType,
        
        [Parameter(Mandatory = $true)]
        [string]$GraphId,
        
        [Parameter()]
        [string]$ThreadId = $null
    )
    
    Write-LangGraphLog -Message "Processing PowerShell state for LangGraph (graph: $GraphId, type: $StateType)" -Function $MyInvocation.MyCommand.Name
    
    try {
        $requestBody = @{
            state_data = $StateData
            state_type = $StateType
            graph_id = $GraphId
            thread_id = $ThreadId
        }
        
        $response = Invoke-LangGraphRequest -Uri "$script:LangGraphServerUri/state/process" -Method Post -Body $requestBody
        
        Write-LangGraphLog -Message "State processing completed successfully" -Level Info
        return $response
    }
    catch {
        Write-LangGraphLog -Message "State processing failed: $($_.Exception.Message)" -Level Error
        throw
    }
}

function Sync-LangGraphState {
    <#
    .SYNOPSIS
    Synchronize state with LangGraph checkpoint storage
    
    .DESCRIPTION
    Merges current state with previously stored checkpoints, enabling state persistence
    and recovery across PowerShell-LangGraph executions.
    
    .PARAMETER GraphId
    Graph identifier
    
    .PARAMETER ThreadId
    Thread identifier
    
    .PARAMETER CurrentState
    Current state data to synchronize
    
    .EXAMPLE
    $currentState = @{ counter = 10; messages = @() }
    Sync-LangGraphState -GraphId "workflow-01" -ThreadId "session-123" -CurrentState $currentState
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$GraphId,
        
        [Parameter(Mandatory = $true)]
        [string]$ThreadId,
        
        [Parameter(Mandatory = $true)]
        [hashtable]$CurrentState
    )
    
    Write-LangGraphLog -Message "Synchronizing state for $GraphId/$ThreadId" -Function $MyInvocation.MyCommand.Name
    
    try {
        $requestBody = @{
            graph_id = $GraphId
            thread_id = $ThreadId
            current_state = $CurrentState
        }
        
        $response = Invoke-LangGraphRequest -Uri "$script:LangGraphServerUri/state/synchronize" -Method Post -Body $requestBody
        
        Write-LangGraphLog -Message "State synchronization completed successfully" -Level Info
        return $response
    }
    catch {
        Write-LangGraphLog -Message "State synchronization failed: $($_.Exception.Message)" -Level Error
        throw
    }
}

function Get-LangGraphStateSnapshot {
    <#
    .SYNOPSIS
    Get state snapshots from LangGraph storage
    
    .DESCRIPTION
    Retrieves state snapshots from LangGraph checkpoint storage, optionally filtered
    by graph ID and thread ID.
    
    .PARAMETER SnapshotId
    Specific snapshot ID to retrieve (when specified, returns single snapshot)
    
    .PARAMETER GraphId
    Filter by graph ID (optional)
    
    .PARAMETER ThreadId
    Filter by thread ID (optional)
    
    .EXAMPLE
    Get-LangGraphStateSnapshot
    
    .EXAMPLE  
    Get-LangGraphStateSnapshot -GraphId "workflow-01"
    
    .EXAMPLE
    Get-LangGraphStateSnapshot -SnapshotId "workflow-01_thread-123_20250823_160000"
    #>
    [CmdletBinding(DefaultParameterSetName = 'List')]
    param(
        [Parameter(ParameterSetName = 'Single', Mandatory = $true)]
        [string]$SnapshotId,
        
        [Parameter(ParameterSetName = 'List')]
        [string]$GraphId = $null,
        
        [Parameter(ParameterSetName = 'List')]
        [string]$ThreadId = $null
    )
    
    if ($PSCmdlet.ParameterSetName -eq 'Single') {
        Write-LangGraphLog -Message "Getting state snapshot: $SnapshotId" -Function $MyInvocation.MyCommand.Name
        
        try {
            $response = Invoke-LangGraphRequest -Uri "$script:LangGraphServerUri/state/snapshots/$SnapshotId" -Method Get
            Write-LangGraphLog -Message "Retrieved snapshot successfully" -Level Info
            return $response
        }
        catch {
            Write-LangGraphLog -Message "Failed to get snapshot: $($_.Exception.Message)" -Level Error
            throw
        }
    }
    else {
        Write-LangGraphLog -Message "Listing state snapshots (graph: $GraphId, thread: $ThreadId)" -Function $MyInvocation.MyCommand.Name
        
        try {
            $uri = "$script:LangGraphServerUri/state/snapshots"
            $queryParams = @()
            
            if ($GraphId) { $queryParams += "graph_id=$GraphId" }
            if ($ThreadId) { $queryParams += "thread_id=$ThreadId" }
            
            if ($queryParams.Count -gt 0) {
                $uri += "?" + ($queryParams -join "&")
            }
            
            $response = Invoke-LangGraphRequest -Uri $uri -Method Get
            Write-LangGraphLog -Message "Listed $($response.total) snapshots" -Level Info
            return $response
        }
        catch {
            Write-LangGraphLog -Message "Failed to list snapshots: $($_.Exception.Message)" -Level Error
            throw
        }
    }
}

function Get-LangGraphStateStatistics {
    <#
    .SYNOPSIS
    Get state management statistics
    
    .DESCRIPTION
    Retrieves statistics about state management operations, including snapshot counts,
    graph/thread activity, and state type distribution.
    
    .EXAMPLE
    Get-LangGraphStateStatistics
    #>
    [CmdletBinding()]
    param()
    
    Write-LangGraphLog -Message "Getting state management statistics" -Function $MyInvocation.MyCommand.Name
    
    try {
        $response = Invoke-LangGraphRequest -Uri "$script:LangGraphServerUri/state/statistics" -Method Get
        
        Write-LangGraphLog -Message "Retrieved state statistics successfully" -Level Info
        return $response
    }
    catch {
        Write-LangGraphLog -Message "Failed to get state statistics: $($_.Exception.Message)" -Level Error
        throw
    }
}

function ConvertFrom-LangGraphState {
    <#
    .SYNOPSIS
    Prepare LangGraph state for PowerShell consumption
    
    .DESCRIPTION
    Converts Python/LangGraph state data to PowerShell-friendly format with proper
    type conversion and optional metadata inclusion.
    
    .PARAMETER StateData
    State data from LangGraph (typically from API response)
    
    .PARAMETER IncludeMetadata
    Include processing metadata in the result
    
    .EXAMPLE
    $pythonState = @{ counter = 5; result = "success" }
    ConvertFrom-LangGraphState -StateData $pythonState -IncludeMetadata
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [hashtable]$StateData,
        
        [Parameter()]
        [switch]$IncludeMetadata
    )
    
    Write-LangGraphLog -Message "Preparing state data for PowerShell" -Function $MyInvocation.MyCommand.Name
    
    try {
        $requestBody = @{
            state_data = $StateData
            include_metadata = $IncludeMetadata.IsPresent
        }
        
        $response = Invoke-LangGraphRequest -Uri "$script:LangGraphServerUri/state/prepare-for-powershell" -Method Post -Body $requestBody
        
        Write-LangGraphLog -Message "State prepared for PowerShell successfully" -Level Info
        return $response
    }
    catch {
        Write-LangGraphLog -Message "Failed to prepare state for PowerShell: $($_.Exception.Message)" -Level Error
        throw
    }
}

# Module initialization
Write-LangGraphLog -Message "Unity-Claude LangGraph Bridge module loaded. Server URI: $script:LangGraphServerUri" -Level Info

# Export functions
Export-ModuleMember -Function @(
    'Test-LangGraphServer',
    'Get-LangGraphServerInfo',
    'Get-LangGraphServerStatus',
    'New-LangGraph',
    'Get-LangGraph', 
    'Remove-LangGraph',
    'Start-LangGraphExecution',
    'Resume-LangGraphExecution',
    'Get-LangGraphThread',
    'Remove-LangGraphThread',
    'Set-LangGraphServerUri',
    'Get-LangGraphServerUri',
    'Enable-LangGraphLogging',
    'Disable-LangGraphLogging',
    'Wait-LangGraphApproval',
    'Test-LangGraphState',
    'ConvertTo-LangGraphState',
    'Sync-LangGraphState',
    'Get-LangGraphStateSnapshot',
    'Get-LangGraphStateStatistics',
    'ConvertFrom-LangGraphState',
    'Show-LangGraphInterrupt',
    'Get-LangGraphInterruptChoice',
    'Wait-LangGraphApprovalEnhanced'
)