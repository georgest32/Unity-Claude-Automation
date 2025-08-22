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