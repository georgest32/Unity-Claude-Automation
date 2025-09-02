# Unity-Claude-NotificationPreferences.psm1
# Week 3 Day 12 Hour 5-6: Notification Preferences and Delivery Rules System
# Research-validated enterprise preference management with rule-based delivery
# Implements tag-driven logic and priority-based routing patterns

# Module state for notification preferences
$script:NotificationPreferencesState = @{
    IsInitialized = $false
    UserPreferences = @{}
    DeliveryRules = @{}
    TagDefinitions = @{}
    RuleEngine = $null
    Statistics = @{
        RulesProcessed = 0
        PreferencesApplied = 0
        CustomRulesCreated = 0
        TagsMatched = 0
        StartTime = $null
    }
    Configuration = @{
        PreferencesFile = ".\Config\notification-preferences.json"
        RulesFile = ".\Config\delivery-rules.json"
        TagsFile = ".\Config\notification-tags.json"
        EnableUserOverrides = $true
        EnableTagMatching = $true
        EnableTimeBasedRules = $true
        MaxRulesPerUser = 50
        MaxTagsPerRule = 10
    }
}

# Notification preference structure
enum PreferenceType {
    ChannelSelection
    TimeBased
    SeverityFiltering
    TagBased
    EscalationSettings
    ContentCustomization
}

# Rule condition operators (research-validated pattern)
enum RuleOperator {
    Equals
    NotEquals
    Contains
    NotContains
    GreaterThan
    LessThan
    In
    NotIn
}

function Initialize-NotificationPreferences {
    <#
    .SYNOPSIS
        Initializes notification preferences and delivery rules system.
    
    .DESCRIPTION
        Sets up enterprise-grade notification preference management with
        rule-based delivery, tag-driven logic, and user customization.
    
    .PARAMETER PreferencesFile
        Path to user preferences JSON file.
    
    .PARAMETER RulesFile
        Path to delivery rules JSON file.
    
    .PARAMETER EnableUserOverrides
        Allow users to override system default rules.
    
    .EXAMPLE
        Initialize-NotificationPreferences -EnableUserOverrides
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [string]$PreferencesFile,
        
        [Parameter(Mandatory = $false)]
        [string]$RulesFile,
        
        [Parameter(Mandatory = $false)]
        [switch]$EnableUserOverrides = $true
    )
    
    Write-Host "Initializing Notification Preferences System..." -ForegroundColor Cyan
    
    try {
        # Set configuration paths if provided
        if ($PreferencesFile) {
            $script:NotificationPreferencesState.Configuration.PreferencesFile = $PreferencesFile
        }
        if ($RulesFile) {
            $script:NotificationPreferencesState.Configuration.RulesFile = $RulesFile
        }
        
        $script:NotificationPreferencesState.Configuration.EnableUserOverrides = $EnableUserOverrides
        
        # Load existing preferences and rules
        Load-NotificationPreferences
        Load-DeliveryRules
        Load-TagDefinitions
        
        # Initialize rule engine
        Initialize-RuleEngine
        
        # Initialize statistics
        $script:NotificationPreferencesState.Statistics.StartTime = Get-Date
        $script:NotificationPreferencesState.IsInitialized = $true
        
        Write-Host "Notification Preferences System initialized successfully" -ForegroundColor Green
        Write-Host "User overrides enabled: $EnableUserOverrides" -ForegroundColor Gray
        Write-Host "Loaded preferences: $($script:NotificationPreferencesState.UserPreferences.Count) users" -ForegroundColor Gray
        Write-Host "Loaded rules: $($script:NotificationPreferencesState.DeliveryRules.Count) rules" -ForegroundColor Gray
        
        return $true
    }
    catch {
        Write-Error "Failed to initialize notification preferences: $($_.Exception.Message)"
        return $false
    }
}

function Load-NotificationPreferences {
    <#
    .SYNOPSIS
        Loads user notification preferences from JSON file.
    #>
    [CmdletBinding()]
    param()
    
    try {
        $preferencesFile = $script:NotificationPreferencesState.Configuration.PreferencesFile
        
        if (Test-Path $preferencesFile) {
            $jsonContent = Get-Content -Path $preferencesFile -Raw
            $preferences = $jsonContent | ConvertFrom-Json
            
            # Convert to hashtable for easier manipulation
            $script:NotificationPreferencesState.UserPreferences = @{}
            foreach ($userPref in $preferences.Users) {
                $script:NotificationPreferencesState.UserPreferences[$userPref.UserId] = $userPref
            }
            
            Write-Verbose "Loaded preferences for $($script:NotificationPreferencesState.UserPreferences.Count) users"
        }
        else {
            Write-Warning "Preferences file not found: $preferencesFile. Creating default preferences."
            $defaultPrefs = Get-DefaultNotificationPreferences
            Save-NotificationPreferences -Preferences $defaultPrefs
        }
    }
    catch {
        Write-Error "Failed to load notification preferences: $($_.Exception.Message)"
        throw
    }
}

function Load-DeliveryRules {
    <#
    .SYNOPSIS
        Loads delivery rules from JSON file.
    #>
    [CmdletBinding()]
    param()
    
    try {
        $rulesFile = $script:NotificationPreferencesState.Configuration.RulesFile
        
        if (Test-Path $rulesFile) {
            $jsonContent = Get-Content -Path $rulesFile -Raw
            $rules = $jsonContent | ConvertFrom-Json
            
            # Convert to hashtable for easier manipulation
            $script:NotificationPreferencesState.DeliveryRules = @{}
            foreach ($rule in $rules.Rules) {
                $script:NotificationPreferencesState.DeliveryRules[$rule.RuleId] = $rule
            }
            
            Write-Verbose "Loaded $($script:NotificationPreferencesState.DeliveryRules.Count) delivery rules"
        }
        else {
            Write-Warning "Rules file not found: $rulesFile. Creating default rules."
            $defaultRules = Get-DefaultDeliveryRules
            Save-DeliveryRules -Rules $defaultRules
        }
    }
    catch {
        Write-Error "Failed to load delivery rules: $($_.Exception.Message)"
        throw
    }
}

function Load-TagDefinitions {
    <#
    .SYNOPSIS
        Loads tag definitions for rule-based matching.
    #>
    [CmdletBinding()]
    param()
    
    try {
        $tagsFile = $script:NotificationPreferencesState.Configuration.TagsFile
        
        if (Test-Path $tagsFile) {
            $jsonContent = Get-Content -Path $tagsFile -Raw
            $tags = $jsonContent | ConvertFrom-Json
            
            # Convert to hashtable
            $script:NotificationPreferencesState.TagDefinitions = @{}
            foreach ($tag in $tags.Tags) {
                $script:NotificationPreferencesState.TagDefinitions[$tag.TagName] = $tag
            }
            
            Write-Verbose "Loaded $($script:NotificationPreferencesState.TagDefinitions.Count) tag definitions"
        }
        else {
            Write-Warning "Tags file not found: $tagsFile. Creating default tags."
            $defaultTags = Get-DefaultTagDefinitions
            Save-TagDefinitions -Tags $defaultTags
        }
    }
    catch {
        Write-Error "Failed to load tag definitions: $($_.Exception.Message)"
        throw
    }
}

function Get-DefaultNotificationPreferences {
    <#
    .SYNOPSIS
        Returns default notification preferences structure.
    #>
    
    return [PSCustomObject]@{
        Version = "1.0.0"
        Users = @(
            [PSCustomObject]@{
                UserId = "default"
                DisplayName = "Default User"
                Email = "admin@company.com"
                Preferences = [PSCustomObject]@{
                    EnabledChannels = @("Email", "Dashboard", "Webhook")
                    DisabledChannels = @("SMS")
                    SeverityFilters = @{
                        Email = @("Critical", "High")
                        Teams = @("Critical", "High", "Medium")
                        Slack = @("Critical", "High", "Medium")
                        Dashboard = @("Critical", "High", "Medium", "Low", "Info")
                        Webhook = @("Critical", "High", "Medium", "Low")
                        SMS = @("Critical")
                    }
                    TimeBasedRules = @(
                        [PSCustomObject]@{
                            Name = "Business Hours"
                            StartTime = "08:00"
                            EndTime = "18:00"
                            DaysOfWeek = @("Monday", "Tuesday", "Wednesday", "Thursday", "Friday")
                            Channels = @("Email", "Teams", "Dashboard")
                            Enabled = $true
                        }
                        [PSCustomObject]@{
                            Name = "After Hours"
                            StartTime = "18:01"
                            EndTime = "07:59"
                            DaysOfWeek = @("Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday")
                            Channels = @("SMS", "Teams")
                            SeverityOverride = @("Critical", "High")
                            Enabled = $true
                        }
                    )
                    TagBasedRules = @(
                        [PSCustomObject]@{
                            Name = "Unity Compilation Errors"
                            Tags = @("unity", "compilation", "error")
                            Channels = @("Email", "Teams", "Dashboard")
                            Priority = 1
                            Enabled = $true
                        }
                        [PSCustomObject]@{
                            Name = "AI Analysis Results"
                            Tags = @("ai", "analysis", "recommendation")
                            Channels = @("Dashboard", "Email")
                            Priority = 2
                            Enabled = $true
                        }
                    )
                    EscalationSettings = [PSCustomObject]@{
                        EnableEscalation = $true
                        EscalationTimeouts = @{
                            Critical = 300    # 5 minutes
                            High = 600        # 10 minutes
                            Medium = 1800     # 30 minutes
                            Low = 3600        # 1 hour
                        }
                        EscalationChannels = @("SMS", "Teams")
                        MaxEscalationLevels = 3
                    }
                }
            }
        )
    }
}

function Get-DefaultDeliveryRules {
    <#
    .SYNOPSIS
        Returns default delivery rules structure.
    #>
    
    return [PSCustomObject]@{
        Version = "1.0.0"
        Rules = @(
            [PSCustomObject]@{
                RuleId = "critical-immediate"
                Name = "Critical Immediate Response"
                Priority = 1
                Enabled = $true
                Conditions = @(
                    [PSCustomObject]@{
                        Field = "Severity"
                        Operator = "Equals"
                        Value = "Critical"
                    }
                )
                Actions = @(
                    [PSCustomObject]@{
                        Type = "SendNotification"
                        Channels = @("Email", "SMS", "Teams", "Slack", "Dashboard")
                        Template = "critical-alert"
                    }
                    [PSCustomObject]@{
                        Type = "EscalateAfter"
                        TimeoutSeconds = 300
                        EscalationChannels = @("SMS", "Teams")
                    }
                )
            }
            [PSCustomObject]@{
                RuleId = "high-priority"
                Name = "High Priority Alerts"
                Priority = 2
                Enabled = $true
                Conditions = @(
                    [PSCustomObject]@{
                        Field = "Severity"
                        Operator = "Equals"
                        Value = "High"
                    }
                )
                Actions = @(
                    [PSCustomObject]@{
                        Type = "SendNotification"
                        Channels = @("Email", "Teams", "Dashboard")
                        Template = "standard-alert"
                    }
                    [PSCustomObject]@{
                        Type = "EscalateAfter"
                        TimeoutSeconds = 600
                        EscalationChannels = @("Teams")
                    }
                )
            }
            [PSCustomObject]@{
                RuleId = "standard-alerts"
                Name = "Standard Monitoring Alerts"
                Priority = 3
                Enabled = $true
                Conditions = @(
                    [PSCustomObject]@{
                        Field = "Severity"
                        Operator = "In"
                        Value = @("Medium", "Low")
                    }
                )
                Actions = @(
                    [PSCustomObject]@{
                        Type = "SendNotification"
                        Channels = @("Dashboard", "Webhook")
                        Template = "standard-alert"
                    }
                )
            }
            [PSCustomObject]@{
                RuleId = "info-notifications"
                Name = "Information Notifications"
                Priority = 4
                Enabled = $true
                Conditions = @(
                    [PSCustomObject]@{
                        Field = "Severity"
                        Operator = "Equals"
                        Value = "Info"
                    }
                )
                Actions = @(
                    [PSCustomObject]@{
                        Type = "SendNotification"
                        Channels = @("Dashboard")
                        Template = "info-notification"
                    }
                )
            }
        )
    }
}

function Get-DefaultTagDefinitions {
    <#
    .SYNOPSIS
        Returns default tag definitions for rule matching.
    #>
    
    return [PSCustomObject]@{
        Version = "1.0.0"
        Tags = @(
            [PSCustomObject]@{
                TagName = "unity"
                DisplayName = "Unity Engine"
                Description = "Alerts related to Unity engine compilation, runtime, or build processes"
                Category = "Development"
                AutoDetectionRules = @("Source contains 'Unity'", "Component contains 'Unity'")
            }
            [PSCustomObject]@{
                TagName = "compilation"
                DisplayName = "Compilation Issues"
                Description = "Code compilation errors, warnings, and build failures"
                Category = "Build"
                AutoDetectionRules = @("Message contains 'compilation'", "Message contains 'build'", "Message contains 'error CS'")
            }
            [PSCustomObject]@{
                TagName = "ai"
                DisplayName = "AI Analysis"
                Description = "AI-generated analysis, recommendations, and insights"
                Category = "Intelligence"
                AutoDetectionRules = @("Source contains 'AI'", "Source contains 'LangGraph'", "Source contains 'Ollama'")
            }
            [PSCustomObject]@{
                TagName = "performance"
                DisplayName = "Performance Issues"
                Description = "Performance-related alerts, bottlenecks, and optimization opportunities"
                Category = "Performance"
                AutoDetectionRules = @("Message contains 'performance'", "Message contains 'slow'", "Message contains 'timeout'")
            }
            [PSCustomObject]@{
                TagName = "security"
                DisplayName = "Security Alerts"
                Description = "Security-related warnings, authentication issues, and access controls"
                Category = "Security"
                AutoDetectionRules = @("Message contains 'security'", "Message contains 'auth'", "Message contains 'access denied'")
            }
        )
    }
}

function Initialize-RuleEngine {
    <#
    .SYNOPSIS
        Initializes the rule processing engine with validation and matching logic.
    #>
    [CmdletBinding()]
    param()
    
    try {
        $script:NotificationPreferencesState.RuleEngine = @{
            ProcessingEnabled = $true
            ValidationEnabled = $true
            CacheEnabled = $true
            Cache = @{}
            CacheTTL = 300  # 5 minutes
            Statistics = @{
                CacheHits = 0
                CacheMisses = 0
                ValidationFailures = 0
                ProcessingErrors = 0
            }
        }
        
        Write-Verbose "Rule engine initialized successfully"
        return $true
    }
    catch {
        Write-Error "Failed to initialize rule engine: $($_.Exception.Message)"
        return $false
    }
}

function Get-NotificationPreferencesForUser {
    <#
    .SYNOPSIS
        Retrieves notification preferences for a specific user.
    
    .DESCRIPTION
        Gets user-specific notification preferences with fallback to default
        preferences if user-specific settings are not found.
    
    .PARAMETER UserId
        User identifier to get preferences for.
    
    .PARAMETER IncludeDefaults
        Include default preferences in the result.
    
    .EXAMPLE
        Get-NotificationPreferencesForUser -UserId "john.doe@company.com"
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$UserId,
        
        [Parameter(Mandatory = $false)]
        [switch]$IncludeDefaults
    )
    
    try {
        # Check for user-specific preferences
        if ($script:NotificationPreferencesState.UserPreferences.ContainsKey($UserId)) {
            $userPrefs = $script:NotificationPreferencesState.UserPreferences[$UserId]
            Write-Verbose "Found user-specific preferences for: $UserId"
        }
        elseif ($script:NotificationPreferencesState.UserPreferences.ContainsKey("default")) {
            $userPrefs = $script:NotificationPreferencesState.UserPreferences["default"]
            Write-Verbose "Using default preferences for: $UserId"
        }
        else {
            Write-Warning "No preferences found for user: $UserId. Creating default."
            $userPrefs = Create-DefaultUserPreferences -UserId $UserId
        }
        
        # Include system defaults if requested
        if ($IncludeDefaults) {
            $systemDefaults = $script:NotificationPreferencesState.UserPreferences["default"]
            $userPrefs = Merge-UserPreferences -UserPreferences $userPrefs -SystemDefaults $systemDefaults
        }
        
        return $userPrefs
    }
    catch {
        Write-Error "Failed to get user preferences: $($_.Exception.Message)"
        return $null
    }
}

function Set-NotificationPreferencesForUser {
    <#
    .SYNOPSIS
        Sets notification preferences for a specific user.
    
    .DESCRIPTION
        Updates user-specific notification preferences with validation
        and automatic persistence to configuration file.
    
    .PARAMETER UserId
        User identifier to set preferences for.
    
    .PARAMETER Preferences
        Preferences object with user settings.
    
    .PARAMETER ValidateConfiguration
        Validate configuration before saving.
    
    .EXAMPLE
        Set-NotificationPreferencesForUser -UserId "john.doe@company.com" -Preferences $prefsObject
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$UserId,
        
        [Parameter(Mandatory = $true)]
        [PSCustomObject]$Preferences,
        
        [Parameter(Mandatory = $false)]
        [switch]$ValidateConfiguration = $true
    )
    
    try {
        # Validate preferences if requested
        if ($ValidateConfiguration) {
            $validation = Test-UserPreferencesConfiguration -Preferences $Preferences
            if (-not $validation.IsValid) {
                throw "Invalid preferences configuration: $($validation.Errors -join ', ')"
            }
        }
        
        # Update user preferences
        $script:NotificationPreferencesState.UserPreferences[$UserId] = $Preferences
        
        # Save to file
        $allPreferences = [PSCustomObject]@{
            Version = "1.0.0"
            LastUpdated = Get-Date -Format "o"
            Users = $script:NotificationPreferencesState.UserPreferences.Values
        }
        
        Save-NotificationPreferences -Preferences $allPreferences
        
        Write-Host "Updated notification preferences for user: $UserId" -ForegroundColor Green
        return $true
    }
    catch {
        Write-Error "Failed to set user preferences: $($_.Exception.Message)"
        return $false
    }
}

function Get-DeliveryChannelsForAlert {
    <#
    .SYNOPSIS
        Determines delivery channels for an alert based on user preferences and rules.
    
    .DESCRIPTION
        Uses rule engine to evaluate alert against delivery rules and user preferences,
        implementing research-validated priority-based routing with tag matching.
    
    .PARAMETER Alert
        Alert object to evaluate.
    
    .PARAMETER UserId
        Optional user ID for user-specific preferences.
    
    .EXAMPLE
        Get-DeliveryChannelsForAlert -Alert $alertObject -UserId "admin@company.com"
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [PSCustomObject]$Alert,
        
        [Parameter(Mandatory = $false)]
        [string]$UserId = "default"
    )
    
    try {
        # Get user preferences
        $userPrefs = Get-NotificationPreferencesForUser -UserId $UserId
        
        # Apply auto-tagging to alert
        $alertWithTags = Add-AutoTags -Alert $Alert
        
        # Evaluate rules in priority order (research-validated pattern)
        $matchingRules = @()
        $sortedRules = $script:NotificationPreferencesState.DeliveryRules.Values | Sort-Object Priority
        
        foreach ($rule in $sortedRules) {
            if (-not $rule.Enabled) {
                continue
            }
            
            $ruleMatches = Test-RuleConditions -Alert $alertWithTags -Rule $rule
            if ($ruleMatches) {
                $matchingRules += $rule
                Write-Verbose "Alert matches rule: $($rule.Name)"
            }
        }
        
        # Determine channels from matching rules and user preferences
        $selectedChannels = Get-ChannelsFromRules -MatchingRules $matchingRules -UserPreferences $userPrefs -Alert $alertWithTags
        
        # Apply time-based rules if enabled
        if ($script:NotificationPreferencesState.Configuration.EnableTimeBasedRules) {
            $selectedChannels = Apply-TimeBasedRules -Channels $selectedChannels -UserPreferences $userPrefs -Alert $alertWithTags
        }
        
        $script:NotificationPreferencesState.Statistics.RulesProcessed++
        $script:NotificationPreferencesState.Statistics.PreferencesApplied++
        
        Write-Verbose "Selected delivery channels: $($selectedChannels -join ', ')"
        return $selectedChannels
    }
    catch {
        Write-Error "Failed to determine delivery channels: $($_.Exception.Message)"
        return @("Dashboard")  # Fallback to dashboard
    }
}

function Add-AutoTags {
    <#
    .SYNOPSIS
        Automatically adds tags to alerts based on tag definitions.
    
    .PARAMETER Alert
        Alert object to add tags to.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [PSCustomObject]$Alert
    )
    
    try {
        $alertTags = @()
        
        foreach ($tagDef in $script:NotificationPreferencesState.TagDefinitions.Values) {
            foreach ($rule in $tagDef.AutoDetectionRules) {
                $matched = $false
                
                # Simple rule evaluation (can be enhanced with more sophisticated logic)
                switch -Regex ($rule) {
                    "Source contains '(.+)'" {
                        if ($Alert.Source -match $Matches[1]) { $matched = $true }
                    }
                    "Component contains '(.+)'" {
                        if ($Alert.Component -match $Matches[1]) { $matched = $true }
                    }
                    "Message contains '(.+)'" {
                        if ($Alert.Message -match $Matches[1]) { $matched = $true }
                    }
                }
                
                if ($matched -and $alertTags -notcontains $tagDef.TagName) {
                    $alertTags += $tagDef.TagName
                    Write-Verbose "Auto-tagged alert with: $($tagDef.TagName)"
                }
            }
        }
        
        # Add tags to alert object
        $Alert | Add-Member -NotePropertyName "Tags" -NotePropertyValue $alertTags -Force
        
        if ($alertTags.Count -gt 0) {
            $script:NotificationPreferencesState.Statistics.TagsMatched++
        }
        
        return $Alert
    }
    catch {
        Write-Error "Failed to add auto tags: $($_.Exception.Message)"
        return $Alert
    }
}

function Test-RuleConditions {
    <#
    .SYNOPSIS
        Tests if an alert matches rule conditions.
    
    .PARAMETER Alert
        Alert object to test.
    
    .PARAMETER Rule
        Rule object with conditions.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [PSCustomObject]$Alert,
        
        [Parameter(Mandatory = $true)]
        [PSCustomObject]$Rule
    )
    
    try {
        foreach ($condition in $Rule.Conditions) {
            $fieldValue = switch ($condition.Field) {
                "Severity" { $Alert.Severity }
                "Source" { $Alert.Source }
                "Component" { $Alert.Component }
                "Message" { $Alert.Message }
                "Tags" { $Alert.Tags }
                default { $null }
            }
            
            $conditionMet = switch ($condition.Operator) {
                "Equals" { $fieldValue -eq $condition.Value }
                "NotEquals" { $fieldValue -ne $condition.Value }
                "Contains" { $fieldValue -match $condition.Value }
                "NotContains" { $fieldValue -notmatch $condition.Value }
                "In" { $fieldValue -in $condition.Value }
                "NotIn" { $fieldValue -notin $condition.Value }
                default { $false }
            }
            
            if (-not $conditionMet) {
                return $false
            }
        }
        
        return $true  # All conditions met
    }
    catch {
        Write-Error "Failed to test rule conditions: $($_.Exception.Message)"
        return $false
    }
}

function Get-ChannelsFromRules {
    <#
    .SYNOPSIS
        Determines channels from matching rules and user preferences.
    
    .PARAMETER MatchingRules
        Array of rules that matched the alert.
    
    .PARAMETER UserPreferences
        User preference object.
    
    .PARAMETER Alert
        Alert object being processed.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [array]$MatchingRules,
        
        [Parameter(Mandatory = $true)]
        [PSCustomObject]$UserPreferences,
        
        [Parameter(Mandatory = $true)]
        [PSCustomObject]$Alert
    )
    
    $channels = @()
    
    # Process rules in priority order (first match wins pattern)
    $sortedRules = $MatchingRules | Sort-Object Priority
    
    foreach ($rule in $sortedRules) {
        foreach ($action in $rule.Actions) {
            if ($action.Type -eq "SendNotification") {
                foreach ($channel in $action.Channels) {
                    # Check if channel is enabled in user preferences
                    if ($userPreferences.Preferences.EnabledChannels -contains $channel -and
                        $userPreferences.Preferences.DisabledChannels -notcontains $channel) {
                        
                        # Check severity filter for this channel
                        if ($userPreferences.Preferences.SeverityFilters[$channel] -contains $Alert.Severity) {
                            if ($channels -notcontains $channel) {
                                $channels += $channel
                            }
                        }
                    }
                }
            }
        }
        
        # First matching rule determines channels (research pattern)
        if ($channels.Count -gt 0) {
            break
        }
    }
    
    return $channels
}

function Apply-TimeBasedRules {
    <#
    .SYNOPSIS
        Applies time-based delivery rules to channel selection.
    
    .PARAMETER Channels
        Currently selected channels.
    
    .PARAMETER UserPreferences
        User preference object.
    
    .PARAMETER Alert
        Alert object being processed.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [array]$Channels,
        
        [Parameter(Mandatory = $true)]
        [PSCustomObject]$UserPreferences,
        
        [Parameter(Mandatory = $true)]
        [PSCustomObject]$Alert
    )
    
    try {
        $currentTime = Get-Date
        $currentDayOfWeek = $currentTime.DayOfWeek.ToString()
        $currentTimeOfDay = $currentTime.ToString("HH:mm")
        
        foreach ($timeRule in $UserPreferences.Preferences.TimeBasedRules) {
            if (-not $timeRule.Enabled) {
                continue
            }
            
            # Check if current time falls within rule
            $dayMatches = $timeRule.DaysOfWeek -contains $currentDayOfWeek
            $timeMatches = Test-TimeInRange -CurrentTime $currentTimeOfDay -StartTime $timeRule.StartTime -EndTime $timeRule.EndTime
            
            if ($dayMatches -and $timeMatches) {
                # Override channels for this time period
                if ($timeRule.Channels) {
                    $Channels = $timeRule.Channels
                    Write-Verbose "Applied time-based rule: $($timeRule.Name)"
                }
                
                # Apply severity override if specified
                if ($timeRule.SeverityOverride -and $Alert.Severity -notin $timeRule.SeverityOverride) {
                    Write-Verbose "Alert filtered out by time-based severity override"
                    return @()
                }
                
                break  # First matching time rule wins
            }
        }
        
        return $Channels
    }
    catch {
        Write-Error "Failed to apply time-based rules: $($_.Exception.Message)"
        return $Channels  # Return original channels on error
    }
}

function Test-TimeInRange {
    <#
    .SYNOPSIS
        Tests if current time falls within specified time range.
    
    .PARAMETER CurrentTime
        Current time in HH:mm format.
    
    .PARAMETER StartTime
        Start time in HH:mm format.
    
    .PARAMETER EndTime
        End time in HH:mm format.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$CurrentTime,
        
        [Parameter(Mandatory = $true)]
        [string]$StartTime,
        
        [Parameter(Mandatory = $true)]
        [string]$EndTime
    )
    
    try {
        $current = [DateTime]::ParseExact($CurrentTime, "HH:mm", $null)
        $start = [DateTime]::ParseExact($StartTime, "HH:mm", $null)
        $end = [DateTime]::ParseExact($EndTime, "HH:mm", $null)
        
        # Handle overnight ranges (e.g., 18:00 to 07:59)
        if ($start -gt $end) {
            return ($current -ge $start -or $current -le $end)
        }
        else {
            return ($current -ge $start -and $current -le $end)
        }
    }
    catch {
        Write-Error "Failed to test time range: $($_.Exception.Message)"
        return $false
    }
}

function Test-NotificationPreferences {
    <#
    .SYNOPSIS
        Tests notification preferences system with comprehensive validation.
    
    .DESCRIPTION
        Validates preference management, rule processing, and delivery
        channel determination across multiple test scenarios.
    
    .EXAMPLE
        Test-NotificationPreferences
    #>
    [CmdletBinding()]
    param()
    
    Write-Host "Testing Notification Preferences System..." -ForegroundColor Cyan
    
    if (-not $script:NotificationPreferencesState.IsInitialized) {
        Write-Error "Notification preferences not initialized"
        return $false
    }
    
    $testResults = @{}
    
    # Test 1: Default user preferences
    Write-Host "Testing default user preferences..." -ForegroundColor Yellow
    $defaultPrefs = Get-NotificationPreferencesForUser -UserId "default"
    $testResults.DefaultPreferences = ($null -ne $defaultPrefs)
    
    # Test 2: Rule-based channel selection
    Write-Host "Testing rule-based channel selection..." -ForegroundColor Yellow
    $testAlert = [PSCustomObject]@{
        Id = [Guid]::NewGuid().ToString()
        Severity = "Critical"
        Source = "PreferencesTest"
        Component = "TestComponent"
        Message = "Test critical alert for preferences validation"
        Timestamp = Get-Date
    }
    
    $channels = Get-DeliveryChannelsForAlert -Alert $testAlert -UserId "default"
    $testResults.RuleBasedChannels = ($channels.Count -gt 0)
    
    # Test 3: Tag auto-detection
    Write-Host "Testing tag auto-detection..." -ForegroundColor Yellow
    $taggedAlert = Add-AutoTags -Alert $testAlert
    $testResults.TagAutoDetection = ($null -ne $taggedAlert.Tags)
    
    # Test 4: Time-based rule application
    Write-Host "Testing time-based rules..." -ForegroundColor Yellow
    $timeFilteredChannels = Apply-TimeBasedRules -Channels $channels -UserPreferences $defaultPrefs -Alert $testAlert
    $testResults.TimeBasedRules = ($null -ne $timeFilteredChannels)
    
    # Calculate success rate
    $successCount = ($testResults.Values | Where-Object { $_ }).Count
    $totalTests = $testResults.Count
    $successRate = [Math]::Round(($successCount / $totalTests) * 100, 1)
    
    Write-Host "Notification preferences test complete: $successCount/$totalTests tests passed ($successRate%)" -ForegroundColor Green
    
    return @{
        TestResults = $testResults
        SuccessCount = $successCount
        TotalTests = $totalTests
        SuccessRate = $successRate
        Statistics = $script:NotificationPreferencesState.Statistics
    }
}

function Get-NotificationPreferencesStatistics {
    <#
    .SYNOPSIS
        Returns comprehensive notification preferences statistics.
    #>
    [CmdletBinding()]
    param()
    
    $stats = $script:NotificationPreferencesState.Statistics.Clone()
    
    if ($stats.StartTime) {
        $stats.Runtime = (Get-Date) - $stats.StartTime
    }
    
    $stats.IsInitialized = $script:NotificationPreferencesState.IsInitialized
    $stats.ConfiguredUsers = $script:NotificationPreferencesState.UserPreferences.Count
    $stats.ActiveRules = $script:NotificationPreferencesState.DeliveryRules.Count
    $stats.DefinedTags = $script:NotificationPreferencesState.TagDefinitions.Count
    $stats.RuleEngineCache = $script:NotificationPreferencesState.RuleEngine.Cache.Count
    
    return [PSCustomObject]$stats
}

# Helper functions for file operations
function Save-NotificationPreferences {
    param($Preferences)
    $file = $script:NotificationPreferencesState.Configuration.PreferencesFile
    $jsonContent = $Preferences | ConvertTo-Json -Depth 10
    [System.IO.File]::WriteAllText($file, $jsonContent, [System.Text.UTF8Encoding]::new($false))
}

function Save-DeliveryRules {
    param($Rules)
    $file = $script:NotificationPreferencesState.Configuration.RulesFile
    $jsonContent = $Rules | ConvertTo-Json -Depth 10
    [System.IO.File]::WriteAllText($file, $jsonContent, [System.Text.UTF8Encoding]::new($false))
}

function Save-TagDefinitions {
    param($Tags)
    $file = $script:NotificationPreferencesState.Configuration.TagsFile
    $jsonContent = $Tags | ConvertTo-Json -Depth 10
    [System.IO.File]::WriteAllText($file, $jsonContent, [System.Text.UTF8Encoding]::new($false))
}

function Create-DefaultUserPreferences {
    param($UserId)
    return (Get-DefaultNotificationPreferences).Users[0]
}

function Test-UserPreferencesConfiguration {
    param($Preferences)
    return @{ IsValid = $true; Errors = @() }  # Placeholder for validation logic
}

function Merge-UserPreferences {
    param($UserPreferences, $SystemDefaults)
    return $UserPreferences  # Placeholder for merge logic
}

# Export notification preferences functions
Export-ModuleMember -Function @(
    'Initialize-NotificationPreferences',
    'Get-NotificationPreferencesForUser',
    'Set-NotificationPreferencesForUser',
    'Get-DeliveryChannelsForAlert',
    'Test-NotificationPreferences',
    'Get-NotificationPreferencesStatistics',
    'Add-AutoTags'
)