function Get-NotificationConfiguration {
    <#
    .SYNOPSIS
    Loads unified notification configuration leveraging SystemStatus configuration system
    
    .DESCRIPTION
    Integrates with the Bootstrap Orchestrator configuration system to provide
    unified notification settings from systemstatus.config.json. Supports:
    - Manifest-aware configuration loading
    - JSON configuration integration with SystemStatus
    - Environment variable overrides with UNITYC_NOTIFY_ prefix
    - Configuration validation for notification settings
    - PowerShell 5.1 compatibility
    
    .PARAMETER ConfigPath
    Path to JSON configuration file (uses SystemStatus default if not specified)
    
    .PARAMETER ForceRefresh
    Force refresh of cached configuration
    
    .PARAMETER NotificationService
    Specific notification service to configure (EmailNotifications, WebhookNotifications, or All)
    
    .EXAMPLE
    Get-NotificationConfiguration
    
    .EXAMPLE
    Get-NotificationConfiguration -NotificationService "EmailNotifications"
    
    .EXAMPLE
    Get-NotificationConfiguration -ForceRefresh
    #>
    [CmdletBinding()]
    param(
        [string]$ConfigPath,
        [switch]$ForceRefresh,
        [ValidateSet("EmailNotifications", "WebhookNotifications", "All")]
        [string]$NotificationService = "All"
    )
    
    Write-SystemStatusLog "Loading notification configuration for service: $NotificationService" -Level 'INFO'
    
    try {
        # Load the unified SystemStatus configuration
        $systemConfig = Get-SystemStatusConfiguration -ConfigPath $ConfigPath -ForceRefresh:$ForceRefresh
        
        # Extract notification-specific configuration
        $notificationConfig = @{
            SystemStatus = $systemConfig.SystemStatus
            Notifications = $systemConfig.Notifications
            EmailNotifications = $systemConfig.EmailNotifications
            WebhookNotifications = $systemConfig.WebhookNotifications
            NotificationTriggers = $systemConfig.NotificationTriggers
        }
        
        # Add Bootstrap Orchestrator manifest integration
        $manifestPath = Join-Path (Split-Path $PSScriptRoot -Parent) "..\..\Manifests"
        $emailManifest = $null
        $webhookManifest = $null
        $integrationManifest = $null
        
        if (Test-Path "$manifestPath\EmailNotifications.manifest.psd1") {
            $emailManifest = Import-PowerShellDataFile "$manifestPath\EmailNotifications.manifest.psd1"
            Write-SystemStatusLog "Loaded EmailNotifications manifest: Version $($emailManifest.Version)" -Level 'DEBUG'
        }
        
        if (Test-Path "$manifestPath\WebhookNotifications.manifest.psd1") {
            $webhookManifest = Import-PowerShellDataFile "$manifestPath\WebhookNotifications.manifest.psd1"
            Write-SystemStatusLog "Loaded WebhookNotifications manifest: Version $($webhookManifest.Version)" -Level 'DEBUG'
        }
        
        if (Test-Path "$manifestPath\NotificationIntegration.manifest.psd1") {
            $integrationManifest = Import-PowerShellDataFile "$manifestPath\NotificationIntegration.manifest.psd1"
            Write-SystemStatusLog "Loaded NotificationIntegration manifest: Version $($integrationManifest.Version)" -Level 'DEBUG'
        }
        
        # Merge manifest settings with JSON configuration
        $notificationConfig.Manifests = @{
            EmailNotifications = $emailManifest
            WebhookNotifications = $webhookManifest
            NotificationIntegration = $integrationManifest
        }
        
        # Apply environment variable overrides with UNITYC_NOTIFY_ prefix
        $envVars = Get-ChildItem Env: | Where-Object { $_.Name -like "UNITYC_NOTIFY_*" }
        foreach ($envVar in $envVars) {
            $configPath = $envVar.Name -replace "^UNITYC_NOTIFY_", "" -replace "_", "."
            $configValue = $envVar.Value
            
            # Convert string values to appropriate types
            if ($configValue -eq "true") { $configValue = $true }
            elseif ($configValue -eq "false") { $configValue = $false }
            elseif ($configValue -match "^\d+$") { $configValue = [int]$configValue }
            
            Write-SystemStatusLog "Applying environment override: $configPath = $configValue" -Level 'DEBUG'
            
            # Apply the override (simplified dot notation parsing for PowerShell 5.1)
            $pathParts = $configPath -split '\.'
            $currentObject = $notificationConfig
            for ($i = 0; $i -lt $pathParts.Length - 1; $i++) {
                if (-not $currentObject[$pathParts[$i]]) {
                    $currentObject[$pathParts[$i]] = @{}
                }
                $currentObject = $currentObject[$pathParts[$i]]
            }
            $currentObject[$pathParts[-1]] = $configValue
        }
        
        # Validate notification configuration
        $validationResult = Test-NotificationConfiguration -Configuration $notificationConfig
        if (-not $validationResult.IsValid) {
            $errorMessage = "Notification configuration validation failed: $($validationResult.Errors -join ', ')"
            Write-SystemStatusLog $errorMessage -Level 'ERROR'
            throw $errorMessage
        }
        
        # Filter configuration based on requested service
        switch ($NotificationService) {
            "EmailNotifications" {
                $result = @{
                    SystemStatus = $notificationConfig.SystemStatus
                    Notifications = $notificationConfig.Notifications
                    EmailNotifications = $notificationConfig.EmailNotifications
                    NotificationTriggers = $notificationConfig.NotificationTriggers
                    Manifests = @{ EmailNotifications = $notificationConfig.Manifests.EmailNotifications }
                }
            }
            "WebhookNotifications" {
                $result = @{
                    SystemStatus = $notificationConfig.SystemStatus
                    Notifications = $notificationConfig.Notifications
                    WebhookNotifications = $notificationConfig.WebhookNotifications
                    NotificationTriggers = $notificationConfig.NotificationTriggers
                    Manifests = @{ WebhookNotifications = $notificationConfig.Manifests.WebhookNotifications }
                }
            }
            default {
                $result = $notificationConfig
            }
        }
        
        Write-SystemStatusLog "Successfully loaded notification configuration for $NotificationService" -Level 'INFO'
        return $result
        
    } catch {
        $errorMessage = "Failed to load notification configuration: $($_.Exception.Message)"
        Write-SystemStatusLog $errorMessage -Level 'ERROR'
        throw $_
    }
}

function Test-NotificationConfiguration {
    <#
    .SYNOPSIS
    Validates notification configuration for consistency and completeness
    
    .DESCRIPTION
    Performs comprehensive validation of notification configuration including:
    - Required field validation
    - Type checking for configuration values
    - Manifest consistency validation
    - Service dependency validation
    
    .PARAMETER Configuration
    Configuration object to validate
    
    .EXAMPLE
    Test-NotificationConfiguration -Configuration $config
    #>
    [CmdletBinding()]
    param(
        [hashtable]$Configuration
    )
    
    $errors = @()
    
    try {
        # Validate core notification settings
        if (-not $Configuration.Notifications) {
            $errors += "Missing Notifications section in configuration"
        } elseif (-not $Configuration.Notifications.EnableNotifications) {
            Write-SystemStatusLog "Notifications are disabled in configuration" -Level 'WARN'
        }
        
        # Validate email configuration if enabled
        if ($Configuration.EmailNotifications -and $Configuration.EmailNotifications.Enabled) {
            if (-not $Configuration.EmailNotifications.SMTPServer) {
                $errors += "EmailNotifications.SMTPServer is required when email notifications are enabled"
            }
            if (-not $Configuration.EmailNotifications.FromAddress) {
                $errors += "EmailNotifications.FromAddress is required when email notifications are enabled"
            }
            if (-not $Configuration.EmailNotifications.ToAddresses -or $Configuration.EmailNotifications.ToAddresses.Count -eq 0) {
                $errors += "EmailNotifications.ToAddresses must contain at least one recipient when email notifications are enabled"
            }
        }
        
        # Validate webhook configuration if enabled
        if ($Configuration.WebhookNotifications -and $Configuration.WebhookNotifications.Enabled) {
            if (-not $Configuration.WebhookNotifications.WebhookURLs -or $Configuration.WebhookNotifications.WebhookURLs.Count -eq 0) {
                $errors += "WebhookNotifications.WebhookURLs must contain at least one URL when webhook notifications are enabled"
            }
            
            # Validate authentication method
            $authMethod = $Configuration.WebhookNotifications.AuthenticationMethod
            if ($authMethod -eq "Bearer" -and -not $Configuration.WebhookNotifications.BearerToken) {
                $errors += "WebhookNotifications.BearerToken is required when using Bearer authentication"
            }
            if ($authMethod -eq "Basic" -and (-not $Configuration.WebhookNotifications.BasicAuthUsername -or -not $Configuration.WebhookNotifications.BasicAuthPassword)) {
                $errors += "WebhookNotifications.BasicAuthUsername and BasicAuthPassword are required when using Basic authentication"
            }
            if ($authMethod -eq "APIKey" -and (-not $Configuration.WebhookNotifications.APIKeyHeader -or -not $Configuration.WebhookNotifications.APIKey)) {
                $errors += "WebhookNotifications.APIKeyHeader and APIKey are required when using APIKey authentication"
            }
        }
        
        # Validate trigger configuration
        if ($Configuration.NotificationTriggers) {
            $triggerSections = @("UnityCompilation", "ClaudeSubmission", "FixApplication", "SystemHealth", "AutonomousAgent")
            foreach ($section in $triggerSections) {
                if ($Configuration.NotificationTriggers[$section] -and $Configuration.NotificationTriggers[$section].DebounceSeconds -lt 1) {
                    $errors += "NotificationTriggers.$section.DebounceSeconds must be at least 1 second"
                }
            }
        }
        
        $result = @{
            IsValid = ($errors.Count -eq 0)
            Errors = $errors
            ValidationDate = Get-Date
        }
        
        if ($errors.Count -eq 0) {
            Write-SystemStatusLog "Notification configuration validation passed" -Level 'INFO'
        } else {
            Write-SystemStatusLog "Notification configuration validation failed with $($errors.Count) errors" -Level 'ERROR'
        }
        
        return $result
        
    } catch {
        $errorMessage = "Error during notification configuration validation: $($_.Exception.Message)"
        Write-SystemStatusLog $errorMessage -Level 'ERROR'
        return @{
            IsValid = $false
            Errors = @($errorMessage)
            ValidationDate = Get-Date
        }
    }
}

# Functions available for dot-sourcing in main module
# Get-NotificationConfiguration, Test-NotificationConfiguration
# SIG # Begin signature block
# MIIFzgYJKoZIhvcNAQcCoIIFvzCCBbsCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCCoiJEa6mMju+Cv
# VuT9mJCmcI1ak4H0mJHWbR5nJHhjuqCCAzAwggMsMIICFKADAgECAhB1HRbZIqgr
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
# MAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIDpLOBDsj6yicQM5k0pUXmSP
# 6HdwYb/kX32IlSFVGehkMA0GCSqGSIb3DQEBAQUABIIBAKvJ7JbFcjcaF9RRzD8e
# dvk1cUpiLBrzxZDtDWbIm6yMG3GdgK+XIGrTm1FGL+t3ZbKRVVDUjGr+FXD9Dhen
# BtPtH7AdufQZZixudxHyULPq/+UR3QQv709heAW/wq5HwVteZuUz4RiE3U/dcIYI
# ekj/E2XG40QpME8d+DTr3DopsfNyAoI0X8D9aXh51jwZx4T8BNFqDN5pN03lht4x
# RAmfhYUX2gf1n2IlafKGlGd0GSMboh1wxhAddelk1+T4lh0JBr45DvwFPjm5fC1K
# Qf37SVIB9+4pcabPk8K+A8J1V7iqdlEc7Qke2YHRPdrjZukvDioiNlzJMuoBMTOq
# aE0=
# SIG # End signature block
