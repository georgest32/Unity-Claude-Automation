# Create-RemainingDocs.ps1
# Creates all remaining documentation files with basic content

$docsToCreate = @(
    # User Guide
    @{Path="docs\user-guide\unity-automation.md"; Title="Unity Automation"},
    @{Path="docs\user-guide\claude-integration.md"; Title="Claude Integration"},
    @{Path="docs\user-guide\system-monitoring.md"; Title="System Status Monitoring"},
    @{Path="docs\user-guide\dashboard.md"; Title="Dashboard"},
    @{Path="docs\user-guide\notifications.md"; Title="Notifications"},
    
    # Modules
    @{Path="docs\modules\overview.md"; Title="Modules Overview"},
    @{Path="docs\modules\system-status.md"; Title="Unity-Claude-SystemStatus Module"},
    @{Path="docs\modules\configuration.md"; Title="Unity-Claude-Configuration Module"},
    @{Path="docs\modules\event-log.md"; Title="Unity-Claude-EventLog Module"},
    @{Path="docs\modules\github.md"; Title="Unity-Claude-GitHub Module"},
    @{Path="docs\modules\notification-hub.md"; Title="Unity-Claude-NotificationHub Module"},
    @{Path="docs\modules\repo-analyst.md"; Title="Unity-Claude-RepoAnalyst Module"},
    
    # API Reference - PowerShell
    @{Path="docs\api\powershell\core.md"; Title="Core Functions"},
    @{Path="docs\api\powershell\system-status.md"; Title="System Status API"},
    @{Path="docs\api\powershell\unity-commands.md"; Title="Unity Commands"},
    @{Path="docs\api\powershell\monitoring.md"; Title="Monitoring API"},
    @{Path="docs\api\powershell\configuration.md"; Title="Configuration API"},
    
    # API Reference - Python
    @{Path="docs\api\python\doc-parser.md"; Title="Documentation Parser"},
    @{Path="docs\api\python\static-analysis.md"; Title="Static Analysis"},
    
    # API Reference - REST
    @{Path="docs\api\rest\endpoints.md"; Title="REST API Endpoints"},
    @{Path="docs\api\rest\websocket.md"; Title="WebSocket API"},
    
    # Advanced Topics
    @{Path="docs\advanced\multi-agent.md"; Title="Multi-Agent Architecture"},
    @{Path="docs\advanced\parallel-processing.md"; Title="Parallel Processing"},
    @{Path="docs\advanced\event-driven.md"; Title="Event-Driven Patterns"},
    @{Path="docs\advanced\performance.md"; Title="Performance Optimization"},
    @{Path="docs\advanced\security.md"; Title="Security"},
    
    # Development
    @{Path="docs\development\contributing.md"; Title="Contributing Guide"},
    @{Path="docs\development\testing.md"; Title="Testing"},
    @{Path="docs\development\ci-cd.md"; Title="CI/CD"},
    @{Path="docs\development\code-style.md"; Title="Code Style"},
    
    # Resources
    @{Path="docs\resources\learnings.md"; Title="Important Learnings"},
    @{Path="docs\resources\troubleshooting.md"; Title="Troubleshooting"},
    @{Path="docs\resources\faq.md"; Title="FAQ"},
    @{Path="docs\resources\glossary.md"; Title="Glossary"},
    
    # About
    @{Path="docs\about\license.md"; Title="License"},
    @{Path="docs\about\changelog.md"; Title="Changelog"},
    @{Path="docs\about\roadmap.md"; Title="Roadmap"},
    @{Path="docs\about\team.md"; Title="Team"}
)

$templateContent = @'
# {TITLE}

## Overview

This page provides documentation for {TITLE}.

## Description

{TITLE} is a component of the Unity-Claude-Automation system.

## Features

- Feature 1
- Feature 2
- Feature 3

## Usage

```powershell
# Example usage
```

## Examples

### Example 1

```powershell
# Code example
```

## Configuration

Configuration options for this component.

## API Reference

### Functions

| Function | Description |
|----------|-------------|
| Function1 | Description |
| Function2 | Description |

## Related Documentation

- [Home](../index.md)
- [User Guide](../user-guide/overview.md)
- [Getting Started](../getting-started/installation.md)

## Notes

!!! info
    This is placeholder documentation. Content will be updated with actual implementation details.

---

*Last updated: 2025-08-23*
'@

$created = 0
$skipped = 0

foreach ($doc in $docsToCreate) {
    $fullPath = Join-Path $PSScriptRoot $doc.Path
    
    if (Test-Path $fullPath) {
        Write-Host "Skipping (exists): $($doc.Path)" -ForegroundColor Yellow
        $skipped++
    }
    else {
        # Create directory if it doesn't exist
        $dir = Split-Path $fullPath -Parent
        if (!(Test-Path $dir)) {
            New-Item -Path $dir -ItemType Directory -Force | Out-Null
        }
        
        # Create file with template content
        $content = $templateContent -replace '{TITLE}', $doc.Title
        Set-Content -Path $fullPath -Value $content -Encoding UTF8
        Write-Host "Created: $($doc.Path)" -ForegroundColor Green
        $created++
    }
}

Write-Host "`nSummary:" -ForegroundColor Cyan
Write-Host "  Created: $created files" -ForegroundColor Green
Write-Host "  Skipped: $skipped files" -ForegroundColor Yellow
Write-Host "`nDocumentation structure complete!" -ForegroundColor Green