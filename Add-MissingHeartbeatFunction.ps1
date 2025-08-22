# Add-MissingHeartbeatFunction.ps1
# Adds the missing Test-AllSubsystemHeartbeats function to the SystemStatus module

$modulePath = "C:\UnityProjects\Sound-and-Shoal\Unity-Claude-Automation\Modules\Unity-Claude-SystemStatus\Unity-Claude-SystemStatus.psm1"

# Read current content
$content = Get-Content $modulePath -Raw

# Add the missing function before the Export-ModuleMember section
$missingFunction = @'

function Test-AllSubsystemHeartbeats {
    <#
    .SYNOPSIS
    Tests heartbeat status for all registered subsystems
    
    .DESCRIPTION
    Checks heartbeat timestamps and health scores for all subsystems
    
    .PARAMETER StatusData
    The system status data hashtable
    #>
    [CmdletBinding()]
    param(
        [hashtable]$StatusData = $script:SystemStatusData
    )
    
    Write-SystemStatusLog "Testing heartbeats for all subsystems..." -Level 'DEBUG'
    
    $results = @{
        Healthy = @()
        Warning = @()
        Critical = @()
        Unknown = @()
    }
    
    $heartbeatThreshold = 120  # 2 minutes
    $currentTime = Get-Date
    
    foreach ($subsystem in $StatusData.Subsystems.Keys) {
        $subsystemData = $StatusData.Subsystems[$subsystem]
        
        if ($subsystemData.LastHeartbeat) {
            $lastHeartbeat = [DateTime]::Parse($subsystemData.LastHeartbeat)
            $timeSinceHeartbeat = ($currentTime - $lastHeartbeat).TotalSeconds
            
            if ($timeSinceHeartbeat -lt 60) {
                $results.Healthy += $subsystem
            } elseif ($timeSinceHeartbeat -lt $heartbeatThreshold) {
                $results.Warning += $subsystem
            } else {
                $results.Critical += $subsystem
            }
            
            Write-SystemStatusLog "Subsystem $subsystem - Last heartbeat: $($timeSinceHeartbeat)s ago" -Level 'DEBUG'
        } else {
            $results.Unknown += $subsystem
            Write-SystemStatusLog "Subsystem $subsystem - No heartbeat recorded" -Level 'WARN'
        }
    }
    
    # Log summary
    Write-SystemStatusLog "Heartbeat check complete - Healthy: $($results.Healthy.Count), Warning: $($results.Warning.Count), Critical: $($results.Critical.Count)" -Level 'INFO'
    
    return $results
}

'@

# Find where to insert (just before Export-ModuleMember)
$exportIndex = $content.IndexOf("Export-ModuleMember")

if ($exportIndex -gt 0) {
    # Insert the function before Export-ModuleMember
    $newContent = $content.Insert($exportIndex - 1, $missingFunction)
    
    # Also update the Export-ModuleMember to include this function
    $newContent = $newContent -replace '("Stop-SystemStatusFileWatcher")', '$1,
    "Test-AllSubsystemHeartbeats"'
    
    # Write back
    $newContent | Set-Content $modulePath -Encoding UTF8
    
    Write-Host "Successfully added Test-AllSubsystemHeartbeats function" -ForegroundColor Green
} else {
    Write-Host "Could not find Export-ModuleMember section" -ForegroundColor Red
}
# SIG # Begin signature block
# MIIFqQYJKoZIhvcNAQcCoIIFmjCCBZYCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUgveik7liK5Hk6SL9wTWWm0k6
# IdCgggMwMIIDLDCCAhSgAwIBAgIQdR0W2SKoK5VE8JId4ZxrRTANBgkqhkiG9w0B
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
# CQQxFgQUwMEJUK6T7BerS/vsZlxPZQDqL+0wDQYJKoZIhvcNAQEBBQAEggEArgMl
# ZJT3oqDdrWPFU/szYYf+4VF+hauN/S6B+XT8Tz+xtfsuv3pnO9/Vc7+fztBbiu3P
# TGW1lBCJO0c4W/uwTuA5eZkaK8LnaUSZGF38Ki0zy4Qo08wb+oYIMt8YZ9q9G4IB
# KJF7AhpsUtQEQJxfGxwkQUafQ4WnfgaOi7ELETYZHkUXT4ezbvYyAqjcLepAKR43
# k+4JzgtGOdXuuWjZVXl5J1fGm3hYGmWy5J76R3Bxc7VQAGk1irXKb9qPyVppkZHo
# IDS7BtpzD73nPTxn7En4DwEMLwRfa14CXovBum4N/AQrcW0SfDMKTGoLmz30skWx
# XQITYlPCPw0EwSIgsw==
# SIG # End signature block
