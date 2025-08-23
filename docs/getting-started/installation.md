# Installation Guide

## Prerequisites

Before installing Unity-Claude-Automation, ensure you have the following:

### Required Software

- **PowerShell**: Version 5.1 or later (PowerShell 7.5+ recommended)
- **Python**: Version 3.10 or later (for documentation generation)
- **Git**: For repository management
- **Unity**: 2021.3 LTS or later

### Development Tools

- **ripgrep**: Fast search tool
  ```powershell
  choco install ripgrep
  ```

- **universal-ctags** (Optional): For code indexing
  ```powershell
  choco install universal-ctags
  ```

## Installation Steps

### 1. Clone the Repository

```powershell
git clone https://github.com/Unity-Claude-Automation/Unity-Claude-Automation.git
cd Unity-Claude-Automation
```

### 2. Set PowerShell Execution Policy

```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

### 3. Install PowerShell Modules

```powershell
# Import the main module
Import-Module .\Modules\Unity-Claude-SystemStatus\Unity-Claude-SystemStatus.psd1

# Import additional modules
Import-Module .\Modules\Unity-Claude-Configuration\Unity-Claude-Configuration.psd1
Import-Module .\Modules\Unity-Claude-GitHub\Unity-Claude-GitHub.psd1
```

### 4. Configure Unity Project Path

```powershell
# Set your Unity project path
$env:UNITY_PROJECT_PATH = "C:\Path\To\Your\Unity\Project"

# Register Unity project
Register-UnityProject -ProjectPath $env:UNITY_PROJECT_PATH
```

### 5. Install Documentation Tools (Optional)

For documentation generation:

```powershell
# Create Python virtual environment
python -m venv .venv
.\.venv\Scripts\Activate.ps1

# Install MkDocs and dependencies
pip install -r requirements.txt
```

## Configuration

### Basic Configuration

Create a configuration file:

```powershell
# Initialize configuration
Initialize-UnityClaudeConfig

# Set basic parameters
Set-UnityClaudeParameter -Key "MonitoringInterval" -Value 30
Set-UnityClaudeParameter -Key "EnableNotifications" -Value $true
```

### GitHub Integration (Optional)

```powershell
# Set GitHub PAT
$pat = Read-Host "Enter GitHub PAT" -AsSecureString
Set-GitHubIntegrationConfig -PAT $pat -Owner "YourGitHubOrg" -Repo "YourRepo"
```

### Email Notifications (Optional)

```powershell
# Configure email settings
.\Configure-NotificationSettings.ps1
```

## Verification

Verify the installation:

```powershell
# Test system status module
Test-SystemStatusModule

# Check all modules
Get-Module Unity-Claude-* | Format-Table Name, Version

# Run basic health check
Get-SystemHealthScore
```

## Quick Start

Start the automation system:

```powershell
# Start autonomous monitoring
.\Start-UnityClaudeAutomation.ps1

# Or start with dashboard
.\Start-EnhancedDashboard.ps1
```

## Troubleshooting

### Common Issues

1. **Module Import Errors**
   ```powershell
   # Reload modules
   Remove-Module Unity-Claude-* -Force
   Import-Module .\Modules\Unity-Claude-SystemStatus\Unity-Claude-SystemStatus.psd1 -Force
   ```

2. **Unity Path Not Found**
   ```powershell
   # Verify Unity installation
   Test-Path $env:UNITY_PROJECT_PATH
   ```

3. **Python Environment Issues**
   ```powershell
   # Recreate virtual environment
   Remove-Item .venv -Recurse -Force
   python -m venv .venv
   ```

## Next Steps

- [Quick Start Tutorial](quick-start.md)
- [Configuration Guide](configuration.md)
- [User Guide](../user-guide/overview.md)