# Unity-Claude-SystemStatus-ModularLoader.psm1
# Improved modular loader for Unity-Claude-SystemStatus
# Date: 2025-08-20
# This loader properly imports submodules and re-exports their functions

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

# Define submodule loading order (dependencies first)
$submoduleLoadOrder = @(
    # Core modules first (these contain shared configuration)
    @{ Path = "Core\Configuration.psm1"; Name = "Configuration" },
    @{ Path = "Core\Logging.psm1"; Name = "Logging" },
    @{ Path = "Core\Validation.psm1"; Name = "Validation" },
    
    # Storage layer
    @{ Path = "Storage\FileLocking.psm1"; Name = "FileLocking" },
    @{ Path = "Storage\StatusFileManager.psm1"; Name = "StatusFileManager" },
    
    # Process management
    @{ Path = "Process\ProcessTracking.psm1"; Name = "ProcessTracking" },
    @{ Path = "Process\ProcessHealth.psm1"; Name = "ProcessHealth" },
    @{ Path = "Process\RunspaceManagement.psm1"; Name = "RunspaceManagement" },
    
    # Subsystem management
    @{ Path = "Subsystems\Registration.psm1"; Name = "Registration" },
    @{ Path = "Subsystems\Heartbeat.psm1"; Name = "Heartbeat" },
    @{ Path = "Subsystems\HealthChecks.psm1"; Name = "HealthChecks" },
    
    # Communication layer
    @{ Path = "Communication\NamedPipes.psm1"; Name = "NamedPipes" },
    @{ Path = "Communication\MessageHandling.psm1"; Name = "MessageHandling" },
    @{ Path = "Communication\EventSystem.psm1"; Name = "EventSystem" },
    
    # Recovery systems
    @{ Path = "Recovery\DependencyGraphs.psm1"; Name = "DependencyGraphs" },
    @{ Path = "Recovery\RestartLogic.psm1"; Name = "RestartLogic" },
    @{ Path = "Recovery\CircuitBreaker.psm1"; Name = "CircuitBreaker" },
    
    # Monitoring systems
    @{ Path = "Monitoring\PerformanceCounters.psm1"; Name = "PerformanceCounters" },
    @{ Path = "Monitoring\AlertSystem.psm1"; Name = "AlertSystem" },
    @{ Path = "Monitoring\Escalation.psm1"; Name = "Escalation" },
    @{ Path = "Monitoring\SystemStatusMonitoring.psm1"; Name = "SystemStatusMonitoring" }
)

# Collection to track all functions to export
$functionsToExport = @()

# Load each submodule and collect its exported functions
foreach ($submodule in $submoduleLoadOrder) {
    $submodulePath = Join-Path $PSScriptRoot $submodule.Path
    
    if (Test-Path $submodulePath) {
        try {
            # Import the submodule into a temporary variable to get its functions
            $tempModule = Import-Module $submodulePath -PassThru -Force -DisableNameChecking
            
            if ($tempModule) {
                # Get exported functions from this submodule
                $exportedFunctions = $tempModule.ExportedFunctions.Keys
                
                if ($exportedFunctions) {
                    $functionsToExport += $exportedFunctions
                    Write-Verbose "[SystemStatus] Loaded $($submodule.Name): $($exportedFunctions.Count) functions"
                    
                    # Now dot-source to bring functions into this module's scope
                    . $submodulePath
                } else {
                    Write-Verbose "[SystemStatus] No functions exported from $($submodule.Name)"
                }
                
                # Remove the temporary module
                Remove-Module $tempModule -Force -ErrorAction SilentlyContinue
            }
        } catch {
            Write-Warning "[SystemStatus] Failed to load $($submodule.Path): $_"
        }
    } else {
        Write-Verbose "[SystemStatus] Submodule not found: $($submodule.Path)"
    }
}

# Also check for functions defined directly in submodules without Export-ModuleMember
# This is a fallback for submodules that might not be properly exporting
$additionalFunctions = @(
    'Write-SystemStatusLog',
    'Test-SystemStatusSchema',
    'ConvertTo-HashTable',
    'Read-SystemStatus',
    'Write-SystemStatus',
    'Get-SystemUptime',
    'Get-SubsystemProcessId',
    'Update-SubsystemProcessInfo',
    'Test-ProcessHealth',
    'Test-ProcessPerformanceHealth',
    'Get-ProcessPerformanceCounters',
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
    'Get-ServiceDependencyGraph',
    'Get-TopologicalSort',
    'Visit-Node',
    'Restart-ServiceWithDependencies',
    'Start-ServiceRecoveryAction',
    'Invoke-CircuitBreakerCheck',
    'Measure-CommunicationPerformance',
    'Send-HealthAlert',
    'Get-AlertHistory',
    'Send-HealthCheckRequest',
    'Invoke-EscalationProcedure',
    'Initialize-SystemStatusMonitoring',
    'Stop-SystemStatusMonitoring',
    'Initialize-SubsystemRunspaces',
    'Start-SubsystemSession',
    'Stop-SubsystemRunspaces'
)

# Check which additional functions are actually available
$availableFunctions = @()
foreach ($func in $additionalFunctions) {
    if (Get-Command $func -ErrorAction SilentlyContinue) {
        $availableFunctions += $func
    }
}

# Combine all functions to export
$allFunctionsToExport = $functionsToExport + $availableFunctions | Select-Object -Unique

Write-Host "[SystemStatus] Modular Unity-Claude-SystemStatus loaded successfully ($($allFunctionsToExport.Count) functions)" -ForegroundColor Green

# Export all collected functions
if ($allFunctionsToExport.Count -gt 0) {
    Export-ModuleMember -Function $allFunctionsToExport
} else {
    Write-Warning "[SystemStatus] No functions to export!"
}
# SIG # Begin signature block
# MIIFqQYJKoZIhvcNAQcCoIIFmjCCBZYCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQU82FX1cawJfhQtmXoFj2SGhDQ
# HEugggMwMIIDLDCCAhSgAwIBAgIQdR0W2SKoK5VE8JId4ZxrRTANBgkqhkiG9w0B
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
# CQQxFgQU/ay7JDbgmQBG/Dr65RlcmbJ3ltkwDQYJKoZIhvcNAQEBBQAEggEAqVJw
# VGYVK0TA6i6fxpeevOnhORZUWcR2fiyyeSOG5chZKwd4KriGIJYFPHZCQNb3DvXj
# Z8lMU3lpGpnMWd6K0qLrI4Jb4Cy8/zKtcRoN2dMJ1UyMrmxXlGkNYVM8IUPG/Rva
# VI3//sAFMWa419b6RdlYPWiNvDskZcX5ZXByImnm5xJxrC+/kLmQmcHvVsb94PiD
# o00QPLKzWh4PqcVqIaxXxVnQKXl4E9EJcxaXaF8fcPNbAxxn1NphCMpEiR5b+TuX
# 7dqbVEzJwoMoioc8UQrHo7nkKsfNdRobo7w5KZKTNnp2Xzm+/56z2+YZjnR6zKr6
# P1GGxEW8C10gzLyHRg==
# SIG # End signature block
