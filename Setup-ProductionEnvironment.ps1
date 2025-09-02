# Enhanced Documentation System - Production Environment Setup
# Phase 3 Day 5: Production Integration & Advanced Features
# Version: 2025-08-25
#
# Configures production environment for Enhanced Documentation System deployment

[CmdletBinding()]
param(
    [ValidateSet('Production', 'Staging', 'Development')]
    [string]$Environment = 'Production',
    
    [string]$DomainName = 'localhost',
    [string]$SSLCertificatePath = '',
    [string]$BackupPath = '.\backups',
    
    [switch]$EnableSSL,
    [switch]$EnableMonitoring,
    [switch]$EnableBackups,
    [switch]$ConfigureFirewall,
    [switch]$SetupScheduledTasks,
    [switch]$Force
)

$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'

function Write-SetupLog {
    param(
        [Parameter(Mandatory)]
        [string]$Message,
        
        [ValidateSet('Info', 'Warning', 'Error', 'Success')]
        [string]$Level = 'Info'
    )
    
    $timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
    $color = switch ($Level) {
        'Info' { 'White' }
        'Warning' { 'Yellow' }
        'Error' { 'Red' }
        'Success' { 'Green' }
    }
    
    Write-Host "[$timestamp] $Message" -ForegroundColor $color
    
    # Also log to setup log file
    "[$timestamp] [$Level] $Message" | Out-File -FilePath "production-setup.log" -Append -Encoding UTF8
}

function Initialize-ProductionDirectories {
    Write-SetupLog "Creating production directory structure..." -Level Info
    
    $directories = @(
        'config\production',
        'logs\production',
        'data\production',
        'backups\production',
        'secrets\production',
        'certificates',
        'monitoring\production',
        'scripts\maintenance'
    )
    
    foreach ($dir in $directories) {
        if (-not (Test-Path $dir)) {
            New-Item -Path $dir -ItemType Directory -Force | Out-Null
            Write-SetupLog "Created directory: $dir" -Level Info
        }
    }
}

function Set-ProductionConfiguration {
    Write-SetupLog "Configuring production settings..." -Level Info
    
    # Production environment configuration
    $prodConfig = @{
        Environment = $Environment
        Domain = $DomainName
        Security = @{
            EnableHTTPS = $EnableSSL
            CertificatePath = $SSLCertificatePath
            RequireAuthentication = $true
            AllowedOrigins = @($DomainName)
        }
        Services = @{
            Documentation = @{
                Port = if ($EnableSSL) { 443 } else { 80 }
                InternalPort = 8080
                HealthCheckInterval = 30
            }
            API = @{
                Port = 8091
                RateLimit = 1000
                EnableCORS = $false
                MaxRequestSize = '10MB'
            }
            Monitoring = @{
                Enabled = $EnableMonitoring
                GrafanaPort = 3000
                PrometheusPort = 9090
                RetentionPeriod = '30d'
            }
        }
        Logging = @{
            Level = 'Warning'
            MaxFileSize = '100MB'
            MaxFiles = 10
            EnableStructured = $true
        }
        Performance = @{
            MaxConcurrentRequests = 100
            CacheSize = '1GB'
            WorkerProcesses = [Environment]::ProcessorCount
        }
        Backup = @{
            Enabled = $EnableBackups
            Schedule = '0 2 * * *'  # Daily at 2 AM
            RetentionDays = 30
            IncludeData = $true
            IncludeLogs = $false
        }
    }
    
    # Save production configuration
    $configPath = "config\production\environment.json"
    $prodConfig | ConvertTo-Json -Depth 10 | Out-File -FilePath $configPath -Encoding UTF8
    Write-SetupLog "Production configuration saved to: $configPath" -Level Success
    
    # Create environment-specific docker-compose override
    $composeOverride = @"
version: '3.9'

# Production overrides for Enhanced Documentation System
services:
  docs-server:
    restart: always
    deploy:
      replicas: 2
      resources:
        limits:
          memory: 512M
        reservations:
          memory: 256M
    environment:
      - NODE_ENV=production
      - LOG_LEVEL=warning
    labels:
      - "traefik.enable=true"
      - "traefik.http.routers.docs.rule=Host(``$DomainName``)"
$(if ($EnableSSL) {
"      - `"traefik.http.routers.docs.tls=true`"
      - `"traefik.http.routers.docs.tls.certresolver=letsencrypt`""
})

  docs-api:
    restart: always
    deploy:
      resources:
        limits:
          memory: 1024M
        reservations:
          memory: 512M
    environment:
      - API_ENV=production
      - LOG_LEVEL=warning
      - RATE_LIMIT=1000
      - ENABLE_CORS=false

  codeql-security:
    restart: always
    deploy:
      resources:
        limits:
          memory: 2048M
        reservations:
          memory: 1024M
    environment:
      - SCAN_INTERVAL=7200  # 2 hours for production
      - LOG_LEVEL=warning

$(if ($EnableMonitoring) {
"  # Production monitoring configuration
  prometheus:
    command:
      - '--config.file=/etc/prometheus/prometheus.yml'
      - '--storage.tsdb.path=/prometheus'
      - '--storage.tsdb.retention.time=30d'
      - '--web.console.libraries=/etc/prometheus/console_libraries'
      - '--web.console.templates=/etc/prometheus/consoles'
      - '--web.enable-lifecycle'
      - '--web.enable-admin-api'
      - '--web.external-url=https://$DomainName/prometheus/'

  grafana:
    environment:
      - GF_SERVER_ROOT_URL=https://$DomainName/grafana/
      - GF_SERVER_SERVE_FROM_SUB_PATH=true
      - GF_SECURITY_ADMIN_PASSWORD=`${GRAFANA_ADMIN_PASSWORD}
      - GF_USERS_ALLOW_SIGN_UP=false"
})

networks:
  default:
    external:
      name: production-network
"@
    
    $composeOverride | Out-File -FilePath "docker-compose.production.yml" -Encoding UTF8
    Write-SetupLog "Production docker-compose override created" -Level Success
}

function Setup-SSLCertificates {
    if (-not $EnableSSL) {
        return
    }
    
    Write-SetupLog "Setting up SSL certificates..." -Level Info
    
    if ($SSLCertificatePath -and (Test-Path $SSLCertificatePath)) {
        # Copy existing certificates
        Copy-Item -Path $SSLCertificatePath -Destination "certificates\" -Recurse -Force
        Write-SetupLog "SSL certificates copied from: $SSLCertificatePath" -Level Success
    } else {
        # Generate self-signed certificate for development/staging
        if ($Environment -ne 'Production') {
            Write-SetupLog "Generating self-signed certificate for $DomainName..." -Level Warning
            
            try {
                $cert = New-SelfSignedCertificate -DnsName $DomainName -CertStoreLocation "cert:\LocalMachine\My" -KeySpec KeyExchange
                
                # Export certificate
                $certPath = "certificates\$DomainName.pfx"
                $password = ConvertTo-SecureString -String "TempPassword123!" -Force -AsPlainText
                Export-PfxCertificate -Cert $cert -FilePath $certPath -Password $password
                
                Write-SetupLog "Self-signed certificate generated: $certPath" -Level Success
                Write-SetupLog "Certificate password: TempPassword123! (CHANGE THIS IN PRODUCTION!)" -Level Warning
            } catch {
                Write-SetupLog "Failed to generate SSL certificate: $_" -Level Error
            }
        } else {
            Write-SetupLog "Production deployment requires valid SSL certificate. Please provide certificate path." -Level Error
            throw "SSL certificate required for production deployment"
        }
    }
}

function Configure-WindowsFirewall {
    if (-not $ConfigureFirewall) {
        return
    }
    
    Write-SetupLog "Configuring Windows Firewall..." -Level Info
    
    # Ports that need to be opened
    $firewallRules = @(
        @{ Name = "Enhanced Docs Web"; Port = 8080; Protocol = "TCP"; Description = "Enhanced Documentation Web Interface" },
        @{ Name = "Enhanced Docs API"; Port = 8091; Protocol = "TCP"; Description = "Enhanced Documentation API" },
        @{ Name = "PowerShell Remoting"; Port = 5985; Protocol = "TCP"; Description = "PowerShell Remoting HTTP" },
        @{ Name = "PowerShell Remoting SSL"; Port = 5986; Protocol = "TCP"; Description = "PowerShell Remoting HTTPS" },
        @{ Name = "LangGraph API"; Port = 8000; Protocol = "TCP"; Description = "LangGraph REST API" },
        @{ Name = "AutoGen Service"; Port = 8001; Protocol = "TCP"; Description = "AutoGen GroupChat Service" }
    )
    
    if ($EnableMonitoring) {
        $firewallRules += @(
            @{ Name = "Prometheus"; Port = 9090; Protocol = "TCP"; Description = "Prometheus Monitoring" },
            @{ Name = "Grafana"; Port = 3000; Protocol = "TCP"; Description = "Grafana Dashboard" },
            @{ Name = "Loki"; Port = 3100; Protocol = "TCP"; Description = "Loki Log Aggregation" }
        )
    }
    
    if ($EnableSSL) {
        $firewallRules += @(
            @{ Name = "HTTPS"; Port = 443; Protocol = "TCP"; Description = "HTTPS Web Traffic" }
        )
    } else {
        $firewallRules += @(
            @{ Name = "HTTP"; Port = 80; Protocol = "TCP"; Description = "HTTP Web Traffic" }
        )
    }
    
    foreach ($rule in $firewallRules) {
        try {
            # Check if rule already exists
            $existingRule = Get-NetFirewallRule -DisplayName $rule.Name -ErrorAction SilentlyContinue
            
            if ($existingRule) {
                Write-SetupLog "Firewall rule '$($rule.Name)' already exists" -Level Info
            } else {
                New-NetFirewallRule -DisplayName $rule.Name -Direction Inbound -Protocol $rule.Protocol -LocalPort $rule.Port -Action Allow -Description $rule.Description
                Write-SetupLog "Created firewall rule: $($rule.Name) (port $($rule.Port))" -Level Success
            }
        } catch {
            Write-SetupLog "Failed to create firewall rule '$($rule.Name)': $_" -Level Warning
        }
    }
}

function Setup-ScheduledMaintenance {
    if (-not $SetupScheduledTasks) {
        return
    }
    
    Write-SetupLog "Setting up scheduled maintenance tasks..." -Level Info
    
    # Create maintenance scripts
    $maintenanceScripts = @{
        "Backup-DocumentationSystem.ps1" = @"
# Automated backup script for Enhanced Documentation System
param([string]`$BackupPath = '$BackupPath')

`$timestamp = Get-Date -Format 'yyyyMMdd-HHmmss'
`$backupDir = Join-Path `$BackupPath "backup-`$timestamp"

try {
    New-Item -Path `$backupDir -ItemType Directory -Force | Out-Null
    
    # Backup configuration
    Copy-Item -Path "config\*" -Destination "`$backupDir\config" -Recurse -Force
    
    # Backup data volumes
    docker run --rm -v unity-claude-automation_docs-generated:/source -v "`${backupDir}:/backup" alpine tar czf /backup/docs-generated.tar.gz -C /source .
    docker run --rm -v unity-claude-automation_codeql-databases:/source -v "`${backupDir}:/backup" alpine tar czf /backup/codeql-databases.tar.gz -C /source .
    
    # Backup logs (last 7 days)
    Get-ChildItem "logs\*" -File | Where-Object { `$_.LastWriteTime -gt (Get-Date).AddDays(-7) } | Copy-Item -Destination "`$backupDir\logs"
    
    Write-Host "Backup completed: `$backupDir"
    
    # Clean up old backups (keep last 30 days)
    Get-ChildItem `$BackupPath -Directory | Where-Object { `$_.Name -like "backup-*" -and `$_.CreationTime -lt (Get-Date).AddDays(-30) } | Remove-Item -Recurse -Force
    
} catch {
    Write-Error "Backup failed: `$_"
    exit 1
}
"@
        
        "Maintenance-HealthCheck.ps1" = @"
# Automated health check for Enhanced Documentation System
try {
    `$healthResult = & ".\Test-SystemHealth.ps1" -TestType Quick -SaveResults
    
    if (`$LASTEXITCODE -ne 0) {
        # Send alert if health check fails
        Write-EventLog -LogName Application -Source "Enhanced Documentation System" -EventID 1001 -EntryType Error -Message "Health check failed with exit code `$LASTEXITCODE"
    }
} catch {
    Write-EventLog -LogName Application -Source "Enhanced Documentation System" -EventID 1002 -EntryType Error -Message "Health check exception: `$_"
}
"@
        
        "Cleanup-TempFiles.ps1" = @"
# Cleanup temporary files and logs
try {
    # Clean Docker system
    docker system prune -f --volumes
    
    # Clean old log files (older than 30 days)
    Get-ChildItem "logs\*.log" | Where-Object { `$_.LastWriteTime -lt (Get-Date).AddDays(-30) } | Remove-Item -Force
    
    # Clean temporary documentation files
    Get-ChildItem "docs\generated\*.tmp" -ErrorAction SilentlyContinue | Remove-Item -Force
    
    Write-Host "Cleanup completed"
} catch {
    Write-Error "Cleanup failed: `$_"
}
"@
    }
    
    # Create maintenance scripts
    foreach ($scriptName in $maintenanceScripts.Keys) {
        $scriptPath = "scripts\maintenance\$scriptName"
        $maintenanceScripts[$scriptName] | Out-File -FilePath $scriptPath -Encoding UTF8
        Write-SetupLog "Created maintenance script: $scriptPath" -Level Success
    }
    
    # Create scheduled tasks
    $tasks = @(
        @{
            Name = "Enhanced Docs - Daily Backup"
            Script = "scripts\maintenance\Backup-DocumentationSystem.ps1"
            Schedule = "Daily"
            Time = "02:00"
        },
        @{
            Name = "Enhanced Docs - Health Check"
            Script = "scripts\maintenance\Maintenance-HealthCheck.ps1"
            Schedule = "Hourly"
            Time = "00:00"
        },
        @{
            Name = "Enhanced Docs - Weekly Cleanup"
            Script = "scripts\maintenance\Cleanup-TempFiles.ps1"
            Schedule = "Weekly"
            Time = "03:00"
        }
    )
    
    foreach ($task in $tasks) {
        try {
            $scriptPath = Join-Path (Get-Location) $task.Script
            $taskExists = Get-ScheduledTask -TaskName $task.Name -ErrorAction SilentlyContinue
            
            if ($taskExists -and -not $Force) {
                Write-SetupLog "Scheduled task '$($task.Name)' already exists (use -Force to recreate)" -Level Warning
                continue
            }
            
            if ($taskExists) {
                Unregister-ScheduledTask -TaskName $task.Name -Confirm:$false
            }
            
            $action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-ExecutionPolicy Bypass -File `"$scriptPath`""
            
            $trigger = switch ($task.Schedule) {
                "Daily" { New-ScheduledTaskTrigger -Daily -At $task.Time }
                "Weekly" { New-ScheduledTaskTrigger -Weekly -At $task.Time -DaysOfWeek Sunday }
                "Hourly" { New-ScheduledTaskTrigger -Once -At (Get-Date) -RepetitionInterval (New-TimeSpan -Hours 1) }
            }
            
            $principal = New-ScheduledTaskPrincipal -UserId "SYSTEM" -LogonType ServiceAccount -RunLevel Highest
            $settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable
            
            Register-ScheduledTask -TaskName $task.Name -Action $action -Trigger $trigger -Principal $principal -Settings $settings -Description "Enhanced Documentation System maintenance task"
            
            Write-SetupLog "Created scheduled task: $($task.Name)" -Level Success
        } catch {
            Write-SetupLog "Failed to create scheduled task '$($task.Name)': $_" -Level Warning
        }
    }
}

function Setup-EventLogSource {
    Write-SetupLog "Setting up Windows Event Log source..." -Level Info
    
    try {
        if (-not [System.Diagnostics.EventLog]::SourceExists("Enhanced Documentation System")) {
            New-EventLog -LogName Application -Source "Enhanced Documentation System"
            Write-SetupLog "Event Log source created" -Level Success
        } else {
            Write-SetupLog "Event Log source already exists" -Level Info
        }
    } catch {
        Write-SetupLog "Failed to create Event Log source: $_" -Level Warning
    }
}

function Create-ProductionReadme {
    Write-SetupLog "Creating production deployment guide..." -Level Info
    
    $readme = @"
# Enhanced Documentation System - Production Deployment

## Environment Configuration
- **Environment**: $Environment
- **Domain**: $DomainName
- **SSL Enabled**: $EnableSSL
- **Monitoring Enabled**: $EnableMonitoring
- **Backups Enabled**: $EnableBackups

## Service URLs
- **Documentation**: $(if ($EnableSSL) { "https" } else { "http" })://$DomainName$(if (-not $EnableSSL -and $DomainName -eq "localhost") { ":8080" })
- **API Documentation**: http://$DomainName:8091/docs
- **Health Check**: http://$DomainName:8091/health
$(if ($EnableMonitoring) {
"- **Monitoring Dashboard**: http://$DomainName:3000
- **Prometheus Metrics**: http://$DomainName:9090"
})

## Deployment Commands

### Start Services
``````bash
# Production deployment
.\Deploy-EnhancedDocumentationSystem.ps1 -Environment $Environment

# Start with monitoring
docker-compose -f docker-compose.yml -f docker-compose.production.yml up -d
$(if ($EnableMonitoring) { "docker-compose -f docker-compose.monitoring.yml up -d" })
``````

### Health Check
``````bash
.\Test-SystemHealth.ps1 -TestType Full -SaveResults -GenerateReport
``````

### Backup
``````bash
.\scripts\maintenance\Backup-DocumentationSystem.ps1
``````

### View Logs
``````bash
# Service logs
docker-compose logs -f docs-server docs-api

# System logs
Get-EventLog -LogName Application -Source "Enhanced Documentation System" -Newest 50
``````

## Configuration Files
- **Environment Config**: config\production\environment.json
- **Docker Override**: docker-compose.production.yml
$(if ($EnableSSL) { "- **SSL Certificates**: certificates\" })
- **Backup Location**: $BackupPath

## Maintenance
$(if ($SetupScheduledTasks) {
"- **Daily Backups**: Automated at 2:00 AM
- **Health Checks**: Automated every hour  
- **Weekly Cleanup**: Automated Sundays at 3:00 AM"
} else {
"- Run maintenance scripts manually from scripts\maintenance\"
})

## Troubleshooting

### Check Service Status
``````bash
docker-compose ps
``````

### View Recent Logs
``````bash
docker-compose logs --tail=100 -f
``````

### Restart Services
``````bash
docker-compose restart
``````

### Emergency Stop
``````bash
docker-compose down
``````

## Security Considerations
- Change default passwords in production
- Regularly update SSL certificates
- Monitor security scan results from CodeQL
- Review firewall rules periodically
- Keep Docker images updated

## Support
- Check deployment logs: production-setup.log
- Health reports: health-reports\
- System metrics: http://$DomainName:3000
"@
    
    $readme | Out-File -FilePath "PRODUCTION_DEPLOYMENT.md" -Encoding UTF8
    Write-SetupLog "Production deployment guide created: PRODUCTION_DEPLOYMENT.md" -Level Success
}

function Show-CompletionSummary {
    Write-SetupLog "Production environment setup completed!" -Level Success
    Write-Host ""
    Write-Host "🎉 Enhanced Documentation System - Production Environment Ready!" -ForegroundColor Green
    Write-Host "================================================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Environment: $Environment" -ForegroundColor White
    Write-Host "Domain: $DomainName" -ForegroundColor White
    Write-Host "SSL Enabled: $EnableSSL" -ForegroundColor White
    Write-Host "Monitoring Enabled: $EnableMonitoring" -ForegroundColor White
    Write-Host "Backups Enabled: $EnableBackups" -ForegroundColor White
    Write-Host ""
    Write-Host "Next Steps:" -ForegroundColor Cyan
    Write-Host "1. Review configuration files in config\production\" -ForegroundColor White
    Write-Host "2. Update secrets and passwords as needed" -ForegroundColor White
    Write-Host "3. Run deployment: .\Deploy-EnhancedDocumentationSystem.ps1 -Environment $Environment" -ForegroundColor White
    Write-Host "4. Verify health: .\Test-SystemHealth.ps1 -TestType Full" -ForegroundColor White
    Write-Host ""
    Write-Host "Documentation: PRODUCTION_DEPLOYMENT.md" -ForegroundColor Yellow
    Write-Host "Setup Log: production-setup.log" -ForegroundColor Yellow
    Write-Host ""
}

# Main execution
try {
    Write-SetupLog "Enhanced Documentation System - Production Environment Setup" -Level Info
    Write-SetupLog "Environment: $Environment | Domain: $DomainName" -Level Info
    
    Initialize-ProductionDirectories
    Set-ProductionConfiguration
    Setup-SSLCertificates
    Configure-WindowsFirewall
    Setup-ScheduledMaintenance
    Setup-EventLogSource
    Create-ProductionReadme
    
    Show-CompletionSummary
    
} catch {
    Write-SetupLog "Production setup failed: $($_.Exception.Message)" -Level Error
    Write-SetupLog "Stack trace: $($_.ScriptStackTrace)" -Level Error
    exit 1
}
# SIG # Begin signature block
# MIIFzgYJKoZIhvcNAQcCoIIFvzCCBbsCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCBpqdAmTFqDaMau
# Zpbiu6UXYj9d84cFMwcMeB/VgdcxIKCCAzAwggMsMIICFKADAgECAhB1HRbZIqgr
# lUTwkh3hnGtFMA0GCSqGSIb3DQEBCwUAMC4xLDAqBgNVBAMMI1VuaXR5LUNsYXVk
# ZS1BdXRvbWF0aW9uLURldmVsb3BtZW50MB4XDTI1MDgyMDIxMTUxN1oXDTI2MDgy
# MDIxMzUxN1owLjEsMCoGA1UEAwwjVW5pdHktQ2xhdWRlLUF1dG9tYXRpb24tRGV2
# ZWxvcG1lbnQwggEiMA0GCSqGSIb3DQEBAQUAA4IBDwAwggEKAoIBAQCx4feqKdUQ
# 6GufY4umNzlM1Pi8aHUGR8HlfhIWFjsrRAxCxhieRlWbHe0Hw+pVBeX76X57e5Pu
# 4Kxxzu+MxMry0NJYf3yOLRTfhYskHBcLraXUCtrMwqnhPKvul6Sx6Lu8vilk605W
# ADJNifl3WFuexVCYJJM9G2mfuYIDN+rZ5zmpn0qCXum49bm629h+HyJ205Zrn9aB
# hIrA4i/JlrAh1kosWnCo62psl7ixbNVqFqwWEt+gAqSeIo4ChwkOQl7GHmk78Q5I
# oRneY4JTVlKzhdZEYhJGFXeoZml/5jcmUcox4UNYrKdokE7z8ZTmyowBOUNS+sHI
# G1TY5DZSb8vdAgMBAAGjRjBEMA4GA1UdDwEB/wQEAwIHgDATBgNVHSUEDDAKBggr
# BgEFBQcDAzAdBgNVHQ4EFgQUfDms7LrGVboHjmwlSyIjYD/JLQwwDQYJKoZIhvcN
# AQELBQADggEBABRMsfT7DzKy+aFi4HDg0MpxmbjQxOH1lzUzanaECRiyA0sn7+sA
# /4jvis1+qC5NjDGkLKOTCuDzIXnBWLCCBugukXbIO7g392ANqKdHjBHw1WlLvMVk
# 4WSmY096lzpvDd3jJApr/Alcp4KmRGNLnQ3vv+F9Uj58Uo1qjs85vt6fl9xe5lo3
# rFahNHL4ngjgyF8emNm7FItJeNtVe08PhFn0caOX0FTzXrZxGGO6Ov8tzf91j/qK
# QdBifG7Fx3FF7DifNqoBBo55a7q0anz30k8p+V0zllrLkgGXfOzXmA1L37Qmt3QB
# FCdJVigjQMuHcrJsWd8rg857Og0un91tfZIxggH0MIIB8AIBATBCMC4xLDAqBgNV
# BAMMI1VuaXR5LUNsYXVkZS1BdXRvbWF0aW9uLURldmVsb3BtZW50AhB1HRbZIqgr
# lUTwkh3hnGtFMA0GCWCGSAFlAwQCAQUAoIGEMBgGCisGAQQBgjcCAQwxCjAIoAKA
# AKECgAAwGQYJKoZIhvcNAQkDMQwGCisGAQQBgjcCAQQwHAYKKwYBBAGCNwIBCzEO
# MAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIAb5/+Dayfp0zUK6qsYI13YF
# 67ct+jj57+aZy2BnSvn6MA0GCSqGSIb3DQEBAQUABIIBAKaOCtjRk1HntBXr2yew
# kAShhYsxT/sw/RtukfIhqcoZdfxTNMKfin74j/ifR3Xl+pIPfpPV5rYK/CBYDfdE
# DA1GC/7Or/Gh4EPKgQu3r2PIL409wFGFrfyNociwH0fQzV0RY5SnTj3VF9NsU33p
# QS9Jl9fTo24bXyGpJBJf7W+0+SMIxgJwCe74zS3HgKZbfnbB9ButwIn/6IcjuKPe
# l52csdOMMSMdxxCa3rdMW0iP/Hi0JzEqxgcA25gB4RuGjUcQcNqRgUsc8TmDpIff
# f0enC5/m2JtDFMV98RIIpFvqpnvRzIL2xdEl3IgjO3A8QvVVkKs/uzuWLLCiEg8t
# HjU=
# SIG # End signature block
