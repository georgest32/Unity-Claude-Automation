# Start-AllServices.ps1
# Consolidated startup script for all Unity-Claude-Automation services
# Includes both native PowerShell modules and Docker containerized services
# Date: 2025-08-24

param(
    [switch]$UseManifest = $false,
    [switch]$SkipDocker = $false,
    [switch]$SkipNative = $false,
    [switch]$StopAll = $false,
    [switch]$Status = $false,
    [switch]$Debug = $false
)

# PowerShell 7 Self-Elevation
if ($PSVersionTable.PSVersion.Major -lt 7) {
    $pwsh7 = "C:\Program Files\PowerShell\7\pwsh.exe"
    if (Test-Path $pwsh7) {
        Write-Host "Upgrading to PowerShell 7..." -ForegroundColor Yellow
        $arguments = @("-NoProfile", "-ExecutionPolicy", "Bypass", "-File", $MyInvocation.MyCommand.Path) + $args
        Start-Process -FilePath $pwsh7 -ArgumentList $arguments -NoNewWindow -Wait
        exit
    } else {
        Write-Warning "PowerShell 7 not found. Running in PowerShell $($PSVersionTable.PSVersion)"
    }
}

$ErrorActionPreference = "Continue"

# Service configuration
$services = @{
    Native = @{
        SystemStatus = @{
            Name = "SystemStatusMonitoring"
            Port = "N/A"
            Description = "Core system monitoring and heartbeat service"
            Script = ".\Start-SystemStatusMonitoring.ps1"
        }
        AutonomousAgent = @{
            Name = "AutonomousAgent"
            Port = "N/A"
            Description = "Unity error detection and autonomous response"
            Script = ".\Start-AutonomousMonitoring.ps1"
        }
    }
    Docker = @{
        LangGraphAPI = @{
            Name = "langgraph-api"
            Port = 8000
            Description = "LangGraph REST API for multi-agent orchestration"
            Service = "langgraph-api"
        }
        AutoGenGroupChat = @{
            Name = "autogen-groupchat"
            Port = 8001
            Description = "AutoGen GroupChat service for agent collaboration"
            Service = "autogen-groupchat"
        }
        Documentation = @{
            Name = "docs-server"
            Port = 8080
            Description = "Documentation server (MkDocs/Nginx)"
            Service = "docs-server"
        }
        FileMonitor = @{
            Name = "file-monitor"
            Port = "N/A"
            Description = "File system monitoring for documentation drift"
            Service = "file-monitor"
        }
        PowerShellModules = @{
            Name = "powershell-modules"
            Port = "N/A"
            Description = "PowerShell module testing environment"
            Service = "powershell-modules"
        }
    }
    External = @{
        MkDocsLocal = @{
            Name = "MkDocs (Local)"
            Port = 8000
            Description = "Local MkDocs server (conflicts with LangGraph API)"
            Process = "mkdocs"
        }
    }
}

function Show-ServiceStatus {
    Write-Host "`n=================================================" -ForegroundColor Cyan
    Write-Host "Unity-Claude-Automation Service Status" -ForegroundColor Cyan
    Write-Host "=================================================" -ForegroundColor Cyan
    Write-Host "Timestamp: $(Get-Date)" -ForegroundColor Gray
    Write-Host ""
    
    # Check Native Services
    Write-Host "Native PowerShell Services:" -ForegroundColor Yellow
    foreach ($service in $services.Native.Values) {
        $running = Get-WmiObject Win32_Process | Where-Object {
            $_.CommandLine -like "*$($service.Script)*"
        }
        
        if ($running) {
            Write-Host "  [RUNNING] $($service.Name) - $($service.Description)" -ForegroundColor Green
            Write-Host "           PID: $($running.ProcessId)" -ForegroundColor Gray
        } else {
            Write-Host "  [STOPPED] $($service.Name) - $($service.Description)" -ForegroundColor Red
        }
    }
    
    Write-Host ""
    Write-Host "Docker Services:" -ForegroundColor Yellow
    
    # Check if Docker is running
    $dockerRunning = $null
    try {
        $dockerVersion = docker version 2>&1
        if ($LASTEXITCODE -eq 0) {
            $dockerRunning = $true
        }
    } catch {
        $dockerRunning = $false
    }
    
    if ($dockerRunning) {
        foreach ($service in $services.Docker.Values) {
            $container = docker ps --filter "name=$($service.Service)" --format "table {{.Names}}\t{{.Status}}" 2>&1 | Select-String $service.Service
            
            if ($container) {
                $port = if ($service.Port -ne "N/A") { "Port: $($service.Port)" } else { "No port" }
                Write-Host "  [RUNNING] $($service.Name) - $($service.Description)" -ForegroundColor Green
                Write-Host "           $port" -ForegroundColor Gray
            } else {
                Write-Host "  [STOPPED] $($service.Name) - $($service.Description)" -ForegroundColor Red
            }
        }
    } else {
        Write-Host "  Docker is not running or not installed" -ForegroundColor Red
    }
    
    Write-Host ""
    Write-Host "External Services:" -ForegroundColor Yellow
    
    # Check for conflicting MkDocs server
    $mkdocsProcess = Get-Process -Name "python*" -ErrorAction SilentlyContinue | Where-Object {
        $_.CommandLine -like "*mkdocs*serve*" -or
        $_.CommandLine -like "*mike*serve*"
    }
    
    if ($mkdocsProcess) {
        Write-Host "  [WARNING] MkDocs local server detected on port 8000" -ForegroundColor Yellow
        Write-Host "           This conflicts with LangGraph API" -ForegroundColor Yellow
        Write-Host "           PID: $($mkdocsProcess.Id)" -ForegroundColor Gray
    }
    
    Write-Host ""
    Write-Host "Port Usage Summary:" -ForegroundColor Yellow
    Write-Host "  Port 8000: " -NoNewline
    if ($mkdocsProcess) {
        Write-Host "MkDocs (Local) - CONFLICT!" -ForegroundColor Red
    } else {
        Write-Host "LangGraph API (Docker)" -ForegroundColor Green
    }
    Write-Host "  Port 8001: AutoGen GroupChat (Docker)" -ForegroundColor Gray
    Write-Host "  Port 8080: Documentation Server (Docker)" -ForegroundColor Gray
    Write-Host ""
}

function Stop-AllServices {
    Write-Host "`nStopping all services..." -ForegroundColor Yellow
    
    # Stop native services
    Write-Host "Stopping native PowerShell services..." -ForegroundColor Gray
    Get-WmiObject Win32_Process | Where-Object {
        $_.CommandLine -like "*SystemStatusMonitoring*.ps1*" -or
        $_.CommandLine -like "*AutonomousMonitoring.ps1*"
    } | ForEach-Object {
        Stop-Process -Id $_.ProcessId -Force -ErrorAction SilentlyContinue
        Write-Host "  Stopped process $($_.ProcessId)" -ForegroundColor Gray
    }
    
    # Stop Docker services
    if (Get-Command docker -ErrorAction SilentlyContinue) {
        Write-Host "Stopping Docker services..." -ForegroundColor Gray
        docker-compose -f docker-compose.yml down 2>&1 | Out-Null
    }
    
    # Stop any MkDocs servers
    Get-Process -Name "python*" -ErrorAction SilentlyContinue | Where-Object {
        $_.CommandLine -like "*mkdocs*serve*" -or
        $_.CommandLine -like "*mike*serve*"
    } | ForEach-Object {
        Stop-Process -Id $_.Id -Force -ErrorAction SilentlyContinue
        Write-Host "  Stopped MkDocs server (PID: $($_.Id))" -ForegroundColor Gray
    }
    
    Write-Host "All services stopped" -ForegroundColor Green
}

function Start-NativeServices {
    Write-Host "`nStarting native PowerShell services..." -ForegroundColor Yellow
    
    # Start using the manifest-based system if requested
    if ($UseManifest -and (Test-Path ".\Start-UnifiedSystem-Complete.ps1")) {
        Write-Host "Using manifest-based startup..." -ForegroundColor Cyan
        & ".\Start-UnifiedSystem-Complete.ps1" -UseManifestMode -Debug:$Debug
    } else {
        # Start services individually
        
        # Start SystemStatusMonitoring
        $existingMonitor = Get-WmiObject Win32_Process | Where-Object {
            $_.CommandLine -like "*SystemStatusMonitoring*.ps1*"
        }
        
        if (-not $existingMonitor) {
            Write-Host "Starting SystemStatusMonitoring..." -ForegroundColor Gray
            Start-Process -FilePath "pwsh.exe" -ArgumentList @(
                "-NoExit",
                "-ExecutionPolicy", "Bypass",
                "-File", ".\Start-SystemStatusMonitoring.ps1",
                "-EnableHeartbeat",
                "-EnableFileWatcher"
            ) -WindowStyle Normal -PassThru | Out-Null
            Start-Sleep -Seconds 3
        }
        
        # Start AutonomousAgent
        $existingAgent = Get-WmiObject Win32_Process | Where-Object {
            $_.CommandLine -like "*AutonomousMonitoring.ps1*"
        }
        
        if (-not $existingAgent -and (Test-Path ".\Start-AutonomousMonitoring.ps1")) {
            Write-Host "Starting AutonomousAgent..." -ForegroundColor Gray
            Start-Process -FilePath "pwsh.exe" -ArgumentList @(
                "-NoExit",
                "-ExecutionPolicy", "Bypass",
                "-File", ".\Start-AutonomousMonitoring.ps1"
            ) -WindowStyle Normal -PassThru | Out-Null
        }
    }
    
    Write-Host "Native services started" -ForegroundColor Green
}

function Start-DockerServices {
    Write-Host "`nStarting Docker services..." -ForegroundColor Yellow
    
    # Check if Docker is available
    if (-not (Get-Command docker -ErrorAction SilentlyContinue)) {
        Write-Host "Docker is not installed or not in PATH" -ForegroundColor Red
        Write-Host "Please install Docker Desktop from: https://www.docker.com/products/docker-desktop" -ForegroundColor Yellow
        return
    }
    
    # Check if Docker daemon is running
    try {
        docker version 2>&1 | Out-Null
        if ($LASTEXITCODE -ne 0) {
            Write-Host "Docker daemon is not running. Please start Docker Desktop." -ForegroundColor Red
            return
        }
    } catch {
        Write-Host "Cannot connect to Docker daemon" -ForegroundColor Red
        return
    }
    
    # Check for port conflicts
    $mkdocsProcess = Get-Process -Name "python*" -ErrorAction SilentlyContinue | Where-Object {
        $_.CommandLine -like "*mkdocs*serve*" -or
        $_.CommandLine -like "*mike*serve*"
    }
    
    if ($mkdocsProcess) {
        Write-Host "WARNING: MkDocs is running on port 8000 (PID: $($mkdocsProcess.Id))" -ForegroundColor Yellow
        Write-Host "This will conflict with the LangGraph API service." -ForegroundColor Yellow
        
        $response = Read-Host "Stop MkDocs server? (Y/N)"
        if ($response -eq 'Y') {
            Stop-Process -Id $mkdocsProcess.Id -Force
            Write-Host "MkDocs server stopped" -ForegroundColor Green
            Start-Sleep -Seconds 2
        }
    }
    
    # Build and start Docker services
    Write-Host "Building Docker images..." -ForegroundColor Gray
    docker-compose build 2>&1 | Out-String | Write-Debug
    
    Write-Host "Starting Docker containers..." -ForegroundColor Gray
    docker-compose up -d 2>&1 | Out-String | Write-Debug
    
    # Wait for services to be ready
    Write-Host "Waiting for services to initialize..." -ForegroundColor Gray
    Start-Sleep -Seconds 5
    
    # Test service health
    Write-Host "Testing service endpoints..." -ForegroundColor Gray
    
    $endpoints = @(
        @{Name="LangGraph API"; Url="http://localhost:8000/health"},
        @{Name="AutoGen GroupChat"; Url="http://localhost:8001/health"},
        @{Name="Documentation"; Url="http://localhost:8080/"}
    )
    
    foreach ($endpoint in $endpoints) {
        try {
            $response = Invoke-WebRequest -Uri $endpoint.Url -Method Get -TimeoutSec 5 -ErrorAction SilentlyContinue
            if ($response.StatusCode -eq 200) {
                Write-Host "  [OK] $($endpoint.Name) is responding" -ForegroundColor Green
            } else {
                Write-Host "  [WARN] $($endpoint.Name) returned status $($response.StatusCode)" -ForegroundColor Yellow
            }
        } catch {
            Write-Host "  [FAIL] $($endpoint.Name) is not responding" -ForegroundColor Red
        }
    }
    
    Write-Host "Docker services started" -ForegroundColor Green
}

# Main execution
Write-Host "=================================================" -ForegroundColor Cyan
Write-Host "Unity-Claude-Automation Service Manager" -ForegroundColor Cyan
Write-Host "=================================================" -ForegroundColor Cyan

if ($Status) {
    Show-ServiceStatus
    exit
}

if ($StopAll) {
    Stop-AllServices
    exit
}

# Start services
if (-not $SkipNative) {
    Start-NativeServices
}

if (-not $SkipDocker) {
    Start-DockerServices
}

# Show final status
Show-ServiceStatus

Write-Host "`nService URLs:" -ForegroundColor Yellow
Write-Host "  LangGraph API:       http://localhost:8000" -ForegroundColor Gray
Write-Host "  AutoGen GroupChat:   http://localhost:8001" -ForegroundColor Gray
Write-Host "  Documentation:       http://localhost:8080" -ForegroundColor Gray
Write-Host ""
Write-Host "Commands:" -ForegroundColor Yellow
Write-Host "  View status:         .\Start-AllServices.ps1 -Status" -ForegroundColor Gray
Write-Host "  Stop all:           .\Start-AllServices.ps1 -StopAll" -ForegroundColor Gray
Write-Host "  Skip Docker:        .\Start-AllServices.ps1 -SkipDocker" -ForegroundColor Gray
Write-Host "  Skip Native:        .\Start-AllServices.ps1 -SkipNative" -ForegroundColor Gray
Write-Host "  Use Manifest mode:  .\Start-AllServices.ps1 -UseManifest" -ForegroundColor Gray
Write-Host ""
# SIG # Begin signature block
# MIIFzgYJKoZIhvcNAQcCoIIFvzCCBbsCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCCry4wWk93dLNcL
# qpVLx5aPwn6Ipyt7dTxyp8QO1fMIpKCCAzAwggMsMIICFKADAgECAhB1HRbZIqgr
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
# MAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEID5GJE+77HGAi7QaXwEto1vX
# kFxeAln50keHDmdhuYXEMA0GCSqGSIb3DQEBAQUABIIBAIS2LsTU8ifmPJhTblzK
# XrmJ0YO3QT1DTPsIiNnPLUG3vPQQSi2zYIdVRUF6bBHLbsNGHLu11EuNhTQ7eAsc
# AJsuvxipaPQGZxDWKodkeAhGk1SwYpYAdflUrydNL0O9Ok1LpQimtBo+bCU5eL60
# ErmMdvWN8c5Y1os6PuXCxo9523t09+x9HeKpU/QQgK9caAx4kAGoTe8ZCHJNGvGg
# rgmcThEW57pLiNP3DBEyWHqu6V6a6Qj1HxrrbRJrQaH8bOYtHpWC1GeWO8mqxU0h
# fuhMQQoKZ/J/iwrp6CNyXnU8+BsMkqX0BPB/TFqBm06CvQCpsigrhJet/00oeEpN
# 4x8=
# SIG # End signature block
