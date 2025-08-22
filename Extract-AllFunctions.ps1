# Extract-AllFunctions.ps1
# Extracts all functions from main module to appropriate submodules
# Date: 2025-08-20
# Phase 4: Extract all functional groups

param(
    [string]$SourceModule = "C:\UnityProjects\Sound-and-Shoal\Unity-Claude-Automation\Modules\Unity-Claude-SystemStatus\Unity-Claude-SystemStatus.psm1",
    [string]$TargetPath = "C:\UnityProjects\Sound-and-Shoal\Unity-Claude-Automation\Modules\Unity-Claude-SystemStatus"
)

Write-Host "=== Extracting All Functions to Submodules ===" -ForegroundColor Cyan
Write-Host "Source: $SourceModule" -ForegroundColor Gray

# Read the source module
$sourceContent = Get-Content $SourceModule -Raw

# Helper function to extract functions by name
function Extract-Function {
    param($Content, $FunctionName)
    $pattern = "(?ms)^function $FunctionName\s*\{.*?^\}"
    if ($Content -match $pattern) {
        return $Matches[0]
    }
    return $null
}

# Phase 4 Hour 1: Storage and Process Functions
Write-Host "`n=== Phase 4 Hour 1: Storage & Process ===" -ForegroundColor Yellow

# Extract Storage functions
Write-Host "Extracting Storage functions..." -ForegroundColor Cyan

$storageFunctions = @{
    "StatusFileManager" = @("Read-SystemStatus", "Write-SystemStatus")
    "FileLocking" = @() # No specific file locking functions found in cleaned module
}

foreach ($module in $storageFunctions.Keys) {
    $functions = @()
    foreach ($funcName in $storageFunctions[$module]) {
        $func = Extract-Function -Content $sourceContent -FunctionName $funcName
        if ($func) {
            $functions += $func
            Write-Host "  Found: $funcName" -ForegroundColor Green
        }
    }
    
    if ($functions.Count -gt 0) {
        $moduleContent = @"
# $module.psm1
# $(if ($module -eq "StatusFileManager") { "System status file read/write operations" } else { "File locking and synchronization" })
# Part of Unity-Claude-SystemStatus module
# Date: 2025-08-20

`$ErrorActionPreference = "Stop"

# Import configuration
`$configPath = Join-Path `$PSScriptRoot "..\Core\Configuration.psm1"
if (Test-Path `$configPath) {
    . `$configPath
}

$($functions -join "`n`n")

# Export functions
Export-ModuleMember -Function @(
    $(($storageFunctions[$module] | ForEach-Object { "'$_'" }) -join ", ")
)
"@
        $moduleContent | Set-Content (Join-Path $TargetPath "Storage\$module.psm1") -Encoding UTF8
        Write-Host "  Created Storage\$module.psm1" -ForegroundColor Green
    }
}

# Extract Process functions
Write-Host "`nExtracting Process functions..." -ForegroundColor Cyan

$processFunctions = @{
    "ProcessTracking" = @("Get-SubsystemProcessId", "Update-SubsystemProcessInfo", "Get-SystemUptime")
    "ProcessHealth" = @("Test-ProcessHealth", "Test-ProcessPerformanceHealth", "Get-ProcessPerformanceCounters")
}

foreach ($module in $processFunctions.Keys) {
    $functions = @()
    foreach ($funcName in $processFunctions[$module]) {
        $func = Extract-Function -Content $sourceContent -FunctionName $funcName
        if ($func) {
            $functions += $func
            Write-Host "  Found: $funcName" -ForegroundColor Green
        }
    }
    
    if ($functions.Count -gt 0) {
        $moduleContent = @"
# $module.psm1
# $(if ($module -eq "ProcessTracking") { "Process ID management and tracking" } else { "Process health monitoring" })
# Part of Unity-Claude-SystemStatus module
# Date: 2025-08-20

`$ErrorActionPreference = "Stop"

# Import configuration
`$configPath = Join-Path `$PSScriptRoot "..\Core\Configuration.psm1"
if (Test-Path `$configPath) {
    . `$configPath
}

$($functions -join "`n`n")

# Export functions
Export-ModuleMember -Function @(
    $(($processFunctions[$module] | ForEach-Object { "'$_'" }) -join ", ")
)
"@
        $moduleContent | Set-Content (Join-Path $TargetPath "Process\$module.psm1") -Encoding UTF8
        Write-Host "  Created Process\$module.psm1" -ForegroundColor Green
    }
}

# Phase 4 Hour 2: Subsystem Functions
Write-Host "`n=== Phase 4 Hour 2: Subsystems ===" -ForegroundColor Yellow

$subsystemFunctions = @{
    "Registration" = @("Register-Subsystem", "Unregister-Subsystem", "Get-RegisteredSubsystems")
    "Heartbeat" = @("Send-Heartbeat", "Test-HeartbeatResponse", "Send-HeartbeatRequest")
    "HealthChecks" = @("Test-AllSubsystemHeartbeats", "Test-ServiceResponsiveness", "Test-CriticalSubsystemHealth", "Get-CriticalSubsystems")
}

foreach ($module in $subsystemFunctions.Keys) {
    $functions = @()
    foreach ($funcName in $subsystemFunctions[$module]) {
        $func = Extract-Function -Content $sourceContent -FunctionName $funcName
        if ($func) {
            $functions += $func
            Write-Host "  Found: $funcName" -ForegroundColor Green
        }
    }
    
    if ($functions.Count -gt 0) {
        $moduleContent = @"
# $module.psm1
# $(switch ($module) {
    "Registration" { "Subsystem registration and management" }
    "Heartbeat" { "Heartbeat system for subsystems" }
    "HealthChecks" { "Subsystem health check functions" }
})
# Part of Unity-Claude-SystemStatus module
# Date: 2025-08-20

`$ErrorActionPreference = "Stop"

# Import configuration
`$configPath = Join-Path `$PSScriptRoot "..\Core\Configuration.psm1"
if (Test-Path `$configPath) {
    . `$configPath
}

$($functions -join "`n`n")

# Export functions
Export-ModuleMember -Function @(
    $(($subsystemFunctions[$module] | ForEach-Object { "'$_'" }) -join ", ")
)
"@
        $moduleContent | Set-Content (Join-Path $TargetPath "Subsystems\$module.psm1") -Encoding UTF8
        Write-Host "  Created Subsystems\$module.psm1" -ForegroundColor Green
    }
}

# Phase 4 Hour 3: Communication Functions
Write-Host "`n=== Phase 4 Hour 3: Communication ===" -ForegroundColor Yellow

$communicationFunctions = @{
    "NamedPipes" = @("Initialize-NamedPipeServer", "Stop-NamedPipeServer")
    "MessageHandling" = @("New-SystemStatusMessage", "Send-SystemStatusMessage", "Receive-SystemStatusMessage", 
                          "Register-MessageHandler", "Invoke-MessageHandler", "Start-MessageProcessor", "Stop-MessageProcessor")
    "EventSystem" = @("Initialize-CrossModuleEvents", "Send-EngineEvent", "Start-SystemStatusFileWatcher", "Stop-SystemStatusFileWatcher")
}

foreach ($module in $communicationFunctions.Keys) {
    $functions = @()
    foreach ($funcName in $communicationFunctions[$module]) {
        $func = Extract-Function -Content $sourceContent -FunctionName $funcName
        if ($func) {
            $functions += $func
            Write-Host "  Found: $funcName" -ForegroundColor Green
        }
    }
    
    if ($functions.Count -gt 0) {
        $moduleContent = @"
# $module.psm1
# $(switch ($module) {
    "NamedPipes" { "Named pipe server and client" }
    "MessageHandling" { "Message processing and routing" }
    "EventSystem" { "Cross-module event system" }
})
# Part of Unity-Claude-SystemStatus module
# Date: 2025-08-20

`$ErrorActionPreference = "Stop"

# Import configuration
`$configPath = Join-Path `$PSScriptRoot "..\Core\Configuration.psm1"
if (Test-Path `$configPath) {
    . `$configPath
}

$($functions -join "`n`n")

# Export functions
Export-ModuleMember -Function @(
    $(($communicationFunctions[$module] | ForEach-Object { "'$_'" }) -join ", ")
)
"@
        $moduleContent | Set-Content (Join-Path $TargetPath "Communication\$module.psm1") -Encoding UTF8
        Write-Host "  Created Communication\$module.psm1" -ForegroundColor Green
    }
}

# Phase 4 Hour 4: Recovery and Monitoring Functions
Write-Host "`n=== Phase 4 Hour 4: Recovery & Monitoring ===" -ForegroundColor Yellow

$recoveryFunctions = @{
    "DependencyGraphs" = @("Get-ServiceDependencyGraph", "Get-TopologicalSort", "Visit-Node")
    "RestartLogic" = @("Restart-ServiceWithDependencies", "Start-ServiceRecoveryAction")
    "CircuitBreaker" = @("Invoke-CircuitBreakerCheck")
}

foreach ($module in $recoveryFunctions.Keys) {
    $functions = @()
    foreach ($funcName in $recoveryFunctions[$module]) {
        $func = Extract-Function -Content $sourceContent -FunctionName $funcName
        if ($func) {
            $functions += $func
            Write-Host "  Found: $funcName" -ForegroundColor Green
        }
    }
    
    if ($functions.Count -gt 0) {
        $moduleContent = @"
# $module.psm1
# $(switch ($module) {
    "DependencyGraphs" { "Service dependency tracking" }
    "RestartLogic" { "Service restart and recovery logic" }
    "CircuitBreaker" { "Circuit breaker pattern implementation" }
})
# Part of Unity-Claude-SystemStatus module
# Date: 2025-08-20

`$ErrorActionPreference = "Stop"

# Import configuration
`$configPath = Join-Path `$PSScriptRoot "..\Core\Configuration.psm1"
if (Test-Path `$configPath) {
    . `$configPath
}

$($functions -join "`n`n")

# Export functions
Export-ModuleMember -Function @(
    $(($recoveryFunctions[$module] | ForEach-Object { "'$_'" }) -join ", ")
)
"@
        $moduleContent | Set-Content (Join-Path $TargetPath "Recovery\$module.psm1") -Encoding UTF8
        Write-Host "  Created Recovery\$module.psm1" -ForegroundColor Green
    }
}

$monitoringFunctions = @{
    "PerformanceCounters" = @("Measure-CommunicationPerformance")
    "AlertSystem" = @("Send-HealthAlert", "Get-AlertHistory", "Send-HealthCheckRequest")
    "Escalation" = @("Invoke-EscalationProcedure")
}

foreach ($module in $monitoringFunctions.Keys) {
    $functions = @()
    foreach ($funcName in $monitoringFunctions[$module]) {
        $func = Extract-Function -Content $sourceContent -FunctionName $funcName
        if ($func) {
            $functions += $func
            Write-Host "  Found: $funcName" -ForegroundColor Green
        }
    }
    
    if ($functions.Count -gt 0) {
        $moduleContent = @"
# $module.psm1
# $(switch ($module) {
    "PerformanceCounters" { "Performance metrics collection" }
    "AlertSystem" { "Alert generation and management" }
    "Escalation" { "Alert escalation procedures" }
})
# Part of Unity-Claude-SystemStatus module
# Date: 2025-08-20

`$ErrorActionPreference = "Stop"

# Import configuration
`$configPath = Join-Path `$PSScriptRoot "..\Core\Configuration.psm1"
if (Test-Path `$configPath) {
    . `$configPath
}

$($functions -join "`n`n")

# Export functions
Export-ModuleMember -Function @(
    $(($monitoringFunctions[$module] | ForEach-Object { "'$_'" }) -join ", ")
)
"@
        $moduleContent | Set-Content (Join-Path $TargetPath "Monitoring\$module.psm1") -Encoding UTF8
        Write-Host "  Created Monitoring\$module.psm1" -ForegroundColor Green
    }
}

# Extract main monitoring functions
$mainMonitoringFuncs = @("Initialize-SystemStatusMonitoring", "Stop-SystemStatusMonitoring")
$mainMonitoring = @()
foreach ($funcName in $mainMonitoringFuncs) {
    $func = Extract-Function -Content $sourceContent -FunctionName $funcName
    if ($func) {
        $mainMonitoring += $func
        Write-Host "  Found: $funcName" -ForegroundColor Green
    }
}

if ($mainMonitoring.Count -gt 0) {
    $monitoringMainContent = @"
# SystemStatusMonitoring.psm1
# Main monitoring orchestration functions
# Part of Unity-Claude-SystemStatus module
# Date: 2025-08-20

`$ErrorActionPreference = "Stop"

# Import configuration
`$configPath = Join-Path `$PSScriptRoot "..\Core\Configuration.psm1"
if (Test-Path `$configPath) {
    . `$configPath
}

$($mainMonitoring -join "`n`n")

# Export functions
Export-ModuleMember -Function @(
    'Initialize-SystemStatusMonitoring',
    'Stop-SystemStatusMonitoring'
)
"@
    $monitoringMainContent | Set-Content (Join-Path $TargetPath "Monitoring\SystemStatusMonitoring.psm1") -Encoding UTF8
    Write-Host "  Created Monitoring\SystemStatusMonitoring.psm1" -ForegroundColor Green
}

# Extract Runspace functions (put in Process folder for now)
$runspaceFuncs = @("Initialize-SubsystemRunspaces", "Start-SubsystemSession", "Stop-SubsystemRunspaces")
$runspaceFunctions = @()
foreach ($funcName in $runspaceFuncs) {
    $func = Extract-Function -Content $sourceContent -FunctionName $funcName
    if ($func) {
        $runspaceFunctions += $func
        Write-Host "  Found: $funcName" -ForegroundColor Green
    }
}

if ($runspaceFunctions.Count -gt 0) {
    $runspaceContent = @"
# RunspaceManagement.psm1
# Runspace management for subsystems
# Part of Unity-Claude-SystemStatus module
# Date: 2025-08-20

`$ErrorActionPreference = "Stop"

# Import configuration
`$configPath = Join-Path `$PSScriptRoot "..\Core\Configuration.psm1"
if (Test-Path `$configPath) {
    . `$configPath
}

$($runspaceFunctions -join "`n`n")

# Export functions
Export-ModuleMember -Function @(
    'Initialize-SubsystemRunspaces',
    'Start-SubsystemSession',
    'Stop-SubsystemRunspaces'
)
"@
    $runspaceContent | Set-Content (Join-Path $TargetPath "Process\RunspaceManagement.psm1") -Encoding UTF8
    Write-Host "  Created Process\RunspaceManagement.psm1" -ForegroundColor Green
}

Write-Host "`n=== Function Extraction Complete ===" -ForegroundColor Green
Write-Host "All functions have been extracted to their respective submodules" -ForegroundColor Cyan
Write-Host "`nNext step: Update the main loader module and test integration" -ForegroundColor Yellow
# SIG # Begin signature block
# MIIFqQYJKoZIhvcNAQcCoIIFmjCCBZYCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUDlvaJOJ8oa3qWXoYPahfG7Sn
# VZ2gggMwMIIDLDCCAhSgAwIBAgIQdR0W2SKoK5VE8JId4ZxrRTANBgkqhkiG9w0B
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
# CQQxFgQUS3kXn7jdLsQ5K1EvnEVaej2Kz4wwDQYJKoZIhvcNAQEBBQAEggEAOxu6
# 8L6+ceAoJYXvyj1n+F53ntoll0mW4dODFIN4kyDjVGcQt1R9MqWZm9UGL/lInvVj
# scrmhGiQXSyuyE1XLV51Zqn1PI1rbfhBxw0Ch9Snvzklztsy6+80YstDf0u1jEs6
# 2uXf1QX8Vp1RVARrvPLa/IG1fJHlCpZMbijh63A1GKxhWLPrQ1Y7XL0DzmjOsRUv
# 0aO8F0eZTDzG2WJ8sAE2n/krYJp1DsbUpS9XOf8Wyh5eyRy6Hz00mgqt4AVYsht9
# bkkdFW/pmup3FPEDlcAdG3oOCibmkeFErSKYvdHkyBdjM6yx0uFEMmjBZhD3Mh7r
# /XmykHFunAe5GwkyOw==
# SIG # End signature block
