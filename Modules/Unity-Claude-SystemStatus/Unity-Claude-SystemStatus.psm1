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
    Initialize-CommunicationState, Initialize-CrossModuleEvents, Initialize-NamedPipeServer, Initialize-SubsystemRunspaces, `
    Initialize-SystemStatusConfig, Initialize-SystemStatusMonitoring, Invoke-CircuitBreakerCheck, `
    Invoke-EscalationProcedure, Invoke-LogRotation, Invoke-MessageHandler, Invoke-ParallelHealthCheck, Measure-CommunicationPerformance, `
    New-DiagnosticReport, New-SubsystemMutex, Remove-SubsystemMutex, Test-SubsystemMutex, `
    New-SystemStatusMessage, Read-SystemStatus, Receive-SystemStatusMessage, Register-MessageHandler, `
    Register-Subsystem, Register-SubsystemFromManifest, Restart-ServiceWithDependencies, `
    Search-SystemStatusLogs, Send-EngineEvent, Send-HealthAlert, Send-HealthCheckRequest, Send-Heartbeat, `
    Send-HeartbeatRequest, Send-SystemStatusMessage, Start-AutonomousAgentSafe, Start-CLIOrchestratorSafe, Start-TraceOperation, Stop-TraceOperation, `
    Start-MessageProcessor, Start-ServiceRecoveryAction, Start-SubsystemSafe, Start-SubsystemSession, `
    Start-SystemStatusFileWatcher, Stop-MessageProcessor, Stop-NamedPipeServer, `
    Stop-SubsystemRunspaces, Stop-SystemStatusFileWatcher, Stop-SystemStatusMonitoring, `
    Test-AllSubsystemHeartbeats, Test-AutonomousAgentStatus, Test-CLIOrchestratorStatus, Test-CriticalSubsystemHealth, Test-DiagnosticMode, `
    Test-HeartbeatResponse, Test-ProcessHealth, Test-ProcessPerformanceHealth, `
    Test-ServiceResponsiveness, Test-SubsystemManifest, Test-SubsystemRunning, Test-SubsystemStatus, Test-SystemStatusConfiguration, Test-SystemStatusSchema, `
    Unregister-Subsystem, Update-SubsystemProcessInfo, Write-SystemStatus, Write-SystemStatusLog, Write-TraceLog, `
    Enable-DiagnosticMode, Disable-DiagnosticMode, Enable-TraceLogging, Disable-TraceLogging, `
    Initialize-DiagnosticPerformanceMonitoring, Stop-DiagnosticPerformanceMonitoring, Register-DiagnosticTimeout, Test-ManifestSecurity
# SIG # Begin signature block
# MIIFzgYJKoZIhvcNAQcCoIIFvzCCBbsCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCDB+obgXtiwfEGc
# xkjIkojBQZMjM7tjk8FvqoKk3BcH9KCCAzAwggMsMIICFKADAgECAhB1HRbZIqgr
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
# MAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIPaDgETborkV/8HVdkEzoGL6
# +uEu+tNnco1xdliz0l/9MA0GCSqGSIb3DQEBAQUABIIBAGio2KPNeo7QBYzKxhek
# 7L35Zs5Zmh1Rt+TXG0FQX/PptsSyCQtoy0uFCSG71fQ5eiRchIkMdwKvieYvoAh8
# 8GBbAr4c/THbZlKAxxWVTNgZBF4EW195mMc5UwHlVqfgIlhbl85st7S8KmV3oizz
# 0LC4iNtFH5BVc+elOIAF8+rAlMC3hoikZPiWUBzx+m7o3j+h+ZS1wVaS+aQV4BM1
# szKuQOYBS1OI67piDRcz4LHPDsn7/kVpxTi+A6zUXQaN8YeIQYj+L9asau3li4Ui
# krYyVPPOg2w35kRbkcyTuGQmYj1z0jvcHcZ/z/YUhz9rHyKTMbPDIMIzwjX0ktDK
# h6A=
# SIG # End signature block
