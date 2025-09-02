#Requires -Version 5.1

<#
.SYNOPSIS
Unity-Claude-LangGraphBridge - PowerShell to LangGraph API integration module

.DESCRIPTION
Provides PowerShell integration functions for LangGraph local server API communication.
Implements the 8 core functions required for Week 1 Day 1 Hour 1-2 deliverables.

.NOTES
Author: Unity-Claude-Automation System
Version: 1.0.0
LangGraph API Endpoint: http://localhost:8000 (configurable)
Dependencies: None (pure PowerShell REST API calls)
#>

# Module configuration
$script:LangGraphConfig = @{
    BaseUrl = "http://localhost:8000"
    TimeoutSeconds = 300
    RetryCount = 3
    RetryDelaySeconds = 2
    ContentType = "application/json"
    Encoding = "UTF-8"
}

#region Core LangGraph Communication Functions

function New-LangGraphWorkflow {
    <#
    .SYNOPSIS
    Creates a new LangGraph workflow definition
    
    .DESCRIPTION
    Submits a workflow definition to the LangGraph service and returns the workflow ID
    
    .PARAMETER WorkflowDefinition
    Hashtable containing the workflow configuration (orchestrator, workers, steps, etc.)
    
    .PARAMETER WorkflowName
    Name identifier for the workflow
    
    .EXAMPLE
    $workflow = @{
        workflow_type = "orchestrator-worker"
        description = "Test workflow"
        orchestrator = @{ name = "TestOrchestrator" }
        workers = @()
    }
    $workflowId = New-LangGraphWorkflow -WorkflowDefinition $workflow -WorkflowName "test_workflow"
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [hashtable]$WorkflowDefinition,
        
        [Parameter(Mandatory = $true)]
        [string]$WorkflowName
    )
    
    try {
        $body = @{
            workflow_name = $WorkflowName
            definition = $WorkflowDefinition
        } | ConvertTo-Json -Depth 10
        
        $response = Invoke-RestMethod -Uri "$($script:LangGraphConfig.BaseUrl)/workflows" -Method Post -Body $body -ContentType $script:LangGraphConfig.ContentType -TimeoutSec $script:LangGraphConfig.TimeoutSeconds
        
        return $response.workflow_id
    }
    catch {
        Write-Error "Failed to create LangGraph workflow: $($_.Exception.Message)"
        return $null
    }
}

function Submit-WorkflowTask {
    <#
    .SYNOPSIS
    Submits a task to a LangGraph workflow for processing
    
    .DESCRIPTION
    Sends input data to a specified workflow and returns the task ID for tracking
    
    .PARAMETER WorkflowId
    ID of the workflow to execute
    
    .PARAMETER InputData
    Input data for the workflow (will be serialized to JSON)
    
    .PARAMETER StreamMode
    Optional stream mode for response handling (default: "messages-tuple")
    
    .EXAMPLE
    $taskId = Submit-WorkflowTask -WorkflowId "workflow-123" -InputData @{ messages = @(@{ role = "human"; content = "Test" }) }
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$WorkflowId,
        
        [Parameter(Mandatory = $true)]
        [hashtable]$InputData,
        
        [Parameter()]
        [string]$StreamMode = "messages-tuple"
    )
    
    try {
        $body = @{
            workflow_id = $WorkflowId
            input = $InputData
            stream_mode = $StreamMode
        } | ConvertTo-Json -Depth 10
        
        $response = Invoke-RestMethod -Uri "$($script:LangGraphConfig.BaseUrl)/runs" -Method Post -Body $body -ContentType $script:LangGraphConfig.ContentType -TimeoutSec $script:LangGraphConfig.TimeoutSeconds
        
        return $response.run_id
    }
    catch {
        Write-Error "Failed to submit workflow task: $($_.Exception.Message)"
        return $null
    }
}

function Get-WorkflowResult {
    <#
    .SYNOPSIS
    Retrieves the result of a submitted workflow task
    
    .DESCRIPTION
    Polls the LangGraph service for task completion and returns the result
    
    .PARAMETER TaskId
    ID of the task to check
    
    .PARAMETER PollIntervalSeconds
    Polling interval in seconds (default: 2)
    
    .PARAMETER MaxWaitSeconds
    Maximum time to wait for completion (default: 300)
    
    .EXAMPLE
    $result = Get-WorkflowResult -TaskId "task-456" -PollIntervalSeconds 1 -MaxWaitSeconds 60
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$TaskId,
        
        [Parameter()]
        [int]$PollIntervalSeconds = 2,
        
        [Parameter()]
        [int]$MaxWaitSeconds = 300
    )
    
    $startTime = Get-Date
    $endTime = $startTime.AddSeconds($MaxWaitSeconds)
    
    do {
        try {
            $response = Invoke-RestMethod -Uri "$($script:LangGraphConfig.BaseUrl)/runs/$TaskId" -Method Get -ContentType $script:LangGraphConfig.ContentType -TimeoutSec $script:LangGraphConfig.TimeoutSeconds
            
            if ($response.status -eq "completed") {
                return $response.result
            }
            elseif ($response.status -eq "failed") {
                Write-Error "Workflow task failed: $($response.error)"
                return $null
            }
            
            Start-Sleep -Seconds $PollIntervalSeconds
        }
        catch {
            Write-Error "Failed to get workflow result: $($_.Exception.Message)"
            return $null
        }
    } while ((Get-Date) -lt $endTime)
    
    Write-Warning "Workflow task timed out after $MaxWaitSeconds seconds"
    return $null
}

function Test-LangGraphServer {
    <#
    .SYNOPSIS
    Tests connectivity to the LangGraph server
    
    .DESCRIPTION
    Performs a health check against the LangGraph service endpoint
    
    .PARAMETER BaseUrl
    Optional custom base URL (uses module default if not specified)
    
    .EXAMPLE
    $status = Test-LangGraphServer
    if ($status.status -eq "healthy") { Write-Host "LangGraph server is running" }
    #>
    [CmdletBinding()]
    param(
        [Parameter()]
        [string]$BaseUrl = $script:LangGraphConfig.BaseUrl
    )
    
    try {
        $response = Invoke-RestMethod -Uri "$BaseUrl/health" -Method Get -ContentType $script:LangGraphConfig.ContentType -TimeoutSec 10
        
        return @{
            status = "healthy"
            server_url = $BaseUrl
            response_time_ms = (Measure-Command { Invoke-RestMethod -Uri "$BaseUrl/health" -Method Get -ContentType $script:LangGraphConfig.ContentType -TimeoutSec 10 }).TotalMilliseconds
            version = $response.version
            database = $response.database
        }
    }
    catch {
        return @{
            status = "unhealthy"
            server_url = $BaseUrl
            error = $_.Exception.Message
            database = "unavailable"
        }
    }
}

function Get-LangGraphWorkflows {
    <#
    .SYNOPSIS
    Lists all available workflows on the LangGraph server
    
    .DESCRIPTION
    Retrieves a list of all workflows registered with the LangGraph service
    
    .EXAMPLE
    $workflows = Get-LangGraphWorkflows
    $workflows | ForEach-Object { Write-Host "Workflow: $($_.name) - Status: $($_.status)" }
    #>
    [CmdletBinding()]
    param()
    
    try {
        $response = Invoke-RestMethod -Uri "$($script:LangGraphConfig.BaseUrl)/workflows" -Method Get -ContentType $script:LangGraphConfig.ContentType -TimeoutSec $script:LangGraphConfig.TimeoutSeconds
        
        return $response.workflows
    }
    catch {
        Write-Error "Failed to retrieve workflows: $($_.Exception.Message)"
        return @()
    }
}

function Set-LangGraphConfig {
    <#
    .SYNOPSIS
    Updates the LangGraph module configuration
    
    .DESCRIPTION
    Allows modification of module settings such as base URL, timeouts, and retry behavior
    
    .PARAMETER BaseUrl
    LangGraph server base URL
    
    .PARAMETER TimeoutSeconds
    Request timeout in seconds
    
    .PARAMETER RetryCount
    Number of retries for failed requests
    
    .EXAMPLE
    Set-LangGraphConfig -BaseUrl "http://localhost:2024" -TimeoutSeconds 60
    #>
    [CmdletBinding()]
    param(
        [Parameter()]
        [string]$BaseUrl,
        
        [Parameter()]
        [int]$TimeoutSeconds,
        
        [Parameter()]
        [int]$RetryCount,
        
        [Parameter()]
        [int]$RetryDelaySeconds
    )
    
    if ($BaseUrl) { $script:LangGraphConfig.BaseUrl = $BaseUrl }
    if ($TimeoutSeconds) { $script:LangGraphConfig.TimeoutSeconds = $TimeoutSeconds }
    if ($RetryCount) { $script:LangGraphConfig.RetryCount = $RetryCount }
    if ($RetryDelaySeconds) { $script:LangGraphConfig.RetryDelaySeconds = $RetryDelaySeconds }
    
    Write-Verbose "LangGraph configuration updated: $($script:LangGraphConfig | ConvertTo-Json)"
}

function Get-LangGraphConfig {
    <#
    .SYNOPSIS
    Retrieves the current LangGraph module configuration
    
    .DESCRIPTION
    Returns the current configuration settings for the LangGraph bridge module
    
    .EXAMPLE
    $config = Get-LangGraphConfig
    Write-Host "Current base URL: $($config.BaseUrl)"
    #>
    [CmdletBinding()]
    param()
    
    return $script:LangGraphConfig.Clone()
}

function Test-LangGraphWorkflow {
    <#
    .SYNOPSIS
    Tests a workflow end-to-end with sample data
    
    .DESCRIPTION
    Performs a complete workflow test by submitting sample data and validating the response
    
    .PARAMETER WorkflowName
    Name of the workflow to test
    
    .PARAMETER TestInput
    Test input data
    
    .EXAMPLE
    $result = Test-LangGraphWorkflow -WorkflowName "maintenance_prediction_enhancement" -TestInput @{ test = "data" }
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$WorkflowName,
        
        [Parameter()]
        [hashtable]$TestInput = @{ test_mode = $true; sample_data = "PowerShell integration test" }
    )
    
    try {
        # Test server connectivity first
        $serverStatus = Test-LangGraphServer
        if ($serverStatus.status -ne "healthy") {
            return @{
                success = $false
                error = "LangGraph server not healthy: $($serverStatus.error)"
                stage = "server_connectivity"
            }
        }
        
        # Create a simple test workflow if needed
        $workflows = Get-LangGraphWorkflows
        $existingWorkflow = $workflows | Where-Object { $_.name -eq $WorkflowName }
        
        if (-not $existingWorkflow) {
            return @{
                success = $false
                error = "Workflow '$WorkflowName' not found on server"
                stage = "workflow_lookup"
                available_workflows = ($workflows | ForEach-Object { $_.name })
            }
        }
        
        # Submit test task
        $taskId = Submit-WorkflowTask -WorkflowId $existingWorkflow.id -InputData $TestInput
        if (-not $taskId) {
            return @{
                success = $false
                error = "Failed to submit test task"
                stage = "task_submission"
            }
        }
        
        # Get result with shorter timeout for testing
        $result = Get-WorkflowResult -TaskId $taskId -PollIntervalSeconds 1 -MaxWaitSeconds 30
        
        return @{
            success = ($result -ne $null)
            workflow_name = $WorkflowName
            task_id = $taskId
            result = $result
            stage = "completed"
        }
    }
    catch {
        return @{
            success = $false
            error = $_.Exception.Message
            stage = "exception"
        }
    }
}

#endregion

#region Module Exports

Export-ModuleMember -Function @(
    'New-LangGraphWorkflow',
    'Submit-WorkflowTask', 
    'Get-WorkflowResult',
    'Test-LangGraphServer',
    'Get-LangGraphWorkflows',
    'Set-LangGraphConfig',
    'Get-LangGraphConfig',
    'Test-LangGraphWorkflow'
)

#endregion

# Module initialization
Write-Verbose "Unity-Claude-LangGraphBridge module loaded successfully"
Write-Verbose "Default LangGraph server: $($script:LangGraphConfig.BaseUrl)"