# Fix-SubmoduleExports.ps1
# Fixes Export-ModuleMember statements in all submodules
# Date: 2025-08-20

param(
    [string]$ModulePath = "C:\UnityProjects\Sound-and-Shoal\Unity-Claude-Automation\Modules\Unity-Claude-SystemStatus"
)

Write-Host "=== Fixing Submodule Exports ===" -ForegroundColor Cyan

# Define what functions each submodule should export
$moduleExports = @{
    "Core\Logging.psm1" = @('Write-SystemStatusLog')
    "Core\Validation.psm1" = @('Test-SystemStatusSchema', 'ConvertTo-HashTable')
    "Core\Configuration.psm1" = @() # Only exports variables
    
    "Storage\StatusFileManager.psm1" = @('Read-SystemStatus', 'Write-SystemStatus')
    "Storage\FileLocking.psm1" = @() # No functions in cleaned version
    
    "Process\ProcessTracking.psm1" = @('Get-SubsystemProcessId', 'Update-SubsystemProcessInfo', 'Get-SystemUptime')
    "Process\ProcessHealth.psm1" = @('Test-ProcessHealth', 'Test-ProcessPerformanceHealth', 'Get-ProcessPerformanceCounters')
    "Process\RunspaceManagement.psm1" = @('Initialize-SubsystemRunspaces', 'Start-SubsystemSession', 'Stop-SubsystemRunspaces')
    
    "Subsystems\Registration.psm1" = @('Register-Subsystem', 'Unregister-Subsystem', 'Get-RegisteredSubsystems')
    "Subsystems\Heartbeat.psm1" = @('Send-Heartbeat', 'Test-HeartbeatResponse', 'Send-HeartbeatRequest')
    "Subsystems\HealthChecks.psm1" = @('Test-AllSubsystemHeartbeats', 'Test-ServiceResponsiveness', 'Test-CriticalSubsystemHealth', 'Get-CriticalSubsystems')
    
    "Communication\NamedPipes.psm1" = @('Initialize-NamedPipeServer', 'Stop-NamedPipeServer')
    "Communication\MessageHandling.psm1" = @('New-SystemStatusMessage', 'Send-SystemStatusMessage', 'Receive-SystemStatusMessage', 'Register-MessageHandler', 'Invoke-MessageHandler', 'Start-MessageProcessor', 'Stop-MessageProcessor')
    "Communication\EventSystem.psm1" = @('Initialize-CrossModuleEvents', 'Send-EngineEvent', 'Start-SystemStatusFileWatcher', 'Stop-SystemStatusFileWatcher')
    
    "Recovery\DependencyGraphs.psm1" = @('Get-ServiceDependencyGraph', 'Get-TopologicalSort', 'Visit-Node')
    "Recovery\RestartLogic.psm1" = @('Restart-ServiceWithDependencies', 'Start-ServiceRecoveryAction')
    "Recovery\CircuitBreaker.psm1" = @('Invoke-CircuitBreakerCheck')
    
    "Monitoring\PerformanceCounters.psm1" = @('Measure-CommunicationPerformance')
    "Monitoring\AlertSystem.psm1" = @('Send-HealthAlert', 'Get-AlertHistory', 'Send-HealthCheckRequest')
    "Monitoring\Escalation.psm1" = @('Invoke-EscalationProcedure')
    "Monitoring\SystemStatusMonitoring.psm1" = @('Initialize-SystemStatusMonitoring', 'Stop-SystemStatusMonitoring')
}

foreach ($module in $moduleExports.Keys) {
    $modulePath = Join-Path $ModulePath $module
    
    if (Test-Path $modulePath) {
        $content = Get-Content $modulePath -Raw
        $functions = $moduleExports[$module]
        
        if ($functions.Count -gt 0) {
            # Check if Export-ModuleMember exists
            if ($content -match 'Export-ModuleMember.*-Function.*@\(\s*\)') {
                # Replace empty export with actual functions
                $functionList = ($functions | ForEach-Object { "'$_'" }) -join ",`n    "
                $newExport = "Export-ModuleMember -Function @(`n    $functionList`n)"
                $content = $content -replace 'Export-ModuleMember.*-Function.*@\(\s*\)', $newExport
                
                $content | Set-Content $modulePath -Encoding UTF8
                Write-Host "Fixed exports in: $module" -ForegroundColor Green
                Write-Host "  Exporting: $($functions -join ', ')" -ForegroundColor Gray
            } else {
                Write-Host "No empty export found in: $module" -ForegroundColor Yellow
            }
        } else {
            Write-Host "No functions to export in: $module" -ForegroundColor Gray
        }
    } else {
        Write-Warning "Module not found: $module"
    }
}

# Special case for Configuration.psm1 - it exports variables
$configPath = Join-Path $ModulePath "Core\Configuration.psm1"
if (Test-Path $configPath) {
    $content = Get-Content $configPath -Raw
    if ($content -notmatch 'Export-ModuleMember.*-Variable') {
        # Configuration module already has correct variable exports
        Write-Host "Configuration.psm1 already has correct exports" -ForegroundColor Green
    }
}

Write-Host "`n=== Export Fixes Complete ===" -ForegroundColor Green
# SIG # Begin signature block
# MIIFqQYJKoZIhvcNAQcCoIIFmjCCBZYCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUd0/YyHyWoA+fmae7qKY5fAT/
# XV6gggMwMIIDLDCCAhSgAwIBAgIQdR0W2SKoK5VE8JId4ZxrRTANBgkqhkiG9w0B
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
# CQQxFgQUZvmiCuQabQ0M6QBckSkw8y/9DoYwDQYJKoZIhvcNAQEBBQAEggEANqqb
# qEPBQNmmCUow6O6NZ9X2BbJ3pJzyZclOUYl1qFfRx3Ou19k5dbi/2v1oXMXPKZ2A
# aTvA4iMyN0Sx4H3aHx6FuTeJjdvcS4fy/yjBAa0ceqaUIWGIAYcIIxIEHyfizWA+
# Su/iQH4BLXOV5sHelx6s5ZIxqSD6lbrq4nDdnRoj4WHBXHjaFcobBS1WLGYESoGW
# vcMGifXWDeCrZYThF9PcgQsU7sxg0AR1LzTbE843puf8EepRWCymuzFEhs4qS6h0
# edoQ1sYOcFidukDchJ03j2rKaZxoTVRzoJ6BQQaToMuDsw4ychF5HPo5Yd5BOx8Z
# FupKUkAN6qe8a2DaGg==
# SIG # End signature block
