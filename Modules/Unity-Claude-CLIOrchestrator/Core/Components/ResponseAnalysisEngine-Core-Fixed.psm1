# Unity-Claude-CLIOrchestrator - Response Analysis Engine Core (Fixed)
# Main orchestration module for the refactored response analysis system  
# Fixed version using dot-sourcing to avoid module nesting limit
# Compatible with PowerShell 5.1 and Claude Code CLI 2025

# === FIXED VERSION - USING DOT-SOURCING ===
Write-Verbose "Loading Fixed ResponseAnalysisEngine-Core with dot-sourcing"

#region Module Configuration and Dependencies

# Load all component modules using dot-sourcing instead of Import-Module
$script:ComponentPath = $PSScriptRoot
$script:RequiredComponents = @(
    'AnalysisLogging',
    'CircuitBreaker', 
    'JsonProcessing'
)

# Dot-source components to avoid nesting limit
foreach ($component in $script:RequiredComponents) {
    $componentFile = Join-Path $script:ComponentPath "$component.psm1"
    if (Test-Path $componentFile) {
        # Check if key functions from this component are already loaded
        $testFunction = switch ($component) {
            'AnalysisLogging' { 'Write-AnalysisLog' }
            'CircuitBreaker' { 'Test-CircuitBreakerState' }
            'JsonProcessing' { 'Test-JsonTruncation' }
            default { $null }
        }
        
        if ($testFunction -and -not (Get-Command $testFunction -ErrorAction SilentlyContinue)) {
            . $componentFile
            Write-Verbose "Dot-sourced component: $component"
        } else {
            Write-Verbose "Component already loaded: $component"
        }
    } else {
        Write-Warning "Component not found: $componentFile"
    }
}

# Core analysis configuration
$script:AnalysisConfig = @{
    TruncationPatterns = @(4000, 6000, 8000, 10000, 12000, 16000)
    MaxRetryAttempts = 3
    RetryDelayMs = @(500, 1000, 2000)  
    SchemaValidationEnabled = $true
    PerformanceTargetMs = 200
    CircuitBreakerThreshold = 5
    CircuitBreakerResetTimeMs = 30000
    EnableAdvancedAnalysis = $true
    MaxConcurrentOperations = 5
}

#endregion

#region Sentiment Analysis Functions

function Analyze-ResponseSentiment {
    <#
    .SYNOPSIS
        Analyzes the sentiment of response text using pattern matching
    
    .DESCRIPTION
        Provides sentiment analysis for response text using keyword patterns
        Returns sentiment score and classification
    
    .PARAMETER ResponseText
        The text to analyze for sentiment
    
    .EXAMPLE
        $sentiment = Analyze-ResponseSentiment -ResponseText "This is a successful completion"
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$ResponseText
    )
    
    $sentiment = [PSCustomObject]@{
        Score = 0.0
        Classification = "Neutral"
        Keywords = @()
    }
    
    # Positive indicators
    $positivePatterns = @(
        'success', 'complete', 'ready', 'available', 'confirmed',
        'approved', 'validated', 'passed', 'working', 'operational'
    )
    
    # Negative indicators
    $negativePatterns = @(
        'error', 'failed', 'invalid', 'missing', 'unavailable',
        'denied', 'rejected', 'broken', 'critical', 'warning'
    )
    
    # Count matches
    $positiveCount = 0
    $negativeCount = 0
    
    foreach ($pattern in $positivePatterns) {
        if ($ResponseText -match "\b$pattern\b") {
            $positiveCount++
            $sentiment.Keywords += "+$pattern"
        }
    }
    
    foreach ($pattern in $negativePatterns) {
        if ($ResponseText -match "\b$pattern\b") {
            $negativeCount++
            $sentiment.Keywords += "-$pattern"
        }
    }
    
    # Calculate sentiment score
    $total = $positiveCount + $negativeCount
    if ($total -gt 0) {
        $sentiment.Score = ($positiveCount - $negativeCount) / $total
    }
    
    # Classify sentiment
    if ($sentiment.Score -gt 0.3) {
        $sentiment.Classification = "Positive"
    } elseif ($sentiment.Score -lt -0.3) {
        $sentiment.Classification = "Negative"
    }
    
    return $sentiment
}

#endregion

#region Entity Extraction Functions

function Extract-ResponseEntities {
    <#
    .SYNOPSIS
        Extracts named entities from response text
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$ResponseText
    )
    
    $entities = @{
        Files = @()
        Commands = @()
        Modules = @()
        Errors = @()
        Recommendations = @()
    }
    
    # Extract file paths
    $filePattern = '([A-Za-z]:\\[^<>:"|?*\n\r]+\.(ps1|psm1|psd1|json|xml|txt|md))'
    $entities.Files = [regex]::Matches($ResponseText, $filePattern) | 
        ForEach-Object { $_.Groups[1].Value } | 
        Select-Object -Unique
    
    # Extract PowerShell commands
    $cmdPattern = '\b(Get|Set|New|Remove|Test|Invoke|Start|Stop|Import|Export)-[A-Za-z]+\b'
    $entities.Commands = [regex]::Matches($ResponseText, $cmdPattern) | 
        ForEach-Object { $_.Value } | 
        Select-Object -Unique
    
    # Extract module names
    $modulePattern = 'Unity-Claude-[A-Za-z]+'
    $entities.Modules = [regex]::Matches($ResponseText, $modulePattern) | 
        ForEach-Object { $_.Value } | 
        Select-Object -Unique
    
    # Extract error messages
    $errorPattern = '(error|exception|failed):\s*([^\n\r]+)'
    $entities.Errors = [regex]::Matches($ResponseText, $errorPattern, [Text.RegularExpressions.RegexOptions]::IgnoreCase) | 
        ForEach-Object { $_.Groups[2].Value.Trim() } | 
        Select-Object -Unique
    
    # Extract recommendations
    $recPattern = 'RECOMMENDATION:\s*([A-Z]+)(?:\s*-\s*([^\]]+))?'
    $entities.Recommendations = [regex]::Matches($ResponseText, $recPattern) | 
        ForEach-Object {
            [PSCustomObject]@{
                Type = $_.Groups[1].Value
                Details = if ($_.Groups[2].Success) { $_.Groups[2].Value.Trim() } else { "" }
            }
        }
    
    return $entities
}

#endregion

#region Context Analysis Functions

function Get-ResponseContext {
    <#
    .SYNOPSIS
        Analyzes response to determine context and intent
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$ResponseText,
        
        [Parameter()]
        [hashtable]$PreviousContext
    )
    
    $context = @{
        PromptType = "Unknown"
        Intent = "Unknown"
        Confidence = 0.0
        Topics = @()
        RequiresAction = $false
        ActionType = $null
    }
    
    # Determine prompt type
    $promptTypePatterns = @{
        Testing = 'test|validation|verify|check'
        Debugging = 'error|fix|debug|issue|problem'
        Implementation = 'create|implement|build|develop'
        Analysis = 'analyze|review|assess|evaluate'
        Documentation = 'document|describe|explain'
    }
    
    foreach ($type in $promptTypePatterns.Keys) {
        if ($ResponseText -match $promptTypePatterns[$type]) {
            $context.PromptType = $type
            $context.Confidence += 0.3
            break
        }
    }
    
    # Determine intent
    if ($ResponseText -match 'RECOMMENDATION:') {
        $context.Intent = "Recommendation"
        $context.RequiresAction = $true
        $context.Confidence += 0.5
    } elseif ($ResponseText -match '(error|failed|exception)') {
        $context.Intent = "ErrorReport"
        $context.RequiresAction = $true
        $context.Confidence += 0.4
    } elseif ($ResponseText -match '(complete|success|ready)') {
        $context.Intent = "StatusUpdate"
        $context.RequiresAction = $false
        $context.Confidence += 0.3
    }
    
    # Extract topics
    $topicPatterns = @(
        'module', 'function', 'test', 'configuration',
        'deployment', 'integration', 'performance', 'security'
    )
    
    foreach ($topic in $topicPatterns) {
        if ($ResponseText -match "\b$topic\b") {
            $context.Topics += $topic
        }
    }
    
    # Determine action type if action required
    if ($context.RequiresAction) {
        if ($ResponseText -match 'TEST') {
            $context.ActionType = "ExecuteTest"
        } elseif ($ResponseText -match 'FIX') {
            $context.ActionType = "ApplyFix"
        } elseif ($ResponseText -match 'CONTINUE') {
            $context.ActionType = "Continue"
        } elseif ($ResponseText -match 'RESTART') {
            $context.ActionType = "RestartModule"
        }
    }
    
    return $context
}

#endregion

#region Main Enhanced Response Analysis Function

function Invoke-EnhancedResponseAnalysis {
    <#
    .SYNOPSIS
        Performs comprehensive response analysis with all enhancement features
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$ResponseText,
        
        [Parameter()]
        [string]$ResponseFile,
        
        [Parameter()]
        [switch]$EnableSentimentAnalysis,
        
        [Parameter()]
        [switch]$ExtractEntities,
        
        [Parameter()]
        [switch]$AnalyzeContext,
        
        [Parameter()]
        [hashtable]$PreviousContext
    )
    
    $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
    
    try {
        # Initialize result structure
        $result = [PSCustomObject]@{
            Timestamp = Get-Date
            Success = $false
            ResponseText = $ResponseText
            ParsedJson = $null
            Sentiment = $null
            Entities = $null
            Context = $null
            Recommendations = @()
            ValidationErrors = @()
            ProcessingTimeMs = 0
            CircuitBreakerState = "Closed"
        }
        
        # Check circuit breaker
        $circuitState = Test-CircuitBreakerState
        $result.CircuitBreakerState = $circuitState
        
        if ($circuitState -eq "Open") {
            Write-Warning "Circuit breaker is open - skipping analysis"
            $result.ValidationErrors += "Circuit breaker is open"
            return $result
        }
        
        # Parse JSON if response looks like JSON
        if ($ResponseText -match '^\s*\{' -or $ResponseText -match '^\s*\[') {
            try {
                # Check for truncation
                if (Test-JsonTruncation -JsonString $ResponseText) {
                    Write-Verbose "Detected truncated JSON - attempting repair"
                    $repairedJson = Repair-TruncatedJson -TruncatedJson $ResponseText
                    if ($repairedJson) {
                        $ResponseText = $repairedJson
                    }
                }
                
                # Parse JSON
                $result.ParsedJson = $ResponseText | ConvertFrom-Json
                
                # Extract recommendations from JSON
                if ($result.ParsedJson.RESPONSE) {
                    if ($result.ParsedJson.RESPONSE -match 'RECOMMENDATION:\s*(.+)') {
                        $result.Recommendations += $Matches[1]
                    }
                }
                
                Update-CircuitBreakerState -Success $true
                
            } catch {
                Write-Warning "JSON parsing failed: $_"
                $result.ValidationErrors += "JSON parsing error: $_"
                Update-CircuitBreakerState -Success $false
            }
        }
        
        # Perform sentiment analysis if requested
        if ($EnableSentimentAnalysis) {
            $result.Sentiment = Analyze-ResponseSentiment -ResponseText $ResponseText
        }
        
        # Extract entities if requested
        if ($ExtractEntities) {
            $result.Entities = Extract-ResponseEntities -ResponseText $ResponseText
            if ($result.Entities.Recommendations) {
                $result.Recommendations += $result.Entities.Recommendations | 
                    ForEach-Object { "$($_.Type) - $($_.Details)" }
            }
        }
        
        # Analyze context if requested
        if ($AnalyzeContext) {
            $result.Context = Get-ResponseContext -ResponseText $ResponseText -PreviousContext $PreviousContext
        }
        
        # Extract recommendations from plain text if not found in JSON
        if ($result.Recommendations.Count -eq 0) {
            $recMatches = [regex]::Matches($ResponseText, 'RECOMMENDATION:\s*([^\n\r]+)')
            $result.Recommendations = $recMatches | ForEach-Object { $_.Groups[1].Value.Trim() }
        }
        
        $result.Success = ($result.ValidationErrors.Count -eq 0)
        
    } catch {
        Write-AnalysisLog "Critical error in response analysis: $_" -Level "ERROR"
        $result.ValidationErrors += "Critical error: $_"
        Update-CircuitBreakerState -Success $false
    } finally {
        $stopwatch.Stop()
        $result.ProcessingTimeMs = $stopwatch.ElapsedMilliseconds
        
        # Log performance
        if ($result.ProcessingTimeMs -gt $script:AnalysisConfig.PerformanceTargetMs) {
            Write-AnalysisLog "Performance target missed: $($result.ProcessingTimeMs)ms > $($script:AnalysisConfig.PerformanceTargetMs)ms" -Level "WARN"
        }
    }
    
    return $result
}

#endregion

# Export all public functions
Export-ModuleMember -Function @(
    'Invoke-EnhancedResponseAnalysis',
    'Analyze-ResponseSentiment',
    'Extract-ResponseEntities',
    'Get-ResponseContext',
    'Test-JsonTruncation',
    'Repair-TruncatedJson',
    'Test-CircuitBreakerState',
    'Update-CircuitBreakerState',
    'Write-AnalysisLog'
)