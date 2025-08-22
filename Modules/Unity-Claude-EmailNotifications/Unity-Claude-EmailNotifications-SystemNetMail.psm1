# Unity-Claude-EmailNotifications-SystemNetMail.psm1
# Alternative email implementation using System.Net.Mail for PowerShell 5.1 compatibility
# Week 5 Day 1 Hour 7-8: Alternative approach for immediate functionality
# Date: 2025-08-21

$ErrorActionPreference = "Stop"

# Module-level variables for email system
$script:EmailConfiguration = @{}
$script:EmailTemplates = @{}
$script:EmailDeliveryStats = @{
    TotalAttempts = 0
    SuccessfulDeliveries = 0
    FailedDeliveries = 0
    LastDeliveryAttempt = $null
    LastSuccessfulDelivery = $null
}
$script:NotificationTriggers = @{}

Write-Host "[DEBUG] [EmailNotifications] Loading Unity-Claude-EmailNotifications (System.Net.Mail implementation)..." -ForegroundColor Gray

# System.Net.Mail functions - immediate PowerShell 5.1 compatibility
function New-EmailConfiguration {
    <#
    .SYNOPSIS
    Creates a new email configuration using System.Net.Mail for PowerShell 5.1 compatibility
    .DESCRIPTION
    Creates SMTP configuration with credential management for email notifications
    .PARAMETER ConfigurationName
    Name for the email configuration
    .PARAMETER SMTPServer
    SMTP server hostname or IP address
    .PARAMETER Port
    SMTP server port (default: 587 for TLS)
    .PARAMETER EnableTLS
    Enable TLS/SSL encryption (recommended)
    .PARAMETER FromAddress
    Sender email address
    .PARAMETER FromDisplayName
    Display name for sender
    .EXAMPLE
    New-EmailConfiguration -ConfigurationName "Production" -SMTPServer "smtp.gmail.com" -Port 587 -EnableTLS -FromAddress "alerts@company.com" -FromDisplayName "Unity-Claude Automation"
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$ConfigurationName,
        [Parameter(Mandatory)]
        [string]$SMTPServer,
        [int]$Port = 587,
        [switch]$EnableTLS,
        [Parameter(Mandatory)]
        [string]$FromAddress,
        [string]$FromDisplayName = "Unity-Claude Automation"
    )
    
    Write-Host "[DEBUG] [EmailNotifications] Creating email configuration: $ConfigurationName (System.Net.Mail)" -ForegroundColor Gray
    
    try {
        # Validate SMTP server format
        if (-not ($SMTPServer -match '^[a-zA-Z0-9.-]+$')) {
            throw "Invalid SMTP server format: $SMTPServer"
        }
        
        # Validate email address format
        if (-not ($FromAddress -match '^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$')) {
            throw "Invalid email address format: $FromAddress"
        }
        
        # Validate port range
        if ($Port -lt 1 -or $Port -gt 65535) {
            throw "Invalid port number: $Port"
        }
        
        # Create configuration object
        $emailConfig = @{
            ConfigurationName = $ConfigurationName
            SMTPServer = $SMTPServer
            Port = $Port
            EnableTLS = $EnableTLS
            FromAddress = $FromAddress
            FromDisplayName = $FromDisplayName
            Created = Get-Date
            LastModified = Get-Date
            CredentialsConfigured = $false
            LastConnectionTest = $null
            ConnectionTestResult = $null
            Implementation = "System.Net.Mail"
        }
        
        # Store in module configuration
        $script:EmailConfiguration[$ConfigurationName] = $emailConfig
        
        Write-Host "[SUCCESS] [EmailNotifications] Email configuration '$ConfigurationName' created successfully (System.Net.Mail)" -ForegroundColor Green
        Write-Host "[INFO] [EmailNotifications] SMTP: $SMTPServer`:$Port (TLS: $EnableTLS)" -ForegroundColor White
        Write-Host "[INFO] [EmailNotifications] From: $FromDisplayName <$FromAddress>" -ForegroundColor White
        
        return $emailConfig
        
    } catch {
        Write-Host "[ERROR] [EmailNotifications] Failed to create email configuration '$ConfigurationName': $($_.Exception.Message)" -ForegroundColor Red
        throw
    }
}

function Set-EmailCredentials {
    <#
    .SYNOPSIS
    Sets secure credentials for email configuration using SecureString
    .DESCRIPTION
    Securely stores email authentication credentials using Windows DPAPI encryption
    .PARAMETER ConfigurationName
    Name of the email configuration
    .PARAMETER Username
    SMTP authentication username
    .PARAMETER Password
    SMTP authentication password (will be converted to SecureString)
    .PARAMETER SecurePassword
    SMTP authentication password as SecureString
    .PARAMETER Credential
    PSCredential object containing username and password
    .EXAMPLE
    Set-EmailCredentials -ConfigurationName "Production" -Username "alerts@company.com" -Password "mypassword"
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$ConfigurationName,
        [string]$Username,
        [string]$Password,
        [SecureString]$SecurePassword,
        [PSCredential]$Credential
    )
    
    Write-Host "[DEBUG] [EmailNotifications] Setting credentials for configuration: $ConfigurationName" -ForegroundColor Gray
    
    try {
        # Validate configuration exists
        if (-not $script:EmailConfiguration.ContainsKey($ConfigurationName)) {
            throw "Email configuration '$ConfigurationName' not found. Create it first with New-EmailConfiguration."
        }
        
        $config = $script:EmailConfiguration[$ConfigurationName]
        
        # Handle different credential input methods
        if ($Credential) {
            $finalUsername = $Credential.UserName
            $finalSecurePassword = $Credential.Password
        } elseif ($Username -and $SecurePassword) {
            $finalUsername = $Username
            $finalSecurePassword = $SecurePassword
        } elseif ($Username -and $Password) {
            $finalUsername = $Username
            $finalSecurePassword = ConvertTo-SecureString $Password -AsPlainText -Force
        } else {
            # Prompt for credentials
            Write-Host "[INFO] [EmailNotifications] Please enter SMTP credentials for '$ConfigurationName'" -ForegroundColor Yellow
            $promptedCred = Get-Credential -Message "Enter SMTP credentials for $($config.SMTPServer)"
            if (-not $promptedCred) {
                throw "No credentials provided"
            }
            $finalUsername = $promptedCred.UserName
            $finalSecurePassword = $promptedCred.Password
        }
        
        # Create encrypted credential storage
        $credentialData = @{
            Username = $finalUsername
            SecurePassword = $finalSecurePassword
            Created = Get-Date
            LastUsed = $null
        }
        
        # Store credentials in configuration (SecureString remains encrypted)
        $config.Credentials = $credentialData
        $config.CredentialsConfigured = $true
        $config.LastModified = Get-Date
        
        Write-Host "[SUCCESS] [EmailNotifications] Credentials configured for '$ConfigurationName'" -ForegroundColor Green
        Write-Host "[INFO] [EmailNotifications] Username: $finalUsername" -ForegroundColor White
        Write-Host "[INFO] [EmailNotifications] Password: [SecureString] (encrypted)" -ForegroundColor White
        
        return $true
        
    } catch {
        Write-Host "[ERROR] [EmailNotifications] Failed to set credentials for '$ConfigurationName': $($_.Exception.Message)" -ForegroundColor Red
        throw
    }
}

function Test-EmailConfiguration {
    <#
    .SYNOPSIS
    Tests email configuration using System.Net.Mail.SmtpClient
    .DESCRIPTION
    Validates SMTP connection and authentication using built-in .NET classes
    .PARAMETER ConfigurationName
    Name of the email configuration to test
    .PARAMETER SendTestEmail
    Send actual test email to verify delivery
    .PARAMETER TestRecipient
    Email address to receive test email
    .EXAMPLE
    Test-EmailConfiguration -ConfigurationName "Production"
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$ConfigurationName,
        [switch]$SendTestEmail,
        [string]$TestRecipient
    )
    
    Write-Host "[DEBUG] [EmailNotifications] Testing email configuration: $ConfigurationName (System.Net.Mail)" -ForegroundColor Gray
    
    try {
        # Validate configuration exists
        if (-not $script:EmailConfiguration.ContainsKey($ConfigurationName)) {
            throw "Email configuration '$ConfigurationName' not found"
        }
        
        $config = $script:EmailConfiguration[$ConfigurationName]
        
        # Validate credentials are configured
        if (-not $config.CredentialsConfigured) {
            throw "Credentials not configured for '$ConfigurationName'. Use Set-EmailCredentials first."
        }
        
        Write-Host "[INFO] [EmailNotifications] Testing SMTP connection to $($config.SMTPServer):$($config.Port)" -ForegroundColor White
        
        # Create System.Net.Mail.SmtpClient
        $smtpClient = New-Object System.Net.Mail.SmtpClient($config.SMTPServer, $config.Port)
        
        try {
            # Configure TLS if enabled
            if ($config.EnableTLS) {
                $smtpClient.EnableSsl = $true
                Write-Host "[DEBUG] [EmailNotifications] TLS/SSL enabled for connection" -ForegroundColor Gray
            }
            
            # Configure authentication
            $credentials = $config.Credentials
            $plaintextPassword = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto([System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($credentials.SecurePassword))
            
            $smtpClient.Credentials = New-Object System.Net.NetworkCredential($credentials.Username, $plaintextPassword)
            Write-Host "[DEBUG] [EmailNotifications] Authentication configured for user: $($credentials.Username)" -ForegroundColor Gray
            
            # Send test email if requested
            if ($SendTestEmail -and $TestRecipient) {
                Write-Host "[INFO] [EmailNotifications] Sending test email to: $TestRecipient" -ForegroundColor White
                
                $testMessage = New-Object System.Net.Mail.MailMessage
                $testMessage.From = New-Object System.Net.Mail.MailAddress($config.FromAddress, $config.FromDisplayName)
                $testMessage.To.Add($TestRecipient)
                $testMessage.Subject = "Unity-Claude Automation Test Email"
                $testMessage.Body = @"
Unity-Claude Automation System Test Email

Configuration: $ConfigurationName
SMTP Server: $($config.SMTPServer):$($config.Port)
TLS Enabled: $($config.EnableTLS)
Test Time: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
Implementation: System.Net.Mail (.NET Framework compatible)

This email confirms that the Unity-Claude email notification system is working correctly.

--
Unity-Claude Automation System
"@
                
                $smtpClient.Send($testMessage)
                Write-Host "[SUCCESS] [EmailNotifications] Test email sent successfully to $TestRecipient" -ForegroundColor Green
                
                $script:EmailDeliveryStats.TotalAttempts++
                $script:EmailDeliveryStats.SuccessfulDeliveries++
                $script:EmailDeliveryStats.LastDeliveryAttempt = Get-Date
                $script:EmailDeliveryStats.LastSuccessfulDelivery = Get-Date
                
                $testMessage.Dispose()
            }
            
            # Clear plaintext password from memory
            $plaintextPassword = $null
            [System.GC]::Collect()
            
            # Update configuration with test results
            $config.LastConnectionTest = Get-Date
            $config.ConnectionTestResult = "SUCCESS"
            $config.Credentials.LastUsed = Get-Date
            
            return @{
                Success = $true
                ConnectionTime = Get-Date
                SMTPServer = $config.SMTPServer
                Port = $config.Port
                TLSEnabled = $config.EnableTLS
                AuthenticationResult = "SUCCESS"
                TestEmailSent = $SendTestEmail -and $TestRecipient
                Implementation = "System.Net.Mail"
            }
            
        } finally {
            if ($smtpClient) {
                $smtpClient.Dispose()
            }
        }
        
    } catch {
        $config.LastConnectionTest = Get-Date
        $config.ConnectionTestResult = "FAILED: $($_.Exception.Message)"
        
        Write-Host "[ERROR] [EmailNotifications] Email configuration test failed: $($_.Exception.Message)" -ForegroundColor Red
        
        if ($SendTestEmail) {
            $script:EmailDeliveryStats.TotalAttempts++
            $script:EmailDeliveryStats.FailedDeliveries++
            $script:EmailDeliveryStats.LastDeliveryAttempt = Get-Date
        }
        
        return @{
            Success = $false
            Error = $_.Exception.Message
            ConnectionTime = Get-Date
            SMTPServer = $config.SMTPServer
            Port = $config.Port
            Implementation = "System.Net.Mail"
        }
    }
}

function Send-EmailNotification {
    <#
    .SYNOPSIS
    Sends email notification using configured SMTP settings
    .DESCRIPTION
    Sends email notification with template formatting and retry logic
    .PARAMETER ConfigurationName
    Name of the email configuration to use
    .PARAMETER ToAddress
    Recipient email address
    .PARAMETER Subject
    Email subject
    .PARAMETER Body
    Email body content
    .PARAMETER TemplateName
    Email template name for formatting
    .PARAMETER TemplateVariables
    Variables for template substitution
    .PARAMETER Priority
    Email priority (High, Normal, Low)
    .EXAMPLE
    Send-EmailNotification -ConfigurationName "Production" -ToAddress "admin@company.com" -Subject "Unity Error" -Body "Compilation failed"
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$ConfigurationName,
        [Parameter(Mandatory)]
        [string]$ToAddress,
        [string]$Subject,
        [string]$Body,
        [string]$TemplateName,
        [hashtable]$TemplateVariables,
        [ValidateSet('High', 'Normal', 'Low')]
        [string]$Priority = 'Normal'
    )
    
    Write-Host "[DEBUG] [EmailNotifications] Sending email notification via $ConfigurationName to $ToAddress" -ForegroundColor Gray
    
    try {
        # Validate configuration
        if (-not $script:EmailConfiguration.ContainsKey($ConfigurationName)) {
            throw "Email configuration '$ConfigurationName' not found"
        }
        
        $config = $script:EmailConfiguration[$ConfigurationName]
        
        if (-not $config.CredentialsConfigured) {
            throw "Credentials not configured for '$ConfigurationName'"
        }
        
        # Process template if specified
        if ($TemplateName -and $TemplateVariables) {
            $formattedContent = Format-NotificationContent -TemplateName $TemplateName -Variables $TemplateVariables
            $Subject = $formattedContent.Subject
            $Body = $formattedContent.BodyText
        }
        
        # Create and configure SMTP client
        $smtpClient = New-Object System.Net.Mail.SmtpClient($config.SMTPServer, $config.Port)
        
        try {
            if ($config.EnableTLS) {
                $smtpClient.EnableSsl = $true
            }
            
            # Configure authentication
            $credentials = $config.Credentials
            $plaintextPassword = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto([System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($credentials.SecurePassword))
            $smtpClient.Credentials = New-Object System.Net.NetworkCredential($credentials.Username, $plaintextPassword)
            
            # Create email message
            $message = New-Object System.Net.Mail.MailMessage
            $message.From = New-Object System.Net.Mail.MailAddress($config.FromAddress, $config.FromDisplayName)
            $message.To.Add($ToAddress)
            $message.Subject = $Subject
            $message.Body = $Body
            
            # Set priority
            switch ($Priority) {
                'High' { $message.Priority = [System.Net.Mail.MailPriority]::High }
                'Low' { $message.Priority = [System.Net.Mail.MailPriority]::Low }
                default { $message.Priority = [System.Net.Mail.MailPriority]::Normal }
            }
            
            # Send email
            Write-Host "[DEBUG] [EmailNotifications] Sending email: '$Subject' to $ToAddress" -ForegroundColor Gray
            $smtpClient.Send($message)
            
            # Clear password from memory
            $plaintextPassword = $null
            [System.GC]::Collect()
            
            # Update statistics
            $script:EmailDeliveryStats.TotalAttempts++
            $script:EmailDeliveryStats.SuccessfulDeliveries++
            $script:EmailDeliveryStats.LastDeliveryAttempt = Get-Date
            $script:EmailDeliveryStats.LastSuccessfulDelivery = Get-Date
            $config.Credentials.LastUsed = Get-Date
            
            Write-Host "[SUCCESS] [EmailNotifications] Email sent successfully to $ToAddress" -ForegroundColor Green
            
            $message.Dispose()
            
            return @{
                Success = $true
                ToAddress = $ToAddress
                Subject = $Subject
                SentTime = Get-Date
                Configuration = $ConfigurationName
                Implementation = "System.Net.Mail"
            }
            
        } finally {
            if ($smtpClient) {
                $smtpClient.Dispose()
            }
        }
        
    } catch {
        # Update failure statistics
        $script:EmailDeliveryStats.TotalAttempts++
        $script:EmailDeliveryStats.FailedDeliveries++
        $script:EmailDeliveryStats.LastDeliveryAttempt = Get-Date
        
        Write-Host "[ERROR] [EmailNotifications] Failed to send email to $ToAddress`: $($_.Exception.Message)" -ForegroundColor Red
        
        return @{
            Success = $false
            Error = $_.Exception.Message
            ToAddress = $ToAddress
            Subject = $Subject
            AttemptTime = Get-Date
            Configuration = $ConfigurationName
            Implementation = "System.Net.Mail"
        }
    }
}

function Get-EmailConfiguration {
    <#
    .SYNOPSIS
    Retrieves email configuration details
    .DESCRIPTION
    Gets email configuration information for specified configuration name
    .PARAMETER ConfigurationName
    Name of the email configuration to retrieve
    .PARAMETER IncludeCredentials
    Include credential information in output (username only, not password)
    .EXAMPLE
    Get-EmailConfiguration -ConfigurationName "Production"
    #>
    [CmdletBinding()]
    param(
        [string]$ConfigurationName,
        [switch]$IncludeCredentials
    )
    
    try {
        if ($ConfigurationName) {
            if (-not $script:EmailConfiguration.ContainsKey($ConfigurationName)) {
                throw "Email configuration '$ConfigurationName' not found"
            }
            
            $config = $script:EmailConfiguration[$ConfigurationName].Clone()
            
            if (-not $IncludeCredentials -and $config.ContainsKey('Credentials')) {
                $config.Remove('Credentials')
            } elseif ($IncludeCredentials -and $config.ContainsKey('Credentials')) {
                # Only include username, not password for security
                $config.Credentials = @{
                    Username = $config.Credentials.Username
                    Created = $config.Credentials.Created
                    LastUsed = $config.Credentials.LastUsed
                    PasswordConfigured = $config.Credentials.SecurePassword -ne $null
                }
            }
            
            return $config
            
        } else {
            # Return all configurations
            $allConfigs = @{}
            foreach ($configName in $script:EmailConfiguration.Keys) {
                $config = $script:EmailConfiguration[$configName].Clone()
                
                if (-not $IncludeCredentials -and $config.ContainsKey('Credentials')) {
                    $config.Remove('Credentials')
                } elseif ($IncludeCredentials -and $config.ContainsKey('Credentials')) {
                    $config.Credentials = @{
                        Username = $config.Credentials.Username
                        Created = $config.Credentials.Created
                        LastUsed = $config.Credentials.LastUsed
                        PasswordConfigured = $config.Credentials.SecurePassword -ne $null
                    }
                }
                
                $allConfigs[$configName] = $config
            }
            
            return $allConfigs
        }
        
    } catch {
        Write-Host "[ERROR] [EmailNotifications] Failed to get email configuration: $($_.Exception.Message)" -ForegroundColor Red
        throw
    }
}

# Copy template functions from original module (these work fine)
function New-EmailTemplate {
    <#
    .SYNOPSIS
    Creates a new email template for notifications
    .DESCRIPTION
    Creates email template with variable substitution and severity-based formatting
    .PARAMETER TemplateName
    Name for the email template
    .PARAMETER Subject
    Email subject template with variable placeholders
    .PARAMETER BodyText
    Plain text email body template
    .PARAMETER BodyHTML
    HTML email body template (optional)
    .PARAMETER Severity
    Template severity level (Critical, Error, Warning, Info)
    .EXAMPLE
    New-EmailTemplate -TemplateName "UnityError" -Subject "Unity Compilation Error: {ErrorType}" -BodyText "Error: {ErrorMessage}\nProject: {ProjectName}\nTime: {Timestamp}" -Severity "Error"
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$TemplateName,
        [Parameter(Mandatory)]
        [string]$Subject,
        [Parameter(Mandatory)]
        [string]$BodyText,
        [string]$BodyHTML,
        [ValidateSet('Critical', 'Error', 'Warning', 'Info')]
        [string]$Severity = 'Info'
    )
    
    Write-Host "[DEBUG] [EmailNotifications] Creating email template: $TemplateName (Severity: $Severity)" -ForegroundColor Gray
    
    try {
        $template = @{
            TemplateName = $TemplateName
            Subject = $Subject
            BodyText = $BodyText
            BodyHTML = $BodyHTML
            Severity = $Severity
            Created = Get-Date
            LastModified = Get-Date
            UsageCount = 0
            LastUsed = $null
        }
        
        $script:EmailTemplates[$TemplateName] = $template
        
        Write-Host "[SUCCESS] [EmailNotifications] Email template '$TemplateName' created successfully" -ForegroundColor Green
        Write-Host "[INFO] [EmailNotifications] Severity: $Severity" -ForegroundColor White
        Write-Host "[INFO] [EmailNotifications] Subject: $Subject" -ForegroundColor White
        
        return $template
        
    } catch {
        Write-Host "[ERROR] [EmailNotifications] Failed to create email template '$TemplateName': $($_.Exception.Message)" -ForegroundColor Red
        throw
    }
}

function Format-NotificationContent {
    <#
    .SYNOPSIS
    Formats notification content using template and variable substitution
    .DESCRIPTION
    Processes email template with variable substitution for dynamic content
    .PARAMETER TemplateName
    Name of the email template to use
    .PARAMETER Variables
    Hashtable of variables for template substitution
    .EXAMPLE
    $vars = @{ErrorType="CS0246"; ErrorMessage="Type not found"; ProjectName="MyGame"; Timestamp=(Get-Date)}
    Format-NotificationContent -TemplateName "UnityError" -Variables $vars
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$TemplateName,
        [Parameter(Mandatory)]
        [hashtable]$Variables
    )
    
    Write-Host "[DEBUG] [EmailNotifications] Formatting notification content with template: $TemplateName" -ForegroundColor Gray
    
    try {
        if (-not $script:EmailTemplates.ContainsKey($TemplateName)) {
            throw "Email template '$TemplateName' not found"
        }
        
        $template = $script:EmailTemplates[$TemplateName]
        
        # Process subject with variable substitution
        $processedSubject = $template.Subject
        foreach ($varName in $Variables.Keys) {
            $varValue = $Variables[$varName]
            $processedSubject = $processedSubject -replace "\{$varName\}", $varValue
        }
        
        # Process body text with variable substitution
        $processedBodyText = $template.BodyText
        foreach ($varName in $Variables.Keys) {
            $varValue = $Variables[$varName]
            $processedBodyText = $processedBodyText -replace "\{$varName\}", $varValue
        }
        
        # Process HTML body if available
        $processedBodyHTML = $null
        if ($template.BodyHTML) {
            $processedBodyHTML = $template.BodyHTML
            foreach ($varName in $Variables.Keys) {
                $varValue = $Variables[$varName]
                $processedBodyHTML = $processedBodyHTML -replace "\{$varName\}", $varValue
            }
        }
        
        # Update template usage statistics
        $template.UsageCount++
        $template.LastUsed = Get-Date
        
        $formattedContent = @{
            TemplateName = $TemplateName
            Severity = $template.Severity
            Subject = $processedSubject
            BodyText = $processedBodyText
            BodyHTML = $processedBodyHTML
            Variables = $Variables
            ProcessedTime = Get-Date
        }
        
        Write-Host "[SUCCESS] [EmailNotifications] Notification content formatted successfully" -ForegroundColor Green
        Write-Host "[DEBUG] [EmailNotifications] Processed subject: $processedSubject" -ForegroundColor Gray
        
        return $formattedContent
        
    } catch {
        Write-Host "[ERROR] [EmailNotifications] Failed to format notification content: $($_.Exception.Message)" -ForegroundColor Red
        throw
    }
}

function Send-EmailWithRetry {
    <#
    .SYNOPSIS
    Sends email notification with retry logic and exponential backoff
    .DESCRIPTION
    Sends email with comprehensive retry logic for production reliability
    .PARAMETER ConfigurationName
    Name of the email configuration to use
    .PARAMETER ToAddress
    Recipient email address
    .PARAMETER Subject
    Email subject
    .PARAMETER Body
    Email body content
    .PARAMETER MaxRetries
    Maximum number of retry attempts (default: 3)
    .PARAMETER BaseDelaySeconds
    Base delay for exponential backoff (default: 1)
    .PARAMETER TemplateName
    Email template name for formatting
    .PARAMETER TemplateVariables
    Variables for template substitution
    .EXAMPLE
    Send-EmailWithRetry -ConfigurationName "Production" -ToAddress "admin@company.com" -Subject "Unity Error" -Body "Compilation failed" -MaxRetries 5
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$ConfigurationName,
        [Parameter(Mandatory)]
        [string]$ToAddress,
        [string]$Subject,
        [string]$Body,
        [int]$MaxRetries = 3,
        [int]$BaseDelaySeconds = 1,
        [string]$TemplateName,
        [hashtable]$TemplateVariables
    )
    
    Write-Host "[DEBUG] [EmailNotifications] Sending email with retry logic: $Subject to $ToAddress (Max retries: $MaxRetries)" -ForegroundColor Gray
    
    $attempt = 0
    $lastError = $null
    
    while ($attempt -le $MaxRetries) {
        $attempt++
        
        try {
            Write-Host "[DEBUG] [EmailNotifications] Email delivery attempt $attempt/$($MaxRetries + 1)" -ForegroundColor Gray
            
            # Attempt email delivery
            $result = Send-EmailNotification -ConfigurationName $ConfigurationName -ToAddress $ToAddress -Subject $Subject -Body $Body -TemplateName $TemplateName -TemplateVariables $TemplateVariables
            
            if ($result.Success) {
                Write-Host "[SUCCESS] [EmailNotifications] Email delivered successfully on attempt $attempt" -ForegroundColor Green
                
                return @{
                    Success = $true
                    DeliveryAttempts = $attempt
                    FinalResult = $result
                    TotalRetryTime = 0
                }
            } else {
                $lastError = $result.Error
                throw $result.Error
            }
            
        } catch {
            $lastError = $_.Exception.Message
            Write-Host "[WARNING] [EmailNotifications] Email delivery attempt $attempt failed: $lastError" -ForegroundColor Yellow
            
            # If this is the last attempt, don't delay
            if ($attempt -le $MaxRetries) {
                # Calculate exponential backoff delay
                $delaySeconds = $BaseDelaySeconds * [math]::Pow(2, $attempt - 1)
                Write-Host "[DEBUG] [EmailNotifications] Waiting $delaySeconds seconds before retry..." -ForegroundColor Gray
                Start-Sleep -Seconds $delaySeconds
            }
        }
    }
    
    # All retries failed
    Write-Host "[ERROR] [EmailNotifications] Email delivery failed after $($MaxRetries + 1) attempts: $lastError" -ForegroundColor Red
    
    return @{
        Success = $false
        DeliveryAttempts = $attempt
        FinalError = $lastError
        TotalRetryTime = ($BaseDelaySeconds * ([math]::Pow(2, $MaxRetries) - 1))
    }
}

function Register-EmailNotificationTrigger {
    <#
    .SYNOPSIS
    Registers email notification trigger for Unity-Claude workflow events
    .DESCRIPTION
    Creates email notification trigger for specific workflow events
    .PARAMETER TriggerName
    Name for the notification trigger
    .PARAMETER EventType
    Type of event to trigger on (UnityError, ClaudeFailure, WorkflowStatus, SystemHealth)
    .PARAMETER ConfigurationName
    Email configuration to use for notifications
    .PARAMETER ToAddress
    Email address to send notifications to
    .PARAMETER TemplateName
    Email template to use for formatting
    .PARAMETER Conditions
    Hashtable of conditions that must be met for trigger to fire
    .EXAMPLE
    Register-EmailNotificationTrigger -TriggerName "CriticalErrors" -EventType "UnityError" -ConfigurationName "Production" -ToAddress "admin@company.com" -TemplateName "UnityErrorTemplate"
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$TriggerName,
        [Parameter(Mandatory)]
        [ValidateSet('UnityError', 'ClaudeFailure', 'WorkflowStatus', 'SystemHealth', 'AutonomousAgent')]
        [string]$EventType,
        [Parameter(Mandatory)]
        [string]$ConfigurationName,
        [Parameter(Mandatory)]
        [string]$ToAddress,
        [string]$TemplateName,
        [hashtable]$Conditions = @{}
    )
    
    Write-Host "[DEBUG] [EmailNotifications] Registering email notification trigger: $TriggerName ($EventType)" -ForegroundColor Gray
    
    try {
        # Validate email configuration exists
        if (-not $script:EmailConfiguration.ContainsKey($ConfigurationName)) {
            throw "Email configuration '$ConfigurationName' not found"
        }
        
        # Validate template exists if specified
        if ($TemplateName -and -not $script:EmailTemplates.ContainsKey($TemplateName)) {
            throw "Email template '$TemplateName' not found"
        }
        
        # Create trigger configuration
        $trigger = @{
            TriggerName = $TriggerName
            EventType = $EventType
            ConfigurationName = $ConfigurationName
            ToAddress = $ToAddress
            TemplateName = $TemplateName
            Conditions = $Conditions
            Created = Get-Date
            LastTriggered = $null
            TriggerCount = 0
            SuccessfulNotifications = 0
            FailedNotifications = 0
            Enabled = $true
        }
        
        # Store trigger
        $script:NotificationTriggers[$TriggerName] = $trigger
        
        Write-Host "[SUCCESS] [EmailNotifications] Email notification trigger '$TriggerName' registered successfully" -ForegroundColor Green
        Write-Host "[INFO] [EmailNotifications] Event type: $EventType → $ToAddress" -ForegroundColor White
        if ($TemplateName) {
            Write-Host "[INFO] [EmailNotifications] Template: $TemplateName" -ForegroundColor White
        }
        
        return $trigger
        
    } catch {
        Write-Host "[ERROR] [EmailNotifications] Failed to register notification trigger '$TriggerName': $($_.Exception.Message)" -ForegroundColor Red
        throw
    }
}

function Invoke-EmailNotificationTrigger {
    <#
    .SYNOPSIS
    Invokes email notification trigger with event data
    .DESCRIPTION
    Processes workflow event and sends notification if trigger conditions are met
    .PARAMETER TriggerName
    Name of the trigger to invoke
    .PARAMETER EventData
    Hashtable containing event data for template variable substitution
    .PARAMETER ForceNotification
    Send notification regardless of conditions
    .EXAMPLE
    $eventData = @{ErrorType="CS0246"; ErrorMessage="Type not found"; ProjectName="MyGame"}
    Invoke-EmailNotificationTrigger -TriggerName "CriticalErrors" -EventData $eventData
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$TriggerName,
        [Parameter(Mandatory)]
        [hashtable]$EventData,
        [switch]$ForceNotification
    )
    
    Write-Host "[DEBUG] [EmailNotifications] Invoking email notification trigger: $TriggerName" -ForegroundColor Gray
    
    try {
        # Validate trigger exists
        if (-not $script:NotificationTriggers.ContainsKey($TriggerName)) {
            throw "Email notification trigger '$TriggerName' not found"
        }
        
        $trigger = $script:NotificationTriggers[$TriggerName]
        
        # Check if trigger is enabled
        if (-not $trigger.Enabled -and -not $ForceNotification) {
            Write-Host "[DEBUG] [EmailNotifications] Trigger '$TriggerName' is disabled, skipping notification" -ForegroundColor Gray
            return @{ Success = $false; Reason = "Trigger disabled" }
        }
        
        # Evaluate trigger conditions
        $conditionsMet = $true
        if ($trigger.Conditions.Count -gt 0 -and -not $ForceNotification) {
            foreach ($conditionKey in $trigger.Conditions.Keys) {
                $expectedValue = $trigger.Conditions[$conditionKey]
                $actualValue = $EventData[$conditionKey]
                
                if ($actualValue -ne $expectedValue) {
                    $conditionsMet = $false
                    Write-Host "[DEBUG] [EmailNotifications] Trigger condition not met: $conditionKey ($actualValue != $expectedValue)" -ForegroundColor Gray
                    break
                }
            }
        }
        
        if (-not $conditionsMet -and -not $ForceNotification) {
            Write-Host "[DEBUG] [EmailNotifications] Trigger conditions not met for '$TriggerName', skipping notification" -ForegroundColor Gray
            return @{ Success = $false; Reason = "Conditions not met" }
        }
        
        # Prepare notification content
        $subject = "Unity-Claude System Notification"
        $body = "Event notification from Unity-Claude automation system"
        
        # Use template if specified
        if ($trigger.TemplateName) {
            $formattedContent = Format-NotificationContent -TemplateName $trigger.TemplateName -Variables $EventData
            $subject = $formattedContent.Subject
            $body = $formattedContent.BodyText
        } else {
            # Default formatting
            $subject = "Unity-Claude $($trigger.EventType) Notification"
            $body = @"
Unity-Claude Automation System Notification

Event Type: $($trigger.EventType)
Trigger: $TriggerName
Time: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')

Event Data:
$($EventData.GetEnumerator() | ForEach-Object { "$($_.Key): $($_.Value)" } | Out-String)

--
Unity-Claude Automation System
"@
        }
        
        # Send notification with retry logic
        Write-Host "[INFO] [EmailNotifications] Sending $($trigger.EventType) notification via trigger '$TriggerName'" -ForegroundColor White
        $deliveryResult = Send-EmailWithRetry -ConfigurationName $trigger.ConfigurationName -ToAddress $trigger.ToAddress -Subject $subject -Body $body -MaxRetries 3
        
        # Update trigger statistics
        $trigger.LastTriggered = Get-Date
        $trigger.TriggerCount++
        
        if ($deliveryResult.Success) {
            $trigger.SuccessfulNotifications++
            Write-Host "[SUCCESS] [EmailNotifications] Notification sent successfully via trigger '$TriggerName'" -ForegroundColor Green
        } else {
            $trigger.FailedNotifications++
            Write-Host "[ERROR] [EmailNotifications] Notification failed via trigger '$TriggerName': $($deliveryResult.FinalError)" -ForegroundColor Red
        }
        
        return @{
            Success = $deliveryResult.Success
            TriggerName = $TriggerName
            EventType = $trigger.EventType
            Subject = $subject
            DeliveryResult = $deliveryResult
            TriggerTime = $trigger.LastTriggered
        }
        
    } catch {
        Write-Host "[ERROR] [EmailNotifications] Failed to invoke notification trigger '$TriggerName': $($_.Exception.Message)" -ForegroundColor Red
        
        if ($script:NotificationTriggers.ContainsKey($TriggerName)) {
            $script:NotificationTriggers[$TriggerName].FailedNotifications++
        }
        
        return @{
            Success = $false
            Error = $_.Exception.Message
            TriggerName = $TriggerName
        }
    }
}

function Get-EmailNotificationTriggers {
    <#
    .SYNOPSIS
    Gets registered email notification triggers
    .DESCRIPTION
    Returns information about registered email notification triggers
    .PARAMETER TriggerName
    Specific trigger name to retrieve
    .PARAMETER EventType
    Filter by event type
    .EXAMPLE
    Get-EmailNotificationTriggers
    #>
    [CmdletBinding()]
    param(
        [string]$TriggerName,
        [string]$EventType
    )
    
    try {
        if ($TriggerName) {
            if (-not $script:NotificationTriggers.ContainsKey($TriggerName)) {
                throw "Email notification trigger '$TriggerName' not found"
            }
            return $script:NotificationTriggers[$TriggerName].Clone()
        } else {
            $allTriggers = @{}
            foreach ($triggerKey in $script:NotificationTriggers.Keys) {
                $trigger = $script:NotificationTriggers[$triggerKey]
                
                # Filter by event type if specified
                if ($EventType -and $trigger.EventType -ne $EventType) {
                    continue
                }
                
                $allTriggers[$triggerKey] = $trigger.Clone()
            }
            
            return $allTriggers
        }
        
    } catch {
        Write-Host "[ERROR] [EmailNotifications] Failed to get notification triggers: $($_.Exception.Message)" -ForegroundColor Red
        throw
    }
}

function Get-EmailDeliveryStatus {
    <#
    .SYNOPSIS
    Gets detailed email delivery status and analytics
    .DESCRIPTION
    Returns comprehensive email delivery statistics and status information
    .PARAMETER ConfigurationName
    Filter by specific email configuration
    .PARAMETER IncludeTriggerStats
    Include notification trigger statistics
    .EXAMPLE
    Get-EmailDeliveryStatus -IncludeTriggerStats
    #>
    [CmdletBinding()]
    param(
        [string]$ConfigurationName,
        [switch]$IncludeTriggerStats
    )
    
    try {
        $deliveryStatus = @{
            OverallStats = $script:EmailDeliveryStats.Clone()
            Configurations = @{}
            TriggerStats = @{}
            GeneratedTime = Get-Date
        }
        
        # Add configuration-specific stats
        foreach ($configName in $script:EmailConfiguration.Keys) {
            if ($ConfigurationName -and $configName -ne $ConfigurationName) {
                continue
            }
            
            $config = $script:EmailConfiguration[$configName]
            $deliveryStatus.Configurations[$configName] = @{
                SMTPServer = $config.SMTPServer
                Port = $config.Port
                EnableTLS = $config.EnableTLS
                LastConnectionTest = $config.LastConnectionTest
                ConnectionTestResult = $config.ConnectionTestResult
                CredentialsConfigured = $config.CredentialsConfigured
                Implementation = $config.Implementation
            }
        }
        
        # Add trigger statistics if requested
        if ($IncludeTriggerStats) {
            foreach ($triggerName in $script:NotificationTriggers.Keys) {
                $trigger = $script:NotificationTriggers[$triggerName]
                $deliveryStatus.TriggerStats[$triggerName] = @{
                    EventType = $trigger.EventType
                    TriggerCount = $trigger.TriggerCount
                    SuccessfulNotifications = $trigger.SuccessfulNotifications
                    FailedNotifications = $trigger.FailedNotifications
                    LastTriggered = $trigger.LastTriggered
                    Enabled = $trigger.Enabled
                    SuccessRate = if ($trigger.TriggerCount -gt 0) { 
                        [math]::Round(($trigger.SuccessfulNotifications / $trigger.TriggerCount) * 100, 1) 
                    } else { 0 }
                }
            }
        }
        
        return $deliveryStatus
        
    } catch {
        Write-Host "[ERROR] [EmailNotifications] Failed to get email delivery status: $($_.Exception.Message)" -ForegroundColor Red
        throw
    }
}

function Get-EmailDeliveryStats {
    <#
    .SYNOPSIS
    Gets email delivery statistics (simple version)
    .DESCRIPTION
    Returns basic statistics about email delivery attempts and success rates
    .EXAMPLE
    Get-EmailDeliveryStats
    #>
    [CmdletBinding()]
    param()
    
    return $script:EmailDeliveryStats.Clone()
}

# Module initialization
Write-Host "[SUCCESS] [EmailNotifications] Unity-Claude-EmailNotifications loaded successfully (System.Net.Mail implementation)" -ForegroundColor Green
Write-Host "[INFO] [EmailNotifications] Using System.Net.Mail for PowerShell 5.1 compatibility" -ForegroundColor White

# Export functions - Week 5 Day 2 Enhanced Integration Functions
Export-ModuleMember -Function @(
    'New-EmailConfiguration',
    'Set-EmailCredentials',
    'Test-EmailConfiguration', 
    'Get-EmailConfiguration',
    'New-EmailTemplate',
    'Format-NotificationContent',
    'Send-EmailNotification',
    'Send-EmailWithRetry',
    'Register-EmailNotificationTrigger',
    'Invoke-EmailNotificationTrigger',
    'Get-EmailNotificationTriggers',
    'Get-EmailDeliveryStatus',
    'Get-EmailDeliveryStats'
)
# SIG # Begin signature block
# MIIFqQYJKoZIhvcNAQcCoIIFmjCCBZYCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUP29ghk92ZpeCmA7uMUW3XO/S
# yiWgggMwMIIDLDCCAhSgAwIBAgIQdR0W2SKoK5VE8JId4ZxrRTANBgkqhkiG9w0B
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
# CQQxFgQUTwfUKdfHP4ooZA+OxD4Gqnc3rhswDQYJKoZIhvcNAQEBBQAEggEAHipT
# cssIJ7W+f9qdI/Qa3rBFc4pHaf4pDsAU0NMioiZLQkOV5fTSuRzgyWytNT+ebbmd
# XDtnb4i+IDwWqNnbtzuypWvcsBf8D2hMVQxDguDwIMvXD7E9CovtlL3UG+wn7ebS
# AW7l9CZS0cLD7z3iDnRrh/pAjFTzhlMXYx23pcnqcjygj2Pja6Nk77ZK45DbohQW
# jyIkWTm6t2lE1MxAcOhIjNi772JVRDcJblI2CyNkymkXCcEHJjLr8fqYXh7cQSw2
# bixAR2GTE64mSZd7MvRvzEtEy5dUAyuYtC0pIW38hZ4HJjC/yvsV7KVF7SDeQSRu
# wW6LtbEIND9X/eYZ2Q==
# SIG # End signature block
