# Unity-Claude-WebhookNotifications.psm1
# Phase 2 Week 5 Days 3-4: Webhook System Implementation
# Webhook notification delivery system using Invoke-RestMethod for Unity-Claude autonomous operation
# Date: 2025-08-21

$ErrorActionPreference = "Stop"

# Module-level variables for webhook system
$script:WebhookConfiguration = @{}
$script:WebhookAuthentication = @{}
$script:WebhookDeliveryStats = @{
    TotalAttempts = 0
    SuccessfulDeliveries = 0
    FailedDeliveries = 0
    LastDeliveryAttempt = $null
    LastSuccessfulDelivery = $null
    AverageResponseTime = 0
}
$script:NotificationTriggers = @{}

Write-Host "[DEBUG] [WebhookNotifications] Loading Unity-Claude-WebhookNotifications module..." -ForegroundColor Gray

# Week 5 Day 3 Hour 1-3: Create Invoke-RestMethod webhook delivery system
function New-WebhookConfiguration {
    <#
    .SYNOPSIS
    Creates a new webhook configuration for Unity-Claude notification system
    .DESCRIPTION
    Creates webhook configuration with URL validation and security settings
    .PARAMETER ConfigurationName
    Name for the webhook configuration
    .PARAMETER WebhookURL
    Webhook endpoint URL (must be HTTPS for security)
    .PARAMETER ContentType
    Content type for webhook payload (default: application/json)
    .PARAMETER UserAgent
    User agent string for webhook requests
    .PARAMETER TimeoutSeconds
    Request timeout in seconds (default: 30)
    .PARAMETER ValidateSSL
    Validate SSL certificates (recommended for production)
    .EXAMPLE
    New-WebhookConfiguration -ConfigurationName "SlackProd" -WebhookURL "https://hooks.slack.com/services/..." -ValidateSSL
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$ConfigurationName,
        [Parameter(Mandatory)]
        [string]$WebhookURL,
        [string]$ContentType = "application/json",
        [string]$UserAgent = "Unity-Claude-Automation/1.0",
        [int]$TimeoutSeconds = 30,
        [switch]$ValidateSSL
    )
    
    Write-Host "[DEBUG] [WebhookNotifications] Creating webhook configuration: $ConfigurationName" -ForegroundColor Gray
    
    try {
        # Validate webhook URL format and security
        if (-not ($WebhookURL -match '^https?://')) {
            throw "Invalid webhook URL format: $WebhookURL"
        }
        
        # Enforce HTTPS for security (with warning for HTTP)
        if ($WebhookURL.StartsWith("http://")) {
            Write-Host "[WARNING] [WebhookNotifications] HTTP webhook URL detected - HTTPS recommended for production: $WebhookURL" -ForegroundColor Yellow
        }
        
        # Validate timeout range
        if ($TimeoutSeconds -lt 5 -or $TimeoutSeconds -gt 300) {
            throw "Invalid timeout seconds: $TimeoutSeconds (must be 5-300)"
        }
        
        # Create configuration object
        $webhookConfig = @{
            ConfigurationName = $ConfigurationName
            WebhookURL = $WebhookURL
            ContentType = $ContentType
            UserAgent = $UserAgent
            TimeoutSeconds = $TimeoutSeconds
            ValidateSSL = $ValidateSSL
            Created = Get-Date
            LastModified = Get-Date
            AuthenticationConfigured = $false
            LastDeliveryTest = $null
            DeliveryTestResult = $null
            DeliveryCount = 0
            SuccessfulDeliveries = 0
            FailedDeliveries = 0
        }
        
        # Store in module configuration
        $script:WebhookConfiguration[$ConfigurationName] = $webhookConfig
        
        Write-Host "[SUCCESS] [WebhookNotifications] Webhook configuration '$ConfigurationName' created successfully" -ForegroundColor Green
        Write-Host "[INFO] [WebhookNotifications] Webhook URL: $WebhookURL" -ForegroundColor White
        Write-Host "[INFO] [WebhookNotifications] Content-Type: $ContentType, Timeout: ${TimeoutSeconds}s, SSL Validation: $ValidateSSL" -ForegroundColor White
        
        return $webhookConfig
        
    } catch {
        Write-Host "[ERROR] [WebhookNotifications] Failed to create webhook configuration '$ConfigurationName': $($_.Exception.Message)" -ForegroundColor Red
        throw
    }
}

function Test-WebhookConfiguration {
    <#
    .SYNOPSIS
    Tests webhook configuration by sending a test payload
    .DESCRIPTION
    Validates webhook endpoint connectivity and authentication
    .PARAMETER ConfigurationName
    Name of the webhook configuration to test
    .PARAMETER SendTestPayload
    Send actual test payload to verify delivery
    .PARAMETER TestPayload
    Custom test payload (hashtable will be converted to JSON)
    .EXAMPLE
    Test-WebhookConfiguration -ConfigurationName "SlackProd" -SendTestPayload
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$ConfigurationName,
        [switch]$SendTestPayload,
        [hashtable]$TestPayload
    )
    
    Write-Host "[DEBUG] [WebhookNotifications] Testing webhook configuration: $ConfigurationName" -ForegroundColor Gray
    
    try {
        # Validate configuration exists
        if (-not $script:WebhookConfiguration.ContainsKey($ConfigurationName)) {
            throw "Webhook configuration '$ConfigurationName' not found"
        }
        
        $config = $script:WebhookConfiguration[$ConfigurationName]
        
        Write-Host "[INFO] [WebhookNotifications] Testing webhook connectivity to $($config.WebhookURL)" -ForegroundColor White
        
        if ($SendTestPayload) {
            # Create test payload if not provided
            if (-not $TestPayload) {
                $TestPayload = @{
                    test_notification = $true
                    system = "Unity-Claude Automation"
                    message = "Webhook connectivity test"
                    timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
                    configuration = $ConfigurationName
                }
            }
            
            # Attempt webhook delivery
            $deliveryResult = Invoke-WebhookDelivery -ConfigurationName $ConfigurationName -Payload $TestPayload
            
            # Update configuration with test results
            $config.LastDeliveryTest = Get-Date
            if ($deliveryResult.Success) {
                $config.DeliveryTestResult = "SUCCESS"
                Write-Host "[SUCCESS] [WebhookNotifications] Webhook test payload delivered successfully" -ForegroundColor Green
            } else {
                $config.DeliveryTestResult = "FAILED: $($deliveryResult.Error)"
                Write-Host "[ERROR] [WebhookNotifications] Webhook test payload delivery failed: $($deliveryResult.Error)" -ForegroundColor Red
            }
            
            return $deliveryResult
            
        } else {
            # Just test URL accessibility without sending payload
            try {
                $testResponse = Invoke-RestMethod -Uri $config.WebhookURL -Method HEAD -TimeoutSec $config.TimeoutSeconds -ErrorAction Stop
                
                $config.LastDeliveryTest = Get-Date
                $config.DeliveryTestResult = "SUCCESS (connectivity only)"
                
                Write-Host "[SUCCESS] [WebhookNotifications] Webhook endpoint accessible" -ForegroundColor Green
                
                return @{
                    Success = $true
                    URL = $config.WebhookURL
                    ConnectivityTest = $true
                    TestTime = Get-Date
                }
                
            } catch {
                $config.LastDeliveryTest = Get-Date
                $config.DeliveryTestResult = "FAILED: $($_.Exception.Message)"
                
                Write-Host "[WARNING] [WebhookNotifications] Webhook connectivity test failed: $($_.Exception.Message)" -ForegroundColor Yellow
                
                return @{
                    Success = $false
                    Error = $_.Exception.Message
                    URL = $config.WebhookURL
                    ConnectivityTest = $true
                    TestTime = Get-Date
                }
            }
        }
        
    } catch {
        Write-Host "[ERROR] [WebhookNotifications] Webhook configuration test failed: $($_.Exception.Message)" -ForegroundColor Red
        throw
    }
}

function Invoke-WebhookDelivery {
    <#
    .SYNOPSIS
    Delivers webhook notification using Invoke-RestMethod
    .DESCRIPTION
    Sends HTTP POST webhook with JSON payload and authentication
    .PARAMETER ConfigurationName
    Name of the webhook configuration to use
    .PARAMETER Payload
    Hashtable payload to be converted to JSON
    .PARAMETER CustomHeaders
    Additional custom headers for the request
    .EXAMPLE
    $payload = @{message="Unity error"; severity="high"}
    Invoke-WebhookDelivery -ConfigurationName "SlackProd" -Payload $payload
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$ConfigurationName,
        [Parameter(Mandatory)]
        [hashtable]$Payload,
        [hashtable]$CustomHeaders = @{}
    )
    
    Write-Host "[DEBUG] [WebhookNotifications] Delivering webhook via $ConfigurationName" -ForegroundColor Gray
    
    try {
        # Validate configuration exists
        if (-not $script:WebhookConfiguration.ContainsKey($ConfigurationName)) {
            throw "Webhook configuration '$ConfigurationName' not found"
        }
        
        $config = $script:WebhookConfiguration[$ConfigurationName]
        
        # Prepare headers
        $headers = @{
            "Content-Type" = $config.ContentType
            "User-Agent" = $config.UserAgent
        }
        
        # Add authentication headers if configured
        if ($config.AuthenticationConfigured -and $script:WebhookAuthentication.ContainsKey($ConfigurationName)) {
            $authConfig = $script:WebhookAuthentication[$ConfigurationName]
            
            switch ($authConfig.AuthType) {
                "Bearer" {
                    $headers["Authorization"] = "Bearer $($authConfig.Token)"
                    Write-Host "[DEBUG] [WebhookNotifications] Using Bearer token authentication" -ForegroundColor Gray
                }
                "Basic" {
                    $headers["Authorization"] = "Basic $($authConfig.EncodedCredentials)"
                    Write-Host "[DEBUG] [WebhookNotifications] Using Basic authentication" -ForegroundColor Gray
                }
                "APIKey" {
                    $headers[$authConfig.HeaderName] = $authConfig.APIKey
                    Write-Host "[DEBUG] [WebhookNotifications] Using API key authentication ($($authConfig.HeaderName))" -ForegroundColor Gray
                }
            }
        }
        
        # Add custom headers
        foreach ($headerName in $CustomHeaders.Keys) {
            $headers[$headerName] = $CustomHeaders[$headerName]
        }
        
        # Convert payload to JSON
        $jsonPayload = $Payload | ConvertTo-Json -Depth 10 -Compress
        Write-Host "[DEBUG] [WebhookNotifications] JSON payload size: $($jsonPayload.Length) characters" -ForegroundColor Gray
        
        # Configure Invoke-RestMethod parameters
        $requestParams = @{
            Uri = $config.WebhookURL
            Method = "POST"
            Body = $jsonPayload
            Headers = $headers
            TimeoutSec = $config.TimeoutSeconds
            ErrorAction = "Stop"
        }
        
        # Add SSL validation settings
        if (-not $config.ValidateSSL) {
            # This is for testing scenarios - production should use SSL validation
            Write-Host "[WARNING] [WebhookNotifications] SSL validation disabled for $ConfigurationName" -ForegroundColor Yellow
        }
        
        # Measure delivery time
        $deliveryStart = Get-Date
        Write-Host "[DEBUG] [WebhookNotifications] Sending webhook to $($config.WebhookURL)" -ForegroundColor Gray
        
        # Send webhook
        $response = Invoke-RestMethod @requestParams
        
        $deliveryEnd = Get-Date
        $responseTime = ($deliveryEnd - $deliveryStart).TotalMilliseconds
        
        # Update statistics
        $script:WebhookDeliveryStats.TotalAttempts++
        $script:WebhookDeliveryStats.SuccessfulDeliveries++
        $script:WebhookDeliveryStats.LastDeliveryAttempt = $deliveryEnd
        $script:WebhookDeliveryStats.LastSuccessfulDelivery = $deliveryEnd
        
        # Update average response time
        if ($script:WebhookDeliveryStats.AverageResponseTime -eq 0) {
            $script:WebhookDeliveryStats.AverageResponseTime = $responseTime
        } else {
            $script:WebhookDeliveryStats.AverageResponseTime = ($script:WebhookDeliveryStats.AverageResponseTime + $responseTime) / 2
        }
        
        # Update configuration statistics
        $config.DeliveryCount++
        $config.SuccessfulDeliveries++
        $config.LastModified = $deliveryEnd
        
        Write-Host "[SUCCESS] [WebhookNotifications] Webhook delivered successfully to $($config.WebhookURL) ($([int]$responseTime)ms)" -ForegroundColor Green
        
        return @{
            Success = $true
            ResponseTime = $responseTime
            URL = $config.WebhookURL
            PayloadSize = $jsonPayload.Length
            Response = $response
            DeliveryTime = $deliveryEnd
            Configuration = $ConfigurationName
        }
        
    } catch {
        # Update failure statistics
        $script:WebhookDeliveryStats.TotalAttempts++
        $script:WebhookDeliveryStats.FailedDeliveries++
        $script:WebhookDeliveryStats.LastDeliveryAttempt = Get-Date
        
        if ($script:WebhookConfiguration.ContainsKey($ConfigurationName)) {
            $script:WebhookConfiguration[$ConfigurationName].DeliveryCount++
            $script:WebhookConfiguration[$ConfigurationName].FailedDeliveries++
        }
        
        Write-Host "[ERROR] [WebhookNotifications] Webhook delivery failed to $($config.WebhookURL): $($_.Exception.Message)" -ForegroundColor Red
        
        return @{
            Success = $false
            Error = $_.Exception.Message
            URL = $config.WebhookURL
            DeliveryTime = Get-Date
            Configuration = $ConfigurationName
        }
    }
}

function Get-WebhookConfiguration {
    <#
    .SYNOPSIS
    Retrieves webhook configuration details
    .DESCRIPTION
    Gets webhook configuration information for specified configuration name
    .PARAMETER ConfigurationName
    Name of the webhook configuration to retrieve
    .PARAMETER IncludeAuthentication
    Include authentication information in output (type only, not credentials)
    .EXAMPLE
    Get-WebhookConfiguration -ConfigurationName "SlackProd"
    #>
    [CmdletBinding()]
    param(
        [string]$ConfigurationName,
        [switch]$IncludeAuthentication
    )
    
    try {
        if ($ConfigurationName) {
            if (-not $script:WebhookConfiguration.ContainsKey($ConfigurationName)) {
                throw "Webhook configuration '$ConfigurationName' not found"
            }
            
            $config = $script:WebhookConfiguration[$ConfigurationName].Clone()
            
            if ($IncludeAuthentication -and $script:WebhookAuthentication.ContainsKey($ConfigurationName)) {
                $authConfig = $script:WebhookAuthentication[$ConfigurationName]
                $config.Authentication = @{
                    AuthType = $authConfig.AuthType
                    Created = $authConfig.Created
                    LastUsed = $authConfig.LastUsed
                    Configured = $true
                }
            }
            
            return $config
            
        } else {
            # Return all configurations
            $allConfigs = @{}
            foreach ($configName in $script:WebhookConfiguration.Keys) {
                $config = $script:WebhookConfiguration[$configName].Clone()
                
                if ($IncludeAuthentication -and $script:WebhookAuthentication.ContainsKey($configName)) {
                    $authConfig = $script:WebhookAuthentication[$configName]
                    $config.Authentication = @{
                        AuthType = $authConfig.AuthType
                        Created = $authConfig.Created
                        LastUsed = $authConfig.LastUsed
                        Configured = $true
                    }
                }
                
                $allConfigs[$configName] = $config
            }
            
            return $allConfigs
        }
        
    } catch {
        Write-Host "[ERROR] [WebhookNotifications] Failed to get webhook configuration: $($_.Exception.Message)" -ForegroundColor Red
        throw
    }
}

# Week 5 Day 3 Hour 4-6: Implement authentication methods
function New-BearerTokenAuth {
    <#
    .SYNOPSIS
    Creates Bearer Token authentication for webhook configuration
    .DESCRIPTION
    Sets up Bearer Token authentication (most common for modern webhooks)
    .PARAMETER ConfigurationName
    Name of the webhook configuration
    .PARAMETER Token
    Bearer token for authentication
    .PARAMETER SecureToken
    Bearer token as SecureString
    .EXAMPLE
    New-BearerTokenAuth -ConfigurationName "SlackProd" -Token "xoxb-your-slack-token"
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$ConfigurationName,
        [string]$Token,
        [SecureString]$SecureToken
    )
    
    Write-Host "[DEBUG] [WebhookNotifications] Setting Bearer token authentication for: $ConfigurationName" -ForegroundColor Gray
    
    try {
        # Validate configuration exists
        if (-not $script:WebhookConfiguration.ContainsKey($ConfigurationName)) {
            throw "Webhook configuration '$ConfigurationName' not found"
        }
        
        # Handle token input
        if ($SecureToken) {
            $finalToken = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto([System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($SecureToken))
        } elseif ($Token) {
            $finalToken = $Token
        } else {
            # Prompt for token
            Write-Host "[INFO] [WebhookNotifications] Please enter Bearer token for '$ConfigurationName'" -ForegroundColor Yellow
            $secureInput = Read-Host "Bearer Token" -AsSecureString
            $finalToken = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto([System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($secureInput))
        }
        
        if ([string]::IsNullOrWhiteSpace($finalToken)) {
            throw "Bearer token cannot be empty"
        }
        
        # Create authentication configuration
        $authConfig = @{
            AuthType = "Bearer"
            Token = $finalToken
            Created = Get-Date
            LastUsed = $null
        }
        
        # Store authentication configuration
        $script:WebhookAuthentication[$ConfigurationName] = $authConfig
        $script:WebhookConfiguration[$ConfigurationName].AuthenticationConfigured = $true
        $script:WebhookConfiguration[$ConfigurationName].LastModified = Get-Date
        
        Write-Host "[SUCCESS] [WebhookNotifications] Bearer token authentication configured for '$ConfigurationName'" -ForegroundColor Green
        Write-Host "[INFO] [WebhookNotifications] Token: $(($finalToken.Substring(0, [math]::Min(8, $finalToken.Length))))..." -ForegroundColor White
        
        # Clear token from memory
        $finalToken = $null
        [System.GC]::Collect()
        
        return $true
        
    } catch {
        Write-Host "[ERROR] [WebhookNotifications] Failed to set Bearer token authentication for '$ConfigurationName': $($_.Exception.Message)" -ForegroundColor Red
        throw
    }
}

function New-BasicAuthentication {
    <#
    .SYNOPSIS
    Creates Basic Authentication for webhook configuration
    .DESCRIPTION
    Sets up Basic Authentication with Base64 encoding for legacy webhooks
    .PARAMETER ConfigurationName
    Name of the webhook configuration
    .PARAMETER Username
    Username for basic authentication
    .PARAMETER Password
    Password for basic authentication
    .PARAMETER Credential
    PSCredential object containing username and password
    .EXAMPLE
    New-BasicAuthentication -ConfigurationName "LegacyWebhook" -Username "api_user" -Password "api_password"
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$ConfigurationName,
        [string]$Username,
        [string]$Password,
        [PSCredential]$Credential
    )
    
    Write-Host "[DEBUG] [WebhookNotifications] Setting Basic authentication for: $ConfigurationName" -ForegroundColor Gray
    
    try {
        # Validate configuration exists
        if (-not $script:WebhookConfiguration.ContainsKey($ConfigurationName)) {
            throw "Webhook configuration '$ConfigurationName' not found"
        }
        
        # Handle credential input
        if ($Credential) {
            $finalUsername = $Credential.UserName
            $finalPassword = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto([System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($Credential.Password))
        } elseif ($Username -and $Password) {
            $finalUsername = $Username
            $finalPassword = $Password
        } else {
            # Prompt for credentials
            Write-Host "[INFO] [WebhookNotifications] Please enter Basic authentication credentials for '$ConfigurationName'" -ForegroundColor Yellow
            $promptedCred = Get-Credential -Message "Enter Basic auth credentials for webhook"
            if (-not $promptedCred) {
                throw "No credentials provided"
            }
            $finalUsername = $promptedCred.UserName
            $finalPassword = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto([System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($promptedCred.Password))
        }
        
        # Create Base64 encoded credentials
        $credentialString = "${finalUsername}:${finalPassword}"
        $encodedCredentials = [System.Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes($credentialString))
        
        # Create authentication configuration
        $authConfig = @{
            AuthType = "Basic"
            Username = $finalUsername
            EncodedCredentials = $encodedCredentials
            Created = Get-Date
            LastUsed = $null
        }
        
        # Store authentication configuration
        $script:WebhookAuthentication[$ConfigurationName] = $authConfig
        $script:WebhookConfiguration[$ConfigurationName].AuthenticationConfigured = $true
        $script:WebhookConfiguration[$ConfigurationName].LastModified = Get-Date
        
        Write-Host "[SUCCESS] [WebhookNotifications] Basic authentication configured for '$ConfigurationName'" -ForegroundColor Green
        Write-Host "[INFO] [WebhookNotifications] Username: $finalUsername" -ForegroundColor White
        Write-Host "[INFO] [WebhookNotifications] Credentials: [Base64 Encoded]" -ForegroundColor White
        
        # Clear credentials from memory
        $finalPassword = $null
        $credentialString = $null
        [System.GC]::Collect()
        
        return $true
        
    } catch {
        Write-Host "[ERROR] [WebhookNotifications] Failed to set Basic authentication for '$ConfigurationName': $($_.Exception.Message)" -ForegroundColor Red
        throw
    }
}

function New-APIKeyAuthentication {
    <#
    .SYNOPSIS
    Creates API Key authentication for webhook configuration
    .DESCRIPTION
    Sets up API Key authentication with custom header for webhook services
    .PARAMETER ConfigurationName
    Name of the webhook configuration
    .PARAMETER APIKey
    API key for authentication
    .PARAMETER HeaderName
    Header name for API key (default: X-API-Key)
    .PARAMETER SecureAPIKey
    API key as SecureString
    .EXAMPLE
    New-APIKeyAuthentication -ConfigurationName "CustomWebhook" -APIKey "abc123def456" -HeaderName "X-Custom-Key"
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$ConfigurationName,
        [string]$APIKey,
        [string]$HeaderName = "X-API-Key",
        [SecureString]$SecureAPIKey
    )
    
    Write-Host "[DEBUG] [WebhookNotifications] Setting API key authentication for: $ConfigurationName" -ForegroundColor Gray
    
    try {
        # Validate configuration exists
        if (-not $script:WebhookConfiguration.ContainsKey($ConfigurationName)) {
            throw "Webhook configuration '$ConfigurationName' not found"
        }
        
        # Handle API key input
        if ($SecureAPIKey) {
            $finalAPIKey = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto([System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($SecureAPIKey))
        } elseif ($APIKey) {
            $finalAPIKey = $APIKey
        } else {
            # Prompt for API key
            Write-Host "[INFO] [WebhookNotifications] Please enter API key for '$ConfigurationName'" -ForegroundColor Yellow
            $secureInput = Read-Host "API Key" -AsSecureString
            $finalAPIKey = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto([System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($secureInput))
        }
        
        if ([string]::IsNullOrWhiteSpace($finalAPIKey)) {
            throw "API key cannot be empty"
        }
        
        # Validate header name
        if ([string]::IsNullOrWhiteSpace($HeaderName)) {
            throw "Header name cannot be empty"
        }
        
        # Create authentication configuration
        $authConfig = @{
            AuthType = "APIKey"
            APIKey = $finalAPIKey
            HeaderName = $HeaderName
            Created = Get-Date
            LastUsed = $null
        }
        
        # Store authentication configuration
        $script:WebhookAuthentication[$ConfigurationName] = $authConfig
        $script:WebhookConfiguration[$ConfigurationName].AuthenticationConfigured = $true
        $script:WebhookConfiguration[$ConfigurationName].LastModified = Get-Date
        
        Write-Host "[SUCCESS] [WebhookNotifications] API key authentication configured for '$ConfigurationName'" -ForegroundColor Green
        Write-Host "[INFO] [WebhookNotifications] Header: $HeaderName" -ForegroundColor White
        Write-Host "[INFO] [WebhookNotifications] API Key: $(($finalAPIKey.Substring(0, [math]::Min(8, $finalAPIKey.Length))))..." -ForegroundColor White
        
        # Clear API key from memory
        $finalAPIKey = $null
        [System.GC]::Collect()
        
        return $true
        
    } catch {
        Write-Host "[ERROR] [WebhookNotifications] Failed to set API key authentication for '$ConfigurationName': $($_.Exception.Message)" -ForegroundColor Red
        throw
    }
}

function Send-WebhookNotification {
    <#
    .SYNOPSIS
    Sends webhook notification with Unity-Claude event formatting
    .DESCRIPTION
    Sends webhook notification with structured payload for Unity-Claude events
    .PARAMETER ConfigurationName
    Name of the webhook configuration to use
    .PARAMETER EventType
    Type of event (UnityError, ClaudeFailure, WorkflowStatus, SystemHealth, AutonomousAgent)
    .PARAMETER EventData
    Hashtable containing event-specific data
    .PARAMETER Severity
    Event severity level (Critical, Error, Warning, Info)
    .PARAMETER CustomPayload
    Custom payload hashtable (overrides default event formatting)
    .EXAMPLE
    $eventData = @{ErrorType="CS0246"; ProjectName="MyGame"; ErrorMessage="Type not found"}
    Send-WebhookNotification -ConfigurationName "SlackProd" -EventType "UnityError" -EventData $eventData -Severity "Error"
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$ConfigurationName,
        [Parameter(Mandatory)]
        [ValidateSet('UnityError', 'ClaudeFailure', 'WorkflowStatus', 'SystemHealth', 'AutonomousAgent', 'Custom')]
        [string]$EventType,
        [hashtable]$EventData = @{},
        [ValidateSet('Critical', 'Error', 'Warning', 'Info')]
        [string]$Severity = 'Info',
        [hashtable]$CustomPayload
    )
    
    Write-Host "[DEBUG] [WebhookNotifications] Sending webhook notification: $EventType ($Severity)" -ForegroundColor Gray
    
    try {
        # Create structured payload
        if ($CustomPayload) {
            $payload = $CustomPayload
        } else {
            $payload = @{
                system = "Unity-Claude Automation"
                event_type = $EventType
                severity = $Severity
                timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss.fff"
                event_data = $EventData
                configuration = $ConfigurationName
                notification_id = [System.Guid]::NewGuid().ToString()
            }
        }
        
        # Add common Unity-Claude context
        $payload.unity_claude_context = @{
            system_version = "1.0.0"
            powershell_version = $PSVersionTable.PSVersion.ToString()
            hostname = $env:COMPUTERNAME
            notification_source = "Unity-Claude-WebhookNotifications"
        }
        
        Write-Host "[DEBUG] [WebhookNotifications] Webhook payload: $EventType notification with $($EventData.Count) event properties" -ForegroundColor Gray
        
        # Deliver webhook
        $deliveryResult = Invoke-WebhookDelivery -ConfigurationName $ConfigurationName -Payload $payload
        
        if ($deliveryResult.Success) {
            Write-Host "[SUCCESS] [WebhookNotifications] $EventType webhook notification delivered successfully" -ForegroundColor Green
        } else {
            Write-Host "[ERROR] [WebhookNotifications] $EventType webhook notification delivery failed: $($deliveryResult.Error)" -ForegroundColor Red
        }
        
        return $deliveryResult
        
    } catch {
        Write-Host "[ERROR] [WebhookNotifications] Failed to send webhook notification: $($_.Exception.Message)" -ForegroundColor Red
        throw
    }
}

# Week 5 Day 4 Hour 7-8: Build retry logic with exponential backoff
function Send-WebhookWithRetry {
    <#
    .SYNOPSIS
    Sends webhook notification with retry logic and exponential backoff
    .DESCRIPTION
    Sends webhook with comprehensive retry logic for production reliability
    .PARAMETER ConfigurationName
    Name of the webhook configuration to use
    .PARAMETER Payload
    Hashtable payload for webhook delivery
    .PARAMETER MaxRetries
    Maximum number of retry attempts (default: 3)
    .PARAMETER BaseDelaySeconds
    Base delay for exponential backoff (default: 1)
    .PARAMETER EventType
    Event type for structured notifications
    .PARAMETER EventData
    Event data for structured notifications
    .PARAMETER Severity
    Event severity for structured notifications
    .EXAMPLE
    Send-WebhookWithRetry -ConfigurationName "SlackProd" -EventType "UnityError" -EventData @{ErrorType="CS0246"} -MaxRetries 5
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$ConfigurationName,
        [hashtable]$Payload,
        [int]$MaxRetries = 3,
        [int]$BaseDelaySeconds = 1,
        [string]$EventType,
        [hashtable]$EventData,
        [string]$Severity = 'Info'
    )
    
    Write-Host "[DEBUG] [WebhookNotifications] Sending webhook with retry logic: $ConfigurationName (Max retries: $MaxRetries)" -ForegroundColor Gray
    
    $attempt = 0
    $lastError = $null
    $totalRetryTime = 0
    
    while ($attempt -le $MaxRetries) {
        $attempt++
        $attemptStart = Get-Date
        
        try {
            Write-Host "[DEBUG] [WebhookNotifications] Webhook delivery attempt $attempt/$($MaxRetries + 1)" -ForegroundColor Gray
            
            # Attempt webhook delivery
            if ($Payload) {
                $result = Invoke-WebhookDelivery -ConfigurationName $ConfigurationName -Payload $Payload
            } elseif ($EventType -and $EventData) {
                $result = Send-WebhookNotification -ConfigurationName $ConfigurationName -EventType $EventType -EventData $EventData -Severity $Severity
            } else {
                throw "Either Payload or EventType with EventData must be provided"
            }
            
            if ($result.Success) {
                $attemptDuration = ((Get-Date) - $attemptStart).TotalMilliseconds
                Write-Host "[SUCCESS] [WebhookNotifications] Webhook delivered successfully on attempt $attempt ($([int]$attemptDuration)ms)" -ForegroundColor Green
                
                return @{
                    Success = $true
                    DeliveryAttempts = $attempt
                    FinalResult = $result
                    TotalRetryTime = $totalRetryTime
                    FinalResponseTime = $result.ResponseTime
                }
            } else {
                $lastError = $result.Error
                throw $result.Error
            }
            
        } catch {
            $lastError = $_.Exception.Message
            $attemptDuration = ((Get-Date) - $attemptStart).TotalMilliseconds
            Write-Host "[WARNING] [WebhookNotifications] Webhook delivery attempt $attempt failed: $lastError ($([int]$attemptDuration)ms)" -ForegroundColor Yellow
            
            # If this is not the last attempt, calculate delay and wait
            if ($attempt -le $MaxRetries) {
                # Calculate exponential backoff delay with jitter
                $baseDelay = $BaseDelaySeconds * [math]::Pow(2, $attempt - 1)
                $jitter = Get-Random -Minimum 0 -Maximum ($baseDelay * 0.1) # 10% jitter
                $delaySeconds = $baseDelay + $jitter
                
                Write-Host "[DEBUG] [WebhookNotifications] Waiting $([math]::Round($delaySeconds, 2)) seconds before retry (attempt $attempt)..." -ForegroundColor Gray
                Start-Sleep -Seconds $delaySeconds
                $totalRetryTime += $delaySeconds
            }
        }
    }
    
    # All retries failed
    Write-Host "[ERROR] [WebhookNotifications] Webhook delivery failed after $($MaxRetries + 1) attempts: $lastError" -ForegroundColor Red
    
    return @{
        Success = $false
        DeliveryAttempts = $attempt
        FinalError = $lastError
        TotalRetryTime = $totalRetryTime
    }
}

function Get-WebhookDeliveryStats {
    <#
    .SYNOPSIS
    Gets webhook delivery statistics
    .DESCRIPTION
    Returns statistics about webhook delivery attempts and success rates
    .EXAMPLE
    Get-WebhookDeliveryStats
    #>
    [CmdletBinding()]
    param()
    
    $stats = $script:WebhookDeliveryStats.Clone()
    
    # Calculate success rate
    if ($stats.TotalAttempts -gt 0) {
        $stats.SuccessRate = [math]::Round(($stats.SuccessfulDeliveries / $stats.TotalAttempts) * 100, 1)
    } else {
        $stats.SuccessRate = 0
    }
    
    return $stats
}

function Get-WebhookDeliveryAnalytics {
    <#
    .SYNOPSIS
    Gets comprehensive webhook delivery analytics
    .DESCRIPTION
    Returns detailed analytics about webhook configurations and delivery performance
    .PARAMETER ConfigurationName
    Filter by specific webhook configuration
    .PARAMETER IncludePerformanceMetrics
    Include detailed performance metrics
    .EXAMPLE
    Get-WebhookDeliveryAnalytics -IncludePerformanceMetrics
    #>
    [CmdletBinding()]
    param(
        [string]$ConfigurationName,
        [switch]$IncludePerformanceMetrics
    )
    
    try {
        $analytics = @{
            OverallStats = $script:WebhookDeliveryStats.Clone()
            Configurations = @{}
            GeneratedTime = Get-Date
        }
        
        # Add configuration-specific analytics
        foreach ($configName in $script:WebhookConfiguration.Keys) {
            if ($ConfigurationName -and $configName -ne $ConfigurationName) {
                continue
            }
            
            $config = $script:WebhookConfiguration[$configName]
            $configAnalytics = @{
                WebhookURL = $config.WebhookURL
                DeliveryCount = $config.DeliveryCount
                SuccessfulDeliveries = $config.SuccessfulDeliveries
                FailedDeliveries = $config.FailedDeliveries
                SuccessRate = if ($config.DeliveryCount -gt 0) { 
                    [math]::Round(($config.SuccessfulDeliveries / $config.DeliveryCount) * 100, 1) 
                } else { 0 }
                LastDeliveryTest = $config.LastDeliveryTest
                DeliveryTestResult = $config.DeliveryTestResult
                AuthenticationConfigured = $config.AuthenticationConfigured
            }
            
            if ($IncludePerformanceMetrics) {
                $configAnalytics.ContentType = $config.ContentType
                $configAnalytics.TimeoutSeconds = $config.TimeoutSeconds
                $configAnalytics.ValidateSSL = $config.ValidateSSL
                $configAnalytics.Created = $config.Created
                $configAnalytics.LastModified = $config.LastModified
            }
            
            $analytics.Configurations[$configName] = $configAnalytics
        }
        
        # Calculate overall success rate
        if ($analytics.OverallStats.TotalAttempts -gt 0) {
            $analytics.OverallStats.SuccessRate = [math]::Round(($analytics.OverallStats.SuccessfulDeliveries / $analytics.OverallStats.TotalAttempts) * 100, 1)
        } else {
            $analytics.OverallStats.SuccessRate = 0
        }
        
        return $analytics
        
    } catch {
        Write-Host "[ERROR] [WebhookNotifications] Failed to get webhook delivery analytics: $($_.Exception.Message)" -ForegroundColor Red
        throw
    }
}

# Initialize module
Write-Host "[SUCCESS] [WebhookNotifications] Unity-Claude-WebhookNotifications module loaded successfully" -ForegroundColor Green
Write-Host "[INFO] [WebhookNotifications] Webhook delivery system ready (Invoke-RestMethod implementation)" -ForegroundColor White

# Export functions - Week 5 Days 3-4 Complete Implementation
Export-ModuleMember -Function @(
    'New-WebhookConfiguration',
    'Test-WebhookConfiguration',
    'Get-WebhookConfiguration',
    'Invoke-WebhookDelivery',
    'New-BearerTokenAuth',
    'New-BasicAuthentication', 
    'New-APIKeyAuthentication',
    'Send-WebhookNotification',
    'Send-WebhookWithRetry',
    'Get-WebhookDeliveryStats',
    'Get-WebhookDeliveryAnalytics'
)
# SIG # Begin signature block
# MIIFqQYJKoZIhvcNAQcCoIIFmjCCBZYCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUgw145FyryAfDOD8upOnMtCDu
# VQmgggMwMIIDLDCCAhSgAwIBAgIQdR0W2SKoK5VE8JId4ZxrRTANBgkqhkiG9w0B
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
# CQQxFgQUYRfJdOwv7fVMirrbfHbwDVAi5dUwDQYJKoZIhvcNAQEBBQAEggEAT1D/
# q3wiUSpy/dgdyIgMwg3S0mLaP5vNPG5TF7J2AIVUCZVk8OKjve5A51SyEw/Sz85v
# 7kqdU9gjWENtBHcPGRkp1gua5yXYycvYoz7+SnBNlBfUoXAG/aKTIN5Dgsl4vaFd
# jOW+QGc86eEX8ieZTVEEyNRfBNTDMPCT1xY8L4UoEiF3oS64sxXWNd4+rONEy3V5
# O9LEPjlzAe/iPJFSwxUg2jcXGIZx+BPeupqy+GUze0NIvMnDkIAsamLrBRg6o3/H
# u/C4tbgzoicqJj4RALnMVfZvo7EAWzEQfkLZIfxMPtS509LTd89CFqAEV+cXbrlY
# Ur3hWTquYuBeMcp71g==
# SIG # End signature block
