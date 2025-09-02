# Unity-Claude Automation System User Guide
*Version 1.0.0 | Last Updated: 2025-08-23*

## Table of Contents
1. [Introduction](#introduction)
2. [Installation](#installation)
3. [Configuration](#configuration)
4. [Basic Usage](#basic-usage)
5. [Advanced Features](#advanced-features)
6. [Troubleshooting](#troubleshooting)
7. [API Reference](#api-reference)
8. [FAQ](#faq)

## Introduction

Unity-Claude Automation System is a comprehensive PowerShell-based automation framework designed to streamline Unity development workflows by automatically detecting, processing, and reporting Unity errors through multiple channels including GitHub issues, email notifications, and Windows Event Log.

### Key Features
- **Parallel Processing**: Multi-threaded error processing for improved performance
- **GitHub Integration**: Automatic issue creation and management
- **Email/Webhook Notifications**: Real-time alerts for critical errors
- **Event Log Integration**: Windows Event Log tracking for audit trails
- **Rate Limiting**: Intelligent API rate limit management
- **Error Deduplication**: Smart duplicate detection to prevent issue spam

### System Requirements
- Windows 10/11 or Windows Server 2016+
- PowerShell 5.1 or higher
- Unity 2019.4 LTS or newer
- .NET Framework 4.7.2 or higher
- GitHub account (for issue tracking)
- SMTP server access (for email notifications)

## Installation

### Step 1: Download the System
```powershell
# Clone the repository
git clone https://github.com/georgest32/Unity-Claude-Automation.git
cd Unity-Claude-Automation
```

### Step 2: Install Prerequisites
```powershell
# Run the installation script
.\Install-UnityClaudeAutomation.ps1

# Or manually install modules
Install-Module -Name Pester -Scope CurrentUser
Install-Module -Name PowerShellForGitHub -Scope CurrentUser # Optional
```

### Step 3: Verify Installation
```powershell
# Import and test the system
Import-Module ".\Modules\Unity-Claude-GitHub" -Force
Test-GitHubPAT
```

## Configuration

### GitHub Integration Setup

#### 1. Create Personal Access Token (PAT)
1. Go to GitHub Settings > Developer settings > Personal access tokens
2. Generate new token with scopes: `repo`, `workflow`, `read:org`
3. Copy the token (starts with `ghp_`)

#### 2. Configure PAT in System
```powershell
# Set your GitHub PAT
Set-GitHubPAT
# Enter token when prompted (hidden input)

# Verify configuration
Test-GitHubPAT
```

#### 3. Configure Repositories
```powershell
# Create configuration
$config = @{
    repositories = @{
        "yourusername/your-repo" = @{
            owner = "yourusername"
            name = "your-repo"
            isDefault = $true
            labels = @("unity", "automation")
        }
    }
}

Set-GitHubIntegrationConfig -Config $config
```

### Email Notification Setup

```powershell
# Configure email settings
$emailConfig = @{
    SmtpServer = "smtp.gmail.com"
    SmtpPort = 587
    UseSsl = $true
    From = "unity-automation@example.com"
    To = @("dev-team@example.com")
    Credential = Get-Credential  # Enter email credentials
}

Set-NotificationConfiguration -EmailConfig $emailConfig
```

### Event Log Configuration

```powershell
# Initialize Event Log integration
Initialize-EventLogIntegration -LogName "Unity-Claude" -Source "UnityAutomation"

# Test Event Log writing
Write-EventLogEntry -Message "Test entry" -EntryType Information
```

## Basic Usage

### Monitor Unity Errors

```powershell
# Start monitoring Unity Editor log
Start-UnityErrorMonitoring -ProjectPath "C:\UnityProjects\MyGame"

# Process existing error log
$errors = Get-UnityErrors -LogPath "C:\Users\$env:USERNAME\AppData\Local\Unity\Editor\Editor.log"
```

### Create GitHub Issues from Errors

```powershell
# Format and create issue for Unity error
$error = @{
    errorCode = "CS0246"
    message = "The type or namespace 'NetworkManager' could not be found"
    file = "Assets/Scripts/Player.cs"
    line = 42
}

$issue = Format-UnityErrorAsIssue -UnityError $error
New-GitHubIssue -Owner "yourusername" -Repository "your-repo" `
    -Title $issue.title -Body $issue.body -Labels $issue.labels
```

### Send Notifications

```powershell
# Send email notification for critical error
Send-UnityErrorNotification -Error $error -Priority "High" -Channel "Email"

# Send webhook notification
Send-WebhookNotification -Url "https://hooks.slack.com/services/..." -Payload $error
```

## Advanced Features

### Parallel Processing

```powershell
# Process multiple errors in parallel
$errors = Get-UnityErrors -LogPath $logPath
$results = Process-UnityErrorsParallel -Errors $errors -MaxThreads 5

# Monitor performance
$stats = Get-ProcessingStatistics
Write-Host "Processed $($stats.TotalErrors) errors in $($stats.Duration) seconds"
```

### Issue Lifecycle Management

```powershell
# Check issue status
$status = Get-GitHubIssueStatus -Owner "yourusername" -Repository "your-repo" -IssueNumber 123

# Auto-close resolved issues
Close-GitHubIssueIfResolved -Owner "yourusername" -Repository "your-repo" `
    -IssueNumber 123 -ErrorSignature "CS0246" -MinConfidence 0.8

# Update issue state
Update-GitHubIssueState -Owner "yourusername" -Repository "your-repo" `
    -IssueNumber 123 -State "closed" -Comment "Fixed in commit abc123"
```

### Rate Limit Management

```powershell
# Check API usage
$usage = Get-GitHubAPIUsageStats -IncludeHistory
Write-Host "API calls remaining: $($usage.Core.Remaining)/$($usage.Core.Limit)"

# Monitor rate limits
if ($usage.Core.PercentUsed -gt 80) {
    Write-Warning "Approaching GitHub API rate limit!"
}
```

### Custom Error Processing

```powershell
# Define custom error processor
$processor = {
    param($error)
    # Custom processing logic
    if ($error.errorCode -match "CS\d{4}") {
        # C# compilation error
        return Format-CompilationError -Error $error
    } else {
        # Runtime error
        return Format-RuntimeError -Error $error
    }
}

# Apply custom processor
Process-UnityErrors -Errors $errors -Processor $processor
```

## Troubleshooting

### Common Issues and Solutions

#### PAT Authentication Fails
```powershell
# Clear and reset PAT
Clear-GitHubPAT
Set-GitHubPAT

# Verify token permissions
Test-GitHubPAT -Verbose
```

#### Module Import Errors
```powershell
# Check execution policy
Get-ExecutionPolicy
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser

# Force module reload
Remove-Module Unity-Claude-* -Force -ErrorAction SilentlyContinue
Import-Module ".\Modules\Unity-Claude-GitHub" -Force -Verbose
```

#### Rate Limit Exceeded
```powershell
# Check when rate limit resets
$stats = Get-GitHubAPIUsageStats
$resetTime = $stats.Core.ResetTime
Write-Host "Rate limit resets at: $resetTime"

# Implement backoff strategy
Start-Sleep -Seconds 60
```

#### Event Log Access Denied
```powershell
# Run PowerShell as Administrator
# Create Event Log source
New-EventLog -LogName "Unity-Claude" -Source "UnityAutomation"
```

### Debug Mode

```powershell
# Enable verbose output
$VerbosePreference = "Continue"
$DebugPreference = "Continue"

# Run with detailed logging
Start-UnityErrorMonitoring -ProjectPath "C:\UnityProjects\MyGame" -Debug

# Check system logs
Get-Content ".\unity_claude_automation.log" -Tail 50
```

## API Reference

### Core Functions

#### Unity Error Processing
- `Get-UnityErrors` - Extract errors from Unity log
- `Format-UnityErrorAsIssue` - Format error for GitHub issue
- `Process-UnityErrorsParallel` - Process errors in parallel
- `Get-UnityErrorSignature` - Generate unique error signature

#### GitHub Integration
- `New-GitHubIssue` - Create new GitHub issue
- `Update-GitHubIssue` - Update existing issue
- `Search-GitHubIssues` - Search for issues
- `Test-GitHubIssueDuplicate` - Check for duplicate issues
- `Get-GitHubIssueStatus` - Get issue lifecycle status
- `Close-GitHubIssueIfResolved` - Auto-close resolved issues

#### Notifications
- `Send-UnityErrorNotification` - Send error notification
- `Send-EmailNotification` - Send email alert
- `Send-WebhookNotification` - Send webhook payload
- `Test-NotificationConfiguration` - Verify notification settings

#### System Management
- `Start-UnityErrorMonitoring` - Begin monitoring
- `Stop-UnityErrorMonitoring` - Stop monitoring
- `Get-ProcessingStatistics` - Get performance stats
- `Test-SystemHealth` - Check system status

## FAQ

### Q: How do I monitor multiple Unity projects?
A: Configure multiple repositories in your GitHub integration config:
```powershell
$config = @{
    repositories = @{
        "user/project1" = @{ ... }
        "user/project2" = @{ ... }
    }
}
```

### Q: Can I customize error detection patterns?
A: Yes, modify the error detection regex patterns in the configuration file or use custom processors.

### Q: How do I prevent duplicate GitHub issues?
A: The system automatically detects duplicates using similarity scoring. Adjust the threshold:
```powershell
$config.global.duplicateSimilarityThreshold = 0.8  # 80% similarity
```

### Q: What Unity versions are supported?
A: Unity 2019.4 LTS and newer. The system parses standard Unity log formats.

### Q: Can I use this without GitHub?
A: Yes, you can use email/webhook notifications and Event Log integration without GitHub.

### Q: How do I contribute to the project?
A: Submit pull requests to the GitHub repository following the contribution guidelines.

## Support

For additional support:
- GitHub Issues: https://github.com/georgest32/Unity-Claude-Automation/issues
- Documentation: https://github.com/georgest32/Unity-Claude-Automation/wiki
- Email: unity-claude-support@example.com

## License

MIT License - See LICENSE file for details

---

*Unity-Claude Automation System - Streamlining Unity Development Workflows*