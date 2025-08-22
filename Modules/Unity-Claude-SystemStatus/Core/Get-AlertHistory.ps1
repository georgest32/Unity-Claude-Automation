
function Get-AlertHistory {
    <#
    .SYNOPSIS
    Gets health alert history for monitoring and analysis
    
    .DESCRIPTION
    Retrieves health alert history with filtering and analysis capabilities:
    - Time-based filtering
    - Subsystem-specific filtering
    - Alert level filtering
    - Statistical analysis
    
    .PARAMETER Hours
    Number of hours of history to retrieve
    
    .PARAMETER SubsystemName
    Filter by specific subsystem name
    
    .PARAMETER AlertLevel
    Filter by alert level
    
    .EXAMPLE
    Get-AlertHistory -Hours 24 -AlertLevel "Critical"
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false)]
        [int]$Hours = 24,
        
        [Parameter(Mandatory=$false)]
        [string]$SubsystemName = $null,
        
        [Parameter(Mandatory=$false)]
        [ValidateSet("Info", "Warning", "Critical")]
        [string]$AlertLevel = $null
    )
    
    Write-SystemStatusLog "Retrieving alert history: Hours=$Hours, Subsystem=$SubsystemName, Level=$AlertLevel" -Level 'DEBUG'
    
    try {
        if (-not $script:HealthAlertHistory) {
            Write-SystemStatusLog "No health alert history available" -Level 'DEBUG'
            return @{
                TotalAlerts = 0
                FilteredAlerts = @()
                Statistics = @{
                    InfoCount = 0
                    WarningCount = 0
                    CriticalCount = 0
                    SubsystemCounts = @{}
                }
            }
        }
        
        $cutoffTime = (Get-Date).AddHours(-$Hours)
        $filteredAlerts = $script:HealthAlertHistory
        
        # Apply time filter
        $filteredAlerts = $filteredAlerts | Where-Object { 
            [DateTime]::Parse($_.Timestamp) -gt $cutoffTime 
        }
        
        # Apply subsystem filter
        if ($SubsystemName) {
            $filteredAlerts = $filteredAlerts | Where-Object { 
                $_.SubsystemName -eq $SubsystemName 
            }
        }
        
        # Apply alert level filter
        if ($AlertLevel) {
            $filteredAlerts = $filteredAlerts | Where-Object { 
                $_.AlertLevel -eq $AlertLevel 
            }
        }
        
        # Calculate statistics
        $statistics = @{
            InfoCount = ($filteredAlerts | Where-Object { $_.AlertLevel -eq "Info" }).Count
            WarningCount = ($filteredAlerts | Where-Object { $_.AlertLevel -eq "Warning" }).Count
            CriticalCount = ($filteredAlerts | Where-Object { $_.AlertLevel -eq "Critical" }).Count
            SubsystemCounts = @{}
        }
        
        # Calculate subsystem counts
        $subsystemGroups = $filteredAlerts | Group-Object -Property SubsystemName
        foreach ($group in $subsystemGroups) {
            $statistics.SubsystemCounts[$group.Name] = $group.Count
        }
        
        $result = @{
            TotalAlerts = $filteredAlerts.Count
            FilteredAlerts = $filteredAlerts
            Statistics = $statistics
            TimeRange = @{
                From = $cutoffTime.ToString('yyyy-MM-dd HH:mm:ss')
                To = (Get-Date).ToString('yyyy-MM-dd HH:mm:ss')
                Hours = $Hours
            }
        }
        
        Write-SystemStatusLog "Retrieved $($result.TotalAlerts) alerts from history" -Level 'DEBUG'
        return $result
        
    } catch {
        Write-SystemStatusLog "Error retrieving alert history: $($_.Exception.Message)" -Level 'ERROR'
        throw
    }
}

# SIG # Begin signature block
# MIIFqQYJKoZIhvcNAQcCoIIFmjCCBZYCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUifM6KQVtqbkwdQCa7foa/xZH
# /a2gggMwMIIDLDCCAhSgAwIBAgIQdR0W2SKoK5VE8JId4ZxrRTANBgkqhkiG9w0B
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
# CQQxFgQUFTXZSR2eX5UbMGMvQDNAAMLV7RAwDQYJKoZIhvcNAQEBBQAEggEATdzW
# oRf250PcgutwyfYlvuw7TaNa1NnsdLU2WcHBsmc/xHANqI28n5Zty+Cn9WSTlXUh
# Vzjgt4LE5l88gx8bhgCJI4UtjraHJwQrpQTJAQxQnUFuPQIbAAoTaqitq16pKBtQ
# vaaPz8UUTjs+zVvjSfPNRCRQd9ywjDQgvh4RExRdZJCGGEx9WRyLi0arjKy1AnTD
# JeN3D8g2XusWdG0/RvUTkabSqev/gXpuQyUUhiYt0NLObITvwcuUkmrvbBZF00VY
# /QxGITADKCpoO0dGZG4glwZ94wwl+AqyB9dv/zjmPlzHB7nPHb4hFa62GiotcgYI
# Dsq+GODzr4BRsPE/rw==
# SIG # End signature block
