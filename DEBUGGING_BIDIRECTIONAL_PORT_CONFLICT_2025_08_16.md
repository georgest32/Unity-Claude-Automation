# Debugging: Bidirectional Communication Port Conflict
Date: 2025-08-16
Status: RESOLVED

## Problem Summary
Test-BidirectionalCommunication.ps1 was failing with port conflict error when Start-TestServer.ps1 was already running on port 5556.

## Root Cause Analysis
1. **Port Conflict**: Test tried to start its own HTTP server on port 5556
2. **Design Flaw**: Test shouldn't start server if external server is running
3. **Background Job Limitation**: PowerShell jobs can't properly handle HTTP listeners

## Error Details
```
Start-HttpApiServer : Failed to start HTTP server: Exception calling "Start" with "0" argument(s):
"Failed to listen on prefix 'http://localhost:5556/' because it conflicts with an existing
registration on the machine."
```

## Solution Implemented

### 1. Fixed HTTP API Test
Changed from starting a new server to checking if external server exists:
```powershell
Test-Function "Check HTTP API Server" {
    # Don't start a new server - check if external server is running
    try {
        $response = Invoke-WebRequest -Uri "http://localhost:5556/api/health" -Method Head -TimeoutSec 2 -UseBasicParsing
        $response.StatusCode -eq 200
    } catch {
        Write-Host "    Note: Start-TestServer.ps1 should be running on port 5556" -ForegroundColor Yellow
        $false
    }
}
```

### 2. Server Management Uses Different Port
Server management tests already use port 5557 to avoid conflicts

### 3. Fixed Status Check
Updated Combined Server Status test to check for pipe jobs instead of servers

## Test Results After Fix

### Named Pipes (3 tests)
- ✅ Start Named Pipe Server
- ✅ Send Message to Pipe
- ❌ Get Pipe Status (returns simple format, needs JSON update)

### HTTP API (4 tests)  
- ✅ Check HTTP API Server
- ✅ HTTP Health Check
- ✅ HTTP Status Endpoint
- ✅ Submit Error via API

### Queue Management (6 tests)
- ✅ All 6 tests passing

### Server Management (4 tests)
- ✅ Start All Servers (port 5557)
- ✅ Combined Server Status
- ✅ Stop All Servers
- ✅ Verify Servers Stopped

## Usage Instructions

### Three-Window Setup
1. **Window #1**: Claude Code CLI (this window)
2. **Window #2**: Test runner
3. **Window #3**: Test server

### Starting the Test Server (Window #3)
```powershell
cd C:\UnityProjects\Sound-and-Shoal\Unity-Claude-Automation
.\Start-TestServer.ps1
```

### Running Tests (Window #2)
```powershell
cd C:\UnityProjects\Sound-and-Shoal\Unity-Claude-Automation
.\Testing\Test-BidirectionalCommunication.ps1
```

## Key Learnings
1. PowerShell background jobs can't properly handle HTTP listeners
2. Tests should detect external servers, not always start their own
3. Use different ports for different test scenarios to avoid conflicts
4. Document window setup clearly for multi-window testing

## Files Modified
- Test-BidirectionalCommunication.ps1 - Fixed port conflict, added timeout
- Unity-Claude-IPC-Bidirectional.psm1 - Simplified implementation
- Start-TestServer.ps1 - Created standalone server for testing

## Next Steps
1. Update Get Pipe Status to return JSON format
2. Consider WebSocket implementation for Phase 3
3. Add automated port detection to avoid hardcoded ports

RECOMMENDED: Continue Implementation - Phase 3 Self-Improvement Mechanism with pattern recognition