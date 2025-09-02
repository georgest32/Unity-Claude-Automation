# Unity-Claude Automation Project Structure
*Complete folder hierarchy and organization for the Unity-Claude Automation System*
*Last Updated: 2025-01-19*

## 📁 Root Directory
```
C:\UnityProjects\Sound-and-Shoal\Unity-Claude-Automation\
│
├── 📁 API-Integration\        # Direct Claude API integration scripts
├── 📁 CLI-Automation\         # SendKeys-based CLI automation scripts  
├── 📁 ClaudeResponses\        # Saved API responses
├── 📁 Documentation\          # Project documentation
├── 📁 Export-Tools\           # Error export and formatting tools
├── 📁 Logs\                   # Error export logs
├── 📁 Modules\                # PowerShell module system
├── 📁 Monitoring\             # Real-time monitoring tools
├── 📁 Research\               # Research documents and findings
├── 📁 Testing\                # Test scripts and validation
├── #PROJECT_DOCUMENTS.txt     # Document tracking file
├── PROJECT_STRUCTURE.md       # This file
├── README.md                  # Main project documentation
└── *.ps1                      # Main automation scripts
```

## 📂 Detailed Structure

### API-Integration\
Direct Claude API communication without window switching
- `Setup-ClaudeAPI.ps1` - API key configuration
- `Submit-ErrorsToClaude-API.ps1` - Main API submission script
- `Submit-ErrorsToClaude-Direct.ps1` - Alternative direct submission

### CLI-Automation\
SendKeys-based automation for Claude Code CLI
- `Submit-ErrorsToClaude-Final.ps1` - Recommended SendKeys script
- Various experimental/legacy versions

### Modules\
PowerShell module architecture for code reusability
- `Unity-Claude-Core\` - Core automation functionality
- `Unity-Claude-Errors\` - Error tracking and database
- `Unity-Claude-IPC\` - Inter-process communication
- `Unity-Claude-AutonomousAgent\` - Autonomous Claude Code CLI feedback loop automation (v1.2.1 - 32 functions)
- `SafeCommandExecution\` - Constrained runspace security framework (v1.0.0 - 8 functions)
- `Unity-TestAutomation\` - Comprehensive Unity test automation (v1.0.0 - 9 functions)
- `Unity-Claude-SystemStatus\` - **ENHANCED**: System status monitoring with advanced logging, diagnostics, and performance monitoring (v1.1.0 - 41+ functions)
  - `Config\` - **NEW**: JSON configuration system with layered overrides and validation
    - `systemstatus.config.json` - Main configuration file
    - `systemstatus.config.schema.md` - Configuration documentation and schema
    - `examples\` - Environment-specific configuration examples (development, production, high-performance)
    - `CONFIGURATION_GUIDE.md` - Comprehensive configuration usage guide
    - `TROUBLESHOOTING.md` - Configuration troubleshooting and debugging guide
  - `Core\` - Core functionality including enhanced configuration loading and advanced logging/diagnostics:
    - `Get-SystemStatusConfiguration.ps1` - Enhanced configuration with logging and performance options
    - `Write-SystemStatusLog.ps1` - Enhanced logging with structured data and rotation support
    - `Invoke-LogRotation.ps1` - Automated log rotation with compression and retention management
    - `Enable-DiagnosticMode.ps1` - Comprehensive diagnostic mode with trace logging and performance monitoring
    - `Write-TraceLog.ps1` - Advanced trace logging framework with operation tracking
    - `Search-SystemStatusLogs.ps1` - High-performance log search and analysis tools
    - `New-DiagnosticReport.ps1` - HTML diagnostic report generation with performance analysis
  - `Execution\` - Enhanced circuit breaker with configuration-driven behavior (`Get-SubsystemCircuitBreakerConfig`)
  - `Monitoring\` - Health monitoring with configurable parameters and performance metrics:
    - `Get-SystemPerformanceMetrics.ps1` - Comprehensive performance counter monitoring with Get-Counter integration
  - `Parsing\` - Message parsing and classification
- `Unity-Claude-DocumentationAnalytics\` - **NEW**: Documentation Analytics and Optimization (v1.0.0 - Week 3 Day 13 Hour 7-8)
  - Research-validated documentation analytics with AI-enhanced optimization recommendations
  - 14 core content performance metrics including Time to First Hello World (TTFHW)
  - Usage pattern analysis, user journey tracking, and behavioral analytics
  - Content optimization engine with automated maintenance and cleanup procedures
  - Multi-format reporting (JSON, HTML, CSV) with cross-platform analytics capabilities
  - AI-powered recommendations using Ollama 34B integration for intelligent content optimization

### Export-Tools\
Scripts for exporting and formatting Unity errors
- `Export-ErrorsForClaude-Fixed.ps1` - Main export script
- `Export-ErrorsForClaude.ps1` - Original export script

### Monitoring\
Real-time error monitoring and automatic submission
- `Watch-AndReport-API.ps1` - API-based monitoring
- `Watch-AndReport.ps1` - CLI-based monitoring

### Testing\
Test scripts for validation and development
- `Test-UnityClaudeModules.ps1` - Module testing
- `Test-ClaudePiping.ps1` - CLI piping tests
- `Test-PredictiveAnalysis-LangGraph-Integration.ps1` - **COMPLETED**: Predictive Analysis LangGraph integration (100% success)
- `Test-MultiStepOrchestration.ps1` - **COMPLETED**: Multi-step orchestration framework validation
- `Test-LangGraph-Comprehensive.ps1` - **COMPLETED**: Comprehensive LangGraph integration testing (32 scenarios)
- `Test-AutoGenBasicConversation.ps1` - **NEW**: AutoGen multi-agent conversation testing
- `test_autogen_installation.py` - **NEW**: Python AutoGen installation verification
- `Test-Day18-Hour1-5-SubsystemDiscovery.ps1` - Day 18 subsystem discovery tests
- `Test-Day18-Hour2.5-CrossSubsystemCommunication.ps1` - IPC and messaging tests
- `Test-Day18-Hour3.5-ProcessHealthMonitoring.ps1` - Health monitoring tests
- `Test-Day18-Hour4.5-DependencyTrackingCascadeRestart.ps1` - Dependency cascade tests
- `Test-Day18-Hour5-SystemIntegrationValidation.ps1` - **NEW**: Final integration validation
- Various other test utilities

## 🔑 Key Files

### Main Scripts
- `unity_claude_automation.ps1` - Primary automation orchestrator
- `Unity-Claude-Automation.ps1` - Alternative main script

### AI Integration Scripts (Week 1 Implementation - 2025-08-29)
- `Unity-Claude-LangGraphBridge.psm1` - **COMPLETED**: PowerShell to LangGraph API integration (8 functions)
- `Unity-Claude-MultiStepOrchestrator.psm1` - **COMPLETED**: Multi-step orchestration framework (11 functions)
- `Unity-Claude-AutoGen.psm1` - **NEW**: AutoGen multi-agent coordination module (13 functions)
- `PowerShell-AutoGen-Terminal-Integration.ps1` - **NEW**: PowerShell terminal integration for AutoGen agents
- `MultiStep-Orchestrator-Workflows.json` - **COMPLETED**: Complex workflow definitions for AI-enhanced analysis
- `PredictiveAnalysis-LangGraph-Workflows.json` - **COMPLETED**: Workflow definitions for predictive analysis integration

### AI Integration Documentation (Week 1 Hour 7-8 - 2025-08-29)
- `LangGraph-Integration-Guide.md` - **NEW**: Comprehensive usage patterns and integration guidelines
- `LangGraph-Error-Handling-Recovery.md` - **NEW**: Production error handling and recovery procedures
- `LangGraph-Performance-Benchmarks-Optimization.md` - **NEW**: Performance targets and optimization strategies

### Documentation
- `README.md` - Project overview and quick start
- `Documentation\README-Automation.md` - Detailed automation guide
- `Documentation\README-MODULES.md` - Module system documentation

### Research
- `Research\RESEARCH-Final-Recommendations.md` - Consolidated findings
- Background communication workaround research documents

## 🎯 File Naming Conventions

### PowerShell Scripts
- `Verb-Noun.ps1` - Standard PowerShell cmdlet naming
- `Test-*.ps1` - Test scripts
- `Export-*.ps1` - Export utilities
- `Submit-*.ps1` - Submission scripts

### Documentation
- `README-*.md` - Specific readme files
- `RESEARCH-*.md` - Research documents
- `*_YYYYMMDD_HHMMSS.*` - Timestamped exports/logs

## 🔄 Workflow Paths

### API Workflow
1. `Setup-ClaudeAPI.ps1` - Configure API key
2. `Export-ErrorsForClaude-Fixed.ps1` - Export errors
3. `Submit-ErrorsToClaude-API.ps1` - Submit to Claude
4. Response saved to `ClaudeResponses\`

### CLI Workflow
1. Open Claude Code CLI manually
2. `Export-ErrorsForClaude-Fixed.ps1` - Export errors
3. `Submit-ErrorsToClaude-Final.ps1` - SendKeys automation
4. Manual interaction with Claude

### Module Development
1. Create module in `Modules\ModuleName\`
2. Write `.psm1` module file
3. Create `.psd1` manifest
4. Test with `Test-UnityClaudeModules.ps1`

## ⚠️ Important Notes

### API vs CLI
- **API**: Fully automated, background operation, requires API key
- **CLI**: Semi-automated, requires window switching, no API key needed

### Module System
- Modules use standard PowerShell module structure
- Each module has manifest (.psd1) and module file (.psm1)
- Modules are loaded dynamically by main scripts

### Error Handling
- All scripts include comprehensive error handling
- Errors logged to `Logs\` directory
- Export format optimized for Claude analysis

## 📊 Status Overview

| Component | Status | Notes |
|-----------|--------|-------|
| API Integration | ✅ Working | Fully functional with proper error handling |
| CLI Automation | ✅ Working | SendKeys fallback due to CLI limitations |
| Module System | 🔄 In Progress | Core modules created, testing needed |
| Export Tools | ✅ Working | Successfully exports Unity errors |
| Monitoring | 🔄 In Progress | Basic monitoring working, enhancements planned |
| Documentation | 🔄 In Progress | Core docs complete, script-level docs needed |

## 🚀 Quick Start Paths

### For API Users
```powershell
cd Unity-Claude-Automation
.\API-Integration\Setup-ClaudeAPI.ps1
.\API-Integration\Submit-ErrorsToClaude-API.ps1
```

### For CLI Users
```powershell
cd Unity-Claude-Automation
claude chat  # In separate window
.\CLI-Automation\Submit-ErrorsToClaude-Final.ps1
```

### For Developers
```powershell
cd Unity-Claude-Automation
.\Testing\Test-UnityClaudeModules.ps1
.\Testing\Run-ModuleTests.ps1
```