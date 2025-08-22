# Unity-Claude-EmailNotifications.psm1
# Phase 2 Week 5 Days 1-2: Email System Implementation
# Secure email notification system using MailKit for Unity-Claude autonomous operation
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
$script:MailKitAssembliesLoaded = $false

# Week 5 Day 1 Hour 1-2: MailKit Assembly Loading
function Load-MailKitAssemblies {
    [CmdletBinding()]
    param()
    
    Write-Host "[DEBUG] [EmailNotifications] Attempting to load MailKit assemblies..." -ForegroundColor Gray
    
    try {
        # Check if assemblies are already loaded
        if ([System.AppDomain]::CurrentDomain.GetAssemblies() | Where-Object { $_.GetName().Name -eq "MimeKit" }) {
            Write-Host "[DEBUG] [EmailNotifications] MimeKit already loaded" -ForegroundColor Gray
            $script:MailKitAssembliesLoaded = $true
            return $true
        }
        
        # Try to source from Load-MailKitAssemblies.ps1 helper if available
        $helperPath = Join-Path (Split-Path $PSScriptRoot -Parent | Split-Path -Parent) "Load-MailKitAssemblies.ps1"
        if (Test-Path $helperPath) {
            Write-Host "[DEBUG] [EmailNotifications] Using MailKit assembly helper: $helperPath" -ForegroundColor Gray
            . $helperPath
            $script:MailKitAssembliesLoaded = $true
            return $true
        }
        
        # Try common NuGet package locations
        $possiblePaths = @(
            "$env:ProgramFiles\PackageManagement\NuGet\Packages",
            "$env:USERPROFILE\.nuget\packages",
            "$env:LOCALAPPDATA\Microsoft\Windows\PowerShell\NuGet\Packages"
        )
        
        foreach ($basePath in $possiblePaths) {
            # Look for MimeKit DLL (load first - dependency)
            $mimeKitPattern = "$basePath\MimeKit*\lib\*\MimeKit.dll"
            $foundMimeKit = Get-ChildItem $mimeKitPattern -ErrorAction SilentlyContinue | Sort-Object LastWriteTime -Descending | Select-Object -First 1
            
            # Look for MailKit DLL
            $mailKitPattern = "$basePath\MailKit*\lib\*\MailKit.dll"
            $foundMailKit = Get-ChildItem $mailKitPattern -ErrorAction SilentlyContinue | Sort-Object LastWriteTime -Descending | Select-Object -First 1
            
            if ($foundMimeKit -and $foundMailKit) {
                Write-Host "[DEBUG] [EmailNotifications] Loading MimeKit: $($foundMimeKit.FullName)" -ForegroundColor Gray
                Add-Type -Path $foundMimeKit.FullName -ErrorAction Stop
                
                Write-Host "[DEBUG] [EmailNotifications] Loading MailKit: $($foundMailKit.FullName)" -ForegroundColor Gray
                Add-Type -Path $foundMailKit.FullName -ErrorAction Stop
                
                $script:MailKitAssembliesLoaded = $true
                Write-Host "[SUCCESS] [EmailNotifications] MailKit assemblies loaded successfully" -ForegroundColor Green
                return $true
            }
        }
        
        throw "MailKit assemblies not found. Run Install-MailKitForUnityClaudeAutomation.ps1 first."
        
    } catch {
        Write-Warning "[EmailNotifications] Failed to load MailKit assemblies: $($_.Exception.Message)"
        $script:MailKitAssembliesLoaded = $false
        return $false
    }
}

# Week 5 Day 1 Hour 3-4: Secure SMTP Configuration System
function New-EmailConfiguration {
    <#
    .SYNOPSIS
    Creates a new email configuration for Unity-Claude notification system
    .DESCRIPTION
    Creates secure SMTP configuration with credential management for email notifications
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
    
    Write-Host "[DEBUG] [EmailNotifications] Creating email configuration: $ConfigurationName" -ForegroundColor Gray
    
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
        }
        
        # Store in module configuration
        $script:EmailConfiguration[$ConfigurationName] = $emailConfig
        
        Write-Host "[SUCCESS] [EmailNotifications] Email configuration '$ConfigurationName' created successfully" -ForegroundColor Green
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
    .EXAMPLE
    $cred = Get-Credential; Set-EmailCredentials -ConfigurationName "Production" -Credential $cred
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
    Tests email configuration by attempting SMTP connection
    .DESCRIPTION
    Validates SMTP connection and authentication using MailKit
    .PARAMETER ConfigurationName
    Name of the email configuration to test
    .PARAMETER SendTestEmail
    Send actual test email to verify delivery
    .PARAMETER TestRecipient
    Email address to receive test email
    .EXAMPLE
    Test-EmailConfiguration -ConfigurationName "Production"
    .EXAMPLE
    Test-EmailConfiguration -ConfigurationName "Production" -SendTestEmail -TestRecipient "admin@company.com"
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$ConfigurationName,
        [switch]$SendTestEmail,
        [string]$TestRecipient
    )
    
    Write-Host "[DEBUG] [EmailNotifications] Testing email configuration: $ConfigurationName" -ForegroundColor Gray
    
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
        
        # Ensure MailKit assemblies are loaded
        if (-not $script:MailKitAssembliesLoaded) {
            if (-not (Load-MailKitAssemblies)) {
                throw "MailKit assemblies not available. Run Install-MailKitForUnityClaudeAutomation.ps1 first."
            }
        }
        
        Write-Host "[INFO] [EmailNotifications] Testing SMTP connection to $($config.SMTPServer):$($config.Port)" -ForegroundColor White
        
        # Test SMTP connection
        $smtpClient = New-Object MailKit.Net.Smtp.SmtpClient
        
        try {
            # Configure connection security
            $secureSocketOptions = if ($config.EnableTLS) {
                [MailKit.Security.SecureSocketOptions]::StartTls
            } else {
                [MailKit.Security.SecureSocketOptions]::None
            }
            
            Write-Host "[DEBUG] [EmailNotifications] Connecting with security options: $secureSocketOptions" -ForegroundColor Gray
            $smtpClient.Connect($config.SMTPServer, $config.Port, $secureSocketOptions, $false)
            Write-Host "[SUCCESS] [EmailNotifications] SMTP connection established" -ForegroundColor Green
            
            # Test authentication
            $credentials = $config.Credentials
            $plaintextPassword = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto([System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($credentials.SecurePassword))
            
            Write-Host "[DEBUG] [EmailNotifications] Testing authentication for user: $($credentials.Username)" -ForegroundColor Gray
            $smtpClient.Authenticate($credentials.Username, $plaintextPassword)
            Write-Host "[SUCCESS] [EmailNotifications] SMTP authentication successful" -ForegroundColor Green
            
            # Clear plaintext password from memory
            $plaintextPassword = $null
            [System.GC]::Collect()
            
            # Update configuration with test results
            $config.LastConnectionTest = Get-Date
            $config.ConnectionTestResult = "SUCCESS"
            $config.Credentials.LastUsed = Get-Date
            
            # Send test email if requested
            if ($SendTestEmail -and $TestRecipient) {
                Write-Host "[INFO] [EmailNotifications] Sending test email to: $TestRecipient" -ForegroundColor White
                
                $testMessage = New-Object MimeKit.MimeMessage
                $testMessage.From.Add([MimeKit.MailboxAddress]::new($config.FromDisplayName, $config.FromAddress))
                $testMessage.To.Add([MimeKit.MailboxAddress]::new($TestRecipient))
                $testMessage.Subject = "Unity-Claude Automation Test Email"
                
                $textPart = [MimeKit.TextPart]::new("plain")
                $textPart.Text = @"
Unity-Claude Automation System Test Email

Configuration: $ConfigurationName
SMTP Server: $($config.SMTPServer):$($config.Port)
TLS Enabled: $($config.EnableTLS)
Test Time: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')

This email confirms that the Unity-Claude email notification system is working correctly.

--
Unity-Claude Automation System
"@
                $testMessage.Body = $textPart
                
                $smtpClient.Send($testMessage)
                Write-Host "[SUCCESS] [EmailNotifications] Test email sent successfully to $TestRecipient" -ForegroundColor Green
                
                $script:EmailDeliveryStats.TotalAttempts++
                $script:EmailDeliveryStats.SuccessfulDeliveries++
                $script:EmailDeliveryStats.LastDeliveryAttempt = Get-Date
                $script:EmailDeliveryStats.LastSuccessfulDelivery = Get-Date
            }
            
            $smtpClient.Disconnect($true)
            
            return @{
                Success = $true
                ConnectionTime = Get-Date
                SMTPServer = $config.SMTPServer
                Port = $config.Port
                TLSEnabled = $config.EnableTLS
                AuthenticationResult = "SUCCESS"
                TestEmailSent = $SendTestEmail -and $TestRecipient
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

# Week 5 Day 1 Hour 5-6: Email Template Engine
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
        # Create template object
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
        
        # Store in module templates
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
        # Validate template exists
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

# Initialize module
Write-Host "[DEBUG] [EmailNotifications] Loading Unity-Claude-EmailNotifications module..." -ForegroundColor Gray

# Attempt to load MailKit assemblies during module import
$assemblyLoadResult = Load-MailKitAssemblies

if ($assemblyLoadResult) {
    Write-Host "[SUCCESS] [EmailNotifications] Unity-Claude-EmailNotifications module loaded successfully (MailKit available)" -ForegroundColor Green
} else {
    Write-Host "[WARNING] [EmailNotifications] Unity-Claude-EmailNotifications module loaded but MailKit assemblies not available" -ForegroundColor Yellow
    Write-Host "[INFO] [EmailNotifications] Run Install-MailKitForUnityClaudeAutomation.ps1 to enable email functionality" -ForegroundColor White
}

# Export functions including assembly loading helper
Export-ModuleMember -Function @(
    'Load-MailKitAssemblies',
    'New-EmailConfiguration',
    'Set-EmailCredentials', 
    'Test-EmailConfiguration',
    'Get-EmailConfiguration',
    'New-EmailTemplate',
    'Format-NotificationContent'
)
# SIG # Begin signature block
# MIIFqQYJKoZIhvcNAQcCoIIFmjCCBZYCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUFBqjqfx1QWGz+0y/UJxmoUBv
# sk6gggMwMIIDLDCCAhSgAwIBAgIQdR0W2SKoK5VE8JId4ZxrRTANBgkqhkiG9w0B
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
# CQQxFgQUNJxsT03baETdySjRAb7uq46/+eIwDQYJKoZIhvcNAQEBBQAEggEAIAZ0
# wfot7M19dGeuiEJzfn3rK1+Y77lsVSEAqjo7m/IgY/bf/2CC5kmTFuS0jm72Gcrr
# emuvU1hLI2Wr93NRioV+oUsVawLRKPQj6Uv21O3Nulw13QUWWkg+neJDgavJj8q8
# SJHc69NhQaP3gKwRZVfw0lkugb601DjucmHZWXQJyF0HIGf1IW+CupfzcCA59k2a
# 69lSeXsdSgg2p8l6z7SmlRVR4QqI08FWSs8NHu3Baspr+OhSgekub0gxDgX0l2DW
# wPFcxpUFYU86wonKvwqUC4eobmh1L2DhOY+MkAcwoUkRVAOpCI/oUhIzjncCnXlE
# J+Yv5gOiNxdM0wywwQ==
# SIG # End signature block
