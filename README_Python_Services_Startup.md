# Enhanced System Startup with Python AI Services

The `Start-UnityClaudeSystem-Windowed.ps1` script has been enhanced to support Python AI service startup alongside the regular PowerShell subsystems.

## New Parameters

- **`-StartPythonServices`**: Start Python AI services (LangGraph and AutoGen) in separate windows
- **`-SkipLangGraph`**: Skip starting the LangGraph service (only when -StartPythonServices is used)
- **`-SkipAutoGen`**: Skip starting the AutoGen service (only when -StartPythonServices is used)

## Usage Examples

### Start with all Python services
```powershell
.\Start-UnityClaudeSystem-Windowed.ps1 -StartPythonServices
```

### Start with only LangGraph service
```powershell
.\Start-UnityClaudeSystem-Windowed.ps1 -StartPythonServices -SkipAutoGen
```

### Start with only AutoGen service
```powershell
.\Start-UnityClaudeSystem-Windowed.ps1 -StartPythonServices -SkipLangGraph
```

### Start with custom windowed subsystems and Python services
```powershell
.\Start-UnityClaudeSystem-Windowed.ps1 -StartPythonServices -WindowedSubsystems @('SystemMonitoring', 'CLIOrchestrator', 'RepoAnalyst')
```

## What It Does

1. **Automatic Python Detection**: Finds conda Python at `C:\Users\georg\miniconda3\python.exe` or falls back to system Python
2. **Service Windows**: Opens separate PowerShell windows for each Python service
3. **Health Checks**: Tests service health endpoints after startup
4. **Integration**: Fully integrated with existing manifest-based subsystem startup

## Python Services Started

### LangGraph Service (Port 8000)
- **Endpoint**: http://localhost:8000
- **Health Check**: http://localhost:8000/health
- **Features**: StateGraph workflows, SQLite checkpointing, HITL interrupts

### AutoGen Service (Port 8001)  
- **Endpoint**: http://localhost:8001
- **Health Check**: http://localhost:8001/health
- **Features**: Multi-agent conversations, code review, technical debt analysis

## Service Management

- Each Python service runs in its own PowerShell window with a descriptive title
- Services use the `--reload` flag for development convenience
- Window titles: "Unity-Claude Subsystem - LangGraph" and "Unity-Claude Subsystem - AutoGen"
- Services can be stopped by closing their respective windows

## Benefits

- **One Command Startup**: Start entire Unity-Claude-Automation system including Python AI services
- **Flexible Configuration**: Choose which services to start
- **Visual Management**: Each service in its own window for easy monitoring
- **Health Verification**: Automatic health checks ensure services are responding
- **Error Handling**: Proper error reporting if services fail to start

## Integration with Existing System

The Python service startup is fully integrated with the existing manifest-based subsystem architecture:

1. Python services start first (if requested)
2. Regular PowerShell subsystems start according to their dependency order
3. Final summary shows both PowerShell subsystems and Python services
4. All services run concurrently in separate windows

This enhancement makes it easy to start the complete AI-enhanced Unity-Claude-Automation environment with a single command.