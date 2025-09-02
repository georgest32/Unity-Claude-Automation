#!/usr/bin/env python3
"""
PowerShell-Python Bridge for AutoGen Integration
Provides REST API interface for AutoGen agents to execute PowerShell commands
"""

import asyncio
import json
import subprocess
import sys
import os
from typing import Dict, Any, Optional, List
from dataclasses import dataclass
from datetime import datetime
import logging

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

@dataclass
class PowerShellCommand:
    """Represents a PowerShell command execution request"""
    command: str
    timeout: int = 30
    working_directory: Optional[str] = None
    parameters: Optional[Dict[str, Any]] = None

@dataclass 
class PowerShellResult:
    """Represents the result of PowerShell command execution"""
    success: bool
    stdout: str
    stderr: str
    exit_code: int
    execution_time: float
    timestamp: str

class PowerShellBridge:
    """Bridge for executing PowerShell commands from Python"""
    
    def __init__(self, default_timeout: int = 30):
        self.default_timeout = default_timeout
        self.execution_count = 0
        
    async def execute_powershell_async(self, command: PowerShellCommand) -> PowerShellResult:
        """Execute PowerShell command asynchronously"""
        start_time = datetime.now()
        self.execution_count += 1
        
        logger.info(f"Executing PowerShell command #{self.execution_count}: {command.command[:100]}...")
        
        try:
            # Build PowerShell command
            ps_cmd = self._build_powershell_command(command)
            
            # Execute with asyncio subprocess
            process = await asyncio.create_subprocess_exec(
                *ps_cmd,
                stdout=asyncio.subprocess.PIPE,
                stderr=asyncio.subprocess.PIPE,
                cwd=command.working_directory
            )
            
            # Wait for completion with timeout
            try:
                stdout, stderr = await asyncio.wait_for(
                    process.communicate(), 
                    timeout=command.timeout
                )
                exit_code = process.returncode
                
            except asyncio.TimeoutError:
                process.kill()
                await process.wait()
                return PowerShellResult(
                    success=False,
                    stdout="",
                    stderr=f"Command timed out after {command.timeout} seconds",
                    exit_code=-1,
                    execution_time=(datetime.now() - start_time).total_seconds(),
                    timestamp=start_time.isoformat()
                )
            
            # Process results
            stdout_str = stdout.decode('utf-8', errors='replace') if stdout else ""
            stderr_str = stderr.decode('utf-8', errors='replace') if stderr else ""
            execution_time = (datetime.now() - start_time).total_seconds()
            
            result = PowerShellResult(
                success=exit_code == 0,
                stdout=stdout_str,
                stderr=stderr_str,
                exit_code=exit_code,
                execution_time=execution_time,
                timestamp=start_time.isoformat()
            )
            
            logger.info(f"PowerShell command #{self.execution_count} completed in {execution_time:.2f}s, exit_code: {exit_code}")
            return result
            
        except Exception as e:
            execution_time = (datetime.now() - start_time).total_seconds()
            logger.error(f"PowerShell command #{self.execution_count} failed: {e}")
            
            return PowerShellResult(
                success=False,
                stdout="",
                stderr=f"Execution error: {str(e)}",
                exit_code=-1,
                execution_time=execution_time,
                timestamp=start_time.isoformat()
            )
    
    def _build_powershell_command(self, command: PowerShellCommand) -> List[str]:
        """Build PowerShell command array for subprocess execution"""
        
        # Try PowerShell 7 first, then fallback to Windows PowerShell
        powershell_paths = [
            r"C:\Program Files\PowerShell\7\pwsh.exe",
            "powershell.exe"
        ]
        
        # Find available PowerShell executable
        powershell_exe = None
        for ps_path in powershell_paths:
            if os.path.exists(ps_path) if os.path.isabs(ps_path) else True:
                powershell_exe = ps_path
                break
        
        if not powershell_exe:
            raise RuntimeError("No PowerShell executable found")
        
        # Build command array
        cmd_array = [
            powershell_exe,
            "-NoProfile",
            "-NonInteractive", 
            "-ExecutionPolicy", "Bypass",
            "-Command", command.command
        ]
        
        return cmd_array
    
    async def test_powershell_connectivity(self) -> bool:
        """Test if PowerShell is accessible"""
        test_command = PowerShellCommand(
            command="Write-Output 'PowerShell Bridge Test'; $PSVersionTable.PSVersion",
            timeout=10
        )
        
        result = await self.execute_powershell_async(test_command)
        return result.success

class AutoGenPowerShellAgent:
    """AutoGen-compatible agent that can execute PowerShell commands"""
    
    def __init__(self, name: str = "PowerShellAgent"):
        self.name = name
        self.bridge = PowerShellBridge()
        self.command_history = []
    
    async def execute_powershell(self, command: str, timeout: int = 30) -> Dict[str, Any]:
        """Execute PowerShell command and return JSON-serializable result"""
        
        ps_command = PowerShellCommand(command=command, timeout=timeout)
        result = await self.bridge.execute_powershell_async(ps_command)
        
        # Convert to JSON-serializable format
        result_dict = {
            "success": result.success,
            "stdout": result.stdout,
            "stderr": result.stderr,
            "exit_code": result.exit_code,
            "execution_time": result.execution_time,
            "timestamp": result.timestamp,
            "command": command
        }
        
        # Store in history for debugging
        self.command_history.append(result_dict)
        
        return result_dict
    
    async def get_unity_claude_status(self) -> Dict[str, Any]:
        """Get Unity Claude Automation system status"""
        command = """
        # Get system status
        $status = @{
            PowerShellVersion = $PSVersionTable.PSVersion.ToString()
            ModulesPath = $env:PSModulePath -split ';' | Select-Object -First 3
            CurrentDirectory = Get-Location | Select-Object -ExpandProperty Path
            AvailableModules = @()
        }
        
        # Check for Unity Claude modules
        $unityModules = Get-Module -ListAvailable -Name 'Unity-Claude-*' | Select-Object Name, Version
        if ($unityModules) {
            $status.AvailableModules = $unityModules | ForEach-Object { 
                @{ Name = $_.Name; Version = $_.Version.ToString() }
            }
        }
        
        $status | ConvertTo-Json -Depth 3
        """
        
        return await self.execute_powershell(command, timeout=15)

async def main():
    """Test the PowerShell-Python bridge"""
    print("PowerShell-Python Bridge Test")
    print("=" * 40)
    
    # Test basic bridge connectivity
    bridge = PowerShellBridge()
    
    print("Testing PowerShell connectivity...")
    connectivity = await bridge.test_powershell_connectivity()
    print(f"PowerShell connectivity: {'✅ OK' if connectivity else '❌ FAILED'}")
    
    if not connectivity:
        print("PowerShell bridge setup failed")
        return False
    
    # Test AutoGen-compatible agent
    print("\nTesting AutoGen-compatible PowerShell agent...")
    agent = AutoGenPowerShellAgent("TestAgent")
    
    # Get system status
    status_result = await agent.get_unity_claude_status()
    print(f"System status query: {'✅ OK' if status_result['success'] else '❌ FAILED'}")
    
    if status_result['success']:
        try:
            status_data = json.loads(status_result['stdout'])
            print(f"PowerShell Version: {status_data.get('PowerShellVersion', 'Unknown')}")
            print(f"Unity Claude Modules Found: {len(status_data.get('AvailableModules', []))}")
        except json.JSONDecodeError:
            print("Status data not in expected JSON format")
    
    print("\n✅ PowerShell-Python bridge operational!")
    print("Ready for AutoGen agent integration")
    
    return True

if __name__ == "__main__":
    asyncio.run(main())