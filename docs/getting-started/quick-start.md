# Quick Start Guide

Welcome to Unity-Claude-Automation! This guide will help you get up and running quickly.

## Prerequisites

Before you begin, ensure you have:

- Windows 10/11 or Windows Server 2019+
- PowerShell 7.5+ installed
- Unity 2021.3 LTS or newer
- Git for version control
- Python 3.10+ (for documentation and analysis tools)

## Installation

If you haven't already, follow our [Installation Guide](installation.md) to set up the system.

## Basic Setup

### 1. Clone the Repository

```powershell
git clone https://github.com/your-org/Unity-Claude-Automation.git
cd Unity-Claude-Automation
```

### 2. Initialize the System

Run the initialization script:

```powershell
.\Initialize-UnityClaudeAutomation.ps1
```

This will:
- Check system requirements
- Install required PowerShell modules
- Configure initial settings
- Set up logging directories

### 3. Configure Unity Path

Set your Unity project path:

```powershell
Set-UnityProjectPath -Path "C:\UnityProjects\YourProject"
```

## Your First Automation

### Monitor Unity Errors

Start monitoring Unity compilation errors:

```powershell
Start-UnityErrorMonitor
```

The system will:
- Watch the Unity Editor log
- Detect compilation errors
- Generate fix suggestions
- Optionally create GitHub issues

### Run a Test Build

Execute an automated Unity build:

```powershell
Invoke-UnityBuild -BuildTarget StandaloneWindows64 -OutputPath ".\Builds"
```

## Key Commands

| Command | Description |
|---------|------------|
| `Start-UnityClaudeAutomation` | Start the main automation system |
| `Get-UnityProjectStatus` | Check current project status |
| `Start-UnityErrorMonitor` | Monitor Unity errors in real-time |
| `Get-ClaudeResponse` | Get AI suggestions for errors |
| `New-GitHubIssue` | Create issue from Unity error |

## Next Steps

- Read the [Configuration Guide](configuration.md) to customize settings
- Explore the [User Guide](../user-guide/overview.md) for detailed features
- Check [Architecture](architecture.md) to understand the system design

## Getting Help

- Check our [FAQ](../resources/faq.md)
- Visit [Troubleshooting](../resources/troubleshooting.md) for common issues
- Open an issue on GitHub for bugs or feature requests

## Quick Tips

!!! tip "Enable Auto-Fix"
    Set `$env:UNITY_CLAUDE_AUTOFIX = "true"` to automatically apply suggested fixes.

!!! info "Dashboard Access"
    Access the web dashboard at `http://localhost:8080` after starting the system.

!!! warning "First Run"
    The first run may take longer as the system indexes your project structure.