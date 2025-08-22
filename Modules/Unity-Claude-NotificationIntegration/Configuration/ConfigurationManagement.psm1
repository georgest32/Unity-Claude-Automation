# ConfigurationManagement.psm1
# Configuration management for notifications
# Date: 2025-08-21

#region Configuration Management Functions

function New-NotificationConfiguration {
    [CmdletBinding()]
    param(
        [Parameter()]
        [bool]$Enabled = $true,
        
        [Parameter()]
        [int]$MaxRetries = 3,
        
        [Parameter()]
        [int]$RetryBaseDelay = 1000,
        
        [Parameter()]
        [int]$RetryMaxDelay = 30000,
        
        [Parameter()]
        [int]$CircuitBreakerThreshold = 5,
        
        [Parameter()]
        [int]$CircuitBreakerTimeout = 60000,
        
        [Parameter()]
        [int]$QueueMaxSize = 1000,
        
        [Parameter()]
        [string[]]$DefaultChannels = @('Email', 'Webhook'),
        
        [Parameter()]
        [ValidateSet('Debug', 'Info', 'Warning', 'Error')]
        [string]$LogLevel = 'Info',
        
        [Parameter()]
        [bool]$EnableFallback = $true
    )
    
    Write-Verbose "Creating new notification configuration"
    
    $config = @{
        Enabled = $Enabled
        AsyncDelivery = $true
        MaxRetries = $MaxRetries
        RetryBaseDelay = $RetryBaseDelay
        RetryMaxDelay = $RetryMaxDelay
        CircuitBreakerThreshold = $CircuitBreakerThreshold
        CircuitBreakerTimeout = $CircuitBreakerTimeout
        QueueMaxSize = $QueueMaxSize
        MetricsRetentionDays = 7
        LogLevel = $LogLevel
        EnableFallback = $EnableFallback
        DefaultChannels = $DefaultChannels
        CreatedAt = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
        Version = '1.0.0'
    }
    
    Write-Verbose "Created notification configuration"
    return $config
}

function Import-NotificationConfiguration {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$FilePath,
        
        [Parameter()]
        [switch]$Validate
    )
    
    Write-Verbose "Importing notification configuration from: $FilePath"
    
    if (-not (Test-Path $FilePath)) {
        throw "Configuration file not found: $FilePath"
    }
    
    try {
        $configContent = Get-Content $FilePath -Raw | ConvertFrom-Json
        
        # Convert PSCustomObject to hashtable
        $config = @{}
        $configContent.PSObject.Properties | ForEach-Object {
            $config[$_.Name] = $_.Value
        }
        
        if ($Validate) {
            $validationResult = Test-NotificationConfiguration -Configuration $config
            if (-not $validationResult.IsValid) {
                throw "Configuration validation failed: $($validationResult.Errors -join ', ')"
            }
        }
        
        # Apply to module configuration
        foreach ($key in $config.Keys) {
            if ($script:NotificationConfig.ContainsKey($key)) {
                $script:NotificationConfig[$key] = $config[$key]
            }
        }
        
        Write-Verbose "Configuration imported successfully"
        return $config
    }
    catch {
        Write-Error "Failed to import configuration: $_"
        throw
    }
}

function Export-NotificationConfiguration {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$FilePath,
        
        [Parameter()]
        [hashtable]$Configuration = $script:NotificationConfig,
        
        [Parameter()]
        [switch]$Pretty
    )
    
    Write-Verbose "Exporting notification configuration to: $FilePath"
    
    try {
        $configToExport = $Configuration.Clone()
        $configToExport.ExportedAt = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
        
        if ($Pretty) {
            $json = $configToExport | ConvertTo-Json -Depth 5
        }
        else {
            $json = $configToExport | ConvertTo-Json -Depth 5 -Compress
        }
        
        $json | Out-File -FilePath $FilePath -Encoding UTF8
        
        Write-Verbose "Configuration exported successfully"
        return $true
    }
    catch {
        Write-Error "Failed to export configuration: $_"
        return $false
    }
}

function Test-NotificationConfiguration {
    [CmdletBinding()]
    param(
        [Parameter()]
        [hashtable]$Configuration = $script:NotificationConfig
    )
    
    Write-Verbose "Testing notification configuration"
    
    $errors = @()
    $warnings = @()
    
    # Required fields
    $requiredFields = @('Enabled', 'MaxRetries', 'RetryBaseDelay', 'QueueMaxSize', 'DefaultChannels')
    foreach ($field in $requiredFields) {
        if (-not $Configuration.ContainsKey($field)) {
            $errors += "Missing required field: $field"
        }
    }
    
    # Validate numeric ranges
    if ($Configuration.ContainsKey('MaxRetries') -and ($Configuration.MaxRetries -lt 0 -or $Configuration.MaxRetries -gt 10)) {
        $errors += "MaxRetries must be between 0 and 10"
    }
    
    if ($Configuration.ContainsKey('RetryBaseDelay') -and ($Configuration.RetryBaseDelay -lt 100 -or $Configuration.RetryBaseDelay -gt 60000)) {
        $errors += "RetryBaseDelay must be between 100 and 60000 milliseconds"
    }
    
    if ($Configuration.ContainsKey('QueueMaxSize') -and ($Configuration.QueueMaxSize -lt 10 -or $Configuration.QueueMaxSize -gt 10000)) {
        $errors += "QueueMaxSize must be between 10 and 10000"
    }
    
    # Validate channels
    if ($Configuration.ContainsKey('DefaultChannels')) {
        $validChannels = @('Email', 'Webhook', 'Console', 'File')
        foreach ($channel in $Configuration.DefaultChannels) {
            if ($channel -notin $validChannels) {
                $warnings += "Unknown channel: $channel (valid channels: $($validChannels -join ', '))"
            }
        }
    }
    
    # Validate log level
    if ($Configuration.ContainsKey('LogLevel')) {
        $validLogLevels = @('Debug', 'Info', 'Warning', 'Error')
        if ($Configuration.LogLevel -notin $validLogLevels) {
            $errors += "Invalid LogLevel: $($Configuration.LogLevel) (valid levels: $($validLogLevels -join ', '))"
        }
    }
    
    $isValid = $errors.Count -eq 0
    
    Write-Verbose "Configuration validation completed. Valid: $isValid, Errors: $($errors.Count), Warnings: $($warnings.Count)"
    
    return @{
        IsValid = $isValid
        Errors = $errors
        Warnings = $warnings
        TestedAt = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
    }
}

function Get-NotificationConfiguration {
    [CmdletBinding()]
    param()
    
    Write-Verbose "Getting current notification configuration"
    Write-Host "[CONFIG MODULE] Getting notification configuration..." -ForegroundColor Yellow
    
    # Access parent module state using Get-Module and scriptblock invocation
    $parentModule = Get-Module 'Unity-Claude-NotificationIntegration-Modular'
    Write-Host "[CONFIG MODULE] Parent module found: $($parentModule.Name)" -ForegroundColor DarkYellow
    
    # Get configuration from parent module
    $config = & $parentModule { Get-NotificationState -StateType 'Config' }
    Write-Host "[CONFIG MODULE] Configuration retrieved with $($config.Keys.Count) keys" -ForegroundColor DarkYellow
    
    # Clone the hashtable to return a copy
    $configCopy = @{}
    foreach ($key in $config.Keys) {
        $configCopy[$key] = $config[$key]
        Write-Host "[CONFIG MODULE] Config.$key = $($config[$key])" -ForegroundColor DarkGray
    }
    
    return $configCopy
}

function Set-NotificationConfiguration {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [hashtable]$Configuration,
        
        [Parameter()]
        [switch]$Validate
    )
    
    Write-Verbose "Setting notification configuration"
    
    if ($Validate) {
        $validationResult = Test-NotificationConfiguration -Configuration $Configuration
        if (-not $validationResult.IsValid) {
            throw "Configuration validation failed: $($validationResult.Errors -join ', ')"
        }
        
        if ($validationResult.Warnings.Count -gt 0) {
            foreach ($warning in $validationResult.Warnings) {
                Write-Warning $warning
            }
        }
    }
    
    # Apply configuration
    foreach ($key in $Configuration.Keys) {
        $script:NotificationConfig[$key] = $Configuration[$key]
    }
    
    Write-Verbose "Configuration updated successfully"
    return $script:NotificationConfig.Clone()
}

#endregion

# Export functions
Export-ModuleMember -Function @(
    'New-NotificationConfiguration',
    'Import-NotificationConfiguration',
    'Export-NotificationConfiguration',
    'Test-NotificationConfiguration',
    'Get-NotificationConfiguration',
    'Set-NotificationConfiguration'
)

Write-Verbose "ConfigurationManagement module loaded successfully"
# SIG # Begin signature block
# MIIFqQYJKoZIhvcNAQcCoIIFmjCCBZYCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUvDAHQBBkM4yRwul7wi/CYKul
# 30igggMwMIIDLDCCAhSgAwIBAgIQdR0W2SKoK5VE8JId4ZxrRTANBgkqhkiG9w0B
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
# CQQxFgQU2wbO932FtR9DEvqtu6+AqaXTc6kwDQYJKoZIhvcNAQEBBQAEggEAPekV
# 85aqD0akD/wqkkxMeqRFtF4+W/LcqiMi3GaVNUWMPgJZwopRVLpLfrFDVk1sV58W
# KpPun6RSo69pbTnalu+BT1cBFwvdJfx0/nrthoQ8ATdP4hF04z7wR4P5troEN71D
# YAZTpA1Qw+2c4gwyNbZBq36c7oxMi0OOaNU/6IImBgobYRl+fPjns2IGmJ+A/2+v
# ap/t3Rc/RY1eqaSy5AO8j7IR5T2vvm667/4bH8URwXMDEDI/7EGJdvlOjV2hatO9
# IpJiLAlQ6NhRV7LnmXRyXicTQNUhd0w8w2xY29IxM15HX73lTZCzDZZ+/V5E8Znj
# xHeOCVbvW4hIbv1iGQ==
# SIG # End signature block
