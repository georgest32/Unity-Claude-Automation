# Unity-Claude-AIAlertClassifier.psm1
# AI-Powered Alert Classification and Prioritization Module
# Part of Week 3: Real-Time Intelligence - Day 12, Hour 1-2

# Module-level variables for AI alert classification state
$script:AIAlertState = @{
    IsInitialized = $false
    OllamaConnection = $null
    ClassificationCache = @{}
    AlertHistory = [System.Collections.Generic.List[PSCustomObject]]::new()
    CorrelationIndex = @{}
    Configuration = @{
        # AI Configuration
        OllamaEndpoint = "http://localhost:11434"
        DefaultModel = "codellama:34b"
        FallbackModel = "llama3.1"
        AITimeout = 10
        MaxRetries = 2
        
        # Classification thresholds
        HighPriorityThreshold = 0.8
        MediumPriorityThreshold = 0.5
        CorrelationThreshold = 0.5
        DeduplicationWindow = 300  # 5 minutes
        
        # Escalation settings
        EscalationTimeThresholds = @{
            Critical = 300    # 5 minutes
            High = 900        # 15 minutes  
            Medium = 1800     # 30 minutes
            Low = 3600        # 1 hour
        }
        
        # Cache settings
        CacheEnabled = $true
        CacheTTL = 3600      # 1 hour
        MaxCacheSize = 1000
    }
    Statistics = @{
        AlertsClassified = 0
        AIClassificationsRequested = 0
        AIClassificationsSuccessful = 0
        CacheHits = 0
        AlertsCorrelated = 0
        AlertsDeduplicated = 0
        EscalationsTriggered = 0
        StartTime = $null
    }
    EscalationRules = @{
        Critical = @{
            Immediate = @("SMS", "Email", "Webhook")
            Tier1Timeout = 300
            Tier2Escalation = @("Manager", "OnCall")
            ExecutiveEscalation = 1800
        }
        High = @{
            Immediate = @("Email", "Webhook")
            Tier1Timeout = 900
            Tier2Escalation = @("TeamLead")
        }
        Medium = @{
            Immediate = @("Email")
            Tier1Timeout = 1800
        }
        Low = @{
            Immediate = @("Webhook")
        }
    }
}

# Alert severity levels (using strings instead of enum to avoid CLR error)
$script:AlertSeverity = @{
    Critical = "Critical"  # System down, security breach, data loss
    High = "High"          # Major functionality impacted, performance degraded
    Medium = "Medium"      # Partial functionality affected, warnings
    Low = "Low"            # Minor issues, informational
    Info = "Info"          # General information, success notifications
}

# Alert categories (using strings instead of enum to avoid CLR error)
$script:AlertCategory = @{
    Security = "Security"        # Security-related alerts
    Performance = "Performance"  # Performance and resource alerts
    Error = "Error"              # Error and exception alerts
    Warning = "Warning"          # Warning and advisory alerts
    Change = "Change"            # Code and configuration changes
    System = "System"            # System status and health
    Maintenance = "Maintenance"  # Maintenance and housekeeping
    Unknown = "Unknown"          # Unclassified alerts
}

# Escalation status (using strings instead of enum to avoid CLR error)
$script:EscalationStatus = @{
    None = "None"              # No escalation needed
    Pending = "Pending"        # Escalation scheduled
    InProgress = "InProgress"  # Currently escalating
    Completed = "Completed"    # Escalation completed
    Failed = "Failed"          # Escalation failed
}

function Initialize-AIAlertClassifier {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [hashtable]$Configuration = @{},
        
        [Parameter(Mandatory = $false)]
        [switch]$EnableAI,
        
        [Parameter(Mandatory = $false)]
        [switch]$TestConnection
    )
    
    Write-Host "Initializing AI-Powered Alert Classifier..." -ForegroundColor Cyan
    
    # Merge configuration
    foreach ($key in $Configuration.Keys) {
        $script:AIAlertState.Configuration[$key] = $Configuration[$key]
    }
    
    # Test Ollama connection if AI enabled
    if ($EnableAI -or $TestConnection) {
        $script:AIAlertState.OllamaConnection = Test-AIConnection
        if ($script:AIAlertState.OllamaConnection.Available) {
            Write-Host "AI Classification enabled with Ollama" -ForegroundColor Green
        }
        else {
            Write-Warning "AI unavailable: $($script:AIAlertState.OllamaConnection.Message)"
        }
    }
    
    # Initialize components
    Initialize-ClassificationEngine
    Initialize-CorrelationEngine
    Initialize-EscalationEngine
    
    $script:AIAlertState.Statistics.StartTime = Get-Date
    $script:AIAlertState.IsInitialized = $true
    
    Write-Host "AI Alert Classifier initialized" -ForegroundColor Green
    return $true
}

function Test-AIConnection {
    [CmdletBinding()]
    param()
    
    try {
        # Use existing Unity-Claude-LLM module if available
        if (Get-Command "Test-OllamaConnection" -ErrorAction SilentlyContinue) {
            return Test-OllamaConnection
        }
        
        # Fallback to direct API test
        $response = Invoke-RestMethod -Uri "$($script:AIAlertState.Configuration.OllamaEndpoint)/api/tags" `
                                      -Method Get `
                                      -TimeoutSec 5 `
                                      -ErrorAction Stop
        
        return @{
            Available = $true
            Models = $response.models
            Message = "Connected to Ollama"
        }
    }
    catch {
        return @{
            Available = $false
            Models = @()
            Message = "Failed to connect: $($_.Exception.Message)"
        }
    }
}

function Initialize-ClassificationEngine {
    [CmdletBinding()]
    param()
    
    # Classification templates for AI prompts
    $script:AIAlertState.ClassificationPrompts = @{
        Severity = @"
Analyze this alert and determine its severity level:

Alert: {ALERT_TEXT}
Context: {CONTEXT}
Source: {SOURCE}

Classify as one of: Critical, High, Medium, Low, Info
Consider impact on system functionality, user experience, and business operations.
Respond with only the severity level.
"@
        
        Category = @"
Categorize this alert into one of these types:

Alert: {ALERT_TEXT}
Details: {DETAILS}

Categories: Security, Performance, Error, Warning, Change, System, Maintenance, Unknown
Respond with only the category name.
"@
        
        Priority = @"
Calculate priority score (0-10) for this alert:

Alert: {ALERT_TEXT}
Severity: {SEVERITY}
Category: {CATEGORY}
Impact: {IMPACT}

Consider urgency, business impact, affected systems, and potential escalation needs.
Respond with only a number 0-10.
"@
    }
    
    Write-Verbose "Classification engine initialized with AI prompts"
}

function Initialize-CorrelationEngine {
    [CmdletBinding()]
    param()
    
    # Correlation patterns for deduplication
    $script:AIAlertState.CorrelationPatterns = @{
        FileChange = @{
            KeyFields = @("FilePath", "ChangeType")
            TimeWindow = 60  # seconds
            MaxCorrelations = 5
        }
        SystemResource = @{
            KeyFields = @("ResourceType", "SystemName")
            TimeWindow = 120
            MaxCorrelations = 10
        }
        Error = @{
            KeyFields = @("ErrorType", "Component")
            TimeWindow = 300
            MaxCorrelations = 3
        }
        Performance = @{
            KeyFields = @("MetricName", "Service")
            TimeWindow = 180
            MaxCorrelations = 8
        }
    }
    
    Write-Verbose "Correlation engine initialized with deduplication patterns"
}

function Initialize-EscalationEngine {
    [CmdletBinding()]
    param()
    
    # Escalation matrix based on severity and time
    $script:AIAlertState.EscalationMatrix = @{
        Critical = @{
            T0 = @("Immediate notification to on-call team", "SMS + Email + Webhook")
            T300 = @("Escalate to Tier 2", "Manager notification")
            T1800 = @("Executive escalation", "Emergency response team")
        }
        High = @{
            T0 = @("Email + Webhook notification")
            T900 = @("Escalate to team lead")
            T3600 = @("Manager notification")
        }
        Medium = @{
            T0 = @("Email notification")
            T1800 = @("Add to daily review queue")
        }
        Low = @{
            T0 = @("Webhook notification")
            T3600 = @("Weekly summary inclusion")
        }
    }
    
    Write-Verbose "Escalation engine initialized with severity-based matrix"
}

function Invoke-AIAlertClassification {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [PSCustomObject]$Alert,
        
        [Parameter(Mandatory = $false)]
        [switch]$UseAI,
        
        [Parameter(Mandatory = $false)]
        [switch]$ForceClassification
    )
    
    Write-Verbose "Classifying alert: $($Alert.Id)"
    
    # Check cache first
    $cacheKey = Get-AlertCacheKey -Alert $Alert
    if ($script:AIAlertState.Configuration.CacheEnabled -and 
        $script:AIAlertState.ClassificationCache.ContainsKey($cacheKey) -and 
        -not $ForceClassification) {
        
        $script:AIAlertState.Statistics.CacheHits++
        Write-Verbose "Cache hit for alert classification: $cacheKey"
        return $script:AIAlertState.ClassificationCache[$cacheKey]
    }
    
    $startTime = Get-Date
    
    # Base classification using rule-based approach
    $classification = Get-RuleBasedClassification -Alert $Alert
    
    # AI enhancement if available and requested
    if ($UseAI -and $script:AIAlertState.OllamaConnection.Available) {
        $classification = Add-AIClassification -Alert $Alert -BaseClassification $classification
    }
    
    # Add contextual information
    $classification = Add-ContextualInformation -Alert $Alert -Classification $classification
    
    # Calculate final priority score
    $classification.Priority = Calculate-AlertPriority -Classification $classification
    
    # Determine if alert should be raised (Critical/High severity with good confidence)
    $classification.ShouldRaiseAlert = (
        $classification.Severity -in @($script:AlertSeverity.Critical, $script:AlertSeverity.High) -and
        $classification.Confidence -gt 0.6
    ) -or (
        $classification.Severity -eq $script:AlertSeverity.Medium -and
        $classification.Confidence -gt 0.85
    )
    
    # Determine escalation requirements
    $classification.EscalationPlan = Get-EscalationPlan -Classification $classification
    
    # Cache the result
    if ($script:AIAlertState.Configuration.CacheEnabled) {
        $script:AIAlertState.ClassificationCache[$cacheKey] = $classification
        
        # Cleanup cache if too large
        if ($script:AIAlertState.ClassificationCache.Count -gt $script:AIAlertState.Configuration.MaxCacheSize) {
            Clear-OldCacheEntries
        }
    }
    
    # Update statistics
    $script:AIAlertState.Statistics.AlertsClassified++
    $processingTime = ((Get-Date) - $startTime).TotalMilliseconds
    
    # Add to alert history
    $historyEntry = @{
        Id = $Alert.Id
        Timestamp = Get-Date
        Classification = $classification
        ProcessingTime = $processingTime
        UsedAI = ($UseAI -and $script:AIAlertState.OllamaConnection.Available)
        # Store original alert data for correlation
        Source = $Alert.Source
        Message = $Alert.Message
        Component = $Alert.Component
        OriginalAlert = $Alert
    }
    
    $script:AIAlertState.AlertHistory.Add([PSCustomObject]$historyEntry)
    
    Write-Verbose "Alert classified in $([math]::Round($processingTime, 2))ms"
    
    return $classification
}

function Get-RuleBasedClassification {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [PSCustomObject]$Alert
    )
    
    $classification = @{
        Id = $Alert.Id
        Severity = $script:AlertSeverity.Medium
        Category = $script:AlertCategory.Unknown
        Priority = 5
        Confidence = 0.5  # Start with baseline confidence
        RuleBased = $true
        AIEnhanced = $false
        ProcessingPath = @("RuleBased")
        Details = @()
        Context = @{}
        Timestamp = Get-Date
        MatchStrength = 0
        PatternMatches = 0
    }
    
    # Enhanced pattern matching with confidence scoring
    $confidenceFactors = @()
    
    # Critical severity patterns with high confidence
    if ($Alert.Message -match 'critical|emergency|system.?down|complete.?failure|data.?loss|security.?breach') {
        $classification.Severity = $script:AlertSeverity.Critical
        $classification.Details += "Critical keywords detected"
        $confidenceFactors += 0.95
        $classification.PatternMatches++
    }
    # High severity patterns
    elseif ($Alert.Message -match 'error|failed|exception|crash|unavailable') {
        $classification.Severity = $script:AlertSeverity.High
        $classification.Details += "Error keywords detected"
        $confidenceFactors += 0.85
        $classification.PatternMatches++
    }
    # Warning patterns
    elseif ($Alert.Message -match 'warning|degraded|slow|timeout|retry') {
        $classification.Severity = $script:AlertSeverity.High
        $classification.Details += "Warning keywords detected"
        $confidenceFactors += 0.75
        $classification.PatternMatches++
    }
    # Info patterns
    elseif ($Alert.Message -match 'info|success|completed|normal|started|stopped') {
        $classification.Severity = $script:AlertSeverity.Info
        $classification.Details += "Informational keywords detected"
        $confidenceFactors += 0.90
        $classification.PatternMatches++
    }
    
    # Enhanced category classification with confidence
    if ($Alert.Source -match 'security|auth|login|credential|permission|access') {
        $classification.Category = $script:AlertCategory.Security
        $classification.Details += "Security source detected"
        $confidenceFactors += 0.90
        $classification.PatternMatches++
    }
    elseif ($Alert.Source -match 'performance|cpu|memory|disk|network|latency') {
        $classification.Category = $script:AlertCategory.Performance
        $classification.Details += "Performance source detected"
        $confidenceFactors += 0.85
        $classification.PatternMatches++
    }
    elseif ($Alert.Message -match 'exception|error|failure|fault|bug') {
        $classification.Category = $script:AlertCategory.Error
        $classification.Details += "Error patterns detected"
        $confidenceFactors += 0.80
        $classification.PatternMatches++
    }
    elseif ($Alert.Source -match 'change|deploy|update|modify|patch|upgrade') {
        $classification.Category = $script:AlertCategory.Change
        $classification.Details += "Change-related source detected"
        $confidenceFactors += 0.85
        $classification.PatternMatches++
    }
    
    # Additional context patterns for better confidence
    if ($Alert.Message -match '\b(production|prod)\b') {
        $confidenceFactors += 0.10
        $classification.Details += "Production environment indicator"
    }
    if ($Alert.Message -match '\b(test|dev|staging)\b') {
        $confidenceFactors += -0.10
        $classification.Details += "Non-production environment indicator"
    }
    if ($Alert.Message -match '\d{3,}%|\d+\s*(GB|MB|ms|seconds?)') {
        $confidenceFactors += 0.05
        $classification.Details += "Metrics detected"
    }
    
    # Calculate final confidence based on pattern matches
    if ($confidenceFactors.Count -gt 0) {
        $avgConfidence = ($confidenceFactors | Measure-Object -Average).Average
        # Boost confidence if multiple patterns match
        $matchBoost = [Math]::Min(0.15, $classification.PatternMatches * 0.05)
        $classification.Confidence = [Math]::Min(0.99, $avgConfidence + $matchBoost)
    } else {
        # Low confidence for unmatched patterns
        $classification.Confidence = 0.40
    }
    
    # Adjust match strength
    $classification.MatchStrength = $classification.Confidence
    
    return $classification
}

function Add-AIClassification {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [PSCustomObject]$Alert,
        
        [Parameter(Mandatory = $true)]
        [hashtable]$BaseClassification
    )
    
    try {
        Write-Verbose "Requesting AI classification for alert: $($Alert.Id)"
        $script:AIAlertState.Statistics.AIClassificationsRequested++
        
        # Prepare context for AI analysis
        $context = @"
Alert Details:
Source: $($Alert.Source)
Message: $($Alert.Message)
Component: $($Alert.Component)
Time: $($Alert.Timestamp)
Current Classification: $($BaseClassification.Severity) / $($BaseClassification.Category)
"@
        
        # Get AI severity assessment
        $severityPrompt = $script:AIAlertState.ClassificationPrompts.Severity -replace '{ALERT_TEXT}', $Alert.Message -replace '{CONTEXT}', $context -replace '{SOURCE}', $Alert.Source
        $aiSeverity = Invoke-OllamaClassification -Prompt $severityPrompt -ExpectedValues @("Critical", "High", "Medium", "Low", "Info")
        
        if ($aiSeverity) {
            $BaseClassification.Severity = $aiSeverity
            $BaseClassification.AIEnhanced = $true
            $BaseClassification.ProcessingPath += "AI-Severity"
            $BaseClassification.Details += "AI severity assessment: $aiSeverity"
            $BaseClassification.Confidence = [Math]::Min($BaseClassification.Confidence + 0.2, 1.0)
        }
        
        # Get AI category assessment
        $categoryPrompt = $script:AIAlertState.ClassificationPrompts.Category -replace '{ALERT_TEXT}', $Alert.Message -replace '{DETAILS}', $context
        $aiCategory = Invoke-OllamaClassification -Prompt $categoryPrompt -ExpectedValues @("Security", "Performance", "Error", "Warning", "Change", "System", "Maintenance", "Unknown")
        
        if ($aiCategory) {
            $BaseClassification.Category = $aiCategory
            $BaseClassification.ProcessingPath += "AI-Category"
            $BaseClassification.Details += "AI category assessment: $aiCategory"
            $BaseClassification.Confidence = [Math]::Min($BaseClassification.Confidence + 0.2, 1.0)
        }
        
        # Get AI priority score
        $priorityPrompt = $script:AIAlertState.ClassificationPrompts.Priority -replace '{ALERT_TEXT}', $Alert.Message -replace '{SEVERITY}', $BaseClassification.Severity -replace '{CATEGORY}', $BaseClassification.Category -replace '{IMPACT}', $Alert.Impact
        $aiPriority = Invoke-OllamaPriorityScore -Prompt $priorityPrompt
        
        if ($aiPriority -and $aiPriority -ge 0 -and $aiPriority -le 10) {
            $BaseClassification.AIPriority = $aiPriority
            $BaseClassification.ProcessingPath += "AI-Priority"
            $BaseClassification.Details += "AI priority score: $aiPriority"
        }
        
        $script:AIAlertState.Statistics.AIClassificationsSuccessful++
        
    }
    catch {
        Write-Warning "AI classification failed: $_"
        $BaseClassification.Details += "AI classification failed: $($_.Exception.Message)"
    }
    
    return $BaseClassification
}

function Invoke-OllamaClassification {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Prompt,
        
        [Parameter(Mandatory = $true)]
        [string[]]$ExpectedValues
    )
    
    try {
        $body = @{
            model = $script:AIAlertState.Configuration.DefaultModel
            prompt = $Prompt
            stream = $false
            options = @{
                temperature = 0.1  # Low temperature for consistent classification
                max_tokens = 50
            }
        } | ConvertTo-Json
        
        $response = Invoke-RestMethod -Uri "$($script:AIAlertState.Configuration.OllamaEndpoint)/api/generate" `
                                      -Method Post `
                                      -Body $body `
                                      -ContentType "application/json" `
                                      -TimeoutSec $script:AIAlertState.Configuration.AITimeout
        
        if ($response.response) {
            $aiResult = $response.response.Trim()
            
            # Validate response against expected values
            foreach ($expected in $ExpectedValues) {
                if ($aiResult -match $expected) {
                    return $expected
                }
            }
            
            # Return closest match if no exact match
            return $aiResult
        }
    }
    catch {
        Write-Verbose "Ollama classification request failed: $_"
    }
    
    return $null
}

function Invoke-OllamaPriorityScore {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Prompt
    )
    
    try {
        $body = @{
            model = $script:AIAlertState.Configuration.DefaultModel
            prompt = $Prompt
            stream = $false
            options = @{
                temperature = 0.2
                max_tokens = 10
            }
        } | ConvertTo-Json
        
        $response = Invoke-RestMethod -Uri "$($script:AIAlertState.Configuration.OllamaEndpoint)/api/generate" `
                                      -Method Post `
                                      -Body $body `
                                      -ContentType "application/json" `
                                      -TimeoutSec $script:AIAlertState.Configuration.AITimeout
        
        if ($response.response) {
            $scoreText = $response.response.Trim()
            $score = $null
            if ([double]::TryParse($scoreText, [ref]$score)) {
                return [Math]::Max(0, [Math]::Min(10, $score))
            }
        }
    }
    catch {
        Write-Verbose "Ollama priority scoring failed: $_"
    }
    
    return $null
}

function Add-ContextualInformation {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [PSCustomObject]$Alert,
        
        [Parameter(Mandatory = $true)]
        [hashtable]$Classification
    )
    
    # Always add basic contextual information
    $Classification.Context["Alert"] = @{
        Source = $Alert.Source
        Component = $Alert.Component
        Timestamp = $Alert.Timestamp
        ProcessingTime = Get-Date
    }
    
    # Add contextual information from existing analysis modules
    if ($Alert.FilePath) {
        # Get change intelligence if available
        if (Get-Command "Get-ChangeClassification" -ErrorAction SilentlyContinue) {
            try {
                $changeEvent = [PSCustomObject]@{
                    FullPath = $Alert.FilePath
                    Name = Split-Path $Alert.FilePath -Leaf
                    Type = "Modified"
                    TimeStamp = $Alert.Timestamp
                }
                
                $changeClassification = Get-ChangeClassification -FileEvent $changeEvent
                $Classification.Context["ChangeIntelligence"] = $changeClassification
                $Classification.Details += "Change classification: $($changeClassification.ChangeType)"
                
                # Adjust severity based on change risk
                if ($changeClassification.RiskLevel -eq "VeryHigh" -or $changeClassification.RiskLevel -eq "High") {
                    if ($Classification.Severity -eq $script:AlertSeverity.Medium) {
                        $Classification.Severity = $script:AlertSeverity.High
                        $Classification.Details += "Severity elevated due to high change risk"
                    }
                }
            }
            catch {
                Write-Verbose "Failed to get change intelligence: $_"
            }
        }
        
        # Add file metadata
        if (Test-Path $Alert.FilePath) {
            $fileInfo = Get-Item $Alert.FilePath -ErrorAction SilentlyContinue
            if ($fileInfo) {
                $Classification.Context["FileInfo"] = @{
                    Size = $fileInfo.Length
                    LastModified = $fileInfo.LastWriteTime
                    Extension = $fileInfo.Extension
                }
            }
        }
    }
    
    # Add system resource context if available
    if ($Alert.ResourceType -and (Get-Command "Get-RTPerformanceStatistics" -ErrorAction SilentlyContinue)) {
        try {
            $perfStats = Get-RTPerformanceStatistics
            $Classification.Context["Performance"] = @{
                CPUUsage = $perfStats.CurrentCPUUsage
                MemoryUsage = $perfStats.CurrentMemoryUsage
                SystemLoad = $perfStats.SystemLoadLevel
            }
            $Classification.Details += "System load: $($perfStats.SystemLoadLevel)"
        }
        catch {
            Write-Verbose "Failed to get performance context: $_"
        }
    }
    
    return $Classification
}

function Calculate-AlertPriority {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [hashtable]$Classification
    )
    
    # Base priority from severity
    $priority = switch ($Classification.Severity) {
        'Critical' { 9 }
        'High'     { 7 }
        'Medium'   { 5 }
        'Low'      { 3 }
        'Info'     { 1 }
    }
    
    # Category adjustments
    $categoryBonus = switch ($Classification.Category) {
        'Security'    { 2 }
        'Error'       { 1 }
        'Performance' { 1 }
        'System'      { 0 }
        'Change'      { 0 }
        'Warning'     { -1 }
        'Maintenance' { -1 }
    }
    
    $priority += $categoryBonus
    
    # AI priority integration if available
    if ($Classification.AIPriority) {
        $priority = [Math]::Round(($priority + $Classification.AIPriority) / 2, 1)
    }
    
    # Confidence adjustment
    if ($Classification.Confidence -lt 0.5) {
        $priority -= 1  # Lower confidence reduces priority
    }
    
    return [Math]::Max(0, [Math]::Min(10, $priority))
}

function Get-EscalationPlan {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [hashtable]$Classification
    )
    
    $severity = $Classification.Severity
    $escalationRules = $script:AIAlertState.EscalationRules[$severity.ToString()]
    
    if (-not $escalationRules) {
        return @{
            Required = $false
            Steps = @()
        }
    }
    
    $plan = @{
        Required = $true
        Severity = $severity
        ImmediateActions = $escalationRules.Immediate
        TimeBasedEscalations = @()
        EstimatedResponseTime = $script:AIAlertState.Configuration.EscalationTimeThresholds[$severity.ToString()]
    }
    
    # Add time-based escalation steps
    foreach ($key in $escalationRules.Keys) {
        if ($key -match '^T\d+$') {
            $timeSeconds = [int]($key -replace 'T', '')
            $plan.TimeBasedEscalations += @{
                TriggerTime = $timeSeconds
                Actions = $escalationRules[$key]
            }
        }
    }
    
    return $plan
}

function Test-AlertCorrelation {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [PSCustomObject]$NewAlert,
        
        [Parameter(Mandatory = $false)]
        [int]$WindowSeconds = 300
    )
    
    $correlatedAlerts = @()
    $cutoffTime = (Get-Date).AddSeconds(-$WindowSeconds)
    
    # Check recent alerts for correlation
    $recentAlerts = $script:AIAlertState.AlertHistory | Where-Object { 
        $_.Timestamp -gt $cutoffTime -and $_.Id -ne $NewAlert.Id 
    }
    
    foreach ($alert in $recentAlerts) {
        $correlationScore = Calculate-CorrelationScore -Alert1 $NewAlert -Alert2 $alert
        
        if ($correlationScore -gt $script:AIAlertState.Configuration.CorrelationThreshold) {
            $correlatedAlerts += @{
                AlertId = $alert.Id
                Score = $correlationScore
                Reason = "Similar content and timing"
            }
        }
    }
    
    if ($correlatedAlerts.Count -gt 0) {
        $script:AIAlertState.Statistics.AlertsCorrelated++
    }
    
    return $correlatedAlerts
}

function Calculate-CorrelationScore {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [PSCustomObject]$Alert1,
        
        [Parameter(Mandatory = $true)]
        [PSCustomObject]$Alert2
    )
    
    $score = 0.0
    
    # Source similarity (40% weight)
    if ($Alert1.Source -eq $Alert2.Source) {
        $score += 0.4
    }
    elseif ($Alert1.Source -and $Alert2.Source -and 
            ($Alert1.Source -match [regex]::Escape($Alert2.Source) -or 
             $Alert2.Source -match [regex]::Escape($Alert1.Source))) {
        $score += 0.2
    }
    
    # Message similarity (30% weight)
    if ($Alert1.Message -and $Alert2.Message) {
        $similarity = Get-StringSimilarity -String1 $Alert1.Message -String2 $Alert2.Message
        $score += $similarity * 0.3
    }
    
    # Component similarity (20% weight)
    if ($Alert1.Component -eq $Alert2.Component) {
        $score += 0.2
    }
    
    # Time proximity (10% weight)
    if ($Alert1.Timestamp -and $Alert2.Timestamp) {
        $timeDiff = [Math]::Abs(($Alert1.Timestamp - $Alert2.Timestamp).TotalMinutes)
        if ($timeDiff -lt 5) {
            $score += 0.1
        }
        elseif ($timeDiff -lt 15) {
            $score += 0.05
        }
    }
    
    return $score
}

function Get-StringSimilarity {
    [CmdletBinding()]
    param(
        [string]$String1,
        [string]$String2
    )
    
    if (-not $String1 -or -not $String2) { return 0 }
    
    # Simple Jaccard similarity using word sets
    $words1 = ($String1 -split '\s+' | ForEach-Object { $_.ToLower() }) | Sort-Object -Unique
    $words2 = ($String2 -split '\s+' | ForEach-Object { $_.ToLower() }) | Sort-Object -Unique
    
    $intersection = $words1 | Where-Object { $_ -in $words2 }
    $union = ($words1 + $words2) | Sort-Object -Unique
    
    if ($union.Count -eq 0) { return 0 }
    
    return $intersection.Count / $union.Count
}

function Get-AlertCacheKey {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [PSCustomObject]$Alert
    )
    
    # Create cache key from alert characteristics
    $keyElements = @(
        $Alert.Source,
        $Alert.Message,
        $Alert.Component
    ) | Where-Object { $_ }
    
    $combined = $keyElements -join "|"
    
    # Use PowerShell-native hash generation instead of FormsAuthentication
    $hasher = [System.Security.Cryptography.MD5]::Create()
    $hashBytes = $hasher.ComputeHash([System.Text.Encoding]::UTF8.GetBytes($combined))
    $hashString = [System.BitConverter]::ToString($hashBytes) -replace '-', ''
    $hasher.Dispose()
    
    return $hashString
}

function Clear-OldCacheEntries {
    [CmdletBinding()]
    param()
    
    # Remove oldest 20% of cache entries
    $removeCount = [Math]::Floor($script:AIAlertState.ClassificationCache.Count * 0.2)
    $oldestKeys = $script:AIAlertState.ClassificationCache.Keys | Select-Object -First $removeCount
    
    foreach ($key in $oldestKeys) {
        $script:AIAlertState.ClassificationCache.Remove($key)
    }
    
    Write-Verbose "Cleared $removeCount old cache entries"
}

function Get-AIAlertStatistics {
    [CmdletBinding()]
    param()
    
    $stats = $script:AIAlertState.Statistics.Clone()
    
    if ($stats.StartTime) {
        $stats.Runtime = (Get-Date) - $stats.StartTime
    }
    
    $stats.IsInitialized = $script:AIAlertState.IsInitialized
    $stats.OllamaAvailable = $script:AIAlertState.OllamaConnection.Available
    $stats.CacheSize = $script:AIAlertState.ClassificationCache.Count
    $stats.HistoryCount = $script:AIAlertState.AlertHistory.Count
    
    # Calculate rates
    if ($stats.AIClassificationsRequested -gt 0) {
        $stats.AISuccessRate = [Math]::Round(($stats.AIClassificationsSuccessful / $stats.AIClassificationsRequested) * 100, 2)
    }
    
    if ($stats.AlertsClassified -gt 0) {
        $stats.CacheHitRate = [Math]::Round(($stats.CacheHits / $stats.AlertsClassified) * 100, 2)
    }
    
    return [PSCustomObject]$stats
}

# Export module functions
Export-ModuleMember -Function @(
    'Initialize-AIAlertClassifier',
    'Invoke-AIAlertClassification',
    'Test-AlertCorrelation',
    'Get-AIAlertStatistics'
)
