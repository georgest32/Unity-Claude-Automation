# ContextManagement.psm1
# Context building and management for notifications
# Date: 2025-08-21

#region Context Management Functions

function New-NotificationContext {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$EventType,
        
        [Parameter()]
        [ValidateSet('Critical', 'Error', 'Warning', 'Info')]
        [string]$Severity = 'Info',
        
        [Parameter()]
        [hashtable]$Data = @{},
        
        [Parameter()]
        [string[]]$Channels = $script:NotificationConfig.DefaultChannels,
        
        [Parameter()]
        [hashtable]$Metadata = @{}
    )
    
    Write-Verbose "Creating notification context for event: $EventType"
    
    $contextId = [System.Guid]::NewGuid().ToString()
    
    $context = @{
        ContextId = $contextId
        EventType = $EventType
        Severity = $Severity
        Data = $Data.Clone()
        Channels = $Channels
        Metadata = $Metadata.Clone()
        CreatedAt = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
        SystemInfo = @{
            MachineName = $env:COMPUTERNAME
            UserName = $env:USERNAME
            ProcessId = $PID
            PowerShellVersion = $PSVersionTable.PSVersion.ToString()
        }
    }
    
    Write-Verbose "Created notification context: $contextId"
    return $context
}

function Add-NotificationContextData {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [hashtable]$Context,
        
        [Parameter(Mandatory = $true)]
        [string]$Key,
        
        [Parameter(Mandatory = $true)]
        [object]$Value,
        
        [Parameter()]
        [switch]$Overwrite
    )
    
    Write-Verbose "Adding data to notification context: $Key"
    
    if ($Context.Data.ContainsKey($Key) -and -not $Overwrite) {
        Write-Warning "Key '$Key' already exists in context data. Use -Overwrite to replace."
        return $false
    }
    
    $Context.Data[$Key] = $Value
    Write-Verbose "Added context data: $Key = $Value"
    return $true
}

function Get-NotificationContext {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [hashtable]$Context
    )
    
    return $Context.Clone()
}

function Clear-NotificationContext {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [hashtable]$Context
    )
    
    Write-Verbose "Clearing notification context data"
    $Context.Data.Clear()
    $Context.Metadata.Clear()
    Write-Verbose "Context data cleared"
}

function Format-NotificationContext {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [hashtable]$Context,
        
        [Parameter()]
        [ValidateSet('Json', 'Table', 'List')]
        [string]$Format = 'Json'
    )
    
    Write-Verbose "Formatting notification context as $Format"
    
    switch ($Format) {
        'Json' {
            return $Context | ConvertTo-Json -Depth 5
        }
        'Table' {
            $flatData = @()
            $flatData += [PSCustomObject]@{ Property = 'ContextId'; Value = $Context.ContextId }
            $flatData += [PSCustomObject]@{ Property = 'EventType'; Value = $Context.EventType }
            $flatData += [PSCustomObject]@{ Property = 'Severity'; Value = $Context.Severity }
            $flatData += [PSCustomObject]@{ Property = 'CreatedAt'; Value = $Context.CreatedAt }
            
            foreach ($key in $Context.Data.Keys) {
                $flatData += [PSCustomObject]@{ Property = "Data.$key"; Value = $Context.Data[$key] }
            }
            
            return $flatData | Format-Table -AutoSize
        }
        'List' {
            $output = @()
            $output += "Context ID: $($Context.ContextId)"
            $output += "Event Type: $($Context.EventType)"
            $output += "Severity: $($Context.Severity)"
            $output += "Created At: $($Context.CreatedAt)"
            $output += "Channels: $($Context.Channels -join ', ')"
            
            if ($Context.Data.Count -gt 0) {
                $output += "Data:"
                foreach ($key in $Context.Data.Keys) {
                    $output += "  $key = $($Context.Data[$key])"
                }
            }
            
            if ($Context.Metadata.Count -gt 0) {
                $output += "Metadata:"
                foreach ($key in $Context.Metadata.Keys) {
                    $output += "  $key = $($Context.Metadata[$key])"
                }
            }
            
            return $output -join "`n"
        }
    }
}

#endregion

# Export functions
Export-ModuleMember -Function @(
    'New-NotificationContext',
    'Add-NotificationContextData',
    'Get-NotificationContext',
    'Clear-NotificationContext',
    'Format-NotificationContext'
)

Write-Verbose "ContextManagement module loaded successfully"
# SIG # Begin signature block
# MIIFqQYJKoZIhvcNAQcCoIIFmjCCBZYCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUPDEdwl2oDWtUe9fYg/v2l4rM
# N7+gggMwMIIDLDCCAhSgAwIBAgIQdR0W2SKoK5VE8JId4ZxrRTANBgkqhkiG9w0B
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
# CQQxFgQUyWUQbSZbrnpEpRXHiSxolzv4nYQwDQYJKoZIhvcNAQEBBQAEggEAYnRj
# 0+Q0Ahw99yk3SpZFrGxkP7rx/auYp6fqtbBGz2BB+QT9E2pIp8E1DXYNJW2xPOs8
# jv1vymf/LwdD37UTX27KRLsn+6FMhizS4kuSVULGISabiWJjpDJHjOI5Pta7w2VJ
# Uvzy5OhS1kUYVQcL1CYx7A6Aa1vO2hF9IUSzQSJVsDmkvilvYgG1HKDa6NnDC1UM
# 5VlOGi3VVV01PRxReLNKxiaHOdqv2Igv0SOFw/QwYXc44EHnIuy7tAHNRusrSSjM
# VEXJQISCyxduSc44SCx3RH/pLWWhvhoX60OZ1PKnugxuzuABSpQGQiAMyBLKmcyU
# hB7qpQKwZnvGU7telw==
# SIG # End signature block
