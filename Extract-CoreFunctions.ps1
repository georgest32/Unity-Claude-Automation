# Extract-CoreFunctions.ps1
# Extracts core functions from main module to Core/ submodules
# Date: 2025-08-20
# Phase 3 Hour 6: Extract Core Components

param(
    [string]$SourceModule = ".\Modules\Unity-Claude-SystemStatus\Unity-Claude-SystemStatus.psm1",
    [string]$TargetPath = ".\Modules\Unity-Claude-SystemStatus"
)

Write-Host "=== Extracting Core Functions ===" -ForegroundColor Cyan
Write-Host "Source: $SourceModule" -ForegroundColor Gray
Write-Host "Target: $TargetPath\Core\" -ForegroundColor Gray

# Read the source module
$sourceContent = Get-Content $SourceModule -Raw

# Extract Configuration content (lines 1-145 approximately)
Write-Host "`nExtracting Configuration module..." -ForegroundColor Yellow
$configContent = @'
# Configuration.psm1
# Module configuration and initialization
# Part of Unity-Claude-SystemStatus module
# Date: 2025-08-20

$ErrorActionPreference = "Stop"

# System status monitoring configuration
$script:SystemStatusConfig = @{
    # Core system status paths
    SystemStatusFile = Join-Path $PSScriptRoot "..\..\..\system_status.json"
    HealthDataPath = Join-Path $PSScriptRoot "..\..\..\SessionData\Health"
    WatchdogDataPath = Join-Path $PSScriptRoot "..\..\..\SessionData\Watchdog"
    SchemaFile = Join-Path $PSScriptRoot "..\..\..\system_status_schema.json"
    
    # Status monitoring settings
    HeartbeatIntervalSeconds = 60
    HeartbeatFailureThreshold = 4
    HealthCheckIntervalSeconds = 15
    StatusUpdateIntervalSeconds = 30
    
    # Performance monitoring thresholds
    CriticalCpuPercentage = 70
    CriticalMemoryMB = 800
    CriticalResponseTimeMs = 1000
    WarningCpuPercentage = 50
    WarningMemoryMB = 500
    
    # Communication configuration
    NamedPipeName = "UnityClaudeSystemStatus"
    CommunicationTimeoutMs = 5000
    MessageRetryAttempts = 3
    
    # Circuit breaker configuration
    CircuitBreakerEnabled = $true
    CircuitBreakerThreshold = 5
    CircuitBreakerResetTimeSeconds = 30
    
    # Alert configuration
    AlertCooldownSeconds = 300
    MaxAlertFrequency = 10
    EscalationEnabled = $true
    EscalationThresholds = @{
        Level1 = 3
        Level2 = 5
        Level3 = 10
    }
    
    # Logging
    LogPath = Join-Path $PSScriptRoot "..\..\..\Logs\SystemStatus"
    LogLevel = "INFO"
    MaxLogSizeMB = 100
    LogRetentionDays = 30
}

# Ensure all directories exist
foreach ($path in @($script:SystemStatusConfig.HealthDataPath, $script:SystemStatusConfig.WatchdogDataPath)) {
    if (-not (Test-Path $path)) {
        New-Item -Path $path -ItemType Directory -Force | Out-Null
    }
}

# Critical subsystems list
$script:CriticalSubsystems = @{
    "Unity" = @{
        Priority = 1
        RestartOnFailure = $true
        HealthCheckInterval = 10
        MaxRestartAttempts = 3
    }
    "Claude" = @{
        Priority = 1
        RestartOnFailure = $false
        HealthCheckInterval = 15
        MaxRestartAttempts = 0
    }
    "AutonomousAgent" = @{
        Priority = 2
        RestartOnFailure = $true
        HealthCheckInterval = 30
        MaxRestartAttempts = 5
    }
    "Watchdog" = @{
        Priority = 1
        RestartOnFailure = $true
        HealthCheckInterval = 5
        MaxRestartAttempts = 3
    }
    "ResponseMonitor" = @{
        Priority = 3
        RestartOnFailure = $true
        HealthCheckInterval = 60
        MaxRestartAttempts = 3
    }
}

# Global variables for module state
$script:SystemStatusState = @{
    IsMonitoring = $false
    MonitoringJob = $null
    FileWatcher = $null
    NamedPipeServer = $null
    MessageHandlers = @{}
    CircuitBreakerState = @{}
    AlertHistory = @()
    SubsystemRegistry = @{}
    RunspacePool = $null
    RunspaceJobs = @()
}

# Schema definition for validation
$script:SystemStatusSchema = @{
    timestamp = @{ Type = "string"; Required = $true }
    subsystems = @{ Type = "hashtable"; Required = $true }
    overall_health = @{ Type = "string"; Required = $false }
    last_update = @{ Type = "datetime"; Required = $false }
    alerts = @{ Type = "array"; Required = $false }
    metrics = @{ Type = "hashtable"; Required = $false }
}

# Export configuration for other modules
Export-ModuleMember -Variable @(
    'SystemStatusConfig',
    'CriticalSubsystems',
    'SystemStatusState',
    'SystemStatusSchema'
)
'@

$configContent | Set-Content (Join-Path $TargetPath "Core\Configuration.psm1") -Encoding UTF8
Write-Host "  Created Core\Configuration.psm1" -ForegroundColor Green

# Extract Logging functions
Write-Host "`nExtracting Logging module..." -ForegroundColor Yellow

# Find Write-SystemStatusLog function
$logFunctionPattern = '(?ms)^function Write-SystemStatusLog.*?^}'
if ($sourceContent -match $logFunctionPattern) {
    $logFunction = $Matches[0]
    
    $loggingContent = @"
# Logging.psm1
# Logging functions for system status
# Part of Unity-Claude-SystemStatus module
# Date: 2025-08-20

`$ErrorActionPreference = "Stop"

# Import configuration
`$configPath = Join-Path `$PSScriptRoot "Configuration.psm1"
if (Test-Path `$configPath) {
    . `$configPath
}

$logFunction

# Export logging functions
Export-ModuleMember -Function @(
    'Write-SystemStatusLog'
)
"@
    
    $loggingContent | Set-Content (Join-Path $TargetPath "Core\Logging.psm1") -Encoding UTF8
    Write-Host "  Created Core\Logging.psm1" -ForegroundColor Green
} else {
    Write-Warning "  Could not find Write-SystemStatusLog function"
}

# Extract Validation functions
Write-Host "`nExtracting Validation module..." -ForegroundColor Yellow

# Find validation functions
$testSchemaPattern = '(?ms)^function Test-SystemStatusSchema.*?^}'
$convertHashPattern = '(?ms)^function ConvertTo-HashTable.*?^}'

$validationFunctions = @()
if ($sourceContent -match $testSchemaPattern) {
    $validationFunctions += $Matches[0]
}
if ($sourceContent -match $convertHashPattern) {
    $validationFunctions += $Matches[0]
}

if ($validationFunctions.Count -gt 0) {
    $validationContent = @"
# Validation.psm1
# Schema and data validation functions
# Part of Unity-Claude-SystemStatus module
# Date: 2025-08-20

`$ErrorActionPreference = "Stop"

# Import configuration
`$configPath = Join-Path `$PSScriptRoot "Configuration.psm1"
if (Test-Path `$configPath) {
    . `$configPath
}

$($validationFunctions -join "`n`n")

# Export validation functions
Export-ModuleMember -Function @(
    'Test-SystemStatusSchema',
    'ConvertTo-HashTable'
)
"@
    
    $validationContent | Set-Content (Join-Path $TargetPath "Core\Validation.psm1") -Encoding UTF8
    Write-Host "  Created Core\Validation.psm1" -ForegroundColor Green
} else {
    Write-Warning "  Could not find validation functions"
}

Write-Host "`n=== Core Function Extraction Complete ===" -ForegroundColor Green
Write-Host "Next steps:" -ForegroundColor Yellow
Write-Host "  1. Test that Core modules load correctly" -ForegroundColor Gray
Write-Host "  2. Continue extracting Storage functions" -ForegroundColor Gray
Write-Host "  3. Update main loader to use new modules" -ForegroundColor Gray
# SIG # Begin signature block
# MIIFqQYJKoZIhvcNAQcCoIIFmjCCBZYCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUUBO5+175FaKtUodR5ebKBhLU
# 2SKgggMwMIIDLDCCAhSgAwIBAgIQdR0W2SKoK5VE8JId4ZxrRTANBgkqhkiG9w0B
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
# CQQxFgQU8kjdWJRlGbHS1v/RCAg3PyrNfcEwDQYJKoZIhvcNAQEBBQAEggEAeIq0
# tcbQV0uXoc87shMSsgyy4LFeDzOn1j8zjVCB3t38ecf7Y4PatcZzb0ZDIctzIwmW
# h4JpKrRmskqG31G2xfq+9azazBT9irDF/DojCKuuUC5xX0rweSiahDfW90nQGHlC
# +xTMpKTqB4TS6LWTH7W1Dy/4GrYbfldsmpFQwx2fdIolgpbuXI9eqLNYoIwOfuhj
# gSEQzZqOcIaitYPBs9ojRjCTT3agq7D/sIx4okdCwLzLEdGcvOoBWtvXTMGvcX4o
# zntXQmLUiTkGxLmCVTN1nQg8e8G/42cgf2cq1peKuumaxe8uS8l0I731h22xdVMh
# Ha8fODwSYoV5Khm92A==
# SIG # End signature block
