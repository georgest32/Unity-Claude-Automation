# Configuration Guide

This guide covers all configuration options for Unity-Claude-Automation.

## Configuration Files

The system uses multiple configuration files:

- `config.json` - Main configuration
- `unity-settings.json` - Unity-specific settings
- `claude-config.json` - Claude API settings
- `github-config.json` - GitHub integration settings

## Main Configuration

### Location

Configuration files are stored in:
```
%APPDATA%\Unity-Claude-Automation\Config\
```

### Basic Settings

```json
{
  "system": {
    "logLevel": "Information",
    "maxLogFiles": 30,
    "enableTelemetry": false,
    "parallelProcessing": true
  },
  "unity": {
    "projectPath": "C:\\UnityProjects\\YourProject",
    "editorPath": "C:\\Program Files\\Unity\\Hub\\Editor\\2021.3.16f1\\Editor\\Unity.exe",
    "logPath": "%LOCALAPPDATA%\\Unity\\Editor\\Editor.log",
    "buildTimeout": 3600
  },
  "monitoring": {
    "pollInterval": 5000,
    "enableFileWatcher": true,
    "autoRestartOnCrash": true
  }
}
```

## Environment Variables

Set these environment variables to override defaults:

| Variable | Description | Default |
|----------|-------------|---------|
| `UNITY_CLAUDE_CONFIG` | Config directory path | `%APPDATA%\Unity-Claude-Automation` |
| `UNITY_PROJECT_PATH` | Unity project location | Current directory |
| `UNITY_EDITOR_LOG` | Unity Editor log path | Auto-detected |
| `CLAUDE_API_KEY` | Claude API key | Required for AI features |
| `GITHUB_PAT` | GitHub Personal Access Token | Required for GitHub integration |

## PowerShell Module Configuration

### Import Modules

```powershell
Import-Module Unity-Claude-SystemStatus
Import-Module Unity-Claude-Configuration
Import-Module Unity-Claude-GitHub
```

### Set Configuration Values

```powershell
# Set Unity project path
Set-UnityClaudeConfig -Key "UnityProjectPath" -Value "C:\MyProject"

# Configure monitoring interval
Set-UnityClaudeConfig -Key "MonitoringInterval" -Value 10

# Enable auto-fix mode
Set-UnityClaudeConfig -Key "AutoFixEnabled" -Value $true
```

## Claude Integration Settings

### API Configuration

```powershell
# Set Claude API key
Set-ClaudeAPIKey -Key "your-api-key-here"

# Configure Claude model
Set-ClaudeConfig -Model "claude-3-opus-20240229" `
                -MaxTokens 4096 `
                -Temperature 0.7
```

### Prompt Templates

Customize AI prompts in `prompt-templates.json`:

```json
{
  "errorAnalysis": "Analyze this Unity error and suggest a fix: {error}",
  "codeReview": "Review this Unity C# code for best practices: {code}",
  "optimization": "Suggest performance optimizations for: {context}"
}
```

## GitHub Integration

### Repository Settings

```powershell
# Configure GitHub repository
Set-GitHubConfig -Owner "your-org" `
                 -Repo "your-repo" `
                 -PAT $env:GITHUB_PAT

# Set issue labels
Set-GitHubLabels -ErrorLabel "unity-error" `
                 -AutoLabel "auto-generated" `
                 -PriorityLabels @("critical", "high", "medium", "low")
```

### Issue Templates

Configure issue templates in `.github/ISSUE_TEMPLATE/`:

```yaml
name: Unity Compilation Error
about: Auto-generated from Unity compilation errors
title: '[Unity Error] {error_type}'
labels: ['unity-error', 'auto-generated']
body:
  - type: markdown
    attributes:
      value: |
        ## Error Details
        **File**: {file_path}
        **Line**: {line_number}
        **Error**: {error_message}
```

## Notification Settings

### Email Notifications

```powershell
Set-NotificationConfig -EnableEmail $true `
                       -SmtpServer "smtp.gmail.com" `
                       -SmtpPort 587 `
                       -FromEmail "automation@example.com" `
                       -ToEmail "team@example.com"
```

### Webhook Notifications

```powershell
# Configure Slack webhook
Set-WebhookConfig -Type "Slack" `
                  -Url "https://hooks.slack.com/services/YOUR/WEBHOOK/URL"

# Configure Discord webhook
Set-WebhookConfig -Type "Discord" `
                  -Url "https://discord.com/api/webhooks/YOUR/WEBHOOK"
```

## Dashboard Configuration

### Web Dashboard Settings

```json
{
  "dashboard": {
    "port": 8080,
    "host": "localhost",
    "enableAuth": false,
    "refreshInterval": 5000,
    "theme": "dark"
  }
}
```

### Start Dashboard

```powershell
Start-UnityClaudeDashboard -Port 8080 -Theme "dark"
```

## Performance Tuning

### Parallel Processing

```powershell
# Configure parallel processing
Set-ParallelConfig -MaxDegreeOfParallelism 4 `
                   -ThrottleLimit 10
```

### Memory Management

```powershell
# Set memory limits
Set-MemoryConfig -MaxMemoryGB 8 `
                 -GCMode "Workstation"
```

## Security Configuration

### API Key Storage

Store API keys securely:

```powershell
# Store API key in Windows Credential Manager
Set-SecureCredential -Name "ClaudeAPIKey" -Value "your-key"
Set-SecureCredential -Name "GitHubPAT" -Value "your-pat"
```

### Access Control

```powershell
# Restrict access to configuration
Set-ConfigAccess -ReadOnly $false `
                 -RequireElevation $true
```

## Logging Configuration

### Log Levels

- `Verbose` - All messages
- `Debug` - Debug and above
- `Information` - Info and above
- `Warning` - Warnings and errors
- `Error` - Only errors

### Configure Logging

```powershell
Set-LogConfig -Level "Information" `
              -MaxFiles 30 `
              -MaxSizeMB 100 `
              -ArchivePath ".\Logs\Archive"
```

## Validation

Validate your configuration:

```powershell
Test-UnityClaudeConfiguration -Verbose
```

This will check:
- File paths exist
- API keys are valid
- Network connectivity
- Required permissions

## Backup and Restore

### Backup Configuration

```powershell
Backup-UnityClaudeConfig -Path ".\Backups\config-backup.zip"
```

### Restore Configuration

```powershell
Restore-UnityClaudeConfig -Path ".\Backups\config-backup.zip"
```

## Next Steps

- Review [Architecture](architecture.md) to understand system design
- Check [User Guide](../user-guide/overview.md) for usage examples
- See [Troubleshooting](../resources/troubleshooting.md) for common issues