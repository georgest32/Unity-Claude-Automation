function Start-PythonBridge {
    <#
    .SYNOPSIS
    Starts the Python bridge for LangGraph and AutoGen integration
    
    .DESCRIPTION
    Creates a named pipe IPC bridge between PowerShell and Python for
    multi-agent orchestration using LangGraph and AutoGen frameworks
    #>
    [CmdletBinding()]
    param(
        [Parameter()]
        [string]$PipeName = "UnityClaudeRepoPipe",
        
        [Parameter()]
        [string]$PythonPath = "python",
        
        [Parameter()]
        [string]$BridgeScriptPath,
        
        [Parameter()]
        [int]$TimeoutSeconds = 30
    )
    
    begin {
        Write-Verbose "Starting Python bridge with pipe: $PipeName"
        $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    }
    
    process {
        try {
            # Check if Python is available
            try {
                $pythonVersion = & $PythonPath --version 2>&1
                Write-Verbose "Python found: $pythonVersion"
            }
            catch {
                throw "Python not found at path: $PythonPath"
            }
            
            # Set default bridge script path if not provided
            if (-not $BridgeScriptPath) {
                $BridgeScriptPath = Join-Path $PSScriptRoot "..\Python\bridge_server.py"
            }
            
            # Create the bridge script if it doesn't exist
            if (-not (Test-Path $BridgeScriptPath)) {
                Write-Verbose "Creating Python bridge script at: $BridgeScriptPath"
                New-PythonBridgeScript -OutputPath $BridgeScriptPath
            }
            
            # Create named pipe server
            $pipePath = "\\.\pipe\$PipeName"
            
            # Start Python process
            $pythonArgs = @($BridgeScriptPath, "--pipe", $PipeName)
            $processInfo = New-Object System.Diagnostics.ProcessStartInfo
            $processInfo.FileName = $PythonPath
            $processInfo.Arguments = $pythonArgs -join ' '
            $processInfo.UseShellExecute = $false
            $processInfo.RedirectStandardOutput = $true
            $processInfo.RedirectStandardError = $true
            $processInfo.RedirectStandardInput = $true
            $processInfo.CreateNoWindow = $true
            
            $process = New-Object System.Diagnostics.Process
            $process.StartInfo = $processInfo
            
            # Start the process
            $process.Start() | Out-Null
            
            # Wait for Python bridge to be ready
            $ready = $false
            $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
            
            while (-not $ready -and $stopwatch.Elapsed.TotalSeconds -lt $TimeoutSeconds) {
                if ($process.StandardOutput.Peek() -ge 0) {
                    $line = $process.StandardOutput.ReadLine()
                    if ($line -match "BRIDGE_READY") {
                        $ready = $true
                        Write-Verbose "Python bridge is ready"
                    }
                }
                Start-Sleep -Milliseconds 100
            }
            
            if (-not $ready) {
                throw "Timeout waiting for Python bridge to start"
            }
            
            # Store bridge information globally
            $global:PythonBridgeProcess = @{
                Process = $process
                PipeName = $PipeName
                PipePath = $pipePath
                StartTime = $timestamp
                Status = 'Running'
            }
            
            Write-Host "Python bridge started successfully on pipe: $PipeName" -ForegroundColor Green
            
            return [PSCustomObject]@{
                PipeName = $PipeName
                ProcessId = $process.Id
                StartTime = $timestamp
                Status = 'Running'
            }
            
        }
        catch {
            Write-Error "Failed to start Python bridge: $_"
            throw
        }
    }
}

function New-PythonBridgeScript {
    <#
    .SYNOPSIS
    Creates the Python bridge server script
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$OutputPath
    )
    
    $scriptContent = @'
#!/usr/bin/env python3
"""
Python Bridge Server for Unity-Claude-RepoAnalyst
Provides IPC bridge between PowerShell and Python for LangGraph/AutoGen
"""

import json
import sys
import os
import argparse
import asyncio
import logging
from typing import Dict, Any, Optional
import win32pipe
import win32file
import pywintypes

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

class PythonBridge:
    """Named pipe IPC bridge for PowerShell-Python communication"""
    
    def __init__(self, pipe_name: str):
        self.pipe_name = pipe_name
        self.pipe_path = f"\\\\.\\pipe\\{pipe_name}"
        self.pipe_handle = None
        self.running = False
        
    def start(self):
        """Start the named pipe server"""
        try:
            # Create named pipe
            self.pipe_handle = win32pipe.CreateNamedPipe(
                self.pipe_path,
                win32pipe.PIPE_ACCESS_DUPLEX,
                win32pipe.PIPE_TYPE_MESSAGE | win32pipe.PIPE_READMODE_MESSAGE | win32pipe.PIPE_WAIT,
                1, 65536, 65536, 0, None
            )
            
            logger.info(f"Named pipe created: {self.pipe_path}")
            print("BRIDGE_READY", flush=True)
            self.running = True
            
            # Main message loop
            while self.running:
                try:
                    # Wait for client connection
                    win32pipe.ConnectNamedPipe(self.pipe_handle, None)
                    
                    # Read message
                    result, data = win32file.ReadFile(self.pipe_handle, 65536)
                    if result == 0:
                        message = data.decode('utf-8')
                        logger.debug(f"Received message: {message}")
                        
                        # Process message
                        response = self.process_message(json.loads(message))
                        
                        # Send response
                        response_data = json.dumps(response).encode('utf-8')
                        win32file.WriteFile(self.pipe_handle, response_data)
                        
                    # Disconnect client
                    win32pipe.DisconnectNamedPipe(self.pipe_handle)
                    
                except pywintypes.error as e:
                    logger.error(f"Pipe error: {e}")
                    if e.args[0] == 109:  # ERROR_BROKEN_PIPE
                        continue
                    else:
                        break
                        
        except Exception as e:
            logger.error(f"Failed to start bridge: {e}")
            raise
        finally:
            if self.pipe_handle:
                win32file.CloseHandle(self.pipe_handle)
                
    def process_message(self, message: Dict[str, Any]) -> Dict[str, Any]:
        """Process incoming message and return response"""
        try:
            method = message.get('method')
            params = message.get('params', {})
            
            if method == 'ping':
                return {'status': 'success', 'result': 'pong'}
            elif method == 'execute_langgraph':
                # TODO: Implement LangGraph execution
                return {'status': 'success', 'result': 'LangGraph execution placeholder'}
            elif method == 'execute_autogen':
                # TODO: Implement AutoGen execution
                return {'status': 'success', 'result': 'AutoGen execution placeholder'}
            elif method == 'shutdown':
                self.running = False
                return {'status': 'success', 'result': 'Shutting down'}
            else:
                return {'status': 'error', 'error': f'Unknown method: {method}'}
                
        except Exception as e:
            logger.error(f"Error processing message: {e}")
            return {'status': 'error', 'error': str(e)}

def main():
    parser = argparse.ArgumentParser(description='Python Bridge Server')
    parser.add_argument('--pipe', default='UnityClaudeRepoPipe', help='Named pipe name')
    parser.add_argument('--debug', action='store_true', help='Enable debug logging')
    
    args = parser.parse_args()
    
    if args.debug:
        logging.getLogger().setLevel(logging.DEBUG)
    
    bridge = PythonBridge(args.pipe)
    
    try:
        bridge.start()
    except KeyboardInterrupt:
        logger.info("Bridge shutdown requested")
    except Exception as e:
        logger.error(f"Bridge error: {e}")
        sys.exit(1)

if __name__ == '__main__':
    main()
'@
    
    # Ensure directory exists
    $dir = Split-Path $OutputPath -Parent
    if (-not (Test-Path $dir)) {
        New-Item -Path $dir -ItemType Directory -Force | Out-Null
    }
    
    # Write script
    $scriptContent | Out-File $OutputPath -Encoding UTF8
    
    Write-Verbose "Python bridge script created at: $OutputPath"
}
# SIG # Begin signature block
# MIIFzgYJKoZIhvcNAQcCoIIFvzCCBbsCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCBcO4CWFAhB6cFv
# QY6hnvR+euVjfNIlyo7TghVNw+LEBKCCAzAwggMsMIICFKADAgECAhB1HRbZIqgr
# lUTwkh3hnGtFMA0GCSqGSIb3DQEBCwUAMC4xLDAqBgNVBAMMI1VuaXR5LUNsYXVk
# ZS1BdXRvbWF0aW9uLURldmVsb3BtZW50MB4XDTI1MDgyMDIxMTUxN1oXDTI2MDgy
# MDIxMzUxN1owLjEsMCoGA1UEAwwjVW5pdHktQ2xhdWRlLUF1dG9tYXRpb24tRGV2
# ZWxvcG1lbnQwggEiMA0GCSqGSIb3DQEBAQUAA4IBDwAwggEKAoIBAQCx4feqKdUQ
# 6GufY4umNzlM1Pi8aHUGR8HlfhIWFjsrRAxCxhieRlWbHe0Hw+pVBeX76X57e5Pu
# 4Kxxzu+MxMry0NJYf3yOLRTfhYskHBcLraXUCtrMwqnhPKvul6Sx6Lu8vilk605W
# ADJNifl3WFuexVCYJJM9G2mfuYIDN+rZ5zmpn0qCXum49bm629h+HyJ205Zrn9aB
# hIrA4i/JlrAh1kosWnCo62psl7ixbNVqFqwWEt+gAqSeIo4ChwkOQl7GHmk78Q5I
# oRneY4JTVlKzhdZEYhJGFXeoZml/5jcmUcox4UNYrKdokE7z8ZTmyowBOUNS+sHI
# G1TY5DZSb8vdAgMBAAGjRjBEMA4GA1UdDwEB/wQEAwIHgDATBgNVHSUEDDAKBggr
# BgEFBQcDAzAdBgNVHQ4EFgQUfDms7LrGVboHjmwlSyIjYD/JLQwwDQYJKoZIhvcN
# AQELBQADggEBABRMsfT7DzKy+aFi4HDg0MpxmbjQxOH1lzUzanaECRiyA0sn7+sA
# /4jvis1+qC5NjDGkLKOTCuDzIXnBWLCCBugukXbIO7g392ANqKdHjBHw1WlLvMVk
# 4WSmY096lzpvDd3jJApr/Alcp4KmRGNLnQ3vv+F9Uj58Uo1qjs85vt6fl9xe5lo3
# rFahNHL4ngjgyF8emNm7FItJeNtVe08PhFn0caOX0FTzXrZxGGO6Ov8tzf91j/qK
# QdBifG7Fx3FF7DifNqoBBo55a7q0anz30k8p+V0zllrLkgGXfOzXmA1L37Qmt3QB
# FCdJVigjQMuHcrJsWd8rg857Og0un91tfZIxggH0MIIB8AIBATBCMC4xLDAqBgNV
# BAMMI1VuaXR5LUNsYXVkZS1BdXRvbWF0aW9uLURldmVsb3BtZW50AhB1HRbZIqgr
# lUTwkh3hnGtFMA0GCWCGSAFlAwQCAQUAoIGEMBgGCisGAQQBgjcCAQwxCjAIoAKA
# AKECgAAwGQYJKoZIhvcNAQkDMQwGCisGAQQBgjcCAQQwHAYKKwYBBAGCNwIBCzEO
# MAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIAPVP+93c/TLwM99o515CA25
# wt9bysyYoR8VIwzI7DqGMA0GCSqGSIb3DQEBAQUABIIBAGwZVgAvb623/HvrFTkQ
# VsA6P+i0TtYpjTf/LghV3Si6hLjGP0ZS0aJiTPaHfFrhQmqE+rahb1v5hDEs/7Uj
# xEtjQsjzHxuZuJ7PtoSsdaMPO/gwv5GoWZa+PtvGY4UGg4ssXWwUJ2uSlP7AJ2gH
# LwcDVclChkyCVI6EF5HW5RfehpUBhWLKxCswLzU7QBcz3F1FS/t8zku+Nf3JzP72
# kp7LujgIzypG58MPTguiHDGp9DEdI9k/n1oM1Np6tsN/RnHAeR4BUmAYYDeLBRlG
# xfVLhsJFzc+k8051x3onjNUCiH12YafeMd6dg/UJybF5dVcgSvXfaHJR6apHIz+e
# jmg=
# SIG # End signature block
