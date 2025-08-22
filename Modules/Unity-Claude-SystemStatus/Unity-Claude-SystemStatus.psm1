# Unity-Claude-SystemStatus Module
# Modular refactor with functions split by responsibility

# 1) Resolve module root
$PSModuleRoot = Split-Path -Parent $PSCommandPath

# 2) Dot-source all module parts (excluding the psm1 itself)
Get-ChildItem -Path $PSModuleRoot -Recurse -Filter *.ps1 |
    Where-Object { $_.FullName -ne $PSCommandPath } |
    ForEach-Object { . $_.FullName }

# 3) Initialize configuration after loading all functions
if (Get-Command Initialize-SystemStatusConfig -ErrorAction SilentlyContinue) {
    Initialize-SystemStatusConfig
}

# 4) Export *after* everything is loaded
Export-ModuleMember -Function `
    ConvertTo-HashTable, Get-AlertHistory, Get-CriticalSubsystems, `
    Get-ProcessPerformanceCounters, Get-RegisteredSubsystems, Get-ServiceDependencyGraph, `
    Get-SubsystemCircuitBreakerConfig, Get-SubsystemManifests, Get-SubsystemStartupOrder, Get-SubsystemProcessId, Get-SystemStatusConfiguration, Get-SystemUptime, Get-TopologicalSort, `
    Get-SystemPerformanceMetrics, `
    Initialize-CrossModuleEvents, Initialize-NamedPipeServer, Initialize-SubsystemRunspaces, `
    Initialize-SystemStatusConfig, Initialize-SystemStatusMonitoring, Invoke-CircuitBreakerCheck, `
    Invoke-EscalationProcedure, Invoke-LogRotation, Invoke-MessageHandler, Invoke-ParallelHealthCheck, Measure-CommunicationPerformance, `
    New-DiagnosticReport, New-SubsystemMutex, Remove-SubsystemMutex, Test-SubsystemMutex, `
    New-SystemStatusMessage, Read-SystemStatus, Receive-SystemStatusMessage, Register-MessageHandler, `
    Register-Subsystem, Register-SubsystemFromManifest, Restart-ServiceWithDependencies, `
    Search-SystemStatusLogs, Send-EngineEvent, Send-HealthAlert, Send-HealthCheckRequest, Send-Heartbeat, `
    Send-HeartbeatRequest, Send-SystemStatusMessage, Start-AutonomousAgentSafe, Start-TraceOperation, Stop-TraceOperation, `
    Start-MessageProcessor, Start-ServiceRecoveryAction, Start-SubsystemSafe, Start-SubsystemSession, `
    Start-SystemStatusFileWatcher, Stop-MessageProcessor, Stop-NamedPipeServer, `
    Stop-SubsystemRunspaces, Stop-SystemStatusFileWatcher, Stop-SystemStatusMonitoring, `
    Test-AllSubsystemHeartbeats, Test-AutonomousAgentStatus, Test-CriticalSubsystemHealth, Test-DiagnosticMode, `
    Test-HeartbeatResponse, Test-ProcessHealth, Test-ProcessPerformanceHealth, `
    Test-ServiceResponsiveness, Test-SubsystemManifest, Test-SubsystemRunning, Test-SubsystemStatus, Test-SystemStatusConfiguration, Test-SystemStatusSchema, `
    Unregister-Subsystem, Update-SubsystemProcessInfo, Write-SystemStatus, Write-SystemStatusLog, Write-TraceLog, `
    Enable-DiagnosticMode, Disable-DiagnosticMode, Enable-TraceLogging, Disable-TraceLogging, `
    Initialize-DiagnosticPerformanceMonitoring, Stop-DiagnosticPerformanceMonitoring, Register-DiagnosticTimeout, Test-ManifestSecurity
# SIG # Begin signature block
# MIIFqQYJKoZIhvcNAQcCoIIFmjCCBZYCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQU/HuSvH3cKwCG4tQdFToVQxXz
# 0uagggMwMIIDLDCCAhSgAwIBAgIQdR0W2SKoK5VE8JId4ZxrRTANBgkqhkiG9w0B
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
# CQQxFgQUp0FOesA66UHokmI3Kz0gTYO4Q6AwDQYJKoZIhvcNAQEBBQAEggEAbG0c
# ODOhYfT6dV8IOwIxZK0t9uyAc0kOxyhuv9ubkhpexxa8iMXt34A7ImVPhYg3TMQ/
# XvPXCpHJOcpGfNquaTfF1BuUGEFWIRHtoMhSO/xDzTiuud5iau90oaNYqvD7FFQm
# YfgAi2QFqhyKuPjM05//MEdStoauuVRwZZnbXqgDewEQC4ImJZzmJ5qwoynmQn//
# dTXdlyUjISTgI7pWT3/BDHStUgsH03XDNWzWfdmQw3BOqyluFJQcKiwUMi932HUs
# H9JVDuwkMkdc3SLF2rgF/ikB+I+wZFj+LbqRJfffKnPLlDj7NbLWWSPH2DH32PNt
# /Gs83Hous1UltiRwrQ==
# SIG # End signature block
