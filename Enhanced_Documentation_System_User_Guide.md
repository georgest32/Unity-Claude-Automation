# Enhanced Documentation System - User Guide

**Version:** 2.0.0  
**Date:** August 25, 2025  
**Status:** Production Ready  

## Table of Contents

1. [Overview](#overview)
2. [Quick Start](#quick-start) 
3. [System Architecture](#system-architecture)
4. [Installation & Deployment](#installation--deployment)
5. [Core Features](#core-features)
6. [API Reference](#api-reference)
7. [Security Analysis](#security-analysis)
8. [Monitoring & Maintenance](#monitoring--maintenance)
9. [Troubleshooting](#troubleshooting)
10. [Advanced Configuration](#advanced-configuration)

## Overview

The Enhanced Documentation System is an intelligent, AI-powered documentation platform that automatically analyzes, generates, and maintains comprehensive documentation for PowerShell, C#, and Python codebases. Built on a foundation of Code Property Graph (CPG) technology, semantic analysis, and local LLM integration, it provides enterprise-grade documentation capabilities with security analysis integration.

### Key Features

- **🧠 Intelligent Analysis**: Advanced semantic analysis with design pattern detection
- **📚 Multi-Language Support**: PowerShell, C#, Python, and TypeScript
- **🔒 Security Integration**: Built-in CodeQL security analysis
- **🚀 Performance Optimized**: Caching, incremental processing, and parallel execution
- **🐳 Container Ready**: Complete Docker containerization for production deployment
- **📊 Real-time Monitoring**: Comprehensive monitoring with Grafana dashboards
- **🔄 Automated Updates**: GitHub integration with PR-based documentation updates

## Quick Start

### Prerequisites

- **PowerShell 7.0+** (Windows/Linux/macOS)
- **Docker 20.10+** with Docker Compose
- **8GB+ RAM** (16GB recommended for production)
- **10GB+ free disk space**
- **Git** for source code management

### 5-Minute Setup

1. **Clone the Repository**
   ```powershell
   git clone https://github.com/your-org/unity-claude-automation.git
   cd unity-claude-automation
   ```

2. **Deploy the System**
   ```powershell
   # Development environment (local testing)
   .\Deploy-EnhancedDocumentationSystem.ps1 -Environment Development
   
   # Production environment (full features)  
   .\Deploy-EnhancedDocumentationSystem.ps1 -Environment Production
   ```

3. **Access Your Documentation**
   - **Documentation Site**: http://localhost:8080
   - **API Explorer**: http://localhost:8091/docs
   - **Monitoring Dashboard**: http://localhost:3000

That's it! The system will automatically begin analyzing your codebase and generating documentation.

## System Architecture

### Component Overview

```
┌─────────────────────────────────────────────────────────────┐
│                    Enhanced Documentation System             │
├─────────────────────────────────────────────────────────────┤
│  ┌─────────────┐ ┌─────────────┐ ┌─────────────────────────┐ │
│  │   Phase 1   │ │   Phase 2   │ │        Phase 3          │ │
│  │     CPG     │ │  Semantic   │ │  Production Features    │ │
│  │ Foundation  │ │ Intelligence │ │                         │ │
│  └─────────────┘ └─────────────┘ └─────────────────────────┘ │
├─────────────────────────────────────────────────────────────┤
│                     Core Modules                            │
│  • Unity-Claude-CPG              • Unity-Claude-Cache       │
│  • Unity-Claude-SemanticAnalysis • Unity-Claude-LLM         │  
│  • Unity-Claude-CodeQL           • Unity-Claude-API-Docs    │
├─────────────────────────────────────────────────────────────┤
│                   Container Services                        │
│  • Documentation Web Server      • CodeQL Security Scanner │
│  • REST API Service              • Monitoring Stack        │
│  • PowerShell Module Service     • File Change Monitor     │
└─────────────────────────────────────────────────────────────┘
```

### Data Flow

1. **Source Code Analysis** → CPG Generation → Relationship Mapping
2. **Semantic Analysis** → Pattern Detection → Purpose Classification  
3. **Security Scanning** → CodeQL Analysis → Vulnerability Reporting
4. **Documentation Generation** → Multi-format Output → API Publishing
5. **Continuous Monitoring** → Health Checks → Performance Metrics

## Installation & Deployment

### Environment Types

| Environment | Use Case | Features | Resource Requirements |
|-------------|----------|----------|---------------------|
| **Development** | Local testing & development | Basic monitoring, Debug logging | 2 CPU, 4GB RAM |
| **Staging** | Pre-production testing | Full monitoring, Enhanced security | 4 CPU, 8GB RAM | 
| **Production** | Enterprise deployment | Maximum security, High availability | 8+ CPU, 16GB+ RAM |

### Deployment Options

#### Option 1: Automated Deployment (Recommended)

```powershell
# Full production deployment with all features
.\Deploy-EnhancedDocumentationSystem.ps1 -Environment Production -BackupExisting

# Development deployment for testing
.\Deploy-EnhancedDocumentationSystem.ps1 -Environment Development -SkipTests
```

#### Option 2: Manual Docker Deployment

```powershell
# Build and start services
docker compose build --parallel
docker compose up -d

# Start monitoring stack
docker compose -f docker-compose.monitoring.yml up -d

# Verify deployment
docker compose ps
```

#### Option 3: PowerShell Module Only

```powershell
# Load core modules for PowerShell-only usage
Import-Module .\Modules\Unity-Claude-CPG\Unity-Claude-CPG.psd1 -Force
Import-Module .\Modules\Unity-Claude-SemanticAnalysis\Unity-Claude-SemanticAnalysis.psd1 -Force
Import-Module .\Modules\Unity-Claude-APIDocumentation\Unity-Claude-APIDocumentation.psd1 -Force

# Generate documentation for specific module
New-ComprehensiveAPIDocs -ModulesPath ".\Modules" -OutputPath ".\docs" -GenerateHTML
```

### Environment Configuration

Create a `.env` file in the project root:

```bash
# Environment Configuration
ENVIRONMENT=Production
DOCKER_REGISTRY=ghcr.io/your-org

# API Keys (configure securely)
OPENAI_API_KEY=your_openai_key_here
GITHUB_TOKEN=your_github_token_here  
OLLAMA_API_KEY=your_ollama_key_here

# Security Settings
ENABLE_TLS=true
ENABLE_RBAC=true
SECURITY_LEVEL=Maximum

# CodeQL Configuration
CODEQL_SCAN_INTERVAL=3600
CODEQL_ENABLE_CSHARP=true
CODEQL_ENABLE_POWERSHELL=true
```

## Core Features

### 1. Code Property Graph (CPG) Analysis

The system builds comprehensive relationship maps of your codebase:

```powershell
# Create CPG for PowerShell module
$graph = ConvertTo-CPGFromFile -FilePath ".\MyModule.psm1" -Language PowerShell

# Analyze relationships
$relationships = Get-CPGEdge -Graph $graph -Type "calls"

# Export for visualization
Export-CPGVisualization -Graph $graph -OutputPath ".\docs\graph.html" -Format D3
```

**Features:**
- **Node Types**: Modules, Functions, Classes, Variables, Parameters
- **Relationships**: Function calls, data dependencies, inheritance
- **Languages**: PowerShell, C#, Python, TypeScript
- **Outputs**: JSON, GraphML, D3 visualizations

### 2. Semantic Intelligence

Advanced AI-powered analysis of code structure and purpose:

```powershell
# Detect design patterns
$patterns = Find-DesignPatterns -Graph $graph
# Output: Singleton (95% confidence), Factory (87% confidence)

# Classify code purpose
$purpose = Get-CodePurpose -Graph $graph  
# Output: Data Access (92% confidence), Business Logic (78% confidence)

# Analyze cohesion metrics
$metrics = Get-CohesionMetrics -Graph $graph
# Output: CHM=0.85, CHD=0.73, Maintainability=High
```

**Capabilities:**
- **Pattern Detection**: 15+ design patterns with confidence scoring
- **Purpose Classification**: CRUD operations, business logic, utility functions
- **Quality Metrics**: Cohesion, coupling, complexity analysis
- **Refactoring Suggestions**: Automated improvement recommendations

### 3. Security Analysis with CodeQL

Enterprise-grade security scanning integrated into documentation:

```powershell
# Install CodeQL CLI  
Install-CodeQLCLI -InstallPath "C:\CodeQL" -AddToPath

# Create security database
New-PowerShellCodeQLDatabase -SourcePath ".\Modules" -DatabasePath ".\security\db"

# Run comprehensive security scan
$results = Invoke-PowerShellSecurityScan -DatabasePath ".\security\db" -QuerySuite "security-extended"

# Generate security report
Export-CodeQLResults -Results $results -Format HTML -OutputPath ".\docs\security-report.html"
```

**Security Checks:**
- **Command Injection** (CWE-78): PowerShell command execution vulnerabilities
- **Script Injection** (CWE-94): Dynamic code execution risks  
- **Credential Exposure** (CWE-200): Hardcoded secrets and API keys
- **Path Traversal** (CWE-22): File system access vulnerabilities
- **Code Quality**: Best practice violations and maintainability issues

### 4. Multi-Format Documentation Generation

Comprehensive API documentation with multiple output formats:

```powershell
# Generate complete API documentation
New-ComprehensiveAPIDocs -ModulesPath ".\Modules" -OutputPath ".\docs" -Format @("HTML", "Markdown", "PDF")

# Individual module documentation
New-ModuleDocumentation -ModulePath ".\Modules\Unity-Claude-CPG" -IncludeExamples -GenerateTests

# Export to specific format
Export-HTMLDocumentation -InputPath ".\docs\markdown" -OutputPath ".\docs\html" -Theme "Bootstrap" -IncludeSearch
```

**Output Formats:**
- **HTML**: Bootstrap-styled responsive documentation
- **Markdown**: GitHub-flavored markdown with mermaid diagrams
- **PDF**: Professional documentation with LaTeX styling  
- **JSON**: Machine-readable API specifications
- **OpenAPI**: REST API specifications for service integration

### 5. Performance Optimization

Built-in caching and performance enhancements:

```powershell
# Initialize cache system
Initialize-UnityClaudeCache -CacheType "Redis" -TTL "3600" -MaxSize "1GB"

# Enable incremental processing
Enable-IncrementalProcessing -WatchPath ".\Modules" -OutputPath ".\docs" -DiffThreshold 0.1

# Performance monitoring
Get-CacheStatistics
# Output: HitRate=87%, EvictionCount=23, MemoryUsage=512MB
```

**Performance Features:**
- **Intelligent Caching**: Redis-compatible in-memory cache with TTL/LRU eviction
- **Incremental Updates**: Process only changed files with diff-based analysis  
- **Parallel Processing**: Multi-threaded analysis with configurable worker pools
- **Background Jobs**: Asynchronous processing with progress tracking

## API Reference

### REST API Endpoints

The system provides a comprehensive REST API accessible at `http://localhost:8091`:

#### Core Documentation Endpoints

```http
# Get all modules
GET /api/modules
Response: Array of ModuleInfo objects

# Get specific module details  
GET /api/modules/{module_id}
Response: Detailed module information with functions

# Search documentation
GET /api/search?q={query}&limit={limit}
Response: Array of SearchResult objects

# Get all functions
GET /api/functions?module={module}&search={term}
Response: Array of FunctionInfo objects
```

#### Security Analysis Endpoints

```http
# Get latest security report
GET /api/security/report  
Response: ComprehensiveSecurityReport object

# Get security scan status
GET /api/security/status
Response: SecurityScanStatus object

# Trigger security scan
POST /api/security/scan
Body: { "scan_type": "full", "languages": ["powershell", "csharp"] }
```

#### System Management Endpoints

```http
# System health check
GET /health
Response: HealthStatus object

# Get system metrics
GET /api/metrics
Response: SystemMetrics object

# Cache statistics
GET /api/cache/stats  
Response: CacheStatistics object
```

### PowerShell Module API

Complete PowerShell API for programmatic access:

#### Unity-Claude-CPG Module

```powershell
# Core CPG functions
New-CPGraph -Name "MyProject"
Add-CPGNode -Graph $graph -Type "Function" -Name "Get-Data" -Properties @{Language="PowerShell"}
Add-CPGEdge -Graph $graph -From $node1 -To $node2 -Type "calls"
ConvertTo-CPGFromFile -FilePath "script.ps1" -Language PowerShell

# Analysis functions
Get-CPGNode -Graph $graph -Type "Function"
Get-CPGEdge -Graph $graph -From $node1
Find-CPGPath -Graph $graph -StartNode $node1 -EndNode $node2

# Export functions
Export-CPGVisualization -Graph $graph -Format "D3" -OutputPath "graph.html"
Export-CPGData -Graph $graph -Format "JSON" -OutputPath "data.json"
```

#### Unity-Claude-SemanticAnalysis Module

```powershell
# Pattern detection
Find-DesignPatterns -Graph $graph -MinConfidence 0.8
Find-AntiPatterns -Graph $graph -IncludeRecommendations

# Code analysis
Get-CodePurpose -Graph $graph -ClassificationThreshold 0.7
Get-CohesionMetrics -Graph $graph -CalculateAll
Extract-BusinessLogic -Graph $graph -ConfidenceLevel "High"

# Quality metrics
Measure-CodeComplexity -Graph $graph -Metrics @("Cyclomatic", "Cognitive")
Test-CodeQuality -Graph $graph -Standards @("Microsoft", "PSScriptAnalyzer")
```

#### Unity-Claude-APIDocumentation Module

```powershell
# Documentation generation
New-ComprehensiveAPIDocs -ModulesPath ".\Modules" -OutputPath ".\docs"
New-ModuleDocumentation -ModulePath ".\Module" -IncludeExamples -GenerateUML

# Export functions
Export-HTMLDocumentation -InputPath ".\docs\md" -OutputPath ".\docs\html" -Theme "Bootstrap"
Export-PDFDocumentation -InputPath ".\docs\md" -OutputPath ".\docs\pdf" -Style "Professional"

# Template management
New-DocumentationTemplate -Type "Function" -Template $template
Get-DocumentationTemplate -Type "Module" -Language "PowerShell"
```

## Security Analysis

### CodeQL Integration

The system includes comprehensive security analysis using GitHub's CodeQL:

#### Supported Languages & Queries

| Language | Query Suites | Focus Areas |
|----------|-------------|------------|
| **PowerShell** | Security Extended | Command injection, script execution, credential exposure |
| **C#** | Security & Quality | SQL injection, XSS, authentication bypasses |
| **Python** | Security Standard | Code injection, path traversal, unsafe deserialization |

#### Security Scan Process

1. **Database Creation**: CodeQL creates language-specific databases from source code
2. **Query Execution**: Runs comprehensive security query suites  
3. **Results Analysis**: Parses SARIF results and generates reports
4. **Risk Assessment**: Categorizes findings by severity (Critical/High/Medium/Low)
5. **Report Generation**: Creates HTML, PDF, and JSON security reports

#### Sample Security Report

```json
{
  "scan_timestamp": "2025-08-25T10:00:00Z",
  "total_findings": 15,
  "languages_scanned": ["powershell", "csharp"],
  "findings_by_severity": {
    "error": 2,
    "warning": 8, 
    "note": 5
  },
  "summary": {
    "critical_issues": 2,
    "high_issues": 8,
    "medium_issues": 5,
    "low_issues": 0
  }
}
```

### Security Best Practices

#### Automated Security Scanning

```powershell
# Schedule regular security scans
Register-ScheduledJob -Name "WeeklySecurityScan" -ScriptBlock {
    Invoke-PowerShellSecurityScan -DatabasePath ".\security\db" -OutputPath ".\reports"
    Send-SecurityReport -Recipients @("security@company.com") -ReportPath ".\reports\latest.html"
} -Trigger (New-JobTrigger -Weekly -DaysOfWeek Monday -At "02:00")
```

#### Integration with CI/CD

```yaml
# GitHub Actions integration
name: Security Analysis
on: [push, pull_request]
jobs:
  security:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - name: Run CodeQL Analysis
        run: |
          docker run --rm -v $PWD:/source unity-claude-codeql:latest
      - name: Upload Results
        uses: github/codeql-action/upload-sarif@v2
        with:
          sarif_file: security-results.sarif
```

## Monitoring & Maintenance

### Real-Time Monitoring

The system includes comprehensive monitoring via Grafana dashboards:

#### Available Dashboards

1. **System Overview**
   - Service health status
   - Resource utilization (CPU, Memory, Disk)
   - Request rate and response times
   - Error rates by service

2. **Documentation Metrics**  
   - Documentation coverage by module
   - Generation success/failure rates
   - Processing time trends
   - Cache hit/miss ratios

3. **Security Monitoring**
   - CodeQL scan status and results
   - Vulnerability trends over time
   - Security finding severity distribution
   - Scan performance metrics

4. **Performance Analytics**
   - API endpoint performance
   - Database query performance  
   - Background job processing times
   - System resource trends

#### Accessing Monitoring

- **Grafana Dashboard**: http://localhost:3000 (admin/admin123!)
- **Prometheus Metrics**: http://localhost:9090
- **Container Logs**: `docker compose logs [service-name]`

### Maintenance Tasks

#### Daily Maintenance

```powershell
# Health check script
.\scripts\daily-health-check.ps1

# Log rotation
Invoke-LogRotation -MaxAge 30 -CompressOld

# Cache optimization  
Optimize-UnityClaudeCache -EvictExpired -CompactData
```

#### Weekly Maintenance

```powershell
# Full system backup
.\scripts\backup-system.ps1 -IncludeData -CompressBackup

# Security scan
Invoke-PowerShellSecurityScan -FullScan -GenerateReport

# Performance optimization
Optimize-SystemPerformance -AnalyzeQueries -OptimizeIndexes
```

#### Monthly Maintenance

```powershell
# Update container images
docker compose pull
docker compose up -d

# Database maintenance
Invoke-DatabaseMaintenance -ReindexTables -UpdateStatistics

# Security updates
Update-SecurityDatabase -Source "GitHub" -UpdateQueries
```

## Troubleshooting

### Common Issues

#### 1. Services Won't Start

**Symptoms**: Docker containers exit immediately or fail health checks

**Solutions**:
```powershell
# Check system resources
Get-ComputerInfo | Select-Object TotalPhysicalMemory, CsProcessors

# Check port conflicts
netstat -ano | findstr ":8080 :8091 :3000 :9090"

# Check Docker logs
docker compose logs [service-name]

# Restart with clean slate
docker compose down --volumes --remove-orphans
docker compose up -d
```

#### 2. Module Import Failures

**Symptoms**: PowerShell modules fail to load with "module not found" errors

**Solutions**:
```powershell
# Verify module paths
Get-ChildItem .\Modules -Recurse -Filter "*.psd1"

# Test module manifests
Test-ModuleManifest -Path ".\Modules\Unity-Claude-CPG\Unity-Claude-CPG.psd1"

# Check PowerShell execution policy
Get-ExecutionPolicy -List
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser

# Force reimport
Get-Module Unity-Claude* | Remove-Module -Force
Import-Module .\Modules\Unity-Claude-CPG\Unity-Claude-CPG.psd1 -Force -Verbose
```

#### 3. CodeQL Analysis Failures

**Symptoms**: Security scans fail or produce no results

**Solutions**:
```powershell
# Check CodeQL installation
codeql --version

# Verify database creation
ls .\data\codeql-databases

# Test with simple query
codeql database analyze .\data\codeql-databases\powershell-db --format=sarif-latest --output=test.sarif

# Check container logs
docker logs unity-claude-codeql
```

#### 4. Performance Issues

**Symptoms**: Slow documentation generation, high memory usage

**Solutions**:
```powershell
# Monitor resource usage
Get-Process | Where-Object {$_.Name -like "*docker*" -or $_.Name -like "*pwsh*"} | 
    Select-Object Name, CPU, WorkingSet | Sort-Object WorkingSet -Descending

# Optimize cache settings
Set-CacheConfiguration -MaxMemoryMB 2048 -TTLSeconds 1800 -EvictionPolicy LRU

# Enable incremental processing
Enable-IncrementalProcessing -DiffThreshold 0.05 -SkipUnchanged

# Scale down for testing
docker compose up -d --scale docs-api=1 --scale powershell-modules=1
```

### Log Analysis

#### Log Locations

| Component | Log Location | Format |
|-----------|-------------|---------|
| Deployment | `deployment-YYYYMMDD.log` | Structured text |
| Docker Services | `docker compose logs [service]` | JSON structured |
| PowerShell Modules | `.\logs\modules-*.log` | PowerShell verbose |
| Security Scanner | `.\docs\generated\security\codeql.log` | Structured text |
| API Server | Docker logs `unity-claude-docs-api` | JSON structured |

#### Useful Log Queries

```powershell
# Find errors in deployment log
Select-String -Path "deployment-*.log" -Pattern "\[ERROR\]" -Context 2

# Analyze API performance
docker logs unity-claude-docs-api 2>&1 | 
    Select-String "response_time" | 
    ForEach-Object { ($_ -split '"response_time":')[1].Split(',')[0] } |
    Measure-Object -Average -Maximum -Minimum

# Check security scan results
Get-Content ".\docs\generated\security\security_summary.md"
```

### Support Resources

#### Community Support

- **GitHub Issues**: https://github.com/your-org/unity-claude-automation/issues
- **Documentation Wiki**: https://github.com/your-org/unity-claude-automation/wiki
- **Discord Community**: https://discord.gg/unity-claude-automation

#### Enterprise Support

- **Email**: support@your-company.com
- **Support Portal**: https://support.your-company.com
- **Professional Services**: Available for deployment, customization, and training

## Advanced Configuration

### Custom Query Development

Create custom CodeQL queries for specialized security analysis:

```ql
/**
 * @name PowerShell Credential Exposure
 * @description Finds hardcoded credentials in PowerShell scripts
 * @kind problem
 * @problem.severity error
 * @id powershell/credential-exposure
 */

import powershell

from StringLiteral str
where str.getValue().regexpMatch("(?i).*(password|secret|key|token)\\s*=\\s*['\"][^'\"]+['\"].*")
select str, "Potential credential exposure in string literal"
```

### Custom Documentation Templates

Create organization-specific documentation templates:

```powershell
# Custom function documentation template
$FunctionTemplate = @'
# {{FunctionName}}

## Synopsis
{{Synopsis}}

## Description  
{{Description}}

## Parameters
{{#Parameters}}
### {{Name}}
- **Type**: {{Type}}
- **Required**: {{Required}}
- **Description**: {{Description}}
{{/Parameters}}

## Examples
{{#Examples}}
### Example {{Number}}
```powershell
{{Code}}
```
{{Description}}
{{/Examples}}

## Security Considerations
{{SecurityNotes}}

## Performance Impact
{{PerformanceNotes}}
'@

Register-DocumentationTemplate -Type "Function" -Language "PowerShell" -Template $FunctionTemplate
```

### Integration with External Systems

#### JIRA Integration

```powershell
# Automatically create JIRA tickets for security findings
function New-SecurityJiraTicket {
    param(
        [Parameter(Mandatory)]
        [object]$SecurityFinding,
        
        [string]$JiraURL = "https://your-company.atlassian.net",
        [string]$ProjectKey = "SEC"
    )
    
    $ticket = @{
        fields = @{
            project = @{ key = $ProjectKey }
            summary = "Security Finding: $($SecurityFinding.rule_id)"
            description = $SecurityFinding.message
            issuetype = @{ name = "Security Bug" }
            priority = @{ name = $(
                switch ($SecurityFinding.level) {
                    'error' { 'Critical' }
                    'warning' { 'High' }
                    default { 'Medium' }
                }
            )}
            components = @(@{ name = "Documentation System" })
            labels = @("security", "automated", "codeql")
        }
    }
    
    $response = Invoke-RestMethod -Uri "$JiraURL/rest/api/2/issue" -Method POST -Body ($ticket | ConvertTo-Json -Depth 10) -ContentType "application/json" -Headers $headers
    return $response.key
}
```

#### Slack Notifications

```powershell
# Send deployment notifications to Slack
function Send-DeploymentNotification {
    param(
        [Parameter(Mandatory)]
        [string]$WebhookURL,
        
        [Parameter(Mandatory)]
        [hashtable]$DeploymentSummary
    )
    
    $message = @{
        text = "Enhanced Documentation System Deployment"
        attachments = @(@{
            color = if ($DeploymentSummary.Success) { "good" } else { "warning" }
            fields = @(
                @{ title = "Environment"; value = $DeploymentSummary.Environment; short = $true },
                @{ title = "Duration"; value = $DeploymentSummary.Duration; short = $true },
                @{ title = "Services"; value = ($DeploymentSummary.Services.Keys -join ", "); short = $false }
            )
        })
    }
    
    Invoke-RestMethod -Uri $WebhookURL -Method POST -Body ($message | ConvertTo-Json -Depth 10) -ContentType "application/json"
}
```

### Performance Tuning

#### Database Optimization

```powershell
# Optimize CodeQL database performance
$optimization = @{
    DatabasePath = ".\data\codeql-databases"
    Settings = @{
        MaxMemoryMB = 4096
        ThreadCount = [Environment]::ProcessorCount
        TempDirectory = ".\temp\codeql"
        CacheSize = "2GB"
    }
}

Optimize-CodeQLDatabase @optimization
```

#### Container Resource Limits

```yaml
# docker-compose.override.yml for production tuning
version: '3.8'
services:
  docs-api:
    deploy:
      resources:
        limits:
          cpus: '2.0'
          memory: 4G
        reservations:
          cpus: '1.0'
          memory: 2G
    environment:
      - WORKER_PROCESSES=4
      - CACHE_SIZE=1024MB
      
  codeql-security:
    deploy:
      resources:
        limits:
          cpus: '4.0'
          memory: 8G
        reservations:
          cpus: '2.0'  
          memory: 4G
    environment:
      - CODEQL_THREADS=4
      - CODEQL_MEMORY=6144
```

---

## Conclusion

The Enhanced Documentation System provides a comprehensive, enterprise-ready solution for intelligent code documentation with integrated security analysis. With its modular architecture, extensive API, and production-ready deployment scripts, it scales from individual developer use to large enterprise deployments.

For additional help, please refer to:

- **API Documentation**: http://localhost:8091/docs
- **System Monitoring**: http://localhost:3000  
- **GitHub Repository**: https://github.com/your-org/unity-claude-automation
- **Support**: support@your-company.com

**Version Information**
- Documentation System: v2.0.0
- Phase 3 Implementation: 100% Complete
- Last Updated: August 25, 2025