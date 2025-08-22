
function Get-ServiceDependencyGraph {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$ServiceName
    )
    
    Write-SystemStatusLog "Getting service dependency graph for: $ServiceName" -Level 'DEBUG'
    
    # Performance optimization: Skip CIM if WinRM not configured
    $useCIM = $false
    if (-not $script:WinRMChecked) {
        $script:WinRMChecked = $true
        try {
            # Quick check if WinRM is configured (timeout 1 second)
            $null = Test-WSMan -ComputerName localhost -ErrorAction Stop
            $script:WinRMAvailable = $true
            $useCIM = $true
        }
        catch {
            $script:WinRMAvailable = $false
            Write-SystemStatusLog "WinRM not configured, will use WMI for all dependency queries" -Level 'DEBUG'
        }
    }
    elseif ($script:WinRMAvailable) {
        $useCIM = $true
    }
    
    if ($useCIM) {
        try {
            # Use Get-CimInstance for better performance (Query 8 research finding)
            $cimSession = New-CimSession -ComputerName "localhost" -OperationTimeoutSec 2
            
            try {
                # Win32_DependentService for dependency relationships (Query 1 research finding)
                $dependencies = Get-CimInstance -CimSession $cimSession -ClassName Win32_DependentService |
                    Where-Object { $_.Dependent.Name -eq $ServiceName } |
                    Select-Object @{N='Service';E={$_.Dependent.Name}}, @{N='DependsOn';E={$_.Antecedent.Name}}
                
                Write-SystemStatusLog "Found $($dependencies.Count) dependencies for service: $ServiceName using CIM" -Level 'DEBUG'
                
                # Build dependency graph for topological sort (Query 6 research finding)
                $graph = @{}
                foreach ($dep in $dependencies) {
                    if (-not $graph.ContainsKey($dep.Service)) { 
                        $graph[$dep.Service] = @() 
                    }
                    $graph[$dep.Service] += $dep.DependsOn
                }
                
                Write-SystemStatusLog "Service dependency graph built successfully for: $ServiceName using CIM" -Level 'INFO'
                return $graph
            }
            finally {
                Remove-CimSession -CimSession $cimSession -ErrorAction SilentlyContinue
            }
        }
        catch {
            Write-SystemStatusLog "CIM session failed for $ServiceName, falling back to WMI - $($_.Exception.Message)" -Level 'WARNING'
            $script:WinRMAvailable = $false
        }
    }
    
    # Fallback to WMI for PowerShell 5.1 compatibility (Research finding: Query 2)
    try {
        $dependencies = Get-WmiObject -Class Win32_DependentService |
            Where-Object { $_.Dependent.Name -eq $ServiceName } |
            Select-Object @{N='Service';E={$_.Dependent.Name}}, @{N='DependsOn';E={$_.Antecedent.Name}}
        
        Write-SystemStatusLog "Found $($dependencies.Count) dependencies for service: $ServiceName using WMI" -Level 'DEBUG'
        
        # Build dependency graph for topological sort
        $graph = @{}
        foreach ($dep in $dependencies) {
            if (-not $graph.ContainsKey($dep.Service)) { 
                $graph[$dep.Service] = @() 
            }
            $graph[$dep.Service] += $dep.DependsOn
        }
        
        Write-SystemStatusLog "Service dependency graph built successfully for: $ServiceName using WMI" -Level 'INFO'
        return $graph
    }
    catch {
        Write-SystemStatusLog "WMI query failed for $ServiceName - $($_.Exception.Message)" -Level 'ERROR'
        return @{}
    }
}

# SIG # Begin signature block
# MIIFqQYJKoZIhvcNAQcCoIIFmjCCBZYCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUcPElQp2JWkJKGOSjsvyHzZi5
# 5b6gggMwMIIDLDCCAhSgAwIBAgIQdR0W2SKoK5VE8JId4ZxrRTANBgkqhkiG9w0B
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
# CQQxFgQUqfdHr7qkMZOyeHFr2jsiTOc79/EwDQYJKoZIhvcNAQEBBQAEggEAg0B9
# USc8CqWcRwcETomxqz3iGlb9l/hZ/LmYyeELZMgmH7LSpc93qetrKgtcVH5R+lHY
# cCUMKLKUWDKaOUl0yWUpvCagWTOOahZQ5gBJu/HKzf87zM1lYXPhH/qk1VqAANmm
# 2/wdGUnNi7kedrXQ+hwest5P7+qLkyckAdZTlT7u/GiZVj8KENAJhVzVFqsZGyNx
# I7LyAT3ellSFSY0bH69WQp2soV+PNWotKpNg+lrBRgRJCrMxSXhddIHMfYE7qmCC
# 71/MKMI6zJp8jCbPOXPILMV1GxLy23BY7ynasBnTv6YBKUWDlVEQdGS36FMv/EB8
# FeIzTswje5ZGtOsn3Q==
# SIG # End signature block
