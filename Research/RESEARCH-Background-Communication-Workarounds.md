# Research: Background Communication Workarounds for Claude Code CLI
## Date: 2025-08-16

## Problem Statement
Claude Code CLI v1.0.53 doesn't support piped input due to using Ink (React for terminals) which requires raw mode. This prevents background automation without window switching.

## Research Findings (Queries 1-5)

### 1. Node.js Child Process Spawn for Interactive CLI
**Key Finding**: Node.js supports multiple methods for spawning child processes with IPC communication.

**Relevant Solutions**:
- `child_process.fork()` creates Node processes with built-in IPC channel for message passing
- `stdio: "ignore"` option prevents stdin blocking in parent process
- Stream-based communication allows processing large data without memory issues
- IPC channels enable bidirectional communication between parent/child processes

**Potential Application**: Create a Node.js wrapper that spawns Claude CLI and manages communication via IPC.

### 2. Windows Named Pipes IPC
**Key Finding**: Node.js net module supports Windows named pipes for IPC, but PowerShell's web cmdlets don't natively support them.

**Technical Details**:
- Windows named pipes: `\\.\pipe\pipename_here`
- Node.js can create named pipe servers and clients
- PowerShell lacks native support but can use .NET APIs
- Cross-platform solution (named pipes on Windows, Unix sockets on Linux)

**Limitation**: PowerShell `Invoke-WebRequest` doesn't support named pipes as of 2024, requiring workarounds.

### 3. Terminal Multiplexers (tmux/screen/ConEmu)
**Key Finding**: Terminal multiplexers can maintain persistent sessions and decouple processes from terminals.

**Windows Options**:
- **ConEmu/Cmder**: Native Windows terminal multiplexer with GUI
- **WSL2 + tmux**: Full Unix-like multiplexing through Windows Subsystem for Linux
- **Windows Terminal + PowerShell Jobs**: Basic background process management

**Benefits**:
- Processes continue running when detached
- Can reattach to sessions later
- Synchronized commands across multiple terminals

### 4. AutoHotkey SendMessage/PostMessage
**Key Finding**: AutoHotkey can send messages to background windows without focus.

**Technical Implementation**:
- `PostMessage`: Non-blocking, sends to message queue
- `SendMessage`: Blocking, waits for response
- Works with background/hidden windows
- Message codes: `0x0111` (WM_COMMAND), `0x100` (WM_KEYDOWN)

**Limitations**:
- Success varies by application architecture (C/C++ best, VB/Delphi problematic)
- Risk of crashing target application if wrong message sent
- Requires finding correct message values for each application

### 5. Claude API Direct Access
**Key Finding**: Claude offers a REST API with API keys for programmatic access.

**API Details**:
- Endpoint-based access (not CLI)
- $5 free credits for testing
- Supports Claude 3.5 Sonnet, Haiku, and Opus models
- Standard HTTP requests (cURL, PowerShell Invoke-RestMethod)
- Pricing: $3/million input tokens, $15/million output tokens

**PowerShell Integration**: Can use `Invoke-RestMethod` for direct API calls, bypassing CLI entirely.

## Promising Workaround Approaches

### Option 1: Direct API Integration (Most Reliable)
- Skip Claude Code CLI entirely
- Use PowerShell `Invoke-RestMethod` with API key
- True background operation, no window switching
- Cost: API usage fees after free credits

### Option 2: Node.js IPC Wrapper
- Create Node.js application that spawns Claude CLI
- Use fork() with IPC channels for communication
- PowerShell communicates with Node.js wrapper
- Complexity: Requires Node.js development

### Option 3: Terminal Multiplexer Automation
- Use ConEmu/WSL2+tmux for persistent sessions
- Detach/reattach as needed
- PowerShell controls multiplexer via commands
- Limitation: Still requires initial setup

### Option 4: AutoHotkey Background Messaging
- Use PostMessage to send to Claude window
- No focus required
- Risk: May not work reliably with Electron/Node apps

## Next Research Areas
- Virtual desktop automation
- Windows UI Automation API
- Electron app debugging/injection
- WebSocket/HTTP server creation
- Process memory manipulation