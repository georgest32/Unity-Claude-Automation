
function Get-CriticalSubsystems {
    <#
    .SYNOPSIS
    Gets the list of critical subsystems for monitoring
    
    .DESCRIPTION
    Returns the critical subsystem list based on existing module dependencies from research.
    Implements enterprise pattern for critical subsystem identification.
    
    .EXAMPLE
    Get-CriticalSubsystems
    #>
    [CmdletBinding()]
    param()
    
    Write-SystemStatusLog "Getting critical subsystems list" -Level 'DEBUG'
    
    # Critical subsystems based on research and existing module dependencies
    $criticalSubsystems = @(
        @{
            Name = "Unity-Claude-Core"
            Description = "Central orchestration"
            Priority = 1
            ProcessPattern = "*Unity*"
            ServiceName = $null
        },
        @{
            Name = "Unity-Claude-AutonomousStateTracker-Enhanced"
            Description = "State management"
            Priority = 2
            ProcessPattern = "*PowerShell*"
            ServiceName = $null
        },
        @{
            Name = "Unity-Claude-IntegrationEngine"
            Description = "Master integration"
            Priority = 3
            ProcessPattern = "*PowerShell*"
            ServiceName = $null
        },
        @{
            Name = "Unity-Claude-IPC-Bidirectional"
            Description = "Communication"
            Priority = 4
            ProcessPattern = "*PowerShell*"
            ServiceName = $null
        }
    )
    
    Write-SystemStatusLog "Retrieved $($criticalSubsystems.Count) critical subsystems" -Level 'DEBUG'
    return $criticalSubsystems
}

# SIG # Begin signature block
# MIIFqQYJKoZIhvcNAQcCoIIFmjCCBZYCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUyozRhon6+nXWbbclLLY3soyC
# 986gggMwMIIDLDCCAhSgAwIBAgIQdR0W2SKoK5VE8JId4ZxrRTANBgkqhkiG9w0B
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
# CQQxFgQUcUVpjWtb+NKV60Rf7bzqzYv9c+gwDQYJKoZIhvcNAQEBBQAEggEAanLC
# 5K4JK1xaZej52CgEkyHkGQtGhPLKFG6u2Ny3F6E22Fu2nTPTNkYsii3uLnRQKiXr
# DsdH8UADYVrFxk0cGLc+v6UfF60lcMcFRwd7OstO/CIIfABJK/EBltiMsUbrghjs
# QB3DkVyB/CyihGO/nnfAoGxr8qdyUP1PT4IpcKgFn7OhbYxASXP/cMN+R3sLzl3d
# 7EjGkSyJDnKXdaZJep9uC9mf2hRdJ395CvvtmdUFbxMGLCvYHHMYhg0JnWcgmg/X
# IuFvZYdPfyuCEG4edSzcTdGffayWGswWvmYJCgOFARTU14hH3+OV9D4Xr/SU107p
# LwkM9jD1mS/NIdYdTw==
# SIG # End signature block
