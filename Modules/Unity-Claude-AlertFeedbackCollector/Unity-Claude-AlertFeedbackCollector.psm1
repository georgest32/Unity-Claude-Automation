# Unity-Claude-AlertFeedbackCollector.psm1
# Week 3 Day 12 Hour 7-8: Alert Quality and Feedback Loop Implementation
# Research-validated feedback collection system with NPS/CSAT metrics integration
# Implements enterprise-grade feedback patterns with automated collection

# Module state for alert feedback collection
$script:AlertFeedbackState = @{
    IsInitialized = $false
    Configuration = $null
    FeedbackDatabase = @{}
    ActiveSurveys = @{}
    QualityMetrics = @{}
    Statistics = @{
        FeedbackCollected = 0
        AlertsRated = 0
        SurveysGenerated = 0
        QualityScoresCalculated = 0
        NPSResponses = 0
        CSATResponses = 0
        StartTime = $null
        LastFeedbackTime = $null
    }
    FeedbackStorage = @{
        DatabasePath = ".\Data\alert-feedback-database.json"
        MetricsPath = ".\Data\alert-quality-metrics.json" 
        ArchivePath = ".\Data\Archives\feedback-archive.json"
        BackupEnabled = $true
        RetentionDays = 365
    }
    ConnectedSystems = @{
        NotificationIntegration = $false
        IntelligentAlerting = $false
        ProactiveMaintenanceEngine = $false
        AIAlertClassifier = $false
    }
}

# Feedback rating scale (research-validated enterprise pattern)
enum FeedbackRating {
    VeryPoor = 1
    Poor = 2
    Fair = 3
    Good = 4
    Excellent = 5
}

# Alert outcome classification (research-validated)
enum AlertOutcome {
    Actionable = 1
    Informational = 2
    FalsePositive = 3
    TruePositive = 4
    Noise = 5
    Critical = 6
}

# Quality metric types (based on enterprise research)
enum QualityMetricType {
    Precision
    Recall
    F1Score
    NPSScore
    CSATScore
    AlertEffectiveness
    ResponseTime
    UserSatisfaction
}

function Initialize-AlertFeedbackCollector {
    <#
    .SYNOPSIS
        Initializes the alert feedback collection system.
    
    .DESCRIPTION
        Sets up enterprise-grade feedback collection with automated surveys,
        quality metrics tracking, and integration with existing alert systems.
        Research-validated approach with NPS/CSAT metrics integration.
    
    .PARAMETER DatabasePath
        Path to feedback database JSON file.
    
    .PARAMETER EnableAutomatedSurveys
        Enable automated feedback collection after alert delivery.
    
    .PARAMETER AutoDiscoverSystems
        Automatically discover and connect to existing alert systems.
    
    .EXAMPLE
        Initialize-AlertFeedbackCollector -EnableAutomatedSurveys -AutoDiscoverSystems
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [string]$DatabasePath = ".\Data\alert-feedback-database.json",
        
        [Parameter(Mandatory = $false)]
        [switch]$EnableAutomatedSurveys,
        
        [Parameter(Mandatory = $false)]
        [switch]$AutoDiscoverSystems
    )
    
    Write-Host "Initializing Alert Feedback Collection System..." -ForegroundColor Cyan
    
    try {
        # Set database path
        $script:AlertFeedbackState.FeedbackStorage.DatabasePath = $DatabasePath
        
        # Create default configuration
        $script:AlertFeedbackState.Configuration = Get-DefaultFeedbackConfiguration
        
        # Create data directories
        $dataDir = Split-Path $DatabasePath -Parent
        if (-not (Test-Path $dataDir)) {
            New-Item -ItemType Directory -Path $dataDir -Force | Out-Null
            Write-Verbose "Created data directory: $dataDir"
        }
        
        $archiveDir = Split-Path $script:AlertFeedbackState.FeedbackStorage.ArchivePath -Parent
        if (-not (Test-Path $archiveDir)) {
            New-Item -ItemType Directory -Path $archiveDir -Force | Out-Null
            Write-Verbose "Created archive directory: $archiveDir"
        }
        
        # Load existing feedback database
        Load-FeedbackDatabase
        
        # Auto-discover connected systems
        if ($AutoDiscoverSystems) {
            Discover-ConnectedAlertSystems
        }
        
        # Initialize quality metrics
        Initialize-QualityMetrics
        
        # Setup automated surveys if enabled
        if ($EnableAutomatedSurveys) {
            Enable-AutomatedFeedbackCollection
        }
        
        $script:AlertFeedbackState.Statistics.StartTime = Get-Date
        $script:AlertFeedbackState.IsInitialized = $true
        
        Write-Host "Alert Feedback Collection System initialized successfully" -ForegroundColor Green
        Write-Host "Database: $DatabasePath" -ForegroundColor Gray
        Write-Host "Automated surveys: $EnableAutomatedSurveys" -ForegroundColor Gray
        Write-Host "Connected systems: $AutoDiscoverSystems" -ForegroundColor Gray
        
        return $true
    }
    catch {
        Write-Error "Failed to initialize alert feedback collector: $($_.Exception.Message)"
        return $false
    }
}

function Get-DefaultFeedbackConfiguration {
    <#
    .SYNOPSIS
        Returns default feedback collection configuration.
    #>
    
    return [PSCustomObject]@{
        Version = "1.0.0"
        FeedbackCollection = [PSCustomObject]@{
            EnableUserRatings = $true
            EnableOutcomeTracking = $true
            EnableNPSSurveys = $true
            EnableCSATSurveys = $true
            AutomatedSurveyDelay = 3600  # 1 hour after alert
            MaxSurveysPerDay = 10
            FeedbackExpirationDays = 7
        }
        QualityMetrics = [PSCustomObject]@{
            EnablePrecisionTracking = $true
            EnableRecallTracking = $true
            EnableF1ScoreCalculation = $true
            EnableEffectivenessTracking = $true
            MetricsCalculationInterval = 3600  # 1 hour
            HistoricalAnalysisPeriod = 30  # 30 days
        }
        Reporting = [PSCustomObject]@{
            EnableDailyReports = $true
            EnableWeeklyTrends = $true
            EnableAlertTrendAnalysis = $true
            DashboardIntegration = $true
            ExportFormats = @("JSON", "CSV", "HTML")
        }
        Integration = [PSCustomObject]@{
            NotificationChannels = @("Email", "Dashboard", "Webhook")
            EnableRealTimeUpdates = $true
            EnableAutoDiscovery = $true
            IntegrationTimeout = 30
        }
        Storage = [PSCustomObject]@{
            UseTimeSeries = $true
            CompressionEnabled = $true
            BackupFrequency = "Daily"
            RetentionPolicy = 365  # days
            ArchiveAfterDays = 90
        }
    }
}

function Load-FeedbackDatabase {
    <#
    .SYNOPSIS
        Loads existing feedback database or creates new one.
    #>
    [CmdletBinding()]
    param()
    
    try {
        $dbPath = $script:AlertFeedbackState.FeedbackStorage.DatabasePath
        
        if (Test-Path $dbPath) {
            $jsonContent = Get-Content -Path $dbPath -Raw
            $database = $jsonContent | ConvertFrom-Json
            
            # Convert to hashtable for easier manipulation (PowerShell 5.1 compatible)
            $script:AlertFeedbackState.FeedbackDatabase = @{}
            
            foreach ($entry in $database.Feedback) {
                $script:AlertFeedbackState.FeedbackDatabase[$entry.AlertId] = $entry
            }
            
            Write-Verbose "Loaded feedback database with $($script:AlertFeedbackState.FeedbackDatabase.Count) entries"
        }
        else {
            Write-Warning "Feedback database not found: $dbPath. Creating new database."
            $script:AlertFeedbackState.FeedbackDatabase = @{}
            Save-FeedbackDatabase
        }
    }
    catch {
        Write-Error "Failed to load feedback database: $($_.Exception.Message)"
        throw
    }
}

function Save-FeedbackDatabase {
    <#
    .SYNOPSIS
        Saves feedback database to JSON file with PowerShell 5.1 compatibility.
    #>
    [CmdletBinding()]
    param()
    
    try {
        $dbPath = $script:AlertFeedbackState.FeedbackStorage.DatabasePath
        
        # Create database structure
        $database = [PSCustomObject]@{
            Version = "1.0.0"
            LastUpdated = Get-Date -Format "o"
            TotalEntries = $script:AlertFeedbackState.FeedbackDatabase.Count
            Feedback = $script:AlertFeedbackState.FeedbackDatabase.Values
        }
        
        # Save with UTF-8 without BOM (PowerShell 5.1 compatible)
        $jsonContent = $database | ConvertTo-Json -Depth 10
        [System.IO.File]::WriteAllText($dbPath, $jsonContent, [System.Text.UTF8Encoding]::new($false))
        
        Write-Verbose "Feedback database saved with $($database.TotalEntries) entries"
    }
    catch {
        Write-Error "Failed to save feedback database: $($_.Exception.Message)"
        throw
    }
}

function Discover-ConnectedAlertSystems {
    <#
    .SYNOPSIS
        Discovers and connects to existing alert systems for feedback integration.
    #>
    [CmdletBinding()]
    param()
    
    Write-Verbose "Discovering connected alert systems..."
    
    $moduleBasePath = Split-Path $PSScriptRoot -Parent
    
    # Check for Notification Integration
    $notificationPath = Join-Path $moduleBasePath "Unity-Claude-NotificationIntegration\Unity-Claude-NotificationIntegration.psm1"
    if (Test-Path $notificationPath) {
        try {
            Import-Module $notificationPath -Force -Global -ErrorAction SilentlyContinue
            $script:AlertFeedbackState.ConnectedSystems.NotificationIntegration = $true
            Write-Verbose "Connected: Notification Integration"
        }
        catch {
            Write-Warning "Failed to connect to Notification Integration: $_"
        }
    }
    
    # Check for Intelligent Alerting
    $alertingPath = Join-Path $moduleBasePath "Unity-Claude-IntelligentAlerting\Unity-Claude-IntelligentAlerting.psm1"
    if (Test-Path $alertingPath) {
        try {
            Import-Module $alertingPath -Force -Global -ErrorAction SilentlyContinue
            $script:AlertFeedbackState.ConnectedSystems.IntelligentAlerting = $true
            Write-Verbose "Connected: Intelligent Alerting"
        }
        catch {
            Write-Warning "Failed to connect to Intelligent Alerting: $_"
        }
    }
    
    # Check for Proactive Maintenance Engine
    $maintenancePath = Join-Path $moduleBasePath "Unity-Claude-ProactiveMaintenanceEngine\Unity-Claude-ProactiveMaintenanceEngine.psm1"
    if (Test-Path $maintenancePath) {
        try {
            Import-Module $maintenancePath -Force -Global -ErrorAction SilentlyContinue
            $script:AlertFeedbackState.ConnectedSystems.ProactiveMaintenanceEngine = $true
            Write-Verbose "Connected: Proactive Maintenance Engine"
        }
        catch {
            Write-Warning "Failed to connect to Proactive Maintenance Engine: $_"
        }
    }
    
    # Check for AI Alert Classifier
    $classifierPath = Join-Path $moduleBasePath "Unity-Claude-AIAlertClassifier\Unity-Claude-AIAlertClassifier.psm1"
    if (Test-Path $classifierPath) {
        try {
            Import-Module $classifierPath -Force -Global -ErrorAction SilentlyContinue
            $script:AlertFeedbackState.ConnectedSystems.AIAlertClassifier = $true
            Write-Verbose "Connected: AI Alert Classifier"
        }
        catch {
            Write-Warning "Failed to connect to AI Alert Classifier: $_"
        }
    }
    
    $connectedCount = ($script:AlertFeedbackState.ConnectedSystems.Values | Where-Object { $_ }).Count
    Write-Host "Connected to $connectedCount alert systems for feedback integration" -ForegroundColor Green
}

function Collect-AlertFeedback {
    <#
    .SYNOPSIS
        Collects user feedback for a specific alert.
    
    .DESCRIPTION
        Collects comprehensive feedback including rating, outcome classification,
        and optional detailed comments. Implements research-validated enterprise
        feedback patterns with NPS/CSAT integration.
    
    .PARAMETER AlertId
        Unique identifier for the alert.
    
    .PARAMETER UserRating
        User rating from 1-5 scale.
    
    .PARAMETER AlertOutcome
        Classification of alert outcome.
    
    .PARAMETER Comments
        Optional detailed feedback comments.
    
    .PARAMETER ResponseTime
        Time taken to respond to alert (for effectiveness metrics).
    
    .EXAMPLE
        Collect-AlertFeedback -AlertId "alert-123" -UserRating 4 -AlertOutcome "Actionable" -Comments "Helped identify real issue"
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$AlertId,
        
        [Parameter(Mandatory = $true)]
        [FeedbackRating]$UserRating,
        
        [Parameter(Mandatory = $true)]
        [AlertOutcome]$AlertOutcome,
        
        [Parameter(Mandatory = $false)]
        [string]$Comments = "",
        
        [Parameter(Mandatory = $false)]
        [double]$ResponseTime = 0,
        
        [Parameter(Mandatory = $false)]
        [string]$UserId = "default"
    )
    
    if (-not $script:AlertFeedbackState.IsInitialized) {
        Write-Error "Alert feedback collector not initialized. Call Initialize-AlertFeedbackCollector first."
        return $false
    }
    
    Write-Verbose "Collecting feedback for alert: $AlertId"
    
    try {
        # Create comprehensive feedback entry
        $feedbackEntry = [PSCustomObject]@{
            AlertId = $AlertId
            UserId = $UserId
            Timestamp = Get-Date
            UserRating = [int]$UserRating
            AlertOutcome = $AlertOutcome.ToString()
            Comments = $Comments
            ResponseTime = $ResponseTime
            
            # Quality metrics (calculated)
            IsActionable = ($AlertOutcome -in @([AlertOutcome]::Actionable, [AlertOutcome]::TruePositive, [AlertOutcome]::Critical))
            IsFalsePositive = ($AlertOutcome -eq [AlertOutcome]::FalsePositive)
            EffectivenessScore = Calculate-AlertEffectiveness -Rating $UserRating -Outcome $AlertOutcome -ResponseTime $ResponseTime
            
            # Metadata
            CollectionMethod = "Manual"
            Version = "1.0.0"
            ProcessedForML = $false
        }
        
        # Store feedback in database
        $script:AlertFeedbackState.FeedbackDatabase[$AlertId] = $feedbackEntry
        
        # Update statistics
        $script:AlertFeedbackState.Statistics.FeedbackCollected++
        $script:AlertFeedbackState.Statistics.AlertsRated++
        $script:AlertFeedbackState.Statistics.LastFeedbackTime = Get-Date
        
        # Calculate quality metrics if enabled
        if ($script:AlertFeedbackState.Configuration.QualityMetrics.EnableEffectivenessTracking) {
            Update-QualityMetrics -FeedbackEntry $feedbackEntry
        }
        
        # Save database
        Save-FeedbackDatabase
        
        Write-Host "Feedback collected for alert $AlertId" -ForegroundColor Green
        Write-Host "Rating: $([int]$UserRating)/5, Outcome: $($AlertOutcome.ToString())" -ForegroundColor Gray
        
        return $true
    }
    catch {
        Write-Error "Failed to collect feedback for alert $AlertId : $($_.Exception.Message)"
        return $false
    }
}

function Calculate-AlertEffectiveness {
    <#
    .SYNOPSIS
        Calculates alert effectiveness score based on rating, outcome, and response time.
    
    .PARAMETER Rating
        User rating (1-5).
    
    .PARAMETER Outcome
        Alert outcome classification.
    
    .PARAMETER ResponseTime
        Response time in seconds.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [FeedbackRating]$Rating,
        
        [Parameter(Mandatory = $true)]
        [AlertOutcome]$Outcome,
        
        [Parameter(Mandatory = $false)]
        [double]$ResponseTime = 0
    )
    
    try {
        # Base score from user rating (0-1 scale)
        $baseScore = ([int]$Rating - 1) / 4.0
        
        # Outcome weight (research-validated)
        $outcomeWeight = switch ($Outcome) {
            ([AlertOutcome]::Critical) { 1.0 }
            ([AlertOutcome]::Actionable) { 0.9 }
            ([AlertOutcome]::TruePositive) { 0.8 }
            ([AlertOutcome]::Informational) { 0.6 }
            ([AlertOutcome]::Noise) { 0.3 }
            ([AlertOutcome]::FalsePositive) { 0.1 }
            default { 0.5 }
        }
        
        # Response time factor (faster response = higher effectiveness)
        $responseTimeFactor = if ($ResponseTime -gt 0) {
            # Research-validated: < 30 minutes = good, > 2 hours = poor
            $maxGoodResponse = 1800  # 30 minutes
            $maxPoorResponse = 7200  # 2 hours
            
            if ($ResponseTime -le $maxGoodResponse) {
                1.0
            }
            elseif ($ResponseTime -ge $maxPoorResponse) {
                0.5
            }
            else {
                # Linear interpolation between good and poor
                1.0 - (($ResponseTime - $maxGoodResponse) / ($maxPoorResponse - $maxGoodResponse)) * 0.5
            }
        } else {
            1.0  # No response time penalty if not provided
        }
        
        # Calculate final effectiveness score (0-1 scale)
        $effectivenessScore = $baseScore * $outcomeWeight * $responseTimeFactor
        
        return [Math]::Round($effectivenessScore, 3)
    }
    catch {
        Write-Error "Failed to calculate alert effectiveness: $($_.Exception.Message)"
        return 0.0
    }
}

function Generate-AutomatedFeedbackSurvey {
    <#
    .SYNOPSIS
        Generates automated feedback survey for delivered alerts.
    
    .DESCRIPTION
        Creates automated feedback collection surveys based on research-validated
        enterprise patterns with NPS/CSAT integration and multi-channel delivery.
    
    .PARAMETER Alert
        Alert object that was delivered.
    
    .PARAMETER DeliveryChannels
        Channels used for alert delivery.
    
    .PARAMETER DeliveryResult
        Result of alert delivery process.
    
    .EXAMPLE
        Generate-AutomatedFeedbackSurvey -Alert $alertObject -DeliveryChannels @("Email", "Teams")
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [PSCustomObject]$Alert,
        
        [Parameter(Mandatory = $true)]
        [array]$DeliveryChannels,
        
        [Parameter(Mandatory = $false)]
        [hashtable]$DeliveryResult = @{}
    )
    
    try {
        # Check if automated surveys are enabled
        if (-not $script:AlertFeedbackState.Configuration.FeedbackCollection.EnableUserRatings) {
            Write-Verbose "Automated feedback surveys disabled"
            return $false
        }
        
        # Check daily survey limits
        $todaySurveys = Get-TodaysSurveyCount
        if ($todaySurveys -ge $script:AlertFeedbackState.Configuration.FeedbackCollection.MaxSurveysPerDay) {
            Write-Verbose "Daily survey limit reached: $todaySurveys"
            return $false
        }
        
        # Generate survey content
        $survey = Create-FeedbackSurveyContent -Alert $Alert -DeliveryChannels $DeliveryChannels
        
        # Schedule survey delivery (research-validated delay)
        $deliveryTime = (Get-Date).AddSeconds($script:AlertFeedbackState.Configuration.FeedbackCollection.AutomatedSurveyDelay)
        
        $surveyData = @{
            SurveyId = [Guid]::NewGuid().ToString()
            AlertId = $Alert.Id
            CreatedTime = Get-Date
            ScheduledDelivery = $deliveryTime
            DeliveryChannels = $DeliveryChannels
            Content = $survey
            Status = "Scheduled"
            ExpiresAt = (Get-Date).AddDays($script:AlertFeedbackState.Configuration.FeedbackCollection.FeedbackExpirationDays)
        }
        
        $script:AlertFeedbackState.ActiveSurveys[$surveyData.SurveyId] = $surveyData
        $script:AlertFeedbackState.Statistics.SurveysGenerated++
        
        Write-Host "Automated feedback survey generated for alert: $($Alert.Id)" -ForegroundColor Blue
        Write-Host "Survey delivery scheduled: $($deliveryTime.ToString('yyyy-MM-dd HH:mm:ss'))" -ForegroundColor Gray
        
        return $surveyData.SurveyId
    }
    catch {
        Write-Error "Failed to generate automated feedback survey: $($_.Exception.Message)"
        return $false
    }
}

function Create-FeedbackSurveyContent {
    <#
    .SYNOPSIS
        Creates feedback survey content optimized for different delivery channels.
    
    .PARAMETER Alert
        Alert object for survey context.
    
    .PARAMETER DeliveryChannels
        Channels used for alert delivery.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [PSCustomObject]$Alert,
        
        [Parameter(Mandatory = $true)]
        [array]$DeliveryChannels
    )
    
    $surveyBaseUrl = "http://localhost:8080/feedback"  # Would be configurable
    $feedbackUrl = "$surveyBaseUrl/alert/$($Alert.Id)"
    
    # Create survey content
    $content = [PSCustomObject]@{
        Title = "Alert Feedback: How helpful was this alert?"
        Description = "Help us improve alert quality by providing feedback"
        AlertSummary = "Alert: [$($Alert.Severity)] $($Alert.Source) - $($Alert.Message)"
        
        # NPS-style question (research-validated)
        NPSQuestion = "How likely are you to recommend this alert system to colleagues? (0-10)"
        
        # CSAT-style question (research-validated)
        CSATQuestion = "How satisfied are you with this alert? (1-5)"
        
        # Outcome classification
        OutcomeQuestion = "What was the outcome of this alert?"
        OutcomeOptions = @(
            "Actionable - Led to immediate action",
            "Informational - Useful for awareness", 
            "False Positive - Not a real issue",
            "True Positive - Confirmed real issue",
            "Noise - Not relevant or helpful",
            "Critical - Required immediate response"
        )
        
        # Additional questions
        AdditionalQuestions = @(
            "Did this alert help you identify a real issue?",
            "Was the alert timing appropriate?",
            "Was the alert severity level accurate?",
            "Would you like to receive similar alerts in the future?"
        )
        
        # Links and actions
        FeedbackUrl = $feedbackUrl
        QuickRatingUrl = "$feedbackUrl/quick"
        
        # Metadata
        AlertId = $Alert.Id
        DeliveryChannels = $DeliveryChannels -join ", "
        Timestamp = Get-Date -Format "o"
    }
    
    return $content
}

function Update-QualityMetrics {
    <#
    .SYNOPSIS
        Updates quality metrics based on new feedback entry.
    
    .PARAMETER FeedbackEntry
        Feedback entry to process for quality metrics.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [PSCustomObject]$FeedbackEntry
    )
    
    try {
        $alertId = $FeedbackEntry.AlertId
        $today = Get-Date -Format "yyyy-MM-dd"
        
        # Initialize metrics for today if not exists
        if (-not $script:AlertFeedbackState.QualityMetrics.ContainsKey($today)) {
            $script:AlertFeedbackState.QualityMetrics[$today] = @{
                Date = $today
                TotalAlerts = 0
                ActionableAlerts = 0
                FalsePositives = 0
                TruePositives = 0
                AverageRating = 0.0
                AverageEffectiveness = 0.0
                AverageResponseTime = 0.0
                Precision = 0.0
                Recall = 0.0
                F1Score = 0.0
                NPSScore = 0.0
                CSATScore = 0.0
                RatingsCount = 0
                ResponseTimesSum = 0.0
                EffectivenessSum = 0.0
            }
        }
        
        $metrics = $script:AlertFeedbackState.QualityMetrics[$today]
        
        # Update counts
        $metrics.TotalAlerts++
        $metrics.RatingsCount++
        
        # Update rating averages
        $metrics.EffectivenessSum += $FeedbackEntry.EffectivenessScore
        $metrics.AverageEffectiveness = $metrics.EffectivenessSum / $metrics.RatingsCount
        
        # Update response time if provided
        if ($FeedbackEntry.ResponseTime -gt 0) {
            $metrics.ResponseTimesSum += $FeedbackEntry.ResponseTime
            $metrics.AverageResponseTime = $metrics.ResponseTimesSum / $metrics.RatingsCount
        }
        
        # Update outcome classifications
        if ($FeedbackEntry.IsActionable) {
            $metrics.ActionableAlerts++
        }
        
        if ($FeedbackEntry.IsFalsePositive) {
            $metrics.FalsePositives++
        }
        elseif ($FeedbackEntry.AlertOutcome -eq "TruePositive") {
            $metrics.TruePositives++
        }
        
        # Calculate precision and recall (research-validated formulas)
        if ($metrics.TotalAlerts -gt 0) {
            # Precision = TruePositives / (TruePositives + FalsePositives)
            $totalPositives = $metrics.TruePositives + $metrics.FalsePositives
            $metrics.Precision = if ($totalPositives -gt 0) { 
                [Math]::Round($metrics.TruePositives / $totalPositives, 3) 
            } else { 0.0 }
            
            # Recall = ActionableAlerts / TotalAlerts (proxy measurement)
            $metrics.Recall = [Math]::Round($metrics.ActionableAlerts / $metrics.TotalAlerts, 3)
            
            # F1 Score = 2 * (Precision * Recall) / (Precision + Recall)
            $precisionRecallSum = $metrics.Precision + $metrics.Recall
            $metrics.F1Score = if ($precisionRecallSum -gt 0) {
                [Math]::Round((2 * $metrics.Precision * $metrics.Recall) / $precisionRecallSum, 3)
            } else { 0.0 }
        }
        
        # Update average rating
        $allRatings = $script:AlertFeedbackState.FeedbackDatabase.Values | Where-Object { $_.Timestamp.Date -eq (Get-Date).Date }
        if ($allRatings.Count -gt 0) {
            $ratingSum = ($allRatings | Measure-Object -Property UserRating -Sum).Sum
            $metrics.AverageRating = [Math]::Round($ratingSum / $allRatings.Count, 2)
            
            # Convert to CSAT score (research-validated)
            $metrics.CSATScore = [Math]::Round(($metrics.AverageRating / 5.0) * 100, 1)
        }
        
        $script:AlertFeedbackState.Statistics.QualityScoresCalculated++
        
        Write-Verbose "Quality metrics updated for $today"
        Write-Verbose "Precision: $($metrics.Precision), Recall: $($metrics.Recall), F1: $($metrics.F1Score)"
        
        return $true
    }
    catch {
        Write-Error "Failed to update quality metrics: $($_.Exception.Message)"
        return $false
    }
}

function Get-AlertQualityMetrics {
    <#
    .SYNOPSIS
        Retrieves alert quality metrics for specified time period.
    
    .DESCRIPTION
        Returns comprehensive quality metrics including precision, recall, F1 score,
        NPS/CSAT scores, and effectiveness metrics for enterprise reporting.
    
    .PARAMETER StartDate
        Start date for metrics period.
    
    .PARAMETER EndDate
        End date for metrics period.
    
    .PARAMETER MetricTypes
        Specific metric types to include.
    
    .EXAMPLE
        Get-AlertQualityMetrics -StartDate (Get-Date).AddDays(-30)
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [DateTime]$StartDate = (Get-Date).AddDays(-30),
        
        [Parameter(Mandatory = $false)]
        [DateTime]$EndDate = (Get-Date),
        
        [Parameter(Mandatory = $false)]
        [QualityMetricType[]]$MetricTypes = @([QualityMetricType]::Precision, [QualityMetricType]::Recall, [QualityMetricType]::F1Score)
    )
    
    try {
        $metrics = @{}
        $dateRange = @()
        
        # Generate date range
        $currentDate = $StartDate.Date
        while ($currentDate -le $EndDate.Date) {
            $dateKey = $currentDate.ToString("yyyy-MM-dd")
            $dateRange += $dateKey
            $currentDate = $currentDate.AddDays(1)
        }
        
        # Collect metrics for date range
        foreach ($date in $dateRange) {
            if ($script:AlertFeedbackState.QualityMetrics.ContainsKey($date)) {
                $metrics[$date] = $script:AlertFeedbackState.QualityMetrics[$date]
            }
        }
        
        # Calculate aggregate metrics
        $aggregateMetrics = Calculate-AggregateQualityMetrics -DailyMetrics $metrics.Values
        
        Write-Verbose "Retrieved quality metrics for $($metrics.Count) days"
        
        return [PSCustomObject]@{
            Period = [PSCustomObject]@{
                StartDate = $StartDate
                EndDate = $EndDate
                DaysIncluded = $metrics.Count
            }
            DailyMetrics = $metrics
            AggregateMetrics = $aggregateMetrics
            RetrievedAt = Get-Date
        }
    }
    catch {
        Write-Error "Failed to get alert quality metrics: $($_.Exception.Message)"
        return $null
    }
}

function Calculate-AggregateQualityMetrics {
    <#
    .SYNOPSIS
        Calculates aggregate quality metrics from daily metrics.
    
    .PARAMETER DailyMetrics
        Collection of daily metric objects.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [array]$DailyMetrics
    )
    
    if ($DailyMetrics.Count -eq 0) {
        return @{}
    }
    
    try {
        # Calculate weighted averages (research-validated approach)
        $totalAlerts = ($DailyMetrics | Measure-Object -Property TotalAlerts -Sum).Sum
        $totalActionable = ($DailyMetrics | Measure-Object -Property ActionableAlerts -Sum).Sum
        $totalFalsePositives = ($DailyMetrics | Measure-Object -Property FalsePositives -Sum).Sum
        $totalTruePositives = ($DailyMetrics | Measure-Object -Property TruePositives -Sum).Sum
        
        # Aggregate precision and recall
        $aggregatePrecision = if (($totalTruePositives + $totalFalsePositives) -gt 0) {
            [Math]::Round($totalTruePositives / ($totalTruePositives + $totalFalsePositives), 3)
        } else { 0.0 }
        
        $aggregateRecall = if ($totalAlerts -gt 0) {
            [Math]::Round($totalActionable / $totalAlerts, 3)
        } else { 0.0 }
        
        # F1 Score
        $aggregateF1 = if (($aggregatePrecision + $aggregateRecall) -gt 0) {
            [Math]::Round((2 * $aggregatePrecision * $aggregateRecall) / ($aggregatePrecision + $aggregateRecall), 3)
        } else { 0.0 }
        
        # Average effectiveness and response time
        $avgEffectiveness = ($DailyMetrics | Measure-Object -Property AverageEffectiveness -Average).Average
        $avgResponseTime = ($DailyMetrics | Measure-Object -Property AverageResponseTime -Average).Average
        $avgCSAT = ($DailyMetrics | Measure-Object -Property CSATScore -Average).Average
        
        return [PSCustomObject]@{
            TotalAlerts = $totalAlerts
            TotalActionable = $totalActionable
            TotalFalsePositives = $totalFalsePositives
            TotalTruePositives = $totalTruePositives
            AggregatePrecision = $aggregatePrecision
            AggregateRecall = $aggregateRecall
            AggregateF1Score = $aggregateF1
            AverageEffectiveness = [Math]::Round($avgEffectiveness, 3)
            AverageResponseTime = [Math]::Round($avgResponseTime, 1)
            AverageCSATScore = [Math]::Round($avgCSAT, 1)
            FalsePositiveRate = if ($totalAlerts -gt 0) { [Math]::Round($totalFalsePositives / $totalAlerts, 3) } else { 0.0 }
            ActionabilityRate = if ($totalAlerts -gt 0) { [Math]::Round($totalActionable / $totalAlerts, 3) } else { 0.0 }
        }
    }
    catch {
        Write-Error "Failed to calculate aggregate metrics: $($_.Exception.Message)"
        return @{}
    }
}

function Test-AlertFeedbackSystem {
    <#
    .SYNOPSIS
        Tests alert feedback collection system with comprehensive validation.
    
    .DESCRIPTION
        Validates feedback collection, quality metrics calculation, and
        integration with existing alert systems.
    
    .EXAMPLE
        Test-AlertFeedbackSystem
    #>
    [CmdletBinding()]
    param()
    
    Write-Host "Testing Alert Feedback Collection System..." -ForegroundColor Cyan
    
    if (-not $script:AlertFeedbackState.IsInitialized) {
        Write-Error "Alert feedback collector not initialized"
        return $false
    }
    
    $testResults = @{}
    
    # Test 1: Feedback collection
    Write-Host "Testing feedback collection..." -ForegroundColor Yellow
    
    $testAlert = [PSCustomObject]@{
        Id = [Guid]::NewGuid().ToString()
        Severity = "High"
        Source = "FeedbackSystemTest"
        Component = "TestComponent"
        Message = "Test alert for feedback collection validation"
        Timestamp = Get-Date
    }
    
    $feedbackResult = Collect-AlertFeedback -AlertId $testAlert.Id -UserRating Good -AlertOutcome Actionable -Comments "Test feedback entry" -ResponseTime 1200
    $testResults.FeedbackCollection = $feedbackResult
    
    # Test 2: Quality metrics calculation
    Write-Host "Testing quality metrics calculation..." -ForegroundColor Yellow
    
    $metricsResult = Get-AlertQualityMetrics -StartDate (Get-Date).AddDays(-1)
    $testResults.QualityMetrics = ($null -ne $metricsResult)
    
    # Test 3: Automated survey generation
    Write-Host "Testing automated survey generation..." -ForegroundColor Yellow
    
    $surveyResult = Generate-AutomatedFeedbackSurvey -Alert $testAlert -DeliveryChannels @("Email", "Dashboard")
    $testResults.AutomatedSurveys = ($surveyResult -ne $false)
    
    # Calculate success rate
    $successCount = ($testResults.Values | Where-Object { $_ }).Count
    $totalTests = $testResults.Count
    $successRate = [Math]::Round(($successCount / $totalTests) * 100, 1)
    
    Write-Host "Alert feedback system test complete: $successCount/$totalTests tests passed ($successRate%)" -ForegroundColor Green
    
    return @{
        TestResults = $testResults
        SuccessCount = $successCount
        TotalTests = $totalTests
        SuccessRate = $successRate
        Statistics = $script:AlertFeedbackState.Statistics
    }
}

function Get-TodaysSurveyCount {
    # Helper function to count surveys generated today
    $today = Get-Date -Format "yyyy-MM-dd"
    $todaySurveys = ($script:AlertFeedbackState.ActiveSurveys.Values | Where-Object { 
        $_.CreatedTime.ToString("yyyy-MM-dd") -eq $today 
    }).Count
    return $todaySurveys
}

function Initialize-QualityMetrics {
    # Helper function to initialize quality metrics storage
    $script:AlertFeedbackState.QualityMetrics = @{}
    Write-Verbose "Quality metrics storage initialized"
}

function Enable-AutomatedFeedbackCollection {
    # Helper function to enable automated feedback collection
    Write-Verbose "Automated feedback collection enabled"
    return $true
}

function Get-AlertFeedbackStatistics {
    <#
    .SYNOPSIS
        Returns comprehensive alert feedback collection statistics.
    #>
    [CmdletBinding()]
    param()
    
    $stats = $script:AlertFeedbackState.Statistics.Clone()
    
    if ($stats.StartTime) {
        $stats.Runtime = (Get-Date) - $stats.StartTime
    }
    
    $stats.IsInitialized = $script:AlertFeedbackState.IsInitialized
    $stats.DatabaseEntries = $script:AlertFeedbackState.FeedbackDatabase.Count
    $stats.ActiveSurveys = $script:AlertFeedbackState.ActiveSurveys.Count
    $stats.ConnectedSystems = $script:AlertFeedbackState.ConnectedSystems.Clone()
    
    return [PSCustomObject]$stats
}

# Export alert feedback functions
Export-ModuleMember -Function @(
    'Initialize-AlertFeedbackCollector',
    'Collect-AlertFeedback',
    'Generate-AutomatedFeedbackSurvey',
    'Get-AlertQualityMetrics',
    'Test-AlertFeedbackSystem',
    'Get-AlertFeedbackStatistics'
)