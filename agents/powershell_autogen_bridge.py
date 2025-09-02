#!/usr/bin/env python3
"""
PowerShell-AutoGen Bridge for Cross-Platform Integration
Implements IPC mechanisms for PowerShell-Python communication
"""

import json
import asyncio
import subprocess
import os
import sys
from typing import Dict, List, Any, Optional
from dataclasses import dataclass
from enum import Enum
import win32pipe
import win32file
import pywintypes
from threading import Thread
import queue
from pathlib import Path

# FastAPI for REST bridge
from fastapi import FastAPI, HTTPException, BackgroundTasks
from pydantic import BaseModel
import uvicorn

# AutoGen imports
from autogen_groupchat_config import create_multi_agent_system

class IPCMethod(Enum):
    """IPC methods for PowerShell-Python communication"""
    NAMED_PIPES = "named_pipes"
    REST_API = "rest_api"
    SUBPROCESS = "subprocess"

class MessageType(Enum):
    """Message types for IPC communication"""
    COMMAND = "command"
    QUERY = "query"
    RESPONSE = "response"
    ERROR = "error"
    STATUS = "status"
    RESULT = "result"

@dataclass
class IPCMessage:
    """Standard message format for IPC"""
    type: MessageType
    content: Any
    metadata: Dict[str, Any] = None
    correlation_id: Optional[str] = None

class NamedPipeServer:
    """Named pipe server for PowerShell communication"""
    
    def __init__(self, pipe_name: str = r"\\.\pipe\UnityClaudeAutogen"):
        self.pipe_name = pipe_name
        self.running = False
        self.message_queue = queue.Queue()
        
    def start(self):
        """Start the named pipe server"""
        self.running = True
        thread = Thread(target=self._listen, daemon=True)
        thread.start()
        
    def _listen(self):
        """Listen for incoming connections"""
        while self.running:
            try:
                # Create named pipe
                pipe = win32pipe.CreateNamedPipe(
                    self.pipe_name,
                    win32pipe.PIPE_ACCESS_DUPLEX,
                    win32pipe.PIPE_TYPE_MESSAGE | win32pipe.PIPE_READMODE_MESSAGE | win32pipe.PIPE_WAIT,
                    1, 65536, 65536, 0, None
                )
                
                # Wait for client connection
                win32pipe.ConnectNamedPipe(pipe, None)
                
                # Read message
                result, data = win32file.ReadFile(pipe, 65536)
                if result == 0:
                    message = json.loads(data.decode('utf-8'))
                    self.message_queue.put(message)
                    
                    # Send response
                    response = self._process_message(message)
                    response_data = json.dumps(response).encode('utf-8')
                    win32file.WriteFile(pipe, response_data)
                
                # Close pipe
                win32file.CloseHandle(pipe)
                
            except pywintypes.error as e:
                print(f"Named pipe error: {e}")
            except Exception as e:
                print(f"Error in named pipe listener: {e}")
    
    def _process_message(self, message: Dict) -> Dict:
        """Process incoming message"""
        try:
            msg = IPCMessage(
                type=MessageType(message.get("type", "command")),
                content=message.get("content"),
                metadata=message.get("metadata", {}),
                correlation_id=message.get("correlation_id")
            )
            
            # Process based on message type
            if msg.type == MessageType.COMMAND:
                return self._handle_command(msg)
            elif msg.type == MessageType.QUERY:
                return self._handle_query(msg)
            else:
                return {"type": "error", "content": "Unknown message type"}
                
        except Exception as e:
            return {"type": "error", "content": str(e)}
    
    def _handle_command(self, msg: IPCMessage) -> Dict:
        """Handle command messages"""
        # This would trigger AutoGen agents
        return {
            "type": "response",
            "content": "Command received",
            "correlation_id": msg.correlation_id
        }
    
    def _handle_query(self, msg: IPCMessage) -> Dict:
        """Handle query messages"""
        return {
            "type": "response",
            "content": "Query processed",
            "correlation_id": msg.correlation_id
        }
    
    def stop(self):
        """Stop the named pipe server"""
        self.running = False

class PowerShellBridge:
    """Bridge for executing PowerShell commands from Python"""
    
    def __init__(self):
        self.ps_executable = self._find_powershell()
        
    def _find_powershell(self) -> str:
        """Find PowerShell executable (prefer PS7)"""
        ps7_path = r"C:\Program Files\PowerShell\7\pwsh.exe"
        if os.path.exists(ps7_path):
            return ps7_path
        return "powershell.exe"  # Fallback to PS5.1
    
    def execute_command(self, command: str, timeout: int = 30) -> Dict[str, Any]:
        """Execute PowerShell command and return result"""
        try:
            result = subprocess.run(
                [self.ps_executable, "-Command", command],
                capture_output=True,
                text=True,
                timeout=timeout
            )
            
            return {
                "success": result.returncode == 0,
                "stdout": result.stdout,
                "stderr": result.stderr,
                "returncode": result.returncode
            }
        except subprocess.TimeoutExpired:
            return {
                "success": False,
                "error": "Command timeout",
                "timeout": timeout
            }
        except Exception as e:
            return {
                "success": False,
                "error": str(e)
            }
    
    def execute_script(self, script_path: str, parameters: Dict[str, Any] = None) -> Dict[str, Any]:
        """Execute PowerShell script with parameters"""
        command = f"-ExecutionPolicy Bypass -File \"{script_path}\""
        
        if parameters:
            for key, value in parameters.items():
                command += f" -{key} \"{value}\""
        
        return self.execute_command(command, timeout=60)
    
    def invoke_module_function(self, module: str, function: str, parameters: Dict[str, Any] = None) -> Dict[str, Any]:
        """Invoke a function from a PowerShell module"""
        command = f"Import-Module {module}; {function}"
        
        if parameters:
            param_str = " ".join([f"-{k} '{v}'" for k, v in parameters.items()])
            command += f" {param_str}"
        
        return self.execute_command(command)

# REST API Bridge
app = FastAPI(title="AutoGen-PowerShell Bridge API")

class AgentRequest(BaseModel):
    """Request model for agent tasks"""
    task: str
    parameters: Dict[str, Any] = {}
    agent_type: str = "analysis"  # analysis, research, implementation
    timeout: int = 300

class AgentResponse(BaseModel):
    """Response model for agent tasks"""
    success: bool
    result: Any
    error: Optional[str] = None
    metadata: Dict[str, Any] = {}

# Global instances
multi_agent_system = None
powershell_bridge = PowerShellBridge()
named_pipe_server = NamedPipeServer()

@app.on_event("startup")
async def startup_event():
    """Initialize services on startup"""
    global multi_agent_system
    multi_agent_system = create_multi_agent_system()
    named_pipe_server.start()
    print("AutoGen-PowerShell Bridge started")

@app.on_event("shutdown")
async def shutdown_event():
    """Cleanup on shutdown"""
    named_pipe_server.stop()
    print("AutoGen-PowerShell Bridge stopped")

@app.post("/agent/task", response_model=AgentResponse)
async def execute_agent_task(request: AgentRequest):
    """Execute an agent task"""
    try:
        # Select appropriate group chat based on agent type
        if request.agent_type == "analysis":
            group_chat = multi_agent_system.create_analysis_group_chat()
        elif request.agent_type == "research":
            group_chat = multi_agent_system.create_research_group_chat()
        elif request.agent_type == "implementation":
            group_chat = multi_agent_system.create_implementation_group_chat()
        else:
            group_chat = multi_agent_system.create_full_system_group_chat()
        
        # Execute task (simplified - actual implementation would be async)
        # result = await group_chat.run(request.task, **request.parameters)
        
        return AgentResponse(
            success=True,
            result={"message": "Task initiated", "type": request.agent_type},
            metadata={"task": request.task}
        )
        
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.post("/powershell/execute")
async def execute_powershell(command: str, timeout: int = 30):
    """Execute PowerShell command"""
    result = powershell_bridge.execute_command(command, timeout)
    return result

@app.post("/powershell/script")
async def execute_powershell_script(script_path: str, parameters: Dict[str, Any] = None):
    """Execute PowerShell script"""
    result = powershell_bridge.execute_script(script_path, parameters)
    return result

@app.get("/status")
async def get_status():
    """Get bridge status"""
    return {
        "status": "running",
        "powershell": powershell_bridge.ps_executable,
        "named_pipe": named_pipe_server.pipe_name,
        "agents_initialized": multi_agent_system is not None
    }

@app.get("/agents/list")
async def list_agents():
    """List available agents"""
    if not multi_agent_system:
        return {"error": "System not initialized"}
    
    return {
        "supervisors": list(multi_agent_system.supervisor_orchestrator.supervisors.keys()),
        "research_agents": list(multi_agent_system.research_team.agents.keys()),
        "implementer_agents": list(multi_agent_system.implementer_team.agents.keys())
    }

class PowerShellIntegration:
    """Integration helpers for PowerShell modules"""
    
    @staticmethod
    def create_powershell_wrapper(module_path: str) -> str:
        """Create PowerShell wrapper script for Python bridge"""
        wrapper_content = """
# PowerShell wrapper for AutoGen Python bridge
param(
    [string]$Task,
    [hashtable]$Parameters = @{},
    [string]$AgentType = "analysis",
    [int]$Timeout = 300
)

# REST API endpoint
$apiUrl = "http://localhost:8000"

# Convert parameters to JSON
$body = @{
    task = $Task
    parameters = $Parameters
    agent_type = $AgentType
    timeout = $Timeout
} | ConvertTo-Json

# Make API call
try {
    $response = Invoke-RestMethod -Uri "$apiUrl/agent/task" -Method Post -Body $body -ContentType "application/json"
    return $response
}
catch {
    Write-Error "Failed to execute agent task: $_"
    return $null
}
"""
        wrapper_path = Path(module_path) / "Invoke-AutoGenAgent.ps1"
        wrapper_path.write_text(wrapper_content)
        return str(wrapper_path)
    
    @staticmethod
    def create_named_pipe_client() -> str:
        """Create PowerShell named pipe client"""
        client_content = """
# PowerShell named pipe client for AutoGen bridge
function Send-AutoGenMessage {
    param(
        [string]$Type = "command",
        [object]$Content,
        [hashtable]$Metadata = @{},
        [string]$PipeName = "\\\\.\\pipe\\UnityClaudeAutogen"
    )
    
    $message = @{
        type = $Type
        content = $Content
        metadata = $Metadata
        correlation_id = [Guid]::NewGuid().ToString()
    } | ConvertTo-Json
    
    try {
        $pipe = New-Object System.IO.Pipes.NamedPipeClientStream(".", "UnityClaudeAutogen", [System.IO.Pipes.PipeDirection]::InOut)
        $pipe.Connect(5000)
        
        $writer = New-Object System.IO.StreamWriter($pipe)
        $writer.WriteLine($message)
        $writer.Flush()
        
        $reader = New-Object System.IO.StreamReader($pipe)
        $response = $reader.ReadLine()
        
        $pipe.Close()
        
        return $response | ConvertFrom-Json
    }
    catch {
        Write-Error "Failed to send message via named pipe: $_"
        return $null
    }
}

Export-ModuleMember -Function Send-AutoGenMessage
"""
        return client_content

def main():
    """Main entry point for standalone execution"""
    # Start REST API server
    uvicorn.run(app, host="0.0.0.0", port=8000)

if __name__ == "__main__":
    main()