# Unity-Claude-NotificationContentEngine Module
# Phase 2 Week 5 Day 5: Notification Content Engine Implementation
# Date: 2025-08-21
#
# Unified notification content engine for email and webhook notifications
# with severity-based routing and template management

#region Module Configuration

$script:ModuleVersion = '1.0.0'
$script:ModuleName = 'Unity-Claude-NotificationContentEngine'

# Module state storage
$script:NotificationTemplates = @{}
$script:TemplateComponents = @{}
$script:RoutingRules = @{}
$script:ChannelPreferences = @{}
$script:NotificationHistory = @()
$script:ContentEngineConfig = @{
    MaxHistoryItems = 1000
    ThrottleWindowMinutes = 5
    DefaultSeverity = 'Info'
    EnablePreview = $true
    EnableValidation = $true
    TemplateVersion = '1.0'
}

# Severity levels and their priority mappings
$script:SeverityLevels = @{
    'Critical' = 1
    'Error' = 2
    'Warning' = 3
    'Info' = 4
}

# Default channel mappings by severity
$script:DefaultChannelMappings = @{
    'Critical' = @('Email', 'Webhook')
    'Error' = @('Email', 'Webhook')
    'Warning' = @('Email')
    'Info' = @('Webhook')
}

#endregion Module Configuration

#region Unified Template System (Hours 1-4)

function New-UnifiedNotificationTemplate {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Name,
        
        [Parameter(Mandatory = $true)]
        [string]$Description,
        
        [Parameter(Mandatory = $true)]
        [hashtable]$EmailContent,
        
        [Parameter(Mandatory = $true)]
        [hashtable]$WebhookContent,
        
        [Parameter()]
        [hashtable]$Variables = @{},
        
        [Parameter()]
        [string]$Version = '1.0',
        
        [Parameter()]
        [string[]]$Components = @(),
        
        [Parameter()]
        [hashtable]$Metadata = @{}
    )
    
    Write-Verbose "Creating unified notification template: $Name"
    
    $template = @{
        Name = $Name
        Description = $Description
        EmailContent = $EmailContent
        WebhookContent = $WebhookContent
        Variables = $Variables
        Version = $Version
        Components = $Components
        Metadata = $Metadata
        CreatedAt = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
        ModifiedAt = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
    }
    
    # Validate template structure
    if (-not (Test-TemplateStructure -Template $template)) {
        throw "Template validation failed for: $Name"
    }
    
    # Store template
    $script:NotificationTemplates[$Name] = $template
    
    Write-Verbose "Successfully created template: $Name (Version: $Version)"
    return $template
}

function Set-NotificationTemplate {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Name,
        
        [Parameter()]
        [hashtable]$EmailContent,
        
        [Parameter()]
        [hashtable]$WebhookContent,
        
        [Parameter()]
        [hashtable]$Variables,
        
        [Parameter()]
        [string]$Version,
        
        [Parameter()]
        [string[]]$Components,
        
        [Parameter()]
        [hashtable]$Metadata
    )
    
    Write-Verbose "Updating notification template: $Name"
    
    if (-not $script:NotificationTemplates.ContainsKey($Name)) {
        throw "Template not found: $Name"
    }
    
    $template = $script:NotificationTemplates[$Name]
    
    # Update provided fields
    if ($PSBoundParameters.ContainsKey('EmailContent')) {
        $template.EmailContent = $EmailContent
    }
    if ($PSBoundParameters.ContainsKey('WebhookContent')) {
        $template.WebhookContent = $WebhookContent
    }
    if ($PSBoundParameters.ContainsKey('Variables')) {
        $template.Variables = $Variables
    }
    if ($PSBoundParameters.ContainsKey('Version')) {
        $template.Version = $Version
    }
    if ($PSBoundParameters.ContainsKey('Components')) {
        $template.Components = $Components
    }
    if ($PSBoundParameters.ContainsKey('Metadata')) {
        $template.Metadata = $Metadata
    }
    
    $template.ModifiedAt = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
    
    # Validate updated template
    if (-not (Test-TemplateStructure -Template $template)) {
        throw "Template validation failed after update: $Name"
    }
    
    Write-Verbose "Successfully updated template: $Name"
    return $template
}

function Get-NotificationTemplate {
    [CmdletBinding()]
    param(
        [Parameter()]
        [string]$Name,
        
        [Parameter()]
        [string]$Version
    )
    
    if ($Name) {
        if ($script:NotificationTemplates.ContainsKey($Name)) {
            $template = $script:NotificationTemplates[$Name]
            if ($Version -and $template.Version -ne $Version) {
                Write-Warning "Template version mismatch. Requested: $Version, Available: $($template.Version)"
            }
            return $template
        }
        else {
            Write-Warning "Template not found: $Name"
            return $null
        }
    }
    else {
        # Return all templates
        return $script:NotificationTemplates.Values
    }
}

function Test-NotificationTemplate {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Name,
        
        [Parameter()]
        [hashtable]$SampleData = @{}
    )
    
    Write-Verbose "Testing notification template: $Name"
    
    $template = Get-NotificationTemplate -Name $Name
    if (-not $template) {
        throw "Template not found: $Name"
    }
    
    $testResults = @{
        TemplateName = $Name
        EmailTest = $null
        WebhookTest = $null
        ValidationPassed = $false
        PreviewEmail = $null
        PreviewWebhook = $null
        Errors = @()
    }
    
    try {
        # Test email content formatting
        $emailContent = Format-ContentForChannel -Template $template -Channel 'Email' -Data $SampleData
        $testResults.EmailTest = $true
        $testResults.PreviewEmail = $emailContent
    }
    catch {
        $testResults.EmailTest = $false
        $testResults.Errors += "Email formatting error: $_"
    }
    
    try {
        # Test webhook content formatting
        $webhookContent = Format-ContentForChannel -Template $template -Channel 'Webhook' -Data $SampleData
        $testResults.WebhookTest = $true
        $testResults.PreviewWebhook = $webhookContent
    }
    catch {
        $testResults.WebhookTest = $false
        $testResults.Errors += "Webhook formatting error: $_"
    }
    
    $testResults.ValidationPassed = $testResults.EmailTest -and $testResults.WebhookTest
    
    Write-Verbose "Template test completed. Validation passed: $($testResults.ValidationPassed)"
    return $testResults
}

function Remove-NotificationTemplate {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Name,
        
        [Parameter()]
        [switch]$Force
    )
    
    Write-Verbose "Removing notification template: $Name"
    
    if (-not $script:NotificationTemplates.ContainsKey($Name)) {
        Write-Warning "Template not found: $Name"
        return
    }
    
    if (-not $Force) {
        $confirmation = Read-Host "Are you sure you want to remove template '$Name'? (Y/N)"
        if ($confirmation -ne 'Y') {
            Write-Verbose "Template removal cancelled"
            return
        }
    }
    
    $script:NotificationTemplates.Remove($Name)
    Write-Verbose "Successfully removed template: $Name"
}

function Export-NotificationTemplate {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path,
        
        [Parameter()]
        [string]$Name,
        
        [Parameter()]
        [switch]$IncludeComponents
    )
    
    Write-Verbose "Exporting notification templates to: $Path"
    
    $exportData = @{
        ExportDate = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
        ModuleVersion = $script:ModuleVersion
        Templates = @{}
    }
    
    if ($Name) {
        # Export specific template
        if ($script:NotificationTemplates.ContainsKey($Name)) {
            $exportData.Templates[$Name] = $script:NotificationTemplates[$Name]
        }
        else {
            throw "Template not found: $Name"
        }
    }
    else {
        # Export all templates
        $exportData.Templates = $script:NotificationTemplates
    }
    
    if ($IncludeComponents) {
        $exportData.Components = $script:TemplateComponents
    }
    
    # Convert to JSON and save
    $exportData | ConvertTo-Json -Depth 10 | Set-Content -Path $Path -Encoding UTF8
    
    Write-Verbose "Successfully exported $($exportData.Templates.Count) template(s)"
}

function Import-NotificationTemplate {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path,
        
        [Parameter()]
        [switch]$Overwrite,
        
        [Parameter()]
        [switch]$IncludeComponents
    )
    
    Write-Verbose "Importing notification templates from: $Path"
    
    if (-not (Test-Path $Path)) {
        throw "Import file not found: $Path"
    }
    
    $importData = Get-Content -Path $Path -Raw | ConvertFrom-Json
    
    $imported = 0
    $skipped = 0
    
    foreach ($templateName in $importData.Templates.PSObject.Properties.Name) {
        $template = $importData.Templates.$templateName
        
        if ($script:NotificationTemplates.ContainsKey($templateName) -and -not $Overwrite) {
            Write-Warning "Template already exists, skipping: $templateName"
            $skipped++
            continue
        }
        
        # Convert PSCustomObject back to hashtable
        $templateHash = @{}
        $template.PSObject.Properties | ForEach-Object {
            $templateHash[$_.Name] = $_.Value
        }
        
        $script:NotificationTemplates[$templateName] = $templateHash
        $imported++
    }
    
    if ($IncludeComponents -and $importData.Components) {
        foreach ($componentName in $importData.Components.PSObject.Properties.Name) {
            $component = $importData.Components.$componentName
            
            # Convert PSCustomObject back to hashtable
            $componentHash = @{}
            $component.PSObject.Properties | ForEach-Object {
                $componentHash[$_.Name] = $_.Value
            }
            
            $script:TemplateComponents[$componentName] = $componentHash
        }
    }
    
    Write-Verbose "Import complete. Imported: $imported, Skipped: $skipped"
    
    return @{
        Imported = $imported
        Skipped = $skipped
    }
}

#endregion Unified Template System

#region Template Components and Management (Hours 1-4)

function New-TemplateComponent {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Name,
        
        [Parameter(Mandatory = $true)]
        [string]$Content,
        
        [Parameter()]
        [string]$Type = 'Generic',
        
        [Parameter()]
        [hashtable]$Variables = @{},
        
        [Parameter()]
        [hashtable]$Metadata = @{}
    )
    
    Write-Verbose "Creating template component: $Name"
    
    $component = @{
        Name = $Name
        Content = $Content
        Type = $Type
        Variables = $Variables
        Metadata = $Metadata
        CreatedAt = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
        ModifiedAt = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
    }
    
    $script:TemplateComponents[$Name] = $component
    
    Write-Verbose "Successfully created component: $Name"
    return $component
}

function Get-TemplateComponent {
    [CmdletBinding()]
    param(
        [Parameter()]
        [string]$Name,
        
        [Parameter()]
        [string]$Type
    )
    
    if ($Name) {
        if ($script:TemplateComponents.ContainsKey($Name)) {
            return $script:TemplateComponents[$Name]
        }
        else {
            Write-Warning "Component not found: $Name"
            return $null
        }
    }
    elseif ($Type) {
        # Return components of specific type
        return $script:TemplateComponents.Values | Where-Object { $_.Type -eq $Type }
    }
    else {
        # Return all components
        return $script:TemplateComponents.Values
    }
}

function Set-TemplateComponent {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Name,
        
        [Parameter()]
        [string]$Content,
        
        [Parameter()]
        [string]$Type,
        
        [Parameter()]
        [hashtable]$Variables,
        
        [Parameter()]
        [hashtable]$Metadata
    )
    
    Write-Verbose "Updating template component: $Name"
    
    if (-not $script:TemplateComponents.ContainsKey($Name)) {
        throw "Component not found: $Name"
    }
    
    $component = $script:TemplateComponents[$Name]
    
    # Update provided fields
    if ($PSBoundParameters.ContainsKey('Content')) {
        $component.Content = $Content
    }
    if ($PSBoundParameters.ContainsKey('Type')) {
        $component.Type = $Type
    }
    if ($PSBoundParameters.ContainsKey('Variables')) {
        $component.Variables = $Variables
    }
    if ($PSBoundParameters.ContainsKey('Metadata')) {
        $component.Metadata = $Metadata
    }
    
    $component.ModifiedAt = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
    
    Write-Verbose "Successfully updated component: $Name"
    return $component
}

function Format-UnifiedNotificationContent {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$TemplateName,
        
        [Parameter(Mandatory = $true)]
        [ValidateSet('Email', 'Webhook')]
        [string]$Channel,
        
        [Parameter()]
        [hashtable]$Data = @{},
        
        [Parameter()]
        [string]$Severity = 'Info'
    )
    
    Write-Verbose "Formatting notification content for $Channel using template: $TemplateName"
    
    $template = Get-NotificationTemplate -Name $TemplateName
    if (-not $template) {
        throw "Template not found: $TemplateName"
    }
    
    # Merge template variables with provided data
    $mergedData = @{}
    foreach ($key in $template.Variables.Keys) {
        $mergedData[$key] = $template.Variables[$key]
    }
    foreach ($key in $Data.Keys) {
        $mergedData[$key] = $Data[$key]
    }
    
    # Add severity information
    $mergedData['Severity'] = $Severity
    $mergedData['Timestamp'] = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
    
    # Format content based on channel
    $formattedContent = Format-ContentForChannel -Template $template -Channel $Channel -Data $mergedData
    
    Write-Verbose "Successfully formatted content for $Channel"
    return $formattedContent
}

function Validate-NotificationContent {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [hashtable]$Content,
        
        [Parameter(Mandatory = $true)]
        [ValidateSet('Email', 'Webhook')]
        [string]$Channel
    )
    
    Write-Verbose "Validating notification content for $Channel"
    
    $validationResults = @{
        IsValid = $true
        Errors = @()
        Warnings = @()
    }
    
    if ($Channel -eq 'Email') {
        # Validate email content
        if (-not $Content.Subject) {
            $validationResults.Errors += "Email subject is required"
            $validationResults.IsValid = $false
        }
        if (-not $Content.Body) {
            $validationResults.Errors += "Email body is required"
            $validationResults.IsValid = $false
        }
        if ($Content.Subject -and $Content.Subject.Length -gt 255) {
            $validationResults.Warnings += "Email subject exceeds recommended length (255 characters)"
        }
    }
    elseif ($Channel -eq 'Webhook') {
        # Validate webhook content
        if (-not $Content.Payload) {
            $validationResults.Errors += "Webhook payload is required"
            $validationResults.IsValid = $false
        }
        
        # Check JSON validity if payload is string
        if ($Content.Payload -is [string]) {
            try {
                $null = $Content.Payload | ConvertFrom-Json
            }
            catch {
                $validationResults.Errors += "Invalid JSON in webhook payload"
                $validationResults.IsValid = $false
            }
        }
    }
    
    Write-Verbose "Validation complete. Is valid: $($validationResults.IsValid)"
    return $validationResults
}

function Preview-NotificationTemplate {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$TemplateName,
        
        [Parameter()]
        [hashtable]$SampleData = @{},
        
        [Parameter()]
        [string]$Severity = 'Info'
    )
    
    Write-Verbose "Generating preview for template: $TemplateName"
    
    if (-not $script:ContentEngineConfig.EnablePreview) {
        Write-Warning "Template preview is disabled in configuration"
        return $null
    }
    
    $preview = @{
        TemplateName = $TemplateName
        Severity = $Severity
        EmailPreview = $null
        WebhookPreview = $null
        GeneratedAt = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
    }
    
    try {
        # Generate email preview
        $emailContent = Format-UnifiedNotificationContent -TemplateName $TemplateName -Channel 'Email' -Data $SampleData -Severity $Severity
        $preview.EmailPreview = $emailContent
    }
    catch {
        Write-Warning "Failed to generate email preview: $_"
    }
    
    try {
        # Generate webhook preview
        $webhookContent = Format-UnifiedNotificationContent -TemplateName $TemplateName -Channel 'Webhook' -Data $SampleData -Severity $Severity
        $preview.WebhookPreview = $webhookContent
    }
    catch {
        Write-Warning "Failed to generate webhook preview: $_"
    }
    
    Write-Verbose "Preview generation complete"
    return $preview
}

#endregion Template Components and Management

#region Severity-Based Routing (Hours 5-8)

function New-NotificationRoutingRule {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Name,
        
        [Parameter(Mandatory = $true)]
        [ValidateSet('Critical', 'Error', 'Warning', 'Info')]
        [string]$Severity,
        
        [Parameter(Mandatory = $true)]
        [ValidateSet('Email', 'Webhook', 'Both')]
        [string[]]$Channels,
        
        [Parameter()]
        [hashtable]$Conditions = @{},
        
        [Parameter()]
        [int]$Priority = 0,
        
        [Parameter()]
        [hashtable]$Metadata = @{}
    )
    
    Write-Verbose "Creating notification routing rule: $Name"
    
    $rule = @{
        Name = $Name
        Severity = $Severity
        Channels = $Channels
        Conditions = $Conditions
        Priority = $Priority
        Metadata = $Metadata
        CreatedAt = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
        ModifiedAt = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
        Enabled = $true
    }
    
    $script:RoutingRules[$Name] = $rule
    
    Write-Verbose "Successfully created routing rule: $Name"
    return $rule
}

function Set-NotificationRouting {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Name,
        
        [Parameter()]
        [ValidateSet('Critical', 'Error', 'Warning', 'Info')]
        [string]$Severity,
        
        [Parameter()]
        [ValidateSet('Email', 'Webhook', 'Both')]
        [string[]]$Channels,
        
        [Parameter()]
        [hashtable]$Conditions,
        
        [Parameter()]
        [int]$Priority,
        
        [Parameter()]
        [bool]$Enabled
    )
    
    Write-Verbose "Updating notification routing rule: $Name"
    
    if (-not $script:RoutingRules.ContainsKey($Name)) {
        throw "Routing rule not found: $Name"
    }
    
    $rule = $script:RoutingRules[$Name]
    
    # Update provided fields
    if ($PSBoundParameters.ContainsKey('Severity')) {
        $rule.Severity = $Severity
    }
    if ($PSBoundParameters.ContainsKey('Channels')) {
        $rule.Channels = $Channels
    }
    if ($PSBoundParameters.ContainsKey('Conditions')) {
        $rule.Conditions = $Conditions
    }
    if ($PSBoundParameters.ContainsKey('Priority')) {
        $rule.Priority = $Priority
    }
    if ($PSBoundParameters.ContainsKey('Enabled')) {
        $rule.Enabled = $Enabled
    }
    
    $rule.ModifiedAt = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
    
    Write-Verbose "Successfully updated routing rule: $Name"
    return $rule
}

function Get-NotificationRouting {
    [CmdletBinding()]
    param(
        [Parameter()]
        [string]$Name,
        
        [Parameter()]
        [ValidateSet('Critical', 'Error', 'Warning', 'Info')]
        [string]$Severity,
        
        [Parameter()]
        [switch]$EnabledOnly
    )
    
    if ($Name) {
        if ($script:RoutingRules.ContainsKey($Name)) {
            return $script:RoutingRules[$Name]
        }
        else {
            Write-Warning "Routing rule not found: $Name"
            return $null
        }
    }
    else {
        $rules = $script:RoutingRules.Values
        
        if ($Severity) {
            $rules = $rules | Where-Object { $_.Severity -eq $Severity }
        }
        
        if ($EnabledOnly) {
            $rules = $rules | Where-Object { $_.Enabled -eq $true }
        }
        
        # Sort by priority (lower number = higher priority)
        return $rules | Sort-Object Priority
    }
}

function Invoke-SeverityBasedRouting {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateSet('Critical', 'Error', 'Warning', 'Info')]
        [string]$Severity,
        
        [Parameter()]
        [hashtable]$Context = @{}
    )
    
    Write-Verbose "Invoking severity-based routing for severity: $Severity"
    
    $selectedChannels = @()
    
    # Get applicable routing rules
    $rules = Get-NotificationRouting -Severity $Severity -EnabledOnly | Sort-Object Priority
    
    if ($rules.Count -eq 0) {
        # Use default channel mappings
        Write-Verbose "No custom rules found, using default mappings"
        $selectedChannels = $script:DefaultChannelMappings[$Severity]
    }
    else {
        # Apply first matching rule
        foreach ($rule in $rules) {
            $match = $true
            
            # Check conditions if any
            if ($rule.Conditions.Count -gt 0) {
                foreach ($condition in $rule.Conditions.GetEnumerator()) {
                    if (-not $Context.ContainsKey($condition.Key) -or $Context[$condition.Key] -ne $condition.Value) {
                        $match = $false
                        break
                    }
                }
            }
            
            if ($match) {
                $selectedChannels = $rule.Channels
                Write-Verbose "Applied routing rule: $($rule.Name)"
                break
            }
        }
        
        # Fallback to defaults if no rules matched
        if ($selectedChannels.Count -eq 0) {
            $selectedChannels = $script:DefaultChannelMappings[$Severity]
            Write-Verbose "No matching rules, using default mappings"
        }
    }
    
    # Convert 'Both' to actual channels
    if ($selectedChannels -contains 'Both') {
        $selectedChannels = @('Email', 'Webhook')
    }
    
    Write-Verbose "Selected channels: $($selectedChannels -join ', ')"
    return $selectedChannels
}

function Test-NotificationRouting {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateSet('Critical', 'Error', 'Warning', 'Info')]
        [string]$Severity,
        
        [Parameter()]
        [hashtable]$Context = @{},
        
        [Parameter()]
        [switch]$ShowDetails
    )
    
    Write-Verbose "Testing notification routing for severity: $Severity"
    
    $testResult = @{
        Severity = $Severity
        Context = $Context
        SelectedChannels = @()
        AppliedRule = $null
        DefaultUsed = $false
    }
    
    # Get channels through routing
    $channels = Invoke-SeverityBasedRouting -Severity $Severity -Context $Context
    $testResult.SelectedChannels = $channels
    
    # Determine which rule was applied
    $rules = Get-NotificationRouting -Severity $Severity -EnabledOnly | Sort-Object Priority
    
    foreach ($rule in $rules) {
        $match = $true
        
        if ($rule.Conditions.Count -gt 0) {
            foreach ($condition in $rule.Conditions.GetEnumerator()) {
                if (-not $Context.ContainsKey($condition.Key) -or $Context[$condition.Key] -ne $condition.Value) {
                    $match = $false
                    break
                }
            }
        }
        
        if ($match) {
            $testResult.AppliedRule = $rule.Name
            break
        }
    }
    
    if (-not $testResult.AppliedRule) {
        $testResult.DefaultUsed = $true
    }
    
    if ($ShowDetails) {
        Write-Host "Routing Test Results:"
        Write-Host "  Severity: $Severity"
        Write-Host "  Channels: $($channels -join ', ')"
        if ($testResult.AppliedRule) {
            Write-Host "  Applied Rule: $($testResult.AppliedRule)"
        }
        else {
            Write-Host "  Applied Rule: Default Mapping"
        }
    }
    
    return $testResult
}

#endregion Severity-Based Routing

#region Channel Selection and Management (Hours 5-8)

function Select-NotificationChannels {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateSet('Critical', 'Error', 'Warning', 'Info')]
        [string]$Severity,
        
        [Parameter()]
        [hashtable]$Context = @{},
        
        [Parameter()]
        [string[]]$PreferredChannels = @(),
        
        [Parameter()]
        [switch]$ApplyThrottling
    )
    
    Write-Verbose "Selecting notification channels for severity: $Severity"
    
    # Get channels based on severity routing
    $routedChannels = Invoke-SeverityBasedRouting -Severity $Severity -Context $Context
    
    # Apply channel preferences if specified
    if ($PreferredChannels.Count -gt 0) {
        $selectedChannels = $routedChannels | Where-Object { $_ -in $PreferredChannels }
        
        if ($selectedChannels.Count -eq 0) {
            Write-Warning "No preferred channels match routing rules, using all routed channels"
            $selectedChannels = $routedChannels
        }
    }
    else {
        $selectedChannels = $routedChannels
    }
    
    # Apply throttling if requested
    if ($ApplyThrottling) {
        $throttledChannels = @()
        foreach ($channel in $selectedChannels) {
            if (Test-ChannelThrottling -Channel $channel -Severity $Severity) {
                $throttledChannels += $channel
            }
            else {
                Write-Verbose "Channel $channel throttled for severity $Severity"
            }
        }
        $selectedChannels = $throttledChannels
    }
    
    Write-Verbose "Selected channels: $($selectedChannels -join ', ')"
    return $selectedChannels
}

function New-ChannelPreferences {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Name,
        
        [Parameter(Mandatory = $true)]
        [string[]]$PreferredChannels,
        
        [Parameter()]
        [hashtable]$SeverityOverrides = @{},
        
        [Parameter()]
        [hashtable]$Metadata = @{}
    )
    
    Write-Verbose "Creating channel preferences: $Name"
    
    $preferences = @{
        Name = $Name
        PreferredChannels = $PreferredChannels
        SeverityOverrides = $SeverityOverrides
        Metadata = $Metadata
        CreatedAt = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
        ModifiedAt = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
        Enabled = $true
    }
    
    $script:ChannelPreferences[$Name] = $preferences
    
    Write-Verbose "Successfully created channel preferences: $Name"
    return $preferences
}

function Set-ChannelPreferences {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Name,
        
        [Parameter()]
        [string[]]$PreferredChannels,
        
        [Parameter()]
        [hashtable]$SeverityOverrides,
        
        [Parameter()]
        [bool]$Enabled
    )
    
    Write-Verbose "Updating channel preferences: $Name"
    
    if (-not $script:ChannelPreferences.ContainsKey($Name)) {
        throw "Channel preferences not found: $Name"
    }
    
    $preferences = $script:ChannelPreferences[$Name]
    
    # Update provided fields
    if ($PSBoundParameters.ContainsKey('PreferredChannels')) {
        $preferences.PreferredChannels = $PreferredChannels
    }
    if ($PSBoundParameters.ContainsKey('SeverityOverrides')) {
        $preferences.SeverityOverrides = $SeverityOverrides
    }
    if ($PSBoundParameters.ContainsKey('Enabled')) {
        $preferences.Enabled = $Enabled
    }
    
    $preferences.ModifiedAt = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
    
    Write-Verbose "Successfully updated channel preferences: $Name"
    return $preferences
}

function Get-ChannelPreferences {
    [CmdletBinding()]
    param(
        [Parameter()]
        [string]$Name,
        
        [Parameter()]
        [switch]$EnabledOnly
    )
    
    if ($Name) {
        if ($script:ChannelPreferences.ContainsKey($Name)) {
            return $script:ChannelPreferences[$Name]
        }
        else {
            Write-Warning "Channel preferences not found: $Name"
            return $null
        }
    }
    else {
        $preferences = $script:ChannelPreferences.Values
        
        if ($EnabledOnly) {
            $preferences = $preferences | Where-Object { $_.Enabled -eq $true }
        }
        
        return $preferences
    }
}

function Invoke-ChannelSelection {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateSet('Critical', 'Error', 'Warning', 'Info')]
        [string]$Severity,
        
        [Parameter()]
        [string]$PreferenceName,
        
        [Parameter()]
        [hashtable]$Context = @{}
    )
    
    Write-Verbose "Invoking channel selection with severity: $Severity"
    
    $preferredChannels = @()
    
    # Get preferences if specified
    if ($PreferenceName) {
        $preferences = Get-ChannelPreferences -Name $PreferenceName
        if ($preferences -and $preferences.Enabled) {
            # Check for severity-specific overrides
            if ($preferences.SeverityOverrides.ContainsKey($Severity)) {
                $preferredChannels = $preferences.SeverityOverrides[$Severity]
            }
            else {
                $preferredChannels = $preferences.PreferredChannels
            }
        }
    }
    
    # Select channels with preferences applied
    $selectedChannels = Select-NotificationChannels -Severity $Severity -Context $Context -PreferredChannels $preferredChannels
    
    Write-Verbose "Final channel selection: $($selectedChannels -join ', ')"
    return $selectedChannels
}

#endregion Channel Selection and Management

#region Notification Processing and Delivery (Hours 5-8)

function Send-UnifiedNotification {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$TemplateName,
        
        [Parameter(Mandatory = $true)]
        [ValidateSet('Critical', 'Error', 'Warning', 'Info')]
        [string]$Severity,
        
        [Parameter()]
        [hashtable]$Data = @{},
        
        [Parameter()]
        [string]$PreferenceName,
        
        [Parameter()]
        [switch]$ApplyThrottling,
        
        [Parameter()]
        [switch]$TestMode
    )
    
    Write-Verbose "Sending unified notification with template: $TemplateName, Severity: $Severity"
    
    $notificationResult = @{
        TemplateName = $TemplateName
        Severity = $Severity
        Channels = @()
        EmailStatus = $null
        WebhookStatus = $null
        Timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
        Success = $false
        Errors = @()
    }
    
    try {
        # Select channels based on severity and preferences
        $channels = Invoke-ChannelSelection -Severity $Severity -PreferenceName $PreferenceName -Context $Data
        $notificationResult.Channels = $channels
        
        # Apply throttling if requested
        if ($ApplyThrottling) {
            $throttledChannels = @()
            foreach ($channel in $channels) {
                if (Test-ChannelThrottling -Channel $channel -Severity $Severity) {
                    $throttledChannels += $channel
                }
            }
            $channels = $throttledChannels
        }
        
        if ($channels.Count -eq 0) {
            Write-Warning "No channels selected for notification"
            $notificationResult.Errors += "No channels selected due to routing or throttling"
            return $notificationResult
        }
        
        # Format content for each channel
        foreach ($channel in $channels) {
            $content = Format-UnifiedNotificationContent -TemplateName $TemplateName -Channel $channel -Data $Data -Severity $Severity
            
            if ($TestMode) {
                Write-Host "TEST MODE - Would send to ${channel}:"
                Write-Host ($content | ConvertTo-Json -Depth 3)
                
                if ($channel -eq 'Email') {
                    $notificationResult.EmailStatus = 'TestMode'
                }
                elseif ($channel -eq 'Webhook') {
                    $notificationResult.WebhookStatus = 'TestMode'
                }
            }
            else {
                # Actual delivery would integrate with email/webhook modules here
                # For now, we'll simulate successful delivery
                if ($channel -eq 'Email') {
                    Write-Verbose "Sending email notification..."
                    # Integration point: Call Send-EmailNotification from email module
                    $notificationResult.EmailStatus = 'Sent'
                }
                elseif ($channel -eq 'Webhook') {
                    Write-Verbose "Sending webhook notification..."
                    # Integration point: Call Send-WebhookNotification from webhook module
                    $notificationResult.WebhookStatus = 'Sent'
                }
            }
        }
        
        $notificationResult.Success = $true
        
        # Add to history
        Add-NotificationHistory -Result $notificationResult
    }
    catch {
        $notificationResult.Errors += $_.Exception.Message
        Write-Error "Failed to send notification: $_"
    }
    
    return $notificationResult
}

function Invoke-NotificationDelivery {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [hashtable]$Content,
        
        [Parameter(Mandatory = $true)]
        [ValidateSet('Email', 'Webhook')]
        [string]$Channel,
        
        [Parameter()]
        [hashtable]$DeliveryOptions = @{}
    )
    
    Write-Verbose "Delivering notification via $Channel"
    
    $deliveryResult = @{
        Channel = $Channel
        Status = 'Pending'
        Timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
        Error = $null
    }
    
    try {
        if ($Channel -eq 'Email') {
            # Integration with email module
            # This would call the actual email sending function
            Write-Verbose "Email delivery simulation"
            $deliveryResult.Status = 'Delivered'
        }
        elseif ($Channel -eq 'Webhook') {
            # Integration with webhook module
            # This would call the actual webhook sending function
            Write-Verbose "Webhook delivery simulation"
            $deliveryResult.Status = 'Delivered'
        }
    }
    catch {
        $deliveryResult.Status = 'Failed'
        $deliveryResult.Error = $_.Exception.Message
        Write-Error "Delivery failed: $_"
    }
    
    return $deliveryResult
}

function Get-NotificationStatus {
    [CmdletBinding()]
    param(
        [Parameter()]
        [int]$LastN = 10,
        
        [Parameter()]
        [ValidateSet('Critical', 'Error', 'Warning', 'Info')]
        [string]$Severity,
        
        [Parameter()]
        [ValidateSet('Email', 'Webhook')]
        [string]$Channel
    )
    
    Write-Verbose "Getting notification status (Last $LastN)"
    
    $history = $script:NotificationHistory
    
    if ($Severity) {
        $history = $history | Where-Object { $_.Severity -eq $Severity }
    }
    
    if ($Channel) {
        $history = $history | Where-Object { $Channel -in $_.Channels }
    }
    
    # Get last N items
    if ($history.Count -gt $LastN) {
        $history = $history[-$LastN..-1]
    }
    
    return $history
}

function Get-NotificationAnalytics {
    [CmdletBinding()]
    param(
        [Parameter()]
        [datetime]$StartDate,
        
        [Parameter()]
        [datetime]$EndDate = (Get-Date)
    )
    
    Write-Verbose "Generating notification analytics"
    
    if (-not $StartDate) {
        $StartDate = (Get-Date).AddDays(-7)
    }
    
    $analytics = @{
        Period = @{
            Start = $StartDate.ToString('yyyy-MM-dd HH:mm:ss')
            End = $EndDate.ToString('yyyy-MM-dd HH:mm:ss')
        }
        TotalNotifications = 0
        BySeverity = @{}
        ByChannel = @{}
        SuccessRate = 0
        Errors = @()
    }
    
    # Filter history by date range
    $filteredHistory = $script:NotificationHistory | Where-Object {
        $timestamp = [datetime]::Parse($_.Timestamp)
        $timestamp -ge $StartDate -and $timestamp -le $EndDate
    }
    
    $analytics.TotalNotifications = $filteredHistory.Count
    
    if ($filteredHistory.Count -gt 0) {
        # Group by severity
        $filteredHistory | Group-Object Severity | ForEach-Object {
            $analytics.BySeverity[$_.Name] = $_.Count
        }
        
        # Count by channel
        $emailCount = ($filteredHistory | Where-Object { 'Email' -in $_.Channels }).Count
        $webhookCount = ($filteredHistory | Where-Object { 'Webhook' -in $_.Channels }).Count
        $analytics.ByChannel['Email'] = $emailCount
        $analytics.ByChannel['Webhook'] = $webhookCount
        
        # Calculate success rate
        $successCount = ($filteredHistory | Where-Object { $_.Success -eq $true }).Count
        $analytics.SuccessRate = [math]::Round(($successCount / $filteredHistory.Count) * 100, 2)
        
        # Collect unique errors
        $analytics.Errors = $filteredHistory | Where-Object { $_.Errors.Count -gt 0 } | ForEach-Object { $_.Errors } | Select-Object -Unique
    }
    
    return $analytics
}

#endregion Notification Processing and Delivery

#region Content Engine Configuration

function Initialize-NotificationContentEngine {
    [CmdletBinding()]
    param(
        [Parameter()]
        [hashtable]$Configuration = @{}
    )
    
    Write-Verbose "Initializing Notification Content Engine"
    
    # Apply custom configuration
    foreach ($key in $Configuration.Keys) {
        if ($script:ContentEngineConfig.ContainsKey($key)) {
            $script:ContentEngineConfig[$key] = $Configuration[$key]
        }
    }
    
    # Initialize default routing rules if none exist
    if ($script:RoutingRules.Count -eq 0) {
        Write-Verbose "Creating default routing rules"
        
        # Critical severity
        New-NotificationRoutingRule -Name 'Default-Critical' -Severity 'Critical' -Channels 'Both' -Priority 100
        
        # Error severity
        New-NotificationRoutingRule -Name 'Default-Error' -Severity 'Error' -Channels 'Both' -Priority 100
        
        # Warning severity
        New-NotificationRoutingRule -Name 'Default-Warning' -Severity 'Warning' -Channels 'Email' -Priority 100
        
        # Info severity
        New-NotificationRoutingRule -Name 'Default-Info' -Severity 'Info' -Channels 'Webhook' -Priority 100
    }
    
    Write-Verbose "Notification Content Engine initialized"
    
    return @{
        Configuration = $script:ContentEngineConfig
        Templates = $script:NotificationTemplates.Count
        Components = $script:TemplateComponents.Count
        RoutingRules = $script:RoutingRules.Count
        Preferences = $script:ChannelPreferences.Count
    }
}

function Get-ContentEngineConfiguration {
    [CmdletBinding()]
    param()
    
    return $script:ContentEngineConfig
}

function Set-ContentEngineConfiguration {
    [CmdletBinding()]
    param(
        [Parameter()]
        [int]$MaxHistoryItems,
        
        [Parameter()]
        [int]$ThrottleWindowMinutes,
        
        [Parameter()]
        [ValidateSet('Critical', 'Error', 'Warning', 'Info')]
        [string]$DefaultSeverity,
        
        [Parameter()]
        [bool]$EnablePreview,
        
        [Parameter()]
        [bool]$EnableValidation,
        
        [Parameter()]
        [string]$TemplateVersion
    )
    
    Write-Verbose "Updating Content Engine configuration"
    
    if ($PSBoundParameters.ContainsKey('MaxHistoryItems')) {
        $script:ContentEngineConfig.MaxHistoryItems = $MaxHistoryItems
    }
    if ($PSBoundParameters.ContainsKey('ThrottleWindowMinutes')) {
        $script:ContentEngineConfig.ThrottleWindowMinutes = $ThrottleWindowMinutes
    }
    if ($PSBoundParameters.ContainsKey('DefaultSeverity')) {
        $script:ContentEngineConfig.DefaultSeverity = $DefaultSeverity
    }
    if ($PSBoundParameters.ContainsKey('EnablePreview')) {
        $script:ContentEngineConfig.EnablePreview = $EnablePreview
    }
    if ($PSBoundParameters.ContainsKey('EnableValidation')) {
        $script:ContentEngineConfig.EnableValidation = $EnableValidation
    }
    if ($PSBoundParameters.ContainsKey('TemplateVersion')) {
        $script:ContentEngineConfig.TemplateVersion = $TemplateVersion
    }
    
    Write-Verbose "Configuration updated"
    return $script:ContentEngineConfig
}

#endregion Content Engine Configuration

#region Helper Functions

function Test-TemplateStructure {
    param([hashtable]$Template)
    
    $required = @('Name', 'EmailContent', 'WebhookContent')
    foreach ($field in $required) {
        if (-not $Template.ContainsKey($field)) {
            Write-Warning "Template missing required field: $field"
            return $false
        }
    }
    
    if ($script:ContentEngineConfig.EnableValidation) {
        # Validate email content
        $emailValidation = Validate-NotificationContent -Content $Template.EmailContent -Channel 'Email'
        if (-not $emailValidation.IsValid) {
            Write-Warning "Email content validation failed: $($emailValidation.Errors -join ', ')"
            return $false
        }
        
        # Validate webhook content
        $webhookValidation = Validate-NotificationContent -Content $Template.WebhookContent -Channel 'Webhook'
        if (-not $webhookValidation.IsValid) {
            Write-Warning "Webhook content validation failed: $($webhookValidation.Errors -join ', ')"
            return $false
        }
    }
    
    return $true
}

function Format-ContentForChannel {
    param(
        [hashtable]$Template,
        [string]$Channel,
        [hashtable]$Data
    )
    
    if ($Channel -eq 'Email') {
        $content = $Template.EmailContent.Clone()
        
        # Replace variables in subject and body
        foreach ($key in $Data.Keys) {
            if ($content.Subject) {
                $content.Subject = $content.Subject -replace "{$key}", $Data[$key]
            }
            if ($content.Body) {
                $content.Body = $content.Body -replace "{$key}", $Data[$key]
            }
        }
        
        # Process template components if any
        if ($Template.Components.Count -gt 0) {
            foreach ($componentName in $Template.Components) {
                $component = Get-TemplateComponent -Name $componentName
                if ($component) {
                    $componentContent = $component.Content
                    foreach ($key in $Data.Keys) {
                        $componentContent = $componentContent -replace "{$key}", $Data[$key]
                    }
                    $content.Body = $content.Body -replace "{Component:$componentName}", $componentContent
                }
            }
        }
    }
    elseif ($Channel -eq 'Webhook') {
        $content = $Template.WebhookContent.Clone()
        
        # Process payload template
        if ($content.Payload -is [string]) {
            foreach ($key in $Data.Keys) {
                $content.Payload = $content.Payload -replace "{$key}", $Data[$key]
            }
        }
        elseif ($content.Payload -is [hashtable]) {
            $content.Payload = Process-HashTableVariables -HashTable $content.Payload -Data $Data
        }
    }
    
    return $content
}

function Process-HashTableVariables {
    param(
        [hashtable]$HashTable,
        [hashtable]$Data
    )
    
    $processed = @{}
    
    foreach ($key in $HashTable.Keys) {
        $value = $HashTable[$key]
        
        if ($value -is [string]) {
            foreach ($dataKey in $Data.Keys) {
                $value = $value -replace "{$dataKey}", $Data[$dataKey]
            }
            $processed[$key] = $value
        }
        elseif ($value -is [hashtable]) {
            $processed[$key] = Process-HashTableVariables -HashTable $value -Data $Data
        }
        else {
            $processed[$key] = $value
        }
    }
    
    return $processed
}

function Test-ChannelThrottling {
    param(
        [string]$Channel,
        [string]$Severity
    )
    
    # Simple throttling check based on recent history
    $throttleWindow = (Get-Date).AddMinutes(-$script:ContentEngineConfig.ThrottleWindowMinutes)
    
    $recentNotifications = $script:NotificationHistory | Where-Object {
        $timestamp = [datetime]::Parse($_.Timestamp)
        $timestamp -gt $throttleWindow -and
        $_.Severity -eq $Severity -and
        $Channel -in $_.Channels
    }
    
    # Allow Critical always, throttle others if more than 3 in window
    if ($Severity -eq 'Critical') {
        return $true
    }
    
    if ($recentNotifications.Count -ge 3) {
        return $false
    }
    
    return $true
}

function Add-NotificationHistory {
    param([hashtable]$Result)
    
    $script:NotificationHistory += $Result
    
    # Trim history if exceeds max
    if ($script:NotificationHistory.Count -gt $script:ContentEngineConfig.MaxHistoryItems) {
        $excess = $script:NotificationHistory.Count - $script:ContentEngineConfig.MaxHistoryItems
        $script:NotificationHistory = $script:NotificationHistory[$excess..($script:NotificationHistory.Count - 1)]
    }
}

#endregion Helper Functions

# Export module members
Export-ModuleMember -Function @(
    'New-UnifiedNotificationTemplate',
    'Set-NotificationTemplate',
    'Get-NotificationTemplate',
    'Test-NotificationTemplate',
    'Remove-NotificationTemplate',
    'Export-NotificationTemplate',
    'Import-NotificationTemplate',
    'New-TemplateComponent',
    'Get-TemplateComponent',
    'Set-TemplateComponent',
    'Format-UnifiedNotificationContent',
    'Validate-NotificationContent',
    'Preview-NotificationTemplate',
    'New-NotificationRoutingRule',
    'Set-NotificationRouting',
    'Get-NotificationRouting',
    'Invoke-SeverityBasedRouting',
    'Test-NotificationRouting',
    'Select-NotificationChannels',
    'New-ChannelPreferences',
    'Set-ChannelPreferences',
    'Get-ChannelPreferences',
    'Invoke-ChannelSelection',
    'Send-UnifiedNotification',
    'Invoke-NotificationDelivery',
    'Get-NotificationStatus',
    'Get-NotificationAnalytics',
    'Initialize-NotificationContentEngine',
    'Get-ContentEngineConfiguration',
    'Set-ContentEngineConfiguration'
)

Write-Verbose "Unity-Claude-NotificationContentEngine module loaded successfully"
# SIG # Begin signature block
# MIIFqQYJKoZIhvcNAQcCoIIFmjCCBZYCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUbGEjw9HTlNMRCt+M9BxromLb
# MYugggMwMIIDLDCCAhSgAwIBAgIQdR0W2SKoK5VE8JId4ZxrRTANBgkqhkiG9w0B
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
# CQQxFgQU31yfU0ADMi2SU4Nzm/L7NQ7TqxYwDQYJKoZIhvcNAQEBBQAEggEArFVZ
# QMkSiD2I7RQF9u4SMQPRgWMW/3DR8rD89U9hKeyow8igW5TU/pepP9vYx0nChXNF
# r5Ru75KESgNfxUH9vZ/j6uHfgKiV4guZgNdZqm2tIosdda4rEi4vRaGqrz5X/qqz
# EWGEn6YXW9X+CFqxHC/4Sz2MzkLIa3tG4FTnCur+CNex7wNHaZ2aNRIIqiJL9vAR
# e0iua/onAft7Ly6BHLdGiDYpWlUrtiVeXbIZl07U2Bgc6EsTDXx9acjrpwftsPxw
# DWfboxSsBCUHO8j+KdexmTfxSkHxU9WUyiPu2PzofeOVUkVwtrHrEIqSseNc9xKu
# 0qSJVFg1s+d06t4HYQ==
# SIG # End signature block
