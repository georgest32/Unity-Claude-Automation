# Unity-Claude-Automation

An advanced PowerShell automation system for integrating Unity compilation error handling with Claude AI, featuring autonomous monitoring, GitHub issue tracking, and Windows Event Log integration.

## Features

### Core Functionality
- **Unity Error Detection**: Monitors Unity Editor logs for compilation errors in real-time
- **Claude AI Integration**: Automatically submits errors to Claude for analysis and solutions
- **Autonomous Monitoring**: Self-healing system with circuit breakers and automatic recovery
- **GitHub Issue Management**: Creates and manages GitHub issues for Unity errors with deduplication

### Advanced Features
- **Windows Event Log Integration**: Enterprise-grade logging and monitoring
- **Real-time Dashboard**: Web-based monitoring dashboard with performance metrics
- **PowerShell 7 Support**: Full compatibility with PowerShell Core
- **Modular Architecture**: Extensible module system for custom functionality

## System Requirements

- Windows 10/11 or Windows Server 2019+
- PowerShell 5.1 or PowerShell 7+
- Unity Editor 2019.4 LTS or newer
- Claude API access (for API mode) or Claude Code CLI (for CLI mode)
- GitHub account with Personal Access Token (for issue tracking)

## Installation

1. Clone the repository:
```powershell
git clone https://github.com/yourusername/Unity-Claude-Automation.git
cd Unity-Claude-Automation
```

2. Import the main module:
```powershell
Import-Module .\Modules\Unity-Claude-Core\Unity-Claude-Core.psd1
```

3. Configure GitHub integration (optional):
```powershell
.\Setup-GitHubIntegration.ps1
```

## Quick Start

### Basic Error Monitoring
```powershell
# Start monitoring Unity errors
.\Start-UnityClaudeAutomation.ps1
```

### Autonomous Monitoring
```powershell
# Start autonomous monitoring with self-healing
.\Start-AutonomousMonitoring.ps1
```

### Dashboard Monitoring
```powershell
# Start the web dashboard on port 8080
.\Start-EnhancedDashboard.ps1 -Port 8080
```

## Directory Structure

### 📁 API-Integration
Claude API direct integration scripts for true background automation

### 📁 CLI-Automation
Scripts that interact with Claude Code CLI using SendKeys and window automation

### 📁 Modules
PowerShell modules for the automation system:
- Unity-Claude-Core: Core automation functionality
- Unity-Claude-Errors: Error tracking and database
- Unity-Claude-SystemStatus: System monitoring
- Unity-Claude-GitHub: GitHub integration
- Unity-Claude-EventLog: Windows Event Log integration
- Unity-Claude-AutonomousAgent: Self-healing automation

### 📁 Export-Tools
Scripts for exporting and formatting Unity errors for Claude analysis

### 📁 Monitoring
Real-time error monitoring and automatic submission tools

### 📁 Testing
Test scripts and validation tools

### 📁 Research
Research documents and findings from automation investigation

### 📁 Documentation
README files and documentation for the system

### 📁 Logs
Error exports and automation logs

### 📁 ClaudeResponses
Saved responses from Claude API calls

## Configuration

Configuration files are stored in JSON format:
- `systemstatus.config.json`: System monitoring configuration
- `github.config.json`: GitHub integration settings
- `automation.config.json`: Core automation settings

## Testing

Run the comprehensive test suite:
```powershell
.\Testing\Test-UnityClaudeModules.ps1
.\Test-GitHubIntegration.ps1 -AllTests
.\Test-EventLogIntegration.ps1 -AllTests
```

## Documentation

### Building Documentation

The project uses MkDocs with Material theme for documentation. To work with documentation:

#### Using Wrapper Scripts (Recommended)

We provide PowerShell wrapper scripts that automatically use the correct virtual environment versions:

```powershell
# Build documentation locally
.\mkdocs.ps1 build

# Serve documentation for preview (hot-reload enabled)
.\mkdocs.ps1 serve

# Deploy versioned documentation
.\mike.ps1 deploy 1.0 latest --push
.\mike.ps1 set-default latest

# List deployed versions
.\mike.ps1 list
```

#### When to Use These Wrappers

- **Always use wrappers** instead of direct `mkdocs` or `mike` commands
- They ensure you're using the virtual environment versions (avoiding conflicts)
- No need to activate virtual environment manually
- Prevents Python dependency issues between projects

#### Direct Virtual Environment Method (Alternative)

If you prefer working directly in the virtual environment:

```powershell
# Activate virtual environment
.\.venv\Scripts\Activate.ps1

# Now use mkdocs/mike directly
mkdocs build
mike deploy 1.0 latest
```

### Testing Documentation

```powershell
# Run documentation CI/CD tests
.\Test-DocumentationCICD.ps1 -TestType All

# Test only build
.\Test-DocumentationCICD.ps1 -TestType Build

# Test quality checks
.\Test-DocumentationCICD.ps1 -TestType Quality
```

## Contributing

Contributions are welcome! Please read our contributing guidelines for details.

## License

This project is licensed under the MIT License.

## Project Status

Current Version: 2.0.0
Status: Active Development
Last Updated: August 2025

### Recent Updates
- Added GitHub Issue Management System
- Implemented Windows Event Log integration
- PowerShell 7 migration completed
- Enhanced autonomous monitoring with circuit breakers
- Real-time web dashboard with performance metrics
