
function Initialize-SubsystemRunspaces {
    [CmdletBinding()]
    param(
        [int]$MinRunspaces = 1,
        [int]$MaxRunspaces = 3
    )
    
    Write-SystemStatusLog "Initializing subsystem runspaces (Min: $MinRunspaces, Max: $MaxRunspaces)" -Level 'INFO'
    
    try {
        # Session isolation with InitialSessionState (Query 3 research finding)
        $initialSessionState = [System.Management.Automation.Runspaces.InitialSessionState]::CreateDefault()
        
        # Add required modules to session state
        $existingModules = @(
            "Unity-Claude-Core",
            "Unity-Claude-SystemStatus", 
            "SafeCommandExecution"
        )
        
        foreach ($moduleName in $existingModules) {
            try {
                $moduleInfo = Get-Module -Name $moduleName -ListAvailable | Select-Object -First 1
                if ($moduleInfo) {
                    $initialSessionState.ImportPSModule($moduleInfo.Path)
                    Write-SystemStatusLog "Added module to runspace session: $moduleName" -Level 'DEBUG'
                } else {
                    Write-SystemStatusLog "Module not found for runspace session: $moduleName" -Level 'WARNING'
                }
            }
            catch {
                Write-SystemStatusLog "Error adding module to runspace session ($moduleName) - $($_.Exception.Message)" -Level 'WARNING'
            }
        }
        
        # Thread safety patterns (Query 9 research finding) - Pass InitialSessionState during creation
        $runspacePool = [runspacefactory]::CreateRunspacePool($MinRunspaces, $MaxRunspaces, $initialSessionState, $Host)
        $runspacePool.Open()
        
        # Synchronized collections for thread safety (Query 9 research finding)  
        $synchronizedResults = [System.Collections.ArrayList]::Synchronized((New-Object System.Collections.ArrayList))
        
        $runspaceContext = @{
            Pool = $runspacePool
            InitialState = $initialSessionState
            SynchronizedResults = $synchronizedResults
            Created = Get-Date
            MinRunspaces = $MinRunspaces
            MaxRunspaces = $MaxRunspaces
        }
        
        # Store in script scope for cleanup
        if (-not $script:RunspaceManagement) {
            $script:RunspaceManagement = @{}
        }
        $script:RunspaceManagement.Context = $runspaceContext
        
        Write-SystemStatusLog "Subsystem runspaces initialized successfully" -Level 'OK'
        return $runspaceContext
        
    }
    catch {
        Write-SystemStatusLog "Error initializing subsystem runspaces - $($_.Exception.Message)" -Level 'ERROR'
        throw
    }
}

# SIG # Begin signature block
# MIIFqQYJKoZIhvcNAQcCoIIFmjCCBZYCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUGKXtf/tT+xE99S81i9I+fYc3
# bO6gggMwMIIDLDCCAhSgAwIBAgIQdR0W2SKoK5VE8JId4ZxrRTANBgkqhkiG9w0B
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
# CQQxFgQUM1FaSDy/8+2ByVHy2PG2A126q6owDQYJKoZIhvcNAQEBBQAEggEAH92k
# zka2vNDsLxNwo1xZDcEZ9uop4/LiduKqA7xd5wwWw9Je7wFEwHUuGzUbSIYvYjOG
# m4DYVPcMadAuftwzjBNXOPLk7ab45dIEwpuU/VGKg7NCDbDq+bsKoX4mvnrBmTg/
# KKvmHrPCtpmhkWAtb3Y3XyhtnHRsqwsXW9f9EcTCjKmm+HB0Q280TjlpveUCeNSy
# P2Den/SFz3hYO6IgqXK61Mzos2LJqelbohMOg0f4TKIKEhzkO2wp1xbsqBf3VHRb
# 6U2FAmJmJKBVFYh0JQjT0es5d2Ko7cUx++RopHsJTD+fjsi7CQVpYk6c2xqDUXfd
# 8SsqDGQeHz56A1pUig==
# SIG # End signature block
