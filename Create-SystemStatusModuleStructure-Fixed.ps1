# Create-SystemStatusModuleStructure-Fixed.ps1
# Creates the modular directory structure for Unity-Claude-SystemStatus
# Date: 2025-08-20
# Phase 3 Hour 5: Create Directory Structure (Fixed version)

param(
    [string]$ModulePath = ".\Modules\Unity-Claude-SystemStatus"
)

Write-Host "=== Creating SystemStatus Module Structure ===" -ForegroundColor Cyan
Write-Host "Module Path: $ModulePath" -ForegroundColor Gray

# Ensure base path exists
if (-not (Test-Path $ModulePath)) {
    New-Item -Path $ModulePath -ItemType Directory -Force | Out-Null
}

# Define subdirectories to create
$subdirectories = @(
    "Core",
    "Storage",
    "Process",
    "Subsystems",
    "Communication",
    "Recovery",
    "Monitoring"
)

# Create each subdirectory
foreach ($dir in $subdirectories) {
    $dirPath = Join-Path $ModulePath $dir
    if (-not (Test-Path $dirPath)) {
        New-Item -Path $dirPath -ItemType Directory -Force | Out-Null
        Write-Host "Created directory: $dir/" -ForegroundColor Green
    } else {
        Write-Host "Directory exists: $dir/" -ForegroundColor Gray
    }
}

# Define all submodule files to create with their descriptions
$submodules = @{
    "Core\Configuration.psm1" = "Module configuration and initialization"
    "Core\Logging.psm1" = "Logging functions for system status"
    "Core\Validation.psm1" = "Schema and data validation functions"
    
    "Storage\StatusFileManager.psm1" = "System status file read/write operations"
    "Storage\FileLocking.psm1" = "File locking and synchronization"
    
    "Process\ProcessTracking.psm1" = "Process ID management and tracking"
    "Process\ProcessHealth.psm1" = "Process health monitoring"
    
    "Subsystems\Registration.psm1" = "Subsystem registration and management"
    "Subsystems\Heartbeat.psm1" = "Heartbeat system for subsystems"
    "Subsystems\HealthChecks.psm1" = "Subsystem health check functions"
    
    "Communication\NamedPipes.psm1" = "Named pipe server and client"
    "Communication\MessageHandling.psm1" = "Message processing and routing"
    "Communication\EventSystem.psm1" = "Cross-module event system"
    
    "Recovery\DependencyGraphs.psm1" = "Service dependency tracking"
    "Recovery\RestartLogic.psm1" = "Service restart and recovery logic"
    "Recovery\CircuitBreaker.psm1" = "Circuit breaker pattern implementation"
    
    "Monitoring\PerformanceCounters.psm1" = "Performance metrics collection"
    "Monitoring\AlertSystem.psm1" = "Alert generation and management"
    "Monitoring\Escalation.psm1" = "Alert escalation procedures"
}

# Create placeholder submodule files
foreach ($moduleKey in $submodules.Keys) {
    $moduleFilePath = Join-Path $ModulePath $moduleKey
    
    if (-not (Test-Path $moduleFilePath)) {
        # Create placeholder content
        $content = @"
# $(Split-Path -Leaf $moduleKey)
# $($submodules[$moduleKey])
# Part of Unity-Claude-SystemStatus module
# Date: $(Get-Date -Format 'yyyy-MM-dd')

# Module configuration
`$ErrorActionPreference = "Stop"

# TODO: Extract relevant functions from main module

# Export public functions
# Export-ModuleMember -Function @()
"@
        
        $content | Set-Content $moduleFilePath -Encoding UTF8
        Write-Host "Created submodule: $moduleKey" -ForegroundColor Green
    } else {
        Write-Host "Submodule exists: $moduleKey" -ForegroundColor Gray
    }
}

# Create the main loader module
$mainModulePath = Join-Path $ModulePath "Unity-Claude-SystemStatus.psm1.new"
$mainModuleContent = @'
# Unity-Claude-SystemStatus.psm1
# Main loader module for Unity-Claude-SystemStatus
# Refactored modular version
# Date: 2025-08-20

$ErrorActionPreference = "Stop"

Write-Host "[SystemStatus] Loading modular Unity-Claude-SystemStatus..." -ForegroundColor Cyan

# Module root path
$script:ModuleRoot = $PSScriptRoot

# Load AutonomousAgentWatchdog if available
$watchdogPath = Join-Path $PSScriptRoot "AutonomousAgentWatchdog.psm1"
if (Test-Path $watchdogPath) {
    Import-Module $watchdogPath -Force -DisableNameChecking
    Write-Host "[SystemStatus] AutonomousAgentWatchdog loaded" -ForegroundColor Green
}

# Define loading order for submodules (dependencies first)
$submoduleLoadOrder = @(
    # Core modules first
    "Core\Configuration.psm1",
    "Core\Logging.psm1",
    "Core\Validation.psm1",
    
    # Storage layer
    "Storage\FileLocking.psm1",
    "Storage\StatusFileManager.psm1",
    
    # Process management
    "Process\ProcessTracking.psm1",
    "Process\ProcessHealth.psm1",
    
    # Subsystem management
    "Subsystems\Registration.psm1",
    "Subsystems\Heartbeat.psm1",
    "Subsystems\HealthChecks.psm1",
    
    # Communication layer
    "Communication\NamedPipes.psm1",
    "Communication\MessageHandling.psm1",
    "Communication\EventSystem.psm1",
    
    # Recovery systems
    "Recovery\DependencyGraphs.psm1",
    "Recovery\RestartLogic.psm1",
    "Recovery\CircuitBreaker.psm1",
    
    # Monitoring systems
    "Monitoring\PerformanceCounters.psm1",
    "Monitoring\AlertSystem.psm1",
    "Monitoring\Escalation.psm1"
)

# Load each submodule
foreach ($submodule in $submoduleLoadOrder) {
    $submodulePath = Join-Path $PSScriptRoot $submodule
    if (Test-Path $submodulePath) {
        try {
            . $submodulePath
            Write-Verbose "[SystemStatus] Loaded: $submodule"
        } catch {
            Write-Warning "[SystemStatus] Failed to load $submodule : $_"
        }
    } else {
        Write-Verbose "[SystemStatus] Submodule not found: $submodule"
    }
}

Write-Host "[SystemStatus] Unity-Claude-SystemStatus module loaded successfully" -ForegroundColor Green

# Export all public functions
# These will be populated as functions are extracted to submodules
Export-ModuleMember -Function @(
    # Core
    'Write-SystemStatusLog',
    'Test-SystemStatusSchema',
    'ConvertTo-HashTable',
    
    # Storage
    'Read-SystemStatus',
    'Write-SystemStatus',
    
    # Process
    'Get-SystemUptime',
    'Get-SubsystemProcessId',
    'Update-SubsystemProcessInfo',
    'Test-ProcessHealth',
    'Test-ProcessPerformanceHealth',
    'Get-ProcessPerformanceCounters',
    
    # Subsystems
    'Register-Subsystem',
    'Unregister-Subsystem',
    'Get-RegisteredSubsystems',
    'Send-Heartbeat',
    'Test-HeartbeatResponse',
    'Test-AllSubsystemHeartbeats',
    'Send-HeartbeatRequest',
    'Test-ServiceResponsiveness',
    'Test-CriticalSubsystemHealth',
    'Get-CriticalSubsystems',
    
    # Communication
    'Initialize-NamedPipeServer',
    'Stop-NamedPipeServer',
    'New-SystemStatusMessage',
    'Send-SystemStatusMessage',
    'Receive-SystemStatusMessage',
    'Register-MessageHandler',
    'Invoke-MessageHandler',
    'Start-MessageProcessor',
    'Stop-MessageProcessor',
    'Initialize-CrossModuleEvents',
    'Send-EngineEvent',
    'Start-SystemStatusFileWatcher',
    'Stop-SystemStatusFileWatcher',
    
    # Recovery
    'Get-ServiceDependencyGraph',
    'Restart-ServiceWithDependencies',
    'Start-ServiceRecoveryAction',
    'Invoke-CircuitBreakerCheck',
    
    # Monitoring
    'Measure-CommunicationPerformance',
    'Send-HealthAlert',
    'Get-AlertHistory',
    'Send-HealthCheckRequest',
    'Invoke-EscalationProcedure',
    'Initialize-SystemStatusMonitoring',
    'Stop-SystemStatusMonitoring',
    
    # Runspace Management
    'Initialize-SubsystemRunspaces',
    'Start-SubsystemSession',
    'Stop-SubsystemRunspaces'
)
'@

$mainModuleContent | Set-Content $mainModulePath -Encoding UTF8
Write-Host "`nCreated main loader module: Unity-Claude-SystemStatus.psm1.new" -ForegroundColor Cyan

# Create module manifest (only if it doesn't exist)
$manifestPath = Join-Path $ModulePath "Unity-Claude-SystemStatus.psd1"
if (-not (Test-Path $manifestPath)) {
    $manifestContent = @'
# Unity-Claude-SystemStatus.psd1
# Module manifest for Unity-Claude-SystemStatus
# Generated: 2025-08-20

@{
    # Module information
    RootModule = 'Unity-Claude-SystemStatus.psm1'
    ModuleVersion = '2.0.0'
    GUID = 'a4f7d8e9-3c5b-4a2d-9e1f-8b7c6d5e4f3a'
    Author = 'Unity-Claude Automation System'
    CompanyName = 'Unity-Claude'
    Copyright = '(c) 2025 Unity-Claude. All rights reserved.'
    Description = 'System status monitoring and cross-subsystem communication for Unity-Claude Automation'
    
    # Requirements
    PowerShellVersion = '5.1'
    # RequiredModules = @()
    
    # Exported members
    FunctionsToExport = @(
        'Write-SystemStatusLog',
        'Test-SystemStatusSchema',
        'Read-SystemStatus',
        'Write-SystemStatus',
        'Get-SystemUptime',
        'Get-SubsystemProcessId',
        'Update-SubsystemProcessInfo',
        'Register-Subsystem',
        'Unregister-Subsystem',
        'Get-RegisteredSubsystems',
        'Send-Heartbeat',
        'Test-HeartbeatResponse',
        'Test-AllSubsystemHeartbeats',
        'Initialize-NamedPipeServer',
        'Stop-NamedPipeServer',
        'Send-SystemStatusMessage',
        'Receive-SystemStatusMessage',
        'Start-SystemStatusFileWatcher',
        'Stop-SystemStatusFileWatcher',
        'Initialize-CrossModuleEvents',
        'Send-EngineEvent',
        'Initialize-SystemStatusMonitoring',
        'Stop-SystemStatusMonitoring',
        'Test-ProcessHealth',
        'Test-ServiceResponsiveness',
        'Get-ProcessPerformanceCounters',
        'Test-ProcessPerformanceHealth',
        'Get-CriticalSubsystems',
        'Test-CriticalSubsystemHealth',
        'Invoke-CircuitBreakerCheck',
        'Send-HealthAlert',
        'Invoke-EscalationProcedure',
        'Get-AlertHistory',
        'Get-ServiceDependencyGraph',
        'Restart-ServiceWithDependencies',
        'Start-ServiceRecoveryAction',
        'Initialize-SubsystemRunspaces',
        'Start-SubsystemSession',
        'Stop-SubsystemRunspaces'
    )
    
    CmdletsToExport = @()
    VariablesToExport = @()
    AliasesToExport = @()
    
    # Private data
    PrivateData = @{
        PSData = @{
            Tags = @('Unity', 'Claude', 'Automation', 'SystemStatus', 'Monitoring')
            ProjectUri = ''
            ReleaseNotes = 'Refactored to modular structure following autonomous agent pattern'
        }
    }
}
'@
    
    $manifestContent | Set-Content $manifestPath -Encoding UTF8
    Write-Host "`nCreated module manifest: Unity-Claude-SystemStatus.psd1" -ForegroundColor Cyan
} else {
    Write-Host "`nModule manifest already exists" -ForegroundColor Gray
}

Write-Host "`n=== Module Structure Created Successfully ===" -ForegroundColor Green
Write-Host "Next steps:" -ForegroundColor Yellow
Write-Host "  1. Extract functions from Unity-Claude-SystemStatus.psm1 to submodules" -ForegroundColor Gray
Write-Host "  2. Update the main loader module to source all submodules" -ForegroundColor Gray
Write-Host "  3. Test module loading and API compatibility" -ForegroundColor Gray
Write-Host "`nStructure created at: $ModulePath" -ForegroundColor Cyan

# List created structure
Write-Host "`nCreated structure:" -ForegroundColor Yellow
Get-ChildItem -Path $ModulePath -Recurse -File | ForEach-Object {
    $relativePath = $_.FullName.Replace("$ModulePath\", "")
    Write-Host "  $relativePath" -ForegroundColor Gray
}
# SIG # Begin signature block
# MIIFqQYJKoZIhvcNAQcCoIIFmjCCBZYCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUlD3ih5WF2/4MJea8ndSkgSJj
# tfGgggMwMIIDLDCCAhSgAwIBAgIQdR0W2SKoK5VE8JId4ZxrRTANBgkqhkiG9w0B
# AQsFADAuMSwwKgYDVQQDDCNVbml0eS1DbGF1ZGUtQXV0b21hdGlvbi1EZXZlbG9w
# bWVudDAeFw0yNTA4MjAyMTE1MTdaFw0yNjA4MjAyMTM1MTdaMC4xLDAqBgNVBAMM
# I1VuaXR5LUNsYXVkZS1BdXRvbWF0aW9uLURldmVsb3BtZW50MIIBIjANBgkqhkiG
# 9w0BAQEFAAOCAQ8AMIIBCgKCAQEAseH3qinVEOhrn2OLpjc5TNT4vGh1BkfB5X4S
# FhY7K0QMQsYYnkZVmx3tB8PqVQXl++l+e3uT7uCscc7vjMTK8tDSWH98ji0U34WL
# JBwXC62l1ArazMKp4Tyr7peksei7vL4pZOtOVgAyTYn5d1hbnsVQmCSTPRtpn7mC
# Azfq2ec5qZ9Kgl7puPW5utvYfh8idtOWa5/WgYSKwOIvyZawIdZKLFpwqOtqbJe4
# sWzVahasFhLfoAKkniKOAocJDkJexh5pO/EOSKEZ3mOCU1ZSs4XWRGISRhV3qGZp
# f+Y3JlHKMeFDWKynaJBO8/GU5sqMATlDUvrByBtU2OQ2Um/L3QIDAQABo0YwRDAO
# BgNVHQ8BAf8EBAMCB4AwEwYDVR0lBAwwCgYIKwYBBQUHAwMwHQYDVR0OBBYEFHw5
# rOy6xlW6B45sJUsiI2A/yS0MMA0GCSqGSIb3DQEBCwUAA4IBAQAUTLH0+w8ysvmh
# YuBw4NDKcZm40MTh9Zc1M2p2hAkYsgNLJ+/rAP+I74rNfqguTYwxpCyjkwrg8yF5
# wViwggboLpF2yDu4N/dgDainR4wR8NVpS7zFZOFkpmNPepc6bw3d4yQKa/wJXKeC
# pkRjS50N77/hfVI+fFKNao7POb7en5fcXuZaN6xWoTRy+J4I4MhfHpjZuxSLSXjb
# VXtPD4RZ9HGjl9BU8162cRhjujr/Lc3/dY/6ikHQYnxuxcdxRew4nzaqAQaOeWu6
# tGp899JPKfldM5Zay5IBl3zs15gNS9+0Jrd0ARQnSVYoI0DLh3KybFnfK4POezoN
# Lp/dbX2SMYIB4zCCAd8CAQEwQjAuMSwwKgYDVQQDDCNVbml0eS1DbGF1ZGUtQXV0
# b21hdGlvbi1EZXZlbG9wbWVudAIQdR0W2SKoK5VE8JId4ZxrRTAJBgUrDgMCGgUA
# oHgwGAYKKwYBBAGCNwIBDDEKMAigAoAAoQKAADAZBgkqhkiG9w0BCQMxDAYKKwYB
# BAGCNwIBBDAcBgorBgEEAYI3AgELMQ4wDAYKKwYBBAGCNwIBFTAjBgkqhkiG9w0B
# CQQxFgQUaVMlhjXGgxjr5SHD9wb9ZMr7R68wDQYJKoZIhvcNAQEBBQAEggEADjaN
# gUPR6yJk0yOrtjig22eNvYbM6uDMnxOaBDoLlnlYdVFUsbTQE8urYuixsckGz514
# Lx0t+FseOk8eZEu3jFfiyyYCJ3ShuFFXgtM2Wq2uwCfJDoTv61aNo39bjBxbv/fF
# Qy6avTDKrlp19y+BoYfNqnKlcA4ofJ554UPumf8EHPQsuG/Z0HsxGjnbWCM1X/7Y
# WhfyzXla5Ee0Xs5pDdWJvDh/NFNvPoItrFQTNNa73uz+6fLg3WIuw61lva2meP1R
# ereDEwjSyBsGG5ClNcFxaFjlY06l9Wu8NErsSptwK/y9gM9VMCUhVeZKltklF8Hq
# wPZC2Hl99DGRkAvBFw==
# SIG # End signature block
