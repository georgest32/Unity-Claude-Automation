# Testing Unity-Claude Bidirectional Communication

## Quick Start

To test the bidirectional communication module, you need to run the server in one window and the tests in another.

### Step 1: Start the Test Server (in PowerShell Window #1)
```powershell
cd C:\UnityProjects\Sound-and-Shoal\Unity-Claude-Automation
.\Start-TestServer.ps1
```

This will start:
- HTTP API server on port 5556
- Message queue system
- Request handler

Keep this window open while running tests.

### Step 2: Run Tests (in PowerShell Window #2)
```powershell
cd C:\UnityProjects\Sound-and-Shoal\Unity-Claude-Automation
.\Testing\Test-BidirectionalCommunication.ps1
```

## Individual Test Options

### Test only Named Pipes
```powershell
.\Testing\Test-BidirectionalCommunication.ps1 -TestNamedPipes
```

### Test only HTTP API
```powershell
.\Testing\Test-BidirectionalCommunication.ps1 -TestHttpApi
```
**Note**: Requires Start-TestServer.ps1 running

### Test only Queues
```powershell
.\Testing\Test-BidirectionalCommunication.ps1 -TestQueues
```

## Expected Results

### Named Pipes (3 tests)
- ✅ Start Named Pipe Server
- ✅ Send Message to Pipe  
- ⚠️ Get Pipe Status (returns simple format, not JSON)

### HTTP API (4 tests)
- ✅ Start HTTP API Server
- ✅ HTTP Health Check
- ✅ HTTP Status Endpoint
- ✅ Submit Error via API

### Queue Management (6 tests)
- ✅ Initialize Message Queues
- ✅ Add Message to Queue
- ✅ Get Queue Status
- ✅ Get Next Message
- ✅ Clear Message Queue
- ✅ Wait for Message (timeout test)

## Troubleshooting

### HTTP tests fail with timeout
Make sure Start-TestServer.ps1 is running in another PowerShell window.

### Named pipe tests hang
The async pipe implementation uses background jobs. If a test hangs:
1. Press Ctrl+C to stop the test
2. Run: `Get-Job | Stop-Job; Get-Job | Remove-Job`
3. Try again

### Port already in use
If port 5556 is already in use, you can change it:
```powershell
# Start server on different port
.\Start-TestServer.ps1 -HttpPort 5557

# Update test to use same port (edit the test file)
```

## Manual Testing

### Test HTTP API with curl
```bash
curl http://localhost:5556/api/health
curl http://localhost:5556/api/status
```

### Test with PowerShell
```powershell
Invoke-RestMethod http://localhost:5556/api/health
Invoke-RestMethod http://localhost:5556/api/status
```

### Test Named Pipe
```powershell
# In one window
Import-Module Unity-Claude-IPC-Bidirectional
Start-NamedPipeServer -PipeName "TestManual" -Async

# In another window  
Import-Module Unity-Claude-IPC-Bidirectional
Send-PipeMessage -PipeName "TestManual" -Message "PING:Test"
```