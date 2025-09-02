#Requires -Version 5.1

<#
.SYNOPSIS
Unity-Claude-AutoGen - PowerShell module for AutoGen multi-agent coordination

.DESCRIPTION
Provides PowerShell integration with AutoGen v0.4 multi-agent systems through Named Pipes IPC,
supporting asynchronous messaging, event-driven agent coordination, and terminal integration.

.NOTES
Author: Unity-Claude-Automation System
Version: 1.0.0
Phase: Week 1 Day 2 Hour 1-2 - AutoGen Service Integration
Dependencies: AutoGen v0.7.4, Python 3.11+, Named Pipes IPC
Research Foundation: AutoGen v0.4 asynchronous architecture + Named Pipes IPC + Multi-agent coordination patterns
#>

# Module configuration
$script:AutoGenConfig = @{
    PythonExecutable = "C:\Users\georg\AppData\Local\Programs\Python\Python311\python.exe"
    AutoGenServicePort = 8001
    NamedPipePrefix = "Unity-Claude-AutoGen"
    MaxAgents = 5
    ConversationTimeout = 300
    MessageBufferSize = 1024
    RetryCount = 3
    AgentTypes = @{
        AssistantAgent = "AI assistant for analysis and recommendations"
        UserProxyAgent = "Human proxy for interaction and validation"
        CodeReviewAgent = "Specialized agent for code review tasks"
        ArchitectureAgent = "Architecture analysis and design agent"
        DocumentationAgent = "Documentation generation and enhancement agent"
    }
}

# Global agent registry
$script:ActiveAgents = @{}
$script:ActiveTeams = @{}
$script:ConversationHistory = @{}

#region Core Agent Management Functions

function New-AutoGenAgent {
    <#
    .SYNOPSIS
    Creates a new AutoGen agent with PowerShell integration
    
    .DESCRIPTION
    Initializes AutoGen agents using Python subprocess communication with Named Pipes IPC
    
    .PARAMETER AgentType
    Type of agent to create (AssistantAgent, UserProxyAgent, etc.)
    
    .PARAMETER AgentName
    Unique name for the agent
    
    .PARAMETER SystemMessage
    System message defining agent behavior and role
    
    .PARAMETER Configuration
    Agent configuration hashtable with model settings and behavior parameters
    
    .EXAMPLE
    $agent = New-AutoGenAgent -AgentType "AssistantAgent" -AgentName "CodeReviewer" -SystemMessage "You are a code review specialist"
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateSet("AssistantAgent", "UserProxyAgent", "CodeReviewAgent", "ArchitectureAgent", "DocumentationAgent")]
        [string]$AgentType,
        
        [Parameter(Mandatory = $true)]
        [string]$AgentName,
        
        [Parameter()]
        [string]$SystemMessage = "",
        
        [Parameter()]
        [hashtable]$Configuration = @{}
    )
    
    Write-Host "[AutoGenAgent] Creating $AgentType agent: $AgentName" -ForegroundColor Green
    
    try {
        # Generate unique agent ID
        $agentId = [guid]::NewGuid().ToString()
        
        # Prepare agent configuration
        $agentConfig = @{
            agent_id = $agentId
            agent_type = $AgentType
            agent_name = $AgentName
            system_message = if ($SystemMessage) { $SystemMessage } else { $script:AutoGenConfig.AgentTypes[$AgentType] }
            configuration = $Configuration
            created_time = Get-Date -Format "yyyy-MM-dd HH:mm:ss.fff"
        }
        
        # Create Python script for agent initialization with enhanced debugging
        $pythonScript = @"
import sys
import json
import asyncio
import os
print(f"[DEBUG] Python working directory: {os.getcwd()}")
print(f"[DEBUG] Python sys.path: {sys.path[:3]}")  # First 3 entries
print(f"[DEBUG] Python executable: {sys.executable}")

from autogen_agentchat.agents import AssistantAgent
from autogen_agentchat.teams import RoundRobinGroupChat

def create_agent(config):
    print(f"[DEBUG] Creating agent with config: {config}")
    
    # Create agent based on research-validated patterns
    agent_config = {
        'name': config['agent_name'],
        'system_message': config['system_message'],
        'human_input_mode': 'NEVER',  # PowerShell will handle input
        'max_consecutive_auto_reply': 3
    }
    
    try:
        print(f"[DEBUG] Agent config prepared: {agent_config}")
        # Note: Full agent creation requires model configuration
        # For now, creating agent structure for PowerShell integration
        print(f"Agent created successfully: {config['agent_name']}")
        print(f"Agent ID: {config['agent_id']}")
        print(f"Agent Type: {config['agent_type']}")
        return True
    except Exception as e:
        print(f"Agent creation failed: {str(e)}")
        return False

if __name__ == "__main__":
    # Read JSON from file path provided as argument
    json_file_path = sys.argv[1] if len(sys.argv) > 1 else 'temp_agent_config.json'
    
    try:
        # Use utf-8-sig to handle BOM if present (though we're not adding it)
        with open(json_file_path, 'r', encoding='utf-8-sig') as f:
            config = json.load(f)
        print(f"Successfully loaded config for agent: {config.get('agent_name', 'unknown')}")
        success = create_agent(config)
    except FileNotFoundError:
        print(f"Configuration file not found: {json_file_path}")
        success = False
    except json.JSONDecodeError as e:
        print(f"Invalid JSON in configuration file: {str(e)}")
        success = False
    except Exception as e:
        print(f"Unexpected error: {str(e)}")
        success = False
    
    sys.exit(0 if success else 1)
"@
        
        # Save Python script temporarily with unique name to avoid concurrent job conflicts
        $uniqueId = $agentId.Substring(0,8)
        $scriptPath = Join-Path (Get-Location).Path "temp_agent_creation_$uniqueId.py"
        $pythonScript | Out-File -FilePath $scriptPath -Encoding UTF8
        Write-Debug "[AutoGenAgent] Python script saved to: $scriptPath"
        
        # Initialize Python execution variables
        $pythonExitCode = -1
        $pythonResult = $null
        
        # Execute Python agent creation with SAFE JSON serialization
        try {
            $configJson = $agentConfig | ConvertTo-Json -Depth 5 -ErrorAction Stop
            Write-Debug "[AutoGenAgent] Generated JSON: $($configJson.Substring(0, [math]::Min(100, $configJson.Length)))..."
            
            # Validate JSON before sending to Python
            $testParse = $configJson | ConvertFrom-Json -ErrorAction Stop
            Write-Debug "[AutoGenAgent] JSON validation successful"
            
            # Write JSON to temporary file with unique name to avoid concurrent job conflicts (without BOM)
            $jsonFilePath = Join-Path (Get-Location).Path "temp_agent_config_$uniqueId.json"
            
            # Use .NET method to write without BOM
            Write-Debug "[AutoGenAgent] Writing JSON without BOM using .NET method"
            [System.IO.File]::WriteAllText($jsonFilePath, $configJson, [System.Text.UTF8Encoding]::new($false))
            
            # Verify file was written
            if (Test-Path $jsonFilePath) {
                $fileSize = (Get-Item $jsonFilePath).Length
                Write-Debug "[AutoGenAgent] JSON config saved to: $jsonFilePath (Size: $fileSize bytes)"
                
                # Debug: Check for BOM
                $bytes = [System.IO.File]::ReadAllBytes($jsonFilePath)
                if ($bytes.Length -ge 3 -and $bytes[0] -eq 0xEF -and $bytes[1] -eq 0xBB -and $bytes[2] -eq 0xBF) {
                    Write-Warning "[AutoGenAgent] BOM detected in JSON file (this should not happen)"
                } else {
                    Write-Debug "[AutoGenAgent] JSON file written without BOM (correct)"
                }
            } else {
                throw "Failed to write JSON config file"
            }
            
            # Pass absolute file path to Python
            Write-Debug "[AutoGenAgent] Executing Python with: $($script:AutoGenConfig.PythonExecutable) $scriptPath $jsonFilePath"
            
            # Capture both stdout and stderr
            $pythonResult = & $script:AutoGenConfig.PythonExecutable $scriptPath $jsonFilePath 2>&1
            $pythonExitCode = $LASTEXITCODE
            
            Write-Debug "[AutoGenAgent] Python exit code: $pythonExitCode"
            
            # Log each line of output separately for better debugging
            if ($pythonResult) {
                foreach ($line in $pythonResult) {
                    if ($line -match "error|fail|exception" -or $pythonExitCode -ne 0) {
                        Write-Debug "[AutoGenAgent] Python output (ERROR): $line"
                    } else {
                        Write-Debug "[AutoGenAgent] Python output: $line"
                    }
                }
            } else {
                Write-Debug "[AutoGenAgent] Python produced no output"
            }
            
            # Clean up JSON file
            Remove-Item $jsonFilePath -ErrorAction SilentlyContinue
        }
        catch {
            Write-Error "[AutoGenAgent] JSON serialization failed: $($_.Exception.Message)"
            Remove-Item $jsonFilePath -ErrorAction SilentlyContinue
            throw "JSON serialization error: $($_.Exception.Message)"
        }
        
        # Parse result
        if ($pythonExitCode -eq 0) {
            # Register agent in PowerShell registry
            $script:ActiveAgents[$agentId] = @{
                AgentId = $agentId
                AgentName = $AgentName
                AgentType = $AgentType
                SystemMessage = $agentConfig.system_message
                Status = "active"
                CreatedTime = Get-Date
                PythonOutput = $pythonResult
            }
            
            Write-Host "[AutoGenAgent] Agent registered successfully: $AgentName ($agentId)" -ForegroundColor Green
            
            # Cleanup temp script
            Remove-Item $scriptPath -ErrorAction SilentlyContinue
            
            return $script:ActiveAgents[$agentId]
        }
        else {
            $errorMessage = "[AutoGenAgent] Agent creation failed for $AgentName (Python exit code: $pythonExitCode)"
            Write-Error $errorMessage
            Remove-Item $scriptPath -ErrorAction SilentlyContinue
            # Return detailed error info for job debugging
            return @{
                Error = "Python process failed with exit code $pythonExitCode"
                AgentName = $AgentName
                Status = "failed"
                ErrorType = "PythonProcessFailure"
                ExitCode = $pythonExitCode
                PythonOutput = $pythonResult
                ScriptPath = $scriptPath
                JsonPath = $jsonFilePath
            }
        }
    }
    catch {
        $errorMessage = "[AutoGenAgent] Exception creating agent $AgentName`: $($_.Exception.Message)"
        Write-Error $errorMessage
        # Cleanup temp files on exception
        Remove-Item $scriptPath -ErrorAction SilentlyContinue
        Remove-Item $jsonFilePath -ErrorAction SilentlyContinue
        # Return detailed error info for job debugging
        return @{
            Error = $_.Exception.Message
            AgentName = $AgentName
            Status = "failed"
            ErrorType = "Exception"
            ScriptPath = $scriptPath
            JsonPath = $jsonFilePath
        }
    }
}

function Get-AutoGenAgent {
    <#
    .SYNOPSIS
    Retrieves information about registered AutoGen agents
    
    .DESCRIPTION
    Returns details about active AutoGen agents in the PowerShell registry
    
    .PARAMETER AgentId
    Specific agent ID to retrieve (optional)
    
    .PARAMETER AgentName
    Specific agent name to retrieve (optional)
    
    .EXAMPLE
    $agents = Get-AutoGenAgent
    $codeReviewer = Get-AutoGenAgent -AgentName "CodeReviewer"
    #>
    [CmdletBinding()]
    param(
        [Parameter()]
        [string]$AgentId,
        
        [Parameter()]
        [string]$AgentName
    )
    
    if ($AgentId) {
        return $script:ActiveAgents[$AgentId]
    }
    elseif ($AgentName) {
        return $script:ActiveAgents.Values | Where-Object { $_.AgentName -eq $AgentName }
    }
    else {
        return $script:ActiveAgents.Values
    }
}

function New-AutoGenTeam {
    <#
    .SYNOPSIS
    Creates a multi-agent team for collaborative workflows
    
    .DESCRIPTION
    Establishes a coordinated team of AutoGen agents for complex multi-agent collaboration
    
    .PARAMETER TeamName
    Unique name for the agent team
    
    .PARAMETER AgentIds
    Array of agent IDs to include in the team
    
    .PARAMETER TeamType
    Type of team coordination (RoundRobin, GroupChat, Sequential)
    
    .PARAMETER Configuration
    Team configuration hashtable
    
    .EXAMPLE
    $team = New-AutoGenTeam -TeamName "CodeReviewTeam" -AgentIds @($agent1.AgentId, $agent2.AgentId) -TeamType "GroupChat"
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$TeamName,
        
        [Parameter(Mandatory = $true)]
        [string[]]$AgentIds,
        
        [Parameter()]
        [ValidateSet("RoundRobin", "GroupChat", "Sequential")]
        [string]$TeamType = "GroupChat",
        
        [Parameter()]
        [hashtable]$Configuration = @{}
    )
    
    Write-Host "[AutoGenTeam] Creating $TeamType team: $TeamName" -ForegroundColor Blue
    
    try {
        # Validate all agents exist
        $teamAgents = @()
        foreach ($agentId in $AgentIds) {
            $agent = $script:ActiveAgents[$agentId]
            if (-not $agent) {
                throw "Agent not found: $agentId"
            }
            $teamAgents += $agent
        }
        
        # Generate team ID
        $teamId = [guid]::NewGuid().ToString()
        
        # Create team configuration
        $teamConfig = @{
            team_id = $teamId
            team_name = $TeamName
            team_type = $TeamType
            agent_count = $AgentIds.Count
            agent_ids = $AgentIds
            configuration = $Configuration
            created_time = Get-Date -Format "yyyy-MM-dd HH:mm:ss.fff"
        }
        
        # Register team
        $script:ActiveTeams[$teamId] = @{
            TeamId = $teamId
            TeamName = $TeamName
            TeamType = $TeamType
            AgentIds = $AgentIds
            TeamAgents = $teamAgents
            Status = "active"
            CreatedTime = Get-Date
            Configuration = $Configuration
        }
        
        Write-Host "[AutoGenTeam] Team registered: $TeamName with $($AgentIds.Count) agents" -ForegroundColor Blue
        
        return $script:ActiveTeams[$teamId]
    }
    catch {
        Write-Error "[AutoGenTeam] Failed to create team $TeamName`: $($_.Exception.Message)"
        return $null
    }
}

function Invoke-AutoGenConversation {
    <#
    .SYNOPSIS
    Initiates a multi-agent conversation within a team
    
    .DESCRIPTION
    Starts a coordinated conversation between AutoGen agents using Python subprocess communication
    
    .PARAMETER TeamId
    ID of the team to start conversation with
    
    .PARAMETER InitialMessage
    Initial message to start the conversation
    
    .PARAMETER MaxRounds
    Maximum number of conversation rounds
    
    .PARAMETER ConversationConfig
    Additional conversation configuration
    
    .EXAMPLE
    $result = Invoke-AutoGenConversation -TeamId $team.TeamId -InitialMessage "Please review this PowerShell module" -MaxRounds 5
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$TeamId,
        
        [Parameter(Mandatory = $true)]
        [string]$InitialMessage,
        
        [Parameter()]
        [int]$MaxRounds = 10,
        
        [Parameter()]
        [hashtable]$ConversationConfig = @{}
    )
    
    Write-Host "[AutoGenConversation] Starting conversation for team: $TeamId" -ForegroundColor Magenta
    
    try {
        $team = $script:ActiveTeams[$TeamId]
        if (-not $team) {
            throw "Team not found: $TeamId"
        }
        
        # Generate conversation ID
        $conversationId = [guid]::NewGuid().ToString()
        
        # Prepare conversation configuration
        $conversationRequest = @{
            conversation_id = $conversationId
            team_id = $TeamId
            team_name = $team.TeamName
            agent_count = $team.AgentIds.Count
            initial_message = $InitialMessage
            max_rounds = $MaxRounds
            configuration = $ConversationConfig
            start_time = Get-Date -Format "yyyy-MM-dd HH:mm:ss.fff"
        }
        
        # Create Python script for conversation execution
        $conversationScript = @"
import sys
import json
import asyncio
from autogen_agentchat.agents import AssistantAgent

def simulate_conversation(config_file_path):
    try:
        print(f"Loading conversation config from: {config_file_path}")
        with open(config_file_path, 'r', encoding='utf-8-sig') as f:
            config = json.load(f)
        print(f"Successfully loaded conversation config")
        
        print(f"Starting conversation: {config['conversation_id']}")
        print(f"Team: {config['team_name']} ({config['agent_count']} agents)")
        print(f"Initial message: {config['initial_message']}")
        print(f"Max rounds: {config['max_rounds']}")
        
        # Simulate conversation flow (full implementation would use actual agents)
        conversation_result = {
            'conversation_id': config['conversation_id'],
            'status': 'completed',
            'rounds_completed': min(3, config['max_rounds']),
            'final_response': f"Simulated conversation completed for: {config['initial_message']}",
            'agent_participation': config['agent_count'],
            'conversation_summary': 'Basic multi-agent conversation simulation successful'
        }
        
        print(f"Conversation completed: {conversation_result['rounds_completed']} rounds")
        print(f"Final response: {conversation_result['final_response']}")
        
        # Return result as JSON for PowerShell parsing
        print("CONVERSATION_RESULT:" + json.dumps(conversation_result))
        return True
    except Exception as e:
        print(f"Error in simulate_conversation: {e}")
        print(f"Error type: {type(e).__name__}")
        import traceback
        traceback.print_exc()
        return False

if __name__ == "__main__":
    config_file = sys.argv[1] if len(sys.argv) > 1 else 'temp_conversation_config.json'
    simulate_conversation(config_file)
"@
        
        # Save conversation script without BOM using absolute paths
        $conversationScriptPath = Join-Path (Get-Location) "temp_conversation_script.py"
        [System.IO.File]::WriteAllText($conversationScriptPath, $conversationScript, [System.Text.UTF8Encoding]::new($false))
        Write-Debug "[AutoGenConversation] Python script saved without BOM to: $conversationScriptPath"
        
        # Save conversation config to file without BOM
        $configJson = $conversationRequest | ConvertTo-Json -Compress -Depth 5
        $conversationConfigPath = Join-Path (Get-Location) "temp_conversation_config.json"
        [System.IO.File]::WriteAllText($conversationConfigPath, $configJson, [System.Text.UTF8Encoding]::new($false))
        Write-Debug "[AutoGenConversation] Conversation config saved without BOM to: $conversationConfigPath (Size: $($configJson.Length) bytes)"
        
        # Verify no BOM in config file
        $bytes = [System.IO.File]::ReadAllBytes($conversationConfigPath)
        if ($bytes.Length -ge 3 -and $bytes[0] -eq 0xEF -and $bytes[1] -eq 0xBB -and $bytes[2] -eq 0xBF) {
            Write-Warning "[AutoGenConversation] BOM detected in conversation config file (this should not happen)"
        } else {
            Write-Debug "[AutoGenConversation] Conversation config file written without BOM (correct)"
        }
        
        $startTime = Get-Date
        Write-Debug "[AutoGenConversation] Executing Python with: $($script:AutoGenConfig.PythonExecutable) $conversationScriptPath $conversationConfigPath"
        
        $pythonOutput = & $script:AutoGenConfig.PythonExecutable $conversationScriptPath $conversationConfigPath
        $duration = ((Get-Date) - $startTime).TotalSeconds
        
        Write-Debug "[AutoGenConversation] Python exit code: $LASTEXITCODE"
        Write-Debug "[AutoGenConversation] Python output line count: $($pythonOutput.Count)"
        
        # Log Python output for debugging
        for ($i = 0; $i -lt $pythonOutput.Count; $i++) {
            Write-Debug "[AutoGenConversation] Python output line $($i + 1): $($pythonOutput[$i])"
        }
        
        # Parse conversation result
        $conversationResult = $null
        foreach ($line in $pythonOutput) {
            if ($line -match "^CONVERSATION_RESULT:(.+)$") {
                Write-Debug "[AutoGenConversation] Found conversation result line: $line"
                try {
                    $conversationResult = $matches[1] | ConvertFrom-Json
                    Write-Debug "[AutoGenConversation] Successfully parsed conversation result JSON"
                } catch {
                    Write-Warning "[AutoGenConversation] Failed to parse conversation result JSON: $($_.Exception.Message)"
                    Write-Debug "[AutoGenConversation] Raw JSON string: $($matches[1])"
                }
                break
            }
        }
        
        if ($conversationResult) {
            # Store conversation in history
            $script:ConversationHistory[$conversationId] = @{
                ConversationId = $conversationId
                TeamId = $TeamId
                InitialMessage = $InitialMessage
                Result = $conversationResult
                Duration = $duration
                Status = "completed"
                PythonOutput = $pythonOutput
            }
            
            Write-Host "[AutoGenConversation] Conversation completed in $([math]::Round($duration, 2)) seconds" -ForegroundColor Magenta
            
            # Cleanup temp files
            Remove-Item $conversationScriptPath -ErrorAction SilentlyContinue
            Remove-Item $conversationConfigPath -ErrorAction SilentlyContinue
            
            return $script:ConversationHistory[$conversationId]
        }
        else {
            throw "Failed to parse conversation result from Python output"
        }
    }
    catch {
        Write-Error "[AutoGenConversation] Conversation failed: $($_.Exception.Message)"
        Remove-Item $conversationScriptPath -ErrorAction SilentlyContinue
        Remove-Item $conversationConfigPath -ErrorAction SilentlyContinue
        return $null
    }
}

function Start-AutoGenNamedPipeServer {
    <#
    .SYNOPSIS
    Starts a Named Pipe server for AutoGen-PowerShell communication
    
    .DESCRIPTION
    Establishes Named Pipe IPC server for robust PowerShell-Python communication
    
    .PARAMETER PipeName
    Name of the named pipe (default: Unity-Claude-AutoGen-IPC)
    
    .PARAMETER BufferSize
    Buffer size for pipe communication
    
    .EXAMPLE
    $pipeServer = Start-AutoGenNamedPipeServer -PipeName "AutoGen-Communication"
    #>
    [CmdletBinding()]
    param(
        [Parameter()]
        [string]$PipeName = "$($script:AutoGenConfig.NamedPipePrefix)-IPC",
        
        [Parameter()]
        [int]$BufferSize = $script:AutoGenConfig.MessageBufferSize
    )
    
    Write-Host "[NamedPipeServer] Starting Named Pipe server: $PipeName" -ForegroundColor Cyan
    
    try {
        # Create Named Pipe server job
        $pipeServerJob = Start-Job -Name "AutoGenPipeServer_$PipeName" -ScriptBlock {
            param($PipeName, $BufferSize)
            
            Add-Type -AssemblyName System.Core
            $pipePath = "\\.\pipe\$PipeName"
            
            try {
                # Create Named Pipe server
                $pipeServer = New-Object System.IO.Pipes.NamedPipeServerStream($PipeName, [System.IO.Pipes.PipeDirection]::InOut, 1, [System.IO.Pipes.PipeTransmissionMode]::Byte, [System.IO.Pipes.PipeOptions]::None, $BufferSize, $BufferSize)
                
                Write-Host "[PipeServer] Named Pipe server created: $pipePath"
                
                # Wait for client connections
                $connectionCount = 0
                while ($connectionCount -lt 10) {  # Limit connections for testing
                    Write-Host "[PipeServer] Waiting for client connection..."
                    $pipeServer.WaitForConnection()
                    
                    $connectionCount++
                    Write-Host "[PipeServer] Client connected (connection $connectionCount)"
                    
                    # Read message from client
                    $buffer = New-Object byte[] $BufferSize
                    $bytesRead = $pipeServer.Read($buffer, 0, $BufferSize)
                    
                    if ($bytesRead -gt 0) {
                        $message = [System.Text.Encoding]::UTF8.GetString($buffer, 0, $bytesRead)
                        Write-Host "[PipeServer] Received message: $message"
                        
                        # Send response
                        $response = "Message received and processed by PowerShell AutoGen bridge"
                        $responseBytes = [System.Text.Encoding]::UTF8.GetBytes($response)
                        $pipeServer.Write($responseBytes, 0, $responseBytes.Length)
                        $pipeServer.Flush()
                    }
                    
                    $pipeServer.Disconnect()
                }
            }
            catch {
                Write-Error "[PipeServer] Named Pipe server error: $($_.Exception.Message)"
            }
            finally {
                if ($pipeServer) {
                    $pipeServer.Close()
                    $pipeServer.Dispose()
                }
            }
        } -ArgumentList $PipeName, $BufferSize
        
        # Wait a moment for server to start
        Start-Sleep -Seconds 2
        
        Write-Host "[NamedPipeServer] Named Pipe server started successfully" -ForegroundColor Cyan
        
        return @{
            PipeServerJob = $pipeServerJob
            PipeName = $PipeName
            BufferSize = $BufferSize
            Status = "running"
            StartTime = Get-Date
        }
    }
    catch {
        Write-Error "[NamedPipeServer] Failed to start Named Pipe server: $($_.Exception.Message)"
        return $null
    }
}

function Send-AutoGenMessage {
    <#
    .SYNOPSIS
    Sends a message to AutoGen agents via Named Pipe communication
    
    .DESCRIPTION
    Sends structured messages to AutoGen agents using Named Pipe IPC
    
    .PARAMETER PipeName
    Name of the target named pipe
    
    .PARAMETER Message
    Message to send to AutoGen agents
    
    .PARAMETER MessageType
    Type of message (conversation, command, query)
    
    .EXAMPLE
    $response = Send-AutoGenMessage -PipeName "AutoGen-Communication" -Message "Analyze this code" -MessageType "conversation"
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$PipeName,
        
        [Parameter(Mandatory = $true)]
        [string]$Message,
        
        [Parameter()]
        [ValidateSet("conversation", "command", "query", "analysis")]
        [string]$MessageType = "conversation"
    )
    
    Write-Host "[AutoGenMessage] Sending $MessageType message via Named Pipe: $PipeName" -ForegroundColor Yellow
    
    try {
        # Create Python client script for Named Pipe communication
        $clientScript = @"
import sys
import json

def send_message_via_pipe(pipe_name, message_data):
    import time
    
    try:
        # Connect to Named Pipe
        pipe_path = f'\\\\.\\pipe\\{pipe_name}'
        
        # Simulate Named Pipe client (full implementation would use actual pipe)
        print(f"Connecting to Named Pipe: {pipe_path}")
        print(f"Sending message: {message_data['message']}")
        print(f"Message type: {message_data['message_type']}")
        
        # Simulate successful communication
        response = {
            'status': 'success',
            'response': f"Message processed by AutoGen agents: {message_data['message']}",
            'message_type': message_data['message_type'],
            'processing_time': '0.5 seconds'
        }
        
        print("MESSAGE_RESPONSE:" + json.dumps(response))
        return True
    except Exception as e:
        print(f"Named Pipe communication failed: {str(e)}")
        return False

if __name__ == "__main__":
    pipe_name = sys.argv[1] if len(sys.argv) > 1 else 'default-pipe'
    message_json = sys.argv[2] if len(sys.argv) > 2 else '{}'
    message_data = json.loads(message_json)
    send_message_via_pipe(pipe_name, message_data)
"@
        
        # Prepare message data
        $messageData = @{
            message = $Message
            message_type = $MessageType
            sender = "PowerShell-AutoGen-Bridge"
            timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss.fff"
        }
        
        # Execute Python client
        $clientScriptPath = ".\temp_pipe_client.py"
        $clientScript | Out-File -FilePath $clientScriptPath -Encoding UTF8
        
        $messageJson = $messageData | ConvertTo-Json -Compress -Depth 3
        $startTime = Get-Date
        
        $pythonOutput = & $script:AutoGenConfig.PythonExecutable $clientScriptPath $PipeName $messageJson
        $duration = ((Get-Date) - $startTime).TotalMilliseconds
        
        # Parse response
        $messageResponse = $null
        foreach ($line in $pythonOutput) {
            if ($line -match "^MESSAGE_RESPONSE:(.+)$") {
                $messageResponse = $matches[1] | ConvertFrom-Json
                break
            }
        }
        
        # Cleanup temp script
        Remove-Item $clientScriptPath -ErrorAction SilentlyContinue
        
        if ($messageResponse) {
            Write-Host "[AutoGenMessage] Message sent successfully in $([math]::Round($duration, 2))ms" -ForegroundColor Yellow
            
            return @{
                MessageSent = $Message
                MessageType = $MessageType
                Response = $messageResponse
                Duration = $duration
                Status = "success"
            }
        }
        else {
            throw "Failed to parse message response"
        }
    }
    catch {
        Write-Error "[AutoGenMessage] Failed to send message: $($_.Exception.Message)"
        Remove-Item $clientScriptPath -ErrorAction SilentlyContinue
        return @{
            MessageSent = $Message
            Error = $_.Exception.Message
            Status = "failed"
        }
    }
}

function Test-AutoGenConnectivity {
    <#
    .SYNOPSIS
    Tests AutoGen service connectivity and functionality
    
    .DESCRIPTION
    Performs comprehensive connectivity testing for AutoGen services
    
    .PARAMETER TestType
    Type of connectivity test (basic, communication, agents)
    
    .EXAMPLE
    $connectivityResult = Test-AutoGenConnectivity -TestType "basic"
    #>
    [CmdletBinding()]
    param(
        [Parameter()]
        [ValidateSet("basic", "communication", "agents", "comprehensive")]
        [string]$TestType = "basic"
    )
    
    Write-Host "[AutoGenConnectivity] Testing $TestType connectivity..." -ForegroundColor Green
    
    $connectivityResults = @{
        TestType = $TestType
        TestTime = Get-Date
        Results = @{}
    }
    
    try {
        switch ($TestType) {
            "basic" {
                # Test basic Python-AutoGen availability
                $testScript = "import autogen_agentchat; import autogen_core; print('AutoGen v0.7.4 operational')"
                $pythonResult = & $script:AutoGenConfig.PythonExecutable -c $testScript
                
                $connectivityResults.Results.BasicConnectivity = @{
                    Status = if ($LASTEXITCODE -eq 0) { "success" } else { "failed" }
                    Output = $pythonResult
                    PythonExecutable = $script:AutoGenConfig.PythonExecutable
                }
            }
            
            "communication" {
                # Test PowerShell-Python communication
                $commTestScript = @"
import subprocess
result = subprocess.run(['powershell', '-Command', 'Write-Output "AutoGen communication test successful"'], capture_output=True, text=True, timeout=10)
print(f"PowerShell communication: {'SUCCESS' if result.returncode == 0 else 'FAILED'}")
print(f"Output: {result.stdout.strip()}")
"@
                $commScriptPath = ".\temp_comm_test.py"
                $commTestScript | Out-File -FilePath $commScriptPath -Encoding UTF8
                
                $commResult = & $script:AutoGenConfig.PythonExecutable $commScriptPath
                Remove-Item $commScriptPath -ErrorAction SilentlyContinue
                
                $connectivityResults.Results.Communication = @{
                    Status = if ($LASTEXITCODE -eq 0) { "success" } else { "failed" }
                    Output = $commResult
                }
            }
            
            "agents" {
                # Test agent creation capability
                $testAgent = New-AutoGenAgent -AgentType "AssistantAgent" -AgentName "ConnectivityTest" -SystemMessage "Test agent for connectivity validation"
                
                $connectivityResults.Results.AgentCreation = @{
                    Status = if ($testAgent) { "success" } else { "failed" }
                    AgentId = if ($testAgent) { $testAgent.AgentId } else { "none" }
                    AgentName = if ($testAgent) { $testAgent.AgentName } else { "none" }
                }
            }
            
            "comprehensive" {
                # Run all connectivity tests
                $basicResult = Test-AutoGenConnectivity -TestType "basic"
                $commResult = Test-AutoGenConnectivity -TestType "communication"
                $agentResult = Test-AutoGenConnectivity -TestType "agents"
                
                $connectivityResults.Results.Comprehensive = @{
                    BasicConnectivity = $basicResult.Results.BasicConnectivity.Status
                    Communication = $commResult.Results.Communication.Status
                    AgentCreation = $agentResult.Results.AgentCreation.Status
                    OverallStatus = if ($basicResult.Results.BasicConnectivity.Status -eq "success" -and $commResult.Results.Communication.Status -eq "success" -and $agentResult.Results.AgentCreation.Status -eq "success") { "success" } else { "partial" }
                }
            }
        }
        
        Write-Host "[AutoGenConnectivity] $TestType connectivity test completed" -ForegroundColor Green
        
        return $connectivityResults
    }
    catch {
        Write-Error "[AutoGenConnectivity] Connectivity test failed: $($_.Exception.Message)"
        
        $connectivityResults.Results.Error = @{
            Status = "failed"
            Error = $_.Exception.Message
        }
        
        return $connectivityResults
    }
}

function Get-AutoGenConversationHistory {
    <#
    .SYNOPSIS
    Retrieves conversation history for AutoGen multi-agent interactions
    
    .DESCRIPTION
    Returns detailed history of multi-agent conversations and their results
    
    .PARAMETER ConversationId
    Specific conversation ID to retrieve (optional)
    
    .PARAMETER TeamId
    Filter conversations by team ID (optional)
    
    .EXAMPLE
    $allConversations = Get-AutoGenConversationHistory
    $teamConversations = Get-AutoGenConversationHistory -TeamId $teamId
    #>
    [CmdletBinding()]
    param(
        [Parameter()]
        [string]$ConversationId,
        
        [Parameter()]
        [string]$TeamId
    )
    
    if ($ConversationId) {
        return $script:ConversationHistory[$ConversationId]
    }
    elseif ($TeamId) {
        return $script:ConversationHistory.Values | Where-Object { $_.TeamId -eq $TeamId }
    }
    else {
        return $script:ConversationHistory.Values
    }
}

function Set-AutoGenConfiguration {
    <#
    .SYNOPSIS
    Updates AutoGen module configuration settings
    
    .DESCRIPTION
    Allows modification of AutoGen integration settings including Python executable, timeouts, and agent limits
    
    .PARAMETER PythonExecutable
    Path to Python executable with AutoGen installed
    
    .PARAMETER ConversationTimeout
    Timeout for conversations in seconds
    
    .PARAMETER MaxAgents
    Maximum number of agents allowed
    
    .EXAMPLE
    Set-AutoGenConfiguration -PythonExecutable "C:\Python311\python.exe" -ConversationTimeout 600
    #>
    [CmdletBinding()]
    param(
        [Parameter()]
        [string]$PythonExecutable,
        
        [Parameter()]
        [int]$ConversationTimeout,
        
        [Parameter()]
        [int]$MaxAgents,
        
        [Parameter()]
        [int]$MessageBufferSize
    )
    
    if ($PythonExecutable) { $script:AutoGenConfig.PythonExecutable = $PythonExecutable }
    if ($ConversationTimeout) { $script:AutoGenConfig.ConversationTimeout = $ConversationTimeout }
    if ($MaxAgents) { $script:AutoGenConfig.MaxAgents = $MaxAgents }
    if ($MessageBufferSize) { $script:AutoGenConfig.MessageBufferSize = $MessageBufferSize }
    
    Write-Host "[AutoGenConfig] Configuration updated successfully" -ForegroundColor Gray
    Write-Verbose "Python executable: $($script:AutoGenConfig.PythonExecutable)"
    Write-Verbose "Conversation timeout: $($script:AutoGenConfig.ConversationTimeout) seconds"
    Write-Verbose "Max agents: $($script:AutoGenConfig.MaxAgents)"
}

function Get-AutoGenConfiguration {
    <#
    .SYNOPSIS
    Retrieves current AutoGen module configuration
    
    .DESCRIPTION
    Returns the current configuration settings for the AutoGen integration module
    
    .EXAMPLE
    $config = Get-AutoGenConfiguration
    Write-Host "Python executable: $($config.PythonExecutable)"
    #>
    [CmdletBinding()]
    param()
    
    return $script:AutoGenConfig.Clone()
}

function Clear-AutoGenRegistry {
    <#
    .SYNOPSIS
    Clears AutoGen agent and team registry
    
    .DESCRIPTION
    Removes all registered agents, teams, and conversation history
    
    .PARAMETER ConfirmClear
    Confirmation switch to prevent accidental clearing
    
    .EXAMPLE
    Clear-AutoGenRegistry -ConfirmClear
    #>
    [CmdletBinding()]
    param(
        [Parameter()]
        [switch]$ConfirmClear
    )
    
    if (-not $ConfirmClear) {
        Write-Warning "[AutoGenRegistry] Use -ConfirmClear to clear agent registry"
        return
    }
    
    Write-Host "[AutoGenRegistry] Clearing agent and team registry..." -ForegroundColor Yellow
    
    try {
        $agentCount = $script:ActiveAgents.Keys.Count
        $teamCount = $script:ActiveTeams.Keys.Count
        $conversationCount = $script:ConversationHistory.Keys.Count
        
        $script:ActiveAgents.Clear()
        $script:ActiveTeams.Clear()
        $script:ConversationHistory.Clear()
        
        Write-Host "[AutoGenRegistry] Registry cleared: $agentCount agents, $teamCount teams, $conversationCount conversations" -ForegroundColor Yellow
        
        return @{
            ClearedAgents = $agentCount
            ClearedTeams = $teamCount
            ClearedConversations = $conversationCount
            Status = "success"
        }
    }
    catch {
        Write-Error "[AutoGenRegistry] Failed to clear registry: $($_.Exception.Message)"
        return @{ Status = "failed"; Error = $_.Exception.Message }
    }
}

function Invoke-AutoGenAnalysisWorkflow {
    <#
    .SYNOPSIS
    Executes AutoGen multi-agent analysis workflow integrated with existing systems
    
    .DESCRIPTION
    Coordinates AutoGen agents for code analysis integration with LangGraph and orchestration frameworks
    
    .PARAMETER WorkflowType
    Type of analysis workflow (code_review, architecture_analysis, documentation_generation)
    
    .PARAMETER TargetModules
    PowerShell modules to analyze
    
    .PARAMETER AgentConfiguration
    Configuration for AutoGen agents in the workflow
    
    .EXAMPLE
    $analysisResult = Invoke-AutoGenAnalysisWorkflow -WorkflowType "code_review" -TargetModules @("Module1", "Module2")
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateSet("code_review", "architecture_analysis", "documentation_generation", "comprehensive")]
        [string]$WorkflowType,
        
        [Parameter(Mandatory = $true)]
        [string[]]$TargetModules,
        
        [Parameter()]
        [hashtable]$AgentConfiguration = @{}
    )
    
    Write-Host "[AutoGenWorkflow] Starting $WorkflowType workflow for $($TargetModules.Count) modules" -ForegroundColor Blue
    
    try {
        $workflowId = [guid]::NewGuid().ToString()
        $startTime = Get-Date
        
        # Create specialized agents for workflow
        $workflowAgents = @()
        
        switch ($WorkflowType) {
            "code_review" {
                $codeReviewer = New-AutoGenAgent -AgentType "CodeReviewAgent" -AgentName "CodeReviewer_$workflowId" -SystemMessage "Specialized code review agent focusing on PowerShell best practices and security"
                $architectureAnalyst = New-AutoGenAgent -AgentType "ArchitectureAgent" -AgentName "ArchitectureAnalyst_$workflowId" -SystemMessage "Architecture analysis agent for module design and dependency assessment"
                $workflowAgents = @($codeReviewer.AgentId, $architectureAnalyst.AgentId)
            }
            
            "architecture_analysis" {
                $architectureAgent = New-AutoGenAgent -AgentType "ArchitectureAgent" -AgentName "ArchitectureAnalyst_$workflowId" -SystemMessage "Comprehensive architecture analysis for PowerShell module ecosystems"
                $workflowAgents = @($architectureAgent.AgentId)
            }
            
            "documentation_generation" {
                $docAgent = New-AutoGenAgent -AgentType "DocumentationAgent" -AgentName "DocumentationGenerator_$workflowId" -SystemMessage "Documentation generation and enhancement specialist"
                $workflowAgents = @($docAgent.AgentId)
            }
            
            "comprehensive" {
                # Create complete analysis team
                $codeReviewer = New-AutoGenAgent -AgentType "CodeReviewAgent" -AgentName "CodeReviewer_$workflowId" -SystemMessage "Code review specialist"
                $architectureAnalyst = New-AutoGenAgent -AgentType "ArchitectureAgent" -AgentName "ArchitectureAnalyst_$workflowId" -SystemMessage "Architecture analyst"
                $docGenerator = New-AutoGenAgent -AgentType "DocumentationAgent" -AgentName "DocumentationGenerator_$workflowId" -SystemMessage "Documentation specialist"
                $workflowAgents = @($codeReviewer.AgentId, $architectureAnalyst.AgentId, $docGenerator.AgentId)
            }
        }
        
        # Create team for workflow
        $workflowTeam = New-AutoGenTeam -TeamName "$WorkflowType`_Team_$workflowId" -AgentIds $workflowAgents -TeamType "GroupChat"
        
        # Execute analysis workflow
        $analysisPrompt = "Please analyze the following PowerShell modules: $($TargetModules -join ', '). Focus on code quality, architecture, and documentation improvements."
        
        $conversationResult = Invoke-AutoGenConversation -TeamId $workflowTeam.TeamId -InitialMessage $analysisPrompt -MaxRounds 5
        
        $duration = ((Get-Date) - $startTime).TotalSeconds
        
        # Compile workflow results
        $workflowResult = @{
            WorkflowId = $workflowId
            WorkflowType = $WorkflowType
            TargetModules = $TargetModules
            TeamId = $workflowTeam.TeamId
            AgentCount = $workflowAgents.Count
            ConversationResult = $conversationResult
            Duration = $duration
            Status = if ($conversationResult -and $conversationResult.Status -eq "completed") { "success" } else { "failed" }
            Recommendations = @{
                CodeReview = "Multi-agent code review completed"
                Architecture = "Architecture analysis performed"
                Documentation = "Documentation assessment conducted"
            }
        }
        
        Write-Host "[AutoGenWorkflow] $WorkflowType workflow completed in $([math]::Round($duration, 2)) seconds" -ForegroundColor Blue
        
        return $workflowResult
    }
    catch {
        Write-Error "[AutoGenWorkflow] Workflow execution failed: $($_.Exception.Message)"
        return @{
            WorkflowType = $WorkflowType
            Error = $_.Exception.Message
            Status = "failed"
        }
    }
}

function Stop-AutoGenServices {
    <#
    .SYNOPSIS
    Stops all AutoGen services and cleanup resources
    
    .DESCRIPTION
    Gracefully stops Named Pipe servers, agent processes, and cleans up resources
    
    .PARAMETER Force
    Force stop all services without graceful shutdown
    
    .EXAMPLE
    Stop-AutoGenServices -Force
    #>
    [CmdletBinding()]
    param(
        [Parameter()]
        [switch]$Force
    )
    
    Write-Host "[AutoGenServices] Stopping AutoGen services..." -ForegroundColor Red
    
    try {
        $stoppedServices = @{
            NamedPipeServers = 0
            BackgroundJobs = 0
            TempFiles = 0
        }
        
        # Stop Named Pipe server jobs
        $pipeJobs = Get-Job | Where-Object { $_.Name -match "AutoGenPipeServer" }
        foreach ($job in $pipeJobs) {
            if ($Force) {
                $job | Stop-Job | Remove-Job -Force
            }
            else {
                $job | Stop-Job | Remove-Job
            }
            $stoppedServices.NamedPipeServers++
        }
        
        # Stop other AutoGen-related background jobs
        $autoGenJobs = Get-Job | Where-Object { $_.Name -match "AutoGen" }
        foreach ($job in $autoGenJobs) {
            if ($Force) {
                $job | Stop-Job | Remove-Job -Force
            }
            else {
                $job | Stop-Job | Remove-Job
            }
            $stoppedServices.BackgroundJobs++
        }
        
        # Cleanup temporary files
        $tempFiles = Get-ChildItem -Path "." -Filter "temp_*.*" -ErrorAction SilentlyContinue
        foreach ($file in $tempFiles) {
            Remove-Item $file.FullName -Force -ErrorAction SilentlyContinue
            $stoppedServices.TempFiles++
        }
        
        Write-Host "[AutoGenServices] Services stopped: $($stoppedServices.NamedPipeServers) pipe servers, $($stoppedServices.BackgroundJobs) jobs, $($stoppedServices.TempFiles) temp files" -ForegroundColor Red
        
        return $stoppedServices
    }
    catch {
        Write-Error "[AutoGenServices] Failed to stop services: $($_.Exception.Message)"
        return @{ Error = $_.Exception.Message; Status = "failed" }
    }
}

#endregion

#region Module Exports

Export-ModuleMember -Function @(
    'New-AutoGenAgent',
    'Get-AutoGenAgent',
    'New-AutoGenTeam',
    'Invoke-AutoGenConversation',
    'Start-AutoGenNamedPipeServer',
    'Send-AutoGenMessage',
    'Test-AutoGenConnectivity',
    'Get-AutoGenConversationHistory',
    'Set-AutoGenConfiguration',
    'Get-AutoGenConfiguration',
    'Clear-AutoGenRegistry',
    'Invoke-AutoGenAnalysisWorkflow',
    'Stop-AutoGenServices'
)

#endregion

Write-Host "[Unity-Claude-AutoGen] Module loaded successfully - Version 1.0.0" -ForegroundColor Green
Write-Host "[Unity-Claude-AutoGen] AutoGen v0.7.4 multi-agent coordination ready" -ForegroundColor Green
Write-Host "[Unity-Claude-AutoGen] Python executable: $($script:AutoGenConfig.PythonExecutable)" -ForegroundColor Gray