#!/usr/bin/env python3
"""
PowerShell REST API Bridge for AutoGen Integration
Provides REST API server that can be run on Windows to bridge WSL2 Python with Windows PowerShell
"""

import asyncio
import json
import subprocess
import sys
import os
from typing import Dict, Any, Optional
from datetime import datetime
import logging
from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
import uvicorn

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

class PowerShellRequest(BaseModel):
    """Request model for PowerShell command execution"""
    command: str
    timeout: int = 30
    working_directory: Optional[str] = None

class PowerShellResponse(BaseModel):
    """Response model for PowerShell command execution"""
    success: bool
    stdout: str
    stderr: str
    exit_code: int
    execution_time: float
    timestamp: str
    command: str

class PowerShellRESTBridge:
    """REST API bridge for PowerShell commands"""
    
    def __init__(self):
        self.app = FastAPI(title="PowerShell REST Bridge", version="1.0.0")
        self.execution_count = 0
        self._setup_routes()
    
    def _setup_routes(self):
        """Setup FastAPI routes"""
        
        @self.app.get("/health")
        async def health_check():
            """Health check endpoint"""
            return {"status": "healthy", "service": "PowerShell REST Bridge"}
        
        @self.app.post("/execute", response_model=PowerShellResponse)
        async def execute_powershell(request: PowerShellRequest):
            """Execute PowerShell command"""
            return await self._execute_command(request)
        
        @self.app.get("/system-status")
        async def get_system_status():
            """Get Unity Claude system status"""
            status_command = PowerShellRequest(
                command="""
                $status = @{
                    PowerShellVersion = $PSVersionTable.PSVersion.ToString()
                    ExecutionCount = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
                    WorkingDirectory = (Get-Location).Path
                    UnityClaudeModules = @()
                }
                
                # Check for Unity Claude modules
                try {
                    $modules = Get-Module -ListAvailable -Name 'Unity-Claude-*' -ErrorAction SilentlyContinue
                    if ($modules) {
                        $status.UnityClaudeModules = $modules | ForEach-Object { 
                            @{ Name = $_.Name; Version = $_.Version.ToString() }
                        }
                    }
                } catch {
                    $status.UnityClaudeModules = @()
                }
                
                $status | ConvertTo-Json -Depth 3
                """,
                timeout=15
            )
            
            result = await self._execute_command(status_command)
            if result.success:
                try:
                    return json.loads(result.stdout)
                except json.JSONDecodeError:
                    return {"error": "Failed to parse system status", "raw_output": result.stdout}
            else:
                return {"error": "Failed to get system status", "details": result.stderr}
    
    async def _execute_command(self, request: PowerShellRequest) -> PowerShellResponse:
        """Execute PowerShell command internally"""
        start_time = datetime.now()
        self.execution_count += 1
        
        logger.info(f"Executing PowerShell command #{self.execution_count}")
        
        try:
            # Build PowerShell command for Windows execution
            ps_cmd = [
                "C:\\Program Files\\PowerShell\\7\\pwsh.exe",  # Try PowerShell 7 first
                "-NoProfile",
                "-NonInteractive",
                "-ExecutionPolicy", "Bypass", 
                "-Command", request.command
            ]
            
            # Fallback to Windows PowerShell if PS7 not available
            if not os.path.exists(ps_cmd[0]):
                ps_cmd[0] = "powershell.exe"
            
            # Execute command
            process = await asyncio.create_subprocess_exec(
                *ps_cmd,
                stdout=asyncio.subprocess.PIPE,
                stderr=asyncio.subprocess.PIPE,
                cwd=request.working_directory
            )
            
            # Wait with timeout
            try:
                stdout, stderr = await asyncio.wait_for(
                    process.communicate(),
                    timeout=request.timeout
                )
                exit_code = process.returncode
            except asyncio.TimeoutError:
                process.kill()
                await process.wait()
                raise TimeoutError(f"Command timed out after {request.timeout} seconds")
            
            # Process results
            stdout_str = stdout.decode('utf-8', errors='replace') if stdout else ""
            stderr_str = stderr.decode('utf-8', errors='replace') if stderr else ""
            execution_time = (datetime.now() - start_time).total_seconds()
            
            return PowerShellResponse(
                success=exit_code == 0,
                stdout=stdout_str,
                stderr=stderr_str, 
                exit_code=exit_code,
                execution_time=execution_time,
                timestamp=start_time.isoformat(),
                command=request.command[:100] + "..." if len(request.command) > 100 else request.command
            )
            
        except Exception as e:
            execution_time = (datetime.now() - start_time).total_seconds()
            logger.error(f"Command execution failed: {e}")
            
            return PowerShellResponse(
                success=False,
                stdout="",
                stderr=f"Execution error: {str(e)}",
                exit_code=-1,
                execution_time=execution_time,
                timestamp=start_time.isoformat(),
                command=request.command[:100] + "..." if len(request.command) > 100 else request.command
            )
    
    def run_server(self, host: str = "0.0.0.0", port: int = 8000):
        """Run the REST API server"""
        logger.info(f"Starting PowerShell REST Bridge on {host}:{port}")
        uvicorn.run(self.app, host=host, port=port, log_level="info")

class AutoGenPowerShellClient:
    """Client for AutoGen agents to communicate with PowerShell REST bridge"""
    
    def __init__(self, bridge_url: str = "http://localhost:8000"):
        self.bridge_url = bridge_url
        self.session = None
    
    async def execute_powershell(self, command: str, timeout: int = 30) -> Dict[str, Any]:
        """Execute PowerShell command via REST bridge"""
        import aiohttp
        
        async with aiohttp.ClientSession() as session:
            try:
                request_data = {
                    "command": command,
                    "timeout": timeout
                }
                
                async with session.post(
                    f"{self.bridge_url}/execute",
                    json=request_data,
                    timeout=aiohttp.ClientTimeout(total=timeout + 10)
                ) as response:
                    if response.status == 200:
                        return await response.json()
                    else:
                        error_text = await response.text()
                        return {
                            "success": False,
                            "stdout": "",
                            "stderr": f"HTTP {response.status}: {error_text}",
                            "exit_code": -1,
                            "execution_time": 0,
                            "timestamp": datetime.now().isoformat(),
                            "command": command
                        }
            except Exception as e:
                return {
                    "success": False,
                    "stdout": "",
                    "stderr": f"Connection error: {str(e)}",
                    "exit_code": -1,
                    "execution_time": 0,
                    "timestamp": datetime.now().isoformat(), 
                    "command": command
                }
    
    async def test_connection(self) -> bool:
        """Test connection to PowerShell bridge"""
        import aiohttp
        
        try:
            async with aiohttp.ClientSession() as session:
                async with session.get(
                    f"{self.bridge_url}/health",
                    timeout=aiohttp.ClientTimeout(total=5)
                ) as response:
                    return response.status == 200
        except:
            return False

def main():
    """Main entry point"""
    if len(sys.argv) > 1 and sys.argv[1] == "server":
        # Run as server (on Windows)
        bridge = PowerShellRESTBridge()
        bridge.run_server()
    else:
        # Run as client test (from WSL2)
        print("PowerShell REST Bridge Client Test")
        print("=" * 40)
        print("To run the server, use: python powershell_rest_bridge.py server")
        print("This client test requires the server to be running on Windows")

if __name__ == "__main__":
    main()